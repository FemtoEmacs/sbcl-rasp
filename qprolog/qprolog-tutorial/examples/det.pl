% Deterministic programming: each call has exactly one answer.
% First-argument indexing and if-then-else leave no choice points.
fact(0, 1) :- !.
fact(N, F) :- N > 0, N1 is N - 1, fact(N1, F1), F is N * F1.

fib(N, F) :-
    (   N < 2
    ->  F = N
    ;   N1 is N - 1, N2 is N - 2,
        fib(N1, F1), fib(N2, F2),
        F is F1 + F2
    ).
