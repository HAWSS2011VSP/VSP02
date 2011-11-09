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
	warten(NameAtom,ArbeitsZeit,Log,LeftN,RightN,trunc(TermZeit/2),KoordinatorNode),
	unregisterSelf(NamensdienstNode,NameAtom,Log).


%%
%% Local Functions
%%
registerSelf(Namensdienst,Koordinator,Name,Log) -> %logBinding
	register(Name,self()),
	Namensdienst ! {self(),{rebind,Name,node()}},
	receive 
		ok -> ok
	end,
	Koordinator ! {hello,Name},
	Log ! {debug, "Registered and waiting for neighbours."},
	receive
		{setneighbors,LeftN,RightN} ->
			Log ! {debug, "Got neighbours."},
			{LeftN,RightN}
	end.

warten(Name,ArbeitsZeit,Log,LeftN,RightN,TermZeit,Koordinator) ->
	Log ! {debug, "Waiting for value."},
	receive
		{setpm,MiNeu} ->
			Log ! {debug, lists:concat(["Got value: ", integer_to_list(MiNeu)])},
			bereit_1(Name,ArbeitsZeit,Log,LeftN,RightN,TermZeit,MiNeu,Koordinator);
		kill ->
			Log ! {debug, "Time to kill!"},
			ok
	end.


bereit_1(Name,ArbeitsZeit,Log,LeftN,RightN,TermZeit,Mi,Koordinator) ->
	Log ! {debug, "Starting calculation..."},
	receive
		{setpm,MiNeu} ->
			Log ! {debug, "Got value."},
			bereit_1(Name,ArbeitsZeit,Log,LeftN,RightN,TermZeit,MiNeu,Koordinator);
		{sendy,Y} ->
			Log ! {debug, lists:concat(["Got value: ", integer_to_list(Y)])},
			Log ! {debug, "Calculating new Mi..."},
			MiNeu = calculate(ArbeitsZeit,Name,Mi,Koordinator,Y,LeftN,RightN),
			Log ! {debug, lists:concat(["New Mi is: ", integer_to_list(MiNeu)])},
			bereit_1(Name,ArbeitsZeit,Log,LeftN,RightN,TermZeit,MiNeu,Koordinator),
			ok;
		{tellmi,From} ->
			From ! Mi,
			bereit_1(Name,ArbeitsZeit,Log,LeftN,RightN,TermZeit,Mi,Koordinator);
		kill ->
			Log ! {debug, "Time to kill!"},
			ok
	after TermZeit ->
			bereit_2(Name,ArbeitsZeit,Log,LeftN,RightN,TermZeit,Mi,Koordinator)
	end.

bereit_2(Name,ArbeitsZeit,Log,LeftN,RightN,TermZeit,Mi,Koordinator) ->
	receive
		{setpm,MiNeu} ->
			Log ! {debug, ">>> setpm"},
			Log ! {debug, "Got value."},
			bereit_1(Name,ArbeitsZeit,Log,LeftN,RightN,TermZeit,MiNeu,Koordinator);
		{sendy,Y} ->
			Log ! {debug, ">>> sendy"},
			Log ! {debug, lists:concat(["Got value: ", integer_to_list(Y)])},
			Log ! {debug, "Calculating new Mi..."},
			MiNeu = calculate(ArbeitsZeit,Name,Mi,Koordinator,Y,LeftN,RightN),
			Log ! {debug, lists:concat(["New Mi is: ", integer_to_list(MiNeu)])},
			bereit_1(Name,ArbeitsZeit,Log,LeftN,RightN,TermZeit,MiNeu,Koordinator),
			ok;
		{abstimmung,Initiator} ->
			Log ! {debug, ">>> abstimmung"},
			if
				Initiator == Name ->
					ok;
				true ->
					Log ! {debug, ">>> abstimmung weiterleiten"},
					Log ! {debug, "Got a voting request."},
					getProc(RightN) ! {abstimmung,Initiator}
			end,
			bereit_1(Name,ArbeitsZeit,Log,LeftN,RightN,TermZeit,Mi,Koordinator);
		{tellmi,From} ->
			Log ! {debug, ">>> tellmi"},
			From ! Mi,
			bereit_1(Name,ArbeitsZeit,Log,LeftN,RightN,TermZeit,Mi,Koordinator);
		kill ->
			Log ! {debug, ">>> kill"},
			Log ! {debug, "Time to kill!"},
			ok
	after 
		TermZeit ->
			Log ! {debug, ">>> after"},
			getProc(RightN) ! {abstimmung,Name},
			warten_after_term(Name,ArbeitsZeit,Log,LeftN,RightN,TermZeit,Mi,Koordinator)
	end.



warten_after_term(Name,ArbeitsZeit,Log,LeftN,RightN,TermZeit,Mi,Koordinator) ->
	receive
		{setpm,MiNeu} ->
			Log ! {debug, "Got value."},
			bereit_1(Name,ArbeitsZeit,Log,LeftN,RightN,TermZeit,MiNeu,Koordinator);
		{sendy,Y} ->
			Log ! {debug, "Calculating new Mi..."},
			MiNeu = calculate(ArbeitsZeit,Name,Mi,Koordinator,Y,LeftN,RightN),
			Log ! {debug, lists:concat(["New Mi is: ", integer_to_list(MiNeu)])},
			bereit_1(Name,ArbeitsZeit,Log,LeftN,RightN,TermZeit,MiNeu,Koordinator),
			ok;
		{tellmi,From} ->
			From ! Mi,
			bereit_1(Name,ArbeitsZeit,Log,LeftN,RightN,TermZeit,Mi,Koordinator);
		{abstimmung,Initiator} ->
			if
				Initiator == Name ->
					Log ! {debug, "Voting successful."},
					Koordinator ! {briefterm,{Name,Mi,time()}},
					warten(Name,ArbeitsZeit,Log,LeftN,RightN,TermZeit,Koordinator);
				true ->
					Log ! {debug, "Got a voting request."},
					getProc(RightN) ! {abstimmung,Initiator},
					warten_after_term(Name,ArbeitsZeit,Log,LeftN,RightN,TermZeit,Mi,Koordinator)
			end;
		kill ->
			Log ! {debug, "Time to kill!"},
			ok
	end.

calculate(ArbeitsZeit,Name,Mi,Koordinator,Y,LeftN,RightN) ->
	timer:sleep(ArbeitsZeit),
	if
		Y<Mi ->
			MiNeu = mod(Mi-1, Y)+1,
			getProc(LeftN) ! {sendy,MiNeu},
			getProc(RightN) ! {sendy,MiNeu},
			if
				Mi == MiNeu ->
					Mi;
				true ->
					Koordinator ! {briefmi,{Name,MiNeu,time()}}, %only if change
					MiNeu
			end;
		true ->
			Mi
	end.

mod(X,Y) ->
	X rem Y.

getProc(Name) ->
  Nameservice = global:whereis_name('nameservice'),
  Nameservice ! {self(), {lookup, Name}},
  receive
    not_found -> nil;
    {Name,Node} -> {Name, Node}
  end.

unregisterSelf(Namensdienst,Name,Log) ->
	Log ! {debug, "Unregistering..."},
	Log ! kill,
	unregister(Name),
	Namensdienst ! {self(),{unbind,Name}}.
