#pragma rtGlobals=3		// Use modern global access method and strict wave access.
/// @file TJ_MIES_PressureControl.ipf
/// @brief Supports use of analog pressure regulators controlled via a ITC device for automated pressure control during approach, seal, break in, and clearing of pipette.
/// @todo TPbackground can crash while operating pressure regulators if called in the middel of a TP. Need to call P_Pressure control from TP functions that occur between TPs to prevent this from happening

///@name Constants Used by pressure control
/// @{
StrConstant 	PRESSURE_CONTROLS_BUTTON_LIST 	= "button_DataAcq_Approach;button_DataAcq_Seal;button_DataAcq_BreakIn;button_DataAcq_Clear"
StrConstant 	PRESSURE_CONTROL_TITLE_LIST 		= "Approach;Seal;Break In;Clear"
StrConstant 	PRESSURE_CONTROL_CHECKBOX_LIST	= "check_DatAcq_ApproachAll;check_DatAcq_SealAll;check_DatAcq_BreakInAll;check_DatAcq_ClearEnable"
StrConstant 	PRESSURE_CONTROL_PRESSURE_DISP = "valdisp_DataAcq_P_0;valdisp_DataAcq_P_1;valdisp_DataAcq_P_2;valdisp_DataAcq_P_3;valdisp_DataAcq_P_4;valdisp_DataAcq_P_5;valdisp_DataAcq_P_6;valdisp_DataAcq_P_7"
Constant	P_METHOD_neg1_ATM				= -1
Constant 	P_METHOD_0_APPROACH 			= 0
Constant 	P_METHOD_1_SEAL 				= 1
Constant 	P_METHOD_2_BREAKIN				= 2
Constant 	P_METHOD_3_CLEAR 				= 3
Constant 	P_SEAL_BY_NEGPandV				= 0
Constant	P_SEAL_BY_DISRUPT_R_PLATEAU 	= 1
Constant 	P_SEAL_BY_atmP					= 2
Constant 	P_SEAL_BY_SUPE_NEG_P			= 3
Constant	TTL_ON								= 1
Constant	TTL_OFF							= 0
Constant	RACK_ZERO						= 0
Constant	RACK_ONE							= 3 // 3 is defined by the ITCWriteDigital command instructions.
Constant	BITS_PER_VOLT						= 3200
Constant	PRESSURE_PULSE_INCREMENT		= 0.2 // psi
Constant	PRESSURE_PULSE_STARTpt			= 1 // 12000
Constant	PRESSURE_PULSE_ENDpt			= 35000
Constant	OVERFLOW							= 1
Constant	UNDERRUN							= 1
Constant	FIFO_RESET						= -1
Constant	SAMPLE_INT_MICRO					= 5
Constant 	SAMPLE_INT_MILLI					= 0.005
Constant	GIGA_SEAL							= 1000
Constant	PRESSURE_OFFSET				= 5
Constant 	MIN_NEG_PRESSURE_PULSE		= -1
/// @}

/// @file TJ_MIES_PressureControl

/// @brief Applies pressure methods based on data in PressureDataWv
///
/// This function gets called every 500 ms while the TP is running. It also gets called when the approach button is enabled.
/// A key point is that data acquisition used to run pressure pulses cannot be active if the TP is not active.
Function P_PressureControl(panelTitle)
	string 	panelTitle
	WAVE 	PressureDataWv = P_GetPressureDataWaveRef(panelTitle)
	variable 	headStage
	for(headStage = 0; headStage <= 7; headStage += 1)
		if(P_ValidatePressureSetHeadstage(panelTitle, headStage) && !IsITCCollectingData(panelTitle, headStage)) // are headstage settings valid AND is the ITC device inactive
			switch(PressureDataWv[headStage][0])
				case P_METHOD_neg1_ATM:
						P_MethodAtmospheric(panelTitle, headstage)
					break
				case P_METHOD_0_APPROACH:
					P_MethodApproach(panelTitle, headStage)
					break
				case P_METHOD_1_SEAL:
					if(P_IsTPActive(panelTitle) && P_IsHSActiveAndInVClamp(panelTitle, headStage))
						P_MethodSeal(panelTitle, headStage)
					endif
					break
				case P_METHOD_2_BREAKIN:
					if(P_IsTPActive(panelTitle) && P_IsHSActiveAndInVClamp(panelTitle, headStage))
						P_MethodBreakIn(panelTitle, headStage)
					endif
					break
				case P_METHOD_3_CLEAR:
					if(P_IsTPActive(panelTitle) && P_IsHSActiveAndInVClamp(panelTitle, headStage))
						
					endif
					break
			endswitch
		endif
	endfor
End

/// @ brief Sets the pressure to atmospheric
Function P_MethodAtmospheric(panelTitle, headstage)
	string 	panelTitle
	variable 	headStage
	WAVE 	PressureDataWv = P_GetPressureDataWaveRef(panelTitle)
	P_UpdateTTLstate(panelTitle, headStage, 0)
	PressureDataWv[headStage][26] = P_SetPressure(panelTitle, headStage, 0)
End
	
/// @brief Applies approach pressures
Function P_MethodApproach(panelTitle, headStage)
	string 	panelTitle
	variable 	headStage
	WAVE 	PressureDataWv = P_GetPressureDataWaveRef(panelTitle)
	variable 	targetP = PressureDataWv[headStage][10] 	// Approach pressure is stored in row 10 (Solution approach pressure). Once manipulators are part of MIES, other approach pressures will be incorporated
	//variable 	actualP = P_GetPressure(panelTitle, headStage)
	variable	ONorOFF = 1
	// Open the TTL
	P_UpdateTTLstate(panelTitle, headStage, ONorOFF)
	PressureDataWv[headStage][26] = P_SetPressure(panelTitle, headStage, targetP)
	PressureDataWv[headStage][%LastPressureCommand]  = targetP
End

/// @brief Applies seal methods
Function P_MethodSeal(panelTitle, headStage)
	string 	panelTitle
	variable 	headStage
	WAVE 	PressureDataWv 			= P_GetPressureDataWaveRef(panelTitle)
	variable 	RSlope
	variable 	RSlopeThreshold 			= 8 // with a slope of 8 Mohm/s it will take two minutes for a seal to form.
	variable 	lastRSlopeCheck 		= PressureDataWv[headStage][25] / 60
	variable 	timeInSec 				= ticks / 60
	variable 	ElapsedTimeInSeconds 	= timeInSec - LastRSlopeCheck

	if(!lastRSlopeCheck || numType(lastRSlopeCheck) == 2) // checks for first time thru.
		ElapsedTimeInSeconds = 0
		PressureDataWv[headStage][%TimeOfLastRSlopeCheck] = ticks
	endif
	
//	P_ApplyNegV(panelTitle, headStage)
	P_UpdateSSRSlopeAndSSR(panelTitle) // update the resistance values used to assess seal changes
	variable resistance = PressureDataWv[headStage][%LastResistanceValue]
	variable pressure = PressureDataWv[headStage][%LastPressureCommand] // P_GetPressure(panelTitle, headstage)  // PressureDataWv[headStage][26]
	
	// if the seal resistance is greater that 1 giga ohm set pressure to atmospheric AND stop sealing process
	if(Resistance >= GIGA_SEAL)
		P_MethodAtmospheric(panelTitle, headstage) // set to atmospheric pressure
 		P_UpdatePressureMode(panelTitle, 1, stringfromlist(1,PRESSURE_CONTROLS_BUTTON_LIST), 0)
		PressureDataWv[headStage][%Approach_Seal_BrkIn_Clear] 	= -1 // remove the seal mode
		PressureDataWv[headStage][%TimeOfLastRSlopeCheck] 		= 0 // reset the time of last slope R check
		
				// apply holding potential of -70 mV 	 	
		SetCheckBoxState(panelTitle, "check_DatAcq_HoldEnableVC", 1) 	 	
		AI_UpdateAmpModel(panelTitle, "check_DatAcq_HoldEnableVC", headStage) 	 	
		SetSetVariable(panelTitle, "setvar_DataAcq_Hold_VC", -70) 	 	
		AI_UpdateAmpModel(panelTitle, "setvar_DataAcq_Hold_VC", headStage)  
		
		print "Seal on head stage:", headstage
		
	else // no seal, start, hold, or increment negative pressure
					 
		// if there is no neg pressure, apply starting pressure.
		if(PressureDataWv[headStage][%LastPressureCommand] > PressureDataWv[headStage][%PSI_SealInitial])
			PressureDataWv[headStage][%LastPressureCommand] = P_SetPressure(panelTitle, headStage, PressureDataWv[headStage][%PSI_SealInitial]) // column 26 is the last pressure command, column 13 is the starting seal pressure
			pressure = PressureDataWv[headStage][%PSI_SealInitial] // P_GetPressure(panelTitle, headstage) // PressureDataWv[headStage][13]
			PressureDataWv[headStage][%LastPressureCommand] = PressureDataWv[headStage][%PSI_SealInitial]
			print "no neg pressure"
		endif	
	//	print ElapsedTimeInSeconds
		// if the seal slope has plateau'd or is going down, increase the negative pressure
		if(ElapsedTimeInSeconds > 10) // Allows 10 seconds to elapse before pressure would be changed again. The R slope is over the last 5 seconds.
			RSlope = PressureDataWv[headStage][%PeakResistanceSlope]
			if(RSlope < RSlopeThreshold) // if the resistance is not going up quickly enough increase the negative pressure
				print "slope", rslope, "thres", RSlopeThreshold
				// what is the pressure
				//pressure = P_GetPressure(panelTitle, headStage)
				if(pressure > (0.98 *PressureDataWv[headStage][%PSI_SealMax])) // is the pressure beign applied less than the maximum allowed?
					print "resistance is not going up fast enough"
					print "pressure =", pressure - 0.1
					PressureDataWv[headStage][%LastPressureCommand] = P_SetPressure(panelTitle, headStage, (pressure - 0.1)) // increase the negative pressure by 0.1 psi
					
				else // max neg pressure has been reached and resistance has stabilized
					print "pressure is at max neg value"  
					// disrupt plateau
				endif
			endif
			PressureDataWv[headStage][%TimeOfLastRSlopeCheck] = ticks
		endif
		P_ApplyNegV(panelTitle, headStage) // apply negative voltage
	endif
