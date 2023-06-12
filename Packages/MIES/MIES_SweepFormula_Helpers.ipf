#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_SFH_HELPERS
#endif

/// @file MIES_SweepFormula_Helpers.ipf
///
/// @brief __SFH__ Sweep formula related helper code

static StrConstant SFH_WORKING_DF = "FormulaData"
static StrConstant SFH_ARGSETUP_OPERATION_KEY = "Operation"
static StrConstant SFH_ARGSETUP_EMPTY_OPERATION_VALUE = "NOOP"

/// @brief Convenience helper function to get a numeric SweepFormula operation argument
///
/// Given the operation `fetchBeer(variable numBottles, [variable size])` one can fetch both parameters via:
///
/// \rst
/// .. code-block:: text
///
///    opShort    = "fetchBeer"
///    numBottles = SFH_GetArgumentAsNumeric(jsonId, jsonPath, graph, opShort, 0)
///    size       = SFH_GetArgumentAsNumeric(jsonId, jsonPath, graph, opShort, 1, defValue = 0.5, allowedValues = {0.33, 0.5, 1.0})
///
/// \endrst
///
/// Here `numBottles` is argument number 0 and mandatory as `defValue` is not present.
///
/// The second argument `size` is optional with 0.5 as default and also defines a list of valid values.
Function SFH_GetArgumentAsNumeric(variable jsonId, string jsonPath, string graph, string opShort, variable argNum, [variable defValue, WAVE/Z allowedValues])

	string msg, sep, allowedValuesAsStr
	variable checkExist, numArgs, result, idx

	if(ParamIsDefault(defValue))
		checkExist = 1
	else
		checkExist = 0
	endif

	numArgs = SFH_GetNumberOfArguments(jsonId, jsonPath)

	if(argNum < numArgs)
		WAVE/Z data = SFH_ResolveDatasetElementFromJSON(jsonId, jsonPath, graph, opShort, argNum, checkExist = checkExist)
		sprintf msg, "Argument #%d of operation %s: Is a NULL wave reference ", argNum, opShort
		SFH_ASSERT(WaveExists(data), msg)

		sprintf msg, "Argument #%d of operation %s: Must be numeric ", argNum, opShort
		SFH_ASSERT(IsNumericWave(data), msg)

		sprintf msg, "Argument #%d of operation %s: Too many input values", argNum, opShort
		SFH_ASSERT(DimSize(data, ROWS) == 1 && DimSize(data, COLS) == 0, msg)

		result = data[0]
	else
		sprintf msg, "Argument #%d of operation %s is mandatory", argNum, opShort
		SFH_ASSERT(!checkExist, msg)

		result = defValue
	endif

	if(!ParamIsDefault(allowedValues))
		ASSERT(WaveExists(allowedValues) && IsNumericWave(allowedValues), "allowedValues must be a numeric wave")

		idx = GetRowIndex(allowedValues, val = result)
		if(IsNaN(idx))
			sep = ", "
			allowedValuesAsStr = RemoveEnding(NumericWaveToList(allowedValues, sep), sep)
			sprintf msg, "Argument #%d of operation %s: The numeric argument \"%g\" is not one of the allowed values (%s)", argNum, opShort, result, allowedValuesAsStr
			SFH_ASSERT(0, msg)
		endif
	endif

	return result
End

/// @brief Convenience helper function to get a textual SweepFormula operation argument
///
/// Given the operation `getTrainTable(string date, [string type])` one can fetch both parameters via:
///
/// \rst
/// .. code-block:: text
///
///    opShort = "getTrainTable"
///    date    = SFH_GetArgumentAsText(jsonId, jsonPath, graph, opShort, 0)
///    type    = SFH_GetArgumentAsText(jsonId, jsonPath, graph, opShort, 1, defValue = "steam train", allowedValues = {"steam train", "light rail"})
///
/// \endrst
///
/// Here `date` is argument number 0 and mandatory as `defValue` is not present.
///
/// The second argument `type` is optional with `steam train` as default and a list of allowed values.
///
/// The text argument can be abbreviated as long as it is unique, the unabbreviated result is returned in all cases.
Function/S SFH_GetArgumentAsText(variable jsonId, string jsonPath, string graph, string opShort, variable argNum, [string defValue, WAVE/T/Z allowedValues])

	string msg, result, sep, allowedValuesAsStr
	variable checkExist, numArgs, idx

	if(ParamIsDefault(defValue))
		checkExist = 1
	else
		checkExist = 0
	endif

	numArgs = SFH_GetNumberOfArguments(jsonId, jsonPath)

	if(argNum < numArgs)
		WAVE/T/Z data = SFH_ResolveDatasetElementFromJSON(jsonId, jsonPath, graph, opShort, argNum, checkExist = checkExist)
		sprintf msg, "Argument #%d of operation %s: Is a NULL wave reference ", argNum, opShort
		SFH_ASSERT(WaveExists(data), msg)

		sprintf msg, "Argument #%d of operation %s: Must be text ", argNum, opShort
		SFH_ASSERT(IsTextWave(data), msg)

		sprintf msg, "Argument #%d of operation %s: Too many input values", argNum, opShort
		SFH_ASSERT(DimSize(data, ROWS) == 1 && DimSize(data, COLS) == 0, msg)

		result = data[0]
	else
		sprintf msg, "Argument #%d of operation %s is mandatory", argNum, opShort
		SFH_ASSERT(!checkExist, msg)

		result = defValue
	endif

	if(!ParamIsDefault(allowedValues))
		ASSERT(WaveExists(allowedValues) && IsTextWave(allowedValues), "allowedValues must be a text wave")

		// search are allowed entries and try to match a unique abbreviation
		WAVE/T/Z matches = GrepTextWave(allowedValues, "(?i)^\\Q" + result + "\\E.*$")
		if(!WaveExists(matches))
			sep = ", "
			allowedValuesAsStr = RemoveEnding(TextWaveToList(allowedValues, sep), sep)
			sprintf msg, "Argument #%d of operation %s: The text argument \"%s\" is not one of the allowed values (%s)", argNum, opShort, result, allowedValuesAsStr
			SFH_ASSERT(0, msg)
		elseif(DimSize(matches, ROWS) > 1)
			sep = ", "
			allowedValuesAsStr = RemoveEnding(TextWaveToList(matches, sep), sep)
			sprintf msg, "Argument #%d of operation %s: The abbreviated text argument \"%s\" is not unique and could be (%s)", argNum, opShort, result, allowedValuesAsStr
			SFH_ASSERT(0, msg)
		else
			ASSERT(DimSize(matches, ROWS) == 1, "Unexpected match")
			// replace abbreviated argument with the full name
			result = matches[0]
		endif
	endif

	return result
