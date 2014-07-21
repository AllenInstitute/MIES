/// @file TJ_MIES_ExperimentDocumentation.ipf
/// @brief Brief description of Experiment Documentation 

#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Function /t AI_ReturnListOf700BChannels(panelTitle)
	string panelTitle
	Variable TotalNoChannels
	Variable i = 0
	String ChannelList = ""
	String Value
	String AmpAndChannel
	//make/o/n=0 W_TelegraphServers
	//AxonTelegraphFindServers
	wave /z W_TelegraphServers = $(Path_AmpFolder(panelTitle) + ":W_TelegraphServers")
	TotalNoChannels = DimSize(W_TelegraphServers, 0 )// 0 is for rows, 1 for columns, 2 for layers, 3 for chunks
		
		if(TotalNoChannels > 0)
			do
			sprintf Value, "%g" W_TelegraphServers[i][0]
//			sprintf Value, "%g" W_TelegraphServers[i][0]
			sprintf AmpAndChannel, "AmpNo %s Chan %g", Value, W_TelegraphServers[i][1]
			ChannelList = addListItem(AmpAndChannel, ChannelList, ";", i)
		//	ChannelList += "AmpNo " + Value + " Chan " + num2str(W_TelegraphServers[i][1]) + ";"
			i += 1
			while(i < TotalNoChannels)
		endif
	
	if(cmpstr(ChannelList, "") == 0)
		ChannelList = "MC not available;"
		print "Activate Multiclamp Commander software to populate list of available amplifiers"
	endif
	
	return ChannelList

End


//==================================================================================================

Function /C AI_RetrieveADGain(panelTitle, AmpSerialNumber, AmpChannel) // returns AD gain of amp in selected mode - mode needs to be switched to return gain for both modes (I-clamp, V-clamp)
	string panelTitle			 // gain is returned in V/pA for V-Clamp, V/mV for I-Clamp
	variable AmpSerialNumber
	variable AmpChannel
	variable /C ADGain = 0
	STRUCT AxonTelegraph_DataStruct tds
	tds.version = 13
	AxonTelegraphGetDataStruct(AmpSerialNumber, AmpChannel, 1, tds)
	if(tds.OperatingMode == 0)
		ADGain = cmplx((tds.ScaleFactor * tds.Alpha) / 1000,  tds.OperatingMode) // real component is the gain, imaginary component is the clamp mode.
	elseif(tds.OperatingMode == 1)
		ADGain = cmplx((tds.ScaleFactor * tds.Alpha) / 1000,  tds.OperatingMode) // real component is the gain, imaginary component is the clamp mode.
	endif
	
	return ADGain
End
//==================================================================================================

Function /C AI_RetrieveDAGain(panelTitle, AmpSerialNumber, AmpChannel) // returns DA gain of amp in selected mode - mode needs to be switched to return gain for both modes (I-clamp, V-clamp)
	string panelTitle				 // gain is returned in mV/V for V-Clamp, V/mV for I clamp
	variable AmpSerialNumber
	variable AmpChannel
	variable /C DAGain = 0
	STRUCT AxonTelegraph_DataStruct tds
	tds.version = 13
	AxonTelegraphGetDataStruct(AmpSerialNumber, AmpChannel, 1, tds)
	if(tds.OperatingMode == 0)
		DAGain = cmplx(tds.ExtCmdSens * 1000, tds.OperatingMode) // real component is the gain, imaginary component is the clamp mode.
	elseif(tds.OperatingMode == 1)
		DAGain = cmplx(tds.ExtCmdSens * 1e12, tds.OperatingMode) // real component is the gain, imaginary component is the clamp mode.
	endif

	return DAGain
End
//==================================================================================================

Function AI_SwitchAxonAmpMode(panelTitle, AmpSerialNumber, AmpChannel) // changes the mode of the amplifier between I-Clamp and V-Clamp depending on the mode when function initiates
	string panelTitle
	variable AmpSerialNumber
	variable AmpChannel	
	string AmpSerialNumberString
	sprintf AmpSerialNumberString, "%.8d" AmpSerialNumber
	MCC_SelectMultiClamp700B(AmpSerialNumberString, AmpChannel)
	variable Mode = MCC_GetMode()
	if(Mode == 0)
		MCC_SetMode(1)
	elseif(Mode == 1)
		MCC_SetMode(0)
	endif
	//MCC_SetMode
	//MCC_GetMode
End
//==================================================================================================
Function AI_ReturnHeadstageChanAndSer(panelTitle, HeadstageNo)
	string panelTitle
	variable HeadstageNo
End
//==================================================================================================
Function AI_IsAmpStillAvailable(panelTitle, AmpSerialNumber, AmpChannel) // no good way to do this
	string panelTitle
	variable AmpSerialNumber
	variable AmpChannel
	string AmpSerialNumberString
	sprintf AmpSerialNumberString, "%.8d" AmpSerialNumber
	MCC_SelectMultiClamp700B(AmpSerialNumberString, AmpChannel);AbortOnRTE
	
End
//==================================================================================================

Function AI_SwitchAxonToVClamp(panelTitle, AmpSerialNumber, AmpChannel)
	string panelTitle
	variable AmpSerialNumber
	variable AmpChannel	
	string AmpSerialNumberString
	sprintf AmpSerialNumberString, "%.8d" AmpSerialNumber
	MCC_SelectMultiClamp700B(AmpSerialNumberString, AmpChannel)
	variable ErrorCode = MCC_SetMode(0)
	if (numtype(ErrorCode) == 2) // NaN is returned
		DFREF saveDFR = GetDataFolderDFR()
		SetDataFolder  $Path_AmpFolder(panelTitle)
		MCC_FindServers /Z = 1
		SetDataFolder saveDFR
		if(V_flag == 0) // checks to see if MCC_FindServers worked without error
			MCC_SetMode(0)
		elseif(V_flag > 0)
			print " Mode cannot be switched. Linked MCC is longer present"
		endif
	endif
End
//==================================================================================================
Function AI_SwitchAxonToIClamp(panelTitle, AmpSerialNumber, AmpChannel)
	string panelTitle
	variable AmpSerialNumber
	variable AmpChannel	
	string AmpSerialNumberString
	sprintf AmpSerialNumberString, "%.8d" AmpSerialNumber
	MCC_SelectMultiClamp700B(AmpSerialNumberString, AmpChannel)
	variable ErrorCode = MCC_SetMode(1)
	if (numtype(ErrorCode) == 2) // NaN is returned
		DFREF saveDFR = GetDataFolderDFR()
		SetDataFolder  $Path_AmpFolder(panelTitle)
		MCC_FindServers /Z = 1
		SetDataFolder saveDFR
		if(V_flag == 0) // checks to see if MCC_FindServers worked without error
			MCC_SetMode(1)
		elseif(V_flag > 0)
			print " Mode cannot be switched. Linked MCC is longer present"
		endif
	endif
		
