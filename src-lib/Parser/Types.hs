module Parser.Types where

import Data.Void (Void)
import Text.Megaparsec (Parsec)

type Parser = Parsec Void String

type IndentationLevel = Int

type AST = [ASTRootNodeGrouped]

data ASTRootNodeUngrouped
  = ASTRootNodeUngroupedAlgebraicDataTypeDeclaration String [(String, [ASTTypeDeclaration])]
  | ASTRootNodeUngroupedMacro String
  | ASTRootNodeUngroupedTypeAssignment String ASTTypeDeclaration
  | ASTRootNodeUngroupedAssignment String ASTExpression
  deriving (Show)

data ASTRootNodeGrouped
  = ASTRootNodeGroupedAlgebraicDataTypeDeclaration String [(String, [ASTTypeDeclaration])]
  | ASTRootNodeGroupedAssignment String (Maybe String) (Maybe ASTTypeDeclaration) [ASTExpression]

data ASTTypeDeclaration
  = ASTTypeDeclarationAlgebraicDataType String [ASTTypeDeclaration]
  | ASTTypeDeclarationFunction [ASTTypeDeclaration] ASTTypeDeclaration
  | ASTTypeDeclarationRecord [(String, ASTTypeDeclaration)]
  deriving (Show)

data ASTStatement
  = ASTStatementVariableAssignment ASTLeftHandSide ASTExpression
  | ASTExpression ASTExpression
  | ASTStream ASTLeftHandSide ASTExpression
  deriving (Show)

type GroupedRecordOption = (String, (Maybe ASTTypeDeclaration, [(Maybe String, ASTExpression)]))

type ASTRecord = ([GroupedRecordOption], [ASTStatement])

data ASTString
  = ASTStringStatic String
  | ASTStringDynamic ASTExpression
  deriving (Show)

type Operator = String

type ASTExpression = [ASTExpression']

data ASTExpression'
  = ASTExpressionVariable String
  | ASTExpressionList [ASTExpression] [ASTStatement]
  | ASTExpressionRecord ASTRecord
  | ASTExpressionAlgebraicDataType String [ASTExpression]
  | ASTExpressionNumber Int
  | ASTExpressionRange Int (Maybe Int)
  | ASTExpressionString [ASTString]
  | ASTExpressionFunctionDeclaration [ASTLeftHandSide] [ASTStatement]
  | ASTExpressionFunctionCall [ASTExpression]
  | ASTExpressionOperator Operator ASTExpression ASTExpression
  | ASTExpressionCondition ASTExpression [ASTStatement] [ASTStatement]
  | ASTExpressionMatch ASTExpression [(ASTLeftHandSide, [ASTStatement])]
  | ASTExpressionHost String ASTRecord [ASTStatement]
  | ASTExpressionFragment [ASTExpression]
  deriving (Show)

data ASTLeftHandSide
  = ASTLeftHandSideVariable String
  | ASTLeftHandSideList [ASTLeftHandSide]
  | ASTLeftHandSideRecord [(String, Maybe ASTLeftHandSide)]
  | ASTLeftHandSideAlgebraicDataType String [ASTLeftHandSide]
  | ASTLeftHandSideAlias String ASTLeftHandSide
  | ASTLeftHandSideHole
  deriving (Show)