End

/// @brief Convenience helper function to get a wave SweepFormula operation argument
///
/// Given the operation `countBirds(array birds, [birdTypes()])` one can fetch both parameters via:
///
/// \rst
/// .. code-block:: text
///
///    opShort      = "countBirds"
///    WAVE/D birds = SFH_GetArgumentAsWave(jsonId, jsonPath, graph, opShort, 0, singleResult = 1)
///    WAVE/T types = SFH_GetArgumentAsWave(jsonId, jsonPath, graph, opShort, 1, defOp = "birdTypes()", singleResult = 1)
///
/// \endrst
///
/// Here `birds` is argument number 0 and mandatory as `defOp` is not present. Passing `singleResult == 1` already
/// unpacks the outer wave reference wave container. It should always be passed if you only expect one wave to be
/// returned.
///
/// The second argument `birdTypes` is optional, if not present the operation `birdTypes()` is called and its result returned.
Function/WAVE SFH_GetArgumentAsWave(variable jsonId, string jsonPath, string graph, string opShort, variable argNum, [string defOp, variable singleResult])

	variable checkExist, numArgs
	string msg

	if(ParamIsDefault(defOp))
		checkExist = 1
	else
		checkExist = 0
	endif

	if(ParamIsDefault(singleResult))
		singleResult = 0
	else
		singleResult = !!singleResult
	endif

	numArgs = SFH_GetNumberOfArguments(jsonId, jsonPath)

	if(argNum < numArgs)
		if(singleResult)
			WAVE/Z data = SFH_ResolveDatasetElementFromJSON(jsonId, jsonPath, graph, opShort, argNum, checkExist = checkExist)
		else
			WAVE data = SF_ResolveDatasetFromJSON(jsonId, jsonPath, graph, argNum)
		endif

		return data
	endif

	sprintf msg, "Argument #%d of operation %s is mandatory", argNum, opShort
	SFH_ASSERT(!checkExist, msg)

	return SF_ExecuteFormula(defOp, graph, singleResult = singleResult, useVariables=0)
End

/// @brief Assertion for sweep formula
///
/// This assertion does *not* indicate a general programmer error but a
/// sweep formula user error.
///
/// All programmer error checks must still use ASSERT().
///
/// UTF_NOINSTRUMENTATION
Function SFH_ASSERT(variable condition, string message[, variable jsonId])

	if(!condition)
		if(!ParamIsDefault(jsonId))
			JSON_Release(jsonId, ignoreErr=1)
		endif
		SVAR error = $GetSweepFormulaParseErrorMessage()
		error = message
#ifdef AUTOMATED_TESTING_DEBUGGING
		Debugger
#endif
		Abort
	endif
End

Function/WAVE SFH_GetEmptyRange()

	Make/FREE/D range = {NaN, NaN}

	return range
End

Function SFH_IsEmptyRange(WAVE range)

	ASSERT(IsNumericWave(range), "Invalid Range wave")
	WAVE rangeRef = SFH_GetEmptyRange()

	return	EqualWaves(rangeRef, range, EQWAVES_DATA)
End

Function/WAVE SFH_GetFullRange()

	Make/FREE/D range = {-inf, inf}

	return range
End

/// @brief Evaluate range parameter
///
/// Range can be `[100-200]` or implicit as `cursors(A, B)` or a named epoch `E0` or a wildcard expression with epochs `E*`
Function/WAVE SFH_EvaluateRange(variable jsonId, string jsonPath, string graph, string opShort, variable argNum)

	variable numArgs

	numArgs = SFH_GetNumberOfArguments(jsonId, jsonPath)

	if(argNum < numArgs)
		WAVE range = SFH_ResolveDatasetElementFromJSON(jsonID, jsonPath, graph, opShort, argNum, checkExist=1)
	else
		return SFH_GetFullRange()
	endif

	SFH_ASSERT(DimSize(range, COLS) == 0, "Range must be a 1d wave.")

	if(IsTextWave(range))
		SFH_ASSERT(DimSize(range, ROWS) > 0, "Epoch range can not be empty.")
	else
		SFH_ASSERT(DimSize(range, ROWS) == 2, "A numerical range is of the form [rangeStart, rangeEnd].")
		// convert an empty range to a full range
		// an empty range can happen with cursors() as input when there are no cursors
		range[] = !IsNaN(range[p]) ? range[p] : (p == 0 ? -1 : 1) * inf
	endif

	return range
End

