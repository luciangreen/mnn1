:- module(mnn_benchmark, [
    evaluate_algorithm/3,
    evaluate_lookup/3,
    generalisation_report/5
]).

:- use_module('../prolog/mnn_learning').

evaluate_algorithm(_, [], Report) :-
    !,
    Report = evaluation{
        total: 0, correct: 0, failed: 0, accuracy: undefined, executions: 0
    }.
evaluate_algorithm(Algorithm, Examples, Report) :-
    Examples = [_|_],
    evaluate_examples(Examples, Algorithm, 0, Correct),
    length(Examples, Total),
    Failed is Total - Correct,
    Accuracy is Correct / Total,
    Report = evaluation{
        total: Total,
        correct: Correct,
        failed: Failed,
        accuracy: Accuracy,
        executions: Total
    }.

evaluate_lookup(_, [], Report) :-
    !,
    Report = evaluation{
        total: 0, correct: 0, failed: 0, accuracy: undefined, executions: 0
    }.
evaluate_lookup(Knowledge, Examples, Report) :-
    Examples = [_|_],
    evaluate_lookup_examples(Examples, Knowledge, 0, Correct),
    length(Examples, Total),
    Failed is Total - Correct,
    Accuracy is Correct / Total,
    Report = evaluation{
        total: Total,
        correct: Correct,
        failed: Failed,
        accuracy: Accuracy,
        executions: Total
    }.

generalisation_report(Algorithm, Training, Seen, Unseen, Report) :-
    evaluate_algorithm(Algorithm, Seen, SeenResult),
    evaluate_algorithm(Algorithm, Unseen, UnseenResult),
    evaluate_lookup(Training, Seen, SeenLookup),
    evaluate_lookup(Training, Unseen, UnseenLookup),
    ratio(SeenResult.accuracy, UnseenResult.accuracy, Ratio),
    Report = generalisation{
        algorithm: Algorithm,
        seen: SeenResult,
        unseen: UnseenResult,
        generalisation_ratio: Ratio,
        lookup_seen: SeenLookup,
        lookup_unseen: UnseenLookup
    }.

evaluate_examples([], _, Correct, Correct).
evaluate_examples([io(Input, Expected)|Examples], Algorithm, Accumulator, Correct) :-
    ( catches_expected_output(Algorithm, Input, Expected) ->
        Next is Accumulator + 1
    ;
        Next = Accumulator
    ),
    evaluate_examples(Examples, Algorithm, Next, Correct).

evaluate_lookup_examples([], _, Correct, Correct).
evaluate_lookup_examples([io(Input, Expected)|Examples], Knowledge, Accumulator, Correct) :-
    ( lookup_output(Knowledge, Input, Actual),
      outputs_equal(Actual, Expected)
    ->
        Next is Accumulator + 1
    ;
        Next = Accumulator
    ),
    evaluate_lookup_examples(Examples, Knowledge, Next, Correct).

catches_expected_output(Algorithm, Input, Expected) :-
    catch(apply_algorithm(Algorithm, Input, Actual, _), _, fail),
    outputs_equal(Actual, Expected).

lookup_output(Knowledge, Input, Output) :-
    member(io(StoredInput, Output), Knowledge),
    StoredInput == Input,
    !.

outputs_equal(Actual, Expected) :-
    number(Actual),
    number(Expected),
    !,
    Actual =:= Expected.
outputs_equal(Actual, Expected) :-
    Actual == Expected.

ratio(0, _, undefined) :-
    !.
ratio(Seen, Unseen, Ratio) :-
    Ratio is Unseen / Seen.
