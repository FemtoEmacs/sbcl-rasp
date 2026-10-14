#!/bin/sh
# Publish the reports on https://femtoemacs.github.io/sbcl-rasp/
# Copies the latest Flexner AI report and the Flexner digest into docs/,
# then commits and pushes with git/gitpush.sh.
# Run it from the sbcl-rasp folder:  git/pages.sh
set -e
cd "$(dirname "$0")/.."
for source in ../paper/autoclave/flexner-ai-report.pdf ../paper/flexner-digest/flexner-digest.pdf; do
    if [ ! -f "$source" ]; then echo "Not found: $source"; exit 1; fi
    cp "$source" docs/
    echo "Copied $(basename "$source") into docs/."
done
if [ ! -s git/next-commit.txt ]; then
    printf '%s\n' "Publish the Flexner AI report on GitHub Pages" > git/next-commit.txt
fi
sh git/gitpush.sh
echo "The report will appear in a minute or two at:"
echo "  https://femtoemacs.github.io/sbcl-rasp/"
