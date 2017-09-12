#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma IgorVersion=7.04

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_DB
#endif

/// @file MIES_DataBrowser.ipf
/// @brief __DB__ Panel for browsing acquired data during acquisition

// stock igor
#include <Resize Controls>
#include <Readback ModifyStr>

// third party includes
#include ":ACL_TabUtilities"
#include ":ACL_UserdataEditor"

// ZeroMQ procedures
#include ":..:ZeroMQ:procedures:ZeroMQ_Interop"

// our includes
#include ":MIES_AnalysisFunctionHelpers"
#include ":MIES_ArtefactRemoval"
#include ":MIES_Cache"
#include ":MIES_Constants"
#include ":MIES_Debugging"
#include ":MIES_EnhancedWMRoutines"
#include ":MIES_GlobalStringAndVariableAccess"
#include ":MIES_GuiUtilities"
#include ":MIES_MiesUtilities"
#include ":MIES_OverlaySweeps"
#include ":MIES_ProgrammaticGuiControl"
#include ":MIES_PulseAveraging"
#include ":MIES_Utilities"
#include ":MIES_Structures"
#include ":MIES_Cache"
#include ":MIES_WaveDataFolderGetters"

Menu "Mies Panels", dynamic
	"Data Browser", /Q, DB_OpenDataBrowser()
End

Function DB_OpenDataBrowser()

	string win, device, devicesWithData

	Execute "DataBrowser()"
	win = GetCurrentWindow()
	AddVersionToPanel(win, DATABROWSER_PANEL_VERSION)

	devicesWithData = ListMatch(DB_GetAllDevicesWithData(), "!" + NONE)

	// immediately lock if we have only data from one device
	if(ItemsInList(devicesWithData) == 1)
		device = StringFromList(0, devicesWithData)
		PGC_SetAndActivateControl(win, "popup_DB_lockedDevices", val=1, str=device)
	endif
End

static Function/DF DB_GetDataPath(panelTitle)
	string panelTitle

	return $GetUserData(panelTitle, "", "DataFolderPath") + ":Data"
End

static Function/DF DB_GetDataBrowserPath(panelTitle)
	string panelTitle

	return $GetUserData(panelTitle, "", "DataFolderPath") + ":DataBrowser"
End

static Function/S DB_GetNotebookSubWindow(panelTitle)
	string panelTitle

	return panelTitle + "#WaveNoteDisplay"
End

Function/S DB_GetMainGraph(panelTitle)
	string panelTitle

	return GetMainWindow(panelTitle) + "#DataBrowserGraph"
End

Function/S DB_ClearAllGraphs()

	string unlocked, locked, listOfGraphs
	string listOfPanels = ""
	string graph
	variable i, numEntries

	locked   = WinList("DB_*", ";", "WIN:64")
	unlocked = WinList("DataBrowser*", ";", "WIN:64")

	if(!IsEmpty(locked))
		listOfPanels = AddListItem(locked, listOfPanels, ";", inf)
	endif

	if(!IsEmpty(unlocked))
		listOfPanels = AddListItem(unlocked, listOfPanels, ";", inf)
	endif

	numEntries = ItemsInList(listOfPanels)
	for(i = 0; i < numEntries; i += 1)
		graph = DB_GetMainGraph(StringFromList(i, listOfPanels))

		if(WindowExists(graph))
			RemoveTracesFromGraph(graph)
		endif
	endfor
End

static Function/S DB_GetLabNoteBookGraph(panelTitle)
	string panelTitle

	return panelTitle + "#Labnotebook"
End

static Function DB_LockDBPanel(panelTitle, device)
	string panelTitle, device

	string panelTitleNew
	variable first, last

	if(!CmpStr(device,NONE))
		panelTitleNew = "DataBrowser"

		if(windowExists(panelTitleNew))
			panelTitleNew = UniqueName("DataBrowser", 9, 1)
		endif

		print "Please choose a device assignment for the data browser"
		ControlWindowToFront()
		DoWindow/W=$panelTitle/C $panelTitleNew
		SetWindow $panelTitleNew, userdata($MIES_PANEL_TYPE_USER_DATA) = ""
		SetWindow $panelTitleNew, userdata(DataFolderPath) = ""
		PopupMenu popup_LBNumericalKeys, win=$panelTitleNew, value=#("\"" + NONE + "\"")
		PopupMenu popup_LBTextualKeys, win=$panelTitleNew, value=#("\"" + NONE + "\"")
		return NaN
	endif

	panelTitleNew = UniqueName("DB_" + device, 9, 0)
	DoWindow/W=$panelTitle/C $panelTitleNew

	GetDeviceDataBrowserPath(device)

	SetWindow $panelTitleNew, userdata($MIES_PANEL_TYPE_USER_DATA) = MIES_DATABROWSER_PANEL
	SetWindow $panelTitleNew, userdata(DataFolderPath)   = GetDevicePathAsString(device)
	PopupMenu popup_LBNumericalKeys, win=$panelTitleNew, value=#("DB_GetLBNumericalKeys(\"" + panelTitleNew + "\")")
	PopupMenu popup_LBTextualKeys, win=$panelTitleNew, value=#("DB_GetLBTextualKeys(\"" + panelTitleNew + "\")")

	DB_FirstAndLastSweepAcquired(panelTitleNew, first, last)
	DB_UpdateSweepControls(panelTitleNew, first, last)
	DB_UpdateSweepPlot(panelTitleNew)

	if(GetCheckBoxState(panelTitleNew, "check_DataBrowser_SweepOverlay"))
		DFREF dfr = GetDeviceDataBrowserPath(device)
		OVS_SetFolder(panelTitleNew, dfr)
	endif
End

static Function/S DB_GetListOfSweepWaves(panelTitle)
	string panelTitle

	dfref dfr = DB_GetDataPath(panelTitle)

	if(!DataFolderExistsDFR(dfr))
		return ""
	endif

	return GetListOfObjects(dfr, DATA_SWEEP_REGEXP, waveProperty="MINCOLS:2")
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
End

static Function DB_UpdateSweepControls(panelTitle, first, last)
	string panelTitle
	variable first, last

	variable formerLast

	formerLast = GetValDisplayAsNum(panelTitle, "valdisp_DataBrowser_LastSweep")
	SetVariable setvar_DataBrowser_SweepNo win = $panelTitle, limits = {first, last, 1}

	if(formerLast != last)
		SetValDisplay(panelTitle, "valdisp_DataBrowser_LastSweep", var=last)
		DB_UpdateOverlaySweepWaves(panelTitle)
	endif
End

static Function DB_ClipSweepNumber(panelTitle, sweepNo)
	string panelTitle
	variable sweepNo

	variable firstSweep, lastSweep

	DB_FirstAndLastSweepAcquired(panelTitle, firstSweep, lastSweep)
	DB_UpdateSweepControls(panelTitle, firstSweep, lastSweep)

	// handles situation where data sweep number starts at a value greater than the controls number
	// usually occurs after locking when control is set to zero
	return limit(sweepNo, firstSweep, lastSweep)
