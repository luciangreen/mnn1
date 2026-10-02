:- begin_tests(mnn_synthetic).

:- use_module('../../datasets/mnn_synthetic').

test(cartesian_product_has_81_values) :-
    multivariate_scenes(Scenes),
    length(Scenes, 81),
    sort(Scenes, Unique),
    length(Unique, 81).

test(held_out_combinations_preserve_individual_values) :-
    Withheld = [
        scene(triangle, green, large, right),
        scene(circle, blue, medium, left),
        scene(square, red, small, centre)
    ],
    split_scenes(Withheld, Training, Test),
    sort(Test, SortedTest),
    sort(Withheld, SortedWithheld),
    assertion(SortedTest == SortedWithheld),
    forall(member(scene(Shape, Colour, Size, Position), Withheld),
        ( member(scene(Shape, _, _, _), Training),
          member(scene(_, Colour, _, _), Training),
          member(scene(_, _, Size, _), Training),
          member(scene(_, _, _, Position), Training)
        )).

:- end_tests(mnn_synthetic).
