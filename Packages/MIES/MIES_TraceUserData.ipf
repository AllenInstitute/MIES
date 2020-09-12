#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_TUD
#endif

/// @file MIES_TraceUserData.ipf
/// @brief This file holds helper functions to work with our own trace user data handling

/// @brief Window hook for clearing the user data of the attached graph
Function TUD_RemoveUserDataWave(s)
	STRUCT WMWinHookStruct &s

	switch(s.eventCode)
		case 2: // Kill
			TUD_Clear(s.winName)
			break
	endswitch

	// we always return zero here as other window hooks
	// might be registered for the window
	return 0
End

/// @brief Clear the user data wave and release the indexing JSON document
Function TUD_Clear(string graph)

	variable jsonID, index, i, numEntries

	WAVE/T graphUserData = GetGraphUserData(graph)

	jsonID = GetNumberFromWaveNote(graphUserData, TUD_INDEX_JSON)
	JSON_Release(jsonID, ignoreErr = 1)
	SetNumberInWaveNote(graphUserData, TUD_INDEX_JSON, NaN)

	index = GetnumberFromWaveNote(graphUserData, NOTE_INDEX)
	// @TODO remove the check once IP9 is mandatory
	if(index > 0)
		Multithread graphUserData[0, index - 1][] = ""
	endif

	// clear column dimension labels
	numEntries = DimSize(graphUserData, COLS)
	for(i = 0; i < numEntries; i += 1)
		SetDimLabel COLS, i, $"", graphUserData
	endfor

	Redimension/N=(-1, 0) graphUserData

	SetNumberInWaveNote(graphUserData, NOTE_INDEX, 0)
End

/// @brief Return the user data the given `graph` and `trace` named `key`
Function/S TUD_GetUserData(string graph, string trace, string key)

	variable row

	WAVE/T graphUserData = GetGraphUserData(graph)
	row = TUD_ConvertTraceNameToRowIndex(graphUserData, trace, create = 0)

	return graphUserData[row][%$key]
End

/// @brief Return the user data for `key` of all traces in graph in a 1D text wave
///
/// @param graph         existing graph
/// @param key           key value to gather data for
/// @param keys          [optional] Either both `keys` and `values` are present or none of them. These allow to further restrict
///                      the returned result to traces having all of the additional key/value pairs
/// @param values        [optional] See `key`
/// @param returnIndizes [optional, default to false] Return the indizes of the matches instead of the values
Function/WAVE TUD_GetUserDataAsWave(string graph, string key, [WAVE/T keys, WAVE/T values, variable returnIndizes])

	variable col, numEntries, i, index

	if(ParamIsDefault(returnIndizes))
		returnIndizes = 0
	else
		returnIndizes = !!returnIndizes
	endif

	WAVE/T graphUserData = GetGraphUserData(graph)

	index = GetNumberFromWaveNote(graphUserData, NOTE_INDEX)

	if(TUD_GetTraceCount(graph) == 0)
		return $""
	endif

	col = FindDimLabel(graphUserData, COLS, key)
	ASSERT(col >= 0, "Invalid key")
	Duplicate/FREE/RMD=[0, index - 1][col]/T graphUserData, result
	Note/K result

	Redimension/N=(-1) result

	if(ParamIsDefault(keys) && ParamIsDefault(values))
		if(returnIndizes)
			Make/N=(DimSize(result, ROWS))/FREE matches = p
			return matches
		else
			return result
		endif
	endif

	ASSERT(ParamIsDefault(keys) + ParamIsDefault(values) != 1, "Unexpected optional paramters")

	// both optional parameters are present

	Make/N=(DimSize(result, ROWS))/FREE matches = p

	ASSERT(EqualWaves(keys, values, 512) == 1, "Unexpected size")

	numEntries = DimSize(keys, ROWS)
	for(i = 0; i < numEntries; i += 1)
		WAVE/Z indizes = FindIndizes(graphUserData, colLabel = keys[i], str = values[i])

		if(!WaveExists(indizes))
			return $""
		endif

		WAVE/Z matchesReturn = GetSetIntersection(matches, indizes)

		if(!WaveExists(matchesReturn))
			return $""
		endif

		WAVE matches = matchesReturn
	endfor

	if(returnIndizes)
		return matches
	endif

	Redimension/N=(DimSize(matches, ROWS)) result

	result = graphUserData[matches[p]][col]

	return result
End


/// @brief Set the given user data for the trace of the graph
Function TUD_SetUserData(string graph, string trace, string key, string value)
	variable keyCol, row

	WAVE/T graphUserData = GetGraphUserData(graph)

	if(TUD_GetTraceCount(graph) == 0)
		 Redimension/N=(-1, 1) graphUserData
		 SetWaveDimLabel(graphUserData, "traceName", COLS)
	endif

	row = TUD_ConvertTraceNameToRowIndex(graphUserData, trace, create = 1)

	keyCol = FindDimLabel(graphUserData, COLS, key)
	if(keyCol == -2)
		keyCol = DimSize(graphUserData, COLS)
		Redimension/N=(-1, keyCol + 1) graphUserData
		SetDimLabel COLS, keyCol, $key, graphUserData
	endif

	graphUserData[row][keyCol] = value
End

