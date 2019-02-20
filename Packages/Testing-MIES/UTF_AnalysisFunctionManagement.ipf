#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma ModuleName=AnalysisFunctionTesting

static Function ChangeAnalysisFunctions()

	WAVE/T wv = root:MIES:WaveBuilder:SavedStimulusSetParameters:DA:WPT_AnaFuncAbortPre_DA_0
	UpgradeWaveTextParam(wv)

	wv[][%Set] = ""
	wv[%$"Analysis pre DAQ function"][%Set]    = "AbortPreDAQ"

	WAVE/T wv = root:MIES:WaveBuilder:SavedStimulusSetParameters:DA:WPT_AnaFuncDiff_DA_0
	UpgradeWaveTextParam(wv)

	wv[][%Set] = ""
	wv[%$"Analysis pre DAQ function"][%Set]    = "preDAQ"
	wv[%$"Analysis pre set function"][%Set]    = "preSet"
	wv[%$"Analysis pre sweep function"][%Set]  = "preSweep"
	wv[%$"Analysis mid sweep function"][%Set]  = "midSweep"
	wv[%$"Analysis post sweep function"][%Set] = "postSweep"
	wv[%$"Analysis post set function"][%Set]   = "postSet"
	wv[%$"Analysis post DAQ function"][%Set]   = "postDAQ"

	WAVE/T wv = root:MIES:WaveBuilder:SavedStimulusSetParameters:DA:WPT_AnaFuncInvalid1_DA_0
	UpgradeWaveTextParam(wv)

	wv[][%Set] = ""
	wv[%$"Analysis pre DAQ function"][%Set]    = "InvalidSignatureAndReturnType"
	wv[%$"Analysis pre set function"][%Set]    = "InvalidSignature"
	wv[%$"Analysis pre sweep function"][%Set]  = "InvalidSignature"
	wv[%$"Analysis mid sweep function"][%Set]  = "InvalidReturnTypeAndValidSig_V1"
	wv[%$"Analysis post sweep function"][%Set] = "InvalidSignatureAndReturnType"
	wv[%$"Analysis post set function"][%Set]   = "InvalidSignature"
	wv[%$"Analysis post DAQ function"][%Set]   = "InvalidSignatureAndReturnType"

	WAVE/T wv = root:MIES:WaveBuilder:SavedStimulusSetParameters:DA:WPT_AnaFuncInvalid2_DA_0
	UpgradeWaveTextParam(wv)

	wv[][%Set] = ""
	wv[%$"Analysis pre DAQ function"][%Set]    = "InvalidSignatureAndReturnType"
	wv[%$"Analysis pre set function"][%Set]    = "InvalidSignature"
	wv[%$"Analysis pre sweep function"][%Set]  = "InvalidSignature"
	wv[%$"Analysis mid sweep function"][%Set]  = "InvalidReturnTypeAndValidSig_V2"
	wv[%$"Analysis post sweep function"][%Set] = "InvalidSignatureAndReturnType"
	wv[%$"Analysis post set function"][%Set]   = "InvalidSignature"
	wv[%$"Analysis post DAQ function"][%Set]   = "InvalidSignatureAndReturnType"

	WAVE/T wv = root:MIES:WaveBuilder:SavedStimulusSetParameters:DA:WPT_AnaFuncStopMid_DA_0
	UpgradeWaveTextParam(wv)

	wv[][%Set] = ""
	wv[%$"Analysis mid sweep function"][%Set]  = "StopMidSweep"

	WAVE/T wv = root:MIES:WaveBuilder:SavedStimulusSetParameters:DA:WPT_AnaFuncValidMult_DA_0
	UpgradeWaveTextParam(wv)

	wv[][%Set] = ""
	wv[%$"Analysis pre DAQ function"][%Set]    = "ValidMultHS_V1"
	wv[%$"Analysis pre set function"][%Set]    = "ValidMultHS_V1"
	wv[%$"Analysis pre sweep function"][%Set]  = "ValidMultHS_V1"
	wv[%$"Analysis mid sweep function"][%Set]  = "ValidMultHS_V1"
	wv[%$"Analysis post sweep function"][%Set] = "ValidMultHS_V1"
	wv[%$"Analysis post set function"][%Set]   = "ValidMultHS_V1"
	wv[%$"Analysis post DAQ function"][%Set]   = "ValidMultHS_V1"

	WAVE/T wv = root:MIES:WaveBuilder:SavedStimulusSetParameters:DA:WPT_AnaFuncValid1_DA_0
	UpgradeWaveTextParam(wv)

	wv[][%Set] = ""
	wv[%$"Analysis pre DAQ function"][%Set]    = "ValidFunc_V1"
	wv[%$"Analysis pre set function"][%Set]    = "ValidFunc_V1"
	wv[%$"Analysis pre sweep function"][%Set]  = "ValidFunc_V1"
	wv[%$"Analysis mid sweep function"][%Set]  = "ValidFunc_V1"
	wv[%$"Analysis post sweep function"][%Set] = "ValidFunc_V1"
	wv[%$"Analysis post set function"][%Set]   = "ValidFunc_V1"
	wv[%$"Analysis post DAQ function"][%Set]   = "ValidFunc_V1"

	WAVE/T wv = root:MIES:WaveBuilder:SavedStimulusSetParameters:DA:WPT_AnaFuncValid2_DA_0
	UpgradeWaveTextParam(wv)

	wv[][%Set] = ""
	wv[%$"Analysis pre DAQ function"][%Set]    = "ValidFunc_V2"
	wv[%$"Analysis pre set function"][%Set]    = "ValidFunc_V2"
	wv[%$"Analysis pre sweep function"][%Set]  = "ValidFunc_V2"
	wv[%$"Analysis mid sweep function"][%Set]  = "ValidFunc_V2"
	wv[%$"Analysis post sweep function"][%Set] = "ValidFunc_V2"
	wv[%$"Analysis post set function"][%Set]   = "ValidFunc_V2"
	wv[%$"Analysis post DAQ function"][%Set]   = "ValidFunc_V2"

	WAVE/T wv = root:MIES:WaveBuilder:SavedStimulusSetParameters:DA:WPT_AnaFuncValid3_DA_0
	UpgradeWaveTextParam(wv)

	wv[][%Set] = ""
	wv[%$"Analysis function (generic)"][%Set]  = "ValidFunc_V3"

	WAVE/T wv = root:MIES:WaveBuilder:SavedStimulusSetParameters:DA:WPT_AnaFuncParams1_DA_0
	UpgradeWaveTextParam(wv)

	wv[][%Set] = ""
	wv[%$"Analysis function (generic)"][%Set]  = "Params1_V3"

	WAVE/T wv = root:MIES:WaveBuilder:SavedStimulusSetParameters:DA:WPT_AnaFuncParams2_DA_0
	UpgradeWaveTextParam(wv)

	wv[][%Set] = ""
	wv[%$"Analysis function (generic)"][%Set]  = "Params2_V3"

	WAVE/T wv = root:MIES:WaveBuilder:SavedStimulusSetParameters:DA:WPT_AnaFuncParams3_DA_0
	UpgradeWaveTextParam(wv)

	wv[][%Set] = ""
	wv[%$"Analysis function (generic)"][%Set]  = "Params3_V3"

	WAVE/T wv = root:MIES:WaveBuilder:SavedStimulusSetParameters:DA:WPT_AnaFuncParams4_DA_0
	UpgradeWaveTextParam(wv)

	wv[][%Set] = ""
	wv[%$"Analysis function (generic)"][%Set]  = "Params4_V3"

	WAVE/T wv = root:MIES:WaveBuilder:SavedStimulusSetParameters:DA:WPT_AnaFuncGeneric_DA_0
	UpgradeWaveTextParam(wv)

	wv[][%Set] = ""
	wv[%$"Analysis pre DAQ function"][%Set]    = "NotCalled_V1"
	wv[%$"Analysis pre set function"][%Set]    = "NotCalled_V1"
	wv[%$"Analysis pre sweep function"][%Set]  = "NotCalled_V1"
	wv[%$"Analysis mid sweep function"][%Set]  = "NotCalled_V1"
	wv[%$"Analysis post sweep function"][%Set] = "NotCalled_V1"
	wv[%$"Analysis post set function"][%Set]   = "NotCalled_V1"
	wv[%$"Analysis post DAQ function"][%Set]   = "NotCalled_V1"
	wv[%$"Analysis function (generic)"][%Set]  = "ValidFunc_V3"

	WAVE/T wv = root:MIES:WaveBuilder:SavedStimulusSetParameters:TTL:WPT_AnaFuncTTLNot_TTL_0
	UpgradeWaveTextParam(wv)

	wv[][%Set] = ""
	wv[%$"Analysis pre DAQ function"][%Set]    = "NotCalled_V1"
	wv[%$"Analysis pre set function"][%Set]    = "NotCalled_V1"
	wv[%$"Analysis pre sweep function"][%Set]  = "NotCalled_V1"
	wv[%$"Analysis mid sweep function"][%Set]  = "NotCalled_V1"
	wv[%$"Analysis post sweep function"][%Set] = "NotCalled_V1"
	wv[%$"Analysis post set function"][%Set]   = "NotCalled_V1"
	wv[%$"Analysis post DAQ function"][%Set]   = "NotCalled_V1"

	WAVE/T wv = root:MIES:WaveBuilder:SavedStimulusSetParameters:DA:WPT_AnaFuncMissing_DA_0
	UpgradeWaveTextParam(wv)

	wv[][%Set] = ""
	wv[%$"Analysis pre DAQ function"][%Set]    = "IDontExist"
	wv[%$"Analysis pre set function"][%Set]    = "IDontExist"
	wv[%$"Analysis pre sweep function"][%Set]  = "IDontExist"
	wv[%$"Analysis mid sweep function"][%Set]  = "IDontExist"
	wv[%$"Analysis post sweep function"][%Set] = "IDontExist"
	wv[%$"Analysis post set function"][%Set]   = "IDontExist"
	wv[%$"Analysis post DAQ function"][%Set]   = "IDontExist"

	WAVE/T wv = root:MIES:WaveBuilder:SavedStimulusSetParameters:DA:WPT_AnaFuncVeryShort_DA_0
	UpgradeWaveTextParam(wv)

	wv[][%Set] = ""
	wv[%$"Analysis function (generic)"][%Set]  = "ValidFunc_V3"

	WAVE/T wv = root:MIES:WaveBuilder:SavedStimulusSetParameters:DA:WPT_AnaFuncPreDAQHar_DA_0
	UpgradeWaveTextParam(wv)

	wv[][%Set] = ""
	wv[%$"Analysis pre DAQ function"][%Set]    = "preDAQHardAbort"
	wv[%$"Analysis pre set function"][%Set]    = "preDAQHardAbort"
	wv[%$"Analysis pre sweep function"][%Set]  = "preDAQHardAbort"
	wv[%$"Analysis mid sweep function"][%Set]  = "preDAQHardAbort"
	wv[%$"Analysis post sweep function"][%Set] = "preDAQHardAbort"
	wv[%$"Analysis post set function"][%Set]   = "preDAQHardAbort"
	wv[%$"Analysis post DAQ function"][%Set]   = "preDAQHardAbort"

	WAVE/T wv = root:MIES:WaveBuilder:SavedStimulusSetParameters:DA:WPT_AnaFuncPreSetHar_DA_0
	UpgradeWaveTextParam(wv)

	wv[][%Set] = ""
	wv[%$"Analysis function (generic)"][%Set]    = "AbortPreSet"

	WAVE/T wv = root:MIES:WaveBuilder:SavedStimulusSetParameters:DA:WPT_AnaFuncOrder_DA_0
	UpgradeWaveTextParam(wv)

	wv[][%Set] = ""
	wv[%$"Analysis function (generic)"][%Set]    = "TotalOrdering"
