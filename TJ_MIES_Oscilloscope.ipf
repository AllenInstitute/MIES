#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Function ITCOscilloscope(WaveToPlot, panelTitle)
	wave WaveToPlot
	string panelTitle
	string NameOfWaveBeingPlotted = nameOfwave(WaveToPlot)
	print NameOfWaveBeingPlotted
	string oscilloscopeSubWindow = panelTitle + "#oscilloscope"
	ModifyGraph /w = $oscilloscopeSubWindow Live = 0
	variable i =  0
	string WavePath = HSU_DataFullFolderPathString(PanelTitle) + ":"
	wave TestPulseITC = $WavePath+"TestPulse:TestPulseITC", ITCChanConfigWave =$WavePath + "ITCChanConfigWave"
	wave ChannelClampMode = $WavePath + "ChannelClampMode"
	wave ResistanceWave = $WavePath + "TestPulse:Resistance"
	string ADChannelName= "AD"
	string ADChannelList = RefToPullDatafrom2DWave(0,0, 1, ITCChanConfigWave)
	string UnitWaveNote = note(ITCChanConfigWave)
	string Unit
	string ResistanceTraceName = "Resistance"
	RemoveTracesOnGraph(oscilloscopeSubWindow)
	
	variable YaxisLow, YaxisHigh, YaxisSpacing, Spacer
	YaxisSpacing = 1 / ((itemsinlist(ADChannelList)))
	Spacer = 0.015
	
	YaxisHigh = 1
	YaxisLow = YaxisHigh-YaxisSpacing + spacer
	
	for(i = 0; i < (itemsinlist(ADChannelList)); i += 1)
		
		ADChannelName ="AD"+stringfromlist(i, ADChannelList,";")
		appendtograph /W = $oscilloscopeSubWindow /L = $ADChannelName WaveToPlot[][(i+((NoOfChannelsSelected("da", "check", panelTitle))))]
		ModifyGraph/w=$oscilloscopeSubWindow axisEnab($ADChannelName)={YaxisLow,YaxisHigh}
		SetAxis /w = $oscilloscopeSubWindow /A =2 /N =2 $ADchannelName // this line should autoscale only the visible data; /N makes the autoscaling range larger
		Unit = stringfromlist(i + NoOfChannelsSelected("da", "check", panelTitle), UnitWaveNote, ";")// extracts unit from string list that contains units in same sequence as columns in the ITCDatawave
		Label /w = $oscilloscopeSubWindow $ADChannelName, ADChannelName + " (" + Unit + ")"
		ModifyGraph /w = $oscilloscopeSubWindow lblPosMode = 1
		
		if(cmpstr(NameOfWaveBeingPlotted, "TestPulseITC") == 0)
			appendtograph /W = $oscilloscopeSubWindow /R = $"Resistance" + num2str(i) ResistanceWave[][i]
			ModifyGraph /W = $oscilloscopeSubWindow noLabel($"Resistance" + num2str(i)) = 2, axThick($"Resistance" + num2str(i)) = 0
			ModifyGraph /W =$oscilloscopeSubWindow axisEnab($"Resistance" + num2str(i)) = {YaxisLow,YaxisHigh}
			if(i > 0)
				ResistanceTraceName = "Resistance#"+num2str(i)
			endif
			Tag /W = $oscilloscopeSubWindow /C /N = $"R" + num2str(i) /F = 0 /X = -15 /Y = -10 /B = 1 /L = 0 $ResistanceTraceName, 0,"\\OY \\Z10(Mohm)"

		endif

		YaxisHigh -= YaxisSpacing
		YaxisLow -= YaxisSpacing
	endfor
	ModifyGraph /w = $oscilloscopeSubWindow freePos=0
	SetAxis /w = $oscilloscopeSubWindow bottom 0, ((CalculateITCDataWaveLength(panelTitle) * (ITCMinSamplingInterval(panelTitle) / 1000)) / 4)
End
SetAxis/A=2 AD0
TextBox /W = $graphName /C /N = RunText "Run "+num2istr(runNumber)
prompt
extract
//=========================================================================================

Function/s FindValueInColumnof2Dwave(Value, Column, TwoDWave)//DA = 1, AD = 0, DO = 3
	variable Value, Column
	wave TwoDwave
	variable i = 0, a = 2
	string RowsThatContainValue = ""
	
	//duplicate/free/r=[][Column] TwoDwave, F
		do
			if(TwoDWave[i][Column] == Value)
			RowsThatContainValue += num2str(i) + ";"
			endif
		i += 1
		while (i < (DimSize(TwoDWave,0)))
	
	return RowsThatContainValue
 
End

//=========================================================================================
Function/s RefToPullDatafrom2DWave(Value,RefColumn, DataColumn, TwoDWave)// Returns the data from the data column based on matched values in the ref column
	wave TwoDWave// For ITCDataWave 0 (value) in Ref column = AD channel, 1 = DA channel,
	variable Value,RefColumn, DataColumn
	variable i = 0
	string Values = ""
	string RowList = FindValueInColumnof2Dwave(Value, RefColumn, TwoDWave)
	
	do
		values += (num2str(TwoDwave[str2num(stringfromlist(i,RowList,";"))][DataColumn])) + ";"
		i += 1
	while(i < (itemsinlist(RowList,";")))
	
	return Values
End
//=========================================================================================

Function RemoveTracesOnGraph(GraphName)
	string GraphName
	variable i = 0
	string cmd, WaveNameFromList
	string ListOfTracesOnGraph
	string Tracename
	
	ListOfTracesOnGraph = TraceNameList(GraphName, ";", 0 + 1)
	if(itemsinlist(ListOfTracesOnGraph,";") > 0)
	do
	TraceName = "\"#0\""
	sprintf cmd, "removefromgraph/w=%s $%s" GraphName, TraceName
	execute cmd
	i += 1
	while(i < (itemsinlist(ListOfTracesOnGraph,";")))
	endif
End

