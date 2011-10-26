-module(config).
-export([get/2, read/1]).

get(Key, List) ->
  {_, Val} = lists:keyfind(Key, 1, List),
  Val.

read(File) ->
  {ok, Config} = file:consult(File),
  Config.