End

/// @brief Update the sweep plotting facility
///
/// Only outside callers are generic external panels which must update the graph.
/// @param panelTitle locked databrowser
/// @param dummyArg   [unnused] required to be compatible to UpdateSweepPlot()
Function DB_UpdateSweepPlot(panelTitle, [dummyArg])
	string panelTitle
	variable dummyArg

	variable numEntries, i, sweepNo, highlightSweep, referenceTime, traceIndex
	string device, subWindow, graph

	if(!HasPanelLatestVersion(panelTitle, DATABROWSER_PANEL_VERSION))
		Abort "Can not display data. The Databrowser panel is too old to be usable. Please close it and open a new one."
	endif

	referenceTime = DEBUG_TIMER_START()

	DFREF dfr = DB_GetDataPath(panelTitle)

	if(!DataFolderExistsDFR(dfr))
		return NaN
	endif

	subWindow = DB_GetNotebookSubWindow(panelTitle)
	graph     = DB_GetMainGraph(panelTitle)

	WAVE numericalValues = DB_GetNumericalValues(panelTitle)
	WAVE textualValues   = DB_GetTextualValues(panelTitle)

	STRUCT TiledGraphSettings tgs
	tgs.displayDAC      = GetCheckBoxState(panelTitle, "check_DataBrowser_DisplayDAchan")
	tgs.displayTTL      = GetCheckBoxState(panelTitle, "check_DataBrowser_DisplayTTL")
	tgs.displayADC      = GetCheckBoxState(panelTitle, "check_DataBrowser_DisplayADChan")
	tgs.overlaySweep    = GetCheckBoxState(panelTitle, "check_DataBrowser_SweepOverlay")
	tgs.overlayChannels = GetCheckBoxState(panelTitle, "check_databrowser_OverlayChan")
	tgs.dDAQDisplayMode = GetCheckBoxState(panelTitle, "check_databrowser_dDAQMode")
	tgs.dDAQHeadstageRegions = GetSliderPositionIndex(panelTitle, "slider_dDAQ_regions")
	tgs.hideSweep       = GetCheckBoxState(panelTitle, "check_databrowser_hideSweep")

	DFREF dataBrowserDFR   = DB_GetDataBrowserPath(panelTitle)
	WAVE channelSel        = GetChannelSelectionWave(dataBrowserDFR)
	WAVE/Z sweepsToOverlay = OVS_GetSelectedSweeps(panelTitle, OVS_SWEEP_SELECTION_SWEEPNO)

	WAVE axesRanges = GetAxesRanges(graph)

	RemoveTracesFromGraph(graph)

	if(!WaveExists(sweepsToOverlay))
		Make/FREE/N=1 sweepsToOverlay = GetSetVariable(panelTitle, "setvar_DataBrowser_SweepNo")
	endif

	WAVE axisLabelCache = GetAxisLabelCacheWave()

	numEntries = DimSize(sweepsToOverlay, ROWS)
	for(i = 0; i < numEntries; i += 1)
		sweepNo = sweepsToOverlay[i]
		WAVE/Z/SDFR=dfr sweepWave = $GetSweepWaveName(sweepNo)

		if(!WaveExists(sweepWave))
			DEBUGPRINT("Expected sweep wave does not exist. Hugh?")
			continue
		endif

		WAVE/Z activeHS = OVS_ParseIgnoreList(panelTitle, highlightSweep, sweepNo=sweepNo)
		tgs.highlightSweep = highlightSweep

		if(WaveExists(activeHS))
			Duplicate/FREE channelSel, sweepChannelSel
			sweepChannelSel[0, NUM_HEADSTAGES - 1][%HEADSTAGE] = sweepChannelSel[p][%HEADSTAGE] && activeHS[p]
		else
			WAVE sweepChannelSel = channelSel
		endif

		DB_SplitSweepsIfReq(panelTitle, sweepNo)
		WAVE config = GetConfigWave(sweepWave)

		CreateTiledChannelGraph(graph, config, sweepNo, numericalValues, textualValues, tgs, dfr, axisLabelCache, traceIndex, channelSelWave=sweepChannelSel)
		AR_UpdateTracesIfReq(graph, dfr, numericalValues, sweepNo)
	endfor

	DEBUGPRINT_ELAPSED(referenceTime)

	if(WaveExists(sweepWave))
		Notebook $subWindow selection={startOfFile, endOfFile} // select entire contents of notebook
		Notebook $subWindow text = "Sweep note: \r " + note(sweepWave) // replaces selected notebook content with new wave note.
	endif

	Struct PostPlotSettings pps
	device = GetPopupMenuString(panelTitle, "popup_DB_lockedDevices")
	pps.averageDataFolder = GetDeviceDataBrowserPath(device)
	pps.averageTraces     = GetCheckboxState(panelTitle, "check_DataBrowser_AverageTraces")
	pps.zeroTraces        = GetCheckBoxState(panelTitle, "check_DataBrowser_ZeroTraces")
	pps.timeAlignRefTrace = ""
	pps.timeAlignMode     = TIME_ALIGNMENT_NONE
	pps.hideSweep         = tgs.hideSweep

	PA_GatherSettings(panelTitle, pps)

	FUNCREF FinalUpdateHookProto pps.finalUpdateHook = DB_PanelUpdate

	PostPlotTransformations(graph, pps)
	SetAxesRanges(graph, axesRanges)
	DEBUGPRINT_ELAPSED(referenceTime)
End

static Function DB_ClearGraph(panelTitle)
	string panelTitle

	string graph = DB_GetLabNoteBookGraph(panelTitle)
	RemoveTracesFromGraph(graph)
	UpdateLBGraphLegend(graph)
End

static Function/WAVE DB_GetNumericalValues(panelTitle)
	string panelTitle

	return GetLBNumericalValues(GetPopupMenuString(panelTitle, "popup_DB_lockedDevices"))
End

static Function/WAVE DB_GetTextualValues(panelTitle)
	string panelTitle

	return GetLBTextualValues(GetPopupMenuString(panelTitle, "popup_DB_lockedDevices"))
End

static Function/WAVE DB_GetNumericalKeys(panelTitle)
	string panelTitle

	return GetLBNumericalKeys(GetPopupMenuString(panelTitle, "popup_DB_lockedDevices"))
End

static Function/WAVE DB_GetTextualKeys(panelTitle)
	string panelTitle

	return GetLBTextualKeys(GetPopupMenuString(panelTitle, "popup_DB_lockedDevices"))
End

