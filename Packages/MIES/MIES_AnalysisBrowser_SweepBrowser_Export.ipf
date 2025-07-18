#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors = 1

#ifdef AUTOMATED_TESTING
#pragma ModuleName = MIES_SBE
#endif // AUTOMATED_TESTING

static StrConstant SBE_EXPORT_PANEL = "ExportSettingsPanel"

/// @file MIES_AnalysisBrowser_SweepBrowser_Export.ipf
/// @brief __SBE__  Panel for exporting sweepbrowser traces to new graphs or existing graphs

static Structure SBE_ExportSettings
	string dataFolder
	variable useCursorRange, resetWaveZero
	variable manualRangeBegin, manualRangeEnd
	string leftAxis, bottomAxis
	string targetGraph, sourceGraph
	variable axisEqualizing, equalYRange
	variable usePulses, numPulses, preFirstPulse, postLastPulse, ADC
EndStructure

static Function SBE_FillExportSettings(string win, STRUCT SBE_ExportSettings &sett)

	variable redistAxis

	sett.dataFolder       = GetSetVariableString(win, "setvar_sweep_export_datafolder")
	sett.useCursorRange   = GetCheckBoxState(win, "checkbox_sweep_export_cursor")
	sett.resetWaveZero    = GetCheckBoxState(win, "checkbox_sweep_export_resetOff")
	sett.manualRangeBegin = GetSetVariable(win, "setvar_sweep_export_x_range_beg")
	sett.manualRangeEnd   = GetSetVariable(win, "setvar_sweep_export_x_range_end")
	sett.targetGraph      = GetPopupMenuString(win, "popup_sweep_export_graph")
	sett.sourceGraph      = GetPopupMenuString(win, "popup_sweep_export_source_graph")
	sett.usePulses        = GetCheckBoxState(win, "checkbox_sweep_export_pulse_set")
	sett.equalYRange      = GetCheckBoxState(win, "checkbox_sweep_export_equalY")
	sett.axisEqualizing   = 0
	redistAxis            = GetCheckBoxState(win, "checkbox_sweep_export_redistAx")

	if(IsControlDisabled(win, "setvar_sweep_export_new_x_name"))
		sett.bottomAxis = GetPopupMenuString(win, "popup_sweep_export_x_axis")

		if(!cmpstr(sett.bottomAxis, "New"))
			if(WindowExists(sett.sourceGraph))
				sett.bottomAxis = GetUniqueAxisName(sett.sourceGraph, "bottom")
			else
				sett.bottomAxis = "bottom"
			endif
		endif
	else
		sett.bottomAxis = GetSetVariableString(win, "setvar_sweep_export_new_x_name")

		if(redistAxis)
			sett.axisEqualizing = sett.axisEqualizing | AXIS_ORIENTATION_HORIZ
		endif
	endif

	if(IsControlDisabled(win, "setvar_sweep_export_new_y_name"))
		sett.leftAxis = GetPopupMenuString(win, "popup_sweep_export_y_axis")

		if(!cmpstr(sett.leftAxis, "New"))
			if(WindowExists(sett.sourceGraph))
				sett.leftAxis = GetUniqueAxisName(sett.sourceGraph, "left")
			else
				sett.leftAxis = "left"
			endif
		endif
	else
		sett.leftAxis = GetSetVariableString(win, "setvar_sweep_export_new_y_name")

		if(redistAxis)
			sett.axisEqualizing = sett.axisEqualizing | AXIS_ORIENTATION_VERT
		endif
	endif

	if(sett.usePulses)
		sett.ADC           = str2num(GetPopupMenuString(win, "popup_sweep_export_pulse_AD"))
		sett.numPulses     = GetSetVariable(win, "setvar_sweep_export_num_pulses")
		sett.preFirstPulse = -GetSetVariable(win, "setvar_sweep_export_pulse_pre")
		sett.postLastPulse = GetSetVariable(win, "setvar_sweep_export_pulse_post")
	else
		sett.ADC           = NaN
		sett.numPulses     = NaN
		sett.preFirstPulse = NaN
		sett.postLastPulse = NaN
	endif
End

