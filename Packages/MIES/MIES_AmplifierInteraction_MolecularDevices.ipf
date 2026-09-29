#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors = 1

#ifdef AUTOMATED_TESTING
#pragma ModuleName = MIES_AIMCC
#endif // AUTOMATED_TESTING

/// @file MIES_AmplifierInteraction_MolecularDevices.ipf
/// @brief __AIMCC__ Interface with the Axon/MCC amplifiers

static Constant NUM_TRIES_AXON_TELEGRAPH = 10

static StrConstant AMPLIFIER_DEF_FORMAT = "AmpNo %d Chan %d"

#if exists("MCC_GetMode") && exists("AxonTelegraphGetDataStruct")
#define AMPLIFIER_XOPS_PRESENT
#endif

static Function AIMCC_InitAxonTelegraphStruct(STRUCT AxonTelegraph_DataStruct &tds)

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
static Function AIMCC_GetAmpAxonSerial(string device, variable headStage)

	WAVE ChanAmpAssign = GetChanAmpAssign(device)

	return ChanAmpAssign[%AmpSerialNo][headStage]
End

/// @brief Returns the serial number of the headstage compatible with MCC* functions, @see GetChanAmpAssign
static Function/S AIMCC_GetAmpMCCSerial(string device, variable headStage)

	variable axonSerial
	string   mccSerial

	axonSerial = AIMCC_GetAmpAxonSerial(device, headStage)

	if(axonSerial == 0)
		return "Demo"
	endif

	sprintf mccSerial, "%08d", axonSerial
	return mccSerial
End

///@brief Return the channel of the currently selected head stage
static Function AIMCC_GetAmpChannel(string device, variable headStage)

	WAVE ChanAmpAssign = GetChanAmpAssign(device)

	return ChanAmpAssign[%AmpChannelID][headStage]
End

static Function AIMCC_IsValidSerialAndChannel([string mccSerial, variable axonSerial, variable channel])

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

static Function AIMCC_AssertOnInvalidAccessType(variable accessType)

	ASSERT(accessType == MCC_READ || accessType == MCC_WRITE, "Invalid accessType")
End

/// @brief Return the unit prefixes used by MIES in comparison to the MCC app
///
/// @param clampMode  clamp mode (pass `NaN` for doesn't matter)
/// @param func       MCC function, one of @ref AI_SendToAmpConstants
/// @param accessType One of @ref MCCAccessType
static Function AIMCC_GetMCCScale(variable clampMode, variable func, variable accessType)

	AIMCC_AssertOnInvalidAccessType(accessType)

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

/// @brief Update the settings which the MCC amplifier changed as a side effect of writing `func`
///
/// @param device    device
/// @param headStage MIES headstage number, must be in the range [0, NUM_HEADSTAGES[
/// @param func      Function which was written, see @ref AI_SendToAmpConstants
/// @param clampMode clamp mode of `func`
Function AIMCC_UpdateDependentSettings(string device, variable headStage, variable func, variable clampMode)

	variable oppositeMode, oldTab, value
	string rowLabel

	PerformSubsystemEntry()

	switch(func)
		case MCC_AUTOPIPETTEOFFSET_FUNC:
			oppositeMode = AIMCC_GetOppositeClampAmpMode(clampMode)

			WAVE AmpStorageWave = GetAmplifierParamStorageWave(device)

			// the pipette offset for the opposite mode has also changed, fetch that too
			AssertOnAndClearRTError()
			try
				oldTab = GetTabID(device, "ADC")
				if(oldTab != 0)
					PGC_SetAndActivateControl(device, "ADC", val = 0)
				endif

				DAP_ChangeHeadStageMode(device, oppositeMode, headstage, MCC_SKIP_UPDATES)

				func     = MCC_PIPETTEOFFSET_FUNC
				rowLabel = AI_MapFunctionConstantToName(func, oppositeMode)

				// selecting amplifier here, as the clamp mode is now different
				value                                    = AIMCC_SendToAmp(device, headstage, oppositeMode, func, MCC_READ, selectAmp = 1)
				AmpStorageWave[%$rowLabel][0][headstage] = value
				AI_UpdateAmpView(device, headstage, func = func, clampMode = oppositeMode)
				DAP_ChangeHeadStageMode(device, clampMode, headstage, MCC_SKIP_UPDATES)

				if(oldTab != 0)
					PGC_SetAndActivateControl(device, "ADC", val = oldTab)
				endif
			catch
				ClearRTError()
				if(DAG_GetNumericalValue(device, "check_Settings_SyncMiesToMCC"))
					printf "(%s) The pipette offset for %s of headstage %d is invalid.\r", device, ConvertAmplifierModeToString(oppositeMode), headstage
				endif
				// do nothing
			endtry
			break
		default:
			break
	endswitch
