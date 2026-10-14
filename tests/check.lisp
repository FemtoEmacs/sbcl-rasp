;;;; check.lisp -- the regression check of sbcl-rasp.
;;;;
;;;; Run from the top directory, after make:   sbcl --script tests/check.lisp
;;;; (or simply: make check).  It runs three tests:
;;;;
;;;;  1. every sentence of codex-correct.txt and constructed-correct.txt must
;;;;     get a full parse from scripts/rasp.sh;
;;;;  2. every sentence of known-bad.txt must be rejected (0 parses), except
;;;;     those listed in known-bad-open.txt, which are known open problems;
;;;;  3. the parser alone, on the 560 DepBank sentences, must give exactly the
;;;;     analyses stored in parc560-not-ne-ccl-t0.out (made by the original
;;;;     RASP 3.3a), apart from how each Lisp escapes symbol names.
;;;;
;;;; The exit code is 0 when all pass, 1 otherwise.

(defpackage #:rasp-check (:use #:common-lisp))
(in-package #:rasp-check)

(declaim (optimize (safety 3) (debug 2) (speed 0)))

(defparameter *root*
  (truename (merge-pathnames "../" (make-pathname :name nil :type nil
                                                  :defaults *load-truename*)))
  "The top directory of sbcl-rasp.")

(defparameter *jobs* 8 "How many RASP processes run at once.")

(declaim (ftype (function (string) pathname) path))
(defun path (relative)
  (merge-pathnames relative *root*))

(declaim (ftype (function () list) environment))
(defun environment ()
  (cons "RASP_LISP=sbcl" (sb-ext:posix-environ)))

;;; Reading the test files: one "id<TAB>sentence" per line.

(declaim (ftype (function (string) list) read-cases))
(defun read-cases (name)
  (with-open-file (in (path (concatenate 'string "tests/" name)) :external-format :utf-8)
    (loop for line = (read-line in nil nil)
          while line
          for tab = (position #\Tab line)
          when tab collect (cons (subseq line 0 tab) (subseq line (1+ tab))))))

(declaim (ftype (function (string) list) read-ids))
(defun read-ids (name)
  (let ((file (path (concatenate 'string "tests/" name))))
    (when (probe-file file)
      (with-open-file (in file)
        (loop for line = (read-line in nil nil)
              while line
              for id = (string-trim '(#\Space #\Tab) line)
              when (and (plusp (length id)) (char/= (char id 0) #\;)) collect id)))))

;;; Running RASP on one sentence.  Its first output line for each sentence
;;; is "(words ...) N ; (scores)"; the sentence has a full parse when RASP
;;; sees exactly one sentence and N > 0.

(declaim (ftype (function (string) (or null integer)) parse-count))
(defun parse-count (line)
  "N in a line \"(...) N ; (...)\", or NIL for any other line."
  (let ((semi (search " ; " line)))
    (when (and semi (plusp (length line)) (char= (char line 0) #\())
      (let ((space (position #\Space line :end semi :from-end t)))
        (when space
          (parse-integer line :start (1+ space) :end semi :junk-allowed t))))))

(declaim (ftype (function (string) t) start-rasp))
(defun start-rasp (sentence)
  (let ((process (sb-ext:run-program "/bin/sh"
                                     (list (namestring (path "scripts/rasp.sh"))
                                           "-p" "-n 1 -t 20")
                                     :input :stream :output :stream :error nil
                                     :wait nil :environment (environment)
                                     :external-format :utf-8)))
    (let ((in (sb-ext:process-input process)))
      (write-line sentence in)
      (close in))
    process))

(declaim (ftype (function (t) boolean) finish-rasp))
(defun finish-rasp (process)
  "Wait for PROCESS; true when its output shows one sentence with a full parse."
  (let ((counts (with-open-stream (out (sb-ext:process-output process))
                  (loop for line = (read-line out nil nil)
                        while line
                        for n = (parse-count line)
                        when n collect n))))
    (sb-ext:process-wait process)
    (sb-ext:process-close process)
    (and (= (length counts) 1) (plusp (first counts)))))

(declaim (ftype (function (list) list) parse-all))
(defun parse-all (cases)
  "For each (id . sentence) of CASES, whether RASP gives a full parse,
running *JOBS* processes at a time."
  (let ((results '()))
    (loop while cases
          do (let ((batch (loop repeat *jobs* while cases collect (pop cases))))
               (let ((processes (mapcar (lambda (c) (start-rasp (cdr c))) batch)))
                 (loop for c in batch
                       for p in processes
                       do (push (cons (car c) (finish-rasp p)) results)))))
    (nreverse results)))

;;; Test 3: comparing parser outputs.  CCL writes a symbol as 473\:5_MC,
;;; SBCL as |473:5_MC|; both are reduced to the name between bars.

;;; One token of TEXT starts at START.  Returns its end and, when it was
;;; escaped with bars or backslashes, its name.
(declaim (ftype (function (string fixnum) (values fixnum (or null string))) read-token))
(defun read-token (text start)
  (let ((n (length text)) (j start) (escaped nil)
        (name (make-string-output-stream)))
    (declare (type fixnum n j))
    (flet ((delimiter-p (ch) (find ch '(#\Space #\Tab #\Newline #\( #\)))))
      (loop while (and (< j n) (not (delimiter-p (char text j))))
            do (let ((ch (char text j)))
                 (cond ((and (char= ch #\\) (< (1+ j) n))
                        (write-char (char text (1+ j)) name)
                        (incf j 2)
                        (setf escaped t))
                       ((char= ch #\|)
                        (setf escaped t)
                        (incf j)
                        (loop while (and (< j n) (char/= (char text j) #\|))
                              do (cond ((and (char= (char text j) #\\) (< (1+ j) n))
                                        (write-char (char text (1+ j)) name)
                                        (incf j 2))
                                       (t
                                        (write-char (char text j) name)
                                        (incf j))))
                        (incf j))
                       (t
                        (write-char ch name)
                        (incf j))))))
    (values (min j n) (and escaped (get-output-stream-string name)))))

(declaim (ftype (function (string) string) canonical))
(defun canonical (text)
  "TEXT with every escaped symbol written as |name|."
  (with-output-to-string (out)
    (let ((i 0) (n (length text)))
      (declare (type fixnum i n))
      (loop while (< i n)
            do (let ((c (char text i)))
                 (cond ((find c '(#\Space #\Tab #\Newline #\( #\) #\"))
                        (write-char c out)
                        (incf i))
                       (t
                        (multiple-value-bind (end name) (read-token text i)
                          (if name
                              (format out "|~A|" name)
                              (write-string text out :start i :end end))
                          (setf i end)))))))))

(declaim (ftype (function (pathname) list) file-lines))
(defun file-lines (file)
  (with-open-file (in file :external-format :latin-1)
    (let ((text (make-string (file-length in))))
      (let ((end (read-sequence text in)))
        (with-input-from-string (s (canonical (subseq text 0 end)))
          (loop for line = (read-line s nil nil) while line collect line))))))

(declaim (ftype (function () boolean) depbank-identical-p))
(defun depbank-identical-p ()
  (let ((output (path "bin/depbank-check.out")))
    (sb-ext:run-program "/bin/sh"
                        (list (namestring (path "scripts/rasp_parse.sh")) "-t0")
                        :input (path "prob/greval/DepBank/parc560/test.not-ne.stag.data")
                        :output output :if-output-exists :supersede
                        :error nil :environment (environment))
    (let* ((expected (file-lines (path "tests/parc560-not-ne-ccl-t0.out")))
           (got (file-lines output))
           (differing (loop for a in expected for b in got
                            for k from 1
                            unless (string= a b) collect k)))
      (format t "DepBank, parser only: ~D vs ~D lines, ~D differing~@[ (first: line ~D)~]~%"
              (length expected) (length got) (length differing) (first differing))
      (and (null differing) (= (length expected) (length got))))))

;;; Main

(declaim (ftype (function (string boolean list &optional list) boolean) report))
(defun report (name want results &optional open)
  "Print how many of RESULTS (id . parsed-p) came out as WANT; true when all
did, apart from the ids in OPEN."
  (let* ((unexpected (loop for (id . parsed) in results
                           unless (eq parsed want) collect id))
         (failures (set-difference unexpected open :test #'string=)))
    (format t "~A: ~D/~D as expected~@[; open: ~{~A~^ ~}~]~@[; FAILED: ~{~A~^ ~}~]~%"
            name (- (length results) (length unexpected)) (length results)
            (intersection unexpected open :test #'string=) failures)
    (null failures)))

(let* ((ok-1 (report "codex-correct" t (parse-all (read-cases "codex-correct.txt"))))
       (ok-2 (report "constructed-correct" t (parse-all (read-cases "constructed-correct.txt"))))
       (ok-3 (report "known-bad" nil (parse-all (read-cases "known-bad.txt"))
                     (read-ids "known-bad-open.txt")))
       (ok-4 (depbank-identical-p)))
  (finish-output)
  (sb-ext:exit :code (if (and ok-1 ok-2 ok-3 ok-4) 0 1)))
