;;; RASP/PROB - patch2-c2s.lsp -- c2s-cover constraints for grammar checking
;;;
;;; Loaded at run time by scripts/rasp_parse.sh, after the parser image.
;;; RASP's grammar sees part-of-speech tags, not words, so it cannot reject
;;; "for for" or "an" read as a proper noun.  The constraints below look at
;;; the words.  A sentence that violates one gets no full parse: the parser
;;; reports its partial analysis instead (0 parses), as for any other
;;; sentence outside the grammar.  Claude, 2026-10-13.

(in-package #+(or cltl2 x3j13 ansi-cl) common-lisp-user #-(or cltl2 x3j13 ansi-cl) 'user)

(declaim (optimize (safety 3) (debug 2)))

(defparameter +c2s-never-doubled+
  '("a" "an" "the" "of" "for" "to" "into" "onto" "from" "with" "without"
    "than" "at" "among" "alongside" "between" "within" "upon" "during"
    "towards" "toward" "and" "or" "nor" "its" "their" "our" "my" "your")
  "Words that are never correct twice in a row.  Words that can end a
phrasal verb (in, on, up, over, by ...) and words with legitimate doubles
(that that, had had) are deliberately absent.")

(defparameter +c2s-not-names+
  '("a" "an" "the" "of" "for" "to" "in" "on" "at" "by" "with" "and" "or")
  "Lowercase function words that must not be read as proper nouns.")

(defvar *c2s-reject-reason* nil
  "Why the current sentence may not have a full parse, or NIL.")

(declaim (ftype (function (t) simple-string) c2s-word-form))
(defun c2s-word-form (token)
  "Lowercase surface form of TOKEN.  With several tags per word a token is
(SURFACE (TAGGED . SCORE) ...); with one tag it is the symbol LEMMA:N_TAG."
  (let* ((name (string (if (consp token) (car token) token)))
         (end (if (consp token) (length name) (or (position #\: name) (length name)))))
    (coerce (string-downcase (subseq name 0 end)) 'simple-string)))

(declaim (ftype (function (t) list) c2s-token-tags))
(defun c2s-token-tags (token)
  "The tag strings offered for TOKEN, e.g. (\"NP1\" \"AT1\")."
  (flet ((tag-of (sym)
           (let ((s (string sym)))
             (subseq s (1+ (or (position #\_ s :from-end t) -1))))))
    (if (consp token)
        (mapcar (lambda (alt) (tag-of (car alt))) (cdr token))
        (list (tag-of token)))))

(declaim (ftype (function (list) (or null string)) c2s-violation))
(defun c2s-violation (words)
  "A short description of the first constraint WORDS violate, or NIL."
  (flet ((lowercase-p (token)
           (let ((s (string (if (consp token) (car token) token))))
             (and (plusp (length s)) (lower-case-p (char s 0))))))
    (or
     ;; the same function word twice in a row: "for for", "a a"
     (loop for (w1 w2) on words
           for f1 = (c2s-word-form w1)
           while w2
           when (and (string= f1 (c2s-word-form w2))
                     (member f1 +c2s-never-doubled+ :test #'string=))
             do (return (format nil "doubled word ~S" f1)))
     ;; a lowercase function word that the tagger could only read as a name,
     ;; as "an" in "an of antigen presentation"
     (loop for token in words
           when (and (consp token)
                     (lowercase-p token)
                     (member (c2s-word-form token) +c2s-not-names+ :test #'string=)
                     (every (lambda (tag) (member tag '("NP1" "NP2") :test #'string=))
                            (c2s-token-tags token)))
             do (return (format nil "function word ~S read as a name"
                                (c2s-word-form token)))))))

(declaim (ftype (function (list) list) c2s-drop-name-readings))
(defun c2s-drop-name-readings (words)
  "Remove proper-noun readings (NP1, NP2) of lowercase function words such
as \"an\", which the tagger can look up capitalised.  Only tokens with
several readings are changed."
  (mapcar
   (lambda (token)
     (if (and (consp token)
              (cddr token)              ; more than one reading
              (let ((s (string (car token))))
                (and (plusp (length s)) (lower-case-p (char s 0))))
              (member (c2s-word-form token) +c2s-not-names+ :test #'string=))
         (let ((kept (remove-if (lambda (alt)
                                  (member (car (c2s-token-tags (list nil alt)))
                                          '("NP1" "NP2") :test #'string=))
                                (cdr token))))
           (if kept (cons (car token) kept) token))
         token))
   words))

(let ((original-parse (symbol-function 'lr1-parse))
      (original-parse-1 (symbol-function 'lr1-parse-1)))
  (declare (type function original-parse original-parse-1))
  (setf (symbol-function 'lr1-parse)
        (lambda (words)
          (let* ((words (c2s-drop-name-readings words))
                 (*c2s-reject-reason* (c2s-violation words)))
            (funcall original-parse words))))
  (setf (symbol-function 'lr1-parse-1)
        (lambda (&rest args)
          (multiple-value-prog1 (apply original-parse-1 args)
            (when (and *c2s-reject-reason* *accepted-vertex-analyses*)
              (setq *accepted-vertex-analyses* nil))))))

;;; End of file
