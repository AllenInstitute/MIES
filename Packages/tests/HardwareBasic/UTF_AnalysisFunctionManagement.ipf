#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma ModuleName=AnalysisFunctionTesting

static Function GlobalPreAcq(string device)

	PASS()
End

static Function GlobalPreInit(string device)

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()
	KillOrMoveToTrash(wv = anaFuncTracker)

	WAVE anaFuncOrder = TrackAnalysisFunctionOrder()
	KillOrMoveToTrash(wv = anaFuncOrder)

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()
End

static Function ChangeAnalysisFunctions_IGNORE()

	ST_SetStimsetParameter("AnaFuncAbortPre_DA_0", "Analysis pre DAQ function", str = "AbortPreDAQ")

	ST_SetStimsetParameter("AnaFuncDiff_DA_0", "Analysis pre DAQ function", str = "preDAQ")
	ST_SetStimsetParameter("AnaFuncDiff_DA_0", "Analysis pre set function", str = "preSet")
	ST_SetStimsetParameter("AnaFuncDiff_DA_0", "Analysis pre sweep function", str = "preSweepConfig")
	ST_SetStimsetParameter("AnaFuncDiff_DA_0", "Analysis mid sweep function", str = "midSweep")
	ST_SetStimsetParameter("AnaFuncDiff_DA_0", "Analysis post sweep function", str = "postSweep")
	ST_SetStimsetParameter("AnaFuncDiff_DA_0", "Analysis post set function", str = "postSet")
	ST_SetStimsetParameter("AnaFuncDiff_DA_0", "Analysis post DAQ function", str = "postDAQ")

	ST_SetStimsetParameter("AnaFuncInvalid1_DA_0", "Analysis pre DAQ function", str = "InvalidSignatureAndReturnType")
	ST_SetStimsetParameter("AnaFuncInvalid1_DA_0", "Analysis pre set function", str = "InvalidSignature")
	ST_SetStimsetParameter("AnaFuncInvalid1_DA_0", "Analysis pre sweep function", str = "InvalidSignature")
	ST_SetStimsetParameter("AnaFuncInvalid1_DA_0", "Analysis mid sweep function", str = "InvalidReturnTypeAndValidSig_V1")
	ST_SetStimsetParameter("AnaFuncInvalid1_DA_0", "Analysis post sweep function", str = "InvalidSignatureAndReturnType")
	ST_SetStimsetParameter("AnaFuncInvalid1_DA_0", "Analysis post set function", str = "InvalidSignature")
	ST_SetStimsetParameter("AnaFuncInvalid1_DA_0", "Analysis post DAQ function", str = "InvalidSignatureAndReturnType")

	ST_SetStimsetParameter("AnaFuncInvalid2_DA_0", "Analysis pre DAQ function", str = "InvalidSignatureAndReturnType")
	ST_SetStimsetParameter("AnaFuncInvalid2_DA_0", "Analysis pre set function", str = "InvalidSignature")
	ST_SetStimsetParameter("AnaFuncInvalid2_DA_0", "Analysis pre sweep function", str = "InvalidSignature")
	ST_SetStimsetParameter("AnaFuncInvalid2_DA_0", "Analysis mid sweep function", str = "InvalidReturnTypeAndValidSig_V2")
	ST_SetStimsetParameter("AnaFuncInvalid2_DA_0", "Analysis post sweep function", str = "InvalidSignatureAndReturnType")
	ST_SetStimsetParameter("AnaFuncInvalid2_DA_0", "Analysis post set function", str = "InvalidSignature")
	ST_SetStimsetParameter("AnaFuncInvalid2_DA_0", "Analysis post DAQ function", str = "InvalidSignatureAndReturnType")

	ST_SetStimsetParameter("AnaFuncStopMid_DA_0", "Analysis mid sweep function", str = "StopMidSweep")

	ST_SetStimsetParameter("AnaFuncValidMult_DA_0", "Analysis pre DAQ function", str = "ValidMultHS_V1")
	ST_SetStimsetParameter("AnaFuncValidMult_DA_0", "Analysis pre set function", str = "ValidMultHS_V1")
	ST_SetStimsetParameter("AnaFuncValidMult_DA_0", "Analysis pre sweep function", str = "ValidMultHS_V1")
	ST_SetStimsetParameter("AnaFuncValidMult_DA_0", "Analysis mid sweep function", str = "ValidMultHS_V1")
	ST_SetStimsetParameter("AnaFuncValidMult_DA_0", "Analysis post sweep function", str = "ValidMultHS_V1")
	ST_SetStimsetParameter("AnaFuncValidMult_DA_0", "Analysis post set function", str = "ValidMultHS_V1")
	ST_SetStimsetParameter("AnaFuncValidMult_DA_0", "Analysis post DAQ function", str = "ValidMultHS_V1")

	ST_SetStimsetParameter("AnaFuncValid1_DA_0", "Analysis pre DAQ function", str = "ValidFunc_V1")
	ST_SetStimsetParameter("AnaFuncValid1_DA_0", "Analysis pre set function", str = "ValidFunc_V1")
	ST_SetStimsetParameter("AnaFuncValid1_DA_0", "Analysis pre sweep function", str = "ValidFunc_V1")
	ST_SetStimsetParameter("AnaFuncValid1_DA_0", "Analysis mid sweep function", str = "ValidFunc_V1")
	ST_SetStimsetParameter("AnaFuncValid1_DA_0", "Analysis post sweep function", str = "ValidFunc_V1")
	ST_SetStimsetParameter("AnaFuncValid1_DA_0", "Analysis post set function", str = "ValidFunc_V1")
	ST_SetStimsetParameter("AnaFuncValid1_DA_0", "Analysis post DAQ function", str = "ValidFunc_V1")

	ST_SetStimsetParameter("AnaFuncValid2_DA_0", "Analysis pre DAQ function", str = "ValidFunc_V2")
	ST_SetStimsetParameter("AnaFuncValid2_DA_0", "Analysis pre set function", str = "ValidFunc_V2")
	ST_SetStimsetParameter("AnaFuncValid2_DA_0", "Analysis pre sweep function", str = "ValidFunc_V2")
	ST_SetStimsetParameter("AnaFuncValid2_DA_0", "Analysis mid sweep function", str = "ValidFunc_V2")
	ST_SetStimsetParameter("AnaFuncValid2_DA_0", "Analysis post sweep function", str = "ValidFunc_V2")
	ST_SetStimsetParameter("AnaFuncValid2_DA_0", "Analysis post set function", str = "ValidFunc_V2")
	ST_SetStimsetParameter("AnaFuncValid2_DA_0", "Analysis post DAQ function", str = "ValidFunc_V2")

	ST_SetStimsetParameter("AnaFuncValid3_DA_0", "Analysis function (generic)", str = "ValidFunc_V3")

	ST_SetStimsetParameter("AnaFuncParams1_DA_0", "Analysis function (generic)", str = "Params1_V3")
	ST_SetStimsetParameter("AnaFuncParams2_DA_0", "Analysis function (generic)", str = "Params2_V3")
	ST_SetStimsetParameter("AnaFuncParams3_DA_0", "Analysis function (generic)", str = "Params3_V3")
	ST_SetStimsetParameter("AnaFuncParams4_DA_0", "Analysis function (generic)", str = "Params4_V3")

	ST_SetStimsetParameter("AnaFuncGeneric_DA_0", "Analysis pre DAQ function", str = "NotCalled_V1")
	ST_SetStimsetParameter("AnaFuncGeneric_DA_0", "Analysis pre set function", str = "NotCalled_V1")
	ST_SetStimsetParameter("AnaFuncGeneric_DA_0", "Analysis pre sweep function", str = "NotCalled_V1")
	ST_SetStimsetParameter("AnaFuncGeneric_DA_0", "Analysis mid sweep function", str = "NotCalled_V1")
	ST_SetStimsetParameter("AnaFuncGeneric_DA_0", "Analysis post sweep function", str = "NotCalled_V1")
	ST_SetStimsetParameter("AnaFuncGeneric_DA_0", "Analysis post set function", str = "NotCalled_V1")
	ST_SetStimsetParameter("AnaFuncGeneric_DA_0", "Analysis post DAQ function", str = "NotCalled_V1")
	ST_SetStimsetParameter("AnaFuncGeneric_DA_0", "Analysis function (generic)", str = "ValidFunc_V3")

	ST_SetStimsetParameter("AnaFuncTTLNot_TTL_0", "Analysis pre DAQ function", str = "NotCalled_V1")
	ST_SetStimsetParameter("AnaFuncTTLNot_TTL_0", "Analysis pre set function", str = "NotCalled_V1")
	ST_SetStimsetParameter("AnaFuncTTLNot_TTL_0", "Analysis pre sweep function", str = "NotCalled_V1")
	ST_SetStimsetParameter("AnaFuncTTLNot_TTL_0", "Analysis mid sweep function", str = "NotCalled_V1")
	ST_SetStimsetParameter("AnaFuncTTLNot_TTL_0", "Analysis post sweep function", str = "NotCalled_V1")
	ST_SetStimsetParameter("AnaFuncTTLNot_TTL_0", "Analysis post set function", str = "NotCalled_V1")
	ST_SetStimsetParameter("AnaFuncTTLNot_TTL_0", "Analysis post DAQ function", str = "NotCalled_V1")

	ST_SetStimsetParameter("AnaFuncMissing_DA_0", "Analysis pre DAQ function", str = "IDontExist")
	ST_SetStimsetParameter("AnaFuncMissing_DA_0", "Analysis pre set function", str = "IDontExist")
	ST_SetStimsetParameter("AnaFuncMissing_DA_0", "Analysis pre sweep function", str = "IDontExist")
	ST_SetStimsetParameter("AnaFuncMissing_DA_0", "Analysis mid sweep function", str = "IDontExist")
	ST_SetStimsetParameter("AnaFuncMissing_DA_0", "Analysis post sweep function", str = "IDontExist")
	ST_SetStimsetParameter("AnaFuncMissing_DA_0", "Analysis post set function", str = "IDontExist")
	ST_SetStimsetParameter("AnaFuncMissing_DA_0", "Analysis post DAQ function", str = "IDontExist")

	ST_SetStimsetParameter("AnaFuncVeryShort_DA_0", "Analysis function (generic)", str = "ValidFunc_V3")

	ST_SetStimsetParameter("AnaFuncPreDAQHar_DA_0", "Analysis pre DAQ function", str = "preDAQHardAbort")

	ST_SetStimsetParameter("AnaFuncPreSetHar_DA_0", "Analysis function (generic)", str = "AbortPreSet")

	ST_SetStimsetParameter("AnaFuncOrder_DA_0", "Analysis function (generic)", str = "TotalOrdering")

	ST_SetStimsetParameter("AnaFuncPostDAQ_DA_0", "Analysis function (generic)", str = "ChangeStimSet")
