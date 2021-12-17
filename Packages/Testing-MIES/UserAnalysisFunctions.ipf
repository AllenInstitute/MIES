#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma version=10000

#ifndef AUTOMATED_TESTING

	#define **error** Can only be used with automated testing
#endif

Function CorrectFileMarker()

	FAIL()
End

Function InvalidSignature()

	FAIL()
End

Function/WAVE InvalidSignatureAndReturnType()

	FAIL()
End

Function/WAVE InvalidReturnTypeAndValidSig_V1(device, eventType, DAQDataWave, headStage)
	string device
	variable eventType
	Wave DAQDataWave
	variable headstage

	FAIL()
End

Function/WAVE InvalidReturnTypeAndValidSig_V2(device, eventType, DAQDataWave, headStage, realDataLength)
	string device
	variable eventType
	Wave DAQDataWave
	variable headstage, realDataLength

	FAIL()
End

Function ValidFunc_V1(device, eventType, DAQDataWave, headStage)
	string device
	variable eventType
	Wave DAQDataWave
	variable headstage

	CHECK_NON_EMPTY_STR(device)
	CHECK_EQUAL_VAR(numType(eventType), 0)

	switch(GetHardwareType(device))
		case HARDWARE_ITC_DAC:
			CHECK_WAVE(DAQDataWave, NUMERIC_WAVE)
			break
		case HARDWARE_NI_DAC:
			CHECK_WAVE(DAQDataWave, WAVE_WAVE)
			break
	endswitch

	CHECK_EQUAL_VAR(NumberByKey("LOCK", WaveInfo(DAQDataWave, 0)), 1)
	CHECK_EQUAL_VAR(headstage, 0)

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()

	CHECK_GE_VAR(eventType, 0)
	CHECK_LT_VAR(eventType, DimSize(anaFuncTracker, ROWS))
	anaFuncTracker[eventType] += 1
End

Function ValidFunc_V2(device, eventType, DAQDataWave, headStage, realDataLength)
	string device
	variable eventType
	Wave DAQDataWave
	variable headstage, realDataLength

	CHECK_NON_EMPTY_STR(device)
	CHECK_EQUAL_VAR(numType(eventType), 0)

	switch(GetHardwareType(device))
		case HARDWARE_ITC_DAC:
			CHECK_WAVE(DAQDataWave, NUMERIC_WAVE)
			break
		case HARDWARE_NI_DAC:
			CHECK_WAVE(DAQDataWave, WAVE_WAVE)
			break
	endswitch

	CHECK_EQUAL_VAR(NumberByKey("LOCK", WaveInfo(DAQDataWave, 0)), 1)
	CHECK_EQUAL_VAR(headstage, 0)

	if(eventType == PRE_DAQ_EVENT || eventType == PRE_SET_EVENT || eventType == PRE_SWEEP_CONFIG_EVENT)
		CHECK_EQUAL_VAR(numType(realDataLength), 2)
	elseif(GetHardWareType(device) == HARDWARE_ITC_DAC)
		CHECK_GE_VAR(realDataLength, 0)
		CHECK_LT_VAR(realDataLength, DimSize(DAQDataWave, ROWS))
	elseif(GetHardWareType(device) == HARDWARE_NI_DAC)
		WAVE/WAVE DAQDataWaveRef = DAQDataWave
		Make/FREE/N=(DimSize(DAQDataWaveRef, ROWS)) sizes = DimSize(DAQDataWaveRef[p], ROWS)
		CHECK_GE_VAR(realDataLength, 0)
		CHECK_LE_VAR(realDataLength, WaveMax(sizes))
	else
		FAIL()
	endif

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()

	CHECK_GE_VAR(eventType, 0)
	CHECK_LT_VAR(eventType, DimSize(anaFuncTracker, ROWS))
	anaFuncTracker[eventType] += 1
End