End

/// @brief Applies break-in methods
Function P_MethodBreakIn(panelTitle, headStage)
	string 	panelTitle
	variable 	headStage
	WAVE 	PressureDataWv 			= P_GetPressureDataWaveRef(panelTitle)
	variable 	lastRSlopeCheck 		= PressureDataWv[headStage][%TimeOfLastRSlopeCheck] / 60
	variable 	timeInSec 				= ticks / 60
	variable 	ElapsedTimeInSeconds 	= timeInSec - LastRSlopeCheck

	if(!lastRSlopeCheck || numType(lastRSlopeCheck) == 2) // checks for first time thru.
		ElapsedTimeInSeconds = 0
		PressureDataWv[headStage][%TimeOfLastRSlopeCheck] = ticks
	endif
	
	P_UpdateSSRSlopeAndSSR(panelTitle) // update the resistance values used to assess seal changes
	variable resistance = PressureDataWv[headStage][%LastResistanceValue]
	
	// if the seal resistance is less that 1 giga ohm set pressure to atmospheric AND break in process
	if(Resistance <= GIGA_SEAL)
		P_MethodAtmospheric(panelTitle, headstage) // set to atmospheric pressure
		P_UpdatePressureMode(panelTitle, 2, stringfromlist(2,PRESSURE_CONTROLS_BUTTON_LIST), 0) // sets break-in button back to base state
		PressureDataWv[headStage][%Approach_Seal_BrkIn_Clear] 	= -1 // remove the seal mode
		PressureDataWv[headStage][%TimeOfLastRSlopeCheck] 		= 0 // reset the time of last slope R check
		PressureDataWv[headStage][%LastPressureCommand]		= 0
		print "Break in on head stage:", headstage,"of", panelTitle
	else // still need to break - in
		 if(ElapsedTimeInSeconds > 2.5)
		 	print "applying negative pressure pulse!"
		 	P_NegPressurePulse(panelTitle, headStage)
		 	PressureDataWv[headStage][%TimeOfLastRSlopeCheck] = ticks
		 endif
	endif
End

/// @brief Applies pipette clearing methods
Function P_MethodClear(panelTitle, headStage)
	string 	panelTitle
	variable 	headStage
End

/// @brief Applies updates the command Voltage so that -100 pA current is applied up to the target voltage
Function P_ApplyNegV(panelTitle, headStage)
	string 	panelTitle
	variable 	headStage
	WAVE 	PressureDataWv 	= P_GetPressureDataWaveRef(panelTitle)
	variable 	resistance 		=  PressureDataWv[headStage][22]
	variable 	vCom 			= -0.200 * resistance
	variable	lastVcom = PressureDataWv[headStage][%LastVcom]
// determine command voltage that will result in a holding pA of -100 pA	
// if V = -100 * resistance is greater than target voltage, apply target voltage, otherwise apply calculated voltage
	

	if(vCom > -70 && vCom < (lastVcom + 3) || vCom > (lastVcom - 3))
		print "vcom",vcom
		P_UpdateVcom(panelTitle, vCom, headStage)
		PressureDataWv[headStage][%LastVcom] = vCom
	endif
End

/// @brief Updates the command voltage
Function P_UpdateVcom(panelTitle, vCom, headStage)
	string 	panelTitle
	variable 	vCom
	variable 	headStage
	
	// make sure holding is enabled
		SetCheckBoxState(panelTitle, "check_DatAcq_HoldEnableVC", 1)
		AI_UpdateAmpModel(panelTitle, "check_DatAcq_HoldEnableVC", headStage)
	// apply holding
	SetSetVariable(panelTitle, "setvar_DataAcq_Hold_VC", vCom)
	AI_UpdateAmpModel(panelTitle, "setvar_DataAcq_Hold_VC", headStage) // used to set holding

End

/// @brief Opens ITC devices used for pressure regulation
Function P_OpenITCDevForP_Reg(panelTitle)
	string 	panelTitle
	string 	ListOfITCDevToOpen = P_ITCDevToOpen()
	variable 	i = 0
	for(i = 0; i < itemsinList(ListOfITCDevToOpen); i += 1)
		P_OpenITCDevice(panelTitle, stringfromlist(i, ListOfITCDevToOpen))
	endfor
End

// @brief Determines which ITC devices to close. Ensures all DA_Ephys panels using a particular ITC device for pressure regulation are updated correctly.
Function P_CloseITCDevForP_Reg(panelTitle)
	string 	panelTitle
	string 	ListOfITCDevToClose = P_ITCDevToOpen()
	string 	ListOfLockedDA_Ephys = DAP_ListOfLockedDevs()
	string 	DeviceToClose
	
	string 	ListOfHeadstagesUsingITCDev
	variable 	headStage
	variable 	i = 0, j = 0
	
	for(i = 0; i < itemsinList(ListOfITCDevToClose); i += 1) // for all the ITC devices used for pressure regulation
		// find device ID
		do
			panelTitle = stringfromlist(j, ListOfLockedDA_Ephys)
			DeviceToClose = stringFromList(i,ListOfITCDevToClose)

			ListOfHeadstagesUsingITCDev = P_HeadstageUsingITCDevice(panelTitle, DeviceToClose)
			j += 1
		while(cmpstr("", ListOfHeadstagesUsingITCDev) == 0)
			j = 0
			
			print "panel title:", panelTitle
			print "Device to close:", DeviceToClose
			headStage = str2num(stringFromList(0, ListOfHeadstagesUsingITCDev))
			
			WAVE PressureDataWv = P_GetPressureDataWaveRef(panelTitle)
			P_CloseITCDevice(panelTitle, DeviceToClose , PressureDataWv[headStage][3])
	endfor
End

/// @brief Used to open ITCdevice used for pressure regulation.
Function P_OpenITCDevice(panelTitle, ITCDeviceToOpen)
	String 	panelTitle, ITCDeviceToOpen
	string 	deviceType, deviceNumber, cmd
	DFREF 	dfr 								= P_DeviceSpecificPressureDFRef(panelTitle)
	
	ParseDeviceString(ITCDeviceToOpen, deviceType, deviceNumber)
	
	Make/o/I/U/N=1 dfr:DevID/WAVE = DevID
	string 	DevIDWaveNameString 			= GetWavesDataFolder(DevID,2)
	
	sprintf 	cmd, "ITCOpenDevice \"%s\", %s, %s", DeviceType, DeviceNumber, DevIDWaveNameString
	Execute	cmd
	print 	"ITC Device used for pressure regulation ID #",DevID[0],"is locked."
	
	variable 	headStage
	string 	ListOfLockedDA_Ephys 			= DAP_ListOfLockedDevs()
	variable 	i, j
	string 	ListOfHeadstageUsingITCDevice	= ""
	
	// update pressure data wave with locked device info
	for(j = 0; j < itemsinlist(ListOfLockedDA_Ephys); j += 1)
		panelTitle = stringfromlist(j, ListOfLockedDA_Ephys)
		ListOfHeadstageUsingITCDevice = P_HeadstageUsingITCDevice(panelTitle, ITCDeviceToOpen)
		if(cmpstr("",ListOfHeadstageUsingITCDevice) != 0)
			for(i = 0; i < itemsInlist(ListOfHeadstageUsingITCDevice); i += 1)
				headStage = str2num(stringfromlist(i, ListOfHeadstageUsingITCDevice))
				WAVE PressureDataWv = P_GetPressureDataWaveRef(panelTitle)
				PressureDataWv[headStage][3] = DevID[0]
			endfor
		endif
	endfor	
End

/// @brief Used to close ITC device used for pressure regulation
Function P_CloseITCDevice(panelTitle, ITCDevToClose, DevID)
	string 	panelTitle, ITCDevToClose
	variable 	DevID
	string 	cmd
	sprintf 	cmd, "ITCSelectDevice %d" DevID
	Execute cmd
	Execute "ITCCloseDevice"
	variable 	headStage
	variable 	i, j
	string 	ListOfHeadstageUsingITCDevice = ""
	
	string 	ListOfLockedDA_Ephys = DAP_ListOfLockedDevs()

	for(j = 0; j < itemsinlist(ListOfLockedDA_Ephys); j += 1)
		panelTitle = stringfromlist(j, ListOfLockedDA_Ephys)	
		ListOfHeadstageUsingITCDevice = P_HeadstageUsingITCDevice(panelTitle, ITCDevToClose)
		for(i = 0; i < itemsInlist(ListOfHeadstageUsingITCDevice); i += 1)
			print "LIST" , ListOfHeadstageUsingITCDevice
			if(cmpstr("",ListOfHeadstageUsingITCDevice) != 0)
				headStage = str2num(stringfromlist(i, ListOfHeadstageUsingITCDevice))
				WAVE PressureDataWv = P_GetPressureDataWaveRef(panelTitle)
				print "about to reset dev ID global"
				PressureDataWv[headStage][3] = Nan
			endif
		endfor
	endfor
End

/// @brief Returns a list of rows that contain a particular string
Function/S P_HeadstageUsingITCDevice(panelTitle, ITCDevice)
	string 		panelTitle
	string 		ITCDevice
	WAVE/T 	PressureDataTxtWv 	= P_PressureDataTxtWaveRef(panelTitle)
	variable i
	string 		ListString 			= ""
	for(i = 0; i <= 7; i += 1)
		if(cmpstr(ITCDevice, PressureDataTxtWv[i][0]) == 0)
			ListString = addlistItem(num2str(i), ListString)
		endif
	endfor

	return ListString