End

Function RewriteAnalysisFunctions_IGNORE()
	LoadStimsets()
	ChangeAnalysisFunctions_IGNORE()
	SaveStimsets()
End

// invalid analysis functions
// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function AFT1([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG1_FAR0"                    + \
	                             "__HS0_DA0_AD0_CM:IC:_ST:AnaFuncInvalid1_DA_0:")

	try
		AcquireData_NG(s, str); AbortOnRTE
		FAIL()
	catch
		PASS()
	endtry
End

static Function AFT1_REENTRY([str])
	string str

	variable sweepNo
	string   key

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 0)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, NaN)

	WAVE/T textualValues = GetLBTextualValues(str)
	key = StringFromList(PRE_DAQ_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, NULL_WAVE)

	key = StringFromList(PRE_SET_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, NULL_WAVE)

	key = StringFromList(PRE_SWEEP_CONFIG_EVENT, EVENT_NAME_LIST_LBN)
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
// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function AFT2([str])
	string str

	variable sweepNo

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG1_FAR0"                    + \
	                             "__HS0_DA0_AD0_CM:IC:_ST:AnaFuncInvalid2_DA_0:")

	try
		AcquireData_NG(s, str); AbortOnRTE
		FAIL()
	catch
		PASS()
	endtry
End

static Function AFT2_REENTRY([str])
	string str

	variable sweepNo
	string   key

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 0)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, NaN)

	WAVE/T textualValues = GetLBTextualValues(str)
	key = StringFromList(PRE_DAQ_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, NULL_WAVE)

	key = StringFromList(PRE_SET_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, NULL_WAVE)

	key = StringFromList(PRE_SWEEP_CONFIG_EVENT, EVENT_NAME_LIST_LBN)
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
// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function AFT3([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG1"                       + \
	                             "__HS0_DA0_AD0_CM:IC:_ST:AnaFuncValid1_DA_0:")
	AcquireData_NG(s, str)
End

