:- module(benchmark_algorithms, [
    run_task/3,
    latest_state/3,
    temporal_delta/3,
    argmax_window/3,
    rule_chain/4,
    run_pipeline/3,
    optimize_pipeline/2,
    optimize_pipeline/3
]).

:- use_module(library(error)).
:- use_module(library(lists)).

run_task(identity, Input, Input).
run_task(reverse, Input, Output) :-
    must_be(list, Input),
    reverse(Input, Output).
run_task(rotate_left, [], []).
run_task(rotate_left, [Head|Tail], Output) :-
    append(Tail, [Head], Output).
run_task(deduplicate, Input, Output) :-
    must_be(list, Input),
    list_to_set(Input, Output).
run_task(run_length_encode, Input, Output) :-
    must_be(list, Input),
    run_length_encode_(Input, Output).
run_task(cumulative_sum, Input, Output) :-
    must_be(list, Input),
    cumulative_sum_(Input, 0, Output).
run_task(affine(Slope, Offset), Input, Output) :-
    number(Slope),
    number(Offset),
    number(Input),
    Output is Slope * Input + Offset.
run_task(moving_average(Window), Input, Output) :-
    must_be(list, Input),
    moving_average(Input, Window, Output).
run_task(latest_state(Entity, Key), Events, Value) :-
    latest_state(Events, entity_key(Entity, Key), Value).
run_task(temporal_delta(Entity, Key), Events, Delta) :-
    temporal_delta(Events, entity_key(Entity, Key), Delta).
run_task(argmax_window(Window), Input, Output) :-
    must_be(list, Input),
    argmax_window(Input, Window, Output).
run_task(rule_chain(Start, Goal), Edges, Path) :-
    rule_chain(Start, Goal, Edges, Path).
run_task(composition(Algorithms), Input, Output) :-
    must_be(list, Algorithms),
    run_pipeline(Algorithms, Input, Output).
run_task(conditional_route(Threshold, Below, AtOrAbove), Input, Output) :-
    number(Input),
    ( Input < Threshold -> Algorithm = Below ; Algorithm = AtOrAbove ),
    run_task(Algorithm, Input, Output).

run_length_encode([], []).
run_length_encode([Head|Tail], [[Head, Count]|Encoded]) :-
    take_same(Tail, Head, 1, Count, Rest),
    run_length_encode(Rest, Encoded).

take_same([Head|Tail], Head, Accumulator, Count, Rest) :-
    !,
    Next is Accumulator + 1,
    take_same(Tail, Head, Next, Count, Rest).
take_same(Rest, _, Count, Count, Rest).

cumulative_sum_([], _, []).
cumulative_sum_([Head|Tail], Accumulator, [Sum|Sums]) :-
    number(Head),
    Sum is Accumulator + Head,
    cumulative_sum_(Tail, Sum, Sums).

moving_average(Input, Window, Averages) :-
    must_be(positive_integer, Window),
    moving_average_(Input, Window, Averages).

moving_average_(Input, Window, [Average|Averages]) :-
    length(Prefix, Window),
    append(Prefix, [_|_], Input),
    maplist(must_be_number, Prefix),
    sum_list(Prefix, Sum),
    Average is Sum / Window,
    Input = [_|Tail],
    moving_average_(Tail, Window, Averages).
moving_average_(_, _, []).

must_be_number(Value) :-
    must_be(number, Value).

latest_state(Events, entity_key(Entity, Key), Value) :-
    matching_events(Events, Entity, Key, [_-Value|_]).

temporal_delta(Events, entity_key(Entity, Key), Delta) :-
    matching_events(Events, Entity, Key, [_-Latest, _-Previous|_]),
    number(Latest),
    number(Previous),
    Delta is Latest - Previous.

matching_events(Events, Entity, Key, LatestFirst) :-
    must_be(list, Events),
    findall(Time-Value,
        member(event(Time, Entity, Key, Value), Events),
        Pairs),
    keysort(Pairs, Sorted),
    reverse(Sorted, LatestFirst),
    LatestFirst = [_|_].

argmax_window(Values, Window, Results) :-
    must_be(positive_integer, Window),
    argmax_window_(Values, Window, 0, Results).

argmax_window_(Values, Window, Start, [argmax(Start, Index, Maximum)|Results]) :-
    length(Prefix, Window),
    append(Prefix, [_|_], Values),
    maplist(must_be_number, Prefix),
    argmax_in_window(Prefix, Start, Index, Maximum),
    NextStart is Start + 1,
    Values = [_|Tail],
    argmax_window_(Tail, Window, NextStart, Results).
argmax_window_(_, _, _, []).

argmax_in_window([Value|Values], Start, Index, Maximum) :-
    argmax_in_window_(Values, Start, 1, Value, Start, Index, Maximum).

argmax_in_window_([], _, _, Maximum, Index, Index, Maximum).
argmax_in_window_([Value|Values], Start, Offset, CurrentMaximum,
        CurrentIndex, Index, Maximum) :-
    ( Value > CurrentMaximum ->
        NextMaximum = Value,
        NextIndex is Start + Offset
    ;
        NextMaximum = CurrentMaximum,
        NextIndex = CurrentIndex
    ),
    NextOffset is Offset + 1,
    argmax_in_window_(Values, Start, NextOffset, NextMaximum, NextIndex,
        Index, Maximum).

rule_chain(Start, Goal, Edges, Path) :-
    rule_chain_(Start, Goal, Edges, [Start], Reversed),
    reverse(Reversed, Path).

rule_chain_(Goal, Goal, _, Path, Path).
rule_chain_(Current, Goal, Edges, Visited, Path) :-
    member(edge(Current, Next), Edges),
    \+ memberchk(Next, Visited),
    rule_chain_(Next, Goal, Edges, [Next|Visited], Path),
    !.

run_pipeline([], Input, Input).
run_pipeline([Algorithm|Algorithms], Input, Output) :-
    run_task(Algorithm, Input, Intermediate),
    run_pipeline(Algorithms, Intermediate, Output).

optimize_pipeline(Pipeline, Optimized) :-
    must_be(list, Pipeline),
    optimize_pipeline_(Pipeline, Simplified),
    exclude(=(identity), Simplified, Optimized).

optimize_pipeline(Pipeline, Examples, Optimized) :-
    must_be(list, Examples),
    optimize_pipeline(Pipeline, Candidate),
    maplist(equivalent_pipeline(Pipeline, Candidate), Examples),
    Optimized = Candidate.

optimize_pipeline_([reverse, reverse|Tail], Optimized) :-
    !,
    optimize_pipeline_(Tail, Optimized).
optimize_pipeline_([Algorithm|Tail], [Algorithm|Optimized]) :-
    optimize_pipeline_(Tail, Optimized).
optimize_pipeline_([], []).

equivalent_pipeline(Original, Optimized, io(Input, Expected)) :-
    run_pipeline(Original, Input, OriginalOutput),
    run_pipeline(Optimized, Input, OptimizedOutput),
    outputs_equal(Expected, OriginalOutput),
    outputs_equal(OriginalOutput, OptimizedOutput).

outputs_equal(Left, Right) :-
    number(Left),
    number(Right),
    !,
    Left =:= Right.
outputs_equal(Left, Right) :-
    Left == Right.
