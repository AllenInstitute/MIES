#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_SB
#endif

/// @file MIES_AnalysisBrowser_SweepBrowser.ipf
/// @brief __SB__  Visualization of sweep data in the analysis browser

static Function/Wave SB_GetSweepBrowserMapFromGraph(win)
	string win

	return GetSweepBrowserMap(SB_GetSweepBrowserFolder(win))
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

	WAVE/T sweepMap = GetSweepBrowserMap(sweepBrowserDFR)

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

	WAVE/T sweepMap = SB_GetSweepBrowserMapFromGraph(win)

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

/// @brief set graph userdata similar to DB_SetUserData()
///
/// @param win 	name of main window or external subwindow in SweepBrowser
static Function SB_SetUserData(win)
	string win

	SetWindow $win, userdata = ""

	DFREF dfr = UniqueDataFolder(root:, "sweepBrowser")
	BSP_SetFolder(win, dfr, MIES_BSP_PANEL_FOLDER)
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

	WAVE/T sweepMap = SB_GetSweepBrowserMapFromGraph(graph)

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

	WAVE/T sweepMap = SB_GetSweepBrowserMapFromGraph(graph)

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

	WAVE/T sweepMap = SB_GetSweepBrowserMapFromGraph(graph)

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

	string device, dataFolder, graph, scPanel, lbPanel, experiment
	variable mapIndex, i, numEntries, sweepNo, traceIndex, currentSweep
	STRUCT TiledGraphSettings tgs

	graph = GetMainWindow(win)
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

	[tgs] = BSP_GatherTiledGraphSettings(graph)

	WAVE/Z sweepsToOverlay = OVS_GetSelectedSweeps(graph, OVS_SWEEP_SELECTION_INDEX)

	WAVE axesRanges = GetAxesRanges(graph)

	WAVE/T/Z cursorInfos = GetCursorInfos(graph)
	RemoveTracesFromGraph(graph)
	RemoveFreeAxisFromGraph(graph)
	TUD_Clear(graph)

	WAVE/T sweepMap = GetSweepBrowserMap(sweepBrowserDFR)

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

		WAVE sweepChannelSel = BSP_FetchSelectedChannels(graph, index=mapIndex)

		WAVE numericalValues = GetAnalysLBNumericalValues(dataFolder, device)
		DFREF sweepDFR       = GetAnalysisSweepPath(dataFolder, device)

		WAVE configWave = GetAnalysisConfigWave(dataFolder, device, sweepNo)
		WAVE textualValues = GetAnalysLBTextualValues(dataFolder, device)

		CreateTiledChannelGraph(graph, configWave, sweepNo, numericalValues, textualValues, tgs, sweepDFR, \
		                        axisLabelCache, traceIndex, experiment, sweepChannelSel)
		AR_UpdateTracesIfReq(graph, sweepDFR, sweepNo)
	endfor

	RestoreCursors(graph, cursorInfos)

	dataFolder = sweepMap[currentSweep][%DataFolder]
	device     = sweepMap[currentSweep][%Device]
	sweepNo    = str2num(sweepMap[currentSweep][%Sweep])
	DFREF sweepDATAdfr = GetAnalysisSweepDataPath(dataFolder, device, sweepNo)
	SVAR/Z sweepNote = sweepDATAdfr:note
	if(SVAR_EXISTS(sweepNote))
		ReplaceNotebookText(lbPanel, "Sweep note: \r " + sweepNote)
	endif

	PostPlotTransformations(graph)
	SetAxesRanges(graph, axesRanges)

	LayoutGraph(graph, tgs)
End

Function SB_AddToSweepBrowser(sweepBrowser, fileName, dataFolder, device, sweep)
	DFREF sweepBrowser
	string fileName, dataFolder, device
	variable sweep

	variable index
	string sweepStr = num2str(sweep)

	WAVE/T map = GetSweepBrowserMap(sweepBrowser)

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

Function SB_SweepBrowserWindowHook(s)
	STRUCT WMWinHookStruct &s

	string graph, scPanel, ctrl
	variable hookResult

	switch(s.eventCode)
		case 2:	 // Kill
			graph = GetMainWindow(s.winName)

			DFREF sweepBrowserDFR = SB_GetSweepBrowserFolder(graph)

			KillWindow $graph
			KillOrMoveToTrash(dfr = sweepBrowserDFR)

			hookResult = 1
			break
		case 22: // mouse wheel
			graph = GetMainWindow(s.winName)

			if(!windowExists(graph))
				break
			endif

			scPanel = BSP_GetSweepControlsPanel(graph)

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
	GetSweepBrowserMap(sweepBrowserDFR)

	renameWin = UniqueName(SWEEPBROWSER_WINDOW_TITLE, 9, 1)
	DoWindow/W=$mainWin/C $renameWin
	mainWin = renameWin

	string/G sweepBrowserDFR:graph = mainWin

	BSP_InitPanel(mainWin)
	BSP_ScaleAxes(mainWin)
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

