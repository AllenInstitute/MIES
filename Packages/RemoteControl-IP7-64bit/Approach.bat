@echo off
SET IGOR="C:\Program Files\WaveMetrics\Igor Pro 7 Folder\IgorBinaries_x64\Igor64.exe"
%IGOR% /Q/X P_SetApproach("ITC1600_Dev_0", "button_DataAcq_Approach")
