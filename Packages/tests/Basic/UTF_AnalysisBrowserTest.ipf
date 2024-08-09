#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma ModuleName=AnalysisBrowserTests

/// @file UTF_AnalysisBrowserTest.ipf
/// @brief __ANALYSISBROWSER_Test__ This file holds the tests for the Analysis Browser Tests

static StrConstant PXP_FILENAME  = "input:AB_LoadSweepsFromIgorData.pxp"
static StrConstant PXP2_FILENAME = "input:AB_SweepsFromMultipleDevices.pxp"
static StrConstant PXP3_FILENAME = "input:SourceOfDependentStimset.pxp"
static StrConstant NWB1_FILENAME = "input:AB_SweepsFromMultipleDevices-compressed-V1.nwb"
static StrConstant NWB2_FILENAME = "input:AB_SweepsFromMultipleDevices-compressed-V2.nwb"
static StrConstant NWB3_FILENAME = ":_2017_09_01_192934-compressed.nwb"

static Function LoadSweepsFromIgor()

	string abWin, sweepBrowsers, win

	[abWin, sweepBrowsers] = OpenAnalysisBrowser({PXP_FILENAME}, loadSweeps = 1)

	CHECK_EQUAL_VAR(ItemsInList(sweepBrowsers), 1)
	win = StringFromList(0, sweepBrowsers)
	WAVE/Z sweep = WaveRefIndexed(win, 0, 1)
	CHECK_WAVE(sweep, NUMERIC_WAVE)
	CHECK_EQUAL_VAR(DimSize(sweep, ROWS), 31667)
	CHECK_CLOSE_VAR(WaveMax(sweep), 1000, tol = 1E-2)
	KillWindow $abWin
	KilLWindow $win
End

static Function CheckRefCount()

	string abWin, dfPath, sweepBrowsers
	string sBrowser1, sBrowser2

	KillOrMoveToTrash(dfr = GetAnalysisFolder())

	[abWin, sweepBrowsers] = OpenAnalysisBrowser({PXP2_FILENAME})

	WAVE expBrowserSel = GetExperimentBrowserGUISel()
	expBrowserSel[0][0][0] = LISTBOX_TREEVIEW | LISTBOX_SELECTED

	DFREF  dfr         = $(GetAnalysisFolderAS() + ":workFolder:")
	WAVE/T workFolders = ListToTextWave(GetListOfObjects(dfr, ".*", typeFlag = COUNTOBJECTS_DATAFOLDER, fullPath = 1), ";")
	CHECK_WAVE(workFolders, TEXT_WAVE)
	dfPath = workFolders[0]
	CHECK_EQUAL_VAR(DataFolderExists(dfPath), 1)

	NVAR rc = $GetDFReferenceCount($dfPath)
	CHECK_EQUAL_VAR(rc, 1)
	sBrowser1 = LoadSweeps(abWin)
	CHECK_EQUAL_VAR(rc, 2)
	sBrowser2 = LoadSweeps(abWin)
	CHECK_EQUAL_VAR(rc, 3)

	KillWindow $abWin
	CHECK_EQUAL_VAR(rc, 2)
	KillWindow $sBrowser1
	CHECK_EQUAL_VAR(rc, 1)
	KillWindow $sBrowser2
	CHECK_EQUAL_VAR(DataFolderExists(dfPath), 0)
End

static Function TryLoadingDifferentFiles()

	string abWin, sweepBrowsers, sBrowser1

	[abWin, sweepBrowsers] = OpenAnalysisBrowser({PXP2_FILENAME, NWB1_FILENAME, NWB2_FILENAME})
	WAVE expBrowserSel = GetExperimentBrowserGUISel()

	expBrowserSel[0][0][0] = LISTBOX_TREEVIEW | LISTBOX_SELECTED
	sBrowser1              = LoadSweeps(abWin)

	expBrowserSel[0][0][0] = LISTBOX_TREEVIEW
	expBrowserSel[6][0][0] = LISTBOX_TREEVIEW | LISTBOX_SELECTED
	try
		LoadSweeps(abWin)
		FAIL()
	catch
		PASS()
	endtry

	expBrowserSel[6][0][0]  = LISTBOX_TREEVIEW
	expBrowserSel[12][0][0] = LISTBOX_TREEVIEW | LISTBOX_SELECTED
	try
		LoadSweeps(abWin)
		FAIL()
	catch
		PASS()
	endtry

	KillWindow $abWin
	KillWindow $sBrowser1
