#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_AF
#endif

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
/// .. image:: ../analysis-functions-calls-during-RA-stages.svg
///    :width: 300 px
///    :align: center
///
/// =========== ============================================== ===============================================================
/// Event        Description                                    Specialities
/// =========== ============================================== ===============================================================
/// Pre DAQ      Before any DAQ occurs                          Called before the settings are validated completely, only the
///                                                             analysis parameters are validated if present. With Indexing ON,
///                                                             only the analysis function of the first stimset will receive
///                                                             that event.
/// Mid Sweep    Each time when new data is polled              Available for background DAQ only.
///                                                             Will always be called at least once and
///                                                             also with the full stimset acquired.
/// Pre Sweep    Immediately before the sweep starts            None
/// Pre Set      Before a new set starts                        None
/// Post Sweep   After each sweep (before possible ITI pause)   None
/// Post Set     After a *full* set has been acquired           This event is not always reached as the user might not acquire all steps
///                                                             of a set or indexing on multiple headstages is used.
/// Post DAQ     After DAQ has finished and before potential    None
///              "TP after DAQ"
/// =========== ============================================== ===============================================================
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
/// ======================================== ============= ============================================================================================
/// Value                                    Event Types   Action
/// ======================================== ============= ============================================================================================
/// NaN                                      All           Nothing
/// 0                                        All           Nothing
/// 1                                        Pre DAQ       DAQ is prevented to start
/// 1                                        Pre Set       DAQ is stopped
/// :cpp:var:`ANALYSIS_FUNC_RET_REPURP_TIME` Mid Sweep     Current sweep is immediately stopped. Left over time is repurposed for ITI.
/// :cpp:var:`ANALYSIS_FUNC_RET_EARLY_STOP`  Mid Sweep     Current sweep is immediately stopped without honouring the left over time in a special way.
/// ======================================== ============= ============================================================================================
///
/// \endrst
///
/// @anchor AnalysisFunctionParameters Analayis function user parameters (V3 only)
///
/// For some analysis functions it is beneficial to send in additional data
/// depending on the stimset. This is supported by adding parameters and their
/// values via WBP_AddAnalysisParameter() to the stimset, or using the
/// Wavebuilder GUI, and then querying them with the help of @ref
/// AnalysisFunctionParameterHelpers. The parameters are stored serialized in
/// the `WPT` wave, see GetWaveBuilderWaveTextParam() for the exact format. See
/// TestAnalysisFunction_V3() for an example implementation.
///
/// If you want to propose a list of parameters which should/must be present, define
/// an additional function named like your analysis function but suffixed with
/// `_GetParams` and return a comma separated list of names. Adding the
/// type is also possible via `$name:$type` syntax. The list of parameter names and types
/// is then checked before DAQ. The supplied names are taken to be required by
/// default, optional parameters, and their types, must be enclosed with `[]`.
/// The list at #ANALYSIS_FUNCTION_PARAMS_TYPES holds all valid types.
///
/// The optional function `_CheckParam` allows you to validate passed
/// parameters. In case of a valid parameter it must return an emtpy string and
/// an error message in case of failure. Parameters which don't pass can
/// neither be added to stimsets nor can they be used for data acquisition.
/// Optional parameters are only checked if they are present in the stimulus
/// set so you don't need to handle that case special.
///
/// The optional function `_GetHelp` allows you to create per parameter help
/// text which is shown in the Wavebuilder.
///
/// Example:
///
/// \rst
/// .. code-block:: igorpro
///
///    Function MyAnalysisFunction(panelTitle, s)
///        string panelTitle
///        struct AnalysisFunction_V3& s
///
///        // ...
///    End
///
///    Function/S MyAnalysisFunction_GetParams()
///        return "param1:variable,[optParam1:wave]"
///    End
///
///    Function/S MyAnalysisFunction_CheckParam(name, params)
///        string name, params
///
///        variable value
///
///        strswitch(name)
///            case "param1":
///                value = AFH_GetAnalysisParamNumerical(name, params)
///                if(!IsFinite(value) || !(value >= 0 && value <= 100))
///                    return "Needs to be between 0 and 100."
///                endif
///                break
///            case "optParam1":
///                WAVE/Z wv = AFH_GetAnalysisParamWave(name, params)
///                if(!WaveExists(wv) || !IsFloatingPointWave(wv))
///                    return "Needs to be an existing floating point wave."
///                break
///        endswitch
///
///        // default to passing for other parameters
///        return ""
///    End
///
///    Function/S MyAnalysisFunction_GetHelp(name)
///        string name, params
///
///        strswitch(name)
///            case "param1":
///                 return "This parameter helps in finding pink unicorns"
///                 break
///            case "optParam1":
///                 return "This parameter delivers food right to your door"
///                 break
///            default:
///                 ASSERT(0, "Unimplemented for parameter " + name)
///                 break
///        endswitch
///    End
///
/// \endrst

/// @name Initial parameters for stimulation
///@{
static StrConstant DEFAULT_DEVICE = "ITC18USB_Dev_0"        ///< panelTitle device
static StrConstant STIM_SET_LOCAL = "PulseTrain_150Hz_DA_0" ///< Initial stimulus set
static Constant VM1_LOCAL         = -55                     ///< Initial holding potential
static Constant VM2_LOCAL         = -85                     ///< Second holding potential to switch to
static Constant SCALE_LOCAL       = 70                      ///< Stimulus amplitude
static Constant NUM_SWEEPS_LOCAL  = 6                       ///< Number of sweeps to acquire
static Constant ITI_LOCAL         = 15                      ///< Inter-trial-interval
///@}

