#pragma rtGlobals=3		// Use modern global access method and strict wave access.

///@todo use these constants instead of literal numbers
Constant V_CLAMP_MODE      = 0
Constant I_CLAMP_MODE      = 1
Constant I_EQUAL_ZERO_MODE = 2

Function/S AI_ConvertAmplifierModeToString(mode)
	variable mode

	switch(mode)
		case V_CLAMP_MODE:
			return "V_CLAMP_MODE"
			break
		case I_CLAMP_MODE:
			return "I_CLAMP_MODE"
			break
		case V_CLAMP_MODE:
			return "I_EQUAL_ZERO_MODE"
			break
		default:
			return "Unknown mode (" + num2str(mode) + ")"
			break
	endswitch
End

/// @returns AD gain of amp in selected mode
/// Gain is returned in V/pA for V-Clamp, V/mV for I-Clamp
Function AI_RetrieveADGain(panelTitle, axonSerial, channel)
	string panelTitle
	variable axonSerial
	variable channel

	STRUCT AxonTelegraph_DataStruct tds
	Init_AxonTelegraph_DataStruct(tds)
	AxonTelegraphGetDataStruct(axonSerial, channel, 1, tds)

	if(tds.OperatingMode == V_CLAMP_MODE)
		return tds.ScaleFactor * tds.Alpha / 1000
	elseif(tds.OperatingMode == I_CLAMP_MODE)
		return tds.ScaleFactor * tds.Alpha / 1000
	endif
End

/// @returns DA gain of amp in selected mode.
/// Gain is returned in mV/V for V_CLAMP_MODE and V/mV for I_CLAMP_MODE.
Function AI_RetrieveDAGain(panelTitle, axonSerial, channel)
	string panelTitle
	variable axonSerial
	variable channel

	STRUCT AxonTelegraph_DataStruct tds
	Init_AxonTelegraph_DataStruct(tds)
	AxonTelegraphGetDataStruct(axonSerial, channel, 1, tds)

	if(tds.OperatingMode == V_CLAMP_MODE)
		return tds.ExtCmdSens * 1000
	elseif(tds.OperatingMode == I_CLAMP_MODE)
		return tds.ExtCmdSens * 1e12
	else
		// do nothing
	endif
End

/// @brief Changes the mode of the amplifier between I-Clamp and V-Clamp depending on the currently set mode
Function AI_SwitchAxonAmpMode(panelTitle, mccSerial, channel)
	string panelTitle
	string mccSerial
	variable channel

	MCC_SelectMultiClamp700B(mccSerial, channel)
	variable mode = MCC_GetMode()

	if(mode == V_CLAMP_MODE)
		MCC_SetMode(I_CLAMP_MODE)
	elseif(Mode == I_CLAMP_MODE)
		MCC_SetMode(V_CLAMP_MODE)
	else
		// do nothing
	endif
End

Function Init_AxonTelegraph_DataStruct(tds)
	struct AxonTelegraph_DataStruct& tds

	tds.version = 13
End

Structure AxonTelegraph_DataStruct
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
Function AI_GetAmpAxonSerial(panelTitle, headStage)
	string panelTitle
	variable headStage

	Wave ChanAmpAssign = GetChanAmpAssign(panelTitle)

	return ChanAmpAssign[8][headStage]
End

/// @brief Returns the serial number of the headstage compatible with MCC* functions, @see GetChanAmpAssign
Function/S AI_GetAmpMCCSerial(panelTitle, headStage)
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
Function AI_GetAmpChannel(panelTitle, headStage)
	string panelTitle
	variable headStage

	Wave ChanAmpAssign = GetChanAmpAssign(panelTitle)

	return ChanAmpAssign[9][headStage]
End

/// @brief Set the clamp mode of user linked MCC based on the headstage number
Function AI_SetClampMode(panelTitle, headStage, mode)
	string panelTitle
	variable headStage
	variable mode

	variable channel, errorCode
	string mccSerial
	ASSERT(mode == V_CLAMP_MODE || mode == I_CLAMP_MODE || mode == I_EQUAL_ZERO_MODE, "invalid mode")

	mccSerial = AI_GetAmpMCCSerial(panelTitle, headStage)
	channel   = AI_GetAmpChannel(panelTitle, headStage)

	if(!AI_IsValidSerialAndChannel(mccSerial=mccSerial, channel=channel))
		print "No Amp is linked with this headstage"
		return NaN
	endif

	try
		MCC_SelectMultiClamp700B(mccSerial, channel); AbortOnRTE
	catch
		errorCode = GetRTError(1)
		printf "Could not find any connected amplifiers, please call \"Query connected Amps\" from the Hardware Tab\r"
		return NaN
	endtry

	if(!IsFinite(MCC_SetMode(mode)))
		printf "MCC amplifier cannot be switched to mode %d. Linked MCC is longer present\r", mode
	endif
End

Function AI_IsValidSerialAndChannel([mccSerial, axonSerial, channel])
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

