:- begin_tests(mnn_pipeline).

:- use_module('../../pipeline/mnn_pipeline').
:- use_module('../../prolog/mnn_learning', [clear_algorithm_library/0]).

pipeline_setup :-
    reset_pipeline_config,
    clear_algorithm_library.

pipeline_cleanup :-
    reset_pipeline_config,
    clear_algorithm_library.

test(pipeline_discovers_verifies_and_incorporates,
     [nondet, setup(pipeline_setup), cleanup(pipeline_cleanup)]) :-
    Examples = [io(1, 2), io(2, 4), io(3, 6)],
    run_pipeline(Examples, [io(137, 274)], double, Candidate, Report),
    Candidate = scale(Slope, Offset),
    assertion(Slope =:= 2),
    assertion(Offset =:= 0),
    assertion(member(pid_discovery-verified, Report)),
    assertion(member(pid_compiled-verified, Report)),
    assertion(member(aioc-incorporated, Report)).

test(stages_can_be_disabled,
     [nondet, setup(pipeline_setup), cleanup(pipeline_cleanup)]) :-
    set_pipeline_stage(loop2, false),
    Examples = [io(1, 2), io(2, 4)],
    run_pipeline(Examples, [io(137, 274)], double, _, Report),
    assertion(member(loop2-skipped(disabled), Report)).

test(disabled_discovery_does_not_stop_pipeline,
     [setup(pipeline_setup), cleanup(pipeline_cleanup)]) :-
    set_pipeline_stage(s2a, false),
    run_pipeline([io(1, 2), io(2, 4)], [io(137, 274)], double,
        Candidate, Report),
    assertion(Candidate == none),
    assertion(member(s2a-unavailable(discovery_disabled_or_failed), Report)),
    assertion(member(pid_compiled-unavailable(no_candidate), Report)).

:- end_tests(mnn_pipeline).