End

Function RewriteAnalysisFunctions()
	LoadStimsets()
	ChangeAnalysisFunctions()
	SaveStimsets()
End

Function/WAVE TrackAnalysisFunctionCalls([numHeadstages])
	variable numHeadstages

	variable i

	DFREF dfr = root:
	WAVE/Z/SDFR=dfr wv = anaFuncTracker

	if(WaveExists(wv))
		return wv
	else
		Make/N=(TOTAL_NUM_EVENTS, numHeadstages) dfr:anaFuncTracker/WAVE=wv
	endif

	for(i = 0; i < TOTAL_NUM_EVENTS; i += 1)
		SetDimLabel ROWS, i, $StringFromList(i, EVENT_NAME_LIST), wv
	endfor

	return wv
End

Function/WAVE TrackAnalysisFunctionOrder([numHeadstages])
	variable numHeadstages

	variable i

	DFREF dfr = root:
	WAVE/D/Z/SDFR=dfr wv = anaFuncOrder

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

	WAVE anaFuncOrder = TrackAnalysisFunctionOrder()
	KillOrMoveToTrash(wv = anaFuncOrder)

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls(numHeadstages = numHeadstages)

	Initialize_IGNORE()

	if(!ParamIsDefault(postInitializeFunc))
		postInitializeFunc()
	endif

	string unlockedPanelTitle = DAP_CreateDAEphysPanel()

	ChooseCorrectDevice(unlockedPanelTitle, DEVICE)
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
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, NULL_WAVE)

	key = StringFromList(PRE_SET_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, NULL_WAVE)

	key = StringFromList(PRE_SWEEP_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, NULL_WAVE)

	key = StringFromList(MID_SWEEP_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, NULL_WAVE)

	key = StringFromList(POST_SWEEP_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, NULL_WAVE)

	key = StringFromList(POST_SET_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, NULL_WAVE)

	key = StringFromList(POST_DAQ_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, NULL_WAVE)

	key = StringFromList(GENERIC_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, NULL_WAVE)
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
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, NULL_WAVE)

	key = StringFromList(PRE_SET_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, NULL_WAVE)

	key = StringFromList(PRE_SWEEP_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, NULL_WAVE)

	key = StringFromList(MID_SWEEP_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, NULL_WAVE)

	key = StringFromList(POST_SWEEP_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, NULL_WAVE)

	key = StringFromList(POST_SET_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, NULL_WAVE)

	key = StringFromList(POST_DAQ_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, NULL_WAVE)

	key = StringFromList(GENERIC_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, NULL_WAVE)
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
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(anaFuncs, {"ValidFunc_V1", "", "", "", "", "", "", "", ""})

	key = StringFromList(PRE_SET_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(anaFuncs, {"ValidFunc_V1", "", "", "", "", "", "", "", ""})

	key = StringFromList(PRE_SWEEP_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(anaFuncs, {"ValidFunc_V1", "", "", "", "", "", "", "", ""})

	key = StringFromList(MID_SWEEP_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(anaFuncs, {"ValidFunc_V1", "", "", "", "", "", "", "", ""})

	key = StringFromList(POST_SWEEP_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(anaFuncs, {"ValidFunc_V1", "", "", "", "", "", "", "", ""})

	key = StringFromList(POST_SET_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(anaFuncs, {"ValidFunc_V1", "", "", "", "", "", "", "", ""})

	key = StringFromList(POST_DAQ_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(anaFuncs, {"ValidFunc_V1", "", "", "", "", "", "", "", ""})

	key = StringFromList(GENERIC_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, NULL_WAVE)
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
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(anaFuncs, {"ValidFunc_V1", "", "", "", "", "", "", "", ""})

	key = StringFromList(PRE_SET_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(anaFuncs, {"ValidFunc_V1", "", "", "", "", "", "", "", ""})

	key = StringFromList(PRE_SWEEP_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(anaFuncs, {"ValidFunc_V1", "", "", "", "", "", "", "", ""})

	key = StringFromList(MID_SWEEP_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(anaFuncs, {"ValidFunc_V1", "", "", "", "", "", "", "", ""})

	key = StringFromList(POST_SWEEP_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(anaFuncs, {"ValidFunc_V1", "", "", "", "", "", "", "", ""})

	key = StringFromList(POST_SET_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(anaFuncs, {"ValidFunc_V1", "", "", "", "", "", "", "", ""})

	key = StringFromList(POST_DAQ_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(anaFuncs, {"ValidFunc_V1", "", "", "", "", "", "", "", ""})

	key = StringFromList(GENERIC_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, NULL_WAVE)
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
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(anaFuncs, {"ValidFunc_V2", "", "", "", "", "", "", "", ""})

	key = StringFromList(PRE_SWEEP_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(anaFuncs, {"ValidFunc_V2", "", "", "", "", "", "", "", ""})

	key = StringFromList(MID_SWEEP_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(anaFuncs, {"ValidFunc_V2", "", "", "", "", "", "", "", ""})

	key = StringFromList(POST_SWEEP_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(anaFuncs, {"ValidFunc_V2", "", "", "", "", "", "", "", ""})

	key = StringFromList(POST_SET_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(anaFuncs, {"ValidFunc_V2", "", "", "", "", "", "", "", ""})

	key = StringFromList(POST_DAQ_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
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
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(anaFuncs, {"ValidFunc_V2", "", "", "", "", "", "", "", ""})

	key = StringFromList(PRE_SET_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(anaFuncs, {"ValidFunc_V2", "", "", "", "", "", "", "", ""})

	key = StringFromList(PRE_SWEEP_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(anaFuncs, {"ValidFunc_V2", "", "", "", "", "", "", "", ""})

	key = StringFromList(MID_SWEEP_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(anaFuncs, {"ValidFunc_V2", "", "", "", "", "", "", "", ""})

	key = StringFromList(POST_SWEEP_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(anaFuncs, {"ValidFunc_V2", "", "", "", "", "", "", "", ""})

	key = StringFromList(POST_SET_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(anaFuncs, {"ValidFunc_V2", "", "", "", "", "", "", "", ""})

	key = StringFromList(POST_DAQ_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(anaFuncs, {"ValidFunc_V2", "", "", "", "", "", "", "", ""})

	key = StringFromList(GENERIC_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, NULL_WAVE)
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
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, NULL_WAVE)

	key = StringFromList(PRE_SET_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, NULL_WAVE)

	key = StringFromList(PRE_SWEEP_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, NULL_WAVE)

	key = StringFromList(MID_SWEEP_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, NULL_WAVE)

	key = StringFromList(POST_SWEEP_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, NULL_WAVE)

	key = StringFromList(POST_SET_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, NULL_WAVE)

	key = StringFromList(POST_DAQ_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, NULL_WAVE)

	key = StringFromList(GENERIC_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
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
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(anaFuncs, {"NotCalled_V1", "", "", "", "", "", "", "", ""})

	key = StringFromList(PRE_SET_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(anaFuncs, {"NotCalled_V1", "", "", "", "", "", "", "", ""})

	key = StringFromList(PRE_SWEEP_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(anaFuncs, {"NotCalled_V1", "", "", "", "", "", "", "", ""})

	key = StringFromList(MID_SWEEP_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(anaFuncs, {"NotCalled_V1", "", "", "", "", "", "", "", ""})

	key = StringFromList(POST_SWEEP_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(anaFuncs, {"NotCalled_V1", "", "", "", "", "", "", "", ""})

	key = StringFromList(POST_SET_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(anaFuncs, {"NotCalled_V1", "", "", "", "", "", "", "", ""})

	key = StringFromList(POST_DAQ_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(anaFuncs, {"NotCalled_V1", "", "", "", "", "", "", "", ""})

	key = StringFromList(GENERIC_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
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
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(anaFuncs, {"ValidMultHS_V1", "ValidMultHS_V1", "", "", "", "", "", "", ""})

	key = StringFromList(PRE_SET_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(anaFuncs, {"ValidMultHS_V1", "ValidMultHS_V1", "", "", "", "", "", "", ""})

	key = StringFromList(PRE_SWEEP_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(anaFuncs, {"ValidMultHS_V1", "ValidMultHS_V1", "", "", "", "", "", "", ""})

	key = StringFromList(MID_SWEEP_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(anaFuncs, {"ValidMultHS_V1", "ValidMultHS_V1", "", "", "", "", "", "", ""})

	key = StringFromList(POST_SWEEP_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(anaFuncs, {"ValidMultHS_V1", "ValidMultHS_V1", "", "", "", "", "", "", ""})

	key = StringFromList(POST_SET_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(anaFuncs, {"ValidMultHS_V1", "ValidMultHS_V1", "", "", "", "", "", "", ""})

	key = StringFromList(POST_DAQ_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(anaFuncs, {"ValidMultHS_V1", "ValidMultHS_V1", "", "", "", "", "", "", ""})

	key = StringFromList(GENERIC_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, NULL_WAVE)
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
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, NULL_WAVE)

	key = StringFromList(PRE_SET_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, NULL_WAVE)

	key = StringFromList(PRE_SWEEP_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, NULL_WAVE)

	key = StringFromList(MID_SWEEP_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, NULL_WAVE)

	key = StringFromList(POST_SWEEP_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, NULL_WAVE)

	key = StringFromList(POST_SET_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, NULL_WAVE)

	key = StringFromList(POST_DAQ_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, NULL_WAVE)

	key = StringFromList(GENERIC_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, NULL_WAVE)
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
	CHECK_EQUAL_VAR(anaFuncTracker[PRE_SET_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[PRE_SWEEP_EVENT], 1)
	CHECK(anaFuncTracker[MID_SWEEP_EVENT] >= 1)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_SWEEP_EVENT], 0)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_SET_EVENT], 0)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_DAQ_EVENT], 0)
	CHECK_EQUAL_VAR(anaFuncTracker[GENERIC_EVENT], 0)

	WAVE/T textualValues = GetLBTextualValues(DEVICE)
	key = StringFromList(PRE_DAQ_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(anaFuncs, {"ValidFunc_V2", "", "", "", "", "", "", "", ""})

	key = StringFromList(PRE_SET_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(anaFuncs, {"ValidFunc_V2", "", "", "", "", "", "", "", ""})

	key = StringFromList(PRE_SWEEP_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(anaFuncs, {"ValidFunc_V2", "", "", "", "", "", "", "", ""})

	key = StringFromList(MID_SWEEP_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(anaFuncs, {"ValidFunc_V2", "", "", "", "", "", "", "", ""})

	key = StringFromList(POST_SWEEP_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(anaFuncs, {"ValidFunc_V2", "", "", "", "", "", "", "", ""})

	key = StringFromList(POST_SET_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(anaFuncs, {"ValidFunc_V2", "", "", "", "", "", "", "", ""})

	key = StringFromList(POST_DAQ_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(anaFuncs, {"ValidFunc_V2", "", "", "", "", "", "", "", ""})

	key = StringFromList(GENERIC_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, NULL_WAVE)
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
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, NULL_WAVE)

	key = StringFromList(PRE_SET_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, NULL_WAVE)

	key = StringFromList(PRE_SWEEP_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, NULL_WAVE)

	key = StringFromList(MID_SWEEP_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, NULL_WAVE)

	key = StringFromList(POST_SWEEP_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, NULL_WAVE)

	key = StringFromList(POST_SET_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, NULL_WAVE)

	key = StringFromList(POST_DAQ_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, NULL_WAVE)

	key = StringFromList(GENERIC_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, NULL_WAVE)
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
	CHECK_EQUAL_VAR(anaFuncTracker[PRE_SET_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[PRE_SWEEP_EVENT], 20)
	CHECK(anaFuncTracker[MID_SWEEP_EVENT] >= 1)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_SWEEP_EVENT], 20)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_SET_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_DAQ_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[GENERIC_EVENT], 0)

	WAVE/T textualValues = GetLBTextualValues(DEVICE)
	key = StringFromList(PRE_DAQ_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(anaFuncs, {"preDAQ", "", "", "", "", "", "", "", ""})

	key = StringFromList(PRE_SET_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(anaFuncs, {"preSet", "", "", "", "", "", "", "", ""})

	key = StringFromList(PRE_SWEEP_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(anaFuncs, {"preSweep", "", "", "", "", "", "", "", ""})

	key = StringFromList(MID_SWEEP_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(anaFuncs, {"midSweep", "", "", "", "", "", "", "", ""})

	key = StringFromList(POST_SWEEP_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(anaFuncs, {"postSweep", "", "", "", "", "", "", "", ""})

	key = StringFromList(POST_SET_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(anaFuncs, {"postSet", "", "", "", "", "", "", "", ""})

	key = StringFromList(POST_DAQ_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(anaFuncs, {"postDAQ", "", "", "", "", "", "", "", ""})

	key = StringFromList(GENERIC_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, NULL_WAVE)
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
	CHECK_EQUAL_VAR(anaFuncTracker[PRE_SET_EVENT], 0)
	CHECK_EQUAL_VAR(anaFuncTracker[PRE_SWEEP_EVENT], 0)
	CHECK_EQUAL_VAR(anaFuncTracker[MID_SWEEP_EVENT], 0)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_SWEEP_EVENT], 0)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_SET_EVENT], 0)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_DAQ_EVENT], 0)
	CHECK_EQUAL_VAR(anaFuncTracker[GENERIC_EVENT], 0)

	WAVE/T textualValues = GetLBTextualValues(DEVICE)

	key = StringFromList(PRE_DAQ_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, NULL_WAVE)

	key = StringFromList(PRE_SET_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, NULL_WAVE)

	key = StringFromList(PRE_SWEEP_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, NULL_WAVE)

	key = StringFromList(MID_SWEEP_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, NULL_WAVE)

	key = StringFromList(POST_SWEEP_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, NULL_WAVE)

	key = StringFromList(POST_SET_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, NULL_WAVE)

	key = StringFromList(POST_DAQ_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, NULL_WAVE)

	key = StringFromList(GENERIC_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, NULL_WAVE)
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
	CHECK_EQUAL_VAR(anaFuncTracker[PRE_SET_EVENT], 0)
	CHECK_EQUAL_VAR(anaFuncTracker[PRE_SWEEP_EVENT], 0)
	CHECK_EQUAL_VAR(anaFuncTracker[MID_SWEEP_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_SWEEP_EVENT], 0)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_SET_EVENT], 0)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_DAQ_EVENT], 0)
	CHECK_EQUAL_VAR(anaFuncTracker[GENERIC_EVENT], 0)

	WAVE/T textualValues = GetLBTextualValues(DEVICE)

	key = StringFromList(PRE_DAQ_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, NULL_WAVE)

	key = StringFromList(PRE_SET_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, NULL_WAVE)

	key = StringFromList(PRE_SWEEP_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, NULL_WAVE)

	key = StringFromList(MID_SWEEP_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(anaFuncs, {"StopMidSweep", "StopMidSweep", "", "", "", "", "", "", ""})

	key = StringFromList(POST_SWEEP_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, NULL_WAVE)

	key = StringFromList(POST_SET_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, NULL_WAVE)

	key = StringFromList(POST_DAQ_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, NULL_WAVE)

	key = StringFromList(GENERIC_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, NULL_WAVE)
End

static Function SetParams1_IGNORE()

	string stimSet = "AnaFuncParams1_DA_0"
	WBP_AddAnalysisParameter(stimSet, "MyVar", str = "abcd")
	WBP_AddAnalysisParameter(stimSet, "MyStr", str = "abcd")
	WBP_AddAnalysisParameter(stimSet, "MyWave", wv = {1, 2, 3})
	Make/FREE/T textData = {"a", "b", "c"}
	WBP_AddAnalysisParameter(stimSet, "MyTextWave", wv = textData)
End

// test parameter handling
// tests also that no type parameters
// in Params1_V3_GetParams() are okay
static Function AFT_DAQ14()

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "DAQ_MD1_RA0_IDX0_LIDX0_BKG_1")

	FUNCREF CALLABLE_PROTO f = SetParams1_IGNORE
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
	CHECK_EQUAL_VAR(anaFuncTracker[PRE_SET_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[PRE_SWEEP_EVENT], 1)
	CHECK(anaFuncTracker[MID_SWEEP_EVENT] >= 1)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_SWEEP_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_SET_EVENT], 0)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_DAQ_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[GENERIC_EVENT], 0)

	WAVE/T textualValues = GetLBTextualValues(DEVICE)

	key = StringFromList(PRE_DAQ_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, NULL_WAVE)

	key = StringFromList(PRE_SET_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, NULL_WAVE)

	key = StringFromList(PRE_SWEEP_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, NULL_WAVE)

	key = StringFromList(MID_SWEEP_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, NULL_WAVE)

	key = StringFromList(POST_SWEEP_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, NULL_WAVE)

	key = StringFromList(POST_SET_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, NULL_WAVE)

	key = StringFromList(POST_DAQ_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, NULL_WAVE)

	key = StringFromList(GENERIC_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(anaFuncs, {"Params1_V3", "", "", "", "", "", "", "", ""})

	key = ANALYSIS_FUNCTION_PARAMS_LBN
	WAVE/T/Z anaFuncParams = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncParams, TEXT_WAVE)
End

static Function SetParams2_IGNORE()

	string stimSet = "AnaFuncParams2_DA_0"
	WBP_AddAnalysisParameter(stimSet, "MyStr", str = "abcd")
	WBP_AddAnalysisParameter(stimSet, "MyVar", str = "abcd")
End

// test parameter handling with valid type string and optional parameter
static Function AFT_DAQ14a()

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "DAQ_MD1_RA0_IDX0_LIDX0_BKG_1")

	FUNCREF CALLABLE_PROTO f = SetParams2_IGNORE
	AcquireData(s, "AnaFuncParams2_DA_0", postInitializeFunc = f)
End

static Function AFT_Test14a()

	variable sweepNo
	string key

	CHECK_EQUAL_VAR(GetSetVariable(DEVICE, "SetVar_Sweep"), 1)

	sweepNo = AFH_GetLastSweepAcquired(DEVICE)
	CHECK_EQUAL_VAR(sweepNo, 0)

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()

	CHECK_EQUAL_VAR(anaFuncTracker[PRE_DAQ_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[PRE_SET_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[PRE_SWEEP_EVENT], 1)
	CHECK(anaFuncTracker[MID_SWEEP_EVENT] >= 1)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_SWEEP_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_SET_EVENT], 0)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_DAQ_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[GENERIC_EVENT], 0)
End

static Function SetParams3_IGNORE()

	string stimSet = "AnaFuncParams3_DA_0"
	WBP_AddAnalysisParameter(stimSet, "MyStr", str = "abcd")
End

// test parameter handling with non-matching type string
static Function AFT_DAQ14b()

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "DAQ_MD1_RA0_IDX0_LIDX0_BKG_1")

	FUNCREF CALLABLE_PROTO f = SetParams3_IGNORE
	AcquireData(s, "AnaFuncParams3_DA_0", postInitializeFunc = f)
End

static Function AFT_Test14b()

	variable sweepNo
	string key

	CHECK_EQUAL_VAR(GetSetVariable(DEVICE, "SetVar_Sweep"), 1)

	sweepNo = AFH_GetLastSweepAcquired(DEVICE)
	CHECK_EQUAL_VAR(sweepNo, 0)

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()

	CHECK_EQUAL_VAR(anaFuncTracker[PRE_DAQ_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[PRE_SET_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[PRE_SWEEP_EVENT], 1)
	CHECK(anaFuncTracker[MID_SWEEP_EVENT] >= 1)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_SWEEP_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_SET_EVENT], 0)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_DAQ_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[GENERIC_EVENT], 0)
End

static Function SetParams4_IGNORE()

	string stimSet = "AnaFuncParams4_DA_0"
	WBP_AddAnalysisParameter(stimSet, "MyStr", str = "abcd")
End

// test parameter handling with invalid type string
static Function AFT_DAQ14c()

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "DAQ_MD1_RA0_IDX0_LIDX0_BKG_1")

	FUNCREF CALLABLE_PROTO f = SetParams4_IGNORE
	AcquireData(s, "AnaFuncParams4_DA_0", postInitializeFunc = f)
End

static Function AFT_Test14c()

	variable sweepNo
	string key

	CHECK_EQUAL_VAR(GetSetVariable(DEVICE, "SetVar_Sweep"), 1)

	sweepNo = AFH_GetLastSweepAcquired(DEVICE)
	CHECK_EQUAL_VAR(sweepNo, 0)

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()

	CHECK_EQUAL_VAR(anaFuncTracker[PRE_DAQ_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[PRE_SET_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[PRE_SWEEP_EVENT], 1)
	CHECK(anaFuncTracker[MID_SWEEP_EVENT] >= 1)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_SWEEP_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_SET_EVENT], 0)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_DAQ_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[GENERIC_EVENT], 0)
End

static Function DisableInsertTP_IGNORE()
	PGC_SetAndActivateControl(DEVICE, "Check_Settings_InsertTP", val = 0)
End

// MD: mid sweep event is also called for very short stimsets
static Function AFT_DAQ15()

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "DAQ_MD1_RA0_IDX0_LIDX0_BKG_1")

	AcquireData(s, "AnaFuncVeryShort*", preAcquireFunc=DisableInsertTP_IGNORE)
End

static Function AFT_Test15()

	variable sweepNo
	string key

	CHECK_EQUAL_VAR(GetSetVariable(DEVICE, "SetVar_Sweep"), 1)

	sweepNo = AFH_GetLastSweepAcquired(DEVICE)
	CHECK_EQUAL_VAR(sweepNo, 0)

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()

	CHECK_EQUAL_VAR(anaFuncTracker[PRE_DAQ_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[PRE_SET_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[PRE_SWEEP_EVENT], 1)
	CHECK(anaFuncTracker[MID_SWEEP_EVENT] >= 1)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_SWEEP_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_SET_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_DAQ_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[GENERIC_EVENT], 0)
End

// SD: mid sweep event is also called for very short stimsets
static Function AFT_DAQ16()

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "DAQ_MD0_RA0_IDX0_LIDX0_BKG_1")

	AcquireData(s, "AnaFuncVeryShort*", preAcquireFunc=DisableInsertTP_IGNORE)
End

static Function AFT_Test16()

	variable sweepNo
	string key

	CHECK_EQUAL_VAR(GetSetVariable(DEVICE, "SetVar_Sweep"), 1)

	sweepNo = AFH_GetLastSweepAcquired(DEVICE)
	CHECK_EQUAL_VAR(sweepNo, 0)

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()

	CHECK_EQUAL_VAR(anaFuncTracker[PRE_DAQ_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[PRE_SET_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[PRE_SWEEP_EVENT], 1)
	CHECK(anaFuncTracker[MID_SWEEP_EVENT] >= 1)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_SWEEP_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_SET_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_DAQ_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[GENERIC_EVENT], 0)
End

// Calling Abort during pre DAQ event will prevent DAQ
static Function AFT_DAQ17()

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "DAQ_MD0_RA0_IDX0_LIDX0_BKG_1")

	try
		AcquireData(s, "AnaFuncPreDAQHar_DA_0"); AbortOnRTE
		FAIL()
	catch
		PASS()
	endtry
End

static Function AFT_Test17()

	variable sweepNo
	string key

	CHECK_EQUAL_VAR(GetSetVariable(DEVICE, "SetVar_Sweep"), 0)

	sweepNo = AFH_GetLastSweepAcquired(DEVICE)
	CHECK_EQUAL_VAR(sweepNo, NaN)

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()

	CHECK_EQUAL_VAR(anaFuncTracker[PRE_DAQ_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[PRE_SET_EVENT], 0)
	CHECK_EQUAL_VAR(anaFuncTracker[PRE_SWEEP_EVENT], 0)
	CHECK_EQUAL_VAR(anaFuncTracker[MID_SWEEP_EVENT], 0)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_SWEEP_EVENT], 0)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_SET_EVENT], 0)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_DAQ_EVENT], 0)
	CHECK_EQUAL_VAR(anaFuncTracker[GENERIC_EVENT], 0)
End

static Function SetIndexingEnd()

	PGC_SetAndActivateControl(DEVICE, GetPanelControl(0, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_INDEX_END), str = "AnaFuncIdx2_DA_0")
End

// Analysis functions work properly with indexing
// We index from AnaFuncIdx1_DA_0 to AnaFuncIdx2_DA_0
// but only the second one has a analysis function set
static Function AFT_DAQ18()

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "DAQ_MD1_RA1_IDX1_LIDX0_BKG_1_RES_2")

	AcquireData(s, "AnaFuncIdx1_DA_0", preAcquireFunc = SetIndexingEnd)
End

static Function AFT_Test18()

	variable sweepNo
	string key

	CHECK_EQUAL_VAR(GetSetVariable(DEVICE, "SetVar_Sweep"), 4)

	sweepNo = AFH_GetLastSweepAcquired(DEVICE)
	CHECK_EQUAL_VAR(sweepNo, 3)

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()

	CHECK_EQUAL_VAR(anaFuncTracker[PRE_DAQ_EVENT], 0)
	CHECK_EQUAL_VAR(anaFuncTracker[PRE_SET_EVENT], 2)
	CHECK_EQUAL_VAR(anaFuncTracker[PRE_SWEEP_EVENT], 2)
	CHECK(anaFuncTracker[MID_SWEEP_EVENT] >= 1)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_SWEEP_EVENT], 2)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_SET_EVENT], 2)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_DAQ_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[GENERIC_EVENT], 0)

	// analysis function storage was must be correct
	// even after indexing
	WAVE analysisFunctions = GetAnalysisFunctionStorage(DEVICE)
	Duplicate/FREE analysisFunctions, analysisFunctionsBefore

	AFM_UpdateAnalysisFunctionWave(DEVICE)

	WAVE analysisFunctionsAfter = GetAnalysisFunctionStorage(DEVICE)
	CHECK_EQUAL_WAVES(analysisFunctionsBefore, analysisFunctionsAfter)
End

// check that pre-set-event can abort
static Function AFT_DAQ19()

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "DAQ_MD1_RA0_IDX0_LIDX0_BKG_1")

	AcquireData(s, "AnaFuncPreSetHar_DA_0")
End

static Function AFT_Test19()

	variable sweepNo
	string key

	CHECK_EQUAL_VAR(GetSetVariable(DEVICE, "SetVar_Sweep"), 0)

	sweepNo = AFH_GetLastSweepAcquired(DEVICE)
	CHECK_EQUAL_VAR(sweepNo, NaN)

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()

	CHECK_EQUAL_VAR(anaFuncTracker[PRE_DAQ_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[PRE_SET_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[PRE_SWEEP_EVENT], 0)
	CHECK_EQUAL_VAR(anaFuncTracker[MID_SWEEP_EVENT], 0)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_SWEEP_EVENT], 0)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_SET_EVENT], 0)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_DAQ_EVENT], 0)
	CHECK_EQUAL_VAR(anaFuncTracker[GENERIC_EVENT], 0)
End

// check total ordering of events via timestamps
static Function AFT_DAQ20()

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "DAQ_MD1_RA0_IDX0_LIDX0_BKG_1")

	AcquireData(s, "AnaFuncOrder_DA_0")
End

static Function AFT_Test20()

	variable sweepNo

	CHECK_EQUAL_VAR(GetSetVariable(DEVICE, "SetVar_Sweep"), 1)

	sweepNo = AFH_GetLastSweepAcquired(DEVICE)
	CHECK_EQUAL_VAR(sweepNo, 0)

	WAVE anaFuncOrder = TrackAnalysisFunctionOrder()

	Make/FREE indexWave = {PRE_DAQ_EVENT, PRE_SET_EVENT, PRE_SWEEP_EVENT, MID_SWEEP_EVENT, POST_SWEEP_EVENT, POST_SET_EVENT, POST_DAQ_EVENT}
	Make/FREE/N=(DimSize(indexWave, ROWS)) anaFuncOrderIndex = anaFuncOrder[indexWave[p]]

	Duplicate/FREE anaFuncOrderIndex, anaFuncOrderSorted
	Sort anaFuncOrderSorted, anaFuncOrderSorted

	CHECK_EQUAL_WAVES(anaFuncOrderIndex, anaFuncOrderSorted)
End

static Function AFT_SetControls1_Setter()

	Make/FREE/T payload = {"Pre DAQ", "1"}
	WBP_AddAnalysisParameter("AnaFuncSetCtrl_DA_0", "unknown_ctrl", wv=payload)
End

// complains on invalid control
static Function AFT_SetControls1()

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "DAQ_MD1_RA0_IDX0_LIDX0_BKG_1")

	try
		AcquireData(s, "AnaFuncSetCtrl_DA_0", postInitializeFunc = AFT_SetControls1_Setter)
		FAIL()
	catch
		PASS()
	endtry
End

static Function AFT_SetControlsTest1()

	variable sweepNo

	CHECK_EQUAL_VAR(GetSetVariable(DEVICE, "SetVar_Sweep"), 0)

	sweepNo = AFH_GetLastSweepAcquired(DEVICE)
	CHECK_EQUAL_VAR(sweepNo, NaN)
End

static Function AFT_SetControls2_Setter()

	WBP_AddAnalysisParameter("AnaFuncSetCtrl_DA_0", "Check_DataAcq_Indexing", str="myValue")
End

// complains on wrong parameter type (string)
static Function AFT_SetControls2()

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "DAQ_MD1_RA0_IDX0_LIDX0_BKG_1")

	try
		AcquireData(s, "AnaFuncSetCtrl_DA_0", postInitializeFunc = AFT_SetControls2_Setter)
		FAIL()
	catch
		PASS()
	endtry
End

static Function AFT_SetControlsTest2()

	variable sweepNo

	CHECK_EQUAL_VAR(GetSetVariable(DEVICE, "SetVar_Sweep"), 0)

	sweepNo = AFH_GetLastSweepAcquired(DEVICE)
	CHECK_EQUAL_VAR(sweepNo, NaN)
End

static Function AFT_SetControls2a_Setter()

	WBP_AddAnalysisParameter("AnaFuncSetCtrl_DA_0", "Check_DataAcq_Indexing", var = 1)
End

// complains on wrong parameter type (numeric)
static Function AFT_SetControls2a()

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "DAQ_MD1_RA0_IDX0_LIDX0_BKG_1")

	try
		AcquireData(s, "AnaFuncSetCtrl_DA_0", postInitializeFunc = AFT_SetControls2a_Setter)
		FAIL()
	catch
		PASS()
	endtry
End

static Function AFT_SetControlsTest2a()

	variable sweepNo

	CHECK_EQUAL_VAR(GetSetVariable(DEVICE, "SetVar_Sweep"), 0)

	sweepNo = AFH_GetLastSweepAcquired(DEVICE)
	CHECK_EQUAL_VAR(sweepNo, NaN)
End

static Function AFT_SetControls2b_Setter()

	Make/FREE wv
	WBP_AddAnalysisParameter("AnaFuncSetCtrl_DA_0", "Check_DataAcq_Indexing", wv = wv)
End

// complains on wrong parameter type (numeric wave)
static Function AFT_SetControls2b()

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "DAQ_MD1_RA0_IDX0_LIDX0_BKG_1")

	try
		AcquireData(s, "AnaFuncSetCtrl_DA_0", postInitializeFunc = AFT_SetControls2b_Setter)
		FAIL()
	catch
		PASS()
	endtry
End

static Function AFT_SetControlsTest2b()

	variable sweepNo

	CHECK_EQUAL_VAR(GetSetVariable(DEVICE, "SetVar_Sweep"), 0)

	sweepNo = AFH_GetLastSweepAcquired(DEVICE)
	CHECK_EQUAL_VAR(sweepNo, NaN)
End

static Function AFT_SetControls3_Setter()

	Make/FREE/T wv
	WBP_AddAnalysisParameter("AnaFuncSetCtrl_DA_0", "Check_DataAcq_Indexing", wv = wv)
End

// invalid parameter wave size
static Function AFT_SetControls3()

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "DAQ_MD1_RA0_IDX0_LIDX0_BKG_1")

	try
		AcquireData(s, "AnaFuncSetCtrl_DA_0", postInitializeFunc = AFT_SetControls3_Setter)
		FAIL()
	catch
		PASS()
	endtry