Function ValidMultHS_V1(device, eventType, DAQDataWave, headStage)
	string device
	variable eventType
	Wave DAQDataWave
	variable headstage

	CHECK_NON_EMPTY_STR(device)
	CHECK_EQUAL_VAR(numType(eventType), 0)

	switch(GetHardwareType(device))
		case HARDWARE_ITC_DAC:
			CHECK_WAVE(DAQDataWave, NUMERIC_WAVE)
			break
		case HARDWARE_NI_DAC:
			CHECK_WAVE(DAQDataWave, WAVE_WAVE)
			break
	endswitch

	CHECK_EQUAL_VAR(NumberByKey("LOCK", WaveInfo(DAQDataWave, 0)), 1)

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()

	CHECK_GE_VAR(eventType, 0)
	CHECK_LT_VAR(eventType, DimSize(anaFuncTracker, ROWS))
	anaFuncTracker[eventType][headstage] += 1
End

Function NotCalled_V1(device, eventType, DAQDataWave, headStage)
	string device
	variable eventType
	Wave DAQDataWave
	variable headstage

	FAIL()
End

Function preDAQHardAbort(device, eventType, DAQDataWave, headStage, realDataLength)
	string device
	variable eventType
	Wave DAQDataWave
	variable headstage, realDataLength

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()

	CHECK_GE_VAR(eventType, 0)
	CHECK_LT_VAR(eventType, DimSize(anaFuncTracker, ROWS))
	anaFuncTracker[eventType][headstage] += 1

	if(eventType == PRE_DAQ_EVENT)
		Abort
	endif
End

Function preDAQ(device, eventType, DAQDataWave, headStage, realDataLength)
	string device
	variable eventType
	Wave DAQDataWave
	variable headstage, realDataLength

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()

	CHECK_GE_VAR(eventType, 0)
	CHECK_LT_VAR(eventType, DimSize(anaFuncTracker, ROWS))
	anaFuncTracker[eventType][headstage] += 1
End

Function preSet(device, eventType, DAQDataWave, headStage, realDataLength)
	string device
	variable eventType
	Wave DAQDataWave
	variable headstage, realDataLength

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()

	CHECK_GE_VAR(eventType, 0)
	CHECK_LT_VAR(eventType, DimSize(anaFuncTracker, ROWS))
	anaFuncTracker[eventType][headstage] += 1
End

Function preSweepConfig(device, eventType, DAQDataWave, headStage, realDataLength)
	string device
	variable eventType
	Wave DAQDataWave
	variable headstage, realDataLength

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()

	CHECK_GE_VAR(eventType, 0)
	CHECK_LT_VAR(eventType, DimSize(anaFuncTracker, ROWS))
	anaFuncTracker[eventType][headstage] += 1
End

Function midSweep(device, eventType, DAQDataWave, headStage, realDataLength)
	string device
	variable eventType
	Wave DAQDataWave
	variable headstage, realDataLength

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()

	CHECK_GE_VAR(eventType, 0)
	CHECK_LT_VAR(eventType, DimSize(anaFuncTracker, ROWS))
	anaFuncTracker[eventType][headstage] += 1
End

Function postSweep(device, eventType, DAQDataWave, headStage, realDataLength)
	string device
	variable eventType
	Wave DAQDataWave
	variable headstage, realDataLength

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()

	CHECK_GE_VAR(eventType, 0)
	CHECK_LT_VAR(eventType, DimSize(anaFuncTracker, ROWS))
	anaFuncTracker[eventType][headstage] += 1
End

Function postSet(device, eventType, DAQDataWave, headStage, realDataLength)
	string device
	variable eventType
	Wave DAQDataWave
	variable headstage, realDataLength

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()

	CHECK_GE_VAR(eventType, 0)
	CHECK_LT_VAR(eventType, DimSize(anaFuncTracker, ROWS))
	anaFuncTracker[eventType][headstage] += 1
End

Function postDAQ(device, eventType, DAQDataWave, headStage, realDataLength)
	string device
	variable eventType
	Wave DAQDataWave
	variable headstage, realDataLength

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()

	CHECK_GE_VAR(eventType, 0)
	CHECK_LT_VAR(eventType, DimSize(anaFuncTracker, ROWS))
	anaFuncTracker[eventType][headstage] += 1
End

Function AbortPreDAQ(device, eventType, DAQDataWave, headStage, realDataLength)
	string device
	variable eventType
	Wave DAQDataWave
	variable headstage, realDataLength

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()

	CHECK_GE_VAR(eventType, 0)
	CHECK_LT_VAR(eventType, DimSize(anaFuncTracker, ROWS))
	anaFuncTracker[eventType][headstage] += 1

	// prevents DAQ
	return 1
