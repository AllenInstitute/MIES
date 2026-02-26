#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3
#pragma rtFunctionErrors = 1

#ifdef AUTOMATED_TESTING
#pragma ModuleName = MIES_MIESUTILS_GUI
#endif // AUTOMATED_TESTING

#include <Axis Utilities>

/// @file MIES_MiesUtilities_GUI.ipf
/// @brief This file holds MIES utility functions for GUI

Menu "GraphPopup"
	"Export graph to SVG", /Q, ExportGraphToSVG(GetCurrentWindow())
End

/// @brief Return the dimension label for the special, aka non-unique, controls
Function/S GetSpecialControlLabel(variable channelType, variable controlType)

	return RemoveEnding(GetPanelControl(0, channelType, controlType), "_00")
End

/// @brief Returns the name of a control from the DA_EPHYS panel
///
/// Constants are defined at @ref ChannelTypeAndControlConstants
Function/S GetPanelControl(variable channelIndex, variable channelType, variable controlType)

	string ctrl

	ctrl = ChannelTypeToString(channelType)

	if(controlType == CHANNEL_CONTROL_WAVE)
		ctrl = "Wave_" + ctrl
	elseif(controlType == CHANNEL_CONTROL_INDEX_END)
		ctrl = "IndexEnd_" + ctrl
	elseif(controlType == CHANNEL_CONTROL_UNIT)
		ctrl = "Unit_" + ctrl
	elseif(controlType == CHANNEL_CONTROL_GAIN)
		ctrl = "Gain_" + ctrl
	elseif(controlType == CHANNEL_CONTROL_SCALE)
		ctrl = "Scale_" + ctrl
	elseif(controlType == CHANNEL_CONTROL_CHECK)
		ctrl = "Check_" + ctrl
	elseif(controlType == CHANNEL_CONTROL_ALARM_MIN)
		ctrl = "Min_" + ctrl
	elseif(controlType == CHANNEL_CONTROL_ALARM_MAX)
		ctrl = "Max_" + ctrl
	elseif(controlType == CHANNEL_CONTROL_SEARCH)
		ctrl = "Search_" + ctrl
	elseif(controlType == CHANNEL_CONTROL_TITLE)
		ctrl = "Title_" + ctrl
	else
		FATAL_ERROR("Invalid controlType")
	endif

	if(channelIndex == CHANNEL_INDEX_ALL)
		ctrl += "_All"
	elseif(channelIndex == CHANNEL_INDEX_ALL_V_CLAMP)
		ctrl += "_AllVClamp"
	elseif(channelIndex == CHANNEL_INDEX_ALL_I_CLAMP)
		ctrl += "_AllIClamp"
	else
		ASSERT(channelIndex >= 0 && channelIndex < 100, "invalid channelIndex")
		sprintf ctrl, "%s_%02d", ctrl, channelIndex
	endif

	return ctrl
End

/// @brief Helper function for CreateTiledChannelGraph and friends
///
/// Return the next trace index for a graph which uses our trace data storage
/// wave.
Function GetNextTraceIndex(string graph)

	variable traceCount, traceIndex
	string lastTraceName

	traceCount = TUD_GetTraceCount(graph)

	if(traceCount == 0)
		return 0
	endif

	WAVE/T graphUserData = GetGraphUserData(graph)
	lastTraceName = graphUserData[traceCount - 1][%traceName]
	traceIndex    = str2num(lastTraceName[1, Inf]) + 1
	ASSERT(IsFinite(traceIndex), "Non finite trace index")

	return traceIndex
End

/// @brief Return a trace name prefix suitable for GetNextTraceIndex()
Function/S GetTraceNamePrefix(variable traceIndex)

	string name

	sprintf name, "T%0*d", TRACE_NAME_NUM_DIGITS, traceIndex

	return name
End

