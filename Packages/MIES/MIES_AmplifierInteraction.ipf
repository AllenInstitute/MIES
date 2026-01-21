#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors = 1

#ifdef AUTOMATED_TESTING
#pragma ModuleName = MIES_AI
#endif // AUTOMATED_TESTING

/// @file MIES_AmplifierInteraction.ipf
/// @brief __AI__ Interface with the Axon/MCC amplifiers

static Constant ZERO_TOLERANCE = 100 // pA

static StrConstant AMPLIFIER_CONTROLS_VC = "setvar_DataAcq_Hold_VC;check_DataAcq_Amp_Chain;check_DatAcq_HoldEnableVC;setvar_DataAcq_WCC;setvar_DataAcq_WCR;check_DatAcq_WholeCellEnable;setvar_DataAcq_RsCorr;setvar_DataAcq_RsPred;check_DataAcq_Amp_Chain;check_DatAcq_RsCompEnable;setvar_DataAcq_PipetteOffset_VC;button_DataAcq_FastComp_VC;button_DataAcq_SlowComp_VC;button_DataAcq_AutoPipOffset_VC;button_DataAcq_WCAuto"
static StrConstant AMPLIFIER_CONTROLS_IC = "setvar_DataAcq_Hold_IC;check_DatAcq_HoldEnable;setvar_DataAcq_BB;check_DatAcq_BBEnable;setvar_DataAcq_CN;check_DatAcq_CNEnable;setvar_DataAcq_AutoBiasV;setvar_DataAcq_AutoBiasVrange;setvar_DataAcq_IbiasMax;check_DataAcq_AutoBias;setvar_DataAcq_PipetteOffset_IC;button_DataAcq_AutoBridgeBal_IC;button_DataAcq_AutoBridgeBal_IC;button_DataAcq_AutoPipOffset_IC"

static Constant MAX_PIPETTEOFFSET = 150 // mV
static Constant MIN_PIPETTEOFFSET = -150

static Constant NUM_TRIES_AXON_TELEGRAPH = 10

#if exists("MCC_GetMode") && exists("AxonTelegraphGetDataStruct")
#define AMPLIFIER_XOPS_PRESENT
#endif

static Function AI_InitAxonTelegraphStruct(STRUCT AxonTelegraph_DataStruct &tds)

	tds.version = 13
End

static Structure AxonTelegraph_DataStruct
	uint32 Version ///< Structure version.  Value should always be 13.
	uint32 SerialNum
	uint32 ChannelID
	uint32 ComPortID
	uint32 AxoBusID
	uint32 OperatingMode
	string OperatingModeString
	uint32 ScaledOutSignal
	string ScaledOutSignalString
	double Alpha
	double ScaleFactor
	uint32 ScaleFactorUnits
	string ScaleFactorUnitsString
	double LPFCutoff
	double MembraneCap
	double ExtCmdSens
	uint32 RawOutSignal
	string RawOutSignalString
	double RawScaleFactor
	uint32 RawScaleFactorUnits
	string RawScaleFactorUnitsString
	uint32 HardwareType
	string HardwareTypeString
	double SecondaryAlpha
	double SecondaryLPFCutoff
	double SeriesResistance
EndStructure

/// @brief Returns the serial number of the headstage compatible with Axon* functions, @see GetChanAmpAssign
static Function AI_GetAmpAxonSerial(string device, variable headStage)

	WAVE ChanAmpAssign = GetChanAmpAssign(device)

	return ChanAmpAssign[%AmpSerialNo][headStage]
End

/// @brief Returns the serial number of the headstage compatible with MCC* functions, @see GetChanAmpAssign
static Function/S AI_GetAmpMCCSerial(string device, variable headStage)

	variable axonSerial
	string   mccSerial

	axonSerial = AI_GetAmpAxonSerial(device, headStage)

	if(axonSerial == 0)
		return "Demo"
	endif

	sprintf mccSerial, "%08d", axonSerial
	return mccSerial
End

///@brief Return the channel of the currently selected head stage
static Function AI_GetAmpChannel(string device, variable headStage)

	WAVE ChanAmpAssign = GetChanAmpAssign(device)

	return ChanAmpAssign[%AmpChannelID][headStage]
End

static Function AI_IsValidSerialAndChannel([string mccSerial, variable axonSerial, variable channel])

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

static Function AI_AssertOnInvalidAccessType(variable accessType)

	ASSERT(accessType == MCC_READ || accessType == MCC_WRITE, "Invalid accessType")
End

/// @brief Return the unit prefixes used by MIES in comparison to the MCC app
///
/// @param clampMode  clamp mode (pass `NaN` for doesn't matter)
/// @param func       MCC function, one of @ref AI_SendToAmpConstants
/// @param accessType One of @ref MCCAccessType
Function AI_GetMCCScale(variable clampMode, variable func, variable accessType)

	AI_AssertOnInvalidAccessType(accessType)

	if(IsFinite(clampMode))
		AI_AssertOnInvalidClampMode(clampMode)
	endif

	if(clampMode == V_CLAMP_MODE)
		if(accessType == MCC_WRITE)
			switch(func)
				case MCC_HOLDING_FUNC:
					return MILLI_TO_ONE
				case MCC_PIPETTEOFFSET_FUNC:
					return MILLI_TO_ONE
				case MCC_RSCOMPBANDWIDTH_FUNC:
					return ONE_TO_MILLI
				case MCC_WHOLECELLCOMPRESIST_FUNC:
					return ONE_TO_MICRO
				case MCC_WHOLECELLCOMPCAP_FUNC:
					return PICO_TO_ONE
				default:
					return 1
					break
			endswitch
		elseif(accessType == MCC_READ)
			switch(func)
				case MCC_HOLDING_FUNC:
					return ONE_TO_MILLI
				case MCC_PIPETTEOFFSET_FUNC:
					return ONE_TO_MILLI
				case MCC_RSCOMPBANDWIDTH_FUNC:
					return MILLI_TO_ONE
				case MCC_WHOLECELLCOMPRESIST_FUNC:
					return MICRO_TO_ONE
				case MCC_WHOLECELLCOMPCAP_FUNC:
					return ONE_TO_PICO
				default:
					return 1
					break
			endswitch
		endif
	else // IC and I=0
		if(accessType == MCC_WRITE)
			switch(func)
				case MCC_BRIDGEBALRESIST_FUNC:
					return ONE_TO_MICRO
				case MCC_HOLDING_FUNC:
					return PICO_TO_ONE
				case MCC_PIPETTEOFFSET_FUNC:
					return MILLI_TO_ONE
				case MCC_NEUTRALIZATIONCAP_FUNC:
					return PICO_TO_ONE
				default:
					return 1
					break
			endswitch
		elseif(accessType == MCC_READ)
			switch(func)
				case MCC_BRIDGEBALRESIST_FUNC:
					return MICRO_TO_ONE
				case MCC_HOLDING_FUNC:
					return ONE_TO_PICO
				case MCC_PIPETTEOFFSET_FUNC:
					return ONE_TO_MILLI
				case MCC_NEUTRALIZATIONCAP_FUNC:
					return ONE_TO_PICO
				default:
					return 1
					break
			endswitch
		endif
	endif
End

