#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors = 1

#ifdef AUTOMATED_TESTING
#pragma ModuleName = MIES_AI_SU
#endif // AUTOMATED_TESTING

/// @file MIES_AmplifierInteraction_Sutter.ipf
/// @brief __AI_SU__ Interface with the amplifiers integrated in the Sutter IPA devices
///
/// The amplifier headstages are addressed by their probe index, which is the
/// zero-based index of the headstage over all IPA devices in the order of
/// `LISTOFDEVICES` from GetSUDeviceInfo(). The MIES headstage with the same
/// index is fixed to that amplifier headstage.

static StrConstant AMPLIFIER_DEF_FORMAT = "%s HS %d"

/// @name Gains of the Sutter headstages
///
/// The Sutter XOP outputs and acquires the headstage signals in SI units,
/// independent of the gain setting of the amplifier.
///@{
static Constant SUTTER_VC_DA_GAIN = 1000  ///< mV/V, command in V
static Constant SUTTER_VC_AD_GAIN = 1e-12 ///< A/pA, current in A
static Constant SUTTER_IC_DA_GAIN = 1e12  ///< pA/A, command in A
static Constant SUTTER_IC_AD_GAIN = 1e-3  ///< V/mV, voltage in V
///@}

// IPA_Control.ipf is only included with the Sutter XOP, see MIES_Include.ipf
#if exists("SutterDAQScanWave")
#define SUTTER_AMPLIFIER_PRESENT
#endif

/// @brief Return the number of amplifier headstages of all IPA devices
static Function AI_SU_GetNumberOfProbes()

	WAVE/T deviceInfo = GetSUDeviceInfo()

	variable numProbes = str2num(deviceInfo[%SUMHEADSTAGES])

	return IsFinite(numProbes) ? numProbes : 0
End

/// @brief Return the IPA device serial and the one-based headstage number on that device
///        of the given probe index
static Function [string serial, variable deviceHeadstage] AI_SU_GetDeviceHeadstageFromProbe(variable probeIndex)

	variable i, numDevices, numHeadstages, offset

	WAVE/T deviceInfo = GetSUDeviceInfo()

	numDevices = ItemsInList(deviceInfo[%LISTOFDEVICES])
	for(i = 0; i < numDevices; i += 1)
		numHeadstages = str2num(StringFromList(i, deviceInfo[%LISTOFHEADSTAGES]))
		if(probeIndex < (offset + numHeadstages))
			serial = StringFromList(i, deviceInfo[%LISTOFDEVICES])
			return [serial, probeIndex - offset + 1]
		endif
		offset += numHeadstages
	endfor

	FATAL_ERROR("Invalid probe index: " + num2istr(probeIndex))

	return ["", NaN]
End

/// @brief Return the probe index of the one-based headstage number on the IPA device with the given serial
static Function AI_SU_GetProbeFromDeviceHeadstage(string serial, variable deviceHeadstage)

	variable i, numDevices, numHeadstages, offset

	WAVE/T deviceInfo = GetSUDeviceInfo()

	numDevices = ItemsInList(deviceInfo[%LISTOFDEVICES])
	for(i = 0; i < numDevices; i += 1)
		numHeadstages = str2num(StringFromList(i, deviceInfo[%LISTOFHEADSTAGES]))
		if(!cmpstr(serial, StringFromList(i, deviceInfo[%LISTOFDEVICES])))
			ASSERT(deviceHeadstage >= 1 && deviceHeadstage <= numHeadstages, "Invalid headstage of IPA device " + serial)
			return offset + deviceHeadstage - 1
		endif
		offset += numHeadstages
	endfor

	FATAL_ERROR("Unknown IPA device: " + serial)
End

/// @brief Return the number of connected amplifier headstages
///
/// The amplifiers are integrated in the IPA devices, so these are the
/// amplifier headstages of all IPA devices found when opening the device.
Function AI_SU_FindConnectedAmps()

	PerformSubsystemEntry()

	return AI_SU_GetNumberOfProbes()
