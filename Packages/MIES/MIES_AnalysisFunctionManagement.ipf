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

	variable error, i, valid_f1, valid_f2, ret
	string func, setName

	if(GetCheckBoxState(panelTitle, "Check_Settings_SkipAnalysFuncs"))
		return 0
	endif

	NVAR count = $GetCount(panelTitle)
	NVAR stopCollectionPoint = $GetStopCollectionPoint(panelTitle)
	WAVE statusHS = DC_ControlStatusWaveCache(panelTitle, CHANNEL_TYPE_HEADSTAGE)

	for(i = 0; i < NUM_HEADSTAGES; i += 1)

		if(!statusHS[i])
			continue
		endif

		AFM_GetAnalysisFuncFromHS(panelTitle, i, eventType, func, setName)

		if(isEmpty(func) || isEmpty(setName))
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
				if(mod(count + 1, IDX_NumberOfTrialsInSet(panelTitle, setName)) != 0)
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

		if(!valid_f1 && !valid_f2) // not a valid analysis function
			continue
		endif

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
		elseif(eventType == MID_SWEEP_EVENT && ret == ANALYSIS_FUNC_RET_REPURP_TIME)
			return ret
		endif
	endfor

	return 0
End

/// @brief Get the analysis function and the stimset from the headstage
///
/// We are called earlier than DAP_CheckSettings() so we can not rely on anything setup in a sane way.
///
/// @param[in]  panelTitle Device
/// @param[in]  headStage  Headstage
/// @param[in]  eventType  One of @ref EVENT_TYPE_ANALYSIS_FUNCTIONS
/// @param[out] func       Analysis function name
/// @param[out] setName    Name of the Stim set
static Function AFM_GetAnalysisFuncFromHS(panelTitle, headStage, eventType, func, setName)
	string panelTitle
	variable headStage, eventType
	string &func, &setName

	string ctrl, dacWave, setNameFromCtrl
	variable clampMode, DACchannel

	func    = ""
	setName = ""

	WAVE chanAmpAssign = GetChanAmpAssign(panelTitle)

	clampMode = DAP_MIESHeadstageMode(panelTitle, headStage)
	if(clampMode == V_CLAMP_MODE)
		DACchannel = ChanAmpAssign[%VC_DA][headStage]
	elseif(clampMode == I_CLAMP_MODE)
		DACchannel = ChanAmpAssign[%IC_DA][headStage]
	else
		return NaN
	endif

	if(!IsFinite(DACchannel))
		return NaN
	endif

	ctrl = GetPanelControl(DACchannel, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE)
	setNameFromCtrl = GetPopupMenuString(panelTitle, ctrl)

	if(!cmpstr(setNameFromCtrl, NONE))
		return NaN
	endif

	WAVE/Z stimSet = WB_CreateAndGetStimSet(setNameFromCtrl)

	if(!WaveExists(stimSet))
		return NaN
	endif

	func    = ExtractAnalysisFuncFromStimSet(stimSet, eventType)
	setName = setNameFromCtrl
End
