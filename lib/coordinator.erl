-module(coordinator).
-export([start/0]).

start() ->
  net_kernel:start([coordinator, shortnames]),
  erlang:nodes(visible),
  process_flag(trap_exit, true),
  register(coordinator, self()),
  io:format("Coordinator running...~n", []),
  preInitial({}).

preInitial(Values) ->
  receive
    {PID, setvalues, NewValues} ->
      io:format("Got some values.~n", []),
      PID ! "Received values.",
      preInitial(NewValues);
    {PID, setinitial} ->
      PID ! "Setting state to initial.",
      io:format("Initialized.~n", []),
      initial(Values, [])
  end.

initial({ProcCountFrom, ProcCountTo, WTimeFrom, WTimeTo, Timeout, Ggt}, Procs) ->
  receive
    {PID, getsteeringval} ->
      io:format("Sending steering vals.~n", []),
      PID ! {ok, {rand(ProcCountFrom, ProcCountTo), rand(WTimeFrom, WTimeTo), Timeout}},
      initial({ProcCountFrom, ProcCountTo, WTimeFrom, WTimeTo, Timeout, Ggt}, Procs);
    {hello, {PID, Name}} ->
      io:format("GCD process ~s said hello.~n", [Name]),
      PID ! {ok},
      initial({ProcCountFrom, ProcCountTo, WTimeFrom, WTimeTo, Timeout, Ggt}, [{PID, Name}|Procs]);
    {PID, setready} ->
      PID ! "Building ring.",
      io:format("Building ring.~n", []),
      buildRing(Procs),
      PID ! "Setting state to ready.",
      io:format("Ready for takeoff.~n", []),
      ready(Procs);
    Msg ->
      io:format("Did not understand ~w.~n", [Msg]),
      initial({ProcCountFrom, ProcCountTo, WTimeFrom, WTimeTo, Timeout, Ggt}, Procs)
  end.

buildRing(Procs) ->
  buildRing(Procs, []).

buildRing([], _Procs2) ->
  done;
buildRing([Left, Proc, Right | Rest], []) ->
  io:format("Ring 1~n", []),
  Left ! {setneighbours, {lists:last(Rest), Proc}},
  Proc ! {setneighbours, {Left, Right}},
  buildRing([Proc, Right | Rest], [Left]);
buildRing([Left, Proc, Right | Rest], Procs2) ->
  io:format("Ring 2~n", []),
  Proc ! {setneighbours, {Left, Right}},
  buildRing([Proc, Right | Rest], [Left | Procs2]);
buildRing([Left, Proc | []], Procs2) ->
  io:format("Ring 3~n", []),
  Proc ! {setneighbours, {Left, lists:last(Procs2)}},
  buildRing([], [Proc, Left | Procs2]).

ready(Procs) ->
  receive
    {setstartvalues, {Ggt}} ->
      setStartValues(Procs, Ggt),
      startGgt(Procs, Ggt)
  end.

setStartValues([], _Ggt) ->
  done;
setStartValues([{PID, _Name} | Rest], Ggt) ->
  PID ! {setinitial, {Ggt * rand(1,100) * rand(1,100)}},
  setStartValues(Rest, Ggt).

startGgt(Procs, Ggt) ->
  startGgt(Procs, Ggt, 3).

startGgt(_Procs, _Ggt, 0) ->
  done;
startGgt(Procs, _Ggt, _Counter) ->
  {Pid, _Name} = lists:nth(rand(1, length(Procs))),
  Pid ! {gcd, {_Ggt * rand(100, 10000)}}.


rand(From, To) when From < To ->
  random:uniform(To - From + 1) + From - 1.