/// @name Initial settings for oodDAQ stimulation
///@{
static Constant POST_DELAY = 150									 ///< Delay after stimulation event in which no other event can occur in ms
///@}

Function TestAnalysisFunction_V1(panelTitle, eventType, ITCDataWave, headStage)
	string panelTitle
	variable eventType
	Wave ITCDataWave
	variable headstage

	printf "Analysis function version 1 called: device %s, eventType \"%s\", headstage %d\r", panelTitle, StringFromList(eventType, EVENT_NAME_LIST), headStage
	printf "Next sweep: %d\r", DAG_GetNumericalValue(panelTitle, "SetVar_Sweep")
End

Function TestAnalysisFunction_V2(panelTitle, eventType, ITCDataWave, headStage, realDataLength)
	string panelTitle
	variable eventType
	Wave ITCDataWave
	variable headstage, realDataLength

	printf "Analysis function version 2 called: device %s, eventType \"%s\", headstage %d\r", panelTitle, StringFromList(eventType, EVENT_NAME_LIST), headStage

	return 0
End

Function TestAnalysisFunction_V3(panelTitle, s)
	string panelTitle
	STRUCT AnalysisFunction_V3& s

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
			case "wave":
				WAVE/T/Z wvText = AFH_GetAnalysisParamTextWave(name, s.params)
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
		case PRE_SWEEP_EVENT:
			// code
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

	printf "Analysis function version 3 called: device %s, eventType \"%s\", headstage %d\r", panelTitle, StringFromList(s.eventType, EVENT_NAME_LIST), s.headStage

	return 0
End

/// @brief Measure the time between mid sweep calls
///
/// Used mainly for debugging.
Function MeasureMidSweepTiming_V3(panelTitle, s)
	string panelTitle
	STRUCT AnalysisFunction_V3& s

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
	endswitch

	return 0
End

Function Enforce_VC(panelTitle, eventType, ITCDataWave, headStage, realDataLength)
	string panelTitle
	variable eventType
	Wave ITCDataWave
	variable headstage, realDataLength

	if(eventType != PRE_DAQ_EVENT)
	   return 0
	endif

	if(DAG_GetHeadstageMode(panelTitle, headStage) != V_CLAMP_MODE)
		variable DAC = AFH_GetDACFromHeadstage(panelTitle, headstage)

		string stimSetName = AFH_GetStimSetName(paneltitle, DAC, CHANNEL_TYPE_DAC)
		printf "%s on DAC %d of headstage %d requires voltage clamp mode. Change clamp mode to voltage clamp to allow data acquistion\r" stimSetName, DAC, headStage
		return 1
	endif

	return 0
End

Function Enforce_IC(panelTitle, eventType, ITCDataWave, headStage, realDataLength)
	string panelTitle
	variable eventType
	Wave ITCDataWave
	variable headstage, realDataLength

	if(eventType != PRE_DAQ_EVENT)
	   return 0
	endif

	if(DAG_GetHeadstageMode(panelTitle, headStage) != I_CLAMP_MODE)
		variable DAC = AFH_GetDACFromHeadstage(panelTitle, headstage)
		string stimSetName = AFH_GetStimSetName(paneltitle, DAC, CHANNEL_TYPE_DAC)
		printf "Stimulus set: %s on DAC: %d of headstage: %d requires current clamp mode. Change clamp mode to current clamp to allow data acquistion\r" stimSetName, DAC, headStage
		return 1
	endif

	return 0
End

// User Defined Analysis Functions
// Functions which can be assigned to various epochs of a stimulus set
// Starts with a pop-up menu to set initial parameters and then switches holding potential midway through total number of sweeps

/// @brief Force active headstages into voltage clamp
Function SetStimConfig_Vclamp(panelTitle, eventType, ITCDataWave, headStage)
	string panelTitle
	variable eventType
	Wave ITCDataWave
	variable headstage

	setVClampMode()

	printf "Stimulus set running in V-Clamp on headstage: %d\r", headStage

End

/// @brief Force active headstages into current clamp
Function SetStimConfig_Iclamp(panelTitle, eventType, ITCDataWave, headStage)
	string panelTitle
	variable eventType
	Wave ITCDataWave
	variable headstage

	setIClampMode()

	printf "Stimulus set running in I-Clamp on headstage: %d\r", headStage

End

/// @brief Change holding potential midway through stim set
Function ChangeHoldingPotential(panelTitle, eventType, ITCDataWave, headStage)
	string panelTitle
	variable eventType
	Wave ITCDataWave
	variable headstage

	variable SweepsRemaining = switchHolding(VM2_LOCAL)

	printf "Number of stimuli remaining is: %d on headstage: %d\r", SweepsRemaining, headStage
End

/// @brief Print last Stim Set run and headstage mode and holding potential
Function LastStimSet(panelTitle, eventType, ITCDataWave, headStage)
	string panelTitle
	variable eventType
	Wave ITCDataWave
	variable headstage

	PGC_SetAndActivateControl(panelTitle, "check_Settings_TPAfterDAQ", val = CHECKBOX_SELECTED)

	LastStimSetRun()

