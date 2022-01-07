#pragma rtGlobals=1		// Use modern global access method.

// This file was created by "Nicholas Hartell <nh88 (at) leicester dot ac dot uk>".
// With minor modifications by "Thomas Braun <thomas dot braun (at) byte minus physics dot de>".

#if exists("VDTGetPortList2")

Menu "Arduino"
		"Open Arduino Sequencer", ARDLaunchSeqPanel()
End Menu

Structure ArduinoSeqSettings
	NVAR gEpochDuration
	NVAR gPulseDuration
	NVAR gPulseInterval
	NVAR gPulseNumber
	NVAR gDutyCycle
	NVAR gPortDBitValue
	NVAR gPortBBitValue
	NVAR gActivePin
	NVAR gWhichCom	// this will be the position in the S_VDT list
	SVAR gWhichComStr
	SVAR gVDT2Message
	NVAR gAllowParallel
	NVAR gAI5
	NVAR gAI4
	NVAR gAI3
	NVAR gAI2
	NVAR gAI1
	NVAR gAI0
	NVAR gActiveInputPin
	Wave wp2
	Wave wp3
	Wave wp4
	Wave wp5
	Wave wp6
	Wave wp7
	Wave wp8
	Wave wp9
	Wave wp10
	Wave wp11
	Wave wp12
	Wave wp13
	Wave wSeqDefaults
	NVAR gSeqRepeats
	NVAR gSeqInterval
	NVAR gSeqDuration
	NVAR gTotalDuration
	NVAR gEndToStartInterval
	SVAR gMessageStr
EndStructure

Function ARDSetSeqSettings(ards)
	Struct ArduinoSeqSettings &ards
	String cdf = getdatafolder(1)
	SetDataFolder root:
	SetDataFolder ImageHardware
	SetDataFolder Arduino
	NVAR ards.gEpochDuration
	NVAR ards.gPulseDuration
	NVAR ards.gPulseInterval
	NVAR ards.gPulseNumber
	NVAR ards.gDutyCycle
	NVAR ards.gPortDBitValue
	NVAR ards.gPortBBitValue
	NVAR ards.gActivePin
	NVAR ards.gWhichCom
	SVAR ards.gWhichComStr
	SVAR ards.gVDT2Message
	NVAR ards.gAllowParallel
	NVAR ards.gAI5
	NVAR ards.gAI4
	NVAR ards.gAI3
	NVAR ards.gAI2
	NVAR ards.gAI1
	NVAR ards.gAI0
	NVAR ards.gActiveInputPin
	Wave ards.wp2
	Wave ards.wp3
	Wave ards.wp4
	Wave ards.wp5
	Wave ards.wp6
	Wave ards.wp7
	Wave ards.wp8
	Wave ards.wp9
	Wave ards.wp10
	Wave ards.wp11
	Wave ards.wp12
	Wave ards.wp13
	Wave ards.wSeqDefaults
	NVAR ards.gSeqRepeats
	NVAR ards.gSeqInterval
	NVAR ards.gSeqDuration
	NVAR ards.gTotalDuration
	NVAR ards.gEndToStartInterval
	SVAR ards.gMessageStr
	SetDataFolder $cdf
End

Function ARDInitialiseSeqGlobals()		// Launches the globals required
	String cdf = getdatafolder(1)
	SetDataFolder root:
	if (!(Datafolderexists ("ImageHardware")))
		NewDataFolder ImageHardware
	endif
	SetDataFolder ImageHardware
	if (!(DataFolderExists ("Arduino")))
		NewDataFolder Arduino
	endif
	SetDataFolder Arduino
	Variable/G gEpochDuration = 0
	Variable/G gPulseDuration =  0	// ms
	Variable/G gPulseInterval = 0		// ms
	Variable/G gPulseNumber = 0	// number
	Variable/G gDutyCycle = 0	// percent

	Variable/G gActivePin = NaN
	Variable/G gWhichCom

	String/G gVDT2Message = "Not Intitialised"
	Variable/G gAllowParallel = 0	// default is to allow only one pin to be active at a time
	Variable/G gAI5 = 0
	Variable/G gAI4 = 0
	Variable/G gAI3 = 0
	Variable/G gAI2 = 0
	Variable/G gAI1 = 0
	Variable/G gAI0 = 0
	Variable/G gPortDBitValue
	Variable/G gPortBBitValue
	Variable/G gActiveInputPin = Nan

	String/G gProtocolListStr = ""

	String ArdSeqPathStr = ParseFilePath(1, FunctionPath(""), ":", 1, 0) + "Sequence Files:"
	NewPath/O/Q ArdSeqPath, ArdSeqPathStr
	gProtocolListStr = IndexedFile(ArdSeqPath,-1,".ibw")

	Make /O/N=1 wp2,wp3,wp4,wp5,wp6,wp7,wp8,wp9,wp10,wp11,wp12,wp13
	wp2=0;wp3=0;wp4=0;wp5=0;wp6=0;wp7=0;wp8=0;wp9=0;wp10=0;wp11=0;wp12=0;wp13=0
	// Should try to load default sequence wave and if not found, create it

	String FileNameStr = "Default Sequence.ibw"
	LoadWave/Q/O/P=ArdSeqPath FileNameStr
	if (V_Flag == 1)		// then one wave has been successfully loaded
		Wave wSeqDefaults = wSeqDefaults
	else		// need to create a default version of the wave
		ARDCreateDefaultSeqWave()
		ARDSaveSeqWave("Default Sequence")
	endif

//	STRUCT ArduinoSeqSettings ards
//	ARDSetSeqSettings(ards)
	Variable/G gSeqRepeats = 0
	Variable/G gSeqInterval = 0
	String/G gMessageStr ="Awaiting Command"

	Variable/G gSeqRepeats = wSeqDefaults[0][0]
	Variable/G gSeqDuration = wSeqDefaults[1][0]
	Variable/G gSeqInterval = wSeqDefaults[2][0]
	Variable/G gWhichCom = wSeqDefaults[3][0]

	Variable/G gTotalDuration = Nan
	Variable/G gEndToStartInterval = Nan
	String/G gWhichComStr = ""
	VDTGetPortList2
	gWhichComStr = stringFromList(gWhichCom, S_VDT)	// this should be the real position of the com is S_VDT

	SetDataFolder $cdf
End

Function ARDCreateDefaultSeqWave()
	String cdf = getdatafolder(1)
	SetDataFolder root:
	if (!(Datafolderexists ("ImageHardware")))
		NewDataFolder ImageHardware
	endif
	SetDataFolder ImageHardware
	if (!(DataFolderExists ("Arduino")))
		NewDataFolder Arduino
	endif
	SetDataFolder Arduino

	Make /O/N=(8,11) wSeqDefaults	// this is a wave that holds all of the data for the various parameters

	// Rows 0-7 represent EventType, Event Duration, Pulse Duration, PulseInterval, PulseNumber, DutyCycle (for PWM),PortDBitPattern, PortCBitPattern
	// the last two rows represent values for the bitpatterns for ports D and C
	// Bit 1 is 8, 2 is 9, 3 is 10, 4 is 11, 5 is 12 and 6 is 13
	// Bit 1 is 2, Bit 2 is 3, Bit 3 is 4, Bit 4 is 5 Bit 5 is 6 and Bit 6 is 7
	// Columns 1 - 10 represent epochs A - J
	wSeqDefaults = nan
	// use the first column for sequence repeats and sequence duration, the start to start interval of the sequence and then the position in S_VDT of the COM

	// We should save the actual position of the port in the S_VDT list which will start from zero
	// Therefore, if -1 is stored, then we should no that we don't know.

	wSeqDefaults [][0] = {1,1.5,1.5,2}		// if we have 3 COM options, then need to add one because the first option in the pop string will be "none"
	wSeqDefaults [][1] = {3,500,1,50,1,0,0,1}	//EventType, Event Duration, Pulse Duration, PulseInterval, PulseNumber, DutyCycle (for PWM)
	wSeqDefaults [][2] = {3,1000,1,50,1,20,0,2}
	wSeqDefaults [][3] = {1,0,0,0,0,0,0,0}
	wSeqDefaults [][4] = {1,0,0,0,0,0,0,0}
	wSeqDefaults [][5] = {1,0,0,0,0,0,0,0}
	wSeqDefaults [][6] = {1,0,0,0,0,0,0,0}
	wSeqDefaults [][7] = {1,0,0,0,0,0,0,0}
	wSeqDefaults [][8] = {1,0,0,0,0,0,0,0}
	wSeqDefaults [][9] = {1,0,0,0,0,0,0,0}
	wSeqDefaults [][10] = {1,0,0,0,0,0,0,0}
	SetDataFolder $cdf