static Function AFT3_REENTRY([str])
	string str

	variable sweepNo
	string   key

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 1)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, 0)

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()
	CHECK_EQUAL_VAR(anaFuncTracker[PRE_DAQ_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[PRE_SET_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[PRE_SWEEP_CONFIG_EVENT], 1)
	CHECK_GE_VAR(anaFuncTracker[MID_SWEEP_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_SWEEP_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_SET_EVENT], 0)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_DAQ_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[GENERIC_EVENT], 0)

	WAVE/T textualValues = GetLBTextualValues(str)
	key = StringFromList(PRE_DAQ_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(anaFuncs, {"ValidFunc_V1", "", "", "", "", "", "", "", ""})

	key = StringFromList(PRE_SET_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(anaFuncs, {"ValidFunc_V1", "", "", "", "", "", "", "", ""})

	key = StringFromList(PRE_SWEEP_CONFIG_EVENT, EVENT_NAME_LIST_LBN)
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
// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function AFT4([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG1"                       + \
	                             "__HS0_DA0_AD0_CM:IC:_ST:AnaFuncValid1_DA_0:")
	AcquireData_NG(s, str)
End

static Function AFT4_REENTRY([str])
	string str

	variable sweepNo
	string   key

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 20)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, 19)

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()
	CHECK_EQUAL_VAR(anaFuncTracker[PRE_DAQ_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[PRE_SET_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[PRE_SWEEP_CONFIG_EVENT], 20)
	CHECK_GE_VAR(anaFuncTracker[MID_SWEEP_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_SWEEP_EVENT], 20)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_SET_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_DAQ_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[GENERIC_EVENT], 0)

	WAVE/T textualValues = GetLBTextualValues(str)
	key = StringFromList(PRE_DAQ_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(anaFuncs, {"ValidFunc_V1", "", "", "", "", "", "", "", ""})

	key = StringFromList(PRE_SET_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(anaFuncs, {"ValidFunc_V1", "", "", "", "", "", "", "", ""})

	key = StringFromList(PRE_SWEEP_CONFIG_EVENT, EVENT_NAME_LIST_LBN)
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
// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function AFT5([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG1"                       + \
	                             "__HS0_DA0_AD0_CM:IC:_ST:AnaFuncValid2_DA_0:")
	AcquireData_NG(s, str)
End

static Function AFT5_REENTRY([str])
	string str

	variable sweepNo
	string   key

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 1)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, 0)

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()
	CHECK_EQUAL_VAR(anaFuncTracker[PRE_DAQ_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[PRE_SET_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[PRE_SWEEP_CONFIG_EVENT], 1)
	CHECK_GE_VAR(anaFuncTracker[MID_SWEEP_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_SWEEP_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_SET_EVENT], 0)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_DAQ_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[GENERIC_EVENT], 0)

	WAVE/T textualValues = GetLBTextualValues(str)
	key = StringFromList(PRE_DAQ_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(anaFuncs, {"ValidFunc_V2", "", "", "", "", "", "", "", ""})

	key = StringFromList(PRE_SWEEP_CONFIG_EVENT, EVENT_NAME_LIST_LBN)
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
// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function AFT6([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG1"                       + \
	                             "__HS0_DA0_AD0_CM:IC:_ST:AnaFuncValid2_DA_0:")
	AcquireData_NG(s, str)
End

static Function AFT6_REENTRY([str])
	string str

	variable sweepNo
	string   key

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 20)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, 19)

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()
	CHECK_EQUAL_VAR(anaFuncTracker[PRE_DAQ_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[PRE_SET_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[PRE_SWEEP_CONFIG_EVENT], 20)
	CHECK_GE_VAR(anaFuncTracker[MID_SWEEP_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_SWEEP_EVENT], 20)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_SET_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_DAQ_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[GENERIC_EVENT], 0)

	WAVE/T textualValues = GetLBTextualValues(str)
	key = StringFromList(PRE_DAQ_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(anaFuncs, {"ValidFunc_V2", "", "", "", "", "", "", "", ""})

	key = StringFromList(PRE_SET_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(anaFuncs, {"ValidFunc_V2", "", "", "", "", "", "", "", ""})

	key = StringFromList(PRE_SWEEP_CONFIG_EVENT, EVENT_NAME_LIST_LBN)
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
// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function AFT6a([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG1"                       + \
	                             "__HS0_DA0_AD0_CM:IC:_ST:AnaFuncValid3_DA_0:")
	AcquireData_NG(s, str)
End

static Function AFT6a_REENTRY([str])
	string str

	variable sweepNo
	string   key

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 20)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, 19)

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()
	CHECK_EQUAL_VAR(anaFuncTracker[PRE_DAQ_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[PRE_SET_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[PRE_SWEEP_CONFIG_EVENT], 20)
	CHECK_GE_VAR(anaFuncTracker[MID_SWEEP_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_SWEEP_EVENT], 20)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_SET_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_DAQ_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[GENERIC_EVENT], 0)

	WAVE/T textualValues = GetLBTextualValues(str)
	key = StringFromList(PRE_DAQ_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, NULL_WAVE)

	key = StringFromList(PRE_SET_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, NULL_WAVE)

	key = StringFromList(PRE_SWEEP_CONFIG_EVENT, EVENT_NAME_LIST_LBN)
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
// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function AFT6b([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG1"                        + \
	                             "__HS0_DA0_AD0_CM:IC:_ST:AnaFuncGeneric_DA_0:")
	AcquireData_NG(s, str)
End

