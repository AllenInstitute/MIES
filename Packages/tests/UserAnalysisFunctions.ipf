#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors = 1
#pragma version          = 10000

#ifndef AUTOMATED_TESTING

#define **error** Can only be used with automated testing
#endif // !AUTOMATED_TESTING

Function CorrectFileMarker()

	FAIL()
End

Function InvalidSignature()

	FAIL()
End

Function/WAVE InvalidSignatureAndReturnType()

	FAIL()
End

Function/WAVE InvalidReturnTypeAndValidSig_V1(string device, variable eventType, WAVE DAQDataWave, variable headStage)

	FAIL()
End

Function/WAVE InvalidReturnTypeAndValidSig_V2(string device, variable eventType, WAVE DAQDataWave, variable headStage, variable realDataLength)

	FAIL()
End

Function ValidFunc_V1(string device, variable eventType, WAVE DAQDataWave, variable headStage)

	CHECK_NON_EMPTY_STR(device)
	CHECK_EQUAL_VAR(numType(eventType), 0)

	switch(GetHardwareType(device))
		case HARDWARE_ITC_DAC:
			CHECK_WAVE(DAQDataWave, NUMERIC_WAVE)
			break
		case HARDWARE_NI_DAC:
			CHECK_WAVE(DAQDataWave, WAVE_WAVE)
			break
		default:
			FATAL_ERROR("Unsupported hardware type")
	endswitch

#ifdef TESTS_WITH_SUTTER_HARDWARE
	CHECK_EQUAL_VAR(NumberByKey("LOCK", WaveInfo(DAQDataWave, 0)), 0)
#else
	CHECK_EQUAL_VAR(NumberByKey("LOCK", WaveInfo(DAQDataWave, 0)), 1)
#endif // TESTS_WITH_SUTTER_HARDWARE
	CHECK_EQUAL_VAR(headstage, 0)

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()

	CHECK_GE_VAR(eventType, 0)
	CHECK_LT_VAR(eventType, DimSize(anaFuncTracker, ROWS))
	anaFuncTracker[eventType] += 1
End

Function ValidFunc_V2(string device, variable eventType, WAVE DAQDataWave, variable headStage, variable realDataLength)

	variable hardwareType

	CHECK_NON_EMPTY_STR(device)
	CHECK_EQUAL_VAR(numType(eventType), 0)

	switch(GetHardwareType(device))
		case HARDWARE_ITC_DAC:
			CHECK_WAVE(DAQDataWave, NUMERIC_WAVE)
			break
		case HARDWARE_NI_DAC:
			CHECK_WAVE(DAQDataWave, WAVE_WAVE)
			break
		default:
			FATAL_ERROR("Unsupported hardware type")
	endswitch

#ifdef TESTS_WITH_SUTTER_HARDWARE
	CHECK_EQUAL_VAR(NumberByKey("LOCK", WaveInfo(DAQDataWave, 0)), 0)
#else
	CHECK_EQUAL_VAR(NumberByKey("LOCK", WaveInfo(DAQDataWave, 0)), 1)
#endif // TESTS_WITH_SUTTER_HARDWARE
	CHECK_EQUAL_VAR(headstage, 0)

	hardwareType = GetHardWareType(device)
	if(eventType == PRE_DAQ_EVENT || eventType == PRE_SET_EVENT || eventType == PRE_SWEEP_CONFIG_EVENT)
		CHECK_EQUAL_VAR(numType(realDataLength), 2)
	elseif(hardwareType == HARDWARE_ITC_DAC)
		CHECK_GE_VAR(realDataLength, 0)
		CHECK_LT_VAR(realDataLength, DimSize(DAQDataWave, ROWS))
	elseif(hardwareType == HARDWARE_NI_DAC || hardwareType == HARDWARE_SUTTER_DAC)
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

Function ValidMultHS_V1(string device, variable eventType, WAVE DAQDataWave, variable headStage)

	CHECK_NON_EMPTY_STR(device)
	CHECK_EQUAL_VAR(numType(eventType), 0)

	switch(GetHardwareType(device))
		case HARDWARE_ITC_DAC:
			CHECK_WAVE(DAQDataWave, NUMERIC_WAVE)
			break
		case HARDWARE_NI_DAC: // intended drop-through
		case HARDWARE_SUTTER_DAC:
			CHECK_WAVE(DAQDataWave, WAVE_WAVE)
			break
		default:
			FATAL_ERROR("Unsupported hardware type")
	endswitch

