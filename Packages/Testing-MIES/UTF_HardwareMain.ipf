#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma ModuleName=HardwareMain

#include "MIES_include"
#include "unit-testing"

// If the next line fails, you are including the MIES created
// "UserAnalysisFunctions.ipf" and not the one from "Packages/Testing-MIES"
#include "UserAnalysisFunctions", version >= 10000

#include "UTF_AnalysisFunctionManagement"
#include "UTF_AnalysisFunctionParameters"
#include "UTF_VeryBasicHardwareTests"
#include "UTF_DAEphys"
#include "UTF_BasicHardwareTests"
#include "UTF_PatchSeqDAScale"
#include "UTF_PatchSeqSquarePulse"
#include "UTF_PatchSeqRheobase"
#include "UTF_PatchSeqRamp"
#include "UTF_ReachTargetVoltage"
#include "UTF_MultiPatchSeqFastRheoEstimate"
#include "UTF_MultiPatchSeqDAScale"
#include "UTF_MultiPatchSeqSpikeControl"
#include "UTF_SetControls"
#include "UTF_TestNWBExportV1"
#include "UTF_TestNWBExportV2"
#include "UTF_Epochs"
#include "UTF_HelperFunctions"

StrConstant LIST_OF_TESTS_WITH_SWEEP_ROLLBACK = "TestSweepRollback"

// Entry point for UTF
Function run()
	return RunWithOpts()
End

// Examples:
// - RunWithOpts()
// - RunWithOpts(testsuite = "UTF_Epochs.ipf")
// - RunWithOpts(testcase = "EP_EpochTest7")
Function RunWithOpts([string testcase, string testsuite, variable allowdebug])

	variable debugMode
	string list = ""
	string name = "MIES with Hardware"

	// speeds up testing to start with a fresh copy
	KillWindow/Z HistoryCarbonCopy
	DisableDebugOutput()

	if(ParamIsDefault(allowdebug))
		debugMode = 0
	else
		debugMode = IUTF_DEBUG_FAILED_ASSERTION | IUTF_DEBUG_ENABLE | IUTF_DEBUG_ON_ERROR | IUTF_DEBUG_NVAR_SVAR_WAVE
	endif

	if(ParamIsDefault(testcase))
		testcase = ""
	endif

	list = AddListItem("UTF_VeryBasicHardwareTests.ipf", list, ";", inf)
	list = AddListItem("UTF_BasicHardwareTests.ipf", list, ";", inf)
	list = AddListItem("UTF_DAEphys.ipf", list, ";", inf)
	list = AddListItem("UTF_Epochs.ipf", list, ";", inf)
	list = AddListItem("UTF_AnalysisFunctionManagement.ipf", list, ";", inf)
	list = AddListItem("UTF_AnalysisFunctionParameters.ipf", list, ";", inf)
	// analysis functions
	list = AddListItem("UTF_SetControls.ipf", list, ";", inf)
	list = AddListItem("UTF_PatchSeqDAScale.ipf", list, ";", inf)
	list = AddListItem("UTF_PatchSeqSquarePulse.ipf", list, ";", inf)
	list = AddListItem("UTF_PatchSeqRheobase.ipf", list, ";", inf)
	list = AddListItem("UTF_PatchSeqRamp.ipf", list, ";", inf)
	list = AddListItem("UTF_ReachTargetVoltage.ipf", list, ";", inf)
	list = AddListItem("UTF_MultiPatchSeqFastRheoEstimate.ipf", list, ";", inf)
	list = AddListItem("UTF_MultiPatchSeqDAScale.ipf", list, ";", inf)
	list = AddListItem("UTF_MultiPatchSeqSpikeControl.ipf", list, ";", inf)

	if(ParamIsDefault(testsuite))
		testsuite = list
	else
		// do nothing
	endif

	if(IsEmpty(testcase))
		RunTest(testsuite, name = name, enableJU = 1, debugMode= debugMode)
	else
		RunTest(testsuite, name = name, enableJU = 1, debugMode= debugMode, testcase = testcase)
	endif
End

Function/WAVE DeviceNameGeneratorMD1()

	string devList = ""
	string lblList = ""
	variable i

#ifdef TESTS_WITH_NI_HARDWARE

#ifdef TESTS_WITH_YOKING
#define *** NI Hardware has no Yoking support
#else
	devList = AddListItem("Dev1", devList, ":")
	lblList = AddListItem("NI", lblList)