/// @name Possible values for the function parameter of AI_SendToAmp()
/// @{
Constant MCC_SETHOLDING_FUNC             = 0x001
Constant MCC_GETHOLDING_FUNC             = 0x002
Constant MCC_SETHOLDINGENABLE_FUNC       = 0x004
Constant MCC_SETWHOLECELLCOMPCAP_FUNC    = 0x008
Constant MCC_SETWHOLECELLCOMPRESIST_FUNC = 0x010
Constant MCC_SETWHOLECELLCOMPENABLE_FUNC = 0x020
Constant MCC_SETRSCOMPCORRECTION_FUNC    = 0x030
Constant MCC_SETRSCOMPPREDICTION_FUNC    = 0x040
Constant MCC_SETRSCOMPENABLE_FUNC        = 0x050
Constant MCC_AUTOBRIDGEBALANCE_FUNC      = 0x060
Constant MCC_SETBRIDGEBALRESIST_FUNC     = 0x070
Constant MCC_SETBRIDGEBALENABLE_FUNC     = 0x080
Constant MCC_SETNEUTRALIZATIONCAP_FUNC   = 0x090
Constant MCC_SETNEUTRALIZATIONENABL_FUNC = 0x100
Constant MCC_AUTOPIPETTEOFFSET_FUNC      = 0x110
Constant MCC_SETPIPETTEOFFSET_FUNC       = 0x120
Constant MCC_GETPIPETTEOFFSET_FUNC       = 0x130
Constant MCC_SETSLOWCURRENTINJENABL_FUNC = 0x140
Constant MCC_GETSLOWCURRENTINJENABL_FUNC = 0x150
Constant MCC_SETSLOWCURRENTINJLEVEL_FUNC = 0x160
Constant MCC_GETSLOWCURRENTINJLEVEL_FUNC = 0x170
Constant MCC_SETSLOWCURRENTINJSETLT_FUNC = 0x180
Constant MCC_GETSLOWCURRENTINJSETLT_FUNC = 0x190
Constant MCC_GETHOLDINGENABLE_FUNC       = 0x200
/// @}

/// @brief Generic interface to call MCC amplifier functions
///
/// @param panelTitle locked panel name to work on
/// @param headStage  number of the headStage, must be in the range [0, NUM_HEADSTAGES[
/// @param mode       one of V_CLAMP_MODE, I_CLAMP_MODE or I_EQUAL_ZERO_MODE
/// @param func       Function to call
/// @param value      Numerical value to send, ignored by getter functions (MCC_GETHOLDING_FUNC and MCC_GETPIPETTEOFFSET_FUNC)
///
/// @returns return value or error condition. An error is indicated by a return value of NaN.
Function AI_SendToAmp(panelTitle, headStage, mode, func, value) ///@todo It might make sense to have this function update the AmpStorageWave 
	string panelTitle
	variable headStage, mode, func, value

	variable ret, channel, headstageMode
	string serial, str

	ASSERT(headStage >= 0 && headStage < NUM_HEADSTAGES, "invalid headStage index")
	ASSERT(mode == V_CLAMP_MODE || mode == I_CLAMP_MODE || mode == I_EQUAL_ZERO_MODE, "invalid mode")

	headstageMode = AI_MIESHeadstageMode(panelTitle, headStage)

	if(headstageMode != mode)
		printf "Headstage %d is in %s but the required one is %s\r", headstage, AI_ConvertAmplifierModeToString(headstageMode), AI_ConvertAmplifierModeToString(mode)
		return NaN
	elseif(!AI_MIESHeadstageMatchesMCCMode(panelTitle, headStage))
		printf "Headstage %d has different modes stored and set\r", headstage
		return NaN
	endif

	serial  = AI_GetAmpMCCSerial(panelTitle, headStage)
	channel = AI_GetAmpChannel(panelTitle, headStage)

	if(!AI_IsValidSerialAndChannel(mccserial=serial, channel=channel))
		return NaN
	endif

	sprintf str, "headStage=%d, mode=%d, func=%d, value=%g", headStage, mode, func, value
	DEBUGPRINT(str)

	MCC_SelectMultiClamp700B(serial, channel)

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
		case MCC_SETWHOLECELLCOMPCAP_FUNC:
			ret = MCC_SetWholeCellCompCap(value)
			break
		case MCC_SETWHOLECELLCOMPRESIST_FUNC:
			ret = MCC_SetWholeCellCompResist(value)
			break
		case MCC_SETWHOLECELLCOMPENABLE_FUNC:
			ret = MCC_SetWholeCellCompEnable(value)
			break
		case MCC_SETRSCOMPCORRECTION_FUNC:
			ret = MCC_SetRsCompCorrection(value)
			break
		case MCC_SETRSCOMPPREDICTION_FUNC:
			ret = MCC_SetRsCompPrediction(value)
			break
		case MCC_SETRSCOMPENABLE_FUNC:
			ret = MCC_SetRsCompEnable(value)
			break
		case MCC_AUTOBRIDGEBALANCE_FUNC:
			ret = MCC_AutoBridgeBal()
			break
		case MCC_SETBRIDGEBALRESIST_FUNC:
			ret = MCC_SetBridgeBalResist(value)
			break
		case MCC_SETBRIDGEBALENABLE_FUNC:
			ret = MCC_SetBridgeBalEnable(value)
			break
		case MCC_SETNEUTRALIZATIONCAP_FUNC:
			ret = MCC_SetNeutralizationCap(value)
			break
		case MCC_SETNEUTRALIZATIONENABL_FUNC:
			ret = MCC_SetNeutralizationEnable(value)
			break
		case MCC_AUTOPIPETTEOFFSET_FUNC:
			ret = MCC_AutoPipetteOffset()
			break
		case MCC_SETPIPETTEOFFSET_FUNC:
			ret = MCC_SetPipetteOffset(value)
			break
		case MCC_GETPIPETTEOFFSET_FUNC:
			ret = MCC_GetPipetteOffset()
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
		case MCC_GETHOLDINGENABLE_FUNC:
			ret = MCC_GetHoldingEnable()
			break
		default:
			ASSERT(0, "Unknown function")
			break
	endswitch

	if(!IsFinite(ret))
		print "Amp communication error. Check associations in hardware tab and/or use Query connected amps button"
	endif

	return ret
