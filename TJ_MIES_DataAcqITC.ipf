#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Function ITCDataAcq(DeviceType, DeviceNum, panelTitle)
	variable DeviceType, DeviceNum
	string panelTitle
	string cmd
	variable i=0
	variable StopCollectionPoint = CalculateITCDataWaveLength(panelTitle)/4
	variable ADChannelToMonitor=(NoOfChannelsSelected("DA", "Check", panelTitle))
	string WavePath = HSU_DataFullFolderPathString(PanelTitle)
	wave ITCDataWave = $WavePath + ":ITCDataWave", ITCFIFOAvailAllConfigWave= $WavePath + ":ITCFIFOAvailAllConfigWave"//, ChannelConfigWave, UpdateFIFOWave, RecordedWave
	string ITCDataWavePath = WavePath + ":ITCDataWave", ITCFIFOAvailAllConfigWavePath= WavePath + ":ITCFIFOAvailAllConfigWave"
	string ITCChanConfigWavePath = WavePath + ":ITCChanConfigWave"
	string ITCFIFOPositionAllConfigWavePth = WavePath + ":ITCFIFOPositionAllConfigWave"
	string oscilloscopeSubwindow=panelTitle+"#oscilloscope"
	string ResultsWavePath = WavePath + ":ResultsWave"
	make /O /I /N = 4 $ResultsWavePath 
	doupdate
	// open ITC device
	sprintf cmd, "ITCOpenDevice %d, %d", DeviceType, DeviceNum
	Execute cmd	
	sprintf cmd, "ITCconfigAllchannels, %s, %s" ITCChanConfigWavePath, ITCDataWavePath
	execute cmd
	do

		sprintf cmd, "ITCUpdateFIFOPositionAll , %s" ITCFIFOPositionAllConfigWavePth // I have found it necessary to reset the fifo here, using the /r=1 with start acq doesn't seem to work
		execute cmd// this also seems necessary to update the DA channel data to the board!!
		sprintf cmd, "ITCStartAcq"// /f/r=0/z=0 -1,0,1,1"//   
		Execute cmd	
			do
				sprintf cmd, "ITCFIFOAvailableALL/z=0 , %s" ITCFIFOAvailAllConfigWavePath
				Execute cmd	
				ITCDataWave[0][0]+=0
				doupdate/w=$oscilloscopeSubwindow
				//doxopidle
			while (ITCFIFOAvailAllConfigWave[ADChannelToMonitor][2] < StopCollectionPoint)// 
		//Check Status
		sprintf cmd, "ITCGetState /R /O /C /E %s" ResultsWavePath
		Execute cmd
		sprintf cmd, "ITCStopAcq/z=0"
		Execute cmd
		itcdatawave[0][0]+=0//runs arithmatic on data wave to force onscreen update 
		doupdate
		sprintf cmd, "ITCConfigChannelUpload/f/z=0"//AS Long as this command is within the do-while loop the number of cycles can be repeated		
		Execute cmd
		i+=1
	while (i<1)// 
	sprintf cmd, "ITCCloseAll" 
	execute cmd

	ControlInfo/w=$panelTitle Check_Settings_SaveData
	If(v_value==0)
	SaveITCData(panelTitle)
	endif
	
	 ScaleITCDataWave(panelTitle)
END