#ifdef TESTS_WITH_SUTTER_HARDWARE
	CHECK_EQUAL_VAR(NumberByKey("LOCK", WaveInfo(DAQDataWave, 0)), 0)
#else
	CHECK_EQUAL_VAR(NumberByKey("LOCK", WaveInfo(DAQDataWave, 0)), 1)
#endif // TESTS_WITH_SUTTER_HARDWARE
	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()

	CHECK_GE_VAR(eventType, 0)
	CHECK_LT_VAR(eventType, DimSize(anaFuncTracker, ROWS))
	anaFuncTracker[eventType][headstage] += 1
End

Function NotCalled_V1(string device, variable eventType, WAVE DAQDataWave, variable headStage)

	FAIL()
End

Function preDAQHardAbort(string device, variable eventType, WAVE DAQDataWave, variable headStage, variable realDataLength)

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()

	CHECK_GE_VAR(eventType, 0)
	CHECK_LT_VAR(eventType, DimSize(anaFuncTracker, ROWS))
	anaFuncTracker[eventType][headstage] += 1

	if(eventType == PRE_DAQ_EVENT)
		Abort
	endif
End

Function preDAQ(string device, variable eventType, WAVE DAQDataWave, variable headStage, variable realDataLength)

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()

	CHECK_GE_VAR(eventType, 0)
	CHECK_LT_VAR(eventType, DimSize(anaFuncTracker, ROWS))
	anaFuncTracker[eventType][headstage] += 1
End

Function preSet(string device, variable eventType, WAVE DAQDataWave, variable headStage, variable realDataLength)

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()

	CHECK_GE_VAR(eventType, 0)
	CHECK_LT_VAR(eventType, DimSize(anaFuncTracker, ROWS))
	anaFuncTracker[eventType][headstage] += 1
End

Function preSweepConfig(string device, variable eventType, WAVE DAQDataWave, variable headStage, variable realDataLength)

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()

	CHECK_GE_VAR(eventType, 0)
	CHECK_LT_VAR(eventType, DimSize(anaFuncTracker, ROWS))
	anaFuncTracker[eventType][headstage] += 1
End

Function midSweep(string device, variable eventType, WAVE DAQDataWave, variable headStage, variable realDataLength)

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()

	CHECK_GE_VAR(eventType, 0)
	CHECK_LT_VAR(eventType, DimSize(anaFuncTracker, ROWS))
	anaFuncTracker[eventType][headstage] += 1
End

Function postSweep(string device, variable eventType, WAVE DAQDataWave, variable headStage, variable realDataLength)

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()

	CHECK_GE_VAR(eventType, 0)
	CHECK_LT_VAR(eventType, DimSize(anaFuncTracker, ROWS))
	anaFuncTracker[eventType][headstage] += 1
End

Function postSet(string device, variable eventType, WAVE DAQDataWave, variable headStage, variable realDataLength)

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()

	CHECK_GE_VAR(eventType, 0)
	CHECK_LT_VAR(eventType, DimSize(anaFuncTracker, ROWS))
	anaFuncTracker[eventType][headstage] += 1
End

Function postDAQ(string device, variable eventType, WAVE DAQDataWave, variable headStage, variable realDataLength)

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()

	CHECK_GE_VAR(eventType, 0)
	CHECK_LT_VAR(eventType, DimSize(anaFuncTracker, ROWS))
	anaFuncTracker[eventType][headstage] += 1
End

Function AbortPreDAQ(string device, variable eventType, WAVE DAQDataWave, variable headStage, variable realDataLength)

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()

	CHECK_GE_VAR(eventType, 0)
	CHECK_LT_VAR(eventType, DimSize(anaFuncTracker, ROWS))
	anaFuncTracker[eventType][headstage] += 1

	// prevents DAQ
	return 1
End

Function StopPreSweepConfig_V3(string device, STRUCT AnalysisFunction_V3 &s)

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()

	CHECK_GE_VAR(s.eventType, 0)
	CHECK_LT_VAR(s.eventType, DimSize(anaFuncTracker, ROWS))
	anaFuncTracker[s.eventType][s.headstage] += 1

	if(s.eventType == PRE_SWEEP_CONFIG_EVENT)
		return 1
	endif

	return NaN
End