static Function AFT6b_REENTRY([str])
	string str

	variable sweepNo
	string   key

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 20)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, 19)

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()
	CHECK_EQUAL_VAR(anaFuncTracker[PRE_DAQ_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[PRE_SET_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[PRE_SWEEP_CONFIG_EVENT], 20)
	CHECK_GE_VAR(anaFuncTracker[MID_SWEEP_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_SWEEP_EVENT], 20)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_SET_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_DAQ_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[GENERIC_EVENT], 0)

	WAVE/T textualValues = GetLBTextualValues(str)
	key = StringFromList(PRE_DAQ_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(anaFuncs, {"NotCalled_V1", "", "", "", "", "", "", "", ""})

	key = StringFromList(PRE_SET_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(anaFuncs, {"NotCalled_V1", "", "", "", "", "", "", "", ""})

	key = StringFromList(PRE_SWEEP_CONFIG_EVENT, EVENT_NAME_LIST_LBN)
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
// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function AFT7([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG1"                             + \
	                             "__HS0_DA0_AD0_CM:IC:_ST:AnaFuncValidMult_DA_0:" + \
	                             "__HS1_DA1_AD1_CM:IC:_ST:AnaFuncValidMult_DA_0:")
	AcquireData_NG(s, str)
End

static Function AFT7_REENTRY([str])
	string str

	variable sweepNo, i, numHeadstages
	string key

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 20)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, 19)

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()

	CHECK_EQUAL_VAR(anaFuncTracker[PRE_DAQ_EVENT][0], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[PRE_SET_EVENT][0], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[PRE_SWEEP_CONFIG_EVENT][0], 20)
	CHECK_GE_VAR(anaFuncTracker[MID_SWEEP_EVENT][0], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_SWEEP_EVENT][0], 20)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_SET_EVENT][0], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_DAQ_EVENT][0], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[GENERIC_EVENT][0], 0)

	CHECK_EQUAL_VAR(anaFuncTracker[PRE_DAQ_EVENT][1], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[PRE_SET_EVENT][1], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[PRE_SWEEP_CONFIG_EVENT][1], 20)
	CHECK_GE_VAR(anaFuncTracker[MID_SWEEP_EVENT][1], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_SWEEP_EVENT][1], 20)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_SET_EVENT][1], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_DAQ_EVENT][1], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[GENERIC_EVENT][1], 0)

	WAVE/T textualValues = GetLBTextualValues(str)
	key = StringFromList(PRE_DAQ_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(anaFuncs, {"ValidMultHS_V1", "ValidMultHS_V1", "", "", "", "", "", "", ""})

	key = StringFromList(PRE_SET_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(anaFuncs, {"ValidMultHS_V1", "ValidMultHS_V1", "", "", "", "", "", "", ""})

	key = StringFromList(PRE_SWEEP_CONFIG_EVENT, EVENT_NAME_LIST_LBN)
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
// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function AFT8([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG1"                         + \
	                             "__HS0_DA0_AD0_CM:IC:_ST:StimulusSetA_DA_0:" + \
	                             "__TTL0_ST:AnaFuncTTLNot_TTL_0:")
	AcquireData_NG(s, str)
End

static Function AFT8_REENTRY([str])
	string str

	variable sweepNo, i, numHeadstages
	string key

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 3)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, 2)

	WAVE/T textualValues = GetLBTextualValues(str)
	key = StringFromList(PRE_DAQ_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, NULL_WAVE)

	key = StringFromList(PRE_SET_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, NULL_WAVE)

	key = StringFromList(PRE_SWEEP_CONFIG_EVENT, EVENT_NAME_LIST_LBN)
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
// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function AFT9([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG1"                          + \
	                             "__HS0_DA0_AD0_CM:IC:_ST:AnaFuncValid3Lon_DA_0:")
	AcquireData_NG(s, str)
	CtrlNamedBackGround Abort_ITI_PressAcq, start=(ticks + 3), period=30, proc=StopAcq_IGNORE
End

static Function AFT9_REENTRY([str])
	string str

	variable sweepNo
	string   key

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 1)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, 0)

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()

	CHECK_EQUAL_VAR(anaFuncTracker[PRE_DAQ_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[PRE_SET_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[PRE_SWEEP_CONFIG_EVENT], 1)
	CHECK_GE_VAR(anaFuncTracker[MID_SWEEP_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_SWEEP_EVENT], 0)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_SET_EVENT], 0)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_DAQ_EVENT], 0)
	CHECK_EQUAL_VAR(anaFuncTracker[GENERIC_EVENT], 0)

	WAVE/T textualValues = GetLBTextualValues(str)
	key = StringFromList(GENERIC_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(anaFuncs, {"ValidFunc_V3", "", "", "", "", "", "", "", ""})
End

// DAQ works if the analysis function can not be found
// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function AFT10([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG1"                        + \
	                             "__HS0_DA0_AD0_CM:IC:_ST:AnaFuncMissing_DA_0:")
	AcquireData_NG(s, str)
End

static Function AFT10_REENTRY([str])
	string str

	variable sweepNo
	string   key

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 1)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, 0)

	WAVE/T textualValues = GetLBTextualValues(str)
	key = StringFromList(PRE_DAQ_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, NULL_WAVE)

	key = StringFromList(PRE_SET_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, NULL_WAVE)

	key = StringFromList(PRE_SWEEP_CONFIG_EVENT, EVENT_NAME_LIST_LBN)
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
// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function AFT11([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG1"                     + \
	                             "__HS0_DA0_AD0_CM:IC:_ST:AnaFuncDiff_DA_0:")
	AcquireData_NG(s, str)
End

static Function AFT11_REENTRY([str])
	string str

	variable sweepNo
	string   key

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 20)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, 19)

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()

	CHECK_EQUAL_VAR(anaFuncTracker[PRE_DAQ_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[PRE_SET_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[PRE_SWEEP_CONFIG_EVENT], 20)
	CHECK_GE_VAR(anaFuncTracker[MID_SWEEP_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_SWEEP_EVENT], 20)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_SET_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_DAQ_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[GENERIC_EVENT], 0)

	WAVE/T textualValues = GetLBTextualValues(str)
	key = StringFromList(PRE_DAQ_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(anaFuncs, {"preDAQ", "", "", "", "", "", "", "", ""})

	key = StringFromList(PRE_SET_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(anaFuncs, {"preSet", "", "", "", "", "", "", "", ""})

	key = StringFromList(PRE_SWEEP_CONFIG_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(anaFuncs, {"preSweepConfig", "", "", "", "", "", "", "", ""})

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
// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function AFT12([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG1_FAR0"                       + \
	                             "__HS0_DA0_AD0_CM:IC:_ST:AnaFuncAbortPre_DA_0:" + \
	                             "__HS1_DA1_AD1_CM:IC:_ST:AnaFuncAbortPre_DA_0:")

	try
		AcquireData_NG(s, str); AbortOnRTE
		FAIL()
	catch
		PASS()
	endtry
End

static Function AFT12_REENTRY([str])
	string str

	variable sweepNo
	string   key

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 0)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, NaN)

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()

	CHECK_EQUAL_VAR(anaFuncTracker[PRE_DAQ_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[PRE_SET_EVENT], 0)
	CHECK_EQUAL_VAR(anaFuncTracker[PRE_SWEEP_CONFIG_EVENT], 0)
	CHECK_EQUAL_VAR(anaFuncTracker[MID_SWEEP_EVENT], 0)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_SWEEP_EVENT], 0)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_SET_EVENT], 0)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_DAQ_EVENT], 0)
	CHECK_EQUAL_VAR(anaFuncTracker[GENERIC_EVENT], 0)

	WAVE/T textualValues = GetLBTextualValues(str)

	key = StringFromList(PRE_DAQ_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, NULL_WAVE)

	key = StringFromList(PRE_SET_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, NULL_WAVE)

	key = StringFromList(PRE_SWEEP_CONFIG_EVENT, EVENT_NAME_LIST_LBN)
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
// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function AFT13([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG1"                           + \
	                             "__HS0_DA0_AD0_CM:IC:_ST:AnaFuncStopMid_DA_0:" + \
	                             "__HS1_DA1_AD1_CM:IC:_ST:AnaFuncStopMid_DA_0:")
	AcquireData_NG(s, str)
