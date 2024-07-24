#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_AI
#endif

/// @file MIES_AmplifierInteraction.ipf
/// @brief __AI__ Interface with headstage amplifiers

/// @brief Update the AmpStorageWave entry and send the value to the amplifier
///
/// Additionally setting the GUI value if the given headstage is the selected one
/// and a value has been passed.
///
/// @param device           device
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
Function AI_UpdateAmpModel(string device, string ctrl, variable headStage, [variable value, variable sendToAll, variable checkBeforeWrite, variable selectAmp])

	variable selectedHeadstage, updateView

	DAP_AbortIfUnlocked(device)

	selectedHeadstage = DAG_GetNumericalValue(device, "slider_DataAcq_ActiveHeadstage")

	updateView = !ParamIsDefault(value)

	if(ParamIsDefault(value))
		ASSERT(headstage == selectedHeadstage, "Supply the optional argument value if setting values of other headstages than the current one")
		// we don't use a wrapper here as we want to be able to query different control types
		ControlInfo/W=$device $ctrl
		ASSERT(V_flag != 0, "non-existing window or control")
		value = V_value
	endif

	selectAmp        = ParamIsDefault(selectAmp) ? 1 : !!selectAmp
	checkBeforeWrite = ParamIsDefault(checkBeforeWrite) ? 0 : !!checkBeforeWrite

	if(ParamIsDefault(sendToAll))
		if(headstage == selectedHeadstage)
			sendToAll = DAG_GetNumericalValue(device, "Check_DataAcq_SendToAllAmp")
		else
			sendToAll = 0
		endif
	else
		sendToAll = !!sendToAll
	endif

	if(IsDeviceNameFromSutter(device))
		// @todo implement
		return 1
	endif

	return AIMCC_UpdateAmpModel(device, ctrl, headStage, value, sendToAll, checkBeforeWrite, selectAmp, updateView)
End

/// @brief Convenience wrapper for #AIMCC_UpdateAmpView
///
/// Disallows setting single controls for outside callers as #AI_UpdateAmpModel should be used for that.
Function AI_SyncAmpStorageToGUI(string device, variable headstage)

	if(IsDeviceNameFromSutter(device))
		// @todo implement
		return 1
	endif

	return AIMCC_SyncAmpStorageToGUI(device, headstage)
End

/// @brief Sync the settings from the GUI to the amp storage wave and the MCC application
Function AI_SyncGUIToAmpStorageAndMCCApp(string device, variable headStage, variable clampMode)

	if(IsDeviceNameFromSutter(device))
		// @todo implement
		return NaN
	endif

	AIMCC_SyncGUIToAmpStorageAndMCCApp(device, headstage, clampMode)
End

/// @brief Executes MCC auto zero command if the baseline current exceeds #ZERO_TOLERANCE
///
/// @param device device
/// @param headStage     [optional: defaults to all active headstages]
Function AI_ZeroAmps(string device, [variable headStage])

	headStage = ParamIsDefault(headStage) ? NaN : headStage

	if(IsDeviceNameFromSutter(device))
		// @todo implement
		return NaN
	endif

	AIMCC_ZeroAmps(device, headstage)
End

/// @brief Query the MCC application for the gains and units of the given clamp mode
///
/// Assumes that the correct amplifier is already selected!
Function [variable DAGain, variable ADGain, string ADUnit, string DAUnit] AI_QueryGainsUnitsForClampMode(string device, variable headstage, variable clampMode)

	if(IsDeviceNameFromSutter(device))
		// @todo implement
		return [NaN, NaN, "", ""]
	endif

	[DAGain, ADGain, ADUnit, DAUnit] = AIMCC_QueryGainsUnitsForClampMode(device, headstage, clampMode)

	return [DAGain, ADGain, ADUnit, DAUnit]
End

/// @brief Update the `ChanAmpAssign` and `ChanAmpAssignUnit` waves according to the passed
/// clamp mode with the gains and units.
Function AI_UpdateChanAmpAssign(string device, variable headStage, variable clampMode, variable DAGain, variable ADGain, string DAUnit, string ADUnit)

	AI_AssertOnInvalidClampMode(device, clampMode)

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
Function AI_AssertOnInvalidClampMode(string device, variable clampMode)

	ASSERT(AI_IsValidClampMode(device, clampMode), "invalid clamp mode")
End

/// @brief Return true if the given clamp mode is valid
Function AI_IsValidClampMode(string device, variable clampMode)

	if(IsDeviceNameFromSutter(device))
		// @todo implement
		return 1
	endif

	return AIMCC_IsValidClampMode(clampMode)
End

/// @brief Opens Multi-clamp commander software
///
/// @param device           device
/// @param ampSerialNumList A text list of amplifier serial numbers without leading zeroes
/// Ex. "834001;435003;836059", "0;" starts the MCC in Demo mode
/// Duplicate serial numbers are ignored as well as amplifier titles for the duplicates.
/// For each unique serial number one MCC is opened.
/// @param ampTitleList [optional, defaults to blank] MCC gui window title
/// @return 1 if all unique MCCs specified in ampSerialNumList were opened, 0 if one or more MCCs specified in ampSerialNumList were not able to be opened
Function AI_OpenMCCs(string device, string ampSerialNumList, [string ampTitleList])

	if(ParamIsDefault(AmpTitleList))
		AmpTitleList = ""
	else
		ASSERT(ItemsInList(AmpSerialNumList) == ItemsInList(ampTitleList), "Number of amplifier serials does not match number of amplifier titles.")
	endif

	if(IsDeviceNameFromSutter(device))
		// @todo implement
		return 1
	endif

	return AIMCC_OpenMCCs(ampSerialNumList, ampTitleList)
