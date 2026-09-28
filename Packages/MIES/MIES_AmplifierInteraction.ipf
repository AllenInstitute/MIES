#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors = 1

#ifdef AUTOMATED_TESTING
#pragma ModuleName = MIES_AI
#endif // AUTOMATED_TESTING

/// @file MIES_AmplifierInteraction.ipf
/// @brief __AI__ Interface with headstage amplifiers

static Constant ZERO_TOLERANCE = 100 // pA

static Constant MAX_PIPETTEOFFSET = 150 // mV
static Constant MIN_PIPETTEOFFSET = -150

/// @brief Convenience wrapper for #AI_UpdateAmpView
///
/// Disallows setting single controls for outside callers as #AI_WriteToAmplifier should be used for that.
Function AI_SyncAmpStorageToGUI(string device, variable headstage)

	PerformSubsystemEntry()

	return AI_UpdateAmpView(device, headstage)
End

/// @brief Sync the settings from the GUI to the amp storage wave and the amplifier
///
/// @param device    device
/// @param headStage MIES headstage number, must be in the range [0, NUM_HEADSTAGES[
/// @param clampMode clamp mode
/// @param force     [optional, defaults to false] write all values instead of only the changed ones
Function AI_SyncGUIToAmpStorageAndMCCApp(string device, variable headStage, variable clampMode, [variable force])

	string ctrl, list
	variable i, numEntries, value, checkBeforeWrite

	PerformSubsystemEntry()

	force = ParamIsDefault(force) ? 0 : !!force

	DAP_AbortIfUnlocked(device)
	AI_AssertOnInvalidClampMode(clampMode)

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
///
/// Only intended to be called from the amplifier specific implementations, outside callers
/// should use AI_SyncAmpStorageToGUI() or AI_WriteToAmplifier().
Function AI_UpdateAmpView(string device, variable headStage, [variable func, variable clampMode])

	string lbl, list, ctrl
	variable i, numEntries, value

	PerformSubsystemEntry()

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
		else
			FATAL_ERROR("Unhandled control: " + ctrl)
		endif
	endfor
End

static Function AI_SetMIESHeadstage(string device, [variable headstage, variable increment])

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

/// @brief Executes auto zero command if the baseline current exceeds the tolerance
///
/// @param device    device
/// @param headStage [optional: defaults to all active headstages]
Function AI_ZeroAmps(string device, [variable headStage])

	variable i

	PerformSubsystemEntry()

	if(ParamIsDefault(headStage))
		headStage = NaN
	endif

	// Ensure that data in BaselineSSAvg is up to date by verifying that TP is active
	if(IsDeviceActiveWithBGTask(device, "TestPulse") || IsDeviceActiveWithBGTask(device, "TestPulseMD"))

		WAVE TPResults = GetTPResults(device)
		if(IsValidHeadstage(headstage))
			if(abs(TPResults[%BaselineSteadyState][headstage]) >= ZERO_TOLERANCE)
				AI_MIESAutoPipetteOffset(device, headStage)
			endif
		else
			for(i = 0; i < NUM_HEADSTAGES; i += 1)
				if(abs(TPResults[%BaselineSteadyState][i]) >= ZERO_TOLERANCE)
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

/// @brief Query the amplifier for the gains and units of the given clamp mode
///
/// Assumes that the correct amplifier is already selected!
Function [variable DAGain, variable ADGain, string DAUnit, string ADUnit] AI_QueryGainsUnitsForClampMode(string device, variable headstage, variable clampMode)

	PerformSubsystemEntry()

	DAGain = NaN
	ADGain = NaN
	DAUnit = ""
	ADUnit = ""

	switch(AI_GetAmplifierType(device, headstage))
		case AMPLIFIER_TYPE_NONE:
			return [DAGain, ADGain, DAUnit, ADUnit]
		case AMPLIFIER_TYPE_MCC:
			[DAGain, ADGain, DAUnit, ADUnit] = AIMCC_QueryGainsUnitsForClampMode(device, headstage, clampMode)
			return [DAGain, ADGain, DAUnit, ADUnit]
		case AMPLIFIER_TYPE_SUTTER:
			[DAGain, ADGain, DAUnit, ADUnit] = AISU_QueryGainsUnitsForClampMode(device, headstage, clampMode)
			return [DAGain, ADGain, DAUnit, ADUnit]
		default:
			FATAL_ERROR("Invalid amplifier type")
	endswitch

	return [DAGain, ADGain, DAUnit, ADUnit]
