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
	{NamensdienstNode,KoordinatorNode,PraktikumsGruppenNr,TeamNummer} = connections(),
	{ArbeitsZeit,TermZeit,GGTProzesseProStarter} = configFromCoordinator(KoordinatorNode),
	startGGTProcess(ArbeitsZeit,TermZeit,1,StarterNummer,PraktikumsGruppenNr,TeamNummer,NamensdienstNode,KoordinatorNode,GGTProzesseProStarter).


%%
%% Local Functions
%%
connections() ->
	Config = config:read('ggt.cfg'),
  net_adm:ping(config:get(nameservicenode, Config)),
  timer:sleep(300),
  NamensdienstNode = global:whereis_name(nameservice),
  KoordinatorNode = getNode(config:get(koordinatorname, Config), NamensdienstNode),
	PraktikumsGruppenNr = config:get(praktikumsgruppe, Config),
	TeamNummer = config:get(teamnummer, Config),
	{NamensdienstNode,KoordinatorNode,PraktikumsGruppenNr,TeamNummer}.

getNode(Name, NamensdienstNode) ->
  NamensdienstNode ! {self(), {lookup, Name}},
  receive
    not_found ->
      io:format("Node ~s not found.~n", [Name]),
      nil;
    {Name,Node} -> {Name, Node}
  end.
 
configFromCoordinator(KoordinatorNode) ->
  KoordinatorNode ! {getsteeringval, self()},
	receive
    {steeringval,ArbeitsZeit,TermZeit,GGTProzesseProStarter} ->
			{ArbeitsZeit,TermZeit,GGTProzesseProStarter};
		_ ->
			configFromCoordinator(KoordinatorNode)
	end.

startGGTProcess(ArbeitsZeit,TermZeit,IdOfGGT,StarterNummer,PraktikumsGruppenNr,TeamNummer,NamensdienstNode,KoordinatorName,IdOfGGT) ->
	spawn_link(ggt_process, start, [ArbeitsZeit,TermZeit,IdOfGGT,StarterNummer,PraktikumsGruppenNr,TeamNummer,NamensdienstNode,KoordinatorName]),
	ok;

startGGTProcess(ArbeitsZeit,TermZeit,IdOfGGT,StarterNummer,PraktikumsGruppenNr,TeamNummer,NamensdienstNode,KoordinatorName,GGTProzesseProStarter) ->
	spawn_link(ggt_process, start, [ArbeitsZeit,TermZeit,IdOfGGT,StarterNummer,PraktikumsGruppenNr,TeamNummer,NamensdienstNode,KoordinatorName]),
	startGGTProcess(ArbeitsZeit,TermZeit,IdOfGGT+1,StarterNummer,PraktikumsGruppenNr,TeamNummer,NamensdienstNode,KoordinatorName,GGTProzesseProStarter).