End

/// @brief Returns a list of ITC devices to open
/// pulls a non repeating list of ITC devices to open from the device specific pressure data wave.
Function/S P_ITCDevToOpen()
	string 	ListOfLockedDevices = DAP_ListOfLockedDevs()
	
	string 	deviceList = ""
	variable 	i = 0, j = 0
	variable 	alreadyInList
	
	for(j = 0; j < itemsInList(ListOfLockedDevices); j += 1)
		for(i = 0; i < 8; i += 1)
			wave/T 	pressureDataTxtWave = P_PressureDataTxtWaveRef(stringfromList(j, ListOfLockedDevices))
			if(cmpstr(pressureDataTxtWave[i][0],"") != 0 && cmpstr(pressureDataTxtWave[i][0],"- none -") != 0) // prevent blanks from being inserted into list
				alreadyInList = WhichListItem(pressureDataTxtWave[i][0], deviceList)
				if(alreadyInList == -1) // prevent duplicates from being inserted into list
					deviceList = AddListItem(pressureDataTxtWave[i][0], deviceList)
				endif
			endif	
		endfor
	endfor
	
	deviceList = sortlist(deviceList) // sort the list so that the devices are opened in the correct sequence (low devID to high devID)
	return 	DeviceList
End

/// @brief Returns the wave reference for the pressure data wave
Function/Wave P_GetPressureDataWvRef()

	dfref dfr = holder
	Wave/Wave/Z/SDFR=dfr dataRef

	if(WaveExists(dataRef))
		return dataRef
	endif

	Make/Wave/N=(0) dfr:dataRef/Wave=dataRef

	return dataRef
End

/// @brief Sets the pressure on a headStage
Function P_SetPressure(panelTitle, headStage, psi)
	string 	panelTitle
	variable 	headStage, psi
	WAVE 	PressureDataWv = P_GetPressureDataWaveRef(panelTitle)
	P_PressureCommand(panelTitle, PressureDataWv[headStage][%DAC_DevID], PressureDataWv[headStage][%DAC], PressureDataWv[headStage][%ADC], psi, PressureDataWv[headStage][%DAC_Gain])
	SetValDisplaySingleVariable(panelTitle, stringfromlist(headstage,PRESSURE_CONTROL_PRESSURE_DISP) , psi, format = "%2.2f")
	return 	psi
End

/// @brief Sets the pressure using a single DA channel on a ITC device	
Function P_PressureCommand(panelTitle, ITCDeviceIDGlobal, DAC, ADC, psi, DA_ScaleFactor)
	string 	panelTitle
	variable 	ITCDeviceIDGlobal 	// ITC device used for pressure control
	variable 	DAC, ADC 				// the DA channel that the pressure regulator recieves its command voltage from
	variable 	psi 					// the command pressure in pounds per square inch
	variable 	DA_scaleFactor		// number of volts per psi for the command

	psi /= DA_scaleFactor
	// psi offset: 0V = -10 psi, 5V = 0 psi, 10V = 10 psi
	psi += 5

	// check assumption that device is open
	string 	ITCCommand
	sprintf 	ITCCommand, "ITCSelectDevice %d" ITCDeviceIDGlobal
	execute 	ITCCommand	
	// set pressure
	sprintf 	ITCCommand, "ITCSetDAC %0d, %g" DAC, psi
	execute 	ITCCommand

End

/// @breif Gets the pressure on a headStage
Function P_GetPressure(panelTitle, headStage)
	string 	panelTitle
	variable 	headStage
	WAVE 	pressureDataWv = P_GetPressureDataWaveRef(panelTitle)
	
	variable 	Pressure = P_ReadADC(panelTitle, pressureDataWv[headStage][%DAC_DevID], pressureDataWv[headStage][%ADC], pressureDataWv[headStage][%ADC_Gain])
	
	return 	Pressure
End

/// @brief Gets the pressure using a single AD channel on a ITC device
Function P_ReadADC(panelTitle, ITCDeviceIDGlobal, ADC, AD_ScaleFactor)
	string 	panelTitle
	variable 	ITCDeviceIDGlobal, ADC, AD_ScaleFactor 	
	DFREF 	dfr = P_GetDevicePressureFolder(panelTitle)
	Make/N=1/D/O dfr:ADC/WAVE=ADV
	string 	ITCCommand
	sprintf 	ITCCommand, "ITCSelectDevice %d" ITCDeviceIDGlobal	
	execute 	ITCCommand	
	
	sprintf 	ITCCommand, "ITCReadADC/C=1 %d, %s" ADC, getWavesDataFolder(ADV, 2) // /C=1
	execute 	ITCCommand	
	ADV[0] -= 5
	ADV[0] /= AD_ScaleFactor
	
	return ADV[0]
End

/// @brief Updates the TTL channel associated with headStage while maintaining existing channel states
/// 
/// 	When setting TTLs, all channels are set at once. To keep existing TTL state on some channels, active state must be known. 
/// 	This funcition queries the hardware to determine the active state. This requires the TTL out to be looped back to the TTL in on the ITC DAC.
Function P_UpdateTTLstate(panelTitle, headStage, ONorOFF) 
	string 	panelTitle
	variable 	headStage
	variable 	ONorOFF							
	variable 	OutPutDecimal
	WAVE 	PressureDataWv 		= P_GetPressureDataWaveRef(panelTitle)

	variable 	ITCDeviceIDGlobal 	= PressureDataWv[headStage][3] // ITC device used for pressure control
	variable 	Channel 				= PressureDataWv[headStage][8]
	variable 	rack 				= 0
	
	If(Channel >= 4)
		rack =3
		Channel -=4
	endif 	
	
	string 	ITCCommand
	sprintf 	ITCCommand, "ITCSelectDevice %d" ITCDeviceIDGlobal
	execute 	ITCCommand
	
	Wave 	DIO = P_DIO(panelTitle)
	sprintf 	ITCCommand, "ITCReadDigital %d, %s" Rack, getWavesDataFolder(DIO, 2)
	execute 	ITCCommand	
	
	string 	BinaryList = P_DecToBinary(DIO[0])

	// check if desired channel is already in correct state
	variable 	channelStatus = str2num(stringfromlist(Channel, BinaryList))

	if(ONorOFF != channelStatus) // update tll associated with headStage only if the desired TTL channel state is different from the actual/current channel state.
		if(ONorOFF)
			OutputDecimal = DIO[0] + 2^channel
		else
			OutputDecimal = DIO[0] - 2^channel
		endif
		sprintf 	ITCCommand, "ITCWriteDigital %d, %d" Rack, OutputDecimal
		execute 	ITCCommand	
	endif
	
	return OutputDecimal
End

/// @brief Sets the TTL state
Function P_SetTTLState(ITCDeviceIDGlobal, Rack, Channels) 	// when setting TTLs all channels are set at once. To keep existing TTL state on some channels, previous state must be known)
	variable ITCDeviceIDGlobal 						// ITC device used for pressure control
	variable Rack  									// The ttl channels to set, the TTLs on the ITC1600 for rack 0 TTL = 0, for rack 1 TTL = 3
	variable Channels 									// 0 = 0V (low), 1 = 5V(high)
	
	// set TTL
	string 	ITCCommand
	sprintf 	ITCCommand, "ITCSelectDevice %d" ITCDeviceIDGlobal
	execute 	ITCCommand
	
	sprintf 	ITCCommand, "ITCWriteDigital %d, %d" Rack, Channels
	execute	ITCCommand
	
	// 0. TTL 1;0;0;0
	// 1. TTL 0;1;0;0
	// 2. TTL 1;1;0;0
	// 3. TTL 0;0;1;0
	// 4. TTL 1;0;1;0
	// 5. TTL 0;1;1;0
	// 6. TTL 1;1;1;0
	// 7. TTL 0;0;0;1
	// 8. TTL 1;0;0;1
	// 9. TTL 0;1;0;1
	// 10. TTL 1;1;0;1
	// 11. TTL 0;0;1;1
	// 12. TTL1;0;1;1
	// 13. TTL 0;1;1;1
	// 14. TTL 1;1;1;1
	
	// 2^0 = 1
	// 2^1 = 2
	// 2^2 = 4
	// 2^3 = 8

End

/// @brief Creates the data folder: root:MIES:Pressure
Function P_CreatePressureDataFolder()
	CreateDFWithAllParents("root:MIES:Pressure:")
End

/// @brief Returns the data folder reference for the main pressure folder "root:MIES:Pressure"
Function/DF P_PressureFolderReference()
	return CreateDFWithAllParents("root:MIES:Pressure:")
End

/// @breif Creates ITC device specific pressure folder - used to store data for pressure regulators
Function/DF P_GetDevicePressureFolder(panelTitle)
	string 	panelTitle
	string 	DeviceNumber 	
	string 	DeviceType 	
	ParseDeviceString(panelTitle, deviceType, deviceNumber)
	string 	FolderPathString
	sprintf FolderPathString, "root:MIES:Pressure:%s:Device_%s" DeviceType, DeviceNumber
	return CreateDFWithAllParents(FolderPathString)
End

/// @brief Returns device specific data folder reference
Function/DF P_DeviceSpecificPressureDFRef(panelTitle)
	string panelTitle
	return P_GetDevicePressureFolder(panelTitle)
End