End
/// @brief GUI to set initial stimulus parameters using SetStimParam() and begin data acquisition.
/// NOTE: DATA ACQUISITION IS INTIATED AT THE END OF FUNCTION!
Function StimParamGUI()

	string StimSetList, stimSet
	variable Vm1, Scale, sweeps, ITI

	StimSetList = ReturnListOfAllStimSets(CHANNEL_TYPE_DAC, CHANNEL_DA_SEARCH_STRING)
	stimSet = STIM_SET_LOCAL
	Vm1 = VM1_LOCAL
	Scale = SCALE_LOCAL
	sweeps = NUM_SWEEPS_LOCAL
	ITI = ITI_LOCAL

	Prompt stimSet, "Choose which stimulus set to run:", popup, StimSetList
	Prompt Vm1, "Enter initial holding potential: "
	Prompt Scale, "Enter scale of stimulation [mV]: "
	Prompt sweeps, "Enter number of sweeps to run: "
	Prompt ITI, "Enter inter-trial interval [s]: "

	DoPrompt "Choose stimulus set and enter initial parameters", stimSet, Vm1,  Scale, sweeps, ITI

	if(!V_flag)
		SetStimParam(stimSet,Vm1,Scale,Sweeps,ITI)
		PGC_SetAndActivateControl(DEFAULT_DEVICE,"DataAcquireButton")
	endif
End

/// @brief Called by StimParamGUI to set initial stimulus parameters
///
/// @param stimSet	Stimulus set to run
/// @param Vm1		Holding potential
/// @param Scale		Stimulus amplitude in mV
/// @param Sweeps	Number of sweeps
/// @param ITI		Inter-trial-interval
Function SetStimParam(stimSet, Vm1, Scale, Sweeps, ITI)
	variable Vm1, scale, sweeps, ITI
	string stimSet

	variable stimSetIndex

	setHolding(Vm1)
	stimSetIndex = GetStimSet(stimSet)

	if(stimSetIndex > 0)

		PGC_SetAndActivateControl(DEFAULT_DEVICE, "Wave_DA_All", val = stimSetIndex + 1)
		PGC_SetAndActivateControl(DEFAULT_DEVICE, "Scale_DA_All", val = scale)
		PGC_SetAndActivateControl(DEFAULT_DEVICE, "SetVar_DataAcq_SetRepeats", val = sweeps)
		PGC_SetAndActivateControl(DEFAULT_DEVICE, "SetVar_DataAcq_ITI", val = ITI)

		InitoodDAQ()
	else
		printf "Requested non-existent stim set"
		return stimSetIndex
	endif

	if(sweeps > 1)
		PGC_SetAndActivateControl(DEFAULT_DEVICE, "Check_DataAcq1_RepeatAcq", val = CHECKBOX_SELECTED)
	endif

End

/// @brief Set holding potential for active headstages
///
/// @param Vm1		   Holding potential
Function setHolding(Vm1)
	variable Vm1

	variable i
	WAVE statusHS = DAG_GetChannelState(DEFAULT_DEVICE, CHANNEL_TYPE_HEADSTAGE)

	for(i=0; i<NUM_HEADSTAGES; i+=1)
		if (statusHS[i] == 1)
			PGC_SetAndActivateControl(DEFAULT_DEVICE, "slider_DataAcq_ActiveHeadstage", val = i)
			PGC_SetAndActivateControl(DEFAULT_DEVICE, "setvar_DataAcq_Hold_VC", val = Vm1)
			PGC_SetAndActivateControl(DEFAULT_DEVICE, "setvar_DataAcq_Hold_IC", val = Vm1)
		endif
	endfor
End

/// @brief Set active headstages into V-clamp
Function setVClampMode()

	variable i
	string ctrl
	WAVE statusHS = DAG_GetChannelState(DEFAULT_DEVICE, CHANNEL_TYPE_HEADSTAGE)

	for(i=0; i<NUM_HEADSTAGES; i+=1)
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
	string ctrl

	WAVE statusHS = DAG_GetChannelState(DEFAULT_DEVICE, CHANNEL_TYPE_HEADSTAGE)

	for(i=0; i<NUM_HEADSTAGES; i+=1)
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
Function switchHolding(Vm2)
	variable Vm2

	variable numSweeps, SweepsRemaining, switchSweep, i, clampMode

	numSweeps = GetValDisplayAsNum(DEFAULT_DEVICE, "valdisp_DataAcq_SweepsInSet")
	SweepsRemaining = DAG_GetNumericalValue(DEFAULT_DEVICE, "valdisp_DataAcq_TrialsCountdown") - 1

	if(numSweeps <= 1)
		PGC_SetAndActivateControl(DEFAULT_DEVICE, "check_Settings_TPAfterDAQ", val = CHECKBOX_SELECTED)
		printf "Not enough sweeps were acquired, can not switch holding \r"
		return SweepsRemaining
	endif

	switchSweep = floor(numSweeps/2)
	WAVE statusHS = DAG_GetChannelState(DEFAULT_DEVICE, CHANNEL_TYPE_HEADSTAGE)

    if(SweepsRemaining == switchSweep)
        for(i=0; i<NUM_HEADSTAGES; i+=1)
            if(statusHS[i])
				clampMode = DAG_GetHeadstageMode(DEFAULT_DEVICE, i)
                PGC_SetAndActivateControl(DEFAULT_DEVICE, "slider_DataAcq_ActiveHeadstage", val = i)
				if(clampMode == V_CLAMP_MODE)
                    PGC_SetAndActivateControl(DEFAULT_DEVICE, "setvar_DataAcq_Hold_VC", val = Vm2)
				elseif(clampMode == I_CLAMP_MODE)
                    PGC_SetAndActivateControl(DEFAULT_DEVICE, "setvar_DataAcq_Hold_IC", val = Vm2)
					else
						ASSERT(0, "Unsupported clamp mode")
					endif
				endif
        endfor
		printf "Half-way through stim set, changing holding potential to: %d\r", Vm2
    endif

	return SweepsRemaining
