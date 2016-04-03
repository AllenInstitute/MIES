#pragma rtGlobals=3		// Use modern global access method and strict wave access.

/// @file MIES_DataBrowser.ipf
/// @brief __DB__ Panel for browsing acquired data during acquisition

// stock igor
#include <Resize Controls>

// third party includes
#include ":ACL_TabUtilities"
#include ":ACL_UserdataEditor"
#include ":FixScrolling"

// our includes
#include ":MIES_AnalysisFunctionHelpers"
#include ":MIES_Constants"
#include ":MIES_Debugging"
#include ":MIES_EnhancedWMRoutines"
#include ":MIES_GlobalStringAndVariableAccess"
#include ":MIES_GuiUtilities"
#include ":MIES_MiesUtilities"
#include ":MIES_Utilities"
#include ":MIES_Structures"
#include ":MIES_WaveDataFolderGetters"

Menu "Mies Panels", dynamic
	"Data Browser", /Q, DB_OpenDataBrowser()
End

///@brief Executes Igor version appropriate data browser macro
///
Function DB_OpenDataBrowser()

#if (IgorVersion() >= 7.0)
	Execute "DataBrowser_IP7()"
#else
	Execute "DataBrowser()"
#endif
End

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

static Function/S DB_GetLabNoteBookGraph(panelTitle)
	string panelTitle

	return panelTitle + "#Labnotebook"
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
		PopupMenu popup_labenotebookViewableCols, win=$panelTitleNew, value=#("\"" + NONE + "\"")
		return NaN
	endif

	panelTitleNew = UniqueName("DB_" + device, 9, 0)
	DoWindow/W=$panelTitle/C $panelTitleNew

	SetWindow $panelTitleNew, userdata($MIES_PANEL_TYPE_USER_DATA) = MIES_DATABROWSER_PANEL
	SetWindow $panelTitleNew, userdata(DataFolderPath)   = GetDevicePathAsString(device)
	PopupMenu popup_labenotebookViewableCols, win=$panelTitleNew, value=#("DB_GetLabNotebookViewAbleCols(\"" + panelTitleNew + "\")")
	DB_PlotSweep(panelTitleNew, currentSweep=0)
End

static Function/S DB_GetListOfSweepWaves(panelTitle)
	string panelTitle

	dfref dfr = DB_GetDataPath(panelTitle)

	if(!DataFolderExistsDFR(dfr))
		return ""
	endif

	return GetListOfWaves(dfr, DATA_SWEEP_REGEXP, waveProperty="MINCOLS:2")
End

static Function DB_FirstAndLastSweepAcquired(panelTitle, first, last)
	string panelTitle
	variable &first, &last

	string list

	first = 0
	last  = 0

	list = DB_GetListOfSweepWaves(panelTitle)

	if(!isEmpty(list))
		first = NumberByKey("Sweep", list, "_")
		last = ItemsInList(list) - 1 + first
	endif

	SetValDisplaySingleVariable(panelTitle, "valdisp_DataBrowser_LastSweep", last)
	SetVariable setvar_DataBrowser_SweepNo win = $panelTitle, limits = {first, last, 1}
End

static Function DB_ClipSweepNumber(panelTitle, sweepNo)
	string panelTitle
	variable sweepNo

	variable firstSweep, lastSweep

	DB_FirstAndLastSweepAcquired(panelTitle, firstSweep, lastSweep)

	// handles situation where data sweep number starts at a value greater than the controls number
	// usually occurs after locking when control is set to zero
	if(sweepNo < firstSweep)
		sweepNo = firstSweep
	elseif(sweepNo > lastSweep)
		sweepNo = lastSweep
	endif

	return sweepNo
End

/// @brief Plot the given sweep in the locked Data Browser
///
/// @param panelTitle                                                                     locked databrowser
/// @param currentSweep [optional, defaults to the value of `setvar_DataBrowser_SweepNo`] currently displayed sweep or last
/// @param newSweep [optional, defaults to currentSweep]                                  new sweep to display
/// @param direction [optional, ignored by default]                                       numerical offset relative to currentSweep to calculate newSweep
/// newSweep is clipped to a valid sweep number
static Function DB_PlotSweep(panelTitle, [currentSweep, newSweep, direction])
	string panelTitle
	variable currentSweep
	variable newSweep, direction

	string subWindow = DB_GetNotebookSubWindow(panelTitle)
	string graph = DB_GetMainGraph(panelTitle)

	string traceList, trace, device
	variable numTraces, i, sweepNo
	variable firstSweep, lastSweep
	variable newWaveDisplayed, currentWaveDisplayed

	DFREF dfr = DB_GetDataPath(panelTitle)

	if(!DataFolderExistsDFR(dfr))
		return NaN
	endif

	Struct PostPlotSettings pps
	device = GetPopupMenuString(panelTitle, "popup_DB_lockedDevices")
	pps.averageDataFolder = GetDeviceDataBrowserPath(device)
	pps.averageTraces     = GetCheckboxState(panelTitle, "check_DataBrowser_AverageTraces")
	pps.zeroTraces        = GetCheckBoxState(panelTitle, "check_DataBrowser_ZeroTraces")
	pps.timeAlignRefTrace = ""
	pps.timeAlignMode     = TIME_ALIGNMENT_NONE
	FUNCREF FinalUpdateHookProto pps.finalUpdateHook = DB_PanelUpdate

	if(ParamIsDefault(currentSweep))
		currentSweep = GetSetVariable(panelTitle, "setvar_DataBrowser_SweepNo")
	endif

	if(ParamIsDefault(newSweep) && ParamIsDefault(direction))
		newSweep = currentSweep
	elseif(ParamIsDefault(direction))
		// just use newSweep
	elseif(ParamIsDefault(newSweep))
		newSweep = currentSweep + direction * GetSetVariable(panelTitle, "setvar_DataBrowser_SweepStep")
	else
		ASSERT(0, "Can not accept both newSweep and direction")
	endif

	newSweep = DB_ClipSweepNumber(panelTitle, newSweep)

	// With overlay enabled:
	// if the last plotted sweep is already on the graph remove it and return
	// otherwise clear the plot
	if(GetCheckBoxState(panelTitle, "check_DataBrowser_SweepOverlay"))

		WAVE/Z/SDFR=dfr newSweepWave = $("Sweep_" + num2str(newSweep))
		WAVE/Z/SDFR=dfr currentSweepWave = $("Sweep_" + num2str(currentSweep))

		newWaveDisplayed     = IsWaveDisplayedOnGraph(graph, wv=newSweepWave)
		currentWaveDisplayed = IsWaveDisplayedOnGraph(graph, wv=currentSweepWave)

		if(newWaveDisplayed && currentWaveDisplayed && !WaveRefsEqual(newSweepWave, currentSweepWave))
			RemoveTracesFromGraph(graph, wv=currentSweepWave)
			sweepNo = DB_ClipSweepNumber(panelTitle, newSweep)
			SetSetVariable(panelTitle, "setvar_DataBrowser_SweepNo", sweepNo)
			DB_SetFormerSweepNumber(panelTitle, sweepNo)
			PostPlotTransformations(graph, pps)
			return NaN
		elseif(newWaveDisplayed)
			PostPlotTransformations(graph, pps)
			return NaN
		endif
	endif

	SetSetVariable(panelTitle, "setvar_DataBrowser_SweepNo", newSweep)
	Wave/Z/SDFR=dfr wv = $("Sweep_" + num2str(newSweep))

	if(WaveExists(wv))
		DB_TilePlotForDataBrowser(panelTitle, wv, newSweep)
		Notebook $subWindow selection={startOfFile, endOfFile} // select entire contents of notebook
		Notebook $subWindow text = "Sweep note: \r " + note(wv) // replaces selected notebook content with new wave note.
		DB_SetFormerSweepNumber(panelTitle, newSweep)
	else
		Notebook $subWindow selection={startOfFile, endOfFile}
		Notebook $subWindow text = "Sweep does not exist."
		if(!GetCheckBoxState(panelTitle, "check_DataBrowser_SweepOverlay"))
			RemoveTracesFromGraph(DB_GetMainGraph(panelTitle))
		endif
	endif

	PostPlotTransformations(graph, pps)