//======================================================================================
Function ITCBkrdAcq(DeviceType, DeviceNum, panelTitle)
	variable DeviceType, DeviceNum
	string panelTitle
	string cmd
	variable i=0
	variable/G StopCollectionPoint = (CalculateITCDataWaveLength(panelTitle)/4)
	variable/G ADChannelToMonitor=(NoOfChannelsSelected("DA", "Check", panelTitle))
	string/G panelTitleG = panelTitle
	doupdate
	string WavePath = HSU_DataFullFolderPathString(PanelTitle)
	wave ITCDataWave = $WavePath+ ":ITCDataWave"
	wave ITCFIFOAvailAllConfigWave =  $WavePath + ":ITCFIFOAvailAllConfigWave"//, ChannelConfigWave, UpdateFIFOWave, RecordedWave
	
	string ITCDataWavePath = WavePath + ":ITCDataWave", ITCFIFOAvailAllConfigWavePath= WavePath + ":ITCFIFOAvailAllConfigWave"
	string ITCChanConfigWavePath = WavePath + ":ITCChanConfigWave"
	string ITCFIFOPositionAllConfigWavePth = WavePath + ":ITCFIFOPositionAllConfigWave"
	// open ITC device
	
	sprintf cmd, "ITCOpenDevice %d, %d", DeviceType, DeviceNum
		Execute cmd	
	sprintf cmd, "ITCconfigAllchannels, %s, %s" ITCChanConfigWavePath, ITCDataWavePath
		execute cmd
	sprintf cmd, "ITCUpdateFIFOPositionAll , %s" ITCFIFOPositionAllConfigWavePth// I have found it necessary to reset the fifo here, using the /r=1 with start acq doesn't seem to work
		execute cmd// this also seems necessary to update the DA channel data to the board!!
	sprintf cmd, "ITCStartAcq" 
		Execute cmd	
	
	StartBackgroundFIFOMonitor()
	
	End
//======================================================================================
Function StopDataAcq()
	variable DeviceType, DeviceNum
	string cmd
	NVAR StopCollectionPoint, ADChannelToMonitor
	SVAR panelTitleG
	string WavePath = HSU_DataFullFolderPathString(PanelTitleG)
	wave ITCDataWave = $WavePath + ":ITCDataWave"
	string CountPath=WavePath+"count"

	sprintf cmd, "ITCStopAcq/z=0"
	Execute cmd

	itcdatawave[0][0]+=0//runs arithmatic on data wave to force onscreen update 
	doupdate
	
	sprintf cmd, "ITCConfigChannelUpload/f/z=0"//AS Long as this command is within the do-while loop the number of cycles can be repeated		
	Execute cmd	
	
	sprintf cmd, "ITCCloseAll" 
	execute cmd
	
	
	ControlInfo/w=$panelTitleG Check_Settings_SaveData
	If(v_value==0)
	SaveITCData(panelTitleG)// saving always comes before scaling - there are two independent scaling steps
	endif
	
	 ScaleITCDataWave(panelTitleG)
	
	if(exists(CountPath)==0)//If the global variable count does not exist, it is the first trial of repeated acquisition
	controlinfo/w=$panelTitleG Check_DataAcq1_RepeatAcq
		if(v_value==1)//repeated aquisition is selected
			RepeatedAcquisition(PanelTitleG)
		endif
	else
		BckgTPwithCallToRptAcqContr(panelTitleG)//FUNCTION THAT ACTIVATES BCKGRD TP AND THEN CALLS REPEATED ACQ XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
	endif
	
	killvariables/z StopCollectionPoint, ADChannelToMonitor
	killstrings/z PanelTitleG
END
//======================================================================================
Function ZeroTheInstrutechDevice()
string cmd
sprintf cmd, "ITCSetDac/z=0 0, 0;ITCSetDac/z=0 1, 0;ITCSetDac/z=0 2, 0;ITCSetDac/z=0 3, 0;ITCSetDac/z=0 4, 0;ITCSetDac/z=0 5, 0;ITCSetDac/z=0 6, 0;ITCSetDac/z=0 7, 0"
execute cmd
END
//======================================================================================
Function StartBackgroundFIFOMonitor()
	CtrlNamedBackground FIFOMonitor, period=2, proc=FIFOMonitor
	CtrlNamedBackground FIFOMonitor, start
End

