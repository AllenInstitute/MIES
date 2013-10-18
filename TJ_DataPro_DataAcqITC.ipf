#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Function ITCDataAcq()
	string cmd
	variable DeviceType = 2	// ITC-1600
	variable DeviceNum = 0
	variable i=0
	variable StopCollectionPoint = CalculateITCDataWaveLength()/4
	variable ADChannelToMonitor=(NoOfChannelsSelected("DA", "Check"))
	wave ITCFIFOAvailAllConfigWave, ITCDataWave//, ChannelConfigWave, UpdateFIFOWave, RecordedWave
	
	make /O /I /N = 4 ResultWave 
	doupdate
	// open ITC device
	sprintf cmd, "ITCOpenDevice %d, %d", DeviceType, DeviceNum
	Execute cmd	
	sprintf cmd, "ITCconfigAllchannels, ITCChanConfigWave, ITCDatawave"
	execute cmd
	do

		sprintf cmd, "ITCUpdateFIFOPositionAll , ITCFIFOPositionAllConfigWave"// I have found it necessary to reset the fifo here, using the /r=1 with start acq doesn't seem to work
		execute cmd// this also seems necessary to update the DA channel data to the board!!
		sprintf cmd, "ITCStartAcq"// /f/r=0/z=0 -1,0,1,1"//   
		Execute cmd	
			do
				sprintf cmd, "ITCFIFOAvailableALL/z=0 , ITCFIFOAvailAllConfigWave"
				Execute cmd	
				ITCDataWave[0][0]+=0
				doupdate/w=datapro_itc1600#oscilloscope
				//doxopidle
			while (ITCFIFOAvailAllConfigWave[ADChannelToMonitor][2] < StopCollectionPoint)// 
		//Check Status
		sprintf cmd, "ITCGetState /R /O /C /E ResultWave"
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

	ControlInfo/w=DataPro_ITC1600 Check_Settings_SaveData
	If(v_value==0)
	SaveITCData()
	endif
	
	 ScaleITCDataWave()
END

//======================================================================================
Function ITCBkrdAcq()
	string cmd
	variable DeviceType = 2	// ITC-1600
	variable DeviceNum = 0
	variable i=0
	variable/G StopCollectionPoint = (CalculateITCDataWaveLength()/4)
	variable/G ADChannelToMonitor=(NoOfChannelsSelected("DA", "Check"))
	//MakeStartParameters()
	doupdate
	
	wave ITCFIFOAvailAllConfigWave, ITCDataWave//, ChannelConfigWave, UpdateFIFOWave, RecordedWave
	// open ITC device
	
	sprintf cmd, "ITCOpenDevice %d, %d", DeviceType, DeviceNum
		Execute cmd	
	sprintf cmd, "ITCconfigAllchannels, ITCChanConfigWave, ITCDatawave"
		execute cmd
	sprintf cmd, "ITCUpdateFIFOPositionAll , ITCFIFOPositionAllConfigWave"// I have found it necessary to reset the fifo here, using the /r=1 with start acq doesn't seem to work
		execute cmd// this also seems necessary to update the DA channel data to the board!!
	sprintf cmd, "ITCStartAcq" 
		Execute cmd	
	
	StartBackgroundFIFOMonitor()
	
	End
//======================================================================================
Function StopDataAcq()
string cmd
wave itcdatawave
NVAR StopCollectionPoint, ADChannelToMonitor


	sprintf cmd, "ITCStopAcq/z=0"
	Execute cmd

	itcdatawave[0][0]+=0//runs arithmatic on data wave to force onscreen update 
	doupdate
	
	sprintf cmd, "ITCConfigChannelUpload/f/z=0"//AS Long as this command is within the do-while loop the number of cycles can be repeated		
	Execute cmd	
	
	sprintf cmd, "ITCCloseAll" 
	execute cmd
	
	killvariables/z StopCollectionPoint, ADChannelToMonitor
	
	ControlInfo/w=DataPro_ITC1600 Check_Settings_SaveData
	If(v_value==0)
	SaveITCData()// saving always comes before scaling - there are two independent scaling steps
	endif
	
	 ScaleITCDataWave()
	
	if(exists("Count")==0)//If the global variable count does not exist, it is the first trial of repeated acquisition
	controlinfo/w=DataPro_ITC1600 Check_DataAcq1_RepeatAcq
		if(v_value==1)//repeated aquisition is selected
			RepeatedAcquisition()
		endif
	else
		BckgTPwithCallToRptAcqContr()//FUNCTION THAT ACTIVATES BCKGRD TP AND THEN CALLS REPEATED ACQ XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
	endif
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
	String cmd
	Wave ITCFIFOAvailAllConfigWave, itcdatawave
	sprintf cmd, "ITCFIFOAvailableALL/z=0 , ITCFIFOAvailAllConfigWave"
	Execute cmd	
	ITCDataWave[0][0]+=0//forces on screen update
	doupdate/w=datapro_itc1600#oscilloscope
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

