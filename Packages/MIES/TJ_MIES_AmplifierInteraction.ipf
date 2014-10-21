#pragma rtGlobals=3		// Use modern global access method and strict wave access.

///@todo use these constants instead of literal numbers
Constant V_CLAMP_MODE      = 0
Constant I_CLAMP_MODE      = 1
Constant I_EQUAL_ZERO_MODE = 2

static Function/S ConvertAmplifierModeToString(mode)
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
			ASSERT(0, "invalid mode")
	endswitch
End

Function/S AI_ReturnListOf700BChannels(panelTitle)
	string panelTitle

	variable numRows
	variable i
	string str
	string list = ""

	Wave/SDFR=GetAmplifierFolder() W_TelegraphServers

	numRows = DimSize(W_TelegraphServers, ROWS)
	if(!numRows)
		print "Activate Multiclamp Commander software to populate list of available amplifiers"
		return "MC not available;"
	endif

	for(i=0; i < numRows; i+=1)
		sprintf str, "AmpNo %d Chan %d", W_TelegraphServers[i][0], W_TelegraphServers[i][1]
		list = AddListItem(str, list, ";", inf)
	endfor

	return list
End

//==================================================================================================
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
//==================================================================================================
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
//==================================================================================================
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
//==================================================================================================
static Function AI_SwitchAxonMode(panelTitle, mccSerial, channel, mode)
	string panelTitle
	string mccSerial
	variable channel
	variable mode

	variable errorCode
	ASSERT(mode == V_CLAMP_MODE || mode == I_CLAMP_MODE || mode == I_EQUAL_ZERO_MODE, "invalid mode")

	MCC_SelectMultiClamp700B(mccSerial, channel)
	errorCode = MCC_SetMode(mode)
	if(!IsFinite(errorCode))
		DFREF saveDFR = GetDataFolderDFR()
		SetDataFolder $Path_AmpFolder(panelTitle)
		MCC_FindServers/Z=1
		SetDataFolder saveDFR
		if(V_flag == 0) // checks to see if MCC_FindServers worked without error
			MCC_SetMode(mode)
		else
			printf "MCC amplifier cannot be switched to mode %d. Linked MCC is longer present\r", mode
		endif
	endif
End
//==================================================================================================
Function Init_AxonTelegraph_DataStruct(tds)
	struct AxonTelegraph_DataStruct& tds

	tds.version = 13
End
//==================================================================================================
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
//==================================================================================================
/// @brief Returns the serial number of the headstage compatible with Axon* functions, @see GetChanAmpAssign
Function AI_GetAmpAxonSerial(panelTitle, headStage)
	string panelTitle
	variable headStage

	Wave ChanAmpAssign = GetChanAmpAssign(panelTitle)

	return ChanAmpAssign[8][headStage]
End
//==================================================================================================
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
//==================================================================================================
///@brief Return the channel of the currently selected head stage
Function AI_GetAmpChannel(panelTitle, headStage)
	string panelTitle
	variable headStage

	Wave ChanAmpAssign = GetChanAmpAssign(panelTitle)

	return ChanAmpAssign[9][headStage]
End
//==================================================================================================
/// @brief changes mode of user linked MCC based on headstage number
Function AI_SwitchClampMode(panelTitle, headStage, mode)
	string panelTitle
	variable headStage
	variable mode

	string serial    = AI_GetAmpMCCSerial(panelTitle, headStage)
	variable channel = AI_GetAmpChannel(panelTitle, headStage)

	if(!AI_IsValidSerialAndChannel(mccSerial=serial, channel=channel))
		print "No Amp is linked with this headstage"
		return NaN
	endif

	AI_SwitchAxonMode(panelTitle, serial, channel, mode)
End
//==================================================================================================
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
Constant MCC_SETBRIDGEBALRESIST_FUNC     = 0x060
Constant MCC_SETBRIDGEBALENABLE_FUNC     = 0x070
Constant MCC_SETNEUTRALIZATIONCAP_FUNC   = 0x080
Constant MCC_SETNEUTRALIZATIONENABL_FUNC = 0x090
Constant MCC_AUTOPIPETTEOFFSET_FUNC      = 0x100
Constant MCC_SETPIPETTEOFFSET_FUNC       = 0x200
Constant MCC_GETPIPETTEOFFSET_FUNC       = 0x300
/// @}

