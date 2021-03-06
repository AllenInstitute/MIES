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

Function/WAVE InvalidReturnTypeAndValidSig_V1(panelTitle, eventType, DAQDataWave, headStage)
	string panelTitle
	variable eventType
	Wave DAQDataWave
	variable headstage

	FAIL()
End

Function/WAVE InvalidReturnTypeAndValidSig_V2(panelTitle, eventType, DAQDataWave, headStage, realDataLength)
	string panelTitle
	variable eventType
	Wave DAQDataWave
	variable headstage, realDataLength

	FAIL()
End

Function ValidFunc_V1(panelTitle, eventType, DAQDataWave, headStage)
	string panelTitle
	variable eventType
	Wave DAQDataWave
	variable headstage

	CHECK_NON_EMPTY_STR(panelTitle)
	CHECK_EQUAL_VAR(numType(eventType), 0)

	switch(GetHardwareType(panelTitle))
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

	CHECK(eventType >= 0 && eventType < DimSize(anaFuncTracker, ROWS))
	anaFuncTracker[eventType] += 1
End

Function ValidFunc_V2(panelTitle, eventType, DAQDataWave, headStage, realDataLength)
	string panelTitle
	variable eventType
	Wave DAQDataWave
	variable headstage, realDataLength

	CHECK_NON_EMPTY_STR(panelTitle)
	CHECK_EQUAL_VAR(numType(eventType), 0)

	switch(GetHardwareType(panelTitle))
		case HARDWARE_ITC_DAC:
			CHECK_WAVE(DAQDataWave, NUMERIC_WAVE)
			break
		case HARDWARE_NI_DAC:
			CHECK_WAVE(DAQDataWave, WAVE_WAVE)
			break
	endswitch

	CHECK_EQUAL_VAR(NumberByKey("LOCK", WaveInfo(DAQDataWave, 0)), 1)
	CHECK_EQUAL_VAR(headstage, 0)

	if(eventType == PRE_DAQ_EVENT || eventType == PRE_SET_EVENT)
		CHECK_EQUAL_VAR(numType(realDataLength), 2)
	elseif(GetHardWareType(panelTitle) == HARDWARE_ITC_DAC)
		CHECK(realDataLength >= 0 && realDataLength < DimSize(DAQDataWave, ROWS))
	elseif(GetHardWareType(panelTitle) == HARDWARE_NI_DAC)
		WAVE/WAVE DAQDataWaveRef = DAQDataWave
		Make/FREE/N=(DimSize(DAQDataWaveRef, ROWS)) sizes = DimSize(DAQDataWaveRef[p], ROWS)
		CHECK(realDataLength >= 0 && realDataLength <= WaveMax(sizes))
	else
		FAIL()
	endif

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()

	CHECK(eventType >= 0 && eventType < DimSize(anaFuncTracker, ROWS))
	anaFuncTracker[eventType] += 1
End

Function ValidMultHS_V1(panelTitle, eventType, DAQDataWave, headStage)
	string panelTitle
	variable eventType
	Wave DAQDataWave
	variable headstage

	CHECK_NON_EMPTY_STR(panelTitle)
	CHECK_EQUAL_VAR(numType(eventType), 0)

	switch(GetHardwareType(panelTitle))
		case HARDWARE_ITC_DAC:
			CHECK_WAVE(DAQDataWave, NUMERIC_WAVE)
			break
		case HARDWARE_NI_DAC:
			CHECK_WAVE(DAQDataWave, WAVE_WAVE)
			break
	endswitch

	CHECK_EQUAL_VAR(NumberByKey("LOCK", WaveInfo(DAQDataWave, 0)), 1)

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()

	CHECK(eventType >= 0 && eventType < DimSize(anaFuncTracker, ROWS))
	anaFuncTracker[eventType][headstage] += 1
End

Function NotCalled_V1(panelTitle, eventType, DAQDataWave, headStage)
	string panelTitle
	variable eventType
	Wave DAQDataWave
	variable headstage

	FAIL()
