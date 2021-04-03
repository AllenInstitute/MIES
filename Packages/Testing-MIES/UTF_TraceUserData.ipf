#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma ModuleName=TraceUserDataTest

static Function TEST_CASE_BEGIN_OVERRIDE(name)
	string name

	AdditionalExperimentCleanup()

	JSONXOP_Release/A

	Display
	string/G root:graph = S_name
End

// Test: GetGraphUserData
Function CreatesWave()

	SVAR graph = root:graph

	WAVE/T/Z graphUserData = GetGraphUserData(graph)
	CHECK_WAVE(graphUserData, TEXT_WAVE)

	CHECK_EQUAL_VAR(DimSize(graphUserData, COLS), 0)

	CHECK_EQUAL_VAR(GetNumberFromWaveNote(graphUserData, NOTE_INDEX), 0)
	CHECK(JSON_Exists(GetNumberFromWaveNote(graphUserData, TUD_INDEX_JSON), ""))
End

Function KillGraphAndCheckEmptyUserData_IGNORE(string graph, WAVE/T graphUserData)

	variable modCount = WaveModCount(graphUserData)

	KillWindow $graph
	DoUpdate

	CHECK(!WindowExists(graph))
	CHECK(WaveModCount(graphUserData) > modCount)

	CHECK_EQUAL_VAR(GetNumberFromWaveNote(graphUserData, NOTE_INDEX), 0)
	CHECK_EQUAL_VAR(GetNumberFromWaveNote(graphUserData, TUD_INDEX_JSON), NaN)

	Make/FREE/N=(DimSize(graphUserData, ROWS), DimSize(graphUserData, COLS)) sizes = strlen(graphUserData[p][q])
	CHECK_EQUAL_VAR(Sum(sizes), 0)
End

// Test: GetGraphUserData, TUD_Clear, TUD_Init
Function ClearsWaveOnKillWindow()

	SVAR graph = root:graph

	WAVE/T/Z graphUserData = GetGraphUserData(graph)

	TUD_SetUserData(graph, "trace1", "efgh", "ijkl")

	KillGraphAndCheckEmptyUserData_IGNORE(graph, graphUserData)

	// recreate the graph
	Display/N=$graph

	// needs now a manual call
	TUD_Init(graph)
	TUD_SetUserData(graph, "trace1", "efgh", "ijkl")

	// check that the window hook is reattached with TUD_Init()
	KillGraphAndCheckEmptyUserData_IGNORE(graph, graphUserData)
End

// Test: TUD_SetUserData
Function SetUserDataWorks()

	variable jsonID
	string expected, actual

	SVAR graph = root:graph

	WAVE/T/Z graphUserData = GetGraphUserData(graph)

	TUD_SetUserData(graph, "trace1", "key", "value")

	CHECK_EQUAL_VAR(GetNumberFromWaveNote(graphUserData, NOTE_INDEX), 1)

	// check indexing json
	jsonID = GetNumberFromWaveNote(graphUserData, TUD_INDEX_JSON)
	WAVE/T/Z traces = JSON_GetKeys(jsonID, "", esc = 0)
	CHECK_EQUAL_TEXTWAVES(traces, {"trace1"})

	// check wave contents
	CHECK_EQUAL_VAR(DimSize(graphUserData, COLS), 2)
	CHECK_EQUAL_VAR(FindDimLabel(graphUserData, COLS, "traceName"), 0)
	CHECK_EQUAL_VAR(FindDimLabel(graphUserData, COLS, "key"), 1)
	expected = "trace1"
	actual   = graphUserData[0][0]
	CHECK_EQUAL_STR(expected, actual)

	expected = "value"
	actual   = graphUserData[0][1]
	CHECK_EQUAL_STR(expected, actual)
End

