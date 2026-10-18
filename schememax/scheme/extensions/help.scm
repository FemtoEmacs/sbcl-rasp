;;;; help.scm -- the keys, one page
;;;;
;;;; Port of SBEmacs's lisp/extensions/help.lisp.  Edit the entries below and
;;;; press C-x C-r; no rebuild.
;;;;
;;;; C-h or F1 shows this page ([?] on the mode line offers it, ChatGPT and
;;;; Claude: menu.scm).  The arrows (or C-n and C-p) scroll it; C-c r
;;;; and C-c g ask Claude or ChatGPT (Codex); any other key goes back to the
;;;; file, closing the assistants' windows.

(define *help-buffer* "*schememax-help*")

;; The help page's mode line has [CLOSE] instead of [?] (menu.scm): help
;; from help would only reopen the page that is already shown.
(define *help-close-requested* #f)

(defcommand (help-close)
  "[CLOSE] on the help page: back to the file."
  (set! *help-close-requested* #t))

(define *help-header*
  "Arrows or Ctrl-n and Ctrl-p to scroll down and up.
Ctrl-c r (hold down the Ctrl key and press c; release and press r) to ask
help from Claude.  Ctrl-c g to ask help from ChatGPT.  You must subscribe
to ask help from them.  Any other key, leave this page and return to the
file you are editing.")

(define *help-notation*
  "C-x means Ctrl-x.  M-x means Esc, then x (or Alt-x; Option-x on a Mac).")

;;; One key per line: (key description).  Keys in Emacs notation.
(define *help-sections*
  '(("Help and assistants"
     ("C-h" "this page (also F1)")
     ("C-x ?" "what does a key do?")
     ("M-x" "run a command by name (TAB completes)")
     ("C-c r" "Claude: a menu for hints, a question or a discussion")
     ("C-c y" "insert the code of the last answer; closes its window")
     ("C-c t" "in the discussion: insert the snippet under the cursor")
     ("C-c g" "write a request for ChatGPT (Codex); C-c g again sends it")
     ("C-c f" "textify a PDF into Markdown, with ChatGPT or Claude")
     ("C-c p" "plot: draw the Kaplan-Meier table at the cursor"))
    ("Files"
     ("C-x C-f" "open a file")
     ("C-x C-s" "save")
     ("C-x C-w" "save as")
     ("C-x s" "save every modified file, asking")
     ("C-x i" "insert a file at the cursor")
     ("C-x C-v" "open another file in place of this one")
     ("C-x d" "list a directory")
     ("C-x C-c" "quit"))
    ("Moving"
     ("C-f" "forward one character (also the right arrow)")
     ("C-b" "back one character (also the left arrow)")
     ("C-n" "next line (also the down arrow)")
     ("C-p" "previous line (also the up arrow)")
     ("M-f" "forward one word")
     ("M-b" "back one word")
     ("C-a" "beginning of the line")
     ("C-e" "end of the line")
     ("M-m" "first non-blank character of the line")
     ("M-a" "back to the start of the sentence")
     ("M-e" "forward to the end of the sentence")
     ("M-{" "back one paragraph")
     ("M-}" "forward one paragraph")
     ("C-v" "next screen")
     ("M-v" "previous screen")
     ("M-<" "beginning of the file")
     ("M->" "end of the file")
     ("M-g" "go to a line number")
     ("C-l" "put the cursor's line in the middle of the window")
     ("C-M-f" "forward over an expression (Lisp: an s-expression)")
     ("C-M-b" "back over an expression")
     ("C-M-u" "out to the enclosing parenthesis")
     ("C-M-d" "into the next parenthesis")
     ("C-M-a" "beginning of the definition (defun, function)")
     ("C-M-e" "end of the definition"))
    ("Selecting (the region is shaded)"
     ("C-SPC" "set the mark: the region runs from it to the cursor")
     ("mouse" "click to move the cursor or choose a window; drag to select")
     ("[SAVE] ..." "the buttons of the mode line do what their keys do")
     ("file name" "click it on the mode line: lines, words, size, full name")
     ("C-x h" "select the whole file")
     ("M-h" "select the paragraph")
     ("M-@" "select to the end of the word")
     ("C-M-SPC" "select to the end of the expression")
     ("C-x C-x" "swap the cursor and the mark")
     ("C-g" "unselect; cancel a command"))
    ("Killing (cutting) and yanking (pasting)"
     ("C-w" "kill the region")
     ("M-w" "copy the region")
     ("C-y" "yank the last kill")
     ("M-y" "right after C-y: replace it with the kill before")
     ("C-k" "kill to the end of the line (again: joins the kills)")
     ("M-d" "kill the next word")
     ("M-DEL" "kill the previous word")
     ("M-k" "kill to the end of the sentence")
     ("C-M-k" "kill the next expression")
     ("M-z" "kill up to and including a character")
     ("C-d" "delete the character under the cursor")
     ("DEL" "delete the character before the cursor (Backspace)")
     ("C-c i" "choose a kill to insert")
     ("C-c k" "browse the kill ring"))
    ("Changing text"
     ("C-/" "undo the last command; again: the one before (also C-x u, C-u)")
     ("C-M-_" "redo what undo took back (also M-_)")
     ("C-t" "swap the two characters at the cursor")
     ("M-t" "swap two words")
     ("C-x C-t" "swap this line with the one above")
     ("M-u" "upper-case the next word")
     ("M-l" "lower-case the next word")
     ("M-c" "capitalize the next word")
     ("C-x C-u" "upper-case the region")
     ("C-x C-l" "lower-case the region")
     ("C-o" "open a line after the cursor")
     ("C-j" "new line, indented")
     ("TAB" "indent the line (again: other levels, in Python)")
     ("C-x TAB" "indent the region (also C-M-\\)")
     ("C-x >" "insert two spaces")
     ("C-x <" "delete two characters back")
     ("M-^" "join this line to the previous one")
     ("M-\\" "delete the spaces around the cursor")
     ("M-SPC" "leave just one space")
     ("C-x C-o" "delete blank lines")
     ("M-q" "refill the paragraph or comment")
     ("C-c w" "word wrap on or off for this file (also MORE > Word wrap)")
     ("M-;" "comment: add one, or (un)comment the region")
     ("C-q" "insert the next key as it is (C-q TAB: a tab)")
     ("INS" "overwrite mode on or off"))
    ("Searching and replacing"
     ("C-s" "search forward (C-s again: next match)")
     ("C-r" "search backward")
     ("M-%" "replace, asking each time (also M-r)")
     ("C-x C-g" "grep: search files")
     ("C-x !" "next grep match"))
    ("Buffers and windows"
     ("C-x b" "switch to a buffer by name")
     ("C-x C-b" "buffer menu")
     ("C-x n" "next buffer")
     ("C-x k" "close a buffer")
     ("C-x 2" "split the window")
     ("C-x o" "go to the other window (or click it)")
     ("C-x 0" "close this window")
     ("C-x 1" "close the other windows")
     ("C-x ^" "make this window taller"))
    ("Keyboard macros"
     ("C-x (" "start recording keys")
     ("C-x )" "stop recording")
     ("C-x e" "replay them; then e replays again"))
    ("Scheme"
     ("C-x C-e" "evaluate the expression before the cursor")
     ("C-M-x" "evaluate the top-level form around the cursor")
     ("M-:" "evaluate an expression typed at the bottom")
     ("M-]" "evaluate the block and insert the value")
     ("M-!" "a window for a shell command (Enter: more lines)")
     ("C-c s" "in that window: run the command; its output follows it")
     ("C-x C-r" "reload the Scheme scripts (no rebuild needed)"))))

;;; Commands with no key of their own: type M-x and the name (TAB completes).
(define *help-commands*
  '(("M-x commands (M-x, then the name; TAB completes)")
    ("toggle-word-wrap" "word wrap on or off for this file (also C-c w)")
    ("visual-line-mode" "the same, by its Emacs name")
    ("fill-paragraph" "refill the paragraph or comment (also M-q)")
    ("indent-buffer" "indent the whole file")
    ("indent-region" "indent the region (also C-x TAB)")
    ("python-mode" "Python colours, indentation and menu")
    ("nim-mode" "Nim colours, indentation and menu")
    ("reload-mode" "reload the active modes from their files")
    ("dark-theme" "the dark palette (yellow cursor)")
    ("light-theme" "the light palette (blue cursor)")
    ("file-info" "lines, words, size and full name of this file")
    ("buffer-menu" "the list of buffers (also C-x C-b)")
    ("save-some-buffers" "save every modified file, asking (also C-x s)")
    ("undo-status" "how much undo history this buffer has")
    ("ai-help" "what Claude and ChatGPT (Codex) can do here")
    ("assistant-status" "how the assistant reaches Claude")
    ("codex-status" "how the assistant reaches ChatGPT (Codex)")
    ("describe-key" "what does a key do? (also C-x ?)")
    ("plot-at-point" "draw the plot table at the cursor (also C-c p)")
    ("plot-save" "save the plot table at the cursor as a picture, no window")))

(define (help-documented-keys)
  (apply append (map (lambda (section) (map (lambda (e) (normalize-key (car e))) (cdr section)))
                     *help-sections*)))

(define (help-other-keys)
  "Bindings the sections do not mention (yours, say)."
  (let ((documented (help-documented-keys)))
    (sort (table.foldl (lambda (key fn acc)
                         (if (or (member key documented) (string-search "esc [" key))
                             acc
                             (cons (list (display-key key) (command-name fn)) acc)))
                       '() *keymap*)
          (lambda (a b) (string<? (car a) (car b))))))

(define (help-commands-text)
  "The M-x section: the names are longer than keys, so they get a wider column."
  (let* ((entries (filter (lambda (e) (command-procedure (string->symbol (car e))))
                          (cdr *help-commands*)))
         (width (apply max 11 (map (lambda (e) (length (car e))) entries))))
    (apply string-append "\n" (caar *help-commands*) "\n"
           (map (lambda (e) (string-append "  " (pad-right (car e) width) " " (cadr e) "\n"))
                entries))))

(define (help-text)
  (let ((section (lambda (title entries)
                   (apply string-append "\n" title "\n"
                          (map (lambda (e) (string-append "  " (pad-right (car e) 11) " " (cadr e) "\n"))
                               entries)))))
    (string-append *help-header* "\n\n" *help-notation* "\n"
                   (apply string-append (map (lambda (s) (section (car s) (cdr s))) *help-sections*))
                   (help-commands-text)
                   (let ((others (help-other-keys)))
                     (if (pair? others) (section "Other keys" others) "")))))

(define (help-scroll top delta lines rows)
  "The new first line when scrolling by DELTA."
  (max 1 (min (+ top delta) (max 1 (+ (- lines rows) 1)))))

(define (show-help-line line)
  (goto-line line)
  (beginning-of-line)
  (set-window-start (point)))

(defcommand (help)
  "The keys, on a page of their own."
  (let* ((origin (get-buffer-name))
         (from (if (assistant-buffer-p origin) (file-behind-assistant) origin))
         (opoint (point))
         (text (help-text))
         (lines (+ 1 (count-byte text 10)))
         (top 1)
         (action #f))
    (set! *help-in-progress* #t)
    (set! *help-pending-menu-action* #f)
    (set! *help-close-requested* #f)
    (select-buffer *help-buffer*)
    (erase-buffer)
    (insert text)
    (fe-set-modified 0)
    (show-help-line 1)
    (dynamic-wind
     (lambda () #f)
     (lambda ()
       (let loop ()
         (message "Help: arrows scroll; C-c r Claude, C-c g ChatGPT; any other key returns to " from)
         (update-display)
         (let* ((k (get-key))
                (name (if (string=? k "") (get-key-name) k))
                (rows (max 1 (window-rows)))
                (continue
                 (cond ((string=? (get-key-binding) "mouse")
                        (fe-mouse-event)
                        (cond (*help-close-requested* (set! *help-close-requested* #f) #f)
                              (*help-pending-menu-action*
                               (set! action *help-pending-menu-action*) #f)
                              (else #t)))
                       ((member name '("down" "C-n")) (set! top (help-scroll top 1 lines rows)) #t)
                       ((member name '("up" "C-p")) (set! top (help-scroll top -1 lines rows)) #t)
                       ((member name '("PgDn" "C-v")) (set! top (help-scroll top (max 1 (- rows 2)) lines rows)) #t)
                       ((member name '("PgUp" "esc v" "esc V")) (set! top (help-scroll top (- (max 1 (- rows 2))) lines rows)) #t)
                       ;; C-h b is the Emacs way to this page: stay
                       ((and (string=? name "b") (= top 1)) #t)
                       ((string=? name "C-c r") (set! action 'ask-claude) #f)
                       ((string=? name "C-c g") (set! action 'ask-codex) #f)
                       (else #f))))
           (when continue (show-help-line top) (loop)))))
     (lambda ()
       ;; however we leave: the file again, the assistants' windows closed
       (set! *help-in-progress* #f)
       (select-buffer origin)
       (goto-char opoint)
       (close-assistant-windows)
       (when (string=? (get-buffer-name) *help-buffer*) (select-buffer from))
       (kill-buffer *help-buffer*)
       (clear-message-line)))
    (when action (run-mode-line-action action))
    #t))

(set-buffer-hint *help-buffer* "arrows scroll; other keys: back")

(global-set-key "C-h" 'help)
(global-set-key "F1" 'help)
(global-set-key "C-x C-h" 'help)