#endif

#endif

#ifdef TESTS_WITH_ITC18USB_HARDWARE

#ifdef TESTS_WITH_YOKING
#define *** ITC18USB has no Yoking support
#else
	devList = AddListItem("ITC18USB_dev_0", devList, ":")
	lblList = AddListItem("ITC", lblList)
#endif

#endif

#ifdef TESTS_WITH_ITC1600_HARDWARE

#ifdef TESTS_WITH_YOKING
	devList = AddListItem("ITC1600_dev_0;ITC1600_dev_1", devList, ":")
	lblList = AddListItem("ITC600_YOKED", lblList)
#else
	devList = AddListItem("ITC1600_dev_0", devList, ":")
	lblList = AddListItem("ITC600", lblList)
#endif

#endif

	WAVE data = ListToTextWave(devList, ":")
	for(i = 0; i < DimSize(data, ROWS); i += 1)
		SetDimLabel ROWS, i, $StringFromList(i, lblList), data
	endfor

	return data
End

Function/WAVE DeviceNameGeneratorMD0()

#ifdef TESTS_WITH_NI_HARDWARE
	// NI Hardware has no single device support
	Make/FREE/T/N=0 data
	return data
#endif

#ifdef TESTS_WITH_ITC18USB_HARDWARE

#ifdef TESTS_WITH_YOKING
	// Yoking with ITC hardware is only supported in multi device mode
	Make/FREE/T/N=0 data
	return data
#else
	return DeviceNameGeneratorMD1()
#endif

#endif

#ifdef TESTS_WITH_ITC1600_HARDWARE

#ifdef TESTS_WITH_YOKING
	// Yoking with ITC hardware is only supported in multi device mode
	Make/FREE/T/N=0 data
	return data
#else
	return DeviceNameGeneratorMD1()
#endif

#endif

End

Function TEST_BEGIN_OVERRIDE(name)
	string name

	NVAR interactiveMode = $GetInteractiveMode()
	interactiveMode = 0
	variable/G root:interactiveMode = interactiveMode

//	DisableDebugOutput()
//	EnableDebugoutput()

	// cache the version string
	SVAR miesVersion = $GetMIESVersion()
	string/G root:miesVersion = miesVersion

	// cache the device lists
	string/G root:ITCDeviceList = DAP_GetITCDeviceList()
	string/G root:NIDeviceList = DAP_GetNIDeviceList()

	NWB_LoadAllStimsets(filename = GetFolder(FunctionPath("")) + "_2017_09_01_192934-compressed.nwb", overwrite = 1)
	KillDataFolder/Z root:WaveBuilder
	DuplicateDataFolder	root:MIES:WaveBuilder, root:WaveBuilder
	KillDataFolder/Z root:WaveBuilder:SavedStimulusSets
End

Function TEST_CASE_BEGIN_OVERRIDE(name)
	string name

	variable numWindows, i
	string list, reentryFuncName, win

	// cut off multi data suffix
	name = StringFromList(0, name, ":")

	RegisterReentryFunction(name)

	AdditionalExperimentCleanupAfterTest()

	GetMiesPath()
	DuplicateDataFolder	root:WaveBuilder, root:MIES:WaveBuilder
	REQUIRE(DataFolderExists("root:MIES:WaveBuilder:SavedStimulusSetParameters:DA"))

	SVAR miesVersion = root:miesVersion
	string/G $(GetMiesPathAsString() + ":version") = miesVersion

	NVAR interactiveMode = root:interactiveMode
	variable/G $(GetMiesPathAsString() + ":interactiveMode") = interactiveMode

	GetDAQDevicesFolder()

	SVAR ITCDeviceList = root:ITCDeviceList
	string/G $(GetDAQDevicesFolderAsString() + ":ITCDeviceList") = ITCDeviceList

	SVAR NIDeviceList = root:NIDeviceList
	string/G $(GetDAQDevicesFolderAsString() + ":NIDeviceList") = NIDeviceList

#ifndef TESTS_WITH_NI_HARDWARE
	HW_ITC_CloseAllDevices()
#endif
End

