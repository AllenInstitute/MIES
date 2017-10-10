#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
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
/// data acquisition cycle. These functions should *never* abort, error out with a runtime error, or open dialogs!
///
/// Useful helper functions are defined in MIES_AnalysisFunctionHelpers.ipf.
///
/// @anchor AnalysisFunctionEventDescriptionTable
///
/// Event      | Description                          | Specialities
/// -----------|--------------------------------------|---------------------------------------------------------------
/// Pre DAQ    | Before any DAQ occurs                | Called before the settings are validated
/// Mid Sweep  | Each time when new data is polled    | Available for background DAQ only
/// Post Sweep | After each sweep                     | None
/// Post Set   | After a *full* set has been acquired | This event is not always reached as the user might not acquire all steps of a set
/// Post DAQ   | After all DAQ has been finished      | None
///
/// The Post Sweep/Set/DAQ functions are *not* executed if a currently running sweep is aborted.
///
/// @anchor AnalysisFunctionReturnTypes Analysis function return types
///
/// Some event types support a range of different return types which let the
/// user decide what should happen next. See also @ref
/// AnalysisFuncReturnTypesConstants.
///
/// Value                             | Event Types | Action
/// ----------------------------------|-------------|-------
/// NaN                               | All         | Nothing
/// 0                                 | All         | Nothing
/// 1                                 | Pre DAQ     | DAQ is prevented to start
/// #ANALYSIS_FUNC_RET_REPURP_TIME    | Mid Sweep   | Current sweep is immediately stopped. Left over time is repurposed for ITI.
/// #ANALYSIS_FUNC_RET_EARLY_STOP     | Mid Sweep   | Current sweep is immediately stopped without honouring the left over time in a special way.

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
static Constant RESOLUTION = 25									 ///< Resolution of oodDAQ protocol in ms
///@}

static StrConstant RESISTANCE_GRAPH = "AnalysisFuncResistanceGraph"

Function TestAnalysisFunction_V1(panelTitle, eventType, ITCDataWave, headStage)
	string panelTitle
	variable eventType
	Wave ITCDataWave
	variable headstage

	printf "Analysis function version 1 called: device %s, eventType \"%s\", headstage %d\r", panelTitle, StringFromList(eventType, EVENT_NAME_LIST), headStage
	printf "Next sweep: %d\r", GetSetVariable(panelTitle, "SetVar_Sweep")
End

Function TestAnalysisFunction_V2(panelTitle, eventType, ITCDataWave, headStage, realDataLength)
	string panelTitle
	variable eventType
	Wave ITCDataWave
	variable headstage, realDataLength

	printf "Analysis function version 2 called: device %s, eventType \"%s\", headstage %d\r", panelTitle, StringFromList(eventType, EVENT_NAME_LIST), headStage
End

Function Enforce_VC(panelTitle, eventType, ITCDataWave, headStage, realDataLength)
	string panelTitle
	variable eventType
	Wave ITCDataWave
	variable headstage, realDataLength

	if(eventType != PRE_DAQ_EVENT)
	   return 0
	endif

	Wave GuiState = GetDA_EphysGuiStateNum(panelTitle)
	if(GuiState[headStage][%HSmode] != V_CLAMP_MODE)
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

	Wave GuiState = GetDA_EphysGuiStateNum(panelTitle)
	if(GuiState[headStage][%HSmode] != I_CLAMP_MODE)
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
	WAVE statusHS = DAP_ControlStatusWaveCache(DEFAULT_DEVICE, CHANNEL_TYPE_HEADSTAGE)

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
	WAVE statusHS = DAP_ControlStatusWaveCache(DEFAULT_DEVICE, CHANNEL_TYPE_HEADSTAGE)

	for(i=0; i<NUM_HEADSTAGES; i+=1)
		if(statusHS[i])
			PGC_SetAndActivateControl(DEFAULT_DEVICE, "slider_DataAcq_ActiveHeadstage", val = CHECKBOX_SELECTED)
			ctrl = DAP_GetClampModeControl(V_CLAMP_MODE, i)
			PGC_SetAndActivateControl(DEFAULT_DEVICE, ctrl, val = CHECKBOX_SELECTED)
		endif
	endfor
End

