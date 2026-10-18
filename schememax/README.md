# Schememax: SBEmacs with C-owned femtoscheme

The C core owns `main()`, startup, the event loop and both screen backends
(terminal and window). It starts an embedded femtoscheme VM, loads
`scheme/init.scm`, and calls Scheme for every key, click, typed character and
change to the text. Everything else -- key bindings, editing commands,
indentation, highlighting rules, undo, menus, help, the shell window and the
assistants -- is a Scheme script, ported from SBEmacs's `lisp/` folder (the
`sbcl` branch). No SBCL runtime or SBCL build step is used.

The keys, menus and behaviour follow SBEmacs. FEATURE-PARITY.md lists what
was ported and the few differences.

## Build and launch

```
make
./schememax paper.md           # terminal
./schememax --gui paper.md     # window (SDL2), when built
make app                       # macOS application bundle
open Schememax.app
make check                     # femtoscheme suites and the editor's tests
make check-ui                  # search, assistant protocols, PDF rendering
```

The terminal uses the system curses library; the window uses SDL2 and
SDL2_ttf. The Scheme runtime is bundled source: no Scheme installation or
package manager is needed. `make` builds the window version when its
libraries are found through pkg-config.

Keep the executable beside the `scheme/`, `femtoscheme/` and `ttfy/`
folders; `make app` copies them into Schememax.app.

## Layout

| Path | Contents |
|---|---|
| `src/` | The C sources: editor core, screen backends (`term.c`, `gui.c`), the femtoscheme bridge (`hooks.c`, `native.c`, `primitives.c`) and the tokenizers (`highlight.c`) |
| `femtoscheme/` | The bundled Scheme, built by its own Makefile |
| `scheme/` | The scripts, in load order: `core`, `api`, `highlight`, `indent`, `theme`, `undo`, `gui`, `languages/`, `defaults`, `extensions/` |
| `scheme/modes/` | The Python and Nim modes and their loader (M-x load-mode) |
| `tests/` | `run-tests.scm` (`make check`) and the C and protocol tests (`make check-ui`) |
| `reference/sbcl-lisp/` | SBEmacs's Lisp scripts, the specification of the port |
| `docs/` | Historical FemtoEmacs documentation |

## Customizing

Edit any script and press C-x C-r (reload-scripts): no rebuild. Your own
settings go in `~/.schememax/init.scm`, loaded last, and your own languages
and extensions in `~/.schememax/languages/*.scm` and
`~/.schememax/extensions/*.scm`. For example:

```scheme
(global-set-key "C-c d" 'insert-day)       ; Emacs key notation
(set-color 'comment 244)                   ; a face, 0-255 or "#rrggbb"
(set! *fill-column* 78)
(set! *gui-theme* 'light)                  ; or M-x light-theme
(set-gui-font "/Library/Fonts/JetBrainsMono-Regular.ttf" 15)
(define-language "Zig" 'extensions '(".zig") 'line-comment "//"
  'keywords '("fn" "const" "var" "pub" "return"))
```

`SCHEMEMAX_NO_INIT=1` skips your files. A script that fails to load is
reported on the message line at start-up; the others still load.

## Keys

C-h (or F1) shows every key on one page. The highlights:

- **Emacs editing:** words, sentences, paragraphs and expressions (M-f, M-e,
  M-}, C-M-f ...), kills that join in the kill ring (C-k C-k, M-d) with
  C-y/M-y, transposing, case changes, M-q filling, M-; comments.
- **Undo and redo:** C-/ (also C-_, C-x u, C-u) undoes a command at a time;
  C-M-_ or M-_ redoes. Undoing back to the saved text clears the `*`.
- **Indentation:** TAB, RET and electric keys indent C, Lisp, Scheme,
  Python, Nim, Ruby, Haskell, Lean, ML, Prolog, TeX and Markdown; repeated
  TAB cycles through the levels where that makes sense. C-x TAB indents the
  region. In Markdown, RET continues a list and an empty item ends it.
- **Files and buffers:** C-x b (filtered buffer picker), C-x C-b (buffer
  menu), C-x d / C-x C-d (directory browser), C-x C-g and C-x ! (grep),
  C-x s, C-x C-v, TAB completion with `*` and `?` in file prompts.
