#pragma rtGlobals=3		// Use modern global access method and strict wave access.


Function DB_ButtonProc_LockDBtoDevice(ctrlName) : ButtonControl
	String ctrlName
	getwindow kwTopWin wtitle
	DB_LockDBPanel(s_value)
End
//==============================================================================================================================

Function DB_LockDBPanel(panelTitle)
	string panelTitle
	controlinfo /w=$panelTitle popup_DB_lockedDevices
	if(v_value>1)// makes sure "- none -" isn't selected
		dowindow /W = $panelTitle /C $s_value+"_DB"
		SetWindow $s_value+"_DB", userdata(DataFolderPath)=HSU_DataFullFolderPathString(s_value)
	else
		print "Please choose a device assingment for the data browser"
	endif
End


	getwindow kwTopWin wtitle
	dowindow /W = $panelTitle /C $DeviceType + "_Dev_" + num2str(DeviceNo)
	popup_DB_lockedDevices
	HSU_DataFolderPathDisplay(PanelTitle)
	getuserdata
	SetWindwo winName, userdata(DataFolderPath)=HSU_DataFolderPathDisplay(PanelTitle)
//==============================================================================================================================
Function DB_LastSweepAcquired(PanelTitle)// returns last sweep acquired 
	string PanelTitle
	string ListOfAcquiredWaves
	variable LastSweepAcquired
	
	string DataPath=getuserdata(panelTitle, "", "DataFolderPath")+":Data"
	DFREF saveDFR = GetDataFolderDFR()
	setDataFolder $DataPath
	
	ListOfAcquiredWaves=wavelist("sweep_*",";","MINCOLS:2")
	LastSweepAcquired=(itemsinlist(ListOfAcquiredWaves,";"))-1
	valdisplay valdisp_DataBrowser_LastSweep win=$PanelTitle, value=_num:LastSweepAcquired
	
	SetDataFolder saveDFR
	
	return LastSweepAcquired
End

//==============================================================================================================================

Function DB_PlotDataBrowserWave(panelTitle, SweepName) // Pass in sweep name with path included
	string panelTitle
	wave SweepName
	controlinfo check_DataBrowser_Overlay
	if(v_value==0)
		DB_TilePlotForDataBrowser(panelTitle, SweepName)
		TitleBox ListBox_DataBrowser_NoteDisplay title=note(SweepName)
	else
		//OverlayPlotForDataBrowser(SweepName)
	endif

End
//==============================================================================================================================

