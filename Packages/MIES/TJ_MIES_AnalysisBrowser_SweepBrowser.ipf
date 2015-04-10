#pragma rtGlobals=3		// Use modern global access method and strict wave access.

static Function/S SB_GetSweepBrowserLeftPanel(graph)
	string graph

	return graph + "#P0"
End

static Function/S SB_GetGraph(win)
	string win

	return StringFromList(0, win, "#")
End

static Function/Wave SB_GetSweepBrowserMapFromGraph(graph)
	string graph

	return SB_GetSweepBrowserMap($SB_GetSweepBrowserFolder(graph))
End

static Function/Wave SB_GetSweepBrowserMap(sweepBrowser)
	DFREF sweepBrowser

	ASSERT(DataFolderExistsDFR(sweepBrowser), "Missing sweepBrowser DFR")
	WAVE/T/Z/SDFR=sweepBrowser wv = map
	if(WaveExists(wv))
		return wv
	endif

	Make/T/N=(MINIMUM_WAVE_SIZE, 4) sweepBrowser:map/Wave=wv

	SetDimLabel COLS, 0, ExperimentName, wv
	SetDimLabel COLS, 1, ExperimentFolder, wv
	SetDimLabel COLS, 2, Device, wv
	SetDimLabel COLS, 3, Sweep, wv

	SetNumberInWaveNote(wv, NOTE_INDEX, 0)

	return wv
End

static Function/S SB_GetSweepBrowserFolder(graph)
	string graph

	string folder = GetUserData(graph, "", "folder")
	ASSERT(DataFolderExists(folder), "Datafolder of the sweep browser could not be found")

	return folder
End

static Function/DF SB_GetSweepDataPathFromIndex(sweepBrowserDFR, mapIndex)
	DFREF sweepBrowserDFR
	variable mapIndex

	string device, expFolder, panel
	variable sweep

	WAVE/T sweepMap = SB_GetSweepBrowserMap(sweepBrowserDFR)

	if(!IsFinite(mapIndex) || mapIndex < 0 || mapIndex >= DimSize(sweepMap, ROWS))
		return $""
	endif

	device    = sweepMap[mapIndex][%Device]
	sweep     = str2num(sweepMap[mapIndex][%Sweep])
	expFolder = sweepMap[mapIndex][%ExperimentFolder]

	if(!IsFinite(sweep))
		return $""
	endif

	return $GetAnalysisSweepDataPathAS(expFolder, device, sweep)
End

static Function SB_SetFormerSweepNumber(win, sweepNo)
	string win
	variable sweepNo

	SetControlUserData(win, "popup_sweep_selector", LAST_SWEEP_USER_DATA, num2str(sweepNo))
End

static Function SB_GetFormerSweepNumber(win)
	string win

	return str2num(GetUserData(win, "popup_sweep_selector", LAST_SWEEP_USER_DATA))
End

/// @param sweepBrowserDFR datatfolder of the sweep browser
/// @param currentMapIndex index into the sweep browser map of the currently shown sweep
/// @param newMapIndex index into the sweep browser map of the new to-be-shown sweep
Function SB_PlotSweep(sweepBrowserDFR, currentMapIndex, newMapIndex)
	DFREF sweepBrowserDFR
	variable currentMapIndex, newMapIndex

	string device, expFolder, panel
	variable sweep, newWaveDisplayed, currentWaveDisplayed
	variable displayDAC, overlaySweep

	ASSERT(DataFolderExistsDFR(sweepBrowserDFR), "sweepBrowserDFR must exist")

	SVAR/SDFR=sweepBrowserDFR graph
	panel = SB_GetSweepBrowserLeftPanel(graph)

	DFREF newSweepDFR = SB_GetSweepDataPathFromIndex(sweepBrowserDFR, newMapIndex)
	if(!DataFolderExistsDFR(newSweepDFR))
		return 0
	endif

	// With overlay enabled:
	// if the last plotted sweep is already on the graph remove it and return
	if(GetCheckBoxState(panel, "check_SweepBrowser_SweepOverlay"))

		DFREF currentSweepDFR = SB_GetSweepDataPathFromIndex(sweepBrowserDFR, currentMapIndex)
		if(!DataFolderExistsDFR(currentSweepDFR))
			return 0
		endif

		newWaveDisplayed     = IsWaveDisplayedOnGraph(graph, dfr=newSweepDFR)
		currentWaveDisplayed = IsWaveDisplayedOnGraph(graph, dfr=currentSweepDFR)

		if(newWaveDisplayed && currentWaveDisplayed && !DataFolderRefsEqual(newSweepDFR, currentSweepDFR))
			RemoveTracesFromGraph(graph, dfr=currentSweepDFR)
			SetPopupMenuIndex(panel, "popup_sweep_selector", newMapIndex)
			SB_SetFormerSweepNumber(panel, newMapIndex)
			return NaN
		elseif(newWaveDisplayed)
			return NaN
		endif
	endif

	WAVE/T sweepMap = SB_GetSweepBrowserMap(sweepBrowserDFR)

	expFolder = sweepMap[newMapIndex][%ExperimentFolder]
	device    = sweepMap[newMapIndex][%Device]
	sweep     = str2num(sweepMap[newMapIndex][%Sweep])

	WAVE configWave = GetAnalysisConfigWave(expFolder, device, sweep)

	DFREF dfr = GetAnalysisLabNBFolder(expFolder, device)
	WAVE/SDFR=dfr numericValues

	displayDAC   = GetCheckBoxState(panel, "check_SweepBrowser_DisplayDAC")
	overlaySweep = GetCheckBoxState(panel, "check_SweepBrowser_SweepOverlay")

	CreateTiledChannelGraph(graph, configWave, sweep, numericValues, displayDAC, overlaySweep, sweepDFR=newSweepDFR)

	SetPopupMenuIndex(panel, "popup_sweep_selector", newMapIndex)
	SB_SetFormerSweepNumber(panel, newMapIndex)