End

/// @brief Return the gains and units of the given clamp mode
///
/// These are fixed for Sutter amplifiers, see @ref SUTTER_VC_DA_GAIN.
Function [variable DAGain, variable ADGain, string DAUnit, string ADUnit] AI_SU_QueryGainsUnitsForClampMode(string device, variable headstage, variable clampMode)

	PerformSubsystemEntry()

	switch(clampMode)
		case V_CLAMP_MODE:
			DAGain = SUTTER_VC_DA_GAIN
			ADGain = SUTTER_VC_AD_GAIN
			DAUnit = "mV"
			ADUnit = "pA"
			break
		case I_CLAMP_MODE:
			DAGain = SUTTER_IC_DA_GAIN
			ADGain = SUTTER_IC_AD_GAIN
			DAUnit = "pA"
			ADUnit = "mV"
			break
		default:
			FATAL_ERROR("Unsupported clamp mode for Sutter amplifiers: " + num2istr(clampMode))
	endswitch

	return [DAGain, ADGain, DAUnit, ADUnit]
End

/// @brief Fill the gains and units of all headstages with Sutter amplifiers
///
/// The data is inserted into `ChanAmpAssign` and `ChanAmpAssignUnit`.
///
/// @returns number of Sutter amplifiers
Function AI_SU_QueryGainsFromMCC(string device)

	variable i, clampMode, numAmplifiers, DAGain, ADGain
	string DAUnit, ADUnit

	PerformSubsystemEntry()

	Make/FREE/D clampModes = {V_CLAMP_MODE, I_CLAMP_MODE}

	for(i = 0; i < NUM_HEADSTAGES; i += 1)
		if(AI_GetAmplifierType(device, i) != AMPLIFIER_TYPE_SUTTER)
			continue
		endif

		numAmplifiers += 1

		for(clampMode : clampModes)
			[DAGain, ADGain, DAUnit, ADUnit] = AI_SU_QueryGainsUnitsForClampMode(device, i, clampMode)
			AI_UpdateChanAmpAssign(device, i, clampMode, DAGain, ADGain, DAUnit, ADUnit)
		endfor
	endfor

	return numAmplifiers
End

/// @brief Return a nicely layouted list of the amplifier headstages of all IPA devices
Function/S AI_SU_GetAmplifierList()

	variable i, numProbes
	string list

	PerformSubsystemEntry()

	list = AddListItem(NONE, "", ";", Inf)

	numProbes = AI_SU_GetNumberOfProbes()
	for(i = 0; i < numProbes; i += 1)
		list = AddListItem(AI_SU_GetAmplifierDef(i), list, ";", Inf)
	endfor

	return list
End

/// @brief Return the amplifier list entry for the given probe index
Function/S AI_SU_GetAmplifierDef(variable probeIndex)

	string str, serial
	variable deviceHeadstage

	PerformSubsystemEntry()

	[serial, deviceHeadstage] = AI_SU_GetDeviceHeadstageFromProbe(probeIndex)

	sprintf str, AMPLIFIER_DEF_FORMAT, serial, deviceHeadstage

	return str
End

/// @brief Parse the entries which AI_SU_GetAmplifierDef() created
///
/// @returns probe index
Function AI_SU_ParseAmplifierDef(string amplifierDef)

	string   serial
	variable deviceHeadstage

	PerformSubsystemEntry()

	sscanf amplifierDef, AMPLIFIER_DEF_FORMAT, serial, deviceHeadstage
	ASSERT(V_flag == 2, "Unexpected amplifier popup list format")

	return AI_SU_GetProbeFromDeviceHeadstage(serial, deviceHeadstage)
End

