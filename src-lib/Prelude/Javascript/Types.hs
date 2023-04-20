module Prelude.Javascript.Types where

import Parser.Types (ASTExpression')
import TypeChecker.Types

data JavascriptTypeHandler = JavascriptTypeHandler
  { properties :: [TypeHandlerContainer JavascriptTypeHandler] -> [(String, JavascriptTypeHandler)],
    call :: [TypeHandlerContainer JavascriptTypeHandler] -> Stack JavascriptTypeHandler -> [JavascriptTypeHandler] -> [ASTExpression'] -> Maybe JavascriptTypeHandler,
    getDom :: String,
    getCode :: String
  }

instance TypeHandler JavascriptTypeHandler where
  properties = Prelude.Javascript.Types.properties
  call = Prelude.Javascript.Types.call

instance Show JavascriptTypeHandler where
  show a = "JavascriptTypeHandler"
