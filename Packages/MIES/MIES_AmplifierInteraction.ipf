#pragma rtGlobals=3		// Use modern global access method and strict wave access.

/// @file MIES_AmplifierInteraction.ipf
/// @brief __AI__ Interface with the Axon/MCC amplifiers

static Constant ZERO_TOLERANCE = 100 // pA

static StrConstant AMPLIFIER_CONTROLS_VC = "setvar_DataAcq_Hold_VC;check_DataAcq_Amp_Chain;check_DatAcq_HoldEnableVC;setvar_DataAcq_WCC;setvar_DataAcq_WCR;check_DatAcq_WholeCellEnable;setvar_DataAcq_RsCorr;setvar_DataAcq_RsPred;check_DataAcq_Amp_Chain;check_DatAcq_RsCompEnable;setvar_DataAcq_PipetteOffset_VC;button_DataAcq_FastComp_VC;button_DataAcq_SlowComp_VC;button_DataAcq_AutoPipOffset_VC"
static StrConstant AMPLIFIER_CONTROLS_IC = "setvar_DataAcq_Hold_IC;check_DatAcq_HoldEnable;setvar_DataAcq_BB;check_DatAcq_BBEnable;setvar_DataAcq_CN;check_DatAcq_CNEnable;setvar_DataAcq_AutoBiasV;setvar_DataAcq_AutoBiasVrange;setvar_DataAcq_IbiasMax;check_DataAcq_AutoBias;setvar_DataAcq_PipetteOffset_IC;button_DataAcq_AutoBridgeBal_IC"
static Constant MAX_PIPETTEOFFSET = 150 // mV
static Constant MIN_PIPETTEOFFSET = -150
/// @brief Stringified version of the clamp mode
Function/S AI_ConvertAmplifierModeToString(mode)
	variable mode

	switch(mode)
		case V_CLAMP_MODE:
			return "V_CLAMP_MODE"
			break
		case I_CLAMP_MODE:
			return "I_CLAMP_MODE"
			break
		case I_EQUAL_ZERO_MODE:
			return "I_EQUAL_ZERO_MODE"
			break
		default:
			return "Unknown mode (" + num2str(mode) + ")"
			break
	endswitch
End

/// @returns AD gain of selected Amplifier in current clamp mode
/// Gain is returned in V/pA for V_CLAMP_MODE, V/mV for I_CLAMP_MODE/I_EQUAL_ZERO_MODE
static Function AI_RetrieveADGain(panelTitle, headstage)
	string panelTitle
	variable headstage

	variable axonSerial = AI_GetAmpAxonSerial(panelTitle, headstage)
	variable channel    = AI_GetAmpChannel(panelTitle, headStage)

	STRUCT AxonTelegraph_DataStruct tds
	AI_InitAxonTelegraphStruct(tds)
	AxonTelegraphGetDataStruct(axonSerial, channel, 1, tds)

	return tds.ScaleFactor * tds.Alpha / 1000
End

/// @returns DA gain of selected Amplifier in current clamp mode
/// Gain is returned in mV/V for V_CLAMP_MODE and V/mV for I_CLAMP_MODE/I_EQUAL_ZERO_MODE
static Function AI_RetrieveDAGain(panelTitle, headstage)
	string panelTitle
	variable headstage

	variable axonSerial = AI_GetAmpAxonSerial(panelTitle, headstage)
	variable channel    = AI_GetAmpChannel(panelTitle, headStage)

	STRUCT AxonTelegraph_DataStruct tds
	AI_InitAxonTelegraphStruct(tds)
	AxonTelegraphGetDataStruct(axonSerial, channel, 1, tds)

	if(tds.OperatingMode == V_CLAMP_MODE)
		return tds.ExtCmdSens * 1000
	elseif(tds.OperatingMode == I_CLAMP_MODE || tds.OperatingMode == I_EQUAL_ZERO_MODE)
		return tds.ExtCmdSens * 1e12
	endif
End

/// @brief Changes the mode of the amplifier between I-Clamp and V-Clamp depending on the currently set mode
static Function AI_SwitchAxonAmpMode(panelTitle, headStage)
	string panelTitle
	variable headStage

	variable mode

	if(AI_SelectMultiClamp(panelTitle, headStage, verbose=1) != AMPLIFIER_CONNECTION_SUCCESS)
		return NAN
	endif

	mode = MCC_GetMode()

	if(mode == V_CLAMP_MODE)
		MCC_SetMode(I_CLAMP_MODE)
	elseif(mode == I_CLAMP_MODE || mode == I_EQUAL_ZERO_MODE)
		MCC_SetMode(V_CLAMP_MODE)
	else
		// do nothing
	endif
End

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

/// @brief Wrapper for MCC_SelectMultiClamp700B
///
/// @param panelTitle                          device
/// @param headStage	                       headstage number
/// @param verbose [optional: default is true] print an error message
///
/// @returns one of @ref AISelectMultiClampReturnValues
Function AI_SelectMultiClamp(panelTitle, headStage, [verbose])
	string panelTitle
	variable headStage, verbose

	variable channel, errorCode, axonSerial, debugOnError
	string mccSerial

	if(ParamIsDefault(verbose))
		verbose = 1
	else
		verbose = !!verbose
	endif

	// checking axonSerial is done as a service to the caller
	axonSerial = AI_GetAmpAxonSerial(panelTitle, headStage)
	mccSerial  = AI_GetAmpMCCSerial(panelTitle, headStage)
	channel    = AI_GetAmpChannel(panelTitle, headStage)

	if(!AI_IsValidSerialAndChannel(mccSerial=mccSerial, axonSerial=axonSerial, channel=channel))
		if(verbose)
			printf "(%s) No amplifier is linked with headstage %d\r", panelTitle, headStage
		endif
		return AMPLIFIER_CONNECTION_INVAL_SER
	endif

	debugOnError = DisableDebugOnError()

	try
		MCC_SelectMultiClamp700B(mccSerial, channel); AbortOnRTE
	catch
		errorCode = GetRTError(1)
		if(verbose)
			printf "(%s) The MCC for Amp serial number: %s associated with MIES headstage %d is not open or is unresponsive.\r", panelTitle, mccSerial, headStage
		endif
		ResetDebugOnError(debugOnError)
		return AMPLIFIER_CONNECTION_MCC_FAILED
	endtry

	ResetDebugOnError(debugOnError)
	return AMPLIFIER_CONNECTION_SUCCESS
