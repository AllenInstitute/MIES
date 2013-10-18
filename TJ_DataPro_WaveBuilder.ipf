#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Function DisplaySetInPanel()
	variable i=0
	
	RemoveAndKillTracesOnGraph()
	
	MakeStimSet()
	string ListOfWavesToGraph
	
	string basename
	controlinfo setvar_WaveBuilder_baseName
	basename=s_value
	
	variable SetNumber
	controlinfo setvar_WaveBuilder_SetNumber
	SetNumber = v_value
	
	controlInfo popup_WaveBuilder_OutputType
	string OutputWaveType=s_value
	string SearchString = "*" + basename + "*"+OutputWaveType+"_Set*"+num2str(SetNumber)
	ListOfWavesToGraph = wavelist(SearchString,";","")
	
	variable NoOfWavesInList = itemsinlist(ListOfWavesToGraph,";")
	
	do
	
		appendtograph/w=WaveBuilder#WaveBuilderGraph $stringfromlist(i,ListOfWavesToGraph,";")
			if(mod(i,2)==0) // odd numbered waves get made black
			ModifyGraph/w=WaveBuilder#WaveBuilderGraph rgb($stringfromlist(i,ListOfWavesToGraph,";"))=(13056,13056,13056)
			endif
		i+=1
	while(i<NoOfWavesInList)
End

Function RemoveAndKillTracesOnGraph()
	variable i=0
	string cmd, WaveNameFromList
	string ListOfTracesOnGraph
	ListOfTracesOnGraph=TraceNameList("WaveBuilder#WaveBuilderGraph", ",",0+1 )

	do
	removefromgraph/z/w=WaveBuilder#WaveBuilderGraph $stringfromlist(i,ListOfTracesOnGraph,",")
	//doupdate
	WaveNameFromList=stringfromlist(i,ListOfTracesOnGraph,",")
	if(strlen(WaveNameFromList) != 0)
	sprintf cmd, "killwaves/f/z  %s" WaveNameFromList
	execute cmd
	endif
	i+=1
	while(i<(itemsinlist(ListOfTracesOnGraph,",")))
End

Function MakeStimSet()
	wave  WaveBuilderWave
	variable i = 1
	
	wave wp//WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW
	duplicate/free wp, wpd// duplicating starting parameter waves so that they can be returned to start parameters at end of wave making
	//duplicate/free wp1, wp1d//WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW
	//duplicate/free wp2, wp2d
	//duplicate/free wp3, wp3d
	//duplicate/free wp4, wp4d
	//duplicate/free wp5, wp5d
	//duplicate/free wp6, wp6d
	//duplicate/free wp7, wp7d

	controlinfo setvar_WaveBuilder_baseName
	string setbasename=s_value
	
	controlinfo setvar_WaveBuilder_SetNumber
	variable setnumber=v_value
	
	controlinfo SetVar_WaveBuilder_StepCount
	variable NoOfWavesInSet=v_value
	
	string OutputWaveName
	
	do
		MakeWaveBuilderWave()
		AddDelta()
		
		controlInfo popup_WaveBuilder_OutputType
		string OutputWaveType=s_value
		
		OutputWaveName=num2str(i)+"_"+setbasename+"_"+OutputWaveType+"_Set_"+num2str(setnumber)
		duplicate/o WaveBuilderWave, $OutputWaveName
		i+=1
	while(i<=NoOfWavesInSet)

	wp = wpd//WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW
	//wp1 = wp1d
	//wp2 = wp2d
	//wp3 = wp3d
	//wp4 = wp4d
	//wp5 = wp5d
	//wp6 = wp6d
	//wp7 = wp7d


End



