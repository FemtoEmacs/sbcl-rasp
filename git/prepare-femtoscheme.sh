#!/bin/sh
# Build the embedded femtoscheme editor. Run: sh git/prepare-femtoscheme.sh
set -e
project_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
echo "Building C-owned SBEmacs with femtoscheme; no nested Git repository."
make -C "$project_dir/sbemacs"
