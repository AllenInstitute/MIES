@echo off
SET IGOR="C:\Program Files (x86)\WaveMetrics\Igor Pro Folder\Igor.exe"
%IGOR% /Q/X P_UpdatePressureMode("ITC1600_Dev_0", 3,"button_DataAcq_Clear",0)