End

Function SB_AddToSweepBrowser(sweepBrowser, expName, expFolder, device, sweep)
	DFREF sweepBrowser
	string expName, expFolder, device
	variable sweep

	variable index, foundExperiment, foundExpFolder, foundDevice, foundSweep
	string sweepStr = num2str(sweep)

	WAVE/T map = SB_GetSweepBrowserMap(sweepBrowser)

	index = GetNumberFromWaveNote(map, NOTE_INDEX)
	EnsureLargeEnoughWave(map, minimumSize=index)

	foundExperiment = WaveExists(FindIndizes(colLabel="ExperimentName", wvText=map, str=expName, endRow=index))
	foundExpFolder  = WaveExists(FindIndizes(colLabel="ExperimentFolder", wvText=map, str=expFolder, endRow=index))
	foundDevice     = WaveExists(FindIndizes(colLabel="Device", wvText=map, str=device, endRow=index))
	foundSweep      = WaveExists(FindIndizes(colLabel="Sweep", wvText=map, str=sweepStr, endRow=index))

	if(foundExperiment && foundExpFolder && foundDevice && foundSweep)
		// we already have that sweep in the map
		return NaN
	endif

	map[index][%ExperimentName]   = expName
	map[index][%ExperimentFolder] = expFolder
	map[index][%Device]           = device
	map[index][%Sweep]            = sweepStr

	SetNumberInWaveNote(map, NOTE_INDEX, index + 1)
End

Function SB_SweepBrowserWindowHook(s)
	STRUCT WMWinHookStruct &s

	variable hookResult, direction, currentSweep, newSweep
	string folder, graph, panel, win

	switch(s.eventCode)
		case 2:	 // Kill
			graph = s.winName

			folder = SB_GetSweepBrowserFolder(graph)

			KillWindow $graph
			KillOrMoveToTrash(folder)

			hookResult = 1
		case 22: // mouse wheel
			graph = s.winName

			if(!windowExists(graph))
				break
			endif

			win = SB_GetSweepBrowserLeftPanel(graph)

			direction =  sign(s.wheelDy)
			folder = SB_GetSweepBrowserFolder(graph)
			panel = SB_GetSweepBrowserLeftPanel(graph)

			currentSweep = GetPopupMenuIndex(panel, "popup_sweep_selector")

			if(GetCheckBoxState(win, "check_SweepBrowser_SweepOverlay"))
				newSweep = currentSweep + direction * GetSetVariable(win, "setvar_SweepBrowser_OverlaySkip")
			else
				newSweep = currentSweep + direction
			endif

			SB_PlotSweep($folder, currentSweep, newSweep)

			hookResult = 1
			break
	endswitch

	return hookResult // 0 if nothing done, else 1
End

