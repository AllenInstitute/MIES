#!/bin/sh

StateFile=DO_AUTORUN.txt

rm -f compilationState.txt

touch $StateFile

for i in $(ls *.pxp)
do
	echo "Running experiment $i"
	timeout 45s env WINEPREFIX=/home/thomasb/.wine-igor wine64 C:/Program\ Files/WaveMetrics/Igor\ Pro\ 7\ Folder/IgorBinaries_x64/Igor64.exe /N /I "$(pwd)/$i"
done

rm -f $StateFile