/// @brief Update the AmpStorageWave entry and send the value to the amplifier
///
/// One of either `ctrl` or `func` plus `clampMode` is required.
///
/// @param device           device
/// @param ctrl             [optional] name of the amplifier control
/// @param headStage        MIES headstage number, must be in the range [0, NUM_HEADSTAGES[
/// @param value            [optional: defaults to the controls value] value to set. values is in MIES units, see AI_SendToAmp()
///                         and there the description of `usePrefixes`.
/// @param sendToAll        [optional: defaults to the state of the checkbox] should the value be send
///                         to all active headstages (true) or just to the given one (false)
/// @param checkBeforeWrite [optional, defaults to false] (ignored for getter functions)
///                         check the current value and do nothing if it is equal within some tolerance to the one written
/// @param selectAmp        [optional, defaults to true] Select the amplifier
///                         before use, some callers might save time in doing that once themselves.
/// @param func             [optional] Function to call, see @ref AI_SendToAmpConstants
/// @param clampMode        [optional] One of V_CLAMP_MODE, I_CLAMP_MODE or I_EQUAL_ZERO_MODE
/// @param GUIWrite         [optional, defaults to false] Should the amplifier control, if available, be updated with the value
///
/// @return 0 on success, 1 otherwise
static Function AI_UpdateAmpModel(string device, variable headStage, [string ctrl, variable value, variable sendToAll, variable checkBeforeWrite, variable selectAmp, variable func, variable clampMode, variable GUIWrite])

	variable i, diff, selectedHeadstage, oppositeMode, oldTab
	variable runMode = TEST_PULSE_NOT_RUNNING
	string str, rowLabel

	DAP_AbortIfUnlocked(device)

	selectedHeadstage = DAG_GetNumericalValue(device, "slider_DataAcq_ActiveHeadstage")

	if(ParamIsDefault(value))
		FATAL_ERROR("Missing optional parameter value")
	endif

	if(ParamIsDefault(selectAmp))
		selectAmp = 1
	else
		selectAmp = !!selectAmp
	endif

	if(ParamIsDefault(GUIWrite))
		GUIWrite = 1
	else
		GUIWrite = !!GUIWrite
	endif

	if(ParamIsDefault(sendToAll))
		if(headstage == selectedHeadstage)
			sendToAll = DAG_GetNumericalValue(device, "Check_DataAcq_SendToAllAmp")
		else
			sendToAll = 0
		endif
	else
		sendToAll = !!sendToAll
	endif

	if(ParamIsDefault(checkBeforeWrite))
		checkBeforeWrite = 0
	endif

	if(ParamIsDefault(ctrl))
		ASSERT(!ParamIsDefault(func) && !ParamIsDefault(clampMode), "Default ctrl requires func and clampMode")
		ASSERT(func > MCC_BEGIN_INVALID_FUNC && func < MCC_END_INVALID_FUNC, "MCC function constant is out for range")
		AI_AssertOnInvalidClampMode(clampMode)

		ctrl = AI_MapFunctionConstantToControl(func, clampMode)
	else
		[func, clampMode] = AI_MapControlNameToFunctionConstant(ctrl)
	endif

	WAVE AmpStoragewave = GetAmplifierParamStorageWave(device)

	WAVE statusHS = DAG_GetChannelState(device, CHANNEL_TYPE_HEADSTAGE)
	if(!sendToAll)
		statusHS[] = ((p == headStage) ? 1 : 0)
	endif

	if(IsEmpty(ctrl))
		GUIWrite = 0
	elseif(!CheckIfValueIsInsideLimits(device, ctrl, value))
		DEBUGPRINT("Ignoring value to set as it is out of range compared to the control limits")
		return 1
	endif

	if(func == MCC_AUTOPIPETTEOFFSET_FUNC)
		runMode = TP_StopTestPulseFast(device)
	endif

	for(i = 0; i < NUM_HEADSTAGES; i += 1)

		if(!statusHS[i])
			continue
		endif

		if(selectAmp)
			if(AI_SelectMultiClamp(device, i) != AMPLIFIER_CONNECTION_SUCCESS)
				continue
			endif
		endif

		sprintf str, "headstage %d, func %d, clamp mode %s, value %g", i, func, ConvertAmplifierModeToString(clampMode), value
		DEBUGPRINT(str)

		switch(func)
			case MCC_HOLDING_FUNC: // fallthrough
			case MCC_HOLDINGENABLE_FUNC: // fallthrough
			case MCC_WHOLECELLCOMPCAP_FUNC: // fallthrough
			case MCC_WHOLECELLCOMPRESIST_FUNC: // fallthrough
			case MCC_WHOLECELLCOMPENABLE_FUNC: // fallthrough
			case MCC_RSCOMPENABLE_FUNC: // fallthrough
			case MCC_PIPETTEOFFSET_FUNC: // fallthrough
			case MCC_BRIDGEBALRESIST_FUNC: // fallthrough
			case MCC_BRIDGEBALENABLE_FUNC: // fallthrough
			case MCC_NEUTRALIZATIONCAP_FUNC: // fallthrough
			case MCC_NEUTRALIZATIONENABL_FUNC:
				rowLabel = AI_MapFunctionConstantToName(func, clampMode)

				AmpStorageWave[%$rowLabel][0][i] = value

				AI_SendToAmp(device, i, clampMode, func, MCC_WRITE, value = value, checkBeforeWrite = checkBeforeWrite, selectAmp = 0)

				if(func == MCC_HOLDING_FUNC || func == MCC_HOLDINGENABLE_FUNC)
					TP_UpdateHoldCmdInTPStorage(device, headstage)
				endif
				break
			case MCC_AUTOFASTCOMP_FUNC: // fallthrough
			case MCC_AUTOSLOWCOMP_FUNC:
				rowLabel = AI_MapFunctionConstantToName(func, clampMode)

				AmpStorageWave[%$rowLabel][0][i] = 0
				AI_SendToAmp(device, i, clampMode, func, MCC_WRITE, value = NaN, checkBeforeWrite = checkBeforeWrite, selectAmp = 0)
				break
			case MCC_AUTOWHOLECELLCOMP_FUNC:
				AI_SendToAmp(device, i, clampMode, func, MCC_WRITE, value = NaN, checkBeforeWrite = checkBeforeWrite, selectAmp = 0)

				func                             = MCC_WHOLECELLCOMPCAP_FUNC
				rowLabel                         = AI_MapFunctionConstantToName(func, clampMode)
				value                            = AI_SendToAmp(device, i, clampMode, func, MCC_READ, checkBeforeWrite = checkBeforeWrite, selectAmp = 0)
				AmpStorageWave[%$rowLabel][0][i] = value
				AI_UpdateAmpView(device, headstage, func = func, clampMode = clampMode)

				func                             = MCC_WHOLECELLCOMPRESIST_FUNC
				rowLabel                         = AI_MapFunctionConstantToName(func, clampMode)
				value                            = AI_SendToAmp(device, i, clampMode, func, MCC_READ, checkBeforeWrite = checkBeforeWrite, selectAmp = 0)
				AmpStorageWave[%$rowLabel][0][i] = value
				AI_UpdateAmpView(device, headstage, func = func, clampMode = clampMode)

				func                             = MCC_WHOLECELLCOMPENABLE_FUNC
				rowLabel                         = AI_MapFunctionConstantToName(func, clampMode)
				value                            = AI_SendToAmp(device, i, clampMode, func, MCC_READ, checkBeforeWrite = checkBeforeWrite, selectAmp = 0)
				AmpStorageWave[%$rowLabel][0][i] = value
				AI_UpdateAmpView(device, headstage, func = func, clampMode = clampMode)
				break
			case MCC_RSCOMPCORRECTION_FUNC:
				rowLabel = AI_MapFunctionConstantToName(func, clampMode)

				diff = value - AmpStorageWave[%$rowLabel][0][i]
				// abort if the corresponding value with chaining would be outside the limits
				if(AmpStorageWave[%RSCompChaining][0][i] && !CheckIfValueIsInsideLimits(device, "setvar_DataAcq_RsPred", AmpStorageWave[%Prediction][0][i] + diff))
					AI_UpdateAmpView(device, i, func = func, clampMode = clampMode)
					return 1
				endif
				AmpStorageWave[%$rowLabel][0][i] = value
				AI_SendToAmp(device, i, clampMode, func, MCC_WRITE, value = value, checkBeforeWrite = checkBeforeWrite, selectAmp = 0)
				if(AmpStorageWave[%RSCompChaining][0][i])
					func     = MCC_RSCOMPPREDICTION_FUNC
					rowLabel = AI_MapFunctionConstantToName(func, clampMode)

					AmpStorageWave[%$rowLabel][0][i] += diff
					AI_SendToAmp(device, i, clampMode, func, MCC_WRITE, value = AmpStorageWave[%$rowLabel][0][i], checkBeforeWrite = checkBeforeWrite, selectAmp = 0)
					AI_UpdateAmpView(device, i, func = func, clampMode = clampMode)
				endif
				break
			case MCC_RSCOMPPREDICTION_FUNC:
				rowLabel = AI_MapFunctionConstantToName(func, clampMode)

				diff = value - AmpStorageWave[%$rowLabel][0][i]
				// abort if the corresponding value with chaining would be outside the limits
				if(AmpStorageWave[%RSCompChaining][0][i] && !CheckIfValueIsInsideLimits(device, "setvar_DataAcq_RsCorr", AmpStorageWave[%Correction][0][i] + diff))
					AI_UpdateAmpView(device, i, func = func, clampMode = clampMode)
					return 1
				endif
				AmpStorageWave[%$rowLabel][0][i] = value
				AI_SendToAmp(device, i, clampMode, func, MCC_WRITE, value = value, checkBeforeWrite = checkBeforeWrite, selectAmp = 0)
				if(AmpStorageWave[%RSCompChaining][0][i])
					func     = MCC_RSCOMPCORRECTION_FUNC
					rowLabel = AI_MapFunctionConstantToName(func, clampMode)

					AmpStorageWave[%$rowLabel][0][i] += diff
					AI_SendToAmp(device, i, clampMode, func, MCC_WRITE, value = AmpStorageWave[%$rowLabel][0][i], checkBeforeWrite = checkBeforeWrite, selectAmp = 0)
					AI_UpdateAmpView(device, i, func = func, clampMode = clampMode)
				endif
				break
			case MCC_AUTOPIPETTEOFFSET_FUNC:

				if(clampMode == V_CLAMP_MODE)
					oppositeMode = I_CLAMP_MODE
				else
					oppositeMode = V_CLAMP_MODE
				endif

				value = AI_SendToAmp(device, i, clampMode, func, MCC_WRITE, value = NaN, checkBeforeWrite = checkBeforeWrite, selectAmp = 0)

				func     = MCC_PIPETTEOFFSET_FUNC
				rowLabel = AI_MapFunctionConstantToName(func, clampMode)

				AmpStorageWave[%$rowLabel][0][i] = value
				AI_UpdateAmpView(device, i, func = func, clampMode = clampMode)
				// the pipette offset for the opposite mode has also changed, fetch that too
				AssertOnAndClearRTError()
				try
					oldTab = GetTabID(device, "ADC")
					if(oldTab != 0)
						PGC_SetAndActivateControl(device, "ADC", val = 0)
					endif

					DAP_ChangeHeadStageMode(device, oppositeMode, i, MCC_SKIP_UPDATES)

					func     = MCC_PIPETTEOFFSET_FUNC
					rowLabel = AI_MapFunctionConstantToName(func, oppositeMode)

					// selecting amplifier here, as the clamp mode is now different
					value                            = AI_SendToAmp(device, i, oppositeMode, func, MCC_READ, checkBeforeWrite = checkBeforeWrite, selectAmp = 1)
					AmpStorageWave[%$rowLabel][0][i] = value
					AI_UpdateAmpView(device, i, func = func, clampMode = oppositeMode)
					DAP_ChangeHeadStageMode(device, clampMode, i, MCC_SKIP_UPDATES)

					if(oldTab != 0)
						PGC_SetAndActivateControl(device, "ADC", val = oldTab)
					endif
				catch
					ClearRTError()
					if(DAG_GetNumericalValue(device, "check_Settings_SyncMiesToMCC"))
						printf "(%s) The pipette offset for %s of headstage %d is invalid.\r", device, ConvertAmplifierModeToString(oppositeMode), i
					endif
					// do nothing
				endtry
				break
			case MCC_NO_AMPCHAIN_FUNC:
				rowLabel = AI_MapFunctionConstantToName(func, clampMode)

				AmpStorageWave[%$rowLabel][0][i] = value

				PUB_AmplifierSettingChange(device, i, clampMode, func, value)

				AI_UpdateAmpModel(device, i, ctrl = "setvar_DataAcq_RsCorr", value = AmpStorageWave[%$rowLabel][0][i], selectAmp = 0)
				break
			case MCC_NO_AUTOBIAS_V_FUNC: // fallthrough
			case MCC_NO_AUTOBIAS_VRANGE_FUNC: // fallthrough
			case MCC_NO_AUTOBIAS_IBIASMAX_FUNC: // fallthrough
			case MCC_NO_AUTOBIAS_ENABLE_FUNC:
				rowLabel = AI_MapFunctionConstantToName(func, clampMode)

				AmpStorageWave[%$rowLabel][0][i] = value

				PUB_AmplifierSettingChange(device, i, clampMode, func, value)
				break
			case MCC_AUTOBRIDGEBALANCE_FUNC:
				clampMode = I_CLAMP_MODE

				value = AI_SendToAmp(device, i, clampMode, func, MCC_WRITE, value = NaN, checkBeforeWrite = checkBeforeWrite, selectAmp = 0)
				AI_UpdateAmpModel(device, i, ctrl = "setvar_DataAcq_BB", value = value, selectAmp = 0)
				AI_UpdateAmpModel(device, i, ctrl = "check_DatAcq_BBEnable", value = 1, selectAmp = 0)
				break
			// no GUI controls
			case MCC_RSCOMPBANDWIDTH_FUNC: // fallthrough
			case MCC_OSCKILLERENABLE_FUNC: // fallthrough
			case MCC_FASTCOMPCAP_FUNC: // fallthrough
			case MCC_SLOWCOMPCAP_FUNC: // fallthrough
			case MCC_FASTCOMPTAU_FUNC: // fallthrough
			case MCC_SLOWCOMPTAU_FUNC: // fallthrough
			case MCC_SLOWCOMPTAUX20ENAB_FUNC: // fallthrough
			case MCC_SLOWCURRENTINJENABL_FUNC: // fallthrough
			case MCC_PRIMARYSIGNALGAIN_FUNC: // fallthrough
			case MCC_SLOWCURRENTINJLEVEL_FUNC: // fallthrough
			case MCC_SLOWCURRENTINJSETLT_FUNC: // fallthrough
			case MCC_SECONDARYSIGNALGAIN_FUNC: // fallthrough
			case MCC_PRIMARYSIGNALHPF_FUNC: // fallthrough
			case MCC_PRIMARYSIGNALLPF_FUNC: // fallthrough
			case MCC_SECONDARYSIGNALLPF_FUNC:
				AI_SendToAmp(device, i, clampMode, func, MCC_WRITE, value = value, checkBeforeWrite = checkBeforeWrite)
				break
			default:
				FATAL_ERROR("Unknown func: " + num2str(func))
				break
		endswitch

		if(GUIWrite)
			AI_UpdateAmpView(device, i, func = func, clampMode = clampMode)
		endif
	endfor

	TP_RestartTestPulse(device, runMode, fast = 1)

	return 0
End

/// @brief Convenience wrapper for #AI_UpdateAmpView
///
/// Disallows setting single controls for outside callers as #AI_UpdateAmpModel should be used for that.
Function AI_SyncAmpStorageToGUI(string device, variable headstage)

	return AI_UpdateAmpView(device, headstage)
