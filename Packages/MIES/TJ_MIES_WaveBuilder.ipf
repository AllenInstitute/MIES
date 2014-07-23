#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Function WB_InitiateWaveBuilder()
	WB_MakeWaveBuilderFolders()
	DFREF saveDFR = GetDataFolderDFR()
	// SetDataFolder  root:MIES:WaveBuilder:Data
	SetDataFolder $Path_WaveBuilderDataFolder("")
	WB_WaveBuilderParameterWaves()
	String WaveBuilderPanel = "WaveBuilder()"
	execute WavebuilderPanel
	SetDataFolder saveDFR
End

Function WB_DisplaySetInPanel()
	variable i = 0
	
	DFREF saveDFR = GetDataFolderDFR()// creates a data folder reference that is later used to access the folder
	// SetDataFolder  root:MIES:WaveBuilder:Data
	SetDataFolder $Path_WaveBuilderDataFolder("")
	
	WB_RemoveAndKillTracesOnGraph()
	
	WB_MakeStimSet()
	string ListOfWavesToGraph
	
	string basename
	controlinfo setvar_WaveBuilder_baseName
	basename = s_value[0,15]
	
	variable SetNumber
	controlinfo setvar_WaveBuilder_SetNumber
	SetNumber = v_value
	
	controlInfo popup_WaveBuilder_OutputType
	string OutputWaveType = s_value
	string SearchString = "*" + basename + "*" + OutputWaveType + "_*" + num2str(SetNumber)
	ListOfWavesToGraph = wavelist(SearchString,";","")
	
	variable NoOfWavesInList = itemsinlist(ListOfWavesToGraph,";")
	
	do
		appendtograph /w = WaveBuilder#WaveBuilderGraph $stringfromlist(i,ListOfWavesToGraph,";")
			if(mod(i, 2) == 0) // odd numbered waves get made black
				ModifyGraph /w = WaveBuilder#WaveBuilderGraph rgb($stringfromlist(i, ListOfWavesToGraph,";")) = (13056,13056,13056)
			endif
		i += 1
	while(i < NoOfWavesInList)
	SetDataFolder saveDFR
End

Function WB_RemoveAndKillTracesOnGraph()
	variable i = 0
	string cmd, WaveNameFromList
	string ListOfTracesOnGraph
	
	DFREF saveDFR = GetDataFolderDFR()// creates a data folder reference that is later used to access the folder
	// SetDataFolder  root:MIES:WaveBuilder:Data
	SetDataFolder $Path_WaveBuilderDataFolder("")
	
	ListOfTracesOnGraph = TraceNameList("WaveBuilder#WaveBuilderGraph", ",", 0+1 )

	do
		removefromgraph /z /w = WaveBuilder#WaveBuilderGraph $stringfromlist(i,ListOfTracesOnGraph,",")
		//doupdate
		WaveNameFromList = stringfromlist(i,ListOfTracesOnGraph,",")
		if(strlen(WaveNameFromList) != 0)
			sprintf cmd, "killwaves/f/z  %s" WaveNameFromList
			execute cmd
		endif
		i += 1
	while(i < (itemsinlist(ListOfTracesOnGraph,",")))
	
	setdatafolder saveDFR
End

Function WB_MakeStimSet()
//	wave  WaveBuilderWave = root:MIES:wavebuilder:data:wavebuilderwave
	wave  WaveBuilderWave = $Path_WaveBuilderDataFolder("") + ":wavebuilderwave"
	variable i = 1
	Variable start = stopmstimer(-2)

	DFREF saveDFR = GetDataFolderDFR()// creates a data folder reference that is later used to access the folder
	// SetDataFolder  root:MIES:WaveBuilder:Data
	SetDataFolder $Path_WaveBuilderDataFolder("")
	
//	wave wp = root:MIES:WaveBuilder:Data:WP
	wave wp = $Path_WaveBuilderDataFolder("") + ":WP"
	duplicate/free wp, wpd// duplicating starting parameter waves so that they can be returned to start parameters at end of wave making

	controlinfo setvar_WaveBuilder_baseName
	string setbasename = s_value[0,15]
	
	controlinfo setvar_WaveBuilder_SetNumber
	variable setnumber = v_value
	
	controlinfo SetVar_WaveBuilder_StepCount
	variable NoOfWavesInSet = v_value
	
	string OutputWaveName
	
	do
		WB_MakeWaveBuilderWave()
		WB_AddDelta()
		controlInfo popup_WaveBuilder_OutputType
		string OutputWaveType = s_value
		
		OutputWaveName = num2str(i) + "_" + setbasename + "_" + OutputWaveType + "_" + num2str(setnumber)
		duplicate /o WaveBuilderWave, $OutputWaveName
		i += 1
	while(i <= NoOfWavesInSet)

	wp = wpd//
	setdatafolder saveDFR
	print "multithread took (ms):", (stopmstimer(-2) - start) / 1000
End

