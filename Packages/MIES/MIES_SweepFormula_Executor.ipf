#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors = 1

#ifdef AUTOMATED_TESTING
#pragma ModuleName = MIES_SFE
#endif // AUTOMATED_TESTING

// to enable debug mode with more persistent data
// #define SWEEPFORMULA_DEBUG

/// @file MIES_SweepFormula_Executor.ipf
///
/// @brief __SFE__ Sweep formula Executor executes a parsed sweep formula

static Constant SFE_VARIABLE_PREFIX = 36

/// @brief Executes a given formula without changing the current SweepFormula notebook
///        supports by default variable assignments
///        does not support "with" and "and" keywords
/// @param formula formula string to execute
/// @param graph name of databrowser window
/// @param singleResult [optional, default 0], if set then the first dataSet is retrieved from the waveRef wave and returned, the waveRef wave is disposed
/// @param checkExist [optional, default 0], only valid if singleResult=1, if set then the data wave in the single dataSet retrieved must exist
/// @param useVariables [optional, default 1], when not set, hint the function that the formula string contains only an expression and no variable definitions
Function/WAVE SFE_ExecuteFormula(string formula, string graph, [variable singleResult, variable checkExist, variable useVariables])

	variable jsonId

	singleResult = ParamIsDefault(singleResult) ? 0 : !!singleResult
	checkExist   = ParamIsDefault(checkExist) ? 0 : !!checkExist
	useVariables = ParamIsDefault(useVariables) ? 1 : !!useVariables

	formula = SF_PreprocessInput(formula)
	if(useVariables)
		formula = SFE_ExecuteVariableAssignments(graph, formula)
	endif
	jsonId = SFP_ParseFormulaToJSON(formula)
	WAVE/Z result = SFE_FormulaExecutor(graph, jsonId)
	JSON_Release(jsonId, ignoreErr = 1)

	WAVE/WAVE out = SF_ResolveDataset(result)
	if(singleResult)
		SFH_ASSERT(DimSize(out, ROWS) == 1, "Expected only a single dataSet")
		WAVE/Z data = out[0]
		SFH_ASSERT(!(checkExist && !WaveExists(data)), "No data in dataSet returned from executed formula.")
		SFH_CleanUpInput(out)
		return data
	endif

	return out
End

Function/S SFE_ExecuteVariableAssignments(string graph, string preProcCode)

	variable i, numAssignments, jsonId
	string code

	WAVE/WAVE varStorage = GetSFVarStorage(graph)
	RemoveAllDimLabels(varStorage)
	Redimension/N=(0, -1) varStorage

	[WAVE/T varAssignments, code] = SF_GetVariableAssignments(preProcCode)
	if(!WaveExists(varAssignments))
		return code
	endif

	numAssignments = DimSize(varAssignments, ROWS)
	Redimension/N=(numAssignments) varStorage

	for(i = 0; i < numAssignments; i += 1)
		jsonId = SFP_ParseFormulaToJSON(varAssignments[i][%EXPRESSION])
		WAVE dataRef = SFE_FormulaExecutor(graph, jsonId)
		WAVE data    = SF_ResolveDataset(dataRef)
		JWN_SetNumberInWaveNote(data, SF_VARIABLE_MARKER, 1)
		varStorage[i] = dataRef
		SetDimLabel ROWS, i, $varAssignments[i][%VARNAME], varStorage
		JSON_Release(jsonId)
	endfor

	return code
End

/// @brief Execute the formula parsed by SF_FormulaParser
///
/// Recursively executes the formula parsed into jsonID.
///
/// @param graph    graph to read from, mainly used by the `data` operation
/// @param jsonID   JSON object ID from the JSON XOP
/// @param jsonPath JSON pointer compliant path
Function/WAVE SFE_FormulaExecutor(string graph, variable jsonID, [string jsonPath])

	string opName, str
	variable i, size, JSONType, arrayElemJSONType, effectiveArrayDimCount, dim
	variable colSize, layerSize, chunkSize, operationsWithScalarResultCount

	if(ParamIsDefault(jsonPath))
		jsonPath = ""
	endif

