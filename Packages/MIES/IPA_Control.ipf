// Copyright Sutter Instrument Corp. 2015 - 2026
// Modified November 5, 2026 TG
// ---------------- Pragmas ----------------
#pragma IgorVersion = 8.00						// Require Igor version 8.0 or later for compatbility
#pragma rtGlobals=3									// Use modern global access method and strict wave access.
#pragma ModuleName = IPAControl 				//This will become an independent module

Static Strconstant AmpPath = "root:SutterIPA"							
Static Constant IPA_StructVersion = 100
Static StrConstant 	kIPAPrefsFileName = "IPAControl.bin"
Static Constant kIPAPrefsRecordID = 0	
Static StrConstant ksPackageName = "SutterIPA"

Static Constant TRUE = 1
Static Constant FALSE = 0
Static Constant SutterXOP_XOPVersion = 2.87			// SutterXOP major version number needs to match SutterPatch, minor version is for info only

Static Constant kLiveMode = -1
Static Constant kNoDevice = 255 // ampIndex and HSIndex are uchar, so -1 would be stored as 255
Static Constant kIPASingle = 1
Static Constant kIPADouble = 2
Static Constant kSutterInterface = 4
Static Constant kMaxDigBits = 8
Static Constant kMaxAmplifiers = 4
Static Constant kMaxHeadstages = 8 //(2 double IPA * max amplifiers) 

Static Constant kCC_deltaCap = 1.4  // CC circuit has 1.4 pF more headstage capacitance.
Static Constant kStabilityControl = 1  //pF moved to prefs

// Valid range of the offset DAC value (2^16/V), the amplifier ignores +16384
Static Constant kOffsetMin = -16384
Static Constant kOffsetMax = 16383

Static StrConstant IGainList = "0.5;1;2.5;5;10;25;"
Static StrConstant VGainList = "10;20;50;100;200;500;"
Static StrConstant FilterList ="500;1000;2000;5000;10000;20000;"

Static Constant VID_Sutter = 0x1342			// Sutter's main manufacture VID
Static Constant PID_DPatch = 0x0500			// dPatch
Static Constant PID_IPA = 0x0400			// IPA

Static StrConstant kIPAStr = "IPA"
Static StrConstant kDIPAStr = "Double IPA"

//-------------------Structure to store amplifier values ------------------------

static STRUCTURE ControlValues
	uchar vc			//VC - CC - I=0
	uchar filter		//Output Filter
	uchar gainvc		//VC Gain
	uchar gaincc		//CC Gain 
	uchar seal		//Seal Test on
	int16 offset		//Offset value
	uchar offsetlock//Offset lock
	float LJP			//Liquid Junction Potential
	float hpot		//Holding potential
	uchar hpoton		//Holding potential checked
	float hcurr		//Holding current
	uchar hcurron	//Holding current checked
	float fastmag	//Electrode Compensation mag
	float fastphase	//Electrode Compensation phase
	uchar compon		//Cell Compensation on
	float rscomp		//Cell Compensation Rs
	float cmcomp		//Cell Compensation Cm
	uchar corron		//Rs Correction on
	uchar rscorr		//Correction %
	uchar lag			//Correction lag
	uchar rspred		//Prediction %
	uchar capneuton	//Cap Neut on
	float bridge		//Bridge Balance
	uchar bridgeon	//bridge balance on
	uchar trackon 	// Tracking on
	float track		//Tracking potential

	char DACOffset  //For Trimming DAC... this is only necessary in rare cases.
	uchar ampIndex
	uchar hsIndex
	double vmon
	double imon
EndStructure

static Structure AmpControls
	double analogOut[2]		//Aux out
	double analogIn[4]	//Aux In
	uchar amptype	//amplifier type
	char serialNum[13]	//serial number
	uchar dout		//Digital Output (1-8)
EndStructure

static Structure IPAControls
	uchar version
	struct ControlValues HS[8] //max headstages
EndStructure

static Structure IPASeries
	struct IPAControls ipa
	struct AmpControls Amp[4] // max amplifiers
	uchar activeHS
	uchar numHeadstages
	uchar numAmps
EndStructure	

static Constant Sutter_DeviceListVersion = 101
static Constant Sutter_MaxDeviceListEntrie = 16
static Constant Sutter_DeviceSerialNumberSize = 64

static Structure Sutter_SerialNumberStruct
	uchar s[ Sutter_DeviceSerialNumberSize ]
EndStructure

static Structure Sutter_AmpListStruct
    uint32 VendorID
    uint32 ProductID[ Sutter_MaxDeviceListEntrie ]
    uint32 EntryID[ Sutter_MaxDeviceListEntrie ]
    uint32 EntryIndex[ Sutter_MaxDeviceListEntrie ]
    uint32 EntryAvailable[ Sutter_MaxDeviceListEntrie ]
	Struct Sutter_SerialNumberStruct EntrySerialNo[ Sutter_MaxDeviceListEntrie ]
    uint32 EntriesFound
    uint32 DeviceListVersion
EndStructure


Static Function SP_IsWindows()
#ifdef WINDOWS
	return TRUE
#else
	return FALSE
#endif
End

Static Function Sutter_GetDevicesListEntry(
	Struct Sutter_AmpListStruct &DeviceList,
	Variable Target_PID,
	Variable StartIndex )

	Variable i
	for( i = StartIndex; i < DeviceList.EntriesFound; i++ )
		if( SP_IsWindows() || DeviceList.EntryAvailable[ i ] )
			if( DeviceList.EntryID[ i ] == Target_PID )
				return i
			EndIf
		EndIf
	EndFor
	return -1
End

// This function gets a list of Sutter Amplifiers connected to the USB bus inclusing their serial numbers.
// Based on the serial number we can distinquish between an IPA, Double IPA or Dendrite interface
// This code is only intrested in IPA and Douple IPA amplifiers
// If the device was already opened, then it will not be shown on the list as it is locked 
Static Function Sutter_GetDevicesList( Struct Sutter_AmpListStruct &DeviceList )
	Variable i
	for( i = 0; i < Sutter_MaxDeviceListEntrie; i++ )
		DeviceList.ProductID[ i ] = 0
	EndFor
	DeviceList.VendorID = VID_Sutter
	DeviceList.ProductID[ 0 ] = PID_DPatch
	DeviceList.ProductID[ 1 ] = PID_IPA
	DeviceList.EntriesFound = 0
	DeviceList.DeviceListVersion = Sutter_DeviceListVersion

#if exists( "Sutter_GetListOfDevices" )
	Sutter_GetListOfDevices( DeviceList )
#endif

	return DeviceList.EntriesFound
End

// Get a list of serial numbers to use with IPA_Connect
Static Function/S Sutter_GetIPASerialNumberList( Struct Sutter_AmpListStruct &DeviceList)
	String dev_list = ""
	if (DeviceList.EntriesFound > 0)
		//IPA and DoubleIPA use the same PID
		Variable target_entry = Sutter_GetDevicesListEntry( DeviceList, PID_IPA, 0 )
		if( target_entry < 0 )
			//no IPA devices
			return dev_list
		EndIf

		String serial_number
		do
			serial_number = DeviceList.EntrySerialNo[ target_entry ].s
			switch (IPA_DeviceTypeFromSerialNumber( serial_number ) )
				case kIPASingle:
				case kIPADouble:
					dev_List += serial_number + ";"
					break
			endswitch
			target_entry = Sutter_GetDevicesListEntry( DeviceList, PID_IPA, target_entry + 1 )
		while( target_entry > 0 )
	endif
	
	return dev_list
End			

// Get the number of IPA series amplifiers that are connected to the USB bus
Static Function Sutter_GetNumIPAConnected( Struct Sutter_AmpListStruct &DeviceList)
	Variable num_ipa = 0
	if (DeviceList.EntriesFound > 0)
		//IPA and DoubleIPA use the same PID
		Variable target_entry = Sutter_GetDevicesListEntry( DeviceList, PID_IPA, 0 )
		if( target_entry >= 0 )
			String serial_number
			do
				serial_number = DeviceList.EntrySerialNo[ target_entry ].s
				switch (IPA_DeviceTypeFromSerialNumber( serial_number ) )
					case kIPASingle:
					case kIPADouble:
						num_ipa+=1
				endswitch
				target_entry = Sutter_GetDevicesListEntry( DeviceList, PID_IPA, target_entry + 1 )
			while( target_entry > 0 )
		endif
	endif
	
	return num_ipa
End			

//use a string match to determine the IPA series device type
Static Function IPA_DeviceTypeFromSerialNumber( String SerialNumber )
	// serial numbers are:
	//    IPA = “IPA/E-1*”
	//    DIPA = “IPA/E-2*
	//    Dendrite = “DAQ*”
	if( stringmatch( SerialNumber, "IPA/E-1*" ) )
		return kIPASingle
	elseif( stringmatch( SerialNumber, "IPA/E-2*" ) )
		return kIPADouble
	elseif( stringmatch( SerialNumber, "DAQ/E-*" ) )
		return kSutterInterface
	endif
	return 0
End

//connect a single device by serial number match or all connected
Static Function IPA_ConnectToDevice(
	Struct Sutter_AmpListStruct &DeviceList,
	Variable UseSerialNo,
	String TargetSerialNo,
	Variable TargetDevice,
	String &ErrorMessage )	
	
	ErrorMessage = ""
	// start with the first IPA device found on the device list
	String serial_number
	Variable num_amps

	Variable target_entry = Sutter_GetDevicesListEntry( DeviceList, PID_IPA, 0 )
	if( target_entry < 0 )
		return FALSE
	EndIf

	// Igor code:
	//		Switch( TargetDevice )
	//			case 0:		// first hardware found
	//			case 1:		// IPA or DIPA
	//			case 2:		// dPatch
	//			case 3:		// dendrite
	//		EndSwitch
	// SutterXOP code, argument of SutterDAQUSBReset:
	//		1 => don't care: IPA or dendrite; 2 = IPA only; 3 => Dendrite only

	Variable ampl_kind = 1
	String name_match = "IPA*"
	if( TargetDevice == 1 )
		ampl_kind = 2
	EndIf

	// connect to the device and
	// - use the serial number to discriminate between IPA and Dendrite
	// - if requested, ensure the correct serial number.
	do
		serial_number = DeviceList.EntrySerialNo[ target_entry ].s
		// check whether this device is either a IPA or Double IPA
		if( stringmatch( serial_number, name_match ) )
			// check whether this device serial number is equal to the target serial number, if required
			if( ( ! UseSerialNo ) || ( cmpstr( serial_number, TargetSerialNo ) == 0 ) )
				num_amps = SutterDAQUSBReset( DeviceList.EntryIndex[ target_entry ], ampl_kind )
				if( num_amps > 0 )
					return num_amps
				endif
			EndIf
		EndIf
		target_entry = Sutter_GetDevicesListEntry( DeviceList, PID_IPA, target_entry + 1 )
	while( target_entry > 0 )

	if( UseSerialNo )
		ErrorMessage = "Connect to IPA with serial number" + TargetSerialNo + " not found."
	endif
	
	return FALSE
End


static Function SetBit( Variable Bit, Variable BitSet )
	return BitSet | ( 1 << Bit )
End


static Function ClearBit( Variable Bit, Variable BitSet )
	return BitSet & ~( 1 << Bit )
End


static Function IPA_GetDigOutWordChannel(Variable ampType)
	switch (ampType)
		case kIPASingle:
			return 3
			break
		case kIPADouble:
		case kSutterInterface:
			return 4
			break
	endswitch	
End


static Function IPA_GetHSHardwareOutChannel(Variable probeIndex)
	Struct IPASeries SIPA
	GetStructure(SIPA)	
	
	if (SIPA.numAmps > 0)
		if (SIPA.ipa.HS[probeIndex].HSIndex == 0)
			return 0
		else
			return 1
		endif
	endif
		
	return kNoDevice
End


static Function IPA_GetHSHardwareInChannel(Variable probeIndex, Variable isCurrent)
	Struct IPASeries SIPA
	GetStructure(SIPA)	
	
	if (SIPA.numAmps > 0)
		if (SIPA.ipa.HS[probeIndex].HSIndex == 0)
			if (isCurrent)
				return 0
			else
				return 1
			endif
		else
			if (isCurrent)
				return 2
			else
				return 3
			endif
		endif
	endif
		
	return kNoDevice
End


