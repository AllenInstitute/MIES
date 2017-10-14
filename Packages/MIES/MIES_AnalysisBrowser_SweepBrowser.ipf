#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_SB
#endif

/// @file MIES_AnalysisBrowser_SweepBrowser.ipf
/// @brief __SB__  Visualization of sweep data in the analysis browser

static StrConstant AXES_SCALING_CHECKBOXES = "check_SB_visibleXRange;check_SB_equalYRanges;check_SB_equalYIgnLevelCross"
static StrConstant WAVE_NOTE_LAYOUT_KEY    = "WAVE_LAYOUT_VERSION"

Function/S SB_GetSweepBrowserLeftPanel(graphOrPanel)
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

Function/S SB_GetSweepBrowserFolder(graph)
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
	expFolder = sweepMap[mapIndex][%DataFolder]

	if(!IsFinite(sweep))
		return $""
	endif

	return $GetAnalysisSweepDataPathAS(expFolder, device, sweep)
End

Function SB_GetIndexFromSweepDataPath(graph, dataDFR)
	string graph
	DFREF dataDFR

	variable mapIndex, sweepNo
	string device, expFolder, sweepFolder

	DFREF sweepBrowserDFR = $SB_GetSweepBrowserFolder(graph)
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

static Function SB_PanelUpdate(graphOrPanel)
	string graphOrPanel

	variable alignMode
	string panel, graph

	graph = GetMainWindow(graphOrPanel)
	panel = SB_GetSweepBrowserLeftPanel(graph)

	if(GetCheckBoxState(panel, "check_SweepBrowser_TimeAlign"))
		EnableControls(panel, "popup_sweepBrowser_tAlignMode;setvar_sweepBrowser_tAlignLevel;popup_sweepBrowser_tAlignMaster;button_SweepBrowser_DoTimeAlign")

		alignMode = GetPopupMenuIndex(panel, "popup_sweepBrowser_tAlignMode")
		if(alignMode == TIME_ALIGNMENT_LEVEL_RISING || alignMode == TIME_ALIGNMENT_LEVEL_FALLING)
			EnableControl(panel, "setvar_sweepBrowser_tAlignLevel")
		else
			DisableControl(panel, "setvar_sweepBrowser_tAlignLevel")
		endif
	else
		DisableControls(panel, "popup_sweepBrowser_tAlignMode;setvar_sweepBrowser_tAlignLevel;popup_sweepBrowser_tAlignMaster;button_SweepBrowser_DoTimeAlign")
	endif

	SB_HandleCursorDisplay(graph)
	SB_ScaleAxes(graph)
	ControlUpdate/W=$panel popup_sweepBrowser_tAlignMaster
End

static Function SB_InitPostPlotSettings(graph, pps)
	string graph
	STRUCT PostPlotSettings &pps

	string panel    = SB_GetSweepBrowserLeftPanel(graph)

	pps.averageDataFolder = $SB_GetSweepBrowserFolder(graph)
	pps.averageTraces     = GetCheckboxState(panel, "check_SweepBrowser_AveragTraces")
	pps.zeroTraces        = GetCheckBoxState(panel, "check_SweepBrowser_ZeroTraces")
	pps.timeAlignMode     = GetPopupMenuIndex(panel, "popup_sweepBrowser_tAlignMode")
	pps.timeAlignLevel    = GetSetVariable(panel, "setvar_sweepBrowser_tAlignLevel")
	pps.timeAlignRefTrace = GetPopupMenuString(panel, "popup_sweepBrowser_tAlignMaster")
	pps.hideSweep         = GetCheckBoxState(panel, "check_SweepBrowser_HideSweep")

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

	DFREF sweepBrowserDFR = $SB_GetSweepBrowserFolder(graph)
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

	DFREF sweepBrowserDFR = $SB_GetSweepBrowserFolder(graph)
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