/// @brief Generic interface to call MCC amplifier functions
///
/// @param panelTitle locked panel name to work on
/// @param headStage  number of the headStage, must be between 0 and 7
/// @param mode       one of V_CLAMP_MODE, I_CLAMP_MODE or I_EQUAL_ZERO_MODE
/// @param func       Function to call
/// @param value      Numerical value to send, ignored by getter functions (MCC_GETHOLDING_FUNC and MCC_GETPIPETTEOFFSET_FUNC)
///
/// @returns return value or error condition. An error is indicated by a return value of NaN.
Function AI_SendToAmp(panelTitle, headStage, mode, func, value)
	string panelTitle
	variable headStage, mode, func, value

	variable ret, channel, headstageMode
	string serial, str

	ASSERT(headStage >= 0 && headStage <= 7, "invalid headStage index")
	ASSERT(mode == V_CLAMP_MODE || mode == I_CLAMP_MODE || mode == I_EQUAL_ZERO_MODE, "invalid mode")

	headstageMode = AI_MIESHeadstageMode(panelTitle, headStage)

	if(headstageMode != mode)
		printf "Headstage %d is in %s but the required one is %s\r", headstage, ConvertAmplifierModeToString(headstageMode), ConvertAmplifierModeToString(mode)
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
		default:
			ASSERT(0, "Unknown function")
			break
	endswitch

	if(!IsFinite(ret))
		print "Amp communication error. Check associations in hardware tab and/or use Query connected amps button"
	endif

	return ret
End
//==================================================================================================
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
//==================================================================================================
/// @returns the mode of the headstage defined in the locked DA_ephys panel,
///          can be V_CLAMP_MODE or I_CLAMP_MODE
Function AI_MIESHeadstageMode(panelTitle, headStage)
	string panelTitle
	variable headStage  // 0 through 7
						// MIESheadstage 1 has radio buttons 0 and 1

	string ctrl
	sprintf ctrl, "Radio_ClampMode_%d", (headStage * 2)

	return GetCheckBoxState(panelTitle, ctrl) == CHECKBOX_SELECTED ? V_CLAMP_MODE : I_CLAMP_MODE