static Function IPA_GetAmpAuxInChannel(Variable amplIndex, Variable auxIndex)
	Struct IPASeries SIPA
	GetStructure(SIPA)	

	if ((auxIndex < 0) || (auxIndex > 3))
		return kNoDevice
	endif
	
	if (SIPA.numAmps > 0)
		Variable startChannel
		if (SIPA.amp[amplIndex].ampType == kIPASingle)
			startChannel = 2
		else
			startChannel = 4
		endif
		return (startChannel+auxIndex)
	endif
		
	return kNoDevice
End


static Function IPA_GetAmpAuxOutChannel(Variable amplIndex, Variable auxIndex)
	Struct IPASeries SIPA
	GetStructure(SIPA)	

	if ((auxIndex < 0) || (auxIndex > 2))
		return kNoDevice
	endif
	
	if (SIPA.numAmps > 0)
		Variable startChannel
		if (SIPA.amp[amplIndex].ampType == kIPASingle)
			startChannel = 1
		else
			startChannel = 2
		endif
		return (startChannel+auxIndex)
	endif
		
	return kNoDevice
End


static Function/S IPA_GetAmpHSOutWaveStr(Variable probeIndex)
	Struct IPASeries SIPA
	GetStructure(SIPA)	
	
	if (SIPA.numAmps == 0)
		return ""
	endif
	
	string waveStr = "0" + num2istr(SIPA.ipa.HS[probeIndex].ampIndex) //amp index
	waveStr+= "0" + num2istr(SIPA.amp[SIPA.ipa.HS[probeIndex].ampIndex].ampType) //amptype
	waveStr+= "0" + num2istr(SIPA.ipa.HS[probeIndex].HSIndex) //hs index based on amplifier 
	
	if (SIPA.ipa.HS[probeIndex].HSIndex == 0)
		waveStr+= "00"
	else
		waveStr+= "01"
	endif
	
	return waveStr
End


static Function/S IPA_GetAmpHSInWaveStr(Variable probeIndex, Variable isCurrent)
	Struct IPASeries SIPA
	GetStructure(SIPA)	
	
	if (SIPA.numAmps == 0)
		return ""
	endif
	
	string waveStr = "0" + num2istr(SIPA.ipa.HS[probeIndex].ampIndex) //amp index
	waveStr+= "0" + num2istr(SIPA.amp[SIPA.ipa.HS[probeIndex].ampIndex].ampType) //amptype
	waveStr+= "0" + num2istr(SIPA.ipa.HS[probeIndex].HSIndex) //hs index based on amplifier 
	
	if (SIPA.ipa.HS[probeIndex].HSIndex == 0)
		if (isCurrent)
			waveStr+= "00"
		else
			waveStr+= "01"
		endif
	else
		if (isCurrent)
			waveStr+= "02"
		else
			waveStr+= "03"
		endif
	endif
	
	return waveStr
End

static Function/S IPA_GetAmpAuxInWaveStr(Variable amplIndex, Variable auxIndex)
	Struct IPASeries SIPA
	GetStructure(SIPA)	
	
	if ((amplIndex < 0) || (amplIndex > SIPA.numAmps)) 
		return ""
	endif

	if ((auxIndex < 0) || (auxIndex > 3))
		return ""
	endif
	
	string waveStr = "0" + num2istr(amplIndex) //amp index
	waveStr+= "0" + num2istr(SIPA.amp[amplIndex].ampType) //amptype
	waveStr+= "-1" //no hs index
	
	if (SIPA.amp[amplIndex].ampType == kIPASingle)
		waveStr+= "0" + num2istr(2+auxIndex)
	else
		waveStr+= "0" + num2istr(4+auxIndex)
	endif
	
	return waveStr
End


static Function/S IPA_GetAmpAuxOutWaveStr(Variable amplIndex, Variable auxIndex, Variable isDigOut)
	Struct IPASeries SIPA
	GetStructure(SIPA)	
	
	if ((amplIndex < 0) || (amplIndex > SIPA.numAmps)) 
		return ""
	endif

	if ((auxIndex < 0) || (auxIndex > 2))
		return ""
	endif
	
	string waveStr = "0" + num2istr(amplIndex) //amp index
	waveStr+= "0" + num2istr(SIPA.amp[amplIndex].ampType) //amptype
	waveStr+= "-1" //no hs index
	
	if (SIPA.amp[amplIndex].ampType == kIPASingle)
		if (isDigOut)
			waveStr+= "03"
		else
			waveStr+= "0" + num2istr(1+auxIndex)
		endif
	else
		if (isDigOut)
			waveStr+= "04"
		else
			waveStr+= "0" + num2istr(2+auxIndex)
		endif
	endif
	
	return waveStr
End


//-------------------Structure to store amplifier values ------------------------
//safe the last control states
static Function SaveControls(Struct IPAControls &ipa)	
	SavePackagePreferences /FLSH=1 ksPackageName, kIPAPrefsFileName, kIPAPrefsRecordID, ipa
End


//load last control states
static Function GetControls(Struct IPAControls &ipa)
	LoadPackagePreferences /MIS=1 ksPackageName, kIPAPrefsFileName, kIPAPrefsRecordID, ipa
	
	// If error or prefs not found or not valid, initialize them.
	if (V_flag != 0 || V_bytesRead == 0 || ipa.version != IPA_StructVersion )
		IPA_InitAllControls(ipa)
	endif
End


static Function IPA_InitAllControls(Struct IPAControls &ipa)
	Variable hsindex
	ipa.version = IPA_StructVersion
	for (hsIndex=0; hsIndex<kMaxHeadstages; hsIndex+=1)
		IPA_InitProbeControls(ipa,hsindex)
	endfor
	IPA_GetDACOffset()
End


static Function IPA_InitProbeControls(Struct IPAControls &ipa, Variable hsindex)
	if ( ( hsindex < 0 ) || ( hsindex >= kMaxHeadstages ) )
		return FALSE
	endif
	
	ipa.hs[hsindex].gainvc = 3
	ipa.hs[hsindex].gaincc = 3
	ipa.hs[hsindex].filter = 3
	ipa.hs[hsindex].lag = 20
	ipa.hs[hsindex].capneuton = 0
	ipa.hs[hsindex].hpoton = 0
	ipa.hs[hsindex].hcurron = 0
	ipa.hs[hsindex].fastphase = 0.1
	ipa.hs[hsindex].vc = 0
	ipa.hs[hsindex].seal	= 0	
	ipa.hs[hsindex].offset = 0.0
	ipa.hs[hsindex].offsetlock = 0
	ipa.hs[hsindex].LJP = 0.0
	ipa.hs[hsindex].hpot = 0.0
	ipa.hs[hsindex].hcurr = 0.0
	ipa.hs[hsindex].fastmag = 0.1
	ipa.hs[hsindex].compon = 0
	ipa.hs[hsindex].rscomp = 0
	ipa.hs[hsindex].cmcomp = 0
	ipa.hs[hsindex].corron = 0
	ipa.hs[hsindex].rscorr = 0
	ipa.hs[hsindex].rspred = 0
	ipa.hs[hsindex].capneuton = 0
	ipa.hs[hsindex].bridge = 0.0
	ipa.hs[hsindex].bridgeon	 = 0
	ipa.hs[hsindex].trackon = 0
	ipa.hs[hsindex].track = 0.0
	
	return TRUE
End

//get struct string path
static Function /S Get_StructPath()
	return AmpPath + ":SD_Struct"
End


//the struct string exists between IPA_Initialize and IPA_Shutdown
static Function IsInitialized()
	SVar/Z SD_Struct = $(Get_StructPath())
	return SVAR_Exists(SD_Struct)
End


//get the local structure
static Function GetStructure(Struct IPASeries &SIPA)
	SVAR SD_Struct = $(Get_StructPath())
	StructGet /S SIPA, SD_Struct
End


//save the local structure
static Function SaveStructure(Struct IPASeries &SIPA)
	SVAR SD_Struct = $(Get_StructPath())
	StructPut /S SIPA, SD_Struct
End


//init the local structure
static Function IPA_InitMainStructure(Struct IPASeries &SIPA)	
	Variable index = 0
	Variable hsindex = 0

	Struct Sutter_AmpListStruct device_list
	Variable total_devices = Sutter_GetDevicesList( device_list )	
	Variable isdemoMode = FALSE

	NVAR demo_amptype = $(AmpPath + ":demo_amptype")
	
	if (total_devices == 0)
		isdemoMode = TRUE
	else
		//if using serial numbers need code to select a device serial number and then store it
		//for now we will load all connected IPA / Double IPA devices 
		Variable use_serial_number = FALSE
		Variable target_device = 0 //all connected
		String target_serial_number = ""
		String error_message = ""
	
		SIPA.numHeadstages = 0
		SIPA.numAmps = 0
		Variable num_amps = IPA_ConnectToDevice( device_list, use_serial_number, target_serial_number, target_device, error_message)
		if (num_amps == 0)
			isdemoMode = TRUE
		else
			String serial_number = ""
			Variable amp_type
			Variable ampl_index = 0
			for (index=0; index<num_amps; index+=1)
				serial_number = SutterDAQSN( index )
				amp_type = IPA_DeviceTypeFromSerialNumber( serial_number )
				if (amp_type != kSutterInterface)
					SIPA.amp[index].serialNum = serial_number
					SIPA.amp[index].ampType = amp_type 
					SIPA.ipa.HS[hsIndex].ampIndex = ampl_index
					SIPA.ipa.HS[hsIndex].HSIndex = 0
					SIPA.numHeadstages+=1
					hsindex+=1
					if (amp_type == kIPADouble)
						SIPA.ipa.HS[hsIndex].ampIndex = ampl_index
						SIPA.ipa.HS[hsIndex].HSIndex = 1
						SIPA.numHeadstages+=1
						hsindex+=1
					endif
					ampl_index+=1
				endif
			endfor
			SIPA.numAmps = ampl_index
			if (SIPA.numAmps == 0)
				//no devices connected
				isdemoMode = TRUE
			endif
		endif
	endif
	
	if ( isdemoMode ) 
		//set up demo mode
		SIPA.numAmps = 1
		SIPA.numHeadstages = 1
		SIPA.amp[0].serialNum = "demo"
		SIPA.ipa.HS[0].ampIndex = 0
		SIPA.ipa.HS[0].HSindex = 0
		demo_amptype = kIPASingle
	else
		demo_amptype = kLiveMode
		NVAR SD_USB = $(AmpPath + ":SD_USB")
		SD_USB = SIPA.numAmps
	endif
	
	//reset all remaining none connected
	for (index=SIPA.numHeadstages; index<kMaxHeadstages; index+=1)
		SIPA.ipa.HS[index].ampIndex = kNoDevice
		SIPA.ipa.HS[index].HSindex = kNoDevice
	endfor
	
	SaveStructure(SIPA)
	
	return TRUE
End

static Function/S IPA_GetActiveSNList()
	//this list is for device that were opened
	Struct IPASeries SIPA
	GetStructure(SIPA)	

	Variable index
	String active_list = ""
	for (index=0; index<SIPA.numAmps ; index+=1)
		active_list += SIPA.amp[index].serialNum + ";"
	endfor
	
	return active_list
End 


static Function IPA_ActivateHeadstage(	Struct IPASeries &SIPA, Variable HSindex)
	DFREF dfr=$AmpPath
	NVar SD_DIO = dfr:SD_DIO

	SIPA.activeHS = HSindex
	Variable ampindex = SIPA.ipa.hs[HSindex].ampIndex
	SD_DIO = SIPA.Amp[ampIndex].dout
End


static Function Sutter_CheckXOPVersion(Variable showDialog)
	String message = "SutterXOP_Win.xop"
	Variable xop_Status = FALSE
#if exists( "SutterXOP_GetXOPVersion" )
	Variable major_version = 0
	Variable minor_version = 0
	SutterXOP_GetXOPVersion( major_version, minor_version )

	if( major_version == SutterXOP_XOPVersion )
		message = ""
		xop_status = TRUE
	else
		String xop_version = ""
		String need_version = ""

		sprintf xop_version, "%.2f", major_version
		sprintf need_version, "%.2f", SutterXOP_XOPVersion

		// the total message length cannot exceed 253 bytes
		message += \
			"\r\r" + \
			"The loaded SutterXOP version is: " + xop_version + "\r" + \
			"which is incompatible with this code.\r" + \
			"Expected version is: " + need_version
	EndIf
#else
	message += "\r\rThe SutterXOP was not found or is faulty and cannot be used."
#endif

	if ( (showDialog) && ( strlen( message ) > 0 ) )
		DoAlert /T=( "XOP Error" ) 0, message
	EndIf

	return xop_status
