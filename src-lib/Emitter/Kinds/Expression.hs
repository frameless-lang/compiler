{-# LANGUAGE LambdaCase #-}
{-# OPTIONS_GHC -Wno-unrecognised-pragmas #-}

{-# HLINT ignore "Redundant bracket" #-}

module Emitter.Kinds.Expression where

import Control.Monad.State.Lazy (get)
import Data.Foldable (find)
import Emitter.Types
import Emitter.Util (getFreshExprId, nameToVariable, slashToCamelCase, slashToDash, variableToString)
import Parser.Kinds.LeftHandSide (leftHandSideVariableParser)
import Types

stringHandler :: TypeHandler
stringHandler stack typeDefinition@(TypeAlgebraicDataType "String" []) =
  Just
    ( \untypedExpression ->
        StackHandler
          { runPrimitive =
              do
                result <-
                  case untypedExpression of
                    Left (result) -> do
                      return [result]
                    Right (RightHandSideString strings) -> do
                      mapM
                        ( \case
                            RightHandSideStringStatic static -> do
                              return ([], [Ln static])
                            RightHandSideStringDynamic untypedExpression -> do
                              (TypedExpression typedExpression) <- toTypedExpression' stack typeDefinition untypedExpression
                              runPrimitive typedExpression
                        )
                        strings
                    Right (RightHandSideVariable variableName) ->
                      error (show untypedExpression)
                return (concatMap fst result, Ln "\"" : concatMap snd result ++ [Ln "\""]),
            runFunctionApplication = \_ -> error "no function application implemented",
            runProperty = \_ -> error "no property access implemented",
            runResolvedType = typeDefinition
          }
    )
stringHandler _ _ = Nothing

recordHandler :: TypeHandler
recordHandler stack typeDefinition@(TypeRecord properties) =
  Just
    ( \untypedExpression ->
        StackHandler
          { runPrimitive =
              do
                result <-
                  case untypedExpression of
                    Left result -> do
                      return [result]
                    Right _ ->
                      error (show untypedExpression)
                return (concatMap fst result, Ln "\"" : concatMap snd result ++ [Ln "\""]),
            runFunctionApplication = \_ -> error "no function application implemented",
            runProperty = \_ -> error "no property access implemented",
            runResolvedType = typeDefinition
          }
    )
recordHandler _ _ = Nothing

componentHandler :: TypeHandler
componentHandler stack typeDefinition@(TypeFunction [typedProperties, _] (TypeAlgebraicDataType "View" [])) =
  Just
    ( \(Right (RightHandSideFunctionDefinition [leftHandSideProperties, leftHandSideAttributes] body)) ->
        StackHandler
          { runPrimitive =
              do
                appState <- get
                exprId <- getFreshExprId
                let scope = [DotNotation "this"]
                let componentName' = componentName appState
                let unscopedMounted = nameToVariable "mounted" exprId
                let unscopedProperties = nameToVariable "properties" exprId
                let scopedMounted = scope ++ unscopedMounted
                let scopedProperties = scope ++ unscopedProperties
                -- let typedProperties = typedOrigin scopedProperties propertyTypes
                let stack' = addToVariableStack stack [(leftHandSideProperties, typedOrigin stack scopedProperties typedProperties)]

                view <- render stack' body [] (scope ++ [DotNotation "shadowRoot"]) []

                return
                  ( [],
                    [ Ln ("class " ++ slashToCamelCase componentName' ++ " extends HTMLElement {"),
                      Ind
                        [ Ln (variableToString unscopedMounted ++ " = false;"),
                          Br,
                          Ln (variableToString unscopedProperties ++ " = {};"),
                          Br,
                          Ln "connectedCallback() {",
                          Ind
                            ( [ Ln "this.attachShadow({mode: 'open'});",
                                Br,
                                Ln (variableToString scopedMounted ++ " = true;"),
                                Br
                              ]
                                ++ runViewCreate view
                            ),
                          Br,
                          Ln "}"
                        ],
                      Ln "}",
                      Br,
                      Br,
                      Ln ("customElements.define(\"" ++ slashToDash componentName' ++ "\", " ++ slashToCamelCase componentName' ++ ");"),
                      Br
                    ]
                  ),
            runFunctionApplication = \_ -> error "no function application implemented",
            runProperty = \_ -> error "no property access implemented",
            runResolvedType = typeDefinition
          }
    )
componentHandler _ _ = Nothing

prelude :: [StackEntry]
prelude =
  [ StackType stringHandler,
    StackType recordHandler,
    StackType componentHandler
  ]

toTypedExpression :: Stack -> TypeDefinition -> UntypedExpression -> AppStateMonad TypedExpression
toTypedExpression = toTypedExpression'

toTypedExpression' :: Stack -> TypeDefinition -> UntypedExpression -> AppStateMonad TypedExpression
toTypedExpression' stack typeDefinition ((RightHandSideVariable variableName) : restUntypedExpression) = do
  case ( find
           ( \case
               (StackValue (variableName', _)) -> variableName' == variableName
               _ -> False
           )
           stack
       ) of
    Just (StackValue (_, typedExpression)) -> do return typedExpression
    Nothing -> error ("Could not find variable" ++ variableName)
toTypedExpression' stack typeDefinition (untypedExpression : restUntypedExpression) = do
  return (TypedExpression (findType stack typeDefinition (Right untypedExpression)))

findType :: Stack -> TypeDefinition -> (StackParameter -> StackHandler)
findType stack = findType' (stack, stack)

findType' :: (Stack, Stack) -> TypeDefinition -> (StackParameter -> StackHandler)
findType' ([], _) typeDefinition = error ("no corresponding type found " ++ show typeDefinition)
findType' ((StackType stackEntry) : nextStack, allStack) typeDefinition =
  case stackEntry allStack typeDefinition of
    Just result -> result
    Nothing -> findType' (nextStack, allStack) typeDefinition
findType' (_ : nextStack, allStack) typeDefinition = findType' (nextStack, allStack) typeDefinition

addToVariableStack :: Stack -> [(LeftHandSide, TypedExpression)] -> Stack
addToVariableStack variableStack [] = variableStack
addToVariableStack variableStack ((LeftHandSideHole, _) : restNewVariables) = addToVariableStack variableStack restNewVariables
addToVariableStack variableStack ((LeftHandSideVariable name, typedExpression) : restNewVariables) = (StackValue (name, typedExpression)) : addToVariableStack variableStack restNewVariables

-- view

render :: Stack -> [Statement] -> [Variable] -> Parent -> [Sibling] -> AppStateMonad ViewResult
render variableStack [] scope parent siblings = do
  return
    ViewResult {runViewCreate = [], runViewUpdate = [], runViewUnmount = [], runViewDelete = [], runSiblings = siblings}
render variableStack ((UntypedExpression [RightHandSideHost elementName properties children]) : restUntypedBody) scope parent siblings = do
  exprId <- getFreshExprId
  let hostElement = scope ++ nameToVariable "element" exprId
  childrenResult <- render variableStack children scope hostElement []
  siblingResult <- render variableStack restUntypedBody scope parent (siblings ++ [hostElement])

  return
    ( ViewResult
        { runViewCreate =
            [ Ln (variableToString hostElement ++ " = document.createElement(\"" ++ elementName ++ "\");"),
              Br
            ]
              ++ appendElement parent siblings hostElement
              ++ runViewCreate childrenResult
              ++ runViewCreate siblingResult,
          runViewUpdate =
            runViewUpdate childrenResult
              ++ runViewUpdate siblingResult,
          runViewUnmount =
            runViewUnmount childrenResult
              ++ runViewUnmount siblingResult,
          runViewDelete =
            runViewDelete childrenResult
              ++ runViewDelete siblingResult,
          runSiblings = runSiblings siblingResult
        }
    )
render variableStack ((UntypedExpression untypedExpression) : restUntypedBody) scope parent siblings = do
  TypedExpression typedResult <- toTypedExpression variableStack (TypeAlgebraicDataType "String" []) untypedExpression
  exprId <- getFreshExprId
  let textElement = scope ++ nameToVariable "text" exprId
  (dependencies, textContent) <- runPrimitive typedResult
  siblingResult <- render variableStack restUntypedBody scope parent (siblings ++ [textElement])

  return
    ( ViewResult
        { runViewCreate =
            Ln (variableToString textElement ++ " = document.createTextNode(") :
            textContent
              ++ [ Ln ");",
                   Br
                 ]
              ++ appendElement parent siblings textElement
              ++ runViewCreate siblingResult,
          runViewUpdate = runViewUpdate siblingResult,
          runViewUnmount = runViewUnmount siblingResult,
          runViewDelete = runViewDelete siblingResult,
          runSiblings = runSiblings siblingResult
        }
    )
render variableStack untypedBody scope parent siblings = error "mep"

appendElement :: Parent -> [Sibling] -> [Variable] -> [Code]
appendElement parent [] element =
  Ln (variableToString parent ++ ".append(") : [Ln (variableToString element), Ln ");", Br]
appendElement parent siblings element =
  let lastSibling = last siblings
   in ( Ln (variableToString lastSibling ++ ".after(") : [Ln (variableToString element), Ln ");", Br]
      )

typedOrigin :: Stack -> [Variable] -> TypeDefinition -> TypedExpression
typedOrigin stack variablePath typeDefinition = TypedExpression (findType stack typeDefinition (Left ([variablePath], [Ln (variableToString variablePath)])))