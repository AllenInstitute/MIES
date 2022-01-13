#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_LBV
#endif

/// @file MIES_LogbookViewer.ipf
/// @brief __LBV__ Panel for browsing the labnotebook and TPStorage waves

static StrConstant LABNOTEBOOK_BOTTOM_AXIS_DELTA_TIME  = "Relative time [s]"
static StrConstant LABNOTEBOOK_BOTTOM_AXIS_TIME  = "Timestamp (a. u.)"
static StrConstant LABNOTEBOOK_BOTTOM_AXIS_SWEEP = "Sweep Number (a. u.)"

StrConstant LBV_UD_SOURCE_WAVE = "sourceWave"
StrConstant LBV_UD_HEADSTAGE   = "headstage"
StrConstant LBV_UD_KEY         = "key"
StrConstant LBV_UD_ISTEXT      = "text"

Function/S LBV_GetSettingsHistoryPanel(string win)

	return GetMainWindow(win) + "#" + EXT_PANEL_SETTINGSHISTORY
End

Function/S LBV_GetLabNoteBookGraph(string win)

	return LBV_GetSettingsHistoryPanel(win) + "#Labnotebook"
End

static Function/WAVE LBV_PopupExtFormatEntries(WAVE/T/Z entries)
	WAVE/T/Z splittedMenu = PEXT_SplitToSubMenus(entries, method = PEXT_SUBSPLIT_ALPHA)

	PEXT_GenerateSubMenuNames(splittedMenu)

	return splittedMenu
End

/// @brief Returns the list of TPStorage keys
Function/WAVE LBV_PopupExtGetTPStorageKeys(string win)
	DFREF dfr = LBV_GetTPStorageLocation(win)

	if(!DataFolderExistsDFR(dfr))
		return $""
	endif

	WAVE/Z entries = LBV_GetTPStorageEntries(dfr)

	return LBV_PopupExtFormatEntries(entries)
End

/// @brief Returns the list of LNB keys for the settings history window menu
Function/WAVE LBV_PopupExtGetLBKeys(string win)

	WAVE/T/Z textualKeys   = BSP_GetLogbookWave(win, LBT_LABNOTEBOOK, LBN_TEXTUAL_KEYS, selectedExpDevice = 1)
	WAVE/T/Z numericalKeys = BSP_GetLogbookWave(win, LBT_LABNOTEBOOK, LBN_NUMERICAL_KEYS, selectedExpDevice = 1)

	WAVE/Z entries = LBV_GetAllLogbookKeys(win, textualKeys, numericalKeys)

	return LBV_PopupExtFormatEntries(entries)
End

/// @brief Returns the list of results keys for the settings history window menu
Function/WAVE LBV_PopupExtGetResultsKeys(string win)

	WAVE/T/Z textualKeys   = BSP_GetLogbookWave(win, LBT_RESULTS, LBN_TEXTUAL_KEYS, selectedExpDevice = 1)
	WAVE/T/Z numericalKeys = BSP_GetLogbookWave(win, LBT_RESULTS, LBN_NUMERICAL_KEYS, selectedExpDevice = 1)

	WAVE/Z entries = LBV_GetAllLogbookKeys(win, textualKeys, numericalKeys)

	return LBV_PopupExtFormatEntries(entries)
End

/// @brief Returns the combined keys from the numerical and textual MD key loogbook waves as 1D text wave
static Function/WAVE LBV_GetAllLogbookKeys(string win, WAVE/T textualKeys, WAVE/T numericalKeys)
	variable existText, existNum

	WAVE/Z/T textualKeys1D = LBV_GetLogbookKeys(textualKeys)
	WAVE/Z/T numericalKeys1D = LBV_GetLogbookKeys(numericalKeys)

	existText = WaveExists(textualKeys1D)
	existNum = WaveExists(numericalKeys1D)
	if(existText && existNum)
		return GetSetUnion(textualKeys1D, numericalKeys1D)
	elseif(existText && !existNum)
		return textualKeys1D
	elseif(!existText && existNum)
		return numericalKeys1D
	endif

	return $""
End

/// @brief Return a wave with all keys in the logbook key wave
static Function/WAVE LBV_GetLogbookKeys(WAVE/Z/T keyWave)
	variable row

	if(!WaveExists(keyWave))
		return $""
	endif

	row = FindDimLabel(keyWave, ROWS, "Parameter")

	Duplicate/FREE/RMD=[row][] keyWave, keys
	Redimension/N=(numpnts(keys))/E=1 keys

	WAVE/T hiddenDefaultKeys = ListToTextWave(LABNOTEBOOK_KEYS_INITIAL, ";")

	return GetSetDifference(keys, hiddenDefaultKeys)
