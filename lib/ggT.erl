-module(ggT).
-export([start/4]).


start(Coordinator, Name, WTime, Term) ->
  hello(Coordinator, Name, 10),
  waitForOrder().
  
hello(_,_,0) ->
  {error};
hello(Coordinator, Name, Count) ->
  Coordinator ! {hello, {self(), Name}},
  receive 
    {ok} ->
      {ok};
    {error} ->
      hello(Coordinator, Name, Count-1)
  end.

waitForOrder() ->
  receive
    {setneighbours, {Pidl, Pidr}}


gcd(A, 0) ->
  A;
gcd(A, B) ->
  gcd(B, A rem B).