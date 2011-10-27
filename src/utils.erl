-module(utils).
-export([mkString/2, nowTimestamp/0]).

mkString(Seperator, Items) ->
  mkString(Seperator, Items, []).

mkString(_, [], Result) ->
  Result;
mkString(Seperator, [Item|[]], Result) ->
  mkString(Seperator, [], lists:concat([Result, Item]));
mkString(Seperator, [Item|Rest], Result) ->
  mkString(Seperator, Rest, lists:concat([Result, Item, Seperator])).

nowTimestamp() ->
  get_unix_timestamp(now()).

get_unix_timestamp({MegaSecs, Secs, _MicroSecs}=_TS) ->
    MegaSecs*1000000+Secs.

