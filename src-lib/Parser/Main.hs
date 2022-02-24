module Parser.Main where

import Control.Monad.State.Strict (runState)
import Data.Void (Void)
import Parser.Kinds.Root (rootParser)
import Parser.Types
import Text.Megaparsec (State, eof, many, parse)
import Text.Megaparsec.Char (eol)
import Text.Megaparsec.Error
import Types

initialState :: IndentationLevel -> ParserState
initialState indentationLevel = indentationLevel

parseRoot = parse parseRoot' ""

parseRoot' :: Parser [Root]
parseRoot' = many (many eol *> (rootParser <* many eol)) <* eof