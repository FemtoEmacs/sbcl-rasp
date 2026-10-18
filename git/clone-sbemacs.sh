#!/bin/sh
# Import master source without nested history. Run: sh git/clone-sbemacs.sh
set -e
project_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
source_dir=$(CDPATH= cd -- "$project_dir/../../sbemacs" && pwd)
target_dir="$project_dir/sbemacs"
if [ -e "$target_dir" ]; then
    echo "SBEmacs source already exists; leaving it unchanged: $target_dir"
    exit 0
fi
archive_file=$(mktemp)
trap 'rm -f "$archive_file"' EXIT HUP INT TERM
echo "Importing committed master source; no Git history is copied."
git -C "$source_dir" archive master > "$archive_file"
mkdir "$target_dir"
tar -xf "$archive_file" -C "$target_dir"
echo "Master source imported. The embedded femtoscheme adaptations are maintained by sbcl-rasp."
