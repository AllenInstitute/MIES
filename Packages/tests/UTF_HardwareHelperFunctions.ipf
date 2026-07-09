#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors = 1
#pragma ModuleName       = HardwareHelperFunctions

#include "UTF_HelperFunctions"
#include "UTF_BackgroundFunctions"
#include "UTF_TestNWBExportV1"
#include "UTF_TestNWBExportV2"

/// @file UTF_HardwareHelperFunctions.ipf
/// @brief This file holds helper functions for the hardware tests

Function HardwareTestBeginCommon(string name)

	variable needsLoading
	string   filepath

	AdditionalExperimentCleanup()

	NVAR interactiveMode = $GetInteractiveMode()
	interactiveMode = 0
	variable/G root:interactiveMode = interactiveMode

	WAVE wv = GetAcqStateTracking()
	KillWaves wv; AbortOnRTE

	// cache the version string
	SVAR     miesVersion      = $GetMIESVersion()
	string/G root:miesVersion = miesVersion

	// cache the device lists
	string/G root:ITCDeviceList = DAP_GetITCDeviceList()
	string/G root:NIDeviceList  = DAP_GetNIDeviceList()

	// cache device info waves
	DFREF dfr  = GetDeviceInfoPath()
	DFREF dest = root:
	DuplicateDataFolder/Z/O=1 dfr, dest
	CHECK_EQUAL_VAR(V_flag, 0)

	CA_FlushCache()

	LoadStimsetsIfRequired()

	TestBeginCommon()
End

Function RestoreCachedInfo()

	DFREF dfr = GetMiesPath()

	SVAR     miesVersion                           = root:miesVersion
	string/G $(GetMiesPathAsString() + ":version") = miesVersion

	NVAR       interactiveMode                               = root:interactiveMode
	variable/G $(GetMiesPathAsString() + ":interactiveMode") = interactiveMode

	GetDAQDevicesFolder()

	SVAR     ITCDeviceList                                       = root:ITCDeviceList
	string/G $(GetDAQDevicesFolderAsString() + ":ITCDeviceList") = ITCDeviceList

	SVAR     NIDeviceList                                       = root:NIDeviceList
	string/G $(GetDAQDevicesFolderAsString() + ":NIDeviceList") = NIDeviceList

	DFREF dest   = GetDAQDevicesFolder()
	DFREF source = root:DeviceInfo
	DuplicateDataFolder/O=1/Z source, dest
	CHECK_EQUAL_VAR(V_flag, 0)
End

Function HardwareTestCaseBeginCommon(string name)

	variable numWindows, i
	string list, reentryFuncName, win, experimentName

	// cut off multi data suffix
	name = StringFromList(0, name, ":")

	RegisterReentryFunction(name)

	TestCaseBeginCommon(name)

	MoveStimsetsIntoPlace()

	RestoreCachedInfo()

	// remove NWB file which will be used for sweep-by-sweep export
	NWB_CloseAllNwBFiles()
	DeleteFile/Z GetExperimentNWBFileForExport()

	// not moved into AdditionalExperimentCleanup() as
	// we don't want to do it after the test
	KillOrMoveToTrash(wv = GetTrackSweepCounts())
	KillOrMoveToTrash(wv = GetTrackActiveSetCount())
	KillOrMoveToTrash(wv = TrackAnalysisFunctionCalls())
End

Function HardwareTestCaseEndCommon(string name)

	string dev, experimentNWBFile, baseFolder, nwbFile, wlName
	variable numEntries, i, fileID, nwbVersion, expensiveChecks

	// be sure that DAQ/TP is stopped before we do anything else
#ifndef TESTS_WITH_NI_HARDWARE
	DQ_StopOngoingDAQAllLocked(DQ_STOP_REASON_INVALID)
	TP_StopTestPulseOnAllDevices()
#endif // !TESTS_WITH_NI_HARDWARE

	expensiveChecks = DoExpensiveChecks()

	// cut off multi data suffix
	name = StringFromList(0, name, ":")

	SVAR devices = $GetLockedDevices()

	numEntries = ItemsInList(devices)
	for(i = 0; i < numEntries; i += 1)
		dev = StringFromList(i, devices)

		wlName = GetWorkLoadName(WORKLOADCLASS_TP, dev)
		CHECK(!ASYNC_WaitForWLCToFinishAndRemove(wlName, 10))

		wlName = GetWorkLoadName(WORKLOADCLASS_NWB, dev)
		CHECK(!ASYNC_WaitForWLCToFinishAndRemove(wlName, 10))

		// no analysis function errors
		NVAR errorCounter = $GetAnalysisFuncErrorCounter(dev)
		CHECK_EQUAL_VAR(errorCounter, 0)

		// correct acquisition state
		NVAR acqState = $GetAcquisitionState(dev)
		CHECK_EQUAL_VAR(acqState, AS_INACTIVE)

		if(!expensiveChecks)
			continue
		endif

		CheckEpochs(dev)

		WAVE/Z sweeps = AFH_GetSweeps(dev)

		if(!WaveExists(sweeps))
			PASS()
			continue
		endif

		// ascending sweep numbers in both labnotebooks
		WAVE   numericalValues = GetLBNumericalValues(dev)
		WAVE/Z sweeps          = GetSweepsWithSetting(numericalValues, "SweepNum")
		CHECK_WAVE(sweeps, NUMERIC_WAVE)

		Duplicate/FREE sweeps, unsortedSweeps
		Sort sweeps, sweeps
		CHECK_EQUAL_WAVES(sweeps, unsortedSweeps, mode = WAVE_DATA)

		WAVE   textualValues = GetLBTextualValues(dev)
		WAVE/Z sweeps        = GetSweepsWithSetting(textualValues, "SweepNum")
		CHECK_WAVE(sweeps, NUMERIC_WAVE)

		Duplicate/FREE sweeps, unsortedSweeps
		Sort sweeps, sweeps
		CHECK_EQUAL_WAVES(sweeps, unsortedSweeps, mode = WAVE_DATA)

		CheckLBIndexCache_IGNORE(dev)
		CheckLBRowCache_IGNORE(dev)

		TestSweepReconstruction_IGNORE(dev)
	endfor

	StopAllBackgroundTasks()

	if(expensiveChecks)
		// store experiment NWB file for later validation
		HDF5CloseFile/A/Z 0
		experimentNWBFile = GetExperimentNWBFileForExport()

		if(FileExists(experimentNWBFile))
			fileID     = H5_OpenFile(experimentNWBFile)
			nwbVersion = GetNWBMajorVersion(ReadNWBVersion(fileID))
			HDF5CloseFile fileID

			[baseFolder, nwbFile] = GetUniqueNWBFileForExport(nwbVersion)
			MoveFile experimentNWBFile as (baseFolder + nwbFile)
		endif
	endif

	TestCaseEndCommon(name, restartAsyncFramework = 1, zeromqMessageCheck = 0)
