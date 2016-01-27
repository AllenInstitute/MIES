@echo off
SET IGOR="C:\Program Files\WaveMetrics\Igor Pro 7 Folder\IgorBinaries_x64\Igor64.exe"
%IGOR% /Q/X AI_SetMIESHeadstage("ITC1600_Dev_0", increment = -1)
