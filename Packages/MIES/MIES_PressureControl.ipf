#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_P
#endif

/// @file MIES_PressureControl.ipf
/// @brief __P__ Supports use of analog pressure regulators controlled via a
/// ITC device for automated pressure control during approach, seal, break in,
/// and clearing of pipette.
///
/// @todo TPbackground can crash while operating pressure regulators if called
/// in the middle of a TP. Need to call P_Pressure control from TP functions
/// that occur between TPs to prevent this from happening

/// @name Constants used by pressure control
/// @anchor PRESSURE_CONSTANTS
/// @{
static StrConstant  PRESSURE_CONTROLS_BUTTON_LIST   = "button_DataAcq_Approach;button_DataAcq_Seal;button_DataAcq_BreakIn;button_DataAcq_Clear;button_DataAcq_SSSetPressureMan"
static StrConstant  PRESSURE_CONTROL_TITLE_LIST     = "Approach;Seal;Break In;Clear;Apply"
static StrConstant  PRESSURE_CONTROL_CHECKBOX_LIST  = "check_DatAcq_ApproachAll;check_DatAcq_SealAll;check_DatAcq_BreakInAll;check_DatAcq_ClearEnable;check_DataAcq_ManPressureAll"
static StrConstant  PRESSURE_CONTROL_PRESSURE_DISP  = "valdisp_DataAcq_P_0;valdisp_DataAcq_P_1;valdisp_DataAcq_P_2;valdisp_DataAcq_P_3;valdisp_DataAcq_P_4;valdisp_DataAcq_P_5;valdisp_DataAcq_P_6;valdisp_DataAcq_P_7"
static StrConstant  PRESSURE_CONTROL_LED_DASHBOARD  = "valdisp_DataAcq_P_LED_0;valdisp_DataAcq_P_LED_1;valdisp_DataAcq_P_LED_2;valdisp_DataAcq_P_LED_3;valdisp_DataAcq_P_LED_4;valdisp_DataAcq_P_LED_5;valdisp_DataAcq_P_LED_6;valdisp_DataAcq_P_LED_7"
static StrConstant  PRESSURE_CONTROL_LED_MODE_USER  = "valdisp_DataAcq_P_LED_Approach;valdisp_DataAcq_P_LED_Seal;valdisp_DataAcq_P_LED_BreakIn;valdisp_DataAcq_P_LED_Clear"
static StrConstant  PRESSURE_CONTROL_USER_CHECBOXES = "check_Settings_UserP_Approach;check_Settings_UserP_Seal;check_Settings_UserP_BreakIn;check_Settings_UserP_Clear"
static StrConstant  LOW_COLOR_HILITE                = "0;0;0"
static StrConstant  ZERO_COLOR_HILITE               = "0;0;65535"
static StrConstant  HIGH_COLOR_HILITE               = "65278;0;0"
static StrConstant  LOW_COLOR                       = "65535;65535;65535"
static StrConstant  ZERO_COLOR                      = "49151;53155;65535"
static StrConstant  HIGH_COLOR                      = "65535;49000;49000"
static Constant     NEG_PRESSURE_PULSE_INCREMENT    = 0.2 // psi
static Constant     POS_PRESSURE_PULSE_INCREMENT    = 0.1 // psi
static Constant     PRESSURE_PULSE_ENDpt            = 70000
static Constant     PRESSURE_TTL_HIGH_START         = 20000
static Constant     GIGA_SEAL                       = 1000
static Constant     PRESSURE_OFFSET                 = 5
static Constant     MIN_NEG_PRESSURE_PULSE          = -2
static Constant     MAX_POS_PRESSURE_PULSE          = 0.1
static Constant     ATMOSPHERIC_PRESSURE            = 0
static Constant     PRESSURE_CHANGE                 = 1
static Constant     P_NEGATIVE_PULSE                = 0x0
static Constant     P_POSITIVE_PULSE                = 0x1
static Constant     P_MANUAL_PULSE                  = 0x2
static Constant     SEAL_POTENTIAL                  = -70 // mV
static Constant     SEAL_RESISTANCE_THRESHOLD       = 100 // Mohm
static Constant     ACCESS_ATM                      = 0 // Access constants are used to set TTL valve configuration
static Constant     ACCESS_REGULATOR                = 1
static Constant     ACCESS_USER                     = 2
/// @}

/// @brief Filled by P_GetPressureForDA()
static Structure P_PressureDA
   variable calPressure, calPressureOffset ///< preconditioned for the DAC hardware
   variable pressure ///< [psi]
   variable first, last
EndStructure

/// @brief Applies pressure methods based on data in PressureDataWv
///
/// This function gets called by TP_RecordTP. It also gets called when the approach button is pushed.
/// A key point is that data acquisition used to run pressure pulses cannot be active if the TP is inactive.
Function P_PressureControl(panelTitle)
	string panelTitle

	variable headStage, manPressureAll
	WAVE PressureDataWv = P_GetPressureDataWaveRef(panelTitle)

	manPressureAll = DAG_GetNumericalValue(panelTitle, "check_DataAcq_ManPressureAll")

	for(headStage = 0; headStage < NUM_HEADSTAGES; headStage += 1)
		// are headstage settings valid AND is the ITC device inactive (avoids ITC commands while pressure pulse is ongoing)
		if(P_ValidatePressureSetHeadstage(panelTitle, headStage) && !P_DACIsCollectingData(panelTitle, headStage))
			switch(PressureDataWv[headStage][%Approach_Seal_BrkIn_Clear])
				case PRESSURE_METHOD_ATM:
					P_MethodAtmospheric(panelTitle, headstage)
					break
				case PRESSURE_METHOD_APPROACH:
					P_MethodApproach(panelTitle, headStage)
					break
				case PRESSURE_METHOD_SEAL:
					if(P_PressureMethodPossible(panelTitle, headStage))
						P_MethodSeal(panelTitle, headStage)
					endif
					break
				case PRESSURE_METHOD_BREAKIN:
					if(P_PressureMethodPossible(panelTitle, headStage))
						P_MethodBreakIn(panelTitle, headStage)
					endif
					break
				case PRESSURE_METHOD_CLEAR:
					if(P_PressureMethodPossible(panelTitle, headStage))
						 P_MethodClear(panelTitle, headStage)
					endif
					break
				case PRESSURE_METHOD_MANUAL:
					P_ManSetPressure(panelTitle, headStage, manPressureAll)
					break
				default:
					PressureDataWv[headStage][%Approach_Seal_BrkIn_Clear] = PRESSURE_METHOD_ATM
					P_MethodAtmospheric(panelTitle, headstage)
					break
			endswitch
		endif

		P_UpdateTPStorage(panelTitle, headStage)
	endfor

	P_RecordUserPressure(panelTitle)
End

static Function P_RecordUserPressure(panelTitle)
	string panelTitle

	string device
	variable ADC, i, deviceID, hwType

	WAVE TPStorage = GetTPStorage(panelTitle)
	variable count = GetNumberFromWaveNote(TPStorage, NOTE_INDEX)

	WAVE pressureType = GetPressureTypeWv(panelTitle)
	WAVE pressureDataWv = P_GetPressureDataWaveRef(panelTitle)

	TPStorage[count][][%UserPressureType] = pressureType[q]

	for(i = 0; i < NUM_HEADSTAGES; i += 1)
		if(pressureType[i] != PRESSURE_TYPE_USER)
			continue
		endif

		hwType   = pressureDataWv[i][%UserPressureDeviceHWType]
		deviceID = pressureDataWv[i][%UserPressureDeviceID]
		ADC      = pressureDataWv[i][%UserPressureDeviceADC]

		if(IsNaN(hwType) || IsNaN(deviceID) || IsNaN(ADC))
			continue
		endif

		TPStorage[count][i][%UserPressure]             = HW_ReadADC(hwType, deviceID, ADC)
		TPStorage[count][i][%UserPressureTimeStampUTC] = DateTimeInUTC()
	endfor
End

/// @brief Record pressure in TPStorage wave
static Function P_UpdateTPStorage(panelTitle, headStage)
	string panelTitle
	variable headstage

	WAVE PressureDataWv = P_GetPressureDataWaveRef(panelTitle)
	WAVE TPStorage      = GetTPStorage(panelTitle)
	variable count      = GetNumberFromWaveNote(TPStorage, NOTE_INDEX)

	if(!P_ValidatePressureSetHeadstage(panelTitle, headStage) || !P_IsHSActiveAndInVClamp(panelTitle, headStage))
		return NaN
	endif

	TPStorage[count][headstage][%Pressure] = PressureDataWv[headStage][%RealTimePressure][0]

	if(count == 0) // don' record pressure change for first entry
		return NaN
	endif

	TPStorage[count][headstage][%PressureChange] = (TPStorage[count - 1][headstage][%Pressure] == PressureDataWv[headStage][%RealTimePressure][0] ? NaN : PRESSURE_CHANGE)

	TPStorage[count][headstage][%PressureMethod] = PressureDataWv[headStage][%Approach_Seal_BrkIn_Clear]
End

/// @brief Sets the pressure to atmospheric
static Function P_MethodAtmospheric(panelTitle, headstage)
	string panelTitle
	variable headStage

	WAVE PressureDataWv = P_GetPressureDataWaveRef(panelTitle)
	P_SetPressureValves(panelTitle, headStage, P_GetUserAccess(panelTitle, headStage, PRESSURE_METHOD_ATM))
	PressureDataWv[headStage][%LastPressureCommand] = P_SetAndGetPressure(panelTitle, headStage, ATMOSPHERIC_PRESSURE)
	PressureDataWv[headStage][%RealTimePressure]    = PressureDataWv[headStage][%LastPressureCommand]
End

/// @brief Applies approach pressures
static Function P_MethodApproach(panelTitle, headStage)
	string panelTitle
	variable headStage

	WAVE 	PressureDataWv = P_GetPressureDataWaveRef(panelTitle)
	WAVE 	AmpStoragewave = GetAmplifierParamStorageWave(panelTitle)
	variable targetP = PressureDataWv[headStage][%PSI_solution] // Approach pressure is stored in row 10 (Solution approach pressure). Once manipulators are part of MIES, other approach pressures will be incorporated
	PressureDataWv[headStage][%TimeOfLastRSlopeCheck] = nan
	P_SetPressureValves(panelTitle, headStage, P_GetUserAccess(panelTitle, headStage, PRESSURE_METHOD_APPROACH))
	// if Near cell checkbox is checked then all headstages, except the active headstage, go to in slice pressure. The active headstage goes to nearCell pressure
	if(PressureDataWv[headStage][%ApproachNear] && headStage != PressureDataWv[headStage][%UserSelectedHeadStage])
		targetP = PressureDataWv[headStage][%PSI_slice]
	endif

	if(IsFinite(PressureDataWv[headstage][%UserPressureOffsetTotal]))
		targetP += PressureDataWv[headstage][%UserPressureOffsetTotal]
	endif

	if(targetP != PressureDataWv[headStage][%LastPressureCommand]) // only update pressure if the pressure is incorrect
		PressureDataWv[headStage][%LastPressureCommand] = P_SetAndGetPressure(panelTitle, headStage, targetP)
		PressureDataWv[headStage][%RealTimePressure] = PressureDataWv[headStage][%LastPressureCommand]
		// Turn off holding
		AI_UpdateAmpModel(panelTitle, "check_DatAcq_HoldEnableVC", headStage, value=0)
	else // Zero amps after pressure on headstage has been set
		// If Near checkbox is checked, then zero amplifiers on approach that require zeroing
		if(PressureDataWv[headStage][%ApproachNear])
			AI_ZeroAmps(panelTitle, headstage = headStage)
		endif
	endif
End

