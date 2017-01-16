module BT exposing (..)

import Html exposing (Html, div)
import Html.App as App
import Html.Events exposing (onClick)

import String exposing (append)

import Tuple

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
import Mouse exposing (..)


type alias Model = (List Follower, Position)

type Msg
  = Animate
  | MousePos Position
  | CreateFollower

type alias Point =
  { x : Float
  , y : Float
  }

type alias Follower = Position


type BTResult =  BTFailure | BTSuccess

type BTState = BTReturn BTResult | BTWait

type alias BTChildren s = List (BT s)

type alias BTAction s = 
  BTResult -> (BTChildren s) -> (BT s, BTChildren s)

type alias BTDecorate s = 
  BTResult -> BT s -> BTResult

type BT s
  = Select (BTChildren s)
  | Sequence (BTChildren s)
  | RepeatWhile (BT s)
  | Leaf (s -> (BTState, s))


type Behavior s =
  Behavior s (BT s) (List (BT s))

behave bt s = Behavior s bt []

step (Behavior s bt frames) = 
  case bt of
    Select children ->
      case children of
        [] ->
          step (retrace BTFailure s frames)

        (a :: rest) ->
          step (Behavior s a (Select rest :: frames)

    Sequence children -> 
      case children of
        [] ->
          step (retrace BTSuccess s frames)

        (a :: rest) ->
          step (Behavior s a (Sequence rest :: frames)

    RepeatWhile bt' ->
      step (Behavior s bt' (RepeatWhile bt' :: frames)

    BTLeaf f -> 
      case f s of
        (BTReturn result, s') ->
          step (retrace result s' rest)

        (BTWait, s') ->
          Behavior s' bt frames

retrace : BTResult -> s -> [BT s] -> Behavior s
retrace result s frames = 
  case frames of
    [] ->
      Behavior s (Leaf waiter) []

    (a :: rest) ->
      case a of
        Select children ->
          case result of
            BTFailure ->
              Behavior s (Select children) rest

            BTSuccess ->
              retrace BTSuccess s rest

        Sequence children -> 
          case result of
            BTFailure ->
              retrace BTFailure s rest

            BTSuccess ->
              Behavior s (Sequence children) rest

        RepeatWhile bt -> 
          case result of
            BTFailure ->
              retrace result s rest

            BTSuccess ->
              Behavior s (RepeatWhile bt) rest

        Leaf f -> 
          Behavior s (Leaf f) rest

waiter s = (BTWait, s)

animationSpeed = 0.1

zeroPoint = { x = 0, y = 0 }

xW = 0
yW = 0
widthW  = 1000
heightW = 1000
viewBoxDims = L.foldl (++) "" <| L.map toString [xW, yW, widthW, heightW]
maxDim = widthW

{- Circles -}

drawFollower pos pos' =
  let segStart = (toFloat pos.x - (widthW/2), (heightW / 2) - toFloat pos.y)
      segEnd   = (toFloat pos'.x - (widthW/2), (heightW/ 2) - toFloat pos'.y)
  in C.traced C.defaultLine <| C.segment segStart segEnd

drawFollowers : List Follower -> C.Form
drawFollowers followers = C.group <| List.map2 drawFollower followers (List.drop 1 followers)

updateFollowers followers = followers

{- Shading -}
apply2 f ls ls' = L.map (uncurry f) <| L.map2 (,) ls ls'

shade levels form = 
  let opacities = L.scanl (+) 0 <| L.drop 1 <| L.repeat levels (1 / toFloat levels)
      sizes     = L.reverse opacities
      forms     = L.repeat (L.length sizes) form
  in
      C.group <| apply2 C.scale sizes <| apply2 C.alpha opacities <| forms

allPutLast ls = List.take (List.length ls - 1) ls

update : Msg -> Model -> (Model, Cmd Msg)
update msg (followers, pos) =
  case msg of
    MousePos pos ->
      ((followers, pos), Cmd.none)

    Animate ->
        ((updateFollowers followers, pos), Cmd.none)

    CreateFollower ->
      if List.isEmpty followers
      then
        ((List.repeat 20 pos, pos), Cmd.none)
      else
        ((allPutLast (pos::followers), pos), Cmd.none)


toPoint { x, y } = { x = toFloat x, y = heightW - toFloat y }

subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.batch 
    [ moves MousePos
    , Time.every animationSpeed (Basics.always Animate)
    ]

init : (Model, Cmd Msg)
init = (([], zeroPoint), Cmd.none)

drawCircle = C.filled green <| C.circle 50

view : Model -> Html Msg
view (followers, pos) = div []
  [ Element.toHtml <| C.collage widthW heightW [drawFollowers followers]
  ]


main = App.program { init = init, view = view, update = update, subscriptions = subscriptions }