End

Function preDAQHardAbort(panelTitle, eventType, DAQDataWave, headStage, realDataLength)
	string panelTitle
	variable eventType
	Wave DAQDataWave
	variable headstage, realDataLength

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()

	CHECK(eventType >= 0 && eventType < DimSize(anaFuncTracker, ROWS))
	anaFuncTracker[eventType][headstage] += 1

	if(eventType == PRE_DAQ_EVENT)
		Abort
	endif
End

Function preDAQ(panelTitle, eventType, DAQDataWave, headStage, realDataLength)
	string panelTitle
	variable eventType
	Wave DAQDataWave
	variable headstage, realDataLength

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()

	CHECK(eventType >= 0 && eventType < DimSize(anaFuncTracker, ROWS))
	anaFuncTracker[eventType][headstage] += 1
End

Function preSet(panelTitle, eventType, DAQDataWave, headStage, realDataLength)
	string panelTitle
	variable eventType
	Wave DAQDataWave
	variable headstage, realDataLength

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()

	CHECK(eventType >= 0 && eventType < DimSize(anaFuncTracker, ROWS))
	anaFuncTracker[eventType][headstage] += 1
End

Function preSweep(panelTitle, eventType, DAQDataWave, headStage, realDataLength)
	string panelTitle
	variable eventType
	Wave DAQDataWave
	variable headstage, realDataLength

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()

	CHECK(eventType >= 0 && eventType < DimSize(anaFuncTracker, ROWS))
	anaFuncTracker[eventType][headstage] += 1
End

Function midSweep(panelTitle, eventType, DAQDataWave, headStage, realDataLength)
	string panelTitle
	variable eventType
	Wave DAQDataWave
	variable headstage, realDataLength

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()

	CHECK(eventType >= 0 && eventType < DimSize(anaFuncTracker, ROWS))
	anaFuncTracker[eventType][headstage] += 1
End

Function postSweep(panelTitle, eventType, DAQDataWave, headStage, realDataLength)
	string panelTitle
	variable eventType
	Wave DAQDataWave
	variable headstage, realDataLength

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()

	CHECK(eventType >= 0 && eventType < DimSize(anaFuncTracker, ROWS))
	anaFuncTracker[eventType][headstage] += 1
End

Function postSet(panelTitle, eventType, DAQDataWave, headStage, realDataLength)
	string panelTitle
	variable eventType
	Wave DAQDataWave
	variable headstage, realDataLength

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()

	CHECK(eventType >= 0 && eventType < DimSize(anaFuncTracker, ROWS))
	anaFuncTracker[eventType][headstage] += 1
End

Function postDAQ(panelTitle, eventType, DAQDataWave, headStage, realDataLength)
	string panelTitle
	variable eventType
	Wave DAQDataWave
	variable headstage, realDataLength

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()

	CHECK(eventType >= 0 && eventType < DimSize(anaFuncTracker, ROWS))
	anaFuncTracker[eventType][headstage] += 1
End

Function AbortPreDAQ(panelTitle, eventType, DAQDataWave, headStage, realDataLength)
	string panelTitle
	variable eventType
	Wave DAQDataWave
	variable headstage, realDataLength

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()

	CHECK(eventType >= 0 && eventType < DimSize(anaFuncTracker, ROWS))
	anaFuncTracker[eventType][headstage] += 1

	// prevents DAQ
	return 1
End

Function StopMidSweep(panelTitle, eventType, DAQDataWave, headStage, realDataLength)
	string panelTitle
	variable eventType
	Wave DAQDataWave
	variable headstage, realDataLength

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()

	CHECK(eventType >= 0 && eventType < DimSize(anaFuncTracker, ROWS))
	anaFuncTracker[eventType][headstage] += 1

	return ANALYSIS_FUNC_RET_REPURP_TIME
End