/// @brief Set the given user data for the trace of the graph
///
/// The `keys`/`values` must span a consecutive range.
Function TUD_SetUserDataFromWaves(string graph, string trace, WAVE/T keys, WAVE/T values)
	variable row, numCols, first, last, numExistingCols

	ASSERT(EqualWaves(keys, values, 512) == 1, "Unexpected size")
	ASSERT(DimSize(keys, ROWS) > 0, "Unexpected empty wave")

	WAVE/T graphUserData = GetGraphUserData(graph)

	first = FindDimLabel(graphUserData, COLS, keys[0])
	last  = FindDimLabel(graphUserData, COLS, keys[DimSize(keys, ROWS) - 1])

	if(TUD_GetTraceCount(graph) == 0)
		numCols = DimSize(keys, ROWS) + 1
		Redimension/N=(-1, numCols) graphUserData
		SetWaveDimLabel(graphUserData, "traceName;" + TextWaveToList(keys, ";"), COLS)
		first = 1
		last  = numCols - 1
	elseif(first == -2 && last == -2)
		numExistingCols = DimSize(graphUserData, COLS)
		numCols = numExistingCols + DimSize(keys, ROWS)
		Redimension/N=(-1, numCols) graphUserData
		SetWaveDimLabel(graphUserData, TextWaveToList(keys, ";"), COLS, startPos = numExistingCols)
		first = numExistingCols
		last  = numCols - 1
	endif

	row = TUD_ConvertTraceNameToRowIndex(graphUserData, trace, create = 1)

	ASSERT(last >= 0, "Invalid last key")
	ASSERT(first >= 0, "Invalid first key")
	graphUserData[row][first, last] = values[q - first]
End

/// @brief Return the number of traces in the user data
Function TUD_GetTraceCount(string graph)

	WAVE/T graphUserData = GetGraphUserData(graph)
	return GetNumberFromWaveNote(graphUserData, NOTE_INDEX)
End

/// @brief Remove all user data from the given trace
Function TUD_RemoveUserData(string graph, string trace)

	WAVE/T graphUserData = GetGraphUserData(graph)
	TUD_RemoveTrace(graphUserData, trace)
End

/// @brief Check if the given trace is displayed on the graph
Function TUD_TraceIsOnGraph(string graph, string trace)
	WAVE/T graphUserData = GetGraphUserData(graph)
	return TUD_ConvertTraceNameToRowIndex(graphUserData, trace, create = 0, allowMissing = 1) >= 0
End

/// @brief Initialize the graph for our user trace data handling
///
/// This is done implicitly after the user data wave is created. Once that is cleared
/// with TUD_Clear() and the window is gone, this function can be used to reattach
/// the cleanup hook to the newly created graph.
Function TUD_Init(string graph)
	ASSERT(WinType(graph) == 1, "Expected graph")
	SetWindow $graph, hook(traceUserDataCleanup) = TUD_RemoveUserDataWave
End

static Function TUD_AddTrace(variable jsonID, WAVE/T graphUserData, string trace)

	variable index, traceCol

	jsonID = TUD_GetIndexJSON(graphUserData)

	index = GetNumberFromWaveNote(graphUserData, NOTE_INDEX)
	EnsureLargeEnoughWave(graphUserData, minimumSize = index)
	graphUserData[index][%traceName] = trace
	SetNumberInWaveNote(graphUserData, NOTE_INDEX, index + 1)

	JSON_AddVariable(jsonID, "/" + trace, index)

	return index
End

static Function TUD_RemoveTrace(WAVE/T graphUserData, string trace)

	variable row, index, jsonID, tracesNeedingUpdate

	row = TUD_ConvertTraceNameToRowIndex(graphUserData, trace, create = 0)

	DeletePoints/M=(ROWS) row, 1, graphUserData

	index = GetNumberFromWaveNote(graphUserData, NOTE_INDEX)
	SetNumberInWaveNote(graphUserData, NOTE_INDEX, --index)

	jsonID = TUD_GetIndexJSON(graphUserData)

	JSON_Remove(jsonID, "/" + trace)

	tracesNeedingUpdate = index - row
	if(tracesNeedingUpdate == 0)
		return NaN
	endif

	Make/FREE/N=(tracesNeedingUpdate) junkWave = JSON_SetVariable(jsonID, "/" + graphUserData[row + p][%traceName], row + p)
End

static Function TUD_ConvertTraceNameToRowIndex(WAVE/T graphUserData, string trace, [variable create, variable allowMissing])

	variable var, index, jsonID

	if(ParamIsDefault(create))
		create = 0
	else
		create = !!create
	endif

	if(ParamIsDefault(allowMissing))
		allowMissing = 0
	else
		allowMissing = !!allowMissing
	endif

	ASSERT(IsValidObjectName(trace), "trace is not a valid object name")

	jsonID = TUD_GetIndexJSON(graphUserData)

	if(create == 0)
		return JSON_GetVariable(jsonID, "/" + trace, ignoreErr=allowMissing)
	endif

	var = JSON_GetVariable(jsonID, "/" + trace, ignoreErr = 1)
	if(!IsNaN(var))
		return var
	endif

	return TUD_AddTrace(jsonID, graphUserData, trace)
End

static Function TUD_GetIndexJSON(Wave/T graphUserData)

	variable jsonID

	jsonID = GetNumberFromWaveNote(graphUserData, TUD_INDEX_JSON)

	if(IsFinite(jsonID) && JSON_Exists(jsonID, ""))
		return jsonID
	endif

	jsonID = JSON_New()
	SetNumberInWaveNote(graphUserData, TUD_INDEX_JSON, jsonID)
	TUD_RegenerateJSONIndex(jsonID, graphUserData)

	return jsonID
End

static Function TUD_RegenerateJSONIndex(variable jsonID, WAVE/T graphUserData)

	variable i, index

	index = GetNumberFromWaveNote(graphUserData, NOTE_INDEX)
	for(i = 0; i < index; i += 1)
		JSON_AddVariable(jsonID, "/" + graphUserData[i][%traceName], i)
	endfor
End