/// @brief Return a list of possible axes for the export panel
Function/S SBE_GetSelectedAxis(string graphPopup, variable axisOrientation)

	string graph
	string list = "New;"

	ASSERT(axisOrientation == AXIS_ORIENTATION_HORIZ || axisOrientation == AXIS_ORIENTATION_VERT, "Invalid axis orientation")

	graph = GetPopupMenuString(SBE_EXPORT_PANEL, graphPopup)

	if(!WindowExists(graph))
		return list
	endif

	return list + GetAllAxesWithOrientation(graph, axisOrientation)
End

/// @brief Add all available sweep data to traceData
///
/// This function can fill in the available data for traces which are *not*
/// shown.
static Function SBE_AddMissingADTraceInfo(WAVE/T traceData)

	variable numPaths, i, j, idx, cnt, sweepNumber
	variable numEntries, headstage
	string folder

	Duplicate/FREE/T traceData, newData
	newData = ""

	// get a list of folders holding the sweep data
	numPaths = DimSize(traceData, ROWS)
	Make/FREE/WAVE/N=(numPaths) shownWaves = $traceData[p][%fullPath]

	for(i = 0; i < numPaths; i += 1)
		DFREF     sweepDFR = $GetWavesDataFolder(shownWaves[i], 1)
		WAVE/WAVE allWaves = GetDAQDataSingleColumnWaves(sweepDFR, XOP_CHANNEL_TYPE_ADC)

		WAVE numericalValues = $traceData[i][%numericalValues]
		sweepNumber = str2num(traceData[i][%sweepNumber])

		WAVE ADCs = GetLastSetting(numericalValues, sweepNumber, "ADC", DATA_ACQUISITION_MODE)
		WAVE HS   = GetLastSetting(numericalValues, sweepNumber, "Headstage Active", DATA_ACQUISITION_MODE)

		numEntries = DimSize(allWaves, ROWS)
		for(j = 0; j < numEntries; j += 1)
			WAVE/Z wv = allWaves[j]

			// no sweep data for this channel
			if(!WaveExists(wv))
				continue
			endif

			idx = GetRowIndex(shownWaves, refWave = allWaves[j])

			if(IsFinite(idx)) // single sweep data already in traceData
				continue
			endif

			// labnotebook layer where the ADC can be found is the headstage number
			headstage = GetRowIndex(ADCs, val = j)

			if(!IsAssociatedChannel(headstage))
				continue
			endif

			EnsureLargeEnoughWave(newData, indexShouldExist = cnt)
			newData[cnt][] = traceData[i][q]

			newData[cnt][%traceName]     = ""
			newData[cnt][%fullPath]      = GetWavesDataFolder(wv, 2)
			newData[cnt][%channelType]   = StringFromList(XOP_CHANNEL_TYPE_ADC, XOP_CHANNEL_NAMES)
			newData[cnt][%channelNumber] = num2str(j)
			newData[cnt][%headstage]     = num2str(headstage)
			cnt                         += 1
		endfor
	endfor

	if(cnt == 0)
		return NaN
	endif

	Redimension/N=(numPaths + cnt, -1) traceData

	traceData[numPaths, Inf][] = newData[p - numPaths][q]

	SortColumns/A/DIML/KNDX={2, 3, 4, 5} sortWaves=traceData
End

static Function/WAVE SBE_GetPulseStartTimesForSel()

	string graph, traceName
	variable region, idx, ADC

	graph = GetPopupMenuString(SBE_EXPORT_PANEL, "popup_sweep_export_source_graph")
	if(!WindowExists(graph))
		return $""
	endif

	ADC = str2num(GetPopupMenuString(SBE_EXPORT_PANEL, "popup_sweep_export_pulse_AD"))

	WAVE/Z/T traceData = GetGraphUserData(graph)
	if(!WaveExists(traceData))
		return $""
	endif

	SBE_AddMissingADTraceInfo(traceData)

	WAVE/Z indizesType   = FindIndizes(traceData, colLabel = "channelType", str = "AD")
	WAVE/Z indizesNumber = FindIndizes(traceData, colLabel = "channelNumber", var = ADC)

	if(!WaveExists(indizesType) || !WaveExists(indizesNumber))
		return $""
	endif

	WAVE indizes = GetSetIntersection(indizesType, indizesNumber)

	if(!WaveExists(indizes) && DimSize(indizes, ROWS) != 1)
		return $""
	endif

	// use the region data from the first sweep
	idx    = indizes[0]
	region = str2num(traceData[idx][%headstage])

	WAVE/Z pulseInfos = PA_GetPulseInfos(traceData, idx, region, "AD")

	if(!WaveExists(pulseInfos))
		return $""
	endif

	Duplicate/FREE/RMD=[][FindDimLabel(pulseInfos, ROWS, "PulseStart")] pulseInfos, pulseStartTimes

	return pulseStartTimes
