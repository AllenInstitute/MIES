#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma igorVersion=7.0

/// @file MIES_DataBrowser.ipf
/// @brief __DB__ Panel for browsing acquired data during acquisition

// stock igor
#include <Resize Controls>

// third party includes
#include ":ACL_TabUtilities"
#include ":ACL_UserdataEditor"

// ZeroMQ procedures
#include ":..:ZeroMQ:procedures:ZeroMQ_Interop"

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

Function DB_OpenDataBrowser()
	Execute "DataBrowser()"
End

static Function/DF DB_GetDataPath(panelTitle)
	string panelTitle

	return $GetUserData(panelTitle, "", "DataFolderPath") + ":Data"
End

static Function/S DB_GetNotebookSubWindow(panelTitle)
	string panelTitle

	return panelTitle + "#WaveNoteDisplay"
End

Function/S DB_GetMainGraph(panelTitle)
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
		PopupMenu popup_LBNumericalKeys, win=$panelTitleNew, value=#("\"" + NONE + "\"")
		PopupMenu popup_LBTextualKeys, win=$panelTitleNew, value=#("\"" + NONE + "\"")
		return NaN
	endif

	panelTitleNew = UniqueName("DB_" + device, 9, 0)
	DoWindow/W=$panelTitle/C $panelTitleNew

	SetWindow $panelTitleNew, userdata($MIES_PANEL_TYPE_USER_DATA) = MIES_DATABROWSER_PANEL
	SetWindow $panelTitleNew, userdata(DataFolderPath)   = GetDevicePathAsString(device)
	PopupMenu popup_LBNumericalKeys, win=$panelTitleNew, value=#("DB_GetLBNumericalKeys(\"" + panelTitleNew + "\")")
	PopupMenu popup_LBTextualKeys, win=$panelTitleNew, value=#("DB_GetLBTextualKeys(\"" + panelTitleNew + "\")")
	DB_PlotSweep(panelTitleNew, currentSweep=0)
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

	SetValDisplay(panelTitle, "valdisp_DataBrowser_LastSweep", var=last)
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

	string traceList, trace, device, artefactRemovalExtPanel
	variable numTraces, i, sweepNo
	variable firstSweep, lastSweep
	variable newWaveDisplayed, currentWaveDisplayed

	DFREF dfr = DB_GetDataPath(panelTitle)

	if(!DataFolderExistsDFR(dfr))
		return NaN
	endif

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

	Struct PostPlotSettings pps
	device = GetPopupMenuString(panelTitle, "popup_DB_lockedDevices")
	pps.averageDataFolder = GetDeviceDataBrowserPath(device)
	pps.averageTraces     = GetCheckboxState(panelTitle, "check_DataBrowser_AverageTraces")
	pps.zeroTraces        = GetCheckBoxState(panelTitle, "check_DataBrowser_ZeroTraces")
	pps.timeAlignRefTrace = ""
	pps.timeAlignMode     = TIME_ALIGNMENT_NONE
	pps.artefactRemoval   = GetCheckBoxState(panelTitle, "CheckBox_DataBrowser_OpenArtRem")
	pps.sweepNo           = newSweep
	pps.sweepFolder       = GetDeviceDataPath(device)
	WAVE pps.numericalValues = DB_GetNumericalValues(panelTitle)
	FUNCREF FinalUpdateHookProto pps.finalUpdateHook = DB_PanelUpdate

	artefactRemovalExtPanel = AR_GetExtPanel(panelTitle)
	if(WindowExists(artefactRemovalExtPanel))
		pps.autoRemove = GetCheckBoxState(artefactRemovalExtPanel, "check_auto_remove")
	endif

	// With overlay enabled:
	// if the last plotted sweep is already on the graph remove it and return
	// otherwise clear the plot
	if(GetCheckBoxState(panelTitle, "check_DataBrowser_SweepOverlay"))

		WAVE/Z/SDFR=dfr newSweepWave     = $GetSweepWaveName(newSweep)
		WAVE/Z/SDFR=dfr currentSweepWave = $GetSweepWaveName(currentSweep)

		newWaveDisplayed     = IsWaveDisplayedOnGraph(graph, wv=newSweepWave)
		currentWaveDisplayed = IsWaveDisplayedOnGraph(graph, wv=currentSweepWave)

		if(newWaveDisplayed && currentWaveDisplayed && !WaveRefsEqual(newSweepWave, currentSweepWave))
			RemoveTracesFromGraph(graph, wv=currentSweepWave)
			sweepNo = DB_ClipSweepNumber(panelTitle, newSweep)
			SetSetVariable(panelTitle, "setvar_DataBrowser_SweepNo", sweepNo)
			pps.sweepNo = sweepNo
			DB_SetFormerSweepNumber(panelTitle, sweepNo)
			PostPlotTransformations(graph, pps)
			return NaN
		elseif(newWaveDisplayed)
			PostPlotTransformations(graph, pps)
			return NaN
		endif
	endif

	SetSetVariable(panelTitle, "setvar_DataBrowser_SweepNo", newSweep)
	WAVE/Z/SDFR=dfr wv = $GetSweepWaveName(newSweep)

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

	Wave config  = GetConfigWave(sweep)
	string graph = DB_GetMainGraph(panelTitle)

	Wave numericalValues = DB_GetNumericalValues(panelTitle)
	Wave textualValues   = DB_GetTextualValues(panelTitle)

	STRUCT TiledGraphSettings tgs
	tgs.displayDAC      = GetCheckBoxState(panelTitle, "check_DataBrowser_DisplayDAchan")
	tgs.displayTTL      = GetCheckBoxState(panelTitle, "check_DataBrowser_DisplayTTL")
	tgs.displayADC      = GetCheckBoxState(panelTitle, "check_DataBrowser_DisplayADChan")
	tgs.overlaySweep    = GetCheckBoxState(panelTitle, "check_DataBrowser_SweepOverlay")
	tgs.overlayChannels = GetCheckBoxState(panelTitle, "check_databrowser_OverlayChan")
	tgs.dDAQDisplayMode = GetCheckBoxState(panelTitle, "check_databrowser_dDAQMode")
	tgs.oodDAQHeadstageRegions = GetSliderPositionIndex(panelTitle, "slider_oodDAQ_regions")

	DB_SplitSweepsIfReq(panelTitle, sweepNo)

	WAVE channelSel = GetChannelSelectionWave(dfr)
	return CreateTiledChannelGraph(graph, config, sweepNo, numericalValues, textualValues, tgs, dfr, channelSelWave=channelSel)
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

