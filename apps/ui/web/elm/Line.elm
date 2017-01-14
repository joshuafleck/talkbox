module Line exposing (..)

import Html exposing (..)
import Html.Attributes exposing (placeholder, value, disabled)
import Html.Events exposing (onClick, onInput)

-- MODEL

type alias Callee = String

type alias CallInfo =
  { sid : String
  , status : String
  , callee : Callee
  }

type Call
  = None
  | Dialling Callee
  | Requested Callee
  | InProgress CallInfo

type alias Model = Call

initialModel : Model
initialModel = None

-- UPDATE

type Msg
  = DialInput Callee
  | RequestCall Callee
  | CallRequestFailed
  | CallStarted CallInfo
  | EndCall CallInfo
  | CallEnded

update : Msg -> Model -> ( Model, Cmd Msg )
update message model =
  case message of
    DialInput callee ->
      ( Dialling callee, Cmd.none )
    RequestCall callee ->
      ( Requested callee, Cmd.none )
    CallRequestFailed ->
      ( None, Cmd.none )
    CallStarted callInfo ->
      ( InProgress callInfo, Cmd.none )
    EndCall callInfo ->
      ( model, Cmd.none )
    CallEnded ->
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
    Requested callee ->
      div [] [
        input [ value callee, disabled True ] [],
        button [ disabled True ] [ text "Hangup" ]
      ]
    InProgress callInfo -> -- TODO: ability to mute and un-mute (through Twilio subscription/cmd)
      div [] [
        input [ value callInfo.callee, disabled True ] [],
        button [ onClick (EndCall callInfo) ] [ text "Hangup" ],
        span [] [ text callInfo.status ]
      ]
