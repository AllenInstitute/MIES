#pragma rtGlobals=3		// Use modern global access method and strict wave access.

#ifndef AUTOMATED_TESTING

	#define **error** Can only be used with automated testing
#endif

Function InvalidSignature()

	FAIL()
End

Function/WAVE InvalidSignatureAndReturnType()

	FAIL()
End

Function/WAVE InvalidReturnTypeAndValidSig_V1(panelTitle, eventType, ITCDataWave, headStage)
	string panelTitle
	variable eventType
	Wave ITCDataWave
	variable headstage

	FAIL()
End

Function/WAVE InvalidReturnTypeAndValidSig_V2(panelTitle, eventType, ITCDataWave, headStage, realDataLength)
	string panelTitle
	variable eventType
	Wave ITCDataWave
	variable headstage, realDataLength

	FAIL()
End

Function ValidFunc_V1(panelTitle, eventType, ITCDataWave, headStage)
	string panelTitle
	variable eventType
	Wave ITCDataWave
	variable headstage

	CHECK_NON_EMPTY_STR(panelTitle)
	CHECK_EQUAL_VAR(numType(eventType), 0)
	CHECK_WAVE(ITCDataWave, NUMERIC_WAVE)
	CHECK_EQUAL_VAR(NumberByKey("LOCK", WaveInfo(ITCDataWave, 0)), 1)
	CHECK_EQUAL_VAR(headstage, 0)

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()

	CHECK(eventType >= 0 && eventType < DimSize(anaFuncTracker, ROWS))
	anaFuncTracker[eventType] += 1
End

Function ValidFunc_V2(panelTitle, eventType, ITCDataWave, headStage, realDataLength)
	string panelTitle
	variable eventType
	Wave ITCDataWave
	variable headstage, realDataLength

	CHECK_NON_EMPTY_STR(panelTitle)
	CHECK_EQUAL_VAR(numType(eventType), 0)
	CHECK_WAVE(ITCDataWave, NUMERIC_WAVE)
	CHECK_EQUAL_VAR(NumberByKey("LOCK", WaveInfo(ITCDataWave, 0)), 1)
	CHECK_EQUAL_VAR(headstage, 0)

	if(eventType == PRE_DAQ_EVENT || eventType == PRE_SET_EVENT)
		CHECK_EQUAL_VAR(numType(realDataLength), 2)
	else
		CHECK(realDataLength >= 0 && realDataLength < DimSize(ITCDataWave, ROWS))
	endif

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()

	CHECK(eventType >= 0 && eventType < DimSize(anaFuncTracker, ROWS))
	anaFuncTracker[eventType] += 1
End

Function ValidMultHS_V1(panelTitle, eventType, ITCDataWave, headStage)
	string panelTitle
	variable eventType
	Wave ITCDataWave
	variable headstage

	CHECK_NON_EMPTY_STR(panelTitle)
	CHECK_EQUAL_VAR(numType(eventType), 0)
	CHECK_WAVE(ITCDataWave, NUMERIC_WAVE)
	CHECK_EQUAL_VAR(NumberByKey("LOCK", WaveInfo(ITCDataWave, 0)), 1)

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()

	CHECK(eventType >= 0 && eventType < DimSize(anaFuncTracker, ROWS))
	anaFuncTracker[eventType][headstage] += 1
End

Function NotCalled_V1(panelTitle, eventType, ITCDataWave, headStage)
	string panelTitle
	variable eventType
	Wave ITCDataWave
	variable headstage

	FAIL()
End

Function preDAQHardAbort(panelTitle, eventType, ITCDataWave, headStage, realDataLength)
	string panelTitle
	variable eventType
	Wave ITCDataWave
	variable headstage, realDataLength

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()

	CHECK(eventType >= 0 && eventType < DimSize(anaFuncTracker, ROWS))
	anaFuncTracker[eventType][headstage] += 1

	if(eventType == PRE_DAQ_EVENT)
		Abort
	endif
End

Function preDAQ(panelTitle, eventType, ITCDataWave, headStage, realDataLength)
	string panelTitle
	variable eventType
	Wave ITCDataWave
	variable headstage, realDataLength

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()

	CHECK(eventType >= 0 && eventType < DimSize(anaFuncTracker, ROWS))
	anaFuncTracker[eventType][headstage] += 1
End

Function preSet(panelTitle, eventType, ITCDataWave, headStage, realDataLength)
	string panelTitle
	variable eventType
	Wave ITCDataWave
	variable headstage, realDataLength

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()

	CHECK(eventType >= 0 && eventType < DimSize(anaFuncTracker, ROWS))
	anaFuncTracker[eventType][headstage] += 1
