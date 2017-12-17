module Internal.Numbers exposing (customInterval, defaultInterval, normalizedInterval, correctFloat, magnitude)

{-| -}

import Regex
import Round
import Lines.Coordinate as Coordinate exposing (..)



{-| -}
defaultInterval : Int -> Coordinate.Limits -> List Float
defaultInterval numOfTicks limits =
    let
      tickRange =
        (limits.max - limits.min) / toFloat numOfTicks -- TODO Correct for axis length

      interval =
        normalizedInterval tickRange [] (magnitude tickRange) True
    in
    customInterval limits.min interval limits


{-| TODO TEST ME -}
customInterval : Float -> Float -> Coordinate.Limits -> List Float
customInterval intersection delta limits =
    let
        firstValue =
          intersection - offset (intersection - limits.min)

        offset value =
          toFloat (floor (value / delta)) * delta

        ticks result index =
          let next = position delta firstValue index in
            if next <= limits.max
              then ticks (result ++ [ next ]) (index + 1)
              else result
    in
    ticks [] 0



-- INTERNAL


position : Float -> Float -> Int -> Float
position delta firstValue index =
    firstValue + toFloat index * delta
        |> Round.round (deltaPrecision delta)
        |> String.toFloat
        |> Result.withDefault 0


deltaPrecision : Float -> Int
deltaPrecision delta = -- TODO make this better...
    delta
        |> toString
        |> Regex.find (Regex.AtMost 1) (Regex.regex "\\.[0-9]*")
        |> List.map .match
        |> List.head
        |> Maybe.withDefault ""
        |> String.length
        |> (-) 1
        |> min 0
        |> abs



-- NORMALIZED


normalizedInterval : Float -> List Float -> Float -> Bool -> Float
normalizedInterval intervalRaw multiples_ magnitude allowDecimals =
  let
    normalized =
      intervalRaw / magnitude

    multiples =
      if List.isEmpty multiples_ then
       produceMultiples magnitude allowDecimals
      else
        multiples_

    findMultiple multiples interval =
      case multiples of
        m1 :: m2 :: rest ->
          if normalized <= (m1 + m2) / 2 then m1 else findMultiple rest interval

        m1 :: rest ->
          if normalized <= m1 then m1 else findMultiple rest interval

        [] ->
          1

    correctBack interval =
      correctFloat (interval * magnitude) 3
  in
  correctBack <|findMultiple multiples intervalRaw


produceMultiples : Float -> Bool -> List Float
produceMultiples magnitude allowDecimals =
  let
    defaults =
      [ 1, 2, 2.5, 5, 10 ]
  in
    if allowDecimals then
      defaults
    else
      if magnitude == 1 then
        List.filter (\n -> toFloat (round n) /= n) defaults
      else if magnitude <= 0.1 then
        [ 1 / magnitude ]
      else
        defaults


{-| -}
correctFloat : Float -> Int -> Float
correctFloat number prec =
  case String.split "." <| toString number ++ String.repeat (prec + 1) "0" of -- TODO
    [ before, after ] ->
        let
          toFloatSafe = String.toFloat >> Result.withDefault 0
          decimals = String.slice 0 prec after
        in
          toFloatSafe <| before ++ "." ++ decimals

    _ ->
       number


{-| -}
magnitude : Float -> Float
magnitude num =
  toFloat <| 10 ^ (floor (logBase e num / logBase e 10))