End

Function StopPreSweepConfig_V3(device, s)
	string device
	STRUCT AnalysisFunction_V3& s

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()

	CHECK_GE_VAR(s.eventType, 0)
	CHECK_LT_VAR(s.eventType, DimSize(anaFuncTracker, ROWS))
	anaFuncTracker[s.eventType][s.headstage] += 1

	if(s.eventType == PRE_SWEEP_CONFIG_EVENT)
		return 1
	endif

	return NaN
End

Function StopMidSweep(device, eventType, DAQDataWave, headStage, realDataLength)
	string device
	variable eventType
	Wave DAQDataWave
	variable headstage, realDataLength

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()

	CHECK_GE_VAR(eventType, 0)
	CHECK_LT_VAR(eventType, DimSize(anaFuncTracker, ROWS))
	anaFuncTracker[eventType][headstage] += 1

	return ANALYSIS_FUNC_RET_REPURP_TIME
End

Function ValidFunc_V3(device, s)
	string device
	STRUCT AnalysisFunction_V3& s

	variable hardwareType

	hardwareType = GetHardwareType(device)

	CHECK_NON_EMPTY_STR(device)

	switch(hardwareType)
		case HARDWARE_ITC_DAC:
			CHECK_WAVE(s.rawDACWave, NUMERIC_WAVE)
			break
		case HARDWARE_NI_DAC:
			CHECK_WAVE(s.rawDACWave, WAVE_WAVE)
			break
	endswitch

	CHECK_WAVE(s.scaledDACWave, NUMERIC_WAVE, minorType = FLOAT_WAVE)

	if(s.eventType != PRE_DAQ_EVENT && s.eventType != PRE_SET_EVENT && s.eventType != PRE_SWEEP_CONFIG_EVENT && s.eventType != POST_DAQ_EVENT)
		switch(hardwareType)
			case HARDWARE_ITC_DAC:
				CHECK_EQUAL_VAR(DimSize(s.scaledDACWave, COLS), DimSize(s.rawDACWave, COLS))
				CHECK_LE_VAR(DimSize(s.scaledDACWave, ROWS), DimSize(s.rawDACWave, ROWS))
				break
			case HARDWARE_NI_DAC:
				CHECK_EQUAL_VAR(DimSize(s.scaledDACWave, COLS), DimSize(s.rawDACWave, ROWS))
				WAVE/WAVE rawDACWaveRef = s.rawDACWave
				Make/FREE/N=(DimSize(rawDACWaveRef, ROWS)) sizes = DimSize(rawDACWaveRef[p], ROWS)
				CHECK_LE_VAR(DimSize(s.scaledDACWave, ROWS), WaveMax(sizes))
				break
			default:
				FAIL()
		endswitch
	endif

	CHECK_EQUAL_VAR(NumberByKey("LOCK", WaveInfo(s.scaledDACWAVE, 0)), 1)
	CHECK_EQUAL_VAR(NumberByKey("LOCK", WaveInfo(s.rawDACWAVE, 0)), 1)
	CHECK_EQUAL_VAR(s.headstage, 0)
	CHECK_EQUAL_VAR(numType(s.sweepNo), 0)
	CHECK_EQUAL_VAR(numType(s.sweepsInSet), 0)
	CHECK_EQUAL_VAR(strlen(s.params), 0)

	if(s.eventType == PRE_DAQ_EVENT || s.eventType == PRE_SET_EVENT || s.eventType == PRE_SWEEP_CONFIG_EVENT)
		CHECK_EQUAL_VAR(numType(s.lastValidRowIndex), 2)
		CHECK_EQUAL_VAR(numType(s.lastKnownRowIndex), 2)
	elseif(s.eventType == MID_SWEEP_EVENT)
		switch(hardwareType)
			case HARDWARE_ITC_DAC:
				CHECK_GE_VAR(s.lastValidRowIndex, 0)
				CHECK_LT_VAR(s.lastValidRowIndex, DimSize(s.rawDACWave, ROWS))
				break
			case HARDWARE_NI_DAC:
				WAVE/WAVE rawDACWaveRef = s.rawDACWave
				Make/FREE/N=(DimSize(rawDACWaveRef, ROWS)) sizes = DimSize(rawDACWaveRef[p], ROWS)
				CHECK_GE_VAR(s.lastValidRowIndex, 0)
				CHECK_LT_VAR(s.lastValidRowIndex, WaveMax(sizes))
				CHECK_GE_VAR(s.lastKnownRowIndex, 0)
				CHECK_LT_VAR(s.lastKnownRowIndex, WaveMax(sizes))
				break
			default:
				FAIL()
		endswitch
	elseif(s.eventType == POST_DAQ_EVENT || s.eventType == POST_SET_EVENT || s.eventType == POST_SWEEP_EVENT)
		WAVE/Z sweepWave = GetSweepWave(device, s.sweepNo)
		CHECK_WAVE(sweepWave, NUMERIC_WAVE)
		CHECK_EQUAL_VAR(DimSize(sweepWave, ROWS) - 1, s.lastValidRowIndex)
		CHECK_EQUAL_VAR(DimSize(sweepWave, ROWS) - 1, s.lastKnownRowIndex)
	else
		FAIL()
	endif

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()

	// check sweep number
	switch(s.eventType)
		case PRE_DAQ_EVENT:
			CHECK_EQUAL_VAR(s.sweepNo, 0)
			CHECK_WAVE(GetSweepWave(device, s.sweepNo), NULL_WAVE)
			break
		case PRE_SWEEP_CONFIG_EVENT:
		case PRE_SET_EVENT:
		case MID_SWEEP_EVENT:
			CHECK_EQUAL_VAR(s.sweepNo, anaFuncTracker[POST_SWEEP_EVENT])
			CHECK_WAVE(GetSweepWave(device, s.sweepNo), NULL_WAVE)
			break
		case POST_SWEEP_EVENT:
			CHECK_EQUAL_VAR(s.sweepNo, anaFuncTracker[POST_SWEEP_EVENT])
			CHECK_WAVE(GetSweepWave(device, s.sweepNo), NUMERIC_WAVE)
			break
		case POST_SET_EVENT:
			CHECK_EQUAL_VAR(s.sweepNo, anaFuncTracker[POST_SWEEP_EVENT] - 1)
			CHECK_WAVE(GetSweepWave(device, s.sweepNo), NUMERIC_WAVE)
			break
		case POST_DAQ_EVENT:
			CHECK_EQUAL_VAR(s.sweepNo, anaFuncTracker[POST_SWEEP_EVENT] - 1)
			CHECK_WAVE(GetSweepWave(device, s.sweepNo), NUMERIC_WAVE)
			break
	endswitch

	// the next sweep can not exist
	CHECK_WAVE(GetSweepWave(device, s.sweepNo + 1), NULL_WAVE)

	CHECK_GE_VAR(s.eventType, 0)
	CHECK_LT_VAR(s.eventType, TOTAL_NUM_EVENTS)
	CHECK(s.eventType != GENERIC_EVENT)
	CHECK_GE_VAR(s.eventType, 0)
	CHECK_LT_VAR(s.eventType, DimSize(anaFuncTracker, ROWS))
	anaFuncTracker[s.eventType] += 1
