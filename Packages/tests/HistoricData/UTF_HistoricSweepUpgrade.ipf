#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma ModuleName=HistoricSweepUpgrade

/// UTF_TD_GENERATOR GetHistoricDataFilesSweepUpgrade
static Function TestSweepUpgrade([string str])

	string abWin, sweepBrowsers, file, bsPanel, sbWin, dataFolder, device, preUpgradeName
	variable sweepNo     = 0
	variable channelSize = 507778

	file = "input:" + str

	[abWin, sweepBrowsers] = OpenAnalysisBrowser({file}, loadSweeps = 1)
	sbWin                  = StringFromList(0, sweepBrowsers)
	CHECK_PROPER_STR(sbWin)
	bsPanel = BSP_GetPanel(sbWin)

	DFREF  sweepBrowserDFR = SB_GetSweepBrowserFolder(sbWin)
	WAVE/T sweepMap        = GetSweepBrowserMap(sweepBrowserDFR)
	dataFolder = sweepMap[0][%DataFolder]
	device     = sweepMap[0][%Device]
	DFREF sweepDFR = GetAnalysisSweepPath(dataFolder, device)

	WAVE/Z/SDFR=sweepDFR sweep = $GetSweepWaveName(sweepNo)
	Make/FREE/T sweepRef = {"X_0:DA_0", "X_0:AD_0"}
	CHECK_EQUAL_WAVES(sweepRef, sweep, mode = WAVE_DATA)

	Make/FREE/T sweepBakRef = {"X_0:DA_0" + WAVE_BACKUP_SUFFIX, "X_0:AD_0" + WAVE_BACKUP_SUFFIX}
	WAVE/Z/T sweepBak = MIES_MIESUTILS_BACKUPWAVES#GetBackupWave_TS(sweep)
	CHECK_EQUAL_WAVES(sweepBakRef, sweepBak, mode = WAVE_DATA)

	WAVE/Z channel0 = ResolveSweepChannel(sweep, 0, allowFail = 1)
	CHECK_WAVE(channel0, NUMERIC_WAVE)
	CHECK_EQUAL_VAR(channelSize, DimSize(channel0, ROWS))
	WAVE/Z channel1 = ResolveSweepChannel(sweep, 1, allowFail = 1)
	CHECK_WAVE(channel1, NUMERIC_WAVE)
	CHECK_EQUAL_VAR(channelSize, DimSize(channel1, ROWS))

	WAVE/Z channelB0 = ResolveSweepChannel(sweepBak, 0, allowFail = 1)
	WAVE/Z channelB1 = ResolveSweepChannel(sweepBak, 1, allowFail = 1)
	CHECK_EQUAL_WAVES(channel0, channelB0)
	CHECK_EQUAL_WAVES(channel1, channelB1)

	preUpgradeName = GetSweepWaveName(sweepNo) + "_preUpgrade"
	WAVE/Z/SDFR=sweepDFR sweepPre = $preUpgradeName
	CHECK_WAVE(sweepPre, NUMERIC_WAVE)
	CHECK_EQUAL_VAR(channelSize, DimSize(sweepPre, ROWS))
	CHECK_EQUAL_VAR(2, DimSize(sweepPre, COLS))

	DFREF            dfr0    = sweepDFR:X_0
	SVAR/Z/SDFR=dfr0 noteStr = note
	CHECK_EQUAL_VAR(SVAR_Exists(noteStr), 1)
End
