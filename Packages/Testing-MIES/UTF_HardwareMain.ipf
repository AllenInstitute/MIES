#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma ModuleName=HardwareMain

#include "MIES_Include", optional
#include "unit-testing"

// If the next line fails, you are including the MIES created
// "UserAnalysisFunctions.ipf" and not the one from "Packages/Testing-MIES"
#include "UserAnalysisFunctions", version >= 10000

// keep sorted
#include "UTF_AnalysisFunctionManagement"
#include "UTF_AnalysisFunctionParameters"
#include "UTF_AutoTestpulse"
#include "UTF_BasicHardwareTests"
#include "UTF_DAEphys"
#include "UTF_Epochs"
#include "UTF_HelperFunctions"
#include "UTF_IVSCC"
#include "UTF_MultiPatchSeqDAScale"
#include "UTF_MultiPatchSeqFastRheoEstimate"
#include "UTF_MultiPatchSeqSpikeControl"
#include "UTF_PatchSeqChirp"
#include "UTF_PatchSeqDAScale"
#include "UTF_PatchSeqRamp"
#include "UTF_PatchSeqRheobase"
#include "UTF_PatchSeqSquarePulse"
#include "UTF_ReachTargetVoltage"
#include "UTF_SetControls"
#include "UTF_TestNWBExportV1"
#include "UTF_TestNWBExportV2"
#include "UTF_VeryBasicHardwareTests"

#include "UTF_VeryLastTestSuite"

StrConstant LIST_OF_TESTS_WITH_SWEEP_ROLLBACK = "TestSweepRollback"

Constant PSQ_TEST_HEADSTAGE = 2

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
	list = AddListItem("UTF_PatchSeqChirp.ipf", list)
	list = AddListItem("UTF_PatchSeqDAScale.ipf", list, ";", inf)
	list = AddListItem("UTF_PatchSeqSquarePulse.ipf", list, ";", inf)
	list = AddListItem("UTF_PatchSeqRheobase.ipf", list, ";", inf)
	list = AddListItem("UTF_PatchSeqRamp.ipf", list, ";", inf)
	list = AddListItem("UTF_ReachTargetVoltage.ipf", list, ";", inf)
	list = AddListItem("UTF_MultiPatchSeqFastRheoEstimate.ipf", list, ";", inf)
	list = AddListItem("UTF_MultiPatchSeqDAScale.ipf", list, ";", inf)
	list = AddListItem("UTF_MultiPatchSeqSpikeControl.ipf", list, ";", inf)
	list = AddListItem("UTF_IVSCC.ipf", list)
	list = AddListItem("UTF_AutoTestpulse.ipf", list)
	list = AddListItem("UTF_VeryLastTestSuite.ipf", list, ";", inf)

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
	devList = AddListItem("ITC18USB_Dev_0", devList, ":")
	lblList = AddListItem("ITC", lblList)
#endif

#endif

#ifdef TESTS_WITH_ITC1600_HARDWARE

#ifdef TESTS_WITH_YOKING
	devList = AddListItem("ITC1600_Dev_0;ITC1600_Dev_1", devList, ":")
	lblList = AddListItem("ITC600_YOKED", lblList)
#else
	devList = AddListItem("ITC1600_Dev_0", devList, ":")
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

	WAVE wv = GetAcqStateTracking()
	KillWaves wv; AbortOnRTE

//	DisableDebugOutput()
//	EnableDebugoutput()

	// cache the version string
	SVAR miesVersion = $GetMIESVersion()
	string/G root:miesVersion = miesVersion

	// cache the device lists
	string/G root:ITCDeviceList = DAP_GetITCDeviceList()
	string/G root:NIDeviceList = DAP_GetNIDeviceList()

	// cache device info waves
	DFREF dfr = GetDeviceInfoPath()
	DFREF dest = root:
	DuplicateDataFolder/Z/O=1 dfr, dest
	CHECK_EQUAL_VAR(V_flag, 0)

	// speedup executing the tests locally
	if(!DataFolderExists("root:WaveBuilder"))
		NWB_LoadAllStimsets(filename = GetFolder(FunctionPath("")) + "_2017_09_01_192934-compressed.nwb", overwrite = 1)
		DuplicateDataFolder	root:MIES:WaveBuilder, root:WaveBuilder
		KillDataFolder/Z root:WaveBuilder:SavedStimulusSets
	endif
End