End
//==================================================================================================
Function AI_SwitchAxonToIZero(panelTitle, AmpSerialNumber, AmpChannel)
	string panelTitle
	variable AmpSerialNumber
	variable AmpChannel	
	string AmpSerialNumberString
	sprintf AmpSerialNumberString, "%.8d" AmpSerialNumber
	MCC_SelectMultiClamp700B(AmpSerialNumberString, AmpChannel)
	variable ErrorCode = MCC_SetMode(0)
	if (numtype(ErrorCode) == 2) // NaN is returned
		DFREF saveDFR = GetDataFolderDFR()
		SetDataFolder  $Path_AmpFolder(panelTitle)
		MCC_FindServers /Z = 1
		SetDataFolder saveDFR
		if(V_flag == 0) // checks to see if MCC_FindServers worked without error
			MCC_SetMode(0)
		elseif(V_flag > 0)
			print " Mode cannot be switched. Linked MCC is longer present"
		endif
	endif
End
//==================================================================================================

Function AI_GetAxonTeleServerInfo(AmpSerialNumber, AmpChannel)
	variable AmpSerialNumber
	variable AmpChannel
	STRUCT AxonTelegraph_DataStruct tds
	tds.version = 13
	AxonTelegraphGetDataStruct(AmpSerialNumber, AmpChannel, 1, tds)
	//print tds
//	print tds.ScaleFactor
End
//==================================================================================================

Structure AxonTelegraph_DataStruct
	uint32 Version	// Structure version.  Value should always be 13.
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

Function /C AI_ReturnSerialAndChanNumber(panelTitle, HeadStageNo) // finds the link between the headstage and the user associated MCC
	string panelTitle
	variable HeadStageNo
	string wavePath = HSU_DataFullFolderPathString(panelTitle)
	Wave ChanAmpAssign = $(WavePath + ":ChanAmpAssign")
	variable /C SerialNoAndChannelNo
	SerialNoAndChannelNo = cmplx(ChanAmpAssign[8][HeadStageNo], ChanAmpAssign[9][HeadStageNo])
	return SerialNoAndChannelNo
End

//==================================================================================================
Function AI_SwitchClampMode(panelTitle, HeadStageNo, IorVorZeroClamp) // changes mode of user linked MCC based on headstage number
	string panelTitle
	variable HeadStageNo
	variable IorVorZeroClamp  // 0 = V-Clamp, 1 = I-Clamp, 2 = I equals zero
	variable /C SerialAndChannel = AI_ReturnSerialAndChanNumber(panelTitle, HeadStageNo)
	if(real(numtype(SerialAndChannel)) == 2)
	print "No Amp is linked with this headstage"
	elseif(real(numtype(SerialAndChannel)) == 0)
		if(IorVorZeroClamp == 0)
			AI_SwitchAxonToVClamp(panelTitle, real(SerialAndChannel), imag(SerialAndChannel))
		elseif(IorVorZeroClamp == 1)
			AI_SwitchAxonToIClamp(panelTitle,  real(SerialAndChannel),  imag(SerialAndChannel))
		elseif(IorVorZeroClamp == 2)
			AI_SwitchAxonToIZero(panelTitle, real(SerialAndChannel), imag(SerialAndChannel))
		endif
	endif
	
End

//==================================================================================================

Function AI_SendVClampParamToMCC(panelTitle, HeadStageNo)
	string panelTitle
	variable HeadStageNo
	variable /C SerialAndChannel = AI_ReturnSerialAndChanNumber(panelTitle, HeadStageNo)
	string AmpSerialNumberString
	sprintf AmpSerialNumberString, "%.8d" real(SerialAndChannel)
	MCC_SelectMultiClamp700B(AmpSerialNumberString, imag(SerialAndChannel))
	
	//Send holding to MCC
End

//==================================================================================================
//Function AI_CreateAmpDataStorageWave(panelTitle)
	string panelTitle
	string PathToAmplifierFolder = Path_AmpFolder(panelTitle)
	string AmpStorageWaveWaveName
	sprintf AmpStorageWaveWaveName, "%s:%s" Path_AmpSettingsFolder(panelTitle), panelTitle
	make /o /n = (26, 2, 8) $AmpStorageWaveWaveName
	wave AmpStorageWave = $AmpStorageWaveWaveName
	setdimlabel 1, 0, VClamp, AmpStorageWave // labels column 0 (of all layers) with the heading VClamp
	setdimlabel 1, 1, IClamp, AmpStorageWave // labels column 1 (of all layers) with the heading IClamp
	setdimlabel 0, 0, StructureVersion, AmpStorageWave
	setdimlabel 0, 1, SerialNum, AmpStorageWave
	setdimlabel 0, 2, ChannelID, AmpStorageWave
	setdimlabel 0, 3, ComPortID, AmpStorageWave
	setdimlabel 0, 4, AxoBusID, AmpStorageWave
	setdimlabel 0, 5, OperatingMode, AmpStorageWave
	setdimlabel 0, 6, ScaledOutSignal, AmpStorageWave
	setdimlabel 0, 7, Alpha, AmpStorageWave
	setdimlabel 0, 8, ScaleFactor, AmpStorageWave
	setdimlabel 0, 9, ScaleFactorUnits, AmpStorageWave
	setdimlabel 0, 10, LPFCutoff, AmpStorageWave
	setdimlabel 0, 11, ExtCmdSens, AmpStorageWave
	setdimlabel 0, 12, RawOutSignal, AmpStorageWave
	setdimlabel 0, 13, RawScaleFactor, AmpStorageWave
	setdimlabel 0, 14, RawScaleFactorUnits, AmpStorageWave
	setdimlabel 0, 15, HardwareType, AmpStorageWave
	setdimlabel 0, 16, SecondaryLPFCutoff, AmpStorageWave
	setdimlabel 0, 17, SeriesResistance, AmpStorageWave
	setdimlabel 0, 18, PlaceHolder, AmpStorageWave
	setdimlabel 0, 19, PlaceHolder, AmpStorageWave
	setdimlabel 0, 20, PlaceHolder, AmpStorageWave
	setdimlabel 0, 21, PlaceHolder, AmpStorageWave
	setdimlabel 0, 22, PlaceHolder, AmpStorageWave
	setdimlabel 0, 23, PlaceHolder, AmpStorageWave
	setdimlabel 0, 24, PlaceHolder, AmpStorageWave
	setdimlabel 0, 25, PlaceHolder, AmpStorageWave
End

//==================================================================================================
// BELOW ARE COMMAND THAT SEND PARAMETERS, OR ENABLE CONTROLS ON THE MCC PANEL
// the commands are wrapped in several checks that ensure they are only sent when the appropriate mode is active
//==================================================================================================

