# sbcl-rasp

Doctors will use generative AI whether or not it is reliable. sbcl-rasp
gathers the tools a person needs to keep a human in the loop: a parser that
checks English written by people and by AI, an editor to read and correct
it, and a logic engine to reason about it. Everything builds with SBCL, a C
compiler and make, and nothing else.

Components are added as the project needs them:

| Folder        | What it is                                                     |
|---------------|----------------------------------------------------------------|
| `rasp/`       | RASP 3.3a, the English parser, ported to SBCL and repaired     |
| `browsered/`  | Browsered, an Emacs-like editor that runs in Chrome or Edge     |
| `qprolog/`    | qprolog, a Prolog written in SBCL                              |

## Aviso

Isto não é um produto e deve ser usado apenas para testar o software, Claude Code, Codex, OpenEvidence e os algoritmos. Se alguém quiser desenvolver o produto para venda, distribuição ou uso próprio, sinta-se à vontade para fazê-lo.

## Build and test

```sh
git clone https://github.com/FemtoEmacs/sbcl-rasp
cd sbcl-rasp
make            # about two minutes
make check      # about two minutes
```

`make` builds RASP and, on macOS, the Browsered helper. qprolog needs no
build. On Linux and Windows, open `browsered/Browsered.html` in Chrome or
Edge.

## Use

```sh
echo "This sentence have a mistake." | rasp/scripts/rasp.sh
cd qprolog && ./qp bench/programs/tak.lisp '(tak 18 12 6 ?a)'
```

Each folder has its own README.

## Licences

RASP is under the GNU Lesser General Public License (`rasp/COPYING`,
`rasp/COPYING.LESSER`). FemtoScheme, inside Browsered, is under a BSD
licence (`browsered/femtoscheme/LICENSE`). flex, used to build RASP, is under
its own BSD-style licence, included in `rasp/third_party/`.
