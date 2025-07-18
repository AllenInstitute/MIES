#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors = 1

#ifdef AUTOMATED_TESTING
#pragma ModuleName = MIES_AF
#endif // AUTOMATED_TESTING

/// @file MIES_AnalysisFunctions.ipf
/// @brief __AF__ Analysis functions to be called during data acquisition
///
/// @sa MIES_AnalysisFunctionPrototypes.ipf
///
/// Users can implement functions which are called at certain events for each
/// data acquisition cycle. See TestAnalysisFunction_V3() for an example.
///
/// @anchor AnalysisFunction_V3DescriptionTable
///
/// \rst
///
/// .. image:: /svg/analysis-functions-calls-during-RA-stages.svg
///    :width: 300 px
///    :align: center
///
/// =================== ============================================== ================================================================= =============
/// Event                Description                                    Specialities                                                      User epochs
/// =================== ============================================== ================================================================= =============
/// Pre DAQ              Before any DAQ occurs                          Called before the settings are validated completely, only the     No
///                                                                     analysis parameters are validated if present. With Indexing ON,
///                                                                     only the analysis function of the first stimset will receive
///                                                                     that event.
/// Pre Set              Before a new set starts                        None                                                              Write
/// Pre Sweep Config     Before the sweep is configured                 None                                                              Write
/// Mid Sweep            Each time when new data is polled              Available for background DAQ only.                                Write
///                                                                     Will always be called at least once and
///                                                                     also with the full stimset acquired.
/// Post Sweep           After each sweep (before possible ITI pause)   None                                                              Read/Write
/// Post Set             After a *full* set has been acquired           This event is not always reached as the user might not acquire    Read/Write
///                                                                     all steps of a set. With indexing, locked and unlocked, only
///                                                                     the post set events for fully acquired stimsets are reached.
/// Post DAQ             After DAQ has finished and before potential    None                                                              No
///                      "TP after DAQ"
/// =================== ============================================== ================================================================= =============
///
/// User epochs will only be recorded in events which support them, see :ref:`user_epochs_doc` for more information about user epochs.
///
/// \endrst
///
/// Useful helper functions are defined in MIES_AnalysisFunctionHelpers.ipf.
///
/// The Post/Pre Sweep/Set/DAQ functions are *not* executed if a currently running sweep is aborted.
/// Changing the stimset in the Post DAQ event is only possible without indexing active.
///
/// @anchor AnalysisFunctionReturnTypes Analysis function return types
///
/// Some event types support a range of different return types which let the
/// user decide what should happen next. See also @ref
/// AnalysisFuncReturnTypesConstants. The first analysis function returning
/// with a special value requesting a DAQ stop or preventing it from starting
/// will immediately do so, thus subsequent analysis functions for other active
/// headstage will not run.
///
/// \rst
///
/// ======================================== ================= ============================================================================================
/// Value                                    Event Types       Action
/// ======================================== ================= ============================================================================================
/// NaN                                      All               Nothing
/// 0                                        All               Nothing
/// 1                                        Pre DAQ           DAQ is prevented to start
/// 1                                        Pre Set           DAQ is stopped
/// 1                                        Pre Sweep Config  DAQ is stopped
/// :cpp:var:`ANALYSIS_FUNC_RET_REPURP_TIME` Mid Sweep         Current sweep is immediately stopped. Left over time is repurposed for ITI.
/// :cpp:var:`ANALYSIS_FUNC_RET_EARLY_STOP`  Mid Sweep         Current sweep is immediately stopped without honouring the left over time in a special way.
/// ======================================== ================= ============================================================================================
///
/// \endrst
///
/// @anchor AnalysisFunctionParameters Analysis function user parameters (V3 only)
///
/// For some analysis functions it is beneficial to send in additional data
/// depending on the stimset. This is supported by adding parameters and their
/// values via AFH_AddAnalysisParameter() to the stimset, or using the
/// Wavebuilder GUI, and then querying them with the help of @ref
/// AnalysisFunctionParameterHelpers. The parameters are stored serialized in
/// the `WPT` wave, see GetWaveBuilderWaveTextParam() for the exact format. See
/// TestAnalysisFunction_V3() for an example implementation.
///
/// If you want to propose a list of parameters which should/must be present,
/// define an additional function named like your analysis function but
/// suffixed with `_GetParams` and return a comma separated list of names.
/// Adding the type is also possible via `$name:$type` syntax. The list of
/// parameter names and types is then checked before DAQ. The supplied names
/// are taken to be required by default, optional parameters, and their types,
/// must be enclosed with `[]`. The list at #ANALYSIS_FUNCTION_PARAMS_TYPES
/// holds all valid types. Case does not matter for the parameter names.
///
/// The optional function `_CheckParam` allows you to validate passed
/// parameters. In case of a valid parameter it must return an emtpy string and
/// an error message in case of failure. Parameters which don't pass can
/// neither be added to stimsets nor can they be used for data acquisition.
/// All required, optional and present parameters are passed into the check
/// function. Passing in the present parameters as well allows for dynamic
/// parameter names not known beforehand.
///
/// The optional function `_GetHelp` allows you to create per parameter help
/// text which is shown in the Wavebuilder.
///
/// Example:
///
/// \rst
/// .. code-block:: igorpro
///
///    Function MyAnalysisFunction(string device, struct AnalysisFunction_V3& s)
///        // ...
///    End
///
///    Function/S MyAnalysisFunction_GetParams()
///        return "param1:variable,[optParam1:wave]"
///    End
///
///    Function/S MyAnalysisFunction_CheckParam(string name, struct CheckParametersStruct& s)
///        variable value
///
///        strswitch(name)
///            case "param1":
///                value = AFH_GetAnalysisParamNumerical(name, s.params)
///                if(!IsFinite(value) || !(value >= 0 && value <= 100))
///                    return "Needs to be between 0 and 100."
///                endif
///                break
///            case "optParam1":
///                WAVE/Z wv = AFH_GetAnalysisParamWave(name, s.params)
///                if(!WaveExists(wv) || !IsFloatingPointWave(wv))
///                    return "Needs to be an existing floating point wave."
///                endif
///                break
///        endswitch
///
///        // default to passing for other parameters
///        return ""
///    End
///
///    Function/S MyAnalysisFunction_GetHelp(string name)
///
///        strswitch(name)
///            case "param1":
///                 return "This parameter helps in finding pink unicorns"
///                 break
///            case "optParam1":
///                 return "This parameter delivers food right to your door"
///                 break
///            default:
///                 FATAL_ERROR( "Unimplemented for parameter " + name)
///                 break
///        endswitch
///    End
///
/// \endrst

/// @name Initial parameters for stimulation
///@{
static StrConstant DEFAULT_DEVICE   = "ITC18USB_Dev_0"        ///< device device
static StrConstant STIM_SET_LOCAL   = "PulseTrain_150Hz_DA_0" ///< Initial stimulus set
static Constant    VM1_LOCAL        = -55                     ///< Initial holding potential
static Constant    VM2_LOCAL        = -85                     ///< Second holding potential to switch to
static Constant    SCALE_LOCAL      = 70                      ///< Stimulus amplitude
static Constant    NUM_SWEEPS_LOCAL = 6                       ///< Number of sweeps to acquire
static Constant    ITI_LOCAL        = 15                      ///< Inter-trial-interval
///@}

/// @name Initial settings for oodDAQ stimulation
///@{
static Constant POST_DELAY = 150 ///< Delay after stimulation event in which no other event can occur in ms
///@}

Function TestAnalysisFunction_V1(string device, variable eventType, WAVE DAQDataWave, variable headStage)

	printf "Analysis function version 1 called: device %s, eventType \"%s\", headstage %d\r", device, StringFromList(eventType, EVENT_NAME_LIST), headStage
	printf "Next sweep: %d\r", DAG_GetNumericalValue(device, "SetVar_Sweep")
End