Function DB_UpdateToLastSweep(panelTitle)
	string panelTitle

	variable first, last
	string device, extPanel

	if(!HasPanelLatestVersion(panelTitle, DATABROWSER_PANEL_VERSION))
		print "Can not display data. The Databrowser panel is too old to be usable. Please close it and open a new one."
		ControlWindowToFront()
		return NaN
	endif

	if(!GetCheckBoxState(panelTitle, "check_DataBrowser_AutoUpdate"))
		return NaN
	endif

	device = GetPopupMenuString(panelTitle, "popup_DB_lockedDevices")

	if(!cmpstr(device, NONE))
		return NaN
	endif

	DB_FirstAndLastSweepAcquired(panelTitle, first, last)
	DB_UpdateSweepControls(panelTitle, first, last)
	SetSetVariable(panelTitle, "setvar_DataBrowser_SweepNo", last)

	extPanel = OVS_GetExtPanel(panelTitle)

	if(WindowExists(extPanel) && GetCheckBoxState(extPanel, "check_overlaySweeps_non_commula"))
		OVS_ChangeSweepSelectionState(panelTitle, CHECKBOX_UNSELECTED, sweepNo=last - 1)
	endif

	OVS_ChangeSweepSelectionState(panelTitle, CHECKBOX_SELECTED, sweepNo=last)
	DB_UpdateSweepPlot(panelTitle)
End

static Function DB_UpdateOverlaySweepWaves(panelTitle)
	string panelTitle

	string device, sweepWaveList

	if(!GetCheckBoxState(panelTitle, "check_DataBrowser_SweepOverlay"))
		return NaN
	endif

	device = GetPopupMenuString(panelTitle, "popup_DB_lockedDevices")

	DFREF dfr = GetDeviceDataBrowserPath(device)
	WAVE listBoxWave       = GetOverlaySweepsListWave(dfr)
	WAVE listBoxSelWave    = GetOverlaySweepsListSelWave(dfr)
	WAVE/T textualValues   = DB_GetTextualValues(panelTitle)
	WAVE numericalValues   = DB_GetNumericalValues(panelTitle)
	WAVE/T sweepSelChoices = GetOverlaySweepSelectionChoices(dfr)

	sweepWaveList = DB_GetListOfSweepWaves(panelTitle)

	OVS_UpdatePanel(panelTitle, listBoxWave, listBoxSelWave, sweepSelChoices, sweepWaveList, textualValues=textualValues, numericalValues=numericalValues)
End