End

static Function AFT13_REENTRY([str])
	string str

	variable sweepNo
	string   key

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 1)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, 0)

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()

	CHECK_EQUAL_VAR(anaFuncTracker[PRE_DAQ_EVENT], 0)
	CHECK_EQUAL_VAR(anaFuncTracker[PRE_SET_EVENT], 0)
	CHECK_EQUAL_VAR(anaFuncTracker[PRE_SWEEP_CONFIG_EVENT], 0)
	CHECK_EQUAL_VAR(anaFuncTracker[MID_SWEEP_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_SWEEP_EVENT], 0)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_SET_EVENT], 0)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_DAQ_EVENT], 0)
	CHECK_EQUAL_VAR(anaFuncTracker[GENERIC_EVENT], 0)

	WAVE/T textualValues = GetLBTextualValues(str)

	key = StringFromList(PRE_DAQ_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, NULL_WAVE)

	key = StringFromList(PRE_SET_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, NULL_WAVE)

	key = StringFromList(PRE_SWEEP_CONFIG_EVENT, EVENT_NAME_LIST_LBN)
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

static Function AFT14_PreInit(device)
	string device

	string stimSet = "AnaFuncParams1_DA_0"
	// use all lower case name for MyVar
	AFH_AddAnalysisParameter(stimSet, "myvar", str = "abcd")
	AFH_AddAnalysisParameter(stimSet, "MyStr", str = "abcd")
	AFH_AddAnalysisParameter(stimSet, "MyWave", wv = {1, 2, 3})
	Make/FREE/T textData = {"a", "b", "c"}
	AFH_AddAnalysisParameter(stimSet, "MyTextWave", wv = textData)
End

// test parameter handling
// tests also that no type parameters
// in Params1_V3_GetParams() are okay
// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function AFT14([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG1"                        + \
	                             "__HS0_DA0_AD0_CM:IC:_ST:AnaFuncParams1_DA_0:")
	AcquireData_NG(s, str)
End

static Function AFT14_REENTRY([str])
	string str

	variable sweepNo
	string   key

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 1)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, 0)

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()

	CHECK_EQUAL_VAR(anaFuncTracker[PRE_DAQ_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[PRE_SET_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[PRE_SWEEP_CONFIG_EVENT], 1)
	CHECK_GE_VAR(anaFuncTracker[MID_SWEEP_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_SWEEP_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_SET_EVENT], 0)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_DAQ_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[GENERIC_EVENT], 0)

	WAVE/T textualValues = GetLBTextualValues(str)

	key = StringFromList(PRE_DAQ_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, NULL_WAVE)

	key = StringFromList(PRE_SET_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, NULL_WAVE)

	key = StringFromList(PRE_SWEEP_CONFIG_EVENT, EVENT_NAME_LIST_LBN)
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

static Function AFT14a_PreInit(device)
	string device

	string stimSet = "AnaFuncParams2_DA_0"
	AFH_AddAnalysisParameter(stimSet, "MyStr", str = "abcd")
	AFH_AddAnalysisParameter(stimSet, "MyVar", str = "abcd")
End

// test parameter handling with valid type string and optional parameter
// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function AFT14a([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG1"                        + \
	                             "__HS0_DA0_AD0_CM:IC:_ST:AnaFuncParams2_DA_0:")
	AcquireData_NG(s, str)
End

static Function AFT14a_REENTRY([str])
	string str

	variable sweepNo
	string   key

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 1)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, 0)

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()

	CHECK_EQUAL_VAR(anaFuncTracker[PRE_DAQ_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[PRE_SET_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[PRE_SWEEP_CONFIG_EVENT], 1)
	CHECK_GE_VAR(anaFuncTracker[MID_SWEEP_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_SWEEP_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_SET_EVENT], 0)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_DAQ_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[GENERIC_EVENT], 0)
End

static Function AFT14b_PreInit(device)
	string device

	string stimSet = "AnaFuncParams3_DA_0"
	AFH_AddAnalysisParameter(stimSet, "MyStr", str = "abcd")
End

// test parameter handling with non-matching type string
// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function AFT14b([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG1_FAR0"                   + \
	                             "__HS0_DA0_AD0_CM:IC:_ST:AnaFuncParams3_DA_0:")

	try
		AcquireData_NG(s, str); AbortOnRTE
		FAIL()
	catch
		PASS()
	endtry
End

static Function AFT14b_REENTRY([str])
	string str

	variable sweepNo
	string   key

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 0)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, NaN)

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()

	CHECK_EQUAL_VAR(anaFuncTracker[PRE_DAQ_EVENT], 0)
	CHECK_EQUAL_VAR(anaFuncTracker[PRE_SET_EVENT], 0)
	CHECK_EQUAL_VAR(anaFuncTracker[PRE_SWEEP_CONFIG_EVENT], 0)
	CHECK_GE_VAR(anaFuncTracker[MID_SWEEP_EVENT], 0)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_SWEEP_EVENT], 0)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_SET_EVENT], 0)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_DAQ_EVENT], 0)
	CHECK_EQUAL_VAR(anaFuncTracker[GENERIC_EVENT], 0)
End

static Function AFT14c_PreInit(device)
	string device

	string stimSet = "AnaFuncParams4_DA_0"
	AFH_AddAnalysisParameter(stimSet, "MyStr", str = "abcd")
End

// test parameter handling with invalid type string
// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function AFT14c([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG1_FAR0"                   + \
	                             "__HS0_DA0_AD0_CM:IC:_ST:AnaFuncParams4_DA_0:")

	try
		AcquireData_NG(s, str); AbortOnRTE
		FAIL()
	catch
		PASS()
	endtry
End

static Function AFT14c_REENTRY([str])
	string str

	variable sweepNo
	string   key

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 0)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, NaN)

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()

	CHECK_EQUAL_VAR(anaFuncTracker[PRE_DAQ_EVENT], 0)
	CHECK_EQUAL_VAR(anaFuncTracker[PRE_SET_EVENT], 0)
	CHECK_EQUAL_VAR(anaFuncTracker[PRE_SWEEP_CONFIG_EVENT], 0)
	CHECK_GE_VAR(anaFuncTracker[MID_SWEEP_EVENT], 0)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_SWEEP_EVENT], 0)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_SET_EVENT], 0)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_DAQ_EVENT], 0)
	CHECK_EQUAL_VAR(anaFuncTracker[GENERIC_EVENT], 0)