Function ValidFunc_V3(panelTitle, s)
	string panelTitle
	STRUCT AnalysisFunction_V3& s

	variable hardwareType

	hardwareType = GetHardwareType(panelTitle)

	CHECK_NON_EMPTY_STR(panelTitle)

	switch(hardwareType)
		case HARDWARE_ITC_DAC:
			CHECK_WAVE(s.rawDACWave, NUMERIC_WAVE)
			break
		case HARDWARE_NI_DAC:
			CHECK_WAVE(s.rawDACWave, WAVE_WAVE)
			break
	endswitch

	CHECK_WAVE(s.scaledDACWave, NUMERIC_WAVE, minorType = FLOAT_WAVE)

	if(s.eventType != PRE_DAQ_EVENT && s.eventType != PRE_SET_EVENT && s.eventType != POST_DAQ_EVENT)
		switch(hardwareType)
			case HARDWARE_ITC_DAC:
				CHECK_EQUAL_VAR(DimSize(s.scaledDACWave, COLS), DimSize(s.rawDACWave, COLS))
				CHECK(DimSize(s.scaledDACWave, ROWS) <= DimSize(s.rawDACWave, ROWS))
				break
			case HARDWARE_NI_DAC:
				CHECK_EQUAL_VAR(DimSize(s.scaledDACWave, COLS), DimSize(s.rawDACWave, ROWS))
				WAVE/WAVE rawDACWaveRef = s.rawDACWave
				Make/FREE/N=(DimSize(rawDACWaveRef, ROWS)) sizes = DimSize(rawDACWaveRef[p], ROWS)
				CHECK(DimSize(s.scaledDACWave, ROWS) <= WaveMax(sizes))
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

	if(s.eventType == PRE_DAQ_EVENT || s.eventType == PRE_SET_EVENT)
		CHECK_EQUAL_VAR(numType(s.lastValidRowIndex), 2)
		CHECK_EQUAL_VAR(numType(s.lastKnownRowIndex), 2)
	elseif(s.eventType == PRE_SWEEP_EVENT)
		CHECK_EQUAL_VAR(numType(s.lastKnownRowIndex), 2)
		CHECK(s.lastValidRowIndex > 0)
	elseif(s.eventType == MID_SWEEP_EVENT)
		switch(hardwareType)
			case HARDWARE_ITC_DAC:
				CHECK(s.lastValidRowIndex >= 0 && s.lastValidRowIndex < DimSize(s.rawDACWave, ROWS))
				break
			case HARDWARE_NI_DAC:
				WAVE/WAVE rawDACWaveRef = s.rawDACWave
				Make/FREE/N=(DimSize(rawDACWaveRef, ROWS)) sizes = DimSize(rawDACWaveRef[p], ROWS)
				CHECK(s.lastValidRowIndex >= 0 && s.lastValidRowIndex < WaveMax(sizes))
				CHECK(s.lastKnownRowIndex >= 0 && s.lastKnownRowIndex < WaveMax(sizes))
				break
			default:
				FAIL()
		endswitch
	elseif(s.eventType == POST_DAQ_EVENT || s.eventType == POST_SET_EVENT || s.eventType == POST_SWEEP_EVENT)
		WAVE/Z sweepWave = GetSweepWave(panelTitle, s.sweepNo)
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
			CHECK_WAVE(GetSweepWave(panelTitle, s.sweepNo), NULL_WAVE)
			break
		case PRE_SWEEP_EVENT:
		case PRE_SET_EVENT:
		case MID_SWEEP_EVENT:
			CHECK_EQUAL_VAR(s.sweepNo, anaFuncTracker[POST_SWEEP_EVENT])
			CHECK_WAVE(GetSweepWave(panelTitle, s.sweepNo), NULL_WAVE)
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
	CHECK_WAVE(GetSweepWave(panelTitle, s.sweepNo + 1), NULL_WAVE)

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
	return "MyStr:string,MyVar,[OptionalParam]"
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