/// @brief Return the color of the given headstage
///
/// @param headstage     Headstage, Use "NaN" for non-associated channels
/// @param channelType   [optional, empty by default] The channel type for non-associated channels, currently only XOP_CHANNEL_TYPE_TTL is evaluated
/// @param channelNumber [optional, empty by default] For plotting "TTL" channels only, GUI channel number for `isSplitted` being true,
///                       a running index of the hardware channel otherwise
/// @param isSplitted    [optional, default 1] For plotting "TTL" channels only, Flag if the color for a splitted or unsplitted channel should be returned
Function [STRUCT RGBColor s] GetHeadstageColor(variable headstage, [variable channelType, variable channelNumber, variable isSplitted])

	string str
	variable colorIndex, blockSizeTTL, activeChannelIndexAsOfITC, ttlBitAsOfITC, blockOffsetTTL
	variable offsetTTL = 10

	isSplitted = ParamIsDefault(isSplitted) ? 1 : !!isSplitted

	if(IsValidHeadstage(headstage))
		colorIndex = headstage
	elseif(!ParamIsDefault(channelType) && channelType == XOP_CHANNEL_TYPE_TTL)
		// The mapping is based on ITC hardware with unsplitted and splitted TTL channels in the following index order
		// Unsplit0, Split0_0, Split0_1, Split0_2, Split0_3, Unsplit1, Split1_0, Split1_1, Split1_2, Split1_3
		blockSizeTTL              = NUM_ITC_TTL_BITS_PER_RACK + 1
		activeChannelIndexAsOfITC = trunc(channelNumber / NUM_ITC_TTL_BITS_PER_RACK)
		ttlBitAsOfITC             = mod(channelNumber, NUM_ITC_TTL_BITS_PER_RACK)
		blockOffsetTTL            = isSplitted ? (1 + ttlBitAsOfITC) : 0
		colorIndex                = offsetTTL + activeChannelIndexAsOfITC * blockSizeTTL + blockOffsetTTL
	else
		colorIndex = NUM_HEADSTAGES
	endif

	sprintf str, "colorIndex=%d", colorIndex
	DEBUGPRINT(str)

	[s] = GetTraceColor(colorIndex)
End

/// @brief Time Alignment for the BrowserSettingsPanel
///
/// This function should work for any given reference trace in
/// pps.timeAlignRefTrace in the popup menu. (DB and SB)
///
/// @param graph graph with sweep traces
/// @param pps   settings
Function TimeAlignMainWindow(string graph, STRUCT PostPlotSettings &pps)

	variable csrAx, csrBx

	if(pps.timeAlignment)
		GetCursorXPositionAB(graph, csrAx, csrBx)
		TimeAlignmentIfReq(pps.timeAlignRefTrace, pps.timeAlignMode, pps.timeAlignLevel, csrAx, csrBx, force = 1)
	endif
End

/// @brief return a list of all traces relevant for TimeAlignment
Function/S TimeAlignGetAllTraces(string graph)

	WAVE/Z/T traces = GetAllSweepTraces(graph)

	if(!WaveExists(traces))
		return ""
	endif

	return TextWaveToList(traces, ";")
End

/// @brief Adds or removes the cursors from the graphs depending on the
///        panel settings
///
/// @param win  main DB/SB graph or any subwindow panel.
Function TimeAlignHandleCursorDisplay(string win)

	string graphtrace, graph, graphs, trace, traceList, bsPanel, csrA, csrB
	variable length, posA, posB

	win     = GetMainWindow(win)
	bsPanel = BSP_GetPanel(win)

	traceList = TimeAlignGetAllTraces(win)
	if(isEmpty(traceList))
		return NaN
	endif

	graphs = win

	// deactivate cursor
	if(!GetCheckBoxState(bsPanel, "check_BrowserSettings_TA"))
		KillCursorInGraphs(graphs, "A")
		KillCursorInGraphs(graphs, "B")
		return 0
	endif

	// save cursor and kill all available A,B cursors
	graph = FindCursorInGraphs(graphs, "A")
	if(!isempty(graph))
		csrA = CsrInfo(A, graph)
		KillCursorInGraphs(graphs, "A")
		csrB = CsrInfo(B, graph)
		KillCursorInGraphs(graphs, "B")
	endif

	// ensure that trace is really on the graph
	graphtrace = GetPopupMenuString(bsPanel, "popup_TimeAlignment_Master")
	if(FindListItem(graphtrace, traceList) == -1)
		graphtrace = StringFromList(0, traceList)
	endif
	graph = StringFromList(0, graphtrace, "#")
	trace = StringFromList(1, graphtrace, "#")

	// set cursor to trace
	if(isEmpty(csrA) || isEmpty(csrB))
		WAVE wv = TraceNameToWaveRef(graph, trace)
		length = DimSize(wv, ROWS)
		posA   = length / 3
		posB   = length * 2 / 3
	else
		posA = NumberByKey("POINT", csrA)
		posB = NumberByKey("POINT", csrB)
	endif
	Cursor/W=$graph/A=1/N=1/P A, $trace, posA
	Cursor/W=$graph/A=1/N=1/P B, $trace, posB