Function AI_SendVHoldToAmp(panelTitle, HoldingV)
	string panelTitle
	variable HoldingV
	
	//Is the control for an active mode? ex. Is V-clamp active and is the user trying to change the holding potential
	
	// Get the MIES headstage
	controlinfo /w = $panelTitle slider_DataAcq_ActiveHeadstage
	variable MIESHeadstageNo = v_value
	
	if(AI_MIESHeadstageMode(panelTitle, MIESHeadstageNo) == 0) // checks to see if Vclamp is the active mode of the MIES headstage
		if(AI_MIESHeadstageMatchesMCCMode(panelTitle, MIESHeadstageNo) == 1) // check to see if the MCC mode matches the MIES headstage mode
			//Get the associated amp serial number and channel
			variable /C SerialAndChannel = AI_ReturnSerialAndChanNumber(panelTitle, MIESHeadstageNo)
			if(real(numtype(SerialAndChannel)) != 2 && imag(numtype(SerialAndChannel)) != 2)
				string AmpSerialNumberString
				sprintf AmpSerialNumberString, "%.8d" real(SerialAndChannel)
				MCC_SelectMultiClamp700B(AmpSerialNumberString, imag(SerialAndChannel))
				variable Error = MCC_Setholding(HoldingV*1e-3)
				if(numtype(Error) == 2)
					print "Amp communication error. Check associations in hardware tab and/or use Query connected amps button"
				endif
			endif
		endif
	endif
End
//==================================================================================================
Function AI_SendVHoldEnableToAmp(panelTitle, EnableHolding)
	string panelTitle
	variable EnableHolding
	
	//Is the control for an active mode? ex. Is V-clamp active and is the user trying to change the holding potential
	
	// Get the MIES headstage
	controlinfo /w = $panelTitle slider_DataAcq_ActiveHeadstage
	variable MIESHeadstageNo = v_value
	
	if(AI_MIESHeadstageMode(panelTitle, MIESHeadstageNo) == 0) // checks to see if Vclamp is the active mode of the MIES headstage
		if(AI_MIESHeadstageMatchesMCCMode(panelTitle, MIESHeadstageNo) == 1) // check to see if the MCC mode matches the MIES headstage mode
			//Get the associated amp serial number and channel
			variable /C SerialAndChannel = AI_ReturnSerialAndChanNumber(panelTitle, MIESHeadstageNo)
			if(real(numtype(SerialAndChannel)) != 2 && imag(numtype(SerialAndChannel)) != 2)
				string AmpSerialNumberString
				sprintf AmpSerialNumberString, "%.8d" real(SerialAndChannel)
				MCC_SelectMultiClamp700B(AmpSerialNumberString, imag(SerialAndChannel))
				variable Error = MCC_SetholdingEnable(EnableHolding)
				if(numtype(Error) == 2)
					print "Amp communication error. Check associations in hardware tab and/or use Query connected amps button"
				endif
			endif
		endif
	endif
End
//==================================================================================================
Function AI_SendWCCToAmp(panelTitle, Capacitance)
	string panelTitle
	variable Capacitance
	
	//Is the control for an active mode? ex. Is V-clamp active and is the user trying to change the holding potential
	
	// Get the MIES headstage
	controlinfo /w = $panelTitle slider_DataAcq_ActiveHeadstage
	variable MIESHeadstageNo = v_value
	
	if(AI_MIESHeadstageMode(panelTitle, MIESHeadstageNo) == 0) // checks to see if Vclamp is the active mode of the MIES headstage
		if(AI_MIESHeadstageMatchesMCCMode(panelTitle, MIESHeadstageNo) == 1) // check to see if the MCC mode matches the MIES headstage mode
			//Get the associated amp serial number and channel
			variable /C SerialAndChannel = AI_ReturnSerialAndChanNumber(panelTitle, MIESHeadstageNo)
			if(real(numtype(SerialAndChannel)) != 2 && imag(numtype(SerialAndChannel)) != 2) // checks if values the user entered for a MIES headstage return an associated amp
				string AmpSerialNumberString
				sprintf AmpSerialNumberString, "%.8d" real(SerialAndChannel)
				MCC_SelectMultiClamp700B(AmpSerialNumberString, imag(SerialAndChannel))
				variable Error = MCC_SetWholeCellCompCap(Capacitance * 1e-12)
				if(numtype(Error) == 2)
					print "Amp communication error. Check associations in hardware tab and/or use Query connected amps button"
				endif
			endif
		endif
	endif
End
//==================================================================================================
Function AI_SendWCRToAmp(panelTitle, Resistance)
	string panelTitle
	variable Resistance
	
	//Is the control for an active mode? ex. Is V-clamp active and is the user trying to change the holding potential
	
	// Get the MIES headstage
	controlinfo /w = $panelTitle slider_DataAcq_ActiveHeadstage
	variable MIESHeadstageNo = v_value
	
	if(AI_MIESHeadstageMode(panelTitle, MIESHeadstageNo) == 0) // checks to see if Vclamp is the active mode of the MIES headstage
		if(AI_MIESHeadstageMatchesMCCMode(panelTitle, MIESHeadstageNo) == 1) // check to see if the MCC mode matches the MIES headstage mode
			//Get the associated amp serial number and channel
			variable /C SerialAndChannel = AI_ReturnSerialAndChanNumber(panelTitle, MIESHeadstageNo)
			if(real(numtype(SerialAndChannel)) != 2 && imag(numtype(SerialAndChannel)) != 2) // checks if values the user entered for a MIES headstage return an associated amp
				string AmpSerialNumberString
				sprintf AmpSerialNumberString, "%.8d" real(SerialAndChannel)
				MCC_SelectMultiClamp700B(AmpSerialNumberString, imag(SerialAndChannel))
				variable Error = MCC_SetWholeCellCompResist(Resistance * 1e6)
				if(numtype(Error) == 2)
					print "Amp communication error. Check associations in hardware tab and/or use Query connected amps button"
				endif
			endif
		endif
	endif
End
//==================================================================================================
Function AI_SendEnableWCToAmp(panelTitle, EnableWholeCell)
	string panelTitle
	variable EnableWholeCell
	
	//Is the control for an active mode? ex. Is V-clamp active and is the user trying to change the holding potential
	
	// Get the MIES headstage
	controlinfo /w = $panelTitle slider_DataAcq_ActiveHeadstage
	variable MIESHeadstageNo = v_value
	
	if(AI_MIESHeadstageMode(panelTitle, MIESHeadstageNo) == 0) // checks to see if Vclamp is the active mode of the MIES headstage
		if(AI_MIESHeadstageMatchesMCCMode(panelTitle, MIESHeadstageNo) == 1) // check to see if the MCC mode matches the MIES headstage mode
			//Get the associated amp serial number and channel
			variable /C SerialAndChannel = AI_ReturnSerialAndChanNumber(panelTitle, MIESHeadstageNo)
			if(real(numtype(SerialAndChannel)) != 2 && imag(numtype(SerialAndChannel)) != 2) // checks if values the user entered for a MIES headstage return an associated amp
				string AmpSerialNumberString
				sprintf AmpSerialNumberString, "%.8d" real(SerialAndChannel)
				MCC_SelectMultiClamp700B(AmpSerialNumberString, imag(SerialAndChannel))
				variable Error = MCC_SetWholeCellCompEnable(EnableWholeCell)
				if(numtype(Error) == 2)
					print "Amp communication error. Check associations in hardware tab and/or use Query connected amps button"
				endif
			endif
		endif
	endif