End

/// @brief Return a nicely layouted list of the amplifiers available for the device
///
/// Used as popup menu value function.
///
/// @param device [optional, defaults to none] device, for unlocked panels
///               the device is not yet known
Function/S AI_GetAmplifierList([string device])

	if(ParamIsDefault(device))
		device = ""
	endif

	switch(AI_GetAmplifierTypeOfDevice(device))
		case AMPLIFIER_TYPE_MCC:
			return AIMCC_GetAmplifierList()
		case AMPLIFIER_TYPE_SUTTER:
			return AISU_GetAmplifierList()
		default:
			FATAL_ERROR("Invalid amplifier type")
	endswitch
End

/// @brief Return the amplifier list entry of the amplifier associated with the headstage
///
/// @param device    device
/// @param headstage MIES headstage number, must be in the range [0, NUM_HEADSTAGES[
///
/// @returns list entry as returned by AI_GetAmplifierList() or #NONE
Function/S AI_GetAmplifierDef(string device, variable headstage)

	PerformSubsystemEntry()

	WAVE ChanAmpAssign = GetChanAmpAssign(device)

	switch(AI_GetAmplifierType(device, headstage))
		case AMPLIFIER_TYPE_NONE:
			return NONE
		case AMPLIFIER_TYPE_MCC:
			return AIMCC_GetAmplifierDef(ChanAmpAssign[%AmpSerialNo][headstage], ChanAmpAssign[%AmpChannelID][headstage])
		case AMPLIFIER_TYPE_SUTTER:
			return AISU_GetAmplifierDef(ChanAmpAssign[%AmpChannelID][headstage])
		default:
			FATAL_ERROR("Invalid amplifier type")
	endswitch
End

/// @brief Return the amplifier list entry of the amplifier fixed to the headstage
///
/// Only devices with integrated amplifiers have fixed amplifiers.
///
/// @param device    device
/// @param headstage MIES headstage number, must be in the range [0, NUM_HEADSTAGES[
///
/// @returns list entry as returned by AI_GetAmplifierList(), #NONE if the headstage has no fixed amplifier
///          or an empty string if the device has no fixed amplifiers
Function/S AI_GetFixedAmplifierDef(string device, variable headstage)

	string list

	PerformSubsystemEntry()

	ASSERT(IsValidHeadstage(headstage), "Invalid headstage")

	switch(AI_GetAmplifierTypeOfDevice(device))
		case AMPLIFIER_TYPE_MCC:
			return ""
		case AMPLIFIER_TYPE_SUTTER:
			// first entry is NONE
			list = AISU_GetAmplifierList()
			return SelectString((headstage + 1) < ItemsInList(list), NONE, StringFromList(headstage + 1, list))
		default:
			FATAL_ERROR("Invalid amplifier type")
	endswitch
End

/// @brief Parse the entries which AI_GetAmplifierList() created
///
/// @param[in]  device       device
/// @param[in]  amplifierDef amplifier list entry
/// @retval     ampType      amplifier type, one of @ref AmplifierTypes
/// @retval     ampSerial    amplifier serial number
/// @retval     ampChannelID amplifier channel
Function [variable ampType, variable ampSerial, variable ampChannelID] AI_ParseAmplifierDef(string device, string amplifierDef)

	PerformSubsystemEntry()

	ampType      = AMPLIFIER_TYPE_NONE
	ampSerial    = NaN
	ampChannelID = NaN

	if(!cmpstr(amplifierDef, NONE))
		return [ampType, ampSerial, ampChannelID]
	endif

	ampType = AI_GetAmplifierTypeOfDevice(device)

	switch(ampType)
		case AMPLIFIER_TYPE_MCC:
			[ampSerial, ampChannelID] = AIMCC_ParseAmplifierDef(amplifierDef)
			break
		case AMPLIFIER_TYPE_SUTTER:
			ampChannelID = AISU_ParseAmplifierDef(amplifierDef)
			break
		default:
			FATAL_ERROR("Invalid amplifier type")
	endswitch

	return [ampType, ampSerial, ampChannelID]