End

/// @brief Return a text wave with all entries from all TPStorage waves which are candidates for plotting
Function/WAVE LBV_GetTPStorageEntries(DFREF dfr)
	variable i, numEntries
	string list

	list = GetListOfObjects(dfr, TP_STORAGE_REGEXP, fullPath = 1)
	WAVE/Z allEntries

	numEntries = ItemsInList(list)
	for(i = 0; i < numEntries; i += 1)
		WAVE wv = $StringFromList(i, list)

		Make/FREE/T/N=(DimSize(wv, LAYERS)) entries = GetDimLabel(wv, LAYERS, p)
		WAVE/Z cleanEntries = GrepTextWave(entries, ".*(Time|Slope).*", invert = 1)

		if(!WaveExists(allEntries))
			WAVE/Z allEntries = cleanEntries
		else
			WAVE/Z tmp = GetSetIntersection(cleanEntries, allEntries)
			WAVE/Z allEntries = tmp
		endif
	endfor

	return allEntries
End

/// @brief Return the datafolder reference where TPStorage waves can be found.
static Function/DF LBV_GetTPStorageLocation(string win)
	string shPanel, device, dataFolder

	if(BSP_IsDataBrowser(win))
		if(!BSP_HasBoundDevice(win))
			return $""
		endif

		device = BSP_GetDevice(win)
		return GetDeviceTestPulse(device)
	endif

	shPanel = LBV_GetSettingsHistoryPanel(win)
	dataFolder = GetPopupMenuString(shPanel, "popup_experiment")

	device = GetPopupMenuString(shPanel, "popup_Device")

	if(!cmpstr(dataFolder, NONE))
		return $""
	endif

	return GetAnalysisDeviceTestpulse(dataFolder, device)
End

/// @brief panel close hook for settings history panel
Function LBV_CloseSettingsHistoryHook(STRUCT WMWinHookStruct &s)
	string mainPanel, shPanel

	switch(s.eventCode)
		case 17: // killVote
			mainPanel = GetMainWindow(s.winName)

			if(!BSP_IsDataBrowser(mainPanel))
				return 0
			endif

			shPanel = LBV_GetSettingsHistoryPanel(mainPanel)

			ASSERT(!cmpstr(s.winName, shPanel), "This hook is only available for Setting History Panel.")

			SetWindow $s.winName hide=1

			BSP_MainPanelButtonToggle(mainPanel, 1)

			return 2 // don't kill window
	endswitch

	return 0
End

Function LBV_ButtonProc_AutoScale(STRUCT WMButtonAction &ba) : ButtonControl
	string win, lbGraph

	switch(ba.eventcode)
		case 2: // mouse up
			win     = ba.win
			lbGraph = LBV_GetLabNotebookGraph(win)

			if(WindowExists(lbGraph))
				SetAxis/A=2/W=$lbGraph
			endif
			break
	endswitch

	return 0
End

Function LBV_ButtonProc_ClearGraph(STRUCT WMButtonAction &ba) : ButtonControl

	switch(ba.eventCode)
		case 2: // mouse up
			LBV_ClearGraph(ba.win)
			break
	endswitch

	return 0
End

Function LBV_ButtonProc_SwitchXAxis(STRUCT WMButtonAction &ba) : ButtonControl
	string lbGraph

	switch(ba.eventCode)
		case 2: // mouse up
			lbGraph = LBV_GetLabNoteBookGraph(ba.win)
			LBV_SwitchLBGraphXAxis(lbGraph)
			break
	endswitch

	return 0
End

Function LBV_PopMenuProc_LabNotebookAndResults(STRUCT WMPopupAction &pa) : PopupMenuControl
	string key, win, lbGraph

	switch(pa.eventCode)
		case 2: // mouse up
			win = pa.win
			key = pa.popStr

			if(!CmpStr(key, NONE))
				break
			endif

			WAVE/Z keys, values
			[keys, values] = LBV_GetLogbookWavesForEntry(win, key)

			lbGraph = LBV_GetLabNoteBookGraph(win)
			LBV_AddTraceToLBGraph(lbGraph, keys, values, key)
		break
	endswitch

	return 0
End