End


Function IPA_DoInitialize()
	if (Sutter_CheckXOPVersion(FALSE) == TRUE)
		NewDataFolder /O $(AmpPath)	
		DFREF dfr=$AmpPath
		variable /G $(AmpPath + ":SD_Seal") = 0
		variable /G $(AmpPath + ":SD_USB") = 0
		variable /G $(AmpPath + ":SD_DIO") = 0
		variable /G $(AmpPath + ":SD_sweeptime") = 0
		variable /G $(AmpPath + ":demo_amptype") = kIPASingle	
		variable /G $(AmpPath + ":LibUSBError") = 0

		Make /D/O/n=(8,kMaxAmplifiers) $(AmpPath + ":SD_Meter") = 0
		//SD_Meter column is amplifier index
		//row 0 = IMon headstage 0
		//row 1 = VMon headstage 0
		//row 2 = IMon headstage 1 only for Double IPA
		//row 3 = VMon headstage 1 only for Double IPA
		//row 4 = AuxIn1
		//row 5 = AuxIn2
		//row 6 = AuxIn3
		//row 7 = AuxIn4
		String /G $(AmpPath + ":SD_Struct") = ""
 
	 	Struct IPASeries SIPA
		GetStructure(SIPA)	
 		IPA_InitMainStructure(SIPA)
 		IPA_ResetAmplifier(SIPA)
		SutterDAQreset()
		SutterDAQUseWaveModify( TRUE )
 		
 		IPA_StartTimerTask()
 		return TRUE
	endif
	
	return FALSE
End


Function IPA_DoShutdown()
	if (IsInitialized() == FALSE)
		return FALSE
	endif

	IPA_StopTimerTask()
	Struct IPASeries SIPA
	GetStructure(SIPA)
	SaveControls(SIPA.ipa)
	
	//close USB connection
	if ( IPA_OkToSendCommand() )
		SutterDAQUSBClose()
	endif
	
	//kill data folder and all SVAR and NVAR
	KillDataFolder/Z $(AmpPath)	
	
	return TRUE
End


static Function IPA_DemoMode()
	NVAR/Z demo_amptype = $(AmpPath + ":demo_amptype")
	if ((!NVAR_Exists(demo_amptype)) || (demo_amptype != kLiveMode))
		return TRUE
	endif
	
	return FALSE 
End


static Function IPA_OkToSendCommand()
	if (IPA_DemoMode() == TRUE)
		return FALSE
	else
		return IPA_USBconnected()
	endif
End


static Function IPA_USBconnected()
	Variable usbConnected
	NVar/Z SD_USB = $(AmpPath + ":SD_USB")
	
	if (nvar_exists(SD_USB) == FALSE)
		usbConnected = FALSE
	elseif (SD_USB == 0)
		usbConnected = FALSE
	else
		usbConnected = TRUE //SD_USB returns number of connected devices 
	endif
	
	return usbConnected
End


static Function IPA_ResetUSB()
	SutterDAQReset()
	if( SutterDAQUSBReset( 0, 0 ) > 0 )
		NVar/Z LibUSBError = $(AmpPath + ":LibUSBError")
		LibUSBError = 0
		Struct IPASeries SIPA
		GetStructure(SIPA)
		IPA_ResetAmplifier(SIPA)
	endif
End


static Function IPA_ResetAmplifier(Struct IPASeries &SIPA)
	if (IPA_OkToSendCommand() == TRUE)
		IPA_SetDacOffset(SIPA)	
		variable step
		variable ampindex
		for (ampindex=0; ampindex<SIPA.numAmps;ampindex+=1)
			sutterdaqwrite(ampindex,11,0,0,3)		//Some dIPAs don't set default filter correctly first time (firmware 207 and earlier)
		endfor
		
		for (step=0; step<SIPA.numHeadstages; step++)
			 IPA_SetFromStructure(SIPA,step)			//This sets amplifier control panel based on stored structure.
		endfor
		IPA_ResetAllOutputs(SIPA) 			// This resets digital and analog aux outs
	endif	
End


static Function IPA_ResetAllOutputs(Struct IPASeries &SIPA)	
	Variable ampIndex
	Variable v_value
	variable step
	
	for (ampindex=0; ampindex<SIPA.numAmps;ampindex+=1)
		v_value = SIPA.amp[ampindex].analogOut[0] * 3276.7
		SutterDAQwrite(ampindex,17,2, (v_value&0xff00)/256,v_value&0x00ff)  	//AuxOUT1
	
		v_value = SIPA.amp[ampindex].analogOut[1] * 3276.7
		SutterDAQwrite(ampindex,17,3, (v_value&0xff00)/256,v_value&0x00ff)	//AuxOUT2
	
		v_value = SIPA.amp[ampindex].dout
		for (step=0; step<8; step+=1)		//Digital OUT 
			if (v_value & 2^step)
				SutterDAQwrite(ampindex,22,0,step,1)
			else
				SutterDAQwrite(ampindex,22,0,step,0)
			endif
		endfor
	endfor
		
	Return TRUE
End


static Function IPA_SetCompensation(Struct IPASeries &SIPA, variable probeIndex)  // This sets the Rs Cm compensation along with Rs Prediction %  (all are related)
	if (IPA_OkToSendCommand() == FALSE)
		return FALSE
	endif
	
	if (probeIndex < 0)
		return FALSE
	endif

	if (probeIndex >= SIPA.numHeadstages)
		return FALSE
	endif

	Variable Amp = SIPA.ipa.hs[probeIndex].ampIndex
	if (Amp == kNoDevice)
		return FALSE
	endif
	
	Variable HS = SIPA.ipa.hs[probeIndex].HSIndex
	Variable tau_set, Pred, cp_set, alpha, rs_val, cp_val,CompOn, CorrOn
	
	CompOn = SIPA.ipa.hs[probeIndex].compon * !SIPA.ipa.hs[probeIndex].vc
	CorrOn = SIPA.ipa.hs[probeIndex].corron
	alpha = CorrOn * SIPA.ipa.hs[probeIndex].rspred/100
	cp_val = SIPA.ipa.hs[probeIndex].cmcomp
	rs_val = SIPA.ipa.hs[probeIndex].rscomp
	
	tau_set = round((1-alpha)*rs_val*cp_val*.752942) //.0939794) //.752942)
	Pred = !SIPA.ipa.hs[probeIndex].vc * CorrOn*floor(163.84*alpha/(1-alpha))	//Rev G:   scaling is now alpha/(1-alpha) 
	cp_set = CompOn*floor(cp_val*163.84) // 327.68 for 5 pf ci.  for 10 pf multiply by 163.84  Rev F has x2 gain(which allows up to 100pF), so 163.84
		
	if (HS) //second headstage on DIPA
		SutterDAQwrite(Amp,23,6,(tau_set&0xff00)/256,tau_set&0x00ff)
		SutterDAQwrite(Amp,23,7,(cp_set&0xff00)/256,cp_set&0x00ff)
		SutterDAQwrite(Amp,23,9,(Pred&0xff00)/256,Pred&0x00ff)
	else
		SutterDAQwrite(Amp,2,6,(tau_set&0xff00)/256,tau_set&0x00ff)
		SutterDAQwrite(Amp,2,7,(cp_set&0xff00)/256,cp_set&0x00ff)
		SutterDAQwrite(Amp,2,9,(Pred&0xff00)/256,Pred&0x00ff)
	endif
End


static Function IPA_SetCorrection(Struct IPASeries &SIPA, variable probeIndex)
	if (IPA_OkToSendCommand() == FALSE)
		return FALSE
	endif
	
	if (probeIndex < 0)
		return FALSE
	endif

	if (probeIndex >= SIPA.numHeadstages)
		return FALSE
	endif

	Variable Amp = SIPA.ipa.hs[probeIndex].ampIndex
	if (Amp == kNoDevice)
		return FALSE
	endif
	
	Variable HS = SIPA.ipa.hs[probeIndex].HSIndex
	if (HS == kNoDevice)
		return FALSE
	endif

	variable CorrOn, rs_val, cm_val, setval

	setval = 0
	if (!SIPA.ipa.hs[probeIndex].vc)   //ipa.vc = 2 for cc, 0 for vc
		setval=round(SIPA.ipa.hs[probeIndex].corrOn * SIPA.ipa.hs[probeIndex].rscorr * SIPA.ipa.hs[probeIndex].rscomp*1.6383)    //product of Rs corr% AND Rs
	endif
	if (HS)
		SutterDAQwrite(Amp,23,8,(setval&0xff00)/256,setval&0x00ff)
	else		
		SutterDAQwrite(Amp,2,8,(setval&0xff00)/256,setval&0x00ff)
	endif
End


static Function IPA_SetFromStructure(Struct IPASeries &SIPA, variable probeIndex)  
// THIS IS CALLED ON STARTUP AND EACH TIME WE SWITCH HS
	if (IPA_OkToSendCommand() == FALSE)
		return FALSE
	endif
	
	if (probeIndex < 0)
		return FALSE
	endif

	if (probeIndex >= SIPA.numHeadstages)
		return FALSE
	endif

	Variable Amp = SIPA.ipa.hs[probeIndex].ampIndex
	if (Amp == kNoDevice)
		return FALSE
	endif
	
	Variable HS = SIPA.ipa.hs[probeIndex].HSIndex
	if (HS == kNoDevice)
		return FALSE
	endif
	
	variable setval
	
	//Different SutterDAQ command for first and second headstage on a dIPA
	//Channel 1 of dIPA is controlled exactly the same as IPA.   So if HS=0; no need to test for amptype.
	variable Cmd = 2
	if (HS)
		Cmd = 23
	endif

//1. Seal test off
	//Currently this is HS indepedent... need to update on dIPA firmware.
	SutterDAQWrite(Amp,18,0,10,10)	//Currently same for both HS
	SIPA.ipa.HS[probeIndex].seal = 0.0

//2. Set Offset
	setval = SIPA.ipa.HS[probeIndex].offset
	if (HS)
		SutterDAQwrite(Amp,17,4,(setval&0xff00)/256,setval&0x00ff)		
	else
		SutterDAQwrite(Amp,17,1,(setval&0xff00)/256,setval&0x00ff)			
	endif

//3. Turn on/off compensation
	if (SIPA.ipa.HS[probeIndex].vc==2)	//CC
		setval = round(SIPA.ipa.HS[probeIndex].bridge*81.92)*SIPA.ipa.HS[probeIndex].bridgeon //2^14/200 max range = 200 MOhm 
		SutterDAQwrite(Amp,Cmd,5,(setval&0xff00)/256,setval&0x00ff)	
	endif		
	
	//Fast Mag -- may allow a different value for CC?
	setval=round(SIPA.ipa.HS[probeIndex].fastmag*655.32)
	if (SIPA.ipa.HS[probeIndex].vc==2)
		IPA_ModifyCapMag(setval)
		if (SIPA.ipa.HS[probeIndex].capneuton == 0)
			setval=0
		endif
	endif		
	SutterDAQwrite(Amp,Cmd,2,(setval&0xff00)/256,setval&0x00ff)	
	
	//Fast Tau can stay on no matter what
	//setval=min(1023,round(ipa.fastphase*10.24))
	setval = round((SIPA.ipa.HS[probeIndex].fastphase-0.1)*1023/4.4)
	SutterDAQwrite(Amp,Cmd,1,(setval&0xff00)/256,setval&0x00ff)	

	//SRs Lag
	setval=min(1023,round(SIPA.ipa.HS[probeIndex].lag*5.12)) 	//Settings from 20 to 200  (us)
	setval=max(51,setval)
	SutterDAQwrite(Amp,cmd,10,(setval&0xff00)/256,setval&0x00ff) //14bit unsigned?
	
	//Rs corr% turns off in IC
	// setval is the product of Rs corr% AND Rs
	//SDsetvar4,SDsetvar5,SDsetvar17: Whole cell compensation turns off in IC
	//Rs can stay on, Pred value is OK, but need to switch off (SwCtrl2) Cm is off in IC

//THIS NEEDS TO BE HS SPECIFIC AND KNOW SWITCH BETWEEN VC AND CC!
 	IPA_SetCompensation(SIPA,probeIndex)
 	IPA_SetCorrection(SIPA,probeIndex)
	IPA_usdelay(2000)
//Short delay to insure injection capacitor is discharged prior to changing to CC
// We may only want this delay if we are going VC->CC

