#!/bin/sh
# Publish only the grounding AI PDF and its index link.
# Run from sbcl-rasp: sh git/publish-grounding.sh
set -e
cd "$(dirname "$0")/.."
echo "Publishing only docs/index.html and docs/grounding-ai.pdf"
git add -- docs/index.html docs/grounding-ai.pdf
git commit --only -m "Publish grounding AI paper and link from reports index" -- docs/index.html docs/grounding-ai.pdf
git push origin main
