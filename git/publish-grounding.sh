#!/bin/sh
# Publish the grounding AI manuscript, PDF, and reports index.
# Run from sbcl-rasp: sh git/publish-grounding.sh
set -e
cd "$(dirname "$0")/.."
echo "Publishing the grounding AI manuscript and PDF"
git add -- docs/index.html docs/grounding-ai.pdf paper/grounding-ai.md git/publish-grounding.sh
git commit --only -F git/next-commit.txt -- docs/index.html docs/grounding-ai.pdf paper/grounding-ai.md git/publish-grounding.sh
: > git/next-commit.txt
git push origin main
