-module(logger).

-export([create/1, start/1]).

create(File) ->
  {ok, Handle} = file:open(File, [append]),
  Run = fun() -> run(Handle) end,
  register(logger, spawn_link(Run)).

start(Name) ->
  File = string:concat("GGTP_",string:concat(Name, ".log")),
  RegName = list_to_atom(string:concat("GGTP_", Name)),
  {ok, Handle} = file:open(File, [append]),
  Run = fun() -> run(Handle) end,
  register(RegName, spawn_link(Run)),
  RegName.

run(File) ->
  receive
    {debug, Msg} ->
      Message = lists:concat(["DEBUG: ", Msg, "\n"]),
      io:format(Message, []),
      file:write(File, Message);
    _ ->
      io:format("unknown operation!")
  end,
  run(File).
