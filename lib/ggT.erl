-module(ggT).
-export([start/4]).


start(Coordinator, Name, WTime, Term) ->
  {_Module, Node} = Coordinator,
  net_kernel:connect_node(Node),
  hello(Coordinator, Name, 10),
  waitForOrder(Coordinator, WTime, Term, nil, nil, 1).
  
hello(_,_,0) ->
  {error};
hello(Coordinator, Name, Count) ->
  io:format("GCD proc ~s sending hello to ~w...~n", [Name, Coordinator]),
  Coordinator ! {hello, {self(), utils:mkString("", [Name, Count])}},
  receive 
    {ok} ->
      {ok};
    {error} ->
      hello(Coordinator, Name, Count-1)
  end.

waitForOrder(Coordinator, WTime, Term, Pidl, Pidr, Mi) ->
  receive
    {setneighbours, {NewPidl, NewPidr}} ->
      waitForOrder(Coordinator, WTime, Term, NewPidl, NewPidr, Mi);
    {setinitial, {Value}} ->
      waitForOrder(Coordinator, WTime, Term, Pidl, Pidr, Value);
    {gcd, {Num}} ->
      NewMi = Mi rem Num,
      timer:sleep(WTime),
      if
        NewMi =/= Mi ->
          report(Coordinator, NewMi),
          waitForOrder(Coordinator, WTime, Term, Pidl, Pidr, NewMi);
        true ->
          waitForOrder(Coordinator, WTime, Term, Pidl, Pidr, Mi)
      end
  end.

report(Coordinator, Mi) ->
  Coordinator ! {newvalue, {self(), Mi}}.