End

static Function DB_TilePlotForDataBrowser(panelTitle, sweep, sweepNo)
	string panelTitle
	wave sweep
	variable sweepNo

	dfref dfr = DB_GetDataPath(panelTitle)
	if(!DataFolderExistsDFR(dfr))
		printf "Datafolder for %s does not exist\r", panelTitle
		return NaN
	endif

	Wave config              = GetConfigWave(sweep)
	string graph             = DB_GetMainGraph(panelTitle)
	Wave settingsHistory     = DB_GetSettingsHistory(panelTitle)
	Wave settingsHistoryText = DB_GetSettingsHistoryText(panelTitle)

	STRUCT TiledGraphSettings tgs
	tgs.displayDAC      = GetCheckBoxState(panelTitle, "check_DataBrowser_DisplayDAchan")
	tgs.displayTTL      = GetCheckBoxState(panelTitle, "check_DataBrowser_DisplayTTL")
	tgs.displayADC      = GetCheckBoxState(panelTitle, "check_DataBrowser_DisplayADChan")
	tgs.overlaySweep    = GetCheckBoxState(panelTitle, "check_DataBrowser_SweepOverlay")
	tgs.overlayChannels = GetCheckBoxState(panelTitle, "check_databrowser_OverlayChan")
	tgs.dDAQDisplayMode = GetCheckBoxState(panelTitle, "check_databrowser_dDAQMode")

	return CreateTiledChannelGraph(graph, config, sweepNo, settingsHistory, settingsHistoryText, tgs, sweepWave=sweep)
End

static Function DB_ClearGraph(panelTitle)
	string panelTitle

	string graph = DB_GetLabNoteBookGraph(panelTitle)
	RemoveTracesFromGraph(graph)
	UpdateLBGraphLegend(graph)
End

static Function/WAVE DB_GetSettingsHistory(panelTitle)
	string panelTitle

	return GetNumDocWave(GetPopupMenuString(panelTitle, "popup_DB_lockedDevices"))
End

static Function/WAVE DB_GetSettingsHistoryText(panelTitle)
	string panelTitle

	return GetTextDocWave(GetPopupMenuString(panelTitle, "popup_DB_lockedDevices"))
End

static Function/WAVE DB_GetSettingsHistoryKeys(panelTitle)
	string panelTitle

	return GetNumDocKeyWave(GetPopupMenuString(panelTitle, "popup_DB_lockedDevices"))
End

static Function/WAVE DB_GetSettingsHistoryTextKeys(panelTitle)
	string panelTitle

	return GetTextDocKeyWave(GetPopupMenuString(panelTitle, "popup_DB_lockedDevices"))
End

Function DB_UpdateToLastSweep(panel)
	string panel

	if(GetCheckBoxState(panel, "check_DataBrowser_AutoUpdate"))
		DB_PlotSweep(panel, newSweep=Inf)
	endif
End

