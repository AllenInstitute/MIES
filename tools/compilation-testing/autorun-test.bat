@echo off

REM Script for automatic test execution and logging from the command line
REM Opens all experiment files in the current directory in autorun mode

set StateFile="DO_AUTORUN.TXT"

del/Q/S compilationState.txt

echo "" > %StateFile%

for /F "tokens=*" %%f IN ('dir /b *.pxp') do (
  echo Running experiment %%f
  start /D "" "C:\Program Files\WaveMetrics\Igor Pro 7 Folder\IgorBinaries_Win32" Igor.exe /N /I "%%f"
  C:\Windows\System32\timeout /t 30
  taskkill /im Igor.exe /f
)

del %StateFile%

:done