End

/// @brief Display the export panel
Function SBE_ShowExportPanel(string sourceWindow)

	string panel = SBE_EXPORT_PANEL

	if(WindowExists(panel))
		DoWindow/F $panel
	else
		Execute panel + "()"
	endif

	ControlUpdate/W=$panel popup_sweep_export_source_graph
	PopupMenu popup_sweep_export_source_graph, win=$panel, popmatch=GetMainWindow(sourceWindow)
End

/// @brief Return a list of possible target graphs for the export panel
Function/S SBE_ListOfGraphsAndNew()

	return "New;" + WinList("*", ";", "WIN:1")
End

/// @brief Return a list of possible source graphs for the export panel
Function/S SBE_ListOfSweepGraphs()

	return WinList("SweepBrowser*", ";", "WIN:1") + WinList("DB_*", ";", "WIN:1")
End

/// @brief Return a list of all AD traces from the selected target graph
Function/S SBE_GetSourceGraphADTraces()

	string sourceGraph

	sourceGraph = GetPopupMenuString(SBE_EXPORT_PANEL, "popup_sweep_export_source_graph")

	if(!cmpstr(sourceGraph, "New"))
		return ""
	endif

	WAVE/Z/T result = GetAllSweepTraces(sourceGraph, prefixTraces = 0, channelType = XOP_CHANNEL_TYPE_ADC)

	if(!WaveExists(result))
		return ""
	endif

	return TextWaveToList(result, ";")
End

