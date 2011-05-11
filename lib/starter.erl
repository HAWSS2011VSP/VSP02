-module(starter).
-export([start/0]).

start() ->
  loop().

loop() ->
  Values = getValues(10).

getValues(PID, 0) ->
  {error, "Could not get values from server."};
getValues(PID, X) ->

  getValues()