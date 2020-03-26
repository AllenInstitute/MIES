#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_SB
#endif

/// @file MIES_AnalysisBrowser_SweepBrowser.ipf
/// @brief __SB__  Visualization of sweep data in the analysis browser

static StrConstant AXES_SCALING_CHECKBOXES = "check_Display_VisibleXrange;check_Display_EqualYrange;check_Display_EqualYignore"
static StrConstant WAVE_NOTE_LAYOUT_KEY    = "WAVE_LAYOUT_VERSION"

Function/S SB_GetSweepBrowserLeftPanel(win)
	string win

	return BSP_GetPanel(win)
End

static Function/Wave SB_GetSweepBrowserMapFromGraph(win)
	string win

	return SB_GetSweepBrowserMap(SB_GetSweepBrowserFolder(win))
End

static Function/Wave SB_GetSweepBrowserMap(sweepBrowser)
	DFREF sweepBrowser

	ASSERT(DataFolderExistsDFR(sweepBrowser), "Missing SweepBrowser DFR")

	Variable versionOfWave = 1

	WAVE/T/Z/SDFR=sweepBrowser wv = map
	if(WaveExists(wv))
		if(GetNumberFromWaveNote(wv, WAVE_NOTE_LAYOUT_KEY) == versionOfWave)
			return wv
		endif
	else
		Make/T/N=(MINIMUM_WAVE_SIZE, 4) sweepBrowser:map/Wave=wv
		SetNumberInWaveNote(wv, NOTE_INDEX, 0)
	endif

	SetDimLabel COLS, 0, FileName, wv
	SetDimLabel COLS, 1, DataFolder, wv
	SetDimLabel COLS, 2, Device, wv
	SetDimLabel COLS, 3, Sweep, wv

	SetNumberInWaveNote(wv, WAVE_NOTE_LAYOUT_KEY, versionOfWave)

	return wv
End

Function/DF SB_GetSweepBrowserFolder(win)
	string win

	return BSP_GetFolder(win, MIES_BSP_PANEL_FOLDER)
End

static Function/DF SB_GetSweepDataPathFromIndex(sweepBrowserDFR, mapIndex)
	DFREF sweepBrowserDFR
	variable mapIndex

	string device, expFolder
	variable sweep

	WAVE/T sweepMap = SB_GetSweepBrowserMap(sweepBrowserDFR)

	if(!IsFinite(mapIndex) || mapIndex < 0 || mapIndex >= DimSize(sweepMap, ROWS))
		return $""
	endif

	device    = sweepMap[mapIndex][%Device]
	sweep     = str2num(sweepMap[mapIndex][%Sweep])
	expFolder = sweepMap[mapIndex][%DataFolder]

	if(!IsFinite(sweep))
		return $""
	endif

	return $GetAnalysisSweepDataPathAS(expFolder, device, sweep)
End

Function SB_GetIndexFromSweepDataPath(win, dataDFR)
	string win
	DFREF dataDFR

	variable mapIndex, sweepNo
	string device, expFolder, sweepFolder

	DFREF sweepBrowserDFR = SB_GetSweepBrowserFolder(win)
	WAVE/T sweepMap = SB_GetSweepBrowserMap(sweepBrowserDFR)

	SplitSTring/E="root:MIES:Analysis:([^:]+):([^:]+):sweep:([^:]+):" GetDataFolder(1, dataDFR), expFolder, device, sweepFolder
	ASSERT(V_flag == 3, "Unmatched string")

	sweepNo = ExtractSweepNumber(sweepFolder)

	WAVE/Z indizesDataFolder = FindIndizes(sweepMap, colLabel="DataFolder", str=expFolder)
	WAVE/Z indizesDevice     = FindIndizes(sweepMap, colLabel="Device", str=device)
	WAVE/Z indizesSweep      = FindIndizes(sweepMap, colLabel="Sweep", str=num2str(sweepNo))

	ASSERT(WaveExists(indizesDevice) && WaveExists(indizesSweep) && WaveExists(indizesDataFolder), "Map could not be queried")

	// indizesSweep is the shortest one
	Duplicate/FREE indizesSweep, matches
	matches[] = (IsFinite(GetRowIndex(indizesDevice, val=indizesSweep[p])) && IsFinite(GetRowIndex(indizesDataFolder, val=indizesSweep[p]))) ? indizesSweep[p] : NaN

	WaveTransform zapNans, matches

	ASSERT(Dimsize(matches, ROWS) == 1, "Unexpected number of matches")

	return matches[0]
