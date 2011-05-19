-module(coordinator).
-export([start/1]).

start(Values) ->
  receive
    {setvalues, Values} ->
      start(Values);
    {setinitial} ->
      initial(Values, [])
  end.

initial({ProcCountFrom, ProcCountTo, WTimeFrom, WTimeTo, Timeout, Ggt}, Procs) ->
  receive
    {PID, getsteeringval} ->
      PID ! {ok, {rand(ProcCountFrom, ProcCountTo), rand(WTimeFrom, WTimeTo), Timeout}},
      initial({ProcCountFrom, ProcCountTo, WTimeFrom, WTimeTo, Timeout, Ggt}, Procs);
    {hello, {PID, Name}} ->
      initial({ProcCountFrom, ProcCountTo, WTimeFrom, WTimeTo, Timeout, Ggt}, [{PID, Name}|Procs]);
    {_PID, setready} ->
      buildRing(Procs),
      ready(Procs)
  end.

buildRing(Procs) ->
  buildRing(Procs, []).

buildRing([], _Procs2) ->
  done;
buildRing([Left, Proc, Right | Rest], []) ->
  Left ! {setneighbours, {lists:last(Rest), Proc}},
  Proc ! {setneighbours, {Left, Right}},
  buildRing([Proc, Right | Rest], [Left]);
buildRing([Left, Proc, Right | Rest], Procs2) ->
  Proc ! {setneighbours, {Left, Right}},
  buildRing([Proc, Right | Rest], [Left | Procs2]);
buildRing([Left, Proc | []], Procs2) ->
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
  PID ! {setinitial, {Ggt * rand(1,100)}},
  setStartValues(Rest, Ggt).

startGgt(Procs, Ggt) ->
  startGgt(Procs, Ggt, 3).

startGgt(Procs, _Ggt, 0) ->
  done;
startGgt(Procs, _Ggt, _Counter) ->
  {Pid, _Name} = lists:nth(rand(1, length(Procs))),
  Pid ! {gcd, {_Ggt * rand(100, 10000)}}.


rand(From, To) when From < To ->
  random:uniform(To - From + 1) + From - 1.