End

/// @brief Return the amplifier type the device supports
///
/// Each device supports only amplifiers of one type, besides headstages
/// without amplifier. Sutter devices have integrated amplifiers, all other
/// devices use MCC amplifiers.
///
/// @param device device, can be empty if not yet known
///
/// @returns one of @ref AmplifierTypes, never #AMPLIFIER_TYPE_NONE
threadsafe Function AI_GetAmplifierTypeOfDevice(string device)

	PerformSubsystemEntry_TS()

	if(IsDeviceNameFromSutter(device))
		return AMPLIFIER_TYPE_SUTTER
	endif

	return AMPLIFIER_TYPE_MCC
End

/// @brief Initialize the amplifiers of the device
///
/// Called when locking the device.
///
/// @returns 0 on success, 1 on error
Function AI_InitializeAmplifiers(string device)

	PerformSubsystemEntry()

	switch(AI_GetAmplifierTypeOfDevice(device))
		case AMPLIFIER_TYPE_MCC:
			// the MCC amplifiers are independent of the device
			return 0
		case AMPLIFIER_TYPE_SUTTER:
			return AISU_Initialize(device)
		default:
			FATAL_ERROR("Invalid amplifier type")
	endswitch
End

/// @brief Shutdown the amplifiers of the device
///
/// Called when unlocking the device.
Function AI_ShutdownAmplifiers(string device)

	PerformSubsystemEntry()

	switch(AI_GetAmplifierTypeOfDevice(device))
		case AMPLIFIER_TYPE_MCC:
			// the MCC amplifiers are independent of the device
			break
		case AMPLIFIER_TYPE_SUTTER:
			AISU_Shutdown(device)
			break
		default:
			FATAL_ERROR("Invalid amplifier type")
	endswitch
End

/// @brief Return true if the clamp mode is supported by the amplifiers of the device
///
/// I=0 is not supported for Sutter amplifiers.
///
/// @param device    device
/// @param clampMode one of #V_CLAMP_MODE, #I_CLAMP_MODE or #I_EQUAL_ZERO_MODE
Function AI_IsClampModeSupported(string device, variable clampMode)

	PerformSubsystemEntry()

	AI_AssertOnInvalidClampMode(clampMode)

	switch(AI_GetAmplifierTypeOfDevice(device))
		case AMPLIFIER_TYPE_MCC:
			return 1
		case AMPLIFIER_TYPE_SUTTER:
			return clampMode != I_EQUAL_ZERO_MODE
		default:
			FATAL_ERROR("Invalid amplifier type")
	endswitch
End

/// @brief Return the amplifier types headstages with associated channels of the device can have
///
/// Sutter devices have fixed integrated amplifiers for all their headstages.
/// Headstages without associated channels have no amplifier.
///
/// @param device device, can be empty if not yet known
///
/// @returns numeric wave with entries from @ref AmplifierTypes
Function/WAVE AI_GetAllowedAmplifierTypes(string device)

	PerformSubsystemEntry()

	switch(AI_GetAmplifierTypeOfDevice(device))
		case AMPLIFIER_TYPE_MCC:
			Make/FREE/D types = {AMPLIFIER_TYPE_MCC, AMPLIFIER_TYPE_NONE}
			break
		case AMPLIFIER_TYPE_SUTTER:
			Make/FREE/D types = {AMPLIFIER_TYPE_SUTTER}
			break
		default:
			FATAL_ERROR("Invalid amplifier type")
	endswitch

	return types
End

/// @brief Return true if headstages of the device can have the given amplifier type
///
/// @param device  device, can be empty if not yet known
/// @param ampType one of @ref AmplifierTypes
Function AI_IsAllowedAmplifierType(string device, variable ampType)

	PerformSubsystemEntry()

	WAVE types = AI_GetAllowedAmplifierTypes(device)

	return IsFinite(GetRowIndex(types, val = ampType))
End

