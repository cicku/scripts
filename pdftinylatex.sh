#!/bin/sh

# pdftinylatex.sh - generate tiny paper sized pdf from PERSONAL LaTeX files
# Last update Time-stamp: <2016-03-07 14:57:33 (f6k)> 
# Author: f6k <f6k@opmbx.org>

# pdftinylatex.sh is shared by license Dual Beer-Ware/WTFPLv2.

# THE BEER-WARE LICENSE:
# As long as you retain this notice you can do whatever you want with this
# stuff. If we meet some day, and you think this stuff is worth it, you can
# buy me a beer in return.

# DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
# Version 2, December 2004
# Copies of this license document, and changing it is allowed as long
# as the name is changed.
# DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
# TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
# 0. You just DO WHAT THE FUCK YOU WANT TO.

TMPFILE="pdflatex-"$$""
touch /tmp/$TMPFILE.tex

# tinyfication activated
# (is usefull only for my own LaTeX files...)
sed -e 's/12pt,a4paper,draft]{article/17pt,a5paper,draft]{extarticle/' \
    -e 's/12pt,a4paper,draft]{report/14pt,a5paper,draft]{extreport/' \
    -e 's/hmargin=2cm,vmargin=2.5cm/hmargin=0.2cm,vmargin=0.25cm/' \
    -e 's/\\hspace\*{0\.2\\textwidth}\\rule{1pt}//' \
    -e 's/{\\textheight}\\hspace\*{0\.05\\textwidth}//' \
    -e 's/\\parbox\[b\]{0\.75\\textwidth}/\\parbox\[b\]{0\.98\\textwidth}/' \
    -e 's/\\vspace{0\.4\\textheight}/\\vspace{0\.3\\textheight}/' \
    $1 > /tmp/$TMPFILE.tex

# compilation time
pushd /tmp/ > /dev/null 2>&1
pdflatex $TMPFILE.tex
pdflatex $TMPFILE.tex
pdflatex $TMPFILE.tex

echo ""
echo -en "Generating $(basename $1 |sed 's/.tex//')_mini.pdf... "
popd > /dev/null 2>&1
mv -f /tmp/$TMPFILE.pdf $(basename $1 |sed 's/.tex//')_mini.pdf
echo "done"

echo -en "Cleaning... "
rm -f /tmp/$TMPFILE.*
echo "done"
