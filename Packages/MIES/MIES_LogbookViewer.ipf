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

static StrConstant LBV_UD_VALUES_WAVE = "values"
static StrConstant LBV_UD_KEYS_WAVE   = "keys"
static StrConstant LBV_UD_HEADSTAGE   = "headstage"
static StrConstant LBV_UD_KEY         = "key"
static StrConstant LBV_UD_ISTEXT      = "text"
static StrConstant LBV_UD_YAXIS       = "yaxis"

Function/S LBV_GetSettingsHistoryPanel(string win)

	return GetMainWindow(win) + "#" + EXT_PANEL_SETTINGSHISTORY
End

Function/S LBV_GetLabNoteBookGraph(string win)

	return LBV_GetSettingsHistoryPanel(win) + "#Labnotebook"
End

Function/S LBV_GetDescriptionNotebook(string win)

	return LBV_GetSettingsHistoryPanel(win) + "#Description"
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

	if(!BSP_HasBoundDevice(win))
		return $""
	endif

	WAVE/Z textualValues   = BSP_GetLogbookWave(win, LBT_LABNOTEBOOK, LBN_TEXTUAL_VALUES, selectedExpDevice = 1)
	WAVE/Z numericalValues = BSP_GetLogbookWave(win, LBT_LABNOTEBOOK, LBN_NUMERICAL_VALUES, selectedExpDevice = 1)

	WAVE/T textualNames = LBV_GetFilledLabnotebookEntries(textualValues)
	WAVE/T numericalNames = LBV_GetFilledLabnotebookEntries(numericalValues)

	WAVE/Z entries = LBV_GetAllLogbookParamNames(textualNames, numericalNames)

	return LBV_PopupExtFormatEntries(entries)
End

/// @brief Returns the list of results keys for the settings history window menu
Function/WAVE LBV_PopupExtGetResultsKeys(string win)

	if(!BSP_HasBoundDevice(win))
		return $""
	endif

	WAVE/Z textualValues   = BSP_GetLogbookWave(win, LBT_RESULTS, LBN_TEXTUAL_VALUES, selectedExpDevice = 1)
	WAVE/Z numericalValues = BSP_GetLogbookWave(win, LBT_RESULTS, LBN_NUMERICAL_VALUES, selectedExpDevice = 1)

	WAVE/T textualNames = LBV_GetFilledLabnotebookEntries(textualValues)
	WAVE/T numericalNames = LBV_GetFilledLabnotebookEntries(numericalValues)

	WAVE/Z entries = LBV_GetAllLogbookParamNames(textualNames, numericalNames)

	return LBV_PopupExtFormatEntries(entries)
End

/// @brief Returns the combined parameter names from the numerical and textual MD key loogbook waves as 1D text wave
static Function/WAVE LBV_GetAllLogbookParamNames(WAVE/T/Z textualNames, WAVE/T/Z numericalNames)
	variable existText, existNum

	WAVE/Z/T textualNamesClean = LBV_CleanLogbookParamNames(textualNames)
	WAVE/Z/T numericalNamesClean = LBV_CleanLogbookParamNames(numericalNames)

	existText = WaveExists(textualNamesClean)
	existNum = WaveExists(numericalNamesClean)
	if(existText && existNum)
		return GetSetUnion(textualNamesClean, numericalNamesClean)
	elseif(existText && !existNum)
		return textualNamesClean
	elseif(!existText && existNum)
		return numericalNamesClean
	endif

	return $""
End

/// @brief Return a wave with all parameter names in the logbook key wave
static Function/WAVE LBV_GetLogbookParamNames(WAVE/Z/T keys)
	variable row

	if(!WaveExists(keys))
		return $""
	endif

	row = FindDimLabel(keys, ROWS, "Parameter")

	Duplicate/FREE/RMD=[row][] keys, names
	Redimension/N=(numpnts(keys))/E=1 names

	return LBV_CleanLogbookParamNames(names)
End

