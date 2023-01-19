#!/bin/bash

if [[ -e "$2" ]]; then
    for i in "$@"; do
        bash "$0" "$i" || exit 1
    done
    exit $?
fi

md_path="$1"
pdf_path="_dist/$(sed 's/.md$/.pdf/' <<< "$md_path")"

mkdir -p "$(dirname "$pdf_path")"

pandoc -i "$md_path" \
    --toc \
    -H <(echo '\apptocmd{\tableofcontents}{\clearpage}') \
    -B <(echo '\frenchspacing') \
    -A <(echo '\clearpage\leavevmode\vfill\small This document is part of NSPlusD software and is published with GNU FDL 1.3.\par\href{https://github.com/ShinonomeTN/nsplusd}{https://github.com/ShinonomeTN/nsplusd}') \
    -V monofont="JetBrains Mono NL" \
    -V fontsize="11pt" \
    -V geometry="a4paper,textwidth=38em,vmargin=25mm" \
    --shift-heading-level-by=-1 \
    --pdf-engine=xelatex \
    -o "$pdf_path"

du -h "$(realpath "$pdf_path")"


### Extra stuff
if [[ $USER == neruthes ]]; then
    cfoss "$pdf_path"
fi