Function TestAnalysisFunction_V2(string device, variable eventType, WAVE DAQDataWave, variable headStage, variable realDataLength)

	printf "Analysis function version 2 called: device %s, eventType \"%s\", headstage %d\r", device, StringFromList(eventType, EVENT_NAME_LIST), headStage

	return 0
End

Function TestAnalysisFunction_V3(string device, STRUCT AnalysisFunction_V3 &s)

	string names, name, type
	variable numEntries, i

	/// Query parameters
	printf "User parameters: "
	print s.params

	names = AFH_GetListOfAnalysisParamNames(s.params)

	numEntries = ItemsInList(names)
	for(i = 0; i < numEntries; i += 1)
		name = Stringfromlist(i, names)
		type = AFH_GetAnalysisParamType(name, s.params)
		strswitch(type)
			case "string":
				print AFH_GetAnalysisParamTextual(name, s.params)
				break
			case "variable":
				print AFH_GetAnalysisParamTextual(name, s.params)
				break
			case "wave":
				WAVE/Z wv = AFH_GetAnalysisParamWave(name, s.params)
				print wv
				break
			case "textwave":
				WAVE/Z/T wvText = AFH_GetAnalysisParamTextWave(name, s.params)
				print wvText
				break
			default:
				printf "Unsupported parameter type %s\r", type
				break
		endswitch
	endfor

	switch(s.eventType)
		case PRE_DAQ_EVENT:
			// code
			// can also return with != 0, see @ref AnalysisFunction_V3DescriptionTable
			break
		case PRE_SWEEP_CONFIG_EVENT:
			// code
			// can also return with != 0, see @ref AnalysisFunction_V3DescriptionTable
			break
		case PRE_SET_EVENT:
			// code
			break
		case MID_SWEEP_EVENT:
			// code
			// can also return with != 0, see @ref AnalysisFunction_V3DescriptionTable
			break
		case POST_SWEEP_EVENT:
			// code
			break
		case POST_SET_EVENT:
			// code
			break
		case POST_DAQ_EVENT:
			// code
			break
		default:
			printf "Unsupported event type %d\r", s.eventType
			break
	endswitch

	printf "Analysis function version 3 called: device %s, eventType \"%s\", headstage %d\r", device, StringFromList(s.eventType, EVENT_NAME_LIST), s.headStage

	return 0
End

/// @brief Measure the time between mid sweep calls
///
/// Used mainly for debugging.
Function MeasureMidSweepTiming_V3(string device, STRUCT AnalysisFunction_V3 &s)

	NVAR lastCall = $GetTemporaryVar()

	switch(s.eventType)
		case PRE_DAQ_EVENT:
			lastCall = NaN
			WAVE/D elapsedTime = GetElapsedTimeWave()
			elapsedTime = NaN
			SetNumberInWaveNote(elapsedTime, NOTE_INDEX, 0)
			break
		case MID_SWEEP_EVENT:
			if(IsFinite(lastCall))
				StoreElapsedTime(lastCall)
			endif

			lastCall = GetReferenceTime()
			break
		default:
			// do nothing
			break
	endswitch

	return 0
End

Function Enforce_VC(string device, variable eventType, WAVE DAQDataWave, variable headStage, variable realDataLength)

	if(eventType != PRE_DAQ_EVENT)
		return 0
	endif

	if(DAG_GetHeadstageMode(device, headStage) != V_CLAMP_MODE)
		variable DAC = AFH_GetDACFromHeadstage(device, headstage)

		string stimSetName = AFH_GetStimSetName(device, DAC, CHANNEL_TYPE_DAC)
		printf "%s on DAC %d of headstage %d requires voltage clamp mode. Change clamp mode to voltage clamp to allow data acquistion\r", stimSetName, DAC, headStage
		return 1
	endif

	return 0
End

Function Enforce_IC(string device, variable eventType, WAVE DAQDataWave, variable headStage, variable realDataLength)

	if(eventType != PRE_DAQ_EVENT)
		return 0
	endif

	if(DAG_GetHeadstageMode(device, headStage) != I_CLAMP_MODE)
		variable DAC         = AFH_GetDACFromHeadstage(device, headstage)
		string   stimSetName = AFH_GetStimSetName(device, DAC, CHANNEL_TYPE_DAC)
		printf "Stimulus set: %s on DAC: %d of headstage: %d requires current clamp mode. Change clamp mode to current clamp to allow data acquistion\r", stimSetName, DAC, headStage
		return 1
	endif

	return 0
End

// User Defined Analysis Functions
// Functions which can be assigned to various epochs of a stimulus set
// Starts with a pop-up menu to set initial parameters and then switches holding potential midway through total number of sweeps

/// @brief Force active headstages into voltage clamp
Function SetStimConfig_Vclamp(string device, variable eventType, WAVE DAQDataWave, variable headStage)

	setVClampMode()

	printf "Stimulus set running in V-Clamp on headstage: %d\r", headStage

End

/// @brief Force active headstages into current clamp
Function SetStimConfig_Iclamp(string device, variable eventType, WAVE DAQDataWave, variable headStage)

	setIClampMode()

	printf "Stimulus set running in I-Clamp on headstage: %d\r", headStage

End

/// @brief Change holding potential midway through stim set
Function ChangeHoldingPotential(string device, variable eventType, WAVE DAQDataWave, variable headStage)

	variable SweepsRemaining = switchHolding(VM2_LOCAL)

	printf "Number of stimuli remaining is: %d on headstage: %d\r", SweepsRemaining, headStage
End

/// @brief Print last Stim Set run and headstage mode and holding potential
Function LastStimSet(string device, variable eventType, WAVE DAQDataWave, variable headStage)

	PGC_SetAndActivateControl(device, "check_Settings_TPAfterDAQ", val = CHECKBOX_SELECTED)

	LastStimSetRun()

End

/// @brief GUI to set initial stimulus parameters using SetStimParam() and begin data acquisition.
/// NOTE: DATA ACQUISITION IS INTIATED AT THE END OF FUNCTION!
Function StimParamGUI()

	string StimSetList, stimSet
	variable Vm1, Scale, sweeps, ITI

	StimSetList = ST_GetStimsetList(channelType = CHANNEL_TYPE_DAC)
	stimSet     = STIM_SET_LOCAL
	Vm1         = VM1_LOCAL
	Scale       = SCALE_LOCAL
	sweeps      = NUM_SWEEPS_LOCAL
	ITI         = ITI_LOCAL

	Prompt stimSet, "Choose which stimulus set to run:", popup, StimSetList
	Prompt Vm1, "Enter initial holding potential: "
	Prompt Scale, "Enter scale of stimulation [mV]: "
	Prompt sweeps, "Enter number of sweeps to run: "
	Prompt ITI, "Enter inter-trial interval [s]: "

	DoPrompt "Choose stimulus set and enter initial parameters", stimSet, Vm1, Scale, sweeps, ITI

	if(!V_flag)
		SetStimParam(stimSet, Vm1, Scale, Sweeps, ITI)
		PGC_SetAndActivateControl(DEFAULT_DEVICE, "DataAcquireButton")
	endif
End

/// @brief Called by StimParamGUI to set initial stimulus parameters
///
/// @param stimSet Stimulus set to run
/// @param Vm1     Holding potential
/// @param Scale   Stimulus amplitude in mV
/// @param Sweeps  Number of sweeps
/// @param ITI     Inter-trial-interval
Function SetStimParam(string stimSet, variable Vm1, variable Scale, variable Sweeps, variable ITI)

	setHolding(Vm1)
	PGC_SetAndActivateControl(DEFAULT_DEVICE, "Wave_DA_All", str = stimset)
	PGC_SetAndActivateControl(DEFAULT_DEVICE, "Scale_DA_All", val = scale)
	PGC_SetAndActivateControl(DEFAULT_DEVICE, "SetVar_DataAcq_SetRepeats", val = sweeps)
	PGC_SetAndActivateControl(DEFAULT_DEVICE, "SetVar_DataAcq_ITI", val = ITI)

	InitoodDAQ()

	if(sweeps > 1)
		PGC_SetAndActivateControl(DEFAULT_DEVICE, "Check_DataAcq1_RepeatAcq", val = CHECKBOX_SELECTED)
	endif
