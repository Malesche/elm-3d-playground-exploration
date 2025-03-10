module Playground3d exposing
    ( game
    , Shape, block, cube, cylinder, group, line, sphere, triangle
    , move, moveX, moveY, moveZ, rotateX, rotateY, rotateZ
    , Time, spin, wave, zigzag
    , Computer, Mouse, Screen, Keyboard, toX, toY, toXY
    , Number
    , toEntities
    , configurations, gameWithConfigurations, getFloat, scale
    )

{-| NOTE: Most of the following code is copied from evancz/elm-playground


# Playground

@docs game


# Shapes

@docs Shape, block, cube, cylinder, group, line, sphere, triangle


# Move Shapes

@docs move, moveX, moveY, moveZ, rotateX, rotateY, rotateZ


# Groups

@docs group


# Time

@docs Time, spin, wave, zigzag


# Computer

@docs Computer, Mouse, Screen, Keyboard, toX, toY, toXY


### Numbers

@docs Number


### Rendering

@docs toEntities

-}

import Angle
import Axis3d exposing (Axis3d)
import Block3d exposing (Block3d)
import Browser
import Browser.Dom as Dom
import Browser.Events as E
import Color exposing (Color)
import Cylinder3d exposing (Cylinder3d)
import Direction3d
import Html exposing (Html, div, h1, text)
import Html.Attributes exposing (style)
import Json.Decode as D
import Length exposing (Length, Meters)
import LineSegment3d exposing (LineSegment3d)
import Playground3d.Configurations as Configurations exposing (Configurations)
import Playground3d.Geometry exposing (Point)
import Point3d exposing (Point3d)
import Scene3d
import Scene3d.Material as Material exposing (Material)
import Set
import Sphere3d exposing (Sphere3d)
import Task
import Time
import Triangle3d exposing (Triangle3d)
import Vector3d



-- COMPUTER