End

Function preSweep(panelTitle, eventType, ITCDataWave, headStage, realDataLength)
	string panelTitle
	variable eventType
	Wave ITCDataWave
	variable headstage, realDataLength

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()

	CHECK(eventType >= 0 && eventType < DimSize(anaFuncTracker, ROWS))
	anaFuncTracker[eventType][headstage] += 1
End

Function midSweep(panelTitle, eventType, ITCDataWave, headStage, realDataLength)
	string panelTitle
	variable eventType
	Wave ITCDataWave
	variable headstage, realDataLength

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()

	CHECK(eventType >= 0 && eventType < DimSize(anaFuncTracker, ROWS))
	anaFuncTracker[eventType][headstage] += 1
End

Function postSweep(panelTitle, eventType, ITCDataWave, headStage, realDataLength)
	string panelTitle
	variable eventType
	Wave ITCDataWave
	variable headstage, realDataLength

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()

	CHECK(eventType >= 0 && eventType < DimSize(anaFuncTracker, ROWS))
	anaFuncTracker[eventType][headstage] += 1
End

Function postSet(panelTitle, eventType, ITCDataWave, headStage, realDataLength)
	string panelTitle
	variable eventType
	Wave ITCDataWave
	variable headstage, realDataLength

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()

	CHECK(eventType >= 0 && eventType < DimSize(anaFuncTracker, ROWS))
	anaFuncTracker[eventType][headstage] += 1
End

Function postDAQ(panelTitle, eventType, ITCDataWave, headStage, realDataLength)
	string panelTitle
	variable eventType
	Wave ITCDataWave
	variable headstage, realDataLength

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()

	CHECK(eventType >= 0 && eventType < DimSize(anaFuncTracker, ROWS))
	anaFuncTracker[eventType][headstage] += 1
End

Function AbortPreDAQ(panelTitle, eventType, ITCDataWave, headStage, realDataLength)
	string panelTitle
	variable eventType
	Wave ITCDataWave
	variable headstage, realDataLength

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()

	CHECK(eventType >= 0 && eventType < DimSize(anaFuncTracker, ROWS))
	anaFuncTracker[eventType][headstage] += 1

	// prevents DAQ
	return 1
End

Function StopMidSweep(panelTitle, eventType, ITCDataWave, headStage, realDataLength)
	string panelTitle
	variable eventType
	Wave ITCDataWave
	variable headstage, realDataLength

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()

	CHECK(eventType >= 0 && eventType < DimSize(anaFuncTracker, ROWS))
	anaFuncTracker[eventType][headstage] += 1

	return ANALYSIS_FUNC_RET_REPURP_TIME
End

Function ValidFunc_V3(panelTitle, s)
	string panelTitle
	STRUCT AnalysisFunction_V3& s

	CHECK_NON_EMPTY_STR(panelTitle)
	CHECK_WAVE(s.rawDACWave, NUMERIC_WAVE)
	CHECK_EQUAL_VAR(NumberByKey("LOCK", WaveInfo(s.rawDACWAVE, 0)), 1)
	CHECK_EQUAL_VAR(s.headstage, 0)
	CHECK_EQUAL_VAR(numType(s.sweepNo), 0)
	CHECK_EQUAL_VAR(numType(s.sweepsInSet), 0)
	CHECK_EQUAL_VAR(strlen(s.params), 0)

	if(s.eventType == PRE_DAQ_EVENT || s.eventType == PRE_SET_EVENT)
		CHECK_EQUAL_VAR(numType(s.lastValidRowIndex), 2)
	else
		CHECK(s.lastValidRowIndex >= 0 && s.lastValidRowIndex < DimSize(s.rawDACWAVE, ROWS))
	endif

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()

	// check sweep number
	switch(s.eventType)
		case PRE_DAQ_EVENT:
			CHECK_EQUAL_VAR(s.sweepNo, 0)
			CHECK(!WaveExists(GetSweepWave(panelTitle, s.sweepNo)))
			break
		case PRE_SWEEP_EVENT:
		case PRE_SET_EVENT:
		case MID_SWEEP_EVENT:
			CHECK_EQUAL_VAR(s.sweepNo, anaFuncTracker[POST_SWEEP_EVENT])
			CHECK(!WaveExists(GetSweepWave(panelTitle, s.sweepNo)))
			break
		case POST_SWEEP_EVENT:
			CHECK_EQUAL_VAR(s.sweepNo, anaFuncTracker[POST_SWEEP_EVENT])
			CHECK_WAVE(GetSweepWave(panelTitle, s.sweepNo), NUMERIC_WAVE)
			break
		case POST_SET_EVENT:
			CHECK_EQUAL_VAR(s.sweepNo, anaFuncTracker[POST_SWEEP_EVENT] - 1)
			CHECK_WAVE(GetSweepWave(panelTitle, s.sweepNo), NUMERIC_WAVE)
			break
		case POST_DAQ_EVENT:
			CHECK_EQUAL_VAR(s.sweepNo, anaFuncTracker[POST_SWEEP_EVENT] - 1)
			CHECK_WAVE(GetSweepWave(panelTitle, s.sweepNo), NUMERIC_WAVE)
			break
	endswitch

	// the next sweep can not exist
	CHECK(!WaveExists(GetSweepWave(panelTitle, s.sweepNo + 1)))

	CHECK(s.eventType >= 0 && s.eventType < TOTAL_NUM_EVENTS && s.eventType != GENERIC_EVENT)
	CHECK(s.eventType >= 0 && s.eventType < DimSize(anaFuncTracker, ROWS))
	anaFuncTracker[s.eventType] += 1
