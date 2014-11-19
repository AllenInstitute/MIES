#pragma rtGlobals=3		// Use modern global access method and strict wave access.

/// @file TJ_MIES_PressureControl.ipf
/// @brief Supports use of analog pressure regulators controlled via a ITC device for automated pressure control during approach, seal, break in, and clearing of pipette.
/// @todo TPbackground can crash while operating pressure regulators if called in the middel of a TP. Need to call P_Pressure control from TP functions that occur between TPs to prevent this from happening

///@name Constants Used by pressure control
/// @{
static StrConstant PRESSURE_CONTROLS_BUTTON_LIST  = "button_DataAcq_Approach;button_DataAcq_Seal;button_DataAcq_BreakIn;button_DataAcq_Clear;button_DataAcq_SSSetPressureMan;button_DataAcq_PPSetPressureMan"
static StrConstant PRESSURE_CONTROL_TITLE_LIST    = "Approach;Seal;Break In;Clear"
static StrConstant PRESSURE_CONTROL_CHECKBOX_LIST = "check_DatAcq_ApproachAll;check_DatAcq_SealAll;check_DatAcq_BreakInAll;check_DatAcq_ClearEnable"
static StrConstant PRESSURE_CONTROL_PRESSURE_DISP = "valdisp_DataAcq_P_0;valdisp_DataAcq_P_1;valdisp_DataAcq_P_2;valdisp_DataAcq_P_3;valdisp_DataAcq_P_4;valdisp_DataAcq_P_5;valdisp_DataAcq_P_6;valdisp_DataAcq_P_7"
static Constant P_METHOD_neg1_ATM            = -1
static Constant P_METHOD_0_APPROACH          = 0
static Constant P_METHOD_1_SEAL              = 1
static Constant P_METHOD_2_BREAKIN           = 2
static Constant P_METHOD_3_CLEAR             = 3
static Constant P_METHOD_4_MANUAL            = 4
static Constant RACK_ZERO                    = 0
static Constant RACK_ONE                     = 3 // 3 is defined by the ITCWriteDigital command instructions.
static Constant BITS_PER_VOLT                = 3200
static Constant NEG_PRESSURE_PULSE_INCREMENT = 0.2 // psi
static Constant POS_PRESSURE_PULSE_INCREMENT = 0.1 // psi
static Constant PRESSURE_PULSE_STARTpt       = 1 // 12000
static Constant PRESSURE_PULSE_ENDpt         = 35000
static Constant SAMPLE_INT_MILLI             = 0.005
static Constant GIGA_SEAL                    = 1000
static Constant PRESSURE_OFFSET              = 5
static Constant MIN_NEG_PRESSURE_PULSE       = -1
Constant        SAMPLE_INT_MICRO             = 5
/// @}

/// @brief Applies pressure methods based on data in PressureDataWv
///
/// This function gets called every 500 ms while the TP is running. It also gets called when the approach button is pushed.
/// A key point is that data acquisition used to run pressure pulses cannot be active if the TP is inactive.
Function P_PressureControl(panelTitle)
	string 	panelTitle
	WAVE 	PressureDataWv = P_GetPressureDataWaveRef(panelTitle)
	variable 	headStage
	for(headStage = 0; headStage < NUM_HEADSTAGES; headStage += 1)
		if(P_ValidatePressureSetHeadstage(panelTitle, headStage) && !IsITCCollectingData(panelTitle, headStage)) // are headstage settings valid AND is the ITC device inactive
			switch(PressureDataWv[headStage][%Approach_Seal_BrkIn_Clear])
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
						 P_MethodClear(panelTitle, headStage)
					endif
					break
			endswitch
		endif
	endfor
End

/// @brief Sets the pressure to atmospheric
Function P_MethodAtmospheric(panelTitle, headstage)
	string 	panelTitle
	variable 	headStage
	WAVE 	PressureDataWv = P_GetPressureDataWaveRef(panelTitle)
	P_UpdateTTLstate(panelTitle, headStage, 0)
	PressureDataWv[headStage][%LastPressureCommand] = P_SetPressure(panelTitle, headStage, 0)
End
	
/// @brief Applies approach pressures
Function P_MethodApproach(panelTitle, headStage)
	string 	panelTitle
	variable 	headStage
	WAVE 	PressureDataWv = P_GetPressureDataWaveRef(panelTitle)
	variable 	targetP = PressureDataWv[headStage][%PSI_solution] 	// Approach pressure is stored in row 10 (Solution approach pressure). Once manipulators are part of MIES, other approach pressures will be incorporated
	variable	ONorOFF = 1
	
	P_UpdateTTLstate(panelTitle, headStage, ONorOFF) // Open the TTL
	PressureDataWv[headStage][%LastPressureCommand] = P_SetPressure(panelTitle, headStage, targetP)
End