End

/// @brief Set holding potential for active headstages
///
/// @param Vm1		   Holding potential
Function setHolding(variable Vm1)

	variable i
	WAVE statusHS = DAG_GetChannelState(DEFAULT_DEVICE, CHANNEL_TYPE_HEADSTAGE)

	for(i = 0; i < NUM_HEADSTAGES; i += 1)
		if(statusHS[i] == 1)
			PGC_SetAndActivateControl(DEFAULT_DEVICE, "slider_DataAcq_ActiveHeadstage", val = i)
			PGC_SetAndActivateControl(DEFAULT_DEVICE, "setvar_DataAcq_Hold_VC", val = Vm1)
			PGC_SetAndActivateControl(DEFAULT_DEVICE, "setvar_DataAcq_Hold_IC", val = Vm1)
		endif
	endfor
End

/// @brief Set active headstages into V-clamp
Function setVClampMode()

	variable i
	string   ctrl
	WAVE statusHS = DAG_GetChannelState(DEFAULT_DEVICE, CHANNEL_TYPE_HEADSTAGE)

	for(i = 0; i < NUM_HEADSTAGES; i += 1)
		if(statusHS[i])
			PGC_SetAndActivateControl(DEFAULT_DEVICE, "slider_DataAcq_ActiveHeadstage", val = i)
			ctrl = DAP_GetClampModeControl(V_CLAMP_MODE, i)
			PGC_SetAndActivateControl(DEFAULT_DEVICE, ctrl, val = CHECKBOX_SELECTED)
		endif
	endfor
End

/// @brief Set active headstages into I-clamp
Function setIClampMode()

	variable i
	string   ctrl

	WAVE statusHS = DAG_GetChannelState(DEFAULT_DEVICE, CHANNEL_TYPE_HEADSTAGE)

	for(i = 0; i < NUM_HEADSTAGES; i += 1)
		if(statusHS[i])
			PGC_SetAndActivateControl(DEFAULT_DEVICE, "slider_DataAcq_ActiveHeadstage", val = i)
			ctrl = DAP_GetClampModeControl(I_CLAMP_MODE, i)
			PGC_SetAndActivateControl(DEFAULT_DEVICE, ctrl, val = CHECKBOX_SELECTED)
		endif
	endfor
End

/// @brief Change holding potential on active headstages to Vm2.
/// Switch occurs after X/2 number of data sweeps. If X!/2 switchSweep = floor(X/2)
///
/// @param Vm2	Holding potential to switch to
Function switchHolding(variable Vm2)

	variable numSweeps, SweepsRemaining, switchSweep, i, clampMode

	numSweeps       = GetValDisplayAsNum(DEFAULT_DEVICE, "valdisp_DataAcq_SweepsInSet")
	SweepsRemaining = DAG_GetNumericalValue(DEFAULT_DEVICE, "valdisp_DataAcq_TrialsCountdown") - 1

	if(numSweeps <= 1)
		PGC_SetAndActivateControl(DEFAULT_DEVICE, "check_Settings_TPAfterDAQ", val = CHECKBOX_SELECTED)
		printf "Not enough sweeps were acquired, can not switch holding \r"
		return SweepsRemaining
	endif

	switchSweep = floor(numSweeps / 2)
	WAVE statusHS = DAG_GetChannelState(DEFAULT_DEVICE, CHANNEL_TYPE_HEADSTAGE)

	if(SweepsRemaining == switchSweep)
		for(i = 0; i < NUM_HEADSTAGES; i += 1)
			if(statusHS[i])
				clampMode = DAG_GetHeadstageMode(DEFAULT_DEVICE, i)
				PGC_SetAndActivateControl(DEFAULT_DEVICE, "slider_DataAcq_ActiveHeadstage", val = i)
				if(clampMode == V_CLAMP_MODE)
					PGC_SetAndActivateControl(DEFAULT_DEVICE, "setvar_DataAcq_Hold_VC", val = Vm2)
				elseif(clampMode == I_CLAMP_MODE)
					PGC_SetAndActivateControl(DEFAULT_DEVICE, "setvar_DataAcq_Hold_IC", val = Vm2)
				else
					FATAL_ERROR("Unsupported clamp mode")
				endif
			endif
		endfor
		printf "Half-way through stim set, changing holding potential to: %d\r", Vm2
	endif

	return SweepsRemaining
End

/// @brief Initialize oodDAQ settings
Function InitoodDAQ()

	// disable dDAQ

	PGC_SetAndActivateControl(DEFAULT_DEVICE, "Check_DataAcq1_DistribDaq", val = CHECKBOX_UNSELECTED)

	// make sure oodDAQ is enabled

	PGC_SetAndActivateControl(DEFAULT_DEVICE, "Check_DataAcq1_dDAQOptOv", val = CHECKBOX_SELECTED)

	// make sure Get/Set ITI is disabled

	PGC_SetAndActivateControl(DEFAULT_DEVICE, "Check_DataAcq_Get_Set_ITI", val = CHECKBOX_UNSELECTED)

	PGC_SetAndActivateControl(DEFAULT_DEVICE, "setvar_DataAcq_dDAQOptOvPost", val = POST_DELAY)

End

/// @brief Print last full stim set aqcuired
Function LastStimSetRun()

	variable LastSweep, i, holding_i
	string StimSet_i, clampHS_i

	WAVE/T textualValues   = GetLBTextualValues(DEFAULT_DEVICE)
	WAVE   numericalValues = GetLBNumericalValues(DEFAULT_DEVICE)
	WAVE   statusHS        = DAG_GetChannelState(DEFAULT_DEVICE, CHANNEL_TYPE_HEADSTAGE)
	LastSweep = AFH_GetLastSweepAcquired(DEFAULT_DEVICE)

	if(!isInteger(LastSweep))
		printf "No sweeps have been acquired"
		return LastSweep
	endif

	WAVE/T StimSet   = GetLastSetting(textualValues, LastSweep, "Stim Wave Name", DATA_ACQUISITION_MODE)
	WAVE   clampHS   = GetLastSetting(numericalValues, LastSweep, CLAMPMODE_ENTRY_KEY, DATA_ACQUISITION_MODE)
	WAVE/Z holdingVC = GetLastSetting(numericalValues, LastSweep, "V-Clamp Holding Level", DATA_ACQUISITION_MODE)
	WAVE/Z holdingIC = GetLastSetting(numericalValues, LastSweep, "I-Clamp Holding Level", DATA_ACQUISITION_MODE)

	for(i = 0; i < NUM_HEADSTAGES; i += 1)
		if(statusHS[i])
			if(clampHS[i] == V_CLAMP_MODE)
				holding_i = holdingVC[i]
				clampHS_i = "V-Clamp"
			elseif(clampHS[i] == I_CLAMP_MODE)
				holding_i = holdingIC[i]
				clampHS_i = "I-Clamp"
			endif

			printf "Stimulus Set %s completed on headstage %d in %s mode holding at %d\r", StimSet_i, i, clampHS_i, holding_i
		endif
	endfor
End

/// @brief Mid sweep analysis function which stops the sweeps and repurposes
///        the left over time at the 20th call.
///
/// This function needs to be set for Pre DAQ, Mid Sweep and Post Sweep Event.
Function TestPrematureSweepStop(string device, variable eventType, WAVE DAQDataWave, variable headStage, variable realDataLength)

	variable num
	SVAR temp = $GetTemporaryString()

	if(eventType == PRE_DAQ_EVENT || eventType == POST_SWEEP_EVENT)
		temp = "0"
		return NaN
	endif

	if(eventType == MID_SWEEP_EVENT)
		num = str2numSafe(temp)
		ASSERT(IsFinite(num), "Missing variable initialization, this analysis function must be set as pre daq, mid sweeep and post sweep")
		num += 1
		temp = num2str(num)

		if(num > 20)
			return ANALYSIS_FUNC_RET_EARLY_STOP
		endif
	endif

	return 0
