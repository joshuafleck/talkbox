module App exposing (..)

import Html exposing (..)
import Html.Attributes exposing (placeholder, value)
import Html.Events exposing (onClick, onInput)

import Json.Decode as JsDecode
import Json.Encode as JsEncode

import Phoenix.Socket
import Phoenix.Channel
import Phoenix.Push

import Twilio

import Line

import Conference

main =
  Html.programWithFlags
    { init = init
    , view = view
    , update = update
    , subscriptions = subscriptions
    }

-- MODEL

type alias Flags =
  { clientName : String
  }

type alias Model =
  { phxSocket : Phoenix.Socket.Socket Msg
  , status : String
  , clientName : String
  , twilioStatus : String
  , line : Line.Model
  , conference : Maybe Conference.Model
  , conferenceStatus : String
  }

clientsChannel : String -> String
clientsChannel clientName =
  "twilio:" ++ clientName

init : Flags -> (Model, Cmd Msg)
init flags =
  let
    channel =
      Phoenix.Channel.init (clientsChannel flags.clientName)
    (initSocket, phxCmd) =
      Phoenix.Socket.init "ws://localhost:5000/socket/websocket"
      |> Phoenix.Socket.withDebug
      |> Phoenix.Socket.on "call_ended" (clientsChannel flags.clientName) CallEnded
      |> Phoenix.Socket.on "call_status_changed" (clientsChannel flags.clientName) CallStatusChanged
      |> Phoenix.Socket.on "conference_changed" (clientsChannel flags.clientName) ConferenceChanged
      |> Phoenix.Socket.on "set_token" (clientsChannel flags.clientName) SetupTwilio
      |> Phoenix.Socket.join channel
    model =
      { phxSocket = initSocket
      , status = "All good"
      , clientName = flags.clientName
      , twilioStatus = "All good"
      , line = Line.initialModel
      , conference = Nothing
      , conferenceStatus = "All good"
      }
  in
    ( model, Cmd.map PhoenixMsg phxCmd )

-- UPDATE

type Msg
  = PhoenixMsg (Phoenix.Socket.Msg Msg)
  | CallEnded JsEncode.Value
  | CallStatusChanged JsEncode.Value
  | ConferenceChanged JsEncode.Value
  | CallRequestFailed JsEncode.Value
  | TwilioStatusChanged String
  | SetupTwilio JsEncode.Value
  | LineMsg Line.Msg
  | ConferenceMsg Conference.Msg

-- TODO: extract these into a Cmd.elm file??
sendStartCall : Model -> Line.Callee -> (Phoenix.Socket.Socket Msg, Cmd (Phoenix.Socket.Msg Msg))
sendStartCall model callee =
  let
    payload = (encodedCall callee model.clientName)
    phxPush =
      Phoenix.Push.init "start_call" (clientsChannel model.clientName)
        |> Phoenix.Push.withPayload payload
        |> Phoenix.Push.onOk CallStatusChanged
        |> Phoenix.Push.onError CallRequestFailed
    (phxSocket, phxCmd) = Phoenix.Socket.push phxPush model.phxSocket
  in
    ( phxSocket, phxCmd )