Function AddDelta()//adds delta to appropriate parameter - relies on alternating sequence of parameter and delta's in parameter waves
wave WP//WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW
	
	variable i=0
	
	do
	controlinfo check_WaveBuilder_exp
	if(v_value==0)
	wp[i][][0]=wp[(i+1)][q][0]+wp[i][q][0]//WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW
	wp[i][][1]=wp[(i+1)][q][1]+wp[i][q][1]
	wp[i][][2]=wp[(i+1)][q][2]+wp[i][q][2]
	wp[i][][3]=wp[(i+1)][q][3]+wp[i][q][3]
	wp[i][][4]=wp[(i+1)][q][4]+wp[i][q][4]
	wp[i][][5]=wp[(i+1)][q][5]+wp[i][q][5]
	wp[i][][6]=wp[(i+1)][q][6]+wp[i][q][6]
	wp[i][][7]=wp[(i+1)][q][7]+wp[i][q][7]
	else
	wp[i][][0]=(wp[(i+1)][q][0])+wp[i][q][0]
	wp[i][][1]=(wp[(i+1)][q][1])+wp[i][q][1]
	wp[i][][2]=(wp[(i+1)][q][2])+wp[i][q][2]
	wp[i][][3]=(wp[(i+1)][q][3])+wp[i][q][3]
	wp[i][][4]=(wp[(i+1)][q][4])+wp[i][q][4]
	wp[i][][5]=(wp[(i+1)][q][5])+wp[i][q][5]
	wp[i][][6]=(wp[(i+1)][q][6])+wp[i][q][6]
	wp[i][][7]=(wp[(i+1)][q][7])+wp[i][q][7]

	
	wp[i+1][][0]+=(wp[(i+1)][q][0])
	wp[i+1][][1]+=(wp[(i+1)][q][1])
	wp[i+1][][2]+=(wp[(i+1)][q][2])
	wp[i+1][][3]+=(wp[(i+1)][q][3])
	wp[i+1][][4]+=(wp[(i+1)][q][4])
	wp[i+1][][5]+=(wp[(i+1)][q][5])
	wp[i+1][][6]+=(wp[(i+1)][q][6])
	wp[i+1][][7]+=(wp[(i+1)][q][7])

	endif
	
	i+=2
	while(i<24)
End



Function MakeWaveBuilderWave()
variable Amplitude, DeltaAmp, Duration, DeltaDur, OffSet, DeltaOffset, Frequency, DeltaFreq, PulseDuration, DeltaPulsedur, TauRise,TauDecay1,TauDecay2,TauDecay2Weight
variable CustomOffset, CustumDeltaOffset, LowPassCutOff, LowPassCutOffDelta, HighPassCutOff, HighPassCutOffDelta
wave SegmentWaveType
make/o/n=0 WaveBuilderWave=0
make/o/n=0 SegmentWave=0

variable NumberOfSegments
controlinfo SetVar_WaveBuilder_NoOfSegments
NumberOfSegments=v_value
variable i = 0
string cmd, NameOfWaveToBeDuplicated, NameOfWaveToBeDuplicated_NOQUOT
String ParameterWaveName

