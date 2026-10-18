#Femto Emacs Change Log

## 2026-10-18 — C-c p: plots back from their tables

* C-c p (M-x plot-at-point, also M-x irene-dixe) draws the Kaplan-Meier
  table (estimator-plot ...) at the cursor in a window of its own, by the
  new program irene-dixe (src/irene-dixe.c, SDL2 and SDL2_ttf): legend
  colours, censor marks, shaded unresolved intervals, numbers at risk and
  the printed statistics.  s saves a PNG beside the file; q closes.  With
  no display, a character sketch opens in *plot*.
* Tables are read, never evaluated; # outside strings is refused (#. would
  evaluate while reading).
* M-x plot-save writes the picture without a window and confirms that
  the file exists.  s in the window now draws the picture again in
  software before saving; reading the window back could fail silently on
  macOS.  The window shows where the picture went.
* Pictures are PNG, written by irene-dixe itself (no SDL_image or zlib):
  about 120 KB for a plot that took 2.5 MB as BMP.
* Fixed: a file opened by a relative name (`schememax paper.md`) had its
  pictures saved in the home folder; they now go beside the file.
* New primitives: spawn-program (start without waiting), os-name, getpid.
* Fixed: number->string truncated reals (0.8 gave "0"), in femtoscheme.
* Fixed: windows split or joined by a script (TTFY, the assistants, C-c p)
  could keep stale text at the ends of shortened rows until C-l.

## 2026-10-18 — Emacs-style word wrap

* Fixed: in a wrapped file (Markdown, TeX, text) that does not end in a
  newline, the cursor at the end of the file sat at the start of the row
  below the text, or at the bottom of the window, while typing went
  above it.  It now stays after the last character.

* Markdown, TeX and plain-text files wrap long lines at word boundaries,
  like Emacs's visual-line-mode.  The blanks at a break stay at the end
  of the upper row, so the next row starts with a word.
* C-c w, MORE > "Word wrap on/off", M-x toggle-word-wrap or
  M-x visual-line-mode switch wrapping on or off for the current file, in
  any language.  The help page (C-h) lists C-c w.
* The help page (C-h, or [?] > Keybindings) has a new section, "M-x
  commands", for commands without a key of their own: toggle-word-wrap,
  visual-line-mode, indent-buffer, python-mode, dark-theme ...
* The help page's mode line has [CLOSE] instead of [?]: help from help
  only reopened the same page.  C-c r and C-c g still reach Claude and
  ChatGPT from the help page.

## 2026-10-18 — SBEmacs's scripts ported to Scheme

* Every script of SBEmacs's lisp/ folder now has a Scheme counterpart in
  scheme/ (core, api, highlight, indent, theme, undo, gui, languages/,
  defaults, extensions/, modes/): Emacs editing keys, undo and redo,
  indentation for 12 languages, Markdown, the mode line menu, help, the
  shell window, dired, grep, kill ring, buffer menu, the Claude and Codex
  assistants with discussions, the Python and Nim modes.
* Key bindings in Emacs notation now work (M-w, M-:, C-/ ... were never
  reached before).
* src/highlight.c: the highlighters (generic tokenizer, Markdown, Python,
  Nim), fed by the Scheme language tables.
* src/primitives.c: buffer text in bulk, exact byte insertion, files,
  running programs with a timeout.
* src/hooks.c: highlight, mode line, change and wrap hooks call Scheme.
* tests/run-tests.scm: SBEmacs's test suite, ported (make check).
* TTFY moved from C-c t to C-c f; C-c t is SBEmacs's discussion key again.
* ~/.schememax/init.scm and ~/.schememax/{languages,extensions}/ are loaded
  after the scripts.

## 2026-10-18 — source reorganization

* All C sources now live in `src/` (the former `bridge/` files moved there).
* Removed the obsolete FemtoEmacs clone at the top level (old C sources,
  `femtolisp/`, `samples/`, old makefiles, `femto.boot`, `init.lsp`,
  `r5rs.scm`, `sbemacs` binaries and `SBEmacs.app`).
* femtoscheme: `string_from_cstr(n)` take `const char *`.
* Editor Scheme scripts moved to `scheme/` (counterpart of the original
  `lisp/`); `init.scm` loads the others through `*scheme-dir*`.


## Femto 1.13 27 Dec 2016
* Fixed bug where could not open multiple files of same name but with different filepaths
* added (rename-buffer) and (find-file) commands
* added grep-command extension C-x C-g to search files, C-x ! to visit next find. (see init.lsp)

## Femto 1.12 18 Dec 2016
* Fixed annoyance. Changed searchtext so that is reset to blank when search is started.

## Femto 1.11 18 Dec 2016
* Modified init.lsp so that keys are bound using 'global-set-key' and there is an interpretter loop
* added additional entries for C-x C-char user-defined-function

## Femto 1.10 6 Nov 2016
* fixed UTF8 char handling in undo for INSERT, BACKSPACE, DEL, INSERT_AT
* fixed DEL, INSERT_AT now working properly at all.
* python support for syntax highlighting
* added C-x C-d start of Dired functionality

## Femto 1.9 27 Oct 2016
* added discard-undo-history command and lisp interface

