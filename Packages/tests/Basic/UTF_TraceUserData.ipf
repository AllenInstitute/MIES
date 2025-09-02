#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors = 1
#pragma ModuleName       = TraceUserDataTest

static Function TEST_CASE_BEGIN_OVERRIDE(string name)

	TestCaseBeginCommon(name)

	JSONXOP_Release/A

	Display
	string/G root:graph = S_name
End

// Test: GetGraphUserData
Function CreatesWave()

	SVAR graph = root:graph

	WAVE/Z/T graphUserData = GetGraphUserData(graph)
	CHECK_WAVE(graphUserData, TEXT_WAVE)

	CHECK_EQUAL_VAR(DimSize(graphUserData, COLS), 0)

	CHECK_EQUAL_VAR(GetNumberFromWaveNote(graphUserData, NOTE_INDEX), 0)
	CHECK(JSON_IsValid(GetNumberFromWaveNote(graphUserData, TUD_INDEX_JSON)))
End

Function KillGraphAndCheckEmptyUserData_IGNORE(string graph, WAVE/T graphUserData, [variable clearInstead])

	variable modCount

	if(ParamIsDefault(clearInstead))
		clearInstead = 0
	else
		clearInstead = !!clearInstead
	endif

	modCount = WaveModCount(graphUserData)

	if(clearInstead)
		TUD_Clear(graph, recursive = 0)
	else
		KillWindow $GetMainWindow(graph)
		DoUpdate

		CHECK(!WindowExists(graph))
	endif

	CHECK_GT_VAR(WaveModCount(graphUserData), modCount)

	CHECK_EQUAL_VAR(GetNumberFromWaveNote(graphUserData, NOTE_INDEX), 0)
	CHECK_EQUAL_VAR(GetNumberFromWaveNote(graphUserData, TUD_INDEX_JSON), NaN)

	Make/FREE/N=(DimSize(graphUserData, ROWS), DimSize(graphUserData, COLS)) sizes = strlen(graphUserData[p][q])
	CHECK_EQUAL_VAR(Sum(sizes), 0)
End

// Test: GetGraphUserData, TUD_Clear, TUD_Init
Function ClearsWaveOnKillWindow()

	SVAR graph = root:graph

	WAVE/Z/T graphUserData = GetGraphUserData(graph)

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

// Test: TUD_Clear
Function ClearsWaveOnKillWindowRecursively()

	string panel, subGraph

	// and now with a subwindow which has a graph
	NewPanel
	panel = S_name
	Display/HOST=$panel
	subGraph = panel + "#" + S_name

	WAVE/Z/T graphUserData = GetGraphUserData(subGraph)

	TUD_Init(subGraph)
	TUD_SetUserData(subGraph, "trace1", "efgh", "ijkl")

	KillGraphAndCheckEmptyUserData_IGNORE(subGraph, graphUserData)
End

// Test: TUD_Clear
Function ClearDoesHonourRecursiveFlag()

	string graph, subGraph, subPanel
	variable modCount

	// and now with an external subwindow graph
	Display
	graph = S_name
	NewPanel/HOST=$graph/EXT=1
	subPanel = graph + "#" + S_name
	Display/HOST=$subPanel
	subGraph = subPanel + "#" + S_name

	TUD_Init(graph)
	TUD_SetUserData(graph, "trace1", "efgh", "ijkl")

	TUD_Init(subGraph)
	TUD_SetUserData(subGraph, "trace1", "efgh", "ijkl")

	WAVE/Z/T graphUserData    = GetGraphUserData(graph)
	WAVE/Z/T subGraphUserData = GetGraphUserData(subGraph)

	modCount = WaveModCount(subGraphUserData)

	KillGraphAndCheckEmptyUserData_IGNORE(graph, graphUserData, clearInstead = 1)

	CHECK_WAVE(subGraphUserData, TEXT_WAVE)

	// subGraph was not touched
	CHECK_EQUAL_VAR(WaveModCount(subGraphUserData), modCount)

	CHECK_EQUAL_VAR(GetNumberFromWaveNote(subGraphUserData, NOTE_INDEX), 1)
	CHECK_GE_VAR(GetNumberFromWaveNote(subGraphUserData, TUD_INDEX_JSON), 0)
End

