// Copyright Sutter Instrument Corp. 2015 - 2024

// ---------------- Pragmas ----------------
#pragma IgorVersion = 8.00						// Require Igor version 8.0 or later for compatbility
#pragma rtGlobals=3									// Use modern global access method and strict wave access.
#pragma ModuleName = IPAControl 				//This will become an independent module

Static Strconstant AmpPath = "root:SutterIPAControl"							
Static Constant IPA_StructVersion = 100
Static StrConstant 	kIPAPrefsFileName = "IPAControl.bin"
Static Constant kIPAPrefsRecordID = 0	
Static StrConstant ksPackageName = "SutterIPA"

Static Constant TRUE = 1
Static Constant FALSE = 0
Static Constant SutterXOP_XOPVersion = 2.60			// SutterXOP major version number needs to match SutterPatch, minor version is for info only

Static Constant kLiveMode = -1
Static Constant kNoDevice = -1
Static Constant kIPASingle = 1
Static Constant kIPADouble = 2
Static Constant kSutterInterface = 3
Static Constant kMaxDigBits = 8
Static Constant kMaxAmplifiers = 4
Static Constant kMaxHeadstages = 8 //(2 double IPA * max amplifiers) 

Static Constant kCC_deltaCap = 1.4  // CC circuit has 1.4 pF more headstage capacitance.
Static Constant kStabilityControl = 1  //pF moved to prefs

//-------------------Structure to store amplifier values ------------------------

STRUCTURE ControlValues
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
EndStructure

Structure AmpControls
	double analogOut[2]		//Aux out
	double analogIn[4]	//Aux In
	uchar amptype	//amplifier type
	char serialNum[13]	//serial number
	uchar dout		//Digital Output (1-8)
EndStructure

Structure IPAControls
	uchar version
	struct ControlValues HS[8] //max headstages
EndStructure

Structure IPASeries
	struct IPAControls ipa
	struct AmpControls Amp[4] // max amplifiers
	uchar activeHS
	uchar numHeadstages
	uchar numAmps
EndStructure	
	

static Function SetBit( Variable Bit, Variable BitSet )
	return BitSet | ( 1 << Bit )
End


static Function ClearBit( Variable Bit, Variable BitSet )
	return BitSet & ~( 1 << Bit )
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
		InitControls(ipa)
	endif
End


static Function InitControls(Struct IPAControls &ipa)
	Variable hsindex
	ipa.version = IPA_StructVersion
	for (hsIndex=0; hsIndex<kMaxHeadstages; hsIndex+=1)
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
		ipa.hs[hsindex].DACOffset = 0.0
	endfor
End


//get struct string path
static Function /S Get_StructPath()
	return AmpPath + ":SD_Struct"
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
static Function InitMainStructure()
	Struct IPASeries SIPA
	GetStructure(SIPA)	
	GetControls(SIPA.ipa)
	
	Variable index = 0
	Variable hsindex = 0
	SIPA.numAmps = SutterDAQusbreset()
	
	if (SIPA.numAmps == 0)
		//set up demo mode
		SIPA.numAmps = 1
		SIPA.numHeadstages = 1
		NVAR demo_amptype = $(AmpPath + ":demo_amptype")
		demo_amptype = kIPASingle
		SIPA.amp[0].serialNum = "demo"
		SIPA.ipa.HS[0].ampIndex = 0
		SIPA.ipa.HS[0].HSindex = 0
	else
		String serial
		for (index=0; index<SIPA.numAmps; index+=1)
			serial = SutterDAQSN(index)
			SIPA.amp[index].serialNum = serial
			if (str2num(serial[6]) == 2)
				SIPA.amp[index].ampType = kIPADouble
				SIPA.ipa.HS[hsIndex].ampIndex = index
				SIPA.ipa.HS[hsIndex].HSIndex = 0
				hsindex+=1
				SIPA.ipa.HS[hsIndex].ampIndex = index
				SIPA.ipa.HS[hsIndex].HSIndex = 1
				hsindex+=1
			else
				SIPA.amp[index].ampType = kIPASingle
				SIPA.ipa.HS[hsIndex].ampIndex = index
				SIPA.ipa.HS[hsIndex].HSIndex = 0
				hsindex+=1
			endif
		endfor
		SIPA.numHeadstages = hsindex
	endif
	
	//reset all remaining none connected
	for (index=SIPA.numHeadstages; index<kMaxHeadstages; index+=1)
		SIPA.ipa.HS[index].ampIndex = kNoDevice
		SIPA.ipa.HS[index].HSindex = kNoDevice
	endfor
	
	SaveStructure(SIPA)
	
	return TRUE