End

/// @brief Query the MCC application for the gains and units of the given clamp mode
///
/// Assumes that the correct amplifier is already selected!
Function [variable DAGain, variable ADGain, string DAUnit, string ADUnit] AIMCC_QueryGainsUnitsForClampMode(string device, variable headstage, variable clampMode)

	PerformSubsystemEntry()

	DAGain = NaN
	ADGain = NaN
	DAUnit = ""
	ADUnit = ""

	AI_AssertOnInvalidClampMode(clampMode)

	[ADGain, DAGain] = AIMCC_RetrieveGains(device, headstage, clampMode)

	if(clampMode == V_CLAMP_MODE)
		DAUnit = "mV"
		ADUnit = "pA"
	else
		DAUnit = "pA"
		ADUnit = "mV"
	endif

	return [DAGain, ADGain, DAUnit, ADUnit]
End

/// @brief Opens Multi-clamp commander software
///
/// @param ampSerialNumList A text list of amplifier serial numbers without leading zeroes
/// Ex. "834001;435003;836059", "0;" starts the MCC in Demo mode
/// Duplicate serial numbers are ignored as well as amplifier titles for the duplicates.
/// For each unique serial number one MCC is opened.
/// @param ampTitleList MCC gui window title list, can be empty
/// @return 1 if all unique MCCs specified in ampSerialNumList were opened, 0 if one or more MCCs specified in ampSerialNumList were not able to be opened
Function AIMCC_OpenMCCs(string ampSerialNumList, string ampTitleList)

	string cmd, serialStr, title
	variable i, j, numDups, serialNum, failedToOpenCount
	variable ItemsInAmpSerialNumList
	variable maxAttempts = 3

	PerformSubsystemEntry()

	ItemsInAmpSerialNumList = ItemsInList(AmpSerialNumList)

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

	WAVE OpenMCCList = AIMCC_GetMCCSerialNumbers()
	do
		for(i = 0; i < ItemsInAmpSerialNumList; i += 1)
			serialStr = stringfromlist(i, AmpSerialNumList)
			serialNum = str2num(serialStr)
			title     = stringfromlist(i, AmpTitleList)
			findvalue/I=(serialNum) OpenMCCList
			if(V_value == -1)
				if(!serialNum)
					sprintf cmd, "\"%s\" /T%s(%s)", AIMCC_GetMCCWinFilePath(), title, SerialStr
				else
					sprintf cmd, "\"%s\" /S00%g /T%s(%s)", AIMCC_GetMCCWinFilePath(), SerialNum, title, SerialStr
				endif
				executeScriptText cmd
			endif
		endfor

		failedToOpenCount = 0
		WAVE OpenMCCList = AIMCC_GetMCCSerialNumbers()
		for(i = 0; i < ItemsInAmpSerialNumList; i += 1)
			serialStr = StringFromList(i, AmpSerialNumList)
			serialNum = str2num(serialStr)
			findvalue/I=(serialNum) OpenMCCList
			if(v_value == -1)
				failedToOpenCount += 1
			endif
		endfor

		if(failedToOpenCount > 0)
			printf "%g MCCs failed to open on attempt count %g\r", failedToOpenCount, j
			ControlWindowToFront()
		endif

		j += 1
	while(failedToOpenCount != 0 && j < maxAttempts)

	return failedToOpenCount == 0
End