/// @brief Return the keys/values logbook pair for the given key
///
/// @return valid waves or null if it can not be found.
Function [WAVE keys, WAVE values] LBV_GetLogbookWavesForEntry(string win, string key)

	variable col

	WAVE/Z numericalKeys = BSP_GetLogbookWave(win, LBT_LABNOTEBOOK, LBN_NUMERICAL_KEYS, selectedExpDevice = 1)
	ASSERT(WaveExists(numericalKeys), "Numerical LabNotebook Keys not found.")
	WAVE/Z numericalValues = BSP_GetLogbookWave(win, LBT_LABNOTEBOOK, LBN_NUMERICAL_VALUES, selectedExpDevice = 1)
	ASSERT(WaveExists(numericalValues), "Numerical LabNotebook not found.")

	col = FindDimLabel(numericalValues, COLS, key)
	if(col >= 0)
		return [numericalKeys, numericalValues]
	endif

	WAVE/Z textualKeys = BSP_GetLogbookWave(win, LBT_LABNOTEBOOK, LBN_TEXTUAL_KEYS, selectedExpDevice = 1)
	ASSERT(WaveExists(textualKeys), "Textual LabNotebook keys not found.")
	WAVE/Z textualValues = BSP_GetLogbookWave(win, LBT_LABNOTEBOOK, LBN_TEXTUAL_VALUES, selectedExpDevice = 1)
	ASSERT(WaveExists(textualValues), "Textual LabNotebook not found.")

	col = FindDimLabel(textualValues, COLS, key)
	if(col >= 0)
		return [textualKeys, textualValues]
	endif

	WAVE/Z numericalResultsKeys   = BSP_GetLogbookWave(win, LBT_RESULTS, LBN_NUMERICAL_KEYS, selectedExpDevice = 1)
	WAVE/Z numericalResultsValues = BSP_GetLogbookWave(win, LBT_RESULTS, LBN_NUMERICAL_VALUES, selectedExpDevice = 1)

	col = WaveExists(numericalResultsKeys) ? FindDimLabel(numericalResultsKeys, COLS, key) : -1
	if(col >= 0)
		ASSERT(WaveExists(numericalResultsValues), "Missing wave")
		return [numericalResultsKeys, numericalResultsValues]
	endif

	WAVE/Z textualResultsKeys   = BSP_GetLogbookWave(win, LBT_RESULTS, LBN_TEXTUAL_KEYS, selectedExpDevice = 1)
	WAVE/Z textualResultsValues = BSP_GetLogbookWave(win, LBT_RESULTS, LBN_TEXTUAL_VALUES, selectedExpDevice = 1)

	col = WaveExists(textualResultsKeys) ? FindDimLabel(textualResultsKeys, COLS, key) : -1
	if(col >= 0)
		ASSERT(WaveExists(textualResultsValues), "Missing wave")
		return [textualResultsKeys, textualResultsValues]
	endif

	return [$"", $""]
End

Function LBV_PopMenuProc_TPStorage(STRUCT WMPopupAction &pa) : PopupMenuControl
	string lbGraph, key, win

	switch(pa.eventCode)
		case 2: // mouse up
			win = pa.win
			lbGraph = LBV_GetLabNoteBookGraph(win)
			key  = pa.popStr

			if(!CmpStr(key, NONE))
				break
			endif

			DFREF dfr = LBV_GetTPStorageLocation(win)
			LBV_AddTraceToLBGraphTPStorage(lbGraph, dfr, key)
		break
	endswitch

	return 0
End

Function/S LBV_GetExperiments(string win)

	if(BSP_IsDataBrowser(win))
		return NONE + ";" + GetExperimentName()
	else
		return NONE + ";" + SB_GetListOfExperiments(win)
	endif
End

Function/S LBV_GetAllDevicesForExperiment(string win)
	string dataFolder, shPanel
	variable index

	if(BSP_IsDataBrowser(win))
		if(BSP_HasBoundDevice(win))
			return NONE + ";" + BSP_GetDevice(win)
		else
			return NONE
		endif
	else
		shPanel = LBV_GetSettingsHistoryPanel(win)
		dataFolder = GetPopupMenuString(shPanel, "popup_experiment")

		if(!cmpstr(dataFolder, NONE))
			return NONE
		endif

		WAVE devices = GetAnalysisDeviceWave(dataFolder)

		index = GetNumberFromWaveNote(devices, NOTE_INDEX)

		if(index == 0)
			return NONE
		endif

		Duplicate/FREE/RMD=[0, index - 1] devices, devicesClean

		return NONE + ";" + TextWaveToList(devicesClean, ";")
	endif
End