/// @brief Returns a range from a epochName
///
/// @param graph name of databrowser graph
/// @param epochName name epoch
/// @param sweep number of sweep
/// @param channel number of DA channel
/// @returns a 1D wave with two elements, [startTime, endTime] in ms, if no epoch could be resolved [NaN, NaN] is returned
Function/WAVE SFH_GetRangeFromEpoch(string graph, string epochName, variable sweep, variable channel)

	string regex
	variable numEpochs

	WAVE range = SFH_GetEmptyRange()
	if(IsEmpty(epochName) || !IsValidSweepNumber(sweep))
		return range
	endif

	WAVE/Z numericalValues = BSP_GetLogbookWave(graph, LBT_LABNOTEBOOK, LBN_NUMERICAL_VALUES, sweepNumber = sweep)
	if(!WaveExists(numericalValues))
		return range
	endif

	WAVE/Z textualValues = BSP_GetLogbookWave(graph, LBT_LABNOTEBOOK, LBN_TEXTUAL_VALUES, sweepNumber = sweep)
	if(!WaveExists(textualValues))
		return range
	endif

	regex = "^" + epochName + "$"
	WAVE/T/Z epochs = EP_GetEpochs(numericalValues, textualValues, sweep, XOP_CHANNEL_TYPE_DAC, channel, regex)
	if(!WaveExists(epochs))
		return range
	endif
	numEpochs = DimSize(epochs, ROWS)
	SFH_ASSERT(numEpochs <= 1, "Found several fitting epochs. Currently only a single epoch is supported")
	if(numEpochs == 0)
		return range
	endif

	range[0] = str2num(epochs[0][EPOCH_COL_STARTTIME]) * ONE_TO_MILLI
	range[1] = str2num(epochs[0][EPOCH_COL_ENDTIME]) * ONE_TO_MILLI

	return range
End

Function SFH_GetDAChannel(string graph, variable sweep, variable channelType, variable channelNumber)

	variable DAC, index

	WAVE/Z numericalValues = BSP_GetLogbookWave(graph, LBT_LABNOTEBOOK, LBN_NUMERICAL_VALUES, sweepNumber = sweep)
	if(!WaveExists(numericalValues))
		return NaN
	endif
	[WAVE settings, index] = GetLastSettingChannel(numericalValues, $"", sweep, "DAC", channelNumber, channelType, DATA_ACQUISITION_MODE)
	if(WaveExists(settings))
		DAC = settings[index]
		ASSERT(IsFinite(DAC) && index < NUM_HEADSTAGES, "Only associated channels are supported.")
		return DAC
	endif

	return NaN
End

/// @brief Return a wave reference wave with the requested sweep data
///
/// All wave input parameters should are treated as const and are thus *not* modified.
///
/// @param graph      name of databrowser graph
/// @param range      numeric/text wave defining the x-range of the extracted
///                   data, see also SFH_EvaluateRange()
/// @param selectData channel/sweep selection, see also SFH_GetArgumentSelect()
/// @param opShort    operation name (short)
Function/WAVE SFH_GetSweepsForFormula(string graph, WAVE range, WAVE/Z selectData, string opShort)

	variable i, j, rangeStart, rangeEnd, DAChannel, sweepNo
	variable chanNr, chanType, cIndex, isSweepBrowser
	variable numSelected, index, numEpochPatterns, numRanges, numEpochs, epIndex
	string dimLabel, device, dataFolder
	string	allEpochsRegex = "^.*$"

	ASSERT(WindowExists(graph), "graph window does not exist")

	SFH_ASSERT(DimSize(range, COLS) == 0, "Range must be a 1d wave.")
	if(IsTextWave(range))
		SFH_ASSERT(DimSize(range, ROWS) > 0, "Epoch range can not be empty.")
		WAVE/T epochNames = range
		numEpochPatterns = DimSize(epochNames, ROWS)
	else
		SFH_ASSERT(DimSize(range, ROWS) == 2, "A numerical range must have two rows for range start and end.")
		numEpochPatterns = 1
	endif
	if(!WaveExists(selectData))
		WAVE/WAVE output = SFH_CreateSFRefWave(graph, opShort, 0)
		JWN_SetStringInWaveNote(output, SF_META_DATATYPE, SF_DATATYPE_SWEEP)
		return output
	endif
	SFH_ASSERT(DimSize(selectData, COLS) == 3, "Select data must have 3 columns.")

	numSelected = DimSize(selectData, ROWS)
	WAVE/WAVE output = SFH_CreateSFRefWave(graph, opShort, numSelected)

	isSweepBrowser = BSP_IsSweepBrowser(graph)

	if(isSweepBrowser)
		DFREF sweepBrowserDFR = SB_GetSweepBrowserFolder(graph)
		WAVE/T sweepMap = GetSweepBrowserMap(sweepBrowserDFR)
	else
		SFH_ASSERT(BSP_HasBoundDevice(graph), "No device bound.")
		device = BSP_GetDevice(graph)
		DFREF deviceDFR = GetDeviceDataPath(device)
	endif

	for(i = 0; i < numSelected; i += 1)

		sweepNo = selectData[i][%SWEEP]
		chanNr = selectData[i][%CHANNELNUMBER]
		chanType = selectData[i][%CHANNELTYPE]

		if(isSweepBrowser)
			DFREF deviceDFR = SB_GetSweepDataFolder(sweepMap, sweepNo = sweepNo)

			if(!DataFolderExistsDFR(deviceDFR))
				continue
			endif
		else
			if(DB_SplitSweepsIfReq(graph, sweepNo))
				continue
			endif
		endif

		DFREF sweepDFR = GetSingleSweepFolder(deviceDFR, sweepNo)

		WAVE/Z sweep = GetDAQDataSingleColumnWave(sweepDFR, chanType, chanNr)
		if(!WaveExists(sweep))
			continue
		endif

		if(WaveExists(epochNames))
			DAChannel = SFH_GetDAChannel(graph, sweepNo, chanType, chanNr)
			WAVE/Z numericalValues = BSP_GetLogbookWave(graph, LBT_LABNOTEBOOK, LBN_NUMERICAL_VALUES, sweepNumber = sweepNo)
			WAVE/Z textualValues = BSP_GetLogbookWave(graph, LBT_LABNOTEBOOK, LBN_TEXTUAL_VALUES, sweepNumber = sweepNo)
			SFH_ASSERT(WaveExists(textualValues) && WaveExists(numericalValues), "LBN not found for sweep " + num2istr(sweepNo))
			WAVE/T/Z epochInfo = EP_GetEpochs(numericalValues, textualValues, sweepNo, XOP_CHANNEL_TYPE_DAC, DAChannel, allEpochsRegex)
			if(!WaveExists(epochInfo))
				continue
			endif
			WAVE/T allEpNames = SFH_GetEpochNamesFromInfo(epochInfo)
			WAVE/Z epIndices = SFH_GetEpochIndicesByWildcardPatterns(allEpNames, epochNames)
			if(!WaveExists(epIndices))
				continue
			endif
			numEpochs = DimSize(epIndices, ROWS)
			WAVE adaptedRange = SFH_GetEmptyRange()
			Redimension/N=(-1, numEpochs) adaptedRange
			for(j = 0; j < numEpochs; j += 1)
				epIndex = epIndices[j]
				adaptedRange[0][j] = str2num(epochInfo[epIndex][EPOCH_COL_STARTTIME]) * ONE_TO_MILLI
				adaptedRange[1][j] = str2num(epochInfo[epIndex][EPOCH_COL_ENDTIME]) * ONE_TO_MILLI
			endfor
		else
			Duplicate/FREE range, adaptedRange
			Redimension/N=(-1, 1) adaptedRange
		endif

		SFH_ASSERT(!SFH_IsEmptyRange(adaptedRange), "Specified range not valid.")

		numRanges = DimSize(adaptedRange, COLS)
		for(j = 0; j < numRanges; j += 1)
			rangeStart = adaptedRange[0][j]
			rangeEnd   = adaptedRange[1][j]

			SFH_ASSERT(rangeStart == -inf || (IsFinite(rangeStart) && rangeStart >= leftx(sweep) && rangeStart < rightx(sweep)), "Specified starting range not inside sweep " + num2istr(sweepNo) + ".")
			SFH_ASSERT(rangeEnd == inf || (IsFinite(rangeEnd) && rangeEnd >= leftx(sweep) && rangeEnd < rightx(sweep)), "Specified ending range not inside sweep " + num2istr(sweepNo) + ".")
			Duplicate/FREE/R=(rangeStart, rangeEnd) sweep, rangedSweepData

			JWN_SetWaveInWaveNote(rangedSweepData, SF_META_RANGE, {rangeStart, rangeEnd})
			JWN_SetNumberInWaveNote(rangedSweepData, SF_META_SWEEPNO, sweepNo)
			JWN_SetNumberInWaveNote(rangedSweepData, SF_META_CHANNELTYPE, chanType)
			JWN_SetNumberInWaveNote(rangedSweepData, SF_META_CHANNELNUMBER, chanNr)

			EnsureLargeEnoughWave(output, indexShouldExist=index)
			output[index] = rangedSweepData
			index += 1
		endfor
	endfor
	Redimension/N=(index) output

	JWN_SetStringInWaveNote(output, SF_META_DATATYPE, SF_DATATYPE_SWEEP)

	return output
