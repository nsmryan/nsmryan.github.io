module Main exposing (..)

import Mouse
import WebGL as GL
import Math.Vector3 exposing (..)
import Math.Vector2 exposing (..)
import Math.Matrix4 as Mat4
import Html exposing (Html)
import Html.Attributes exposing (width, height)
import Time exposing (Time, inSeconds)
import Mouse exposing (Position)
import AnimationFrame
import Task


winHeight = 600
winWidth = 1000

type alias Model =
  { mousePos : Position
  , currentTime : Time
  , deltaTime : Time
  }

type Msg
  = DeltaTime Time
  | MousePos Position
  | LoadTexture GL.Texture
  
type alias Uniforms = 
  { mousePos : Vec2
  , radius : Float
  , time : Float
  , dims : Vec2
  }
  
-- 100 x 100 png
texUrl = "http://3.bp.blogspot.com/-A24gZlZtY-E/UhzK12cBgzI/AAAAAAAAA5o/pPPCFiDj9xQ/s1600/p7shaded.png"

initModel = { mousePos = { x = 0, y = 0 }, currentTime = inSeconds 0.0, deltaTime = inSeconds 0.0 }

updateTime model diff =
  { model | deltaTime = diff
          , currentTime = model.currentTime + diff
  }

updateMousePos model position = { model | mousePos = position }

update msg model =
  case msg of
    DeltaTime diff ->
      (updateTime model diff, Cmd.none)
    MousePos position ->
      (updateMousePos model position, Cmd.none)

main : Program Never Model Msg
main =
    Html.program
        { init = ( initModel, GL.load texUrl LoadTexture)
        , view = view
        , subscriptions = (\_ -> Sub.batch [AnimationFrame.diffs DeltaTime, Mouse.moves MousePos])
        , update = update
        }


type alias Vertex =
    { position : Vec2, color : Vec3 }


mesh : GL.Drawable Vertex
mesh =
    GL.Triangle <|
        [ ( Vertex (vec2 0 0) (vec3 1 0 0)
          , Vertex (vec2 1 1) (vec3 0 1 0)
          , Vertex (vec2 1 0) (vec3 0 0 1)
          )
        , ( Vertex (vec2 0 0) (vec3 1 0 0)
          , Vertex (vec2 0 1) (vec3 0 0 1)
          , Vertex (vec2 1 1) (vec3 0 1 0)
          )
        ]


ortho2D : Float -> Float -> Mat4.Mat4
ortho2D w h =
    Mat4.makeOrtho2D 0 w h 0

mouseToVec2 pos = vec2 (toFloat pos.x) (winHeight - toFloat pos.y)

view : Model -> Html Msg
view model =
    GL.toHtml
        [ width winWidth, height winHeight ]
        [ GL.render vertexShader fragmentShader mesh { mat = ortho2D 1 1 , dims = vec2 winWidth winHeight, time = model.currentTime, mousePos = mouseToVec2 model.mousePos, radius = 60.0 } ]



-- Shaders


vertexShader : GL.Shader { attr | position : Vec2, color : Vec3 } { unif | mat : Mat4.Mat4 } { vcolor : Vec3 }
vertexShader =
    [glsl|

attribute vec2 position;
attribute vec3 color;
uniform mat4 mat;
varying vec3 vcolor;

void main () {
    gl_Position = mat * vec4(position, 0.0, 1.0);
    vcolor = color;
}

|]


fragmentShader : GL.Shader {} { u | mousePos : Vec2, dims : Vec2, time : Float, radius : Float } { vcolor : Vec3 }
fragmentShader =
    [glsl|

precision mediump float;
varying vec3 vcolor;
uniform vec2 mousePos;
uniform vec2 dims;
uniform float radius;
uniform float time;

float atan2(float x, float y){
	if(x>0.0)return atan(y/x);
	if(x<0.0&& y>=0.0)return atan(y/x)+3.14;
	if(y<0.0&&x<0.0)return atan(y/x)-3.14;
	if(y>0.0&&x==0.0)return 3.14/2.0;
	if(y<0.0&& x==0.0)return -3.14/2.0;
	return 0.0;
}

float noise(vec3 p) //Thx to Las^Mercury
{
	vec3 i = floor(p);
	vec4 a = dot(i, vec3(1., 57., 21.)) + vec4(0., 57., 21., 78.);
	vec3 f = cos((p-i)*acos(-1.))*(-.5)+.5;
	a = mix(sin(cos(a)*a),sin(cos(1.+a)*(1.+a)), f.x);
	a.xy = mix(a.xz, a.yw, f.y);
	return mix(a.x, a.y, f.z);
}

void main () {
  vec2 pos = dims/2.0; // mousePos;
  float dist = distance(gl_FragCoord.xy, pos);
  vec2 toMouse = gl_FragCoord.xy - pos;
  float rads = atan2(toMouse.y, toMouse.x);
  float radiusLocal = radius + 10.0*noise(vec3(time/ 1000.0 + sin(rads), time / 1000.0 + sin(rads), 0));//sin(time/500.0 + 35.0 * atan2(toMouse.y, toMouse.x));
  if (dist < radiusLocal)
  {
    //gl_FragColor = vec4(0.0, 0.5, 0.0, 1.0 - (dist/radius));
    //gl_FragColor = vec4(0.0, 0.5, 0.0, (dist / radius) + ((1.0 + sin(time / 1000.0)) / 2.0));
    gl_FragColor = vec4(0.0, 0.5, 0.0, 1);
  }
  else
  {
    gl_FragColor = vec4(0.0, 0.0, 0.5, 0.5);
  }
}

|]

