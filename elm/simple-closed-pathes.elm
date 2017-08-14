module SimpleClosedPathes exposing (..)

import Html exposing (Html, div)
import Html.Events exposing (onClick)

import String exposing (append)
import String as S

import Math.Vector2 as V exposing (Vec2, vec2, getX, getY, scale, sub)

import Time exposing (Time, second, now)
--import Random.Pcg as R
import Random as R
import Random.Float as RF
import Random.Array as RA
import Array as A
import Array.Extra as A
import Platform.Cmd as C

import Color exposing (..)

import List as L
import Bitwise exposing (..)
import Keyboard as Key
import Mouse exposing (..)
import Task as T
import TypedSvg exposing (svg, rect, line, linearGradient, radialGradient, stop, defs, g)
import TypedSvg.Attributes exposing (viewBox, rx, ry, width, height, fill, x, y, x1, x2, y1, y2, stopColor, fillOpacity, transform, stroke, strokeWidth)
import TypedSvg.Types exposing (px, percent, Opacity(..), Length(..), Transform(..))
import TypedSvg.Core exposing (Svg, attribute, text)
import TypedSvg.Filters.Attributes as SvgAttr

import Debug exposing (log)

-- TODO port to using OpenSolid and OpenSolid.Svg
-- for geometry and visualization

type alias Model = 
  { lastTime : Time
  , mousePoint : Point
  , points : List Point
  }

type Msg
  = Animate Time
  | MousePos Point
  | Err
  | InitTime (Maybe Time)
  | NewPoints (List Point)

type alias Point =
  { x : Float
  , y : Float
  }


animationSpeed = 1.0
updateTime = 0.1

defaultSize = 50
defaultPoint = zeroPoint
defaultPoints = []

zeroPoint = { x = 0, y = 0 }

numPoints = 10
point x y = { x = x, y = y }

xW = 0
yW = 0
widthW  = 1000
heightW = 1000
viewBoxDims = L.foldl (++) "" <| L.map toString [xW, yW, widthW, heightW]
maxDim = widthW


vec { x, y } = vec2 x y

clamp low high v = min high <| max low v

toSeconds ms = ms / second

toPoint : Position -> Point
toPoint { x, y } = { x = toFloat x - (widthW / 2), y = (heightW / 2) - toFloat y }

-- mouseMsg pos = toPoint pos |> MousePos
mouseMsg {x, y} = log "mouse" <| MousePos { x = toFloat x, y = toFloat y }

subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.batch 
    [ moves mouseMsg
    , Time.every animationSpeed (Animate << toSeconds)
    ]

randomPoints w h n =
  let rWidth  =  R.float 0 w
      rHeight =  R.float 0 h 
  in R.list n <| R.map2 point rWidth rHeight

initTimeTask = T.perform (toSeconds >> Just >> InitTime) now
initPopulationTask =
  let genPoints = randomPoints widthW heightW numPoints
  in R.generate NewPoints genPoints

init : (Model, Cmd Msg)
init = ({ lastTime = 0.0, mousePoint = zeroPoint, points = defaultPoints },
        C.batch [initTimeTask, initPopulationTask])

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    MousePos pos ->
      ({ model | mousePoint = pos }, Cmd.none)

    Animate time ->
      (model, Cmd.none) -- Note - this is a place to put a new set of points

    InitTime (Just time) ->
      ({ model | lastTime = time }, Cmd.none)

    InitTime Nothing ->
      ({ model | lastTime = 0.0 }, Cmd.none)

    NewPoints newPoints ->
      ({ model | points = newPoints }, Cmd.none)

    Err ->
      (model, Cmd.none)

rgbFloat rf gf bf = rgb (truncate <| rf * 255) (truncate <| gf * 255) (truncate <| bf * 255)

simpleClosedPathes : Point -> List Point -> (Point, List Point)
simpleClosedPathes anchor points = 
  let withAngles = L.map2 (,) points <| L.map (angleBetween anchor) points
      sorted = L.sortBy Tuple.second withAngles
  in (anchor, L.map Tuple.first sorted)

angleBetween p1 p2 = atan2 (p2.y - p1.y) (p2.x - p1.x)

maybeDraw : (a -> List b) -> Maybe a -> List b
maybeDraw f ma = 
  case ma of
    Nothing ->
      []
    
    Just p ->
      f p

drawLines : (Point, List Point) -> List (Svg msg)
drawLines (p, ps) = L.map (drawLine p) <| ps

drawLine : Point -> Point -> Svg msg
drawLine p1 p2 =
  line [ x1 <| px p1.x
       , y1 <| px p1.y
       , x2 <| px p2.x
       , y2 <| px p2.y
       , stroke black
       , strokeWidth <| px 1
       ]
       []

view : Model -> Html Msg
view { lastTime, mousePoint, points } = 
  svg 
      [ viewBox 0 0 widthW heightW ]
      [ g [ ] <| drawLines <| simpleClosedPathes mousePoint points
      --, g []
      --    [ line [ x1 <| px 100.0
      --           , y1 <| px 100.0
      --           , x2 <| px 800.0
      --           , y2 <| px 800.0
      --           , stroke black
      --           , strokeWidth <| px 1
      --           ]
      --           []
      --    ]
      ]
  
main = Html.program { init = init, view = view, update = update, subscriptions = subscriptions }