// Test: TUD_SetUserData
Function SetUserDataWorks()

	variable jsonID
	string expected, actual

	SVAR graph = root:graph

	WAVE/Z/T graphUserData = GetGraphUserData(graph)

	TUD_SetUserData(graph, "trace1", "key", "value")

	CHECK_EQUAL_VAR(GetNumberFromWaveNote(graphUserData, NOTE_INDEX), 1)

	// check indexing json
	jsonID = GetNumberFromWaveNote(graphUserData, TUD_INDEX_JSON)
	WAVE/Z/T traces = JSON_GetKeys(jsonID, "", esc = 0)
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

	WAVE/Z/T graphUserData = GetGraphUserData(graph)

	TUD_SetUserDataFromWaves(graph, "trace1", {"key1", "key2"}, {"value1", "value2"})

	CHECK_EQUAL_VAR(GetNumberFromWaveNote(graphUserData, NOTE_INDEX), 1)

	// check indexing json
	jsonID = GetNumberFromWaveNote(graphUserData, TUD_INDEX_JSON)
	WAVE/Z/T traces = JSON_GetKeys(jsonID, "", esc = 0)
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

	WAVE/Z/T graphUserData = GetGraphUserData(graph)

	TUD_SetUserData(graph, "trace1", "key1", "value1")
	TUD_SetUserDataFromWaves(graph, "trace1", {"key2", "key3"}, {"value2", "value3"})

	CHECK_EQUAL_VAR(GetNumberFromWaveNote(graphUserData, NOTE_INDEX), 1)

	// check indexing json
	jsonID = GetNumberFromWaveNote(graphUserData, TUD_INDEX_JSON)
	WAVE/Z/T traces = JSON_GetKeys(jsonID, "", esc = 0)
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

	WAVE/Z/T graphUserData = GetGraphUserData(graph)

	TUD_SetUserDataFromWaves(graph, "trace1", {"key1", "key2"}, {"value1", "value2"})
	TUD_SetUserData(graph, "trace1", "key3", "value3")

	CHECK_EQUAL_VAR(GetNumberFromWaveNote(graphUserData, NOTE_INDEX), 1)

	// check indexing json
	jsonID = GetNumberFromWaveNote(graphUserData, TUD_INDEX_JSON)
	WAVE/Z/T traces = JSON_GetKeys(jsonID, "", esc = 0)
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

	WAVE/Z/T graphUserData = GetGraphUserData(graph)

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

	WAVE/Z/T graphUserData = GetGraphUserData(graph)

	TUD_SetUserData(graph, "trace1", "key", "value")

	// check indexing json
	jsonIDOld = GetNumberFromWaveNote(graphUserData, TUD_INDEX_JSON)
	WAVE/Z/T traces = JSON_GetKeys(jsonIDOld, "", esc = 0)
	CHECK_EQUAL_TEXTWAVES(traces, {"trace1"})

	JSON_Release(jsonIDOld)

	// fetch Index JSON to trigger regeneration
	jsonIDNew = MIES_TUD#TUD_GetIndexJSON(graphUserData)
	WAVE/Z/T traces = JSON_GetKeys(jsonIDNew, "", esc = 0)
	CHECK_EQUAL_TEXTWAVES(traces, {"trace1"})

	CHECK(jsonIDOld != jsonIDNew)
End

// Test: TUD_GetUserData
Function GetUserDataExpectsExistingTraceAndKey()

	SVAR graph = root:graph

	WAVE/Z/T graphUserData = GetGraphUserData(graph)

	TUD_SetUserData(graph, "trace1", "key", "value")

	try
		TUD_GetUserData(graph, "I DONT EXIST", "key")
		FAIL()
	catch
		PASS()
	endtry

	try
		TUD_GetUserData(graph, "trace1", "I DONT EXIST")
		FAIL()
	catch
		PASS()
	endtry
End

// Test: TUD_GetUserData
Function GetUserDataWorks()

	string actual, expected

	SVAR graph = root:graph

	WAVE/Z/T graphUserData = GetGraphUserData(graph)

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

// Test: TUD_GetAllUserData
Function GetAllUserDataExpectsExistingTrace()

	SVAR graph = root:graph

	WAVE/Z/T graphUserData = GetGraphUserData(graph)

	TUD_SetUserData(graph, "trace1", "key", "value")

	try
		WAVE/Z wv = TUD_GetAllUserData(graph, "I DONT EXIST")
		FAIL()
	catch
		PASS()
	endtry

	try
		WAVE/Z wv = TUD_GetAllUserData(graph, "wrongTraceName")
		FAIL()
	catch
		PASS()
	endtry
End

// Test: TUD_GetAllUserData
Function GetAllUserDataWorks()

	SVAR graph = root:graph

	WAVE/Z/T graphUserData = GetGraphUserData(graph)

	TUD_SetUserDataFromWaves(graph, "trace1", {"key1", "key2"}, {"value1", "value2"})
	TUD_SetUserData(graph, "trace1", "key3", "value3")

	WAVE/Z actual = TUD_GetAllUserData(graph, "trace1")
	CHECK_WAVE(actual, TEXT_WAVE)

	Make/FREE/T ref = {"trace1", "value1", "value2", "value3"}
	SetDimensionLabels(ref, "traceName;key1;key2;key3;", ROWS)
	CHECK_EQUAL_TEXTWAVES(actual, ref, mode = DIMENSION_LABELS)