end

/// @brief Set the clamp mode of user linked MCC based on the headstage number
Function AI_SetClampMode(panelTitle, headStage, mode)
	string panelTitle
	variable headStage
	variable mode

	AI_AssertOnInvalidClampMode(mode)

	if(AI_SelectMultiClamp(panelTitle, headStage) != AMPLIFIER_CONNECTION_SUCCESS)
		return NaN
	endif

	if(!IsFinite(MCC_SetMode(mode)))
		printf "MCC amplifier cannot be switched to mode %d. Linked MCC is no longer present\r", mode
	endif
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

/// @brief Generic interface to call MCC amplifier functions
///
/// @param panelTitle       locked panel name to work on
/// @param headStage        number of the headStage, must be in the range [0, NUM_HEADSTAGES[
/// @param mode             one of V_CLAMP_MODE, I_CLAMP_MODE or I_EQUAL_ZERO_MODE
/// @param func             Function to call, see @ref AI_SendToAmpConstants
/// @param value            Numerical value to send, ignored by all getter functions
/// @param checkBeforeWrite [optional, defaults to false] (ignored for getter functions)
///                         check the current value and do nothing if it is equal within some tolerance to the one written
/// @param usePrefixes      [optional, defaults to true] Use SI-prefixes common in MIES for the passed and returned values, e.g.
///                         `mV` instead of `V`
///
/// @returns return value or error condition. An error is indicated by a return value of NaN.
Function AI_SendToAmp(panelTitle, headStage, mode, func, value, [checkBeforeWrite, usePrefixes])
	string panelTitle
	variable headStage, mode, func, value
	variable checkBeforeWrite, usePrefixes

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

	if(AI_SelectMultiClamp(panelTitle, headstage) != AMPLIFIER_CONNECTION_SUCCESS)
		return NaN
	endif

	if(ParamIsDefault(usePrefixes) || !!usePrefixes)
		scale = AI_GetMCCScale(mode, func)
	else
		scale = 1
	endif

	headstageMode = DAP_MIESHeadstageMode(panelTitle, headStage)

	if(headstageMode != mode)
		return NaN
	elseif(AI_MIESHeadstageMatchesMCCMode(panelTitle, headStage) == 0)
		return NaN
	endif

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
			ret = AI_SendToAmp(panelTitle, headstage, mode, MCC_GETBRIDGEBALRESIST_FUNC, NaN, usePrefixes=usePrefixes)
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
			ret = AI_SendToAmp(panelTitle, headStage, mode, MCC_GETPIPETTEOFFSET_FUNC, NaN, usePrefixes=usePrefixes)
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
	endif

	return ret * scale
End

