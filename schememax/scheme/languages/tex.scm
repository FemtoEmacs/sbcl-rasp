;;;; tex.scm -- syntax highlighting and indentation for TeX and LaTeX

(define-language "TeX"
  'extensions '(".tex" ".sty" ".bib")
  'line-comment "%" 'strings '() 'escape #f
  'backslash-commands #t)

(define-indentation "TeX"
  'style 'block 'width 2 'tabs #f
  'comment "%"
  'reindent-on-newline #t
  'open-anywhere '("\\begin{")
  'not-open-anywhere '("\\begin{document}" "\\end{")
  'close-words '("\\end")
  'electric-keys "}" 'electric-prefixes '("\\end"))