End

/// @returns 1 if the MIES headstage mode matches the associated MCC mode, zero otherwise
Function AI_MIESHeadstageMatchesMCCMode(panelTitle, headStage)
	string panelTitle
	variable headStage

	// if these are out of sync the user needs to intervene unless MCC monitoring is enabled
	// (at the time of writing this comment, monitoring has not been implemented)

	variable serial  = AI_GetAmpAxonSerial(panelTitle, headStage)
	variable channel = AI_GetAmpChannel(panelTitle, headStage)

	STRUCT AxonTelegraph_DataStruct tds
	Init_AxonTelegraph_DataStruct(tds)
	AxonTelegraphGetDataStruct(serial, channel, 1, tds)

	return (tds.operatingMode == AI_MIESHeadstageMode(panelTitle, headStage))
End

/// @returns the mode of the headstage defined in the locked DA_ephys panel,
///          can be V_CLAMP_MODE or I_CLAMP_MODE
Function AI_MIESHeadstageMode(panelTitle, headStage)
	string panelTitle
	variable headStage  // range: [0, NUM_HEADSTAGES[
						// headstage 1 has radio buttons 0 and 1

	string ctrl
	sprintf ctrl, "Radio_ClampMode_%d", (headStage * 2)

	return GetCheckBoxState(panelTitle, ctrl) == CHECKBOX_SELECTED ? V_CLAMP_MODE : I_CLAMP_MODE
End

