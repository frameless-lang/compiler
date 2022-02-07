module Emitter.Types.Root where

import Control.Monad.State.Lazy (runState)
import Data.List (intersperse)
import Emitter.Types (AppState (AppState), AppStateMonad, Code (..))
import Emitter.Types.RootAssignment (rootAssignment)
import Emitter.Types.RootDeclaration (algebraicDataTypeConstructor)
import Types

compileRoot :: String -> [Root] -> String
compileRoot componentName roots =
  let code = compileRoot' roots
      (result, _) = runState code (AppState componentName 0)
   in codeToString 0 True result

compileRoot' :: [Root] -> AppStateMonad [Code]
compileRoot' [] = do return []
compileRoot' (RootDataDeclaration _ dataDeclarations : restRoot) = do
  result <- algebraicDataTypeConstructor dataDeclarations
  next <- compileRoot' restRoot

  return (result ++ next)
compileRoot' (RootAssignment name expression : restRoot) = do
  result <- rootAssignment name expression
  next <- compileRoot' restRoot
  return (result ++ next)

codeToString :: Int -> Bool -> [Code] -> String
codeToString indentationLevel first [] = ""
codeToString indentationLevel first (Ind nestedCode : restCode) =
  codeToString (indentationLevel + 1) True nestedCode ++ "\n"
    ++ codeToString indentationLevel True restCode
codeToString indentationLevel first (Ln code : restCode)
  | first = '\n' : replicate indentationLevel '\t' ++ code'
  | otherwise = code'
  where
    code' = code ++ codeToString indentationLevel False restCode
codeToString indentationLevel first (Br : restCode) = '\n' : codeToString indentationLevel True restCode