Variable/g  ParameterHolder
String/g StringHolder
do
	//Load in parameters
	//ParameterWaveName="WP"+num2str(SegmentWaveType[i])
	ParameterWaveName="WP"
	//Amplitude=$ParameterWaveName[0][i] 

	sprintf cmd, "ParameterHolder	=%s[%d][%d][%d]" ParameterWaveName, 0, i, SegmentWaveType[i]
	Execute cmd
	Duration=ParameterHolder
	
	sprintf cmd, "	ParameterHolder	=%s[%d][%d][%d]" ParameterWaveName, 1, i, SegmentWaveType[i]
	Execute cmd
	DeltaDur=ParameterHolder
	
	sprintf cmd, "ParameterHolder	=%s[%d][%d][%d]" ParameterWaveName, 2, i, SegmentWaveType[i]		
	Execute cmd
	Amplitude=ParameterHolder
	
	sprintf cmd, "ParameterHolder	=%s[%d][%d][%d]" ParameterWaveName, 3, i, SegmentWaveType[i]
	Execute cmd
	DeltaAmp=ParameterHolder
	
	sprintf cmd, "ParameterHolder	=%s[%d][%d][%d]" ParameterWaveName, 4, i, SegmentWaveType[i]
	Execute cmd
	Offset=ParameterHolder
	
	sprintf cmd, "	ParameterHolder	=%s[%d][%d][%d]" ParameterWaveName, 5, i, SegmentWaveType[i]
	Execute cmd
	DeltaOffset=ParameterHolder
	
	sprintf cmd, "	ParameterHolder	=%s[%d][%d][%d]" ParameterWaveName, 6, i, SegmentWaveType[i]
	Execute cmd
	Frequency=ParameterHolder
	
	sprintf cmd, "	ParameterHolder	=%s[%d][%d][%d]" ParameterWaveName, 7, i, SegmentWaveType[i]
	Execute cmd
	DeltaFreq=ParameterHolder
	
	sprintf cmd, "	ParameterHolder	=%s[%d][%d][%d]" ParameterWaveName, 8, i, SegmentWaveType[i]
	Execute cmd
	PulseDuration=ParameterHolder
	
	sprintf cmd, "ParameterHolder	=%s[%d][%d][%d]" ParameterWaveName, 9, i, SegmentWaveType[i]
	Execute cmd
	DeltaPulsedur=ParameterHolder

	sprintf cmd, "	ParameterHolder	=%s[%d][%d][%d]" ParameterWaveName, 10, i, SegmentWaveType[i]	//row spacing changes here to leave room for addition of delta parameters in the future - also allows for universal delta parameter addition		
	Execute cmd
	TauRise=ParameterHolder
	
	sprintf cmd, "	ParameterHolder	=%s[%d][%d][%d]" ParameterWaveName, 12, i, SegmentWaveType[i]
	Execute cmd
	TauDecay1=ParameterHolder
	
	sprintf cmd, "	ParameterHolder	=%s[%d][%d][%d]" ParameterWaveName, 14, i, SegmentWaveType[i]
	Execute cmd
	TauDecay2=ParameterHolder
	
	sprintf cmd, "ParameterHolder=%s[%d][%d][%d]" ParameterWaveName, 16, i, SegmentWaveType[i]
	Execute cmd
	TauDecay2Weight=ParameterHolder
	
	sprintf cmd, "ParameterHolder=%s[%d][%d][%d]" ParameterWaveName, 18, i, SegmentWaveType[i]
	Execute cmd
	CustomOffset=ParameterHolder
	
	sprintf cmd, "ParameterHolder=%s[%d][%d][%d]" ParameterWaveName, 19, i, SegmentWaveType[i]
	Execute cmd
	CustumDeltaOffset=ParameterHolder
	
	sprintf cmd, "StringHolder=%s[%d][%d]"  "WP7T", 0, i// passes name of custom wave from a text wave
	Execute cmd
	NameOfWaveToBeDuplicated="'"+StringHolder+"'"
	
	sprintf cmd, "ParameterHolder=%s[%d][%d][%d]" ParameterWaveName, 20, i, SegmentWaveType[i]
	Execute cmd
	LowPassCutOff=ParameterHolder	
	
	sprintf cmd, "ParameterHolder=%s[%d][%d][%d]" ParameterWaveName, 21, i, SegmentWaveType[i]
	Execute cmd
	LowPassCutOffDelta=ParameterHolder	

	sprintf cmd, "ParameterHolder=%s[%d][%d][%d]" ParameterWaveName, 22, i, SegmentWaveType[i]
	Execute cmd
	HighPassCutOff=ParameterHolder
		
	sprintf cmd, "ParameterHolder=%s[%d][%d][%d]" ParameterWaveName, 23, i, SegmentWaveType[i]
	Execute cmd
	HighPassCutOffDelta=ParameterHolder	
	
		
	//Make correct wave segment with above parameters
	switch(SegmentWaveType[i])												// numeric switch
		case 0:
			SquareSegment(Amplitude, DeltaAmp, Duration, DeltaDur, OffSet, DeltaOffset, Frequency, DeltaFreq, PulseDuration, DeltaPulsedur, TauRise,TauDecay1,TauDecay2,TauDecay2Weight)
			Note WaveBuilderWave, "Segment "+num2str(i)+"= Square pulse , properties: Amplitude = "+num2str(Amplitude)+"  Duration = " + num2str(Duration)
			break
		case 1:
			RampSegment(Amplitude, DeltaAmp, Duration, DeltaDur, OffSet, DeltaOffset, Frequency, DeltaFreq, PulseDuration, DeltaPulsedur, TauRise,TauDecay1,TauDecay2,TauDecay2Weight)
			Note WaveBuilderWave, "Segment "+num2str(i)+"= Ramp, properties: Amplitude = "+num2str(Amplitude)+"  Duration = " + num2str(Duration)
			break
		case 2:
			NoiseSegment(Amplitude, DeltaAmp, Duration, DeltaDur, OffSet, DeltaOffset, Frequency, DeltaFreq, PulseDuration, DeltaPulsedur, LowPassCutOff, LowPassCutOffDelta, HighPassCutOff, HighPassCutOffDelta)
			Note WaveBuilderWave, "Segment "+num2str(i)+"= G-noise, properties:  SD = " + num2str(Amplitude)+ "  SD delta = "+num2str(DeltaAmp)+"  Low pass cut off = " + num2str(LowPassCutOff)+ "  Low pass cut off delta = " + num2str(LowPassCutOffDelta) + "  High pass cut off = " + num2str(HighPassCutOff)+ "  High pass cut off delta = " + num2str(HighPassCutOffDelta)
			break
		case 3:
			SinSegment(Amplitude, DeltaAmp, Duration, DeltaDur, OffSet, DeltaOffset, Frequency, DeltaFreq, PulseDuration, DeltaPulsedur, TauRise,TauDecay1,TauDecay2,TauDecay2Weight)
			Note WaveBuilderWave, "Segment "+num2str(i)+"= Sin wave, properties: Frequency = "+num2str(Frequency)+"  Frequency Delta = " + num2str(DeltaFreq)
			break
		case 4:
			SawToothSegment(Amplitude, DeltaAmp, Duration, DeltaDur, OffSet, DeltaOffset, Frequency, DeltaFreq, PulseDuration, DeltaPulsedur, TauRise,TauDecay1,TauDecay2,TauDecay2Weight)
			Note WaveBuilderWave, "Segment "+num2str(i)+"= Saw tooth, properties: Frequency = "+num2str(Frequency)+"  Frequency Delta = " + num2str(DeltaFreq)
			break
		case 5:
			SquarePulseTrainSegment(Amplitude, DeltaAmp, Duration, DeltaDur, OffSet, DeltaOffset, Frequency, DeltaFreq, PulseDuration, DeltaPulsedur, TauRise,TauDecay1,TauDecay2,TauDecay2Weight)
			Note WaveBuilderWave, "Segment "+num2str(i)+"= SPT, properties: Frequency = "+num2str(Frequency)+"  Frequency Delta = " + num2str(DeltaFreq)+ "  Pulse duration = " + num2str(PulseDuration) + "  Pulse duration delta = " + num2str(DeltaPulsedur) 
			break
		case 6:
			PSCSegment(Amplitude, DeltaAmp, Duration, DeltaDur, OffSet, DeltaOffset, Frequency, DeltaFreq, PulseDuration, DeltaPulsedur, TauRise,TauDecay1,TauDecay2,TauDecay2Weight)
			Note WaveBuilderWave, "Segment "+num2str(i)+"= PSC, properties: Tau rise = "+num2str(TauRise)+"  Tau Decay 1 = " + num2str(TauDecay1)+ "  Tau Decay 2 = " + num2str(TauDecay2) + "  Tau Decay 2 weight = " + num2str(TauDecay2Weight) 
			break
		case 7:
			if(waveexists($stringholder)==1)
				CustomWaveSegment(CustomOffset, NameOfWaveToBeDuplicated)
				Note WaveBuilderWave, "Segment "+num2str(i)+"= Custom wave, properties: Name = "+stringholder  
			else
				if(cmpstr(stringholder,"") != 0)// checks if - none - is the "wave" selected in the pull down menu
					print "Wave currently selected no longer exists. Please select a new wave from the pull down menu"
				endif
			endif
			break
	endswitch
	
	//Add segment to final wave
	//String WaveToAdd = "SegmentWave"
	
	
	Concatenate/np=0 {SegmentWave}, WaveBuilderWave
	
