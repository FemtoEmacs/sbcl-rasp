# Browsered in sbcl-rasp

Browsered is an editor with Emacs keys that runs in Chrome or Edge, scripted
in femtoscheme (a small Scheme compiled to WebAssembly). In sbcl-rasp it is
the editor for things that need a window: showing RASP's analyses to people
who are not linguists.

This folder holds the finished editor and the helper's source, taken from
[FemtoEmacs/browsered](https://github.com/FemtoEmacs/browsered) at commit
a751c12. Changing the editor itself (its C interpreter, the build of
`Browsered.html`) is done in that repository, which needs Emscripten.

- **macOS:** `make` (at the top of sbcl-rasp, or here) builds `Browsered.app`.
  Double-click it: it starts the helper and opens the editor at
  http://127.0.0.1:8766/.
- **Linux:** open `Browsered.html` in Chrome or Edge. There is no Linux
  helper yet.
- **Windows:** `windows/` has the helper's source and the installer script;
  the installer is built by GitHub Actions.
- **Tailoring:** key bindings and commands are in `editor.scm` and
  `init.scm`, loaded as text; changing them needs no rebuild.

femtoscheme derives from femtolisp by Jeff Bezanson (BSD licence,
`femtoscheme/LICENSE`).