/// @brief Return the IPA control keyword and the scale factors for the given amplifier function
///
/// The value for the IPA control package is `value * prefixScale * unitScale`, where `value`
/// is in MIES units (see `usePrefixes` of AI_SendToAmp()), `prefixScale` converts from MIES units
/// to SI units and `unitScale` from SI units to the unit of the IPA control package.
///
/// @param func      Function to call, see @ref AI_SendToAmpConstants
/// @param clampMode #V_CLAMP_MODE or #I_CLAMP_MODE
///
/// @returns keyword, empty if the function is not supported by the Sutter amplifiers
static Function [string setting, variable prefixScale, variable unitScale] AI_SU_GetSetting(variable func, variable clampMode)

	switch(func)
		case MCC_HOLDING_FUNC:
			if(clampMode == V_CLAMP_MODE)
				return ["VHold", MILLI_TO_ONE, 1]
			endif

			return ["IHold", PICO_TO_ONE, 1]
		case MCC_HOLDINGENABLE_FUNC:
			if(clampMode == V_CLAMP_MODE)
				return ["VHoldOn", 1, 1]
			endif

			return ["IHoldOn", 1, 1]
		case MCC_BRIDGEBALENABLE_FUNC:
			return ["BridgeOn", 1, 1]
		case MCC_BRIDGEBALRESIST_FUNC:
			return ["Bridge", MEGA_TO_ONE, 1]
		case MCC_NEUTRALIZATIONENABL_FUNC:
			return ["ECompOn", 1, 1]
		case MCC_NEUTRALIZATIONCAP_FUNC:
			return ["ECompMag", PICO_TO_ONE, 1]
		case MCC_WHOLECELLCOMPENABLE_FUNC:
			return ["RsCompOn", 1, 1]
		case MCC_WHOLECELLCOMPCAP_FUNC:
			return ["CmComp", PICO_TO_ONE, 1]
		case MCC_WHOLECELLCOMPRESIST_FUNC:
			return ["RsComp", MEGA_TO_ONE, 1]
		case MCC_AUTOWHOLECELLCOMP_FUNC:
			return ["AutoCellComp", 1, 1]
		case MCC_RSCOMPENABLE_FUNC:
			return ["RsCorrOn", 1, 1]
		case MCC_RSCOMPCORRECTION_FUNC:
			// in percent also without prefixes, the IPA control package uses fractions
			return ["RsCorr", 1, PERCENT_TO_ONE]
		case MCC_RSCOMPPREDICTION_FUNC:
			return ["RsPred", 1, PERCENT_TO_ONE]
		case MCC_PIPETTEOFFSET_FUNC:
			return ["Offset", MILLI_TO_ONE, 1]
		case MCC_AUTOPIPETTEOFFSET_FUNC:
			return ["AutoOffset", 1, 1]
		case MCC_FASTCOMPCAP_FUNC:
			return ["ECompMag", 1, 1]
		case MCC_FASTCOMPTAU_FUNC:
			return ["ECompTau", 1, 1]
		case MCC_AUTOFASTCOMP_FUNC:
			return ["AutoEComp", 1, 1]
		case MCC_PRIMARYSIGNALLPF_FUNC:
			return ["Filter", 1, 1]
		case MCC_AUTOBRIDGEBALANCE_FUNC: // fallthrough
		case MCC_RSCOMPBANDWIDTH_FUNC: // fallthrough
		case MCC_OSCKILLERENABLE_FUNC: // fallthrough
		case MCC_SLOWCOMPCAP_FUNC: // fallthrough
		case MCC_SLOWCOMPTAU_FUNC: // fallthrough
		case MCC_SLOWCOMPTAUX20ENAB_FUNC: // fallthrough
		case MCC_AUTOSLOWCOMP_FUNC: // fallthrough
		case MCC_SLOWCURRENTINJENABL_FUNC: // fallthrough
		case MCC_SLOWCURRENTINJLEVEL_FUNC: // fallthrough
		case MCC_SLOWCURRENTINJSETLT_FUNC: // fallthrough
		case MCC_PRIMARYSIGNALGAIN_FUNC: // fallthrough
		case MCC_SECONDARYSIGNALGAIN_FUNC: // fallthrough
		case MCC_PRIMARYSIGNALHPF_FUNC: // fallthrough
		case MCC_SECONDARYSIGNALLPF_FUNC:
			return ["", NaN, NaN]
		default:
			FATAL_ERROR("Invalid func: " + num2istr(func))
	endswitch
