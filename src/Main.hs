{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE PartialTypeSignatures #-}
{-# LANGUAGE PolyKinds #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE TupleSections #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE TypeOperators #-}
{-# OPTIONS_GHC -fno-warn-partial-type-signatures #-}

module Main where

import Data.List (find)
import Data.Proxy
import Data.Text (Text)
import Mu.GraphQL.Quasi
import Mu.GraphQL.Server
import Mu.Schema
import Mu.Server

graphql "ServiceDefinition" "schema.graphql"

-- GraphQL App

main :: IO ()
main = do
  putStrLn "starting GraphQL server on port 8080"
  runGraphQLAppQuery 8080 server (Proxy @"Query")

type ServiceMapping =
  '[ "Book" ':-> (Text, Text),
     "Author" ':-> Text
   ]

library :: [(Text, [Text])]
library =
  [ ("Robert Louis Stevenson", ["Treasure Island", "Strange Case of Dr Jekyll and Mr Hyde"]),
    ("Immanuel Kant", ["Critique of Pure Reason"]),
    ("Michael Ende", ["The Neverending Story", "Momo"])
  ]

server :: forall m. MonadServer m => ServerT ServiceMapping ServiceDefinition m _
server =
  resolver
    ( object @"Book"
        ( field @"title" bookTitle,
          field @"author" bookAuthor
        ),
      object @"Author"
        ( field @"name" authorName,
          field @"books" authorBooks
        ),
      object @"Query"
        ( method @"authors" allAuthors,
          method @"books" allBooks
        )
    )
  where
    bookTitle :: (Text, Text) -> m Text
    bookTitle (_, title) = pure title
    bookAuthor :: (Text, Text) -> m Text
    bookAuthor (auth, _) = pure auth
    authorName :: Text -> m Text
    authorName = pure
    authorBooks :: Text -> m [(Text, Text)]
    authorBooks name = pure $ (name,) <$> maybe [] snd (find ((== name) . fst) library)
    allAuthors :: m [Text]
    allAuthors = pure $ fst <$> library
    allBooks :: m [(Text, Text)]
    allBooks = pure [(author, title) | (author, books) <- library, title <- books]