End


static Function ActivateHeadstage(	Struct IPASeries &SIPA, Variable HSindex)
	DFREF dfr=$AmpPath
	NVar SD_DIO = dfr:SD_DIO

	SIPA.activeHS = HSindex
	Variable ampindex = SIPA.ipa.hs[HSindex].ampIndex
	SD_DIO = SIPA.Amp[ampIndex].dout
End


static Function CheckXOPVersion()
	String message = "SutterXOP_Win.xop"

#if exists( "SutterXOP_GetXOPVersion" )
	Variable major_version = 0
	Variable minor_version = 0
	SutterXOP_GetXOPVersion( major_version, minor_version )

	if( major_version == SutterXOP_XOPVersion )
		message = ""
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

	if( strlen( message ) > 0 )
		DoAlert /T=( "XOP Error" ) 0, message
		return FALSE
	EndIf

	return TRUE
End


Function IPA_Initialize()
	if (CheckXOPVersion() == TRUE)
		NewDataFolder /O $(AmpPath)	
		DFREF dfr=$AmpPath
		variable /G $(AmpPath + ":SD_Seal") = 0
		variable /G $(AmpPath + ":SD_USB") = 0
		variable /G $(AmpPath + ":SD_DIO") = 0
		variable /G $(AmpPath + ":SD_sweeptime")=0
		variable /G $(AmpPath + ":demo_amptype") = kIPASingle
		Make /O/n=(8,2) $(AmpPath + ":SD_Meter") = 0
		String /G $(AmpPath + ":SD_Struct") = ""
 		InitMainStructure()
 		return TRUE
	endif
	
	return FALSE
End


Function IPA_Shutdown()
	Struct IPASeries SIPA
	GetStructure(SIPA)
	SaveControls(SIPA.ipa)
	
	//kill data folder and all SVAR and NVAR
	KillDataFolder $(AmpPath)	
	
	return TRUE
End


Function IPA_DemoMode()
	NVAR/Z demo_amptype = $(AmpPath + ":demo_amptype")
	if ((!NVAR_Exists(demo_amptype)) || (demo_amptype != kLiveMode))
		return TRUE
	endif
	
	return FALSE 
End


Function IPA_OkToSendCommand()
	if (IPA_DemoMode() == TRUE)
		return FALSE
	else
		return IPA_USBconnected()
	endif
End


Function IPA_USBconnected()
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


static Function ResetUSB()
	SutterDAQReset()
	if (SutterDAQUSBReset())
		Struct IPASeries SIPA
		GetStructure(SIPA)
		ResetAmplifier(SIPA)
	endif
End


static Function ResetAmplifier(Struct IPASeries &SIPA)
	if (IPA_OkToSendCommand() == TRUE)
		SetDacOffset(SIPA)	
		variable step
		sutterdaqwrite(0,11,0,0,3)		//Some dIPAs don't set default filter correctly first time (firmware 207 and earlier)
		for (step=0; step<SIPA.numHeadstages; step++)
			 SetDIPA_fromStructure(SIPA,step)			//This sets amplifier control panel based on stored structure.
		endfor
		ResetAllOutputs(SIPA) 			// This sets digital and analog aux outs
	endif	
End


static Function ReSetAllOutputs(Struct IPASeries &SIPA)	
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


static Function SetCompensation(Struct IPASeries &SIPA, variable probeIndex)  // This sets the Rs Cm compensation along with Rs Prediction %  (all are related)
	if (IPA_OkToSendCommand() == FALSE)
		return FALSE
	endif
	
	if (probeIndex > SIPA.numHeadstages)
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


