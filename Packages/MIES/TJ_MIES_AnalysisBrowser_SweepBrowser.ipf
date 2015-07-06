#pragma rtGlobals=3		// Use modern global access method and strict wave access.

static StrConstant AXES_SCALING_CHECKBOXES = "check_SB_visibleXRange;check_SB_equalYRanges;check_SB_equalYIgnLevelCross"
static StrConstant SWEEP_OVERLAY_DEP_CTRLS = "check_SweepBrowser_DisplayDAC;check_sweepbrowser_OverlayChan;check_SweepBrowser_DisplayTTL;check_SweepBrowser_DisplayADC;check_SweepBrowser_splitTTL"

static Function/S SB_GetSweepBrowserChanSelPanel(graphOrPanel)
	string graphOrPanel

	return GetMainWindow(graphOrPanel) + "#channelSel"
End

static Function/S SB_GetSweepBrowserLeftPanel(graphOrPanel)
	string graphOrPanel

	return GetMainWindow(graphOrPanel) + "#P0"
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

	ASSERT(windowExists(graph), "Window must exist")
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

static Function SB_PanelUpdate(graphOrPanel)
	string graphOrPanel

	variable alignMode
	string panel, graph

	graph = GetMainWindow(graphOrPanel)
	panel = SB_GetSweepBrowserLeftPanel(graph)

	if(GetCheckBoxState(panel, "check_SweepBrowser_TimeAlign"))
		EnableListOfControls(panel, "popup_sweepBrowser_tAlignMode;setvar_sweepBrowser_tAlignLevel;popup_sweepBrowser_tAlignMaster;button_SweepBrowser_DoTimeAlign")

		alignMode = GetPopupMenuIndex(panel, "popup_sweepBrowser_tAlignMode")
		if(alignMode == TIME_ALIGNMENT_LEVEL_RISING || alignMode == TIME_ALIGNMENT_LEVEL_FALLING)
			EnableControl(panel, "setvar_sweepBrowser_tAlignLevel")
		else
			DisableControl(panel, "setvar_sweepBrowser_tAlignLevel")
		endif
	else
		DisableListOfControls(panel, "popup_sweepBrowser_tAlignMode;setvar_sweepBrowser_tAlignLevel;popup_sweepBrowser_tAlignMaster;button_SweepBrowser_DoTimeAlign")
	endif

	SB_HandleCursorDisplay(graph)
	SB_ScaleAxes(graph)
	ControlUpdate/W=$panel popup_sweepBrowser_tAlignMaster
End

static Function SB_InitPostPlotSettings(graph, pps)
	string graph
	STRUCT PostPlotSettings &pps

	string	panel = SB_GetSweepBrowserLeftPanel(graph)

	pps.averageDataFolder = $SB_GetSweepBrowserFolder(graph)
	pps.averageTraces     = GetCheckboxState(panel, "check_SweepBrowser_AveragTraces")
	pps.zeroTraces        = GetCheckBoxState(panel, "check_SweepBrowser_ZeroTraces")
	pps.timeAlignMode     = GetPopupMenuIndex(panel, "popup_sweepBrowser_tAlignMode")
	pps.timeAlignLevel    = GetSetVariable(panel, "setvar_sweepBrowser_tAlignLevel")
	pps.timeAlignRefTrace = GetPopupMenuString(panel, "popup_sweepBrowser_tAlignMaster")

	FUNCREF FinalUpdateHookProto pps.finalUpdateHook = SB_PanelUpdate
End

static Function/WAVE SB_GetChannelSelWave(graph)
	string graph

	DFREF dfr = $SB_GetSweepBrowserFolder(graph)

	WAVE/Z/SDFR=dfr wv = channelSelection
	if(WaveExists(wv))
		return wv
	endif

	Make/N=(max(NUM_DA_TTL_CHANNELS, NUM_AD_CHANNELS), 2) dfr:channelSelection/Wave=wv

	SetDimLabel COLS, 0, DA, wv
	SetDimLabel COLS, 1, AD, wv

	// by default all channels are selected
	wv = 1

	return wv
End

static Function SB_ParseChannelSelCtrl(ctrl, channelType, channelNum)
	string ctrl
	string &channelType
	variable &channelNum

	sscanf ctrl, "check_SB_channelSel_%[^_]_%d", channelType, channelNum
	ASSERT(V_flag == 2, "Unexpected control name format")
End