Function LBV_ClearGraph(string win)

	string graph = LBV_GetLabNoteBookGraph(win)
	if(!WindowExists(graph))
		return 0
	endif

	RemoveTracesFromGraph(graph)
	RemoveFreeAxisFromGraph(graph)
	RemoveDrawLayers(graph)
	LBV_UpdateLBGraphLegend(graph)
	TUD_Clear(graph)
End

/// @brief Update the legend in the labnotebook graph
///
/// Passing traceList is required if you just added traces
/// to the graph as these can not be immediately queried using
/// `TraceNameList` as that would require an `DoUpdate` call before.
///
/// Assumes that the traceList displays information from the labnotebook. All entries
/// with indizes equal or higher than #NUM_HEADSTAGES will be labeled as `all` denoting that
/// the information is headstage independent and therefore valid for all headstages.
///
/// @param graph       name of the graph
/// @param traceList   list of traces in the graph
static Function LBV_UpdateLBGraphLegend(string graph, [string traceList])
	string str, trace, header, prefix
	variable numEntries, i, headstage

	if(!windowExists(graph))
		return NaN
	endif

	if(FindListItem("text0", AnnotationList(graph)) == -1)
		return NaN
	endif

	if(ParamIsDefault(traceList) || ItemsInList(traceList) == 0)
		TextBox/C/W=$graph/N=text0/F=0 ""
		return NaN
	endif

	Make/FREE/N=(NUM_HEADSTAGES) hsMarker = 0

	header = "\\JCHeadstage\r"
	str = ""

	numEntries = ItemsInList(traceList)
	for(i = 0 ; i < numEntries; i += 1)
		trace = StringFromList(i, traceList)

		if(str2num(TUD_GetUserData(graph, trace, LBV_UD_ISTEXT)))
			continue
		endif

		prefix = "\\s(" + PossiblyQuoteName(trace) + ") "

		headstage = str2num(TUD_GetUserData(graph, trace, LBV_UD_HEADSTAGE))

		if(IsFinite(headstage))
			if(hsMarker[headstage])
				continue
			endif

			hsMarker[headstage] = 1
			str += prefix + num2str(headstage)
		else
			str += prefix + "all"
		endif

		if(mod(i, 2))
			str += "\r"
		endif
	endfor

	if(IsEmpty(str))
		return NaN
	endif

	str = RemoveEnding(header + str, "\r")
	TextBox/C/W=$graph/N=text0/F=2 str
End

static Function/WAVE LBV_GetTraceUserDataNames()
	Make/FREE/T wv = {LBV_UD_KEY, LBV_UD_ISTEXT, LBV_UD_SOURCE_WAVE, LBV_UD_HEADSTAGE}

	return wv
End

static Function/S LBV_MakeTraceNameUnique(string graph, string trace)

	if(!TUD_TraceIsOnGraph(graph, trace))
		return trace
	endif

	return UniqueTraceName(graph, trace)
End