static Function SetCorrection(Struct IPASeries &SIPA, variable probeIndex)
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


static Function SetDIPA_fromStructure(Struct IPASeries &SIPA, variable probeIndex)  
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
		ModifyCapMag(setval)
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
	setval=max(51,round(SIPA.ipa.HS[probeIndex].lag*5.12))
	if (HS)
		SutterDAQwrite(Amp,23,10,(setval&0xff00)/256,setval&0x00ff) //14bit unsigned?
	else
		SutterDAQwrite(Amp,2,10,(setval&0xff00)/256,setval&0x00ff)
	endif
	
	//Rs corr% turns off in IC
	// setval is the product of Rs corr% AND Rs
	//SDsetvar4,SDsetvar5,SDsetvar17: Whole cell compensation turns off in IC
	//Rs can stay on, Pred value is OK, but need to switch off (SwCtrl2) Cm is off in IC

//THIS NEEDS TO BE HS SPECIFIC AND KNOW SWITCH BETWEEN VC AND CC!
 	SetCompensation(SIPA,probeIndex)
 	SetCorrection(SIPA,probeIndex)
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
			//Enter code for slow hold here:
		else
			setval = 1.63835*SIPA.ipa.HS[probeIndex].hcurr*SIPA.ipa.HS[probeIndex].hcurron
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


static Function ModifyCapMag (variable &Value)
	Value +=  (kCC_deltaCap - kStabilityControl)*655.32
	if (Value<0)
		Value = 0
	elseif (Value>16383)
		Value = 16383 
	endif
	
	return TRUE
end


static Function Auto_WholeCellCompensation(Struct IPASeries &SIPA, Variable probeIndex) 
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
	
	return TRUE
End


static Function Auto_ElectrodeCompensation(Struct IPASeries &SIPA, Variable probeIndex)
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
	
	return TRUE
End


static Function SetDigOut(Struct IPASeries &SIPA, Variable ampindex, Variable bit, Variable state)
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


static Function SetAllDigOut(Struct IPASeries &SIPA, Variable ampindex, Variable state)
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


static Function SetAuxOut(Struct IPASeries &SIPA, Variable ampIndex, Variable channel, Variable value)	
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
	SIPA.amp[ampindex].analogOut[channel] = value

	return TRUE
End


static Function ReadAuxIn(Struct IPASeries &SIPA, Variable ampIndex, Variable channel)
	Variable value = nan
	if ((ampindex<0) || (ampindex>SIPA.numAmps))
		return FALSE
	endif

	if ((channel <0) || (channel >=4))
		return FALSE
	endif
	 
	Variable ADCin
	variable Amptype = SIPA.amp[ampindex].amptype
	
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
	SIPA.amp[ampindex].analogIn[channel] = value
	SaveStructure(SIPA)

	return TRUE
End


//------------------IPA Delay Functions-------------------------------

Function IPA_tickdelay(timeval) 		//for inaccurate short delays (1 tick ~ 17ms)
	variable timeval
	variable t0 = ticks
	
	do
	while(ticks-t0<timeval)
End

Function IPA_usdelay(timeval)  		//for microsecond delays 
	variable timeval
	variable t0 = stopmstimer(-2)

	do
	while(stopmstimer(-2)-t0<timeval)
End



//-------------Zero offset for DAC ----------------------------------------------

static Function ZeroOffset(variable ampindex, variable channel, variable value)
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


static Function SetDACOffset(Struct IPASeries &SIPA)	
	Variable hsIndex
	for (hsIndex=0; hsIndex<SIPA.numHeadstages; hsIndex+=1)
		if (SIPA.ipa.HS[hsindex].DACoffset !=0)	
			ZeroOffset(SIPA.ipa.HS[hsindex].ampIndex,SIPA.ipa.HS[hsindex].HSIndex,SIPA.ipa.HS[hsindex].DACoffset)
		endif
	endfor
End