Function WB_AddDelta()//adds delta to appropriate parameter - relies on alternating sequence of parameter and delta's in parameter waves
String WPStringPath = Path_WaveBuilderDataFolder("") + ":WP"
// wave WP = root:MIES:WaveBuilder:Data:WP //
wave WP = $WPStringPath	
	variable i = 0
	
	do
		controlinfo check_WaveBuilder_exp
		if(v_value == 0)
			wp[i][][0] = wp[(i + 1)][q][0] + wp[i][q][0]//
			wp[i][][1] = wp[(i + 1)][q][1] +wp[i][q][1]
			wp[i][][2] = wp[(i + 1)][q][2] +wp[i][q][2]
			wp[i][][3] = wp[(i + 1)][q][3] +wp[i][q][3]
			wp[i][][4] = wp[(i + 1)][q][4] +wp[i][q][4]
			wp[i][][5] = wp[(i + 1)][q][5] +wp[i][q][5]
			wp[i][][6] = wp[(i + 1)][q][6] +wp[i][q][6]
			wp[i][][7] = wp[(i + 1)][q][7] +wp[i][q][7]
		else
			wp[i][][0] = (wp[(i + 1)][q][0]) +wp[i][q][0]
			wp[i][][1] = (wp[(i + 1)][q][1]) +wp[i][q][1]
			wp[i][][2] = (wp[(i + 1)][q][2]) +wp[i][q][2]
			wp[i][][3] = (wp[(i + 1)][q][3]) +wp[i][q][3]
			wp[i][][4] = (wp[(i + 1)][q][4]) +wp[i][q][4]
			wp[i][][5] = (wp[(i + 1)][q][5]) +wp[i][q][5]
			wp[i][][6] = (wp[(i + 1)][q][6]) +wp[i][q][6]
			wp[i][][7] = (wp[(i + 1)][q][7]) +wp[i][q][7]
		
			wp[i + 1][][0] += (wp[(i + 1)][q][0])
			wp[i + 1][][1] += (wp[(i + 1)][q][1])
			wp[i + 1][][2] += (wp[(i + 1)][q][2])
			wp[i + 1][][3] += (wp[(i + 1)][q][3])
			wp[i + 1][][4] += (wp[(i + 1)][q][4])
			wp[i + 1][][5] += (wp[(i + 1)][q][5])
			wp[i + 1][][6] += (wp[(i + 1)][q][6])
			wp[i + 1][][7] += (wp[(i + 1)][q][7])
		endif
		i += 2
	while(i < 30)
End


Function WB_MakeWaveBuilderWave()
	variable Amplitude, DeltaAmp, Duration, DeltaDur, OffSet, DeltaOffset, Frequency, DeltaFreq, PulseDuration, DeltaPulsedur, TauRise,TauDecay1,TauDecay2,TauDecay2Weight
	variable DeltaTauRise,DeltaTauDecay1,DeltaTauDecay2,DeltaTauDecay2Weight, CustomOffset, DeltaCustomOffset, LowPassCutOff, DeltaLowPassCutOff, HighPassCutOff, DeltaHighPassCutOff, EndFrequency, DeltaEndFrequency
	variable HighPassFiltCoefCount, DeltaHighPassFiltCoefCount, LowPassFiltCoefCount, DeltaLowPassFiltCoefCount, FIncrement
//	wave SegWvType=root:MIES:WaveBuilder:Data:SegWvType
	wave SegWvType= $Path_WaveBuilderDataFolder("") + ":SegWvType"
	//wave WaveBuilderWave=root:WaveBuilder:Data:WaveBuilderWave
	DFREF saveDFR = GetDataFolderDFR()// creates a data folder reference that is later used to access the folder
	// SetDataFolder  root:MIES:WaveBuilder:Data
	SetDataFolder $Path_WaveBuilderDataFolder("")
	make /o /n = 0 WaveBuilderWave = 0
	make /o /n = 0 SegmentWave = 0
	
	variable NumberOfSegments
	controlinfo SetVar_WaveBuilder_NoOfSegments
	NumberOfSegments = v_value
	variable i = 0
	string cmd, NameOfWaveToBeDuplicated, NameOfWaveToBeDuplicated_NOQUOT
	String ParameterWaveName
	
//	Variable /g  root:MIES:WaveBuilder:Data:ParameterHolder
	Variable /g  $Path_WaveBuilderDataFolder("") + ":ParameterHolder"
//	NVAR ParameterHolder = root:MIES:WaveBuilder:Data:ParameterHolder
	NVAR ParameterHolder = $Path_WaveBuilderDataFolder("") + ":ParameterHolder"
//	String /g root:MIES:WaveBuilder:Data:StringHolder
	String /g $Path_WaveBuilderDataFolder("") + ":StringHolder"
//	SVAR StringHolder = root:MIES:WaveBuilder:Data:StringHolder
	SVAR StringHolder = $Path_WaveBuilderDataFolder("") + ":StringHolder"
	do
		//Load in parameters
