:- begin_tests(mnn_core).

:- use_module('../../prolog/mnn').

test(indexed_lookup, [setup(clear_memory), cleanup(clear_memory)]) :-
    remember(property(apple, colour, red)),
    remember(property(pear, colour, green)),
    indexed_facts(property, 3, Facts),
    assertion(Facts == [
        property(apple, colour, red),
        property(pear, colour, green)
    ]).

test(zero_arity_facts, [setup(clear_memory), cleanup(clear_memory)]) :-
    remember(raining),
    solve(raining, Answer, [sentence(raining)], _),
    assertion(Answer == raining).

test(ownership_reasoning_and_memory, [setup(clear_memory), cleanup(clear_memory)]) :-
    remember(owns(john, apple)),
    remember(property(apple, colour, red)),
    solve(colour_of_owned(john, Colour), Answer, Trace, Memory),
    assertion(Colour == red),
    assertion(Answer == colour_of_owned(john, red)),
    assertion(Trace = [
        sentence(owns(john, apple)),
        sentence(property(apple, colour, red)),
        sentence(_)
    ]),
    render_trace(Trace, Sentences),
    assertion(Sentences == [
        "john owns apple.",
        "The apple is red.",
        "Therefore john's apple is red."
    ]),
    assertion(Memory.output == Answer),
    assertion(Memory.original_input = colour_of_owned(john, _)),
    assertion(Memory.completed_goals == [colour_of_owned(john, red)]),
    assertion(Memory.intermediate_results == [
        owns(john, apple),
        property(apple, colour, red)
    ]).

test(transitive_reasoning_trace, [setup(clear_memory), cleanup(clear_memory)]) :-
    remember(older(alice, bob)),
    remember(older(bob, carol)),
    solve(transitive(older, alice, carol), Answer, Trace, Memory),
    assertion(Answer == transitive(older, alice, carol)),
    assertion(Trace == [
        sentence(older(alice, bob)),
        sentence(older(bob, carol)),
        sentence(transitive(older, alice, carol))
    ]),
    render_trace(Trace, Sentences),
    assertion(Sentences == [
        "alice is older than bob.",
        "bob is older than carol.",
        "Therefore alice is older than carol."
    ]),
    assertion(Memory.candidate_algorithms == [transitive(older)]).

test(unknown_query_fails, [fail, setup(clear_memory), cleanup(clear_memory)]) :-
    solve(colour_of_owned(unknown, _), _, _, _).

test(unknown_query_has_explicit_status,
     [setup(clear_memory), cleanup(clear_memory)]) :-
    solve_status(colour_of_owned(unknown, _), Status, Trace, Memory),
    assertion(Status == no_applicable_algorithm),
    assertion(Trace == []),
    assertion(Memory.output == no_applicable_algorithm).

test(conflicting_answers_are_reported_as_ambiguous,
     [setup(clear_memory), cleanup(clear_memory)]) :-
    remember(owns(john, apple)),
    remember(property(apple, colour, red)),
    remember(property(apple, colour, blue)),
    solve_status(colour_of_owned(john, _), Status, _, Memory),
    Status = ambiguous(Answers),
    assertion(Answers == [
        colour_of_owned(john, blue),
        colour_of_owned(john, red)
    ]),
    assertion(Memory.rejected_candidates == Answers).

:- end_tests(mnn_core).
