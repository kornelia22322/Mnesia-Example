%%%-------------------------------------------------------------------
%%% @author Kornelia Rohulko
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 05. cze 2017 21:59
%%%-------------------------------------------------------------------
-module('Mnesia_ex').
-author("Kornelia").
-include_lib("stdlib/include/qlc.hrl").

%% API
-export([initDB/0, storeDB/4, getDB/1, deleteDB/1]).

-record(contact, {name, surname, dateofBirth, placeofBirth, createdOn}).

%%Inicjalizacja bazy danych
initDB() ->
  mnesia:create_schema([node()]),
  %tworzymy schemat, jako argument podajemy listę Nodów (tylko tych z dyskiem twardym)
  mnesia:start(),
  try
      mnesia:table_info(contact, type)
  catch
      exit: _ ->
        mnesia:create_table(contact, [{attributes, record_info(fields, contact)},
          {type, bag},{disc_copies, [node()]}])
  %type - bag, brak klucza głównego
  end.

storeDB(Name, Surname, DateofBirth, PlaceofBirth) ->
  AF = fun() ->
    {CreatedOn,_}= calendar:universal_time(),
    mnesia:write(#contact{name = Name, surname = Surname, dateofBirth = DateofBirth,
      placeofBirth = PlaceofBirth, createdOn = CreatedOn})
       end,
  mnesia:transaction(AF).

getDB(PlaceofBirth) ->
  AF = fun() ->
    Query = qlc:q([X || X <- mnesia:table(contact), X#contact.placeofBirth =:= PlaceofBirth]),
    Results = qlc:e(Query),
    %qlc:q - make query
    %qlc:e - execute query

     lists:map(fun(Item) -> {Item#contact.name, Item#contact.surname, Item#contact.dateofBirth,
  Item#contact.createdOn} end, Results)
       end,
    {atomic, Result} = mnesia:transaction(AF),
    Result.

deleteDB(PlaceofBirth) ->
  AF = fun() ->
    Query = qlc:q([X || X <- mnesia:table(contact), X#contact.placeofBirth =:= PlaceofBirth]),
    Results = qlc:e(Query),

      F=fun() ->
        lists:foreach(fun(Result) -> mnesia:delete_object(Result) end, Results)
      end,

    mnesia:transaction(F)
    end,
  mnesia:transaction(AF).