Function TEST_CASE_BEGIN_OVERRIDE(name)
	string name

	variable numWindows, i
	string list, reentryFuncName, win, experimentName

	// cut off multi data suffix
	name = StringFromList(0, name, ":")

	RegisterReentryFunction(name)

	AdditionalExperimentCleanup()

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

	DFREF dest = GetDAQDevicesFolder()
	DFREF source = root:DeviceInfo
	DuplicateDataFolder/O=1/Z source, dest
	CHECK_EQUAL_VAR(V_flag, 0)

#ifndef TESTS_WITH_NI_HARDWARE
	HW_ITC_CloseAllDevices()
#endif

	// remove NWB file which will be used for sweep-by-sweep export
	CloseNwBFile()
	DeleteFile/Z GetExperimentNWBFileForExport()
End

Function TEST_CASE_END_OVERRIDE(name)
	string name

	string dev, experimentNWBFile, baseFolder, nwbFile
	variable numEntries, i, fileID, nwbVersion

	// cut off multi data suffix
	name = StringFromList(0, name, ":")

	SVAR devices = $GetLockedDevices()

	numEntries = ItemsInList(devices)
	for(i = 0; i < numEntries; i += 1)
		dev = StringFromList(i, devices)

		// no analysis function errors
		NVAR errorCounter = $GetAnalysisFuncErrorCounter(dev)
		CHECK_EQUAL_VAR(errorCounter, 0)

		// correct acquisition state
		NVAR acqState = $GetAcquisitionState(dev)
		CHECK_EQUAL_VAR(acqState, AS_INACTIVE)

		CheckEpochs(dev)

		if(WhichListItem(name, LIST_OF_TESTS_WITH_SWEEP_ROLLBACK) == -1)
			// ascending sweep numbers in both labnotebooks
			WAVE numericalValues = GetLBNumericalValues(dev)
			WAVE/Z sweeps = GetSweepsWithSetting(numericalValues, "SweepNum")

			if(!WaveExists(sweeps))
				PASS()
				continue
			endif

			Duplicate/FREE sweeps, unsortedSweeps
			Sort sweeps, sweeps
			CHECK_EQUAL_WAVES(sweeps, unsortedSweeps, mode = WAVE_DATA)

			WAVE textualValues = GetLBTextualValues(dev)
			WAVE/Z sweeps = GetSweepsWithSetting(textualValues, "SweepNum")

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

		TestSweepReconstruction_IGNORE(dev)
	endfor

	StopAllBackgroundTasks()

	NVAR bugCount = $GetBugCount()
	CHECK_EQUAL_VAR(bugCount, 0)

	// store experiment NWB file for later validation
	HDF5CloseFile/A/Z 0
	experimentNWBFile = GetExperimentNWBFileForExport()

	if(FileExists(experimentNWBFile))
		fileID = H5_OpenFile(experimentNWBFile)
		nwbVersion = GetNWBMajorVersion(ReadNWBVersion(fileID))
		HDF5CloseFile fileID

		[baseFolder, nwbFile] = GetUniqueNWBFileForExport(nwbVersion)
		MoveFile experimentNWBFile as (baseFolder + nwbFile)
	endif

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