/// @brief Set active headstages into I-clamp
Function setIClampMode()
	
	variable i
	string ctrl

	WAVE statusHS = DAP_ControlStatusWaveCache(DEFAULT_DEVICE, CHANNEL_TYPE_HEADSTAGE)

	for(i=0; i<NUM_HEADSTAGES; i+=1)
		if(statusHS[i])
			PGC_SetAndActivateControl(DEFAULT_DEVICE, "slider_DataAcq_ActiveHeadstage", val = CHECKBOX_SELECTED)
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

	variable numSweeps, SweepsRemaining, switchSweep, i
	
	numSweeps = GetValDisplayAsNum(DEFAULT_DEVICE, "valdisp_DataAcq_SweepsInSet")
	WAVE GuiState = GetDA_EphysGuiStateNum(DEFAULT_DEVICE)
	SweepsRemaining = GuiState[0][%valdisp_DataAcq_TrialsCountdown]-1

	if(numSweeps <= 1)
		PGC_SetAndActivateControl(DEFAULT_DEVICE, "check_Settings_TPAfterDAQ", val = CHECKBOX_SELECTED)
		printf "Not enough sweeps were acquired, can not switch holding \r"
		return SweepsRemaining
	endif

	switchSweep = floor(numSweeps/2)
	WAVE statusHS = DAP_ControlStatusWaveCache(DEFAULT_DEVICE, CHANNEL_TYPE_HEADSTAGE)

    if(SweepsRemaining == switchSweep)
        for(i=0; i<NUM_HEADSTAGES; i+=1)
            if(statusHS[i])
                PGC_SetAndActivateControl(DEFAULT_DEVICE, "slider_DataAcq_ActiveHeadstage", val = i)
                if(GuiState[i][%HSMode] == V_CLAMP_MODE)
                    PGC_SetAndActivateControl(DEFAULT_DEVICE, "setvar_DataAcq_Hold_VC", val = Vm2)
                elseif(GuiState[i][%HSMode] == I_CLAMP_MODE)
                    PGC_SetAndActivateControl(DEFAULT_DEVICE, "setvar_DataAcq_Hold_IC", val = Vm2)
				else
						printf "Unsupported clamp mode \r"
						return GuiState[i][%HSMode]
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

	WAVE GuiState = GetDA_EphysGuiStateNum(DEFAULT_DEVICE)

	// disable dDAQ

   	PGC_SetAndActivateControl(DEFAULT_DEVICE, "Check_DataAcq1_DistribDaq", val = CHECKBOX_UNSELECTED)

   // make sure oodDAQ is enabled

   	PGC_SetAndActivateControl(DEFAULT_DEVICE, "Check_DataAcq1_dDAQOptOv", val = CHECKBOX_SELECTED)
   
   // make sure Get/Set ITI is disabled

   	PGC_SetAndActivateControl(DEFAULT_DEVICE, "Check_DataAcq_Get_Set_ITI", val = CHECKBOX_UNSELECTED)

   	PGC_SetAndActivateControl(DEFAULT_DEVICE, "setvar_DataAcq_dDAQOptOvPost", val = POST_DELAY)
   	PGC_SetAndActivateControl(DEFAULT_DEVICE,"setvar_DataAcq_dDAQOptOvRes", val = RESOLUTION)

End

/// @brief Print last full stim set aqcuired
Function LastStimSetRun()

	variable LastSweep, i, holding_i
	string StimSet_i, clampHS_i
	
	WAVE /T textualValues = GetLBTextualValues(DEFAULT_DEVICE)
	WAVE  numericalValues = GetLBNumericalValues(DEFAULT_DEVICE)
	WAVE statusHS = DAP_ControlStatusWaveCache(DEFAULT_DEVICE, CHANNEL_TYPE_HEADSTAGE)
	LastSweep = AFH_GetLastSweepAcquired(DEFAULT_DEVICE)

	if (!isInteger(LastSweep))
		printf "No sweeps have been acquired"
		return LastSweep
	endif

	WAVE /T StimSet = GetLastSettingText(textualValues, LastSweep, "Stim Wave Name", DATA_ACQUISITION_MODE)
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

			WAVE GuiState = GetDA_EphysGuiStateNum(panelTitle)
			if(GuiState[headStage][%HSmode] != I_CLAMP_MODE)
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
		SetSetVariable(panelTitle, ctrl, DAScales[index])
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
/// Usually called by AdjustDAScale().
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

	WAVE statusHS = DAP_ControlStatusWaveCache(panelTitle, CHANNEL_TYPE_HEADSTAGE)

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

	WAVE statusHS = DAP_ControlStatusWaveCache(panelTitle, CHANNEL_TYPE_HEADSTAGE)

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
static Function SetDAScale(panelTitle, headstage, DAScale)
	string panelTitle
	variable headstage, DAScale

	variable amps, DAC
	string DAUnit, ctrl

	DAC = AFH_GetDACFromHeadstage(panelTitle, headstage)
	ASSERT(IsFinite(DAC), "This analysis function does not work with unassociated DA channels")

	ctrl = GetPanelControl(DAC, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_UNIT)
	DAUnit = GetSetVariableString(panelTitle, ctrl)

	// check for correct units
	ASSERT(!cmpstr(DAunit, "pA"), "Unexpected DA Unit")

	amps = DAScale / 1e-12
	ctrl = GetPanelControl(DAC, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_SCALE)
	SetSetVariable(panelTitle, ctrl, amps)

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
	
	WAVE statusHS = DAP_ControlStatusWaveCache(panelTitle, CHANNEL_TYPE_HEADSTAGE)
	
	WAVE ampParam = GetAmplifierParamStorageWave(panelTitle)

	switch(eventType)
		case PRE_DAQ_EVENT:
			targetVoltagesIndex[headstage] = -1

			if(DAP_MIESHeadstageMode(panelTitle, headstage) != I_CLAMP_MODE)
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
				
				if(holdingPotential != -70)
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

