module Line exposing (..)

import Html exposing (..)
import Html.Attributes exposing (placeholder, value, disabled)
import Html.Events exposing (onClick, onInput)

-- MODEL

type alias Callee = String

type Call
  = None
  | Dialling Callee

type alias Model = Call

initialModel : Model
initialModel = None

-- UPDATE

type Msg
  = DialInput Callee
  | RequestCall Callee

update : Msg -> Model -> ( Model, Cmd Msg )
update message model =
  case message of
    DialInput callee ->
      ( Dialling callee, Cmd.none )
    RequestCall callee ->
      ( None, Cmd.none )

-- VIEW

view : Model -> Html Msg
view model =
  case model of
    None ->
      div [] [
        input [ placeholder "+44... or client:...", onInput DialInput ] [],
        button [ disabled True ] [ text "Call" ]
      ]
    Dialling callee ->
      div [] [
        input [ value callee, onInput DialInput ] [],
        button [ onClick (RequestCall callee) ] [ text "Call" ]
      ]