/// @brief Returns wave reference of wave used to configure ITC device for data acquisition used in pressure control
///
/// Row:
/// -1: Channel configuration
///
/// Column:
/// -1: Channel type (DA = 1, AD = 0, TTL = )
/// -2: Channel number
/// -3: Number of samples to acquire (for ITCShortAcquisition)
Function/WAVE P_ITCChanConfig(panelTitle)
	string 	panelTitle
	dfref 	dfr = P_DeviceSpecificPressureDFRef(panelTitle)
	
	Wave/Z/SDFR=dfr ITCChanConfigP
	
	if(WaveExists(ITCChanConfigP))
		return ITCChanConfigP
	endif
	
	Make/I/O/N = (1,4) dfr:ITCChanConfigP/Wave=ITCChanConfigPloc
	
	ITCChanConfigPloc = 0
	ITCChanConfigPloc[0][2] = 10
	
	return ITCChanConfigPloc
End

/// @brief Returns wave reference of wave used to send or recieve data from ITC device used in pressure control
///
/// Rows:
/// - 0-10 DA, AD, or TTL samples
///
/// Columns:
/// - 0: DA,AD, or TTL data
Function/WAVE P_ITCDataWave(panelTitle)
	string 	panelTitle
	dfref 	dfr = P_DeviceSpecificPressureDFRef(panelTitle)
	
	Wave/Z/SDFR=dfr ITCDataWaveP
	
	if(WaveExists(ITCDataWaveP))
		return ITCDataWaveP
	endif
	
	Make /W /O /N = (10,2) dfr:ITCDataWaveP/Wave=ITCDataWavePLoc
	ITCDataWavePLoc = 0
	
	return ITCDataWavePLoc
End


/// @breif Returns wave reference of wave used to store data used in functions that run pressure regulators
/// creates the wave if it does not exist
Function/WAVE P_GetPressureDataWaveRef(panelTitle)
	string	panelTitle
	dfref 	dfr = P_DeviceSpecificPressureDFRef(panelTitle)
	
	Wave/Z/SDFR=dfr PressureData

	if(WaveExists(PressureData))
		return PressureData
	endif

	make/o/n = (8,32,1) dfr:PressureData/Wave=PressureData
	
	PressureData 	= nan
	PressureData[][0]	= -1 // prime the wave to avoid index out of range error for popup menus and to set all pressure methods to OFF (-1)
	PressureData[][1]	= 0
	PressureData[][4]	= 0
	PressureData[][6]	= 0
	PressureData[][8]	= 0
	
	SetDimLabel COLS, 0, 	Approach_Seal_BrkIn_Clear, 	PressureData // -1 = atmospheric pressure; 0 = approach; 1 = Seal; Break in = 2, Clear = 3
	SetDimLabel COLS, 1, 	DAC_List_Index, 				PressureData // The position in the popup menu list of attached ITC devices
	SetDimLabel COLS, 2, 	DAC_Type, 					PressureData // type of ITC DAC
	SetDimLabel COLS, 3,  	DAC_DevID, 					PressureData // ITC DAC number
	SetDimLabel COLS, 4,  	DAC, 						PressureData // DA channel
	SetDimLabel COLS, 5,  	DAC_Gain, 					PressureData 
	SetDimLabel COLS, 6,  	ADC, 						PressureData 
	SetDimLabel COLS, 7,  	ADC_Gain, 					PressureData 
	SetDimLabel COLS, 8,  	TTL, 						PressureData // TTL channel
	SetDimLabel COLS, 9,  	PSI_air, 						PressureData // used to set pipette pressure on approach
	SetDimLabel COLS, 10, 	PSI_solution, 				PressureData // used to set pipette pressure on approach
	SetDimLabel COLS, 11, 	PSI_slice, 					PressureData // used to set pipette pressure on approach
	SetDimLabel COLS, 12, 	PSI_nearCell, 				PressureData // used to set pipette pressure on approach
	SetDimLabel COLS, 13, 	PSI_SealInitial, 				PressureData // used to set the minium negative pressure for sealing
	SetDimLabel COLS, 14, 	PSI_SealMax, 				PressureData // used to set the maximum negative pressure for sealing
	SetDimLabel COLS, 15, 	solutionZaxis, 				PressureData // solution height in microns (as measured from bottom of the chamber).
	SetDimLabel COLS, 16, 	sliceZaxis, 					PressureData // top of slice in microns (as measured from bottom of the chamber).
	SetDimLabel COLS, 17, 	cellZaxis, 					PressureData // height of cell (as measured from bottom of the chamber).
	SetDimLabel COLS, 18, 	cellXaxis, 					PressureData // cell position data
	SetDimLabel COLS, 19, 	cellYaxis, 					PressureData // cell position data
	SetDimLabel COLS, 20, 	Method, 						PressureData // used to store pressure method currently being used on cell
	SetDimLabel COLS, 21, 	Method_Cycle_Count,			PressureData // numbe of times current state has been cycled through
	SetDimLabel COLS, 22, 	LastResistanceValue,			PressureData // last steady state resistance value
	SetDimLabel COLS, 23, 	PeakResistanceSlope,		PressureData // Slope of the peak TP resistance value over the last 5 seconds
	SetDimLabel COLS, 24, 	ActiveTP,					PressureData // Indicates if the TP is active on the headStage
															/// @todo Ensure that auto pressure regulation only is invokable in V-Clamp or auto switch mode to V-Clamp
															/// @todo If user switched headStage mode while pressure regulation is ongoing, pressure reg either needs to be turned off, or steady state slope values need to be used
															/// @todo Enable mode switching with TP running (auto stop TP, switch mode, auto startTP)
															/// @todo Enable headstate switching with TP running (auto stop TP, change headStage state, auto start TP)
	SetDimLabel COLS, 24, PeakResistanceSlopeThreshold, 	PressureData // If the PeakResistance slope is greater than the PeakResistanceSlope thershold pressure method does not need to update i.e. the pressure is "good" as it is
	SetDimLabel COLS, 25, TimeOfLastRSlopeCheck, 		PressureData // The time in ticks of the last check of the resistance slopes
	SetDimLabel COLS, 26, LastPressureCommand, 		PressureData 
	SetDimLabel COLS, 27, OngoingPessurePulse,			PressureData
	SetDimLabel COLS, 28, LastVcom,						PressureData
	SetDimLabel COLS, 29, ManSSPressure,				PressureData
	SetDimLabel COLS, 30, ManPPPressure,				PressureData
	SetDimLabel COLS, 31, ManPPDuration,				PressureData
	
	SetDimLabel ROWS, 0, Headstage_0, PressureData
	SetDimLabel ROWS, 1, Headstage_1, PressureData
	SetDimLabel ROWS, 2, Headstage_2, PressureData
	SetDimLabel ROWS, 3, Headstage_3, PressureData
	SetDimLabel ROWS, 4, Headstage_4, PressureData
	SetDimLabel ROWS, 5, Headstage_5, PressureData
	SetDimLabel ROWS, 6, Headstage_6, PressureData
	SetDimLabel ROWS, 7, Headstage_7, PressureData
	
	return PressureData
End

/// @brief Returns wave reference for wave used to store text used in pressure control.
/// creates the text storage wave if it doesn't already exist.
Function/WAVE P_PressureDataTxtWaveRef(panelTitle)
	string panelTitle
	dfref dfr = P_DeviceSpecificPressureDFRef(panelTitle)
	
	Wave/Z/T/SDFR=dfr PressureDataTextWv

	if(WaveExists(PressureDataTextWv))
		return PressureDataTextWv
	endif

	make/o/T/n = (8, 3, 1) dfr:PressureDataTextWv/WAVE= PressureDataTextWv
	
	SetDimLabel COLS, 0, ITC_Device, PressureDataTextWv
	SetDimLabel COLS, 1, DA_Unit, 	PressureDataTextWv
	SetDimLabel COLS, 2, AD_Unit, 	PressureDataTextWv
	
	SetDimLabel ROWS, 0, Headstage_0, PressureDataTextWv
	SetDimLabel ROWS, 1, Headstage_1, PressureDataTextWv
	SetDimLabel ROWS, 2, Headstage_2, PressureDataTextWv
	SetDimLabel ROWS, 3, Headstage_3, PressureDataTextWv
	SetDimLabel ROWS, 4, Headstage_4, PressureDataTextWv
	SetDimLabel ROWS, 5, Headstage_5, PressureDataTextWv
	SetDimLabel ROWS, 6, Headstage_6, PressureDataTextWv
	SetDimLabel ROWS, 7, Headstage_7, PressureDataTextWv
	
	PressureDataTextWv[][0] = "- none -"
	
	return PressureDataTextWv
End

/// @brief Updates resistance slope and the resistance in PressureDataWv from TPStorageWave
/// param 
Function P_UpdateSSRSlopeAndSSR(panelTitle)
	string 	panelTitle
	wave 	TPStorageWave 		= GetTPStorage(panelTitle)
	wave 	PressureDataWv 	= P_GetPressureDataWaveRef(panelTitle)
	string 	HeadStageStateList	= DAP_HeadstageStateList(panelTitle)
	DFREF 	dfr 				= $HSU_DataFullFolderPathString(panelTitle)
	/// @todo Make wave reference function for ITCChanConfigWave
	Wave/SDFR = dfr  ITCChanConfigWave
	string 	ADChannelList = SCOPE_RefToPullDatafrom2DWave(0, 0, 1, ITCChanConfigWave)
	variable TPCycleCount = GetNumberFromWaveNote(TPStorageWave, TP_CYLCE_COUNT_KEY) // used to pull most recent resistance value from TP storage wave
	// pull data from TPStorageWave, apply it to headStage using TP_HeadstageUsingADC(panelTitle, AD)
	variable ColumnsInTPStorageWave = dimsize(TPStorageWave, 1)
	if(ColumnsInTPStorageWave == 0)
		ColumnsInTPStorageWave = 1
	endif
	
	variable ADC
	variable i = 0
	for(i = 0; i < ColumnsInTPStorageWave; i += 1) // 
		ADC = str2num(stringfromlist(i, ADChannelList))
		PressureDataWv[TP_HeadstageUsingADC(panelTitle, ADC)][22] = TPStorageWave[TPCycleCount - 1 ][i][2]	// update the steady state resistance value
		PressureDataWv[TP_HeadstageUsingADC(panelTitle, ADC)][23] = TPStorageWave[0][i][5] 	// Layer 5 of the TP storage wave contains the slope of the steady state resistance values of the TP
	endfor																					// Column 22 of the PressureDataWv stores the steady state resistance slope
