#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_UTILS_GUI
#endif

/// @file MIES_Utilities_GUI.ipf
/// @brief utility functions for GUI

Menu "GraphMarquee"
	"Horiz Expand (VisX)", /Q, HorizExpandWithVisX()
End

/// @brief Check if a given wave, or at least one wave from the dfr, is displayed on a graph
///
/// @return one if one is displayed, zero otherwise
Function IsWaveDisplayedOnGraph(win, [wv, dfr])
	string win
	WAVE/Z wv
	DFREF  dfr

	string traceList, trace, list
	variable numWaves, numTraces, i

	ASSERT(ParamIsDefault(wv) + ParamIsDefault(dfr) == 1, "Expected exactly one parameter of wv and dfr")

	if(!ParamIsDefault(wv))
		if(!WaveExists(wv))
			return 0
		endif

		MAKE/FREE/WAVE/N=1 candidates = wv
	else
		if(!DataFolderExistsDFR(dfr) || CountObjectsDFR(dfr, COUNTOBJECTS_WAVES) == 0)
			return 0
		endif

		WAVE/WAVE candidates = ListToWaveRefWave(GetListOfObjects(dfr, ".*", fullpath = 1))
		numWaves = DimSize(candidates, ROWS)
	endif

	traceList = TraceNameList(win, ";", 1)
	numTraces = ItemsInList(traceList)
	for(i = numTraces - 1; i >= 0; i -= 1)
		trace = StringFromList(i, traceList)
		WAVE traceWave = TraceNameToWaveRef(win, trace)

		if(GetRowIndex(candidates, refWave = traceWave) >= 0)
			return 1
		endif
	endfor

	return 0
End

/// @brief Kill all cursors in a given list of graphs
///
/// @param graphs     semicolon separated list of graph names
/// @param cursorName name of cursor as string
Function KillCursorInGraphs(graphs, cursorName)
	string graphs, cursorName

	string graph
	variable i, numGraphs

	ASSERT(strlen(cursorName) == 1, "Invalid Cursor Name.")
	ASSERT(char2num(cursorName) > 64 && char2num(cursorName) < 75, "Cursor name out of range.")

	numGraphs = ItemsInList(graphs)
	for(i = 0; i < numGraphs; i += 1)
		graph = StringFromList(i, graphs)
		if(!WindowExists(graph))
			continue
		endif
		Cursor/K/W=$graph $cursorName
	endfor
End

/// @brief Find the first match for a given cursor in a list of graph names
///
/// @param graphs     semicolon separated list of graph names
/// @param cursorName name of cursor as string
///
/// @return graph where cursor was found
Function/S FindCursorInGraphs(graphs, cursorName)
	string graphs, cursorName

	string graph, csr
	variable i, numGraphs

	ASSERT(strlen(cursorName) == 1, "Invalid Cursor Name.")
	ASSERT(char2num(cursorName) > 64 && char2num(cursorName) < 75, "Cursor name out of range.")

	numGraphs = ItemsInList(graphs)
	for(i = 0; i < numGraphs; i += 1)
		graph = StringFromList(i, graphs)
		if(!WindowExists(graph))
			continue
		endif
		csr = CsrInfo($cursorName, graph)
		if(!IsEmpty(csr))
			return graph
		endif
	endfor
End

/// @brief get the x value of the cursors A and B
///
/// @todo make this a generic cursor getter function and merge with
///       `cursors()` in @see SF_FormulaExecutor
///
/// @param[in]  graph where the cursor are
/// @param[out] csrAx Position of cursor A
/// @param[out] csrBx Position of cursor B
Function GetCursorXPositionAB(graph, csrAx, csrBx)
	string graph
	variable &csrAx, &csrBx

	string csrA, csrB

	ASSERT(WindowExists(graph), "Graph for given cursors does not exist.")

	csrA = CsrInfo(A, graph)
	csrB = CsrInfo(B, graph)

	if(isEmpty(csrA) || isEmpty(csrB))
		csrAx = -Inf
		csrBx = Inf
	else
		csrAx = xcsr(A, graph)
		csrBx = xcsr(B, graph)
	endif
End

///@brief Removes all annotations from the graph
Function RemoveAnnotationsFromGraph(graph)
	string graph

	DeleteAnnotations/W=$graph/A
End