End

/// @brief Sync the settings from the GUI to the amp storage wave and the MCC application
Function AI_SyncGUIToAmpStorageAndMCCApp(string device, variable headStage, variable clampMode, [variable force])

	string ctrl, list
	variable i, numEntries, value, checkBeforeWrite

	DAP_AbortIfUnlocked(device)
	AI_AssertOnInvalidClampMode(clampMode)

	if(ParamIsDefault(force))
		force = 0
	else
		force = !!force
	endif

	if(DAG_GetNumericalValue(device, "slider_DataAcq_ActiveHeadstage") != headStage)
		return NaN
	endif

	if(AI_EnsureCorrectMode(device, headStage, selectAmp = 1))
		return NaN
	endif

	if(clampMode == V_CLAMP_MODE)
		list = AMPLIFIER_CONTROLS_VC
	else
		list = AMPLIFIER_CONTROLS_IC
	endif

	if(force)
		checkBeforeWrite = 0
	else
		checkBeforeWrite = 1
	endif

	numEntries = ItemsInList(list)
	for(i = 0; i < numEntries; i += 1)
		ctrl = StringFromList(i, list)

		if(StringMatch(ctrl, "button_*"))
			continue
		endif

		value = DAG_GetNumericalValue(device, ctrl)
		AI_UpdateAmpModel(device, headStage, ctrl = ctrl, value = value, checkBeforeWrite = checkBeforeWrite, sendToAll = 0, selectAmp = 0)
	endfor
End

/// @brief Synchronizes the AmpStorageWave to the amplifier GUI control
///
/// @param device      device
/// @param headStage   MIES headstage number, must be in the range [0, NUM_HEADSTAGES]
/// @param func        Function to call, see @ref AI_SendToAmpConstants
/// @param clampMode   one of #V_CLAMP_MODE, #I_CLAMP_MODE or #I_EQUAL_ZERO_MODE
static Function AI_UpdateAmpView(string device, variable headStage, [variable func, variable clampMode])

	string lbl, list, ctrl
	variable i, numEntries, value

	DAP_AbortIfUnlocked(device)

	// only update view if headstage is selected
	if(DAG_GetNumericalValue(device, "slider_DataAcq_ActiveHeadstage") != headStage)
		return NaN
	endif

	WAVE AmpStorageWave = GetAmplifierParamStorageWave(device)

	if(!ParamIsDefault(func))
		ASSERT(!ParamIsDefault(clampMode), "Missing clampMode")
		list = AI_MapFunctionConstantToControl(func, clampMode)
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
			SetSetVariable(device, ctrl, value)
			DAG_Update(device, ctrl, val = value)
		elseif(StringMatch(ctrl, "check_*"))
			SetCheckBoxState(device, ctrl, value)
			DAG_Update(device, ctrl, val = value)
		elseif(!cmpstr(ctrl, "button_DataAcq_WCAuto"))
			// do nothing
		else
			FATAL_ERROR("Unhandled control: " + ctrl)
		endif
	endfor
End

Function AI_SetMIESHeadstage(string device, [variable headstage, variable increment])

	if(ParamIsDefault(headstage) && ParamIsDefault(increment))
		return NaN
	endif

	if(!ParamIsDefault(increment))
		headstage = DAG_GetNumericalValue(device, "slider_DataAcq_ActiveHeadstage") + increment
	endif

	if(headstage >= 0 && headstage < NUM_HEADSTAGES)
		PGC_SetAndActivateControl(device, "slider_DataAcq_ActiveHeadstage", val = headstage)
	endif
End

/// @brief Executes MCC auto zero command if the baseline current exceeds #ZERO_TOLERANCE
///
/// @param device device
/// @param headStage     [optional: defaults to all active headstages]
Function AI_ZeroAmps(string device, [variable headStage])

	variable i
	// Ensure that data in BaselineSSAvg is up to date by verifying that TP is active
	if(IsDeviceActiveWithBGTask(device, "TestPulse") || IsDeviceActiveWithBGTask(device, "TestPulseMD"))

		WAVE TPResults = GetTPResults(device)
		if(!ParamIsDefault(headstage))
			if(abs(TPResults[%BaselineSteadyState][headstage]) >= ZERO_TOLERANCE)
				AI_MIESAutoPipetteOffset(device, headStage)
			endif
		else
			for(i = 0; i < NUM_HEADSTAGES; i += 1)
				if(abs(TPResults[%BaselineSteadyState][headstage]) >= ZERO_TOLERANCE)
					AI_MIESAutoPipetteOffset(device, i)
				endif
			endfor
		endif
	endif
End

/// @brief Auto pipette zeroing
/// Quicker than MCC auto pipette offset
///
/// @param device device
/// @param headStage MIES headstage number, must be in the range [0, NUM_HEADSTAGES]
static Function AI_MIESAutoPipetteOffset(string device, variable headStage)

	variable clampMode, vDelta, offset, value

	WAVE TPResults = GetTPResults(device)

	clampMode = DAG_GetHeadstageMode(device, headStage)

	ASSERT(clampMode == V_CLAMP_MODE || clampMode == I_CLAMP_MODE, "Headstage must be in VC/IC mode to use this function")
	// calculate delta current to reach zero
	// @todo check for IC
	vdelta = ((TPResults[%BaselineSteadyState][headstage] * PICO_TO_ONE) * (TPResults[%ResistanceSteadyState][headstage] * MEGA_TO_ONE)) * ONE_TO_MILLI
	// get current DC V offset
	offset = AI_SendToAmp(device, headStage, clampMode, MCC_PIPETTEOFFSET_FUNC, MCC_READ)
	// add delta to current DC V offset
	value = offset - vDelta
	if(value > MIN_PIPETTEOFFSET && value < MAX_PIPETTEOFFSET)
		AI_UpdateAmpModel(device, headStage, ctrl = "setvar_DataAcq_PipetteOffset_VC", value = value, checkBeforeWrite = 1)
		AI_UpdateAmpModel(device, headStage, ctrl = "setvar_DataAcq_PipetteOffset_IC", value = value, checkBeforeWrite = 1)
	endif
End

/// @brief Query the MCC application for the gains and units of the given clamp mode
///
/// Assumes that the correct amplifier is already selected!
Function AI_QueryGainsUnitsForClampMode(string device, variable headstage, variable clampMode, variable &DAGain, variable &ADGain, string &DAUnit, string &ADUnit)

	DAGain = NaN
	ADGain = NaN
	DAUnit = ""
	ADUnit = ""

	AI_AssertOnInvalidClampMode(clampMode)

	AI_RetrieveGains(device, headstage, clampMode, ADGain, DAGain)

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
Function AI_UpdateChanAmpAssign(string device, variable headStage, variable clampMode, variable DAGain, variable ADGain, string DAUnit, string ADUnit)

	AI_AssertOnInvalidClampMode(clampMode)

	WAVE   ChanAmpAssign     = GetChanAmpAssign(device)
	WAVE/T ChanAmpAssignUnit = GetChanAmpAssignUnit(device)

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
threadsafe Function AI_AssertOnInvalidClampMode(variable clampMode)

	ASSERT_TS(AI_IsValidClampMode(clampMode), "invalid clamp mode")
End

/// @brief Return true if the given clamp mode is valid
threadsafe Function AI_IsValidClampMode(variable clampMode)

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
Function AI_OpenMCCs(string ampSerialNumList, [string ampTitleList])

	string cmd, serialStr, title
	variable i, j, numDups, serialNum, failedToOpenCount
	variable ItemsInAmpSerialNumList = ItemsInList(AmpSerialNumList)
	variable maxAttempts             = 3

	if(paramIsDefault(AmpTitleList))
		AmpTitleList = ""
	else
		ASSERT(ItemsInAmpSerialNumList == ItemsInList(ampTitleList), "Number of amplifier serials does not match number of amplifier titles.")
	endif

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
		AmpSerialNumList        = TextWaveToList(ampSerialList, ";")
		ItemsInAmpSerialNumList = ItemsInList(AmpSerialNumList)
	endif

	WAVE OpenMCCList = AI_GetMCCSerialNumbers()
	do
		for(i = 0; i < ItemsInAmpSerialNumList; i += 1)
			serialStr = stringfromlist(i, AmpSerialNumList)
			serialNum = str2num(serialStr)
			title     = stringfromlist(i, AmpTitleList)
			findvalue/I=(serialNum) OpenMCCList
			if(V_value == -1)
				if(!serialNum)
					sprintf cmd, "\"%s\" /T%s(%s)", AI_GetMCCWinFilePath(), title, SerialStr
				else
					sprintf cmd, "\"%s\" /S00%g /T%s(%s)", AI_GetMCCWinFilePath(), SerialNum, title, SerialStr
				endif
				executeScriptText cmd
			endif
		endfor

		failedToOpenCount = 0
		WAVE OpenMCCList = AI_GetMCCSerialNumbers()
		for(i = 0; i < ItemsInAmpSerialNumList; i += 1)
			serialNum = str2num(serialStr)
			findvalue/I=(serialNum) OpenMCCList
			if(v_value == -1)
				failedToOpenCount += 1
			endif
		endfor

		if(failedToOpenCount > 0)
			printf "%g MCCs failed to open on attempt count %g\r", failedTOopenCount, j
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

	AI_FindConnectedAmps(rescanHardware = 1)
	WAVE W_TelegraphServers = GetAmplifierTelegraphServers()
	Duplicate/FREE/R=[][FindDimLabel(W_TelegraphServers, COLS, "SerialNum")] W_TelegraphServers, OpenMCCList
	return GetUniqueEntries(OpenMCCList)
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

	MAKE/FREE/T locations = {"Molecular Devices\\MultiClamp_64\\MC700B.exe", "Molecular Devices\\MultiClamp 700B Commander\\MC700B.exe"}

	numEntries = DimSize(locations, ROWS)
	for(i = 0; i < numEntries; i += 1)
		path = progFolder + locations[i]

		if(FileExists(path))
			return path
		endif
	endfor

	FATAL_ERROR("Could not find the MCC application")
	return "ERROR"
End