/// @brief Applies seal methods
static Function P_MethodSeal(panelTitle, headStage)
	string panelTitle
	variable headStage

	WAVE 	PressureDataWv 			= P_GetPressureDataWaveRef(panelTitle)
	variable RSlope
	variable RSlopeThreshold 			= 4 // with a slope of 8 Mohm/s it will take two minutes for a seal to form.
	variable lastRSlopeCheck 		= PressureDataWv[headStage][%TimeOfLastRSlopeCheck] / 60
	variable timeInSec 				= ticks / 60
	variable ElapsedTimeInSeconds 	= timeInSec - LastRSlopeCheck
	variable access

	if(!lastRSlopeCheck || !IsFinite(lastRSlopeCheck) || !ElapsedTimeInSeconds) // checks for first time thru.
		ElapsedTimeInSeconds = 0
		PressureDataWv[headStage][%TimeOfLastRSlopeCheck] = ticks
	endif

	P_UpdateSSRSlopeAndSSR(panelTitle) // update the resistance values used to assess seal changes
	variable resistance = PressureDataWv[headStage][%LastResistanceValue]
	variable pressure = PressureDataWv[headStage][%LastPressureCommand]
	variable targetPressure
	// if the seal resistance is greater that 1 giga ohm set pressure to atmospheric AND stop sealing process
	if(Resistance >= GIGA_SEAL)
		P_MethodAtmospheric(panelTitle, headstage) // set to atmospheric pressure
 		if(PressureDataWv[headStage][%UserSelectedHeadStage] == headstage && !GetTabID(panelTitle, "tab_DataAcq_Pressure")) // only update buttons if selected headstage matches headstage with seal
 			P_UpdatePressureMode(panelTitle, 1, StringFromList(1,PRESSURE_CONTROLS_BUTTON_LIST), 0)
 		else
			PressureDataWv[headStage][%Approach_Seal_BrkIn_Clear] = PRESSURE_METHOD_ATM // remove the seal mode
			P_ResetPressureData(panelTitle, headStageNo = headstage)
		endif

		PressureDataWv[headStage][%TimeOfLastRSlopeCheck] 	= 0 // reset the time of last slope R check

		// apply holding potential of SEAL_POTENTIAL
		P_UpdateVcom(panelTitle, SEAL_POTENTIAL, headStage)
		print "Seal on head stage:", headstage
	else // no seal, start, hold, or increment negative pressure
		// if there is no neg pressure, apply starting pressure.
		access = P_GetUserAccess(panelTitle, headStage, PRESSURE_METHOD_SEAL)
		P_SetPressureValves(panelTitle, headStage, access)
		if(access != ACCESS_USER)
			if(PressureDataWv[headStage][%LastPressureCommand] > PressureDataWv[headStage][%PSI_SealInitial])
				if(PressureDataWv[headStage][%SealAtm])
					targetPressure = ATMOSPHERIC_PRESSURE
					P_MethodAtmospheric(panelTitle, headstage)
				else
					targetPressure = PressureDataWv[headStage][%PSI_SealInitial]
					PressureDataWv[headStage][%LastPressureCommand] = P_SetAndGetPressure(panelTitle, headStage, targetPressure) // column 26 is the last pressure command, column 13 is the starting seal pressure
					pressure = targetPressure
					PressureDataWv[headStage][%LastPressureCommand] = targetPressure
					PressureDataWv[headStage][%RealTimePressure] = targetPressure
					P_SetPressureValves(panelTitle, headStage, P_GetUserAccess(panelTitle, headStage, PRESSURE_METHOD_SEAL))
					print "starting seal"
				endif
			endif
			// if the seal slope has plateau'd or is going down, increase the negative pressure
			// print ElapsedTimeInSeconds

			if(ElapsedTimeInSeconds > 20) // Allows 10 seconds to elapse before pressure would be changed again. The R slope is over the last 5 seconds.
				RSlope = PressureDataWv[headStage][%SSResistanceSlope]
				print "slope:", rslope, "thres:", RSlopeThreshold
				if(RSlope < RSlopeThreshold) // if the resistance is not going up quickly enough increase the negative pressure
					if(pressure > (0.98 *PressureDataWv[headStage][%PSI_SealMax])) // is the pressure beign applied less than the maximum allowed?
						print "resistance is not going up fast enough"
						print "updated seal pressure =", pressure - 0.1

						if(PressureDataWv[headStage][%LastPressureCommand] == 0)
							targetPressure = PressureDataWv[headStage][%PSI_SealInitial]
						else
							targetPressure = pressure - 0.1
						endif
						PressureDataWv[headStage][%LastPressureCommand] = P_SetAndGetPressure(panelTitle, headStage, targetPressure) // increase the negative pressure by 0.1 psi
						PressureDataWv[headStage][%RealTimePressure] = PressureDataWv[headStage][%LastPressureCommand]
					else // max neg pressure has been reached and resistance has stabilized
						print "pressure is at max neg value"
						// disrupt plateau
					endif
				endif
				PressureDataWv[headStage][%TimeOfLastRSlopeCheck] = ticks
			endif
		endif
		P_ApplyNegV(panelTitle, headStage) // apply negative voltage
	endif
End

/// @brief Applies break-in method
static Function P_MethodBreakIn(panelTitle, headStage)
	string panelTitle
	variable headStage

	WAVE 	PressureDataWv 			= P_GetPressureDataWaveRef(panelTitle)
	variable lastRSlopeCheck 		= PressureDataWv[headStage][%TimeOfLastRSlopeCheck] / 60
	variable timeInSec 				= ticks / 60
	variable ElapsedTimeInSeconds 	= timeInSec - LastRSlopeCheck

	if(!lastRSlopeCheck || !IsFinite(lastRSlopeCheck)) // checks for first time thru.
		P_MethodAtmospheric(panelTitle, headstage)
		ElapsedTimeInSeconds = 0
		if(P_GetUserAccess(panelTitle, headStage, PRESSURE_METHOD_BREAKIN) == ACCESS_USER)
			P_SetPressureValves(panelTitle, headStage,ACCESS_USER)
		else
			P_NegPressurePulse(panelTitle, headStage)
		endif
		PressureDataWv[headStage][%TimeOfLastRSlopeCheck] = ticks
	endif

	P_UpdateSSRSlopeAndSSR(panelTitle) // update the resistance values used to assess seal changes
	variable resistance = PressureDataWv[headStage][%LastResistanceValue]

	// if the seal resistance is less that 1 giga ohm set pressure to atmospheric AND break in process
	if(Resistance <= GIGA_SEAL)
		P_MethodAtmospheric(panelTitle, headstage) // set to atmospheric pressure

		if(PressureDataWv[headStage][%UserSelectedHeadStage] == headstage && !GetTabID(panelTitle, "tab_DataAcq_Pressure")) // only update buttons if selected headstage matches headstage with seal
 			P_UpdatePressureMode(panelTitle, 2, StringFromList(2,PRESSURE_CONTROLS_BUTTON_LIST), 0) // sets break-in button back to base state and sets to atmospheric
 		else
			PressureDataWv[headStage][%Approach_Seal_BrkIn_Clear] 	= PRESSURE_METHOD_ATM // remove the seal mode
			P_ResetPressureData(panelTitle, headStageNo = headStage)
		endif

		PressureDataWv[headStage][%TimeOfLastRSlopeCheck] 		= 0 // reset the time of last slope R check
		PressureDataWv[headStage][%LastPressureCommand]		= 0
		print "Break in on head stage:", headstage,"of", panelTitle
	else // still need to break - in
		PressureDataWv[headStage][%RealTimePressure] 		= 0

		if(P_GetUserAccess(panelTitle, headStage, PRESSURE_METHOD_BREAKIN) == ACCESS_USER)
			P_SetPressureValves(panelTitle, headStage, ACCESS_USER)
		elseif(ElapsedTimeInSeconds > 5)
			print "applying negative pressure pulse!"
			P_SetPressureValves(panelTitle, headStage, ACCESS_ATM)
			P_NegPressurePulse(panelTitle, headStage)
			PressureDataWv[headStage][%TimeOfLastRSlopeCheck] = ticks
		endif
	endif
End

/// @brief Applies pipette clearing method
static Function P_MethodClear(panelTitle, headStage)
	string panelTitle
	variable headStage

	WAVE 	PressureDataWv 			= P_GetPressureDataWaveRef(panelTitle)
	variable lastRpeakCheck 			= PressureDataWv[headStage][%TimePeakRcheck] / 60
	variable timeInSec 				= ticks / 60
	variable ElapsedTimeInSeconds 	= timeInSec - lastRpeakCheck

	P_UpdateSSRSlopeAndSSR(panelTitle)

	if(!lastRpeakCheck || !IsFinite(lastRpeakCheck)) // checks for first time thru.
		ElapsedTimeInSeconds = 0
		PressureDataWv[headStage][%TimePeakRcheck] = ticks
		PressureDataWv[headStage][%LastPeakR] = PressureDataWv[headStage][%PeakR] // sets the last peak R = to the current peak R
	endif

	if(PressureDataWv[headStage][%peakR] > (0.9 * PressureDataWv[headStage][%LastPeakR]))
		PressureDataWv[headStage][%RealTimePressure] = 0
		if(P_GetUserAccess(panelTitle, headStage, PRESSURE_METHOD_CLEAR) == ACCESS_USER)
			P_SetPressureValves(panelTitle, headStage, ACCESS_USER)
		elseif(ElapsedTimeInSeconds > 2.5)
			print "applying positive pressure pulse!"
		 	P_PosPressurePulse(panelTitle, headStage)
		 	PressureDataWv[headStage][%TimePeakRcheck] = ticks
		 	PressureDataWv[headStage][%LastPeakR] = PressureDataWv[headStage][%PeakR]
		endif
	else
		P_MethodAtmospheric(panelTitle, headstage) // set to atmospheric pressure
		if(PressureDataWv[headStage][%UserSelectedHeadStage] == headstage && !GetTabID(panelTitle, "tab_DataAcq_Pressure")) // only update buttons if selected headstage matches headstage with seal
			P_UpdatePressureMode(panelTitle, 3, StringFromList(3,PRESSURE_CONTROLS_BUTTON_LIST), 0) // sets break-in button back to base state
		else
			PressureDataWv[headStage][%Approach_Seal_BrkIn_Clear] 	= PRESSURE_METHOD_ATM // remove the seal mode
			P_ResetPressureData(panelTitle, headStageNo = headStage)
		endif
		PressureDataWv[headStage][%TimePeakRcheck]			= 0 // reset the time of last slope R check
		PressureDataWv[headStage][%LastPressureCommand]		= 0
	endif

End

/// @brief Applies updates the command voltage to the #SEAL_POTENTIAL when #SEAL_RESISTANCE_THRESHOLD is crossed
static Function P_ApplyNegV(panelTitle, headStage)
	string panelTitle
	variable headStage

	WAVE 	PressureDataWv 	= P_GetPressureDataWaveRef(panelTitle)
	variable resistance 		=  PressureDataWv[headStage][%LastResistanceValue]
	variable vCom 			= SEAL_POTENTIAL
	variable	lastVcom = PressureDataWv[headStage][%LastVcom]

	if(DAG_GetNumericalValue(panelTitle, "Check_DataAcq_SendToAllAmp")) // ensure that vCom is being updated on headstage associated amplifier (not all amplifiers).
		PGC_SetAndActivateControl(panelTitle, "Check_DataAcq_SendToAllAmp",val = CHECKBOX_UNSELECTED)
	endif

	if(lastVCom != vCom && resistance >= SEAL_RESISTANCE_THRESHOLD)
		printf "headstage=%d, vCom=%g\r", headstage, vcom
		P_UpdateVcom(panelTitle, vCom, headStage)
		PressureDataWv[headStage][%LastVcom] = vCom
	endif
End

/// @brief Updates the command voltage
static Function P_UpdateVcom(panelTitle, vCom, headStage)
	string panelTitle
	variable vCom
	variable headStage

	// apply holding
	AI_UpdateAmpModel(panelTitle, "setvar_DataAcq_Hold_VC", headStage, value=vCom)

	// make sure holding is enabled
	AI_UpdateAmpModel(panelTitle, "check_DatAcq_HoldEnableVC", headStage, value=1)
End

/// @brief Determines which ITC devices to close. Ensures all DA_Ephys panels
/// using a particular ITC device for pressure regulation are updated
/// correctly.
static Function P_CloseDevice(panelTitle)
	string panelTitle

	string ListOfITCDevToClose = P_GetListOfPressureCtrlDevices(panelTitle)
	string ListOfLockedDA_Ephys = GetListOfLockedDevices()
	string DeviceToClose
	string ListOfHeadstagesUsingITCDev
	variable headStage
	variable i, j

	for(i = 0; i < ItemsInList(ListOfITCDevToClose); i += 1) // for all the ITC devices used for pressure regulation
		// find device ID
		do
			panelTitle = StringFromList(j, ListOfLockedDA_Ephys)
			DeviceToClose = StringFromList(i,ListOfITCDevToClose)

			ListOfHeadstagesUsingITCDev = P_HeadstageUsingDevice(panelTitle, DeviceToClose)
			j += 1
		while(cmpstr("", ListOfHeadstagesUsingITCDev) == 0)
		j = 0
		headStage = str2num(StringFromList(0, ListOfHeadstagesUsingITCDev))
		P_CloseDeviceLowLevel(panelTitle, DeviceToClose, headstage)
	endfor
End

/// @brief Open device used for pressure regulation.
static Function P_OpenDevice(mainDevice, pressureDevice)
	string mainDevice, pressureDevice

	variable hwType
	variable headStage, i, j, numEntries, deviceID
	string ListOfLockedDA_Ephys = GetListOfLockedDevices()
	string listOfHeadstageUsingDevice = ""

	deviceID = HW_OpenDevice(pressureDevice, hwType, flags=HARDWARE_ABORT_ON_ERROR)
	HW_RegisterDevice(mainDevice, hwType, deviceID, pressureDevice=pressureDevice)

	if(hwType == HARDWARE_ITC_DAC)
		P_PrepareITCWaves(mainDevice, pressureDevice)
	endif

	printf "Device used for pressure regulation: %s (%s)\r", pressureDevice, StringFromList(hwType, HARDWARE_DAC_TYPES)

	// update pressure data wave with locked device info
	for(j = 0; j < ItemsInList(ListOfLockedDA_Ephys); j += 1)
		mainDevice = StringFromList(j, ListOfLockedDA_Ephys)
		listOfHeadstageUsingDevice = P_HeadstageUsingDevice(mainDevice, pressureDevice)
		numEntries = ItemsInList(listOfHeadstageUsingDevice)
		for(i = 0; i < numEntries; i += 1)
			headStage = str2num(StringFromList(i, ListOfHeadstageUsingDevice))
			WAVE PressureDataWv = P_GetPressureDataWaveRef(mainDevice)
			PressureDataWv[headStage][%DAC_DevID]   = deviceID
			PressureDataWv[headStage][%HW_DAC_Type] = hwType

			WAVE/T PressureDataTxtWv = P_PressureDataTxtWaveRef(mainDevice)
			PressureDataTxtWv[headStage][%Device] = pressureDevice

			HW_WriteDAC(hwType, deviceID, PressureDataWv[headStage][%DAC], PRESSURE_OFFSET)
		endfor
	endfor
End

/// @brief Adapt the ITC DAQ waves for hardware specialities
static Function P_PrepareITCWaves(mainDevice, pressureDevice)
	string mainDevice, pressureDevice

	variable ret
	string deviceType, deviceNumber

	ret = ParseDeviceString(pressureDevice, deviceType, deviceNumber)
	ASSERT(ret, "Could not parse device string")

	WAVE ITCData    = P_GetITCData(mainDevice)
	WAVE ITCConfig  = P_GetITCChanConfig(mainDevice)

	if(!cmpstr(deviceType, "ITC1600")) // two racks
		Redimension/N=(-1, 4) ITCData
		Redimension/N=(4, -1) ITCConfig

		SetDimLabel COLS, 3, TTL_R1, ITCData
		SetDimLabel ROWS, 3, TTL_R1, ITCConfig

		ITCConfig[3][0]  = ITC_XOP_CHANNEL_TYPE_TTL

		ITCConfig[3][1]  = HW_ITC_GetITCXOPChannelForRack(pressureDevice, RACK_ONE)
	else // one rack
		Redimension/N=(-1, 3) ITCData
		Redimension/N=(3, -1) ITCConfig
	endif

	ITCConfig[2][1]  = HW_ITC_GetITCXOPChannelForRack(pressureDevice, RACK_ZERO)
