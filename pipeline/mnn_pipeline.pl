:- module(mnn_pipeline, [
    pipeline_stages/1,
    set_pipeline_stage/2,
    reset_pipeline_config/0,
    run_pipeline/5
]).

:- use_module('../prolog/mnn_learning').
:- dynamic configured_stage/2.

pipeline_stages([
    s2a, starlog, pid_discovery, loop2, plop, algebraplop,
    pid_optimization, detlog, piglog2, compiler, pid_compiled, aioc
]).

set_pipeline_stage(Stage, Enabled) :-
    pipeline_stages(Stages),
    memberchk(Stage, Stages),
    must_be(boolean, Enabled),
    retractall(configured_stage(Stage, _)),
    assertz(configured_stage(Stage, Enabled)).

reset_pipeline_config :-
    retractall(configured_stage(_, _)).

stage_enabled(Stage, Enabled) :-
    ( configured_stage(Stage, Value) -> Enabled = Value ; Enabled = true ).

run_pipeline(Examples, Validation, Name, Candidate, Report) :-
    ( stage_enabled(s2a, true),
      discover_algorithm(Examples, Candidate, Discovery)
    ->
        Initial = Candidate,
        DiscoveryResult = discovered(Initial, Discovery)
    ;
        Initial = none,
        DiscoveryResult = unavailable(discovery_disabled_or_failed)
    ),
    Candidate = Initial,
    pipeline_stages(Stages),
    run_stages(Stages, Initial, Examples, Validation, Name,
        [s2a-DiscoveryResult], Report).

run_stages([], _, _, _, _, Accumulator, Report) :-
    reverse(Accumulator, Report).
run_stages([s2a|Stages], Candidate, Examples, Validation, Name, Accumulator, Report) :-
    !,
    run_stages(Stages, Candidate, Examples, Validation, Name, Accumulator, Report).
run_stages([Stage|Stages], Candidate, Examples, Validation, Name, Accumulator, Report) :-
    stage_enabled(Stage, Enabled),
    ( Enabled == false ->
        Result = skipped(disabled)
    ;
        run_stage(Stage, Candidate, Examples, Validation, Name, Result)
    ),
    run_stages(Stages, Candidate, Examples, Validation, Name,
        [Stage-Result|Accumulator], Report).

run_stage(starlog, Candidate, _, _, _, starlog(specification(Candidate))).
run_stage(pid_discovery, Candidate, Examples, _, _, Result) :-
    ( Candidate == none ->
        Result = unavailable(no_candidate)
    ; verify_algorithm(Candidate, Examples) ->
        Result = verified
    ;
        Result = rejected(verification_failed)
    ).
run_stage(loop2, _, _, _, _, unavailable(external_adapter_not_installed)).
run_stage(plop, _, _, _, _, unavailable(external_adapter_not_installed)).
run_stage(algebraplop, _, _, _, _, unavailable(external_adapter_not_installed)).
run_stage(pid_optimization, Candidate, Examples, _, _, Result) :-
    ( Candidate == none ->
        Result = unavailable(no_candidate)
    ; verify_algorithm(Candidate, Examples) ->
        Result = verified
    ;
        Result = rejected(verification_failed)
    ).
run_stage(detlog, Candidate, _, _, _, Result) :-
    ( Candidate == none ->
        Result = unavailable(no_candidate)
    ; deterministic_algorithm(Candidate) ->
        Result = deterministic_subset(Candidate)
    ;
        Result = rejected(unsupported_construct)
    ).
run_stage(piglog2, Candidate, _, _, Name,
          neuroalgorithm(Name, input(Input), [], Candidate, output(Output),
              metadata(template_gaps([Input, Output]), dependencies([])))) :-
    Candidate \== none.
run_stage(piglog2, none, _, _, _, unavailable(no_candidate)).
run_stage(compiler, Candidate, _, _, _, compiled(Candidate)) :-
    Candidate \== none.
run_stage(compiler, none, _, _, _, unavailable(no_candidate)).
run_stage(pid_compiled, Candidate, Examples, _, _, Result) :-
    ( Candidate == none ->
        Result = unavailable(no_candidate)
    ; verify_algorithm(Candidate, Examples) ->
        Result = verified
    ;
        Result = rejected(verification_failed)
    ).
run_stage(aioc, Candidate, Examples, Validation, Name, Result) :-
    ( Candidate \== none ->
        incorporate_algorithm(Name, Candidate, Examples, Validation, Status, _),
        Result = Status
    ;
        Result = unavailable(no_candidate)
    ).

deterministic_algorithm(scale(_, _)).
deterministic_algorithm(reverse).