i+=1	
while(i<NumberOfSegments)
SetScale/P x 0,0.005,"ms", WaveBuilderWave
killvariables/z  ParameterHolder
killstrings/z StringHolder
killwaves/f/z SegmentWave
End


Function WaveBuilderParameterWaves()
Make /O /N =(24,100,8) WP //WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW
//Make /O /N =(24,100) WP1
//Make /O /N =(24,100) WP2
//Make /O /N =(24,100) WP3
//Make /O /N =(24,100) WP4
//Make /O /N =(24,100) WP5
//Make /O /N =(24,100) WP6
//Make /O /N =(24,100) WP6
//Make /O /N =(24,100) WP7
Make /T /O /N =(24,100) WP7T

Make/O/N = 100 SegmentWaveType
End

Function ParamToPanel(WaveParametersWave)//hhhhhhhhhhhhhhjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
variable WaveParametersWave
wave WP
string ControlName ="setvar_WaveBuilder_P"
variable rowNo=0

controlInfo setvar_WaveBuilder_SegmentEdit
variable columnNo=v_value

do
ControlName="setvar_WaveBuilder_P"+num2str(RowNo)
variable Parameter=WP[rowNo][ColumnNo][WaveParametersWave]
SetVariable $ControlName value=_Num:Parameter
RowNo+=1
while(RowNo<23)