Function SB_UpdateSweepPlot(graph, [newSweep])
	string graph
	variable newSweep

	string device, dataFolder, extPanel
	variable mapIndex, i, numEntries, sweepNo, highlightSweep, traceIndex

	graph = GetMainWindow(graph)
	if(!HasPanelLatestVersion(graph, SWEEPBROWSER_PANEL_VERSION))
		Abort "Can not display data. The SweepBrowser Graph is too old to be usable. Please close it and open a new one."
	endif
	DFREF sweepBrowserDFR = $SB_GetSweepBrowserFolder(graph)
	ASSERT(DataFolderExistsDFR(sweepBrowserDFR), "sweepBrowserDFR must exist")

	extPanel = SB_GetSweepBrowserLeftPanel(graph)

	if(!ParamIsDefault(newSweep))
		SetPopupMenuIndex(extPanel, "popup_sweep_selector", newSweep)
	endif

	STRUCT TiledGraphSettings tgs
	tgs.displayDAC      = GetCheckBoxState(extPanel, "check_SweepBrowser_DisplayDAC")
	tgs.overlaySweep    = GetCheckBoxState(extPanel, "check_SweepBrowser_SweepOverlay")
	tgs.displayADC      = GetCheckBoxState(extPanel, "check_SweepBrowser_DisplayADC")
	tgs.displayTTL      = GetCheckBoxState(extPanel, "check_SweepBrowser_DisplayTTL")
	tgs.overlayChannels = GetCheckBoxState(extPanel, "check_sweepbrowser_OverlayChan")
	tgs.splitTTLBits    = GetCheckBoxState(extPanel, "check_SweepBrowser_SplitTTL")
	tgs.dDAQDisplayMode = GetCheckBoxState(extPanel, "check_sweepbrowser_dDAQ")
	tgs.dDAQHeadstageRegions = str2num(GetPopupMenuString(extPanel, "popup_dDAQ_regions"))
	tgs.hideSweep       = GetCheckBoxState(extPanel, "check_SweepBrowser_HideSweep")

	STRUCT PostPlotSettings pps
	SB_InitPostPlotSettings(graph, pps)

	WAVE/Z sweepsToOverlay = OVS_GetSelectedSweeps(graph, OVS_SWEEP_SELECTION_INDEX)

	WAVE axesRanges = GetAxesRanges(graph)

	RemoveTracesFromGraph(graph)

	WAVE/T sweepMap = SB_GetSweepBrowserMap(sweepBrowserDFR)
	WAVE channelSel = GetChannelSelectionWave(sweepBrowserDFR)

	if(!WaveExists(sweepsToOverlay))
		Make/FREE/N=1 sweepsToOverlay = GetPopupMenuIndex(extPanel, "popup_sweep_selector")
	endif

	WAVE axisLabelCache = GetAxisLabelCacheWave()

	numEntries = DimSize(sweepsToOverlay, ROWS)
	for(i = 0; i < numEntries; i += 1)
		mapIndex = sweepsToOverlay[i]

		dataFolder = sweepMap[mapIndex][%DataFolder]
		device     = sweepMap[mapIndex][%Device]
		sweepNo    = str2num(sweepMap[mapIndex][%Sweep])

		WAVE/Z activeHS = OVS_ParseIgnoreList(extPanel, highlightSweep, index=mapIndex)
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

		CreateTiledChannelGraph(graph, configWave, sweepNo, numericalValues, textualValues, tgs, sweepDFR, axisLabelCache, traceIndex, channelSelWave=sweepChannelSel)
		AR_UpdateTracesIfReq(graph, sweepDFR, numericalValues, sweepNo)
	endfor

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

	string folder, graph, extPanel, ctrl
	variable hookResult

	switch(s.eventCode)
		case 2:	 // Kill
			graph = s.winName

			folder = SB_GetSweepBrowserFolder(graph)

			KillWindow $graph
			KillOrMoveToTrashPath(folder)

			hookResult = 1
			break
		case 22: // mouse wheel
			graph = s.winName

			if(!windowExists(graph))
				break
			endif

			if(sign(s.wheelDy) == 1) // positive
				ctrl = "button_SweepBrowser_PrevSweep"
			else //negative
				ctrl = "button_SweepBrowser_NextSweep"
			endif

			extPanel = SB_GetSweepBrowserLeftPanel(graph)
			PGC_SetAndActivateControl(extPanel, ctrl)

			hookResult = 1
			break
	endswitch

	return hookResult // 0 if nothing done, else 1
