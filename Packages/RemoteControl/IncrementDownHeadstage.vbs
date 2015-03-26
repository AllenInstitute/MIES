Set WshShell = CreateObject("WScript.Shell")
ScriptDir = CreateObject("Scripting.FileSystemObject").GetParentFolderName(WScript.ScriptFullName)
WshShell.Run chr(34) & ScriptDir & "\IncrementDownHeadstage.bat" & Chr(34), 0
Set WshShell = Nothing