/// @brief Return a unique trace name in the graph
///
/// Remember that it might be necessary to call `DoUpdate`
/// if you added possibly colliding trace names in the current
/// function run.
///
/// @param graph existing graph
/// @param baseName base name of the trace, must not be empty
Function/S UniqueTraceName(graph, baseName)
	string graph, baseName

	variable i = 1
	variable numTrials
	string trace, traceList

	ASSERT(windowExists(graph), "graph must exist")
	ASSERT(!isEmpty(baseName), "baseName must not be empty")

	traceList = TraceNameList(graph, ";", 0 + 1)
	// use an upper limit of trials to ease calculation
	numTrials = 2 * ItemsInList(traceList) + 1

	trace = baseName
	do
		if(WhichListItem(trace, traceList) == -1)
			return trace
		endif

		trace = baseName + "_" + num2str(i)
		i    += 1

	while(i < numTrials)

	ASSERT(0, "Could not find a trace name")
End

/// @brief Calculate the value for `mskip` of `ModifyGraph`
///
/// @param numPoints  number of points shown
/// @param numMarkers desired number of markers
Function GetMarkerSkip(numPoints, numMarkers)
	variable numPoints, numMarkers

	if(!IsFinite(numPoints) || !IsFinite(numMarkers))
		return 1
	endif

	return trunc(limit(numPoints / numMarkers, 1, 2^15 - 1))
End

/// @brief Kill all passed windows
///
/// Silently ignore errors.
Function KillWindows(list)
	string list

	variable numEntries, i

	numEntries = ItemsInList(list)
	for(i = 0; i < numEntries; i += 1)
		KillWindow/Z $StringFromList(i, list)
	endfor
End

/// @brief Return all axes with the given orientation
///
/// @param graph graph
/// @param axisOrientation One of @ref AxisOrientationConstants
Function/S GetAllAxesWithOrientation(graph, axisOrientation)
	string   graph
	variable axisOrientation

	string axList, axis
	string list = ""
	variable numAxes, i

	axList  = AxisList(graph)
	numAxes = ItemsInList(axList)

	for(i = 0; i < numAxes; i += 1)
		axis = StringFromList(i, axList)

		if(axisOrientation & GetAxisOrientation(graph, axis))
			list = AddListItem(axis, list, ";", Inf)
		endif
	endfor

	return list
End

/// @brief Polished version of `GetNumFromModifyStr` from `Readback ModifyStr.ipf`
///
/// @param info     string as returned by AxisInfo or TraceInfo
/// @param key      keyword
/// @param listChar empty, `{` or `(` depending on keyword style
/// @param item     return the given element from the extracted list
Function GetNumFromModifyStr(info, key, listChar, item)
	string   info
	string   key
	string   listChar
	variable item

	string list, escapedListChar, regexp

	escapedListChar = "\\Q" + listChar + "\\E"

	sprintf regexp, "(?i)\\b\\Q%s\\E\([^=]+\)=%s([^});]+)", key, escapedListChar

	SplitString/E=regexp info, list

	if(V_Flag < 1)
		return NaN
	endif

	if(item == 0)
		return str2num(list)
	else
		ASSERT(item >= 0 && item < ItemsInList(list, ","), "Invalid index")
		return str2num(StringFromList(item, list, ","))
	endif
End

/// @brief Return the list of axis sorted from highest
///        to lowest starting value of the `axisEnab` keyword.
///
/// `list` must be from one orientation, usually something returned by GetAllAxesWithOrientation()
Function/S SortAxisList(graph, list)
	string graph, list

	variable numAxes, i
	string axis

	numAxes = ItemsInList(list)

	if(numAxes < 2)
		return list
	endif

	Make/FREE/D/N=(numAxes) axisStart

	for(i = 0; i < numAxes; i += 1)
		axis         = StringFromList(i, list)
		axisStart[i] = GetNumFromModifyStr(AxisInfo(graph, axis), "axisEnab", "{", 0)
	endfor

	WAVE/T axisListWave = ListToTextWave(list, ";")

	Sort/R axisStart, axisListWave

	return TextWaveToList(axisListWave, ";")
End

Function GetPlotArea(win, s)
	string        win
	STRUCT RectD &s

	InitRectD(s)

	if(!WindowExists(win))
		return NaN
	endif

	GetWindow $win, psizeDC

	s.left   = V_left
	s.right  = V_right
	s.top    = V_top
	s.bottom = V_bottom
