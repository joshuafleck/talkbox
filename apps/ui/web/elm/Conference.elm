module Conference exposing (..)

import Html exposing (..)
import Html.Attributes exposing (disabled, hidden)
import Html.Events exposing (onClick)

import Json.Decode as JsDecode

-- MODEL

type alias CallLeg =
  { identifier : String
  , call_status : Maybe String
  , call_sid : Maybe String
  , hangup_requested : Bool
  }

type alias Model =
  { identifier : String
  , chair : CallLeg
  , pending_participant : Maybe CallLeg
  , participants : List CallLeg
  }

type alias Response =
  { message : String
  , conference : Maybe Model
  }

decodeResponse: JsDecode.Decoder Response
decodeResponse =
    JsDecode.map2 Response
      (JsDecode.field "message" JsDecode.string)
      (JsDecode.maybe (JsDecode.field "conference" decodeConference))

decodeConference: JsDecode.Decoder Model
decodeConference =
  JsDecode.map4 Model
    (JsDecode.field "identifier" JsDecode.string)
    (JsDecode.field "chair" decodeCallLeg)
    (JsDecode.maybe (JsDecode.field "pending_participant" decodeCallLeg))
    (JsDecode.field "participants" decodeParticipants)

decodeCallLeg: JsDecode.Decoder CallLeg
decodeCallLeg =
  JsDecode.map4 CallLeg
    (JsDecode.field "identifier" JsDecode.string)
    (JsDecode.maybe (JsDecode.field "call_status" JsDecode.string))
    (JsDecode.maybe (JsDecode.field "call_sid" JsDecode.string))
    (JsDecode.succeed False)

decodeParticipants: JsDecode.Decoder (List CallLeg)
decodeParticipants =
  JsDecode.list decodeCallLeg

-- UPDATE

type Msg
  = Hangup CallLeg
  | Cancel CallLeg

update : Msg -> Model -> ( Model, Cmd Msg )
update message model =
  case message of
    Hangup callLeg ->
      ( { model | participants = List.map (\participant -> findCallLegAndRequestHangup participant callLeg) model.participants }, Cmd.none )
    Cancel callLeg ->
      ( { model | pending_participant = Just (requestHangup callLeg) }, Cmd.none )

findCallLegAndRequestHangup : CallLeg -> CallLeg -> CallLeg
findCallLegAndRequestHangup participant target =
  if participant == target
  then requestHangup participant
  else participant

requestHangup : CallLeg -> CallLeg
requestHangup callLeg =
  { callLeg | hangup_requested = True }

---- VIEW

type CallLegType
  = Chair
  | Participant
  | PendingParticipant

view : Model -> Html Msg
view model =
  ul [] [
      li [] [ b [] [ text "Identifier: " ], text model.identifier ]
    , li [] [ b [] [ text "Chair: " ], viewCallLeg model.chair Chair ]
    , li [] [ b [] [ text "Participants: " ] ]
    , ul [] (List.map (\participant -> viewCallLeg participant Participant) model.participants)
    , case model.pending_participant of
      Just callLeg ->
        li [] [ b [] [ text "Pending participant: " ], viewCallLeg callLeg PendingParticipant ]
      Nothing ->
        li [] [ text "This should be an input to dial" ]
  ]

viewCallLeg : CallLeg -> CallLegType -> Html Msg
viewCallLeg callLeg callLegType =
  ul [] [
      li [] [ b [] [ text "Identifier: " ], text callLeg.identifier ]
    , li [] [ b [] [ text "Status: " ], text (Maybe.withDefault "" callLeg.call_status) ]
    , li [] [ b [] [ text "Sid: " ], text (Maybe.withDefault "" callLeg.call_sid) ]
    , li [] [ case callLegType of
      Chair ->
        button [ hidden True ] [ text "Hang up" ]
      Participant ->
        button [ onClick (Hangup callLeg), disabled (callLeg.hangup_requested || (callLeg.call_sid == Nothing)) ] [ text "Hang up" ]
      PendingParticipant ->
        button [ onClick (Cancel callLeg), disabled (callLeg.hangup_requested || (callLeg.call_sid == Nothing)) ] [ text "Hang up" ] ]
  ]
