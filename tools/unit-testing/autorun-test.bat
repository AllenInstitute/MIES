@echo off

REM Script for automatic test execution and logging from the command line
REM Opens all experiment files in the current directory in autorun mode

set IgorPath="%PROGRAMFILES%\WaveMetrics\Igor Pro 7 Folder\IgorBinaries_Win32\Igor.exe"
set StateFile="DO_AUTORUN.TXT"

if exist %IgorPath% goto foundIgor
echo Igor Pro could not be found in %IgorPath%, please adjust the variable IgorPath in the script
goto done

:foundIgor

echo "" > %StateFile%

for /F "tokens=*" %%f IN ('dir /b *.pxp') do (
  echo Running experiment %%f
  %IgorPath% /I "%%f"
)

del %StateFile%

:done