/// @brief Export the sweep browser traces to a user given folder
///
/// Creates a new graph from it or appends to an existing one.
/// Only duplicates the main graph without external subwindows
static Function SBE_ExportSweepBrowser(STRUCT SBE_ExportSettings &sett)

	string trace, folder, newPrefix, analysisPrefix, relativeDest, win, wvName, unit, stimset
	string graphName, graphMacro, saveDFR, traceList, line, newGraph, newWvName, traceAxis
	string rest, xAxesList, yAxesList, axis, refMacro, newAxis, oldTrace, newTrace, niceStimSet, garbage
	string newHorizAxes   = ""
	string newVertAxes    = ""
	string listOfStimSets = ""
	variable numTraces, i, j, pos, numLines, clipXRange, doCreateNewGraph, axisIndex, sweep
	variable beginX, endX, xcsrA, xcsrB, beginXPerWave, endXPerWave, numAxesList, headstage

	doCreateNewGraph = !cmpstr(sett.targetGraph, "New")

	if(!cmpstr(sett.sourceGraph, sett.targetGraph))
		printf "Source and target graph can not be the same!\r"
		ControlWindowToFront()
		return NaN
	elseif(!WindowExists(sett.sourceGraph))
		printf "Source graph does not exist!\r"
		ControlWindowToFront()
		return NaN
	elseif(!doCreateNewGraph && !WindowExists(sett.targetGraph))
		printf "Target graph does not exist!\r"
		ControlWindowToFront()
		return NaN
	endif

	DFREF sweepBrowserDFR = SB_GetSweepBrowserFolder(sett.sourceGraph)

	if(doCreateNewGraph)
		newPrefix = GetDataFolder(1, UniqueDataFolder($"root:", sett.dataFolder))
		newPrefix = RemoveEnding(newPrefix, ":")
	else
		traceList = TraceNameList(sett.targetGraph, ";", 0 + 1)
		numTraces = ItemsInList(traceList)
		ASSERT(numTraces > 0, "No traces found on existing graph")
		newPrefix = GetDataFolder(1, GetWavesDataFolderDFR(TraceNameToWaveRef(sett.targetGraph, StringFromList(0, traceList))))
		newPrefix = RemoveEnding(ParseFilePath(1, newPrefix, ":", 0, 2), ":")
	endif

	analysisPrefix = GetAnalysisFolderAS()

	if(sett.usePulses)
		WAVE/Z pulseStartTimes = SBE_GetPulseStartTimesForSel()
		if(!WaveExists(pulseStartTimes))
			printf "Could not find any pulse starting times for ADC %d\r", sett.ADC
			ControlWindowToFront()
			return NaN
		endif
		ASSERT(sett.numPulses < DimSize(pulseStartTimes, ROWS), "Invalid number of pulses")
		beginX     = pulseStartTimes[0] + sett.preFirstPulse
		endX       = pulseStartTimes[sett.numPulses] + sett.postLastPulse
		clipXRange = 1
	elseif(sett.useCursorRange)
		xcsrA          = xcsr(A, sett.sourceGraph)
		xcsrB          = xcsr(B, sett.sourceGraph)
		[beginX, endX] = MinMax(xcsrA, xcsrB)
		clipXRange     = 1
	elseif(isFinite(sett.manualRangeBegin) && IsFinite(sett.manualRangeEnd))
		beginX     = sett.manualRangeBegin
		endX       = sett.manualRangeEnd
		clipXRange = 1
	endif

	graphMacro = WinRecreation(sett.sourceGraph, 0)

	// everything we don't need anymore starts in the line with SetWindow
	// ranging to the macro's end
	pos = strsearch(graphMacro, "SetWindow kwTopWin", 0)
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
	folder     = GetDataFolder(1, sweepBrowserDFR)
	folder     = RemovePrefix(folder, start = "root:")
	folder     = ":::::::" + folder
	graphMacro = ReplaceString(folder, graphMacro, newPrefix + ":")

	traceList = TraceNameList(sett.sourceGraph, ";", 0 + 1)
	numTraces = ItemsInList(traceList)

	for(i = 0; i < numTraces; i += 1)
		trace = StringFromList(i, traceList)
		WAVE wv = TraceNameToWaveRef(sett.sourceGraph, trace)

		// the waves can be in two locations, either in root:$sweepBrowser
		// or down below in root:MIES:analysis:$Experiment:$Device:sweep:$X
		DFREF loc = GetWavesDataFolderDFR(wv)
		if(DataFolderRefsEqual(loc, sweepBrowserDFR))
			DFREF dfr = createDFWithAllParents(newPrefix)
		else
			relativeDest = RemovePrefix(GetDataFolder(1, loc), start = analysisPrefix)
			DFREF dfr = createDFWithAllParents(newPrefix + relativeDest)
		endif

		if(clipXRange)
			beginXPerWave = max(leftx(wv), beginX)
			endXPerWave   = min(rightx(wv), endX)
		else
			beginXPerWave = leftx(wv)
			endXPerWave   = rightx(wv)
		endif

		wvName    = NameOfWave(wv)
		newWvName = UniqueWaveName(dfr, wvName)

		Duplicate/R=(beginXPerWave, endXPerWave) wv, dfr:$newWvName/WAVE=dup
		WaveClear wv

		if(cmpstr(wvName, newWvName))
			graphMacro = ReplaceWordInString(wvName, graphMacro, newWvName)
		endif

		if(clipXRange)
			AddEntryIntoWaveNoteAsList(dup, "CursorA", var = beginX)
			AddEntryIntoWaveNoteAsList(dup, "CursorB", var = endX)
		endif

		if(sett.resetWaveZero)
			AddEntryIntoWaveNoteAsList(dup, "OldDimOffset", var = DimOffset(dup, ROWS))
			SetScale/P x, 0, DimDelta(dup, ROWS), WaveUnits(dup, ROWS), dup
		endif
	endfor

	// we have to replace all occurences of existing axes with
	// the new axes and also add a numerical suffix for the new
	// axes as the user only chooses the base name
	axisIndex   = 0
	newAxis     = sett.bottomAxis
	xAxesList   = GetAllAxesWithOrientation(sett.sourceGraph, AXIS_ORIENTATION_HORIZ)
	numAxesList = ItemsInList(xAxesList)
	for(i = 0; i < numAxesList; i += 1)
		axis = StringFromList(i, xAxesList)

		refMacro   = graphMacro
		graphMacro = ReplaceWordInString(axis, graphMacro, newAxis)

		if(cmpstr(refMacro, graphMacro))
			newHorizAxes = AddListItem(newAxis, newHorizAxes, ";", Inf)
			newAxis      = sett.bottomAxis + num2str(axisIndex++)
		endif
	endfor

	axisIndex   = 0
	newAxis     = sett.leftAxis
	yAxesList   = GetAllAxesWithOrientation(sett.sourceGraph, AXIS_ORIENTATION_VERT)
	numAxesList = ItemsInList(yAxesList)

	Make/FREE/N=(numAxesList, 2)/T yAxesStimSetMapping

	for(i = 0; i < numAxesList; i += 1)
		axis = StringFromList(i, yAxesList)

		refMacro   = graphMacro
		graphMacro = ReplaceWordInString(axis, graphMacro, newAxis)

		listOfStimSets = ""

		for(j = 0; j < numTraces; j += 1)
			trace     = StringFromList(j, traceList)
			traceAxis = TUD_GetUserData(sett.sourceGraph, trace, "YAXIS")

			if(cmpstr(traceAxis, axis))
				continue
			endif

			WAVE/Z textualValues = $TUD_GetUserData(sett.sourceGraph, trace, "textualValues")

			if(!WaveExists(textualValues)) // non-sweep waves
				continue
			endif

			headstage = str2num(TUD_GetUserData(sett.sourceGraph, trace, "headstage"))
			sweep     = str2num(TUD_GetUserData(sett.sourceGraph, trace, "sweepNumber"))

			WAVE/T stimSets = GetLastSetting(textualValues, sweep, STIM_WAVE_NAME_KEY, DATA_ACQUISITION_MODE)

			listOfStimSets = AddListItem(stimSets[headstage], listOfStimSets, ";", Inf)
		endfor

		yAxesStimSetMapping[i][0] = newAxis

		if(ListHasOnlyOneUniqueEntry(listOfStimSets))
			stimset = StringFromList(0, listOfStimSets)
			SplitString/E="^(.*)_(?:DA|TTL)_[[:digit:]]$" stimset, niceStimSet, garbage
			yAxesStimSetMapping[i][1] = niceStimSet
		else
			yAxesStimSetMapping[i][1] = ""
		endif

		if(cmpstr(refMacro, graphMacro))
			newVertAxes = AddListItem(newAxis, newVertAxes, ";", Inf)
			newAxis     = sett.leftAxis + num2str(axisIndex++)
		endif
	endfor

	// replace trace name specifications so that they are unique in the target graph
	if(!doCreateNewGraph)
		traceList = TraceNameList(sett.sourceGraph, ";", 1 + 2)
		numTraces = ItemsInList(traceList)
		for(i = 0; i < numTraces; i += 1)
			oldTrace   = StringFromList(i, traceList)
			newTrace   = UniqueTraceName(sett.targetGraph, oldTrace)
			graphMacro = ReplaceWordInString(oldTrace, graphMacro, newTrace)
		endfor
	endif

	if(!doCreateNewGraph)
		ASSERT(WindowExists(sett.targetGraph), "Missing targetGraph")
		DoWindow/F $sett.targetGraph
	endif

	saveDFR = GetDataFolder(1)
	// The first three lines are:
	// Window SweepBrowser1() : Graph
	//		PauseUpdate; Silent 1		// building window...
	// 		String fldrSav0= GetDataFolder(1)
	numLines = ItemsInList(graphMacro, "\r")
	for(i = 3; i < numLines; i += 1)
		line = TrimString(StringFromList(i, graphMacro, "\r"), 1)

		if(!doCreateNewGraph)
			if(GrepString(line, "^Display.*"))
				SplitString/E="Display[[:space:]]*/W=\([^)]+\)[[:space:]]*(?:/K=1)?[[:space:]]*(.*)" line, rest
				line = "AppendToGraph" + rest
			endif
		endif

		if(GrepString(line, "^Label.*"))
			SplitString/E="(?i)^Label ([^[:space:]]+) .*(\(.*\))\"$" line, axis, unit
			if(V_Flag == 2)
				WAVE indizes = FindIndizes(yAxesStimSetMapping, str = axis)
				ASSERT(DimSize(indizes, ROWS) == 1, "Invalid yAxesStimSetMapping wave")
				sprintf line, "Label %s \"\\Z12%s\\r%s\"", axis, yAxesStimSetMapping[indizes[0]][1], unit
			endif
		endif

		DEBUGPRINT(line)
		Execute/Q line
	endfor

	if(doCreateNewGraph)
		graphName = RemovePrefix(newPrefix, start = "root:")
		if(WindowExists(graphName))
			graphName = UniqueName(graphName, 6, 0)
		endif

		// created by Display command from the Macro execution
		SVAR newName = S_name
		RenameWindow $newName, $graphName
		AutoPositionWindow/R=$sett.sourceGraph/M=1 $graphName
	else
		graphName = sett.targetGraph
	endif

	if(sett.axisEqualizing & AXIS_ORIENTATION_HORIZ)
		EquallySpaceAxis(graphName, axisOrientation = AXIS_ORIENTATION_HORIZ, listForEnd = newHorizAxes)
	endif

	if(sett.axisEqualizing & AXIS_ORIENTATION_VERT)
		EquallySpaceAxis(graphName, axisOrientation = AXIS_ORIENTATION_VERT, listForEnd = newVertAxes)
	endif

	ModifyGraph/W=$graphName freePos=0

	if(sett.equalYRange)
		DoUpdate/W=$graphName
		EqualizeVerticalAxesRanges(graphName, rangePerClampMode = 1)
	endif

	Execute/P/Q "KillStrings/Z S_name"
	Execute/P/Q "SetDataFolder " + saveDFR
