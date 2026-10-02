:- begin_tests(mnn_learning).

:- use_module('../../prolog/mnn_learning').

test(discover_and_apply_affine_rule) :-
    Examples = [io(1, 2), io(2, 4), io(3, 6), io(4, 8)],
    discover_algorithm(Examples, scale(Slope, Offset), discovered(affine, Examples)),
    assertion(Slope =:= 2),
    assertion(Offset =:= 0),
    apply_algorithm(scale(Slope, Offset), 137, 274, Trace),
    assertion(string(Trace)).

test(discover_list_reversal) :-
    Examples = [io([a, b], [b, a]), io([1, 2, 3], [3, 2, 1])],
    discover_algorithm(Examples, Algorithm, discovered(list_reversal, Examples)),
    assertion(Algorithm == reverse),
    apply_algorithm(Algorithm, [x, y, z], [z, y, x], _).

test(reject_invalid_generalisation, [fail]) :-
    verify_algorithm(scale(2, 0), [io(1, 2), io(2, 5)]).

test(incorporate_only_after_validation, [setup(clear_algorithm_library), cleanup(clear_algorithm_library)]) :-
    Training = [io(1, 2), io(2, 4)],
    Validation = [io(137, 274)],
    incorporate_algorithm(double, scale(2, 0), Training, Validation,
        incorporated, Metadata),
    assertion(Metadata.verification == passed),
    assertion(algorithm_library(double, scale(2, 0), _)),
    incorporate_algorithm(broken, scale(2, 0), Training, [io(10, 21)],
        rejected(regression_failure), _),
    assertion(\+ algorithm_library(broken, _, _)).

test(library_persistence_round_trip,
     [setup(clear_algorithm_library), cleanup(clear_algorithm_library)]) :-
    tmp_file_stream(text, File, Stream),
    close(Stream),
    setup_call_cleanup(
        true,
        ( incorporate_algorithm(double, scale(2, 0),
              [io(1, 2), io(2, 4)], [io(137, 274)], incorporated, _),
          save_algorithm_library(File),
          clear_algorithm_library,
          load_algorithm_library(File),
          algorithm_library(double, scale(2, 0), Metadata),
          assertion(Metadata.verification == passed)
        ),
        ( delete_file(File), clear_algorithm_library )
    ).

test(library_input_is_not_executed, [fail]) :-
    tmp_file_stream(text, File, Stream),
    setup_call_cleanup(
        true,
        ( write_term(Stream, throw(untrusted_term_executed),
              [fullstop(true), nl(true)]),
          close(Stream),
          load_algorithm_library(File)
        ),
        ( catch(close(Stream), _, true), delete_file(File) )
    ).

:- end_tests(mnn_learning).
