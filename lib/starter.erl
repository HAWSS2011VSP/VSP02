-module(starter).
-export([start/4]).

start(Coordinator, PraktID, TeamID, StarterID) ->
  net_kernel:start([node()]),
  net_kernel:connect_node(Coordinator),
  case getValues({coordinator, Coordinator}, 10) of
    {ok, {PNum, WTime, Term}} ->
      io:format("Got steering vals, starting gcd processes. ~n", []),
      startGCD({coordinator, Coordinator}, PNum, utils:mkString("", [PraktID, TeamID, PNum, StarterID]), WTime, Term);
    {error, Msg} ->
      io:write("Error: ~s~n", [Msg])
    end.

startGCD(_Coordinator, 0, _, _, _) ->
  io:format("Started all gcd procs, going to sleep.~n", []),
  sleep();
startGCD(Coordinator, PNum, Name, WTime, Term) ->
  io:format("Starting gcd process ~w.~n", [PNum]),
  spawn(ggT, start, [Coordinator, utils:mkString("", [Name, PNum]), WTime, Term]),
  startGCD(Coordinator, PNum-1, Name, WTime, Term).

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

sleep() ->
  receive
  after 500 ->
      sleep()
  end.

