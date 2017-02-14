module Line exposing (..)
-- Provides the ability to enter a phone number or client name and request to call them

import Html exposing (..)
import Html.Attributes exposing (placeholder, value, disabled, class, type_)
import Html.Events exposing (onInput, onSubmit)

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
      form [ class "form-inline" ] [
          div [ class "form-group" ] [
            input [ class "form-control", placeholder "+44... or name", onInput DialInput ] []
          ]
        , button [ disabled True, type_ "submit", class "btn btn-default" ] [ text "Call" ]
      ]
    Dialling callee ->
      form [ class "form-inline", onSubmit (RequestCall callee) ] [
          div [ class "form-group" ] [
            input [ class "form-control", value callee, onInput DialInput ] []
          ]
        , button [ type_ "submit", class "btn btn-default" ] [ text "Call" ]
      ]