/// @brief Patch Seq Analysis function for sub threshold stimsets
///
/// Prerequisites:
/// - This stimset must have this analysis function set for the "Pre DAQ", "Mid
///   Sweep", "Post Sweep" and "Post Set" Event
/// - A sweep passes if all tests on all headstages pass
/// - Assumes that the number of sets in all stimsets are equal
/// - Assumes that the stimset has 500ms of pre pulse baseline, a 1000ms (#PATCHSEQ_PULSE_DUR) pulse and at least 1000ms post pulse baseline.
/// - Each 500ms (#PATCHSEQ_BL_EVAL_RANGE_MS) of the baseline is a chunk
///
/// Testing:
/// For testing the sweep/set passing/fail logic define the wave
/// root:overrideResults with as many rows as sweeps in the stimset.  Each
/// entry in that wave determines if the sweep passes (1) or failed (0).
///
/// Reading the results from the labnotebook:
///
/// \rst
/// .. code-block:: igorpro
///
///    WAVE numericalValues = GetLBNumericalValues(panelTitle)
///
///    // set properties
///    variable i, numEntries
///    WAVE/Z sweeps = AFH_GetSweepsFromSameRACycle(numericalValues, sweepNo)
///    ASSERT(WaveExists(sweeps), "Missing RA cycle information, maybe the sweep is too old?")
///
///    numEntries = DimSize(sweeps, ROWS)
///    for(i = 0; i < numEntries; i += 1)
///         setPassed = GetLastSettingIndep(numericalValues, sweeps[i], LABNOTEBOOK_USER_PREFIX + PATCHSEQ_LBN_SET_PASSED, UNKNOWN_MODE)
///         if(isFinite(setPassed))
///         	break
///         endif
///    endfor
///
///    if(setPassed)
///      // set passed
///    else
///      // set did not pass
///    endif
///
///    // single sweep properties
///    sweepPassed = GetLastSettingIndep(numericalValues, sweepNo, LABNOTEBOOK_USER_PREFIX + PATCHSEQ_LBN_SWEEP_PASSED, UNKNOWN_MODE)
///
///    // chunk (500ms portions of the baseline) properties
///    sprintf key, PATCHSEQ_LBN_CHUNK_PASSED_FMT, chunk
///    chunkPassed = GetLastSettingIndep(numericalValues, sweepNo, LABNOTEBOOK_USER_PREFIX + key, UNKNOWN_MODE)
///
///    // single test properties (currently not set/queryable per chunk)
///    rmsShortPassed = GetLastSettingIndep(numericalValues, sweepNo, LABNOTEBOOK_USER_PREFIX + PATCHSEQ_LBN_RMS_SHORT_PASSED, UNKNOWN_MODE)
///    rmsLongPassed  = GetLastSettingIndep(numericalValues, sweepNo, LABNOTEBOOK_USER_PREFIX + PATCHSEQ_LBN_RMS_LONG_PASSED, UNKNOWN_MODE)
///    targetVPassed  = GetLastSettingIndep(numericalValues, sweepNo, LABNOTEBOOK_USER_PREFIX + PATCHSEQ_LBN_TARGETV_PASSED, UNKNOWN_MODE)
///
///    // get fitted resistance from last passing sweep
///    variable lastSweepNo
///    WAVE/Z sweeps = AFH_GetSweepsFromSameRACycle(numericalValues, sweepNo)
///    ASSERT(WaveExists(sweeps), "Missing RA cycle information, maybe the sweep is too old?")
///    lastSweepNo = sweeps[DimSize(sweeps, ROWS) - 1]
///    WAVE/Z resistanceFitted = GetLastSetting(numericalValues, lastSweepNo, LABNOTEBOOK_USER_PREFIX + "ResistanceFromFit", UNKNOWN_MODE)
///	   ASSERT(WaveExists(resistanceFitted), "Expected fitted resistance data")
///	   // resistance for the first headstage can be found in resistanceFitted[0]
/// \endrst
///
/// @verbatim
///
/// Sketch of a stimset with inserted TP, pre pulse baseline (-), pulse (*), and post pulse baseline (-).
///
///  |-|                 ***********************************
///  | |                 |                                 |
///  | |                 |                      \WWW/      |
///  | |                 |                      /   \      |
///  | |                 |                     /wwwww\     |
///  | |                 |                   _|  o_o  |_   |
///  | |                 |      \WWWWWWW/   (_   / \   _)  |
///  | |                 |    _/`  o_o  `\_   |  \_/  |    |
///  | |                 |   (_    (_)    _)  : ~~~~~ :    |
///  | |                 |     \ '-...-' /     \_____/     |
///  | |                 |     (`'-----'`)     [     ]     |
///  | |                 |      `"""""""`      `"""""`     |
///  | |                 |                                 |
/// -| |-----------------|                                 |--------------------------------------------
///
/// ascii art image from: http://ascii.co.uk/art/erniebert
///
/// @endverbatim
///
Function PatchSeqSubThreshold(panelTitle, eventType, ITCDataWave, headStage, realDataLength)
	string panelTitle
	variable eventType
	Wave ITCDataWave
	variable headstage, realDataLength

	variable val, totalOnsetDelay, lastFifoPos
	variable i, sweepNo, fifoInStimsetPoint, fifoInStimsetTime
	variable index, skipToEnd, ret
	variable sweepPassed, setPassed
	variable sweepsInSet, passesInSet, acquiredSweepsInSet, numBaselineChunks
	string msg, stimset

	// only do something if we are called for the very last headstage
	if(DAP_GetHighestActiveHeadstage(panelTitle) != headstage)
		return NaN
	endif

	// BEGIN CHANGE ME
	MAKE/D/FREE DAScales = {-30, -70, -90}
	// END CHANGE ME

	WAVE DAScalesIndex = GetAnalysisFuncIndexingHelper(panelTitle)

	WAVE statusHS = DAP_ControlStatusWaveCache(panelTitle, CHANNEL_TYPE_HEADSTAGE)

	switch(eventType)
		case PRE_DAQ_EVENT:
			DAScalesIndex[headstage] = 0

			if(!GetCheckBoxState(panelTitle, "check_Settings_ITITP"))
				printf "(%s): TP during ITI must be checked\r", panelTitle
				ControlWindowToFront()
				return 1
			elseif(!GetCheckBoxState(panelTitle, "check_DataAcq_AutoBias"))
				printf "(%s): Auto Bias must be checked\r", panelTitle
				ControlWindowToFront()
				return 1
			elseif(!GetCheckBoxState(panelTitle, "check_Settings_MD"))
				printf "(%s): Please check \"Multi Device\" mode.\r", panelTitle
				ControlWindowToFront()
				return 1
			endif

			val = GetSetVariable(panelTitle, "setvar_DataAcq_AutoBiasV")

			if(!IsFinite(val) || CheckIfSmall(val, tol = 1e-12))
				printf "(%s): Autobias value is zero or non-finite\r", panelTitle
				ControlWindowToFront()
				return 1
			endif

			break
		case POST_SWEEP_EVENT:
			sweepNo              = AFH_GetLastSweepAcquired(panelTitle)
			WAVE numericalValues = GetLBNumericalValues(panelTitle)
			WAVE textualValues   = GetLBTextualValues(panelTitle)

			sweepPassed = GetLastSettingIndep(numericalValues, sweepNo, LABNOTEBOOK_USER_PREFIX + PATCHSEQ_LBN_SWEEP_PASSED, UNKNOWN_MODE)
			ASSERT(IsFinite(sweepPassed), "Could not find the sweep passed labnotebook entry")

			WAVE/T stimsets = GetLastSettingText(textualValues, sweepNo, STIM_WAVE_NAME_KEY, DATA_ACQUISITION_MODE)
			stimset = stimsets[headstage]

			sweepsInSet         = IDX_NumberOfTrialsInSet(stimset)
			passesInSet         = NumPassesInSet(panelTitle, sweepNo)
			acquiredSweepsInSet = NumAcquiredSweepsInSet(panelTitle, sweepNo)

			if(!sweepPassed)
				// not enough sweeps left to pass the set
				skipToEnd = (sweepsInSet - acquiredSweepsInSet) < (PATCHSEQ_NUM_SWEEPS_PASSED - passesInSet)
			else
				// sweep passed

				WAVE/Z sweep = GetSweepWave(panelTitle, sweepNo)
				ASSERT(WaveExists(sweep), "Expected a sweep for evaluation")

				Make/D/FREE/N=(LABNOTEBOOK_LAYER_COUNT) deltaV     = NaN
				Make/D/FREE/N=(LABNOTEBOOK_LAYER_COUNT) deltaI     = NaN
				Make/D/FREE/N=(LABNOTEBOOK_LAYER_COUNT) resistance = NaN

				CalculateTPLikePropsFromSweep(numericalValues, textualValues, sweep, deltaI, deltaV, resistance)

				ED_AddEntryToLabnotebook(panelTitle, "Delta I", deltaI, unit = "I")
				ED_AddEntryToLabnotebook(panelTitle, "Delta V", deltaV, unit = "V")

				PlotResistanceGraph(panelTitle)

				if(passesInSet >= PATCHSEQ_NUM_SWEEPS_PASSED)
					skipToEnd = 1
				else
					// set next DAScale value
					DAScalesIndex[headstage] += 1
				endif
			endif

			sprintf msg, "Sweep %s, total sweeps %d, acquired sweeps %d, passed sweeps %d, skipToEnd %s, DAScalesIndex %d\r", SelectString(sweepPassed, "failed", "passed"), sweepsInSet, acquiredSweepsInSet, passesInSet, SelectString(skiptoEnd, "false", "true"), DAScalesIndex[headstage]
			DEBUGPRINT(msg)

			if(skiptoEnd)
				RA_SkipSweeps(panelTitle, inf)
				return NaN
			endif

			break
		case POST_SET_EVENT:
			sweepNo = AFH_GetLastSweepAcquired(panelTitle)
			setPassed = NumPassesInSet(panelTitle, sweepNo) >= PATCHSEQ_NUM_SWEEPS_PASSED

			sprintf msg, "Set has %s\r", SelectString(setPassed, "failed", "passed")
			DEBUGPRINT(msg)

			Make/FREE/N=(LABNOTEBOOK_LAYER_COUNT) result = NaN
			result[INDEP_HEADSTAGE] = setPassed
			ED_AddEntryToLabnotebook(panelTitle, PATCHSEQ_LBN_SET_PASSED, result, unit = "On/Off")

			return NaN
			break
	endswitch

	if(eventType == PRE_DAQ_EVENT || eventType == POST_SWEEP_EVENT)
		for(i = 0; i < NUM_HEADSTAGES; i += 1)
			if(!statusHS[i])
				continue
			endif

			index = DAScalesIndex[i]

			// index equals the number of sweeps in the stimset on the last call (*post* sweep event)
			if(index > DimSize(DAScales, ROWS))
				printf "(%s): The stimset has too many sweeps, increase the size of DAScales.\r", GetRTStackInfo(1)
				continue
			elseif(index < DimSize(DAScales, ROWS))
				SetDAScale(panelTitle, i, DAScales[index] * 1e-12)
			endif
		endfor
	endif

	if(eventType != MID_SWEEP_EVENT)
		return NaN
	endif

	WAVE numericalValues = GetLBNumericalValues(panelTitle)

	// we can't use AFH_GetLastSweepAcquired as the sweep is not yet acquired
	sweepNo = GetSetVariable(panelTitle, "SetVar_Sweep")
	sweepPassed = GetLastSettingIndep(numericalValues, sweepNo, LABNOTEBOOK_USER_PREFIX + PATCHSEQ_LBN_SWEEP_PASSED, UNKNOWN_MODE, defValue = 0)

	if(sweepPassed) // already done
		return NaN
	endif

	// oscilloscope data holds scaled data already
	WAVE OscilloscopeData = GetOscilloscopeWave(panelTitle)
	lastFifoPos = GetNumberFromWaveNote(OscilloscopeData, "lastFifoPos") - 1

	totalOnsetDelay = GetSetVariable(panelTitle, "setvar_DataAcq_OnsetDelayUser") \
					  + GetValDisplayAsNum(panelTitle, "valdisp_DataAcq_OnsetDelayAuto")

	fifoInStimsetPoint = lastFifoPos - totalOnsetDelay / DimDelta(OscilloscopeData, ROWS)
	fifoInStimsetTime  = fifoInStimsetPoint * DimDelta(OscilloscopeData, ROWS)

	numBaselineChunks = GetNumberOfChunks(panelTitle)

	for(i = 0; i < numBaselineChunks; i += 1)

		ret = EvaluateBaselineProperties(panelTitle, sweepNo, i, fifoInStimsetTime, totalOnsetDelay)

		if(IsNaN(ret))
			// NaN: not enough data for check
			//
			// not last chunk: retry on next invocation
			// last chunk: mark sweep as failed
			if(i == numBaselineChunks - 1)
				ret = 1
				break
			else
				return NaN
			endif
		elseif(ret)
			// != 0: failed with special mid sweep return value (on first failure)
			if(i == 0)
				// pre pulse baseline
				// fail sweep
				break
			else
				// post pulse baseline
				// try next chunk
				continue
			endif
		else
			// 0: passed
			if(i == 0)
				// pre pulse baseline
				// try next chunks
				continue
			else
				// post baseline
				// we're done!
				break
			endif
		endif
	endfor

	sweepPassed = (ret == 0)

	sprintf msg, "Sweep %s, last evaluated chunk %d returned with %g\r", SelectString(sweepPassed, "failed", "passed"), i, ret
	DEBUGPRINT(msg)

	// document sweep results
	Make/FREE/N=(LABNOTEBOOK_LAYER_COUNT) result = NaN
	result[INDEP_HEADSTAGE] = sweepPassed

	ED_AddEntryToLabnotebook(panelTitle, PATCHSEQ_LBN_SWEEP_PASSED, result, unit = "On/Off", overrideSweepNo = sweepNo)

	return sweepPassed ? ANALYSIS_FUNC_RET_EARLY_STOP : ret
