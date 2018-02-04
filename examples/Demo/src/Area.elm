module Area exposing (Model, init, Msg, update, view)

import Html
import Time
import Random
import LineChart
import LineChart.Junk as Junk
import LineChart.Area as Area
import LineChart.Axis as Axis
import LineChart.Junk as Junk
import LineChart.Dots as Dots
import LineChart.Grid as Grid
import LineChart.Dots as Dots
import LineChart.Line as Line
import LineChart.Colors as Colors
import LineChart.Events as Events
import LineChart.Legends as Legends
import LineChart.Container as Container
import LineChart.Coordinate as Coordinate
import LineChart.Interpolation as Interpolation
import LineChart.Axis.Intersection as Intersection



main : Program Never Model Msg
main =
  Html.program
    { init = init
    , update = update
    , view = view
    , subscriptions = always Sub.none
    }



-- MODEL


type alias Model =
    { data : Data
    , hinted : Maybe Coordinate.Point
    }


type alias Data =
  { alice : List Coordinate.Point
  , bobby : List Coordinate.Point
  , chuck : List Coordinate.Point
  }



-- INIT


init : ( Model, Cmd Msg )
init =
  ( { data = Data [] [] []
    , hinted = Nothing
    }
  , getNumbers
  )


getNumbers : Cmd Msg
getNumbers =
  let
    genNumbers =
      Random.list 40 (Random.float 5 20)
  in
  Random.map3 (,,) genNumbers genNumbers genNumbers
    |> Random.generate RecieveNumbers



-- API


setData : ( List Float, List Float, List Float ) -> Model -> Model
setData ( n1, n2, n3 ) model =
  { model | data = Data (toData n1) (toData n2) (toData n3) }


toData : List Float -> List Coordinate.Point
toData numbers =
  List.indexedMap (\i -> Coordinate.Point (toDate i)) numbers


toDate : Int -> Time.Time
toDate index =
  Time.hour * 24 * 256 * 40 + Time.hour * 24 * 21 * toFloat index


setHint : Maybe Coordinate.Point -> Model -> Model
setHint hinted model =
  { model | hinted = hinted }



-- UPDATE


type Msg
  = RecieveNumbers ( List Float, List Float, List Float )
  | Hint (Maybe Coordinate.Point)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
  case msg of
    RecieveNumbers numbers ->
      model
        |> setData numbers
        |> addCmd Cmd.none

    Hint point ->
      model
        |> setHint point
        |> addCmd Cmd.none


addCmd : Cmd Msg -> Model -> ( Model, Cmd Msg )
addCmd cmd model =
  ( model, Cmd.none )



-- VIEW


view : Model -> Html.Html Msg
view model =
  Html.div [] [ chart model ]



-- CHART


chart : Model -> Html.Html Msg
chart model =
  LineChart.viewCustom
    { y = Axis.default 450 "cash" .y
    , x = Axis.time 1270 "time" .x
    , container =
        Container.custom
          { attributesHtml = []
          , attributesSvg = []
          , size = Container.static
          , margin = Container.Margin 30 100 60 50
          , id = "line-chart-area"
          }
    , interpolation = Interpolation.monotone
    , intersection = Intersection.default
    , legends = Legends.default
    , events = Events.hoverOne Hint
    , junk =
        Junk.hoverOne model.hinted
          [ ( "x", toString << round100 << .x )
          , ( "y", toString << round100 << .y )
          ]
    , grid = Grid.dots 1 Colors.gray
    , area = Area.stacked 0.5
    , line = Line.default
    , dots = Dots.custom (Dots.empty 5 1)
    }
    [ LineChart.line Colors.pink Dots.diamond "Alice" model.data.alice
    , LineChart.line Colors.red Dots.circle "Bobby" model.data.bobby
    , LineChart.line Colors.purple Dots.triangle "Chuck" model.data.chuck
    ]



-- UTILS


round100 : Float -> Float
round100 float =
  toFloat (round (float * 100)) / 100