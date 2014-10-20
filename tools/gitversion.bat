REM This script assumes that .. of its location is the git top level directory

SET REPO=%~dp0
"c:\Program Files (x86)\Git\bin\git.exe" --git-dir=%REPO%..\\.git describe --always --tags > %REPO%..\\version.txt