static Function/WAVE LBV_CleanLogbookParamNames(WAVE/Z/T names)

	if(!WaveExists(names))
		return $""
	endif

	WAVE/T hiddenDefaultKeys = ListToTextWave(LABNOTEBOOK_KEYS_INITIAL, ";")

	return GetSetDifference(names, hiddenDefaultKeys)
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

			[WAVE keys, WAVE values] = LBV_GetLogbookWavesForEntry(win, key)

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

	string graph, descNB

	graph = LBV_GetLabNoteBookGraph(win)
	if(!WindowExists(graph))
		return 0
	endif

	RemoveTracesFromGraph(graph)
	RemoveFreeAxisFromGraph(graph)
	RemoveDrawLayers(graph)
	LBV_UpdateLBGraphLegend(graph)
	TUD_Clear(graph)

	descNB = LBV_GetDescriptionNotebook(graph)
	ReplaceNotebookText(descNB, "")
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
	variable numEntries, i, headstage, hasAllEntry

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
			if(!hasAllEntry)
				str += prefix + "indep"
				hasAllEntry = 1
			endif
		endif

		if(mod(i, 2))
			str += "\r"
		endif
	endfor

	if(IsEmpty(str))
		return NaN
	endif

	str = RemoveEndingRegExp(header + str, "\r*")
	TextBox/C/W=$graph/N=text0/F=2 str
End

static Function/WAVE LBV_GetTraceUserDataNames()
	Make/FREE/T wv = {LBV_UD_KEY, LBV_UD_ISTEXT, LBV_UD_KEYS_WAVE, LBV_UD_VALUES_WAVE, LBV_UD_HEADSTAGE, LBV_UD_YAXIS}

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

	isTimeAxis = LBV_CheckIfXAxisIsTime(graph, logbookType=logbookType)
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
		                         num2str(isTextData),                    \
		                         GetWavesDataFolder(keys, 2),            \
		                         GetWavesDataFolder(values, 2),          \
		                         num2str(i < NUM_HEADSTAGES ? i : NaN ), \
		                         axis})

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

	Label/W=$graph $axis, lbl

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

Function LBV_Update(string win)

	LBV_LimitXRangeToSelected(win)
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
		isTimeAxis = LBV_CheckIfXAxisIsTime(graph, logbookType=LBT_TPSTORAGE)
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
			                          "",                                    \
			                          GetWavesDataFolder(TPStorage, 2),      \
			                          num2str(headstage),                    \
			                          axis                                   \
			                         })

			[s] = GetHeadstageColor(headstage)
			marker = headstage == 0 ? 39 : headstage
			ModifyGraph/W=$graph rgb($trace)=(s.red, s.green, s.blue), marker($trace)=marker
			SetAxis/W=$graph/A=2 $axis
		endfor

		if(!IsEmpty(traceList))
			Label/W=$graph $axis, lbl

			ModifyGraph/W=$graph lblPosMode = 1, standoff($axis) = 0, freePos($axis) = 0
			ModifyGraph/W=$graph mode = 3
		endif
	endfor

	WAVE/Z allTraces = TUD_GetUserDataAsWave(graph, "traceName")
	LBV_UpdateLBGraphLegend(graph, traceList=TextWaveToList(allTraces, ";"))

	LBV_SetLabNotebookBottomLabel(graph, isTimeAxis)
	EquallySpaceAxis(graph, axisRegExp= ".*" + VERT_AXIS_BASE_NAME + ".*", sortOrder = 16)
End

static Function [WAVE/T/Z traces, string name, string unit, variable col] LBV_GetPropertiesForLabnotebookEntry(WAVE/T keys, string key)
	variable result

	[result, unit, col] = LBN_GetEntryProperties(keys, key)

	if(result)
		return [$"", "", "", NaN]
	endif

	[traces, name] = LBV_GenerateTraceNames(key, LABNOTEBOOK_LAYER_COUNT)

	return [traces, name, unit, col]
End