Function DB_TilePlotForDataBrowser(panelTitle, SweepName) // Pass in sweep name with path included
	string panelTitle
	wave Sweepname
	string DataPath = getuserdata(panelTitle, "", "DataFolderPath")+":Data"
	wave ConfigWaveName = $DataPath + ":Config_" + nameofwave(SweepName)
	string ADChannelList = RefToPullDatafrom2DWave(0,0, 1, ConfigWaveName)
	string DAChannelList = RefToPullDatafrom2DWave(1,0, 1, ConfigWaveName)
	variable NumberOfDAchannels = itemsinlist(DAChannelList)
	variable NumberOfADchannels = itemsinlist(ADChannelList)
	variable DACounter, ADCounter, i
	variable DisplayDAChan
	variable ADYaxisLow, ADYaxisHigh, ADYaxisSpacing, DAYaxisSpacing, Spacer,DAYaxisLow, DAYaxisHigh, YaxisHigh, YaxisLow
	string AxisName, NewTraceName
	
	controlinfo check_DataBrowser_SweepOverlay
	if(v_value == 0)
		DB_RemoveAndKillWavesOnGraph(panelTitle, panelTitle+"#DataBrowserGraph")
	endif
	
	ControlInfo check_DataBrowser_DisplayDAchan// Check to see if user wants DA channels displayed in DataBrowser graph
	DisplayDAChan = v_value
	if(DisplayDAChan == 1 )
		ADYaxisSpacing = (0.8 / (NumberOfADchannels))
		DAYaxisSpacing = (0.2 / (NumberOfDAchannels))
	else
		ADYaxisSpacing = 1 / (NumberOfADchannels)
	endif
	//Tiledplot
	Spacer = 0.03
	
	
	if(DisplayDAChan == 1)
		DAYaxisHigh = 1
		DAYaxisLow = DAYaxisHigh-DAYaxisSpacing+spacer
		ADYaxisHigh = DAYaxisLow-spacer
		ADYaxisLow = ADYaxisHigh-ADYaxisSpacing+spacer
	else
		ADYaxisHigh = 1
		ADYaxisLow = 1 - ADYaxisSpacing+spacer
	endif
	
	
	do////USE CODE IN THIS LOOP TO ALLOW FOR HEADSTAGE ASSOCIATING TO BE PLOTTED
		if(DisplayDAChan == 1)
			//DA wave to plot
			if(i < NumberOfDAchannels)
				YaxisHigh = DAYaxisHigh
				YaxisLow = DAYaxisLow
				
				AxisName = "DA"+stringfromlist(i, DAChannelList,";")
				NewTraceName = nameofwave(sweepName)+ "_"+AxisName
				duplicate /o /r = (0,inf)(i) SweepName $NewTraceName
				appendtograph /w = $PanelTitle + "#DataBrowserGraph" /L = $AxisName $NewTraceName
				ModifyGraph /w = $PanelTitle + "#DataBrowserGraph" axisEnab($AxisName) = {YaxisLow,YaxisHigh}
				Label /w = $PanelTitle + "#DataBrowserGraph" $AxisName, AxisName
				ModifyGraph /w = $PanelTitle + "#DataBrowserGraph" lblPosMode = 1
				ModifyGraph /w = $PanelTitle + "#DataBrowserGraph" standoff($AxisName) = 0,freePos($AxisName) = 0
			endif
		endif
			//AD wave to plot
			YaxisHigh = ADYaxisHigh
			YaxisLow = ADYaxisLow
		if(i<NumberOfADchannels)
			AxisName = "AD"+stringfromlist(i, ADChannelList,";")
			NewTraceName = nameofwave(sweepName)+ "_"+AxisName
			duplicate /o /r = (0,inf)(i+NumberOfADchannels) SweepName $NewTraceName
			appendtograph /w = $PanelTitle + "#DataBrowserGraph" /L = $AxisName $NewTraceName
			ModifyGraph /w = $PanelTitle + "#DataBrowserGraph" axisEnab($AxisName) = {YaxisLow,YaxisHigh}
			Label /w = $PanelTitle + "#DataBrowserGraph" $AxisName, AxisName
			ModifyGraph /w = $PanelTitle + "#DataBrowserGraph" lblPosMode = 1
			ModifyGraph /w = $PanelTitle + "#DataBrowserGraph" standoff($AxisName) = 0, freePos($AxisName) = 0
		endif
			if(DisplayDAChan == 1)
				DAYAxisHigh -= (ADYaxisSpacing+DAYaxisSpacing)
				DAYaxisLow -= (ADYaxisSpacing+DAYaxisSpacing)
			endif
			
			ADYAxisHigh -= (ADYaxisSpacing+DAYaxisSpacing)
			ADYaxisLow -= (ADYaxisSpacing+DAYaxisSpacing)
			i+=1
	while(i < max(NumberOfDAchannels,NumberOfADchannels))
End

//==============================================================================================================================
Function DB_OverlayPlotForDataBrowser(SweepName)
wave SweepName

end
//==============================================================================================================================