End

/// @brief Parse a color specification as used by ModifyGraph having an optionl
/// translucency part
Function [STRUCT RGBAColor result] ParseColorSpec(string str)

	string str1, str2, str3, str4

	SplitString/E="^[[:space:]]*\([[:space:]]*([[:digit:]]+)[[:space:]]*,[[:space:]]*([[:digit:]]+)[[:space:]]*,[[:space:]]*([[:digit:]]+)[[:space:]]*(?:,[[:space:]]*([[:digit:]]+))*[[:space:]]*\)$" str, str1, str2, str3, str4
	ASSERT(V_Flag == 3 || V_Flag == 4, "Invalid color spec")

	result.red   = str2num(str1)
	result.green = str2num(str2)
	result.blue  = str2num(str3)
	result.alpha = (V_Flag == 4) ? str2num(str4) : 655356
End

/// @brief If the layout of an panel was changed, this function calls the
///        ResizeControlsPanel module functions of the Igor Pro native package
///        to store the changed resize info. The originally intended way to do this
///        was through the Packages GUI, which is clunky for some workflows.
Function StoreCurrentPanelsResizeInfo(string panel)

	ASSERT(!IsEmpty(panel), "Panel name can not be empty.")

	ResizeControlsPanel#ResetListboxWaves()
	ResizeControlsPanel#SaveControlPositions(panel, 0)
End

/// @brief Return the CRC of the contents of the plain/formatted notebook
///
/// Takes into account formatting but ignores selection.
Function GetNotebookCRC(string win)

	string content

	content = WinRecreation(win, 1)

	// Filter out // lines which contain the selection
	content = GrepList(content, "//.*", 1, "\r")

	return StringCRC(0, content)
End

///@brief Format the 2D text wave into a string usable for a legend
Function/S FormatTextWaveForLegend(WAVE/T input)

	variable i, j, numRows, numCols, length
	variable spacing = 2
	string   str     = ""
	string line

	numRows = DimSize(input, ROWS)
	numCols = DimSize(input, COLS)

	// determine the maximum length of each column
	Make/FREE/N=(numRows, numCols) totalLength = strlen(input[p][q])

	MatrixOp/FREE maxColLength = maxCols(totalLength)^t

	for(i = 0; i < numRows; i += 1)
		line = ""

		for(j = 0; j < numCols; j += 1)
			length = maxColLength[j] - totalLength[i][j]

			if(j < numCols - 1)
				length += spacing
			endif

			line += input[i][j] + PadString("", length, 0x20) // space
		endfor

		str += line + "\r"
	endfor

	return RemoveEndingRegExp(str, "[[:space:]]*\\r+$")
End

/// @brief Checks if given lineStyle code is valid (as of Igor Pro 9)
///
/// @param lineStyleCode line style code value for a trace
/// @returns 1 if valid, 0 otherwise
Function IsValidTraceLineStyle(variable lineStyleCode)

	return IsFinite(lineStyleCode) && lineStyleCode >= 0 && lineStyleCode <= 17
End

/// @brief Checks if given trace display code is valid (as of Igor Pro 9)
///
/// @param traceDisplayCode line style code value for a trace
/// @returns 1 if valid, 0 otherwise
Function IsValidTraceDisplayMode(variable traceDisplayCode)

	return IsFinite(traceDisplayCode) && traceDisplayCode >= TRACE_DISPLAY_MODE_LINES && traceDisplayCode <= TRACE_DISPLAY_MODE_LAST_VALID
End

/// @brief Update the help and user data of a button used as info/copy button
Function UpdateInfoButtonHelp(string win, string ctrl, string content)

	string htmlStr = "<pre>" + content + "</pre>"

	Button $ctrl, win=$win, help={htmlStr}, userdata=content
End

