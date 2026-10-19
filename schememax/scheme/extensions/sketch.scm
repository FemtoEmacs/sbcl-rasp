;;;; sketch.scm -- C-c p: draw the plot table at the cursor
;;;;
;;;; A textified paper (C-c f) carries its Kaplan-Meier curves as
;;;; (estimator-plot ...) tables (ttfy/plots-guidelines.md, schema
;;;; schememax/km-table/1).  Put the cursor on a table, or anywhere inside
;;;; it, and press C-c p (M-x plot-at-point): the curves are redrawn in a
;;;; window of their own by irene-dixe, a small drawing program built with
;;;; Schememax.  Without a display (an ssh session, say), or without
;;;; irene-dixe, a rough character sketch opens in the *plot* buffer.
;;;;
;;;; The table is DATA.  It is read, never evaluated, and text with a #
;;;; outside strings is refused, because the reader's #. would evaluate.
;;;; (image ...) forms, the sketches of diagnostic images, will use the same
;;;; key; they are not drawn yet.

(define *sketch-viewer-name* "irene-dixe")
(define *plot-buffer* "*plot*")
(define *sketch-forms* '("(estimator-plot" "(image"))

;;; ------------------------------------------------------------------
;;; Property lists and numbers
;;; ------------------------------------------------------------------

(define (pget plist key (default #f))
  "The value after KEY in the property list PLIST, or DEFAULT."
  (let loop ((l plist))
    (cond ((or (not (pair? l)) (not (pair? (cdr l)))) default)
          ((eq? (car l) key) (cadr l))
          (else (loop (cddr l))))))

(define (plist-list v)
  "V when it is a list of entries; '() for nil, :not-shown and the like."
  (if (pair? v) v '()))

(define (sketch-number x what)
  (if (number? x) x (error (concat "plot table: " what " is not a number: " (->string x)))))

(define (fmt-num x)
  "X with at most two decimals, for labels: 0.8, 24, 2.7 (never 2.7000000000000002)."
  (if (not (number? x)) (->string x)
      (let* ((neg (< x 0))
             (n (exact (round (* (abs x) 100))))
             (whole (quotient n 100))
             (frac (remainder n 100))
             (digits (cond ((= frac 0) "")
                           ((= (remainder frac 10) 0) (concat "." (quotient frac 10)))
                           ((< frac 10) (concat ".0" frac))
                           (else (concat "." frac)))))
        (concat (if (and neg (> n 0)) "-" "") whole digits))))

(define (num-text x)
  "X for the drawing file: full precision, which C reads with strtod."
  (if (number? x) (number->string (exact->inexact x)) "0"))

;;; ------------------------------------------------------------------
;;; Finding and reading the table at the cursor
;;; ------------------------------------------------------------------

(define (sexp-end text start)
  "The byte after the list that opens at START in TEXT, or #f.  Strings
and ; comments are skipped."
  (let ((n (length text)))
    (let loop ((i start) (depth 0) (in-string #f))
      (if (>= i n) #f
          (let ((b (aref text i)))
            (cond (in-string
                   (cond ((= b 92) (loop (+ i 2) depth #t))      ; backslash
                         ((= b 34) (loop (+ i 1) depth #f))
                         (else (loop (+ i 1) depth #t))))
                  ((= b 34) (loop (+ i 1) depth #t))
                  ((= b 59) (let skip ((j i))                     ; ;comment
                              (if (or (>= j n) (= (aref text j) 10)) (loop j depth #f) (skip (+ j 1)))))
                  ((= b 40) (loop (+ i 1) (+ depth 1) #f))
                  ((= b 41) (if (= depth 1) (+ i 1) (loop (+ i 1) (- depth 1) #f)))
                  (else (loop (+ i 1) depth #f))))))))

(define (safe-sexp-text? text)
  "No # outside strings and comments: #. would run code while reading."
  (let ((n (length text)))
    (let loop ((i 0) (in-string #f))
      (if (>= i n) #t
          (let ((b (aref text i)))
            (cond (in-string
                   (cond ((= b 92) (loop (+ i 2) #t))
                         ((= b 34) (loop (+ i 1) #f))
                         (else (loop (+ i 1) #t))))
                  ((= b 34) (loop (+ i 1) #t))
                  ((= b 59) (let skip ((j i))
                              (if (or (>= j n) (= (aref text j) 10)) (loop j #f) (skip (+ j 1)))))
                  ((= b 35) #f)
                  (else (loop (+ i 1) #f))))))))

(define (form-starts text)
  "Byte offsets of every sketchable form in TEXT, in order."
  (sort (apply append
               (map (lambda (head)
                      (let loop ((i (string-search head text 0)) (acc '()))
                        (if i (loop (string-search head text (+ i 1)) (cons i acc)) acc)))
                    *sketch-forms*))
        <))

(define (form-at text pos)
  "(start . end) of the table the cursor is in: on its opening paren,
anywhere inside it, or just after its closing paren.  #f elsewhere, so C-c p
outside a table draws nothing."
  (let loop ((starts (form-starts text)) (found #f))
    (if (or (null? starts) (> (car starts) pos))
        found
        (let ((end (sexp-end text (car starts))))
          (loop (cdr starts) (if (and end (<= pos end)) (cons (car starts) end) found))))))

(define (read-sketch-form text)
  "The table in TEXT as data, after the safety check."
  (if (not (safe-sexp-text? text))
      (error "plot table refused: it contains # outside strings (the reader would run #. code)")
      (read (open-input-string text))))

;;; ------------------------------------------------------------------
;;; Kaplan-Meier: from the table to drawing records
;;; ------------------------------------------------------------------

(define *named-colors*
  '(("blue" 31 119 180) ("red" 214 39 40) ("green" 44 160 44) ("orange" 255 127 14)
    ("purple" 148 103 189) ("brown" 140 86 75) ("pink" 227 119 194) ("gray" 127 127 127)
    ("grey" 127 127 127) ("black" 30 30 30) ("olive" 188 189 34) ("cyan" 23 190 207)
    ("teal" 0 128 128) ("navy" 0 0 128) ("magenta" 200 0 200) ("yellow" 200 170 0)))

(define (series-color style index)
  "RGB of a cohort: its legend colour when the table names one, otherwise a
palette colour by INDEX."
  (let* ((name (pget (plist-list style) ':color #f))
         (key (and (string? name) (string-downcase (car (string-split (trim name) " ")))))
         (known (and key (assoc key *named-colors*))))
    (if known (cdr known)
        (cdr (list-ref *named-colors* (modulo index 8))))))

(define (nice-ticks lo hi)
  "About six round tick values from LO to HI."
  (let* ((span (if (> hi lo) (- hi lo) 1))
         (raw (/ span 6.0))
         (mag (expt 10 (exact (floor (/ (log raw) (log 10))))))
         (step (let ((r (/ raw mag)))
                 (* mag (cond ((< r 1.5) 1) ((< r 3) 2) ((< r 7) 5) (else 10))))))
    (let loop ((t (* step (ceiling (/ lo step)))) (acc '()))
      (if (> t (+ hi (* step 0.001))) (reverse acc) (loop (+ t step) (cons t acc))))))

(define (axis-info axes key steps-max default-max)
  "(label lo hi ticks) for axis KEY (:x or :y)."
  (let* ((a (plist-list (pget axes key '())))
         (limits (pget a ':limits #f))
         (lo (if (and (pair? limits) (number? (car limits))) (car limits) 0))
         (hi (if (and (pair? limits) (pair? (cdr limits)) (number? (cadr limits)))
                 (cadr limits)
                 (max steps-max default-max)))
         (ticks (pget a ':ticks #f))
         (label (pget a ':label "")))
    (list (if (string? label) label (->string label)) lo hi
          (if (and (pair? ticks) (number? (car ticks))) ticks (nice-ticks lo hi)))))

;; A table records a curve in one of two ways (ttfy/plots-guidelines.md):
;;   every visible step:   :start, then :drop rows (time, from, to), :end
;;   sampled landmarks:    :start, :landmark rows (time, survival), :end
;; Steps are drawn as the staircase they are.  Between landmarks the shape
;; is not known, so they are joined by a thin dotted line and each one gets
;; a dot: the picture must not claim more than the table holds.
(define (curve-segments curve tolerance)
  "(segments notes points): segments are (x1 y1 x2 y2 kind), kind step or
link (dotted, between sampled landmarks); points are the landmarks (x y)."
  (let loop ((steps (plist-list (pget curve ':steps '())))
             (prev #f) (mode 'step) (segs '()) (notes '()) (points '()))
    (if (null? steps) (list (reverse segs) (reverse notes) (reverse points))
        (let* ((row (car steps))
               (kind (pget row ':kind #f))
               (t (pget row ':time #f))
               (sv (pget row ':survival #f)))
          (cond ((not (number? t))
                 (loop (cdr steps) prev mode segs (cons "a row without a numeric :time was skipped" notes) points))
                ((eq? kind ':start)
                 (loop (cdr steps) (list t (sketch-number sv ":survival")) 'step segs notes points))
                ((eq? kind ':drop)
                 (let* ((from (sketch-number (pget row ':from #f) ":from"))
                        (to (sketch-number (pget row ':to #f) ":to")))
                   (if (not prev)
                       ;; a curve that starts with a drop: begin at its top
                       (loop (cdr steps) (list t to) 'step (cons (list t from t to 'step) segs) notes points)
                       (let* ((px (car prev)) (py (cadr prev))
                              (notes (if (> (abs (- from py)) tolerance)
                                         (cons (concat "at time " (fmt-num t) " the drop starts at " (fmt-num from)
                                                       ", but the curve was at " (fmt-num py))
                                               notes)
                                         notes))
                              (lead (if (eq? mode 'link) (list px py t from 'link) (list px py t py 'step))))
                         (loop (cdr steps) (list t to) 'step
                               (cons (list t from t to 'step) (cons lead segs))
                               notes points)))))
                ((eq? kind ':end)
                 (cond ((not prev)
                        (if (number? sv)
                            (loop (cdr steps) (list t sv) mode segs notes (cons (list t sv) points))
                            (loop (cdr steps) prev mode segs notes points)))
                       ((eq? mode 'link)
                        (let ((y (if (number? sv) sv (cadr prev))))
                          (loop (cdr steps) (list t y) mode
                                (cons (list (car prev) (cadr prev) t y 'link) segs) notes (cons (list t y) points))))
                       (else
                        (let ((px (car prev)) (py (cadr prev)))
                          (loop (cdr steps) (list t py) mode (cons (list px py t py 'step) segs)
                                (if (and (number? sv) (> (abs (- sv py)) tolerance))
                                    (cons (concat "the end row at time " (fmt-num t) " says " (fmt-num sv)
                                                  ", but the curve was at " (fmt-num py))
                                          notes)
                                    notes)
                                points)))))
                ((number? sv)
                 ;; :landmark, or an unknown kind that still gives a point
                 (let ((notes (if (eq? kind ':landmark) notes
                                  (cons (concat "row kind " (->string kind) " drawn as a sampled point") notes))))
                   (loop (cdr steps) (list t sv) 'link
                         (if prev (cons (list (car prev) (cadr prev) t sv 'link) segs) segs)
                         notes (cons (list t sv) points))))
                (else
                 (loop (cdr steps) prev mode segs (cons (concat "unknown row kind " (->string kind)) notes) points)))))))

(define (curve-gaps curve)
  "The unresolved intervals of the CURVE itself (not those about censor marks)."
  (filter-map (lambda (u)
                (and (pair? u) (not (eq? (pget u ':feature #f) ':censors))
                     (number? (pget u ':from-time #f)) (number? (pget u ':to-time #f))
                     (list (pget u ':from-time) (pget u ':to-time)
                           (let ((r (pget u ':reason ""))) (if (string? r) r "")))))
              (plist-list (pget curve ':unresolved '()))))

(define (sketch-line s)
  "S on one line (newlines become spaces), at most about 200 bytes."
  (let* ((t (string-join (string-split (->string s) "\n") " "))
         (t (string-join (string-split t "\r") " ")))
    (if (> (length t) 200) (string.sub t 0 200) t)))

(define (statistic-row-line row name)
  "One printed statistic given as its own row, (:kind :median ...) and the like."
  (let* ((kind (pget row ':kind #f))
         (v (pget row ':value #f))
         (vt (cond ((number? v) (fmt-num v))
                   ((eq? v ':not-reached) "not reached")
                   ((string? v) v)
                   (v (->string v))
                   (else "")))
         (ci (pget row ':ci #f))
         (who (cond ((pget row ':cohort #f) (name (pget row ':cohort)))
                    ((string? (pget row ':comparison #f)) (pget row ':comparison))
                    (else ""))))
    (cond ((eq? kind ':median)
           (concat "Median, " who ": " vt (if (and (number? v) (pget row ':unit #f)) (concat " " (->string (pget row ':unit))) "")))
          ((eq? kind ':p-value)
           (concat "p " (if (and (> (length vt) 0) (memv (aref vt 0) '(60 62 61))) vt (concat "= " vt))
                   (if (> (length who) 0) (concat " (" who ")") "")))
          (else
           (concat (if kind (let ((k (->string kind))) (if (string-prefix? ":" k) (string.sub k 1 (length k)) k)) "value")
                   (if (> (length who) 0) (concat ", " who) "") ": " vt
                   (if (pair? ci) (concat " (CI " (fmt-num (car ci)) "-" (fmt-num (cadr ci)) ")") ""))))))

(define (statistics-lines stats labels)
  "Short readable lines for the printed statistics: either a plist with
:rows and :comparison, or a list of rows each with its :kind."
  (if (not (pair? stats)) '()
   (if (pair? (car stats))
      (let ((name (lambda (id) (let ((e (assq id labels))) (if e (cdr e) (->string id))))))
        (map (lambda (row) (statistic-row-line row name)) (filter pair? stats)))
      (let ((name (lambda (id) (let ((e (assq id labels))) (if e (cdr e) (->string id))))))
        (append
         (map (lambda (row)
                (let ((ci (pget row ':ci #f)) (med (pget row ':median-survival #f)))
                  (concat (name (pget row ':cohort "")) ":"
                          (if (pget row ':patients #f) (concat " " (pget row ':patients) " patients") "")
                          (if (pget row ':events #f) (concat ", " (pget row ':events) " events") "")
                          (if med (concat ", median " (fmt-num med) " " (->string (pget row ':unit ""))) "")
                          (if (pair? ci) (concat " (CI " (fmt-num (car ci)) "-" (fmt-num (cadr ci)) ")") ""))))
              (filter pair? (plist-list (pget stats ':rows '()))))
         (let ((c (pget stats ':comparison #f)))
           (if (not (pair? c)) '()
               (let ((ci (pget c ':ci #f)) (p (pget c ':p-value #f)))
                 (list (concat (if (eq? (pget c ':measure #f) 'hazard-ratio) "HR" (->string (pget c ':measure "effect")))
                               " " (fmt-num (pget c ':estimate ""))
                               (if (pair? ci) (concat " (CI " (fmt-num (car ci)) "-" (fmt-num (cadr ci)) ")") "")
                               (if p (concat ", p " (->string p)) "")
                               (if (pget c ':reference #f) (concat ", vs " (name (pget c ':reference))) "")))))))))))

(define (km-drawing form)
  "The lines of the drawing file for an (estimator-plot ...) FORM."
  (let* ((plist (cdr form))
         (axes (plist-list (pget plist ':axes '())))
         (cohorts (filter pair? (plist-list (pget plist ':cohorts '()))))
         (curves (filter pair? (plist-list (pget plist ':curves '()))))
         (labels (map (lambda (c) (cons (pget c ':id #f) (->string (pget c ':label (pget c ':id ""))))) cohorts))
         (all-steps (apply append (map (lambda (c) (plist-list (pget c ':steps '()))) curves)))
         (max-time (apply max 0 (filter number? (map (lambda (r) (pget r ':time #f)) all-steps))))
         (percent (eq? (pget (plist-list (pget axes ':y '())) ':unit #f) 'percent))
         (x (axis-info axes ':x max-time 1))
         (y (axis-info axes ':y 0 (if percent 100 1)))
         (ytol (* 0.015 (- (caddr y) (cadr y))))
         (out '()))
    (define (emit . parts) (set! out (cons (apply concat parts) out)))
    (when (null? curves) (error "plot table: no :curves"))
    (emit "sketch 1")
    (emit "title " (sketch-line (pget plist ':title (pget plist ':type "Kaplan-Meier curves"))))
    (emit "subtitle " (sketch-line (concat (->string (pget plist ':endpoint ""))
                                        (let ((p (pget plist ':provenance #f)))
                                          (if (pair? p)
                                              (concat "  [" (->string (pget p ':source "")) ", figure "
                                                      (->string (pget p ':figure "?")) "]")
                                              "")))))
    (emit "xaxis " (num-text (cadr x)) " " (num-text (caddr x)) " " (sketch-line (car x)))
    (emit "xticks " (string-join (map num-text (cadddr x)) " "))
    (emit "yaxis " (num-text (cadr y)) " " (num-text (caddr y)) " " (sketch-line (car y)))
    (emit "yticks " (string-join (map num-text (cadddr y)) " "))
    ;; One series per cohort: a cohort may have several curve records (a
    ;; trace split by an overlap), drawn in the same colour, listed once.
    (define (series-index id k)
      (or (list-index (lambda (c) (eq? (pget c ':id #f) id)) cohorts)
          (+ (length cohorts) k)))
    (define listed '())
    (let loop ((cs curves) (k 0))
      (when (pair? cs)
        (let* ((curve (car cs))
               (id (pget curve ':cohort #f))
               (i (series-index id k))
               (cohort (or (find (lambda (c) (eq? (pget c ':id #f) id)) cohorts) '()))
               ;; (:cohort (p1 p2 p3)): a trace the cohorts share where they overlap
               (shared (pair? id))
               (rgb (if shared '(60 60 60) (series-color (pget cohort ':style '()) i)))
               (label (cond (shared
                             (concat (string-join (map (lambda (m) (let ((e (assq m labels))) (if e (cdr e) (->string m)))) id)
                                                  " / ")
                                     " (overlapping)"))
                            ((assq id labels) => cdr)
                            (else (->string (or id (concat "curve " (+ k 1)))))))
               (dashed (eq? (pget (plist-list (pget cohort ':style '())) ':line #f) ':dashed))
               (tol (let ((v (pget curve ':survival-tolerance #f))) (if (number? v) (max v ytol) ytol)))
               (result (curve-segments curve tol)))
          (unless (memv i listed)
            (set! listed (cons i listed))
            (emit "series " i " " (car rgb) " " (cadr rgb) " " (caddr rgb) " " (if dashed 1 0) " " (sketch-line label)))
          (for-each (lambda (s) (emit (if (eq? (list-ref s 4) 'link) "link " "seg ") i " "
                                      (num-text (car s)) " " (num-text (cadr s)) " "
                                      (num-text (caddr s)) " " (num-text (cadddr s))))
                    (car result))
          (for-each (lambda (p) (emit "point " i " " (num-text (car p)) " " (num-text (cadr p))))
                    (caddr result))
          (for-each (lambda (c)
                      (when (and (number? (pget c ':time #f)) (number? (pget c ':survival #f)))
                        (emit "censor " i " " (num-text (pget c ':time)) " " (num-text (pget c ':survival)))))
                    (filter pair? (plist-list (pget curve ':censors '()))))
          (for-each (lambda (g) (emit "gap " i " " (num-text (car g)) " " (num-text (cadr g)) " " (sketch-line (caddr g))))
                    (curve-gaps curve))
          (for-each (lambda (n) (emit "note " (sketch-line (concat label ": " n)))) (cadr result))
          (loop (cdr cs) (+ k 1)))))
    (let ((risk (pget plist ':numbers-at-risk #f)))
      (when (and (pair? risk) (pair? (pget risk ':times #f)))
        (emit "risktimes " (string-join (map num-text (filter number? (pget risk ':times))) " "))
        (for-each (lambda (row)
                    (let ((idx (and (find (lambda (c) (eq? (pget c ':cohort #f) (pget row ':cohort #f))) curves)
                                    (series-index (pget row ':cohort #f) 0))))
                      (when idx
                        (emit "risk " idx " " (string-join (map (lambda (v) (if (number? v) (fmt-num v) "-"))
                                                                (plist-list (pget row ':counts '())))
                                                           " ")))))
                  (filter pair? (plist-list (pget risk ':rows '()))))))
    (for-each (lambda (s) (emit "stat " (sketch-line s))) (statistics-lines (pget plist ':statistics #f) labels))
    (for-each (lambda (s) (when (string? s) (emit "remark " (sketch-line s))))
              (plist-list (pget plist ':annotations '())))
    (reverse out)))

;;; ------------------------------------------------------------------
;;; The drawing records, parsed back (for the character sketch and tests)
;;; ------------------------------------------------------------------

(define (drawing-records lines)
  "Each line split into (tag . fields)."
  (map (lambda (l) (string-split l " ")) lines))

(define (record-numbers rec from) (map string->number (list-tail rec from)))

;;; ------------------------------------------------------------------
;;; The character sketch: no display, or no irene-dixe
;;; ------------------------------------------------------------------

(define (text-plot lines (width 64) (height 18))
  "A rough sketch in characters: each curve drawn with its own letter."
  (let* ((recs (drawing-records lines))
         (find-rec (lambda (tag) (find (lambda (r) (string=? (car r) tag)) recs)))
         (xa (find-rec "xaxis")) (ya (find-rec "yaxis"))
         (x0 (string->number (cadr xa))) (x1 (string->number (caddr xa)))
         (y0 (string->number (cadr ya))) (y1 (string->number (caddr ya)))
         (grid (list->vector (map (lambda (i) (make-vector width #\space)) (iota height))))
         (col (lambda (x) (max 0 (min (- width 1) (exact (round (* (- width 1) (/ (- x x0) (if (= x1 x0) 1 (- x1 x0))))))))))
         (row (lambda (y) (max 0 (min (- height 1) (exact (round (* (- height 1) (/ (- y1 y) (if (= y1 y0) 1 (- y1 y0))))))))))
         (put (lambda (r c ch) (vector-set! (vector-ref grid r) c ch)))
         (mark (lambda (i) (integer->char (+ 65 (modulo i 26))))))
    (for-each
     (lambda (r)
       (cond ((string=? (car r) "seg")
              (let* ((v (record-numbers r 1)) (ch (mark (car v)))
                     (c1 (col (cadr v))) (r1 (row (caddr v))) (c2 (col (cadddr v))) (r2 (row (car (cddddr v)))))
                (if (= r1 r2)
                    (do ((c (min c1 c2) (+ c 1))) ((> c (max c1 c2))) (put r1 c ch))
                    (do ((k (min r1 r2) (+ k 1))) ((> k (max r1 r2))) (put k c1 ch)))))
             ((string=? (car r) "link")      ; dotted join: lower-case letters
              (let* ((v (record-numbers r 1)) (ch (char-downcase (mark (car v))))
                     (c1 (col (cadr v))) (r1 (row (caddr v))) (c2 (col (cadddr v))) (r2 (row (car (cddddr v))))
                     (n (max 1 (abs (- c2 c1)) (abs (- r2 r1)))))
                (do ((k 0 (+ k 1))) ((> k n))
                  (put (exact (round (+ r1 (* k (/ (- r2 r1) n))))) (exact (round (+ c1 (* k (/ (- c2 c1) n))))) ch))))
             ((string=? (car r) "point")     ; a sampled landmark: its letter
              (let ((v (record-numbers r 1))) (put (row (caddr v)) (col (cadr v)) (mark (car v)))))
             ((string=? (car r) "censor")
              (let ((v (record-numbers r 1))) (put (row (caddr v)) (col (cadr v)) #\+)))))
     recs)
    (let* ((label-width 7)
           (tick-rows (map (lambda (t) (cons (row t) (fmt-num t)))
                           (record-numbers (find-rec "yticks") 1)))
           (ylabel (lambda (k) (let ((e (assv k tick-rows)))
                                 (if e
                                     (string-append (make-spaces (- label-width 1 (length (cdr e)))) (cdr e) " ")
                                     (make-spaces label-width)))))
           (body (map (lambda (k) (string-append (ylabel k) "|" (list->string (vector->list (vector-ref grid k)))))
                      (iota height)))
           (axis (string-append (make-spaces label-width) "+" (make-string width #\-)))
           (xlabels (let* ((a (fmt-num x0)) (b (fmt-num x1)))
                      (string-append (make-spaces (+ label-width 1)) a
                                     (make-spaces (- width (length a) (length b))) b)))
           (title (find-rec "title"))
           (legend (filter-map (lambda (r)
                                 (and (string=? (car r) "series")
                                      (concat "  " (string (mark (string->number (cadr r)))) " = "
                                              (string-join (list-tail r 6) " "))))
                               recs))
           (extra (filter-map (lambda (r)
                                (cond ((string=? (car r) "gap")
                                       (concat "  unresolved, curve " (string (mark (string->number (cadr r))))
                                               ", " (fmt-num (string->number (caddr r))) " to "
                                               (fmt-num (string->number (cadddr r))) ": "
                                               (string-join (list-tail r 4) " ")))
                                      ((member (car r) '("stat" "note"))
                                       (concat "  " (string-join (cdr r) " ")))
                                      (else #f)))
                              recs)))
      (string-join (append (list (string-join (cdr title) " ") "")
                           body (list axis xlabels
                                      (concat (make-spaces (+ label-width 1)) (string-join (cdddr xa) " "))
                                      "" "Curves (+ = censored; lower case = shape unknown between sampled points):")
                           legend
                           (if (pair? extra) (cons "" extra) '())
                           (list "" "A rough sketch: install irene-dixe (make) and use a display for the real plot."))
                   "\n"))))

;;; ------------------------------------------------------------------
;;; Running irene-dixe
;;; ------------------------------------------------------------------

(define (sketch-viewer-path)
  (let ((p (string-append *install-dir* "/" *sketch-viewer-name*)))
    (and (file-executable? p) p)))

(define (display-available?)
  "Can a window be opened?  macOS: yes unless over ssh; elsewhere: X or Wayland."
  (let ((set? (lambda (name) (let ((v (os.getenv name))) (and (string? v) (> (length v) 0))))))
    (if (string=? (os-name) "darwin")
        (not (set? "SSH_CONNECTION"))
        (or (set? "DISPLAY") (set? "WAYLAND_DISPLAY")))))

(define (write-lines-file path lines)
  (let ((f (file path :write :create :truncate)))
    (for-each (lambda (l) (io.write f l) (io.write f "\n")) lines)
    (io.close f)
    path))

(define *sketch-sequence* 0)

(define (picture-path)
  "Where the picture is saved: beside this buffer's file (paper.md ->
paper-plot-1.png, then -plot-2 ...), or in the home folder."
  ;; The buffer may name its file relative to where the editor started
  ;; ("paper.md", "NAIA-tst/paper.md"): make it absolute first, or a name
  ;; without a slash would send the picture to the home folder.
  (let* ((name (buffer-filename))
         (file (and name (or (real-path name)
                             (if (string-prefix? "/" name) name (concat (real-path ".") "/" name)))))
         (slash (and file (string-search-back "/" file)))
         (dir (if slash (string.sub file 0 slash) (home-directory)))
         (name (if file (string.sub file (if slash (+ slash 1) 0) (length file)) "schememax"))
         (dot (string-search-back "." name))
         (base (if (and dot (> dot 0)) (string.sub name 0 dot) name)))
    ;; the first number not taken, so earlier pictures are never overwritten
    (let loop ((n 1))
      (let ((path (concat dir "/" base "-plot-" n ".png")))
        (if (file-attributes path) (loop (+ n 1)) path)))))

(define (show-text-plot lines why)
  (let ((text (text-plot lines)))
    (delete-other-windows)
    (split-window)
    (other-window)
    (select-buffer *plot-buffer*)
    (erase-buffer)
    (insert text)
    (goto-char 0)
    (fe-set-modified 0)
    (message why)))

(define (draw-sketch lines)
  (let ((viewer (sketch-viewer-path)))
    (cond ((not viewer)
           (show-text-plot lines "irene-dixe is not installed: a character sketch instead (run make)"))
          ((not (display-available?))
           (show-text-plot lines "No display here: a character sketch instead"))
          (else
           (set! *sketch-sequence* (+ *sketch-sequence* 1))
           (let ((path (write-lines-file (concat "/tmp/schememax-plot-" (getpid) "-" *sketch-sequence* ".txt") lines)))
             (let* ((save (picture-path))
                    (result (spawn-program viewer (list path save))))
               (if (eq? result #t)
                   (message "Plot window opened. In it, s saves the picture as " save)
                   (show-text-plot lines (concat "irene-dixe did not start (" (->string result) "): a character sketch instead")))))))))

(define (plot-lines-at-point)
  "The drawing records of the plot table at the cursor, or #f after saying why."
  (let* ((text (buffer-string))
         (span (form-at text (point))))
    (if (not span)
        (begin (message "No plot table here: put the cursor inside an (estimator-plot ...) table") #f)
        (guard (e (#t (message (describe-error e)) #f))
          (let* ((form (read-sketch-form (string.sub text (car span) (cdr span))))
                 (head (and (pair? form) (car form))))
            (cond ((eq? head 'estimator-plot) (km-drawing form))
                  ((eq? head 'image) (message "Sketches of diagnostic images (image ...) are not drawn yet") #f)
                  (else (message "Not a plot table: " (->string head)) #f)))))))

(defcommand (plot-at-point)
  "C-c p: draw the plot table (estimator-plot ...) at or after the cursor."
  (let ((lines (plot-lines-at-point)))
    (when lines (draw-sketch lines))))

(defcommand (plot-save)
  "Save the plot table at the cursor as a picture beside this file, without a window."
  (let ((lines (plot-lines-at-point))
        (viewer (sketch-viewer-path)))
    (cond ((not lines) #f)
          ((not viewer) (message "irene-dixe is not installed (run make)"))
          (else
           (set! *sketch-sequence* (+ *sketch-sequence* 1))
           (let* ((table (write-lines-file (concat "/tmp/schememax-plot-" (getpid) "-" *sketch-sequence* ".txt") lines))
                  (out (picture-path))
                  (result (run-program viewer (list "--render" table out) #f 30 #f))
                  (info (file-attributes out)))
             (if (and info (> (cadr info) 54))
                 (message "Saved " out)
                 (message "Could not save " out ": " (trim (cadr result)))))))))

(defcommand (irene-dixe)
  "Another name for plot-at-point (C-c p)."
  (plot-at-point))

(global-set-key "C-c p" 'plot-at-point)