End

static Function AFT_SetControlsTest3()

	variable sweepNo

	CHECK_EQUAL_VAR(GetSetVariable(DEVICE, "SetVar_Sweep"), 0)

	sweepNo = AFH_GetLastSweepAcquired(DEVICE)
	CHECK_EQUAL_VAR(sweepNo, NaN)
End

static Function AFT_SetControls3a_Setter()

	Make/FREE/T wv = {"Unknown", "1"}
	WBP_AddAnalysisParameter("AnaFuncSetCtrl_DA_0", "Check_DataAcq_Indexing", wv = wv)
End

// invalid event type (unknown)
static Function AFT_SetControls3a()

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "DAQ_MD1_RA0_IDX0_LIDX0_BKG_1")

	try
		AcquireData(s, "AnaFuncSetCtrl_DA_0", postInitializeFunc = AFT_SetControls3a_Setter)
		FAIL()
	catch
		PASS()
	endtry
End

static Function AFT_SetControlsTest3a()

	variable sweepNo

	CHECK_EQUAL_VAR(GetSetVariable(DEVICE, "SetVar_Sweep"), 0)

	sweepNo = AFH_GetLastSweepAcquired(DEVICE)
	CHECK_EQUAL_VAR(sweepNo, NaN)
End

static Function AFT_SetControls3b_Setter()

	Make/FREE/T wv = {"Mid Sweep", "1"}
	WBP_AddAnalysisParameter("AnaFuncSetCtrl_DA_0", "Check_DataAcq_Indexing", wv = wv)
