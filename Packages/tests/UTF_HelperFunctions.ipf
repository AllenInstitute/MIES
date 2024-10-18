#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma ModuleName=TestHelperFunctions

#include "MIES_Include", optional
#include "igortest"

// If the next line fails, you are including the MIES created
// "UserAnalysisFunctions.ipf" and not the one from "Packages/tests"
#include "UserAnalysisFunctions", version >= 10000

#include "UTF_Constants"
#include "UTF_DataGenerators"

/// @file UTF_HelperFunctions.ipf
/// @brief This file holds helper functions for the tests

Function/S PrependExperimentFolder_IGNORE(filename)
	string filename

	PathInfo home
	CHECK(V_flag)

	return S_path + filename
End

Function FixupJSONConfigImplMain(variable jsonId, string device)

	string jPath

	jPath = MIES_CONF#CONF_FindControl(jsonID, "popup_MoreSettings_Devices")
	JSON_SetString(jsonID, jPath + "/StrValue", device)
	PathInfo home
	JSON_SetString(jsonID, "/Common configuration data/Save data to", S_path)
	JSON_SetString(jsonID, "/Common configuration data/Stim set file name", GetTestStimsetFullFilePath())
End

Function FixupJSONConfigImplRig(variable jsonId)

	string serialNumStr, jsonPath
	variable serialNum, i

	// replace stored serial number with present serial number
	AI_FindConnectedAmps()
	WAVE ampMCC = GetAmplifierMultiClamps()

	CHECK_GT_VAR(DimSize(ampMCC, ROWS), 0)
	serialNumStr = GetDimLabel(ampMCC, ROWS, 0)
	if(!cmpstr(serialNumStr, "Demo"))
		serialNum = 0
	else
		serialNum = str2num(serialNumStr)
	endif

	for(i = 0; i < NUM_HEADSTAGES; i += 1)
		sprintf jsonPath, "/Common configuration data/Headstage Association/%d/Amplifier/Serial", i
		if(!JSON_Exists(jsonID, jsonPath))
			continue
		endif
		if(JSON_GetType(jsonID, jsonPath) == JSON_NULL)
			continue
		endif

		JSON_SetVariable(jsonID, jsonPath, serialNum)
	endfor
End

Function FixupJSONConfigImpl(variable jsonId, string device)

	FixupJSONConfigImplMain(jsonId, device)
	FixupJSONConfigImplRig(jsonId)
End

/// Adapts JSON configuration files for test execution specialities
///
/// Returns the full path to the rewritten JSON configuration file the corresponding jsonID.
Function [variable jsonID, string fullPath] FixupJSONConfig_IGNORE(string path, string device)

	string data, fName, rewrittenConfigPath

	[data, fName] = LoadTextFile(path)
	CHECK_PROPER_STR(data)
	CHECK_PROPER_STR(fName)

	jsonID = JSON_Parse(data)
	PathInfo home
	CHECK_PROPER_STR(S_path)

	FixupJSONConfigImpl(jsonId, device)

	rewrittenConfigPath = S_Path + "rewritten_config.json"
	SaveTextFile(JSON_Dump(jsonID), rewrittenConfigPath)

	return [jsonID, rewrittenConfigPath]
End

/// Kill all left-over windows and remove the trash
Function AdditionalExperimentCleanup()

	string win, list, name, dest
	variable i, numWindows, reopenDebugPanel, err

	if(IsRunningInCI())
		ModifyBrowser close; err = GetRTError(1)
	endif

	list = WinList("*", ";", "WIN:67") // Panels, Graphs and tables

	numWindows = ItemsInList(list)
	for(i = 0; i < numWindows; i += 1)
		win = StringFromList(i, list)

		if(!cmpstr(win, "BW_MiesBackgroundWatchPanel"))
			continue
		endif

		if(!cmpstr(win, "DebugPanel"))
			reopenDebugPanel = 1

			WAVE debugPanelList = GetDebugPanelListWave()
			Duplicate/FREE debugPanelList, debugPanelListCopy
			WAVE debugPanelSel = GetDebugPanelListSelWave()
			Duplicate/FREE debugPanelSel, debugPanelSelCopy
		endif

		KillWindow $win
	endfor

	DFREF dfr = GetDebugPanelFolder()
	name = GetDataFolder(0, dfr)
	MoveDataFolder/O=1 dfr, root:

	NWB_CloseAllNWBFiles()
	HDF5CloseFile/A/Z 0

	KillDataFolder/Z root:$DF_NAME_MIES
	if(V_flag)
		DFREF tmpDFR = UniqueDataFolder(root:, TRASH_FOLDER_PREFIX)
		dest = RemoveEnding(GetDataFolder(1, tmpDFR), ":")
		MoveDataFolder root:MIES, $dest
		CHECK_NO_RTE()
	endif

	NewDataFolder root:$DF_NAME_MIES
	MoveDataFolder root:$name, root:$DF_NAME_MIES

	if(reopenDebugPanel)
		DP_OpenDebugPanel()

		WAVE debugPanelList = GetDebugPanelListWave()
		Duplicate/O debugPanelListCopy, debugPanelList
		WAVE debugPanelSel = GetDebugPanelListSelWave()
		Duplicate/O debugPanelSelCopy, debugPanelSel
	endif

	// currently superfluous as we remove root:MIES above
	// but might be needed in the future and helps in understanding the code
	CA_FlushCache()

	NVAR interactiveMode = $GetInteractiveMode()
	interactiveMode = 0

	NVAR bugCount = $GetBugCount()
	KillVariables bugCount

	TUFXOP_AcquireLock/N=(TSDS_BUGCOUNT)
	TSDS_WriteVar(TSDS_BUGCOUNT, 0)
	TUFXOP_ReleaseLock/N=(TSDS_BUGCOUNT)

	KillOrMoveToTrash(wv = GetOverrideResults())
End

static Function WaitForPubSubHeartbeat()
	variable i, foundHeart
	string msg, filter

	// wait until we get the first heartbeat
	for(i = 0; i < 200; i += 1)
		msg = zeromq_sub_recv(filter)
		if(!cmpstr(filter, ZEROMQ_HEARTBEAT))
			PASS()
			return NaN
		endif

		Sleep/S 0.1
	endfor

	FAIL()
End

Function PrepareForPublishTest()

	UpdateXOPLoggingTemplate()

	variable numTrials = StartZeroMQSockets(forceRestart = 1)
	REQUIRE_EQUAL_VAR(numTrials, 0)

	zeromq_sub_remove_filter("")

	zeromq_sub_add_filter("")
	zeromq_sub_connect("tcp://127.0.0.1:" + num2str(ZEROMQ_BIND_PUB_PORT))

	WaitForPubSubHeartbeat()
End

static Function CheckMessageFilters_IGNORE(string filter)
	WAVE/T/Z allFilters = FFI_GetAvailableMessageFilters()
	CHECK_WAVE(allFilters, TEXT_WAVE)

	FindValue/TXOP=4/TEXT=(filter) allFilters
	CHECK_GE_VAR(V_Value, 0)
End

Function/S FetchPublishedMessage(string expectedFilter)

	variable msgCnt, waitCnt
	string msg, filter

	variable MAX_WAITS    = 100
	variable MAX_MESSAGES = 10000

	for(;;)
		msg = zeromq_sub_recv(filter)

		if(!cmpstr(filter, expectedFilter))
			break
		endif

		if(IsEmpty(msg))
			waitCnt += 1
			if(waitCnt == MAX_WAITS)
				break
			endif
			Sleep/S 0.1
		else
			msgCnt += 1
			if(msgCnt == MAX_MESSAGES)
				break
			endif
		endif

	endfor

	CHECK_EQUAL_STR(filter, expectedFilter)
	CheckMessageFilters_IGNORE(filter)

	return msg
End

Function AdjustAnalysisParamsForPSQ(string device, string stimset)

	variable samplingFrequency, multiplier
	samplingFrequency = PSQ_GetDefaultSamplingFrequencyForSingleHeadstage(device)

#ifdef TESTS_WITH_SUTTER_HARDWARE
	multiplier = 1
#else
	multiplier = 4
#endif
	AFH_AddAnalysisParameter(stimset, "SamplingMultiplier", var = multiplier)
	AFH_AddAnalysisParameter(stimset, "SamplingFrequency", var = samplingFrequency)
End

// Read the environment variable `key` as number and if present, return 1 for
// all finite values not equal to 0 and 0 otherwise. Return `NaN` in all other
// cases.
Function GetEnvironmentVariableAsBoolean(string key)
	variable value

	value = str2numSafe(GetEnvironmentVariable(key))

	if(IsFinite(value))
		return !!value
	endif

	return NaN