End
//==================================================================================================
Function AI_SendRsCompCorrToAmp(panelTitle, Correction)
	string panelTitle
	variable Correction
	
	//Is the control for an active mode? ex. Is V-clamp active and is the user trying to change the holding potential
	
	// Get the MIES headstage
	controlinfo /w = $panelTitle slider_DataAcq_ActiveHeadstage
	variable MIESHeadstageNo = v_value
	
	if(AI_MIESHeadstageMode(panelTitle, MIESHeadstageNo) == 0) // checks to see if Vclamp is the active mode of the MIES headstage
		if(AI_MIESHeadstageMatchesMCCMode(panelTitle, MIESHeadstageNo) == 1) // check to see if the MCC mode matches the MIES headstage mode
			//Get the associated amp serial number and channel
			variable /C SerialAndChannel = AI_ReturnSerialAndChanNumber(panelTitle, MIESHeadstageNo)
			if(real(numtype(SerialAndChannel)) != 2 && imag(numtype(SerialAndChannel)) != 2) // checks if values the user entered for a MIES headstage return an associated amp
				string AmpSerialNumberString
				sprintf AmpSerialNumberString, "%.8d" real(SerialAndChannel)
				MCC_SelectMultiClamp700B(AmpSerialNumberString, imag(SerialAndChannel))
				variable Error = MCC_SetRsCompCorrection(Correction)
				if(numtype(Error) == 2)
					print "Amp communication error. Check associations in hardware tab and/or use Query connected amps button"
				endif
			endif
		endif
	endif
End
//==================================================================================================
Function AI_SendRsCompPredToAmp(panelTitle, Prediction)
	string panelTitle
	variable Prediction
	
	//Is the control for an active mode? ex. Is V-clamp active and is the user trying to change the holding potential
	
	// Get the MIES headstage
	controlinfo /w = $panelTitle slider_DataAcq_ActiveHeadstage
	variable MIESHeadstageNo = v_value
	
	if(AI_MIESHeadstageMode(panelTitle, MIESHeadstageNo) == 0) // checks to see if Vclamp is the active mode of the MIES headstage
		if(AI_MIESHeadstageMatchesMCCMode(panelTitle, MIESHeadstageNo) == 1) // check to see if the MCC mode matches the MIES headstage mode
			//Get the associated amp serial number and channel
			variable /C SerialAndChannel = AI_ReturnSerialAndChanNumber(panelTitle, MIESHeadstageNo)
			if(real(numtype(SerialAndChannel)) != 2 && imag(numtype(SerialAndChannel)) != 2) // checks if values the user entered for a MIES headstage return an associated amp
				string AmpSerialNumberString
				sprintf AmpSerialNumberString, "%.8d" real(SerialAndChannel)
				MCC_SelectMultiClamp700B(AmpSerialNumberString, imag(SerialAndChannel))
				variable Error = MCC_SetRsCompPrediction(Prediction)
				if(numtype(Error) == 2)
					print "Amp communication error. Check associations in hardware tab and/or use Query connected amps button"
				endif
			endif
		endif
	endif
End	
//==================================================================================================
Function AI_SendRsCompEnableToAmp(panelTitle, EnableRsComp)
	string panelTitle
	variable EnableRsComp // 1 = enabled
	
	//Is the control for an active mode? ex. Is V-clamp active and is the user trying to change the holding potential
	
	// Get the MIES headstage
	controlinfo /w = $panelTitle slider_DataAcq_ActiveHeadstage
	variable MIESHeadstageNo = v_value
	
	if(AI_MIESHeadstageMode(panelTitle, MIESHeadstageNo) == 0) // checks to see if Vclamp is the active mode of the MIES headstage
		if(AI_MIESHeadstageMatchesMCCMode(panelTitle, MIESHeadstageNo) == 1) // check to see if the MCC mode matches the MIES headstage mode
			//Get the associated amp serial number and channel
			variable /C SerialAndChannel = AI_ReturnSerialAndChanNumber(panelTitle, MIESHeadstageNo)
			if(real(numtype(SerialAndChannel)) != 2 && imag(numtype(SerialAndChannel)) != 2) // checks if values the user entered for a MIES headstage return an associated amp
				string AmpSerialNumberString
				sprintf AmpSerialNumberString, "%.8d" real(SerialAndChannel)
				MCC_SelectMultiClamp700B(AmpSerialNumberString, imag(SerialAndChannel))
				variable Error = MCC_SetRsCompEnable(EnableRsComp)
				if(numtype(Error) == 2)
					print "Amp communication error. Check associations in hardware tab and/or use Query connected amps button"
				endif
			endif
		endif
	endif
End	


//==================================================================================================
Function AI_SendBiasIToAmp(panelTitle, BiasCurrent)
	string panelTitle
	variable BiasCurrent
	
	//Is the control for an active mode? ex. Is V-clamp active and is the user trying to change the holding potential
	
	// Get the MIES headstage
	controlinfo /w = $panelTitle slider_DataAcq_ActiveHeadstage
	variable MIESHeadstageNo = v_value
	
	if(AI_MIESHeadstageMode(panelTitle, MIESHeadstageNo) == 1) // checks to see if Vclamp is the active mode of the MIES headstage
		if(AI_MIESHeadstageMatchesMCCMode(panelTitle, MIESHeadstageNo) == 1) // check to see if the MCC mode matches the MIES headstage mode
			//Get the associated amp serial number and channel
			variable /C SerialAndChannel = AI_ReturnSerialAndChanNumber(panelTitle, MIESHeadstageNo)
			if(real(numtype(SerialAndChannel)) != 2 && imag(numtype(SerialAndChannel)) != 2) // checks if values the user entered for a MIES headstage return an associated amp
				string AmpSerialNumberString
				sprintf AmpSerialNumberString, "%.8d" real(SerialAndChannel)
				MCC_SelectMultiClamp700B(AmpSerialNumberString, imag(SerialAndChannel))
				variable Error = MCC_SetHolding(BiasCurrent*1e-12)
				if(numtype(Error) == 2)
					print "Amp communication error. Check associations in hardware tab and/or use Query connected amps button"
				endif
			endif
		endif
	endif