//		ParameterWaveName = "root:MIES:WaveBuilder:Data:WP"
		ParameterWaveName = Path_WaveBuilderDataFolder("") + ":WP"
	
		sprintf cmd, "ParameterHolder	= %s[%d][%d][%d]" ParameterWaveName, 0, i, SegWvType[i]
		Execute cmd
		Duration = ParameterHolder
		
		if(Duration < 0)
			Print "User input has generated a negative epoch duration. Please adjust input. Duration for epoch has been reset to 1 ms."
			Duration = 1
		endif
		
		sprintf cmd, "	ParameterHolder	= %s[%d][%d][%d]" ParameterWaveName, 1, i, SegWvType[i]
		Execute cmd
		DeltaDur = ParameterHolder
		
		sprintf cmd, "ParameterHolder	= %s[%d][%d][%d]" ParameterWaveName, 2, i, SegWvType[i]		
		Execute cmd
		Amplitude = ParameterHolder
		
		sprintf cmd, "ParameterHolder	= %s[%d][%d][%d]" ParameterWaveName, 3, i, SegWvType[i]
		Execute cmd
		DeltaAmp = ParameterHolder
		
		sprintf cmd, "ParameterHolder	= %s[%d][%d][%d]" ParameterWaveName, 4, i, SegWvType[i]
		Execute cmd
		Offset = ParameterHolder
		
		sprintf cmd, "	ParameterHolder	= %s[%d][%d][%d]" ParameterWaveName, 5, i, SegWvType[i]
		Execute cmd
		DeltaOffset = ParameterHolder
		
		sprintf cmd, "	ParameterHolder	= %s[%d][%d][%d]" ParameterWaveName, 6, i, SegWvType[i]
		Execute cmd
		Frequency = ParameterHolder
		
		sprintf cmd, "	ParameterHolder	= %s[%d][%d][%d]" ParameterWaveName, 7, i, SegWvType[i]
		Execute cmd
		DeltaFreq = ParameterHolder
		
		sprintf cmd, "	ParameterHolder	= %s[%d][%d][%d]" ParameterWaveName, 8, i, SegWvType[i]
		Execute cmd
		PulseDuration = ParameterHolder
		
		sprintf cmd, "ParameterHolder	= %s[%d][%d][%d]" ParameterWaveName, 9, i, SegWvType[i]
		Execute cmd
		DeltaPulsedur = ParameterHolder
	
		sprintf cmd, "	ParameterHolder	= %s[%d][%d][%d]" ParameterWaveName, 10, i, SegWvType[i]	//row spacing changes here to leave room for addition of delta parameters in the future - also allows for universal delta parameter addition		
		Execute cmd
		TauRise = ParameterHolder

		sprintf cmd, "	ParameterHolder	= %s[%d][%d][%d]" ParameterWaveName, 11, i, SegWvType[i]	//row spacing changes here to leave room for addition of delta parameters in the future - also allows for universal delta parameter addition		
		Execute cmd
		DeltaTauRise = ParameterHolder
				
		sprintf cmd, "	ParameterHolder	= %s[%d][%d][%d]" ParameterWaveName, 12, i, SegWvType[i]
		Execute cmd
		TauDecay1 = ParameterHolder
		
		sprintf cmd, "	ParameterHolder	= %s[%d][%d][%d]" ParameterWaveName, 13, i, SegWvType[i]
		Execute cmd
		DeltaTauDecay1 = ParameterHolder
		
		sprintf cmd, "	ParameterHolder	= %s[%d][%d][%d]" ParameterWaveName, 14, i, SegWvType[i]
		Execute cmd
		TauDecay2 = ParameterHolder

		sprintf cmd, "	ParameterHolder	= %s[%d][%d][%d]" ParameterWaveName, 15, i, SegWvType[i]
		Execute cmd
		DeltaTauDecay2 = ParameterHolder
		
		sprintf cmd, "ParameterHolder = %s[%d][%d][%d]" ParameterWaveName, 16, i, SegWvType[i]
		Execute cmd
		TauDecay2Weight = ParameterHolder
		
		sprintf cmd, "ParameterHolder = %s[%d][%d][%d]" ParameterWaveName, 17, i, SegWvType[i]
		Execute cmd
		DeltaTauDecay2Weight = ParameterHolder
		
		sprintf cmd, "ParameterHolder = %s[%d][%d][%d]" ParameterWaveName, 18, i, SegWvType[i]
		Execute cmd
		CustomOffset = ParameterHolder
		
		sprintf cmd, "ParameterHolder = %s[%d][%d][%d]" ParameterWaveName, 19, i, SegWvType[i]
		Execute cmd
		DeltaCustomOffset = ParameterHolder
		