End

/// @brief Enable/Disable TimeAlignment Controls and Cursors
Function TimeAlignUpdateControls(string win)

	variable alignMode

	string bsPanel, graph

	bsPanel = BSP_GetPanel(win)
	graph   = GetMainWindow(win)

	if(GetCheckBoxState(bsPanel, "check_BrowserSettings_TA"))
		EnableControls(bsPanel, "popup_TimeAlignment_Mode;setvar_TimeAlignment_LevelCross;popup_TimeAlignment_Master;button_TimeAlignment_Action")

		alignMode = GetPopupMenuIndex(bsPanel, "popup_TimeAlignment_Mode")
		if(alignMode == TIME_ALIGNMENT_LEVEL_RISING || alignMode == TIME_ALIGNMENT_LEVEL_FALLING)
			EnableControl(bsPanel, "setvar_TimeAlignment_LevelCross")
		else
			DisableControl(bsPanel, "setvar_TimeAlignment_LevelCross")
		endif

		ControlUpdate/W=$bsPanel popup_TimeAlignment_Master
	else
		DisableControls(bsPanel, "popup_TimeAlignment_Mode;setvar_TimeAlignment_LevelCross;popup_TimeAlignment_Master;button_TimeAlignment_Action")
	endif

	TimeAlignHandleCursorDisplay(graph)
End

Function TimeAlignCursorMovedHook(STRUCT WMWinHookStruct &s)

	string trace, graphtrace, graphtraces, xAxis, yAxis, bsPanel, mainPanel
	variable numTraces, i

	switch(s.eventCode)
		case EVENT_WINDOW_HOOK_CURSORMOVED:
			trace = s.traceName
			if(isEmpty(trace))
				return 0
			endif

			bsPanel = BSP_GetPanel(s.winName)

			if(!GetCheckBoxState(bsPanel, "check_BrowserSettings_TA"))
				return 0
			endif

			mainPanel   = GetMainWindow(bsPanel)
			graphtrace  = s.winName + "#" + trace
			graphtraces = TimeAlignGetAllTraces(mainPanel)
			if(FindListItem(graphtrace, graphtraces) == -1)
				xAxis = TUD_GetUserData(s.winName, trace, "XAXIS")
				yAxis = TUD_GetUserData(s.winName, trace, "YAXIS")

				WAVE/T traces = TUD_GetUserDataAsWave(s.winName, "tracename", keys = {"XAXIS", "YAXIS"}, \
				                                      values = {xAxis, yAxis})

				numTraces = DimSize(traces, ROWS)
				for(i = 0; i < numTraces; i += 1)
					trace      = traces[i]
					graphtrace = s.winName + "#" + trace

					if(FindListItem(graphtrace, graphtraces) != -1)
						break
					endif
				endfor
			endif

			PGC_SetAndActivateControl(bsPanel, "popup_TimeAlignment_Master", str = graphtrace)
			break
		default:
			break
	endswitch

	return 0
End

/// @brief Get a textwave of all traces from a list of graphs
///
/// @param graphs       semicolon separated list of graph names
/// @param region       [optional] return only traces with the specified region
///                     userdata entry
/// @param channelType  [optional] return only the traces with the given channel type
/// @param prefixTraces [optional, defaults to true] prefix the traces names with the graph name and a `#`
///
/// @returns graph#trace named patterns
Function/WAVE GetAllSweepTraces(string graphs, [variable region, variable channelType, variable prefixTraces])

	string graph
	variable i, idx, numGraphs

	if(ParamIsDefault(prefixTraces))
		prefixTraces = 1
	else
		prefixTraces = !!prefixTraces
	endif

	numGraphs = ItemsInList(graphs)

	Make/FREE/N=(numGraphs)/WAVE resultWave

	for(i = 0; i < numGraphs; i += 1)
		graph = StringFromList(i, graphs)
		if(ParamIsDefault(region) && ParamIsDefault(channelType))
			WAVE/Z/T traces = GetSweepUserData(graph, "traceName")
		elseif(!ParamIsDefault(region))
			WAVE/Z/T traces = GetSweepUserData(graph, "traceName", region = region)
		elseif(!ParamIsDefault(channelType))
			WAVE/Z/T traces = GetSweepUserData(graph, "traceName", channelType = channelType)
		elseif(!ParamIsDefault(region) && !ParamIsDefault(channelType))
			WAVE/Z/T traces = GetSweepUserData(graph, "traceName", channelType = channelType, region = region)
		endif

		if(!WaveExists(traces))
			continue
		endif

		if(prefixTraces)
			traces[] = graph + "#" + traces[p]
		endif

		resultWave[idx++] = traces
	endfor

	if(idx == 0)
		return $""
	elseif(idx == 1)
		return resultWave[0]
	endif

	Redimension/N=(idx) resultWave

	Concatenate/FREE/NP {resultWave}, graphTraces

	return graphTraces
