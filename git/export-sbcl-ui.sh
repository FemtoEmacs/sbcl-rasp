#!/bin/sh
# Import committed sbcl UI sources for the femtoscheme port. Run from sbcl-rasp.
set -e
project_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
source_dir="$project_dir/../../sbemacs"
snapshot=$(mktemp -d /private/tmp/sbemacs-sbcl-ui-XXXXXX)
git -C "$source_dir" archive sbcl | tar -xf - -C "$snapshot"
echo "$snapshot"