End

static Constant PATCHSEQ_BL_PRE_PULSE   = 0x0
static Constant PATCHSEQ_BL_POST_PULSE  = 0x1

static Constant PATCHSEQ_RMS_SHORT_TEST = 0x0
static Constant PATCHSEQ_RMS_LONG_TEST  = 0x1
static Constant PATCHSEQ_TARGETV_TEST   = 0x2

/// @brief Evaluate one chunk of the baseline.
///
/// chunk 0: Pre pulse baseline
/// chunk 1: Post pulse baseline
static Function EvaluateBaselineProperties(panelTitle, sweepNo, chunk, fifoInStimsetTime, totalOnsetDelay)
	string panelTitle
	variable sweepNo, chunk, fifoInStimsetTime, totalOnsetDelay

	variable , evalStartTime, evalRangeTime
	variable i, ADC, ADcol, chunkStartTime
	variable targetV, index, testOverrideActive
	variable rmsShortPassedAll, rmsLongPassedAll, chunkPassed
	variable targetVPassedAll, baselineType
	string msg, adUnit, ctrl, key

	if(chunk == 0) // pre pulse baseline
		chunkStartTime = totalOnsetDelay
		baselineType   = PATCHSEQ_BL_PRE_PULSE
	else // post pulse baseline
		 // skip: onset delay, the pulse itself and one chunk of post pulse baseline
		chunkStartTime = (totalOnsetDelay + PATCHSEQ_PULSE_DUR + PATCHSEQ_BL_EVAL_RANGE_MS) + chunk * PATCHSEQ_BL_EVAL_RANGE_MS
		baselineType   = PATCHSEQ_BL_POST_PULSE
	endif

	// not enough data to evaluate
	if(fifoInStimsetTime < chunkStartTime + PATCHSEQ_BL_EVAL_RANGE_MS)
		return NaN
	endif

	WAVE numericalValues = GetLBNumericalValues(panelTitle)
	WAVE textualValues   = GetLBTextualValues(panelTitle)

	sprintf key, PATCHSEQ_LBN_CHUNK_PASSED_FMT, chunk
	chunkPassed = GetLastSettingIndep(numericalValues, sweepNo, LABNOTEBOOK_USER_PREFIX + key, UNKNOWN_MODE, defValue = NaN)

	if(IsFinite(chunkPassed)) // already evaluated
		return !chunkPassed
	endif

	// Rows: baseline types
	// - 0: pre pulse
	// - 1: post pulse
	//
	// Cols: checks
	// - 0: short RMS
	// - 1: long RMS
	// - 2: average voltage
	//
	// Contents:
	//  0: skip test
	//  1: perform test
	Make/FREE/N=(2, 3) testMatrix

	testMatrix[PATCHSEQ_BL_PRE_PULSE][] = 1 // all tests
	testMatrix[PATCHSEQ_BL_POST_PULSE][PATCHSEQ_TARGETV_TEST] = 1

	WAVE OscilloscopeData = GetOscilloscopeWave(panelTitle)

	sprintf msg, "We have some data to evaluate in chunk %d [%g, %g]:  %gms\r", chunk, chunkStartTime, chunkStartTime + PATCHSEQ_BL_EVAL_RANGE_MS, fifoInStimsetTime
	DEBUGPRINT(msg)

	WAVE config = GetITCChanConfigWave(panelTitle)

	Make/FREE/N = (LABNOTEBOOK_LAYER_COUNT) rmsShort       = NaN
	Make/FREE/N = (LABNOTEBOOK_LAYER_COUNT) rmsShortPassed = NaN
	Make/FREE/N = (LABNOTEBOOK_LAYER_COUNT) rmsLong        = NaN
	Make/FREE/N = (LABNOTEBOOK_LAYER_COUNT) rmsLongPassed  = NaN
	Make/FREE/N = (LABNOTEBOOK_LAYER_COUNT) avgVoltage     = NaN
	Make/FREE/N = (LABNOTEBOOK_LAYER_COUNT) targetVPassed  = NaN

	targetV = GetSetVariable(panelTitle, "setvar_DataAcq_AutoBiasV")

	WAVE statusHS = DAP_ControlStatusWaveCache(panelTitle, CHANNEL_TYPE_HEADSTAGE)

	for(i = 0; i < NUM_HEADSTAGES; i += 1)

		if(!statusHS[i])
			continue
		endif

		ADC = AFH_GetADCFromHeadstage(panelTitle, i)
		ASSERT(IsFinite(ADC), "This analysis function does not work with unassociated AD channels")
		ADcol = AFH_GetITCDataColumn(config, ADC, ITC_XOP_CHANNEL_TYPE_ADC)

		ctrl   = GetPanelControl(ADC, CHANNEL_TYPE_ADC, CHANNEL_CONTROL_UNIT)
		ADUnit = GetSetVariableString(panelTitle, ctrl)

		// assuming millivolts
		ASSERT(!cmpstr(ADunit, "mV"), "Unexpected AD Unit")

		if(testMatrix[baselineType][PATCHSEQ_RMS_SHORT_TEST])

			evalStartTime = chunkStartTime + PATCHSEQ_BL_EVAL_RANGE_MS - 1.5
			evalRangeTime = 1.5

			// check 1: RMS of the last 1.5ms of the baseline should be below 0.07mV
			rmsShort[i]       = CalculateRMS(OscilloscopeData, ADCol, evalStartTime, evalRangeTime)
			rmsShortPassed[i] = rmsShort[i] < PATCHSEQ_RMS_SHORT_THRESHOLD

			sprintf msg, "RMS noise short: %g (%s)\r", rmsShort[i], SelectString(rmsShortPassed[i], "failed", "passed")
			DEBUGPRINT(msg)
		else
			sprintf msg, "RMS noise short: (%s)\r", "skipped"
			DEBUGPRINT(msg)
			rmsShortPassed[i] = -1
		endif

		if(!rmsShortPassed[i])
			continue
		endif

		if(testMatrix[baselineType][PATCHSEQ_RMS_LONG_TEST])

			evalStartTime = chunkStartTime
			evalRangeTime = PATCHSEQ_BL_EVAL_RANGE_MS

			// check 2: RMS of the last 500ms of the baseline should be below 0.50mV
			rmsLong[i]       = CalculateRMS(OscilloscopeData, ADCol, evalStartTime, evalRangeTime)
			rmsLongPassed[i] = rmsLong[i] < PATCHSEQ_RMS_LONG_THRESHOLD

			sprintf msg, "RMS noise long: %g (%s)", rmsLong[i], SelectString(rmsLongPassed[i], "failed", "passed")
			DEBUGPRINT(msg)
		else
			sprintf msg, "RMS noise long: (%s)\r", "skipped"
			DEBUGPRINT(msg)
			rmsLongPassed[i] = -1
		endif

		if(!rmsLongPassed[i])
			continue
		endif

		if(testMatrix[baselineType][PATCHSEQ_TARGETV_TEST])

			evalStartTime = chunkStartTime
			evalRangeTime = PATCHSEQ_BL_EVAL_RANGE_MS

			// check 3: Average voltage within 1mV of auto bias target voltage
			avgVoltage[i]    = CalculateAvg(OscilloscopeData, ADCol, evalStartTime, evalRangeTime)
			targetVPassed[i] = abs(avgVoltage[i] - targetV) <= PATCHSEQ_TARGETV_THRESHOLD

			sprintf msg, "Average voltage of %gms: %g (%s)", evalRangeTime, avgVoltage[i], SelectString(targetVPassed[i], "failed", "passed")
			DEBUGPRINT(msg)
		else
			sprintf msg, "Average voltage of %gms: (%s)\r", evalRangeTime, "skipped"
			DEBUGPRINT(msg)
			targetVPassed[i] = -1
		endif

		if(!targetVPassed[i])
			continue
		endif

		// more tests can be added here
	endfor

	// document results per headstage
	ED_AddEntryToLabnotebook(panelTitle, PATCHSEQ_LBN_RMS_SHORT_PASSED, rmsShortPassed, unit = "On/Off", overrideSweepNo = sweepNo)
	ED_AddEntryToLabnotebook(panelTitle, PATCHSEQ_LBN_RMS_LONG_PASSED, rmsLongPassed, unit = "On/Off", overrideSweepNo = sweepNo)
	ED_AddEntryToLabnotebook(panelTitle, PATCHSEQ_LBN_TARGETV_PASSED, targetVPassed, unit = "On/Off", overrideSweepNo = sweepNo)

	if(testMatrix[baselineType][PATCHSEQ_RMS_SHORT_TEST])
		rmsShortPassedAll = WaveMin(rmsShortPassed) == 1
	else
		rmsShortPassedAll = -1
	endif

	if(testMatrix[baselineType][PATCHSEQ_RMS_LONG_TEST])
		rmsLongPassedAll = WaveMin(rmsLongPassed) == 1
	else
		rmsLongPassedAll = -1
	endif

	if(testMatrix[baselineType][PATCHSEQ_TARGETV_TEST])
		targetVPassedAll = WaveMin(targetVPassed) == 1
	else
		targetVPassedAll = -1
	endif

	if(rmsShortPassedAll == -1 && rmsLongPassedAll == - 1 && targetVPassedAll == -1)
		print "All tests were skipped??"
		ControlWindowToFront()
		return NaN
	endif

	chunkPassed = rmsShortPassedAll && rmsLongPassedAll && targetVPassedAll

	// BEGIN TEST
	WAVE/Z/SDFR=root: overrideResults
	testOverrideActive = WaveExists(overrideResults)

	if(testOverrideActive)
		NVAR count = $GetCount(panelTitle)
		chunkPassed = overrideResults[chunk][count]
		printf "TEST OVERRIDE ACTIVE: \"Chunk %d %s\"\r", chunk, SelectString(chunkPassed, "failed", "passed")
	endif
	// END TEST

	// document chunk results
	Make/FREE/N=(LABNOTEBOOK_LAYER_COUNT) result = NaN
	result[INDEP_HEADSTAGE] = chunkPassed
	sprintf key, PATCHSEQ_LBN_CHUNK_PASSED_FMT, chunk
	ED_AddEntryToLabnotebook(panelTitle, key, result, unit = "On/Off", overrideSweepNo = sweepNo)

	if(testOverrideActive)
		if(baselineType == PATCHSEQ_BL_PRE_PULSE)
			if(!chunkPassed)
				return ANALYSIS_FUNC_RET_EARLY_STOP
			else
				return 0
			endif
		elseif(baselineType == PATCHSEQ_BL_POST_PULSE)
			if(!chunkPassed)
				return NaN
			else
				return 0
			else
				ASSERT(0, "unknown baseline type")
			endif
		endif
	endif

	if(baselineType == PATCHSEQ_BL_PRE_PULSE)
		if(!rmsShortPassedAll)
			return ANALYSIS_FUNC_RET_EARLY_STOP
		elseif(!rmsLongPassedAll)
			return ANALYSIS_FUNC_RET_EARLY_STOP
		elseif(!targetVPassedAll)
			NVAR repurposedTime = $GetRepurposedSweepTime(panelTitle)
			repurposedTime = 10
			return ANALYSIS_FUNC_RET_REPURP_TIME
		else
			ASSERT(chunkPassed, "logic error")
			return 0
		endif
	elseif(baselineType == PATCHSEQ_BL_POST_PULSE)
		if(chunkPassed)
			return 0
		else
			return NaN
		endif
	else
		ASSERT(0, "unknown baseline type")
	endif