End

Function/S Params1_V3_GetParams()
	return "MyStr,MyVar,MyWave,MyTextWave"
End

Function Params1_V3(device, s)
	string device
	STRUCT AnalysisFunction_V3& s

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()

	CHECK_GE_VAR(s.eventType, 0)
	CHECK_LT_VAR(s.eventType, TOTAL_NUM_EVENTS)
	CHECK(s.eventType != GENERIC_EVENT)
	CHECK_GE_VAR(s.eventType, 0)
	CHECK_LT_VAR(s.eventType, DimSize(anaFuncTracker, ROWS))
	anaFuncTracker[s.eventType] += 1
End

Function/S Params2_V3_GetParams()
	return "MyStr:string,MyVar,[OptionalParam]"
End

Function Params2_V3(device, s)
	string device
	STRUCT AnalysisFunction_V3& s

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()

	CHECK_GE_VAR(s.eventType, 0)
	CHECK_LT_VAR(s.eventType, TOTAL_NUM_EVENTS)
	CHECK(s.eventType != GENERIC_EVENT)
	CHECK_GE_VAR(s.eventType, 0)
	CHECK_LT_VAR(s.eventType, DimSize(anaFuncTracker, ROWS))
	anaFuncTracker[s.eventType] += 1
End

Function/S Params3_V3_GetParams()
	return "MyStr:invalidType"