End

/// @brief Updates the pressure state (approach, seal, break in, or clear) from DA_Ephys panel to the pressureData wave
Function P_UpdatePressureDataStorageWv(panelTitle)
	string 	panelTitle
	variable 	headStageNo 	= GetPopupMenuIndex(panelTitle, "Popup_Settings_HeadStage")
	WAVE 	PressureDataWv 	= P_GetPressureDataWaveRef(panelTitle)
	string 	deviceType, deviceNum
	
	string SelectedITCDevice = getPopupMenuString(panelTitle, "popup_Settings_Pressure_ITCdev")
	parseDeviceString(SelectedITCDevice, deviceType, DeviceNum)
//	PressureDataWv[headStageNo][0] STORES THE ACTIVE PRESSURE METHOD OR -1 IF NO ACTIVE METHOD. IT IS UPDATED BY THE PRESSURE CONTROL BUTTONS IN THE DATA ACQUISITION TAB OF THE DA_EPHYS PANEL	
	PressureDataWv[headStageNo][1] 	= GetPopupMenuIndex	(panelTitle, "popup_Settings_Pressure_ITCdev")
	PressureDataWv[headStageNo][2] 	= str2num(DeviceNum)
//	PressureDataWv[headStageNo][3] STORES THE DEVICE ID WHICH IS DETERMINED WHEN THE DEVICE IS OPENED
	PressureDataWv[headStageNo][4] 	= GetPopupMenuIndex	(panelTitle, "Popup_Settings_Pressure_DA")
	PressureDataWv[headStageNo][5] 	= GetSetVariable			(panelTitle, "setvar_Settings_Pressure_DAgain")
	PressureDataWv[headStageNo][6] 	= GetPopupMenuIndex	(panelTitle, "Popup_Settings_Pressure_AD")
	PressureDataWv[headStageNo][7]  	= GetSetVariable			(panelTitle, "setvar_Settings_Pressure_ADgain")
	PressureDataWv[headStageNo][8]  	= GetPopupMenuIndex	(panelTitle, "Popup_Settings_Pressure_TTL")
	PressureDataWv[][9]   			= GetSetVariable			(panelTitle, "setvar_Settings_InAirP")
	PressureDataWv[][10] 			= GetSetVariable			(panelTitle, "setvar_Settings_InBathP")
	PressureDataWv[][11] 			= GetSetVariable			(panelTitle, "setvar_Settings_InSliceP")
	PressureDataWv[][12] 			= GetSetVariable			(panelTitle, "setvar_Settings_NearCellP")
	PressureDataWv[][13] 			= GetSetVariable			(panelTitle, "setvar_Settings_SealStartP")
	PressureDataWv[][14] 			= GetSetVariable			(panelTitle, "setvar_Settings_SealMaxP")
	PressureDataWv[][15] 			= GetSetVariable			(panelTitle, "setvar_Settings_SurfaceHeight")
	PressureDataWv[][16] 			= GetSetVariable			(panelTitle, "setvar_Settings_SliceSurfHeight")
	
	WAVE/T PressureDataTxtWv = P_PressureDataTxtWaveRef(panelTitle)
	
	PressureDataTxtWv[headStageNo][0] = SelectedITCDevice
	PressureDataTxtWv[headStageNo][1] = GetSetVariableString(panelTitle, "SetVar_Hardware_Pressur_DA_Unit")
	PressureDataTxtWv[headStageNo][2] = GetSetVariableString(panelTitle, "SetVar_Hardware_Pressur_AD_Unit")
	
End

/// @brief Retrieves the parameters stored in the PressureData wave and passes them to the GUI controls
// based on the headStage selected in the device associations of the Hardware tab on the DA_Ephys panel
Function P_UpdatePressureControls(panelTitle, headStageNo)
	string 	panelTitle
	variable 	headStageNo
	WAVE 	PressureDataWv = P_GetPressureDataWaveRef(panelTitle)
	
	P_UpdatePopupITCdev(panelTitle, headStageNo)
	SetPopupMenuIndex	(panelTitle, "Popup_Settings_Pressure_DA", 	PressureDataWv[headStageNo][%DAC])
	SetSetVariable		(panelTitle, "setvar_Settings_Pressure_DAgain", 	PressureDataWv[headStageNo][%DAC_Gain])
	SetPopupMenuIndex	(panelTitle, "Popup_Settings_Pressure_AD", 	PressureDataWv[headStageNo][%ADC])
	SetSetVariable		(panelTitle, "setvar_Settings_Pressure_ADgain", 	PressureDataWv[headStageNo][%ADC_Gain])
	SetPopupMenuIndex	(panelTitle, "Popup_Settings_Pressure_TTL", 	PressureDataWv[headStageNo][%TTL])
	SetSetVariable		(panelTitle, "setvar_Settings_InAirP", 			PressureDataWv[headStageNo][%PSI_Air])
	SetSetVariable		(panelTitle, "setvar_Settings_InBathP", 			PressureDataWv[headStageNo][%PSI_Solution])
	SetSetVariable		(panelTitle, "setvar_Settings_InSliceP", 			PressureDataWv[headStageNo][%PSI_Slice])
	SetSetVariable		(panelTitle, "setvar_Settings_NearCellP", 		PressureDataWv[headStageNo][%PSI_NearCell])
	SetSetVariable		(panelTitle, "setvar_Settings_SealStartP", 		PressureDataWv[headStageNo][%PSI_SealInitial])
	SetSetVariable		(panelTitle, "setvar_Settings_SealMaxP", 		PressureDataWv[headStageNo][%PSI_SealMax])
	SetSetVariable		(panelTitle, "setvar_Settings_SurfaceHeight", 	PressureDataWv[headStageNo][%solutionZaxis])
	SetSetVariable		(panelTitle, "setvar_Settings_SliceSurfHeight", 	PressureDataWv[headStageNo][%sliceZaxis])
	
	WAVE/T PressureDataTxtWv = P_PressureDataTxtWaveRef(panelTitle)
	
	SetSetVariableString(panelTitle, "SetVar_Hardware_Pressur_DA_Unit", PressureDataTxtWv[headStageNo][%DA_Unit])
	SetSetVariableString(panelTitle, "SetVar_Hardware_Pressur_AD_Unit", PressureDataTxtWv[headStageNo][%AD_Unit])
End

/// @brief Updates the popupmenu popup_Settings_Pressure_ITCdev
Function P_UpdatePopupITCdev(panelTitle, headStageNo)
	string 		panelTitle
	variable 		headStageNo
	WAVE 		PressureDataWv 		= P_GetPressureDataWaveRef(panelTitle)
	WAVE/T 	PressureDataTxtWv 	= P_PressureDataTxtWaveRef(panelTitle)
	string 		control 				= "popup_Settings_Pressure_ITCdev"
	
	SetPopupMenuIndex(panelTitle, control, PressureDataWv[headStageNo][1])
	
	if(isFinite(PressureDataWv[headStageNo][1])) // only compare saved and selected device if a device was saved
		string 	SavedITCdev = PressureDataTxtWv[headStageNo][0]
		string 	PopUpMenuString = GetPopupMenuString(panelTitle, control)
		if(PressureDataWv[headStageNo][1] != 1) // compare saved and selected device to verify that they match. Non match could occur if data was saved prior to a popup menu update and ITC hardware change.
			if(cmpstr(SavedITCdev, PopUpMenuString) != 0)
				print "Saved ITC device for headStage", headStageNo, "is no longer at same list position."
				print "Verify the selected ITC device for headStage.", headStageNo
			endif
		endif
	endif
End


/// @brief Sends a pressure pulse to the pressure regulator. Gates the TTLs apropriately to maintain the exisiting TTL state while opening the TTL on the channel with the pressure pulse
Function P_NegPressurePulse(panelTitle, headStage)
	string 	panelTitle
	variable	headstage
	variable activeTTLstate
	variable pulseTTLstate
	Wave 	ITCData				= P_GetITCData(panelTitle)
	Wave 	ITCConfig			= P_GetITCChanConfig(panelTitle)
	Wave 	FIFOConfig			= P_GetITCFIFOConfig(panelTitle)
	Wave	FIFOAvail			= P_GetITCFIFOAvail(panelTitle)
	Wave 	pressureDataWv 		= P_GetPressureDataWaveRef(panelTitle)
	string	cmd
	DFREF PressureFolder = P_PressureFolderReference()

	P_DAforPpulse(panelTitle, Headstage) 	// update DA data
	P_ADforPpulse(panelTitle, Headstage) 	// update AD data
	P_TTLforPpulse(panelTitle, Headstage) 	// update TTL data
	
	// select the ITC device
	sprintf cmd, "ITCSelectDevice %d" pressureDataWv[headStage][%DAC_DevID]
	execute cmd
	
	// ensure device has stopped acquisition
	execute "ITCStopAcq"

	// configure all channels
	sprintf cmd, "ITCconfigAllchannels, %s, %s" getWavesDataFolder(ITCConfig, 2), getWavesDataFolder(ITCData, 2)
	execute cmd
	
	// reset the FIFO
	sprintf cmd, "ITCUpdateFIFOPositionAll, %s" getWavesDataFolder(FIFOConfig, 2)
	execute cmd
	
	// record onset of data acquisition
	pressureDataWv[][%OngoingPessurePulse]				= 0 // ensure that only one headstage is recorded as having an ongoing pressure pulse
	pressureDataWv[headStage][%OngoingPessurePulse] 	= 1 // record headstage with ongoing pressure pulse
	// start data acquisition
	execute "ITCStartAcq"
	
	// Start FIFO monitor
	CtrlNamedBackground P_FIFOMonitor, period = 15, proc = P_FIFOMonitorProc
	CtrlNamedBackground P_FIFOMonitor, start