Function AI_UpdateAmpModel(panelTitle, cntrlName, headStage)
	string panelTitle
	string cntrlName
	variable headStage

	if(HSU_DeviceIsUnlocked(panelTitle, silentCheck=1))
		print "Associate the panel with a DAC prior to using panel"
		return 0
	endif

	variable i, numHS, value
	wave AmpStoragewave = GetAmplifierParamStorageWave(panelTitle)

	Wave statusHS = DC_ControlStatusWave(panelTitle, "DataAcq_HS")
	numHS = DimSize(statusHS, ROWS)

	// we don't use a wrapper here as we want to be able to query different control types
	ControlInfo /w = $panelTitle $cntrlName
	ASSERT(V_flag != 0, "non-existing window or control")
	value = v_value

	if(!GetCheckBoxState(panelTitle, "Check_DataAcq_SendToAllAmp"))
		headStage  = GetSliderPositionIndex(panelTitle, "slider_DataAcq_ActiveHeadstage")
		statusHS[] = (p == headStage ? 1 : 0)
	endif

	for(i = 0; i < numHS; i += 1)

		if(!statusHS[i])
			continue
		endif

		string str
		sprintf str, "headstage %d, cntrl %s, value %g", i, cntrlName, value
		DEBUGPRINT(str)

		strswitch(cntrlName)
			//V-clamp controls
			case "setvar_DataAcq_Hold_VC":
				AmpStorageWave[0][0][i] = value
				AI_SendToAmp(panelTitle, i, V_CLAMP_MODE, MCC_SETHOLDING_FUNC, value * 1e-3)
				break
			case "check_DatAcq_HoldEnableVC":
				AmpStorageWave[1][0][i] = value
				AI_SendToAmp(panelTitle, i, V_CLAMP_MODE, MCC_SETHOLDINGENABLE_FUNC, value)
				break
			case "setvar_DataAcq_WCC":
				AmpStorageWave[2][0][i] = value
				AI_SendToAmp(panelTitle, i, V_CLAMP_MODE, MCC_SETWHOLECELLCOMPCAP_FUNC, value * 1e-12)
				break
			case "setvar_DataAcq_WCR":
				AmpStorageWave[3][0][i] = value
				AI_SendToAmp(panelTitle, i, V_CLAMP_MODE, MCC_SETWHOLECELLCOMPRESIST_FUNC, value * 1e6)
				break
			case "check_DatAcq_WholeCellEnable":
				AmpStorageWave[4][0][i] = value
				AI_SendToAmp(panelTitle, i, V_CLAMP_MODE, MCC_SETWHOLECELLCOMPENABLE_FUNC, value)
				break
			case "setvar_DataAcq_RsCorr":
				AmpStorageWave[5][0][i] = value
				AI_SendToAmp(panelTitle, i, V_CLAMP_MODE, MCC_SETRSCOMPCORRECTION_FUNC, value)
				break
			case "setvar_DataAcq_RsPred":
				AmpStorageWave[6][0][i] = value
				AI_SendToAmp(panelTitle, i, V_CLAMP_MODE, MCC_SETRSCOMPPREDICTION_FUNC, value)
				break
			case "check_DatAcq_RsCompEnable":
				AmpStorageWave[7][0][i] = value
				AI_SendToAmp(panelTitle, i, V_CLAMP_MODE, MCC_SETRSCOMPENABLE_FUNC, value)
				break
			case "setvar_DataAcq_PipetteOffset_VC":
				AmpStorageWave[8][0][i] = value
				AI_SendToAmp(panelTitle, i, V_CLAMP_MODE, MCC_SETPIPETTEOFFSET_FUNC, value * 1e-3)
				break
			case "button_DataAcq_AutoPipOffset_VC":
				AI_SendToAmp(panelTitle, i, V_CLAMP_MODE, MCC_AUTOPIPETTEOFFSET_FUNC, NaN)
				break
			// I-Clamp controls
			case "setvar_DataAcq_Hold_IC":
				AmpStorageWave[16][0][i] = value
				AI_SendToAmp(panelTitle, i, I_CLAMP_MODE, MCC_SETHOLDING_FUNC, value * 1e-12)
				break
			case "check_DatAcq_HoldEnable":
				AmpStorageWave[17][0][i] = value
				AI_SendToAmp(panelTitle, i, I_CLAMP_MODE, MCC_SETHOLDINGENABLE_FUNC, value)
				break
			case "setvar_DataAcq_BB":
				AmpStorageWave[18][0][i] = value
				AI_SendToAmp(panelTitle, i, I_CLAMP_MODE, MCC_SETBRIDGEBALRESIST_FUNC, value * 1e6)
				break
			case "check_DatAcq_BBEnable":
				AmpStorageWave[19][0][i] = value
				AI_SendToAmp(panelTitle, i, I_CLAMP_MODE, MCC_SETBRIDGEBALENABLE_FUNC, value)
				break
			case "setvar_DataAcq_CN":
				AmpStorageWave[20][0][i] = value
				AI_SendToAmp(panelTitle, i, I_CLAMP_MODE, MCC_SETNEUTRALIZATIONCAP_FUNC, value * 1e-12)
				break
			case "check_DatAcq_CNEnable":
				AmpStorageWave[21][0][i] = value
				AI_SendToAmp(panelTitle, i, I_CLAMP_MODE, MCC_SETNEUTRALIZATIONENABL_FUNC, value)
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
				AI_SendToAmp(panelTitle, i, I_CLAMP_MODE, MCC_AUTOBRIDGEBALANCE_FUNC, NaN)
				break
			// I Zero controls
			case "check_DataAcq_IzeroEnable":
				AmpStorageWave[30][0][i] = value
				break
			default:
				printf "BUG: unknown control %s\r", cntrlName
				break
		endswitch
	endfor
End

