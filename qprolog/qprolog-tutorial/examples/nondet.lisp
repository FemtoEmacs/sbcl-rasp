;;;; nondet.lisp -- GENERATED from swi/nondet.pl by bench/pl2lispy.lisp; do not edit.

(<- (sentence ?_dcg_1 ?_dcg_2) (noun_phrase ?_dcg_1 ?_dcg_3) (verb_phrase ?_dcg_3 ?_dcg_2))
(<- (noun_phrase ?_dcg_4 ?_dcg_5) (det ?_dcg_4 ?_dcg_6) (noun ?_dcg_6 ?_dcg_5))
(<- (verb_phrase ?_dcg_7 ?_dcg_8) (verb ?_dcg_7 ?_dcg_9) (noun_phrase ?_dcg_9 ?_dcg_8))
(<- (det ?_dcg_10 ?_dcg_11) (unify ?_dcg_10 (the . ?_dcg_11)))
(<- (det ?_dcg_12 ?_dcg_13) (unify ?_dcg_12 (a . ?_dcg_13)))
(<- (noun ?_dcg_14 ?_dcg_15) (unify ?_dcg_14 (parser . ?_dcg_15)))
(<- (noun ?_dcg_16 ?_dcg_17) (unify ?_dcg_16 (sentence . ?_dcg_17)))
(<- (verb ?_dcg_18 ?_dcg_19) (unify ?_dcg_18 (corrects . ?_dcg_19)))
(<- (verb ?_dcg_20 ?_dcg_21) (unify ?_dcg_20 (reads . ?_dcg_21)))
