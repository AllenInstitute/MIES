REM This script assumes that .. of its location is the git top level directory

SET REPO=%~dp0

SET GIT_I386="C:\Program Files (x86)\Git\bin\git.exe"
SET GIT_X64="C:\Program Files\Git\mingw64\bin\git.exe"

IF EXIST %GIT_I386% (
	SET GIT=%GIT_I386%
)

IF EXIST %GIT_X64% (
	SET GIT=%GIT_X64%
)

%GIT% --git-dir="%REPO%..\\.git" describe --always --tags > "%REPO%..\\version.txt"