///@brief Updates the amplifier GUI
///
///@param panelTitle locked device to work on
///@param MIESHeadStageNo The headstage on which the MIES DA_Ephys amplifer controls will be updated
///@param cntrlName Name of the control being updated. cntrlName is an optional parameter (see displayHelpTopic "Using Optional Parameters").
Function AI_UpdateAmpView(panelTitle, MIESHeadStageNo, [cntrlName])
	string panelTitle
	variable MIESHeadStageNo
	string cntrlName
	variable Param
	
	if(HSU_DeviceIsUnlocked(panelTitle, silentCheck=1))
		print "Associate the panel with a DAC prior to using panel"
		return 0
	endif
	
	Wave AmpStorageWave = GetAmplifierParamStorageWave(panelTitle)
	if(GetSliderPositionIndex(panelTitle, "slider_DataAcq_ActiveHeadstage") == MIESHeadStageNo) // only update view if headstage is selected. 
		if(paramIsDefault(cntrlName)) // update all amplifier controls
			cntrlName = ""
			setSetVariable(panelTitle, "setvar_DataAcq_Hold_VC", AmpStorageWave[%holdingPotential][0][MIESHeadStageNo])
			setCheckBoxState(panelTitle, "check_DatAcq_HoldEnableVC", AmpStorageWave[%HoldingPotentialEnable][0][MIESHeadStageNo])
			setSetVariable(panelTitle, "setvar_DataAcq_WCC", AmpStorageWave[%WholeCellCap][0][MIESHeadStageNo])
			setSetVariable(panelTitle, "setvar_DataAcq_WCC", AmpStorageWave[%WholeCellRes][0][MIESHeadStageNo])
			setCheckBoxState(panelTitle, "check_DatAcq_WholeCellEnable", AmpStorageWave[%WholeCellEnable][0][MIESHeadStageNo])
			setSetVariable(panelTitle, "setvar_DataAcq_RsCorr", AmpStorageWave[%Correction][0][MIESHeadStageNo])
			setSetVariable(panelTitle, "setvar_DataAcq_RsPred", AmpStorageWave[%Prediction][0][MIESHeadStageNo])
			setCheckBoxState(panelTitle, "check_DatAcq_RsCompEnable", AmpStorageWave[%RsCompEnable][0][MIESHeadStageNo])
			setSetVariable(panelTitle, "setvar_DataAcq_PipetteOffset_VC", AmpStorageWave[%PipetteOffset][0][MIESHeadStageNo])			
	
			setSetVariable(panelTitle, "setvar_DataAcq_Hold_IC", AmpStorageWave[%BiasCurrent][0][MIESHeadStageNo])
			setCheckBoxState(panelTitle, "check_DatAcq_HoldEnable", AmpStorageWave[%BiasCurrentEnable][0][MIESHeadStageNo])
			setSetVariable(panelTitle, "setvar_DataAcq_BB", AmpStorageWave[%BridgeBalance][0][MIESHeadStageNo])
			setCheckBoxState(panelTitle, "check_DatAcq_BBEnable", AmpStorageWave[%BridgeBalanceEnable][0][MIESHeadStageNo])
			setSetVariable(panelTitle, "setvar_DataAcq_CN", AmpStorageWave[%CapNeut][0][MIESHeadStageNo])
			setCheckBoxState(panelTitle, "check_DatAcq_CNEnable", AmpStorageWave[%CapNeutEnable][0][MIESHeadStageNo])
			setSetVariable(panelTitle, "setvar_DataAcq_AutoBiasV", AmpStorageWave[%AutoBiasVcom][0][MIESHeadStageNo])
			setSetVariable(panelTitle, "setvar_DataAcq_AutoBiasVrange", AmpStorageWave[%AutoBiasVcomVariance][0][MIESHeadStageNo])
			setSetVariable(panelTitle, "setvar_DataAcq_IbiasMax", AmpStorageWave[%AutoBiasIbiasmax][0][MIESHeadStageNo])
			setCheckBoxState(panelTitle, "check_DataAcq_AutoBias", AmpStorageWave[%AutoBiasEnable][0][MIESHeadStageNo])
			return 1
		endif
	
		strSwitch(cntrlName) // update specific controls
		// V-Clamp controls
			case "setvar_DataAcq_Hold_VC":
				setSetVariable(panelTitle, "setvar_DataAcq_Hold_VC", AmpStorageWave[%holdingPotential][0][MIESHeadStageNo])
				break
			case "check_DatAcq_HoldEnableVC":
				setCheckBoxState(panelTitle, "check_DatAcq_HoldEnableVC", AmpStorageWave[%HoldingPotentialEnable][0][MIESHeadStageNo])
				break
			case "setvar_DataAcq_WCC":
				setSetVariable(panelTitle, "setvar_DataAcq_WCC", AmpStorageWave[%WholeCellCap][0][MIESHeadStageNo])
				break
			case "setvar_DataAcq_WCR":
				setSetVariable(panelTitle, "setvar_DataAcq_WCC", AmpStorageWave[%WholeCellRes][0][MIESHeadStageNo])
				break
			case "check_DatAcq_WholeCellEnable":
				setCheckBoxState(panelTitle, "check_DatAcq_WholeCellEnable", AmpStorageWave[%WholeCellEnable][0][MIESHeadStageNo])
				break
			case "setvar_DataAcq_RsCorr":
				setSetVariable(panelTitle, "setvar_DataAcq_RsCorr", AmpStorageWave[%Correction][0][MIESHeadStageNo])
				break
			case "setvar_DataAcq_RsPred":
				setSetVariable(panelTitle, "setvar_DataAcq_RsPred", AmpStorageWave[%Prediction][0][MIESHeadStageNo])
				break
			case "check_DatAcq_RsCompEnable":
				setCheckBoxState(panelTitle, "check_DatAcq_RsCompEnable", AmpStorageWave[%RsCompEnable][0][MIESHeadStageNo])
				break
			case "setvar_DataAcq_PipetteOffset_VC":
				setSetVariable(panelTitle, "setvar_DataAcq_PipetteOffset_VC", AmpStorageWave[%PipetteOffset][0][MIESHeadStageNo])
				break
			// I-Clamp controls
			case "setvar_DataAcq_Hold_IC":
				setSetVariable(panelTitle, "setvar_DataAcq_Hold_IC", AmpStorageWave[%BiasCurrent][0][MIESHeadStageNo])
				break
			case "check_DatAcq_HoldEnable":
				setCheckBoxState(panelTitle, "check_DatAcq_HoldEnable", AmpStorageWave[%BiasCurrentEnable][0][MIESHeadStageNo])
				break
			case "setvar_DataAcq_BB":
				setSetVariable(panelTitle, "setvar_DataAcq_BB", AmpStorageWave[%BridgeBalance][0][MIESHeadStageNo])
				break
			case "check_DatAcq_BBEnable":
				setCheckBoxState(panelTitle, "check_DatAcq_BBEnable", AmpStorageWave[%BridgeBalanceEnable][0][MIESHeadStageNo])
				break
			case "setvar_DataAcq_CN":
				setSetVariable(panelTitle, "setvar_DataAcq_CN", AmpStorageWave[%CapNeut][0][MIESHeadStageNo])
				break
			case "check_DatAcq_CNEnable":
				setCheckBoxState(panelTitle, "check_DatAcq_CNEnable", AmpStorageWave[%CapNeutEnable][0][MIESHeadStageNo])
				break
			case "setvar_DataAcq_AutoBiasV":
				setSetVariable(panelTitle, "setvar_DataAcq_AutoBiasV", AmpStorageWave[%AutoBiasVcom][0][MIESHeadStageNo])
				break
			case "setvar_DataAcq_AutoBiasVrange":
				setSetVariable(panelTitle, "setvar_DataAcq_AutoBiasVrange", AmpStorageWave[%AutoBiasVcomVariance][0][MIESHeadStageNo])
				break
			case "setvar_DataAcq_IbiasMax":
				setSetVariable(panelTitle, "setvar_DataAcq_IbiasMax", AmpStorageWave[%AutoBiasIbiasmax][0][MIESHeadStageNo])
				break
			case "check_DataAcq_AutoBias":
				setCheckBoxState(panelTitle, "check_DataAcq_AutoBias", AmpStorageWave[%AutoBiasEnable][0][MIESHeadStageNo])
				break
			// I = zero controls
			case "check_DataAcq_IzeroEnable":
				setCheckBoxState(panelTitle, "check_DataAcq_IzeroEnable", AmpStorageWave[%IZeroEnable][0][MIESHeadStageNo])
				break
			default:
				printf "BUG: unknown control %s\r", cntrlName
				break
		endSwitch
	endIf