End

/// @brief Checks user epochs for consistency
static Function CheckUserEpochsFromChunks(string dev)

	variable i, j, sweepCnt, numEpochs, DAC

	WAVE/Z sweeps = AFH_GetSweeps(dev)

	if(!WaveExists(sweeps))
		PASS()
		return NaN
	endif

	WAVE numericalValues = GetLBNumericalValues(dev)
	WAVE textualValues   = GetLBTextualValues(dev)

	sweepCnt = DimSize(sweeps, ROWS)
	for(i = 0; i < sweepCnt; i += 1)

		WAVE statusHS = GetLastSetting(numericalValues, sweeps[i], "Headstage Active", DATA_ACQUISITION_MODE)

		for(j = 0; j < NUM_HEADSTAGES; j += 1)

			if(!statusHS[j])
				continue
			endif

			DAC = AFH_GetDACFromHeadstage(dev, j)
			WAVE/Z/T userChunkEpochs = EP_GetEpochs(numericalValues, textualValues, sweeps[i], XOP_CHANNEL_TYPE_DAC, DAC, EPOCH_SHORTNAME_USER_PREFIX + PSQ_BASELINE_CHUNK_SHORT_NAME_PREFIX + "[0-9]+", treelevel = EPOCH_USER_LEVEL)

			if(!WaveExists(userChunkEpochs))
				continue
			endif

			CheckUserEpochChunkUniqueness(userChunkEpochs)
			CheckUserEpochChunkNoOverlap(userChunkEpochs)
		endfor
	endfor

	PASS()
End

static Function CheckUserEpochChunkUniqueness(WAVE/T epochInfo)

	variable numEpochs

	numEpochs = DimSize(epochInfo, ROWS)
	Make/FREE/D/N=(numEpochs) chunkNums, chunkRef

	chunkNums = NumberByKey("Index", epochInfo[p][EPOCH_COL_TAGS], "=")
	Sort chunkNums, chunkNums

	chunkRef = p
	CHECK_EQUAL_WAVES(chunkNums, chunkRef) // equal if ascending from 0 with step 1 and thus, unique at the same time
End

static Function CheckUserEpochChunkNoOverlap(WAVE/T epochInfo)

	variable numEpochs, i, j
	variable s1, e1, s2, e2, overlap

	numEpochs = DimSize(epochInfo, ROWS)
	for(i = 0; i < (numEpochs - 1); i += 1)
		s1 = str2num(epochInfo[i][EPOCH_COL_STARTTIME])
		e1 = str2num(epochInfo[i][EPOCH_COL_ENDTIME])
		for(j = i + 1; j < numEpochs; j += 1)
			s2      = str2num(epochInfo[j][EPOCH_COL_STARTTIME])
			e2      = str2num(epochInfo[j][EPOCH_COL_ENDTIME])
			overlap = min(e1, e2) - max(s1, s2)
			CHECK_LE_VAR(overlap, 0) // if overlap is positive the two intervalls intersect
		endfor
	endfor
End

/// @brief Checks epochs for consistency
///        - all epochs must have a short name
///        - no duplicate short names allowed
static Function CheckEpochs(string dev)

	variable sweepCnt, i, j, k, index, channelTypeCount, channelCnt
	string str

	WAVE/Z sweeps = AFH_GetSweeps(dev)

	if(!WaveExists(sweeps))
		PASS()
		return NaN
	endif

	WAVE numericalValues = GetLBNumericalValues(dev)
	WAVE textualValues   = GetLBTextualValues(dev)

	Make/D/FREE channelTypes = {XOP_CHANNEL_TYPE_ADC, XOP_CHANNEL_TYPE_DAC} // note: XOP_CHANNEL_TYPE_TTL not supported by GetLastSettingChannel
	channelTypeCount = DimSize(channelTypes, ROWS)

	sweepCnt = DimSize(sweeps, ROWS)

	for(i = 0; i < sweepCnt; i += 1)
		for(j = 0; j < channelTypeCount; j += 1)
			channelCnt = GetNumberFromType(var = channelTypes[j])
			for(k = 0; k < channelCnt; k += 1)
				[WAVE settings, index] = GetLastSettingChannel(numericalValues, textualValues, sweeps[i], EPOCHS_ENTRY_KEY, k, channelTypes[j], DATA_ACQUISITION_MODE)

				if(WaveExists(settings))
					WAVE/T settingsT = settings
					str = settingsT[index]
					if(!IsEmpty(str))
						WAVE/T epochInfo = EP_EpochStrToWave(str)
						Make/FREE/N=(DimSize(epochInfo, ROWS))/T epNames = EP_GetShortName(epochInfo[p][EPOCH_COL_TAGS])
						// All Epochs should have short names
						FindValue/TXOP=(TXOP_WHOLE_ELEM)/TEXT="" epNames
						CHECK_EQUAL_VAR(V_Value, -1)
						// No duplicate short names should exist
						FindDuplicates/FREE/DT=dupsWave/Z epNames
						if(WaveExists(dupsWave))
							CHECK_EQUAL_VAR(DimSize(dupsWave, ROWS), 0)
						else
							CHECK_EQUAL_VAR(DimSize(epNames, ROWS), 1)
						endif
					endif
				endif

			endfor
		endfor
	endfor

	channelCnt = GetNumberFromType(var = XOP_CHANNEL_TYPE_DAC)
	for(i = 0; i < sweepCnt; i += 1)
		for(j = 0; j < channelCnt; j += 1)
			[WAVE settings, index] = GetLastSettingChannel(numericalValues, textualValues, sweeps[i], EPOCHS_ENTRY_KEY, j, XOP_CHANNEL_TYPE_DAC, DATA_ACQUISITION_MODE)
			if(WaveExists(settings))
				WAVE/T settingsT = settings
				str = settingsT[index]
				CHECK(!IsEmpty(str))
			endif
		endfor
	endfor

	PASS()