/// @brief Checks user epochs for consistency
static Function CheckUserEpochsFromChunks(string dev)

	variable i, j, sweepCnt, numEpochs, DAC

	WAVE numericalValues = GetLBNumericalValues(dev)
	WAVE textualValues = GetLBTextualValues(dev)

	WAVE/Z sweeps = GetSweepsWithSetting(numericalValues, "SweepNum")

	if(!WaveExists(sweeps))
		PASS()
		return NaN
	endif

	sweepCnt = DimSize(sweeps, ROWS)
	for(i = 0; i < sweepCnt; i += 1)

		WAVE statusHS = GetLastSetting(numericalValues, sweeps[i], "Headstage Active", DATA_ACQUISITION_MODE)

		for(j = 0; j <  NUM_HEADSTAGES; j += 1)

			if(!statusHS[j])
				continue
			endif

			DAC = AFH_GetDACFromHeadstage(dev, j)
			WAVE/T/Z userChunkEpochs = EP_GetEpochs(numericalValues, textualValues, sweeps[i], XOP_CHANNEL_TYPE_DAC, DAC, EPOCH_SHORTNAME_USER_PREFIX + PSQ_BASELINE_CHUNK_SHORT_NAME_PREFIX + "[0-9]+", treelevel = EPOCH_USER_LEVEL)

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
	for(i = 0; i < numEpochs - 1; i += 1)
		s1 = str2num(epochInfo[i][EPOCH_COL_STARTTIME])
		e1 = str2num(epochInfo[i][EPOCH_COL_ENDTIME])
		for(j = i + 1; j < numEpochs; j += 1)
			s2 = str2num(epochInfo[j][EPOCH_COL_STARTTIME])
			e2 = str2num(epochInfo[j][EPOCH_COL_ENDTIME])
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

	WAVE numericalValues = GetLBNumericalValues(dev)
	WAVE textualValues = GetLBTextualValues(dev)

	WAVE/Z sweeps = GetSweepsWithSetting(numericalValues, "SweepNum")

	if(!WaveExists(sweeps))
		PASS()
		return NaN
	endif

	Make/D/FREE channelTypes = {XOP_CHANNEL_TYPE_ADC, XOP_CHANNEL_TYPE_DAC} // note: XOP_CHANNEL_TYPE_TTL not supported by GetLastSettingChannel
	channelTypeCount = DimSize(channelTypes, ROWS)

	sweepCnt = DimSize(sweeps, ROWS)

	WAVE/Z settings
	for(i = 0; i < sweepCnt; i += 1)
		for(j = 0; j <  channelTypeCount; j += 1)
			channelCnt = GetNumberFromType(var=channelTypes[j])
			for(k = 0; k <  channelCnt; k += 1)
				[settings, index] = GetLastSettingChannel(numericalValues, textualValues, sweeps[i], EPOCHS_ENTRY_KEY, k, channelTypes[j], DATA_ACQUISITION_MODE)

				if(WaveExists(settings))
					WAVE/T settingsT = settings
					str = settingsT[index]
					if(!IsEmpty(str))
						WAVE/T epochInfo = EP_EpochStrToWave(str)
						Make/FREE/N=(DimSize(epochInfo, ROWS))/T epNames = EP_GetShortName(epochInfo[p][EPOCH_COL_TAGS])
						// All Epochs should have short names
						FindValue/TXOP=4/TEXT="" epNames
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

	channelCnt = GetNumberFromType(var=XOP_CHANNEL_TYPE_DAC)
	for(i = 0; i < sweepCnt; i += 1)
		for(j = 0; j <  channelCnt; j += 1)
			[settings, index] = GetLastSettingChannel(numericalValues, textualValues, sweeps[i], EPOCHS_ENTRY_KEY, j, XOP_CHANNEL_TYPE_DAC, DATA_ACQUISITION_MODE)
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
/// accepting string/ref wave arguments.
Function RegisterReentryFunction(string testcase)

	string reentryFuncName = testcase + "_REENTRY"
	FUNCREF TEST_CASE_PROTO reentryFuncPlain = $reentryFuncName
	FUNCREF TEST_CASE_PROTO_MD_STR reentryFuncMDStr = $reentryFuncName
	FUNCREF TEST_CASE_PROTO_MD_WVWAVEREF reentryFuncRefWave = $reentryFuncName

	if(FuncRefIsAssigned(FuncRefInfo(reentryFuncPlain)) || FuncRefIsAssigned(FuncRefInfo(reentryFuncMDStr)) || FuncRefIsAssigned(FuncRefInfo(reentryFuncRefWave)))
		CtrlNamedBackGround DAQWatchdog, start, period=120, proc=WaitUntilDAQDone_IGNORE
		CtrlNamedBackGround TPWatchdog, start, period=120, proc=WaitUntilTPDone_IGNORE
		RegisterUTFMonitor(TASKNAMES + "DAQWatchdog;TPWatchdog", BACKGROUNDMONMODE_AND, reentryFuncName, timeout = 600, failOnTimeout = 1)
	endif
End

/// @brief Background function to wait until DAQ is finished.
Function WaitUntilDAQDone_IGNORE(s)
	STRUCT WMBackgroundStruct &s

	string dev
	variable numEntries, i

	SVAR devices = $GetLockedDevices()

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

	SVAR devices = $GetLockedDevices()

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

	SVAR devices = $GetLockedDevices()
	string device = StringFromList(0, devices)

	NVAR runMode = $GetTestpulseRunMode(device)

	if(runMode & TEST_PULSE_DURING_RA_MOD)
		PGC_SetAndActivateControl(device, "DataAcquireButton")
		return 1
	endif

	return 0