/// @brief Applies seal methods
Function P_MethodSeal(panelTitle, headStage)
	string 	panelTitle
	variable 	headStage
	WAVE 	PressureDataWv 			= P_GetPressureDataWaveRef(panelTitle)
	variable 	RSlope
	variable 	RSlopeThreshold 			= 8 // with a slope of 8 Mohm/s it will take two minutes for a seal to form.
	variable 	lastRSlopeCheck 		= PressureDataWv[headStage][%TimeOfLastRSlopeCheck] / 60
	variable 	timeInSec 				= ticks / 60
	variable 	ElapsedTimeInSeconds 	= timeInSec - LastRSlopeCheck
	
	if(!lastRSlopeCheck || numType(lastRSlopeCheck) == 2) // checks for first time thru.
		ElapsedTimeInSeconds = 0
		PressureDataWv[headStage][%TimeOfLastRSlopeCheck] = ticks
	endif
	
	P_UpdateSSRSlopeAndSSR(panelTitle) // update the resistance values used to assess seal changes
	variable resistance = PressureDataWv[headStage][%LastResistanceValue]
	variable pressure = PressureDataWv[headStage][%LastPressureCommand] 
	
	// if the seal resistance is greater that 1 giga ohm set pressure to atmospheric AND stop sealing process
	if(Resistance >= GIGA_SEAL)
		P_MethodAtmospheric(panelTitle, headstage) // set to atmospheric pressure
 		P_UpdatePressureMode(panelTitle, 1, StringFromList(1,PRESSURE_CONTROLS_BUTTON_LIST), 0)
		PressureDataWv[headStage][%Approach_Seal_BrkIn_Clear] 	= P_METHOD_neg1_ATM // remove the seal mode
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
			pressure = PressureDataWv[headStage][%PSI_SealInitial] 
			PressureDataWv[headStage][%LastPressureCommand] = PressureDataWv[headStage][%PSI_SealInitial]
			print "starting seal"
		endif	
		// if the seal slope has plateau'd or is going down, increase the negative pressure
		// print ElapsedTimeInSeconds
		if(ElapsedTimeInSeconds > 5) // Allows 10 seconds to elapse before pressure would be changed again. The R slope is over the last 5 seconds.
			RSlope = PressureDataWv[headStage][%PeakResistanceSlope]
			print "slope", rslope, "thres", RSlopeThreshold
			if(RSlope < RSlopeThreshold) // if the resistance is not going up quickly enough increase the negative pressure
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
		P_UpdatePressureMode(panelTitle, 2, StringFromList(2,PRESSURE_CONTROLS_BUTTON_LIST), 0) // sets break-in button back to base state
		PressureDataWv[headStage][%Approach_Seal_BrkIn_Clear] 	= P_METHOD_neg1_ATM // remove the seal mode
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
	WAVE 	PressureDataWv 			= P_GetPressureDataWaveRef(panelTitle)
	variable 	lastRpeakCheck 			= PressureDataWv[headStage][%TimePeakRcheck] / 60
	variable 	timeInSec 				= ticks / 60
	variable 	ElapsedTimeInSeconds 	= timeInSec - lastRpeakCheck	

	P_UpdateSSRSlopeAndSSR(panelTitle)

	if(!lastRpeakCheck || numType(lastRpeakCheck) == 2) // checks for first time thru.
		ElapsedTimeInSeconds = 0
		PressureDataWv[headStage][%TimePeakRcheck] = ticks
		PressureDataWv[headStage][%LastPeakR] = PressureDataWv[headStage][%PeakR] // sets the last peak R = to the current peak R
	endif

	if(PressureDataWv[headStage][%peakR] > (0.9 * PressureDataWv[headStage][%LastPeakR]))
		if(ElapsedTimeInSeconds > 2.5)
			print "applying positive pressure pulse!"
		 	P_PosPressurePulse(panelTitle, headStage)
		 	PressureDataWv[headStage][%TimePeakRcheck] = ticks
		 	PressureDataWv[headStage][%LastPeakR] = PressureDataWv[headStage][%PeakR]
		endif	
	else
		P_MethodAtmospheric(panelTitle, headstage) // set to atmospheric pressure
		P_UpdatePressureMode(panelTitle, 3, StringFromList(3,PRESSURE_CONTROLS_BUTTON_LIST), 0) // sets break-in button back to base state
		PressureDataWv[headStage][%Approach_Seal_BrkIn_Clear] 	= P_METHOD_neg1_ATM // remove the seal mode
		PressureDataWv[headStage][%TimePeakRcheck]			= 0 // reset the time of last slope R check
		PressureDataWv[headStage][%LastPressureCommand]		= 0
	endif
	
End

/// @brief Applies updates the command Voltage so that -100 pA current is applied up to the target voltage
Function P_ApplyNegV(panelTitle, headStage)
	string 	panelTitle
	variable 	headStage
	WAVE 	PressureDataWv 	= P_GetPressureDataWaveRef(panelTitle)
	variable 	resistance 		=  PressureDataWv[headStage][%LastResistanceValue]
	variable 	vCom 			= floor(-0.200 * resistance)
	variable	lastVcom = PressureDataWv[headStage][%LastVcom]

	if(getCheckBoxstate(panelTitle, "Check_DataAcq_SendToAllAmp")) // ensure that vCom is being updated on headstage associated amplifier (not all amplifiers).
		setCheckBoxstate(panelTitle, "Check_DataAcq_SendToAllAmp",0)
	endif
// determine command voltage that will result in a holding pA of -100 pA	
// if V = -100 * resistance is greater than target voltage, apply target voltage, otherwise apply calculated voltage
	
 	if(!isFinite(lastVcom))
		lastVcom = 0
	endif
	
	if(vCom > -70 && (vCom > (lastVcom + 2) || vCom < (lastVcom - 2)))
		print "vcom=",vcom
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
	for(i = 0; i < ItemsInList(ListOfITCDevToOpen); i += 1)
		P_OpenITCDevice(panelTitle, StringFromList(i, ListOfITCDevToOpen))
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
	variable 	i, j
	
	for(i = 0; i < ItemsInList(ListOfITCDevToClose); i += 1) // for all the ITC devices used for pressure regulation
		// find device ID
		do
			panelTitle = StringFromList(j, ListOfLockedDA_Ephys)
			DeviceToClose = StringFromList(i,ListOfITCDevToClose)

			ListOfHeadstagesUsingITCDev = P_HeadstageUsingITCDevice(panelTitle, DeviceToClose)
			j += 1
		while(cmpstr("", ListOfHeadstagesUsingITCDev) == 0)
			j = 0
			
			print "panel title:", panelTitle
			print "Device to close:", DeviceToClose
			headStage = str2num(StringFromList(0, ListOfHeadstagesUsingITCDev))
			
			WAVE PressureDataWv = P_GetPressureDataWaveRef(panelTitle)
			P_CloseITCDevice(panelTitle, DeviceToClose , PressureDataWv[headStage][%DAC_DevID])
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
	for(j = 0; j < ItemsInList(ListOfLockedDA_Ephys); j += 1)
		panelTitle = StringFromList(j, ListOfLockedDA_Ephys)
		ListOfHeadstageUsingITCDevice = P_HeadstageUsingITCDevice(panelTitle, ITCDeviceToOpen)
		if(cmpstr("",ListOfHeadstageUsingITCDevice) != 0)
			for(i = 0; i < ItemsInList(ListOfHeadstageUsingITCDevice); i += 1)
				headStage = str2num(StringFromList(i, ListOfHeadstageUsingITCDevice))
				WAVE PressureDataWv = P_GetPressureDataWaveRef(panelTitle)
				PressureDataWv[headStage][%DAC_DevID] = DevID[0]
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

	for(j = 0; j < ItemsInList(ListOfLockedDA_Ephys); j += 1)
		panelTitle = StringFromList(j, ListOfLockedDA_Ephys)	
		ListOfHeadstageUsingITCDevice = P_HeadstageUsingITCDevice(panelTitle, ITCDevToClose)
		for(i = 0; i < ItemsInList(ListOfHeadstageUsingITCDevice); i += 1)
			print "LIST" , ListOfHeadstageUsingITCDevice
			if(cmpstr("",ListOfHeadstageUsingITCDevice) != 0)
				headStage = str2num(StringFromList(i, ListOfHeadstageUsingITCDevice))
				WAVE PressureDataWv = P_GetPressureDataWaveRef(panelTitle)
				print "about to reset dev ID global"
				PressureDataWv[headStage][%DAC_DevID] = Nan
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
	for(i = 0; i < NUM_HEADSTAGES; i += 1)
		if(cmpstr(ITCDevice, PressureDataTxtWv[i][0]) == 0)
			ListString = AddListItem(num2str(i), ListString)
		endif
	endfor

	return ListString
