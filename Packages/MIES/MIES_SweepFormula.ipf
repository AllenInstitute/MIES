#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

static Constant STATE_DEFAULT = 0
static Constant STATE_COLLECT = 1
static Constant STATE_ADDITION = 2
static Constant STATE_SUBTRACTION = 3
static Constant STATE_MULTIPLICATION = 4
static Constant STATE_DIVISION = 5
static Constant STATE_PARENTHESIS = 6
static Constant STATE_FUNCTION = 7
static Constant STATE_ARRAY = 8
static Constant STATE_ARRAYELEMENT = 9

static Constant ACTION_SKIP = 0
static Constant ACTION_COLLECT = 1
static Constant ACTION_CALCULATION = 2
static Constant ACTION_SAMECALCULATION = 3
static Constant ACTION_HIGHERORDER = 4
static Constant ACTION_ARRAYELEMENT = 5
static Constant ACTION_PARENTHESIS = 6
static Constant ACTION_FUNCTION = 7
static Constant ACTION_ARRAY = 8

/// @brief serialize a string formula into JSON
///
/// @param formula  string formula
/// @returns a JSONid representation
Function FormulaParser(formula)
	String formula

	Variable i, parenthesisStart, parenthesisEnd, jsonIDdummy, jsonIDarray
	String tempPath
	Variable action = -1
	String token = ""
	Variable state = STATE_DEFAULT
	Variable lastState = STATE_DEFAULT
	Variable lastCalculation = -1
	Variable level = 0
	Variable arrayLevel = 0

	Variable jsonID = JSON_New()
	String jsonPath = ""

	if(strlen(formula) == 0)
		return jsonID
	endif

	for(i = 0; i < strlen(formula); i += 1)
		// state
		strswitch(formula[i])
			case "/":
				state = STATE_DIVISION
				break
			case "*":
				state = STATE_MULTIPLICATION
				break
			case "-":
				state = STATE_SUBTRACTION
				break
			case "+":
				state = STATE_ADDITION
				break
			case "(":
				level += 1
				break
			case ")":
				level -= 1
				if(!cmpstr(token[0], "("))
					state = STATE_PARENTHESIS
					break
				endif
				if(GrepString(token, "^[A-Za-z]"))
					state = STATE_FUNCTION
					break
				endif
				state = STATE_DEFAULT
				break
			case "[":
				arrayLevel += 1
				break
			case "]":
				arrayLevel -= 1
				state = STATE_ARRAY
				break
			case ",":
				state = STATE_ARRAYELEMENT
				break
			default:
				state = STATE_COLLECT
				ASSERT(GrepString(formula[i], "[A-Za-z0-9_\.;]"), "undefined pattern in formula")
		endswitch
		if(level > 0 || arrayLevel > 0)
			state = STATE_DEFAULT
		endif

		// state transition
		action = ACTION_COLLECT
		if(state != lastState)
			switch(state)
				case STATE_ADDITION:
					if(lastCalculation == STATE_SUBTRACTION)
						action = ACTION_HIGHERORDER
						break
					endif
				case STATE_SUBTRACTION:
					if(lastCalculation == STATE_MULTIPLICATION)
						action = ACTION_HIGHERORDER
						break
					endif
				case STATE_MULTIPLICATION:
					if(lastCalculation == STATE_DIVISION)
						action = ACTION_HIGHERORDER
						break
					endif
				case STATE_DIVISION:
					if(!cmpstr(token, ""))
						if(lastCalculation == -1)
							action = ACTION_HIGHERORDER
						else
							action = ACTION_SKIP
						endif
						break
					endif
					action = ACTION_CALCULATION
					if(state == lastCalculation)
						action = ACTION_SAMECALCULATION
					endif
					if(lastCalculation == STATE_ARRAYELEMENT)
						action = ACTION_COLLECT
					endif
					break
				case STATE_PARENTHESIS:
					action = ACTION_PARENTHESIS
					if(lastCalculation == STATE_ARRAYELEMENT)
						action = ACTION_COLLECT
					endif
					break
				case STATE_FUNCTION:
					action = ACTION_FUNCTION
					if(lastCalculation == STATE_ARRAYELEMENT)
						action = ACTION_COLLECT
					endif
					break
				case STATE_ARRAYELEMENT:
					action = ACTION_ARRAYELEMENT
					if(lastCalculation != STATE_ARRAYELEMENT)
						action = ACTION_HIGHERORDER
					endif
					break
				case STATE_ARRAY:
					action = ACTION_ARRAY
					break
				case STATE_COLLECT:
				case STATE_DEFAULT:
					action = ACTION_COLLECT
					break
				default:
					ASSERT(0, "Encountered undefined transition " + num2str(state))
			endswitch
			lastState = state
		endif

		// action
		switch(action)
			case ACTION_COLLECT:
				token += formula[i]
			case ACTION_SKIP:
				continue
			case ACTION_FUNCTION:
				tempPath = jsonPath
				if(JSON_GetType(jsonID, jsonPath) == JSON_ARRAY)
					JSON_AddObjects(jsonID, jsonPath)
					tempPath += "/" + num2str(JSON_GetArraySize(jsonID, jsonPath) - 1)
				endif
				tempPath += "/"
				parenthesisStart = strsearch(token, "(", 0, 0)
				tempPath += EscapeJsonPath(token[0, parenthesisStart - 1])
				jsonIDdummy = FormulaParser(token[parenthesisStart + 1, inf])
				if(JSON_GetType(jsonIDdummy, "") != JSON_ARRAY)
					JSON_AddTreeArray(jsonID, tempPath)
				endif
				JSON_AddJSON(jsonID, tempPath, jsonIDdummy)
				JSON_Release(jsonIDdummy)
				break
			case ACTION_PARENTHESIS:
				JSON_AddJSON(jsonID, jsonPath, FormulaParser(token[1, inf]))
				break
			case ACTION_HIGHERORDER:
				lastCalculation = state
				if(!!cmpstr(token, ""))
					JSON_AddJSON(jsonID, jsonPath, FormulaParser(token))
				endif
				jsonPath = EscapeJsonPath(formula[i])
				if(!cmpstr(jsonPath, ",") || !cmpstr(jsonPath, "]"))
					jsonPath = ""
				endif
				jsonIDdummy = jsonID
				jsonID = JSON_New()
				JSON_AddTreeArray(jsonID, jsonPath)
				JSON_AddJSON(jsonID, jsonPath, jsonIDdummy)
				JSON_Release(jsonIDdummy)
				break
			case ACTION_ARRAY:
				ASSERT(!cmpstr(token[0], "["), "Encountered array ending without array start.")
				jsonIDarray = JSON_New()
				jsonIDdummy = FormulaParser(token[1,inf])
				if(JSON_GetType(jsonIDdummy, "") != JSON_ARRAY)
					JSON_AddTreeArray(jsonIDarray, "")
				endif
				JSON_AddJSON(jsonIDarray, "", jsonIDdummy)
				JSON_Release(jsonIDdummy)
				JSON_AddJSON(jsonID, jsonPath, jsonIDarray)
				JSON_Release(jsonIDarray)
				break
			case ACTION_CALCULATION:
				if(JSON_GetType(jsonID, jsonPath) == JSON_ARRAY)
					JSON_AddObjects(jsonID, jsonPath) // prepare for decent
					jsonPath += "/" + num2str(JSON_GetArraySize(jsonID, jsonPath) - 1)
				endif
				jsonPath += "/" + EscapeJsonPath(formula[i])
			case ACTION_ARRAYELEMENT:
				JSON_AddTreeArray(jsonID, jsonPath)
				lastCalculation = state
			case ACTION_SAMECALCULATION:
			default:
				if(strlen(token) > 0)
					JSON_AddJSON(jsonID, jsonPath, FormulaParser(token))
				endif
		endswitch
		token = ""
	endfor

	// last element (recursion)
	if(!cmpstr(token, formula))
		if(GrepString(token, "^(?i)[0-9]+(?:\.[0-9]+)?(?:[\+-]?E[0-9]+)?$"))
			JSON_AddVariable(jsonID, jsonPath, str2num(formula))
		else
			JSON_AddString(jsonID, jsonPath, token)
		endif
	elseif(strlen(token) > 0)
		JSON_AddJSON(jsonID, jsonPath, FormulaParser(token))
	endif

	return jsonID