//		sprintf cmd, "StringHolder = %s[%d][%d]"  "root:MIES:WaveBuilder:Data:WPT", 0, i// passes name of custom wave from a text wave
		sprintf cmd, "StringHolder = %s:WPT[%d][%d]"  Path_WaveBuilderDataFolder(""), 0, i// passes name of custom wave from a text wave
		Execute cmd
		NameOfWaveToBeDuplicated = "'" + StringHolder + "'"
		
		sprintf cmd, "ParameterHolder = %s[%d][%d][%d]" ParameterWaveName, 20, i, SegWvType[i]
		Execute cmd
		LowPassCutOff = ParameterHolder	
		
		sprintf cmd, "ParameterHolder = %s[%d][%d][%d]" ParameterWaveName, 21, i, SegWvType[i]
		Execute cmd
		DeltaLowPassCutOff = ParameterHolder	
	
		sprintf cmd, "ParameterHolder = %s[%d][%d][%d]" ParameterWaveName, 22, i, SegWvType[i]
		Execute cmd
		HighPassCutOff = ParameterHolder
			
		sprintf cmd, "ParameterHolder = %s[%d][%d][%d]" ParameterWaveName, 23, i, SegWvType[i]
		Execute cmd
		DeltaHighPassCutOff = ParameterHolder	
		
		sprintf cmd, "ParameterHolder = %s[%d][%d][%d]" ParameterWaveName, 24, i, SegWvType[i]
		Execute cmd
		EndFrequency = ParameterHolder	
			
		sprintf cmd, "ParameterHolder = %s[%d][%d][%d]" ParameterWaveName, 25, i, SegWvType[i]
		Execute cmd
		DeltaEndFrequency = ParameterHolder	
		
		sprintf cmd, "ParameterHolder = %s[%d][%d][%d]" ParameterWaveName, 26, i, SegWvType[i]
		Execute cmd
		HighPassFiltCoefCount = ParameterHolder	
		
		sprintf cmd, "ParameterHolder = %s[%d][%d][%d]" ParameterWaveName, 27, i, SegWvType[i]
		Execute cmd
		DeltaHighPassFiltCoefCount = ParameterHolder
		
		sprintf cmd, "ParameterHolder = %s[%d][%d][%d]" ParameterWaveName, 28, i, SegWvType[i]
		Execute cmd
		LowPassFiltCoefCount = ParameterHolder	
		
		sprintf cmd, "ParameterHolder = %s[%d][%d][%d]" ParameterWaveName, 29, i, SegWvType[i]
		Execute cmd
		DeltaLowPassFiltCoefCount = ParameterHolder
		
		sprintf cmd, "ParameterHolder = %s[%d][%d][%d]" ParameterWaveName, 30, i, SegWvType[i]
		Execute cmd
		FIncrement = ParameterHolder	
		
		//Make correct wave segment with above parameters
		switch(SegWvType[i])												// numeric switch
			case 0:
				WB_SquareSegment(Amplitude, DeltaAmp, Duration, DeltaDur, OffSet, DeltaOffset, Frequency, DeltaFreq, PulseDuration, DeltaPulsedur, TauRise,TauDecay1,TauDecay2,TauDecay2Weight)
				Note WaveBuilderWave, "Epoch " + num2str(i) + " = Square pulse , properties: Amplitude = " + num2str(Amplitude) + "  Delta amplitude = " + num2str(DeltaAmp) + "  Duration = " + num2str(Duration) + "  Delta duration = " + num2str(DeltaDur) + "  Offset = " + num2str(Offset) + "  Delta offset = " + num2str(DeltaOffset)
				break
			case 1:
				WB_RampSegment(Amplitude, DeltaAmp, Duration, DeltaDur, OffSet, DeltaOffset, Frequency, DeltaFreq, PulseDuration, DeltaPulsedur, TauRise,TauDecay1,TauDecay2,TauDecay2Weight)
				Note WaveBuilderWave, "Epoch " + num2str(i) + " = Ramp, properties: Amplitude = " + num2str(Amplitude) + "  Delta amplitude = " + num2str(DeltaAmp) + "  Duration = " + num2str(Duration) + "  Delta duration = " + num2str(DeltaDur) + "  Offset = " + num2str(Offset) + "  Delta offset = " + num2str(DeltaOffset)
				break
			case 2:
				WB_NoiseSegment(Amplitude, Duration, OffSet, LowPassCutOff, LowPassFiltCoefCount, HighPassCutOff, HighPassFiltCoefCount, FIncrement)
				Note WaveBuilderWave, "Epoch " + num2str(i) + " = G-noise, properties:  SD = " + num2str(Amplitude) + "  SD delta = "+num2str(DeltaAmp) + "  Low pass cut off = " + num2str(LowPassCutOff) + "  Low pass cut off delta = " + num2str(DeltaLowPassCutOff) + "  High pass cut off = " + num2str(HighPassCutOff)+ "  High pass cut off delta = " + num2str(DeltaHighPassCutOff)
				Note/NOCR WaveBuilderWave, "  Offset = " + num2str(Offset) + "  Delta offset = " + num2str(DeltaOffset)
				break
			case 3:
				WB_SinSegment(Amplitude, DeltaAmp, Duration, DeltaDur, OffSet, DeltaOffset, Frequency, DeltaFreq, PulseDuration, DeltaPulsedur, TauRise,TauDecay1,TauDecay2,TauDecay2Weight, EndFrequency, DeltaEndFrequency)
				Note WaveBuilderWave, "Epoch "+num2str(i)+"= Sin wave, properties: Frequency = "+num2str(Frequency)+"  Frequency Delta = " + num2str(DeltaFreq)+ "EndFrequency = "+num2str(EndFrequency)+"  EndFrequency Delta = " + num2str(DeltaEndFrequency)
				break
			case 4:
				WB_SawToothSegment(Amplitude, DeltaAmp, Duration, DeltaDur, OffSet, DeltaOffset, Frequency, DeltaFreq, PulseDuration, DeltaPulsedur, TauRise,TauDecay1,TauDecay2,TauDecay2Weight)
				Note WaveBuilderWave, "Epoch " + num2str(i) + " = Saw tooth, properties: Frequency = " + num2str(Frequency) + "  Frequency Delta = " + num2str(DeltaFreq)
				Note/NOCR WaveBuilderWave, "  Offset = " + num2str(Offset) + "  Delta offset = " + num2str(DeltaOffset)
				break
			case 5:
				WB_SquarePulseTrainSegment(Amplitude, DeltaAmp, Duration, DeltaDur, OffSet, DeltaOffset, Frequency, DeltaFreq, PulseDuration, DeltaPulsedur, TauRise,TauDecay1,TauDecay2,TauDecay2Weight)
				Note WaveBuilderWave, "Epoch " + num2str(i) + " = SPT, properties: Frequency = "+num2str(Frequency) + "  Frequency Delta = " + num2str(DeltaFreq) + "  Pulse duration = " + num2str(PulseDuration) + "  Pulse duration delta = " + num2str(DeltaPulsedur) 
				Note/NOCR WaveBuilderWave, "  Offset = " + num2str(Offset) + "  Delta offset = " + num2str(DeltaOffset)
				break
			case 6:
				WB_PSCSegment(Amplitude, DeltaAmp, Duration, DeltaDur, OffSet, DeltaOffset, Frequency, DeltaFreq, PulseDuration, DeltaPulsedur, TauRise,TauDecay1,TauDecay2,TauDecay2Weight)
				Note WaveBuilderWave, "Epoch " + num2str(i) + " = PSC, properties: Tau rise = " + num2str(TauRise) + "  Tau Decay 1 = " + num2str(TauDecay1) + "  Tau Decay 2 = " + num2str(TauDecay2) + "  Tau Decay 2 weight = " + num2str(TauDecay2Weight) 
				Note/NOCR WaveBuilderWave, "  Offset = " + num2str(Offset) + "  Delta offset = " + num2str(DeltaOffset)
				break
			case 7:
				controlinfo group_WaveBuilder_FolderPath
				string customWaveName = s_value + stringholder
				
				if(waveexists($customWaveName) == 1)
					WB_CustomWaveSegment(CustomOffset, NameOfWaveToBeDuplicated)
					Note WaveBuilderWave, "Epoch " + num2str(i) + " = Custom wave, properties: Name = " + stringholder  
					Note /NOCR WaveBuilderWave, "  Offset = " + num2str(Offset) + "  Delta offset = " + num2str(DeltaOffset)
				else
					if(cmpstr(stringholder, "") != 0)// checks if - none - is the "wave" selected in the pull down menu
						print "Wave currently selected no longer exists. Please select a new wave from the pull down menu"
					endif
				endif
				break
		endswitch
		
		Concatenate /np = 0 {SegmentWave}, WaveBuilderWave
		
		i += 1	
	while(i < NumberOfSegments)
	SetScale /P x 0, 0.005, "ms", WaveBuilderWave
	killvariables /z  ParameterHolder
	killstrings /z StringHolder
	killwaves /f /z SegmentWave
	setdatafolder saveDFR
