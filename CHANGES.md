# Changes from RASP 3.3a

sbcl-rasp starts from the open-source release RASP 3.3a (December 2020, LGPL;
its README is kept as `README.rasp-3.3a`). Every change to the original files is
in `docs/changes-from-rasp-3.3a.patch`. `make check` runs the tests described in
`README.md`.

## 2026-10-11, the port to SBCL

0. The parser ran only on Clozure Common Lisp for Intel processors. A build
   script (`gde/build-sbcl.lisp`) and small changes in `scripts/rasp_parse.sh`,
   `prob/code/tools.lsp`, `extract-grs.lsp` and `xml-output.lsp` make it build
   and run on SBCL, so it runs natively on Apple Silicon. On the 560 DepBank
   sentences the SBCL parser gives exactly the analyses of the original
   (`tests/parc560-not-ne-ccl-t0.out`, made with Clozure CL 1.12).

## 2026-10-13 (Claude), first repairs

Results on Linux (SBCL 2.2.9), same sources:

| | RASP 3.3a | sbcl-rasp |
|---|---|---|
| codex-correct (81) parsed | 68 | 81 |
| known-bad (30) rejected | 17 | 17 (the same 17) |
| DepBank 560, parser only | = oracle | = oracle (0 differing lines) |
| the original README, sentences parsed | 17/84 | 24/84 |

1. **Tokeniser: numbers were split into digits.** `tokenise/token.flex`. "1990"
   became "1 9 9 0", "76" became "7 6", "C2S-Scale" became "C 2S-Scale", DOIs
   became strings of digits. Cause: the trailing-context rule
   `{alphanum}/{leftbracket}{alphanum}` is compiled by flex 2.6 so that it
   matches a single digit. Parenthesising the definitions restores the intended
   rule ("word(" before a bracket). Contractions, possessives, `f(x)`,
   decimals and thousands are unchanged. The CCL oracle shows the same split
   ("2020" → "2 0 2 0"), so the fault was in the original build, not the port.
   Fixes s020 s030 (with 2).
2. **Several tags per word by default.** `scripts/rasp.sh`: the existing `-m`
   mode (tagger passes all plausible tags to the parser) is now the default;
   `-1` gives the old single-tag mode. Fixes verbs tagged as plural nouns
   ("notes", "lists", "points", "groups", "accounts") and "that" read as a
   conjunction: s008 s010 s016 s018 s050 s057 s088.
3. **Lexicon additions.** `tag/auxiliary_files/c2s-additions.lex`, merged with
   the untouched `seclarge.lex` into `seclarge-c2s.lex` by `make-c2s-lex.sh`
   (rerun after editing the additions). Verb readings of "benchmark" and
   "reuse" (both were unknown words, tagged as nouns); "CINEMA-OT" as a proper
   noun (was guessed as an adjective). Fixes s049 s062 s086.
4. **Sentence splitter: DOIs were cut.** `sentence/sentence.flex`. A full stop
   followed directly by a digit, with no space, started a new sentence
   ("10.1016/j.scib.2026..." was cut before "2026"). Now a full stop without a
   following space ends a sentence only before a capital. Abbreviations,
   decimals and "ended.Next" are unchanged. Fixes s024.

## 2026-10-13 (Claude), rejecting wrong sentences

| | RASP 3.3a | sbcl-rasp |
|---|---|---|
| codex-correct (81) parsed | 68 | 81 |
| constructed-correct (11) parsed | 11 | 11 |
| known-bad (27) rejected | 17 | 25 |
| DepBank 560, parser only | = oracle | = oracle (0 differing lines) |

5. **Run-time patches were never loaded under SBCL.** `scripts/rasp_parse.sh`
   loads `prob/patch*.lsp`, but builds the file pattern with
   `(make-pathname :name "patch*")`, which SBCL reads as a literal name, and
   passes a relative directory that the parser image cannot resolve. Now the
   pattern is the string `"patch*.lsp"` and the RASP directory is absolute.
   (The distribution's `patch1.lsp` is empty, so earlier outputs are unaffected.)
6. **Word constraints.** `prob/patch2-c2s.lsp` (new; loaded at run time, no
   rebuild needed). The grammar sees only tags, so it cannot tell "for for"
   from "from under". The patch looks at the words and, when a sentence breaks
   a constraint, discards the full parses, so RASP reports its partial
   analysis (0 parses):
   - the same function word twice in a row ("for for", "of of", "a a", "to to",
     "than than", "into into", "alongside alongside"); words that can end a
     phrasal verb ("on on Monday", "in in pairs") and words with correct
     doubles ("that that", "had had", "her her") are not in the list;
   - a lowercase function word that the tagger could only read as a proper
     noun ("an" in "an of antigen presentation", read as the name "An").
   Fixes b03 b08 b12 b18 b22 b25 b27 b29.
7. **Test sets corrected.** b11 "it cites.", b24 "at each.", b28 "and
   discusses." are grammatical (intransitive verbs, "each" as a pronoun); they
   were wrongly put in known-bad and now sit in `constructed-correct.txt`
   (g09-g11), with eight correct sentences that resemble the errors
   ("That that is fine.", "The light went on on Monday.", ...).

## 2026-10-14 (Claude), a self-contained build

8. **No Berkeley DB.** The tagger linked Berkeley DB only for an optional
   binary dictionary (option `-v`) that `rasp.sh` never uses. `tag/src/nodb.c`
   replaces the library; asking for `-v` now stops with a message.
9. **flex is bundled.** `third_party/flex-2.6.4.tar.gz` (the official release,
   SHA-256 e87aae032bf07c26f85ac0ed3250998c37621d95f8bd748b31f15b33c45ee995) is
   built once by `make`; the sentence splitter, tokeniser and morphological
   analyser are always generated from their `.flex`/`.lex` sources by that
   version. The original shipped `morph/morpha.yy.c` made by flex 2.5.4 with
   enlarged tables; flex 2.6.4 needs option `-Ca` for `morpha.lex` (over 32,000
   NFA states). The regenerated `morpha` gives identical output on all 66,683
   word/tag pairs of the tagger's dictionary.
10. **Tests in Lisp.** `tests/check.lisp` (run by `make check`) replaces the
    Python scripts used before; the build and the tests need only SBCL, a C
    compiler and make.

## Open

- **b13** "ST-ConMa directly a Pythia model trained through the work." (no
  finite verb) is accepted: "directly a Pythia model" is read as an apposition
  to the name, and "trained" as a finite verb. Needs a grammar change
  (`prob/data/tsg15`, rule NP/n1-name_np-r) checked against DepBank.
- **b19** "without a." is accepted with "a" as the letter a (tag ZZ1), which
  is grammatical in principle. Decide whether a sentence-final letter after a
  preposition should be flagged.
- "CINEMA-OT" was added by hand. If more all-capital hyphenated names appear,
  replace the entry with a general rule for unknown words.
- Sentence-initial "Prognostic" in "Prognostic image biomarkers provide ..." is
  tagged as a proper noun (NP1); "Image" in "Image biomarkers that predict
  patient outcomes provide ..." is read as an imperative verb, so "patient
  outcomes" becomes the subject of "provide". Found 2026-10-14 (canonical-form
  example in the paper).
