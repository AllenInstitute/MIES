#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma ModuleName=EpochRecreation

/// @brief This function is a helper function to create copies of recreated epochs waves for each sweep of an experiment file
///        as preparation for testcase @ref TestEpochRecreationShortNames
///
/// @param dfName name of data folder that is created in root:
Function ExportEpochsFromFileToDF(string dfNameTemp)

	string file, win, abWin, sweepBrowsers, device, dfName, dataFolder
	variable sweep

	Open/D/R/F="Data Files (*.pxp,*.nwb):.pxp,.nwb;" i
	if(IsEmpty(s_fileName))
		return NaN
	endif
	file = S_fileName

	[abWin, sweepBrowsers] = OpenAnalysisBrowser({file}, loadSweeps = 1, loadStimsets = 1, absolutePaths = 1)
	win = StringFromList(0, sweepBrowsers)

	WAVE/T map = MIES_SB#SB_GetSweepBrowserMapFromGraph(win)
	if(!GetNumberFromWaveNote(map, NOTE_INDEX))
		print "No entries in sweepmap"
		return NaN
	endif
	WAVE/Z/T devices = SB_GetDeviceList(win)
	if(!WaveExists(devices))
		print "No devices with data loaded in SB."
		return NaN
	endif
	// we have only a single experiment/DF
	dataFolder = map[0][%DataFolder]

	for(device : devices)

		if(DimSize(devices, ROWS) > 1)
			dfName = dfNameTemp + "_" + device
		else
			dfName = dfNameTemp
		endif
		KillOrMoveToTrash(dfr = root:$dfName)
		DFREF dfr = createDFWithAllParents("root:" + dfName)

		WAVE/Z sweeps = SB_GetSweepsFromDevice(win, device)
		if(!WaveExists(sweeps))
			printf "Found no sweeps for device %s\r", device
			continue
		endif

		for(sweep : sweeps)
			WAVE/Z/T numericalValues = SB_GetLogbookWave(win, LBT_LABNOTEBOOK, LBN_NUMERICAL_VALUES, dataFolder = dataFolder, device = device)
			ASSERT(WaveExists(numericalValues), "Numerical LabNotebook not found.")
			WAVE/Z/T textualValues = SB_GetLogbookWave(win, LBT_LABNOTEBOOK, LBN_TEXTUAL_VALUES, dataFolder = dataFolder, device = device)
			ASSERT(WaveExists(textualValues), "Textual LabNotebook not found.")

			DFREF  sweepDFR = GetSingleSweepFolder(GetAnalysisSweepPath(dataFolder, device), sweep)
			WAVE/Z epochs   = MIES_EP#EP_RecreateEpochsFromLoadedData(numericalValues, textualValues, sweepDFR, sweep)
			Duplicate epochs, dfr:$("epoch_" + num2istr(sweep))
		endfor

		string/G dfr:fullFileName = file
		printf "Exported recreated epochs for file %s, device %s, %d sweeps to root:%s\r", file, device, DimSize(sweeps, ROWS), dfName
	endfor
End

/// UTF_TD_GENERATOR GetHistoricDataFilesPXP
static Function TestEpochRecreationFromLoadedPXP([string str])

	string win, device, bsPanel
	variable sweep

	LoadMIESFolderFromPXP("input:" + str)

	win = DB_OpenDataBrowser()
	WAVE/T devicesWithData = ListToTextWave(ListMatch(DB_GetAllDevicesWithData(), "!" + NONE), ";")

	for(device : devicesWithData)
		bsPanel = BSP_GetPanel(win)
		PGC_SetAndActivateControl(bsPanel, "popup_DB_lockedDevices", str = device)
		win = GetMainWindow(GetCurrentWindow())

		WAVE/Z sweepNums = DB_GetPlainSweepList(win)
		CHECK_WAVE(sweepNums, NUMERIC_WAVE)

		WAVE numericalValues = DB_GetLBNWave(win, LBN_NUMERICAL_VALUES)
		WAVE textualValues   = DB_GetLBNWave(win, LBN_TEXTUAL_VALUES)
		for(sweep : sweepNums)
			SplitAndUpgradeSweepGlobal(device, sweep)
			DFREF  sweepDFR = BSP_GetSweepDF(win, sweep)
			WAVE/Z epochs   = MIES_EP#EP_RecreateEpochsFromLoadedData(numericalValues, textualValues, sweepDFR, sweep)
			CHECK_NO_RTE()
			CHECK_WAVE(epochs, TEXT_WAVE)
		endfor
	endfor