End

Function WB_WaveBuilderParameterWaves()//generates waves neccessary to run wavebuilder panel
	DFREF saveDFR = GetDataFolderDFR()// creates a data folder reference that is later used to access the folder
	// SetDataFolder  root:MIES:WaveBuilder:Data
	SetDataFolder $Path_WaveBuilderDataFolder("")
	Make /O /N = 100 WaveBuilderWave
	Make /O /N = (31,100,8) WP //WP=Wave Parameters
	Make /T /O /N = (31,100) WPT//WPT=Wave Parameters Text (wave)
	Make/O/N = 102 SegWvType//Wave that stores the wave type used in each epoch
	WP[20][][2] = 10001//sets low pass filter to off (off value is related to samplling frequency)
	WP[26][][2] = 500//sets coefficent count for low pass filter to a reasonable and legal Number
	WP[28][][2] = 500//sets coefficent count for high pass filter to a reasonable and legal Number
	SetDataFolder saveDFR
End

Function WB_MakeWaveBuilderFolders()//makes folders used by wavebuilder panel
	//DataFolderExists(folderNameStr ) -
//	NewDataFolder /O root:MIES:WaveBuilder
//	NewDataFolder /O root:MIES:WaveBuilder:Data
//	NewDataFolder /O root:MIES:WaveBuilder:SavedStimulusSetParameters
//	NewDataFolder /O root:MIES:WaveBuilder:SavedStimulusSetParameters:DA
//	NewDataFolder /O root:MIES:WaveBuilder:SavedStimulusSetParameters:TTL
//	NewDataFolder /O root:MIES:WaveBuilder:SavedStimulusSets
//	NewDataFolder /O root:MIES:WaveBuilder:SavedStimulusSets:DA
//	NewDataFolder /O root:MIES:WaveBuilder:SavedStimulusSets:TTL
	NewDataFolder /O $Path_WaveBuilderFolder("")
	NewDataFolder /O $Path_WaveBuilderDataFolder("")
	NewDataFolder /O $Path_WBSvdStimSetParamFolder("")
	NewDataFolder /O $Path_WBSvdStimSetParamDAFolder("")
	NewDataFolder /O $Path_WBSvdStimSetParamTTLFolder("")
	NewDataFolder /O $Path_WBSvdStimSetFolder("")
	NewDataFolder /O $Path_WBSvdStimSetDAFolder("")
	NewDataFolder /O $Path_WBSvdStimSetTTLFolder("")
