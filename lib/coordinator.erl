-module(coordinator).
-export([start/0]).

start() ->
  loop()

loop() ->
  receive
    {}