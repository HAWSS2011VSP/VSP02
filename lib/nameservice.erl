%Starten des Namensdienstes:
%--------------------------
%(w)erl -(s)name ns -setcookie zummsel
%1>nameservice:start( ).
%
%ns_send:msg(State,NameServiceNode)
%- State: einen der Nachrichten help, reset, list oder kill
%- NameServiceNode: Name des Nodes, auf dem der Namensdienst gestartet wurde

-module(nameservice).
-export([start/0]).

%% Namensdienst wird global bei allen Erlang nodes unter nameservice registriert.
start() ->
	{ok, HostName} = inet:gethostname(),
	Datei = lists:concat(["nameservice@",HostName,".log"]),	
	ServerPid = spawn(fun() -> loop(dict:new(),Datei) end),
	global:register_name(nameservice,ServerPid),
    Zeit = lists:concat(["Nameservice Startzeit: ",werkzeug:timeMilliSecond()]),
	Inhalt = lists:concat([Zeit," mit PID ",pid_to_list(ServerPid)," registriert mit Namen 'nameservice'.\r\n"]),
	werkzeug:logging(Datei,Inhalt).

loop(Dict,Datei) ->
	receive
		{From,{lookup,Name}} ->
			Inhalt1 = lists:concat(["lookup um ",werkzeug:timeMilliSecond()," von ",pid_to_list(From),":"]),
			case dict:find(Name,Dict) of
				{ok,Node} ->
					Inhalt = lists:concat([Inhalt1,"{",Name,",",Node,"}.\n"]),
					From ! {Name,Node};
				error ->
					Inhalt = lists:concat([Inhalt1,"not_found.\n"]),
					From ! not_found
			end,		
			werkzeug:logging(Datei,Inhalt),
			
			loop(Dict,Datei);
		{From,{bind,Name,Node}} ->
			Inhalt1 = lists:concat(["bind um ",werkzeug:timeMilliSecond()," von ",pid_to_list(From),":"]),
			case dict:find(Name,Dict) of
				{ok,Node} ->
					Inhalt = lists:concat([Inhalt1,"in_use ({",Name,",",Node,"}.\n"]),
					DictNew = Dict,
					From ! in_use;
				error ->
					Inhalt = lists:concat([Inhalt1,"{",Name,",",Node,"}.\n"]),
					DictNew = dict:store(Name, Node, Dict),
					From ! ok
			end,		
			werkzeug:logging(Datei,Inhalt),
			
			loop(DictNew,Datei);
		{From,{rebind,Name,Node}} ->
			DictNew = dict:store(Name, Node, Dict),
			Inhalt = lists:concat(["rebind um ",werkzeug:timeMilliSecond()," von ",pid_to_list(From),": {",Name,",",Node,"}.\n"]),
			From ! ok,
			werkzeug:logging(Datei,Inhalt),
			
			loop(DictNew,Datei);
		{From,{unbind,Name}} ->
			DictNew = dict:erase(Name, Dict),
			Inhalt = lists:concat(["unbind um ",werkzeug:timeMilliSecond()," von ",pid_to_list(From),":",Name,".\n"]),
			From ! ok,
			werkzeug:logging(Datei,Inhalt),

			loop(DictNew,Datei);
		{From,listall} ->
			Inhalt = lists:concat(["listall um ",werkzeug:timeMilliSecond()," von ",pid_to_list(From),".\n"]),
			List = dict:to_list(Dict),
			From ! List,
			werkzeug:logging(Datei,Inhalt),

			loop(Dict,Datei);
		{From,reset} ->
			Inhalt = lists:concat(["reset um ",werkzeug:timeMilliSecond()," von ",pid_to_list(From),".\n"]),
			From ! ok,
			werkzeug:logging(Datei,Inhalt),

			loop(dict:new(),Datei);
		{From,kill} ->
			Inhalt = lists:concat(["kill um ",werkzeug:timeMilliSecond()," von ",pid_to_list(From),".\n"]),
			From ! ok,
			werkzeug:logging(Datei,Inhalt)
	end.

