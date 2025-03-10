module Main exposing (main)

import Color exposing (blue, green, hsl, lightBlue, red, rgb, yellow)
import Html exposing (Html)
import Playground3d exposing (Computer, Shape, block, cylinder, game, group, line, moveX, moveY, rotateY, sphere, spin, wave)
import Playground3d.Camera as Camera exposing (Camera, perspective)
import Playground3d.Scene as Scene


main =
    game view update initialModel


type alias Model =
    {}



-- INIT


initialModel : Model
initialModel =
    {}



-- UPDATE


update : Computer -> Model -> Model
update computer model =
    model



-- VIEW


camera : Camera
camera =
    perspective
        { focalPoint = { x = 0, y = 10, z = 0 }
        , eyePoint = { x = 0, y = 10, z = 30 }
        , upDirection = { x = 0, y = 1, z = 0 }
        }


view : Computer -> Model -> Html Never
view computer model =
    Scene.sunny
        { screen = computer.screen
        , camera = camera
        , sunlightAzimuth = degrees -45
        , sunlightElevation = degrees -45
        , backgroundColor = lightBlue
        }
        (shapes computer model)


shapes : Computer -> Model -> List Shape
shapes computer model =
    [ axes
    , floor
    , cubes computer
    ]


axes : Shape
axes =
    group
        [ line red ( 100, 0, 0 ) -- x axis
        , line green ( 0, 100, 0 ) -- y axis
        , line blue ( 0, 0, 100 ) -- z axis
        ]


floor : Shape
floor =
    cylinder (rgb 0.294 0.588 0.478) 30 1
        |> moveY -1.001


makeCube : Computer -> Int -> Shape
makeCube computer i =
    let
        w =
            wave 0.2 0.8 10 computer.time
    in
    block (hsl w 0.5 0.5) ( toFloat i, 1, toFloat i )
        |> moveY (toFloat i * 1.1)
        |> rotateY (0.1 * toFloat i)
        |> rotateY (spin 1000 computer.time)


cubes : Computer -> Shape
cubes computer =
    group
        (List.map (makeCube computer) (List.range 1 18))