End

Function DoInstrumentation()

	variable instru

	instru = GetEnvironmentVariableAsBoolean("CI_INSTRUMENT_TESTS")

	if(IsFinite(instru))
		return instru
	endif

	return !cmpstr(GetEnvironmentVariable("GITHUB_REF_NAME"), "main")
End

Function [string key, string keyTxt] PrepareLBN_IGNORE(string device)

	variable sweepNo, hwType
	string strVal

	key    = LABNOTEBOOK_USER_PREFIX + "some key"
	keyTxt = LABNOTEBOOK_USER_PREFIX + "other key"

	WAVE numericalValues = GetLBNumericalValues(device)
	WAVE textualValues   = GetLBTextualValues(device)
	hwType = GetHardwareType(device)

	// prepare the LBN
	Make/FREE/N=(1, 1, LABNOTEBOOK_LAYER_COUNT) values, valuesDAC, valuesADC
	Make/T/FREE/N=(1, 1, LABNOTEBOOK_LAYER_COUNT) valuesTxt
	Make/T/FREE/N=(3, 1, 1) keys

	sweepNo = 0

	// HS 0: DAC 2 and ADC 6
	// HS 1: DAC 3 and ADC 7
	valuesDAC[]        = NaN
	valuesDAC[0][0][0] = 2
	valuesDAC[0][0][1] = 3
	keys[0][0][0]      = "DAC"
	keys[2][0][0]      = "0.1"
	ED_AddEntriesToLabnotebook(valuesDAC, keys, sweepNo, device, DATA_ACQUISITION_MODE)

	valuesADC[]        = NaN
	valuesADC[0][0][0] = 6
	valuesADC[0][0][1] = 7
	keys[0][0][0]      = "ADC"
	keys[2][0][0]      = "0.1"
	ED_AddEntriesToLabnotebook(valuesADC, keys, sweepNo, device, DATA_ACQUISITION_MODE)

	values[]        = 0
	values[0][0][0] = 1
	values[0][0][1] = 1
	keys[0][0][0]   = "Headstage Active"
	keys[1][0][0]   = LABNOTEBOOK_BINARY_UNIT
	keys[2][0][0]   = LABNOTEBOOK_NO_TOLERANCE
	ED_AddEntriesToLabnotebook(valuesDAC, keys, sweepNo, device, DATA_ACQUISITION_MODE)

	keys = ""

	// numerical entries

	// DAC 4: unassoc (old)
	values[]                      = NaN
	values[0][0][INDEP_HEADSTAGE] = 123
	keys[0][0][0]                 = CreateLBNUnassocKey(key, 4, NaN) // old format does not include the channelType
	ED_AddEntriesToLabnotebook(values, keys, sweepNo, device, DATA_ACQUISITION_MODE)

	// ADC 8: unassoc (old)
	values[]                      = NaN
	values[0][0][INDEP_HEADSTAGE] = 789
	keys[0][0][0]                 = CreateLBNUnassocKey(key, 8, NaN) // old format does not include the channelType
	ED_AddEntriesToLabnotebook(values, keys, sweepNo, device, DATA_ACQUISITION_MODE)

	// associated
	values[]        = NaN
	values[0][0][0] = 131415
	values[0][0][1] = 161718
	keys[0][0][0]   = key
	ED_AddEntriesToLabnotebook(values, keys, sweepNo, device, DATA_ACQUISITION_MODE)

	values[]        = NaN
	values[0][0][0] = I_CLAMP_MODE
	keys[0][0][0]   = CLAMPMODE_ENTRY_KEY
	keys[2][0][0]   = "-"
	ED_AddEntriesToLabnotebook(values, keys, sweepNo, device, DATA_ACQUISITION_MODE)

	// Set a acquisition cycle ID SCI
	values[]        = NaN
	values[0][0][0] = 43
	values[0][0][1] = 45
	keys[0][0][0]   = STIMSET_ACQ_CYCLE_ID_KEY
	keys[2][0][0]   = "1"
	ED_AddEntriesToLabnotebook(values, keys, sweepNo, device, DATA_ACQUISITION_MODE)

	// Set a repeated acquisition cycle RAC
	values[]                      = NaN
	values[0][0][INDEP_HEADSTAGE] = 49
	keys[0][0][0]                 = RA_ACQ_CYCLE_ID_KEY
	keys[2][0][0]                 = "1"
	ED_AddEntriesToLabnotebook(values, keys, sweepNo, device, DATA_ACQUISITION_MODE)

	// Set set QC passed
	values[]                      = NaN
	values[0][0][INDEP_HEADSTAGE] = 1
	keys[0][0][0]                 = CreateAnaFuncLBNKey(PSQ_CHIRP, PSQ_FMT_LBN_SET_PASS, query = 1)
	keys[2][0][0]                 = "-"
	ED_AddEntriesToLabnotebook(values, keys, sweepNo, device, UNKNOWN_MODE)

	// Set Set Cycle Count
	values[]        = NaN
	values[0][0][0] = 711
	values[0][0][1] = 117
	keys[0][0][0]   = "Set Cycle Count"
	keys[2][0][0]   = "1"
	ED_AddEntriesToLabnotebook(values, keys, sweepNo, device, DATA_ACQUISITION_MODE)

	// Set Set Sweep Count
	values[]        = NaN
	values[0][0][0] = 635
	values[0][0][1] = 251
	keys[0][0][0]   = "Set Sweep Count"
	keys[2][0][0]   = "0.1"
	ED_AddEntriesToLabnotebook(values, keys, sweepNo, device, DATA_ACQUISITION_MODE)

	// textual entries
	keys[2][0][0] = "-"

	// Stimset name HS0/HS1
	valuesTxt[]        = ""
	valuesTxt[0][0][0] = "stimsetSweep0HS0"
	valuesTxt[0][0][1] = "stimsetSweep0HS1"
	keys[0][0][0]      = STIM_WAVE_NAME_KEY
	ED_AddEntriesToLabnotebook(valuesTxt, keys, sweepNo, device, DATA_ACQUISITION_MODE)

	// Set some analysis function
	valuesTxt[]        = ""
	valuesTxt[0][0][0] = "PSQ_Chirp"
	valuesTxt[0][0][1] = "PSQ_Chirp"
	keys[0][0][0]      = "Generic function"
	ED_AddEntriesToLabnotebook(valuesTxt, keys, sweepNo, device, DATA_ACQUISITION_MODE)

	// DAC 4: unassoc (old)
	valuesTxt[]                      = ""
	valuesTxt[0][0][INDEP_HEADSTAGE] = "123"
	keys[0][0][0]                    = CreateLBNUnassocKey(keyTxt, 4, NaN) // old format does not include the channelType
	ED_AddEntriesToLabnotebook(valuesTxt, keys, sweepNo, device, DATA_ACQUISITION_MODE)

	// ADC 8: unassoc (old)
	valuesTxt[]                      = ""
	valuesTxt[0][0][INDEP_HEADSTAGE] = "789"
	keys[0][0][0]                    = CreateLBNUnassocKey(keyTxt, 8, NaN) // old format does not include the channelType
	ED_AddEntriesToLabnotebook(valuesTxt, keys, sweepNo, device, DATA_ACQUISITION_MODE)

	// associated
	valuesTxt[]        = ""
	valuesTxt[0][0][0] = "131415"
	valuesTxt[0][0][1] = "161718"
	keys[0][0][0]      = keyTxt
	ED_AddEntriesToLabnotebook(valuesTxt, keys, sweepNo, device, DATA_ACQUISITION_MODE)

	sweepNo = 1

	valuesDAC[]        = NaN
	valuesDAC[0][0][0] = 2
	valuesDAC[0][0][1] = 3
	keys[0][0][0]      = "DAC"
	ED_AddEntriesToLabnotebook(valuesDAC, keys, sweepNo, device, DATA_ACQUISITION_MODE)

	valuesADC[]        = NaN
	valuesADC[0][0][0] = 6
	valuesADC[0][0][1] = 7
	keys[0][0][0]      = "ADC"
	ED_AddEntriesToLabnotebook(valuesADC, keys, sweepNo, device, DATA_ACQUISITION_MODE)

	values[]        = 0
	values[0][0][0] = 1
	values[0][0][1] = 1
	keys[0][0][0]   = "Headstage Active"
	ED_AddEntriesToLabnotebook(valuesDAC, keys, sweepNo, device, DATA_ACQUISITION_MODE)

	// numerical entries

	// DAC 5: unassoc (new)
	values[]                      = NaN
	values[0][0][INDEP_HEADSTAGE] = 456
	keys[0][0][0]                 = CreateLBNUnassocKey(key, 5, XOP_CHANNEL_TYPE_DAC)
	ED_AddEntriesToLabnotebook(values, keys, sweepNo, device, DATA_ACQUISITION_MODE)

	// ADC 9: unassoc (new)
	values[]                      = NaN
	values[0][0][INDEP_HEADSTAGE] = 101112
	keys[0][0][0]                 = CreateLBNUnassocKey(key, 9, XOP_CHANNEL_TYPE_ADC)
	ED_AddEntriesToLabnotebook(values, keys, sweepNo, device, DATA_ACQUISITION_MODE)

	// associated
	values[]        = NaN
	values[0][0][0] = 192021
	values[0][0][1] = 222324
	keys[0][0][0]   = key
	ED_AddEntriesToLabnotebook(values, keys, sweepNo, device, DATA_ACQUISITION_MODE)

	values[]        = NaN
	values[0][0][0] = V_CLAMP_MODE
	keys[0][0][0]   = CLAMPMODE_ENTRY_KEY
	ED_AddEntriesToLabnotebook(values, keys, sweepNo, device, DATA_ACQUISITION_MODE)

	// Set a acquisition cycle ID
	values[]        = NaN
	values[0][0][0] = 43
	values[0][0][1] = 46
	keys[0][0][0]   = STIMSET_ACQ_CYCLE_ID_KEY
	keys[2][0][0]   = "1"
	ED_AddEntriesToLabnotebook(values, keys, sweepNo, device, DATA_ACQUISITION_MODE)

	// Set a repeated acquisition cycle RAC
	values[]                      = NaN
	values[0][0][INDEP_HEADSTAGE] = 49
	keys[0][0][0]                 = RA_ACQ_CYCLE_ID_KEY
	keys[2][0][0]                 = "1"
	ED_AddEntriesToLabnotebook(values, keys, sweepNo, device, DATA_ACQUISITION_MODE)

	// Set sweepQC passed
	values[]                      = NaN
	values[0][0][INDEP_HEADSTAGE] = 1
	keys[0][0][0]                 = CreateAnaFuncLBNKey(PSQ_CHIRP, PSQ_FMT_LBN_SWEEP_PASS, query = 1)
	keys[2][0][0]                 = "-"
	ED_AddEntriesToLabnotebook(values, keys, sweepNo, device, UNKNOWN_MODE)

	// textual entries
	keys[2][0][0] = "-"

	// Set some analysis function
	valuesTxt[]        = ""
	valuesTxt[0][0][0] = "PSQ_Chirp"
	valuesTxt[0][0][1] = "PSQ_Chirp"
	keys[0][0][0]      = "Generic function"
	ED_AddEntriesToLabnotebook(valuesTxt, keys, sweepNo, device, DATA_ACQUISITION_MODE)

	// Stimset name HS0/HS1
	valuesTxt[]        = ""
	valuesTxt[0][0][0] = "stimsetSweep1HS0"
	valuesTxt[0][0][1] = "stimsetSweep1HS1"
	keys[0][0][0]      = STIM_WAVE_NAME_KEY
	ED_AddEntriesToLabnotebook(valuesTxt, keys, sweepNo, device, DATA_ACQUISITION_MODE)

	// DAC 5: unassoc (new)
	valuesTxt[]                      = ""
	valuesTxt[0][0][INDEP_HEADSTAGE] = "456"
	keys[0]                          = CreateLBNUnassocKey(keyTxt, 5, XOP_CHANNEL_TYPE_DAC)
	ED_AddEntriesToLabnotebook(valuesTxt, keys, sweepNo, device, DATA_ACQUISITION_MODE)

	// ADC 9: unassoc (new)
	valuesTxT[]                      = ""
	valuesTxT[0][0][INDEP_HEADSTAGE] = "101112"
	keys[0][0][0]                    = CreateLBNUnassocKey(keyTxt, 9, XOP_CHANNEL_TYPE_ADC)
	ED_AddEntriesToLabnotebook(valuesTxt, keys, sweepNo, device, DATA_ACQUISITION_MODE)

	// associated
	valuesTxT[]        = ""
	valuesTxT[0][0][0] = "192021"
	valuesTxT[0][0][1] = "222324"
	keys[0][0][0]      = keyTxt
	ED_AddEntriesToLabnotebook(valuesTxt, keys, sweepNo, device, DATA_ACQUISITION_MODE)

	sweepNo = 2

	valuesDAC[]        = NaN
	valuesDAC[0][0][0] = 2
	valuesDAC[0][0][1] = 3
	keys[0][0][0]      = "DAC"
	ED_AddEntriesToLabnotebook(valuesDAC, keys, sweepNo, device, DATA_ACQUISITION_MODE)

	valuesADC[]        = NaN
	valuesADC[0][0][0] = 6
	valuesADC[0][0][1] = 7
	keys[0][0][0]      = "ADC"
	ED_AddEntriesToLabnotebook(valuesADC, keys, sweepNo, device, DATA_ACQUISITION_MODE)

	values[]        = 0
	values[0][0][0] = 1
	values[0][0][1] = 1
	keys[0][0][0]   = "Headstage Active"
	ED_AddEntriesToLabnotebook(valuesDAC, keys, sweepNo, device, DATA_ACQUISITION_MODE)

	values[]        = NaN
	values[0][0][0] = I_EQUAL_ZERO_MODE
	keys[0][0][0]   = CLAMPMODE_ENTRY_KEY
	ED_AddEntriesToLabnotebook(values, keys, sweepNo, device, DATA_ACQUISITION_MODE)

	// Set a acquisition cycle ID SCI
	values[]        = NaN
	values[0][0][0] = 44
	values[0][0][1] = 46
	keys[0][0][0]   = STIMSET_ACQ_CYCLE_ID_KEY
	keys[2][0][0]   = "1"
	ED_AddEntriesToLabnotebook(values, keys, sweepNo, device, DATA_ACQUISITION_MODE)

	// indep headstage
	values[]                      = NaN
	values[0][0][INDEP_HEADSTAGE] = 252627
	keys[0][0][0]                 = key
	ED_AddEntriesToLabnotebook(values, keys, sweepNo, device, DATA_ACQUISITION_MODE)

	valuesTxt[]                      = ""
	valuesTxt[0][0][INDEP_HEADSTAGE] = "252627"
	keys[0][0][0]                    = keyTxt
	ED_AddEntriesToLabnotebook(valuesTxt, keys, sweepNo, device, DATA_ACQUISITION_MODE)

	// Set a repeated acquisition cycle RAC
	values[]                      = NaN
	values[0][0][INDEP_HEADSTAGE] = 50
	keys[0][0][0]                 = RA_ACQ_CYCLE_ID_KEY
	keys[2][0][0]                 = "1"
	ED_AddEntriesToLabnotebook(values, keys, sweepNo, device, DATA_ACQUISITION_MODE)

	sweepNo = 3

	// HS0 with DA1 and AD0
	valuesDAC[]        = NaN
	valuesDAC[0][0][0] = 1
	keys[0][0][0]      = "DAC"
	ED_AddEntriesToLabnotebook(valuesDAC, keys, sweepNo, device, DATA_ACQUISITION_MODE)

	valuesADC[]        = NaN
	valuesADC[0][0][0] = 0
	keys[0][0][0]      = "ADC"
	ED_AddEntriesToLabnotebook(valuesADC, keys, sweepNo, device, DATA_ACQUISITION_MODE)

	// Create unassoc AD1 and DA0
	values[]                      = NaN
	values[0][0][INDEP_HEADSTAGE] = 1
	keys[0][0][0]                 = CreateLBNUnassocKey("ADC", 1, XOP_CHANNEL_TYPE_ADC)
	keys[2][0][0]                 = "0.1"
	ED_AddEntriesToLabnotebook(values, keys, sweepNo, device, DATA_ACQUISITION_MODE)
	values[]                      = NaN
	values[0][0][INDEP_HEADSTAGE] = 0
	keys[0][0][0]                 = CreateLBNUnassocKey("DAC", 0, XOP_CHANNEL_TYPE_DAC)
	keys[2][0][0]                 = "0.1"
	ED_AddEntriesToLabnotebook(values, keys, sweepNo, device, DATA_ACQUISITION_MODE)

	values[]        = 0
	values[0][0][0] = 1
	keys[0][0][0]   = "Headstage Active"
	ED_AddEntriesToLabnotebook(valuesDAC, keys, sweepNo, device, DATA_ACQUISITION_MODE)

	values[]        = NaN
	values[0][0][0] = V_CLAMP_MODE
	keys[0][0][0]   = CLAMPMODE_ENTRY_KEY
	ED_AddEntriesToLabnotebook(values, keys, sweepNo, device, DATA_ACQUISITION_MODE)

	// indep headstage
	values[]                      = NaN
	values[0][0][INDEP_HEADSTAGE] = hwType
	keys[0][0][0]                 = "Digitizer Hardware Type"
	keys[2][0][0]                 = "1"
	ED_AddEntriesToLabnotebook(values, keys, sweepNo, device, DATA_ACQUISITION_MODE)

	if(hwType == HARDWARE_NI_DAC)
		Make/FREE/T/N=(NUM_DA_TTL_CHANNELS) ttlChannels
		ttlChannels[2]                   = "2"
		strVal                           = TextWaveToList(ttlChannels, ";")
		valuesTxt[]                      = ""
		valuesTxt[0][0][INDEP_HEADSTAGE] = strVal
		keys[0][0][0]                    = "TTL channels"
		keys[2][0][0]                    = LABNOTEBOOK_NO_TOLERANCE
		ED_AddEntriesToLabnotebook(valuesTxt, keys, sweepNo, device, DATA_ACQUISITION_MODE)

	elseif(hwType == HARDWARE_ITC_DAC)

		values[]                      = NaN
		keys                          = ""
		values[0][0][INDEP_HEADSTAGE] = IsITC1600(device) ? HARDWARE_ITC_TTL_1600_RACK_ZERO : HARDWARE_ITC_TTL_DEF_RACK_ZERO
		keys[0][0][0]                 = "TTL rack zero channel"
		keys[2][0][0]                 = LABNOTEBOOK_NO_TOLERANCE
		ED_AddEntriesToLabnotebook(values, keys, sweepNo, device, DATA_ACQUISITION_MODE)

		values[]                      = NaN
		keys                          = ""
		values[0][0][INDEP_HEADSTAGE] = 1 << 2
		keys[0][0][0]                 = "TTL rack zero bits"
		keys[1][0][0]                 = "bit mask"
		keys[2][0][0]                 = LABNOTEBOOK_NO_TOLERANCE
		ED_AddEntriesToLabnotebook(values, keys, sweepNo, device, DATA_ACQUISITION_MODE)
	endif

	return [key, keyTxt]