End

static Function TestAB_LoadDataWrapper()

	variable numLoaded
	string   expFilePath
	string expName = "TestAB_LoadDataWrapper.pxp"
	string wName   = "wAvE1"

	WAVE/Z wv = root:WAVE1
	KillOrMoveToTrash(wv = wv)
	wName = UpperStr(wName)
	Make root:$wName
	SaveExperiment/P=home as expName

	PathInfo home
	expFilePath = S_path + expName

	DFREF tmpDFR = NewFreeDataFolder()
	wName     = LowerStr(wName) + ";"
	numLoaded = MIES_AB#AB_LoadDataWrapper(tmpDFR, expFilePath, "root:", wName, typeFlags = COUNTOBJECTS_WAVES)
	CHECK_GT_VAR(numLoaded, 0)
End

static Function TestABLoadWave()

	variable err
	string   expFilePath
	string expName = "TestAB_LoadWave.pxp"
	string wName   = "wAvE1"

	WAVE/Z wv = root:$wName
	KillOrMoveToTrash(wv = wv)

	Make root:$wName/WAVE=wv
	SaveExperiment/P=home as expName

	KillOrMoveToTrash(wv = wv)

	PathInfo home
	expFilePath = S_path + expName
	err         = MIES_AB#AB_LoadWave(expFilePath, "root:" + wName, 1)
	CHECK_EQUAL_VAR(err, 0)

	WAVE/Z wv = root:$wName
	CHECK_WAVE(wv, NUMERIC_WAVE)

End

static Function LoadStimsetsFromNWB()

	string abWin, sweepBrowsers

	WBP_CreateWaveBuilderPanel()
	[abWin, sweepBrowsers] = OpenAnalysisBrowser({NWB3_FILENAME}, loadStimsets = 1)
	WAVE/T epochCombineList = GetWBEpochCombineList(CHANNEL_TYPE_DAC)
	CHECK_WAVE(epochCombineList, TEXT_WAVE)
	CHECK_GT_VAR(DimSize(epochCombineList, ROWS), 0)

	KillWindow $abWin
End

static Function LoadDependentStimsetsFromPXP()

	string abWin, sweepBrowsers, formulaSet

	[abWin, sweepBrowsers] = OpenAnalysisBrowser({PXP3_FILENAME}, loadStimsets = 1)
	formulaSet = MIES_WB#WB_StimsetChildren(stimset = "baseset_DA_0")
	CHECK_EQUAL_STR(formulaSet, "formula_da_0;")

	KillWindow $abWin
End