End

Function preDAQ_MP_mainConfig(string device, variable eventType, WAVE DAQDataWave, variable headStage, variable realDataLength)

	ASSERT(eventType == PRE_DAQ_EVENT, "Invalid event type")

	PGC_SetAndActivateControl(device, "Check_DataAcq1_DistribDaq", val = 0)

	PGC_SetAndActivateControl(device, "Check_DataAcq1_dDAQOptOv", val = 1)

	PGC_SetAndActivateControl(device, "Check_DataAcq1_RepeatAcq", val = 1)
End

Function preDAQ_MP_IfMixed(string device, variable eventType, WAVE DAQDataWave, variable headStage, variable realDataLength)

	ASSERT(eventType == PRE_DAQ_EVENT, "Invalid event type")

	PGC_SetAndActivateControl(device, "Check_DataAcq1_DistribDaq", val = 1)

	PGC_SetAndActivateControl(device, "Check_DataAcq1_dDAQOptOv", val = 0)

	PGC_SetAndActivateControl(device, "Check_DataAcq1_RepeatAcq", val = 1)
End

Function preDAQ_MP_ChirpBlowout(string device, variable eventType, WAVE DAQDataWave, variable headStage, variable realDataLength)

	ASSERT(eventType == PRE_DAQ_EVENT, "Invalid event type")

	PGC_SetAndActivateControl(device, "Check_DataAcq1_DistribDaq", val = 0)

	PGC_SetAndActivateControl(device, "Check_DataAcq1_dDAQOptOv", val = 0)

	PGC_SetAndActivateControl(device, "Check_DataAcq1_RepeatAcq", val = 1)
End

/// @brief Analysis function to set different "DA Scale" values for a sweep
///
/// Prerequisites:
/// - Stimset with multiple but identical sweeps and testpulse-like shape. The
///   number of sweeps must be larger than the number of rows in the DAScales wave below.
/// - This stimset must have this analysis function set for the "Pre DAQ" and the "Post Sweep" Event
/// - Does currently nothing for "Mid Sweep" Event
/// - Does not support DA/AD channels not associated with a MIES headstage (aka unassociated DA/AD Channels)
/// - All active headstages must be in "Current Clamp"
Function AdjustDAScale(string device, variable eventType, WAVE DAQDataWave, variable headStage, variable realDataLength)

	variable val, index, DAC, ADC
	string ctrl, msg

	// BEGIN CHANGE ME
	MAKE/D/FREE DAScales = {-25, 25, -50, 50, -100, 100}
	// END CHANGE ME

	WAVE DAScalesIndex = GetAnalysisFuncIndexingHelper(device)

	switch(eventType)
		case PRE_DAQ_EVENT:

			if(DAG_GetHeadstageMode(device, headStage) != I_CLAMP_MODE)
				printf "The analysis function \"%s\" can only be used in Current Clamp mode.\r", GetRTStackInfo(1)
				return 1
			endif

			DAScalesIndex[headstage] = 0
			KillOrMoveToTrash(wv = GetAnalysisFuncDAScaleDeltaI(device))
			KillOrMoveToTrash(wv = GetAnalysisFuncDAScaleDeltaV(device))
			KillOrMoveToTrash(wv = GetAnalysisFuncDAScaleRes(device))
			KillWindow/Z $RESISTANCE_GRAPH
			break
		case POST_SWEEP_EVENT:
			DAScalesIndex[headstage] += 1
			break
		default:
			FATAL_ERROR("Unknown eventType")
			break
	endswitch

	DAC = AFH_GetDACFromHeadstage(device, headstage)
	ASSERT(IsFinite(DAC), "This analysis function does not work with unassociated DA channels")

	ADC = AFH_GetADCFromHeadstage(device, headstage)
	ASSERT(IsFinite(ADC), "This analysis function does not work with unassociated AD channels")

	index = DAScalesIndex[headstage]
	if(index < DimSize(DAScales, ROWS))
		ctrl = GetPanelControl(DAC, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_SCALE)
		PGC_SetAndActivateControl(device, ctrl, val = DAScales[index])
	endif

	sprintf msg, "(%s, %d): DAScale = %g", device, headstage, ((index < DimSize(DAScales, ROWS)) ? DAScales[index] : NaN)
	DEBUGPRINT(msg)

	// index equals the number of sweeps in the stimset on the last call (*post* sweep event)
	if(index > DimSize(DAScales, ROWS))
		printf "(%s): Skipping analysis function \"%s\".\r", device, GetRTStackInfo(1)
		printf "The stimset \"%s\" of headstage %d has too many sweeps, increase the size of DAScales.\r", AFH_GetStimSetName(device, DAC, CHANNEL_TYPE_DAC), headstage
		return NaN
	endif

	if(eventType == PRE_DAQ_EVENT)
		return NaN
	endif

	// only do something if we are called for the very last headstage
	if(!DAG_HeadstageIsHighestActive(device, headstage))
		return NaN
	endif

	WAVE/Z sweep = AFH_GetLastSweepWaveAcquired(device)
	ASSERT(WaveExists(sweep), "Expected a sweep for evalulation")

	WAVE numericalValues = GetLBNumericalValues(device)
	WAVE textualValues   = GetLBTextualValues(device)

	WAVE deltaV     = LBN_GetNumericWave()
	WAVE deltaI     = LBN_GetNumericWave()
	WAVE resistance = LBN_GetNumericWave()

	CalculateTPLikePropsFromSweep(numericalValues, textualValues, sweep, deltaI, deltaV, resistance)

	ED_AddEntryToLabnotebook(device, LBN_DELTA_I, deltaI, unit = "A")
	ED_AddEntryToLabnotebook(device, LBN_DELTA_V, deltaV, unit = "V")

	FitResistance(device, headstage)
End