End

/// @brief Fill the amplifier settings wave by querying the MC700B and send the data to ED_createWaveNotes
///
/// @param panelTitle 		 device
/// @param savedDataWaveName wave name that the wavenotes will be amended to
/// @param sweepNo           data wave sweep number
Function AI_FillAndSendAmpliferSettings(panelTitle, savedDataWaveName, sweepNo)
	string panelTitle
	string savedDataWaveName
	variable sweepNo

	variable numHS, i, axonSerial, channel
	string mccSerial

	WAVE/SDFR=GetDevicePath(panelTitle) ChannelClampMode
	WAVE statusHS         = DC_ControlStatusWave(panelTitle, "DataAcq_HS")
	WAVE ampSettingsWave  = GetAmplifierSettingsWave(panelTitle)
	WAVE/T ampSettingsKey = GetAmplifierSettingsKeyWave(panelTitle)

	ampSettingsWave = NaN

	numHS = DimSize(statusHS, ROWS)
	for(i = 0; i < numHS ; i += 1)
		if(!statusHS[i])
			continue
		endif

		mccSerial  = AI_GetAmpMCCSerial(panelTitle, i)
		axonSerial = AI_GetAmpAxonSerial(panelTitle, i)
		channel    = AI_GetAmpChannel(panelTitle, i)

		// checks to make sure amp is associated with MIES headstage
		if(!AI_IsValidSerialAndChannel(axonSerial=axonSerial, mccSerial=mccSerial, channel=channel))
			continue
		endif

		MCC_SelectMultiClamp700B(mccSerial, channel)

		// now start to query the amp to get the status
		if (ChannelClampMode[i][0] == V_CLAMP_MODE)
			// See if the thing is enabled
			// Save the enabled state in column 0
			ampSettingsWave[0][0][i]  = MCC_GetHoldingEnable() // V-Clamp holding enable

			// Save the level in column 1
			ampSettingsWave[0][1][i] = (MCC_GetHolding() * 1e+3)	// V-Clamp holding level, converts Volts to mV

			// Save the Osc Killer Enable in column 2
			ampSettingsWave[0][2][i] = MCC_GetOscKillerEnable() // V-Clamp Osc Killer Enable

			// Save the RsCompBandwidth in column 3
			ampSettingsWave[0][3][i] = (MCC_GetRsCompBandwidth() * 1e-3) // V-Clamp RsComp Bandwidth, converts Hz to KHz

			// Save the RsCompCorrection in column 4
			ampSettingsWave[0][4][i] = MCC_GetRsCompCorrection() // V-Clamp RsComp Correction

			// Save the RsCompEnable in column 5
			ampSettingsWave[0][5][i] =   MCC_GetRsCompEnable() // V-Clamp RsComp Enable

			// Save the RsCompPrediction in column 6
			ampSettingsWave[0][6][i] = MCC_GetRsCompPrediction() // V-Clamp RsCompPrediction

			// Save the whole celll cap value in column 7
			ampSettingsWave[0][7][i] =   MCC_GetWholeCellCompEnable() // V-Clamp Whole Cell Comp Enable

			// Save the whole celll cap value in column 8
			ampSettingsWave[0][8][i] =   (MCC_GetWholeCellCompCap() * 1e+12) // V-Clamp Whole Cell Comp Cap, Converts F to pF

			// Save the whole cell comp resist value in column 9
			ampSettingsWave[0][9][i] =  (MCC_GetWholeCellCompResist() * 1e-6) // V-Clamp Whole Cell Comp Resist, Converts Ohms to MOhms

		elseif (ChannelClampMode[i][0] == I_CLAMP_MODE)
			// Save the i clamp holding enabled in column 10
			ampSettingsWave[0][10][i] =  MCC_GetHoldingEnable() // I-Clamp holding enable

			// Save the i clamp holding value in column 11
			ampSettingsWave[0][11][i] = (MCC_GetHolding() * 1e+12)	 // I-Clamp holding level, converts Amps to pAmps

			// Save the neutralization enable in column 12
			ampSettingsWave[0][12][i] = MCC_GetNeutralizationEnable() // I-Clamp Neut Enable

			// Save neut cap value in column 13
			ampSettingsWave[0][13][i] =  (MCC_GetNeutralizationCap() * 1e+12) // I-Clamp Neut Cap Value, Conversts Farads to pFarads

			// save bridge balance enabled in column 14
			ampSettingsWave[0][14][i] =   MCC_GetBridgeBalEnable() // I-Clamp Bridge Balance Enable

			// save bridge balance enabled in column 15
			ampSettingsWave[0][15][i] =  (MCC_GetBridgeBalResist() * 1e-6)	 // I-Clamp Bridge Balance Resist

			ampSettingsWave[0][36][i] =  MCC_GetSlowCurrentInjEnable()
			ampSettingsWave[0][37][i] =  MCC_GetSlowCurrentInjLevel()
			ampSettingsWave[0][38][i] =  MCC_GetSlowCurrentInjSetlTime()
		endif

		// save the axon telegraph settings as well
		// get the data structure to get axon telegraph information
		STRUCT AxonTelegraph_DataStruct tds
		Init_AxonTelegraph_DataStruct(tds)

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
		ampSettingsWave[0][26][i] = (tds.MembraneCap * 1e+12) // converts F to pF
		ampSettingsWave[0][27][i] = tds.ExtCmdSens
		ampSettingsWave[0][28][i] = tds.RawOutSignal
		ampSettingsWave[0][29][i] = tds.RawScaleFactor
		ampSettingsWave[0][30][i] = tds.RawScaleFactorUnits
		ampSettingsWave[0][31][i] = tds.HardwareType
		ampSettingsWave[0][32][i] = tds.SecondaryAlpha
		ampSettingsWave[0][33][i] = tds.SecondaryLPFCutoff
		ampSettingsWave[0][34][i] = (tds.SeriesResistance * 1e-6) // converts Ohms to MOhms

		// new parameters
		ampSettingsWave[0][35][i] = MCC_GetPipetteOffset() * 1e3 // convert V to mV
	endfor
	
	// now call the function that will create the wave notes	
	ED_createWaveNotes(ampSettingsWave, ampSettingsKey, savedDataWaveName, sweepNo, panelTitle)