/// @brief Map from amplifier control names to @ref AI_SendToAmpConstants constants and clamp mode
threadsafe Function [variable func, variable clampMode] AI_MapControlNameToFunctionConstant(string ctrl)

	strswitch(ctrl)
		// begin VC controls
		case "setvar_DataAcq_Hold_VC":
			return [MCC_HOLDING_FUNC, V_CLAMP_MODE]
		case "check_DatAcq_HoldEnableVC":
			return [MCC_HOLDINGENABLE_FUNC, V_CLAMP_MODE]
		case "setvar_DataAcq_WCC":
			return [MCC_WHOLECELLCOMPCAP_FUNC, V_CLAMP_MODE]
		case "setvar_DataAcq_WCR":
			return [MCC_WHOLECELLCOMPRESIST_FUNC, V_CLAMP_MODE]
		case "button_DataAcq_WCAuto":
			return [MCC_AUTOWHOLECELLCOMP_FUNC, V_CLAMP_MODE]
		case "check_DatAcq_WholeCellEnable":
			return [MCC_WHOLECELLCOMPENABLE_FUNC, V_CLAMP_MODE]
		case "setvar_DataAcq_RsCorr":
			return [MCC_RSCOMPCORRECTION_FUNC, V_CLAMP_MODE]
		case "setvar_DataAcq_RsPred":
			return [MCC_RSCOMPPREDICTION_FUNC, V_CLAMP_MODE]
		case "check_DatAcq_RsCompEnable":
			return [MCC_RSCOMPENABLE_FUNC, V_CLAMP_MODE]
		case "setvar_DataAcq_PipetteOffset_VC":
			return [MCC_PIPETTEOFFSET_FUNC, V_CLAMP_MODE]
		case "button_DataAcq_AutoPipOffset_VC":
			return [MCC_AUTOPIPETTEOFFSET_FUNC, V_CLAMP_MODE]
		case "button_DataAcq_FastComp_VC":
			return [MCC_AUTOFASTCOMP_FUNC, V_CLAMP_MODE]
		case "button_DataAcq_SlowComp_VC":
			return [MCC_AUTOSLOWCOMP_FUNC, V_CLAMP_MODE]
		case "check_DataAcq_Amp_Chain":
			return [MCC_NO_AMPCHAIN_FUNC, V_CLAMP_MODE]
		// end VC controls
		// begin IC controls
		case "setvar_DataAcq_Hold_IC":
			return [MCC_HOLDING_FUNC, I_CLAMP_MODE]
		case "check_DatAcq_HoldEnable":
			return [MCC_HOLDINGENABLE_FUNC, I_CLAMP_MODE]
		case "setvar_DataAcq_BB":
			return [MCC_BRIDGEBALRESIST_FUNC, I_CLAMP_MODE]
		case "check_DatAcq_BBEnable":
			return [MCC_BRIDGEBALENABLE_FUNC, I_CLAMP_MODE]
		case "setvar_DataAcq_CN":
			return [MCC_NEUTRALIZATIONCAP_FUNC, I_CLAMP_MODE]
		case "check_DatAcq_CNEnable":
			return [MCC_NEUTRALIZATIONENABL_FUNC, I_CLAMP_MODE]
		case "button_DataAcq_AutoPipOffset_IC":
			return [MCC_AUTOPIPETTEOFFSET_FUNC, I_CLAMP_MODE]
		case "setvar_DataAcq_AutoBiasV":
			return [MCC_NO_AUTOBIAS_V_FUNC, I_CLAMP_MODE]
		case "setvar_DataAcq_AutoBiasVrange":
			return [MCC_NO_AUTOBIAS_VRANGE_FUNC, I_CLAMP_MODE]
		case "setvar_DataAcq_IbiasMax":
			return [MCC_NO_AUTOBIAS_IBIASMAX_FUNC, I_CLAMP_MODE]
		case "check_DataAcq_AutoBias":
			return [MCC_NO_AUTOBIAS_ENABLE_FUNC, I_CLAMP_MODE]
		case "button_DataAcq_AutoBridgeBal_IC":
			return [MCC_AUTOBRIDGEBALANCE_FUNC, I_CLAMP_MODE]
		case "setvar_DataAcq_PipetteOffset_IC":
			return [MCC_PIPETTEOFFSET_FUNC, I_CLAMP_MODE]
		// end IC controls
		default:
			FATAL_ERROR("Unknown control " + ctrl)
			break
	endswitch
End

/// @brief Map from @ref AI_SendToAmpConstants constants and clamp mode to control names
Function/S AI_MapFunctionConstantToControl(variable func, variable clampMode)

	switch(func)
		case MCC_HOLDING_FUNC:
			if(clampMode == V_CLAMP_MODE)
				return "setvar_DataAcq_Hold_VC"
			endif

			return "setvar_DataAcq_Hold_IC"
		case MCC_HOLDINGENABLE_FUNC:
			if(clampMode == V_CLAMP_MODE)
				return "check_DatAcq_HoldEnableVC"
			endif

			return "check_DatAcq_HoldEnable"
		case MCC_WHOLECELLCOMPCAP_FUNC:
			return "setvar_DataAcq_WCC"
		case MCC_WHOLECELLCOMPRESIST_FUNC:
			return "setvar_DataAcq_WCR"
		case MCC_AUTOWHOLECELLCOMP_FUNC:
			return "button_DataAcq_WCAuto"
		case MCC_WHOLECELLCOMPENABLE_FUNC:
			return "check_DatAcq_WholeCellEnable"
		case MCC_RSCOMPCORRECTION_FUNC:
			return "setvar_DataAcq_RsCorr"
		case MCC_RSCOMPPREDICTION_FUNC:
			return "setvar_DataAcq_RsPred"
		case MCC_RSCOMPENABLE_FUNC:
			return "check_DatAcq_RsCompEnable"
		case MCC_PIPETTEOFFSET_FUNC:
			if(clampMode == V_CLAMP_MODE)
				return "setvar_DataAcq_PipetteOffset_VC"
			endif

			return "setvar_DataAcq_PipetteOffset_IC"
		case MCC_AUTOPIPETTEOFFSET_FUNC:
			if(clampMode == V_CLAMP_MODE)
				return "button_DataAcq_AutoPipOffset_VC"
			endif

			return "button_DataAcq_AutoPipOffset_IC"
		case MCC_AUTOFASTCOMP_FUNC:
			return "button_DataAcq_FastComp_VC"
		case MCC_AUTOSLOWCOMP_FUNC:
			return "button_DataAcq_SlowComp_VC"
		case MCC_NO_AMPCHAIN_FUNC:
			return "check_DataAcq_Amp_Chain"
		case MCC_BRIDGEBALRESIST_FUNC:
			return "setvar_DataAcq_BB"
		case MCC_BRIDGEBALENABLE_FUNC:
			return "check_DatAcq_BBEnable"
		case MCC_NEUTRALIZATIONCAP_FUNC:
			return "setvar_DataAcq_CN"
		case MCC_NEUTRALIZATIONENABL_FUNC:
			return "check_DatAcq_CNEnable"
		case MCC_NO_AUTOBIAS_V_FUNC:
			return "setvar_DataAcq_AutoBiasV"
		case MCC_NO_AUTOBIAS_VRANGE_FUNC:
			return "setvar_DataAcq_AutoBiasVrange"
		case MCC_NO_AUTOBIAS_IBIASMAX_FUNC:
			return "setvar_DataAcq_IbiasMax"
		case MCC_NO_AUTOBIAS_ENABLE_FUNC:
			return "check_DataAcq_AutoBias"
		case MCC_AUTOBRIDGEBALANCE_FUNC:
			return "button_DataAcq_AutoBridgeBal_IC"
		// no controls available
		case MCC_RSCOMPBANDWIDTH_FUNC: // fallthrough
		case MCC_OSCKILLERENABLE_FUNC: // fallthrough
		case MCC_FASTCOMPCAP_FUNC: // fallthrough
		case MCC_SLOWCOMPCAP_FUNC: // fallthrough
		case MCC_FASTCOMPTAU_FUNC: // fallthrough
		case MCC_SLOWCOMPTAU_FUNC: // fallthrough
		case MCC_SLOWCOMPTAUX20ENAB_FUNC: // fallthrough
		case MCC_SLOWCURRENTINJENABL_FUNC: // fallthrough
		case MCC_PRIMARYSIGNALGAIN_FUNC: // fallthrough
		case MCC_SLOWCURRENTINJLEVEL_FUNC: // fallthrough
		case MCC_SLOWCURRENTINJSETLT_FUNC: // fallthrough
		case MCC_SECONDARYSIGNALGAIN_FUNC: // fallthrough
		case MCC_PRIMARYSIGNALHPF_FUNC: // fallthrough
		case MCC_PRIMARYSIGNALLPF_FUNC: // fallthrough
		case MCC_SECONDARYSIGNALLPF_FUNC:
			return ""
		default:
			FATAL_ERROR("Unknown func: " + num2str(func))
			break
	endswitch
End

/// @brief Map constants from @ref AI_SendToAmpConstants to human readable names
threadsafe Function/S AI_MapFunctionConstantToName(variable func, variable clampMode)

	AI_AssertOnInvalidClampMode(clampMode)

	switch(func)
		// begin AmpStorageWave row labels
		case MCC_HOLDING_FUNC:

			if(clampMode == V_CLAMP_MODE)
				return "HoldingPotential"
			endif

			return "BiasCurrent"
		case MCC_HOLDINGENABLE_FUNC:
			if(clampMode == V_CLAMP_MODE)
				return "HoldingPotentialEnable"
			endif

			return "BiasCurrentEnable"
		case MCC_WHOLECELLCOMPCAP_FUNC:
			return "WholeCellCap"
		case MCC_WHOLECELLCOMPRESIST_FUNC:
			return "WholeCellRes"
		case MCC_WHOLECELLCOMPENABLE_FUNC:
			return "WholeCellEnable"
		case MCC_RSCOMPCORRECTION_FUNC:
			return "Correction"
		case MCC_RSCOMPPREDICTION_FUNC:
			return "Prediction"
		case MCC_RSCOMPENABLE_FUNC:
			return "RsCompEnable"
		case MCC_PIPETTEOFFSET_FUNC:
			if(clampMode == V_CLAMP_MODE)
				return "PipetteOffsetVC"
			endif

			return "PipetteOffsetIC"
		case MCC_AUTOFASTCOMP_FUNC:
			return "FastCapacitanceComp"
		case MCC_AUTOSLOWCOMP_FUNC:
			return "SlowCapacitanceComp"
		case MCC_AUTOBRIDGEBALANCE_FUNC: // fallthrough
		case MCC_BRIDGEBALRESIST_FUNC:
			return "BridgeBalance"
		case MCC_BRIDGEBALENABLE_FUNC:
			return "BridgeBalanceEnable"
		case MCC_NEUTRALIZATIONCAP_FUNC:
			return "CapNeut"
		case MCC_NEUTRALIZATIONENABL_FUNC:
			return "CapNeutEnable"
		// end AmpStorageWave row labels
		// begin others
		case MCC_AUTOWHOLECELLCOMP_FUNC:
			return "WholeCellCap"
		case MCC_RSCOMPBANDWIDTH_FUNC:
			return "RsCompBandWidth"
		case MCC_OSCKILLERENABLE_FUNC:
			return "OscKillerEnable"
		case MCC_AUTOPIPETTEOFFSET_FUNC:
			return "AutoPipetteOffset"
		case MCC_FASTCOMPCAP_FUNC:
			return "FastCompCap"
		case MCC_FASTCOMPTAU_FUNC:
			return "FastCompTau"
		case MCC_SLOWCOMPCAP_FUNC:
			return "SlowCompCap"
		case MCC_SLOWCOMPTAU_FUNC:
			return "SlowCompTau"
		case MCC_SLOWCOMPTAUX20ENAB_FUNC:
			return "SlowCompTauX20"
		case MCC_SLOWCURRENTINJENABL_FUNC:
			return "SlowCurrentInjectEnable"
		case MCC_SLOWCURRENTINJLEVEL_FUNC:
			return "SlowCurrentInjectLevel"
		case MCC_SLOWCURRENTINJSETLT_FUNC:
			return "SlowCurrentInjectSettleTime"
		case MCC_PRIMARYSIGNALGAIN_FUNC:
			return "SetPrimarySignalGain"
		case MCC_SECONDARYSIGNALGAIN_FUNC:
			return "SetSecondaySignalGain"
		case MCC_PRIMARYSIGNALHPF_FUNC:
			return "SetPrimarySignalHPF"
		case MCC_PRIMARYSIGNALLPF_FUNC:
			return "SetPrimarySignalLPF"
		case MCC_SECONDARYSIGNALLPF_FUNC:
			return "SetSecondaySignalLPF"
		case MCC_NO_AMPCHAIN_FUNC:
			return "RSCompChaining"
		case MCC_NO_AUTOBIAS_V_FUNC:
			return "AutoBiasVcom"
		case MCC_NO_AUTOBIAS_VRANGE_FUNC:
			return "AutoBiasVcomVariance"
		case MCC_NO_AUTOBIAS_IBIASMAX_FUNC:
			return "AutoBiasIbiasmax"
		case MCC_NO_AUTOBIAS_ENABLE_FUNC:
			return "AutoBiasEnable"
		// end others
		default:
			FATAL_ERROR("Invalid func: " + num2str(func))
	endswitch