End

/// @brief Get index of stim set from stim set list
Function GetStimSet(stimSet)
	string stimSet

	string StimSetList = ReturnListOfAllStimSets(CHANNEL_TYPE_DAC, CHANNEL_DA_SEARCH_STRING)
	variable stimSetIndex = whichlistitem(stimSet,StimSetList)

	return stimSetIndex
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

	WAVE /T textualValues = GetLBTextualValues(DEFAULT_DEVICE)
	WAVE  numericalValues = GetLBNumericalValues(DEFAULT_DEVICE)
	WAVE statusHS = DAG_GetChannelState(DEFAULT_DEVICE, CHANNEL_TYPE_HEADSTAGE)
	LastSweep = AFH_GetLastSweepAcquired(DEFAULT_DEVICE)

	if (!isInteger(LastSweep))
		printf "No sweeps have been acquired"
		return LastSweep
	endif

	WAVE /T StimSet = GetLastSetting(textualValues, LastSweep, "Stim Wave Name", DATA_ACQUISITION_MODE)
	WAVE clampHS = GetLastSetting(numericalValues, LastSweep, "Clamp Mode", DATA_ACQUISITION_MODE)
	WAVE /Z holdingVC = GetLastSetting(numericalValues, LastSweep, "V-Clamp Holding Level", DATA_ACQUISITION_MODE)
	WAVE /Z holdingIC = GetLastSetting(numericalValues, LastSweep, "I-Clamp Holding Level", DATA_ACQUISITION_MODE)

	for(i=0; i<NUM_HEADSTAGES; i+=1)
		if(statusHS[i])
			if(clampHS[i] == V_CLAMP_MODE )
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
Function TestPrematureSweepStop(panelTitle, eventType, ITCDataWave, headStage, realDataLength)
	string panelTitle
	variable eventType
	Wave ITCDataWave
	variable headstage, realDataLength

	variable num
	SVAR temp = $GetTemporaryString()

	if(eventType == PRE_DAQ_EVENT || eventType == POST_SWEEP_EVENT)
		temp = "0"
		return NaN
	elseif(eventType == MID_SWEEP_EVENT)
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

Function preDAQ_MP_mainConfig(panelTitle, eventType, ITCDataWave, headStage, realDataLength)
	string panelTitle
	variable eventType
	Wave ITCDataWave
	variable headstage, realDataLength

	ASSERT(eventType == PRE_DAQ_EVENT, "Invalid event type")

	PGC_SetAndActivateControl(panelTitle,"Check_DataAcq1_DistribDaq", val = 0)

	PGC_SetAndActivateControl(panelTitle,"Check_DataAcq1_dDAQOptOv", val = 1)

	PGC_SetAndActivateControl(panelTitle, "Check_DataAcq1_RepeatAcq", val = 1)
End

Function preDAQ_MP_IfMixed(panelTitle, eventType, ITCDataWave, headStage, realDataLength)
	string panelTitle
	variable eventType
	Wave ITCDataWave
	variable headstage, realDataLength

	ASSERT(eventType == PRE_DAQ_EVENT, "Invalid event type")

	PGC_SetAndActivateControl(panelTitle,"Check_DataAcq1_DistribDaq", val = 1)

	PGC_SetAndActivateControl(panelTitle,"Check_DataAcq1_dDAQOptOv", val = 0)

	PGC_SetAndActivateControl(panelTitle, "Check_DataAcq1_RepeatAcq", val = 1)
End