End

// Test: TUD_GetUserDataAsWave
Function GetUserDataAsWaveChecksInput()

	SVAR graph = root:graph

	WAVE/Z/T graphUserData = GetGraphUserData(graph)

	WAVE/Z result = TUD_GetUserDataAsWave(graph, "I DONT EXIST")
	// no traces exist
	CHECK_WAVE(result, NULL_WAVE)

	TUD_SetUserData(graph, "trace1", "key3", "value3")

	try
		TUD_GetUserDataAsWave(graph, "I DONT EXIST")
		FAIL()
	catch
		PASS()
	endtry

	// both keys/values must be present or absent
	try
		TUD_GetUserDataAsWave(graph, "traceName", keys = {"traceName"})
		FAIL()
	catch
		PASS()
	endtry

	// both keys/values must be present or absent
	try
		TUD_GetUserDataAsWave(graph, "traceName", values = {"trace1"})
		FAIL()
	catch
		PASS()
	endtry

	// mismatched keys/values sizes
	try
		TUD_GetUserDataAsWave(graph, "traceName", keys = {"a", "b"}, values = {"c"})
		FAIL()
	catch
		PASS()
	endtry

	// mismatched keys/values sizes
	try
		TUD_GetUserDataAsWave(graph, "traceName", keys = {"a"}, values = {"b", "c"})
		FAIL()
	catch
		PASS()
	endtry

	// non-existing key
	try
		TUD_GetUserDataAsWave(graph, "traceName", keys = {"a"}, values = {"b"})
		FAIL()
	catch
		PASS()
	endtry
End

// Test: TUD_GetUserDataAsWave
Function GetUserDataAsWaveWorksBasic()

	SVAR graph = root:graph

	WAVE/Z/T graphUserData = GetGraphUserData(graph)

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

	WAVE/Z/T graphUserData = GetGraphUserData(graph)

	TUD_SetUserData(graph, "trace1", "key1", "value1")
	TUD_SetUserData(graph, "trace2", "key2", "value2")
	MakE/FREE/D ref = {0, 1}

	WAVE/Z result = TUD_GetUserDataAsWave(graph, "traceName", returnIndizes = 1)
	CHECK_WAVE(result, NUMERIC_WAVE)
	CHECK_EQUAL_WAVES(result, ref)

	WAVE/Z result = TUD_GetUserDataAsWave(graph, "key1", returnIndizes = 1)
	CHECK_WAVE(result, NUMERIC_WAVE)
	CHECK_EQUAL_WAVES(result, ref)

	WAVE/Z result = TUD_GetUserDataAsWave(graph, "key2", returnIndizes = 1)
	CHECK_WAVE(result, NUMERIC_WAVE)
	CHECK_EQUAL_WAVES(result, ref)
End

// Test: TUD_GetUserDataAsWave
Function GetUserDataAsWaveWorksComplex()

	SVAR graph = root:graph

	WAVE/Z/T graphUserData = GetGraphUserData(graph)

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

	WAVE/Z/T graphUserData = GetGraphUserData(graph)

	TUD_SetUserData(graph, "trace1", "key1", "value1")
	TUD_SetUserData(graph, "trace2", "key2", "value2")

	WAVE/Z result = TUD_GetUserDataAsWave(graph, "traceName", keys = {"key1"}, values = {"value1"}, returnIndizes = 1)
	CHECK_WAVE(result, NUMERIC_WAVE)
	Make/FREE/D ref = {0}
	CHECK_EQUAL_WAVES(result, ref)

	WAVE/Z result = TUD_GetUserDataAsWave(graph, "traceName", keys = {"key2"}, values = {"value2"}, returnIndizes = 1)
	CHECK_WAVE(result, NUMERIC_WAVE)
	Make/FREE/D ref = {1}
	CHECK_EQUAL_WAVES(result, ref)

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

	SVAR graph = root:graph

	// expects existing trace
	try
		TUD_RemoveUserData(graph, "I DONT EXIST")
		FAIL()
	catch
		PASS()
	endtry
End

