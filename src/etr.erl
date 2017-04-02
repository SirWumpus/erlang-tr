%%#!/usr/bin/env escript

-module(etr).
-export([main/1, tr/3]).

-define(BUFSIZ, 1024).

usage() ->
	io:format("usage: etr [-c] string1 string2~n"),
	io:format("       etr [-c] -d string1~n~n"),
	io:format("-c\t\tthe complement of string1~n"),
	io:format("-d\t\tdelete characters in string1 from input~n"),
	halt(2).

main(Args) ->
	case egetopt:parse(Args, [
		{ $c, flag, complement_set },
		{ $d, flag, delete_set }
	]) of
	{ok, Options, ArgsN} ->
		process(Options, ArgsN);
	{error, Reason, Opt} ->
		io:format("~s -~c~n", [Reason, Opt]),
		usage()
	end.


process(Opts, [String1, String2]) ->
	case proplists:get_value(delete_set, Opts, false) of
	false ->
		tr(standard_io, which_set(Opts, String1), list_to_binary(String2));
	true ->
		usage()
	end;
process(Opts, [String1]) ->
	case proplists:get_value(delete_set, Opts, false) of
	true ->
		tr(standard_io, which_set(Opts, String1), <<>>);
	false ->
		usage()
	end;
process(_Opts, _) ->
	usage().

tr(Fp, FromSet, ToSet) ->
	case file:read_line(Fp) of
	{ok, Line} ->
		file:write(standard_io, str:tr(list_to_binary(Line), FromSet, ToSet)),
		tr(Fp, FromSet, ToSet);
	{error, Reason} ->
		throw({error, Reason});
	eof ->
		ok
	end.

which_set(Opts, Set) ->
	Bset = list_to_binary(Set),
	case proplists:get_value(complement_set, Opts, false) of
	true ->
		complement_set(Bset);
	false ->
		Bset
	end.

complement_set(Set) ->
	complement_set(Set, lists:seq(0, 256), <<>>).
complement_set(_Set, [], Acc) ->
	Acc;
complement_set(Set, [Octet | Rest], Acc) ->
	case str:chr(Set, Octet) of
	-1 ->
		complement_set(Set, Rest, <<Acc/binary, Octet:8>>);
	_ ->
		complement_set(Set, Rest, Acc)
	end.