Function StopMidSweep(string device, variable eventType, WAVE DAQDataWave, variable headStage, variable realDataLength)

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()

	CHECK_GE_VAR(eventType, 0)
	CHECK_LT_VAR(eventType, DimSize(anaFuncTracker, ROWS))
	anaFuncTracker[eventType][headstage] += 1

	return ANALYSIS_FUNC_RET_REPURP_TIME
End

Function ValidFunc_V3(string device, STRUCT AnalysisFunction_V3 &s)

	variable hardwareType, i

	hardwareType = GetHardwareType(device)

	CHECK_NON_EMPTY_STR(device)

	if(WaveExists(s.scaledDACWave))
		if(IsTextWave(s.scaledDACWave))
			WAVE channelDA = ResolveSweepChannel(s.scaledDACWave, 0)
			CHECK_WAVE(channelDA, NUMERIC_WAVE, minorType = FLOAT_WAVE)
		elseif(IsWaveRefWave(s.scaledDACWave))
			WAVE/WAVE scaledDACWaveRef = s.scaledDACWave
			WAVE      channelDA        = scaledDACWaveRef[0]
			CHECK_WAVE(channelDA, NUMERIC_WAVE, minorType = FLOAT_WAVE)
		else
			INFO("Unknown data format")
			FAIL()
		endif
	endif

	if(s.eventType != PRE_DAQ_EVENT && s.eventType != PRE_SET_EVENT && s.eventType != PRE_SWEEP_CONFIG_EVENT && s.eventType != POST_DAQ_EVENT)
		switch(hardwareType)
			case HARDWARE_ITC_DAC:
				WAVE DAQDataWave = GetDAQDataWave(device, DATA_ACQUISITION_MODE)
				CHECK_EQUAL_VAR(DimSize(s.scaledDACWave, ROWS), DimSize(DAQDataWave, COLS))
				if(IsTextWave(s.scaledDACWave))
					for(string notused : s.scaledDACWave)
						CHECK_LE_VAR(DimSize(ResolveSweepChannel(s.scaledDACWave, i), ROWS), DimSize(DAQDataWave, ROWS))
						i += 1
					endfor
				elseif(IsWaveRefWave(s.scaledDACWave))
					for(WAVE channel : scaledDACWaveRef)
						CHECK_LE_VAR(DimSize(channel, ROWS), DimSize(DAQDataWave, ROWS))
					endfor
				endif
				break
			case HARDWARE_NI_DAC: // intended drop through
			case HARDWARE_SUTTER_DAC:
				WAVE/WAVE DAQDataWaveRef = GetDAQDataWave(device, DATA_ACQUISITION_MODE)
				CHECK_EQUAL_VAR(DimSize(s.scaledDACWave, ROWS), DimSize(DAQDataWaveRef, ROWS))
				Make/FREE/N=(DimSize(DAQDataWaveRef, ROWS)) sizesDAQ = DimSize(DAQDataWaveRef[p], ROWS)
				if(IsTextWave(s.scaledDACWave))
					Make/FREE/N=(DimSize(s.scaledDACWave, ROWS)) sizesScaled = DimSize(ResolveSweepChannel(s.scaledDACWave, p), ROWS)
				elseif(IsWaveRefWave(s.scaledDACWave))
					WAVE/WAVE scaledDACWaveRef = s.scaledDACWave
					Make/FREE/N=(DimSize(scaledDACWaveRef, ROWS)) sizesScaled = DimSize(scaledDACWaveRef[p], ROWS)
				endif
				CHECK_EQUAL_WAVES(sizesDAQ, sizesScaled, mode = WAVE_DATA)
				break
			default:
				FAIL()
		endswitch
	elseif(s.eventType == POST_DAQ_EVENT)
		if(!(IsTextWave(s.scaledDACWave) || IsWaveRefWave(s.scaledDACWave)))
			FAIL()
		endif
	else
		CHECK_WAVE(s.scaledDACWave, NULL_WAVE)
	endif

	if(WaveExists(s.scaledDACWave))
		CHECK_EQUAL_VAR(NumberByKey("LOCK", WaveInfo(s.scaledDACWAVE, 0)), 1)
	endif
	CHECK_EQUAL_VAR(s.headstage, 0)
	CHECK_EQUAL_VAR(numType(s.sweepNo), 0)
	CHECK_EQUAL_VAR(numType(s.sweepsInSet), 0)
	CHECK_EQUAL_VAR(strlen(s.params), 0)

	if(s.eventType == PRE_DAQ_EVENT || s.eventType == PRE_SET_EVENT || s.eventType == PRE_SWEEP_CONFIG_EVENT)
		CHECK_EQUAL_VAR(s.lastValidRowIndexAD, NaN)
		CHECK_EQUAL_VAR(s.lastKnownRowIndexAD, NaN)
		CHECK_EQUAL_VAR(s.lastValidRowIndexDA, NaN)
		CHECK_EQUAL_VAR(s.lastKnownRowIndexDA, NaN)
		CHECK_EQUAL_VAR(s.sampleIntervalDA, NaN)
		CHECK_EQUAL_VAR(s.sampleIntervalAD, NaN)

	elseif(s.eventType == MID_SWEEP_EVENT)
		switch(hardwareType)
			case HARDWARE_ITC_DAC:
				WAVE DAQDataWave = GetDAQDataWave(device, DATA_ACQUISITION_MODE)
				CHECK_GE_VAR(s.lastValidRowIndexDA, 0)
				CHECK_LT_VAR(s.lastValidRowIndexDA, DimSize(DAQDataWave, ROWS))
				CHECK_GE_VAR(s.lastValidRowIndexAD, 0)
				CHECK_LT_VAR(s.lastValidRowIndexAD, DimSize(DAQDataWave, ROWS))
				CHECK_GE_VAR(s.lastKnownRowIndexDA, 0)
				CHECK_LT_VAR(s.lastKnownRowIndexDA, DimSize(DAQDataWave, ROWS))
				CHECK_GE_VAR(s.lastKnownRowIndexAD, 0)
				CHECK_LT_VAR(s.lastKnownRowIndexAD, DimSize(DAQDataWave, ROWS))
				CHECK_EQUAL_VAR(s.sampleIntervalDA, DimDelta(DAQDataWave, ROWS))
				CHECK_EQUAL_VAR(s.sampleIntervalAD, DimDelta(DAQDataWave, ROWS))
				break
			case HARDWARE_NI_DAC: // intended drop-through
			case HARDWARE_SUTTER_DAC:
				WAVE/WAVE DAQDataWaveRef = GetDAQDataWave(device, DATA_ACQUISITION_MODE)
				Make/FREE/N=(DimSize(DAQDataWaveRef, ROWS)) sizes = DimSize(DAQDataWaveRef[p], ROWS)
				CHECK_GE_VAR(s.lastValidRowIndexAD, 0)
				CHECK_LT_VAR(s.lastValidRowIndexAD, WaveMax(sizes))
				CHECK_GE_VAR(s.lastKnownRowIndexAD, 0)
				CHECK_LT_VAR(s.lastKnownRowIndexAD, WaveMax(sizes))
				CHECK_GE_VAR(s.lastValidRowIndexDA, 0)
				CHECK_LT_VAR(s.lastValidRowIndexDA, WaveMax(sizes))
				CHECK_GE_VAR(s.lastKnownRowIndexDA, 0)
				CHECK_LT_VAR(s.lastKnownRowIndexDA, WaveMax(sizes))
				CHECK_GT_VAR(s.sampleIntervalDA, 0)
				CHECK_GT_VAR(s.sampleIntervalAD, 0)
				break
			default:
				FAIL()
		endswitch
	elseif(s.eventType == POST_DAQ_EVENT || s.eventType == POST_SET_EVENT || s.eventType == POST_SWEEP_EVENT)
		WAVE/Z sweepWave = GetSweepWave(device, s.sweepNo)
		CHECK_WAVE(sweepWave, TEXT_WAVE)
		CHECK_GT_VAR(DimSize(sweepWave, ROWS), 0)
		WAVE channel = ResolveSweepChannel(sweepWave, 0)
		CHECK_EQUAL_VAR(DimSize(channel, ROWS) - 1, s.lastValidRowIndexDA)
		CHECK_EQUAL_VAR(DimSize(channel, ROWS) - 1, s.lastKnownRowIndexDA)
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
			CHECK_WAVE(GetSweepWave(device, s.sweepNo), TEXT_WAVE)
			break
		case POST_SET_EVENT:
			CHECK_EQUAL_VAR(s.sweepNo, anaFuncTracker[POST_SWEEP_EVENT] - 1)
			CHECK_WAVE(GetSweepWave(device, s.sweepNo), TEXT_WAVE)
			break
		case POST_DAQ_EVENT:
			CHECK_EQUAL_VAR(s.sweepNo, anaFuncTracker[POST_SWEEP_EVENT] - 1)
			CHECK_WAVE(GetSweepWave(device, s.sweepNo), TEXT_WAVE)
			break
		default:
			FATAL_ERROR("Unsupported hardware type")
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