End

Function ARDSaveSeqWave(FileNameStr)
	String FileNameStr
	sprintf FileNameStr, "%s.ibw", FileNameStr
	String cdf = getdatafolder(1)

	String ArdSeqPathStr = ParseFilePath(1, FunctionPath(""), ":", 1, 0) + "Sequence Files:"
	NewPath/O/Q ArdSeqPath, ArdSeqPathStr

	SetDataFolder root:ImageHardware:Arduino
	Wave wSeqDefaults =wSeqDefaults
	Save/O/P=ArdSeqPath wSeqDefaults as FileNameStr
	SetDataFolder $cdf
End

Function ARDSaveCurrentSeqWave()
	Wave wSeqDefaults = root:ImageHardware:Arduino:wSeqDefaults

	String ArdSeqPathStr = ParseFilePath(1, FunctionPath(""), ":", 1, 0) + "Sequence Files:"
	NewPath/O/Q ArdSeqPath, ArdSeqPathStr

	Variable tmpVar
	String FilterStr = "Igor Binary Files (*.ibw):.ibw;"
	Open/D/P=ArdSeqPath/F=FilterStr tmpVar
	String FileNameStr
	FileNameStr = replaceString(ArdSeqPathStr, S_FileName, "")
	FileNameStr = replaceString(".ibw", FileNameStr, "")	// if this is already present, remove it
	FileNameStr += ".ibw"
	Save/O/P=ArdSeqPath wSeqDefaults as FileNameStr
	// update the wave list and
	String cdf = getdatafolder(1)
	SetDataFolder root:ImageHardware:Arduino
	SVAR ProtocolListStr = gProtocolListStr
	ProtocolListStr = IndexedFile(ArdSeqPath,-1,".ibw")
	PopupMenu QuickSeqLoadPop, win=ArduinoSeq_Panel, value= #"root:ImageHardware:Arduino:gProtocolListStr"
	SetDataFolder $cdf
End

Function ARDLoadSeqWave()
	String cdf = getdatafolder(1)
	SetDataFolder root:
	if (!(Datafolderexists ("ImageHardware")))
		NewDataFolder ImageHardware
	endif
	SetDataFolder ImageHardware
	if (!(DataFolderExists ("Arduino")))
		NewDataFolder Arduino
	endif
	SetDataFolder Arduino

	String ArdSeqPathStr = ParseFilePath(1, FunctionPath(""), ":", 1, 0) + "Sequence Files:"
	NewPath/O/Q ArdSeqPath, ArdSeqPathStr

	Loadwave/H/O
	SetDataFolder $cdf
End

Function/T ARDCOMListForPop()
	VDTGetPortList2	// this now puts the list into S_VDT

	string PopStr = "\"None"
	Variable Counter
	String tmpStr
	PopStr = "\"None"
	Variable NumItems = ItemsInList(S_VDT)
	if (NumItems !=0)
		For (Counter = 0; Counter < NumItems; Counter +=1)
			tmpStr = stringfromList(Counter, S_VDT)
			PopStr = PopStr + ";" + tmpStr
		EndFor
	else
		PopStr = PopStr + ";"
	endif
	PopStr += "\""
	Return PopStr

End