End

/// @brief Returns a list of ITC devices to open
/// pulls a non repeating list of ITC devices to open from the device specific pressure data wave.
Function/S P_ITCDevToOpen()
	string 	ListOfLockedDevices = DAP_ListOfLockedDevs()
	
	string 	deviceList = ""
	variable 	i, j
	variable 	alreadyInList
	
	for(j = 0; j < ItemsInList(ListOfLockedDevices); j += 1)
		for(i = 0; i < NUM_HEADSTAGES; i += 1)
			wave/T 	pressureDataTxtWave = P_PressureDataTxtWaveRef(StringFromList(j, ListOfLockedDevices))
			if(cmpstr(pressureDataTxtWave[i][0],"") != 0 && cmpstr(pressureDataTxtWave[i][0],"- none -") != 0) // prevent blanks from being inserted into list
				if(WhichListItem(pressureDataTxtWave[i][0], deviceList) == -1) // prevent duplicates from being inserted into list
					deviceList = AddListItem(pressureDataTxtWave[i][0], deviceList)
				endif
			endif	
		endfor
	endfor
	
	return sortlist(deviceList) // sort the list so that the devices are opened in the correct sequence (low devID to high devID)
End

/// @brief Sets the pressure on a headStage
Function P_SetPressure(panelTitle, headStage, psi)
	string 	panelTitle
	variable 	headStage, psi
	WAVE 	PressureDataWv = P_GetPressureDataWaveRef(panelTitle)
	P_PressureCommand(panelTitle, PressureDataWv[headStage][%DAC_DevID], PressureDataWv[headStage][%DAC], PressureDataWv[headStage][%ADC], psi, PressureDataWv[headStage][%DAC_Gain])
	SetValDisplaySingleVariable(panelTitle, StringFromList(headstage,PRESSURE_CONTROL_PRESSURE_DISP) , psi, format = "%2.2f")
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

/// @brief Gets the pressure on a headStage
Function P_GetPressure(panelTitle, headStage)
	string 	panelTitle
	variable 	headStage
	WAVE 	pressureDataWv = P_GetPressureDataWaveRef(panelTitle)
	return P_ReadADC(panelTitle, pressureDataWv[headStage][%DAC_DevID], pressureDataWv[headStage][%ADC], pressureDataWv[headStage][%ADC_Gain])
End

/// @brief Gets the pressure using a single AD channel on a ITC device
Function P_ReadADC(panelTitle, ITCDeviceIDGlobal, ADC, AD_ScaleFactor)
	string 	panelTitle
	variable 	ITCDeviceIDGlobal, ADC, AD_ScaleFactor 	
	DFREF 	dfr = P_DeviceSpecificPressureDFRef(panelTitle)
	Make/N=1/D/O dfr:ADC/WAVE=ADV
	string 	ITCCommand
	sprintf 	ITCCommand, "ITCSelectDevice %d" ITCDeviceIDGlobal	
	execute 	ITCCommand	
	
	sprintf 	ITCCommand, "ITCReadADC/C=1 %d, %s" ADC, GetWavesDataFolder(ADV, 2)
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

	variable 	ITCDeviceIDGlobal 	= PressureDataWv[headStage][%DAC_DevID] // ITC device used for pressure control
	variable 	Channel 				= PressureDataWv[headStage][%TTL]
	variable 	rack 				= 0
	
	If(Channel >= 4) // channel is on rack 1 of two racks (rack 0 and rack 1).
		rack = 3 // rack 1 TTLs front = 3 in the ITC XOP
		Channel -=4 // channels on each rack are numbered 0 through 3
	endif 	
	
	string 	ITCCommand
	sprintf 	ITCCommand, "ITCSelectDevice %d" ITCDeviceIDGlobal
	execute 	ITCCommand
	
	Wave 	DIO = P_DIO(panelTitle)
	sprintf 	ITCCommand, "ITCReadDigital %d, %s" Rack, GetWavesDataFolder(DIO, 2)
	execute 	ITCCommand	
	
	string 	BinaryList = P_DecToBinary(DIO[0])

	// check if desired channel is already in correct state
	variable 	channelStatus = str2num(StringFromList(Channel, BinaryList))

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

/// @brief Updates resistance slope and the resistance in PressureDataWv from TPStorageWave
/// param 
Function P_UpdateSSRSlopeAndSSR(panelTitle)
	string 	panelTitle

	wave 	TPStorageWave 		= GetTPStorage(panelTitle)
	wave 	PressureDataWv 	= P_GetPressureDataWaveRef(panelTitle)
	DFREF 	dfr 				= $HSU_DataFullFolderPathString(panelTitle)
	/// @todo Make wave reference function for ITCChanConfigWave
	Wave/SDFR = dfr  ITCChanConfigWave
	string 	ADChannelList = SCOPE_RefToPullDatafrom2DWave(0, 0, 1, ITCChanConfigWave)
	variable TPCycleCount = GetNumberFromWaveNote(TPStorageWave, TP_CYLCE_COUNT_KEY) // used to pull most recent resistance value from TP storage wave
	variable Row
	// pull data from TPStorageWave, apply it to headStage using TP_HeadstageUsingADC(panelTitle, AD)
	variable ColumnsInTPStorageWave = DimSize(TPStorageWave, 1)
	if(ColumnsInTPStorageWave == 0)
		ColumnsInTPStorageWave = 1
	endif
	
	variable ADC
	variable i
	for(i = 0; i < ColumnsInTPStorageWave; i += 1)
		ADC = str2num(StringFromList(i, ADChannelList))
		Row = TP_HeadstageUsingADC(panelTitle, ADC)
		ASSERT(TPCycleCount > 0, "Expecting a strictly positive TPCycleCount") 
		PressureDataWv[Row][%PeakR] = TPStorageWave[TPCycleCount - 1 ][i][1] // update the peak resistance value
		PressureDataWv[Row][%LastResistanceValue] = TPStorageWave[TPCycleCount - 1 ][i][2]	// update the steady state resistance value
		PressureDataWv[Row][%PeakResistanceSlope] = TPStorageWave[0][i][5] 	// Layer 5 of the TP storage wave contains the slope of the steady state resistance values of the TP
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
	PressureDataWv[headStageNo][%DAC_List_Index] 	= GetPopupMenuIndex	(panelTitle, "popup_Settings_Pressure_ITCdev")
	PressureDataWv[headStageNo][%DAC_Type] 		= str2num(DeviceNum)