END

/// Brief description of the function AI_createAmplifierTextDocWave
///@brief Creates wave of text documentation inputs, and a corresponding key wave.  This wave will then be sent to the 
/// ED_createTextNotes to amend to the savedDataWave as text wavenotes.
///
///  For the KeyWave, the wave dimensions are:
/// row 0 - Parameter name
/// row 1 - Unit
/// row 2 - Tolerance factor
///
/// For the settings history, the wave dimensions are:
/// Col 0 - Sweep Number
/// Col 1 - Time Stamp
///
/// The history wave will use layers to report the different headstages.
///
/// Incoming parameters
/// @param panelTitle -- the calling panel name, used for finding the right folder to save data in.
/// @param SavedDataWaveName -- the wave name that the wavenotes will be amended to.
/// @param SweepCount -- the current data wave sweep number
/// 
/// The function will take text input from the user, in a manner yet to be determined, and append them to the savedDataWave
function AI_createAmpliferTextDocWave(panelTitle, SavedDataWaveName, SweepCount)
	string panelTitle
	string SavedDataWaveName
	Variable SweepCount
	
	dfref ampdfr = GetAmpSettingsFolder()
	// Location for the text documentation wave
	
	// get all the Amp connection information
	String controlledHeadStage = DC_ControlStatusListString("DataAcq_HS", "check",panelTitle)  	
	// get the number of headStages...used for building up the ampSettingsWave
	variable noHeadStages = itemsinlist(controlledHeadStage, ";")
	
	Wave/Z/T/SDFR=ampdfr ampTextDocWave = ampTextDoc
	if (!WaveExists(ampTextDocWave))
		make /T /o /n = (1, 16, noHeadStages ) ampdfr:ampTextDoc/Wave=ampTextDocWave
	endif
	
	Wave/T/SDFR=ampdfr ampTextDocKey
	if (!WaveExists(ampTextDocKey))
		//print "making settingsKey Wave...."
		// create the 2 dimensional wave
		make /T /o  /n = (3, 16) ampdfr:ampTextDocKey/Wave=ampTextDocKey

		// Row 0: Parameter
			
		// Add dimension labels to the ampSettingsKey wave
		SetDimLabel 0, 0, Parameter, ampTextDocKey
		
		// And now populate the wave
		ampTextDocKey[0][0] =  "V-Clamp Holding Enable"		
		ampTextDocKey[0][1] =   "V-Clamp Holding Level"
		ampTextDocKey[0][2] =   "Osc Killer Enable"
		ampTextDocKey[0][3] =   "RsComp Bandwidth"
		ampTextDocKey[0][4] =   "RsComp Correction"
		ampTextDocKey[0][5] =   "RsComp Enable"
		ampTextDocKey[0][6] =   "RsComp Prediction"
		ampTextDocKey[0][7] =   "Whole Cell Comp Enable"
		ampTextDocKey[0][8] =   "Whole Cell Comp Cap"
		ampTextDocKey[0][9] =   "Whole Cell Comp Resist"
		ampTextDocKey[0][10] =   "I-Clamp Holding Enable"
		ampTextDocKey[0][11] =   "I-Clamp Holding Level"
		ampTextDocKey[0][12] =   "Neut Cap Enabled"
		ampTextDocKey[0][13] =   "Neut Cap Value"
		ampTextDocKey[0][14] =   "Bridge Bal Enable"
		ampTextDocKey[0][15] =   "Bridge Bal Value"
	endif	

	// populate the textDocWave
	variable textDocColCounter 
	variable textDocLayerCounter
	string textDocText
	for (textDocLayerCounter = 0; textDocLayerCounter < noHeadStages; textDocLayerCounter += 1)
		for (textDocColCounter = 0; textDocColCounter < 16; textDocColCounter += 1)
			sprintf textDocText, "Headstage#%d:%s: Text Place Holder" textDocLayerCounter, ampTextDocKey[textDocColCounter]
			ampTextDocWave[0][textDocColCounter][textDocLayerCounter] = textDocText
		endfor
	endfor
	
	// call the function to create the text notes
	ED_createTextNotes(ampTextDocWave, ampTextDocKey, SavedDataWaveName, SweepCount, panelTitle)