End

Function Params3_V3(device, s)
	string device
	STRUCT AnalysisFunction_V3& s

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()

	CHECK_GE_VAR(s.eventType, 0)
	CHECK_LT_VAR(s.eventType, TOTAL_NUM_EVENTS)
	CHECK(s.eventType != GENERIC_EVENT)
	CHECK_GE_VAR(s.eventType, 0)
	CHECK_LT_VAR(s.eventType, DimSize(anaFuncTracker, ROWS))
	anaFuncTracker[s.eventType] += 1
End

Function/S Params4_V3_GetParams()
	return "MyStr:variable" // wrong type
End

Function Params4_V3(device, s)
	string device
	STRUCT AnalysisFunction_V3& s

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()

	CHECK_GE_VAR(s.eventType, 0)
	CHECK_LT_VAR(s.eventType, TOTAL_NUM_EVENTS)
	CHECK(s.eventType != GENERIC_EVENT)
	CHECK_GE_VAR(s.eventType, 0)
	CHECK_LT_VAR(s.eventType, DimSize(anaFuncTracker, ROWS))
	anaFuncTracker[s.eventType] += 1
End

Function/S Params5_V3_CheckParam(name, params)
	string name, params

	string str
	variable var

	strswitch(name)
		case "MyStr":
			str = AFH_GetAnalysisParamTextual(name, params)
			if(!cmpstr(str, "INVALIDCONTENT"))
				return "Nope that is not valid content"
			endif
			break
		case "MyNum":
			var = AFH_GetAnalysisParamNumerical(name, params)
			if(!IsFinite(var))
				ASSERT(0, "trying to bug out")
			endif
		default:
			// default to passing for other parameters
			return ""
			break
	endswitch

	return ""
End

Function/S Params5_V3_GetHelp(string name)
	string str

	strswitch(name)
		case "MyStr":
			return "That is actually a useless parameter"
		case "MyNum":
			ASSERT(0, "trying to bug out")
			break
	endswitch

	return ""
End

Function/S Params5_V3_GetParams()
	return "MyStr:string,[MyNum:variable]"
End

Function Params5_V3(device, s)
	string device
	STRUCT AnalysisFunction_V3& s

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()

	CHECK_GE_VAR(s.eventType, 0)
	CHECK_LT_VAR(s.eventType, TOTAL_NUM_EVENTS)
	CHECK(s.eventType != GENERIC_EVENT)
	CHECK_GE_VAR(s.eventType, 0)
	CHECK_LT_VAR(s.eventType, DimSize(anaFuncTracker, ROWS))
	anaFuncTracker[s.eventType] += 1
End

Function/S Params6_V3_CheckParam(string name, STRUCT CheckParametersStruct &s)
	string expected, actual

	strswitch(name)
		case "MyStr":
			expected = "AnaFuncParams6_DA_0"
			actual   = s.setName
			CHECK_EQUAL_STR(expected, actual)
			WAVE/Z stimset = WB_CreateAndGetStimSet(s.setName)
			CHECK_WAVE(stimset, NUMERIC_WAVE)
			break
		default:
			FAIL()
			break
	endswitch

	return ""
End

Function/S Params6_V3_GetParams()
	return "MyStr:string"
End

Function Params6_V3(device, s)
	string device
	STRUCT AnalysisFunction_V3& s

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()

	CHECK_GE_VAR(s.eventType, 0)
	CHECK_LT_VAR(s.eventType, TOTAL_NUM_EVENTS)
	CHECK(s.eventType != GENERIC_EVENT)
	CHECK_GE_VAR(s.eventType, 0)
	CHECK_LT_VAR(s.eventType, DimSize(anaFuncTracker, ROWS))
	anaFuncTracker[s.eventType] += 1
End

Function ChangeToSingleDeviceDAQAF(device, eventType, DAQDataWave, headStage, realDataLength)
	string device
	variable eventType
	Wave DAQDataWave
	variable headstage, realDataLength

	PGC_SetAndActivateControl(device, "check_Settings_MD", val = CHECKBOX_UNSELECTED)
	return 0