static Function [WAVE/T traces, string niceName] LBV_GenerateTraceNames(string name, variable count)

	niceName = LineBreakingIntoPar(name)

	Make/FREE/N=(count)/T traces = CleanupName(niceName[0, MAX_OBJECT_NAME_LENGTH_IN_BYTES - 5] + " (" + num2str(p + 1) + ")", 0) // +1 because the headstage number is 1-based

	return [traces, niceName]
End

static Function LBV_AddTagsForTextualLBNEntries(string graph, WAVE/T keys, WAVE/T values, string key, [variable firstSweep])
	variable i, j, numRows, numEntries, isTimeAxis, col, sweepCol, firstRow, logbookType, lastSweep
	string tagString, tmp, text, unit, lbl, name, lastTag
	STRUCT RGBColor s

	WAVE/T/Z traces
	[traces, lbl, unit, col] = LBV_GetPropertiesForLabnotebookEntry(keys, key)

	if(!WaveExists(traces))
		return NaN
	endif

	WAVE valuesSweep = ExtractLogbookSliceSweep(values)
	WAVE valuesDat = ExtractLogbookSliceTimeStamp(values)

	logbookType = GetLogbookType(keys)

	isTimeAxis = LBV_CheckIfXAxisIsTime(graph, logbookType=logbookType)
	sweepCol   = GetSweepColumn(values)

	if(isTimeAxis)
		WAVE xPos = valuesDat
	else
		WAVE xPos = valuesSweep
	endif

	numRows    = GetNumberFromWaveNote(values, NOTE_INDEX)
	numEntries = DimSize(values, LAYERS)

	if(ParamIsDefault(firstSweep))
		firstRow = 0
	else
		FindValue/V=(firstSweep) valuesSweep
		firstRow = V_value
	endif

	lastSweep = NaN
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
			sprintf tmp, "\\K(%d, %d, %d)%d:\\K(0, 0, 0)", s.red, s.green, s.blue, j
			text = ReplaceString("\\", text, "\\\\")
			tagString = tagString + tmp + text + "\r"
		endfor

		if(IsEmpty(tagString))
			continue
		endif

		name = traces[0] + "_" + num2str(i)
		tagString = RemoveEnding(tagString, "\r")

		if(lastSweep == valuesSweep[i] && !cmpstr(tagString, lastTag))
			// don't add the same tag again
			continue
		endif

		Tag/C/N=$name/W=$graph/F=0/L=0/X=0.00/Y=0.00/O=90 $traces[0], i, tagString
		lastSweep = valuesSweep[i]
		lastTag = tagString
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
		WAVE/Z values = $TUD_GetUserData(graph, trace, LBV_UD_VALUES_WAVE)
		ASSERT(WaveExists(values), "Missing values user data")

		isTextData = str2num(TUD_GetUserData(graph, trace, LBV_UD_ISTEXT))

		logbookType = GetLogbookType(values)

		switch(logbookType)
			case LBT_LABNOTEBOOK:
			case LBT_RESULTS:
				if(isTimeAxis)
					if(isTextData)
						WAVE valuesSweep = ExtractLogbookSliceSweep(values)
						ReplaceWave/W=$graph/X trace=$trace, valuesSweep
					else
						sweepCol = GetSweepColumn(values)
						ReplaceWave/W=$graph/X trace=$trace, values[][sweepCol][0]
					endif
				else // other direction
					WAVE dat = ExtractLogbookSliceTimeStamp(values)

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

	LBV_LimitXRangeToSelected(graph)
End

/// @brief Check if the x wave belonging to the first trace in the
/// graph has a date/time scale.
static Function LBV_CheckIfXAxisIsTime(string graph, [variable logbookType])
	string list, trace, name

	list = TraceNameList(graph, ";", 0 + 1)

	if(isEmpty(list))
		if(!ParamIsDefault(logbookType))
			switch(logbookType)
				case LBT_RESULTS:
				case LBT_TPSTORAGE:
					return 1
				case LBT_LABNOTEBOOK:
					return 0
				default:
					ASSERT(0, "Invalid logbookType")
			endswitch
		endif

		return 0
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

