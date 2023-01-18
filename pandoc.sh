#!/bin/bash

md_path="$1"
pdf_path="_dist/$(sed 's/.md$/.pdf/' <<< "$md_path")"

mkdir -p "$(dirname "$pdf_path")"

pandoc -i "$md_path" \
    -V fontsize="12pt" \
    -V geometry="a4paper" \
    --shift-heading-level-by=-1 \
    -o "$pdf_path"

du -h "$(realpath "$pdf_path")"