End

/// @brief Map human readable names to functions constants from @ref AI_SendToAmpConstants
threadsafe Function AI_MapNameToFunctionConstant(string name)

	strswitch(name)
		// begin AmpStorageWave row labels
		case "BiasCurrent": // fallthrough
		case "HoldingPotential":
			return MCC_HOLDING_FUNC
		case "BiasCurrentEnable": // fallthrough
		case "HoldingPotentialEnable":
			return MCC_HOLDINGENABLE_FUNC
		case "WholeCellCap":
			return MCC_WHOLECELLCOMPCAP_FUNC
		case "WholeCellRes":
			return MCC_WHOLECELLCOMPRESIST_FUNC
		case "WholeCellEnable":
			return MCC_WHOLECELLCOMPENABLE_FUNC
		case "Correction":
			return MCC_RSCOMPCORRECTION_FUNC
		case "Prediction":
			return MCC_RSCOMPPREDICTION_FUNC
		case "RsCompEnable":
			return MCC_RSCOMPENABLE_FUNC
		case "PipetteOffsetVC": // fallthrough
		case "PipetteOffsetIC":
			return MCC_PIPETTEOFFSET_FUNC
		case "FastCapacitanceComp":
			return MCC_AUTOFASTCOMP_FUNC
		case "SlowCapacitanceComp":
			return MCC_AUTOSLOWCOMP_FUNC
		case "BridgeBalance":
			return MCC_BRIDGEBALRESIST_FUNC
		case "BridgeBalanceEnable":
			return MCC_BRIDGEBALENABLE_FUNC
		case "CapNeut":
			return MCC_NEUTRALIZATIONCAP_FUNC
		case "CapNeutEnable":
			return MCC_NEUTRALIZATIONENABL_FUNC
		// end AmpStorageWave row labels
		// begin others
		case "RsCompBandWidth":
			return MCC_RSCOMPBANDWIDTH_FUNC
		case "OscKillerEnable":
			return MCC_OSCKILLERENABLE_FUNC
		case "AutoPipetteOffset":
			return MCC_AUTOPIPETTEOFFSET_FUNC
		case "FastCompCap":
			return MCC_FASTCOMPCAP_FUNC
		case "FastCompTau":
			return MCC_FASTCOMPTAU_FUNC
		case "SlowCompCap":
			return MCC_SLOWCOMPCAP_FUNC
		case "SlowCompTau":
			return MCC_SLOWCOMPTAU_FUNC
		case "SlowCompTauX20":
			return MCC_SLOWCOMPTAUX20ENAB_FUNC
		case "SlowCurrentInjectEnable":
			return MCC_SLOWCURRENTINJENABL_FUNC
		case "SlowCurrentInjectLevel":
			return MCC_SLOWCURRENTINJLEVEL_FUNC
		case "SlowCurrentInjectSettleTime":
			return MCC_SLOWCURRENTINJSETLT_FUNC
		case "SetPrimarySignalGain":
			return MCC_PRIMARYSIGNALGAIN_FUNC
		case "SetSecondaySignalGain":
			return MCC_SECONDARYSIGNALGAIN_FUNC
		case "SetPrimarySignalHPF":
			return MCC_PRIMARYSIGNALHPF_FUNC
		case "SetPrimarySignalLPF":
			return MCC_PRIMARYSIGNALLPF_FUNC
		case "SetSecondaySignalLPF":
			return MCC_SECONDARYSIGNALLPF_FUNC
		case "RSCompChaining":
			return MCC_NO_AMPCHAIN_FUNC
		case "AutoBiasVcom":
			return MCC_NO_AUTOBIAS_V_FUNC
		case "AutoBiasVcomVariance":
			return MCC_NO_AUTOBIAS_VRANGE_FUNC
		case "AutoBiasIbiasmax":
			return MCC_NO_AUTOBIAS_IBIASMAX_FUNC
		case "AutoBiasEnable":
			return MCC_NO_AUTOBIAS_ENABLE_FUNC
		// end others
		default:
			FATAL_ERROR("Invalid name: " + name)
	endswitch
End

/// @brief Return the truthness that the ctrl belongs to the clamp mode
Function AI_IsControlFromClampMode(string ctrl, variable clampMode)

	string list

	switch(clampMode)
		case V_CLAMP_MODE:
			list = AMPLIFIER_CONTROLS_VC
			break
		case I_CLAMP_MODE: // fallthrough
		case I_EQUAL_ZERO_MODE:
			list = AMPLIFIER_CONTROLS_IC
			break
		default:
			FATAL_ERROR("Invalid clamp mode")
	endswitch

	return WhichListItem(ctrl, list, ";", 0, 0) >= 0
End

/// @brief Convert amplifier controls to row labels for `AmpStorageWave`
static Function/S AI_AmpStorageControlToRowLabel(string ctrl)

	strswitch(ctrl)
		// V-Clamp controls
		case "setvar_DataAcq_Hold_VC":
			return "HoldingPotential"
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
		case "button_DataAcq_WCAuto":
			return "WholeCellCap"
			break
		case "button_DataAcq_AutoBridgeBal_IC": // fallthrough
		case "button_DataAcq_AutoPipOffset_IC": // fallthrough
		case "button_DataAcq_FastComp_VC": // fallthrough
		case "button_DataAcq_SlowComp_VC": // fallthrough
		case "button_DataAcq_AutoPipOffset_VC":
			// no row exists
			return ""
			break
		default:
			FATAL_ERROR("Unknown control " + ctrl)
			break
	endswitch
End

/// @brief Return the unit with prefix of the given function constant and clampMode
///
/// This uses the MIES internal units i.e. with prefixes.
threadsafe Function/S AI_GetUnitForFunctionConstant(variable func, variable clampMode)

	AI_AssertOnInvalidClampMode(clampMode)

	switch(func)
		// begin AmpStorageWave row labels
		case MCC_HOLDING_FUNC:

			if(clampMode == V_CLAMP_MODE)
				return "mV"
			endif

			return "pA"
		case MCC_HOLDINGENABLE_FUNC:
			return "On/Off"
		case MCC_WHOLECELLCOMPCAP_FUNC:
			return "pF"
		case MCC_WHOLECELLCOMPRESIST_FUNC:
			return "MΩ"
		case MCC_WHOLECELLCOMPENABLE_FUNC:
			return "On/Off"
		case MCC_RSCOMPCORRECTION_FUNC:
			return "%"
		case MCC_RSCOMPPREDICTION_FUNC:
			return "%"
		case MCC_RSCOMPENABLE_FUNC:
			return "On/Off"
		case MCC_PIPETTEOFFSET_FUNC:
			return "mV"
		case MCC_AUTOFASTCOMP_FUNC:
			return "a.u."
		case MCC_AUTOSLOWCOMP_FUNC:
			return "a.u."
		case MCC_AUTOBRIDGEBALANCE_FUNC:
			return "a.u."
		case MCC_BRIDGEBALRESIST_FUNC:
			return "MΩ"
		case MCC_BRIDGEBALENABLE_FUNC:
			return "On/Off"
		case MCC_NEUTRALIZATIONCAP_FUNC:
			return "pF"
		case MCC_NEUTRALIZATIONENABL_FUNC:
			return "On/Off"
		// end AmpStorageWave row labels
		// begin others
		case MCC_AUTOWHOLECELLCOMP_FUNC:
			return "a.u."
		case MCC_RSCOMPBANDWIDTH_FUNC:
			return "kHz"
		case MCC_OSCKILLERENABLE_FUNC:
			return "On/Off"
		case MCC_AUTOPIPETTEOFFSET_FUNC:
			return "a.u."
		case MCC_FASTCOMPCAP_FUNC:
			return "pF"
		case MCC_FASTCOMPTAU_FUNC:
			return "μs"
		case MCC_SLOWCOMPCAP_FUNC:
			return "pF"
		case MCC_SLOWCOMPTAU_FUNC:
			return "μs"
		case MCC_SLOWCOMPTAUX20ENAB_FUNC:
			return "On/Off"
		case MCC_SLOWCURRENTINJENABL_FUNC:
			return "On/Off"
		case MCC_SLOWCURRENTINJLEVEL_FUNC:
			return "mV"
		case MCC_SLOWCURRENTINJSETLT_FUNC:
			return "ms"
		case MCC_PRIMARYSIGNALGAIN_FUNC:
			return "a.u."
		case MCC_SECONDARYSIGNALGAIN_FUNC:
			return "a.u."
		case MCC_PRIMARYSIGNALHPF_FUNC:
			return "kHz"
		case MCC_PRIMARYSIGNALLPF_FUNC:
			return "kHz"
		case MCC_SECONDARYSIGNALLPF_FUNC:
			return "kHz"
		case MCC_NO_AMPCHAIN_FUNC:
			return "On/Off"
		case MCC_NO_AUTOBIAS_V_FUNC:
			return "mV"
		case MCC_NO_AUTOBIAS_VRANGE_FUNC:
			return "mV"
		case MCC_NO_AUTOBIAS_IBIASMAX_FUNC:
			return "pA"
		case MCC_NO_AUTOBIAS_ENABLE_FUNC:
			return "On/Off"
		// end others
		default:
			FATAL_ERROR("Invalid func: " + num2str(func))
	endswitch
End

/// @brief Return a wave with all function constants for the given clamp mode
threadsafe Function/WAVE AI_GetFunctionConstantForClampMode(variable clampMode)

	string list, ctrl
	variable func, clampModeRet, numEntries, i

	AI_AssertOnInvalidClampMode(clampMode)

	switch(clampMode)
		case V_CLAMP_MODE:
			list = AMPLIFIER_CONTROLS_VC
			break
		case I_CLAMP_MODE:
			list = AMPLIFIER_CONTROLS_IC
			break
		case I_EQUAL_ZERO_MODE:
			return $""
		default:
			FATAL_ERROR("Invalid clamp mode")
	endswitch

	numEntries = ItemsInList(list)
	Make/FREE/N=(numEntries) funcs
	for(i = 0; i < numEntries; i += 1)
		ctrl                 = StringFromList(i, list)
		[func, clampModeRet] = AI_MapControlNameToFunctionConstant(ctrl)

		ASSERT_TS(clampMode == clampModeRet, "Non-matching clamp mode")

		funcs[i] = func
	endfor

	WAVE uniqueFuncs = GetUniqueEntries(funcs)

	return uniqueFuncs
End

#ifdef AMPLIFIER_XOPS_PRESENT

///@brief Returns the holding command of the amplifier
Function AI_GetHoldingCommand(string device, variable headstage)

	if(AI_SelectMultiClamp(device, headstage) != AMPLIFIER_CONNECTION_SUCCESS)
		return NaN
	endif

	return MCC_GetHoldingEnable() ? (MCC_GetHolding() * AI_GetMCCScale(MCC_GetMode(), MCC_HOLDING_FUNC, MCC_READ)) : 0
End