/// @brief Gets the serial numbers of all open MCCs
///
/// @return a 1D FREE wave containing amplifier serial numbers without leading zeroes
static Function/WAVE AIMCC_GetMCCSerialNumbers()

	AIMCC_FindConnectedAmps(1)
	WAVE W_TelegraphServers = GetAmplifierTelegraphServers()
	Duplicate/FREE/R=[][FindDimLabel(W_TelegraphServers, COLS, "SerialNum")] W_TelegraphServers, OpenMCCList
	return GetUniqueEntries(OpenMCCList)
End

/// @brief Return a path to the MCC.
///
/// Hardcoded as Igor does not allow to query that information.
///
/// Distinguishes between i386 and x64 Igor versions
static Function/S AIMCC_GetMCCWinFilePath()

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

/// @brief Return a nicely layouted list of amplifier channels
Function/S AIMCC_GetAmplifierList()

	PerformSubsystemEntry()

	WAVE telegraphServers = GetAmplifierTelegraphServers()

	if(!DimSize(telegraphServers, ROWS))
		return AddListItem("\\M1(MC not available", NONE, ";", Inf)
	endif

	return AddListItem(AIMCC_FormatTelegraphServerList(telegraphServers), NONE, ";", Inf)
End

static Function/S AIMCC_FormatTelegraphServerList(WAVE telegraphServers)

	variable i, numRows
	string str
	string list = ""

	numRows = DimSize(telegraphServers, ROWS)
	for(i = 0; i < numRows; i += 1)
		str  = AIMCC_GetAmplifierDef(telegraphServers[i][0], telegraphServers[i][1])
		list = AddListItem(str, list, ";", Inf)
	endfor

	return list
End

/// @brief Return the amplifier list entry for the given amplifier serial and channel
Function/S AIMCC_GetAmplifierDef(variable ampSerial, variable ampChannel)

	string str

	PerformSubsystemEntry()

	sprintf str, AMPLIFIER_DEF_FORMAT, ampSerial, ampChannel

	return str
End

/// @brief Parse the entries which AIMCC_GetAmplifierDef() created
Function [variable ampSerial, variable ampChannelID] AIMCC_ParseAmplifierDef(string amplifierDef)

	PerformSubsystemEntry()

	ampSerial    = NaN
	ampChannelID = NaN

	if(!cmpstr(amplifierDef, NONE))
		return [ampSerial, ampChannelID]
	endif

	sscanf amplifierDef, AMPLIFIER_DEF_FORMAT, ampSerial, ampChannelID
	ASSERT(V_Flag == 2, "Unexpected amplifier popup list format")

	return [ampSerial, ampChannelID]
End

#ifdef AMPLIFIER_XOPS_PRESENT

///@brief Returns the holding command of the amplifier
Function AIMCC_GetHoldingCommand(string device, variable headstage)

	PerformSubsystemEntry()

	if(AIMCC_SelectMultiClamp(device, headstage) != AMPLIFIER_CONNECTION_SUCCESS)
		return NaN
	endif

	return MCC_GetHoldingEnable() ? (MCC_GetHolding() * AIMCC_GetMCCScale(MCC_GetMode(), MCC_HOLDING_FUNC, MCC_READ)) : 0
End

/// @brief Return the clamp mode of the headstage as returned by the amplifier
///
/// Should only be used during the setup phase when you don't know if the
/// clamp mode in MIES matches already. It is always better to prefer
/// DAP_ChangeHeadStageMode() if possible.
///
/// @brief One of @ref AmplifierClampModes or NaN if no amplifier is connected
Function AIMCC_GetMode(string device, variable headstage)

	PerformSubsystemEntry()

	if(AIMCC_SelectMultiClamp(device, headstage) != AMPLIFIER_CONNECTION_SUCCESS)
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
/// @retval     ADGain     ADC gain
/// @retval     DAGain     DAC gain
static Function [variable ADGain, variable DAGain] AIMCC_RetrieveGains(string device, variable headstage, variable clampMode)

	variable axonSerial = AIMCC_GetAmpAxonSerial(device, headstage)
	variable channel    = AIMCC_GetAmpChannel(device, headStage)

	[STRUCT AxonTelegraph_DataStruct tds] = AIMCC_GetTelegraphStruct(axonSerial, channel)

	ASSERT(clampMode == tds.OperatingMode, "Non matching clamp mode from MCC application")

	ADGain    = tds.ScaleFactor * tds.Alpha / ONE_TO_MILLI
	clampMode = tds.OperatingMode

	if(tds.OperatingMode == V_CLAMP_MODE)
		DAGain = tds.ExtCmdSens * ONE_TO_MILLI
	elseif(tds.OperatingMode == I_CLAMP_MODE || tds.OperatingMode == I_EQUAL_ZERO_MODE)
		DAGain = tds.ExtCmdSens * ONE_TO_PICO
	endif

	return [ADGain, DAGain]