End

/// @brief Return true if `func` is an automatic function, which has no value to read or compare
static Function AI_SU_IsAutomaticFunction(variable func)

	switch(func)
		case MCC_AUTOWHOLECELLCOMP_FUNC: // fallthrough
		case MCC_AUTOPIPETTEOFFSET_FUNC: // fallthrough
		case MCC_AUTOFASTCOMP_FUNC:
			return 1
		default:
			return 0
	endswitch
End

#ifdef SUTTER_AMPLIFIER_PRESENT

/// @brief Initialize the Sutter amplifiers
///
/// Must only be called when no acquisition is running as it resets the USB connection.
///
/// @returns 0 on success, 1 on error
Function AI_SU_Initialize(string device)

	variable i, numProbes, clampMode

	PerformSubsystemEntry()

	if(!IPA_MIES_IsXOPCompatible())
		printf "(%s) The Sutter XOP is not compatible with the Sutter amplifier control procedures.\r", device
		ControlWindowToFront()
		return 1
	endif

	if(!IPA_Initialize() || !IPA_MIES_Connect())
		printf "(%s) Could not connect to the Sutter amplifiers.\r", device
		ControlWindowToFront()
		return 1
	endif

	// the stored control values of the package do not reflect the state of
	// the amplifiers, so send the state of MIES
	numProbes = AI_SU_GetNumberOfProbes()
	for(i = 0; i < numProbes; i += 1)
		if(AI_GetAmplifierType(device, i) != AMPLIFIER_TYPE_SUTTER)
			continue
		endif

		clampMode = DAG_GetHeadstageMode(device, i)
		AI_SU_SetClampMode(device, i, clampMode)
	endfor

	return 0
End

/// @brief Shutdown the Sutter amplifiers
Function AI_SU_Shutdown(string device)

	PerformSubsystemEntry()

	if(IPA_MIES_IsInitialized())
		IPA_Shutdown()
	endif
End

/// @brief Return the clamp mode of the headstage as read from the amplifier
///
/// @returns #V_CLAMP_MODE, #I_CLAMP_MODE or NaN if the amplifier can not be read
Function AI_SU_GetMode(string device, variable headstage)

	variable currentClamp

	PerformSubsystemEntry()

	currentClamp = IPA_MIES_ReadClampModeFromHardware(headstage + 1)
	if(IsNaN(currentClamp))
		return NaN
	endif

	return currentClamp ? I_CLAMP_MODE : V_CLAMP_MODE
End

/// @brief Return the holding command of the amplifier in the current clamp mode
///
/// @returns holding potential in mV (VC) or holding current in pA (IC), zero if the
///          holding is disabled and NaN if the amplifier can not be used
Function AI_SU_GetHoldingCommand(string device, variable headstage)

	PerformSubsystemEntry()

	if(AI_SU_SelectMultiClamp(device, headstage) != AMPLIFIER_CONNECTION_SUCCESS)
		return NaN
	endif

	switch(DAG_GetHeadstageMode(device, headstage))
		case V_CLAMP_MODE:
			// zero if disabled
			return IPA_GetValue(headstage + 1, "VHold") * ONE_TO_MILLI
		case I_CLAMP_MODE:
			return IPA_GetValue(headstage + 1, "IHold") * ONE_TO_PICO
		default:
			return NaN
	endswitch
End

