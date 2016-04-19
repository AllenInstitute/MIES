#!/bin/sh

StateFile=DO_AUTORUN.txt

rm -f compilationState.txt

touch $StateFile

for i in $(ls *.pxp)
do
	echo "Running experiment $i"
	timeout 30s env WINEPREFIX=/home/thomasb/.wine-igor wine C:/Program\ Files/WaveMetrics/Igor\ Pro\ 7\ Folder/IgorBinaries_Win32/Igor.exe /N /I "$(pwd)/$i"
done

rm -f $StateFile