{-| When writing a [`game`](#game), you can look up all sorts of information
about your computer:

  - [`Mouse`](#Mouse) - Where is the mouse right now?
  - [`Keyboard`](#Keyboard) - Are the arrow keys down?
  - [`Screen`](#Screen) - How wide is the screen?
  - [`Time`](#Time) - What time is it right now?

So you can use expressions like `computer.mouse.x` and `computer.keyboard.enter`
in games where you want some mouse or keyboard interaction.

-}
type alias Computer =
    { mouse : Mouse
    , keyboard : Keyboard
    , screen : Screen
    , time : Time
    , configurations : Configurations
    }


configurations =
    Configurations.Configurations


getFloat : String -> Computer -> Float
getFloat key computer =
    computer.configurations |> Configurations.getFloat key



-- MOUSE


{-| Figure out what is going on with the mouse.

You could draw a circle around the mouse with a program like this:

    import Playground3d exposing (..)

    main =
        game view update 0

    view computer memory =
        [ circle yellow 40
            |> moveX computer.mouse.x
            |> moveY computer.mouse.y
        ]

    update computer memory =
        memory

You could also use `computer.mouse.down` to change the color of the circle
while the mouse button is down.

-}
type alias Mouse =
    { x : Number
    , y : Number
    , down : Bool
    , click : Bool
    }


{-| A number like `1` or `3.14` or `-120`.
-}
type alias Number =
    Float



-- KEYBOARD


{-| Figure out what is going on with the keyboard.

If someone is pressing the UP and RIGHT arrows, you will see a value like this:

    { up = True
    , down = False
    , left = False
    , right = True
    , space = False
    , enter = False
    , shift = False
    , backspace = False
    , keys = Set.fromList [ "ArrowUp", "ArrowRight" ]
    }

So if you want to move a character based on arrows, you could write an update
like this:

    update computer y =
        if computer.keyboard.up then
            y + 1

        else
            y

Check out [`toX`](#toX) and [`toY`](#toY) which make this even easier!

**Note:** The `keys` set will be filled with the name of all keys which are
down right now. So you will see things like `"a"`, `"b"`, `"c"`, `"1"`, `"2"`,
`"Space"`, and `"Control"` in there. Check out [this list][list] to see the
names used for all the different special keys! From there, you can use
[`Set.member`][member] to check for whichever key you want. E.g.
`Set.member "Control" computer.keyboard.keys`.

[list]: https://developer.mozilla.org/en-US/docs/Web/API/KeyboardEvent/key/Key_Values
[member]: /packages/elm/core/latest/Set#member

-}
type alias Keyboard =
    { up : Bool
    , down : Bool
    , left : Bool
    , right : Bool
    , space : Bool
    , enter : Bool
    , shift : Bool
    , backspace : Bool
    , keys : Set.Set String
    }


{-| Turn the LEFT and RIGHT arrows into a number.

    toX { left = False, right = False, ... } == 0
    toX { left = True , right = False, ... } == -1
    toX { left = False, right = True , ... } == 1
    toX { left = True , right = True , ... } == 0

So to make a square move left and right based on the arrow keys, we could say:

    import Playground3d exposing (..)

    main =
        game view update 0

    view computer x =
        [ square green 40
            |> moveX x
        ]

    update computer x =
        x + toX computer.keyboard

-}
toX : Keyboard -> Number
toX keyboard =
    (if keyboard.right then
        1

     else
        0
    )
        - (if keyboard.left then
            1

           else
            0
          )


{-| Turn the UP and DOWN arrows into a number.

    toY { up = False, down = False, ... } == 0
    toY { up = True , down = False, ... } == 1
    toY { up = False, down = True , ... } == -1
    toY { up = True , down = True , ... } == 0

This can be used to move characters around in games just like [`toX`](#toX):

    import Playground3d exposing (..)

    main =
        game view update ( 0, 0 )

    view computer ( x, y ) =
        [ square blue 40
            |> move x y
        ]

    update computer ( x, y ) =
        ( x + toX computer.keyboard
        , y + toY computer.keyboard
        )

-}
toY : Keyboard -> Number
toY keyboard =
    (if keyboard.up then
        1

     else
        0
    )
        - (if keyboard.down then
            1

           else
            0
          )


{-| If you just use `toX` and `toY`, you will move diagonal too fast. You will go
right at 1 pixel per update, but you will go up/right at 1.41421 pixels per
update.

So `toXY` turns the arrow keys into an `(x,y)` pair such that the distance is
normalized:

    toXY { up = True , down = False, left = False, right = False, ... } == (1, 0)
    toXY { up = True , down = False, left = False, right = True , ... } == (0.707, 0.707)
    toXY { up = False, down = False, left = False, right = True , ... } == (0, 1)

Now when you go up/right, you are still going 1 pixel per update.

    import Playground3d exposing (..)

    main =
        game view update ( 0, 0 )

    view computer ( x, y ) =
        [ square green 40
            |> move x y
        ]

    update computer ( x, y ) =
        let
            ( dx, dy ) =
                toXY computer.keyboard
        in
        ( x + dx, y + dy )

-}
toXY : Keyboard -> ( Number, Number )
toXY keyboard =
    let
        x =
            toX keyboard

        y =
            toY keyboard
    in
    if x /= 0 && y /= 0 then
        ( x / squareRootOfTwo, y / squareRootOfTwo )

    else
        ( x, y )


squareRootOfTwo : Number
squareRootOfTwo =
    sqrt 2



-- SCREEN


{-| Get the dimensions of the screen. If the screen is 800 by 600, you will see
a value like this:

    { width = 800
    , height = 600
    , top = 300
    , left = -400
    , right = 400
    , bottom = -300
    }

This can be nice when used with [`moveY`](#moveY) if you want to put something
on the bottom of the screen, no matter the dimensions.

-}
type alias Screen =
    { width : Number
    , height : Number
    , top : Number
    , left : Number
    , right : Number
    , bottom : Number
    }



-- TIME


{-| The current time.

Helpful when making an [`animation`](#animation) with functions like
[`spin`](#spin), [`wave`](#wave), and [`zigzag`](#zigzag).

-}
type Time
    = Time Time.Posix


{-| Create an angle that cycles from 0 to 360 degrees over time.

Here is an [`animation`](#animation) with a spinning triangle:

    import Playground3d exposing (..)

    main =
        animation view

    view time =
        [ triangle orange 50
            |> rotate (spin 8 time)
        ]

It will do a full rotation once every eight seconds. Try changing the `8` to
a `2` to make it do a full rotation every two seconds. It moves a lot faster!

-}
spin : Number -> Time -> Number
spin period time =
    360 * toFrac period time


{-| Smoothly wave between two numbers.

Here is an [`animation`](#animation) with a circle that resizes:

    import Playground3d exposing (..)

    main =
        animation view

    view time =
        [ circle lightBlue (wave 50 90 7 time)
        ]

The radius of the circle will cycles between 50 and 90 every seven seconds.
It kind of looks like it is breathing.

-}
wave : Number -> Number -> Number -> Time -> Number
wave lo hi period time =
    lo + (hi - lo) * (1 + cos (turns (toFrac period time))) / 2


{-| Zig zag between two numbers.

Here is an [`animation`](#animation) with a rectangle that tips back and forth:

    import Playground3d exposing (..)

    main =
        animation view

    view time =
        [ rectangle lightGreen 20 100
            |> rotate (zigzag -20 20 4 time)
        ]

It gets rotated by an angle. The angle cycles from -20 degrees to 20 degrees
every four seconds.

-}
zigzag : Number -> Number -> Number -> Time -> Number
zigzag lo hi period time =
    lo + (hi - lo) * abs (2 * toFrac period time - 1)


toFrac : Float -> Time -> Float
toFrac period (Time posix) =
    let
        ms =
            Time.posixToMillis posix

        p =
            period * 1000
    in
    toFloat (modBy (round p) ms) / p



-- GAME


{-| Create a game!

Once you get comfortable with [`animation`](#animation), you can try making a
game with the keyboard and mouse. Here is an example of a green square that
just moves to the right:

    import Playground3d exposing (..)

    main =
        game view update 0

    view computer offset =
        [ square green 40
            |> moveRight offset
        ]

    update computer offset =
        offset + 0.03

This shows the three important parts of a game:

1.  `memory` - makes it possible to store information. So with our green square,
    we save the `offset` in memory. It starts out at `0`.
2.  `view` - lets us say which shapes to put on screen. So here we move our
    square right by the `offset` saved in memory.
3.  `update` - lets us update the memory. We are incrementing the `offset` by
    a tiny amount on each frame.

The `update` function is called about 60 times per second, so our little
changes to `offset` start to add up pretty quickly!

This game is not very fun though! Making a `game` also gives you access to the
[`Computer`](#Computer), so you can use information about the [`Mouse`](#Mouse)
and [`Keyboard`](#Keyboard) to make it interactive! So here is a red square that
moves based on the arrow keys:

    import Playground3d exposing (..)

    main =
        game view update ( 0, 0 )

    view computer ( x, y ) =
        [ square red 40
            |> move x y
        ]

    update computer ( x, y ) =
        ( x + toX computer.keyboard
        , y + toY computer.keyboard
        )

Notice that in the `update` we use information from the keyboard to update the
`x` and `y` values. These building blocks let you make pretty fancy games!

-}
game :
    (Computer -> memory -> Html Never)
    -> (Computer -> memory -> memory)
    -> memory
    -> Program () (Game memory) Msg
game viewMemory updateMemory initialMemory =
    gameWithConfigurations viewMemory updateMemory Configurations.empty initialMemory


gameWithConfigurations :
    (Computer -> memory -> Html Never)
    -> (Computer -> memory -> memory)
    -> Configurations
    -> memory
    -> Program () (Game memory) Msg
gameWithConfigurations viewMemory updateMemory initialConfigurations initialMemory =
    let
        init () =
            ( Game E.Visible initialMemory (initialComputer initialConfigurations)
            , Task.perform GotViewport Dom.getViewport
            )

        view (Game _ memory computer) =
            div
                [ style "position" "fixed"
                , style "top" "0px"
                , style "left" "0px"
                ]
                [ div [ style "position" "absolute" ] [ Html.map ConfigurationsInput (Configurations.view computer.configurations) ]
                , Html.map (always NoOp) (viewMemory computer memory)
                ]

        update msg model =
            ( gameUpdate updateMemory msg model
            , Cmd.none
            )

        subscriptions (Game visibility _ _) =
            case visibility of
                E.Hidden ->
                    E.onVisibilityChange VisibilityChanged

                E.Visible ->
                    gameSubscriptions
    in
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


initialComputer : Configurations -> Computer
initialComputer initialConfigurations =
    { mouse = Mouse 0 0 False False
    , keyboard = emptyKeyboard
    , screen = toScreen 600 600
    , time = Time (Time.millisToPosix 0)
    , configurations = initialConfigurations
    }



-- SUBSCRIPTIONS


gameSubscriptions : Sub Msg
gameSubscriptions =
    Sub.batch
        [ E.onResize Resized
        , E.onKeyUp (D.map (KeyChanged False) (D.field "key" D.string))
        , E.onKeyDown (D.map (KeyChanged True) (D.field "key" D.string))
        , E.onAnimationFrame Tick
        , E.onVisibilityChange VisibilityChanged
        , E.onClick (D.succeed MouseClick)
        , E.onMouseDown (D.succeed (MouseButton True))
        , E.onMouseUp (D.succeed (MouseButton False))
        , E.onMouseMove (D.map2 MouseMove (D.field "pageX" D.float) (D.field "pageY" D.float))
        ]



-- GAME HELPERS


type Game memory
    = Game E.Visibility memory Computer


type Msg
    = NoOp
    | ConfigurationsInput Configurations.Msg
    | KeyChanged Bool String
    | Tick Time.Posix
    | GotViewport Dom.Viewport
    | Resized Int Int
    | VisibilityChanged E.Visibility
    | MouseMove Float Float
    | MouseClick
    | MouseButton Bool


gameUpdate : (Computer -> memory -> memory) -> Msg -> Game memory -> Game memory
gameUpdate updateMemory msg (Game vis memory computer) =
    case msg of
        NoOp ->
            Game vis memory computer

        ConfigurationsInput configurationsMsg ->
            Game vis memory <|
                { computer
                    | configurations =
                        computer.configurations |> Configurations.update configurationsMsg
                }

        Tick time ->
            Game vis (updateMemory computer memory) <|
                if computer.mouse.click then
                    { computer | time = Time time, mouse = mouseClick False computer.mouse }

                else
                    { computer | time = Time time }

        GotViewport { viewport } ->
            Game vis memory { computer | screen = toScreen viewport.width viewport.height }

        Resized w h ->
            Game vis memory { computer | screen = toScreen (toFloat w) (toFloat h) }

        KeyChanged isDown key ->
            Game vis memory { computer | keyboard = updateKeyboard isDown key computer.keyboard }

        MouseMove pageX pageY ->
            let
                x =
                    computer.screen.left + pageX

                y =
                    computer.screen.top - pageY
            in
            Game vis memory { computer | mouse = mouseMove x y computer.mouse }

        MouseClick ->
            Game vis memory { computer | mouse = mouseClick True computer.mouse }

        MouseButton isDown ->
            Game vis memory { computer | mouse = mouseDown isDown computer.mouse }

        VisibilityChanged visibility ->
            Game visibility
                memory
                { computer
                    | keyboard = emptyKeyboard
                    , mouse = Mouse computer.mouse.x computer.mouse.y False False
                }



-- SCREEN HELPERS


toScreen : Float -> Float -> Screen
toScreen width height =
    { width = width
    , height = height
    , top = height / 2
    , left = -width / 2
    , right = width / 2
    , bottom = -height / 2
    }



-- MOUSE HELPERS


mouseClick : Bool -> Mouse -> Mouse
mouseClick bool mouse =
    { mouse | click = bool }


mouseDown : Bool -> Mouse -> Mouse
mouseDown bool mouse =
    { mouse | down = bool }


mouseMove : Float -> Float -> Mouse -> Mouse
mouseMove x y mouse =
    { mouse | x = x, y = y }



-- KEYBOARD HELPERS


emptyKeyboard : Keyboard
emptyKeyboard =
    { up = False
    , down = False
    , left = False
    , right = False
    , space = False
    , enter = False
    , shift = False
    , backspace = False
    , keys = Set.empty
    }


updateKeyboard : Bool -> String -> Keyboard -> Keyboard
updateKeyboard isDown key keyboard =
    let
        keys =
            if isDown then
                Set.insert key keyboard.keys

            else
                Set.remove key keyboard.keys
    in
    case key of
        " " ->
            { keyboard | keys = keys, space = isDown }

        "Enter" ->
            { keyboard | keys = keys, enter = isDown }

        "Shift" ->
            { keyboard | keys = keys, shift = isDown }

        "Backspace" ->
            { keyboard | keys = keys, backspace = isDown }

        "ArrowUp" ->
            { keyboard | keys = keys, up = isDown }

        "ArrowDown" ->
            { keyboard | keys = keys, down = isDown }

        "ArrowLeft" ->
            { keyboard | keys = keys, left = isDown }

        "ArrowRight" ->
            { keyboard | keys = keys, right = isDown }

        _ ->
            { keyboard | keys = keys }



-- SHAPES


{-| Shapes help you make a `picture`, `animation`, or `game`.

Read on to see examples of [`circle`](#circle), [`rectangle`](#rectangle),
[`words`](#words), [`image`](#image), and many more!

-}
type Shape
    = Block Color (Block3d Meters ())
    | Triangle Color (Triangle3d Meters ())
    | Cylinder Color (Cylinder3d Meters ())
    | Sphere Color (Sphere3d Meters ())
    | Line Color (LineSegment3d Meters ())
    | Group (List Shape)


material color =
    Material.matte color


type alias Vector =
    ( Float, Float, Float )


block : Color -> Vector -> Shape
block color ( xDim, yDim, zDim ) =
    let
        ( hXDim, hYDim, hZDim ) =
            ( xDim / 2
            , yDim / 2
            , zDim / 2
            )
    in
    Block color
        (Block3d.from
            (Point3d.meters -hXDim -hYDim -hZDim)
            (Point3d.meters hXDim hYDim hZDim)
        )


triangle : Color -> ( Point, Point, Point ) -> Shape
triangle color ( p, q, r ) =
    Triangle color
        (Triangle3d.from
            (Point3d.meters p.x p.y p.z)
            (Point3d.meters q.x q.y q.z)
            (Point3d.meters r.x r.y r.z)
        )


cube : Color -> Float -> Shape
cube color width =
    let
        hw =
            width / 2
    in
    Block color
        (Block3d.from
            (Point3d.meters -hw -hw -hw)
            (Point3d.meters hw hw hw)
        )


cylinder : Color -> Float -> Float -> Shape
cylinder color radius length =
    Cylinder color
        (Cylinder3d.centeredOn Point3d.origin
            Direction3d.positiveY
            { radius = Length.meters radius
            , length = Length.meters length
            }
        )


sphere : Color -> Float -> Shape
sphere color radius =
    Sphere color
        (Sphere3d.withRadius (Length.meters radius) Point3d.origin)


line : Color -> Vector -> Shape
line color ( x, y, z ) =
    Line color
        (LineSegment3d.fromPointAndVector Point3d.origin
            (Vector3d.fromMeters { x = x, y = y, z = z })
        )


group : List Shape -> Shape
group drawables =
    Group drawables



-- MODIFY


rotate : Axis3d Meters () -> Float -> Shape -> Shape
rotate axis angle drawable =
    case drawable of
        Block color block3d ->
            Block color
                (block3d |> Block3d.rotateAround axis (Angle.radians angle))

        Triangle color triangle3d ->
            Triangle color
                (triangle3d |> Triangle3d.rotateAround axis (Angle.radians angle))

        Sphere color sphere3d ->
            Sphere color
                (sphere3d |> Sphere3d.rotateAround axis (Angle.radians angle))

        Cylinder color cylinder3d ->
            Cylinder color
                (cylinder3d |> Cylinder3d.rotateAround axis (Angle.radians angle))

        Line color lineSegment3d ->
            Line color
                (lineSegment3d |> LineSegment3d.rotateAround axis (Angle.radians angle))

        Group drawables ->
            Group
                (List.map (rotate axis angle) drawables)


rotateX : Float -> Shape -> Shape
rotateX angle drawable =
    rotate Axis3d.x angle drawable


rotateY : Float -> Shape -> Shape
rotateY angle drawable =
    rotate Axis3d.y angle drawable


rotateZ : Float -> Shape -> Shape
rotateZ angle drawable =
    rotate Axis3d.z angle drawable


scale : Float -> Shape -> Shape
scale factor drawable =
    case drawable of
        Block color block3d ->
            Block color
                (block3d |> Block3d.scaleAbout Point3d.origin factor)

        Triangle color triangle3d ->
            Triangle color
                (triangle3d |> Triangle3d.scaleAbout Point3d.origin factor)

        Sphere color sphere3d ->
            Sphere color
                (sphere3d |> Sphere3d.scaleAbout Point3d.origin factor)

        Cylinder color cylinder3d ->
            Cylinder color
                (cylinder3d |> Cylinder3d.scaleAbout Point3d.origin factor)

        Line color lineSegment3d ->
            Line color
                (lineSegment3d |> LineSegment3d.scaleAbout Point3d.origin factor)

        Group drawables ->
            Group
                (List.map (scale factor) drawables)


move : Vector -> Shape -> Shape
move ( x, y, z ) drawable =
    let
        translation =
            Vector3d.meters x y z
    in
    case drawable of
        Block color block3d ->
            Block color
                (block3d |> Block3d.translateBy translation)

        Triangle color triangle3d ->
            Triangle color
                (triangle3d |> Triangle3d.translateBy translation)

        Sphere color sphere3d ->
            Sphere color
                (sphere3d |> Sphere3d.translateBy translation)

        Cylinder color cylinder3d ->
            Cylinder color
                (cylinder3d |> Cylinder3d.translateBy translation)

        Line color lineSegment3d ->
            Line color
                (lineSegment3d |> LineSegment3d.translateBy translation)

        Group drawables ->
            Group
                (List.map (move ( x, y, z )) drawables)


moveX : Float -> Shape -> Shape
moveX x =
    move ( x, 0, 0 )


moveY : Float -> Shape -> Shape
moveY y =
    move ( 0, y, 0 )


moveZ : Float -> Shape -> Shape
moveZ z =
    move ( 0, 0, z )



-- VIEW


toEntities : List Shape -> List (Scene3d.Entity ())
toEntities drawables =
    drawables
        |> List.concatMap drawableToEntities


drawableToEntities : Shape -> List (Scene3d.Entity ())
drawableToEntities drawable =
    case drawable of
        Block color block3d ->
            [ Scene3d.blockWithShadow (material color) block3d ]

        Triangle color triangle3d ->
            [ Scene3d.facetWithShadow (material color) triangle3d ]

        Sphere color sphere3d ->
            [ Scene3d.sphereWithShadow (material color) sphere3d ]

        Cylinder color cylinder3d ->
            [ Scene3d.cylinderWithShadow (material color) cylinder3d ]

        Line color lineSegment3d ->
            [ Scene3d.lineSegment (Material.color color) lineSegment3d ]

        Group drawables ->
            drawables
                |> List.concatMap drawableToEntities