End

/// @brief Return the opposite clamp mode depending on the current one
static Function AIMCC_GetOppositeClampAmpMode(variable mode)

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
Function AIMCC_SelectMultiClamp(string device, variable headStage)

	variable channel, axonSerial, err
	string mccSerial

	PerformSubsystemEntry()

	// checking axonSerial is done as a service to the caller
	axonSerial = AIMCC_GetAmpAxonSerial(device, headStage)
	mccSerial  = AIMCC_GetAmpMCCSerial(device, headStage)
	channel    = AIMCC_GetAmpChannel(device, headStage)

	if(!AIMCC_IsValidSerialAndChannel(mccSerial = mccSerial, axonSerial = axonSerial, channel = channel))
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
///
/// @param device    device
/// @param headStage MIES headstage number, must be in the range [0, NUM_HEADSTAGES[
/// @param mode      clamp mode to set
/// @param zeroStep  switch via I=0 to the target clamp mode
/// @param selectAmp select the amplifier before use
Function AIMCC_SetClampMode(string device, variable headStage, variable mode, variable zeroStep, variable selectAmp)

	PerformSubsystemEntry()

	AI_AssertOnInvalidClampMode(mode)

	if(selectAmp)
		if(AIMCC_SelectMultiClamp(device, headStage) != AMPLIFIER_CONNECTION_SUCCESS)
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
Function AIMCC_SendToAmp(string device, variable headStage, variable mode, variable func, variable accessType, [variable checkBeforeWrite, variable usePrefixes, variable selectAmp, variable value])

	variable ret, headstageMode, scale, nonScaledValue
	string str

	PerformSubsystemEntry()

	ASSERT(func > MCC_BEGIN_INVALID_FUNC && func < MCC_END_INVALID_FUNC, "MCC function constant is out for range")
	ASSERT(IsValidHeadstage(headstage), "invalid headStage index")
	AI_AssertOnInvalidClampMode(mode)
	AIMCC_AssertOnInvalidAccessType(accessType)

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
		scale = AIMCC_GetMCCScale(mode, func, accessType)
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
		if(AIMCC_SelectMultiClamp(device, headstage) != AMPLIFIER_CONNECTION_SUCCESS)
			return NaN
		endif
	endif

	AIMCC_EnsureCorrectMode(device, headStage, 0)

	sprintf str, "headStage=%d, mode=%d, func=%d, value(passed)=%g, scale=%g\r", headStage, mode, func, value, scale
	DEBUGPRINT(str)

	nonScaledValue = value
	value         *= scale

	if(checkBeforeWrite)
		ret = AIMCC_ReadFromMCC(func)

		// Don't send the value if it is equal to the current value, with tolerance
		// being 1% of the reference value, or if it is zero and the current value is
		// smaller than DEFAULT_TOL.
		if(CheckIfClose(ret, value, tol = 1e-2 * abs(ret), strong_or_weak = 1) || (value == 0 && CheckIfSmall(ret, tol = DEFAULT_TOL)))
			DEBUGPRINT("The value to be set is equal to the current value, skip setting it: " + num2str(func))
			return 0
		endif
	endif

	switch(func)
		case MCC_AUTOBRIDGEBALANCE_FUNC:
			ret = AIMCC_WriteToMCC(func, NaN)
			// the bridge balance resistance is unchanged on failure
			if(!IsFinite(ret))
				break
			endif

			ret = AIMCC_SendToAmp(device, headstage, mode, MCC_BRIDGEBALRESIST_FUNC, MCC_READ, selectAmp = 0)
			PUB_AutoBridgeBalance(device, headstage, ret)
			break
		case MCC_AUTOPIPETTEOFFSET_FUNC:
			AIMCC_WriteToMCC(func, NaN)
			ret = AIMCC_SendToAmp(device, headStage, mode, MCC_PIPETTEOFFSET_FUNC, MCC_READ, selectAmp = 0)
			break
		default:
			if(accessType == MCC_READ)
				ret = AIMCC_ReadFromMCC(func)
			else
				ret = AIMCC_WriteToMCC(func, value)
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

