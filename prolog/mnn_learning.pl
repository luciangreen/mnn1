:- module(mnn_learning, [
    discover_algorithm/3,
    apply_algorithm/4,
    verify_algorithm/2,
    incorporate_algorithm/6,
    algorithm_library/3,
    clear_algorithm_library/0,
    save_algorithm_library/1,
    load_algorithm_library/1
]).

:- use_module(library(error)).
:- dynamic algorithm_library/3.

discover_algorithm(Examples, scale(Slope, Offset), discovered(affine, Examples)) :-
    must_be(list, Examples),
    length(Examples, Count),
    Count >= 2,
    affine_candidate(Examples, Slope, Offset),
    verify_algorithm(scale(Slope, Offset), Examples),
    !.
discover_algorithm(Examples, reverse, discovered(list_reversal, Examples)) :-
    must_be(list, Examples),
    length(Examples, Count),
    Count >= 2,
    maplist(reversed_example, Examples).

affine_candidate(Examples, Slope, Offset) :-
    member(io(X1, Y1), Examples),
    member(io(X2, Y2), Examples),
    number(X1),
    number(X2),
    number(Y1),
    number(Y2),
    X1 =\= X2,
    Slope is (Y2 - Y1) / (X2 - X1),
    Offset is Y1 - Slope * X1,
    !.

reversed_example(io(Input, Output)) :-
    is_list(Input),
    reverse(Input, Output).

apply_algorithm(scale(Slope, Offset), Input, Output, Trace) :-
    number(Input),
    Output is Slope * Input + Offset,
    format(string(Trace),
        "The discovered linear transformation computes ~w × input + ~w. ~w × ~w + ~w = ~w.",
        [Slope, Offset, Slope, Input, Offset, Output]).
apply_algorithm(reverse, Input, Output, Trace) :-
    must_be(list, Input),
    reverse(Input, Output),
    format(string(Trace), "The discovered list transformation reverses ~w to ~w.",
        [Input, Output]).

verify_algorithm(Algorithm, Examples) :-
    must_be(list, Examples),
    Examples \= [],
    maplist(algorithm_matches(Algorithm), Examples).

algorithm_matches(scale(Slope, Offset), io(Input, Expected)) :-
    apply_algorithm(scale(Slope, Offset), Input, Actual, _),
    number(Expected),
    Actual =:= Expected,
    !.
algorithm_matches(reverse, io(Input, Expected)) :-
    apply_algorithm(reverse, Input, Actual, _),
    Actual == Expected.

incorporate_algorithm(Name, Algorithm, Training, Validation, Status, Metadata) :-
    must_be(atom, Name),
    ( verify_algorithm(Algorithm, Training),
      verify_algorithm(Algorithm, Validation)
    ->
        Metadata = metadata{
            provenance: Training,
            validation: Validation,
            verification: passed,
            version: 1
        },
        assertz(algorithm_library(Name, Algorithm, Metadata)),
        Status = incorporated
    ;
        Metadata = metadata{verification: failed},
        Status = rejected(regression_failure)
    ).

clear_algorithm_library :-
    retractall(algorithm_library(_, _, _)).

save_algorithm_library(File) :-
    setup_call_cleanup(
        open(File, write, Stream),
        forall(algorithm_library(Name, Algorithm, Metadata),
            write_term(Stream, algorithm(Name, Algorithm, Metadata),
                [quoted(true), fullstop(true), nl(true)])),
        close(Stream)).

load_algorithm_library(File) :-
    setup_call_cleanup(
        open(File, read, Stream),
        read_library_terms(Stream),
        close(Stream)).

read_library_terms(Stream) :-
    read_term(Stream, Term, []),
    ( Term == end_of_file ->
        true
    ; Term = algorithm(Name, Algorithm, Metadata),
      ground(Term),
      atom(Name),
      ( valid_library_algorithm(Algorithm) ->
          assertz(algorithm_library(Name, Algorithm, Metadata))
      ;
          throw(error(domain_error(library_algorithm, Algorithm), _))
      ),
      read_library_terms(Stream)
    ).

valid_library_algorithm(scale(Slope, Offset)) :-
    number(Slope),
    number(Offset).
valid_library_algorithm(reverse).