End

// @brief add escape characters to a path element
Function/S EscapeJsonPath(str)
	String str

	return ReplaceString("/", str, "~1")
End

Function/WAVE FormulaExecutor(jsonID, [jsonPath, graph])
	Variable jsonID
	String jsonPath
	String graph

	Variable i, numIndices, JSONtype

	if(ParamIsDefault(jsonPath))
		jsonPath = ""
	endif
	if(ParamIsDefault(graph))
		graph = ""
	endif

	// object and array evaluation
	JSONtype = JSON_GetType(jsonID, jsonPath)
	if(JSONtype == JSON_NUMERIC)
		Make/FREE out = { JSON_GetVariable(jsonID, jsonPath) }
		return out
	elseif(JSONtype == JSON_STRING)
		Make/FREE/T outT = { JSON_GetString(jsonID, jsonPath) }
		return outT
	elseif(JSONtype == JSON_ARRAY)
		WAVE topArraySize = JSON_GetMaxArraySize(jsonID, jsonPath)
		Make/FREE/N=(topArraySize[0])/B types = JSON_GetType(jsonID, jsonPath + "/" + num2str(p))

		if(topArraySize[0] != 0 && types[0] == JSON_STRING)
			ASSERT(DimSize(topArraySize, ROWS) <= 1, "Text Waves Must Be 1-dimensional.")
			return JSON_GetTextWave(jsonID, jsonPath)
		endif
		EXTRACT/FREE types, strings, types[p] == JSON_STRING
		ASSERT(DimSize(strings, ROWS) == 0, "Object evaluation For Mixed Text/Numeric Arrays Is Not Allowed")
		WaveClear strings

		ASSERT(DimSize(topArraySize, ROWS) < 4, "Unhandled Data Alignment. Only 3 Dimensions Are Supported For Operations.")
		WAVE out = JSON_GetWave(jsonID, jsonPath)

		Redimension/N=4 topArraySize
		topArraySize[] = topArraySize[p] != 0 ? topArraySize[p] : 1
		Redimension/N=(topArraySize[0], topArraySize[1], topArraySize[2], topArraySize[3])/E=1 out

		EXTRACT/FREE/INDX types, indices, (types[p] == JSON_OBJECT) || (types[p] == JSON_ARRAY)
		if(DimSize(indices, ROWS) == 1 && DimSize(out, ROWS) == 1)
			return FormulaExecutor(jsonID, jsonPath = jsonPath + "/" + num2str(indices[0]), graph = graph)
		endif
		for(i = 0; i < DimSize(indices, ROWS); i += 1)
			WAVE element = FormulaExecutor(jsonID, jsonPath = jsonPath + "/" + num2str(indices[i]), graph = graph)
			if(DimSize(element, CHUNKS) > 1)
				DebugPrint("Merging Chunks To Layers for object: " + jsonPath + "/" + num2str(indices[i]))
				Redimension/N=(-1, -1, max(1, DimSize(element, LAYERS)) * DimSize(element, CHUNKS), 0)/E=1 element
			endif
			topArraySize[1,*] = max(topArraySize[p], DimSize(element, p - 1))
			if((DimSize(out, ROWS)   < topArraySize[0]) || \
			   (DimSize(out, COLS)   < topArraySize[1]) || \
			   (DimSize(out, LAYERS) < topArraySize[2]) || \
			   (DimSize(out, CHUNKS) < topArraySize[3]))
				Redimension/N=(topArraySize[0], topArraySize[1], topArraySize[2], topArraySize[3]) out
			endif
			FormulaWaveScaleTransfer(element, out, ROWS, COLS)
			FormulaWaveScaleTransfer(element, out, COLS, LAYERS)
			FormulaWaveScaleTransfer(element, out, LAYERS, CHUNKS)
			out[indices[i]][0, max(0, DimSize(element, ROWS) - 1)][0, max(0, DimSize(element, COLS) - 1)][0, max(0, DimSize(element, LAYERS) - 1)] = element[q][r][s]
		endfor

		topArraySize[1,*] = topArraySize[p] == 1 ? 0 : topArraySize[p]
		Redimension/N=(topArraySize[0], topArraySize[1], topArraySize[2], topArraySize[3])/E=1 out

		return out
	endif

	// operation evaluation
	ASSERT(JSONtype == JSON_OBJECT, "Topmost element needs to be an object")
	WAVE/T operations = JSON_GetKeys(jsonID, jsonPath)
	ASSERT(DimSize(operations, ROWS) == 1, "Only one operation is allowed")
	jsonPath += "/" + EscapeJsonPath(operations[0])
	ASSERT(JSON_GetType(jsonID, jsonPath) == JSON_ARRAY, "An array is required to hold the operands of the operation.")
	strswitch(operations[0])
		case "cursors":
		case "channel":
			WAVE/T wvT = JSON_GetTextWave(jsonID, jsonPath)
			break
		case "sweeps":
			break
		default:
			WAVE wv = FormulaExecutor(jsonID, jsonPath = jsonPath, graph = graph)
	endswitch

	strswitch(operations[0])
		case "-":
			ASSERT(DimSize(wv, ROWS) >= 2, "At least two operands are required")
			MatrixOP/FREE out = (row(wv, 0) + sumCols((-1) * subRange(wv, 1, numRows(wv) - 1, 0, numCols(wv) - 1)))^t
			Redimension/N=(-1, DimSize(out, LAYERS), DimSize(out, CHUNKS), 0)/E=1 out
			break
		case "+":
			MatrixOP/FREE out = sumCols(wv)^t
			Redimension/N=(-1, DimSize(out, LAYERS), DimSize(out, CHUNKS), 0)/E=1 out
			break
		case "~1": // division
			ASSERT(DimSize(wv, ROWS) >= 2, "At least two operands are required")
			MatrixOP/FREE out = (row(wv, 0) / productCols(subRange(wv, 1, numRows(wv) - 1, 0, numCols(wv) - 1)))^t
			Redimension/N=(-1, DimSize(out, LAYERS), DimSize(out, CHUNKS), 0)/E=1 out
			break
		case "*":
			MatrixOP/FREE out = productCols(wv)^t
			Redimension/N=(-1, DimSize(out, LAYERS), DimSize(out, CHUNKS), 0)/E=1 out
			break
		case "min":
			ASSERT(DimSize(wv, LAYERS) <= 1, "Unhandled dimension")
			ASSERT(DimSize(wv, CHUNKS) <= 1, "Unhandled dimension")
			MatrixOP/FREE out = minCols(wv)^t
			break
		case "max":
			ASSERT(DimSize(wv, LAYERS) <= 1, "Unhandled dimension")
			ASSERT(DimSize(wv, CHUNKS) <= 1, "Unhandled dimension")
			MatrixOP/FREE out = maxCols(wv)^t
			break
		case "avg":
		case "mean":
			ASSERT(DimSize(wv, LAYERS) <= 1, "Unhandled dimension")
			ASSERT(DimSize(wv, CHUNKS) <= 1, "Unhandled dimension")
			MatrixOP/FREE out = averageCols(wv)^t
			FormulaWaveScaleTransfer(wv, out, COLS, ROWS)
			break
		case "variance":
			ASSERT(DimSize(wv, LAYERS) <= 1, "Unhandled dimension")
			ASSERT(DimSize(wv, CHUNKS) <= 1, "Unhandled dimension")
			MatrixOP/FREE out = (sumCols(magSqr(wv - rowRepeat(averageCols(wv), numRows(wv))))/(numRows(wv) - 1))^t
			break
		case "stdev":
			ASSERT(DimSize(wv, LAYERS) <= 1, "Unhandled dimension")
			ASSERT(DimSize(wv, CHUNKS) <= 1, "Unhandled dimension")
			MatrixOP/FREE out = (sqrt(sumCols(powR(wv - rowRepeat(averageCols(wv), numRows(wv)), 2))/(numRows(wv) - 1)))^t
			break
		case "merge":
			ASSERT(DimSize(wv, LAYERS) <= 1, "Unhandled dimension")
			ASSERT(DimSize(wv, CHUNKS) <= 1, "Unhandled dimension")
			MatrixOP/FREE transposed = wv^T
			Extract/FREE transposed, out, (p < (JSON_GetType(jsonID, jsonPath + "/" + num2str(q)) != JSON_ARRAY ? 1 : JSON_GetArraySize(jsonID, jsonPath + "/" + num2str(q))))
			break
		case "channel":
			Make/N=(DimSize(wvT, ROWS))/FREE out = WhichListItem(wvT[p], ITC_CHANNEL_NAMES)
			break
		case "sweeps":
			ASSERT(!ParamIsDefault(graph) && !!cmpstr(graph, ""), "Graph for extracting sweeps not specified.")
			WAVE range = FormulaExecutor(jsonID, jsonPath = jsonPath + "/0", graph = graph)
			ASSERT(DimSize(range, ROWS) == 2, "A range can not hold more than two points.")
			WAVE channel = FormulaExecutor(jsonID, jsonPath = jsonPath + "/1")
			ASSERT(DimSize(channel, ROWS) == 1, "Only one channel name is allowed.")
			WAVE/T sweeps = FormulaExecutor(jsonID, jsonPath = jsonPath + "/2", graph = graph)
			ASSERT(DimSize(sweeps, ROWS) == 1, "sweeps need to be given as a semicolon separated list.")
			return GetSweepForFormula(graph, range[0], range[1], channel[0], sweeps[0])
			break
		case "log": // JSON logic debug operation
			print wv[0]
			WAVE out = wv
			break
		case "log10": // decadic logarithm
			ASSERT(DimSize(wv, LAYERS) <= 1, "Unhandled dimension")
			ASSERT(DimSize(wv, CHUNKS) <= 1, "Unhandled dimension")
			MatrixOP/FREE out = log(wv)
			FormulaWaveScaleTransfer(wv, out, COLS, ROWS)
			break
		case "cursors":
			Make/FREE/N=(DimSize(wvT, ROWS)) out = NaN
			for(i = 0; i < DimSize(wvT, ROWS); i += 1)
				ASSERT(GrepString(wvT[i], "^(?i)[A-J]$"), "Invalid Cursor Name")
				if(ParamIsDefault(graph))
					out[i] = xcsr($wvT[i])
				else
					if(!cmpstr(CsrInfo($wvT[i], graph), ""))
						continue
					endif
					out[i] = xcsr($wvT[i], graph)
				endif
			endfor
			break
		default:
			ASSERT(0, "Undefined Operation")
	endswitch

	return out