static Function AIMCC_ReadFromMCC(variable func)

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

static Function AIMCC_WriteToMCC(variable func, variable value)

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
/// @param headStage  headstage
/// @param selectAmp  selects the amplifier before using, some callers might be able to skip it.
///
/// @return 0 on success, 1 when the headstage does not have an amplifier connected or it could not be selected
Function AIMCC_EnsureCorrectMode(string device, variable headStage, variable selectAmp)

	variable serial, channel, storedMode, setMode, ampConnectionState

	PerformSubsystemEntry()

	serial  = AIMCC_GetAmpAxonSerial(device, headStage)
	channel = AIMCC_GetAmpChannel(device, headStage)

	if(!AIMCC_IsValidSerialAndChannel(channel = channel, axonSerial = serial))
		return 1
	endif

	if(selectAmp)
		ampConnectionState = AIMCC_SelectMultiClamp(device, headstage)
		if(ampConnectionState != AMPLIFIER_CONNECTION_SUCCESS)
			return 1
		endif
	endif

	[STRUCT AxonTelegraph_DataStruct tds] = AIMCC_GetTelegraphStruct(serial, channel)

	storedMode = DAG_GetHeadstageMode(device, headStage)
	setMode    = tds.operatingMode

	if(setMode != storedMode)
		print "There was a mismatch in clamp mode between MIES and the MCC. The MCC mode was switched to match the mode specified by MIES."
		AIMCC_SetClampMode(device, headStage, storedMode, 0, 0)
	endif

	return 0
End