/// @brief Return the amplifier type of the given headstage
///
/// @param device    device
/// @param headstage MIES headstage number, must be in the range [0, NUM_HEADSTAGES[
///
/// @returns one of @ref AmplifierTypes
Function AI_GetAmplifierType(string device, variable headstage)

	PerformSubsystemEntry()

	ASSERT(IsValidHeadstage(headstage), "Invalid headstage")

	WAVE ChanAmpAssign = GetChanAmpAssign(device)

	return ChanAmpAssign[%AmpType][headstage]
End

/// @brief Return true if the given headstage has an amplifier associated
///
/// @param device    device
/// @param headstage MIES headstage number, must be in the range [0, NUM_HEADSTAGES[
Function AI_HasAmplifier(string device, variable headstage)

	PerformSubsystemEntry()

	return AI_GetAmplifierType(device, headstage) != AMPLIFIER_TYPE_NONE
End

/// @brief Update the `ChanAmpAssign` and `ChanAmpAssignUnit` waves according to the passed
/// clamp mode with the gains and units.
Function AI_UpdateChanAmpAssign(string device, variable headStage, variable clampMode, variable DAGain, variable ADGain, string DAUnit, string ADUnit)

	PerformSubsystemEntry()

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

	PerformSubsystemEntry_TS()

	ASSERT_TS(AI_IsValidClampMode(clampMode), "invalid clamp mode")
End

/// @brief Return true if the given clamp mode is valid
threadsafe Function AI_IsValidClampMode(variable clampMode)

	PerformSubsystemEntry_TS()

	return clampMode == V_CLAMP_MODE || clampMode == I_CLAMP_MODE || clampMode == I_EQUAL_ZERO_MODE
End

/// @brief Opens the amplifier control software
///
/// @param device           device
/// @param ampSerialNumList A text list of amplifier serial numbers without leading zeroes
/// Ex. "834001;435003;836059", "0;" starts the MCC in Demo mode
/// Duplicate serial numbers are ignored as well as amplifier titles for the duplicates.
/// For each unique serial number one MCC is opened.
/// @param ampTitleList [optional, defaults to blank] MCC gui window title
/// @return 1 if all unique MCCs specified in ampSerialNumList were opened, 0 if one or more MCCs specified in ampSerialNumList were not able to be opened
Function AI_OpenMCCs(string device, string ampSerialNumList, [string ampTitleList])

	PerformSubsystemEntry()

	if(ParamIsDefault(ampTitleList))
		ampTitleList = ""
	else
		ASSERT(ItemsInList(ampSerialNumList) == ItemsInList(ampTitleList), "Number of amplifier serials does not match number of amplifier titles.")
	endif

	switch(AI_GetAmplifierTypeOfDevice(device))
		case AMPLIFIER_TYPE_MCC:
			return AIMCC_OpenMCCs(ampSerialNumList, ampTitleList)
		case AMPLIFIER_TYPE_SUTTER:
			// @todo implement
			return 1
		default:
			FATAL_ERROR("Invalid amplifier type")
	endswitch
End

/// @brief Map from amplifier control names to @ref AI_SendToAmpConstants constants and clamp mode
threadsafe Function [variable func, variable clampMode] AI_MapControlNameToFunctionConstant(string ctrl)

	PerformSubsystemEntry_TS()

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

	PerformSubsystemEntry()

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

	PerformSubsystemEntry_TS()

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
threadsafe static Function AI_MapNameToFunctionConstant(string name)

	PerformSubsystemEntry_TS()

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

	PerformSubsystemEntry()

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
Function/S AI_AmpStorageControlToRowLabel(string ctrl)

	PerformSubsystemEntry()

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
		case "check_DataAcq_Amp_Chain":
			return "RSCompChaining"
			break
		case "button_DataAcq_WCAuto": // fallthrough
		case "button_DataAcq_FastComp_VC": // fallthrough
		case "button_DataAcq_SlowComp_VC": // fallthrough
		case "button_DataAcq_AutoPipOffset_VC":
			// no row exists
			return ""
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
		case "button_DataAcq_AutoBridgeBal_IC": // fallthrough
		case "button_DataAcq_AutoPipOffset_IC": // fallthrough
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

	PerformSubsystemEntry_TS()

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

	PerformSubsystemEntry_TS()

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

