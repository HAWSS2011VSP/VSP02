-module(coordinator).
-export([start/0]).
-compile(debug_info).

start() ->
  erlang:nodes(visible),
  process_flag(trap_exit, true),
  Config = config:read('koordinator.cfg'),
  KoordinatorName = config:get('koordinatorname', Config),
  register(KoordinatorName, self()),
  net_adm:ping(config:get('nameservicenode', Config)),
  timer:sleep(200),
  bindProc(KoordinatorName),
  io:format("Coordinator running...~n", []),
  preInitial(Config).

preInitial(Config) ->
  receive
    {getsteeringval, PID} ->
      io:format("Sending steering vals.~n", []),
      PID ! {steeringval,
             config:get('arbeitszeit', Config),
             config:get('termzeit', Config) * 1000,
             config:get('ggtprozessnummer', Config)},
      preInitial(Config);
    setinitial ->
      io:format("Initialized.~n", []),
      initial(Config, [])
  end.

initial(Config, Procs) ->
  receive
    {hello, Name} ->
      io:format("GCD process ~s said hello.~n", [Name]),
      initial(Config, [Name|Procs]);
    setready ->
      io:format("Building ring.~n", []),
      buildRing(Procs),
      {ok, [Ggt]} = io:fread("Gewuenschter GGT: ", "~d"),
      setStartValues(Procs, Ggt),
      waitForResult(Config, Procs, Ggt);
    Msg ->
      io:format("Did not understand ~w.~n", [Msg]),
      initial(Config, Procs)
  end.

buildRing(Procs) ->
  io:format("building ring with ~w.~n", [Procs]),
  buildRing(Procs, lists:last(Procs), []).

buildRing([], _Recent, _Procs2) ->
  done;
buildRing([Proc, Right | []], Recent, Procs2) ->
  Left = lists:last(Procs2),
  io:format("Setting Neighbours for ~w, Left: ~w, Right: ~w~n", [Proc, Left, Right]),
  io:format("Setting Neighbours for ~w, Left: ~w, Right: ~w~n", [Right, Proc, Left]),
  getProc(Proc) ! {setneighbors, Recent, Right},
  getProc(Right) ! {setneighbors, Proc, Left},
  buildRing([], Proc, [ Right, Proc | Procs2]);
buildRing([Proc, Right | Rest], Recent, []) ->
  io:format("Setting Neighbours for ~w, Left: ~w, Right: ~w~n", [Proc, Recent, Right]),
  getProc(Proc) ! {setneighbors, Recent, Right},
  buildRing([Right | Rest], Proc, [Proc]);
buildRing([Proc, Right | Rest], Recent, Procs2) ->
  io:format("Setting Neighbours for ~w, Left: ~w, Right: ~w~n", [Proc, Recent, Right]),
  getProc(Proc) ! {setneighbors, Recent, Right},
  buildRing([Right | Rest], Proc, [Proc | Procs2]);
buildRing(Procs, Recent, Procs2) ->
  io:format("Something shitty... ~w ~w ~w~n", [Procs, Recent, Procs2]).

setStartValues([], _Ggt) ->
  done;
setStartValues([PID | Rest], Ggt) ->
  getProc(PID) ! {setpm, Ggt * rand(1,100) * rand(1,100)},
  setStartValues(Rest, Ggt).

waitForResult(Config, Procs, Ggt) ->
  receive
    {briefmi, {Name, Mi, Time}} ->
      io:format("[~w] Got new Mi from ~s: ~w~n", [Time, Name, Mi]),
      waitForResult(Config, Procs, Ggt);
    {briefterm, {Name, Result, Time}} ->
      io:format("[~w] Got result from ~s: ~w~n", [Time, Name, Result]),
      waitForResult(Config, Procs, Ggt);
    'reset' ->
      killProcs(Procs),
      preInitial(Config);
    'kill' ->
      killProcs(Procs)
  end.

killProcs(Procs) ->
  F = fun(Proc) ->
    getProc(Proc) ! 'kill'
  end,
  lists:foreach(F, Procs).

getProc(Name) ->
  Nameservice = global:whereis_name('nameservice'),
  Nameservice ! {self(), {lookup, Name}},
  receive
    not_found -> nil;
    {Name,Node} -> {Name, Node}
  end.

bindProc(Name) ->
  Nameservice = global:whereis_name('nameservice'),
  io:format("Nameservice: ~w~n", [Nameservice]),
  Nameservice ! {self(),{rebind,Name,node()}},
  receive ok -> io:format("..bind.done.\n");
    in_use -> io:format("..schon gebunden.\n")
  end.

rand(Lo,Hi) ->
  crypto:rand_uniform(Lo, Hi).

