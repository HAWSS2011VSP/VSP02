-module(coordinator).
-export([start/0]).

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
      initial({ProcCountFrom, ProcCountTo, WTimeFrom, WTimeTo, Timeout, Ggt}, [{PID, Name}|Procs]) 
  end.

rand(From, To) if From < To ->
  random:uniform(To - From + 1) + From - 1.
