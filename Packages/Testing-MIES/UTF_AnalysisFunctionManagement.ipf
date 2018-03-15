﻿#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma ModuleName=AnalysisFunctionTesting

static Function ChangeAnalysisFunctions()

	WAVE/T wv = root:MIES:WaveBuilder:SavedStimulusSetParameters:DA:WPT_AnaFuncAbortPre_DA_0

	wv[][%Set] = ""
	wv[%$"Analysis pre DAQ function"][%Set]    = "AbortPreDAQ"

	WAVE/T wv = root:MIES:WaveBuilder:SavedStimulusSetParameters:DA:WPT_AnaFuncDiff_DA_0

	wv[][%Set] = ""
	wv[%$"Analysis pre DAQ function"][%Set]    = "preDAQ"
	wv[%$"Analysis pre sweep function"][%Set]  = "preSweep"
	wv[%$"Analysis mid sweep function"][%Set]  = "midSweep"
	wv[%$"Analysis post sweep function"][%Set] = "postSweep"
	wv[%$"Analysis post set function"][%Set]   = "postSet"
	wv[%$"Analysis post DAQ function"][%Set]   = "postDAQ"

	WAVE/T wv = root:MIES:WaveBuilder:SavedStimulusSetParameters:DA:WPT_AnaFuncInvalid1_DA_0

	wv[][%Set] = ""
	wv[%$"Analysis pre DAQ function"][%Set]    = "InvalidSignatureAndReturnType"
	wv[%$"Analysis pre sweep function"][%Set]  = "InvalidSignature"
	wv[%$"Analysis mid sweep function"][%Set]  = "InvalidReturnTypeAndValidSig_V1"
	wv[%$"Analysis post sweep function"][%Set] = "InvalidSignatureAndReturnType"
	wv[%$"Analysis post set function"][%Set]   = "InvalidSignature"
	wv[%$"Analysis post DAQ function"][%Set]   = "InvalidSignatureAndReturnType"

	WAVE/T wv = root:MIES:WaveBuilder:SavedStimulusSetParameters:DA:WPT_AnaFuncInvalid2_DA_0

	wv[][%Set] = ""
	wv[%$"Analysis pre DAQ function"][%Set]    = "InvalidSignatureAndReturnType"
	wv[%$"Analysis pre sweep function"][%Set]  = "InvalidSignature"
	wv[%$"Analysis mid sweep function"][%Set]  = "InvalidReturnTypeAndValidSig_V2"
	wv[%$"Analysis post sweep function"][%Set] = "InvalidSignatureAndReturnType"
	wv[%$"Analysis post set function"][%Set]   = "InvalidSignature"
	wv[%$"Analysis post DAQ function"][%Set]   = "InvalidSignatureAndReturnType"

	WAVE/T wv = root:MIES:WaveBuilder:SavedStimulusSetParameters:DA:WPT_AnaFuncStopMid_DA_0

	wv[][%Set] = ""
	wv[%$"Analysis mid sweep function"][%Set]  = "StopMidSweep"

	WAVE/T wv = root:MIES:WaveBuilder:SavedStimulusSetParameters:DA:WPT_AnaFuncValidMult_DA_0

	wv[][%Set] = ""
	wv[%$"Analysis pre DAQ function"][%Set]    = "ValidMultHS_V1"
	wv[%$"Analysis pre sweep function"][%Set]  = "ValidMultHS_V1"
	wv[%$"Analysis mid sweep function"][%Set]  = "ValidMultHS_V1"
	wv[%$"Analysis post sweep function"][%Set] = "ValidMultHS_V1"
	wv[%$"Analysis post set function"][%Set]   = "ValidMultHS_V1"
	wv[%$"Analysis post DAQ function"][%Set]   = "ValidMultHS_V1"

	WAVE/T wv = root:MIES:WaveBuilder:SavedStimulusSetParameters:DA:WPT_AnaFuncValid1_DA_0

	wv[][%Set] = ""
	wv[%$"Analysis pre DAQ function"][%Set]    = "ValidFunc_V1"
	wv[%$"Analysis pre sweep function"][%Set]  = "ValidFunc_V1"
	wv[%$"Analysis mid sweep function"][%Set]  = "ValidFunc_V1"
	wv[%$"Analysis post sweep function"][%Set] = "ValidFunc_V1"
	wv[%$"Analysis post set function"][%Set]   = "ValidFunc_V1"
	wv[%$"Analysis post DAQ function"][%Set]   = "ValidFunc_V1"

	WAVE/T wv = root:MIES:WaveBuilder:SavedStimulusSetParameters:DA:WPT_AnaFuncValid2_DA_0

	wv[][%Set] = ""
	wv[%$"Analysis pre DAQ function"][%Set]    = "ValidFunc_V2"
	wv[%$"Analysis pre sweep function"][%Set]  = "ValidFunc_V2"
	wv[%$"Analysis mid sweep function"][%Set]  = "ValidFunc_V2"
	wv[%$"Analysis post sweep function"][%Set] = "ValidFunc_V2"
	wv[%$"Analysis post set function"][%Set]   = "ValidFunc_V2"
	wv[%$"Analysis post DAQ function"][%Set]   = "ValidFunc_V2"

	WAVE/T wv = root:MIES:WaveBuilder:SavedStimulusSetParameters:DA:WPT_AnaFuncValid3_DA_0

	wv[][%Set] = ""
	wv[%$"Analysis function (generic)"][%Set]  = "ValidFunc_V3"


	WAVE/T wv = root:MIES:WaveBuilder:SavedStimulusSetParameters:DA:WPT_AnaFuncParams1_DA_0

	wv[][%Set] = ""
	wv[%$"Analysis function (generic)"][%Set]  = "Params1_V3"

	WAVE/T wv = root:MIES:WaveBuilder:SavedStimulusSetParameters:DA:WPT_AnaFuncGeneric_DA_0

	wv[][%Set] = ""
	wv[%$"Analysis pre DAQ function"][%Set]    = "NotCalled_V1"
	wv[%$"Analysis pre sweep function"][%Set]  = "NotCalled_V1"
	wv[%$"Analysis mid sweep function"][%Set]  = "NotCalled_V1"
	wv[%$"Analysis post sweep function"][%Set] = "NotCalled_V1"
	wv[%$"Analysis post set function"][%Set]   = "NotCalled_V1"
	wv[%$"Analysis post DAQ function"][%Set]   = "NotCalled_V1"
	wv[%$"Analysis function (generic)"][%Set]  = "ValidFunc_V3"

	WAVE/T wv = root:MIES:WaveBuilder:SavedStimulusSetParameters:TTL:WPT_AnaFuncTTLNot_TTL_0

	wv[][%Set] = ""
	wv[%$"Analysis pre DAQ function"][%Set]    = "NotCalled_V1"
	wv[%$"Analysis pre sweep function"][%Set]  = "NotCalled_V1"
	wv[%$"Analysis mid sweep function"][%Set]  = "NotCalled_V1"
	wv[%$"Analysis post sweep function"][%Set] = "NotCalled_V1"
	wv[%$"Analysis post set function"][%Set]   = "NotCalled_V1"
	wv[%$"Analysis post DAQ function"][%Set]   = "NotCalled_V1"

	WAVE/T wv = root:MIES:WaveBuilder:SavedStimulusSetParameters:DA:WPT_AnaFuncMissing_DA_0

	wv[][%Set] = ""
	wv[%$"Analysis pre DAQ function"][%Set]    = "IDontExist"
	wv[%$"Analysis pre sweep function"][%Set]  = "IDontExist"
	wv[%$"Analysis mid sweep function"][%Set]  = "IDontExist"
	wv[%$"Analysis post sweep function"][%Set] = "IDontExist"
	wv[%$"Analysis post set function"][%Set]   = "IDontExist"
	wv[%$"Analysis post DAQ function"][%Set]   = "IDontExist"