static Function PrepareUserDataWaveForRemoval_IGNORE()

	variable jsonID

	SVAR graph = root:graph

	WAVE/Z/T graphUserData = GetGraphUserData(graph)
	KillWaves/Z graphUserData

	WAVE/Z/T graphUserData = GetGraphUserData(graph)

	TUD_SetUserData(graph, "trace1", "key1", "value1")
	TUD_SetUserData(graph, "trace2", "key2", "value2")
	TUD_SetUserData(graph, "trace3", "key3", "value3")

	Redimension/N=(3, -1) graphUserData
	CHECK_EQUAL_VAR(GetNumberFromWaveNote(graphUserData, NOTE_INDEX), 3)
	CHECK_EQUAL_TEXTWAVES(TUD_GetUserDataAsWave(graph, "traceName"), {"trace1", "trace2", "trace3"})

	jsonID = GetNumberFromWaveNote(graphUserData, TUD_INDEX_JSON)
	WAVE/Z/T traces = JSON_GetKeys(jsonID, "", esc = 0)
	CHECK_EQUAL_TEXTWAVES(traces, {"trace1", "trace2", "trace3"})
End

// Test: TUD_RemoveUserData
Function RemoveUserDataWorks()

	variable jsonID

	SVAR graph = root:graph

	PrepareUserDataWaveForRemoval_IGNORE()

	WAVE/Z/T graphUserData = GetGraphUserData(graph)

	// remove the first entry
	TUD_RemoveUserData(graph, "trace1")
	CHECK_EQUAL_VAR(DimSize(graphUserData, ROWS), 2)
	CHECK_EQUAL_VAR(GetNumberFromWaveNote(graphUserData, NOTE_INDEX), 2)
	CHECK_EQUAL_TEXTWAVES(TUD_GetUserDataAsWave(graph, "traceName"), {"trace2", "trace3"})

	jsonID = GetNumberFromWaveNote(graphUserData, TUD_INDEX_JSON)
	WAVE/Z/T traces = JSON_GetKeys(jsonID, "", esc = 0)
	CHECK_EQUAL_TEXTWAVES(traces, {"trace2", "trace3"})
	CHECK_EQUAL_VAR(JSON_GetVariable(jsonID, "/trace2"), 0)
	CHECK_EQUAL_VAR(JSON_GetVariable(jsonID, "/trace3"), 1)

	PrepareUserDataWaveForRemoval_IGNORE()

	WAVE/Z/T graphUserData = GetGraphUserData(graph)

	// remove the second entry
	TUD_RemoveUserData(graph, "trace2")
	CHECK_EQUAL_VAR(DimSize(graphUserData, ROWS), 2)
	CHECK_EQUAL_VAR(GetNumberFromWaveNote(graphUserData, NOTE_INDEX), 2)
	CHECK_EQUAL_TEXTWAVES(TUD_GetUserDataAsWave(graph, "traceName"), {"trace1", "trace3"})

	jsonID = GetNumberFromWaveNote(graphUserData, TUD_INDEX_JSON)
	WAVE/Z/T traces = JSON_GetKeys(jsonID, "", esc = 0)
	CHECK_EQUAL_TEXTWAVES(traces, {"trace1", "trace3"})
	CHECK_EQUAL_VAR(JSON_GetVariable(jsonID, "/trace1"), 0)
	CHECK_EQUAL_VAR(JSON_GetVariable(jsonID, "/trace3"), 1)

	PrepareUserDataWaveForRemoval_IGNORE()

	WAVE/Z/T graphUserData = GetGraphUserData(graph)

	// remove last entry
	TUD_RemoveUserData(graph, "trace3")
	CHECK_EQUAL_VAR(DimSize(graphUserData, ROWS), 2)
	CHECK_EQUAL_VAR(GetNumberFromWaveNote(graphUserData, NOTE_INDEX), 2)
	CHECK_EQUAL_TEXTWAVES(TUD_GetUserDataAsWave(graph, "traceName"), {"trace1", "trace2"})

	jsonID = GetNumberFromWaveNote(graphUserData, TUD_INDEX_JSON)
	WAVE/Z/T traces = JSON_GetKeys(jsonID, "", esc = 0)
	CHECK_EQUAL_TEXTWAVES(traces, {"trace1", "trace2"})
	CHECK_EQUAL_VAR(JSON_GetVariable(jsonID, "/trace1"), 0)
	CHECK_EQUAL_VAR(JSON_GetVariable(jsonID, "/trace2"), 1)
End

// Test: TUD_TraceIsOnGraph
Function TraceIsOnGraphWorks()

	SVAR graph = root:graph

	WAVE/Z/T graphUserData = GetGraphUserData(graph)

	TUD_SetUserData(graph, "trace1", "key1", "value1")

	CHECK_EQUAL_VAR(TUD_TraceIsOnGraph(graph, "trace1"), 1)
	CHECK_EQUAL_VAR(TUD_TraceIsOnGraph(graph, "trace2"), 0)
End
