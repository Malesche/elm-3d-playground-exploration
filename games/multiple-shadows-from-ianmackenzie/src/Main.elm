module Main exposing (main)

import Color exposing (black, blue, brown, darkGreen, gray, green, hsl, lightBlue, lightGray, lightGreen, lightPurple, lightRed, orange, purple, red, white, yellow)
import Html exposing (Html)
import Illuminance
import LuminousFlux
import Playground3d exposing (Computer, Shape, block, cube, cylinder, game, group, line, move, moveX, moveY, moveZ, rotateX, rotateY, rotateZ, scale, sphere, spin, triangle, wave)
import Playground3d.Camera exposing (Camera, perspective)
import Playground3d.Light as Light
import Playground3d.Scene as Scene
import Scene3d
import Scene3d.Light
import Temperature


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
        { focalPoint = { x = 0, y = 1, z = 0 }
        , eyePoint = { x = 5, y = 5, z = 12 }
        , upDirection = { x = 0, y = 1, z = 0 }
        }


view : Computer -> Model -> Html Never
view computer model =
    let
        firstLight =
            Light.point
                { position = { x = -2, y = 4, z = 1 }
                , chromaticity = Scene3d.Light.incandescent
                , intensity = LuminousFlux.lumens 6000
                }

        secondLight =
            Light.point
                { position = { x = 2, y = 3, z = 1 }
                , chromaticity = Scene3d.Light.fluorescent
                , intensity = LuminousFlux.lumens 6000
                }

        thirdLight =
            Light.directional
                { azimuth = degrees -90
                , elevation = degrees -45
                , chromaticity = Scene3d.Light.colorTemperature (Temperature.kelvins 2000)
                , intensity = Illuminance.lux 100
                }

        fourthLight =
            Light.soft
                { azimuth = degrees 0
                , elevation = degrees -45
                , chromaticity = Scene3d.Light.fluorescent
                , intensityAbove = Illuminance.lux 20
                , intensityBelow = Illuminance.lux 10
                }
    in
    Scene.custom
        { screen = computer.screen
        , camera = camera
        , lights =
            Scene3d.fourLights
                firstLight
                secondLight
                thirdLight
                fourthLight
        , clipDepth = 0.1
        , exposure = Scene3d.exposureValue 6
        , toneMapping = Scene3d.hableFilmicToneMapping -- See ExposureAndToneMapping.elm for details
        , whiteBalance = Scene3d.Light.fluorescent
        , antialiasing = Scene3d.multisampling
        , backgroundColor = lightBlue
        }
        (shapes computer model)


shapes : Computer -> Model -> List Shape
shapes computer model =
    [ floor computer
    , cubes computer
    , orbitingCubes computer
    , spheres computer

    --, axes
    ]


axes : Shape
axes =
    group
        [ line red ( 100, 0, 0 ) -- x axis
        , line green ( 0, 100, 0 ) -- y axis
        , line blue ( 0, 0, 100 ) -- z axis
        ]


floor : Computer -> Shape
floor computer =
    let
        square color =
            block color ( 10, 1, 10 )
                |> moveY -1

        octaThing color =
            group
                [ square color
                , square color |> rotateY (degrees 45)
                ]
    in
    group
        [ funky
        , octaThing gray
        , octaThing blue
            |> scale 1.1
            |> moveY -0.1
        , octaThing gray
            |> scale 1.2
            |> moveY -0.2
        , tree computer
            |> moveX 5
            |> moveY 1
        , group
            (List.range 1 7
                |> List.map
                    (\i ->
                        tetrahedron
                            |> scale 2
                            |> moveX 5.5
                            |> moveY (-1 / 3)
                            |> rotateY (degrees (toFloat i * 45))
                    )
            )
        ]
        |> rotateY (spin 1000 computer.time)


spheres : Computer -> Shape
spheres computer =
    group
        [ group
            [ sphere lightBlue 0.5 |> moveX -0.02
            , sphere lightGreen 0.5 |> moveX 0.02
            ]
            |> rotateZ (spin 100 computer.time)
            |> moveZ 3.5
            |> rotateY -(spin 640 computer.time)
        ]


cubes : Computer -> Shape
cubes computer =
    let
        spinIt s =
            s
                |> rotateX (spin 300 computer.time)
                |> rotateY (spin 300 computer.time)
                |> rotateZ (spin 300 computer.time)
    in
    group
        [ cube lightGreen 1
            |> spinIt
            |> moveX -2
            |> moveY 2
        , cube blue 1
            |> spinIt
            |> moveX 2
            |> moveY 2
        , cube lightPurple 1
            |> spinIt
            |> moveY 4
        , tetrahedron
            |> spinIt
            |> moveY 1.5
        ]


funky : Shape
funky =
    let
        a =
            group
                [ cube white 1
                , cube white 1
                    |> rotateY (degrees 45)
                ]
    in
    group
        [ group [ a, a |> scale 1.3 |> moveY -0.4 ]
        , cylinder white 1 0.5 |> moveY -0.7
        ]


tree : Computer -> Shape
tree computer =
    let
        n =
            16

        layerBlock i =
            let
                width =
                    0.2 * (n - toFloat i) |> min 2

                height =
                    0.25

                wavyColor =
                    hsl (wave (toFloat i / n) 1 10 computer.time) 0.6 0.6
            in
            block wavyColor ( width, height, width )
                |> moveY (toFloat i * 1.2 * height)
                |> rotateY (toFloat i * wave 3 5 10 computer.time)
    in
    group
        [ block brown ( 0.2, 8, 0.2 )
        , group (List.map layerBlock (List.range 0 (n - 1)))
        ]


orbitingCubes : Computer -> Shape
orbitingCubes computer =
    let
        n =
            14
    in
    group
        (List.range 0 (n - 1)
            |> List.map
                (\i ->
                    cube orange 0.3
                        |> rotateZ (spin 300 computer.time)
                        |> rotateX (spin 600 computer.time)
                        |> moveY (wave -1 1 10 computer.time)
                        |> moveX 1.3
                        |> rotateY -(toFloat i / n * degrees 360)
                        |> rotateY -(spin 200 computer.time)
                        |> rotateX (spin 1000 computer.time)
                        |> rotateZ (spin 1000 computer.time)
                        |> moveY 4
                )
        )


tetrahedron : Shape
tetrahedron =
    let
        h =
            sqrt 3 / 2

        equilateralTriangle =
            triangle white
                ( { x = h, y = 0, z = 0 }
                , { x = 0, y = 0.5, z = 0 }
                , { x = 0, y = -0.5, z = 0 }
                )

        oneSide =
            equilateralTriangle |> rotateY (acos (1 / 3)) |> moveX -(h / 3)
    in
    group
        [ equilateralTriangle |> moveX -(h / 3)
        , oneSide
        , oneSide |> rotateZ (degrees 120)
        , oneSide |> rotateZ (degrees 240)
        ]
        |> rotateX (degrees 90)
        |> moveY -(h / 3)