End

static Function AFT14d_PreInit(device)
	string device

	string stimSet = "AnaFuncParams5_DA_0"
	AFH_AddAnalysisParameter(stimSet, "MyStr", str = "INVALIDCONTENT")
	AFH_AddAnalysisParameter(stimSet, "MyNum", var = 123)
End

// test parameter handling with analysis parameter check and help function and
// non-passing check
// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function AFT14d([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG1_FAR0"                   + \
	                             "__HS0_DA0_AD0_CM:IC:_ST:AnaFuncParams5_DA_0:")

	try
		AcquireData_NG(s, str); AbortOnRTE
		FAIL()
	catch
		PASS()
	endtry
End

static Function AFT14d_REENTRY([str])
	string str

	variable sweepNo
	string   key

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 0)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, NaN)

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()

	CHECK_EQUAL_VAR(anaFuncTracker[PRE_DAQ_EVENT], 0)
	CHECK_EQUAL_VAR(anaFuncTracker[PRE_SET_EVENT], 0)
	CHECK_EQUAL_VAR(anaFuncTracker[PRE_SWEEP_CONFIG_EVENT], 0)
	CHECK_EQUAL_VAR(anaFuncTracker[MID_SWEEP_EVENT], 0)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_SWEEP_EVENT], 0)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_SET_EVENT], 0)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_DAQ_EVENT], 0)
	CHECK_EQUAL_VAR(anaFuncTracker[GENERIC_EVENT], 0)
End

static Function AFT14e_PreInit(device)
	string device

	string stimSet = "AnaFuncParams5_DA_0"
	AFH_AddAnalysisParameter(stimSet, "MyStr", str = "ValidContent")
	AFH_AddAnalysisParameter(stimSet, "MyNum", var = NaN)
End

// Test parameter handling with analysis parameter check and help function
// - Check asserts out on MyNum == NaN
// - Help also asserts out but that is silently ignored
// - Asserting out is equal to not passing the check function
// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function AFT14e([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG1_FAR0"                   + \
	                             "__HS0_DA0_AD0_CM:IC:_ST:AnaFuncParams5_DA_0:")

	try
		AcquireData_NG(s, str); AbortOnRTE
		FAIL()
	catch
		PASS()
	endtry
End

static Function AFT14e_REENTRY([str])
	string str

	variable sweepNo
	string   key

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 0)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, NaN)

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()

	CHECK_EQUAL_VAR(anaFuncTracker[PRE_DAQ_EVENT], 0)
	CHECK_EQUAL_VAR(anaFuncTracker[PRE_SET_EVENT], 0)
	CHECK_EQUAL_VAR(anaFuncTracker[PRE_SWEEP_CONFIG_EVENT], 0)
	CHECK_EQUAL_VAR(anaFuncTracker[MID_SWEEP_EVENT], 0)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_SWEEP_EVENT], 0)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_SET_EVENT], 0)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_DAQ_EVENT], 0)
	CHECK_EQUAL_VAR(anaFuncTracker[GENERIC_EVENT], 0)
End

static Function AFT14f_PreInit(device)
	string device

	string stimSet = "AnaFuncParams5_DA_0"
	AFH_AddAnalysisParameter(stimSet, "MyStr", str = "ValidContent")
	AFH_AddAnalysisParameter(stimSet, "MyNum", var = 1)
End

// test parameter handling with analysis parameter check and help function
// - Checks pass
// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function AFT14f([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG1"                        + \
	                             "__HS0_DA0_AD0_CM:IC:_ST:AnaFuncParams5_DA_0:")

	AcquireData_NG(s, str)
End

static Function AFT14f_REENTRY([str])
	string str

	variable sweepNo
	string   key

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 1)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, 0)

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()

	CHECK_EQUAL_VAR(anaFuncTracker[PRE_DAQ_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[PRE_SET_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[PRE_SWEEP_CONFIG_EVENT], 1)
	CHECK_GE_VAR(anaFuncTracker[MID_SWEEP_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_SWEEP_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_SET_EVENT], 0)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_DAQ_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[GENERIC_EVENT], 0)
End

static Function AFT14g_PreInit(device)
	string device

	string stimSet = "AnaFuncParams5_DA_0"
	AFH_AddAnalysisParameter(stimSet, "MyStr", str = "ValidContent")
End

// test parameter handling with analysis parameter check and help function
// - Checks pass, MyNum is not present and optional and is therefore not checked
//   (the check would assert out)
// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function AFT14g([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG1"                        + \
	                             "__HS0_DA0_AD0_CM:IC:_ST:AnaFuncParams5_DA_0:")

	AcquireData_NG(s, str)
End

static Function AFT14g_REENTRY([str])
	string str

	variable sweepNo
	string   key

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 1)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, 0)

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()

	CHECK_EQUAL_VAR(anaFuncTracker[PRE_DAQ_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[PRE_SET_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[PRE_SWEEP_CONFIG_EVENT], 1)
	CHECK_GE_VAR(anaFuncTracker[MID_SWEEP_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_SWEEP_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_SET_EVENT], 0)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_DAQ_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[GENERIC_EVENT], 0)
End

static Function AFT14h_PreInit(device)
	string device

	string stimSet = "AnaFuncParams6_DA_0"
	AFH_AddAnalysisParameter(stimSet, "MyStr", str = "ValidContent")
End

// test parameter handling with new analysis parameter check signature
// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function AFT14h([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG1"                        + \
	                             "__HS0_DA0_AD0_CM:IC:_ST:AnaFuncParams6_DA_0:")

	AcquireData_NG(s, str)
End

static Function AFT14h_REENTRY([str])
	string str

	variable sweepNo
	string   key

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 1)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, 0)

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()

	CHECK_EQUAL_VAR(anaFuncTracker[PRE_DAQ_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[PRE_SET_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[PRE_SWEEP_CONFIG_EVENT], 1)
	CHECK_GE_VAR(anaFuncTracker[MID_SWEEP_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_SWEEP_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_SET_EVENT], 0)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_DAQ_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[GENERIC_EVENT], 0)
End

static Function AFT14i_PreInit(device)
	string device

	string stimSet = "AnaFuncParams7_DA_0"
	AFH_AddAnalysisParameter(stimSet, "MyVar", var = 1)
End

// parameter MyVar is neither required nor optional as no _GetParams is present but still checked
// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function AFT14i([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG1_FAR0"                   + \
	                             "__HS0_DA0_AD0_CM:IC:_ST:AnaFuncParams7_DA_0:")

	try
		AcquireData_NG(s, str)
		FAIL()
	catch
		PASS()
	endtry