/// Plot the resistance of the sweeps of the same SCI
///
/// Usually called by PSQ_AdjustDAScale().
Function FitResistance(string device, variable headstage, [variable showPlot, variable anaFuncType])

	variable deltaVCol, DAScaleCol, i, j, sweepNo, idx, numEntries
	variable lastWrittenSweep, sweepPassed
	string graph, textBoxString, trace, key

	if(ParamIsDefault(showPlot))
		showPlot = 1
	else
		showPlot = !!showPlot
	endif

	if(ParamIsDefault(anaFuncType))
		anaFuncType = NaN
	endif

	sweepNo = AFH_GetLastSweepAcquired(device)

	if(!IsFinite(sweepNo))
		return NaN
	endif

	WAVE   numericalValues = GetLBNumericalValues(device)
	WAVE/Z sweeps          = AFH_GetSweepsFromSameSCI(numericalValues, sweepNo, headstage)

	if(!WaveExists(sweeps))
		printf "The last sweep %d did not hold any stimset cycle information.\r", sweepNo
		ControlWindowToFront()
		return NaN
	endif

	WAVE statusHS = DAG_GetChannelState(device, CHANNEL_TYPE_HEADSTAGE)

	WAVE storageDeltaI = GetAnalysisFuncDAScaleDeltaI(device)
	WAVE storageDeltaV = GetAnalysisFuncDAScaleDeltaV(device)
	WAVE storageResist = GetAnalysisFuncDAScaleRes(device)

	lastWrittenSweep = GetNumberFromWaveNote(storageDeltaV, "Last Sweep")

	if(IsFinite(lastWrittenSweep))
		Extract/O sweeps, sweeps, sweeps > lastWrittenSweep
	endif

	idx = GetNumberFromWaveNote(storageDeltaV, NOTE_INDEX)

	numEntries = DimSize(sweeps, ROWS)
	for(i = 0; i < numEntries; i += 1)

		sweepNo = sweeps[i]
		WAVE/Z deltaI = GetLastSetting(numericalValues, sweepNo, LABNOTEBOOK_USER_PREFIX + LBN_DELTA_I, UNKNOWN_MODE)
		WAVE/Z deltaV = GetLastSetting(numericalValues, sweepNo, LABNOTEBOOK_USER_PREFIX + LBN_DELTA_V, UNKNOWN_MODE)

		if(!WaveExists(deltaI) || !WaveExists(deltaV))
			if(IsFinite(anaFuncType))
				key         = CreateAnaFuncLBNKey(anaFuncType, PSQ_FMT_LBN_SWEEP_PASS, query = 1)
				sweepPassed = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)

				if(IsFinite(sweepPassed) && !sweepPassed)
					continue
				endif
			endif

			print "Could not find all required labnotebook keys"
			ControlWindowToFront()
			continue
		endif

		EnsureLargeEnoughWave(storageDeltaI, indexShouldExist = idx, initialValue = NaN)
		EnsureLargeEnoughWave(storageDeltaV, indexShouldExist = idx, initialValue = NaN)

		storageDeltaI[idx][] = deltaI[q]
		storageDeltaV[idx][] = deltaV[q]

		idx += 1
	endfor

	SetNumberInWaveNote(storageDeltaV, NOTE_INDEX, idx)
	SetNumberInWaveNote(storageDeltaV, "Last Sweep", sweepNo)

	textBoxString = ""
	for(i = 0; i < NUM_HEADSTAGES; i += 1)
		WaveStats/Q/M=1/RMD=[][i] storageDeltaV
		if(V_npnts < 2)
			if(statusHS[i])
				storageResist[i][%Value] = deltaV[i] / deltaI[i]
				storageResist[i][%Error] = NaN

				sprintf textBoxString, "%sHS%d: no fit possible\r", textBoxString, i
			endif

			continue
		endif

		Make/FREE/N=2 coefWave
		CurveFit/Q/N=1/NTHR=1/M=0/W=2 line, kwCWave=coefWave, storageDeltaV[][i]/D/X=storageDeltaI[][i]
		WAVE/Z W_sigma = MakeWaveFree($"W_sigma")

		storageResist[i][%Value] = coefWave[1]
		storageResist[i][%Error] = W_sigma[1]

		sprintf textBoxString, "%sHS%d: %.0W1PΩ +/- %.0W1PΩ\r", textBoxString, i, storageResist[i][%Value], storageResist[i][%Error]

		WAVE fitWave = $("fit_" + NameOfWave(storageDeltaV))
		RemoveFromGraph/Z $NameOfWave(fitWave)

		WAVE curveFitWave = GetAnalysisFuncDAScaleResFit(device, i)
		Duplicate/O fitWave, curveFitWave
	endfor

	WAVE storage = LBN_GetNumericWave()
	storage[0, NUM_HEADSTAGES - 1] = storageResist[p][%Value]
	ED_AddEntryToLabnotebook(device, LBN_RESISTANCE_FIT, storage, unit = "Ohm")

	storage                        = NaN
	storage[0, NUM_HEADSTAGES - 1] = storageResist[p][%Error]
	ED_AddEntryToLabnotebook(device, LBN_RESISTANCE_FIT_ERR, storage, unit = "Ohm")

	KillOrMoveToTrash(wv = W_sigma)
	KillOrMoveToTrash(wv = fitWave)

	WAVE statusHS = DAG_GetChannelState(device, CHANNEL_TYPE_HEADSTAGE)

	if(!WindowExists(RESISTANCE_GRAPH) && showPlot)
		Display/K=1/N=$RESISTANCE_GRAPH

		for(i = 0; i < NUM_HEADSTAGES; i += 1)

			if(!statusHS[i])
				continue
			endif

			trace = "HS_" + num2str(i)
			AppendToGraph/W=$RESISTANCE_GRAPH/L=VertCrossing/B=HorizCrossing storageDeltaV[][i]/TN=$trace vs storageDeltaI[][i]
			STRUCT RGBColor s
			[s] = GetTraceColor(i)
			ModifyGraph/W=$RESISTANCE_GRAPH rgb($trace)=(s.red, s.green, s.blue)
			ModifyGraph/W=$RESISTANCE_GRAPH mode($trace)=3

			WAVE curveFitWave = GetAnalysisFuncDAScaleResFit(device, i)
			trace = "fit_HS_" + num2str(i)
			AppendToGraph/W=$RESISTANCE_GRAPH/L=VertCrossing/B=HorizCrossing curveFitWave/TN=$trace
			ModifyGraph/W=$RESISTANCE_GRAPH rgb($trace)=(s.red, s.green, s.blue)
			ModifyGraph/W=$RESISTANCE_GRAPH freePos(VertCrossing)={0, HorizCrossing}, freePos(HorizCrossing)={0, VertCrossing}, lblLatPos=-50
		endfor
	endif

	if(!IsEmpty(textBoxString))
		TextBox/C/N=text/W=$RESISTANCE_GRAPH RemoveEnding(textBoxString, "\r")
	endif
End

/// @brief Helper for setting the DAScale, see also SetDAScale()
Function SetDAScaleModOp(string device, variable sweepNo, variable headstage, variable modifier, string operator, [variable invert, variable roundTopA, variable limitCheck])

	if(ParamIsDefault(invert))
		invert = 0
	else
		invert = !!invert
	endif

	if(ParamIsDefault(roundTopA))
		roundTopA = 0
	else
		roundTopA = !!roundTopA
	endif

	if(ParamIsDefault(limitCheck))
		limitCheck = 1
	else
		limitCheck = !!limitCheck
	endif

	strswitch(operator)
		case "+":
			return SetDAScale(device, sweepNo, headstage, offset = invert ? -modifier : modifier, roundTopA = roundTopA, limitCheck = limitCheck)
		case "*":
			return SetDAScale(device, sweepNo, headstage, relative = invert ? (1 / modifier) : modifier, roundTopA = roundTopA, limitCheck = limitCheck)
		default:
			FATAL_ERROR("Invalid operator")
			break
	endswitch
End

/// @brief Set the DAScale value of the given headstage
///
/// The limit check assumes that the next sweep is the next sweep of the current stimset (aka has a set count + 1).
///
/// @param device     device
/// @param headstage  MIES headstage
/// @param sweepNo    Sweep number
/// @param absolute   (optional) DAScale value in `A` (Amperes)
/// @param relative   (optional) relative DAScale modifier
/// @param offset     (optional) offset DAScale value
/// @param roundTopA  (optional, defaults to false) round the set DAScale to integer pA values
/// @param limitCheck (optional, defaults to true) check if the new DAScale value would be out of range
///
/// @return 0 on sucessful limits check, 1 on out-of-range and NaN if the limits check was skipped
Function SetDAScale(string device, variable sweepNo, variable headstage, [variable absolute, variable relative, variable offset, variable roundTopA, variable limitCheck])

	variable amps, DAC, nextStimsetColumn, DAScaleLimit, skipCountExisting, setCount
	string DAUnit, ctrl, lbl, stimSetName

	ASSERT((ParamIsDefault(absolute) + ParamIsDefault(relative) + ParamIsDefault(offset)) == 2, "One of absolute, relative or offset has to be present")

	if(ParamIsDefault(roundTopA))
		roundTopA = 0
	else
		roundTopA = !!roundTopA
	endif

	if(ParamIsDefault(limitCheck))
		limitCheck = 1
	else
		limitCheck = !!limitCheck
	endif

	DAC = AFH_GetDACFromHeadstage(device, headstage)
	ASSERT(IsFinite(DAC), "Does not work with unassociated DA channels")

	DAUnit = DAG_GetTextualValue(device, GetSpecialControlLabel(CHANNEL_TYPE_DAC, CHANNEL_CONTROL_UNIT), index = DAC)

	// check for correct units
	ASSERT(!cmpstr(DAunit, "pA"), "Unexpected DA Unit")

	ctrl = GetPanelControl(DAC, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_SCALE)

	if(!ParamIsDefault(absolute))
		amps = absolute * ONE_TO_PICO
	elseif(!ParamIsDefault(relative))
		lbl  = GetSpecialControlLabel(CHANNEL_TYPE_DAC, CHANNEL_CONTROL_SCALE)
		amps = DAG_GetNumericalValue(device, lbl, index = DAC) * relative
	elseif(!ParamIsDefault(offset))
		lbl  = GetSpecialControlLabel(CHANNEL_TYPE_DAC, CHANNEL_CONTROL_SCALE)
		amps = DAG_GetNumericalValue(device, lbl, index = DAC) + offset
	endif

	amps = roundTopA ? round(amps) : amps
	ASSERT(IsFinite(amps), "Invalid non-finite value")

	if(limitCheck)
		stimSetName = AFH_GetStimSetNameForHeadstage(device, headstage)
		WAVE numericalValues = GetLBNumericalValues(device)

		nextStimsetColumn = AFH_GetNextSweepSetCount(numericalValues, sweepNo, headstage)

		DAScaleLimit = DAP_GetDAScaleMax(device, headstage, stimsetName, nextStimsetColumn)
		ASSERT(IsFinite(DAScaleLimit), "Unsupported return value from DAP_GetDataLimits")

		// the border value is not valid, see DC_CheckIfDataWaveHasBorderVals
		if(amps >= DAScaleLimit)
			return 1
		endif
	endif

	PGC_SetAndActivateControl(device, ctrl, val = amps)

	if(limitCheck)
		return 0
	endif