End

/// @brief Return the number of chunks
///
/// A chunk is #PATCHSEQ_BL_EVAL_RANGE_MS [ms] of baseline
static Function GetNumberOfChunks(panelTitle)
	string panelTitle

	variable length, nonBL, totalOnsetDelay

	WAVE OscilloscopeData    = GetOscilloscopeWave(panelTitle)
	NVAR stopCollectionPoint = $GetStopCollectionPoint(panelTitle)
	totalOnsetDelay = GetSetVariable(panelTitle, "setvar_DataAcq_OnsetDelayUser") \
					  + GetValDisplayAsNum(panelTitle, "valdisp_DataAcq_OnsetDelayAuto")

	length = stopCollectionPoint * DimDelta(OscilloscopeData, ROWS)
	nonBL  = totalOnsetDelay + PATCHSEQ_PULSE_DUR + PATCHSEQ_BL_EVAL_RANGE_MS

	return floor((length - nonBL) / PATCHSEQ_BL_EVAL_RANGE_MS)
End

// @brief Calculate the average from `startTime` spanning
//        `rangeTime` milliseconds
static Function CalculateAvg(wv, column, startTime, rangeTime)
	WAVE wv
	variable column, startTime, rangeTime

	variable rangePoints, startPoints

	startPoints = startTime / DimDelta(wv, ROWS)
	rangePoints = rangeTime / DimDelta(wv, ROWS)

	MatrixOP/FREE data = subWaveC(wv, startPoints, column, rangePoints)
	MatrixOP/FREE avg  = mean(data)

	ASSERT(IsFinite(avg[0]), "result must be finite")

	return avg[0]