static Function SB_ChannelSelWaveToGUI(graph)
	string graph

	string list, channelType, ctrl, panel
	variable channelNum, numEntries, i

	WAVE channelSel = SB_GetChannelSelWave(graph)
	panel = SB_GetSweepBrowserChanSelPanel(graph)
	list = ControlNameList(panel, ";", "check_SB_channelSel_*")
	numEntries = ItemsInList(list)
	for(i = 0; i < numEntries; i += 1)
		ctrl = StringFromList(i, list)
		SB_ParseChannelSelCtrl(ctrl, channelType, channelNum)
		SetCheckBoxState(panel, ctrl, channelSel[channelNum][%$channelType])
	endfor
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

	DFREF sweepBrowserDFR = $SB_GetSweepBrowserFolder(graph)
	WAVE/T sweepMap = SB_GetSweepBrowserMap(sweepBrowserDFR)

	if(!IsFinite(mapIndex) || mapIndex < 0 || mapIndex >= DimSize(sweepMap, ROWS))
		return $""
	endif

	device    = sweepMap[mapIndex][%Device]
	sweep     = str2num(sweepMap[mapIndex][%Sweep])
	expFolder = sweepMap[mapIndex][%ExperimentFolder]

	DFREF dfr = GetAnalysisLabNBFolder(expFolder, device)
	WAVE/SDFR=dfr numericValues

	return GetLastSetting(numericValues, sweep, key)
End

/// @brief Duplicate the sweep browser graph to a user given folder and name
///
/// Only duplicates the main graph without external subwindows
static Function SB_DuplicateSweepBrowser(graph)
	string graph

	string trace, folder, newPrefix, analysisPrefix, relativeDest
	string newGraphName, graphMacro, saveDFR, traceList
	variable numTraces, i, pos, numLines, useCursorRange, resetWaveZero
	variable beginX, endX, xcsrA, xcsrB, beginXPerWave, endXPerWave
	variable manualRangeBegin, manualRangeEnd, clipXRange

	folder           = "myFolder"
	newGraphName     = "myGraph"
	useCursorRange   = 0
	resetWaveZero    = 0
	manualRangeBegin = NaN
	manualRangeEnd   = NaN

	Prompt folder,           "Datafolder: "
	Prompt newGraphName,     "Graph name: "
	Prompt useCursorRange,   "Duplicate only the cursor range: "
	Prompt manualRangeBegin, "Manual X range begin: "
	Prompt manualRangeEnd,   "Manual X range end: "
	Prompt resetWaveZero,    "Reset the wave's dim offset to zero: "

	DoPrompt/HELP="No help available" "Please provide some information for the duplicated graph", folder, newGraphName, useCursorRange, manualRangeBegin, manualRangeEnd, resetWaveZero
	if(V_flag)
		return NaN
	endif

	DFREF sweepBrowserDFR = $SB_GetSweepBrowserFolder(graph)
	newPrefix      = GetDataFolder(1, UniqueDataFolder($"root:", folder))
	newPrefix      = RemoveEnding(newPrefix, ":")
	analysisPrefix = GetAnalysisFolderAS()

	if(useCursorRange)
		xcsrA  = xcsr(A, graph)
		xcsrB  = xcsr(B, graph)
		beginX = min(xcsrA, xcsrB)
		endX   = max(xcsrA, xcsrB)
		clipXRange = 1
	elseif(isFinite(manualRangeBegin) && IsFinite(manualRangeEnd))
		beginX = manualRangeBegin
		endX   = manualRangeEnd
		clipXRange = 1
	endif

	traceList = TraceNameList(graph, ";", 0 + 1)
	numTraces = ItemsInList(traceList)
	for(i = 0; i < numTraces; i += 1)
		trace = StringFromList(i, traceList)
		WAVE wv = TraceNameToWaveRef(graph, trace)

		// the waves can be in two locations, either in root:$sweepBrowser
		// or done below in root:MIES:analysis:$Experiment:$Device:sweep:$X
		DFREF loc = GetWavesDataFolderDFR(wv)
		if(DataFolderRefsEqual(loc, sweepBrowserDFR))
			DFREF dfr = createDFWithAllParents(newPrefix)
		else
			relativeDest = RemovePrefix(GetDataFolder(1, loc), startStr=analysisPrefix)
			DFREF dfr = createDFWithAllParents(newPrefix + relativeDest)
		endif

		if(clipXRange)
			beginXPerWave = max(leftx(wv), beginX)
			endXPerWave   = min(rightx(wv), endX)
		else
			beginXPerWave = leftx(wv)
			endXPerWave   = rightx(wv)
		endif

		Duplicate/R=(beginXPerWave, endXPerWave) wv, dfr:$NameOfWave(wv)/WAVE=dup
		WaveClear wv
		if(clipXRange)
			AddEntryIntoWaveNoteAsList(dup, "CursorA", var=beginX)
			AddEntryIntoWaveNoteAsList(dup, "CursorB", var=endX)
		endif
		if(resetWaveZero)
			AddEntryIntoWaveNoteAsList(dup, "OldDimOffset", var=DimOffset(dup, ROWS))
			SetScale/P x, 0, DimDelta(dup, ROWS), WaveUnits(dup, ROWS), dup
		endif
	endfor

	graphMacro = WinRecreation(graph, 0)

	// everything we don't need anymore starts in the line with SetWindow
	// ranging to the macro's end
	pos = strsearch(graphMacro, "SetWindow kwTopWin" , 0)
	if(pos != -1)
		graphMacro = graphMacro[0, pos - 2]
	endif
	// remove setting the CDF, we do that ourselves later on
	graphMacro = ListMatch(graphMacro, "!*SetDataFolder fldrSav*", "\r")

	// remove setting the bottom axis range, as this might be wrong
	graphMacro = ListMatch(graphMacro, "!*SetAxis bottom*", "\r")

	// replace the old data location with the new one
	graphMacro = ReplaceString(analysisPrefix, graphMacro, newPrefix)

	// replace relative reference to sweepBrowserDFR
	// with absolut ones to newPrefix
	folder = GetDataFolder(1, sweepBrowserDFR)
	folder = RemovePrefix(folder, startStr="root:")
	folder = ":::::::" + folder
	graphMacro = ReplaceString(folder, graphMacro, newPrefix + ":")

	saveDFR = GetDataFolder(1)
	// The first three lines are:
	// Window SweepBrowser1() : Graph
	//		PauseUpdate; Silent 1		// building window...
	// 		String fldrSav0= GetDataFolder(1)
	numLines = ItemsInList(graphMacro, "\r")
	for(i = 3; i < numLines; i += 1)
		string line = StringFromList(i, graphMacro, "\r")
		Execute/Q line
	endfor

	// rename the graph
	newGraphName = CleanUpName(newGraphName, 0)
	if(windowExists(newGraphName))
		newGraphName = UniqueName(newGraphName, 6, 0)
	endif
	SVAR S_name
	RenameWindow $S_name, $newGraphName

	Execute/P/Q "KillStrings/Z S_name"
	Execute/P/Q "SetDataFolder " + saveDFR