End

/// @brief Register the function `<testcase>_REENTRY`
///        as reentry part of the given test case.
///
/// Does nothing if the reentry function does not exist. Supports both plain test cases and multi data test cases
/// accepting string/ref wave arguments and multi-multi data test cases.
///
/// @param testcase function name of the testcase, needs to include a module specification `ABC#` if it's static
Function RegisterReentryFunction(string testcase)

	string                               reentryFuncName    = testcase + "_REENTRY"
	FUNCREF TEST_CASE_PROTO              reentryFuncPlain   = $reentryFuncName
	FUNCREF TEST_CASE_PROTO_MD_STR       reentryFuncMDStr   = $reentryFuncName
	FUNCREF TEST_CASE_PROTO_MD_WVWAVEREF reentryFuncRefWave = $reentryFuncName
	FUNCREF TEST_CASE_PROTO_MD           reentryFuncMDD     = $reentryFuncName

	if(FuncRefIsAssigned(FuncRefInfo(reentryFuncPlain)) || FuncRefIsAssigned(FuncRefInfo(reentryFuncMDStr)) || FuncRefIsAssigned(FuncRefInfo(reentryFuncRefWave)) || FuncRefIsAssigned(FuncRefInfo(reentryFuncMDD)))
		CtrlNamedBackGround DAQWatchdog, start, period=120, proc=WaitUntilDAQDone_IGNORE
		CtrlNamedBackGround TPWatchdog, start, period=120, proc=WaitUntilTPDone_IGNORE
		RegisterUTFMonitor(TASKNAMES + "DAQWatchdog;TPWatchdog", BACKGROUNDMONMODE_AND, reentryFuncName, timeout = 2400, failOnTimeout = 1)
	endif
End

Function LoadStimsets()

	string filename = GetTestStimsetFullFilePath()
	NWB_LoadAllStimsets(filename = filename, overwrite = 1)
End

Function SaveStimsets()

	string filename = GetTestStimsetFullFilePath()
	DeleteFile filename
	MIES_NWB#NWB_ExportAllStimsets(2, filename)
End

Function StopAllBackgroundTasks()

	string list, name, bkgInfo
	variable i, numEntries

	CtrlNamedBackGround _all_, status
	list       = S_info
	numEntries = ItemsInList(list, "\r")

	for(i = 0; i < numEntries; i += 1)
		bkgInfo = StringFromList(i, list, "\r")

		name = StringByKey("NAME", bkgInfo)
		// ignore background watcher panel and testing framework background functions
		if(stringmatch(name, "BW*") || stringmatch(name, "UTF*"))
			continue
		endif

		CtrlNamedBackGround $name, stop
	endfor
End

Function CheckLBIndexCache_IGNORE(string device)

	variable i, j, k, l, numEntries, numSweeps, numRows, numCols, numLayers
	variable entry, sweepNo, entrySourceType
	string setting, msg

	WAVE numericalValues = GetLBNumericalValues(device)
	WAVE textualValues   = GetLBTextualValues(device)

	Make/FREE/WAVE entries = {numericalValues, textualValues}
	numEntries = DimSize(entries, ROWS)
	for(i = 0; i < numEntries; i += 1)
		WAVE values       = entries[i]
		WAVE LBindexCache = GetLBindexCache(values)

		numRows   = DimSize(LBIndexCache, ROWS)
		numCols   = DimSize(LBIndexCache, COLS)
		numLayers = DimSize(LBindexCache, LAYERS)

		Make/FREE/N=(numCols, numLayers) match

		for(j = 0; j < numRows; j += 1)
			for(k = 0; k < numCols; k += 1)
				MultiThread match[][] = LBindexCache[j][p][q]

				if(IsConstant(match, LABNOTEBOOK_UNCACHED_VALUE))
					continue
				endif

				for(l = 0; l < numLayers; l += 1)
					entry = LBindexCache[j][k][l]

					if(entry == LABNOTEBOOK_UNCACHED_VALUE)
						continue
					endif

					sweepNo         = j
					setting         = GetDimLabel(values, COLS, k)
					entrySourceType = ReverseEntrySourceTypeMapper(l)

					WAVE/Z settingsNoCache = MIES_MIESUTILS_LOGBOOK#GetLastSettingNoCache(values, sweepNo, setting, entrySourceType)

					if(!WaveExists(settingsNoCache))
						CHECK_EQUAL_VAR(entry, LABNOTEBOOK_MISSING_VALUE)
						if(entry != LABNOTEBOOK_MISSING_VALUE)
							sprintf msg, "bug: LBN %s, setting %s, sweep %d, entrySourceType %g\r", NameOfWave(values), setting, j, entrySourceType
							FATAL_ERROR(msg)
						endif
					else
						Duplicate/FREE/RMD=[entry][k] values, settings
						Redimension/N=(LABNOTEBOOK_LAYER_COUNT)/E=1 settings

						if(!EqualWaves(settings, settingsNoCache, EQWAVES_DATA))

							Note/K settings, setting

							Duplicate/O settings, root:settings
							Duplicate/O settingsNoCache, root:settingsNoCache

							sprintf msg, "bug: LBN %s, setting %s, sweep %d, entrySourceType %g\r", NameOfWave(values), setting, j, entrySourceType
							FATAL_ERROR(msg)
						endif

						REQUIRE_EQUAL_WAVES(settings, settingsNoCache, mode = WAVE_DATA)
					endif
				endfor
			endfor
		endfor
	endfor
End

