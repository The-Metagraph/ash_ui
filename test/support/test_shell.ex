defmodule AshUI.TestShell do
  @moduledoc false

  def run(command, opts) do
    cd = Keyword.fetch!(opts, :cd)
    env = Keyword.get(opts, :env, [])
    stderr_to_stdout = Keyword.get(opts, :stderr_to_stdout, true)

    case :os.type() do
      {:win32, _} ->
        wsl_command = build_wsl_command(cd, env, command)
        System.cmd("wsl.exe", ["bash", "-lc", wsl_command], stderr_to_stdout: stderr_to_stdout)

      _ ->
        System.cmd("bash", ["-lc", command], cd: cd, env: env, stderr_to_stdout: stderr_to_stdout)
    end
  end

  def run_spec_validate(repo_root) do
    case :os.type() do
      {:win32, _} ->
        System.cmd("cmd.exe", ["/c", "mix.bat spec.validate --strict"], stderr_to_stdout: true)

      _ ->
        System.cmd("mix", ["spec.validate", "--strict"], cd: repo_root, stderr_to_stdout: true)
    end
  end

  defp build_wsl_command(cd, env, command) do
    exports =
      env
      |> Enum.map(fn {key, value} ->
        "export #{key}=#{shell_escape(maybe_to_wsl_path(value))};"
      end)
      |> Enum.join(" ")

    "set -e; #{exports} cd #{shell_escape(maybe_to_wsl_path(cd))} && #{command}"
  end

  defp maybe_to_wsl_path(value) do
    value = to_string(value)

    case Regex.run(~r/^([A-Za-z]):[\/\\](.*)$/, value) do
      [_, drive, rest] ->
        "/mnt/#{String.downcase(drive)}/#{String.replace(rest, "\\", "/")}"

      _ ->
        value
    end
  end

  defp shell_escape(value) do
    "'" <> String.replace(value, "'", "'\"'\"'") <> "'"
  end
end
