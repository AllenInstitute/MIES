#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MiesTesting
#endif

/// @file MIES_AmplifierInteraction.ipf
/// @brief __AI__ Interface with the Axon/MCC amplifiers

static Constant ZERO_TOLERANCE = 100 // pA

static StrConstant AMPLIFIER_CONTROLS_VC = "setvar_DataAcq_Hold_VC;check_DataAcq_Amp_Chain;check_DatAcq_HoldEnableVC;setvar_DataAcq_WCC;setvar_DataAcq_WCR;check_DatAcq_WholeCellEnable;setvar_DataAcq_RsCorr;setvar_DataAcq_RsPred;check_DataAcq_Amp_Chain;check_DatAcq_RsCompEnable;setvar_DataAcq_PipetteOffset_VC;button_DataAcq_FastComp_VC;button_DataAcq_SlowComp_VC;button_DataAcq_AutoPipOffset_VC"
static StrConstant AMPLIFIER_CONTROLS_IC = "setvar_DataAcq_Hold_IC;check_DatAcq_HoldEnable;setvar_DataAcq_BB;check_DatAcq_BBEnable;setvar_DataAcq_CN;check_DatAcq_CNEnable;setvar_DataAcq_AutoBiasV;setvar_DataAcq_AutoBiasVrange;setvar_DataAcq_IbiasMax;check_DataAcq_AutoBias;setvar_DataAcq_PipetteOffset_IC;button_DataAcq_AutoBridgeBal_IC"
static Constant MAX_PIPETTEOFFSET = 150 // mV
static Constant MIN_PIPETTEOFFSET = -150

#if exists("MCC_GetMode") && exists("AxonTelegraphGetDataStruct")
#define AMPLIFIER_XOPS_PRESENT
#endif

static Function AI_InitAxonTelegraphStruct(tds)
	struct AxonTelegraph_DataStruct& tds

	tds.version = 13
End

static Structure AxonTelegraph_DataStruct
	uint32 Version	///< Structure version.  Value should always be 13.
	uint32 SerialNum
	uint32 ChannelID
	uint32 ComPortID
	uint32 AxoBusID
	uint32 OperatingMode
	String OperatingModeString
	uint32 ScaledOutSignal
	String ScaledOutSignalString
	double Alpha
	double ScaleFactor
	uint32 ScaleFactorUnits
	String ScaleFactorUnitsString
	double LPFCutoff
	double MembraneCap
	double ExtCmdSens
	uint32 RawOutSignal
	String RawOutSignalString
	double RawScaleFactor
	uint32 RawScaleFactorUnits
	String RawScaleFactorUnitsString
	uint32 HardwareType
	String HardwareTypeString
	double SecondaryAlpha
	double SecondaryLPFCutoff
	double SeriesResistance
EndStructure

/// @brief Returns the serial number of the headstage compatible with Axon* functions, @see GetChanAmpAssign
static Function AI_GetAmpAxonSerial(panelTitle, headStage)
	string panelTitle
	variable headStage

	Wave ChanAmpAssign = GetChanAmpAssign(panelTitle)

	return ChanAmpAssign[%AmpSerialNo][headStage]
End

/// @brief Returns the serial number of the headstage compatible with MCC* functions, @see GetChanAmpAssign
static Function/S AI_GetAmpMCCSerial(panelTitle, headStage)
	string panelTitle
	variable headStage

	variable axonSerial
	string mccSerial

	axonSerial = AI_GetAmpAxonSerial(panelTitle, headStage)

	if(axonSerial == 0)
		return "Demo"
	else
		sprintf mccSerial, "%08d", axonSerial
		return mccSerial
	endif
End

///@brief Return the channel of the currently selected head stage
static Function AI_GetAmpChannel(panelTitle, headStage)
	string panelTitle
	variable headStage

	Wave ChanAmpAssign = GetChanAmpAssign(panelTitle)

	return ChanAmpAssign[%AmpChannelID][headStage]
End

static Function AI_IsValidSerialAndChannel([mccSerial, axonSerial, channel])
	string mccSerial
	variable axonSerial
	variable channel

	if(!ParamIsDefault(mccSerial))
		if(isEmpty(mccSerial))
			return 0
		endif
	endif

	if(!ParamIsDefault(axonSerial))
		if(!IsFinite(axonSerial))
			return 0
		endif
	endif

	if(!ParamIsDefault(channel))
		if(!IsFinite(channel))
			return 0
		endif
	endif

	return 1
End
/// @brief Return the unit prefixes used by MIES in comparison to the MCC app
///
/// @param clampMode clamp mode (pass `NaN` for doesn't matter)
/// @param func      MCC function,  one of @ref AI_SendToAmpConstants
Function AI_GetMCCScale(clampMode, func)
	variable clampMode, func

	if(IsFinite(clampMode))
		AI_AssertOnInvalidClampMode(clampMode)
	endif

	if(clampMode == V_CLAMP_MODE)
		switch(func)
			case MCC_SETHOLDING_FUNC:
				return 1e-3
			case MCC_GETHOLDING_FUNC:
				return 1e+3
			case MCC_SETPIPETTEOFFSET_FUNC:
				return 1e-3
			case MCC_GETPIPETTEOFFSET_FUNC:
			case MCC_AUTOPIPETTEOFFSET_FUNC:
				return 1e+3
			case MCC_SETRSCOMPBANDWIDTH_FUNC:
				return 1e+3
			case MCC_GETRSCOMPBANDWIDTH_FUNC:
				return 1e-3
			case MCC_GETWHOLECELLCOMPCAP_FUNC:
				return 1e+12
			case MCC_SETWHOLECELLCOMPRESIST_FUNC:
				return 1e+6
			case MCC_GETWHOLECELLCOMPRESIST_FUNC:
				return 1e-6
			case MCC_SETWHOLECELLCOMPCAP_FUNC:
				return 1e-12
			case MCC_GETWHOLECELLCOMPCAP_FUNC:
				return 1e+12
			default:
				return 1
				break
		endswitch
	else // IC and I=0
		switch(func)
			case MCC_SETBRIDGEBALRESIST_FUNC:
				return 1e+6
			case MCC_GETBRIDGEBALRESIST_FUNC:
			case MCC_AUTOBRIDGEBALANCE_FUNC:
				return 1e-6
			case MCC_SETHOLDING_FUNC:
				return 1e-12
			case MCC_GETHOLDING_FUNC:
				return 1e+12
			case MCC_SETPIPETTEOFFSET_FUNC:
				return 1e-3
			case MCC_GETPIPETTEOFFSET_FUNC:
			case MCC_AUTOPIPETTEOFFSET_FUNC:
				return 1e+3
			case MCC_SETNEUTRALIZATIONCAP_FUNC:
				return 1e-12
			case MCC_GETNEUTRALIZATIONCAP_FUNC:
				return 1e+12
			default:
				return 1
				break
		endswitch
	endif
End