/// @returns 1 if the MIES headstage mode matches the associated MCC mode, zero if not and NaN
/// if the headstage has no amplifier connected
Function AI_MIESHeadstageMatchesMCCMode(panelTitle, headStage)
	string panelTitle
	variable headStage

	// if these are out of sync the user needs to intervene unless MCC monitoring is enabled
	// (at the time of writing this comment, monitoring has not been implemented)

	variable serial  = AI_GetAmpAxonSerial(panelTitle, headStage)
	variable channel = AI_GetAmpChannel(panelTitle, headStage)
	variable equalModes, storedMode, setMode

	if(!AI_IsValidSerialAndChannel(channel=channel, axonSerial=serial))
		return NaN
	endif

	STRUCT AxonTelegraph_DataStruct tds
	AI_InitAxonTelegraphStruct(tds)
	AxonTelegraphGetDataStruct(serial, channel, 1, tds)
	storedMode = DAP_MIESHeadstageMode(panelTitle, headStage)
	setMode    = tds.operatingMode
	equalModes = (setMode == storedMode)

	if(!equalModes)
		printf "(%s) Headstage %d has different modes stored (%s) and set (%s)\r", panelTitle, headstage, AI_ConvertAmplifierModeToString(storedMode), AI_ConvertAmplifierModeToString(setMode)
	endif

	return equalModes
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
/// @param headStage        headstage of the desired amplifier
/// @param value            [optional: defaults to the controls value] value to set
/// @param sendToAll        [optional: defaults to the state of the checkbox] should the value be send
///                         to all active headstages (true) or just to the given one (false)
/// @param checkBeforeWrite [optional, defaults to false] (ignored for getter functions)
///                         check the current value and do nothing if it is equal within some tolerance to the one written
///
/// @return 0 on success, 1 otherwise
Function AI_UpdateAmpModel(panelTitle, ctrl, headStage, [value, sendToAll, checkBeforeWrite])
	string panelTitle
	string ctrl
	variable headStage, value, sendToAll, checkBeforeWrite

	variable i, diff, selectedHeadstage, clampMode, oppositeMode
	string str, rowLabel, rowLabelOpposite, ctrlToCall, ctrlToCallOpposite

	DAP_AbortIfUnlocked(panelTitle)

	selectedHeadstage = GetSliderPositionIndex(panelTitle, "slider_DataAcq_ActiveHeadstage")

	if(ParamIsDefault(value))
		ASSERT(headstage == selectedHeadstage, "Supply the optional argument value if setting values of other headstages than the current one")
		// we don't use a wrapper here as we want to be able to query different control types
		ControlInfo/W=$panelTitle $ctrl
		ASSERT(V_flag != 0, "non-existing window or control")
		value = v_value
	endif

	if(ParamIsDefault(sendToAll))
		if(headstage == selectedHeadstage)
			sendToAll = GetCheckBoxState(panelTitle, "Check_DataAcq_SendToAllAmp")
		else
			sendToAll = 0
		endif
	else
		sendToAll = !!sendToAll
	endif

	WAVE AmpStoragewave = GetAmplifierParamStorageWave(panelTitle)

	WAVE statusHS = DC_ControlStatusWave(panelTitle, CHANNEL_TYPE_HEADSTAGE)
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

	for(i = 0; i < NUM_HEADSTAGES; i += 1)

		if(!statusHS[i])
			continue
		endif

		sprintf str, "headstage %d, ctrl %s, value %g", i, ctrl, value
		DEBUGPRINT(str)

		strswitch(ctrl)
			//V-clamp controls
			case "setvar_DataAcq_Hold_VC":
				AmpStorageWave[0][0][i] = value
				AI_SendToAmp(panelTitle, i, V_CLAMP_MODE, MCC_SETHOLDING_FUNC, value, checkBeforeWrite=checkBeforeWrite)
				break
			case "check_DatAcq_HoldEnableVC":
				AmpStorageWave[1][0][i] = value
				AI_SendToAmp(panelTitle, i, V_CLAMP_MODE, MCC_SETHOLDINGENABLE_FUNC, value, checkBeforeWrite=checkBeforeWrite)
				break
			case "setvar_DataAcq_WCC":
				AmpStorageWave[2][0][i] = value
				AI_SendToAmp(panelTitle, i, V_CLAMP_MODE, MCC_SETWHOLECELLCOMPCAP_FUNC, value, checkBeforeWrite=checkBeforeWrite)
				break
			case "setvar_DataAcq_WCR":
				AmpStorageWave[3][0][i] = value
				AI_SendToAmp(panelTitle, i, V_CLAMP_MODE, MCC_SETWHOLECELLCOMPRESIST_FUNC, value, checkBeforeWrite=checkBeforeWrite)
				break
			case "button_DataAcq_WCAuto":
				AI_SendToAmp(panelTitle, i, V_CLAMP_MODE, MCC_AUTOWHOLECELLCOMP_FUNC, NaN, checkBeforeWrite=checkBeforeWrite)
				value = AI_SendToAmp(panelTitle, i, V_CLAMP_MODE, MCC_GETWHOLECELLCOMPCAP_FUNC, NaN, checkBeforeWrite=checkBeforeWrite)
				AmpStorageWave[%WholeCellCap][0][i] = value
				AI_UpdateAmpView(panelTitle, i, ctrl =  "setvar_DataAcq_WCC")
				value = AI_SendToAmp(panelTitle, i, V_CLAMP_MODE, MCC_GETWHOLECELLCOMPRESIST_FUNC, NaN, checkBeforeWrite=checkBeforeWrite)
				AmpStorageWave[%WholeCellRes][0][i] = value
				AI_UpdateAmpView(panelTitle, i, ctrl =  "setvar_DataAcq_WCR")
				value = AI_SendToAmp(panelTitle, i, V_CLAMP_MODE, MCC_GETWHOLECELLCOMPENABLE_FUNC, NaN, checkBeforeWrite=checkBeforeWrite)
				AmpStorageWave[%WholeCellEnable][0][i] = value
				AI_UpdateAmpView(panelTitle, i, ctrl =  "check_DatAcq_WholeCellEnable")
				break
			case "check_DatAcq_WholeCellEnable":
				AmpStorageWave[4][0][i] = value
				AI_SendToAmp(panelTitle, i, V_CLAMP_MODE, MCC_SETWHOLECELLCOMPENABLE_FUNC, value, checkBeforeWrite=checkBeforeWrite)
				break
			case "setvar_DataAcq_RsCorr":
				diff = value - AmpStorageWave[%Correction][0][i]
				// abort if the corresponding value with chaining would be outside the limits
				if(AmpStorageWave[%RSCompChaining][0][i] && !CheckIfValueIsInsideLimits(panelTitle, "setvar_DataAcq_RsPred", AmpStorageWave[%Prediction][0][i] + diff))
					AI_UpdateAmpView(panelTitle, i, ctrl = ctrl)
					return 1
				endif
				AmpStorageWave[%Correction][0][i] = value
				AI_SendToAmp(panelTitle, i, V_CLAMP_MODE, MCC_SETRSCOMPCORRECTION_FUNC, value, checkBeforeWrite=checkBeforeWrite)
				if(AmpStorageWave[%RSCompChaining][0][i])
					AmpStorageWave[%Prediction][0][i] += diff
					AI_SendToAmp(panelTitle, i, V_CLAMP_MODE, MCC_SETRSCOMPPREDICTION_FUNC, AmpStorageWave[%Prediction][0][i], checkBeforeWrite=checkBeforeWrite)
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
				AI_SendToAmp(panelTitle, i, V_CLAMP_MODE, MCC_SETRSCOMPPREDICTION_FUNC, value, checkBeforeWrite=checkBeforeWrite)
				if(AmpStorageWave[%RSCompChaining][0][i])
					AmpStorageWave[%Correction][0][i] += diff
					AI_SendToAmp(panelTitle, i, V_CLAMP_MODE, MCC_SETRSCOMPCORRECTION_FUNC, AmpStorageWave[%Correction][0][i], checkBeforeWrite=checkBeforeWrite)
					AI_UpdateAmpView(panelTitle, i, ctrl =  "setvar_DataAcq_RsCorr")
				endif
				break
			case "check_DatAcq_RsCompEnable":
				AmpStorageWave[7][0][i] = value
				AI_SendToAmp(panelTitle, i, V_CLAMP_MODE, MCC_SETRSCOMPENABLE_FUNC, value, checkBeforeWrite=checkBeforeWrite)
				break
			case "setvar_DataAcq_PipetteOffset_VC":
				AmpStorageWave[%PipetteOffsetVC][0][i] = value
				AI_SendToAmp(panelTitle, i, V_CLAMP_MODE, MCC_SETPIPETTEOFFSET_FUNC, value, checkBeforeWrite=checkBeforeWrite)
				break
			case "button_DataAcq_AutoPipOffset_IC":
			case "button_DataAcq_AutoPipOffset_VC":
				clampMode = DAP_MIESHeadstageMode(panelTitle, i)

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

				value = AI_SendToAmp(panelTitle, i, clampMode, MCC_AUTOPIPETTEOFFSET_FUNC, NaN, checkBeforeWrite=checkBeforeWrite)
				AmpStorageWave[%$rowLabel][0][i] = value
				AI_UpdateAmpView(panelTitle, i, ctrl=ctrlToCall)
				// the pipette offset for the opposite mode has also changed, fetch that too
				try
					DAP_ChangeHeadStageMode(panelTitle, oppositeMode, i, SKIP_MCC_MIES_SYNCING)
					value = AI_SendToAmp(panelTitle, i, oppositeMode, MCC_GETPIPETTEOFFSET_FUNC, NaN, checkBeforeWrite=checkBeforeWrite)
					AmpStorageWave[%$rowLabelOpposite][0][i] = value
					AI_UpdateAmpView(panelTitle, i, ctrl=ctrlToCallOpposite)
					DAP_ChangeHeadStageMode(panelTitle, clampMode, i, SKIP_MCC_MIES_SYNCING)
				catch
					if(GetCheckBoxState(panelTitle, "check_Settings_SyncMiesToMCC"))
						printf "(%s) The pipette offset for %s of headstage %d is invalid.\r", panelTitle, AI_ConvertAmplifierModeToString(oppositeMode), i
					endif
					// do nothing
				endtry
				break
			case "button_DataAcq_FastComp_VC":
				AmpStorageWave[%FastCapacitanceComp][0][i] = value
				AI_SendToAmp(panelTitle, i, V_CLAMP_MODE, MCC_AUTOFASTCOMP_FUNC, NaN, checkBeforeWrite=checkBeforeWrite)
				break
			case "button_DataAcq_SlowComp_VC":
				AmpStorageWave[%SlowCapacitanceComp][0][i] = value
				AI_SendToAmp(panelTitle, i, V_CLAMP_MODE, MCC_AUTOSLOWCOMP_FUNC, NaN, checkBeforeWrite=checkBeforeWrite)
				break
			case "check_DataAcq_Amp_Chain":
				AmpStorageWave[%RSCompChaining][0][i] = value
				AI_UpdateAmpModel(panelTitle, "setvar_DataAcq_RsCorr", i, value=AmpStorageWave[5][0][i])
				break
			// I-Clamp controls
			case "setvar_DataAcq_Hold_IC":
				AmpStorageWave[16][0][i] = value
				AI_SendToAmp(panelTitle, i, I_CLAMP_MODE, MCC_SETHOLDING_FUNC, value, checkBeforeWrite=checkBeforeWrite)
				break
			case "check_DatAcq_HoldEnable":
				AmpStorageWave[17][0][i] = value
				AI_SendToAmp(panelTitle, i, I_CLAMP_MODE, MCC_SETHOLDINGENABLE_FUNC, value, checkBeforeWrite=checkBeforeWrite)
				break
			case "setvar_DataAcq_BB":
				AmpStorageWave[18][0][i] = value
				AI_SendToAmp(panelTitle, i, I_CLAMP_MODE, MCC_SETBRIDGEBALRESIST_FUNC, value, checkBeforeWrite=checkBeforeWrite)
				break
			case "check_DatAcq_BBEnable":
				AmpStorageWave[19][0][i] = value
				AI_SendToAmp(panelTitle, i, I_CLAMP_MODE, MCC_SETBRIDGEBALENABLE_FUNC, value, checkBeforeWrite=checkBeforeWrite)
				break
			case "setvar_DataAcq_CN":
				AmpStorageWave[20][0][i] = value
				AI_SendToAmp(panelTitle, i, I_CLAMP_MODE, MCC_SETNEUTRALIZATIONCAP_FUNC, value, checkBeforeWrite=checkBeforeWrite)
				break
			case "check_DatAcq_CNEnable":
				AmpStorageWave[21][0][i] = value
				AI_SendToAmp(panelTitle, i, I_CLAMP_MODE, MCC_SETNEUTRALIZATIONENABL_FUNC, value, checkBeforeWrite=checkBeforeWrite)
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
				value = AI_SendToAmp(panelTitle, i, I_CLAMP_MODE, MCC_AUTOBRIDGEBALANCE_FUNC, NaN, checkBeforeWrite=checkBeforeWrite)
				AI_UpdateAmpModel(panelTitle, "setvar_DataAcq_BB", i, value=value)
				AI_UpdateAmpModel(panelTitle, "check_DatAcq_BBEnable", i, value=1)
				break
			case "setvar_DataAcq_PipetteOffset_IC":
				AmpStorageWave[%PipetteOffsetIC][0][i] = value
				AI_SendToAmp(panelTitle, i, I_CLAMP_MODE, MCC_SETPIPETTEOFFSET_FUNC, value, checkBeforeWrite=checkBeforeWrite)
				break
			default:
				ASSERT(0, "Unknown control " + ctrl)
				break
		endswitch

		if(!ParamIsDefault(value))
			AI_UpdateAmpView(panelTitle, i, ctrl = ctrl)
		endif
	endfor

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

	if(GetSliderPositionIndex(panelTitle, "slider_DataAcq_ActiveHeadstage") != headStage)
		return NaN
	elseif(!AI_MIESHeadstageMatchesMCCMode(panelTitle, headStage))
		return NaN
	endif

	AI_AssertOnInvalidClampMode(clampMode)

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

		AI_UpdateAmpModel(panelTitle, ctrl, headStage, checkBeforeWrite=1)
	endfor