End

/// @see DB_GraphUpdate
Function SB_PanelUpdate(win)
	string win

	SB_ScaleAxes(win)
End

/// @brief set graph userdata similar to DB_SetUserData()
///
/// @param win 	name of main window or external subwindow in SweepBrowser
static Function SB_SetUserData(win)
	string win

	SetWindow $win, userdata = ""

	DFREF dfr = UniqueDataFolder(root:, "sweepBrowser")
	BSP_SetFolder(win, dfr, MIES_BSP_PANEL_FOLDER)
End

/// @see DB_InitPostPlotSettings
static Function SB_InitPostPlotSettings(graph, pps)
	string graph
	STRUCT PostPlotSettings &pps

	string bsPanel = BSP_GetPanel(graph)

	pps.averageDataFolder = SB_GetSweepBrowserFolder(graph)
	pps.averageTraces     = GetCheckboxState(bsPanel, "check_Calculation_AverageTraces")
	pps.zeroTraces        = GetCheckBoxState(bsPanel, "check_Calculation_ZeroTraces")
	pps.timeAlignRefTrace = ""
	pps.timeAlignMode     = TIME_ALIGNMENT_NONE
	pps.hideSweep         = GetCheckBoxState(bsPanel, "check_SweepControl_HideSweep")

	PA_GatherSettings(graph, pps)

	FUNCREF FinalUpdateHookProto pps.finalUpdateHook = SB_PanelUpdate
End

/// @brief Return numeric labnotebook entries
///
/// @param graph    sweep browser graph
/// @param mapIndex index into the sweep browser map, equal to the index into the popup menu (0-based)
/// @param key      labnotebook key
///
/// @return wave with the setting for each headstage or an invalid wave reference if the setting does not exist
static Function/WAVE SB_GetSweepPropertyFromNumLBN(graph, mapIndex, key)
	string graph
	variable mapIndex
	string key

	string device, expFolder
	variable sweep

	DFREF sweepBrowserDFR = SB_GetSweepBrowserFolder(graph)
	WAVE/T sweepMap = SB_GetSweepBrowserMap(sweepBrowserDFR)

	if(!IsFinite(mapIndex) || mapIndex < 0 || mapIndex >= DimSize(sweepMap, ROWS))
		return $""
	endif

	device    = sweepMap[mapIndex][%Device]
	sweep     = str2num(sweepMap[mapIndex][%Sweep])
	expFolder = sweepMap[mapIndex][%DataFolder]

	WAVE numericalValues = GetAnalysLBNumericalValues(expFolder, device)

	return GetLastSetting(numericalValues, sweep, key, DATA_ACQUISITION_MODE)
End

/// @brief Return a list of experiments from which the sweeps in the sweep browser
/// graph originated from
///
/// @param graph sweep browser name
Function/S SB_GetListOfExperiments(graph)
	string graph

	DFREF sweepBrowserDFR = SB_GetSweepBrowserFolder(graph)
	WAVE/T sweepMap = SB_GetSweepBrowserMap(sweepBrowserDFR)

	variable numEntries, i
	string experiment
	string list = ""

	numEntries = GetNumberFromWaveNote(sweepMap, NOTE_INDEX)
	for(i = 0; i < numEntries; i += 1)
		experiment = sweepMap[i][%FileName]
		if(WhichListItem(experiment, list) == -1)
			list = AddListItem(experiment, list, ";", Inf)
		endif
	endfor

	return list
End

