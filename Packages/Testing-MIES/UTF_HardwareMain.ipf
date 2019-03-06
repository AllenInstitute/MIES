#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.

#include "MIES_include"
#include "unit-testing"

#include "UTF_AnalysisFunctionManagement"
#include "UserAnalysisFunctions"
#include "UTF_AnalysisFunctionParameters"
#include "UTF_VeryBasicHardwareTests"
#include "UTF_DAEphys"
#include "UTF_BasicHardwareTests"
#include "UTF_PatchSeqDAScale"
#include "UTF_PatchSeqSquarePulse"
#include "UTF_PatchSeqRheobase"
#include "UTF_PatchSeqRamp"
#include "UTF_MultiPatchSeqFastRheoEstimate"
#include "UTF_MultiPatchSeqDAScale"
#include "UTF_TestNWBExportV1"

#ifdef TESTS_WITH_NI_HARDWARE

StrConstant DEVICE        = "Dev1"
StrConstant DEVICES_YOKED = "Unsupported"

#else

StrConstant DEVICE        = "ITC18USB_dev_0"
StrConstant DEVICES_YOKED = "ITC1600_dev_0;ITC1600_dev_1"

#endif

Function run()

	string list = ""
	list = AddListItem("UTF_VeryBasicHardwareTests.ipf", list)
	list = AddListItem("UTF_BasicHardwareTests.ipf", list)
	list = AddListItem("UTF_AnalysisFunctionManagement.ipf", list)
	list = AddListItem("UTF_AnalysisFunctionParameters.ipf", list)
	list = AddListItem("UTF_DAEphys.ipf", list)
	list = AddListItem("UTF_PatchSeqDAScale.ipf", list)
	list = AddListItem("UTF_PatchSeqSquarePulse.ipf", list)
	list = AddListItem("UTF_PatchSeqRheobase.ipf", list)
	list = AddListItem("UTF_PatchSeqRamp.ipf", list)
	list = AddListItem("UTF_MultiPatchSeqFastRheoEstimate.ipf", list)
	list = AddListItem("UTF_MultiPatchSeqDAScale.ipf", list)

	RunTest(list, name = "MIES with ITC Hardware", enableJU = 1, allowDebug = 0)
End

Function TEST_BEGIN_OVERRIDE(name)
	string name

	NVAR interactiveMode = $GetInteractiveMode()
	interactiveMode = 0

//	DisableDebugOutput()
//	EnableDebugoutput()

	NWB_LoadAllStimsets(filename = GetFolder(FunctionPath("")) + "_2017_09_01_192934-compressed.nwb", overwrite = 1)
	KillDataFolder/Z root:WaveBuilder
	DuplicateDataFolder	root:MIES:WaveBuilder, root:WaveBuilder
	KillDataFolder/Z root:WaveBuilder:SavedStimulusSets
End

Function TEST_CASE_BEGIN_OVERRIDE(name)
	string name

	variable numWindows, i
	string list, reentryFuncName, win

	reentryFuncName = name + "_REENTRY"
	FUNCREF TEST_CASE_PROTO reentryFunc = $reentryFuncName

	if(FuncRefIsAssigned(FuncRefInfo(reentryFunc)))
		CtrlNamedBackGround DAQWatchdog, start, period=120, proc=WaitUntilDAQDone_IGNORE
		CtrlNamedBackGround TPWatchdog, start, period=120, proc=WaitUntilTPDone_IGNORE
		RegisterUTFMonitor(TASKNAMES + "DAQWatchdog;TPWatchdog", BACKGROUNDMONMODE_AND, reentryFuncName, timeout = 600)
	endif

	list = WinList("*", ";", "WIN:67") // Panels, Graphs and tables

	numWindows = ItemsInList(list)
	for(i = 0; i < numWindows; i += 1)
		win = StringFromList(i, list)

		if(!cmpstr(win, "BW_MiesBackgroundWatchPanel"))
			continue
		endif

		KillWindow $win
	endfor

	KillOrMoveToTrash(dfr=root:MIES)

	GetMiesPath()
	DuplicateDataFolder	root:WaveBuilder, root:MIES:WaveBuilder
	REQUIRE(DataFolderExists("root:MIES:WaveBuilder:SavedStimulusSetParameters:DA"))

	HW_ITC_CloseAllDevices()

	CA_FlushCache()

	DAP_GetNIDeviceList()
	NVAR errorCounter = $GetAnalysisFuncErrorCounter(DEVICE)
	errorCounter = 0
End

Function TEST_CASE_END_OVERRIDE(name)
	string name

	string devices, dev
	variable numEntries, i

	devices = GetDevices()

	numEntries = ItemsInList(devices)
	for(i = 0; i < numEntries; i += 1)
		dev = StringFromList(i, devices)

		// no analysis function errors
		NVAR errorCounter = $GetAnalysisFuncErrorCounter(dev)
		CHECK_EQUAL_VAR(errorCounter, 0)

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
	endfor

	StopAllBackgroundTasks()

	// accessing UTF internals, don't do that at home
	// but it helps debugging flaky tests
	DFREF dfr = GetPackageFolder()
	NVAR/Z/SDFR=dfr error_count

	if(NVAR_Exists(error_count) && error_count > 0)
		CtrlNamedBackGround _all_, status
		print s_info
	endif