End

// invalid event type (mid sweep)
static Function AFT_SetControls3b()

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "DAQ_MD1_RA0_IDX0_LIDX0_BKG_1")

	try
		AcquireData(s, "AnaFuncSetCtrl_DA_0", postInitializeFunc = AFT_SetControls3b_Setter)
		FAIL()
	catch
		PASS()
	endtry
End

static Function AFT_SetControlsTest3b()

	variable sweepNo

	CHECK_EQUAL_VAR(GetSetVariable(DEVICE, "SetVar_Sweep"), 0)

	sweepNo = AFH_GetLastSweepAcquired(DEVICE)
	CHECK_EQUAL_VAR(sweepNo, NaN)
End

static Function AFT_SetControls3c_Setter()

	Make/FREE/T wv = {"Generic", "1"}
	WBP_AddAnalysisParameter("AnaFuncSetCtrl_DA_0", "Check_DataAcq_Indexing", wv = wv)
End

// invalid event type (generic)
static Function AFT_SetControls3c()

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "DAQ_MD1_RA0_IDX0_LIDX0_BKG_1")

	try
		AcquireData(s, "AnaFuncSetCtrl_DA_0", postInitializeFunc = AFT_SetControls3c_Setter)
		FAIL()
	catch
		PASS()
	endtry