End

/// @brief Return a list of experiments from which the sweeps in the sweep browser
/// graph originated from
///
/// @param graph sweep browser name
Function/S SB_GetListOfExperiments(graph)
	string graph

	DFREF sweepBrowserDFR = $SB_GetSweepBrowserFolder(graph)
	WAVE/T sweepMap = SB_GetSweepBrowserMap(sweepBrowserDFR)

	variable numEntries, i
	string experiment
	string list = ""

	numEntries = GetNumberFromWaveNote(sweepMap, NOTE_INDEX)
	for(i = 0; i < numEntries; i += 1)
		experiment = sweepMap[i][%ExperimentName]
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
/// Example usage:
/// @code
/// variable channelNumber, headstage, numWaves, i
/// string graph   = "SweepBrowser1" // name of an existing sweep browser graph
/// string channel = "DA"
/// WAVE/T wv =  SB_GetChannelInfoFromGraph(graph, channel)
///
/// numWaves = DimSize(wv, ROWS)
/// for(i = 0; i < numWaves; i += 1)
/// 	WAVE data     = $(wv[i][%path])
/// 	channelNumber = str2num(wv[i][%channel])
/// 	headstage     = str2num(wv[i][%headstage])
///
/// 	printf "Channel %d acquired by headstage %d is stored in %s\r", channelNumber, headstage, NameOfWave(data)
/// endfor
/// @endcode
///
/// @param graph                                  sweep browser name
/// @param channel                                type of the channel, one of #ITC_CHANNEL_NAMES
/// @param experiment [optional, defaults to all] name of the experiment the channel wave should originate from
Function/WAVE SB_GetChannelInfoFromGraph(graph, channel, [experiment])
	string graph, channel, experiment

	variable i, j, numEntries, idx, numWaves, channelNumber
	string list, headstage, path

	ASSERT(FindListitem(channel, ITC_CHANNEL_NAMES) != -1, "Given channel could not be found in ITC_CHANNEL_NAMES")

	DFREF sweepBrowserDFR = $SB_GetSweepBrowserFolder(graph)
	WAVE/T sweepMap = SB_GetSweepBrowserMap(sweepBrowserDFR)

	Make/FREE/T/N=(MINIMUM_WAVE_SIZE, 3) channelMap

	SetDimLabel COLS, 0, channel,   channelMap
	SetDimLabel COLS, 1, path,      channelMap
	SetDimLabel COLS, 2, headstage, channelMap

	if(ParamIsDefault(experiment))
		numEntries = GetNumberFromWaveNote(sweepMap, NOTE_INDEX)
		Make/FREE/N=(numEntries) indizes = p
	else
		WAVE/Z indizes = FindIndizes(wvText=sweepMap, colLabel="ExperimentName", str=experiment)
		ASSERT(WaveExists(indizes), "The experiment could not be found in the sweep browser")
		numEntries = DimSize(indizes, ROWS)
	endif

	for(i = 0; i < numEntries; i += 1)
		DFREF dfr = SB_GetSweepDataPathFromIndex(sweepBrowserDFR, indizes[i])

		list = GetListOfWaves(dfr, channel + "_.*", fullpath=1)
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

