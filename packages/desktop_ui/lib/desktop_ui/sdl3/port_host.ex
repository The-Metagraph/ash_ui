defmodule DesktopUi.Sdl3.PortHost do
  @moduledoc """
  Port-backed default host boundary for the SDL3 native runtime process.
  """

  @behaviour DesktopUi.Sdl3.Host

  alias DesktopUi.Runtime.Error
  alias DesktopUi.Sdl3.{Capabilities, NativeBuild, Protocol}

  @enforce_keys [:id, :port, :executable, :args, :protocol_version, :backend]
  defstruct [
    :id,
    :port,
    :executable,
    :args,
    :protocol_version,
    :backend,
    :cwd,
    :env,
    :last_exit_status,
    :last_message_family,
    buffer: <<>>,
    transport: :port,
    state: :running,
    messages_sent: 0,
    messages_received: 0
  ]

  @type t :: %__MODULE__{}

  @impl true
  def contract do
    %{
      transport: :port,
      framed_protocol: Protocol.contract().framing,
      default_runner: :auto_detected,
      supported_backends: [:compiled_sdl3_host, :elixir_host],
      crash_reporting: [:exit_status, :closed],
      liveness_states: [:running, :stopped, :crashed],
      version_negotiation: :explicit
    }
  end

  @impl true
  def validation_state, do: :port_host_ready

  @impl true
  def launch_spec(opts) do
    %{
      backend: Keyword.get(opts, :backend, :custom),
      executable: Keyword.get(opts, :executable),
      args: List.wrap(Keyword.get(opts, :args, [])),
      cwd: Keyword.get(opts, :cd),
      env: Keyword.get(opts, :env, []),
      transport: :port,
      protocol_version: Keyword.get(opts, :protocol_version, hd(Protocol.supported_versions()))
    }
  end

  @spec default_launch_spec(keyword()) :: map()
  def default_launch_spec(opts \\ []) do
    package_root = Path.expand("../../..", __DIR__)
    code_paths = default_code_paths()
    capabilities = Keyword.get(opts, :capabilities, Capabilities.detect())
    requested_backend = Keyword.get(opts, :backend, :auto)

    cond do
      requested_backend == :compiled_sdl3_host ->
        %{
          backend: :compiled_sdl3_host,
          requested_backend: requested_backend,
          executable: NativeBuild.executable_path(),
          args: [],
          cd: Keyword.get(opts, :cd, package_root),
          env: [],
          transport: :port,
          protocol_version:
            Keyword.get(opts, :protocol_version, hd(Protocol.supported_versions())),
          launch_ready?: capabilities.build.launch_ready?,
          capabilities: capabilities
        }

      capabilities.build.launch_ready? ->
        %{
          backend: :compiled_sdl3_host,
          requested_backend: requested_backend,
          executable: NativeBuild.executable_path(),
          args: [],
          cd: Keyword.get(opts, :cd, package_root),
          env: [],
          transport: :port,
          protocol_version:
            Keyword.get(opts, :protocol_version, hd(Protocol.supported_versions())),
          launch_ready?: true,
          capabilities: capabilities
        }

      true ->
        %{
          backend: :elixir_host,
          requested_backend: requested_backend,
          executable: System.find_executable("elixir"),
          args:
            Enum.flat_map(code_paths, fn path -> ["-pa", path] end) ++
              [
                "--no-halt",
                "-e",
                "DesktopUi.Sdl3.NativeHost.main()"
              ],
          cd: Keyword.get(opts, :cd, package_root),
          env: [],
          transport: :port,
          protocol_version:
            Keyword.get(opts, :protocol_version, hd(Protocol.supported_versions())),
          launch_ready?: true,
          capabilities: capabilities
        }
    end
  end

  @spec launch_default(keyword()) :: {:ok, t()} | {:error, Error.t()}
  def launch_default(opts \\ []) do
    spec = default_launch_spec(opts)

    cond do
      spec.backend == :compiled_sdl3_host and not spec.launch_ready? ->
        {:error,
         Error.new(
           :compiled_native_host_not_launch_ready,
           %{executable: spec.executable, capabilities: spec.capabilities},
           :sdl3_port_host
         )}

      true ->
        launch(
          executable: spec.executable,
          args: spec.args,
          cd: spec.cd,
          env: spec.env,
          backend: spec.backend
        )
    end
  end

  @impl true
  def launch(opts) do
    spec = launch_spec(opts)

    with {:ok, executable} <- validate_executable(spec.executable) do
      port = Port.open({:spawn_executable, String.to_charlist(executable)}, port_options(spec))

      {:ok,
       %__MODULE__{
         id: Keyword.get(opts, :id, "desktop-ui-host-#{System.unique_integer([:positive])}"),
         port: port,
         executable: executable,
         args: spec.args,
         backend: spec.backend,
         cwd: spec.cwd,
         env: spec.env,
         protocol_version: spec.protocol_version
       }}
    end
  end

  @impl true
  def status(%__MODULE__{} = session) do
    %{
      id: session.id,
      executable: session.executable,
      args: session.args,
      cwd: session.cwd,
      env: session.env,
      backend: session.backend,
      transport: session.transport,
      protocol_version: session.protocol_version,
      supported_versions: Protocol.supported_versions(),
      version_compatible?: session.protocol_version in Protocol.supported_versions(),
      state: state_for(session),
      liveness: if(alive?(session), do: :alive, else: :dead),
      last_exit_status: session.last_exit_status,
      last_message_family: session.last_message_family,
      messages_sent: session.messages_sent,
      messages_received: session.messages_received
    }
  end

  @impl true
  def send_message(%__MODULE__{} = session, message) do
    with {:ok, frame} <- Protocol.frame(message) do
      true = Port.command(session.port, frame)

      {:ok,
       %{
         session
         | messages_sent: session.messages_sent + 1,
           last_message_family: nil
       }
       |> record_last_family(message)}
    end
  end

  @impl true
  def recv_message(%__MODULE__{} = session, timeout) do
    case Protocol.next_message(session.buffer) do
      {:ok, message, rest} ->
        {:ok, message,
         %{session | buffer: rest, messages_received: session.messages_received + 1}}

      :more ->
        receive_frame(session, timeout)

      {:error, _} = error ->
        error
    end
  end

  @impl true
  def shutdown(%__MODULE__{} = session) do
    if alive?(session) do
      try do
        Port.close(session.port)
      rescue
        ArgumentError -> :ok
      end
    end

    {:ok, %{session | state: :stopped}}
  end

  defp receive_frame(%__MODULE__{} = session, timeout) do
    receive do
      {port, {:data, data}} when port == session.port ->
        next_session = %{session | buffer: session.buffer <> data}

        case Protocol.next_message(next_session.buffer) do
          {:ok, message, rest} ->
            {:ok, message,
             %{next_session | buffer: rest, messages_received: session.messages_received + 1}}
            |> record_received_family()

          :more ->
            receive_frame(next_session, timeout)

          {:error, _} = error ->
            error
        end

      {port, {:exit_status, status}} when port == session.port ->
        {:error,
         Error.new(
           :native_host_exited,
           %{host_id: session.id, exit_status: status},
           :sdl3_port_host
         )}

      {port, :closed} when port == session.port ->
        {:error, Error.new(:native_host_closed, %{host_id: session.id}, :sdl3_port_host)}
    after
      timeout ->
        {:error,
         Error.new(
           :native_host_timeout,
           %{host_id: session.id, timeout: timeout},
           :sdl3_port_host
         )}
    end
  end

  defp state_for(%__MODULE__{} = session) do
    cond do
      session.state == :stopped -> :stopped
      session.last_exit_status not in [nil, 0] -> :crashed
      alive?(session) -> :running
      true -> :stopped
    end
  end

  defp alive?(%__MODULE__{port: port}) do
    case Port.info(port) do
      nil -> false
      _info -> true
    end
  end

  defp validate_executable(nil) do
    {:error, Error.new(:missing_native_host_executable, %{}, :sdl3_port_host)}
  end

  defp validate_executable(executable) when is_binary(executable) do
    if File.exists?(executable) do
      {:ok, executable}
    else
      {:error,
       Error.new(
         :missing_native_host_executable,
         %{executable: executable},
         :sdl3_port_host
       )}
    end
  end

  defp port_options(spec) do
    options = [:binary, :exit_status, :use_stdio, :hide]
    options = [{:args, Enum.map(spec.args, &String.to_charlist/1)} | options]
    options = if spec.cwd, do: [{:cd, String.to_charlist(spec.cwd)} | options], else: options

    if spec.env != [] do
      [
        {:env,
         Enum.map(spec.env, fn {key, value} ->
           {String.to_charlist(to_string(key)), String.to_charlist(to_string(value))}
         end)}
        | options
      ]
    else
      options
    end
  end

  defp record_last_family(session, message) when is_map(message) do
    %{session | last_message_family: Map.get(message, :family) || Map.get(message, "family")}
  end

  defp record_last_family(session, _message), do: session

  defp record_received_family({:ok, message, session}) do
    {:ok, message, %{session | last_message_family: Map.get(message, :family)}}
  end

  defp default_code_paths do
    :code.get_path()
    |> Enum.map(&List.to_string/1)
    |> Enum.filter(&String.contains?(&1, "/_build/"))
    |> Enum.uniq()
  end
end
