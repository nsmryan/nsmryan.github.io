module Tests exposing (suite)

import Test exposing (Test, describe, test, fuzz, fuzz3)
import Fuzz
import Expect
import Math.Vector2 as V2
import Math.Vector3 as V3
import Math.Matrix4 as M4


suite : Test
suite =
    describe "elm-linear-algebra"
        [ describe "Vector2 module"
            [ test "vec2" <|
                \() ->
                    Expect.equal
                        (V2.vec2 3 4)
                        (V2.vec2 3 4)
            , test "setX" <|
                \() ->
                    Expect.equal
                        (V2.vec2 5 4)
                        (V2.vec2 3 4 |> V2.setX 5)
            , test "setY" <|
                \() ->
                    Expect.equal
                        (V2.vec2 3 6)
                        (V2.vec2 3 4 |> V2.setY 6)
            ]
        , describe "Matrix4 module"
            [ describe "inverse"
                [ test "Identity is its own inverse" <|
                    \_ ->
                        M4.inverse M4.identity |> Expect.equal (Just M4.identity)
                , test "Scaling in 3D inverts to shrinking" <|
                    \_ ->
                        M4.makeScale3 2 3 (1 / 8)
                            |> M4.inverse
                            |> Expect.equal (Just (M4.makeScale3 0.5 (1 / 3) 8))
                , fuzz3 Fuzz.float Fuzz.float Fuzz.float "Translating in 3D inverts to translating the other way" <|
                    \x y z ->
                        M4.makeTranslate3 x y z
                            |> M4.inverse
                            |> Expect.equal (Just (M4.makeTranslate3 -x -y -z))
                , Test.concat <|
                    -- using constants instead of fuzz because of floating point errors
                    (flip List.map) [ pi, 1.5 * pi, pi / 12, pi / 50 ]
                        (\theta ->
                            test ("Rotation by " ++ toString theta) <|
                                \_ ->
                                    let
                                        m =
                                            M4.makeRotate theta V3.i
                                    in
                                        m
                                            |> M4.inverse
                                            |> Maybe.map (M4.mul m)
                                            |> Expect.equal (Just M4.identity)
                        )
                , test "cannot invert a singular matrix" <|
                    \_ ->
                        M4.makeBasis V3.i V3.j (V3.fromTuple ( 0, 0, 0 ))
                            |> M4.inverse
                            |> Expect.equal Nothing
                , test "inverts a known matrix" <|
                    \_ ->
                        M4.makeBasis
                            (V3.fromTuple ( 2, 9, -3 ))
                            (V3.fromTuple ( -4, 3, 14 ))
                            (V3.fromTuple ( 1, 12, 6 ))
                            |> M4.inverse
                            |> Expect.equal
                                (M4.makeBasis
                                    (V3.fromTuple ( -150, -90, 135 ))
                                    (V3.fromTuple ( 38, 15, -16 ))
                                    (V3.fromTuple ( -51, -15, 42 ))
                                    |> M4.scale3 (1 / 195) (1 / 195) (1 / 195)
                                    |> Just
                                )
                , test "makeFromList should be able create identity matrix" <|
                    \_ ->
                        M4.makeFromList ([ 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1 ]) |> Expect.equal (Just M4.identity)
                , test "makeFromList should return Nothing for short list of elements" <|
                    \_ ->
                        M4.makeFromList ([]) |> Expect.equal Nothing
                , test "makeFromList should return Nothing for too long list of elements" <|
                    \_ ->
                        M4.makeFromList ([ 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 1 ]) |> Expect.equal Nothing
                , test "matrix should not lose precision" <|
                    \_ ->
                        let
                            matrix =
                                M4.makeFromList
                                    ([ 0.0007645259938837921, 0, 0, 0, 0, 0.0007645259938837921, 0, 0, -178844.39532879056, -115444.72328862673, -23930.400791413915, -0.4996215217852649, 179114.76199136386, 115619.29560235815, 23930.038231557068, 0.5003784782148529 ])
                        in
                            matrix
                                |> toString
                                |> Expect.equal "Just { 0 = 0.0007645259938837921, 1 = 0, 2 = 0, 3 = 0, 4 = 0, 5 = 0.0007645259938837921, 6 = 0, 7 = 0, 8 = -178844.39532879056, 9 = -115444.72328862673, 10 = -23930.400791413915, 11 = -0.4996215217852649, 12 = 179114.76199136386, 13 = 115619.29560235815, 14 = 23930.038231557068, 15 = 0.5003784782148529 }"
                , test "matrix should not lose precision" <|
                    \_ ->
                        let
                            matrix =
                                M4.makeBasis
                                    (V3.fromTuple ( 0.0007645259938837921, 0, 0 ))
                                    (V3.fromTuple ( 0, 0, 0 ))
                                    (V3.fromTuple ( 0, 0, -178844.39532879056 ))
                        in
                            matrix
                                |> toString
                                |> Expect.equal "{ 0 = 0.0007645259938837921, 1 = 0, 2 = 0, 3 = 0, 4 = 0, 5 = 0, 6 = 0, 7 = 0, 8 = 0, 9 = 0, 10 = -178844.39532879056, 11 = 0, 12 = 0, 13 = 0, 14 = 0, 15 = 1 }"
                ]
            ]
        ]