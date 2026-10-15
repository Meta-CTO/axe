#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION="${1:?usage: scripts/package-metacto.sh <version, for example 1.8.0-metacto.1>}"
LOG="$PWD/dist/package-metacto.log"
OUT="$PWD/dist/axe-metacto"
mkdir -p dist
rm -rf "$OUT" "$LOG"

command -v xcodegen > /dev/null || { echo "needs xcodegen: brew install xcodegen"; exit 1; }

for stage in setup clean frameworks install strip xcframeworks; do
  echo "- idb frameworks: $stage"
  ./scripts/build.sh "$stage" >> "$LOG" 2>&1 || { tail -20 "$LOG"; exit 1; }
done

echo "- axe"
swift build -c release >> "$LOG" 2>&1 || { grep -m5 error: "$LOG"; exit 1; }

mkdir -p "$OUT"
cp .build/release/axe "$OUT/"
cp -R .build/release/*.framework .build/release/AXe_AXe.bundle "$OUT/"
git rev-parse HEAD > "$OUT/COMMIT"

echo "- check the packaged axe runs from another folder"
CHECK="$(mktemp -d)"
cp -R "$OUT" "$CHECK/"
"$CHECK/axe-metacto/axe" --version
rm -rf "$CHECK"

tar -C dist -czf "dist/axe-metacto-$VERSION.tar.gz" axe-metacto
echo "packaged dist/axe-metacto-$VERSION.tar.gz"
echo "publish it with:"
echo "  gh release create v$VERSION dist/axe-metacto-$VERSION.tar.gz -R Meta-CTO/axe --target metacto --title v$VERSION --notes 'MetaCTO build of axe'"
