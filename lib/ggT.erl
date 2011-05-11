-module(ggT).
-export([start/0]).


start() ->
  waitForOrder().

waitForOrder() ->
  receive
    {PID, initialize} ->


gcd(A, 0) ->
  A;
gcd(A, B) ->
  gcd(B, A rem B).