/// @param sweepBrowserDFR datatfolder of the sweep browser
/// @param currentMapIndex index into the sweep browser map of the currently shown sweep
/// @param newMapIndex index into the sweep browser map of the new to-be-shown sweep
Function SB_PlotSweep(sweepBrowserDFR, currentMapIndex, newMapIndex)
	DFREF sweepBrowserDFR
	variable currentMapIndex, newMapIndex

	string device, expFolder, panel
	variable sweep, newWaveDisplayed, currentWaveDisplayed
	variable displayDAC, overlaySweep, overlayChannels

	ASSERT(DataFolderExistsDFR(sweepBrowserDFR), "sweepBrowserDFR must exist")

	SVAR/SDFR=sweepBrowserDFR graph
	panel = SB_GetSweepBrowserLeftPanel(graph)

	DFREF newSweepDFR = SB_GetSweepDataPathFromIndex(sweepBrowserDFR, newMapIndex)
	if(!DataFolderExistsDFR(newSweepDFR))
		return 0
	endif

	STRUCT PostPlotSettings pps
	SB_InitPostPlotSettings(graph, pps)

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
			PostPlotTransformations(graph, pps)
			return NaN
		elseif(newWaveDisplayed)
			PostPlotTransformations(graph, pps)
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
	WAVE/T/SDFR=dfr textValues

	STRUCT TiledGraphSettings tgs
	tgs.displayDAC      = GetCheckBoxState(panel, "check_SweepBrowser_DisplayDAC")
	tgs.overlaySweep    = GetCheckBoxState(panel, "check_SweepBrowser_SweepOverlay")
	tgs.displayADC      = GetCheckBoxState(panel, "check_SweepBrowser_DisplayADC")
	tgs.displayTTL      = GetCheckBoxState(panel, "check_SweepBrowser_DisplayTTL")
	tgs.overlayChannels = GetCheckBoxState(panel, "check_sweepbrowser_OverlayChan")
	tgs.splitTTLBits    = GetCheckBoxState(panel, "check_SweepBrowser_SplitTTL")
	WAVE channelSelWave = SB_GetChannelSelWave(graph)

	CreateTiledChannelGraph(graph, configWave, sweep, numericValues, textValues, tgs, sweepDFR=newSweepDFR, channelSelWave=channelSelWave)

	SetPopupMenuIndex(panel, "popup_sweep_selector", newMapIndex)
	SB_SetFormerSweepNumber(panel, newMapIndex)
	PostPlotTransformations(graph, pps)
End

Function SB_AddToSweepBrowser(sweepBrowser, expName, expFolder, device, sweep)
	DFREF sweepBrowser
	string expName, expFolder, device
	variable sweep

	variable index
	string sweepStr = num2str(sweep)

	WAVE/T map = SB_GetSweepBrowserMap(sweepBrowser)

	index = GetNumberFromWaveNote(map, NOTE_INDEX)
	EnsureLargeEnoughWave(map, minimumSize=index)

	Duplicate/FREE/R=[0][]/T map, singleRow

	singleRow = ""
	singleRow[0][%ExperimentName]   = expName
	singleRow[0][%ExperimentFolder] = expFolder
	singleRow[0][%Device]           = device
	singleRow[0][%Sweep]            = sweepStr

	if(IsFinite(GetRowWithSameContent(map, singleRow, 0)))
		// we already have that sweep in the map
		return NaN
	endif

	map[index][%ExperimentName]   = expName
	map[index][%ExperimentFolder] = expFolder
	map[index][%Device]           = device
	map[index][%Sweep]            = sweepStr

	SetNumberInWaveNote(map, NOTE_INDEX, index + 1)
End

static Function SB_HandleTimeAlignPropChange(graphOrPanel)
	string graphOrPanel

	string panel, graph
	graph = GetMainWindow(graphOrPanel)
	panel = SB_GetSweepBrowserLeftPanel(graph)

	STRUCT PostPlotSettings pps
	SB_InitPostPlotSettings(graph, pps)
	pps.timeAlignment = GetCheckBoxState(panel, "check_SweepBrowser_TimeAlign")
	PostPlotTransformations(graph, pps)
End

static Function SB_ScaleAxes(graphOrPanel)
	string graphOrPanel

	string panel, graph
	variable visXRange, equalY, equalYIgn, level

	panel      = SB_GetSweepBrowserLeftPanel(graphOrPanel)
	graph      = GetMainWindow(panel)
	visXRange  = GetCheckBoxState(panel, "check_SB_visibleXRange")
	equalY     = GetCheckBoxState(panel, "check_SB_equalYRanges")
	equalYIgn  = GetCheckBoxState(panel, "check_SB_equalYIgnLevelCross")

	ASSERT(visXRange + equalY + equalYIgn <= 1, "Only one scaling mode is allowed to be selected")

	if(visXRange)
		AutoscaleVertAxisVisXRange(graph)
	elseif(equalY)
		EqualizeVerticalAxesRanges(graph, ignoreAxesWithLevelCrossing=0)
	elseif(equalYIgn)
		level = GetSetVariable(panel, "setvar_SB_equalYLevel")
		EqualizeVerticalAxesRanges(graph, ignoreAxesWithLevelCrossing=1, level=level)
	else
		// do nothing
	endif