End

// This is a testing function to make sure the experiment documentation function is working correctly
function createDummySettingsWave(panelTitle, SavedDataWaveName, SweepCount)
	string panelTitle
	string SavedDataWaveName
	Variable SweepCount

	// Location for the settings wave
	dfref ampdfr = GetAmpSettingsFolder()

	Wave/Z/SDFR=ampdfr dummySettingsWave = dummySettings
	if (!WaveExists(dummySettingsWave))
		// create the 3 dimensional wave
		make /o /n = (1, 6, 8) ampdfr:dummySettings/Wave=dummySettingsWave
	endif

	Wave/T/SDFR=ampdfr dummySettingsKey
	if (!WaveExists(dummySettingsKey))
		make /T /o  /n = (3, 6) ampdfr:dummySettingsKey/Wave=dummySettingsKey
	
		// Row 0: Parameter
		// Row 1: Units	
		// Row 2: Tolerance factor
			
		// Add dimension labels to the dummySettingsKey wave
		SetDimLabel 0, 0, Parameter, dummySettingsKey
		SetDimLabel 0, 1, Units, dummySettingsKey
		SetDimLabel 0, 2, Tolerance, dummySettingsKey
		
		// And now populate the wave
		dummySettingsKey[0][0] =  "Dummy Setting 1"
		dummySettingsKey[1][0] =  "V"
		dummySettingsKey[2][0] =  "0.5"
		
		dummySettingsKey[0][1] =   "Dummy Setting 2"
		dummySettingsKey[1][1] =  "V"
		dummySettingsKey[2][1] =  "0.5"
		
		dummySettingsKey[0][2] =   "Dummy Setting 3"
		dummySettingsKey[1][2] =   "V"
		dummySettingsKey[2][2] =   "0.5"
		
		dummySettingsKey[0][3] =   "Dummy Setting 4"
		dummySettingsKey[1][3] =   "V"
		dummySettingsKey[2][3] =   "0.5"
		
		dummySettingsKey[0][4] =   "Dummy Setting 5"
		dummySettingsKey[1][4] =   "V"
		dummySettingsKey[2][4] =   "0.05"
		
		dummySettingsKey[0][5] =   "Dummy Setting 6"
		dummySettingsKey[1][5] =   "V"
		dummySettingsKey[2][5] =   "0.05"		
	endif

	// Now populate the Settings Wave
	// the wave is 1 row, 15 columns, and headstage number layers
	// first...determine if the head stage is being controlled
	variable headStageControlledCounter
	for(headStageControlledCounter = 0;headStageControlledCounter < NUM_HEADSTAGES ;headStageControlledCounter += 1)
		dummySettingsWave[0][0][headStageControlledCounter] = sweepCount*.1 
		dummySettingsWave[0][1][headStageControlledCounter] = sweepCount*.2
		dummySettingsWave[0][2][headStageControlledCounter] = sweepCount*.3 
		dummySettingsWave[0][3][headStageControlledCounter] = sweepCount*.4
		dummySettingsWave[0][4][headStageControlledCounter] = sweepCount*.5 
		dummySettingsWave[0][5][headStageControlledCounter] = sweepCount*.6
	endfor
	
	// now call the function that will create the wave notes	
	ED_createWaveNotes(dummySettingsWave, dummySettingsKey, SavedDataWaveName, SweepCount, panelTitle)
	
End

//==================================================================================================
// Below is code to open the MCC and manipulate the MCC windows. It is hard coded from TimJs 700Bs. Needs to be adapted for MIES
//==================================================================================================

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
