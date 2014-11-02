#pragma rtGlobals=3		// Use modern global access method and strict wave access.

static Constant GRAPH_DIV_SPACING = 0.03

static Function/DF DB_GetDataPath(panelTitle)
	string panelTitle

	return $GetUserData(panelTitle, "", "DataFolderPath") + ":Data"
End

static Function/S DB_GetNotebookSubWindow(panelTitle)
	string panelTitle

	return panelTitle + "#WaveNoteDisplay"
End

static Function/S DB_GetMainGraph(panelTitle)
	string panelTitle

	return panelTitle + "#DataBrowserGraph"
End
End

static Function DB_LockDBPanel(panelTitle)
	string panelTitle

	string panelTitleNew, device

	device = GetPopupMenuString(panelTitle, "popup_DB_lockedDevices")
	if(!CmpStr(device,NONE))
		panelTitleNew = "DataBrowser"

		if(windowExists(panelTitleNew))
			panelTitleNew = UniqueName("DataBrowser", 9, 1)
		endif

		print "Please choose a device assignment for the data browser"
		DoWindow/W=$panelTitle/C $panelTitleNew
		return NaN
	endif

	panelTitleNew = "DB_" + device
	DoWindow/W=$panelTitle/C $panelTitleNew

	SetWindow $panelTitleNew, userdata(DataFolderPath) = GetDevicePathAsString(device)
	DB_PlotSweep(panelTitleNew, 0)
End

static Function DB_FirstAndLastSweepAcquired(panelTitle, first, last)
	string panelTitle
	variable &first, &last

	first = 0
	last  = 0

	string ListOfAcquiredWaves
	dfref dfr = DB_GetDataPath(panelTitle)

	if(!DataFolderExistsDFR(dfr))
		return NaN
	endif

	ListOfAcquiredWaves = GetListOfWaves(dfr, DATA_SWEEP_REGEXP, options="MINCOLS:2")
	if(!isEmpty(ListOfAcquiredWaves))
		first = NumberByKey("Sweep", ListOfAcquiredWaves, "_")
		last = ItemsInList(ListOfAcquiredWaves) - 1 + first
	endif
	SetValDisplaySingleVariable(panelTitle, "valdisp_DataBrowser_LastSweep", last)
	SetVariable setvar_DataBrowser_SweepNo win = $panelTitle, limits = {first, last, 1}
End

static Function DB_PlotSweep(panelTitle, sweepNo)
	string panelTitle
	variable sweepNo

	string subWindow = DB_GetNotebookSubWindow(panelTitle)
	variable firstSweep, lastSweep

	DFREF dfr = DB_GetDataPath(panelTitle)

	if(!DataFolderExistsDFR(dfr))
		return NaN
	endif

	DB_FirstAndLastSweepAcquired(panelTitle, firstSweep, lastSweep)

	// handles situation where data sweep number starts at a value greater than the controls number
	// usually occurs after locking when control is set to zero
	if(sweepNo < firstSweep)
		sweepNo = firstSweep
	elseif(sweepNo > lastSweep)
		sweepNo = lastSweep
	endif

	SetSetVariable(panelTitle, "setvar_DataBrowser_SweepNo", sweepNo)
	Wave/Z/SDFR=dfr wv = $("Sweep_" + num2str(sweepNo))

	if(!GetCheckBoxState(panelTitle, "check_DataBrowser_Overlay")) // normal plotting
		if(WaveExists(wv))
			DB_TilePlotForDataBrowser(panelTitle, wv)
			Notebook $subWindow selection={startOfFile, endOfFile} // select entire contents of notebook
			Notebook $subWindow text = "Sweep note: \r " + note(wv) // replaces selected notebook content with new wave note.
		else
			Notebook $subWindow selection={startOfFile, endOfFile}
			Notebook $subWindow text = "Sweep does not exist."
			if(!GetCheckBoxState(panelTitle, "check_DataBrowser_SweepOverlay"))
				RemoveTracesFromGraph(DB_GetMainGraph(panelTitle))
			endif			
		endif		
	else
		DEBUGPRINT("channel overlay - not yet implemented")
	endif
End

static Function DB_TilePlotForDataBrowser(panelTitle, sweep)
	string panelTitle
	wave sweep

	dfref dfr = DB_GetDataPath(panelTitle)
	if(!DataFolderExistsDFR(dfr))
		printf "Datafolder for %s does not exist\r", panelTitle
		return NaN
	endif

	Wave/SDFR=dfr config = GetConfigWave(sweep)
	string ADChannelList = SCOPE_RefToPullDatafrom2DWave(0, 0, 1, config)
	string DAChannelList = SCOPE_RefToPullDatafrom2DWave(1, 0, 1, config)
	variable NumberOfDAchannels = ItemsInList(DAChannelList)
	variable NumberOfADchannels = ItemsInList(ADChannelList)
	// the max allows for uneven number of AD and DA channels
	variable numChannels = max(NumberOfDAchannels, NumberOfADchannels)
	variable i
	variable DisplayDAChan
	variable ADYaxisLow, ADYaxisHigh, ADYaxisSpacing, DAYaxisSpacing, DAYaxisLow, DAYaxisHigh, YaxisHigh, YaxisLow
	string axis
	string configNote = note(config)
	string unit
	string graph = DB_GetMainGraph(panelTitle)

	if(!GetCheckBoxState(panelTitle, "check_DataBrowser_SweepOverlay"))
		RemoveTracesFromGraph(graph)
	endif

	DisplayDAChan = GetCheckBoxState(panelTitle, "check_DataBrowser_DisplayDAchan")
	if(DisplayDAChan)
		ADYaxisSpacing = 0.8 / numChannels
		DAYaxisSpacing = 0.2 / numChannels
	else
		ADYaxisSpacing = 1 / NumberOfADchannels
	endif

	if(DisplayDAChan)
		DAYaxisHigh = 1
		DAYaxisLow  = DAYaxisHigh - DAYaxisSpacing + GRAPH_DIV_SPACING
		ADYaxisHigh = DAYaxisLow - GRAPH_DIV_SPACING
		ADYaxisLow  = ADYaxisHigh - ADYaxisSpacing + GRAPH_DIV_SPACING
	else
		ADYaxisHigh = 1
		ADYaxisLow  = 1 - ADYaxisSpacing + GRAPH_DIV_SPACING
	endif

	for(i = 0; i < numChannels; i += 1)
		if(DisplayDAChan && i < NumberOfDAchannels)
			YaxisHigh = DAYaxisHigh
			YaxisLow = DAYaxisLow

			axis = "DA" + StringFromList(i, DAChannelList)
			AppendToGraph/W=$graph /L=$axis sweep[][i]
			ModifyGraph/W=$graph axisEnab($axis) = {YaxisLow, YaxisHigh}
			unit = StringFromList(i, configNote)
			Label/W=$graph $axis, axis + "\r(" + unit + ")"
			ModifyGraph/W=$graph lblPosMode = 1
			ModifyGraph/W=$graph standoff($axis) = 0, freePos($axis) = 0
		endif

		//AD wave to plot
		YaxisHigh = ADYaxisHigh
		YaxisLow  = ADYaxisLow

		if(i < NumberOfADchannels)
			axis = "AD" + StringFromList(i, ADChannelList)
			AppendToGraph/W=$graph /L=$axis sweep[][i + NumberOfDAchannels]
			ModifyGraph/W=$graph axisEnab($axis) = {YaxisLow, YaxisHigh}
			unit = StringFromList(i + NumberOfDAchannels, configNote)
			Label/W=$graph $axis, axis + "\r(" + unit + ")"
			ModifyGraph/W=$graph lblPosMode = 1
			ModifyGraph/W=$graph standoff($axis) = 0, freePos($axis) = 0
		endif

		if(i >= NumberOfDAchannels)
			DAYaxisSpacing = 0
		endif	

		if(i >= NumberOfADchannels)
			ADYaxisSpacing = 0
		endif

		if(DisplayDAChan)
			DAYAxisHigh -= ADYaxisSpacing + DAYaxisSpacing
			DAYaxisLow  -= ADYaxisSpacing + DAYaxisSpacing
		endif

		ADYAxisHigh -= ADYaxisSpacing + DAYaxisSpacing
		ADYaxisLow  -= ADYaxisSpacing + DAYaxisSpacing
	endfor
End