End

Function RewriteAnalysisFunctions()
	LoadStimsets()
	ChangeAnalysisFunctions()
	SaveStimsets()
End

Function/WAVE TrackAnalysisFunctionCalls([numHeadstages])
	variable numHeadstages

	DFREF dfr = root:
	WAVE/Z/SDFR=dfr wv = anaFuncTracker

	if(WaveExists(wv))
		return wv
	else
		Make/N=(TOTAL_NUM_EVENTS, numHeadstages) dfr:anaFuncTracker/WAVE=wv
	endif

	return wv
End

Function CALLABLE_PROTO()
	FAIL()
End

/// @brief Acquire data with the given DAQSettings
static Function AcquireData(s, stimset, [numHeadstages, TTLStimset, postInitializeFunc, preAcquireFunc])
	STRUCT DAQSettings& s
	string stimset
	variable numHeadstages
	string TTLStimset
	FUNCREF CALLABLE_PROTO postInitializeFunc, preAcquireFunc

	variable i

	if(ParamIsDefault(numHeadstages))
		numHeadstages = 1
	endif

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()
	KillOrMoveToTrash(wv = anaFuncTracker)

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls(numHeadstages = numHeadstages)

	Initialize_IGNORE()

	if(!ParamIsDefault(postInitializeFunc))
		postInitializeFunc()
	endif

	string unlockedPanelTitle = DAP_CreateDAEphysPanel()

	PGC_SetAndActivateControl(unlockedPanelTitle, "popup_MoreSettings_DeviceType", val=5)
	PGC_SetAndActivateControl(unlockedPanelTitle, "button_SettingsPlus_LockDevice")

	REQUIRE(WindowExists(DEVICE))

	WAVE ampMCC = GetAmplifierMultiClamps()
	WAVE ampTel = GetAmplifierTelegraphServers()

	CHECK_EQUAL_VAR(DimSize(ampMCC, ROWS), 2)
	CHECK_EQUAL_VAR(DimSize(ampTel, ROWS), 2)

	PGC_SetAndActivateControl(DEVICE, "ADC", val=0)
	DoUpdate/W=$DEVICE

	for(i = 0; i < numHeadstages; i += 1)
		PGC_SetAndActivateControl(DEVICE, GetPanelControl(i, CHANNEL_TYPE_HEADSTAGE, CHANNEL_CONTROL_CHECK), val=1)
		PGC_SetAndActivateControl(DEVICE, GetPanelControl(i, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE), str = stimset)

		PGC_SetAndActivateControl(DEVICE, "Popup_Settings_HeadStage", val = i)
		PGC_SetAndActivateControl(DEVICE, "popup_Settings_Amplifier", val = i + 1)

		PGC_SetAndActivateControl(DEVICE, DAP_GetClampModeControl(I_CLAMP_MODE, i), val=1)
	endfor

	if(!ParamIsDefault(TTLStimset))
		PGC_SetAndActivateControl(DEVICE, GetPanelControl(0, CHANNEL_TYPE_TTL, CHANNEL_CONTROL_WAVE), str = TTLStimset)
		PGC_SetAndActivateControl(DEVICE, GetPanelControl(0, CHANNEL_TYPE_TTL, CHANNEL_CONTROL_CHECK), val=1)
	endif

	DoUpdate/W=$DEVICE

	PGC_SetAndActivateControl(DEVICE, "button_Hardware_AutoGainAndUnit")

	PGC_SetAndActivateControl(DEVICE, "check_Settings_MD", val = s.MD)
	PGC_SetAndActivateControl(DEVICE, "Check_DataAcq1_RepeatAcq", val = s.RA)
	PGC_SetAndActivateControl(DEVICE, "Check_DataAcq_Indexing", val = s.IDX)
	PGC_SetAndActivateControl(DEVICE, "Check_DataAcq1_IndexingLocked", val = s.LIDX)
	PGC_SetAndActivateControl(DEVICE, "Check_Settings_BackgrndDataAcq", val = s.BKG_DAQ)
	PGC_SetAndActivateControl(DEVICE, "SetVar_DataAcq_SetRepeats", val = s.RES)
	PGC_SetAndActivateControl(DEVICE, "Check_Settings_SkipAnalysFuncs", val = 0)

	DoUpdate/W=$DEVICE

	if(!ParamIsDefault(preAcquireFunc))
		preAcquireFunc()
	endif

	CtrlNamedBackGround DAQWatchdog, start, period=120, proc=WaitUntilDAQDone_IGNORE
	PGC_SetAndActivateControl(DEVICE, "DataAcquireButton")
