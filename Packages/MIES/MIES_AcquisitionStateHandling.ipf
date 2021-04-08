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
		case AS_EARLY_CHECK:
			return "AS_EARLY_CHECK"
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
/// We track the acquisition state so that we can perform actions for state transitions when required.
///
/// @param panelTitle  device
/// @param newAcqState One of @ref AcquisitionStates
/// @param call        [optional, defaults to false] Call analysis function
///                    which is connected to the state transition.
Function AS_HandlePossibleTransition(string panelTitle, variable newAcqState, [variable call])

	variable oldAcqState
	string msg

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

#ifdef AUTOMATED_TESTING
	AS_RecordStateTransition(oldAcqState, newAcqState)
#endif

	if(!AS_CheckStateTransition(oldAcqState, newAcqState))
		sprintf msg, "The state transition %s -> %s is not expected.\r", AS_StateToString(oldAcqState), AS_StateToString(newAcqState)
		BUG(msg)
	endif

	if(!call)
		return 0
	endif

	switch(newAcqState)
		case AS_INACTIVE:
		case AS_EARLY_CHECK:
			// do nothing
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

	WAVE validAcqStateTransitions = GetValidAcqStateTransitions()

	return (validAcqStateTransitions[oldAcqState][newAcqState] == 1)
End

/// @brief Return the sweep number of the currently active sweep
///
/// The ITI between sweeps belongs to the earlier sweep. The main use is to add
/// a labnotebook entry during data acquisition. The similiar named function
/// AFH_GetLastSweepAcquired() returns the last acquired sweep in comparison.
Function AS_GetSweepNumber(string panelTitle)

	variable acqState, sweepNo

	acqState = ROVAR(GetAcquisitionState(panelTitle))

	// same sweep number derivation logic as in AFM_CallAnalysisFunctions
	switch(acqState)
		case AS_INACTIVE:
		case AS_EARLY_CHECK:
			ASSERT(0, "Can not query the sweep number without data acqisition running")
			break
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

static Function AS_RecordStateTransition(variable oldAcqState, variable newAcqState)

	variable index

	WAVE wv = GetAcqStateTracking()
	index = GetNumberFromWaveNote(wv, NOTE_INDEX)

	EnsureLargeEnoughWave(wv, dimension = ROWS, minimumSize = index)
	wv[index][%OLD] = oldAcqState
	wv[index][%NEW] = newAcqState

	SetNumberInWaveNote(wv, NOTE_INDEX, ++index)
End

/// @brief Return a wave with all encountered state transitions
///
/// Requires that they were recorded with AS_RecordStateTransition().
Function/WAVE AS_GenerateEncounteredTransitions()
	variable numEntries, i, j

	WAVE acqStateTracking = GetAcqStateTracking()
	numEntries = GetNumberFromWaveNote(acqStateTracking, NOTE_INDEX)

	WAVE validAcqStateTransitions = GetValidAcqStateTransitions()

	Duplicate/FREE validAcqStateTransitions, acqStateTransitions

	acqStateTransitions = 0

	for(i = 0; i < numEntries; i += 1)
		acqStateTransitions[acqStateTracking[i][%OLD]][acqStateTracking[i][%NEW]] = 1
	endfor

	// now output all encountered transitions from old to new
	printf "Encountered state transitions:\r"
	for(i = 0; i < AS_NUM_STATES; i += 1)
		for(j = 0; j < AS_NUM_STATES; j += 1)
			if(acqStateTransitions[i][j])
				printf "%s -> %s\r", AS_StateToString(i), AS_StateToString(j)
			endif
		endfor
	endfor

	return acqStateTransitions
End