Function TEST_CASE_END_OVERRIDE(name)
	string name

	string dev
	variable numEntries, i

	// cut off multi data suffix
	name = StringFromList(0, name, ":")

	SVAR devices = $GetDevicePanelTitleList()

	numEntries = ItemsInList(devices)
	for(i = 0; i < numEntries; i += 1)
		dev = StringFromList(i, devices)

		// no analysis function errors
		NVAR errorCounter = $GetAnalysisFuncErrorCounter(dev)
		CHECK_EQUAL_VAR(errorCounter, 0)

		if(WhichListItem(name, LIST_OF_TESTS_WITH_SWEEP_ROLLBACK) == -1)
			// ascending sweep numbers in both labnotebooks
			WAVE/Z sweeps = GetSweepsFromLBN_IGNORE(dev, "numericalValues")

			if(!WaveExists(sweeps))
				PASS()
				continue
			endif

			Duplicate/FREE sweeps, unsortedSweeps
			Sort sweeps, sweeps
			CHECK_EQUAL_WAVES(sweeps, unsortedSweeps, mode = WAVE_DATA)

			WAVE/Z sweeps = GetSweepsFromLBN_IGNORE(dev, "textualValues")

			if(!WaveExists(sweeps))
				PASS()
				continue
			endif

			Duplicate/FREE sweeps, unsortedSweeps
			Sort sweeps, sweeps
			CHECK_EQUAL_WAVES(sweeps, unsortedSweeps, mode = WAVE_DATA)
		endif

		CheckLBIndexCache_IGNORE(dev)
		CheckLBRowCache_IGNORE(dev)
	endfor

	StopAllBackgroundTasks()

#ifdef AUTOMATED_TESTING_DEBUGGING

	// accessing UTF internals, don't do that at home
	// but it helps debugging flaky tests
	DFREF dfr = GetPackageFolder()
	NVAR/Z/SDFR=dfr error_count

	if(NVAR_Exists(error_count) && error_count > 0)
		CtrlNamedBackGround _all_, status
		print s_info
	endif

#endif

End

/// @brief Register the function `<testcase>_REENTRY`
///        as reentry part of the given test case.
///
/// Does nothing if the reentry function does not exist. Supports both plain test cases and multi data test cases
/// accepting string arguments.
Function RegisterReentryFunction(string testcase)

	string reentryFuncName = testcase + "_REENTRY"
	FUNCREF TEST_CASE_PROTO reentryFuncPlain = $reentryFuncName
	FUNCREF TEST_CASE_PROTO_MD_STR reentryFuncMDStr = $reentryFuncName

	if(FuncRefIsAssigned(FuncRefInfo(reentryFuncPlain)) || FuncRefIsAssigned(FuncRefInfo(reentryFuncMDStr)))
		CtrlNamedBackGround DAQWatchdog, start, period=120, proc=WaitUntilDAQDone_IGNORE
		CtrlNamedBackGround TPWatchdog, start, period=120, proc=WaitUntilTPDone_IGNORE
		RegisterUTFMonitor(TASKNAMES + "DAQWatchdog;TPWatchdog", BACKGROUNDMONMODE_AND, reentryFuncName, timeout = 600, failOnTimeout = 1)
	endif
End

static Function/WAVE GetSweepsFromLBN_IGNORE(device, name)
	string device, name

	variable col

	DFREF dfr = GetDevSpecLabNBFolder(device)
	WAVE/Z values = dfr:$name

	if(!WaveExists(values))
		return $""
	endif

	// all sweep numbers are ascending
	col = GetSweepColumn(values)

	if(IsTextWave(values))
		Duplicate/T/FREE/RMD=[*][col][0] values, sweepsText
		Redimension/N=-1 sweepsText

		Make/FREE/N=(DimSize(sweepsText, ROWS)) sweeps = str2num(sweepsText[p])
	else
		Duplicate/FREE/RMD=[*][col][0] values, sweeps
		Redimension/N=-1 sweeps
	endif

	WaveTransform/O zapNaNs, sweeps

	return sweeps
End

/// @brief Background function to wait until DAQ is finished.
Function WaitUntilDAQDone_IGNORE(s)
	STRUCT WMBackgroundStruct &s

	string dev
	variable numEntries, i

	SVAR devices = $GetDevicePanelTitleList()

	numEntries = ItemsInList(devices)
	for(i = 0; i < numEntries; i += 1)
		dev = StringFromList(i, devices)

		NVAR dataAcqRunMode = $GetDataAcqRunMode(dev)

		if(IsNaN(dataAcqRunMode))
			// not active
			continue
		endif

		if(dataAcqRunMode != DAQ_NOT_RUNNING)
			return 0
		endif
	endfor

	return 1