End


Function WB_ParamToPanel(WaveParametersWave)//passes the data from the WP wave to the panel
	variable WaveParametersWave
//	wave WP = root:MIES:wavebuilder:data:wp
	wave WP = $Path_WaveBuilderDataFolder("") + ":WP"
	string ControlName = "setvar_WaveBuilder_P"
	variable rowNo = 0
	
	controlInfo setvar_WaveBuilder_SegmentEdit
	variable columnNo = v_value
	
	do
		ControlName = "setvar_WaveBuilder_P"+num2str(RowNo)
		variable Parameter = WP[rowNo][ColumnNo][WaveParametersWave]
		SetVariable $ControlName value = _Num:Parameter
		RowNo += 1
	while(RowNo < 23)
End

//=====================================================================================
//FUNCTIONS THAT BUILD WAVE TYPES
//=====================================================================================
Function WB_SquareSegment(Amplitude, DeltaAmp, Duration, DeltaDur, OffSet, DeltaOffset, Frequency, DeltaFreq, PulseDuration, DeltaPulsedur, TauRise,TauDecay1,TauDecay2,TauDecay2Weight)
	variable Amplitude, DeltaAmp, Duration, DeltaDur, OffSet, DeltaOffset, Frequency, DeltaFreq, PulseDuration, DeltaPulsedur, TauRise,TauDecay1,TauDecay2,TauDecay2Weight
	make /o /n = (Duration / 0.005) SegmentWave = 0
	SetScale /P x 0,0.005,"ms", SegmentWave
	SegmentWave = Amplitude
End

Threadsafe Function WB_RampSegment(Amplitude, DeltaAmp, Duration, DeltaDur, OffSet, DeltaOffset, Frequency, DeltaFreq, PulseDuration, DeltaPulsedur, TauRise,TauDecay1,TauDecay2,TauDecay2Weight)
	variable Amplitude, DeltaAmp, Duration, DeltaDur, OffSet, DeltaOffset, Frequency, DeltaFreq, PulseDuration, DeltaPulsedur, TauRise,TauDecay1,TauDecay2,TauDecay2Weight
	Variable AmplitudeIncrement=Amplitude/(Duration/0.005)
	make /o /n = (Duration / 0.005) SegmentWave
	SetScale /P x 0,0.005, "ms", SegmentWave
	MultiThread SegmentWave = AmplitudeIncrement * p
	SegmentWave += Offset
End
	
Function WB_NoiseSegment(Amplitude, Duration, OffSet, LowPassCutOff, LowPassFiltCoefCount HighPassCutOff,HighPassFiltCoefCount, FIncrement)
	variable Amplitude, Duration, OffSet, LowPassCutOff, LowPassFiltCoefCount, HighPassCutOff, HighPassFiltCoefCount, FIncrement
	make /o /n = (Duration / 0.005) SegmentWave
	SetScale /P x 0,0.005, "ms", SegmentWave
	variable brownCheck, pinkCheck
	
	controlinfo /w = wavebuilder check_Noise_Pink
	pinkCheck = v_value
	
	controlinfo /w = wavebuilder check_Noise_Brown
	brownCheck = v_value	
	
	if(brownCheck == 0 && pinkCheck == 0)
		make /o /n = (Duration / 0.005) SegmentWave
		SetScale /P x 0,0.005, "ms", SegmentWave
		SegmentWave = gnoise(Amplitude)// MultiThread didn't impact processing time for gnoise
		if(duration > 0)
			If(LowPassCutOff <= 100000 && LowPassCutOff != 0)	
				 FilterFIR /DIM = 0 /LO = {(LowPassCutOff / 200000), (LowPassCutOff / 200000), LowPassFiltCoefCount}SegmentWave
			endif
			
			if(HighPassCutOff > 0 && HighPassCutOff<100000)//  && HighPassCutOffDelta < 100000)
				FilterFIR /DIM = 0 /Hi = {(HighPassCutOff/200000), (HighPassCutOff/200000), HighPassFiltCoefCount}SegmentWave
			endif
		endif
	endif
	
	variable PinkOrBrown
	if(pinkCheck == 1)
		PinkOrBrown = 0
		WB_PinkAndBrownNoise(Amplitude, Duration, LowPassCutOff, HighPassCutOff, Fincrement, PinkOrBrown)
	endif
	
	if(brownCheck == 1)
		PinkOrBrown = 1
		WB_PinkAndBrownNoise(Amplitude, Duration, LowPassCutOff, HighPassCutOff, Fincrement, PinkOrBrown)
	endif
		
	SegmentWave += offset
