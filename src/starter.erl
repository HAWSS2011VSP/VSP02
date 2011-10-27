%% Author: BlueDragon
%% Created: 25.10.2011
%% Description: TODO: Add description to starter
-module(starter).

%%
%% Include files
%%

%%
%% Exported Functions
%%
-export([start/1]).

%%
%% API Functions
%%
start(StarterNummer) ->
	{ArbeitsZeit,TermZeit,GGTProzesseProStarter} = configFromCoordinator(),
	{NamensdienstNode,KoordinatorName,PraktikumsGruppenNr,TeamNummer} = connections(),
	startGGTProcess(ArbeitsZeit,TermZeit,1,StarterNummer,PraktikumsGruppenNr,TeamNummer,NamensdienstNode,KoordinatorName,GGTProzesseProStarter).


%%
%% Local Functions
%%
connections() ->
	Config = config:read('ggt.cfg'),
	NamensdienstNode = config:get(nameservicenode, Config),
	KoordinatorName = config:get(koordinatorname, Config),
	PraktikumsGruppenNr = config:get(praktikumsgruppe, Config),
	TeamNummer = config:get(teamnummer, Config),
	{NamensdienstNode,KoordinatorName,PraktikumsGruppenNr,TeamNummer}.

configFromCoordinator() ->
	receive
    	{steeringval,ArbeitsZeit,TermZeit,GGTProzesseProStarter} ->
			{ArbeitsZeit,TermZeit,GGTProzesseProStarter};
		_ ->
			configFromCoordinator()
	end.

startGGTProcess(ArbeitsZeit,TermZeit,IdOfGGT,StarterNummer,PraktikumsGruppenNr,TeamNummer,NamensdienstNode,KoordinatorName,IdOfGGT) ->
	spawn_link(ggt_process, start, [ArbeitsZeit,TermZeit,IdOfGGT,StarterNummer,PraktikumsGruppenNr,TeamNummer,NamensdienstNode,KoordinatorName]),
	ok;

startGGTProcess(ArbeitsZeit,TermZeit,IdOfGGT,StarterNummer,PraktikumsGruppenNr,TeamNummer,NamensdienstNode,KoordinatorName,GGTProzesseProStarter) ->
	spawn_link(ggt_process, start, [ArbeitsZeit,TermZeit,IdOfGGT,StarterNummer,PraktikumsGruppenNr,TeamNummer,NamensdienstNode,KoordinatorName]),
	startGGTProcess(ArbeitsZeit,TermZeit,IdOfGGT+1,StarterNummer,PraktikumsGruppenNr,TeamNummer,NamensdienstNode,KoordinatorName,GGTProzesseProStarter).