End

/// @brief Background function to wait until TP is finished.
///
/// If it is finished pushes the next two, one setup and the
/// corresponding `Test`, testcases to the queue.
Function WaitUntilTPDone_IGNORE(s)
	STRUCT WMBackgroundStruct &s

	string device
	variable numEntries, i

	SVAR devices = $GetDevicePanelTitleList()

	numEntries = ItemsInList(devices)
	for(i = 0; i < numEntries; i += 1)
		device = StringFromList(i, devices)

		NVAR runMode = $GetTestpulseRunMode(device)

		if(IsNaN(runMode))
			// not active
			continue
		endif

		if(runMode != TEST_PULSE_NOT_RUNNING)
			return 0
		endif
	endfor

	return 1
End

Function StopAcqDuringITI_IGNORE(s)
	STRUCT WMBackgroundStruct &s

	SVAR devices = $GetDevicePanelTitleList()
	string device = StringFromList(0, devices)

	NVAR runMode = $GetTestpulseRunMode(device)

	if(runMode & TEST_PULSE_DURING_RA_MOD)
		PGC_SetAndActivateControl(device, "DataAcquireButton")
		return 1
	endif

	return 0
End

Function StartTPDuringITI_IGNORE(s)
	STRUCT WMBackgroundStruct &s

	SVAR devices = $GetDevicePanelTitleList()
	string device = StringFromList(0, devices)

	NVAR runMode = $GetTestpulseRunMode(device)

	if(runMode & TEST_PULSE_DURING_RA_MOD)
		PGC_SetAndActivateControl(device, "StartTestPulseButton")
		return 1
	endif

	return 0
End

Function SkipToEndDuringITI_IGNORE(s)
	STRUCT WMBackgroundStruct &s

	SVAR devices = $GetDevicePanelTitleList()
	string device = StringFromList(0, devices)

	NVAR runMode = $GetTestpulseRunMode(device)

	if(runMode & TEST_PULSE_DURING_RA_MOD)
		RA_SkipSweeps(device, inf)
		return 1
	endif

	return 0
End

Function SkipSweepBackDuringITI_IGNORE(s)
	STRUCT WMBackgroundStruct &s

	SVAR devices = $GetDevicePanelTitleList()
	string device = StringFromList(0, devices)

	NVAR runMode = $GetTestpulseRunMode(device)

	if(runMode & TEST_PULSE_DURING_RA_MOD)
		CHECK_EQUAL_VAR(AFH_GetLastSweepAcquired(device), 0)
		RA_SkipSweeps(device, -1)
		return 1
	endif

	return 0
End

Function StopAcq_IGNORE(s)
	STRUCT WMBackgroundStruct &s

	SVAR devices = $GetDevicePanelTitleList()
	string device = StringFromList(0, devices)
	variable runMode = ROVAR(GetDataAcqRunMode(device))

	if(runMode == DAQ_NOT_RUNNING)
		return 0
	endif

	PGC_SetAndActivateControl(device, "DataAcquireButton")

	return 1
End

Function JustDelay_IGNORE(s)
	STRUCT WMBackgroundStruct &s

	return 1
End

Function StopTP_IGNORE(s)
	STRUCT WMBackgroundStruct &s

	SVAR devices = $GetDevicePanelTitleList()
	string device = StringFromList(0, devices)
	PGC_SetAndActivateControl(device, "StartTestPulseButton")

	return 1
End

Function StartAcq_IGNORE(s)
	STRUCT WMBackgroundStruct &s

	SVAR devices = $GetDevicePanelTitleList()
	string device = StringFromList(0, devices)
	PGC_SetAndActivateControl(device, "DataAcquireButton")
	CtrlNamedBackGround DAQWatchdog, start, period=120, proc=WaitUntilDAQDone_IGNORE

	return 1
End

Function ChangeStimSet_IGNORE(s)
	STRUCT WMBackgroundStruct &s

	string ctrl
	SVAR devices = $GetDevicePanelTitleList()
	string device = StringFromList(0, devices)

	ctrl   = GetPanelControl(0, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE)

	PGC_SetAndActivateControl(device, ctrl, val = GetPopupMenuIndex(device, ctrl) + 1)

	return 1
End