End

static Function AFT_SetControlsTest3c()

	variable sweepNo

	CHECK_EQUAL_VAR(GetSetVariable(DEVICE, "SetVar_Sweep"), 0)

	sweepNo = AFH_GetLastSweepAcquired(DEVICE)
	CHECK_EQUAL_VAR(sweepNo, NaN)
End

static Function AFT_SetControls4_Setter()

	Make/FREE/T wv = {"Pre Sweep", "1"}
	WBP_AddAnalysisParameter("AnaFuncSetCtrl_DA_0", "Check_DataAcq_Indexing", wv = wv)
End

// unchangeable control in other event than pre DAQ
static Function AFT_SetControls4()

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "DAQ_MD1_RA0_IDX0_LIDX0_BKG_1")

	try
		AcquireData(s, "AnaFuncSetCtrl_DA_0", postInitializeFunc = AFT_SetControls4_Setter)
		FAIL()
	catch
		PASS()
	endtry
End

static Function AFT_SetControlsTest4()

	variable sweepNo

	CHECK_EQUAL_VAR(GetSetVariable(DEVICE, "SetVar_Sweep"), 0)

	sweepNo = AFH_GetLastSweepAcquired(DEVICE)
	CHECK_EQUAL_VAR(sweepNo, NaN)
End