End

// @brief Return a 1D text wave with the given property of all sweep waves without duplicates
Function/WAVE GetSweepUserData(string graph, string key, [variable channelType, variable region])

	if(ParamIsDefault(channelType) && ParamIsDefault(region))
		return TUD_GetUserDataAsWave(graph, key, keys = {"traceType", "occurence"}, values = {"sweep", "0"})
	elseif(!ParamIsDefault(channelType))
		return TUD_GetUserDataAsWave(graph, key, keys = {"traceType", "occurence", "channelType"},          \
		                             values = {"sweep", "0", StringFromList(channelType, XOP_CHANNEL_NAMES)})
	elseif(!ParamIsDefault(region))
		return TUD_GetUserDataAsWave(graph, key, keys = {"traceType", "occurence", "region"}, \
		                             values = {"sweep", "0", num2str(region)})
	endif
End

/// @brief Find the given feature in the given wave range
/// `first` and `last` are in x coordinates and clipped to valid values
static Function CalculateFeatureLoc(WAVE wv, variable mode, variable level, variable first, variable last)

	variable edgeType

	ASSERT(mode == TIME_ALIGNMENT_NONE || mode == TIME_ALIGNMENT_LEVEL_RISING || mode == TIME_ALIGNMENT_LEVEL_FALLING || mode == TIME_ALIGNMENT_MIN || mode == TIME_ALIGNMENT_MAX, "Invalid mode")

	first = max(first, leftx(wv))
	last  = min(last, rightx(wv))

	if(mode == TIME_ALIGNMENT_MIN || mode == TIME_ALIGNMENT_MAX)
		WaveStats/M=1/Q/R=(first, last) wv

		if(mode == TIME_ALIGNMENT_MAX)
			return V_maxLoc
		endif

		return V_minLoc
	elseif(mode == TIME_ALIGNMENT_LEVEL_RISING || mode == TIME_ALIGNMENT_LEVEL_FALLING)
		if(mode == TIME_ALIGNMENT_LEVEL_RISING)
			edgeType = 1
		else
			edgeType = 2
		endif
		FindLevel/Q/R=(first, last)/EDGE=(edgeType) wv, level
		if(V_Flag) // found no level
			return NaN
		endif
		return V_LevelX
	endif
End