Function Params1_V3(string device, STRUCT AnalysisFunction_V3 &s)

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

Function Params2_V3(string device, STRUCT AnalysisFunction_V3 &s)

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

Function Params3_V3(string device, STRUCT AnalysisFunction_V3 &s)

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

Function Params4_V3(string device, STRUCT AnalysisFunction_V3 &s)

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()

	CHECK_GE_VAR(s.eventType, 0)
	CHECK_LT_VAR(s.eventType, TOTAL_NUM_EVENTS)
	CHECK(s.eventType != GENERIC_EVENT)
	CHECK_GE_VAR(s.eventType, 0)
	CHECK_LT_VAR(s.eventType, DimSize(anaFuncTracker, ROWS))
	anaFuncTracker[s.eventType] += 1
End

Function/S Params5_V3_CheckParam(string name, string params)

	string   str
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
				FATAL_ERROR("trying to bug out")
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
			FATAL_ERROR("trying to bug out")
			break
		default:
			return ""
	endswitch
End

Function/S Params5_V3_GetParams()

	return "MyStr:string,[MyNum:variable]"
End

Function Params5_V3(string device, STRUCT AnalysisFunction_V3 &s)

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

Function Params6_V3(string device, STRUCT AnalysisFunction_V3 &s)

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()

	CHECK_GE_VAR(s.eventType, 0)
	CHECK_LT_VAR(s.eventType, TOTAL_NUM_EVENTS)
	CHECK(s.eventType != GENERIC_EVENT)
	CHECK_GE_VAR(s.eventType, 0)
	CHECK_LT_VAR(s.eventType, DimSize(anaFuncTracker, ROWS))
	anaFuncTracker[s.eventType] += 1
