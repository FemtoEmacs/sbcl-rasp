% Tail-call optimisation: the recursive call is the last goal,
% so a loop of ten million steps runs in constant stack space.
sum_to(N, S) :- sum_to(N, 0, S).

sum_to(0, Acc, Acc) :- !.
sum_to(N, Acc, S) :-
    Acc1 is Acc + N,
    N1 is N - 1,
    sum_to(N1, Acc1, S).
