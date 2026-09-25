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