/// @brief Add a trace to the labnotebook graph
///
/// @param graph  name of the graph
/// @param keys   labnotebook keys wave (numerical or text)
/// @param values labnotebook values wave (numerical or text)
/// @param key    name of the key to add
static Function LBV_AddTraceToLBGraph(string graph, WAVE keys, WAVE values, string key)
	string unit, lbl, axis, trace, text, tagString, tmp, axisBaseName
	string traceList = ""
	variable i, j, row, col, numRows, sweepCol, marker
	variable isTimeAxis, isTextData, xPos, logbookType
	STRUCT RGBColor s

	WAVE/T/Z traces
	[traces, lbl, unit, col] = LBV_GetPropertiesForLabnotebookEntry(keys, key)

	if(!WaveExists(traces))
		return NaN
	endif

	logbookType = GetLogbookType(keys)

	WAVE valuesDat = ExtractLogbookSliceTimeStamp(values)

	isTimeAxis = LBV_CheckIfXAxisIsTime(graph)
	isTextData = IsTextWave(values)
	sweepCol   = GetSweepColumn(values)

	switch(logbookType)
		case LBT_LABNOTEBOOK:
			axisBaseName = "lbn_" + VERT_AXIS_BASE_NAME
			break
		case LBT_RESULTS:
			axisBaseName = "results_" + VERT_AXIS_BASE_NAME
			break
		default:
			ASSERT(0, "Unexpected logbook type")
	endswitch

	axis = GetNextFreeAxisName(graph, axisBaseName)

	if(IsTextData)
		WAVE valuesNull  = ExtractLogbookSliceEmpty(values)
		WAVE valuesSweep = ExtractLogbookSliceSweep(values)
	endif

	WAVE userDataKeys = LBV_GetTraceUserDataNames()

	for(i = 0; i < LABNOTEBOOK_LAYER_COUNT; i += 1)
		trace = LBV_MakeTraceNameUnique(graph, traces[i])
		traceList = AddListItem(trace, traceList, ";", inf)

		if(isTextData)
			if(isTimeAxis)
				AppendToGraph/W=$graph/L=$axis valuesNull/TN=$trace vs valuesDat
			else
				AppendToGraph/W=$graph/L=$axis valuesNull/TN=$trace vs valuesSweep
			endif

			ModifyGraph/W=$graph nticks($axis)=0, axRGB($axis)=(65535,65535,65535)
		else
			if(isTimeAxis)
				AppendToGraph/W=$graph/L=$axis values[][col][i]/TN=$trace vs valuesDat
			else
				AppendToGraph/W=$graph/L=$axis values[][col][i]/TN=$trace vs values[][sweepCol][0]
			endif
		endif

		TUD_SetUserDataFromWaves(graph,                                  \
								 trace,                                  \
								 userDataKeys,                           \
								 {key,                                   \
								  num2str(isTextData),                   \
								  GetWavesDataFolder(values, 2),         \
								  num2str(i < NUM_HEADSTAGES ? i : NaN ) \
								 })

		[s] = GetHeadstageColor(i)
		marker = i == 0 ? 39 : i
		ModifyGraph/W=$graph rgb($trace)=(s.red, s.green, s.blue, IsTextData ? 0 : inf), marker($trace)=marker
		SetAxis/W=$graph/A=2 $axis

		// we only need one trace, all the info is in the tag
		if(isTextData)
			break
		endif
	endfor

	if(isTextData)
		WAVE/T valuesText = values
		LBV_AddTagsForTextualLBNEntries(graph, keys, valuesText, key)
	endif

	if(!isEmpty(unit))
		lbl += "\r(" + unit + ")"
	endif

	Label/W=$graph $axis lbl

	ModifyGraph/W=$graph lblPosMode = 1, standoff($axis) = 0, freePos($axis) = 0
	ModifyGraph/W=$graph mode = 3
	ModifyGraph/W=$graph nticks(bottom) = 10, manTick(bottom) = {0,1,0,0}, manMinor(bottom) = {0,50}

	if(!cmpstr(unit, LABNOTEBOOK_BINARY_UNIT))
		ModifyGraph/W=$graph manTick($axis)={0,1,0,0}, manMinor($axis)={0,50}, zapTZ($axis)=1
	endif

	LBV_SetLabNotebookBottomLabel(graph, isTimeAxis)
	EquallySpaceAxis(graph, axisRegExp= ".*" + VERT_AXIS_BASE_NAME + ".*", sortOrder = 16)
	LBV_UpdateLBGraphLegend(graph, traceList=traceList)
End

Function LBV_UpdateTagsForTextualLBNEntries(string win, variable sweepNo)
	string lbGraph, traceList, key, trace
	variable i, numTraces

	lbGraph = LBV_GetLabNotebookGraph(win)

	traceList = TraceNameList(lbGraph, ";", 0 + 1)
	numTraces = ItemsInList(traceList)

	if(!numTraces)
		return NaN
	endif

	WAVE textualValues = DB_GetLBNWave(win, LBN_TEXTUAL_VALUES)
	WAVE textualKeys   = DB_GetLBNWave(win, LBN_TEXTUAL_KEYS)

	for(i = 0; i < numTraces; i += 1)
		trace = StringFromList(i, traceList)

		if(!str2num(TUD_GetUserData(lbGraph, trace, LBV_UD_ISTEXT)))
			continue
		endif

		key = TUD_GetUserData(lbGraph, trace, LBV_UD_KEY)
		ASSERT(!IsEmpty(key), "Missing key")
		LBV_AddTagsForTextualLBNEntries(lbGraph, textualKeys, textualValues, key, firstSweep = sweepNo)
	endfor
End

