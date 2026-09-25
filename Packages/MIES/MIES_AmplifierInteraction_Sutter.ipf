#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors = 1

#ifdef AUTOMATED_TESTING
#pragma ModuleName = MIES_AISU
#endif // AUTOMATED_TESTING

/// @file MIES_AmplifierInteraction_Sutter.ipf
/// @brief __AISU__ Interface with the amplifiers integrated in the Sutter IPA devices
///
/// The amplifier headstages are addressed by their probe index, which is the
/// zero-based index of the headstage over all IPA devices in the order of
/// `LISTOFDEVICES` from GetSUDeviceInfo(). The MIES headstage with the same
/// index is fixed to that amplifier headstage.

static StrConstant AMPLIFIER_DEF_FORMAT = "%s HS %d"

// IPA_Control.ipf is only included with the Sutter XOP, see MIES_Include.ipf
#if exists("SutterDAQScanWave")
#define SUTTER_AMPLIFIER_PRESENT
#endif

/// @brief Return the number of amplifier headstages of all IPA devices
static Function AISU_GetNumberOfProbes()

	WAVE/T deviceInfo = GetSUDeviceInfo()

	variable numProbes = str2num(deviceInfo[%SUMHEADSTAGES])

	return IsFinite(numProbes) ? numProbes : 0
End

/// @brief Return the IPA device serial and the one-based headstage number on that device
///        of the given probe index
static Function [string serial, variable deviceHeadstage] AISU_GetDeviceHeadstageFromProbe(variable probeIndex)

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
static Function AISU_GetProbeFromDeviceHeadstage(string serial, variable deviceHeadstage)

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
Function AISU_FindConnectedAmps()

	PerformSubsystemEntry()

	return AISU_GetNumberOfProbes()
End

/// @brief Return a nicely layouted list of the amplifier headstages of all IPA devices
Function/S AISU_GetAmplifierList()

	variable i, numProbes
	string list

	PerformSubsystemEntry()

	list = AddListItem(NONE, "", ";", Inf)

	numProbes = AISU_GetNumberOfProbes()
	for(i = 0; i < numProbes; i += 1)
		list = AddListItem(AISU_GetAmplifierDef(i), list, ";", Inf)
	endfor

	return list
End

/// @brief Return the amplifier list entry for the given probe index
Function/S AISU_GetAmplifierDef(variable probeIndex)

	string str, serial
	variable deviceHeadstage

	PerformSubsystemEntry()

	[serial, deviceHeadstage] = AISU_GetDeviceHeadstageFromProbe(probeIndex)

	sprintf str, AMPLIFIER_DEF_FORMAT, serial, deviceHeadstage

	return str
End

/// @brief Parse the entries which AISU_GetAmplifierDef() created
///
/// @returns probe index
Function AISU_ParseAmplifierDef(string amplifierDef)

	string   serial
	variable deviceHeadstage

	PerformSubsystemEntry()

	sscanf amplifierDef, AMPLIFIER_DEF_FORMAT, serial, deviceHeadstage
	ASSERT(V_flag == 2, "Unexpected amplifier popup list format")

	return AISU_GetProbeFromDeviceHeadstage(serial, deviceHeadstage)
End

#ifdef SUTTER_AMPLIFIER_PRESENT

/// @brief Initialize the Sutter amplifiers
///
/// Must only be called when no acquisition is running as it resets the USB connection.
///
/// @returns 0 on success, 1 on error
Function AISU_Initialize(string device)

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
	numProbes = AISU_GetNumberOfProbes()
	for(i = 0; i < numProbes; i += 1)
		if(AI_GetAmplifierType(device, i) != AMPLIFIER_TYPE_SUTTER)
			continue
		endif

		clampMode = DAG_GetHeadstageMode(device, i)
		AISU_SetClampMode(device, i, clampMode)
	endfor

	return 0
End

/// @brief Shutdown the Sutter amplifiers
Function AISU_Shutdown(string device)

	PerformSubsystemEntry()

	if(IPA_MIES_IsInitialized())
		IPA_Shutdown()
	endif
End

/// @brief Return the clamp mode of the headstage as read from the amplifier
///
/// @returns #V_CLAMP_MODE, #I_CLAMP_MODE or NaN if the amplifier can not be read
Function AISU_GetMode(string device, variable headstage)

	variable currentClamp

	PerformSubsystemEntry()

	currentClamp = IPA_MIES_ReadClampModeFromHardware(headstage + 1)
	if(IsNaN(currentClamp))
		return NaN
	endif

	return currentClamp ? I_CLAMP_MODE : V_CLAMP_MODE
End

/// @brief Set the clamp mode of the amplifier of the headstage
///
/// I=0 is not supported for Sutter amplifiers, therefore `zeroStep` is ignored. DAEphys
/// does not allow selecting it for Sutter devices.
///
/// Switching fails only for probes without amplifier or when the amplifier control package
/// is not initialized, which both must not happen for a locked Sutter device.
Function AISU_SetClampMode(string device, variable headstage, variable mode)

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
Function AISU_EnsureCorrectMode(string device, variable headstage)

	variable storedMode, setMode

	PerformSubsystemEntry()

	setMode = AISU_GetMode(device, headstage)
	if(IsNaN(setMode))
		return 1
	endif

	storedMode = DAG_GetHeadstageMode(device, headstage)
	if(setMode != storedMode)
		print "There was a mismatch in clamp mode between MIES and the Sutter amplifier. The amplifier mode was switched to match the mode specified by MIES."
		AISU_SetClampMode(device, headstage, storedMode)
	endif

	return 0
End

#else // SUTTER_AMPLIFIER_PRESENT

Function AISU_Initialize(string device)

	PerformSubsystemEntry()

	DEBUGPRINT("Unimplemented")

	return 1
End

Function AISU_Shutdown(string device)

	PerformSubsystemEntry()

	DEBUGPRINT("Unimplemented")
End

Function AISU_GetMode(string device, variable headstage)

	PerformSubsystemEntry()

	DEBUGPRINT("Unimplemented")

	return NaN
End

Function AISU_SetClampMode(string device, variable headstage, variable mode)

	PerformSubsystemEntry()

	DEBUGPRINT("Unimplemented")
End

Function AISU_EnsureCorrectMode(string device, variable headstage)

	PerformSubsystemEntry()

	DEBUGPRINT("Unimplemented")

	return 1
End

#endif // SUTTER_AMPLIFIER_PRESENT