End

/// @brief Used to close the device used for pressure regulation
static Function P_CloseDeviceLowLevel(panelTitle, deviceToClose, refHeadstage)
	string panelTitle, deviceToClose
	variable refHeadstage

	variable headStage, deviceID, hwType
	variable i, j, doDeRegister
	string ListOfHeadstageUsingITCDevice = ""
	string ListOfLockedDA_Ephys = GetListOfLockedDevices()

	WAVE PressureDataWv = P_GetPressureDataWaveRef(panelTitle)
	deviceID = PressureDataWv[refHeadstage][%DAC_DevID]
	hwType   = pressureDataWv[refHeadstage][%HW_DAC_Type]

	if(IsFinite(deviceID) && IsFinite(hwType) && !HW_SelectDevice(hwType, deviceID, flags=HARDWARE_PREVENT_ERROR_POPUP | HARDWARE_PREVENT_ERROR_MESSAGE))
		HW_ResetDevice(hwType, deviceID)
		doDeRegister = 1
	endif

	for(j = 0; j < ItemsInList(ListOfLockedDA_Ephys); j += 1)
		panelTitle = StringFromList(j, ListOfLockedDA_Ephys)
		ListOfHeadstageUsingITCDevice = P_HeadstageUsingDevice(panelTitle, deviceToClose)
		for(i = 0; i < ItemsInList(ListOfHeadstageUsingITCDevice); i += 1)
			if(cmpstr("",ListOfHeadstageUsingITCDevice) != 0)
				headStage = str2num(StringFromList(i, ListOfHeadstageUsingITCDevice))
				deviceID = PressureDataWv[headstage][%DAC_DevID]
				hwType   = pressureDataWv[headstage][%HW_DAC_Type]

				if(IsFinite(deviceID) && IsFinite(hwType) && !HW_SelectDevice(hwType, deviceID, flags=HARDWARE_PREVENT_ERROR_POPUP | HARDWARE_PREVENT_ERROR_MESSAGE))
					P_SetAndGetPressure(panelTitle, headstage, 0)
				endif

				WAVE PressureDataWv = P_GetPressureDataWaveRef(panelTitle)
				PressureDataWv[headStage][%DAC_DevID]   = NaN
				PressureDataWv[headstage][%HW_DAC_Type] = NaN
			endif
		endfor
	endfor

	if(doDeRegister)
		HW_CloseDevice(hwType, deviceID)
		HW_DeRegisterDevice(hwType, deviceID)
	endif
End

/// @brief Returns a list of rows that contain a particular string
static Function/S P_HeadstageUsingDevice(panelTitle, device)
	string panelTitle
	string device

	variable i
	string list = ""
	WAVE/T PressureDataTxtWv = P_PressureDataTxtWaveRef(panelTitle)

	for(i = 0; i < NUM_HEADSTAGES; i += 1)
		if(cmpstr(device, PressureDataTxtWv[i][0]) == 0)
			list = AddListItem(num2str(i), list)
		endif
	endfor

	return list
End

/// @brief Returns a list of ITC/NI devices to open
///
/// Pulls a non repeating list of ITC/NI devices to open from the device
/// specific pressure data wave.
static Function/S P_GetListOfPressureCtrlDevices(panelTitle)
	string panelTitle

	string deviceList = ""
	string device
	variable i

	WAVE/T pressureDataTxtWave = P_PressureDataTxtWaveRef(panelTitle)

	for(i = 0; i < NUM_HEADSTAGES; i += 1)
		device = pressureDataTxtWave[i][0]
		if(!isEmpty(device) && cmpstr(device,NONE) != 0)
			if(WhichListItem(device, deviceList) == -1)
				deviceList = AddListItem(device, deviceList)
			endif
		endif
	endfor

	// sort the list so that the devices are opened in the correct sequence
	// (low deviceID to high deviceID)
	return SortList(deviceList)
End

/// @brief Sets the pressure on a headStage
Function P_SetAndGetPressure(panelTitle, headStage, psi)
	string panelTitle
	variable headStage, psi

	variable hwType, deviceID, channel, scale, CalPsi
	string msg

	WAVE pressureDataWv = P_GetPressureDataWaveRef(panelTitle)
	hwType   = pressureDataWv[headStage][%HW_DAC_Type]
	deviceID = pressureDataWv[headStage][%DAC_DevID]
	channel  = pressureDataWv[headStage][%DAC]
	scale    = pressureDataWv[headStage][%DAC_Gain]
	// psi offset: 0V = -10 psi, 5V = 0 psi, 10V = 10 psi
	SetValDisplay(panelTitle, StringFromList(headstage,PRESSURE_CONTROL_PRESSURE_DISP), var=psi, format = "%2.2f")
	if(psi && isFinite(PressureDataWv[headStage][%PosCalConst]))
		CalPsi = PressureDataWv[headStage][%PosCalConst] + psi
	elseif(isFinite(PressureDataWv[headStage][%NegCalConst]))
		CalPsi = PressureDataWv[headStage][%NegCalConst] + psi 
	endif

	sprintf msg, "panelTitle=%s, hwtype=%d, deviceID=%d, channel=%d, headstage=%d, psi=%g\r", panelTitle, hwType, deviceID, channel, headStage, CalPsi
	DEBUGPRINT(msg)

	HW_WriteDAC(hwType, deviceID, channel, CalPsi / scale + PRESSURE_OFFSET)

	return psi
End

/// @brief Returns pressure access defined in @ref PRESSURE_CONSTANTS of the headstage
///
/// @param panelTitle The DAQ device for which user access is being queried
/// @param headStage MIES headstage number, must be in the range [0, NUM_HEADSTAGES]
/// @param pressureMode One of the pressure modes defined in @ref PRESSURE_CONSTANTS
Function P_GetUserAccess(panelTitle, headStage, pressureMode)
	string panelTitle
	variable headStage
	variable pressureMode

	WAVE GuiState = GetDA_EphysGuiStateNum(panelTitle)
	WAVE pressureDataWv = P_GetPressureDataWaveRef(panelTitle)

	if(PressureDataWv[0][%UserSelectedHeadStage] == headStage) // does the slider selected headstage match the headstage being passed
		if(GuiState[0][%check_DataAcq_Pressure_User]) // if user access is checked
			return ACCESS_USER
		endif

		switch(pressureMode)
			case PRESSURE_METHOD_ATM:
				return ACCESS_ATM
				break
			case PRESSURE_METHOD_APPROACH:
				if(GuiState[0][%check_Settings_UserP_Approach])
					return ACCESS_USER
				else
					return ACCESS_REGULATOR
				endif
				break
			case PRESSURE_METHOD_SEAL:
				if(GuiState[0][%check_Settings_UserP_Seal])
					return ACCESS_USER
				else
					return ACCESS_REGULATOR
				endif
				break
			case PRESSURE_METHOD_BREAKIN:
				if(GuiState[0][%check_Settings_UserP_BreakIn])
					return ACCESS_USER
				else
					return ACCESS_ATM
				endif
				break
			case PRESSURE_METHOD_CLEAR:
				if(GuiState[0][%check_Settings_UserP_Clear])
					return ACCESS_USER
				else
					return ACCESS_ATM
				endif
				break
			case PRESSURE_METHOD_MANUAL:
					return ACCESS_REGULATOR
				break
			default:
				ASSERT(0, "Invalid pressure mode")
		endswitch
	else
		if(pressureDataWv[headStage][%Approach_Seal_BrkIn_Clear] == PRESSURE_METHOD_ATM)
			return ACCESS_ATM
		else
			return ACCESS_REGULATOR
		endif
	endif
End

/// @brief Maps the access (defined in @ref PRESSURE_CONSTANTS) to the TTL settings
 Function P_SetPressureValves(panelTitle, headStage, Access)
	string panelTitle
	variable headStage
	variable Access

	variable ONorOFFA, ONorOFFB
	WAVE pressureDataWv = P_GetPressureDataWaveRef(panelTitle)
	switch(Access)
		case ACCESS_ATM:
			ONorOFFA = 0
			ONorOFFB = 0
			break
		case ACCESS_REGULATOR:
			ONorOFFA = 1
			ONorOFFB = 0
			break
		case ACCESS_USER:
			ONorOFFA = 0
			ONorOFFB = 1
			break
		default:
			ASSERT(0, "Invalid case")
	endswitch

	// Set Access for headstage
	P_UpdateTTLstate(panelTitle, headStage, ONorOFFA, ONorOFFB)
End

/// @brief Updates the TTL channel associated with headStage while maintaining existing channel states
///
/// When setting TTLs, all channels are set at once. To keep existing TTL
/// state on some channels, active state must be known. This function queries
/// the hardware to determine the active state.
///
/// ITC hardware:
/// This requires the TTL out to be looped back to the TTL in on the ITC DAC.
///
/// NI hardware:
/// There are no dedicated input or output channels for DIO. The last written value
/// is read according to documentation.
Function P_UpdateTTLstate(panelTitle, headStage, ONorOFFA, ONorOFFB)
	string panelTitle
	variable headStage, ONorOFFA, ONorOFFB

	variable outputDecimal, val, idxA, idxB, channel
	variable hwType, deviceID, ttlBitA, ttlBitB
	string deviceName

	WAVE PressureDataWv = P_GetPressureDataWaveRef(panelTitle)
	// force value to 0/1
	ONorOFFA = !!ONorOFFA
	ONorOFFB = !!ONorOFFB
	hwType   = PressureDataWv[headStage][%HW_DAC_Type]
	deviceID = PressureDataWv[headStage][%DAC_DevID]
	ttlBitA  = PressureDataWv[headStage][%TTL_A]
	ttlBitB  = PressureDataWv[headStage][%TTL_B]
	deviceName = HW_GetDeviceName(hwType, deviceID)

	ASSERT(IsFinite(ttlBitA), "TTL A must be finite")

	if(hwType == HARDWARE_ITC_DAC)
		if(IsFinite(ttlBitB))
			ASSERT(HW_ITC_GetRackForTTLBit(panelTitle, ttlBitA) == HW_ITC_GetRackForTTLBit(panelTitle, ttlBitB), "Both TTLbits have to be on the same rack")
		endif

		// HW_ReadDigital/HW_WriteDigital internally uses
		// HW_ITC_GetRackForTTLBit so it does not matter which ttlBit we are
		// sending
		channel = ttlBitA

		val = HW_ReadDigital(hwType, deviceID, channel, flags=HARDWARE_ABORT_ON_ERROR)

		WAVE binary = P_DecToBinary(val)

		idxA = HW_ITC_ClipTTLBit(deviceName, ttlBitA)

		if(IsFinite(ttlBitB))
			idxB = HW_ITC_ClipTTLBit(deviceName, ttlBitB)
		endif

		// update tll associated with headStage only if the desired TTL channel
		// state is different from the actual/current channel state.

		if(ONorOFFA != binary[idxA] || (IsFinite(ttlBitB) && ONorOFFB != binary[idxB]))

			outputDecimal = val

			if(ONorOFFA)
				outputDecimal = SetBit(outputDecimal, 2^idxA)
			else
				outputDecimal = ClearBit(outputDecimal, 2^idxA)
			endif

			if(IsFinite(ttlBitB))
				if(ONorOFFB)
					outputDecimal = SetBit(outputDecimal, 2^idxB)
				else
					outputDecimal = ClearBit(outputDecimal, 2^idxB)
				endif
			endif

			HW_WriteDigital(hwType, deviceID, channel, outputDecimal, flags=HARDWARE_ABORT_ON_ERROR)
		endif

	elseif(hwType == HARDWARE_NI_DAC)

		channel = 0
		val = HW_ReadDigital(hwType, deviceID, channel, line=ttlBitA, flags=HARDWARE_ABORT_ON_ERROR)

		if(ONorOFFA != val)
			HW_WriteDigital(hwType, deviceID, channel, ONorOFFA, line=ttlBitA, flags=HARDWARE_ABORT_ON_ERROR)
		endif

		if(IsFinite(ttlBitB))
			val = HW_ReadDigital(hwType, deviceID, channel, line=ttlBitB, flags=HARDWARE_ABORT_ON_ERROR)

			if(ONorOFFB != val)
				HW_WriteDigital(hwType, deviceID, channel, ONorOFFB, line=ttlBitB, flags=HARDWARE_ABORT_ON_ERROR)
			endif
		endif
	endif
End

/// @brief Updates resistance slope and the resistance in PressureDataWv from TPStorageWave
/// param
static Function P_UpdateSSRSlopeAndSSR(panelTitle)
	string panelTitle

	variable lastValidEntry, i

	WAVE TPStorageWave  = GetTPStorage(panelTitle)
	WAVE PressureDataWv = P_GetPressureDataWaveRef(panelTitle)

	lastValidEntry = GetNumberFromWaveNote(TPStorageWave, NOTE_INDEX) - 1

	if(lastValidEntry < 0) // very first call without any TpStorage data
		return NaN
	endif

	for(i = 0; i < NUM_HEADSTAGES; i += 1)
		if(!TPStorageWave[lastValidEntry][i][%ValidState] || !IsFinite(TPStorageWave[lastValidEntry][i][%Headstage]))
			continue
		endif

		PressureDataWv[i][%PeakR]               = TPStorageWave[lastValidEntry][i][%PeakResistance]
		PressureDataWv[i][%LastResistanceValue] = TPStorageWave[lastValidEntry][i][%SteadyStateResistance]
		PressureDataWv[i][%SSResistanceSlope]   = TPStorageWave[0][i][%Rss_Slope]
	endfor