/// @brief Return a text wave with information about the channel waves
/// of the sweep browser graph of all or a specific experiment
///
/// The returned textwave will have multiple columns with different information on each wave.
///
/// Rows:
///  - One entry for each wave
///
/// Columns:
/// - 0: channel number
/// - 1: absolute path to the wave
/// - 2: headstage
///
/// \rst
/// .. code-block:: igorpro
///
///		variable channelNumber, headstage, numWaves, i
///		string graph   = "SweepBrowser1" // name of an existing sweep browser graph
///		string channel = "DA"
///		WAVE/T wv =  SB_GetChannelInfoFromGraph(graph, channel)
///
///		numWaves = DimSize(wv, ROWS)
///		for(i = 0; i < numWaves; i += 1)
///			WAVE data     = $(wv[i][%path])
///			channelNumber = str2num(wv[i][%channel])
///			headstage     = str2num(wv[i][%headstage])
///
///			printf "Channel %d acquired by headstage %d is stored in %s\r", channelNumber, headstage, NameOfWave(data)
///		endfor
/// \endrst
///
/// @param graph                                  name of main window or external subwindow in SweepBrowser
/// @param channel                                type of the channel, one of #ITC_CHANNEL_NAMES
/// @param experiment [optional, defaults to all] name of the experiment the channel wave should originate from
Function/WAVE SB_GetChannelInfoFromGraph(graph, channel, [experiment])
	string graph, channel, experiment

	variable i, j, numEntries, idx, numWaves, channelNumber
	string list, headstage, path

	ASSERT(FindListitem(channel, ITC_CHANNEL_NAMES) != -1, "Given channel could not be found in ITC_CHANNEL_NAMES")

	DFREF sweepBrowserDFR = SB_GetSweepBrowserFolder(graph)
	WAVE/T sweepMap = SB_GetSweepBrowserMap(sweepBrowserDFR)

	Make/FREE/T/N=(MINIMUM_WAVE_SIZE, 3) channelMap

	SetDimLabel COLS, 0, channel,   channelMap
	SetDimLabel COLS, 1, path,      channelMap
	SetDimLabel COLS, 2, headstage, channelMap

	if(ParamIsDefault(experiment))
		numEntries = GetNumberFromWaveNote(sweepMap, NOTE_INDEX)
		Make/FREE/N=(numEntries) indizes = p
	else
		WAVE/Z indizes = FindIndizes(sweepMap, colLabel="FileName", str=experiment)
		ASSERT(WaveExists(indizes), "The experiment could not be found in the sweep browser")
		numEntries = DimSize(indizes, ROWS)
	endif

	for(i = 0; i < numEntries; i += 1)
		DFREF dfr = SB_GetSweepDataPathFromIndex(sweepBrowserDFR, indizes[i])

		list = GetListOfObjects(dfr, channel + "_.*", fullpath=1)
		if(IsEmpty(list))
			continue
		endif

		WAVE headstages = SB_GetSweepPropertyFromNumLBN(graph, i, "Headstage Active")
		WAVE ADCs = SB_GetSweepPropertyFromNumLBN(graph, i, "ADC")
		WAVE DACs = SB_GetSweepPropertyFromNumLBN(graph, i, "DAC")

		numWaves = ItemsInList(list)
		for(j = 0; j < numWaves; j += 1)
			path = StringFromList(j, list)
			channelNumber = str2num(RemovePrefix(GetBaseName(path), startstr=channel + "_"))
			ASSERT(IsFinite(channelNumber), "Extracted non finite channel number")

			strswitch(channel)
				case "AD":
					FindValue/V=(channelNumber) ADCs
					break
				case "DA":
					FindValue/V=(channelNumber) DACs
					break
				default:
					ASSERT(0, "Unsupported channel")
					break
			endswitch

			ASSERT(V_value != -1, "Could not find the channel number")
			ASSERT(headstages[V_value] == 1, "The headstage of the channel was not active but should have been")

			headstage = num2str(V_value)

			EnsureLargeEnoughWave(channelMap, minimumSize=idx)
			channelMap[idx][%channel]    = num2str(channelNumber)
			channelMap[idx][%path]      = path
			channelMap[idx][%headstage] = headstage
			idx += 1
		endfor
	endfor

	Redimension/N=(idx, -1) channelMap

	return channelMap
End