End
//==================================================================================================
Function AI_UpdateAmpModel(panelTitle, cntrlName)
	string panelTitle
	string cntrlName

	if(HSU_DeviceIsUnlocked(panelTitle, silentCheck=1))
		print "Associate the panel with a DAC prior to using panel"
		return 0
	endif

	variable headStage  = GetSliderPositionIndex(panelTitle, "slider_DataAcq_ActiveHeadstage")
	wave AmpStoragewave = GetAmplifierParamStorageWave(panelTitle)

	ControlInfo /w = $panelTitle $cntrlName
	ASSERT(V_flag != 0, "non-existing window or control")

	strswitch(cntrlName)
		//V-clamp controls
		case "setvar_DataAcq_Hold_VC":
			AmpStorageWave[0][0][headStage] = v_value
			AI_SendToAmp(panelTitle, headStage, V_CLAMP_MODE, MCC_SETHOLDING_FUNC, v_value * 1e-3)
			break
		case "check_DatAcq_HoldEnableVC":
			AmpStorageWave[1][0][headStage] = v_value
			AI_SendToAmp(panelTitle, headStage, V_CLAMP_MODE, MCC_SETHOLDINGENABLE_FUNC, v_value)
			break
		case "setvar_DataAcq_WCC":
			AmpStorageWave[2][0][headStage] = v_value
			AI_SendToAmp(panelTitle, headStage, V_CLAMP_MODE, MCC_SETWHOLECELLCOMPCAP_FUNC, v_value * 1e-12)
			break
		case "setvar_DataAcq_WCR":
			AmpStorageWave[3][0][headStage] = v_value
			AI_SendToAmp(panelTitle, headStage, V_CLAMP_MODE, MCC_SETWHOLECELLCOMPRESIST_FUNC, v_value * 1e6)
			break
		case "check_DatAcq_WholeCellEnable":
			AmpStorageWave[4][0][headStage] = v_value
			AI_SendToAmp(panelTitle, headStage, V_CLAMP_MODE, MCC_SETWHOLECELLCOMPENABLE_FUNC, v_value)
			break
		case "setvar_DataAcq_RsCorr":
			AmpStorageWave[5][0][headStage] = v_value
			AI_SendToAmp(panelTitle, headStage, V_CLAMP_MODE, MCC_SETRSCOMPCORRECTION_FUNC, v_value)
			break
		case "setvar_DataAcq_RsPred":
			AmpStorageWave[6][0][headStage] = v_value
			AI_SendToAmp(panelTitle, headStage, V_CLAMP_MODE, MCC_SETRSCOMPPREDICTION_FUNC, v_value)
			break
		case "check_DatAcq_RsCompEnable":
			AmpStorageWave[7][0][headStage] = v_value
			AI_SendToAmp(panelTitle, headStage, V_CLAMP_MODE, MCC_SETRSCOMPENABLE_FUNC, v_value)
			break
		case "setvar_DataAcq_PipetteOffset_VC":
			AmpStorageWave[8][0][headStage] = v_value
			AI_SendToAmp(panelTitle, headStage, V_CLAMP_MODE, MCC_SETPIPETTEOFFSET_FUNC, v_value * 1e-3)
			break
		// I-Clamp controls
		case "setvar_DataAcq_Hold_IC":
			AmpStorageWave[16][0][headStage] = v_value
			AI_SendToAmp(panelTitle, headStage, I_CLAMP_MODE, MCC_SETHOLDING_FUNC, v_value * 1e-12)
			break
		case "check_DatAcq_HoldEnable":
			AmpStorageWave[17][0][headStage] = v_value
			AI_SendToAmp(panelTitle, headStage, I_CLAMP_MODE, MCC_SETHOLDINGENABLE_FUNC, v_value)
			break
		case "setvar_DataAcq_BB":
			AmpStorageWave[18][0][headStage] = v_value
			AI_SendToAmp(panelTitle, headStage, I_CLAMP_MODE, MCC_SETBRIDGEBALRESIST_FUNC, v_value * 1e6)
			break
		case "check_DatAcq_BBEnable":
			AmpStorageWave[19][0][headStage] = v_value
			AI_SendToAmp(panelTitle, headStage, I_CLAMP_MODE, MCC_SETBRIDGEBALENABLE_FUNC, v_value)
			break
		case "setvar_DataAcq_CN":
			AmpStorageWave[20][0][headStage] = v_value
			AI_SendToAmp(panelTitle, headStage, I_CLAMP_MODE, MCC_SETNEUTRALIZATIONCAP_FUNC, v_value * 1e-12)
			break
		case "check_DatAcq_CNEnable":
			AmpStorageWave[21][0][headStage] = v_value
			AI_SendToAmp(panelTitle, headStage, I_CLAMP_MODE, MCC_SETNEUTRALIZATIONENABL_FUNC, v_value)
			break
		case "setvar_DataAcq_AutoBiasV":
			AmpStorageWave[22][0][headStage] = v_value
			break
		case "setvar_DataAcq_AutoBiasVrange":
			AmpStorageWave[23][0][headStage] = v_value
			break
		case "setvar_DataAcq_IbiasMax":
			AmpStorageWave[24][0][headStage] = v_value
			break
		case "check_DataAcq_AutoBias":
			AmpStorageWave[25][0][headStage] = v_value
			break
		// I Zero controls
		case "check_DataAcq_IzeroEnable":
			AmpStorageWave[30][0][headStage] = v_value
			break
		default:
			printf "BUG: unknown control %s\r", cntrlName
			break
	endswitch
End
//==================================================================================================