End

/// @brief Updates the pressure state (approach, seal, break in, or clear) from DA_Ephys panel to the pressureData wave
Function P_UpdatePressureDataStorageWv(panelTitle) /// @todo Needs to be reworked for specific controls and allow the value to be directly passed in with an optional parameter
	string panelTitle

	variable idx
	variable settingHS 	= GetPopupMenuIndex(panelTitle, "Popup_Settings_HeadStage") // get the active headstage
	WAVE PressureDataWv = P_GetPressureDataWaveRef(panelTitle)
	variable userHS = PressureDataWv[settingHS][%UserSelectedHeadStage]

	PressureDataWv[settingHS][%DAC_List_Index] = GetPopupMenuIndex(panelTitle, "popup_Settings_Pressure_dev")
	PressureDataWv[settingHS][%DAC]            = GetPopupMenuIndex(panelTitle, "Popup_Settings_Pressure_DA")
	PressureDataWv[settingHS][%DAC_Gain]       = GetSetVariable(panelTitle, "setvar_Settings_Pressure_DAgain")
	PressureDataWv[settingHS][%ADC]            = GetPopupMenuIndex(panelTitle, "Popup_Settings_Pressure_AD")
	PressureDataWv[settingHS][%ADC_Gain]       = GetSetVariable(panelTitle, "setvar_Settings_Pressure_ADgain")
	idx = GetPopupMenuIndex(panelTitle, "Popup_Settings_Pressure_TTLA")
	PressureDataWv[settingHS][%TTL_A]          = idx == 0 ? NaN : --idx
	idx = GetPopupMenuIndex(panelTitle, "Popup_Settings_Pressure_TTLB")
	PressureDataWv[settingHS][%TTL_B]          = idx == 0 ? NaN : --idx
	PressureDataWv[userHS][%ManSSPressure]     = DAG_GetNumericalValue(panelTitle, "setvar_DataAcq_SSPressure")
	PressureDataWv[][%PSI_air]                 = GetSetVariable(panelTitle, "setvar_Settings_InAirP")
	PressureDataWv[][%PSI_solution]            = GetSetVariable(panelTitle, "setvar_Settings_InBathP")
	PressureDataWv[][%PSI_slice]               = GetSetVariable(panelTitle, "setvar_Settings_InSliceP")
	PressureDataWv[][%PSI_nearCell]            = GetSetVariable(panelTitle, "setvar_Settings_NearCellP")
	PressureDataWv[][%PSI_SealInitial]         = GetSetVariable(panelTitle, "setvar_Settings_SealStartP")
	PressureDataWv[][%PSI_SealMax]             = GetSetVariable(panelTitle, "setvar_Settings_SealMaxP")
	PressureDataWv[][%solutionZaxis]           = GetSetVariable(panelTitle, "setvar_Settings_SurfaceHeight")
	PressureDataWv[][%sliceZaxis]              = GetSetVariable(panelTitle, "setvar_Settings_SliceSurfHeight")
	PressureDataWv[][%ManPPPressure]           = DAG_GetNumericalValue(panelTitle, "setvar_DataAcq_PPPressure")
	PressureDataWv[][%ManPPDuration]           = DAG_GetNumericalValue(panelTitle, "setvar_DataAcq_PPDuration")
	PressureDataWv[][%ApproachNear]            = DAG_GetNumericalValue(panelTitle, "check_DatAcq_ApproachNear")
	PressureDataWv[][%SealAtm]                 = DAG_GetNumericalValue(panelTitle, "check_DatAcq_SealAtm")

	WAVE/T PressureDataTxtWv = P_PressureDataTxtWaveRef(panelTitle)

	PressureDataTxtWv[settingHS][%Device]  = GetPopupMenuString(panelTitle, "popup_Settings_Pressure_dev")
	PressureDataTxtWv[settingHS][%DA_Unit] = GetSetVariableString(panelTitle, "SetVar_Hardware_Pressur_DA_Unit")
	PressureDataTxtWv[settingHS][%AD_Unit] = GetSetVariableString(panelTitle, "SetVar_Hardware_Pressur_AD_Unit")
End

/// @brief Retrieves the parameters stored in the PressureData wave and passes them to the GUI controls
// based on the headStage selected in the device associations of the Hardware tab on the DA_Ephys panel
Function P_UpdatePressureControls(panelTitle, headStageNo)
	string panelTitle
	variable headStageNo

	variable ttl
	WAVE PressureDataWv = P_GetPressureDataWaveRef(panelTitle)

	P_UpdatePopupITCdev(panelTitle, headStageNo)
	SetPopupMenuIndex(panelTitle, "Popup_Settings_Pressure_DA"     , PressureDataWv[headStageNo][%DAC])
	SetSetVariable(panelTitle   , "setvar_Settings_Pressure_DAgain", PressureDataWv[headStageNo][%DAC_Gain])
	SetPopupMenuIndex(panelTitle, "Popup_Settings_Pressure_AD"     , PressureDataWv[headStageNo][%ADC])
	SetSetVariable(panelTitle   , "setvar_Settings_Pressure_ADgain", PressureDataWv[headStageNo][%ADC_Gain])
	ttl = PressureDataWv[headStageNo][%TTL_A]
	SetPopupMenuIndex(panelTitle, "Popup_Settings_Pressure_TTLA"   , !IsFinite(ttl) ? 0 : ++ttl)
	ttl = PressureDataWv[headStageNo][%TTL_B]
	SetPopupMenuIndex(panelTitle, "Popup_Settings_Pressure_TTLB"   , !IsFinite(ttl) ? 0 : ++ttl)
	SetSetVariable(panelTitle   , "setvar_Settings_InAirP"         , PressureDataWv[headStageNo][%PSI_Air])
	SetSetVariable(panelTitle   , "setvar_Settings_InBathP"        , PressureDataWv[headStageNo][%PSI_Solution])
	SetSetVariable(panelTitle   , "setvar_Settings_InSliceP"       , PressureDataWv[headStageNo][%PSI_Slice])
	SetSetVariable(panelTitle   , "setvar_Settings_NearCellP"      , PressureDataWv[headStageNo][%PSI_NearCell])
	SetSetVariable(panelTitle   , "setvar_Settings_SealStartP"     , PressureDataWv[headStageNo][%PSI_SealInitial])
	SetSetVariable(panelTitle   , "setvar_Settings_SealMaxP"       , PressureDataWv[headStageNo][%PSI_SealMax])
	SetSetVariable(panelTitle   , "setvar_Settings_SurfaceHeight"  , PressureDataWv[headStageNo][%solutionZaxis])
	SetSetVariable(panelTitle   , "setvar_Settings_SliceSurfHeight", PressureDataWv[headStageNo][%sliceZaxis])

	WAVE/T PressureDataTxtWv = P_PressureDataTxtWaveRef(panelTitle)

	SetSetVariableString(panelTitle, "SetVar_Hardware_Pressur_DA_Unit", PressureDataTxtWv[headStageNo][%DA_Unit])
	SetSetVariableString(panelTitle, "SetVar_Hardware_Pressur_AD_Unit", PressureDataTxtWv[headStageNo][%AD_Unit])
End

/// @brief Updates the popupmenu popup_Settings_Pressure_dev
static Function P_UpdatePopupITCdev(panelTitle, headStageNo)
	string panelTitle
	variable headStageNo

	WAVE PressureDataWv 		= P_GetPressureDataWaveRef(panelTitle)
	WAVE/T PressureDataTxtWv 	= P_PressureDataTxtWaveRef(panelTitle)
	string control 				= "popup_Settings_Pressure_dev"

	SetPopupMenuIndex(panelTitle, control, PressureDataWv[headStageNo][%DAC_List_Index])

	// only compare saved and selected device if a device was saved
	if(isFinite(PressureDataWv[headStageNo][%DAC_List_Index]))
		string SavedITCdev = PressureDataTxtWv[headStageNo][0]
		// deliberately not using the GUI state wave
		string PopUpMenuString = GetPopupMenuString(panelTitle, control)

		// compare saved and selected device to verify that they match. Non
		// match could occur if data was saved prior to a popup menu update
		// and ITC hardware change.
		if(PressureDataWv[headStageNo][%DAC_List_Index] != 1)
			if(cmpstr(SavedITCdev, PopUpMenuString) != 0)
				print "Saved ITC device for headStage", headStageNo, "is no longer at same list position."
				print "Verify the selected ITC device for headStage.", headStageNo
			endif
		endif
	endif
End

/// @brief Initiates a pressure pulse who's settings are are controlled in the
/// manual tab of the pressure regulation controls
static Function P_ManPressurePulse(panelTitle, headStage)
	string panelTitle
	variable headStage

	P_ITC_SetChannels(panelTitle, headStage)
	P_DAforManPpulse(panelTitle, headstage)
	P_TTLforPpulse(panelTitle, headstage)
	P_DataAcq(panelTitle, headStage)
End

/// @brief Sends a negative pressure pulse to the pressure regulator. Gates the
/// TTLs apropriately to maintain the exisiting TTL state while opening the TTL
/// on the channel with the pressure pulse
static Function P_NegPressurePulse(panelTitle, headStage)
	string panelTitle
	variable headStage

	P_ITC_SetChannels(panelTitle, headstage)
	P_DAforNegPpulse(panelTitle, Headstage)
	P_TTLforPpulse(panelTitle, Headstage)
	P_DataAcq(panelTitle, headStage)
End

/// @brief Initiates a positive pressure pulse to the pressure regulator. Gates
/// the TTLs apropriately to maintain the exisiting TTL state while opening the
/// TTL on the channel with the pressure pulse
static Function P_PosPressurePulse(panelTitle, headStage)
	string panelTitle
	variable headStage

	P_ITC_SetChannels(panelTitle, headstage)
	P_DAforPosPpulse(panelTitle, headstage)
	P_TTLforPpulse(panelTitle, headstage)
	P_DataAcq(panelTitle, headStage)
End

static Function P_ITC_SetChannels(panelTitle, headstage)
	string panelTitle
	variable headstage

	WAVE ITCConfig      = P_GetITCChanConfig(panelTitle)
	WAVE pressureDataWv = P_GetPressureDataWaveRef(panelTitle)

	ITCConfig[%DA][%Chan_num]  = pressureDataWv[headStage][%DAC]
	ITCConfig[%AD][%Chan_num]  = pressureDataWv[headStage][%ADC]
End

/// @brief Check wether the given device is used as pressure device already
Function P_DeviceIsUsedForPressureCtrl(panelTitle, pressureDevice)
	string panelTitle, pressureDevice

	variable i, hwType, deviceID

	WAVE pressureDataWv = P_GetPressureDataWaveRef(panelTitle)

	for(i = 0; i < NUM_HEADSTAGES; i += 1)
		deviceID = pressureDataWv[i][%DAC_DevID]
		hwType   = pressureDataWv[i][%HW_DAC_Type]

		if(isFinite(deviceID) && isFinite(hwType))
			if(!cmpstr(HW_GetDeviceName(hwType, deviceID), pressureDevice))
				return 1
			endif
		endif
	endfor

	return 0
End

/// @brief Perform an acquisition cycle on the pressure device for pressure control
static Function P_DataAcq(panelTitle, headStage)
	string panelTitle
	variable headstage

	variable deviceID, hwType, TTL, DAC, ADC, startTime, elapsedTime, duration
	string str, pfi, device, endFunc

	Wave pressureDataWv = P_GetPressureDataWaveRef(panelTitle)

	deviceID = pressureDataWv[headStage][%DAC_DevID]
	hwType   = pressureDataWv[headStage][%HW_DAC_Type]
	TTL      = pressureDataWv[headStage][%TTL_A]
	DAC      = pressureDataWv[headStage][%DAC]
	ADC      = pressureDataWv[headStage][%ADC]

	HW_StopAcq(hwType, deviceID, flags=HARDWARE_ABORT_ON_ERROR)

	// record onset of data acquisition
	pressureDataWv[][%OngoingPessurePulse]          = 0 // ensure that only one headstage is recorded as having an ongoing pressure pulse
	pressureDataWv[headStage][%OngoingPessurePulse] = 1 // record headstage with ongoing pressure pulse

	if(hwType == HARDWARE_ITC_DAC)
		HW_ITC_PrepareAcq(deviceID, dataFunc=P_GetITCData, configFunc=P_GetITCChanConfig)
		HW_StartAcq(hwType, deviceID, flags=HARDWARE_ABORT_ON_ERROR)

		CtrlNamedBackground P_ITC_FIFOMonitor, start
	elseif(hwType == HARDWARE_NI_DAC)

#if exists("fDAQmx_DeviceNames")

		WAVE da = P_NI_GetDAWave(panelTitle, headStage)
		WAVE ad = P_NI_GetADWave(panelTitle, headStage)

		// set our triggering TTL channel P1.0 to low
		HW_WriteDigital(HARDWARE_NI_DAC, deviceID, 1, 0, line=0)

		// set the solenoid TTL channel to low
		HW_WriteDigital(HARDWARE_NI_DAC, deviceID, 0, 0, line=TTL)

		// @todo write proper wrappers once we finalized the functionality
		device = HW_GetDeviceName(hwType, deviceID)
		sprintf str, "%s, %d/Diff;", GetWavesDataFolder(ad, 2), ADC
		sprintf pfi, "/%s/pfi0", device
		sprintf endFunc, "P_NI_StopDAQ(\"%s\", %d)", panelTitle, headStage
		DAQmx_Scan/DEV=device/TRIG={pfi, 1, 1}/BKG/EOSH=endFunc WAVES=str
		sprintf str, "%s, %d/Diff;", GetWavesDataFolder(da, 2), DAC
		sprintf pfi, "/%s/pfi1", device
		DAQmx_WaveformGen/DEV=device/NPRD=1/TRIG={pfi, 1, 1} str

		// start acquisition by setting our special TTL port 1 line 0 high
		// this TTL line must be manually hardwired to the PFI0 and PFI1 lines.
		HW_WriteDigital(HARDWARE_NI_DAC, deviceID, 1, 1, line=0)

		// wait some time before opening the solenoid
		startTime = stopmstimer(-2)
		duration = PRESSURE_TTL_HIGH_START * WAVEBUILDER_MIN_SAMPINT * 1000
		do
			elapsedTime = stopmstimer(-2) - startTime
			if(elapsedTime >= duration)
				// set solenoid TTL to high
				HW_WriteDigital(HARDWARE_NI_DAC, deviceID, 0, 1, line=TTL)
				break
			endif
		while(1)
