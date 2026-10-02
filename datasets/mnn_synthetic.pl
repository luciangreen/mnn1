:- module(mnn_synthetic, [
    multivariate_scenes/1,
    split_scenes/3
]).

shape(circle).
shape(square).
shape(triangle).
colour(red).
colour(green).
colour(blue).
size(small).
size(medium).
size(large).
position(left).
position(centre).
position(right).

multivariate_scenes(Scenes) :-
    findall(scene(Shape, Colour, Size, Position),
        ( shape(Shape),
          colour(Colour),
          size(Size),
          position(Position)
        ),
        Scenes).

split_scenes(HeldOut, Training, Test) :-
    must_be(list, HeldOut),
    multivariate_scenes(All),
    sort(HeldOut, UniqueHeldOut),
    length(HeldOut, HeldOutCount),
    length(UniqueHeldOut, HeldOutCount),
    maplist(member_of(All), UniqueHeldOut),
    partition(is_held_out(UniqueHeldOut), All, Test, Training).

member_of(List, Element) :-
    memberchk(Element, List).

is_held_out(HeldOut, Scene) :-
    memberchk(Scene, HeldOut).
