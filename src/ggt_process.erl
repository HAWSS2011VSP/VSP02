%% Author: BlueDragon
%% Created: 25.10.2011
%% Description: TODO: Add description to ggt_process
-module(ggt_process).

%%
%% Include files
%%

%%
%% Exported Functions
%%
-export([start/8]).

%%
%% API Functions
%%
start(ArbeitsZeit,TermZeit,IdOfGGT,StarterNummer,PraktikumsGruppenNr,TeamNummer,NamensdienstNode,KoordinatorNode) ->
	Name = string:concat(string:concat(integer_to_list(PraktikumsGruppenNr), integer_to_list(TeamNummer)),
    string:concat(integer_to_list(IdOfGGT), integer_to_list(StarterNummer))),
  NameAtom = list_to_atom(Name),
  Log = logger:start(Name),
	{LeftN,RightN} = registerSelf(NamensdienstNode,KoordinatorNode,NameAtom,Log),
	setPM(NameAtom,ArbeitsZeit,Log,LeftN,RightN,TermZeit,KoordinatorNode),
	unregisterSelf(NamensdienstNode,NameAtom,Log).


%%
%% Local Functions
%%
registerSelf(Namensdienst,Koordinator,Name,Log) -> %logBinding
	register(Name,self()),
	Namensdienst ! {self(),{rebind,Name,node()}},
	Koordinator ! {hello,Name},
  Log ! {debug, "Registered and waiting for neighbours."},
	receive
  	{setneighbors,LeftN,RightN} ->
      Log ! {debug, "Got neighbours."},
			{LeftN,RightN}
	end.

setPM(Name,ArbeitsZeit,Log,LeftN,RightN,TermZeit,Koordinator) ->
  Log ! {debug, "Waiting for value."},
	receive
		{setpm,MiNeu} ->
			afterSetPM(Name,ArbeitsZeit,Log,LeftN,RightN,TermZeit,MiNeu,Koordinator),
      Log ! {debug, "Got value."};
		kill ->
      Log ! {debug, "Time to kill!"},
			ok;
		_ ->
			setPM(Name,ArbeitsZeit,Log,LeftN,RightN,TermZeit,Koordinator)
	end.

afterSetPM(Name,ArbeitsZeit,Log,LeftN,RightN,TermZeit,MiNeu,Koordinator) ->
  Log ! {debug, "Starting calculation..."},
	receive
		{sendy,Y} ->
      Log ! {debug, lists:concat(["Got value: ", integer_to_list(Y)])},
			calculate(ArbeitsZeit,Name,MiNeu,Koordinator,Y,LeftN,RightN),
			ok;
		{abstimmung,Initiator} ->
			if
				Initiator == self() ->
          Log ! {debug, "Voting successful."},
					Koordinator ! {briefterm,{Name,MiNeu,time()}},
					ok;
				true ->
          Log ! {debug, "Got a voting request."},
					waitBeforeAbstimmungGoOn(Name,ArbeitsZeit,Log,LeftN,RightN,TermZeit/2,MiNeu,Initiator,Koordinator),
					afterSetPM(Name,ArbeitsZeit,Log,LeftN,RightN,TermZeit,MiNeu,Koordinator)
			end;
		{tellmi,From} ->
			From ! MiNeu
	after TermZeit ->
			RightN ! {abstimmung,self()}
	end.

waitBeforeAbstimmungGoOn(Name,ArbeitsZeit,_Log,LeftN,RightN,HalbeTermZeit,MiNeu,Initiator,Koordinator) ->
	receive
		{sendy,Y} ->
			calculate(ArbeitsZeit,Name,MiNeu,Koordinator,Y,LeftN,RightN),
			ok;
		{tellmi,From} ->
			From ! MiNeu
	after HalbeTermZeit ->
			RightN ! {abstimmung,Initiator}
	end.

calculate(ArbeitsZeit,Name,Mi,Koordinator,Y,LeftN,RightN) ->
	timer:sleep(ArbeitsZeit),
	if
		Y<Mi ->
			MiNeu = mod(Mi-1, Y)+1,
			self() ! {tellmi,LeftN},
			self() ! {tellmi,RightN},
			if
				Mi == MiNeu ->
					ok;
				true ->
					Koordinator ! {briefmi,{Name,MiNeu,time()}} %only if change
			end;
		true ->
			ok
	end,
	ok.

mod(X,Y) when X > 0 -> X rem Y;
mod(X,Y) when X < 0 -> Y + X rem Y;
mod(0,_Y) -> 0.

unregisterSelf(Namensdienst,Name,_Log) ->
	Namensdienst ! {self(),{unbind,Name}}.