Function ARDLaunchSeqPanel()
	String cdf = getdatafolder(1)
	ARDInitialiseSeqGlobals()

	Variable Left, Top, Right, Bottom
	Left = 300
	Top = 50
	Right = 542
	Bottom = 700

	STRUCT ArduinoSeqSettings ards
	ARDSetSeqSettings(ards)
	SetDataFolder root:
	SetDataFolder ImageHardware
	SetDataFolder Arduino
	DoWindow/K ArduinoSeq_Panel
	NewPanel /W=(Left, Top, Right, Bottom)/K=1 as "Arduino Sequencer"
	DoWindow/C ArduinoSeq_Panel

	SetDrawLayer UserBack
	SetDrawEnv linefgc= (48059,48059,48059)
	DrawLine 14,218,226,218

	GroupBox SeqGroup,pos={4,5},size={234,640},title="Sequence Controller"

	GroupBox ArduinoControls,pos={9,24},size={224,66},title="Arduino"

	// The mode will be 1 for None and 2 for the first in the S_VDT list. Therefore, need to add 2 to the gWhichCom

	PopupMenu WhichCOMPop,pos={62,45},size={164,20},bodyWidth=166,title="COM Port", proc=ARDWhichComPopMenuProc
	PopupMenu WhichCOMPop,mode=(2+ards.gWhichCom),value= #ARDCOMListForPop()
	PopupMenu WhichCOMPop help={"Select the COM port to which your Arduino is connected"}

	SetVariable MessageStrSetVar,pos={15,70},size={211,15},bodyWidth=176,title="\\K(65535,0,0)Status:"
	SetVariable MessageStrSetVar,frame=0
	SetVariable MessageStrSetVar,value= root:ImageHardware:Arduino:gMessageStr,noedit= 1

	GroupBox Controller,pos={9,97},size={224,158},title="Pin Out Controller"
	PopupMenu EpochPopup,pos={17,117},size={89,20},bodyWidth=60,proc=ARDEpochPopMenuProc,title="Epoch"
	PopupMenu EpochPopup,mode=1,popvalue="A",value= #"\"A;B;C;D;E;F;G;H;I;J;K\""
	PopupMenu EpochEvent,pos={138,117},size={88,20},bodyWidth=60,proc=ARDEpochEventPopMenuProc,title="Event"
	PopupMenu EpochEvent,mode=3,popvalue="Pulse",value= #"\"Off;DC;Pulse\""
	SetVariable EpochDurationSetVar,pos={77,141},size={149,15},bodyWidth=60,proc=ARDStorePinValuesSetVarProc,title="Epoch Duration (ms)"
	SetVariable EpochDurationSetVar,format="%2.1f"
	SetVariable EpochDurationSetVar,limits={0.1,10000,0.1},value= root:ImageHardware:Arduino:gEpochDuration
	SetVariable PulseDurationSetvar,pos={81,160},size={145,15},bodyWidth=60,proc=ARDStorePinValuesSetVarProc,title="Pulse Duration (ms)"
	SetVariable PulseDurationSetvar,format="%2.1f"
	SetVariable PulseDurationSetvar,limits={0.1,5000,0.1},value= root:ImageHardware:Arduino:gPulseDuration
	SetVariable PulseIntervalSetvar,pos={86,179},size={140,15},bodyWidth=60,proc=ARDStorePinValuesSetVarProc,title="Pulse Interval (ms)"
	SetVariable PulseIntervalSetvar,format="%2.1f"
	SetVariable PulseIntervalSetvar,limits={0.1,5000,0.1},value= root:ImageHardware:Arduino:gPulseInterval
	SetVariable PulseNumberSetvar,pos={108,198},size={118,15},bodyWidth=60,proc=ARDStorePinValuesSetVarProc,title="Pulse Number"
	SetVariable PulseNumberSetvar,format="%2.1f"
	SetVariable PulseNumberSetvar,limits={0,1000,1},value= root:ImageHardware:Arduino:gPulsenumber

	TitleBox PinTitle,pos={17,201},size={17,12},title="Pins",frame=0

	CheckBox EpochCheck13,pos={14,235},size={16,14},proc=ARDPortDBitCheckProc,title=""
	CheckBox EpochCheck13,value= 0
	CheckBox EpochCheck12,pos={30,235},size={16,14},proc=ARDPortDBitCheckProc,title=""
	CheckBox EpochCheck12,value= 0
	CheckBox EpochCheck11,pos={47,235},size={16,14},proc=ARDPortDBitCheckProc,title=""
	CheckBox EpochCheck11,value= 0
	CheckBox EpochCheck10,pos={64,235},size={16,14},proc=ARDPortDBitCheckProc,title=""
	CheckBox EpochCheck10,value= 0
	CheckBox EpochCheck9,pos={81,235},size={16,14},proc=ARDPortDBitCheckProc,title=""
	CheckBox EpochCheck9,value= 0
	CheckBox EpochCheck8,pos={98,235},size={16,14},proc=ARDPortDBitCheckProc,title=""
	CheckBox EpochCheck8,value= 0
	CheckBox EpochCheck7,pos={129,235},size={16,14},proc=ARDPortBBitCheckProc,title=""
	CheckBox EpochCheck7,value= 0
	CheckBox EpochCheck6,pos={145,235},size={16,14},proc=ARDPortBBitCheckProc,title=""
	CheckBox EpochCheck6,value= 0
	CheckBox EpochCheck5,pos={162,235},size={16,14},proc=ARDPortBBitCheckProc,title=""
	CheckBox EpochCheck5,value= 0
	CheckBox EpochCheck4,pos={179,235},size={16,14},proc=ARDPortBBitCheckProc,title=""
	CheckBox EpochCheck4,value= 0
	CheckBox EpochCheck3,pos={196,235},size={16,14},proc=ARDPortBBitCheckProc,title=""
	CheckBox EpochCheck3,value= 0
	CheckBox EpochCheck2,pos={213,235},size={16,14},proc=ARDPortBBitCheckProc,title=""
	CheckBox EpochCheck2,value= 0
	TitleBox Pin13,pos={14,222},size={12,12},title="13",frame=0
	TitleBox Pin12,pos={30,222},size={12,12},title="12",frame=0
	TitleBox Pin11,pos={47,222},size={12,12},title="11",frame=0
	TitleBox Pin10,pos={64,222},size={12,12},title="10",frame=0
	TitleBox Pin9,pos={85,222},size={6,12},title="9",frame=0
	TitleBox Pin8,pos={102,222},size={6,12},title="8",frame=0
	TitleBox Pin7,pos={132,222},size={6,12},title="7",frame=0
	TitleBox Pin6,pos={148,222},size={6,12},title="6",frame=0
	TitleBox Pin5,pos={165,222},size={6,12},title="5",frame=0
	TitleBox Pin4,pos={182,222},size={6,12},title="4",frame=0
	TitleBox Pin3,pos={199,222},size={6,12},title="3",frame=0
	TitleBox Pin2,pos={216,222},size={6,12},title="2",frame=0

	// Buttons start disabled so that they can only be enabled once the arduino is contacted and a pattern has been sent

	GroupBox SequenceRepeatGroup,pos={9,428},size={224,66},title="Sequence Repeater"
	CheckBox MinSeqIntervalCheck,pos={16,463},size={56,24},proc=ARDMinIntervalCheckProc,title="\\JCAuto\rMinimum"
	CheckBox MinSeqIntervalCheck,value= 0,side= 1
	SetVariable SeqIntervalSetVar,pos={78,468},size={152,15},bodyWidth=50,proc=ARDStorePinValuesSetVarProc,title="Start-Start Interval (s)"
	SetVariable SeqIntervalSetVar,format="%2.2f", limits={0,100,0.01}
	SetVariable SeqIntervalSetVar,value= root:ImageHardware:Arduino:gSeqInterval
	SetVariable SeqRepetitionsSetVar,pos={96,448},size={134,15},bodyWidth=50,proc=ARDStorePinValuesSetVarProc,title="Sequence Repeats"
	SetVariable SeqRepetitionsSetVar,format="%g"
	SetVariable SeqRepetitionsSetVar,value= root:ImageHardware:Arduino:gSeqRepeats

	SetVariable SeqIntervalSetVar,pos={78,469},size={152,15},bodyWidth=50,proc=ARDStorePinValuesSetVarProc,title="Start-Start Interval (s)"
	SetVariable SeqIntervalSetVar,format="%2.2f"
	SetVariable SeqIntervalSetVar,value= root:ImageHardware:Arduino:gSeqInterval

	Button SendSequenceButton,pos={16,502},size={210,20},proc=ARDSeqButtonProc,title="Send Sequence To Arduino"
	Button SendSequenceButton,fColor=(49151,49152,65535),disable=2

	GroupBox SequenceLoadGroup,pos={9,530},size={224,74},title="Sequence Loader"
	Button LoadSeqButton,pos={16,549},size={100,20},proc=ARDSeqButtonProc,title="Load New"
	Button SaveSeqButton,pos={125,549},size={100,20},proc=ARDSeqButtonProc,title="Save Current"
	PopupMenu QuickSeqLoadPop,pos={15,577},size={211,20},bodyWidth=160,proc=ARDLoadProtocolPopMenuProc,title="Quick Load"
	PopupMenu QuickSeqLoadPop,mode=1,popvalue="Default Sequence",value= #"root:ImageHardware:Arduino:gProtocolListStr"
	Button ArduinoStartButton,pos={125,611},size={100,28},proc=ARDSeqButtonProc,title="Start"
	Button ArduinoStartButton,fColor=(32768,65280,32768),disable=2
	Button ArduinoStopButton,pos={16,611},size={100,28},disable=2,proc=ARDSeqButtonProc,title="Stop"
	Button ArduinoStopButton,fColor=(65535,32768,32768)

	DefineGuide UGV0={FL,10}
	DefineGuide UGV1={FR,-10}
	DefineGuide UGH0={FT,260}
	DefineGuide UGH1={UGH0,160}
	Display/W=(10,208,231,378)/FG=(UGV0,UGH0,UGV1,UGH1)/HOST=#
	String fldrSav0= GetDataFolder(1)
	SetDataFolder root:ImageHardware:Arduino:

	AppendToGraph /L=wp2 wp2
	AppendToGraph /L=wp3 wp3
	AppendToGraph /L=wp4 wp4
	AppendToGraph /L=wp5 wp5
	AppendToGraph /L=wp6 wp6
	AppendToGraph /L=wp7 wp7
	AppendToGraph /L=wp8 wp8
	AppendToGraph /L=wp9 wp9
	AppendToGraph /L=wp10 wp10
	AppendToGraph /L=wp11 wp11
	AppendToGraph /L=wp12 wp12
	AppendToGraph /L=wp13 wp13
	SetDataFolder fldrSav0
	ModifyGraph minor(bottom)=1
	ModifyGraph axisEnab(bottom)={0.06,1}
	Label bottom "Time (ms)"
	ModifyGraph margin(left)=24,margin(bottom)=34,margin(top)=6,margin(right)=12

	ModifyGraph nticks(wp2)=1, noLabel(wp2)=1,lblPos(wp2)=16,freePos(wp2)=-3,axisEnab(wp2)={0.01,0.08},lblRot(wp2)=-90
	SetAxis wp2 0,1
	Label wp2 "2"

	ModifyGraph nticks(wp3)=1, noLabel(wp3)=1,lblPos(wp3)=16,freePos(wp3)=-3,axisEnab(wp3)={0.09,0.16},lblRot(wp3)=-90
	SetAxis wp3 0,1
	Label wp3 "3"

	ModifyGraph nticks(wp4)=1, noLabel(wp4)=1,lblPos(wp4)=16,freePos(wp4)=-3,axisEnab(wp4)={0.17,0.24},lblRot(wp4)=-90
	SetAxis wp4 0,1
	Label wp4 "4"

	ModifyGraph nticks(wp5)=1, noLabel(wp5)=1,lblPos(wp5)=16,freePos(wp5)=-3,axisEnab(wp5)={0.25,0.32},lblRot(wp5)=-90
	SetAxis wp5 0,1
	Label wp5 "5"

	ModifyGraph nticks(wp6)=1, noLabel(wp6)=1,lblPos(wp6)=16,freePos(wp6)=-3,axisEnab(wp6)={0.33,0.40},lblRot(wp6)=-90
	SetAxis wp6 0,1
	Label wp6 "6"

	ModifyGraph nticks(wp7)=1, noLabel(wp7)=1,lblPos(wp7)=16,freePos(wp7)=-3,axisEnab(wp7)={0.41,0.48},lblRot(wp7)=-90
	SetAxis wp7 0,1
	Label wp7 "7"

	ModifyGraph nticks(wp8)=1, noLabel(wp8)=1,lblPos(wp8)=16,freePos(wp8)=-3,axisEnab(wp8)={0.49,0.56},lblRot(wp8)=-90
	SetAxis wp8 0,1
	Label wp8 "8"

	ModifyGraph nticks(wp9)=1, noLabel(wp9)=1,lblPos(wp9)=16,freePos(wp9)=-3,axisEnab(wp9)={0.57,0.64},lblRot(wp9)=-90
	SetAxis wp9 0,1
	Label wp9 "9"

	ModifyGraph nticks(wp10)=1, noLabel(wp10)=1,lblPos(wp10)=21,freePos(wp10)=-3,axisEnab(wp10)={0.65,0.72},lblRot(wp10)=-90
	SetAxis wp10 0,1
	Label wp10 "10"

	ModifyGraph nticks(wp11)=1, noLabel(wp11)=1,lblPos(wp11)=21,freePos(wp11)=-3,axisEnab(wp11)={0.73,0.80},lblRot(wp11)=-90
	SetAxis wp11 0,1
	Label wp11 "11"

	ModifyGraph nticks(wp12)=1, noLabel(wp12)=1,lblPos(wp12)=21,freePos(wp12)=-3,axisEnab(wp12)={0.81,0.88},lblRot(wp12)=-90
	SetAxis wp12 0,1
	Label wp12 "12"

	ModifyGraph nticks(wp13)=1, noLabel(wp13)=1,lblPos(wp13)=21,freePos(wp13)=-3,axisEnab(wp13)={0.89,0.96},lblRot(wp13)=-90
	SetAxis wp13 0,1
	Label wp13 "13"

	RenameWindow #,G0
	SetActiveSubwindow ##
	ARDEpochPopMenuProc("EpochPopup",1,"A")

	ARDCalculateWavesPnts()
	// Try this to ensure that the send sequence is active if the arduino responds
	ARDWhichComPopMenuProc("WhichCOMPop",ards.gWhichCom,ards.gWhichComStr)

