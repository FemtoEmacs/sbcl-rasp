;;;; ttfy.scm -- C-c f: textify a PDF into Markdown, with ChatGPT or Claude
;;;;
;;;; Schememax's own extension (not in SBEmacs).  C-c f (or TTFY in the
;;;; [MORE] window) offers 1 ChatGPT or 2 Claude, then asks for the PDF and
;;;; the pages (all, N or N-M).  The pages are rendered as images in C
;;;; (src/pdf-pages.c) and sent with the guidelines of
;;;; ttfy/plots-guidelines.md; the Markdown answer opens in a new buffer
;;;; for review (C-x C-s saves it).  Failures are shown in *ttfy-errors*.

(define *ttfy-errors-buffer* "*ttfy-errors*")
(defvar *ttfy-sequence* 0)

(define (ttfy-read-guidelines)
  (or (file-contents (string-append *install-dir* "/ttfy/plots-guidelines.md")) ""))

(define (ttfy-failed? text)
  (or (string-prefix? "Assistant failed" text)
      (string-prefix? "TTFY failed" text)
      (string=? (trim text) "")))

(define (ttfy-error-text e) (describe-error e))

(define (ttfy-choice-provider choice) (if (= choice 1) "codex" "claude"))

(define (ttfy-show-errors text)
  (show-in-assistant-window "Textify failed" text)
  (set-buffer-hint *assistant-buffer* "C-x 1 close")
  (message "Textify failed; see the window below"))

(define (ttfy-convert provider path range)
  (message "Textifying PDF with " (if (string=? provider "codex") "ChatGPT" "Claude") "; please wait...")
  (update-display)
  (let ((text (guard (e (#t (string-append "TTFY failed: " (ttfy-error-text e))))
                (ttfy-request provider path range (ttfy-read-guidelines)))))
    (if (ttfy-failed? text)
        (ttfy-show-errors text)
        (begin
          (set! *ttfy-sequence* (+ *ttfy-sequence* 1))
          (delete-other-windows)
          (split-window)
          (other-window)
          (select-buffer (concat "*ttfy-" *ttfy-sequence* ".md*"))
          (erase-buffer)
          (insert "<!-- TTFY provider: " (if (string=? provider "codex") "ChatGPT" "Claude")
                  "; review plot estimates before reuse. -->\n\n" text)
          (goto-char 0)
          (message "Textify complete. Review/edit Markdown; C-x C-w saves it.")))))

(defcommand (ttfy-menu)
  "C-c f: textify a PDF into Markdown with ChatGPT or Claude."
  (let ((saved (list *more-menu-buffer* *menu-title* *menu-number-keys*)))
    (set! *more-menu-buffer* "*ttfy-menu*")
    (set! *menu-title* "Textify PDF")
    (set! *menu-number-keys* #t)
    (let ((choice (dynamic-wind (lambda () #f)
                                (lambda () (choose-menu '(("Textify with ChatGPT" "1") ("Textify with Claude" "2"))))
                                (lambda ()
                                  (set! *more-menu-buffer* (car saved))
                                  (set! *menu-title* (cadr saved))
                                  (set! *menu-number-keys* (caddr saved))))))
      (if (not choice)
          (message "Textify cancelled")
          (let ((path (ttfy-file-prompt)))
            (if (string=? path "")
                (message "Textify cancelled")
                (let ((range (prompt "PDF pages (all, N or N-M; C-g cancels): " "all")))
                  (if (string=? range "")
                      (message "Textify cancelled")
                      (ttfy-convert (ttfy-choice-provider (string->number choice)) path
                                    (if (string-ci=? (trim range) "all") "" range))))))))))

(global-set-key "C-c f" 'ttfy-menu)
