#!/usr/bin/env bash
# Builds ScreenOCR.swift into ~/.local/bin/screen-ocr. The binary is not versioned
# (see .gitignore).
set -euo pipefail

src_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
out="${HOME}/.local/bin/screen-ocr"

mkdir -p "$(dirname "$out")"
swiftc -O -framework AppKit -o "$out" "${src_dir}/ScreenOCR.swift"
echo "built $out"