/// @brief Fill the amplifier settings wave by querying the MC700B and send the data to ED_AddEntriesToLabnotebook
///
/// @param device 		 device
/// @param sweepNo           data wave sweep number
Function AIMCC_FillAndSendAmpliferSettings(string device, variable sweepNo)

	variable i, axonSerial, channel, ampConnState, clampMode
	string mccSerial

	PerformSubsystemEntry()

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

		mccSerial  = AIMCC_GetAmpMCCSerial(device, i)
		axonSerial = AIMCC_GetAmpAxonSerial(device, i)
		channel    = AIMCC_GetAmpChannel(device, i)

		ampConnState = AIMCC_SelectMultiClamp(device, i)

		if(ampConnState != AMPLIFIER_CONNECTION_SUCCESS)
			if(DAG_GetNumericalValue(device, "check_Settings_RequireAmpConn"))
				BUG("The amplifier could not be selected, but that should work, ampConnState = " + num2str(ampConnState))
				BUG("Please report that as a bug with a description what you did. Thanks!")
			endif
			continue
		endif

		clampMode = DAG_GetHeadstageMode(device, i)
		AI_AssertOnInvalidClampMode(clampMode)

		[STRUCT AxonTelegraph_DataStruct tds] = AIMCC_GetTelegraphStruct(axonSerial, channel)

		ASSERT(clampMode == tds.OperatingMode, "A clamp mode mismatch was detected. Please describe the events leading up to that assertion. Thanks!")

		if(clampMode == V_CLAMP_MODE)
			ampSettingsWave[0][0][i]  = MCC_GetHoldingEnable()
			ampSettingsWave[0][1][i]  = MCC_GetHolding() * AIMCC_GetMCCScale(V_CLAMP_MODE, MCC_HOLDING_FUNC, MCC_READ)
			ampSettingsWave[0][2][i]  = MCC_GetOscKillerEnable()
			ampSettingsWave[0][3][i]  = MCC_GetRsCompBandwidth() * AIMCC_GetMCCScale(V_CLAMP_MODE, MCC_RSCOMPBANDWIDTH_FUNC, MCC_READ)
			ampSettingsWave[0][4][i]  = MCC_GetRsCompCorrection()
			ampSettingsWave[0][5][i]  = MCC_GetRsCompEnable()
			ampSettingsWave[0][6][i]  = MCC_GetRsCompPrediction()
			ampSettingsWave[0][7][i]  = MCC_GetWholeCellCompEnable()
			ampSettingsWave[0][8][i]  = MCC_GetWholeCellCompCap() * AIMCC_GetMCCScale(V_CLAMP_MODE, MCC_WHOLECELLCOMPCAP_FUNC, MCC_READ)
			ampSettingsWave[0][9][i]  = MCC_GetWholeCellCompResist() * AIMCC_GetMCCScale(V_CLAMP_MODE, MCC_WHOLECELLCOMPRESIST_FUNC, MCC_READ)
			ampSettingsWave[0][39][i] = MCC_GetFastCompCap()
			ampSettingsWave[0][40][i] = MCC_GetSlowCompCap()
			ampSettingsWave[0][41][i] = MCC_GetFastCompTau()
			ampSettingsWave[0][42][i] = MCC_GetSlowCompTau()
		elseif(clampMode == I_CLAMP_MODE || clampMode == I_EQUAL_ZERO_MODE)
			ampSettingsWave[0][10][i] = MCC_GetHoldingEnable()
			ampSettingsWave[0][11][i] = MCC_GetHolding() * AIMCC_GetMCCScale(I_CLAMP_MODE, MCC_HOLDING_FUNC, MCC_READ)
			ampSettingsWave[0][12][i] = MCC_GetNeutralizationEnable()
			ampSettingsWave[0][13][i] = MCC_GetNeutralizationCap() * AIMCC_GetMCCScale(I_CLAMP_MODE, MCC_NEUTRALIZATIONCAP_FUNC, MCC_READ)
			ampSettingsWave[0][14][i] = MCC_GetBridgeBalEnable()
			ampSettingsWave[0][15][i] = MCC_GetBridgeBalResist() * AIMCC_GetMCCScale(I_CLAMP_MODE, MCC_BRIDGEBALRESIST_FUNC, MCC_READ)
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
		ampSettingsWave[0][35][i] = MCC_GetPipetteOffset() * AIMCC_GetMCCScale(NaN, MCC_PIPETTEOFFSET_FUNC, MCC_READ)
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
Function AIMCC_QueryGainsFromMCC(string device)

	variable clampMode, old_ClampMode, i, numConnAmplifiers
	variable DAGain, ADGain
	string DAUnit, ADUnit

	PerformSubsystemEntry()

	for(i = 0; i < NUM_HEADSTAGES; i += 1)

		if(AIMCC_SelectMultiClamp(device, i) != AMPLIFIER_CONNECTION_SUCCESS)
			continue
		endif

		numConnAmplifiers += 1

		clampMode = DAG_GetHeadstageMode(device, i)

		DAP_ChangeHeadStageMode(device, clampMode, i, MCC_SKIP_UPDATES)

		AI_AssertOnInvalidClampMode(clampMode)

		[DAGain, ADGain, DAUnit, ADUnit] = AIMCC_QueryGainsUnitsForClampMode(device, i, clampMode)
		AI_UpdateChanAmpAssign(device, i, clampMode, DAGain, ADGain, DAUnit, ADUnit)

		AI_WriteToAmplifier(device, i, clampMode, MCC_HOLDINGENABLE_FUNC, 0, checkBeforeWrite = 0, selectAmp = 0, GUIWrite = 1)

		old_clampMode = clampMode
		clampMode     = AIMCC_GetOppositeClampAmpMode(old_clampMode)

		DAP_ChangeHeadStageMode(device, clampMode, i, MCC_SKIP_UPDATES)

		[DAGain, ADGain, DAUnit, ADUnit] = AIMCC_QueryGainsUnitsForClampMode(device, i, clampMode)
		AI_UpdateChanAmpAssign(device, i, clampMode, DAGain, ADGain, DAUnit, ADUnit)

		AI_WriteToAmplifier(device, i, clampMode, MCC_HOLDINGENABLE_FUNC, 0, checkBeforeWrite = 0, selectAmp = 0, GUIWrite = 1)

		DAP_ChangeHeadStageMode(device, old_clampMode, i, MCC_SKIP_UPDATES)
	endfor

	return numConnAmplifiers