/// @brief Update the AmpStorageWave entry and send the value to the amplifier
///
/// Additionally setting the GUI value if the given headstage is the selected one
/// and a value has been passed.
///
/// @param panelTitle       device
/// @param ctrl             name of the amplifier control
/// @param headStage        MIES headstage number, must be in the range [0, NUM_HEADSTAGES]
/// @param value            [optional: defaults to the controls value] value to set. values is in MIES units, see AI_SendToAmp()
///                         and there the description of `usePrefixes`.
/// @param sendToAll        [optional: defaults to the state of the checkbox] should the value be send
///                         to all active headstages (true) or just to the given one (false)
/// @param checkBeforeWrite [optional, defaults to false] (ignored for getter functions)
///                         check the current value and do nothing if it is equal within some tolerance to the one written
/// @param selectAmp        [optional, defaults to true] Select the amplifier
///                         before use, some callers might save time in doing that once themselves.
///
/// @return 0 on success, 1 otherwise
Function AI_UpdateAmpModel(panelTitle, ctrl, headStage, [value, sendToAll, checkBeforeWrite, selectAmp])
	string panelTitle
	string ctrl
	variable headStage, value, sendToAll, checkBeforeWrite, selectAmp

	variable i, diff, selectedHeadstage, clampMode, oppositeMode, oldTab
	variable runMode = TEST_PULSE_NOT_RUNNING
	string str, rowLabel, rowLabelOpposite, ctrlToCall, ctrlToCallOpposite

	DAP_AbortIfUnlocked(panelTitle)

	selectedHeadstage = DAG_GetNumericalValue(panelTitle, "slider_DataAcq_ActiveHeadstage")

	if(ParamIsDefault(value))
		ASSERT(headstage == selectedHeadstage, "Supply the optional argument value if setting values of other headstages than the current one")
		// we don't use a wrapper here as we want to be able to query different control types
		ControlInfo/W=$panelTitle $ctrl
		ASSERT(V_flag != 0, "non-existing window or control")
		value = v_value
	endif

	if(ParamIsDefault(selectAmp))
		selectAmp = 1
	else
		selectAmp = !!selectAmp
	endif

	if(ParamIsDefault(sendToAll))
		if(headstage == selectedHeadstage)
			sendToAll = DAG_GetNumericalValue(panelTitle, "Check_DataAcq_SendToAllAmp")
		else
			sendToAll = 0
		endif
	else
		sendToAll = !!sendToAll
	endif

	WAVE AmpStoragewave = GetAmplifierParamStorageWave(panelTitle)

	WAVE statusHS = DAG_GetChannelState(panelTitle, CHANNEL_TYPE_HEADSTAGE)
	if(!sendToAll)
		statusHS[] = (p == headStage ? 1 : 0)
	endif

	if(!CheckIfValueIsInsideLimits(panelTitle, ctrl, value))
		DEBUGPRINT("Ignoring value to set as it is out of range compared to the control limits")
		return 1
	endif

	if(ParamIsDefault(checkBeforeWrite))
		checkBeforeWrite = 0
	endif

	strswitch(ctrl)
		case "button_DataAcq_AutoPipOffset_IC":
		case "button_DataAcq_AutoPipOffset_VC":
			if(!DeviceHasFollower(panelTitle))
				runMode = TP_StopTestPulseFast(panelTitle)
			endif
		default:
			// do nothing
	endswitch

	for(i = 0; i < NUM_HEADSTAGES; i += 1)

		if(!statusHS[i])
			continue
		endif

		if(selectAmp)
			if(AI_SelectMultiClamp(panelTitle, i) != AMPLIFIER_CONNECTION_SUCCESS)
				continue
			endif
		endif

		sprintf str, "headstage %d, ctrl %s, value %g", i, ctrl, value
		DEBUGPRINT(str)

		strswitch(ctrl)
			//V-clamp controls
			case "setvar_DataAcq_Hold_VC":
				AmpStorageWave[0][0][i] = value
				AI_SendToAmp(panelTitle, i, V_CLAMP_MODE, MCC_SETHOLDING_FUNC, value, checkBeforeWrite=checkBeforeWrite, selectAmp = 0)
				TP_UpdateHoldCmdInTPStorage(panelTitle, headstage)
				break
			case "check_DatAcq_HoldEnableVC":
				AmpStorageWave[1][0][i] = value
				AI_SendToAmp(panelTitle, i, V_CLAMP_MODE, MCC_SETHOLDINGENABLE_FUNC, value, checkBeforeWrite=checkBeforeWrite, selectAmp = 0)
				TP_UpdateHoldCmdInTPStorage(panelTitle, headstage)
				break
			case "setvar_DataAcq_WCC":
				AmpStorageWave[2][0][i] = value
				AI_SendToAmp(panelTitle, i, V_CLAMP_MODE, MCC_SETWHOLECELLCOMPCAP_FUNC, value, checkBeforeWrite=checkBeforeWrite, selectAmp = 0)
				break
			case "setvar_DataAcq_WCR":
				AmpStorageWave[3][0][i] = value
				AI_SendToAmp(panelTitle, i, V_CLAMP_MODE, MCC_SETWHOLECELLCOMPRESIST_FUNC, value, checkBeforeWrite=checkBeforeWrite, selectAmp = 0)
				break
			case "button_DataAcq_WCAuto":
				AI_SendToAmp(panelTitle, i, V_CLAMP_MODE, MCC_AUTOWHOLECELLCOMP_FUNC, NaN, checkBeforeWrite=checkBeforeWrite, selectAmp = 0)
				value = AI_SendToAmp(panelTitle, i, V_CLAMP_MODE, MCC_GETWHOLECELLCOMPCAP_FUNC, NaN, checkBeforeWrite=checkBeforeWrite, selectAmp = 0)
				AmpStorageWave[%WholeCellCap][0][i] = value
				AI_UpdateAmpView(panelTitle, i, ctrl =  "setvar_DataAcq_WCC")
				value = AI_SendToAmp(panelTitle, i, V_CLAMP_MODE, MCC_GETWHOLECELLCOMPRESIST_FUNC, NaN, checkBeforeWrite=checkBeforeWrite, selectAmp = 0)
				AmpStorageWave[%WholeCellRes][0][i] = value
				AI_UpdateAmpView(panelTitle, i, ctrl =  "setvar_DataAcq_WCR")
				value = AI_SendToAmp(panelTitle, i, V_CLAMP_MODE, MCC_GETWHOLECELLCOMPENABLE_FUNC, NaN, checkBeforeWrite=checkBeforeWrite, selectAmp = 0)
				AmpStorageWave[%WholeCellEnable][0][i] = value
				AI_UpdateAmpView(panelTitle, i, ctrl =  "check_DatAcq_WholeCellEnable")
				break
			case "check_DatAcq_WholeCellEnable":
				AmpStorageWave[4][0][i] = value
				AI_SendToAmp(panelTitle, i, V_CLAMP_MODE, MCC_SETWHOLECELLCOMPENABLE_FUNC, value, checkBeforeWrite=checkBeforeWrite, selectAmp = 0)
				break
			case "setvar_DataAcq_RsCorr":
				diff = value - AmpStorageWave[%Correction][0][i]
				// abort if the corresponding value with chaining would be outside the limits
				if(AmpStorageWave[%RSCompChaining][0][i] && !CheckIfValueIsInsideLimits(panelTitle, "setvar_DataAcq_RsPred", AmpStorageWave[%Prediction][0][i] + diff))
					AI_UpdateAmpView(panelTitle, i, ctrl = ctrl)
					return 1
				endif
				AmpStorageWave[%Correction][0][i] = value
				AI_SendToAmp(panelTitle, i, V_CLAMP_MODE, MCC_SETRSCOMPCORRECTION_FUNC, value, checkBeforeWrite=checkBeforeWrite, selectAmp = 0)
				if(AmpStorageWave[%RSCompChaining][0][i])
					AmpStorageWave[%Prediction][0][i] += diff
					AI_SendToAmp(panelTitle, i, V_CLAMP_MODE, MCC_SETRSCOMPPREDICTION_FUNC, AmpStorageWave[%Prediction][0][i], checkBeforeWrite=checkBeforeWrite, selectAmp = 0)
					AI_UpdateAmpView(panelTitle, i, ctrl =  "setvar_DataAcq_RsPred")
				endif
				break
			case "setvar_DataAcq_RsPred":
				diff = value - AmpStorageWave[%Prediction][0][i]
				// abort if the corresponding value with chaining would be outside the limits
				if(AmpStorageWave[%RSCompChaining][0][i] && !CheckIfValueIsInsideLimits(panelTitle, "setvar_DataAcq_RsCorr", AmpStorageWave[%Correction][0][i] + diff))
					AI_UpdateAmpView(panelTitle, i, ctrl = ctrl)
					return 1
				endif
				AmpStorageWave[%Prediction][0][i] = value
				AI_SendToAmp(panelTitle, i, V_CLAMP_MODE, MCC_SETRSCOMPPREDICTION_FUNC, value, checkBeforeWrite=checkBeforeWrite, selectAmp = 0)
				if(AmpStorageWave[%RSCompChaining][0][i])
					AmpStorageWave[%Correction][0][i] += diff
					AI_SendToAmp(panelTitle, i, V_CLAMP_MODE, MCC_SETRSCOMPCORRECTION_FUNC, AmpStorageWave[%Correction][0][i], checkBeforeWrite=checkBeforeWrite, selectAmp = 0)
					AI_UpdateAmpView(panelTitle, i, ctrl =  "setvar_DataAcq_RsCorr")
				endif
				break
			case "check_DatAcq_RsCompEnable":
				AmpStorageWave[7][0][i] = value
				AI_SendToAmp(panelTitle, i, V_CLAMP_MODE, MCC_SETRSCOMPENABLE_FUNC, value, checkBeforeWrite=checkBeforeWrite, selectAmp = 0)
				break
			case "setvar_DataAcq_PipetteOffset_VC":
				AmpStorageWave[%PipetteOffsetVC][0][i] = value
				AI_SendToAmp(panelTitle, i, V_CLAMP_MODE, MCC_SETPIPETTEOFFSET_FUNC, value, checkBeforeWrite=checkBeforeWrite, selectAmp = 0)
				break
			case "button_DataAcq_AutoPipOffset_IC":
			case "button_DataAcq_AutoPipOffset_VC":
				clampMode = DAG_GetHeadstageMode(panelTitle, i)

				if(clampMode == V_CLAMP_MODE)
					ctrlToCall         = "setvar_DataAcq_PipetteOffset_VC"
					ctrlToCallOpposite = "setvar_DataAcq_PipetteOffset_IC"
					rowLabel           = "PipetteOffsetVC"
					rowLabelOpposite   = "PipetteOffsetIC"
					oppositeMode       = I_CLAMP_MODE
				else
					ctrlToCall         = "setvar_DataAcq_PipetteOffset_IC"
					ctrlToCallOpposite = "setvar_DataAcq_PipetteOffset_VC"
					rowLabel           = "PipetteOffsetIC"
					rowLabelOpposite   = "PipetteOffsetVC"
					oppositeMode       = V_CLAMP_MODE
				endif

				value = AI_SendToAmp(panelTitle, i, clampMode, MCC_AUTOPIPETTEOFFSET_FUNC, NaN, checkBeforeWrite=checkBeforeWrite, selectAmp = 0)
				AmpStorageWave[%$rowLabel][0][i] = value
				AI_UpdateAmpView(panelTitle, i, ctrl=ctrlToCall)
				// the pipette offset for the opposite mode has also changed, fetch that too
				try
					oldTab = GetTabID(panelTitle, "ADC")
					if(oldTab != 0)
						PGC_SetAndActivateControl(panelTitle, "ADC", val=0)
					endif

					DAP_ChangeHeadStageMode(panelTitle, oppositeMode, i, MCC_SKIP_UPDATES)
					// selecting amplifier here, as the clamp mode is now different
					value = AI_SendToAmp(panelTitle, i, oppositeMode, MCC_GETPIPETTEOFFSET_FUNC, NaN, checkBeforeWrite=checkBeforeWrite, selectAmp = 1)
					AmpStorageWave[%$rowLabelOpposite][0][i] = value
					AI_UpdateAmpView(panelTitle, i, ctrl=ctrlToCallOpposite)
					DAP_ChangeHeadStageMode(panelTitle, clampMode, i, MCC_SKIP_UPDATES)

					if(oldTab != 0)
						PGC_SetAndActivateControl(panelTitle, "ADC", val=oldTab)
					endif
				catch
					if(DAG_GetNumericalValue(panelTitle, "check_Settings_SyncMiesToMCC"))
						printf "(%s) The pipette offset for %s of headstage %d is invalid.\r", panelTitle, ConvertAmplifierModeToString(oppositeMode), i
					endif
					// do nothing
				endtry

				break
			case "button_DataAcq_FastComp_VC":
				AmpStorageWave[%FastCapacitanceComp][0][i] = value
				AI_SendToAmp(panelTitle, i, V_CLAMP_MODE, MCC_AUTOFASTCOMP_FUNC, NaN, checkBeforeWrite=checkBeforeWrite, selectAmp = 0)
				break
			case "button_DataAcq_SlowComp_VC":
				AmpStorageWave[%SlowCapacitanceComp][0][i] = value
				AI_SendToAmp(panelTitle, i, V_CLAMP_MODE, MCC_AUTOSLOWCOMP_FUNC, NaN, checkBeforeWrite=checkBeforeWrite, selectAmp = 0)
				break
			case "check_DataAcq_Amp_Chain":
				AmpStorageWave[%RSCompChaining][0][i] = value
				AI_UpdateAmpModel(panelTitle, "setvar_DataAcq_RsCorr", i, value=AmpStorageWave[5][0][i], selectAmp = 0)
				break
			// I-Clamp controls
			case "setvar_DataAcq_Hold_IC":
				AmpStorageWave[16][0][i] = value
				AI_SendToAmp(panelTitle, i, I_CLAMP_MODE, MCC_SETHOLDING_FUNC, value, checkBeforeWrite=checkBeforeWrite, selectAmp = 0)
				TP_UpdateHoldCmdInTPStorage(panelTitle, headstage)
				break
			case "check_DatAcq_HoldEnable":
				AmpStorageWave[17][0][i] = value
				AI_SendToAmp(panelTitle, i, I_CLAMP_MODE, MCC_SETHOLDINGENABLE_FUNC, value, checkBeforeWrite=checkBeforeWrite, selectAmp = 0)
				TP_UpdateHoldCmdInTPStorage(panelTitle, headstage)
				break
			case "setvar_DataAcq_BB":
				AmpStorageWave[18][0][i] = value
				AI_SendToAmp(panelTitle, i, I_CLAMP_MODE, MCC_SETBRIDGEBALRESIST_FUNC, value, checkBeforeWrite=checkBeforeWrite, selectAmp = 0)
				break
			case "check_DatAcq_BBEnable":
				AmpStorageWave[19][0][i] = value
				AI_SendToAmp(panelTitle, i, I_CLAMP_MODE, MCC_SETBRIDGEBALENABLE_FUNC, value, checkBeforeWrite=checkBeforeWrite, selectAmp = 0)
				break
			case "setvar_DataAcq_CN":
				AmpStorageWave[20][0][i] = value
				AI_SendToAmp(panelTitle, i, I_CLAMP_MODE, MCC_SETNEUTRALIZATIONCAP_FUNC, value, checkBeforeWrite=checkBeforeWrite, selectAmp = 0)
				break
			case "check_DatAcq_CNEnable":
				AmpStorageWave[21][0][i] = value
				AI_SendToAmp(panelTitle, i, I_CLAMP_MODE, MCC_SETNEUTRALIZATIONENABL_FUNC, value, checkBeforeWrite=checkBeforeWrite, selectAmp = 0)
				break
			case "setvar_DataAcq_AutoBiasV":
				AmpStorageWave[22][0][i] = value
				break
			case "setvar_DataAcq_AutoBiasVrange":
				AmpStorageWave[23][0][i] = value
				break
			case "setvar_DataAcq_IbiasMax":
				AmpStorageWave[24][0][i] = value
				break
			case "check_DataAcq_AutoBias":
				AmpStorageWave[25][0][i] = value
				break
			case "button_DataAcq_AutoBridgeBal_IC":
				value = AI_SendToAmp(panelTitle, i, I_CLAMP_MODE, MCC_AUTOBRIDGEBALANCE_FUNC, NaN, checkBeforeWrite=checkBeforeWrite, selectAmp = 0)
				AI_UpdateAmpModel(panelTitle, "setvar_DataAcq_BB", i, value=value, selectAmp = 0)
				AI_UpdateAmpModel(panelTitle, "check_DatAcq_BBEnable", i, value=1, selectAmp = 0)
				break
			case "setvar_DataAcq_PipetteOffset_IC":
				AmpStorageWave[%PipetteOffsetIC][0][i] = value
				AI_SendToAmp(panelTitle, i, I_CLAMP_MODE, MCC_SETPIPETTEOFFSET_FUNC, value, checkBeforeWrite=checkBeforeWrite, selectAmp = 0)
				break
			default:
				ASSERT(0, "Unknown control " + ctrl)
				break
		endswitch

		if(!ParamIsDefault(value))
			AI_UpdateAmpView(panelTitle, i, ctrl = ctrl)
		endif
	endfor

	if(!DeviceHasFollower(panelTitle))
		TP_RestartTestPulse(panelTitle, runMode, fast = 1)
	endif

	return 0