Function preDAQ_MP_ChirpBlowout(panelTitle, eventType, ITCDataWave, headStage, realDataLength)
	string panelTitle
	variable eventType
	Wave ITCDataWave
	variable headstage, realDataLength

	ASSERT(eventType == PRE_DAQ_EVENT, "Invalid event type")

	PGC_SetAndActivateControl(panelTitle,"Check_DataAcq1_DistribDaq", val = 0)

	PGC_SetAndActivateControl(panelTitle,"Check_DataAcq1_dDAQOptOv", val = 0)

	PGC_SetAndActivateControl(panelTitle, "Check_DataAcq1_RepeatAcq", val = 1)
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
Function AdjustDAScale(panelTitle, eventType, ITCDataWave, headStage, realDataLength)
	string panelTitle
	variable eventType
	Wave ITCDataWave
	variable headstage, realDataLength

	variable val, index, DAC, ADC
	string ctrl, msg

	// BEGIN CHANGE ME
	MAKE/D/FREE DAScales = {-25, 25, -50, 50, -100, 100}
	// END CHANGE ME

	WAVE DAScalesIndex = GetAnalysisFuncIndexingHelper(panelTitle)

	switch(eventType)
		case PRE_DAQ_EVENT:

			if(DAG_GetHeadstageMode(panelTitle, headStage) != I_CLAMP_MODE)
				printf "The analysis function \"%s\" can only be used in Current Clamp mode.\r", GetRTStackInfo(1)
				return 1
			endif

			DAScalesIndex[headstage] = 0
			KillOrMoveToTrash(wv = GetAnalysisFuncDAScaleDeltaI(panelTitle))
			KillOrMoveToTrash(wv = GetAnalysisFuncDAScaleDeltaV(panelTitle))
			KillOrMoveToTrash(wv = GetAnalysisFuncDAScaleRes(panelTitle))
			KillWindow/Z $RESISTANCE_GRAPH
			break
		case POST_SWEEP_EVENT:
			DAScalesIndex[headstage] += 1
			break
		default:
			ASSERT(0, "Unknown eventType")
			break
	endswitch

	DAC = AFH_GetDACFromHeadstage(panelTitle, headstage)
	ASSERT(IsFinite(DAC), "This analysis function does not work with unassociated DA channels")

	ADC = AFH_GetADCFromHeadstage(panelTitle, headstage)
	ASSERT(IsFinite(ADC), "This analysis function does not work with unassociated AD channels")

	index = DAScalesIndex[headstage]
	if(index < DimSize(DAScales, ROWS))
		ctrl = GetPanelControl(DAC, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_SCALE)
		PGC_SetAndActivateControl(panelTitle, ctrl, val = DAScales[index])
	endif

	sprintf msg, "(%s, %d): DAScale = %g", panelTitle, headstage, (index < DimSize(DAScales, ROWS) ? DAScales[index] : NaN)
	DEBUGPRINT(msg)

	// index equals the number of sweeps in the stimset on the last call (*post* sweep event)
	if(index > DimSize(DAScales, ROWS))
		printf "(%s): Skipping analysis function \"%s\".\r", panelTitle, GetRTStackInfo(1)
		printf "The stimset \"%s\" of headstage %d has too many sweeps, increase the size of DAScales.\r", AFH_GetStimSetName(panelTitle, DAC,  CHANNEL_TYPE_DAC), headstage
		return NaN
	endif

	if(eventType == PRE_DAQ_EVENT)
		return NaN
	endif

	// only do something if we are called for the very last headstage
	if(DAP_GetHighestActiveHeadstage(panelTitle) != headstage)
		return NaN
	endif

	WAVE/Z sweep = AFH_GetLastSweepWaveAcquired(panelTitle)
	ASSERT(WaveExists(sweep), "Expected a sweep for evalulation")

	WAVE numericalValues = GetLBNumericalValues(panelTitle)
	WAVE textualValues   = GetLBTextualValues(panelTitle)

	Make/D/FREE/N=(LABNOTEBOOK_LAYER_COUNT) deltaV     = NaN
	Make/D/FREE/N=(LABNOTEBOOK_LAYER_COUNT) deltaI     = NaN
	Make/D/FREE/N=(LABNOTEBOOK_LAYER_COUNT) resistance = NaN

	CalculateTPLikePropsFromSweep(numericalValues, textualValues, sweep, deltaI, deltaV, resistance)

	ED_AddEntryToLabnotebook(panelTitle, "Delta I", deltaI, unit = "I")
	ED_AddEntryToLabnotebook(panelTitle, "Delta V", deltaV, unit = "V")

	PlotResistanceGraph(panelTitle)
End

