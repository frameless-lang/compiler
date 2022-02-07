module Emitter.Types.Expression where

import Data.List (intersperse)
import Emitter.Types
import Types

expressionToCode :: Expression -> AppStateMonad [Code]
expressionToCode [] = do
  return []
expressionToCode (expression : expressions) = do
  result <- expressionToCode' expression
  next <- expressionToCode expressions
  return
    ( if null next
        then result
        else result ++ [Ln "."] ++ next
    )

expressionToCode' :: Expression' -> AppStateMonad [Code]
expressionToCode' (RightHandSideRecord _) = do
  return
    [ Ln "{",
      Ln "}"
    ]