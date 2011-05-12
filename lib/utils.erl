-module(utils).
-export([mkString/2]).

mkString(Seperator, Items) ->
  mkString(Seperator, Items, []).

mkString(_, [], Result) ->
  Result;
mkString(Seperator, [Item|[]], Result) ->
  mkString(Seperator, [], lists:concat([Result, Item]));
mkString(Seperator, [Item|Rest], Result) ->
  mkString(Seperator, Rest, lists:concat([Result, Item, Seperator])).