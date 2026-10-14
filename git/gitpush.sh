#!/bin/sh
# Commit every change in sbcl-rasp and push it to GitHub.
#   git/gitpush.sh                 message taken from git/next-commit.txt
#   git/gitpush.sh "My message"    message given here
# Run it from the sbcl-rasp folder.
set -e
cd "$(dirname "$0")/.."

if [ -n "$1" ]; then
    msgfile=$(mktemp); printf '%s\n' "$1" > "$msgfile"
elif [ -s git/next-commit.txt ]; then
    msgfile=git/next-commit.txt
else
    echo "No commit message. Write one:  git/gitpush.sh \"What changed\""; exit 1
fi

git add -A
if git diff --cached --quiet; then
    echo "Nothing new to commit."
else
    git commit -F "$msgfile"
    [ "$msgfile" = git/next-commit.txt ] && : > git/next-commit.txt
fi

echo "Sending to GitHub..."
git push origin main
echo "Done. See https://github.com/FemtoEmacs/sbcl-rasp (the Actions tab shows the test run)."