/// Plot the resistance of the sweeps of the same RA cycle
///
/// Usually called by PSQ_AdjustDAScale().
Function PlotResistanceGraph(panelTitle)
	string panelTitle

	variable deltaVCol, DAScaleCol, i, j, sweepNo, idx, numEntries
	variable red, green, blue, lastWrittenSweep
	string graph, textBoxString, trace

	sweepNo = AFH_GetLastSweepAcquired(panelTitle)

	if(!IsFinite(sweepNo))
		return NaN
	endif

	WAVE numericalValues = GetLBNumericalValues(panelTitle)
	WAVE/Z sweeps = AFH_GetSweepsFromSameRACycle(numericalValues, sweepNo)

	if(!WaveExists(sweeps))
		printf "The last sweep %d did not hold any repeated acquisition cycle information.\r", sweepNo
		ControlWindowToFront()
		return NaN
	endif

	WAVE statusHS = DAG_GetChannelState(panelTitle, CHANNEL_TYPE_HEADSTAGE)

	WAVE storageDeltaI = GetAnalysisFuncDAScaleDeltaI(panelTitle)
	WAVE storageDeltaV = GetAnalysisFuncDAScaleDeltaV(panelTitle)
	WAVE storageResist = GetAnalysisFuncDAScaleRes(panelTitle)

	lastWrittenSweep = GetNumberFromWaveNote(storageDeltaV, "Last Sweep")

	if(IsFinite(lastWrittenSweep))
		Extract/O sweeps, sweeps, sweeps > lastWrittenSweep
	endif

	idx = GetNumberFromWaveNote(storageDeltaV, NOTE_INDEX)

	numEntries = DimSize(sweeps, ROWS)
	for(i = 0; i < numEntries; i += 1)

		sweepNo = sweeps[i]
		WAVE/Z deltaI = GetLastSetting(numericalValues, sweepNo, LABNOTEBOOK_USER_PREFIX + "Delta I", UNKNOWN_MODE)
		WAVE/Z deltaV = GetLastSetting(numericalValues, sweepNo, LABNOTEBOOK_USER_PREFIX + "Delta V", UNKNOWN_MODE)

		if(!WaveExists(deltaI) || !WaveExists(deltaV))
			print "Could not find all required labnotebook keys"
			ControlWindowToFront()
			continue
		endif

		EnsureLargeEnoughWave(storageDeltaI, minimumSize = idx, initialValue = NaN)
		EnsureLargeEnoughWave(storageDeltaV, minimumSize = idx, initialValue = NaN)

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
		WAVE W_sigma

		storageResist[i][%Value] = coefWave[1]
		storageResist[i][%Error] = W_sigma[1]

		sprintf textBoxString, "%sHS%d: %.0W1PΩ +/- %.0W1PΩ\r", textBoxString, i, storageResist[i][%Value], storageResist[i][%Error]

		WAVE fitWave = $("fit_" + NameOfWave(storageDeltaV))
		RemoveFromGraph/Z $NameOfWave(fitWave)

		WAVE curveFitWave = GetAnalysisFuncDAScaleResFit(panelTitle, i)
		Duplicate/O fitWave, curveFitWave
	endfor

	Make/D/FREE/N=(LABNOTEBOOK_LAYER_COUNT) storage = NaN
	storage[0, NUM_HEADSTAGES - 1] = storageResist[p][%Value]
	ED_AddEntryToLabnotebook(panelTitle, "ResistanceFromFit", storage, unit = "Ohm")

	storage = NaN
	storage[0, NUM_HEADSTAGES - 1] = storageResist[p][%Error]
	ED_AddEntryToLabnotebook(panelTitle, "ResistanceFromFit_Err", storage, unit = "Ohm")

	KillOrMoveToTrash(wv=W_sigma)
	KillOrMoveToTrash(wv=fitWave)

	WAVE statusHS = DAG_GetChannelState(panelTitle, CHANNEL_TYPE_HEADSTAGE)

	if(!WindowExists(RESISTANCE_GRAPH))
		Display/K=1/N=$RESISTANCE_GRAPH

		for(i = 0; i < NUM_HEADSTAGES; i += 1)

			if(!statusHS[i])
				continue
			endif

			trace = "HS_" + num2str(i)
			AppendToGraph/W=$RESISTANCE_GRAPH/L=VertCrossing/B=HorizCrossing storageDeltaV[][i]/TN=$trace vs storageDeltaI[][i]
			GetTraceColor(i, red, green, blue)
			ModifyGraph/W=$RESISTANCE_GRAPH rgb($trace)=(red, green, blue)
			ModifyGraph/W=$RESISTANCE_GRAPH mode($trace)=3

			WAVE curveFitWave = GetAnalysisFuncDAScaleResFit(panelTitle, i)
			trace = "fit_HS_" + num2str(i)
			AppendToGraph/W=$RESISTANCE_GRAPH/L=VertCrossing/B=HorizCrossing curveFitWave/TN=$trace
			ModifyGraph/W=$RESISTANCE_GRAPH rgb($trace)=(red, green, blue)
			ModifyGraph/W=$RESISTANCE_GRAPH freePos(VertCrossing)={0,HorizCrossing},freePos(HorizCrossing)={0,VertCrossing}, lblLatPos=-50

		endfor
	endif

	if(!IsEmpty(textBoxString))
		TextBox/C/N=text/W=$RESISTANCE_GRAPH RemoveEnding(textBoxString, "\r")
	endif
End

/// @brief Set the DAScale value of the given headstage
///
/// @param panelTitle device
/// @param headstage  MIES headstage
/// @param DAScale    DA scale value in `A` (Amperes)
Function SetDAScale(panelTitle, headstage, DAScale)
	string panelTitle
	variable headstage, DAScale

	variable amps, DAC
	string DAUnit, ctrl

	DAC = AFH_GetDACFromHeadstage(panelTitle, headstage)
	ASSERT(IsFinite(DAC), "This analysis function does not work with unassociated DA channels")

	DAUnit = DAG_GetTextualValue(panelTitle, GetSpecialControlLabel(CHANNEL_TYPE_DAC, CHANNEL_CONTROL_UNIT), index = DAC)

	// check for correct units
	ASSERT(!cmpstr(DAunit, "pA"), "Unexpected DA Unit")

	amps = DAScale / 1e-12
	ctrl = GetPanelControl(DAC, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_SCALE)
	PGC_SetAndActivateControl(panelTitle, ctrl, val = amps)

	return 0
End