End

Function/WAVE GetSweepForFormula(graph, rangeStart, rangeEnd, channelType, sweepList)
	String graph
	Variable rangeStart, rangeEnd
	Variable channelType
	String sweepList

	Variable i, numSweeps
	Variable pStart, pEnd

	ASSERT(WindowExists(graph), "graph window does not exist")
	ASSERT(isFinite(rangeStart) && isFinite(rangeEnd), "Specified range not valid.")

	WAVE/T traces = PA_GetTraceInfos(graph, channelType = channelType)
	Make/N=(DimSize(traces, ROWS))/FREE sweepListIndex = WhichListItem(traces[p][%sweepNumber], sweepList)
	Extract/FREE/INDX sweepListIndex, indices, sweepListIndex[p] != -1
	numSweeps = DimSize(indices, ROWS)
	if(numSweeps == 0)
		DebugPrint("No matching sweeps")
		return $""
	endif

	WAVE reference = $(traces[indices[0]][%fullPath])
	ASSERT(DimSize(reference, COLS) <= 1, "Unhandled Sweep Format.")

	pStart = ScaleToIndex(reference, rangeStart, ROWS)
	pEnd = ScaleToIndex(reference, rangeEnd, ROWS)
	ASSERT(pEnd < DimSize(reference, ROWS) && pStart >= 0, "Invalid sweep range.")
	Make/FREE/N=(abs(pStart - pEnd), numSweeps) sweeps
	SetScale/P x, IndexToScale(reference, pStart, ROWS), DimDelta(reference, ROWS), sweeps
	for(i = 0; i < numSweeps; i += 1)
		WAVE sweep = $(traces[indices[i]][%fullPath])
		pStart = IsFinite(rangeStart) ? ScaleToIndex(sweep, rangeStart, ROWS) : 0
		pEnd = IsFinite(rangeEnd) ? ScaleToIndex(sweep, rangeEnd, ROWS) : DimSize(reference, ROWS) - 1
		ASSERT(pEnd < DimSize(sweep, ROWS) && pStart >= 0, "Invalid sweep range.")
		ASSERt(abs(pStart - pEnd) == DimSize(sweeps, ROWS), "Sweeps not equal.")
		ASSERT(DimDelta(sweep, ROWS) == DimDelta(sweeps, ROWS), "Sweeps not equal.")
		sweeps[][i] = sweep[pStart + p]
	endfor

	return sweeps