End

/// UTF_TD_GENERATOR GetHistoricDataFiles
static Function TestEpochRecreationShortNames([string str])

	string file, win, abWin, sweepBrowsers, refEpFolder, dfName, device, dataFolder
	variable sweep

	// Data file to datafolder matching for data files that require to also use @ref ExtendRefEpochsWithUserEpochs
	if(!CmpStr(str, "C57BL6J-628261.02.01.02.nwb"))
		refEpFolder = "EpochsC57"
	elseif(!CmpStr(str, "Gad2-IRES-Cre;Ai14-709273.06.02.02.nwb"))
		refEpFolder = "EpochsGad2"
	elseif(!CmpStr(str, "H22.03.311.11.08.01.06.nwb"))
		refEpFolder = "EpochsH22"
	elseif(!CmpStr(str, "C57BL6J-629713.05.01.02.pxp"))
		refEpFolder = "EpochsC57PXP"
	elseif(!CmpStr(str, "Pvalb-IRES-Cre;Ai14-646904.13.03.02.pxp"))
		refEpFolder = "EpochsPValbPXP"
	elseif(!CmpStr(str, "NWB-Export-bug-two-devices.pxp"))
		refEpFolder = "NWBExportBugTwoDevices"
	else
		refEpFolder = ""
	endif

	file = "input:" + str

	[abWin, sweepBrowsers] = OpenAnalysisBrowser({file}, loadSweeps = 1, loadStimsets = 1)
	win = StringFromList(0, sweepBrowsers)
	WAVE/T map = MIES_SB#SB_GetSweepBrowserMapFromGraph(win)
	REQUIRE_GE_VAR(GetNumberFromWaveNote(map, NOTE_INDEX), 0)
	WAVE/Z/T devices = SB_GetDeviceList(win)
	REQUIRE_WAVE(devices, TEXT_WAVE)
	// we have only a single experiment/DF
	dataFolder = map[0][%DataFolder]

	for(device : devices)

		if(DimSize(devices, ROWS) > 1)
			dfName = refEpFolder + "_" + device
		else
			dfName = refEpFolder
		endif

		WAVE/Z sweeps = SB_GetSweepsFromDevice(win, device)
		REQUIRE_WAVE(sweeps, NUMERIC_WAVE)

		for(sweep : sweeps)
			WAVE/Z/T numericalValues = SB_GetLogbookWave(win, LBT_LABNOTEBOOK, LBN_NUMERICAL_VALUES, dataFolder = dataFolder, device = device)
			ASSERT(WaveExists(numericalValues), "Numerical LabNotebook not found.")
			WAVE/Z/T textualValues = SB_GetLogbookWave(win, LBT_LABNOTEBOOK, LBN_TEXTUAL_VALUES, dataFolder = dataFolder, device = device)
			ASSERT(WaveExists(textualValues), "Textual LabNotebook not found.")

			DFREF sweepDFR = GetSingleSweepFolder(GetAnalysisSweepPath(dataFolder, device), sweep)

			try
				WAVE/Z epochs = MIES_EP#EP_RecreateEpochsFromLoadedData(numericalValues, textualValues, sweepDFR, sweep)
			catch
				// This can happen for old nwb2 data where some stimsets are created from formulas.
				// In these formulas other "dependend" stimsets are refrenced that were not saved to the nwb files.
				// As a result of this missing data the stimsets from formulas can not be recreated and thus, the epochs can not be recreated.
				// Can potentially happen in all nwb2 files that were exported before commit
				// ad9130c2 (WB: fix recursive resolving dependet stimsets (e.g. formulas), 2024-03-12)
				printf "Note: Could not recreate epochs for sweep %d in file %s.\r", sweep, str
				continue
			endtry
			WAVE/ZZ refEpochs
			if(!IsEmpty(dfName))
				DFREF dfr       = root:$dfName
				WAVE  refEpochs = dfr:$("epoch_" + num2istr(sweep))
			endif
			CompareEpochsOfSweep(numericalValues, textualValues, sweep, sweepDFR, epochs, historic = 1, userEpochRef = refEpochs)
		endfor
	endfor
End