End

Function ChooseCorrectDevice(unlockedPanelTitle, dev)
	string unlockedPanelTitle, dev

	if(!cmpstr(dev, "ITC18USB_dev_0"))
		PGC_SetAndActivateControl(unlockedPanelTitle, "popup_MoreSettings_DeviceType", val=5)
	else // assume first NI device
		PGC_SetAndActivateControl(unlockedPanelTitle, "popup_MoreSettings_DeviceType", val=6)
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

/// @brief Return the list of active devices
Function/S GetDevices()

#ifdef TESTS_WITH_YOKING
	return DEVICES_YOKED
#else
	return DEVICE
#endif
End

Function/S GetSingleDevice()

#ifdef TESTS_WITH_YOKING
	return StringFromList(0, DEVICES_YOKED)
#else
	return DEVICE
#endif
End

/// @brief Background function to wait until DAQ is finished.
Function WaitUntilDAQDone_IGNORE(s)
	STRUCT WMBackgroundStruct &s

	string devices, dev
	variable numEntries, i

	devices = GetDevices()

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

	string devices, dev
	variable numEntries, i

	devices = GetDevices()

	numEntries = ItemsInList(devices)
	for(i = 0; i < numEntries; i += 1)
		dev = StringFromList(i, devices)

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

	string device = GetSingleDevice()
	NVAR runMode = $GetTestpulseRunMode(device)

	if(runMode & TEST_PULSE_DURING_RA_MOD)
		PGC_SetAndActivateControl(device, "DataAcquireButton")
		return 1
	endif

	return 0
End

Function StartTPDuringITI_IGNORE(s)
	STRUCT WMBackgroundStruct &s

	string device = GetSingleDevice()

	NVAR runMode = $GetTestpulseRunMode(device)

	if(runMode & TEST_PULSE_DURING_RA_MOD)
		PGC_SetAndActivateControl(device, "StartTestPulseButton")
		return 1
	endif

	return 0
End

Function ExecuteDuringITI_IGNORE(s)
	STRUCT WMBackgroundStruct &s

	string device = GetSingleDevice()

	NVAR runMode = $GetTestpulseRunMode(device)

	if(runMode & TEST_PULSE_DURING_RA_MOD)
		RA_SkipSweeps(device, inf)
		return 1
	endif

	return 0
End

Function StopAcq_IGNORE(s)
	STRUCT WMBackgroundStruct &s

	string device = GetSingleDevice()
	PGC_SetAndActivateControl(device, "DataAcquireButton")

	return 1
End

Function StopTP_IGNORE(s)
	STRUCT WMBackgroundStruct &s

	string device = GetSingleDevice()
	PGC_SetAndActivateControl(device, "StartTestPulseButton")

	return 1
End

Function StartAcq_IGNORE(s)
	STRUCT WMBackgroundStruct &s

	string device = GetSingleDevice()
	PGC_SetAndActivateControl(device, "DataAcquireButton")
	CtrlNamedBackGround DAQWatchdog, start, period=120, proc=WaitUntilDAQDone_IGNORE

	return 1
End

Function ChangeStimSet_IGNORE(s)
	STRUCT WMBackgroundStruct &s

	string device, ctrl

	device = GetSingleDevice()
	ctrl   = GetPanelControl(0, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE)

	PGC_SetAndActivateControl(device, ctrl, val = GetPopupMenuIndex(device, ctrl) + 1)

	return 1
End

Function ClampModeDuringSweep_IGNORE(s)
	STRUCT WMBackgroundStruct &s

	string device = GetSingleDevice()

	NVAR dataAcqRunMode = $GetDataAcqRunMode(device)

	if(dataAcqRunMode != DAQ_NOT_RUNNING)
		PGC_SetAndActivateControl(device, DAP_GetClampModeControl(I_CLAMP_MODE, 1), val=1)
		return 1
	endif

	return 0
End

Function ClampModeDuringITI_IGNORE(s)
	STRUCT WMBackgroundStruct &s

	string device = GetSingleDevice()

	NVAR dataAcqRunMode = $GetDataAcqRunMode(device)

	if(IsFinite(dataAcqRunMode) && dataAcqRunMode != DAQ_NOT_RUNNING && IsDeviceActiveWithBGTask(device, "ITC_TimerMD"))
		PGC_SetAndActivateControl(device, DAP_GetClampModeControl(I_CLAMP_MODE, 1), val=1)
		return 1
	endif

	return 0
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

Function OpenDatabrowser()
	string win = DB_OpenDataBrowser()
	string panel = BSP_GetSweepControlsPanel(win)
	PGC_SetAndActivateControl(panel, "check_SweepControl_AutoUpdate", val = 1)
End

Function CALLABLE_PROTO()
	FAIL()
End

Function LoadStimsets()
	string filename = GetFolder(FunctionPath("")) + "_2017_09_01_192934-compressed.nwb"
	NWB_LoadAllStimsets(filename = filename, overwrite = 1)
End

Function SaveStimsets()
	string filename = GetFolder(FunctionPath("")) + "_2017_09_01_192934-compressed.nwb"
	DeleteFile filename
	NWB_ExportAllStimsets(overrideFilePath = filename)
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