End

Function SBE_PopMenu_ExportTargetAxis(STRUCT WMPopupAction &pa) : PopupMenuControl

	string popStr, win, list

	switch(pa.eventCode)
		case 2: // mouse up
			popStr = pa.popStr
			win    = pa.win

			strswitch(pa.ctrlName)
				case "popup_sweep_export_y_axis":
					list = "setvar_sweep_export_new_y_name"
					break
				case "popup_sweep_export_x_axis":
					list = "setvar_sweep_export_new_x_name"
					break
				default:
					FATAL_ERROR("Unknown control name")
					break
			endswitch

			if(!cmpstr(popStr, "New"))
				EnableControls(win, list)
			else
				DisableControls(win, list)
			endif

			break
		default:
			break
	endswitch

	return 0
End

Function SBE_PopMenu_ExportTargetGraph(STRUCT WMPopupAction &pa) : PopupMenuControl

	string popStr, win

	switch(pa.eventCode)
		case 2: // mouse up
			popStr = pa.popStr
			win    = pa.win

			if(!cmpstr(popStr, "New"))
				EnableControl(win, "setvar_sweep_export_datafolder")
			else
				DisableControl(win, "setvar_sweep_export_datafolder")
			endif

			break
		default:
			break
	endswitch

	return 0
End

