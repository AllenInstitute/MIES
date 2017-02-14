#!/bin/sh

StateFile=DO_AUTORUN.txt

touch $StateFile

for i in $(ls *.pxp)
do
	echo "Running experiment $i"
	env WINEPREFIX=/home/thomasb/.wine-igor wine C:/Program\ Files/WaveMetrics/Igor\ Pro\ 7\ Folder/IgorBinaries_Win32/Igor.exe /N /I "$(pwd)/$i"
done

rm -f $StateFile
