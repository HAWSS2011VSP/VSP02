-module(starter).
-export([start/1]).

start(Coordinator, PraktID, TeamID, StarterID) ->
  case getValues(Coordinator, 10) of
    {ok, {PNum, WTime, Term}} ->
      startGCD(Coordinator, utils:mkString("", [PraktID, TeamID, PNum, StarterID]), WTime, Term)
    {error, Msg} ->
      io:write("Error: ~s~n", [Msg])
    end.

startGCD(_Coordinator, 0, _, _) ->
  {ok};
startGCD(Coordinator, PNum, WTime, Term, TeamID, StarterID) ->
  spawn(ggT, start, [Coordinator, WTime, Term, PNum, TeamID, StarterID]).

getValues(_Coordinator, 0) ->
  {error, "Could not get values from server."};
getValues(Coordinator, X) ->
  Coordinator ! {self(), getsteeringval},
  receive
    {ok, {PNum, WTime, Term}} ->
      {ok, {PNum, WTime, Term}};
    {error, Msg} ->
      io:write("Error: ~s, trying again.~n",[Msg]),
      getValues(Coordinator, X-1)
  after 500 ->
    io:write("Error: timeout, trying again.~n",[]),
    getValues(Coordinator, X-1)
  end.