static Function LBV_AddTraceToLBGraphTPStorage(string graph, DFREF dfr, string key, [variable isTimeAxis])
	string lbl, axis, trace, text, tagString, tmp, list, lblTemplate
	string traceList, suffix, axisBasename
	variable i, j, row, numRows, sweepCol, marker, numEntries, headstage, numCols
	variable xPos, layer, legacyActiveADColumns, searchLayer
	STRUCT RGBColor s

	WAVE/T/Z traces
	[traces, lblTemplate] = LBV_GenerateTraceNames(key, NUM_HEADSTAGES)

	list = GetListOfObjects(dfr, TP_STORAGE_REGEXP, fullPath = 1)

	axisBaseName = "tpstorage_" + VERT_AXIS_BASE_NAME

	WAVE/Z numericalValues = BSP_GetLogbookWave(graph, LBT_LABNOTEBOOK, LBN_NUMERICAL_VALUES, selectedExpDevice = 1)
	ASSERT(WaveExists(numericalValues), "LabNotebook not found.")

	// 5872e556 (Modified files: DR_MIES_TangoInteract:  changes recommended by Thomas ..., 2014-09-11)
	//
	// as we don't have anyway to handle changning associations of activeADC and headstage anyway we
	// just use what we have in the first sweep
	WAVE/Z statusADC = GetLastSetting(numericalValues, 0, "ADC", TEST_PULSE_MODE)

	WAVE channelSel = BSP_GetChannelSelectionWave(graph)

	WAVE userDataKeys = LBV_GetTraceUserDataNames()

	if(ParamIsDefault(isTimeAxis))
		isTimeAxis = LBV_CheckIfXAxisIsTime(graph)
	else
		isTimeAxis = isTimeAxis
	endif

	numEntries = ItemsInList(list)
	for(i = 0; i < numEntries; i += 1)
		WAVE TPStorage = $StringFromList(i, list)

		layer = FindDimLabel(TPStorage, LAYERS, key)

		if(layer < 0)
			continue
		endif

		if(numEntries > 1)
			suffix = NameOfWave(TPStorage)
			lbl = lblTemplate + "\r(" + suffix + ")"
		else
			suffix = ""
			lbl = lblTemplate
		endif

		WAVE dat = ExtractLogbookSliceTimeStamp(TPStorage)

		axis = GetNextFreeAxisName(graph, axisBaseName)
		traceList = ""

		legacyActiveADColumns = !cmpstr(GetDimLabel(TPStorage, COLS, -1), "ADChannel")

		numCols = DimSize(TPStorage, COLS)
		ASSERT(numCols <= max(NUM_HEADSTAGES, NUM_DA_TTL_CHANNELS), "Invalid number of columns")
		for(j = 0; j < numCols; j += 1)

			if(legacyActiveADColumns)
				headstage = AFH_GetHeadstageFromActiveADC(statusADC, j)

				if(IsNaN(headstage))
					BUG("Could not derive headstage from active ADC")
					headstage = j
				endif
			else
				headstage = j
			endif

			if(IsFinite(headstage) && !channelSel[headstage][%HEADSTAGE])
				continue
			endif

			// ignore completely empty headstages
			if(!legacyActiveADColumns)
				searchLayer = FindDimLabel(TPStorage, LAYERS, "Headstage")
				WAVE/Z indizes = FindIndizes(TPStorage, col = j, prop = PROP_NON_EMPTY, startLayer = searchLayer, endLayer = searchLayer)

				if(!WaveExists(indizes))
					continue
				endif
			endif

			trace = LBV_MakeTraceNameUnique(graph, traces[headstage])

			if(numEntries > 1)
				trace += "_" + suffix
			endif

			traceList = AddListItem(trace, traceList, ";", inf)

			if(isTimeAxis)
				AppendToGraph/W=$graph/L=$axis/B=bottom TPStorage[][headstage][layer]/TN=$trace vs dat
			else
				AppendToGraph/W=$graph/L=$axis/T=top TPStorage[][headstage][layer]/TN=$trace vs TPStorage[][0][%DeltaTimeInSeconds]
			endif

			TUD_SetUserDataFromWaves(graph,                                  \
									 trace,                                  \
									 userDataKeys,                           \
									 {key,                                   \
									  "0",                                   \
									  GetWavesDataFolder(TPStorage, 2),      \
									  num2str(headstage)                     \
									 })

			[s] = GetHeadstageColor(headstage)
			marker = headstage == 0 ? 39 : headstage
			ModifyGraph/W=$graph rgb($trace)=(s.red, s.green, s.blue), marker($trace)=marker
			SetAxis/W=$graph/A=2 $axis
		endfor

		Label/W=$graph $axis lbl

		ModifyGraph/W=$graph lblPosMode = 1, standoff($axis) = 0, freePos($axis) = 0
		ModifyGraph/W=$graph mode = 3

		LBV_UpdateLBGraphLegend(graph, traceList=traceList)
	endfor

	LBV_SetLabNotebookBottomLabel(graph, isTimeAxis)
	EquallySpaceAxis(graph, axisRegExp= ".*" + VERT_AXIS_BASE_NAME + ".*", sortOrder = 16)