End

Function/S Params7_V3_CheckParam(string name, STRUCT CheckParametersStruct &s)

	variable var

	strswitch(name)
		case "MyVar":
			return "Encountered expected check"
		default:
			FAIL()
	endswitch

	return ""
End

// Params7_V3_GetParams is not present

Function Params7_V3(string device, STRUCT AnalysisFunction_V3 &s)

	return NaN
End

Function ChangeToOtherDeviceDAQAF(string device, variable eventType, WAVE DAQDataWave, variable headStage, variable realDataLength)

	PGC_SetAndActivateControl(device, "check_Settings_MD", val = !GetCheckBoxState(device, "check_Settings_MD"))
	return 0
End

Function Indexing_V3(string device, STRUCT AnalysisFunction_V3 &s)

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()

	CHECK_GE_VAR(s.eventType, 0)
	CHECK_LT_VAR(s.eventType, TOTAL_NUM_EVENTS)
	CHECK(s.eventType != GENERIC_EVENT)
	CHECK_GE_VAR(s.eventType, 0)
	CHECK_LT_VAR(s.eventType, DimSize(anaFuncTracker, ROWS))
	anaFuncTracker[s.eventType] += 1
End

Function TrackSweepCount_V3(string device, STRUCT AnalysisFunction_V3 &s)

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

Function AbortPreSet(string device, STRUCT AnalysisFunction_V3 &s)

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()

	CHECK_GE_VAR(s.eventType, 0)
	CHECK_LT_VAR(s.eventType, DimSize(anaFuncTracker, ROWS))
	anaFuncTracker[s.eventType][s.headstage] += 1

	if(s.eventType == PRE_SET_EVENT)
		// aborts DAQ
		return 1
	endif

	return 0
End

Function TotalOrdering(string device, STRUCT AnalysisFunction_V3 &s)

	WAVE anaFuncOrder = TrackAnalysisFunctionOrder()

	CHECK_GE_VAR(s.eventType, 0)
	CHECK_LT_VAR(s.eventType, DimSize(anaFuncOrder, ROWS))

	Sleep/T 2
	anaFuncOrder[s.eventType][s.headstage] = ticks
End

Function TrackActiveSetCount(string device, STRUCT AnalysisFunction_V3 &s)

	if(s.eventType != PRE_SWEEP_CONFIG_EVENT)
		return NaN
	endif

	WAVE anaFuncActiveSetCount = GetTrackActiveSetCount()

	NVAR activeSetCount = $GetActiveSetCount(device)
	anaFuncActiveSetCount[s.sweepNo][s.headstage] = activeSetCount