// Test: TUD_SetUserDataFromWaves
Function SetUserDataFromWaveWorks()

	variable jsonID
	string expected, actual

	SVAR graph = root:graph

	WAVE/T/Z graphUserData = GetGraphUserData(graph)

	TUD_SetUserDataFromWaves(graph, "trace1", {"key1", "key2"}, {"value1", "value2"})

	CHECK_EQUAL_VAR(GetNumberFromWaveNote(graphUserData, NOTE_INDEX), 1)

	// check indexing json
	jsonID = GetNumberFromWaveNote(graphUserData, TUD_INDEX_JSON)
	WAVE/T/Z traces = JSON_GetKeys(jsonID, "", esc = 0)
	CHECK_EQUAL_TEXTWAVES(traces, {"trace1"})

	// check wave contents
	CHECK_EQUAL_VAR(DimSize(graphUserData, COLS), 3)
	CHECK_EQUAL_VAR(FindDimLabel(graphUserData, COLS, "traceName"), 0)
	CHECK_EQUAL_VAR(FindDimLabel(graphUserData, COLS, "key1"), 1)
	CHECK_EQUAL_VAR(FindDimLabel(graphUserData, COLS, "key2"), 2)

	expected = "trace1"
	actual   = graphUserData[0][0]
	CHECK_EQUAL_STR(expected, actual)

	expected = "value1"
	actual   = graphUserData[0][1]
	CHECK_EQUAL_STR(expected, actual)

	expected = "value2"
	actual   = graphUserData[0][2]
	CHECK_EQUAL_STR(expected, actual)
End

// Test: TUD_SetUserData, TUD_SetUserDataFromWaves
Function SetUserDataBothTogether()

	variable jsonID
	string expected, actual

	SVAR graph = root:graph

	WAVE/T/Z graphUserData = GetGraphUserData(graph)

	TUD_SetUserData(graph, "trace1", "key1", "value1")
	TUD_SetUserDataFromWaves(graph, "trace1", {"key2", "key3"}, {"value2", "value3"})

	CHECK_EQUAL_VAR(GetNumberFromWaveNote(graphUserData, NOTE_INDEX), 1)

	// check indexing json
	jsonID = GetNumberFromWaveNote(graphUserData, TUD_INDEX_JSON)
	WAVE/T/Z traces = JSON_GetKeys(jsonID, "", esc = 0)
	CHECK_EQUAL_TEXTWAVES(traces, {"trace1"})

	// check wave contents
	CHECK_EQUAL_VAR(DimSize(graphUserData, COLS), 4)
	CHECK_EQUAL_VAR(FindDimLabel(graphUserData, COLS, "traceName"), 0)
	CHECK_EQUAL_VAR(FindDimLabel(graphUserData, COLS, "key1"), 1)
	CHECK_EQUAL_VAR(FindDimLabel(graphUserData, COLS, "key2"), 2)
	CHECK_EQUAL_VAR(FindDimLabel(graphUserData, COLS, "key3"), 3)

	expected = "trace1"
	actual   = graphUserData[0][0]
	CHECK_EQUAL_STR(expected, actual)

	expected = "value1"
	actual   = graphUserData[0][1]
	CHECK_EQUAL_STR(expected, actual)

	expected = "value2"
	actual   = graphUserData[0][2]
	CHECK_EQUAL_STR(expected, actual)

	expected = "value3"
	actual   = graphUserData[0][3]
	CHECK_EQUAL_STR(expected, actual)
End

// Test: TUD_SetUserData, TUD_SetUserDataFromWaves
Function SetUserDataBothTogetherInvertedOrder()

	variable jsonID
	string expected, actual

	SVAR graph = root:graph

	WAVE/T/Z graphUserData = GetGraphUserData(graph)

	TUD_SetUserDataFromWaves(graph, "trace1", {"key1", "key2"}, {"value1", "value2"})
	TUD_SetUserData(graph, "trace1", "key3", "value3")

	CHECK_EQUAL_VAR(GetNumberFromWaveNote(graphUserData, NOTE_INDEX), 1)

	// check indexing json
	jsonID = GetNumberFromWaveNote(graphUserData, TUD_INDEX_JSON)
	WAVE/T/Z traces = JSON_GetKeys(jsonID, "", esc = 0)
	CHECK_EQUAL_TEXTWAVES(traces, {"trace1"})

	// check wave contents
	CHECK_EQUAL_VAR(DimSize(graphUserData, COLS), 4)
	CHECK_EQUAL_VAR(FindDimLabel(graphUserData, COLS, "traceName"), 0)
	CHECK_EQUAL_VAR(FindDimLabel(graphUserData, COLS, "key1"), 1)
	CHECK_EQUAL_VAR(FindDimLabel(graphUserData, COLS, "key2"), 2)
	CHECK_EQUAL_VAR(FindDimLabel(graphUserData, COLS, "key3"), 3)

	expected = "trace1"
	actual   = graphUserData[0][0]
	CHECK_EQUAL_STR(expected, actual)

	expected = "value1"
	actual   = graphUserData[0][1]
	CHECK_EQUAL_STR(expected, actual)

	expected = "value2"
	actual   = graphUserData[0][2]
	CHECK_EQUAL_STR(expected, actual)

	expected = "value3"
	actual   = graphUserData[0][3]
	CHECK_EQUAL_STR(expected, actual)