static Function AFT_SetControls5_Setter()

	Make/FREE/T wv = {"Post Sweep", "0"}
	WBP_AddAnalysisParameter("AnaFuncSetCtrl_DA_0", "Check_DataAcqHS_00", wv = wv)
End

// hidden control is ignored
static Function AFT_SetControls5()

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "DAQ_MD1_RA0_IDX0_LIDX0_BKG_1")

	AcquireData(s, "AnaFuncSetCtrl_DA_0", postInitializeFunc = AFT_SetControls5_Setter)
End

static Function AFT_SetControlsTest5()

	variable sweepNo

	CHECK_EQUAL_VAR(GetSetVariable(DEVICE, "SetVar_Sweep"), 1)

	sweepNo = AFH_GetLastSweepAcquired(DEVICE)
	CHECK_EQUAL_VAR(sweepNo, 0)

	CHECK_EQUAL_VAR(GetCheckBoxState(DEVICE, "Check_DataAcqHS_00"), 1)
End

static Function AFT_SetControls6_Setter()

	// indexing and repeated acquistion are special as both can only be set in Pre/POST DAQ

	Make/FREE/T/N=2 wv
	wv[] = {"Pre DAQ", "0"}
	WBP_AddAnalysisParameter("AnaFuncSetCtrl_DA_0", "Check_DataAcq1_RepeatAcq", wv = wv)

	wv[] = {"Pre DAQ", "1"}
	WBP_AddAnalysisParameter("AnaFuncSetCtrl_DA_0", "Check_Settings_UseDoublePrec", wv = wv)

	wv[] = {"Pre Set", "47"}
	WBP_AddAnalysisParameter("AnaFuncSetCtrl_DA_0", "SetVar_DataAcq_TPBaselinePerc", wv = wv)

	wv[] = {"Pre Sweep", "4"}
	WBP_AddAnalysisParameter("AnaFuncSetCtrl_DA_0", "Popup_Settings_SampIntMult", wv = wv)

	wv[] = {"Post Sweep", "abcd efgh"}
	WBP_AddAnalysisParameter("AnaFuncSetCtrl_DA_0", "SetVar_DataAcq_Comment", wv = wv)

	wv[] = {"Post Set", "10"}
	WBP_AddAnalysisParameter("AnaFuncSetCtrl_DA_0", "setvar_DataAcq_OnsetDelayUser", wv = wv)

	wv[] = {"Post DAQ", "0"}
	WBP_AddAnalysisParameter("AnaFuncSetCtrl_DA_0", "Check_DataAcq_Indexing", wv = wv)
