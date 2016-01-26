@echo off
SET IGOR="C:\Program Files\WaveMetrics\Igor Pro 7 Folder\IgorBinaries_Win32\Igor.exe"
%IGOR% /Q/X AI_SetMIESHeadstage("ITC1600_Dev_0", headstage = 3)