// Set Gain to 1 (for firmware versions <4)... This can cause glitch if acquisition is on, so 
// we will only change gain if not... 
 	if (HS)
		SutterDAQwrite(amp,23,12,0,0)   
	else
		SutterDAQwrite(amp,12,0,0,0)   
	endif
	SutterDAQread(amp,0)
	
//4. Switch to VC / IC    
	if (HS)
		SutterDAQwrite(amp,23,20,3,!SIPA.ipa.HS[probeIndex].vc)		//SmartSwitch on
	else
		SutterDAQwrite(amp,20,1,1,!SIPA.ipa.HS[probeIndex].vc)		//SmartSwitch on.
	endif

//5. Turn on holding i/v (if checked)
	if (SIPA.ipa.HS[probeIndex].vc == 0)  //VC
		setval = 32.767*SIPA.ipa.HS[probeIndex].hpot*SIPA.ipa.HS[probeIndex].hpoton
		SutterDAQwrite(amp,16,HS,(setval&0xff00)/256,setval&0x00ff)
	else
		if (SIPA.ipa.HS[probeIndex].trackon)
			setval = 32.767*SIPA.ipa.HS[probeIndex].track
			if (HS)
		 		SutterDAQwrite(amp,25,1,(setval&0xff00)/256,setval&0x00ff)
	 		else
				SutterDAQwrite(Amp,19,1,(setval&0xff00)/256,setval&0x00ff)
			endif
		else
			setval = 1.63834*SIPA.ipa.HS[probeIndex].hcurr*SIPA.ipa.HS[probeIndex].hcurron
			SutterDAQwrite(amp,16,HS,(setval&0xff00)/256,setval&0x00ff)
		endif
	endif

//6. Change to correct gain
	if(SIPA.ipa.HS[probeIndex].vc==0)  //VC
		setval = SIPA.ipa.HS[probeIndex].gainvc
	else
		setval = SIPA.ipa.HS[probeIndex].gaincc
	endif
	if (HS)
		SutterDAQwrite(amp,23,12,0,setval)   
	else
		SutterDAQwrite(amp,12,0,0,setval)   
	endif

//7. Set correct filter
	setval = 5-SIPA.ipa.HS[probeIndex].filter
	if (HS)
		SutterDAQwrite(amp,23,11,0,setval)   
	else
		SutterDAQwrite(amp,11,0,0,setval)
	endif
End


static Function IPA_ModifyCapMag (variable &Value)
	Value +=  (kCC_deltaCap - kStabilityControl)*655.32
	if (Value<0)
		Value = 0
	elseif (Value>16383)
		Value = 16383 
	endif
	
	return TRUE
end


static Function IPA_AutoWholeCellCompensation(Struct IPASeries &SIPA, Variable probeIndex) 
	if (IPA_OkToSendCommand() == FALSE)
		return FALSE
	endif
	
	if (probeIndex < 0)
		return FALSE
	endif

	if (probeIndex >= SIPA.numHeadstages)
		return FALSE
	endif

	Variable Amp = SIPA.ipa.hs[probeIndex].ampIndex
	if (Amp == kNoDevice)
		return FALSE
	endif
	
	Variable HS = SIPA.ipa.hs[probeIndex].HSIndex
	if (HS == kNoDevice)
		return FALSE
	endif
	variable capreturn, rsreturn
	
	SutterDAQWrite(Amp,1,0,0,100) //set sampling rate to 50 kHz

	SutterDAQwrite(Amp,13,HS,0,1)
	ipa_tickdelay(30)
	if (HS)
		capreturn = round(SutterDAQread(Amp,19)/16.384)/10
		if (capreturn==0)
			rsreturn = 0
		else
			rsreturn = round(SutterDAQread(Amp,18)*13.2812/capreturn)/10   //10x difference due to change in rc circuit
		endif	
	else
		capreturn = round(SutterDAQread(Amp,12)/16.384)/10
		if (capreturn==0)
			rsreturn = 0
		else
			rsreturn = round(SutterDAQread(Amp,11)*13.2812/capreturn)/10   //10x difference due to change in rc circuit
		endif	
	endif
	
	SIPA.ipa.HS[probeIndex].cmcomp = capreturn
	SIPA.ipa.HS[probeIndex].rscomp = rsreturn
	SIPA.ipa.HS[probeIndex].bridge = rsreturn
	SIPA.ipa.HS[probeIndex].compon = 1
	
	//if acquisition is running reset sampling rate
	return TRUE
End


static Function IPA_AutoElectrodeCompensation(Struct IPASeries &SIPA, Variable probeIndex)
	if (IPA_OkToSendCommand() == FALSE)
		return FALSE
	endif
	
	if (probeIndex < 0)
		return FALSE
	endif

	if (probeIndex >= SIPA.numHeadstages)
		return FALSE
	endif

	Variable Amp = SIPA.ipa.hs[probeIndex].ampIndex
	if (Amp == kNoDevice)
		return FALSE
	endif
	
	Variable HS = SIPA.ipa.hs[probeIndex].HSIndex
	if (HS == kNoDevice)
		return FALSE
	endif
	variable magreturn, taureturn
	
	SutterDAQWrite(Amp,1,0,0,100) //set sampling rate to 50 kHz
	
	SutterDAQwrite(Amp,13,HS,0,0)
	if (HS)
		magreturn = round(SutterDAQread(Amp,16+HS*7)/6.5532)/100		//16 and 17 for HS2
		taureturn = round(SutterDAQread(Amp,17+HS*7)*4.4/10.23)/100+0.1 // /10
	else
		magreturn = round(SutterDAQread(Amp,9+HS*7)/6.5532)/100
		taureturn = round(SutterDAQread(Amp,10+HS*7)*4.4/10.23)/100+0.1 // /10
	endif
	SIPA.ipa.HS[probeIndex].fastmag = magreturn
	SIPA.ipa.HS[probeIndex].fastphase = taureturn

	//if acquisition is running reset sampling rate	
	return TRUE
End


static Function IPA_SetDigOut(Struct IPASeries &SIPA, Variable ampindex, Variable bit, Variable state)
	// Write DIO to Amplifier
	if ((bit<0) || (bit>=kMaxDigBits))
		return FALSE
	endif

	if ((ampindex<0) || (ampindex>SIPA.numAmps))
		return FALSE
	endif

	if (IPA_OkToSendCommand() == TRUE)
		SutterDAQwrite(ampindex,22,0,bit,state)
	endif
	
	DFREF dfr=$AmpPath
	NVar SD_DIO = dfr:SD_DIO
	if (state)
		SD_DIO = SetBit(bit,SD_DIO)
	else
		SD_DIO = ClearBit(bit,SD_DIO)
	endif
	SIPA.amp[ampindex].dout = SD_DIO	
	
	return TRUE
End


static Function IPA_SetAllDigOut(Struct IPASeries &SIPA, Variable ampindex, Variable state)
	Variable digOutIndex
	
	DFREF dfr=$AmpPath
	NVar SD_DIO = dfr:SD_DIO
	SD_DIO = 0
	if (state == 1)
		SD_DIO = 255
	endif
	
	if (IPA_OkToSendCommand() == TRUE)
		for (digOutIndex=0; digOutIndex<kMaxDigBits; digOutIndex+=1)
			SutterDAQwrite(ampIndex,22,0,digOutIndex,state)		
		endfor	
	endif
	SIPA.amp[ampindex].dout = SD_DIO	
	
	return TRUE
End


static Function IPA_SetAuxOut(Struct IPASeries &SIPA, Variable ampIndex, Variable channel, Variable value)	
	if (abs(value)>10)
		value = 10*sign(value)
	endif

	Variable DACout
	Variable scaledvalue = value * 3276.7
	Variable Amptype = SIPA.amp[ampindex].amptype
	
	switch (Amptype)
		case kIPASingle:
		case kIPADouble:
			DACout = Channel + 1	//ch1 writes to DAC2, ch2 writes to DAC3	
			break
		case kSutterInterface:
			//should never get here
			return FALSE
	endswitch

	if (IPA_OKToSendCommand())
		SutterDAQwrite(ampIndex,17,DACout, (scaledvalue&0xff00)/256,scaledvalue&0x00ff)
	endif
	SIPA.amp[ampindex].analogOut[channel - 1] = value // channel is one based

	return TRUE
End


static Function IPA_ReadAuxIn(Struct IPASeries &SIPA, Variable ampIndex, Variable channel [,Variable use_SDMeter])
	Variable value = nan
	if ((ampindex<0) || (ampindex>SIPA.numAmps))
		return FALSE
	endif

	if ((channel <0) || (channel >=4))
		return FALSE
	endif
	 
	Variable ADCin
	variable Amptype = SIPA.amp[ampindex].amptype
	
	if (ParamIsDefault(use_SDMeter))
		use_SDMeter = FALSE
	endif
	
	if (use_SDMeter)
		Wave/D/Z SD_Meter = $(AmpPath + ":SD_Meter")
		if (waveExists(SD_Meter))
			//AuxIn1 = index 4
			//channel is 0-based
			value = SD_Meter[channel+4][ampIndex]
		else
			value = nan
		endif
	else
		switch (Amptype)
			case kIPASingle:
				ADCin = 3 + channel //channel one arrives on read(3)
				break
			case kIPADouble:
				switch (channel)
					case 0: 
						ADCin = 5
						break
					case 1: 
						ADCin = 6
						break
					case 2: 
						ADCin = 23
						break
					case 3: 
						ADCin = 24
						break
				endswitch
				break
			case kSutterInterface:
				//should never get here
				return FALSE
		endswitch
	
		if (IPA_OKToSendCommand())
			value = SutterDAQread(ampIndex,ADCin)
		else
			value = ADCin // fake value
		endif
	endif
	
	SIPA.amp[ampindex].analogIn[channel] = value
	SaveStructure(SIPA)

	return TRUE
End


//------------------IPA Delay Functions-------------------------------

static Function IPA_tickdelay(timeval) 		//for inaccurate short delays (1 tick ~ 17ms)
	variable timeval
	variable t0 = ticks
	
	do
	while(ticks-t0<timeval)
End

static Function IPA_usdelay(timeval)  		//for microsecond delays 
	variable timeval
	variable t0 = stopmstimer(-2)

	do
	while(stopmstimer(-2)-t0<timeval)
End



//-------------Zero offset for DAC ----------------------------------------------

static Function IPA_ZeroOffset(variable ampindex, variable channel, variable value)
	if (value > 256)
		value = 255
	elseif (value < -256)
		value = -255
	else
		value = trunc(value)
	endif
	if (IPA_OKToSendCommand() == TRUE)
		SutterDAQwrite(ampindex,21,channel, (value&0xff00)/256,value&0x00ff)
	endif
End	


static Function IPA_SetDACOffset(Struct IPASeries &SIPA)	
	Variable hsIndex
	for (hsIndex=0; hsIndex<SIPA.numHeadstages; hsIndex+=1)
		if (SIPA.ipa.HS[hsindex].DACoffset !=0)	
			IPA_ZeroOffset(SIPA.ipa.HS[hsindex].ampIndex,SIPA.ipa.HS[hsindex].HSIndex,SIPA.ipa.HS[hsindex].DACoffset)
		endif
	endfor
End


static Function IPA_GetDACOffset()
	if (IPA_OkToSendCommand() == FALSE)
		Return FALSE
	endif

	Struct IPASeries SIPA
	GetStructure(SIPA)
	
	variable probeIndex, VCMode, ReadCh, step, offset, singleread
	Variable ampl_index
	Variable amp_channel

	for (probeIndex=0; probeIndex<SIPA.numHeadstages; probeIndex+=1)
		ampl_index = SIPA.ipa.HS[probeIndex].ampIndex
		amp_channel = SIPA.ipa.HS[probeIndex].HSindex

		IPA_ZeroOffset(ampl_index,amp_channel,0)
		VCMode = IPA_GetValue(probeIndex+1,"VCMode")
		ReadCh = 2 + amp_channel*20
		if (VCMode)
			IPA_SetValue(probeIndex+1,"VHold",0)
		else
			IPA_SetValue(probeIndex+1,"IHold",0)
		endif	
		
		SutterDAQread(ampl_index,ReadCh)
		IPA_tickdelay(3) 

		offset = 0
		for (step=0; step<16; step+=1)
			singleread = SutterDAQread(ampl_index,ReadCh)
			offset += singleread
			Sutter_DelaySeconds( 1000e-6 )
		endfor
		
		offset /=16
		if (!VCMode) //CC
			offset *= 5e7
		endif
		//convert to bits
		offset *= 2^18
		SIPA.ipa.HS[probeIndex].DACoffset = -offset
		IPA_ZeroOffset( ampl_index, amp_channel, SIPA.ipa.HS[probeIndex].DACoffset )
	endfor
	
	SaveStructure(SIPA)
