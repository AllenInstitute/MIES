@echo off
SET IGOR="C:\Program Files (x86)\WaveMetrics\Igor Pro Folder\Igor.exe"
%IGOR% /Q/X P_SetApproach("ITC1600_Dev_0", "button_DataAcq_Approach")