Function AI_UpdateAmpView(panelTitle, MIESHeadStageNo)
	string panelTitle
	variable MIESHeadStageNo

	Variable Param
	Wave AmpStorageWave = GetAmplifierParamStorageWave(panelTitle)

	// V-Clamp controls
	Param = AmpStorageWave[0][0][MIESHeadStageNo]
	setvariable setvar_DataAcq_Hold_VC WIN = $panelTitle, value= _NUM:Param

	Param = AmpStorageWave[1][0][MIESHeadStageNo]
	checkbox check_DatAcq_HoldEnableVC WIN = $panelTitle, Value = Param
	Param = AmpStorageWave[2][0][MIESHeadStageNo]
	setvariable setvar_DataAcq_WCC WIN = $panelTitle, value= _NUM:Param
	Param = AmpStorageWave[3][0][MIESHeadStageNo]
	setvariable setvar_DataAcq_WCR WIN = $panelTitle, value= _NUM:Param
	Param = AmpStorageWave[4][0][MIESHeadStageNo]
	checkbox check_DatAcq_WholeCellEnable WIN = $panelTitle, Value = Param
	Param = AmpStorageWave[5][0][MIESHeadStageNo]
	setvariable setvar_DataAcq_RsCorr WIN = $panelTitle, value= _NUM:Param
	Param = AmpStorageWave[6][0][MIESHeadStageNo]
	setvariable setvar_DataAcq_RsPred WIN = $panelTitle, value= _NUM:Param
	Param = AmpStorageWave[7][0][MIESHeadStageNo]
	checkbox check_DatAcq_RsCompEnable WIN = $panelTitle, Value = Param
	Param = AmpStorageWave[8][0][MIESHeadStageNo]
	setvariable setvar_DataAcq_PipetteOffset_VC WIN = $panelTitle, Value = _NUM:Param

	// I-Clamp controls
	Param = AmpStorageWave[16][0][MIESHeadStageNo]
	setvariable setvar_DataAcq_Hold_IC WIN = $panelTitle, value= _NUM:Param
	Param = AmpStorageWave[17][0][MIESHeadStageNo]
	checkbox check_DatAcq_HoldEnable win = $panelTitle, Value = Param
	Param = AmpStorageWave[18][0][MIESHeadStageNo]
	setvariable setvar_DataAcq_BB WIN = $panelTitle, value= _NUM:Param
	Param = AmpStorageWave[19][0][MIESHeadStageNo]
	checkbox check_DatAcq_BBEnable win = $panelTitle, Value = Param
	Param = AmpStorageWave[20][0][MIESHeadStageNo]
	setvariable setvar_DataAcq_CN WIN = $panelTitle, value= _NUM:Param
	Param = AmpStorageWave[21][0][MIESHeadStageNo]
	checkbox check_DatAcq_CNEnable WIN = $panelTitle, Value = Param
	Param = AmpStorageWave[22][0][MIESHeadStageNo]
	setvariable setvar_DataAcq_AutoBiasV WIN = $panelTitle, value= _NUM:Param
	Param = AmpStorageWave[23][0][MIESHeadStageNo]
	setvariable setvar_DataAcq_AutoBiasVrange WIN = $panelTitle, value= _NUM:Param
	Param = AmpStorageWave[24][0][MIESHeadStageNo]
	setvariable setvar_DataAcq_IbiasMax WIN = $panelTitle, value= _NUM:Param
	Param = AmpStorageWave[25][0][MIESHeadStageNo]
	checkbox check_DataAcq_AutoBias WIN = $panelTitle, Value = Param

	// I = zero controls
	Param =  AmpStorageWave[30][0][MIESHeadStageNo]
	checkbox check_DataAcq_IzeroEnable WIN = $panelTitle, Value = Param
End