End

Function ChangeToMultiDeviceDAQAF(device, eventType, DAQDataWave, headStage, realDataLength)
	string device
	variable eventType
	Wave DAQDataWave
	variable headstage, realDataLength

	PGC_SetAndActivateControl(device, "check_Settings_MD", val = CHECKBOX_SELECTED)
	return 0
End

Function Indexing_V3(device, s)
	string device
	STRUCT AnalysisFunction_V3& s

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()

	CHECK_GE_VAR(s.eventType, 0)
	CHECK_LT_VAR(s.eventType, TOTAL_NUM_EVENTS)
	CHECK(s.eventType != GENERIC_EVENT)
	CHECK_GE_VAR(s.eventType, 0)
	CHECK_LT_VAR(s.eventType, DimSize(anaFuncTracker, ROWS))
	anaFuncTracker[s.eventType] += 1
End

Function TrackSweepCount_V3(device, s)
	string device
	STRUCT AnalysisFunction_V3& s

	WAVE anaFuncSweepCounts = GetTrackSweepCounts()

	CHECK_GE_VAR(s.eventType, 0)
	CHECK_LT_VAR(s.eventType, TOTAL_NUM_EVENTS)
	CHECK(s.eventType != GENERIC_EVENT)
	CHECK_GE_VAR(s.sweepNo, 0)
	CHECK_LT_VAR(s.sweepNo, DimSize(anaFuncSweepCounts, ROWS))
	CHECK_GE_VAR(s.eventType, 0)
	CHECK_LT_VAR(s.eventType, DimSize(anaFuncSweepCounts, COLS))
	CHECK_GE_VAR(s.headstage, 0)
	CHECK_LT_VAR(s.headstage, DimSize(anaFuncSweepCounts, LAYERS))

	if(s.eventType == MID_SWEEP_EVENT)
		// don't check that here
		return 0
	endif

	NVAR count = $GetCount(device)
	anaFuncSweepCounts[s.sweepNo][s.eventType][s.headstage] = count
End

Function AbortPreSet(device, s)
	string device
	STRUCT AnalysisFunction_V3& s

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()

	CHECK_GE_VAR(s.eventType, 0)
	CHECK_LT_VAR(s.eventType, DimSize(anaFuncTracker, ROWS))
	anaFuncTracker[s.eventType][s.headstage] += 1

	if(s.eventType == PRE_SET_EVENT)
		// aborts DAQ
		return 1
	else
		return 0
	endif
End

Function TotalOrdering(device, s)
	string device
	STRUCT AnalysisFunction_V3& s

	WAVE anaFuncOrder = TrackAnalysisFunctionOrder()

	CHECK_GE_VAR(s.eventType, 0)
	CHECK_LT_VAR(s.eventType, DimSize(anaFuncOrder, ROWS))

	Sleep/T 2
	anaFuncOrder[s.eventType][s.headstage] = ticks
End

Function TrackActiveSetCount(device, s)
	string device
	STRUCT AnalysisFunction_V3& s

	if(s.eventType != PRE_SWEEP_CONFIG_EVENT)
		return NaN
	endif

	WAVE anaFuncActiveSetCount = GetTrackActiveSetCount()

	NVAR activeSetCount = $GetActiveSetCount(device)
	anaFuncActiveSetCount[s.sweepNo][s.headstage] = activeSetCount
End

Function SkipSweeps(device, s)
	string device
	STRUCT AnalysisFunction_V3& s

	variable skipCountExisting

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()

	CHECK_GE_VAR(s.eventType, 0)
	CHECK_LT_VAR(s.eventType, DimSize(anaFuncTracker, ROWS))
	anaFuncTracker[s.eventType][s.headstage] += 1

	// we want to trigger that RA_DocumentSweepSkipping reads back the current value
	// of SKIP_SWEEPS_KEY and uses that as basis
	// therefore we call it twice: Once during mid sweep with +1 and then after the sweep with inf
	if(s.eventType == MID_SWEEP_EVENT)
		WAVE numericalValues = GetLBNumericalValues(device)
		skipCountExisting = GetLastSettingIndep(numericalValues, s.sweepNo, SKIP_SWEEPS_KEY, UNKNOWN_MODE)

		if(IsNaN(skipCountExisting))
			RA_SkipSweeps(device, 1, limitToSetBorder = 1, document = 1)
		endif
	elseif(s.eventType == POST_SWEEP_EVENT)
		RA_SkipSweeps(device, inf, limitToSetBorder = 1, document = 1)
	endif