//	PressureDataWv[headStageNo][3] STORES THE DEVICE ID WHICH IS DETERMINED WHEN THE DEVICE IS OPENED
	PressureDataWv[headStageNo][%DAC] 			= GetPopupMenuIndex	(panelTitle, "Popup_Settings_Pressure_DA")
	PressureDataWv[headStageNo][%DAC_Gain] 		= GetSetVariable			(panelTitle, "setvar_Settings_Pressure_DAgain")
	PressureDataWv[headStageNo][%ADC] 			= GetPopupMenuIndex	(panelTitle, "Popup_Settings_Pressure_AD")
	PressureDataWv[headStageNo][%ADC_Gain]  		= GetSetVariable			(panelTitle, "setvar_Settings_Pressure_ADgain")
	PressureDataWv[headStageNo][%TTL]  				= GetPopupMenuIndex	(panelTitle, "Popup_Settings_Pressure_TTL")
	PressureDataWv[][%PSI_air]   						= GetSetVariable			(panelTitle, "setvar_Settings_InAirP")
	PressureDataWv[][%PSI_solution] 					= GetSetVariable			(panelTitle, "setvar_Settings_InBathP")
	PressureDataWv[][%PSI_slice] 					= GetSetVariable			(panelTitle, "setvar_Settings_InSliceP")
	PressureDataWv[][%PSI_nearCell] 					= GetSetVariable			(panelTitle, "setvar_Settings_NearCellP")
	PressureDataWv[][%PSI_SealInitial] 				= GetSetVariable			(panelTitle, "setvar_Settings_SealStartP")
	PressureDataWv[][%PSI_SealMax] 				= GetSetVariable			(panelTitle, "setvar_Settings_SealMaxP")
	PressureDataWv[][%solutionZaxis] 					= GetSetVariable			(panelTitle, "setvar_Settings_SurfaceHeight")
	PressureDataWv[][%sliceZaxis] 					= GetSetVariable			(panelTitle, "setvar_Settings_SliceSurfHeight")
	PressureDataWv[][%ManSSPressure]				= GetSetVariable			(panelTitle, "setvar_DataAcq_SSPressure")
	PressureDataWv[][%ManPPPressure]				= GetSetVariable			(panelTitle, "setvar_DataAcq_PPPressure")
	PressureDataWv[][%ManPPDuration]				= GetSetVariable			(panelTitle, "setvar_DataAcq_PPDuration")
	
	WAVE/T PressureDataTxtWv = P_PressureDataTxtWaveRef(panelTitle)
	
	PressureDataTxtWv[headStageNo][%ITC_Device] = SelectedITCDevice
	PressureDataTxtWv[headStageNo][%DA_Unit] = GetSetVariableString(panelTitle, "SetVar_Hardware_Pressur_DA_Unit")
	PressureDataTxtWv[headStageNo][%AD_Unit] = GetSetVariableString(panelTitle, "SetVar_Hardware_Pressur_AD_Unit")
	
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
	
	SetPopupMenuIndex(panelTitle, control, PressureDataWv[headStageNo][%DAC_List_Index])
	
	if(isFinite(PressureDataWv[headStageNo][%DAC_List_Index])) // only compare saved and selected device if a device was saved
		string 	SavedITCdev = PressureDataTxtWv[headStageNo][0]
		string 	PopUpMenuString = GetPopupMenuString(panelTitle, control)
		if(PressureDataWv[headStageNo][%DAC_List_Index] != 1) // compare saved and selected device to verify that they match. Non match could occur if data was saved prior to a popup menu update and ITC hardware change.
			if(cmpstr(SavedITCdev, PopUpMenuString) != 0)
				print "Saved ITC device for headStage", headStageNo, "is no longer at same list position."
				print "Verify the selected ITC device for headStage.", headStageNo
			endif
		endif
	endif
End

/// @brief Sends a negative pressure pulse to the pressure regulator. Gates the TTLs apropriately to maintain the exisiting TTL state while opening the TTL on the channel with the pressure pulse
Function P_NegPressurePulse(panelTitle, headStage)
	string 	panelTitle
	variable	headStage

	P_DAforNegPpulse(panelTitle, Headstage) 	// update DA data
	P_ADforPpulse(panelTitle, Headstage) 	// update AD data
	P_TTLforPpulse(panelTitle, Headstage) 	// update TTL data
	P_ITCDataAcq(panelTitle, headStage)
End

/// @brief Initiates a positive pressure pulse to the pressure regulator. Gates the TTLs apropriately to maintain the exisiting TTL state while opening the TTL on the channel with the pressure pulse
Function P_PosPressurePulse(panelTitle, headStage)
	string 	panelTitle
	variable	headStage

	P_DAforPosPpulse(panelTitle, Headstage) 	// update DA data
	P_ADforPpulse(panelTitle, Headstage) 	// update AD data
	P_TTLforPpulse(panelTitle, Headstage) 	// update TTL data
	P_ITCDataAcq(panelTitle, headStage)
End