/// @brief Set the clamp mode of the amplifier of the headstage
///
/// I=0 is not supported for Sutter amplifiers, therefore `zeroStep` is ignored. DAEphys
/// does not allow selecting it for Sutter devices.
///
/// Switching fails only for probes without amplifier or when the amplifier control package
/// is not initialized, which both must not happen for a locked Sutter device.
Function AI_SU_SetClampMode(string device, variable headstage, variable mode)

	string msg

	PerformSubsystemEntry()

	AI_AssertOnInvalidClampMode(mode)

	if(mode == I_EQUAL_ZERO_MODE)
		FATAL_ERROR("The clamp mode I=0 is not supported for Sutter amplifiers")
	endif

	if(!IPA_MIES_SetClampMode(headstage + 1, mode == I_CLAMP_MODE))
		sprintf msg, "The Sutter amplifier of headstage %d could not be switched to %s", headstage, ConvertAmplifierModeToString(mode)
		FATAL_ERROR(msg)
	endif
End

/// @brief Set the clamp mode of the amplifier to the clamp mode stored in MIES
///
/// @returns 0 on success, 1 when the amplifier can not be used
Function AI_SU_EnsureCorrectMode(string device, variable headstage)

	variable storedMode, setMode

	PerformSubsystemEntry()

	setMode = AI_SU_GetMode(device, headstage)
	if(IsNaN(setMode))
		return 1
	endif

	storedMode = DAG_GetHeadstageMode(device, headstage)
	if(setMode != storedMode)
		print "There was a mismatch in clamp mode between MIES and the Sutter amplifier. The amplifier mode was switched to match the mode specified by MIES."
		AI_SU_SetClampMode(device, headstage, storedMode)
	endif

	return 0
End

/// @brief Check that the amplifier of the headstage can be used
///
/// There is nothing to select as the amplifiers are addressed by their probe index.
///
/// @returns one of @ref AISelectMultiClampReturnValues, #AMPLIFIER_CONNECTION_MCC_FAILED
///          if the amplifiers are not connected
Function AI_SU_SelectMultiClamp(string device, variable headstage)

	PerformSubsystemEntry()

	if(headstage >= AI_SU_GetNumberOfProbes())
		return AMPLIFIER_CONNECTION_INVAL_SER
	endif

	if(!IPA_OkToSendCommand())
		return AMPLIFIER_CONNECTION_MCC_FAILED
	endif

	return AMPLIFIER_CONNECTION_SUCCESS
End