End

static Function AFT14j_PreInit(device)
	string device

	string stimSet = "AnaFuncParams1_DA_0"
	AFH_AddAnalysisParameter(stimSet, "MyVar", str = "abcd")
	AFH_AddAnalysisParameter(stimSet, "MyStr", str = "abcd")
	AFH_AddAnalysisParameter(stimSet, "MyWave", wv = {1, 2, 3})
	Make/FREE/T textData = {"a", "b", "c"}
	AFH_AddAnalysisParameter(stimSet, "MyTextWave", wv = textData)

	AFH_AddAnalysisParameter(stimSet, "UnknownVar", var = 0)
End

// parameter MyVar is present but neither required nor optional and we have a _GetParams function
// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function AFT14j([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG1_FAR0"                   + \
	                             "__HS0_DA0_AD0_CM:IC:_ST:AnaFuncParams1_DA_0:")

	try
		AcquireData_NG(s, str)
		FAIL()
	catch
		PASS()
	endtry
End

// MD: mid sweep event is also called for very short stimsets
// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function AFT15([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG1_ITP0"                     + \
	                             "__HS0_DA0_AD0_CM:IC:_ST:AnaFuncVeryShort_DA_0:")

	AcquireData_NG(s, str)
End

static Function AFT15_REENTRY([str])
	string str

	variable sweepNo
	string   key

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 1)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, 0)

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()

	CHECK_EQUAL_VAR(anaFuncTracker[PRE_DAQ_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[PRE_SET_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[PRE_SWEEP_CONFIG_EVENT], 1)
	CHECK_GE_VAR(anaFuncTracker[MID_SWEEP_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_SWEEP_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_SET_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_DAQ_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[GENERIC_EVENT], 0)
End

// SD: mid sweep event is also called for very short stimsets
// UTF_TD_GENERATOR DeviceNameGeneratorMD0
static Function AFT16([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD0_RA0_I0_L0_BKG1_ITP0"                     + \
	                             "__HS0_DA0_AD0_CM:IC:_ST:AnaFuncVeryShort_DA_0:")

	AcquireData_NG(s, str)
End

static Function AFT16_REENTRY([str])
	string str

	variable sweepNo
	string   key

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 1)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, 0)

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()

	CHECK_EQUAL_VAR(anaFuncTracker[PRE_DAQ_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[PRE_SET_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[PRE_SWEEP_CONFIG_EVENT], 1)
	CHECK_GE_VAR(anaFuncTracker[MID_SWEEP_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_SWEEP_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_SET_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_DAQ_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[GENERIC_EVENT], 0)
End

// Calling Abort during pre DAQ event will prevent DAQ
// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function AFT17([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD0_RA0_I0_L0_BKG1_FAR0"                     + \
	                             "__HS0_DA0_AD0_CM:IC:_ST:AnaFuncPreDAQHar_DA_0:")

	try
		AcquireData_NG(s, str); AbortOnRTE
		FAIL()
	catch
		PASS()
		NVAR errorCounter = $GetAnalysisFuncErrorCounter(str)
		CHECK_EQUAL_VAR(errorCounter, 1)
		errorCounter = 0 // avoid TEST_CASE_END_OVERRIDE() complaining
	endtry
End

static Function AFT17_REENTRY([str])
	string str

	variable sweepNo
	string   key

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 0)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, NaN)

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()

	CHECK_EQUAL_VAR(anaFuncTracker[PRE_DAQ_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[PRE_SET_EVENT], 0)
	CHECK_EQUAL_VAR(anaFuncTracker[PRE_SWEEP_CONFIG_EVENT], 0)
	CHECK_EQUAL_VAR(anaFuncTracker[MID_SWEEP_EVENT], 0)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_SWEEP_EVENT], 0)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_SET_EVENT], 0)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_DAQ_EVENT], 0)
	CHECK_EQUAL_VAR(anaFuncTracker[GENERIC_EVENT], 0)
End

// Analysis functions work properly with indexing
// We index from AnaFuncIdx1_DA_0 to AnaFuncIdx2_DA_0
// but only the second one has a analysis function set
// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function AFT18([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I1_L0_BKG1_RES2"                                      + \
	                             "__HS0_DA0_AD0_CM:IC:_ST:AnaFuncIdx1_DA_0:_IST:AnaFuncIdx2_DA_0:")

	AcquireData_NG(s, str)
End

static Function AFT18_REENTRY([str])
	string str

	variable sweepNo
	string   key

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 4)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, 3)

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()

	CHECK_EQUAL_VAR(anaFuncTracker[PRE_DAQ_EVENT], 0)
	CHECK_EQUAL_VAR(anaFuncTracker[PRE_SET_EVENT], 2)
	CHECK_EQUAL_VAR(anaFuncTracker[PRE_SWEEP_CONFIG_EVENT], 2)
	CHECK_GE_VAR(anaFuncTracker[MID_SWEEP_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_SWEEP_EVENT], 2)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_SET_EVENT], 2)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_DAQ_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[GENERIC_EVENT], 0)

	// analysis function storage was must be correct
	// even after indexing
	WAVE analysisFunctions = GetAnalysisFunctionStorage(str)
	Duplicate/FREE analysisFunctions, analysisFunctionsBefore

	AFM_UpdateAnalysisFunctionWave(str)

	WAVE analysisFunctionsAfter = GetAnalysisFunctionStorage(str)
	CHECK_EQUAL_WAVES(analysisFunctionsBefore, analysisFunctionsAfter)
End

// check that pre-set-event can abort
// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function AFT19([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG1"                          + \
	                             "__HS0_DA0_AD0_CM:IC:_ST:AnaFuncPreSetHar_DA_0:")

	AcquireData_NG(s, str)
End

static Function AFT19_REENTRY([str])
	string str

	variable sweepNo
	string   key

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 0)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, NaN)

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()

	CHECK_EQUAL_VAR(anaFuncTracker[PRE_DAQ_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[PRE_SET_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[PRE_SWEEP_CONFIG_EVENT], 0)
	CHECK_EQUAL_VAR(anaFuncTracker[MID_SWEEP_EVENT], 0)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_SWEEP_EVENT], 0)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_SET_EVENT], 0)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_DAQ_EVENT], 0)
	CHECK_EQUAL_VAR(anaFuncTracker[GENERIC_EVENT], 0)
End

// check that pre sweep config can abort
// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function AFT19a([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG1"                         + \
	                             "__HS0_DA0_AD0_CM:IC:_ST:AnaFuncPreSwCfg_DA_0:")

	AcquireData_NG(s, str)
