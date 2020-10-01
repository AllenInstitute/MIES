#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_AFM
#endif

/// @file MIES_AnalysisFunctionManagement.ipf
/// @brief __AFM__ Analysis functions routines

/// @brief Call the analysis function associated with the stimset from the wavebuilder
///
/// @return Valid analysis function return types, zero otherwise, see also @ref AnalysisFunctionReturnTypes
Function AFM_CallAnalysisFunctions(panelTitle, eventType)
	string panelTitle
	variable eventType

	variable i, valid_f1, valid_f2, valid_f3, ret, DAC, sweepsInSet
	variable realDataLength, sweepNo, fifoPosition
	string func, msg
	struct AnalysisFunction_V3 s

	if(DAG_GetNumericalValue(panelTitle, "Check_Settings_SkipAnalysFuncs"))
		return 0
	endif

	NVAR count = $GetCount(panelTitle)
	NVAR stopCollectionPoint = $GetStopCollectionPoint(panelTitle)
	WAVE statusHS = DAG_GetChannelState(panelTitle, CHANNEL_TYPE_HEADSTAGE)
	WAVE/T allSetNames = DAG_GetChannelTextual(panelTitle, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE)
	fifoPosition = ROVar(GetFifoPosition(panelTitle))
	WAVE/T analysisFunctions = GetAnalysisFunctionStorage(panelTitle)

	if(eventType == PRE_SET_EVENT || eventType == POST_SET_EVENT)
		WAVE setEventFlagWithoutAlreadyFired = AFM_GetEventFlags(panelTitle, eventType, statusHS, count)
	endif

	if(eventType == PRE_DAQ_EVENT || eventType == PRE_SET_EVENT)
		realDataLength = NaN
	else
		realDataLength = stopCollectionPoint
	endif

	// use safe defaults
	if(eventType == PRE_DAQ_EVENT || eventType == PRE_SET_EVENT || eventType == PRE_SWEEP_EVENT)
		fifoPosition = NaN
	endif

	for(i = 0; i < NUM_HEADSTAGES; i += 1)

		if(!statusHS[i])
			continue
		endif

		DAC = AFH_GetDACFromHeadstage(panelTitle, i)

		if(!cmpstr(allSetNames[DAC], STIMSET_TP_WHILE_DAQ, 1))
			continue
		endif

		// always prefer the generic event over the specialized ones
		func = analysisFunctions[i][GENERIC_EVENT]

		if(isEmpty(func))
			func = analysisFunctions[i][eventType]
		endif

		if(isEmpty(func))
			continue
		endif

		if((eventType == PRE_SET_EVENT && !setEventFlagWithoutAlreadyFired[i][%PRE_SET_EVENT]) \
		   || (eventType == POST_SET_EVENT && !setEventFlagWithoutAlreadyFired[i][%POST_SET_EVENT]))
			sprintf msg, "Skipping event \"%s\" on headstage %d", StringFromList(eventType, EVENT_NAME_LIST), i
			DEBUGPRINT(msg)
			continue
		endif

		switch(eventType)
			case PRE_DAQ_EVENT:
			case PRE_SWEEP_EVENT:
			case PRE_SET_EVENT:
			case MID_SWEEP_EVENT: // fallthrough-by-design
				sweepNo = DAG_GetNumericalValue(panelTitle, "SetVar_Sweep")
				WAVE scaledDataWave = GetScaledDataWave(panelTitle)
				break
			case POST_SWEEP_EVENT:
			case POST_SET_EVENT:
			case POST_DAQ_EVENT: // fallthrough-by-design
				sweepNo = DAG_GetNumericalValue(panelTitle, "SetVar_Sweep") - 1
				WAVE scaledDataWave = GetSweepWave(panelTitle, sweepNo)
				break
			default:
				ASSERT(0, "Invalid eventType")
				break
		endswitch

		FUNCREF AF_PROTO_ANALYSIS_FUNC_V1 f1 = $func
		FUNCREF AF_PROTO_ANALYSIS_FUNC_V2 f2 = $func
		FUNCREF AF_PROTO_ANALYSIS_FUNC_V3 f3 = $func

		valid_f1 = FuncRefIsAssigned(FuncRefInfo(f1))
		valid_f2 = FuncRefIsAssigned(FuncRefInfo(f2))
		valid_f3 = FuncRefIsAssigned(FuncRefInfo(f3))

		// all functions are valid
		WAVE DAQDataWave = GetHardwareDataWave(panelTitle)
		ChangeWaveLock(DAQDataWave, 1)

		ChangeWaveLock(scaledDataWave, 1)

		ret = NaN
		try
			ClearRTError()
			if(valid_f1)
				ret = f1(panelTitle, eventType, DAQDataWave, i); AbortOnRTE
			elseif(valid_f2)
				ret = f2(panelTitle, eventType, DAQDataWave, i, realDataLength); AbortOnRTE
			elseif(valid_f3)
				s.eventType          = eventType
				WAVE s.rawDACWave    = DAQDataWave
				WAVE s.scaledDACWave = scaledDataWave
				s.headstage          = i
				s.lastValidRowIndex  = realDataLength - 1
				s.lastKnownRowIndex  = fifoPosition - 1
				s.sweepNo            = sweepNo
				s.sweepsInSet        = sweepsInSet
				s.params             = analysisFunctions[i][ANALYSIS_FUNCTION_PARAMS]

				ret = f3(panelTitle, s); AbortOnRTE
			else
				ASSERT(0, "impossible case")
			endif
		catch
			msg   = GetRTErrMessage()
			ClearRTError()
			printf "The analysis function %s aborted with error \"%s\", this is dangerous and must *not* happen!\r", func, msg

			NVAR errorCounter = $GetAnalysisFuncErrorCounter(panelTitle)
			errorCounter += 1

			// abort early
			if(eventType == PRE_DAQ_EVENT)
				ret = 1
			endif
		endtry

		ChangeWaveLock(DAQDataWave, 0)
		ChangeWaveLock(scaledDataWave, 0)

		sprintf msg, "Calling analysis function \"%s\" for event \"%s\" on headstage %d returned ret %d", func, StringFromList(eventType, EVENT_NAME_LIST), i, ret
		DEBUGPRINT(msg)

		if((eventType == PRE_DAQ_EVENT || eventType == PRE_SET_EVENT) && ret == 1)
			return ret
		elseif(eventType == MID_SWEEP_EVENT && (ret == ANALYSIS_FUNC_RET_REPURP_TIME || ret == ANALYSIS_FUNC_RET_EARLY_STOP))
			return ret
		endif
	endfor

	if(eventType == PRE_SET_EVENT || eventType == POST_SET_EVENT)
		AFM_SetHistoryEventFillIn(panelTitle, eventType, statusHS, count, setEventFlagWithoutAlreadyFired)
	endif

	return 0