End

// Test: TUD_GetTraceCount
Function GetTraceCountWorks()

	SVAR graph = root:graph

	WAVE/T/Z graphUserData = GetGraphUserData(graph)

	CHECK_EQUAL_VAR(TUD_GetTraceCount(graph), 0)

	TUD_SetUserData(graph, "trace1", "key", "value")

	CHECK_EQUAL_VAR(TUD_GetTraceCount(graph), 1)

	TUD_SetUserDataFromWaves(graph, "trace1", {"key1", "key2"}, {"value1", "value2"})

	// still the same trace count as we add additional data to an existing trace
	CHECK_EQUAL_VAR(TUD_GetTraceCount(graph), 1)

	TUD_SetUserData(graph, "trace2", "key", "value")

	CHECK_EQUAL_VAR(TUD_GetTraceCount(graph), 2)
End

// Test: TUD_RegenerateJSONIndex
Function RegeneratesJSON()

	variable jsonIDOld, jsonIDNew

	SVAR graph = root:graph

	WAVE/T/Z graphUserData = GetGraphUserData(graph)

	TUD_SetUserData(graph, "trace1", "key", "value")

	// check indexing json
	jsonIDOld = GetNumberFromWaveNote(graphUserData, TUD_INDEX_JSON)
	WAVE/T/Z traces = JSON_GetKeys(jsonIDOld, "", esc = 0)
	CHECK_EQUAL_TEXTWAVES(traces, {"trace1"})

	JSON_Release(jsonIDOld)

	// fetch Index JSON to trigger regeneration
	jsonIDNew = MIES_TUD#TUD_GetIndexJSON(graphUserData)
	WAVE/T/Z traces = JSON_GetKeys(jsonIDNew, "", esc = 0)
	CHECK_EQUAL_TEXTWAVES(traces, {"trace1"})

	CHECK(jsonIDOld != jsonIDNew)
End

// Test: TUD_GetUserData
Function GetUserDataExpectsExistingTraceAndKey()

	variable err

	SVAR graph = root:graph

	WAVE/T/Z graphUserData = GetGraphUserData(graph)

	TUD_SetUserData(graph, "trace1", "key", "value")

	try
		TUD_GetUserData(graph, "I DONT EXIST", "key"); AbortOnRTE
		FAIL()
	catch
		err = GetRTError(1)
		PASS()
	endtry

	try
		TUD_GetUserData(graph, "trace1", "I DONT EXIST"); AbortOnRTE
		FAIL()
	catch
		err = GetRTError(1)
		PASS()
	endtry
End

// Test: TUD_GetUserData
Function GetUserDataWorks()

	variable err
	string actual, expected

	SVAR graph = root:graph

	WAVE/T/Z graphUserData = GetGraphUserData(graph)

	TUD_SetUserDataFromWaves(graph, "trace1", {"key1", "key2"}, {"value1", "value2"})
	TUD_SetUserData(graph, "trace1", "key3", "value3")

	actual   = TUD_GetUserData(graph, "trace1", "traceName")
	expected = "trace1"
	CHECK_EQUAL_STR(actual, expected)

	actual   = TUD_GetUserData(graph, "trace1", "key1")
	expected = "value1"
	CHECK_EQUAL_STR(actual, expected)

	actual   = TUD_GetUserData(graph, "trace1", "key2")
	expected = "value2"
	CHECK_EQUAL_STR(actual, expected)

	actual   = TUD_GetUserData(graph, "trace1", "key3")
	expected = "value3"
	CHECK_EQUAL_STR(actual, expected)