Function IPA_GetValue(variable probe_count, string value)
	if (probe_count <=0)
		return FALSE
	endif
	//one based
	Variable probeIndex = probe_count - 1
	Variable ampIndex
	
	Struct IPASeries SIPA
	GetStructure(SIPA)

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
		case "CCMode":
			return (SIPA.ipa.HS[probeIndex].vc &&1)
			break
		case "VCMode":
			return !(SIPA.ipa.HS[probeIndex].vc)
			break 
		case "Filter":
		case "IFilter":
		case "VFilter":
			return str2num(stringfromlist(SIPA.ipa.HS[probeIndex].filter,"500;1000;2000;5000;10000;20000"))
			break
		case "VGain":
			if (SIPA.ipa.HS[probeIndex].vc==0) //Voltage Clamp
				return 10
			else
				return str2num(stringfromlist(SIPA.ipa.HS[probeIndex].gaincc,"10;20;50;100;200;500"))
			endif
			break
		case "IGain":
			if (SIPA.ipa.HS[probeIndex].vc==0)
				return str2num(stringfromlist(SIPA.ipa.HS[probeIndex].gainvc,"0.5;1;2.5;5;10;25"))*1e9
			else
				return 5e8
			endif
			break
		case "OffsetLock":
			return SIPA.ipa.HS[probeIndex].offsetlock
			break
		case "Offset":
			return SIPA.ipa.HS[probeIndex].offset /2^16
			break
		case "LJP":
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
		case "ECompTau":					// was "ECompPhase"
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
			else
				return 0.0
			endif
		case "VHold":
			if (SIPA.ipa.HS[probeIndex].hpoton == TRUE)
				return SIPA.ipa.HS[probeIndex].hpot*1e-3
			else
				return 0.0
			endif
			break
		case "IMon":
			Wave SD_Meter = dfr:SD_Meter
			return (SD_Meter[probeIndex][0])
		case "VMon":
			Wave SD_Meter = dfr:SD_Meter
			return (SD_Meter[probeIndex+1][1])
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
			ReadAuxIn(SIPA,ampIndex,1)
			return SIPA.amp[ampindex].analogIn[0]
		case "AuxIn2":
			ampIndex = SIPA.ipa.HS[probeIndex].ampIndex
			ReadAuxIn(SIPA,ampIndex,1)
			return SIPA.amp[ampindex].analogIn[1]
		case "AuxIn3":
			ampIndex = SIPA.ipa.HS[probeIndex].ampIndex
			ReadAuxIn(SIPA,ampIndex,1)
			return SIPA.amp[ampindex].analogIn[2]
		case "AuxIn4":
			ampIndex = SIPA.ipa.HS[probeIndex].ampIndex
			ReadAuxIn(SIPA,ampIndex,1)
			return SIPA.amp[ampindex].analogIn[3]
	endswitch
End


