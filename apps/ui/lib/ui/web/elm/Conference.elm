module Conference exposing (..)
-- Displays the state of the conference and provides the ability to hangup call legs

import Html exposing (..)
import Html.Attributes exposing (disabled, hidden, value, class, type_)
import Html.Events exposing (onClick)

import Json.Decode as JsDecode


-- MODEL

type alias CallLeg =
    { identifier : String
    , callStatus : Maybe String
    , callSid : Maybe String
    , hangupRequested : Bool
    }


type alias Model =
    { identifier : String
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
    JsDecode.map2 Model
        (JsDecode.field "identifier" JsDecode.string)
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


update : Msg -> Model -> ( Model, Cmd Msg )
update message model =
    case message of
        Hangup callLeg ->
            ( { model
                  | participants = List.map (\participant -> findCallLegAndRequestHangup participant callLeg) model.participants
              }
            , Cmd.none
            )


findCallLegAndRequestHangup : CallLeg -> CallLeg -> CallLeg
findCallLegAndRequestHangup participant target =
    if participant == target then
        requestHangup participant
    else
        participant


requestHangup : CallLeg -> CallLeg
requestHangup callLeg =
    { callLeg | hangupRequested = True }


-- VIEW


view : Model -> Html Msg
view model =
    div [ class "list-group" ]
        (allCallLegs model)


allCallLegs : Model -> List (Html Msg)
allCallLegs model =
    List.map (\participant -> viewCallLeg participant) model.participants


viewCallLeg : CallLeg -> Html Msg
viewCallLeg callLeg =
    button [ type_ "button"
           , onClick (Hangup callLeg)
           , disabled (callLeg.hangupRequested || (callLeg.callSid == Nothing))
           , class "list-group-item"
           ]
           [ text (callLeg.identifier ++ " (" ++ (Maybe.withDefault "pending" callLeg.callStatus) ++ ")") ]