End

// @brief Background function that monitors the device FIFO and terminates acquisition when sufficient data has been collected
Function P_FIFOMonitorProc(s)
	STRUCT 	WMBackgroundStruct &s
	string 		panelTitle
	variable 		DevID
	variable		headStage
	
	if(!P_FindPanelTitleExecutingPP(panelTitle, DevID, headStage))
		CtrlNamedBackground P_FIFOMonitor, stop
		print "No device can be found that is executing a pressure pulse"
	endif
	
	Wave		FIFOAvail			= P_GetITCFIFOAvail(panelTitle)
	Wave 		pressureDataWv 		= P_GetPressureDataWaveRef(panelTitle)
	string		cmd
	
	sprintf cmd, "ITCSelectDevice %d" DevID
	execute cmd
	
	sprintf cmd, "ITCFIFOAvailableALL /z = 0 , %s" getWavesDataFolder(FIFOAvail, 2)
	Execute cmd
	
	if(FIFOAvail[1][2] > 200 / SAMPLE_INT_MILLI)
		execute "ITCStopAcq"
		pressureDataWv[][%OngoingPessurePulse]	= 0
		CtrlNamedBackground P_FIFOMonitor, stop
		print "Pressure pulse is complete"
//		sprintf cmd, "ITCConfigChannelUpload /f /z = 0"//AS Long as this command is within the do-while loop the number of cycles can be repeated		
//		Execute cmd
		//P_ScaleP_ITCDataAD(panelTitle, headStage)
	endif
	
	
	return 0
	
End

Function P_ScaleP_ITCDataAD(panelTitle, headStage)
	string 	panelTitle
	variable 	headStage
	Wave 	ITCData			= P_GetITCData(panelTitle)
	Wave 	pressureDataWv 	= P_GetPressureDataWaveRef(panelTitle)
	Redimension /d ITCData
	ITCData[][%AD] /= BITS_PER_VOLT
	ITCData[][%AD] -= PRESSURE_OFFSET
	ITCData[][%AD] *= pressureDataWv[headStage][%ADC_Gain]
	redimension /w ITCData
End
/// @brief Returns the panelTitle of the ITC device associated with ITC device conducting a pressure pulse
Function P_FindPanelTitleExecutingPP(panelTitle, DevID, headStage)
	string 	&panelTitle
	variable 	&DevID, &headStage
	string 	ListOfLockedDevices = DAP_ListOfLockedDevs()
	variable 	i
	for(i = 0; i < itemsInList(ListOfLockedDevices); i += 1)
		panelTitle = stringfromlist(i, ListOfLockedDevices)
		Wave 	pressureDataWv 		= P_GetPressureDataWaveRef(panelTitle)
		for(headStage = 0; headstage <= 7; headStage += 1)
			if(pressureDataWv[headStage][%OngoingPessurePulse])
				DevID = pressureDataWv[headStage][%DAC_DevID]
				return 1
			endif
		endfor
	endfor
	
	return 0
End


/// @brief Updates the DA data used for ITC controlled pressure devices
Function P_DAforPpulse(panelTitle, Headstage)
	string 	panelTitle
	variable 	Headstage
	Wave 	ITCData				= P_GetITCData(panelTitle)
	Wave 	ITCConfig			= P_GetITCChanConfig(panelTitle)
	Wave 	FIFOConfig			= P_GetITCFIFOConfig(panelTitle)
	Wave	FIFOAvail			= P_GetITCFIFOAvail(panelTitle)	
	Wave 	pressureDataWv 		= P_GetPressureDataWaveRef(panelTitle)
	variable 	lastPressureCom		= pressureDataWv[Headstage][%LastPressureCommand]
	variable 	DAGain				= pressureDataWv[Headstage][%DAC_Gain]
	variable 	PressureCom = lastPressureCom - PRESSURE_PULSE_INCREMENT + MIN_NEG_PRESSURE_PULSE
	
	if((PressureCom) > -10)
		ITCData[][%DA] = (PRESSURE_OFFSET * BITS_PER_VOLT)
		ITCData[PRESSURE_PULSE_STARTpt, PRESSURE_PULSE_ENDpt][%DA] 	= ((((PressureCom) / DAGain) + PRESSURE_OFFSET) * BITS_PER_VOLT)
		ITCConfig	[%DA][%Chan_num] 											= pressureDataWv[headStage][%DAC] // set the DAC channel for the headstage
		FIFOConfig	[%DA][%Chan_num] 											= pressureDataWv[headStage][%DAC]
		FIFOAvail	[%DA][%Chan_num]											= pressureDataWv[headStage][%DAC]
	
	
		pressureDataWv[Headstage][%LastPressureCommand] =  (PressureCom)
		print "pulse amp",(PressureCom)
	else
		ITCData[][%DA] = (PRESSURE_OFFSET * BITS_PER_VOLT)
		ITCData[PRESSURE_PULSE_STARTpt, PRESSURE_PULSE_ENDpt][%DA] 	= ((((-2) / DAGain) + PRESSURE_OFFSET) * BITS_PER_VOLT)
		
		pressureDataWv[Headstage][%LastPressureCommand] =  - 2
		print "pulse amp", -2
	endif
	
End

/// @brief Update the AD data used for ITC controlled pressure devices
Function P_ADforPpulse(panelTitle, Headstage)
	string 	panelTitle
	variable 	Headstage
	Wave 	ITCData				= P_GetITCData(panelTitle)
	Wave 	ITCConfig			= P_GetITCChanConfig(panelTitle)
	Wave 	FIFOConfig			= P_GetITCFIFOConfig(panelTitle)
	Wave	FIFOAvail			= P_GetITCFIFOAvail(panelTitle)	
	Wave 	pressureDataWv 		= P_GetPressureDataWaveRef(panelTitle)
	
	ITCData		[][%AD] 				= 0
	ITCConfig	[%AD][%Chan_num] 	= pressureDataWv[headStage][%ADC]
	FIFOConfig	[%AD][%Chan_num] 	= pressureDataWv[headStage][%ADC]
	FIFOAvail	[%AD][%Chan_num]	= pressureDataWv[headStage][%ADC]
End
/// @brief Updates the rack 0 and rack 1 TTL waves used for ITC controlled pressure devices.
Function P_TTLforPpulse(panelTitle, Headstage)
	string 	panelTitle
	variable 	Headstage
	Wave 	ITCData				= P_GetITCData(panelTitle)
	Wave 	DIO 				= P_DIO(panelTitle)
	Wave 	pressureDataWv 		= P_GetPressureDataWaveRef(panelTitle)
	variable 	TTL					= pressureDataWv[headStage][%TTL]
	variable 	Rack0state
	variable 	Rack1state
	string 	ITCcom
	
	sprintf ITCcom, "ITCSelectDevice %d" pressureDataWv[headStage][%DAC_DevID]
	execute ITCcom
	
	sprintf ITCcom, "ITCReadDigital %d, %s" RACK_ZERO, getWavesDataFolder(DIO, 2) // get rack zero TTL state
	execute ITCcom	
	
	Rack0state = DIO[0]

	sprintf ITCcom, "ITCReadDigital %d, %s" RACK_ONE, getWavesDataFolder(DIO, 2) // get rack one TTL state
	execute ITCcom		
	
	Rack1state = DIO[0]
	
	// Set the TTL columns to their existing state
	ITCData[][%TTL_R1] = Rack1state 
	ITCData[][%TTL_R0] = Rack0state 

	if(TTL < 4) // Rack 0
		Rack0state = UpdateTTLdecimal(Rack0state, TTL, 1) // determine the TTL state for the pulse period
		ITCData[5000, PRESSURE_PULSE_ENDpt][%TTL_R0] = Rack0state // update the pulse period TTL state
	else // Rack 1
		Rack1state = UpdateTTLdecimal(Rack1state, TTL, 1)
		ITCData[5000, PRESSURE_PULSE_ENDpt][%TTL_R1] = Rack1state
	endif

End

/// @brief returns the new TTL state based on the starting TTL state.
Function UpdateTTLdecimal(startDecimal, TTL, ONorOFF)
	variable 	startDecimal
	variable	TTL
	variable 	ONorOFF
	variable 	endDecimal
	string 	BinaryList = P_DecToBinary(startDecimal)
	variable 	channelStatus = str2num(stringfromlist(TTL, BinaryList))
	
	if(TTL >= 4)
		TTL -= 4
	endif
	
	if(ONorOFF != channelStatus) // update tll associated with headStage only if the desired TTL channel state is different from the actual/current channel state.
		if(ONorOFF)
			endDecimal = startDecimal + 2^TTL
		else
			endDecimal = startDecimal - 2^TTL
		endif
	endif

	return endDecimal
End