/// @brief Return the clamp mode of the headstage as returned by the amplifier
///
/// Should only be used during the setup phase when you don't know if the
/// clamp mode in MIES matches already. It is always better to prefer
/// DAP_ChangeHeadStageMode() if possible.
///
/// @brief One of @ref AmplifierClampModes or NaN if no amplifier is connected
Function AI_GetMode(string device, variable headstage)

	if(AI_SelectMultiClamp(device, headstage) != AMPLIFIER_CONNECTION_SUCCESS)
		return NaN
	endif

	return MCC_GetMode()
End

/// @brief Return the DA/AD gains of the given headstage
///
/// Internally we query the External Command Sensitivity of the Amplifier (MCC) GUI.
///
/// =========== ==========================
///  ClampMode   MultiClampCommander GUI
/// =========== ==========================
///  VC          Off
///               20 mV/V
///              100 mV/V
/// =========== ==========================
///  IC          Off
///              400 pA/V
///                2 nA/V
/// =========== ==========================
///
/// Gain is returned in mV/V for #V_CLAMP_MODE and pA/V for #I_CLAMP_MODE/#I_EQUAL_ZERO_MODE
///
/// @param      device device
/// @param      headstage  headstage [0, NUM_HEADSTAGES[
/// @param      clampMode  clamp mode
/// @param[out] ADGain     ADC gain
/// @param[out] DAGain     DAC gain
static Function AI_RetrieveGains(string device, variable headstage, variable clampMode, variable &ADGain, variable &DAGain)

	variable axonSerial = AI_GetAmpAxonSerial(device, headstage)
	variable channel    = AI_GetAmpChannel(device, headStage)

	[STRUCT AxonTelegraph_DataStruct tds] = AI_GetTelegraphStruct(axonSerial, channel)

	ASSERT(clampMode == tds.OperatingMode, "Non matching clamp mode from MCC application")

	ADGain    = tds.ScaleFactor * tds.Alpha / ONE_TO_MILLI
	clampMode = tds.OperatingMode

	if(tds.OperatingMode == V_CLAMP_MODE)
		DAGain = tds.ExtCmdSens * ONE_TO_MILLI
	elseif(tds.OperatingMode == I_CLAMP_MODE || tds.OperatingMode == I_EQUAL_ZERO_MODE)
		DAGain = tds.ExtCmdSens * ONE_TO_PICO
	endif
End

/// @brief Return the opposite clamp mode depending on the current one
static Function AI_GetOppositeClampAmpMode(variable mode)

	if(mode == V_CLAMP_MODE)
		return I_CLAMP_MODE
	elseif(mode == I_CLAMP_MODE || mode == I_EQUAL_ZERO_MODE)
		return V_CLAMP_MODE
	endif

	FATAL_ERROR("Invalid clamp mode: " + num2str(mode))
End

/// @brief Wrapper for MCC_SelectMultiClamp700B
///
/// @param device device
/// @param headStage MIES headstage number, must be in the range [0, NUM_HEADSTAGES]
///
/// @returns one of @ref AISelectMultiClampReturnValues
Function AI_SelectMultiClamp(string device, variable headStage)

	variable channel, axonSerial, err
	string mccSerial

	// checking axonSerial is done as a service to the caller
	axonSerial = AI_GetAmpAxonSerial(device, headStage)
	mccSerial  = AI_GetAmpMCCSerial(device, headStage)
	channel    = AI_GetAmpChannel(device, headStage)

	if(!AI_IsValidSerialAndChannel(mccSerial = mccSerial, axonSerial = axonSerial, channel = channel))
		return AMPLIFIER_CONNECTION_INVAL_SER
	endif

	AssertOnAndClearRTError()
	MCC_SelectMultiClamp700B(mccSerial, channel); err = GetRTError(1) // see developer docu section Preventing Debugger Popup

	if(err)
		return AMPLIFIER_CONNECTION_MCC_FAILED
	endif

	return AMPLIFIER_CONNECTION_SUCCESS
End

/// @brief Set the clamp mode of user linked MCC based on the headstage number
Function AI_SetClampMode(string device, variable headStage, variable mode, [variable zeroStep, variable selectAmp])

	if(ParamIsDefault(zeroStep))
		zeroStep = 0
	else
		zeroStep = !!zeroStep
	endif

	if(ParamIsDefault(selectAmp))
		selectAmp = 1
	else
		selectAmp = !!selectAmp
	endif

	AI_AssertOnInvalidClampMode(mode)

	if(selectAmp)
		if(AI_SelectMultiClamp(device, headStage) != AMPLIFIER_CONNECTION_SUCCESS)
			return NaN
		endif
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

/// @brief Write to the amplifier
///
/// @param device           device
/// @param headStage        MIES headstage number, must be in the range [0, NUM_HEADSTAGES[
/// @param mode             One of V_CLAMP_MODE, I_CLAMP_MODE or I_EQUAL_ZERO_MODE
/// @param func             Function to call, see @ref AI_SendToAmpConstants
/// @param value            value to set. values is in MIES units, see AI_SendToAmp() and there the description of `usePrefixes`
/// @param sendToAll        [optional: defaults to the state of the checkbox] should the value be send
///                         to all active headstages (true) or just to the given one (false)
/// @param checkBeforeWrite [optional, defaults to false] (ignored for getter functions)
///                         check the current value and do nothing if it is equal within some tolerance to the one written
/// @param selectAmp        [optional, defaults to true] Select the amplifier
///                         before use, some callers might save time in doing that once themselves.
/// @param GUIWrite         [optional, defaults to false] Should the amplifier control, if available, be updated with the value
///
/// @return 0 on success, 1 otherwise
Function AI_WriteToAmplifier(string device, variable headStage, variable mode, variable func, variable value, [variable sendToAll, variable checkBeforeWrite, variable selectAmp, variable GUIWrite])

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

	if(ParamIsDefault(GUIWrite))
		GUIWrite = 1
	else
		GUIWrite = !!GUIWrite
	endif

	if(ParamIsDefault(sendToAll))
		return AI_UpdateAmpModel(device, headStage, clampMode = mode, func = func, value = value, checkBeforeWrite = checkBeforeWrite, selectAmp = selectAmp, GUIWrite = GUIWrite)
	endif

	return AI_UpdateAmpModel(device, headStage, clampMode = mode, func = func, value = value, checkBeforeWrite = checkBeforeWrite, selectAmp = selectAmp, GUIWrite = GUIWrite, sendToAll = !!sendToAll)
End

/// @brief Read from amplifier
///
/// @param device           device
/// @param headStage        MIES headstage number, must be in the range [0, NUM_HEADSTAGES[
/// @param mode             One of V_CLAMP_MODE, I_CLAMP_MODE or I_EQUAL_ZERO_MODE
/// @param func             Function to call, see @ref AI_SendToAmpConstants
/// @param value            value to set. values is in MIES units, see AI_SendToAmp() and there the description of `usePrefixes`
/// @param usePrefixes      [optional, defaults to true] Use SI-prefixes common in MIES for the passed and returned values, e.g.
///                         `mV` instead of `V`
/// @param selectAmp        [optional, defaults to true] Select the amplifier
///                         before use, some callers might save time in doing that once themselves.
/// @return 0 on success, 1 otherwise
Function AI_ReadFromAmplifier(string device, variable headStage, variable mode, variable func, [variable usePrefixes, variable selectAmp])

	if(ParamIsDefault(selectAmp))
		selectAmp = 1
	else
		selectAmp = !!selectAmp
	endif

	if(ParamIsdefault(usePrefixes))
		return AI_SendToAmp(device, headStage, mode, func, MCC_READ, selectAmp = selectAmp)
	endif

	return AI_SendToAmp(device, headStage, mode, func, MCC_READ, usePrefixes = usePrefixes, selectAmp = selectAmp)
End

/// @brief Generic interface to call MCC amplifier functions
///
/// @param device           locked panel name to work on
/// @param headStage        MIES headstage number, must be in the range [0, NUM_HEADSTAGES]
/// @param mode             one of V_CLAMP_MODE, I_CLAMP_MODE or I_EQUAL_ZERO_MODE
/// @param func             Function to call, see @ref AI_SendToAmpConstants
/// @param accessType       One of @ref MCCAccessType
/// @param checkBeforeWrite [optional, defaults to false] (ignored for getter functions)
///                         check the current value and do nothing if it is equal within some tolerance to the one written
/// @param usePrefixes      [optional, defaults to true] Use SI-prefixes common in MIES for the passed and returned values, e.g.
///                         `mV` instead of `V`
/// @param selectAmp        [optional, defaults to true] Select the amplifier
///                         before use, some callers might save time in doing that once themselves.
/// @param value            [optional] Required for writers, must be left out for readers
///
/// @returns return value (for getters, respects `usePrefixes`), success (`0`) or error (`NaN`).
static Function AI_SendToAmp(string device, variable headStage, variable mode, variable func, variable accessType, [variable checkBeforeWrite, variable usePrefixes, variable selectAmp, variable value])

	variable ret, headstageMode, scale, nonScaledValue
	string str

	ASSERT(func > MCC_BEGIN_INVALID_FUNC && func < MCC_END_INVALID_FUNC, "MCC function constant is out for range")
	ASSERT(IsValidHeadstage(headstage), "invalid headStage index")
	AI_AssertOnInvalidClampMode(mode)
	AI_AssertOnInvalidAccessType(accessType)

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
		scale = AI_GetMCCScale(mode, func, accessType)
	else
		scale = 1
	endif

	if(accessType == MCC_READ)
		ASSERT(ParamIsDefault(value), "Can't pass value for reading")
		ASSERT(!checkBeforeWrite, "Can't use checkBeforeWrite for reading")
	elseif(accessType == MCC_WRITE)
		ASSERT(!ParamIsDefault(value), "Value is required for writing")
	else
		FATAL_ERROR("Impossible case")
	endif

	headstageMode = DAG_GetHeadstageMode(device, headStage)

	if(headstageMode != mode)
		return NaN
	endif

	if(selectAmp)
		if(AI_SelectMultiClamp(device, headstage) != AMPLIFIER_CONNECTION_SUCCESS)
			return NaN
		endif
	endif

	AI_EnsureCorrectMode(device, headStage, selectAmp = 0)

	sprintf str, "headStage=%d, mode=%d, func=%d, value(passed)=%g, scale=%g\r", headStage, mode, func, value, scale
	DEBUGPRINT(str)

	nonScaledValue = value
	value         *= scale

	if(checkBeforeWrite)
		ret = AI_ReadFromMCC(func)

		// Don't send the value if it is equal to the current value, with tolerance
		// being 1% of the reference value, or if it is zero and the current value is
		// smaller than 1e-12.
		if(CheckIfClose(ret, value, tol = 1e-2 * abs(ret), strong_or_weak = 1) || (value == 0 && CheckIfSmall(ret, tol = 1e-12)))
			DEBUGPRINT("The value to be set is equal to the current value, skip setting it: " + num2str(func))
			return 0
		endif
	endif

	switch(func)
		case MCC_AUTOBRIDGEBALANCE_FUNC:
			AI_WriteToMCC(func, NaN)
			ret = AI_SendToAmp(device, headstage, mode, MCC_BRIDGEBALRESIST_FUNC, MCC_READ, selectAmp = 0)
			PUB_AutoBridgeBalance(device, headstage, ret)
			break
		case MCC_AUTOPIPETTEOFFSET_FUNC:
			AI_WriteToMCC(func, NaN)
			ret = AI_SendToAmp(device, headStage, mode, MCC_PIPETTEOFFSET_FUNC, MCC_READ, selectAmp = 0)
			break
		default:
			if(accessType == MCC_READ)
				ret = AI_ReadFromMCC(func)
			else
				ret = AI_WriteToMCC(func, value)
			endif
			break
	endswitch

	if(accessType == MCC_WRITE)
		PUB_AmplifierSettingChange(device, headstage, mode, func, nonScaledValue)
	endif

	if(!IsFinite(ret))
		print "Amp communication error. Check associations in hardware tab and/or use Query connected amps button"
		ControlWindowToFront()
	endif

	return ret * scale