End

// @brief Calculate the RMS minus the average from `startTime` spanning
//        `rangeTime` milliseconds
//
// @note: This differs from what WaveStats returns in `V_sdev` as we divide by
//        `N` but WaveStats by `N -1`.
static Function CalculateRMS(wv, column, startTime, rangeTime)
	WAVE wv
	variable column, startTime, rangeTime

	variable rangePoints, startPoints

	startPoints = startTime / DimDelta(wv, ROWS)
	rangePoints = rangeTime / DimDelta(wv, ROWS)

	MatrixOP/FREE data = subWaveC(wv, startPoints, column, rangePoints)
	MatrixOP/FREE avg  = mean(data)
	MatrixOP/FREE rms  = sqrt(sumSqr(data - avg[0]) / numRows(data))

	ASSERT(IsFinite(rms[0]), "result must be finite")

	return rms[0]
End

/// @brief Return the number of already acquired sweeps from the given
///        repeated acquisition cycle.
static Function NumAcquiredSweepsInSet(panelTitle, sweepNo)
	string panelTitle
	variable sweepNo

	WAVE numericalValues = GetLBNumericalValues(panelTitle)

	WAVE/Z sweeps = AFH_GetSweepsFromSameRACycle(numericalValues, sweepNo)

	if(!WaveExists(sweeps)) // very unlikely
		return 0
	endif

	return DimSize(sweeps, ROWS)