End	


static Function IPA_ResetDACOffset()
	Struct IPASeries SIPA
	GetStructure(SIPA)

	variable probeIndex
	Variable ampl_index
	Variable amp_channel

	for (probeIndex=0; probeIndex<SIPA.numHeadstages; probeIndex+=1)
		ampl_index = SIPA.ipa.HS[probeIndex].ampIndex
		amp_channel = SIPA.ipa.HS[probeIndex].HSindex
		IPA_ZeroOffset(ampl_index,amp_channel,0)
		SIPA.ipa.HS[probeIndex].DACoffset = 0
	endfor

	SaveStructure(SIPA)
End	


Function IPA_GetValue(variable probe_count, string value)
	if (probe_count <=0)
		return FALSE
	endif
	if (IsInitialized() == FALSE)
		return FALSE
	endif
	
	//one based
	Variable probeIndex = probe_count - 1
	Variable ampIndex
	
	Struct IPASeries SIPA
	GetStructure(SIPA)
	//values are read directly from the structure

	if (probeIndex >= SIPA.numHeadstages)
		return FALSE
	endif

	DFREF dfr=$AmpPath
	
	strswitch (value)
		case "ActiveIPA":
			return SIPA.ipa.HS[SIPA.activeHS].ampIndex+1
			break
		case "ActiveHS":
		case "ActiveProbe":
			return SIPA.activeHS+1
			break
		case "AmplIndex":
			//0 based
			return SIPA.ipa.HS[probeIndex].ampIndex
			break
		case "NumHS":
		case "NumProbes":
			return SIPA.numHeadstages
			break
		case "AmpType":
			ampIndex = SIPA.ipa.HS[probeIndex].ampIndex
			return SIPA.amp[ampIndex].ampType
			break
		case "AmpSN":
			ampIndex = SIPA.ipa.HS[probeIndex].ampIndex
			string mystring=SIPA.amp[ampindex].serialNum
			return str2num(mystring[7,11])
			//return str2num(ipa.serial)	//THIS DOESN'T WORK... can't return string.
			break
		case "Mode":
			if( !SIPA.ipa.HS[probeIndex].vc)
				return !(SIPA.ipa.HS[probeIndex].vc)
			else
				return (SIPA.ipa.HS[probeIndex].vc &&1)
			endif
			break
		case "CCMode":
			return (SIPA.ipa.HS[probeIndex].vc &&1)
			break
		case "VCMode":
			return !(SIPA.ipa.HS[probeIndex].vc)
			break 
		case "Filter":
		case "IFilter":
		case "VFilter":
			return str2num(stringfromlist(SIPA.ipa.HS[probeIndex].filter,FilterList))
			break
		case "VGain":
			if (SIPA.ipa.HS[probeIndex].vc==0) //Voltage Clamp
				return 10
			else
				return str2num(stringfromlist(SIPA.ipa.HS[probeIndex].gaincc,VGainList))
			endif
			break
		case "IGain":
			if (SIPA.ipa.HS[probeIndex].vc==0)
				return str2num(stringfromlist(SIPA.ipa.HS[probeIndex].gainvc,IGainList))*1e9
			else
				return 5e8
			endif
			break
		case "InLimit":
			if ((SIPA.ipa.HS[probeIndex].vc &&1))
				return 10/str2num(stringfromlist(SIPA.ipa.HS[probeIndex].gaincc,VGainList))
			endif
			return 10/(str2num(stringfromlist(SIPA.ipa.HS[probeIndex].gainvc,IGainList)))*1e9
			break
		case "ILimit":
			return 10/(str2num(stringfromlist(SIPA.ipa.HS[probeIndex].gainvc,IGainList)))*1e9
			break
		case "VLimit":
			return 10/str2num(stringfromlist(SIPA.ipa.HS[probeIndex].gaincc,VGainList))
			break
		case "OffsetLock":
			return SIPA.ipa.HS[probeIndex].offsetlock
			break
		case "Offset":
			return SIPA.ipa.HS[probeIndex].offset /2^16
			break
		case "LJP":
		case "LiquidJunction":
			return SIPA.ipa.HS[probeIndex].LJP
			break	
		case "DynHoldOn":
			return SIPA.ipa.HS[probeIndex].trackon
			break
		case "DynHold":
			return SIPA.ipa.HS[probeIndex].track *1e-3
			break
		case "ECompMag":
			//return ipa.fastmag*((!ipa.vc)||ipa.capneuton)*1e-12
			return SIPA.ipa.HS[probeIndex].fastmag*1e-12
			break
		case "ECompTau":
		case "ECompPhase": //no longer used but just in case
			//return ipa.fastphase*((!ipa.vc)||ipa.capneuton)*.01
			return SIPA.ipa.HS[probeIndex].fastphase * 1e-6 //*.01
			break
		case "ECompOn":
			return (SIPA.ipa.HS[probeIndex].capneuton)
		case "RsCompOn":
			return (SIPA.ipa.HS[probeIndex].compon)
			break	
		case "RsComp":
			//return ipa.rscomp*(ipa.compon)*1e6
			return SIPA.ipa.HS[probeIndex].rscomp*1e6
			break
		case "CmComp":
			//return ipa.cmcomp*(ipa.compon)*1e-12
			return SIPA.ipa.HS[probeIndex].cmcomp*1e-12
			break
		case "RsCorrOn":
			return SIPA.ipa.HS[probeIndex].corron
			break 
		case "RsPred":
			//return ipa.rspred*(ipa.corron)*.01
			return SIPA.ipa.HS[probeIndex].rspred*.01
			break
		case "RsCorr":
			//return ipa.rscorr*(ipa.corron)*.01
			return SIPA.ipa.HS[probeIndex].rscorr*.01
			break
		case "RsLag":
			return SIPA.ipa.HS[probeIndex].lag*1e-6
			break
		case "Bridge":
			return SIPA.ipa.HS[probeIndex].bridge*1e6
			break
		case "BridgeOn":
			return SIPA.ipa.HS[probeIndex].bridgeon
			break
		case "IHoldOn":
			return SIPA.ipa.HS[probeIndex].hcurron
			break
		case "VHoldOn":
			return SIPA.ipa.HS[probeIndex].hpoton
			break
		case "IHold":
			if (SIPA.ipa.HS[probeIndex].hcurron == TRUE)
				return SIPA.ipa.HS[probeIndex].hcurr*1e-12
			endif
			return 0.0
			break
		case "VHold":
			if (SIPA.ipa.HS[probeIndex].hpoton == TRUE)
				return SIPA.ipa.HS[probeIndex].hpot*1e-3
			endif
			return 0.0
			break
		case "Hold":
			if (SIPA.ipa.HS[probeIndex].vc==0) //Voltage Clamp
				if (SIPA.ipa.HS[probeIndex].hpoton == TRUE)
					return SIPA.ipa.HS[probeIndex].hpot*1e-3
				endif
			else
				if (SIPA.ipa.HS[probeIndex].hcurron == TRUE)
					return SIPA.ipa.HS[probeIndex].hcurr*1e-12
				endif
			endif
			return 0.0
		case "IMon":
			//if the background task is running to update the structure the value can be read directy
			//return (SIPA.ipa.HS[probeIndex].Imon
			Wave SD_Meter = dfr:SD_Meter
			if ((SIPA.ipa.HS[probeIndex].ampIndex == kNoDevice) || (SIPA.ipa.HS[probeIndex].HSindex == kNoDevice))
				return nan
			endif
			if (SIPA.ipa.HS[probeIndex].HSindex == 0)
				return (SD_Meter[0][SIPA.ipa.HS[probeIndex].ampIndex])
			else
				return (SD_Meter[2][SIPA.ipa.HS[probeIndex].ampIndex])
			endif
			break
		case "VMon":
			//if the background task is running to update the structure the value can be read directy
			//return (SIPA.ipa.HS[probeIndex].Vmon
			Wave SD_Meter = dfr:SD_Meter
			if ((SIPA.ipa.HS[probeIndex].ampIndex == kNoDevice) || (SIPA.ipa.HS[probeIndex].HSindex == kNoDevice))
				return nan
			endif
			if (SIPA.ipa.HS[probeIndex].HSindex == 0)
				return (SD_Meter[1][SIPA.ipa.HS[probeIndex].ampIndex])
			else
				return (SD_Meter[3][SIPA.ipa.HS[probeIndex].ampIndex])
			endif
			break
		case "DigOutWord":
			ampIndex = SIPA.ipa.HS[probeIndex].ampIndex
			return SIPA.amp[ampindex].dout
			break
		case "AuxOut1":
			ampIndex = SIPA.ipa.HS[probeIndex].ampIndex
			return SIPA.amp[ampindex].analogOut[0]
			break
		case "AuxOut2":
			ampIndex = SIPA.ipa.HS[probeIndex].ampIndex
			return SIPA.amp[ampindex].analogOut[1]
			break
		case "AuxIn1":
			ampIndex = SIPA.ipa.HS[probeIndex].ampIndex
			IPA_ReadAuxIn(SIPA,ampIndex,0,use_SDMeter=TRUE)
			return SIPA.amp[ampindex].analogIn[0]
		case "AuxIn2":
			ampIndex = SIPA.ipa.HS[probeIndex].ampIndex
			IPA_ReadAuxIn(SIPA,ampIndex,1,use_SDMeter=TRUE)
			return SIPA.amp[ampindex].analogIn[1]
		case "AuxIn3":
			ampIndex = SIPA.ipa.HS[probeIndex].ampIndex
			IPA_ReadAuxIn(SIPA,ampIndex,2,use_SDMeter=TRUE)
			return SIPA.amp[ampindex].analogIn[2]
		case "AuxIn4":
			ampIndex = SIPA.ipa.HS[probeIndex].ampIndex
			IPA_ReadAuxIn(SIPA,ampIndex,3,use_SDMeter=TRUE)
			return SIPA.amp[ampindex].analogIn[3]
	endswitch
End