#ifdef DEBUGGING_ENABLED
	if(DP_DebuggingEnabledForCaller())
		printf "##########################\r"
		printf "%s\r", JSON_Dump(jsonID, indent = 2)
		printf "##########################\r"
	endif
#endif // DEBUGGING_ENABLED

	// object and array evaluation
	JSONtype = JSON_GetType(jsonID, jsonPath)
	if(JSONtype == JSON_NUMERIC)
		Make/FREE/D out = {JSON_GetVariable(jsonID, jsonPath)}
		return SFH_GetOutputForExecutorSingle(out, graph, "ExecutorNumberReturn")
	elseif(JSONtype == JSON_STRING)
		return SFE_FormulaExecutorStringOrVariable(graph, jsonId, jsonPath)
	elseif(JSONtype == JSON_ARRAY)
		// Evaluate an array consisting of any elements including subarrays and objects (operations)

		// If we want to return an Igor Pro data wave the final dimensionality can not exceed 4
		WAVE topArraySize = JSON_GetMaxArraySize(jsonID, jsonPath)
		effectiveArrayDimCount = DimSize(topArraySize, ROWS)
		SFH_ASSERT(effectiveArrayDimCount <= MAX_DIMENSION_COUNT, "Array in evaluation has more than " + num2istr(MAX_DIMENSION_COUNT) + "dimensions.", jsonId = jsonId)
		// Check against empty array
		if(DimSize(topArraySize, ROWS) == 1 && topArraySize[0] == 0)
			Make/FREE/D/N=0 out
			return SFH_GetOutputForExecutorSingle(out, graph, "ExecutorNumberReturn")
		endif

		// Get all types of current level (row)
		Make/FREE/N=(topArraySize[0]) types = JSON_GetType(jsonID, jsonPath + "/" + num2istr(p))
		// Do not allow null, that can happen if a formula like "integrate()" is executed and SF_GetArgumentTop attempts to parse all arguments into one array
		FindValue/V=(JSON_NULL) types
		SFH_ASSERT(!(V_Value >= 0), "Encountered null element in array.", jsonId = jsonId)

		Redimension/N=(MAX_DIMENSION_COUNT) topArraySize
		topArraySize[] = (topArraySize[p] != 0) ? topArraySize[p] : 1

		Make/FREE/D/N=0 indicesOfOperationsWithScalarResult
		WAVE/ZZ   out
		WAVE/ZZ/T outT

		// Get indices of Objects, Arrays and Strings on current level
		EXTRACT/FREE/INDX types, arrElemAt, (types[p] == JSON_OBJECT) || (types[p] == JSON_ARRAY) || (types[p] == JSON_STRING) || (types[p] == JSON_NUMERIC)
		// Iterate over all subarrays and objects on current level
		for(index : arrElemAt)
			WAVE/WAVE genericElement = SF_ResolveDatasetFromJSON(jsonId, jsonPath, graph, index)
			if(DimSize(genericElement, ROWS) == 1)
				// single dataset
				WAVE/Z subArray = genericElement[0]
				SFH_ASSERT(WaveExists(subArray), "no data in array element")
				if(IsTextWave(subArray))
					WAVE/Z numericalAttempt = SFE_ConvertNonFiniteElements(subArray)
					if(WaveExists(numericalAttempt))
						WAVE subArray = numericalAttempt
						[out, outT] = SFE_ExecutorCreateOrCheckNumeric(out, outT, topArraySize[0], topArraySize[1], topArraySize[2], topArraySize[3])
					else
						[out, outT] = SFE_ExecutorCreateOrCheckTextual(out, outT, topArraySize[0], topArraySize[1], topArraySize[2], topArraySize[3])
					endif
				elseif(IsNumericWave(subArray))
					[out, outT] = SFE_ExecutorCreateOrCheckNumeric(out, outT, topArraySize[0], topArraySize[1], topArraySize[2], topArraySize[3])
				else
					[out, outT] = SFE_ExecutorCreateOrCheckTextual(out, outT, topArraySize[0], topArraySize[1], topArraySize[2], topArraySize[3])
					WAVE subArrayWrapped = SFH_GetOutputForExecutor(subArray, graph, "WrappedArrayElement")
					WAVE subArray        = subArrayWrapped
				endif
			else
				// multi dataset
				[out, outT] = SFE_ExecutorCreateOrCheckTextual(out, outT, topArraySize[0], topArraySize[1], topArraySize[2], topArraySize[3])
				WAVE subArray = SFH_GetOutputForExecutor(genericElement, graph, "WrappedArrayElement")
			endif

			SFH_ASSERT(numpnts(subArray), "Encountered subArray with zero size.")
			SFH_ASSERT(WaveDims(subArray) < MAX_DIMENSION_COUNT, "Encountered 4d sub array at " + jsonPath)

			// Promote WaveNote with meta data if topArray is 1 point.
			// The single topArray element is object or array at this point
			if(WaveExists(out) && numpnts(out) == 1)
				Note/K out, note(subArray)
			endif
			if(WaveExists(outT) && numpnts(outT) == 1)
				Note/K outT, note(subArray)
			endif

			// do expand array dimensionality if
			// - original source was a array
			// - original source was not: a string that resolved to a scalar datum (the source string can refer to a variable that was resolved)
			// - original source was not: a object (aka operation) that resolved to a scalar datum
			if(types[index] == JSON_ARRAY || !((types[index] == JSON_STRING || types[index] == JSON_OBJECT || types[index] == JSON_NUMERIC) && WaveDims(subArray) == 1 && numpnts(subArray) == 1))
				// subArray will be inserted into the current array, thus the dimension will be WaveDims(subArray) + 1
				// Thus, [1, [2]] returns the correct wave of size (2, 1) with {{1, 2}}.
				effectiveArrayDimCount = max(effectiveArrayDimCount, WaveDims(subArray) + 1)
			endif

			// If the whole JSON array consists of STRING or NUMERIC types then topArraySize already is of the correct size.
			// If we encounter an Object aka operation it could return an array that is larger than a single element,
			// then we might have to resize beyond the original topArraySize.
			// Increase 4D array size tracking according to new data
			topArraySize[1, *] = max(topArraySize[p], DimSize(subArray, p - 1))
			WAVE outCombinedType = SelectWave(WaveExists(outT), out, outT)
			// resize data according to new topArraySize adapted by sub array size and fill new elements with NaN
			if((DimSize(outCombinedType, COLS) < topArraySize[1]) ||   \
			   (DimSize(outCombinedType, LAYERS) < topArraySize[2]) || \
			   (DimSize(outCombinedType, CHUNKS) < topArraySize[3]))

				if(WaveExists(out))
					Duplicate/FREE out, outTmp
					Redimension/N=(topArraySize[0], topArraySize[1], topArraySize[2], topArraySize[3]) outTmp
					FastOp outTmp = (NaN)
					Multithread outTmp[0, DimSize(out, ROWS) - 1][0, DimSize(out, COLS) - 1][0, DimSize(out, LAYERS) - 1][0, DimSize(out, CHUNKS) - 1] = out[p][q][r][s]
					WAVE out = outTmp
				endif
				if(WaveExists(outT))
					Redimension/N=(topArraySize[0], topArraySize[1], topArraySize[2], topArraySize[3]) outT
				endif
			endif
			if(WaveExists(out))
				SFE_PlaceSubArrayAt(out, subArray, index)
			else
				SFE_PlaceSubArrayAt(outT, subArray, index)
			endif

			// Save indices of operation/subArray evaluations that returned scalar results
			if(numpnts(subArray) == 1)
				EnsureLargeEnoughWave(indicesOfOperationsWithScalarResult, indexShouldExist = operationsWithScalarResultCount)
				indicesOfOperationsWithScalarResult[operationsWithScalarResultCount] = index
				operationsWithScalarResultCount                                     += 1
			endif
		endfor
		Redimension/N=(operationsWithScalarResultCount) indicesOfOperationsWithScalarResult

		// SCALAR EXTENSION
		// Find all indices that are not subArray or objects but either string or numeric, depending on final type determined above
		// As the first element is string or numeric, the array element itself is a skalar.
		// We also consider operations/subArrays that returned a scalar result that we gathered above.
		// The non-skalar case:
		// If from object elements (operations) the topArraySize is increased and as example one operations returns a 3x3 array
		// and another operation a 2x2 array, then for the first operation the topArraySize increase happens, the data from the
		// second operation is just filled in the array with remaining "untouched" elements in that row. These elements stay with the fill
		// value NaN or "".
		arrayElemJSONType = WaveExists(outT) ? JSON_STRING : JSON_NUMERIC
		EXTRACT/FREE/INDX types, indices, types[p] == arrayElemJSONType
		Concatenate/FREE/NP {indicesOfOperationsWithScalarResult}, indices
		if(WaveExists(outT))
			for(index : indices)
				Multithread outT[index][][][] = outT[index][0][0][0]
			endfor
		else
			for(index : indices)
				Multithread out[index][][][] = out[index][0][0][0]
			endfor
		endif

		// out can be text or numeric, afterwards if following code has no type expectations
		if(WaveExists(outT))
			WAVE out = outT
		endif
		// shrink data to actual array size
		for(dim = effectiveArrayDimCount; dim < MAX_DIMENSION_COUNT; dim += 1)
			ASSERT(topArraySize[dim] == 1, "Inconsistent array dimension size")
			topArraySize[dim] = 0
		endfor
		Redimension/N=(topArraySize[0], topArraySize[1], topArraySize[2], topArraySize[3])/E=1 out
		return SFH_GetOutputForExecutorSingle(out, graph, "ExecutorArrayReturn")
	endif

	// operation evaluation
	SFH_ASSERT(JSONtype == JSON_OBJECT, "Topmost element needs to be an object", jsonId = jsonId)
	WAVE/T operations = JSON_GetKeys(jsonID, jsonPath)
	SFH_ASSERT(DimSize(operations, ROWS) == 1, "Only one operation is allowed", jsonId = jsonId)
	jsonPath += "/" + SF_EscapeJsonPath(operations[0])
	SFH_ASSERT(JSON_GetType(jsonID, jsonPath) == JSON_ARRAY, "An array is required to hold the operands of the operation.", jsonId = jsonId)

	opName = LowerStr(operations[0])
