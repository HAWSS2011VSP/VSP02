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
      initial({ProcCountFrom, ProcCountTo, WTimeFrom, WTimeTo, Timeout, Ggt}, [PID|Procs]);
    {PID, setready} ->
      PID ! "Building ring.",
      io:format("Building ring.~n", []),
      buildRing(Procs),
      PID ! "Setting start values.",
      setStartValues(Procs, Ggt),
      PID ! "Starting calculation.",
      timer:sleep(1000),
      startGgt(Procs, Ggt),
      waitForResult(PID, Procs, Ggt);
    Msg ->
      io:format("Did not understand ~w.~n", [Msg]),
      initial({ProcCountFrom, ProcCountTo, WTimeFrom, WTimeTo, Timeout, Ggt}, Procs)
  end.

buildRing(Procs) ->
  io:format("building ring with ~w.~n", [Procs]),
  buildRing(Procs, lists:last(Procs), []).

buildRing([], _Recent, _Procs2) ->
  done;
buildRing([Proc, Right | []], Recent, Procs2) ->
  io:format("Ring 3~n", []),
  Proc ! {setneighbours, {Recent, Right}},
  Right ! {setneighbours, {Proc, lists:last(Procs2)}},
  buildRing([], Proc, [ Right, Proc | Procs2]);
buildRing([Proc, Right | Rest], Recent, []) ->
  io:format("Ring 1~n", []),
  Proc ! {setneighbours, {Recent, Right}},
  buildRing([Right | Rest], Proc, [Proc]);
buildRing([Proc, Right | Rest], Recent, Procs2) ->
  io:format("Ring 2~n", []),
  Proc ! {setneighbours, {Recent, Right}},
  buildRing([Right | Rest], Proc, [Proc | Procs2]);
buildRing(Procs, Recent, Procs2) ->
  io:format("Something shitty... ~w ~w ~w~n", [Procs, Recent, Procs2]).

setStartValues([], _Ggt) ->
  done;
setStartValues([PID | Rest], Ggt) ->
  PID ! {setinitial, {Ggt * rand(1,100) * rand(1,100)}},
  setStartValues(Rest, Ggt).

startGgt(Procs, Ggt) ->
  startGgt(Procs, Ggt, 3).

startGgt(_Procs, _Ggt, 0) ->
  done;
startGgt(Procs, Ggt, Counter) ->
  Pid = lists:nth(rand(1, length(Procs)), Procs),
  Pid ! {gcd, {Ggt * rand(100, 10000)}},
  startGgt(lists:delete(Pid, Procs), Ggt, Counter-1).

waitForResult(Logger, Procs, Ggt) ->
  receive
    {newvalue, {Pid, Name, Mi, Time}} ->
      io:format("[~w] Got new Mi from ~s: ~w~n", [Time, Name, Mi]),
      Logger ! utils:mkString("", ["[", Time, "] Got new Mi from ", Name, ": ", Mi]),
      waitForResult(Logger, Procs, Ggt);
    {result, {Pid, Name, Result, Time}} ->
      io:format("[~w] Got result from ~s: ~w~n", [Time, Name, Result]),
      Logger ! utils:mkString("", ["Got Result: ", Result]),
      waitForResult(Logger, Procs, Ggt);
    {ready, {Name}} ->
      Logger ! utils:mkString("", [Name, " is ready to take new values."]),
      waitForResult(Logger, Procs, Ggt);
    {Pid, setready} ->
      startGgt(Procs, Ggt),
      waitForResult(Logger, Procs, Ggt)
  end.

rand(From, From) -> From;
rand(From, To) when From < To ->
  random:uniform(To - From + 1) + From - 1.

