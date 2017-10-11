@echo off

REM Script for automatic test execution and logging from the command line
REM Opens all experiment files in the current directory in autorun mode

set StateFile="DO_AUTORUN.TXT"

echo "" > %StateFile%

for /F "tokens=*" %%f IN ('dir /b *.pxp') do (
  echo Running experiment %%f
  "C:\Program Files\WaveMetrics\Igor Pro 7 Folder\IgorBinaries_x64\Igor64.exe" /CompErrNoDialog /N /I "%%f" 2> errorOutput.log
)

echo "Igor Pro compilation error output:"
type errorOutput.log

del %StateFile%
