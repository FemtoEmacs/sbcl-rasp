#!/bin/sh
# Publish the reports on https://femtoemacs.github.io/sbcl-rasp/
# Copies the latest report from c2s-cover/paper/autoclave into docs/,
# then commits and pushes with git/gitpush.sh.
# Run it from the sbcl-rasp folder:  git/pages.sh
set -e
cd "$(dirname "$0")/.."
report=../paper/autoclave/flexner-ai-report.pdf
if [ ! -f "$report" ]; then
    echo "Report not found: $report"; exit 1
fi
cp "$report" docs/flexner-ai-report.pdf
echo "Copied the report into docs/."
if [ ! -s git/next-commit.txt ]; then
    printf '%s\n' "Publish the Flexner AI report on GitHub Pages" > git/next-commit.txt
fi
sh git/gitpush.sh
echo "The report will appear in a minute or two at:"
echo "  https://femtoemacs.github.io/sbcl-rasp/flexner-ai-report.pdf"