End


//=====================================================================================
//FUNCTIONS THAT BUILD WAVE TYPES
//=====================================================================================
Function SquareSegment(Amplitude, DeltaAmp, Duration, DeltaDur, OffSet, DeltaOffset, Frequency, DeltaFreq, PulseDuration, DeltaPulsedur, TauRise,TauDecay1,TauDecay2,TauDecay2Weight)
	variable Amplitude, DeltaAmp, Duration, DeltaDur, OffSet, DeltaOffset, Frequency, DeltaFreq, PulseDuration, DeltaPulsedur, TauRise,TauDecay1,TauDecay2,TauDecay2Weight
	make/o/n=(Duration/0.005) SegmentWave=0
	SetScale/P x 0,0.005,"ms", SegmentWave
	SegmentWave=Amplitude
End

Function RampSegment(Amplitude, DeltaAmp, Duration, DeltaDur, OffSet, DeltaOffset, Frequency, DeltaFreq, PulseDuration, DeltaPulsedur, TauRise,TauDecay1,TauDecay2,TauDecay2Weight)
	variable Amplitude, DeltaAmp, Duration, DeltaDur, OffSet, DeltaOffset, Frequency, DeltaFreq, PulseDuration, DeltaPulsedur, TauRise,TauDecay1,TauDecay2,TauDecay2Weight
	Variable AmplitudeIncrement=Amplitude/(Duration/0.005)
	make/o/n=(Duration/0.005) SegmentWave
	SetScale/P x 0,0.005,"ms", SegmentWave
	SegmentWave=AmplitudeIncrement*p
	SegmentWave+=Offset
End
	
Function NoiseSegment(Amplitude, DeltaAmp, Duration, DeltaDur, OffSet, DeltaOffset, Frequency, DeltaFreq, PulseDuration, DeltaPulsedur, LowPassCutOff, LowPassCutOffDelta, HighPassCutOff, HighPassCutOffDelta)
	variable Amplitude, DeltaAmp, Duration, DeltaDur, OffSet, DeltaOffset, Frequency, DeltaFreq, PulseDuration, DeltaPulsedur, LowPassCutOff, LowPassCutOffDelta, HighPassCutOff, HighPassCutOffDelta
	make/o/n=(Duration/0.005) SegmentWave
	SetScale/P x 0,0.005,"ms", SegmentWave
	SegmentWave=gnoise(Amplitude)
	
	If(LowPassCutOff <= 100000 )//&& LowPassCutOffDelta != 0)	
		FilterFIR/DIM=0/LO={(LowPassCutOff/200000),(LowPassCutOff/200000),500}SegmentWave
	endif
	
	If(HighPassCutOff > 0  && HighPassCutOffDelta < 100000)
		FilterFIR/DIM=0/Hi={(HighPassCutOff/200000),(HighPassCutOff/200000),500}SegmentWave
	endif
	
	SegmentWave+=offset
End