End

static Function AI_ReadFromMCC(variable func)

	switch(func)
		case MCC_AUTOWHOLECELLCOMP_FUNC: // fallthrough
		case MCC_AUTOFASTCOMP_FUNC: // fallthrough
		case MCC_AUTOSLOWCOMP_FUNC:
			return 0
		case MCC_HOLDING_FUNC:
			return MCC_Getholding()
		case MCC_HOLDINGENABLE_FUNC:
			return MCC_GetholdingEnable()
		case MCC_BRIDGEBALENABLE_FUNC:
			return MCC_GetBridgeBalEnable()
		case MCC_BRIDGEBALRESIST_FUNC:
			return MCC_GetBridgeBalResist()
		case MCC_NEUTRALIZATIONENABL_FUNC:
			return MCC_GetNeutralizationEnable()
		case MCC_NEUTRALIZATIONCAP_FUNC:
			return MCC_GetNeutralizationCap()
		case MCC_WHOLECELLCOMPENABLE_FUNC:
			return MCC_GetWholeCellCompEnable()
		case MCC_WHOLECELLCOMPCAP_FUNC:
			return MCC_GetWholeCellCompCap()
		case MCC_WHOLECELLCOMPRESIST_FUNC:
			return MCC_GetWholeCellCompResist()
		case MCC_RSCOMPENABLE_FUNC:
			return MCC_GetRsCompEnable()
		case MCC_RSCOMPBANDWIDTH_FUNC:
			return MCC_GetRsCompBandwidth()
		case MCC_RSCOMPCORRECTION_FUNC:
			return MCC_GetRsCompCorrection()
		case MCC_RSCOMPPREDICTION_FUNC:
			return MCC_GetRsCompPrediction()
		case MCC_OSCKILLERENABLE_FUNC:
			return MCC_GetOscKillerEnable()
		case MCC_PIPETTEOFFSET_FUNC:
			return MCC_GetPipetteOffset()
		case MCC_FASTCOMPCAP_FUNC:
			return MCC_GetFastCompCap()
		case MCC_SLOWCOMPCAP_FUNC:
			return MCC_GetSlowCompCap()
		case MCC_FASTCOMPTAU_FUNC:
			return MCC_GetFastCompTau()
		case MCC_SLOWCOMPTAU_FUNC:
			return MCC_GetSlowCompTau()
		case MCC_SLOWCOMPTAUX20ENAB_FUNC:
			return MCC_GetSlowCompTauX20Enable()
		case MCC_SLOWCURRENTINJENABL_FUNC:
			return MCC_GetSlowCurrentInjEnable()
		case MCC_SLOWCURRENTINJLEVEL_FUNC:
			return MCC_GetSlowCurrentInjLevel()
		case MCC_SLOWCURRENTINJSETLT_FUNC:
			return MCC_GetSlowCurrentInjSetlTime()
		case MCC_PRIMARYSIGNALGAIN_FUNC:
			return MCC_GetPrimarySignalGain()
		case MCC_SECONDARYSIGNALGAIN_FUNC:
			return MCC_GetSecondarySignalGain()
		case MCC_PRIMARYSIGNALHPF_FUNC:
			return MCC_GetPrimarySignalHPF()
		case MCC_PRIMARYSIGNALLPF_FUNC:
			return MCC_GetPrimarySignalLPF()
		case MCC_SECONDARYSIGNALLPF_FUNC:
			return MCC_GetSecondarySignalLPF()
		default:
			FATAL_ERROR("Invalid func: " + num2str(func))
			break
	endswitch
End

static Function AI_WriteToMCC(variable func, variable value)

	switch(func)
		case MCC_AUTOWHOLECELLCOMP_FUNC:
			return MCC_AutowholeCellComp()
		case MCC_AUTOFASTCOMP_FUNC:
			return MCC_AutoFastComp()
		case MCC_AUTOSLOWCOMP_FUNC:
			return MCC_AutoSlowComp()
		case MCC_HOLDING_FUNC:
			return MCC_Setholding(value)
		case MCC_HOLDINGENABLE_FUNC:
			return MCC_SetholdingEnable(value)
		case MCC_BRIDGEBALENABLE_FUNC:
			return MCC_SetBridgeBalEnable(value)
		case MCC_BRIDGEBALRESIST_FUNC:
			return MCC_SetBridgeBalResist(value)
		case MCC_NEUTRALIZATIONENABL_FUNC:
			return MCC_SetNeutralizationEnable(value)
		case MCC_NEUTRALIZATIONCAP_FUNC:
			return MCC_SetNeutralizationCap(value)
		case MCC_WHOLECELLCOMPENABLE_FUNC:
			return MCC_SetWholeCellCompEnable(value)
		case MCC_WHOLECELLCOMPCAP_FUNC:
			return MCC_SetWholeCellCompCap(value)
		case MCC_WHOLECELLCOMPRESIST_FUNC:
			return MCC_SetWholeCellCompResist(value)
		case MCC_RSCOMPENABLE_FUNC:
			return MCC_SetRsCompEnable(value)
		case MCC_RSCOMPBANDWIDTH_FUNC:
			return MCC_SetRsCompBandwidth(value)
		case MCC_RSCOMPCORRECTION_FUNC:
			return MCC_SetRsCompCorrection(value)
		case MCC_RSCOMPPREDICTION_FUNC:
			return MCC_SetRsCompPrediction(value)
		case MCC_OSCKILLERENABLE_FUNC:
			return MCC_SetOscKillerEnable(value)
		case MCC_PIPETTEOFFSET_FUNC:
			return MCC_SetPipetteOffset(value)
		case MCC_FASTCOMPCAP_FUNC:
			return MCC_SetFastCompCap(value)
		case MCC_SLOWCOMPCAP_FUNC:
			return MCC_SetSlowCompCap(value)
		case MCC_FASTCOMPTAU_FUNC:
			return MCC_SetFastCompTau(value)
		case MCC_SLOWCOMPTAU_FUNC:
			return MCC_SetSlowCompTau(value)
		case MCC_SLOWCOMPTAUX20ENAB_FUNC:
			return MCC_SetSlowCompTauX20Enable(value)
		case MCC_SLOWCURRENTINJENABL_FUNC:
			return MCC_SetSlowCurrentInjEnable(value)
		case MCC_SLOWCURRENTINJLEVEL_FUNC:
			return MCC_SetSlowCurrentInjLevel(value)
		case MCC_SLOWCURRENTINJSETLT_FUNC:
			return MCC_SetSlowCurrentInjSetlTime(value)
		case MCC_PRIMARYSIGNALGAIN_FUNC:
			return MCC_SetPrimarySignalGain(value)
		case MCC_SECONDARYSIGNALGAIN_FUNC:
			return MCC_SetSecondarySignalGain(value)
		case MCC_PRIMARYSIGNALHPF_FUNC:
			return MCC_SetPrimarySignalHPF(value)
		case MCC_PRIMARYSIGNALLPF_FUNC:
			return MCC_SetPrimarySignalLPF(value)
		case MCC_SECONDARYSIGNALLPF_FUNC:
			return MCC_SetSecondarySignalLPF(value)
		case MCC_AUTOBRIDGEBALANCE_FUNC:
			return MCC_AutoBridgeBal()
		case MCC_AUTOPIPETTEOFFSET_FUNC:
			return MCC_AutoPipetteOffset()
		default:
			FATAL_ERROR("Invalid func: " + num2str(func))
			break
	endswitch
End

/// @brief Set the clamp mode in the MCC app to the
///        same clamp mode as MIES has stored.
///
/// @param device device
/// @param headstage  headstage
/// @paran selectAmp  [optional, defaults to false] selects the amplifier
///                   before using, some callers might be able to skip it.
///
/// @return 0 on success, 1 when the headstage does not have an amplifier connected or it could not be selected
Function AI_EnsureCorrectMode(string device, variable headStage, [variable selectAmp])

	variable serial, channel, storedMode, setMode, ampConnectionState

	if(ParamIsDefault(selectAmp))
		selectAmp = 0
	else
		selectAmp = !!selectAmp
	endif

	serial  = AI_GetAmpAxonSerial(device, headStage)
	channel = AI_GetAmpChannel(device, headStage)

	if(!AI_IsValidSerialAndChannel(channel = channel, axonSerial = serial))
		return 1
	endif

	if(selectAmp)
		ampConnectionState = AI_SelectMultiClamp(device, headstage)
		if(ampConnectionState != AMPLIFIER_CONNECTION_SUCCESS)
			return 1
		endif
	endif

	[STRUCT AxonTelegraph_DataStruct tds] = AI_GetTelegraphStruct(serial, channel)

	storedMode = DAG_GetHeadstageMode(device, headStage)
	setMode    = tds.operatingMode

	if(setMode != storedMode)
		print "There was a mismatch in clamp mode between MIES and the MCC. The MCC mode was switched to match the mode specified by MIES."
		AI_SetClampMode(device, headStage, storedMode)
	endif

	return 0
End