///@brief Returns the holding command of the amplifier
Function AI_GetHoldingCommand(string device, variable headstage)

	PerformSubsystemEntry()

	switch(AI_GetAmplifierType(device, headstage))
		case AMPLIFIER_TYPE_NONE:
			return NaN
		case AMPLIFIER_TYPE_MCC:
			return AIMCC_GetHoldingCommand(device, headstage)
		case AMPLIFIER_TYPE_SUTTER:
			return AISU_GetHoldingCommand(device, headstage)
		default:
			FATAL_ERROR("Invalid amplifier type")
	endswitch
End

/// @brief Return the clamp mode of the headstage as returned by the amplifier
///
/// Should only be used during the setup phase when you don't know if the
/// clamp mode in MIES matches already. It is always better to prefer
/// DAP_ChangeHeadStageMode() if possible.
///
/// @brief One of @ref AmplifierClampModes or NaN if no amplifier is connected
Function AI_GetMode(string device, variable headstage)

	PerformSubsystemEntry()

	switch(AI_GetAmplifierType(device, headstage))
		case AMPLIFIER_TYPE_NONE:
			return NaN
		case AMPLIFIER_TYPE_MCC:
			return AIMCC_GetMode(device, headstage)
		case AMPLIFIER_TYPE_SUTTER:
			return AISU_GetMode(device, headstage)
		default:
			FATAL_ERROR("Invalid amplifier type")
	endswitch
End

/// @brief Select the amplifier of the given headstage
///
/// @param device    device
/// @param headStage MIES headstage number, must be in the range [0, NUM_HEADSTAGES]
///
/// @returns one of @ref AISelectMultiClampReturnValues
Function AI_SelectMultiClamp(string device, variable headStage)

	PerformSubsystemEntry()

	switch(AI_GetAmplifierType(device, headStage))
		case AMPLIFIER_TYPE_NONE:
			return AMPLIFIER_CONNECTION_INVAL_SER
		case AMPLIFIER_TYPE_MCC:
			return AIMCC_SelectMultiClamp(device, headStage)
		case AMPLIFIER_TYPE_SUTTER:
			return AISU_SelectMultiClamp(device, headStage)
		default:
			FATAL_ERROR("Invalid amplifier type")
	endswitch
End

/// @brief Set the clamp mode of the amplifier based on the headstage number
///
/// @param device    device
/// @param headStage MIES headstage number, must be in the range [0, NUM_HEADSTAGES[
/// @param mode      clamp mode to set
/// @param zeroStep  [optional, defaults to false] switch via I=0 to the target clamp mode
/// @param selectAmp [optional, defaults to true] Select the amplifier
///                  before use, some callers might save time in doing that once themselves.
Function AI_SetClampMode(string device, variable headStage, variable mode, [variable zeroStep, variable selectAmp])

	PerformSubsystemEntry()

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

	switch(AI_GetAmplifierType(device, headStage))
		case AMPLIFIER_TYPE_NONE:
			return NaN
		case AMPLIFIER_TYPE_MCC:
			AIMCC_SetClampMode(device, headStage, mode, zeroStep, selectAmp)
			break
		case AMPLIFIER_TYPE_SUTTER:
			AISU_SetClampMode(device, headStage, mode)
			break
		default:
			FATAL_ERROR("Invalid amplifier type")
	endswitch
End

/// @brief Generic interface to call amplifier functions
///
/// Dispatches to the implementation of the amplifier type of the headstage.
///
/// @param device           device
/// @param headStage        MIES headstage number, must be in the range [0, NUM_HEADSTAGES[
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
Function AI_SendToAmp(string device, variable headStage, variable mode, variable func, variable accessType, [variable checkBeforeWrite, variable usePrefixes, variable selectAmp, variable value])

	PerformSubsystemEntry()

	checkBeforeWrite = ParamIsDefault(checkBeforeWrite) ? 0 : !!checkBeforeWrite
	usePrefixes      = ParamIsDefault(usePrefixes) ? 1 : !!usePrefixes
	selectAmp        = ParamIsDefault(selectAmp) ? 1 : !!selectAmp

	switch(AI_GetAmplifierType(device, headStage))
		case AMPLIFIER_TYPE_NONE:
			return NaN
		case AMPLIFIER_TYPE_MCC:
			if(ParamIsDefault(value))
				return AIMCC_SendToAmp(device, headStage, mode, func, accessType, checkBeforeWrite = checkBeforeWrite, usePrefixes = usePrefixes, selectAmp = selectAmp)
			endif

			return AIMCC_SendToAmp(device, headStage, mode, func, accessType, checkBeforeWrite = checkBeforeWrite, usePrefixes = usePrefixes, selectAmp = selectAmp, value = value)
		case AMPLIFIER_TYPE_SUTTER:
			return AISU_SendToAmp(device, headStage, mode, func, accessType, checkBeforeWrite, usePrefixes, selectAmp, ParamIsDefault(value) ? NaN : value)
		default:
			FATAL_ERROR("Invalid amplifier type")
	endswitch