End

Function/DF SB_OpenSweepBrowser()

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
	CheckBox check_SweepBrowser_DisplayDAC,pos={13.00,6.00},size={31.00,15.00},proc=SB_CheckProc_ChangedSetting,title="DA"
	CheckBox check_SweepBrowser_DisplayDAC,help={"Display the DA channel data"}
	CheckBox check_SweepBrowser_DisplayDAC,value= 0
	CheckBox check_SweepBrowser_DisplayADC,pos={57.00,6.00},size={31.00,15.00},proc=SB_CheckProc_ChangedSetting,title="AD"
	CheckBox check_SweepBrowser_DisplayADC,help={"Display the AD channels"},value= 1
	CheckBox check_SweepBrowser_DisplayTTL,pos={98.00,6.00},size={35.00,15.00},proc=SB_CheckProc_ChangedSetting,title="TTL"
	CheckBox check_SweepBrowser_DisplayTTL,help={"Display the TTL channels"}
	CheckBox check_SweepBrowser_DisplayTTL,value= 0
	CheckBox check_SweepBrowser_splitTTL,pos={138.00,7.00},size={13.00,13.00},proc=SB_CheckProc_ChangedSetting,title=""
	CheckBox check_SweepBrowser_splitTTL,help={"Display the TTL channel data as single traces for each TTL bit"}
	CheckBox check_SweepBrowser_splitTTL,value= 0
	CheckBox check_SweepBrowser_OpenArtRem,pos={17.00,295.00},size={103.00,15.00},proc=SB_CheckProc_ChangedSetting,title="Artefact removal"
	CheckBox check_SweepBrowser_OpenArtRem,help={"Open the \"Artefact Removal\" panel"}
	CheckBox check_SweepBrowser_OpenArtRem,value= 0
	CheckBox check_SweepBrowser_ZeroTraces,pos={17.00,278.00},size={76.00,15.00},proc=SB_CheckProc_ChangedSetting,title="Zero Traces"
	CheckBox check_SweepBrowser_ZeroTraces,help={"Remove the offset of all traces"}
	CheckBox check_SweepBrowser_ZeroTraces,value= 0
	CheckBox check_SweepBrowser_AveragTraces,pos={17.00,262.00},size={95.00,15.00},proc=SB_CheckProc_ChangedSetting,title="Average Traces"
	CheckBox check_SweepBrowser_AveragTraces,help={"Average all traces which belong to the same y axis"}
	CheckBox check_SweepBrowser_AveragTraces,value= 0
	Button button_SweepBrowser_RestData,pos={100.00,277.00},size={51.00,20.00},proc=SB_ButtonProc_RestoreData,title="Restore"
	Button button_SweepBrowser_RestData,help={"Duplicate the graph and its trace for further processing"}
	SetVariable setvar_SweepBrowser_SweepStep,pos={68.00,141.00},size={64.00,18.00},title="Step"
	SetVariable setvar_SweepBrowser_SweepStep,help={"Number of sweeps to step for each Previous/Next click or mouse wheel turn"}
	SetVariable setvar_SweepBrowser_SweepStep,limits={1,inf,1},value= _NUM:1
	CheckBox check_sweepbrowser_OverlayChan,pos={13.00,50.00},size={64.00,15.00},proc=SB_CheckProc_ChangedSetting,title="Channels"
	CheckBox check_sweepbrowser_OverlayChan,help={"Overlay the data from multiple channels in one graph"}
	CheckBox check_sweepbrowser_OverlayChan,value= 0
	CheckBox check_SweepBrowser_SweepOverlay,pos={13.00,30.00},size={54.00,15.00},proc=SB_CheckboxProc_OverlaySweeps,title="Sweeps"
	CheckBox check_SweepBrowser_SweepOverlay,help={"Add the data from all visited sweeps instead of clearing the graph every time"}
	CheckBox check_SweepBrowser_SweepOverlay,value= 0
	Button button_SweepBrowser_NextSweep,pos={81.00,117.00},size={60.00,20.00},proc=SB_ButtonProc_ChangeSweep,title="Next"
	Button button_SweepBrowser_NextSweep,help={"Select the previous sweep"}
	Button button_SweepBrowser_PrevSweep,pos={11.00,117.00},size={60.00,20.00},proc=SB_ButtonProc_ChangeSweep,title="Previous"
	Button button_SweepBrowser_PrevSweep,help={"Select the next sweep"}
	CheckBox check_SweepBrowser_TimeAlign,pos={12.00,176.00},size={101.00,15.00},proc=SB_TimeAlignmentProc,title="Time Alignment"
	CheckBox check_SweepBrowser_TimeAlign,help={"Activate time alignment"},value= 0
	PopupMenu popup_sweepBrowser_tAlignMode,pos={0.00,195.00},size={143.00,19.00},bodyWidth=50,disable=2,proc=SB_TimeAlignmentPopup,title="Alignment Mode"
	PopupMenu popup_sweepBrowser_tAlignMode,help={"Select the alignment mode"}
	PopupMenu popup_sweepBrowser_tAlignMode,mode=1,popvalue="Level (Raising)",value= #"\"Level (Raising);Level (Falling);Min;Max\""
	SetVariable setvar_sweepBrowser_tAlignLevel,pos={61.00,219.00},size={80.00,18.00},disable=2,proc=SB_TimeAlignmentLevel,title="Level"
	SetVariable setvar_sweepBrowser_tAlignLevel,help={"Select the level (for rising and falling alignment mode) at which traces are aligned"}
	SetVariable setvar_sweepBrowser_tAlignLevel,limits={-inf,inf,0},value= _NUM:0
	PopupMenu popup_sweepBrowser_tAlignMaster,pos={7.00,239.00},size={134.00,19.00},bodyWidth=50,disable=2,proc=SB_TimeAlignmentPopup,title="Reference trace"
	PopupMenu popup_sweepBrowser_tAlignMaster,help={"Select the reference trace to which all other traces should be aligned to"}
	PopupMenu popup_sweepBrowser_tAlignMaster,mode=1,popvalue="AD0",value= #("SB_GetAllTraces(\"" + graph + "\")")
	Button button_SweepBrowser_DoTimeAlign,pos={117.00,174.00},size={30.00,20.00},disable=2,proc=SB_DoTimeAlignment,title="Do!"
	Button button_SweepBrowser_DoTimeAlign,help={"Perform the time alignment, needs the cursors A and B to have a selected feature"}
	PopupMenu popup_sweep_selector,pos={13.00,91.00},size={127.00,19.00},bodyWidth=127,proc=SB_PopupMenuSelectSweep
	PopupMenu popup_sweep_selector,help={"List of sweeps in this sweep browser"}
	PopupMenu popup_sweep_selector,value= #("SB_GetSweepList(\"" + graph + "\")")
	Button button_SweepBrowser_OpenChanSel,pos={71.00,25.00},size={40.00,20.00},proc=SB_OpenChannelSelectionPanel,title="Chan"
	Button button_SweepBrowser_OpenChanSel,help={"Open the channel selection dialog, allows to disable single channels and headstages"}
	CheckBox check_SweepBrowser_PulseAvg,pos={114.00,26.00},size={37.00,15.00},proc=SB_CheckProc_ChangedSetting,title="PPA"
	CheckBox check_SweepBrowser_PulseAvg,help={"Display per pulse averaged data"}
	CheckBox check_SweepBrowser_PulseAvg,value= 0
	GroupBox group_SB_axes_scaling,pos={11.00,310.00},size={133.00,60.00},title="Axes Scaling"
	CheckBox check_SB_visibleXRange,pos={19.00,329.00},size={40.00,15.00},proc=SB_AxisScaling,title="Vis X"
	CheckBox check_SB_visibleXRange,help={"Scale the y axis to the visible x data range"}
	CheckBox check_SB_visibleXRange,value= 0
	CheckBox check_SB_equalYRanges,pos={69.00,329.00},size={54.00,15.00},proc=SB_AxisScaling,title="Equal Y"
	CheckBox check_SB_equalYRanges,help={"Equalize the vertical axes ranges"}
	CheckBox check_SB_equalYRanges,value= 0
	CheckBox check_SB_equalYIgnLevelCross,pos={19.00,348.00},size={77.00,15.00},proc=SB_AxisScaling,title="Equal Y ign."
	CheckBox check_SB_equalYIgnLevelCross,help={"Equalize the vertical axes ranges but ignore all traces with level crossings"}
	CheckBox check_SB_equalYIgnLevelCross,value= 0
	SetVariable setvar_SB_equalYLevel,pos={98.00,348.00},size={25.00,18.00},disable=2,proc=SB_AxisScalingLevelCross
	SetVariable setvar_SB_equalYLevel,help={"Crossing level value for 'Equal Y ign.\""}
	SetVariable setvar_SB_equalYLevel,limits={-inf,inf,0},value= _NUM:0
	Button button_SweepBrowser_ExportGraph,pos={28.00,375.00},size={100.00,25.00},proc=SB_ButtonProc_ExportTraces,title="Export Traces"
	Button button_SweepBrowser_ExportGraph,help={"Export the traces for further processing"}
	GroupBox group_sweep,pos={6.00,71.00},size={139.00,98.00},title="Sweep"
	CheckBox check_sweepbrowser_dDAQ,pos={97.00,50.00},size={47.00,15.00},proc=SB_CheckProc_ChangedSetting,title="dDAQ"
	CheckBox check_sweepbrowser_dDAQ,help={"Enable dedicated support for viewing distributed DAQ data"}
	CheckBox check_sweepbrowser_dDAQ,value= 0
	PopupMenu popup_dDAQ_regions,pos={96.00,67.00},size={35.00,19.00},bodyWidth=35,disable=2,proc=SB_PopMenuProc_ChangedSettings
	PopupMenu popup_dDAQ_regions,help={"Allows to view only oodDAQ regions from the selected headstage. Choose -1 to display all."}
	PopupMenu popup_dDAQ_regions,mode=1,popvalue="-1",value= #"\"-1;0;1;2;3;4;5;6;7\""
	CheckBox check_SweepBrowser_HideSweep,pos={20.00,143.00},size={50.00,15.00},proc=SB_CheckProc_ChangedSetting,title="Hide"
	CheckBox check_SweepBrowser_HideSweep,help={"Hide sweep traces. Usually combined with \"Average traces\"."}
	CheckBox check_SweepBrowser_HideSweep,value= 0
	RenameWindow #,P0
	SetActiveSubwindow ##

	AddVersionToPanel(graph, SWEEPBROWSER_PANEL_VERSION)
	SB_PanelUpdate(graph)

	return sweepBrowserDFR