sendEndCall : Model -> Line.CallInfo -> (Phoenix.Socket.Socket Msg, Cmd (Phoenix.Socket.Msg Msg))
sendEndCall model callInfo =
  let
    payload = (encodedCallEnd callInfo.sid)
    phxPush =
      Phoenix.Push.init "end_call" (clientsChannel model.clientName)
        |> Phoenix.Push.withPayload payload
        |> Phoenix.Push.onOk CallEnded
        |> Phoenix.Push.onError CallRequestFailed
    (phxSocket, phxCmd) = Phoenix.Socket.push phxPush model.phxSocket
  in
    ( phxSocket, phxCmd )

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    CallStatusChanged raw ->
      let
        decodeResult = JsDecode.decodeValue decodeCall raw
      in
        case decodeResult of
          Ok callInfo ->
            let
              ( updatedLineModel, lineCmd ) =
                Line.update (Line.CallStarted callInfo) model.line
            in
              (
                { model | status = "Call with sid " ++ callInfo.sid ++ " " ++ callInfo.status, line = updatedLineModel },
                Cmd.map LineMsg lineCmd
              )
          Err error ->
            ({ model | status = "Failed to decode call: " ++ error }, Cmd.none )
    CallEnded raw ->
      let
        ( updatedLineModel, lineCmd ) =
          Line.update Line.CallEnded model.line
      in
      (
        { model | status = "Call ended", line = updatedLineModel },
        Cmd.map LineMsg lineCmd
      )
    TwilioStatusChanged twilioStatus ->
      (
        { model | twilioStatus = twilioStatus },
        Cmd.none
      )
    SetupTwilio raw ->
      let
        decodeResult = JsDecode.decodeValue decodeTwilioToken raw
      in
        case decodeResult of
          Ok token ->
            (
              { model | status = "Twilio token received" },
              Twilio.setup token
            )
          Err error ->
            ({ model | status = error }, Cmd.none )
    ConferenceChanged raw ->
      let
        decodeResult = JsDecode.decodeValue Conference.decodeResponse raw
      in
        case decodeResult of
          Ok response ->
            (
              { model | conference = response.conference, conferenceStatus = response.message },
              Cmd.none
            )
          Err error ->
            ({ model | status = error }, Cmd.none )
    CallRequestFailed raw ->
      let
        decodeResult = JsDecode.decodeValue decodeCallRequestFailure raw
      in
        case decodeResult of
          Ok message ->
            let
              ( updatedLineModel, lineCmd ) =
                Line.update Line.CallRequestFailed model.line
            in
            (
              { model | status = message, line = updatedLineModel },
              Cmd.map LineMsg lineCmd
            )
          Err error ->
            ({ model | status = "Failed to decode call request failure: " ++ error }, Cmd.none )
    LineMsg subMsg ->
      let
          ( updatedLineModel, lineCmd ) =
              Line.update subMsg model.line
          ( phxSocket, phxCmd ) =
            case subMsg of
              (Line.RequestCall callee) ->
                sendStartCall model callee
              (Line.EndCall callInfo) ->
                sendEndCall model callInfo
              _ ->
                ( model.phxSocket, Cmd.none )
        in
            ( { model | line = updatedLineModel, phxSocket = phxSocket }, Cmd.batch [ Cmd.map LineMsg lineCmd, Cmd.map PhoenixMsg phxCmd ] )
    ConferenceMsg subMsg ->
      case model.conference of
        Nothing ->
          (model, Cmd.none)
        Just conference ->
          let
              ( updatedConferenceModel, conferenceCmd ) =
                  Conference.update subMsg conference
              ( phxSocket, phxCmd ) =
                case subMsg of
                  --(Conference.RequestCall callee) ->
                  --  sendStartCall model callee
                  --(Conference.EndCall callInfo) ->
                  --  sendEndCall model callInfo
                  _ ->
                    ( model.phxSocket, Cmd.none )
            in
                ( { model | conference = Just updatedConferenceModel, phxSocket = phxSocket }, Cmd.batch [ Cmd.map ConferenceMsg conferenceCmd, Cmd.map PhoenixMsg phxCmd ] )
    PhoenixMsg msg ->
      let
        ( phxSocket, phxCmd ) = Phoenix.Socket.update msg model.phxSocket
      in
        ( { model | phxSocket = phxSocket }
          , Cmd.map PhoenixMsg phxCmd
        )

-- VIEW

view : Model -> Html Msg
view model =
  div [] [
      h4 [] [ text "Elm" ]
    , p [] [ text model.status ]
    , h4 [] [ text "Twilio" ]
    , p [] [ text (toString model.twilioStatus) ]
    , h4 [] [ text "Conference" ]
    , p [] [ text (toString model.conferenceStatus) ]
    , case model.conference of
        Nothing ->
          p [] [ text "no conference yet" ]
        Just conference ->
          Html.map ConferenceMsg (Conference.view conference)
    , Html.map LineMsg (Line.view model.line)
  ]

-- SUBSCRIPTIONS

subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.batch
    [ Twilio.statusChanged TwilioStatusChanged
    , Phoenix.Socket.listen model.phxSocket PhoenixMsg
    ]

-- HTTP

encodedCall: String -> String -> JsDecode.Value
encodedCall callee caller =
    JsEncode.object
      [ ("callee", JsEncode.string callee)
      , ("caller", JsEncode.string caller)]

encodedCallEnd: String -> JsDecode.Value
encodedCallEnd sid =
    JsEncode.object
      [ ("sid", JsEncode.string sid) ]

decodeCall: JsDecode.Decoder Line.CallInfo
decodeCall =
  JsDecode.map3 Line.CallInfo
    (JsDecode.field "sid" JsDecode.string)
    (JsDecode.field "status" JsDecode.string)
    (JsDecode.field "callee" JsDecode.string)

decodeCallRequestFailure: JsDecode.Decoder String
decodeCallRequestFailure =
  JsDecode.at ["reason"] JsDecode.string

decodeTwilioToken: JsDecode.Decoder String
decodeTwilioToken =
  JsDecode.at ["token"] JsDecode.string