End

Function StopAcqByUnlocking_IGNORE(s)
	STRUCT WMBackgroundStruct &s

	SVAR devices = $GetLockedDevices()
	string device = StringFromList(0, devices)

	NVAR runMode = $GetTestpulseRunMode(device)

	if(runMode & TEST_PULSE_DURING_RA_MOD)
		PGC_SetAndActivateControl(device, "button_SettingsPlus_unLockDevic")
		return 1
	endif

	return 0
End

Function StopAcqByUncompiled_IGNORE(s)
	STRUCT WMBackgroundStruct &s

	SVAR devices = $GetLockedDevices()
	string device = StringFromList(0, devices)

	NVAR runMode = $GetTestpulseRunMode(device)

	if(runMode & TEST_PULSE_DURING_RA_MOD)
		ForceRecompile()
		return 1
	endif

	return 0
End

Function StartTPDuringITI_IGNORE(s)
	STRUCT WMBackgroundStruct &s

	SVAR devices = $GetLockedDevices()
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

	SVAR devices = $GetLockedDevices()
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

	SVAR devices = $GetLockedDevices()
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

	SVAR devices = $GetLockedDevices()
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

Function AutoPipetteOffsetAndStopTP_IGNORE(s)
	STRUCT WMBackgroundStruct &s

	SVAR devices = $GetLockedDevices()
	string device = StringFromList(0, devices)

	PGC_SetAndActivateControl(device, "button_DataAcq_AutoPipOffset_VC")
	PGC_SetAndActivateControl(device, "StartTestPulseButton")

	return 1
End

Function StopTP_IGNORE(s)
	STRUCT WMBackgroundStruct &s

	SVAR devices = $GetLockedDevices()
	string device = StringFromList(0, devices)
	PGC_SetAndActivateControl(device, "StartTestPulseButton")

	return 1
End

Function StartAcq_IGNORE(s)
	STRUCT WMBackgroundStruct &s

	SVAR devices = $GetLockedDevices()
	string device = StringFromList(0, devices)
	PGC_SetAndActivateControl(device, "DataAcquireButton")
	CtrlNamedBackGround DAQWatchdog, start, period=120, proc=WaitUntilDAQDone_IGNORE

	return 1
End

Function ChangeStimSet_IGNORE(s)
	STRUCT WMBackgroundStruct &s

	string ctrl
	SVAR devices = $GetLockedDevices()
	string device = StringFromList(0, devices)

	NVAR dataAcqRunMode = $GetDataAcqRunMode(device)

	NVAR tpRunMode = $GetTestpulseRunMode(device)

	if(dataAcqRunMode != DAQ_NOT_RUNNING && !(tpRunMode & TEST_PULSE_DURING_RA_MOD))
		ctrl = GetPanelControl(0, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE)
		PGC_SetAndActivateControl(device, ctrl, val = GetPopupMenuIndex(device, ctrl) + 1)

		return 1
	endif

	return 0
End

Function ClampModeDuringSweep_IGNORE(s)
	STRUCT WMBackgroundStruct &s

	SVAR devices = $GetLockedDevices()
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

	SVAR devices = $GetLockedDevices()
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

	SVAR devices = $GetLockedDevices()
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
	REQUIRE_GE_VAR(V_Flag, 5)

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

Function SaveStimsets()

	string filename = GetFolder(FunctionPath("")) + "_2017_09_01_192934-compressed.nwb"
	DeleteFile filename
	NWB_ExportAllStimsets(2, overrideFilePath = filename)
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

Function CheckLBIndexCache_IGNORE(string device)

	variable i, j, k, l, numEntries, numSweeps, numRows, numCols, numLayers
	variable entry, sweepNo, entrySourceType
	string setting, msg

	WAVE numericalValues = GetLBNumericalValues(device)
	WAVE textualValues = GetLBTextualValues(device)

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

Function CheckLBRowCache_IGNORE(string device)

	variable i, j, k, numEntries, numRows, numCols, numLayers, first, last, sweepNo, entrySourceType

	WAVE numericalValues = GetLBNumericalValues(device)
	WAVE textualValues = GetLBTextualValues(device)

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