// UTF_TD_GENERATOR DataGenerators#RoundTripStimsetFileType
static Function RoundTripDepStimsets([string str])

	string fName, abWin, sweepBrowsers, stimsets, refList, setNameF, setNameB, formula, set
	string   setNameFormula = "formula"
	string   setNameBase    = "baseSet"
	string   baseFileName   = "RoundTripDepStimsets." + str
	string   chanTypeSuffix = "_DA_0"
	variable nwbVersion     = GetNWBVersion()

	DFREF dfr = GetWaveBuilderPath()
	KillDataFolder dfr

	setNameF = ST_CreateStimset(setNameFormula, CHANNEL_TYPE_DAC)
	ST_SetStimsetParameter(setNameF, "Total number of epochs", var = 1)
	ST_SetStimsetParameter(setNameF, "Total number of steps", var = 1)
	ST_SetStimsetParameter(setNameF, "Type of Epoch 0", var = EPOCH_TYPE_SQUARE_PULSE)
	ST_SetStimsetParameter(setNameF, "Duration", epochIndex = 0, var = 10)
	ST_SetStimsetParameter(setNameF, "Amplitude", epochIndex = 0, var = 1)

	setNameB = ST_CreateStimset(setNameBase, CHANNEL_TYPE_DAC)
	ST_SetStimsetParameter(setNameB, "Total number of epochs", var = 1)
	ST_SetStimsetParameter(setNameB, "Total number of steps", var = 1)
	ST_SetStimsetParameter(setNameB, "Type of Epoch 0", var = EPOCH_TYPE_COMBINE)
	formula = "2*" + LowerStr(setNameF) + "?"
	ST_SetStimsetParameter(setNameB, "Combine epoch formula", epochIndex = 0, str = formula)
	ST_SetStimsetParameter(setNameB, "Combine epoch formula version", epochIndex = 0, str = WAVEBUILDER_COMBINE_FORMULA_VER)

	WAVE/Z baseSet = WB_CreateAndGetStimSet(setNameBase + chanTypeSuffix)
	CHECK_WAVE(baseSet, NUMERIC_WAVE)
	CHECK_GT_VAR(DimSize(baseSet, ROWS), 0)
	WaveStats/Q baseSet
	CHECK_EQUAL_VAR(V_max, 2)
	CHECK_EQUAL_VAR(V_min, 2)

	DFREF dfr = GetWBSvdStimSetPath()
	KillDataFolder dfr

	PathInfo home
	fName = S_path + baseFileName

	if(!CmpStr(str, "nwb"))
		MIES_NWB#NWB_ExportAllStimsets(nwbVersion, fName)
	elseif(!CmpStr(str, "pxp"))
		SaveExperiment/C as fName
	else
		FAIL()
	endif

	DFREF dfr = GetWaveBuilderPath()
	KillDataFolder dfr

	[abWin, sweepBrowsers] = OpenAnalysisBrowser({baseFileName}, loadStimsets = 1)

	stimsets = ST_GetStimsetList()
	stimsets = SortList(stimsets, ";", 16)
	refList  = AddListItem(setNameFormula + chanTypeSuffix, "")
	refList  = AddListItem(setNameBase + chanTypeSuffix, refList)
	refList  = AddListItem(STIMSET_TP_WHILE_DAQ, refList)
	refList  = SortList(refList, ";", 16)
	CHECK_EQUAL_STR(stimsets, refList, case_sensitive = 0)

	WAVE/T wStimsets = ListToTextWave(stimsets, ";")
	for(set : wStimsets)
		if(CmpStr(set, STIMSET_TP_WHILE_DAQ))
			INFO("Stimset %s should not be third party.\r", s0 = set)
			CHECK_EQUAL_VAR(WB_StimsetIsFromThirdParty(set), 0)
		endif
	endfor

	WAVE baseSet = WB_CreateAndGetStimSet(setNameBase + chanTypeSuffix)
	CHECK_WAVE(baseSet, NUMERIC_WAVE)
	CHECK_GT_VAR(DimSize(baseSet, ROWS), 0)
	WaveStats/Q baseSet
	CHECK_EQUAL_VAR(V_max, 2)
	CHECK_EQUAL_VAR(V_min, 2)
End