/// @brief Runs acquisition cycle on ITC devices for pressure control.
Function P_ITCDataAcq(panelTitle, headStage)
	string 	panelTitle
	variable	headstage
	Wave 	ITCData				= P_GetITCData(panelTitle)
	Wave 	ITCConfig			= P_GetITCChanConfig(panelTitle)
	Wave 	FIFOConfig			= P_GetITCFIFOConfig(panelTitle)
	Wave	FIFOAvail			= P_GetITCFIFOAvail(panelTitle)
	Wave 	pressureDataWv 		= P_GetPressureDataWaveRef(panelTitle)
	string	cmd
	
	// select the ITC device
	sprintf cmd, "ITCSelectDevice %d" pressureDataWv[headStage][%DAC_DevID]
	execute cmd
	
	// ensure device has stopped acquisition
	execute "ITCStopAcq"

	// configure all channels
	sprintf cmd, "ITCconfigAllchannels, %s, %s" GetWavesDataFolder(ITCConfig, 2), GetWavesDataFolder(ITCData, 2)
	execute cmd
	
	// reset the FIFO
	sprintf cmd, "ITCUpdateFIFOPositionAll, %s" GetWavesDataFolder(FIFOConfig, 2)
	execute cmd
	
	// record onset of data acquisition
	pressureDataWv[][%OngoingPessurePulse]				= 0 // ensure that only one headstage is recorded as having an ongoing pressure pulse
	pressureDataWv[headStage][%OngoingPessurePulse] 	= 1 // record headstage with ongoing pressure pulse
	// start data acquisition
	execute "ITCStartAcq"
	
	// Start FIFO monitor
	CtrlNamedBackground P_FIFOMonitor, period = 12, proc = P_FIFOMonitorProc
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
	
	sprintf cmd, "ITCFIFOAvailableALL /z = 0 , %s" GetWavesDataFolder(FIFOAvail, 2)
	Execute cmd
	
	if(FIFOAvail[1][2] > 300 / SAMPLE_INT_MILLI)
		execute "ITCStopAcq"
		pressureDataWv[][%OngoingPessurePulse]	= 0
		CtrlNamedBackground P_FIFOMonitor, stop
		print "Pressure pulse is complete"
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
	for(i = 0; i < ItemsInList(ListOfLockedDevices); i += 1)
		panelTitle = StringFromList(i, ListOfLockedDevices)
		Wave 	pressureDataWv 		= P_GetPressureDataWaveRef(panelTitle)
		for(headStage = 0; headstage < NUM_HEADSTAGES; headStage += 1)
			if(pressureDataWv[headStage][%OngoingPessurePulse])
				DevID = pressureDataWv[headStage][%DAC_DevID]
				return 1
			endif
		endfor
	endfor
	
	return 0
End

/// @brief Updates the DA data used for ITC controlled pressure devices for a negative pressure pulse
Function P_DAforNegPpulse(panelTitle, Headstage)
	string 	panelTitle
	variable 	Headstage
	Wave 	ITCData				= P_GetITCData(panelTitle)
	Wave 	ITCConfig			= P_GetITCChanConfig(panelTitle)
	Wave 	FIFOConfig			= P_GetITCFIFOConfig(panelTitle)
	Wave	FIFOAvail			= P_GetITCFIFOAvail(panelTitle)	
	Wave 	pressureDataWv 		= P_GetPressureDataWaveRef(panelTitle)
	variable 	lastPressureCom		= pressureDataWv[Headstage][%LastPressureCommand]
	variable 	DAGain				= pressureDataWv[Headstage][%DAC_Gain]
	variable 	PressureCom
	
	if(lastPressureCom > MIN_NEG_PRESSURE_PULSE)
		PressureCom = lastPressureCom - NEG_PRESSURE_PULSE_INCREMENT + MIN_NEG_PRESSURE_PULSE
	else
		PressureCom = lastPressureCom - NEG_PRESSURE_PULSE_INCREMENT
	endif
	
	if((PressureCom) > -10)
		ITCData[][%DA] = (PRESSURE_OFFSET * BITS_PER_VOLT)
		ITCData[PRESSURE_PULSE_STARTpt, PRESSURE_PULSE_ENDpt][%DA] 	= (PressureCom / DAGain + PRESSURE_OFFSET) * BITS_PER_VOLT
		ITCConfig	[%DA][%Chan_num] 	= pressureDataWv[headStage][%DAC] // set the DAC channel for the headstage
		FIFOConfig	[%DA][%Chan_num] 	= pressureDataWv[headStage][%DAC]
		FIFOAvail	[%DA][%Chan_num]	= pressureDataWv[headStage][%DAC]
	
		pressureDataWv[Headstage][%LastPressureCommand] =  (PressureCom)
		print "pulse amp",(PressureCom)
	else
		ITCData[][%DA] = (PRESSURE_OFFSET * BITS_PER_VOLT)
		ITCData[PRESSURE_PULSE_STARTpt, PRESSURE_PULSE_ENDpt][%DA] 	= (-2 / DAGain + PRESSURE_OFFSET) * BITS_PER_VOLT
		
		pressureDataWv[Headstage][%LastPressureCommand] =  - 2
		print "pulse amp", -2
	endif
End

/// @brief Updates the DA data used for ITC controlled pressure devices for a positive pressure pulse
Function P_DAforPosPpulse(panelTitle, Headstage)
	string 	panelTitle
	variable 	Headstage
	Wave 	ITCData				= P_GetITCData(panelTitle)
	Wave 	ITCConfig			= P_GetITCChanConfig(panelTitle)
	Wave 	FIFOConfig			= P_GetITCFIFOConfig(panelTitle)
	Wave	FIFOAvail			= P_GetITCFIFOAvail(panelTitle)	
	Wave 	pressureDataWv 		= P_GetPressureDataWaveRef(panelTitle)
	variable 	lastPressureCom		= pressureDataWv[Headstage][%LastPressureCommand]
	variable 	DAGain				= pressureDataWv[Headstage][%DAC_Gain]
	variable 	PressureCom

	PressureCom = lastPressureCom + POS_PRESSURE_PULSE_INCREMENT
	
	if((PressureCom) < 10 && PressureCom > 0)
		ITCData[][%DA] = (PRESSURE_OFFSET * BITS_PER_VOLT)
		ITCData[PRESSURE_PULSE_STARTpt, PRESSURE_PULSE_ENDpt][%DA] 	= ((((PressureCom) / DAGain) + PRESSURE_OFFSET) * BITS_PER_VOLT)
		ITCConfig	[%DA][%Chan_num] 											= pressureDataWv[headStage][%DAC] // set the DAC channel for the headstage
		FIFOConfig	[%DA][%Chan_num] 											= pressureDataWv[headStage][%DAC]
		FIFOAvail	[%DA][%Chan_num]											= pressureDataWv[headStage][%DAC]
	
		pressureDataWv[Headstage][%LastPressureCommand] =  (PressureCom)
		print "pulse amp",(PressureCom)
	else
		ITCData[][%DA] = (PRESSURE_OFFSET * BITS_PER_VOLT)
		ITCData[PRESSURE_PULSE_STARTpt, PRESSURE_PULSE_ENDpt][%DA] 	= (0.1 / DAGain + PRESSURE_OFFSET) * BITS_PER_VOLT
		
		pressureDataWv[Headstage][%LastPressureCommand] =  0.1
		print "pulse amp", 0.1
	endif