Function FIFOMonitor(s)
	STRUCT WMBackgroundStruct &s
	NVAR StopCollectionPoint, ADChannelToMonitor
	SVAR panelTitleG
	String cmd
	string WavePath = HSU_DataFullFolderPathString(PanelTitleG)
	wave ITCDataWave = $WavePath + ":ITCDataWave", ITCFIFOAvailAllConfigWave= $WavePath + ":ITCFIFOAvailAllConfigWave"
	string ITCFIFOAvailAllConfigWavePath = WavePath + ":ITCFIFOAvailAllConfigWave"
	sprintf cmd, "ITCFIFOAvailableALL/z=0 , %s" ITCFIFOAvailAllConfigWavePath
	Execute cmd	
	ITCDataWave[0][0]+=0//forces on screen update
	string OscilloscopeSubWindow=panelTitleG+"#oscilloscope"
	doupdate/w=$OscilloscopeSubWindow
	if(ITCFIFOAvailAllConfigWave[ADChannelToMonitor][2] >= StopCollectionPoint)	
		StopDataAcq()
		STOPFifoMonitor()
	endif
				
	return 0
End

Function STOPFifoMonitor()
CtrlNamedBackground FIFOMonitor, stop
End
//======================================================================================

#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Function StartBackgroundTimer(RunTimePassed,FunctionNameAPassedIn, FunctionNameBPassedIn,  FunctionNameCPassedIn, panelTitle)//Function name is the name of the function you want to run after run time has elapsed
	Variable RunTimePassed//how long you want the background timer to run in seconds
	String FunctionNameAPassedIn, FunctionNameBPassedIn, FunctionNameCPassedIn, panelTitle
	String/G FunctionNameA=FunctionNameAPassedIn
	String/G FunctionNameB=FunctionNameBPassedIn
	String/G FunctionNameC=FunctionNameCPassedIn
	String/G PanelTitleG = panelTitle
	Variable numTicks = 15		// Run every quarter second (15 ticks)
	Variable/G Start=ticks
	Variable/G RunTime=(RunTimePassed*60)
	CtrlNamedBackground Timer, period=5, proc=Timer
	CtrlNamedBackground Timer, start
End

Function Timer(s)
	STRUCT WMBackgroundStruct &s
	SVAR panelTitleG
	NVAR Start, RunTime
	variable TimeLeft
	
	variable ElapsedTime=(ticks-Start)
	
	TimeLeft=abs(((RunTime-(ElapsedTime))/60))
	if(TimeLeft<0)
	timeleft=0
	endif
	ValDisplay valdisp_DataAcq_ITICountdown win=$panelTitleG, value=_NUM:TimeLeft
	
	if(ElapsedTime>=RunTime)
	StopBackgroundTimerTask()
	endif
	//printf "NextRunTicks %d", s.nextRunTicks
	return 0
End

Function StopBackgroundTimerTask()
	SVAR FunctionNameA
	SVAR FunctionNameB
	//SVAR FunctionNameC
	CtrlNamedBackground Timer, stop
	Execute FunctionNameA
 	Execute FunctionNameB
	//Execute FunctionNameC
	//killvariables/z Start, RunTime
	//Killstrings/z FunctionNameA, FunctionNameB, FunctionNameC
End
//======================================================================================

Function StartBackgroundTestPulse(DeviceType, DeviceNum, panelTitle)
	variable DeviceType, DeviceNum	// ITC-1600
	string panelTitle
	string/G PanelTitleG = panelTitle
	string cmd
	variable i=0
	variable/G StopCollectionPoint = CalculateITCDataWaveLength(panelTitle)/4
	variable/G ADChannelToMonitor=(NoOfChannelsSelected("DA", "Check", panelTitle))
	doupdate
	string WavePath = HSU_DataFullFolderPathString(PanelTitle)
	wave ITCDataWave = $WavePath + ":ITCDataWave", ITCFIFOAvailAllConfigWave = $WavePath + ":ITCFIFOAvailAllConfigWave"//, ChannelConfigWave, UpdateFIFOWave, RecordedWave
	string  ITCDataWavePath = WavePath + ":ITCDataWave", ITCChanConfigWavePath = WavePath + ":ITCChanConfigWave"
	// open ITC device
	sprintf cmd, "ITCOpenDevice %d, %d", DeviceType, DeviceNum
	Execute cmd	
	sprintf cmd, "ITCconfigAllchannels, %s, %s" ITCChanConfigWavePath, ITCDataWavePath
	execute cmd
	CtrlNamedBackground TestPulse, period=2, proc=TestPulseFunc
	CtrlNamedBackground TestPulse, start
