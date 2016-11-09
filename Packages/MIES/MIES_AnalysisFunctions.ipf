#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

/// @file MIES_AnalysisFunctions.ipf
/// @brief __AF__ Analysis functions to be called during data acquisition
///
/// Function prototypes for analysis functions
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

/// @deprecated Use AF_PROTO_ANALYSIS_FUNC_V2() instead
///
/// @param panelTitle  device
/// @param eventType   eventType, one of @ref EVENT_TYPE_ANALYSIS_FUNCTIONS,
///                    always compare `eventType` with the constants, never use the current numerical value directly
/// @param ITCDataWave data wave (locked to prevent changes using `SetWaveLock`)
/// @param headStage   active headstage index
///
/// @return ignored
Function AF_PROTO_ANALYSIS_FUNC_V1(panelTitle, eventType, ITCDataWave, headStage)
	string panelTitle
	variable eventType
	Wave ITCDataWave
	variable headstage
End

/// @param panelTitle     device
/// @param eventType      eventType, one of @ref EVENT_TYPE_ANALYSIS_FUNCTIONS,
///                       always compare `eventType` with the constants, never use the current numerical value directly
/// @param ITCDataWave    data wave (locked to prevent changes using `SetWaveLock`)
/// @param headStage      active headstage index
/// @param realDataLength number of rows in `ITCDataWave` with data, the total number of rows in `ITCDataWave` might be
///                       higher due to alignment requirements of the data acquisition hardware
///
/// @return see @ref AnalysisFunctionEventDescriptionTable
Function AF_PROTO_ANALYSIS_FUNC_V2(panelTitle, eventType, ITCDataWave, headStage, realDataLength)
	string panelTitle
	variable eventType
	Wave ITCDataWave
	variable headstage, realDataLength

	// return value currently only honoured for `Pre DAQ` event
	return 0
End

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

/// @name Initial parameters for stimulation
///@{
static strCONSTANT STIM_SET_LOCAL = "PulseTrain_150Hz_DA_0"	///< Initial stimulus set
static CONSTANT VM1_LOCAL = -55										///< Initial holding potential	
static CONSTANT VM2_LOCAL = -85										///< Second holding potential to switch to
static CONSTANT SCALE_LOCAL = 70										///< Stimulus amplitude in mV
static CONSTANT NUM_SWEEPS_LOCAL = 6								///< Number of sweeps to acquire
static CONSTANT ITI_LOCAL = 15										///< Inter-trial-interval
///@}

/// @name Initial settings for oodDAQ stimulation
///@{
static CONSTANT POST_DELAY = 150										///< Delay after stimulation event in which no other event can occur in ms
static CONSTANT RESOLUTION = 25										///< Resolution of oodDAQ protocol in ms
///@}

static strCONSTANT panelTitle = "ITC18USB_Dev_0"

/// @brief Force active headstages into voltage clamp
Function SetStimConfig_Vclamp(panelTitle, eventType, ITCDataWave, headStage)
	string panelTitle
	variable eventType
	Wave ITCDataWave
	variable headstage
	
	setVClampMode(panelTitle)
	
	printf "Stimulus set running in V-Clamp on headstage: %d\r", headStage
	
End

/// @brief Change holding potential midway through stim set
Function ChangeHoldingPotential(panelTitle, eventType, ITCDataWave, headStage)
	string panelTitle
	variable eventType
	Wave ITCDataWave
	variable headstage
	
	variable StimRemaining = switchHolding(panelTitle,VM2_LOCAL)
	
	printf "Number of stimuli remaining is: %d on headstage: %d\r", StimRemaining, headStage
End

/// @brief Print last Stim Set run and headstage mode and holding potential
Function LastStimSet(panelTitle, eventType, ITCDataWave, headStage)
	string panelTitle
	variable eventType
	Wave ITCDataWave
	variable headstage
	
	LastStimSetRun(panelTitle)