#ifdef AUTOMATED_TESTING
	strswitch(opName)
		case SF_OP_MINUS: // fallthrough
		case SF_OP_PLUS: // fallthrough
		case SF_OP_DIV: // fallthrough
		case SF_OP_MULT: // fallthrough
		case SF_OP_RANGESHORT:
			break
		default:
			WAVE ops = SF_GetNamedOperations()
			ASSERT(GetRowIndex(ops, str = opName) >= 0, "List of operations with long name is out of date as the following is missing: " + opName)
			break
	endswitch
#endif // AUTOMATED_TESTING

	/// @name SweepFormulaOperations
	///@{
	strswitch(opName)
		case SF_OP_MINUS:
			WAVE out = SFO_OperationMinus(jsonId, jsonPath, graph)
			break
		case SF_OP_PLUS:
			WAVE out = SFO_OperationPlus(jsonId, jsonPath, graph)
			break
		case SF_OP_DIV: // division
			WAVE out = SFO_OperationDiv(jsonId, jsonPath, graph)
			break
		case SF_OP_MULT:
			WAVE out = SFO_OperationMult(jsonId, jsonPath, graph)
			break
		case SF_OP_RANGE: // fallthrough
		case SF_OP_RANGESHORT:
			WAVE out = SFO_OperationRange(jsonId, jsonPath, graph)
			break
		case SF_OP_CONCAT:
			WAVE out = SFO_OperationConcat(jsonId, jsonPath, graph)
			break
		case SF_OP_MIN:
			WAVE out = SFO_OperationMin(jsonId, jsonPath, graph)
			break
		case SF_OP_MAX:
			WAVE out = SFO_OperationMax(jsonId, jsonPath, graph)
			break
		case SF_OP_AVG: // fallthrough
		case SF_OP_MEAN:
			WAVE out = SFO_OperationAvg(jsonId, jsonPath, graph)
			break
		case SF_OP_RMS:
			WAVE out = SFO_OperationRMS(jsonId, jsonPath, graph)
			break
		case SF_OP_VARIANCE:
			WAVE out = SFO_OperationVariance(jsonId, jsonPath, graph)
			break
		case SF_OP_STDEV:
			WAVE out = SFO_OperationStdev(jsonId, jsonPath, graph)
			break
		case SF_OP_DERIVATIVE:
			WAVE out = SFO_OperationDerivative(jsonId, jsonPath, graph)
			break
		case SF_OP_INTEGRATE:
			WAVE out = SFO_OperationIntegrate(jsonId, jsonPath, graph)
			break
		case SF_OP_EPOCHS:
			WAVE out = SFO_OperationEpochs(jsonId, jsonPath, graph)
			break
		case SF_OP_AREA:
			WAVE out = SFO_OperationArea(jsonId, jsonPath, graph)
			break
		case SF_OP_BUTTERWORTH:
			WAVE out = SFO_OperationButterworth(jsonId, jsonPath, graph)
			break
		case SF_OP_TIME: // fallthrough
		case SF_OP_XVALUES:
			WAVE out = SFO_OperationXValues(jsonId, jsonPath, graph)
			break
		case SF_OP_TEXT:
			WAVE out = SFO_OperationText(jsonId, jsonPath, graph)
			break
		case SF_OP_SETSCALE:
			WAVE out = SFO_OperationSetScale(jsonId, jsonPath, graph)
			break
		case SF_OP_WAVE:
			WAVE out = SFO_OperationWave(jsonId, jsonPath, graph)
			break
		case SF_OP_SELECTCHANNELS:
			WAVE out = SFO_OperationSelectChannels(jsonId, jsonPath, graph)
			break
		case SF_OP_SELECTSWEEPS:
			WAVE out = SFO_OperationSelectSweeps(jsonId, jsonPath, graph)
			break
		case SF_OP_DATA:
			WAVE out = SFO_OperationData(jsonId, jsonPath, graph)
			break
		case SF_OP_LABNOTEBOOK:
			WAVE out = SFO_OperationLabnotebook(jsonId, jsonPath, graph)
			break
		case SF_OP_ANAFUNCPARAM:
			WAVE out = SFO_OperationAnaFuncParam(jsonId, jsonPath, graph)
			break
		case SF_OP_LOG: // JSON logic debug operation
			WAVE out = SFO_OperationLog(jsonId, jsonPath, graph)
			break
		case SF_OP_LOG10: // decadic logarithm
			WAVE out = SFO_OperationLog10(jsonId, jsonPath, graph)
			break
		case SF_OP_CURSORS:
			WAVE out = SFO_OperationCursors(jsonId, jsonPath, graph)
			break
		case SF_OP_FINDLEVEL:
			WAVE out = SFO_OperationFindLevel(jsonId, jsonPath, graph)
			break
		case SF_OP_APFREQUENCY:
			WAVE out = SFO_OperationApFrequency(jsonId, jsonPath, graph)
			break
		case SF_OP_TP:
			WAVE out = SFO_OperationTP(jsonId, jsonPath, graph)
			break
		case SF_OP_STORE:
			WAVE out = SFO_OperationStore(jsonId, jsonPath, graph)
			break
		case SF_OP_SELECT:
			WAVE out = SFO_OperationSelect(jsonId, jsonPath, graph)
			break
		case SF_OP_POWERSPECTRUM:
			WAVE out = SFO_OperationPowerSpectrum(jsonId, jsonPath, graph)
			break
		case SF_OP_TPSS:
			WAVE out = SFO_OperationTPSS(jsonId, jsonPath, graph)
			break
		case SF_OP_TPINST:
			WAVE out = SFO_OperationTPInst(jsonId, jsonPath, graph)
			break
		case SF_OP_TPBASE:
			WAVE out = SFO_OperationTPBase(jsonId, jsonPath, graph)
			break
		case SF_OP_TPFIT:
			WAVE out = SFO_OperationTPFit(jsonId, jsonPath, graph)
			break
		case SF_OP_PSX:
			WAVE out = PSX_Operation(jsonId, jsonPath, graph)
			break
		case SF_OP_PSX_KERNEL:
			WAVE out = PSX_OperationKernel(jsonId, jsonPath, graph)
			break
		case SF_OP_PSX_STATS:
			WAVE out = PSX_OperationStats(jsonId, jsonPath, graph)
			break
		case SF_OP_PSX_RISETIME:
			WAVE out = PSX_OperationRiseTime(jsonId, jsonPath, graph)
			break
		case SF_OP_PSX_PREP:
			WAVE out = PSX_OperationPrep(jsonId, jsonPath, graph)
			break
		case SF_OP_PSX_DECONV_FILTER:
			WAVE out = PSX_OperationDeconvFilter(jsonId, jsonPath, graph)
			break
		case SF_OP_MERGE:
			WAVE out = SFO_OperationMerge(jsonId, jsonPath, graph)
			break
		case SF_OP_FIT:
			WAVE out = SFO_OperationFit(jsonId, jsonPath, graph)
			break
		case SF_OP_FITLINE:
			WAVE out = SFO_OperationFitLine(jsonId, jsonPath, graph)
			break
		case SF_OP_DATASET:
			WAVE out = SFO_OperationDataset(jsonId, jsonPath, graph)
			break
		case SF_OP_SELECTVIS:
			WAVE out = SFO_OperationSelectVis(jsonId, jsonPath, graph)
			break
		case SF_OP_SELECTEXP:
			WAVE out = SFO_OperationSelectExperiment(jsonId, jsonPath, graph)
			break
		case SF_OP_SELECTDEV:
			WAVE out = SFO_OperationSelectDevice(jsonId, jsonPath, graph)
			break
		case SF_OP_SELECTEXPANDSCI:
			WAVE out = SFO_OperationSelectExpandSCI(jsonId, jsonPath, graph)
			break
		case SF_OP_SELECTEXPANDRAC:
			WAVE out = SFO_OperationSelectExpandRAC(jsonId, jsonPath, graph)
			break
		case SF_OP_SELECTSETCYCLECOUNT:
			WAVE out = SFO_OperationSelectSetCycleCount(jsonId, jsonPath, graph)
			break
		case SF_OP_SELECTSETSWEEPCOUNT:
			WAVE out = SFO_OperationSelectSetSweepCount(jsonId, jsonPath, graph)
			break
		case SF_OP_SELECTSCIINDEX:
			WAVE out = SFO_OperationSelectSCIIndex(jsonId, jsonPath, graph)
			break
		case SF_OP_SELECTRACINDEX:
			WAVE out = SFO_OperationSelectRACIndex(jsonId, jsonPath, graph)
			break
		case SF_OP_SELECTCM:
			WAVE out = SFO_OperationSelectCM(jsonId, jsonPath, graph)
			break
		case SF_OP_SELECTSTIMSET:
			WAVE out = SFO_OperationSelectStimset(jsonId, jsonPath, graph)
			break
		case SF_OP_SELECTIVSCCSWEEPQC:
			WAVE out = SFO_OperationSelectIVSCCSweepQC(jsonId, jsonPath, graph)
			break
		case SF_OP_SELECTIVSCCSETQC:
			WAVE out = SFO_OperationSelectIVSCCSetQC(jsonId, jsonPath, graph)
			break
		case SF_OP_SELECTRANGE:
			WAVE out = SFO_OperationSelectRange(jsonId, jsonPath, graph)
			break
		default:
			SFH_FATAL_ERROR("Undefined Operation", jsonId = jsonId)
	endswitch
	///@}

	return out