Function SB_UpdateSweepPlot(win, [newSweep])
	string win
	variable newSweep

	string device, dataFolder, graph, bsPanel, scPanel, lbPanel, experiment
	variable mapIndex, i, numEntries, sweepNo, highlightSweep, traceIndex, currentSweep

	graph = GetMainWindow(win)
	bsPanel   = BSP_GetPanel(graph)
	scPanel   = BSP_GetSweepControlsPanel(win)
	lbPanel   = BSP_GetNotebookSubWindow(win)

	if(BSP_MainPanelNeedsUpdate(graph))
		DoAbortNow("The main panel is too old to be usable. Please close it and open a new one.")
	endif

	DFREF sweepBrowserDFR = SB_GetSweepBrowserFolder(graph)
	ASSERT(DataFolderExistsDFR(sweepBrowserDFR), "sweepBrowserDFR must exist")

	if(!ParamIsDefault(newSweep))
		SetPopupMenuIndex(scPanel, "popup_SweepControl_Selector", newSweep)
	endif

	STRUCT TiledGraphSettings tgs
	tgs.overlaySweep 	= OVS_IsActive(graph)
	tgs.displayDAC      = GetCheckBoxState(bsPanel, "check_BrowserSettings_DAC")
	tgs.displayADC      = GetCheckBoxState(bsPanel, "check_BrowserSettings_ADC")
	tgs.displayTTL      = GetCheckBoxState(bsPanel, "check_BrowserSettings_TTL")
	tgs.overlayChannels = GetCheckBoxState(bsPanel, "check_BrowserSettings_OChan")
	tgs.splitTTLBits    = GetCheckBoxState(bsPanel, "check_BrowserSettings_splitTTL")
	tgs.dDAQDisplayMode = GetCheckBoxState(bsPanel, "check_BrowserSettings_dDAQ")
	tgs.dDAQHeadstageRegions = BSP_GetDDAQ(win)
	tgs.hideSweep       = GetCheckBoxState(bsPanel, "check_SweepControl_HideSweep")

	STRUCT PostPlotSettings pps
	SB_InitPostPlotSettings(graph, pps)

	WAVE/Z sweepsToOverlay = OVS_GetSelectedSweeps(graph, OVS_SWEEP_SELECTION_INDEX)

	WAVE axesRanges = GetAxesRanges(graph)

	WAVE/T cursorInfos = GetCursorInfos(graph)
	RemoveTracesFromGraph(graph)

	WAVE/T sweepMap = SB_GetSweepBrowserMap(sweepBrowserDFR)
	WAVE channelSel = GetChannelSelectionWave(sweepBrowserDFR)

	currentSweep = GetPopupMenuIndex(scPanel, "popup_SweepControl_Selector")
	if(!WaveExists(sweepsToOverlay))
		Make/FREE/N=1 sweepsToOverlay = currentSweep
	endif

	WAVE axisLabelCache = GetAxisLabelCacheWave()

	numEntries = DimSize(sweepsToOverlay, ROWS)
	for(i = 0; i < numEntries; i += 1)
		mapIndex = sweepsToOverlay[i]

		dataFolder = sweepMap[mapIndex][%DataFolder]
		device     = sweepMap[mapIndex][%Device]
		experiment = sweepMap[mapIndex][%FileName]
		sweepNo    = str2num(sweepMap[mapIndex][%Sweep])

		WAVE/Z activeHS = OVS_ParseIgnoreList(graph, highlightSweep, index=mapIndex)
		tgs.highlightSweep = highlightSweep

		if(WaveExists(activeHS))
			Duplicate/FREE channelSel, sweepChannelSel
			sweepChannelSel[0, NUM_HEADSTAGES - 1][%HEADSTAGE] = sweepChannelSel[p][%HEADSTAGE] && activeHS[p]
		else
			WAVE sweepChannelSel = channelSel
		endif

		WAVE numericalValues = GetAnalysLBNumericalValues(dataFolder, device)
		DFREF sweepDFR       = GetAnalysisSweepPath(dataFolder, device)

		WAVE configWave = GetAnalysisConfigWave(dataFolder, device, sweepNo)
		WAVE textualValues = GetAnalysLBTextualValues(dataFolder, device)

		CreateTiledChannelGraph(graph, configWave, sweepNo, numericalValues, textualValues, tgs, sweepDFR, axisLabelCache, traceIndex, experiment, channelSelWave=sweepChannelSel)
		AR_UpdateTracesIfReq(graph, sweepDFR, numericalValues, sweepNo)
	endfor

	RestoreCursors(graph, cursorInfos)

	dataFolder = sweepMap[currentSweep][%DataFolder]
	device     = sweepMap[currentSweep][%Device]
	sweepNo    = str2num(sweepMap[currentSweep][%Sweep])
	DFREF sweepDATAdfr = GetAnalysisSweepDataPath(dataFolder, device, sweepNo)
	SVAR/Z sweepNote = sweepDATAdfr:note
	if(SVAR_EXISTS(sweepNote))
		Notebook $lbPanel text = "Sweep note: \r " + sweepNote
	endif
	Notebook $lbPanel selection={startOfFile, endOfFile} // select entire contents of notebook

	PostPlotTransformations(graph, pps)
	SetAxesRanges(graph, axesRanges)
