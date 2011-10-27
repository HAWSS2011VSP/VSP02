-module(werkzeug).
-export([get_config_value/2,logging/2,timeMilliSecond/0,delete_last/1]).
-define(ZERO, integer_to_list(0)).

%% -------------------------------------------
% Werkzeug
%%
%% Sucht aus einer Config-Liste die gewÃ¼nschten EintrÃ¤ge
% Beispielaufruf: 	{ok, ConfigListe} = file:consult("server.cfg"),
%                  	{ok, Lifetime} = get_config_value(lifetime, ConfigListe),
%
get_config_value(Key, []) ->
	{nok, Key};
get_config_value(Key, [{Key, Value} | _ConfigT]) ->
	{ok, Value};
get_config_value(Key, [{_OKey, _Value} | ConfigT]) ->
	get_config_value(Key, ConfigT).

% Schreibt auf den Bildschirm und in eine Datei
% nebenlÃ¤ufig zur Beschleunigung
% Beispielaufruf: logging("FileName.log","Textinhalt"),
%
logging(Datei,Inhalt) -> spawn( fun() ->
								io:format(Inhalt),		
								file:write_file(Datei,Inhalt,[append])
								end).

%% LÃ¶scht das letzte Element einer Liste
% Beispielaufruf: Erg = delete_last([a,b,c]),
%
delete_last(List) -> delete_last(List,[]).
delete_last([_H|[]],NewList) -> NewList;
delete_last([H|T],NewList) -> delete_last(T,NewList++[H]).

%% Zeitstempel: 'MM.DD HH:MM:SS,SSS'
% Beispielaufruf: Text = lists:concat([Clientname," Startzeit: ",timeMilliSecond()]),
%
timeMilliSecond() ->
	{_Year, Month, Day} = date(),
	{Hour, Minute, Second} = time(),
	Tag = lists:concat([klebe(Day,""),".",klebe(Month,"")," ",klebe(Hour,""),":"]),
	{_, _, MicroSecs} = now(),
	Tag ++ concat([Minute,Second],":") ++ "," ++ toMilliSeconds(MicroSecs)++"|".
toMilliSeconds(MicroSecs) ->
	Seconds = MicroSecs / 1000000,
	string:substr( float_to_list(Seconds), 3, 3).
concat(List, Between) -> concat(List, Between, "").
concat([], _, Text) -> Text;
concat([First|[]], _, Text) ->
	concat([],"",klebe(First,Text));
concat([First|List], Between, Text) ->
	concat(List, Between, string:concat(klebe(First,Text), Between)).
klebe(First,Text) -> 	
	NumberList = integer_to_list(First),
	string:concat(Text,minTwo(NumberList)).	
minTwo(List) ->
	case {length(List)} of
		{0} -> ?ZERO ++ ?ZERO;
		{1} -> ?ZERO ++ List;
		_ -> List
	end.
