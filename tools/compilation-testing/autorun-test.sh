#!/bin/sh

StateFile=DO_AUTORUN.txt

touch $StateFile

for i in $(ls *.pxp)
do
	echo "Running experiment $i"
	WINEPREFIX=/home/thomasb/.wine-igor wine64 C:/Program\ Files/WaveMetrics/Igor\ Pro\ 7\ Folder/IgorBinaries_x64/Igor64.exe /CompErrNoDialog /N /I "$(pwd)/$i" 2> errorOutput.log
done

echo "Igor Pro compilation error output:"
cat errorOutput.log

rm -f $StateFile
