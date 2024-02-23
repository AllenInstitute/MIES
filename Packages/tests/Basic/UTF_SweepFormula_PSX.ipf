#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma ModuleName=UTF_SweepFormula_PSX

Function [string browser, string device, string formulaGraph] CreateFakeDataBrowserWithSweepFormulaGraph()

	[browser, device] = CreateEmptyUnlockedDataBrowserWindow()
	GetDeviceDataPath(device)
	browser = MIES_DB#DB_LockToDevice(browser, device)

	formulaGraph = GetSweepFormulaGraph()

	SetWindow $formulaGraph, userData($SFH_USER_DATA_BROWSER)=browser

	return [browser, device, formulaGraph]
End

Function/S GetSweepFormulaGraph()

	string win
	variable numEvents, comboIndex

	numEvents = 5

	win = CleanupName(SF_PLOT_NAME_TEMPLATE, 0)
	NewPanel/N=$win
	win = S_name

	DFREF workDFR = UniqueDataFolder(GetMiesPath(), "psx_test")

	BSP_SetFolder(win, workDFR, MIES_PSX#PSX_GetUserDataForWorkingFolder())
	MIES_PSX#PSX_MarkGraphForPSX(win)

	comboIndex = 0

	WAVE psxEvent = CreateEventWaveInComboFolder_IGNORE(comboIndex = comboIndex)
	Redimension/N=(numEvents, -1) psxEvent

	DFREF dfr = GetPSXFolderForCombo(workDFR, comboIndex)
	CHECK(DataFolderExistsDFR(dfr))

	WAVE eventColors = GetPSXEventColorsWaveAsFree(numEvents)
	MoveWave eventColors, dfr:eventColors

	WAVE eventMarker = GetPSXEventMarkerWaveAsFree(numEvents)
	MoveWave eventMarker, dfr:eventMarker

	psxEvent[][%$"Event manual QC call"] = PSX_UNDET
	psxEvent[][%$"Fit manual QC call"]   = PSX_UNDET
	psxEvent[][%$"Fit result"]           = mod(p, 2)

	return win
End

static Function/WAVE CreateEventWaveInComboFolder_IGNORE([variable comboIndex])

	string win, userData

	if(ParamIsDefault(comboIndex))
		comboIndex = 0
	else
		CHECK(IsInteger(comboIndex))
	endif

	WAVE psxEvent = GetPSXEventWaveAsFree()
	CHECK_WAVE(psxEvent, NUMERIC_WAVE, minorType = DOUBLE_WAVE)

	JWN_CreatePath(psxEvent, SF_META_USER_GROUP + "Parameters/psx")
	JWN_SetStringInWaveNote(psxEvent, SF_META_USER_GROUP + "Parameters/psx/id", "myId")
	JWN_SetStringInWaveNote(psxEvent, PSX_EVENTS_COMBO_KEY_WAVE_NOTE, "fake combo key")
	JWN_CreatePath(psxEvent, SF_META_USER_GROUP + "Parameters/psxRiseTime")

	win      = GetCurrentWindow()
	userData = MIES_PSX#PSX_GetUserDataForWorkingFolder()
	DFREF workDFR = BSP_GetFolder(win, userData, versionCheck = 0)

	DFREF dfr = GetPSXFolderForCombo(workDFR, comboIndex)
	CHECK(DataFolderExistsDFR(dfr))

	MoveWave psxEvent, dfr:psxEvent

	WAVE psxEvent = GetPSXEventWaveFromDFR(dfr)
	CHECK_WAVE(psxEvent, NUMERIC_WAVE, minorType = DOUBLE_WAVE)

	return psxEvent
End

static Function/WAVE GetEventWave([variable comboIndex])

	string win

	if(ParamIsDefault(comboIndex))
		comboIndex = 0
	else
		CHECK(IsInteger(comboIndex))
	endif

	win = GetCurrentWindow()
	DFREF workDFR = BSP_GetFolder(win, MIES_PSX#PSX_GetUserDataForWorkingFolder(), versionCheck = 0)

	DFREF dfr = GetPSXFolderForCombo(workDFR, comboIndex)
	CHECK(DataFolderExistsDFR(dfr))

	WAVE psxEvent = GetPSXEventWaveFromDFR(dfr)
	CHECK_WAVE(psxEvent, NUMERIC_WAVE, minorType = DOUBLE_WAVE)

	return psxEvent
End

static Function CheckEvent(WAVE indizes, variable eventState, variable fitState)

	variable idx

	WAVE psxEvent = GetEventWave()

	for(idx : indizes)
		INFO("eventState: index %d, %s vs %s", n0 = idx, s0 = MIES_PSX#PSX_StateToString(eventState), s1 = MIES_PSX#PSX_StateToString(psxEvent[idx][%$"Event manual QC call"]))
		CHECK_EQUAL_VAR(psxEvent[idx][%$"Event manual QC call"], eventState)

		INFO("fitState: index %d, %s vs %s", n0 = idx, s0 = MIES_PSX#PSX_StateToString(fitState), s1 = MIES_PSX#PSX_StateToString(psxEvent[idx][%$"Fit manual QC call"]))
		CHECK_EQUAL_VAR(psxEvent[idx][%$"Fit manual QC call"], fitState)
	endfor
End

static Function [variable psxEventModCount, variable eventMarkerModCount, variable eventColorsModCount] GetModCounts(string win)

	variable modCountColors, modCountMarkers, comboIndex

	win = GetCurrentWindow()
	DFREF workDFR = BSP_GetFolder(win, MIES_PSX#PSX_GetUserDataForWorkingFolder(), versionCheck = 0)

	comboIndex = 0
	DFREF dfr = GetPSXFolderForCombo(workDFR, comboIndex)
	CHECK(DataFolderExistsDFR(dfr))

	WAVE/Z/SDFR=dfr psxEvent, eventColors, eventMarker

	CHECK_WAVE(eventColors, NUMERIC_WAVE)
	CHECK_WAVE(eventMarker, NUMERIC_WAVE)

	return [WaveModCountWrapper(psxEvent), WaveModCountWrapper(eventMarker), WaveModCountWrapper(eventColors)]
End

static Function EWUCheckOneOfValToggle()

	string win = GetSweepFormulaGraph()

	try
		MIES_PSX#PSX_UpdateEventWaves(win)
		FAIL()
	catch
		PASS()
	endtry
End

static Function EWUCheckWin()

	string win = GetSweepFormulaGraph()

	try
		MIES_PSX#PSX_UpdateEventWaves("I_DONT_EXIST", toggle = 1)
		FAIL()
	catch
		PASS()
	endtry
End

static Function EWUCheckCombo()

	string win = GetSweepFormulaGraph()

	try
		MIES_PSX#PSX_UpdateEventWaves(win, toggle = 1, comboIndex = 100)
		FAIL()
	catch
		PASS()
	endtry
End

static Function EWUCheckStateType()

	string win = GetSweepFormulaGraph()

	try
		MIES_PSX#PSX_UpdateEventWaves(win, toggle = 1, comboIndex = 0, stateType = -1)
		FAIL()
	catch
		PASS()
	endtry
End

static Function EQUCheckIndizesWave()

	string win = GetSweepFormulaGraph()

	try
		MIES_PSX#PSX_UpdateEventWaves(win, toggle = 1, comboIndex = 0, indizes = {{0, 1}, {2, 3}})
		FAIL()
	catch
		PASS()
	endtry
End

static Function EWUCheckVal()

	string win = GetSweepFormulaGraph()

	try
		MIES_PSX#PSX_UpdateEventWaves(win, val = -1, comboIndex = 0)
		FAIL()
	catch
		PASS()
	endtry
End

static Function EWUCheckInitialToggle()

	string win = GetSweepFormulaGraph()

	WAVE psxEvent = GetEventWave()
	psxEvent[][%$"Event manual QC call"] = Inf

	try
		MIES_PSX#PSX_UpdateEventWaves(win, toggle = 1, comboIndex = 0)
		FAIL()
	catch
		PASS()
	endtry
End

static Function EWUToggleWorksWithEvent()

	string win = GetSweepFormulaGraph()

	CheckEvent({0, 1, 2, 3, 4}, PSX_UNDET, PSX_UNDET)
	MIES_PSX#PSX_UpdateEventWaves(win, toggle = 1, comboIndex = 0)
	// undet -> accept
	// fitState is untouched as stateType defaults to event
	CheckEvent({0, 1, 2, 3, 4}, PSX_ACCEPT, PSX_UNDET)

	// accept -> reject
	MIES_PSX#PSX_UpdateEventWaves(win, toggle = 1, comboIndex = 0)
	CheckEvent({0, 1, 2, 3, 4}, PSX_REJECT, PSX_UNDET)

	// reject -> undet
	MIES_PSX#PSX_UpdateEventWaves(win, toggle = 1, comboIndex = 0)
	CheckEvent({0, 1, 2, 3, 4}, PSX_UNDET, PSX_UNDET)
End

static Function EWUToggleWorksWithFit()

	string win = GetSweepFormulaGraph()

	CheckEvent({0, 1, 2, 3, 4}, PSX_UNDET, PSX_UNDET)
	MIES_PSX#PSX_UpdateEventWaves(win, toggle = 1, comboIndex = 0, stateType = PSX_STATE_FIT)
	// eventState is untouched
	// fitState was adapted only for the indizes which have fit result 1
	CheckEvent({1, 3}, PSX_UNDET, PSX_ACCEPT)
	CheckEvent({0, 2, 4}, PSX_UNDET, PSX_UNDET)
End

static Function EWUToggleWorksWithBoth()

	string win = GetSweepFormulaGraph()

	CheckEvent({0, 1, 2, 3, 4}, PSX_UNDET, PSX_UNDET)
	MIES_PSX#PSX_UpdateEventWaves(win, toggle = 1, comboIndex = 0, stateType = PSX_STATE_BOTH)
	// both are adapted
	CheckEvent({1, 3}, PSX_ACCEPT, PSX_ACCEPT)
	CheckEvent({0, 2, 4}, PSX_ACCEPT, PSX_UNDET)
End

static Function EWUToggleWorksWithEventAndNoStateWrite()

	string win = GetSweepFormulaGraph()
	variable psxEventModCountOld, modCountMarkersOld, modCountColorsOld, psxEventModCountNew, modCountMarkersNew, modCountColorsNew

	CheckEvent({0, 1, 2, 3, 4}, PSX_UNDET, PSX_UNDET)
	[psxEventModCountOld, modCountMarkersOld, modCountColorsOld] = GetModCounts(win)
	CHECK_GT_VAR(psxEventModCountOld, 0)
	CHECK_GT_VAR(modCountMarkersOld, 0)
	CHECK_GT_VAR(modCountColorsOld, 0)

	MIES_PSX#PSX_UpdateEventWaves(win, toggle = 1, comboIndex = 0, writeState = 0)

	CheckEvent({0, 1, 2, 3, 4}, PSX_UNDET, PSX_UNDET)
	[psxEventModCountNew, modCountMarkersNew, modCountColorsNew] = GetModCounts(win)
	CHECK_EQUAL_VAR(psxEventModCountNew, psxEventModCountOld)
	CHECK_GT_VAR(modCountMarkersNew, modCountMarkersOld)
	CHECK_GT_VAR(modCountColorsNew, modCountColorsOld)
End

static Function EWUIndexWorksWithEvent()

	string win = GetSweepFormulaGraph()

	CheckEvent({0, 1, 2, 3, 4}, PSX_UNDET, PSX_UNDET)
	MIES_PSX#PSX_UpdateEventWaves(win, comboIndex = 0, index = 1, val = PSX_REJECT, stateType = PSX_STATE_EVENT)
	// only eventState at index 1
	CheckEvent({0, 2, 3, 4}, PSX_UNDET, PSX_UNDET)
	CheckEvent({1}, PSX_REJECT, PSX_UNDET)
End

static Function EWUIndexWorksWithFit()

	string win = GetSweepFormulaGraph()

	CheckEvent({0, 1, 2, 3, 4}, PSX_UNDET, PSX_UNDET)
	MIES_PSX#PSX_UpdateEventWaves(win, comboIndex = 0, index = 3, val = PSX_REJECT, stateType = PSX_STATE_FIT)
	// only fitState at index 3
	CheckEvent({0, 1, 2, 4}, PSX_UNDET, PSX_UNDET)
	CheckEvent({3}, PSX_UNDET, PSX_REJECT)
End

static Function EWUIndexWorksWithBoth()

	string win = GetSweepFormulaGraph()

	CheckEvent({0, 1, 2, 3, 4}, PSX_UNDET, PSX_UNDET)
	MIES_PSX#PSX_UpdateEventWaves(win, comboIndex = 0, index = 3, val = PSX_REJECT, stateType = PSX_STATE_BOTH)
	// both at index 3
	CheckEvent({0, 1, 2, 4}, PSX_UNDET, PSX_UNDET)
	CheckEvent({3}, PSX_REJECT, PSX_REJECT)
End

static Function EWUIndizesWorksWithEvent()

	string win = GetSweepFormulaGraph()

	CheckEvent({0, 1, 2, 3, 4}, PSX_UNDET, PSX_UNDET)
	MIES_PSX#PSX_UpdateEventWaves(win, comboIndex = 0, indizes = {0, 2, 3}, val = PSX_REJECT, stateType = PSX_STATE_EVENT)
	// only eventState at {0, 2, 3}
	CheckEvent({0, 2, 3}, PSX_REJECT, PSX_UNDET)
	CheckEvent({1, 4}, PSX_UNDET, PSX_UNDET)
End

static Function EWUIndizesWorksWithFit()

	string win = GetSweepFormulaGraph()

	CheckEvent({0, 1, 2, 3, 4}, PSX_UNDET, PSX_UNDET)
	MIES_PSX#PSX_UpdateEventWaves(win, comboIndex = 0, indizes = {0, 2, 3}, val = PSX_REJECT, stateType = PSX_STATE_FIT)
	// only fitState at {0, 2, 3}
	CheckEvent({0, 2}, PSX_UNDET, PSX_UNDET)
	CheckEvent({3}, PSX_UNDET, PSX_REJECT)
	CheckEvent({1, 4}, PSX_UNDET, PSX_UNDET)
End

static Function EWUIndizesWorksWithBoth()

	string win = GetSweepFormulaGraph()

	CheckEvent({0, 1, 2, 3, 4}, PSX_UNDET, PSX_UNDET)
	MIES_PSX#PSX_UpdateEventWaves(win, comboIndex = 0, indizes = {0, 2, 3}, val = PSX_REJECT, stateType = PSX_STATE_BOTH)
	// both at {0, 2, 3}
	CheckEvent({0, 2}, PSX_REJECT, PSX_UNDET)
	CheckEvent({3}, PSX_REJECT, PSX_REJECT)
	CheckEvent({1, 4}, PSX_UNDET, PSX_UNDET)
End

static Function CheckSweepEquiv()

	variable sweepNo, chanType, chanNr

	WAVE selectData = SFH_NewSelectDataWave(5, 1)

	selectData[0][%SWEEP] = 1
	selectData[1][%SWEEP] = 2
	selectData[2][%SWEEP] = 3
	selectData[3][%SWEEP] = 4
	selectData[4][%SWEEP] = 5

	selectData[0][%CHANNELNUMBER] = 10
	selectData[1][%CHANNELNUMBER] = 30
	selectData[2][%CHANNELNUMBER] = 10
	selectData[3][%CHANNELNUMBER] = 20 // same sweep but different channel number
	selectData[4][%CHANNELNUMBER] = 10

	selectData[0][%CHANNELTYPE] = XOP_CHANNEL_TYPE_ADC
	selectData[1][%CHANNELTYPE] = XOP_CHANNEL_TYPE_ADC
	selectData[2][%CHANNELTYPE] = XOP_CHANNEL_TYPE_TTL // same sweep bug different channel type
	selectData[3][%CHANNELTYPE] = XOP_CHANNEL_TYPE_ADC
	selectData[4][%CHANNELTYPE] = XOP_CHANNEL_TYPE_ADC

	// sweep 1 and 5 are a group the rest is separate

	WAVE/Z selectDataEquiv = MIES_PSX#PSX_GenerateSweepEquiv(selectData)
	CHECK_WAVE(selectDataEquiv, NUMERIC_WAVE, minorType = FLOAT_WAVE)

	Make/FREE ref = {{1, 2, 3, 4}, {5, NaN, NaN, NaN}}
	CHECK_EQUAL_WAVES(selectDataEquiv, ref, mode = WAVE_DATA)

	Make/T/N=(4)/FREE refLabels = MIES_PSX#PSX_BuildSweepEquivKey(selectData[p][%CHANNELTYPE], selectData[p][%CHANNELNUMBER])
	Make/T/N=(4)/FREE labels = GetDimLabel(selectDataEquiv, ROWS, p)
	CHECK_EQUAL_WAVES(refLabels, labels, mode = WAVE_DATA)

	[chanNr, chanType, sweepNo] = MIES_PSX#PSX_GetSweepEquivKeyAndSweep(selectDataEquiv, 0, 1)
	CHECK_EQUAL_VAR(sweepNo, 5)
	CHECK_EQUAL_VAR(chanType, XOP_CHANNEL_TYPE_ADC)
	CHECK_EQUAL_VAR(chanNr, 10)
End

Function [WAVE range, WAVE selectData] GetFakeRangeAndSelectData()

	WAVE range      = SFH_GetEmptyRange()
	WAVE selectData = SFH_NewSelectDataWave(1, 1)

	range[]                       = {100, 200}
	selectData[0][%SWEEP]         = 1
	selectData[0][%CHANNELTYPE]   = XOP_CHANNEL_TYPE_ADC
	selectData[0][%CHANNELNUMBER] = 3

	return [range, selectData]
End

static Function StatsComplainsWithoutEvents()

	string formulaGraph, browser, device, result, stateAsStr, postProc, prop
	string error, id

	[browser, device, formulaGraph] = CreateFakeDataBrowserWithSweepFormulaGraph()

	[WAVE range, WAVE selectData] = GetFakeRangeAndSelectData()

	prop       = "tau"
	stateAsStr = MIES_PSX#PSX_StateToString(PSX_ACCEPT)
	postProc   = "nothing"
	id         = "myID"

	// matching id but no events
	try
		MIES_PSX#PSX_OperationStatsImpl(browser, id, {range}, selectData, prop, stateAsStr, postProc)
		FAIL()
	catch
		error = ROStr(GetSweepFormulaParseErrorMessage())
		CHECK_EQUAL_STR(error, "Could not find any PSX events for all given combinations.")
	endtry

	id = "I_DONT_EXIST"

	// mismatched id
	try
		MIES_PSX#PSX_OperationStatsImpl(browser, id, {range}, selectData, prop, stateAsStr, postProc)
		FAIL()
	catch
		error = ROStr(GetSweepFormulaParseErrorMessage())
		CHECK_EQUAL_STR(error, "Could not find any PSX events for all given combinations.")
	endtry
End

static Function FillEventWave_IGNORE(WAVE psxEvent, string id, string comboKey)

	variable jsonID

	CHECK_EQUAL_VAR(DimSize(psxEvent, COLS), 14) // test needs update if that fails

	psxEvent[][%index]        = p
	psxEvent[][%peak_t]       = 100 * p
	psxEvent[][%peak]         = NaN
	psxEvent[][%post_min]     = NaN
	psxEvent[][%post_min_t]   = -10 * p
	psxEvent[][%pre_max]      = NaN
	psxEvent[][%pre_max_t]    = NaN
	psxEvent[][%rel_peak]     = p == 0 ? NaN : 10 * p
	psxEvent[][%isi]          = 1000 * p
	psxEvent[][%tau]          = 1e-6 * p
	psxEvent[][%$"Rise Time"] = p == 0 ? NaN : 0.1 * p
	// PSX_ACCEPT:1
	// PSX_REJECT:2
	// PSX_UNDET: 4

	Make/FREE refFitState = {1, 4, 2, 4, 1, 4, 2, 4, 1, 4}
	Make/FREE refEventState = {2, 1, 4, 1, 2, 1, 4, 1, 2, 4}
	Make/FREE refFitResult = {0, 1, 0, 1, 0, 1, 0, 1, 0, 1}

	psxEvent[][%$"Fit manual QC call"]   = refFitState[p]
	psxEvent[][%$"Event manual QC call"] = refEventState[p]
	psxEvent[][%$"Fit result"]           = refFitResult[p]

	jsonID = JSON_New()
	JSON_AddTreeObject(jsonID, "/User/Parameters/psx")
	JSON_SetString(jsonID, "/User/Parameters/psx/id", id)
	JSON_SetString(jsonID, PSX_EVENTS_COMBO_KEY_WAVE_NOTE, comboKey)
	JSON_AddTreeObject(jsonID, "/User/Parameters/psxRiseTime")
	JWN_SetWaveNoteFromJSON(psxEvent, jsonID)
End

Function/WAVE StatsTest_GetInput()

	Make/T/FREE/N=(3) template
	SetDimensionLabels(template, "prop;state;postProc", ROWS)

	// wv0
	Duplicate/FREE/T template, wv0
	WAVE/T input = wv0

	input[%prop]     = "estate"
	input[%state]    = "accept"
	input[%postProc] = "nothing"

	JWN_SetWaveInWaveNote(input, "/results", {PSX_ACCEPT, PSX_ACCEPT, PSX_ACCEPT, PSX_ACCEPT})
	JWN_SetWaveInWaveNote(input, "/xValues", {1, 3, 5, 7})
	JWN_SetWaveInWaveNote(input, "/marker", {PSX_MARKER_ACCEPT, PSX_MARKER_ACCEPT, PSX_MARKER_ACCEPT, PSX_MARKER_ACCEPT})

	// wv1
	Duplicate/FREE/T template, wv1
	WAVE/T input = wv1

	input[%prop]     = "estate"
	input[%state]    = "reject"
	input[%postProc] = "nothing"

	JWN_SetWaveInWaveNote(input, "/results", {PSX_REJECT, PSX_REJECT, PSX_REJECT})
	JWN_SetWaveInWaveNote(input, "/xValues", {0, 4, 8})
	JWN_SetWaveInWaveNote(input, "/marker", {PSX_MARKER_REJECT, PSX_MARKER_REJECT, PSX_MARKER_REJECT})

	// wv2
	Duplicate/FREE/T template, wv2
	WAVE/T input = wv2

	input[%prop]     = "estate"
	input[%state]    = "undetermined"
	input[%postProc] = "nothing"

	JWN_SetWaveInWaveNote(input, "/results", {PSX_UNDET, PSX_UNDET, PSX_UNDET})
	JWN_SetWaveInWaveNote(input, "/xValues", {2, 6, 9})
	JWN_SetWaveInWaveNote(input, "/marker", {PSX_MARKER_UNDET, PSX_MARKER_UNDET, PSX_MARKER_UNDET})

	// wv3
	Duplicate/FREE/T template, wv3
	WAVE/T input = wv3

	input[%prop]     = "tau"
	input[%state]    = "accept"
	input[%postProc] = "nothing"

	JWN_SetWaveInWaveNote(input, "/results", {0e-6, 4e-6, 8e-6})
	JWN_SetWaveInWaveNote(input, "/xValues", {0, 4, 8})
	JWN_SetWaveInWaveNote(input, "/marker", {PSX_MARKER_ACCEPT, PSX_MARKER_ACCEPT, PSX_MARKER_ACCEPT})

	// wv4
	Duplicate/FREE/T template, wv4
	WAVE/T input = wv4

	input[%prop]     = "amp"
	input[%state]    = "accept"
	input[%postProc] = "stats"

	JWN_SetWaveInWaveNote(input, "/results", {40, 40, 20, 25.81988897471611, 0, -2.0775})
	JWN_SetWaveInWaveNote(input, "/xValues", ListToTextWave(PSX_STATS_LABELS, ";"))
	JWN_SetWaveInWaveNote(input, "/marker", {PSX_MARKER_ACCEPT, PSX_MARKER_ACCEPT, PSX_MARKER_ACCEPT, \
	                                         PSX_MARKER_ACCEPT, PSX_MARKER_ACCEPT, PSX_MARKER_ACCEPT})

	// wv5
	Duplicate/FREE/T template, wv5
	WAVE/T input = wv5

	input[%prop]     = "fstate"
	input[%state]    = "undetermined"
	input[%postProc] = "count"

	JWN_SetWaveInWaveNote(input, "/results", {5})
	// no xValues
	JWN_SetWaveInWaveNote(input, "/marker", {PSX_MARKER_UNDET})

	// wv6
	Duplicate/FREE/T template, wv6
	WAVE/T input = wv6

	input[%prop]     = "xpos"
	input[%state]    = "undetermined"
	input[%postProc] = "hist"

	JWN_SetWaveInWaveNote(input, "/results", {1, 2})
	// no xValues
	JWN_SetWaveInWaveNote(input, "/marker", {PSX_MARKER_UNDET, PSX_MARKER_UNDET})

	// wv7
	Duplicate/FREE/T template, wv7
	WAVE/T input = wv7

	input[%prop]     = "xinterval"
	input[%state]    = "undetermined"
	input[%postProc] = "log10"

	JWN_SetWaveInWaveNote(input, "/results", {NaN, log(600 - 200), log(900 - 600)})
	JWN_SetWaveInWaveNote(input, "/xValues", {2, 6, 9})
	JWN_SetWaveInWaveNote(input, "/marker", {PSX_MARKER_UNDET, PSX_MARKER_UNDET, PSX_MARKER_UNDET})

	// wv8
	Duplicate/FREE/T template, wv8
	WAVE/T input = wv8

	input[%prop]     = "fitresult"
	input[%state]    = "undetermined"
	input[%postProc] = "nothing"

	JWN_SetWaveInWaveNote(input, "/results", {1, 1, 1, 1, 1})
	JWN_SetWaveInWaveNote(input, "/xValues", {1, 3, 5, 7, 9})
	JWN_SetWaveInWaveNote(input, "/marker", {PSX_MARKER_UNDET, PSX_MARKER_UNDET, PSX_MARKER_UNDET, PSX_MARKER_UNDET, PSX_MARKER_UNDET})

	// wv8
	Duplicate/FREE/T template, wv9
	WAVE/T input = wv9

	input[%prop]     = "risetime"
	input[%state]    = "undetermined"
	input[%postProc] = "nothing"

	JWN_SetWaveInWaveNote(input, "/results", {0.2, 0.6, 0.9})
	JWN_SetWaveInWaveNote(input, "/xValues", {2, 6, 9})
	JWN_SetWaveInWaveNote(input, "/marker", {PSX_MARKER_UNDET, PSX_MARKER_UNDET, PSX_MARKER_UNDET})

	// wv10
	Duplicate/FREE/T template, wv10
	WAVE/T input = wv10

	input[%prop]     = "xpos"
	input[%state]    = "all"
	input[%postProc] = "nonfinite"

	JWN_SetWaveInWaveNote(input, "/results", {1, 3, 5, 7, 9})
	JWN_SetWaveInWaveNote(input, "/xValues", {0, -1, +1, 0, -1})
	JWN_SetWaveInWaveNote(input, "/marker", {PSX_MARKER_ACCEPT, PSX_MARKER_ACCEPT, PSX_MARKER_ACCEPT, PSX_MARKER_ACCEPT, PSX_MARKER_UNDET})
	Make/FREE/T lbl = {"-inf", "NaN", "inf"}
	JWN_SetWaveInWaveNote(input, "/XTickLabels", lbl)
	JWN_SetWaveInWaveNote(input, "/XTickPositions", {-1, 0, 1})

	// end
	Make/FREE/WAVE results = {wv0, wv1, wv2, wv3, wv4, wv5, wv6, wv7, wv8, wv9, wv10}

	return results
End

/// UTF_TD_GENERATOR w0:StatsTest_GetInput
static Function StatsWorksWithResults([STRUCT IUTF_mData &m])

	string formulaGraph, browser, device, stateAsStr, postProc, prop
	string error, ref, comboKey, id

	WAVE/T input = m.w0

	prop       = input[%prop]
	stateAsStr = input[%state]
	postProc   = input[%postProc]
	WAVE/Z results        = JWN_GetNumericWaveFromWaveNote(input, "/results")
	WAVE/Z xValues        = JWN_GetNumericWaveFromWaveNote(input, "/xValues")
	WAVE/Z marker         = JWN_GetNumericWaveFromWaveNote(input, "/marker")
	WAVE/Z xTickLabels    = JWN_GetTextWaveFromWaveNote(input, "/XTickLabels")
	WAVE/Z XTickPositions = JWN_GetNumericWaveFromWaveNote(input, "/XTickPositions")

	if(WaveExists(xValues) && !HasOneValidEntry(xValues))
		WaveClear xValues

		WAVE/Z xValues = JWN_GetTextWaveFromWaveNote(input, "/xValues")
	endif

	[browser, device, formulaGraph] = CreateFakeDataBrowserWithSweepFormulaGraph()

	[WAVE range, WAVE selectData] = GetFakeRangeAndSelectData()

	WAVE psxEvent = GetPSXEventWaveAsFree()
	Redimension/N=(10, -1) psxEvent

	comboKey = MIES_PSX#PSX_GenerateComboKey(browser, selectData, range)
	ref      = "Range[100, 200], Sweep [1], Channel [AD3], Device [ITC16_Dev_0]"
	CHECK_EQUAL_STR(comboKey, ref)

	id = "myID"
	FillEventWave_IGNORE(psxEvent, id, comboKey)

	if(!cmpstr(postProc, "nonfinite"))
		// overwrite peak_t data
		Make/FREE/D peak_t = {10, NaN, 20, -Inf, 30, +Inf, 40, NaN, 50, -Inf}
		psxEvent[][%peak_t] = peak_t[p]
	endif

	MIES_PSX#PSX_StoreIntoResultsWave(browser, SFH_RESULT_TYPE_PSX_EVENTS, psxEvent, id)

	WAVE/WAVE output = MIES_PSX#PSX_OperationStatsImpl(browser, id, {range}, selectData, prop, stateAsStr, postProc)
	CHECK_WAVE(output, WAVE_WAVE)

	Make/FREE/N=4 dims = DimSize(output, p)
	Make/FREE/N=4 refDims = {1, 0, 0, 0}
	CHECK_EQUAL_WAVES(dims, refDims, mode = WAVE_DATA)

	WAVE/Z resultsRead = output[0]

	if(!cmpstr(postProc, "count"))
		CHECK_WAVE(resultsRead, NUMERIC_WAVE, minorType = INT32_WAVE | UNSIGNED_WAVE)
	else
		CHECK_WAVE(resultsRead, NUMERIC_WAVE, minorType = DOUBLE_WAVE)
	endif

	CHECK_EQUAL_WAVES(resultsRead, results, mode = WAVE_DATA, tol = 1e-5)

	WAVE/Z xValuesReadNumeric = JWN_GetNumericWaveFromWaveNote(resultsRead, SF_META_XVALUES)

	if(WaveExists(xValuesReadNumeric) && !HasOneValidEntry(xValuesReadNumeric))
		WaveClear xValuesReadNumeric

		WAVE/Z xValuesReadText = JWN_GetTextWaveFromWaveNote(resultsRead, SF_META_XVALUES)
	endif

	if(WaveExists(xValues))
		if(IsNumericWave(xValuesReadNumeric))
			CHECK_WAVE(xValuesReadNumeric, NUMERIC_WAVE, minorType = DOUBLE_WAVE)
			CHECK_EQUAL_WAVES(xValuesReadNumeric, xValues, mode = WAVE_DATA)
		elseif(IsTextWave(xValuesReadText))
			CHECK_WAVE(xValuesReadText, TEXT_WAVE)
			CHECK_EQUAL_WAVES(xValuesReadText, xValues, mode = WAVE_DATA)
		endif
	else
		CHECK_WAVE(xValuesReadNumeric, NULL_WAVE)
		CHECK_WAVE(xValuesReadText, NULL_WAVE)
		CHECK_WAVE(xValues, NULL_WAVE)
	endif

	WAVE/Z markerRead = JWN_GetNumericWaveFromWaveNote(resultsRead, SF_META_MOD_MARKER)

	if(WaveExists(marker))
		// we do write a float wave into the json wave note, but it is read always as double
		CHECK_WAVE(markerRead, NUMERIC_WAVE, minorType = DOUBLE_WAVE)
		CHECK_EQUAL_WAVES(markerRead, marker)
	else
		CHECK_WAVE(markerRead, NULL_WAVE)
		CHECK_WAVE(marker, NULL_WAVE)
	endif

	WAVE/Z xTickPositionsRead = JWN_GetNumericWaveFromWaveNote(resultsRead, SF_META_XTICKPOSITIONS)
	WAVE/Z xTickLabelsRead    = JWN_GetTextWaveFromWaveNote(resultsRead, SF_META_XTICKLABELS)

	if(WaveExists(xTickPositions))
		CHECK_EQUAL_WAVES(xTickPositionsRead, xTickPositions, mode = WAVE_DATA)
	else
		CHECK_WAVE(xTickPositionsRead, NULL_WAVE)
		CHECK_WAVE(xTickPositions, NULL_WAVE)
	endif

	if(WaveExists(xTickLabels))
		CHECK_EQUAL_WAVES(xTickLabelsRead, xTickLabels, mode = WAVE_DATA)
	else
		CHECK_WAVE(xTickLabelsRead, NULL_WAVE)
		CHECK_WAVE(xTickLabels, NULL_WAVE)
	endif
End

Function/WAVE StatsTestSpecialCases_GetInput()

	Make/T/FREE/N=(7) template
	SetDimensionLabels(template, "prop;state;postProc;refNumOutputRows;numEventsCombo0;numEventsCombo1;outOfRange", ROWS)

	// wv0
	// every
	Duplicate/FREE/T template, wv0
	WAVE/T input = wv0

	input[%prop]             = "estate"
	input[%state]            = "every"
	input[%postProc]         = "nothing"
	input[%refNumOutputRows] = "3"
	input[%numEventsCombo0]  = "5"
	input[%numEventsCombo1]  = "3"
	input[%outOfRange]       = "0"

	JWN_CreatePath(input, "/0")
	JWN_SetWaveInWaveNote(input, "/0/results", {PSX_ACCEPT, PSX_ACCEPT, PSX_ACCEPT})
	JWN_SetWaveInWaveNote(input, "/0/xValues", {1, 3, 1})
	JWN_SetWaveInWaveNote(input, "/0/marker", {PSX_MARKER_ACCEPT, PSX_MARKER_ACCEPT, PSX_MARKER_ACCEPT})

	JWN_CreatePath(input, "/1")
	JWN_SetWaveInWaveNote(input, "/1/results", {PSX_REJECT, PSX_REJECT, PSX_REJECT})
	JWN_SetWaveInWaveNote(input, "/1/xValues", {0, 4, 0})
	JWN_SetWaveInWaveNote(input, "/1/marker", {PSX_MARKER_REJECT, PSX_MARKER_REJECT, PSX_MARKER_REJECT})

	JWN_CreatePath(input, "/2")
	JWN_SetWaveInWaveNote(input, "/2/results", {PSX_UNDET, PSX_UNDET})
	JWN_SetWaveInWaveNote(input, "/2/xValues", {2, 2})
	JWN_SetWaveInWaveNote(input, "/2/marker", {PSX_MARKER_UNDET, PSX_MARKER_UNDET})

	// wv1
	// no match
	Duplicate/FREE/T template, wv1
	WAVE/T input = wv1

	input[%prop]             = "estate"
	input[%state]            = "accept"
	input[%postProc]         = "nothing"
	input[%refNumOutputRows] = "0"
	input[%numEventsCombo0]  = "1"
	input[%numEventsCombo1]  = "1"
	input[%outOfRange]       = "0"

	// wv2
	// histogram works also with just one point
	Duplicate/FREE/T template, wv2
	WAVE/T input = wv2

	input[%prop]             = "estate"
	input[%state]            = "reject"
	input[%postProc]         = "hist"
	input[%refNumOutputRows] = "1"
	input[%numEventsCombo0]  = "1"
	input[%numEventsCombo1]  = "0"
	input[%outOfRange]       = "0"

	JWN_CreatePath(input, "/0")
	JWN_SetWaveInWaveNote(input, "/0/results", {1})
	// no x values
	JWN_SetWaveInWaveNote(input, "/0/marker", {PSX_MARKER_REJECT})

	// wv3
	// histogram with no match as the tau values are out-of-range
	Duplicate/FREE/T template, wv3
	WAVE/T input = wv3

	input[%prop]             = "tau"
	input[%state]            = "undetermined"
	input[%postProc]         = "hist"
	input[%refNumOutputRows] = "0"
	input[%numEventsCombo0]  = "3"
	input[%numEventsCombo1]  = "0"
	input[%outOfRange]       = "1"

	// wv4
	// histogram with match but cut out data
	Duplicate/FREE/T template, wv4
	WAVE/T input = wv4

	input[%prop]             = "amp"
	input[%state]            = "all"
	input[%postProc]         = "hist"
	input[%refNumOutputRows] = "1"
	input[%numEventsCombo0]  = "3"
	input[%numEventsCombo1]  = "0"
	input[%outOfRange]       = "1"

	JWN_CreatePath(input, "/0")
	JWN_SetWaveInWaveNote(input, "/0/results", {1})
	// no xValues
	JWN_SetWaveInWaveNote(input, "/0/marker", {PSX_MARKER_REJECT})

	// wv5
	// stats ignores NaN
	Duplicate/FREE/T template, wv5
	WAVE/T input = wv5

	input[%prop]             = "amp"
	input[%state]            = "all"
	input[%postProc]         = "stats"
	input[%refNumOutputRows] = "1"
	input[%numEventsCombo0]  = "2"
	input[%numEventsCombo1]  = "2"
	input[%outOfRange]       = "0"

	JWN_CreatePath(input, "/0")
	JWN_SetWaveInWaveNote(input, "/0/results", {10, NaN, 0, 0, NaN, NaN})
	JWN_SetWaveInWaveNote(input, "/0/xValues", ListToTextWave(PSX_STATS_LABELS, ";"))
	JWN_SetWaveInWaveNote(input, "/0/marker", {PSX_MARKER_REJECT, PSX_MARKER_REJECT, PSX_MARKER_REJECT, \
	                                           PSX_MARKER_REJECT, PSX_MARKER_REJECT, PSX_MARKER_REJECT})

	// wv6
	// stats ignores NaN and with all data NaN we don't get anything
	Duplicate/FREE/T template, wv6
	WAVE/T input = wv6

	input[%prop]             = "amp"
	input[%state]            = "all"
	input[%postProc]         = "stats"
	input[%refNumOutputRows] = "0"
	input[%numEventsCombo0]  = "1"
	input[%numEventsCombo1]  = "1"
	input[%outOfRange]       = "0"

	// no results
	// no xValues
	// no marker

	// wv7
	// xinterval with multiple combos
	Duplicate/FREE/T template, wv7
	WAVE/T input = wv7

	input[%prop]             = "xinterval"
	input[%state]            = "accept"
	input[%postProc]         = "nothing"
	input[%refNumOutputRows] = "1"
	input[%numEventsCombo0]  = "5"
	input[%numEventsCombo1]  = "5"
	input[%outOfRange]       = "0"

	JWN_CreatePath(input, "/0")
	JWN_SetWaveInWaveNote(input, "/0/results", {NaN, 200, NaN, 200})
	JWN_SetWaveInWaveNote(input, "/0/xValues", {1, 3, 1, 3})
	JWN_SetWaveInWaveNote(input, "/0/marker", {PSX_MARKER_ACCEPT, PSX_MARKER_ACCEPT, PSX_MARKER_ACCEPT, PSX_MARKER_ACCEPT})

	// end
	Make/FREE/WAVE results = {wv0, wv1, wv2, wv3, wv4, wv5, wv6, wv7}

	return results
End

// Test events being present locally in a DFREF
/// UTF_TD_GENERATOR w0:StatsTestSpecialCases_GetInput
static Function StatsWorksWithResultsSpecialCases([STRUCT IUTF_mData &m])

	string prop, stateAsStr, postProc, browser, device, formulaGraph, comboKey, pathPrefix, history, id
	variable numEventsCombo0, numEventsCombo1, idx, refNumRows, outOfRange, refNum

	WAVE/T input = m.w0

	prop            = input[%prop]
	stateAsStr      = input[%state]
	postProc        = input[%postProc]
	refNumRows      = str2num(input[%refNumOutputRows])
	numEventsCombo0 = str2num(input[%numEventsCombo0])
	numEventsCombo1 = str2num(input[%numEventsCombo1])
	outOfRange      = str2num(input[%outOfRange])

	[browser, device, formulaGraph] = CreateFakeDataBrowserWithSweepFormulaGraph()

	[WAVE range, WAVE selectData] = GetFakeRangeAndSelectData()

	Duplicate/FREE selectData, selectDataComboIndex0

	// 1st event wave
	// comboIndex 0 already exists
	WAVE/Z psxEvent = GetEventWave(comboIndex = 0)
	Redimension/N=(numEventsCombo0, -1) psxEvent
	comboKey = MIES_PSX#PSX_GenerateComboKey(browser, selectDataComboIndex0, range)
	id       = "myID"
	FillEventWave_IGNORE(psxEvent, id, comboKey)

	selectDataComboIndex0[0][%SWEEP] = 1
	JWN_CreatePath(psxEvent, "/User/Parameters/psxKernel/")
	JWN_SetNumberInWaveNote(psxEvent, "/User/Parameters/psxKernel/decayTau", 1e-8)
	JWN_SetNumberInWaveNote(psxEvent, "/User/Parameters/psxKernel/amp", 0.1)

	// 2nd event wave
	WAVE/Z psxEvent = CreateEventWaveInComboFolder_IGNORE(comboIndex = 1)
	Redimension/N=(numEventsCombo1, -1) psxEvent

	Duplicate/FREE selectData, selectDataComboIndex1
	selectDataComboIndex1[0][%SWEEP] = 2
	comboKey                         = MIES_PSX#PSX_GenerateComboKey(browser, selectDataComboIndex1, range)
	id                               = "myID"
	FillEventWave_IGNORE(psxEvent, id, comboKey)

	Duplicate/FREE selectData, selectDataComboIndex2
	// invalid sweep numbers are silently ignored
	selectDataComboIndex2[0][%SWEEP] = -1

	Concatenate/NP=(ROWS)/FREE {selectDataComboIndex0, selectDataComboIndex1, selectDataComboIndex2}, allSelectData

	if(outOfRange)
		refNum = CaptureHistoryStart()
	else
		refNum = NaN
	endif

	WAVE/WAVE output = MIES_PSX#PSX_OperationStatsImpl(browser, id, {range}, allSelectData, prop, stateAsStr, postProc)
	CHECK_WAVE(output, WAVE_WAVE)

	if(outOfRange)
		history = CaptureHistory(refNum, 1)
		CHECK_PROPER_STR(history)
		CHECK_GE_VAR(strsearch(history, "out-of-range", 0), 0)
	endif

	Make/FREE/N=4 dims = DimSize(output, p)
	Make/FREE/N=4 refDims = {refNumRows, 0, 0, 0}
	CHECK_EQUAL_WAVES(dims, refDims, mode = WAVE_DATA)

	for(resultsRead : output)

		pathPrefix = "/" + num2str(idx)

		WAVE/Z results = JWN_GetNumericWaveFromWaveNote(input, pathPrefix + "/results")
		WAVE/Z xValues = JWN_GetNumericWaveFromWaveNote(input, pathPrefix + "/xValues")
		WAVE/Z marker  = JWN_GetNumericWaveFromWaveNote(input, pathPrefix + "/marker")

		WAVE/Z xValuesRead = JWN_GetNumericWaveFromWaveNote(resultsRead, SF_META_XVALUES)
		if(WaveExists(xValues))
			CHECK_WAVE(xValuesRead, NUMERIC_WAVE, minorType = DOUBLE_WAVE)
			CHECK_EQUAL_WAVES(xValuesRead, xValues, mode = WAVE_DATA)
		else
			CHECK_WAVE(xValuesRead, NULL_WAVE)
			CHECK_WAVE(xValues, NULL_WAVE)
		endif

		WAVE/Z markerRead = JWN_GetNumericWaveFromWaveNote(resultsRead, SF_META_MOD_MARKER)
		// we do write a float wave into the json wave note, but it is read always as double
		CHECK_WAVE(markerRead, NUMERIC_WAVE, minorType = DOUBLE_WAVE)
		CHECK_EQUAL_WAVES(markerRead, marker)

		CHECK_EQUAL_WAVES(resultsRead, results, mode = WAVE_DATA, tol = 1e-5)

		idx += 1
	endfor
End

static Function StatsComplainsAboutIntersectingRanges()

	string browser, device, formulaGraph, comboKey, id

	[browser, device, formulaGraph] = CreateFakeDataBrowserWithSweepFormulaGraph()

	[WAVE range0, WAVE selectData] = GetFakeRangeAndSelectData()

	// 1st event wave
	WAVE/Z psxEvent = GetEventWave(comboIndex = 0)
	comboKey = MIES_PSX#PSX_GenerateComboKey(browser, selectData, range0)
	id       = "myID"
	FillEventWave_IGNORE(psxEvent, id, comboKey)

	Duplicate/FREE range0, range1

	// 2nd event wave where we shift the range
	WAVE/Z psxEvent = CreateEventWaveInComboFolder_IGNORE(comboIndex = 1)
	range1[] += 0.5 * (range0[1] - range0[0])
	comboKey  = MIES_PSX#PSX_GenerateComboKey(browser, selectData, range1)
	id        = "myID"
	FillEventWave_IGNORE(psxEvent, id, comboKey)

	try
		MIES_PSX#PSX_OperationStatsImpl(browser, id, {range0, range1}, selectData, "amp", "all", "nothing")
		FAIL()
	catch
		CHECK_NO_RTE()
	endtry
End

Function/WAVE FakeSweepDataGeneratorPSXKernel(WAVE sweep, variable numChannels)

	variable pnts = 1001

	Redimension/D/N=(pnts, numChannels) sweep
	SetScale/I x, 0, 200, "ms", sweep
	sweep[ScaleToIndex(sweep, 90, ROWS), ScaleToIndex(sweep, 110, ROWS)] = 1

	return sweep
End

static Function TestOperationPSXKernel()

	string win, device, str, expected, actual
	variable jsonID

	[win, device] = CreateEmptyUnlockedDataBrowserWindow()

	win = CreateFakeSweepData(win, device, sweepNo = 0, sweepGen = FakeSweepDataGeneratorPSXKernel)
	win = CreateFakeSweepData(win, device, sweepNo = 2, sweepGen = FakeSweepDataGeneratorPSXKernel)

	str = "psxKernel([50, 150], select(channels(AD6), [0, 2], all), 1, 15, -5)"
	WAVE/WAVE dataWref = SF_ExecuteFormula(str, win, useVariables = 0)
	CHECK_WAVE(dataWref, WAVE_WAVE)
	CHECK_EQUAL_VAR(DimSize(dataWref, ROWS), 6)

	actual = MIES_CA#CA_WaveCRCs(dataWref, includeWaveScalingAndUnits = 1)

#if IgorVersion() < 10
	expected = "1323156356;3770352039;3016891533;1323156356;3770352039;3016891533;"
#else
	expected = "1323156356;2862587511;3016891533;1323156356;2862587511;3016891533;"
#endif

	CHECK_EQUAL_STR(expected, actual)

	// check dimension labels
	Make/FREE=1/N=6/T dimlabels = GetDimLabel(dataWref, ROWS, p)
	CHECK_EQUAL_TEXTWAVES(dimlabels, {"psxKernel_0", "psxKernelFFT_0", "sweepData_0", "psxKernel_1", "psxKernelFFT_1", "sweepData_1"})

	// check that we have parameters in the JSON wave note
	jsonID = JWN_GetWaveNoteAsJSON(dataWref)
	CHECK_GE_VAR(jsonID, 0)
	WAVE/Z params = JSON_GetKeys(jsonID, SF_META_USER_GROUP + "Parameters/" + SF_OP_PSX_KERNEL)
	CHECK_WAVE(params, TEXT_WAVE)
	CHECK_EQUAL_VAR(DimSize(params, ROWS), 4)
	JSON_Release(jsonID)

	// offset for sweep data is 50 due to the range above
	CheckDimensionScaleHelper(dataWref[0], 0, 0.2)
	CheckDimensionScaleHelper(dataWref[1], 0, 0.01)
	CheckDimensionScaleHelper(dataWref[2], 50, 0.2)
	CheckDimensionScaleHelper(dataWref[3], 0, 0.2)
	CheckDimensionScaleHelper(dataWref[4], 0, 0.01)
	CheckDimensionScaleHelper(dataWref[5], 50, 0.2)

	// no data from select statement
	str = "psxKernel([50, 150], select(channels(AD15), [0]), 1, 15, -5)"
	try
		WAVE/WAVE dataWref = SF_ExecuteFormula(str, win, useVariables = 0)
		FAIL()
	catch
		PASS()
	endtry

	// no data from this sweep statement
	str = "psxKernel(ABCD, select(channels(AD6), [0, 2], all), 1, 15, -5)"
	try
		WAVE/WAVE dataWref = SF_ExecuteFormula(str, win, useVariables = 0)
		FAIL()
	catch
		PASS()
	endtry

	// too large decayTau
	str = "psxKernel([50, 150], select(channels(AD15), [0]), 1, 150, -5)"
	try
		WAVE/WAVE dataWref = SF_ExecuteFormula(str, win, useVariables = 0)
		FAIL()
	catch
		PASS()
	endtry
End

static Function CheckDimensionScaleHelper(WAVE wv, variable refOffset, variable refPerPoint)

	CHECK_EQUAL_VAR(DimOffset(wv, ROWS), refOffset)
	CHECK_EQUAL_VAR(DimDelta(wv, ROWS), refPerPoint)
End

Function/WAVE FakeSweepDataGeneratorPSX(WAVE sweep, variable numChannels)

	variable pnts = 1001

	Redimension/D/N=(pnts, numChannels) sweep
	SetScale/I x, 0, 200, "ms", sweep
	sweep[ScaleToIndex(sweep, 40, ROWS), ScaleToIndex(sweep, 65, ROWS)] = 1
	sweep[ScaleToIndex(sweep, 40, ROWS), ScaleToIndex(sweep, 68, ROWS)] = 1

	sweep[ScaleToIndex(sweep, 80, ROWS), ScaleToIndex(sweep, 95, ROWS)] = 1
	sweep[ScaleToIndex(sweep, 95, ROWS), ScaleToIndex(sweep, 96, ROWS)] = 20

	sweep[ScaleToIndex(sweep, 120, ROWS), ScaleToIndex(sweep, 130, ROWS)] = 1
	sweep[ScaleToIndex(sweep, 130, ROWS), ScaleToIndex(sweep, 132, ROWS)] = 20

	return sweep
End

static Function/WAVE GetKernelAmplitude()

	Make/D/FREE wv = {5, -5}

	return wv
End

/// IUTF_TD_GENERATOR v0:GetKernelAmplitude
static Function TestOperationPSX([STRUCT IUTF_mData &m])
	string win, device, str
	variable jsonID, kernelAmp

	kernelAmp = m.v0

	Make/FREE/T combos = {"Range[50, 150], Sweep [0], Channel [AD6], Device [ITC16_Dev_0]", \
	                      "Range[50, 150], Sweep [2], Channel [AD6], Device [ITC16_Dev_0]"}
	WAVE overrideResults = MIES_PSX#PSX_CreateOverrideResults(4, combos)

	// all decay fits are successfull
	overrideResults[][][%$"Fit Result"] = 1

	[win, device] = CreateEmptyUnlockedDataBrowserWindow()

	win = CreateFakeSweepData(win, device, sweepNo = 0, sweepGen = FakeSweepDataGeneratorPSX)
	win = CreateFakeSweepData(win, device, sweepNo = 2, sweepGen = FakeSweepDataGeneratorPSX)

	str = "psx(myID, psxKernel([50, 150], select(channels(AD6), [0, 2], all), 1, 15, " + num2str(kernelAmp) + "), 2.5, 100, 0)"
	WAVE/WAVE dataWref = SF_ExecuteFormula(str, win, useVariables = 0)
	CHECK_WAVE(dataWref, WAVE_WAVE)
	CHECK_EQUAL_VAR(DimSize(dataWref, ROWS), 2 * 7)

	// check dimension labels
	Make/FREE=1/N=14/T dimlabels = GetDimLabel(dataWref, ROWS, p)
	CHECK_EQUAL_TEXTWAVES(dimlabels, {"sweepData_0", "sweepDataFiltOff_0", "sweepDataFiltOffDeconv_0", "peakX_0", "peakY_0", "psxEvent_0", "eventFit_0", \
	                                  "sweepData_1", "sweepDataFiltOff_1", "sweepDataFiltOffDeconv_1", "peakX_1", "peakY_1", "psxEvent_1", "eventFit_1"})

	CheckEventDataHelper(dataWref, 0)
	CheckEventDataHelper(dataWref, 1)

	// check that we have parameters in the JSON wave note
	jsonID = JWN_GetWaveNoteAsJSON(dataWref)
	CHECK_GE_VAR(jsonID, 0)
	WAVE/Z params = JSON_GetKeys(jsonID, SF_META_USER_GROUP + "Parameters/" + SF_OP_PSX_KERNEL)
	CHECK_WAVE(params, TEXT_WAVE)
	CHECK_EQUAL_VAR(DimSize(params, ROWS), 4)

	WAVE/Z params = JSON_GetKeys(jsonID, SF_META_USER_GROUP + "Parameters/" + SF_OP_PSX)
	CHECK_WAVE(params, TEXT_WAVE)
	CHECK_EQUAL_VAR(DimSize(params, ROWS), 5)

	WAVE/Z params = JSON_GetKeys(jsonID, SF_META_USER_GROUP + "Parameters/" + SF_OP_PSX_RISETIME)
	CHECK_WAVE(params, TEXT_WAVE)
	CHECK_EQUAL_VAR(DimSize(params, ROWS), 2)

	JSON_Release(jsonID)

	// check that plain psx does not error out
	str = "psx(id, psxKernel([50, 150], select(channels(AD6), [0, 2], all)))"
	WAVE/WAVE dataWref = SF_ExecuteFormula(str, win, useVariables = 0)
	CHECK_NO_RTE()
	CHECK_WAVE(dataWref, WAVE_WAVE)

	// complains without events found
	str = "psx(myID, psxKernel([50, 150], select(channels(AD6), [0, 2], all), 5000, 15, -5), 25, 100, 0)"
	try
		WAVE/WAVE dataWref = SF_ExecuteFormula(str, win, useVariables = 0)
		FAIL()
	catch
		PASS()
	endtry
End

static Function TestOperationPSXTooLargeDecayTau()
	string win, device, str
	variable jsonID

	Make/FREE/T combos = {"Range[50, 150], Sweep [0], Channel [AD6], Device [ITC16_Dev_0]"}
	WAVE overrideResults = MIES_PSX#PSX_CreateOverrideResults(2, combos)

	// all decay fits are successfull
	overrideResults[][][%$"Fit Result"] = 1
	overrideResults[][][%Tau]           = 1000

	[win, device] = CreateEmptyUnlockedDataBrowserWindow()

	win = CreateFakeSweepData(win, device, sweepNo = 0, sweepGen = FakeSweepDataGeneratorPSX)
	win = CreateFakeSweepData(win, device, sweepNo = 2, sweepGen = FakeSweepDataGeneratorPSX)

	str = "psx(myID, psxKernel([50, 150], select(channels(AD6), [0], all), 1, 15, -5), 10, 100, 0)"
	WAVE/WAVE dataWref = SF_ExecuteFormula(str, win, useVariables = 0)
	CHECK_WAVE(dataWref, WAVE_WAVE)

	WAVE psxEvent = dataWref[%$"psxEvent_0"]

	Duplicate/FREE/RMD=[][FindDimLabel(psxEvent, COLS, "Fit Result")] psxEvent, fitResult
	Redimension/N=(DimSize(fitResult, ROWS)) fitResult

	CHECK_EQUAL_WAVES(fitResult, {PSX_DECAY_FIT_ERROR, PSX_DECAY_FIT_ERROR}, mode = WAVE_DATA)
End

static Function CheckEventDataHelper(WAVE/WAVE/Z dataWref, variable index)

	variable numEvents

	WAVE/Z psxEvent = dataWref[%$"psxEvent_" + num2str(index)]
	CHECK_WAVE(psxEvent, NUMERIC_WAVE, minorType = DOUBLE_WAVE)

	WAVE/WAVE/Z eventFit = dataWref[%$"eventFit_" + num2str(index)]
	CHECK_WAVE(eventFit, WAVE_WAVE)

	numEvents = DimSize(psxEvent, ROWS)

	CHECK_EQUAL_VAR(numEvents, DimSize(eventFit, ROWS))

	// "Fit Result" corresponds to non-null fit wave
	Make/FREE/N=(numEvents) comp
	comp = psxEvent[p][%$"Fit Result"] == WaveExists(eventFit[p])
	CHECK_EQUAL_VAR(Sum(comp), numEvents)

	// default states are PSX_UNDET
	comp = psxEvent[p][%$"Fit manual QC call"] == PSX_UNDET
	CHECK_EQUAL_VAR(Sum(comp), numEvents)

	comp = psxEvent[p][%$"Event manual QC call"] == PSX_UNDET
	CHECK_EQUAL_VAR(Sum(comp), numEvents)

	comp = sign(psxEvent[p][%$"Rise Time"])
	CHECK_EQUAL_VAR(Sum(comp), numEvents)

	// 1 NaN for the first event only
	WaveStats/M=0/Q psxEvent
	CHECK_EQUAL_VAR(V_numNaNs, 1)
	CHECK_EQUAL_VAR(V_numInfs, 0)
End

static Function ExecuteSweepFormulaCode(string browser, string code)
	string bsPanel

	SF_SetFormula(browser, code)

	bsPanel = BSP_GetPanel(browser)

	PGC_SetAndActivateControl(bsPanel, "check_BrowserSettings_SF", val = 1)
	PGC_SetAndActivateControl(bsPanel, "button_sweepFormula_display", val = NaN)
End

static Function CheckPSXEventField(WAVE/WAVE psxEventWaves, WAVE/T colLabels, WAVE indices, variable val)

	variable idx
	string   colLabel

	for(colLabel : colLabels)
		for(WAVE psxEvent : psxEventWaves)
			for(idx : indices)
				INFO("psxEvent %s, colLabel \"%s\", index %d, state: actual %s vs ref %s", s0 = NameOfWave(psxEvent), s1 = colLabel, n0 = idx, s3 = MIES_PSX#PSX_StateToString(psxEvent[idx][%$colLabel]), s2 = MIES_PSX#PSX_StateToString(val))
				CHECK_EQUAL_VAR(psxEvent[idx][%$colLabel], val)
			endfor
		endfor
	endfor
End

static Function [WAVE psxEvent_0, WAVE psxEvent_1] GetPSXEventWavesHelper(string win)

	REQUIRE(WindowExists(win))

	DFREF workDFR = MIES_PSX#PSX_GetWorkingFolder(win)
	CHECK(DataFolderExistsDFR(workDFR))

	WAVE/DF/Z comboFolders = MIES_PSX#PSX_GetAllCombinationFolders(workDFR)
	CHECK_WAVE(comboFolders, DATAFOLDER_WAVE)
	CHECK_EQUAL_VAR(DimSize(comboFolders, ROWS), 2)

	return [GetPSXEventWaveFromDFR(comboFolders[0]), GetPSXEventWaveFromDFR(comboFolders[1])]
End

static Function MouseSelectionPSX()

	string browser, device, code, psxPlot, win

	Make/FREE/T combos = {"Range[50, 150], Sweep [0], Channel [AD6], Device [ITC16_Dev_0]", \
	                      "Range[50, 150], Sweep [2], Channel [AD6], Device [ITC16_Dev_0]"}
	WAVE overrideResults = MIES_PSX#PSX_CreateOverrideResults(4, combos)

	overrideResults[][][%$"Fit Result"] = 1
	overrideResults[][][%$"Tau"]        = 1

	browser = DB_OpenDataBrowser()
	device  = HW_ITC_BuildDeviceString(StringFromList(0, DEVICE_TYPES_ITC), StringFromList(0, DEVICE_NUMBERS))

	browser = CreateFakeSweepData(browser, device, sweepNo = 0, sweepGen = FakeSweepDataGeneratorPSX)
	browser = CreateFakeSweepData(browser, device, sweepNo = 2, sweepGen = FakeSweepDataGeneratorPSX)

	browser = MIES_DB#DB_LockToDevice(browser, device)

	code = "psx(myId, psxKernel([50, 150], select(channels(AD6), [0, 2], all)), 5, 100, 0)"

	// combo0 is the current one

	ExecuteSweepFormulaCode(browser, code)

	win     = SFH_GetFormulaGraphForBrowser(browser)
	psxPlot = MIES_PSX#PSX_GetPSXGraph(win)
	REQUIRE(WindowExists(psxPlot))

	[WAVE psxEvent_0, WAVE psxEvent_1] = GetPSXEventWavesHelper(psxPlot)

	CheckPSXEventField({psxEvent_0, psxEvent_1}, {"Fit manual QC call", "Event manual QC call"}, {0, 1}, PSX_UNDET)

	// select event 0
	SetMarquee/W=$psxPlot/HAX=bottom/VAX=$"leftFiltOffDeconv" 80, 15e-3, 110, 5e-3

	SetActiveSubwindow $psxPlot
	PSX_MouseEventSelection(PSX_ACCEPT, PSX_STATE_EVENT)

	// refetch the changed waves after each selection
	[WAVE psxEvent_0, WAVE psxEvent_1] = GetPSXEventWavesHelper(psxPlot)

	CheckPSXEventField({psxEvent_0}, {"Fit manual QC call"}, {0, 1}, PSX_UNDET)
	CheckPSXEventField({psxEvent_0}, {"Event manual QC call"}, {0}, PSX_ACCEPT)
	CheckPSXEventField({psxEvent_0}, {"Event manual QC call"}, {1}, PSX_UNDET)
	CheckPSXEventField({psxEvent_1}, {"Fit manual QC call", "Event manual QC call"}, {0, 1}, PSX_UNDET)

	// select event 1
	SetMarquee/W=$psxPlot/HAX=bottom/VAX=$"leftFiltOffDeconv" 120, 25e-3, 200, 5e-3

	SetActiveSubwindow $psxPlot
	PSX_MouseEventSelection(PSX_REJECT, PSX_STATE_EVENT)

	[WAVE psxEvent_0, WAVE psxEvent_1] = GetPSXEventWavesHelper(psxPlot)

	CheckPSXEventField({psxEvent_0}, {"Fit manual QC call"}, {0, 1}, PSX_UNDET)
	CheckPSXEventField({psxEvent_0}, {"Event manual QC call"}, {0}, PSX_ACCEPT)
	CheckPSXEventField({psxEvent_0}, {"Event manual QC call"}, {1}, PSX_REJECT)
	CheckPSXEventField({psxEvent_1}, {"Fit manual QC call", "Event manual QC call"}, {0, 1}, PSX_UNDET)

	// select both events top axis pair, event and fit state
	SetMarquee/W=$psxPlot/HAX=bottom/VAX=$"leftFiltOff" 50, 0, 200, 1

	SetActiveSubwindow $psxPlot
	PSX_MouseEventSelection(PSX_REJECT, PSX_STATE_FIT | PSX_STATE_EVENT)

	[WAVE psxEvent_0, WAVE psxEvent_1] = GetPSXEventWavesHelper(psxPlot)

	CheckPSXEventField({psxEvent_0}, {"Fit manual QC call", "Event manual QC call"}, {0, 1}, PSX_REJECT)
	CheckPSXEventField({psxEvent_1}, {"Fit manual QC call", "Event manual QC call"}, {0, 1}, PSX_UNDET)

	// select nothing in both directions
	SetMarquee/W=$psxPlot/HAX=bottom/VAX=$"leftFiltOff" 0, 1, 50, 10

	SetActiveSubwindow $psxPlot
	PSX_MouseEventSelection(PSX_REJECT, PSX_STATE_FIT | PSX_STATE_EVENT)

	[WAVE psxEvent_0, WAVE psxEvent_1] = GetPSXEventWavesHelper(psxPlot)

	CheckPSXEventField({psxEvent_0}, {"Fit manual QC call", "Event manual QC call"}, {0, 1}, PSX_REJECT)
	CheckPSXEventField({psxEvent_1}, {"Fit manual QC call", "Event manual QC call"}, {0, 1}, PSX_UNDET)

	// select nothing in x direction
	SetMarquee/W=$psxPlot/HAX=bottom/VAX=$"leftFiltOff" 0, 0, 50, 1

	SetActiveSubwindow $psxPlot
	PSX_MouseEventSelection(PSX_REJECT, PSX_STATE_FIT | PSX_STATE_EVENT)

	[WAVE psxEvent_0, WAVE psxEvent_1] = GetPSXEventWavesHelper(psxPlot)

	CheckPSXEventField({psxEvent_0}, {"Fit manual QC call", "Event manual QC call"}, {0, 1}, PSX_REJECT)
	CheckPSXEventField({psxEvent_1}, {"Fit manual QC call", "Event manual QC call"}, {0, 1}, PSX_UNDET)

	// select nothing in y direction
	SetMarquee/W=$psxPlot/HAX=bottom/VAX=$"leftFiltOff" 50, 1, 200, 10

	SetActiveSubwindow $psxPlot
	PSX_MouseEventSelection(PSX_REJECT, PSX_STATE_FIT | PSX_STATE_EVENT)

	[WAVE psxEvent_0, WAVE psxEvent_1] = GetPSXEventWavesHelper(psxPlot)

	CheckPSXEventField({psxEvent_0}, {"Fit manual QC call", "Event manual QC call"}, {0, 1}, PSX_REJECT)
	CheckPSXEventField({psxEvent_1}, {"Fit manual QC call", "Event manual QC call"}, {0, 1}, PSX_UNDET)
End

static Function/WAVE SupportedPostProcForEventSelection()

	// nonfinite is tested elsewhere
	Make/FREE/T wv = {"nothing", "log10"}
	SetDimensionLabels(wv, AddPrefixToEachListItem("PostProc=", TextWavetoList(wv, ";")), ROWS)

	return wv
End

static Function/WAVE SupportedAxisModesForEventSelection()

	Make/FREE wv = {MODIFY_GRAPH_LOG_MODE_NORMAL, MODIFY_GRAPH_LOG_MODE_LOG10, MODIFY_GRAPH_LOG_MODE_LOG2}
	SetDimensionLabels(wv, "LeftAxis=linear;LeftAxis=log10;LeftAxis=log2", ROWS)

	return wv
End

static Function/S SetupDatabrowserWithSomeData()

	string browser, device

	[browser, device] = CreateEmptyUnlockedDataBrowserWindow()

	browser = CreateFakeSweepData(browser, device, sweepNo = 0, sweepGen = FakeSweepDataGeneratorPSX)
	browser = CreateFakeSweepData(browser, device, sweepNo = 2, sweepGen = FakeSweepDataGeneratorPSX)

	// adjust x-position of sweep 2
	// so sweep 0 has two events and sweep 2 only one but with a different x position
	WAVE/Z sweepWave = GetSweepWave(device, 2)
	CHECK_WAVE(sweepWave, TEXT_WAVE)

	Make/FREE/WAVE/N=(DimSize(sweepWave, ROWS)) input = ResolveSweepChannel(sweepWave, p)
	for(WAVE wv : input)
		SetScale/P x, 25, DimDelta(wv, ROWS), wv
	endfor

	return browser
End

static Function AdaptForPostProc(string postProc, variable val)

	strswitch(postProc)
		case "nothing":
			return val
		case "log10":
			return log(val)
		default:
			ASSERT(0, "Unknown postProc value")
	endswitch
End

/// UTF_TD_GENERATOR v0:SupportedAxisModesForEventSelection
/// UTF_TD_GENERATOR s0:SupportedPostProcForEventSelection
static Function MouseSelectionPSXStats([STRUCT IUTF_mData &m])

	string win, browser, code, psxGraph, psxStatsGraph, postProc
	variable numEvents, logMode

	Make/FREE/T combos = {"Range[50, 150], Sweep [0], Channel [AD6], Device [ITC16_Dev_0]", \
	                      "Range[50, 150], Sweep [2], Channel [AD6], Device [ITC16_Dev_0]"}
	WAVE overrideResults = MIES_PSX#PSX_CreateOverrideResults(4, combos)

	overrideResults[][][%$"Fit Result"] = 1
	overrideResults[][][%$"Tau"]        = 1

	postProc = m.s0
	logMode  = m.v0

	browser = SetupDatabrowserWithSomeData()

	code = GetTestCode(postProc)

	// combo0 is the current one

	ExecuteSweepFormulaCode(browser, code)

	win           = SFH_GetFormulaGraphForBrowser(browser)
	psxGraph      = MIES_PSX#PSX_GetPSXGraph(win)
	psxStatsGraph = MIES_PSX#PSX_GetPSXStatsGraph(psxGraph)

	ModifyGraph/W=$psxStatsGraph log(left)=logMode

	[WAVE psxEvent_0, WAVE psxEvent_1] = GetPSXEventWavesHelper(psxStatsGraph)

	CheckPSXEventField({psxEvent_0}, {"Fit manual QC call", "Event manual QC call"}, {0, 1}, PSX_UNDET)
	CheckPSXEventField({psxEvent_1}, {"Fit manual QC call", "Event manual QC call"}, {0}, PSX_UNDET)

	// required for stats
	DoUpdate

	// select event 0 from combo 0
	SetActiveSubwindow $psxStatsGraph
	SetMarquee/W=$psxStatsGraph/HAX=bottom/VAX=left -0.1, AdaptForPostProc(postProc, 110), 0.1, AdaptForPostProc(postProc, 100)

	PSX_MouseEventSelection(PSX_ACCEPT, PSX_STATE_EVENT)

	// refetch the changed waves after each selection
	[WAVE psxEvent_0, WAVE psxEvent_1] = GetPSXEventWavesHelper(psxStatsGraph)

	// unchanged
	CheckPSXEventField({psxEvent_0}, {"Fit manual QC call", "Event manual QC call"}, {1}, PSX_UNDET)
	CheckPSXEventField({psxEvent_1}, {"Fit manual QC call", "Event manual QC call"}, {0}, PSX_UNDET)

	// changed
	CheckPSXEventField({psxEvent_0}, {"Event manual QC call"}, {0}, PSX_ACCEPT)

	DoUpdate

	// select event 0 from combo 1
	SetActiveSubwindow $psxStatsGraph
	SetMarquee/W=$psxStatsGraph/HAX=bottom/VAX=left -0.1, AdaptForPostProc(postProc, 130), 0.1, AdaptForPostProc(postProc, 125)

	PSX_MouseEventSelection(PSX_REJECT, PSX_STATE_EVENT)

	// refetch the changed waves after each selection
	[WAVE psxEvent_0, WAVE psxEvent_1] = GetPSXEventWavesHelper(psxStatsGraph)

	// unchanged
	CheckPSXEventField({psxEvent_0}, {"Fit manual QC call", "Event manual QC call"}, {1}, PSX_UNDET)
	CheckPSXEventField({psxEvent_0}, {"Event manual QC call"}, {0}, PSX_ACCEPT)
	CheckPSXEventField({psxEvent_1}, {"Fit manual QC call"}, {0}, PSX_UNDET)

	// changed
	CheckPSXEventField({psxEvent_1}, {"Event manual QC call"}, {0}, PSX_REJECT)

	DoUpdate

	// select all events from both combos
	SetActiveSubwindow $psxStatsGraph
	SetMarquee/W=$psxStatsGraph/HAX=bottom/VAX=left -0.1, AdaptForPostProc(postProc, 100), 1.1, AdaptForPostProc(postProc, 140)

	PSX_MouseEventSelection(PSX_UNDET, PSX_STATE_EVENT | PSX_STATE_FIT)

	// refetch the changed waves after each selection
	[WAVE psxEvent_0, WAVE psxEvent_1] = GetPSXEventWavesHelper(psxStatsGraph)

	// changed
	CheckPSXEventField({psxEvent_0}, {"Fit manual QC call", "Event manual QC call"}, {0, 1}, PSX_UNDET)
	CheckPSXEventField({psxEvent_1}, {"Fit manual QC call", "Event manual QC call"}, {0}, PSX_UNDET)
End

static Function MouseSelectionStatsPostProcNonFinite()

	string browser, code, psxGraph, win, mainWindow, psxStatsGraph, trace, tracenames

	Make/FREE/T combos = {"Range[50, 150], Sweep [0], Channel [AD6], Device [ITC16_Dev_0]", \
	                      "Range[50, 150], Sweep [2], Channel [AD6], Device [ITC16_Dev_0]"}
	WAVE overrideResults = MIES_PSX#PSX_CreateOverrideResults(4, combos)

	overrideResults[1][%$combos[0]][%$"Fit Result"] = 1
	overrideResults[1][%$combos[0]][%$"Tau"]        = -Inf

	overrideResults[0][%$combos[0]][%$"Fit Result"] = 0
	overrideResults[0][%$combos[0]][%$"Tau"]        = NaN

	overrideResults[0][%$combos[1]][%$"Fit Result"] = 1
	overrideResults[0][%$combos[1]][%$"Tau"]        = +Inf

	browser = SetupDatabrowserWithSomeData()

	code = GetTestCode("nonfinite", eventState = "all", prop = "tau")

	ExecuteSweepFormulaCode(browser, code)

	win           = SFH_GetFormulaGraphForBrowser(browser)
	mainWindow    = GetMainWindow(win)
	psxGraph      = MIES_PSX#PSX_GetPSXGraph(win)
	psxStatsGraph = MIES_PSX#PSX_GetPSXStatsGraph(psxGraph)

	REQUIRE(WindowExists(psxStatsGraph))

	SetActiveSubwindow $psxStatsGraph

	tracenames = TraceNameList(psxStatsGraph, ";", 1)
	trace      = StringFromList(0, tracenames)
	CHECK_PROPER_STR(trace)

	Cursor/W=$psxStatsGraph/P A, $trace, 0

	CheckCurrentEvent(psxStatsGraph, 0, 0, 0)

	[WAVE psxEvent_0, WAVE psxEvent_1] = GetPSXEventWavesHelper(psxStatsGraph)

	CheckPSXEventField({psxEvent_0}, {"Fit manual QC call"}, {0}, PSX_REJECT)
	CheckPSXEventField({psxEvent_0}, {"Event manual QC call"}, {0}, PSX_UNDET)
	CheckPSXEventField({psxEvent_0}, {"Fit manual QC call", "Event manual QC call"}, {1}, PSX_UNDET)

	CheckPSXEventField({psxEvent_1}, {"Fit manual QC call", "Event manual QC call"}, {0}, PSX_UNDET)

	// select event 0 from combo 1
	SetActiveSubwindow $psxStatsGraph
	SetMarquee/W=$psxStatsGraph/HAX=bottom/VAX=left 0.5, 0.25, 1.5, -0.5

	PSX_MouseEventSelection(PSX_ACCEPT, PSX_STATE_EVENT | PSX_STATE_FIT)

	// refetch the changed waves after each selection
	[WAVE psxEvent_0, WAVE psxEvent_1] = GetPSXEventWavesHelper(psxStatsGraph)

	// unchanged
	CheckPSXEventField({psxEvent_0}, {"Fit manual QC call"}, {0}, PSX_REJECT)
	CheckPSXEventField({psxEvent_0}, {"Event manual QC call"}, {0}, PSX_UNDET)
	CheckPSXEventField({psxEvent_0}, {"Fit manual QC call", "Event manual QC call"}, {1}, PSX_UNDET)

	// changed
	CheckPSXEventField({psxEvent_1}, {"Fit manual QC call", "Event manual QC call"}, {0}, PSX_ACCEPT)
End

static Function/WAVE GetTracesHelper(string win, variable options)

	return ListToTextWave(SortList(TraceNameList(win, ";", options)), ";")
End

static Function CheckTraceColors(string win, WAVE/T traces, variable state)

	string tInfo, rgbValue, trace
	variable numEntries

	[WAVE acceptColors, WAVE rejectColors, WAVE undetColors] = MIES_PSX#PSX_GetEventColors()

	switch(state)
		case PSX_ACCEPT:
			WAVE refColors = acceptColors
			break
		case PSX_REJECT:
			WAVE refColors = rejectColors
			break
		case PSX_UNDET:
			WAVE refColors = undetColors
			break
		case PSX_ALL:
			// black
			Make/FREE refColors = {1, 1, 1}
			break
		default:
			ASSERT(0, "Invalid state")
	endswitch

	for(trace : traces)
		tInfo    = TraceInfo(win, trace, 0)
		rgbValue = StringByKey("rgb(x)", tInfo, "=", ";")
		WAVE traceColors = ListToNumericWave(rgbValue[1, strlen(rgbValue) - 2], ",")

		INFO("trace %s, state %s, rgbValue \"%s\"", s0 = trace, s1 = MIES_PSX#PSX_StateToString(state), s2 = rgbValue)

		// average waves don't have alpha set
		numEntries = DimSize(traceColors, ROWS)
		if(numEntries == 3)
			Redimension/N=(3) refColors
		endif

		CHECK_EQUAL_WAVES(traceColors, refColors, mode = WAVE_DATA)
	endfor
End

// two sweeps in one operation
static Function/S GetTestCode(string postProc, [string eventState, string prop])

	string code

	if(ParamIsDefault(eventState))
		eventState = "all"
	endif

	if(ParamIsDefault(prop))
		prop = "xpos"
	endif

	code  = "psx(myId, psxKernel([50, 150], select(channels(AD6), [0, 2], all)), 1.5, 100, 0)"
	code += "\r and \r"
	code += "psxStats(myId, [50, 150], select(channels(AD6), [0, 2], all), " + prop + ", " + eventState + ", " + postProc + ")"

	return code
End

static Function/WAVE GetCodeVariations()

	string code

	Make/T/N=2/FREE wv

	wv[0] = GetTestCode("nothing")
	code  = ""

	// one sweep per operation separated with `with`
	code  = "psx(myId, psxKernel([50, 150], select(channels(AD6), [0], all)), 10, 100, 0)"
	code += "\r with \r"
	code += "psx(myId, psxKernel([50, 150], select(channels(AD6), [2], all)), 2.5, 100, 0)"
	code += "\r and \r"
	code += "psxStats(myId, [50, 150], select(channels(AD6), [0, 2], all), xpos, all, nothing)"
	wv[1] = code
	code  = ""

	return wv
End

/// IUTF_TD_GENERATOR s0:GetCodeVariations
static Function AllEventGraph([STRUCT IUTF_mData &m])

	string browser, code, extAllGraph, win, trace, info, rgbValue, mainWindow, specialEventPanel
	variable numEvents

	browser = SetupDatabrowserWithSomeData()

	code = m.s0

	// combo0 is the current one

	ExecuteSweepFormulaCode(browser, code)

	win               = SFH_GetFormulaGraphForBrowser(browser)
	mainWindow        = GetMainWindow(win)
	extAllGraph       = MIES_PSX#PSX_GetAllEventGraph(win)
	specialEventPanel = MIES_PSX#PSX_GetSpecialPanel(win)

	REQUIRE(WindowExists(extAllGraph))

	// GUI processing
	DoUpdate

	// check calculated average waves
	DFREF averageGlobalDFR = MIES_PSX#PSX_GetWorkingFolder(win)

	WAVE averageGlobalAccept = GetPSXAverageWave(averageGlobalDFR, PSX_ACCEPT)
	WAVE averageGlobalReject = GetPSXAverageWave(averageGlobalDFR, PSX_REJECT)
	WAVE averageGlobalUndet  = GetPSXAverageWave(averageGlobalDFR, PSX_UNDET)
	WAVE averageGlobalAll    = GetPSXAverageWave(averageGlobalDFR, PSX_ALL)

	CHECK_EQUAL_WAVES(averageGlobalUndet, averageGlobalAll)
	CHECK_EQUAL_VAR(DimSize(averageGlobalAccept, ROWS), 0)
	CHECK_EQUAL_VAR(DimSize(averageGlobalReject, ROWS), 0)
	CHECK_GT_VAR(DimSize(averageGlobalUndet, ROWS), 0)
	CHECK_GT_VAR(DimSize(averageGlobalAll, ROWS), 0)

	WAVE/T allTraces = GetTracesHelper(extAllGraph, 1)

	Make/FREE/T allTracesRef = {"T000000", "T000001",                                                        \
	                            "T000002_averageAccept_ComboIndex0", "T000003_averageReject_ComboIndex0",    \
	                            "T000004_averageUndetermined_ComboIndex0", "T000005_averageAll_ComboIndex0", \
	                            "T000006_acceptAverageFit_ComboIndex0",                                      \
	                            "T000007",                                                                   \
	                            "T000008_averageAccept_ComboIndex1", "T000009_averageReject_ComboIndex1",    \
	                            "T000010_averageUndetermined_ComboIndex1", "T000011_averageAll_ComboIndex1", \
	                            "T000012_acceptAverageFit_ComboIndex1",                                      \
	                            "T000013_averageAccept_global", "T000014_averageReject_global",              \
	                            "T000015_averageUndetermined_global", "T000016_averageAll_global",           \
	                            "T000017_acceptAverageFit_global"}

	CHECK_EQUAL_TEXTWAVES(allTracesRef, allTraces)

	// currently shown traces
	WAVE/T dispTraces = GetTracesHelper(extAllGraph, 1 + 2^2)
	Make/FREE/T dispTracesRef = {"T000000", "T000001", "T000007"}
	CHECK_EQUAL_TEXTWAVES(dispTracesRef, dispTraces)

	CheckTraceColors(extAllGraph, dispTraces, PSX_UNDET)

	// no change when we change the combo as "Current combo" is unchecked
	PGC_SetAndActivateControl(mainWindow, "listbox_select_combo", val = 1)

	WAVE/T dispTraces = GetTracesHelper(extAllGraph, 1 + 2^2)
	CheckTraceColors(extAllGraph, dispTraces, PSX_UNDET)

	// no change when turning off accept/reject
	PGC_SetAndActivateControl(specialEventPanel, "checkbox_single_events_accept", val = 0)
	PGC_SetAndActivateControl(specialEventPanel, "checkbox_single_events_reject", val = 0)

	WAVE/T dispTraces = GetTracesHelper(extAllGraph, 1 + 2^2)
	CheckTraceColors(extAllGraph, dispTraces, PSX_UNDET)

	// no traces with undet being unchecked
	PGC_SetAndActivateControl(specialEventPanel, "checkbox_single_events_undetermined", val = 0)
	WAVE/T dispTraces = GetTracesHelper(extAllGraph, 1 + 2^2)
	Make/FREE/T/N=0 dispTracesRef
	CHECK_EQUAL_TEXTWAVES(dispTracesRef, dispTraces)

	// only global average undet
	PGC_SetAndActivateControl(specialEventPanel, "checkbox_average_events_accept", val = 0)
	PGC_SetAndActivateControl(specialEventPanel, "checkbox_average_events_reject", val = 0)
	PGC_SetAndActivateControl(specialEventPanel, "checkbox_average_events_undetermined", val = 1)

	WAVE/T dispTraces = GetTracesHelper(extAllGraph, 1 + 2^2)
	Make/FREE/T dispTracesRef = {"T000015_averageUndetermined_global"}
	CHECK_EQUAL_TEXTWAVES(dispTracesRef, dispTraces)

	CheckTraceColors(extAllGraph, dispTraces, PSX_UNDET)

	// only global average all
	PGC_SetAndActivateControl(specialEventPanel, "checkbox_average_events_undetermined", val = 0)
	PGC_SetAndActivateControl(specialEventPanel, "checkbox_average_events_all", val = 1)

	WAVE/T dispTraces = GetTracesHelper(extAllGraph, 1 + 2^2)
	Make/FREE/T dispTracesRef = {"T000016_averageAll_global"}
	CHECK_EQUAL_TEXTWAVES(dispTracesRef, dispTraces)

	CheckTraceColors(extAllGraph, dispTraces, PSX_ALL)

	// restrict to current combo
	PGC_SetAndActivateControl(specialEventPanel, "checkbox_restrict_events_to_current_combination", val = 1)
	WAVE/T dispTraces = GetTracesHelper(extAllGraph, 1 + 2^2)
	Make/FREE/T dispTracesRef = {"T000011_averageAll_ComboIndex1"}
	CHECK_EQUAL_TEXTWAVES(dispTracesRef, dispTraces)

	CheckTraceColors(extAllGraph, dispTraces, PSX_ALL)

	// check average wave contents

	// combo1

	// all
	WAVE averageWaveFromTrace = TraceNameToWaveRef(extAllGraph, "T000011_averageAll_ComboIndex1")

	DFREF comboDFR       = MIES_PSX#PSX_GetCurrentComboFolder(win)
	DFREF singleEventDFR = GetPSXSingleEventFolder(comboDFR)

	WAVE/WAVE singleEventWaves = ListToWaveRefWave(GetListOfObjects(singleEventDFR, ".*", fullPath = 1))
	CHECK_EQUAL_VAR(DimSize(singleEventWaves, ROWS), 1)
	CHECK_EQUAL_WAVES(singleEventWaves[0], averageWaveFromTrace, mode = WAVE_DATA)

	// same as undet
	PGC_SetAndActivateControl(specialEventPanel, "checkbox_average_events_undetermined", val = 1)
	PGC_SetAndActivateControl(specialEventPanel, "checkbox_average_events_all", val = 0)

	WAVE averageWaveFromTrace = TraceNameToWaveRef(extAllGraph, "T000010_averageUndetermined_ComboIndex1")
	CHECK_EQUAL_WAVES(singleEventWaves[0], averageWaveFromTrace, mode = WAVE_DATA)

	// combo0
	PGC_SetAndActivateControl(mainWindow, "listbox_select_combo", val = 0)

	DoUpdate

	// all
	PGC_SetAndActivateControl(specialEventPanel, "checkbox_average_events_undetermined", val = 0)
	PGC_SetAndActivateControl(specialEventPanel, "checkbox_average_events_all", val = 1)

	WAVE averageWaveFromTrace = TraceNameToWaveRef(extAllGraph, "T000005_averageAll_ComboIndex0")

	DFREF comboDFR       = MIES_PSX#PSX_GetCurrentComboFolder(win)
	DFREF singleEventDFR = GetPSXSingleEventFolder(comboDFR)

	WAVE/WAVE singleEventWaves = ListToWaveRefWave(GetListOfObjects(singleEventDFR, ".*", fullPath = 1))
	CHECK_EQUAL_VAR(DimSize(singleEventWaves, ROWS), 2)
	WAVE/WAVE/Z calcAvgPack = MIES_fWaveAverage(singleEventWaves, 1, IGOR_TYPE_64BIT_FLOAT)
	CHECK_WAVE(calcAvgPack, WAVE_WAVE)
	WAVE/Z calcAvg = calcAvgPack[0]
	CHECK_WAVE(calcAvg, NUMERIC_WAVE, minorType = DOUBLE_WAVE)
	CHECK_EQUAL_WAVES(calcAvg, averageWaveFromTrace, mode = WAVE_DATA)

	// same as undet
	PGC_SetAndActivateControl(specialEventPanel, "checkbox_average_events_undetermined", val = 1)
	PGC_SetAndActivateControl(specialEventPanel, "checkbox_average_events_all", val = 0)

	WAVE averageWaveFromTrace = TraceNameToWaveRef(extAllGraph, "T000004_averageUndetermined_ComboIndex0")
	CHECK_EQUAL_WAVES(calcAvg, averageWaveFromTrace, mode = WAVE_DATA)

	// now let's change some event/fit states
	PGC_SetAndActivateControl(specialEventPanel, "checkbox_single_events_accept", val = 1)
	PGC_SetAndActivateControl(specialEventPanel, "checkbox_single_events_reject", val = 1)
	PGC_SetAndActivateControl(specialEventPanel, "checkbox_single_events_undetermined", val = 1)

	PGC_SetAndActivateControl(specialEventPanel, "checkbox_average_events_accept", val = 0)
	PGC_SetAndActivateControl(specialEventPanel, "checkbox_average_events_reject", val = 0)
	PGC_SetAndActivateControl(specialEventPanel, "checkbox_average_events_undetermined", val = 0)
	PGC_SetAndActivateControl(specialEventPanel, "checkbox_average_events_all", val = 0)

	// still only undet traces shown as we use the event state by default
	MIES_PSX#PSX_UpdateEventWaves(win, val = PSX_REJECT, index = 0, stateType = PSX_STATE_FIT)
	MIES_PSX#PSX_UpdateEventWaves(win, val = PSX_ACCEPT, index = 1, stateType = PSX_STATE_FIT)

	WAVE/T dispTraces = GetTracesHelper(extAllGraph, 1 + 2^2)
	Make/FREE/T dispTracesRef = {"T000000", "T000001"}
	CHECK_EQUAL_TEXTWAVES(dispTracesRef, dispTraces)

	CheckTraceColors(extAllGraph, dispTraces, PSX_UNDET)

	// change to fit state
	PGC_SetAndActivateControl(specialEventPanel, "popupmenu_state_type", str = "Fit*")

	DoUpdate

	WAVE/T dispTraces = GetTracesHelper(extAllGraph, 1 + 2^2)
	Make/FREE/T dispTracesRef = {"T000000", "T000001"}
	CHECK_EQUAL_TEXTWAVES(dispTracesRef, dispTraces)

	CheckTraceColors(extAllGraph, {"T000000"}, PSX_REJECT)
	CheckTraceColors(extAllGraph, {"T000001"}, PSX_ACCEPT)

	// change event 1 to event state reject
	MIES_PSX#PSX_UpdateEventWaves(win, val = PSX_REJECT, index = 1, stateType = PSX_STATE_EVENT)

	// and disable reject
	PGC_SetAndActivateControl(specialEventPanel, "checkbox_single_events_reject", val = 0)

	// and change back to event state
	PGC_SetAndActivateControl(specialEventPanel, "popupmenu_state_type", str = "Event*")

	WAVE/T dispTraces = GetTracesHelper(extAllGraph, 1 + 2^2)
	Make/FREE/T dispTracesRef = {"T000000"}
	CHECK_EQUAL_TEXTWAVES(dispTracesRef, dispTraces)
End

static Function JumpToUndet()

	string browser, code, psxGraph, win, mainWindow

	browser = SetupDatabrowserWithSomeData()

	code = GetTestCode("nothing")

	// combo0 is the current one

	ExecuteSweepFormulaCode(browser, code)

	win        = SFH_GetFormulaGraphForBrowser(browser)
	mainWindow = GetMainWindow(win)
	psxGraph   = MIES_PSX#PSX_GetPSXGraph(win)

	REQUIRE(WindowExists(psxGraph))

	// GUI processing
	DoUpdate

	// nothing happens as the currently selected event is already undetermined
	PGC_SetAndActivateControl(mainWindow, "button_jump_first_undet")
	CHECK_EQUAL_VAR(pcsr(A, psxGraph), 0)
	CHECK_EQUAL_VAR(MIES_PSX#PSX_GetCurrentComboIndex(win), 0)

	// reject event state event 0
	MIES_PSX#PSX_UpdateEventWaves(win, val = PSX_REJECT, index = 0, stateType = PSX_STATE_EVENT, comboIndex = 0)

	// reject fit state event 0
	MIES_PSX#PSX_UpdateEventWaves(win, val = PSX_ACCEPT, index = 1, stateType = PSX_STATE_FIT, comboIndex = 0)

	// as we look only at the event state we now find event 1
	PGC_SetAndActivateControl(mainWindow, "button_jump_first_undet")
	CHECK_EQUAL_VAR(pcsr(A, psxGraph), 1)
	CHECK_EQUAL_VAR(MIES_PSX#PSX_GetCurrentComboIndex(win), 0)

	// reject event state event 1
	MIES_PSX#PSX_UpdateEventWaves(win, val = PSX_REJECT, index = 1, stateType = PSX_STATE_EVENT, comboIndex = 0)

	// find event 0 of next combo
	PGC_SetAndActivateControl(mainWindow, "button_jump_first_undet")
	CHECK_EQUAL_VAR(pcsr(A, psxGraph), 0)
	CHECK_EQUAL_VAR(MIES_PSX#PSX_GetCurrentComboIndex(win), 1)

	// undet event state event 1 of combo 0
	MIES_PSX#PSX_UpdateEventWaves(win, val = PSX_UNDET, index = 1, stateType = PSX_STATE_EVENT, comboIndex = 0)

	// reject current event
	MIES_PSX#PSX_UpdateEventWaves(win, val = PSX_REJECT, index = 0, stateType = PSX_STATE_EVENT, comboIndex = 1)

	// search wraps around
	PGC_SetAndActivateControl(mainWindow, "button_jump_first_undet")
	CHECK_EQUAL_VAR(pcsr(A, psxGraph), 1)
	CHECK_EQUAL_VAR(MIES_PSX#PSX_GetCurrentComboIndex(win), 0)
End

/// UTF_TD_GENERATOR v0:SupportedAxisModesForEventSelection
/// UTF_TD_GENERATOR s0:SupportedPostProcForEventSelection
static Function JumpToSelectedEvents([STRUCT IUTF_mData &m])

	string browser, code, psxGraph, win, mainWindow, postProc, psxStatsGraph
	variable logMode

	postProc = m.s0
	logMode  = m.v0

	browser = SetupDatabrowserWithSomeData()
	code    = GetTestCode(postProc)

	// combo0 is the current one

	ExecuteSweepFormulaCode(browser, code)

	win           = SFH_GetFormulaGraphForBrowser(browser)
	mainWindow    = GetMainWindow(win)
	psxGraph      = MIES_PSX#PSX_GetPSXGraph(win)
	psxStatsGraph = MIES_PSX#PSX_GetPSXStatsGraph(psxGraph)

	REQUIRE(WindowExists(psxGraph))

	ModifyGraph/W=$psxStatsGraph log(left)=logMode

	// GUI processing
	DoUpdate

	// select event 0, combo 1
	SetActiveSubwindow $psxStatsGraph
	SetMarquee/W=$psxStatsGraph/HAX=bottom/VAX=left -0.1, AdaptForPostProc(postProc, 130), 0.1, AdaptForPostProc(postProc, 125)

	PSX_JumpToEvents()

	CHECK_EQUAL_VAR(pcsr(A, psxGraph), 0)
	CHECK_EQUAL_VAR(MIES_PSX#PSX_GetCurrentComboIndex(win), 1)

	// select all events
	SetActiveSubwindow $psxStatsGraph
	SetMarquee/W=$psxStatsGraph/HAX=bottom/VAX=left -0.1, AdaptForPostProc(postProc, 130), 1.1, AdaptForPostProc(postProc, 100)

	PSX_JumpToEvents()

	CHECK_EQUAL_VAR(pcsr(A, psxGraph), 0)
	CHECK_EQUAL_VAR(MIES_PSX#PSX_GetCurrentComboIndex(win), 1)
End

static StrConstant PSXGRAPH_REF_TRACE = "PeakY"

static Function CheckCurrentEvent(string win, variable comboIndex, variable eventIndex, variable waveIndex)

	string singleEventGraph, annoInfo

	INFO("win %s comboIndex %d, eventIndex %d, waveIndex %d", s0 = win, n0 = comboIndex, n1 = eventIndex, n2 = waveIndex)

	singleEventGraph = MIES_PSX#PSX_GetSingleEventGraph(win)

	CHECK_EQUAL_VAR(pcsr(A, win), waveIndex)
	CHECK_EQUAL_VAR(MIES_PSX#PSX_GetCurrentComboIndex(win), comboIndex)
	annoInfo = AnnotationInfo(singleEventGraph, "description")
	CHECK(GrepString(annoInfo, "Event:[[:space:]]*" + num2istr(eventIndex)))
End

static Function CursorMovement()

	string browser, code, psxGraph, win, mainWindow

	browser = SetupDatabrowserWithSomeData()

	code = GetTestCode("nothing")

	// combo0 is the current one

	ExecuteSweepFormulaCode(browser, code)

	win        = SFH_GetFormulaGraphForBrowser(browser)
	mainWindow = GetMainWindow(win)
	psxGraph   = MIES_PSX#PSX_GetPSXGraph(win)

	REQUIRE(WindowExists(psxGraph))

	// GUI processing
	DoUpdate

	CheckCurrentEvent(psxGraph, 0, 0, 0)

	Cursor/W=$psxGraph/P A, $PSXGRAPH_REF_TRACE, 1
	DoUpdate

	CheckCurrentEvent(psxGraph, 0, 1, 1)

	// change to combo 1
	PGC_SetAndActivateControl(mainWindow, "listbox_select_combo", val = 1)

	CheckCurrentEvent(psxGraph, 1, 0, 0)
End

static Function CursorMovementStats()

	string browser, code, psxGraph, win, mainWindow, psxStatsGraph, trace, tracenames

	browser = SetupDatabrowserWithSomeData()

	code = GetTestCode("nothing")

	// combo0 is the current one

	ExecuteSweepFormulaCode(browser, code)

	win           = SFH_GetFormulaGraphForBrowser(browser)
	mainWindow    = GetMainWindow(win)
	psxGraph      = MIES_PSX#PSX_GetPSXGraph(win)
	psxStatsGraph = MIES_PSX#PSX_GetPSXStatsGraph(psxGraph)

	REQUIRE(WindowExists(psxStatsGraph))

	// GUI processing
	DoUpdate

	tracenames = TraceNameList(psxStatsGraph, ";", 1)
	trace      = StringFromList(0, tracenames)
	CHECK_PROPER_STR(trace)

	Cursor/W=$psxStatsGraph/P A, $trace, 0

	CheckCurrentEvent(psxStatsGraph, 0, 0, 0)
	CheckCurrentEvent(psxGraph, 0, 0, 0)

	Cursor/W=$psxStatsGraph/P A, $trace, 1

	CheckCurrentEvent(psxStatsGraph, 0, 1, 1)
	CheckCurrentEvent(psxGraph, 0, 1, 1)

	Cursor/W=$psxStatsGraph/P A, $trace, 2

	CheckCurrentEvent(psxStatsGraph, 1, 0, 2)
	CheckCurrentEvent(psxGraph, 1, 0, 0)
End

static Function SendKey(string win, variable key)

	STRUCT WMWinHookStruct s

	s.winName   = win
	s.eventCode = 11
	s.keyCode   = key

	MIES_PSX#PSX_PlotInteractionHook(s)
End

static Function KeyboardInteractions()

	string browser, code, psxGraph, win, mainWindow, psxStatsGraph, trace, tracenames

	Make/FREE/T combos = {"Range[50, 150], Sweep [0], Channel [AD6], Device [ITC16_Dev_0]", \
	                      "Range[50, 150], Sweep [2], Channel [AD6], Device [ITC16_Dev_0]"}
	WAVE overrideResults = MIES_PSX#PSX_CreateOverrideResults(4, combos)

	overrideResults[][][%$"Fit Result"] = 1
	overrideResults[][][%$"Tau"]        = 1

	browser = SetupDatabrowserWithSomeData()

	code = GetTestCode("nothing")

	ExecuteSweepFormulaCode(browser, code)

	DoUpdate

	win           = SFH_GetFormulaGraphForBrowser(browser)
	mainWindow    = GetMainWindow(win)
	psxGraph      = MIES_PSX#PSX_GetPSXGraph(win)
	psxStatsGraph = MIES_PSX#PSX_GetPSXStatsGraph(psxGraph)

	REQUIRE(WindowExists(psxStatsGraph))

	SetActiveSubwindow $psxGraph

	CheckCurrentEvent(psxGraph, 0, 0, 0)

	[WAVE psxEvent_0, WAVE psxEvent_1] = GetPSXEventWavesHelper(psxGraph)

	CheckPSXEventField({psxEvent_0}, {"Fit manual QC call", "Event manual QC call"}, {0, 1}, PSX_UNDET)
	CheckPSXEventField({psxEvent_1}, {"Fit manual QC call", "Event manual QC call"}, {0}, PSX_UNDET)

	SendKey(psxGraph, UP_KEY)

	DoUpdate

	CheckCurrentEvent(psxGraph, 0, 1, 1)

	[WAVE psxEvent_0, WAVE psxEvent_1] = GetPSXEventWavesHelper(psxGraph)

	CheckPSXEventField({psxEvent_0}, {"Fit manual QC call", "Event manual QC call"}, {0}, PSX_ACCEPT)
	CheckPSXEventField({psxEvent_0}, {"Fit manual QC call", "Event manual QC call"}, {1}, PSX_UNDET)
	CheckPSXEventField({psxEvent_1}, {"Fit manual QC call", "Event manual QC call"}, {0}, PSX_UNDET)

	SendKey(psxGraph, DOWN_KEY)

	DoUpdate

	CheckCurrentEvent(psxGraph, 1, 0, 0)

	[WAVE psxEvent_0, WAVE psxEvent_1] = GetPSXEventWavesHelper(psxGraph)

	CheckPSXEventField({psxEvent_0}, {"Fit manual QC call", "Event manual QC call"}, {0}, PSX_ACCEPT)
	CheckPSXEventField({psxEvent_0}, {"Fit manual QC call", "Event manual QC call"}, {1}, PSX_REJECT)
	CheckPSXEventField({psxEvent_1}, {"Fit manual QC call", "Event manual QC call"}, {0}, PSX_UNDET)

	SendKey(psxGraph, LEFT_KEY)

	DoUpdate

	// cursor changed
	CheckCurrentEvent(psxGraph, 0, 1, 1)

	[WAVE psxEvent_0, WAVE psxEvent_1] = GetPSXEventWavesHelper(psxGraph)

	// but not the event/fit states
	CheckPSXEventField({psxEvent_0}, {"Fit manual QC call", "Event manual QC call"}, {0}, PSX_ACCEPT)
	CheckPSXEventField({psxEvent_0}, {"Fit manual QC call", "Event manual QC call"}, {1}, PSX_REJECT)
	CheckPSXEventField({psxEvent_1}, {"Fit manual QC call", "Event manual QC call"}, {0}, PSX_UNDET)

	SendKey(psxGraph, LEFT_KEY)

	DoUpdate

	// cursor changed
	CheckCurrentEvent(psxGraph, 0, 0, 0)

	[WAVE psxEvent_0, WAVE psxEvent_1] = GetPSXEventWavesHelper(psxGraph)

	// but not the event/fit states
	CheckPSXEventField({psxEvent_0}, {"Fit manual QC call", "Event manual QC call"}, {0}, PSX_ACCEPT)
	CheckPSXEventField({psxEvent_0}, {"Fit manual QC call", "Event manual QC call"}, {1}, PSX_REJECT)
	CheckPSXEventField({psxEvent_1}, {"Fit manual QC call", "Event manual QC call"}, {0}, PSX_UNDET)

	SendKey(psxGraph, C_KEY)

	DoUpdate

	// only changes axis scaling
	CheckCurrentEvent(psxGraph, 0, 0, 0)

	[WAVE psxEvent_0, WAVE psxEvent_1] = GetPSXEventWavesHelper(psxGraph)

	// and not the event/fit states
	CheckPSXEventField({psxEvent_0}, {"Fit manual QC call", "Event manual QC call"}, {0}, PSX_ACCEPT)
	CheckPSXEventField({psxEvent_0}, {"Fit manual QC call", "Event manual QC call"}, {1}, PSX_REJECT)
	CheckPSXEventField({psxEvent_1}, {"Fit manual QC call", "Event manual QC call"}, {0}, PSX_UNDET)

	SendKey(psxGraph, R_KEY)
	// we are now going backwards
	SendKey(psxGraph, DOWN_KEY)

	DoUpdate

	CheckCurrentEvent(psxGraph, 1, 0, 0)

	[WAVE psxEvent_0, WAVE psxEvent_1] = GetPSXEventWavesHelper(psxGraph)

	CheckPSXEventField({psxEvent_0}, {"Fit manual QC call", "Event manual QC call"}, {0}, PSX_REJECT)
	CheckPSXEventField({psxEvent_0}, {"Fit manual QC call", "Event manual QC call"}, {1}, PSX_REJECT)
	CheckPSXEventField({psxEvent_1}, {"Fit manual QC call", "Event manual QC call"}, {0}, PSX_UNDET)

	SendKey(psxGraph, -1)

	DoUpdate

	// ignores unkonwn key
	CheckCurrentEvent(psxGraph, 1, 0, 0)

	[WAVE psxEvent_0, WAVE psxEvent_1] = GetPSXEventWavesHelper(psxGraph)

	CheckPSXEventField({psxEvent_0}, {"Fit manual QC call", "Event manual QC call"}, {0}, PSX_REJECT)
	CheckPSXEventField({psxEvent_0}, {"Fit manual QC call", "Event manual QC call"}, {1}, PSX_REJECT)
	CheckPSXEventField({psxEvent_1}, {"Fit manual QC call", "Event manual QC call"}, {0}, PSX_UNDET)

	SendKey(psxGraph, E_KEY)

	DoUpdate

	// no cursor change
	CheckCurrentEvent(psxGraph, 1, 0, 0)

	[WAVE psxEvent_0, WAVE psxEvent_1] = GetPSXEventWavesHelper(psxGraph)

	CheckPSXEventField({psxEvent_0}, {"Fit manual QC call", "Event manual QC call"}, {0}, PSX_REJECT)
	CheckPSXEventField({psxEvent_0}, {"Fit manual QC call", "Event manual QC call"}, {1}, PSX_REJECT)
	CheckPSXEventField({psxEvent_1}, {"Fit manual QC call"}, {0}, PSX_UNDET)
	CheckPSXEventField({psxEvent_1}, {"Event manual QC call"}, {0}, PSX_ACCEPT)

	// and e again, we are toggling!

	SendKey(psxGraph, E_KEY)

	DoUpdate

	// no cursor change
	CheckCurrentEvent(psxGraph, 1, 0, 0)

	[WAVE psxEvent_0, WAVE psxEvent_1] = GetPSXEventWavesHelper(psxGraph)

	CheckPSXEventField({psxEvent_0}, {"Fit manual QC call", "Event manual QC call"}, {0}, PSX_REJECT)
	CheckPSXEventField({psxEvent_0}, {"Fit manual QC call", "Event manual QC call"}, {1}, PSX_REJECT)
	CheckPSXEventField({psxEvent_1}, {"Fit manual QC call"}, {0}, PSX_UNDET)
	CheckPSXEventField({psxEvent_1}, {"Event manual QC call"}, {0}, PSX_REJECT)

	SendKey(psxGraph, F_KEY)

	DoUpdate

	// no cursor change
	CheckCurrentEvent(psxGraph, 1, 0, 0)

	[WAVE psxEvent_0, WAVE psxEvent_1] = GetPSXEventWavesHelper(psxGraph)

	CheckPSXEventField({psxEvent_0}, {"Fit manual QC call", "Event manual QC call"}, {0}, PSX_REJECT)
	CheckPSXEventField({psxEvent_0}, {"Fit manual QC call", "Event manual QC call"}, {1}, PSX_REJECT)
	CheckPSXEventField({psxEvent_1}, {"Fit manual QC call"}, {0}, PSX_ACCEPT)
	CheckPSXEventField({psxEvent_1}, {"Event manual QC call"}, {0}, PSX_REJECT)

	// and again
	SendKey(psxGraph, F_KEY)

	DoUpdate

	// no cursor change
	CheckCurrentEvent(psxGraph, 1, 0, 0)

	[WAVE psxEvent_0, WAVE psxEvent_1] = GetPSXEventWavesHelper(psxGraph)

	CheckPSXEventField({psxEvent_0}, {"Fit manual QC call", "Event manual QC call"}, {0}, PSX_REJECT)
	CheckPSXEventField({psxEvent_0}, {"Fit manual QC call", "Event manual QC call"}, {1}, PSX_REJECT)
	CheckPSXEventField({psxEvent_1}, {"Fit manual QC call"}, {0}, PSX_REJECT)
	CheckPSXEventField({psxEvent_1}, {"Event manual QC call"}, {0}, PSX_REJECT)

	SendKey(psxGraph, SPACE_KEY)

	DoUpdate

	// no cursor change
	CheckCurrentEvent(psxGraph, 1, 0, 0)

	[WAVE psxEvent_0, WAVE psxEvent_1] = GetPSXEventWavesHelper(psxGraph)

	CheckPSXEventField({psxEvent_0}, {"Fit manual QC call", "Event manual QC call"}, {0}, PSX_REJECT)
	CheckPSXEventField({psxEvent_0}, {"Fit manual QC call", "Event manual QC call"}, {1}, PSX_REJECT)
	CheckPSXEventField({psxEvent_1}, {"Fit manual QC call"}, {0}, PSX_UNDET)
	CheckPSXEventField({psxEvent_1}, {"Event manual QC call"}, {0}, PSX_UNDET)

	SendKey(psxGraph, SPACE_KEY)

	DoUpdate

	// no cursor change
	CheckCurrentEvent(psxGraph, 1, 0, 0)

	[WAVE psxEvent_0, WAVE psxEvent_1] = GetPSXEventWavesHelper(psxGraph)

	CheckPSXEventField({psxEvent_0}, {"Fit manual QC call", "Event manual QC call"}, {0}, PSX_REJECT)
	CheckPSXEventField({psxEvent_0}, {"Fit manual QC call", "Event manual QC call"}, {1}, PSX_REJECT)
	CheckPSXEventField({psxEvent_1}, {"Fit manual QC call"}, {0}, PSX_ACCEPT)
	CheckPSXEventField({psxEvent_1}, {"Event manual QC call"}, {0}, PSX_ACCEPT)
End

static Function KeyboardInteractionsStats()

	string browser, code, psxGraph, win, mainWindow, psxStatsGraph, trace, tracenames

	Make/FREE/T combos = {"Range[50, 150], Sweep [0], Channel [AD6], Device [ITC16_Dev_0]", \
	                      "Range[50, 150], Sweep [2], Channel [AD6], Device [ITC16_Dev_0]"}
	WAVE overrideResults = MIES_PSX#PSX_CreateOverrideResults(4, combos)

	overrideResults[][][%$"Fit Result"] = 1
	overrideResults[][][%$"Tau"]        = 1

	browser = SetupDatabrowserWithSomeData()

	code = GetTestCode("nothing")

	ExecuteSweepFormulaCode(browser, code)

	win           = SFH_GetFormulaGraphForBrowser(browser)
	mainWindow    = GetMainWindow(win)
	psxGraph      = MIES_PSX#PSX_GetPSXGraph(win)
	psxStatsGraph = MIES_PSX#PSX_GetPSXStatsGraph(psxGraph)

	REQUIRE(WindowExists(psxStatsGraph))

	SetActiveSubwindow $psxStatsGraph

	tracenames = TraceNameList(psxStatsGraph, ";", 1)
	trace      = StringFromList(0, tracenames)
	CHECK_PROPER_STR(trace)

	Cursor/W=$psxStatsGraph/P A, $trace, 0

	CheckCurrentEvent(psxStatsGraph, 0, 0, 0)

	[WAVE psxEvent_0, WAVE psxEvent_1] = GetPSXEventWavesHelper(psxStatsGraph)

	CheckPSXEventField({psxEvent_0}, {"Fit manual QC call", "Event manual QC call"}, {0, 1}, PSX_UNDET)
	CheckPSXEventField({psxEvent_1}, {"Fit manual QC call", "Event manual QC call"}, {0}, PSX_UNDET)

	SendKey(psxStatsGraph, UP_KEY)

	DoUpdate

	CheckCurrentEvent(psxStatsGraph, 0, 1, 1)

	[WAVE psxEvent_0, WAVE psxEvent_1] = GetPSXEventWavesHelper(psxStatsGraph)

	CheckPSXEventField({psxEvent_0}, {"Fit manual QC call", "Event manual QC call"}, {0}, PSX_ACCEPT)
	CheckPSXEventField({psxEvent_0}, {"Fit manual QC call", "Event manual QC call"}, {1}, PSX_UNDET)
	CheckPSXEventField({psxEvent_1}, {"Fit manual QC call", "Event manual QC call"}, {0}, PSX_UNDET)

	SendKey(psxStatsGraph, DOWN_KEY)

	DoUpdate

	CheckCurrentEvent(psxStatsGraph, 1, 0, 2)

	[WAVE psxEvent_0, WAVE psxEvent_1] = GetPSXEventWavesHelper(psxStatsGraph)

	CheckPSXEventField({psxEvent_0}, {"Fit manual QC call", "Event manual QC call"}, {0}, PSX_ACCEPT)
	CheckPSXEventField({psxEvent_0}, {"Fit manual QC call", "Event manual QC call"}, {1}, PSX_REJECT)
	CheckPSXEventField({psxEvent_1}, {"Fit manual QC call", "Event manual QC call"}, {0}, PSX_UNDET)

	SendKey(psxStatsGraph, LEFT_KEY)

	DoUpdate

	// cursor changed
	CheckCurrentEvent(psxStatsGraph, 0, 1, 1)

	[WAVE psxEvent_0, WAVE psxEvent_1] = GetPSXEventWavesHelper(psxStatsGraph)

	// but not the event/fit states
	CheckPSXEventField({psxEvent_0}, {"Fit manual QC call", "Event manual QC call"}, {0}, PSX_ACCEPT)
	CheckPSXEventField({psxEvent_0}, {"Fit manual QC call", "Event manual QC call"}, {1}, PSX_REJECT)
	CheckPSXEventField({psxEvent_1}, {"Fit manual QC call", "Event manual QC call"}, {0}, PSX_UNDET)

	SendKey(psxStatsGraph, LEFT_KEY)

	DoUpdate

	// cursor changed
	CheckCurrentEvent(psxStatsGraph, 0, 0, 0)

	[WAVE psxEvent_0, WAVE psxEvent_1] = GetPSXEventWavesHelper(psxStatsGraph)

	// but not the event/fit states
	CheckPSXEventField({psxEvent_0}, {"Fit manual QC call", "Event manual QC call"}, {0}, PSX_ACCEPT)
	CheckPSXEventField({psxEvent_0}, {"Fit manual QC call", "Event manual QC call"}, {1}, PSX_REJECT)
	CheckPSXEventField({psxEvent_1}, {"Fit manual QC call", "Event manual QC call"}, {0}, PSX_UNDET)

	SendKey(psxStatsGraph, C_KEY)

	DoUpdate

	// only changes axis scaling
	CheckCurrentEvent(psxStatsGraph, 0, 0, 0)

	[WAVE psxEvent_0, WAVE psxEvent_1] = GetPSXEventWavesHelper(psxStatsGraph)

	// and not the event/fit states
	CheckPSXEventField({psxEvent_0}, {"Fit manual QC call", "Event manual QC call"}, {0}, PSX_ACCEPT)
	CheckPSXEventField({psxEvent_0}, {"Fit manual QC call", "Event manual QC call"}, {1}, PSX_REJECT)
	CheckPSXEventField({psxEvent_1}, {"Fit manual QC call", "Event manual QC call"}, {0}, PSX_UNDET)

	SendKey(psxStatsGraph, R_KEY)
	// we are now going backwards
	SendKey(psxStatsGraph, DOWN_KEY)

	DoUpdate

	// we don't wrap-around in the stats graph
	CheckCurrentEvent(psxStatsGraph, 0, 0, 0)

	[WAVE psxEvent_0, WAVE psxEvent_1] = GetPSXEventWavesHelper(psxStatsGraph)

	CheckPSXEventField({psxEvent_0}, {"Fit manual QC call", "Event manual QC call"}, {0}, PSX_REJECT)
	CheckPSXEventField({psxEvent_0}, {"Fit manual QC call", "Event manual QC call"}, {1}, PSX_REJECT)
	CheckPSXEventField({psxEvent_1}, {"Fit manual QC call", "Event manual QC call"}, {0}, PSX_UNDET)

	// correct for below tests assuming a certain position
	SendKey(psxStatsGraph, RIGHT_KEY)
	SendKey(psxStatsGraph, RIGHT_KEY)

	CheckCurrentEvent(psxStatsGraph, 1, 0, 2)

	SendKey(psxStatsGraph, -1)

	DoUpdate

	// ignores unkonwn key
	CheckCurrentEvent(psxStatsGraph, 1, 0, 2)

	[WAVE psxEvent_0, WAVE psxEvent_1] = GetPSXEventWavesHelper(psxStatsGraph)

	CheckPSXEventField({psxEvent_0}, {"Fit manual QC call", "Event manual QC call"}, {0}, PSX_REJECT)
	CheckPSXEventField({psxEvent_0}, {"Fit manual QC call", "Event manual QC call"}, {1}, PSX_REJECT)
	CheckPSXEventField({psxEvent_1}, {"Fit manual QC call", "Event manual QC call"}, {0}, PSX_UNDET)

	SendKey(psxStatsGraph, E_KEY)

	DoUpdate

	// no cursor change
	CheckCurrentEvent(psxStatsGraph, 1, 0, 2)

	[WAVE psxEvent_0, WAVE psxEvent_1] = GetPSXEventWavesHelper(psxStatsGraph)

	CheckPSXEventField({psxEvent_0}, {"Fit manual QC call", "Event manual QC call"}, {0}, PSX_REJECT)
	CheckPSXEventField({psxEvent_0}, {"Fit manual QC call", "Event manual QC call"}, {1}, PSX_REJECT)
	CheckPSXEventField({psxEvent_1}, {"Fit manual QC call"}, {0}, PSX_UNDET)
	CheckPSXEventField({psxEvent_1}, {"Event manual QC call"}, {0}, PSX_ACCEPT)

	// and e again, we are toggling!

	SendKey(psxStatsGraph, E_KEY)

	DoUpdate

	// no cursor change
	CheckCurrentEvent(psxStatsGraph, 1, 0, 2)

	[WAVE psxEvent_0, WAVE psxEvent_1] = GetPSXEventWavesHelper(psxStatsGraph)

	CheckPSXEventField({psxEvent_0}, {"Fit manual QC call", "Event manual QC call"}, {0}, PSX_REJECT)
	CheckPSXEventField({psxEvent_0}, {"Fit manual QC call", "Event manual QC call"}, {1}, PSX_REJECT)
	CheckPSXEventField({psxEvent_1}, {"Fit manual QC call"}, {0}, PSX_UNDET)
	CheckPSXEventField({psxEvent_1}, {"Event manual QC call"}, {0}, PSX_REJECT)

	SendKey(psxStatsGraph, F_KEY)

	DoUpdate

	// no cursor change
	CheckCurrentEvent(psxStatsGraph, 1, 0, 2)

	[WAVE psxEvent_0, WAVE psxEvent_1] = GetPSXEventWavesHelper(psxStatsGraph)

	CheckPSXEventField({psxEvent_0}, {"Fit manual QC call", "Event manual QC call"}, {0}, PSX_REJECT)
	CheckPSXEventField({psxEvent_0}, {"Fit manual QC call", "Event manual QC call"}, {1}, PSX_REJECT)
	CheckPSXEventField({psxEvent_1}, {"Fit manual QC call"}, {0}, PSX_ACCEPT)
	CheckPSXEventField({psxEvent_1}, {"Event manual QC call"}, {0}, PSX_REJECT)

	// and again
	SendKey(psxStatsGraph, F_KEY)

	DoUpdate

	// no cursor change
	CheckCurrentEvent(psxStatsGraph, 1, 0, 2)

	[WAVE psxEvent_0, WAVE psxEvent_1] = GetPSXEventWavesHelper(psxStatsGraph)

	CheckPSXEventField({psxEvent_0}, {"Fit manual QC call", "Event manual QC call"}, {0}, PSX_REJECT)
	CheckPSXEventField({psxEvent_0}, {"Fit manual QC call", "Event manual QC call"}, {1}, PSX_REJECT)
	CheckPSXEventField({psxEvent_1}, {"Fit manual QC call"}, {0}, PSX_REJECT)
	CheckPSXEventField({psxEvent_1}, {"Event manual QC call"}, {0}, PSX_REJECT)

	SendKey(psxStatsGraph, SPACE_KEY)

	DoUpdate

	// no cursor change
	CheckCurrentEvent(psxStatsGraph, 1, 0, 2)

	[WAVE psxEvent_0, WAVE psxEvent_1] = GetPSXEventWavesHelper(psxStatsGraph)

	CheckPSXEventField({psxEvent_0}, {"Fit manual QC call", "Event manual QC call"}, {0}, PSX_REJECT)
	CheckPSXEventField({psxEvent_0}, {"Fit manual QC call", "Event manual QC call"}, {1}, PSX_REJECT)
	CheckPSXEventField({psxEvent_1}, {"Fit manual QC call"}, {0}, PSX_UNDET)
	CheckPSXEventField({psxEvent_1}, {"Event manual QC call"}, {0}, PSX_UNDET)

	SendKey(psxStatsGraph, SPACE_KEY)

	DoUpdate

	// no cursor change
	CheckCurrentEvent(psxStatsGraph, 1, 0, 2)

	[WAVE psxEvent_0, WAVE psxEvent_1] = GetPSXEventWavesHelper(psxStatsGraph)

	CheckPSXEventField({psxEvent_0}, {"Fit manual QC call", "Event manual QC call"}, {0}, PSX_REJECT)
	CheckPSXEventField({psxEvent_0}, {"Fit manual QC call", "Event manual QC call"}, {1}, PSX_REJECT)
	CheckPSXEventField({psxEvent_1}, {"Fit manual QC call"}, {0}, PSX_ACCEPT)
	CheckPSXEventField({psxEvent_1}, {"Event manual QC call"}, {0}, PSX_ACCEPT)
End

static Function KeyboardInteractionsStatsSpecial()

	string browser, code, psxGraph, win, mainWindow, psxStatsGraph, trace, tracenames

	Make/FREE/T combos = {"Range[50, 150], Sweep [0], Channel [AD6], Device [ITC16_Dev_0]", \
	                      "Range[50, 150], Sweep [2], Channel [AD6], Device [ITC16_Dev_0]"}
	WAVE overrideResults = MIES_PSX#PSX_CreateOverrideResults(4, combos)

	overrideResults[][][%$"Fit Result"] = 1
	overrideResults[][][%$"Tau"]        = 1

	browser = SetupDatabrowserWithSomeData()

	code = GetTestCode("nothing", eventState = "accept")

	ExecuteSweepFormulaCode(browser, code)

	win           = SFH_GetFormulaGraphForBrowser(browser)
	mainWindow    = GetMainWindow(win)
	psxGraph      = MIES_PSX#PSX_GetPSXGraph(win)
	psxStatsGraph = MIES_PSX#PSX_GetPSXStatsGraph(psxGraph)

	SetActiveSubwindow $psxGraph

	SendKey(psxGraph, UP_KEY)
	SendKey(psxGraph, DOWN_KEY)
	SendKey(psxGraph, UP_KEY)

	// replot so that stats now has data
	ExecuteSweepFormulaCode(browser, code)

	psxStatsGraph = MIES_PSX#PSX_GetPSXStatsGraph(psxGraph)

	REQUIRE(WindowExists(psxStatsGraph))

	SetActiveSubwindow $psxStatsGraph

	tracenames = TraceNameList(psxStatsGraph, ";", 1)
	trace      = StringFromList(0, tracenames)
	CHECK_PROPER_STR(trace)

	Cursor/W=$psxStatsGraph/P A, $trace, 0

	CheckCurrentEvent(psxStatsGraph, 0, 0, 0)

	[WAVE psxEvent_0, WAVE psxEvent_1] = GetPSXEventWavesHelper(psxStatsGraph)

	CheckPSXEventField({psxEvent_0}, {"Fit manual QC call", "Event manual QC call"}, {0}, PSX_ACCEPT)
	CheckPSXEventField({psxEvent_0}, {"Fit manual QC call", "Event manual QC call"}, {1}, PSX_REJECT)
	CheckPSXEventField({psxEvent_1}, {"Fit manual QC call", "Event manual QC call"}, {0}, PSX_ACCEPT)

	// going one right, moves two events
	SendKey(psxGraph, RIGHT_KEY)

	DoUpdate

	CheckCurrentEvent(psxStatsGraph, 1, 0, 1)

	// and left as well
	SendKey(psxGraph, LEFT_KEY)

	DoUpdate

	CheckCurrentEvent(psxStatsGraph, 0, 0, 0)
End

static Function KeyboardInteractionsStatsPostProcNonFinite()

	string browser, code, psxGraph, win, mainWindow, psxStatsGraph, trace, tracenames

	Make/FREE/T combos = {"Range[50, 150], Sweep [0], Channel [AD6], Device [ITC16_Dev_0]", \
	                      "Range[50, 150], Sweep [2], Channel [AD6], Device [ITC16_Dev_0]"}
	WAVE overrideResults = MIES_PSX#PSX_CreateOverrideResults(4, combos)

	overrideResults[1][%$combos[0]][%$"Fit Result"] = 1
	overrideResults[1][%$combos[0]][%$"Tau"]        = -Inf

	overrideResults[0][%$combos[0]][%$"Fit Result"] = 0
	overrideResults[0][%$combos[0]][%$"Tau"]        = NaN

	overrideResults[0][%$combos[1]][%$"Fit Result"] = 1
	overrideResults[0][%$combos[1]][%$"Tau"]        = +Inf

	browser = SetupDatabrowserWithSomeData()

	code = GetTestCode("nonfinite", eventState = "all", prop = "tau")

	ExecuteSweepFormulaCode(browser, code)

	win           = SFH_GetFormulaGraphForBrowser(browser)
	mainWindow    = GetMainWindow(win)
	psxGraph      = MIES_PSX#PSX_GetPSXGraph(win)
	psxStatsGraph = MIES_PSX#PSX_GetPSXStatsGraph(psxGraph)

	REQUIRE(WindowExists(psxStatsGraph))

	SetActiveSubwindow $psxStatsGraph

	tracenames = TraceNameList(psxStatsGraph, ";", 1)
	trace      = StringFromList(0, tracenames)
	CHECK_PROPER_STR(trace)

	Cursor/W=$psxStatsGraph/P A, $trace, 0

	CheckCurrentEvent(psxStatsGraph, 0, 0, 0)

	[WAVE psxEvent_0, WAVE psxEvent_1] = GetPSXEventWavesHelper(psxStatsGraph)

	CheckPSXEventField({psxEvent_0}, {"Fit manual QC call"}, {0}, PSX_REJECT)
	CheckPSXEventField({psxEvent_0}, {"Event manual QC call"}, {0}, PSX_UNDET)
	CheckPSXEventField({psxEvent_0}, {"Fit manual QC call", "Event manual QC call"}, {1}, PSX_UNDET)

	CheckPSXEventField({psxEvent_1}, {"Fit manual QC call", "Event manual QC call"}, {0}, PSX_UNDET)

	SendKey(psxStatsGraph, UP_KEY)
	SendKey(psxStatsGraph, DOWN_KEY)
	SendKey(psxStatsGraph, UP_KEY)

	CheckCurrentEvent(psxStatsGraph, 1, 0, 2)

	CheckPSXEventField({psxEvent_0}, {"Fit manual QC call"}, {0}, PSX_REJECT)
	CheckPSXEventField({psxEvent_0}, {"Event manual QC call"}, {0}, PSX_ACCEPT)
	CheckPSXEventField({psxEvent_0}, {"Fit manual QC call", "Event manual QC call"}, {1}, PSX_REJECT)

	CheckPSXEventField({psxEvent_1}, {"Fit manual QC call", "Event manual QC call"}, {0}, PSX_ACCEPT)
End

static Function NoEventsAtAll()

	string browser, code, psxGraph, win

	browser = SetupDatabrowserWithSomeData()

	code = "psx(psxKernel([50, 150], select(channels(AD6), [0, 2], all)), 100, 100, 0)"

	ExecuteSweepFormulaCode(browser, code)

	win = SFH_GetFormulaGraphForBrowser(browser)

	try
		psxGraph = MIES_PSX#PSX_GetPSXGraph(win)
		FAIL()
	catch
		PASS()
	endtry
End

static Function CheckResultsWavesForAverageFitResult()

	string browser, code, psxGraph, win, mainWindow, specialEventPanel, name, entry

	browser = SetupDatabrowserWithSomeData()

	code = GetTestCode("nothing")

	ExecuteSweepFormulaCode(browser, code)

	win               = SFH_GetFormulaGraphForBrowser(browser)
	mainWindow        = GetMainWindow(win)
	psxGraph          = MIES_PSX#PSX_GetPSXGraph(win)
	specialEventPanel = MIES_PSX#PSX_GetSpecialPanel(win)

	REQUIRE(WindowExists(psxGraph))

	SetActiveSubwindow $psxGraph

	// mark event as passed
	SendKey(psxGraph, UP_KEY)

	WAVE/T textualResultsValues = GetLogbookWaves(LBT_RESULTS, LBN_TEXTUAL_VALUES)
	CHECK_EQUAL_VAR(GetNumberFromWaveNote(textualResultsValues, NOTE_INDEX), 1)

	PGC_SetAndActivateControl(specialEventPanel, "checkbox_average_events_accept", val = 1)
	CHECK_EQUAL_VAR(GetNumberFromWaveNote(textualResultsValues, NOTE_INDEX), 1)

	PGC_SetAndActivateControl(specialEventPanel, "checkbox_average_events_fit", val = 1)
	// our data makes the fit fail
	CHECK_EQUAL_VAR(GetNumberFromWaveNote(textualResultsValues, NOTE_INDEX), 1)

	name  = SFH_FormatResultsKey(SFH_RESULT_TYPE_PSX_MISC, "accepted average fit results")
	entry = GetLastSettingTextIndep(textualResultsValues, NaN, name, SWEEP_FORMULA_RESULT)
	CHECK_EMPTY_STR(entry)
End

static Function TestBlockIndexLogic()

	string browser, code, psxGraph, win, mainWindow, specialEventPanel, extAllGraph

	browser = SetupDatabrowserWithSomeData()

	code = GetTestCode("nothing")

	ExecuteSweepFormulaCode(browser, code)

	win               = SFH_GetFormulaGraphForBrowser(browser)
	mainWindow        = GetMainWindow(win)
	psxGraph          = MIES_PSX#PSX_GetPSXGraph(win)
	specialEventPanel = MIES_PSX#PSX_GetSpecialPanel(win)
	extAllGraph       = MIES_PSX#PSX_GetAllEventGraph(win)

	// not restricted to current combinations aka all combinations
	CHECK_EQUAL_VAR(GetCheckBoxState(specialEventPanel, "checkbox_restrict_events_to_current_combination"), 0)
	CHECK_EQUAL_VAR(GetSetVariable(specialEventPanel, "setvar_event_block_size"), 100)
	CHECK_EQUAL_STR(GetPopupMenuString(specialEventPanel, "popup_block"), "0")
	CHECK_EQUAL_STR(PSX_GetAllEventBlockNumbers(specialEventPanel), "0;")

	WAVE/T dispTraces = GetTracesHelper(extAllGraph, 1 + 2^2)
	Make/FREE/T dispTracesRef = {"T000000", "T000001", "T000007"}
	CHECK_EQUAL_TEXTWAVES(dispTracesRef, dispTraces)

	// 50% block size
	PGC_SetAndActivateControl(specialEventPanel, "setvar_event_block_size", val = 50)

	DoUpdate

	CHECK_EQUAL_STR(PSX_GetAllEventBlockNumbers(specialEventPanel), "0;1;")

	// first block
	CHECK_EQUAL_STR(GetPopupMenuString(specialEventPanel, "popup_block"), "0")

	WAVE/T dispTraces = GetTracesHelper(extAllGraph, 1 + 2^2)
	Make/FREE/T dispTracesRef = {"T000000"}
	CHECK_EQUAL_TEXTWAVES(dispTracesRef, dispTraces)

	// second block
	PGC_SetAndActivateControl(specialEventPanel, "popup_block", str = "1")

	DoUpdate

	CHECK_EQUAL_STR(GetPopupMenuString(specialEventPanel, "popup_block"), "1")

	WAVE/T dispTraces = GetTracesHelper(extAllGraph, 1 + 2^2)
	Make/FREE/T dispTracesRef = {"T000001", "T000007"}
	CHECK_EQUAL_TEXTWAVES(dispTracesRef, dispTraces)

	// 33% block size
	// reset block index
	PGC_SetAndActivateControl(specialEventPanel, "popup_block", str = "0")
	PGC_SetAndActivateControl(specialEventPanel, "setvar_event_block_size", val = 33)

	DoUpdate

	CHECK_EQUAL_STR(PSX_GetAllEventBlockNumbers(specialEventPanel), "0;1;2;")

	// first block
	CHECK_EQUAL_STR(GetPopupMenuString(specialEventPanel, "popup_block"), "0")

	WAVE/T dispTraces = GetTracesHelper(extAllGraph, 1 + 2^2)
	Make/FREE/T dispTracesRef = {"T000000"}
	CHECK_EQUAL_TEXTWAVES(dispTracesRef, dispTraces)

	// second block
	PGC_SetAndActivateControl(specialEventPanel, "popup_block", str = "1")

	DoUpdate

	CHECK_EQUAL_STR(GetPopupMenuString(specialEventPanel, "popup_block"), "1")

	WAVE/T dispTraces = GetTracesHelper(extAllGraph, 1 + 2^2)
	Make/FREE/T dispTracesRef = {"T000001"}
	CHECK_EQUAL_TEXTWAVES(dispTracesRef, dispTraces)

	// third block
	PGC_SetAndActivateControl(specialEventPanel, "popup_block", str = "2")

	DoUpdate

	CHECK_EQUAL_STR(GetPopupMenuString(specialEventPanel, "popup_block"), "2")

	WAVE/T dispTraces = GetTracesHelper(extAllGraph, 1 + 2^2)
	Make/FREE/T dispTracesRef = {"T000007"}
	CHECK_EQUAL_TEXTWAVES(dispTracesRef, dispTraces)

	// current combination only
	PGC_SetAndActivateControl(specialEventPanel, "checkbox_restrict_events_to_current_combination", val = 1)
	PGC_SetAndActivateControl(specialEventPanel, "setvar_event_block_size", val = 100)

	CHECK_EQUAL_STR(GetPopupMenuString(specialEventPanel, "popup_block"), "0")
	CHECK_EQUAL_STR(PSX_GetAllEventBlockNumbers(specialEventPanel), "0;")

	WAVE/T dispTraces = GetTracesHelper(extAllGraph, 1 + 2^2)
	Make/FREE/T dispTracesRef = {"T000000", "T000001"}
	CHECK_EQUAL_TEXTWAVES(dispTracesRef, dispTraces)

	// 50% block size
	PGC_SetAndActivateControl(specialEventPanel, "setvar_event_block_size", val = 50)

	DoUpdate

	CHECK_EQUAL_STR(PSX_GetAllEventBlockNumbers(specialEventPanel), "0;1;")

	// first block
	CHECK_EQUAL_STR(GetPopupMenuString(specialEventPanel, "popup_block"), "0")

	WAVE/T dispTraces = GetTracesHelper(extAllGraph, 1 + 2^2)
	Make/FREE/T dispTracesRef = {"T000000"}
	CHECK_EQUAL_TEXTWAVES(dispTracesRef, dispTraces)

	// second block
	PGC_SetAndActivateControl(specialEventPanel, "popup_block", str = "1")

	DoUpdate

	CHECK_EQUAL_STR(GetPopupMenuString(specialEventPanel, "popup_block"), "1")

	WAVE/T dispTraces = GetTracesHelper(extAllGraph, 1 + 2^2)
	Make/FREE/T dispTracesRef = {"T000001"}
	CHECK_EQUAL_TEXTWAVES(dispTracesRef, dispTraces)

	// 33% block size
	// reset block index
	PGC_SetAndActivateControl(specialEventPanel, "popup_block", str = "0")

	PGC_SetAndActivateControl(specialEventPanel, "setvar_event_block_size", val = 33)

	DoUpdate

	// two few events for 3 blocks
	CHECK_EQUAL_STR(PSX_GetAllEventBlockNumbers(specialEventPanel), "0;1;")

	// first block
	CHECK_EQUAL_STR(GetPopupMenuString(specialEventPanel, "popup_block"), "0")

	WAVE/T dispTraces = GetTracesHelper(extAllGraph, 1 + 2^2)
	Make/FREE/T dispTracesRef = {"T000000"}
	CHECK_EQUAL_TEXTWAVES(dispTracesRef, dispTraces)

	// second block
	PGC_SetAndActivateControl(specialEventPanel, "popup_block", str = "1")

	DoUpdate

	CHECK_EQUAL_STR(GetPopupMenuString(specialEventPanel, "popup_block"), "1")

	WAVE/T dispTraces = GetTracesHelper(extAllGraph, 1 + 2^2)
	Make/FREE/T dispTracesRef = {"T000001"}
	CHECK_EQUAL_TEXTWAVES(dispTracesRef, dispTraces)
End

static Function [variable lowerThreshold, variable upperThreshold] TestRiseTimeContainer(WAVE/WAVE dataWref)

	CHECK_WAVE(dataWref, WAVE_WAVE)
	CHECK_EQUAL_VAR(DimSize(dataWref, ROWS), 1)
	WAVE/Z data = dataWref[0]
	CHECK_WAVE(data, NUMERIC_WAVE)
	CHECK_EQUAL_VAR(DimSize(data, ROWS), 2)

	upperThreshold = data[%$"Upper Threshold"]
	CHECK(BetweenZeroAndOneExc(upperThreshold))
	lowerThreshold = data[%$"Lower Threshold"]
	CHECK(BetweenZeroAndOneExc(lowerThreshold))

	return [lowerThreshold, upperThreshold]
End

static Function TestOperationRiseTime()

	string win, str
	variable lowerThreshold, upperThreshold

	win = SetupDatabrowserWithSomeData()

	str = "psxRiseTime()"
	WAVE/WAVE dataWref = SF_ExecuteFormula(str, win, useVariables = 0)
	[lowerThreshold, upperThreshold] = TestRiseTimeContainer(dataWref)
	CHECK_EQUAL_VAR(lowerThreshold, 0.2)
	CHECK_EQUAL_VAR(upperThreshold, 0.8)

	str = "psxRiseTime(10)"
	WAVE/WAVE dataWref = SF_ExecuteFormula(str, win, useVariables = 0)
	[lowerThreshold, upperThreshold] = TestRiseTimeContainer(dataWref)
	CHECK_EQUAL_VAR(lowerThreshold, 0.1)
	CHECK_EQUAL_VAR(upperThreshold, 0.8)

	str = "psxRiseTime(10, 90)"
	WAVE/WAVE dataWref = SF_ExecuteFormula(str, win, useVariables = 0)
	[lowerThreshold, upperThreshold] = TestRiseTimeContainer(dataWref)
	CHECK_EQUAL_VAR(lowerThreshold, 0.1)
	CHECK_EQUAL_VAR(upperThreshold, 0.9)

	// checks parameters
	try
		str = "psxRiseTime(110, 90)"
		WAVE/WAVE dataWref = SF_ExecuteFormula(str, win, useVariables = 0)
		FAIL()
	catch
		CHECK_NO_RTE()
	endtry

	try
		str = "psxRiseTime(10, -10)"
		WAVE/WAVE dataWref = SF_ExecuteFormula(str, win, useVariables = 0)
		FAIL()
	catch
		CHECK_NO_RTE()
	endtry
End

static Function TestOperationPrep()

	string win, device, code, psxCode

	[win, device] = CreateEmptyUnlockedDataBrowserWindow()

	win = CreateFakeSweepData(win, device, sweepNo = 0, sweepGen = FakeSweepDataGeneratorPSX)

	psxCode = "psx(myID, psxKernel([50, 150], select(channels(AD6), [0, 2], all), 1, 15, -5), 2.5, 100, 0)"
	sprintf code, "psxPrep(%s)", psxCode

	WAVE/WAVE dataWref = SF_ExecuteFormula(code, win, useVariables = 0)
	CHECK_WAVE(dataWref, WAVE_WAVE)
	CHECK_EQUAL_VAR(DimSize(dataWref, ROWS), 3)

	WAVE hist = dataWref[0]
	CHECK_GT_VAR(DimSize(hist, ROWS), 0)

	WAVE fit = dataWref[1]
	CHECK_EQUAL_VAR(DimSize(fit, ROWS), 200)

	WAVE threshold = dataWref[2]
	CHECK_EQUAL_VAR(DimSize(threshold, ROWS), 1)
	CHECK_EQUAL_VAR(threshold[0], 0) // because the input data is BS

	// checks parameters
	try
		sprintf code, "psxPrep(%s, 0)", psxCode
		WAVE/WAVE dataWref = SF_ExecuteFormula(code, win, useVariables = 0)
		FAIL()
	catch
		CHECK_NO_RTE()
	endtry

	try
		sprintf code, "psxPrep(%s, -1)", psxCode
		WAVE/WAVE dataWref = SF_ExecuteFormula(code, win, useVariables = 0)
		FAIL()
	catch
		CHECK_NO_RTE()
	endtry
End

static Function TestStoreAndLoad()

	string browser, code, psxGraph, win, mainWindow, specialEventPanel, extAllGraph, bsPanel

	Make/FREE/T combos = {"Range[50, 150], Sweep [0], Channel [AD6], Device [ITC16_Dev_0]", \
	                      "Range[50, 150], Sweep [2], Channel [AD6], Device [ITC16_Dev_0]"}
	WAVE overrideResults = MIES_PSX#PSX_CreateOverrideResults(4, combos)

	overrideResults[][][%$"Fit Result"] = 1
	overrideResults[][][%$"Tau"]        = 1

	browser = SetupDatabrowserWithSomeData()

	code = GetTestCode("nothing")

	ExecuteSweepFormulaCode(browser, code)

	win        = SFH_GetFormulaGraphForBrowser(browser)
	mainWindow = GetMainWindow(win)
	psxGraph   = MIES_PSX#PSX_GetPSXGraph(win)
	bsPanel    = BSP_GetPanel(browser)

	SetActiveSubwindow $psxGraph

	SendKey(psxGraph, SPACE_KEY)

	DoUpdate/W=$psxGraph

	[WAVE psxEvent_0, WAVE psxEvent_1] = GetPSXEventWavesHelper(psxGraph)

	CheckPSXEventField({psxEvent_0}, {"Fit manual QC call", "Event manual QC call"}, {0}, PSX_ACCEPT)
	CheckPSXEventField({psxEvent_0}, {"Fit manual QC call", "Event manual QC call"}, {1}, PSX_UNDET)
	CheckPSXEventField({psxEvent_1}, {"Fit manual QC call", "Event manual QC call"}, {0}, PSX_UNDET)

	PGC_SetAndActivateControl(mainWindow, "button_store")

	SendKey(psxGraph, SPACE_KEY)

	DoUpdate/W=$psxGraph

	[WAVE psxEvent_0, WAVE psxEvent_1] = GetPSXEventWavesHelper(psxGraph)

	CheckPSXEventField({psxEvent_0}, {"Fit manual QC call", "Event manual QC call"}, {0}, PSX_REJECT)
	CheckPSXEventField({psxEvent_0}, {"Fit manual QC call", "Event manual QC call"}, {1}, PSX_UNDET)
	CheckPSXEventField({psxEvent_1}, {"Fit manual QC call", "Event manual QC call"}, {0}, PSX_UNDET)

	PGC_SetAndActivateControl(mainWindow, "button_load")

	DoUpdate/W=$psxGraph

	[WAVE psxEvent_0, WAVE psxEvent_1] = GetPSXEventWavesHelper(psxGraph)

	// now it is accepted again
	CheckPSXEventField({psxEvent_0}, {"Fit manual QC call", "Event manual QC call"}, {0}, PSX_ACCEPT)
	CheckPSXEventField({psxEvent_0}, {"Fit manual QC call", "Event manual QC call"}, {1}, PSX_UNDET)
	CheckPSXEventField({psxEvent_1}, {"Fit manual QC call", "Event manual QC call"}, {0}, PSX_UNDET)

	// reject it again
	SendKey(psxGraph, SPACE_KEY)

	DoUpdate/W=$psxGraph

	[WAVE psxEvent_0, WAVE psxEvent_1] = GetPSXEventWavesHelper(psxGraph)

	CheckPSXEventField({psxEvent_0}, {"Fit manual QC call", "Event manual QC call"}, {0}, PSX_REJECT)
	CheckPSXEventField({psxEvent_0}, {"Fit manual QC call", "Event manual QC call"}, {1}, PSX_UNDET)
	CheckPSXEventField({psxEvent_1}, {"Fit manual QC call", "Event manual QC call"}, {0}, PSX_UNDET)

	// redisplaying still gives reject as we load the last state from the cache
	PGC_SetAndActivateControl(bsPanel, "button_sweepFormula_display")

	DoUpdate/W=$psxGraph

	SetActiveSubwindow $psxGraph

	[WAVE psxEvent_0, WAVE psxEvent_1] = GetPSXEventWavesHelper(psxGraph)

	CheckPSXEventField({psxEvent_0}, {"Fit manual QC call", "Event manual QC call"}, {0}, PSX_REJECT)
	CheckPSXEventField({psxEvent_0}, {"Fit manual QC call", "Event manual QC call"}, {1}, PSX_UNDET)
	CheckPSXEventField({psxEvent_1}, {"Fit manual QC call", "Event manual QC call"}, {0}, PSX_UNDET)

	// but if we clear the cache we load the last results data
	CA_FLushCache()

	PGC_SetAndActivateControl(bsPanel, "button_sweepFormula_display")

	DoUpdate/W=$psxGraph

	SetActiveSubwindow $psxGraph

	[WAVE psxEvent_0, WAVE psxEvent_1] = GetPSXEventWavesHelper(psxGraph)

	CheckPSXEventField({psxEvent_0}, {"Fit manual QC call", "Event manual QC call"}, {0}, PSX_ACCEPT)
	CheckPSXEventField({psxEvent_0}, {"Fit manual QC call", "Event manual QC call"}, {1}, PSX_UNDET)
	CheckPSXEventField({psxEvent_1}, {"Fit manual QC call", "Event manual QC call"}, {0}, PSX_UNDET)
End

static Function [variable filterLow, variable filterHigh, variable filterOrder] TestDevonvFilterContainer(WAVE/WAVE dataWref)

	CHECK_WAVE(dataWref, WAVE_WAVE)
	CHECK_EQUAL_VAR(DimSize(dataWref, ROWS), 1)
	WAVE/Z data = dataWref[0]
	CHECK_WAVE(data, NUMERIC_WAVE)
	CHECK_EQUAL_VAR(DimSize(data, ROWS), 3)

	filterLow = data[%$"Filter Low"]
	if(IsNaN(filterLow))
		PASS()
	else
		CHECK(IsNullOrPositiveAndFinite(filterLow))
	endif

	filterHigh = data[%$"Filter High"]
	if(IsNaN(filterHigh))
		PASS()
	else
		CHECK(IsNullOrPositiveAndFinite(filterHigh))
	endif

	filterOrder = data[%$"Filter Order"]

	if(IsNaN(filterOrder))
		PASS()
	else
		CHECK(IsOdd(filterOrder))
	endif

	return [filterLow, filterHigh, filterOrder]
End

static Function TestOperationDeconvFilter()

	string win, str
	variable filterLow, filterHigh, filterOrder

	win = SetupDatabrowserWithSomeData()

	str = "psxDeconvFilter()"
	WAVE/WAVE dataWref = SF_ExecuteFormula(str, win, useVariables = 0)
	[filterLow, filterHigh, filterOrder] = TestDevonvFilterContainer(dataWref)
	CHECK_EQUAL_VAR(filterLow, NaN)
	CHECK_EQUAL_VAR(filterHigh, NaN)
	CHECK_EQUAL_VAR(filterOrder, NaN)

	str = "psxDeconvFilter(40)"
	WAVE/WAVE dataWref = SF_ExecuteFormula(str, win, useVariables = 0)
	[filterLow, filterHigh, filterOrder] = TestDevonvFilterContainer(dataWref)
	CHECK_EQUAL_VAR(filterLow, 40)
	CHECK_EQUAL_VAR(filterHigh, NaN)
	CHECK_EQUAL_VAR(filterOrder, NaN)

	str = "psxDeconvFilter(40, 50)"
	WAVE/WAVE dataWref = SF_ExecuteFormula(str, win, useVariables = 0)
	[filterLow, filterHigh, filterOrder] = TestDevonvFilterContainer(dataWref)
	CHECK_EQUAL_VAR(filterLow, 40)
	CHECK_EQUAL_VAR(filterHigh, 50)
	CHECK_EQUAL_VAR(filterOrder, NaN)

	str = "psxDeconvFilter(40, 50, 11)"
	WAVE/WAVE dataWref = SF_ExecuteFormula(str, win, useVariables = 0)
	[filterLow, filterHigh, filterOrder] = TestDevonvFilterContainer(dataWref)
	CHECK_EQUAL_VAR(filterLow, 40)
	CHECK_EQUAL_VAR(filterHigh, 50)
	CHECK_EQUAL_VAR(filterOrder, 11)

	// check parameters
	try
		str = "psxDeconvFilter(-1)"
		WAVE/WAVE dataWref = SF_ExecuteFormula(str, win, useVariables = 0)
		FAIL()
	catch
		CHECK_NO_RTE()
	endtry

	try
		str = "psxDeconvFilter(1, -1)"
		WAVE/WAVE dataWref = SF_ExecuteFormula(str, win, useVariables = 0)
		FAIL()
	catch
		CHECK_NO_RTE()
	endtry

	try
		str = "psxDeconvFilter(1, 1, 2)"
		WAVE/WAVE dataWref = SF_ExecuteFormula(str, win, useVariables = 0)
		FAIL()
	catch
		CHECK_NO_RTE()
	endtry
End