End

/// @brief Update the analysis function storage wave from the stimset waves notes
///
/// We are called earlier than DAP_CheckSettings() so we can not rely on anything setup in a sane way.
Function AFM_UpdateAnalysisFunctionWave(panelTitle)
	string panelTitle

	variable i, j, DAC
	string ctrl, setName, possibleFunctions, func

	WAVE statusHS            = DAG_GetChannelState(panelTitle, CHANNEL_TYPE_HEADSTAGE)
	WAVE/T analysisFunctions = GetAnalysisFunctionStorage(panelTitle)

	analysisFunctions = ""
	possibleFunctions = AFH_GetAnalysisFunctions(ANALYSIS_FUNCTION_VERSION_ALL)

	for(i = 0; i < NUM_HEADSTAGES; i += 1)

		if(!statusHS[i])
			continue
		endif

		DAC = AFH_GetDACFromHeadstage(panelTitle, i)

		// ignore unassociated DACs
		if(!IsFinite(DAC))
			continue
		endif

		ctrl = GetPanelControl(DAC, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE)
		// deliberately not using the GUI state wave
		setName = GetPopupMenuString(panelTitle, ctrl)

		WAVE/Z stimSet = WB_CreateAndGetStimSet(setName)

		if(!WaveExists(stimSet))
			continue
		endif

		for(j = 0; j < TOTAL_NUM_EVENTS; j += 1)
			func = ExtractAnalysisFuncFromStimSet(stimSet, j)

			if(WhichListItem(func, possibleFunctions) == -1) // not valid
				continue
			endif

			analysisFunctions[i][j] = func
		endfor

		analysisFunctions[i][ANALYSIS_FUNCTION_PARAMS] = ExtractAnalysisFunctionParams(stimSet)
	endfor
End

