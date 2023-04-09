module Main where

import Control.Applicative
import Data.Char

data JsonValue = JsonNull
               | JsonBool Bool
               | JsonNumber Integer -- NOTE who needs to support floats anyway
               | JsonString String
               | JsonArray [JsonValue]
               | JsonObject [(String, JsonValue)]
               deriving (Eq, Show)

-- NOTE, TODO: no error handling 
newtype Parser a = Parser
  { runParser :: String -> Maybe (String, a)
  }

instance Functor Parser where
  fmap f (Parser p) = Parser $ \input -> do
    (input', x) <- p input
    Just (input', f x)

instance Applicative Parser where
  pure x = Parser $ \input -> Just (input, x)
  (Parser p1) <*> (Parser p2) =
    Parser $ \input -> do
      (input', f) <- p1 input
      (input'', a) <- p2 input'
      Just (input'', f a)

instance Alternative Parser where
  empty = Parser $ \_ -> Nothing
  (Parser p1) <|> (Parser p2) = Parser $ \input ->
    p1 input <|> p2 input

jsonNull :: Parser JsonValue
jsonNull = (\_ -> JsonNull) <$> stringP "null"

charP :: Char -> Parser Char
charP x = Parser f
          where
            f (y:ys)
              | y == x = Just (ys, x)
              | otherwise = Nothing
            f [] = Nothing

stringP :: String -> Parser String
stringP = sequenceA . map charP

jsonBool :: Parser JsonValue
jsonBool = f <$> (stringP "true" <|> stringP "false")
   where f "true" = JsonBool True
         f "false" = JsonBool False

spanP :: (Char -> Bool) -> Parser String
spanP f = Parser $ \input ->
  let (token, rest) = span f input
    in Just (rest, token)

jsonNumber :: Parser JsonValue
jsonNumber = f <$> notNull (spanP isDigit)
  where f ds = JsonNumber $ read ds

notNull :: Parser [a] -> Parser [a]
notNull (Parser p) = Parser $ \input -> do
  (input', xs) <- p  input
  if null xs
    then Nothing
    else Just (input', xs)

jsonString :: Parser String
jsonString = undefined
  
jsonValue :: Parser JsonValue
jsonValue = jsonNull <|> jsonBool <|> jsonNumber

main :: IO ()
main = undefined