End
//======================================================================================

Function TestPulseFunc(s)
	STRUCT WMBackgroundStruct &s
	NVAR StopCollectionPoint, ADChannelToMonitor
	SVAR panelTitleG
	String cmd, Keyboard
	string paneltitle = panelTitleG
	string WavePath = HSU_DataFullFolderPathString(PanelTitle)
	wave ITCDataWave = $WavePath + ":ITCDataWave", ITCFIFOAvailAllConfigWave = $WavePath + ":ITCFIFOAvailAllConfigWave"
	string  ITCFIFOPositionAllConfigWavePth = WavePath + ":ITCFIFOPositionAllConfigWave"
	string ITCFIFOAvailAllConfigWavePath = WavePath + ":ITCFIFOAvailAllConfigWave"
	string ResultsWavePath = WavePath + ":ResultsWave"
	string CountPath=WavePath+"count"
		sprintf cmd, "ITCUpdateFIFOPositionAll , %s" ITCFIFOPositionAllConfigWavePth // I have found it necessary to reset the fifo here, using the /r=1 with start acq doesn't seem to work
		execute cmd// this also seems necessary to update the DA channel data to the board!!
		sprintf cmd, "ITCStartAcq"
		Execute cmd	
		
		 //StartBackgroundFIFOMonitor()
			do
				sprintf cmd, "ITCFIFOAvailableALL/z=0 , %s" ITCFIFOAvailAllConfigWavePath
				Execute cmd	
				//doxopidle
			while (ITCFIFOAvailAllConfigWave[ADChannelToMonitor][2] < StopCollectionPoint)// 5000 IS CHOSEN AS A POINT THAT IS A BIT LARGER THAN THE OUTPUT DATA
		//Check Status
		sprintf cmd, "ITCGetState /R /O /C /E %s" ResultsWavePath
		Execute cmd
		sprintf cmd, "ITCStopAcq/z=0"
		Execute cmd
		sprintf cmd, "ITCConfigChannelUpload/f/z=0"//AS Long as this command is within the do-while loop the number of cycles can be repeated		
		Execute cmd
		CreateAndScaleTPHoldingWave(panelTitle)
		TPDelta(panelTitle, WavePath + ":TestPulse") 
		//itcdatawave[0][0]+=0//runs arithmatic on data wave to force onscreen update 
		//doupdate	

		if(exists(countPath)==0)// uses the presence of a global variable that is created by the activation of repeated aquisition to determine if the space bar can turn off the TP
			Keyboard = KeyboardState("")
			if (cmpstr(Keyboard[9], " ") == 0)	// Is space bar pressed (note the space between the quotations)?
				beep 
				STOPTestPulse(panelTitle)
			endif
		endif
	return 0
	
End
//======================================================================================

Function STOPTestPulse(panelTitle)
	string panelTitle
	string cmd
	CtrlNamedBackground TestPulse, stop
	sprintf cmd, "ITCCloseAll" 
	execute cmd
	killvariables/z  StopCollectionPoint, ADChannelToMonitor, BackgroundTaskActive
	killstrings/z PanelTitleG
	controlinfo/w=$panelTitle check_Settings_ShowScopeWindow
	if(v_value==0)
	SmoothResizePanel(-340, panelTitle)
	endif

	RestoreTTLState(panelTitle)
	//killwaves/z root:WaveBuilder:SavedStimulusSets:DA:TestPulse// this line generates an error. hence the /z. not sure why.


End

//======================================================================================