End

/// @brief Return the number of passed sweeps in all sweeps from the given
///        repeated acquisition cycle.
static Function NumPassesInSet(panelTitle, sweepNo)
	string panelTitle
	variable sweepNo

	WAVE numericalValues = GetLBNumericalValues(panelTitle)

	WAVE/Z sweeps = AFH_GetSweepsFromSameRACycle(numericalValues, sweepNo)

	if(!WaveExists(sweeps)) // very unlikely
		return NaN
	endif

	Make/FREE/N=(DimSize(sweeps, ROWS)) passes
	passes[] = GetLastSettingIndep(numericalValues, sweeps[p], LABNOTEBOOK_USER_PREFIX + PATCHSEQ_LBN_SWEEP_PASSED, UNKNOWN_MODE)

	return sum(passes)
End

/// CreateOverrideResults("ITC18USB_DEV_0", 0)
///
/// Rows:
/// - chunks
///
/// Cols:
/// - sweeps/steps
Function/WAVE CreateOverrideResults(panelTitle, headstage)
	string panelTitle
	variable headstage

	variable DAC = AFH_GetDACFromHeadstage(panelTitle, headstage)
	string stimset = AFH_GetStimSetName(panelTitle, DAC, CHANNEL_TYPE_DAC)
	WAVE wv = WB_CreateAndGetStimSet(stimset)

	Make/O/B/N=(GetNumberOfChunks(panelTitle), IDX_NumberOfTrialsInSet(stimset)) root:overrideResults/WAVE=overrideResults

	overrideResults = 0

	return overrideResults
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