End

// Test: TUD_GetUserDataAsWave
Function GetUserDataAsWaveChecksInput()

	variable err

	SVAR graph = root:graph

	WAVE/T/Z graphUserData = GetGraphUserData(graph)

	WAVE/Z result = TUD_GetUserDataAsWave(graph, "I DONT EXIST")
	// no traces exist
	CHECK_WAVE(result, NULL_WAVE)

	TUD_SetUserData(graph, "trace1", "key3", "value3")

	try
		TUD_GetUserDataAsWave(graph, "I DONT EXIST"); AbortOnRTE
		FAIL()
	catch
		err = GetRTError(1)
		PASS()
	endtry

	// both keys/values must be present or absent
	try
		TUD_GetUserDataAsWave(graph, "traceName", keys = {"traceName"}); AbortOnRTE
		FAIL()
	catch
		err = GetRTError(1)
		PASS()
	endtry

	// both keys/values must be present or absent
	try
		TUD_GetUserDataAsWave(graph, "traceName", values = {"trace1"}); AbortOnRTE
		FAIL()
	catch
		err = GetRTError(1)
		PASS()
	endtry

	// mismatched keys/values sizes
	try
		TUD_GetUserDataAsWave(graph, "traceName", keys = {"a", "b"}, values = {"c"}); AbortOnRTE
		FAIL()
	catch
		err = GetRTError(1)
		PASS()
	endtry

	// mismatched keys/values sizes
	try
		TUD_GetUserDataAsWave(graph, "traceName", keys = {"a"}, values = {"b", "c"}); AbortOnRTE
		FAIL()
	catch
		err = GetRTError(1)
		PASS()
	endtry

	// non-existing key
	try
		TUD_GetUserDataAsWave(graph, "traceName", keys = {"a"}, values = {"b"}); AbortOnRTE
		FAIL()
	catch
		err = GetRTError(1)
		PASS()
	endtry
End