//==================================================================================================
/// Brief description of the function createAmplifierSettingsWave
/// This function to create wave of amplifier settings, and a corresponding key wave.  This wave will then be sent to the 
/// ED_createWaveNotes to amend to the general history settings for reporting to the wave notations.
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
/// @param SweepNo -- the current data wave sweep number
///
/// The function is called from DM_SaveITCData function, if the saveAmpSettingsCheck box is checked on the DA_Ephys panel.
/// 
/// The function will call the MC700B and query it for the settings and will be added to the Settings wave before it is sent off to the 
/// ED_createWaveNotes function.
function AI_createAmpliferSettingsWave(panelTitle, SavedDataWaveName, SweepNo)
	string panelTitle
	string SavedDataWaveName
	Variable SweepNo
		
	Wave/SDFR=$HSU_DataFullFolderPathString(panelTitle) ChannelClampMode
		
	// get all the Amp connection information
	String controlledHeadStage = DC_ControlStatusListString("DataAcq_HS", "check",panelTitle)  	
	// get the number of headStages...used for building up the ampSettingsWave
	variable noHeadStages = itemsinlist(controlledHeadStage, ";")
		
	// sweep count
	Variable sweepCount = SweepNo
	
	// Location for the settings wave
	String ampSettingsWavePath
	sprintf ampSettingsWavePath, "%s:%s" Path_AmpSettingsFolder(panelTitle), "ampSettings"
	
	// see if the wave exists....if so, append to it...if not, create it
	wave /z ampSettingsWave = $ampSettingsWavePath
	if (!WaveExists(ampSettingsWave))
		// create the 3 dimensional wave
		make /o /n = (1, 35, noHeadStages ) $ampSettingsWavePath = 0
		Wave /z ampSettingsWave = $ampSettingsWavePath
	endif	
	//Redimension/N=(1, 15, noHeadStages ) ampSettingsWave
		
	// make the amp settings key wave
	String ampSettingsKeyPath
	sprintf ampSettingsKeyPath, "%s:%s" Path_AmpSettingsFolder(panelTitle), "ampSettingsKey"
	
	// see if the wave exists....if so, skip this part..if not, create it
	wave/Z/T ampSettingsKey = $ampSettingsKeyPath
	if (!WaveExists(ampSettingsKey))
		//print "making settingsKey Wave...."
		// create the 2 dimensional wave
		make /T /o  /n = (3, 35) $ampSettingsKeyPath
		Wave/T ampSettingsKey = $ampSettingsKeyPath
	
		// Row 0: Parameter
		// Row 1: Units	
		// Row 2: Tolerance factor
			
		// Add dimension labels to the ampSettingsKey wave
		SetDimLabel 0, 0, Parameter, ampSettingsKey
		SetDimLabel 0, 1, Units, ampSettingsKey
		SetDimLabel 0, 2, Tolerance, ampSettingsKey
		
		// And now populate the wave
		ampSettingsKey[0][0] =  "V-Clamp Holding Enable"
		ampSettingsKey[1][0] =  "On/Off"
		ampSettingsKey[2][0] =  "-"
		
		ampSettingsKey[0][1] =   "V-Clamp Holding Level"
		ampSettingsKey[1][1] =  "mV"
		ampSettingsKey[2][1] =  "0.9"
		
		ampSettingsKey[0][2] =   "Osc Killer Enable"
		ampSettingsKey[1][2] =   "On/Off"
		ampSettingsKey[2][2] =   "-"
		
		ampSettingsKey[0][3] =   "RsComp Bandwidth"
		ampSettingsKey[1][3] =   "Hz"
		ampSettingsKey[2][3] =   "0.9"
		
		ampSettingsKey[0][4] =   "RsComp Correction"
		ampSettingsKey[1][4] =   "%"
		ampSettingsKey[2][4] =   "0.9"
		
		ampSettingsKey[0][5] =   "RsComp Enable"
		ampSettingsKey[1][5] =   "On/Off"
		ampSettingsKey[2][5] =   "-"
		
		ampSettingsKey[0][6] =   "RsComp Prediction"
		ampSettingsKey[1][6] =   "%"
		ampSettingsKey[2][6] =   "0.9"
		
		ampSettingsKey[0][7] =   "Whole Cell Comp Enable"
		ampSettingsKey[1][7] =   "On/Off"
		ampSettingsKey[2][7] =   "-"
		
		ampSettingsKey[0][8] =   "Whole Cell Comp Cap"
		ampSettingsKey[1][8] =   "pF"
		ampSettingsKey[2][8] =   "0.9"
		
		ampSettingsKey[0][9] =   "Whole Cell Comp Resist"
		ampSettingsKey[1][9] =   "MOhm"
		ampSettingsKey[2][9] =   "0.9"
		
		ampSettingsKey[0][10] =   "I-Clamp Holding Enable"
		ampSettingsKey[1][10] =   "On/Off"
		ampSettingsKey[2][10] =   "-"
		
		ampSettingsKey[0][11] =   "I-Clamp Holding Level"
		ampSettingsKey[1][11] =   "pA"
		ampSettingsKey[2][11] =   "0.9"
		
		ampSettingsKey[0][12] =   "Neut Cap Enabled"
		ampSettingsKey[1][12] =   "On/Off"
		ampSettingsKey[2][12] =   "-"
		
		ampSettingsKey[0][13] =   "Neut Cap Value"
		ampSettingsKey[1][13] =   "pF"
		ampSettingsKey[2][13] =   "0.9"
		
		ampSettingsKey[0][14] =   "Bridge Bal Enable"
		ampSettingsKey[1][14] =   "On/Off"
		ampSettingsKey[2][14] =   "-"
		
		ampSettingsKey[0][15] =   "Bridge Bal Value"
		ampSettingsKey[1][15] =   "MOhm"
		ampSettingsKey[2][15] =   "0.9"
		
		// and now add the Axon values to the amp settings key
		ampSettingsKey[0][16] =   "Serial Number"
		ampSettingsKey[1][16] =   ""
		ampSettingsKey[2][16] =   ""
		
		ampSettingsKey[0][17] =   "Channel ID"
		ampSettingsKey[1][17] =   ""
		ampSettingsKey[2][17] =   ""
		
		ampSettingsKey[0][18] =   "ComPort ID"
		ampSettingsKey[1][18] =   ""
		ampSettingsKey[2][18] =   ""		
		
		ampSettingsKey[0][19] =   "AxoBus ID"
		ampSettingsKey[1][19] =   ""
		ampSettingsKey[2][19] =   ""
		
		ampSettingsKey[0][20] =   "Operating Mode"
		ampSettingsKey[1][20] =   ""
		ampSettingsKey[2][20] =   ""
		
		ampSettingsKey[0][21] =   "Scaled Out Signal"
		ampSettingsKey[1][21] =   ""
		ampSettingsKey[2][21] =   ""
		
		ampSettingsKey[0][22] =   "Alpha"
		ampSettingsKey[1][22] =   ""
		ampSettingsKey[2][22] =   ""
				
		ampSettingsKey[0][23] =   "Scale Factor"
		ampSettingsKey[1][23] =   ""
		ampSettingsKey[2][23] =   ""		
		
		ampSettingsKey[0][24] =   "Scale Factor Units"
		ampSettingsKey[1][24] =   ""
		ampSettingsKey[2][24] =   ""		
		
		ampSettingsKey[0][25] =   "LPF Cutoff"
		ampSettingsKey[1][25] =   ""
		ampSettingsKey[2][25] =   ""
		
		ampSettingsKey[0][26] =   "Membrane Cap"
		ampSettingsKey[1][26] =   "pF"
		ampSettingsKey[2][26] =   "0.9"
		
		ampSettingsKey[0][27] =   "Ext Cmd Sens"
		ampSettingsKey[1][27] =   ""
		ampSettingsKey[2][27] =   ""
		
		ampSettingsKey[0][28] =   "Raw Out Signal"
		ampSettingsKey[1][28] =   ""
		ampSettingsKey[2][28] =   ""
		
		ampSettingsKey[0][29] =   "Raw Scale Factor"
		ampSettingsKey[1][29] =   ""
		ampSettingsKey[2][29] =   ""
		
		ampSettingsKey[0][30] =   "Raw Scale Factor Units"
		ampSettingsKey[1][30] =   ""
		ampSettingsKey[2][30] =   ""
		
		ampSettingsKey[0][31] =   "Hardware Type"
		ampSettingsKey[1][31] =   ""
		ampSettingsKey[2][31] =   ""
		
		ampSettingsKey[0][32] =   "Secondary Alpha"
		ampSettingsKey[1][32] =   ""
		ampSettingsKey[2][32] =   ""
		
		ampSettingsKey[0][33] =   "Secondary LPF Cutoff"
		ampSettingsKey[1][33] =   ""
		ampSettingsKey[2][33] =   ""
		
		ampSettingsKey[0][34] =   "Series Resistance"
		ampSettingsKey[1][34] =   "MOhms"
		ampSettingsKey[2][34] =   "0.9"		
	endif
	
	// Now populate the Settings Wave
	// the wave is 1 row, 35 columns, and headstage number layers
	// first...determine if the head stage is being controlled
	variable i
	for(i = 0; i < noHeadStages ; i += 1)
		Variable hsControl = str2num(stringfromlist(i, controlledHeadStage))
		if (hsControl)
			string mccSerial    = AI_GetAmpMCCSerial(panelTitle, i)
			variable axonSerial = AI_GetAmpAxonSerial(panelTitle, i)
			variable channel    = AI_GetAmpChannel(panelTitle, i)
			
			if(AI_IsValidSerialAndChannel(axonSerial=axonSerial, mccSerial=mccSerial, channel=channel)) // checks to make sure amp is associated with MIES headstage

				MCC_SelectMultiClamp700B(mccSerial, channel)

				// now start to query the amp to get the status
				//Figure out if we are looking at current clamp mode or voltage clamp mode
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
			endif
		endif
	endfor
	
	// now call the function that will create the wave notes	
	ED_createWaveNotes(ampSettingsWave, ampSettingsKey, SavedDataWaveName, SweepCount, panelTitle)
	
