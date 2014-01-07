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

Window DataBrowser() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(9,267,1150,890)
	ShowTools/A
	ValDisplay valdisp_DataBrowser_Sweep,pos={471,524},size={41,30},fSize=24
	ValDisplay valdisp_DataBrowser_Sweep,fStyle=1,limits={0,0,0},barmisc={0,1000}
	ValDisplay valdisp_DataBrowser_Sweep,value= _NUM:0
	Button button_DataBrowser_NextSweep,pos={592,518},size={450,43},proc=DB_ButtonProc_6,title="Next Sweep \\W649"
	Button button_DataBrowser_NextSweep,fSize=20
	Button button_DataBrowser_Previous,pos={17,516},size={450,43},proc=DB_ButtonProc_7,title="\\W646 Previous Sweep"
	Button button_DataBrowser_Previous,fSize=20
	ValDisplay valdisp_DataBrowser_LastSweep,pos={517,524},size={70,30},title="of"
	ValDisplay valdisp_DataBrowser_LastSweep,fSize=24,fStyle=1
	ValDisplay valdisp_DataBrowser_LastSweep,limits={0,0,0},barmisc={0,1000}
	ValDisplay valdisp_DataBrowser_LastSweep,value= _NUM:5
	CheckBox check_DataBrowser_DisplayDAchan,pos={20,6},size={116,14},proc=DB_CheckProc_3,title="Display DA channels"
	CheckBox check_DataBrowser_DisplayDAchan,value= 1
	CheckBox check_DataBrowser_Overlay,pos={429,6},size={101,14},title="Overlay Channels"
	CheckBox check_DataBrowser_Overlay,fColor=(65280,43520,0),value= 0
	CheckBox check_DataBrowser_ChanBaseline,pos={451,22},size={87,14},title="Baseline offset"
	CheckBox check_DataBrowser_ChanBaseline,value= 0
	TitleBox ListBox_DataBrowser_NoteDisplay,pos={1053,71},size={61,13},title="10:48:22 AM"
	TitleBox ListBox_DataBrowser_NoteDisplay,labelBack=(65535,65535,65535),fSize=8
	TitleBox ListBox_DataBrowser_NoteDisplay,frame=0
	CheckBox check_DataBrowser_SweepOverlay,pos={205,6},size={95,14},title="Overlay Sweeps"
	CheckBox check_DataBrowser_SweepOverlay,value= 0
	SetVariable setvar_DataBrowser_OverlaySkip,pos={223,22},size={87,30},title="Every\rsweeps"
	SetVariable setvar_DataBrowser_OverlaySkip,limits={1,inf,1},value= _NUM:1
	CheckBox check_DataBrowser_AutoUpdate,pos={602,6},size={149,14},title="Display last sweep acquired"
	CheckBox check_DataBrowser_AutoUpdate,fColor=(65280,43520,0),value= 0
	CheckBox check_DataBrowser_SweepBaseline,pos={222,53},size={87,14},title="Baseline offset"
	CheckBox check_DataBrowser_SweepBaseline,fColor=(65280,43520,0),value= 0
	CheckBox Check_DataBrowser_StimulusWaves,pos={795,8},size={186,14},title="Display DAC or TTL stimulus waves"
	CheckBox Check_DataBrowser_StimulusWaves,fColor=(65280,43520,0),value= 0
	CheckBox check_DataBrowser_Scroll,pos={997,9},size={137,14},title="Scrolling during aquisition"
	CheckBox check_DataBrowser_Scroll,fColor=(65280,43520,0),value= 0
	PopupMenu popup_DB_lockedDevices,pos={54,575},size={268,21},title="Data browser device assingment:"
	PopupMenu popup_DB_lockedDevices,mode=2,popvalue="ITC1600_Dev_0",value= #"\" - none -;\"+root:ITCPanelTitleList"
	Button Button_dataBrowser_lockBrowser,pos={329,576},size={65,20},proc=DB_ButtonProc_LockDBtoDevice,title="Lock"
	DefineGuide UGV0={FR,-171},UGV1={FR,-148}
	SetWindow kwTopWin,userdata(DataFolderPath)=  "root:ITC1600:Device0"
	String fldrSav0= GetDataFolder(1)
	SetDataFolder root:ITC1600:Device0:Data:
	Display/W=(18,73,1038,494)/FG=(,,UGV0,)/HOST=# /L=DA0 Sweep_0_DA0
	AppendToGraph/L=AD0 Sweep_0_AD0
	AppendToGraph/L=DA1 Sweep_0_DA1
	AppendToGraph/L=AD1 Sweep_0_AD1
	AppendToGraph/L=DA3 Sweep_0_DA3
	AppendToGraph/L=AD4 Sweep_0_AD4
	SetDataFolder fldrSav0
	ModifyGraph standoff(DA0)=0,standoff(AD0)=0,standoff(DA1)=0,standoff(AD1)=0,standoff(DA3)=0
	ModifyGraph standoff(AD4)=0
	ModifyGraph lblPosMode=1
	ModifyGraph freePos(DA0)=0
	ModifyGraph freePos(AD0)=0
	ModifyGraph freePos(DA1)=0
	ModifyGraph freePos(AD1)=0
	ModifyGraph freePos(DA3)=0
	ModifyGraph freePos(AD4)=0
	ModifyGraph axisEnab(DA0)={0.9633,1}
	ModifyGraph axisEnab(AD0)={0.6967,0.9333}
	ModifyGraph axisEnab(DA1)={0.63,0.6667}
	ModifyGraph axisEnab(AD1)={0.3633,0.6}
	ModifyGraph axisEnab(DA3)={0.2967,0.3333}
	ModifyGraph axisEnab(AD4)={0.03,0.2667}
	Label DA0 "DA0"
	Label AD0 "AD0"
	Label DA1 "DA1"
	Label AD1 "AD1"
	Label DA3 "DA3"
	Label AD4 "AD4"
	RenameWindow #,DataBrowserGraph
	SetActiveSubwindow ##
EndMacro