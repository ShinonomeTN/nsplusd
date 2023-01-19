#!/bin/bash

md="DOCUMENTATION_PDF_LINKS.md"
echo -e '# Documentation Artifacts\n\n' > $md
cat .osslist |
    sed 's|pdf$|pdf)|' |
    sed 's|pdf http|pdf](http|' |
    sed 's|^_dist|- [|' >> $md