End	
//==================================================================================================
Function AI_BiasToAmp(panelTitle, BiasEnable)
	string panelTitle
	variable BiasEnable
	
	//Is the control for an active mode? ex. Is V-clamp active and is the user trying to change the holding potential
	
	// Get the MIES headstage
	controlinfo /w = $panelTitle slider_DataAcq_ActiveHeadstage
	variable MIESHeadstageNo = v_value
	
	if(AI_MIESHeadstageMode(panelTitle, MIESHeadstageNo) == 1) // checks to see if Vclamp is the active mode of the MIES headstage
		if(AI_MIESHeadstageMatchesMCCMode(panelTitle, MIESHeadstageNo) == 1) // check to see if the MCC mode matches the MIES headstage mode
			//Get the associated amp serial number and channel
			variable /C SerialAndChannel = AI_ReturnSerialAndChanNumber(panelTitle, MIESHeadstageNo)
			if(real(numtype(SerialAndChannel)) != 2 && imag(numtype(SerialAndChannel)) != 2) // checks if values the user entered for a MIES headstage return an associated amp
				string AmpSerialNumberString
				sprintf AmpSerialNumberString, "%.8d" real(SerialAndChannel)
				MCC_SelectMultiClamp700B(AmpSerialNumberString, imag(SerialAndChannel))
				variable Error = MCC_SetHoldingEnable(BiasEnable)
				if(numtype(Error) == 2)
					print "Amp communication error. Check associations in hardware tab and/or use Query connected amps button"
				endif
			endif
		endif
	endif
End	
//==================================================================================================
Function AI_BridgeBalanceToAmp(panelTitle, BridgeBalance)
	string panelTitle
	variable BridgeBalance
	
	//Is the control for an active mode? ex. Is V-clamp active and is the user trying to change the holding potential
	
	// Get the MIES headstage
	controlinfo /w = $panelTitle slider_DataAcq_ActiveHeadstage
	variable MIESHeadstageNo = v_value
	
	if(AI_MIESHeadstageMode(panelTitle, MIESHeadstageNo) == 1) // checks to see if Vclamp is the active mode of the MIES headstage
		if(AI_MIESHeadstageMatchesMCCMode(panelTitle, MIESHeadstageNo) == 1) // check to see if the MCC mode matches the MIES headstage mode
			//Get the associated amp serial number and channel
			variable /C SerialAndChannel = AI_ReturnSerialAndChanNumber(panelTitle, MIESHeadstageNo)
			if(real(numtype(SerialAndChannel)) != 2 && imag(numtype(SerialAndChannel)) != 2) // checks if values the user entered for a MIES headstage return an associated amp
				string AmpSerialNumberString
				sprintf AmpSerialNumberString, "%.8d" real(SerialAndChannel)
				MCC_SelectMultiClamp700B(AmpSerialNumberString, imag(SerialAndChannel))
				variable Error = MCC_SetBridgeBalResist(BridgeBalance * 1e6)
				if(numtype(Error) == 2)
					print "Amp communication error. Check associations in hardware tab and/or use Query connected amps button"
				endif
			endif
		endif
	endif
End	
//==================================================================================================

Function AI_BridgeBalanceEnableToAmp(panelTitle, BridgeBalanceEnable)
	string panelTitle
	variable BridgeBalanceEnable
	
	//Is the control for an active mode? ex. Is V-clamp active and is the user trying to change the holding potential
	
	// Get the MIES headstage
	controlinfo /w = $panelTitle slider_DataAcq_ActiveHeadstage
	variable MIESHeadstageNo = v_value
	
	if(AI_MIESHeadstageMode(panelTitle, MIESHeadstageNo) == 1) // checks to see if Vclamp is the active mode of the MIES headstage
		if(AI_MIESHeadstageMatchesMCCMode(panelTitle, MIESHeadstageNo) == 1) // check to see if the MCC mode matches the MIES headstage mode
			//Get the associated amp serial number and channel
			variable /C SerialAndChannel = AI_ReturnSerialAndChanNumber(panelTitle, MIESHeadstageNo)
			if(real(numtype(SerialAndChannel)) != 2 && imag(numtype(SerialAndChannel)) != 2) // checks if values the user entered for a MIES headstage return an associated amp
				string AmpSerialNumberString
				sprintf AmpSerialNumberString, "%.8d" real(SerialAndChannel)
				MCC_SelectMultiClamp700B(AmpSerialNumberString, imag(SerialAndChannel))
				variable Error = MCC_SetBridgeBalEnable(BridgeBalanceEnable)
				if(numtype(Error) == 2)
					print "Amp communication error. Check associations in hardware tab and/or use Query connected amps button"
				endif
			endif
		endif
	endif
End	
//==================================================================================================
Function AI_CapCompToAmp(panelTitle, CapCompCap)
	string panelTitle
	variable CapCompCap
	
	//Is the control for an active mode? ex. Is V-clamp active and is the user trying to change the holding potential
	
	// Get the MIES headstage
	controlinfo /w = $panelTitle slider_DataAcq_ActiveHeadstage
	variable MIESHeadstageNo = v_value
	
	if(AI_MIESHeadstageMode(panelTitle, MIESHeadstageNo) == 1) // checks to see if Vclamp is the active mode of the MIES headstage
		if(AI_MIESHeadstageMatchesMCCMode(panelTitle, MIESHeadstageNo) == 1) // check to see if the MCC mode matches the MIES headstage mode
			//Get the associated amp serial number and channel
			variable /C SerialAndChannel = AI_ReturnSerialAndChanNumber(panelTitle, MIESHeadstageNo)
			if(real(numtype(SerialAndChannel)) != 2 && imag(numtype(SerialAndChannel)) != 2) // checks if values the user entered for a MIES headstage return an associated amp
				string AmpSerialNumberString
				sprintf AmpSerialNumberString, "%.8d" real(SerialAndChannel)
				MCC_SelectMultiClamp700B(AmpSerialNumberString, imag(SerialAndChannel))
				variable Error = MCC_SetNeutralizationCap(CapCompCap * 1e-12)
				if(numtype(Error) == 2)
					print "Amp communication error. Check associations in hardware tab and/or use Query connected amps button"
				endif
			endif
		endif
	endif
End	
//==================================================================================================
Function AI_CapCompEnable(panelTitle, CapCompCapEnable)
	string panelTitle
	variable CapCompCapEnable
	
	//Is the control for an active mode? ex. Is V-clamp active and is the user trying to change the holding potential
	
	// Get the MIES headstage
	controlinfo /w = $panelTitle slider_DataAcq_ActiveHeadstage
	variable MIESHeadstageNo = v_value
	
	if(AI_MIESHeadstageMode(panelTitle, MIESHeadstageNo) == 1) // checks to see if Vclamp is the active mode of the MIES headstage
		if(AI_MIESHeadstageMatchesMCCMode(panelTitle, MIESHeadstageNo) == 1) // check to see if the MCC mode matches the MIES headstage mode
			//Get the associated amp serial number and channel
			variable /C SerialAndChannel = AI_ReturnSerialAndChanNumber(panelTitle, MIESHeadstageNo)
			if(real(numtype(SerialAndChannel)) != 2 && imag(numtype(SerialAndChannel)) != 2) // checks if values the user entered for a MIES headstage return an associated amp
				string AmpSerialNumberString
				sprintf AmpSerialNumberString, "%.8d" real(SerialAndChannel)
				MCC_SelectMultiClamp700B(AmpSerialNumberString, imag(SerialAndChannel))
				variable Error = MCC_SetNeutralizationEnable(CapCompCapEnable)
				if(numtype(Error) == 2)
					print "Amp communication error. Check associations in hardware tab and/or use Query connected amps button"
				endif
			endif
		endif
	endif
