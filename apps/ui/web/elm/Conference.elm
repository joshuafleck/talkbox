module Conference exposing (..)

import Json.Decode as JsDecode

type alias CallLeg =
  { identifier : String
  , call_status : String
  , call_sid : String
  }

type alias Conference =
  { identifier : String
  , chair : CallLeg
  , pending_participant : CallLeg
  , participants : List CallLeg
  }

type Model
  = InProgress Conference
  | None

type alias Response =
  { message : String
  , conference : Conference
  }

decodeResponse: JsDecode.Decoder Response
decodeResponse =
    JsDecode.map2 Response
      (JsDecode.field "message" JsDecode.string)
      (JsDecode.field "conference" decodeConference)

decodeConference: JsDecode.Decoder Conference
decodeConference =
  JsDecode.map4 Conference
    (JsDecode.field "identifier" JsDecode.string)
    (JsDecode.field "chair" decodeCallLeg)
    (JsDecode.field "pending_participant" decodeCallLeg)
    (JsDecode.field "participants" decodeParticipants)

decodeCallLeg: JsDecode.Decoder CallLeg
decodeCallLeg =
  JsDecode.map3 CallLeg
    (JsDecode.field "identifier" JsDecode.string)
    (JsDecode.field "call_status" JsDecode.string)
    (JsDecode.field "call_sid" JsDecode.string)

decodeParticipants: JsDecode.Decoder (List CallLeg)
decodeParticipants =
  JsDecode.list decodeCallLeg