End

/// @brief Synchronizes the AmpStorageWave to the amplifier GUI control
///
/// @param panelTitle  device
/// @param headStage   headstage
/// @param ctrl        [optional, defaults to all controls] name of the control being updated
static Function AI_UpdateAmpView(panelTitle, headStage, [ctrl])
	string panelTitle
	variable headStage
	string ctrl

	string lbl, list
	variable i, numEntries

	DAP_AbortIfUnlocked(panelTitle)

	// only update view if headstage is selected
	if(GetSliderPositionIndex(panelTitle, "slider_DataAcq_ActiveHeadstage") != headStage)
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

		if(StringMatch(ctrl, "setvar_*"))
			SetSetVariable(panelTitle, ctrl, AmpStorageWave[%$lbl][0][headStage])
		elseif(StringMatch(ctrl, "check_*"))
			SetCheckBoxState(panelTitle, ctrl, AmpStorageWave[%$lbl][0][headStage])
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

/// @brief Fill the amplifier settings wave by querying the MC700B and send the data to ED_createWaveNotes
///
/// @param panelTitle 		 device
/// @param sweepNo           data wave sweep number
Function AI_FillAndSendAmpliferSettings(panelTitle, sweepNo)
	string panelTitle
	variable sweepNo

	variable numHS, i, axonSerial, channel, DAC
	string mccSerial

	WAVE channelClampMode      = GetChannelClampMode(panelTitle)
	WAVE statusHS              = DC_ControlStatusWaveCache(panelTitle, CHANNEL_TYPE_HEADSTAGE)
	WAVE ampSettingsWave       = GetAmplifierSettingsWave()
	WAVE/T ampSettingsKey      = GetAmplifierSettingsKeyWave()
	WAVE/T ampSettingsTextWave = GetAmplifierSettingsTextWave()
	WAVE/T ampSettingsTextKey  = GetAmplifierSettingsTextKeyWave()

	ampSettingsWave = NaN

	numHS = DimSize(statusHS, ROWS)
	for(i = 0; i < numHS ; i += 1)
		if(!statusHS[i])
			continue
		endif

		mccSerial  = AI_GetAmpMCCSerial(panelTitle, i)
		axonSerial = AI_GetAmpAxonSerial(panelTitle, i)
		channel    = AI_GetAmpChannel(panelTitle, i)

		if(AI_SelectMultiClamp(panelTitle, i) != AMPLIFIER_CONNECTION_SUCCESS)
			continue
		endif

		DAC = AFH_GetDACFromHeadstage(panelTitle, i)
		ASSERT(IsFinite(DAC), "Expected finite DAC")

		if(channelClampMode[DAC][%DAC] == V_CLAMP_MODE)
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
		elseif(channelClampMode[DAC][%DAC] == I_CLAMP_MODE || channelClampMode[DAC][%DAC] == I_EQUAL_ZERO_MODE)
			ampSettingsWave[0][10][i] = MCC_GetHoldingEnable()
			ampSettingsWave[0][11][i] = MCC_GetHolding() * AI_GetMCCScale(I_CLAMP_MODE, MCC_GETHOLDING_FUNC)
			ampSettingsWave[0][12][i] = MCC_GetNeutralizationEnable()
			ampSettingsWave[0][13][i] = MCC_GetNeutralizationCap() * AI_GetMCCScale(I_CLAMP_MODE, MCC_GETNEUTRALIZATIONCAP_FUNC)
			ampSettingsWave[0][14][i] = MCC_GetBridgeBalEnable()
			ampSettingsWave[0][15][i] = MCC_GetBridgeBalResist() * AI_GetMCCScale(I_CLAMP_MODE, MCC_GETBRIDGEBALRESIST_FUNC)
			ampSettingsWave[0][36][i] = MCC_GetSlowCurrentInjEnable()
			ampSettingsWave[0][37][i] = MCC_GetSlowCurrentInjLevel()
			ampSettingsWave[0][38][i] = MCC_GetSlowCurrentInjSetlTime()
		endif

		STRUCT AxonTelegraph_DataStruct tds
		AI_InitAxonTelegraphStruct(tds)

		AxonTelegraphGetDataStruct(axonSerial, channel, 1, tds)
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

	ED_createWaveNotes(ampSettingsWave, ampSettingsKey, sweepNo, panelTitle)
	ED_createTextNotes(ampSettingsTextWave, ampSettingsTextKey, sweepNo, panelTitle)
