module Ga exposing (..)

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
import TypedSvg exposing (svg, rect, linearGradient, radialGradient, stop, defs, g)
import TypedSvg.Attributes exposing (viewBox, rx, ry, width, height, fill, x, y, x1, x2, y1, y2, stopColor, fillOpacity, transform)
import TypedSvg.Types exposing (px, percent, Opacity(..), Length(..), Transform(..))
import TypedSvg.Core exposing (Svg, attribute)


type alias Model = 
  { lastTime : Time
  , mousePoint : Point
  , population : RealPop
  }

type Msg
  = Animate Time
  | MousePos Point
  | Err
  | InitTime (Maybe Time)
  | NewPopulation RealPop

type alias Point =
  { x : Float
  , y : Float
  }

type alias Vect =
  { x    : Float
  , y    : Float
  , xDir : Float
  , yDir : Float
  }


type alias RealInd =
  { genes : A.Array Float }

type alias RealPop =
  { realInds : A.Array RealInd }
    
type alias GAParams =
  { popSize : Int
  , indSize : Int
  , pm : Float
  }

gaParams =
  { popSize = populationSize
  , indSize = individualSize
  , pm = 0.01
  }

animationSpeed = 1.0
updateTime = 0.1

defaultSize = 50
defaultPoint = zeroPoint

zeroPoint = { x = 0, y = 0 }

xW = 0
yW = 0
widthW  = 1000
heightW = 1000
viewBoxDims = L.foldl (++) "" <| L.map toString [xW, yW, widthW, heightW]
maxDim = widthW

populationSize = 35 ^ 2
individualSize = 3


vec { x, y } = vec2 x y

singleton a = A.push a A.empty

{- Real-valued genetic algorithm -}
mkPopulation pop = { realInds = pop }
mkIndividual ind = { genes = ind }

defaultIndividual = mkIndividual A.empty
defaultPopulation = mkPopulation A.empty

randomArray n g = R.map A.fromList <| R.list n g

randomPopulation : Int -> Int -> R.Generator RealPop
randomPopulation n m = R.map mkPopulation <| randomArray n <| randomIndividual m

randomIndividual : Int -> R.Generator RealInd
randomIndividual n = R.map mkIndividual <| randomArray n (R.float 0.0 1.0)

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    MousePos pos ->
      ({ model | mousePoint = pos }, Cmd.none)

    Animate time ->
      (model, R.generate NewPopulation <| pointMutation model.population)

    InitTime (Just time) ->
      ({ model | lastTime = time }, Cmd.none)

    InitTime Nothing ->
      ({ model | lastTime = 0.0 }, Cmd.none)

    NewPopulation newPopulation ->
      ({ model | population = newPopulation}, Cmd.none)

    Err ->
      (model, Cmd.none)

pointMutation : RealPop -> R.Generator RealPop
pointMutation realPop = R.map (mutatePopulation realPop) <| RA.array gaParams.popSize <| RA.array gaParams.indSize <| RF.normal 0.0 0.1


mutatePopulation : RealPop -> A.Array (A.Array Float) -> RealPop
mutatePopulation pop mutes = { pop | realInds = A.map2 mutateInd pop.realInds mutes }

mutateInd : RealInd -> A.Array Float -> RealInd
mutateInd ind mutes = { ind | genes = A.map2 mutateLocus ind.genes mutes }

mutateLocus : Float -> Float -> Float
mutateLocus locus r = clamp 0 1 <| locus + r

clamp low high v = min high <| max low v

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

initTimeTask = T.perform (toSeconds >> Just >> InitTime) now
initPopulationTask = R.generate NewPopulation <| randomPopulation populationSize individualSize

init : (Model, Cmd Msg)
init = ({ lastTime = 0.0, mousePoint = zeroPoint, population = defaultPopulation },
        C.batch [initTimeTask, initPopulationTask])