End

Function SB_AddToSweepBrowser(sweepBrowser, fileName, dataFolder, device, sweep)
	DFREF sweepBrowser
	string fileName, dataFolder, device
	variable sweep

	variable index
	string sweepStr = num2str(sweep)

	WAVE/T map = SB_GetSweepBrowserMap(sweepBrowser)

	index = GetNumberFromWaveNote(map, NOTE_INDEX)
	EnsureLargeEnoughWave(map, minimumSize=index)

	Duplicate/FREE/R=[0][]/T map, singleRow

	singleRow = ""
	singleRow[0][%FileName]         = fileName
	singleRow[0][%DataFolder]       = dataFolder
	singleRow[0][%Device]           = device
	singleRow[0][%Sweep]            = sweepStr

	if(IsFinite(GetRowWithSameContent(map, singleRow, 0)))
		// we already have that sweep in the map
		return NaN
	endif

	map[index][%FileName]         = fileName
	map[index][%DataFolder]       = dataFolder
	map[index][%Device]           = device
	map[index][%Sweep]            = sweepStr

	SetNumberInWaveNote(map, NOTE_INDEX, index + 1)
End

/// @see DB_HandleTimeAlignPropChange
static Function SB_HandleTimeAlignPropChange(win)
	string win

	string bsPanel, graph

	graph = GetMainWindow(win)
	bsPanel = BSP_GetPanel(graph)

	STRUCT PostPlotSettings pps
	SB_InitPostPlotSettings(graph, pps)

	TimeAlignGatherSettings(bsPanel, pps)

	PostPlotTransformations(graph, pps)
End

static Function SB_ScaleAxes(win)
	string win

	string graph, bsPanel
	variable visXRange, equalY, equalYIgn, level

	graph      = GetMainWindow(win)
	bsPanel    = BSP_GetPanel(win)
	visXRange  = GetCheckBoxState(bsPanel, "check_Display_VisibleXrange")
	equalY     = GetCheckBoxState(bsPanel, "check_Display_EqualYrange")
	equalYIgn  = GetCheckBoxState(bsPanel, "check_Display_EqualYignore")

	ASSERT(visXRange + equalY + equalYIgn <= 1, "Only one scaling mode is allowed to be selected")

	if(visXRange)
		AutoscaleVertAxisVisXRange(graph)
	elseif(equalY)
		EqualizeVerticalAxesRanges(graph, ignoreAxesWithLevelCrossing=0)
	elseif(equalYIgn)
		level = GetSetVariable(bsPanel, "setvar_Display_EqualYlevel")
		EqualizeVerticalAxesRanges(graph, ignoreAxesWithLevelCrossing=1, level=level)
	else
		// do nothing
	endif
End

Function SB_SweepBrowserWindowHook(s)
	STRUCT WMWinHookStruct &s

	string graph, bsPanel, scPanel, ctrl
	variable hookResult

	graph   = GetMainWindow(s.winName)
	bsPanel = BSP_GetPanel(graph)
	scPanel = BSP_GetSweepControlsPanel(graph)

	switch(s.eventCode)
		case 2:	 // Kill
			DFREF sweepBrowserDFR = SB_GetSweepBrowserFolder(graph)

			KillWindow $graph
			KillOrMoveToTrash(dfr = sweepBrowserDFR)

			hookResult = 1
			break
		case 22: // mouse wheel
			if(!windowExists(graph))
				break
			endif

			if(sign(s.wheelDy) == 1) // positive
				ctrl = "button_SweepControl_PrevSweep"
			else //negative
				ctrl = "button_SweepControl_NextSweep"
			endif

			PGC_SetAndActivateControl(scPanel, ctrl)

			hookResult = 1
			break
	endswitch

	return hookResult // 0 if nothing done, else 1
End

Function/DF SB_OpenSweepBrowser()

	string mainWin, renameWin

	Execute "DataBrowser()"

	mainWin = GetMainWindow(GetCurrentWindow())

	AddVersionToPanel(mainWin, SWEEPBROWSER_PANEL_VERSION)
	BSP_SetSweepBrowser(mainWin)

	SetWindow $mainWin, hook(cleanup)=SB_SweepBrowserWindowHook
	SB_SetUserData(mainWin)


	DFREF sweepBrowserDFR = BSP_GetFolder(mainWin, MIES_BSP_PANEL_FOLDER)
	SB_GetSweepBrowserMap(sweepBrowserDFR)

	renameWin = UniqueName(SWEEPBROWSER_WINDOW_TITLE, 9, 1)
	DoWindow/W=$mainWin/C $renameWin
	mainWin = renameWin

	string/G sweepBrowserDFR:graph = mainWin

	BSP_InitPanel(mainWin)
	SB_PanelUpdate(mainWin)
	return sweepBrowserDFR
End

Function/S SB_GetSweepList(win)
	string win

	string list = "", str
	variable numRows, i

	WAVE/T map = SB_GetSweepBrowserMapFromGraph(win)

	numRows = GetNumberFromWaveNote(map, NOTE_INDEX)
	for(i = 0; i < numRows; i += 1)
		sprintf str, "Sweep %d [%s.%s]", str2num(map[i][%Sweep]), ReplaceString(";", GetBaseName(map[i][%FileName]), "_"), GetFileSuffix(map[i][%FileName])
		list = AddListItem(str, list, ";", Inf)
	endfor

	return list
End

/// @brief Returns a list of all sweeps of the form "Sweep_0;Sweep_1;...".
///
/// Can contain duplicates!
Function/S SB_GetPlainSweepList(win)
	string win

	string list = "", str
	variable numRows, i

	WAVE/T map = SB_GetSweepBrowserMapFromGraph(win)

	numRows = GetNumberFromWaveNote(map, NOTE_INDEX)
	for(i = 0; i < numRows; i += 1)
		str  = GetSweepWaveName(str2num(map[i][%Sweep]))
		list = AddListItem(str, list, ";", Inf)
	endfor

	return list
End

/// @brief Return a wave reference wave with all numerical value labnotebook waves
///
/// @param win         SweepBrowser data window
/// @param sweepNumber [optional, default: all] return the labnotebook only for a specific sweep
Function/WAVE SB_GetNumericalValuesWaves(win, [sweepNumber])
	string win
	variable sweepNumber

	variable numRows = 0

	WAVE/T map = SB_GetSweepBrowserMapFromGraph(win)
	if(ParamIsDefault(sweepNumber))
		numRows = GetNumberFromWaveNote(map, NOTE_INDEX)
		Make/FREE/N=(numRows) indices = p
	else
		WAVE/Z indices = FindIndizes(map, colLabel = "Sweep", var = sweepNumber)
		if(WaveExists(indices))
			numRows = DimSize(indices, ROWS)
		endif
	endif

	Make/WAVE/FREE/N=(numRows) allNumericalValues
	allNumericalValues[] = GetAnalysLBNumericalValues(map[indices][%DataFolder], map[indices][%Device])

	return allNumericalValues
End

/// @brief Return a wave reference wave with all textual value labnotebook waves
///
/// @param win         SweepBrowser data window
/// @param sweepNumber [optional, default: all] return the labnotebook only for a specific sweep
Function/WAVE SB_GetTextualValuesWaves(win, [sweepNumber])
	string win
	variable sweepNumber

	variable numRows = 0

	WAVE/T map = SB_GetSweepBrowserMapFromGraph(win)
	if(ParamIsDefault(sweepNumber))
		numRows = GetNumberFromWaveNote(map, NOTE_INDEX)
		Make/FREE/N=(numRows) indices = p
	else
		WAVE/Z indices = FindIndizes(map, colLabel = "Sweep", var = sweepNumber)
		if(WaveExists(indices))
			numRows = DimSize(indices, ROWS)
		endif
	endif

	Make/WAVE/FREE/N=(numRows) allTextualValues
	allTextualValues[] = GetAnalysLBTextualValues(map[p][%DataFolder], map[p][%Device])

	return allTextualValues
