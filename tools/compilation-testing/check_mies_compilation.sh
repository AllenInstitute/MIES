#!/bin/sh

set -e

export DISPLAY=:0

rm -f *.txt *.log *.xml

echo MIES_Include          >> input.txt
echo MIES_AnalysisBrowser  >> input.txt
echo MIES_Databrowser      >> input.txt
echo MIES_WavebuilderPanel >> input.txt
echo MIES_Downsample       >> input.txt

./autorun-test.sh

exit 0