End

/// @brief Convenience wrapper for #AI_UpdateAmpView
///
/// Disallows setting single controls for outside callers as #AI_UpdateAmpModel should be used for that.
Function AI_SyncAmpStorageToGUI(panelTitle, headstage)
	string panelTitle
	variable headstage

	return AI_UpdateAmpView(panelTitle, headstage)
End

/// @brief Sync the settings from the GUI to the amp storage wave and the MCC application
Function AI_SyncGUIToAmpStorageAndMCCApp(panelTitle, headStage, clampMode)
	string panelTitle
	variable headStage, clampMode

	string ctrl, list
	variable i, numEntries

	DAP_AbortIfUnlocked(panelTitle)
	AI_AssertOnInvalidClampMode(clampMode)

	if(DAG_GetNumericalValue(panelTitle, "slider_DataAcq_ActiveHeadstage") != headStage)
		return NaN
	endif

	AI_EnsureCorrectMode(panelTitle, headStage, selectAmp = 1)

	if(clampMode == V_CLAMP_MODE)
		list = AMPLIFIER_CONTROLS_VC
	else
		list = AMPLIFIER_CONTROLS_IC
	endif

	numEntries = ItemsInList(list)
	for(i = 0; i < numEntries; i += 1)
		ctrl = StringFromList(i, list)

		if(StringMatch(ctrl, "button_*"))
			continue
		endif

		AI_UpdateAmpModel(panelTitle, ctrl, headStage, checkBeforeWrite=1, sendToAll = 0, selectAmp = 0)
	endfor
End

/// @brief Synchronizes the AmpStorageWave to the amplifier GUI control
///
/// @param panelTitle  device
/// @param headStage   MIES headstage number, must be in the range [0, NUM_HEADSTAGES]
/// @param ctrl        [optional, defaults to all controls] name of the control being updated
static Function AI_UpdateAmpView(panelTitle, headStage, [ctrl])
	string panelTitle
	variable headStage
	string ctrl

	string lbl, list
	variable i, numEntries, value

	DAP_AbortIfUnlocked(panelTitle)

	// only update view if headstage is selected
	if(DAG_GetNumericalValue(panelTitle, "slider_DataAcq_ActiveHeadstage") != headStage)
		return NaN
	endif

	WAVE AmpStorageWave = GetAmplifierParamStorageWave(panelTitle)

	if(!ParamIsDefault(ctrl))
		list = ctrl
	else
		list = AMPLIFIER_CONTROLS_VC + ";" + AMPLIFIER_CONTROLS_IC
	endif

	numEntries = ItemsInList(list)
	for(i = 0; i < numEntries; i += 1)
		ctrl = StringFromList(i, list)
		lbl  = AI_AmpStorageControlToRowLabel(ctrl)

		if(IsEmpty(lbl))
			continue
		endif

		value = AmpStorageWave[%$lbl][0][headStage]

		if(StringMatch(ctrl, "setvar_*"))
			SetSetVariable(panelTitle, ctrl, value)
			DAG_Update(panelTitle, ctrl, val = value)
		elseif(StringMatch(ctrl, "check_*"))
			SetCheckBoxState(panelTitle, ctrl, value)
			DAG_Update(panelTitle, ctrl, val = value)
		else
			ASSERT(0, "Unhandled control")
		endif
	endfor
End

