# qprolog tutorial

qprolog is a Prolog compiler written in Common Lisp (SBCL), based on a model
by Roger Allan. The engine is the parent folder (`qprolog`); this folder holds the
tutorial and its examples.

Idea of the project: Jeffrey Ishizuka, Curtis Perry, David van Dijk,
Ivan Vrkic, Philippos Costa and Lucas Guerra.

You need `sbcl`. Section 1 also needs `swipl`.
Run every command from this folder (`qprolog-tutorial`).

## 1. Benchmark: qprolog against SWI-Prolog

```sh
../bench/vs-swi.sh            # full run, about 1 s per program in SWI
../bench/vs-swi.sh 0.2 3      # quicker: fewer iterations, median of 3 runs
```

Both systems run the same 15 classical programs (boyer, browse, chat_parser,
crypt, derive, det, divide10, fast_mu, reducer, sendmore, serialize, sieve,
simple_analyzer, tak, zebra). The table shows milliseconds per call for each
system and the ratio qprolog/SWI: below 1 means qprolog is faster. The last
line is the geometric mean. Raw numbers are saved in `../results/`.

## 2. From Edinburgh notation to Lispy notation

Write ordinary Prolog (`X is Expr`, `[H|T]`, `->`, `-->`) in a `.pl` file,
then translate it:

```sh
../tr.x examples/tco.pl          # writes examples/tco.lisp
../tr.x examples/det.pl
../tr.x examples/nondet.pl
```

What changes:

| Edinburgh | Lispy |
|---|---|
| `p(X) :- q(X), r(X).` | `(<- (p ?x) (q ?x) (r ?x))` |
| `X is N + 1` | `(is ?x (+ ?n 1))` |
| `X = Y` | `(unify ?x ?y)` |
| `[H\|T]` | `(?h . ?t)` |
| `[a,b,c]` | `(:l a b c)` |
| `( C -> T ; E )` | `(:or c -> t e)` |

### Tail-call optimisation: `examples/tco.pl`

```prolog
sum_to(N, S) :- sum_to(N, 0, S).

sum_to(0, Acc, Acc) :- !.
sum_to(N, Acc, S) :-
    Acc1 is Acc + N,
    N1 is N - 1,
    sum_to(N1, Acc1, S).
```

becomes

```lisp
(<- (sum_to ?n ?s) (sum_to ?n 0 ?s))
(<- (sum_to 0 ?acc ?acc) !)
(<- (sum_to ?n ?acc ?s) (is ?acc1 (+ ?acc ?n)) (is ?n1 (- ?n 1)) (sum_to ?n1 ?acc1 ?s))
```

The recursive call is the last goal, so ten million steps run in constant
stack space.

### Deterministic programming: `examples/det.pl`

```prolog
fact(0, 1) :- !.
fact(N, F) :- N > 0, N1 is N - 1, fact(N1, F1), F is N * F1.

fib(N, F) :-
    (   N < 2
    ->  F = N
    ;   N1 is N - 1, N2 is N - 2,
        fib(N1, F1), fib(N2, F2),
        F is F1 + F2
    ).
```

becomes

```lisp
(<- (fact 0 1) !)
(<- (fact ?n ?f) (> ?n 0) (is ?n1 (- ?n 1)) (fact ?n1 ?f1) (is ?f (* ?n ?f1)))
(<- (fib ?n ?f)
 (:or (< ?n 2) -> (unify ?f ?n)
  (:and (is ?n1 (- ?n 1)) (is ?n2 (- ?n 2)) (fib ?n1 ?f1) (fib ?n2 ?f2) (is ?f (+ ?f1 ?f2)))))
```

Each call has exactly one answer; the cut and the if-then-else leave no
choice points.

### Non-deterministic programming: `examples/nondet.pl`

```prolog
sentence --> noun_phrase, verb_phrase.
noun_phrase --> det, noun.
verb_phrase --> verb, noun_phrase.

det  --> [the].
det  --> [a].
noun --> [parser].
noun --> [sentence].
verb --> [corrects].
verb --> [reads].
```

becomes (the grammar rules get two extra arguments: the input list and what
is left of it)

```lisp
(<- (sentence ?_dcg_1 ?_dcg_2) (noun_phrase ?_dcg_1 ?_dcg_3) (verb_phrase ?_dcg_3 ?_dcg_2))
(<- (det ?_dcg_10 ?_dcg_11) (unify ?_dcg_10 (the . ?_dcg_11)))
...
```

The same program checks a sentence or, by backtracking, generates all of them.

## 3. Compile and run

`../qp FILE GOAL` loads the file, compiles each clause the first time
it is called, and prints the goal with its variables filled in. Add `-a` for
all solutions.

```sh
../qp examples/tco.lisp '(sum_to 10000000 ?s)'
#   (SUM_TO 10000000 50000005000000)   yes

../qp examples/det.lisp '(fact 30 ?f)'
#   (FACT 30 265252859812191058636308480000000)   yes
../qp examples/det.lisp '(fib 25 ?f)'
#   (FIB 25 75025)   yes

../qp examples/nondet.lisp '(sentence (:l the parser corrects a sentence) ())'
#   yes
../qp examples/nondet.lisp '(sentence (:l parser the corrects) ())'
#   no
../qp examples/nondet.lisp '(sentence ?s ())' -a
#   ... 32 solutions
```

`qp` also accepts the `.pl` file and translates it on the fly:

```sh
../qp examples/nondet.pl '(sentence (:l a parser reads the sentence) ())'
```

To keep the compiled program loaded between goals, use the SBCL REPL:

```lisp
$ sbcl --load ../load.lisp
* (qp::load-qp "examples/det.lisp")
* (qp::solve-one '(fib 20 ?f))        ; T ((QPROLOG::FIB 20 6765))
* (qp::load-qp "examples/nondet.lisp")
* (qp::solve-all '(sentence ?s ()))   ; T, followed by the 32 sentences
* (sb-ext:exit)
```

Goals are written in Lispy notation. Lists that start with an atom need `:l`:
`(:l the parser reads)`. More details: `../README.md`, section 4.