End

// Below is code to open the MCC and manipulate the MCC windows. It is hard coded from TimJs 700Bs. Needs to be adapted for MIES

///To open Multiclamp commander, use ExecuteScriptText to open from Windows command line.
///Each window is appended with a serial number for the amplifier (/S) and a title designating which 
///headstages it controls (/T). You may also assign configuations (.mcc files) to a window of your 
///choice. Add the file path to the configuation after /C. The file path for MC700B.exe must be the 
///default path (C:\\Program Files (x86)\\Molecular Devices\\MultiClamp 700B Commander\\MC700B.exe)
///or else you must change the path in OpenAllMCC().
///

///Reminder!!! When adding a file path inside of a string, always add \" to the front and end of the
///path name or else IGOR will not recognize it.

///These scripts use nircmd (http://www.nirsoft.net/utils/nircmd.html) to control window visability 
///and location. You have the option of having only one window will be visable at a time, but they 
///all will be open.

Function AI_OpenAllMCC (isHidden)
	// If ishidden = 1, only one window will be visiable at a time. You can switch between windows 
	//by using ShowWindowMCC If ishidden = 0, all windows will be stacked ontop of each other.
	Variable isHidden
	
	//This opens the MCC window for the designated amplifier based on its serial number (/S)
	//3&4
	ExecuteScriptText "\"C:\Program Files (x86)\Molecular Devices\MultiClamp 700B Commander\MC700B.exe\" /S00834001 /T3&4"// /C\"C:\Program Files (x86)\Molecular Devices\MultiClamp 700B Commander\Configurations\Config00834001.mcc\""
	ExecuteScriptText "nircmd.exe win center title \"3&4\""
	
	//5&6
	ExecuteScriptText "\"C:\Program Files (x86)\Molecular Devices\MultiClamp 700B Commander\MC700B.exe\" /S00834228 /T5&6"// /C\"C:\Program Files (x86)\Molecular Devices\MultiClamp 700B Commander\Configurations\Config00834228.mcc\""
	ExecuteScriptText "nircmd.exe win center title \"5&6\""
	
	//7&8
	ExecuteScriptText "\"C:\Program Files (x86)\Molecular Devices\MultiClamp 700B Commander\MC700B.exe\" /S00834191 /T7&8"// /C\"C:\Program Files (x86)\Molecular Devices\MultiClamp 700B Commander\Configurations\Config00834191.mcc\""
	ExecuteScriptText "nircmd.exe win center title \"7&8\""
	 
	//9&10
	ExecuteScriptText "\"C:\Program Files (x86)\Molecular Devices\MultiClamp 700B Commander\MC700B.exe\" /S00832774 /T9&10"// /C\"C:\Program Files (x86)\Molecular Devices\MultiClamp 700B Commander\Configurations\Config00832774.mcc\""
	ExecuteScriptText "nircmd.exe win center title \"9&10\""
	
	//11&12
	ExecuteScriptText "\"C:\Program Files (x86)\Molecular Devices\MultiClamp 700B Commander\MC700B.exe\" /S00834000 /T11&12"// /C\"C:\Program Files (x86)\Molecular Devices\MultiClamp 700B Commander\Configurations\Config00834000.mcc\""
	ExecuteScriptText "nircmd.exe win center title \"11&12\""