End

// returns number of operation arguments
Function SFH_GetNumberOfArguments(variable jsonId, string jsonPath)

	variable size

	size = JSON_GetArraySize(jsonID, jsonPath)
	if(!size)
		return size
	endif

	return JSON_GetType(jsonId, jsonPath + "/0") == JSON_NULL ? 0 : size
End

Function/DF SFH_GetWorkingDF(string win)

	return createDFWithAllParents(GetDataFolder(1, SF_GetBrowserDF(win)) + SFH_WORKING_DF)
End

Function/WAVE SFH_CreateSFRefWave(string win, string opShort, variable size)

	string wName

	DFREF dfrWork = SFH_GetWorkingDF(win)
	wName = UniqueWaveName(dfrWork, opShort + "_output_")

	Make/WAVE/N=(size) dfrWork:$wName/WAVE=wv

	return wv
End

Function SFH_CleanUpInput(WAVE input)

#ifndef SWEEPFORMULA_DEBUG
	if(JWN_GetNumberFromWaveNote(input, SF_VARIABLE_MARKER) == 1)
		return NaN
	endif
	KillOrMoveToTrash(wv = input)
#endif
End

Function SFH_AddOpToOpStack(WAVE w, string oldStack, string opShort)

	JWN_SetStringInWaveNote(w, SF_META_OPSTACK, AddListItem(opShort, oldStack))
End

Function SFH_AddToArgSetupStack(WAVE output, WAVE/Z input, string argSetupStr, [variable resetStack])

	string argSetupStack
	variable argStackId, stackCnt

	resetStack = ParamIsDefault(resetStack) ? 0 : !!resetStack
	if(!resetStack)
		ASSERT(WaveExists(input), "Need input wave")
		argSetupStack = JWN_GetStringFromWaveNote(input, SF_META_ARGSETUPSTACK)
		if(IsEmpty(argSetupStack))
			argStackId = JSON_New()
		else
			argStackId = JSON_Parse(argSetupStack)
		endif
	else
		argStackId = JSON_New()
	endif

	WAVE/Z/T wStack = JSON_GetKeys(argStackId, "", ignoreErr=1)
	if(waveExists(wStack))
		stackCnt = DimSize(wStack, ROWS)
	endif
	JSON_AddString(argStackId, "/" + num2istr(stackCnt), argSetupStr)
	JWN_SetStringInWaveNote(output, SF_META_ARGSETUPSTACK, JSON_Dump(argStackId))
	JSON_Release(argStackId)
End

Function/WAVE SFH_GetOutputForExecutorSingle(WAVE/Z data, string graph, string opShort[, variable discardOpStack, WAVE clear, string dataType])

	discardOpStack = ParamIsDefault(discardOpStack) ? 0 : !!discardOpStack
	if(!ParamIsDefault(clear))
		SFH_CleanUpInput(clear)
	endif

	WAVE/WAVE output = SFH_CreateSFRefWave(graph, opShort, 1)
	if(!ParamIsDefault(dataType))
		JWN_SetStringInWaveNote(output, SF_META_DATATYPE, dataType)
	endif
	if(WaveExists(data))
		output[0] = data
	endif

	if(discardOpStack)
		SFH_AddOpToOpStack(output, "", opShort)
		SFH_ResetArgSetupStack(output, opShort)
	endif

	return SFH_GetOutputForExecutor(output, graph, opShort)
End

