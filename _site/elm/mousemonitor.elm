module MouseMonitor exposing (..)

import Html exposing (Html, div)
import Html
import Html.Events exposing (onClick)

import Plot

import String exposing (append)

import Math.Vector2 as V exposing (Vec2, vec2, getX, getY, scale, sub)

import Time exposing (Time, second, now, inSeconds)
--import Random.Pcg as R
import Random as R

import Color exposing (..)

import Collage as C exposing (defaultLine)
import Element
import List as L
import Bitwise exposing (..)
import Keyboard as Key
import Mouse exposing (..)
import Task as T


type alias Model = 
  { lastTime : Time
  , mousePoint : Point
  , mouseHistory : List Sample
  }

type Msg
  = Animate Time
  | MousePos Point
  | Err
  | InitTime (Maybe Time)

type alias Point =
  { x : Float
  , y : Float
  }

type alias Sample =
  { sampleTime : Time
  , sample : Point
  }

type alias Vect =
  { x    : Float
  , y    : Float
  , xDir : Float
  , yDir : Float
  }

    
animationSpeed = 10.0
updateTime = 0.1

historyFrames = 100

defaultPoint = zeroPoint

zeroPoint = { x = 0, y = 0 }
zeroSample = { sampleTime = 0.0, sample = zeroPoint }

xW = 0
yW = 0
widthW  = 1000
heightW = 1000
viewBoxDims = L.foldl (++) "" <| L.map toString [xW, yW, widthW, heightW]
maxDim = widthW



animateModel model time =
  let dt = time - model.lastTime
  in
  { model | lastTime = time
  }

pushSample n sample samples =
  if List.length samples >= n
  then
    sample :: List.take (n-1) samples
  else
    sample :: samples

mkSample time sam = {sampleTime = time, sample = sam}

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    MousePos pos ->
      ({ model | mousePoint = pos, 
                 mouseHistory = pushSample historyFrames (mkSample model.lastTime pos) model.mouseHistory
       }
      , Cmd.none
      )

    Animate time ->
      (animateModel model time, Cmd.none)

    InitTime (Just time) ->
      ({ model | lastTime = time }, Cmd.none)

    InitTime Nothing ->
      ({ model | lastTime = 0.0 }, Cmd.none)

    Err ->
      (model, Cmd.none)

toSeconds ms = ms / second

toPoint : Position -> Point
toPoint { x, y } = { x = toFloat x - (widthW / 2), y = (heightW / 2) - toFloat y }

mouseMsg pos = toPoint pos |> MousePos

subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.batch 
    [ moves mouseMsg
    , Time.every animationSpeed (Animate << toSeconds)
    ]

init : (Model, Cmd Msg)
init = ({ lastTime = 0.0, mousePoint = zeroPoint, mouseHistory = List.repeat historyFrames zeroSample},
        T.perform  (toSeconds >> Just >> InitTime) now)
      

drawCircle = C.filled green <| C.circle 50

mousePosDot point = 
  Plot.circle point.x point.y

windowEdges = [Plot.clear (negate heightW/2.0) (negate widthW/2.0), Plot.clear (heightW/2.0) (widthW/2.0)]

mousePointsPlot : List Sample -> Html msg
mousePointsPlot points =
  Plot.viewSeries
    [ (Plot.dots (\points -> windowEdges ++ List.map mousePosDot points)) ]
    (List.map .sample points)

distance p1 p2 = (p1.x-p2.x)^2 + (p1.y-p2.y)^2

pointDiff points = 
  case points of
    (a :: b :: rest) ->
      (distance a b :: pointDiff (b :: rest))

    (a :: []) ->
      []

    [] ->
      []

mouseVelPlot : List Sample -> Html msg
mouseVelPlot points =
  let vels = pointDiff <| List.map .sample points
      times = List.map .sampleTime points
      timedVels = List.map2 (\v t -> {x=inSeconds t, y=v}) vels times
  in Plot.viewSeries [Plot.line (List.map (\{x, y} -> Plot.circle x y))] timedVels

view : Model -> Html Msg
view model =
  div [] [ mousePointsPlot model.mouseHistory
         , mouseVelPlot model.mouseHistory
         , Html.text <| toString model.mousePoint
         ]


main = Html.program { init = init, view = view, update = update, subscriptions = subscriptions }