End

Function/S Params1_V3_GetParams()
	return "MyStr,MyVar,MyWave,MyTextWave"
End

Function Params1_V3(panelTitle, s)
	string panelTitle
	STRUCT AnalysisFunction_V3& s

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()

	CHECK(s.eventType >= 0 && s.eventType < TOTAL_NUM_EVENTS && s.eventType != GENERIC_EVENT)
	CHECK(s.eventType >= 0 && s.eventType < DimSize(anaFuncTracker, ROWS))
	anaFuncTracker[s.eventType] += 1
End

Function/S Params2_V3_GetParams()
	return "MyStr:string,MyVar"
End

Function Params2_V3(panelTitle, s)
	string panelTitle
	STRUCT AnalysisFunction_V3& s

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()

	CHECK(s.eventType >= 0 && s.eventType < TOTAL_NUM_EVENTS && s.eventType != GENERIC_EVENT)
	CHECK(s.eventType >= 0 && s.eventType < DimSize(anaFuncTracker, ROWS))
	anaFuncTracker[s.eventType] += 1
End

Function/S Params3_V3_GetParams()
	return "MyStr:invalidType"
End

Function Params3_V3(panelTitle, s)
	string panelTitle
	STRUCT AnalysisFunction_V3& s

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()

	CHECK(s.eventType >= 0 && s.eventType < TOTAL_NUM_EVENTS && s.eventType != GENERIC_EVENT)
	CHECK(s.eventType >= 0 && s.eventType < DimSize(anaFuncTracker, ROWS))
	anaFuncTracker[s.eventType] += 1
End

Function/S Params4_V3_GetParams()
	return "MyStr:variable" // wrong type
End

Function Params4_V3(panelTitle, s)
	string panelTitle
	STRUCT AnalysisFunction_V3& s

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()

	CHECK(s.eventType >= 0 && s.eventType < TOTAL_NUM_EVENTS && s.eventType != GENERIC_EVENT)
	CHECK(s.eventType >= 0 && s.eventType < DimSize(anaFuncTracker, ROWS))
	anaFuncTracker[s.eventType] += 1
End

Function ChangeToSingleDeviceDAQ(panelTitle, eventType, ITCDataWave, headStage, realDataLength)
	string panelTitle
	variable eventType
	Wave ITCDataWave
	variable headstage, realDataLength

	PGC_SetAndActivateControl(panelTitle, "check_Settings_MD", val = CHECKBOX_UNSELECTED)
	return 0
End

Function ChangeToMultiDeviceDAQ(panelTitle, eventType, ITCDataWave, headStage, realDataLength)
	string panelTitle
	variable eventType
	Wave ITCDataWave
	variable headstage, realDataLength

	PGC_SetAndActivateControl(panelTitle, "check_Settings_MD", val = CHECKBOX_SELECTED)
	return 0
End

Function Indexing_V3(panelTitle, s)
	string panelTitle
	STRUCT AnalysisFunction_V3& s

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()

	// the generic event is never sent to analysis functions
	CHECK(s.eventType >= 0 && s.eventType < TOTAL_NUM_EVENTS - 1)
	CHECK(s.eventType >= 0 && s.eventType < DimSize(anaFuncTracker, ROWS))
	anaFuncTracker[s.eventType] += 1
End
