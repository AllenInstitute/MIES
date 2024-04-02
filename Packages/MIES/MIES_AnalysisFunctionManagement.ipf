#pragma TextEncoding="UTF-8"
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
Function AFM_CallAnalysisFunctions(device, eventType)
	string   device
	variable eventType

	variable i, valid_f1, valid_f2, valid_f3, ret, DAC, sweepsInSet
	variable realDataLengthAD, realDataLengthDA, sweepNo, fifoPositionAD, fifoPositionDA, sampleIntDA, sampleIntAD
	string func, msg
	STRUCT AnalysisFunction_V3 s

	if(DAG_GetNumericalValue(device, "Check_Settings_SkipAnalysFuncs"))
		return 0
	endif

	NVAR   count        = $GetCount(device)
	WAVE   statusHS     = DAG_GetChannelState(device, CHANNEL_TYPE_HEADSTAGE)
	WAVE/T allSetNames  = DAG_GetChannelTextual(device, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE)
	WAVE   setEventFlag = GetSetEventFlag(device)

	WAVE/T analysisFunctions = GetAnalysisFunctionStorage(device)

	if(eventType == PRE_DAQ_EVENT || eventType == PRE_SET_EVENT || eventType == PRE_SWEEP_CONFIG_EVENT)
		realDataLengthAD = NaN
		realDataLengthDA = NaN
		fifoPositionAD   = NaN
		fifoPositionDA   = NaN
	else
		realDataLengthAD = HW_GetEffectiveADCWaveLength(device, DATA_ACQUISITION_MODE)
		realDataLengthDA = HW_GetEffectiveDACWaveLength(device, DATA_ACQUISITION_MODE)
		fifoPositionAD   = ROVar(GetFifoPosition(device))
		fifoPositionDA   = HW_GetDAFifoPosition(device, DATA_ACQUISITION_MODE)
	endif

	for(i = 0; i < NUM_HEADSTAGES; i += 1)

		if(!statusHS[i])
			continue
		endif

		DAC = AFH_GetDACFromHeadstage(device, i)

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

		if((eventType == PRE_SET_EVENT && !setEventFlag[DAC][%PRE_SET_EVENT])     \
		   || (eventType == POST_SET_EVENT && !setEventFlag[DAC][%POST_SET_EVENT]))
			sprintf msg, "Skipping event \"%s\" on headstage %d", StringFromList(eventType, EVENT_NAME_LIST), i
			DEBUGPRINT(msg)
			continue
		endif

		sampleIntDA = NaN
		sampleIntAD = NaN

		// @todo Use AS_GetSweepNumber once acquisition state handling supports PRE/POST SET_EVENTS
		switch(eventType)
			case PRE_DAQ_EVENT:
			case PRE_SWEEP_CONFIG_EVENT:
			case PRE_SET_EVENT: // fallthrough-by-design
				sweepNo = DAG_GetNumericalValue(device, "SetVar_Sweep")
				WAVE/Z dataWave = $""
				break
			case MID_SWEEP_EVENT:
				if(fifoPositionAD == 0)
					// no data yet to analyse
					return 0
				endif
				sweepNo = DAG_GetNumericalValue(device, "SetVar_Sweep")
				WAVE/Z/WAVE scaledDataWave = GetScaledDataWave(device)
				if(!WaveExists(scaledDataWave))
					BUG("AnalysisFunctionCall: Expected scaledData wave, could not find it. Event:" + num2istr(eventType))
					return NaN
				endif

				WAVE config = GetDAQConfigWave(device)
				[sampleIntDA, sampleIntAD] = AFH_GetSampleIntervalsFromSweep(scaledDataWave, config)
				WAVE dataWave = scaledDataWave
				break
			case POST_SWEEP_EVENT:
			case POST_SET_EVENT:
			case POST_DAQ_EVENT: // fallthrough-by-design
				sweepNo = DAG_GetNumericalValue(device, "SetVar_Sweep") - 1
				WAVE/Z/T sweepWave = GetSweepWave(device, sweepNo)
				if(!WaveExists(sweepWave))
					BUG("AnalysisFunctionCall: Expected sweep wave, could not find it. Event:" + num2istr(eventType))
					return NaN
				endif
				WAVE config = GetConfigWave(sweepWave)
				[sampleIntDA, sampleIntAD] = AFH_GetSampleIntervalsFromSweep(sweepWave, config)
				WAVE dataWave = sweepWave
				break
			default:
				ASSERT(0, "Invalid eventType")
				break
		endswitch

		FUNCREF AFP_ANALYSIS_FUNC_V1 f1 = $func
		FUNCREF AFP_ANALYSIS_FUNC_V2 f2 = $func
		FUNCREF AFP_ANALYSIS_FUNC_V3 f3 = $func

		valid_f1 = FuncRefIsAssigned(FuncRefInfo(f1))
		valid_f2 = FuncRefIsAssigned(FuncRefInfo(f2))
		valid_f3 = FuncRefIsAssigned(FuncRefInfo(f3))

		// all functions are valid

		ret = NaN
		AssertOnAndClearRTError()
		try

			if(valid_f1)
				WAVE DAQDataWave = GetDAQDataWave(device, DATA_ACQUISITION_MODE)
				ChangeWaveLock(DAQDataWave, 1)
				ret = f1(device, eventType, DAQDataWave, i); AbortOnRTE
			elseif(valid_f2)
				WAVE DAQDataWave = GetDAQDataWave(device, DATA_ACQUISITION_MODE)
				ChangeWaveLock(DAQDataWave, 1)
				ret = f2(device, eventType, DAQDataWave, i, realDataLengthAD); AbortOnRTE
			elseif(valid_f3)

				if(WaveExists(dataWave))
					ChangeWaveLock(dataWave, 1)
				endif

				s.eventType = eventType
				WAVE/Z s.scaledDACWave = dataWave
				s.headstage           = i
				s.lastValidRowIndexAD = realDataLengthAD - 1
				s.lastKnownRowIndexAD = fifoPositionAD - 1
				s.lastValidRowIndexDA = realDataLengthDA - 1
				s.lastKnownRowIndexDA = fifoPositionDA - 1
				s.sampleIntervalDA    = sampleIntDA
				s.sampleIntervalAD    = sampleIntAD
				s.sweepNo             = sweepNo
				s.sweepsInSet         = sweepsInSet
				s.params              = analysisFunctions[i][ANALYSIS_FUNCTION_PARAMS]

				ret = f3(device, s); AbortOnRTE
			else
				ASSERT(0, "impossible case")
			endif
		catch
			msg = GetRTErrMessage()
			ClearRTError()
			printf "The analysis function %s aborted with error \"%s\", this is dangerous and must *not* happen!\r", func, msg

			NVAR errorCounter = $GetAnalysisFuncErrorCounter(device)
			errorCounter += 1

			// abort early
			if(eventType == PRE_DAQ_EVENT)
				ret = 1
			endif
		endtry

		if(WaveExists(dataWave))
			ChangeWaveLock(dataWave, 0)
		endif
		if(WaveExists(DAQDataWave))
			ChangeWaveLock(DAQDataWave, 0)
		endif

		// error out in CI on pending RTEs
		AssertOnAndClearRTError()

		sprintf msg, "Calling analysis function \"%s\" for event \"%s\" on headstage %d returned ret %g", func, StringFromList(eventType, EVENT_NAME_LIST), i, ret
		DEBUGPRINT(msg)

		if((eventType == PRE_DAQ_EVENT || eventType == PRE_SET_EVENT || eventType == PRE_SWEEP_CONFIG_EVENT) && ret == 1)
			return ret
		elseif(eventType == MID_SWEEP_EVENT && (ret == ANALYSIS_FUNC_RET_REPURP_TIME || ret == ANALYSIS_FUNC_RET_EARLY_STOP))
			return ret
		endif
	endfor

	return 0
End

/// @brief Update the analysis function storage wave from the stimset waves notes
///
/// We are called earlier than DAP_CheckSettings() so we can not rely on anything setup in a sane way.
Function AFM_UpdateAnalysisFunctionWave(device)
	string device

	variable i, j, DAC
	string ctrl, setName, possibleFunctions, func

	WAVE   statusHS          = DAG_GetChannelState(device, CHANNEL_TYPE_HEADSTAGE)
	WAVE/T analysisFunctions = GetAnalysisFunctionStorage(device)

	analysisFunctions = ""
	possibleFunctions = AFH_GetAnalysisFunctions(ANALYSIS_FUNCTION_VERSION_ALL)

	for(i = 0; i < NUM_HEADSTAGES; i += 1)

		if(!statusHS[i])
			continue
		endif

		DAC = AFH_GetDACFromHeadstage(device, i)

		// ignore unassociated DACs
		if(!IsFinite(DAC))
			continue
		endif

		ctrl = GetPanelControl(DAC, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE)
		// deliberately not using the GUI state wave
		setName = GetPopupMenuString(device, ctrl)

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