End

Function SkipSweeps(string device, STRUCT AnalysisFunction_V3 &s)

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
			RA_SkipSweeps(device, 1, SWEEP_SKIP_AUTO, limitToSetBorder = 1)
		endif
	elseif(s.eventType == POST_SWEEP_EVENT)
		RA_SkipSweeps(device, Inf, SWEEP_SKIP_AUTO, limitToSetBorder = 1)
	endif
End

Function SkipSweepsAdvanced(string device, STRUCT AnalysisFunction_V3 &s)

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
		RA_SkipSweeps(device, -10, SWEEP_SKIP_AUTO)
	elseif(s.sweepNo == 1)
		// skip one forward
		RA_SkipSweeps(device, 1, SWEEP_SKIP_AUTO, limitToSetBorder = 1)
	elseif(s.sweepNo == 2)
		// and repeat the last one
		RA_SkipSweeps(device, -1, SWEEP_SKIP_AUTO)
	endif
End

Function TrackActiveSetCountsAndEvents(string device, STRUCT AnalysisFunction_V3 &s)

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()

	CHECK_GE_VAR(s.eventType, 0)
	CHECK_LT_VAR(s.eventType, DimSize(anaFuncTracker, ROWS))
	anaFuncTracker[s.eventType][s.headstage] += 1

	WAVE anaFuncActiveSetCount = GetTrackActiveSetCount()

	NVAR activeSetCount = $GetActiveSetCount(device)
	anaFuncActiveSetCount[s.sweepNo][s.headstage] = activeSetCount
End

Function WriteIntoLBNOnPreDAQ(string device, STRUCT AnalysisFunction_V3 &s)

	if(s.eventType == PRE_DAQ_EVENT)
		Make/FREE/N=(LABNOTEBOOK_LAYER_COUNT) values = p
		values[INDEP_HEADSTAGE] = NaN
		ED_AddEntryToLabnotebook(device, "GARBAGE", values, overrideSweepNo = s.sweepNo)
	endif

	return 0
End

Function ChangeStimSet(string device, STRUCT AnalysisFunction_V3 &s)

	string ctrl

	if(s.eventType == POST_DAQ_EVENT)
		ctrl = GetPanelControl(0, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE)
		PGC_SeTAndActivateControl(device, ctrl, str = "StimulusSetA_DA_0")
	endif

	return 0
End

Function IncrementalLabnotebookUpdate(string device, STRUCT AnalysisFunction_V3 &s)

	if(s.eventType == POST_SWEEP_EVENT)
#if exists("ILCUCheck_IGNORE")
		ILCUCheck_IGNORE(device, s)
#else
		FAIL()
#endif
	endif

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()

	CHECK_GE_VAR(s.eventType, 0)
	CHECK_LT_VAR(s.eventType, DimSize(anaFuncTracker, ROWS))
	anaFuncTracker[s.eventType][s.headstage] += 1

	return 0
End

Function AcquisitionStateTrackingFunc(string device, STRUCT AnalysisFunction_V3 &s)

	variable acqState, expectedAcqState
	string name

	acqState = ROVAR(GetAcquisitionState(device))

	Make/D/FREE/N=(LABNOTEBOOK_LAYER_COUNT) values = NaN
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
			FATAL_ERROR("Invalid event")
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

Function ModifyStimSet(string device, STRUCT AnalysisFunction_V3 &s)

	string   stimset
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
		default:
			break
	endswitch

	return 0
End

Function StopMidSweep_V3(string device, STRUCT AnalysisFunction_V3 &s)

	variable DAC

	switch(s.eventType)
		case MID_SWEEP_EVENT:
			DAC = AFH_GetDACFromHeadstage(device, s.headstage)

			WAVE/T epochWave = GetEpochsWave(device)
			EP_AddUserEpoch(epochWave, XOP_CHANNEL_TYPE_DAC, DAC, 0, 1e9, "key=value")

			return ANALYSIS_FUNC_RET_EARLY_STOP
		default:
			break
	endswitch

	return 0
End

Function WaitMidSweep(string device, variable eventType, WAVE DAQDataWave, variable headStage, variable realDataLength)

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()

	CHECK_GE_VAR(eventType, 0)
	CHECK_LT_VAR(eventType, DimSize(anaFuncTracker, ROWS))
	anaFuncTracker[eventType][headstage] += 1

	Sleep/S 5

	return ANALYSIS_FUNC_RET_REPURP_TIME