static Function CheckDashboard(string device, WAVE headstageQC)

	string databrowser, bsPanel
	variable numEntries, i, state

	databrowser = DB_FindDataBrowser(device)
	DFREF dfr = BSP_GetFolder(databrowser, MIES_BSP_PANEL_FOLDER)
	WAVE/T/Z listWave = GetAnaFuncDashboardListWave(dfr)
	CHECK_WAVE(listWave, TEXT_WAVE)

	// enable the dashboard
	bsPanel = BSP_GetPanel(databrowser)
	PGC_SetAndActivateControl(bsPanel, "check_BrowserSettings_DS", val = 1)

	// Check that we have acquired some sweeps
	WAVE numericalValues = GetLBNumericalValues(device)
	WAVE/Z sweeps = GetSweepsWithSetting(numericalValues, "SweepNum")
	CHECK_WAVE(sweeps, NUMERIC_WAVE)

	numEntries = GetNumberFromWaveNote(listWave, NOTE_INDEX)
	CHECK_GT_VAR(numEntries, 0)

	for(i = 0; i < numEntries; i += 1)
		state = !cmpstr(listWave[i][%Result], DASHBOARD_PASSING_MESSAGE)
		CHECK_EQUAL_VAR(state, headstageQC[i])
	endfor
End

static Function CheckAnaFuncVersion(string device, variable type)
	string key
	variable refVersion, version, sweepNo, i, idx

	WAVE numericalValues = GetLBNumericalValues(device)
	key = CreateAnaFuncLBNKey(type, FMT_LBN_ANA_FUNC_VERSION, query = 1)
	sweepNo = 0

	// check that at least one headstage has the desired analysis function version set
	for(i = 0; i < NUM_HEADSTAGES; i += 1)
		WAVE/Z versions = GetLastSettingSCI(numericalValues, sweepNo, key, i, UNKNOWN_MODE)
		if(!WaveExists(versions))
			continue
		endif

		refVersion = GetAnalysisFunctionVersion(type)
		idx = GetRowIndex(versions, val = refVersion)
		CHECK_GE_VAR(idx, 0)
		return NaN
	endfor

	FAIL()
End

Function CommonAnalysisFunctionChecks(string device, variable sweepNo, WAVE headstageQC)
	string key
	variable type

	CHECK_EQUAL_VAR(GetSetVariable(device, "SetVar_Sweep"), sweepNo + 1)

	sweepNo = AFH_GetLastSweepAcquired(device)
	CHECK_EQUAL_VAR(sweepNo, sweepNo)

	WAVE textualValues = GetLBTextualValues(device)
	key = StringFromList(GENERIC_EVENT, EVENT_NAME_LIST_LBN)

	WAVE/Z/T anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)

	Make/N=(LABNOTEBOOK_LAYER_COUNT)/FREE anaFuncTypes = MapAnaFuncToConstant(anaFuncs[p])

	// map invalid analysis function value to NaN
	anaFuncTypes[] = (anaFuncTypes[p] == INVALID_ANALYSIS_FUNCTION) ? NaN : anaFuncTypes[p]

	WAVE/Z anaFuncTypesWoNaN = ZapNaNs(anaFuncTypes)
	CHECK_WAVE(anaFuncTypesWoNaN, NUMERIC_WAVE)

	WAVE/Z uniqueAnaFuncTypes = GetUniqueEntries(anaFuncTypesWoNaN)
	CHECK_WAVE(uniqueAnaFuncTypes, NUMERIC_WAVE)
	CHECK_EQUAL_VAR(DimSize(uniqueAnaFuncTypes, ROWS), 1)

	type = uniqueAnaFuncTypes[0]

	CheckAnaFuncVersion(device, type)
	CheckDashboard(device, headstageQC)

	CheckUserEpochsFromChunks(device)
End

Function AddLabnotebookEntries_IGNORE(s)
	STRUCT WMBackgroundStruct &s

	SVAR devices = $GetLockedDevices()
	string device = StringFromList(0, devices)

	NVAR runMode = $GetTestpulseRunMode(device)

	if(runMode & TEST_PULSE_DURING_RA_MOD)
		// add entry for AS_ITI
		Make/D/FREE/N=(LABNOTEBOOK_LAYER_COUNT) values     = NaN
		Make/T/FREE/N=(LABNOTEBOOK_LAYER_COUNT) valuesText = ""
		values[0] = AS_ITI
		ED_AddEntryToLabnotebook(device, "AcqStateTrackingValue_AS_ITI", values)
		valuesText[0] = AS_StateToString(AS_ITI)
		ED_AddEntryToLabnotebook(device, "AcqStateTrackingValue_AS_ITI", valuesText)
		return 1
	endif

	return 0