- **Scheme:** C-x C-e, C-M-x and M-: evaluate; C-x C-r reloads the scripts.
- **Shell:** M-! opens a window for a command (Enter: more lines); C-c s
  runs it and shows the output below the command.

## Menus

Every mode line is a menu the mouse can click:
`file.py, L. 12 [?][SAVE][UNDO][Select][MORE][TTFY]   [QUIT]`. With text
selected, Select becomes COPY and DELETE. A narrow window drops buttons
from the right but keeps [?], [MORE], [TTFY] and [QUIT]. [MORE] lists every action for the
window, including those a narrow window cannot show. The file name is a
button too: it shows the file's lines, words, size and save time. [?] offers
Keybindings, ChatGPT and Claude.

M-x light-theme and M-x dark-theme switch the window's Tomorrow palettes
(blue and yellow cursors). The terminal keeps its own background.

## Assistants

C-c r asks Claude and C-c g asks Codex (ChatGPT). Each offers **h** hints
about the code at the cursor, **q** a question written in a window of its
own (the same key sends it), or **d** a discussion that stays open. C-c y
inserts the code of an answer, after asking; in a discussion, C-c t inserts
the snippet under the cursor. The assistants only read: Claude runs with
every tool disabled, Codex in its read-only sandbox, and nothing enters
your file without confirmation (C-/ takes it back).

Claude is reached through Claude Code (`claude -p`, your usual login) or,
without it, the Messages API with ANTHROPIC_API_KEY or
`~/.schememax/anthropic-api-key`. Codex is found on the PATH, in
`~/.local/bin` or in the ChatGPT app. `SCHEMEMAX_CLAUDE` and
`SCHEMEMAX_CODEX` choose other executables.

## Textify a PDF for an AI that accepts only text

Click [TTFY] on the mode line (or press C-c f), then **1 Textify with ChatGPT** or
**2 Textify with Claude**. The PDF prompt has the same TAB completion as
C-x C-f. Choose `all` pages, a page such as `4`, or a range such as `3-5`;
C-g cancels.

The chosen CLI receives the selected pages and `ttfy/plots-guidelines.md`.
On macOS, the C bridge renders 144-dpi page PNGs through Quartz/ImageIO; no
Python, OCR library or Poppler installation is needed. Codex receives image
attachments in its read-only sandbox; Claude gets only the Read tool, for
these page images. The Markdown appears in a new `*ttfy-N.md*` buffer; C-x
C-w saves it. Failures are shown in a window below; logs and rendered pages
stay in private `/tmp/schememax-ttfy-*` folders. Ranges are limited to 32
pages per conversion. Native rendering is implemented on macOS only.

`make check-ui` exercises rendering, both provider protocols, page selection
and failures with offline test providers. It expects the seven-page fixture
`ttfy/benedetto.pdf`.

### Plots back from their tables: C-c p

A textified paper carries each Kaplan-Meier figure as an `(estimator-plot ...)`
table. Put the cursor on a table, or anywhere inside it, and press C-c p
(M-x plot-at-point): `irene-dixe`, a small SDL program built by `make`,
opens a window with the curves redrawn from the table, in the legend's
colours, with censor marks, the unresolved intervals shaded, the numbers at
risk under the axis and the printed statistics beside it. In that window s
saves the picture as a PNG beside the Markdown file (`paper-plot-1.png`),
q closes it. M-x plot-save writes the same picture without opening a
window, and the editor checks that the file is there before saying
"Saved". Without a display, or without irene-dixe, a character sketch
opens in `*plot*`.

The table is read as data and never evaluated; a table with `#` outside
strings is refused, because the reader's `#.` would run code. Levels that
do not join (a drop starting away from the current level) are listed under
the legend for review, not repaired. `irene-dixe --render TABLE OUT.png`
draws without a window. Sketches of diagnostic images will use C-c p too.

## Search

C-s searches forward and C-r backward as you type; repeat them for the
next or previous match. Enter accepts; C-g cancels and returns. M-%
replaces, asking each time. Search is literal and case-sensitive.