End

Function SB_SweepBrowserWindowHook(s)
	STRUCT WMWinHookStruct &s

	variable hookResult, direction, currentSweep, newSweep
	string folder, graph, panel

	switch(s.eventCode)
		case 2:	 // Kill
			graph = s.winName

			folder = SB_GetSweepBrowserFolder(graph)

			KillWindow $graph
			KillOrMoveToTrash(folder)

			hookResult = 1
			break
		case 22: // mouse wheel
			graph = s.winName

			if(!windowExists(graph))
				break
			endif

			direction =  sign(s.wheelDy)
			folder = SB_GetSweepBrowserFolder(graph)

			panel = SB_GetSweepBrowserLeftPanel(graph)
			currentSweep = GetPopupMenuIndex(panel, "popup_sweep_selector")
			newSweep = currentSweep + direction * GetSetVariable(panel, "setvar_SweepBrowser_SweepStep")

			SB_PlotSweep($folder, currentSweep, newSweep)

			hookResult = 1
			break
	endswitch

	return hookResult // 0 if nothing done, else 1
End

Function/DF SB_CreateNewSweepBrowser()

	string panel
	DFREF dfr = $"root:"
	DFREF sweepBrowserDFR = UniqueDataFolder(dfr, "sweepBrowser")

	SB_GetSweepBrowserMap(sweepBrowserDFR)

	Display /W=(169.5,269,603,574.25)/K=1/N=$UniqueName("SweepBrowser", 9, 1)
	string/G sweepBrowserDFR:graph = S_name
	SVAR/SDFR=sweepBrowserDFR graph

	SetWindow $graph, hook(cleanup)=SB_SweepBrowserWindowHook, userdata(folder)=GetDataFolder(1, sweepBrowserDFR)

	NewPanel/HOST=#/EXT=1/W=(156,0,0,407)
	ModifyPanel fixedSize=0
	CheckBox check_SweepBrowser_DisplayDAC,pos={17,7},size={33,14},proc=SB_CheckboxChangedSettings,title="DA"
	CheckBox check_SweepBrowser_DisplayDAC,value= 0,help={"Display the DA channel data"}
	CheckBox check_SweepBrowser_DisplayADC,pos={61,7},size={33,14},proc=SB_CheckboxChangedSettings,title="AD"
	CheckBox check_SweepBrowser_DisplayADC,value= 1, help={"Display the AD channels"}
	CheckBox check_SweepBrowser_DisplayTTL,pos={102,7},size={38,14},proc=SB_CheckboxChangedSettings,title="TTL"
	CheckBox check_SweepBrowser_DisplayTTL,value= 0, help={"Display the TTL channels"}
	CheckBox check_SweepBrowser_splitTTL,pos={142,6},size={16,14},proc=SB_CheckboxChangedSettings,title=""
	CheckBox check_SweepBrowser_splitTTL,help={"Display the TTL channel data as single traces for each TTL bit"}
	CheckBox check_SweepBrowser_splitTTL,value= 0
	CheckBox check_SweepBrowser_AveragTraces,pos={17,265},size={94,14},proc=SB_CheckboxChangedSettings,title="Average Traces"
	CheckBox check_SweepBrowser_AveragTraces,help={"Average all traces which belong to the same y axis"}
	CheckBox check_SweepBrowser_AveragTraces,value= 0
	CheckBox check_SweepBrowser_ZeroTraces,pos={17,285},size={76,14},proc=SB_CheckboxChangedSettings,title="Zero Traces"
	CheckBox check_SweepBrowser_ZeroTraces,help={"Remove the offset of all traces"}
	CheckBox check_SweepBrowser_ZeroTraces,value= 0
	SetVariable setvar_SweepBrowser_SweepStep,pos={46,141},size={64,16},title="Step"
	SetVariable setvar_SweepBrowser_SweepStep,limits={1,inf,1},value= _NUM:1
	SetVariable setvar_SweepBrowser_SweepStep,help={"Number of sweeps to step for each Previous/Next click or mouse wheel turn"}
	CheckBox check_sweepbrowser_OverlayChan,pos={17,50},size={101,14},proc=SB_CheckboxChangedSettings,title="Overlay Channels"
	CheckBox check_sweepbrowser_OverlayChan,value= 1,help={"Overlay the data from multiple channels in one graph"}
	CheckBox check_SweepBrowser_SweepOverlay,pos={17,30},size={95,14},proc=SB_CheckboxChangedSettings,title="Overlay Sweeps"
	CheckBox check_SweepBrowser_SweepOverlay,value= 0,help={"Add the data from all visited sweeps instead of clearing the graph every time"}
	GroupBox group_sweep,pos={6,71},size={139,98},title="Sweep"
	Button button_SweepBrowser_NextSweep,pos={81,117},size={60,20},proc=SB_ButtonProc_ChangeSweep,title="Next"
	Button button_SweepBrowser_NextSweep,help={"Select the previous sweep"}
	Button button_SweepBrowser_PrevSweep,pos={11,117},size={60,20},proc=SB_ButtonProc_ChangeSweep,title="Previous"
	Button button_SweepBrowser_PrevSweep,help={"Select the next sweep"}
	CheckBox check_SweepBrowser_TimeAlign,pos={17,176},size={90,14},proc=SB_TimeAlignmentProc,title="Time Alignment"
	CheckBox check_SweepBrowser_TimeAlign,value= 0
	CheckBox check_SweepBrowser_TimeAlign,help={"Activate time alignment"}
	PopupMenu popup_sweepBrowser_tAlignMode,pos={13,195},size={129,21},bodyWidth=50,disable=2,proc=SB_TimeAlignmentPopup,title="Alignment Mode"
	PopupMenu popup_sweepBrowser_tAlignMode,mode=1,popvalue="Level (Raising)",value= #"\"Level (Raising);Level (Falling);Min;Max\""
	PopupMenu popup_sweepBrowser_tAlignMode,help={"Select the alignment mode"}
	SetVariable setvar_sweepBrowser_tAlignLevel,pos={61,219},size={80,16},disable=2,proc=SB_TimeAlignmentLevel,title="Level"
	SetVariable setvar_sweepBrowser_tAlignLevel,limits={-inf,inf,0},value= _NUM:0
	SetVariable setvar_sweepBrowser_tAlignLevel,help={"Select the level (for rising and falling alignment mode) at which traces are aligned"}
	PopupMenu popup_sweepBrowser_tAlignMaster,pos={11,239},size={130,21},bodyWidth=50,disable=2,proc=SB_TimeAlignmentPopup,title="Reference trace"
	PopupMenu popup_sweepBrowser_tAlignMaster,mode=1,popvalue="",value= #("SB_GetAllTraces(\"" + graph + "\")")
	PopupMenu popup_sweepBrowser_tAlignMaster,help={"Select the reference trace to which all other traces should be aligned to"}
	Button button_SweepBrowser_DoTimeAlign,pos={113,174},size={30,20},disable=2,proc=SB_DoTimeAlignment,title="Do!"
	Button button_SweepBrowser_DoTimeAlign,help={"Perform the time alignment, needs the cursors A and B to have a selected feature"}
	PopupMenu popup_sweep_selector,pos={13,91},size={127,21},bodyWidth=127,proc=SB_PopupMenuSelectSweep
	PopupMenu popup_sweep_selector,mode=12,popvalue="",value= #("SB_GetSweepList(\"" + graph + "\")")
	PopupMenu popup_sweep_selector,help={"List of sweeps in this sweep browser"}
	Button button_SweepBrowser_OpenChanSel,pos={118,29},size={33,17},proc=SB_OpenChannelSelectionPanel,title="Chan"
	Button button_SweepBrowser_OpenChanSel,help={"Open the channel selection dialog, allows to disable single channels"}
	GroupBox group_SB_axes_scaling,pos={11,310},size={133,60},title="Axes Scaling"
	CheckBox check_SB_visibleXRange,pos={19,329},size={42,14},proc=SB_AxisScaling,title="Vis X"
	CheckBox check_SB_visibleXRange,help={"Scale the y axis to the visible x data range"}
	CheckBox check_SB_visibleXRange,value= 0
	CheckBox check_SB_equalYRanges,pos={69,329},size={55,14},proc=SB_AxisScaling,title="Equal Y"
	CheckBox check_SB_equalYRanges,help={"Equalize the vertical axes ranges"},value= 0
	CheckBox check_SB_equalYIgnLevelCross,pos={19,348},size={75,14},proc=SB_AxisScaling,title="Equal Y ign."
	CheckBox check_SB_equalYIgnLevelCross,help={"Equalize the vertical axes ranges but ignore all traces with level crossings"}
	CheckBox check_SB_equalYIgnLevelCross,value= 0
	SetVariable setvar_SB_equalYLevel,pos={98,348},size={25,16},proc=SB_AxisScalingLevelCross
	SetVariable setvar_SB_equalYLevel,help={"Crossing level value for 'Equal Y ign.\""}
	SetVariable setvar_SB_equalYLevel,limits={-inf,inf,0},value= _NUM:0,disable=2
	Button button_SweepBrowser_DupGraph,pos={32,376},size={88,25},proc=SB_ButtonProc_DupGraph,title="Duplicate Graph"
	Button button_SweepBrowser_DupGraph,help={"Duplicate the graph and its trace for further processing"}
	SetActiveSubwindow ##
	NewPanel/HOST=#/EXT=0/W=(0,0,214,407)  as "Analysis Results"
	ModifyPanel fixedSize=0
	NewNotebook /F=0 /N=NB0 /W=(16,29,196,362) /HOST=#
	Notebook kwTopWin, defaultTab=20, statusWidth=0, autoSave=1
	Notebook kwTopWin font="Arial", fSize=10, fStyle=0, textRGB=(0,0,0)
	Notebook kwTopWin, zdata= "GaqDU%ejN7!Z)%D?io>lbN?PWL]d_/WWX="
	Notebook kwTopWin, zdataEnd= 1
	SetActiveSubwindow ##

	SB_PanelUpdate(graph)
	WMZoomBrowser#AddZoomBrowserPanel()

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