/// @brief Analysis function to experimentally determine the cell resistance by sweeping
/// through a wave of target voltages.
///
/// Prerequisites:
/// - Stimset with multiple but identical sweeps and testpulse-like shape. The
///   number of sweeps must be larger than the number of rows in the targetVoltages wave below.
/// - This stimset must have this analysis function set for the "Pre DAQ" and the "Post Sweep" Event
/// - Does not support DA/AD channels not associated with a MIES headstage (aka unassociated DA/AD Channels)
/// - All active headstages must be in "Current Clamp"
/// - An inital DAScale of -20pA is used, a fixup value of -100pA is used on the next sweep if the measured resistance is smaller than 20MOhm
Function ReachTargetVoltage(panelTitle, eventType, ITCDataWave, headStage, realDataLength)
	string panelTitle
	variable eventType
	Wave ITCDataWave
	variable headstage, realDataLength

	variable sweepNo, index, i
	variable amps
	variable autoBiasCheck, holdingPotential
	string msg

	// BEGIN CHANGE ME
	Make/FREE targetVoltages = {0.002, -0.002, -0.005, -0.01, -0.015} // units are Volts, i.e. 70mV = 0.070V
	// END CHANGE ME

	WAVE targetVoltagesIndex = GetAnalysisFuncIndexingHelper(panelTitle)

	WAVE statusHS = DAG_GetChannelState(panelTitle, CHANNEL_TYPE_HEADSTAGE)

	WAVE ampParam = GetAmplifierParamStorageWave(panelTitle)

	switch(eventType)
		case PRE_DAQ_EVENT:
			targetVoltagesIndex[headstage] = -1

			if(DAG_GetHeadstageMode(panelTitle, headstage) != I_CLAMP_MODE)
				printf "(%s) The analysis function %s does only work in clamp mode.\r", panelTitle, GetRTStackInfo(1)
				ControlWindowToFront()
				return 1
			endif

			for(i = 0; i < NUM_HEADSTAGES; i += 1)
				if(!statusHS[i])
					continue
				endif

				autoBiasCheck = ampParam[%AutoBiasEnable][0][i]
				holdingPotential = ampParam[%AutoBiasVcom][0][i]

				if(autoBiasCheck != 1)
					printf "Abort: Autobias for headstage %d not enabled.\r", i
					ControlWindowToFront()
					return 1
				endif

				if(CheckIfClose(holdingPotential, -70, tol=1) != 1)
					if(holdingPotential > -75 && holdingPotential < -65)
						printf "Warning: Holding potential for headstage %d is not -70mV but is within acceptable range, targetV continuing.\r", i
					else
						printf "Abort: Holding potential for headstage %d is set outside of the acceptable range for targetV.\r", i
						ControlWindowToFront()
						return 1
					endif
				endif
			endfor

			KillOrMoveToTrash(wv = GetAnalysisFuncDAScaleDeltaI(panelTitle))
			KillOrMoveToTrash(wv = GetAnalysisFuncDAScaleDeltaV(panelTitle))
			KillOrMoveToTrash(wv = GetAnalysisFuncDAScaleRes(panelTitle))
			KillWindow/Z $RESISTANCE_GRAPH

			SetDAScale(panelTitle, headstage, -20e-12)

			PGC_SetAndActivateControl(panelTitle,"Check_DataAcq1_DistribDaq", val = 1)

			PGC_SetAndActivateControl(panelTitle,"Check_DataAcq1_dDAQOptOv", val = 0)

			PGC_SetAndActivateControl(panelTitle,"Setvar_DataAcq_dDAQDelay", val = 500)

			return Nan
			break
		case POST_SWEEP_EVENT:
			targetVoltagesIndex[headstage] += 1
			break
		default:
			ASSERT(0, "Unknown eventType")
			break
	endswitch

	// only do something if we are called for the very last headstage
	if(DAP_GetHighestActiveHeadstage(panelTitle) != headstage)
		return NaN
	endif

	WAVE/Z sweep = AFH_GetLastSweepWaveAcquired(panelTitle)
	ASSERT(WaveExists(sweep), "Expected a sweep for evaluation")

	sweepNo = ExtractSweepNumber(NameOfWave(sweep))

	WAVE numericalValues = GetLBNumericalValues(panelTitle)
	WAVE textualValues   = GetLBTextualValues(panelTitle)

	Make/D/FREE/N=(LABNOTEBOOK_LAYER_COUNT) deltaV     = NaN
	Make/D/FREE/N=(LABNOTEBOOK_LAYER_COUNT) deltaI     = NaN
	Make/D/FREE/N=(LABNOTEBOOK_LAYER_COUNT) resistance = NaN

	CalculateTPLikePropsFromSweep(numericalValues, textualValues, sweep, deltaI, deltaV, resistance)

	ED_AddEntryToLabnotebook(panelTitle, "Delta I", deltaI, unit = "I")
	ED_AddEntryToLabnotebook(panelTitle, "Delta V", deltaV, unit = "V")

	PlotResistanceGraph(panelTitle)

	WAVE/Z resistanceFitted = GetLastSetting(numericalValues, sweepNo, LABNOTEBOOK_USER_PREFIX + "ResistanceFromFit", UNKNOWN_MODE)
	ASSERT(WaveExists(resistanceFitted), "Expected fitted resistance data")


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
			printf "(%s): Skipping analysis function \"%s\".\r", panelTitle, GetRTStackInfo(1)
			printf "The stimset has too many sweeps, increase the size of DAScales.\r"
			continue
		endif

		// check initial response
		if(index == 0 && resistanceFitted[i] <= 20e6)
			amps = -100e-12
			targetVoltagesIndex[i] = -1
		else
			amps = targetVoltages[index] / resistanceFitted[i]
		endif

		sprintf msg, "(%s, %d): ΔR = %.0W1PΩ, V_target = %.0W1PV, I = %.0W1PA", panelTitle, i, resistanceFitted[i], targetVoltages[targetVoltagesIndex[i]], amps
		DEBUGPRINT(msg)

		SetDAScale(panelTitle, i, amps)
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
///   be a toplevel or subwindow notebook. For multiple matching panels or
///   graphs we prefer the corresponding DAEphys panel and Databrowser.
///
/// Examples:
///
/// \rst
/// .. code-block:: none
///
/// 	setvar_DataAcq_OnsetDelayUser -> Pre DAQ|20|
/// 	Popup_Settings_FixedFreq -> Pre Sweep|100|Post Sweep|Maximum|
/// 	sweepFormula_formula -> Pre Set|data(cursors(A,B), channels(AD), sweeps())
///
/// \endrst
///
Function SetControlInEvent(panelTitle, s)
	string panelTitle
	STRUCT AnalysisFunction_V3 &s

	string guiElements, guiElem, type, valueStr, event, msg, win, windowsWithGUIElement, databrowser, str
	variable numEntries, i, controlType, j, numTuples, numMatches

	if(s.eventType == MID_SWEEP_EVENT)
		return NaN
	endif

	if(s.headstage != DAP_GetHighestActiveHeadstage(panelTitle))
		return NaN
	endif

	guiElements = AFH_GetListOfAnalysisParamNames(s.params)
	numEntries = ItemsInList(guiElements)

	for(i = 0; i < numEntries; i += 1)
		guiElem = StringFromList(i, guiElements)

		if(ControlExists(panelTitle, guiElem))
			windowsWithGUIElement = panelTitle
		else
			windowsWithGUIElement = FindControl(guiElem)
		endif

		numMatches = ItemsInList(windowsWithGUIElement)

		if(numMatches == 1)
			win = StringFromList(0, windowsWithGUIElement)
		elseif(numMatches > 1)
			printf "(%s): The analysis parameter %s is a control which is present in multiple panels or graphs.\r", panelTitle, guiElem
			ControlWindowToFront()
			continue
		else
			ASSERT(numMatches == 0, "invalid code")

			windowsWithGUIElement = FindNotebook(guiElem)
			numMatches = ItemsInList(windowsWithGUIElement)

			if(numMatches == 1)
				win = StringFromList(0, windowsWithGUIElement)
			elseif(numMatches > 1)
				databrowser = DB_FindDataBrowser(panelTitle)
				str = GrepList(windowsWithGUIElement, "^\\Q" + databrowser + "\\E")
				if(!IsEmpty(str))
					// the notebook belongs to the databrowser associated to the DAEphys panel
					win = StringFromList(0, str)
				else
					printf "(%s): The analysis parameter %s is a notebook which is present in multiple panels or graphs.\r", panelTitle, guiElem
					ControlWindowToFront()
					continue
				endif
			else
				ASSERT(numMatches == 0, "invalid code")

				printf "(%s): The analysis parameter %s does not exist as control or notebook in one of the open panels and graphs.\r", panelTitle, guiElem
				ControlWindowToFront()
				continue
			endif
		endif

		// check payload type and format
		type = AFH_GetAnalysisParamType(guiElem, s.params)

		if(cmpstr(type, "textwave"))
			printf "(%s): The analysis parameter's %s type is not \"textwave\".\r", panelTitle, guiElem
			ControlWindowToFront()
			return 1
		endif

		WAVE/T/Z data = AFH_GetAnalysisParamTextWave(guiElem, s.params)

		if(!WaveExists(data))
			printf "(%s): The analysis parameter's %s payload is empty.\r", panelTitle, guiElem
			ControlWindowToFront()
			return 1
		elseif(DimSize(data, ROWS) == 0 || mod(DimSize(data, ROWS), 2) != 0 || DimSize(data, COLS) != 0)
			printf "(%s): The analysis parameter's %s payload has not a multiple of two rows.\r", panelTitle, guiElem
			ControlWindowToFront()
			return 1
		endif

		numTuples = DimSize(data, ROWS)
		for(j = 0; j < numTuples; j += 2)

			// check given event type
			event = data[j]

			if(WhichListItem(event, EVENT_NAME_LIST, ";", 0, 0) == -1 || WhichListItem(event, "Mid Sweep;Generic", ";", 0, 0) != -1)
				printf "(%s): The analysis parameter's %s event \"%s\" is invalid.\r", panelTitle, guiElem, event
				ControlWindowToFront()
				return 1
			elseif(WhichListItem(guiElem, CONTROLS_DISABLE_DURING_DAQ, ";", 0, 0) != -1 && WhichListItem(event, "Pre DAQ;Post DAQ", ";", 0, 0) == -1)
				printf "(%s): The analysis parameter %s is a control which can only be changed in Pre/Post DAQ.\r", panelTitle, guiElem
				ControlWindowToFront()
				return 1
			endif

			// now we can finally check if it is our turn
			if(WhichListItem(event, EVENT_NAME_LIST, ";", 0, 0) != s.eventType)
				continue
			endif

			// set the control
			valueStr = data[j + 1]

			sprintf msg, "%s: Setting control %s to %s in event %s\r", GetRTStackInfo(1), guiElem, valueStr, event
			DEBUGPRINT(msg)

			switch(WinType(win))
				case WINTYPE_GRAPH:
				case WINTYPE_PANEL:
					if(IsControlDisabled(win, guiElem))
						printf "(%s): The analysis parameter %s is a control which is disabled. Therefore it can not be set.\r", panelTitle, guiElem
						ControlWindowToFront()
						return 1
					endif

					controlType = GetControlType(win, guiElem)
					if(controlType == CONTROL_TYPE_SETVARIABLE || controlType == CONTROL_TYPE_POPUPMENU)
						PGC_SetAndActivateControl(win, guiElem, str = valueStr)
					else
						PGC_SetAndActivateControl(win, guiElem, val = str2numSafe(valueStr))
					endif
					break
				case WINTYPE_NOTEBOOK:
					ReplaceNotebookText(win, NormalizeToEOL(valueStr, "\r"))
					break
				default:
					ASSERT(0, "Unexpected window type")
			endswitch
		endfor
	endfor
End