End

static Function/WAVE SFE_FormulaExecutorStringOrVariable(string graph, variable jsonId, string jsonPath)

	string   str
	variable dim

	str = JSON_GetString(jsonID, jsonPath)
	if(strlen(str) > 1 && char2num(str[0]) == SFE_VARIABLE_PREFIX)
		WAVE/WAVE varStorage = GetSFVarStorage(graph)
		dim = FindDimLabel(varStorage, ROWS, str[1, Inf])
		SFH_ASSERT(dim != -2, "Unknown variable " + str[1, Inf])
		return varStorage[dim]
	endif

	Make/FREE/T outT = {str}
	return SFH_GetOutputForExecutorSingle(outT, graph, "ExecutorStringReturn")
End

static Function/WAVE SFE_ConvertNonFiniteElements(WAVE/T subArray)

	Make/FREE/D/N=(DimSize(subArray, ROWS), DimSize(subArray, COLS), DimSize(subArray, LAYERS), DimSize(subArray, CHUNKS)) convert
	MultiThread convert[][][][] = SFE_ConvertNonFiniteElementsImpl(subArray[p][q][r][s])
	if(HasOneFiniteEntry(convert))
		return $""
	endif

	return convert
End

threadsafe static Function SFE_ConvertNonFiniteElementsImpl(string element)

	if(!CmpStr(element, "inf"))
		return Inf
	elseif(!CmpStr(element, "-inf"))
		return -Inf
	elseif(!CmpStr(element, "NaN"))
		return NaN
	elseif(!CmpStr(element, "-NaN"))
		return NaN
	endif

	return 0
