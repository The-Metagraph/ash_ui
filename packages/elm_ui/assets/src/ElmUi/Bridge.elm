module ElmUi.Bridge exposing (decodeRuntimeId)

import Json.Decode as Decode exposing (Decoder)


decodeRuntimeId : Decoder String
decodeRuntimeId =
    Decode.field "runtime_id" Decode.string