End

static Function AFT19a_REENTRY([str])
	string str

	variable sweepNo
	string   key

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 0)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, NaN)

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()

	CHECK_EQUAL_VAR(anaFuncTracker[PRE_DAQ_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[PRE_SET_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[PRE_SWEEP_CONFIG_EVENT], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[MID_SWEEP_EVENT], 0)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_SWEEP_EVENT], 0)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_SET_EVENT], 0)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_DAQ_EVENT], 0)
	CHECK_EQUAL_VAR(anaFuncTracker[GENERIC_EVENT], 0)
End

// check total ordering of events via timestamps
// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function AFT20([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG1"                      + \
	                             "__HS0_DA0_AD0_CM:IC:_ST:AnaFuncOrder_DA_0:")

	AcquireData_NG(s, str)
End

static Function AFT20_REENTRY([str])
	string str

	variable sweepNo

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 1)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, 0)

	WAVE anaFuncOrder = TrackAnalysisFunctionOrder()

	Make/FREE indexWave = {PRE_DAQ_EVENT, PRE_SET_EVENT, PRE_SWEEP_CONFIG_EVENT, MID_SWEEP_EVENT, POST_SWEEP_EVENT, POST_SET_EVENT, POST_DAQ_EVENT}
	Make/FREE/N=(DimSize(indexWave, ROWS)) anaFuncOrderIndex = anaFuncOrder[indexWave[p]]

	Duplicate/FREE anaFuncOrderIndex, anaFuncOrderSorted
	Sort anaFuncOrderSorted, anaFuncOrderSorted

	CHECK_EQUAL_WAVES(anaFuncOrderIndex, anaFuncOrderSorted)
End

// it possible to change the stimset in POST DAQ event
// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function AFT21([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG1"                        + \
	                             "__HS0_DA0_AD0_CM:IC:_ST:AnaFuncPostDAQ_DA_0:")

	AcquireData_NG(s, str)
End

static Function AFT21_REENTRY([str])
	string str

	variable sweepNo
	string stimset, expected

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 1)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, 0)

	WAVE/T   textualValues = GetLBTextualValues(str)
	WAVE/T/Z foundStimSets = GetLastSetting(textualValues, sweepNo, STIM_WAVE_NAME_KEY, DATA_ACQUISITION_MODE)

	REQUIRE_WAVE(foundStimSets, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(foundStimSets, {"AnaFuncPostDAQ_DA_0", "", "", "", "", "", "", "", ""})

	stimset  = AFH_GetStimSetName(str, 0, CHANNEL_TYPE_DAC)
	expected = "StimulusSetA_DA_0"
	REQUIRE_EQUAL_STR(stimset, expected)
End

// POST_SET_EVENT works with only HS1 active
// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function AFT22([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG1"                          + \
	                             "__HS1_DA1_AD1_CM:IC:_ST:AnaFuncValidMult_DA_0:")

	AcquireData_NG(s, str)
End

static Function AFT22_REENTRY([str])
	string str

	variable sweepNo
	string   key

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 20)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, 19)

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()

	CHECK_EQUAL_VAR(anaFuncTracker[PRE_DAQ_EVENT][1], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[PRE_SET_EVENT][1], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[PRE_SWEEP_CONFIG_EVENT][1], 20)
	CHECK_GE_VAR(anaFuncTracker[MID_SWEEP_EVENT][1], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_SWEEP_EVENT][1], 20)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_SET_EVENT][1], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[POST_DAQ_EVENT][1], 1)
	CHECK_EQUAL_VAR(anaFuncTracker[GENERIC_EVENT][1], 0)

	WAVE/T textualValues = GetLBTextualValues(str)
	key = StringFromList(PRE_DAQ_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(anaFuncs, {"", "ValidMultHS_V1", "", "", "", "", "", "", ""})

	key = StringFromList(PRE_SET_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(anaFuncs, {"", "ValidMultHS_V1", "", "", "", "", "", "", ""})

	key = StringFromList(PRE_SWEEP_CONFIG_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(anaFuncs, {"", "ValidMultHS_V1", "", "", "", "", "", "", ""})

	key = StringFromList(MID_SWEEP_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(anaFuncs, {"", "ValidMultHS_V1", "", "", "", "", "", "", ""})

	key = StringFromList(POST_SWEEP_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(anaFuncs, {"", "ValidMultHS_V1", "", "", "", "", "", "", ""})

	key = StringFromList(POST_SET_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(anaFuncs, {"", "ValidMultHS_V1", "", "", "", "", "", "", ""})

	key = StringFromList(POST_DAQ_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(anaFuncs, {"", "ValidMultHS_V1", "", "", "", "", "", "", ""})

	key = StringFromList(GENERIC_EVENT, EVENT_NAME_LIST_LBN)
	WAVE/T/Z anaFuncs = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(anaFuncs, NULL_WAVE)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function CanModifyStimsetInPreSweepConfig([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG1"                        + \
	                             "__HS0_DA0_AD0_CM:IC:_ST:AnaFuncModStim_DA_0:")

	AcquireData_NG(s, str)
End

static Function CanModifyStimsetInPreSweepConfig_REENTRY([str])
	string str

	variable sweepNo, var
	string key, stimset

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 2)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, 1)

	// stimset has modified duration
	stimset = "AnaFuncModStim_DA_0"
	var     = ST_GetStimsetParameterAsVariable(stimset, "Duration", epochIndex = 0)
	CHECK_EQUAL_VAR(var, 6)

	// and the stimset checksum is different for both sweeps
	WAVE numericalValues = GetLBNumericalValues(str)

	WAVE/Z settings = GetLastSettingEachRAC(numericalValues, sweepNo, "Stim Wave Checksum", 0, DATA_ACQUISITION_MODE)
	CHECK_WAVE(settings, NUMERIC_WAVE)
	CHECK_EQUAL_VAR(DimSize(settings, ROWS), 2)

	WAVE/Z settingsUnique = GetUniqueEntries(settings)
	CHECK_EQUAL_WAVES(settings, settingsUnique)

	// and both sweeps have a different stimset cycle ID
	WAVE/Z settings = GetLastSettingEachRAC(numericalValues, sweepNo, STIMSET_ACQ_CYCLE_ID_KEY, 0, DATA_ACQUISITION_MODE)
	CHECK_WAVE(settings, NUMERIC_WAVE)
	CHECK_EQUAL_VAR(DimSize(settings, ROWS), 2)

	WAVE/Z settingsUnique = GetUniqueEntries(settings)
	CHECK_EQUAL_WAVES(settings, settingsUnique)
End