End

/// @brief Return a list of required parameters
Function/S ReachTargetVoltage_GetParams()

	return "[EnableIndexing:variable],[IndexingEndStimsetAllIC:string]"
End

Function/S ReachTargetVoltage_GetHelp(string name)

	strswitch(name)
		case "EnableIndexing":
			return "Enable Locked Indexing in preDAQ event"
			break
		case "IndexingEndStimsetAllIC":
			return "Indexing end stimulus set for all IC headstages"
		default:
			FATAL_ERROR("Unimplemented for parameter " + name)
			break
	endswitch
End

Function/S ReachTargetVoltage_CheckParam(string name, STRUCT CheckParametersStruct &s)

	variable val
	string   str

	strswitch(name)
		case "EnableIndexing":
			val = AFH_GetAnalysisParamNumerical(name, s.params)
			if(!IsFinite(val))
				return "Invalid value " + num2str(val)
			endif
			break
		case "IndexingEndStimsetAllIC":
			str = AFH_GetAnalysisParamTextual(name, s.params)
			if(IsEmpty(str))
				return "Invalid value " + str
			endif

			// we don't check if the stimset exists, as that might not yet be the case

			break
		default:
			FATAL_ERROR("Unimplemented for parameter " + name)
			break
	endswitch
End

/// #ReachTargetVoltage:
///
/// Rows:
/// - Headstage
///
/// Cols:
/// - 0: Resistance [MΩ]
static Function/WAVE CreateOverrideResults()

	variable numRows, numCols

	numRows = LABNOTEBOOK_LAYER_COUNT
	numCols = 1

	WAVE/Z/D wv = GetOverrideResults()

	if(WaveExists(wv))
		ASSERT(IsNumericWave(wv), "overrideResults wave must be numeric here")
		Redimension/D/N=(numRows, numCols) wv
	else
		Make/D/N=(numRows, numCols) root:overrideResults/WAVE=wv
	endif

	wv[] = 0

	SetDimensionLabels(wv, "Resistance", COLS)

	return wv
End

/// @brief Analysis function to experimentally determine the cell resistance by sweeping
/// through a wave of target voltages.
///
/// Prerequisites:
/// - Stimset with multiple but identical sweeps and testpulse-like shape. The
///   number of sweeps must be larger than the number of rows in the targetVoltages wave below.
/// - Does not support DA/AD channels not associated with a MIES headstage (aka unassociated DA/AD Channels)
/// - All active headstages must be in "Current Clamp"
/// - All active IC headstages must run this analysis function
/// - An inital DAScale of -20pA is used, a fixup value of -100pA is used on
/// the next sweep if the measured resistance is smaller than 20MΩ
Function ReachTargetVoltage(string device, STRUCT AnalysisFunction_V3 &s)

	variable index, i, targetV, prevActiveHS, prevSendToAllAmp
	variable amps, result
	variable autoBiasCheck, holdingPotential, indexing
	string msg, name, control

	switch(s.eventType)
		case PRE_DAQ_EVENT:
			WAVE targetVoltagesIndex = GetAnalysisFuncIndexingHelper(device)

			targetVoltagesIndex[s.headstage] = -1

			if(!DAG_HeadstageIsHighestActive(device, s.headstage))
				return NaN
			endif

			WAVE ampParam = GetAmplifierParamStorageWave(device)
			WAVE statusHS = DAG_GetChannelState(device, CHANNEL_TYPE_HEADSTAGE)

			for(i = 0; i < NUM_HEADSTAGES; i += 1)
				if(!statusHS[i])
					continue
				endif

				if(DAG_GetHeadstageMode(device, i) != I_CLAMP_MODE)
					printf "(%s) The analysis function %s does only work in clamp mode.\r", device, GetRTStackInfo(1)
					ControlWindowToFront()
					return 1
				endif

				SetDAScale(device, s.sweepNo, i, absolute = -20e-12, limitCheck = 0)

				autoBiasCheck    = ampParam[%AutoBiasEnable][0][i]
				holdingPotential = ampParam[%AutoBiasVcom][0][i]

				if(autoBiasCheck != 1)
					printf "Abort: Autobias for headstage %d not enabled.\r", i
					ControlWindowToFront()
					return 1
				endif

				if(CheckIfClose(holdingPotential, -70, tol = 1) != 1)
					if(holdingPotential > -75 && holdingPotential < -65)
						printf "Warning: Holding potential for headstage %d is not -70mV but is within acceptable range, targetV continuing.\r", i
					else
						printf "Abort: Holding potential for headstage %d is set outside of the acceptable range for targetV.\r", i
						ControlWindowToFront()
						return 1
					endif
				endif
			endfor

			KillOrMoveToTrash(wv = GetAnalysisFuncDAScaleDeltaI(device))
			KillOrMoveToTrash(wv = GetAnalysisFuncDAScaleDeltaV(device))
			KillOrMoveToTrash(wv = GetAnalysisFuncDAScaleRes(device))
			KillWindow/Z $RESISTANCE_GRAPH

			PGC_SetAndActivateControl(device, "check_Settings_ITITP", val = 1)

			PGC_SetAndActivateControl(device, "Check_DataAcq1_DistribDaq", val = 1)

			PGC_SetAndActivateControl(device, "Check_DataAcq1_dDAQOptOv", val = 0)

			PGC_SetAndActivateControl(device, "Setvar_DataAcq_dDAQDelay", val = 500)

			indexing = !!AFH_GetAnalysisParamNumerical("EnableIndexing", s.params, defValue = 0)

			if(indexing)
				name = AFH_GetAnalysisParamTextual("IndexingEndStimsetAllIC", s.params)
				WAVE/Z stimset = WB_CreateAndGetStimSet(name)

				if(!WaveExists(stimset))
					printf "Abort: The analysis parameter IndexingEndStimsetAllIC holds \"%s\" which is not a valid stimset.", name
					ControlWindowToFront()
					return 1
				endif

				PGC_SetAndActivateControl(device, "Check_DataAcq_Indexing", val = 1)
				PGC_SetAndActivateControl(device, "Check_DataAcq1_IndexingLocked", val = 1)

				control = GetPanelControl(CHANNEL_INDEX_ALL_I_CLAMP, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_INDEX_END)
				PGC_SetAndActivateControl(device, control, str = name)

				DFREF dfr       = GetUniqueTempPath()
				WAVE  autobiasV = LBN_GetNumericWave()
				MoveWave autobiasV, dfr:autobiasV

				autobiasV[] = (p < NUM_HEADSTAGES && statusHS[p] == 1) ? -70 : NaN

				Duplicate/FREE autobiasV, autobiasVMock
				autobiasVMock[] = autobiasVMock[p] + 1

				result = ID_AskUserForSettings(ID_HEADSTAGE_SETTINGS, "Autobias V", autobiasV, autobiasVMock)

				if(result)
					return 1
				endif

				ED_AddEntryToLabnotebook(device, LBN_AUTOBIAS_TARGET_DIAG, autobiasV, unit = "mV", overrideSweepNo = s.sweepNo)
			endif
			break
		case POST_SWEEP_EVENT:
			// BEGIN CHANGE ME
			Make/FREE targetVoltages = {0.002, -0.002, -0.005, -0.01, -0.015} // units are Volts, i.e. 70mV = 0.070V
			// END CHANGE ME

			WAVE targetVoltagesIndex = GetAnalysisFuncIndexingHelper(device)

			WAVE statusHS = DAG_GetChannelState(device, CHANNEL_TYPE_HEADSTAGE)

			targetVoltagesIndex[s.headstage] += 1

			// only do something if we are called for the very last headstage
			if(!DAG_HeadstageIsHighestActive(device, s.headstage))
				return NaN
			endif

			WAVE numericalValues = GetLBNumericalValues(device)
			WAVE textualValues   = GetLBTextualValues(device)

			WAVE deltaV     = LBN_GetNumericWave()
			WAVE deltaI     = LBN_GetNumericWave()
			WAVE resistance = LBN_GetNumericWave()
			WAVE oorDAScale = LBN_GetNumericWave()

			CalculateTPLikePropsFromSweep(numericalValues, textualValues, s.scaledDACWave, deltaI, deltaV, resistance)

			ED_AddEntryToLabnotebook(device, LBN_DELTA_I, deltaI, unit = "A")
			ED_AddEntryToLabnotebook(device, LBN_DELTA_V, deltaV, unit = "V")

			FitResistance(device, s.headstage, showPlot = 1)

			WAVE/Z resistanceFitted = GetLastSetting(numericalValues, s.sweepNo, LABNOTEBOOK_USER_PREFIX + LBN_RESISTANCE_FIT, UNKNOWN_MODE)
			ASSERT(WaveExists(resistanceFitted), "Expected fitted resistance data")