/// This function closes all of the MCC windows. A window may be closed normally and this will still work.
	//1&2
	ExecuteScriptText "\"C:\Program Files (x86)\Molecular Devices\MultiClamp 700B Commander\MC700B.exe\" /S00836059 /T1&2"// /C\"C:\Program Files (x86)\Molecular Devices\MultiClamp 700B Commander\Configurations\Config00834380.mcc\""
	ExecuteScriptText "nircmd.exe win center title \"1&2\""
	
	String/G curMCC = "1&2"
	
	if (isHidden)  //1&2 will be the only one open at start up. This line and the others like it will hide all other windows.
		ExecuteScriptText "nircmd.exe win hide title \"3&4\""
		ExecuteScriptText "nircmd.exe win hide title \"5&6\""
		ExecuteScriptText "nircmd.exe win hide title \"7&8\""
		ExecuteScriptText "nircmd.exe win hide title \"9&10\""
		ExecuteScriptText "nircmd.exe win hide title \"11&12\""		
	endif
End 

Function AI_ShowWindowMCC(newMCC)
	
	//newMCC must fall between 1 and 6. These correlated to the amplifiers associated with each pair of headstages.
	
	Variable newMCC
	if (exists("curMCC")!=2)
		String/G curMCC
		sprintf curMCC, "%d&%d", newMCC*2-1, newMCC*2 //amplifier 1 goes to headstage 1&2, 2 -> 3&4, 3 -> 5&6, etc.
	endif
	SVAR/Z curMCC
	String cmd
	
	//Hide the current window
	sprintf cmd, "nircmd.exe win hide title \"%s\"", curMCC
	ExecuteScriptText cmd
	
	//Make the current window into the new window
	sprintf curMCC, "%d&%d", newMCC*2-1, newMCC*2
	
	//Show the new window
	sprintf cmd, "nircmd.exe win show title \"%s\"", curMCC
	ExecuteScriptText cmd
	
End

/// This function is for when the windows are stacked ontop of each other. This will bring the selected one to the front without hiding the previous one.

Function AI_BringToFrontMCC(newMCC)

	Variable newMCC
	if (exists("curMCC")!=2)
		String/G curMCC
		sprintf curMCC, "%d&%d", newMCC*2-1, newMCC*2 //amplifier 1 goes to headstage 1&2, 2 -> 3&4, 3 -> 5&6, etc.
	endif
	SVAR/Z curMCC
	String cmd
	
	//Make the current window into the new window
	sprintf curMCC, "%d&%d", newMCC*2-1, newMCC*2
	
	//Show the new window
	sprintf cmd, "nircmd.exe win activate title \"%s\"", curMCC
	ExecuteScriptText cmd

End

/// This function will tile all of the MCC windows so that they are all visable on the screen.