End

Function/S SB_GetSweepList(graph)
	string graph

	string list = "", str
	variable numRows, i

	WAVE/T map = SB_GetSweepBrowserMapFromGraph(graph)

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
static Function/S SB_GetPlainSweepList(graph)
	string graph

	string list = "", str
	variable numRows, i

	WAVE/T map = SB_GetSweepBrowserMapFromGraph(graph)

	numRows = GetNumberFromWaveNote(map, NOTE_INDEX)
	for(i = 0; i < numRows; i += 1)
		str  = GetSweepWaveName(str2num(map[i][%Sweep]))
		list = AddListItem(str, list, ";", Inf)
	endfor

	return list
End

/// @brief Return a wave reference wave with all numerical value labnotebook waves
static Function/WAVE SB_GetNumericalValuesWaves(graph)
	string graph

	string list = ""
	string str
	variable numRows, i

	WAVE/T map = SB_GetSweepBrowserMapFromGraph(graph)

	numRows = GetNumberFromWaveNote(map, NOTE_INDEX)

	Make/WAVE/FREE/N=(numRows) allNumericalValues
	allNumericalValues[] = GetAnalysLBNumericalValues(map[p][%DataFolder], map[p][%Device])

	return allNumericalValues
End

/// @brief Return a wave reference wave with all textual value labnotebook waves
static Function/WAVE SB_GetTextualValuesWaves(graph)
	string graph

	string list = ""
	string str
	variable numRows, i

	WAVE/T map = SB_GetSweepBrowserMapFromGraph(graph)

	numRows = GetNumberFromWaveNote(map, NOTE_INDEX)

	Make/WAVE/FREE/N=(numRows) allTextualValues
	allTextualValues[] = GetAnalysLBTextualValues(map[p][%DataFolder], map[p][%Device])

	return allTextualValues