#else

	DoAbortNow("NI-DAQ XOP is not available")

#endif
	else
		ASSERT(0, "unknown hardware")
	endif
End

/// @brief Monitor the device FIFO and terminates acquisition when sufficient data has been collected
///
/// @ingroup BackgroundFunctions
Function P_ITC_FIFOMonitorProc(s)
	STRUCT WMBackgroundStruct &s

	string panelTitle
	variable hwType, moreData, deviceID, headstage

	if(!P_FindPanelTitleExecutingPP(panelTitle, deviceID, headStage))
		CtrlNamedBackground P_ITC_FIFOMonitor, stop
		print "No device can be found that is executing a pressure pulse"
		return 1
	endif

	Wave pressureDataWv = P_GetPressureDataWaveRef(panelTitle)
	hwType   = pressureDataWv[headStage][%HW_DAC_Type]
	deviceID = pressureDataWv[headStage][%DAC_DevID]

	moreData = HW_ITC_MoreData(deviceID, ADChannelToMonitor=1, stopCollectionPoint=350 / HARDWARE_ITC_MIN_SAMPINT, flags=HARDWARE_ABORT_ON_ERROR)

	if(!moreData)
		HW_StopAcq(hwType, deviceID)
		pressureDataWv[][%OngoingPessurePulse] = 0
		print "Pressure pulse is complete"
		return 1
	endif

	return 0
End

Function P_NI_StopDAQ(panelTitle, headStage)
	string panelTitle
	variable headStage

	variable hwType, deviceID, TTL

	WAVE pressureDataWv = P_GetPressureDataWaveRef(panelTitle)
	hwType   = pressureDataWv[headStage][%HW_DAC_Type]
	deviceID = pressureDataWv[headStage][%DAC_DevID]
	TTL      = pressureDataWv[headStage][%TTL_A]

	print "Stopping NI DAQ"

	// set the solenoid TTL channel to low
	HW_WriteDigital(hwType, deviceID, 0, 0, line=TTL)
End

/// @brief Returns the panelTitle of the ITC device associated with ITC device conducting a pressure pulse
static Function P_FindPanelTitleExecutingPP(panelTitle, deviceID, headStage)
	string &panelTitle
	variable &deviceID, &headStage

	string ListOfLockedDevices = GetListOfLockedDevices()
	variable i
	for(i = 0; i < ItemsInList(ListOfLockedDevices); i += 1)
		panelTitle = StringFromList(i, ListOfLockedDevices)
		Wave 	pressureDataWv 		= P_GetPressureDataWaveRef(panelTitle)
		for(headStage = 0; headstage < NUM_HEADSTAGES; headStage += 1)
			if(pressureDataWv[headStage][%OngoingPessurePulse])
				deviceID = pressureDataWv[headStage][%DAC_DevID]
				return 1
			endif
		endfor
	endfor

	return 0
End

/// @brief Fill the passed structure with pressure details for the DA wave
///
/// @param[in]  panelTitle   device
/// @param[in]  headStage    headstage
/// @param[in]  pressureMode one of #P_NEGATIVE_PULSE, #P_POSITIVE_PULSE, #P_MANUAL_PULSE
/// @param[out] p            pressure details
static Function P_GetPressureForDA(panelTitle, headStage, pressureMode, p)
	string panelTitle
	variable headStage, pressureMode
	STRUCT P_PressureDA &p

	variable DAGain, hwType

	WAVE pressureDataWv = P_GetPressureDataWaveRef(panelTitle)

	DAGain = pressureDataWv[Headstage][%DAC_Gain]
	hwType = pressureDataWv[headStage][%HW_DAC_Type]

	p.first             = 0
	p.last              = NaN
	p.calPressureOffset = PRESSURE_OFFSET
	p.pressure          = NaN

	switch(pressureMode)
		case P_MANUAL_PULSE:
			p.last        = PRESSURE_TTL_HIGH_START * WAVEBUILDER_MIN_SAMPINT + pressureDataWv[headStage][%ManPPDuration]
			p.pressure    = pressureDataWv[headStage][%ManPPPressure]
			p.calPressure = p.calPressureOffset + p.pressure / DAGain
			break
		case P_POSITIVE_PULSE:
			p.last     = PRESSURE_PULSE_ENDpt * WAVEBUILDER_MIN_SAMPINT
			p.pressure = pressureDataWv[Headstage][%LastPressureCommand] + POS_PRESSURE_PULSE_INCREMENT

			p.calPressure = p.pressure

			if(isFinite(PressureDataWv[headStage][%PosCalConst]))
				p.calPressure += PressureDataWv[headStage][%PosCalConst]
			endif

			if(p.calPressure >= MAX_REGULATOR_PRESSURE || p.calPressure <= 0)
				p.pressure    = MAX_POS_PRESSURE_PULSE
				p.calPressure = p.pressure
				if(isFinite(PressureDataWv[headStage][%NegCalConst]))
					p.calPressure += PressureDataWv[headStage][%NegCalConst]
				endif
			endif

			p.pressure    += pressureDataWv[headStage][%UserPressureOffsetPeriod]
			p.calPressure  = p.calPressureOffset + (p.calPressure + pressureDataWv[headStage][%UserPressureOffsetPeriod]) / DAGain

			break
		case P_NEGATIVE_PULSE:
			p.last     = PRESSURE_PULSE_ENDpt * WAVEBUILDER_MIN_SAMPINT
			p.pressure = pressureDataWv[Headstage][%LastPressureCommand]

			if(IsFinite(pressureDataWv[headStage][%UserPressureOffsetTotal]))
				p.pressure += pressureDataWv[headStage][%UserPressureOffsetPeriod]
			else
				if(p.pressure > MIN_NEG_PRESSURE_PULSE)
					p.pressure = MIN_NEG_PRESSURE_PULSE
				else
					p.pressure = max(MIN_REGULATOR_PRESSURE, P_GetPulseAmp(panelTitle, headStage))
				endif
			endif

			p.calPressure = p.pressure

			if(isFinite(PressureDataWv[headStage][%NegCalConst]))
				p.calPressure += PressureDataWv[headStage][%NegCalConst]
			endif

			if(p.calPressure <= MIN_REGULATOR_PRESSURE)
				p.pressure    = MIN_NEG_PRESSURE_PULSE
				p.calPressure = p.pressure

				if(isFinite(PressureDataWv[headStage][%NegCalConst]))
					p.calPressure += PressureDataWv[headStage][%NegCalConst]
				endif
			endif
			p.calPressure  = p.calPressureOffset + p.calPressure / DAGain

			break
		default:
			ASSERT(0, "Invalid pressure mode")
			break
	endswitch

	pressureDataWv[headStage][%UserPressureOffsetPeriod] = 0.0

	if(hwType == HARDWARE_ITC_DAC)
		p.first             /= HARDWARE_ITC_MIN_SAMPINT
		p.last              /= HARDWARE_ITC_MIN_SAMPINT
		p.calPressure       *= HARDWARE_ITC_BITS_PER_VOLT
		p.calPressureOffset *= HARDWARE_ITC_BITS_PER_VOLT
	elseif(hwType == HARDWARE_NI_DAC)
		p.first /= HARDWARE_NI_6001_MIN_SAMPINT
		p.last  /= HARDWARE_NI_6001_MIN_SAMPINT
		// calibrated pressures are already in volts
	else
		ASSERT(0, "unsupported hardware")
	endif
End

static Function/WAVE P_NI_GetDAWave(panelTitle, headStage)
	string panelTitle
	variable headStage

	variable DAC
	string wvName

   DFREF dfr = P_DeviceSpecificPressureDFRef(panelTitle)

	WAVE pressureDataWv = P_GetPressureDataWaveRef(panelTitle)
	DAC = pressureDataWv[headStage][%DAC]

	wvName = "NI_DA" + num2str(DAC)

	WAVE/SDFR=dfr/Z wv = $wvName

	if(WaveExists(wv))
		return wv
	else
		Make/O dfr:$wvName/WAVE=wv
		return wv
	endif
End

static Function/WAVE P_NI_GetADWave(panelTitle, headStage)
	string panelTitle
	variable headStage

	variable ADC
	string wvName

   DFREF dfr = P_DeviceSpecificPressureDFRef(panelTitle)

	WAVE pressureDataWv = P_GetPressureDataWaveRef(panelTitle)
	ADC = pressureDataWv[headStage][%ADC]

	wvName = "NI_AD" + num2str(ADC)

	WAVE/SDFR=dfr/Z wv = $wvName

	if(WaveExists(wv))
		return wv
	else
		Make/O dfr:$wvName/WAVE=wv
		return wv
	endif
End

static Function P_FillDAQWaves(panelTitle, headStage, p)
	string panelTitle
	variable headStage
	STRUCT P_PressureDA &p

	ASSERT(p.first < p.last && p.last - p.first >= 1, "first/last mismatch")

	variable hwType

	WAVE pressureDataWv = P_GetPressureDataWaveRef(panelTitle)
	hwType = pressureDataWv[headStage][%HW_DAC_Type]

	switch(hwType)
		case HARDWARE_ITC_DAC:
			WAVE ITCData = P_GetITCData(panelTitle)
			ITCData[][%AD]                = 0
			ITCData[][%DA]                = p.calPressureOffset
			ITCData[p.first, p.last][%DA] = p.calPressure
			break
		case HARDWARE_NI_DAC:
			// we have always only one DA and one AD

			WAVE da = P_NI_GetDAWave(panelTitle, headStage)
			WAVE ad = P_NI_GetADWave(panelTitle, headStage)

			Redimension/N=(p.last - p.first + 1) da, ad

			ad[] = 0
			da[] = p.calPressure
			da[DimSize(da, ROWS) - 1] = p.calPressureOffset

			SetScale/P x, 0, HARDWARE_NI_6001_MIN_SAMPINT * 1e-3, "s", da, ad
			break
		default:
			ASSERT(0, "unsupported hardware")
			break
	endswitch
End

/// @brief Updates the DA data used for ITC controlled pressure devices for a negative pressure pulse
static Function P_DAforNegPpulse(panelTitle, headStage)
	string panelTitle
	variable headStage

	STRUCT P_PressureDA p
	P_GetPressureForDA(panelTitle, headStage, P_NEGATIVE_PULSE, p)

	P_FillDAQWaves(panelTitle, headStage, p)

	WAVE pressureDataWv = P_GetPressureDataWaveRef(panelTitle)
	pressureDataWv[headstage][%RealTimePressure]    = p.pressure
	pressureDataWv[headstage][%LastPressureCommand] = p.pressure

	printf "pulse amp: %g\r", p.pressure
End

/// @brief Returns the negative pressure pulse amplitude
static Function P_GetPulseAmp(panelTitle, headStage)
	string panelTitle
	variable headstage

	WAVE PressureDataWv = P_GetPressureDataWaveRef(panelTitle)
	variable NextPulseCount = P_LastPulseCount(PressureDataWv[headStage][%LastPressureCommand]) + 1

	return MIN_NEG_PRESSURE_PULSE - (NextPulseCount/2)^2
End

///@brief Returns the pulse count
static Function P_LastPulseCount(pulseAmp)
	variable pulseAmp

	return -MIN_NEG_PRESSURE_PULSE * ((pulseAmp - MIN_NEG_PRESSURE_PULSE)/ -1)^0.5
End

/// @brief Updates the DA data used for ITC controlled pressure devices for a positive pressure pulse
static Function P_DAforPosPpulse(panelTitle, headstage)
	string panelTitle
	variable headstage

	STRUCT P_PressureDA p
	P_GetPressureForDA(panelTitle, headstage, P_POSITIVE_PULSE, p)

	P_FillDAQWaves(panelTitle, headStage, p)

	WAVE pressureDataWv = P_GetPressureDataWaveRef(panelTitle)
	pressureDataWv[Headstage][%LastPressureCommand] = p.pressure
	pressureDataWv[Headstage][%RealTimePressure]    = p.pressure

	printf "pulse amp: %g\r", p.pressure
End

/// @brief Updates the DA data used for ITC controlled pressure devices for a manual pressure pulse
static Function P_DAforManPpulse(panelTitle, Headstage)
	string panelTitle
	variable Headstage

	STRUCT P_PressureDA p
	P_GetPressureForDA(panelTitle, headstage, P_MANUAL_PULSE, p)

	if(p.pressure < MAX_REGULATOR_PRESSURE && p.pressure > MIN_REGULATOR_PRESSURE)

		P_FillDAQWaves(panelTitle, headStage, p)

		WAVE pressureDataWv = P_GetPressureDataWaveRef(panelTitle)
		pressureDataWv[Headstage][%LastPressureCommand] = p.pressure
		printf "pulse amp: %g\r", p.pressure
	else
		print "pressure command is out of range"
	endif
End