End

Function AddTooLargeUserEpoch_V3(string device, STRUCT AnalysisFunction_V3 &s)

	variable DAC

	switch(s.eventType)
		case PRE_SWEEP_CONFIG_EVENT:
			DAC = AFH_GetDACFromHeadstage(device, s.headstage)
			WAVE/T epochWave = GetEpochsWave(device)
			EP_AddUserEpoch(epochWave, XOP_CHANNEL_TYPE_DAC, DAC, 0, 1e9, "key=value")
			break
		default:
			break
	endswitch
End

Function AddUserEpoch_V3(string device, STRUCT AnalysisFunction_V3 &s)

	variable DAC
	string   tags

	DAC = AFH_GetDACFromHeadstage(device, s.headstage)

	sprintf tags, "HS=%d;eventType=%d;", s.headstage, s.eventType
	WAVE/T epochWave = GetEpochsWave(device)
	EP_AddUserEpoch(epochWave, XOP_CHANNEL_TYPE_DAC, DAC, 0.5, 0.6, tags)
End

Function ChangeTPSettings(string device, STRUCT AnalysisFunction_V3 &s)

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
			break
	endswitch
End

Function SetSweepFormula(string device, STRUCT AnalysisFunction_V3 &s)

	string win, bsPanel, sweepFormulaNB, code

	switch(s.eventType)
		case PRE_DAQ_EVENT:
			win     = DB_OpenDataBrowser()
			bsPanel = BSP_GetPanel(win)
			PGC_SetAndActivateControl(bsPanel, "check_BrowserSettings_SF", val = CHECKBOX_SELECTED)
			break
		case PRE_SWEEP_CONFIG_EVENT:
			win            = DB_FindDataBrowser(device)
			sweepFormulaNB = BSP_GetSFFormula(win)
			sprintf code, "data(select(selrange(TP), selchannels(AD), selsweeps(%d)))\r", s.sweepNo
			ReplaceNotebookText(sweepFormulaNB, code)
			break
		default:
			// do nothing
			break
	endswitch
End

Function BreakConfigWave(string device, STRUCT AnalysisFunction_V3 &s)

	switch(s.eventType)
		case MID_SWEEP_EVENT:
			if(s.lastKnownRowIndexAD > 0)
				WAVE/Z configWave = GetDAQConfigWave(device)
				CHECK_WAVE(configWave, NUMERIC_WAVE)
				CHECK(IsValidSweepAndConfig(s.scaledDACWave, configWave))

				// add one more row so that IsValidSweepAndConfig fails
				Redimension/N=(DimSize(configWave, ROWS) + 1, -1) configWave
				CHECK(!IsValidSweepAndConfig(s.scaledDACWave, configWave))

				return ANALYSIS_FUNC_RET_EARLY_STOP
			endif
			break
		default:
			break
	endswitch
End

Function/S ComplainWithProperString_GetHelp(string name)

	strswitch(name)
		case "param":
			return "Hi there!"
		default:
			FAIL()
	endswitch
End

Function/S ComplainWithProperString_CheckParam(string name, string params)

	strswitch(name)
		case "param":
			if(!IsEmpty(name))
				return "wrong value"
			endif
		default:
			FAIL()
	endswitch
End

Function/S ComplainWithProperString_GetParams()

	return "param"
End

Function ComplainWithProperString(string device, STRUCT AnalysisFunction_V3 &s)

	FAIL()
End

Function EnableIndexing(string device, STRUCT AnalysisFunction_V3 &s)

	switch(s.eventType)
		case POST_DAQ_EVENT:
			PGC_SetAndActivateControl(device, "Check_DataAcq_Indexing", val = CHECKBOX_SELECTED)
			break
		default:
			// do nothing
			break
	endswitch
End

Function AddUserEpochsForTPLike(string device, STRUCT AnalysisFunction_V3 &s)

	variable ret

	switch(s.eventType)
		case PRE_SWEEP_CONFIG_EVENT:
			ret = MIES_PSQ#PSQ_CreateTestpulseEpochs(device, s.headstage, 3)
			if(ret)
				return 1
			endif
		default:
			// do nothing
			break
	endswitch
End