Window databrowser() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(1200,321,2426,874)
	SetDrawLayer UserBack
	DrawText 100,100,"ListBox_DataBrowser_NoteDisplay"
	DrawText 100,100,"ListBox_DataBrowser_NoteDisplay"
	ValDisplay valdisp_DataBrowser_Sweep,pos={447,512},size={60,30},disable=1
	ValDisplay valdisp_DataBrowser_Sweep,userdata(ResizeControlsInfo)= A"!!,IH!!#CP!!#?)!!#=Sz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	ValDisplay valdisp_DataBrowser_Sweep,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#?(FEDG<zzzzzzzzzzz"
	ValDisplay valdisp_DataBrowser_Sweep,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	ValDisplay valdisp_DataBrowser_Sweep,fSize=24,fStyle=1
	ValDisplay valdisp_DataBrowser_Sweep,limits={0,0,0},barmisc={0,1000}
	ValDisplay valdisp_DataBrowser_Sweep,value= _NUM:0
	Button button_DataBrowser_NextSweep,pos={616,464},size={425,43},proc=DB_ButtonProc_NextSweep,title="Next Sweep \\W649"
	Button button_DataBrowser_NextSweep,userdata(ResizeControlsInfo)= A"!!,J%!!#CM!!#C9J,hnez!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_DataBrowser_NextSweep,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#?(FEDG<zzzzzzzzzzz"
	Button button_DataBrowser_NextSweep,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	Button button_DataBrowser_NextSweep,fSize=20
	Button button_DataBrowser_Previous,pos={17,462},size={425,43},proc=DB_ButtonProc_PrevSweep,title="\\W646 Previous Sweep"
	Button button_DataBrowser_Previous,userdata(ResizeControlsInfo)= A"!!,BA!!#CL!!#C9J,hnez!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_DataBrowser_Previous,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#?(FEDG<zzzzzzzzzzz"
	Button button_DataBrowser_Previous,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	Button button_DataBrowser_Previous,fSize=20
	ValDisplay valdisp_DataBrowser_LastSweep,pos={525,471},size={86,30},bodyWidth=60,title="of"
	ValDisplay valdisp_DataBrowser_LastSweep,userdata(ResizeControlsInfo)= A"!!,I_!!#CP!!#?e!!#=Sz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	ValDisplay valdisp_DataBrowser_LastSweep,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#?(FEDG<zzzzzzzzzzz"
	ValDisplay valdisp_DataBrowser_LastSweep,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	ValDisplay valdisp_DataBrowser_LastSweep,fSize=24,frame=2,fStyle=1
	ValDisplay valdisp_DataBrowser_LastSweep,limits={0,0,0},barmisc={0,1000}
	ValDisplay valdisp_DataBrowser_LastSweep,value= _NUM:0
	ValDisplay valdisp_DataBrowser_LastSweep,barBackColor= (56576,56576,56576)
	CheckBox check_DataBrowser_DisplayDAchan,pos={21,7},size={116,14},proc=DB_CheckProc_DADisplay,title="Display DA channels"
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
	TitleBox ListBox_DataBrowser_NoteDisplay,pos={937,25},size={197,39}
	TitleBox ListBox_DataBrowser_NoteDisplay,userdata(ResizeControlsInfo)= A"!!,K>+94`o!!#AT!!#>^z!!#o2B4uAezzzzzzzzzzzzzz!!#o2B4uAezz"
	TitleBox ListBox_DataBrowser_NoteDisplay,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	TitleBox ListBox_DataBrowser_NoteDisplay,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	TitleBox ListBox_DataBrowser_NoteDisplay,labelBack=(62208,62208,62208),fSize=8
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
	PopupMenu popup_DB_lockedDevices,pos={636,522},size={330,21},bodyWidth=170,title="Data browser device assingment:"
	PopupMenu popup_DB_lockedDevices,userdata(ResizeControlsInfo)= A"!!,J0!!#Cg!!#B_!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu popup_DB_lockedDevices,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#?(FEDG<zzzzzzzzzzz"
	PopupMenu popup_DB_lockedDevices,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	PopupMenu popup_DB_lockedDevices,mode=1,popvalue=" - none - ",value= #"\" - none - ;\" + root:MIES:ITCDevices:ITCPanelTitleList"
	Button Button_dataBrowser_lockBrowser,pos={971,520},size={70,20},proc=DB_ButtonProc_LockDBtoDevice,title="Lock"
	Button Button_dataBrowser_lockBrowser,userdata(ResizeControlsInfo)= A"!!,K.^]6b(!!#?E!!#<Xz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button Button_dataBrowser_lockBrowser,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#?(FEDG<zzzzzzzzzzz"
	Button Button_dataBrowser_lockBrowser,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	CheckBox check_DB_DispTTLChan,pos={21,30},size={122,14},title="Display TTL Channels"
	CheckBox check_DB_DispTTLChan,userdata(ResizeControlsInfo)= A"!!,Ba!!#=S!!#@X!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_DB_DispTTLChan,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_DB_DispTTLChan,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox check_DB_DispTTLChan,fColor=(65280,43520,0),value= 0
	CheckBox check_DB_DispADChan,pos={21,52},size={117,14},title="Display AD Channels"
	CheckBox check_DB_DispADChan,userdata(ResizeControlsInfo)= A"!!,Ba!!#>^!!#@N!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_DB_DispADChan,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_DB_DispADChan,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox check_DB_DispADChan,fColor=(65280,43520,0),value= 0
	Button button_DataBrowser_setaxis,pos={19,517},size={150,23},proc=DB_ButtonProc_AutoScale,title="Autoscale"
	Button button_DataBrowser_setaxis,userdata(ResizeControlsInfo)= A"!!,BQ!!#Cf5QF.e!!#<pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_DataBrowser_setaxis,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#?(FEDG<zzzzzzzzzzz"
	Button button_DataBrowser_setaxis,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_DataBrowser_SweepNo,pos={447,470},size={74,32},proc=DB_SetVarProc_SweepNo
	SetVariable setvar_DataBrowser_SweepNo,fSize=24
	SetVariable setvar_DataBrowser_SweepNo,limits={0,inf,1},value= _NUM:0,live= 1
	DefineGuide UGV0={FR,-193},UGV1={FR,-148},UGH0={FB,-317},UGH1={FB,-101}
	SetWindow kwTopWin,hook(ResizeControls)=ResizeControls#ResizeControlsHook
	SetWindow kwTopWin,userdata(DataFolderPath)= A"Ec5l<3_`17;`[KL6UYL/Bk(^q3_<:<0fC^>3^dP&Bk(^."
	SetWindow kwTopWin,userdata(ResizeControlsInfo)= A"!!*'\"z!!#ET5QF1Z5QCcazzzzzzzzzzzzzzzzzzzz"
	SetWindow kwTopWin,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzzzzzzzzzzzzzzz"
	SetWindow kwTopWin,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzzzzzzzzz!!!"
	SetWindow kwTopWin,userdata(ResizeControlsGuides)=  "UGV0;UGV1;UGH0;UGH1;"
	SetWindow kwTopWin,userdata(ResizeControlsInfoUGV0)= A":-hTC3`S[N0KW?-:-)ooFCAX!Dg-86E][6':dmEFF(KAR85E,T>#.mm5tj<n4&A^O8Q88W:-(*`1G_*_<CoSI0fhd%4%E:B6q&jl4&SL@:et\"]<(Tk\\3\\<'H1HP"
	SetWindow kwTopWin,userdata(ResizeControlsInfoUGV1)= A":-hTC3`S[N0frH.:-)ooFCAX!Dg-86E][6':dmEFF(KAR85E,T>#.mm5tj<n4&A^O8Q88W:-(*`2`Nlh<CoSI0fhd%4%E:B6q&jl4&SL@:et\"]<(Tk\\3\\<'C3'."
	SetWindow kwTopWin,userdata(ResizeControlsInfoUGH0)= A":-hTC3`S[@0KW?-:-)ooFCAX!Dg-86E][6':dmEFF(KAR85E,T>#.mm5tj<o4&A^O8Q88W:-(-d2EOE/8OQ!%3^uFt7o`,K75?nc;FO8U:K'ha8P`)B/Mf+?3r"
	SetWindow kwTopWin,userdata(ResizeControlsInfoUGH1)= A":-hTC3`S[@0frH.:-)ooFCAX!Dg-86E][6':dmEFF(KAR85E,T>#.mm5tj<o4&A^O8Q88W:-(3h1-8!+8OQ!%3^uFt7o`,K75?nc;FO8U:K'ha8P`)B/MSq63r"
	Display/W=(18,72,1039,368)/FG=(,,,UGH1)/HOST=# 
	RenameWindow #,DataBrowserGraph
	SetActiveSubwindow ##
	NewNotebook /F=1 /N=WaveNoteDisplay /W=(1042,72,1220,341)/FG=(,,,UGH1) /HOST=# /OPTS=10 
	Notebook kwTopWin, defaultTab=36, statusWidth=0, autoSave=1, showRuler=0, rulerUnits=1
	Notebook kwTopWin newRuler=Normal, justification=0, margins={0,0,111}, spacing={0,0,0}, tabs={}, rulerDefaults={"Arial",10,0,(0,0,0)}
	Notebook kwTopWin, zdata= "GaqDU%ejN7!Z)ts!b+VAAccFQf<WF*6ioh3ac'6&\":'pGblu%.:d-YZK%8.G#03I^`#KnXR/m<e<!k&"
	Notebook kwTopWin, zdataEnd= 1
	RenameWindow #,WaveNoteDisplay
	SetActiveSubwindow ##
