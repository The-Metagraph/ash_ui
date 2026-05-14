module Main exposing (main)

import Browser
import Html exposing (Html, div, text)


type alias Model =
    { status : String }


type Msg
    = NoOp


init : () -> ( Model, Cmd Msg )
init _ =
    ( { status = "elm_ui frontend runtime scaffold" }, Cmd.none )


update : Msg -> Model -> ( Model, Cmd Msg )
update _ model =
    ( model, Cmd.none )


view : Model -> Html Msg
view model =
    div [] [ text model.status ]


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }
