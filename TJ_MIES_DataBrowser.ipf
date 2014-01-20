#pragma rtGlobals=3		// Use modern global access method and strict wave access.


Function DB_ButtonProc_LockDBtoDevice(ctrlName) : ButtonControl
	String ctrlName
	getwindow kwTopWin wtitle
	DB_LockDBPanel(s_value)
End
//==============================================================================================================================

Function DB_LockDBPanel(panelTitle)
	string panelTitle
	controlinfo /w = $panelTitle popup_DB_lockedDevices
	if(v_value > 1)// makes sure "- none -" isn't selected
		dowindow /W = $panelTitle /C $"DB_" + s_value
		SetWindow $"DB_" + s_value, userdata(DataFolderPath) = HSU_DataFullFolderPathString(s_value)
	else
		print "Please choose a device assingment for the data browser"
	endif
End

//==============================================================================================================================
Function DB_LastSweepAcquired(PanelTitle)// returns last sweep acquired 
	string PanelTitle
	string ListOfAcquiredWaves
	variable LastSweepAcquired
	
	string DataPath = getuserdata(panelTitle, "", "DataFolderPath")+":Data"
	DFREF saveDFR = GetDataFolderDFR()
	setDataFolder $DataPath
	
	ListOfAcquiredWaves = wavelist("sweep_*",";","MINCOLS:2")
	LastSweepAcquired = (itemsinlist(ListOfAcquiredWaves,";")) - 1
	valdisplay valdisp_DataBrowser_LastSweep win = $PanelTitle, value = _num:LastSweepAcquired
	
	SetDataFolder saveDFR
	
	return LastSweepAcquired
End

//==============================================================================================================================

Function DB_PlotDataBrowserWave(panelTitle, SweepName) // Pass in sweep name with path included
	string panelTitle
	wave SweepName
	controlinfo check_DataBrowser_Overlay
	if(v_value == 0)
		DB_TilePlotForDataBrowser(panelTitle, SweepName)
		TitleBox ListBox_DataBrowser_NoteDisplay title = note(SweepName)
	else
		//OverlayPlotForDataBrowser(SweepName)
	endif

End
//==============================================================================================================================

Function DB_TilePlotForDataBrowser(panelTitle, SweepName) // Pass in sweep name with path included
	string panelTitle
	wave Sweepname
	string DataPath = getuserdata(panelTitle, "", "DataFolderPath") + ":Data"
	wave ConfigWaveName = $DataPath + ":Config_" + nameofwave(SweepName)
	string ADChannelList = RefToPullDatafrom2DWave(0,0, 1, ConfigWaveName)
	string DAChannelList = RefToPullDatafrom2DWave(1,0, 1, ConfigWaveName)
	variable NumberOfDAchannels = itemsinlist(DAChannelList)
	variable NumberOfADchannels = itemsinlist(ADChannelList)
	variable DACounter, ADCounter, i
	variable DisplayDAChan
	variable ADYaxisLow, ADYaxisHigh, ADYaxisSpacing, DAYaxisSpacing, Spacer,DAYaxisLow, DAYaxisHigh, YaxisHigh, YaxisLow
	string AxisName, NewTraceName
	string WavePath = getuserdata(panelTitle, "", "DataFolderPath")
	wave ChannelClampMode = $WavePath + ":ChannelClampMode"
	string UnitWaveNote = note(ConfigWaveName)
	string Unit
	
	controlinfo check_DataBrowser_SweepOverlay
	if(v_value == 0)
		DB_RemoveAndKillWavesOnGraph(panelTitle, panelTitle+"#DataBrowserGraph")
	endif
	
	ControlInfo check_DataBrowser_DisplayDAchan// Check to see if user wants DA channels displayed in DataBrowser graph
	DisplayDAChan = v_value
	if(DisplayDAChan == 1 )
		ADYaxisSpacing = (0.8 / (max(NumberOfADchannels,NumberOfDAchannels)))// the max allows for uneven number of AD and DA channels
		DAYaxisSpacing = (0.2 / (max(NumberOfADchannels,NumberOfDAchannels)))
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
	
	
	do ////USE CODE IN THIS LOOP TO ALLOW FOR HEADSTAGE ASSOCIATING TO BE PLOTTED
		if(DisplayDAChan == 1)
			//DA wave to plot
			if(i < NumberOfDAchannels)
				YaxisHigh = DAYaxisHigh
				YaxisLow = DAYaxisLow
				
				AxisName = "DA"+stringfromlist(i, DAChannelList,";")
				NewTraceName = DataPath +":"+nameofwave(sweepName)+ "_"+AxisName
				duplicate /o /r = (0,inf)(i) SweepName $NewTraceName
				appendtograph /w = $PanelTitle + "#DataBrowserGraph" /L = $AxisName $NewTraceName
				ModifyGraph /w = $PanelTitle + "#DataBrowserGraph" axisEnab($AxisName) = {YaxisLow,YaxisHigh}
				Unit = stringfromlist(i, UnitWaveNote, ";")
				Label /w = $PanelTitle + "#DataBrowserGraph" $AxisName, AxisName + " (" + Unit + ")"
				ModifyGraph /w = $PanelTitle + "#DataBrowserGraph" lblPosMode = 1
				ModifyGraph /w = $PanelTitle + "#DataBrowserGraph" standoff($AxisName) = 0,freePos($AxisName) = 0
			endif
		endif
			//AD wave to plot
			YaxisHigh = ADYaxisHigh
			YaxisLow = ADYaxisLow
		if(i < NumberOfADchannels)
			AxisName = "AD"+stringfromlist(i, ADChannelList,";")
			NewTraceName = DataPath +":"+nameofwave(sweepName)+ "_"+AxisName
			duplicate /o /r = (0, inf)(i + NumberOfDAchannels) SweepName $NewTraceName
			appendtograph /w = $PanelTitle + "#DataBrowserGraph" /L = $AxisName $NewTraceName
			ModifyGraph /w = $PanelTitle + "#DataBrowserGraph" axisEnab($AxisName) = {YaxisLow,YaxisHigh}
			Unit = stringfromlist((i + NumberOfDAchannels), UnitWaveNote, ";")
			Label /w = $PanelTitle + "#DataBrowserGraph" $AxisName, AxisName + " (" + Unit + ")"
			ModifyGraph /w = $PanelTitle + "#DataBrowserGraph" lblPosMode = 1
			ModifyGraph /w = $PanelTitle + "#DataBrowserGraph" standoff($AxisName) = 0, freePos($AxisName) = 0
		endif
		
		if(i >= NumberOfDAchannels)
			DAYaxisSpacing = 0
			//ADYaxisSpacing += DAYaxisSpacing
		endif	
		
		if(i >= NumberOfADchannels)
			ADYaxisSpacing = 0
			//DAYaxisSpacing +=DAYaxisSpacing
		endif
				
			if(DisplayDAChan == 1)
				DAYAxisHigh -= (ADYaxisSpacing+DAYaxisSpacing)
				DAYaxisLow -= (ADYaxisSpacing+DAYaxisSpacing)
			endif

		//print i, numberofadchannels
		
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
	variable i = 0
	string cmd, WaveNameFromList
	string ListOfTracesOnGraph
	string Tracename
	string DataPath = getuserdata(panelTitle, "", "DataFolderPath") + ":Data:"
	
	ListOfTracesOnGraph = TraceNameList(GraphName, ";",0+1)
	if(itemsinlist(ListOfTracesOnGraph,";") > 0)
		do
			TraceName = "\"#0\""
			sprintf cmd, "removefromgraph/w=%s $%s" GraphName, TraceName
			execute cmd
			Tracename=stringfromlist(i, ListOfTracesOnGraph,";")
			Killwaves/z  $DataPath+Tracename
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
	string panelTitle = DB_ReturnDBPanelName()	
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

Function DB_ButtonProc_PrevSweep(ctrlName) : ButtonControl
	String ctrlName
	variable SweepNo
	variable SweepToPlot
	string SweepToPlotName
	string panelTitle = DB_ReturnDBPanelName()	
	string DataPath = getuserdata(panelTitle, "", "DataFolderPath")+":Data"
	
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
		SweepToPlotName = DataPath+":Sweep_"+num2str(SweepToPlot)
		valdisplay valdisp_DataBrowser_Sweep win = $panelTitle, value = _num:SweepToPlot
		DB_PlotDataBrowserWave(panelTitle, $SweepToPlotName)
		DB_LastSweepAcquired(panelTitle)
	endif
	


End
//==============================================================================================================================

Function DB_CheckProc_DADisplay(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	variable SweepNo
	variable SweepToPlot
	string SweepToPlotName
	string panelTitle
	panelTitle = DB_ReturnDBPanelName()	
	string DataPath = getuserdata(panelTitle, "", "DataFolderPath")+":Data"
	
	variable LastSweep = DB_LastSweepAcquired(panelTitle)
	controlinfo /w = $panelTitle valdisp_DataBrowser_Sweep
	SweepNo = v_value
	print sweepno
	SweepToPlot = SweepNo
	if(SweepToPlot <= LastSweep)
		SweepToPlotName = DataPath + ":Sweep_"+num2str(SweepToPlot)
		valdisplay valdisp_DataBrowser_Sweep win = $panelTitle, value = _num:SweepToPlot
		DB_PlotDataBrowserWave(panelTitle, $SweepToPlotName)
	endif
End
//==============================================================================================================================
Function /T DB_ReturnDBPanelName()	
	string panelTitle
	getwindow kwTopWin activesw
	PanelTitle = s_value
	variable SearchResult = strsearch(panelTitle, "DataBrowserGraph", 2)
	if(SearchResult != -1)
		PanelTitle = PanelTitle[0,SearchResult-2]//SearchResult+1]
	endif
	
	return PanelTitle
End
Window DataBrowser() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(522,119,1665,661)
	ValDisplay valdisp_DataBrowser_Sweep,pos={471,450},size={41,30}
	ValDisplay valdisp_DataBrowser_Sweep,userdata(ResizeControlsInfo)= A"!!,IQJ,hsq!!#>2!!#=Sz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	ValDisplay valdisp_DataBrowser_Sweep,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#?(FEDG<zzzzzzzzzzz"
	ValDisplay valdisp_DataBrowser_Sweep,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	ValDisplay valdisp_DataBrowser_Sweep,fSize=24,fStyle=1
	ValDisplay valdisp_DataBrowser_Sweep,limits={0,0,0},barmisc={0,1000}
	ValDisplay valdisp_DataBrowser_Sweep,value= _NUM:0
	Button button_DataBrowser_NextSweep,pos={592,444},size={450,43},proc=DB_ButtonProc_6,title="Next Sweep \\W649"
	Button button_DataBrowser_NextSweep,userdata(ResizeControlsInfo)= A"!!,J%!!#CC!!#CF!!#>:z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_DataBrowser_NextSweep,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#?(FEDG<zzzzzzzzzzz"
	Button button_DataBrowser_NextSweep,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	Button button_DataBrowser_NextSweep,fSize=20
	Button button_DataBrowser_Previous,pos={17,442},size={450,43},proc=DB_ButtonProc_PrevSweep,title="\\W646 Previous Sweep"
	Button button_DataBrowser_Previous,userdata(ResizeControlsInfo)= A"!!,BA!!#CB!!#CF!!#>:z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_DataBrowser_Previous,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#?(FEDG<zzzzzzzzzzz"
	Button button_DataBrowser_Previous,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	Button button_DataBrowser_Previous,fSize=20
	ValDisplay valdisp_DataBrowser_LastSweep,pos={517,450},size={70,30},title="of"
	ValDisplay valdisp_DataBrowser_LastSweep,userdata(ResizeControlsInfo)= A"!!,Ig5QF11!!#?E!!#=Sz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	ValDisplay valdisp_DataBrowser_LastSweep,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#?(FEDG<zzzzzzzzzzz"
	ValDisplay valdisp_DataBrowser_LastSweep,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	ValDisplay valdisp_DataBrowser_LastSweep,fSize=24,fStyle=1
	ValDisplay valdisp_DataBrowser_LastSweep,limits={0,0,0},barmisc={0,1000}
	ValDisplay valdisp_DataBrowser_LastSweep,value= _NUM:0
	CheckBox check_DataBrowser_DisplayDAchan,pos={20,6},size={116,14},proc=DB_CheckProc_DADisplay,title="Display DA channels"
	CheckBox check_DataBrowser_DisplayDAchan,userdata(ResizeControlsInfo)= A"!!,BY!!#:\"!!#@L!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_DataBrowser_DisplayDAchan,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_DataBrowser_DisplayDAchan,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_DataBrowser_DisplayDAchan,value= 0
	CheckBox check_DataBrowser_Overlay,pos={429,6},size={101,14},title="Overlay Channels"
	CheckBox check_DataBrowser_Overlay,userdata(ResizeControlsInfo)= A"!!,I<J,hjM!!#@.!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_DataBrowser_Overlay,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_DataBrowser_Overlay,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_DataBrowser_Overlay,fColor=(65280,43520,0),value= 0
	CheckBox check_DataBrowser_ChanBaseline,pos={451,22},size={87,14},title="Baseline offset"
	CheckBox check_DataBrowser_ChanBaseline,userdata(ResizeControlsInfo)= A"!!,IGJ,hm>!!#?g!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_DataBrowser_ChanBaseline,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_DataBrowser_ChanBaseline,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_DataBrowser_ChanBaseline,value= 0
	TitleBox ListBox_DataBrowser_NoteDisplay,pos={1053,71},size={55,13}
	TitleBox ListBox_DataBrowser_NoteDisplay,userdata(ResizeControlsInfo)= A"!!,K?TE%<=!!#>j!!#;]z!!#o2B4uAezzzzzzzzzzzzzz!!#o2B4uAezz"
	TitleBox ListBox_DataBrowser_NoteDisplay,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	TitleBox ListBox_DataBrowser_NoteDisplay,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	TitleBox ListBox_DataBrowser_NoteDisplay,labelBack=(65535,65535,65535),fSize=8
	TitleBox ListBox_DataBrowser_NoteDisplay,frame=0
	CheckBox check_DataBrowser_SweepOverlay,pos={205,6},size={95,14},title="Overlay Sweeps"
	CheckBox check_DataBrowser_SweepOverlay,userdata(ResizeControlsInfo)= A"!!,G]!!#:\"!!#@\"!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_DataBrowser_SweepOverlay,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_DataBrowser_SweepOverlay,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_DataBrowser_SweepOverlay,value= 0
	SetVariable setvar_DataBrowser_OverlaySkip,pos={223,22},size={87,30},title="Every\rsweeps"
	SetVariable setvar_DataBrowser_OverlaySkip,userdata(ResizeControlsInfo)= A"!!,Go!!#<h!!#?g!!#=Sz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_DataBrowser_OverlaySkip,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable setvar_DataBrowser_OverlaySkip,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_DataBrowser_OverlaySkip,limits={1,inf,1},value= _NUM:1
	CheckBox check_DataBrowser_AutoUpdate,pos={602,6},size={149,14},title="Display last sweep acquired"
	CheckBox check_DataBrowser_AutoUpdate,userdata(ResizeControlsInfo)= A"!!,J'J,hjM!!#A$!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_DataBrowser_AutoUpdate,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_DataBrowser_AutoUpdate,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_DataBrowser_AutoUpdate,fColor=(65280,43520,0),value= 0
	CheckBox check_DataBrowser_SweepBaseline,pos={222,53},size={87,14},title="Baseline offset"
	CheckBox check_DataBrowser_SweepBaseline,userdata(ResizeControlsInfo)= A"!!,Gn!!#>b!!#?g!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_DataBrowser_SweepBaseline,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_DataBrowser_SweepBaseline,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_DataBrowser_SweepBaseline,fColor=(65280,43520,0),value= 0
	CheckBox Check_DataBrowser_StimulusWaves,pos={795,8},size={186,14},title="Display DAC or TTL stimulus waves"
	CheckBox Check_DataBrowser_StimulusWaves,userdata(ResizeControlsInfo)= A"!!,JW^]6Y#!!#AI!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_DataBrowser_StimulusWaves,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox Check_DataBrowser_StimulusWaves,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_DataBrowser_StimulusWaves,fColor=(65280,43520,0),value= 0
	CheckBox check_DataBrowser_Scroll,pos={997,9},size={137,14},title="Scrolling during aquisition"
	CheckBox check_DataBrowser_Scroll,userdata(ResizeControlsInfo)= A"!!,K55QF(]!!#@m!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_DataBrowser_Scroll,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_DataBrowser_Scroll,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_DataBrowser_Scroll,fColor=(65280,43520,0),value= 0
	PopupMenu popup_DB_lockedDevices,pos={54,501},size={231,21},title="Data browser device assingment:"
	PopupMenu popup_DB_lockedDevices,userdata(ResizeControlsInfo)= A"!!,Dg!!#C_J,hrk!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu popup_DB_lockedDevices,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#?(FEDG<zzzzzzzzzzz"
	PopupMenu popup_DB_lockedDevices,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	PopupMenu popup_DB_lockedDevices,mode=1,popvalue=" - none - ",value= #"\" - none - ;\" + root:ITCPanelTitleList"
	Button Button_dataBrowser_lockBrowser,pos={329,502},size={65,20},proc=DB_ButtonProc_LockDBtoDevice,title="Lock"
	Button Button_dataBrowser_lockBrowser,userdata(ResizeControlsInfo)= A"!!,H_J,ht6!!#?;!!#<Xz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button Button_dataBrowser_lockBrowser,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#?(FEDG<zzzzzzzzzzz"
	Button Button_dataBrowser_lockBrowser,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	CheckBox check_DB_DispTTLChan,pos={21,30},size={122,14},title="Display TTL Channels"
	CheckBox check_DB_DispTTLChan,userdata(ResizeControlsInfo)= A"!!,Ba!!#=S!!#@X!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_DB_DispTTLChan,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#?(FEDG<zzzzzzzzzzz"
	CheckBox check_DB_DispTTLChan,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	CheckBox check_DB_DispTTLChan,fColor=(65280,43520,0),value= 0
	CheckBox check_DB_DispADChan,pos={21,52},size={117,14},title="Display AD Channels"
	CheckBox check_DB_DispADChan,userdata(ResizeControlsInfo)= A"!!,Ba!!#>^!!#@N!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_DB_DispADChan,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#?(FEDG<zzzzzzzzzzz"
	CheckBox check_DB_DispADChan,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	CheckBox check_DB_DispADChan,fColor=(65280,43520,0),value= 0
	DefineGuide UGV0={FR,-171},UGV1={FR,-148},UGH0={FB,-106}
	SetWindow kwTopWin,hook(ResizeControls)=ResizeControls#ResizeControlsHook
	SetWindow kwTopWin,userdata(DataFolderPath)=  "root:ITC1600:Device0"
	SetWindow kwTopWin,userdata(ResizeControlsInfo)= A"!!*'\"z!!#EIhuH.MJ,fQLzzzzzzzzzzzzzzzzzzzz"
	SetWindow kwTopWin,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzzzzzzzzzzzzzzz"
	SetWindow kwTopWin,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzzzzzzzzz!!!"
	SetWindow kwTopWin,userdata(ResizeControlsGuides)=  "UGV0;UGV1;UGH0;"
	SetWindow kwTopWin,userdata(ResizeControlsInfoUGV0)= A":-hTC3`S[N0KW?-:-(d0?V+3a0fC^>?USIK?SFQ@=\\qOJ<HD_l4%N.F8Qnnb<'a2=0KW*,;b9q[:JNr22_mHb<CoSI0fhd%4%E:B6q&jl4&SL@:et\"]<(Tk\\3\\<'F0fo"
	SetWindow kwTopWin,userdata(ResizeControlsInfoUGV1)= A":-hTC3`S[N0frH.:-(d0?V+3a0fC^>?USIK?SFQ@=\\qOJ<HD_l4%N.F8Qnnb<'a2=0KW*,;b9q[:JNr23Ailg<CoSI0fhd%4%E:B6q&jl4&SL@:et\"]<(Tk\\3\\<'C3'."
	SetWindow kwTopWin,userdata(ResizeControlsInfoUGH0)= A":-hTC3`S[@0KW?-:-(d0?V+3a0fC^>?USIK?SFQ@=\\qOJ<HD_l4%N.F8Qnnb<'a2=0fr3-;b9q[:JNr-1H%<b<CoSI0fhcj4%E:B6q&jl4&SL@:et\"]<(Tk\\3\\<'?2EL"
	Display/W=(18,73,1038,431)/FG=(,,UGV0,)/HOST=# 
	RenameWindow #,DataBrowserGraph
	SetActiveSubwindow ##
EndMacro