/// @brief Convert amplifier controls to row labels for `AmpStorageWave`
static Function/S AI_AmpStorageControlToRowLabel(ctrl)
	string ctrl

	strswitch(ctrl)
		// V-Clamp controls
		case "setvar_DataAcq_Hold_VC":
			return "holdingPotential"
			break
		case "check_DatAcq_HoldEnableVC":
			return "HoldingPotentialEnable"
			break
		case "setvar_DataAcq_WCC":
			return "WholeCellCap"
			break
		case "setvar_DataAcq_WCR":
			return "WholeCellRes"
			break
		case "check_DatAcq_WholeCellEnable":
			return "WholeCellEnable"
			break
		case "setvar_DataAcq_RsCorr":
			return "Correction"
			break
		case "setvar_DataAcq_RsPred":
			return "Prediction"
			break
		case "check_DatAcq_RsCompEnable":
			return "RsCompEnable"
			break
		case "setvar_DataAcq_PipetteOffset_VC":
			return "PipetteOffsetVC"
			break
		// I-Clamp controls
		case "setvar_DataAcq_Hold_IC":
			return "BiasCurrent"
			break
		case "check_DatAcq_HoldEnable":
			return "BiasCurrentEnable"
			break
		case "setvar_DataAcq_BB":
			return "BridgeBalance"
			break
		case "check_DatAcq_BBEnable":
			return "BridgeBalanceEnable"
			break
		case "setvar_DataAcq_CN":
			return "CapNeut"
			break
		case "check_DatAcq_CNEnable":
			return "CapNeutEnable"
			break
		case "setvar_DataAcq_AutoBiasV":
			return "AutoBiasVcom"
			break
		case "setvar_DataAcq_AutoBiasVrange":
			return "AutoBiasVcomVariance"
			break
		case "setvar_DataAcq_IbiasMax":
			return "AutoBiasIbiasmax"
			break
		case "check_DataAcq_AutoBias":
			return "AutoBiasEnable"
			break
		case "setvar_DataAcq_PipetteOffset_IC":
			return "PipetteOffsetIC"
			break
		case "check_DataAcq_Amp_Chain":
			return "RSCompChaining"
			break
		case "button_DataAcq_AutoBridgeBal_IC":
		case "button_DataAcq_FastComp_VC":
		case "button_DataAcq_SlowComp_VC":
		case "button_DataAcq_AutoPipOffset_VC":
			// no row exists
			return ""
			break
		default:
			ASSERT(0, "Unknown control " + ctrl)
			break
	endswitch
End
Function AI_SetMIESHeadstage(panelTitle, [headstage, increment])
	string panelTitle
	variable headstage, increment

	if(ParamIsDefault(headstage) && ParamIsDefault(increment))
		return Nan
	endif

	if(!ParamIsDefault(increment))
		headstage = DAG_GetNumericalValue(panelTitle, "slider_DataAcq_ActiveHeadstage") + increment
	endif

	if(headstage >= 0 && headstage < NUM_HEADSTAGES)
		PGC_SetAndActivateControl(panelTitle, "slider_DataAcq_ActiveHeadstage", val=headstage)
	endif
End

/// @brief Executes MCC auto zero command if the baseline current exceeds #ZERO_TOLERANCE
///
/// @param panelTitle device
/// @param headStage     [optional: defaults to all active headstages]
Function AI_ZeroAmps(panelTitle, [headStage])
	string panelTitle
	variable headstage

	variable i, col
	// Ensure that data in BaselineSSAvg is up to date by verifying that TP is active
	if(IsDeviceActiveWithBGTask(panelTitle, "TestPulse") || IsDeviceActiveWithBGTask(panelTitle, "TestPulseMD"))

		WAVE baselineSSAvg = GetBaselineAverage(panelTitle)
		if(!ParamIsDefault(headstage))
			if(abs(baselineSSAvg[headstage]) >= ZERO_TOLERANCE)
				AI_MIESAutoPipetteOffset(panelTitle, headStage)
			endif
		else
			for(i = 0; i < NUM_HEADSTAGES; i += 1)
				if(abs(baselineSSAvg[i]) >= ZERO_TOLERANCE)
					AI_MIESAutoPipetteOffset(panelTitle, i)
				endif
			endfor
		endif
	endif
End

/// @brief Auto pipette zeroing
/// Quicker than MCC auto pipette offset
///
/// @param panelTitle device
/// @param headStage MIES headstage number, must be in the range [0, NUM_HEADSTAGES]
Function AI_MIESAutoPipetteOffset(panelTitle, headStage)
	string panelTitle
	variable headStage

	variable clampMode, column, vDelta, offset, value

	WAVE BaselineSSAvg = GetBaselineAverage(panelTitle)
	WAVE SSResistance = GetSSResistanceWave(panelTitle)

	if(!DimSize(baselineSSAvg, ROWS) || !DimSize(SSResistance, ROWS))
		return NaN
	endif

	clampMode = DAG_GetHeadstageMode(panelTitle, headStage)

	ASSERT(clampMode == V_CLAMP_MODE || clampMode == I_CLAMP_MODE, "Headstage must be in VC/IC mode to use this function")
	ASSERT(column >= 0, "Invalid column number")
	//calculate delta current to reach zero
	vdelta = (baselineSSAvg[headstage] * SSResistance[headstage]) / 1000 // set to mV
	// get current DC V offset
	offset = AI_SendToAmp(panelTitle, headStage, clampMode, MCC_GETPIPETTEOFFSET_FUNC, nan)
	// add delta to current DC V offset
	value = offset - vDelta
	if(value > MIN_PIPETTEOFFSET && value < MAX_PIPETTEOFFSET)
		AI_UpdateAmpModel(panelTitle, "setvar_DataAcq_PipetteOffset_VC", headStage, value = value, checkBeforeWrite = 1)
		AI_UpdateAmpModel(panelTitle, "setvar_DataAcq_PipetteOffset_IC", headStage, value = value, checkBeforeWrite = 1)
	endif
End

/// @brief Query the MCC application for the gains and units of the given clamp mode
///
/// Assumes that the correct amplifier is already selected!
Function AI_QueryGainsUnitsForClampMode(panelTitle, headstage, clampMode, DAGain, ADGain, DAUnit, ADUnit)
	string panelTitle
	variable headstage, clampMode
	variable &DAGain, &ADGain
	string &DAUnit, &ADUnit

	DAGain = NaN
	ADGain = NaN
	DAUnit = ""
	ADUnit = ""

	AI_AssertOnInvalidClampMode(clampMode)

	AI_RetrieveGains(panelTitle, headstage, clampMode, ADGain, DAGain)

	if(clampMode == V_CLAMP_MODE)
		DAUnit = "mV"
		ADUnit = "pA"
	else
		DAUnit = "pA"
		ADUnit = "mV"
	endif
End

/// @brief Update the `ChanAmpAssign` and `ChanAmpAssignUnit` waves according to the passed
/// clamp mode with the gains and units.
Function AI_UpdateChanAmpAssign(panelTitle, headStage, clampMode, DAGain, ADGain, DAUnit, ADUnit)
	string panelTitle
	variable headStage, clampMode, DAGain, ADGain
	string DAUnit, ADUnit

	AI_AssertOnInvalidClampMode(clampMode)

	WAVE ChanAmpAssign       = GetChanAmpAssign(panelTitle)
	WAVE/T ChanAmpAssignUnit = GetChanAmpAssignUnit(panelTitle)

	if(clampMode == V_CLAMP_MODE)
		ChanAmpAssign[%VC_DAGain][headStage]     = DAGain
		ChanAmpAssign[%VC_ADGain][headStage]     = ADGain
		ChanAmpAssignUnit[%VC_DAUnit][headStage] = DAUnit
		ChanAmpAssignUnit[%VC_ADUnit][headStage] = ADUnit
	elseif(clampMode == I_CLAMP_MODE)
		ChanAmpAssign[%IC_DAGain][headStage]     = DAGain
		ChanAmpAssign[%IC_ADGain][headStage]     = ADGain
		ChanAmpAssignUnit[%IC_DAUnit][headStage] = DAUnit
		ChanAmpAssignUnit[%IC_ADUnit][headStage] = ADUnit
	elseif(clampMode == I_EQUAL_ZERO_MODE)
		// don't update DAGain as that will be always zero for I=0
		ChanAmpAssign[%IC_ADGain][headStage]     = ADGain
		ChanAmpAssignUnit[%IC_DAUnit][headStage] = DAUnit
		ChanAmpAssignUnit[%IC_ADUnit][headStage] = ADUnit
	endif
End

/// @brief Assert on invalid clamp modes, does nothing otherwise
Function AI_AssertOnInvalidClampMode(clampMode)
	variable clampMode

	ASSERT(AI_IsValidClampMode(clampMode), "invalid clamp mode")
End

/// @brief Return true if the given clamp mode is valid
Function AI_IsValidClampMode(clampMode)
	variable clampMode

	return clampMode == V_CLAMP_MODE || clampMode == I_CLAMP_MODE || clampMode == I_EQUAL_ZERO_MODE
End

/// @brief Opens Multi-clamp commander software
///
/// @param ampSerialNumList A text list of amplifier serial numbers without leading zeroes
/// Ex. "834001;435003;836059", "0;" starts the MCC in Demo mode
/// Duplicate serial numbers are ignored as well as amplifier titles for the duplicates.
/// For each unique serial number one MCC is opened.
/// @param ampTitleList [optional, defaults to blank] MCC gui window title
/// @return 1 if all unique MCCs specified in ampSerialNumList were opened, 0 if one or more MCCs specified in ampSerialNumList were not able to be opened
Function AI_OpenMCCs(ampSerialNumList, [ampTitleList])
	string ampSerialNumList
	string ampTitleList

	string cmd, serialStr, title
	variable i, j, numDups, serialNum, failedToOpenCount
	variable ItemsInAmpSerialNumList = ItemsInList(AmpSerialNumList)
	variable maxAttempts = 3

	if(paramIsDefault(AmpTitleList))
		AmpTitleList = ""
	else
		ASSERT(ItemsInAmpSerialNumList == ItemsInList(ampTitleList), "Number of amplifier serials does not match number of amplifier titles.")
	endIf

	if(ItemsInAmpSerialNumList > 1)
		WAVE/T ampSerialListRaw = ListToTextWave(ampSerialNumList, ";")
		FindDuplicates/FREE/RT=ampSerialList/INDX=dupIndices ampSerialListRaw
		numDups = DimSize(dupIndices, ROWS)
		if(numDups)
			if(numDups > 1)
				Sort/R dupIndices, dupIndices
				for(i = 0; i < numDups; i += 1)
					AmpTitleList = RemoveListItem(dupIndices[i], AmpTitleList)
				endfor
			else
				AmpTitleList = RemoveListItem(dupIndices[0], AmpTitleList)
			endif
		endif
		AmpSerialNumList = TextWaveToList(ampSerialList, ";")
		ItemsInAmpSerialNumList = ItemsInList(AmpSerialNumList)
	endif

	WAVE OpenMCCList = AI_GetMCCSerialNumbers()
	Do
		for(i=0 ; i < ItemsInAmpSerialNumList ; i+=1)
			serialStr = stringfromlist(i, AmpSerialNumList)
			serialNum = str2num(serialStr)
			title = stringfromlist(i, AmpTitleList)
			findvalue/I=(serialNum) OpenMCCList
			if( V_value == -1)
				if(!serialNum)
					sprintf cmd, "\"%s\" /T%s(%s)", AI_GetMCCWinFilePath(), title, SerialStr
				else
					sprintf cmd, "\"%s\" /S00%g /T%s(%s)", AI_GetMCCWinFilePath(), SerialNum, title, SerialStr
				endif
				executeScriptText cmd
			endif
		endfor

		failedToOpenCount=0
		WAVE OpenMCCList = AI_GetMCCSerialNumbers()
		for(i=0 ; i < ItemsInAmpSerialNumList ; i+=1)
			serialNum = str2num(serialStr)
			findvalue/I=(serialNum) OpenMCCList
			if(v_value == -1)
				failedToOpenCount += 1
			endif
		endfor

		if(failedToOpenCount > 0)
			printf "%g MCCs failed to open on attempt count %g\r" failedTOopenCount, j
			ControlWindowToFront()
		endif

		j += 1
	while(failedToOpenCount != 0 && j < maxAttempts)

	return failedToOpenCount == 0
End

/// @brief Gets the serial numbers of all open MCCs
///
/// @return a 1D FREE wave containing amplifier serial numbers without leading zeroes
static Function/WAVE AI_GetMCCSerialNumbers()
		AI_FindConnectedAmps()
		WAVE W_TelegraphServers = GetAmplifierTelegraphServers()
		Duplicate/FREE/R=[][FindDimLabel(W_TelegraphServers, COLS, "SerialNum")] W_TelegraphServers, OpenMCCList
		return DeleteDuplicates(OpenMCCList)
End

/// @brief Return a path to the MCC.
///
/// Hardcoded as Igor does not allow to query that information.
///
/// Distinguishes between i386 and x64 Igor versions
static Function/S AI_GetMCCWinFilePath()

	variable numEntries, i
	string progFolder, path

	progFolder = GetProgramFilesFolder()

#if defined(IGOR64)
	MAKE/FREE/T locations = {"Molecular Devices\\MultiClamp_64\\MC700B.exe", "Molecular Devices\\MultiClamp 700B Commander\\MC700B.exe"}
#else
	MAKE/FREE/T locations = {"Molecular Devices\\MultiClamp 700B Commander\\MC700B.exe"}
#endif

	numEntries = DimSize(locations, ROWS)
	for(i = 0; i < numEntries; i += 1)
		path = progFolder + locations[i]

		if(FileExists(path))
			return path
		endif
	endfor

	ASSERT(0, "Could not find the MCC application")
	return "ERROR"
End

#ifdef AMPLIFIER_XOPS_PRESENT

///@brief Returns the holding command of the amplifier
Function AI_GetHoldingCommand(panelTitle, headstage)
	string panelTitle
	variable headstage

	if(AI_SelectMultiClamp(panelTitle, headstage) != AMPLIFIER_CONNECTION_SUCCESS)
		return NaN
	endif

	return MCC_GetHoldingEnable() ? MCC_GetHolding() * AI_GetMCCScale(MCC_GetMode(), MCC_GETHOLDING_FUNC) : 0
End

/// @brief Return the clamp mode of the headstage as returned by the amplifier
///
/// Should only be used during the setup phase when you don't know if the
/// clamp mode in MIES matches already. It is always better to prefer
/// DAP_ChangeHeadStageMode() if possible.
///
/// @brief One of @ref AmplifierClampModes or NaN if no amplifier is connected
Function AI_GetMode(panelTitle, headstage)
	string panelTitle
	variable headstage

	if(AI_SelectMultiClamp(panelTitle, headstage) != AMPLIFIER_CONNECTION_SUCCESS)
		return NaN
	endif

	return MCC_GetMode()
End

/// @brief Return the DA/AD gains and the current clampmode of the selected amplifier
///
/// Gain is returned in mV/V for #V_CLAMP_MODE and V/mV for #I_CLAMP_MODE/#I_EQUAL_ZERO_MODE
///
/// @param      panelTitle device
/// @param      headstage  headstage [0, NUM_HEADSTAGES[
/// @param[out] clampMode  clamp mode (expected)
/// @param[out] ADGain     ADC gain
/// @param[out] DAGain     DAC gain
static Function AI_RetrieveGains(panelTitle, headstage, clampMode, ADGain, DAGain)
	string panelTitle
	variable headstage,clampMode
	variable &ADGain, &DAGain

	variable axonSerial = AI_GetAmpAxonSerial(panelTitle, headstage)
	variable channel    = AI_GetAmpChannel(panelTitle, headStage)

	STRUCT AxonTelegraph_DataStruct tds
	AI_InitAxonTelegraphStruct(tds)
	AxonTelegraphGetDataStruct(axonSerial, channel, 1, tds)

	ASSERT(clampMode == tds.OperatingMode, "Non matching clamp mode from MCC application")

	ADGain    = tds.ScaleFactor * tds.Alpha / 1000
	clampMode = tds.OperatingMode

	if(tds.OperatingMode == V_CLAMP_MODE)
		DAGain = tds.ExtCmdSens * 1000
	elseif(tds.OperatingMode == I_CLAMP_MODE || tds.OperatingMode == I_EQUAL_ZERO_MODE)
		DAGain =tds.ExtCmdSens * 1e12
	endif
End

/// @brief Changes the mode of the amplifier between I-Clamp and V-Clamp depending on the currently set mode
///
/// Assumes that the correct amplifier is selected.
static Function AI_SwitchAxonAmpMode()

	variable mode

	mode = MCC_GetMode()

	if(mode == V_CLAMP_MODE)
		MCC_SetMode(I_CLAMP_MODE)
	elseif(mode == I_CLAMP_MODE || mode == I_EQUAL_ZERO_MODE)
		MCC_SetMode(V_CLAMP_MODE)
	else
		// do nothing
	endif
End

/// @brief Wrapper for MCC_SelectMultiClamp700B
///
/// @param panelTitle device
/// @param headStage MIES headstage number, must be in the range [0, NUM_HEADSTAGES]
///
/// @returns one of @ref AISelectMultiClampReturnValues
Function AI_SelectMultiClamp(panelTitle, headStage)
	string panelTitle
	variable headStage

	variable channel, axonSerial, debugOnError
	string mccSerial

	// checking axonSerial is done as a service to the caller
	axonSerial = AI_GetAmpAxonSerial(panelTitle, headStage)
	mccSerial  = AI_GetAmpMCCSerial(panelTitle, headStage)
	channel    = AI_GetAmpChannel(panelTitle, headStage)

	if(!AI_IsValidSerialAndChannel(mccSerial=mccSerial, axonSerial=axonSerial, channel=channel))
		return AMPLIFIER_CONNECTION_INVAL_SER
	endif

	debugOnError = DisableDebugOnError()

	try
		ClearRTError()
		MCC_SelectMultiClamp700B(mccSerial, channel); AbortOnRTE
	catch
		ClearRTError()
		ResetDebugOnError(debugOnError)
		return AMPLIFIER_CONNECTION_MCC_FAILED
	endtry

	ResetDebugOnError(debugOnError)
	return AMPLIFIER_CONNECTION_SUCCESS
end

/// @brief Set the clamp mode of user linked MCC based on the headstage number
Function AI_SetClampMode(panelTitle, headStage, mode, [zeroStep])
	string panelTitle
	variable headStage
	variable mode, zeroStep

	if(ParamIsDefault(zeroStep))
		zeroStep = 0
	else
		zeroStep = !!zeroStep
	endif

	AI_AssertOnInvalidClampMode(mode)

	if(AI_SelectMultiClamp(panelTitle, headStage) != AMPLIFIER_CONNECTION_SUCCESS)
		return NaN
	endif

	if(zeroStep && (mode == I_CLAMP_MODE || mode == V_CLAMP_MODE))
		if(!IsFinite(MCC_SetMode(I_EQUAL_ZERO_MODE)))
			printf "MCC amplifier cannot be switched to mode %d. Linked MCC is no longer present\r", mode
		endif
		Sleep/Q/T/C=-1 6
	endif

	if(!IsFinite(MCC_SetMode(mode)))
		printf "MCC amplifier cannot be switched to mode %d. Linked MCC is no longer present\r", mode
	endif