End

/// @brief Update the settings which the amplifier changed as a side effect of writing `func`
///
/// @param device    device
/// @param headStage MIES headstage number, must be in the range [0, NUM_HEADSTAGES[
/// @param func      Function which was written, see @ref AI_SendToAmpConstants
/// @param clampMode clamp mode of `func`
static Function AI_UpdateDependentSettings(string device, variable headStage, variable func, variable clampMode)

	switch(AI_GetAmplifierType(device, headStage))
		case AMPLIFIER_TYPE_NONE:
			return NaN
		case AMPLIFIER_TYPE_MCC:
			return AIMCC_UpdateDependentSettings(device, headStage, func, clampMode)
		case AMPLIFIER_TYPE_SUTTER:
			return AISU_UpdateDependentSettings(device, headStage, func, clampMode)
		default:
			FATAL_ERROR("Invalid amplifier type")
	endswitch
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

	variable i, diff, selectedHeadstage, requestedFunc, requestedClampMode, requestedValue, chainedFunc
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

	requestedFunc      = func
	requestedClampMode = clampMode
	requestedValue     = value

	for(i = 0; i < NUM_HEADSTAGES; i += 1)

		// the cases below can change these, e.g. to update dependent settings
		func      = requestedFunc
		clampMode = requestedClampMode
		value     = requestedValue

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
					TP_UpdateHoldCmdInTPStorage(device, i)
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
				AI_UpdateAmpView(device, i, func = func, clampMode = clampMode)

				func                             = MCC_WHOLECELLCOMPRESIST_FUNC
				rowLabel                         = AI_MapFunctionConstantToName(func, clampMode)
				value                            = AI_SendToAmp(device, i, clampMode, func, MCC_READ, checkBeforeWrite = checkBeforeWrite, selectAmp = 0)
				AmpStorageWave[%$rowLabel][0][i] = value
				AI_UpdateAmpView(device, i, func = func, clampMode = clampMode)

				func                             = MCC_WHOLECELLCOMPENABLE_FUNC
				rowLabel                         = AI_MapFunctionConstantToName(func, clampMode)
				value                            = AI_SendToAmp(device, i, clampMode, func, MCC_READ, checkBeforeWrite = checkBeforeWrite, selectAmp = 0)
				AmpStorageWave[%$rowLabel][0][i] = value
				AI_UpdateAmpView(device, i, func = func, clampMode = clampMode)
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
					chainedFunc = MCC_RSCOMPPREDICTION_FUNC
					rowLabel    = AI_MapFunctionConstantToName(chainedFunc, clampMode)

					AmpStorageWave[%$rowLabel][0][i] += diff
					AI_SendToAmp(device, i, clampMode, chainedFunc, MCC_WRITE, value = AmpStorageWave[%$rowLabel][0][i], checkBeforeWrite = checkBeforeWrite, selectAmp = 0)
					AI_UpdateAmpView(device, i, func = chainedFunc, clampMode = clampMode)
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
					chainedFunc = MCC_RSCOMPCORRECTION_FUNC
					rowLabel    = AI_MapFunctionConstantToName(chainedFunc, clampMode)

					AmpStorageWave[%$rowLabel][0][i] += diff
					AI_SendToAmp(device, i, clampMode, chainedFunc, MCC_WRITE, value = AmpStorageWave[%$rowLabel][0][i], checkBeforeWrite = checkBeforeWrite, selectAmp = 0)
					AI_UpdateAmpView(device, i, func = chainedFunc, clampMode = clampMode)
				endif
				break
			case MCC_AUTOPIPETTEOFFSET_FUNC:
				value = AI_SendToAmp(device, i, clampMode, func, MCC_WRITE, value = NaN, checkBeforeWrite = checkBeforeWrite, selectAmp = 0)

				func     = MCC_PIPETTEOFFSET_FUNC
				rowLabel = AI_MapFunctionConstantToName(func, clampMode)

				AmpStorageWave[%$rowLabel][0][i] = value
				AI_UpdateAmpView(device, i, func = func, clampMode = clampMode)
				break
			case MCC_NO_AMPCHAIN_FUNC:
				rowLabel = AI_MapFunctionConstantToName(func, clampMode)

				AmpStorageWave[%$rowLabel][0][i] = value

				PUB_AmplifierSettingChange(device, i, clampMode, func, value)

				// resend the Rs correction with the new chaining state
				AI_UpdateAmpModel(device, i, ctrl = "setvar_DataAcq_RsCorr", value = AmpStorageWave[%Correction][0][i], sendToAll = 0, selectAmp = 0)
				break
			case MCC_NO_AUTOBIAS_V_FUNC: // fallthrough
				ASSERT(value > -100 && value < 100, "Out of range: value = " + num2str(value) + " mV, expected (-100, 100) mV")
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

				// not supported by the amplifier or failed
				if(!IsFinite(value))
					break
				endif

				AI_UpdateAmpModel(device, i, ctrl = "setvar_DataAcq_BB", value = value, sendToAll = 0, selectAmp = 0)
				AI_UpdateAmpModel(device, i, ctrl = "check_DatAcq_BBEnable", value = 1, sendToAll = 0, selectAmp = 0)
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
				AI_SendToAmp(device, i, clampMode, func, MCC_WRITE, value = value, checkBeforeWrite = checkBeforeWrite, selectAmp = 0)
				break
			default:
				FATAL_ERROR("Unknown func: " + num2str(func))
				break
		endswitch

		if(GUIWrite)
			AI_UpdateAmpView(device, i, func = func, clampMode = clampMode)
		endif

		AI_UpdateDependentSettings(device, i, requestedFunc, requestedClampMode)
	endfor

	TP_RestartTestPulse(device, runMode, fast = TP_FAST_NO_CONFIG)

	return 0
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
/// @param GUIWrite         [optional, defaults to true] Should the amplifier control, if available, be updated with the value
///
/// @return 0 on success, 1 otherwise
Function AI_WriteToAmplifier(string device, variable headStage, variable mode, variable func, variable value, [variable sendToAll, variable checkBeforeWrite, variable selectAmp, variable GUIWrite])

	PerformSubsystemEntry()

	if(ParamIsDefault(sendToAll))
		sendToAll = NaN
	else
		sendToAll = !!sendToAll
	endif

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

	switch(AI_GetAmplifierTypeOfDevice(device))
		case AMPLIFIER_TYPE_MCC: // fallthrough
		case AMPLIFIER_TYPE_SUTTER:
			if(IsNaN(sendToAll))
				return AI_UpdateAmpModel(device, headStage, clampMode = mode, func = func, value = value, checkBeforeWrite = checkBeforeWrite, selectAmp = selectAmp, GUIWrite = GUIWrite)
			endif

			return AI_UpdateAmpModel(device, headStage, clampMode = mode, func = func, value = value, checkBeforeWrite = checkBeforeWrite, selectAmp = selectAmp, GUIWrite = GUIWrite, sendToAll = sendToAll)
		default:
			FATAL_ERROR("Invalid amplifier type")
	endswitch
