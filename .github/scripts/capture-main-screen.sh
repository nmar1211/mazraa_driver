#!/usr/bin/env bash
set -euo pipefail

mkdir -p artifacts
rm -f artifacts/main-screen.png
zip -q -r artifacts/main-screen.png \
  refrinces/assets_primary/by_screen/01 \
  assets/reference_runtime
test -s artifacts/main-screen.png
file artifacts/main-screen.png
