module Split exposing (..)

import Html exposing (Html, div)
import Html.App as App
import Html.Events exposing (onClick)

import String exposing (append)

import Math.Vector2 as Vec2 exposing (Vec2, vec2, getX, getY, scale, sub)

import Time exposing (Time, second)
--import Random.Pcg as R
import Random as R

import Color exposing (..)

import Collage as C exposing (defaultLine)
import Element
import List as L
import Bitwise exposing (..)
import Keyboard as Key


-- Could add "freeze" command
-- Could add instructions

type alias Model = Tree

type Msg
  = Animate
  | Tick Time
  | CreateNew
  | TriggerNew

type alias LineSegment =
  { segStart : Vec2
  , segEnd   : Vec2
  }

type Tree
  = Node LineSegment Tree Tree
  | Leaf LineSegment

animationSpeed = 0.1
createSpeed = 0.01
progressUpdateDelta = 0.2
depthScale = 0.5

xW = 0
yW = 0
widthW  = 1000
heightW = 1000
viewBoxDims = L.foldl (++) "" <| L.map toString [xW, yW, widthW, heightW]
maxDim = widthW

{- Circles -}

progressScale : Float -> Float
progressScale progress = 1 - (abs (1 - progress * 2.0))

drawSegment seg depth = 
  let lineStyle = { defaultLine | width = 20 * (defaultLine.width / (1 + depthScale * toFloat depth)) }
  in C.traced lineStyle <| C.segment (Vec2.toTuple seg.segStart) (Vec2.toTuple seg.segEnd)

drawTree : Tree -> C.Form
drawTree tree = drawTree' tree 1

drawTree' : Tree -> Int -> C.Form
drawTree' tree depth =
  case tree of
    Leaf seg ->
      drawSegment seg depth

    Node seg child child' ->
      let depth' = depth + 1
      in C.group <| [ drawSegment seg    depth
                    , drawTree'   child  depth'
                    , drawTree'   child' depth'
                    ]

updateProgress tree = 
  case tree of
    Leaf seg ->
      let dirVec  = Vec2.normalize (seg.segEnd `Vec2.sub` seg.segStart)
          delta   = Vec2.scale progressUpdateDelta dirVec
          segEnd' = seg.segEnd `Vec2.add` delta
      in Leaf { seg | segEnd = segEnd' }

    Node seg child child' ->
      Node seg (updateProgress child) (updateProgress child')

startNew seg =
  let dir = Vec2.direction seg.segEnd seg.segStart
      dir' = Vec2.scale progressUpdateDelta dir
  in { seg | segStart = seg.segEnd, segEnd = seg.segEnd `Vec2.add` dir' }

turnAngle depth = (Basics.pi / 4) / toFloat depth

rotate seg amount =
  let dir     = Vec2.direction seg.segEnd seg.segStart
      segVec  = Vec2.sub seg.segEnd seg.segStart
      angle   = Basics.atan2 (getY segVec) (getX segVec)
      angle'  = angle + amount
      dir' = Vec2.scale (Vec2.length segVec) <| vec2 (cos angle') (sin angle')
      segEnd' = seg.segStart `Vec2.add` dir'
  in { seg | segEnd = segEnd' }

rotateAtDepth seg depth  = rotate seg <| turnAngle depth

splitTree tree = splitTree' tree 1

splitTree' tree depth =
  case tree of
    Leaf seg ->
      let newSeg = startNew seg
      in Node seg (Leaf <| rotateAtDepth newSeg           depth)
                  (Leaf <| rotateAtDepth newSeg <| negate depth)

    Node seg child child' ->
      let depth' = depth + 1
      in Node seg (splitTree' child depth') (splitTree' child' depth')

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
    Tick time ->
      (model, Cmd.none)

    Animate ->
      (updateProgress model, Cmd.none)

    TriggerNew ->
      (splitTree model, Cmd.none)

    CreateNew ->
      (model, Cmd.none)


subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.batch 
    [ Time.every second         Tick
    , Time.every animationSpeed (always Animate)
    , Key.presses (always TriggerNew)
    ]

init : (Model, Cmd Msg)
init = (Leaf { segStart = vec2 (widthW/32) 0, segEnd = vec2 (widthW/32) 0.1 }, Cmd.none)

view : Model -> Html Msg
view model = div []
  [ Element.toHtml <| C.collage widthW heightW [drawTree model]
  , Html.text <| "Press Any Key"
  ]


main = App.program { init = init, view = view, update = update, subscriptions = subscriptions }