End

Function WB_SinSegment(Amplitude, DeltaAmp, Duration, DeltaDur, OffSet, DeltaOffset, Frequency, DeltaFreq, PulseDuration, DeltaPulsedur, TauRise,TauDecay1,TauDecay2,TauDecay2Weight, EndFrequency, EndFrequencyDelta)
	variable Amplitude, DeltaAmp, Duration, DeltaDur, OffSet, DeltaOffset, Frequency, DeltaFreq, PulseDuration, DeltaPulsedur, TauRise,TauDecay1,TauDecay2,TauDecay2Weight, EndFrequency, EndFrequencyDelta
	variable k0, k1, k2, k3 
	string cmd
	make /o /n = (Duration / 0.005) SegmentWave
	SetScale /P x 0,0.005, "ms", SegmentWave
	controlinfo check_Sin_Chirp
	if(v_value == 0)
		MultiThread SegmentWave = Amplitude * sin(2 * Pi * (Frequency * 1000) * (5 / 1000000000) * p)
		SegmentWave += Offset
	else
		 k0 = ln(frequency / 1000)
		 k1 = (ln(endFrequency / 1000) - k0) / (duration)
		 k2 = 2 * pi * e^k0 / k1
		 k3 = mod(k2, 2 * pi)		// LH040117: start on rising edge of sin and don't try to round.
		 MultiThread SegmentWave = Amplitude * sin(k2 * e^(k1 * x) - k3)
		 SegmentWave += Offset
	endif
End

Function WB_SawToothSegment(Amplitude, DeltaAmp, Duration, DeltaDur, OffSet, DeltaOffset, Frequency, DeltaFreq, PulseDuration, DeltaPulsedur, TauRise,TauDecay1,TauDecay2,TauDecay2Weight)
	variable Amplitude, DeltaAmp, Duration, DeltaDur, OffSet, DeltaOffset, Frequency, DeltaFreq, PulseDuration, DeltaPulsedur, TauRise,TauDecay1,TauDecay2,TauDecay2Weight
	make /o /n = (Duration / 0.005) SegmentWave
	SetScale /P x 0,0.005,"ms", SegmentWave
	SegmentWave = 1 * Amplitude * sawtooth(2 * Pi * (Frequency * 1000) * (5 / 1000000000) * p)
	SegmentWave += Offset
End

Function WB_SquarePulseTrainSegment(Amplitude, DeltaAmp, Duration, DeltaDur, OffSet, DeltaOffset, Frequency, DeltaFreq, PulseDuration, DeltaPulsedur, TauRise,TauDecay1,TauDecay2,TauDecay2Weight)
	variable Amplitude, DeltaAmp, Duration, DeltaDur, OffSet, DeltaOffset, Frequency, DeltaFreq, PulseDuration, DeltaPulsedur, TauRise,TauDecay1,TauDecay2,TauDecay2Weight
	//Variable InterPulseIntervalDuration
	Variable i = 1
	Variable PulseStartTime = 0
	Variable EndPoint
	Variable SegmentDuration
	Variable NumberOfPulses = Frequency * (Duration / 1000)//+1
	Variable TotalPulseTime = PulseDuration * NumberOfPulses
	Variable TotalBaselineTime = Duration - TotalPulseTime
	Variable NumberOfInterPulseIntervals = NumberOfPulses - 1
	Variable InterPulseInterval = TotalBaselineTime/NumberOfInterPulseIntervals
	Variable PoissonIntPulseInt
	//poissonNoise
	make /o /n = (Duration / 0.005) SegmentWave = 0
	SetScale /P x 0,0.005, "ms", SegmentWave
	
	controlinfo /w = wavebuilder check_SPT_Poisson
	Variable Poisson = v_value
	EndPoint = NumberOfPulses
	
	if (Poisson == 0)
		do
		SegmentWave[(PulseStartTime / 0.005), ((PulseStartTime / 0.005) + (PulseDuration / 0.005))] = Amplitude
			if(i + 1 == EndPoint)
				PulseStartTime += ((InterPulseInterval + PulseDuration))
			else
				PulseStartTime += ((InterPulseInterval + PulseDuration))
			endif
		i += 1
		while (i < Endpoint)
	endif
	
	//print InterpulseInterval
	if (Poisson == 1)
		do
			PoissonIntPulseInt = (-ln(abs(enoise(1))) / Frequency) * 1000
			PulseStartTime += (PoissonIntPulseInt)
			if(((PulseStartTime + PulseDuration) / 0.005) < numpnts(segmentWave))
				SegmentWave[(PulseStartTime / 0.005), ((PulseStartTime / 0.005) + (PulseDuration / 0.005))] = Amplitude
			endif
		while (((PulseStartTime + PulseDuration) / 0.005) < numpnts(segmentWave))
	endif	
	
	SegmentWave += Offset