/// @brief Updates the rack 0 and rack 1 TTL waves used for ITC controlled pressure devices.
static Function P_TTLforPpulse(panelTitle, headStage)
	string panelTitle
	variable headStage

	variable rackZeroState, rackOneState, deviceID, hwType, rack, TTL, ret
	string deviceType, deviceNumber
	string pressureDevice

	WAVE ITCData             = P_GetITCData(panelTitle)
	WAVE pressureDataWv      = P_GetPressureDataWaveRef(panelTitle)
	WAVE/T PressureDataTxtWv = P_PressureDataTxtWaveRef(panelTitle)
	TTL                      = pressureDataWv[headStage][%TTL_A]
	pressureDevice           = PressureDataTxtWv[headStage][%Device]

	hwType   = pressureDataWv[headStage][%HW_DAC_Type]
	deviceID = pressureDataWv[headStage][%DAC_DevID]

	if(hwType == HARDWARE_NI_DAC)
		return 0
	endif

	ASSERT(IsFinite(TTL), "TTL A must be finite")

	ret = ParseDeviceString(panelTitle, deviceType, deviceNumber)
	if(!cmpstr(deviceType, "ITC1600"))
		// request TTL bit definitly in rack zero
		rackZeroState = HW_ReadDigital(hwType, deviceID, 0)
		ITCData[][%TTL_R0] = rackZeroState

		// request TTL bit definitly in rack one
		rackOneState = HW_ReadDigital(hwType, deviceID, 4)
		ITCData[][%TTL_R1] = rackOneState
	else
		ASSERT(0, "does currently not work with the ITC18USB as DI/DO channels are different")
	endif

	rack = HW_ITC_GetRackForTTLBit(pressureDevice, TTL)
	if(rack == RACK_ZERO)
		rackZeroState = P_UpdateTTLdecimal(pressureDevice, rackZeroState, TTL, 1)
		ITCData[PRESSURE_TTL_HIGH_START, PRESSURE_PULSE_ENDpt][%TTL_R0] = rackZeroState
	elseif(rack == RACK_ONE)
		rackOneState = P_UpdateTTLdecimal(pressureDevice, rackOneState, TTL, 1)
		ITCData[PRESSURE_TTL_HIGH_START, PRESSURE_PULSE_ENDpt][%TTL_R1] = rackOneState
	else
		ASSERT(0, "Impossible case")
	endif
End

/// @brief returns the new TTL state based on the starting TTL state.
static Function P_UpdateTTLdecimal(pressureDevice, dec, ttlBit, ONorOFF)
	string pressureDevice
	variable dec, ttlBit, ONorOFF

	WAVE binary = P_DecToBinary(dec)

	ttlBit = HW_ITC_ClipTTLBit(pressureDevice, ttlBit)

	// update tll associated with headStage only if the desired TTL channel
	// state is different from the actual/current channel state.
	if(ONorOFF != binary[ttlBit])
		if(ONorOFF)
			return SetBit(dec, 2^ttlBit)
		else
			return ClearBit(dec, 2^ttlBit)
		endif
	endif

	return dec
End

/// @brief Updates the pressure mode button state in the DA_Ephys Data Acq tab
Function P_UpdatePressureMode(panelTitle, pressureMode, pressureControlName, checkALL)
	string panelTitle
	variable pressureMode
	string pressureControlName
	variable checkAll

	WAVE PressureDataWv = P_GetPressureDataWaveRef(panelTitle)
	variable headStageNo = PressureDataWv[0][%UserSelectedHeadStage]	
	variable SavedPressureMode = PressureDataWv[headStageNo][%Approach_Seal_BrkIn_Clear]

	if(P_ValidatePressureSetHeadstage(panelTitle, headStageNo)) // check if headStage pressure settings are valid
		P_EnableButtonsIfValid(panelTitle, headStageNo)

		if(pressureMode == SavedPressureMode) // The saved pressure mode and the pressure mode being passed are equal therefore toggle the same button
			SetControlTitle(panelTitle, pressureControlName, StringFromList(pressureMode, PRESSURE_CONTROL_TITLE_LIST))
			SetControlTitleColor(panelTitle, pressureControlName, 0, 0, 0)
			PressureDataWv[headStageNo][%Approach_Seal_BrkIn_Clear] = PRESSURE_METHOD_ATM
			P_ResetPressureData(panelTitle, headStageNo = headStageNo)
		else // saved and new pressure mode don't match
			if(SavedPressureMode != PRESSURE_METHOD_ATM) // saved pressure mode isn't pressure OFF (-1)
				// reset the button for the saved pressure mode
				SetControlTitle(panelTitle, StringFromList(SavedPressureMode, PRESSURE_CONTROLS_BUTTON_LIST), StringFromList(SavedPressureMode, PRESSURE_CONTROL_TITLE_LIST))
				SetControlTitleColor(panelTitle, StringFromList(SavedPressureMode, PRESSURE_CONTROLS_BUTTON_LIST), 0, 0, 0)
			endif

			if(PressureMode == PRESSURE_METHOD_APPROACH) // On approach, apply the mode
				SetControlTitle(panelTitle, pressureControlName, ("Stop " + StringFromList(pressureMode, PRESSURE_CONTROL_TITLE_LIST)))
				SetControlTitleColor(panelTitle, pressureControlName, 39168, 0, 0)
				PressureDataWv[headStageNo][%Approach_Seal_BrkIn_Clear] = pressureMode
			elseif(PressureMode == PRESSURE_METHOD_MANUAL) // Manual pressure set, apply the mode
				SetControlTitle(panelTitle, pressureControlName, ("Stop " + StringFromList(pressureMode, PRESSURE_CONTROL_TITLE_LIST)))
				SetControlTitleColor(panelTitle, pressureControlName, 39168, 0, 0)
				PressureDataWv[headStageNo][%Approach_Seal_BrkIn_Clear] = pressureMode
			elseif(PressureMode) // all other modes, only apply if TP is running
				if(P_PressureMethodPossible(panelTitle, headStageNo))
					SetControlTitle(panelTitle, pressureControlName, ("Stop " + StringFromList(pressureMode, PRESSURE_CONTROL_TITLE_LIST)))
					SetControlTitleColor(panelTitle, pressureControlName, 39168, 0, 0)
					PressureDataWv[headStageNo][%Approach_Seal_BrkIn_Clear] = pressureMode
				endif
			endif
		endif
		P_UpdatePressureType(panelTitle)
		P_PressureDisplayHighlite(panelTitle, 1)
	endif

	if(checkAll)
		P_CheckAll(panelTitle, pressureMode, SavedPressureMode)
	endif
End

/// @brief Resets pressure data to base state
///
static Function P_ResetPressureData(panelTitle, [headStageNo])
	string panelTitle
	variable headStageNo
	
	WAVE PressureDataWv = P_GetPressureDataWaveRef(panelTitle)
	if(paramIsDefault(headStageNo))
		PressureDataWv[][%TimeOfLastRSlopeCheck]     = 0.0
		PressureDataWv[][%UserPressureOffset]        = 0.0
		PressureDataWv[][%UserPressureOffsetTotal]   = NaN
		PressureDataWv[][%UserPressureOffsetPeriod]  = 0.0		
	else
		PressureDataWv[headStageNo][%TimeOfLastRSlopeCheck]     = 0.0
		PressureDataWv[headStageNo][%UserPressureOffset]        = 0.0
		PressureDataWv[headStageNo][%UserPressureOffsetTotal]   = NaN
		PressureDataWv[headStageNo][%UserPressureOffsetPeriod]  = 0.0	
	endif
End

/// @brief Applies pressure mode to all headstages with valid pressure settings
static Function P_CheckAll(panelTitle, pressureMode, SavedPressureMode)
	string panelTitle
	variable pressureMode, SavedPressureMode

	variable headStage
	WAVE PressureDataWv = P_GetPressureDataWaveRef(panelTitle)
	if(pressureMode == savedPressureMode) // un clicking button
		if(DAG_GetNumericalValue(panelTitle, StringFromList(savedPressureMode, PRESSURE_CONTROL_CHECKBOX_LIST)))
			PressureDataWv[][%Approach_Seal_BrkIn_Clear] = PRESSURE_METHOD_ATM
		endif
	else
		if(DAG_GetNumericalValue(panelTitle, StringFromList(pressureMode, PRESSURE_CONTROL_CHECKBOX_LIST)))
			for(headStage = 0; headStage < NUM_HEADSTAGES; headStage += 1)
				if(P_ValidatePressureSetHeadstage(panelTitle, headStage))
					if(pressureMode && P_PressureMethodPossible(panelTitle, headStage))
						PressureDataWv[headStage][%Approach_Seal_BrkIn_Clear] = pressureMode
					else
						PressureDataWv[headStage][%Approach_Seal_BrkIn_Clear] = pressureMode // pressure mode = 0
					endif
				endif
			endfor
		endif
	endif
	P_UpdatePressureType(panelTitle)
End

Function P_SetPressureOffset(panelTitle, headstage, userOffset)
	string panelTitle
	variable headstage
	variable userOffset

	variable method, val

	WAVE pressureDataWv = P_GetPressureDataWaveRef(panelTitle)

	if(headstage < 0 || headstage >= NUM_headstageS)
		DEBUGPRINT("headstage is out of range", var=headstage)
		return NaN
	endif

	method = pressureDataWv[headstage][%Approach_Seal_BrkIn_Clear]

	if(method == PRESSURE_METHOD_ATM)
		return NaN
	endif

	pressureDataWv[headstage][%UserPressureOffset]        = userOffset
	pressureDataWv[headstage][%UserPressureOffsetPeriod] += userOffset

	if(!IsFinite(PressureDataWv[headstage][%UserPressureOffsetTotal]))
		pressureDataWv[headstage][%UserPressureOffsetTotal] = userOffset
	else
		pressureDataWv[headstage][%UserPressureOffsetTotal] += userOffset
	endif

	switch(method)
		// pulse based methods
		case PRESSURE_METHOD_BREAKIN:
		case PRESSURE_METHOD_CLEAR:
		case PRESSURE_METHOD_MANUAL:
			// wait till next time point or ignore
			break
		// steady state methods
		case PRESSURE_METHOD_ATM:
			ASSERT(0, "Offset must be ignored for ATM method")
			break
		case PRESSURE_METHOD_SEAL:
			val = pressureDataWv[headstage][%LastPressureCommand] + pressureDataWv[headstage][%UserPressureOffset]
			val = P_SetAndGetPressure(panelTitle, headstage, val)
			pressureDataWv[headstage][%RealTimePressure]    = val
			pressureDataWv[headstage][%LastPressureCommand] = val
			break
		case PRESSURE_METHOD_APPROACH:
			// wait till next time point or do now if no TP is running
			if(!TP_CheckIfTestpulseIsRunning(panelTitle))
				val = pressureDataWv[headstage][%LastPressureCommand] + pressureDataWv[headstage][%UserPressureOffset]
				val = P_SetAndGetPressure(panelTitle, headstage, val)
				pressureDataWv[headstage][%LastPressureCommand] = val
				pressureDataWv[headstage][%RealTimePressure]    = val
			endif
			break
		default:
			ASSERT(0, "unhandled pressure method")
			break
	endswitch
End

Function P_InitBeforeTP(panelTitle)
	string panelTitle

	variable headstage
	
	WAVE PressureDataWv = P_GetPressureDataWaveRef(panelTitle)
	headstage = PressureDataWv[0][%UserSelectedHeadStage]
	P_ResetPressureData(panelTitle)
	P_SaveUserSelectedHeadstage(panelTitle, headstage)
	P_LoadPressureButtonState(panelTitle)
End

/// @brief Colors and changes the title of the pressure buttons based on the saved pressure mode.
Function P_LoadPressureButtonState(panelTitle)
	string panelTitle

	variable headStageNo

	WAVE PressureDataWv = P_GetPressureDataWaveRef(panelTitle)
	// value is equal for all rows
	headStageNo = PressureDataWv[0][%UserSelectedHeadStage]

	P_ResetAll_P_ButtonsToBaseState(panelTitle)
	if(P_ValidatePressureSetHeadstage(panelTitle, headStageNo)) // check if headStage pressure settings are valid

		P_EnableButtonsIfValid(panelTitle, headStageNo)
		variable SavedPressureMode = PressureDataWv[headStageNo][%Approach_Seal_BrkIn_Clear]

		if(SavedPressureMode != PRESSURE_METHOD_ATM) // there is an active pressure mode
			if(SavedPressureMode == PRESSURE_METHOD_APPROACH || savedPressureMode == PRESSURE_METHOD_MANUAL) // On approach, apply the mode
				SetControlTitle(panelTitle, StringFromList(SavedPressureMode, PRESSURE_CONTROLS_BUTTON_LIST), ("Stop " + StringFromList(SavedPressureMode, PRESSURE_CONTROL_TITLE_LIST)))
				SetControlTitleColor(panelTitle, StringFromList(SavedPressureMode, PRESSURE_CONTROLS_BUTTON_LIST), 39168, 0, 0)
			elseif(SavedPressureMode) // other pressure modes
				if(P_PressureMethodPossible(panelTitle, headStageNo))
					SetControlTitle(panelTitle, StringFromList(SavedPressureMode, PRESSURE_CONTROLS_BUTTON_LIST), ("Stop " + StringFromList(SavedPressureMode, PRESSURE_CONTROL_TITLE_LIST)))
					SetControlTitleColor(panelTitle, StringFromList(SavedPressureMode, PRESSURE_CONTROLS_BUTTON_LIST), 39168, 0, 0)
				endif
			endif
		elseif(SavedPressureMode == PRESSURE_METHOD_ATM)
			SetControlTitle(panelTitle, stringFromList(4,PRESSURE_CONTROLS_BUTTON_LIST), StringFromList(4, PRESSURE_CONTROL_TITLE_LIST))
			SetControlTitleColor(panelTitle, stringFromList(4,PRESSURE_CONTROLS_BUTTON_LIST), 0, 0, 0)
		endif
	else
		SetPressureButtonsToBaseState(panelTitle)
	endif

	P_PressureDisplayHighlite(panelTitle, 1) // highlites specific headStage
End

/// @brief Sets the pressure toggle buttons to disabled, default color, default title
Static Function SetPressureButtonsToBaseState(panelTitle)
	string panelTitle

	DisableControls(panelTitle, PRESSURE_CONTROLS_BUTTON_LIST)
	SetControlTitles(panelTitle, PRESSURE_CONTROLS_BUTTON_LIST, PRESSURE_CONTROL_TITLE_LIST)
	SetControlTitleColors(panelTitle, PRESSURE_CONTROLS_BUTTON_LIST, 0, 0, 0)