End

/// @brief Read from amplifier
///
/// @param device           device
/// @param headStage        MIES headstage number, must be in the range [0, NUM_HEADSTAGES[
/// @param mode             One of V_CLAMP_MODE, I_CLAMP_MODE or I_EQUAL_ZERO_MODE
/// @param func             Function to call, see @ref AI_SendToAmpConstants
/// @param usePrefixes      [optional, defaults to true] Use SI-prefixes common in MIES for the passed and returned values, e.g.
///                         `mV` instead of `V`
/// @param selectAmp        [optional, defaults to true] Select the amplifier
///                         before use, some callers might save time in doing that once themselves.
/// @return read value or NaN on error
Function AI_ReadFromAmplifier(string device, variable headStage, variable mode, variable func, [variable usePrefixes, variable selectAmp])

	PerformSubsystemEntry()

	if(ParamIsDefault(usePrefixes))
		usePrefixes = 1
	else
		usePrefixes = !!usePrefixes
	endif

	if(ParamIsDefault(selectAmp))
		selectAmp = 1
	else
		selectAmp = !!selectAmp
	endif

	switch(AI_GetAmplifierType(device, headStage))
		case AMPLIFIER_TYPE_NONE:
			return NaN
		case AMPLIFIER_TYPE_MCC: // fallthrough
		case AMPLIFIER_TYPE_SUTTER:
			return AI_SendToAmp(device, headStage, mode, func, MCC_READ, usePrefixes = usePrefixes, selectAmp = selectAmp)
		default:
			FATAL_ERROR("Invalid amplifier type")
	endswitch