End

Function/S SB_GetAllTraces(graph)
	string graph

	return TraceNameList(graph, ";", 1 + 2)
End

Function SB_PopupMenuSelectSweep(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	string win

	switch(pa.eventCode)
		case 2: // mouse up
			win = pa.win
			SB_UpdateSweepPlot(win)
			break
	endswitch
End

Function SB_ButtonProc_ChangeSweep(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	string win, graph, ctrl
	variable currentSweep, newSweep, direction, totalNumSweeps

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
			totalNumSweeps = ItemsInList(SB_GetSweepList(graph))
			newSweep = limit(newSweep, 0, totalNumSweeps - 1)
			OVS_ChangeSweepSelectionState(win, CHECKBOX_SELECTED, index=newSweep)
			SB_UpdateSweepPlot(win, newSweep=newSweep)
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

			DFREF sweepBrowserDFR = $SB_GetSweepBrowserFolder(graph)
			WAVE channelSel = GetChannelSelectionWave(sweepBrowserDFR)
			ToggleChannelSelectionPanel(graph, channelSel, "SB_CheckProc_ChangedSetting")
			break
	endswitch

	return 0
End

Function SB_ButtonProc_ExportTraces(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch(ba.eventCode)
		case 2: // mouse up
			SBE_ShowExportPanel(ba.win)
			break
	endswitch

	return 0
End

Function SB_ButtonProc_FindMinis(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	variable numTraces, i, first, last
	string list, graph, trace
	switch(ba.eventCode)
		case 2: // mouse up
			graph = GetMainWindow(ba.win)
			list = GetAllSweepTraces(graph)

			first = NumberByKey("POINT", CsrInfo(A, graph))
			last  = NumberByKey("POINT", CsrInfo(B, graph))
			first = min(first, last)
			last  = max(first, last)

			DFREF workDFR = UniqueDataFolder($SB_GetSweepBrowserFolder(graph), "findminis")

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

Function SB_PopMenuProc_ChangedSettings(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	string win

	switch(pa.eventCode)
		case 2: // mouse up
			win   = pa.win
			SB_UpdateSweepPlot(win)
		break
	endswitch

	return 0
End

Function SB_CheckProc_ChangedSetting(cba) : CheckBoxControl
	STRUCT WMCheckBoxAction &cba

	string graph, win, ctrl, channelType, device
	variable idx, checked, channelNum
	DFREF sweepDFR

	switch(cba.eventCode)
		case 2: // mouse up
			ctrl    = cba.ctrlName
			checked = cba.checked
			win     = SB_GetSweepBrowserLeftPanel(cba.win)
			graph   = GetMainWindow(win)
			idx     = GetPopupMenuIndex(win, "popup_sweep_selector")
			DFREF dfr = $SB_GetSweepBrowserFolder(graph)

			if(!cmpstr(ctrl, "check_sweepbrowser_dDAQ"))
				if(checked)
					EnableControl(win, "popup_dDAQ_regions")
				else
					DisableControl(win, "popup_dDAQ_regions")
				endif
			elseif(StringMatch(ctrl, "check_channelSel_*"))
				WAVE channelSel = GetChannelSelectionWave(dfr)
				ParseChannelSelectionControl(cba.ctrlName, channelType, channelNum)
				channelSel[channelNum][%$channelType] = checked
			elseif(!cmpstr(ctrl, "check_SweepBrowser_OpenArtRem"))
				WAVE listBoxWave = GetArtefactRemovalListWave(dfr)
				AR_TogglePanel(win, listBoxWave)
				BSP_TogglePanel(win)
			elseif(!cmpstr(ctrl, "check_SweepBrowser_PulseAvg"))
				PA_TogglePanel(win)
			endif

			SB_UpdateSweepPlot(graph)
			break
	endswitch

	return 0
End

Function SB_ButtonProc_RestoreData(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	string win, graph, traceList, artefactRemovalExtPanel
	variable autoRemoveOldState

	switch(ba.eventCode)
		case 2: // mouse up
			win   = ba.win
			graph = GetMainWindow(ba.win)
			traceList = GetAllSweepTraces(graph)
			ReplaceAllWavesWithBackup(graph, traceList)

			artefactRemovalExtPanel = AR_GetExtPanel(win)
			if(!WindowExists(artefactRemovalExtPanel))
				SB_UpdateSweepPlot(win)
			else
				autoRemoveOldState = GetCheckBoxState(artefactRemovalExtPanel, "check_auto_remove")
				SetCheckBoxState(artefactRemovalExtPanel, "check_auto_remove", CHECKBOX_UNSELECTED)
				SB_UpdateSweepPlot(win)
				SetCheckBoxState(artefactRemovalExtPanel, "check_auto_remove", autoRemoveOldState)
			endif
			break
	endswitch

	return 0
End

Function SB_CheckboxProc_OverlaySweeps(cba) : CheckBoxControl
	STRUCT WMCheckBoxAction &cba

	string graph, sweepWaveList, extPanel
	variable index

	switch(cba.eventCode)
		case 2: // mouse up
			graph    = GetMainWindow(cba.win)
			extPanel = SB_GetSweepBrowserLeftPanel(graph)

			DFREF dfr = $SB_GetSweepBrowserFolder(graph)
			WAVE/T listBoxWave        = GetOverlaySweepsListWave(dfr)
			WAVE listBoxSelWave       = GetOverlaySweepsListSelWave(dfr)
			WAVE/WAVE sweepSelChoices = GetOverlaySweepSelectionChoices(dfr)

			WAVE/WAVE allNumericalValues = SB_GetNumericalValuesWaves(graph)
			WAVE/WAVE allTextualValues   = SB_GetTextualValuesWaves(graph)

			sweepWaveList = SB_GetPlainSweepList(graph)
			OVS_UpdatePanel(graph, listBoxWave, listBoxSelWave, sweepSelChoices, sweepWaveList, allTextualValues=allTextualValues, allNumericalValues=allNumericalValues)
			OVS_TogglePanel(graph, listBoxWave, listBoxSelWave)
			if(OVS_IsActive(graph))
				index = GetPopupMenuIndex(extPanel, "popup_sweep_selector")
				OVS_ChangeSweepSelectionState(extPanel, CHECKBOX_SELECTED, index=index)
			endif
			SB_UpdateSweepPlot(graph)
			break
	endswitch

	return 0
End