End

/// @brief Checks if the Approach button can be enabled or all pressure mode buttons can be enabled. Enables buttons that pass checks.
static Function P_EnableButtonsIfValid(panelTitle, headStageNo)
	string panelTitle
	variable headStageNo

	string PRESSURE_CONTROLS_BUTTON_subset = RemoveListItem(0, PRESSURE_CONTROLS_BUTTON_LIST)

	// set the pressure button controls to their base color and titles
	SetControlTitles(panelTitle, PRESSURE_CONTROLS_BUTTON_LIST, PRESSURE_CONTROL_TITLE_LIST)
	SetControlTitleColors(panelTitle, PRESSURE_CONTROLS_BUTTON_LIST, 0, 0, 0)

	if(P_PressureMethodPossible(panelTitle, headStageNo))
		if(DAG_GetNumericalValue(panelTitle, StringFromList(PRESSURE_METHOD_CLEAR, PRESSURE_CONTROL_CHECKBOX_LIST)))
			EnableControls(panelTitle, PRESSURE_CONTROLS_BUTTON_LIST)
		else
			DisableControls(panelTitle, PRESSURE_CONTROLS_BUTTON_subset)
			EnableControl(panelTitle, StringFromList(0, PRESSURE_CONTROLS_BUTTON_LIST)) // approach button
			EnableControl(panelTitle, StringFromList(1, PRESSURE_CONTROLS_BUTTON_LIST))
			EnableControl(panelTitle, StringFromList(2, PRESSURE_CONTROLS_BUTTON_LIST))
			EnableControl(panelTitle, StringFromList(4, PRESSURE_CONTROLS_BUTTON_LIST))
		endif
	else
		DisableControls(panelTitle, PRESSURE_CONTROLS_BUTTON_subset)
		EnableControl(panelTitle, StringFromList(0, PRESSURE_CONTROLS_BUTTON_LIST)) // approach button
		EnableControl(panelTitle, StringFromList(4, PRESSURE_CONTROLS_BUTTON_LIST))
	endif
End

///@brief updates the tablabels for the pressure tabControl according to the pressure mode
Function P_UpdatePressureModeTabs(panelTitle, headStage)
	string panelTitle
	variable headStage

	WAVE pressureWave = P_GetPressureDataWaveRef(panelTitle)
	variable pressureMode = PressureWave[headStage][%Approach_Seal_BrkIn_Clear]
	string highlightSpec = "\\f01\\Z11"

	if(pressureMode == PRESSURE_METHOD_ATM)
		TabControl tab_DataAcq_Pressure win=$panelTitle, tabLabel(0) = "Auto"
		TabControl tab_DataAcq_Pressure win=$panelTitle, tabLabel(1) = "Manual"
	elseif(pressureMode == PRESSURE_METHOD_MANUAL)
		PGC_SetAndActivateControl(panelTitle, "tab_DataAcq_Pressure", val = 1)
		TabControl tab_DataAcq_Pressure win=$panelTitle, tabLabel(0) = "Auto"
		TabControl tab_DataAcq_Pressure win=$panelTitle, tabLabel(1) = highlightSpec + "Manual"
	else
		PGC_SetAndActivateControl(panelTitle, "tab_DataAcq_Pressure", val = 0)
		TabControl tab_DataAcq_Pressure win=$panelTitle, tabLabel(0) = highlightSpec + "Auto"
		TabControl tab_DataAcq_Pressure win=$panelTitle, tabLabel(1) = "Manual"
	endif

	PGC_SetAndActivateControl(panelTitle, "setvar_DataAcq_SSPressure", val = pressureWave[headStage][%ManSSPressure])
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

	if(!isFinite(PressureDataWv[headStageNo][%HW_DAC_Type]))
		sprintf msg, "DAC Type is not configured for headStage %d"  headStageNo
		DEBUGPRINT(msg)
		return 0
	endif

	if(!isFinite(PressureDataWv[headStageNo][%DAC_DevID]))
		sprintf msg, "DAC device ID is not configured for headstage %d"  headStageNo
		DEBUGPRINT(msg)
		return 0
	endif

	// TTL_B is optional
	if(!isFinite(PressureDataWv[headStageNo][%TTL_A]))
		sprintf msg, "TTL A is not configured for headstage %d"  headStageNo
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
static Function P_DACIsCollectingData(panelTitle, headStage)
	string panelTitle
	variable headStage

	variable hwType, deviceID

	wave PressureDataWv = P_GetPressureDataWaveRef(panelTitle)

	hwType   = pressureDataWv[headStage][%HW_DAC_Type]
	deviceID = pressureDataWv[headStage][%DAC_DevID]

	return HW_IsRunning(hwType, deviceID)
End

/// @brief Return true if pressure methods can be used on that headstage now
///
/// Does not check if the headstage has valid settings, see P_ValidatePressureSetHeadstage(),
/// or that no pressure pulse is currently ongoing, see P_DACIsCollectingData().
static Function P_PressureMethodPossible(panelTitle, headstage)
	string panelTitle
	variable headstage

	return TP_CheckIfTestpulseIsRunning(panelTitle) && P_IsHSActiveAndInVClamp(panelTitle, headstage)
End

/// @brief Determines headStage is on and in V-Clamp mode
static Function P_IsHSActiveAndInVClamp(panelTitle, headStage)
	string panelTitle
	variable headStage

	return V_CLAMP_MODE == DAG_GetHeadstageMode(panelTitle, headStage) && DAG_GetHeadstageState(panelTitle, headStage)
End

/// @brief Returns the four pressure buttons to the base state (gray color; removes "Stop" string from button title)
static Function P_ResetAll_P_ButtonsToBaseState(panelTitle)
	string panelTitle

	variable i = 0
	for(i = 0; i < 4; i += 1)
		SetControlTitle(panelTitle, StringFromList(i, PRESSURE_CONTROLS_BUTTON_LIST), StringFromList(i, PRESSURE_CONTROL_TITLE_LIST))
		SetControlTitleColor(panelTitle, StringFromList(i, PRESSURE_CONTROLS_BUTTON_LIST), 0, 0, 0)
	endfor
End

Function P_PressureDisplayHighlite(panelTitle, hilite)
	string panelTitle
	variable hilite
	
	variable RGB
	string Zero, Low, High
	if(hilite)
		Zero = ZERO_COLOR_HILITE
		Low = LOW_COLOR_HILITE
		high = HIGH_COLOR_HILITE
		RGB = 65000
	else
		Zero = ZERO_COLOR
		Low = LOW_COLOR
		high = HIGH_COLOR
		RGB = 0
	endif
	
	wave PressureDataWv = P_GetPressureDataWaveRef(panelTitle)
	variable Rz = str2num(stringFromList(0,Zero))
	variable Gz = str2num(stringFromList(1,Zero))
	variable Bz = str2num(stringFromList(2,Zero))
	variable Rl = str2num(stringFromList(0,Low))
	variable Gl = str2num(stringFromList(1,Low))
	variable Bl = str2num(stringFromList(2,Low))
	variable Rh = str2num(stringFromList(0,High))
	variable Gh = str2num(stringFromList(1,High))
	variable Bh = str2num(stringFromList(2,High))	

	string controlName
	sprintf controlName, "valdisp_DataAcq_P_LED_%d" pressureDataWv[0][%userSelectedHeadStage]
	ValDisplay $controlName zeroColor=(Rz, Gz, Bz), lowColor=(Rl, Gl, Bl), highColor=(Rh, Gh, Bh), win=$panelTitle
	
	sprintf controlName, "valdisp_DataAcq_P_%d" pressureDataWv[0][%userSelectedHeadStage]
	ChangeControlValueColor(panelTitle, controlName, RGB, RGB, RGB)

//	sprintf controlName, "valdisp_DataAcq_P_%d" pressureDataWv[0][%userSelectedHeadStage]
	//ValDisplay $controlNamevalueColor=(65535,65535,65535)
End

/// @brief Enables ITC devices for all locked DA_Ephys panels. Sets the correct pressure button state for all locked DA_Ephys panels.
static Function P_Enable()
	variable i, j, headstage, numPressureDevices
	string lockedDevice, listOfPressureCtrlDevices, device
	string listOfLockedDA_Ephys = GetListOfLockedDevices()

	// disable any devices that may already be assigned to pressure regulation
	// handles mistmatch between GUI controls and hardware state
	P_Disable()

	for(i = 0; i < ItemsInList(ListOfLockedDA_Ephys); i += 1)
		lockedDevice = StringFromList(i, ListOfLockedDA_Ephys)
		listOfPressureCtrlDevices = P_GetListOfPressureCtrlDevices(lockedDevice)
		numPressureDevices = ItemsInList(listOfPressureCtrlDevices)

		for(j = 0; j < numPressureDevices; j += 1)
			device = StringFromList(j, listOfPressureCtrlDevices)
			P_OpenDevice(lockedDevice, device)
		endfor

		if(numPressureDevices)
			DisableControl(lockedDevice, "button_Hardware_P_Enable")
			EnableControl(lockedDevice, "button_Hardware_P_Disable")
			EnableControls(lockedDevice, PRESSURE_CONTROL_CHECKBOX_LIST)

			headStage = DAG_GetNumericalValue(lockedDevice, "slider_DataAcq_ActiveHeadstage")
			P_SaveUserSelectedHeadstage(lockedDevice, headstage)

			P_LoadPressureButtonState(lockedDevice)
			P_SetLEDValueAssoc(lockedDevice)
		else
			printf "No devices are presently assigned for pressure regulation on: %s\r" LockedDevice
		endif
	endfor
End

/// @brief Disables ITC devices for all locked DA_Ephys panels. Sets the correct pressure button state for all locked DA_Ephys panels.
Function P_Disable()
	string ListOfLockedDA_Ephys = GetListOfLockedDevices()
	variable i, numPressureDevices
	string lockedDevice, listOfPressureCtrlDevices, device

	for(i = 0; i < ItemsInList(ListOfLockedDA_Ephys); i += 1)
		lockedDevice = StringFromList(i, ListOfLockedDA_Ephys)
		listOfPressureCtrlDevices = P_GetListOfPressureCtrlDevices(lockedDevice)
		numPressureDevices = ItemsInList(listOfPressureCtrlDevices)

		if(numPressureDevices)
			P_CloseDevice(lockedDevice)

			DisableControl(LockedDevice, "button_Hardware_P_Disable")
			EnableControl(LockedDevice, "button_Hardware_P_Enable")
			EnableControls(LockedDevice,PRESSURE_CONTROL_CHECKBOX_LIST)
			DisableControls(LockedDevice, PRESSURE_CONTROLS_BUTTON_LIST)
			DisableControls(LockedDevice, PRESSURE_CONTROL_CHECKBOX_LIST)
			P_UpdatePressureType(LockedDevice)
		endif
	endfor
End

/// @brief Decimal to binary in 8bit wave
///
/// Wave is always 4 rows long so that each TTL channel on the front of the ITC DAC gets "encoded"
static Function/WAVE P_DecToBinary(dec)
	variable dec

	variable bit, i
	MAKE/FREE/B/U/N=4 binary

	for(i = 0; i < 4; i += 1)
		bit = mod(dec, 2)
		dec = floor(dec / 2^1) // shift one to the right
		binary[i] = bit
	endfor

	return binary
End

/// @brief Manual pressure control
static Function P_ManSetPressure(panelTitle, headStage, manPressureAll)
	string panelTitle
	variable headStage, manPressureAll

	WAVE PressureDataWv = P_GetPressureDataWaveRef(panelTitle)

	variable psi
	variable ONorOFF = 1
	variable userSelectedHeadstage

	userSelectedHeadstage = PressureDataWv[0][%UserSelectedHeadstage]

	if(manPressureAll && PressureDataWv[userSelectedHeadstage][%Approach_Seal_BrkIn_Clear] == PRESSURE_METHOD_MANUAL && headstage == 0)
		PressureDataWv[][%ManSSPressure] = PressureDataWv[userSelectedHeadstage][%ManSSPressure]
	endif

	psi = PressureDataWv[headStage][%ManSSPressure]

	PressureDataWv[headstage][%LastPressureCommand] = P_SetAndGetPressure(panelTitle, headstage, psi)
	P_SetPressureValves(panelTitle, headStage, P_GetUserAccess(panelTitle, headstage, PRESSURE_METHOD_MANUAL))
End

/// @brief Saves user seleted headstage in pressureData wave
///
Function P_SaveUserSelectedHeadstage(panelTitle, headStage)
	string panelTitle
	variable headStage
	WAVE PressureDataWv = P_GetPressureDataWaveRef(panelTitle)
	PressureDataWv[][%UserSelectedHeadStage] =  headStage
End

/// @brief Sets all headstage to atmospheric pressure
///
Function P_SetAllHStoAtmospheric(panelTitle)
	string panelTitle
	
	DFREF dfr=P_DeviceSpecificPressureDFRef(panelTitle)
	WAVE/Z/SDFR=dfr PressureData

	if(WaveExists(PressureData))
		if(sum(GetColfromWavewithDimLabel(PressureData, "Approach_Seal_BrkIn_Clear")) != (PRESSURE_METHOD_ATM * NUM_HEADSTAGES)) // Only update pressure wave if pressure methods are different from atmospheric
			PressureData[][%Approach_Seal_BrkIn_Clear] = PRESSURE_METHOD_ATM
			P_PressureControl(panelTitle)
		endif
	endif
End

/// @brief Gets the pressure mode for a headstage
///
Function P_GetPressureMode(panelTitle, headStage)
	string panelTitle
	variable headstage
	
	return P_GetPressureDataWaveRef(panelTitle)[headStage][%Approach_Seal_BrkIn_Clear]
End

