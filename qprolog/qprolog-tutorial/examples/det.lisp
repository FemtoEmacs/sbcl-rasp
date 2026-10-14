;;;; det.lisp -- GENERATED from swi/det.pl by bench/pl2lispy.lisp; do not edit.

(<- (fact 0 1) !)
(<- (fact ?n ?f) (> ?n 0) (is ?n1 (- ?n 1)) (fact ?n1 ?f1) (is ?f (* ?n ?f1)))
(<- (fib ?n ?f)
 (:or (< ?n 2) -> (unify ?f ?n)
  (:and (is ?n1 (- ?n 1)) (is ?n2 (- ?n 2)) (fib ?n1 ?f1) (fib ?n2 ?f2) (is ?f (+ ?f1 ?f2)))))