End
/// @brief GUI to set initial stimulus parameters using SetStimParam() and begin data acquisition. 
/// NOTE: DATA ACQUISITION IS INTIATED AT THE END OF FUNCTION! 
Function StimParamGUI()
	
	string StimSetList = ReturnListOfAllStimSets(CHANNEL_TYPE_DAC,"*DA*")
	
	variable Vm1 = VM1_LOCAL, Scale = SCALE_LOCAL, sweeps = NUM_SWEEPS_LOCAL, ITI = ITI_LOCAL
	string stimSet = STIM_SET_LOCAL 
	Prompt stimSet, "Choose which stimulus set to run:", popup, StimSetList
	Prompt Vm1, "Enter initial holding potential: "
	Prompt Scale, "Enter scale of stimulation [mV]: "
	Prompt sweeps, "Enter number of sweeps to run: "
	Prompt ITI, "Enter inter-trial interval [s]: "
	
	DoPrompt "Choose stimulus set and enter initial parameters", stimSet, Vm1,  Scale, sweeps, ITI
	
	SetStimParam(stimSet,Vm1,Scale,Sweeps,ITI)
	
	PGC_SetAndActivateControl(panelTitle,"DataAcquireButton")
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
	
	setHolding(panelTitle, Vm1)
	
	variable stimSetIndex = GetStimSet(stimSet)
	
	PGC_SetAndActivateControl(panelTitle,"Wave_DA_All", val = stimSetIndex + 1)
	PGC_SetAndActivateControl(panelTitle,"Scale_DA_All", val = scale)
	PGC_SetAndActivateControl(panelTitle,"SetVar_DataAcq_SetRepeats", val = sweeps)
	PGC_SetAndActivateControl(panelTitle,"SetVar_DataAcq_ITI", val = ITI)
	
	InitoodDAQ(panelTitle)

End

/// @brief Set holding potential for active headstages
///
/// @param Vm1		Holding potential
Function setHolding(panelTitle, Vm1)
	string panelTitle
	variable Vm1
	
	WAVE statusHS = DC_ControlStatusWaveCache(panelTitle, CHANNEL_TYPE_HEADSTAGE)
	
	variable i
	
	for (i=0; i<NUM_HEADSTAGES; i+=1)
		if (statusHS[i] == 1)
			PGC_SetAndActivateControl(panelTitle,"slider_DataAcq_ActiveHeadstage", val = i)
			PGC_SetAndActivateControl(panelTitle,"setvar_DataAcq_Hold_VC", val = Vm1)
			PGC_SetAndActivateControl(panelTitle,"setvar_DataAcq_Hold_IC", val = Vm1)
		endif
	endfor
End

/// @brief Set active headstages into V-clamp
Function setVClampMode(panelTitle)
	string panelTitle
	
	WAVE statusHS = DC_ControlStatusWaveCache(panelTitle, CHANNEL_TYPE_HEADSTAGE)
	
	variable i
	
	for (i=0; i<NUM_HEADSTAGES; i+=1)
		if (statusHS[i] == 1)
			PGC_SetAndActivateControl(panelTitle,"slider_DataAcq_ActiveHeadstage", val = i)
			PGC_SetAndActivateControl(panelTitle,"Radio_ClampMode_0", val = 1)
		endif
	endfor
End

/// @brief Change holding potential on active headstages to Vm2.
/// Switch occurs after X/2 number of data sweeps. If X!/2 switchSweep = floor(X/2)
///
/// @param Vm2	Holding potential to switch to
Function switchHolding(panelTitle, Vm2)
	string panelTitle
	variable Vm2
	
	variable numSweeps = GetValDisplayAsNum(panelTitle,"valdisp_DataAcq_SweepsInSet")
	variable switchSweep = floor(numSweeps/2)
	
	WAVE statusHS = DC_ControlStatusWaveCache(panelTitle, CHANNEL_TYPE_HEADSTAGE)
	
	WAVE GuiState = GetDA_EphysGuiStateNum(panelTitle)
	
	variable StimRemaining = GuiState[0][findDimLabel(GuiState,1,"valdisp_DataAcq_TrialsCountdown")]-1
    if (StimRemaining == switchSweep)
        variable i
        for (i=0; i<NUM_HEADSTAGES; i+=1)
            if (statusHS[i] == 1)
                PGC_SetAndActivateControl(panelTitle,"slider_DataAcq_ActiveHeadstage", val = i)
                if (GuiState[i][1] == 0)
                    PGC_SetAndActivateControl(panelTitle,"setvar_DataAcq_Hold_VC", val = Vm2)
                elseif (GuiState[i][1] == 1)
                    PGC_SetAndActivateControl(panelTitle,"setvar_DataAcq_Hold_IC", val = Vm2)
                endif
            endif
        endfor
        printf "Half-way through stim set, changing holding potential to: %d\r", Vm2  
    endif
	
	return StimRemaining