End

// invalid analysis functions
static Function AFT_DAQ1()

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "DAQ_MD1_RA1_IDX0_LIDX0_BKG_1")

	try
		AcquireData(s, "AnaFuncInvalid1_DA*"); AbortOnRTE
		FAIL()
	catch
		PASS()
	endtry
End

static Function AFT_Test1()

	variable sweepNo
	string key

	CHECK_EQUAL_VAR(GetSetVariable(DEVICE, "SetVar_Sweep"), 0)

	sweepNo = AFH_GetLastSweepAcquired(DEVICE)
	CHECK_EQUAL_VAR(sweepNo, NaN)

	WAVE/T textualValues = GetLBTextualValues(DEVICE)
	key = StringFromList(PRE_DAQ_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSettingText(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK(!WaveExists(anaFuncs))

	key = StringFromList(PRE_SWEEP_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSettingText(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK(!WaveExists(anaFuncs))

	key = StringFromList(MID_SWEEP_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSettingText(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK(!WaveExists(anaFuncs))

	key = StringFromList(POST_SWEEP_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSettingText(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK(!WaveExists(anaFuncs))

	key = StringFromList(POST_SET_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSettingText(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK(!WaveExists(anaFuncs))

	key = StringFromList(POST_DAQ_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSettingText(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK(!WaveExists(anaFuncs))

	key = StringFromList(GENERIC_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSettingText(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK(!WaveExists(anaFuncs))
End

// can not call prototype analysis functions as they reside in the wrong file
static Function AFT_DAQ2()

	variable sweepNo

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "DAQ_MD1_RA1_IDX0_LIDX0_BKG_1")

	try
		AcquireData(s, "AnaFuncInvalid2_DA*"); AbortOnRTE
		FAIL()
	catch
		PASS()
	endtry
End

static Function AFT_Test2()

	variable sweepNo
	string key

	CHECK_EQUAL_VAR(GetSetVariable(DEVICE, "SetVar_Sweep"), 0)

	sweepNo = AFH_GetLastSweepAcquired(DEVICE)
	CHECK_EQUAL_VAR(sweepNo, NaN)

	WAVE/T textualValues = GetLBTextualValues(DEVICE)
	key = StringFromList(PRE_DAQ_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSettingText(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK(!WaveExists(anaFuncs))

	key = StringFromList(PRE_SWEEP_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSettingText(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK(!WaveExists(anaFuncs))

	key = StringFromList(MID_SWEEP_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSettingText(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK(!WaveExists(anaFuncs))

	key = StringFromList(POST_SWEEP_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSettingText(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK(!WaveExists(anaFuncs))

	key = StringFromList(POST_SET_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSettingText(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK(!WaveExists(anaFuncs))

	key = StringFromList(POST_DAQ_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSettingText(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK(!WaveExists(anaFuncs))

	key = StringFromList(GENERIC_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSettingText(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK(!WaveExists(anaFuncs))
End

// uses a valid V1 function and got calls for all events except post set
static Function AFT_DAQ3()

	variable sweepNo

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "DAQ_MD1_RA0_IDX0_LIDX0_BKG_1")

	AcquireData(s, "AnaFuncValid1_DA*")
End

static Function AFT_Test3()

	variable sweepNo
	string key

	CHECK_EQUAL_VAR(GetSetVariable(DEVICE, "SetVar_Sweep"), 1)

	sweepNo = AFH_GetLastSweepAcquired(DEVICE)
	CHECK_EQUAL_VAR(sweepNo, 0)

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()
	CHECK_EQUAL_VAR(anaFuncTracker[PRE_DAQ_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[PRE_SWEEP_EVENT], 1)
	CHECK(anaFuncTracker[MID_SWEEP_EVENT] >= 1)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_SWEEP_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_SET_EVENT], 0)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_DAQ_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[GENERIC_EVENT], 0)

	WAVE/T textualValues = GetLBTextualValues(DEVICE)
	key = StringFromList(PRE_DAQ_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSettingText(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(anaFuncs, {"ValidFunc_V1", "", "", "", "", "", "", "", ""})

	key = StringFromList(PRE_SWEEP_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSettingText(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(anaFuncs, {"ValidFunc_V1", "", "", "", "", "", "", "", ""})

	key = StringFromList(MID_SWEEP_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSettingText(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(anaFuncs, {"ValidFunc_V1", "", "", "", "", "", "", "", ""})

	key = StringFromList(POST_SWEEP_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSettingText(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(anaFuncs, {"ValidFunc_V1", "", "", "", "", "", "", "", ""})

	key = StringFromList(POST_SET_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSettingText(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(anaFuncs, {"ValidFunc_V1", "", "", "", "", "", "", "", ""})

	key = StringFromList(POST_DAQ_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSettingText(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(anaFuncs, {"ValidFunc_V1", "", "", "", "", "", "", "", ""})

	key = StringFromList(GENERIC_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSettingText(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK(!WaveExists(anaFuncs))
End

// uses a valid V1 function and got calls for all events including post set
static Function AFT_DAQ4()

	variable sweepNo

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "DAQ_MD1_RA1_IDX0_LIDX0_BKG_1")

	AcquireData(s, "AnaFuncValid1_DA*")
End

static Function AFT_Test4()

	variable sweepNo
	string key

	CHECK_EQUAL_VAR(GetSetVariable(DEVICE, "SetVar_Sweep"), 20)

	sweepNo = AFH_GetLastSweepAcquired(DEVICE)
	CHECK_EQUAL_VAR(sweepNo, 19)

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()
	CHECK_EQUAL_VAR(anaFuncTracker[PRE_DAQ_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[PRE_SWEEP_EVENT], 20)
	CHECK(anaFuncTracker[MID_SWEEP_EVENT] >= 1)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_SWEEP_EVENT], 20)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_SET_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_DAQ_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[GENERIC_EVENT], 0)

	WAVE/T textualValues = GetLBTextualValues(DEVICE)
	key = StringFromList(PRE_DAQ_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSettingText(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(anaFuncs, {"ValidFunc_V1", "", "", "", "", "", "", "", ""})

	key = StringFromList(PRE_SWEEP_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSettingText(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(anaFuncs, {"ValidFunc_V1", "", "", "", "", "", "", "", ""})

	key = StringFromList(MID_SWEEP_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSettingText(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(anaFuncs, {"ValidFunc_V1", "", "", "", "", "", "", "", ""})

	key = StringFromList(POST_SWEEP_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSettingText(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(anaFuncs, {"ValidFunc_V1", "", "", "", "", "", "", "", ""})

	key = StringFromList(POST_SET_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSettingText(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(anaFuncs, {"ValidFunc_V1", "", "", "", "", "", "", "", ""})

	key = StringFromList(POST_DAQ_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSettingText(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(anaFuncs, {"ValidFunc_V1", "", "", "", "", "", "", "", ""})

	key = StringFromList(GENERIC_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSettingText(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK(!WaveExists(anaFuncs))
End

// uses a valid V2 function and got calls for all events except post set
static Function AFT_DAQ5()

	variable sweepNo

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "DAQ_MD1_RA0_IDX0_LIDX0_BKG_1")

	AcquireData(s, "AnaFuncValid2_DA*")
End

static Function AFT_Test5()

	variable sweepNo
	string key

	CHECK_EQUAL_VAR(GetSetVariable(DEVICE, "SetVar_Sweep"), 1)

	sweepNo = AFH_GetLastSweepAcquired(DEVICE)
	CHECK_EQUAL_VAR(sweepNo, 0)

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()
	CHECK_EQUAL_VAR(anaFuncTracker[PRE_DAQ_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[PRE_SWEEP_EVENT], 1)
	CHECK(anaFuncTracker[MID_SWEEP_EVENT] >= 1)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_SWEEP_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_SET_EVENT], 0)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_DAQ_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[GENERIC_EVENT], 0)

	WAVE/T textualValues = GetLBTextualValues(DEVICE)
	key = StringFromList(PRE_DAQ_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSettingText(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(anaFuncs, {"ValidFunc_V2", "", "", "", "", "", "", "", ""})

	key = StringFromList(PRE_SWEEP_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSettingText(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(anaFuncs, {"ValidFunc_V2", "", "", "", "", "", "", "", ""})

	key = StringFromList(MID_SWEEP_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSettingText(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(anaFuncs, {"ValidFunc_V2", "", "", "", "", "", "", "", ""})

	key = StringFromList(POST_SWEEP_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSettingText(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(anaFuncs, {"ValidFunc_V2", "", "", "", "", "", "", "", ""})

	key = StringFromList(POST_SET_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSettingText(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(anaFuncs, {"ValidFunc_V2", "", "", "", "", "", "", "", ""})

	key = StringFromList(POST_DAQ_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSettingText(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(anaFuncs, {"ValidFunc_V2", "", "", "", "", "", "", "", ""})
End

// uses a valid V2 function and got calls for all events including post set
static Function AFT_DAQ6()

	variable sweepNo

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "DAQ_MD1_RA1_IDX0_LIDX0_BKG_1")

	AcquireData(s, "AnaFuncValid2_DA*")
End

static Function AFT_Test6()

	variable sweepNo
	string key

	CHECK_EQUAL_VAR(GetSetVariable(DEVICE, "SetVar_Sweep"), 20)

	sweepNo = AFH_GetLastSweepAcquired(DEVICE)
	CHECK_EQUAL_VAR(sweepNo, 19)

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()
	CHECK_EQUAL_VAR(anaFuncTracker[PRE_DAQ_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[PRE_SWEEP_EVENT], 20)
	CHECK(anaFuncTracker[MID_SWEEP_EVENT] >= 1)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_SWEEP_EVENT], 20)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_SET_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_DAQ_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[GENERIC_EVENT], 0)

	WAVE/T textualValues = GetLBTextualValues(DEVICE)
	key = StringFromList(PRE_DAQ_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSettingText(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(anaFuncs, {"ValidFunc_V2", "", "", "", "", "", "", "", ""})

	key = StringFromList(PRE_SWEEP_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSettingText(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(anaFuncs, {"ValidFunc_V2", "", "", "", "", "", "", "", ""})

	key = StringFromList(MID_SWEEP_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSettingText(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(anaFuncs, {"ValidFunc_V2", "", "", "", "", "", "", "", ""})

	key = StringFromList(POST_SWEEP_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSettingText(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(anaFuncs, {"ValidFunc_V2", "", "", "", "", "", "", "", ""})

	key = StringFromList(POST_SET_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSettingText(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(anaFuncs, {"ValidFunc_V2", "", "", "", "", "", "", "", ""})

	key = StringFromList(POST_DAQ_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSettingText(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(anaFuncs, {"ValidFunc_V2", "", "", "", "", "", "", "", ""})

	key = StringFromList(GENERIC_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSettingText(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK(!WaveExists(anaFuncs))
End

// uses a valid V3 function and got calls for all events including post set
static Function AFT_DAQ6a()

	variable sweepNo

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "DAQ_MD1_RA1_IDX0_LIDX0_BKG_1")

	AcquireData(s, "AnaFuncValid3_DA*")
End

static Function AFT_Test6a()

	variable sweepNo
	string key

	CHECK_EQUAL_VAR(GetSetVariable(DEVICE, "SetVar_Sweep"), 20)

	sweepNo = AFH_GetLastSweepAcquired(DEVICE)
	CHECK_EQUAL_VAR(sweepNo, 19)

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()
	CHECK_EQUAL_VAR(anaFuncTracker[PRE_DAQ_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[PRE_SWEEP_EVENT], 20)
	CHECK(anaFuncTracker[MID_SWEEP_EVENT] >= 1)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_SWEEP_EVENT], 20)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_SET_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_DAQ_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[GENERIC_EVENT], 0)

	WAVE/T textualValues = GetLBTextualValues(DEVICE)
	key = StringFromList(PRE_DAQ_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSettingText(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK(!WaveExists(anaFuncs))

	key = StringFromList(PRE_SWEEP_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSettingText(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK(!WaveExists(anaFuncs))

	key = StringFromList(MID_SWEEP_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSettingText(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK(!WaveExists(anaFuncs))

	key = StringFromList(POST_SWEEP_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSettingText(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK(!WaveExists(anaFuncs))

	key = StringFromList(POST_SET_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSettingText(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK(!WaveExists(anaFuncs))

	key = StringFromList(POST_DAQ_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSettingText(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK(!WaveExists(anaFuncs))

	key = StringFromList(GENERIC_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSettingText(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(anaFuncs, {"ValidFunc_V3", "", "", "", "", "", "", "", ""})
End

// uses a valid V3 generic function and then ignores other set analysis functions
// The wavebuilder does not store other analysis functions if the generic name is set.
// That is the reason why they are in the labnotebook but not called.
static Function AFT_DAQ6b()

	variable sweepNo

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "DAQ_MD1_RA1_IDX0_LIDX0_BKG_1")

	AcquireData(s, "AnaFuncGeneric_DA*")
End

static Function AFT_Test6b()

	variable sweepNo
	string key

	CHECK_EQUAL_VAR(GetSetVariable(DEVICE, "SetVar_Sweep"), 20)

	sweepNo = AFH_GetLastSweepAcquired(DEVICE)
	CHECK_EQUAL_VAR(sweepNo, 19)

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()
	CHECK_EQUAL_VAR(anaFuncTracker[PRE_DAQ_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[PRE_SWEEP_EVENT], 20)
	CHECK(anaFuncTracker[MID_SWEEP_EVENT] >= 1)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_SWEEP_EVENT], 20)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_SET_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_DAQ_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[GENERIC_EVENT], 0)

	WAVE/T textualValues = GetLBTextualValues(DEVICE)
	key = StringFromList(PRE_DAQ_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSettingText(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(anaFuncs, {"NotCalled_V1", "", "", "", "", "", "", "", ""})

	key = StringFromList(PRE_SWEEP_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSettingText(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(anaFuncs, {"NotCalled_V1", "", "", "", "", "", "", "", ""})

	key = StringFromList(MID_SWEEP_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSettingText(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(anaFuncs, {"NotCalled_V1", "", "", "", "", "", "", "", ""})

	key = StringFromList(POST_SWEEP_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSettingText(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(anaFuncs, {"NotCalled_V1", "", "", "", "", "", "", "", ""})

	key = StringFromList(POST_SET_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSettingText(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(anaFuncs, {"NotCalled_V1", "", "", "", "", "", "", "", ""})

	key = StringFromList(POST_DAQ_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSettingText(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(anaFuncs, {"NotCalled_V1", "", "", "", "", "", "", "", ""})

	key = StringFromList(GENERIC_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSettingText(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(anaFuncs, {"ValidFunc_V3", "", "", "", "", "", "", "", ""})
End


// ana func called for each headstage
static Function AFT_DAQ7()

	variable sweepNo

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "DAQ_MD1_RA1_IDX0_LIDX0_BKG_1")

	AcquireData(s, "AnaFuncValidMult_DA*", numHeadstages = 2)
End

static Function AFT_Test7()

	variable sweepNo, i, numHeadstages
	string key

	CHECK_EQUAL_VAR(GetSetVariable(DEVICE, "SetVar_Sweep"), 20)

	sweepNo = AFH_GetLastSweepAcquired(DEVICE)
	CHECK_EQUAL_VAR(sweepNo, 19)

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()

	CHECK_EQUAL_VAR(anaFuncTracker[PRE_DAQ_EVENT][0], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[PRE_SWEEP_EVENT][0], 20)
	CHECK(anaFuncTracker[MID_SWEEP_EVENT][0] >= 1)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_SWEEP_EVENT][0], 20)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_SET_EVENT][0], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_DAQ_EVENT][0], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[GENERIC_EVENT][0], 0)

	CHECK_EQUAL_VAR(anaFuncTracker[PRE_DAQ_EVENT][1], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[PRE_SWEEP_EVENT][1], 20)
	CHECK(anaFuncTracker[MID_SWEEP_EVENT][1] >= 1)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_SWEEP_EVENT][1], 20)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_SET_EVENT][1], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_DAQ_EVENT][1], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[GENERIC_EVENT][1], 0)

	WAVE/T textualValues = GetLBTextualValues(DEVICE)
	key = StringFromList(PRE_DAQ_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSettingText(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(anaFuncs, {"ValidMultHS_V1", "ValidMultHS_V1", "", "", "", "", "", "", ""})

	key = StringFromList(PRE_SWEEP_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSettingText(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(anaFuncs, {"ValidMultHS_V1", "ValidMultHS_V1", "", "", "", "", "", "", ""})

	key = StringFromList(MID_SWEEP_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSettingText(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(anaFuncs, {"ValidMultHS_V1", "ValidMultHS_V1", "", "", "", "", "", "", ""})

	key = StringFromList(POST_SWEEP_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSettingText(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(anaFuncs, {"ValidMultHS_V1", "ValidMultHS_V1", "", "", "", "", "", "", ""})

	key = StringFromList(POST_SET_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSettingText(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(anaFuncs, {"ValidMultHS_V1", "ValidMultHS_V1", "", "", "", "", "", "", ""})

	key = StringFromList(POST_DAQ_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSettingText(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(anaFuncs, {"ValidMultHS_V1", "ValidMultHS_V1", "", "", "", "", "", "", ""})

	key = StringFromList(GENERIC_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSettingText(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK(!WaveExists(anaFuncs))
End

// not called if attached to TTL stimsets
static Function AFT_DAQ8()

	variable sweepNo

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "DAQ_MD1_RA1_IDX0_LIDX0_BKG_1")

	AcquireData(s, "StimulusSetA_DA*", TTLstimset = "AnaFuncTTLNot_TTL_*")
End

static Function AFT_Test8()

	variable sweepNo, i, numHeadstages
	string key

	CHECK_EQUAL_VAR(GetSetVariable(DEVICE, "SetVar_Sweep"), 3)

	sweepNo = AFH_GetLastSweepAcquired(DEVICE)
	CHECK_EQUAL_VAR(sweepNo, 2)

	WAVE/T textualValues = GetLBTextualValues(DEVICE)
	key = StringFromList(PRE_DAQ_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSettingText(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK(!WaveExists(anaFuncs))

	key = StringFromList(PRE_SWEEP_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSettingText(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK(!WaveExists(anaFuncs))

	key = StringFromList(MID_SWEEP_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSettingText(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK(!WaveExists(anaFuncs))

	key = StringFromList(POST_SWEEP_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSettingText(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK(!WaveExists(anaFuncs))

	key = StringFromList(POST_SET_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSettingText(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK(!WaveExists(anaFuncs))

	key = StringFromList(POST_DAQ_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSettingText(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK(!WaveExists(anaFuncs))

	key = StringFromList(GENERIC_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSettingText(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK(!WaveExists(anaFuncs))
End

// does not call some ana funcs if aborted
static Function AFT_DAQ9()

	variable sweepNo

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "DAQ_MD1_RA1_IDX0_LIDX0_BKG_1")

	AcquireData(s, "AnaFuncValid2_DA*")
	CtrlNamedBackGround Abort_ITI_PressAcq, start, period=30, proc=StopAcq_IGNORE
End

static Function AFT_Test9()

	variable sweepNo
	string key

	CHECK_EQUAL_VAR(GetSetVariable(DEVICE, "SetVar_Sweep"), 1)

	sweepNo = AFH_GetLastSweepAcquired(DEVICE)
	CHECK_EQUAL_VAR(sweepNo, 0)

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()

	CHECK_EQUAL_VAR(anaFuncTracker[PRE_DAQ_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[PRE_SWEEP_EVENT], 1)
	CHECK(anaFuncTracker[MID_SWEEP_EVENT] >= 1)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_SWEEP_EVENT], 0)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_SET_EVENT], 0)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_DAQ_EVENT], 0)
	CHECK_EQUAL_VAR(anaFuncTracker[GENERIC_EVENT], 0)

	WAVE/T textualValues = GetLBTextualValues(DEVICE)
	key = StringFromList(PRE_DAQ_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSettingText(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(anaFuncs, {"ValidFunc_V2", "", "", "", "", "", "", "", ""})

	key = StringFromList(PRE_SWEEP_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSettingText(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(anaFuncs, {"ValidFunc_V2", "", "", "", "", "", "", "", ""})

	key = StringFromList(MID_SWEEP_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSettingText(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(anaFuncs, {"ValidFunc_V2", "", "", "", "", "", "", "", ""})

	key = StringFromList(POST_SWEEP_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSettingText(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(anaFuncs, {"ValidFunc_V2", "", "", "", "", "", "", "", ""})

	key = StringFromList(POST_SET_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSettingText(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(anaFuncs, {"ValidFunc_V2", "", "", "", "", "", "", "", ""})

	key = StringFromList(POST_DAQ_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSettingText(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(anaFuncs, {"ValidFunc_V2", "", "", "", "", "", "", "", ""})

	key = StringFromList(GENERIC_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSettingText(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK(!WaveExists(anaFuncs))
End

// DAQ works if the analysis function can not be found
static Function AFT_DAQ10()

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "DAQ_MD1_RA0_IDX0_LIDX0_BKG_1")

	AcquireData(s, "AnaFuncMissing_DA*")
End

static Function AFT_Test10()

	variable sweepNo
	string key

	CHECK_EQUAL_VAR(GetSetVariable(DEVICE, "SetVar_Sweep"), 1)

	sweepNo = AFH_GetLastSweepAcquired(DEVICE)
	CHECK_EQUAL_VAR(sweepNo, 0)

	WAVE/T textualValues = GetLBTextualValues(DEVICE)
	key = StringFromList(PRE_DAQ_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSettingText(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK(!WaveExists(anaFuncs))

	key = StringFromList(PRE_SWEEP_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSettingText(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK(!WaveExists(anaFuncs))

	key = StringFromList(MID_SWEEP_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSettingText(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK(!WaveExists(anaFuncs))

	key = StringFromList(POST_SWEEP_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSettingText(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK(!WaveExists(anaFuncs))

	key = StringFromList(POST_SET_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSettingText(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK(!WaveExists(anaFuncs))

	key = StringFromList(POST_DAQ_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSettingText(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK(!WaveExists(anaFuncs))

	key = StringFromList(GENERIC_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSettingText(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK(!WaveExists(anaFuncs))
End

// calls correct analysis functions
static Function AFT_DAQ11()

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "DAQ_MD1_RA1_IDX0_LIDX0_BKG_1")

	AcquireData(s, "AnaFuncDiff_DA*")
End

static Function AFT_Test11()

	variable sweepNo
	string key

	CHECK_EQUAL_VAR(GetSetVariable(DEVICE, "SetVar_Sweep"), 20)

	sweepNo = AFH_GetLastSweepAcquired(DEVICE)
	CHECK_EQUAL_VAR(sweepNo, 19)

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()

	CHECK_EQUAL_VAR(anaFuncTracker[PRE_DAQ_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[PRE_SWEEP_EVENT], 20)
	CHECK(anaFuncTracker[MID_SWEEP_EVENT] >= 1)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_SWEEP_EVENT], 20)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_SET_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_DAQ_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[GENERIC_EVENT], 0)

	WAVE/T textualValues = GetLBTextualValues(DEVICE)
	key = StringFromList(PRE_DAQ_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSettingText(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(anaFuncs, {"preDAQ", "", "", "", "", "", "", "", ""})

	key = StringFromList(PRE_SWEEP_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSettingText(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(anaFuncs, {"preSweep", "", "", "", "", "", "", "", ""})

	key = StringFromList(MID_SWEEP_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSettingText(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(anaFuncs, {"midSweep", "", "", "", "", "", "", "", ""})

	key = StringFromList(POST_SWEEP_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSettingText(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(anaFuncs, {"postSweep", "", "", "", "", "", "", "", ""})

	key = StringFromList(POST_SET_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSettingText(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(anaFuncs, {"postSet", "", "", "", "", "", "", "", ""})

	key = StringFromList(POST_DAQ_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSettingText(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(anaFuncs, {"postDAQ", "", "", "", "", "", "", "", ""})

	key = StringFromList(GENERIC_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSettingText(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK(!WaveExists(anaFuncs))
End

// abort early results in other analysis functions not being called
// preDAQ
static Function AFT_DAQ12()

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "DAQ_MD1_RA0_IDX0_LIDX0_BKG_1")

	try
		AcquireData(s, "AnaFuncAbortPre_DA*", numHeadstages = 2); AbortOnRTE
		FAIL()
	catch
		PASS()
	endtry
End

static Function AFT_Test12()

	variable sweepNo
	string key

	CHECK_EQUAL_VAR(GetSetVariable(DEVICE, "SetVar_Sweep"), 0)

	sweepNo = AFH_GetLastSweepAcquired(DEVICE)
	CHECK_EQUAL_VAR(sweepNo, NaN)

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()

	CHECK_EQUAL_VAR(anaFuncTracker[PRE_DAQ_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[PRE_SWEEP_EVENT], 0)
	CHECK_EQUAL_VAR(anaFuncTracker[MID_SWEEP_EVENT], 0)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_SWEEP_EVENT], 0)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_SET_EVENT], 0)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_DAQ_EVENT], 0)
	CHECK_EQUAL_VAR(anaFuncTracker[GENERIC_EVENT], 0)

	WAVE/T textualValues = GetLBTextualValues(DEVICE)

	key = StringFromList(PRE_DAQ_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSettingText(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK(!WaveExists(anaFuncs))

	key = StringFromList(PRE_SWEEP_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSettingText(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK(!WaveExists(anaFuncs))

	key = StringFromList(MID_SWEEP_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSettingText(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK(!WaveExists(anaFuncs))

	key = StringFromList(POST_SWEEP_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSettingText(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK(!WaveExists(anaFuncs))

	key = StringFromList(POST_SET_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSettingText(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK(!WaveExists(anaFuncs))

	key = StringFromList(POST_DAQ_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSettingText(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK(!WaveExists(anaFuncs))

	key = StringFromList(GENERIC_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSettingText(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK(!WaveExists(anaFuncs))
End

// abort early results in other analysis functions not being called
// midSweep
static Function AFT_DAQ13()

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "DAQ_MD1_RA0_IDX0_LIDX0_BKG_1")

	AcquireData(s, "AnaFuncStopMid_DA*", numHeadstages = 2)
End

static Function AFT_Test13()

	variable sweepNo
	string key

	CHECK_EQUAL_VAR(GetSetVariable(DEVICE, "SetVar_Sweep"), 1)

	sweepNo = AFH_GetLastSweepAcquired(DEVICE)
	CHECK_EQUAL_VAR(sweepNo, 0)

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()

	CHECK_EQUAL_VAR(anaFuncTracker[PRE_DAQ_EVENT], 0)
	CHECK_EQUAL_VAR(anaFuncTracker[PRE_SWEEP_EVENT], 0)
	CHECK_EQUAL_VAR(anaFuncTracker[MID_SWEEP_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_SWEEP_EVENT], 0)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_SET_EVENT], 0)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_DAQ_EVENT], 0)
	CHECK_EQUAL_VAR(anaFuncTracker[GENERIC_EVENT], 0)

	WAVE/T textualValues = GetLBTextualValues(DEVICE)

	key = StringFromList(PRE_DAQ_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSettingText(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK(!WaveExists(anaFuncs))

	key = StringFromList(PRE_SWEEP_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSettingText(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK(!WaveExists(anaFuncs))

	key = StringFromList(MID_SWEEP_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSettingText(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(anaFuncs, {"StopMidSweep", "StopMidSweep", "", "", "", "", "", "", ""})

	key = StringFromList(POST_SWEEP_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSettingText(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK(!WaveExists(anaFuncs))

	key = StringFromList(POST_SET_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSettingText(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK(!WaveExists(anaFuncs))

	key = StringFromList(POST_DAQ_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSettingText(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK(!WaveExists(anaFuncs))

	key = StringFromList(GENERIC_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSettingText(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK(!WaveExists(anaFuncs))
End

static Function SetParams_IGNORE()

	string stimSet = "AnaFuncParams1_DA_0"
	WBP_AddAnalysisParameter(stimSet, "MyVar", str = "abcd")
	WBP_AddAnalysisParameter(stimSet, "MyStr", str = "abcd")
	WBP_AddAnalysisParameter(stimSet, "MyWave", wv = {1, 2, 3})
	Make/FREE/T textData = {"a", "b", "c"}
	WBP_AddAnalysisParameter(stimSet, "MyTextWave", wv = textData)
End

// test parameter handling
static Function AFT_DAQ14()

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "DAQ_MD1_RA0_IDX0_LIDX0_BKG_1")

	FUNCREF CALLABLE_PROTO f = SetParams_IGNORE
	AcquireData(s, "AnaFuncParams1_DA_0", postInitializeFunc = f)
End

static Function AFT_Test14()

	variable sweepNo
	string key

	CHECK_EQUAL_VAR(GetSetVariable(DEVICE, "SetVar_Sweep"), 1)

	sweepNo = AFH_GetLastSweepAcquired(DEVICE)
	CHECK_EQUAL_VAR(sweepNo, 0)

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()

	CHECK_EQUAL_VAR(anaFuncTracker[PRE_DAQ_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[PRE_SWEEP_EVENT], 1)
	CHECK(anaFuncTracker[MID_SWEEP_EVENT] >= 1)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_SWEEP_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_SET_EVENT], 0)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_DAQ_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[GENERIC_EVENT], 0)

	WAVE/T textualValues = GetLBTextualValues(DEVICE)

	key = StringFromList(PRE_DAQ_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSettingText(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK(!WaveExists(anaFuncs))

	key = StringFromList(PRE_SWEEP_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSettingText(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK(!WaveExists(anaFuncs))

	key = StringFromList(MID_SWEEP_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSettingText(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK(!WaveExists(anaFuncs))

	key = StringFromList(POST_SWEEP_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSettingText(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK(!WaveExists(anaFuncs))

	key = StringFromList(POST_SET_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSettingText(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK(!WaveExists(anaFuncs))

	key = StringFromList(POST_DAQ_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSettingText(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK(!WaveExists(anaFuncs))

	key = StringFromList(GENERIC_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSettingText(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(anaFuncs, {"Params1_V3", "", "", "", "", "", "", "", ""})

	key = ANALYSIS_FUNCTION_PARAMS_LBN
	WAVE/T/Z anaFuncParams = GetLastSettingText(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncParams, TEXT_WAVE)
End
