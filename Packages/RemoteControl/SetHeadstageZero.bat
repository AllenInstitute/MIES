@echo off
SET IGOR="C:\Program Files (x86)\WaveMetrics\Igor Pro Folder\Igor.exe"
%IGOR% /Q/X AI_SetMIESHeadstage("ITC1600_Dev_0", headstage = 0)