Function/S SB_GetAllTraces(graph)
	string graph

	return TraceNameList(graph, ";", 1 + 2)
End

Function SB_CheckboxChangedSettings(cba) : CheckBoxControl
	STRUCT WMCheckBoxAction &cba

	string graph, win, ctrl, channelType
	variable idx, checked, channelNum
	DFREF sweepDFR

	switch(cba.eventCode)
		case 2: // mouse up
			ctrl    = cba.ctrlName
			checked = cba.checked
			win     = SB_GetSweepBrowserLeftPanel(cba.win)
			graph   = GetMainWindow(win)

			if(!cmpstr(ctrl, "check_SweepBrowser_SweepOverlay"))
				if(checked)
					DisableListOfControls(win, SWEEP_OVERLAY_DEP_CTRLS)
				else
					EnableListOfControls(win, SWEEP_OVERLAY_DEP_CTRLS)
				endif
			elseif(StringMatch(ctrl, "check_SB_channelSel_*"))
				WAVE channelSel = SB_GetChannelSelWave(graph)
				SB_ParseChannelSelCtrl(cba.ctrlName, channelType, channelNum)
				channelSel[channelNum][%$channelType] = checked
			endif

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
			graph     = GetMainWindow(pa.win)
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
			graph = GetMainWindow(win)
			ctrl  = ba.ctrlName

			currentSweep = GetPopupMenuIndex(win, "popup_sweep_selector")

			if(!cmpstr(ctrl, "button_SweepBrowser_PrevSweep"))
				direction = -1
			elseif(!cmpstr(ctrl, "button_SweepBrowser_NextSweep"))
				direction = +1
			else
				ASSERT(0, "unhandled control name")
			endif

			newSweep = currentSweep + direction * GetSetVariable(win, "setvar_SweepBrowser_SweepStep")
			DFREF dfr = $SB_GetSweepBrowserFolder(graph)
			SB_PlotSweep(dfr, currentSweep, newSweep)
			break
	endswitch

	return 0