Function/WAVE SFH_GetOutputForExecutor(WAVE output, string win, string opShort[, WAVE clear])

	if(!ParamIsDefault(clear))
		SFH_CleanUpInput(clear)
	endif
	Make/FREE/T wRefPath = {SF_WREF_MARKER + GetWavesDataFolder(output, 2)}

#ifdef SWEEPFORMULA_DEBUG
	SFH_ConvertAllReturnDataToPermanent(output, win, opShort)
#endif

	return wRefPath
End

static Function SFH_ConvertAllReturnDataToPermanent(WAVE/WAVE output, string win, string opShort)

	string wName
	variable i

	for(data : output)
		if(WaveExists(data) && IsFreeWave(data))
			DFREF dfrWork = SFH_GetWorkingDF(win)
			wName = UniqueWaveName(dfrWork, opShort + "_return_arg" + num2istr(i) + "_")
			MoveWave data, dfrWork:$wName
		endif
		i += 1
	endfor
End

/// @brief Retrieves from an argument the first dataset and disposes the argument
Function/WAVE SFH_ResolveDatasetElementFromJSON(variable jsonId, string jsonPath, string graph, string opShort, variable argNum[, variable checkExist])

	checkExist = ParamIsDefault(checkExist) ? 0 : !!checkExist

	WAVE/WAVE input = SF_ResolveDatasetFromJSON(jsonId, jsonPath, graph, argNum)
	SFH_ASSERT(DimSize(input, ROWS) == 1, "Expected only a single dataSet")
	WAVE/Z data = input[0]
	SFH_ASSERT(!(checkExist && !WaveExists(data)), "No data in dataSet at operation " + opShort + " arg num " + num2istr(argNum))
	SFH_CleanUpInput(input)

	return data
End

/// @brief Transfer wavenote from input data sets to output data sets
///        set a label for a x-axis and x-value(s) for data waves
///
/// @param input Input wave reference wave
/// @param output Output wave reference wave
/// @param opShort operation short name
/// @param newDataType data type of output
/// @param argSetup [optional, default=$""] 2d text wave with argument setup of operation @sa SFH_GetNewArgSetupWave
/// @param keepX [optional, default=0] When set then xvalues and xlabel of output are kept.
Function SFH_TransferFormulaDataWaveNoteAndMeta(WAVE/WAVE input, WAVE/WAVE output, string opShort, string newDataType[, WAVE/T argSetup, variable keepX])

	variable sweepNo, numResults, i, setXLabel, size
	string opStack, argSetupStr, inDataType
	string xLabel = ""

	numResults = DimSize(input, ROWS)
	ASSERT(numResults == DimSize(output, ROWS), "Input and output must have the same size.")
	keepX = ParamIsDefault(keepX) ? 0 : !!keepX
	if(ParamIsDefault(argSetup))
		WAVE/T argSetup = SFH_GetNewArgSetupWave(1)
		argSetup[0][%KEY] = SFH_ARGSETUP_OPERATION_KEY
		argSetup[0][%VALUE] = opShort
	else
		size = DimSize(argSetup, ROWS)
		Redimension/N=(size + 1, -1) argSetup
		argSetup[size][%KEY] = SFH_ARGSETUP_OPERATION_KEY
		argSetup[size][%VALUE] = opShort
	endif
	argSetupStr = SFH_SerializeArgSetup(argSetup)

	if(keepX)
		xLabel = JWN_GetStringFromWaveNote(output, SF_META_XAXISLABEL)
	endif

	JWN_SetStringInWaveNote(output, SF_META_DATATYPE, newDataType)

	opStack = JWN_GetStringFromWaveNote(input, SF_META_OPSTACK)
	SFH_AddOpToOpStack(output, opStack, opShort)
	SFH_AddToArgSetupStack(output, input, argSetupStr)

	inDataType = JWN_GetStringFromWaveNote(input, SF_META_DATATYPE)

	setXLabel = 1
	for(i = 0; i < numResults; i += 1)
		WAVE/Z inData = input[i]
		WAVE/Z outData = output[i]
		if(!WaveExists(inData) || !WaveExists(outData))
			continue
		endif
		if(keepX)
			WAVE/Z xValues = JWN_GetNumericWaveFromWaveNote(outData, SF_META_XVALUES)
		endif

		Note/K outData, note(inData)

		if(keepX && WaveExists(xValues))
			JWN_SetWaveInWaveNote(outData, SF_META_XVALUES, xValues)
			continue
		endif

		strswitch(inDataType)
			case SF_DATATYPE_SWEEP:
				if(numpnts(outData) == 1 && IsEmpty(WaveUnits(outData, ROWS)))
					sweepNo = JWN_GetNumberFromWaveNote(outData, SF_META_SWEEPNO)
					JWN_SetWaveInWaveNote(outData, SF_META_XVALUES, {sweepNo})
				else
					setXLabel = 0
				endif
				break
			default:
				sweepNo = JWN_GetNumberFromWaveNote(outData, SF_META_SWEEPNO)
				if(numpnts(outData) == 1 && IsEmpty(WaveUnits(outData, ROWS)) && !IsNaN(sweepNo))
					JWN_SetWaveInWaveNote(outData, SF_META_XVALUES, {sweepNo})
				else
					setXLabel = 0
				endif
				break
		endswitch

	endfor

	if(!keepX && setXLabel)
		strswitch(inDataType)
			case SF_DATATYPE_SWEEP:
				xLabel = "Sweeps"
				break
			default:
				xLabel = "Sweeps"
				break
		endswitch
	endif

	JWN_SetStringInWaveNote(output, SF_META_XAXISLABEL, xLabel)
End

Function/WAVE SFH_GetArgumentSelect(variable jsonId, string jsonPath, string graph, string opShort, variable argNum)

	string msg

	WAVE/Z selectData = SFH_GetArgumentAsWave(jsonId, jsonPath, graph, opShort, argNum, defOp = "select()", singleResult = 1)

	if(WaveExists(selectData))
		sprintf msg, "Argument #%d of operation %s: input must have three columns", argNum, opShort
		SFH_ASSERT(DimSize(selectData, COLS) == 3, msg)

		sprintf msg, "Argument #%d of operation %s: Must be numeric ", argNum, opShort
		SFH_ASSERT(IsNumericWave(selectData), msg)
	endif

	return selectData
End

Function/WAVE SFH_GetEpochNamesFromInfo(WAVE/T epochInfo)

	string epName, epShortName
	variable i
	variable numEpochs = DimSize(epochInfo, ROWS)

	Make/FREE/T/N=(numEpochs) epNames
	for(i = 0; i < numEpochs; i += 1)
		epName = epochInfo[i][EPOCH_COL_TAGS]
		epShortName = EP_GetShortName(epName)
		epNames[i] = SelectString(IsEmpty(epShortName), epShortName, epName)
	endfor

	return epNames
End

Function/WAVE SFH_GetEpochIndicesByWildcardPatterns(WAVE/T epochNames, WAVE/T patterns)

	variable i
	variable numPatterns = DimSize(patterns, ROWS)

	for(i = 0; i < numPatterns; i += 1)
		WAVE/Z indices = FindIndizes(epochNames, str=patterns[i], prop=PROP_WILDCARD)
		if(!WaveExists(indices))
			continue
		endif
		Concatenate/FREE/NP {indices}, allIndices
	endfor
	if(!WaveExists(allIndices))
		return $""
	endif
	WAVE uniqueEntries = GetUniqueEntries(allIndices, dontDuplicate=1)

	return uniqueEntries
End

Function/S SFH_ResultTypeToString(variable resultType)

	switch(resultType)
		case SFH_RESULT_TYPE_STORE:
			return "store"
		case SFH_RESULT_TYPE_EPSP:
			return "epsp"
		default:
			ASSERT(0, "Invalid resultType")
	endswitch
End

Function/S SFH_FormatResultsKey(variable resultType, string name)

	return "Sweep Formula " + SFH_ResultTypeToString(resultType) + " [" + name + "]"
End

Function [WAVE/T keys, WAVE/T values] SFH_CreateResultsWaveWithCode(string graph, string code, [WAVE data, string name, variable resultType])

	variable numEntries, numOptParams, hasStoreEntry, numCursors, numBasicEntries
	string shPanel, dataFolder, device, str

	numOptParams = ParamIsDefault(data) + ParamIsDefault(name)
	ASSERT(numOptParams == 0 || numOptParams == 2, "Invalid optional parameters data and name")
	hasStoreEntry = (numOptParams == 0)

	ASSERT(!IsEmpty(code), "Unexpected empty code")
	numCursors = ItemsInList(CURSOR_NAMES)
	numBasicEntries = 4
	numEntries = numBasicEntries + numCursors + hasStoreEntry

	Make/T/FREE/N=(1, numEntries) keys
	Make/T/FREE/N=(1, numEntries, LABNOTEBOOK_LAYER_COUNT) values

	keys[0][0]                                                 = "Sweep Formula code"
	keys[0][1]                                                 = "Sweep Formula sweeps/channels"
	keys[0][2]                                                 = "Sweep Formula experiment"
	keys[0][3]                                                 = "Sweep Formula device"
	keys[0][numBasicEntries, numBasicEntries + numCursors - 1] = "Sweep Formula cursor " + StringFromList(q - numBasicEntries, CURSOR_NAMES)

	if(hasStoreEntry)
		ASSERT(IsWaveRefWave(data), "Expected a wave reference wave")
		SFH_ASSERT(!ParamIsDefault(resultType), "Missing type")
		SFH_ASSERT(IsValidLiberalObjectName(name[0]), "Can not use the given name for the labnotebook key")
		keys[0][numEntries - 1] = SFH_FormatResultsKey(resultType, name)
	endif

	LBN_SetDimensionLabels(keys, values)

	values[0][%$"Sweep Formula code"][INDEP_HEADSTAGE] = NormalizeToEOL(TrimString(code), "\n")

	WAVE/T/Z cursorInfos = GetCursorInfos(graph)

	WAVE/Z selectData = SF_ExecuteFormula("select()", graph, singleResult=1, useVariables=0)
	if(WaveExists(selectData))
		values[0][%$"Sweep Formula sweeps/channels"][INDEP_HEADSTAGE] = NumericWaveToList(selectData, ";")
	endif

	shPanel = LBV_GetSettingsHistoryPanel(graph)

	dataFolder = GetPopupMenuString(shPanel, "popup_experiment")
	values[0][%$"Sweep Formula experiment"][INDEP_HEADSTAGE] = dataFolder

	device = GetPopupMenuString(shPanel, "popup_Device")
	values[0][%$"Sweep Formula device"][INDEP_HEADSTAGE] = device

	if(WaveExists(cursorInfos))
		values[0][numBasicEntries, numBasicEntries + numCursors - 1][INDEP_HEADSTAGE] = cursorInfos[q - numBasicEntries]
	endif

	if(hasStoreEntry)
		// since bdee94c6 (Merge pull request #1713 from AllenInstitute/bugfix/1713-correct-referenced-commits-in-code, 2023-05-18)
		// we always store in JSON format, before we used the format defined by TextWaveToList() for the store operation.
		values[0][numEntries - 1][INDEP_HEADSTAGE] = WaveToJSON(data)
	endif

	return [keys, values]
End

/// @brief Return the SweepBrowser/DataBrowser from which the given
///        SweepFormula plot window originated from
Function/S SFH_GetBrowserForFormulaGraph(string win)

	return GetUserData(GetMainWindow(win), "", SFH_USER_DATA_BROWSER)
End

/// @brief Return the SweepFormula plot created by the given
///        SweepBrowser/DataBrowser
Function/S SFH_GetFormulaGraphForBrowser(string browser)

	string entry

	WAVE/T matches = ListToTextWave(WinList(CleanupName(SF_PLOT_NAME_TEMPLATE, 0) + "*", ";", "WIN:64"), ";") // only panels

	for(entry : matches)
		if(!cmpstr(SFH_GetBrowserForFormulaGraph(entry), browser))
			return entry
		endif
	endfor

	return ""