Function ClampModeDuringSweep_IGNORE(s)
	STRUCT WMBackgroundStruct &s

	SVAR devices = $GetDevicePanelTitleList()
	string device = StringFromList(0, devices)

	NVAR dataAcqRunMode = $GetDataAcqRunMode(device)

	if(dataAcqRunMode != DAQ_NOT_RUNNING)
		PGC_SetAndActivateControl(device, DAP_GetClampModeControl(I_CLAMP_MODE, 1), val=1)
		return 1
	endif

	return 0
End

Function ClampModeDuringITI_IGNORE(s)
	STRUCT WMBackgroundStruct &s

	SVAR devices = $GetDevicePanelTitleList()
	string device = StringFromList(0, devices)

	NVAR dataAcqRunMode = $GetDataAcqRunMode(device)

	if(IsFinite(dataAcqRunMode) && dataAcqRunMode != DAQ_NOT_RUNNING && IsDeviceActiveWithBGTask(device, TASKNAME_TIMERMD))
		PGC_SetAndActivateControl(device, DAP_GetClampModeControl(I_CLAMP_MODE, 1), val=1)
		return 1
	endif

	return 0
End

Function StopTPAfterFiveSeconds_IGNORE(s)
   STRUCT WMBackgroundStruct &s

	SVAR devices = $GetDevicePanelTitleList()
	string device = StringFromList(0, devices)

	PGC_SetAndActivateControl(device, "StartTestPulseButton")

   return 1
End

/// @brief Structure to hold various common DAQ DAQSettings
///
/// MultiDevice (MD: 1/0)
/// Repeated Acquisition (RA: 1/0)
/// Indexing (IDX: 1/0)
/// Locked Indexing (LIDX: 1/0)
/// Background Data acquisition (BKG_DAQ: 1/0)
/// Repeat Sets (RES: [1, inf])
Structure DAQSettings
	variable MD, RA, IDX, LIDX, BKG_DAQ, RES
EndStructure

/// @brief Fill the #DAQSetttings structure from a specially crafted string
Function InitDAQSettingsFromString(s, str)
	STRUCT DAQSettings& s
	string str

	variable md, ra, idx, lidx, bkg_daq, res

	/// @todo use longer names once IP8 is mandatory
	sscanf str, "MD%d_RA%d_I%d_L%d_BKG_%d_RES_%d", md, ra, idx, lidx, bkg_daq, res
	REQUIRE(V_Flag >= 5)

	s.md        = md
	s.ra        = ra
	s.idx       = idx
	s.lidx      = lidx
	s.bkg_daq   = bkg_daq
	s.res       = limit(res, 1, inf)
End

/// @brief Similiar to InitDAQSettingsFromString() but uses the function name of the caller
Function InitSettings(s)
	STRUCT DAQSettings& s

	string caller = GetRTStackInfo(2)
	InitDAQSettingsFromString(s, caller)
End

Function CALLABLE_PROTO(device)
	string device
	FAIL()
End

Function LoadStimsets()
	string filename = GetFolder(FunctionPath("")) + "_2017_09_01_192934-compressed.nwb"
	NWB_LoadAllStimsets(filename = filename, overwrite = 1)
End

Function SaveStimsets(nwbVersion)
	variable nwbVersion

	string filename = GetFolder(FunctionPath("")) + "_2017_09_01_192934-compressed.nwb"
	DeleteFile filename
	NWB_ExportAllStimsets(nwbVersion, overrideFilePath = filename)
End

Function StopAllBackgroundTasks()

	string list, name, bkgInfo
	variable i, numEntries

	CtrlNamedBackGround _all_, status
	list = S_info
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