End	
//==================================================================================================
Function AI_MIESHeadstageMatchesMCCMode(panelTitle, MIESHeadstageNo) // returns 1 if the MIES headstage mode matches the associated MCC mode
	string panelTitle									  // if these are out of sync the user needs to intervene unless MCC monitoring is enabled (at the time of writing this comment, monitoring has not been implemented)
	variable MIESHeadstageNo
	variable /C SerialAndChannel = AI_ReturnSerialAndChanNumber(panelTitle, MIESHeadstageNo)
	variable Match
	STRUCT AxonTelegraph_DataStruct tds
	tds.version = 13
	AxonTelegraphGetDataStruct(real(SerialAndChannel), imag(SerialAndChannel), 1, tds)
	if(tds.operatingMode == AI_MIESHeadstageMode(panelTitle, MIESHeadstageNo))
		Match = 1
	elseif(tds.operatingMode != AI_MIESHeadstageMode(panelTitle, MIESHeadstageNo))
		Match = 0
	endif
	
	return Match
End
//==================================================================================================
Function AI_MIESHeadstageMode(panelTitle, MIESHeadstageNo) // returns the mode of the headstage defined in the locked DA_ephys panel
	string panelTitle
	variable MIESHeadstageNo // 0 through 7 MIESheadstage 1 has radio buttons 0 and 1 
	string ClampModeRadioButton
	sprintf ClampModeRadioButton, "Radio_ClampMode_%d" (MIESHeadstageNo * 2)
	controlinfo /w = $panelTitle $ClampModeRadioButton
	variable ClampModeRadioButtonState = v_value
	variable MIESHeadstageMode 
	if(ClampModeRadioButtonState == 0)
		MIESHeadstageMode = 1
	elseif(ClampModeRadioButtonState == 1)
		MIESHeadstageMode = 0
	endif
	
	return MIESHeadstageMode
End
//==================================================================================================
Function AI_UpdateAmpModel(panelTitle, cntrlName)
	string panelTitle
	string cntrlName
	string PathToAmplifierFolder = Path_AmpSettingsFolder(panelTitle)
	string PathToAmpStorageWave
	sprintf PathToAmpStorageWave,"%s:%s" PathToAmplifierFolder, panelTitle
	
	controlinfo /w = $panelTitle slider_DataAcq_ActiveHeadstage
	variable MIESHeadStageNo =  v_value
	
	if(waveexists($PathToAmpStorageWave) == 1)
		wave AmpStoragewave = $PathToAmpStorageWave
		strswitch(cntrlName) // used case switch because controlinfo is a slowish command 
			//V-clamp controls
			case "setvar_DataAcq_Hold_VC":
				controlinfo /w = $panelTitle $cntrlName
				AmpStorageWave[0][0][MIESHeadStageNo] = v_value
				AI_SendVHoldToAmp(panelTitle, AmpStorageWave[0][0][MIESHeadStageNo])
				break
			case "check_DatAcq_HoldEnableVC":
				controlinfo /w = $panelTitle $cntrlName
				AmpStorageWave[1][0][MIESHeadStageNo] = v_value
				AI_SendVHoldEnableToAmp(panelTitle, AmpStorageWave[1][0][MIESHeadStageNo])
				break
			case "setvar_DataAcq_WCC":
				controlinfo /w = $panelTitle $cntrlName
				AmpStorageWave[2][0][MIESHeadStageNo] = v_value
				AI_SendWCCToAmp(panelTitle, AmpStorageWave[2][0][MIESHeadStageNo])
				break				
			case "setvar_DataAcq_WCR":
				controlinfo /w = $panelTitle $cntrlName
				AmpStorageWave[3][0][MIESHeadStageNo] = v_value
				AI_SendWCRToAmp(panelTitle, AmpStorageWave[3][0][MIESHeadStageNo])
				break		
			case "check_DatAcq_WholeCellEnable":
				controlinfo /w = $panelTitle $cntrlName
				AmpStorageWave[4][0][MIESHeadStageNo] = v_value
				AI_SendEnableWCToAmp(panelTitle, AmpStorageWave[4][0][MIESHeadStageNo])
				break
			case "setvar_DataAcq_RsCorr":
				controlinfo /w = $panelTitle $cntrlName
				AmpStorageWave[5][0][MIESHeadStageNo] = v_value
				 AI_SendRsCompCorrToAmp(panelTitle, AmpStorageWave[5][0][MIESHeadStageNo])
				break
			case "setvar_DataAcq_RsPred":
				controlinfo /w = $panelTitle $cntrlName
				AmpStorageWave[6][0][MIESHeadStageNo] = v_value
				AI_SendRsCompPredToAmp(panelTitle, AmpStorageWave[6][0][MIESHeadStageNo])
				break								
			case "check_DatAcq_RsCompEnable":
				controlinfo /w = $panelTitle $cntrlName
				AmpStorageWave[7][0][MIESHeadStageNo] = v_value
				AI_SendRsCompEnableToAmp(panelTitle, AmpStorageWave[7][0][MIESHeadStageNo])
				break
			// I-Clamp controls	
			case "setvar_DataAcq_Hold_IC":
				controlinfo /w = $panelTitle $cntrlName
				AmpStorageWave[16][0][MIESHeadStageNo] = v_value
				AI_SendBiasIToAmp(panelTitle, AmpStorageWave[16][0][MIESHeadStageNo])
				break
			case "check_DatAcq_HoldEnable":
				controlinfo /w = $panelTitle $cntrlName
				AmpStorageWave[17][0][MIESHeadStageNo] = v_value
				AI_BiasToAmp(panelTitle, AmpStorageWave[17][0][MIESHeadStageNo])
				break
			case "setvar_DataAcq_BB":
				controlinfo /w = $panelTitle $cntrlName
				AmpStorageWave[18][0][MIESHeadStageNo] = v_value
				AI_BridgeBalanceToAmp(panelTitle, AmpStorageWave[18][0][MIESHeadStageNo])
				break								
			case "check_DatAcq_BBEnable":
				controlinfo /w = $panelTitle $cntrlName
				AmpStorageWave[19][0][MIESHeadStageNo] = v_value
				AI_BridgeBalanceEnableToAmp(panelTitle, AmpStorageWave[19][0][MIESHeadStageNo])
				break
			case "setvar_DataAcq_CN":
				controlinfo /w = $panelTitle $cntrlName
				AmpStorageWave[20][0][MIESHeadStageNo] = v_value
				AI_CapCompToAmp(panelTitle, AmpStorageWave[20][0][MIESHeadStageNo])
				break
			case "check_DatAcq_CNEnable":
				controlinfo /w = $panelTitle $cntrlName
				AmpStorageWave[21][0][MIESHeadStageNo] = v_value
				AI_CapCompEnable(panelTitle, AmpStorageWave[21][0][MIESHeadStageNo])
				break
			case "setvar_DataAcq_AutoBiasV":
				controlinfo /w = $panelTitle $cntrlName
				AmpStorageWave[22][0][MIESHeadStageNo] = v_value
				break
			case "setvar_DataAcq_AutoBiasVrange":
				controlinfo /w = $panelTitle $cntrlName
				AmpStorageWave[23][0][MIESHeadStageNo] = v_value
				break
			case "setvar_DataAcq_Ri":
				controlinfo /w = $panelTitle $cntrlName
				AmpStorageWave[24][0][MIESHeadStageNo] = v_value
				break
			case "check_DataAcq_AutoBias":
				controlinfo /w = $panelTitle $cntrlName
				AmpStorageWave[25][0][MIESHeadStageNo] = v_value
				break
			// I Zero controls
			case "check_DataAcq_IzeroEnable":
				controlinfo /w = $panelTitle $cntrlName
				AmpStorageWave[30][0][MIESHeadStageNo] = v_value
				break
			endswitch			
		endif
		