/// @brief Custom graph marquee
///
/// Requires an existing marquee and a graph as current top window
Function HorizExpandWithVisX()

	string graph, axis, str
	variable numEntries, i, minimum, maximum, first, last

	graph = GetCurrentWindow()

	WAVE axesProps = GetAxesProperties(graph, orientation = AXIS_ORIENTATION_HORIZ, mode = AXIS_RANGE_INC_AUTOSCALED)
	numEntries = DimSize(axesProps, ROWS)
	for(i = 0; i < numEntries; i += 1)
		axis = GetDimLabel(axesProps, ROWS, i)

		[first, last] = GetMarqueeHelper(axis, kill = 0, doAssert = 0, horiz = 1)

		if(IsNan(first) && IsNaN(last))
			// no marquee on axis
			continue
		endif

		minimum = axesProps[i][%minimum]
		maximum = axesProps[i][%maximum]

		first = limit(first, minimum, maximum)
		last  = limit(last, minimum, maximum)

		if(first == last)
			// marquee lies completely outside the axis
			continue
		endif

		sprintf str, "graph=%s, axis=%s, left=%d, right=%d", graph, axis, first, last
		DEBUGPRINT(str)

		SetAxis/W=$graph $axis, first, last
		AutoscaleVertAxisVisXRange(graph)
	endfor

	GetMarquee/K/W=$graph
End

/// @brief Space the matching axis in an equal manner
///
/// @param graph           graph
/// @param axisRegExp      [optional, defaults to ".*"] regular expression matching the axes names
/// @param axisOffset      [optional, defaults to 0] offset of first axis in parts of total width
/// @param axisOrientation [optional, defaults to all] allows to apply equalization to all axis of one orientation
/// @param sortOrder       [optional, defaults to no sorting (NaN)] apply different sorting
///                        schemes to list of axes, see sortingOrder parameter of `SortList`
/// @param listForBegin    [optional, defaults to an empty list] list of axes to move to the front of the sorted axis list
/// @param listForEnd      [optional, defaults to an empty list] list of axes to move to the end of the sorted axis list
Function EquallySpaceAxis(graph, [axisRegExp, axisOffset, axisOrientation, sortOrder, listForBegin, listForEnd])
	string graph, axisRegExp, listForBegin, listForEnd
	variable axisOffset, axisOrientation, sortOrder

	variable numAxes, i
	string axes, axis, list
	string adaptedList = ""

	if(ParamIsDefault(axisRegExp))
		axisRegExp = ".*"
	endif

	if(ParamIsDefault(axisOrientation))
		list = AxisList(graph)
	else
		list = GetAllAxesWithOrientation(graph, axisOrientation)
	endif

	if(ParamIsDefault(axisOffset))
		axisOffset = 0
	else
		ASSERT(axisOffset >= 0 && axisOffset <= 1.0, "Invalid axis offset")
	endif

	axes    = GrepList(list, axisRegExp)
	numAxes = ItemsInList(axes)

	if(ParamIsDefault(listForEnd))
		listForEnd = ""
	else
		listForEnd = RemoveEnding(listForEnd, ";")
	endif

	if(ParamIsDefault(listForBegin))
		listForBegin = ""
	else
		listForBegin = RemoveEnding(listForBegin, ";")
	endif

	if(ParamIsDefault(sortOrder) || !IsFinite(sortOrder))
		list = SortAxisList(graph, list)
	else
		axes         = SortList(axes, ";", sortOrder)
		listForEnd   = SortList(listForEnd, ";", sortOrder)
		listForBegin = SortList(listForBegin, ";", sortOrder)
	endif

	if(!IsEmpty(listForBegin) || !IsEmpty(listForEnd))
		for(i = 0; i < numAxes; i += 1)
			axis = StringFromList(i, axes)

			if(WhichListItem(axis, listForBegin) == -1 && WhichListItem(axis, listForEnd) == -1)
				adaptedList = AddListItem(axis, adaptedList, ";", Inf)
			endif
		endfor

		// adaptedList now holds all axes which are neither in listForBegin nor listForEnd
		if(!IsEmpty(listForBegin))
			adaptedList = AddListItem(listForBegin, adaptedList, ";", 0)
		endif

		if(!IsEmpty(listForEnd))
			adaptedList = AddListItem(listForEnd, adaptedList, ";", Inf)
		endif
	else
		adaptedList = axes
	endif

	if(numAxes > 0)
		[WAVE axisStart, WAVE axisEnd] = DistributeElements(numAxes, offset = axisOffset)

		numAxes = ItemsInList(adaptedList)
		for(i = 0; i < numAxes; i += 1)
			axis = StringFromList(i, adaptedList)
			ModifyGraph/Z/W=$graph axisEnab($axis)={axisStart[i], axisEnd[i]}
		endfor
	endif