static Function/S LBV_FormatDescription(WAVE/T/Z keys, string name)
	variable idx, i, numEntries
	string template, result, str, text

	idx = FindDimLabel(keys, COLS, name)

	if(idx < 0 || FindDimLabel(keys, ROWS, "Description") < 0)
		return "<None>"
	endif

	result = ""

	template = "%s: %s\r"

	numEntries = DimSize(keys, ROWS)
	for(i = 0; i < numEntries; i += 1)
		text = keys[i][idx]

		if(IsEmpty(text))
			continue
		endif

		sprintf str, template, GetDimLabel(keys, ROWS, i), text
		result += str
	endfor

	return result
End

Function LBV_EntryDescription(STRUCT WMWinHookStruct &s)
	string win, info, list, axis, descNB, key
	variable numEntries, i, axisOrientation, first, last, relYPos, width, yAxisHorizPos

	switch(s.eventCode)
		case EVENT_WINDOW_HOOK_MOUSEMOVED:
			win = LBV_GetLabNoteBookGraph(s.winName)
			if(cmpstr(s.winName, win))
				// not our subwindow
				break
			endif

			list = AxisList(win)
			if(IsEmpty(list))
				// empty graph
				break
			endif

			GetAxis/Q/W=$win bottom

			yAxisHorizPos = AxisValFromPixel(win, "bottom", s.mouseLoc.h)

			if(yAxisHorizPos > V_min)
				// to the right of the y-axis
				break
			endif

			list = GrepList(list, "lbn_.*")
			numEntries = ItemsInList(list)

			for(i = 0; i < numEntries; i += 1)
				axis = StringFromList(i, list)

				axisOrientation = GetAxisOrientation(win, axis)
				if(axisOrientation != AXIS_ORIENTATION_LEFT)
					continue
				endif

				info = AxisInfo(win, axis)

				first = GetNumFromModifyStr(info, "axisEnab", "{", 0)
				last  = GetNumFromModifyStr(info, "axisEnab", "{", 1)

				relYPos = 1 - (s.mouseloc.v / (s.winRect.bottom - s.winRect.top))

				if(first < relYPos && relYPos < last)
					WAVE/T/Z matches = TUD_GetUserDataAsWave(win, LBV_UD_KEY, keys = {LBV_UD_YAXIS}, values = {axis})
					ASSERT(WaveExists(matches), "Invalid key")
					key = matches[0]

					WAVE/T/Z matches = TUD_GetUserDataAsWave(win, LBV_UD_KEYS_WAVE, keys = {LBV_UD_YAXIS, LBV_UD_KEY}, values = {axis, key})
					ASSERT(WaveExists(matches), "Invalid keys")
					WAVE/T/Z keys = $matches[0]

					descNB = LBV_GetDescriptionNotebook(win)
					ReplaceNotebookText(descNB, LBV_FormatDescription(keys, key))
					ReflowNotebookText(descNB)
				endif
			endfor
			break
		case EVENT_WINDOW_HOOK_RESIZE:
			descNB = LBV_GetDescriptionNotebook(s.winName)
			ReflowNotebookText(descNB)
			break
	endswitch

	return 0
End