/// @brief Updates the pressure mode button state in the DA_Ephys Data Acq tab
Function P_UpdatePressureMode(panelTitle, pressureMode, pressureControlName, checkALL)
	string panelTitle
	variable pressureMode
	string pressureControlName
	variable checkAll
	variable headStageNo = GetSliderPositionIndex(panelTitle, "slider_DataAcq_ActiveHeadstage")
	WAVE PressureDataWv = P_GetPressureDataWaveRef(panelTitle)
	variable SavedPressureMode = PressureDataWv[headStageNo][0]
	
	if(P_ValidatePressureSetHeadstage(panelTitle, headStageNo)) // check if headStage pressure settings are valid
		P_CheckEnable(panelTitle, headStageNo)
		
		if(pressureMode == SavedPressureMode) // The saved pressure mode and the pressure mode being passed are equal therefore toggle the same button
			SetControlTitle(panelTitle, pressureControlName, stringfromlist(pressureMode, PRESSURE_CONTROL_TITLE_LIST))
			SetControlTitleColor(panelTitle, pressureControlName, 0, 0, 0)
			PressureDataWv[headStageNo][0] = -1
		else // saved and new pressure mode don't match
			if(SavedPressureMode != -1) // saved pressure mode isn't pressure OFF (-1) 
				// reset the button for the saved pressure mode
				SetControlTitle(panelTitle, stringfromlist(SavedPressureMode, PRESSURE_CONTROLS_BUTTON_LIST), stringfromlist(SavedPressureMode, PRESSURE_CONTROL_TITLE_LIST))
				SetControlTitleColor(panelTitle, stringfromlist(SavedPressureMode, PRESSURE_CONTROLS_BUTTON_LIST), 0, 0, 0)
			endif
			
			if(PressureMode == 0) // On approach, apply the mode			
				SetControlTitle(panelTitle, pressureControlName, ("Stop " + stringfromlist(pressureMode, PRESSURE_CONTROL_TITLE_LIST)))
				SetControlTitleColor(panelTitle, pressureControlName, 39168, 0, 0)
				PressureDataWv[headStageNo][0] = pressureMode
			elseif(PressureMode)
				if(P_IsTPActive(panelTitle) && P_IsHSActiveAndInVClamp(panelTitle, headStageNo)) // check to see if TP is running and the headStage is in V-clampmode
					SetControlTitle(panelTitle, pressureControlName, ("Stop " + stringfromlist(pressureMode, PRESSURE_CONTROL_TITLE_LIST)))
					SetControlTitleColor(panelTitle, pressureControlName, 39168, 0, 0)
					PressureDataWv[headStageNo][0] = pressureMode
				endif
			endif
		endif
	endif
	
	if(checkAll)
		P_CheckAll(panelTitle, pressureMode, SavedPressureMode)
	endif
	
End

/// @brief Applies pressure mode to all headstages with valid pressure settings
Function P_CheckAll(panelTitle, pressureMode, SavedPressureMode)
	string 	panelTitle
	variable 	pressureMode, SavedPressureMode
	variable 	headStage
	WAVE PressureDataWv = P_GetPressureDataWaveRef(panelTitle)
	if(pressureMode == savedPressureMode) // un clicking button
		if(getCheckboxState(panelTitle, stringfromlist(savedPressureMode, PRESSURE_CONTROL_CHECKBOX_LIST)))
			PressureDataWv[][0] = -1
		endif
	else	
		if(getCheckboxState(panelTitle, stringfromlist(pressureMode, PRESSURE_CONTROL_CHECKBOX_LIST)))
			for(headStage = 0; headStage <= 7; headStage += 1)
				if(P_ValidatePressureSetHeadstage(panelTitle, headStage))
					if(pressureMode && P_IsTPActive(panelTitle) && P_IsHSActiveAndInVClamp(panelTitle, headStage))
						PressureDataWv[headStage][0] = pressureMode
					else
						PressureDataWv[headStage][0] = pressureMode // pressure mode = 0
					endif
				endif
			endfor
		endif
	endif	
End


/// @brief Colors and changes the title of the pressure buttons based on the saved pressure mode.
Function P_LoadPressureButtonState(panelTitle, headStageNo)
	string panelTitle
	variable headStageNo
	
	P_ResetAll_P_ButtonsToBaseState(panelTitle)
	WAVE PressureDataWv = P_GetPressureDataWaveRef(panelTitle)
	if(P_ValidatePressureSetHeadstage(panelTitle, headStageNo)) // check if headStage pressure settings are valid
		
//		EnableListOfControls(panelTitle, PRESSURE_CONTROLS_BUTTON_LIST)
		P_CheckEnable(panelTitle, headStageNo)
		variable SavedPressureMode = PressureDataWv[headStageNo][0]
		
		if(SavedPressureMode != -1) // there is an active pressure mode
			if(SavedPressureMode == 0) // On approach, apply the mode
				SetControlTitle(panelTitle, stringfromlist(SavedPressureMode, PRESSURE_CONTROLS_BUTTON_LIST), ("Stop " + stringfromlist(SavedPressureMode, PRESSURE_CONTROL_TITLE_LIST)))
				SetControlTitleColor(panelTitle, stringfromlist(SavedPressureMode, PRESSURE_CONTROLS_BUTTON_LIST), 39168, 0, 0)
			elseif(SavedPressureMode) // other pressure modes
				if(P_IsTPActive(panelTitle) && P_IsHSActiveAndInVClamp(panelTitle, headStageNo)) // check to see if TP is running and the headStage is in V-clampmode
					SetControlTitle(panelTitle, stringfromlist(SavedPressureMode, PRESSURE_CONTROLS_BUTTON_LIST), ("Stop " + stringfromlist(SavedPressureMode, PRESSURE_CONTROL_TITLE_LIST)))
					SetControlTitleColor(panelTitle, stringfromlist(SavedPressureMode, PRESSURE_CONTROLS_BUTTON_LIST), 39168, 0, 0)
				endif
			endif	
		endif
	else
		DisableListOfControls(panelTitle, PRESSURE_CONTROLS_BUTTON_LIST)
		print "An ITC device used for pressure regulation is not enabled for this MIES headstage"
	endif
	
	P_PressureDisplayUnhighlite(panelTitle) // remove highlite from val displays that show pressure for each headStage
	P_PressureDisplayHighlite(panelTitle, headStageNo) // highlites specific headStage
End


/// @brief Checks if the Approach button can be enabled or all pressure mode buttons can be enabled. Enables buttons that pass checks.
Function P_CheckEnable(panelTitle, headStageNo)
	string panelTitle
	variable headStageNo
	
	if(P_IsTPActive(panelTitle) && P_IsHSActiveAndInVClamp(panelTitle, headStageNo))
		EnableListOfControls(panelTitle, PRESSURE_CONTROLS_BUTTON_LIST)
	else
		string PRESSURE_CONTROLS_BUTTON_subset = removeListItem(0, PRESSURE_CONTROLS_BUTTON_LIST)
		DisableListOfControls(panelTitle, PRESSURE_CONTROLS_BUTTON_subset)
		EnableControl(panelTitle, stringfromlist(0, PRESSURE_CONTROLS_BUTTON_LIST))
	endif
End

/// @brief Checks if all the pressure settings for a headStage are valid
Function P_ValidatePressureSetHeadstage(panelTitle, headStageNo)
	string panelTitle
	variable headStageNo
	WAVE PressureDataWv = P_GetPressureDataWaveRef(panelTitle)
	WAVE/T PressureDataTxtWv = P_PressureDataTxtWaveRef(panelTitle)
	string msg
	
	if(!isFinite(PressureDataWv[headStageNo][2]))
		sprintf msg, "DAC Type is not configured for headStage %d"  headStageNo
		DEBUGPRINT(msg)
		return 0
	endif
	
	if(!isFinite(PressureDataWv[headStageNo][3]))
		sprintf msg, "DAC device ID is not configured for headstage %d"  headStageNo
		DEBUGPRINT(msg)		
		return 0
	endif

	if(!isFinite(PressureDataWv[headStageNo][5]))
		sprintf msg, "DAC gain is not configured for headstage %d"  headStageNo
		DEBUGPRINT(msg)		
		return 0
	endif	
	
	if(!isFinite(PressureDataWv[headStageNo][7]))
		sprintf msg, "ADC Type is not configured for headstage %d"  headStageNo
		DEBUGPRINT(msg)		
		return 0
	endif
	
	if(!isFinite(PressureDataWv[headStageNo][9]))
		sprintf msg, "Approach pressure in air is not configured for headstage %d"  headStageNo
		DEBUGPRINT(msg)		
		return 0
	endif
	
	if(!isFinite(PressureDataWv[headStageNo][10]))
		sprintf msg, "Approach pressure in solution is not configured for headstage %d"  headStageNo
		DEBUGPRINT(msg)		

		return 0
	endif
	
	if(!isFinite(PressureDataWv[headStageNo][11]))
		sprintf msg, "Approach pressure in slice is not configured for headstage %d"  headStageNo
		DEBUGPRINT(msg)		

		return 0
	endif
	
	if(!isFinite(PressureDataWv[headStageNo][12]))
		sprintf msg, "Approach pressure in slice is not configured for headstage %d"  headStageNo
		DEBUGPRINT(msg)		
		return 0
	endif
	
	if(!isFinite(PressureDataWv[HeadStageNo][13]))
		sprintf msg, "Initial seal pressure is not configured for headstage %d"  headStageNo
		DEBUGPRINT(msg)		
		return 0
	endif
	
	if(!isFinite(PressureDataWv[headStageNo][14]))
		sprintf msg, "Maximum seal pressure is not configured for headstage %d"  headStageNo
		DEBUGPRINT(msg)		
		return 0
	endif
	
	return 1
End
/// @brief Determines if ITC device is active (i.e. collecting data)
///
/// used to determine if pressure pulse has completed.
Function IsITCCollectingData(panelTitle, headStage)
	string panelTitle
	variable headStage
	
	string cmd
	wave StateWave =  P_ITCState(panelTitle)
	wave PressureDataWv = P_GetPressureDataWaveRef(panelTitle)
	
	sprintf cmd, "ITCSelectDevice %d" pressureDataWv[headStage][%DAC_DevID]
	execute cmd	
	
	sprintf cmd, "ITCGetState/R=1 %s" getWavesDataFolder(StateWave, 2)
	execute cmd
	
	if(StateWave[0] == 0)
		return 0
	else
		return 1
	endif
	