Function Params5_V3(panelTitle, s)
	string panelTitle
	STRUCT AnalysisFunction_V3& s

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()

	CHECK(s.eventType >= 0 && s.eventType < TOTAL_NUM_EVENTS && s.eventType != GENERIC_EVENT)
	CHECK(s.eventType >= 0 && s.eventType < DimSize(anaFuncTracker, ROWS))
	anaFuncTracker[s.eventType] += 1
End

Function ChangeToSingleDeviceDAQAF(panelTitle, eventType, DAQDataWave, headStage, realDataLength)
	string panelTitle
	variable eventType
	Wave DAQDataWave
	variable headstage, realDataLength

	PGC_SetAndActivateControl(panelTitle, "check_Settings_MD", val = CHECKBOX_UNSELECTED)
	return 0
End

Function ChangeToMultiDeviceDAQAF(panelTitle, eventType, DAQDataWave, headStage, realDataLength)
	string panelTitle
	variable eventType
	Wave DAQDataWave
	variable headstage, realDataLength

	PGC_SetAndActivateControl(panelTitle, "check_Settings_MD", val = CHECKBOX_SELECTED)
	return 0
End

Function Indexing_V3(panelTitle, s)
	string panelTitle
	STRUCT AnalysisFunction_V3& s

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()

	CHECK(s.eventType >= 0 && s.eventType < TOTAL_NUM_EVENTS && s.eventType != GENERIC_EVENT)
	CHECK(s.eventType >= 0 && s.eventType < DimSize(anaFuncTracker, ROWS))
	anaFuncTracker[s.eventType] += 1
End

Function TrackSweepCount_V3(panelTitle, s)
	string panelTitle
	STRUCT AnalysisFunction_V3& s

	WAVE anaFuncSweepCounts = GetTrackSweepCounts()

	CHECK(s.eventType >= 0 && s.eventType < TOTAL_NUM_EVENTS && s.eventType != GENERIC_EVENT)
	CHECK(s.sweepNo >= 0 && s.sweepNo < DimSize(anaFuncSweepCounts, ROWS))
	CHECK(s.eventType >= 0 && s.eventType < DimSize(anaFuncSweepCounts, COLS))
	CHECK(s.headstage >= 0 && s.headstage < DimSize(anaFuncSweepCounts, LAYERS))

	if(s.eventType == MID_SWEEP_EVENT)
		// don't check that here
		return 0
	endif

	NVAR count = $GetCount(panelTitle)
	anaFuncSweepCounts[s.sweepNo][s.eventType][s.headstage] = count
End

Function AbortPreSet(panelTitle, s)
	string panelTitle
	STRUCT AnalysisFunction_V3& s

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()

	CHECK(s.eventType >= 0 && s.eventType < DimSize(anaFuncTracker, ROWS))
	anaFuncTracker[s.eventType][s.headstage] += 1

	if(s.eventType == PRE_SET_EVENT)
		// aborts DAQ
		return 1
	else
		return 0
	endif
End

Function TotalOrdering(panelTitle, s)
	string panelTitle
	STRUCT AnalysisFunction_V3& s

	WAVE anaFuncOrder = TrackAnalysisFunctionOrder()

	CHECK(s.eventType >= 0 && s.eventType < DimSize(anaFuncOrder, ROWS))

	Sleep/T 2
	anaFuncOrder[s.eventType][s.headstage] = ticks
End

Function TrackActiveSetCount(panelTitle, s)
	string panelTitle
	STRUCT AnalysisFunction_V3& s

	if(s.eventType != PRE_SWEEP_EVENT)
		return NaN
	endif

	WAVE anaFuncActiveSetCount = GetTrackActiveSetCount()

	NVAR activeSetCount = $GetActiveSetCount(panelTitle)
	anaFuncActiveSetCount[s.sweepNo][s.headstage] = activeSetCount
End

Function SkipSweeps(panelTitle, s)
	string panelTitle
	STRUCT AnalysisFunction_V3& s

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()

	CHECK(s.eventType >= 0 && s.eventType < DimSize(anaFuncTracker, ROWS))
	anaFuncTracker[s.eventType][s.headstage] += 1

	if(s.eventType != POST_SWEEP_EVENT)
		return NaN
	endif

	RA_SkipSweeps(panelTitle, inf, limitToSetBorder = 1)