Function IPA_SetValue(variable probe_count, string setting, variable value )
	if (probe_count <=0)
		return FALSE
	endif
	
	Struct IPASeries SIPA
	GetStructure(SIPA)
	
	Variable probeIndex = probe_count-1
	Variable ampl_index = SIPA.ipa.HS[probeIndex].ampIndex
	Variable amptype = SIPA.amp[ampl_index].amptype
	Variable amp_channel = SIPA.ipa.HS[probeIndex].HSindex
	Variable oktosend = IPA_OKToSendCommand()
	
	Variable StabilityControl
	variable setval
		
	strswitch (setting)
		case "Reset":
			ResetControls(SIPA)
			break
		case "SelectHS":
		case "SelectProbe":	
			ActivateHeadstage(SIPA, probeIndex)
			break
		case "CCMode":
		  	SIPA.ipa.HS[probeIndex].vc = 2
		  	SetDIPA_fromStructure(SIPA, amp_channel)
			break
		case "VCMode":
		  	SIPA.ipa.HS[probeIndex].vc= 0
		  	SetDIPA_fromStructure(SIPA, amp_channel)
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
				if (amp_channel)
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
				if (amp_channel)
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
				if (amp_channel)
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
			if (SIPA.ipa.HS[probeIndex].vc == 2)
				value += kCC_deltaCap - kStabilityControl
			endif				
			setval =  round(value*655.32)
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
			SetCompensation(SIPA,probeIndex)
			SetCorrection(SIPA,probeIndex)
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
			SetCompensation(SIPA,probeIndex)
			SetCorrection(SIPA,probeIndex)
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
			SetCompensation(SIPA,probeIndex)
			SetCorrection(SIPA,probeIndex)
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
			SetCorrection(SIPA,probeIndex)
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
			setval =  value*round(SIPA.ipa.HS[probeIndex].bridge*81.92)
			if (oktosend)
				SutterDAQwrite(ampl_index,2+21*amp_channel,5,(setval&0xff00)/256,setval&0x00ff)
			endif
			SIPA.ipa.HS[probeIndex].bridgeon = !value
			break	
		case "AutoEComp":
			Auto_ElectrodeCompensation(SIPA,probeIndex)
			break
		case "AutoCellComp":
			Auto_WholeCellCompensation(SIPA,probeIndex)
			break				
		case "RsCompOn":	// Rs Compensation enabled
			SIPA.ipa.HS[probeIndex].compon = value
			SetCompensation(SIPA,probeIndex)
			break
		case "RsCorrOn":	//Prediction/Correction enabled
			SIPA.ipa.HS[probeIndex].corron = value
			SetCompensation(SIPA,probeIndex)
			SetCorrection(SIPA,probeIndex)
			break
		case "DynHold":
			if (abs(value)>1)
				value = sign(value)
			endif
			value*=1000
			setval =  round(value*32.767)
			if (oktosend)
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
					SutterDAQwrite(ampl_index,19,0,0,0)
				endif
			endif		
			break	
		case "ECompOn":		//Current Clamp electrode compensation enabled.
			if (SIPA.ipa.HS[probeIndex].vc == 2) //only set if in CC
				setval=value*round((SIPA.ipa.HS[probeIndex].fastmag+kCC_deltaCap-kStabilityControl)*655.32)
				if (oktosend)
					SutterDAQwrite(ampl_index ,2,2,(setval&0xff00)/256,setval&0x00ff)
				endif
			endif	
			SIPA.ipa.HS[probeIndex].capneuton = value
			break
		case "VHoldOn":		//Holding potential set
			if (SIPA.ipa.HS[probeIndex].vc == 0) //only set if in VC
				setval = 32.767*SIPA.ipa.HS[probeIndex].hpot*value
				if (oktosend)
					SutterDAQwrite(ampl_index,16,0,(setval&0xff00)/256,setval&0x00ff)
				endif
				SIPA.ipa.HS[probeIndex].hpoton = value
			endif
			break
		case "IHoldOn":		//Holding current set
			if (SIPA.ipa.HS[probeIndex].vc == 2) //only set if in CC
				setval = 1.63835*SIPA.ipa.HS[probeIndex].hcurr*value
				if (oktosend)
					SutterDAQwrite(ampl_index,16,0,(setval&0xff00)/256,setval&0x00ff)
				endif
			endif
			SIPA.ipa.HS[probeIndex].hcurron = value
			break
		case "DigOutWord": //not amplifier specific
			SetAllDigOut(SIPA,ampl_index,value)
			break	
		case "DigOut1":
			SetDigOut(SIPA,ampl_index, 0, value)
			break
		case "DigOut2":
			SetDigOut(SIPA,ampl_index, 1, value)
			break
		case "DigOut3":
			SetDigOut(SIPA,ampl_index, 2, value)
			break
		case "DigOut4":
			SetDigOut(SIPA,ampl_index, 3, value)
			break
		case "DigOut5":
			SetDigOut(SIPA,ampl_index, 4, value)
			break
		case "DigOut6":
			SetDigOut(SIPA,ampl_index, 5, value)
			break
		case "DigOut7":
			SetDigOut(SIPA,ampl_index, 6, value)
			break
		case "DigOut8":
			SetDigOut(SIPA,ampl_index, 7, value)
			break
		case "AuxOut1":
			SetAuxOut(SIPA, ampl_index,1,value)
			break
		case "AuxOut2":
			SetAuxOut(SIPA, ampl_index,2,value)
			break
		case "Reconnect":
			ResetUSB()
			return TRUE
		case "AutoOffset":
			if (SIPA.ipa.HS[probeIndex].offsetlock)
				return FALSE
			endif
			ZeroIPAOffset(SIPA,probeIndex)
			return TRUE
		case "SealTest":
			if (oktosend)
				if (value==0)
					SutterDAQWrite(0,18,0,10,10)
				else 
					SutterDAQwrite(0,18,1,10,value)
				endif
			endif
			SIPA.ipa.HS[probeIndex].seal = value
		case "Buzz":
			Buzz(SIPA,probeIndex,value)
			break