End

/// @brief transfer the wave scaling from one wave to another
///
/// Note: wave scale transfer requires wave units for the first wave in the array that
///
/// @param source    Wave whos scaling should get transferred
/// @param dest      Wave that accepts the new scaling
/// @param dimSource dimension of the source wave
/// @param dimDest   dimension of the destination wave
///
/// @return 0 if wave scaling was transferred, 1 if not
Function FormulaWaveScaleTransfer(source, dest, dimSource, dimDest)
	WAVE source, dest
	Variable dimSource, dimDest

	if(cmpstr(WaveUnits(source, dimSource), "") && cmpstr(WaveUnits(dest, dimDest), ""))
		return 1
	endif

	switch(dimDest)
		case ROWS:
			SetScale/P x, DimOffset(source, dimSource), DimDelta(source, dimSource), WaveUnits(source, dimSource), dest
			break
		case COLS:
			SetScale/P y, DimOffset(source, dimSource), DimDelta(source, dimSource), WaveUnits(source, dimSource), dest
			break
		case LAYERS:
			SetScale/P z, DimOffset(source, dimSource), DimDelta(source, dimSource), WaveUnits(source, dimSource), dest
			break
		case CHUNKS:
			SetScale/P t, DimOffset(source, dimSource), DimDelta(source, dimSource), WaveUnits(source, dimSource), dest
			break
		default:
			return 1