Function CheckLBRowCache_IGNORE(string device)

	variable i, j, k, numEntries, numRows, numCols, numLayers, first, last, sweepNo, entrySourceType

	WAVE numericalValues = GetLBNumericalValues(device)
	WAVE textualValues   = GetLBTextualValues(device)

	Make/FREE/WAVE entries = {numericalValues, textualValues}

	numEntries = DimSize(entries, ROWS)
	for(i = 0; i < numEntries; i += 1)
		WAVE values     = entries[i]
		WAVE LBRowCache = GetLBRowCache(values)

		numRows   = DimSize(LBRowCache, ROWS)
		numCols   = DimSize(LBRowCache, COLS)
		numLayers = DimSize(LBRowCache, LAYERS)

		for(j = 0; j < numRows; j += 1)

			Make/FREE/N=(numCols, numLayers) match

			match[][] = LBRowCache[j][p][q]

			if(IsConstant(match, LABNOTEBOOK_GET_RANGE))
				continue
			endif

			for(k = 0; k < numLayers; k += 1)

				if(LBRowCache[j][%first][k] == LABNOTEBOOK_GET_RANGE  \
				   && LBRowCache[j][%last][k] == LABNOTEBOOK_GET_RANGE)
					continue
				endif

				sweepNo         = j
				entrySourceType = ReverseEntrySourceTypeMapper(k)

				first = LABNOTEBOOK_GET_RANGE
				last  = LABNOTEBOOK_GET_RANGE

				WAVE/Z settingsNoCache = MIES_MIESUTILS_LOGBOOK#GetLastSettingNoCache(values, sweepNo, "TimeStamp", entrySourceType, \
				                                                                      first = first, last = last)

				CHECK_EQUAL_VAR(first, LBRowCache[j][%first][k])
				CHECK_EQUAL_VAR(last, LBRowCache[j][%last][k])
			endfor
		endfor
	endfor
End

static Function CheckDashboard(string device, WAVE headstageQC)

	string databrowser, message
	variable numEntries, i, state

	databrowser = DB_FindDataBrowser(device)
	DFREF    dfr      = BSP_GetFolder(databrowser, MIES_BSP_PANEL_FOLDER)
	WAVE/Z/T listWave = GetAnaFuncDashboardListWave(dfr)
	CHECK_WAVE(listWave, TEXT_WAVE)

	// Check that we have acquired some sweeps
	WAVE   numericalValues = GetLBNumericalValues(device)
	WAVE/Z sweeps          = AFH_GetSweeps(device)
	CHECK_WAVE(sweeps, NUMERIC_WAVE)

	numEntries = GetNumberFromWaveNote(listWave, NOTE_INDEX)
	CHECK_GT_VAR(numEntries, 0)

	for(i = 0; i < numEntries; i += 1)
		message = listWave[i][%Result]
		CHECK_PROPER_STR(message)
		state = !cmpstr(message, DASHBOARD_PASSING_MESSAGE)
		CHECK_EQUAL_VAR(state, headstageQC[i])

		if(!headstageQC[i])
			INFO("Index=%g, state=%g, message=%s", n0 = i, n1 = state, s0 = message)
			CHECK_EQUAL_VAR(strsearch(message, DAQ_STOPPED_EARLY_LEGACY_MSG, 0), -1)
		endif
	endfor
End

static Function CheckAnaFuncVersion(string device, variable type)

	string key
	variable refVersion, version, sweepNo, i, idx

	WAVE numericalValues = GetLBNumericalValues(device)
	key     = CreateAnaFuncLBNKey(type, FMT_LBN_ANA_FUNC_VERSION, query = 1)
	sweepNo = 0

	// check that at least one headstage has the desired analysis function version set
	for(i = 0; i < NUM_HEADSTAGES; i += 1)
		WAVE/Z versions = GetLastSettingSCI(numericalValues, sweepNo, key, i, UNKNOWN_MODE)
		if(!WaveExists(versions))
			continue
		endif

		refVersion = GetAnalysisFunctionVersion(type)
		idx        = GetRowIndex(versions, val = refVersion)
		CHECK_GE_VAR(idx, 0)
		return NaN
	endfor

	FAIL()
End

Function CommonAnalysisFunctionChecks(string device, variable sweepNo, WAVE headstageQC)

	string key
	variable type, DAC, index

	CHECK_EQUAL_VAR(GetSetVariable(device, "SetVar_Sweep"), sweepNo + 1)
	CHECK_EQUAL_VAR(AFH_GetLastSweepAcquired(device), sweepNo)

	WAVE textualValues = GetLBTextualValues(device)
	key = StringFromList(GENERIC_EVENT, EVENT_NAME_LIST_LBN)

	WAVE/Z/T anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	REQUIRE_WAVE(anaFuncs, TEXT_WAVE)

	Make/N=(LABNOTEBOOK_LAYER_COUNT)/FREE anaFuncTypes = MapAnaFuncToConstant(anaFuncs[p])

	// map invalid/test analysis function value to NaN
	anaFuncTypes[] = (anaFuncTypes[p] == INVALID_ANALYSIS_FUNCTION || anaFuncTypes[p] == TEST_ANALYSIS_FUNCTION) ? NaN : anaFuncTypes[p]

	WAVE/Z anaFuncTypesWoNaN = ZapNaNs(anaFuncTypes)
	REQUIRE_WAVE(anaFuncTypesWoNaN, NUMERIC_WAVE)

	WAVE/Z uniqueAnaFuncTypes = GetUniqueEntries(anaFuncTypesWoNaN)
	CHECK_WAVE(uniqueAnaFuncTypes, NUMERIC_WAVE)
	CHECK_EQUAL_VAR(DimSize(uniqueAnaFuncTypes, ROWS), 1)

	type = uniqueAnaFuncTypes[0]

	CheckAnaFuncVersion(device, type)
	CheckDashboard(device, headstageQC)
	CheckPublishedMessage(device, type)

	CheckUserEpochsFromChunks(device)

	CheckForOtherUserLBNKeys(device, type)
	CheckRangeOfUserLabnotebookKeys(device, type, sweepNo)
	CheckDAStimulusSets(device, sweepNo, type)

	TestEpochRecreation(device, sweepNo)
End

