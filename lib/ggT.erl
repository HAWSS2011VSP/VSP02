-module(ggT).
-export([start/4]).


start(Coordinator, Name, WTime, Term) ->
  {_Module, Node} = Coordinator,
  net_kernel:connect_node(Node),
  hello(Coordinator, Name, 10),
  waitForOrder(Coordinator, Name, WTime, Term, nil, nil, 1, 0).

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

waitForOrder(Coordinator, Name, WTime, Term, Pidl, Pidr, Mi, LastRecv) ->
  receive
    {setneighbours, {NewPidl, NewPidr}} ->
      io:format("~s got his neighbours.~n", [Name]),
      waitForOrder(Coordinator, Name, WTime, Term, NewPidl, NewPidr, Mi, LastRecv);
    {setinitial, {Value}} ->
      io:format("~s got initial value: ~w~n", [Name, Value]),
      waitForOrder(Coordinator, Name, WTime, Term, Pidl, Pidr, Value, LastRecv);
    {gcd, {Num}} ->
      io:format("~s calculating gcd.~n", [Name]),
      NewMi = Mi rem Num,
      timer:sleep(WTime),
      if
        NewMi == 0 ->
          io:format("Maybe got the value: ~w~n", [Num]),
          waitForOrder(Coordinator, Name, WTime, Term, Pidl, Pidr, Num, utils:nowTimestamp());
        NewMi =/= Mi ->
          report(Coordinator, Name, NewMi),
          Pidr ! {gcd, {NewMi}},
          waitForOrder(Coordinator, Name, WTime, Term, Pidl, Pidr, NewMi, utils:nowTimestamp());
        true ->
          io:format("~s: No change after calculation.~n", [Name]),
          Pidr ! {gcd, {Mi}},
          waitForOrder(Coordinator, Name, WTime, Term, Pidl, Pidr, Mi, utils:nowTimestamp())
      end;
      {terminate, Pid} ->
        Last = (utils:nowTimestamp() - LastRecv) / 2,
        if 
          Last =< 0 ->
            Pidr ! {terminate, self()},
            Pid ! shouldTerminate(Pidr);
          true ->
            Pid ! {self(), no}
        end,
        waitForOrder(Coordinator, Name, WTime, Term, Pidl, Pidr, Mi, utils:nowTimestamp())
  after Term ->
    Pidr ! {terminate, self()},
    ShouldTerminate = terminationMode(Pidl),
    if 
      ShouldTerminate ->
        Coordinator ! {result, {self(), Name, Mi, currentTimeInSillyFormat()}},
        waitForOrder(Coordinator, Name, WTime, Term, Pidl, Pidr, Mi, utils:nowTimestamp());
      true ->
        waitForOrder(Coordinator, Name, WTime, Term, Pidl, Pidr, Mi, utils:nowTimestamp())
    end
  end.

terminationMode(Pidl) ->
  receive
    {terminate, Pidl} ->
      Pidl ! {self(), yes},
      terminationMode(Pidl);
    {Pid, yes} ->
      io:format("should terminate~n", []),
      true;
    {Pid, no} ->
      io:format("should not terminate~n", []),
      false
  end.

shouldTerminate(Pid) ->
  receive
    {Pid, Answer} ->
      io:format("Should terminate? Received ~w~n", [Answer]),
      Answer
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