Function LBV_PlotAllAnalysisFunctionLBNKeys(string browser, variable anaFuncType)
	string key, graph, axes, prefix
	variable i, numEntries

	WAVE/T/Z textualKeys   = BSP_GetLogbookWave(browser, LBT_LABNOTEBOOK, LBN_TEXTUAL_KEYS, selectedExpDevice = 1)
	WAVE/T/Z numericalKeys = BSP_GetLogbookWave(browser, LBT_LABNOTEBOOK, LBN_NUMERICAL_KEYS, selectedExpDevice = 1)

	WAVE/T/Z allKeys = LBV_GetAllLogbookParamNames(numericalkeys, textualKeys)

	if(!WaveExists(allKeys))
		printf "Could not find any labnotebook keys.\r"
		ControlWindowToFront()
		return NaN
	endif

	// remove entries which would clutter everything
	prefix = CreateAnaFuncLBNKey(anaFuncType, "%s", query = 1)
	Make/FREE/T ignoredKeys = {prefix + " cycle x values"}

	WAVE/T/Z anaFuncKeys = GrepTextWave(allKeys, prefix + "*")

	if(!WaveExists(anaFuncKeys))
		printf "Could not find any labnotebook keys for analysis function.\r"
		ControlWindowToFront()
		return NaN
	endif

	WAVE/T/Z keys = GetSetDifference(anaFuncKeys, ignoredKeys)

	STRUCT WMPopupAction pa
	pa.win = LBV_GetSettingsHistoryPanel(browser)
	pa.eventCode = 2

	// add user entries from given analysis function
	numEntries = DimSize(keys, ROWS)
	for(i = 0; i < numEntries; i += 1)
		pa.popStr = keys[i]
		LBV_PopMenuProc_LabNotebookAndResults(pa)
	endfor

	// add interesting stock entries
	pa.popStr = STIMSET_SCALE_FACTOR_KEY
	LBV_PopMenuProc_LabNotebookAndResults(pa)

	pa.popStr = "Stimset Acq Cycle ID"
	LBV_PopMenuProc_LabNotebookAndResults(pa)
End

/// @brief Limit the bottom axis of the settings history graph to the selected/displayed sweeps
static Function LBV_LimitXRangeToSelected(string browser)
	variable minSweep, maxSweep, first, last
	string graph, shPanel, scPanel, key

	graph = LBV_GetLabNoteBookGraph(browser)

	if(TUD_GetTraceCount(graph) == 0)
		return NaN
	endif

	shPanel = LBV_GetSettingsHistoryPanel(browser)

	if(!GetCheckBoxState(shPanel, "check_limit_x_selected_sweeps"))
		return NaN
	endif

	WAVE/Z selectedSweeps = OVS_GetSelectedSweeps(browser, OVS_SWEEP_SELECTION_SWEEPNO)

	if(!WaveExists(selectedSweeps))
		scPanel = BSP_GetSweepControlsPanel(browser)
		Make/FREE selectedSweeps = {GetSetVariable(scPanel, "setvar_SweepControl_SweepNo")}
	endif

	[minSweep, maxSweep] = WaveMinAndMax(selectedSweeps)

	// display one more sweep on both sides
	minSweep = max(0, minSweep - 1)
	maxSweep  = maxSweep + 1

	if(LBV_CheckIfXAxisIsTime(graph))
		WAVE/T/Z numericalValues = BSP_GetLogbookWave(browser, LBT_LABNOTEBOOK, LBN_NUMERICAL_VALUES, selectedExpDevice = 1)
		ASSERT(WaveExists(numericalValues), "numericalValues can not be found")

		// get the timestamps of minSweep/maxSweep, moving inwards if they are empty

		// present since ec6c1ac6 (Labnotebook: Add UTC timestamps, 2015-09-18)
		key = "TimeStampSinceIgorEpochUTC"

		first = GetLastSettingIndep(numericalValues, minSweep, key, DATA_ACQUISITION_MODE)

		if(IsNaN(first))
			first = GetLastSettingIndep(numericalValues, minSweep + 1, key, DATA_ACQUISITION_MODE)
		endif

		last = GetLastSettingIndep(numericalValues, maxSweep, key, DATA_ACQUISITION_MODE)

		if(IsNaN(last))
			last = GetLastSettingIndep(numericalValues, maxSweep - 1, key, DATA_ACQUISITION_MODE)
		endif

		// convert to local time zone
		first += date2secs(-1, -1, -1)
		last  += date2secs(-1, -1, -1)

		ASSERT(IsFinite(first) && IsFinite(last), "Invalid first/last")
	else
		first = minSweep
		last  = maxSweep
	endif

	SetAxis/W=$graph bottom, first, last
End

Function LBV_CheckProc_XRangeSelected(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	switch(cba.eventCode)
		case 2: // mouse up
			if(cba.checked)
				LBV_LimitXRangeToSelected(cba.win)
			endif
			break
	endswitch

	return 0
End
