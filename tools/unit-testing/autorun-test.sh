#!/bin/sh

StateFile=DO_AUTORUN.txt

touch $StateFile

# use only the given experiments if present
if [ "$#" -eq 0 ]
then
  experiments=$(ls *.pxp)
else
  experiments=$@
fi

for i in $experiments
do
	echo "Running experiment $i"

  case $MSYSTEM in
    MINGW*)
      # we don't want MSYS path conversion, as that would break the /X options,
      # see https://github.com/git-for-windows/build-extra/blob/master/ReleaseNotes.md
      MSYS_NO_PATHCONV=1 "/c/Program Files/WaveMetrics/Igor Pro 7 Folder/IgorBinaries_x64/Igor64.exe" /N /I "$i"
      ;;
    *)
      env WINEPREFIX=/home/thomasb/.wine-igor wine C:/Program\ Files/WaveMetrics/Igor\ Pro\ 7\ Folder/IgorBinaries_x64/Igor64.exe /N /I "$(pwd)/$i"
        ;;
  esac

done

rm -f $StateFile