/// @brief Perform time alignment of features in the sweep traces
///
/// @param graphtrace reference trace in the form of graph#trace
/// @param mode       time alignment mode
/// @param level      level input to the @c FindLevel operation in @see CalculateFeatureLoc
/// @param pos1x      specify start range for feature position
/// @param pos2x      specify end range for feature position
/// @param force      [optional, defaults to false] redo time aligment regardless of wave note
Function TimeAlignmentIfReq(string graphtrace, variable mode, variable level, variable pos1x, variable pos2x, [variable force])

	if(ParamIsDefault(force))
		force = 0
	else
		force = !!force
	endif

	string str, refAxis, axis
	string trace, refTrace, graph, refGraph
	variable offset, refPos
	variable first, last, pos, numTraces, i, idx
	string sweepNo, pulseIndexStr, indexStr

	if(mode == TIME_ALIGNMENT_NONE) // nothing to do
		return NaN
	endif

	refGraph = StringFromList(0, graphtrace, "#")
	refTrace = StringFromList(1, graphtrace, "#")
	ASSERT(windowExists(refGraph), "Graph must exist")

	[first, last] = MinMax(pos1x, pos2x)

	sprintf str, "first=%g, last=%g", first, last
	DEBUGPRINT(str)

	// now determine the feature's time position
	// using the traces from the same axis as the reference trace
	refAxis = TUD_GetUserData(refGraph, refTrace, "YAXIS")
	WAVE/T graphtraces = GetAllSweepTraces(refGraph)
	refPos = NaN

	numTraces = DimSize(graphtraces, ROWS)
	MAKE/FREE/D/N=(numTraces) featurePos = NaN, sweepNumber = NaN
	MAKE/FREE/T/N=(numTraces) refIndex
	for(i = 0; i < numTraces; i += 1)
		graph = StringFromList(0, graphtraces[i], "#")
		trace = StringFromList(1, graphtraces[i], "#")
		axis  = TUD_GetUserData(graph, trace, "YAXIS")

		if(cmpstr(axis, refAxis) || cmpstr(graph, refGraph))
			continue
		endif

		WAVE wv = $TUD_GetUserData(graph, trace, "fullPath")

		pos = CalculateFeatureLoc(wv, mode, level, first, last)

		if(!IsFinite(pos))
			printf "The alignment of trace %s could not be performed, aborting\r", trace
			return NaN
		endif

		if(!cmpstr(refTrace, trace))
			refPos = pos
		endif

		featurePos[i] = pos
		sweepNo       = TUD_GetUserData(graph, trace, "sweepNumber")
		ASSERT(!isEmpty(sweepNo), "Sweep number is empty. Set \"sweepNumber\" userData entry for trace.")
		sweepNumber[i] = str2num(sweepNo)
		pulseIndexStr  = TUD_GetUserData(graph, trace, "pulseIndex")
		refIndex[i]    = sweepNo + ":" + pulseIndexStr
	endfor

	// now shift all traces from all sweeps according to their relative offsets
	// to the reference position
	for(i = 0; i < numTraces; i += 1)
		graph = StringFromList(0, graphtraces[i], "#")
		trace = StringFromList(1, graphtraces[i], "#")
		WAVE/Z wv = $TUD_GetUserData(graph, trace, "fullPath")
		ASSERT(WaveExists(wv), "Could not resolve trace to wave")

		if(GetNumberFromWaveNote(wv, NOTE_KEY_TIMEALIGN) == 1 && force == 0)
			continue
		endif

		sweepNo       = TUD_GetUserData(graph, trace, "sweepNumber")
		pulseIndexStr = TUD_GetUserData(graph, trace, "pulseIndex")
		indexStr      = sweepNo + ":" + pulseIndexStr
		idx           = GetRowIndex(refIndex, str = indexStr)

		if(IsNaN(idx))
			continue
		endif

		offset = -(refPos + featurePos[idx])
		DEBUGPRINT("trace", str = trace)
		DEBUGPRINT("old DimOffset", var = DimOffset(wv, ROWS))
		DEBUGPRINT("new DimOffset", var = DimOffset(wv, ROWS) + offset)
		SetScale/P x, DimOffset(wv, ROWS) + offset, DimDelta(wv, ROWS), wv
		SetNumberInWaveNote(wv, NOTE_KEY_TIMEALIGN_TOTAL_OFFSET, offset)
		SetNumberInWaveNote(wv, NOTE_KEY_TIMEALIGN, 1)
	endfor
End