#ifdef AUTOMATED_TESTING
			WAVE/Z overrideResults = GetOverrideResults()

			if(WaveExists(overrideResults))
				resistanceFitted[] = overrideResults[p][%Resistance] * MEGA_TO_ONE
			endif
#endif // AUTOMATED_TESTING

			for(i = 0; i < NUM_HEADSTAGES; i += 1)

				if(!statusHS[i])
					continue
				endif

				index = targetVoltagesIndex[i]

				if(index == DimSize(targetVoltages, ROWS))
					// reached last sweep of stimset, do nothing
					continue
				endif

				// index equals the number of sweeps in the stimset on the last call (*post* sweep event)
				if(index > DimSize(targetVoltages, ROWS))
					printf "(%s): Skipping analysis function \"%s\".\r", device, GetRTStackInfo(1)
					printf "The stimset has too many sweeps, increase the size of DAScales.\r"
					continue
				endif

				WAVE sweeps = AFH_GetSweepsFromSameSCI(numericalValues, s.sweepNo, i)

				// check initial response
				if(DimSize(sweeps, ROWS) == 1 && resistanceFitted[i] <= 20e6)
					amps                   = -100e-12
					targetVoltagesIndex[i] = -1
				else
					amps = targetVoltages[index] / resistanceFitted[i]
				endif

				index   = targetVoltagesIndex[i]
				targetV = (index >= 0 && index < DimSize(targetVoltages, ROWS)) ? targetVoltages[index] : NaN
				sprintf msg, "(%s, %d): ΔR = %.0W1PΩ, V_target = %.0W1PV, I = %.0W1PA", device, i, resistanceFitted[i], targetV, amps
				DEBUGPRINT(msg)

				oorDAScale[i] = SetDAScale(device, s.sweepNo, i, absolute = amps)
			endfor

			ReportOutOfRangeDAScale(device, s.sweepNo, INVALID_ANALYSIS_FUNCTION, oorDAScale)
			break
		case POST_SET_EVENT:
			if(!DAG_HeadstageIsHighestActive(device, s.headstage))
				return NaN
			endif

			WAVE   numericalValues    = GetLBNumericalValues(device)
			WAVE/Z autobiasFromDialog = GetLastSettingSCI(numericalValues, s.sweepNo, LABNOTEBOOK_USER_PREFIX + LBN_AUTOBIAS_TARGET_DIAG, s.headstage, UNKNOWN_MODE)
			if(WaveExists(autobiasFromDialog))
				WAVE statusHS = DAG_GetChannelState(device, CHANNEL_TYPE_HEADSTAGE)

				prevActiveHS     = GetSliderPositionIndex(device, "slider_DataAcq_ActiveHeadstage")
				prevSendToAllAmp = GetCheckBoxState(device, "Check_DataAcq_SendToAllAmp")
				PGC_SetAndActivateControl(device, "Check_DataAcq_SendToAllAmp", val = CHECKBOX_UNSELECTED)

				for(i = 0; i < NUM_HEADSTAGES; i += 1)

					if(!statusHS[i])
						continue
					endif

					ASSERT(IsFinite(autoBiasFromDialog[i]), "Autobias target voltage can not be NaN")
					PGC_SetAndActivateControl(device, "slider_DataAcq_ActiveHeadstage", val = i, switchTab = 1)
					PGC_SetAndActivateControl(device, "setvar_DataAcq_AutoBiasV", val = autoBiasFromDialog[i])
				endfor

				if(prevActiveHS != GetSliderPositionIndex(device, "slider_DataAcq_ActiveHeadstage"))
					PGC_SetAndActivateControl(device, "slider_DataAcq_ActiveHeadstage", val = prevActiveHS)
				endif

				PGC_SetAndActivateControl(device, "Check_DataAcq_SendToAllAmp", val = prevSendToAllAmp)
			endif
			break
		default:
			// do nothing
			break
	endswitch
End

/// @brief Report a future out of range DAScale value to the user and the labnotebook
///
/// Usage for a single headstage:
///
/// \rst
/// .. code-block:: igorpro
///
///     WAVE oorDAScale = LBN_GetNumericWave()
///     oorDAScale[s.headstage] = SetDAScale(...)
///
///    if(oorDAScale[s.headstage])
///			ReportOutOfRangeDAScale(...)
///	   endif
/// \endrst
Function ReportOutOfRangeDAScale(string device, variable sweepNo, variable anaFuncType, WAVE oorDAScale)

	variable i
	string   key

	ASSERT(GetHardwareType(device) != HARDWARE_SUTTER_DAC, "Missing support for Sutter amplifier")

	switch(anaFuncType)
		case PSQ_CHIRP: // fallthrough
		case PSQ_RAMP: // fallthrough
		case PSQ_DA_SCALE: // fallthrough
		case PSQ_SQUARE_PULSE: // fallthrough
		case PSQ_RHEOBASE:
			key = CreateAnaFuncLBNKey(anaFuncType, PSQ_FMT_LBN_DASCALE_OOR)
			ED_AddEntryToLabnotebook(device, key, oorDAScale, overrideSweepNo = sweepNo, unit = LABNOTEBOOK_BINARY_UNIT)
			break
		case MSQ_FAST_RHEO_EST: // fallthrough
		case MSQ_DA_SCALE: // fallthrough
		case SC_SPIKE_CONTROL:
			key = CreateAnaFuncLBNKey(anaFuncType, MSQ_FMT_LBN_DASCALE_OOR)
			ED_AddEntryToLabnotebook(device, key, oorDAScale, overrideSweepNo = sweepNo, unit = LABNOTEBOOK_BINARY_UNIT)
			break
		case INVALID_ANALYSIS_FUNCTION: // ReachTargetVoltage
			ED_AddEntryToLabnotebook(device, LBN_DASCALE_OUT_OF_RANGE, oorDAScale, unit = LABNOTEBOOK_BINARY_UNIT)
			break
		default:
			FATAL_ERROR("Unknown analysis function")
	endswitch

	WAVE statusHS = DAG_GetChannelState(device, CHANNEL_TYPE_HEADSTAGE)

	Make/FREE/N=(NUM_HEADSTAGES) failedHS = statusHS[p] && oorDAScale[p] == 1

	if(Sum(failedHS) == 0)
		return NaN
	endif

	printf "(%s) The DAScale value could not be set as it is out-of-range.\r", GetRTStackInfo(2)
	printf "Please adjust the \"External Command Sensitivity\" in the MultiClamp Commander application and try again.\r"
	ControlWindowToFront()

	for(i = 0; i < NUM_HEADSTAGES; i += 1)

		if(!failedHS[i])
			continue
		endif

		ForceSetEvent(device, i)
	endfor

	RA_SkipSweeps(device, Inf, SWEEP_SKIP_AUTO)
