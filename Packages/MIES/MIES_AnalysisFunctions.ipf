#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

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
/// Event      | Description                          | Analysis function return value            | Specialities
/// -----------|--------------------------------------|-------------------------------------------|---------------------------------------------------------------
/// Pre DAQ    | Before any DAQ occurs                | Return 1 to *not* start data acquisition  | Called before the settings are validated
/// Mid Sweep  | Each time when new data is polled    | Ignored                                   | Available for background DAQ only
/// Post Sweep | After each sweep                     | Ignored                                   | None
/// Post Set   | After a *full* set has been acquired | Ignored                                   | This event is not always reached as the user might not acquire all steps of a set
/// Post DAQ   | After all DAQ has been finished      | Ignored                                   | None

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

	StimSetList = ReturnListOfAllStimSets(CHANNEL_TYPE_DAC,"*DA*")
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
	WAVE statusHS = DC_ControlStatusWaveCache(DEFAULT_DEVICE, CHANNEL_TYPE_HEADSTAGE)

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
	WAVE statusHS = DC_ControlStatusWaveCache(DEFAULT_DEVICE, CHANNEL_TYPE_HEADSTAGE)

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

	WAVE statusHS = DC_ControlStatusWaveCache(DEFAULT_DEVICE, CHANNEL_TYPE_HEADSTAGE)

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
	WAVE statusHS = DC_ControlStatusWaveCache(DEFAULT_DEVICE, CHANNEL_TYPE_HEADSTAGE)

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

	string StimSetList = ReturnListOfAllStimSets(CHANNEL_TYPE_DAC,"*DA*")
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
	WAVE statusHS = DC_ControlStatusWaveCache(DEFAULT_DEVICE, CHANNEL_TYPE_HEADSTAGE)
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
