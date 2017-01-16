module Quad exposing (..)

import Html exposing (Html, div)
import Html.App as App
import Html.Events exposing (onClick)

import String exposing (append)

import Math.Vector2 as Vec2 exposing (Vec2, vec2, getX, getY, scale, sub)

import Time exposing (Time, second)
--import Random.Pcg as R
import Random as R

import Color exposing (..)
import Color.Manipulate exposing (darken, lighten, saturate, desaturate, weightedMix)

import Collage as C exposing (defaultLine)
import Element
import List as L
import Bitwise exposing (..)
import Keyboard as Key
import Mouse exposing (..)


-- Could add "freeze" command
-- Could add instructions

type alias Model = (Point, QuadTree)

type Msg
  = MousePos Point

type alias Point =
  { x : Float
  , y : Float
  }

type alias Region =
  { size : Float
  , lowerLeft : Point
  }
    

type QuadTree
  = QNode Region QuadTree QuadTree QuadTree QuadTree
  | Leaf Region

animationSpeed = 0.1
createSpeed = 0.01
progressUpdateDelta = 0.2
depthScale = 0.5
maxQuadTreeDepth = 25
zeroPoint = { x = 0.0, y = 0.0 }
regionColor = orange

xW = 0
yW = 0
widthW  = 1000
heightW = 1000
viewBoxDims = L.foldl (++) "" <| L.map toString [xW, yW, widthW, heightW]
maxDim = widthW

{- Circles -}

drawRegion depth { size, lowerLeft } =
  let offset = (widthW / 2) - (size/2)
      rectangle = C.rect size size
      col = weightedMix  regionColor darkRed ((1 / (toFloat depth - 1)))
      rectForm = C.group [C.filled col <| rectangle, C.outlined C.defaultLine rectangle]
  in C.move (lowerLeft.x - offset, lowerLeft.y - offset) <| rectForm 

drawTree : QuadTree -> C.Form
drawTree tree = drawTree' tree 1

drawTree' tree depth = 
  case tree of
    Leaf region ->
      drawRegion depth region

    QNode region c1 c2 c3 c4 ->
      C.group <| [ drawTree' c1 (depth + 1)
                 , drawTree' c2 (depth + 1)
                 , drawTree' c3 (depth + 1)
                 , drawTree' c4 (depth + 1)
                 ]


withinRegion : Point -> Region -> Bool
withinRegion point { size, lowerLeft } =  
  point.x >= lowerLeft.x          &&
  point.x <  (lowerLeft.x + size) && 
  point.y >= lowerLeft.y          &&
  point.y <  (lowerLeft.y + size)

offsetPos : Point -> (Float, Float) -> Point
offsetPos {x,y} (distX, distY) = { x = x + distX, y = y + distY }

splitRegion region = 
  let size' = region.size/2
      r1 = { size = size', lowerLeft = offsetPos region.lowerLeft (0,     0)     }
      r2 = { size = size', lowerLeft = offsetPos region.lowerLeft (size', 0)     }
      r3 = { size = size', lowerLeft = offsetPos region.lowerLeft (0,     size') }
      r4 = { size = size', lowerLeft = offsetPos region.lowerLeft (size', size') }
  in (r1, r2, r3, r4)

quadTreeOnPoint : Point -> Int -> QuadTree
quadTreeOnPoint point maxDepth
  = quadTreeOnPoint' point maxDepth { size = toFloat widthW, lowerLeft = zeroPoint }

quadTreeOnPoint' point maxDepth region = 
  if withinRegion point region
    then
      case maxDepth of
        0 -> 
          Leaf region

        n ->
          let (r1, r2, r3, r4) = splitRegion region
              maxDepth' = maxDepth - 1
              q = quadTreeOnPoint' point maxDepth'
          in QNode region (q r1) (q r2) (q r3) (q r4)

    else Leaf region


{- Shading -}
apply2 f ls ls' = L.map (uncurry f) <| L.map2 (,) ls ls'

shade levels form = 
  let opacities = L.scanl (+) 0 <| L.drop 1 <| L.repeat levels (1 / toFloat levels)
      sizes     = L.reverse opacities
      forms     = L.repeat (L.length sizes) form
  in
      C.group <| apply2 C.scale sizes <| apply2 C.alpha opacities <| forms


update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    MousePos pos ->
      ((pos, quadTreeOnPoint pos maxQuadTreeDepth), Cmd.none)


toPoint { x, y } = { x = toFloat x, y = heightW - toFloat y }
subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.batch 
    [ moves (toPoint >> MousePos)
    ]

init : (Model, Cmd Msg)
init = ((zeroPoint, Leaf { size = toFloat widthW, lowerLeft = zeroPoint }), Cmd.none)

drawCircle = C.filled green <| C.circle 50

view : Model -> Html Msg
view (pos, tree) = div []
  [ Element.toHtml <| C.collage widthW heightW [drawTree tree]
  , Html.text <| toString pos
  , Html.text <| toString tree
  ]


main = App.program { init = init, view = view, update = update, subscriptions = subscriptions }

