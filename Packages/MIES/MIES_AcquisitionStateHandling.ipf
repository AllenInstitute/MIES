#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_ACQSTATE
#endif

/// @file MIES_AcquisitionStateHandling.ipf
/// @brief __AS__ Acquisition state handling

/// @brief Get the acquisition state as string
Function/S AS_StateToString(variable acqState)
	switch(acqState)
		case AS_INACTIVE:
			return "AS_INACTIVE"
			break
		case AS_PRE_DAQ:
			return "AS_PRE_DAQ"
			break
		case AS_PRE_SWEEP:
			return "AS_PRE_SWEEP"
			break
		case AS_MID_SWEEP:
			return "AS_MID_SWEEP"
			break
		case AS_POST_SWEEP:
			return "AS_POST_SWEEP"
			break
		case AS_ITI:
			return "AS_ITI"
			break
		case AS_POST_DAQ:
			return "AS_POST_DAQ"
			break
		default:
			ASSERT(0, "Invalid acqState")
	endswitch
End

/// @brief Takes care of (possible) acquisition state transitions
///
/// We track the acquisition state so that we can do certain actions only in certain states.
///
/// @param panelTitle  device
/// @param newAcqState One of @ref AcquisitionStates
/// @param call        [optional, defaults to false]
Function AS_HandlePossibleTransition(string panelTitle, variable newAcqState, [variable call])

	variable oldAcqState

	NVAR acqState = $GetAcquisitionState(panelTitle)

	if(ParamIsDefault(call))
		call = 1
	else
		call = !!call
	endif

	oldAcqState = acqState
	acqState = newAcqState

	if(oldAcqState == AS_PRE_SWEEP && newAcqState == AS_MID_SWEEP)
		ED_MarkSweepStart(panelTitle)
	endif

	if(!call)
		return 0
	endif

#ifdef AUTOMATED_TESTING
	AS_CheckStateTransition(oldAcqState, newAcqState)
#endif

	switch(newAcqState)
		case AS_INACTIVE:
			break
		case AS_PRE_DAQ:
			return AFM_CallAnalysisFunctions(panelTitle, PRE_DAQ_EVENT)
			break
		case AS_PRE_SWEEP:
			return AFM_CallAnalysisFunctions(panelTitle, PRE_SWEEP_EVENT)
			break
		case AS_MID_SWEEP:
			if(oldAcqState == AS_MID_SWEEP)
				return AFM_CallAnalysisFunctions(panelTitle, MID_SWEEP_EVENT)
			endif
			break
		case AS_POST_SWEEP:
			return AFM_CallAnalysisFunctions(panelTitle, POST_SWEEP_EVENT)
			break
		case AS_ITI:
			// nothing to do
			break
		case AS_POST_DAQ:
			return AFM_CallAnalysisFunctions(panelTitle, POST_DAQ_EVENT)
			break
		default:
			ASSERT(0, "Invalid acqState")
	endswitch
End

/// @brief Check the acquisition state transition between old and new
///
/// The following graph shows the allowed transitions for all states.
///
/// \rst
/// .. image:: /dot/acquisition-state-transitions.svg
///    :width: 300 px
///    :align: center
/// \endrst
static Function AS_CheckStateTransition(variable oldAcqState, variable newAcqState)

	string msg
	sprintf msg, "Old %s -> New %s\r", AS_StateToString(oldAcqState), AS_StateToString(newAcqState)
	DEBUGPRINT(msg)

	switch(oldAcqState)
		case AS_INACTIVE:
			AS_EnsureCorrectState(oldAcqState, newAcqState, {AS_PRE_DAQ})
			break
		case AS_PRE_DAQ:
			AS_EnsureCorrectState(oldAcqState, newAcqState, {AS_PRE_SWEEP})
			break
		case AS_PRE_SWEEP:
			AS_EnsureCorrectState(oldAcqState, newAcqState, {AS_MID_SWEEP})
			break
		case AS_MID_SWEEP:
			AS_EnsureCorrectState(oldAcqState, newAcqState, {AS_MID_SWEEP, AS_POST_SWEEP})
			break
		case AS_POST_SWEEP:
			AS_EnsureCorrectState(oldAcqState, newAcqState, {AS_PRE_SWEEP, AS_ITI, AS_POST_DAQ})
			break
		case AS_ITI:
			AS_EnsureCorrectState(oldAcqState, newAcqState, {AS_PRE_SWEEP, AS_POST_DAQ})
			break
		case AS_POST_DAQ:
			AS_EnsureCorrectState(oldAcqState, newAcqState, {AS_INACTIVE})
			break
		default:
			ASSERT(0, "Invalid oldAcqState")
	endswitch
End

/// @brief Check that the state transition is faithful which means that `newAcqState`
///        must be one of `candidates`
static Function AS_EnsureCorrectState(variable oldAcqState, variable newAcqState, WAVE candidates)

	string msg

	Make/FREE/T/N=(DimSize(candidates, ROWS)) candidatesLabel = AS_StateToString(candidates[p])

	sprintf msg, "Invalid state transition: old %s, new %s, candidates %s\r", AS_StateToString(oldAcqState), AS_StateToString(newAcqState), TextWaveToList(candidatesLabel, ";")
	ASSERT(IsFinite(GetRowIndex(candidates, val = newAcqState)), msg)
End

// @todo why is that now duplicated wrt AFH_GetLastSweepAcquired??
Function AS_GetCurrentSweepNumber(string panelTitle)

	variable acqState, sweepNo

	acqState = ROVAR(GetAcquisitionState(panelTitle))

	// same sweep number derivation logic as in AFM_CallAnalysisFunction
	switch(acqState)
		case AS_INACTIVE:
		case AS_PRE_DAQ:
		case AS_PRE_SWEEP:
		case AS_MID_SWEEP:  // fallthrough-by-design
			sweepNo = DAG_GetNumericalValue(panelTitle, "SetVar_Sweep")
			break
		case AS_POST_SWEEP:
		case AS_ITI:
		case AS_POST_DAQ:  // fallthrough-by-design
			sweepNo = DAG_GetNumericalValue(panelTitle, "SetVar_Sweep") - 1
			break
		default:
			ASSERT(0, "Invalid acqState")
	endswitch

	ASSERT(IsValidSweepNumber(sweepNo), "Could not derive a valid sweep number")

	return sweepNo
End