/// @brief Fill the amplifier settings wave by querying the MC700B and send the data to ED_AddEntriesToLabnotebook
///
/// @param device 		 device
/// @param sweepNo           data wave sweep number
Function AI_FillAndSendAmpliferSettings(string device, variable sweepNo)

	variable i, axonSerial, channel, ampConnState, clampMode
	string mccSerial

	WAVE   statusHS            = DAG_GetChannelState(device, CHANNEL_TYPE_HEADSTAGE)
	WAVE   ampSettingsWave     = GetAmplifierSettingsWave()
	WAVE/T ampSettingsKey      = GetAmplifierSettingsKeyWave()
	WAVE/T ampSettingsTextWave = GetAmplifierSettingsTextWave()
	WAVE/T ampSettingsTextKey  = GetAmplifierSettingsTextKeyWave()
	WAVE   ampParamStorage     = GetAmplifierParamStorageWave(device)

	for(i = 0; i < NUM_HEADSTAGES; i += 1)

		if(!statusHS[i])
			continue
		endif

		mccSerial  = AI_GetAmpMCCSerial(device, i)
		axonSerial = AI_GetAmpAxonSerial(device, i)
		channel    = AI_GetAmpChannel(device, i)

		ampConnState = AI_SelectMultiClamp(device, i)

		if(ampConnState != AMPLIFIER_CONNECTION_SUCCESS)
			if(DAG_GetNumericalValue(device, "check_Settings_RequireAmpConn"))
				BUG("The amplifier could not be selected, but that should work, ampConnState = " + num2str(ampConnState))
				BUG("Please report that as a bug with a description what you did. Thanks!")
			endif
			continue
		endif

		clampMode = DAG_GetHeadstageMode(device, i)
		AI_AssertOnInvalidClampMode(clampMode)

		[STRUCT AxonTelegraph_DataStruct tds] = AI_GetTelegraphStruct(axonSerial, channel)

		ASSERT(clampMode == tds.OperatingMode, "A clamp mode mismatch was detected. Please describe the events leading up to that assertion. Thanks!")

		if(clampMode == V_CLAMP_MODE)
			ampSettingsWave[0][0][i]  = MCC_GetHoldingEnable()
			ampSettingsWave[0][1][i]  = MCC_GetHolding() * AI_GetMCCScale(V_CLAMP_MODE, MCC_HOLDING_FUNC, MCC_READ)
			ampSettingsWave[0][2][i]  = MCC_GetOscKillerEnable()
			ampSettingsWave[0][3][i]  = MCC_GetRsCompBandwidth() * AI_GetMCCScale(V_CLAMP_MODE, MCC_RSCOMPBANDWIDTH_FUNC, MCC_READ)
			ampSettingsWave[0][4][i]  = MCC_GetRsCompCorrection()
			ampSettingsWave[0][5][i]  = MCC_GetRsCompEnable()
			ampSettingsWave[0][6][i]  = MCC_GetRsCompPrediction()
			ampSettingsWave[0][7][i]  = MCC_GetWholeCellCompEnable()
			ampSettingsWave[0][8][i]  = MCC_GetWholeCellCompCap() * AI_GetMCCScale(V_CLAMP_MODE, MCC_WHOLECELLCOMPCAP_FUNC, MCC_READ)
			ampSettingsWave[0][9][i]  = MCC_GetWholeCellCompResist() * AI_GetMCCScale(V_CLAMP_MODE, MCC_WHOLECELLCOMPRESIST_FUNC, MCC_READ)
			ampSettingsWave[0][39][i] = MCC_GetFastCompCap()
			ampSettingsWave[0][40][i] = MCC_GetSlowCompCap()
			ampSettingsWave[0][41][i] = MCC_GetFastCompTau()
			ampSettingsWave[0][42][i] = MCC_GetSlowCompTau()
		elseif(clampMode == I_CLAMP_MODE || clampMode == I_EQUAL_ZERO_MODE)
			ampSettingsWave[0][10][i] = MCC_GetHoldingEnable()
			ampSettingsWave[0][11][i] = MCC_GetHolding() * AI_GetMCCScale(I_CLAMP_MODE, MCC_HOLDING_FUNC, MCC_READ)
			ampSettingsWave[0][12][i] = MCC_GetNeutralizationEnable()
			ampSettingsWave[0][13][i] = MCC_GetNeutralizationCap() * AI_GetMCCScale(I_CLAMP_MODE, MCC_NEUTRALIZATIONCAP_FUNC, MCC_READ)
			ampSettingsWave[0][14][i] = MCC_GetBridgeBalEnable()
			ampSettingsWave[0][15][i] = MCC_GetBridgeBalResist() * AI_GetMCCScale(I_CLAMP_MODE, MCC_BRIDGEBALRESIST_FUNC, MCC_READ)
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
		ampSettingsWave[0][26][i] = tds.MembraneCap * ONE_TO_PICO      // converts F to pF
		ampSettingsWave[0][27][i] = tds.ExtCmdSens
		ampSettingsWave[0][28][i] = tds.RawOutSignal
		ampSettingsWave[0][29][i] = tds.RawScaleFactor
		ampSettingsWave[0][30][i] = tds.RawScaleFactorUnits
		ampSettingsWave[0][31][i] = tds.HardwareType
		ampSettingsWave[0][32][i] = tds.SecondaryAlpha
		ampSettingsWave[0][33][i] = tds.SecondaryLPFCutoff
		ampSettingsWave[0][34][i] = tds.SeriesResistance * ONE_TO_MEGA // converts Ω to MΩ

		ampSettingsTextWave[0][0][i] = tds.OperatingModeString
		ampSettingsTextWave[0][1][i] = tds.ScaledOutSignalString
		ampSettingsTextWave[0][2][i] = tds.ScaleFactorUnitsString
		ampSettingsTextWave[0][3][i] = tds.RawOutSignalString
		ampSettingsTextWave[0][4][i] = tds.RawScaleFactorUnitsString
		ampSettingsTextWave[0][5][i] = tds.HardwareTypeString

		// new parameters
		ampSettingsWave[0][35][i] = MCC_GetPipetteOffset() * AI_GetMCCScale(NaN, MCC_PIPETTEOFFSET_FUNC, MCC_READ)
	endfor

	ED_AddEntriesToLabnotebook(ampSettingsWave, ampSettingsKey, sweepNo, device, DATA_ACQUISITION_MODE)
	ED_AddEntriesToLabnotebook(ampSettingsTextWave, ampSettingsTextKey, sweepNo, device, DATA_ACQUISITION_MODE)
End

/// @brief Auto fills the units and gains for all headstages connected to amplifiers
/// by querying the MCC application
///
/// The data is inserted into `ChanAmpAssign` and `ChanAmpAssignUnit`
///
/// @return number of connected amplifiers
Function AI_QueryGainsFromMCC(string device)

	variable clampMode, old_ClampMode, i, numConnAmplifiers
	variable DAGain, ADGain
	string DAUnit, ADUnit

	for(i = 0; i < NUM_HEADSTAGES; i += 1)

		if(AI_SelectMultiClamp(device, i) != AMPLIFIER_CONNECTION_SUCCESS)
			continue
		endif

		numConnAmplifiers += 1

		clampMode = DAG_GetHeadstageMode(device, i)

		DAP_ChangeHeadStageMode(device, clampMode, i, MCC_SKIP_UPDATES)

		AI_AssertOnInvalidClampMode(clampMode)

		AI_QueryGainsUnitsForClampMode(device, i, clampMode, DAGain, ADGain, DAUnit, ADUnit)
		AI_UpdateChanAmpAssign(device, i, clampMode, DAGain, ADGain, DAUnit, ADUnit)

		AI_WriteToAmplifier(device, i, clampMode, MCC_HOLDINGENABLE_FUNC, 0, selectAmp = 0)

		old_clampMode = clampMode
		clampMode     = AI_GetOppositeClampAmpMode(old_clampMode)

		DAP_ChangeHeadStageMode(device, clampMode, i, MCC_SKIP_UPDATES)

		AI_QueryGainsUnitsForClampMode(device, i, clampMode, DAGain, ADGain, DAUnit, ADUnit)
		AI_UpdateChanAmpAssign(device, i, clampMode, DAGain, ADGain, DAUnit, ADUnit)

		AI_WriteToAmplifier(device, i, clampMode, MCC_HOLDINGENABLE_FUNC, 0, selectAmp = 0)

		DAP_ChangeHeadStageMode(device, old_clampMode, i, MCC_SKIP_UPDATES)
	endfor

	return numConnAmplifiers
End

Function AI_FindConnectedAmps([variable rescanHardware])

	string key

	if(ParamIsDefault(rescanHardware))
		rescanHardware = 0
	else
		rescanHardware = !!rescanHardware
	endif

	key = CA_AmplifierHardwareWavesKey()

	if(rescanHardware)
		IH_RemoveAmplifierConnWaves()
		CA_DeleteCacheEntry(key)
	endif

	WAVE telegraphServers = GetAmplifierTelegraphServers()
	WAVE ampMCC           = GetAmplifierMultiClamps()

	if(DimSize(telegraphServers, ROWS) == 0 || DimSize(ampMCC, ROWS) == 0)

		WAVE/Z/WAVE cache = CA_TryFetchingEntryFromCache(key)

		if(WaveExists(cache))
			Duplicate/O cache[0], telegraphServers
			Duplicate/O cache[1], ampMCC
		else
			[WAVE telegraphServers, WAVE ampMCC] = AI_FindConnectedAmpsNoCache()

			Make/FREE/WAVE cache = {telegraphServers, ampMCC}

			CA_StoreEntryIntoCache(key, cache)
		endif
	endif
End

/// @brief Create the amplifier connection waves
static Function [WAVE telegraphServers, WAVE ampMCC] AI_FindConnectedAmpsNoCache()

	string list

	IH_RemoveAmplifierConnWaves()

	DFREF saveDFR = GetDataFolderDFR()
	SetDataFolder GetAmplifierFolder()

	AxonTelegraphFindServers
	WAVE telegraphServers = GetAmplifierTelegraphServers()
	SortColumns/DIML/KNDX={0, 1} sortWaves={telegraphServers}

	MCC_FindServers/Z=1
	WAVE ampMCC = GetAmplifierMultiClamps()

	SetDataFolder saveDFR

	list = DAP_FormatTelegraphServerList(telegraphServers)

	if(IsEmpty(list))
		print "Activate Multiclamp Commander software to populate list of available amplifiers"
		ControlWindowToFront()
	endif

	LOG_AddEntry(PACKAGE_MIES, "amplifiers", keys = {"list"}, values = {list})

	return [telegraphServers, ampMCC]
End

Function [STRUCT AxonTelegraph_DataStruct tds] AI_GetTelegraphStruct(variable axonSerial, variable channel)

	variable i, err
	string errMsg

	AI_InitAxonTelegraphStruct(tds)

	for(i = 0; i < NUM_TRIES_AXON_TELEGRAPH; i += 1)

		try
			AssertOnAndClearRTError()
			AxonTelegraphGetDataStruct(axonSerial, channel, 1, tds); AbortOnRTE

			return [tds]
		catch
			errMsg = GetRTErrMessage()
			err    = GetRTError(1)

			LOG_AddEntry(PACKAGE_MIES, "querying amplifier failed", \
			             stacktrace = 1,                            \
			             keys = {"error code", "error message"},    \
			             values = {num2str(err), errMsg})

			Sleep/S 0.1
		endtry
	endfor

	FATAL_ERROR("Could not query amplifier")
End

#else // AMPLIFIER_XOPS_PRESENT

Function AI_GetHoldingCommand(string device, variable headstage)

	DEBUGPRINT("Unimplemented")
End

Function AI_GetMode(string device, variable headstage)

	DEBUGPRINT("Unimplemented")
End

static Function AI_RetrieveGains(string device, variable headstage, variable clampMode, variable &ADGain, variable &DAGain)

	ADGain = NaN
	DAGain = NaN

	DEBUGPRINT("Unimplemented")
End

static Function AI_GetOppositeClampAmpMode(variable mode)

	DEBUGPRINT("Unimplemented")
End

Function AI_SelectMultiClamp(string device, variable headStage)

	DEBUGPRINT("Unimplemented")
End

Function AI_SetClampMode(string device, variable headStage, variable mode, [variable zeroStep, variable selectAmp])

	DEBUGPRINT("Unimplemented")
End

Function AI_ReadFromAmplifier(string device, variable headStage, variable mode, variable func, [variable checkBeforeWrite, variable usePrefixes, variable selectAmp])

	DEBUGPRINT("Unimplemented")
End

Function AI_WriteToAmplifier(string device, variable headStage, variable mode, variable func, variable value, [variable sendToAll, variable checkBeforeWrite, variable selectAmp, variable GUIWrite])

	DEBUGPRINT("Unimplemented")
End

static Function AI_SendToAmp(string device, variable headStage, variable mode, variable func, variable accessType, [variable checkBeforeWrite, variable usePrefixes, variable selectAmp, variable value])

	DEBUGPRINT("Unimplemented")
End

Function AI_EnsureCorrectMode(string device, variable headStage, [variable selectAmp])

	DEBUGPRINT("Unimplemented")
End

Function AI_FillAndSendAmpliferSettings(string device, variable sweepNo)

	DEBUGPRINT("Unimplemented")
End

Function AI_QueryGainsFromMCC(string device)

	DEBUGPRINT("Unimplemented")
End

Function AI_FindConnectedAmps([variable rescanHardware])

	DEBUGPRINT("Unimplemented")
End

Function [STRUCT AxonTelegraph_DataStruct tds] AI_GetTelegraphStruct(variable axonSerial, variable channel)

	DEBUGPRINT("Unimplemented")
End
#endif // AMPLIFIER_XOPS_PRESENT