End

/// @brief Updates the DA data used for ITC controlled pressure devices for a manual pressure pulse
Function P_DAforManPpulse(panelTitle, Headstage)
	string 	panelTitle
	variable 	Headstage
	Wave 	ITCData				= P_GetITCData(panelTitle)
	Wave 	ITCConfig			= P_GetITCChanConfig(panelTitle)
	Wave 	FIFOConfig			= P_GetITCFIFOConfig(panelTitle)
	Wave	FIFOAvail			= P_GetITCFIFOAvail(panelTitle)	
	Wave 	pressureDataWv 		= P_GetPressureDataWaveRef(panelTitle)
	variable 	lastPressureCom		= pressureDataWv[Headstage][%LastPressureCommand]
	variable 	DAGain				= pressureDataWv[Headstage][%DAC_Gain]
	variable 	PressureCom		= pressureDataWv[headStage][%ManPPPressure]
	variable 	PPEndPoint			= PRESSURE_PULSE_STARTpt + (pressureDataWv[headStage][%ManPPDuration] / 0.005)

	if((PressureCom) < 10 && PressureCom > -10)
		ITCData[][%DA] = (PRESSURE_OFFSET * BITS_PER_VOLT)
		ITCData[PRESSURE_PULSE_STARTpt, PPEndPoint][%DA] 	= (PressureCom / DAGain + PRESSURE_OFFSET) * BITS_PER_VOLT
		ITCConfig	[%DA][%Chan_num] 											= pressureDataWv[headStage][%DAC] // set the DAC channel for the headstage
		FIFOConfig	[%DA][%Chan_num] 											= pressureDataWv[headStage][%DAC]
		FIFOAvail	[%DA][%Chan_num]											= pressureDataWv[headStage][%DAC]
	
		pressureDataWv[Headstage][%LastPressureCommand] =  (PressureCom)
		print "pulse amp",(PressureCom)
	else
		print "pressure command is out of range"
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
	
	sprintf ITCcom, "ITCReadDigital %d, %s" RACK_ZERO, GetWavesDataFolder(DIO, 2) // get rack zero TTL state
	execute ITCcom	
	
	Rack0state = DIO[0]

	sprintf ITCcom, "ITCReadDigital %d, %s" RACK_ONE, GetWavesDataFolder(DIO, 2) // get rack one TTL state
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
	variable 	channelStatus = str2num(StringFromList(TTL, BinaryList))
	
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
	variable SavedPressureMode = PressureDataWv[headStageNo][%Approach_Seal_BrkIn_Clear]
	
	if(P_ValidatePressureSetHeadstage(panelTitle, headStageNo)) // check if headStage pressure settings are valid
		P_EnableButtonsIfValid(panelTitle, headStageNo)
		
		if(pressureMode == SavedPressureMode) // The saved pressure mode and the pressure mode being passed are equal therefore toggle the same button
			SetControlTitle(panelTitle, pressureControlName, StringFromList(pressureMode, PRESSURE_CONTROL_TITLE_LIST))
			SetControlTitleColor(panelTitle, pressureControlName, 0, 0, 0)
			PressureDataWv[headStageNo][%Approach_Seal_BrkIn_Clear] = P_METHOD_neg1_ATM
		else // saved and new pressure mode don't match
			if(SavedPressureMode != P_METHOD_neg1_ATM) // saved pressure mode isn't pressure OFF (-1) 
				// reset the button for the saved pressure mode
				SetControlTitle(panelTitle, StringFromList(SavedPressureMode, PRESSURE_CONTROLS_BUTTON_LIST), StringFromList(SavedPressureMode, PRESSURE_CONTROL_TITLE_LIST))
				SetControlTitleColor(panelTitle, StringFromList(SavedPressureMode, PRESSURE_CONTROLS_BUTTON_LIST), 0, 0, 0)
			endif
			
			if(PressureMode == P_METHOD_0_APPROACH) // On approach, apply the mode			
				SetControlTitle(panelTitle, pressureControlName, ("Stop " + StringFromList(pressureMode, PRESSURE_CONTROL_TITLE_LIST)))
				SetControlTitleColor(panelTitle, pressureControlName, 39168, 0, 0)
				PressureDataWv[headStageNo][%Approach_Seal_BrkIn_Clear] = pressureMode
			elseif(PressureMode)
				if(P_IsTPActive(panelTitle) && P_IsHSActiveAndInVClamp(panelTitle, headStageNo)) // check to see if TP is running and the headStage is in V-clampmode
					SetControlTitle(panelTitle, pressureControlName, ("Stop " + StringFromList(pressureMode, PRESSURE_CONTROL_TITLE_LIST)))
					SetControlTitleColor(panelTitle, pressureControlName, 39168, 0, 0)
					PressureDataWv[headStageNo][%Approach_Seal_BrkIn_Clear] = pressureMode
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
		if(getCheckboxState(panelTitle, StringFromList(savedPressureMode, PRESSURE_CONTROL_CHECKBOX_LIST)))
			PressureDataWv[][%Approach_Seal_BrkIn_Clear] = P_METHOD_neg1_ATM
		endif
	else	
		if(getCheckboxState(panelTitle, StringFromList(pressureMode, PRESSURE_CONTROL_CHECKBOX_LIST)))
			for(headStage = 0; headStage < NUM_HEADSTAGES; headStage += 1)
				if(P_ValidatePressureSetHeadstage(panelTitle, headStage))
					if(pressureMode && P_IsTPActive(panelTitle) && P_IsHSActiveAndInVClamp(panelTitle, headStage))
						PressureDataWv[headStage][%Approach_Seal_BrkIn_Clear] = pressureMode
					else
						PressureDataWv[headStage][%Approach_Seal_BrkIn_Clear] = pressureMode // pressure mode = 0
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
		
		P_EnableButtonsIfValid(panelTitle, headStageNo)
		variable SavedPressureMode = PressureDataWv[headStageNo][%Approach_Seal_BrkIn_Clear]
		
		if(SavedPressureMode != P_METHOD_neg1_ATM) // there is an active pressure mode
			if(SavedPressureMode == P_METHOD_0_APPROACH) // On approach, apply the mode
				SetControlTitle(panelTitle, StringFromList(SavedPressureMode, PRESSURE_CONTROLS_BUTTON_LIST), ("Stop " + StringFromList(SavedPressureMode, PRESSURE_CONTROL_TITLE_LIST)))
				SetControlTitleColor(panelTitle, StringFromList(SavedPressureMode, PRESSURE_CONTROLS_BUTTON_LIST), 39168, 0, 0)
			elseif(SavedPressureMode) // other pressure modes
				if(P_IsTPActive(panelTitle) && P_IsHSActiveAndInVClamp(panelTitle, headStageNo)) // check to see if TP is running and the headStage is in V-clampmode
					SetControlTitle(panelTitle, StringFromList(SavedPressureMode, PRESSURE_CONTROLS_BUTTON_LIST), ("Stop " + StringFromList(SavedPressureMode, PRESSURE_CONTROL_TITLE_LIST)))
					SetControlTitleColor(panelTitle, StringFromList(SavedPressureMode, PRESSURE_CONTROLS_BUTTON_LIST), 39168, 0, 0)
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
Function P_EnableButtonsIfValid(panelTitle, headStageNo)
	string panelTitle
	variable headStageNo
	string PRESSURE_CONTROLS_BUTTON_subset = RemoveListItem(0, PRESSURE_CONTROLS_BUTTON_LIST)
	
	if(P_IsTPActive(panelTitle) && P_IsHSActiveAndInVClamp(panelTitle, headStageNo))
		if(getCheckBoxState(panelTitle, StringFromList(P_METHOD_3_CLEAR, PRESSURE_CONTROL_CHECKBOX_LIST)))
			EnableListOfControls(panelTitle, PRESSURE_CONTROLS_BUTTON_LIST)
		else
			DisableListOfControls(panelTitle, PRESSURE_CONTROLS_BUTTON_subset)
			EnableControl(panelTitle, StringFromList(0, PRESSURE_CONTROLS_BUTTON_LIST)) // approach button
			EnableControl(panelTitle, StringFromList(1, PRESSURE_CONTROLS_BUTTON_LIST))
			EnableControl(panelTitle, StringFromList(2, PRESSURE_CONTROLS_BUTTON_LIST))
			EnableControl(panelTitle, StringFromList(4, PRESSURE_CONTROLS_BUTTON_LIST))
			EnableControl(panelTitle, StringFromList(5, PRESSURE_CONTROLS_BUTTON_LIST))
		endif
	else
		DisableListOfControls(panelTitle, PRESSURE_CONTROLS_BUTTON_subset)
		EnableControl(panelTitle, StringFromList(0, PRESSURE_CONTROLS_BUTTON_LIST)) // approach button
		EnableControl(panelTitle, StringFromList(4, PRESSURE_CONTROLS_BUTTON_LIST))
		EnableControl(panelTitle, StringFromList(5, PRESSURE_CONTROLS_BUTTON_LIST))
	endif