End

static Function [WAVE outNum, WAVE/T outText] SFE_ExecutorCreateOrCheckNumeric(WAVE/Z/D out, WAVE/Z/T outT, variable size0, variable size1, variable size2, variable size3)

	SFH_ASSERT(!WaveExists(outT), "mixed array types")
	if(!WaveExists(out))
		Make/FREE/D/N=(size0, size1, size2, size3) out
	endif

	return [out, outT]
End

static Function [WAVE outNum, WAVE/T outText] SFE_ExecutorCreateOrCheckTextual(WAVE/Z out, WAVE/Z/T outT, variable size0, variable size1, variable size2, variable size3)

	SFH_ASSERT(!WaveExists(out), "mixed array types")
	if(!WaveExists(outT))
		Make/FREE/T/N=(size0, size1, size2, size3) outT
	endif

	return [out, outT]
End

static Function SFE_PlaceSubArrayAt(WAVE/Z out, WAVE/Z subArray, variable index)

	if(!WaveExists(out))
		return NaN
	endif

	SF_FormulaWaveScaleTransfer(subArray, out, ROWS, COLS)
	SF_FormulaWaveScaleTransfer(subArray, out, COLS, LAYERS)
	SF_FormulaWaveScaleTransfer(subArray, out, LAYERS, CHUNKS)
	// Copy max 3d subarray to data
	if(IsTextWave(out))
		WAVE/T outT      = out
		WAVE/T subArrayT = subArray
		Multithread outT[index][0, max(0, DimSize(subArray, ROWS) - 1)][0, max(0, DimSize(subArray, COLS) - 1)][0, max(0, DimSize(subArray, LAYERS) - 1)] = subArrayT[q][r][s]
	else
		Multithread out[index][0, max(0, DimSize(subArray, ROWS) - 1)][0, max(0, DimSize(subArray, COLS) - 1)][0, max(0, DimSize(subArray, LAYERS) - 1)] = subArray[q][r][s]
	endif
End