## Femto 1.8.1 27 Oct 2016
* removed _(x) macro from header.h
* changed C-o to Esc-; for repl(), frees up Control-O for other editor commands.
* cleaned up call_lisp code in flcall.c
* cleaned up main code that calls init_lisp(), pass size of heap in KB into init_lisp().
* removed double wrapping of lisp commands with the (let ((b buffer)) expression
* changed repl() so that output more than 60 chars is sent to a *lisp_output* buffer that pops up
* changed killbuffer so it does not ask to kill a special buffer (even if modified)
* renamed temp to response_buf and ensured we only use it for getting response at the command line

## Femto 1.8 26 Oct 2016
* Added unlimited undo (supports Insert, Backspace, Yank, Kill-Region, Delete), see docs/undo.txt for details
* Added special buffer mode for buffers that have names starting with * (Thanks to chigoncalves)

## Femto 1.7 9 Oct 2016
* Potential fix for segmentation fault when calling (environment) within FemtoEmacs

## Femto 1.6 8 Oct 2016
* Added apropos Esc-a
* Execute-command Esc-x (with command completion)
* Added list-bindings command
* Sorted key binding list
* Fixed bug with copying first time in a buffer

## Femto 1.5.X dd/mm/yy
* Interim history to be added from got logs

## Femto 1.5 20 June 2016
* Added automatic matching of parenthesis {}() and []
* Fixed bug where a new file created when file not found did not have a buffer created

## Femto 1.4 13 June 2016
* Initialised buffer name to empty string
* Added basic colour scheme

## Femto v1.3 12 June 2016
* Fixed defect with paste command introduced in v1.1
* Added messages on copy and cut to show how many bytes

## Femto v1.2 3 June 2016
* Added UTF8 support

## Femto v1.1 31 May 2016
* Added list-buffers C-x C-b
* fixed problem of opening up multiple output windows
* refactored paste.  Paste now calls insert-string with contents of scrap

## Femto v1.0 29 May 2016
* Added filename completion (use TAB to complete)
* Added shell-command (C-x @), output is read into a buffer

2026-10-17: C-owned embedded femtoscheme architecture in sbcl-rasp/sbemacs.
Based on original master, replacing the embedded femtolisp runtime with the
local Browsered femtoscheme runtime. Added Makefile, init.scm, C bridge and
headless --eval/--version commands. Native build, runtime suites, and terminal
editing/save/evaluation smoke checks passed on macOS. No SBCL dependency.

The editor folder is now ordinary vendored source under sbcl-rasp; its nested
Git history has been removed. The original SBEmacs repository retains that history.

2026-10-17: Imported modern sbcl-branch C screen/editor core, keeping C-owned
startup and embedding femtoscheme. Built terminal, GUI and macOS app bundle.
Added typed Scheme API, mode-line menus, light/dark palettes with contrasting
cursors, provider CLI bridges, basic undo/navigation/editing extensions and
basic highlighting. Local provider/highlighter tests passed. Full original
feature parity remains incomplete; FEATURE-PARITY.md records the gaps.

2026-10-17: Shared GUI/ncurses Help selector matching the original editor:
1 Keybindings, 2 ChatGPT, 3 Claude; arrows/Enter, direct number selection,
mouse Run/Close, and source/point restoration. Added help.scm and menu checks.

2026-10-17: Fixed Help Run for ChatGPT/Claude: bypass the invisible secondary
menu and open the request pane directly, preserving drafts. Refresh provider
shortcut menus before reading input. Added dispatch regression tests and tested
actual ncurses mouse selection/Run for both providers without an extra key.

2026-10-17: Replaced blank provider request panes with visible instructions,
Send/Close buttons and empty-request feedback. Exclude form instructions from
provider prompts. Added request-form tests and verified terminal mouse Send
through a local fake provider to the displayed response.

2026-10-17: AI response/setup panes now have a dedicated Close action instead
of the document Quit button. Close removes the pane and restores the source
buffer. Added modeline and Close-dispatch regression checks for both providers.

2026-10-17: Renamed build outputs to schememax, schememax-gui and Schememax.app.
Updated GUI launcher, bundle metadata, checks and documented launch commands.

2026-10-17: Added TTFY button, provider menu, completing PDF picker and page
ranges. Native macOS PDF rendering supplies Codex image attachments or Claude
Read inputs; Markdown opens in an editable, savable result buffer. Added
plot-to-table guidelines, diagnostic panes and offline seven-page Benedetto
integration tests. Restored missing complete-file event/native binding for
Tab completion in C-x C-f and the PDF picker, with ~/ expansion on acceptance.

2026-10-17: Require Kaplan-Meier curve-building S-expression tables in TTFY.
Documented axis calibration, every recoverable jump, separate censor/risk
annotations, uncertainty, gaps, start/end points and step reconstruction.

2026-10-17: Fixed Search: typing now searches incrementally, Enter accepts,
C-s/C-r repeat in their respective directions, and C-g restores the origin.
Fixed backward matches at buffer start, off-by-one positioning and unsafe
end-of-buffer reads. Failed searches retain the previous cursor position.
Added C regression tests covering input handling and gap-buffer boundaries.
