#!/bin/sh

set -e

export DISPLAY=:0

rm -f *.txt *.log

echo MIES_Include > input.txt
./autorun-test.sh
mv compilationState.txt IncludeState.txt

echo MIES_AnalysisBrowser > input.txt
./autorun-test.sh
mv compilationState.txt AnalysisBrowserState.txt

echo MIES_Databrowser > input.txt
./autorun-test.sh
mv compilationState.txt DataBrowserState.txt

echo MIES_WavebuilderPanel > input.txt
./autorun-test.sh
mv compilationState.txt WaveBuilderPanelState.txt

echo MIES_Downsample > input.txt
./autorun-test.sh
mv compilationState.txt DownsampleState.txt

include=$(cat IncludeState.txt)
analysis=$(cat AnalysisBrowserState.txt)
databrowser=$(cat DataBrowserState.txt)
wavebuilder=$(cat WaveBuilderPanelState.txt)
downsample=$(cat DownsampleState.txt)

echo "Results (4 means compiles, everything else not)"
echo "$include:Include"
echo "$analysis:AnalysisBrowser"
echo "$databrowser:Databrowser"
echo "$wavebuilder:WavebuilderPanel"
echo "$downsample:Downsample"

if [ $include -eq 4 -a $analysis -eq 4 -a $databrowser -eq 4 -a $wavebuilder -eq 4 -a $downsample -eq 4 ]
then
  exit 0
fi

exit 1
