#!/bin/sh
# Build seclarge-c2s.lex = seclarge.lex (unchanged) + c2s-additions.lex.
# The tagger merges repeated words, so additions may add tags to existing words.
cd "$(dirname "$0")"
n=$(( $(tail -n +2 seclarge.lex | wc -l) + $(grep -c . c2s-additions.lex) ))
{ printf 'D%d\n' "$n"; tail -n +2 seclarge.lex; cat c2s-additions.lex; } > seclarge-c2s.lex
