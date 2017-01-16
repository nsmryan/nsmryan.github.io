import Html exposing (Html, div)
import Html.App as App
import Html.Events exposing (onClick)

import String exposing (append)

import Math.Vector2 as Vec2 exposing (Vec2, vec2, getX, getY, scale, sub)

import Svg exposing (..)
import Svg.Attributes exposing (..)

import Time exposing (Time, second)
import Random.Pcg as Random

import Color exposing (..)

import Collage
import Element
import Window


type alias Model = GridLines

type Msg
  = Animate
  | Tick Time
  | CreateLine Bool
  | TriggerLine
  | AddLine Line

type alias Box =
  { pos  : Vec2
  , dims : Vec2
  }

type Polygon
  = Leaf Vec2 Vec2
  | Node Polygon Polygon

type alias Line =
  { segStart : Vec2
  , segEnd   : Vec2
  , progress : Float
  }
type alias GridLines = List Line

type alias Grid =
  { spacing : Float
  , length  : Int
  }

type Direction
 = Up
 | Down
 | Left
 | Right


hexOrange  = 0xC94047
hexOrange2 = 0xFF7400
hexBlue    = 0x6Ba5CE
hexGreen   = 0x8E933F
hexRed     = 0x0C4047

animationSpeed = 0.2
lineCreateSpeed = 0.1
lineCreateProb = 0.1
maxNumLines = 150

xW = 0
yW = 0
widthW  = 1000
heightW = 1000
viewBoxDims = List.foldl (++) "" <| List.map toString [xW, yW, widthW, heightW]
maxDim = widthW
circleColor = darkGray

{- Line Grid -}

grid = Grid 10 50

progressLine line = { line | progress = Basics.min 1.0 (line.progress + 0.001) }
vecPair vec = (getX vec, getY vec)
testCreateLine p = p < lineCreateProb
offsetToPos offset = toFloat offset * grid.spacing

lineFinished {progress} = progress /= 1.0

randomLine = 
  let rDir = Random.sample [Up, Down, Left, Right]
      rOffset = Random.int 0 (grid.length)
      rCell = Random.map2 (,) rOffset rOffset
      mkLine cell dir offset =
        let segStart = vec2 (offsetToPos (fst cell)) (offsetToPos (snd cell))
            segEnd   = segStart `Vec2.add` Vec2.scale (offsetToPos offset) directionVector
            directionVector = dirVec dir
        in { segStart = segStart, segEnd = segEnd, progress = 0.0 }
      dirVec dir =
        case Maybe.withDefault Up dir of
          Up    -> vec2 0    1
          Down  -> vec2 0    (-1)
          Left  -> vec2 (-1) 0
          Right -> vec2 1    0
  in Random.map3 mkLine rCell rDir rOffset

lineScale progress = 1 - (abs (1 - progress * 2.0))

drawLine { segStart, segEnd, progress } = 
  let beforeMid = progress < 0.5
      dirLine = if beforeMid 
                then segEnd   `sub` segStart
                else segStart `sub` segEnd
      currentScale = lineScale progress
      line = Vec2.scale currentScale dirLine
      startPoint = if beforeMid
                      then segStart
                      else segEnd
      endPoint = startPoint `Vec2.add` line
      segment = Collage.segment (vecPair startPoint) (vecPair endPoint)
  in Collage.traced Collage.defaultLine segment

drawLineGrid lineGrid =
  Collage.group <| List.map drawLine lineGrid

{- Circles -}
drawCircle radius = 
  let circleForm = Collage.filled circleColor <| Collage.circle radius 
  in Collage.group <| shade 25 circleForm

apply2 f ls ls' = List.map (uncurry f) <| List.map2 (,) ls ls'

shade levels form = 
  let opacities = List.scanl (+) 0 <| List.drop 1 <| List.repeat levels (1 / toFloat levels)
      sizes     = List.reverse opacities
      forms     = List.repeat (List.length sizes) form
  in
      apply2 Collage.scale sizes <| apply2 Collage.alpha opacities <| forms

{- Polygons -}
unitBox = Node (Node (Leaf (vec2 0 0) (vec2 1 0))
                     (Leaf (vec2 1 0) (vec2 1 1)))
               (Node (Leaf (vec2 1 1) (vec2 0 1))
                     (Leaf (vec2 0 1) (vec2 0 0)))

listCorners : Polygon -> List (Float, Float)
listCorners polygon =
  case polygon of
    (Leaf st end) ->
      [(getX st, getY st)]

    (Node c  c')  ->
      listCorners c ++ listCorners c'

polygonStyle = Collage.defaultLine

drawPolygon polygon =
  Collage.outlined polygonStyle <| Collage.polygon <| listCorners polygon

scalePolygon a b polygon =
  case polygon of
    Leaf st end ->
      Leaf (vec2 (getX st  * a)  (getY st * b))
                        (vec2 (getX end * a) (getY end * b))
    Node c c'   ->
      Node (scalePolygon a b c) (scalePolygon a b c')

randomPolgon a b =
  let rvec  = randomVec2 a b
      rleaf = Random.map2 Leaf rvec rvec
      rnode = Random.map2 Node rleaf rleaf
  in Random.map2 Node rnode rnode

{- Boxes -}
zero2 = vec2 0.0 0.0
initBox = mkBox zero2 zero2

mkBox pos dims = { pos = pos
                 , dims = dims
                 }

drawBox box = 
  let rectangle = Collage.rect (getX box.dims) (getY box.dims)
      offset = Collage.move (getX box.dims, getY box.dims)
  in Collage.filled blue rectangle |> offset

randomVec2 a b = Random.map2 vec2 (Random.float a b) (Random.float a b)
randomBox a b =
  let rvec = randomVec2 a b
  in Random.map2 mkBox rvec rvec

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    Tick time ->
      (model, Cmd.none)

    Animate ->
      (List.filter lineFinished <| List.map progressLine model, Cmd.none)
      --(model, Random.generate CreateLine (Random.map |> lineCreateProb) <| Random.float 0 1))

    TriggerLine ->
      (model, Random.generate CreateLine (Random.map testCreateLine <| (Random.float 0 1)))

    AddLine line ->
      (if List.length model < maxNumLines then line :: model else model, Cmd.none)

    CreateLine b ->
      case b of
        True  ->
          (model, Random.generate AddLine randomLine)

        False ->
          (model, Cmd.none)

    --Room poly ->
    --  (poly, Cmd.none)

subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.batch 
    [ Time.every second Tick
    , Time.every animationSpeed  (always Animate)
    , Time.every lineCreateSpeed (always TriggerLine)
    ]

init : (Model, Cmd Msg)
init = ([{segStart = vec2 10 100, segEnd = vec2 10 10, progress = 0.0 }], Cmd.none)
--init = (scalePolygon 50 20 unitBox, Cmd.none)

view : Model -> Html Msg
view model = div []
  -- [ svg [viewBox viewBoxDims, width "300px"] [drawBox model]
  -- [ Element.toHtml <| Collage.collage widthW heightW [drawPolygon <| model]
  --[ Element.toHtml <| Collage.collage widthW heightW [drawCircle 100]
  [ Element.toHtml <| Collage.collage widthW heightW [drawLineGrid model]
  --, text <| toString model
  ]


main = App.program { init = init, view = view, update = update, subscriptions = subscriptions }