End

/// @brief Create a new selectData wave
///        The row counts the selected combinations of sweep, channel type, channel number
///        The three columns per row store the sweep number, channel type, channel number
Function/WAVE SFH_NewSelectDataWave(variable numSweeps, variable numChannels)

	ASSERT(numSweeps >= 0 && numChannels >= 0, "Invalid wave size specified")

	Make/FREE/D/N=(numSweeps * numChannels, 3) selectData
	SetDimLabel COLS, 0, SWEEP, selectData
	SetDimLabel COLS, 1, CHANNELTYPE, selectData
	SetDimLabel COLS, 2, CHANNELNUMBER, selectData

	return selectData
End

/// @brief Recreate a **single** select data wave and range stored in the JSON wavenote from SFH_GetSweepsForFormula()
Function [WAVE selectData, WAVE range] SFH_ParseToSelectDataWaveAndRange(WAVE sweepData)

	WAVE range = JWN_GetNumericWaveFromWaveNote(sweepData, SF_META_RANGE)

	WAVE selectData = SFH_NewSelectDataWave(1, 1)

	selectData[0][%SWEEP]         = JWN_GetNumberFromWaveNote(sweepData, SF_META_SWEEPNO)
	selectData[0][%CHANNELTYPE]   = JWN_GetNumberFromWaveNote(sweepData, SF_META_CHANNELTYPE)
	selectData[0][%CHANNELNUMBER] = JWN_GetNumberFromWaveNote(sweepData, SF_META_CHANNELNUMBER)

	return [selectData, range]
End

Function/WAVE SFH_GetNewArgSetupWave(variable size)

	ASSERT(size >= 0, "Invalid size")
	Make/FREE/T/N=(size, 2) wv
	SetDimLabel COLS, 0, KEY, wv
	SetDimLabel COLS, 1, VALUE, wv

	return wv
End

static Function/S SFH_SerializeArgSetup(WAVE/T argSetup)

	variable i, jsonId, size
	string argSetupStr, key

	size = DimSize(argSetup, ROWS)
	ASSERT(size > 0, "Encountered empty argSetup")

	jsonId = JSON_New()
	for(i = 0; i < size; i += 1)
		key = argSetup[i][%KEY]
		ASSERT(!IsEmpty(key), "ArgumentSetup key is empty.")
		JSON_AddString(jsonId, "/" + key, argSetup[i][%VALUE])
	endfor

	argSetupStr = JSON_Dump(jsonId)
	JSON_Release(jsonId)

	return argSetupStr
End

Function/WAVE SFH_DeSerializeArgSetup(variable jsonId, string jsonPath)

	variable size, jsonIdOp
	string argSetupStr

	argSetupStr = JSON_GetString(jsonId, jsonPath)
	jsonIdOp = JSON_Parse(argSetupStr)

	WAVE/Z/T keys = JSON_GetKeys(jsonIdOp, "")
	if(!WaveExists(keys))
		WAVE/T argSetup = SFH_GetNewArgSetupWave(0)
		return argSetup
	endif

	size = DimSize(keys, ROWS)
	WAVE/T argSetup = SFH_GetNewArgSetupWave(size)
	argSetup[][%KEY] = keys[p]
	argSetup[][%VALUE] = JSON_GetString(jsonIdOp, "/" + keys[p])

	JSON_Release(jsonIdOp)

	return argSetup
End

Function SFH_ResetArgSetupStack(WAVE output, string opShort)

	string argSetupStr

	WAVE/T argSetup = SFH_GetNewArgSetupWave(1)
	argSetup[0][%KEY] = SFH_ARGSETUP_OPERATION_KEY
	argSetup[0][%VALUE] = opShort
	argSetupStr = SFH_SerializeArgSetup(argSetup)
	SFH_AddToArgSetupStack(output, $"", argSetupStr, resetStack=1)
End

static Function/S SFH_GetArgSetupValueByKey(WAVE/T argSetup, string key)

	variable dim

	dim = FindDimLabel(argSetup, COLS, "KEY")
	FindValue/RMD=[][dim]/TEXT=key/TXOP=4 argSetup
	if(!(V_Value >= 0))
		return ""
	endif

	return argSetup[V_row][%VALUE]
End

static Function/S SFH_GetEmptyArgSetup()

	variable jsonId, jsonId1
	string dump

	jsonId = JSON_New()
	jsonId1 = JSON_New()
	JSON_AddString(jsonId1, "/" + SFH_ARGSETUP_OPERATION_KEY, SFH_ARGSETUP_EMPTY_OPERATION_VALUE)
	JSON_AddString(jsonId, "/0", JSON_Dump(jsonId1))
	dump = JSON_Dump(jsonId)
	JSON_Release(jsonId1)
	JSON_Release(jsonId)

	return dump
End