End

/// @brief Adds or removes the cursors from the graphs depending on the
///        panel settings
static Function SB_HandleCursorDisplay(graph)
	string graph

	string traceList, trace, csrA, csrB, panel
	variable length

	traceList = GetAllSweepTraces(graph)
	if(isEmpty(traceList))
		return NaN
	endif

	panel = SB_GetSweepBrowserLeftPanel(graph)

	if(GetCheckBoxState(panel, "check_SweepBrowser_TimeAlign"))

		// ensure that trace is really on the graph
		trace = GetPopupMenuString(panel, "popup_sweepBrowser_tAlignMaster")
		if(FindListItem(trace, traceList) == -1)
			trace = StringFromList(0, traceList)
		endif

		length = DimSize(TraceNameToWaveRef(graph, trace), ROWS)

		csrA = CsrInfo(A, graph)
		if(IsEmpty(csrA))
			Cursor/W=$graph/A=1/N=1/P A $trace length / 3
		endif

		csrB = CsrInfo(B, graph)
		if(isEmpty(csrB))
			Cursor/W=$graph/A=1/N=1/P B $trace length * 2 / 3
		endif
	else
		Cursor/K/W=$graph A
		Cursor/K/W=$graph B
	endif
End

Function SB_TimeAlignmentProc(cba) : CheckBoxControl
	STRUCT WMCheckBoxAction &cba

	switch(cba.eventCode)
		case 2: // mouse up
			if(cba.checked)
				SB_PanelUpdate(cba.win)
			else
				SB_HandleTimeAlignPropChange(cba.win)
			endif
			break
	endswitch
End

