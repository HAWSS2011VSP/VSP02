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
start(ArbeitsZeit,TermZeit,IdOfGGT,StarterNummer,PraktikumsGruppenNr,TeamNummer,NamensdienstNode,KoordinatorName) ->
	Name = string:concat(string:concat(PraktikumsGruppenNr, TeamNummer),string:concat(IdOfGGT, StarterNummer)),
	{Namensdienst,Koordinator,Log} = connections(NamensdienstNode,KoordinatorName,Name),
	{LeftN,RightN} = registerSelf(Namensdienst,Koordinator,Name,Log),
	setPM(Name,ArbeitsZeit,Log,LeftN,RightN,TermZeit,Koordinator),
	unregisterSelf(Namensdienst,Name,Log).


%%
%% Local Functions
%%
connections(NamensdienstNode,KoordinatorName,Name) -> %NeedHelpHere!!!
	Namensdienst = global:whereis_name(nameservice),
	Koordinator = global:whereis_name(),
	Log = logger:start(Name),
	{Namensdienst,Koordinator,Log}.

registerSelf(Namensdienst,Koordinator,Name,_Log) -> %logBinding
	register(Name,self()),
	Namensdienst ! {self(),{rebind,Name,node()}},
	Koordinator ! {hello,Name},
	receive
    	{setneighbors,LeftN,RightN} ->
			{LeftN,RightN}
	end.

setPM(Name,ArbeitsZeit,Log,LeftN,RightN,TermZeit,Koordinator) ->
	receive
		{setpm,MiNeu} ->
			afterSetPM(Name,ArbeitsZeit,Log,LeftN,RightN,TermZeit,MiNeu,Koordinator);
		kill ->
			ok;
		_ ->
			setPM(Name,ArbeitsZeit,Log,LeftN,RightN,TermZeit,Koordinator)
	end.

afterSetPM(Name,ArbeitsZeit,Log,LeftN,RightN,TermZeit,MiNeu,Koordinator) ->
	receive
		{sendy,Y} ->
			calculate(ArbeitsZeit,Name,MiNeu,Koordinator,Y,LeftN,RightN),
			ok;
		{abstimmung,Initiator} ->
			if
				Initiator == self() ->
					Koordinator ! {briefterm,{Name,MiNeu,time()}},
					ok;
				true ->
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