@echo off
SET IGOR="C:\Program Files\WaveMetrics\Igor Pro 7 Folder\IgorBinaries_Win32\Igor.exe"
%IGOR% /Q/X P_UpdatePressureMode("ITC1600_Dev_0", 1,"button_DataAcq_Seal",0)