Function IPA_SetValue(variable probe_count, string setting, variable value )
	if (probe_count <=0)
		return FALSE
	endif
	if (IsInitialized() == FALSE)
		return FALSE
	endif
	
	Struct IPASeries SIPA
	GetStructure(SIPA)
	
	Variable probeIndex = probe_count-1
	if (probeIndex >= SIPA.numHeadstages)
		return FALSE
	endif

	//double IPA is a single amplifier device with two headstages.
	//ampl_index will get us the physical index if more than one amplifier is connected
	//amp_channel is the local headstage index for that amplifier
	//for a DIPA its 0 and 1, IPA always uses 0
	//the second headstage is not treated as a different device
	
	Variable ampl_index = SIPA.ipa.HS[probeIndex].ampIndex
	Variable amptype = SIPA.amp[ampl_index].amptype
	Variable amp_channel = SIPA.ipa.HS[probeIndex].HSindex
	Variable oktosend = IPA_OKToSendCommand()
		
	Variable StabilityControl
	variable setval
		
	strswitch (setting)
		case "Reset":
			IPA_ResetControls(SIPA, probeIndex)
			break
		case "SelectHS":
		case "SelectProbe":	
			IPA_ActivateHeadstage(SIPA, probeIndex)
			break
		case "LJP":
		case "LiquidJunction":
			//no firmware command just entered in the structure
			//stored as millivolts
			SIPA.ipa.HS[probeIndex].LJP = value
			break
		case "CCMode":
		  	SIPA.ipa.HS[probeIndex].vc = 2
			IPA_SetFromStructure(SIPA, probeIndex)
			break
		case "VCMode":
		  	SIPA.ipa.HS[probeIndex].vc= 0
			IPA_SetFromStructure(SIPA, probeIndex)
			break
		case "IHold":  
			if (abs(value)>20e-9)
				value = 20e-9*sign(value)
			endif
			value =round(value*1e12)
			SIPA.ipa.HS[probeIndex].hcurr = value
			SIPA.ipa.HS[probeIndex].hcurron = TRUE
			if ((SIPA.ipa.HS[probeIndex].vc != 0) && (oktosend))
				SutterDAQwrite(ampl_index,16,amp_channel,((1.6384* value)&0xff00)/256,(1.6384* value)&0x00ff)
			endif
			break
		case "VHold": 
			if (abs(value)>1)
				value = sign(value)
			endif
			value =round(value*1000)
			SIPA.ipa.HS[probeIndex].hpot = value
			SIPA.ipa.HS[probeIndex].hpoton = TRUE
			if ((SIPA.ipa.HS[probeIndex].vc == 0) && (oktosend))
				SutterDAQwrite(ampl_index,16,amp_channel,((32.767*value)&0xff00)/256,(32.767*value)&0x00ff)
			endif	
			break
		case "Filter":
		case "IFilter":
		case "VFilter":
			setval = whichlistitem(num2str(value),"500;1000;2000;5000;10000;20000")
			if (setval == -1)
				if (value<550)
					setval = 0
				elseif (value<1100)
					setval = 1
				elseif (value<2200)
					setval = 2
				elseif (value<5500)
					setval = 3
				elseif (value<11000)
					setval = 4
				else
					setval = 5
				endif
			endif
			if (oktosend)
				if (amp_channel) //DIPA second headstage
					SutterDAQwrite(ampl_index,23,11,0,5-setval)
				else
					SutterDAQwrite(ampl_index,11,0,0,5-setval)
				endif
			endif
			SIPA.ipa.HS[probeIndex].filter = setval
			break
		case "VGain":
			setval = whichlistitem(num2str(value),"10;20;50;100;200;500")
			if (setval == -1 )
				if (value<18)
					setval=0
				elseif (value<45)
					setval=1
				elseif (value<90)
					setval=2
				elseif (value<180)
					setval=3
				elseif (value<450)
					setval=4
				else
					setval=5
				endif			
			endif
			if ((SIPA.ipa.HS[probeIndex].vc == 2) && (oktosend))
				if (amp_channel) //DIPA second headstage
					SutterDAQwrite(ampl_index,23,12,0,setval)  // 0 for VC; 1 for CC, dval is code for gain
				else
					SutterDAQwrite(ampl_index,12,0,0,setval)  // 0 for VC; 1 for CC, dval is code for gain
				endif
			endif
			SIPA.ipa.HS[probeIndex].gaincc = setval
			break
		case "IGain":
			setval = whichlistitem(num2str(value),"0.5;1;2.5;5;10;25")
			if (setval == -1 )
				if (value<.9e9)
					setval=0
				elseif (value<2.25e9)
					setval=1
				elseif (value<4.5e9)
					setval=2
				elseif (value<9e9)
					setval=3
				elseif (value<22.5e9)
					setval=4
				else
					setval=5
				endif			
			endif
			if ((SIPA.ipa.HS[probeIndex].vc == 0) && (oktosend))
				if (amp_channel) //DIPA second headstage
					SutterDAQwrite(ampl_index,23,12,0,setval)  // 0 for VC; 1 for CC, dval is code for gain
				else
					SutterDAQwrite(ampl_index,12,0,0,setval)
				endif
			endif
			SIPA.ipa.HS[probeIndex].gainvc = setval
			break
		case "Offset":  //value sent in volts
			if (abs(value)>=0.25)
				value = 0.25*sign(value)
			endif
			Value = round(2^16*value)  //convert to 16bit value
			Value = limit(Value, kOffsetMin, kOffsetMax)
			if (oktosend)
				SutterDAQwrite(ampl_index,17,1+3*amp_channel,(value&0xff00)/256,value&0x00ff)		//1 for HS#0, 4 for HS#1
			endif
			SIPA.ipa.HS[probeIndex].offset = value
			break
		case "OffsetLock":
			SIPA.ipa.HS[probeIndex].offsetlock = value
			break
		case "ECompMag":
			if (value<0)
				value = 0
			elseif (value>25e-12)
				value = 25e-12
			endif
			value *= 1e12
			// store the value without the CC offset, it is added when the value is sent in CC,
			// see ModifyCapMag()
			setval =  round(value*655.32)
			if (SIPA.ipa.HS[probeIndex].vc == 2)
				IPA_ModifyCapMag(setval)
				// in CC the value is the capacitance neutralization, only active with ECompOn
				if (SIPA.ipa.HS[probeIndex].capneuton == 0)
					setval = 0
				endif
			endif
			if (setval<0)
				setval=0
			endif
			if (oktosend)
				SutterDAQwrite(ampl_index,2+21*amp_channel,2,(setval&0xff00)/256,setval&0x00ff)		//2 for HS#0, 23 for HS#1
			endif
			SIPA.ipa.HS[probeIndex].fastmag = value
			break
		case "ECompTau":					// was "ECompPhase"
			if (value<1e-7)
				value = 1e-7
			elseif (value>4.5e-6)
				value = 4.5e-6
			endif
			value *=1e6
			setval = round((value-0.1)*1023/4.4)
			if (oktosend)
				SutterDAQwrite(ampl_index,2+21*amp_channel,1,(setval&0xff00)/256,setval&0x00ff)
			endif
			SIPA.ipa.HS[probeIndex].fastphase = value
			break
		case "RsComp":  
			if (value<0)
				value = 0
			elseif (value>100e6) 
				value = 100e6
			endif
			value *= 1e-6
			SIPA.ipa.HS[probeIndex].rscomp = value
			SIPA.ipa.HS[probeIndex].compon = TRUE
			IPA_SetCompensation(SIPA,probeIndex)
			IPA_SetCorrection(SIPA,probeIndex)
			break
		case "CmComp": 
			if (value<0)
				value = 0
			elseif(value>100e-12) 
				value = 100e-12
			endif
			value *=1e12
			SIPA.ipa.HS[probeIndex].cmcomp = value
			SIPA.ipa.HS[probeIndex].compon = TRUE
			IPA_SetCompensation(SIPA,probeIndex)
			IPA_SetCorrection(SIPA,probeIndex)
			break
		case "RsPred": 
			if (value<0)
				value = 0
			elseif (value>1) 
				value = 1
			endif
			value *=100
			SIPA.ipa.HS[probeIndex].rspred = value
			SIPA.ipa.HS[probeIndex].corron = TRUE
			SIPA.ipa.HS[probeIndex].compon = TRUE
			IPA_SetCompensation(SIPA,probeIndex)
			IPA_SetCorrection(SIPA,probeIndex)
			break
		case "RsCorr":  
			if (value<0)
				value = 0
			elseif (value>1) 
				value = 1
			endif
			value *=100
			SIPA.ipa.HS[probeIndex].rscorr = value
			SIPA.ipa.HS[probeIndex].corron = TRUE
			IPA_SetCorrection(SIPA,probeIndex)
			break
		case "RsLag":	
			if (value<20e-6)
				value = 20e-6
			elseif (value>200e-6) 
				value = 200e-6
			endif
			value *= 1e6
			setval =  min(1023,round(value*5.12))
			if (oktosend)
				SutterDAQwrite(ampl_index,2+21*amp_channel,10,(setval&0xff00)/256,setval&0x00ff)
			endif
			SIPA.ipa.HS[probeIndex].lag = value
			break	
		case "Bridge":
			if (value<0)
				value = 0
			elseif (value>200e6) 
				value = 200e6
			endif
			value *=1e-6
			setval =  round(value*81.92)
			if (oktosend)
				SutterDAQwrite(ampl_index,2+21*amp_channel,5,(setval&0xff00)/256,setval&0x00ff)
			endif
			SIPA.ipa.HS[probeIndex].bridge = value
			SIPA.ipa.HS[probeIndex].bridgeon = TRUE
			break
		case "BridgeOn":
			value = !!value
			setval =  value*round(SIPA.ipa.HS[probeIndex].bridge*81.92)
			if (oktosend)
				SutterDAQwrite(ampl_index,2+21*amp_channel,5,(setval&0xff00)/256,setval&0x00ff)
			endif
			SIPA.ipa.HS[probeIndex].bridgeon = value
			break	
		case "AutoEComp":
			IPA_AutoElectrodeCompensation(SIPA,probeIndex)
			break
		case "AutoCellComp":
			IPA_AutoWholeCellCompensation(SIPA,probeIndex)
			break				
		case "RsCompOn":	// Rs Compensation enabled
			SIPA.ipa.HS[probeIndex].compon = value
			IPA_SetCompensation(SIPA,probeIndex)
			break
		case "RsCorrOn":	//Prediction/Correction enabled
			SIPA.ipa.HS[probeIndex].corron = value
			IPA_SetCompensation(SIPA,probeIndex)
			IPA_SetCorrection(SIPA,probeIndex)
			break
		case "DynHold":
			if (abs(value)>1)
				value = sign(value)
			endif
			value*=1000
			setval =  round(value*32.767)
			// sending the value enables the dynamic hold, only do that when it is on
			if (oktosend && SIPA.ipa.HS[probeIndex].trackon && (SIPA.ipa.HS[probeIndex].vc == 2))
				SutterDAQwrite(ampl_index,19+6*amp_channel,1,(setval&0xff00)/256,setval&0x00ff)
			endif
			SIPA.ipa.HS[probeIndex].track = value
			break
		case "DynHoldOn":		//Slow holding potential enabled
			SIPA.ipa.HS[probeIndex].trackon = value
			if (value)  //Tracking turned ON
				if (SIPA.ipa.HS[probeIndex].vc == 2)  //CC
					setval = 32.767 * SIPA.ipa.hs[probeindex].track
					if (oktosend)
						SutterDAQwrite(ampl_index,19+6*amp_channel,1,((setval)&0xff00)/256,(setval)&0x00ff)
					endif
				endif
			else 					//Tracking turned OFF
				if ((SIPA.ipa.HS[probeIndex].vc == 2) && (oktosend))
					SutterDAQwrite(ampl_index,19+6*amp_channel,0,0,0)
				endif
			endif		
			break	
		case "ECompOn":		//Current Clamp electrode compensation enabled.
			if (SIPA.ipa.HS[probeIndex].vc == 2) //only set if in CC
				setval=value*round((SIPA.ipa.HS[probeIndex].fastmag+kCC_deltaCap-kStabilityControl)*655.32)
				if (oktosend)
					SutterDAQwrite(ampl_index,2+21*amp_channel,2,(setval&0xff00)/256,setval&0x00ff)
				endif
			endif	
			SIPA.ipa.HS[probeIndex].capneuton = value
			break
		case "VHoldOn":		//Holding potential set
			if (SIPA.ipa.HS[probeIndex].vc == 0) //only set if in VC
				setval = 32.767*SIPA.ipa.HS[probeIndex].hpot*value
				if (oktosend)
					SutterDAQwrite(ampl_index,16,amp_channel,(setval&0xff00)/256,setval&0x00ff)
				endif
			endif
			SIPA.ipa.HS[probeIndex].hpoton = value
			break
		case "IHoldOn":		//Holding current set
			if (SIPA.ipa.HS[probeIndex].vc == 2) //only set if in CC
				setval = 1.63835*SIPA.ipa.HS[probeIndex].hcurr*value
				if (oktosend)
					SutterDAQwrite(ampl_index,16,amp_channel,(setval&0xff00)/256,setval&0x00ff)
				endif
			endif
			SIPA.ipa.HS[probeIndex].hcurron = value
			break
		case "DigOutWord": //not amplifier specific
			IPA_SetAllDigOut(SIPA,ampl_index,value)
			break	
		case "DigOut1":
			IPA_SetDigOut(SIPA,ampl_index, 0, value)
			break
		case "DigOut2":
			IPA_SetDigOut(SIPA,ampl_index, 1, value)
			break
		case "DigOut3":
			IPA_SetDigOut(SIPA,ampl_index, 2, value)
			break
		case "DigOut4":
			IPA_SetDigOut(SIPA,ampl_index, 3, value)
			break
		case "DigOut5":
			IPA_SetDigOut(SIPA,ampl_index, 4, value)
			break
		case "DigOut6":
			IPA_SetDigOut(SIPA,ampl_index, 5, value)
			break
		case "DigOut7":
			IPA_SetDigOut(SIPA,ampl_index, 6, value)
			break
		case "DigOut8":
			IPA_SetDigOut(SIPA,ampl_index, 7, value)
			break
		case "AuxOut1":
			IPA_SetAuxOut(SIPA, ampl_index,1,value)
			break
		case "AuxOut2":
			IPA_SetAuxOut(SIPA, ampl_index,2,value)
			break
		case "Reconnect":
			IPA_ResetUSB()
			return TRUE
		case "AutoOffset":
			if (SIPA.ipa.HS[probeIndex].offsetlock)
				return FALSE
			endif
			IPA_ZeroIPAOffset(SIPA,probeIndex)
			break	// store the new offset
		case "SealTest":
			if (oktosend)
				if (value==0)
					SutterDAQWrite(ampl_index,18,0,10,10)
				else 
					SutterDAQwrite(ampl_index,18,1,10,value)
				endif
			endif
			SIPA.ipa.HS[probeIndex].seal = value
			break
		case "Buzz":
			IPA_Buzz(SIPA,probeIndex,value)
			break
		case "AutoBridge":
			if (IPA_AutoBridge(SIPA,probeIndex) != TRUE)
				return FALSE
			endif
			//structure values are updated in the IPA_DoSetAutoBridge
			return TRUE
			break
		DEFAULT:
			return FALSE  //Not a proper keyword
	endswitch
	
	SaveStructure(SIPA)
	
	return TRUE