Function StartBackgroundTimer(RunTimePassed,FunctionNameAPassedIn, FunctionNameBPassedIn,  FunctionNameCPassedIn)//Function name is the name of the function you want to run after run time has elapsed
	Variable RunTimePassed//how long you want the background timer to run in seconds
	String FunctionNameAPassedIn, FunctionNameBPassedIn, FunctionNameCPassedIn
	String/G FunctionNameA=FunctionNameAPassedIn
	String/G FunctionNameB=FunctionNameBPassedIn
	String/G FunctionNameC=FunctionNameCPassedIn
	Variable numTicks = 15		// Run every quarter second (15 ticks)
	Variable/G Start=ticks
	Variable/G RunTime=(RunTimePassed*60)
	CtrlNamedBackground Timer, period=5, proc=Timer
	CtrlNamedBackground Timer, start
End

Function Timer(s)
	STRUCT WMBackgroundStruct &s
	NVAR Start, RunTime
	variable TimeLeft
	
	variable ElapsedTime=(ticks-Start)
	
	TimeLeft=abs(((RunTime-(ElapsedTime))/60))
	if(TimeLeft<0)
	timeleft=0
	endif
	ValDisplay valdisp_DataAcq_ITICountdown win=DataPro_ITC1600, value=_NUM:TimeLeft
	
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

Function StartBackgroundTestPulse()
	string cmd
	variable DeviceType = 2	// ITC-1600
	variable DeviceNum = 0
	variable i=0
	variable/G StopCollectionPoint = CalculateITCDataWaveLength()/4
	variable/G ADChannelToMonitor=(NoOfChannelsSelected("DA", "Check"))
	doupdate
	wave ITCFIFOAvailAllConfigWave, ITCDataWave//, ChannelConfigWave, UpdateFIFOWave, RecordedWave

	// open ITC device
	sprintf cmd, "ITCOpenDevice %d, %d", DeviceType, DeviceNum
	Execute cmd	
	sprintf cmd, "ITCconfigAllchannels, ITCChanConfigWave, ITCDatawave"
	execute cmd
	CtrlNamedBackground TestPulse, period=2, proc=TestPulseFunc
	CtrlNamedBackground TestPulse, start
End
//======================================================================================

Function TestPulseFunc(s)
	STRUCT WMBackgroundStruct &s
	NVAR StopCollectionPoint, ADChannelToMonitor
	String cmd, Keyboard
	Wave ITCFIFOAvailAllConfigWave, itcdatawave
	
		sprintf cmd, "ITCUpdateFIFOPositionAll , ITCFIFOPositionAllConfigWave"// I have found it necessary to reset the fifo here, using the /r=1 with start acq doesn't seem to work
		execute cmd// this also seems necessary to update the DA channel data to the board!!
		sprintf cmd, "ITCStartAcq"
		Execute cmd	
		
		 //StartBackgroundFIFOMonitor()
			do
				sprintf cmd, "ITCFIFOAvailableALL/z=0 , ITCFIFOAvailAllConfigWave"
				Execute cmd	
				//doxopidle
			while (ITCFIFOAvailAllConfigWave[ADChannelToMonitor][2] < StopCollectionPoint)// 5000 IS CHOSEN AS A POINT THAT IS A BIT LARGER THAN THE OUTPUT DATA
		//Check Status
		sprintf cmd, "ITCGetState /R /O /C /E ResultWave"
		Execute cmd
		sprintf cmd, "ITCStopAcq/z=0"
		Execute cmd
		sprintf cmd, "ITCConfigChannelUpload/f/z=0"//AS Long as this command is within the do-while loop the number of cycles can be repeated		
		Execute cmd
		CreateAndScaleTPHoldingWave()
		//itcdatawave[0][0]+=0//runs arithmatic on data wave to force onscreen update 
		//doupdate	

		if(exists("count")==0)// uses the presence of a global variable that is created by the activation of repeated aquisition to determine if the space bar can turn off the TP
			Keyboard = KeyboardState("")
			if (cmpstr(Keyboard[9], " ") == 0)	// Is space bar pressed (note the space between the quotations)?
				beep 
				STOPTestPulse()
			endif
		endif
	return 0
	
End
//======================================================================================

Function STOPTestPulse()
	string cmd
	CtrlNamedBackground TestPulse, stop
	sprintf cmd, "ITCCloseAll" 
	execute cmd
	killvariables/z  StopCollectionPoint, ADChannelToMonitor, BackgroundTaskActive
	controlinfo/w=DataPro_ITC1600 check_Settings_ShowScopeWindow
	if(v_value==0)
	SmoothResizePanel(-340)
	endif

	RestoreTTLState()

End

//======================================================================================


//StartBackgroundTestPulse();StartBackgroundTimer(20, "STOPTestPulse()")  This line of code starts the tests pulse and runs it for 20 seconds