EndMacro

Function DB_ButtonProc_NextSweep(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	string panelTitle
	variable sweepNo
	switch(ba.eventcode)
		case EVENT_MOUSE_UP:
			panelTitle = ba.win
			sweepNo = GetSetVariable(panelTitle, "setvar_DataBrowser_SweepNo")

			if(GetCheckBoxState(panelTitle, "check_DataBrowser_SweepOverlay"))
				DisableControl(panelTitle, "button_DataBrowser_Previous")
				sweepNo += GetSetVariable(panelTitle, "setvar_DataBrowser_OverlaySkip")
			else
				EnableControl(panelTitle, "button_DataBrowser_Previous")
				sweepNo += 1
			endif

			DB_PlotSweep(panelTitle, sweepNo)
			break
	endswitch

	return 0
End

Function DB_ButtonProc_AutoScale(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	string panelTitle = ba.win
	switch(ba.eventcode)
		case EVENT_MOUSE_UP:
			panelTitle = ba.win
			SetAxis/A/W=$(panelTitle + "#DataBrowserGraph")
			SetAxis/A/W=$(panelTitle + "#LabNotebook")
			break
	endswitch

	return 0
End

Function DB_ButtonProc_PrevSweep(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	variable sweepNo
	string panelTitle
	switch(ba.eventcode)
		case EVENT_MOUSE_UP:
			panelTitle = ba.win
			sweepNo = GetSetVariable(panelTitle, "setvar_DataBrowser_SweepNo")

			if(GetCheckBoxState(panelTitle, "check_DataBrowser_SweepOverlay"))
				DisableControl(panelTitle, "button_DataBrowser_nextSweep")
				sweepNo -= GetSetVariable(panelTitle, "setvar_DataBrowser_OverlaySkip")
			else
				EnableControl(panelTitle, "button_DataBrowser_nextSweep")
				sweepNo -= 1
			endif

			DB_PlotSweep(panelTitle, sweepNo)
			break
	endswitch

	return 0
End

Function DB_CheckProc_DADisplay(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	variable sweepNo
	string panelTitle

	switch(cba.eventCode)
		case EVENT_MOUSE_UP:
			panelTitle = cba.win

			sweepNo = GetSetVariable(panelTitle, "setvar_DataBrowser_SweepNo")
			DB_PlotSweep(panelTitle, sweepNo)
			break
	endswitch

	return 0
End

Function DB_ButtonProc_LockDBtoDevice(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch(ba.eventcode)
		case EVENT_MOUSE_UP:
			DB_LockDBPanel(ba.win)
			break
	endswitch

	return 0
End

Function DB_SetVarProc_SweepNo(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	string panelTitle
	variable dval, firstSweep, lastSweep, lastSweepDisplayed, sweepNo

	switch(sva.eventCode)
		case 1: // mouse up - when the scroll wheel is used on the mouse - "up or down"
		case 2: // Enter key - when a number is manually entered
		case 3: // Live update - happens when you hit the arrow keys associated with the set variable
			dval = sva.dval
			paneltitle = sva.win

			DB_FirstAndLastSweepAcquired(panelTitle, firstSweep, lastSweep)

			if(GetCheckBoxState(panelTitle, "check_DataBrowser_SweepOverlay"))
				lastSweepDisplayed = GetCheckBoxState(panelTitle, "check_DataBrowser_Sweep")
				if(dval > lastSweepDisplayed)
					SetVariable setvar_DataBrowser_SweepNo win =$panelTitle, limits = {dval, lastSweep , 1}
					ControlUpdate/W=$panelTitle setvar_DataBrowser_SweepNo
				elseif(dval < lastSweepDisplayed)
					SetVariable setvar_DataBrowser_SweepNo win = $panelTitle, limits = {firstSweep, dval , 1}
				endif
			else
				SetVariable setvar_DataBrowser_SweepNo win = $panelTitle, limits = {firstSweep, lastSweep , 1}
				ValDisplay valdisp_DataBrowser_Sweep win = $panelTitle, value =_NUM:dval
			endif

			DB_PlotSweep(panelTitle, sweepNo)
			break
	endswitch
	return 0
End