End	


static Function IPA_ResetControls(Struct IPASeries &SIPA, Variable probeIndex)
	//Reset Structure Wave
	IPA_InitProbeControls(SIPA.IPA, probeIndex)	
	IPA_SetValue(probeIndex+1,"SelectHS",1)
	
	return TRUE
End	


static Function IPA_ZeroIPAOffset(Struct IPASeries &SIPA, Variable probeIndex)	//This is the automatic offset button
	Variable ampl_index = SIPA.ipa.HS[probeIndex].ampIndex
	Variable amp_channel = SIPA.ipa.HS[probeIndex].HSindex
	Variable oktosend = IPA_OKToSendCommand()
	
	SutterDAQreset()		//Halts acquisition
	IPA_tickdelay(1)
	
	variable readvalue
	variable myoffset = SIPA.ipa.HS[probeIndex].offset	// already in DAC units, see "Offset" in IPA_SetValue
	variable myLJP = SIPA.ipa.HS[probeIndex].ljp * 2^16
	variable offsetMV
	variable readchannel
	if (amp_channel==0)
		readchannel=1
	else
		readchannel=21	//Second headstage on dIPA
	endif
 	
 	if (SIPA.ipa.HS[probeIndex].vc == 0)
		variable offsetstep = 1024	//Start at 16 mV step 
		variable direction =1
		variable count = 0
		if (oktosend)
			readvalue = sutterdaqread(ampl_index,readchannel)
		endif
		direction = (readvalue > 0)		//1 is positive, 0 is negative
		
		// output voltage of the amplifier, gainvc is the index into the VC gains in mV/pA
		if (abs(readvalue*str2num(stringfromlist(SIPA.ipa.HS[probeIndex].gainvc,"0.5;1;2.5;5;10;25"))*1e9) > 9.9)
			//Print "Out of Range"
			offsetstep = 2048	//32 mV
		endif
		
		for (count=0; count<50; count+=1)
			if (abs(readvalue)<2e-12 || offsetstep < 1)
				break
			endif
			if (readvalue>0)
				if (!direction)
					offsetstep /=2
				endif
				myoffset-=offsetstep
				direction = 1
			else
				if (direction)
					offsetstep /=2
				endif
				myoffset += offsetstep
				direction = 0
			endif
			if (myoffset < kOffsetMin || myoffset > kOffsetMax)
				myoffset = limit(myoffset, kOffsetMin, kOffsetMax) //limit to +/- 250 mV
				break
			endif
			if (oktosend)
				if (amp_channel==1)  //Second HS on dIPA
					SutterDAQwrite(ampl_index,17,4,(myoffset&0xff00)/256,myoffset&0x00ff)
				else
					SutterDAQwrite(ampl_index,17,1,(myoffset&0xff00)/256,myoffset&0x00ff)
				endif
			endif
			IPA_tickdelay(3)  //Wait before taking next reading (~50ms)	
			if (oktosend)
				readvalue = Sutterdaqread(ampl_index,readchannel)
			endif
		endfor
		myoffset += myljp
		myoffset = limit(myoffset, kOffsetMin, kOffsetMax)
		if (oktosend)
			if (amp_channel==1)  //Second HS on dIPA
					SutterDAQwrite(ampl_index,17,4,(myoffset&0xff00)/256,myoffset&0x00ff)
				else
					SutterDAQwrite(ampl_index,17,1,(myoffset&0xff00)/256,myoffset&0x00ff)
			endif
		endif
	else
		// Otherwise CC, just read voltage and subtract
		if (oktosend)
			readvalue = Sutterdaqread(ampl_index,readchannel)
		endif
		myoffset += readvalue*2^16
		myoffset = limit(myoffset, kOffsetMin, kOffsetMax)
		myoffset += myljp
		myoffset = limit(myoffset, kOffsetMin, kOffsetMax)
		
		if (oktosend)
			if (amp_channel==1)   //Second HS on dIPA
				SutterDAQwrite(ampl_index,17,4,(myoffset&0xff00)/256,myoffset&0x00ff)
			else
				SutterDAQwrite(ampl_index,17,1,(myoffset&0xff00)/256,myoffset&0x00ff)
			endif
		endif
	endif
	
	offsetMV =myoffset*1000/2^16  //convert offset to volts
	SIPA.ipa.HS[probeIndex].offset = myoffset //stored in DAC units
	
	//restart acquisition if it was running
	return TRUE
end

//--------------- ZAP, BUZZ and SEALTEST ---------------------------

static Function IPA_Buzz(Struct IPASeries &SIPA, Variable probeIndex, Variable duration)
	if (IPA_OKToSendCommand() == FALSE)
		return FALSE
	endif
	
 	if (SIPA.ipa.HS[probeIndex].vc != 2) //CC mode
 		return FALSE
 	endif

	Variable ampl_index = SIPA.ipa.HS[probeIndex].ampIndex
	Variable amp_channel = SIPA.ipa.HS[probeIndex].HSindex

	SutterDAQwrite(ampl_index,2+21*amp_channel,1,3,0) //set ECtau
	SutterDAQwrite(ampl_index,2+21*amp_channel,2,40,0) //set ECmag
	
	variable step, stepsign
	stepsign=1
	for (step=0; step<(1*duration); step+=1)
		//set holding
		if (stepsign==1)
			SutterDAQwrite(ampl_index,16,amp_channel,192,0)
			stepsign= -1
		else
			SutterDAQwrite(ampl_index,16,amp_channel,64,0)
			stepsign=1
		endif
		IPA_usdelay(1000)
	endfor
	
	variable setval
	setval=round((SIPA.ipa.HS[probeIndex].fastmag+kCC_deltaCap-kStabilityControl)*655.32)*SIPA.ipa.HS[probeIndex].capneuton
	SutterDAQwrite(ampl_index,2+21*amp_channel,2,(setval&0xff00)/256,setval&0x00ff)
	setval=round((SIPA.ipa.HS[probeIndex].fastphase-0.1)*1023/4.4)
	SutterDAQwrite(ampl_index,2+21*amp_channel,1,(setval&0xff00)/256,setval&0x00ff)
	setval = 1.63835*SIPA.ipa.HS[probeIndex].hcurr*SIPA.ipa.HS[probeIndex].hcurron
	SutterDAQwrite(ampl_index,16,amp_channel,(setval&0xff00)/256,setval&0x00ff)

	return TRUE
End


static Function IPA_AutoBridge(Struct IPASeries &SIPA, Variable probeIndex)
	if (IPA_OKToSendCommand() == FALSE)
		return FALSE
	endif
	
 	if (SIPA.ipa.HS[probeIndex].vc != 2) //CC mode
 		return FALSE
 	endif

	Variable ampl_index = SIPA.ipa.HS[probeIndex].ampIndex
	Variable amp_channel = SIPA.ipa.HS[probeIndex].HSindex
	
	if (amp_channel==1)
		SutterDAQWrite(ampl_index,23,11,0,0)
	else
		SutterDAQWrite(ampl_index,11,0,0,0)  //switch filter to 20k
	endif

	DFREF dfr=$AmpPath
	make /o/n=5 dfr:AutoBridgeOut
	wave AutoBridgeOut = dfr:AutoBridgeOut
	AutoBridgeOut = 0
	AutoBridgeOut[1] = -400e-12
	SetScale /p x, 0, 0.001, AutoBridgeOut
	
	make /o/n=200 dfr:AutoBridgeIn
	wave AutoBridgeIn = dfr:AutoBridgeIn
	SetScale /p x, 0, 2e-5, AutoBridgeIn
	
	Make /O/T /n=(1,3) dfr:BridgeInputWaveList
	Wave /T BridgeInputWaveList = dfr:BridgeInputWaveList
	BridgeInputWaveList[0][0] = AmpPath + ":AutoBridgeIn"
	if (amp_channel == 0)
		BridgeInputWaveList[0][1] = "1"		
	else
		BridgeInputWaveList[0][1] = "3"
	endif
	
	Make /o/t/n=(1,3) dfr:BridgeOutputWaveList	
	Wave /T BridgeOutputWaveList = dfr:BridgeOutputWaveList
	BridgeOutputWaveList[0][0] = AmpPath + ":AutoBridgeOut"
	if (amp_channel == 0)
		BridgeOutputWaveList[0][1] = "0"
	else
		BridgeOutputWaveList[0][1] = "1"
	endif
	
	SutterDAQWriteWave /T=1 /MULT=1 /CC=3 /RHP=3  BridgeOutputWaveList
	SutterDAQScanWave /T=1  /B /MULT=1 /H="IPA_DoSetAutoBridge()" dfr:BridgeInputWaveList 
	SutterDAQClock(ampl_index,0,0)

	//active headstage so that we get the proper probe index in the callback function
	IPA_ActivateHeadstage(SIPA,probeIndex)
end


Function IPA_DoSetAutoBridge()	//called by the SutterDAQScanWave
	DFREF dfr=$AmpPath
	variable Xoffset = 0.96e-3
	wave AutoBridgeIn = dfr:AutoBridgeIn
	CurveFit/Q/M=2/W=0 line, AutoBridgeIn[65,90]/D
	Wave W_Coef
	
	Variable probeIndex = IPA_GetValue(0,"ActiveHS")
	Variable OldBridge = IPA_GetValue(probeIndex,"Bridge")*IPA_GetValue(probeIndex,"BridgeON")
	Variable Change = ((W_Coef[0]+W_Coef[1]*Xoffset)-IPA_GetValue(probeIndex,"Vmon"))/-4e-10
	Variable NewBridge = OldBridge + Change
	
	IPA_SetValue(probeIndex,"Bridge",NewBridge)
	IPA_SetValue(probeIndex,"BridgeON",1)
	IPA_SetValue(probeIndex,"VFilter",IPA_GetValue(0,"VFilter"))
End


Function IPA_UpdateInputs()
//call from a background task
//in the xop during idle time SD_Meter is updated every 250 ms
//during acquisition its updated before the first sweep 
	if (IPA_USBconnected() == FALSE)
		return FALSE
	endif

	Wave/D/Z SD_Meter = $(AmpPath + ":SD_Meter")
	if (waveExists(SD_Meter) == FALSE)
		return FALSE
	endif

	Struct IPASeries SIPA
	GetStructure(SIPA)
	
	//Update all inputs 
	//first the headstages
	Variable probe_index
	for (probe_index=0; probe_index<SIPA.numHeadstages; probe_index+=1)
		//each headstgae has its own structure, SD_Meter values are shared for up to 2 headstages
		if (SIPA.ipa.HS[probe_index].HSIndex == 0)
			SIPA.ipa.HS[probe_index].imon = SD_Meter[0][SIPA.ipa.HS[probe_index].ampIndex]
			SIPA.ipa.HS[probe_index].vmon = SD_Meter[1][SIPA.ipa.HS[probe_index].ampIndex]
		else
			SIPA.ipa.HS[probe_index].imon = SD_Meter[2][SIPA.ipa.HS[probe_index].ampIndex]
			SIPA.ipa.HS[probe_index].vmon = SD_Meter[3][SIPA.ipa.HS[probe_index].ampIndex]
		endif
	endfor	
	
	//amplifier auxchannels
	Variable ampl_index
	Variable aux_index
	Variable channel = 0
	for (ampl_index=0; ampl_index<SIPA.numAmps; ampl_index+=1)
		channel = 0
		for (aux_index=4; aux_index<8; aux_index+=1)
			//indev 4 to 7 for auxin
			SIPA.amp[ampl_index].analogIn[channel] = SD_Meter[aux_index][ampl_index]
			channel+=1
		endfor
	endfor
	
	SaveStructure(SIPA)
	
	return TRUE
End

static StrConstant IPA_TimerTaskName = "IPA_TimerTask"
static Constant IPA_TimerInterval = 0.250

Function IPA_TimerWorkTask( STRUCT WMBackgroundStruct &TheTask )
	IPA_UpdateInputs()
	return 0
End