End

Function SkipSweepsAdvanced(device, s)
	string device
	STRUCT AnalysisFunction_V3& s

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()

	CHECK_GE_VAR(s.eventType, 0)
	CHECK_LT_VAR(s.eventType, DimSize(anaFuncTracker, ROWS))
	anaFuncTracker[s.eventType][s.headstage] += 1

	if(s.eventType != POST_SWEEP_EVENT)
		return NaN
	endif

	WAVE anaFuncActiveSetCount = GetTrackActiveSetCount()

	NVAR activeSetCount = $GetActiveSetCount(device)
	anaFuncActiveSetCount[s.sweepNo][s.headstage] = activeSetCount

	// sweeps in stimset: 0, 1, 2
	// we acquire: 0, 0, 2, 2
	if(s.sweepNo == 0)
		// repeat first sweep
		RA_SkipSweeps(device, -10)
	elseif(s.sweepNo == 1)
		// skip one forward
		RA_SkipSweeps(device, 1, limitToSetBorder = 1)
	elseif(s.sweepNo == 2)
		// and repeat the last one
		RA_SkipSweeps(device, -1)
	endif
End

Function TrackActiveSetCountsAndEvents(device, s)
	string device
	STRUCT AnalysisFunction_V3& s

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()

	CHECK_GE_VAR(s.eventType, 0)
	CHECK_LT_VAR(s.eventType, DimSize(anaFuncTracker, ROWS))
	anaFuncTracker[s.eventType][s.headstage] += 1

	WAVE anaFuncActiveSetCount = GetTrackActiveSetCount()

	NVAR activeSetCount = $GetActiveSetCount(device)
	anaFuncActiveSetCount[s.sweepNo][s.headstage] = activeSetCount
End

Function WriteIntoLBNOnPreDAQ(device, s)
	string device
	STRUCT AnalysisFunction_V3& s

	if(s.eventType == PRE_DAQ_EVENT)
		Make/FREE/N=(LABNOTEBOOK_LAYER_COUNT) values = p
		values[INDEP_HEADSTAGE] = NaN
		ED_AddEntryToLabnotebook(device, "GARBAGE", values, overrideSweepNo = s.sweepNo)
	endif

	return 0
End

Function ChangeStimSet(device, s)
	string device
	STRUCT AnalysisFunction_V3& s

	string ctrl

	if(s.eventType == POST_DAQ_EVENT)
		ctrl = GetPanelControl(0, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE)
		PGC_SeTAndActivateControl(device, ctrl, str = "StimulusSetA_DA_0")
	endif

	return 0
End

Function IncrementalLabnotebookUpdate(device, s)
	string device
	STRUCT AnalysisFunction_V3& s

	if(s.eventType == POST_SWEEP_EVENT)
		ILCUCheck_IGNORE(device, s)
	endif

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()

	CHECK_GE_VAR(s.eventType, 0)
	CHECK_LT_VAR(s.eventType, DimSize(anaFuncTracker, ROWS))
	anaFuncTracker[s.eventType][s.headstage] += 1

	return 0
End

Function SweepRollbackChecker(device, s)
	string device
	STRUCT AnalysisFunction_V3& s

	string list, refList

	if(s.eventType == PRE_DAQ_EVENT)
		DFREF dfr = GetDeviceDataPath(device)
		list    = SortList(GetListOfObjects(dfr, ".*"))
		refList = SortList("Config_Sweep_0;Sweep_0;")
		CHECK_EQUAL_STR(refList, list)
	endif

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()

	CHECK_GE_VAR(s.eventType, 0)
	CHECK_LT_VAR(s.eventType, DimSize(anaFuncTracker, ROWS))
	anaFuncTracker[s.eventType][s.headstage] += 1

	return 0
End