Function SB_TimeAlignmentPopup(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	switch(pa.eventCode)
		case 2: // mouse up
			SB_PanelUpdate(pa.win)
			break
	endswitch

	return 0
End

Function SB_TimeAlignmentLevel(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	switch(sva.eventCode)
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			SB_PanelUpdate(sva.win)
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

Function SB_AxisScaling(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	string ctrls, panel
	variable numCtrls, i
	switch( cba.eventCode )
		case 2: // mouse up
			panel = cba.win
			if(cba.checked)
				ctrls = ListMatch(AXES_SCALING_CHECKBOXES, "!" + cba.ctrlName)
				numCtrls = ItemsInList(ctrls)
				for(i = 0; i < numCtrls; i += 1)
					SetCheckBoxState(panel, StringFromList(i, ctrls), CHECKBOX_UNSELECTED)
				endfor
			endif

			if(GetCheckBoxState(panel, "check_SB_equalYIgnLevelCross"))
				EnableControl(panel, "setvar_SB_equalYLevel")
			else
				DisableControl(panel, "setvar_SB_equalYLevel")
			endif

			SB_ScaleAxes(cba.win)
			break
	endswitch

	return 0
End

Function SB_AxisScalingLevelCross(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	switch(sva.eventCode)
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			if(GetCheckBoxState(sva.win, "check_SB_equalYIgnLevelCross"))
				SB_ScaleAxes(sva.win)
			endif
			break
	endswitch

	return 0
End

Function SB_OpenChannelSelectionPanel(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	string graph
	switch(ba.eventCode)
		case 2: // mouse up
			graph = GetMainWindow(ba.win)
			if(windowExists(SB_GetSweepBrowserChanSelPanel(graph)))
				break
			endif
			NewPanel/HOST=$graph/EXT=1/W=(107,0,0,383)/N=channelSel as " "
			// DAC
			GroupBox group_SB_channelSel_DA,pos={56,5},size={44,199},title="DA"
			CheckBox check_SB_channelSel_DA_0,pos={66,21},size={24,14},title="0",value= 0, proc=SB_CheckboxChangedSettings
			CheckBox check_SB_channelSel_DA_1,pos={66,42},size={24,14},title="1",value= 0, proc=SB_CheckboxChangedSettings
			CheckBox check_SB_channelSel_DA_2,pos={66,63},size={24,14},title="2",value= 0, proc=SB_CheckboxChangedSettings
			CheckBox check_SB_channelSel_DA_3,pos={66,84},size={24,14},title="3",value= 0, proc=SB_CheckboxChangedSettings
			CheckBox check_SB_channelSel_DA_4,pos={66,105},size={24,14},title="4",value= 0, proc=SB_CheckboxChangedSettings
			CheckBox check_SB_channelSel_DA_5,pos={66,126},size={24,14},title="5",value= 0, proc=SB_CheckboxChangedSettings
			CheckBox check_SB_channelSel_DA_6,pos={66,147},size={24,14},title="6",value= 0, proc=SB_CheckboxChangedSettings
			CheckBox check_SB_channelSel_DA_7,pos={66,168},size={24,14},title="7",value= 0, proc=SB_CheckboxChangedSettings
			// ADC
			GroupBox group_SB_channelSel_AD,pos={5,5},size={45,360},title="AD"
			CheckBox check_SB_channelSel_AD_0,pos={13,21},size={24,14},title="0",value= 0, proc=SB_CheckboxChangedSettings
			CheckBox check_SB_channelSel_AD_1,pos={13,42},size={24,14},title="1",value= 0, proc=SB_CheckboxChangedSettings
			CheckBox check_SB_channelSel_AD_2,pos={13,63},size={24,14},title="2",value= 0, proc=SB_CheckboxChangedSettings
			CheckBox check_SB_channelSel_AD_3,pos={13,84},size={24,14},title="3",value= 0, proc=SB_CheckboxChangedSettings
			CheckBox check_SB_channelSel_AD_4,pos={13,105},size={24,14},title="4",value= 0, proc=SB_CheckboxChangedSettings
			CheckBox check_SB_channelSel_AD_5,pos={13,126},size={24,14},title="5",value= 0, proc=SB_CheckboxChangedSettings
			CheckBox check_SB_channelSel_AD_6,pos={13,147},size={24,14},title="6",value= 0, proc=SB_CheckboxChangedSettings
			CheckBox check_SB_channelSel_AD_7,pos={13,168},size={24,14},title="7",value= 0, proc=SB_CheckboxChangedSettings
			CheckBox check_SB_channelSel_AD_8,pos={13,190},size={24,14},title="8",value= 0, proc=SB_CheckboxChangedSettings
			CheckBox check_SB_channelSel_AD_9,pos={13,211},size={24,14},title="9",value= 0, proc=SB_CheckboxChangedSettings
			CheckBox check_SB_channelSel_AD_10,pos={13,232},size={30,14},title="10",value= 0, proc=SB_CheckboxChangedSettings
			CheckBox check_SB_channelSel_AD_11,pos={13,253},size={30,14},title="11",value= 0, proc=SB_CheckboxChangedSettings
			CheckBox check_SB_channelSel_AD_12,pos={13,274},size={30,14},title="12",value= 0, proc=SB_CheckboxChangedSettings
			CheckBox check_SB_channelSel_AD_13,pos={13,295},size={30,14},title="13",value= 0, proc=SB_CheckboxChangedSettings
			CheckBox check_SB_channelSel_AD_14,pos={13,316},size={30,14},title="14",value= 0, proc=SB_CheckboxChangedSettings
			CheckBox check_SB_channelSel_AD_15,pos={13,338},size={30,14},title="15",value= 0, proc=SB_CheckboxChangedSettings
			SB_ChannelSelWaveToGUI(graph)
			break
	endswitch

	return 0
End

Function SB_ButtonProc_DupGraph(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch(ba.eventCode)
		case 2: // mouse up
			SB_DuplicateSweepBrowser(GetMainWindow(ba.win))
			break
	endswitch

	return 0
End