End

/// @brief Generic interface to call MCC amplifier functions
///
/// @param panelTitle       locked panel name to work on
/// @param headStage        MIES headstage number, must be in the range [0, NUM_HEADSTAGES]
/// @param mode             one of V_CLAMP_MODE, I_CLAMP_MODE or I_EQUAL_ZERO_MODE
/// @param func             Function to call, see @ref AI_SendToAmpConstants
/// @param value            Numerical value to send, ignored by all getter functions
/// @param checkBeforeWrite [optional, defaults to false] (ignored for getter functions)
///                         check the current value and do nothing if it is equal within some tolerance to the one written
/// @param usePrefixes      [optional, defaults to true] Use SI-prefixes common in MIES for the passed and returned values, e.g.
///                         `mV` instead of `V`
/// @param selectAmp        [optional, defaults to true] Select the amplifier
///                         before use, some callers might save time in doing that once themselves.
///
/// @returns return value (for getters, respects `usePrefixes`), success (`0`) or error (`NaN`).
Function AI_SendToAmp(panelTitle, headStage, mode, func, value, [checkBeforeWrite, usePrefixes, selectAmp])
	string panelTitle
	variable headStage, mode, func, value
	variable checkBeforeWrite, usePrefixes, selectAmp

	variable ret, headstageMode, scale
	string str

	ASSERT(func > MCC_BEGIN_INVALID_FUNC && func < MCC_END_INVALID_FUNC, "MCC function constant is out for range")
	ASSERT(headStage >= 0 && headStage < NUM_HEADSTAGES, "invalid headStage index")
	AI_AssertOnInvalidClampMode(mode)

	if(ParamIsDefault(checkBeforeWrite))
		checkBeforeWrite = 0
	else
		checkBeforeWrite = !!checkBeforeWrite
	endif

	if(ParamIsDefault(selectAmp))
		selectAmp = 1
	else
		selectAmp = !!selectAmp
	endif

	if(ParamIsDefault(usePrefixes) || !!usePrefixes)
		scale = AI_GetMCCScale(mode, func)
	else
		scale = 1
	endif

	headstageMode = DAG_GetHeadstageMode(panelTitle, headStage)

	if(headstageMode != mode)
		return NaN
	endif

	if(selectAmp)
		if(AI_SelectMultiClamp(panelTitle, headstage) != AMPLIFIER_CONNECTION_SUCCESS)
			return NaN
		endif
	endif

	AI_EnsureCorrectMode(panelTitle, headStage, selectAmp = 0)

	sprintf str, "headStage=%d, mode=%d, func=%d, value(passed)=%g, scale=%g\r", headStage, mode, func, value, scale
	DEBUGPRINT(str)

	value *= scale

	if(checkBeforeWrite)
		switch(func)
			case MCC_SETHOLDING_FUNC:
				ret = MCC_Getholding()
				break
			case MCC_SETHOLDINGENABLE_FUNC:
				ret = MCC_GetholdingEnable()
				break
			case MCC_SETBRIDGEBALENABLE_FUNC:
				ret = MCC_GetBridgeBalEnable()
				break
			case MCC_SETBRIDGEBALRESIST_FUNC:
				ret = MCC_GetBridgeBalResist()
				break
			case MCC_SETNEUTRALIZATIONENABL_FUNC:
				ret = MCC_GetNeutralizationEnable()
				break
			case MCC_SETNEUTRALIZATIONCAP_FUNC:
				ret = MCC_GetNeutralizationCap()
				break
			case MCC_SETWHOLECELLCOMPENABLE_FUNC:
				ret = MCC_GetWholeCellCompEnable()
				break
			case MCC_SETWHOLECELLCOMPCAP_FUNC:
				ret = MCC_GetWholeCellCompCap()
				break
			case MCC_SETWHOLECELLCOMPRESIST_FUNC:
				ret = MCC_GetWholeCellCompResist()
				break
			case MCC_SETRSCOMPENABLE_FUNC:
				ret = MCC_GetRsCompEnable()
				break
			case MCC_SETRSCOMPBANDWIDTH_FUNC:
				ret = MCC_GetRsCompBandwidth()
				break
			case MCC_SETRSCOMPCORRECTION_FUNC:
				ret = MCC_GetRsCompCorrection()
				break
			case MCC_SETRSCOMPPREDICTION_FUNC:
				ret = MCC_GetRsCompPrediction()
				break
			case MCC_SETOSCKILLERENABLE_FUNC:
				ret = MCC_GetOscKillerEnable()
				break
			case MCC_SETPIPETTEOFFSET_FUNC:
				ret = MCC_GetPipetteOffset()
				break
			case MCC_SETFASTCOMPCAP_FUNC:
				ret = MCC_GetFastCompCap()
				break
			case MCC_SETSLOWCOMPCAP_FUNC:
				ret = MCC_GetSlowCompCap()
				break
			case MCC_SETFASTCOMPTAU_FUNC:
				ret = MCC_GetFastCompTau()
				break
			case MCC_SETSLOWCOMPTAU_FUNC:
				ret = MCC_GetSlowCompTau()
				break
			case MCC_SETSLOWCOMPTAUX20ENAB_FUNC:
				ret = MCC_GetSlowCompTauX20Enable()
				break
			case MCC_SETSLOWCURRENTINJENABL_FUNC:
				ret = MCC_GetSlowCurrentInjEnable()
				break
			case MCC_SETSLOWCURRENTINJLEVEL_FUNC:
				ret = MCC_GetSlowCurrentInjLevel()
				break
			case MCC_SETSLOWCURRENTINJSETLT_FUNC:
				ret = MCC_GetSlowCurrentInjSetlTime()
				break
			default:
				ret = NaN
				break
		endswitch

		// Don't send the value if it is equal to the current value, with tolerance
		// being 1% of the reference value, or if it is zero and the current value is
		// smaller than 1e-12.
		if(CheckIfClose(ret, value, tol=1e-2 * abs(ret), strong_or_weak=1) || (value == 0 && CheckIfSmall(ret, tol=1e-12)))
			DEBUGPRINT("The value to be set is equal to the current value, skip setting it: " + num2str(func))
			return 0
		endif
	endif

	switch(func)
		case MCC_SETHOLDING_FUNC:
			ret = MCC_Setholding(value)
			break
		case MCC_GETHOLDING_FUNC:
			ret = MCC_Getholding()
			break
		case MCC_SETHOLDINGENABLE_FUNC:
			ret = MCC_SetholdingEnable(value)
			break
		case MCC_GETHOLDINGENABLE_FUNC:
			ret = MCC_GetHoldingEnable()
			break
		case MCC_SETBRIDGEBALENABLE_FUNC:
			ret = MCC_SetBridgeBalEnable(value)
			break
		case MCC_GETBRIDGEBALENABLE_FUNC:
			ret = MCC_GetBridgeBalEnable()
			break
		case MCC_SETBRIDGEBALRESIST_FUNC:
			ret = MCC_SetBridgeBalResist(value)
			break
		case MCC_GETBRIDGEBALRESIST_FUNC:
			ret = MCC_GetBridgeBalResist()
			break
		case MCC_AUTOBRIDGEBALANCE_FUNC:
			MCC_AutoBridgeBal()
			ret = AI_SendToAmp(panelTitle, headstage, mode, MCC_GETBRIDGEBALRESIST_FUNC, NaN, usePrefixes=usePrefixes, selectAmp = 0)
			break
		case MCC_SETNEUTRALIZATIONENABL_FUNC:
			ret = MCC_SetNeutralizationEnable(value)
			break
		case MCC_GETNEUTRALIZATIONENABL_FUNC:
			ret = MCC_GetNeutralizationEnable()
			break
		case MCC_SETNEUTRALIZATIONCAP_FUNC:
			ret = MCC_SetNeutralizationCap(value)
			break
		case MCC_GETNEUTRALIZATIONCAP_FUNC:
			ret = MCC_GetNeutralizationCap()
			break
		case MCC_SETWHOLECELLCOMPENABLE_FUNC:
			ret = MCC_SetWholeCellCompEnable(value)
			break
		case MCC_GETWHOLECELLCOMPENABLE_FUNC:
			ret = MCC_GetWholeCellCompEnable()
			break
		case MCC_SETWHOLECELLCOMPCAP_FUNC:
			ret = MCC_SetWholeCellCompCap(value)
			break
		case MCC_GETWHOLECELLCOMPCAP_FUNC:
			ret = MCC_GetWholeCellCompCap()
			break
		case MCC_SETWHOLECELLCOMPRESIST_FUNC:
			ret = MCC_SetWholeCellCompResist(value)
			break
		case MCC_GETWHOLECELLCOMPRESIST_FUNC:
			ret = MCC_GetWholeCellCompResist()
			break
		case MCC_AUTOWHOLECELLCOMP_FUNC:
			MCC_AutoWholeCellComp()
			// as we would have to return two values (resistance and capacitance)
			// we return just zero
			ret = 0
			break
		case MCC_SETRSCOMPENABLE_FUNC:
			ret = MCC_SetRsCompEnable(value)
			break
		case MCC_GETRSCOMPENABLE_FUNC:
			ret = MCC_GetRsCompEnable()
			break
		case MCC_SETRSCOMPBANDWIDTH_FUNC:
			ret = MCC_SetRsCompBandwidth(value)
			break
		case MCC_GETRSCOMPBANDWIDTH_FUNC:
			ret = MCC_GetRsCompBandwidth()
			break
		case MCC_SETRSCOMPCORRECTION_FUNC:
			ret = MCC_SetRsCompCorrection(value)
			break
		case MCC_GETRSCOMPCORRECTION_FUNC:
			ret = MCC_GetRsCompCorrection()
			break
		case MCC_SETRSCOMPPREDICTION_FUNC:
			ret = MCC_SetRsCompPrediction(value)
			break
		case MCC_GETRSCOMPPREDICTION_FUNC:
			ret = MCC_SetRsCompPrediction(value)
			break
		case MCC_SETOSCKILLERENABLE_FUNC:
			ret = MCC_SetOscKillerEnable(value)
			break
		case MCC_GETOSCKILLERENABLE_FUNC:
			ret = MCC_GetOscKillerEnable()
			break
		case MCC_AUTOPIPETTEOFFSET_FUNC:
			MCC_AutoPipetteOffset()
			ret = AI_SendToAmp(panelTitle, headStage, mode, MCC_GETPIPETTEOFFSET_FUNC, NaN, usePrefixes=usePrefixes, selectAmp = 0)
			break
		case MCC_SETPIPETTEOFFSET_FUNC:
			ret = MCC_SetPipetteOffset(value)
			break
		case MCC_GETPIPETTEOFFSET_FUNC:
			ret = MCC_GetPipetteOffset()
			break
		case MCC_SETFASTCOMPCAP_FUNC:
			ret = MCC_SetFastCompCap(value)
			break
		case MCC_GETFASTCOMPCAP_FUNC:
			ret = MCC_GetFastCompCap()
			break
		case MCC_SETSLOWCOMPCAP_FUNC:
			ret = MCC_SetSlowCompCap(value)
			break
		case MCC_GETSLOWCOMPCAP_FUNC:
			ret = MCC_GetSlowCompCap()
			break
		case MCC_SETFASTCOMPTAU_FUNC:
			ret = MCC_SetFastCompTau(value)
			break
		case MCC_GETFASTCOMPTAU_FUNC:
			ret = MCC_GetFastCompTau()
			break
		case MCC_SETSLOWCOMPTAU_FUNC:
			ret = MCC_SetSlowCompTau(value)
			break
		case MCC_GETSLOWCOMPTAU_FUNC:
			ret = MCC_GetSlowCompTau()
			break
		case MCC_SETSLOWCOMPTAUX20ENAB_FUNC:
			ret = MCC_SetSlowCompTauX20Enable(value)
			break
		case MCC_GETSLOWCOMPTAUX20ENAB_FUNC:
			ret = MCC_GetSlowCompTauX20Enable()
			break
		case MCC_AUTOFASTCOMP_FUNC:
			ret = MCC_AutoFastComp()
			break
		case MCC_AUTOSLOWCOMP_FUNC:
			ret = MCC_AutoSlowComp()
			break
		case MCC_SETSLOWCURRENTINJENABL_FUNC:
			ret = MCC_SetSlowCurrentInjEnable(value)
			break
		case MCC_GETSLOWCURRENTINJENABL_FUNC:
			ret = MCC_GetSlowCurrentInjEnable()
			break
		case MCC_SETSLOWCURRENTINJLEVEL_FUNC:
			ret = MCC_SetSlowCurrentInjLevel(value)
			break
		case MCC_GETSLOWCURRENTINJLEVEL_FUNC:
			ret = MCC_GetSlowCurrentInjLevel()
			break
		case MCC_SETSLOWCURRENTINJSETLT_FUNC:
			ret = MCC_SetSlowCurrentInjSetlTime(value)
			break
		case MCC_GETSLOWCURRENTINJSETLT_FUNC:
			ret = MCC_GetSlowCurrentInjSetlTime()
			break
		default:
			ASSERT(0, "Unknown function: " + num2str(func))
			break
	endswitch

	if(!IsFinite(ret))
		print "Amp communication error. Check associations in hardware tab and/or use Query connected amps button"
		ControlWindowToFront()
	endif

	// return value is only relevant for the getters
	return ret * scale