End

/// @brief Return the number of connected amplifiers
///
/// @param rescanHardware rescan the hardware instead of using cached results
Function AIMCC_FindConnectedAmps(variable rescanHardware)

	string key

	PerformSubsystemEntry()

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
			[WAVE telegraphServers, WAVE ampMCC] = AIMCC_FindConnectedAmpsNoCache()

			Make/FREE/WAVE cache = {telegraphServers, ampMCC}

			CA_StoreEntryIntoCache(key, cache)
		endif
	endif

	ASSERT(DimSize(telegraphServers, ROWS) == DimSize(ampMCC, ROWS), "Non-matched number of amplifiers")

	return DimSize(telegraphServers, ROWS)
End

/// @brief Create the amplifier connection waves
static Function [WAVE telegraphServers, WAVE ampMCC] AIMCC_FindConnectedAmpsNoCache()

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

	list = AIMCC_FormatTelegraphServerList(telegraphServers)

	LOG_AddEntry(PACKAGE_MIES, "amplifiers", keys = {"list"}, values = {list})

	return [telegraphServers, ampMCC]
End

static Function [STRUCT AxonTelegraph_DataStruct tds] AIMCC_GetTelegraphStruct(variable axonSerial, variable channel)

	variable i, err
	string errMsg

	PerformSubsystemEntry()

	AIMCC_InitAxonTelegraphStruct(tds)

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

Function AIMCC_GetHoldingCommand(string device, variable headstage)

	DEBUGPRINT("Unimplemented")
End

Function AIMCC_GetMode(string device, variable headstage)

	DEBUGPRINT("Unimplemented")
End

static Function [variable ADGain, variable DAGain] AIMCC_RetrieveGains(string device, variable headstage, variable clampMode)

	ADGain = NaN
	DAGain = NaN

	DEBUGPRINT("Unimplemented")

	return [ADGain, DAGain]
End

static Function AIMCC_GetOppositeClampAmpMode(variable mode)

	DEBUGPRINT("Unimplemented")
End

Function AIMCC_SelectMultiClamp(string device, variable headStage)

	DEBUGPRINT("Unimplemented")
End

Function AIMCC_SetClampMode(string device, variable headStage, variable mode, variable zeroStep, variable selectAmp)

	DEBUGPRINT("Unimplemented")
End

Function AIMCC_SendToAmp(string device, variable headStage, variable mode, variable func, variable accessType, [variable checkBeforeWrite, variable usePrefixes, variable selectAmp, variable value])

	DEBUGPRINT("Unimplemented")
End

Function AIMCC_EnsureCorrectMode(string device, variable headStage, variable selectAmp)

	DEBUGPRINT("Unimplemented")
End

Function AIMCC_FillAndSendAmpliferSettings(string device, variable sweepNo)

	DEBUGPRINT("Unimplemented")
End

Function AIMCC_QueryGainsFromMCC(string device)

	DEBUGPRINT("Unimplemented")
End

Function AIMCC_FindConnectedAmps(variable rescanHardware)

	DEBUGPRINT("Unimplemented")
End

static Function [STRUCT AxonTelegraph_DataStruct tds] AIMCC_GetTelegraphStruct(variable axonSerial, variable channel)

	DEBUGPRINT("Unimplemented")
End
#endif // AMPLIFIER_XOPS_PRESENT
