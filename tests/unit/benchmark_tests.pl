:- begin_tests(mnn_benchmark).

:- use_module('../../benchmarks/mnn_benchmark').

test(algorithm_generalises_beyond_literal_lookup) :-
    Training = [io(1, 2), io(2, 4), io(3, 6), io(4, 8)],
    Seen = [io(1, 2), io(3, 6)],
    Unseen = [io(137, 274), io(25, 50)],
    generalisation_report(scale(2, 0), Training, Seen, Unseen, Report),
    assertion(Report.seen.accuracy =:= 1),
    assertion(Report.unseen.accuracy =:= 1),
    assertion(Report.generalisation_ratio =:= 1),
    assertion(Report.lookup_seen.accuracy =:= 1),
    assertion(Report.lookup_unseen.accuracy =:= 0).

test(empty_dataset_has_undefined_accuracy) :-
    evaluate_algorithm(scale(2, 0), [], Report),
    assertion(Report.accuracy == undefined),
    assertion(Report.executions == 0).

:- end_tests(mnn_benchmark).