End

Function ARDWhichComPopMenuProc(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr

	STRUCT ArduinoSeqSettings ards
	ARDSetSeqSettings(ards)
	ards.gWhichComStr = popStr
	Variable ShowHide
	if (ARDInitialise(0) == 1)	// then we initialised succesfully
		// need to save this in the defaults wave
		ards.wSeqDefaults[3][0] = popNum		// 1 will be "none" so need to take this into account

		// now we should be able to send a sequence to the arduino so activate the button
		ShowHide = 0
	//	Button SendSequenceButton, disable = 0
	else
		ShowHide = 1
	//	Button SendSequenceButton, disable = 2
	endif
	ARDToggleButtons(ShowHide)	// this should be zero for active, 1 for hidden and 2 for disabled
	if(ShowHide)
		Button ArduinoStartButton, win=ArduinoSeq_Panel, disable=2
	endif
End

Function ARDToggleButtons(ShowHide)	// this should be zero for active, 1 for disabled
	Variable ShowHide
	Button SendSequenceButton, win=ArduinoSeq_Panel, disable = (ShowHide*2)
	Button ArduinoStartButton, disable = (!ShowHide*2)	// when one button is on, the other will be disabled
End

Function ARDEpochPopMenuProc(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr

	STRUCT ArduinoSeqSettings ards
	ARDSetSeqSettings(ards)
	Variable PopMode
	String PopString
	PopMode = ards.wSeqDefaults[0][popNum]
	PopupMenu EpochEvent,mode=PopMode,win=ArduinoSeq_Panel
	if (PopMode == 1)
		PopString = "Off"
		ARDEpochEventPopMenuProc("EpochEvent",PopMode,PopString)
	elseif (PopMode == 2)
		PopString = "DC"
		ARDEpochEventPopMenuProc("EpochEvent",PopMode,PopString)
	elseif (PopMode == 3)
		PopString = "Pulses"
		ARDEpochEventPopMenuProc("EpochEvent",PopMode,PopString)
	endif
	ARDRetrieveEpochValues(popNum)
End

Function ARDRetrieveEpochValues(WhichEpoch)
	Variable WhichEpoch
	STRUCT ArduinoSeqSettings ards
	ARDSetSeqSettings(ards)
	ards.gSeqRepeats =  ards.wSeqDefaults[0][0]
	ards.gSeqDuration =  ards.wSeqDefaults[1][0]
	ards.gSeqInterval =  ards.wSeqDefaults[2][0]
	ards.gWhichCom = ards.wSeqDefaults[3][0]
	ards.gEpochDuration = ards.wSeqDefaults[1][WhichEpoch]
	ards.gPulseDuration = ards.wSeqDefaults[2][WhichEpoch]
	ards.gPulseInterval = ards.wSeqDefaults[3][WhichEpoch]
	ards.gPulseNumber = ards.wSeqDefaults[4][WhichEpoch]
	ards.gDutyCycle = ards.wSeqDefaults[5][WhichEpoch]
	ards.gPortDBitValue = ards.wSeqDefaults[6][WhichEpoch]
	ards.gPortBBitValue = ards.wSeqDefaults[7][WhichEpoch]
	// These commands set the checkboxes for ports D and C
	ARDBitty("D", ards.gPortDBitValue)
	ARDBitty("B", ards.gPortBBitValue)

End

Function ARDStoreEpochValues()		// this needs to be called to save any updates to the sequenc wave
	STRUCT ArduinoSeqSettings ards
	ARDSetSeqSettings(ards)
	ARDCalculateMinimumTimes()
	ControlInfo /W=ArduinoSeq_Panel EpochPopup
	Variable WhichEpoch = V_Value
	ControlInfo /W=ArduinoSeq_Panel EpochEvent
	Variable WhichEvent = V_Value		// this will be whether we are looking at DC or Pulse events
	// only update if DC or pulses
	ards.wSeqDefaults[0][0] = ards.gSeqRepeats
	ards.wSeqDefaults[1][0] = ards.gSeqDuration
	ards.wSeqDefaults[2][0] = ards.gSeqInterval
	ards.wSeqDefaults[3][0] = ards.gWhichCom
	if (WhichEvent== 2)	// then this is DC so need to remember epoch duration
		ards.wSeqDefaults[0][WhichEpoch] = WhichEvent
		ards.wSeqDefaults[1][WhichEpoch] = ards.gEpochDuration
		ards.wSeqDefaults[6][WhichEpoch] = ards.gPortDBitValue
		ards.wSeqDefaults[7][WhichEpoch] = ards.gPortBBitValue
	elseif (WhichEvent== 3)	// then this is DC so need to remember epoch duration
		ards.wSeqDefaults[0][WhichEpoch] = WhichEvent
		ards.wSeqDefaults[1][WhichEpoch] = ards.gEpochDuration
		ards.wSeqDefaults[2][WhichEpoch] = ards.gPulseDuration
		ards.wSeqDefaults[3][WhichEpoch] = ards.gPulseInterval
		ards.wSeqDefaults[4][WhichEpoch] = ards.gPulseNumber
		ards.wSeqDefaults[5][WhichEpoch] = ards.gDutyCycle
		ards.wSeqDefaults[6][WhichEpoch] = ards.gPortDBitValue
		ards.wSeqDefaults[7][WhichEpoch] = ards.gPortBBitValue
		DoUpdate
	elseif (WhichEvent == 1)	// then this is off
		ards.wSeqDefaults[0][WhichEpoch] = WhichEvent
	endif
	ARDCalculateWavesPnts()
	// whenever this is called, we must have updated the wave pattern so we have to sent this to the arduino
	Variable ShowHide = 0	// enable so it can be sent
	ARDToggleButtons(ShowHide)
End

Function ARDCalculateMinimumTimes()
	STRUCT ArduinoSeqSettings ards
	ARDSetSeqSettings(ards)
	// Find out which Epoch we are currently on and fill up the default Sequence Wave with the current values
	ControlInfo /W=ArduinoSeq_Panel EpochPopup
	Variable WhichEpoch = V_Value
	ControlInfo /W=ArduinoSeq_Panel EpochEvent
	Variable WhichEvent = V_Value		// this will be whether we are looking at DC or Pulse events

	Variable MinimumDuration = (ards.gPulseInterval) * ards.gPulseNumber
	if (WhichEvent <=2)	// then we are looking at DC so no need to interfere

	else
		if (ards.gPulseDuration > ards.gPulseInterval)
			ards.gPulseInterval += 0.1
		else
		endif
		if (MinimumDuration > ards.gEpochDuration)
			ards.gEpochDuration = MinimumDuration
		else
		endif
	endif
	// put in a bit to calculate the minimum start to start interval. This will be the duration

End

Function ARDMinIntervalCheckProc(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	STRUCT ArduinoSeqSettings ards
	ARDSetSeqSettings(ards)

		if ((checked == 1) || (ards.gSeqInterval < ards.gSeqDuration))	// then either checked or the minimum start to start interval should be minimised
			ards.gSeqInterval = ards.gSeqDuration
		else

		endif
		ards.gEndToStartInterval = ards.gSeqInterval - ards.gSeqDuration
End

Function ARDEpochEventPopMenuProc(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr

	STRUCT ArduinoSeqSettings ards
	ARDSetSeqSettings(ards)
	String cdf = getdatafolder(1)
	SetDataFolder root:
	SetDataFolder ImageHardware
	SetDataFolder Arduino
	Variable DurationHide
	Variable PDurHide
	Variable PIntHide
	Variable PNumHide
	Variable DutyHide
	Variable CheckHide
	Variable WhichEpoch
	switch(popNum)	// numeric switch
		case 1:		// Off so hide all
			DurationHide = 1
			PDurHide = 1
			PIntHide = 1
 			PNumHide = 1
			DutyHide = 1
			CheckHide = 1
			ards.gEpochDuration = 0
			ards.gPulseDuration = 0
			ards.gPulseInterval = 0
			ards.gPulseNumber = 0

			// if this is now off, then we should make sure that the values in the wSeqDefaults are set to zero
			// Also need to update the length of the waves

			// Find out which epoch we are looking at
			ControlInfo /W=ArduinoSeq_Panel EpochPopup
			WhichEpoch = V_Value
			ards.wSeqDefaults[][WhichEpoch] = 0	// if DC, send all the data to zero
			ards.wSeqDefaults[0][WhichEpoch] = 1	// make the first row for this epoch 1 to show it is Off
			ARDCalculateWavesPnts()
			ARDToggleButtons(0)	// toggle buttons because this option changes the data in wSeqDefaults and so it needs to be refreshed
			break
		case 2:		// DC so deactivate all
			DurationHide = 0
			PDurHide = 1
			PIntHide = 1
 			PNumHide = 1
			DutyHide = 1
			CheckHide = 0
			break
		case 3:		// Pulse so reveal all
			DurationHide = 0
			PDurHide = 0
			PIntHide = 0
 			PNumHide = 0
			DutyHide = 1
			CheckHide = 0
			break

		default:
			break
	endswitch
	SetVariable EpochDurationSetVar, win=ArduinoSeq_Panel, disable = DurationHide
	SetVariable PulseDurationSetvar, win=ArduinoSeq_Panel, disable = PDurHide
	SetVariable PulseIntervalSetvar, win=ArduinoSeq_Panel, disable = PIntHide
	SetVariable PulseNumberSetvar, win=ArduinoSeq_Panel, disable = PNumHide
	SetVariable DutyCycleSetvar, win=ArduinoSeq_Panel, disable = DutyHide
	Variable Counter
	String CheckNameStr = ""
	String PinLabelStr = ""
	For (Counter = 2; Counter <=13; Counter +=1)
		sprintf CheckNameStr, "EpochCheck%g", Counter
		CheckBox $CheckNameStr, win=ArduinoSeq_Panel, disable = CheckHide
		sprintf PinLabelStr, "Pin%g", Counter
		TitleBox $PinLabelStr, win=ArduinoSeq_Panel, disable = CheckHide
	EndFor
	// Hide all of the check boxes as well
End

Function ARDStorePinValuesSetVarProc(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName

	if (stringmatch(ctrlName, "SeqIntervalSetVar") == 1)	// then we need to uncheck auto
		CheckBox MinSeqIntervalCheck value = 0
	else

	endif

	ARDStoreEpochValues()	// ensure that updates are saved to the wave file
	ARDCalculateWavesPnts()
End

Function ARDPortDBitCheckProc(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	STRUCT ArduinoSeqSettings ards
	ARDSetSeqSettings(ards)
	Variable Counter
	String WhichCheck
	ards.gPortDBitValue = 0
	For (Counter = 8; Counter <= 13; Counter += 1)
		sprintf WhichCheck, "EpochCheck%g", Counter
		ControlInfo /W=ArduinoSeq_Panel $WhichCheck
		if (V_Value == 1)	// then the control is checked
			ards.gPortDBitValue += 2^(Counter-8)
		else
		endif

	EndFor
	ARDStoreEpochValues()
End

Function ARDPortBBitCheckProc(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	STRUCT ArduinoSeqSettings ards
	ARDSetSeqSettings(ards)
	Variable Counter
	String WhichCheck
	ards.gPortBBitValue = 0
	For (Counter = 2; Counter <= 7; Counter += 1)
		sprintf WhichCheck, "EpochCheck%g", Counter
		ControlInfo /W=ArduinoSeq_Panel $WhichCheck
		if (V_Value == 1)	// then the control is checked
			ards.gPortBBitValue += 2^(Counter-2)
		else
		endif

	EndFor
	ARDStoreEpochValues()
End

Function ARDSeqButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch(ba.eventCode)
		case 2: // mouse up
			strswitch(ba.ctrlName)
				case "LoadSeqButton":
					ARDLoadSeqWave()
					break
				case "SaveSeqButton":
					ARDSaveCurrentSeqWave()
					break
				case "ArduinoStartButton":
					ARDStartSequence()
					break
				case "ArduinoStopButton":
					ARDEndSequence()
					break
				case "SendSequenceButton":
					if(ARDSendEpochs() >= 0) // then no errors
						ARDToggleButtons(1)
					else
						ARDToggleButtons(0)
					endif
					break
			endswitch
			break
	endswitch

	return 0
End

Function ARDLoadProtocolPopMenuProc(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	String AlertString
	Sprintf AlertString, "Do you want to save changes to the current protocol file first?"
	DoAlert 2, AlertString
	if (V_Flag == 1)		// yes clicked so save changes before loading new file
		ARDSaveCurrentSeqWave()
		ARDLoadNamedProtocol(popStr)
		ARDEpochPopMenuProc("EpochPopup",1,"A")
		ARDCalculateWavesPnts()
		ARDToggleButtons(0)	// this will show send sequence button and hide start button
	elseif (V_Flag == 2)	// no clicked so just load new file
		ARDLoadNamedProtocol(popStr)
		ARDEpochPopMenuProc("EpochPopup",1,"A")
		ARDCalculateWavesPnts()
		ARDToggleButtons(0)
	elseif (V_Flag == 3)	// Cancel clicked so gracefully leave
		Return 0
	endif
End

Function ARDLoadNamedProtocol(FileNameStr)
	String FileNameStr
	String cdf = getdatafolder(1)
	SetDataFolder root:
	if (!(Datafolderexists ("ImageHardware")))
		NewDataFolder ImageHardware
	endif
	SetDataFolder ImageHardware
	if (!(DataFolderExists ("Arduino")))
		NewDataFolder Arduino
	endif
	SetDataFolder Arduino

	String ArdSeqPathStr = ParseFilePath(1, FunctionPath(""), ":", 1, 0) + "Sequence Files:"
	NewPath/O/Q ArdSeqPath, ArdSeqPathStr

	Loadwave/H/O/P=ArdSeqPath FileNameStr

	SetDataFolder $cdf

End

Function ARDBitty(WhichPort, BitValue)	// function that will tell if various bits are set or not and set check boxes accordingly
	String WhichPort
	Variable BitValue
	Variable StartPoint
	Variable/G Bit0, Bit1, Bit2, Bit3, Bit4, Bit5

	String WhichCheck, WhichBit
	if (Stringmatch(WhichPort,"D") == 1)
		StartPoint = 8
	else
		StartPoint = 2
	endif
	Variable/G  tmpBitValue
	BitValue = trunc(BitValue)				// Makes sense with integers only
	if ((BitValue & 2^0) != 0)		// Test if bit 0 is set
		Bit0 = 1
	else
		Bit0 = 0
	endif
	if ((BitValue & 2^1) != 0)		// Test if bit 1 is set
		Bit1 = 1
	else
		Bit1 = 0
	endif
	if ((BitValue & 2^2) != 0)		// Test if bit 2 is set
		Bit2 = 1
	else
		Bit2 = 0
	endif
	if ((BitValue & 2^3) != 0)		// Test if bit 3 is set
		Bit3 = 1
	else
		Bit3 = 0
	endif
	if ((BitValue & 2^4) != 0)		// Test if bit 4 is set
		Bit4 = 1
	else
		Bit4 = 0
	endif
	if ((BitValue & 2^5) != 0)		// Test if bit 4 is set
		Bit5 = 1
	else
		Bit5 = 0
	endif
	Variable Counter, BitNum
	BitNum = 0
	For (Counter = StartPoint; Counter <= (StartPoint + 5); Counter +=1)
		sprintf WhichCheck, "EpochCheck%g", Counter
		sprintf WhichBit, "Bit%g", BitNum
		NVAR tmpBitValue = $WhichBit
		Checkbox $WhichCheck, win=ArduinoSeq_Panel, value = tmpBitValue
		BitNum +=1
	EndFor
	Killvariables/Z tmpBitValue, Bit0, Bit1, Bit2, Bit3, Bit4, Bit5
End

Function ARDCalculateWavesPnts()
	STRUCT ArduinoSeqSettings ards
	ARDSetSeqSettings(ards)
	// Need to go through each epoch and determine how many points are required.
	Variable Counter
	Variable NumPoints = 0
	Variable SampleRate = 10
	Variable Bit0, Bit1, Bit2, Bit3, Bit4, Bit5
	Variable i
	Variable StartPnts, EndPnts, PulseStartToStart
	Variable EndOfPulsePnt
	Variable PulseDuration, PulseInterval, PulseNumber
	String GateOnStr = ""
	String GateOffStr = ""
	String PulseOnStr = ""

	String destWaveList = ""
	String/G Pin2wList, Pin3wList, Pin4wList, Pin5wList, Pin6wList, Pin7wList
	String/G Pin8wList, Pin9wList, Pin10wList, Pin11wList, Pin12wList, Pin13wList
	Pin2wList = ""
	Pin3wList = ""
	Pin4wList = ""
	Pin5wList = ""
	Pin6wList = ""
	Pin7wList = ""
	Pin8wList = ""
	Pin9wList = ""
	Pin10wList = ""
	Pin11wList = ""
	Pin12wList = ""
	Pin13wList = ""
	Variable PortDBitValue
	Variable PortBBitValue
		For (Counter = 1; Counter <=10; Counter +=1)		// goes through each epoch at a time
			PortDBitValue = ards.wSeqDefaults[6][Counter]	// get the bit values for ports D and C
			PortBBitValue = ards.wSeqDefaults[7][Counter]

			if (ards.wSeqDefaults[0][Counter] > 1)	// then it must be DC or pulses so make some points
				NumPoints = (SampleRate * ards.wSeqDefaults[1][Counter])	// this is the duration x sample rate
				sprintf GateOnStr, "Epoch%gGateOn", Counter
				sprintf GateOffStr, "Epoch%gGateOff", Counter
				sprintf PulseOnStr, "Epoch%gPulseOn", Counter

				make/O/N=(NumPoints) $GateOnStr, $GateOffStr, $PulseOnStr
				Wave wGateOn = $GateOnStr
				Wave wGateOff = $GateOffStr
				Wave wPulseOn = $PulseOnStr
				wGateOn = 1
				wGateOff = 0
				wPulseOn = 0

				if (ards.wSeqDefaults[0][Counter] == 2)	// then this is DC
				elseif (ards.wSeqDefaults[0][Counter] == 3)	// then this is Pulses so set up some code to make suitable waves
					PulseDuration = ards.wSeqDefaults[2][Counter]	// get the bit values for ports D and C
					PulseInterval = ards.wSeqDefaults[3][Counter]
					PulseNumber = ards.wSeqDefaults[4][Counter]

					EndPnts = PulseDuration*10
					PulseStartToStart =  (PulseInterval*10)	// make the interval independent of pulse duration
					EndOfPulsePnt = PulseStartToStart *PulseNumber
					StartPnts = 0
					For (i=0; i<EndOfPulsePnt; i+=PulseStartToStart )
						wPulseOn[i+StartPnts,i+EndPnts]=1
					EndFor

				else
				endif

				// now find out if the bits for port C are set or not
				if ((PortBBitValue & 2^0) != 0)		// Test if bit 0 is set
					if (ards.wSeqDefaults[0][Counter] == 2)
						sprintf Pin2wList, "%s%s;", Pin2wList, GateOnStr
					else
						sprintf Pin2wList, "%s%s;", Pin2wList, PulseOnStr
					endif

				else
					sprintf Pin2wList, "%s%s;", Pin2wList, GateOffStr
				endif

				if ((PortBBitValue & 2^1) != 0)		// Test if bit 1 is set
					if (ards.wSeqDefaults[0][Counter] == 2)
						sprintf Pin3wList, "%s%s;", Pin3wList, GateOnStr
					else
						sprintf Pin3wList, "%s%s;", Pin3wList, PulseOnStr
					endif

				else
					sprintf Pin3wList, "%s%s;", Pin3wList, GateOffStr
				endif

				if ((PortBBitValue & 2^2) != 0)		// Test if bit 2 is set
					if (ards.wSeqDefaults[0][Counter] == 2)
						sprintf Pin4wList, "%s%s;", Pin4wList, GateOnStr
					else
						sprintf Pin4wList, "%s%s;", Pin4wList, PulseOnStr
					endif

				else
					sprintf Pin4wList, "%s%s;", Pin4wList, GateOffStr
				endif

				if ((PortBBitValue & 2^3) != 0)		// Test if bit 3 is set
					if (ards.wSeqDefaults[0][Counter] == 2)
						sprintf Pin5wList, "%s%s;", Pin5wList, GateOnStr
					else
						sprintf Pin5wList, "%s%s;", Pin5wList, PulseOnStr
					endif

				else
					sprintf Pin5wList, "%s%s;", Pin5wList, GateOffStr
				endif

				if ((PortBBitValue & 2^4) != 0)		// Test if bit 4 is set
					if (ards.wSeqDefaults[0][Counter] == 2)
						sprintf Pin6wList, "%s%s;", Pin6wList, GateOnStr
					else
						sprintf Pin6wList, "%s%s;", Pin6wList, PulseOnStr
					endif

				else
					sprintf Pin6wList, "%s%s;", Pin6wList, GateOffStr
				endif

				if ((PortBBitValue & 2^5) != 0)		// Test if bit 4 is set
					if (ards.wSeqDefaults[0][Counter] == 2)
						sprintf Pin7wList, "%s%s;", Pin7wList, GateOnStr
					else
						sprintf Pin7wList, "%s%s;", Pin7wList, PulseOnStr
					endif

				else
					sprintf Pin7wList, "%s%s;", Pin7wList, GateOffStr
				endif

				// now find out if the bits for port D are set or not
				if ((PortDBitValue & 2^0) != 0)		// Test if bit 0 is set
					if (ards.wSeqDefaults[0][Counter] == 2)
						sprintf Pin8wList, "%s%s;", Pin8wList, GateOnStr
					else
						sprintf Pin8wList, "%s%s;", Pin8wList, PulseOnStr
					endif

				else
					sprintf Pin8wList, "%s%s;", Pin8wList, GateOffStr
				endif

				if ((PortDBitValue & 2^1) != 0)		// Test if bit 1 is set
					if (ards.wSeqDefaults[0][Counter] == 2)
						sprintf Pin9wList, "%s%s;", Pin9wList, GateOnStr
					else
						sprintf Pin9wList, "%s%s;", Pin9wList, PulseOnStr
					endif

				else
					sprintf Pin9wList, "%s%s;", Pin9wList, GateOffStr
				endif

				if ((PortDBitValue & 2^2) != 0)		// Test if bit 2 is set
					if (ards.wSeqDefaults[0][Counter] == 2)
						sprintf Pin10wList, "%s%s;", Pin10wList, GateOnStr
					else
						sprintf Pin10wList, "%s%s;", Pin10wList, PulseOnStr
					endif

				else
					sprintf Pin10wList, "%s%s;", Pin10wList, GateOffStr
				endif

				if ((PortDBitValue & 2^3) != 0)		// Test if bit 3 is set
					if (ards.wSeqDefaults[0][Counter] == 2)
						sprintf Pin11wList, "%s%s;", Pin11wList, GateOnStr
					else
						sprintf Pin11wList, "%s%s;", Pin11wList, PulseOnStr
					endif

				else
					sprintf Pin11wList, "%s%s;", Pin11wList, GateOffStr
				endif

				if ((PortDBitValue & 2^4) != 0)		// Test if bit 4 is set
					if (ards.wSeqDefaults[0][Counter] == 2)
						sprintf Pin12wList, "%s%s;", Pin12wList, GateOnStr
					else
						sprintf Pin12wList, "%s%s;", Pin12wList, PulseOnStr
					endif

				else
					sprintf Pin12wList, "%s%s;", Pin12wList, GateOffStr
				endif

				if ((PortDBitValue & 2^5) != 0)		// Test if bit 4 is set
					if (ards.wSeqDefaults[0][Counter] == 2)
						sprintf Pin13wList, "%s%s;", Pin13wList, GateOnStr
					else
						sprintf Pin13wList, "%s%s;", Pin13wList, PulseOnStr
					endif

				else
					sprintf Pin13wList, "%s%s;", Pin13wList, GateOffStr
				endif

			else
			endif

		EndFor

		string WhichPin = ""
		string tmpList
		string/G WhichList = ""

		For (Counter = 2; Counter <=13; Counter +=1)
			sprintf WhichPin, "wp%g", Counter
			sprintf tmpList, "Pin%gwList", Counter
			SVAR WhichList = $tmpList
			Concatenate/O/NP=0 WhichList, $WhichPin
			if (dimsize($WhichPin,0) > 0)
				SetScale/P x 0,0.1,"", $WhichPin
			else
			endif
		EndFor

		// use oen of the waves to get the final sequence duration
		ards.gSeqDuration = (dimsize(wP2,0)/10000)	// this will convert to seconds

		ControlInfo /W=ArduinoSeq_Panel MinSeqIntervalCheck
		if ((V_Value == 1) || (ards.gSeqInterval < ards.gSeqDuration))	// then either checked or the minimum start to start interval should be minimised
			ards.gSeqInterval = ards.gSeqDuration
		else

		endif
		ards.gEndToStartInterval = ards.gSeqInterval - ards.gSeqDuration
End

// Try a different approach whereby all data is sent regardless.
// Now the arduino stores the type of pulse and will use that to decide what to do
Function ARDSendEpochs()
	STRUCT ArduinoSeqSettings ards
	ARDSetSeqSettings(ards)
	Variable WhichEpoch

	String ArduinoStr = ""
	Variable Command
	String OutStr= ""
	// Need to have a function to send these parameters to the arduino as well

	if (ARDSendRepSeq() != 1)
		sprintf  ards.gMessageStr, "Failed to send Sequence Data"
		Return 0
	else
		sprintf  ards.gMessageStr, "Sequence Data Sent"
	endif

	Variable CurrentTicks
	Variable TargetTicks
	Variable Outcome
	if (ARDResetEpochs() == 0)	// then we have succesfully reset all epochs
		For (WhichEpoch = 1; WhichEpoch <= 10; WhichEpoch +=1)
			Outcome = ARDSendEpoch(WhichEpoch)
			if (Outcome == 1)	// success
				sprintf  ards.gMessageStr, "Data for epoch %s sent", num2char(WhichEpoch+64)
			elseif (Outcome == -1)	// then the arduino has failed to receive an epoch
				 sprintf  ards.gMessageStr, "Data for epoch %s was not received", num2char(WhichEpoch+64)
			else		// then the epoch is off and so not required to be sent

			endif
			CurrentTicks = ticks
			TargetTicks = CurrentTicks + 5
			Do		// add a bit of a delay to make sure the information is sent
				CurrentTicks = ticks
			While(CurrentTicks < TargetTicks)
		EndFor
	else
	endif
	Return Outcome
End

Function ARDSendRepSeq()
	STRUCT ArduinoSeqSettings ards
	ARDSetSeqSettings(ards)

	Variable SeqRepeats
	Variable SeqInterval
	Variable SeqDuration
	String ArduinoStr = "Waiting ... "
	Variable Command
	String OutStr= ""
	SeqRepeats =  ards.wSeqDefaults[0][0]
	SeqDuration =  ards.wSeqDefaults[1][0]
	SeqInterval =  ards.wSeqDefaults[2][0]
	Command = 12
	sprintf OutStr, "%d, %d, %d, %d;", Command, SeqRepeats, (SeqDuration*1000), (SeqInterval*1000)	// deal with ms not second to avoid float problems
	Variable CurrentTicks
	Variable TargetTicks
	Variable Attempts
	Variable Success = 0
	VDT2 killio
	Do
		VDTWrite2 /O=0.1 OutStr
		VDTRead2 /N=255 /O=0.1 /Q /T=";"ArduinoStr
		ards.gVDT2Message = ArduinoStr
		if (stringmatch(ArduinoStr,"*12,Reps Cmd Received*") == 1)
			Attempts = 10
			Success = 1
		else
			Attempts +=1
		endif
		CurrentTicks = ticks
		TargetTicks = CurrentTicks + 10
		Do		// add a bit of a delay to make sure the information is sent
			CurrentTicks = ticks
		While(CurrentTicks < TargetTicks)

	While(Attempts < 10)
	if (Success == 1)
		sprintf  ards.gMessageStr, "Sequence Data Sent"
		Return 1	// this is good and succesful
	else
		sprintf  ards.gMessageStr, "Failed to send Sequence Data"
		Return -1
	endif
End

Function ARDSendEpoch(WhichEpoch)
	Variable WhichEpoch
	// Get information from wSeqDefaults
	STRUCT ArduinoSeqSettings ards
	ARDSetSeqSettings(ards)

	Variable Event = ards.wSeqDefaults[0][WhichEpoch]
	Variable EpochDuration = ards.wSeqDefaults[1][WhichEpoch]
	Variable PulseDuration = ards.wSeqDefaults[2][WhichEpoch]
	Variable PulseInterval = ards.wSeqDefaults[3][WhichEpoch]
	Variable PulseNumber = ards.wSeqDefaults[4][WhichEpoch]
	Variable DutyCycle = ards.wSeqDefaults[5][WhichEpoch]
	Variable PortDBitValue = ards.wSeqDefaults[6][WhichEpoch]
	Variable PortBBitValue = ards.wSeqDefaults[7][WhichEpoch]

	String ArduinoStr = "Waiting ... "
	Variable Command
	String OutStr= ""

	Command = 13
	sprintf OutStr, "%d, %d, %d, %d,%d,%d,%d,%d,%d;", Command, WhichEpoch, Event, EpochDuration, PulseDuration, PulseInterval, PulseNumber,PortDBitValue, PortBBitValue

	Variable Attempts

	if (Event >1)	// then it is not off so it should be sent to the arduino
		Variable Success = 0
		Do
			VDT2 killio
			VDTWrite2 /O=0.1 OutStr
			VDTRead2 /N=255 /O=0.1 /Q /T=";"ArduinoStr
			ards.gVDT2Message = ArduinoStr
			if (stringmatch(ArduinoStr,"*13,Epoch Data Received*") == 1)
				Attempts = 20
				Success = 1
			else
				Attempts +=1
			endif
		While(Attempts < 20)

		if (Success !=1)
			sprintf  ards.gMessageStr, "Failed to set epoch %s after %g attempts\r", num2char(WhichEpoch+64), Attempts
			Return -1
		else
		endif
		Return 1	// this is good and succesful
	else
		Return 0	// this means that this epoch was not sent to the arduino because it is off
	endif

End

// This calls fuction 5 and resets all of the values held in the arduino to zero
Function ARDResetEpochs()
	Variable Command
	STRUCT ArduinoSeqSettings ards
	ARDSetSeqSettings(ards)
	String ArduinoStr = "Waiting ... "
	String OutStr= ""
	sprintf OutStr, "11,0;"
	if (ARDInitialise(1) == 1)	// then initialised succesfully
		VDT2 killio
		VDTWrite2 /O=0.1 OutStr
		VDTRead2 /N=255 /O=0.1 /Q /T=";"ArduinoStr
		ards.gVDT2Message = ArduinoStr
		if (stringmatch(ArduinoStr,"*11,Epochs Reset*") == 1)
			sprintf  ards.gMessageStr, "Arduino Epochs Reset"
			Return 0
		else
			sprintf  ards.gMessageStr, "Failed to reset Epochs"
			Return -1
		endif
	else
	endif
End

// This will ask for a ready response from the arduino
Function ARDInitialise(Quiet)
	Variable Quiet
	String ArduinoStr = "Not Intialised"
	Variable Counter
	STRUCT ArduinoSeqSettings ards
	ARDSetSeqSettings(ards)

	if(strlen(ards.gWhichComStr) > 0 && CmpStr(ards.gWhichComStr,"None") != 0)
		VDTOperationsPort2 $ards.gWhichComStr
		VDT2 baud=115200
		VDT2 killio
		For (Counter = 0; Counter < 5; Counter +=1)
			VDTWrite2 /O=0.1 "2;"	// a value of 2 should elicit a response of 1,Arduino ready;
			VDTRead2 /N=255 /O=0.1 /Q /T=";"ArduinoStr
			ards.gVDT2Message = ArduinoStr
			if (stringmatch(ArduinoStr,"*1,Arduino ready*") == 1)
				sprintf  ards.gMessageStr, "Arduino Initialised on attempt %g", Counter
				if (Quiet != 1)	// then print the message
					printf "Arduino Initialised on attempt %g\r", Counter
				else
				endif
				Return 1
			else
			endif
		EndFor
	endif

	sprintf ards.gMessageStr, "Arduino failed to respond"
	Return -1
End

Function ARDCloseCOMPort()
	STRUCT ArduinoSeqSettings ards
	ARDSetSeqSettings(ards)
	VDTClosePort2 $ards.gWhichCOMStr
End

Function ARDStartSequence()
	STRUCT ArduinoSeqSettings ards
	ARDSetSeqSettings(ards)

	String ArduinoStr = "Waiting ... "
	Variable Command
	String OutStr= ""

	Command = 14
	sprintf OutStr, "%d;", Command
	Variable Attempts
	Variable Success = 0
	Do
		VDT2 killio
		VDTWrite2 /O=0.1 OutStr
		VDTRead2 /N=255 /O=0.1 /Q /T=";"ArduinoStr
		ards.gVDT2Message = ArduinoStr
		if (stringmatch(ArduinoStr,"*14,Sequence Started*") == 1)
			sprintf  ards.gMessageStr, "Start signal sent after %g attempts",  Attempts
			Attempts = 10
			Success = 1
		else
			Attempts +=1
		endif
	While(Attempts < 10)

	if (Success !=1)
		sprintf  ards.gMessageStr, "Failed to send start signal after %g attempts",  Attempts
		Return -1
	else

	endif
	Return 1	// this is good and succesful

End

Function ARDEndSequence()

End

//Function SelectCOMPort()
//	if (exists("root:ImageHardware:Arduino:gWhichCom") == 2)	// then it exists
//
//	else
//		ARDLaunch
//		SeqPanel()
//
//	endif
//
//	STRUCT ArduinoSeqSettings ards
//	ARDSetSeqSettings(ards)
//	DoWindow/K COMSelectionPanel
//	NewPanel /W=(600,150,890,350)
//	DoWindow/C/T  COMSelectionPanel  "COM Selection Panel"
//
//	TitleBox COTitle,pos={58,21},size={171,32},title="\\JCChoose which COM port\r your arduino is connected to"
//	TitleBox COTitle,fSize=12,frame=0
//
//	VDTGetPortList2	// this now puts the list into S_VDT
//
//	string PopStr = "\"None"
//	Variable Counter
//	String tmpStr
//	PopStr = "\"None"
//	Variable NumItems = ItemsInList(S_VDT)
//	if (NumItems !=0)
//		For (Counter = 0; Counter < NumItems; Counter +=1)
//			tmpStr = stringfromList(Counter, S_VDT)
//			PopStr = PopStr + ";" + tmpStr
//		EndFor
//	else
//		PopStr = PopStr + ";"
//	endif
//	PopStr += "\""
//
//	PopupMenu COMSelectorPop,pos={40,77},size={204,20},bodyWidth=160,title="COM Port"
//	PopupMenu COMSelectorPop,mode=(ards.gWhichCom+1),value= #PopStr,proc=WhichComPopMenuProc
//
//	Button COMCancelButton,pos={55,148},size={60,20},proc=COMSelectButtonProc,title="Cancel"
//	Button COMAcceptButton,pos={165,148},size={60,20},proc=COMSelectButtonProc,title="OK"
//
//
//End
//
//Function COMSelectButtonProc(ctrlName) : ButtonControl
//	String ctrlName
//	STRUCT ArduinoSeqSettings ards
//	ARDSetSeqSettings(ards)
//	if (Stringmatch(ctrlName, "COMCancelButton") == 1)
//		DoWindow/K COMSelectionPanel
//
//	else
//		ControlInfo /W=COMSelectionPanel COMSelectorPop
//		ards.gWhichComStr = S_Value
//		ards.gWhichCom = V_Value - 1	// this is because the "none" will always be the first in the pop list
//		ards.wSeqDefaults[3][0] = ards.gWhichCom
//		DoWindow/K COMSelectionPanel
//	endif
//
//End
//
//
//Function WhichComPopMenuProc(ctrlName,popNum,popStr) : PopupMenuControl
//	String ctrlName
//	Variable popNum
//	String popStr
//
//End

#else

Function ARDLaunchSeqPanel()

	DEBUGPRINT("Unimplemented")
End

Function ARDStartSequence()

	DEBUGPRINT("Unimplemented")
End

#endif