/// Used for patch seq analysis functions and NextStimSetName/NextIndexingEndStimSetName analysis parameters
static Function CheckDAStimulusSets(string device, variable sweepNo, variable type)

	string stimset, stimsetIndexEnd, previousStimset, expected, key, names, params
	variable setPassed, nextStimsetPresent, indexingEndPresent, indexingState

	WAVE textualValues   = GetLBTextualValues(device)
	WAVE numericalValues = GetLBNumericalValues(device)

	params = LBN_GetAnalysisFunctionParameters(textualValues, sweepNo, PSQ_TEST_HEADSTAGE)

	names = AFH_GetListOfAnalysisParamNames(params)

	nextStimsetPresent = WhichListItem("NextStimsetName", names, ";", 0, 0) != -1
	indexingEndPresent = WhichListItem("NextIndexingEndStimsetName", names, ";", 0, 0) != -1

	if(!nextStimsetPresent && !indexingEndPresent)
		PASS()
		return NaN
	endif

	key       = CreateAnaFuncLBNKey(type, PSQ_FMT_LBN_SET_PASS, query = 1)
	setPassed = GetLastSettingIndepSCI(numericalValues, sweepNo, key, PSQ_TEST_HEADSTAGE, UNKNOWN_MODE)
	CHECK(IsFinite(setPassed))

	WAVE/Z/T results = GetLastSetting(textualValues, sweepNo, "Stim Wave Name", DATA_ACQUISITION_MODE)
	CHECK_WAVE(results, TEXT_WAVE)
	previousStimset = results[PSQ_TEST_HEADSTAGE]
	CHECK_PROPER_STR(previousStimset)

	[stimset, stimsetIndexEnd] = GetStimsets_IGNORE(device)

	if(setPassed)
		expected = "StimulusSetA_DA_0"
		CHECK_EQUAL_STR(stimset, expected)

		if(indexingEndPresent)
			expected      = "StimulusSetB_DA_0"
			indexingState = 1

		else
			indexingState = 0
			expected      = NONE
		endif

		CHECK_EQUAL_STR(stimsetIndexEnd, expected)
		CHECK_EQUAL_VAR(DAG_GetNumericalValue(device, "Check_DataAcq_Indexing"), indexingState)
	else
		expected = previousStimset
		CHECK_EQUAL_STR(stimset, expected)
		expected = NONE
		CHECK_EQUAL_STR(stimsetIndexEnd, expected)
	endif
End

static Function [string stimset, string stimsetIndexEnd] GetStimsets_IGNORE(string device)

	variable DAC
	string ctrl0, ctrl1

	DAC = AFH_GetDACFromHeadstage(device, PSQ_TEST_HEADSTAGE)
	CHECK(IsFinite(DAC))

	ctrl0 = GetSpecialControlLabel(CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE)
	ctrl1 = GetSpecialControlLabel(CHANNEL_TYPE_DAC, CHANNEL_CONTROL_INDEX_END)

	return [DAG_GetTextualValue(device, ctrl0, index = DAC), DAG_GetTextualValue(device, ctrl1, index = DAC)]
End

static Function CheckForOtherUserLBNKeys(string device, variable type)

	string prefix

	WAVE numericalValues = GetLBNumericalValues(device)
	WAVE textualValues   = GetLBTextualValues(device)

	WAVE/Z entries = MIES_LBV#LBV_GetAllLogbookParamNames(textualValues, numericalValues)
	CHECK_WAVE(entries, TEXT_WAVE)

	// check that all user entries are from our analysis function
	WAVE/Z allUserEntries = GrepTextWave(entries, LABNOTEBOOK_USER_PREFIX + ".*")

	// remove legacy entries
	RemoveTextWaveEntry1D(allUserEntries, LABNOTEBOOK_USER_PREFIX + LBN_DELTA_I)
	RemoveTextWaveEntry1D(allUserEntries, LABNOTEBOOK_USER_PREFIX + LBN_DELTA_V)
	RemoveTextWaveEntry1D(allUserEntries, LABNOTEBOOK_USER_PREFIX + LBN_RESISTANCE_FIT)
	RemoveTextWaveEntry1D(allUserEntries, LABNOTEBOOK_USER_PREFIX + LBN_RESISTANCE_FIT_ERR)

	prefix = CreateAnaFuncLBNKey(type, "%s", query = 1)
	WAVE/Z ourUserEntries = GrepTextWave(entries, prefix + ".*")

	CHECK_EQUAL_TEXTWAVES(allUserEntries, ourUserEntries)
End