Function AI_ShowAllMCC()
	ExecuteScriptText "nircmd.exe win show title \"1&2\""
	ExecuteScriptText "nircmd.exe win setsize title \"1&2\" 50 200 365 580"
	ExecuteScriptText "nircmd.exe win show title \"3&4\""
	ExecuteScriptText "nircmd.exe win setsize title \"3&4\" 415 200 365 580"
	ExecuteScriptText "nircmd.exe win show title \"5&6\""
	ExecuteScriptText "nircmd.exe win setsize title \"5&6\" 780 200 365 580"
	ExecuteScriptText "nircmd.exe win show title \"7&8\""
	ExecuteScriptText "nircmd.exe win setsize title \"7&8\" 50 780 365 580"
	ExecuteScriptText "nircmd.exe win show title \"9&10\""
	ExecuteScriptText "nircmd.exe win setsize title \"9&10\" 415 780 365 580"
	ExecuteScriptText "nircmd.exe win show title \"11&12\""
	ExecuteScriptText "nircmd.exe win setsize title \"11&12\" 780 780 365 580"
	
End

/// This function will center all of the MCC windows and hide all but the current window.

Function AI_CenterAndHideAllMCC()
	String cmd
	SVAR/Z curMCC
	//Need to figure out if windows can be tiled by nircmd
	ExecuteScriptText "nircmd.exe win center title \"1&2\""
	ExecuteScriptText "nircmd.exe win hide title \"1&2\""
	ExecuteScriptText "nircmd.exe win center title \"3&4\""
	ExecuteScriptText "nircmd.exe win hide title \"3&4\""
	ExecuteScriptText "nircmd.exe win center title \"5&6\""
	ExecuteScriptText "nircmd.exe win hide title \"5&6\""
	ExecuteScriptText "nircmd.exe win center title \"7&8\""
	ExecuteScriptText "nircmd.exe win hide title \"7&8\""
	ExecuteScriptText "nircmd.exe win center title \"9&10\""
	ExecuteScriptText "nircmd.exe win hide title \"9&10\""
	ExecuteScriptText "nircmd.exe win center title \"11&12\""
	ExecuteScriptText "nircmd.exe win hide title \"11&12\""
	
	sprintf cmd, "nircmd.exe win show title \"%s\"", curMCC
	ExecuteScriptText cmd
End

/// This function will center all of the MCC windows and leave them stacked ontop of each other.

Function AI_CenterAndShowAllMCC()
	String cmd
	SVAR/Z curMCC
	//Need to figure out if windows can be tiled by nircmd
	ExecuteScriptText "nircmd.exe win center title \"1&2\""
	ExecuteScriptText "nircmd.exe win show title \"1&2\""
	ExecuteScriptText "nircmd.exe win center title \"3&4\""
	ExecuteScriptText "nircmd.exe win show title \"3&4\""
	ExecuteScriptText "nircmd.exe win center title \"5&6\""
	ExecuteScriptText "nircmd.exe win show title \"5&6\""
	ExecuteScriptText "nircmd.exe win center title \"7&8\""
	ExecuteScriptText "nircmd.exe win show title \"7&8\""
	ExecuteScriptText "nircmd.exe win center title \"9&10\""
	ExecuteScriptText "nircmd.exe win show title \"9&10\""
	ExecuteScriptText "nircmd.exe win center title \"11&12\""
	ExecuteScriptText "nircmd.exe win show title \"11&12\""
	sprintf cmd, "nircmd.exe win show title \"%s\"", curMCC
	ExecuteScriptText cmd
End

/// This function closes all of the MCC windows. A window may be closed normally and this will still work.

Function AI_CloseAllMCC()
	//Need to figure out if windows can be tiled by nircmd
	ExecuteScriptText "nircmd.exe win close title \"1&2\""
	ExecuteScriptText "nircmd.exe win close title \"3&4\""
	ExecuteScriptText "nircmd.exe win close title \"5&6\""
	ExecuteScriptText "nircmd.exe win close title \"7&8\""
	ExecuteScriptText "nircmd.exe win close title \"9&10\""
	ExecuteScriptText "nircmd.exe win close title \"11&12\""
	
End

Function AI_SetMIESHeadstage(panelTitle, [headstage, increment])
	string panelTitle
	variable headstage, increment
	
	if(ParamIsDefault(headstage) && ParamIsDefault(increment))
		return Nan
	endif
	
	if(!ParamIsDefault(increment))
		headstage = GetSliderPositionIndex(panelTitle, "slider_DataAcq_ActiveHeadstage") + increment
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
		DFREF dfr = GetDeviceTestPulse(panelTitle)
		WAVE/SDFR=dfr baselineSSAvg
		if(!ParamIsDefault(headstage))
			col = TP_GetTPResultsColOfHS(panelTitle, headstage)
			if(col >= 0 && abs(baselineSSAvg[0][col]) >= ZERO_TOLERANCE)
				AI_MIESAutoPipetteOffset(panelTitle, headStage)
			endif
		else
			WAVE statusHS = DC_ControlStatusWave(panelTitle, CHANNEL_TYPE_HEADSTAGE)
			for(i = 0; i < NUM_HEADSTAGES; i += 1)
		
				if(!statusHS[i])
					continue
				endif
				col = TP_GetTPResultsColOfHS(panelTitle, i)
				if(col >= 0 && abs(baselineSSAvg[0][col]) >= ZERO_TOLERANCE)
					AI_MIESAutoPipetteOffset(panelTitle, headStage)
				endif
			endfor
		endif
	endif
End