/// @brief Equalize all vertical axes ranges so that they cover the same range
///
/// @param graph                       graph
/// @param ignoreAxesWithLevelCrossing [optional, defaults to false] ignore all vertical axis which
///                                    cross the given level in the visible range
/// @param level                       [optional, defaults to zero] level to be used for `ignoreAxesWithLevelCrossing=1`
/// @param rangePerClampMode           [optional, defaults to false] use separate Y ranges per clamp mode
Function EqualizeVerticalAxesRanges(string graph, [variable ignoreAxesWithLevelCrossing, variable level, variable rangePerClampMode])

	string axList, axis, trace
	variable i, j, numAxes, axisOrient, xRangeBegin, xRangeEnd
	variable beginY, endY, clampMode
	variable maxYRange, numTraces, range, refClampMode, err

	if(ParamIsDefault(ignoreAxesWithLevelCrossing))
		ignoreAxesWithLevelCrossing = 0
	else
		ignoreAxesWithLevelCrossing = !!ignoreAxesWithLevelCrossing
	endif

	if(ParamIsDefault(rangePerClampMode))
		rangePerClampMode = 0
	else
		rangePerClampMode = !!rangePerClampMode
	endif

	if(ParamIsDefault(level))
		level = 0
	else
		ASSERT(ignoreAxesWithLevelCrossing, "Optional argument level makes only sense if ignoreAxesWithLevelCrossing is enabled")
	endif

	AssertOnAndClearRTError()
	GetAxis/W=$graph/Q bottom; err = GetRTError(1) // see developer docu section Preventing Debugger Popup
	if(!V_Flag)
		xRangeBegin = V_min
		xRangeEnd   = V_max
	else
		xRangeBegin = NaN
		xRangeEnd   = NaN
	endif

	WAVE/Z/T traces = TUD_GetUserDataAsWave(graph, "traceName")

	if(!WaveExists(traces))
		return NaN
	endif

	numTraces = DimSize(traces, ROWS)
	axList    = AxisList(graph)
	numAxes   = ItemsInList(axList)

	Make/FREE/D/N=(NUM_CLAMP_MODES + 1) maxYRangeClampMode = 0
	Make/FREE/D/N=(numAxes) axisClampMode = NaN
	Make/FREE/D/N=(numAxes, 2) YValues = Inf

	SetDimLabel COLS, 0, minimum, YValues
	SetDimLabel COLS, 1, maximum, YValues

	YValues[][%minimum] = Inf
	YValues[][%maximum] = -Inf

	// collect the y ranges of the visible x range of all vertical axis
	// respecting ignoreAxesWithLevelCrossing
	for(i = 0; i < numAxes; i += 1)
		axis = StringFromList(i, axList)

		axisOrient = GetAxisOrientation(graph, axis)
		if(axisOrient != AXIS_ORIENTATION_LEFT && axisOrient != AXIS_ORIENTATION_RIGHT)
			continue
		endif

		refClampMode = NaN

		for(j = 0; j < numTraces; j += 1)
			trace = traces[j]
			if(cmpstr(axis, TUD_GetUserData(graph, trace, "YAXIS")))
				continue
			endif

			WAVE wv = $TUD_GetUserData(graph, trace, "fullPath")

			if(!IsFinite(xRangeBegin) || !IsFinite(xRangeEnd))
				xRangeBegin = leftx(wv)
				xRangeEnd   = rightx(wv)
			endif

			if(ignoreAxesWithLevelCrossing)
				FindLevel/Q/R=(xRangeBegin, xRangeEnd) wv, level
				if(!V_flag)
					continue
				endif
			endif

			clampMode = str2num(TUD_GetUserData(graph, trace, "clampMode"))

			if(!IsFinite(clampMode))
				// TTL data has NaN for the clamp mode, map that to something which
				// can be used as an index into maxYRangeClampMode.
				clampMode = NUM_CLAMP_MODES
			endif

			if(!IsFinite(refClampMode))
				refClampMode = clampMode
			else
				axisClampMode[i] = (refClampMode == clampMode) ? clampMode : -1
			endif

			WaveStats/M=2/Q/R=(xRangeBegin, xRangeEnd) wv
			YValues[i][%minimum] = min(V_min, YValues[i][%minimum])
			YValues[i][%maximum] = max(V_max, YValues[i][%maximum])

			range = abs(YValues[i][%maximum] - YValues[i][%minimum])
			if(range > maxYRange)
				maxYRange = range
			endif

			if(rangePerClampMode && range > maxYRangeClampMode[clampMode])
				maxYRangeClampMode[clampMode] = range
			endif
		endfor
	endfor

	if(maxYRange == 0) // too few traces
		return NaN
	endif

	// and now set vertical axis ranges to the maximum
	for(i = 0; i < numAxes; i += 1)
		axis = StringFromList(i, axList)

		axisOrient = GetAxisOrientation(graph, axis)
		if(axisOrient != AXIS_ORIENTATION_LEFT && axisOrient != AXIS_ORIENTATION_RIGHT)
			continue
		endif

		if(!IsFinite(YValues[i][%minimum]) || !IsFinite(YValues[i][%minimum]))
			continue
		endif

		beginY = YValues[i][%minimum]

		if(rangePerClampMode && axisClampMode[i] >= 0)
			endY = beginY + maxYRangeClampMode[axisClampMode[i]]
		else
			endY = beginY + maxYRange
		endif

		DebugPrint("Setting new axis ranges for:", str = axis)
		DebugPrint("beginY:", var = beginY)
		DebugPrint("endY:", var = endY)

		SetAxis/W=$graph $axis, beginY, endY
	endfor