End

/// @brief This is a light weight adapted version of @sa EquallySpaceAxis
///        It allows to give a list of distAxes that do not require to exist.
///        Non-existing axes are taken into account on the distribution, but are skipped when the graph is accessed.
///        Also removing images from a graph does not update AxisList until the graph is updated,
///        so we can not rely on Axislist here as we do the Layout after pending changes
///        So with allAxes = "1;2;3;4;" and distAxes = "2;3;" axis 2 and 3 are set at 25% to 50% and 50% to 75% respectively.
/// @param[in] graph Name of graph where axes from distAxes list exist
/// @param[in] allAxes List of all axes, that should be distributed. May include non-existing axes.
/// @param[in] distAxes List of axes that are distributed. Only axes that appear in allAxes as well are modified.
/// @param[in] axisOffset [optional, default = 0] offset between 0 and 1 where distribution starts.
Function EquallySpaceAxisPA(string graph, string allAxes, string distAxes, [variable axisOffset])

	variable numAxes, i
	string axis

	if(ParamIsDefault(axisOffset))
		axisOffset = 0
	else
		ASSERT(axisOffset >= 0 && axisOffset <= 1.0, "Invalid axis offset")
	endif

	numAxes = ItemsInList(distAxes)
	if(numAxes > 0)
		[WAVE axisStart, WAVE axisEnd] = DistributeElements(numAxes, offset = axisOffset)
		for(i = 0; i < numAxes; i += 1)
			axis = StringFromList(i, distAxes)
			if(WhichListItem(axis, allAxes) != -1)
				ModifyGraph/Z/W=$graph axisEnab($axis)={axisStart[i], axisEnd[i]}
			endif
		endfor
	endif
End

/// @brief Remove all free axis from the given graph
Function RemoveFreeAxisFromGraph(graph)
	string graph

	string list, name, info
	variable i, numEntries

	list       = AxisList(graph)
	numEntries = ItemsInList(list)

	for(i = 0; i < numEntries; i += 1)
		name = StringFromList(i, list)
		info = AxisInfo(graph, name)

		if(!NumberByKey("ISTFREE", info))
			continue
		endif

		KillFreeAxis/W=$graph $name
	endfor
End

/// @brief Remove all draw layers from the graph
Function RemoveDrawLayers(string graph)
	variable i, numLayers

	Make/FREE/T layers = {"ProgBack", "UserBack", "ProgAxes", "UserAxes", "ProgFront", "UserFront", "Overlay"}
	ASSERT(WinType(graph) == 1, "Only works for graphs")

	numLayers = DimSize(layers, ROWS)
	for(i = 0; i < numLayers; i += 1)
		SetDrawLayer/W=$graph/K $layers[i]
	endfor
End

/// @brief Remove traces from a graph
///
/// @param graph                            graph
/// @param trace [optional, default: all]   remove the given trace only
/// @param wv [optional, default: ignored]  remove all traces which stem from the given wave
/// @param dfr [optional, default: ignored] remove all traces which stem from one of the waves in dfr
///
/// Only one of trace/wv/dfr may be supplied.
Function RemoveTracesFromGraph(graph, [trace, wv, dfr])
	string graph
	string trace
	WAVE/Z wv
	DFREF  dfr

	variable i, numEntries, numOptArgs, remove_all_traces, err
	string traceList, refTrace

	numOptArgs = ParamIsDefault(trace) + ParamIsDefault(wv) + ParamIsDefault(dfr)
	ASSERT(numOptArgs == 3 || numOptArgs == 2, "Can only accept one of the trace/wv/dfr parameters")

	if(!ParamIsDefault(wv) && !WaveExists(wv) || !ParamIsDefault(dfr) && !DataFolderExistsDFR(dfr))
		return 0
	endif

	if(!ParamIsDefault(dfr))
		WAVE/WAVE candidates = ListToWaveRefWave(GetListOfObjects(dfr, ".*", fullpath = 1))
	endif

	remove_all_traces = ParamIsDefault(trace) && ParamIsDefault(wv) && ParamIsDefault(dfr)

	// remove without calling TraceNameList or TraceNameToWaveRef
	if(remove_all_traces)
		RemoveFromGraph/ALL/W=$graph
		return NaN
	endif

	traceList  = TraceNameList(graph, ";", 1)
	numEntries = ItemsInList(traceList)

	// iterating backwards is required, see http://www.igorexchange.com/node/1677#comment-2315
	for(i = numEntries - 1; i >= 0; i -= 1)
		refTrace = StringFromList(i, traceList)

		WAVE/Z refWave = TraceNameToWaveRef(graph, refTrace)

		if(remove_all_traces)
			RemoveFromGraph/W=$graph $refTrace
		elseif(!ParamIsDefault(trace))
			if(!cmpstr(refTrace, trace))
				RemoveFromGraph/W=$graph $refTrace
			endif
		elseif(!ParamIsDefault(wv))
			if(WaveRefsEqual(refWave, wv))
				RemoveFromGraph/W=$graph $refTrace
			endif
		elseif(!ParamIsDefault(dfr))
			if(GetRowIndex(candidates, refWave = refWave) >= 0)
				RemoveFromGraph/W=$graph $refTrace
			endif
		endif

	endfor

	return NaN