End

// works with different controls
static Function AFT_SetControls6()

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "DAQ_MD1_RA0_IDX0_LIDX0_BKG_1")

	AcquireData(s, "AnaFuncSetCtrl_DA_0", postInitializeFunc = AFT_SetControls6_Setter)
End

static Function AFT_SetControlsTest6()

	variable sweepNo
	string ref, actual

	CHECK_EQUAL_VAR(GetSetVariable(DEVICE, "SetVar_Sweep"), 1)

	sweepNo = AFH_GetLastSweepAcquired(DEVICE)
	CHECK_EQUAL_VAR(sweepNo, 0)

	CHECK_EQUAL_VAR(GetCheckBoxState(DEVICE, "Check_DataAcq1_RepeatAcq"), 0)
	CHECK_EQUAL_VAR(GetCheckBoxState(DEVICE, "Check_Settings_UseDoublePrec"), 1)
	CHECK_EQUAL_VAR(GetSetVariable(DEVICE, "setvar_DataAcq_OnsetDelayUser"), 10)

	ref = "abcd efgh"
	actual = GetSetVariableString(DEVICE, "SetVar_DataAcq_Comment")
	CHECK_EQUAL_STR(ref, actual)

	CHECK_EQUAL_VAR(GetSetVariable(DEVICE, "SetVar_DataAcq_TPBaselinePerc"), 47)
	CHECK_EQUAL_VAR(GetSetVariable(DEVICE, "setvar_DataAcq_OnsetDelayUser"), 10)
	// the third entry is four
	CHECK_EQUAL_VAR(GetPopupMenuIndex(DEVICE, "Popup_Settings_SampIntMult"), 2)
End