End

static Function [WAVE/T/Z traces, string name, string unit, variable col] LBV_GetPropertiesForLabnotebookEntry(WAVE/T keys, string key)

	if(GetKeyWaveParameterAndUnit(keys, key, name, unit, col))
		return [$"", "", "", NaN]
	endif

	[traces, name] = LBV_GenerateTraceNames(name, LABNOTEBOOK_LAYER_COUNT)

	return [traces, name, unit, col]
End

static Function [WAVE/T traces, string niceName] LBV_GenerateTraceNames(string name, variable count)

	niceName = LineBreakingIntoPar(name)

	Make/FREE/N=(count)/T traces = CleanupName(niceName[0, MAX_OBJECT_NAME_LENGTH_IN_BYTES - 5] + " (" + num2str(p + 1) + ")", 0) // +1 because the headstage number is 1-based

	return [traces, niceName]
End

static Function LBV_AddTagsForTextualLBNEntries(string graph, WAVE/T keys, WAVE/T values, string key, [variable firstSweep])
	variable i, j, numRows, numEntries, isTimeAxis, col, sweepCol, firstRow
	string tagString, tmp, text, unit, lbl, name
	STRUCT RGBColor s

	WAVE/T/Z traces
	[traces, lbl, unit, col] = LBV_GetPropertiesForLabnotebookEntry(keys, key)

	if(!WaveExists(traces))
		return NaN
	endif

	WAVE valuesSweep = ExtractLogbookSliceSweep(values)
	WAVE valuesDat = ExtractLogbookSliceTimeStamp(values)

	isTimeAxis = LBV_CheckIfXAxisIsTime(graph)
	sweepCol   = GetSweepColumn(values)

	if(isTimeAxis)
		WAVE xPos = valuesSweep
	else
		WAVE xPos = valuesDat
	endif

	numRows    = GetNumberFromWaveNote(values, NOTE_INDEX)
	numEntries = DimSize(values, LAYERS)

	if(ParamIsDefault(firstSweep))
		firstRow = 0
	else
		FindValue/V=(firstSweep) valuesSweep
		firstRow = V_value
	endif

	for(i = firstRow; i < numRows; i += 1)
		if(!IsFinite(xPos[i]))
			continue
		endif

		tagString = ""
		for(j = 0; j < LABNOTEBOOK_LAYER_COUNT; j += 1)
			text = values[i][col][j]

			if(IsEmpty(text))
				continue
			endif

			[s] = GetHeadstageColor(j)
			sprintf tmp, "\\K(%d, %d, %d)%d:\\K(0, 0, 0)", s.red, s.green, s.blue, j + 1
			text = ReplaceString("\\", text, "\\\\")
			tagString = tagString + tmp + text + "\r"
		endfor

		if(IsEmpty(tagString))
			continue
		endif

		name = traces[0] + "_" + num2str(i)

		Tag/C/N=$name/W=$graph/F=0/L=0/X=0.00/Y=0.00/O=90 $traces[0], i, RemoveEnding(tagString, "\r")
	endfor
End