End

/// @brief Set the clamp mode in the amplifier to the
///        same clamp mode as MIES has stored.
///
/// @param device     device
/// @param headStage  headstage
/// @param selectAmp  [optional, defaults to false] selects the amplifier
///                   before using, some callers might be able to skip it.
///
/// @return 0 on success, 1 when the headstage does not have an amplifier connected or it could not be selected
Function AI_EnsureCorrectMode(string device, variable headStage, [variable selectAmp])

	PerformSubsystemEntry()

	if(ParamIsDefault(selectAmp))
		selectAmp = 0
	else
		selectAmp = !!selectAmp
	endif

	switch(AI_GetAmplifierType(device, headStage))
		case AMPLIFIER_TYPE_NONE:
			return 1
		case AMPLIFIER_TYPE_MCC:
			return AIMCC_EnsureCorrectMode(device, headStage, selectAmp)
		case AMPLIFIER_TYPE_SUTTER:
			return AISU_EnsureCorrectMode(device, headStage)
		default:
			FATAL_ERROR("Invalid amplifier type")
	endswitch
End

/// @brief Fill the amplifier settings wave by querying the amplifier and send the data to ED_AddEntriesToLabnotebook
///
/// @param device  device
/// @param sweepNo data wave sweep number
Function AI_FillAndSendAmpliferSettings(string device, variable sweepNo)

	PerformSubsystemEntry()

	switch(AI_GetAmplifierTypeOfDevice(device))
		case AMPLIFIER_TYPE_MCC:
			return AIMCC_FillAndSendAmpliferSettings(device, sweepNo)
		case AMPLIFIER_TYPE_SUTTER:
			// @todo implement
			return NaN
		default:
			FATAL_ERROR("Invalid amplifier type")
	endswitch
End

/// @brief Auto fills the units and gains for all headstages connected to amplifiers
/// by querying the amplifier
///
/// The data is inserted into `ChanAmpAssign` and `ChanAmpAssignUnit`
///
/// @return number of connected amplifiers
Function AI_QueryGainsFromMCC(string device)

	PerformSubsystemEntry()

	switch(AI_GetAmplifierTypeOfDevice(device))
		case AMPLIFIER_TYPE_MCC:
			return AIMCC_QueryGainsFromMCC(device)
		case AMPLIFIER_TYPE_SUTTER:
			return AISU_QueryGainsFromMCC(device)
		default:
			FATAL_ERROR("Invalid amplifier type")
	endswitch
End

/// @brief Return the number of connected amplifiers
///
/// @param device         device, can be empty if not yet known
/// @param rescanHardware [optional, defaults to false] rescan the hardware instead of using cached results
Function AI_FindConnectedAmps(string device, [variable rescanHardware])

	PerformSubsystemEntry()

	if(ParamIsDefault(rescanHardware))
		rescanHardware = 0
	else
		rescanHardware = !!rescanHardware
	endif

	switch(AI_GetAmplifierTypeOfDevice(device))
		case AMPLIFIER_TYPE_MCC:
			return AIMCC_FindConnectedAmps(rescanHardware)
		case AMPLIFIER_TYPE_SUTTER:
			// the integrated amplifiers can not be rescanned without resetting the device
			return AISU_FindConnectedAmps()
		default:
			FATAL_ERROR("Invalid amplifier type")
	endswitch
End