/// @brief Returns a numeric wave with all sweep numbers
///
/// Can contain duplicates!
Function/WAVE SB_GetPlainSweepList(win)
	string win

	variable numRows

	WAVE/T map = SB_GetSweepBrowserMapFromGraph(win)
	numRows = GetNumberFromWaveNote(map, NOTE_INDEX)

	if(numRows == 0)
		return $""
	endif

	Make/FREE/R/N=(numRows) sweeps = str2num(map[p][%Sweep])

	return sweeps
End

/// @brief Return a wave with numerical value labnotebook waves
///
/// If `sweepNumber` is present the labnotebook wave is returned, otherwise a
/// wave reference wave is returned.
///
/// @param win         SweepBrowser data window
/// @param sweepNumber [optional, default: all] return the labnotebook only for a specific sweep
Function/WAVE SB_GetNumericalValuesWaves(win, [sweepNumber])
	string win
	variable sweepNumber

	variable numRows

	WAVE/T map = SB_GetSweepBrowserMapFromGraph(win)

	if(!ParamIsDefault(sweepNumber))
		WAVE/Z indices = FindIndizes(map, colLabel = "Sweep", var = sweepNumber)
		if(!WaveExists(indices))
			return $""
		endif

		return GetAnalysLBNumericalValues(map[indices[0]][%DataFolder], map[indices[0]][%Device])
	endif

	numRows = GetNumberFromWaveNote(map, NOTE_INDEX)
	Make/WAVE/FREE/N=(numRows) allNumericalValues = GetAnalysLBNumericalValues(map[p][%DataFolder], map[p][%Device])

	return allNumericalValues
End

/// @brief Return a wave with numerical value numerical waves
///
/// If `sweepNumber` is present the labnotebook wave is returned, otherwise a
/// wave reference wave is returned.
///
/// @param win         SweepBrowser data window
/// @param sweepNumber [optional, default: all] return the labnotebook only for a specific sweep
Function/WAVE SB_GetTextualValuesWaves(win, [sweepNumber])
	string win
	variable sweepNumber

	variable numRows

	WAVE/T map = SB_GetSweepBrowserMapFromGraph(win)

	if(!ParamIsDefault(sweepNumber))
		WAVE/Z indices = FindIndizes(map, colLabel = "Sweep", var = sweepNumber)
		if(!WaveExists(indices))
			return $""
		endif

		return GetAnalysLBNumericalValues(map[indices[0]][%DataFolder], map[indices[0]][%Device])
	endif

	numRows = GetNumberFromWaveNote(map, NOTE_INDEX)
	Make/WAVE/FREE/N=(numRows) allTextualValues = GetAnalysLBTextualValues(map[p][%DataFolder], map[p][%Device])

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

	string graph, scPanel
	variable firstSweep, lastSweep, index

	switch(ba.eventCode)
		case 2: // mouse up
			graph   = GetMainWindow(ba.win)
			scPanel = BSP_GetSweepControlsPanel(graph)

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

Function SB_ButtonProc_ExportTraces(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	string graph

	switch(ba.eventCode)
		case 2: // mouse up
			graph = GetMainWindow(ba.win)
			SBE_ShowExportPanel(graph)
			break
	endswitch

	return 0
End

Function SB_ButtonProc_FindMinis(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	variable numTraces, i, first, last
	string graph, list, trace

	switch(ba.eventCode)
		case 2: // mouse up
			graph = GetMainWindow(ba.win)

			WAVE/T/Z tracePaths = GetAllSweepTraces(graph)

			if(!WaveExists(tracePaths))
				break
			endif

			first = NumberByKey("POINT", CsrInfo(A, graph))
			last  = NumberByKey("POINT", CsrInfo(B, graph))
			[first, last] = MinMax(first, last)

			DFREF workDFR = UniqueDataFolder(SB_GetSweepBrowserFolder(graph), "findminis")

			numTraces = DimSize(tracePaths, ROWS)
			for(i = 0; i < numTraces; i += 1)
				WAVE full = $tracePaths[i]
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