static Function AFM_SetHistoryEventFillIn(string panelTitle, variable eventType, WAVE statusHS, variable count, WAVE setEventFlagWithoutAlreadyFired)

	variable index, sweepNo, i, DAC

	if(Sum(setEventFlagWithoutAlreadyFired) == 0)
		return NaN
	endif

	// skipping the first sweep backwards results in count being  -1
	index = limit(count, 0, inf)

	WAVE setEventHistory = GetSetEventHistory(panelTitle)
	EnsureLargeEnoughWave(setEventHistory, minimumSize=index)

	switch(eventType)
		case PRE_SET_EVENT:
			setEventHistory[index][][%PRE_SET_EVENT]  += setEventFlagWithoutAlreadyFired[q][r]
			break
		case POST_SET_EVENT:
			setEventHistory[index][][%POST_SET_EVENT] += setEventFlagWithoutAlreadyFired[q][r]
			break
		default:
			ASSERT(0, "Unsupported event type")
	endswitch

	SetNumberInWaveNote(setEventHistory, NOTE_INDEX, index + 1)
End

static Function/WAVE AFM_GetEventFlags(string panelTitle, variable eventType, WAVE statusHS, variable count)

	variable i, result, DAC
	string msg

	WAVE setEventFlag = GetSetEventFlag(panelTitle)

	switch(eventType)
		case PRE_SET_EVENT:
			setEventFlag[][%PRE_SET_EVENT] = 0
			break
		case POST_SET_EVENT:
			setEventFlag[][%POST_SET_EVENT] = 0
			break
		default:
			ASSERT(0, "Unsupported event type")
	endswitch

	for(i = 0; i < NUM_HEADSTAGES; i += 1)

		if(!statusHS[i])
			continue
		endif

		DAC = AFH_GetDACFromHeadstage(panelTitle, i)

		switch(eventType)
			case PRE_SET_EVENT:
				result = IDX_DetIfCountIsAtstimsetSetBorder(panelTitle, count - 1, DAC)
				setEventFlag[i][%PRE_SET_EVENT] = result
				break
			case POST_SET_EVENT:
				result = count >=0 && IDX_DetIfCountIsAtstimsetSetBorder(panelTitle, count, DAC)
				setEventFlag[i][%POST_SET_EVENT] = result
				break
			default:
				ASSERT(0, "Unsupported event type")
		endswitch
	endfor

	WAVE alreadyFired = AFM_EventAlreadyFired(panelTitle, count)

	sprintf msg, "count %d, setEventFlag PRE [%g, %g], POST [%g, %g], alreadyFired PRE [%g, %g], POST [%g, %g]\r", count, setEventFlag[0][%PRE_SET_EVENT], setEventFlag[1][%PRE_SET_EVENT], setEventFlag[0][%POST_SET_EVENT], setEventFlag[1][%POST_SET_EVENT], alreadyFired[0][%PRE_SET_EVENT], alreadyFired[1][%PRE_SET_EVENT], alreadyFired[0][%POST_SET_EVENT], alreadyFired[1][%POST_SET_EVENT]
	DEBUGPRINT(msg)

	Duplicate/FREE setEventFlag, setEventFlagWithoutAlreadyFired

	switch(eventType)
		case PRE_SET_EVENT:
			setEventFlagWithoutAlreadyFired[][%PRE_SET_EVENT] = !alreadyFired[p][q] && setEventFlag[p][q]
			break
		case POST_SET_EVENT:
			setEventFlagWithoutAlreadyFired[][%POST_SET_EVENT] = !alreadyFired[p][q] && setEventFlag[p][q]
			break
		default:
			ASSERT(0, "Unsupported event type")
	endswitch

	return setEventFlagWithoutAlreadyFired
End

/// @brief Return a wave with NUM_HEADSTAGES rows and two columns with boolean
/// values denoting if the PRE_SET_EVENT/POST_SET_EVENT were already fired once.
static Function/WAVE AFM_EventAlreadyFired(string panelTitle, variable count)

	variable index

	WAVE setEventHistory = GetSetEventHistory(panelTitle)

	Make/FREE/N=(NUM_HEADSTAGES, 2) result = 0

	SetDimLabel COLS, 0, PRE_SET_EVENT, result
	SetDimLabel COLS, 1, POST_SET_EVENT, result

	index = limit(count, 0, inf)

	result[][] = setEventHistory[index][p][q]

	return result
End