End

/// @brief Manually force the pre/post set events
///
/// Required to do before skipping sweeps.
/// @todo this hack must go away.
static Function ForceSetEvent(string device, variable headstage)

	variable DAC

	WAVE setEventFlag = GetSetEventFlag(device)
	DAC = AFH_GetDACFromHeadstage(device, headstage)

	setEventFlag[DAC][%PRE_SET_EVENT]  = 1
	setEventFlag[DAC][%POST_SET_EVENT] = 1
End

Function/S SetControlInEvent_CheckParam(string name, STRUCT CheckParametersStruct &s)

	string type, event
	variable i, numTuples

	type = AFH_GetAnalysisParamType(name, s.params, typeCheck = 0)

	if(CmpStr(type, "textwave"))
		return "Must be of type \"text wave\""
	endif

	WAVE/Z/T data = AFH_GetAnalysisParamTextWave(name, s.params)

	if(!WaveExists(data))
		return "Does not hold anything."
	endif

	if(DimSize(data, ROWS) == 0 || !IsEven(DimSize(data, ROWS)) || DimSize(data, COLS) != 0)
		return "Does not hold valid entries as the text wave must have an even number of rows (2, 4, 6, ...)."
	endif

	numTuples = DimSize(data, ROWS)
	for(i = 0; i < numTuples; i += 2)

		// check given event type
		event = data[i]

		// backwards compatibility
		if(!cmpstr(event, "Pre Sweep"))
			printf "The event \"%s\" is deprecated. Please use the new name \"%s\" and see the documentation for it's slightly different properties.\r", event, StringFromList(PRE_SWEEP_CONFIG_EVENT, EVENT_NAME_LIST)
			event = StringFromList(PRE_SWEEP_CONFIG_EVENT, EVENT_NAME_LIST)
		endif

		if(WhichListItem(event, EVENT_NAME_LIST, ";", 0, 0) == -1 || WhichListItem(event, "Mid Sweep;Generic", ";", 0, 0) != -1)
			return "The event \"" + event + "\" is invalid."
		endif

		if(WhichListItem(name, CONTROLS_DISABLE_DURING_DAQ, ";", 0, 0) != -1 && WhichListItem(event, "Pre DAQ;Post DAQ", ";", 0, 0) == -1)
			return "The control " + name + "can only be changed in Pre/Post DAQ."
		endif
	endfor
End

/// @brief Analysis function to set GUI controls or notebooks in the events
///
/// Usage:
/// - Add analysis parameters named like the control/notebook
/// - Their value must be a textwave with at least one tuple of event type and data.
/// - Valid number of rows are therefore 2, 4, 6, ...
/// - The first tuple element is the event type, one of #EVENT_NAME_LIST without "Mid Sweep"
///   and "Generic", and the second element the value to set
/// - For PopupMenus the passed value is the menu item and *not* its index
/// - The controls are searched in all open panels and graphs. The notebook can
///   be a toplevel or subwindow notebook.
///
/// Examples:
///
/// \rst
///
/// =============================== ============================================================
///  Name                            Value
/// =============================== ============================================================
///  setvar_DataAcq_OnsetDelayUser   Pre DAQ;20
///  Popup_Settings_FixedFreq        Pre Sweep;100;Post Sweep;Maximum
///  sweepFormula_formula            Pre Set;data(select(selchannels(AD)))
/// =============================== ============================================================
///
/// \endrst
///
Function SetControlInEvent(string device, STRUCT AnalysisFunction_V3 &s)

	string guiElements, guiElem, type, valueStr, event, msg, win, windowsWithGUIElement, databrowser, str
	variable numEntries, i, controlType, j, numTuples, numMatches, numWindows, k

	if(s.eventType == MID_SWEEP_EVENT)
		return NaN
	endif

	if(!DAG_HeadstageIsHighestActive(device, s.headstage))
		return NaN
	endif

	guiElements = AFH_GetListOfAnalysisParamNames(s.params)
	numEntries  = ItemsInList(guiElements)

	for(i = 0; i < numEntries; i += 1)
		guiElem = StringFromList(i, guiElements)

		if(ControlExists(device, guiElem))
			windowsWithGUIElement = device
		else
			windowsWithGUIElement = FindControl(guiElem)
		endif

		numMatches = ItemsInList(windowsWithGUIElement)

		if(numMatches == 1)
			// do nothing
		elseif(numMatches > 1)
			printf "(%s): The analysis parameter %s is a control which is present in multiple panels or graphs.\r", device, guiElem
			ControlWindowToFront()
			continue
		else
			ASSERT(numMatches == 0, "invalid code")

			windowsWithGUIElement = FindNotebook(guiElem)
			numMatches            = ItemsInList(windowsWithGUIElement)

			if(numMatches == 0)
				printf "(%s): The analysis parameter %s does not exist as control or notebook in one of the open panels and graphs.\r", device, guiElem
				ControlWindowToFront()
				continue
			endif
		endif

		WAVE/Z/T data = AFH_GetAnalysisParamTextWave(guiElem, s.params)
		ASSERT(WaveExists(data), "No payload")

		numTuples = DimSize(data, ROWS)
		for(j = 0; j < numTuples; j += 2)

			// check given event type
			event = data[j]

			// backwards compatibility
			if(!cmpstr(event, "Pre Sweep"))
				event = StringFromList(PRE_SWEEP_CONFIG_EVENT, EVENT_NAME_LIST)
			endif

			// now we can finally check if it is our turn
			if(WhichListItem(event, EVENT_NAME_LIST, ";", 0, 0) != s.eventType)
				continue
			endif

			// set the control
			valueStr = data[j + 1]

			sprintf msg, "%s: Setting control %s to %s in event %s\r", GetRTStackInfo(1), guiElem, valueStr, event
			DEBUGPRINT(msg)

			numWindows = ItemsInList(windowsWithGUIElement)
			for(k = 0; k < numWindows; k += 1)
				win = StringFromList(k, windowsWithGUIElement)

				switch(WinType(win))
					case WINTYPE_GRAPH: // fallthrough
					case WINTYPE_PANEL:
						if(IsControlDisabled(win, guiElem))
							printf "(%s): The analysis parameter %s is a control which is disabled. Therefore it can not be set.\r", device, guiElem
							ControlWindowToFront()
							return 1
						endif

						controlType = GetControlType(win, guiElem)
						switch(controlType)
							case CONTROL_TYPE_SETVARIABLE: // fallthrough
							case CONTROL_TYPE_POPUPMENU:
								PGC_SetAndActivateControl(win, guiElem, str = valueStr)
								break
							case CONTROL_TYPE_VALDISPLAY: // fallthrough
							case CONTROL_TYPE_CHART: // fallthrough
							case CONTROL_TYPE_GROUPBOX: // fallthrough
							case CONTROL_TYPE_TITLEBOX:
								printf "(%s): The analysis parameter %s is a control which can not be set. Please fix the stimulus set.\r", device, guiElem
								ControlWindowToFront()
								break
							default:
								PGC_SetAndActivateControl(win, guiElem, val = str2numSafe(valueStr))
								break
						endswitch
						break
					case WINTYPE_NOTEBOOK:
						ReplaceNotebookText(win, NormalizeToEOL(valueStr, "\r"))
						break
					default:
						FATAL_ERROR("Unexpected window type")
				endswitch
			endfor
		endfor
	endfor
End
