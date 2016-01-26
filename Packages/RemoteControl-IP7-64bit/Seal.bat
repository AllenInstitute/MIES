@echo off
SET IGOR="C:\Program Files\WaveMetrics\Igor Pro 7 Folder\IgorBinaries_x64\Igor64.exe"
%IGOR% /Q/X P_UpdatePressureMode("ITC1600_Dev_0", 1,"button_DataAcq_Seal",0)