Function CheckLBIndexCache_IGNORE(string panelTitle)

	variable i, j, k, l, numEntries, numSweeps, numRows, numCols, numLayers
	variable entry, sweepNo, entrySourceType
	string setting, msg

	WAVE numericalValues = GetLBNumericalValues(panelTitle)
	WAVE textualValues = GetLBTextualValues(panelTitle)

	Make/FREE/WAVE entries = {numericalValues, textualValues}
	numEntries = DimSize(entries, ROWS)
	for(i = 0; i < numEntries; i += 1)
		WAVE values = entries[i]
		WAVE LBindexCache = GetLBindexCache(values)

		numRows = DimSize(LBIndexCache, ROWS)
		numCols = DimSize(LBIndexCache, COLS)
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

					sweepNo = j
					setting = GetDimLabel(values, COLS, k)
					entrySourceType = ReverseEntrySourceTypeMapper(l)

					WAVE/Z settingsNoCache = MIES_MIESUTILS#GetLastSettingNoCache(values, sweepNo, setting, entrySourceType)

					if(!WaveExists(settingsNoCache))
						CHECK_EQUAL_VAR(entry, LABNOTEBOOK_MISSING_VALUE)
						if(entry != LABNOTEBOOK_MISSING_VALUE)
							sprintf msg, "bug: LBN %s, setting %s, sweep %d, entrySourceType %g\r", NameOfWave(values), setting, j, entrySourceType
							ASSERT(0, msg)
						endif
					else
						Duplicate/FREE/RMD=[entry][k] values, settings
						Redimension/N=(LABNOTEBOOK_LAYER_COUNT)/E=1 settings

						if(!EqualWaves(settings, settingsNoCache, WAVE_DATA))

							Note/K settings, setting

							Duplicate/O settings, root:settings
							Duplicate/O settingsNoCache, root:settingsNoCache

							sprintf msg, "bug: LBN %s, setting %s, sweep %d, entrySourceType %g\r", NameOfWave(values), setting, j, entrySourceType
							ASSERT(0, msg)
						endif

						REQUIRE_EQUAL_WAVES(settings, settingsNoCache, mode = WAVE_DATA)
					endif
				endfor
			endfor
		endfor
	endfor
End

Function CheckLBRowCache_IGNORE(string panelTitle)

	variable i, j, k, numEntries, numRows, numCols, numLayers, first, last, sweepNo, entrySourceType

	WAVE numericalValues = GetLBNumericalValues(panelTitle)
	WAVE textualValues = GetLBTextualValues(panelTitle)

	Make/FREE/WAVE entries = {numericalValues, textualValues}

	numEntries = DimSize(entries, ROWS)
	for(i = 0; i < numEntries; i += 1)
		WAVE values = entries[i]
		WAVE LBRowCache = GetLBRowCache(values)

		numRows = DimSize(LBRowCache, ROWS)
		numCols = DimSize(LBRowCache, COLS)
		numLayers = DimSize(LBRowCache, LAYERS)

		for(j = 0; j < numRows; j += 1)

			Make/FREE/N=(numCols, numLayers) match

			match[][] = LBRowCache[j][p][q]

			if(IsConstant(match, LABNOTEBOOK_GET_RANGE))
				continue
			endif

			for(k = 0; k < numLayers; k += 1)

				if(LBRowCache[j][%first][k] == LABNOTEBOOK_GET_RANGE   \
				   && LBRowCache[j][%last][k] == LABNOTEBOOK_GET_RANGE)
					continue
				endif

				sweepNo = j
				entrySourceType = ReverseEntrySourceTypeMapper(k)

				first = LABNOTEBOOK_GET_RANGE
				last  = LABNOTEBOOK_GET_RANGE

				WAVE/Z settingsNoCache = MIES_MIESUTILS#GetLastSettingNoCache(values, sweepNo, "TimeStamp", entrySourceType, \
							                                                  first = first, last = last)

				CHECK_EQUAL_VAR(first, LBRowCache[j][%first][k])
				CHECK_EQUAL_VAR(last, LBRowCache[j][%last][k])
			endfor
		endfor
	endfor
End

Function CheckDashboard(string device, WAVE headstageQC)

	string databrowser
	variable numEntries, i, state

	databrowser = DB_FindDataBrowser(device)
	DFREF dfr = BSP_GetFolder(databrowser, MIES_BSP_PANEL_FOLDER)
	WAVE/T/Z listWave = GetAnaFuncDashboardListWave(dfr)
	CHECK_WAVE(listWave, TEXT_WAVE)

	// Check that we have acquired some sweeps
	WAVE numericalValues = GetLBNumericalValues(device)
	WAVE/Z sweeps = GetSweepsWithSetting(numericalValues, "SweepNum")
	CHECK_WAVE(sweeps, NUMERIC_WAVE)

	numEntries = GetNumberFromWaveNote(listWave, NOTE_INDEX)
	CHECK(numEntries > 0)

	for(i = 0; i < numEntries; i += 1)
		state = !cmpstr(listWave[i][%Result], DASHBOARD_PASSING_MESSAGE)
		CHECK_EQUAL_VAR(state, headstageQC[i])
	endfor
End