End

/// @brief Add user data "panelVersion" to the panel
Function AddVersionToPanel(win, version)
	string   win
	variable version

	SetWindow $win, userData(panelVersion)=num2str(version)
End

/// @brief Return 1 if the panel is up to date, zero otherwise
Function HasPanelLatestVersion(win, expectedVersion)
	string   win
	variable expectedVersion

	variable version

#ifdef EVIL_KITTEN_EATING_MODE
	return 1
#endif

	version = GetPanelVersion(GetMainWindow(win))

	return version == expectedVersion
End

/// @brief Get the user data "panelVersion"
///
/// @param win panel window as string
/// @returns numeric panel version greater 0 and -1 if no version is present
///          or -2 if the windows does not exist
Function GetPanelVersion(win)
	string win

	variable version

	if(!WindowExists(win))
		return -2
	endif

	version = str2numSafe(GetUserData(win, "", "panelVersion"))
	version = abs(version)

	if(IsNaN(version))
		return -1
	endif

	return version
End

///@brief Places paired checkboxes in opposite state
///
/// @param win     window name
/// @param checkBoxIn	ctrl checkbox ex. cba.ctrlName
/// @param checkBoxPartner	checkbox that will be placed in opposite state
/// @param checkBoxInState	state of the ctrl checkbox
Function ToggleCheckBoxes(win, checkBoxIn, checkBoxPartner, checkBoxInState)
	string   win
	string   checkBoxIn
	string   checkBoxPartner
	variable checkBoxInState

	SetCheckBoxState(win, checkBoxIn, checkBoxInState)
	DAG_Update(win, checkBoxIn, val = checkBoxInState)
	SetCheckBoxState(win, checkBoxPartner, !checkBoxInState)
	DAG_Update(win, checkBoxPartner, val = !checkBoxInState)
End

///@brief Placed paired checkboxes in same state
///
/// @param win     window name
/// @param checkBoxIn	ctrl checkbox ex. cba.ctrlName
/// @param checkBoxPartner	checkbox that will be placed in the same state
/// @param checkBoxInState	state of the ctrl checkbox
Function EqualizeCheckBoxes(win, checkBoxIn, checkBoxPartner, checkBoxInState)
	string   win
	string   checkBoxIn
	string   checkBoxPartner
	variable checkBoxInState

	SetCheckBoxState(win, checkBoxIn, checkBoxInState)
	DAG_Update(win, checkBoxIn, val = checkBoxInState)

	SetCheckBoxState(win, checkBoxPartner, checkBoxInState)
	DAG_Update(win, checkBoxPartner, val = checkBoxInState)
End

Function RemoveAllControls(string win)

	string control

	WAVE/T controls = ListToTextWave(ControlNameList(win), ";")
	for(control : controls)
		KillControl/W=$win $control
	endfor
End

Function RemoveAllDrawLayers(string win)

	SetDrawLayer/W=$win/K ProgBack
	SetDrawLayer/W=$win/K UserBack
	SetDrawLayer/W=$win/K ProgFront
	SetDrawLayer/W=$win/K UserFront
	SetDrawLayer/W=$win/K Overlay

	if(WinType(win) == WINTYPE_GRAPH)
		SetDrawLayer/W=$win/K ProgAxes
		SetDrawLayer/W=$win/K UserAxes
	endif
End