End

///@brief Returns the holding command of the amplifier
Function AI_GetHoldingCommand(string device, variable headstage)

	if(IsDeviceNameFromSutter(device))
		// @todo implement
		return NaN
	endif

	return AIMCC_GetHoldingCommand(device, headstage)
End

/// @brief Return the clamp mode of the headstage as returned by the amplifier
///
/// Should only be used during the setup phase when you don't know if the
/// clamp mode in MIES matches already. It is always better to prefer
/// DAP_ChangeHeadStageMode() if possible.
///
/// @brief One of @ref AmplifierClampModes or NaN if no amplifier is connected
Function AI_GetMode(string device, variable headstage)

	if(IsDeviceNameFromSutter(device))
		// @todo implement
		return NaN
	endif

	return AIMCC_GetMode(device, headstage)
End

/// @brief Wrapper for MCC_SelectMultiClamp700B
///
/// @param device device
/// @param headStage MIES headstage number, must be in the range [0, NUM_HEADSTAGES]
///
/// @returns one of @ref AISelectMultiClampReturnValues
Function AI_SelectMultiClamp(string device, variable headStage)

	if(IsDeviceNameFromSutter(device))
		// @todo implement
		return NaN
	endif

	return AIMCC_SelectMultiClamp(device, headstage)
End

/// @brief Set the clamp mode of user linked MCC based on the headstage number
Function AI_SetClampMode(string device, variable headStage, variable mode, [variable zeroStep])

	zeroStep = ParamIsDefault(zeroStep) ? 0 : !!zeroStep

	if(IsDeviceNameFromSutter(device))
		// @todo implement
		return NaN
	endif

	AIMCC_SetClampMode(device, headstage, mode, zeroStep)
End

/// @brief Generic interface to call MCC amplifier functions
///
/// @param device       locked panel name to work on
/// @param headStage        MIES headstage number, must be in the range [0, NUM_HEADSTAGES]
/// @param mode             one of V_CLAMP_MODE, I_CLAMP_MODE or I_EQUAL_ZERO_MODE
/// @param func             Function to call, see @ref AIMCC_SendToAmpConstants
/// @param value            Numerical value to send, ignored by all getter functions
/// @param checkBeforeWrite [optional, defaults to false] (ignored for getter functions)
///                         check the current value and do nothing if it is equal within some tolerance to the one written
/// @param usePrefixes      [optional, defaults to true] Use SI-prefixes common in MIES for the passed and returned values, e.g.
///                         `mV` instead of `V`
/// @param selectAmp        [optional, defaults to true] Select the amplifier
///                         before use, some callers might save time in doing that once themselves.
///
/// @returns return value (for getters, respects `usePrefixes`), success (`0`) or error (`NaN`).
Function AI_SendToAmp(string device, variable headStage, variable mode, variable func, variable value, [variable checkBeforeWrite, variable usePrefixes, variable selectAmp])

	ASSERT(func > MCC_BEGIN_INVALID_FUNC && func < MCC_END_INVALID_FUNC, "MCC function constant is out for range")
	ASSERT(headStage >= 0 && headStage < NUM_HEADSTAGES, "invalid headStage index")
	AI_AssertOnInvalidClampMode(device, mode)

	checkBeforeWrite = ParamIsDefault(checkBeforeWrite) ? 0 : !!checkBeforeWrite
	usePrefixes      = ParamIsDefault(usePrefixes) ? 1 : !!usePrefixes
	selectAmp        = ParamIsDefault(selectAmp) ? 1 : !!selectAmp

	if(IsDeviceNameFromSutter(device))
		// @todo implement
		return NaN
	endif

	return AIMCC_SendToAmp(device, headstage, mode, func, value, checkBeforeWrite, usePrefixes, selectAmp)
End

/// @brief Set the clamp mode in the MCC app to the
///        same clamp mode as MIES has stored.
///
/// @param device     device
/// @param headstage  headstage
/// @param selectAmp  [optional, defaults to false] selects the amplifier
///                   before using, some callers might be able to skip it.
///
/// @return 0 on success, 1 when the headstage does not have an amplifier connected or it could not be selected
Function AI_EnsureCorrectMode(string device, variable headstage, [variable selectAmp])

	selectAmp = ParamIsDefault(selectAmp) ? 0 : !!selectAmp

	if(IsDeviceNameFromSutter(device))
		// @todo implement
		return 0
	endif

	return AIMCC_EnsureCorrectMode(device, headstage, selectAmp)
End

/// @brief Fill the amplifier settings wave by querying the MC700B and send the data to ED_AddEntriesToLabnotebook
///
/// @param device 		 device
/// @param sweepNo           data wave sweep number
Function AI_FillAndSendAmpliferSettings(string device, variable sweepNo)

	if(IsDeviceNameFromSutter(device))
		// @todo implement
		return NaN
	endif

	AIMCC_FillAndSendAmpliferSettings(device, sweepNo)
End

/// @brief Auto fills the units and gains for all headstages connected to amplifiers
/// by querying the MCC application
///
/// The data is inserted into `ChanAmpAssign` and `ChanAmpAssignUnit`
///
/// @return number of connected amplifiers
Function AI_QueryGainsFromMCC(string device)

	if(IsDeviceNameFromSutter(device))
		// @todo implement
		return NaN
	endif

	return AIMCC_QueryGainsFromMCC(device)
End

/// @brief Create the amplifier connection waves
Function AI_FindConnectedAmps(string device)

	if(IsDeviceNameFromSutter(device))
		// @todo implement
		return NaN
	endif

	AIMCC_FindConnectedAmps()
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
