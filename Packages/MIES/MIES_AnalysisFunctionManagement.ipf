#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
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

	variable error, i, valid_f1, valid_f2, ret, DAC
	string func, setName, ctrl

	WAVE GuiState = GetDA_EphysGuiStateNum(panelTitle)

	if(GuiState[0][%Check_Settings_SkipAnalysFuncs])
		return 0
	endif

	NVAR count = $GetCount(panelTitle)
	NVAR stopCollectionPoint = $GetStopCollectionPoint(panelTitle)
	WAVE statusHS = DAG_GetChannelState(panelTitle, CHANNEL_TYPE_HEADSTAGE)

	WAVE/T analysisFunctions = GetAnalysisFunctionStorage(panelTitle)

	for(i = 0; i < NUM_HEADSTAGES; i += 1)

		if(!statusHS[i])
			continue
		endif

		func = analysisFunctions[i][eventType]

		if(isEmpty(func))
			continue
		endif

		switch(eventType)
			case PRE_DAQ_EVENT:
			case MID_SWEEP_EVENT:
			case POST_SWEEP_EVENT:
			case POST_DAQ_EVENT:
				// nothing to do
				break
			case POST_SET_EVENT:
				DAC = AFH_GetDACFromHeadstage(panelTitle, i)

				ctrl    = GetPanelControl(DAC, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE)
				// deliberately not using the GUI state wave
				setName = GetPopupMenuString(panelTitle, ctrl)

				if(mod(count + 1, IDX_NumberOfSweepsInSet(setName)) != 0)
					continue
				endif
				break
			default:
				ASSERT(0, "Invalid eventType")
				break
		endswitch

		FUNCREF AF_PROTO_ANALYSIS_FUNC_V1 f1 = $func
		FUNCREF AF_PROTO_ANALYSIS_FUNC_V2 f2 = $func

		valid_f1 = FuncRefIsAssigned(FuncRefInfo(f1))
		valid_f2 = FuncRefIsAssigned(FuncRefInfo(f2))

		// all functions are valid

		WAVE ITCDataWave = GetITCDataWave(panelTitle)
		SetWaveLock 1, ITCDataWave

		ret = NaN
		try
			if(valid_f1)
				ret = f1(panelTitle, eventType, ITCDataWave, i); AbortOnRTE
			elseif(valid_f2)
				ret = f2(panelTitle, eventType, ITCDataWave, i, stopCollectionPoint - 1); AbortOnRTE
			else
				ASSERT(0, "impossible case")
			endif
		catch
			error = GetRTError(1)
			printf "The analysis function %s aborted, this is dangerous and must *not* happen!\r", func
		endtry

		SetWaveLock 0, ITCDataWave

		if(eventType == PRE_DAQ_EVENT && ret == 1)
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
	endfor
End