Function DashboardAnaFunc(string device, STRUCT AnalysisFunction_V3 &s)

	string win, key, ref, str
	variable index

	win = DB_GetBoundDataBrowser(device)
	DFREF  dfr      = BSP_GetFolder(win, MIES_BSP_PANEL_FOLDER)
	WAVE/T infoWave = GetAnaFuncDashboardInfoWave(dfr)
	WAVE/T listWave = GetAnaFuncDashboardListWave(dfr)

	switch(s.eventType)
		case POST_SWEEP_EVENT:
			// five sweeps in total, but we are only called for the three of setA

			index = GetNumberFromWaveNote(listWave, NOTE_INDEX)
			CHECK_EQUAL_VAR(index, 1)

			ref = "1"
			str = infoWave[0][%$"Ongoing DAQ"]
			CHECK_EQUAL_STR(ref, str)
			break
		case POST_SET_EVENT:
			key = CreateAnaFuncLBNKey(TEST_ANALYSIS_FUNCTION, PSQ_FMT_LBN_SET_PASS)
			WAVE setPassed = LBN_GetNumericWave()
			setPassed[INDEP_HEADSTAGE] = 1
			ED_AddEntryToLabnotebook(device, key, setPassed, unit = LABNOTEBOOK_BINARY_UNIT, overrideSweepNo = s.sweepNo)
			break
		default:
			// do nothing
			break
	endswitch
End

Function JustFail(string device, STRUCT AnalysisFunction_V3 &s)

	FAIL()
End

static Function ILCUCheck_IGNORE(string device, STRUCT AnalysisFunction_V3 &s)

	variable nonExistingSweep

	WAVE/T textualValues   = GetLBTextualValues(device)
	WAVE   numericalValues = GetLBNumericalValues(device)

	// fetch some existing entries from the LBN
	WAVE/Z sweepCounts = GetLastSetting(numericalValues, s.sweepNo, "Set Sweep Count", DATA_ACQUISITION_MODE)
	CHECK_WAVE(sweepCounts, NUMERIC_WAVE)

	WAVE/Z/T foundStimSets = GetLastSetting(textualValues, s.sweepNo, STIM_WAVE_NAME_KEY, DATA_ACQUISITION_MODE)
	CHECK_WAVE(foundStimSets, TEXT_WAVE)

	WAVE/Z sweeps = AFH_GetSweepsFromSameSCI(numericalValues, s.sweepNo, 0)
	CHECK_WAVE(sweeps, NUMERIC_WAVE)
	CHECK_EQUAL_VAR(DimSize(sweeps, ROWS), s.sweepNo + 1)

	WAVE/Z sweeps = AFH_GetSweepsFromSameRACycle(numericalValues, s.sweepNo)
	CHECK_WAVE(sweeps, NUMERIC_WAVE)
	CHECK_EQUAL_VAR(DimSize(sweeps, ROWS), s.sweepNo + 1)

	if(s.sweepNo == 0)
		// now fetch non-existing ones from the next sweep
		// this adds "missing" entries to the LBN cache
		// our wave cache updating results in these missing values being move to uncached on the cache update
		nonExistingSweep = s.sweepNo + 1
		WAVE/Z sweepCounts = GetLastSetting(numericalValues, nonExistingSweep, "Set Sweep Count", DATA_ACQUISITION_MODE)
		CHECK_WAVE(sweepCounts, NULL_WAVE)

		WAVE/Z/T foundStimSets = GetLastSetting(textualValues, nonExistingSweep, STIM_WAVE_NAME_KEY, DATA_ACQUISITION_MODE)
		CHECK_WAVE(foundStimSets, NULL_WAVE)

		WAVE/Z sweeps = AFH_GetSweepsFromSameSCI(numericalValues, nonExistingSweep, 0)
		CHECK_WAVE(sweeps, NULL_WAVE)

		WAVE/Z sweeps = AFH_GetSweepsFromSameRACycle(numericalValues, nonExistingSweep)
		CHECK_WAVE(sweeps, NULL_WAVE)
	else
		CHECK_EQUAL_VAR(s.sweepNo, 1)
	endif
End

Function LastSweepInSetWithoutSkip(string device, STRUCT AnalysisFunction_V3 &s)

	string key

	sprintf key, "LastSweepInSet_Event_%s_HS_%d", StringFromList(s.eventType, EVENT_NAME_LIST), s.headstage

	WAVE values = LBN_GetNumericWave()
	values[INDEP_HEADSTAGE] = AFH_LastSweepInSet(device, s.sweepNo, s.headstage, s.eventType)
	ED_AddEntryToLabnotebook(device, key, values, overrideSweepNo = s.sweepNo)
End