End

/// @brief Checks if all the pressure settings for a headStage are valid
///
/// @returns 1 if all settings are valid, 0 otherwise
Function P_ValidatePressureSetHeadstage(panelTitle, headStageNo)
	string panelTitle
	variable headStageNo
	WAVE PressureDataWv = P_GetPressureDataWaveRef(panelTitle)
	WAVE/T PressureDataTxtWv = P_PressureDataTxtWaveRef(panelTitle)
	string msg
	
	if(!isFinite(PressureDataWv[headStageNo][%DAC_Type]))
		sprintf msg, "DAC Type is not configured for headStage %d"  headStageNo
		DEBUGPRINT(msg)
		return 0
	endif
	
	if(!isFinite(PressureDataWv[headStageNo][%DAC_DevID]))
		sprintf msg, "DAC device ID is not configured for headstage %d"  headStageNo
		DEBUGPRINT(msg)		
		return 0
	endif

	if(!isFinite(PressureDataWv[headStageNo][%DAC_Gain]))
		sprintf msg, "DAC gain is not configured for headstage %d"  headStageNo
		DEBUGPRINT(msg)		
		return 0
	endif	
	
	if(!isFinite(PressureDataWv[headStageNo][%ADC_Gain]))
		sprintf msg, "ADC Type is not configured for headstage %d"  headStageNo
		DEBUGPRINT(msg)		
		return 0
	endif
	
	if(!isFinite(PressureDataWv[headStageNo][%PSI_air]))
		sprintf msg, "Approach pressure in air is not configured for headstage %d"  headStageNo
		DEBUGPRINT(msg)		
		return 0
	endif
	
	if(!isFinite(PressureDataWv[headStageNo][%PSI_solution]))
		sprintf msg, "Approach pressure in solution is not configured for headstage %d"  headStageNo
		DEBUGPRINT(msg)		
		return 0
	endif
	
	if(!isFinite(PressureDataWv[headStageNo][%PSI_slice]))
		sprintf msg, "Approach pressure in slice is not configured for headstage %d"  headStageNo
		DEBUGPRINT(msg)		
		return 0
	endif
	
	if(!isFinite(PressureDataWv[headStageNo][%PSI_nearCell]))
		sprintf msg, "Approach pressure in slice is not configured for headstage %d"  headStageNo
		DEBUGPRINT(msg)		
		return 0
	endif
	
	if(!isFinite(PressureDataWv[HeadStageNo][%PSI_SealInitial]))
		sprintf msg, "Initial seal pressure is not configured for headstage %d"  headStageNo
		DEBUGPRINT(msg)		
		return 0
	endif
	
	if(!isFinite(PressureDataWv[headStageNo][%PSI_SealMax]))
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
	
	sprintf cmd, "ITCGetState/R=1 %s" GetWavesDataFolder(StateWave, 2)
	execute cmd
	
	return StateWave[0] != 0
End

