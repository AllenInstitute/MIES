#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma ModuleName=EpochRecreation

/// @brief This function is a helper function to create copies of recreated epochs waves for each sweep of an experiment file
///        as preparation for testcase @ref TestEpochRecreationShortNames
///
/// @param dfName name of data folder that is created in root:
Function ExportEpochsFromFileToDF(string dfName)

	string file, win, abWin, sweepBrowsers
	variable first, last, i

	Open/D/R/F="Data Files (*.pxp,*.nwb):.pxp,.nwb;" i
	if(IsEmpty(s_fileName))
		return NaN
	endif
	file = S_fileName

	[abWin, sweepBrowsers] = OpenAnalysisBrowser({file}, loadSweeps = 1, loadStimsets = 1, absolutePaths = 1)
	win = StringFromList(0, sweepBrowsers)
	[first, last] = BSP_FirstAndLastSweepAcquired(win)

	KillOrMoveToTrash(dfr = root:$dfName)
	DFREF dfr = createDFWithAllParents("root:" + dfName)

	for(i = first; i < last; i += 1)
		WAVE/Z/T numericalValues = BSP_GetLogbookWave(win, LBT_LABNOTEBOOK, LBN_NUMERICAL_VALUES, sweepNumber = i)
		ASSERT(WaveExists(numericalValues), "Numerical LabNotebook not found.")
		WAVE/Z/T textualValues = BSP_GetLogbookWave(win, LBT_LABNOTEBOOK, LBN_TEXTUAL_VALUES, sweepNumber = i)
		ASSERT(WaveExists(textualValues), "Textual LabNotebook not found.")

		DFREF  sweepDFR = BSP_GetSweepDF(win, i)
		WAVE/Z epochs   = MIES_EP#EP_RecreateEpochsFromLoadedData(numericalValues, textualValues, sweepDFR, i)
		Duplicate epochs, dfr:$("epoch_" + num2istr(i))
	endfor

	string/G dfr:fullFileName = file

	printf "Exported recreated epochs for %d sweeps from file %s to root:%s\r", last, file, dfName
End

/// UTF_TD_GENERATOR GetHistoricDataFilesPXP
static Function TestEpochRecreationFromLoadedPXP([string str])

	string file, miesPath, win, device
	variable numObjectsLoaded, first, last, i

	if(!StringEndsWith(LowerStr(str), ".pxp"))
		PASS()
		return NaN
	endif

	file = "input:" + str
	PathInfo home

	DFREF dfr = GetMIESPath()
	KillDataFolder dfr

	miesPath = GetMiesPathAsString()

	DFREF dfr     = NewFreeDataFolder()
	DFREF savedDF = GetDataFolderDFR()
	SetDataFolder dfr
	LoadData/Q/R/P=home/S=miesPath file
	numObjectsLoaded = V_flag
	SetDataFolder savedDF
	MoveDataFolder dfr, root:
	RenameDataFolder root:$DF_NAME_FREE, $DF_NAME_MIES

	// sanity check if the test setup is ok
	CHECK_NO_RTE()
	CHECK_GT_VAR(numObjectsLoaded, 0)

	// This is a workaround because LoadData DOES NOT LOAD WaveRef WAVES
	// The Cache values are in the pxp present but not loaded as they are of type /WAVE
	// PLEASE CHECK THIS, IF THIS TEST FAILS IN FUTURE HISTORIC DATA TESTS
	CA_FlushCache()

	win    = DB_OpenDataBrowser()
	device = BSP_GetDevice(win)
	[first, last] = BSP_FirstAndLastSweepAcquired(win)
	CHECK_GE_VAR(last, first)

	WAVE numericalValues = DB_GetLBNWave(win, LBN_NUMERICAL_VALUES)
	WAVE textualValues   = DB_GetLBNWave(win, LBN_TEXTUAL_VALUES)
	for(i = first; i < last; i += 1)
		SplitAndUpgradeSweepGlobal(device, i)
		DFREF  sweepDFR = BSP_GetSweepDF(win, i)
		WAVE/Z epochs   = MIES_EP#EP_RecreateEpochsFromLoadedData(numericalValues, textualValues, sweepDFR, i)
		CHECK_NO_RTE()
		CHECK_WAVE(epochs, TEXT_WAVE)
	endfor
End

/// UTF_TD_GENERATOR GetHistoricDataFiles
static Function TestEpochRecreationShortNames([string str])

	string file, win, abWin, sweepBrowsers, refEpFolder
	variable first, last, i

	// Data file to datafolder matching for data files that require to also use @ref ExtendRefEpochsWithUserEpochs
	if(!CmpStr(str, "C57BL6J-628261.02.01.02.nwb"))
		refEpFolder = "EpochsC57"
	elseif(!CmpStr(str, "Gad2-IRES-Cre;Ai14-709273.06.02.02.nwb"))
		refEpFolder = "EpochsGad2"
	else
		refEpFolder = ""
	endif

	file = "input:" + str

	[abWin, sweepBrowsers] = OpenAnalysisBrowser({file}, loadSweeps = 1, loadStimsets = 1)
	win = StringFromList(0, sweepBrowsers)
	[first, last] = BSP_FirstAndLastSweepAcquired(win)

	for(i = first; i < last; i += 1)
		WAVE/Z/T numericalValues = BSP_GetLogbookWave(win, LBT_LABNOTEBOOK, LBN_NUMERICAL_VALUES, sweepNumber = i)
		ASSERT(WaveExists(numericalValues), "Numerical LabNotebook not found.")
		WAVE/Z/T textualValues = BSP_GetLogbookWave(win, LBT_LABNOTEBOOK, LBN_TEXTUAL_VALUES, sweepNumber = i)
		ASSERT(WaveExists(textualValues), "Textual LabNotebook not found.")

		DFREF sweepDFR = BSP_GetSweepDF(win, i)
		try
			WAVE/Z epochs = MIES_EP#EP_RecreateEpochsFromLoadedData(numericalValues, textualValues, sweepDFR, i)
		catch
			// This can happen for old nwb2 data where some stimsets are created from formulas.
			// In these formulas other "dependend" stimsets are refrenced that were not saved to the nwb files.
			// As a result of this missing data the stimsets from formulas can not be recreated and thus, the epochs can not be recreated.
			// Can potentially happen in all nwb2 files that were exported before commit
			// ad9130c2 (WB: fix recursive resolving dependet stimsets (e.g. formulas), 2024-03-12)
			printf "Note: Could not recreate epochs for sweep %d in file %s.\r", i, str
			continue
		endtry
		WAVE/ZZ refEpochs
		if(!IsEmpty(refEpFolder))
			DFREF dfr       = root:$refEpFolder
			WAVE  refEpochs = dfr:$("epoch_" + num2istr(i))
		endif
		CompareEpochsOfSweep(numericalValues, textualValues, i, sweepDFR, epochs, historic = 1, userEpochRef = refEpochs)
	endfor
End