End
//==================================================================================================

Function AI_UpdateAmpView(panelTitle, MIESHeadStageNo)
	string panelTitle
	variable MIESHeadStageNo
	string PathToAmplifierFolder = Path_AmpSettingsFolder(panelTitle)
	string PathToAmpStorageWave
	sprintf PathToAmpStorageWave,"%s:%s" PathToAmplifierFolder, panelTitle

	Variable Param
	if(waveexists($PathToAmpStorageWave) == 1)
		Wave AmpStorageWave = $PathToAmpStorageWave
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
		setvariable setvar_DataAcq_Ri WIN = $panelTitle, value= _NUM:Param
		Param = AmpStorageWave[25][0][MIESHeadStageNo]
		checkbox check_DataAcq_AutoBias WIN = $panelTitle, Value = Param
		
		// I = zero controls
		Param =  AmpStorageWave[30][0][MIESHeadStageNo]
		checkbox check_DataAcq_IzeroEnable WIN = $panelTitle, Value = Param
	endif
End

//==================================================================================================
Function AI_CreateAmpParamStorageWave(panelTitle)
	string panelTitle
	string PathToAmplifierFolder = Path_AmpFolder(panelTitle)
	string AmpStorageWaveWaveName
	sprintf AmpStorageWaveWaveName, "%s:%s" Path_AmpSettingsFolder(panelTitle), panelTitle
	make /o /n = (31, 1, 8) $AmpStorageWaveWaveName
	wave AmpStorageWave = $AmpStorageWaveWaveName
	setdimlabel 1, 0, HeadstageParam, AmpStorageWave // labels column 0 (of all layers) with the heading VClamp
	setdimlabel 0, 0, HoldingPotential, AmpStorageWave
	setdimlabel 0, 1, HoldingPotentialEnable, AmpStorageWave
	setdimlabel 0, 2, WholeCellCap, AmpStorageWave
	setdimlabel 0, 3, WholeCellRes, AmpStorageWave
	setdimlabel 0, 4, WholeCellEnable, AmpStorageWave
	setdimlabel 0, 5, Correction, AmpStorageWave
	setdimlabel 0, 6, Prediction, AmpStorageWave
	setdimlabel 0, 7, RsCompEnable, AmpStorageWave
	setdimlabel 0, 8,VClampPlaceHolder, AmpStorageWave
	setdimlabel 0, 9, VClampPlaceHolder, AmpStorageWave
	setdimlabel 0, 10, VClampPlaceHolder, AmpStorageWave
	setdimlabel 0, 11, VClampPlaceHolder, AmpStorageWave
	setdimlabel 0, 12, VClampPlaceHolder, AmpStorageWave
	setdimlabel 0, 13, VClampPlaceHolder, AmpStorageWave
	setdimlabel 0, 14, VClampPlaceHolder, AmpStorageWave
	setdimlabel 0, 15, VClampPlaceHolder, AmpStorageWave
	setdimlabel 0, 16, BiasCurrent, AmpStorageWave
	setdimlabel 0, 17, BiasCurrentEnable, AmpStorageWave
	setdimlabel 0, 18, BridgeBalance, AmpStorageWave
	setdimlabel 0, 19, BridgeBalanceEnable, AmpStorageWave
	setdimlabel 0, 20, CapNeut, AmpStorageWave
	setdimlabel 0, 21, CapNeutEnable, AmpStorageWave
	setdimlabel 0, 22, AutoBiasVcom, AmpStorageWave
	setdimlabel 0, 23, AutoBiasVcomVariance, AmpStorageWave
	setdimlabel 0, 24, AutoBiasRi, AmpStorageWave
	setdimlabel 0, 25, AutoBiasEnable, AmpStorageWave
	setdimlabel 0, 26, IclampPlaceHolder, AmpStorageWave
	setdimlabel 0, 27, IclampPlaceHolder, AmpStorageWave
	setdimlabel 0, 28, IclampPlaceHolder, AmpStorageWave
	setdimlabel 0, 29, IclampPlaceHolder, AmpStorageWave
	setdimlabel 0, 30, IZeroEnable, AmpStorageWave
End
////==================================================================================================
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
		