grade name c1 c2 x1Input y1Input x2Input y2Input =
    linearGradient 
      [ x1 <| percent x1Input
      , y1 <| percent y1Input
      , x2 <| percent x2Input
      , y2 <| percent y2Input
      , attribute "id" name
      ]
      [ stop 
          [ stopColor c1
          , attribute "offset" "0%"
          ]
          []
      , stop 
          [ stopColor c2
          , attribute "offset" "1000%"
          ]
          []
      ]

sample gradient xPos yPos op = 
  rect 
    [ x <| px xPos
    , y <| px yPos
    , width <| px 100
    , height <| px 100
    , attribute "fill" <| S.concat <| ["url(#", gradient, ")"]
    , fillOpacity <| Opacity op
    ]
    [ 
    ]

box xPos yPos w h color op = 
  rect 
    [ x <| px xPos
    , y <| px yPos
    , width <| px w
    , height <| px h
    , fill color
    , fillOpacity <| Opacity op
    ]
    [ 
    ]

geneSize = 10.0
svgGene geneSize xIx yIx colr = box (toFloat xIx * geneSize + toFloat xIx) (toFloat yIx * geneSize + toFloat yIx) geneSize geneSize colr 1.0
rgbFloat rf gf bf = rgb (truncate <| rf * 255) (truncate <| gf * 255) (truncate <| bf * 255)

gridPopulation : Float -> RealPop -> Svg Msg
gridPopulation geneSize realPop =
  let greybox xpos ypos val = svgGene geneSize xpos ypos (greyscale val) -- box (toFloat xpos) (toFloat ypos) geneSize geneSize (greyscale val) 1.0
  in svgPopulation greybox realPop

colorPopulation : Float -> RealPop -> Svg Msg
colorPopulation geneSize realPop = 
  let colorIndividual xpos ypos ind = 
      case (A.get 0 ind.genes, A.get 1 ind.genes, A.get 2 ind.genes) of
        (Just r, Just g, Just b) ->
          svgGene geneSize xpos ypos (rgbFloat r g b)

        otherwise ->
          svgGene geneSize xpos ypos (rgb 0 0 0)
  in svgIndividuals colorIndividual realPop

svgGenes : (Int -> Int -> Float -> Svg Msg) -> Int -> RealInd -> Svg Msg
svgGenes f ypos ind = g [] <| A.toList <| A.indexedMap (\xpos val -> f xpos ypos val) ind.genes

svgPopulation : (Int -> Int -> Float -> Svg Msg) -> RealPop -> Svg Msg
svgPopulation f pop = g [] <| A.toList <| A.indexedMap (svgGenes f) pop.realInds

svgIndividuals : (Int -> Int -> RealInd -> Svg Msg) -> RealPop -> Svg Msg
svgIndividuals f pop =
  let popLen = A.length pop.realInds
      len = truncate <| sqrt <| toFloat popLen
      xPositions = L.concat <| L.repeat popLen <| L.range 0 (len-1)
      yPositions = L.concat <| L.map (L.repeat len) <| L.range 0 (len-1)
  in g [] <| L.map3 f xPositions yPositions <| A.toList pop.realInds
 
view : Model -> Html Msg
view { lastTime, mousePoint, population } = 
  let op = mousePoint.x / 800 in 
  svg 
      [ viewBox 0 0 800 800 ]
      [ defs 
          []
          [ grade "grade1" "orange"  "white"   0 0 100 100
          , grade "grade2" "green" "white" 100 0   0 100
          ]
      , g [ transform [Translate 10  10] ] [gridPopulation geneSize population]
      , g [ transform [Translate 100 10] ] [colorPopulation geneSize population]
            {-
      , sample "grade1" 350 200 op
      , sample "grade2" 350 200 op

      , sample "grade2" 200 200 op
      , sample "grade1" 200 200 op


      , sample "grade1" 350 400 op
      , sample "grade2" 350 400 op

      , sample "grade2" 200 400 op
      , sample "grade1" 200 400 op
            -}
      ]
  

main = Html.program { init = init, view = view, update = update, subscriptions = subscriptions }


