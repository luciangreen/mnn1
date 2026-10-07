:- begin_tests(benchmark_algorithms).

:- use_module('../../benchmarks/benchmark_algorithms').

test(sequence_and_numeric_tasks) :-
    run_task(identity, [a, b], [a, b]),
    run_task(rotate_left, [a, b, c], [b, c, a]),
    run_task(deduplicate, [a, b, a, c, b], [a, b, c]),
    run_task(run_length_encode, [a, a, b, b, b, a], [[a, 2], [b, 3], [a, 1]]),
    run_task(cumulative_sum, [2, -1, 4], [2, 1, 5]),
    run_task(affine(2, 3), 4, 11),
    run_task(moving_average(2), [2, 4, 6, 8], [3, 5, 7]).

test(time_series_tasks) :-
    Events = [
        event(1, sensor, temperature, 10),
        event(2, sensor, temperature, 12),
        event(3, sensor, temperature, 9),
        event(4, other, temperature, 100)
    ],
    latest_state(Events, entity_key(sensor, temperature), 9),
    temporal_delta(Events, entity_key(sensor, temperature), -3),
    run_task(latest_state(sensor, temperature), Events, 9),
    run_task(temporal_delta(sensor, temperature), Events, -3).

test(window_ranking_and_rule_chain) :-
    argmax_window([1, 5, 5, 2], 3,
        [argmax(0, 1, 5), argmax(1, 1, 5)]),
    rule_chain(a, d, [edge(a, b), edge(b, c), edge(c, d)], [a, b, c, d]).

test(composition_and_conditional_routing) :-
    run_task(composition([affine(2, 0), affine(1, 3)]), 4, 11),
    run_task(conditional_route(10, affine(2, 0), affine(3, 0)), 5, 10),
    run_task(conditional_route(10, affine(2, 0), affine(3, 0)), 10, 30).

test(optimizer_removes_identities_and_cancellations) :-
    optimize_pipeline([identity, reverse, reverse, identity, reverse], [reverse]),
    optimize_pipeline([identity, reverse, reverse], [io([a, b], [a, b])],
        Optimized),
    assertion(Optimized == []).

test(optimizer_rejects_incorrect_examples, [fail]) :-
    optimize_pipeline([reverse, reverse], [io([a, b], [b, a])], _).

test(invalid_window_fails, [fail]) :-
    run_task(moving_average(0), [1, 2], _).

:- end_tests(benchmark_algorithms).