End

/// @brief Set the clamp mode in the MCC app to the
///        same clamp mode as MIES has stored.
///
/// @param panelTitle device
/// @param headstage  headstage
/// @paran selectAmp  [optional, defaults to false] selects the amplifier
///                   before using, some callers might be able to skip it.
Function AI_EnsureCorrectMode(panelTitle, headStage, [selectAmp])
	string panelTitle
	variable headStage, selectAmp

	variable serial, channel, storedMode, setMode

	if(ParamIsDefault(selectAmp))
		selectAmp = 0
	else
		selectAmp = !!selectAmp
	endif

	serial  = AI_GetAmpAxonSerial(panelTitle, headStage)
	channel = AI_GetAmpChannel(panelTitle, headStage)

	if(!AI_IsValidSerialAndChannel(channel=channel, axonSerial=serial))
		return NaN
	endif

	if(selectAmp)
		AI_SelectMultiClamp(panelTitle, headstage)
	endif

	STRUCT AxonTelegraph_DataStruct tds
	AI_InitAxonTelegraphStruct(tds)
	AxonTelegraphGetDataStruct(serial, channel, 1, tds)
	storedMode = DAG_GetHeadstageMode(panelTitle, headStage)
	setMode    = tds.operatingMode

	if(setMode != storedMode)
		print "There was a mismatch in clamp mode between MIES and the MCC. The MCC mode was switched to match the mode specified by MIES."
		AI_SetClampMode(panelTitle, headStage, storedMode)
	endif
End