Function SBE_ButtonProc_PerformExport(STRUCT WMButtonAction &ba) : ButtonControl

	string win

	switch(ba.eventCode)
		case 2: // mouse up
			win = ba.win

			STRUCT SBE_ExportSettings sett
			SBE_FillExportSettings(win, sett)
			SBE_ExportSweepBrowser(sett)
			break
		default:
			break
	endswitch

	return 0
End

Function SBE_CheckProc_UsePulseForXRange(STRUCT WMCheckboxAction &cba) : CheckBoxControl

	string listXManual, listXPulses, win

	switch(cba.eventCode)
		case 2: // mouse up
			win = cba.win

			listXManual = "checkbox_sweep_export_cursor;setvar_sweep_export_x_range_beg;setvar_sweep_export_x_range_end"
			listXPulses = "popup_sweep_export_pulse_AD;setvar_sweep_export_num_pulses;setvar_sweep_export_pulse_pre;setvar_sweep_export_pulse_post"
			if(cba.checked)
				EnableControls(win, listXPulses)
				DisableControls(win, listXManual)
				// force control activation without changing the selection
				PGC_SetAndActivateControl(win, "popup_sweep_export_pulse_AD", val = GetPopupMenuIndex(win, "popup_sweep_export_pulse_AD"))
			else
				EnableControls(win, listXManual)
				DisableControls(win, listXPulses)
			endif
			break
		default:
			break
	endswitch

	return 0
End

Function SBE_PopMenuProc_PulsesADTrace(STRUCT WMPopupAction &pa) : PopupMenuControl

	variable numPulses

	switch(pa.eventCode)
		case 2: // mouse up
			WAVE/Z pulseStartTimes = SBE_GetPulseStartTimesForSel()

			if(!WaveExists(pulseStartTimes))
				break
			endif

			numPulses = DimSize(pulseStartTimes, ROWS)
			SetVariable setvar_sweep_export_num_pulses, win=$pa.win, limits={1, numPulses, 1}

			break
		default:
			break
	endswitch

	return 0
End