//StartBackgroundTestPulse();StartBackgroundTimer(20, "STOPTestPulse()")  This line of code starts the tests pulse and runs it for 20 seconds

Function StartTestPulse(DeviceType, DeviceNum, panelTitle)
	variable DeviceType, DeviceNum
	string panelTitle
	string cmd
	variable i=0
	variable StopCollectionPoint = CalculateITCDataWaveLength(panelTitle)/4
	variable ADChannelToMonitor=(NoOfChannelsSelected("DA", "Check", panelTitle))
	
	string WavePath = HSU_DataFullFolderPathString(PanelTitle)
	
	//wave ITCChanConfigWave = $WavePath + ":ITCChanConfigWave"
	string ITCChanConfigWavePath = WavePath + ":ITCChanConfigWave"
	
	//wave ITCDataWave = $WavePath + ":ITCDataWave"
	string ITCDataWavePath = WavePath + ":ITCDataWave"
	
	wave ITCFIFOAvailAllConfigWave = $WavePath+ ":ITCFIFOAvailAllConfigWave"//, ChannelConfigWave, UpdateFIFOWave, RecordedWave
	string ITCFIFOAvailAllConfigWavePath = WavePath+ ":ITCFIFOAvailAllConfigWave"
	
	//wave ITCFIFOPositionAllConfigWave = $WavePath + ":ITCFIFOPositionAllConfigWave"
	string ITCFIFOPositionAllConfigWavePth = WavePath + ":ITCFIFOPositionAllConfigWave"
	
	//wave ResultsWave = $WavePath + ":ResultsWave"
	string ResultsWavePath = WavePath + ":ResultsWave"
	
	string Keyboard

	make /O /I /N = 4 $ResultsWavePath 
	doupdate
	// open ITC device
	sprintf cmd, "ITCOpenDevice %d, %d", DeviceType, DeviceNum
	Execute cmd	
	sprintf cmd, "ITCconfigAllchannels, %s, %s" ITCChanConfigWavePath, ITCDataWavePath
	execute cmd
	do

		sprintf cmd, "ITCUpdateFIFOPositionAll , %s" ITCFIFOPositionAllConfigWavePth// I have found it necessary to reset the fifo here, using the /r=1 with start acq doesn't seem to work
		execute cmd// this also seems necessary to update the DA channel data to the board!!
		sprintf cmd, "ITCStartAcq"// /f/r=0/z=0 -1,0,1,1"//   
		Execute cmd	
			do
				sprintf cmd, "ITCFIFOAvailableALL/z=0 , %s" ITCFIFOAvailAllConfigWavePath
				Execute cmd	
				//doxopidle
			while (ITCFIFOAvailAllConfigWave[ADChannelToMonitor][2] < StopCollectionPoint)// 
		//Check Status
		sprintf cmd, "ITCGetState /R /O /C /E %s" ResultsWavePath
		Execute cmd
		sprintf cmd, "ITCStopAcq/z=0"
		Execute cmd
		CreateAndScaleTPHoldingWave(panelTitle)
		TPDelta(panelTitle, WavePath + ":TestPulse") 
		doupdate
		//itcdatawave[0][0]+=0//runs arithmatic on data wave to force onscreen update 
		//doupdate
		sprintf cmd, "ITCConfigChannelUpload/f/z=0"//AS Long as this command is within the do-while loop the number of cycles can be repeated		
		Execute cmd
		
	Keyboard = KeyboardState("")
	while (cmpstr(Keyboard[9], " ") != 0)// 
	
	sprintf cmd, "ITCCloseAll" 
	execute cmd

	RestoreTTLState(panelTitle)


END
//======================================================================================