Function DB_UpdateToLastSweep(panel)
	string panel

	if(GetCheckBoxState(panel, "check_DataBrowser_AutoUpdate"))
		DB_PlotSweep(panel, newSweep=Inf)
	endif
End

Window DataBrowser() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /K=1 /W=(8,449,1220,1169) as "DataBrowser"
	Button button_DataBrowser_NextSweep,pos={628.00,630.00},size={425.00,45.00},proc=DB_ButtonProc_Sweep,title="Next Sweep \\W649"
	Button button_DataBrowser_NextSweep,help={"Displays the next sweep (sweep no. = last sweep number + step)"}
	Button button_DataBrowser_NextSweep,userdata(ResizeControlsInfo)= A"!!,J.!!#D-J,hsdJ,hnmz!!#](Aon\"q<C^(Dzzzzzzzzzzzzz!!#](Aon\"q<C^(Dz"
	Button button_DataBrowser_NextSweep,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#?(FEDG<zzzzzzzzzzz"
	Button button_DataBrowser_NextSweep,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	Button button_DataBrowser_NextSweep,fSize=20
	Button button_DataBrowser_PrevSweep,pos={20.00,630.00},size={425.00,45.00},proc=DB_ButtonProc_Sweep,title="\\W646 Previous Sweep"
	Button button_DataBrowser_PrevSweep,help={"Displays the previous sweep (sweep no. = last sweep number - step)"}
	Button button_DataBrowser_PrevSweep,userdata(ResizeControlsInfo)= A"!!,BY!!#D-J,hsdJ,hnmz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_DataBrowser_PrevSweep,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#?(FEDG<zzzzzzzzzzz"
	Button button_DataBrowser_PrevSweep,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	Button button_DataBrowser_PrevSweep,fSize=20
	ValDisplay valdisp_DataBrowser_LastSweep,pos={530.00,634.00},size={89.00,34.00},bodyWidth=60,title="of"
	ValDisplay valdisp_DataBrowser_LastSweep,help={"The number of the last sweep acquired for the device assigned to the data browser"}
	ValDisplay valdisp_DataBrowser_LastSweep,userdata(ResizeControlsInfo)= A"!!,IjJ,htYJ,hpA!!#=kz!!#](Aon\"q<C^(Dzzzzzzzzzzzzz!!#](Aon\"q<C^(Dz"
	ValDisplay valdisp_DataBrowser_LastSweep,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#?(FEDG<zzzzzzzzzzz"
	ValDisplay valdisp_DataBrowser_LastSweep,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	ValDisplay valdisp_DataBrowser_LastSweep,fSize=24,frame=2,fStyle=1
	ValDisplay valdisp_DataBrowser_LastSweep,limits={0,0,0},barmisc={0,1000}
	ValDisplay valdisp_DataBrowser_LastSweep,value= #"0"
	ValDisplay valdisp_DataBrowser_LastSweep,barBackColor= (56576,56576,56576)
	CheckBox check_DataBrowser_DisplayDAchan,pos={20.00,9.00},size={122.00,15.00},proc=DB_CheckProc_ChangedSetting,title="Display DA channels"
	CheckBox check_DataBrowser_DisplayDAchan,help={"Display DA (digital to analog) channel data"}
	CheckBox check_DataBrowser_DisplayDAchan,userdata(ResizeControlsInfo)= A"!!,BY!!#:r!!#@X!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_DataBrowser_DisplayDAchan,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_DataBrowser_DisplayDAchan,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_DataBrowser_DisplayDAchan,value= 0
	CheckBox check_databrowser_OverlayChan,pos={205.00,27.00},size={107.00,15.00},proc=DB_CheckProc_ChangedSetting,title="Overlay Channels"
	CheckBox check_databrowser_OverlayChan,help={"Displays all channels using a single  vertical axis"}
	CheckBox check_databrowser_OverlayChan,userdata(ResizeControlsInfo)= A"!!,G]!!#=;!!#@:!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_databrowser_OverlayChan,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_databrowser_OverlayChan,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_databrowser_OverlayChan,value= 0
	CheckBox check_databrowser_dDAQMode,pos={205.00,47.00},size={85.00,15.00},proc=DB_CheckProc_ChangedSetting,title="dDAQ Viewer"
	CheckBox check_databrowser_dDAQMode,help={"Enable dedicated support for viewing distributed DAQ data"}
	CheckBox check_databrowser_dDAQMode,userdata(ResizeControlsInfo)= A"!!,G]!!#>J!!#?c!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_databrowser_dDAQMode,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_databrowser_dDAQMode,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_databrowser_dDAQMode,value= 0
	Button button_DataBrowser_OpenChanSel,pos={155.00,25.00},size={40.00,20.00},proc=DB_OpenChannelSelectionPanel,title="Chan"
	Button button_DataBrowser_OpenChanSel,help={"Open the channel selection dialog, allows to disable single channels and headstages"}
	Button button_DataBrowser_OpenChanSel,userdata(ResizeControlsInfo)= A"!!,G+!!#=+!!#>.!!#<Xz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_DataBrowser_OpenChanSel,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafn!(TR7zzzzzzzzzz"
	Button button_DataBrowser_OpenChanSel,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafn!(TR7zzzzzzzzzzzzz!!!"
	TitleBox ListBox_DataBrowser_NoteDisplay,pos={1756,75},size={197.00,39.00}
	TitleBox ListBox_DataBrowser_NoteDisplay,labelBack=(62208,62208,62208),fSize=8
	TitleBox ListBox_DataBrowser_NoteDisplay,frame=0
	TitleBox ListBox_DataBrowser_NoteDisplay,userdata(ResizeControlsInfo)= A"!!,LBJ,hp%!!#AT!!#>*z!!#o2B4uAezzzzzzzzzzzzzz!!#o2B4uAezz"
	TitleBox ListBox_DataBrowser_NoteDisplay,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	TitleBox ListBox_DataBrowser_NoteDisplay,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_DataBrowser_SweepOverlay,pos={205.00,9.00},size={97.00,15.00},proc=DB_CheckProc_ChangedSetting,title="Overlay Sweeps"
	CheckBox check_DataBrowser_SweepOverlay,help={"Adds unplotted sweep to graph. Removes plotted sweep from graph."}
	CheckBox check_DataBrowser_SweepOverlay,userdata(ResizeControlsInfo)= A"!!,G]!!#:r!!#@&!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_DataBrowser_SweepOverlay,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_DataBrowser_SweepOverlay,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_DataBrowser_SweepOverlay,value= 0
	CheckBox check_DataBrowser_AutoUpdate,pos={484.00,9.00},size={159.00,15.00},title="Display last sweep acquired"
	CheckBox check_DataBrowser_AutoUpdate,help={"Displays the last sweep acquired when data acquistion is ongoing"}
	CheckBox check_DataBrowser_AutoUpdate,userdata(ResizeControlsInfo)= A"!!,IX!!#:r!!#A.!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_DataBrowser_AutoUpdate,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_DataBrowser_AutoUpdate,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_DataBrowser_AutoUpdate,value= 0
	PopupMenu popup_DB_lockedDevices,pos={639.00,684.00},size={275.00,19.00},bodyWidth=170,proc=DB_PopMenuProc_LockDBtoDevice,title="Device assingment:"
	PopupMenu popup_DB_lockedDevices,help={"Select a data acquistion device to display data"}
	PopupMenu popup_DB_lockedDevices,userdata(ResizeControlsInfo)= A"!!,J0^]6bQ!!#BCJ,hm&z!!#](Aon\"q<C^(Dzzzzzzzzzzzzz!!#](Aon\"q<C^(Dz"
	PopupMenu popup_DB_lockedDevices,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#?(FEDG<!(TR7zzzzzzzzzz"
	PopupMenu popup_DB_lockedDevices,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<!(TR7zzzzzzzzzzzzz!!!"
	PopupMenu popup_DB_lockedDevices,mode=1,popvalue="- none -",value= #"DB_GetAllDevicesWithData()"
	CheckBox check_DataBrowser_DisplayTTL,pos={20.00,27.00},size={128.00,15.00},proc=DB_CheckProc_ChangedSetting,title="Display TTL Channels"
	CheckBox check_DataBrowser_DisplayTTL,help={"Display TTL channel data"}
	CheckBox check_DataBrowser_DisplayTTL,userdata(ResizeControlsInfo)= A"!!,BY!!#=;!!#@d!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_DataBrowser_DisplayTTL,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_DataBrowser_DisplayTTL,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox check_DataBrowser_DisplayTTL,value= 0
	CheckBox check_DataBrowser_DisplayADChan,pos={20.00,45.00},size={124.00,15.00},proc=DB_CheckProc_ChangedSetting,title="Display AD Channels"
	CheckBox check_DataBrowser_DisplayADChan,help={"Display AD (analog to digital) channel data"}
	CheckBox check_DataBrowser_DisplayADChan,userdata(ResizeControlsInfo)= A"!!,BY!!#>B!!#@\\!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_DataBrowser_DisplayADChan,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_DataBrowser_DisplayADChan,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox check_DataBrowser_DisplayADChan,value= 1
	CheckBox check_DataBrowser_AverageTraces,pos={349.00,9.00},size={92.00,15.00},proc=DB_CheckProc_ChangedSetting,title="Average traces"
	CheckBox check_DataBrowser_AverageTraces,help={"Displays the average (pink trace) of overlayed sweeps for each channel"}
	CheckBox check_DataBrowser_AverageTraces,userdata(ResizeControlsInfo)= A"!!,HiJ,hkH!!#?q!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_DataBrowser_AverageTraces,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_DataBrowser_AverageTraces,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_DataBrowser_AverageTraces,value= 0
	Button button_DataBrowser_setaxis,pos={20.00,682.00},size={150.00,23.00},proc=DB_ButtonProc_AutoScale,title="Autoscale"
	Button button_DataBrowser_setaxis,help={"Autoscale sweep data"}
	Button button_DataBrowser_setaxis,userdata(ResizeControlsInfo)= A"!!,BY!!#D:J,hqP!!#<pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_DataBrowser_setaxis,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#?(FEDG<zzzzzzzzzzz"
	Button button_DataBrowser_setaxis,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_DataBrowser_SweepNo,pos={454.00,634.00},size={74.00,35.00},proc=DB_SetVarProc_SweepNo
	SetVariable setvar_DataBrowser_SweepNo,help={"Sweep number of last sweep plotted"}
	SetVariable setvar_DataBrowser_SweepNo,userdata(ResizeControlsInfo)= A"!!,II!!#D.J,hp#!!#=oz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_DataBrowser_SweepNo,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#?(FEDG<zzzzzzzzzzz"
	SetVariable setvar_DataBrowser_SweepNo,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_DataBrowser_SweepNo,userdata(lastSweep)=  "NaN",fSize=24
	SetVariable setvar_DataBrowser_SweepNo,limits={0,0,1},value= _NUM:0,live= 1
	PopupMenu popup_LBNumericalKeys,pos={1041,460},size={150.00,19.00},bodyWidth=150,proc=DB_PopMenuProc_LabNotebook
	PopupMenu popup_LBNumericalKeys,help={"Select numeric lab notebook data to display"}
	PopupMenu popup_LBNumericalKeys,mode=1,popvalue="- none -",value= #"DB_GetLBNumericalKeys(\"\")"
	PopupMenu popup_LBNumericalKeys,userdata(ResizeControlsInfo)= A"!!,K>+94dk!!#A%!!#<Pz!!#N3Bk1ct<C^(Dzzzzzzzzzzzzz!!#N3Bk1ct<C^(Dz"
	PopupMenu popup_LBNumericalKeys,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#N3Bk1ct<C]S7zzzzzzzzzz"
	PopupMenu popup_LBNumericalKeys,userdata(ResizeControlsInfo) += A"zzz!!#N3Bk1ct<C]S7zzzzzzzzzzzzz!!!"
	PopupMenu popup_LBTextualKeys,pos={1041,489},size={150.00,19.00},bodyWidth=150,proc=DB_PopMenuProc_LabNotebook
	PopupMenu popup_LBTextualKeys,help={"Select textual lab notebook data to display"}
	PopupMenu popup_LBTextualKeys,mode=1,popvalue="- none -",value= #"DB_GetLBTextualKeys(\"\")"
	PopupMenu popup_LBTextualKeys,userdata(ResizeControlsInfo)= A"!!,K>+94e$J,hqP!!#<Pz!!#N3Bk1ct<C^(Dzzzzzzzzzzzzz!!#N3Bk1ct<C^(Dz"
	PopupMenu popup_LBTextualKeys,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#N3Bk1ct<C]S7zzzzzzzzzz"
	PopupMenu popup_LBTextualKeys,userdata(ResizeControlsInfo) += A"zzz!!#N3Bk1ct<C]S7zzzzzzzzzzzzz!!!"
	Button button_clearlabnotebookgraph,pos={1075,521},size={80.00,20.00},proc=DB_ButtonProc_ClearGraph,title="Clear graph"
	Button button_clearlabnotebookgraph,userdata(ResizeControlsInfo)= A"!!,KB?iWRr5QF-D!!#<Xz!!#N3Bk1ct<C^(Dzzzzzzzzzzzzz!!#N3Bk1ct<C^(Dz"
	Button button_clearlabnotebookgraph,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#N3Bk1ct<C]S7zzzzzzzzzz"
	Button button_clearlabnotebookgraph,userdata(ResizeControlsInfo) += A"zzz!!#N3Bk1ct<C]S7zzzzzzzzzzzzz!!!"
	Button button_switchxaxis,pos={1075,548},size={80.00,20.00},proc=DB_ButtonProc_SwitchXAxis,title="Switch X-axis"
	Button button_switchxaxis,help={"Toggle lab notebook horizontal axis between time of day or sweep number"}
	Button button_switchxaxis,userdata(ResizeControlsInfo)= A"!!,KB?iWS$!!#?Y!!#<Xz!!#N3Bk1ct<C^(Dzzzzzzzzzzzzz!!#N3Bk1ct<C^(Dz"
	Button button_switchxaxis,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#N3Bk1ct<C]S7zzzzzzzzzz"
	Button button_switchxaxis,userdata(ResizeControlsInfo) += A"zzz!!#N3Bk1ct<C]S7zzzzzzzzzzzzz!!!"
	GroupBox group_labnotebook_ctrls,pos={1033,439},size={170.00,78.00},title="Settings History Column"
	GroupBox group_labnotebook_ctrls,userdata(ResizeControlsInfo)= A"!!,K=+94d`J,hqd!!#?Uz!!#N3Bk1ct<C^(Dzzzzzzzzzzzzz!!#N3Bk1ct<C^(Dz"
	GroupBox group_labnotebook_ctrls,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#N3Bk1ct<C]S7zzzzzzzzzz"
	GroupBox group_labnotebook_ctrls,userdata(ResizeControlsInfo) += A"zzz!!#N3Bk1ct<C]S7zzzzzzzzzzzzz!!!"
	CheckBox check_DataBrowser_ZeroTraces,pos={349.00,27.00},size={73.00,15.00},proc=DB_CheckProc_ChangedSetting,title="Zero traces"
	CheckBox check_DataBrowser_ZeroTraces,help={"Sets the baseline of the sweep to zero by differentiating and the integrating a copy of the sweep"}
	CheckBox check_DataBrowser_ZeroTraces,userdata(ResizeControlsInfo)= A"!!,HiJ,hmf!!#?K!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_DataBrowser_ZeroTraces,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_DataBrowser_ZeroTraces,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_DataBrowser_ZeroTraces,value= 0
	SetVariable setvar_DataBrowser_SweepStep,pos={498.00,674.00},size={67.00,18.00},bodyWidth=40,title="Step"
	SetVariable setvar_DataBrowser_SweepStep,help={"Set the increment between sweeps"}
	SetVariable setvar_DataBrowser_SweepStep,userdata(ResizeControlsInfo)= A"!!,I_!!#D8J,hoj!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_DataBrowser_SweepStep,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#?(FEDG<zzzzzzzzzzz"
	SetVariable setvar_DataBrowser_SweepStep,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_DataBrowser_SweepStep,userdata(lastSweep)=  "0",fSize=12
	SetVariable setvar_DataBrowser_SweepStep,limits={1,inf,1},value= _NUM:1
	CheckBox checkbox_DB_AutoScaleVertAxVisX,pos={179.00,686.00},size={40.00,15.00},proc=DB_ScaleAxis,title="Vis X"
	CheckBox checkbox_DB_AutoScaleVertAxVisX,help={"Scale the y axis to the visible x data range"}
	CheckBox checkbox_DB_AutoScaleVertAxVisX,userdata(ResizeControlsInfo)= A"!!,GC!!#D;J,hnY!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox checkbox_DB_AutoScaleVertAxVisX,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#?(FEDG<zzzzzzzzzzz"
	CheckBox checkbox_DB_AutoScaleVertAxVisX,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	CheckBox checkbox_DB_AutoScaleVertAxVisX,value= 0
	Slider slider_oodDAQ_regions,pos={657.00,12.00},size={233.00,54.00},disable=2,proc=DB_SliderProc_ChangedSetting
	Slider slider_oodDAQ_regions,help={"Allows to view only oodDAQ regions from the selected headstage. Choose -1 to display all."}
	Slider slider_oodDAQ_regions,userdata(ResizeControlsInfo)= A"!!,J55QF)8!!#B#!!#>fz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Slider slider_oodDAQ_regions,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:DuaGl<C]S7zzzzzzzzzz"
	Slider slider_oodDAQ_regions,userdata(ResizeControlsInfo) += A"zzz!!#u:DuaGl<C]S7zzzzzzzzzzzzz!!!"
	Slider slider_oodDAQ_regions,limits={-1,7,1},value= -1,vert= 0
	CheckBox CheckBox_DataBrowser_OpenArtRem,pos={349.00,46.00},size={106.00,15.00},proc=DB_CheckBoxProc_ArtRemoval,title="Artefact Removal"
	CheckBox CheckBox_DataBrowser_OpenArtRem,help={"Open the artefact removal dialog"}
	CheckBox CheckBox_DataBrowser_OpenArtRem,userdata(ResizeControlsInfo)= A"!!,HiJ,hnq!!#@8!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox CheckBox_DataBrowser_OpenArtRem,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafn!(TR7zzzzzzzzzz"
	CheckBox CheckBox_DataBrowser_OpenArtRem,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafn!(TR7zzzzzzzzzzzzz!!!"
	CheckBox CheckBox_DataBrowser_OpenArtRem,value= 0
	Button button_databrowser_restore,pos={483.00,29.00},size={76.00,21.00},proc=DB_ButtonProc_RestoreData,title="Restore data"
	Button button_databrowser_restore,help={"Restore the data in its pristine state without any modifications"}
	Button button_databrowser_restore,userdata(ResizeControlsInfo)= A"!!,IWJ,hn!!!#?Q!!#<`z!!#N3Bk1ct<C^(Dzzzzzzzzzzzzz!!#N3Bk1ct<C^(Dz"
	Button button_databrowser_restore,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#N3Bk1ct<C]S7zzzzzzzzzz"
	Button button_databrowser_restore,userdata(ResizeControlsInfo) += A"zzz!!#N3Bk1ct<C]S7zzzzzzzzzzzzz!!!"
	DefineGuide UGV0={FR,-200},UGH1={FT,0.584722,FB},UGH0={UGH1,0.662207,FB}
	SetWindow kwTopWin,hook(ResizeControls)=ResizeControls#ResizeControlsHook
	SetWindow kwTopWin,userdata(ResizeControlsInfo)= A"!!*'\"z!!#ERJ,htozzzzzzzzzzzzzzzzzzzzz"
	SetWindow kwTopWin,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzzzzzzzzzzzzzzz"
	SetWindow kwTopWin,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzzzzzzzzz!!!"
	SetWindow kwTopWin,userdata(ResizeControlsGuides)=  "UGV0;UGH1;UGH0;"
	SetWindow kwTopWin,userdata(ResizeControlsInfoUGV0)= A":-hTC3`S[N0KW?-:-(dOFC@LVDg-86E][6':dmEFF(KAR85E,T>#.mm5tj<n4&A^O8Q88W:-(*`0et@80KVd)8OQ!%3_!\"/7o`,K75?nc;FO8U:K'ha8P`)B/M]\"63r"
	SetWindow kwTopWin,userdata(ResizeControlsInfoUGH1)= A":-hTC3`S[@0frH.:-(dOFC@LVDg-86E][6':dmEFF(KAR85E,T>#.mm5tj<o4&A^O8Q88W:-(3e0eP.64%E:B6q&gk7T;H><CoSI1-.lk4&SL@:et\"]<(Tk\\3\\W0D3&EQL1-5"
	SetWindow kwTopWin,userdata(ResizeControlsInfoUGH0)= A":-hTC3`S[@0KW?-:-(dOFC@LVDg-86E][6':dmEFF(KAR85E,T>#.mm5tj<o4&A^O8Q88W:-(9f3A*!>4%E:B6q&gk<C]S74%E:B6q&jl7RB1778-NR;b9q[:JNr)/iGUC1,(XK"
	SetWindow kwTopWin,userdata(MiesPanelType)=  "DataBrowser"
	Execute/Q/Z "SetWindow kwTopWin sizeLimit={909,540,inf,inf}" // sizeLimit requires Igor 7 or later
	Display/W=(18,72,1039,362)/FG=($"",$"",UGV0,UGH1)/HOST=#
	SetWindow kwTopWin,userdata(MiesPanelType)=  "DataBrowser"
	RenameWindow #,DataBrowserGraph
	SetActiveSubwindow ##
	NewNotebook /F=1 /N=WaveNoteDisplay /W=(1052,72,1220,341)/FG=(UGV0,$"",FR,UGH1) /HOST=# /OPTS=10
	Notebook kwTopWin, defaultTab=36, autoSave= 1, showRuler=0, rulerUnits=1
	Notebook kwTopWin newRuler=Normal, justification=0, margins={0,0,128}, spacing={0,0,0}, tabs={}, rulerDefaults={"Arial",10,0,(0,0,0)}
	Notebook kwTopWin, zdata= "GaqDU%ejN7!Z)u^\"(F_BAcgt=>?2+c&.'2989@[[K>tpnK\"?L6M8jCF(5$*oAmu5P!$@%)/c"
	Notebook kwTopWin, zdataEnd= 1
	Execute/Q/Z "SetWindow kwTopWin sizeLimit={909,540,inf,inf}" // sizeLimit requires Igor 7 or later
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
	SetValDisplay(panelTitle, "valdisp_DataBrowser_LastSweep", var=0)

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

	SetSliderPositionIndex(panelTitle, "slider_oodDAQ_regions", -1)
	DisableControl(panelTitle, "slider_oodDAQ_regions")

	DB_ClearGraph(panelTitle)
	SetPopupMenuIndex(panelTitle, "popup_LBNumericalKeys", 0)
	SetPopupMenuIndex(panelTitle, "popup_LBTextualKeys", 0)
	PopupMenu popup_LBNumericalKeys, win=$panelTitle, value=#("\"" + NONE + "\"")
	PopupMenu popup_LBTextualKeys, win=$panelTitle, value=#("\"" + NONE + "\"")
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

	return AddListItem(NONE, GetAllDevicesWithData(), ";", 0)
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

	if(spa.eventCode & 0x1)
		panelTitle = spa.win
		DB_PlotSweep(panelTitle)
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
				case "check_DataBrowser_SweepOverlay":
					if(checked)
						DisableControls(panelTitle, "check_DataBrowser_DisplayDAchan;check_databrowser_OverlayChan;check_DataBrowser_DisplayADChan;check_DataBrowser_DisplayTTL;check_databrowser_dDAQMode")
					else
						EnableControls(panelTitle, "check_DataBrowser_DisplayDAchan;check_databrowser_OverlayChan;check_DataBrowser_DisplayADChan;check_DataBrowser_DisplayTTL;check_databrowser_dDAQMode")
					endif
				break
				case "check_databrowser_dDAQMode":
					if(checked)
						EnableControl(panelTitle, "slider_oodDAQ_regions")
					else
						DisableControl(panelTitle, "slider_oodDAQ_regions")
					endif
				break
				default:
				if(StringMatch(ctrl, "check_channelSel_*"))
					DFREF dfr = DB_GetDataPath(panelTitle)
					WAVE channelSel = GetChannelSelectionWave(dfr)
					ParseChannelSelectionControl(cba.ctrlName, channelType, channelNum)
					channelSel[channelNum][%$channelType] = checked
				endif
				break
			endswitch

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

Function DB_OpenChannelSelectionPanel(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	string panelTitle

	switch(ba.eventCode)
		case 2: // mouse up
			panelTitle = GetMainWindow(ba.win)
			DFREF dfr = DB_GetDataPath(panelTitle)
			WAVE channelSel = GetChannelSelectionWave(dfr)
			ToggleChannelSelectionPanel(panelTitle, channelSel, "DB_CheckProc_ChangedSetting")
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
			DB_PlotSweep(panelTitle)
			break
	endswitch

	return 0
End

Function DB_SplitSweepsIfReq(panelTitle, sweepNo)
	string panelTitle
	variable sweepNo

	string device, singleSweepFolder

	device = GetPopupMenuString(panelTitle, "popup_DB_lockedDevices")

	if(!cmpstr(device, NONE))
		return NaN
	endif

	DFREF deviceDFR = GetDeviceDataPath(device)
	DFREF singleSweepDFR = GetSingleSweepFolder(deviceDFR, sweepNo)

	if(CountObjectsDFR(singleSweepDFR, COUNTOBJECTS_WAVES) > 0)
		return NaN
	endif

	WAVE sweepWave  = GetSweepWave(device, sweepNo)
	WAVE configWave = GetConfigWave(sweepWave)
	WAVE numericalValues = DB_GetNumericalValues(panelTitle)

	SplitSweepIntoComponents(numericalValues, sweepNo, sweepWave, configWave, targetDFR=singleSweepDFR)
End

Function DB_ButtonProc_RestoreData(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	string graph, traceList

	switch(ba.eventCode)
		case 2: // mouse up
			graph = DB_GetMainGraph(ba.win)
			traceList = GetAllSweepTraces(graph)
			ReplaceAllWavesWithBackup(graph, traceList)
			break
	endswitch

	return 0
End