End

Function WB_PSCSegment(Amplitude, DeltaAmp, Duration, DeltaDur, OffSet, DeltaOffset, Frequency, DeltaFreq, PulseDuration, DeltaPulsedur, TauRise,TauDecay1,TauDecay2,TauDecay2Weight)
variable Amplitude, DeltaAmp, Duration, DeltaDur, OffSet, DeltaOffset, Frequency, DeltaFreq, PulseDuration, DeltaPulsedur, TauRise,TauDecay1,TauDecay2,TauDecay2Weight
	make /o /n = (Duration / 0.005) SegmentWave = 0
	//doupdate
	SetScale /P x 0,0.005, "ms", SegmentWave
	variable first, last
	variable scale = 1.2
	variable baseline, peak
	variable i
	
	TauRise = 1 / TauRise
	TauRise *= 0.005
	TauDecay1 = 1 / TauDecay1
	TauDecay1 *= 0.005
	TauDecay2 = 1 / TauDecay2
	TauDecay2 *= 0.005
	
	MultiThread SegmentWave[] = ((1 - exp( - TauRise * p))) * amplitude
	MultiThread SegmentWave[] += (exp( - TauDecay1 * (p)) * (amplitude * (1 - TauDecay2Weight)))
	MultiThread SegmentWave[] += (exp( - TauDecay2 * (p)) * ((amplitude * (TauDecay2Weight))))
	
	baseline = wavemin(SegmentWave)
	peak = wavemax(SegmentWave)
	SegmentWave *= Amplitude/(Peak-Baseline)
	
	baseline = wavemin(SegmentWave)
	SegmentWave -= baseline
	SegmentWave += OffSet
End

Function WB_CustomWaveSegment(CustomOffset, NameOfWaveToBeDuplicated)
	variable CustomOffset
	string NameOfWaveToBeDuplicated
	string cmd
	
	controlinfo group_WaveBuilder_FolderPath
	NameOfWaveToBeDuplicated = s_value+NameOfWaveToBeDuplicated
	
	DFREF saveDFR = GetDataFolderDFR()// creates a data folder reference that is later used to access the folder
	// SetDataFolder  root:MIES:WaveBuilder:Data
	SetDataFolder $Path_WaveBuilderDataFolder("")
	
	make /o /n = 1 SegmentWave
	
	if(stringmatch(NameOfWaveToBeDuplicated, "''") == 1)
		SegmentWave += CustomOffSet
		print "Custom wave needs to be selected from pull down menu"
	else
		
		sprintf cmd, "duplicate/o %s SegmentWave" NameOfWaveToBeDuplicated
		execute cmd
		SegmentWave += CustomOffSet
	endif
	setDataFolder saveDFR
End


Threadsafe Function WB_PinkAndBrownNoise(Amplitude, Duration, LowPassCutOff, HighPassCutOff, FrequencyIncrement, PinkOrBrown)// Pink = 0, Brown = 1
		variable Amplitude, Duration, LowPassCutOff, HighPassCutOff, frequencyIncrement, PinkOrBrown
		variable phase = (abs(enoise(2)) * Pi)
		variable NumberOfBuildWaves = floor((LowPassCutOff - HighPassCutOff) / FrequencyIncrement)
		make /free /n = (Duration / 0.005, NumberOfBuildWaves) BuildWave
		SetScale /P x 0,0.005,"ms", BuildWave
		variable Frequency = HighPassCutOff
		variable i = 0
		variable localAmplitude
		//make /free /n = (NumberOfBuildWaves) PhaseWave
		//Multithread PhaseWave[] = ((abs(enoise(2))) * Pi)
		do
			phase = ((abs(enoise(2))) * Pi) // random phase generator
			if(PinkOrBrown == 0)
				localAmplitude = 1 / Frequency
			else
				localAmplitude = 1 / (Frequency ^ .5)
			endif
			
			MultiThread BuildWave[][i] = localAmplitude * sin( Pi * Frequency * 1e-05 * p + phase) //  factoring out Pi * 1e-05 actually makes it a tiny bit slower
			//MultiThread BuildWave[][i] = localAmplitude * sin(2 * Pi * (Frequency*1000) * (5 / 1000000000) * p + phase) // Multithread of sin funciton is the BOMB!!
			Frequency += FrequencyIncrement
			i += 1
		while (i < NumberOfBuildWaves)
		
		MatrixOp /o /NTHR = 0   SegmentWave = sumRows(BuildWave)
		
		SetScale /P x 0, 0.005,"ms", SegmentWave
		//SegmentWave /= NumberOfBuildWaves
		
		Wavestats /q SegmentWave
		variable scalefactor = Amplitude / V_sdev // (V_max - V_min)
		SegmentWave *= ScaleFactor
End

//=====================================================================================
//=====================================================================================

//Function /t WaveBuilderFolderPath()
//string FolderPath = "root:MIES:WaveBuilder"
//return FolderPath
//End