{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE RankNTypes #-}

module Data.Conduit.Concurrent where

import Control.Concurrent.Async
import Control.Concurrent.STM
import Control.Exception
import Control.Monad.IO.Class
import Control.Monad.Trans.Control
import Data.Conduit
import Data.Conduit.List
import Prelude hiding (mapM_)

import Control.Concurrent (threadDelay)

buffer :: (MonadBaseControl IO m, MonadIO m)
       => Int -> Producer m a -> Consumer a m b -> m b
buffer _size input output = do
    chan <- liftIO $ newTChanIO
    control $ \runInIO ->
        bracketOnError
            (async $ runInIO $ input $$ mapM_ (submit chan))
            cancel
            (const $ runInIO $ loop chan $$ output)
  where
    submit chan = liftIO . atomically . writeTChan chan . Just

    loop chan = do
        mx <- liftIO $ atomically $ readTChan chan
        case mx of
            Nothing -> return ()
            Just x  -> yield x >> loop chan

($$&) :: (MonadIO m, MonadBaseControl IO m)
      => Producer m a -> Consumer a m b -> m b
($$&) = buffer 16

main :: IO ()
main = do
    liftIO $ putStrLn "Sequential case..."
    producer $$ consumer
    liftIO $ putStrLn "Concurrent case..."
    producer $$& consumer
  where
    producer = do
        liftIO $ putStrLn "Producing..."
        yield (1 :: Int)
        liftIO $ putStrLn "Producing..."
        yield 2
        liftIO $ putStrLn "Producing..."
        yield 3
        liftIO $ putStrLn "Done producing"

    consumer = do
        liftIO $ putStrLn "Consuming..."
        liftIO . print =<< await
        liftIO $ threadDelay 1000000
        liftIO $ putStrLn "Consuming..."
        liftIO . print =<< await
        liftIO $ threadDelay 1000000
        liftIO $ putStrLn "Consuming..."
        liftIO . print =<< await
        liftIO $ putStrLn "Done consuming"