Function AcquisitionStateTrackingFunc(device, s)
	string device
	STRUCT AnalysisFunction_V3& s

	variable acqState, expectedAcqState
	string name

	acqState = ROVAR(GetAcquisitionState(device))

	Make/D/FREE/N=(LABNOTEBOOK_LAYER_COUNT) values     = NaN
	Make/T/FREE/N=(LABNOTEBOOK_LAYER_COUNT) valuesText = ""

	switch(s.eventType)
		case PRE_DAQ_EVENT:
			expectedAcqState = AS_PRE_DAQ
			break
		case PRE_SET_EVENT:
			// AS_POST_SET does not yet exist
			if(s.sweepNo > 0)
				expectedAcqState = AS_ITI
			else
				expectedAcqState = AS_PRE_DAQ
			endif
			break
		case PRE_SWEEP_CONFIG_EVENT:
			expectedAcqState = AS_PRE_SWEEP_CONFIG
			break
		case MID_SWEEP_EVENT:
			expectedAcqState = AS_MID_SWEEP
			break
		case POST_SWEEP_EVENT:
		case POST_SET_EVENT:
			// AS_POST_SET does not yet exist
			expectedAcqState = AS_POST_SWEEP
			break
		case POST_DAQ_EVENT:
			expectedAcqState = AS_POST_DAQ
			break
		default:
			ASSERT(0, "Invalid event")
	endswitch

	name = "AcqStateTrackingValue_" + AS_StateToString(acqState)

	CHECK_EQUAL_VAR(s.sweepNo, AS_GetSweepNumber(device))

	CHECK_EQUAL_VAR(acqState, expectedAcqState)
	values[s.headstage] = expectedAcqState
	ED_AddEntryToLabnotebook(device, name, values, overrideSweepNo = s.sweepNo)
	valuesText[s.headstage] = AS_StateToString(expectedAcqState)
	ED_AddEntryToLabnotebook(device, name, valuesText, overrideSweepNo = s.sweepNo)

	return 0
End

Function ModifyStimSet(string device, STRUCT AnalysisFunction_V3& s)

	string stimset
	variable var

	stimset = "AnaFuncModStim_DA_0"

	switch(s.eventType)
		case PRE_SWEEP_CONFIG_EVENT:
			if(s.sweepNo == 1)
				var = ST_GetStimsetParameterAsVariable(stimset, "Duration", epochIndex = 0)
				CHECK_EQUAL_VAR(5, var)
				ST_SetStimsetParameter("AnaFuncModStim_DA_0", "Duration", epochIndex = 0, var = var + 1)
			endif
			break
	endswitch

	return 0
End

Function StopMidSweep_V3(string device, STRUCT AnalysisFunction_V3& s)

	switch(s.eventType)
		case MID_SWEEP_EVENT:
			return ANALYSIS_FUNC_RET_EARLY_STOP
	endswitch

	return 0
End

Function AddUserEpoch_V3(string device, STRUCT AnalysisFunction_V3& s)
	variable DAC
	string tags

	DAC = AFH_GetDACFromHeadstage(device, s.headstage)

	sprintf tags, "HS=%d;eventType=%d;", s.headstage, s.eventType
	EP_AddUserEpoch(device, XOP_CHANNEL_TYPE_DAC, DAC, 0.5, 0.6, tags)
End

Function ChangeTPSettings(device, s)
	string device
	STRUCT AnalysisFunction_V3& s

	switch(s.eventType)
		case POST_SWEEP_EVENT:
			if(s.sweepNo == 1)
				PGC_SetAndActivateControl(device, "slider_DataAcq_ActiveHeadstage", val = 0)
				PGC_SetAndActivateControl(device, "SetVar_DataAcq_TPAmplitudeIC", val = -80)

				PGC_SetAndActivateControl(device, "slider_DataAcq_ActiveHeadstage", val = 1)
				PGC_SetAndActivateControl(device, "SetVar_DataAcq_TPAmplitude", val = 40)
			endif
			break
		case PRE_SWEEP_CONFIG_EVENT:
			if(s.sweepNo == 2)
				PGC_SetAndActivateControl(device, "slider_DataAcq_ActiveHeadstage", val = 0)

				PGC_SetAndActivateControl(device, "SetVar_DataAcq_TPAmplitudeIC", val = -90)
				PGC_SetAndActivateControl(device, "SetVar_DataAcq_TPAmplitude", val = 50)
			endif
			break
		default:
			// do nothing
	endswitch
End