End

/// @brief Get index of stim set from stim set list
Function GetStimSet(stimSet)
	string stimSet
	
	string StimSetList = ReturnListOfAllStimSets(CHANNEL_TYPE_DAC,"*DA*")
	variable stimSetIndex = whichlistitem(stimSet,StimSetList)
	
	return stimSetIndex
End

/// @brief Initialize oodDAQ settings
Function InitoodDAQ(panelTitle)
	string panelTitle
	
	WAVE GuiState = GetDA_EphysGuiStateNum(panelTitle)
	
   variable GuiControl = findDimLabel(GuiState,1,"Check_DataAcq1_dDAQOptOv")				// make sure oodDAQ is enabled
   if (GuiControl != 1)
   		PGC_SetAndActivateControl(panelTitle,"Check_DataAcq1_DistribDaq", val = 1)
   	endif
   	
   	GuiControl = findDimLabel(GuiState,1,"Check_DataAcq_Get_Set_ITI")						// make sure Get/Set ITI is disabled
   	if (GuiControl != 0)
   		PGC_SetAndActivateControl(panelTitle,"Check_DataAcq_Get_Set_ITI", val = 0)
   	endif
   	
   	PGC_SetAndActivateControl(panelTitle,"setvar_DataAcq_dDAQOptOvPost", val = POST_DELAY)
   	PGC_SetAndActivateControl(panelTitle,"setvar_DataAcq_dDAQOptOvRes", val = RESOLUTION)

End

/// @brief Print last full stim set aqcuired
Function LastStimSetRun(panelTitle)
	string panelTitle
	
	WAVE /T textualValues = GetLBTextualValues(panelTitle)
	
	WAVE  numericalValues = GetLBNumericalValues(panelTitle)
	
	WAVE statusHS = DC_ControlStatusWaveCache(panelTitle, CHANNEL_TYPE_HEADSTAGE)
	
	variable LastSweep = GetSetVariable(panelTitle, "SetVar_Sweep")-1
	
	WAVE /T StimSet = GetLastSettingText(textualValues, LastSweep, "Stim Wave Name", DATA_ACQUISITION_MODE)
	WAVE /T clampHS = GetLastSettingText(textualValues, LastSweep, "OperatingModeString", DATA_ACQUISITION_MODE)
	WAVE holdingVC = GetLastSetting(numericalValues, LastSweep, "V-Clamp Holding Level", DATA_ACQUISITION_MODE)
	WAVE holdingIC = GetLastSetting(numericalValues, LastSweep, "I-Clamp Holding Level", DATA_ACQUISITION_MODE)
	
	variable i
	for (i=0; i<NUM_HEADSTAGES; i+=1)
		if (statusHS[i] == 1)
			string StimSet_i = StimSet[i]
			string clampHS_i = clampHS[i]
			variable holding_i
			if (stringmatch(clampHS[i],"V-Clamp*") == 1)
				holding_i = holdingVC[i]
			elseif (stringmatch(clampHS[i],"I-Clamp*") == 1)
				holding_i = holdingIC[i]
			endif
		
			printf "Stimulus Set %s completed on headstage %d in %s mode holding at %d\r", StimSet_i, i, clampHS_i, holding_i
		endif
	endfor
End