Function SingleADReading(Channel, panelTitle)//channels 16-23 are asynch channels on ITC1600
variable Channel
string panelTitle
variable ChannelValue
string cmd
string WavePath = HSU_DataFullFolderPathString(PanelTitle)
make/o/n=1 $WavePath+":AsyncChannelData"
string AsyncChannelDataPath = WavePath+":AsyncChannelData"
wave AsyncChannelData = $AsyncChannelDataPath
sprintf cmd, "ITCReadADC %d, %s" Channel, AsyncChannelDataPath
execute cmd
ChannelValue = AsyncChannelData[0]
killwaves/f AsyncChannelData
return ChannelValue
End 

//======================================================================================

Function AD_DataBasedWaveNotes(DataWave, DeviceType, DeviceNum,panelTitle)
Wave DataWave
variable DeviceType, DeviceNum
string panelTitle
// This function takes about 0.9 seconds to run
// this is the wave that the note gets appended to. The note contains the async ad channel value and info
//variable starttime=ticks
string AsyncChannelState = ControlStatusListString("AsyncAD", "check", panelTitle)
variable i
variable TotAsyncChannels = itemsinlist(AsyncChannelState,";")
variable RawChannelValue
string cmd
string SetVar_Title, Title
string SetVar_gain, Measurement
string SetVar_Unit, Unit
string WaveNote = ""
sprintf cmd, "ITCOpenDevice %d, %d", DeviceType, DeviceNum
Execute cmd	

do
if(str2num(stringfromlist(i,AsyncChannelState,";"))==1)
RawChannelValue=SingleADReading(i+15, panelTitle)//Async channels start at channel 16 on ITC 1600, needs to be a diff value constant for ITC18

	if(i<10)
		 SetVar_title = "SetVar_Async_Title_0"+num2str(i)
		 SetVar_gain = "SetVar_AsyncAD_Gain_0"+num2str(i)
		 SetVar_Unit = "SetVar_Async_Unit_0"+num2str(i)
	else
		 SetVar_title = "SetVar_Async_Title_"+num2str(i)
		 SetVar_gain = "SetVar_AsyncAD_Gain_"+num2str(i)
		 SetVar_Unit = "SetVar_Async_Unit_"+num2str(i)
	endif 
	
	controlInfo/w=$panelTitle $SetVar_title
	title=s_value
	controlInfo/w=$panelTitle $SetVar_gain
	Measurement=num2str(v_value*RawChannelValue)
	SupportSystemAlarm(i, v_value*RawChannelValue, title, panelTitle)
	controlInfo/w=$panelTitle $SetVar_Unit
	Unit=s_value
	WaveNote= title +" "+ Measurement +" " + Unit
	note DataWave, WaveNote
endif
i+=1
while(i<TotAsyncChannels)

sprintf cmd, "ITCCloseAll" 
execute cmd
//print (ticks-starttime)/60

End
//======================================================================================
Function SupportSystemAlarm(Channel, Measurement, MeasurementTitle, panelTitle)
variable Channel, Measurement
string MeasurementTitle, panelTitle
String CheckAlarm, SetVarTitle, SetVarMin, SetVarMax, Title
variable ParamMin, ParamMax

if(channel<10)
	CheckAlarm="check_Async_Alarm_0"+num2str(channel)
	SetVarMin="setvar_Async_min_0"+num2str(channel)	
	SetVarMax="setvar_Async_max_0"+num2str(channel)	
else
	CheckAlarm="check_Async_Alarm_"+num2str(channel)
	SetVarMin="setvar_Async_min_"+num2str(channel)				
	SetVarMax="setvar_Async_max_"+num2str(channel)
endif

ControlInfo /W=$panelTitle $CheckAlarm
if(v_value==1)
	ControlInfo /W=$panelTitle $SetVarMin
	ParamMin=v_value
	ControlInfo /W=$panelTitle $SetVarMax
	ParamMax=v_value
	print measurement
	if(Measurement>= ParamMax || Measurement<= ParamMin)
		beep
		print time() +" !!!!!!!!!!!!! "+ MeasurementTitle +" has exceeded max/min settings"+" !!!!!!!!!!!!!"
		beep
	endif
endif

End