Window DataBrowser() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /K=1 /W=(72,811,1283,1559) as "DataBrowser"
	Button button_DataBrowser_NextSweep,pos={628.00,667.00},size={384.00,45.00},proc=DB_ButtonProc_Sweep,title="Next Sweep \\W649"
	Button button_DataBrowser_NextSweep,help={"Displays the next sweep (sweep no. = last sweep number + step)"}
	Button button_DataBrowser_NextSweep,userdata(ResizeControlsInfo)= A"!!,J.!!#D6^]6a;!!#>Bz!!#](Aon\"q<C^(Dzzzzzzzzzzzzz!!#](Aon\"q<C^(Dz"
	Button button_DataBrowser_NextSweep,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#?(FEDG<zzzzzzzzzzz"
	Button button_DataBrowser_NextSweep,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	Button button_DataBrowser_NextSweep,fSize=20
	Button button_DataBrowser_PrevSweep,pos={20.00,667.00},size={425.00,45.00},proc=DB_ButtonProc_Sweep,title="\\W646 Previous Sweep"
	Button button_DataBrowser_PrevSweep,help={"Displays the previous sweep (sweep no. = last sweep number - step)"}
	Button button_DataBrowser_PrevSweep,userdata(ResizeControlsInfo)= A"!!,BY!!#D6^]6aOJ,hnmz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_DataBrowser_PrevSweep,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#?(FEDG<zzzzzzzzzzz"
	Button button_DataBrowser_PrevSweep,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	Button button_DataBrowser_PrevSweep,fSize=20
	ValDisplay valdisp_DataBrowser_LastSweep,pos={530.00,671.00},size={89.00,34.00},bodyWidth=60,title="of"
	ValDisplay valdisp_DataBrowser_LastSweep,help={"The number of the last sweep acquired for the device assigned to the data browser"}
	ValDisplay valdisp_DataBrowser_LastSweep,userdata(ResizeControlsInfo)= A"!!,IjJ,htb^]6^,!!#=kz!!#](Aon\"q<C^(Dzzzzzzzzzzzzz!!#](Aon\"q<C^(Dz"
	ValDisplay valdisp_DataBrowser_LastSweep,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#?(FEDG<zzzzzzzzzzz"
	ValDisplay valdisp_DataBrowser_LastSweep,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	ValDisplay valdisp_DataBrowser_LastSweep,fSize=24,frame=2,fStyle=1
	ValDisplay valdisp_DataBrowser_LastSweep,limits={0,0,0},barmisc={0,1000}
	ValDisplay valdisp_DataBrowser_LastSweep,value= #"0"
	ValDisplay valdisp_DataBrowser_LastSweep,barBackColor= (56576,56576,56576)
	CheckBox check_DataBrowser_DisplayDAchan,pos={18.00,9.00},size={122.00,15.00},proc=DB_CheckProc_ChangedSetting,title="Display DA channels"
	CheckBox check_DataBrowser_DisplayDAchan,help={"Display DA (digital to analog) channel data"}
	CheckBox check_DataBrowser_DisplayDAchan,userdata(ResizeControlsInfo)= A"!!,BI!!#:r!!#@X!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_DataBrowser_DisplayDAchan,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_DataBrowser_DisplayDAchan,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_DataBrowser_DisplayDAchan,value= 0
	CheckBox check_databrowser_OverlayChan,pos={153.00,27.00},size={107.00,15.00},proc=DB_CheckProc_ChangedSetting,title="Overlay Channels"
	CheckBox check_databrowser_OverlayChan,help={"Displays all channels using a single  vertical axis"}
	CheckBox check_databrowser_OverlayChan,userdata(ResizeControlsInfo)= A"!!,G)!!#=;!!#@:!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_databrowser_OverlayChan,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_databrowser_OverlayChan,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_databrowser_OverlayChan,value= 0
	CheckBox check_databrowser_dDAQMode,pos={153.00,45.00},size={85.00,15.00},proc=DB_CheckProc_ChangedSetting,title="dDAQ Viewer"
	CheckBox check_databrowser_dDAQMode,help={"Enable dedicated support for viewing distributed DAQ data"}
	CheckBox check_databrowser_dDAQMode,userdata(ResizeControlsInfo)= A"!!,G)!!#>B!!#?c!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_databrowser_dDAQMode,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_databrowser_dDAQMode,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_databrowser_dDAQMode,value= 0
	TitleBox ListBox_DataBrowser_NoteDisplay,pos={1756.00,75.00},size={197.00,39.00}
	TitleBox ListBox_DataBrowser_NoteDisplay,userdata(ResizeControlsInfo)= A"!!,LBJ,hp%!!#AT!!#>*z!!#o2B4uAezzzzzzzzzzzzzz!!#o2B4uAezz"
	TitleBox ListBox_DataBrowser_NoteDisplay,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	TitleBox ListBox_DataBrowser_NoteDisplay,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	TitleBox ListBox_DataBrowser_NoteDisplay,labelBack=(62208,62208,62208),fSize=8
	TitleBox ListBox_DataBrowser_NoteDisplay,frame=0
	CheckBox check_DataBrowser_SweepOverlay,pos={153.00,9.00},size={97.00,15.00},proc=DB_CheckboxProc_OverlaySweeps,title="Overlay Sweeps"
	CheckBox check_DataBrowser_SweepOverlay,help={"Adds unplotted sweep to graph. Removes plotted sweep from graph."}
	CheckBox check_DataBrowser_SweepOverlay,userdata(ResizeControlsInfo)= A"!!,G)!!#:r!!#@&!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_DataBrowser_SweepOverlay,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_DataBrowser_SweepOverlay,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_DataBrowser_SweepOverlay,value= 0
	CheckBox check_DataBrowser_AutoUpdate,pos={378.00,9.00},size={159.00,15.00},title="Display last sweep acquired"
	CheckBox check_DataBrowser_AutoUpdate,help={"Displays the last sweep acquired when data acquistion is ongoing"}
	CheckBox check_DataBrowser_AutoUpdate,userdata(ResizeControlsInfo)= A"!!,I#!!#:r!!#A.!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_DataBrowser_AutoUpdate,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_DataBrowser_AutoUpdate,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_DataBrowser_AutoUpdate,value= 0
	PopupMenu popup_DB_lockedDevices,pos={639.00,721.00},size={275.00,19.00},bodyWidth=170,proc=DB_PopMenuProc_LockDBtoDevice,title="Device assingment:"
	PopupMenu popup_DB_lockedDevices,help={"Select a data acquistion device to display data"}
	PopupMenu popup_DB_lockedDevices,userdata(ResizeControlsInfo)= A"!!,J0^]6bZ5QF0.J,hm&z!!#](Aon\"q<C^(Dzzzzzzzzzzzzz!!#](Aon\"q<C^(Dz"
	PopupMenu popup_DB_lockedDevices,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#?(FEDG<!(TR7zzzzzzzzzz"
	PopupMenu popup_DB_lockedDevices,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<!(TR7zzzzzzzzzzzzz!!!"
	PopupMenu popup_DB_lockedDevices,mode=1,popvalue="- none -",value= #"DB_GetAllDevicesWithData()"
	CheckBox check_DataBrowser_DisplayTTL,pos={18.00,27.00},size={128.00,15.00},proc=DB_CheckProc_ChangedSetting,title="Display TTL Channels"
	CheckBox check_DataBrowser_DisplayTTL,help={"Display TTL channel data"}
	CheckBox check_DataBrowser_DisplayTTL,userdata(ResizeControlsInfo)= A"!!,BI!!#=;!!#@d!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_DataBrowser_DisplayTTL,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_DataBrowser_DisplayTTL,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox check_DataBrowser_DisplayTTL,value= 0
	CheckBox check_DataBrowser_DisplayADChan,pos={18.00,45.00},size={124.00,15.00},proc=DB_CheckProc_ChangedSetting,title="Display AD Channels"
	CheckBox check_DataBrowser_DisplayADChan,help={"Display AD (analog to digital) channel data"}
	CheckBox check_DataBrowser_DisplayADChan,userdata(ResizeControlsInfo)= A"!!,BI!!#>B!!#@\\!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_DataBrowser_DisplayADChan,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_DataBrowser_DisplayADChan,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox check_DataBrowser_DisplayADChan,value= 1
	CheckBox check_DataBrowser_AverageTraces,pos={270.00,9.00},size={92.00,15.00},proc=DB_CheckProc_ChangedSetting,title="Average traces"
	CheckBox check_DataBrowser_AverageTraces,help={"Displays the average (pink trace) of overlayed sweeps for each channel"}
	CheckBox check_DataBrowser_AverageTraces,userdata(ResizeControlsInfo)= A"!!,HB!!#:r!!#?q!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_DataBrowser_AverageTraces,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_DataBrowser_AverageTraces,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_DataBrowser_AverageTraces,value= 0
	Button button_DataBrowser_setaxis,pos={20.00,719.00},size={150.00,23.00},proc=DB_ButtonProc_AutoScale,title="Autoscale"
	Button button_DataBrowser_setaxis,help={"Autoscale sweep data"}
	Button button_DataBrowser_setaxis,userdata(ResizeControlsInfo)= A"!!,BY!!#DC^]6_;!!#<pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_DataBrowser_setaxis,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#?(FEDG<zzzzzzzzzzz"
	Button button_DataBrowser_setaxis,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_DataBrowser_SweepNo,pos={454.00,671.00},size={74.00,35.00},proc=DB_SetVarProc_SweepNo
	SetVariable setvar_DataBrowser_SweepNo,help={"Sweep number of last sweep plotted"}
	SetVariable setvar_DataBrowser_SweepNo,userdata(ResizeControlsInfo)= A"!!,II!!#D7^]6]c!!#=oz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_DataBrowser_SweepNo,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#?(FEDG<zzzzzzzzzzz"
	SetVariable setvar_DataBrowser_SweepNo,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_DataBrowser_SweepNo,userdata(lastSweep)=  "NaN",fSize=24
	SetVariable setvar_DataBrowser_SweepNo,limits={0,0,1},value= _NUM:0,live= 1
	PopupMenu popup_LBNumericalKeys,pos={1041.00,495.00},size={150.00,19.00},bodyWidth=150,proc=DB_PopMenuProc_LabNotebook
	PopupMenu popup_LBNumericalKeys,help={"Select numeric lab notebook data to display"}
	PopupMenu popup_LBNumericalKeys,userdata(ResizeControlsInfo)= A"!!,K>+94e'J,hqP!!#<Pz!!#N3Bk1ct<C^(Dzzzzzzzzzzzzz!!#N3Bk1ct<C^(Dz"
	PopupMenu popup_LBNumericalKeys,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#N3Bk1ct<C]S7zzzzzzzzzz"
	PopupMenu popup_LBNumericalKeys,userdata(ResizeControlsInfo) += A"zzz!!#N3Bk1ct<C]S7zzzzzzzzzzzzz!!!"
	PopupMenu popup_LBNumericalKeys,mode=1,popvalue="- none -",value= #"\"- none -\""
	PopupMenu popup_LBTextualKeys,pos={1041.00,524.00},size={150.00,19.00},bodyWidth=150,proc=DB_PopMenuProc_LabNotebook
	PopupMenu popup_LBTextualKeys,help={"Select textual lab notebook data to display"}
	PopupMenu popup_LBTextualKeys,userdata(ResizeControlsInfo)= A"!!,K>+94e3!!#A%!!#<Pz!!#N3Bk1ct<C^(Dzzzzzzzzzzzzz!!#N3Bk1ct<C^(Dz"
	PopupMenu popup_LBTextualKeys,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#N3Bk1ct<C]S7zzzzzzzzzz"
	PopupMenu popup_LBTextualKeys,userdata(ResizeControlsInfo) += A"zzz!!#N3Bk1ct<C]S7zzzzzzzzzzzzz!!!"
	PopupMenu popup_LBTextualKeys,mode=1,popvalue="- none -",value= #"\"- none -\""
	Button button_clearlabnotebookgraph,pos={1075.00,556.00},size={80.00,20.00},proc=DB_ButtonProc_ClearGraph,title="Clear graph"
	Button button_clearlabnotebookgraph,userdata(ResizeControlsInfo)= A"!!,KB?iWS&!!#?Y!!#<Xz!!#N3Bk1ct<C^(Dzzzzzzzzzzzzz!!#N3Bk1ct<C^(Dz"
	Button button_clearlabnotebookgraph,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#N3Bk1ct<C]S7zzzzzzzzzz"
	Button button_clearlabnotebookgraph,userdata(ResizeControlsInfo) += A"zzz!!#N3Bk1ct<C]S7zzzzzzzzzzzzz!!!"
	Button button_switchxaxis,pos={1075.00,583.00},size={80.00,20.00},proc=DB_ButtonProc_SwitchXAxis,title="Switch X-axis"
	Button button_switchxaxis,help={"Toggle lab notebook horizontal axis between time of day or sweep number"}
	Button button_switchxaxis,userdata(ResizeControlsInfo)= A"!!,KB?iWS,^]6]o!!#<Xz!!#N3Bk1ct<C^(Dzzzzzzzzzzzzz!!#N3Bk1ct<C^(Dz"
	Button button_switchxaxis,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#N3Bk1ct<C]S7zzzzzzzzzz"
	Button button_switchxaxis,userdata(ResizeControlsInfo) += A"zzz!!#N3Bk1ct<C]S7zzzzzzzzzzzzz!!!"
	GroupBox group_labnotebook_ctrls,pos={1033.00,474.00},size={170.00,78.00},title="Settings History Column"
	GroupBox group_labnotebook_ctrls,userdata(ResizeControlsInfo)= A"!!,K=+94dr!!#A9!!#?Uz!!#N3Bk1ct<C^(Dzzzzzzzzzzzzz!!#N3Bk1ct<C^(Dz"
	GroupBox group_labnotebook_ctrls,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#N3Bk1ct<C]S7zzzzzzzzzz"
	GroupBox group_labnotebook_ctrls,userdata(ResizeControlsInfo) += A"zzz!!#N3Bk1ct<C]S7zzzzzzzzzzzzz!!!"
	CheckBox check_DataBrowser_ZeroTraces,pos={270.00,27.00},size={73.00,15.00},proc=DB_CheckProc_ChangedSetting,title="Zero traces"
	CheckBox check_DataBrowser_ZeroTraces,help={"Sets the baseline of the sweep to zero by differentiating and the integrating a copy of the sweep"}
	CheckBox check_DataBrowser_ZeroTraces,userdata(ResizeControlsInfo)= A"!!,HB!!#=;!!#?K!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_DataBrowser_ZeroTraces,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_DataBrowser_ZeroTraces,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_DataBrowser_ZeroTraces,value= 0
	SetVariable setvar_DataBrowser_SweepStep,pos={498.00,711.00},size={67.00,18.00},bodyWidth=40,title="Step"
	SetVariable setvar_DataBrowser_SweepStep,help={"Set the increment between sweeps"}
	SetVariable setvar_DataBrowser_SweepStep,userdata(ResizeControlsInfo)= A"!!,I_!!#DA^]6]U!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_DataBrowser_SweepStep,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#?(FEDG<zzzzzzzzzzz"
	SetVariable setvar_DataBrowser_SweepStep,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_DataBrowser_SweepStep,userdata(lastSweep)=  "0",fSize=12
	SetVariable setvar_DataBrowser_SweepStep,limits={1,inf,1},value= _NUM:1
	CheckBox checkbox_DB_AutoScaleVertAxVisX,pos={179.00,723.00},size={40.00,15.00},proc=DB_ScaleAxis,title="Vis X"
	CheckBox checkbox_DB_AutoScaleVertAxVisX,help={"Scale the y axis to the visible x data range"}
	CheckBox checkbox_DB_AutoScaleVertAxVisX,userdata(ResizeControlsInfo)= A"!!,GC!!#DD^]6\\D!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox checkbox_DB_AutoScaleVertAxVisX,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#?(FEDG<zzzzzzzzzzz"
	CheckBox checkbox_DB_AutoScaleVertAxVisX,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	CheckBox checkbox_DB_AutoScaleVertAxVisX,value= 0
	Slider slider_dDAQ_regions,pos={546.00,11.00},size={233.00,54.00},disable=2,proc=DB_SliderProc_ChangedSetting
	Slider slider_dDAQ_regions,help={"Allows to view only regions from the selected headstage (oodDAQ) resp. the selected headstage (dDAQ). Choose -1 to display all."}
	Slider slider_dDAQ_regions,userdata(ResizeControlsInfo)= A"!!,InJ,hkh!!#B#!!#>fz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Slider slider_dDAQ_regions,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:DuaGl<C]S7zzzzzzzzzz"
	Slider slider_dDAQ_regions,userdata(ResizeControlsInfo) += A"zzz!!#u:DuaGl<C]S7zzzzzzzzzzzzz!!!"
	Slider slider_dDAQ_regions,limits={-1,7,1},value= -1,vert= 0
	CheckBox CheckBox_DataBrowser_OpenArtRem,pos={270.00,45.00},size={106.00,15.00},proc=DB_CheckBoxProc_ArtRemoval,title="Artefact Removal"
	CheckBox CheckBox_DataBrowser_OpenArtRem,help={"Open the artefact removal dialog"}
	CheckBox CheckBox_DataBrowser_OpenArtRem,userdata(ResizeControlsInfo)= A"!!,HB!!#>B!!#@8!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox CheckBox_DataBrowser_OpenArtRem,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafn!(TR7zzzzzzzzzz"
	CheckBox CheckBox_DataBrowser_OpenArtRem,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafn!(TR7zzzzzzzzzzzzz!!!"
	CheckBox CheckBox_DataBrowser_OpenArtRem,value= 0
	Button button_databrowser_restore,pos={816.00,23.00},size={76.00,21.00},proc=DB_ButtonProc_RestoreData,title="Restore data"
	Button button_databrowser_restore,help={"Restore the data in its pristine state without any modifications"}
	Button button_databrowser_restore,userdata(ResizeControlsInfo)= A"!!,J]!!#<p!!#?Q!!#<`z!!#](Aon\"q<C^(Dzzzzzzzzzzzzz!!#](Aon\"Q<C^(Dz"
	Button button_databrowser_restore,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:DuaGl<C]S7zzzzzzzzzz"
	Button button_databrowser_restore,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafn!(TR7zzzzzzzzzzzzz!!!"
	CheckBox check_DataBrowser_PulseAvg,pos={378.00,45.00},size={100.00,15.00},proc=DB_ButtonProc_PerPulseAver,title="Pulse Averaging"
	CheckBox check_DataBrowser_PulseAvg,help={"Allows to average multiple pulses from pulse train epochs"}
	CheckBox check_DataBrowser_PulseAvg,userdata(ResizeControlsInfo)= A"!!,I#!!#>B!!#@,!!#<(z!!#](Aon\"q<C^(Dzzzzzzzzzzzzz!!#](Aon\"Q<C^(Dz"
	CheckBox check_DataBrowser_PulseAvg,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:DuaGl<C]S7zzzzzzzzzz"
	CheckBox check_DataBrowser_PulseAvg,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafn!(TR7zzzzzzzzzzzzz!!!"
	CheckBox check_DataBrowser_PulseAvg,value= 0
	CheckBox check_DataBrowser_OpenChanSel,pos={378.00,27.00},size={110.00,15.00},proc=DB_OpenChannelSelectionPanel,title="Channel Selection"
	CheckBox check_DataBrowser_OpenChanSel,help={"Open the channel selection dialog, allows to disable single channels and headstages"}
	CheckBox check_DataBrowser_OpenChanSel,userdata(ResizeControlsInfo)= A"!!,I#!!#=;!!#@@!!#<(z!!#](Aon\"q<C^(Dzzzzzzzzzzzzz!!#](Aon\"Q<C^(Dz"
	CheckBox check_DataBrowser_OpenChanSel,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:DuaGl<C]S7zzzzzzzzzz"
	CheckBox check_DataBrowser_OpenChanSel,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafn!(TR7zzzzzzzzzzzzz!!!"
	CheckBox check_DataBrowser_OpenChanSel,value= 0
	CheckBox check_DataBrowser_HideSweep,pos={18.00,63.00},size={110.00,15.00},proc=DB_CheckProc_ChangedSetting,title="Hide sweep traces"
	CheckBox check_DataBrowser_HideSweep,help={"Hide all sweep traces. This setting is usually combined with \"Average Traces\"."}
	CheckBox check_DataBrowser_HideSweep,userdata(ResizeControlsInfo)= A"!!,BI!!#?5!!#@\\!!#<(z!!#](Aon\"q<C^(Dzzzzzzzzzzzzz!!#](Aon\"Q<C^(Dz"
	CheckBox check_DataBrowser_HideSweep,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:DuaGl<C]S7zzzzzzzzzz"
	CheckBox check_DataBrowser_HideSweep,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafn!(TR7zzzzzzzzzzzzz!!!"
	CheckBox check_DataBrowser_HideSweep,value= 0
	DefineGuide UGV0={FR,-200},UGH1={FT,0.602378,FB},UGH0={UGH1,0.700637,FB}
	SetWindow kwTopWin,hook(ResizeControls)=ResizeControls#ResizeControlsHook
	SetWindow kwTopWin,userdata(ResizeControlsInfo)= A"!!*'\"z!!#ER?iWSVzzzzzzzzzzzzzzzzzzzzz"
	SetWindow kwTopWin,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzzzzzzzzzzzzzzz"
	SetWindow kwTopWin,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzzzzzzzzz!!!"
	SetWindow kwTopWin,userdata(ResizeControlsGuides)=  "UGV0;UGH1;UGH0;"
	SetWindow kwTopWin,userdata(ResizeControlsInfoUGV0)= A":-hTC3`S[N0KW?-:-(dOFC@LVDg-86E][6':dmEFF(KAR85E,T>#.mm5tj<n4&A^O8Q88W:-(*`0ek:70KVd)8OQ!%3_!\"/7o`,K75?nc;FO8U:K'ha8P`)B/M]\"63r"
	SetWindow kwTopWin,userdata(ResizeControlsInfoUGH1)= A":-hTC3`S[@0frH.:-(dOFC@LVDg-86E][6':dmEFF(KAR85E,T>#.mm5tj<o4&A^O8Q88W:-(3h0eP.64%E:B6q&gk7T;H><CoSI1-.lk4&SL@:et\"]<(Tk\\3\\W0E0JYFC3'."
	SetWindow kwTopWin,userdata(ResizeControlsInfoUGH0)= A":-hTC3`S[@0KW?-:-(dOFC@LVDg-86E][6':dmEFF(KAR85E,T>#.mm5tj<o4&A^O8Q88W:-(9j3A*!>4%E:B6q&gk<C]S74%E:B6q&jl7RB1778-NR;b9q[:JNr)/iPI<2D[9R"
	SetWindow kwTopWin,userdata(panelVersion)=  "4"
	Execute/Q/Z "SetWindow kwTopWin sizeLimit={908.25,561,inf,inf}" // sizeLimit requires Igor 7 or later
	Display/W=(18,85,1039,362)/FG=($"",$"",UGV0,UGH1)/HOST=#
	ModifyGraph margin(left)=28,margin(bottom)=1
	SetWindow kwTopWin,userdata(MiesPanelType)=  "DataBrowser"
	RenameWindow #,DataBrowserGraph
	SetActiveSubwindow ##
	NewNotebook /F=1 /N=WaveNoteDisplay /W=(1052,84,1220,341)/FG=(UGV0,$"",FR,UGH1) /HOST=# /OPTS=10
	Notebook kwTopWin, defaultTab=36, autoSave= 1, showRuler=0, rulerUnits=1
	Notebook kwTopWin newRuler=Normal, justification=0, margins={0,0,128}, spacing={0,0,0}, tabs={}, rulerDefaults={"Arial",10,0,(0,0,0)}
	Notebook kwTopWin, zdata= "GaqDU%ejN7!Z)u^\"(F_BAcgt=>?2+c&.'2989@[[K>tpnK\"?L6M8jCF(5$*oAmu5P!$@%)/c"
	Notebook kwTopWin, zdataEnd= 1
	Execute/Q/Z "SetWindow kwTopWin sizeLimit={908.25,561,inf,inf}" // sizeLimit requires Igor 7 or later
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
		ControlWindowToFront()
		return NaN
	endif

	// remove tools
	HideTools/A/W=$panelTitle

	SetSetVariable(panelTitle, "setvar_DataBrowser_SweepNo", 0)
	SetVariable setvar_DataBrowser_SweepNo, win=$panelTitle, limits={0, 0, 1}
	SetValDisplay(panelTitle, "valdisp_DataBrowser_LastSweep", var=0)

	RemoveTracesFromGraph(DB_GetMainGraph(panelTitle))
	RemoveTracesFromGraph(DB_GetLabNotebookGraph(panelTitle))

	Notebook $subWindow selection={startOfFile, endOfFile}
	Notebook $subWindow text = ""
	SetPopupMenuIndex(panelTitle, "popup_DB_lockedDevices", 0)
	SetSetVariable(panelTitle, "setvar_DataBrowser_SweepStep", 1)

	SetWindow $panelTitle, userdata(DataFolderPath) = ""

	allCheckBoxes = ControlNameList(panelTitle, ";", "check*")

	numCheckBoxes = ItemsInList(allCheckBoxes)
	for(i = 0; i < numCheckBoxes; i += 1)
		SetCheckBoxState(panelTitle, StringFromList(i, allCheckBoxes), CHECKBOX_UNSELECTED)
	endfor

	SetCheckBoxState(panelTitle, "check_DataBrowser_DisplayADChan", CHECKBOX_SELECTED)

	SetSliderPositionIndex(panelTitle, "slider_dDAQ_regions", -1)
	DisableControl(panelTitle, "slider_dDAQ_regions")

	DB_ClearGraph(panelTitle)
	SetPopupMenuIndex(panelTitle, "popup_LBNumericalKeys", 0)
	SetPopupMenuIndex(panelTitle, "popup_LBTextualKeys", 0)
	PopupMenu popup_LBNumericalKeys, win=$panelTitle, value=#("\"" + NONE + "\"")
	PopupMenu popup_LBTextualKeys, win=$panelTitle, value=#("\"" + NONE + "\"")

	SearchForInvalidControlProcs(panelTitle)
End

Function DB_ButtonProc_Sweep(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	string panelTitle, ctrl
	variable step, sweepNo, currentSweep

	switch(ba.eventcode)
		case 2: // mouse up
			panelTitle = ba.win
			ctrl       = ba.ctrlName

			currentSweep = GetSetVariable(panelTitle, "setvar_DataBrowser_SweepNo")
			step = GetSetVariable(panelTitle, "setvar_DataBrowser_SweepStep")

			if(!cmpstr(ctrl, "button_DataBrowser_PrevSweep"))
				sweepNo = currentSweep - step
			elseif(!cmpstr(ctrl, "button_DataBrowser_NextSweep"))
				sweepNo = currentSweep + step
			else
				ASSERT(0, "unhandled control name")
			endif

			sweepNo = DB_ClipSweepNumber(panelTitle, sweepNo)
			SetSetVariable(panelTitle, "setvar_DataBrowser_SweepNo", sweepNo)
			OVS_InvertSweepSelection(panelTitle, sweepNO=sweepNo)
			DB_UpdateSweepPlot(panelTitle)
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
			SetAxis/A=2/W=$DB_GetLabNotebookGraph(panelTitle)
			break
	endswitch

	return 0
End

Function DB_PopMenuProc_LockDBtoDevice(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	switch(pa.eventcode)
		case 2: // mouse up
			DB_LockDBPanel(pa.win, pa.popStr)
			break
	endswitch

	return 0
End

Function DB_PopMenuProc_LabNotebook(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	string graph, popStr, panelTitle, device, ctrl

	switch(pa.eventCode)
		case 2: // mouse up
			panelTitle = pa.win
			graph      = DB_GetLabNoteBookGraph(panelTitle)
			popStr     = pa.popStr
			ctrl       = pa.ctrlName
			if(!CmpStr(popStr, NONE))
				break
			endif

			strswitch(ctrl)
				case "popup_LBNumericalKeys":
					Wave values = DB_GetNumericalValues(panelTitle)
					WAVE keys   = DB_GetNumericalKeys(panelTitle)
				break
				case "popup_LBTextualKeys":
					Wave values = DB_GetTextualValues(panelTitle)
					WAVE keys   = DB_GetTextualKeys(panelTitle)
				break
				default:
					ASSERT(0, "Unknown ctrl")
					break
			endswitch

			AddTraceToLBGraph(graph, keys, values, popStr)
		break
	endswitch

	return 0
End

Function DB_SetVarProc_SweepNo(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	string panelTitle
	variable sweepNo

	switch(sva.eventCode)
		case 1: // mouse up - when the scroll wheel is used on the mouse - "up or down"
		case 2: // Enter key - when a number is manually entered
		case 3: // Live update - happens when you hit the arrow keys associated with the set variable
			sweepNo = sva.dval
			paneltitle = sva.win

			DB_UpdateSweepPlot(panelTitle)
			OVS_InvertSweepSelection(panelTitle, sweepNo=sweepNo)
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

Function/S DB_GetLBTextualKeys(panelTitle)
	string panelTitle

	string device

	if(!windowExists(panelTitle))
		return NONE
	endif

	device = GetPopupMenuString(panelTitle, "popup_DB_lockedDevices")
	if(!CmpStr(device, NONE))
		return NONE
	endif

	WAVE/T keyWave = DB_GetTextualKeys(panelTitle)

	return AddListItem(NONE, GetLabNotebookSortedKeys(keyWave), ";", 0)
End

Function/S DB_GetLBNumericalKeys(panelTitle)
	string panelTitle

	string device

	if(!windowExists(panelTitle))
		return NONE
	endif

	device = GetPopupMenuString(panelTitle, "popup_DB_lockedDevices")
	if(!CmpStr(device, NONE))
		return NONE
	endif

	WAVE/T keyWave = DB_GetNumericalKeys(panelTitle)

	return AddListItem(NONE, GetLabNotebookSortedKeys(keyWave), ";", 0)
End

Function/S DB_GetAllDevicesWithData()

	return AddListItem(NONE, GetAllDevicesWithContent(), ";", 0)
End

Function DB_ButtonProc_SwitchXAxis(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	string panelTitle, graph

	switch(ba.eventCode)
		case 2: // mouse up
			panelTitle = ba.win
			graph      = DB_GetLabNoteBookGraph(panelTitle)
			WAVE numericalValues = DB_GetNumericalValues(panelTitle)
			WAVE textualValues   = DB_GetTextualValues(panelTitle)

			SwitchLBGraphXAxis(graph, numericalValues, textualValues)
			break
	endswitch

	return 0
End

Function DB_SliderProc_ChangedSetting(spa) : SliderControl
	STRUCT WMSliderAction &spa

	string panelTitle

	if(spa.eventCode > 0 && spa.eventCode & 0x1)
		panelTitle = spa.win
		DB_UpdateSweepPlot(panelTitle)
	endif

	return 0
End

Function DB_CheckProc_ChangedSetting(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	variable checked, channelNum
	string panelTitle, ctrl, channelType, device

	switch(cba.eventCode)
		case 2: // mouse up
			panelTitle = GetMainWindow(cba.win)
			ctrl       = cba.ctrlName
			checked    = cba.checked

			strswitch(ctrl)
				case "check_databrowser_dDAQMode":
					if(checked)
						EnableControl(panelTitle, "slider_dDAQ_regions")
					else
						DisableControl(panelTitle, "slider_dDAQ_regions")
					endif
					break
				default:
					if(StringMatch(ctrl, "check_channelSel_*"))
						DFREF dataBrowserDFR = DB_GetDataBrowserPath(panelTitle)
						WAVE channelSel      = GetChannelSelectionWave(dataBrowserDFR)
						ParseChannelSelectionControl(cba.ctrlName, channelType, channelNum)
						channelSel[channelNum][%$channelType] = checked
					endif
					break
			endswitch

			DB_UpdateSweepPlot(panelTitle)
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

Function DB_OpenChannelSelectionPanel(cba) : CheckBoxControl
	STRUCT WMCheckBoxAction &cba

	string win

	switch(cba.eventCode)
		case 2: // mouse up
			win = GetMainWindow(cba.win)
			DFREF dataBrowserDFR = DB_GetDataBrowserPath(win)
			WAVE channelSel      = GetChannelSelectionWave(dataBrowserDFR)
			ToggleChannelSelectionPanel(win, channelSel, "DB_CheckProc_ChangedSetting")
			break
	endswitch

	return 0
End

Function DB_CheckboxProc_ArtRemoval(cba) : CheckBoxControl
	STRUCT WMCheckBoxAction &cba

	string panelTitle, device

	switch(cba.eventCode)
		case 2: // mouse up
			panelTitle = GetMainWindow(cba.win)

			device = GetPopupMenuString(panelTitle, "popup_DB_lockedDevices")
			DFREF dfr = GetDeviceDataBrowserPath(device)
			WAVE listBoxWave = GetArtefactRemovalListWave(dfr)
			AR_TogglePanel(panelTitle, listBoxWave)
			DB_UpdateSweepPlot(panelTitle)
			break
	endswitch

	return 0
End

Function DB_CheckboxProc_OverlaySweeps(cba) : CheckBoxControl
	STRUCT WMCheckBoxAction &cba

	string panelTitle, device, sweepWaveList
	variable sweepNo

	switch(cba.eventCode)
		case 2: // mouse up
			panelTitle = GetMainWindow(cba.win)

			device = GetPopupMenuString(panelTitle, "popup_DB_lockedDevices")
			DFREF dfr = GetDeviceDataBrowserPath(device)
			WAVE/T listBoxWave        = GetOverlaySweepsListWave(dfr)
			WAVE listBoxSelWave       = GetOverlaySweepsListSelWave(dfr)
			WAVE/WAVE sweepSelChoices = GetOverlaySweepSelectionChoices(dfr)

			WAVE/T numericalValues = DB_GetNumericalValues(panelTitle)
			WAVE/T textualValues   = DB_GetTextualValues(panelTitle)
			sweepWaveList = DB_GetListOfSweepWaves(panelTitle)
			OVS_UpdatePanel(panelTitle, listBoxWave, listBoxSelWave, sweepSelChoices, sweepWaveList, textualValues=textualValues, numericalValues=numericalValues)
			if(!OVS_TogglePanel(panelTitle, listBoxWave, listBoxSelWave))
				sweepNo = GetSetVariable(panelTitle, "setvar_DataBrowser_SweepNo")
				OVS_ChangeSweepSelectionState(panelTitle, CHECKBOX_SELECTED, sweepNo=sweepNo)
			endif
			DB_UpdateSweepPlot(panelTitle)
			break
	endswitch

	return 0
End

static Function DB_SplitSweepsIfReq(panelTitle, sweepNo)
	string panelTitle
	variable sweepNo

	string device
	variable sweepModTime, numWaves, requireNewSplit, i

	device = GetPopupMenuString(panelTitle, "popup_DB_lockedDevices")

	if(!cmpstr(device, NONE))
		return NaN
	endif

	DFREF deviceDFR = GetDeviceDataPath(device)
	DFREF singleSweepDFR = GetSingleSweepFolder(deviceDFR, sweepNo)

	WAVE sweepWave  = GetSweepWave(device, sweepNo)
	WAVE configWave = GetConfigWave(sweepWave)

	sweepModTime = max(ModDate(sweepWave), ModDate(configWave))
	numWaves = CountObjectsDFR(singleSweepDFR, COUNTOBJECTS_WAVES)	
	requireNewSplit = (numWaves == 0)

	for(i = 0; i < numWaves; i += 1)
		WAVE/SDFR=singleSweepDFR wv = $GetIndexedObjNameDFR(singleSweepDFR, COUNTOBJECTS_WAVES, i)
		if(sweepModTime > ModDate(wv))
			// original sweep was modified, regenerate single sweep waves
			KillOrMoveToTrash(dfr=singleSweepDFR)
			DFREF singleSweepDFR = GetSingleSweepFolder(deviceDFR, sweepNo)
			requireNewSplit = 1
			break
		endif
	endfor

	if(!requireNewSplit)
		return NaN
	endif

	WAVE numericalValues = DB_GetNumericalValues(panelTitle)

	SplitSweepIntoComponents(numericalValues, sweepNo, sweepWave, configWave, targetDFR=singleSweepDFR)
End

Function DB_ButtonProc_RestoreData(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	string win, graph, traceList, artefactRemovalExtPanel
	variable autoRemoveOldState, zeroTracesOldState

	switch(ba.eventCode)
		case 2: // mouse up
			win   = ba.win
			graph = DB_GetMainGraph(win)
			traceList = GetAllSweepTraces(graph)
			ReplaceAllWavesWithBackup(graph, traceList)

			zeroTracesOldState = GetCheckBoxState(win, "check_DataBrowser_ZeroTraces")
			SetCheckBoxState(win, "check_DataBrowser_ZeroTraces", CHECKBOX_UNSELECTED)

			artefactRemovalExtPanel = AR_GetExtPanel(win)
			if(!WindowExists(artefactRemovalExtPanel))
				DB_UpdateSweepPlot(win)
			else
				autoRemoveOldState = GetCheckBoxState(artefactRemovalExtPanel, "check_auto_remove")
				SetCheckBoxState(artefactRemovalExtPanel, "check_auto_remove", CHECKBOX_UNSELECTED)
				DB_UpdateSweepPlot(win)
				SetCheckBoxState(artefactRemovalExtPanel, "check_auto_remove", autoRemoveOldState)
			endif

			SetCheckBoxState(win, "check_DataBrowser_ZeroTraces", zeroTracesOldState)
			break
	endswitch

	return 0
End

Function DB_ButtonProc_PerPulseAver(cba) : CheckBoxControl
	STRUCT WMCheckBoxAction &cba

	string win

	switch(cba.eventCode)
		case 2: // mouse up
			win = cba.win
			PA_TogglePanel(win)
			DB_UpdateSweepPlot(win)
			break
	endswitch

	return 0
End