//	string stringPath 
//	sprintf stringPath, "%s:channelClampMode" HSU_DataFullFolderPathString(panelTitle)
//	wave ChannelClampMode = $stringPath
//	print "channelClampMode path: ", stringPath

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
	//print "Does the settings wave exist?..."
	if (!WaveExists(ampSettingsWave))
		//print "making ampSettingsWave..."
		// create the 3 dimensional wave
		make /o /n = (1, 16, noHeadStages ) $ampSettingsWavePath = 0
		Wave /z ampSettingsWave = $ampSettingsWavePath
	endif	
	//Redimension/N=(1, 15, noHeadStages ) ampSettingsWave
		
	// make the amp settings key wave
	String ampSettingsKeyPath
	sprintf ampSettingsKeyPath, "%s:%s" Path_AmpSettingsFolder(panelTitle), "ampSettingsKey"
	
	// see if the wave exists....if so, skip this part..if not, create it
	//print "Does the key wave exist?"
	wave/T ampSettingsKey = $ampSettingsKeyPath
	if (!WaveExists(ampSettingsKey))
		//print "making settingsKey Wave...."
		// create the 2 dimensional wave
		make /T /o  /n = (3, 16) $ampSettingsKeyPath
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
		ampSettingsKey[2][1] =  "0.05"
		
		ampSettingsKey[0][2] =   "Osc Killer Enable"
		ampSettingsKey[1][2] =   "On/Off"
		ampSettingsKey[2][2] =   "-"
		
		ampSettingsKey[0][3] =   "RsComp Bandwidth"
		ampSettingsKey[1][3] =   "?"
		ampSettingsKey[2][3] =   "0.05"
		
		ampSettingsKey[0][4] =   "RsComp Correction"
		ampSettingsKey[1][4] =   "%"
		ampSettingsKey[2][4] =   "0.05"
		
		ampSettingsKey[0][5] =   "RsComp Enable"
		ampSettingsKey[1][5] =   "On/Off"
		ampSettingsKey[2][5] =   "-"
		
		ampSettingsKey[0][6] =   "RsComp Prediction"
		ampSettingsKey[1][6] =   "&"
		ampSettingsKey[2][6] =   "0.05"
		
		ampSettingsKey[0][7] =   "Whole Cell Comp Enable"
		ampSettingsKey[1][7] =   "On/Off"
		ampSettingsKey[2][7] =   "-"
		
		ampSettingsKey[0][8] =   "Whole Cell Comp Cap"
		ampSettingsKey[1][8] =   "pF"
		ampSettingsKey[2][8] =   "0.05"
		
		ampSettingsKey[0][9] =   "Whole Cell Comp Resist"
		ampSettingsKey[1][9] =   "M-Ohm"
		ampSettingsKey[2][9] =   "0.05"
		
		ampSettingsKey[0][10] =   "I-Clamp Holding Enable"
		ampSettingsKey[1][10] =   "On/Off"
		ampSettingsKey[2][10] =   "-"
		
		ampSettingsKey[0][11] =   "I-Clamp Holding Level"
		ampSettingsKey[1][11] =   "pA"
		ampSettingsKey[2][11] =   "0.05"
		
		ampSettingsKey[0][12] =   "Neut Cap Enabled"
		ampSettingsKey[1][12] =   "On/Off"
		ampSettingsKey[2][12] =   "-"
		
		ampSettingsKey[0][13] =   "Neut Cap Value"
		ampSettingsKey[1][13] =   "pF"
		ampSettingsKey[2][13] =   "0.05"
		
		ampSettingsKey[0][14] =   "Bridge Bal Enable"
		ampSettingsKey[1][14] =   "On/Off"
		ampSettingsKey[2][14] =   "-"
		
		ampSettingsKey[0][15] =   "Bridge Bal Value"
		ampSettingsKey[1][15] =   "M-Ohm"
		ampSettingsKey[2][15] =   "0.05"		
	endif
	
	// Now populate the Settings Wave
	// the wave is 1 row, 15 columns, and headstage number layers
	// first...determine if the head stage is being controlled
	variable headStageControlledCounter
	for(headStageControlledCounter = 0;headStageControlledCounter < noHeadStages ;headStageControlledCounter += 1)
		Variable hsControl = str2num(stringfromlist(headStageControlledCounter, controlledHeadStage,";")) // str2num(controlledHeadStage[i])
		if (hsControl == 1)
			Variable ampChannel = headStageControlledCounter
			Variable/C SerAndChan = AI_ReturnSerialAndChanNumber(panelTitle, ampChannel)
			variable serialNumber = real(SerAndChan)
			variable channel = imag(serAndChan)
			//print "serial no =", serialNumber
			if(numtype(serialNumber) != 2 && numtype(channel) != 2) // checks to make sure amp is associated with MIES headstage
//				String serialNumString
//				sprintf serialNumString, "%g%g%s" 0, 0, num2str(real(SerAndChan))
				string AmpSerialNumberString
				sprintf AmpSerialNumberString, "%.8d" real(serAndChan)				
				//print AmpSerialNumberString
				
				if (stringmatch(ampSerialNumberString, "00000000") == 1) // amp in DemoMode
					print "Amp is in Demo Mode!"
				else	
//					print "Selecting MC700B..."
					MCC_SelectMultiClamp700B(AmpSerialNumberString, imag(SerAndChan))			
					// now start to query the amp to get the status
					//Figure out if we are looking at current clamp mode or voltage clamp mode
//					print "ampChannel: ", ampChannel
//					print "ChannelClampMode: ", ChannelClampMode[ampChannel][0]
					if (ChannelClampMode[ampChannel][0] == 0) // V-clamp
					// See if the thing is enabled
						// Save the enabled state in column 0
						ampSettingsWave[0][0][headStageControlledCounter]  = MCC_GetHoldingEnable() // V-Clamp holding enable
											
						// Save the level in column 1
						ampSettingsWave[0][1][headStageControlledCounter] = MCC_GetHolding()	// V-Clamp holding level
						
						// Save the Osc Killer Enable in column 2	
						ampSettingsWave[0][2][headStageControlledCounter] = MCC_GetOscKillerEnable() // V-Clamp Osc Killer Enable
						
						// Save the RsCompBandwidth in column 3
						ampSettingsWave[0][3][headStageControlledCounter] = MCC_GetRsCompBandwidth() // V-Clamp RsComp Bandwidth
						
						// Save the RsCompCorrection in column 4
						ampSettingsWave[0][4][headStageControlledCounter] = MCC_GetRsCompCorrection() // V-Clamp RsComp Correction
						
						// Save the RsCompEnable in column 5
						ampSettingsWave[0][5][headStageControlledCounter] =   MCC_GetRsCompEnable() // V-Clamp RsComp Enable
						
						// Save the RsCompPrediction in column 6
						ampSettingsWave[0][6][headStageControlledCounter] = MCC_GetRsCompPrediction() // V-Clamp RsCompPrediction
						
						// Save the whole celll cap value in column 7
						ampSettingsWave[0][7][headStageControlledCounter] =   MCC_GetWholeCellCompEnable() // V-Clamp Whole Cell Comp Enable
						
						// Save the whole celll cap value in column 8
						ampSettingsWave[0][8][headStageControlledCounter] =   MCC_GetWholeCellCompCap() // V-Clamp Whole Cell Comp Cap
						
						// Save the whole cell comp resist value in column 9
						ampSettingsWave[0][9][headStageControlledCounter] =  MCC_GetWholeCellCompResist() // V-Clamp Whole Cell Comp Resist
						
					elseif (ChannelClampMode[ampChannel][0]==1) // I-Clamp
						// Save the i clamp holding enabled in column 10
						ampSettingsWave[0][10][headStageControlledCounter] =  MCC_GetHoldingEnable() // I-Clamp holding enable
						
						// Save the i clamp holding value in column 11
						ampSettingsWave[0][11][headStageControlledCounter] = MCC_GetHolding()	 // I-Clamp holding level		
						
						// Save the neutralization enable in column 12
						ampSettingsWave[0][12][headStageControlledCounter] = MCC_GetNeutralizationEnable() // I-Clamp Neut Enable
						
						// Save neut cap value in column 13					
						ampSettingsWave[0][13][headStageControlledCounter] =  MCC_GetNeutralizationCap() // I-Clamp Neut Cap Value
		
						// save bridge balance enabled in column 14
						ampSettingsWave[0][14][headStageControlledCounter] =   MCC_GetBridgeBalEnable() // I-Clamp Bridge Balance Enable
						
						// save bridge balance enabled in column 15
						ampSettingsWave[0][15][headStageControlledCounter] =  MCC_GetBridgeBalResist()	 // I-Clamp Bridge Balance Resist				
					endif
				endif
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