// Test: TUD_GetUserDataAsWave
Function GetUserDataAsWaveWorksBasic()

	SVAR graph = root:graph

	WAVE/T/Z graphUserData = GetGraphUserData(graph)

	WAVE/Z result = TUD_GetUserDataAsWave(graph, "traceName")
	CHECK_WAVE(result, NULL_WAVE)

	TUD_SetUserData(graph, "trace1", "key1", "value1")
	TUD_SetUserData(graph, "trace2", "key2", "value2")

	WAVE/Z result = TUD_GetUserDataAsWave(graph, "traceName")
	CHECK_WAVE(result, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(result, {"trace1", "trace2"})

	WAVE/Z result = TUD_GetUserDataAsWave(graph, "key1")
	CHECK_WAVE(result, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(result, {"value1", ""})

	WAVE/Z result = TUD_GetUserDataAsWave(graph, "key2")
	CHECK_WAVE(result, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(result, {"", "value2"})
End

// Test: TUD_GetUserDataAsWave
Function GetUserDataAsWaveWorksBasicIndizes()

	SVAR graph = root:graph

	WAVE/T/Z graphUserData = GetGraphUserData(graph)

	TUD_SetUserData(graph, "trace1", "key1", "value1")
	TUD_SetUserData(graph, "trace2", "key2", "value2")

	WAVE/Z result = TUD_GetUserDataAsWave(graph, "traceName", returnIndizes = 1)
	CHECK_WAVE(result, NUMERIC_WAVE)
	CHECK_EQUAL_WAVES(result, {0, 1})

	WAVE/Z result = TUD_GetUserDataAsWave(graph, "key1", returnIndizes = 1)
	CHECK_WAVE(result, NUMERIC_WAVE)
	CHECK_EQUAL_WAVES(result, {0, 1})

	WAVE/Z result = TUD_GetUserDataAsWave(graph, "key2", returnIndizes = 1)
	CHECK_WAVE(result, NUMERIC_WAVE)
	CHECK_EQUAL_WAVES(result, {0, 1})
End

// Test: TUD_GetUserDataAsWave
Function GetUserDataAsWaveWorksComplex()

	SVAR graph = root:graph

	WAVE/T/Z graphUserData = GetGraphUserData(graph)

	TUD_SetUserData(graph, "trace1", "key1", "value1")
	TUD_SetUserData(graph, "trace2", "key2", "value2")

	WAVE/Z result = TUD_GetUserDataAsWave(graph, "traceName", keys = {"key1"}, values = {"value1"})
	CHECK_WAVE(result, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(result, {"trace1"})

	WAVE/Z result = TUD_GetUserDataAsWave(graph, "traceName", keys = {"key2"}, values = {"value2"})
	CHECK_WAVE(result, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(result, {"trace2"})

	// no traces have all properties
	WAVE/Z result = TUD_GetUserDataAsWave(graph, "traceName", keys = {"key1", "key2"}, values = {"value1", "value2"})
	CHECK_WAVE(result, NULL_WAVE)

	// key exists but no match
	WAVE/Z result = TUD_GetUserDataAsWave(graph, "traceName", keys = {"key1"}, values = {"I DONT EXIST"})
	CHECK_WAVE(result, NULL_WAVE)

	// key exists but no match in second keys/values entry
	WAVE/Z result = TUD_GetUserDataAsWave(graph, "traceName", keys = {"key1", "key2"}, values = {"value1", "I DONT EXIST"})
	CHECK_WAVE(result, NULL_WAVE)
End

// Test: TUD_GetUserDataAsWave
Function GetUserDataAsWaveWorksComplexIndizes()

	SVAR graph = root:graph

	WAVE/T/Z graphUserData = GetGraphUserData(graph)

	TUD_SetUserData(graph, "trace1", "key1", "value1")
	TUD_SetUserData(graph, "trace2", "key2", "value2")

	WAVE/Z result = TUD_GetUserDataAsWave(graph, "traceName", keys = {"key1"}, values = {"value1"}, returnIndizes = 1)
	CHECK_WAVE(result, NUMERIC_WAVE)
	CHECK_EQUAL_WAVES(result, {0})

	WAVE/Z result = TUD_GetUserDataAsWave(graph, "traceName", keys = {"key2"}, values = {"value2"}, returnIndizes = 1)
	CHECK_WAVE(result, NUMERIC_WAVE)
	CHECK_EQUAL_WAVES(result, {1})

	// no traces have all properties
	WAVE/Z result = TUD_GetUserDataAsWave(graph, "traceName", keys = {"key1", "key2"}, values = {"value1", "value2"}, returnIndizes = 1)
	CHECK_WAVE(result, NULL_WAVE)

	// key exists but no match
	WAVE/Z result = TUD_GetUserDataAsWave(graph, "traceName", keys = {"key1"}, values = {"I DONT EXIST"}, returnIndizes = 1)
	CHECK_WAVE(result, NULL_WAVE)

	// key exists but no match in second keys/values entry
	WAVE/Z result = TUD_GetUserDataAsWave(graph, "traceName", keys = {"key1", "key2"}, values = {"value1", "I DONT EXIST"}, returnIndizes = 1)
	CHECK_WAVE(result, NULL_WAVE)
End

// Test: TUD_RemoveUserData
Function RemoveUserDataChecksInput()

	variable err

	SVAR graph = root:graph

	// expects existing trace
	try
		TUD_RemoveUserData(graph, "I DONT EXIST"); AbortOnRTE
		FAIL()
	catch
		err = GetRTError(1)
		PASS()
	endtry
End

static Function PrepareUserDataWaveForRemoval_IGNORE()

	variable jsonID

	SVAR graph = root:graph

	WAVE/T/Z graphUserData = GetGraphUserData(graph)
	KillWaves/Z graphUserData

	WAVE/T/Z graphUserData = GetGraphUserData(graph)

	TUD_SetUserData(graph, "trace1", "key1", "value1")
	TUD_SetUserData(graph, "trace2", "key2", "value2")
	TUD_SetUserData(graph, "trace3", "key3", "value3")

	Redimension/N=(3, -1) graphUserData
	CHECK_EQUAL_VAR(GetNumberFromWaveNote(graphUserData, NOTE_INDEX), 3)
	CHECK_EQUAL_TEXTWAVES(TUD_GetUserDataAsWave(graph, "traceName"), {"trace1", "trace2", "trace3"})

	jsonID = GetNumberFromWaveNote(graphUserData, TUD_INDEX_JSON)
	WAVE/T/Z traces = JSON_GetKeys(jsonID, "", esc = 0)
	CHECK_EQUAL_TEXTWAVES(traces, {"trace1", "trace2", "trace3"})
End

// Test: TUD_RemoveUserData
Function RemoveUserDataWorks()

	variable jsonID

	SVAR graph = root:graph

	PrepareUserDataWaveForRemoval_IGNORE()

	WAVE/T/Z graphUserData = GetGraphUserData(graph)

	// remove the first entry
	TUD_RemoveUserData(graph, "trace1")
	CHECK_EQUAL_VAR(DimSize(graphUserData, ROWS), 2)
	CHECK_EQUAL_VAR(GetNumberFromWaveNote(graphUserData, NOTE_INDEX), 2)
	CHECK_EQUAL_TEXTWAVES(TUD_GetUserDataAsWave(graph, "traceName"), {"trace2", "trace3"})

	jsonID = GetNumberFromWaveNote(graphUserData, TUD_INDEX_JSON)
	WAVE/T/Z traces = JSON_GetKeys(jsonID, "", esc = 0)
	CHECK_EQUAL_TEXTWAVES(traces, {"trace2", "trace3"})
	CHECK_EQUAL_VAR(JSON_GetVariable(jsonID, "/trace2"), 0)
	CHECK_EQUAL_VAR(JSON_GetVariable(jsonID, "/trace3"), 1)

	PrepareUserDataWaveForRemoval_IGNORE()

	WAVE/T/Z graphUserData = GetGraphUserData(graph)

	// remove the second entry
	TUD_RemoveUserData(graph, "trace2")
	CHECK_EQUAL_VAR(DimSize(graphUserData, ROWS), 2)
	CHECK_EQUAL_VAR(GetNumberFromWaveNote(graphUserData, NOTE_INDEX), 2)
	CHECK_EQUAL_TEXTWAVES(TUD_GetUserDataAsWave(graph, "traceName"), {"trace1", "trace3"})

	jsonID = GetNumberFromWaveNote(graphUserData, TUD_INDEX_JSON)
	WAVE/T/Z traces = JSON_GetKeys(jsonID, "", esc = 0)
	CHECK_EQUAL_TEXTWAVES(traces, {"trace1", "trace3"})
	CHECK_EQUAL_VAR(JSON_GetVariable(jsonID, "/trace1"), 0)
	CHECK_EQUAL_VAR(JSON_GetVariable(jsonID, "/trace3"), 1)

	PrepareUserDataWaveForRemoval_IGNORE()

	WAVE/T/Z graphUserData = GetGraphUserData(graph)

	// remove last entry
	TUD_RemoveUserData(graph, "trace3")
	CHECK_EQUAL_VAR(DimSize(graphUserData, ROWS), 2)
	CHECK_EQUAL_VAR(GetNumberFromWaveNote(graphUserData, NOTE_INDEX), 2)
	CHECK_EQUAL_TEXTWAVES(TUD_GetUserDataAsWave(graph, "traceName"), {"trace1", "trace2"})

	jsonID = GetNumberFromWaveNote(graphUserData, TUD_INDEX_JSON)
	WAVE/T/Z traces = JSON_GetKeys(jsonID, "", esc = 0)
	CHECK_EQUAL_TEXTWAVES(traces, {"trace1", "trace2"})
	CHECK_EQUAL_VAR(JSON_GetVariable(jsonID, "/trace1"), 0)
	CHECK_EQUAL_VAR(JSON_GetVariable(jsonID, "/trace2"), 1)
End

// Test: TUD_TraceIsOnGraph
Function TraceIsOnGraphWorks()

	SVAR graph = root:graph

	WAVE/T/Z graphUserData = GetGraphUserData(graph)

	TUD_SetUserData(graph, "trace1", "key1", "value1")

	CHECK_EQUAL_VAR(TUD_TraceIsOnGraph(graph, "trace1"), 1)
	CHECK_EQUAL_VAR(TUD_TraceIsOnGraph(graph, "trace2"), 0)
End