static Function CheckRangeOfUserLabnotebookKeys(string device, variable type, variable sweepNoRef)

	variable numSweeps, sweepNo, numEntries, i, j, k
	variable result, col, value
	string unit, entry

	WAVE numericalKeys = GetLBNumericalKeys(device)
	WAVE textualKeys   = GetLBTextualKeys(device)

	WAVE numericalValues = GetLBNumericalValues(device)
	WAVE textualValues   = GetLBTextualValues(device)

	WAVE/Z entries = MIES_LBV#LBV_GetAllLogbookParamNames(textualValues, numericalValues)
	CHECK_WAVE(entries, TEXT_WAVE)

	WAVE/Z/T allUserEntries = GrepTextWave(entries, LABNOTEBOOK_USER_PREFIX + ".*")
	CHECK_WAVE(allUserEntries, TEXT_WAVE)

	WAVE/Z sweeps = AFH_GetSweepsFromSameRACycle(numericalValues, sweepNoRef)
	CHECK_WAVE(sweeps, NUMERIC_WAVE)

	Make/T/FREE entriesWithoutUnit = {FMT_LBN_ANA_FUNC_VERSION, PSQ_FMT_LBN_SE_TESTPULSE_GROUP,                                              \
	                                  PSQ_FMT_LBN_STEPSIZE, PSQ_FMT_LBN_STEPSIZE_FUTURE, PSQ_FMT_LBN_SPIKE_COUNT,                            \
	                                  PSQ_FMT_LBN_CR_BOUNDS_ACTION, PSQ_FMT_LBN_INITIAL_SCALE, PSQ_FMT_LBN_FINAL_SCALE,                      \
	                                  MSQ_FMT_LBN_INITIAL_SCALE, MSQ_FMT_LBN_FINAL_SCALE, MSQ_FMT_LBN_IDEAL_SPIKE_COUNTS,                    \
	                                  MSQ_FMT_LBN_FAILED_PULSE_LEVEL, MSQ_FMT_LBN_RERUN_TRIAL, PSQ_FMT_LBN_VM_FULL_AVG_RDIFF,                \
	                                  PSQ_FMT_LBN_AR_RESISTANCE_RATIO, PSQ_FMT_LBN_DA_AT_MIN_DASCALE_NORM, PSQ_FMT_LBN_DA_AT_MAX_DASCALE_NORM}

	entriesWithoutUnit = CreateAnaFuncLBNKey(type, entriesWithoutUnit[p], query = 1)

	numSweeps  = DimSize(sweeps, ROWS)
	numEntries = DimSize(allUserEntries, ROWS)
	for(i = 0; i < numSweeps; i += 1)
		for(j = 0; j < numEntries; j += 1)
			sweepNo = sweeps[i]
			entry   = allUserEntries[j]

			WAVE/Z settingNum = GetLastSetting(numericalValues, sweepNo, entry, UNKNOWN_MODE)
			WAVE/Z settingTxt = GetLastSetting(textualValues, sweepNo, entry, UNKNOWN_MODE)

			if(!WaveExists(settingNum) && !WaveExists(settingTxt))
				PASS()
				continue
			endif

			if(WaveExists(settingTxt))
				// textual entries don't have units
				[result, unit, col] = LBN_GetEntryProperties(numericalKeys, entry)
				CHECK_EQUAL_VAR(result, 1)
				CHECK_EMPTY_STR(unit)

				// we can not check anything more
				continue
			endif

			CHECK_WAVE(settingNum, NUMERIC_WAVE)

			// check that we have a unit for most entries
			[result, unit, col] = LBN_GetEntryProperties(numericalKeys, entry)
			CHECK_EQUAL_VAR(result, 0)

			if(GetRowIndex(entriesWithoutUnit, str = entry) >= 0)
				CHECK_EMPTY_STR(unit)
			else
				CHECK_PROPER_STR(unit)

				for(k = 0; k < LABNOTEBOOK_LAYER_COUNT; k += 1)
					value = settingNum[k]
					if(!IsNaN(value))
						break
					endif
				endfor

				// allow inf for this one only
				if(!cmpstr(entry, LABNOTEBOOK_USER_PREFIX + LBN_RESISTANCE_FIT_ERR))
					if(value == Inf)
						continue
					endif
				endif

				INFO("sweepNo=%g, entry=%s, unit=%s\r", n0 = sweepNo, s0 = entry, s1 = unit)

				// do a coarse range check
				strswitch(unit)
					case "On/Off":
						// baseline QC entries write -1 for "check not done"
						Make/FREE allowedValues = {0, 1, -1}
						FindValue/V=(value) allowedValues
						CHECK_GE_VAR(V_Value, 0)
						break
					case "Amperes": // fallthrough
					case "A":
						value = abs(value)
						CHECK_GT_VAR(value, 0)
						CHECK_LE_VAR(value, 4000e-12)
						break
					case "Volts": // fallthrough
					case "Volt": // fallthrough
					case "V":
						CHECK_GE_VAR(value, -0.1)
						CHECK_LE_VAR(value, 1)
						break
					case "Ohm": // fallthrough
					case "Ω":
						value = abs(value)
						CHECK_GT_VAR(value, 0)
						CHECK_LE_VAR(value, 12.5e9)
						break
					case "ms":
						CHECK_GE_VAR(value, 0)
						CHECK_LE_VAR(value, 15000)
						break
					case "% of Hz/pA":
						value = abs(value)
						CHECK_GE_VAR(value, 0)
						CHECK_LE_VAR(value, 1e4)
						break
					case "Hz":
						if(!cmpstr(entry, "USER_DA Scale f-I offset") || !cmpstr(entry, "USER_DA Scale f-I offset for DAScale estimation"))
							CHECK_GE_VAR(value, -1e6)
							CHECK_LE_VAR(value, 1e6)
						else
							CHECK_GT_VAR(value, 0)
							if(value != PSQ_TEST_VERY_LARGE_FREQUENCY)
								CHECK_LE_VAR(value, 1e6)
							endif
						endif
						break
					default:
						printf "missing %s with unit %s\r", entry, unit
						CHECK(0)
						break
				endswitch
			endif
		endfor
	endfor
End

Function CheckPublishedMessage(string device, variable type)

	string   expectedFilter
	variable jsonID

	switch(type)
		case PSQ_PIPETTE_BATH:
			expectedFilter = ANALYSIS_FUNCTION_PB
			break
		case PSQ_SEAL_EVALUATION:
			expectedFilter = ANALYSIS_FUNCTION_SE
			break
		case PSQ_TRUE_REST_VM:
			expectedFilter = ANALYSIS_FUNCTION_VM
			break
		case PSQ_ACC_RES_SMOKE:
			expectedFilter = ANALYSIS_FUNCTION_AR
			break
		default:
			PASS()
			return NaN
	endswitch

	jsonID = FetchAndParseMessage(expectedFilter)
	CHECK_GE_VAR(jsonID, 0)
	JSON_Release(jsonID)
End