/// @brief Sets the pressure mode
///
/// Intended for use by other processes
/// @param panelTitle device
/// @param headStage MIES headstage number, must be in the range [0, NUM_HEADSTAGES]
/// @param pressureMode One of the pressure modes defined in @ref PressureModeConstants
/// @param pressure [optional, ignored by default. Sets pressure of manual mode]
Function P_SetPressureMode(panelTitle, headStage, pressureMode, [pressure])
	string panelTitle
	variable headstage
	variable pressureMode
	variable pressure
	
	ASSERT(headstage < NUM_HEADSTAGES && headStage >= 0,  "Select headstage number between 0 and 7")
	ASSERT(pressureMode >= PRESSURE_METHOD_ATM && pressureMode <= PRESSURE_METHOD_MANUAL, "Select a pressure mode between -1 and 4")
	
	WAVE PressureDataWv = P_GetPressureDataWaveRef(panelTitle)
	variable activePressureMode = P_GetPressureMode(panelTitle, headStage)
	variable UserSelectedHS = PressureDataWv[headStage][%UserSelectedHeadStage]
	
	if(!paramIsDefault(pressure) && pressureMode == PRESSURE_METHOD_MANUAL)
		ASSERT(pressure > MIN_REGULATOR_PRESSURE && pressure < MAX_REGULATOR_PRESSURE, "Use pressure value greater than -10 psi and less than 10 psi")
		if(UserSelectedHS == headStage)
			PGC_SetAndActivateControl(panelTitle, "setvar_DataAcq_SSPressure", val = pressure)
		endif
		PressureDataWv[headStage][%ManSSPressure] = pressure
	endif
		
	if(activePressureMode != pressureMode)
		if(UserSelectedHS == headStage)
			if(pressureMode == PRESSURE_METHOD_ATM)
				P_UpdatePressureMode(panelTitle, activePressureMode, stringFromList(activePressureMode,PRESSURE_CONTROLS_BUTTON_LIST), 0)	
				P_ResetPressureData(panelTitle, headStageNo = headStage)
			else
				P_UpdatePressureMode(panelTitle, PressureMode, stringFromList(PressureMode,PRESSURE_CONTROLS_BUTTON_LIST), 0)	
			endif
		else
			PressureDataWv[headStage][%Approach_Seal_BrkIn_Clear] = pressureMode
			if(pressureMode == PRESSURE_METHOD_ATM)
				P_ResetPressureData(panelTitle, headStageNo = headStage)
			endif
		endif
	endif
	
	P_RunP_ControlIfTPOFF(panelTitle)
End

// PRESSURE CONTROLS; DA_ePHYS PANEL; DATA ACQUISTION TAB

/// @brief Approach button.
Function ButtonProc_Approach(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch(ba.eventCode)
		case 2: // mouse up
			P_SetApproach(ba.win, ba.ctrlName)
			break
	endswitch

	return 0
End

/// @brief Sets approach state
///
/// Handles the TP depency of the approach pressure application
Function P_SetApproach(panelTitle, cntrlName)
	string panelTitle, cntrlName
	P_UpdatePressureMode(panelTitle, PRESSURE_METHOD_APPROACH, cntrlName, 1)
	P_RunP_ControlIfTPOFF(panelTitle)
End

/// @brief Seal button.
Function ButtonProc_Seal(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch(ba.eventCode)
		case 2: // mouse up
			P_UpdatePressureMode(ba.win, PRESSURE_METHOD_SEAL, ba.ctrlName, 1)
			break
	endswitch

	return 0
End

/// @brief Break in button.
Function ButtonProc_BreakIn(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch(ba.eventCode)
		case 2: // mouse up
			P_UpdatePressureMode(ba.win, PRESSURE_METHOD_BREAKIN, ba.ctrlName, 1)
			break
	endswitch

	return 0
End

/// @brief Clear button.
Function ButtonProc_Clear(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch(ba.eventCode)
		case 2: // mouse up
			P_UpdatePressureMode(ba.win, PRESSURE_METHOD_CLEAR, ba.ctrlName, 0)
			break
	endswitch

	return 0
End

/// @brief Handles the TP depency of the Manual pressure application
static Function P_SetManual(panelTitle, cntrlName)
	string panelTitle, cntrlName
	P_UpdatePressureMode(panelTitle, PRESSURE_METHOD_MANUAL, cntrlName, 1)
	P_RunP_ControlIfTPOFF(panelTitle)
End

/// @brief Clear all check box.
Function CheckProc_ClearEnable(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	variable headstage

	switch(cba.eventCode)
		case 2: // mouse up
			Variable checked = cba.checked
			DAG_Update(cba.win, cba.ctrlName, val = cba.checked)
			headstage = DAG_GetNumericalValue(cba.win, "slider_DataAcq_ActiveHeadstage")

			if(checked)
				if(P_PressureMethodPossible(cba.win, headstage))
					EnableControl(cba.win, "button_DataAcq_Clear")
				endif
			else
				DisableControl(cba.win, "button_DataAcq_Clear")
			endif
			break
	endswitch

	return 0
End

/// @brief Update DAC list button.
Function ButtonProc_Hrdwr_P_UpdtDAClist(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch(ba.eventCode)
		case 2: // mouse up
			string filteredList = ""
			string DeviceList = NONE + ";" + HW_ITC_ListDevices() + HW_NI_ListDevices()
			string lockedList = GetListOfLockedDevices()
			string dev
			variable nrDevs = ItemsInList(DeviceList)
			variable i
			for(i = 0;i < nrDevs; i += 1)
				dev = StringFromList(i, DeviceList)
				if(WhichListItem(dev, lockedList) == -1)
					filteredList = AddListItem(dev, filteredList, ";", INF)
				endif
			endfor

			SetPopupMenuVal(ba.win, "popup_Settings_Pressure_dev", filteredList)
			SetPopupMenuVal(ba.win, "popup_Settings_UserPressure", filteredList)
			break
	endswitch

	return 0
End

/// @brief Pressure control ITC device Enable button in Hardware tab of DA_Ephys panel
Function P_ButtonProc_Enable(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	string panelTitle

	switch(ba.eventCode)
		case 2: // mouse up
			panelTitle = ba.win
			DAP_AbortIfUnlocked(panelTitle)
			P_Enable()
			P_UpdatePressureDataStorageWv(panelTitle)
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
	endswitch

	return 0
End

/// @brief Set pressure button.
Function ButtonProc_DataAcq_ManPressSet(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch(ba.eventCode)
		case 2: // mouse up
			P_SetManual(ba.win, ba.ctrlname)
			break
	endswitch

	return 0
End

/// @brief Manual pressure pulse button.
Function ButtonProc_ManPP(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch(ba.eventCode)
		case 2: // mouse up
			variable headStage = DAG_GetNumericalValue(ba.win, "slider_DataAcq_ActiveHeadstage")
			P_ManPressurePulse(ba.win, headStage)
			break
	endswitch

	return 0
End

Function P_Check_ApproachNear(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	switch(cba.eventCode)
		case 2: // mouse up
			DAP_AbortIfUnlocked(cba.win)
			DAG_Update(cba.win, cba.ctrlName, val = cba.checked)
			P_UpdatePressureDataStorageWv(cba.win)
			P_RunP_ControlIfTPOFF(cba.win)
			break
	endswitch

	return 0
End

Function P_Check_SealAtm(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	switch(cba.eventCode)
		case 2: // mouse up
			DAP_AbortIfUnlocked(cba.win)
			DAG_Update(cba.win, cba.ctrlName, val = cba.checked)
			P_UpdatePressureDataStorageWv(cba.win)
			break
	endswitch

	return 0
End

Function P_ButtonProc_UserPressure(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	string userPressureDevice, panelTitle
	variable hardwareType, deviceID, ADC, flags

	switch(ba.eventCode)
		case 2: // mouse up
			panelTitle = ba.win

			DAP_AbortIfUnlocked(panelTitle)

			WAVE pressureDataWv = P_GetPressureDataWaveRef(panelTitle)
			userPressureDevice = DAG_GetTextualValue(panelTitle, "popup_Settings_UserPressure")

			if(!cmpstr(ba.ctrlName, "button_Hardware_PUser_Enable"))

				if(!cmpstr(userPressureDevice, NONE))
					break
				endif

				ADC = str2num(DAG_GetTextualValue(panelTitle, "Popup_Settings_UserPressure_ADC"))

				deviceID = HW_OpenDevice(userPressureDevice, hardwareType)
				HW_RegisterDevice(panelTitle, hardwareType, deviceID, pressureDevice=userPressureDevice)

				pressureDataWv[][%UserPressureDeviceID]     = deviceID
				pressureDataWv[][%UserPressureDeviceHWType] = hardwareType
				pressureDataWv[][%UserPressureDeviceADC]    = ADC

				DisableControls(panelTitle, "popup_Settings_UserPressure;Popup_Settings_UserPressure_ADC;button_Hardware_PUser_Enable")
				EnableControls(panelTitle, "button_Hardware_PUser_Disable")

			elseif(!cmpstr(ba.ctrlName, "button_Hardware_PUser_Disable"))

				// the same device can be used for pressure control and user pressure control
				if(!P_DeviceIsUsedForPressureCtrl(panelTitle, userPressureDevice))
					// the device is the same for all headstages
					deviceID = pressureDataWv[0][%UserPressureDeviceID]
					hardwareType = pressureDataWv[0][%UserPressureDeviceHWType]
					HW_CloseDevice(deviceID, hardwareType, flags = HARDWARE_PREVENT_ERROR_POPUP | HARDWARE_PREVENT_ERROR_MESSAGE)
					HW_DeRegisterDevice(deviceID, hardwareType)
				endif

				pressureDataWv[][%UserPressureDeviceID]     = NaN
				pressureDataWv[][%UserPressureDeviceHWType] = NaN
				pressureDataWv[][%UserPressureDeviceADC]    = NaN

				DisableControls(panelTitle, "button_Hardware_PUser_Disable")
				EnableControls(panelTitle, "popup_Settings_UserPressure;Popup_Settings_UserPressure_ADC;button_Hardware_PUser_Enable")
			else
				ASSERT(0, "Invalid ctrl")
			endif
			break
	endswitch

	return 0
End

/// @brief Runs P_PressureControl if the TP is OFF
Function P_RunP_ControlIfTPOFF(panelTitle)
	string panelTitle

	if(!TP_CheckIfTestpulseIsRunning(panelTitle)) // P_PressureControl will be called from TP functions when the TP is running
		P_PressureControl(panelTitle)
	endif
End

/// @brief If auto-user-OFF is checked, then user access is turned off
/// this function is run by the active headstage slider control
Function P_GetAutoUserOff(panelTitle)
	string panelTitle
	WAVE pressureDataWv = P_GetPressureDataWaveRef(panelTitle)

	WAVE GuiState = GetDA_EphysGuiStateNum(panelTitle)
	if(GuiState[0][%check_DataACq_Pressure_AutoOFF] && GuiState[0][%check_DataACq_Pressure_User])
		PGC_SetAndActivateControl(panelTitle,"check_DataACq_Pressure_User", val = CHECKBOX_UNSELECTED)
		GuiState[0][%check_DataACq_Pressure_User] = 0
	endif
End

/// @brief Sets the value of the headstage LED valDisplays to the correct cell in pressureType wave
static Function P_SetLEDValueAssoc(panelTitle)
	string panelTitle

	WAVE pressureType = GetPressureTypeWv(panelTitle)
	WAVE GuiState = GetDA_EphysGuiStateNum(panelTitle)

	String stringPath = GetWavesDataFolder(PressureType, 2)
	String pathAndCell, controlName
	variable i, col

	for(i = 0; i < NUM_HEADSTAGES;i += 1)
		sprintf pathAndCell, "%s[%d]" stringPath, i
		controlName = stringfromlist(i, PRESSURE_CONTROL_LED_DASHBOARD)
		SetValDisplay(panelTitle, controlName, str=pathAndCell)
	endfor
	
	stringPath = GetWavesDataFolder(GuiState, 2)
	for(i = 0; i < 4; i += 1)
		controlName = stringFromList(i,PRESSURE_CONTROL_USER_CHECBOXES)
		col = FindDimlabel(GuiState, COLS, controlName)
		sprintf pathAndCell, "%s[0][%d]" stringPath, col
		controlName = stringFromList(i,PRESSURE_CONTROL_LED_MODE_USER)
		SetValDisplay(panelTitle, controlName, str=pathAndCell)
	endfor
End

/// @brief Encodes the pressure type for each headstage
///
/// See also @ref PressureTypeConstants
Function P_UpdatePressureType(panelTitle)
	string panelTitle

	variable headstage

	WAVE pressureType = GetPressureTypeWv(panelTitle)
	WAVE pressureDataWv = P_GetPressureDataWaveRef(panelTitle)
	// Encode atm pressure mode
	pressureType[] = pressureDataWv[p][0] == PRESSURE_METHOD_ATM ? PRESSURE_TYPE_ATM : pressureType[p]
	// Encode automated pressure modes
	pressureType[] = pressureDataWv[p][0] >= PRESSURE_METHOD_APPROACH && pressureDataWv[p][0] <= PRESSURE_METHOD_CLEAR ? PRESSURE_TYPE_AUTO : pressureType[p]
	// Encode manual pressure mode
	pressureType[] = pressureDataWv[p][0] == PRESSURE_METHOD_MANUAL ? PRESSURE_TYPE_MANUAL : pressureType[p]
	// Encode user access
	headstage = pressureDataWv[0][%userSelectedHeadStage]
	pressureType[headstage] = P_GetUserAccess(panelTitle, headstage, pressureDataWv[headstage][0]) == ACCESS_USER ? PRESSURE_TYPE_USER : PressureType[headstage]
	// Encode headstages without valid pressure settings
	pressureType[] = P_ValidatePressureSetHeadstage(panelTitle, p) == 1 ? pressureType[p] : NaN
End