End

Function/WAVE FakeSweepDataGeneratorProto(WAVE sweep, variable numChannels)

	ASSERT(0, "Prototype Function FakeSweepDataGeneratorProto called.")
End

Function/WAVE FakeSweepDataGeneratorDefault(WAVE sweep, variable numChannels)

	Redimension/N=(10, numChannels) sweep
	sweep = p
	SetScale x, 0, 0, "ms", sweep

	return sweep
End

Function/S CreateFakeSweepData(string win, string device, [variable sweepNo, FUNCREF FakeSweepDataGeneratorProto sweepGen])

	string list, key, keyTxt
	variable numChannels, hwType

	sweepNo = ParamIsDefault(sweepNo) ? 0 : sweepNo
	if(ParamIsDefault(sweepGen))
		FUNCREF FakeSweepDataGeneratorProto sweepGen = FakeSweepDataGeneratorDefault
	endif

	GetDAQDeviceID(device)

	[key, keyTxt] = PrepareLBN_IGNORE(device)

	// Use old 2D data format as sweep template and rely on sweep splitting for upconversion
	WAVE sweepTemplate = GetDAQDataWave(device, DATA_ACQUISITION_MODE)
	WAVE config        = GetDAQConfigWave(device)
	hwType = GetHardwareType(device)
	switch(sweepNo)
		case 0: // intended drop through
		case 1:
		case 2:
			numChannels = 4 // from LBN creation in PrepareLBN_IGNORE -> DA2, AD6, DA3, AD7
			WAVE sweep = sweepGen(sweepTemplate, numChannels)
			// config channel order: DAC, ADC, TTL
			Redimension/N=(numChannels, -1) config
			// creates HS 0 with DAC 2
			config[0][%ChannelType]   = XOP_CHANNEL_TYPE_DAC
			config[0][%ChannelNumber] = 2

			// creates HS 1 with DAC 3
			config[1][%ChannelType]   = XOP_CHANNEL_TYPE_DAC
			config[1][%ChannelNumber] = 3

			// creates HS 0 with ADC 6
			config[2][%ChannelType]   = XOP_CHANNEL_TYPE_ADC
			config[2][%ChannelNumber] = 6

			// creates HS 1 with ADC 7
			config[3][%ChannelType]   = XOP_CHANNEL_TYPE_ADC
			config[3][%ChannelNumber] = 7
			break
		case 3:
			numChannels = 5 // from LBN creation in PrepareLBN_IGNORE -> DA2, AD6, DA3, AD7
			WAVE sweep = sweepGen(sweepTemplate, numChannels)

			Redimension/N=(numChannels, -1) config
			// creates HS 0 with DAC 1
			config[0][%ChannelType]   = XOP_CHANNEL_TYPE_DAC
			config[0][%ChannelNumber] = 1

			// DAC 0 unassoc
			config[1][%ChannelType]   = XOP_CHANNEL_TYPE_DAC
			config[1][%ChannelNumber] = 0

			// creates HS 0 with ADC 0
			config[2][%ChannelType]   = XOP_CHANNEL_TYPE_ADC
			config[2][%ChannelNumber] = 0

			// ADC 1 unassoc
			config[3][%ChannelType]   = XOP_CHANNEL_TYPE_ADC
			config[3][%ChannelNumber] = 1
			// TTL 2
			config[4][%ChannelType]   = XOP_CHANNEL_TYPE_TTL
			config[4][%ChannelNumber] = hwType == HARDWARE_NI_DAC ? 2 : IsITC1600(device) ? HARDWARE_ITC_TTL_1600_RACK_ZERO : HARDWARE_ITC_TTL_DEF_RACK_ZERO
			break
		default:
			INFO("Unsupported sweep number in test setup")
			FAIL()
			return ""
	endswitch

	DFREF dfr = GetDeviceDataPath(device)
	MoveWave sweep, dfr:$GetSweepWaveName(sweepNo)
	MoveWave config, dfr:$GetConfigWaveName(sweepNo)

	PGC_SetAndActivateControl(BSP_GetPanel(win), "popup_DB_lockedDevices", str = device)
	win = GetCurrentWindow()
	REQUIRE_EQUAL_VAR(MIES_DB#DB_SplitSweepsIfReq(win, sweepNo), 0)

	list = GetAllDevicesWithContent()
	list = RemoveEnding(list, ";")
	CHECK_EQUAL_VAR(ItemsInList(list), 1)
	CHECK_EQUAL_STR(list, device)

	return win
End

Function/S GetDataBrowserWithData()
	string win, device, result

	device = HW_ITC_BuildDeviceString(StringFromList(0, DEVICE_TYPES_ITC), StringFromList(0, DEVICE_NUMBERS))

	win = DB_OpenDataBrowser()
	CreateFakeSweepData(win, device)
	win = GetCurrentWindow()

	result = BSP_GetDevice(win)
	CHECK_EQUAL_STR(device, result)

	return win
End

Function/WAVE TrackAnalysisFunctionCalls()
	variable i

	DFREF           dfr = root:
	WAVE/Z/SDFR=dfr wv  = anaFuncTracker

	if(WaveExists(wv))
		return wv
	else
		Make/N=(TOTAL_NUM_EVENTS, 2) dfr:anaFuncTracker/WAVE=wv
	endif

	for(i = 0; i < TOTAL_NUM_EVENTS; i += 1)
		SetDimLabel ROWS, i, $StringFromList(i, EVENT_NAME_LIST), wv
	endfor

	return wv
End

Function/WAVE TrackAnalysisFunctionOrder([numHeadstages])
	variable numHeadstages

	variable i

	DFREF             dfr = root:
	WAVE/D/Z/SDFR=dfr wv  = anaFuncOrder

	if(WaveExists(wv))
		return wv
	else
		Make/N=(TOTAL_NUM_EVENTS, numHeadstages)/D dfr:anaFuncOrder/WAVE=wv
	endif

	wv = NaN

	for(i = 0; i < TOTAL_NUM_EVENTS; i += 1)
		SetDimLabel ROWS, i, $StringFromList(i, EVENT_NAME_LIST), wv
	endfor

	return wv
End

Function/WAVE GetTrackActiveSetCount()

	DFREF           dfr = root:
	WAVE/Z/SDFR=dfr wv  = anaFuncActiveSetCount

	if(WaveExists(wv))
		return wv
	else
		Make/N=(100) dfr:anaFuncActiveSetCount/WAVE=wv
	endif

	wv = NaN

	return wv
End

/// @brief Track at which sweep count an analysis function was called.
Function/WAVE GetTrackSweepCounts()

	variable i

	DFREF           dfr = root:
	WAVE/Z/SDFR=dfr wv  = anaFuncSweepTracker

	if(WaveExists(wv))
		return wv
	else
		Make/N=(100, TOTAL_NUM_EVENTS, 2) dfr:anaFuncSweepTracker/WAVE=wv
	endif

	for(i = 0; i < TOTAL_NUM_EVENTS; i += 1)
		SetDimLabel COLS, i, $StringFromList(i, EVENT_NAME_LIST), wv
	endfor

	wv = NaN

	return wv
End

Function IsRunningInCI()
	return !IsEmpty(GetEnvironmentVariable("CI"))
End

static Function RetrieveAllWindowsInCI()

	if(!IsRunningInCI())
		return NaN
	endif

	DoIgorMenu "Control", "Retrieve All Windows"
End

Function TestBeginCommon()
	RetrieveAllWindowsInCI()

	MEN_ClearPackageSettings()
End

Function TestEndCommon()

	zeromq_stop()
End

Function TestCaseBeginCommon(string testcase)

	AdditionalExperimentCleanup()
End

Function TestCaseEndCommon(string testcase, [variable restartAsyncFramework])

	string contents

	restartAsyncFramework = ParamIsDefault(restartAsyncFramework) ? 0 : !!restartAsyncFramework

	contents = GetListOfObjects(GetDataFolderDFR(), ".*", recursive = 1, typeFlag = COUNTOBJECTS_WAVES)      \
	           + GetListOfObjects(GetDataFolderDFR(), ".*", recursive = 1, typeFlag = COUNTOBJECTS_VAR)      \
	           + GetListOfObjects(GetDataFolderDFR(), ".*", recursive = 1, typeFlag = COUNTOBJECTS_STR)      \
	           + GetListOfObjects(GetDataFolderDFR(), ".*", recursive = 1, typeFlag = COUNTOBJECTS_DATAFOLDER)

	INFO("Testcase: %s, Contents: %s", s0 = testcase, s1 = contents)
	CHECK_EMPTY_FOLDER()

	CheckForBugMessages()

	if(GetWaveTrackingMode() != UTF_WAVE_TRACKING_NONE)
		if(restartAsyncFramework)
			ASYNC_Stop()
		endif

		AdditionalExperimentCleanup()

		if(restartAsyncFramework)
			ASYNC_Start(ThreadProcessorCount, disableTask = 1)
		endif
	endif
End

Function SetAsyncChannelProperties(string device, WAVE asyncChannels, variable minValue, variable maxValue)
	variable chan
	string ctrl, title, unit

	for(chan : asyncChannels)
		ctrl = GetPanelControl(chan, CHANNEL_TYPE_ASYNC, CHANNEL_CONTROL_CHECK)
		PGC_SetAndActivateControl(device, ctrl, val = CHECKBOX_SELECTED)

		ctrl = GetPanelControl(chan, CHANNEL_TYPE_ALARM, CHANNEL_CONTROL_CHECK)
		PGC_SetAndActivateControl(device, ctrl, val = CHECKBOX_SELECTED)

		ctrl = GetPanelControl(chan, CHANNEL_TYPE_ASYNC, CHANNEL_CONTROL_ALARM_MIN)
		PGC_SetAndActivateControl(device, ctrl, val = minValue)

		ctrl = GetPanelControl(chan, CHANNEL_TYPE_ASYNC, CHANNEL_CONTROL_ALARM_MAX)
		PGC_SetAndActivateControl(device, ctrl, val = maxValue)

		ctrl = GetPanelControl(chan, CHANNEL_TYPE_ASYNC, CHANNEL_CONTROL_TITLE)
		sprintf title, "title %d", chan
		PGC_SetAndActivateControl(device, ctrl, str = title)

		ctrl = GetPanelControl(chan, CHANNEL_TYPE_ASYNC, CHANNEL_CONTROL_UNIT)
		sprintf unit, "unit %d", chan
		PGC_SetAndActivateControl(device, ctrl, str = unit)
	endfor
End

Function/WAVE ExtractSweepsFromSFPairs(WAVE/T/Z wv)
	variable numEntries, i

	if(!WaveExists(wv))
		return $""
	endif

	ASSERT(IsTextWave(wv), "Expected text wave")

	// Pairs are "A;B;C,X;Y;Z,"
	// where A and X are the sweep numbers which we want
	numEntries = DimSize(wv, ROWS)
	for(i = 0; i < numEntries; i += 1)
		WAVE/T data = ListToTextWave(wv[i], ",")
		data[] = StringFromList(0, data)
		wv[i]  = TextWaveToList(data, ";")
	endfor

	return wv
End

Function CheckForBugMessages()
	variable bugCount_ts

	NVAR bugCount = $GetBugCount()
	if(IsFinite(bugCount))
		CHECK_EQUAL_VAR(bugCount, 0)
	else
		CHECK_EQUAL_VAR(bugCount, NaN)
	endif

	TUFXOP_AcquireLock/N=(TSDS_BUGCOUNT)
	bugCount_ts = TSDS_ReadVar(TSDS_BUGCOUNT, defValue = 0, create = 1)
	TUFXOP_ReleaseLock/N=(TSDS_BUGCOUNT)

	if(IsFinite(bugCount_ts))
		CHECK_EQUAL_VAR(bugCount_ts, 0)
	else
		CHECK_EQUAL_VAR(bugCount_ts, NaN)
	endif
End

Function DisableBugChecks()

	NVAR bugCount = $GetBugCount()
	bugCount = NaN

	TSDS_WriteVar(TSDS_BUGCOUNT, NaN)
End

/// @brief Exhaust all memory so that only `amountOfFreeMemoryLeft` [GB] is left
///
/// Unwise use of this function can break Igor!
Function ExhaustMemory(amountOfFreeMemoryLeft)
	variable amountOfFreeMemoryLeft

	variable i, expo = 10, err
	string str

	for(i = expo; i >= 0;)
		err = GetRTError(1)
		str = UniqueName("base", 1, 0)
		Make/D/N=(10^expo) $str; err = GetRTError(1)

		if(err != 0)
			expo -= 1
		endif

		printf "Free Memory: %gGB\r", GetFreeMemory()

		if(GetFreeMemory() < amountOfFreeMemoryLeft)
			break
		endif
	endfor
End

Function LoadStimsetsIfRequired()
	string   filepath
	variable needsLoading

	filepath = GetTestStimsetFullFilePath()
	GetFileFolderInfo/Q/Z filePath

	// speedup executing the tests locally
	if(!DataFolderExists("root:WaveBuilder"))
		needsLoading = 1
	else
		NVAR/Z modTime = root:WaveBuilder:modTime

		if(!NVAR_Exists(modTime) || V_modificationDate != modTime)
			needsloading = 1
		endif
	endif

	if(needsLoading)
		NWB_LoadAllStimsets(filename = filepath, overwrite = 1)
		DuplicateDataFolder/O=1 root:MIES:WaveBuilder, root:WaveBuilder; AbortOnRTE
		variable/G root:WaveBuilder:modTime = V_modificationDate
	endif
End

Function MoveStimsetsIntoPlace()

	GetMiesPath()
	DuplicateDataFolder root:WaveBuilder, root:MIES:WaveBuilder
	REQUIRE(DataFolderExists("root:MIES:WaveBuilder:SavedStimulusSetParameters:DA"))
End

Function/S GetTestName()

	return "MIES with " + GetExperimentName()
End

Function/S GetDefaultTraceOptions()

	string traceOptions = ""

	traceOptions = ReplaceNumberByKey(UTF_KEY_REGEXP, traceOptions, 1)

	if(!IsRunningInCI() || !CmpStr("1", GetEnvironmentVariable("CI_INSTRUMENT_TESTS")))
		traceOptions = ReplaceNumberByKey(UTF_KEY_HTMLCREATION, traceOptions, 0)
		traceOptions = ReplaceNumberByKey(UTF_KEY_COBERTURA, traceOptions, 1)
	endif

	return traceOptions
End

Function/WAVE GetMIESMacros()

	string win
	string allMacros = ""

	WAVE/T miesWindows = ListToTextWave(WinList("MIES_*.ipf", ";", "WIN:128"), ";")
	for(win : miesWindows)
		allMacros += MacroList("*", ";", "WIN:" + win)
	endfor

	return ListToTextWave(allMacros, ";")
End

Function/S GetTestStimsetFullFilePath()

	string fullPath = GetFolder(FunctionPath("")) + "_2017_09_01_192934-compressed.nwb"

	ASSERT(FileExists(fullPath), "Stimset File for tests if missing.")

	return fullPath
End

Function/S LoadSweeps(string winAB)

	PGC_SetAndActivateControl(winAB, "button_load_sweeps")

	return StringFromList(0, WinList("*", ";", "WIN:" + num2istr(WINTYPE_GRAPH)))
End

/// @brief Open the given files in the analysis browser. By default files are located relative to the symbolic path `home` unless absolutePaths is set
Function [string abWin, string sweepBrowsers] OpenAnalysisBrowser(WAVE/T files, [variable loadSweeps, variable loadStimsets, variable absolutePaths])

	variable idx
	string filePath, fullFilePath

	absolutePaths = ParamIsDefault(absolutePaths) ? 0 : !!absolutePaths
	if(ParamIsDefault(loadSweeps))
		loadSweeps = 0
	else
		loadSweeps = !!loadSweeps
	endif
	loadStimsets = ParamIsDefault(loadStimsets) ? 0 : !!loadStimsets

	if(absolutePaths)
		WAVE/T filesWithPath = files
	else
		PathInfo home

		Duplicate/FREE/T files, filesWithPath
		filesWithPath[] = S_path + GetHFSPath(files[p])
	endif

	abWin = AB_OpenAnalysisBrowser(restoreSettings = 0)

	for(fullFilePath : filesWithPath)
		MIES_AB#AB_AddElementToSourceList(fullFilePath)
	endfor

	PGC_SetAndActivateControl(abWin, "button_AB_refresh")

	if(!loadSweeps && !loadStimsets)
		return [abWin, ""]
	endif

	sweepBrowsers = ""
	WAVE/T expBrowserList = GetExperimentBrowserGUIList()
	WAVE   expBrowserSel  = GetExperimentBrowserGUISel()

	WAVE/Z indizes = FindIndizes(expBrowserList, colLabel = "file", prop = PROP_EMPTY | PROP_NOT)

	if(loadSweeps)
		for(idx : indizes)
			expBrowserSel[idx][0][0] = LISTBOX_TREEVIEW | LISTBOX_SELECTED
			PGC_SetAndActivateControl(abWin, "button_load_sweeps")
		endfor

		sweepBrowsers = WinList("*", ";", "WIN:" + num2istr(WINTYPE_GRAPH))
	endif

	if(loadStimsets)
		for(idx : indizes)
			expBrowserSel[idx][0][0] = LISTBOX_TREEVIEW | LISTBOX_SELECTED
			PGC_SetAndActivateControl(abWin, "button_load_stimsets")
		endfor
	endif

	return [abWin, sweepBrowsers]
End

Function DoExpensiveChecks()

	variable expensive

#ifdef AUTOMATED_TESTING_EXPENSIVE
	return 1
#endif

	expensive = GetEnvironmentVariableAsBoolean("CI_EXPENSIVE_CHECKS")

	if(IsFinite(expensive))
		return expensive
	endif

	return 0
End

Function GetWaveTrackingMode()

	if(DoExpensiveChecks())
		return UTF_WAVE_TRACKING_ALL
	endif

	return UTF_WAVE_TRACKING_NONE
End

Function ResetOverrideResults()

	KillOrMoveToTrash(wv = root:overrideResults)
	Make/N=0 root:overrideResults
End

Function [string baseSet, string stimsetList, string customWavePath, variable amplitude] CreateDependentStimset()

	string setNameC, setNameF1, setNameF2, setNameB, formula, wPath

	string   wName           = "customWave"
	string   setNameCustom   = "CustomSet"
	string   setNameFormula1 = "formula1"
	string   setNameFormula2 = "formula2"
	string   setNameBase     = "baseSet"
	string   chanTypeSuffix  = "_DA_0"
	variable val             = 3

	DFREF dfr = GetWaveBuilderPath()
	KillDataFolder dfr

	KillWaves/Z root:$wName
	Make root:$wName/WAVE=customWave = val

	setNameC = ST_CreateStimset(setNameCustom, CHANNEL_TYPE_DAC)
	ST_SetStimsetParameter(setNameC, "Total number of epochs", var = 1)
	ST_SetStimsetParameter(setNameC, "Total number of steps", var = 1)
	ST_SetStimsetParameter(setNameC, "Type of Epoch 0", var = EPOCH_TYPE_CUSTOM)
	wPath = GetWavesDataFolder(customWave, 2)
	ST_SetStimsetParameter(setNameC, "Custom epoch wave name", epochIndex = 0, str = wPath)

	setNameF1 = ST_CreateStimset(setNameFormula1, CHANNEL_TYPE_DAC)
	ST_SetStimsetParameter(setNameF1, "Total number of epochs", var = 1)
	ST_SetStimsetParameter(setNameF1, "Total number of steps", var = 1)
	ST_SetStimsetParameter(setNameF1, "Type of Epoch 0", var = EPOCH_TYPE_COMBINE)
	formula = "2*" + LowerStr(setNameC) + "?"
	ST_SetStimsetParameter(setNameF1, "Combine epoch formula", epochIndex = 0, str = formula)
	ST_SetStimsetParameter(setNameF1, "Combine epoch formula version", epochIndex = 0, str = WAVEBUILDER_COMBINE_FORMULA_VER)

	setNameF2 = ST_CreateStimset(setNameFormula2, CHANNEL_TYPE_DAC)
	ST_SetStimsetParameter(setNameF2, "Total number of epochs", var = 1)
	ST_SetStimsetParameter(setNameF2, "Total number of steps", var = 1)
	ST_SetStimsetParameter(setNameF2, "Type of Epoch 0", var = EPOCH_TYPE_COMBINE)
	formula = "2*" + LowerStr(setNameF1) + "?"
	ST_SetStimsetParameter(setNameF2, "Combine epoch formula", epochIndex = 0, str = formula)
	ST_SetStimsetParameter(setNameF2, "Combine epoch formula version", epochIndex = 0, str = WAVEBUILDER_COMBINE_FORMULA_VER)

	setNameB = ST_CreateStimset(setNameBase, CHANNEL_TYPE_DAC)
	ST_SetStimsetParameter(setNameB, "Total number of epochs", var = 1)
	ST_SetStimsetParameter(setNameB, "Total number of steps", var = 1)
	ST_SetStimsetParameter(setNameB, "Type of Epoch 0", var = EPOCH_TYPE_COMBINE)
	formula = "2*" + LowerStr(setNameF2) + "?"
	ST_SetStimsetParameter(setNameB, "Combine epoch formula", epochIndex = 0, str = formula)
	ST_SetStimsetParameter(setNameB, "Combine epoch formula version", epochIndex = 0, str = WAVEBUILDER_COMBINE_FORMULA_VER)

	amplitude = val * 2^3
	WAVE/Z wBaseSet = WB_CreateAndGetStimSet(setNameBase + chanTypeSuffix)
	CHECK_WAVE(wBaseSet, NUMERIC_WAVE)
	CHECK_GT_VAR(DimSize(wBaseSet, ROWS), 0)
	WaveStats/Q wBaseSet
	CHECK_EQUAL_VAR(V_max, amplitude)
	CHECK_EQUAL_VAR(V_min, amplitude)

	DFREF dfr = GetWBSvdStimSetPath()
	KillDataFolder dfr

	stimsetList = AddListItem(setNameC, "")
	stimsetList = AddListItem(setNameF1, stimsetList)
	stimsetList = AddListItem(setNameF2, stimsetList)
	stimsetList = AddListItem(setNameB, stimsetList)
	stimsetList = SortList(stimsetList, ";", 16)

	wPath = GetWavesDataFolder(customWave, 2)

	return [setNameB, stimsetList, wPath, amplitude]
End

static Function TestEpochRecreationRemoveUnsupportedUserEpochs(WAVE/T epochChannel, variable type)

	string supportedUserEpochsRegExp
	string regexpUserEpochs = "^" + EPOCH_SHORTNAME_USER_PREFIX + ".*"

	Make/FREE/T supportedUserEpochs = {"^U_CR_CE$", "^U_CR_SE$", PSQ_BASELINE_CHUNK_SHORT_NAME_RE_MATCHER, "^U_BLS[[:digit:]]+$", "^U_TP[[:digit:]]+_B0$", "^U_TP[[:digit:]]+_P$", "^U_TP[[:digit:]]+_B1$", "^U_TP[[:digit:]]+$", "^U_RA_DS$", "^U_RA_UD$"}
	supportedUserEpochsRegExp = ConvertListToRegexpWithAlternations(TextWaveToList(supportedUserEpochs, ";", trailSep = 0), literal = 0)
	Make/FREE/T/N=(DimSize(epochChannel, ROWS)) shortnames = EP_GetShortName(epochChannel[p][EPOCH_COL_TAGS])
	WAVE/Z userEpochIndices = FindIndizes(shortNames, str = regexpUserEpochs, prop = PROP_GREP)
	if(!WaveExists(userEpochIndices))
		return NaN
	endif
	Make/FREE/T/N=(DimSize(userEpochIndices, ROWS)) userEpochShortNames = shortnames[userEpochIndices[p]]
	WAVE/Z matches = FindIndizes(userEpochShortNames, str = supportedUserEpochsRegExp, prop = PROP_GREP | PROP_NOT)
	if(!WaveExists(matches))
		return NaN
	endif
	matches[] = userEpochIndices[matches[p]]
	DeleteWavePoint(epochChannel, ROWS, indices = matches)
End

Function TestEpochRecreation(string device, variable sweepNo)

	WAVE/Z numericalValues = GetLBNumericalValues(device)
	WAVE/Z textualValues   = GetLBTextualValues(device)
	DFREF  deviceDFR       = GetDeviceDataPath(device)
	DFREF  sweepDFR        = GetSingleSweepFolder(deviceDFR, sweepNo)

	WAVE epochWave = MIES_EP#EP_RecreateEpochsFromLoadedData(numericalValues, textualValues, sweepDFR, sweepNo)

	CompareEpochsOfSweep(numericalValues, textualValues, sweepNo, sweepDFR, epochWave)

End

/// @brief Compares epochs of all channels of a given sweep. By default equality is checked, unless historic is set.
///        Because the epoch recreation does not support recreation of all user epochs, in @ref TestEpochRecreationRemoveUnsupportedUserEpochs a
///        list of supported user epochs in epoch recreation is set. All other (unsupported) user epochs are removed from the reference epochs of
///        the experiment before comparison.
///
/// @param numericalValues numerical labnotebook values
/// @param textualValues   textual labnotebook values
/// @param sweepNo         sweep number
/// @param sweepDFR        sweep datafolder
/// @param epochRec        4d epochs wave from recreated epochs
/// @param historic        [optional, default 0], when set instead of equality only the existence of epochs based on the shortNames is checked.
///                        All non-user epochs that exist in the reference epochs from the experiment must exist in the recreated epochs
///                        All user epochs that were recreated must exist in the reference epochs from the experiment
/// @param userEpochRef    [optional, default null] When set the user epochs from this wave are used to extend the epochs from the experiment if not already present
///                        These epochs usually originate from exported recreated epochs used for test case @ref TestEpochRecreationShortNames
Function CompareEpochsOfSweep(WAVE/Z numericalValues, WAVE/Z/T textualValues, variable sweepNo, DFREF sweepDFR, WAVE epochRec, [variable historic, WAVE/Z userEpochRef])

	variable channelNumber, index, type
	string anaFunc

	historic = ParamIsDefault(historic) ? 0 : !!historic

	for(channelNumber = 0; channelNumber < NUM_DA_TTL_CHANNELS; channelNumber += 1)

		WAVE/Z/T epochChannelRef = EP_FetchEpochs(numericalValues, textualValues, sweepNo, sweepDFR, channelNumber, XOP_CHANNEL_TYPE_DAC)
		WAVE/Z/T epochChannelRec = EP_FetchEpochsFromRecreated(epochRec, channelNumber, XOP_CHANNEL_TYPE_DAC)

		if(WaveExists(epochChannelRef))
			[WAVE settings, index] = GetLastSettingChannel(numericalValues, textualValues, sweepNo, "Generic function", channelNumber, XOP_CHANNEL_TYPE_DAC, DATA_ACQUISITION_MODE)
			if(WaveExists(settings))
				WAVE/T settingsT = settings
				type = MapAnaFuncToConstant(settingsT[index])
				TestEpochRecreationRemoveUnsupportedUserEpochs(epochChannelRef, type)
			endif
			if(historic)
				if(WaveExists(userEpochRef))
					WAVE/T epochChannelRecUser = EP_FetchEpochsFromRecreated(userEpochRef, channelNumber, XOP_CHANNEL_TYPE_DAC)
					ExtendRefEpochsWithUserEpochs(epochChannelRef, epochChannelRecUser)
				endif
				CompareEpochsHistoricChannel(epochChannelRef, epochChannelRec)
			else
				// also TP channels can be active but have no epochs
				AdaptRecEpoch_U_RA_UD(epochChannelRec, epochChannelRef)
				CHECK_EQUAL_WAVES(epochChannelRec, epochChannelRef)
			endif
		else
			CHECK_WAVE(epochChannelRec, NULL_WAVE)
		endif
	endfor
End

static Function AdaptRecEpoch_U_RA_UD(WAVE/T epochChannelRec, WAVE/T epochChannelRef)

	string shortNameRef

	Make/FREE/T/N=(DimSize(epochChannelRec, ROWS)) shortnamesRec = EP_GetShortName(epochChannelRec[p][EPOCH_COL_TAGS])
	FindValue/TEXT="U_RA_UD"/TXOP=4 shortnamesRec
	if(V_Value == -1)
		// Nothing to adapt
		return NaN
	endif

	shortNameRef = EP_GetShortName(epochChannelRef[V_row][EPOCH_COL_TAGS])
	CHECK_EQUAL_STR(shortnamesRec[V_row], shortNameRef)
	epochChannelRec[V_row][EPOCH_COL_ENDTIME] = epochChannelRef[V_row][EPOCH_COL_ENDTIME]
End

/// @brief This function extends epochs of a single channel from the experiment with user epochs from a reference source if this user epochs do
///        not exist in the epochs of the experiment. The reference source is typically a set of exported recreated epochs as implemented in test case
///        @ref TestEpochRecreationShortNames
///        A typical case is an experiment with data created with an old MIES version where user epochs from analysis function were not implemented.
///        In that case the current epoch recreation creates more epochs than there were originally in the experiment.
///        The extension from this function fulfills then two points:
///        - the comparison as implemented in @ref CompareEpochsHistoricChannel works
///        - changes in epoch recreation since the point of exporting the reference epochs can be found
static Function ExtendRefEpochsWithUserEpochs(WAVE/T epochChannelRef, WAVE/T epochChannelRecRef)

	variable i, numEpochs, numEpochsRef
	string shortName

	numEpochsRef = DimSize(epochChannelRef, ROWS)
	Make/FREE/T/N=(numEpochsRef) epRefShortnames = EP_GetShortName(epochChannelRef[p][EPOCH_COL_TAGS])
	numEpochs = DimSize(epochChannelRecRef, ROWS)
	for(i = 0; i < numEpochs; i += 1)
		shortName = EP_GetShortName(epochChannelRecRef[i][EPOCH_COL_TAGS])
		if(strsearch(shortName, EPOCH_SHORTNAME_USER_PREFIX, 0) != 0)
			continue
		endif
		FindValue/TEXT=shortName/TXOP=4 epRefShortnames
		if(V_value >= 0)
			continue
		endif
		Redimension/N=(numEpochsRef + 1, -1) epochChannelRef
		epochChannelRef[numEpochsRef][] = epochChannelRecRef[i][q]
		numEpochsRef                   += 1
	endfor
End

/// @brief The historic epoch comparison only compares existence of epochs from shortnames if present
static Function CompareEpochsHistoricChannel(WAVE/T epochChannelRef, WAVE/T epochChannelRec)

	string shortName
	variable i, numEpochs, numEpochsRec

	numEpochs = DimSize(epochChannelRef, ROWS)
	Make/FREE/T/N=(numEpochs) epRefShortnames = EP_GetShortName(epochChannelRef[p][EPOCH_COL_TAGS])
	WAVE/T UniqueShortNames = GetUniqueEntries(epRefShortnames)
	if(DimSize(UniqueShortNames, ROWS) == 1 && IsEmpty(UniqueShortNames[0]))
		print "Note: Epochs in experiment have no shortNames, skipped CompareEpochsHistoricChannel check."
		return NaN
	endif

	numEpochsRec = DimSize(epochChannelRec, ROWS)
	Make/FREE/T/N=(numEpochsRec) epRecShortnames = EP_GetShortName(epochChannelRec[p][EPOCH_COL_TAGS])
	ASSERT(numEpochs > 0, "numEpochs is zero")
	// test if all reference epochs are also present in recreated
	for(i = 0; i < numEpochs; i += 1)
		shortName = epRefShortnames[i]
		if(IsEmpty(shortName))
			continue
		endif
		FindValue/TEXT=shortName/TXOP=4 epRecShortnames
		INFO("Could not find reference epoch %s in recreated epochs.", s0 = shortName)
		CHECK_GE_VAR(V_value, 0)
	endfor
	// test if all recreated user epochs are also present in reference
	ASSERT(numEpochsRec > 0, "numEpochsRec is zero")
	for(i = 0; i < numEpochsRec; i += 1)
		shortName = epRecShortnames[i]
		if(strsearch(shortName, EPOCH_SHORTNAME_USER_PREFIX, 0) != 0)
			continue
		endif
		FindValue/TEXT=shortName/TXOP=4 epRefShortnames
		INFO("Could not find recreated user epoch %s in reference epochs.", s0 = shortName)
		CHECK_GE_VAR(V_value, 0)
	endfor
End

Function ExecuteSweepFormulaInDB(string code, string win)
	string sfFormula, bsPanel

	bsPanel = BSP_GetPanel(win)

	sfFormula = BSP_GetSFFormula(win)
	ReplaceNotebookText(sfFormula, code)

	PGC_SetAndActivateControl(bsPanel, "check_BrowserSettings_SF", val = CHECKBOX_SELECTED)
	PGC_SetAndActivateControl(bsPanel, "button_sweepFormula_display")

	return GetValDisplayAsNum(bsPanel, "status_sweepFormula_parser")
End

/// @brief test two jsonIDs for equal content
Function CHECK_EQUAL_JSON(jsonID0, jsonID1)
	variable jsonID0, jsonID1

	string jsonDump0, jsonDump1

	JSONXOP_Dump/IND=2 jsonID0
	jsonDump0 = S_Value
	JSONXOP_Dump/IND=2 jsonID1
	jsonDump1 = S_Value

	CHECK_EQUAL_STR(jsonDump0, jsonDump1)
End

/// Add 10 sweeps from various AD/DA channels to the fake databrowser
Function [variable numSweeps, variable numChannels, WAVE/U/I channels] FillFakeDatabrowserWindow(string win, string device, variable channelTypeNumeric, string lbnTextKey, string lbnTextValue)

	variable i, j, channelNumber, sweepNumber, clampMode, channelType
	string name, trace

	numSweeps   = 10
	numChannels = 4

	variable dataSize = 128
	variable mode     = DATA_ACQUISITION_MODE

	string channelTypeStr  = StringFromList(channelTypeNumeric, XOP_CHANNEL_NAMES)
	string channelTypeStrC = channelTypeStr + "C"

	WAVE/T numericalKeys   = GetLBNumericalKeys(device)
	WAVE   numericalValues = GetLBNumericalValues(device)
	KillWaves numericalKeys, numericalValues

	Make/FREE/T/N=(1, 1) keys = {{channelTypeStrC}}
	Make/FREE/U/I/N=(numChannels) connections = {7, 5, 3, 1}
	Make/FREE/U/I/N=(numSweeps, numChannels) channels = q * 2
	Make/D/FREE/N=(LABNOTEBOOK_LAYER_COUNT) values = NaN
	Make/D/FREE/N=(LABNOTEBOOK_LAYER_COUNT) clampModeValues = NaN
	Make/T/FREE/N=(LABNOTEBOOK_LAYER_COUNT) valuesText = lbnTextValue
	Make/FREE/T/N=(1, 1) dacKeys = "DAC"
	Make/FREE/T/N=(1, 1) adcKeys = "ADC"
	Make/FREE/T/N=(1, 1) clampModeKeys = "Operating Mode"
	Make/FREE/T/N=(1, 1) textKeys = lbnTextKey

	DFREF dfr = GetDeviceDataPath(device)
	GetDAQDeviceID(device)

	for(i = 0; i < numSweeps; i += 1)
		sweepNumber = i
		WAVE sweepTemplate = GetDAQDataWave(device, DATA_ACQUISITION_MODE)
		WAVE sweep         = FakeSweepDataGeneratorDefault(sweepTemplate, numChannels)
		WAVE config        = GetDAQConfigWave(device)
		Redimension/N=(numChannels, -1) config
		for(j = 0; j < numChannels; j += 1)
			clampMode                       = mod(sweepNumber, 2) ? V_CLAMP_MODE : I_CLAMP_MODE
			channelNumber                   = channels[i][j]
			values[connections[j]]          = channelNumber
			clampModeValues[connections[j]] = clampMode
			config[j][%ChannelType]         = XOP_CHANNEL_TYPE_ADC
			config[j][%ChannelNumber]       = channelNumber
		endfor

		// create sweeps with dummy data for sweeps() operation thats called when omitting select
		MoveWave sweep, dfr:$GetSweepWaveName(sweepNumber)
		MoveWave config, dfr:$GetConfigWaveName(sweepNumber)

		Redimension/N=(1, 1, LABNOTEBOOK_LAYER_COUNT)/E=1 values, clampModeValues
		Redimension/N=(1, 1, LABNOTEBOOK_LAYER_COUNT)/E=1 valuesText
		ED_AddEntriesToLabnotebook(values, keys, sweepNumber, device, mode)
		ED_AddEntriesToLabnotebook(values, dacKeys, sweepNumber, device, mode)
		ED_AddEntriesToLabnotebook(values, adcKeys, sweepNumber, device, mode)
		ED_AddEntriesToLabnotebook(clampModeValues, clampModeKeys, sweepNumber, device, mode)
		Redimension/N=(LABNOTEBOOK_LAYER_COUNT)/E=1 values, clampModeValues
		ED_AddEntryToLabnotebook(device, keys[0], values, overrideSweepNo = sweepNumber)
		ED_AddEntriesToLabnotebook(valuesText, textKeys, sweepNumber, device, mode)

		PGC_SetAndActivateControl(BSP_GetPanel(win), "popup_DB_lockedDevices", str = device)
		win = GetCurrentWindow()

		REQUIRE_EQUAL_VAR(MIES_DB#DB_SplitSweepsIfReq(win, sweepNumber), 0)
	endfor

	RemoveFromGraph/ALL
	TUD_Clear(win)

	Make/FREE/N=(dataSize, numSweeps, numChannels) input = q + p^r // + gnoise(1)
	for(i = 0; i < numSweeps; i += 1)
		sweepNumber = i
		for(j = 0; j < numChannels; j += 1)
			channelNumber = config[j][%ChannelNumber]
			channelType   = config[j][%ChannelType]

			DFREF singleSweepFolder    = GetSingleSweepFolder(dfr, sweepNumber)
			WAVE  singleColumnDataWave = GetDAQDataSingleColumnWave(singleSweepFolder, channelType, channelNumber)
			Redimension/N=(dataSize) singleColumnDataWave

			sprintf trace, "trace_%d_%s", sweepNumber, NameOfWave(singleColumnDataWave)
			clampMode = mod(sweepNumber, 2) ? V_CLAMP_MODE : I_CLAMP_MODE

			AppendToGraph/W=$win singleColumnDataWave/TN=$trace
			WAVE numericalValues = BSP_GetLogbookWave(win, LBT_LABNOTEBOOK, LBN_NUMERICAL_VALUES, sweepNumber = sweepNumber)
			WAVE textualValues   = BSP_GetLogbookWave(win, LBT_LABNOTEBOOK, LBN_TEXTUAL_VALUES, sweepNumber = sweepNumber)
			TUD_SetUserDataFromWaves(win, trace, {"experiment", "textualValues", "numericalValues", "fullPath", "traceType", "occurence", "channelType", "channelNumber", "sweepNumber", "GUIChannelNumber", "clampMode", "SweepMapIndex"},                                                              \
			                         {"blah", GetWavesDataFolder(textualValues, 2), GetWavesDataFolder(numericalValues, 2), GetWavesDataFolder(singleColumnDataWave, 2), "Sweep", "0", channelTypeStr, num2str(channelNumber), num2str(sweepNumber), num2istr(channelNumber), num2istr(clampMode), "NaN"})
		endfor
	endfor

	return [numSweeps, numChannels, channels]
End

Function [string win, string device] CreateEmptyUnlockedDataBrowserWindow()

	string extWin

	device = HW_ITC_BuildDeviceString(StringFromList(0, DEVICE_TYPES_ITC), StringFromList(0, DEVICE_NUMBERS))
	DFREF dfr = GetDeviceDataPath(device)
	win = DB_OpenDataBrowser()
	return [win, device]
End

Function LoadMIESFolderFromPXP(string fName)

	variable numObjectsLoaded
	string   miesPath

	PathInfo home

	DFREF dfr = GetMIESPath()
	KillDataFolder dfr

	miesPath = GetMiesPathAsString()

	DFREF dfr     = NewFreeDataFolder()
	DFREF savedDF = GetDataFolderDFR()
	SetDataFolder dfr
	LoadData/Q/R/P=home/S=miesPath fName
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
End
