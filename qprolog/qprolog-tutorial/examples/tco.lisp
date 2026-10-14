;;;; tco.lisp -- GENERATED from swi/tco.pl by bench/pl2lispy.lisp; do not edit.

(<- (sum_to ?n ?s) (sum_to ?n 0 ?s))
(<- (sum_to 0 ?acc ?acc) !)
(<- (sum_to ?n ?acc ?s) (is ?acc1 (+ ?acc ?n)) (is ?n1 (- ?n 1)) (sum_to ?n1 ?acc1 ?s))