/// @brief Switch the labnotebook graph x axis type (time <-> sweep numbers)
static Function LBV_SwitchLBGraphXAxis(string graph)
	string trace, dataUnits, list, wvName, info, keysToReadd, key
	variable i, numEntries, isTimeAxis, sweepCol, isTextData, logbookType

	list = TraceNameList(graph, ";", 0 + 1)

	if(isEmpty(list))
		return NaN
	endif

	keysToReadd = ""

	isTimeAxis = LBV_CheckIfXAxisIsTime(graph)

	numEntries = ItemsInList(list)
	for(i = 0; i < numEntries; i += 1)
		trace = StringFromList(i, list)

		WAVE yWave = TraceNameToWaveRef(graph, trace)
		WAVE/Z sourceWave = $TUD_GetUserData(graph, trace, LBV_UD_SOURCE_WAVE)
		ASSERT(WaveExists(sourceWave), "Missing sourceWave user data")

		isTextData = str2num(TUD_GetUserData(graph, trace, LBV_UD_ISTEXT))

		logbookType = GetLogbookType(sourceWave)

		switch(logbookType)
			case LBT_LABNOTEBOOK:
			case LBT_RESULTS:
				if(isTimeAxis)
					if(isTextData)
						WAVE valuesSweep = ExtractLogbookSliceSweep(sourceWave)
						ReplaceWave/W=$graph/X trace=$trace, valuesSweep
					else
						sweepCol = GetSweepColumn(sourceWave)
						ReplaceWave/W=$graph/X trace=$trace, sourceWave[][sweepCol][0]
					endif
				else // other direction
					WAVE dat = ExtractLogbookSliceTimeStamp(sourceWave)

					ReplaceWave/W=$graph/X trace=$trace, dat
				endif
				break
			case LBT_TPSTORAGE:
				key = TUD_GetUserData(graph, trace, "key")
				RemoveTracesFromGraph(graph, trace = trace)
				TUD_RemoveUserData(graph, trace)

				keysToReadd = AddListItem(key, keysToReadd, ";", inf)
				break
		default:
			ASSERT(0, "Invalid logbook type")
		endswitch
	endfor

	keysToReadd = GetUniqueTextEntriesFromList(keysToReadd)

	// readd TPStorage traces with inverted axis type
	numEntries = ItemsInList(keysToReadd)
	DFREF dfr = LBV_GetTPStorageLocation(graph)
	for(i = 0; i < numEntries; i += 1)
		if(!DataFolderExistsDFR(dfr))
			break
		endif

		key = StringFromList(i, keysToReadd)

		LBV_AddTraceToLBGraphTPStorage(graph, dfr, key, isTimeAxis = !isTimeAxis)
	endfor

	LBV_SetLabNotebookBottomLabel(graph, !isTimeAxis)

	LBV_UpdateLBGraphLegend(graph, traceList = list)

	// autoscale all axis after a switch
	list = AxisList(graph)

	numEntries = ItemsInList(list)
	for(i = 0; i < numEntries; i += 1)
		SetAxis/W=$graph/A $StringFromList(i, list)
	endfor
End

/// @brief Check if the x wave belonging to the first trace in the
/// graph has a date/time scale. Returns false if no traces have been found.
static Function LBV_CheckIfXAxisIsTime(string graph)
	string list, trace, name

	list = TraceNameList(graph, ";", 0 + 1)

	if(isEmpty(list))
		WAVE/Z sweeps = GetPlainSweepList(graph)
		// use sweeps axis as default if we have sweeps, use time axis otherwise
		// this is useful for plotting TP data without any sweep data
		return !WaveExists(sweeps)
	endif

	trace = StringFromList(0, list)
	name = NameOfWave(XWaveRefFromTrace(graph, trace))

	return GrepString(name, ".*Dat$")
End

/// @brief Set the appropriate label for the bottom axis of the graph created by CreateTiledChannelGraph
///
/// Assumes that wave data units are equal for all traces
static Function LBV_SetLabNotebookBottomLabel(string graph, variable isTimeAxis)
	// top: LBT_TPSTORAGE in delta time mode
	// bottom: LBT_LABNOTEBOOK/LBT_TPSTORAGE when it is a timestamp axis

	GetAxis/Q/W=$graph top

	if(!V_Flag)
		Label/W=$graph top LABNOTEBOOK_BOTTOM_AXIS_DELTA_TIME
	endif

	GetAxis/Q/W=$graph bottom

	if(!V_Flag)
		if(isTimeAxis)
			Label/W=$graph bottom LABNOTEBOOK_BOTTOM_AXIS_TIME
		else
			Label/W=$graph bottom LABNOTEBOOK_BOTTOM_AXIS_SWEEP
		endif
	endif
End

// @brief Pre-select an entry if we only have one experiment and one device
Function LBV_SelectExperimentAndDevice(string win)
	string experiments, devices, shPanel

	shPanel = LBV_GetSettingsHistoryPanel(win)

	// check for two entries as we also have NONE in both cases

	experiments = LBV_GetExperiments(shPanel)
	if(ItemsInList(experiments) == 2)
		SetPopupMenuIndex(shPanel, "popup_Experiment", 1)
		DisableControl(shPanel, "popup_Experiment")
	else
		SetPopupMenuIndex(shPanel, "popup_Experiment", 0)
	endif

	devices = LBV_GetAllDevicesForExperiment(shPanel)

	// select the device if we have only one (NONE is always present)
	if(ItemsInList(devices) == 2)
		SetPopupMenuIndex(shPanel, "popup_Device", 1)
		DisableControl(shPanel, "popup_Device")
	else
		SetPopupMenuIndex(shPanel, "popup_Device", 0)
	endif
End