/// @brief Generic interface to call Sutter amplifier functions
///
/// See AI_SendToAmp() for the parameters. Setting a value does not change its
/// enable state, see IPA_MIES_SetValue().
///
/// @returns return value (for getters, respects `usePrefixes`), success (`0`) or error (`NaN`).
Function AI_SU_SendToAmp(string device, variable headStage, variable mode, variable func, variable accessType, variable checkBeforeWrite, variable usePrefixes, variable selectAmp, variable value)

	variable prefixScale, unitScale, scale, ret, current, success
	string setting, str

	PerformSubsystemEntry()

	ASSERT(func > MCC_BEGIN_INVALID_FUNC && func < MCC_END_INVALID_FUNC, "Function constant is out for range")
	ASSERT(IsValidHeadstage(headstage), "invalid headStage index")
	AI_AssertOnInvalidClampMode(mode)
	ASSERT(accessType == MCC_READ || accessType == MCC_WRITE, "Invalid access type")

	if(accessType == MCC_READ)
		ASSERT(IsNaN(value), "Can't pass value for reading")
		ASSERT(!checkBeforeWrite, "Can't use checkBeforeWrite for reading")
	endif

	if(mode == I_EQUAL_ZERO_MODE || DAG_GetHeadstageMode(device, headStage) != mode)
		return NaN
	endif

	[setting, prefixScale, unitScale] = AI_SU_GetSetting(func, mode)

	if(IsEmpty(setting))
		DEBUGPRINT("Unsupported function for Sutter amplifiers: " + num2istr(func))
		return NaN
	endif

	if(selectAmp)
		if(AI_SU_SelectMultiClamp(device, headstage) != AMPLIFIER_CONNECTION_SUCCESS)
			return NaN
		endif
	endif

	if(AI_SU_EnsureCorrectMode(device, headStage))
		return NaN
	endif

	scale = (usePrefixes ? prefixScale : 1) * unitScale

	sprintf str, "headStage=%d, mode=%d, func=%d, setting=%s, value(passed)=%g, scale=%g\r", headStage, mode, func, setting, value, scale
	DEBUGPRINT(str)

	if(accessType == MCC_READ)
		ret = IPA_MIES_GetValue(headstage + 1, setting)

		return ret / scale
	endif

	if(checkBeforeWrite && !AI_SU_IsAutomaticFunction(func))
		current = IPA_MIES_GetValue(headstage + 1, setting)

		// Don't send the value if it is equal to the current value, with tolerance
		// being 1% of the reference value, or if it is zero and the current value is
		// smaller than DEFAULT_TOL.
		if(CheckIfClose(current, value * scale, tol = 1e-2 * abs(current), strong_or_weak = 1) || (value == 0 && CheckIfSmall(current, tol = DEFAULT_TOL)))
			DEBUGPRINT("The value to be set is equal to the current value, skip setting it: " + num2istr(func))
			return 0
		endif
	endif

	success = IPA_MIES_SetValue(headstage + 1, setting, value * scale)

	if(success)
		strswitch(setting)
			case "AutoOffset":
				// return the new offset, as done for MCC amplifiers
				[setting, prefixScale, unitScale] = AI_SU_GetSetting(MCC_PIPETTEOFFSET_FUNC, mode)
				ret                               = IPA_MIES_GetValue(headstage + 1, setting) / ((usePrefixes ? prefixScale : 1) * unitScale)
				break
			default:
				ret = 0
				break
		endswitch
	else
		ret = NaN
	endif

	PUB_AmplifierSettingChange(device, headstage, mode, func, value)

	if(!IsFinite(ret))
		printf "(%s) The setting \"%s\" could not be sent to the Sutter amplifier of headstage %d.\r", device, setting, headstage
		ControlWindowToFront()
	endif

	return ret
End

#else // SUTTER_AMPLIFIER_PRESENT

Function AI_SU_Initialize(string device)

	PerformSubsystemEntry()

	DEBUGPRINT("Unimplemented")

	return 1
End

Function AI_SU_Shutdown(string device)

	PerformSubsystemEntry()

	DEBUGPRINT("Unimplemented")
End

Function AI_SU_GetMode(string device, variable headstage)

	PerformSubsystemEntry()

	DEBUGPRINT("Unimplemented")

	return NaN
End

Function AI_SU_GetHoldingCommand(string device, variable headstage)

	PerformSubsystemEntry()

	DEBUGPRINT("Unimplemented")

	return NaN
End

Function AI_SU_SetClampMode(string device, variable headstage, variable mode)

	PerformSubsystemEntry()

	DEBUGPRINT("Unimplemented")
End

Function AI_SU_EnsureCorrectMode(string device, variable headstage)

	PerformSubsystemEntry()

	DEBUGPRINT("Unimplemented")

	return 1
End

Function AI_SU_SelectMultiClamp(string device, variable headstage)

	PerformSubsystemEntry()

	DEBUGPRINT("Unimplemented")

	return AMPLIFIER_CONNECTION_INVAL_SER
End

Function AI_SU_SendToAmp(string device, variable headStage, variable mode, variable func, variable accessType, variable checkBeforeWrite, variable usePrefixes, variable selectAmp, variable value)

	PerformSubsystemEntry()

	DEBUGPRINT("Unimplemented")

	return NaN
End

#endif // SUTTER_AMPLIFIER_PRESENT
