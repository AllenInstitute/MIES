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
	MCC_SetMode(0)
End
//==================================================================================================
Function AI_SwitchAxonToIClamp(panelTitle, AmpSerialNumber, AmpChannel)
	string panelTitle
	variable AmpSerialNumber
	variable AmpChannel	
	string AmpSerialNumberString
	sprintf AmpSerialNumberString, "%.8d" AmpSerialNumber
	MCC_SelectMultiClamp700B(AmpSerialNumberString, AmpChannel)
	MCC_SetMode(1)
End
//==================================================================================================
Function AI_SwitchAxonToIZero(panelTitle, AmpSerialNumber, AmpChannel)
	string panelTitle
	variable AmpSerialNumber
	variable AmpChannel	
	string AmpSerialNumberString
	sprintf AmpSerialNumberString, "%.8d" AmpSerialNumber
	MCC_SelectMultiClamp700B(AmpSerialNumberString, AmpChannel)
	MCC_SetMode(2)
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

Function /C AI_ReturnSerialAndChanNumber(panelTitle, HeadStageNo)
	string panelTitle
	variable HeadStageNo
	string wavePath = HSU_DataFullFolderPathString(PanelTitle)
	Wave ChanAmpAssign = $(WavePath + ":ChanAmpAssign")
	variable /C SerialNoAndChannelNo
	SerialNoAndChannelNo = cmplx(ChanAmpAssign[8][HeadStageNo], ChanAmpAssign[9][HeadStageNo])
	return SerialNoAndChannelNo
End

//==================================================================================================
Function AI_SwitchClampMode(panelTitle, HeadStageNo, IorVorZeroClamp)
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