Function SinSegment(Amplitude, DeltaAmp, Duration, DeltaDur, OffSet, DeltaOffset, Frequency, DeltaFreq, PulseDuration, DeltaPulsedur, TauRise,TauDecay1,TauDecay2,TauDecay2Weight)
	variable Amplitude, DeltaAmp, Duration, DeltaDur, OffSet, DeltaOffset, Frequency, DeltaFreq, PulseDuration, DeltaPulsedur, TauRise,TauDecay1,TauDecay2,TauDecay2Weight
	make/o/n=(Duration/0.005) SegmentWave
	SetScale/P x 0,0.005,"ms", SegmentWave
	//DataWave[][0]=1 * 3200 * sin(2 * Pi * 100000 * (5 / 1000000000) * x)
	SegmentWave=1 * Amplitude * sin(2 * Pi * (Frequency*1000) * (5 / 1000000000) * p)
	SegmentWave+=Offset
End

Function SawToothSegment(Amplitude, DeltaAmp, Duration, DeltaDur, OffSet, DeltaOffset, Frequency, DeltaFreq, PulseDuration, DeltaPulsedur, TauRise,TauDecay1,TauDecay2,TauDecay2Weight)
	variable Amplitude, DeltaAmp, Duration, DeltaDur, OffSet, DeltaOffset, Frequency, DeltaFreq, PulseDuration, DeltaPulsedur, TauRise,TauDecay1,TauDecay2,TauDecay2Weight
	make/o/n=(Duration/0.005) SegmentWave
	SetScale/P x 0,0.005,"ms", SegmentWave
	SegmentWave=1*Amplitude*sawtooth(2 * Pi * (Frequency*1000) * (5 / 1000000000) * p)
	SegmentWave+=Offset
End

Function SquarePulseTrainSegment(Amplitude, DeltaAmp, Duration, DeltaDur, OffSet, DeltaOffset, Frequency, DeltaFreq, PulseDuration, DeltaPulsedur, TauRise,TauDecay1,TauDecay2,TauDecay2Weight)
	variable Amplitude, DeltaAmp, Duration, DeltaDur, OffSet, DeltaOffset, Frequency, DeltaFreq, PulseDuration, DeltaPulsedur, TauRise,TauDecay1,TauDecay2,TauDecay2Weight
	//Variable InterPulseIntervalDuration
	Variable i = 1
	Variable PulseStartPoint=0
	Variable EndPoint
	Variable SegmentDuration
	Variable NumberOfPulses = Frequency*(Duration/1000)+1
	Variable TotalPulseTime=PulseDuration*NumberOfPulses
	Variable TotalBaselineTime=Duration-TotalPulseTime
	Variable NumberOfInterPulseIntervals=NumberOfPulses-1
	Variable InterPulseInterval=TotalBaselineTime/NumberOfInterPulseIntervals
	//poissonNoise
	make/o/n=(Duration/0.005) SegmentWave=0
	SetScale/P x 0,0.005,"ms", SegmentWave
	
	controlinfo/w=wavebuilder check_SPT_Poisson
	Variable Poisson = v_value
	EndPoint=NumberOfPulses
	Variable PoissonInterPulseInterval
	if (Poisson==0)
		do
		SegmentWave[(PulseStartPoint/0.005), ((PulseStartPoint/0.005)+(PulseDuration/0.005))]=Amplitude
			if(i+1==EndPoint)
			PulseStartPoint+=((InterPulseInterval+PulseDuration))
			else
			PulseStartPoint+=((InterPulseInterval+PulseDuration))
			endif
		i+=1
		while (i<Endpoint)
	endif
	
	
	if (Poisson==1)
		do
	
			PoissonInterPulseInterval=poissonNoise(InterpulseInterval)
			PulseStartPoint+=((PoissonInterPulseInterval))//+PulseDuration))
			if(((PulseStartPoint+PulseDuration)/0.005)<numpnts(segmentWave))
			SegmentWave[(PulseStartPoint/0.005), ((PulseStartPoint/0.005)+(PulseDuration/0.005))]=Amplitude
			endif
		while (((PulseStartPoint+PulseDuration)/0.005)<numpnts(segmentWave))
	endif	
	
	
	
	
	SegmentWave+=Offset

End

