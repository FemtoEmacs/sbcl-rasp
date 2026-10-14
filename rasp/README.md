# sbcl-rasp

RASP (Robust Accurate Statistical Parsing) is a parser for English by Ted
Briscoe, John Carroll and colleagues at the Universities of Cambridge and
Sussex [1, 2]. It splits text into sentences and words, tags each word with
its part of speech, reduces it to its root, and parses the sequence of tags
with a grammar, returning parse trees and grammatical relations (subject,
object, modifier, ...).

sbcl-rasp is RASP 3.3a ported to SBCL and repaired, as part of a project
that uses RASP to check English written by people and by generative AI. The
original only ran on Clozure Common Lisp for Intel processors; this version
runs natively on Apple Silicon and on Linux.

## Build

You need SBCL, a C compiler and make. Nothing else: flex comes with the
sources and is built once.

```sh
git clone https://github.com/FemtoEmacs/sbcl-rasp
cd sbcl-rasp       # build and test from the top folder
make            # about two minutes; RASP goes to rasp/bin/<arch>/
make check      # RASP and qprolog tests
```

## Use

```sh
echo "This sentence have a mistake. These tools helps me write." | rasp/scripts/rasp.sh
```

Each sentence comes out as its words, the number of complete parses and
their scores, and the grammatical relations of the best parse. A sentence
outside the grammar gets 0 parses and the fragments RASP found. Options of
`scripts/rasp.sh`: `-p "-n 5"` for the five best parses, `-p "-o t"` for the
tree, `-1` for one tag per word (the original default).

## What changed

`CHANGES.md` explains each change and the sentences it fixes; every change to
the original files is in `docs/changes-from-rasp-3.3a.patch`. In short:

- the parser builds and runs on SBCL, with analyses identical to the original
  on the 560 DepBank test sentences;
- the tokeniser no longer splits numbers into digits ("1990" became
  "1 9 9 0"), and the sentence splitter no longer cuts DOIs;
- the tagger passes several tags per word to the parser, and knows a few more
  words;
- RASP rejects doubled function words ("evaluated for for reproducibility")
  and function words read as names ("an of antigen presentation"), which the
  original accepted;
- no Berkeley DB, no Python: SBCL, a C compiler and make are enough.

## Tests

`make check` runs `tests/check.lisp`:

1. all sentences in `tests/codex-correct.txt` and
   `tests/constructed-correct.txt` must parse;
2. the sentences of `tests/known-bad.txt` must be rejected, except the open
   problems listed in `tests/known-bad-open.txt`;
3. the parser's analyses of the 560 DepBank sentences must be identical to
   those of the original RASP 3.3a.

A change to RASP is accepted only when all three pass.

## Licence and credits

RASP is free software under the GNU Lesser General Public License, version 3
or later (`COPYING`, `COPYING.LESSER`); the changes are under the same
licence. RASP is by Ted Briscoe, John Carroll, Rebecca Watson, Øistein
Andersen and colleagues; see `README.rasp-3.3a`. flex
(`third_party/flex-2.6.4.tar.gz`) is distributed under its own BSD-style
licence, included in the archive.

[1] Briscoe T, Carroll J, Watson R. The second release of the RASP system.
*Proceedings of the COLING/ACL 2006 Interactive Presentation Sessions*,
77–80. doi:10.3115/1225403.1225423.

[2] Briscoe T. An introduction to tag sequence grammars and the RASP system
parser. Technical Report UCAM-CL-TR-662, University of Cambridge Computer
Laboratory, 2006.
