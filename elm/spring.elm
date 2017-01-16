module Spring exposing (..)

import Html exposing (Html, div)
import Html.App as App
import Html.Events exposing (onClick)

import String exposing (append)

import Math.Vector2 as V exposing (Vec2, vec2, getX, getY, scale, sub)

import Time exposing (Time, second, now)
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
  { followers : (Follower, Follower)
  , lastTime : Time
  , mousePoint : Point
  }

type Msg
  = Animate Time
  | MousePos Point
  | CreateFollower
  | Err
  | InitTime (Maybe Time)

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

type alias Follower = 
  { size         : Float
  , goal         : V.Vec2
  , position     : Point
  , velocity     : V.Vec2
  , acceleration : V.Vec2
  , spring       : Spring
  , color        : Color
  }

-- this should take a type argument that is
-- either a Constraint, Proxy, or is unpacked into
-- this type to generalize to other types
type alias Spring =
  { stiffness    : Float
  , dampening    : Float
  }
    
animationSpeed = 10.0
updateTime = 0.1

defaultSize = 50
defaultStiffness = 5
defaultDampening = 0.2
defaultSpring = 
  { stiffness = defaultStiffness
  , dampening = defaultDampening
  }

defaultPoint = zeroPoint

follower1 = 
  { size         = defaultSize
  , goal         = vec2 0 0
  , position     = { x = 25, y = 25 }
  , velocity     = vec2   1.0  0.0
  , acceleration = vec2 (-1.0) 2.5
  , spring       = defaultSpring
  , color        = orange
  }

follower2 = 
  { size         = defaultSize
  , goal         = vec2 0 0
  , position     = { x = -25, y = -25 }
  , velocity     = vec2   1.0  0.0
  , acceleration = vec2 (-2.2) 1.0
  , spring       = defaultSpring
  , color        = blue
  }

zeroPoint = { x = 0, y = 0 }

xW = 0
yW = 0
widthW  = 1000
heightW = 1000
viewBoxDims = L.foldl (++) "" <| L.map toString [xW, yW, widthW, heightW]
maxDim = widthW

{- Circles -}

drawFollower : Follower -> C.Form
drawFollower fol =
  C.circle fol.size |> C.filled fol.color |> C.move (fol.position.x, fol.position.y) |> shade 10

drawFollowers : List Follower -> C.Form
drawFollowers followers = C.group <| List.map drawFollower followers

updatePoint {x, y} v = { x = x + getX v, y = y + getY v }

updateFollower pos dt follower =
  { follower | position = updatePoint follower.position (V.scale dt follower.velocity)
             , velocity = follower.velocity `V.add` (V.scale dt follower.acceleration)
             , goal = vec pos
  }

springPhysics pos spring goal vel =
  let pos' = vec2 pos.x pos.y
  in (V.scale spring.stiffness (goal `V.sub` pos')) `V.sub` (spring.dampening `V.scale` vel)

updateSprings dt follower = { follower | acceleration = springPhysics follower.position
                                                                      follower.spring
                                                                      follower.goal 
                                                                      follower.velocity
                            }

--updateFollowers : Float -> List Follower -> List Follower
--updateFollowers dt followers = L.map (updateFollower dt << updateSprings dt) followers

createFollower : Point -> Follower
createFollower pos =
  { size         = defaultSize
  , goal         = vec2 0 0
  , position     = pos
  , velocity     = vec2 0 0
  , acceleration = vec2 0 0
  , spring       = defaultSpring
  , color        = orange
  }

{- Shading -}
apply2 f ls ls' = L.map (uncurry f) <| L.map2 (,) ls ls'

times a b = a * b
shade levels form = 
  let opacities = L.map (times 0.5) <| L.scanl (+) 0 <| L.drop 1 <| L.repeat levels (1 / toFloat levels)
      sizes     = L.reverse opacities
      forms     = L.repeat (L.length sizes) form
  in
      C.group <| apply2 C.scale sizes <| apply2 C.alpha opacities <| forms

allButLast ls = List.take (List.length ls - 1) ls

vec { x, y } = vec2 x y

pushAway pos follower = { follower | acceleration = follower.acceleration `V.add`
                                                    (V.scale 1.0 (vec pos `V.sub` (vec follower.position)))
                        }

animateModel model time =
  let (fol, fol') = model.followers
      dt = time - model.lastTime
      pushFromMouse = pushAway model.mousePoint
  in
  { model | followers = (pushFromMouse <| updateSprings dt <| updateFollower fol'.position dt fol,
                         pushFromMouse <| updateSprings dt <| updateFollower fol.position  dt fol')
          , lastTime = time
  }

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    MousePos pos ->
      ({ model | mousePoint = pos }, Cmd.none)

    Animate time ->
      (animateModel model time, Cmd.none)

    CreateFollower ->
      (model, Cmd.none)

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
init = ({ followers = (follower1, follower2), lastTime = 0.0, mousePoint = zeroPoint },
        T.perform (Basics.always Err) (toSeconds >> Just >> InitTime) now)

drawCircle = C.filled green <| C.circle 50

view : Model -> Html Msg
view { followers, lastTime, mousePoint } = let (fol, fol') = followers in div []
  [ Element.toHtml <| C.collage widthW heightW [drawFollowers [fol, fol']]
  -- , Html.text <| toString lastTime
   , Html.text <| toString mousePoint
  -- , Html.text <| toString followers
  ]


main = App.program { init = init, view = view, update = update, subscriptions = subscriptions }