Function/DF SB_CreateNewSweepBrowser()

	DFREF dfr = $"root:"
	DFREF sweepBrowserDFR = UniqueDataFolder(dfr, "sweepBrowser")

	SB_GetSweepBrowserMap(sweepBrowserDFR)

	Display/W=(220.5,208.25,654,495.5)/K=1/N=$UniqueName("SweepBrowser", 9, 1)
	string/G sweepBrowserDFR:graph = S_name
	SVAR/SDFR=sweepBrowserDFR graph

	SetWindow $graph, hook(cleanup)=SB_SweepBrowserWindowHook, userdata(folder)=GetDataFolder(1, sweepBrowserDFR)

	NewPanel/HOST=#/EXT=1/W=(156,0,0,383) as " "
	ModifyPanel fixedSize=0
	CheckBox check_SweepBrowser_DisplayDAC,pos={17,7},size={116,14},title="Display DA channels"
	CheckBox check_SweepBrowser_DisplayDAC,value= 0, proc=SB_CheckboxDisplayDAChannels
	SetVariable setvar_SweepBrowser_OverlaySkip,pos={38,53},size={64,16},title="Step"
	SetVariable setvar_SweepBrowser_OverlaySkip,limits={1,inf,1},value= _NUM:1
	CheckBox check_SweepBrowser_SweepOverlay,pos={18,36},size={95,14},title="Overlay Sweeps"
	CheckBox check_SweepBrowser_SweepOverlay,value= 0
	GroupBox group_sweep,pos={9,90},size={139,74},title="Sweep"
	GroupBox group_postSynPot,pos={9,266},size={137,92},title="Post-synaptic potentials"
	Button button_SweepBrowser_NextSweep,pos={84,136},size={60,20},title="Next",proc=SB_ButtonProc_ChangeSweep
	Button button_SweepBrowser_PrevSweep,pos={14,136},size={60,20},title="Previous",proc=SB_ButtonProc_ChangeSweep
	GroupBox group_actionPot,pos={9,175},size={138,60},title="Action potentials"
	PopupMenu popup_sweep_selector,pos={17,110},size={124,21}
	PopupMenu popup_sweep_selector,mode=1,proc=SB_PopupMenuSelectSweep,value=#("SB_GetSweepList(" + "\"" +  graph + "\")")
	SetActiveSubwindow ##
	NewPanel/HOST=#/EXT=0/W=(0,0,214,383) as "Analysis Results"
	ModifyPanel fixedSize=0
	NewNotebook /F=0 /N=NB0 /W=(16,29,196,362) /HOST=#
	Notebook kwTopWin, defaultTab=20, statusWidth=0, autoSave=1
	Notebook kwTopWin font="Arial", fSize=10, fStyle=0, textRGB=(0,0,0)
	Notebook kwTopWin, zdata= "GaqDU%ejN7!Z)%D?io>lbN?PWL]d_/WWX="
	Notebook kwTopWin, zdataEnd= 1
	SetActiveSubwindow ##

	return sweepBrowserDFR
End

Function/S SB_GetSweepList(graph)
	string graph

	string list = "", str
	variable numRows, i

	WAVE/T map = SB_GetSweepBrowserMapFromGraph(graph)

	numRows = GetNumberFromWaveNote(map, NOTE_INDEX)
	for(i = 0; i < numRows; i += 1)
		sprintf str, "Sweep %d [%s]", str2num(map[i][%Sweep]), GetBaseName(map[i][%ExperimentName])
		list = AddListItem(str, list, ";", Inf)
	endfor

	return list
End

Function SB_CheckboxDisplayDAChannels(cba) : CheckBoxControl
	STRUCT WMCheckBoxAction &cba

	string graph, win
	variable idx
	DFREF sweepDFR

	switch(cba.eventCode)
		case 2: // mouse up
			win   = cba.win
			graph = SB_GetGraph(win)
			idx   = GetPopupMenuIndex(win, "popup_sweep_selector")

			DFREF dfr = $SB_GetSweepBrowserFolder(graph)

			SB_PlotSweep(dfr, idx, idx)
			break
	endswitch
End

Function SB_PopupMenuSelectSweep(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	string graph, win

	switch(pa.eventCode)
		case 2: // mouse up
			win       = pa.win
			graph     = SB_GetGraph(pa.win)
			DFREF dfr = $SB_GetSweepBrowserFolder(graph)

			SB_PlotSweep(dfr, SB_GetFormerSweepNumber(win), pa.popNum - 1)
			break
	endswitch
End

Function SB_ButtonProc_ChangeSweep(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	string win, graph, ctrl
	variable currentSweep, newSweep, direction

	switch(ba.eventCode)
		case 2: // mouse up
			win   = ba.win
			graph = SB_GetGraph(win)
			ctrl  = ba.ctrlName

			currentSweep = GetPopupMenuIndex(win, "popup_sweep_selector")

			if(!cmpstr(ctrl, "button_SweepBrowser_PrevSweep"))
				direction = -1
			elseif(!cmpstr(ctrl, "button_SweepBrowser_NextSweep"))
				direction = +1
			else
				ASSERT(0, "unhandled control name")
			endif

			if(GetCheckBoxState(win, "check_SweepBrowser_SweepOverlay"))
				newSweep = currentSweep + direction * GetSetVariable(win, "setvar_SweepBrowser_OverlaySkip")
			else
				newSweep = currentSweep + direction
			endif

			DFREF dfr = $SB_GetSweepBrowserFolder(graph)
			SB_PlotSweep(dfr, currentSweep, newSweep)
			break
	endswitch

	return 0
End
