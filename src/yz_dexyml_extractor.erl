-module(yz_dexyml_extractor).

-export([extract/1, extract/2]).

extract(Val) ->
    extract(binary_to_term(Val), []).

extract(Props, _Opts) when is_list(Props) ->
	error_logger:info_msg("yz_dexyml_extractor:extract/2 -> Props: ~p~n", [Props]),
	lists:flatten(fields(Props, []));
extract(_, _) ->
	[].

fields([], Acc) ->
	error_logger:info_msg("yz_dexyml_extractor:fields/2 -> Acc: ~p~n", [Acc]),
	Acc;
fields([{bucket, V} = H | T], Acc) when is_bitstring(V) -> fields(T, [H | Acc]);
fields([{datetime, V} = H | T], Acc) when is_bitstring(V) -> fields(T, [H | Acc]);
fields([{created, Usecs} | T], Acc) when is_number(Usecs) ->
	%Secs = trunc(Usecs / 1000000),
	fields(T, [{created, Usecs} | Acc]);
fields([{tags, V} | T], Acc) when is_list(V) ->
	case tags(V, []) of
		[] -> fields(T, Acc);
		Tags -> fields(T, [Tags | Acc])
	end;
fields([_ | T], Acc) -> fields(T, Acc).

tags([], Acc) -> Acc;
tags([Head | Tail], Acc) when is_bitstring(Head) -> tags(Tail, [{tags, Head} | Acc]);
tags([_ | Tail], Acc) -> tags(Tail, Acc);
tags(_, Acc) -> Acc.