/// @brief Fill the amplifier settings wave by querying the MC700B and send the data to ED_AddEntriesToLabnotebook
///
/// @param panelTitle 		 device
/// @param sweepNo           data wave sweep number
Function AI_FillAndSendAmpliferSettings(panelTitle, sweepNo)
	string panelTitle
	variable sweepNo

	variable i, axonSerial, channel, ampConnState, clampMode
	string mccSerial

	WAVE statusHS              = DAG_GetChannelState(panelTitle, CHANNEL_TYPE_HEADSTAGE)
	WAVE ampSettingsWave       = GetAmplifierSettingsWave()
	WAVE/T ampSettingsKey      = GetAmplifierSettingsKeyWave()
	WAVE/T ampSettingsTextWave = GetAmplifierSettingsTextWave()
	WAVE/T ampSettingsTextKey  = GetAmplifierSettingsTextKeyWave()
	WAVE ampParamStorage       = GetAmplifierParamStorageWave(panelTitle)

	ampSettingsWave = NaN

	for(i = 0; i < NUM_HEADSTAGES; i += 1)

		if(!statusHS[i])
			continue
		endif

		mccSerial  = AI_GetAmpMCCSerial(panelTitle, i)
		axonSerial = AI_GetAmpAxonSerial(panelTitle, i)
		channel    = AI_GetAmpChannel(panelTitle, i)

		ampConnState = AI_SelectMultiClamp(panelTitle, i)

		if(ampConnState != AMPLIFIER_CONNECTION_SUCCESS)
			if(DAG_GetNumericalValue(panelTitle, "check_Settings_RequireAmpConn"))
				BUG("The amplifier could not be selected, but that should work, ampConnState = " + num2str(ampConnState))
				BUG("Please report that as a bug with a description what you did. Thanks!")
			endif
			continue
		endif

		clampMode = DAG_GetHeadstageMode(panelTitle, i)
		AI_AssertOnInvalidClampMode(clampMode)

		STRUCT AxonTelegraph_DataStruct tds
		AI_InitAxonTelegraphStruct(tds)
		AxonTelegraphGetDataStruct(axonSerial, channel, 1, tds)
		ASSERT(clampMode == tds.OperatingMode, "A clamp mode mismatch was detected. Please describe the events leading up to that assertion. Thanks!")

		if(clampMode == V_CLAMP_MODE)
			ampSettingsWave[0][0][i]  = MCC_GetHoldingEnable()
			ampSettingsWave[0][1][i]  = MCC_GetHolding() * AI_GetMCCScale(V_CLAMP_MODE, MCC_GETHOLDING_FUNC)
			ampSettingsWave[0][2][i]  = MCC_GetOscKillerEnable()
			ampSettingsWave[0][3][i]  = MCC_GetRsCompBandwidth() * AI_GetMCCScale(V_CLAMP_MODE, MCC_GETRSCOMPBANDWIDTH_FUNC)
			ampSettingsWave[0][4][i]  = MCC_GetRsCompCorrection()
			ampSettingsWave[0][5][i]  = MCC_GetRsCompEnable()
			ampSettingsWave[0][6][i]  = MCC_GetRsCompPrediction()
			ampSettingsWave[0][7][i]  = MCC_GetWholeCellCompEnable()
			ampSettingsWave[0][8][i]  = MCC_GetWholeCellCompCap() * AI_GetMCCScale(V_CLAMP_MODE, MCC_GETWHOLECELLCOMPCAP_FUNC)
			ampSettingsWave[0][9][i]  = MCC_GetWholeCellCompResist() * AI_GetMCCScale(V_CLAMP_MODE, MCC_GETWHOLECELLCOMPRESIST_FUNC)
			ampSettingsWave[0][39][i] = MCC_GetFastCompCap()
			ampSettingsWave[0][40][i] = MCC_GetSlowCompCap()
			ampSettingsWave[0][41][i] = MCC_GetFastCompTau()
			ampSettingsWave[0][42][i] = MCC_GetSlowCompTau()
		elseif(clampMode == I_CLAMP_MODE || clampMode == I_EQUAL_ZERO_MODE)
			ampSettingsWave[0][10][i] = MCC_GetHoldingEnable()
			ampSettingsWave[0][11][i] = MCC_GetHolding() * AI_GetMCCScale(I_CLAMP_MODE, MCC_GETHOLDING_FUNC)
			ampSettingsWave[0][12][i] = MCC_GetNeutralizationEnable()
			ampSettingsWave[0][13][i] = MCC_GetNeutralizationCap() * AI_GetMCCScale(I_CLAMP_MODE, MCC_GETNEUTRALIZATIONCAP_FUNC)
			ampSettingsWave[0][14][i] = MCC_GetBridgeBalEnable()
			ampSettingsWave[0][15][i] = MCC_GetBridgeBalResist() * AI_GetMCCScale(I_CLAMP_MODE, MCC_GETBRIDGEBALRESIST_FUNC)
			ampSettingsWave[0][36][i] = MCC_GetSlowCurrentInjEnable()
			ampSettingsWave[0][37][i] = MCC_GetSlowCurrentInjLevel()
			ampSettingsWave[0][38][i] = MCC_GetSlowCurrentInjSetlTime()

			// parameters exclusively on the MIES amplifier panel
			ampSettingsWave[0][43][i] = ampParamStorage[%AutoBiasVcom][0][i]
			ampSettingsWave[0][44][i] = ampParamStorage[%AutoBiasVcomVariance][0][i]
			ampSettingsWave[0][45][i] = ampParamStorage[%AutoBiasIbiasmax][0][i]
			ampSettingsWave[0][46][i] = ampParamStorage[%AutoBiasEnable][0][i]
		endif

		ampSettingsWave[0][16][i] = tds.SerialNum
		ampSettingsWave[0][17][i] = tds.ChannelID
		ampSettingsWave[0][18][i] = tds.ComPortID
		ampSettingsWave[0][19][i] = tds.AxoBusID
		ampSettingsWave[0][20][i] = tds.OperatingMode
		ampSettingsWave[0][21][i] = tds.ScaledOutSignal
		ampSettingsWave[0][22][i] = tds.Alpha
		ampSettingsWave[0][23][i] = tds.ScaleFactor
		ampSettingsWave[0][24][i] = tds.ScaleFactorUnits
		ampSettingsWave[0][25][i] = tds.LPFCutoff
		ampSettingsWave[0][26][i] = tds.MembraneCap * 1e+12 // converts F to pF
		ampSettingsWave[0][27][i] = tds.ExtCmdSens
		ampSettingsWave[0][28][i] = tds.RawOutSignal
		ampSettingsWave[0][29][i] = tds.RawScaleFactor
		ampSettingsWave[0][30][i] = tds.RawScaleFactorUnits
		ampSettingsWave[0][31][i] = tds.HardwareType
		ampSettingsWave[0][32][i] = tds.SecondaryAlpha
		ampSettingsWave[0][33][i] = tds.SecondaryLPFCutoff
		ampSettingsWave[0][34][i] = tds.SeriesResistance * 1e-6 // converts Ohms to MOhms

		ampSettingsTextWave[0][0][i] = tds.OperatingModeString
		ampSettingsTextWave[0][1][i] = tds.ScaledOutSignalString
		ampSettingsTextWave[0][2][i] = tds.ScaleFactorUnitsString
		ampSettingsTextWave[0][3][i] = tds.RawOutSignalString
		ampSettingsTextWave[0][4][i] = tds.RawScaleFactorUnitsString
		ampSettingsTextWave[0][5][i] = tds.HardwareTypeString

		// new parameters
		ampSettingsWave[0][35][i] = MCC_GetPipetteOffset() * AI_GetMCCScale(NaN, MCC_GETPIPETTEOFFSET_FUNC)
	endfor

	ED_AddEntriesToLabnotebook(ampSettingsWave, ampSettingsKey, sweepNo, panelTitle, DATA_ACQUISITION_MODE)
	ED_AddEntriesToLabnotebook(ampSettingsTextWave, ampSettingsTextKey, sweepNo, panelTitle, DATA_ACQUISITION_MODE)
End

/// @brief Auto fills the units and gains for all headstages connected to amplifiers
/// by querying the MCC application
///
/// The data is inserted into `ChanAmpAssign` and `ChanAmpAssignUnit`
///
/// @return number of connected amplifiers
Function AI_QueryGainsFromMCC(panelTitle)
	string panelTitle

	variable clampMode, old_ClampMode, i, numConnAmplifiers, clampModeSwitchAllowed
	variable DAGain, ADGain
	string DAUnit, ADUnit

	for(i = 0; i < NUM_HEADSTAGES; i += 1)

		if(AI_SelectMultiClamp(panelTitle, i) != AMPLIFIER_CONNECTION_SUCCESS)
			continue
		endif

		numConnAmplifiers += 1

		clampMode = MCC_GetMode()
		AI_AssertOnInvalidClampMode(clampMode)

		AI_QueryGainsUnitsForClampMode(panelTitle, i, clampMode, DAGain, ADGain, DAUnit, ADUnit)
		AI_UpdateChanAmpAssign(panelTitle, i, clampMode, DAGain, ADGain, DAUnit, ADUnit)

		clampModeSwitchAllowed = !MCC_GetHoldingEnable()

#ifdef AUTOMATED_TESTING
		if(!clampModeSwitchAllowed)
			printf "AI_QueryGainsFromMCC: Turning off holding potential for automated testing!\r"
			MCC_SetHoldingEnable(0)
			clampModeSwitchAllowed = 1
		endif
#endif

		if(clampModeSwitchAllowed)
			old_clampMode = clampMode
			AI_SwitchAxonAmpMode()

			clampMode = MCC_GetMode()

			AI_QueryGainsUnitsForClampMode(panelTitle, i, clampMode, DAGain, ADGain, DAUnit, ADUnit)
			AI_UpdateChanAmpAssign(panelTitle, i, clampMode, DAGain, ADGain, DAUnit, ADUnit)

			AI_SetClampMode(panelTitle, i, old_clampMode)
		else
			printf "It appears that a holding potential is being applied, therefore as a precaution, "
			printf "the gains cannot be imported for the %s.\r", ConvertAmplifierModeToString(clampMode == V_CLAMP_MODE ? I_CLAMP_MODE : V_CLAMP_MODE)
			printf "The gains were successfully imported for the %s on i: %d\r", ConvertAmplifierModeToString(clampMode), i
		endif
	endfor

	return numConnAmplifiers
End

/// @brief Create the amplifier connection waves
Function AI_FindConnectedAmps()

	IH_RemoveAmplifierConnWaves()

	DFREF saveDFR = GetDataFolderDFR()
	SetDataFolder GetAmplifierFolder()

	AxonTelegraphFindServers
	WAVE telegraphServers = GetAmplifierTelegraphServers()
	MDSort(telegraphServers, 0, keyColSecondary=1)

	MCC_FindServers/Z=1

	SetDataFolder saveDFR
End

#else // AMPLIFIER_XOPS_PRESENT

Function AI_GetHoldingCommand(panelTitle, headstage)
	string panelTitle
	variable headstage

	DEBUGPRINT("Unimplemented")
End

Function AI_GetMode(panelTitle, headstage)
	string panelTitle
	variable headstage

	DEBUGPRINT("Unimplemented")
End

static Function AI_RetrieveGains(panelTitle, headstage, clampMode, ADGain, DAGain)
	string panelTitle
	variable headstage, clampMode
	variable &ADGain, &DAGain

	ADGain = NaN
	DAGain = NaN

	DEBUGPRINT("Unimplemented")
End

static Function AI_SwitchAxonAmpMode()

	DEBUGPRINT("Unimplemented")
End

Function AI_SelectMultiClamp(panelTitle, headStage)
	string panelTitle
	variable headStage

	DEBUGPRINT("Unimplemented")
End

Function AI_SetClampMode(panelTitle, headStage, mode, [zeroStep])
	string panelTitle
	variable headStage
	variable mode, zeroStep

	DEBUGPRINT("Unimplemented")
End

Function AI_SendToAmp(panelTitle, headStage, mode, func, value, [checkBeforeWrite, usePrefixes, selectAmp])
	string panelTitle
	variable headStage, mode, func, value
	variable checkBeforeWrite, usePrefixes, selectAmp

	DEBUGPRINT("Unimplemented")
End

Function AI_EnsureCorrectMode(panelTitle, headStage, [selectAmp])
	string panelTitle
	variable headStage, selectAmp

	DEBUGPRINT("Unimplemented")
End

Function AI_FillAndSendAmpliferSettings(panelTitle, sweepNo)
	string panelTitle
	variable sweepNo

	DEBUGPRINT("Unimplemented")
End

Function AI_QueryGainsFromMCC(panelTitle)
	string panelTitle

	DEBUGPRINT("Unimplemented")
End

Function AI_FindConnectedAmps()

	DEBUGPRINT("Unimplemented")
End
#endif