/// @brief Auto pipette zeroing
/// Quicker than MCC auto pipette offset
///
/// @param panelTitle device
/// @param headStage
Function AI_MIESAutoPipetteOffset(panelTitle, headStage)
	string panelTitle
	variable headStage

	variable clampMode, column, vDelta, offset, value

	DFREF dfr = GetDeviceTestPulse(panelTitle)
	WAVE/Z/SDFR=dfr baselineSSAvg
	WAVE/Z/SDFR=dfr SSResistance

	if(!WaveExists(baselineSSAvg) || !WaveExists(SSResistance))
		return NaN
	endif

	clampMode = DAP_MIESHeadstageMode(panelTitle, headStage)

	ASSERT(clampMode == V_CLAMP_MODE || clampMode == I_CLAMP_MODE, "Headstage must be in VC/IC mode to use this function")
	column =TP_GetTPResultsColOfHS(panelTitle, headstage)
	ASSERT(column >= 0, "Invalid column number")
	//calculate delta current to reach zero
	vdelta = (baselineSSAvg[0][column] * SSResistance[0][column]) / 1000 // set to mV
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

	if(AI_SelectMultiClamp(panelTitle, headStage, verbose=0) != AMPLIFIER_CONNECTION_SUCCESS)
		return NaN
	endif

	ASSERT(clampMode == MCC_GetMode(), "Non matching clamp mode from MCC application")

	DAGain = AI_RetrieveDAGain(panelTitle, headStage)
	ADGain = AI_RetrieveADGain(panelTitle, headStage)

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

/// @brief Auto fills the units and gains for all headstages connected to amplifiers
/// by querying the MCC application
///
/// The data is inserted into `ChanAmpAssign` and `ChanAmpAssignUnit`
///
/// @return number of connected amplifiers
Function AI_QueryGainsFromMCC(panelTitle)
	string panelTitle

	variable clampMode, old_ClampMode, i, numConnAmplifiers
	variable DAGain, ADGain
	string DAUnit, ADUnit

	for(i = 0; i < NUM_HEADSTAGES; i += 1)

		if(AI_SelectMultiClamp(panelTitle, i, verbose=0) != AMPLIFIER_CONNECTION_SUCCESS)
			continue
		endif

		numConnAmplifiers += 1

		clampMode = MCC_GetMode()
		AI_AssertOnInvalidClampMode(clampMode)

		AI_QueryGainsUnitsForClampMode(panelTitle, i, clampMode, DAGain, ADGain, DAUnit, ADUnit)
		AI_UpdateChanAmpAssign(panelTitle, i, clampMode, DAGain, ADGain, DAUnit, ADUnit)

		if(!MCC_GetHoldingEnable())
			old_clampMode = clampMode
			AI_SwitchAxonAmpMode(panelTitle, i)

			clampMode = MCC_GetMode()

			AI_QueryGainsUnitsForClampMode(panelTitle, i, clampMode, DAGain, ADGain, DAUnit, ADUnit)
			AI_UpdateChanAmpAssign(panelTitle, i, clampMode, DAGain, ADGain, DAUnit, ADUnit)

			AI_SetClampMode(panelTitle, i, old_clampMode)
		else
			printf "It appears that a holding potential is being applied, therefore as a precaution, "
			printf "the gains cannot be imported for the %s.\r", AI_ConvertAmplifierModeToString(clampMode == V_CLAMP_MODE ? I_CLAMP_MODE : V_CLAMP_MODE)
			printf "The gains were successfully imported for the %s on i: %d\r", AI_ConvertAmplifierModeToString(clampMode), i
		endif
	endfor

	return numConnAmplifiers
End

/// @brief Assert on invalid clamp modes, does nothing otherwise
Function AI_AssertOnInvalidClampMode(clampMode)
	variable clampMode

	ASSERT(clampMode == V_CLAMP_MODE || clampMode == I_CLAMP_MODE || clampMode == I_EQUAL_ZERO_MODE, "invalid clamp mode")
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

/// @brief Opens Multi-clamp commander software
///
/// @param ampSerialNumList A text list of amplifier serial numbers without leading zeroes
/// Ex. "834001;435003;836059"
/// @param ampTitleList [optional, defaults to blank] MCC gui window title
/// @param maxAttempts [optional, defaults to inf] Maximum number of attempts made to open specified MCCs
/// @return 1 if all MCCs specified in ampSerialNumList were opened, 0 if one or more MCCs specified in ampSerialNumList were not able to be opened
Function AI_OpenMCCs(ampSerialNumList, [ampTitleList, maxAttempts])
	string ampSerialNumList
	string ampTitleList
	variable maxAttempts

	string cmd, serialStr, title
	variable i, j, serialNum, failedToOpenCount
	variable ItemsInAmpSerialNumList = itemsinlist(AmpSerialNumList)

	if(paramIsDefault(maxAttempts))
		maxAttempts = inf
	endif

	if(paramIsDefault(AmpTitleList))
		AmpTitleList = ""
	endIf

	WAVE OpenMCCList = AI_GetMCCSerialNumbers()
	Do
		for(i=0 ; i < ItemsInAmpSerialNumList ; i+=1)
			serialStr = stringfromlist(i, AmpSerialNumList)
			serialNum = str2num(serialStr)
			title = stringfromlist(i, AmpTitleList)
			findvalue/I=(serialNum) OpenMCCList
			if( V_value == -1)
				sprintf cmd, "\"%s%s\" /S00%g /T%s(%s)" GetProgramFilesFolder(), AI_GetMCCWinFilePath(), SerialNum, title, SerialStr
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
			printf "%g MCCs failed to open on attempt count %g " failedTOopenCount, j
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
		DeleteDuplicates(OpenMCCList)
		return OpenMCCList
End

/// @brief Return a path to the MCC.
///
/// Hardcoded as Igor does not allow to query that information.
///
/// Distinguishes between i386 and x64 Igor versions
static Function/S AI_GetMCCWinFilePath()

#if defined(IGOR64)
	return "Molecular Devices\MultiClamp_64\MC700B.exe"
#else
	return "Molecular Devices\MultiClamp 700B Commander\MC700B.exe"
#endif
End