END

////==================================================================================================
/// Brief description of the function AI_createAmplifierTextDocWave
/// This function to create wave of text documentation inputs, and a corresponding key wave.  This wave will then be sent to the 
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
/// @param SweepNo -- the current data wave sweep number
/// 
/// The function will take text input from the user, in a manner yet to be determined, and append them to the savedDataWave
function AI_createAmpliferTextDocWave(panelTitle, SavedDataWaveName, SweepNo)
	string panelTitle
	string SavedDataWaveName
	Variable SweepNo	
	
	// Location for the text documentation wave
	String ampTextDocWavePath
	sprintf ampTextDocWavePath, "%s:%s" Path_AmpSettingsFolder(panelTitle), "ampTextDoc"
	
	// sweep count
	Variable sweepCount = SweepNo
	
	// get all the Amp connection information
	String controlledHeadStage = DC_ControlStatusListString("DataAcq_HS", "check",panelTitle)  	
	// get the number of headStages...used for building up the ampSettingsWave
	variable noHeadStages = itemsinlist(controlledHeadStage, ";")
	
	// see if the wave exists....if so, append to it...if not, create it
	wave /z /t ampTextDocWave = $ampTextDocWavePath
	//print "Does the settings wave exist?..."
	if (!WaveExists(ampTextDocWave))
		//print "making ampSettingsWave..."
		// create the 3 dimensional wave
		make /T /o /n = (1, 16, noHeadStages ) $ampTextDocWavePath
		Wave /T /z ampTextDocWave = $ampTextDocWavePath
	endif
	
	// make the amp settings text doc key wave
	String ampTextDocKeyPath
	sprintf ampTextDocKeyPath, "%s:%s" Path_AmpSettingsFolder(panelTitle), "ampTextDocKey"
	
	// see if the wave exists....if so, skip this part..if not, create it
	//print "Does the key wave exist?"
	wave/T ampTextDocKey = $ampTextDocKeyPath
	if (!WaveExists(ampTextDocKey))
		//print "making settingsKey Wave...."
		// create the 2 dimensional wave
		make /T /o  /n = (3, 16) $ampTextDocKeyPath
		Wave/T ampTextDocKey = $ampTextDocKeyPath
	
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
function createDummySettingsWave(panelTitle, SavedDataWaveName, SweepNo)
	string panelTitle
	string SavedDataWaveName
	Variable SweepNo

	// sweep count
	Variable sweepCount = SweepNo
	
	// Location for the settings wave
	String dummySettingsWavePath
	sprintf dummySettingsWavePath, "%s:%s" Path_AmpSettingsFolder(panelTitle), "dummySettings"
	
	// see if the wave exists....if so, append to it...if not, create it
	wave /z dummySettingsWave = $dummySettingsWavePath
	//print "Does the settings wave exist?..."
	if (!WaveExists(dummySettingsWave))
		//print "making ampSettingsWave..."
		// create the 3 dimensional wave
		make /o /n = (1, 6, 8) $dummySettingsWavePath = 0
		Wave /z dummySettingsWave = $dummySettingsWavePath
	endif	
		
	// make the amp settings key wave
	String dummySettingsKeyPath
	sprintf dummySettingsKeyPath, "%s:%s" Path_AmpSettingsFolder(panelTitle), "dummySettingsKey"
	
	// see if the wave exists....if so, skip this part..if not, create it
	//print "Does the key wave exist?"
	wave/T dummySettingsKey = $dummySettingsKeyPath
	if (!WaveExists(dummySettingsKey))
		//print "making settingsKey Wave...."
		// create the 2 dimensional wave
		make /T /o  /n = (3, 6) $dummySettingsKeyPath
		Wave/T dummySettingsKey = $dummySettingsKeyPath
	
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
	for(headStageControlledCounter = 0;headStageControlledCounter < 8 ;headStageControlledCounter += 1)
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
	ExecuteScriptText "\"C:\Program Files (x86)\Molecular Devices\MultiClamp 700B Commander\MC700B.exe\" /S00834380 /T1&2"// /C\"C:\Program Files (x86)\Molecular Devices\MultiClamp 700B Commander\Configurations\Config00834380.mcc\""
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

//==================================================================================================


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
//==================================================================================================

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
//==================================================================================================

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
//==================================================================================================

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
//==================================================================================================


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
//==================================================================================================

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

//==================================================================================================