/// @brief Determines if bacground TP is active
///
/// Accounts for different acquistion modes (different background functions are used for different TP acquisition modes)
Function P_IsTPActive(panelTitle)
	string panelTitle
	
	if(GetCheckBoxState(panelTitle, "check_Settings_MD"))
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
		SetControlTitle(panelTitle, StringFromList(i, PRESSURE_CONTROLS_BUTTON_LIST), StringFromList(i, PRESSURE_CONTROL_TITLE_LIST))
		SetControlTitleColor(panelTitle, StringFromList(i, PRESSURE_CONTROLS_BUTTON_LIST), 0, 0, 0)
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
	variable j
	string LockedDevice
	for(i = 0; i < ItemsInList(ListOfLockedDA_Ephys); i += 1)
		LockedDevice = StringFromList(i, ListOfLockedDA_Ephys)
		if(ItemsInList(P_ITCDevToOpen())) // check to ensure there are ITC devices assigned by the user for pressure regulation
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
	for(i = 0; i < ItemsInList(ListOfLockedDA_Ephys); i += 1)
		LockedDevice = StringFromList(i, ListOfLockedDA_Ephys)
		if(ItemsInList(P_ITCDevToOpen())) // check to ensure there are ITC devices assigned by the user for pressure regulation
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

	variable i

	for(i = 0; i < 4; i += 1)
		bit = mod(Dec,2)
		dec /= 2
		dec = floor(dec)
		binary = AddListItem(num2str(bit), binary,";", inf)
	endfor
	
	return binary
End
//============================================================================================================
// MANUAL PRESSURE CONTROL 
//============================================================================================================
/// @brief Sets the pressure on the active headstage or all headstages.
Function P_ManSetPressure(panelTitle)
	string panelTitle
	variable headStage = GetSliderPositionIndex(panelTitle, "slider_DataAcq_ActiveHeadstage")
	WAVE PressureDataWv = P_GetPressureDataWaveRef(panelTitle)
	variable psi = PressureDataWv[0][%ManSSPressure]
	variable ONorOFF = 1
	 
	PressureDataWv[headStage][%Approach_Seal_BrkIn_Clear] = P_METHOD_4_MANUAL
	
	if(psi == 0)
		ONorOFF = 0
		PressureDataWv[headStage][%Approach_Seal_BrkIn_Clear] = P_METHOD_neg1_ATM
	endif

	if(GetCheckBoxState(panelTitle, "check_DataAcq_ManPressureAll"))
		for(headStage = 0; headStage < NUM_HEADSTAGES; headStage += 1)
			P_SetPressure(panelTitle, headStage, psi)
			P_UpdateTTLstate(panelTitle, headStage, ONorOFF) 
			SetValDisplaySingleVariable(panelTitle, StringFromList(headstage,PRESSURE_CONTROL_PRESSURE_DISP) , psi, format = "%2.2f") // update the pressure display
			PressureDataWv[headStage][%LastPressureCommand] = psi // save the pressure command
		endfor
	else
		P_SetPressure(panelTitle, headStage, psi)
		P_UpdateTTLstate(panelTitle, headStage, ONorOFF) 
		SetValDisplaySingleVariable(panelTitle, StringFromList(headstage,PRESSURE_CONTROL_PRESSURE_DISP) , psi, format = "%2.2f") // update the pressure display
		PressureDataWv[headStage][%LastPressureCommand] = psi // save the pressure command
	endif
End

/// @brief Initiates a pressure pulse who's settings are are controlled in the manual tab of the pressure regulation controls
Function P_ManPressurePulse(panelTitle, headStage)
	string panelTitle
	variable headStage
	
	P_DAforManPpulse(panelTitle, Headstage)
	P_ADforPpulse(panelTitle, Headstage) 	// update AD data
	P_TTLforPpulse(panelTitle, Headstage) 	// update TTL data
	P_ITCDataAcq(panelTitle, headStage)
End
//============================================================================================================
// PRESSURE CONTROLS; DA_ePHYS PANEL; DATA ACQUISTION TAB
//============================================================================================================
/// @brief Approach button.
Function ButtonProc_Approach(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch(ba.eventCode)
		case 2: // mouse up
			variable PressureMode = 0
			P_UpdatePressureMode(ba.win, PressureMode, ba.ctrlName, 1)
			if(!P_IsTPActive(ba.win)) // P_PressureControl will be called from TP functions when the TP is running
				P_PressureControl(ba.win)
			endif
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

/// @brief Seal button.
Function ButtonProc_Seal(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch(ba.eventCode)
		case 2: // mouse up
			variable PressureMode = 1
			P_UpdatePressureMode(ba.win, PressureMode, ba.ctrlName, 1)
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

/// @brief Break in button.
Function ButtonProc_BreakIn(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch(ba.eventCode)
		case 2: // mouse up
			variable PressureMode = 2
			P_UpdatePressureMode(ba.win, PressureMode, ba.ctrlName, 1)
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

/// @brief Clear button.
Function ButtonProc_Clear(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch(ba.eventCode)
		case 2: // mouse up
			variable PressureMode = 3
			P_UpdatePressureMode(ba.win, PressureMode, ba.ctrlName, 0)
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

/// @brief Clear all check box.
Function CheckProc_ClearEnable(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	switch(cba.eventCode)
		case 2: // mouse up
			Variable checked = cba.checked
			if(checked)
				if(P_IsTPActive(cba.win) && P_IsHSActiveAndInVClamp(cba.win, GetSliderPositionIndex(cba.win, "slider_DataAcq_ActiveHeadstage")))
					EnableControl(cba.win, "button_DataAcq_Clear")
				endif
			else
				DisableControl(cba.win, "button_DataAcq_Clear")
			endif
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

/// @brief Update DAC list button.
Function ButtonProc_Hrdwr_P_UpdtDAClist(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch(ba.eventCode)
		case 2: // mouse up
			string DeviceList = "- none -;" + HSU_ListDevices()
			SetPopupMenuVal(ba.win, "popup_Settings_Pressure_ITCdev", DeviceList)
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

/// @brief Pressure control ITC device Enable button in Hardware tab of DA_Ephys panel
Function P_ButtonProc_Enable(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch(ba.eventCode)
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

	switch(ba.eventCode)
		case 2: // mouse up
			P_Disable()		
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

/// @brief Set pressure button.
Function ButtonProc_DataAcq_ManPressSet(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch(ba.eventCode)
		case 2: // mouse up
			P_ManSetPressure(ba.win)
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

/// @brief Manual pressure pulse button.
Function ButtonProc_ManPP(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch(ba.eventCode)
		case 2: // mouse up
			variable headStage = GetSliderPositionIndex(ba.win, "slider_DataAcq_ActiveHeadstage")
			P_ManPressurePulse(ba.win, headStage)
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End