/// @brief Based on the argument setup modifies the annotations per formula with additional information from
///        the different arguments.
///
/// @returns 1 of difference was found, 0 otherwise
Function SFH_EnrichAnnotations(WAVE/T annotations, WAVE/T formulaArgSetup)

	variable i, j, k, numFormulas, numOps, numKeys, dim, isDifferent
	string testKey, testValue, buildDiffArgsStr, newAnnotation

	numFormulas = DimSize(formulaArgSetup, ROWS)

	Make/FREE/N=(numFormulas) stackSize, formulaIds
	for(i = 0; i < numFormulas; i += 1)
		if(IsEmpty(formulaArgSetup[i]))
			formulaArgSetup[i] = SFH_GetEmptyArgSetup()
		endif
		formulaIds[i] = JSON_Parse(formulaArgSetup[i])
		WAVE/Z/T wStack = JSON_GetKeys(formulaIds[i], "")
		ASSERT(WaveExists(wStack), "Encountered invalid argSetup")
		stackSize[i] = DimSize(wStack, ROWS)
	endfor
	WAVE uniques = GetUniqueEntries(stackSize)
	if(DimSize(uniques, ROWS) > 1)
		// stacksize different -> all different
		SFH_EnrichAnnotationsRelease(formulaIds)
		return 1
	else
		numOps = stackSize[0]
		Make/FREE/WAVE/N=(numFormulas, numOps) argSetup
		argSetup[][] = SFH_DeSerializeArgSetup(formulaIds[p], "/" + num2istr(q))

		Make/FREE/T/N=(numFormulas, numOps) opIds
		opIds[][] = SFH_GetArgSetupValueByKey(argSetup[p][q], SFH_ARGSETUP_OPERATION_KEY)
		for(i = 0; i < numOps; i += 1)
			Duplicate/FREE/RMD=[][i] opIds, opRow
			Redimension/N=(-1) opRow
			WAVE opRowUniques = GetUniqueEntries(opRow)
			if(DimSize(opRowUniques, ROWS) > 1)
				// At least one operation is different
				SFH_EnrichAnnotationsRelease(formulaIds)
				return 1
			endif
		endfor

		Make/FREE/T/N=(numFormulas, numOps) shrinkedDiff
		Make/FREE/T/N=(numFormulas) opStackStr
		for(i = 0; i < numOps; i += 1)
			Make/FREE/T/N=0 allKeys
			for(j = 0; j < numFormulas; j += 1)
				WAVE/T argOpSetup = argSetup[j][i]
				dim = FindDimLabel(argOpSetup, COLS, "KEY")
				Duplicate/FREE/RMD=[][dim] argOpSetup, argOpSetupKeys
				Redimension/N=(-1) argOpSetupKeys
				Concatenate/NP/T {argOpSetupKeys}, allKeys
			endfor
			WAVE/T uniqueKeys = GetUniqueEntries(allKeys)
			numKeys = DimSize(uniqueKeys, ROWS)
			Make/FREE/N=(numKeys) markDiff
			if(numKeys > 1)
				for(j = 0; j < numKeys; j += 1)
					testKey = uniqueKeys[j]
					testValue = ""
					for(k = 0; k < numFormulas; k += 1)
						WAVE/T argOpSetup = argSetup[k][i]
						if(IsEmpty(testValue))
							testValue = SFH_GetArgSetupValueByKey(argOpSetup, testKey)
							continue
						endif
						if(CmpStr(testValue, SFH_GetArgSetupValueByKey(argOpSetup, testKey), 1))
							markDiff[j] = 1
						endif
					endfor
				endfor
			endif
			// build nice string per formula
			shrinkedDiff[][i] = SFH_GetArgSetupValueByKey(WaveRef(argSetup, row = p, col = i), SFH_ARGSETUP_OPERATION_KEY)
			opStackStr[] = shrinkedDiff[p][i] + " " + opStackStr[p]
			for(j = 0; j < numFormulas; j += 1)
				WAVE/T argOpSetup = argSetup[j][i]

				if(sum(markDiff) == 0)
					continue
				endif

				isDifferent = 1

				buildDiffArgsStr = ""
				for(k = 0; k < numKeys; k += 1)
					if(!markDiff[k])
						continue
					endif
					buildDiffArgsStr += uniqueKeys[k] + ":" + SFH_GetArgSetupValueByKey(argOpSetup, uniqueKeys[k]) + " "
				endfor
				buildDiffArgsStr = RemoveEnding(buildDiffArgsStr, " ")
				shrinkedDiff[j][i] += "(" + buildDiffArgsStr + ")"
			endfor
		endfor

		opStackStr[] = RemoveEnding(opStackStr[p], " ")
		for(i = 0; i < numFormulas; i += 1)
			newAnnotation = ""
			for(j = 0; j < numOps; j += 1)
				newAnnotation = shrinkedDiff[i][j] + " " + newAnnotation
			endfor
			newAnnotation = RemoveEnding(newAnnotation, " ")
			annotations[i] = ReplaceString(opStackStr[i], annotations[i], newAnnotation)
		endfor

	endif

	SFH_EnrichAnnotationsRelease(formulaIds)

	return isDifferent
End

static Function SFH_EnrichAnnotationsRelease(WAVE formulaIDs)

	for(ids : formulaIds)
		JSON_Release(ids)
	endfor
End

Function SFH_GetPlotMarkerCodeSelection(variable count)

	Make/FREE wv = {19, 5, 16, 8, 17, 7, 18, 6}

	return wv[mod(count, DimSize(wv, ROWS))]
End

Function SFH_GetPlotLineCodeSelection(variable count)

	Make/FREE wv = {0, 3, 7, 2, 1, 8}

	return wv[mod(count, DimSize(wv, ROWS))]
End

/// @brief filters data from select, currently supports only one option:
///        - specify a channel type to keep
Function/WAVE SFH_FilterSelect(WAVE/Z selectData, variable keepChanType)

	variable i, numSelected, idx

	if(!WaveExists(selectData))
		return $""
	endif

	Duplicate/FREE selectData, selectDataFiltered

	numSelected = DimSize(selectData, ROWS)
	for(i = 0; i < numSelected; i += 1)
		if(selectData[i][%CHANNELTYPE] == keepChanType)
			selectDataFiltered[idx][] = selectData[i][q]
			idx += 1
		endif
	endfor
	if(!idx)
		return $""
	endif
	Redimension/N=(idx, -1) selectDataFiltered

	return selectDataFiltered
End

/// @brief checks the argument count and returns the number of arguments
Function SFH_CheckArgumentCount(variable jsonId, string jsonPath, string opShort, variable minArgs, [variable maxArgs])

	variable numArgs
	string errMsg

	maxArgs = ParamIsDefault(maxArgs) ? Inf : maxArgs
	numArgs = SFH_GetNumberOfArguments(jsonID, jsonPath)
	sprintf errMsg, "%s has %d arguments at most.", opShort, maxArgs
	SFH_ASSERT(numArgs <= maxArgs, errMsg)
	sprintf errMsg, "%s needs at least %d argument(s).", opShort, minArgs
	SFH_ASSERT(numArgs >= minArgs, errMsg)

	return numArgs
End
