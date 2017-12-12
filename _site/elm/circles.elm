import Html exposing (Html, div)
import Html.App as App
import Html.Events exposing (onClick)

import String exposing (append)

import Math.Vector2 as Vec2 exposing (Vec2, vec2, getX, getY, scale, sub)

import Svg exposing (..)
import Svg.Attributes exposing (..)

import Time exposing (Time, second)
import Random.Pcg as R

import Color exposing (..)
import Color.Manipulate exposing (..)
import Color.Blending exposing (..)

import Collage as C
import Element
import Window
import List as L
import Bitwise exposing (..)


type alias Model = Circles

type alias Circles = List Circle

type Msg
  = Animate
  | Tick Time
  | CreateCircle Bool
  | TriggerCircle
  | AddCircle Circle


type alias Circle =
  { centerPos : Vec2
  , radius    : Float
  , color     : Color
  , progress  : Float
  }

type ColorType
  = PureColor
  | MultColor
  | Interp
  | Darker
  | Lighter
  | Saturate
  | Desaturate
  | FadeIn
  | FadeOut
  | Mixed

hexOrange  = hexToColor 0xFF7400
hexOrange2 = hexToColor 0xA64B00
hexBlue    = hexToColor 0x6Ba5CE
hexBlue2   = hexToColor 0x73AB84
hexGreen   = hexToColor 0x8E933F
hexGreen2  = hexToColor 0x84D36E
hexRed     = hexToColor 0x0C4047
hexRed2    = hexToColor 0xAA3838
hexPurple  = hexToColor 0x7F2483
hexPurple2 = hexToColor 0x8153B2

hexToColor hex = Color.rgb ((hex `shiftRight` 16) `and` 0xFF)
                           ((hex `shiftRight` 8)  `and` 0xFF)
                           ((hex `shiftRight` 0)  `and` 0xFF)
colorScheme = [ hexOrange
              , hexOrange2
              , hexBlue
              , hexBlue2
              , hexGreen
              , hexGreen2
              , hexRed
              , hexRed2
              ]

colorTypes = [PureColor, MultColor, Interp,     Darker,
              Lighter,   Saturate,  Desaturate, FadeIn,
              FadeOut,   Mixed]

animationSpeed = 0.1
createSpeed = 0.01
progressUpdateDelta = 0.005
createProb = 1
maxNumCircles = 500
maxRadius = 40

xW = 0
yW = 0
widthW  = 1000
heightW = 1000
viewBoxDims = L.foldl (++) "" <| L.map toString [xW, yW, widthW, heightW]
maxDim = widthW

{- Circles -}

updateProgress a = { a | progress = Basics.min 1.0 (a.progress + progressUpdateDelta) }

vecPair vec = (getX vec, getY vec)

testCreate p = p < createProb

finishedProgress {progress} = progress /= 1.0

randomColor : R.Generator Color
randomColor = 
  let rType = R.map (Maybe.withDefault PureColor) (R.sample colorTypes)
      rColor = R.map (Maybe.withDefault hexOrange) (R.sample colorScheme)
      rFloat = R.float 0 1
      mkColor typ f c c' =
        case typ of
          PureColor  -> c
          MultColor  -> c `multiply` c'
          Interp     -> c `multiply` c'
          Darker     -> Color.Manipulate.darken f c
          Lighter    -> Color.Manipulate.lighten f c
          Saturate   -> saturate f c
          Desaturate -> desaturate f c
          FadeIn     -> fadeIn f c
          FadeOut    -> fadeOut f c
          Mixed      -> mix c c'

  in R.map4 mkColor rType rFloat rColor rColor

randomCircle : Float -> R.Generator Circle
randomCircle a = 
  let rVec    = R.map2 vec2 (R.float 0 widthW) (R.float 0 heightW)
      rRadius = R.float 0 a
      rColor  = randomColor
      mkCircle color pos r = { centerPos = pos,
                               radius    = r,
                               color     = color,
                               progress  = 0.0
                              }
  in R.map3 mkCircle rColor rVec rRadius

progressScale : Float -> Float
progressScale progress = 1 - (abs (1 - progress * 2.0))

drawCircle { centerPos, radius, color, progress } = 
  let beforeMid = progress < 0.5
      currentScale = progressScale progress
      circleForm = C.filled color <| C.circle (currentScale * radius)
      placedCircle = C.move (getX centerPos, getY centerPos) <| circleForm
  in placedCircle

drawCircles circles =
  C.group <| L.map drawCircle circles

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
      (L.filter finishedProgress <| L.map updateProgress model, Cmd.none)
      --(model, R.generate CreateLine (R.map |> lineCreateProb) <| R.float 0 1))

    TriggerCircle ->
      (model, R.generate CreateCircle (R.map testCreate <| (R.float 0 1)))

    AddCircle circle ->
      (if L.length model < maxNumCircles then circle :: model else model, Cmd.none)

    CreateCircle b ->
      case b of
        True  ->
          (model, R.generate AddCircle (randomCircle maxRadius))

        False ->
          (model, Cmd.none)

    --Room poly ->
    --  (poly, Cmd.none)

subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.batch 
    [ Time.every second         Tick
    , Time.every animationSpeed (always Animate)
    , Time.every createSpeed    (always TriggerCircle)
    ]

init : (Model, Cmd Msg)
init = ([], Cmd.none)
--init = (scalePolygon 50 20 unitBox, Cmd.none)

view : Model -> Html Msg
view model = div []
  -- [ svg [viewBox viewBoxDims, width "300px"] [drawBox model]
  -- [ Element.toHtml <| C.collage widthW heightW [drawPolygon <| model]
  --[ Element.toHtml <| C.collage widthW heightW [drawCircle 100]
  [ Element.toHtml <| C.collage widthW heightW [drawCircles model]
  --, text <| toString model
  ]


main = App.program { init = init, view = view, update = update, subscriptions = subscriptions }

