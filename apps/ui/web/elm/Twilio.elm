port module Twilio exposing (..)
-- TODO: Do not allow calling unless Twilio device is in 'Ready' state
port statusChanged : (String -> msg) -> Sub msg

port setup : String -> Cmd msg