End
/// @brief Determines if bacground TP is active
///
/// Accounts for different acquistion modes (different background functions are used for different TP acquisition modes)
Function P_IsTPActive(panelTitle)
	string panelTitle
	variable MDEnable = GetCheckBoxState(panelTitle, "check_Settings_MD")
	
	if(MDEnable)
		if(getControlDisable(panelTitle, "StartTestPulseButton")) // check if TP is running on this particular device by seeing if the TP button is disabled
			return TP_IsBackgrounOpRunning(panelTitle, "TestPulseMD") // check if the background function that runs the TP is also active
		endif
	else
		return TP_IsBackgrounOpRunning(panelTitle, "testpulse")
	endif
	
	return 0
End

/// @brief Determines headStage is on and in V-Clamp mode
Function P_IsHSActiveAndInVClamp(panelTitle, headStage)
	string panelTitle
	variable headStage
	string headStageCheckboxName
	sprintf headStageCheckboxName, "Check_DataAcq_HS_%0.2d" headStage

	if(!AI_MIESHeadstageMode(panelTitle, headStage) && getcheckboxstate(panelTitle, headStageCheckboxName))
		return 1
	endif
	
	return 0
End

/// @brief Returns the four pressure buttons to the base state (gray color; removes "Stop" string from button title)
Function P_ResetAll_P_ButtonsToBaseState(panelTitle)
	string panelTitle

	variable i = 0
	for(i = 0; i < 4; i += 1)
		SetControlTitle(panelTitle, stringfromlist(i, PRESSURE_CONTROLS_BUTTON_LIST), stringfromlist(i, PRESSURE_CONTROL_TITLE_LIST))
		SetControlTitleColor(panelTitle, stringfromlist(i, PRESSURE_CONTROLS_BUTTON_LIST), 0, 0, 0)
	endfor
End

/// @brief Highlite pressure display
Function P_PressureDisplayHighlite(panelTitle, headStageNo)
	string panelTitle
	variable headStageNo
	string ControlName
	sprintf ControlName, "valdisp_DataAcq_P_%d" headStageNo
	ChangeControlValueColor(panelTitle, controlName, 65535, 65535, 65535) // black
	ChangeControlBckgColor(panelTitle, controlName, 0, 0, 0) // white
End

/// @brief unHighlites pressure display
Function P_PressureDisplayUnhighlite(panelTitle)
	string panelTitle
		
	ChangeListOfControlValueColor(panelTitle, PRESSURE_CONTROL_PRESSURE_DISP, 0, 0, 0) // white
	ChangeListOfControlBckgColor(panelTitle, PRESSURE_CONTROL_PRESSURE_DISP,65535, 65535, 65535) // black
End

/// @brief Enables ITC devices for all locked DA_Ephys panels. Sets the correct pressure button state for all locked DA_Ephys panels.
Function P_Enable()
	string ListOfLockedDA_Ephys = DAP_ListOfLockedDevs()
	variable i
	variable j = 0
	string LockedDevice
	for(i = 0; i < itemsinList(ListOfLockedDA_Ephys); i += 1)
		LockedDevice = stringfromlist(i, ListOfLockedDA_Ephys)
		if(itemsinlist(P_ITCDevToOpen())) // check to ensure there are ITC devices assigned by the user for pressure regulation
			DisableControl(LockedDevice, "button_Hardware_P_Enable") // disable this button
			if(j == 0)
				P_OpenITCDevForP_Reg(LockedDevice) // 	open ITC devices used for pressure regulation
			endif
			EnableControl(LockedDevice, "button_Hardware_P_Disable") // enable the ITC device pressure regulation disable button
			EnableListOfControls(LockedDevice, PRESSURE_CONTROL_CHECKBOX_LIST) // enable the pressure regulation check box controls
			variable headStage = GetSliderPositionIndex(LockedDevice, "slider_DataAcq_ActiveHeadstage") // determine the selected MIES headstage
			P_LoadPressureButtonState(LockedDevice, headStage) // apply the pressure button settings for the active MIES headStage (prevent pressure buttons from being activated if an ITC device isn't assigned and enabled to the headStage for pressure regulation)	
			j+=1
		else
			print "No ITC devices are presently assigned for pressure regulation on:",LockedDevice
		endif
	endfor
	
End

/// @brief Disables ITC devices for all locked DA_Ephys panels. Sets the correct pressure button state for all locked DA_Ephys panels.
Function P_Disable()
	string ListOfLockedDA_Ephys = DAP_ListOfLockedDevs()
	variable i, j = 0
	string LockedDevice
	for(i = 0; i < itemsinList(ListOfLockedDA_Ephys); i += 1)
		LockedDevice = stringfromlist(i, ListOfLockedDA_Ephys)
		if(itemsinlist(P_ITCDevToOpen())) // check to ensure there are ITC devices assigned by the user for pressure regulation
			DisableControl(LockedDevice, "button_Hardware_P_Disable") // disable this button
			if(j == 0)
				P_CloseITCDevForP_Reg(LockedDevice) // 	close ITC devices used for pressure regulation
			endif
			EnableControl(LockedDevice, "button_Hardware_P_Enable") // enable the ITC device pressure regulation disable button
			EnableListOfControls(LockedDevice,PRESSURE_CONTROL_CHECKBOX_LIST)		// enable the pressure regulation check box controls
			DisableListOfControls(LockedDevice, PRESSURE_CONTROLS_BUTTON_LIST) 		// disable the buttons used for pressure regulation
			DisableListOfControls(LockedDevice, PRESSURE_CONTROL_CHECKBOX_LIST)	// disable the checkboxes used for pressure regulation
			j += 1
		endif
	endfor
End

/// @brief Decimal to binary in string list format. 
///
/// List is always 4 items long so that each TTL channel on the front of the ITC DAC gets "encoded"
/// use commented out code for arbitrary decimal numbers 
Function/S P_DecToBinary(dec)
	variable dec
	variable bit	
	string binary	=""
//	do
//		bit = mod(Dec,2)
//		dec /= 2
//		dec = floor(dec)
//		binary = addlistitem(num2str(bit), binary,";", inf)
//	
//	while(Dec > 0)
	variable i

	for(i = 0; i < 4; i += 1)
		bit = mod(Dec,2)
		dec /= 2
		dec = floor(dec)
		binary = addlistitem(num2str(bit), binary,";", inf)
	endfor
	
	return binary
End
//============================================================================================================
// MANUAL PRESSURE CONTROL 
//============================================================================================================
/// @ brief Sets the pressure on the active headstage or all headstages.
Function P_ManSetPressure(panelTitle)
	string panelTitle
	variable psi = GetSetVariable(panelTitle, "setvar_DataAcq_SSPressure")
	variable headStage
	if(GetCheckBoxState(panelTitle, "check_DataAcq_ManPressureAll"))
		for(headStage = 0; headStage < 8; headStage += 1)
			P_SetPressure(panelTitle, headStage, psi)
		endfor
	else
		headStage = GetSliderPositionIndex(panelTitle, "slider_DataAcq_ActiveHeadstage")
		P_SetPressure(panelTitle, headStage, psi)
	endif
End

Function P_ManPressurePulse(panelTitle)
	string panelTitle
	
End
//============================================================================================================
// PRESSURE CONTROLS; DA_ePHYS PANEL; DATA ACQUISTION TAB
//============================================================================================================
Function ButtonProc_Approach(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			variable PressureMode = 0
			P_UpdatePressureMode(ba.win, PressureMode, ba.ctrlName, 1) // 
			if(!P_IsTPActive(ba.win)) // P_PressureControl will be called from TP functions when the TP is running
				P_PressureControl(ba.win)
			endif
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function CheckProc_ApproachAll(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	switch( cba.eventCode )
		case 2: // mouse up
			Variable checked = cba.checked
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function ButtonProc_Seal(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			variable PressureMode = 1
			P_UpdatePressureMode(ba.win, PressureMode, ba.ctrlName, 1)// 
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function CheckProc_SealAll(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	switch( cba.eventCode )
		case 2: // mouse up
			Variable checked = cba.checked
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function ButtonProc_BreakIn(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			variable PressureMode = 2
			P_UpdatePressureMode(ba.win, PressureMode, ba.ctrlName, 1)
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function CheckProc_BreakInAll(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	switch( cba.eventCode )
		case 2: // mouse up
			Variable checked = cba.checked
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function ButtonProc_Clear(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			variable PressureMode = 3
			P_UpdatePressureMode(ba.win, PressureMode, ba.ctrlName, 1)
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

/// @breif Enables button that controls pipette pressure clearing
/// Pipette pressure clearing could kill a neuon if accidentally activated
Function CheckProc_ClearEnable(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	switch( cba.eventCode )
		case 2: // mouse up
			Variable checked = cba.checked
			if(checked)
				EnableControl(cba.win, "button_DataAcq_Clear")
			else
				DisableControl(cba.win, "button_DataAcq_Clear")
			endif
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function PopMenuProc_AvaillTCDevices(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	switch( pa.eventCode )
		case 2: // mouse up
			Variable popNum = pa.popNum
			String popStr = pa.popStr
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

//============================================================================================================
// PRESSURE CONTROLS; DA_ePHYS PANEL; HARDWARE TAB
//============================================================================================================
Function CheckProc_PostivePressureAll(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	switch( cba.eventCode )
		case 2: // mouse up
			Variable checked = cba.checked
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function ButtonProc_Hrdwr_P_UpdtDAClist(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			string DeviceList = "- none -;" + HSU_ListDevices()
			SetPopupMenuVal(ba.win, "popup_Settings_Pressure_ITCdev", DeviceList)// click code here
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

/// @brief Pressure control ITC device Enable button in Hardware tab of DA_Ephys panel
Function P_ButtonProc_Enable(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			P_Enable()
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

/// @brief Pressure control ITC device Disable button in Hardware tab of DA_Ephys panel
Function P_ButtonProc_Disable(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			P_Disable()		
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