static Function TestSweepReconstruction_IGNORE(string device)

	variable i, j, numEntries, sweepNo, numChannels
	string list, nameRecon, nameOrig

	WAVE numericalValues = GetLBTextualValues(device)

	WAVE/Z sweeps = AFH_GetSweeps(device)

	if(!WaveExists(sweeps))
		// no sweeps acquired, so we can't test anything
		PASS()
		return NaN
	endif

	DFREF deviceDFR = GetDeviceDataPath(device)

	DuplicateDataFolder/O=1 deviceDFR, deviceDataBorkedUp
	DFREF deviceDataBorkedUp = deviceDataBorkedUp

	// kill all X_XXXX folders with single sweep channels
	list = GetListOfObjects(deviceDataBorkedUp, ".*", typeFlag = COUNTOBJECTS_DATAFOLDER, fullPath = 1)
	CallFunctionForEachListItem_TS(KillOrMoveToTrashPath, list)

	// generate sweep channel waves in X_XXXX folders in deviceDataBorkedUp from original sweeps in deviceDFR
	numEntries = DimSize(sweeps, ROWS)
	for(i = 0; i < numEntries; i += 1)
		sweepNo = sweeps[i]

		WAVE sweepWave  = GetSweepWave(device, sweepNo)
		WAVE configWave = GetConfigWave(sweepWave)

		DFREF singleSweepDFR = GetSingleSweepFolder(deviceDataBorkedUp, sweepNo)

		SplitAndUpgradeSweep(numericalValues, sweepNo, sweepWave, configWave, TTL_RESCALE_OFF, 1, targetDFR = singleSweepDFR)
	endfor

	// delete sweep and config waves
	list = GetListOfObjects(deviceDataBorkedUp, ".*", typeFlag = COUNTOBJECTS_WAVES, fullPath = 1)
	CallFunctionForEachListItem_TS(KillOrMoveToTrashPath, list)

	// Recreate sweep as 2D wave and config
	RecreateMissingSweepAndConfigWaves(device, deviceDataBorkedUp)

	// compare the 2D sweep and config waves in deviceDFR and reconstructed
	DFREF reconstructed = root:reconstructed

	WAVE/T wavesReconstructed = ListToTextWave(GetListOfObjects(reconstructed, ".*", typeFlag = COUNTOBJECTS_WAVES, fullPath = 1), ";")
	WAVE/T wavesOriginal      = ListToTextWave(GetListOfObjects(deviceDFR, ".*", typeFlag = COUNTOBJECTS_WAVES, fullPath = 1), ";")

	Sort wavesReconstructed, wavesReconstructed
	Sort wavesOriginal, wavesOriginal

	CHECK_GT_VAR(DimSize(sweeps, ROWS), 0)
	CHECK_EQUAL_VAR(DimSize(wavesReconstructed, ROWS), numEntries * 3)
	CHECK_EQUAL_VAR(DimSize(wavesOriginal, ROWS), numEntries * 3)

	// loop over all waves and compare them
	numEntries = DimSize(wavesReconstructed, ROWS)
	for(i = 0; i < numEntries; i += 1)
		WAVE/Z wvReconstructed = $wavesReconstructed[i]
		WAVE/Z wvOriginal      = $wavesOriginal[i]
		CHECK_WAVE(wvReconstructed, NORMAL_WAVE)
		CHECK_WAVE(wvOriginal, NORMAL_WAVE)

		nameRecon = NameOfWave(wvReconstructed)
		nameOrig  = NameOfWave(wvOriginal)
		CHECK_EQUAL_STR(nameRecon, nameOrig)

		if(GrepString(nameRecon, DATA_CONFIG_REGEXP))
			CHECK_WAVE(wvReconstructed, NUMERIC_WAVE)
			CHECK_WAVE(wvOriginal, NUMERIC_WAVE)

			// set offset to zero for comparison
			// only data acquired with PSQ_Ramp has offset != 0
			wvReconstructed[][%Offset] = 0
			wvOriginal[][%Offset]      = 0
		else
			CHECK_WAVE(wvReconstructed, TEXT_WAVE)
			CHECK_WAVE(wvOriginal, TEXT_WAVE)
			numChannels = DimSize(wvReconstructed, ROWS)
			for(j = 0; j < numChannels; j += 1)
				WAVE channelRecon = ResolveSweepChannel(wvReconstructed, j)
				WAVE channelOrig  = ResolveSweepChannel(wvOriginal, j)
				CHECK_EQUAL_WAVES(channelRecon, channelOrig)
			endfor
		endif
	endfor

	KillDataFolder/Z deviceDataBorkedUp
End

Function [string baseFolder, string nwbFile] GetUniqueNWBFileForExport(variable nwbVersion)

	string suffix

	ASSERT(EnsureValidNWBVersion(nwbVersion), "Invalid nwb version")

	PathInfo home
	REQUIRE(V_flag)
	baseFolder = S_path

	sprintf suffix, "-V%d.nwb", nwbVersion

	nwbFile = UniqueFileOrFolder("home", GetExperimentName(), suffix = suffix)

	return [baseFolder, nwbFile]
End

Function/S GetExperimentNWBFileForExport()

	string experimentName

	PathInfo home
	CHECK(V_Flag)

	experimentName = GetExperimentName()
	CHECK(cmpstr(experimentName, UNTITLED_EXPERIMENT))

	return S_path + experimentName + ".nwb"
End

Function CheckPSQChunkTimes(string dev, WAVE chunkTimes, [variable sweep])

	string shortNameFormat

	shortNameFormat = EPOCH_SHORTNAME_USER_PREFIX + PSQ_BASELINE_CHUNK_SHORT_NAME_PREFIX + "%d"

	if(ParamIsDefault(sweep))
		CheckUserEpochs(dev, chunkTimes, shortNameFormat)
	else
		CheckUserEpochs(dev, chunkTimes, shortNameFormat, sweep = sweep)
	endif
End

/// @brief Check the start/end positions of the given user epochs
///
/// @param dev              device
/// @param times            epoch starting/end times [ms]
/// @param shortNameFormat  short name pattern must contain `%d` (and only that `%`-pattern) for multiple epochs.
///                         Must not be present for single epochs.
/// @param sweep            [optional] Allows to limit checking only a specific sweep,
///                         by default all sweeps in the stimset cycle are checked
/// @param ignoreIncomplete [optional, defaults to false] ignore epochs from incomplete sweeps
Function CheckUserEpochs(string dev, WAVE times, string shortNameFormat, [variable sweep, variable ignoreIncomplete])

	variable size, numChunks, index, expectedChunkCnt, sweepCnt, DAC
	variable i, j, k
	variable startTime, endTime, startRef, endRef
	string str, regexp

	sweep            = ParamIsDefault(sweep) ? NaN : sweep
	ignoreIncomplete = ParamIsDefault(ignoreIncomplete) ? 0 : !!ignoreIncomplete

	size = DimSize(times, ROWS)
	REQUIRE(IsEven(size))
	expectedChunkCnt = size >> 1

	WAVE/Z sweeps = AFH_GetSweeps(dev)

	if(!WaveExists(sweeps))
		FAIL()
		return NaN
	endif

	WAVE numericalValues = GetLBNumericalValues(dev)
	WAVE textualValues   = GetLBTextualValues(dev)

	sweepCnt = DimSize(sweeps, ROWS)

	for(i = 0; i < sweepCnt; i += 1)
		if(!IsNaN(sweep) && sweep != sweeps[i])
			continue
		endif

		WAVE statusHS = GetLastSetting(numericalValues, sweeps[i], "Headstage Active", DATA_ACQUISITION_MODE)

		for(j = 0; j < NUM_HEADSTAGES; j += 1)

			if(!statusHS[j])
				continue
			endif

			DAC = AFH_GetDACFromHeadstage(dev, j)
			REQUIRE(IsFinite(DAC))

			WAVE/Z/T unacquiredEpoch = EP_GetEpochs(numericalValues, textualValues, sweeps[i], XOP_CHANNEL_TYPE_DAC, DAC, "UA")

			if(ignoreIncomplete)
				CHECK_WAVE(unacquiredEpoch, TEXT_WAVE)
				continue
			endif

			// also works with full names without %d being present
			regexp = "^" + ReplaceString("%d", shortNameFormat, "[0-9]+") + "$"
			WAVE/Z/T userChunkEpochs = EP_GetEpochs(numericalValues, textualValues, sweeps[i], XOP_CHANNEL_TYPE_DAC, DAC, regexp, treelevel = EPOCH_USER_LEVEL)
			if(!WaveExists(userChunkEpochs))
				continue
			endif

			numChunks = DimSize(userChunkEpochs, ROWS)

			CHECK_EQUAL_VAR(DimSize(times, ROWS) / 2, numChunks)

			Make/FREE/T/N=(numChunks) epochShortNames = EP_GetShortName(userChunkEpochs[p][EPOCH_COL_TAGS])
			for(k = 0; k < numChunks; k += 1)
				if(numChunks == 1 && strsearch(shortNameFormat, "%d", 0) == -1)
					str = shortNameFormat
				else
					sprintf str, shortNameFormat, k
				endif

				FindValue/TEXT=str/TXOP=(TXOP_WHOLE_ELEM) epochShortNames
				index = V_Value
				CHECK_NEQ_VAR(index, -1)
				startTime = str2num(userChunkEpochs[k][EPOCH_COL_STARTTIME])
				endTime   = str2num(userChunkEpochs[k][EPOCH_COL_ENDTIME])
				startRef  = times[k << 1] * MILLI_TO_ONE
				endRef    = times[(k << 1) + 1] * MILLI_TO_ONE

				if(CheckIfSmall(startRef, tol = 1e-12))
					CHECK_SMALL_VAR(startTime)
				else
					CHECK_CLOSE_VAR(startTime, startRef, tol = 0.0005)
				endif

				CHECK_CLOSE_VAR(endTime, endRef, tol = 0.0005)
			endfor
		endfor
	endfor

	// In the case we did not reached the inner checks of the upper loop
	CHECK_EQUAL_VAR(numChunks, expectedChunkCnt)