End

Function SB_PopupMenuSelectSweep(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	string win
	variable newSweep

	switch(pa.eventCode)
		case 2: // mouse up
			win = pa.win
			newSweep = pa.popNum - 1
			if(OVS_IsActive(win))
				OVS_ChangeSweepSelectionState(win, CHECKBOX_SELECTED, index=newSweep)
			endif
			SetSetVariable(win, "setvar_SweepControl_SweepNo", newSweep)
			SB_UpdateSweepPlot(win)
			break
	endswitch
End

Function SB_ButtonProc_ChangeSweep(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	string graph
	variable firstSweep, lastSweep, index

	graph = GetMainWindow(ba.win)

	switch(ba.eventCode)
		case 2: // mouse up
			firstSweep = 0
			lastSweep = ItemsInList(SB_GetSweepList(graph)) - 1
			index = BSP_UpdateSweepControls(graph, ba.ctrlName, firstSweep, lastSweep)

			if(OVS_IsActive(graph))
				OVS_ChangeSweepSelectionState(graph, CHECKBOX_SELECTED, index=index)
			endif

			SB_UpdateSweepPlot(graph, newSweep=index)
			break
	endswitch

	return 0
End

Function SB_DoTimeAlignment(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			SB_HandleTimeAlignPropChange(ba.win)
			break
	endswitch

	return 0
End

Function SB_CheckProc_ScaleAxes(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	string ctrls, graph, bsPanel
	variable numCtrls, i

	graph   = GetMainWindow(cba.win)
	bsPanel = BSP_GetPanel(graph)

	switch( cba.eventCode )
		case 2: // mouse up
			if(cba.checked)
				ctrls = ListMatch(AXES_SCALING_CHECKBOXES, "!" + cba.ctrlName)
				numCtrls = ItemsInList(ctrls)
				for(i = 0; i < numCtrls; i += 1)
					SetCheckBoxState(bsPanel, StringFromList(i, ctrls), CHECKBOX_UNSELECTED)
				endfor
			endif

			if(GetCheckBoxState(bsPanel, "check_Display_EqualYignore"))
				EnableControl(bsPanel, "setvar_Display_EqualYlevel")
			else
				DisableControl(bsPanel, "setvar_Display_EqualYlevel")
			endif

			SB_ScaleAxes(graph)
			break
	endswitch

	return 0
End

Function SB_AxisScalingLevelCross(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	string graph, bsPanel

	graph   = GetMainWindow(sva.win)
	bsPanel = BSP_GetPanel(graph)

	switch(sva.eventCode)
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			if(GetCheckBoxState(bsPanel, "check_Display_EqualYignore"))
				SB_ScaleAxes(graph)
			endif
			break
	endswitch

	return 0
End

Function SB_ButtonProc_ExportTraces(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	string graph = GetMainWindow(ba.win)

	switch(ba.eventCode)
		case 2: // mouse up
			SBE_ShowExportPanel(graph)
			break
	endswitch

	return 0
End

Function SB_ButtonProc_FindMinis(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	variable numTraces, i, first, last
	string graph, list, trace

	graph = GetMainWindow(ba.win)

	switch(ba.eventCode)
		case 2: // mouse up
			list = GetAllSweepTraces(graph)

			first = NumberByKey("POINT", CsrInfo(A, graph))
			last  = NumberByKey("POINT", CsrInfo(B, graph))
			[first, last] = MinMax(first, last)

			DFREF workDFR = UniqueDataFolder(SB_GetSweepBrowserFolder(graph), "findminis")

			numTraces = ItemsInList(list)
			for(i = 0; i < numTraces; i += 1)
				trace = StringFromList(i, list)
				WAVE full = TraceNameToWaveRef(graph, trace)
				if(IsFinite(first) && isFinite(last))
					Duplicate/R=[first, last] full, workDFR:$(NameOfWave(full) + "_res")/Wave=wv
				else
					WAVE wv = full
				endif

				EDC_FindMinis(workDFR, wv)
			endfor
			break
	endswitch

	return 0
End

Function SB_CheckProc_ChangedSetting(cba) : CheckBoxControl
	STRUCT WMCheckBoxAction &cba

	string graph, bsPanel, scPanel, ctrl, channelType, device
	variable checked, channelNum
	DFREF sweepDFR

	graph   = GetMainWindow(cba.win)
	bsPanel = BSP_GetPanel(graph)
	scPanel = BSP_GetSweepControlsPanel(graph)

	switch(cba.eventCode)
		case 2: // mouse up
			ctrl      = cba.ctrlName
			checked   = cba.checked

			if(BSP_MainPanelNeedsUpdate(graph))
				DoAbortNow("The main panel is too old to be usable. Please close it and open a new one.")
			endif

			DFREF dfr = SB_GetSweepBrowserFolder(graph)
			strswitch(ctrl)
				case "check_BrowserSettings_dDAQ":
					if(checked)
						EnableControl(bsPanel, "slider_BrowserSettings_dDAQ")
					else
						DisableControl(bsPanel, "slider_BrowserSettings_dDAQ")
					endif
					break
				default:
					if(StringMatch(ctrl, "check_channelSel_*"))
						WAVE channelSel = GetChannelSelectionWave(dfr)
						BSP_ParseChannelSelectionControl(cba.ctrlName, channelType, channelNum)
						channelSel[channelNum][%$channelType] = checked
					endif
					break
			endswitch

			SB_UpdateSweepPlot(graph)
			break
	endswitch

	return 0
End

Function SB_ButtonProc_RestoreData(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	string graph, bsPanel, traceList
	variable autoRemoveOldState

	graph   = GetMainWindow(ba.win)
	bsPanel = BSP_GetPanel(graph)

	switch(ba.eventCode)
		case 2: // mouse up
			traceList = GetAllSweepTraces(graph)
			ReplaceAllWavesWithBackup(graph, traceList)

			if(!AR_IsActive(graph))
				SB_UpdateSweepPlot(graph)
			else
				autoRemoveOldState = GetCheckBoxState(bsPanel, "check_auto_remove")
				SetCheckBoxState(bsPanel, "check_auto_remove", CHECKBOX_UNSELECTED)
				SB_UpdateSweepPlot(graph)
				SetCheckBoxState(bsPanel, "check_auto_remove", autoRemoveOldState)
			endif
			break
	endswitch

	return 0
End

Function SB_CheckProc_OverlaySweeps(cba) : CheckBoxControl
	STRUCT WMCheckBoxAction &cba

	string graph, bsPanel, scPanel
	variable index

	graph   = GetMainWindow(cba.win)
	bsPanel = BSP_GetPanel(graph)
	scPanel = BSP_GetSweepControlsPanel(graph)

	switch(cba.eventCode)
		case 2: // mouse up
			BSP_SetOVSControlStatus(bsPanel)

			DFREF dfr = SB_GetSweepBrowserFolder(graph)
			WAVE/T listBoxWave        = GetOverlaySweepsListWave(dfr)
			WAVE listBoxSelWave       = GetOverlaySweepsListSelWave(dfr)
			WAVE/WAVE sweepSelChoices = GetOverlaySweepSelectionChoices(dfr)

			WAVE/WAVE allNumericalValues = SB_GetNumericalValuesWaves(graph)
			WAVE/WAVE allTextualValues   = SB_GetTextualValuesWaves(graph)

			OVS_UpdatePanel(graph, listBoxWave, listBoxSelWave, sweepSelChoices, allTextualValues=allTextualValues, allNumericalValues=allNumericalValues)
			if(OVS_IsActive(graph))
				index = GetPopupMenuIndex(scPanel, "popup_SweepControl_Selector")
				OVS_ChangeSweepSelectionState(bsPanel, CHECKBOX_SELECTED, index=index)
			endif
			SB_UpdateSweepPlot(graph)
			break
	endswitch

	return 0
End