End

Function SkipSweepsAdvanced(panelTitle, s)
	string panelTitle
	STRUCT AnalysisFunction_V3& s

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()

	CHECK(s.eventType >= 0 && s.eventType < DimSize(anaFuncTracker, ROWS))
	anaFuncTracker[s.eventType][s.headstage] += 1

	if(s.eventType != POST_SWEEP_EVENT)
		return NaN
	endif

	WAVE anaFuncActiveSetCount = GetTrackActiveSetCount()

	NVAR activeSetCount = $GetActiveSetCount(panelTitle)
	anaFuncActiveSetCount[s.sweepNo][s.headstage] = activeSetCount

	// sweeps in stimset: 0, 1, 2
	// we acquire: 0, 0, 2, 2
	if(s.sweepNo == 0)
		// repeat first sweep
		RA_SkipSweeps(panelTitle, -10)
	elseif(s.sweepNo == 1)
		// skip one forward
		RA_SkipSweeps(panelTitle, 1, limitToSetBorder = 1)
	elseif(s.sweepNo == 2)
		// and repeat the last one
		RA_SkipSweeps(panelTitle, -1)
	endif
End

Function TrackActiveSetCountsAndEvents(panelTitle, s)
	string panelTitle
	STRUCT AnalysisFunction_V3& s

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()

	CHECK(s.eventType >= 0 && s.eventType < DimSize(anaFuncTracker, ROWS))
	anaFuncTracker[s.eventType][s.headstage] += 1

	WAVE anaFuncActiveSetCount = GetTrackActiveSetCount()

	NVAR activeSetCount = $GetActiveSetCount(panelTitle)
	anaFuncActiveSetCount[s.sweepNo][s.headstage] = activeSetCount
End

Function WriteIntoLBNOnPreDAQ(panelTitle, s)
	string panelTitle
	STRUCT AnalysisFunction_V3& s

	if(s.eventType == PRE_DAQ_EVENT)
		Make/FREE/N=(LABNOTEBOOK_LAYER_COUNT) values = p
		values[INDEP_HEADSTAGE] = NaN
		ED_AddEntryToLabnotebook(panelTitle, "GARBAGE", values, overrideSweepNo = s.sweepNo)
	endif

	return 0
End

Function ChangeStimSet(panelTitle, s)
	string panelTitle
	STRUCT AnalysisFunction_V3& s

	string ctrl

	if(s.eventType == POST_DAQ_EVENT)
		ctrl = GetPanelControl(0, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE)
		PGC_SeTAndActivateControl(panelTitle, ctrl, str = "StimulusSetA_DA_0")
	endif

	return 0
End

Function IncrementalLabnotebookUpdate(panelTitle, s)
	string panelTitle
	STRUCT AnalysisFunction_V3& s

	if(s.eventType == POST_SWEEP_EVENT)
		ILCUCheck_IGNORE(panelTitle, s)
	endif

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()

	CHECK(s.eventType >= 0 && s.eventType < DimSize(anaFuncTracker, ROWS))
	anaFuncTracker[s.eventType][s.headstage] += 1

	return 0
End

Function SweepRollbackChecker(panelTitle, s)
	string panelTitle
	STRUCT AnalysisFunction_V3& s

	string list, refList

	if(s.eventType == PRE_DAQ_EVENT)
		DFREF dfr = GetDeviceDataPath(panelTitle)
		list    = SortList(GetListOfObjects(dfr, ".*"))
		refList = SortList("Config_Sweep_0;Sweep_0;")
		CHECK_EQUAL_STR(refList, list)
	endif

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()

	CHECK(s.eventType >= 0 && s.eventType < DimSize(anaFuncTracker, ROWS))
	anaFuncTracker[s.eventType][s.headstage] += 1

	return 0
End
