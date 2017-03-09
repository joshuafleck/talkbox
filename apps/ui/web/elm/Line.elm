module Line exposing (..)
-- Provides the ability to enter a phone number or client name and request to call them

import Html exposing (..)
import Html.Attributes exposing (placeholder, value, disabled, class, type_)
import Html.Events exposing (onInput, onSubmit)


-- MODEL

type alias Callee
    = String

type alias Model
    = Callee


-- UPDATE

type Msg
  = DialInput Callee
  | RequestCall


update : Msg -> Model -> ( Model, Cmd Msg )
update message model =
  case message of
    DialInput callee ->
      ( callee, Cmd.none )

    RequestCall ->
      ( "", Cmd.none )


-- VIEW

view : Model -> Html Msg
view model =
  form [ class "form-inline"
       , onSubmit RequestCall
       ]
       [ div [ class "form-group" ]
             [ input [ class "form-control"
                     , value model
                     , placeholder "+44... or name"
                     , onInput DialInput
                     ]
                     [ ]
             ]
       , button [ type_ "submit"
                , class "btn btn-default"
                ]
                [ text "Call" ]
       ]