Function StartTestPulse()
	string cmd
	variable DeviceType = 2	// ITC-1600
	variable DeviceNum = 0
	variable i=0
	variable StopCollectionPoint = CalculateITCDataWaveLength()/4
	variable ADChannelToMonitor=(NoOfChannelsSelected("DA", "Check"))
	wave ITCFIFOAvailAllConfigWave, ITCDataWave//, ChannelConfigWave, UpdateFIFOWave, RecordedWave
	string Keyboard

	
	make /O /I /N = 4 ResultWave 
	doupdate
	// open ITC device
	sprintf cmd, "ITCOpenDevice %d, %d", DeviceType, DeviceNum
	Execute cmd	
	sprintf cmd, "ITCconfigAllchannels, ITCChanConfigWave, ITCDatawave"
	execute cmd
	do

		sprintf cmd, "ITCUpdateFIFOPositionAll , ITCFIFOPositionAllConfigWave"// I have found it necessary to reset the fifo here, using the /r=1 with start acq doesn't seem to work
		execute cmd// this also seems necessary to update the DA channel data to the board!!
		sprintf cmd, "ITCStartAcq"// /f/r=0/z=0 -1,0,1,1"//   
		Execute cmd	
			do
				sprintf cmd, "ITCFIFOAvailableALL/z=0 , ITCFIFOAvailAllConfigWave"
				Execute cmd	
				//doxopidle
			while (ITCFIFOAvailAllConfigWave[ADChannelToMonitor][2] < StopCollectionPoint)// 
		//Check Status
		sprintf cmd, "ITCGetState /R /O /C /E ResultWave"
		Execute cmd
		sprintf cmd, "ITCStopAcq/z=0"
		Execute cmd
		CreateAndScaleTPHoldingWave()
		doupdate
		//itcdatawave[0][0]+=0//runs arithmatic on data wave to force onscreen update 
		//doupdate
		sprintf cmd, "ITCConfigChannelUpload/f/z=0"//AS Long as this command is within the do-while loop the number of cycles can be repeated		
		Execute cmd
		
	Keyboard = KeyboardState("")
	while (cmpstr(Keyboard[9], " ") != 0)// 
	
	sprintf cmd, "ITCCloseAll" 
	execute cmd

	RestoreTTLState()


END
//======================================================================================

Function SingleADReading(Channel)//channels 16-23 are asynch channels on ITC1600
variable Channel
variable ChannelValue
string cmd
make/o/n=1 AsyncChannelData
sprintf cmd, "ITCReadADC %d, AsyncChannelData" Channel
execute cmd
ChannelValue = AsyncChannelData[0]
killwaves/f AsyncChannelData
return ChannelValue
End 

//======================================================================================

Function AD_DataBasedWaveNotes(DataWave)// This function takes about 0.9 seconds to run
Wave DataWave// this is the wave that the note gets appended to. The note contains the async ad channel value and info
//variable starttime=ticks
string AsyncChannelState = ControlStatusListString("AsyncAD", "check")
variable i
variable TotAsyncChannels = itemsinlist(AsyncChannelState,";")
variable DeviceType = 2	// ITC-1600
variable DeviceNum = 0
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
RawChannelValue=SingleADReading(i+15)//Async channels start at channel 16 on ITC 1600, needs to be a diff value constant for ITC18

	if(i<10)
		 SetVar_title = "SetVar_Async_Title_0"+num2str(i)
		 SetVar_gain = "SetVar_AsyncAD_Gain_0"+num2str(i)
		 SetVar_Unit = "SetVar_Async_Unit_0"+num2str(i)
	else
		 SetVar_title = "SetVar_Async_Title_"+num2str(i)
		 SetVar_gain = "SetVar_AsyncAD_Gain_"+num2str(i)
		 SetVar_Unit = "SetVar_Async_Unit_"+num2str(i)
	endif 
	
	controlInfo/w=datapro_ITC1600 $SetVar_title
	title=s_value
	controlInfo/w=datapro_ITC1600 $SetVar_gain
	Measurement=num2str(v_value*RawChannelValue)
	SupportSystemAlarm(i, v_value*RawChannelValue, title)
	controlInfo/w=datapro_ITC1600 $SetVar_Unit
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
Function SupportSystemAlarm(Channel, Measurement, MeasurementTitle)
variable Channel, Measurement
string MeasurementTitle
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

ControlInfo $CheckAlarm
if(v_value==1)
	ControlInfo $SetVarMin
	ParamMin=v_value
	ControlInfo $SetVarMax
	ParamMax=v_value
	print measurement
	if(Measurement>= ParamMax || Measurement<= ParamMin)
		beep
		print time() +" !!!!!!!!!!!!! "+ MeasurementTitle +" has exceeded max/min settings"+" !!!!!!!!!!!!!"
		beep
	endif
endif

End