End

Function UpdateSweepPlot(string win)

	if(BSP_IsDataBrowser(win))
		DB_UpdateSweepPlot(win)
	else
		SB_UpdateSweepPlot(win)
	endif
End

/// @brief update of panel elements and related displayed graphs in BSP
Function UpdateSettingsPanel(string win)

	string bsPanel

	bsPanel = BSP_GetPanel(win)

	TimeAlignUpdateControls(bsPanel)
	BSP_ScaleAxes(bsPanel)
End

Function/WAVE GetPlainSweepList(string win)

	if(BSP_IsDataBrowser(win))
		return DB_GetPlainSweepList(win)
	endif

	return SB_GetPlainSweepList(win)
End

/// @brief Return the graph user data as 2D text wave
///
/// Only returns infos for sweep traces without duplicates.
/// Duplicates are present with oodDAQ display mode.
/// @param[in] graph Name of graph
/// @param[in] addFilterKeys [optional, default = $""]  additional keys for filtering
/// @param[in] addFilterValues [optional, default = $""] additional values for filtering, must have same size as keys
Function/WAVE GetTraceInfos(string graph, [WAVE/T addFilterKeys, WAVE/T addFilterValues])

	if(TUD_GetTraceCount(graph) == 0)
		return $""
	endif

	ASSERT((ParamIsDefault(addFilterKeys) + ParamIsDefault(addFilterValues)) != 1, "Either both or no filter wave must be given.")

	Make/FREE/T keys = {"traceType", "occurence"}
	Make/FREE/T values = {"Sweep", "0"}

	if(!ParamIsDefault(addFilterKeys) && DimSize(addFilterKeys, ROWS) > 0)
		ASSERT(DimSize(addFilterKeys, ROWS) == DimSize(addFilterValues, ROWS), "key wave has different size as value wave")
		Concatenate/FREE/NP/T {addFilterKeys}, keys
		Concatenate/FREE/NP/T {addFilterValues}, values
	endif

	WAVE/Z matches = TUD_GetUserDataAsWave(graph, "fullPath", returnIndizes = 1, keys = keys, values = values)

	if(!WaveExists(matches))
		return $""
	endif

	WAVE/T graphUserData = GetGraphUserData(graph)

	Make/FREE/T/N=(DimSize(matches, ROWS), DimSize(graphUserData, COLS)) graphUserDataSelection
	CopyDimLabels graphUserData, graphUserDataSelection
	Multithread graphUserDataSelection[][] = graphUserData[matches[p]][q]

	SortColumns/A/DIML/KNDX={2, 3, 4, 5} sortWaves=graphUserDataSelection

	return graphUserDataSelection
End

/// @brief Remove the given sweep from the Databrowser/Sweepbrowser
///
/// Needs a manual call to PostPlotTransformations() afterwards.
///
/// @param win              graph
/// @param index            overlay sweeps listbox index
Function RemoveSweepFromGraph(string win, variable index)

	string device, graph, dataFolder, experiment
	string trace
	variable sweepNo, i, numTraces

	graph = GetMainWindow(win)

	if(!HasPanelLatestVersion(graph, DATA_SWEEP_BROWSER_PANEL_VERSION))
		DoAbortNow("Can not display data. The panel is too old to be usable. Please close it and open a new one.")
	endif

	if(!BSP_HasBoundDevice(graph))
		return NaN
	endif

	DEBUGPRINT("Removing sweep with index ", var = index)

	[sweepNo, experiment] = OVS_GetSweepAndExperiment(graph, index)

	WAVE/Z/T traces = TUD_GetUserDataAsWave(graph, "tracename", keys = {"traceType", "sweepNumber", "experiment"}, \
	                                        values = {"sweep", num2str(sweepNo), experiment})

	if(!WaveExists(traces))
		return NaN
	endif

	numTraces = DimSize(traces, ROWS)
	for(i = 0; i < numTraces; i += 1)
		trace = traces[i]

		RemoveFromGraph/W=$graph $trace
		TUD_RemoveUserData(graph, trace)
	endfor
End