Function PSCSegment(Amplitude, DeltaAmp, Duration, DeltaDur, OffSet, DeltaOffset, Frequency, DeltaFreq, PulseDuration, DeltaPulsedur, TauRise,TauDecay1,TauDecay2,TauDecay2Weight)
variable Amplitude, DeltaAmp, Duration, DeltaDur, OffSet, DeltaOffset, Frequency, DeltaFreq, PulseDuration, DeltaPulsedur, TauRise,TauDecay1,TauDecay2,TauDecay2Weight
	make/o/n=(Duration/0.005) SegmentWave=0
	//doupdate
	SetScale /P x 0,0.005,"ms", SegmentWave
	variable first, last
	variable scale=1.2
	variable baseline,peak
	variable i
	
	//TauRise*=Scale
	//TauDecay1*=(1/Scale)
	//TauDecay2*=(1/Scale)
	
	
	TauRise=1/TauRise
	TauRise*=0.005
	TauDecay1=1/TauDecay1
	TauDecay1*=0.005
	TauDecay2=1/TauDecay2
	TauDecay2*=0.005
	
	SegmentWave[]=((1-exp(-TauRise*p)))*amplitude
	SegmentWave[]+=(exp(-TauDecay1*(p))*(amplitude*(1-TauDecay2Weight)))
	SegmentWave[]+=(exp(-TauDecay2*(p))*((amplitude*(TauDecay2Weight))))
	
	baseline=wavemin(SegmentWave)
	peak=wavemax(SegmentWave)
	SegmentWave*=Amplitude/(Peak-Baseline)
	
	baseline=wavemin(SegmentWave)
	SegmentWave-=baseline
	SegmentWave+=OffSet
End

//Proc PSCVarChange()//Nelson's PSC code
	Variable i, j, first, last, totaldur, max, scale, rise, decay1, decay2, err
	String notestr
	Vars2Wave("pscdur","duration",3)
	PauseUpdate
	totaldur=0
	i=0
	do
		totaldur+=duration[i]
		i+=1
	while(i<3)
	Redimension /N=(totaldur/sintpb) PSCDAC
	Setscale /P x, 0, sintpb, "ms", PSCDAC
	Note /K PSCDAC
	WriteWaveNote(PSCDAC,"WAVETYPE","pscdac")
	WriteWaveNote(PSCDAC,"TIME",time())
	WriteWaveNote(PSCDAC,"PSCAMP",num2str(pscamp))
	WriteWaveNote(PSCDAC,"PSCTAUR",num2str(psctaur))
	WriteWaveNote(PSCDAC,"PSCTAUD1",num2str(psctaud1))
	WriteWaveNote(PSCDAC,"PSCTAUD2",num2str(psctaud2))
	WriteWaveNote(PSCDAC,"WTTD2",num2str(wttd2))
	scale=1.37		// correct value is unique for each psc wave; adjusted in loop below
	first=0
	i=0
	do
		if (i==1)
			last=first+pscdur1
			PSCDAC(first,last)=pscamp*scale*-exp((pscdur0-x)/psctaur)
			PSCDAC(first,last)+=(1-wttd2)*pscamp*scale*exp((pscdur0-x)/psctaud1)
			PSCDAC(first,last)+=wttd2*pscamp*scale*exp((pscdur0-x)/psctaud2)
			do
				Wavestats /Q/R=(first,last) PSCDAC
				if (abs(V_min)<V_max)
					err=(V_max-pscamp)/pscamp
				else
					err=(V_min-pscamp)/pscamp
				endif
				PSCDAC=PSCDAC*(1-err)
			while(abs(err)>0.001)
		else
			last=first+duration[i]
			PSCDAC(first,last)=0
		endif
		first=last+sintpb
		sprintf notestr, "PSCDUR%d", i
		WriteWaveNote(PSCDAC,notestr,num2str(duration[i]))
		i+=1
	while(i<3)
	ResumeUpdate
	Duplicate /O PSCDAC NewDAC
End

Function CustomWaveSegment(CustomOffset, NameOfWaveToBeDuplicated)
variable CustomOffset
string NameOfWaveToBeDuplicated
string cmd
	make/o/n=1 SegmentWave
	
	if(stringmatch(NameOfWaveToBeDuplicated,"''")==1)
	SegmentWave+=CustomOffSet
	print "Custom wave needs to be selected from pull down menu"
	else
	sprintf cmd, "duplicate/o %s SegmentWave" NameOfWaveToBeDuplicated
	execute cmd
	SegmentWave+=CustomOffSet
	
	endif
End

//=====================================================================================

//=====================================================================================


