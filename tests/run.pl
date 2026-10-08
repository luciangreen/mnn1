:- use_module(library(plunit)).
:- ensure_loaded('unit/core_tests').
:- ensure_loaded('unit/learning_tests').
:- ensure_loaded('unit/pipeline_tests').
:- ensure_loaded('unit/dataset_tests').
:- ensure_loaded('unit/benchmark_tests').
:- ensure_loaded('unit/benchmark_algorithm_tests').

:- initialization(main, main).

main :-
    run_tests,
    halt.