//			case "AutoBridge":
//				if (IPA_AutoBridge() != TRUE)
//					return FALSE
//				endif
//				return TRUE
		DEFAULT:
			return FALSE  //Not a proper keyword
	endswitch
	
	SaveStructure(SIPA)
	
	return TRUE
End	


static Function ResetControls(Struct IPASeries &SIPA)
	//Reset Structure Wave
	InitControls(SIPA.IPA)	
	IPA_SetValue(0,"SelectHS",1)
	
	return TRUE
End	


static Function ZeroIPAOffset(Struct IPASeries &SIPA, Variable probeIndex)	//This is the automatic offset button
	Variable ampl_index = SIPA.ipa.HS[probeIndex].ampIndex
	Variable amp_channel = SIPA.ipa.HS[probeIndex].HSindex
	Variable oktosend = IPA_OKToSendCommand()
	variable readvalue
	variable myoffset = SIPA.ipa.HS[probeIndex].offset * 2^16
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
		
		if (abs(readvalue*SIPA.ipa.HS[probeIndex].gainvc) > 9.9)
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
			if (abs(myoffset)>16384)
				myoffset = 16384*sign(myoffset) //limit to +/- 250 mV
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
		if (abs(myoffset)>16384)
			myoffset = 16384*sign(myoffset)
		endif
		myoffset += myljp
		
		if (oktosend)
			if (amp_channel==1)   //Second HS on dIPA
				SutterDAQwrite(ampl_index,17,4,(myoffset&0xff00)/256,myoffset&0x00ff)
			else
				SutterDAQwrite(ampl_index,17,1,(myoffset&0xff00)/256,myoffset&0x00ff)
			endif
		endif
	endif
	
	offsetMV =myoffset*1000/2^16  //convert offset to volts
	SIPA.ipa.HS[probeIndex].offset = myoffset
	
	return TRUE
end

//--------------- ZAP, BUZZ and SEALTEST ---------------------------

static Function Buzz(Struct IPASeries &SIPA, Variable probeIndex, Variable duration)	//This is the automatic offset button
	if (IPA_OKToSendCommand() == FALSE)
		return FALSE
	endif
	
 	if (SIPA.ipa.HS[probeIndex].vc != 2) //CC mode
 		return FALSE
 	endif

	Variable ampl_index = SIPA.ipa.HS[probeIndex].ampIndex
	Variable amp_channel = SIPA.ipa.HS[probeIndex].HSindex

	SutterDAQwrite(0,2,1,3,0)
	SutterDAQwrite(0,2,2,40,0)
	
	variable step, stepsign
	stepsign=1
	for (step=0; step<(1*duration); step+=1)
		if (stepsign==1)
			SutterDAQwrite(0,16,0,192,0)
			stepsign= -1
		else
			SutterDAQwrite(0,16,0,64,0)
			stepsign=1
		endif
		IPA_usdelay(1000)
	endfor
	
	variable setval
	setval=round((SIPA.ipa.HS[probeIndex].fastmag+kCC_deltaCap-kStabilityControl)*655.32)*SIPA.ipa.HS[probeIndex].capneuton
	SutterDAQwrite(0,2,2,(setval&0xff00)/256,setval&0x00ff)	
	setval=round((SIPA.ipa.HS[probeIndex].fastphase-0.1)*1023/4.4)
	SutterDAQwrite(0,2,1,(setval&0xff00)/256,setval&0x00ff)	
	setval = 1.63835*SIPA.ipa.HS[probeIndex].hcurr*SIPA.ipa.HS[probeIndex].hcurron
	SutterDAQwrite(0,16,0,(setval&0xff00)/256,setval&0x00ff)

	return TRUE
End