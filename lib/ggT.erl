-module(ggT).
-export([start/4]).


start(Coordinator, Name, WTime, Term) ->
  {_Module, Node} = Coordinator,
  net_kernel:connect_node(Node),
  hello(Coordinator, Name, 10),
  waitForOrder(Coordinator, Name, WTime, Term, nil, nil, 1).

hello(_,_,0) ->
  {error};
hello(Coordinator, Name, Count) ->
  io:format("GCD proc ~s sending hello to ~w...~n", [Name, Coordinator]),
  Coordinator ! {hello, {self(), Name}},
  receive 
    {ok} ->
      io:format("~s registered and waiting for order.~n", [Name]),
      {ok};
    {error} ->
      hello(Coordinator, Name, Count-1)
  end.

waitForOrder(Coordinator, Name, WTime, Term, Pidl, Pidr, Mi) ->
  receive
    {setneighbours, {NewPidl, NewPidr}} ->
      io:format("~s got his neighbours.~n", [Name]),
      waitForOrder(Coordinator, Name, WTime, Term, NewPidl, NewPidr, Mi);
    {setinitial, {Value}} ->
      io:format("~s got initial value: ~w~n", [Name, Value]),
      waitForOrder(Coordinator, Name, WTime, Term, Pidl, Pidr, Value);
    {gcd, {Num}} ->
      io:format("~s calculating gcd.~n", [Name]),
      NewMi = Mi rem Num,
      timer:sleep(WTime),
      if
        NewMi =/= Mi ->
          report(Coordinator, Name, NewMi),
          waitForOrder(Coordinator, Name, WTime, Term, Pidl, Pidr, NewMi);
        true ->
          waitForOrder(Coordinator, Name, WTime, Term, Pidl, Pidr, Mi)
      end
  end.

report(Coordinator, Name, Mi) ->
  Coordinator ! {newvalue, {self(), Name, Mi, currentTimeInSillyFormat()}}.

currentTimeInSillyFormat() ->
  {Hour, Minute, Second} = time(),
  list_to_integer(utils:mkString("", 
      [leadingZero(Hour), leadingZero(Minute), leadingZero(Second)])).

leadingZero(Num) when Num < 10 ->
  utils:mkString("", [0,Num]);
leadingZero(Num) -> Num.

