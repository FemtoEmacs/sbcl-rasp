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

## The autoclave (proof of concept, macOS)

Browsered can test another medical AI, NAIA, and check its answers.

1. Ask Claude for a test, naming the source: *Create a test about the
   contents of https://...pdf*. Browsered downloads the source (or reads a
   file you name, such as `~/Downloads/paper.pdf`), extracts its text, and
   Claude writes the test into the buffer: questions `Q1:`, expected answers
   `KEY1:` with a quotation from the source, and empty `NAIA1:` lines.
2. Open NAIA (naia.med.br/app) in Chrome and press **NAIA**. Browsered types
   each question into NAIA's page and writes NAIA's answer after `NAIAn:`.
   Chrome must allow it once: View › Developer › Allow JavaScript from Apple
   Events; macOS asks once whether Browsered may control Chrome.
3. Press **Autoclave**. Every quotation in the KEY and NAIA lines is searched
   for in the source text, letter by letter, with no AI involved; the report
   goes at the end of the buffer, and quotations not found in the source are
   marked.
4. Ask Claude to score the answers; it adds a `SCOREn:` line after each.

Every change to the buffer can be undone with Ctrl+/.

## Notice

**English.** This is not a product and must be used only to test the software,
Claude Code, Codex, OpenEvidence and the algorithms. Anyone who wishes to
develop the product for sale, distribution or their own use is free to do so.

**Português (original).** Isto não é um produto e deve ser usado apenas para testar o software, Claude Code, Codex, OpenEvidence e os algoritmos. Se alguém quiser desenvolver o produto para venda, distribuição ou uso próprio, sinta-se à vontade para fazê-lo.

**中文.** 本项目不是产品，仅可用于测试软件、Claude Code、Codex、OpenEvidence 及相关算法。任何人如欲开发该产品用于销售、分发或自用，均可自由进行。

**Latine.** Hoc opus merx non est; adhibendum est tantummodo ad programmata,
Claude Code, Codex, OpenEvidence algorithmosque probanda. Si quis ex eo
mercem facere voluerit, ut vendat, distribuat vel ipse utatur, libere faciat.