Function DB_RemoveAndKillWavesOnGraph(PanelTitle, GraphName)
	string panelTitle
	string GraphName
	variable i=0
	string cmd, WaveNameFromList
	string ListOfTracesOnGraph
	string Tracename
	
	ListOfTracesOnGraph=TraceNameList(GraphName, ";",0+1)
	if(itemsinlist(ListOfTracesOnGraph,";")>0)
		do
			TraceName = "\"#0\""
			sprintf cmd, "removefromgraph/w=%s $%s" GraphName, TraceName
			execute cmd
			Tracename=stringfromlist(i, ListOfTracesOnGraph,";")
			Killwaves/z  $Tracename
			i+=1
		while(i<(itemsinlist(ListOfTracesOnGraph,";")))
	endif
End
//==============================================================================================================================


Function DB_ButtonProc_6(ctrlName) : ButtonControl
	String ctrlName
	variable SweepNo
	variable SweepToPlot
	string SweepToPlotName
	string panelTitle
	getwindow kwTopWin wtitle
	panelTitle = s_value
	variable LastSweep = DB_LastSweepAcquired(panelTitle)
	string DataPath = getuserdata(panelTitle, "", "DataFolderPath")+":Data"
	
	controlinfo check_DataBrowser_SweepOverlay
	if(v_value == 1)
		Button button_DataBrowser_Previous disable = 2
		controlinfo /w = $panelTitle valdisp_DataBrowser_Sweep
		SweepNo = V_value
		controlinfo /w = $panelTitle setvar_DataBrowser_OverlaySkip
		SweepToPlot = SweepNo+v_value
	else
		Button button_DataBrowser_Previous disable = 0
		controlinfo /w = $panelTitle valdisp_DataBrowser_Sweep
		SweepNo = V_value
		SweepToPlot = SweepNo+1
	endif
	
	
	if(SweepToPlot <= LastSweep)
		SweepToPlotName = DataPath+":Sweep_"+num2str(SweepToPlot)
		valdisplay valdisp_DataBrowser_Sweep win = $panelTitle, value = _num:SweepToPlot
		DB_PlotDataBrowserWave(panelTitle, $SweepToPlotName)
	endif
	
	

End
//==============================================================================================================================

Function DB_ButtonProc_7(ctrlName) : ButtonControl
	String ctrlName
	variable SweepNo
	variable SweepToPlot
	string SweepToPlotName
	string panelTitle
	getwindow kwTopWin wtitle
	panelTitle=s_value
	
	controlinfo check_DataBrowser_SweepOverlay
	if(v_value == 1)
		Button button_DataBrowser_nextSweep disable = 2
		controlinfo /w = $panelTitle valdisp_DataBrowser_Sweep
		SweepNo = V_value
		controlinfo /w = $panelTitle setvar_DataBrowser_OverlaySkip
		SweepToPlot = SweepNo-v_value
	else
		Button button_DataBrowser_nextSweep disable = 0
		controlinfo /w = $panelTitle valdisp_DataBrowser_Sweep
		SweepNo = V_value
		SweepToPlot = SweepNo - 1
	endif
	
	
	if(SweepToPlot >= 0)
		SweepToPlotName = "Sweep_"+num2str(SweepToPlot)
		valdisplay valdisp_DataBrowser_Sweep win = $panelTitle, value = _num:SweepToPlot
		DB_PlotDataBrowserWave(panelTitle, $SweepToPlotName)
		DB_LastSweepAcquired(panelTitle)
	endif
	


End
//==============================================================================================================================

Function DB_CheckProc_3(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	variable SweepNo
	variable SweepToPlot
	string SweepToPlotName
	string panelTitle
	getwindow kwTopWin wtitle
	panelTitle=s_value
	
	variable LastSweep=DB_LastSweepAcquired(panelTitle)
	controlinfo/w=DataBrowser valdisp_DataBrowser_Sweep
	SweepNo=V_value
	SweepToPlot=SweepNo
	if(SweepToPlot<=LastSweep)
		SweepToPlotName="Sweep_"+num2str(SweepToPlot)
		valdisplay valdisp_DataBrowser_Sweep win=$panelTitle, value=_num:SweepToPlot
		DB_PlotDataBrowserWave(panelTitle, $SweepToPlotName)
	endif
End
//==============================================================================================================================