Window DataBrowser() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(132,158,1345,878) /K=1 as "DataBrowser"
	Button button_DataBrowser_NextSweep,pos={628,628},size={395,36},proc=DB_ButtonProc_Sweep,title="Next Sweep \\W649"
	Button button_DataBrowser_NextSweep,userdata(ResizeControlsInfo)= A"!!,J.!!#D-!!#C*J,hnIz!!#N3Bk1ct<C^(Dzzzzzzzzzzzzz!!#N3Bk1ct<C^(Dz"
	Button button_DataBrowser_NextSweep,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#?(FEDG<zzzzzzzzzzz"
	Button button_DataBrowser_NextSweep,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	Button button_DataBrowser_NextSweep,fSize=20
	Button button_DataBrowser_NextSweep help={"Displays the next sweep (sweep no. = last sweep number + step)"}
	Button button_DataBrowser_PrevSweep,pos={18,626},size={425,43},proc=DB_ButtonProc_Sweep,title="\\W646 Previous Sweep"
	Button button_DataBrowser_PrevSweep,userdata(ResizeControlsInfo)= A"!!,BI!!#D,J,hsdJ,hnez!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_DataBrowser_PrevSweep,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#?(FEDG<zzzzzzzzzzz"
	Button button_DataBrowser_PrevSweep,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	Button button_DataBrowser_PrevSweep,fSize=20
	Button button_DataBrowser_PrevSweep help={"Displays the previous sweep (sweep no. = last sweep number - step)"}	
	ValDisplay valdisp_DataBrowser_LastSweep,pos={531,634},size={86,30},bodyWidth=60,title="of"
	ValDisplay valdisp_DataBrowser_LastSweep,userdata(ResizeControlsInfo)= A"!!,Ij^]6bDJ,hp;!!#=Sz!!#](Aon\"q<C^(Dzzzzzzzzzzzzz!!#](Aon\"q<C^(Dz"
	ValDisplay valdisp_DataBrowser_LastSweep,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#?(FEDG<zzzzzzzzzzz"
	ValDisplay valdisp_DataBrowser_LastSweep,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	ValDisplay valdisp_DataBrowser_LastSweep,fSize=24,frame=2,fStyle=1
	ValDisplay valdisp_DataBrowser_LastSweep,limits={0,0,0},barmisc={0,1000}
	ValDisplay valdisp_DataBrowser_LastSweep,value= #"0"
	ValDisplay valdisp_DataBrowser_LastSweep,barBackColor= (56576,56576,56576)
	ValDisplay valdisp_DataBrowser_LastSweep help={"The number of the last sweep acquired for the device assigned to the data browser"}
	CheckBox check_DataBrowser_DisplayDAchan,pos={20,6},size={116,14},proc=DB_CheckProc_ChangedSetting,title="Display DA channels"
	CheckBox check_DataBrowser_DisplayDAchan,userdata(ResizeControlsInfo)= A"!!,BY!!#:\"!!#@L!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_DataBrowser_DisplayDAchan,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_DataBrowser_DisplayDAchan,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_DataBrowser_DisplayDAchan,value= 0
	CheckBox check_DataBrowser_DisplayDAchan help={"Display DA (digital to analog) channel data"}
	CheckBox check_databrowser_OverlayChan,pos={205.00,27.00},size={107.00,15.00},proc=DB_CheckProc_ChangedSetting,title="Overlay Channels"
	CheckBox check_databrowser_OverlayChan,userdata(ResizeControlsInfo)= A"!!,G]!!#=;!!#@:!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_databrowser_OverlayChan,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_databrowser_OverlayChan,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_databrowser_OverlayChan,value= 0
	CheckBox check_databrowser_OverlayChan help={"Displays all channels using a single  vertical axis"}
	CheckBox check_databrowser_dDAQMode,pos={205.00,47.00},size={85.00,15.00},proc=DB_CheckProc_ChangedSetting,title="dDAQ Viewer"
	CheckBox check_databrowser_dDAQMode,help={"Enable dedicated support for viewing distributed DAQ data"}
	CheckBox check_databrowser_dDAQMode,value= 0
	CheckBox check_databrowser_dDAQMode,userdata(ResizeControlsInfo)= A"!!,G]!!#>J!!#?c!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_databrowser_dDAQMode,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_databrowser_dDAQMode,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	TitleBox ListBox_DataBrowser_NoteDisplay,pos={1759,75},size={197,39}
	TitleBox ListBox_DataBrowser_NoteDisplay,userdata(ResizeControlsInfo)= A"!!,LBhuH*0!!#AT!!#>*z!!#o2B4uAezzzzzzzzzzzzzz!!#o2B4uAezz"
	TitleBox ListBox_DataBrowser_NoteDisplay,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	TitleBox ListBox_DataBrowser_NoteDisplay,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	TitleBox ListBox_DataBrowser_NoteDisplay,labelBack=(62208,62208,62208),fSize=8
	TitleBox ListBox_DataBrowser_NoteDisplay,frame=0
	CheckBox check_DataBrowser_SweepOverlay,pos={205,6},size={95,14},proc=DB_CheckProc_ChangedSetting,title="Overlay Sweeps"
	CheckBox check_DataBrowser_SweepOverlay,userdata(ResizeControlsInfo)= A"!!,G]!!#:\"!!#@\"!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_DataBrowser_SweepOverlay,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_DataBrowser_SweepOverlay,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_DataBrowser_SweepOverlay,value= 0
	CheckBox check_DataBrowser_SweepOverlay help={"Adds unplotted sweep to graph. Removes plotted sweep from graph."}
	CheckBox check_DataBrowser_AutoUpdate,pos={602,6},size={149,14},title="Display last sweep acquired"
	CheckBox check_DataBrowser_AutoUpdate,userdata(ResizeControlsInfo)= A"!!,J'J,hjM!!#A$!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_DataBrowser_AutoUpdate,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_DataBrowser_AutoUpdate,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_DataBrowser_AutoUpdate,value= 0
	CheckBox check_DataBrowser_AutoUpdate help={"Displays the last sweep acquired when data acquistion is ongoing"}
	PopupMenu popup_DB_lockedDevices,pos={639,673},size={266,21},proc=DB_PopMenuProc_LockDBtoDevice,bodyWidth=170,title="Device assingment:"
	PopupMenu popup_DB_lockedDevices,userdata(ResizeControlsInfo)= A"!!,J0^]6bN5QF0*!!#<`z!!#N3Bk1ct<C^(Dzzzzzzzzzzzzz!!#N3Bk1ct<C^(Dz"
	PopupMenu popup_DB_lockedDevices,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#?(FEDG<!(TR7zzzzzzzzzz"
	PopupMenu popup_DB_lockedDevices,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<!(TR7zzzzzzzzzzzzz!!!"
	PopupMenu popup_DB_lockedDevices,mode=1,popvalue="- none -",value= #"DB_GetAllDevicesWithData()"
	PopupMenu popup_DB_lockedDevices help={"Select a data acquistion device to display data"}
	CheckBox check_DataBrowser_DisplayTTL,pos={21,30},size={122,14},proc=DB_CheckProc_ChangedSetting,title="Display TTL Channels"
	CheckBox check_DataBrowser_DisplayTTL,userdata(ResizeControlsInfo)= A"!!,Ba!!#=S!!#@X!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_DataBrowser_DisplayTTL,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_DataBrowser_DisplayTTL,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox check_DataBrowser_DisplayTTL,value= 0
	CheckBox check_DataBrowser_DisplayTTL help={"Display TTL channel data"}
	CheckBox check_DataBrowser_DisplayADChan,pos={21,52},size={117,14},proc=DB_CheckProc_ChangedSetting,title="Display AD Channels"
	CheckBox check_DataBrowser_DisplayADChan,userdata(ResizeControlsInfo)= A"!!,Ba!!#>^!!#@N!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_DataBrowser_DisplayADChan,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_DataBrowser_DisplayADChan,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox check_DataBrowser_DisplayADChan,value= 1
	CheckBox check_DataBrowser_DisplayADChan help={"Display AD (analog to digital) channel data"}
	CheckBox check_DataBrowser_AverageTraces,pos={429,36},size={90,14},proc=DB_CheckProc_ChangedSetting,title="Average traces"
	CheckBox check_DataBrowser_AverageTraces,userdata(ResizeControlsInfo)= A"!!,I<J,hnI!!#?m!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_DataBrowser_AverageTraces,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_DataBrowser_AverageTraces,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_DataBrowser_AverageTraces,value= 0
	CheckBox check_DataBrowser_AverageTraces help={"Displays the average (pink trace) of overlayed sweeps for each channel"}
	Button button_DataBrowser_setaxis,pos={20,681},size={150,23},proc=DB_ButtonProc_AutoScale,title="Autoscale"
	Button button_DataBrowser_setaxis,userdata(ResizeControlsInfo)= A"!!,BY!!#D:5QF.e!!#<pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_DataBrowser_setaxis,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#?(FEDG<zzzzzzzzzzz"
	Button button_DataBrowser_setaxis,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	Button button_DataBrowser_setaxis help={"Autoscale sweep data"}
	SetVariable setvar_DataBrowser_SweepNo,pos={454,634},size={74,32},proc=DB_SetVarProc_SweepNo
	SetVariable setvar_DataBrowser_SweepNo,userdata(ResizeControlsInfo)= A"!!,II!!#D.J,hp#!!#=cz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_DataBrowser_SweepNo,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#?(FEDG<zzzzzzzzzzz"
	SetVariable setvar_DataBrowser_SweepNo,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_DataBrowser_SweepNo,userdata(lastSweep)=  "NaN",fSize=24
	SetVariable setvar_DataBrowser_SweepNo,limits={0,0,1},value= _NUM:0,live= 1
	SetVariable setvar_DataBrowser_SweepNo help={"Sweep number of last sweep plotted"}
	PopupMenu popup_labenotebookViewableCols,pos={1045,455},size={150,21},bodyWidth=150,proc=DB_PopMenuProc_LabNotebook
	PopupMenu popup_labenotebookViewableCols,userdata(ResizeControlsInfo)= A"!!,K>TE%@>J,hqP!!#<`z!!#N3Bk1ct<C^(Dzzzzzzzzzzzzz!!#N3Bk1ct<C^(Dz"
	PopupMenu popup_labenotebookViewableCols,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#N3Bk1ct<C]S7zzzzzzzzzz"
	PopupMenu popup_labenotebookViewableCols,userdata(ResizeControlsInfo) += A"zzz!!#N3Bk1ct<C]S7zzzzzzzzzzzzz!!!"
	PopupMenu popup_labenotebookViewableCols,mode=1,popvalue="- none -",value= #"\"- none -\""
	PopupMenu popup_labenotebookViewableCols help={"Select numeric lab notebook data to display"}
	Button button_clearlabnotebookgraph,pos={1072,495},size={80,20},proc=DB_ButtonProc_ClearGraph,title="Clear graph"
	Button button_clearlabnotebookgraph,userdata(ResizeControlsInfo)= A"!!,KB!!#C\\J,hp/!!#<Xz!!#N3Bk1ct<C^(Dzzzzzzzzzzzzz!!#N3Bk1ct<C^(Dz"
	Button button_clearlabnotebookgraph,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#N3Bk1ct<C]S7zzzzzzzzzz"
	Button button_clearlabnotebookgraph,userdata(ResizeControlsInfo) += A"zzz!!#N3Bk1ct<C]S7zzzzzzzzzzzzz!!!"
	Button button_switchxaxis help={"Toggle lab notebook horizontal axis between time of day or sweep number"}
	GroupBox group_labnotebook_ctrls,pos={1036,439},size={169,47},title="Settings History Column"
	GroupBox group_labnotebook_ctrls,userdata(ResizeControlsInfo)= A"!!,K=J,hskJ,hqc!!#>Jz!!#N3Bk1ct<C^(Dzzzzzzzzzzzzz!!#N3Bk1ct<C^(Dz"
	GroupBox group_labnotebook_ctrls,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#N3Bk1ct<C]S7zzzzzzzzzz"
	GroupBox group_labnotebook_ctrls,userdata(ResizeControlsInfo) += A"zzz!!#N3Bk1ct<C]S7zzzzzzzzzzzzz!!!"
	Button button_switchxaxis,pos={1074,522},size={80,20},proc=DB_ButtonProc_SwitchXAxis,title="Switch X-axis"
	Button button_switchxaxis,userdata(ResizeControlsInfo)= A"!!,KB5QF1RJ,hp/!!#<Xz!!#N3Bk1ct<C^(Dzzzzzzzzzzzzz!!#N3Bk1ct<C^(Dz"
	Button button_switchxaxis,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#N3Bk1ct<C]S7zzzzzzzzzz"
	Button button_switchxaxis,userdata(ResizeControlsInfo) += A"zzz!!#N3Bk1ct<C]S7zzzzzzzzzzzzz!!!"
	Button button_switchxaxis help={"Toggle lab notebook horizontal axis between time of day or sweep number"}
	CheckBox check_DataBrowser_ZeroTraces,pos={529,37},size={72,14},proc=DB_CheckProc_ChangedSetting,title="Zero traces"
	CheckBox check_DataBrowser_ZeroTraces,userdata(ResizeControlsInfo)= A"!!,Ij5QF+b!!#?I!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_DataBrowser_ZeroTraces,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_DataBrowser_ZeroTraces,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_DataBrowser_ZeroTraces,value= 0
	CheckBox check_DataBrowser_ZeroTraces help={"Sets the baseline of the sweep to zero by differentiating and the integrating a copy of the sweep"}
	SetVariable setvar_DataBrowser_SweepStep,pos={499,674},size={66,16},bodyWidth=40,title="Step"
	SetVariable setvar_DataBrowser_SweepStep,userdata(ResizeControlsInfo)= A"!!,I_J,htcJ,hoh!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_DataBrowser_SweepStep,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#?(FEDG<zzzzzzzzzzz"
	SetVariable setvar_DataBrowser_SweepStep,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_DataBrowser_SweepStep,userdata(lastSweep)=  "0",fSize=12
	SetVariable setvar_DataBrowser_SweepStep help={"Set the increment between sweeps"}
	SetVariable setvar_DataBrowser_SweepStep,limits={1,inf,1},value= _NUM:1
	CheckBox checkbox_DB_AutoScaleVertAxVisX,pos={179,685},size={42,14},proc=DB_ScaleAxis,title="Vis X"
	CheckBox checkbox_DB_AutoScaleVertAxVisX,help={"Scale the y axis to the visible x data range"}
	CheckBox checkbox_DB_AutoScaleVertAxVisX,userdata(ResizeControlsInfo)= A"!!,GD!!#D:5QF.+!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox checkbox_DB_AutoScaleVertAxVisX,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#?(FEDG<zzzzzzzzzzz"
	CheckBox checkbox_DB_AutoScaleVertAxVisX,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	CheckBox checkbox_DB_AutoScaleVertAxVisX,value= 0
	DefineGuide UGV0={FR,-200},UGH1={FT,0.584722,FB},UGH0={UGH1,0.662207,FB}
	SetWindow kwTopWin,hook(ResizeControls)=ResizeControls#ResizeControlsHook
	SetWindow kwTopWin,userdata(ResizeControlsInfo)= A"!!*'\"z!!#ERTE%A:zzzzzzzzzzzzzzzzzzzzz"
	SetWindow kwTopWin,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzzzzzzzzzzzzzzz"
	SetWindow kwTopWin,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzzzzzzzzz!!!"
	SetWindow kwTopWin,userdata(ResizeControlsGuides)=  "UGV0;UGH1;UGH0;"
	SetWindow kwTopWin,userdata(ResizeControlsInfoUGV0)= A":-hTC3`S[N0KW?-:-(dOFC@LVDg-86E][6':dmEFF(KAR85E,T>#.mm5tj<n4&A^O8Q88W:-(*`0f(m]<CoSI0fhd%4%E:B6q&jl4&SL@:et\"]<(Tk\\3\\<*@0KT"
	SetWindow kwTopWin,userdata(ResizeControlsInfoUGH1)= A":-hTC3`S[@0frH.:-(dOFC@LVDg-86E][6':dmEFF(KAR85E,T>#.mm5tj<o4&A^O8Q88W:-(3e0fqm*8OQ!%3_!(17o`,K75?nn69A(69MeM`8Q88W:-(']2)mEO1,:o"
	SetWindow kwTopWin,userdata(ResizeControlsInfoUGH0)= A":-hTC3`S[@0KW?-:-(dOFC@LVDg-86E][6':dmEFF(KAR85E,T>#.mm5tj<o4&A^O8Q88W:-(9f3BK`28OQ!%3`S[@0fqm*8OQ!&3^uFt;FO8U:K'ha8P`)B0J57A1,:OB3r"
	Display/W=(18,72,1039,362)/FG=(,,UGV0,UGH1)/HOST=#
	SetWindow kwTopWin,userdata(MiesPanelType)=  "DataBrowser"
	RenameWindow #,DataBrowserGraph
	SetActiveSubwindow ##
	NewNotebook /F=1 /N=WaveNoteDisplay /W=(1052,72,1220,341)/FG=(UGV0,,FR,UGH1) /HOST=# /OPTS=10
	Notebook kwTopWin, defaultTab=36, statusWidth=0, autoSave=1, showRuler=0, rulerUnits=1
	Notebook kwTopWin newRuler=Normal, justification=0, margins={0,0,127}, spacing={0,0,0}, tabs={}, rulerDefaults={"Arial",10,0,(0,0,0)}
	Notebook kwTopWin, zdata= "GaqDU%ejN7!Z)ts!b+VAAccFQf<WF*6ioh3ac'6&\":'pGblu%.:d-YZK%8.G#03I^`#KnXR/m<e<!k&"
	Notebook kwTopWin, zdataEnd= 1
	RenameWindow #,WaveNoteDisplay
	SetActiveSubwindow ##
	Display/W=(17,427,1051,614)/FG=(,UGH1,UGV0,UGH0)/HOST=#
	ModifyGraph margin(right)=74
	TextBox/C/N=text0/F=0/B=1/X=0.50/Y=2.02/E=2 ""
	RenameWindow #,LabNoteBook
	SetActiveSubwindow ##
EndMacro

Window DataBrowser_IP7() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /K=1 /W=(2037,71,3250,791) as "DataBrowser"
	SetDrawLayer UserBack
	Button button_DataBrowser_NextSweep,pos={628.00,630.00},size={425.00,45.00},proc=DB_ButtonProc_Sweep,title="Next Sweep \\W649"
	Button button_DataBrowser_NextSweep,userdata(ResizeControlsInfo)= A"!!,J.!!#D-J,hsdJ,hnmz!!#](Aon\"q<C^(Dzzzzzzzzzzzzz!!#](Aon\"q<C^(Dz"
	Button button_DataBrowser_NextSweep,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#?(FEDG<zzzzzzzzzzz"
	Button button_DataBrowser_NextSweep,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	Button button_DataBrowser_NextSweep,fSize=20
	Button button_DataBrowser_NextSweep help={"Displays the next sweep (sweep no. = last sweep number + step)"}
	Button button_DataBrowser_PrevSweep,pos={20.00,630.00},size={425.00,45.00},proc=DB_ButtonProc_Sweep,title="\\W646 Previous Sweep"
	Button button_DataBrowser_PrevSweep,userdata(ResizeControlsInfo)= A"!!,BY!!#D-J,hsdJ,hnmz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_DataBrowser_PrevSweep,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#?(FEDG<zzzzzzzzzzz"
	Button button_DataBrowser_PrevSweep,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	Button button_DataBrowser_PrevSweep,fSize=20
	Button button_DataBrowser_PrevSweep help={"Displays the previous sweep (sweep no. = last sweep number - step)"}
	ValDisplay valdisp_DataBrowser_LastSweep,pos={530.00,634.00},size={89.00,34.00},bodyWidth=60,title="of"
	ValDisplay valdisp_DataBrowser_LastSweep,userdata(ResizeControlsInfo)= A"!!,IjJ,htYJ,hpA!!#=kz!!#](Aon\"q<C^(Dzzzzzzzzzzzzz!!#](Aon\"q<C^(Dz"
	ValDisplay valdisp_DataBrowser_LastSweep,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#?(FEDG<zzzzzzzzzzz"
	ValDisplay valdisp_DataBrowser_LastSweep,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	ValDisplay valdisp_DataBrowser_LastSweep,fSize=24,frame=2,fStyle=1
	ValDisplay valdisp_DataBrowser_LastSweep,limits={0,0,0},barmisc={0,1000}
	ValDisplay valdisp_DataBrowser_LastSweep,value= #"0"
	ValDisplay valdisp_DataBrowser_LastSweep,barBackColor= (56576,56576,56576)
	ValDisplay valdisp_DataBrowser_LastSweep help={"The number of the last sweep acquired for the device assigned to the data browser"}
	CheckBox check_DataBrowser_DisplayDAchan,pos={20.00,9.00},size={122.00,15.00},proc=DB_CheckProc_ChangedSetting,title="Display DA channels"
	CheckBox check_DataBrowser_DisplayDAchan,userdata(ResizeControlsInfo)= A"!!,BY!!#:r!!#@X!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_DataBrowser_DisplayDAchan,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_DataBrowser_DisplayDAchan,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_DataBrowser_DisplayDAchan,value= 0
	CheckBox check_DataBrowser_DisplayDAchan help={"Display DA (digital to analog) channel data"}
	CheckBox check_databrowser_OverlayChan,pos={205.00,27.00},size={107.00,15.00},proc=DB_CheckProc_ChangedSetting,title="Overlay Channels"
	CheckBox check_databrowser_OverlayChan,userdata(ResizeControlsInfo)= A"!!,G]!!#=;!!#@:!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_databrowser_OverlayChan,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_databrowser_OverlayChan,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_databrowser_OverlayChan,value= 0
	CheckBox check_databrowser_OverlayChan help={"Displays all channels using a single  vertical axis"}
	CheckBox check_databrowser_dDAQMode,pos={205.00,47.00},size={85.00,15.00},proc=DB_CheckProc_ChangedSetting,title="dDAQ Viewer"
	CheckBox check_databrowser_dDAQMode,help={"Enable dedicated support for viewing distributed DAQ data"}
	CheckBox check_databrowser_dDAQMode,value= 0
	CheckBox check_databrowser_dDAQMode,userdata(ResizeControlsInfo)= A"!!,G]!!#>J!!#?c!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_databrowser_dDAQMode,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_databrowser_dDAQMode,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	TitleBox ListBox_DataBrowser_NoteDisplay,pos={1759.00,75.00},size={197.00,39.00}
	TitleBox ListBox_DataBrowser_NoteDisplay,userdata(ResizeControlsInfo)= A"!!,LBhuH*0!!#AT!!#>*z!!#o2B4uAezzzzzzzzzzzzzz!!#o2B4uAezz"
	TitleBox ListBox_DataBrowser_NoteDisplay,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	TitleBox ListBox_DataBrowser_NoteDisplay,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	TitleBox ListBox_DataBrowser_NoteDisplay,labelBack=(62208,62208,62208),fSize=8
	TitleBox ListBox_DataBrowser_NoteDisplay,frame=0
	CheckBox check_DataBrowser_SweepOverlay,pos={205.00,9.00},size={97.00,15.00},proc=DB_CheckProc_ChangedSetting,title="Overlay Sweeps"
	CheckBox check_DataBrowser_SweepOverlay,userdata(ResizeControlsInfo)= A"!!,G]!!#:r!!#@&!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_DataBrowser_SweepOverlay,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_DataBrowser_SweepOverlay,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_DataBrowser_SweepOverlay,value= 0
	CheckBox check_DataBrowser_SweepOverlay help={"Adds unplotted sweep to graph. Removes plotted sweep from graph."}
	CheckBox check_DataBrowser_AutoUpdate,pos={484.00,9.00},size={159.00,15.00},title="Display last sweep acquired"
	CheckBox check_DataBrowser_AutoUpdate,userdata(ResizeControlsInfo)= A"!!,IX!!#:r!!#A.!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_DataBrowser_AutoUpdate,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_DataBrowser_AutoUpdate,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_DataBrowser_AutoUpdate,value= 0
	CheckBox check_DataBrowser_AutoUpdate help={"Displays the last sweep acquired when data acquistion is ongoing"}
	PopupMenu popup_DB_lockedDevices,pos={639.00,684.00},size={275.00,19.00},proc=DB_PopMenuProc_LockDBtoDevice,bodyWidth=170,title="Device assingment:"
	PopupMenu popup_DB_lockedDevices,userdata(ResizeControlsInfo)= A"!!,J0^]6bQ!!#BCJ,hm&z!!#](Aon\"q<C^(Dzzzzzzzzzzzzz!!#](Aon\"q<C^(Dz"
	PopupMenu popup_DB_lockedDevices,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#?(FEDG<!(TR7zzzzzzzzzz"
	PopupMenu popup_DB_lockedDevices,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<!(TR7zzzzzzzzzzzzz!!!"
	PopupMenu popup_DB_lockedDevices,mode=1,popvalue="- none -",value= #"DB_GetAllDevicesWithData()"
	PopupMenu popup_DB_lockedDevices help={"Select a data acquistion device to display data"}
	CheckBox check_DataBrowser_DisplayTTL,pos={20.00,27.00},size={128.00,15.00},proc=DB_CheckProc_ChangedSetting,title="Display TTL Channels"
	CheckBox check_DataBrowser_DisplayTTL,userdata(ResizeControlsInfo)= A"!!,BY!!#=;!!#@d!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_DataBrowser_DisplayTTL,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_DataBrowser_DisplayTTL,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox check_DataBrowser_DisplayTTL,value= 0
	CheckBox check_DataBrowser_DisplayTTL help={"Display TTL channel data"}
	CheckBox check_DataBrowser_DisplayADChan,pos={20.00,45.00},size={124.00,15.00},proc=DB_CheckProc_ChangedSetting,title="Display AD Channels"
	CheckBox check_DataBrowser_DisplayADChan,userdata(ResizeControlsInfo)= A"!!,BY!!#>B!!#@\\!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_DataBrowser_DisplayADChan,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_DataBrowser_DisplayADChan,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox check_DataBrowser_DisplayADChan,value= 1
	CheckBox check_DataBrowser_DisplayADChan help={"Display AD (analog to digital) channel data"}
	CheckBox check_DataBrowser_AverageTraces,pos={349.00,9.00},size={92.00,15.00},proc=DB_CheckProc_ChangedSetting,title="Average traces"
	CheckBox check_DataBrowser_AverageTraces,userdata(ResizeControlsInfo)= A"!!,HiJ,hkH!!#?q!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_DataBrowser_AverageTraces,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_DataBrowser_AverageTraces,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_DataBrowser_AverageTraces,value= 0
	CheckBox check_DataBrowser_AverageTraces help={"Displays the average (pink trace) of overlayed sweeps for each channel"}
	Button button_DataBrowser_setaxis,pos={20.00,682.00},size={150.00,23.00},proc=DB_ButtonProc_AutoScale,title="Autoscale"
	Button button_DataBrowser_setaxis,userdata(ResizeControlsInfo)= A"!!,BY!!#D:J,hqP!!#<pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_DataBrowser_setaxis,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#?(FEDG<zzzzzzzzzzz"
	Button button_DataBrowser_setaxis,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	Button button_DataBrowser_setaxis help={"Autoscale sweep data"}
	SetVariable setvar_DataBrowser_SweepNo,pos={454.00,634.00},size={74.00,35.00},proc=DB_SetVarProc_SweepNo
	SetVariable setvar_DataBrowser_SweepNo,userdata(ResizeControlsInfo)= A"!!,II!!#D.J,hp#!!#=oz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_DataBrowser_SweepNo,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#?(FEDG<zzzzzzzzzzz"
	SetVariable setvar_DataBrowser_SweepNo,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_DataBrowser_SweepNo,userdata(lastSweep)=  "NaN",fSize=24
	SetVariable setvar_DataBrowser_SweepNo,limits={0,0,1},value= _NUM:0,live= 1
	SetVariable setvar_DataBrowser_SweepNo help={"Sweep number of last sweep plotted"}
	PopupMenu popup_labenotebookViewableCols,pos={1043.00,458.00},size={153.00,19.00},bodyWidth=150,proc=DB_PopMenuProc_LabNotebook
	PopupMenu popup_labenotebookViewableCols,userdata(ResizeControlsInfo)= A"!!,K>?iWRU!!#A(!!#<Pz!!#N3Bk1ct<C^(Dzzzzzzzzzzzzz!!#N3Bk1ct<C^(Dz"
	PopupMenu popup_labenotebookViewableCols,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#N3Bk1ct<C]S7zzzzzzzzzz"
	PopupMenu popup_labenotebookViewableCols,userdata(ResizeControlsInfo) += A"zzz!!#N3Bk1ct<C]S7zzzzzzzzzzzzz!!!"
	PopupMenu popup_labenotebookViewableCols,mode=1,popvalue="- none -",value= #"\"- none -\""
	PopupMenu popup_labenotebookViewableCols help={"Select numeric lab notebook data to display"}
	Button button_clearlabnotebookgraph,pos={1043.00,498.00},size={80.00,20.00},proc=DB_ButtonProc_ClearGraph,title="Clear graph"
	Button button_clearlabnotebookgraph,userdata(ResizeControlsInfo)= A"!!,K>?iWRi!!#?Y!!#<Xz!!#N3Bk1ct<C^(Dzzzzzzzzzzzzz!!#N3Bk1ct<C^(Dz"
	Button button_clearlabnotebookgraph,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#N3Bk1ct<C]S7zzzzzzzzzz"
	Button button_clearlabnotebookgraph,userdata(ResizeControlsInfo) += A"zzz!!#N3Bk1ct<C]S7zzzzzzzzzzzzz!!!"
	Button button_switchxaxis help={"Toggle lab notebook horizontal axis between time of day or sweep number"}
	GroupBox group_labnotebook_ctrls,pos={1036.00,439.00},size={169.00,47.00},title="Settings History Column"
	GroupBox group_labnotebook_ctrls,userdata(ResizeControlsInfo)= A"!!,K=J,hskJ,hqc!!#>Jz!!#N3Bk1ct<C^(Dzzzzzzzzzzzzz!!#N3Bk1ct<C^(Dz"
	GroupBox group_labnotebook_ctrls,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#N3Bk1ct<C]S7zzzzzzzzzz"
	GroupBox group_labnotebook_ctrls,userdata(ResizeControlsInfo) += A"zzz!!#N3Bk1ct<C]S7zzzzzzzzzzzzz!!!"
	Button button_switchxaxis,pos={1043.00,525.00},size={80.00,20.00},proc=DB_ButtonProc_SwitchXAxis,title="Switch X-axis"
	Button button_switchxaxis,userdata(ResizeControlsInfo)= A"!!,K>?iWRs5QF-D!!#<Xz!!#N3Bk1ct<C^(Dzzzzzzzzzzzzz!!#N3Bk1ct<C^(Dz"
	Button button_switchxaxis,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#N3Bk1ct<C]S7zzzzzzzzzz"
	Button button_switchxaxis,userdata(ResizeControlsInfo) += A"zzz!!#N3Bk1ct<C]S7zzzzzzzzzzzzz!!!"
	Button button_switchxaxis help={"Toggle lab notebook horizontal axis between time of day or sweep number"}
	CheckBox check_DataBrowser_ZeroTraces,pos={349.00,27.00},size={73.00,15.00},proc=DB_CheckProc_ChangedSetting,title="Zero traces"
	CheckBox check_DataBrowser_ZeroTraces,userdata(ResizeControlsInfo)= A"!!,HiJ,hmf!!#?K!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_DataBrowser_ZeroTraces,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_DataBrowser_ZeroTraces,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_DataBrowser_ZeroTraces,value= 0
	CheckBox check_DataBrowser_ZeroTraces help={"Sets the baseline of the sweep to zero by differentiating and the integrating a copy of the sweep"}
	SetVariable setvar_DataBrowser_SweepStep,pos={498.00,674.00},size={67.00,18.00},bodyWidth=40,title="Step"
	SetVariable setvar_DataBrowser_SweepStep,userdata(ResizeControlsInfo)= A"!!,I_!!#D8J,hoj!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_DataBrowser_SweepStep,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#?(FEDG<zzzzzzzzzzz"
	SetVariable setvar_DataBrowser_SweepStep,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_DataBrowser_SweepStep,userdata(lastSweep)=  "0",fSize=12
	SetVariable setvar_DataBrowser_SweepStep,limits={1,inf,1},value= _NUM:1
	SetVariable setvar_DataBrowser_SweepStep help={"Set the increment between sweeps"}
	CheckBox checkbox_DB_AutoScaleVertAxVisX,pos={179.00,686.00},size={40.00,15.00},proc=DB_ScaleAxis,title="Vis X"
	CheckBox checkbox_DB_AutoScaleVertAxVisX,help={"Scale the y axis to the visible x data range"}
	CheckBox checkbox_DB_AutoScaleVertAxVisX,userdata(ResizeControlsInfo)= A"!!,GC!!#D;J,hnY!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox checkbox_DB_AutoScaleVertAxVisX,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#?(FEDG<zzzzzzzzzzz"
	CheckBox checkbox_DB_AutoScaleVertAxVisX,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	CheckBox checkbox_DB_AutoScaleVertAxVisX,value= 0
	DefineGuide UGV0={FR,-200},UGH1={FT,0.584722,FB},UGH0={UGH1,0.662207,FB}
	SetWindow kwTopWin,hook(ResizeControls)=ResizeControls#ResizeControlsHook
	SetWindow kwTopWin,userdata(ResizeControlsInfo)= A"!!*'\"z!!#ERTE%A:zzzzzzzzzzzzzzzzzzzzz"
	SetWindow kwTopWin,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzzzzzzzzzzzzzzz"
	SetWindow kwTopWin,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzzzzzzzzz!!!"
	SetWindow kwTopWin,userdata(ResizeControlsGuides)=  "UGV0;UGH1;UGH0;"
	SetWindow kwTopWin,userdata(ResizeControlsInfoUGV0)= A":-hTC3`S[N0KW?-:-(dOFC@LVDg-86EaMC72d\\:$<*<$d3`U64E]Zff;Ft%f:/jMQ3\\WWl:K'ha8P`)B0eb=</het@7o`,K756hm;EIBK8OQ!&3]g5.9MeM`8Q88W:-'s^0JGQ"
	SetWindow kwTopWin,userdata(ResizeControlsInfoUGH1)= A":-hTC3`S[@0frH.:-(dOFC@LVDg-86EaMC72d\\:$<*<$d3`U64E]Zff;Ft%f:/jMQ3\\`]m:K'ha8P`)B1bpd<0JGRY<CoSI0fhd'4%E:B6q&jl7RB1778-NR;b9q[:JNr)/i>UF2_m-M"
	SetWindow kwTopWin,userdata(ResizeControlsInfoUGH0)= A":-hTC3`S[@0KW?-:-(dOFC@LVDg-86EaMC72d\\:$<*<$d3`U64E]Zff;Ft%f:/jMQ3\\`]m:K'ha8P`)B2DI3E0JGRY<CoSI0fi<)8231r<CoSI1-.lk4&SL@:et\"]<(Tk\\3\\W0E2DR$A2`h"
	Display/W=(18,72,1039,362)/FG=($"",$"",UGV0,UGH1)/HOST=#
	SetWindow kwTopWin,userdata(MiesPanelType)=  "DataBrowser"
	RenameWindow #,DataBrowserGraph
	SetActiveSubwindow ##
	NewNotebook /F=1 /N=WaveNoteDisplay /W=(1052,72,1220,341)/FG=(UGV0,$"",FR,UGH1) /HOST=# /OPTS=10
	Notebook kwTopWin, defaultTab=36, autoSave= 1, showRuler=0, rulerUnits=1
	Notebook kwTopWin newRuler=Normal, justification=0, margins={0,0,127}, spacing={0,0,0}, tabs={}, rulerDefaults={"Arial",10,0,(0,0,0)}
	Notebook kwTopWin, zdata= "GaqDU%ejN7!Z)u^\"(F_BAcgu_S&%T4L]iZ-,W[?i6\"=DG6/B>,7,t^s'8'dlAmu5P!&>c+OT"
	Notebook kwTopWin, zdataEnd= 1
	RenameWindow #,WaveNoteDisplay
	SetActiveSubwindow ##
	Display/W=(17,427,1051,614)/FG=($"",UGH1,UGV0,UGH0)/HOST=#
	ModifyGraph margin(right)=74
	TextBox/C/N=text0/F=0/B=1/X=0.50/Y=2.02/E=2 ""
	RenameWindow #,LabNoteBook
	SetActiveSubwindow ##
EndMacro

Function DB_DataBrowserStartupSettings()

	string allCheckBoxes, panelTitle, subWindow
	variable i, numCheckBoxes

	panelTitle = "DataBrowser"
	subWindow  = DB_GetNotebookSubWindow(panelTitle)

	if(!windowExists(panelTitle))
		print "A panel named \"DataBrowser\" does not exist"
		return NaN
	endif

	// remove tools
	HideTools/A/W=$panelTitle

	SetSetVariable(panelTitle, "setvar_DataBrowser_SweepNo", 0)
	SetVariable setvar_DataBrowser_SweepNo, win=$panelTitle, limits={0, 0, 1}
	SetValDisplaySingleVariable(panelTitle, "valdisp_DataBrowser_LastSweep", 0)

	RemoveTracesFromGraph(DB_GetMainGraph(panelTitle))
	RemoveTracesFromGraph(DB_GetLabNotebookGraph(panelTitle))

	Notebook $subWindow selection={startOfFile, endOfFile}
	Notebook $subWindow text = ""
	SetPopupMenuIndex(panelTitle, "popup_DB_lockedDevices", 0)
	SetSetVariable(panelTitle, "setvar_DataBrowser_SweepStep", 1)

	SetWindow $panelTitle, userdata(DataFolderPath) = ""
	DB_SetFormerSweepNumber(panelTitle, NaN)

	allCheckBoxes = ControlNameList(panelTitle, ";", "check*")

	numCheckBoxes = ItemsInList(allCheckBoxes)
	for(i = 0; i < numCheckBoxes; i += 1)
		SetCheckBoxState(panelTitle, StringFromList(i, allCheckBoxes), CHECKBOX_UNSELECTED)
	endfor

	SetCheckBoxState(panelTitle, "check_databrowser_OverlayChan", CHECKBOX_SELECTED)
	SetCheckBoxState(panelTitle, "check_DataBrowser_DisplayADChan", CHECKBOX_SELECTED)
	EnableControls(panelTitle, "check_DataBrowser_DisplayDAchan;check_databrowser_OverlayChan;check_DataBrowser_DisplayADChan;check_DataBrowser_DisplayTTL")

	DB_ClearGraph(panelTitle)
	SetPopupMenuIndex(panelTitle, "popup_labenotebookViewableCols", 0)
End

Function DB_ButtonProc_Sweep(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	string panelTitle, ctrl
	variable currentSweep, direction
	switch(ba.eventcode)
		case 2: // mouse up
			panelTitle = ba.win
			ctrl       = ba.ctrlName

			if(!cmpstr(ctrl, "button_DataBrowser_PrevSweep"))
				DB_PlotSweep(panelTitle, direction= -1)
			elseif(!cmpstr(ctrl, "button_DataBrowser_NextSweep"))
				DB_PlotSweep(panelTitle, direction= +1)
			else
				ASSERT(0, "unhandled control name")
			endif

			break
	endswitch

	return 0
End

Function DB_ButtonProc_AutoScale(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	string panelTitle
	switch(ba.eventcode)
		case 2: // mouse up
			panelTitle = ba.win
			SetAxis/A/W=$DB_GetMainGraph(panelTitle)
			SetAxis/A/W=$DB_GetLabNotebookGraph(panelTitle)
			break
	endswitch

	return 0
End

Function DB_PopMenuProc_LockDBtoDevice(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	switch(pa.eventcode)
		case 2: // mouse up
			DB_LockDBPanel(pa.win)
			break
	endswitch

	return 0
End

Function DB_PopMenuProc_LabNotebook(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	string graph, popStr, panelTitle, device

	switch(pa.eventCode)
		case 2: // mouse up
			panelTitle = pa.win
			graph      = DB_GetLabNoteBookGraph(panelTitle)
			popStr     = pa.popStr

			if(!CmpStr(popStr, NONE))
				break
			endif

			Wave settingsHistory = DB_GetSettingsHistory(panelTitle)
			WAVE keyWave = DB_GetSettingsHistoryKeys(panelTitle)

			AddTraceToLBGraph(graph, keyWave, settingsHistory, popStr)
		break
	endswitch

	return 0
End

static Function DB_SetFormerSweepNumber(panelTitle, sweepNo)
	string panelTitle
	variable sweepNo

	SetControlUserData(panelTitle, "setvar_DataBrowser_SweepNo", LAST_SWEEP_USER_DATA, num2str(sweepNo))
End

static Function DB_GetFormerSweepNumber(panelTitle)
	string panelTitle

	return str2num(GetUserData(panelTitle, "setvar_DataBrowser_SweepNo", LAST_SWEEP_USER_DATA))
End

Function DB_SetVarProc_SweepNo(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	string panelTitle
	variable firstSweep, lastSweep, formerSweep, sweepNo

	switch(sva.eventCode)
		case 1: // mouse up - when the scroll wheel is used on the mouse - "up or down"
		case 2: // Enter key - when a number is manually entered
		case 3: // Live update - happens when you hit the arrow keys associated with the set variable
			sweepNo = sva.dval
			paneltitle = sva.win

			DB_FirstAndLastSweepAcquired(panelTitle, firstSweep, lastSweep)

			if(GetCheckBoxState(panelTitle, "check_DataBrowser_SweepOverlay"))
				formerSweep = DB_GetFormerSweepNumber(panelTitle)

				if(sweepNo > formerSweep)
					SetVariable setvar_DataBrowser_SweepNo win = $panelTitle, limits = {sweepNo, lastSweep , 1}
					ControlUpdate/W=$panelTitle setvar_DataBrowser_SweepNo
				elseif(sweepNo < formerSweep)
					SetVariable setvar_DataBrowser_SweepNo win = $panelTitle, limits = {firstSweep, sweepNo , 1}
				endif
			else
				SetVariable setvar_DataBrowser_SweepNo win = $panelTitle, limits = {firstSweep, lastSweep , 1}
			endif

			DB_PlotSweep(panelTitle, currentSweep=formerSweep, newSweep=sweepNo)
			break
	endswitch

	return 0
End

Function DB_ButtonProc_ClearGraph(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch(ba.eventCode)
		case 2: // mouse up
			DB_ClearGraph(ba.win)
			break
	endswitch

	return 0
End

Function/S DB_GetLabNotebookViewAbleCols(panelTitle)
	string panelTitle

	string device

	if(!windowExists(panelTitle))
		return NONE
	endif

	device = GetPopupMenuString(panelTitle, "popup_DB_lockedDevices")
	if(!CmpStr(device, NONE))
		return NONE
	endif

	WAVE/T keyWave = DB_GetSettingsHistoryKeys(panelTitle)

	return AddListItem(NONE, GetLabNotebookSortedKeys(keyWave), ";", 0)
End

Function/S DB_GetAllDevicesWithData()

	return AddListItem(NONE, GetAllDevicesWithData(), ";", 0)
End

Function DB_ButtonProc_SwitchXAxis(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	string panelTitle, graph

	switch(ba.eventCode)
		case 2: // mouse up
			panelTitle = ba.win
			graph      = DB_GetLabNoteBookGraph(panelTitle)
			WAVE settingsHistory = DB_GetSettingsHistory(panelTitle)

			SwitchLBGraphXAxis(graph, settingsHistory)
			break
	endswitch

	return 0
End

Function DB_CheckProc_ChangedSetting(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	variable checked
	string panelTitle, ctrl

	switch(cba.eventCode)
		case 2: // mouse up
			panelTitle = cba.win
			ctrl       = cba.ctrlName
			checked    = cba.checked

			if(!cmpstr(ctrl, "check_DataBrowser_SweepOverlay"))
				if(checked)
					DisableControls(panelTitle, "check_DataBrowser_DisplayDAchan;check_databrowser_OverlayChan;check_DataBrowser_DisplayADChan;check_DataBrowser_DisplayTTL;check_databrowser_dDAQMode")
				else
					EnableControls(panelTitle, "check_DataBrowser_DisplayDAchan;check_databrowser_OverlayChan;check_DataBrowser_DisplayADChan;check_DataBrowser_DisplayTTL;check_databrowser_dDAQMode")
				endif
			endif

			DB_PlotSweep(panelTitle)
			break
	endswitch

	return 0
End

Function DB_ScaleAxis(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba
	
	switch(cba.eventCode)
		case 2: // mouse up
			DB_PanelUpdate(cba.win)
			break
	endswitch

	return 0
End

static Function DB_PanelUpdate(graphOrPanel)
	string graphOrPanel

	string panel, graph

	panel = GetMainWindow(graphOrPanel)
	graph = DB_GetMainGraph(panel)

	if(GetCheckBoxState(panel, "checkbox_DB_AutoScaleVertAxVisX"))
		AutoscaleVertAxisVisXRange(graph)
	endif
End