End

Function CheckDAQStopReason(string device, variable stopReason, [variable sweepNo])

	string key

	key = "DAQ stop reason"

	WAVE   numericalValues = GetLBNumericalValues(device)
	WAVE/Z sweeps          = GetSweepsWithSetting(numericalValues, key)
	CHECK_WAVE(sweeps, NUMERIC_WAVE)
	CHECK_GE_VAR(DimSize(sweeps, ROWS), 1)

	if(ParamIsDefault(sweepNo))
		sweepNo = sweeps[0]
	endif

	WAVE/Z settings = GetLastSetting(numericalValues, sweepNo, key, UNKNOWN_MODE)
	CHECK_WAVE(settings, NUMERIC_WAVE)
	CHECK_EQUAL_VAR(settings[INDEP_HEADSTAGE], stopReason)
End

Function CheckStartStopMessages(string mode, string state)

	string actual, expected
	variable jsonID

	jsonID   = FetchAndParseMessage(DAQ_TP_STATE_CHANGE_FILTER)
	actual   = JSON_GetString(jsonID, "/" + mode)
	expected = state
	CHECK_EQUAL_STR(actual, expected)
	JSON_Release(jsonID)
End

Function GetMinSamplingInterval([string unit])

	variable factor

	if(ParamIsDefault(unit))
		FAIL()
	endif

	if(cmpstr(unit, "µs"))
		factor = 1
	elseif(cmpstr(unit, "ms"))
		factor = 1000
	else
		FAIL()
	endif

#ifdef TESTS_WITH_NI_HARDWARE
	return factor * HARDWARE_NI_DAC_MIN_SAMPINT
#elif defined(TESTS_WITH_SUTTER_HARDWARE)
	return factor * HARDWARE_SU_MIN_SAMPINT_ADC
#else
	return factor * HARDWARE_ITC_MIN_SAMPINT
#endif // TESTS_WITH_NI_HARDWARE
End

Function StartFakeThreadMonitor_IGNORE(string device, variable fixedFifoPos)

	variable deviceID, i, numChannels, fifoPosLatest

	deviceID = ROVar(GetDAQDeviceID(device))
	NVAR tgID = $GetThreadGroupIDFifo(device)
	fifoPosLatest = TS_GetNewestFromThreadQueue(tgID, "fifoPos")
	TFH_StopFifoDaemon(HARDWARE_ITC_DAC, deviceID)

	if(IsFinite(fifoPosLatest) && fixedFifoPos > 0)
		fixedFifoPos = fifoPosLatest
	endif

	NVAR tgID = $GetThreadGroupIDFifo(device)
	tgID = ThreadGroupCreate(1)

#ifdef THREADING_DISABLED
	BUG("Fake thread monitor and no threading is not supported.")
#else
	ThreadStart tgID, 0, FakeThreadMonitor_IGNORE(fixedFifoPos)
#endif // THREADING_DISABLED
End

threadsafe static Function FakeThreadMonitor_IGNORE(variable fixedFifoPos)

	do
		DFREF dfr = ThreadGroupGetDFR(MAIN_THREAD, 100)

		if(DataFolderExistsDFR(dfr))
			break
		endif

		TS_ThreadGroupPutVariable(MAIN_THREAD, "fifoPos", fixedFifoPos)
	while(1)
End

Function UseFakeFIFOThreadWithTimeout_IGNORE(STRUCT WMBackgroundStruct &s)

	variable fifoPos

	SVAR   devices = $GetLockedDevices()
	string device  = StringFromList(0, devices)

	NVAR dataAcqRunMode = $GetDataAcqRunMode(device)

	fifoPos = ROVar(GetFifoPosition(device))

	if(IsFinite(dataAcqRunMode) && dataAcqRunMode != DAQ_NOT_RUNNING && fifoPos > 10000)
		StartFakeThreadMonitor_IGNORE(device, HARDWARE_ITC_FIFO_ERROR)

		return 1
	endif

	return 0
End

Function UseFakeFIFOThreadBeingStuck_IGNORE(STRUCT WMBackgroundStruct &s)

	variable fifoPos

	SVAR   devices = $GetLockedDevices()
	string device  = StringFromList(0, devices)

	NVAR dataAcqRunMode = $GetDataAcqRunMode(device)

	fifoPos = ROVar(GetFifoPosition(device))

	if(IsFinite(dataAcqRunMode) && dataAcqRunMode != DAQ_NOT_RUNNING && fifoPos > 10000)
		StartFakeThreadMonitor_IGNORE(device, fifoPos)

		return 1
	endif

	return 0
End