Function IPA_StartTimerTask()
	CtrlNamedBackground $IPA_TimerTaskName, period = ( IPA_TimerInterval * 60 ), proc = IPA_TimerWorkTask
	CtrlNamedBackground $IPA_TimerTaskName, start
End


Function IPA_StopTimerTask()
	CtrlNamedBackground $IPA_TimerTaskName, stop
End

// ---------------- MIES specific functions ----------------
//
// The following functions were added for MIES, they are not part of the
// original Sutter Instrument package.
//
// The probe index is one-based over all headstages of all connected IPA
// devices, as in IPA_SetValue() and IPA_GetValue().

/// @brief Return TRUE if the loaded SutterXOP is compatible with this package
///
/// Same check as Sutter_CheckXOPVersion() but without showing a dialog.
Function IPA_MIES_IsXOPCompatible()

	PerformSubsystemEntry()
	//no dialog
	return Sutter_CheckXOPVersion(FALSE)
End

/// @brief Initialize the package without its background task
///
/// IPA_DoInitialize() starts a background task, which copies SD_Meter into the stored
/// structure every 250 ms. MIES does not use these values, so the task would only run
/// alongside the data acquisition.
///
/// @returns TRUE on success and FALSE on error
Function IPA_MIES_Initialize()

	PerformSubsystemEntry()

	if(!IPA_DoInitialize())
		return FALSE
	endif

	IPA_StopTimerTask()

	return TRUE
End

/// @brief Return TRUE if commands can be sent to the amplifier
///
/// Without a connected amplifier IPA_DoInitialize() leaves the package in demo
/// mode, where IPA_SetValue() only changes the stored control values.
Function IPA_MIES_OkToSendCommand()

	PerformSubsystemEntry()

	return IPA_OkToSendCommand()
End

/// @brief Return TRUE if the package is initialized, i.e. IPA_DoInitialize() was called
///        and IPA_DoShutdown() was not called afterwards
Function IPA_MIES_IsInitialized()

	PerformSubsystemEntry()

	return DataFolderExists(AmpPath)
End

/// @brief Shut down the package without closing the USB connection
///
/// In contrast to IPA_DoShutdown() the USB connection stays open, as MIES uses it for the
/// data acquisition and closes it itself when the device is unlocked.
///
/// @returns TRUE on success and FALSE if the package is not initialized
Function IPA_MIES_Shutdown()

	STRUCT IPASeries SIPA

	PerformSubsystemEntry()

	if(!IsInitialized())
		return FALSE
	endif

	IPA_StopTimerTask()

	GetStructure(SIPA)
	SaveControls(SIPA.ipa)

	KillDataFolder/Z $AmpPath

	return TRUE
End

/// @brief Reset the stored control values of all probes to the package defaults and send them to the amplifiers
///
/// The package stores the control values in its preferences, so without the reset the settings of the
/// previous session are sent to the amplifiers on the next mode switch. The probe assignment and the DAC
/// offset trim are kept.
///
/// @returns TRUE on success and FALSE on error
Function IPA_MIES_ResetToDefaults()

	variable probeIndex, ret

	STRUCT IPASeries SIPA

	PerformSubsystemEntry()

	if(!IPA_OkToSendCommand())
		return FALSE
	endif

	GetStructure(SIPA)

	// IPA_InitAllControls also measures the DAC offset trim on the hardware, which is
	// a calibration of the hardware and kept, IPA_InitProbeControls does not change it
	SIPA.ipa.version = IPA_StructVersion
	for(probeIndex = 0; probeIndex < kMaxHeadstages; probeIndex += 1)
		IPA_InitProbeControls(SIPA.ipa, probeIndex)
	endfor

	ret = TRUE
	for(probeIndex = 0; probeIndex < SIPA.numHeadstages; probeIndex += 1)
		// the amplifier keeps the dynamic hold across mode switches and IPA_SetFromStructure does not switch it off
		SutterDAQwrite(SIPA.ipa.HS[probeIndex].ampIndex, 19 + 6 * SIPA.ipa.HS[probeIndex].HSindex, 0, 0, 0)

		// returns FALSE on error and nothing otherwise
		if(IPA_SetFromStructure(SIPA, probeIndex) == FALSE)
			ret = FALSE
		endif
	endfor

	SaveStructure(SIPA)

	return ret
End

/// @brief Set the clamp mode of the given probe
///
/// In contrast to the "VCMode" and "CCMode" keywords of IPA_SetValue() this uses
/// the probe index over all IPA devices, which is also correct for double IPAs
/// and multiple IPA devices.
///
/// Sends all stored control values of the probe to the amplifier.
///
/// @param probeCount   one-based probe index
/// @param currentClamp TRUE for current clamp, FALSE for voltage clamp
///
/// @returns TRUE on success and FALSE on error
Function IPA_MIES_SetClampMode(variable probeCount, variable currentClamp)

	variable probeIndex, ret

	STRUCT IPASeries SIPA

	PerformSubsystemEntry()

	if(probeCount <= 0)
		return FALSE
	endif

	GetStructure(SIPA)

	probeIndex = probeCount - 1
	if(probeIndex >= SIPA.numHeadstages)
		return FALSE
	endif

	SIPA.ipa.HS[probeIndex].vc = currentClamp ? 2 : 0

	// returns FALSE on error and nothing otherwise
	ret = IPA_SetFromStructure(SIPA, probeIndex)
	SaveStructure(SIPA)

	return (ret == FALSE) ? FALSE : TRUE
End

/// @brief Read the clamp mode of the given probe from the amplifier
///
/// @param probeCount one-based probe index
///
/// @returns TRUE for current clamp, FALSE for voltage clamp and NaN on error
Function IPA_MIES_ReadClampModeFromHardware(variable probeCount)

	variable probeIndex, ampIndex, hsIndex, value

	STRUCT IPASeries SIPA

	PerformSubsystemEntry()

	if(probeCount <= 0)
		return NaN
	endif

	GetStructure(SIPA)

	probeIndex = probeCount - 1
	if(probeIndex >= SIPA.numHeadstages)
		return NaN
	endif

	ampIndex = SIPA.ipa.HS[probeIndex].ampIndex
	hsIndex  = SIPA.ipa.HS[probeIndex].HSIndex
	if(ampIndex == kNoDevice)
		return NaN
	endif

	// item 0: gain and VC vs CC of HS#1, item 15: the same for HS#2 of a double IPA
	value = SutterDAQRead(ampIndex, (hsIndex == 0) ? 0 : 15)
	if(value < 0)
		return NaN
	endif

	// VC adds 256
	return (value & 256) ? FALSE : TRUE
End

/// @brief Set a value without changing its enable state
///
/// In contrast to IPA_SetValue() the keywords "VHold", "IHold", "Bridge",
/// "CmComp", "RsComp", "RsCorr" and "RsPred" do not enable the
/// corresponding setting. The value is stored and then sent to the
/// amplifier with the unchanged enable state.
///
/// The automatic functions behave as for MCC amplifiers:
/// - "AutoCellComp" keeps the bridge balance, IPA_SetValue() also stores the
///   found series resistance as bridge balance.
/// - "AutoOffset" is done with the holding disabled, as the automatic offset
///   would otherwise also compensate the holding.
///
/// All other keywords are passed to IPA_SetValue().
///
/// @param probeCount one-based probe index
/// @param setting    keyword of IPA_SetValue()
/// @param value      value in SI units, as for IPA_SetValue()
///
/// @returns TRUE on success and FALSE on error
Function IPA_MIES_SetValue(variable probeCount, string setting, variable value)

	variable probeIndex, bridge, holdOn, dynHoldOn, ret
	string holdOnSetting

	STRUCT IPASeries SIPA

	PerformSubsystemEntry()

	if(probeCount <= 0)
		return FALSE
	endif

	GetStructure(SIPA)

	probeIndex = probeCount - 1
	if(probeIndex >= SIPA.numHeadstages)
		return FALSE
	endif

	// same limits and units as in IPA_SetValue()
	strswitch(setting)
		case IPA_SET_V_HOLD:
			value                        = limit(value, -1, 1)
			SIPA.ipa.HS[probeIndex].hpot = round(value * 1000)
			SaveStructure(SIPA)
			return IPA_SetValue(probeCount, IPA_SET_V_HOLD_ON, SIPA.ipa.HS[probeIndex].hpoton)
		case IPA_SET_I_HOLD:
			value                         = limit(value, -20e-9, 20e-9)
			SIPA.ipa.HS[probeIndex].hcurr = round(value * 1e12)
			SaveStructure(SIPA)
			return IPA_SetValue(probeCount, IPA_SET_I_HOLD_ON, SIPA.ipa.HS[probeIndex].hcurron)
		case IPA_SET_BRIDGE:
			value                          = limit(value, 0, 200e6)
			SIPA.ipa.HS[probeIndex].bridge = value * 1e-6
			SaveStructure(SIPA)
			return IPA_SetValue(probeCount, IPA_SET_BRIDGE_ON, SIPA.ipa.HS[probeIndex].bridgeon)
		case IPA_SET_CM_COMP:
			value                          = limit(value, 0, 100e-12)
			SIPA.ipa.HS[probeIndex].cmcomp = value * 1e12
			break
		case IPA_SET_RS_COMP:
			value                          = limit(value, 0, 100e6)
			SIPA.ipa.HS[probeIndex].rscomp = value * 1e-6
			break
		case IPA_SET_RS_CORR:
			value                          = limit(value, 0, 1)
			SIPA.ipa.HS[probeIndex].rscorr = value * 100
			break
		case IPA_SET_RS_PRED:
			value                          = limit(value, 0, 1)
			SIPA.ipa.HS[probeIndex].rspred = value * 100
			break
		case IPA_SET_AUTO_CELL_COMP:
			bridge = SIPA.ipa.HS[probeIndex].bridge
			ret    = IPA_SetValue(probeCount, setting, value)

			// only the stored value is changed, it is sent when switching to current clamp
			GetStructure(SIPA)
			SIPA.ipa.HS[probeIndex].bridge = bridge
			SaveStructure(SIPA)

			return ret
		case IPA_SET_AUTO_OFFSET:
			if(SIPA.ipa.HS[probeIndex].vc == 0)
				holdOnSetting = IPA_SET_V_HOLD_ON
				holdOn        = SIPA.ipa.HS[probeIndex].hpoton
			else
				// in current clamp the dynamic hold is sent instead of the holding current
				holdOnSetting = IPA_SET_I_HOLD_ON
				holdOn        = SIPA.ipa.HS[probeIndex].hcurron
				dynHoldOn     = SIPA.ipa.HS[probeIndex].trackon
			endif

			if(holdOn)
				IPA_SetValue(probeCount, holdOnSetting, 0)
			endif
			if(dynHoldOn)
				IPA_SetValue(probeCount, IPA_SET_DYN_HOLD_ON, 0)
			endif

			ret = IPA_SetValue(probeCount, setting, value)

			if(holdOn)
				ret = IPA_SetValue(probeCount, holdOnSetting, 1) && ret
			endif
			if(dynHoldOn)
				ret = IPA_SetValue(probeCount, IPA_SET_DYN_HOLD_ON, 1) && ret
			endif

			return ret
		default:
			return IPA_SetValue(probeCount, setting, value)
	endswitch

	// whole cell compensation and Rs correction/prediction are sent together
	SaveStructure(SIPA)

	return IPA_SetValue(probeCount, IPA_SET_RS_CORR_ON, SIPA.ipa.HS[probeIndex].corron)
End

/// @brief Return a stored value
///
/// In contrast to IPA_GetValue() the keywords "VHold" and "IHold" return the
/// stored holding value also when the holding is disabled. All other
/// keywords are passed to IPA_GetValue().
///
/// @param probeCount one-based probe index
/// @param setting    keyword of IPA_GetValue()
///
/// @returns value in SI units, as for IPA_GetValue(), or NaN on error
Function IPA_MIES_GetValue(variable probeCount, string setting)

	variable probeIndex

	STRUCT IPASeries SIPA

	PerformSubsystemEntry()

	if(probeCount <= 0)
		return NaN
	endif

	GetStructure(SIPA)

	probeIndex = probeCount - 1
	if(probeIndex >= SIPA.numHeadstages)
		return NaN
	endif

	strswitch(setting)
		case IPA_SET_V_HOLD:
			return SIPA.ipa.HS[probeIndex].hpot * 1e-3
		case IPA_SET_I_HOLD:
			return SIPA.ipa.HS[probeIndex].hcurr * 1e-12
		default:
			return IPA_GetValue(probeCount, setting)
	endswitch
End
