:- module(mnn, [
    clear_memory/0,
    remember/1,
    indexed_facts/3,
    solve/4,
    solve_status/4,
    render_trace/2
]).

:- dynamic fact/1.
:- dynamic fact_index/4.

clear_memory :-
    retractall(fact(_)),
    retractall(fact_index(_, _, _, _)).

remember(Fact) :-
    must_be(ground, Fact),
    ( fact(Fact) ->
        true
    ;
        functor(Fact, Predicate, Arity),
        fact_key(Fact, FirstArgument),
        assertz(fact(Fact)),
        assertz(fact_index(Predicate, Arity, FirstArgument, Fact))
    ).

fact_key(Fact, none) :-
    functor(Fact, _, 0),
    !.
fact_key(Fact, FirstArgument) :-
    arg(1, Fact, FirstArgument).

indexed_facts(Predicate, Arity, Facts) :-
    findall(Fact, fact_index(Predicate, Arity, _, Fact), Indexed),
    sort(Indexed, Facts).

solve(Query, Answer, Trace, WorkingMemory) :-
    solve_status(Query, solved(Answer), Trace, WorkingMemory).

solve_status(Query, Status, Trace, WorkingMemory) :-
    must_be(nonvar, Query),
    copy_term(Query, OriginalInput),
    findall(Rank-result(Candidate, Explanation, Algorithms, Intermediates),
        ( derive(Query, Candidate, Explanation, Algorithms, Intermediates),
          derivation_rank(Algorithms, Rank)
        ),
        Results),
    ( Results == [] ->
        Status = no_applicable_algorithm,
        Trace = [],
        WorkingMemory = working_memory{
            original_input: OriginalInput,
            canonical_input: OriginalInput,
            bindings: [],
            intermediate_results: [],
            active_goals: [OriginalInput],
            completed_goals: [],
            candidate_algorithms: [],
            rejected_candidates: [],
            output: no_applicable_algorithm
        }
    ;
        keysort(Results, [BestRank-_|_]),
        findall(Candidate,
            member(BestRank-result(Candidate, _, _, _), Results),
            Candidates),
        sort(Candidates, UniqueCandidates),
        resolve_candidates(UniqueCandidates, BestRank, Results,
            Query, OriginalInput, Status, Trace, WorkingMemory)
    ).

resolve_candidates([Answer], BestRank, Results, Query, OriginalInput,
        solved(Answer), Trace, WorkingMemory) :-
    member(BestRank-result(Answer, Trace, Algorithms, Intermediates), Results),
    !,
    Query = Answer,
    WorkingMemory = working_memory{
        original_input: OriginalInput,
        canonical_input: OriginalInput,
        bindings: binding(OriginalInput, Answer),
        intermediate_results: Intermediates,
        active_goals: [],
        completed_goals: [Answer],
        candidate_algorithms: Algorithms,
        rejected_candidates: [],
        output: Answer
    }.
resolve_candidates(Answers, _, _, OriginalInput, OriginalInput,
        ambiguous(Answers), [], WorkingMemory) :-
    WorkingMemory = working_memory{
        original_input: OriginalInput,
        canonical_input: OriginalInput,
        bindings: [],
        intermediate_results: [],
        active_goals: [OriginalInput],
        completed_goals: [],
        candidate_algorithms: [],
        rejected_candidates: Answers,
        output: ambiguous(Answers)
    }.

derivation_rank([direct_fact], 0).
derivation_rank([ownership_colour], 1).
derivation_rank([transitive(_)], 2).

derive(Query, Answer, [sentence(Fact)], [direct_fact], []) :-
    indexed_match(Query, Fact),
    Answer = Fact.
derive(colour_of_owned(Person, Colour), colour_of_owned(Person, Colour),
       [sentence(Ownership), sentence(ColourFact), sentence(Conclusion)],
       [ownership_colour], [Ownership, ColourFact]) :-
    indexed_match(owns(Person, Object), Ownership),
    indexed_match(property(Object, colour, Colour), ColourFact),
    format(string(Conclusion), "Therefore ~w's ~w is ~w.",
        [Person, Object, Colour]).
derive(transitive(Relation, From, To), transitive(Relation, From, To),
       Sentences, [transitive(Relation)], Path) :-
    relation_path(Relation, From, To, [From], Path),
    maplist(path_sentence, Path, PathSentences),
    append(PathSentences, [sentence(transitive(Relation, From, To))], Sentences).

indexed_match(Pattern, Fact) :-
    functor(Pattern, Predicate, Arity),
    ( Arity =:= 0 ->
        fact_index(Predicate, Arity, none, Fact)
    ;
        arg(1, Pattern, FirstArgument),
        ( var(FirstArgument) ->
            fact_index(Predicate, Arity, _, Fact)
        ;
            fact_index(Predicate, Arity, FirstArgument, Fact)
        )
    ),
    Pattern = Fact.

relation_path(Relation, From, To, _Visited, [RelationFact]) :-
    relation_fact(Relation, From, To, RelationFact).
relation_path(Relation, From, To, Visited, [RelationFact|Rest]) :-
    relation_fact(Relation, From, Next, RelationFact),
    \+ memberchk(Next, Visited),
    relation_path(Relation, Next, To, [Next|Visited], Rest).

relation_fact(Relation, From, To, Fact) :-
    Goal =.. [Relation, From, To],
    indexed_match(Goal, Fact).

path_sentence(Fact, sentence(Fact)).

render_trace(Trace, Sentences) :-
    maplist(render_sentence, Trace, Sentences).

render_sentence(sentence(owns(Person, Object)), Text) :-
    !,
    format(string(Text), "~w owns ~w.", [Person, Object]).
render_sentence(sentence(property(Object, colour, Colour)), Text) :-
    !,
    format(string(Text), "The ~w is ~w.", [Object, Colour]).
render_sentence(sentence(transitive(older, Person, Other)), Text) :-
    !,
    format(string(Text), "Therefore ~w is older than ~w.", [Person, Other]).
render_sentence(sentence(transitive(taller, Person, Other)), Text) :-
    !,
    format(string(Text), "Therefore ~w is taller than ~w.", [Person, Other]).
render_sentence(sentence(older(Person, Other)), Text) :-
    !,
    format(string(Text), "~w is older than ~w.", [Person, Other]).
render_sentence(sentence(taller(Person, Other)), Text) :-
    !,
    format(string(Text), "~w is taller than ~w.", [Person, Other]).
render_sentence(sentence(Fact), Text) :-
    Fact =.. [Relation, Person, Other],
    Relation \== transitive,
    !,
    format(string(Text), "~w(~w, ~w).", [Relation, Person, Other]).
render_sentence(sentence(transitive(Relation, Person, Other)), Text) :-
    !,
    format(string(Text), "Therefore ~w is related to ~w by ~w.",
        [Person, Other, Relation]).
render_sentence(sentence(Text), Text) :-
    string(Text),
    !.