End

static Function TestSweepReconstruction_IGNORE(string device)
	variable i, numEntries, sweepNo
	string list, nameRecon, nameOrig

	WAVE numericalValues = GetLBTextualValues(device)

	WAVE/Z sweeps = GetSweepsWithSetting(numericalValues, "SweepNum")

	if(!WaveExists(sweeps))
		// no sweeps acquired, so we can't test anything
		PASS()
		return NaN
	endif

	DFREF deviceDFR = GetDeviceDataPath(device)

	DuplicateDataFolder/O=1 deviceDFR, deviceDataBorkedUp
	DFREF deviceDataBorkedUp = deviceDataBorkedUp

	// we might already have X_XXXX folders from the databrowser, delete them in our copy
	list = GetListOfObjects(deviceDataBorkedUp, ".*", typeFlag = COUNTOBJECTS_DATAFOLDER, fullPath = 1)
	CallFunctionForEachListItem_TS(KillOrMoveToTrashPath, list)

	// generate 1D sweep waves in X_XXXX folders
	numEntries = DimSize(sweeps, ROWS)
	for(i = 0; i < numEntries; i += 1)
		sweepNo = sweeps[i]

		WAVE sweepWave  = GetSweepWave(device, sweepNo)
		WAVE configWave = GetConfigWave(sweepWave)

		DFREF singleSweepDFR = GetSingleSweepFolder(deviceDataBorkedUp, sweepNo)

		SplitSweepIntoComponents(numericalValues, sweepNo, sweepWave, configWave, TTL_RESCALE_OFF, targetDFR=singleSweepDFR)
	endfor

	// delete 2D sweep and config waves
	list = GetListOfObjects(deviceDataBorkedUp, ".*", typeFlag = COUNTOBJECTS_WAVES, fullPath = 1)
	CallFunctionForEachListItem_TS(KillOrMoveToTrashPath, list)

	RecreateMissingSweepAndConfigWaves(device, deviceDataBorkedUp)

	// compare the 2D sweep and config waves in deviceDFR and reconstructed
	DFREF reconstructed = root:reconstructed

	WAVE/T wavesReconstructed = ListToTextWave(GetListOfObjects(reconstructed, ".*", typeFlag = COUNTOBJECTS_WAVES, fullPath = 1), ";")
	WAVE/T wavesOriginal = ListToTextWave(GetListOfObjects(deviceDFR, ".*", typeFlag = COUNTOBJECTS_WAVES, fullPath = 1), ";")

	Sort wavesReconstructed, wavesReconstructed
	Sort wavesOriginal, wavesOriginal

	CHECK_GT_VAR(DimSize(sweeps, ROWS), 0)
	CHECK_EQUAL_VAR(DimSize(wavesReconstructed, ROWS), DimSize(sweeps, ROWS) * 2)
	CHECK_EQUAL_VAR(DimSize(wavesOriginal, ROWS), DimSize(sweeps, ROWS) * 2)

	// loop over all waves and compare them
	numEntries = DimSize(wavesReconstructed, ROWS)
	for(i = 0; i < numEntries; i += 1)
		WAVE/Z wvReconstructed = $wavesReconstructed[i]
		CHECK_WAVE(wvReconstructed, NUMERIC_WAVE)

		WAVE/Z wvOriginal = $wavesOriginal[i]
		CHECK_WAVE(wvOriginal, NUMERIC_WAVE)

		nameRecon = NameOfWave(wvReconstructed)
		nameOrig  = NameOfWave(wvOriginal)
		CHECK_EQUAL_STR(nameRecon, nameOrig)

		if(GrepString(nameRecon, DATA_CONFIG_REGEXP))
			// set offset to zero for comparison
			// only data acquired with PSQ_Ramp has offset != 0
			wvReconstructed[][%Offset] = 0
			wvOriginal[][%Offset]      = 0
		endif

		CHECK_EQUAL_WAVES(wvReconstructed, wvOriginal)
	endfor
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

Function/WAVE MajorNWBVersions()

	Make/FREE wv = {1, 2}

	SetDimensionLabels(wv, "v1;v2", ROWS)

	return wv
End

Function/S GetExperimentNWBFileForExport()

	string experimentName

	PathInfo home
	CHECK(V_Flag)

	experimentName = GetExperimentName()
	CHECK(cmpstr(experimentName, UNTITLED_EXPERIMENT))

	return S_path + experimentName + ".nwb"