// UTF_TD_GENERATOR DataGenerators#RoundTripStimsetFileType
static Function RoundTripCustStimsets([string str])

	string wbPanel, fName, abWin, sweepBrowsers, stimsets, refList, setNameB, wPath, set
	string   wName          = "customWave"
	string   setNameBase    = "baseSet"
	string   baseFileName   = "RoundTripCustStimsets." + str
	string   chanTypeSuffix = "_DA_0"
	variable nwbVersion     = GetNWBVersion()
	variable val            = 3

	DFREF dfr = GetWaveBuilderPath()
	KillDataFolder dfr

	KillWaves/Z root:$wName
	Make root:$wName/WAVE=customWave = val

	setNameB = ST_CreateStimset(setNameBase, CHANNEL_TYPE_DAC)
	ST_SetStimsetParameter(setNameB, "Total number of epochs", var = 1)
	ST_SetStimsetParameter(setNameB, "Total number of steps", var = 1)
	ST_SetStimsetParameter(setNameB, "Type of Epoch 0", var = EPOCH_TYPE_CUSTOM)
	wPath = GetWavesDataFolder(customWave, 2)
	ST_SetStimsetParameter(setNameB, "Custom epoch wave name", epochIndex = 0, str = wPath)

	WAVE baseSet = WB_CreateAndGetStimSet(setNameBase + chanTypeSuffix)
	CHECK_WAVE(baseSet, NUMERIC_WAVE)
	CHECK_GT_VAR(DimSize(baseSet, ROWS), 0)
	WaveStats/Q baseSet
	CHECK_EQUAL_VAR(V_max, val)
	CHECK_EQUAL_VAR(V_min, val)

	PathInfo home
	fName = S_path + baseFileName

	if(!CmpStr(str, "nwb"))
		MIES_NWB#NWB_ExportAllStimsets(nwbVersion, fName)
	elseif(!CmpStr(str, "pxp"))
		SaveExperiment/C as fName
	else
		FAIL()
	endif

	DFREF dfr = GetWaveBuilderPath()
	KillDataFolder dfr
	KillWaves root:$wName

	[abWin, sweepBrowsers] = OpenAnalysisBrowser({baseFileName}, loadStimsets = 1)

	stimsets = ST_GetStimsetList()
	stimsets = SortList(stimsets, ";", 16)
	refList  = AddListItem(setNameBase + chanTypeSuffix, "")
	refList  = AddListItem(STIMSET_TP_WHILE_DAQ, refList)
	refList  = SortList(refList, ";", 16)
	CHECK_EQUAL_STR(stimsets, refList, case_sensitive = 0)
	WAVE/T wStimsets = ListToTextWave(stimsets, ";")
	for(set : wStimsets)
		if(CmpStr(set, STIMSET_TP_WHILE_DAQ))
			INFO("Stimset %s should not be third party.\r", s0 = set)
			CHECK_EQUAL_VAR(WB_StimsetIsFromThirdParty(set), 0)
		endif
	endfor

	WAVE baseSet = WB_CreateAndGetStimSet(setNameBase + chanTypeSuffix)
	CHECK_WAVE(baseSet, NUMERIC_WAVE)
	CHECK_GT_VAR(DimSize(baseSet, ROWS), 0)
	WaveStats/Q baseSet
	CHECK_EQUAL_VAR(V_max, val)
	CHECK_EQUAL_VAR(V_min, val)
End

// UTF_TD_GENERATOR DataGenerators#RoundTripStimsetFileType
static Function RoundTripDepStimsetsRecursion([string str])

	string fName, abWin, sweepBrowsers, stimsets, refList, customWavePath, setNameB
	variable amplitude
	string   baseFileName = "RoundTripDepStimsetsRecursion." + str
	variable nwbVersion   = GetNWBVersion()

	[setNameB, refList, customWavePath, amplitude] = CreateDependentStimset()

	PathInfo home
	fName = S_path + baseFileName

	if(!CmpStr(str, "nwb"))
		MIES_NWB#NWB_ExportAllStimsets(nwbVersion, fName)
	elseif(!CmpStr(str, "pxp"))
		SaveExperiment/C as fName
	else
		FAIL()
	endif

	DFREF dfr = GetWaveBuilderPath()
	KillDataFolder dfr
	KillWaves $customWavePath

	[abWin, sweepBrowsers] = OpenAnalysisBrowser({baseFileName}, loadStimsets = 1)

	stimsets = ST_GetStimsetList()
	stimsets = SortList(stimsets, ";", 16)
	refList  = AddListItem(STIMSET_TP_WHILE_DAQ, refList)
	refList  = SortList(refList, ";", 16)
	CHECK_EQUAL_STR(stimsets, refList, case_sensitive = 0)
	WAVE/T wStimsets = ListToTextWave(stimsets, ";")
	for(set : wStimsets)
		if(CmpStr(set, STIMSET_TP_WHILE_DAQ))
			INFO("Stimset %s should not be third party.\r", s0 = set)
			CHECK_EQUAL_VAR(WB_StimsetIsFromThirdParty(set), 0)
		endif
	endfor

	WAVE baseSet = WB_CreateAndGetStimSet(setNameB)
	CHECK_WAVE(baseSet, NUMERIC_WAVE)
	CHECK_GT_VAR(DimSize(baseSet, ROWS), 0)
	WaveStats/Q baseSet
	CHECK_EQUAL_VAR(V_max, amplitude)
	CHECK_EQUAL_VAR(V_min, amplitude)
End