/// @brief Add the given sweep to the Databrowser/Sweepbrowser
///
/// Needs a manual call to PostPlotTransformations() afterwards.
///
/// @param win   graph
/// @param index overlay sweeps listbox index
/// @param bdi [optional, default = n/a] BufferedDrawInfo structure, when given buffered draw is used.
Function AddSweepToGraph(string win, variable index, [STRUCT BufferedDrawInfo &bdi])

	if(!HasPanelLatestVersion(win, DATA_SWEEP_BROWSER_PANEL_VERSION))
		DoAbortNow("Can not display data. The panel is too old to be usable. Please close it and open a new one.")
	endif

	if(!BSP_HasBoundDevice(win))
		return NaN
	endif

	DEBUGPRINT("Adding sweep with index ", var = index)

	if(BSP_IsDataBrowser(win))
		if(ParamIsDefault(bdi))
			DB_AddSweepToGraph(win, index)
		else
			DB_AddSweepToGraph(win, index, bdi = bdi)
		endif
	else
		SB_AddSweepToGraph(win, index)
	endif
End

/// @brief Update the given sweep in the Databrowser/Sweepbrowser plot
///
/// Needs a manual call to PostPlotTransformations() afterwards.
///
/// @param win   graph
/// @param index overlay sweeps listbox index
Function UpdateSweepInGraph(string win, variable index)

	string graph

	graph = GetMainWindow(win)

	WAVE     axesProps   = GetAxesProperties(graph)
	WAVE/Z/T cursorInfos = GetCursorInfos(graph)

	RemoveSweepFromGraph(win, index)
	AddSweepToGraph(win, index)

	RestoreCursors(graph, cursorInfos)
	SetAxesProperties(graph, axesProps)
End

/// @brief Generic window hooks for storing the window
///        coordinates in the JSON settings file.
Function StoreWindowCoordinatesHook(STRUCT WMWinHookStruct &s)

	string win

	switch(s.eventCode)
		case EVENT_WINDOW_HOOK_SUBWINDOWKILL: // fallthrough
		case EVENT_WINDOW_HOOK_KILL:
			win = s.winName
			NVAR JSONid = $GetSettingsJSONid()
			PS_StoreWindowCoordinate(JSONid, win)
			break
		default:
			break
	endswitch

	return 0
End

/// @brief Export a graph to SVG format
///
/// Saves the graph as SVG to:
/// - Windows: Downloads folder (falls back to Documents if Downloads doesn't exist)
/// - Mac: Documents folder
/// @param winName Name of the window (graph) to export
Function ExportGraphToSVG(string winName)

	string savePath, fileName, fullPath, timeStamp, documentsPath, msg

	ASSERT(!IsEmpty(winName), "Window name must not be empty")
	ASSERT(WindowExists(winName), "Window does not exist: " + winName)

	// Get Documents folder path as fallback
#ifdef WINDOWS
	documentsPath = GetUserDocumentsFolderPath()
#else
	documentsPath = SpecialDirPath("Documents", 0, 0, 0)
#endif // WINDOWS
	ASSERT(!IsEmpty(documentsPath), "Could not determine Documents folder location")
	if(!FolderExists(documentsPath))
		CreateFolderOnDisk(documentsPath)
	endif
	ASSERT(FolderExists(documentsPath), "Documents folder does not exist and could not be created")

	savePath = documentsPath

#ifdef WINDOWS
	// On Windows, prefer Downloads folder over Documents
	string downloadsPath = GetUserDownloadsFolderPath()
	ASSERT(!IsEmpty(downloadsPath), "Could not determine Downloads folder location")
	if(!FolderExists(downloadsPath))
		CreateFolderOnDisk(downloadsPath)
	endif
	ASSERT(FolderExists(downloadsPath), "Downloads folder does not exist and could not be created")
	savePath = downloadsPath
#endif // WINDOWS

	// Generate file name from window name and timestamp
	timeStamp = GetISO8601TimeStamp(localTimeZone = 1)
	ASSERT(!IsEmpty(timeStamp), "Timestamp must not be empty")
	fileName = SanitizeFilename(winName + "_" + timeStamp) + ".svg"
	ASSERT(!IsEmpty(fileName), "File name must not be empty")
	fullPath = savePath + fileName

	// Save graph as SVG (E=-9 is SVG format)
	try
		SavePICT/O/E=-9/WIN=$winName as fullPath; AbortOnRTE
	catch
		msg = GetRTErrMessage()
		ClearRTError()
		FATAL_ERROR("Failed to save SVG file: " + fullPath + ", RTE: " + msg)
	endtry
End