End

Function StopTPWhenWeHaveOne(STRUCT WMBackgroundStruct &s)
	SVAR devices = $GetLockedDevices()
	string device = StringFromList(0, devices)

	if(TP_TestPulseHasCycled(device, 1))
		PGC_SetAndActivateControl(device, "StartTestPulseButton")
		return 1
	endif

	return 0
End

/// @brief chunkTimes in ms, if sweeps is given, the chunkTimes are only checked for this specific sweep
Function CheckPSQChunkTimes(string dev, WAVE chunkTimes[, variable sweep])

	variable size, numChunks, index, expectedChunkCnt, sweepCnt, DAC
	variable i, j, k
	variable startTime, endTime, startRef, endRef
	string str

	sweep = ParamIsDefault(sweep) ? NaN : sweep

	size = DimSize(chunkTimes, ROWS)
	REQUIRE(IsEven(size))
	expectedChunkCnt = size >> 1

	WAVE numericalValues = GetLBNumericalValues(dev)
	WAVE textualValues = GetLBTextualValues(dev)

	WAVE/Z sweeps = GetSweepsWithSetting(numericalValues, "SweepNum")

	if(!WaveExists(sweeps))
		FAIL()
		return NaN
	endif

	sweepCnt = DimSize(sweeps, ROWS)

	for(i = 0; i < sweepCnt; i += 1)
		if(!IsNaN(sweep) && sweep != sweeps[i])
			continue
		endif

		WAVE statusHS = GetLastSetting(numericalValues, sweeps[i], "Headstage Active", DATA_ACQUISITION_MODE)

		for(j = 0; j <  NUM_HEADSTAGES; j += 1)

			if(!statusHS[j])
				continue
			endif

			DAC = AFH_GetDACFromHeadstage(dev, j)
			WAVE/T/Z userChunkEpochs = EP_GetEpochs(numericalValues, textualValues, sweeps[i], XOP_CHANNEL_TYPE_DAC, DAC, EPOCH_SHORTNAME_USER_PREFIX + PSQ_BASELINE_CHUNK_SHORT_NAME_PREFIX + "[0-9]+", treelevel = EPOCH_USER_LEVEL)
			if(!WaveExists(userChunkEpochs))
				continue
			endif

			numChunks = DimSize(userChunkEpochs, ROWS)

			Make/FREE/T/N=(numChunks) epochShortNames = EP_GetShortName(userChunkEpochs[p][EPOCH_COL_TAGS])
			for(k = 0; k < numChunks; k += 1)
				str = EPOCH_SHORTNAME_USER_PREFIX + PSQ_BASELINE_CHUNK_SHORT_NAME_PREFIX + num2istr(k)
				FindValue/TEXT=str/TXOP=4 epochShortNames
				index = V_Value
				CHECK_NEQ_VAR(index, -1)
				startTime = str2num(userChunkEpochs[k][EPOCH_COL_STARTTIME])
				endTime = str2num(userChunkEpochs[k][EPOCH_COL_ENDTIME])
				startRef = chunkTimes[k << 1] / 1E3
				endRef = chunkTimes[k << 1 + 1] / 1E3
				CHECK_CLOSE_VAR(startTime, startRef, tol = 0.0005)
				CHECK_CLOSE_VAR(endTime, endRef, tol = 0.0005)
			endfor
		endfor
	endfor

	// In the case we did not reached the inner checks of the upper loop
	CHECK_EQUAL_VAR(numChunks, expectedChunkCnt)
End

Function StopTPWhenFinished(STRUCT WMBackgroundStruct &s)
	SVAR devices = $GetLockedDevices()
	string device = StringFromList(0, devices)

	WAVE settings = GetTPSettings(device)

	WAVE statusHS = DAG_GetChannelState(device, CHANNEL_TYPE_HEADSTAGE)

	Duplicate/FREE/RMD=[FindDimLabel(settings, ROWS, "autoTPEnable")][0, NUM_HEADSTAGES - 1] settings, autoTPEnable
	Redimension/N=(numpnts(autoTPEnable)) autoTPEnable

	autoTPEnable[] = statusHS[p] && autoTPEnable[p]

	if(Sum(autoTPEnable) == 0)
		PGC_SetAndActivateControl(device, "StartTestPulseButton")
		return 1
	endif

	return 0
End
