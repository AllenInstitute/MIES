#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_SFH_HELPERS
#endif // AUTOMATED_TESTING

/// @file MIES_SweepFormula_Helpers.ipf
///
/// @brief __SFH__ Sweep formula related helper code

static StrConstant SFH_WORKING_DF                     = "FormulaData"
static StrConstant SFH_ARGSETUP_OPERATION_KEY         = "Operation"
static StrConstant SFH_ARGSETUP_EMPTY_OPERATION_VALUE = "NOOP"
static StrConstant SFH_DEFAULT_SELECT_FORMULA         = "select()"

threadsafe Function SFH_StringChecker_Prototype(string str)

	ASSERT_TS(0, "Can't call prototype function")
End

threadsafe Function SFH_NumericChecker_Prototype(variable var)

	ASSERT_TS(0, "Can't call prototype function")
End

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
Function SFH_GetArgumentAsNumeric(variable jsonId, string jsonPath, string graph, string opShort, variable argNum, [variable defValue, WAVE/Z allowedValues, FUNCREF SFH_NumericChecker_Prototype checkFunc, variable checkDefault])

	string msg, sep, allowedValuesAsStr
	variable checkExist, numArgs, result, idx, ret

	if(ParamIsDefault(checkDefault))
		checkDefault = 1
	else
		checkDefault = !!checkDefault
	endif

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

		if(!checkDefault)
			return result
		endif
	endif

	if(!ParamIsDefault(allowedValues))
		ASSERT(WaveExists(allowedValues) && IsNumericWave(allowedValues), "allowedValues must be a numeric wave")

		idx = GetRowIndex(allowedValues, val = result)
		if(IsNaN(idx))
			sep                = ", "
			allowedValuesAsStr = NumericWaveToList(allowedValues, sep, trailSep = 0)
			sprintf msg, "Argument #%d of operation %s: The numeric argument \"%g\" is not one of the allowed values (%s)", argNum, opShort, result, allowedValuesAsStr
			SFH_ASSERT(0, msg)
		endif
	endif

	if(!ParamIsDefault(checkFunc))
		ret = !!checkFunc(result)

		if(!ret)
			sprintf msg, "Argument #%d of operation %s: The numeric argument \"%g\" does not meet the requirements of \"%s\"", argNum, opShort, result, StringByKey("NAME", FuncRefInfo(checkFunc))
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
Function/S SFH_GetArgumentAsText(variable jsonId, string jsonPath, string graph, string opShort, variable argNum, [string defValue, WAVE/Z/T allowedValues, FUNCREF SFH_StringChecker_Prototype checkFunc, variable checkDefault])

	string msg, result, sep, allowedValuesAsStr
	variable checkExist, numArgs, idx, ret, matchIndex

	if(ParamIsDefault(checkDefault))
		checkDefault = 1
	else
		checkDefault = !!checkDefault
	endif

	if(ParamIsDefault(defValue))
		checkExist = 1
	else
		checkExist = 0
	endif

	numArgs = SFH_GetNumberOfArguments(jsonId, jsonPath)

	if(argNum < numArgs)
		WAVE/Z/WAVE input = SF_ResolveDatasetFromJSON(jsonId, jsonPath, graph, argNum)
		sprintf msg, "Argument #%d of operation %s: input is a NULL wave reference", argNum, opShort
		SFH_ASSERT(WaveExists(input), msg)

		sprintf msg, "Argument #%d of operation %s: Expected only one dataset", argNum, opShort
		SFH_ASSERT(DimSize(input, ROWS) == 1, msg)

		WAVE/Z/T data = input[0]
		SFH_CleanUpInput(input)
		sprintf msg, "Argument #%d of operation %s: Is a NULL wave reference", argNum, opShort
		SFH_ASSERT(WaveExists(data), msg)

		sprintf msg, "Argument #%d of operation %s: Must be text", argNum, opShort
		SFH_ASSERT(IsTextWave(data), msg)

		sprintf msg, "Argument #%d of operation %s: Too many input values", argNum, opShort
		SFH_ASSERT(DimSize(data, ROWS) == 1 && DimSize(data, COLS) == 0, msg)

		result = data[0]
	else
		sprintf msg, "Argument #%d of operation %s is mandatory", argNum, opShort
		SFH_ASSERT(!checkExist, msg)

		result = defValue

		if(!checkDefault)
			return result
		endif
	endif

	if(!ParamIsDefault(allowedValues))
		ASSERT(WaveExists(allowedValues) && IsTextWave(allowedValues), "allowedValues must be a text wave")

		// result can be either an exact match or a unique abbreviation
		// need to check the exact match first as otherwise we find two
		// abbreviations when given `a` with allowedValues `a`, `aXXX`

		matchIndex = GetRowIndex(allowedValues, str = result)

		if(IsNaN(matchIndex))
			// no exact match, search allowed entries and try to match a unique abbreviation
			WAVE/Z/T matches = GrepTextWave(allowedValues, "(?i)^\\Q" + result + "\\E.*$")
			if(!WaveExists(matches))
				sep                = ", "
				allowedValuesAsStr = TextWaveToList(allowedValues, sep, trailSep = 0)
				sprintf msg, "Argument #%d of operation %s: The text argument \"%s\" is not one of the allowed values (%s)", argNum, opShort, result, allowedValuesAsStr
				SFH_ASSERT(0, msg)
			elseif(DimSize(matches, ROWS) > 1)
				sep                = ", "
				allowedValuesAsStr = TextWaveToList(matches, sep, trailSep = 0)
				sprintf msg, "Argument #%d of operation %s: The abbreviated text argument \"%s\" is not unique and could be (%s)", argNum, opShort, result, allowedValuesAsStr
				SFH_ASSERT(0, msg)
			else
				ASSERT(DimSize(matches, ROWS) == 1, "Unexpected match")
				// replace possibly abbreviated argument with its full name
				result = matches[0]
			endif
		endif
	endif

	if(!ParamIsDefault(checkFunc))
		ret = !!checkFunc(result)

		if(!ret)
			sprintf msg, "Argument #%d of operation %s: The text argument \"%s\" does not meet the requirements of \"%s\"", argNum, opShort, result, StringByKey("NAME", FuncRefInfo(checkFunc))
			SFH_ASSERT(0, msg)
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
///    WAVE/T types = SFH_GetArgumentAsWave(jsonId, jsonPath, graph, opShort, 1, defOp = "birdTypes()", singleResult = 1, expectedWaveType = IGOR_TYPE_TEXT_WAVE)
///
/// \endrst
///
/// Here `birds` is argument number 0 and mandatory as `defOp` is not present. Passing `singleResult == 1` already
/// unpacks the outer wave reference wave container. It should always be passed if you only expect one wave to be
/// returned.
///
/// The second argument `birdTypes` is optional, if not present the operation `birdTypes()` is called and its result returned. Alternatively `defWave` can be supplied which is then returned if the argument is not present.
///
/// @param jsonId            JSON identifier
/// @param jsonPath          Location in the AST
/// @param graph             Databrowser graph
/// @param opShort           Short name of the operation
/// @param argNum            Argument index
/// @param defOp             [optional, defaults to None] SF code to execute in case the argument is not present
/// @param defWave           [optional] wave to return in case the argument is not present and defOp is not supplied
/// @param singleResult      [optional, defaults to 0] Return the first wave of the dataset if it has only one entry
/// @param expectedMinorType [optional, defaults to None] Expected minor wave type, possible values are from WaveType(wv, 0)
/// @param expectedMajorType [optional, defaults to None] Expected major wave type, possible values are from WaveType(wv, 1)
/// @param copy              [optional, defaults to 0] If the returned data should be safe for modification (true) or is only read (false)
/// @param[out] wvNote       [optional, defaults to None] Wave note of the dataset, useful for single result cases where you still need
///                          to query JSON wave note entries
Function/WAVE SFH_GetArgumentAsWave(variable jsonId, string jsonPath, string graph, string opShort, variable argNum, [string defOp, WAVE/Z defWave, variable singleResult, variable expectedMinorType, variable expectedMajorType, variable copy, string &wvNote])

	variable checkExist, numArgs, checkMinorType, checkMajorType
	string msg

	if(!ParamIsDefault(wvNote))
		ASSERT(ParamIsDefault(defOp) && ParamIsDefault(defWave),                        \
		       "The optional parameters wvNote and defOp/defWave can't be used together")
	endif

	if(ParamIsDefault(defOp) && ParamIsDefault(defWave))
		checkExist = 1
	else
		ASSERT((ParamIsDefault(defOp) + ParamIsDefault(defWave)) == 1, "Can only supply one of defOp and defWave")
		checkExist = 0
	endif

	checkMinorType = !ParamIsDefault(expectedMinorType)
	checkMajorType = !ParamIsDefault(expectedMajorType)

	if(ParamIsDefault(singleResult))
		singleResult = 0
	else
		singleResult = !!singleResult
	endif
	copy = ParamIsDefault(copy) ? 0 : !!copy

	numArgs = SFH_GetNumberOfArguments(jsonId, jsonPath)

	if(argNum < numArgs)
		WAVE/WAVE input = SF_ResolveDatasetFromJSON(jsonId, jsonPath, graph, argNum)

		if(singleResult)
			sprintf msg, "Argument #%d of operation %s: Too many input values", argNum, opShort
			SFH_ASSERT(DimSize(input, ROWS) == 1, msg)

			if(!ParamIsDefault(wvNote))
				wvNote = note(input)
			endif

			WAVE/Z data = input[0]
			SFH_CleanUpInput(input)
		else
			WAVE data = input
		endif

		if(checkMinorType)
			if(singleResult)
				Make/FREE types = {WaveType(data)}
			else
				WAVE/WAVE dataAsRef = data
				Make/FREE/N=(DimSize(data, ROWS)) types = WaveType(dataAsRef[p])
			endif
			sprintf msg, "Argument #%d of operation %s: Expected minor wave type %d", argNum, opShort, expectedMinorType
			if(expectedMinorType > 0)
				types[] = !!(types[p] & expectedMinorType)
				SFH_ASSERT(sum(types) == DimSize(types, ROWS), msg)
			else
				SFH_ASSERT(IsConstant(types, expectedMinorType), msg)
			endif
		endif
		if(checkMajorType)
			if(singleResult)
				Make/FREE types = {WaveType(data, 1)}
			else
				WAVE/WAVE dataAsRef = data
				Make/FREE/N=(DimSize(data, ROWS)) types = WaveType(dataAsRef[p], 1)
			endif

			sprintf msg, "Argument #%d of operation %s: Expected major wave type %d", argNum, opShort, expectedMajorType
			SFH_ASSERT(IsConstant(types, expectedMajorType), msg)
		endif

		return SFH_CopyDataIfRequired(copy, input, data)
	endif

	sprintf msg, "Argument #%d of operation %s is mandatory", argNum, opShort
	SFH_ASSERT(!checkExist, msg)

	if(!ParamIsDefault(defOp))
		return SF_ExecuteFormula(defOp, graph, singleResult = singleResult, useVariables = 0)
	endif

	return defWave
End

/// @brief Assertion for sweep formula
///
/// This assertion does *not* indicate a general programmer error but a
/// sweep formula user error.
///
/// All programmer error checks must still use ASSERT().
///
/// UTF_NOINSTRUMENTATION
Function SFH_ASSERT(variable condition, string message, [variable jsonId])

	if(!condition)
		if(!ParamIsDefault(jsonId))
			JSON_Release(jsonId, ignoreErr = 1)
		endif
		SVAR error = $GetSweepFormulaParseErrorMessage()
		error = message

#ifdef AUTOMATED_TESTING_DEBUGGING

#ifdef AUTOMATED_TESTING
#if exists("INFO")
		INFO("SFH_ASSERT: %s", s0 = error)
#endif
#endif // AUTOMATED_TESTING
		Debugger
#endif // AUTOMATED_TESTING_DEBUGGING
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

	return EqualWaves(rangeRef, range, EQWAVES_DATA)
End

Function/WAVE SFH_GetFullRange()

	Make/FREE/D range = {-Inf, Inf}

	return range
End

Function SFH_IsFullRange(WAVE range)

	ASSERT(IsNumericWave(range), "Invalid Range wave")
	WAVE rangeRef = SFH_GetFullRange()

	return EqualWaves(rangeRef, range, EQWAVES_DATA)
End

Function/WAVE SFH_AsDataSet(WAVE data)

	Make/FREE/WAVE/N=1 output
	output[0] = data

	return output
End

/// @brief Formula "cursors(A,B)" can return NaNs if no cursor(s) are set.
static Function SFH_ExtendIncompleteRanges(WAVE/WAVE ranges)

	for(WAVE/Z wv : ranges)
		if(!WaveExists(wv))
			continue
		endif

		if(IsNumericWave(wv))
			SFH_ASSERT(DimSize(wv, ROWS) == 2, "Numerical range must have two rows in the form [start, end].")
			wv[0][] = IsNaN(wv[0][q]) ? -Inf : wv[0][q]
			wv[1][] = IsNaN(wv[1][q]) ? Inf : wv[1][q]
		endif
	endfor
End

/// @brief Evaluate range parameter
///
/// Range is read as dataset(s), it can be per dataset:
/// - numerical 1D: `[start,end]`
/// - numerical 2D with multiple ranges: `[[start1,start2,start3],[end1,end2,end3]]`
///    - implicit: `cursors(A, B)` or `[cursors(A, B), cursors(C, D)]`
///    - implicit: `epochs([E0, TP])`
///    - implicit with offset calculcation: `epochs(E0) + [1, -1]`
/// - named epoch: `E0` or a as wildcard expression `E*` or multiple
///
/// If one dataset is returned, numRows == 1, all ranges will be used for
/// all sweeps in the selection.
///
/// When multiple datasets are returned, numRows > 1, the i-th sweep will use
/// all ranges from the i-th dataset. The number of sweeps and datasets also
/// has to match.
///
/// @return One or multiple datasets
Function/WAVE SFH_EvaluateRange(variable jsonId, string jsonPath, string graph, string opShort, variable argNum)

	variable numArgs

	numArgs = SFH_GetNumberOfArguments(jsonId, jsonPath)

	if(argNum < numArgs)
		WAVE/WAVE ranges    = SF_ResolveDatasetFromJSON(jsonId, jsonPath, graph, argNum)
		WAVE      rangesTmp = SFH_MoveDatasetHigherIfCompatible(ranges)
		WAVE      ranges    = rangesTmp

		SFH_ExtendIncompleteRanges(ranges)

		return ranges
	endif

	return SFH_AsDataSet(SFH_GetFullRange())
End

/// @brief Returns a range from a epochName
///
/// @param graph     name of databrowser graph
/// @param epochName name epoch
/// @param sweep     number of sweep
/// @param chanType  type of channel
/// @param channel   number of DA channel
/// @param mapIndex  index in sweepMap, required if source is a SweepBrowser
///
/// @returns a 1D wave with two elements, [startTime, endTime] in ms, if no epoch could be resolved [NaN, NaN] is returned
Function/WAVE SFH_GetRangeFromEpoch(string graph, string epochName, variable sweep, variable chanType, variable channel, variable mapIndex)

	string   regex
	variable numEpochs

	WAVE range = SFH_GetEmptyRange()
	if(IsEmpty(epochName) || !IsValidSweepNumber(sweep))
		return range
	endif

	DFREF sweepDFR
	[WAVE numericalValues, WAVE textualValues, sweepDFR] = SFH_GetLabNoteBooksAndDFForSweep(graph, sweep, mapIndex)
	if(!WaveExists(numericalValues) || !WaveExists(textualValues))
		return range
	endif
	SFH_ASSERT(DataFolderExistsDFR(sweepDFR), "Could not determine sweepDFR")

	regex = "^" + epochName + "$"
	WAVE/Z/T epochs = EP_GetEpochs(numericalValues, textualValues, sweep, chanType, channel, regex, sweepDFR = sweepDFR)
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

Function/WAVE SFH_GetSweepsForFormula(string graph, WAVE/Z/WAVE selectDataArray, string opShort)

	if(!WaveExists(selectDataArray))
		return $""
	endif

	WAVE/Z/WAVE result = $""

	for(WAVE/Z/WAVE selectDataComp : selectDataArray)

		WAVE/Z/WAVE sweepData = SFH_GetSweepsForFormulaImpl(graph, selectDataComp, opShort)
		if(!WaveExists(sweepData))
			continue
		endif

		if(!WaveExists(result))
			WAVE/WAVE result = sweepData
			continue
		endif

		Concatenate/FREE/WAVE/NP {sweepData}, result
	endfor

	if(WaveExists(result))
		return result
	endif

	WAVE/WAVE result = SFH_CreateSFRefWave(graph, opShort, 0)
	JWN_SetStringInWaveNote(result, SF_META_DATATYPE, SF_DATATYPE_SWEEP)

	return result
End

/// @brief Return a wave reference wave with the requested sweep data. The argument range can contain multiple datasets,
///        if it is a single dataset the range(s) are extracted from each selection,
///        if there are multiple datasets then the number of datasets must equal the number of selections,
///        for that case range datasets and selections are indexed the same.
///        This is usually only senseful if the same select arguments are used for e.g. data to retrieve sweeps and epochs to retrieve ranges.
///
/// All wave input parameters are treated as const and are thus *not* modified.
///
/// @param graph          name of databrowser graph
/// @param selectDataComp channel/sweep selection composite, see also SFH_GetArgumentSelect()
/// @param opShort        operation name (short)
static Function/WAVE SFH_GetSweepsForFormulaImpl(string graph, WAVE/WAVE selectDataComp, string opShort)

	variable i, j, rangeStart, rangeEnd, sweepNo, isSingleRange
	variable chanNr, chanType, cIndex, isSweepBrowser, mapIndex
	variable numSelected, index, numRanges, sweepSize, samplingInterval, samplingOffset
	variable rangeStartIndex, rangeEndIndex, colorGroup

	string dimLabel, device, experiment
	ASSERT(WindowExists(graph), "graph window does not exist")

	WAVE/Z    selectData = selectDataComp[%SELECTION]
	WAVE/WAVE range      = selectDataComp[%RANGE]

	if(!WaveExists(selectData) || !DimSize(range, ROWS))
		return $""
	endif
	SFH_ASSERT(DimSize(selectData, COLS) == 4, "Select data must have 4 columns.")
	isSingleRange = DimSize(range, ROWS) == 1

	numSelected = DimSize(selectData, ROWS)
	if(!isSingleRange)
		SFH_ASSERT(DimSize(range, ROWS) == numSelected, "Number of ranges is not equal number of selection.")
	endif

	WAVE/WAVE output = SFH_CreateSFRefWave(graph, opShort, numSelected)

	isSweepBrowser = BSP_IsSweepBrowser(graph)
	if(isSweepBrowser)
		WAVE/T sweepMap = SB_GetSweepMap(graph)
	else
		experiment = GetExperimentName()
		device     = BSP_GetDevice(graph)
	endif

	for(i = 0; i < numSelected; i += 1)

		WAVE/Z setRange = range[isSingleRange ? 0 : i]

		if(!WaveExists(setRange))
			continue
		endif

		sweepNo = selectData[i][%SWEEP]
		if(!isSweepBrowser && DB_SplitSweepsIfReq(graph, sweepNo))
			continue
		endif
		chanNr   = selectData[i][%CHANNELNUMBER]
		chanType = selectData[i][%CHANNELTYPE]
		mapIndex = selectData[i][%SWEEPMAPINDEX]

		DFREF sweepDFR
		[WAVE numericalValues, WAVE textualValues, sweepDFR] = SFH_GetLabNoteBooksAndDFForSweep(graph, sweepNo, selectData[i][%SWEEPMAPINDEX])
		SFH_ASSERT(WaveExists(textualValues) && WaveExists(numericalValues), "LBN not found for sweep " + num2istr(sweepNo))
		if(!DataFolderExistsDFR(sweepDFR))
			continue
		endif
		if(isSweepBrowser)
			device     = sweepMap[mapIndex][%Device]
			experiment = sweepMap[mapIndex][%FileName]
		endif

		WAVE/Z sweep = GetDAQDataSingleColumnWaveNG(numericalValues, textualValues, sweepNo, sweepDFR, chanType, chanNr)
		if(!WaveExists(sweep))
			continue
		endif

		WAVE/ZZ   adaptedRange
		WAVE/ZZ/T epochRangeNames
		[adaptedRange, epochRangeNames] = SFH_GetNumericRangeFromEpoch(graph, numericalValues, textualValues, setRange, sweepNo, chanType, chanNr, mapIndex)

		if(!WaveExists(adaptedRange) && !WaveExists(epochRangeNames))
			continue
		endif

		sweepSize        = DimSize(Sweep, ROWS)
		samplingInterval = DimDelta(sweep, ROWS)
		samplingOffset   = DimOffset(sweep, ROWS)

		numRanges = DimSize(adaptedRange, COLS)
		for(j = 0; j < numRanges; j += 1)
			rangeStart = adaptedRange[0][j]
			rangeEnd   = adaptedRange[1][j]

			rangeStartIndex = round((rangeStart - samplingOffset) / samplingInterval)
			rangeEndIndex   = round((rangeEnd - samplingOffset) / samplingInterval)

			// Release 8c6e5da (EP_WriteEpochInfoIntoSweepSettings: Handle unacquired data, 2021-07-13) and before:
			// we did not cap epoch ranges properly on aborted/shortened sweeps
			// we also did not calculate the sampling points for TP and Stimesets exactly the same way
			// Thus, if necessary we clip the data here.
			if(WaveExists(epochRangeNames))
				// complete epoch starting at or beyond sweep end
				if(rangeStartIndex >= sweepSize)
					continue
				endif
				rangeEndIndex = limit(rangeEndIndex, -Inf, sweepSize)
			endif

			SFH_ASSERT(rangeStartIndex < (rangeEndIndex - 1), "Starting range must be smaller than the ending range for sweep " + num2istr(sweepNo) + ".")
			SFH_ASSERT(rangeStartIndex == -Inf || (IsFinite(rangeStartIndex) && rangeStartIndex >= 0 && rangeStartIndex < sweepSize), "Specified starting range not inside sweep " + num2istr(sweepNo) + ".")
			SFH_ASSERT(rangeEndIndex == Inf || (IsFinite(rangeEndIndex) && rangeEndIndex > 0 && rangeEndIndex <= sweepSize), "Specified ending range not inside sweep " + num2istr(sweepNo) + ".")
			Duplicate/FREE/RMD=[rangeStartIndex, rangeEndIndex - 1] sweep, rangedSweepData

			if(WaveExists(epochRangeNames))
				Make/FREE/T entry = {epochRangeNames[j]}
				JWN_SetWaveInWaveNote(rangedSweepData, SF_META_RANGE, entry)
			else
				// we write here on purpose the requested range
				JWN_SetWaveInWaveNote(rangedSweepData, SF_META_RANGE, {rangeStart, rangeEnd})
			endif

			JWN_SetNumberInWaveNote(rangedSweepData, SF_META_SWEEPNO, sweepNo)
			JWN_SetNumberInWaveNote(rangedSweepData, SF_META_CHANNELTYPE, chanType)
			JWN_SetNumberInWaveNote(rangedSweepData, SF_META_CHANNELNUMBER, chanNr)
			JWN_SetStringInWaveNote(rangedSweepData, SF_META_DEVICE, device)
			JWN_SetStringInWaveNote(rangedSweepData, SF_META_EXPERIMENT, experiment)
			if(!IsNaN(mapIndex))
				JWN_SetNumberInWaveNote(rangedSweepData, SF_META_SWEEPMAPINDEX, mapIndex)
			endif

			colorGroup = GetUniqueInteger()
			JWN_SetNumberInWaveNote(rangedSweepData, SF_META_COLOR_GROUP, colorGroup)

			JWN_SetNumberInWaveNote(rangedSweepData, SF_META_TRACE_MODE, TRACE_DISPLAY_MODE_LINES)

			EnsureLargeEnoughWave(output, indexShouldExist = index)
			output[index] = rangedSweepData
			index        += 1
		endfor
	endfor
	if(!index)
		return $""
	endif
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

	return (JSON_GetType(jsonId, jsonPath + "/0") == JSON_NULL) ? 0 : size
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

Function SFH_IsVariable(WAVE dataset)

	return JWN_GetNumberFromWaveNote(dataset, SF_VARIABLE_MARKER) == 1
End

Function SFH_CleanUpInput(WAVE input)

#ifndef SWEEPFORMULA_DEBUG
	if(SFH_IsVariable(input))
		return NaN
	endif
	KillOrMoveToTrash(wv = input)
#endif // !SWEEPFORMULA_DEBUG
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

	WAVE/Z/T wStack = JSON_GetKeys(argStackId, "", ignoreErr = 1)
	if(waveExists(wStack))
		stackCnt = DimSize(wStack, ROWS)
	endif
	JSON_AddString(argStackId, "/" + num2istr(stackCnt), argSetupStr)
	JWN_SetStringInWaveNote(output, SF_META_ARGSETUPSTACK, JSON_Dump(argStackId))
	JSON_Release(argStackId)
End

Function/WAVE SFH_GetOutputForExecutorSingle(WAVE/Z data, string graph, string opShort, [variable discardOpStack, WAVE clear, string dataType])

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

Function/WAVE SFH_GetOutputForExecutor(WAVE output, string win, string opShort, [WAVE clear])

	if(!ParamIsDefault(clear))
		SFH_CleanUpInput(clear)
	endif
	Make/FREE/T wRefPath = {SF_WREF_MARKER + GetWavesDataFolder(output, 2)}

#ifdef SWEEPFORMULA_DEBUG
	SFH_ConvertAllReturnDataToPermanent(output, win, opShort)
#endif // SWEEPFORMULA_DEBUG

	return wRefPath
End

static Function SFH_ConvertAllReturnDataToPermanent(WAVE/WAVE output, string win, string opShort)

	string   wName
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

/// @brief If the copy condition is met and dataset is a variable then returns a free copy of data
///        dataset and data can refer to the same wave
Function/WAVE SFH_CopyDataIfRequired(variable copy, WAVE/Z dataset, WAVE/Z data)

	if(!WaveExists(data) || !WaveExists(dataset))
		// There are cases where the caller calls SFH_CleanUpInput on the dataset before this function is called
		// Datasets are only cleaned if they are not a variable.
		return data
	endif

	return FreeCopyOnTrue(copy && SFH_IsVariable(dataset), data)
End

/// @brief Retrieves from an argument the datatype and the first dataset and disposes the argument
Function [WAVE data, string dataType] SFH_ResolveDatasetElementFromJSONAndType(variable jsonId, string jsonPath, string graph, string opShort, variable argNum, [variable checkExist, variable copy])

	checkExist = ParamIsDefault(checkExist) ? 0 : !!checkExist
	copy       = ParamIsDefault(copy) ? 0 : !!copy

	WAVE/WAVE input = SF_ResolveDatasetFromJSON(jsonId, jsonPath, graph, argNum)
	dataType = JWN_GetStringFromWaveNote(input, SF_META_DATATYPE)
	WAVE/Z data         = SFH_CheckForSingleDSAndGetData(input, checkExist, opShort, argNum)
	WAVE/Z possDataCopy = SFH_CopyDataIfRequired(copy, input, data)

	return [possDataCopy, dataType]
End

static Function/WAVE SFH_CheckForSingleDSAndGetData(WAVE/WAVE input, variable checkExist, string opShort, variable argNum)

	SFH_ASSERT(DimSize(input, ROWS) == 1, "Expected only a single dataSet")
	WAVE/Z data = input[0]
	SFH_ASSERT(!(checkExist && !WaveExists(data)), "No data in dataSet at operation " + opShort + " arg num " + num2istr(argNum))
	SFH_CleanUpInput(input)

	return data
End

/// @brief Retrieves from an argument the first dataset and disposes the argument
Function/WAVE SFH_ResolveDatasetElementFromJSON(variable jsonId, string jsonPath, string graph, string opShort, variable argNum, [variable checkExist, variable copy])

	checkExist = ParamIsDefault(checkExist) ? 0 : !!checkExist
	copy       = ParamIsDefault(copy) ? 0 : !!copy

	WAVE/WAVE input = SF_ResolveDatasetFromJSON(jsonId, jsonPath, graph, argNum)
	WAVE/Z    data  = SFH_CheckForSingleDSAndGetData(input, checkExist, opShort, argNum)

	return SFH_CopyDataIfRequired(copy, input, data)
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
Function SFH_TransferFormulaDataWaveNoteAndMeta(WAVE/WAVE input, WAVE/WAVE output, string opShort, string newDataType, [WAVE/T argSetup, variable keepX])

	variable sweepNo, numResults, i, setXLabel, size, oldJSONId, newJSONId
	string opStack, argSetupStr, inDataType, key
	string xLabel = ""

	numResults = DimSize(input, ROWS)
	ASSERT(numResults == DimSize(output, ROWS), "Input and output must have the same size.")
	keepX = ParamIsDefault(keepX) ? 0 : !!keepX
	if(ParamIsDefault(argSetup))
		WAVE/T argSetup = SFH_GetNewArgSetupWave(1)
		argSetup[0][%KEY]   = SFH_ARGSETUP_OPERATION_KEY
		argSetup[0][%VALUE] = opShort
	else
		size = DimSize(argSetup, ROWS)
		Redimension/N=(size + 1, -1) argSetup
		argSetup[size][%KEY]   = SFH_ARGSETUP_OPERATION_KEY
		argSetup[size][%VALUE] = opShort
	endif
	argSetupStr = SFH_SerializeArgSetup(argSetup)

	if(keepX)
		xLabel = JWN_GetStringFromWaveNote(output, SF_META_XAXISLABEL)
	endif

	JWN_SetStringInWaveNote(output, SF_META_DATATYPE, newDataType)
	JWN_SetNumberInWaveNote(output, SF_VARIABLE_MARKER, 0)

	opStack = JWN_GetStringFromWaveNote(input, SF_META_OPSTACK)
	SFH_AddOpToOpStack(output, opStack, opShort)
	SFH_AddToArgSetupStack(output, input, argSetupStr)

	inDataType = JWN_GetStringFromWaveNote(input, SF_META_DATATYPE)

	setXLabel = 1
	for(i = 0; i < numResults; i += 1)
		WAVE/Z inData  = input[i]
		WAVE/Z outData = output[i]
		if(!WaveExists(inData) || !WaveExists(outData))
			continue
		endif

		if(keepX)
			WAVE/Z xValues = JWN_GetNumericWaveFromWaveNote(outData, SF_META_XVALUES)

			if(!WaveExists(xValues))
				WAVE/Z xValues = JWN_GetTextWaveFromWaveNote(outData, SF_META_XVALUES)
			endif
		endif

		oldJSONId = JWN_GetWaveNoteAsJSON(outData)
		newJSONId = JWN_GetWaveNoteAsJSON(inData)

		// wave note of the outData wave consists of:
		// - non-JWN header from inData
		// - JWN from inData (optional)
		// - plus all toplevel keys from outData (duplicates from inData are overwritten, also optional)
		Note/K outData, note(inData)

		if(cmpstr(WAVE_NOTE_EMPTY_JSON, JSON_Dump(newJSONId)))
			JSON_SyncJSON(oldJSONId, newJSONId, "", "", JSON_SYNC_OVERWRITE_IN_TARGET)
			JWN_SetWaveNoteFromJSON(outData, newJSONId, release = 0)
		endif

		JSON_Release(oldJSONId)
		JSON_Release(newJSONId)

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

/// @brief This function returns an array of select composites that are parsed from one argument
///        that can be either a single select: select(...)
///        or an 1d array of selects: [select(...), select(...), ...]
///        The distinction between a single select an array of selects is done through the SF_META_DATATYPE field in the JSON wavenote
///        select composites are of type SF_DATATYPE_SELECTCOMP, whereas arrays are untyped
///        There is also a quick path for argNum >= numArgs, which is the case for e.g. data()
///        For that case numArgs is 0 and select is expected at argNum 0. Then the result of "select()" is
///        returned (as selectArray with a single element)
///
///        selectArray is wave reference wave containing select composite wave reference waves with SELECTION, RANGE each.
///
///        This allows operations with selects as arguments to iterate over different selections given by the user
Function/WAVE SFH_GetArgumentSelect(variable jsonId, string jsonPath, string graph, string opShort, variable argNum)

	variable numArgs
	string   type

	numArgs = SFH_GetNumberOfArguments(jsonID, jsonPath)
	if(argNum < numArgs)

		WAVE/WAVE selectComp = SF_ResolveDatasetFromJSON(jsonId, jsonPath, graph, argNum)
		type = JWN_GetStringFromWaveNote(selectComp, SF_META_DATATYPE)
		if(!CmpStr(type, SF_DATATYPE_SELECTCOMP))
			Make/FREE/WAVE selectArray = {selectComp}

			return selectArray
		endif

		SFH_ASSERT(DimSize(selectComp, ROWS) == 1, "Expected a single array")
		WAVE array = selectComp[0]
		SFH_ASSERT(IsTextWave(array), "Expected a text wave")

		Make/FREE/WAVE/N=(DimSize(array, ROWS)) selectArray = SFH_AttemptDatasetResolve(WaveText(array, row = p), checkWithSFHAssert = 1)
		for(WAVE/Z/WAVE selectComp : selectArray)
			ASSERT(WaveExists(selectComp), "Expected select composite")
			type = JWN_GetStringFromWaveNote(selectComp, SF_META_DATATYPE)
			SFH_ASSERT(!CmpStr(type, SF_DATATYPE_SELECTCOMP), "Expected select data as argument")
		endfor

		return selectArray
	endif

	WAVE selectComp = SF_ExecuteFormula(SFH_DEFAULT_SELECT_FORMULA, graph, useVariables = 0)
	Make/FREE/WAVE selectArray = {selectComp}

	return selectArray
End

Function/WAVE SFH_GetEpochNamesFromInfo(WAVE/T epochInfo)

	string epName, epShortName, epLongName
	variable i
	variable numEpochs = DimSize(epochInfo, ROWS)

	Make/FREE/T/N=(numEpochs) epNames
	for(i = 0; i < numEpochs; i += 1)
		epName      = epochInfo[i][EPOCH_COL_TAGS]
		epShortName = EP_GetShortName(epName)
		epLongName  = RemoveEnding(epName, ";")
		epNames[i]  = SelectString(IsEmpty(epShortName), epShortName, epLongName)
	endfor

	return epNames
End

Function/WAVE SFH_GetEpochIndicesByWildcardPatterns(WAVE/T epochNames, WAVE/T patterns)

	variable i
	variable numPatterns = DimSize(patterns, ROWS)

	for(i = 0; i < numPatterns; i += 1)
		WAVE/Z indices = FindIndizes(epochNames, str = patterns[i], prop = PROP_WILDCARD)
		if(!WaveExists(indices))
			continue
		endif
		Concatenate/FREE/NP {indices}, allIndices
	endfor
	if(!WaveExists(allIndices))
		return $""
	endif
	WAVE uniqueEntries = GetUniqueEntries(allIndices, dontDuplicate = 1)

	return uniqueEntries
End

Function/S SFH_ResultTypeToString(variable resultType)

	switch(resultType)
		case SFH_RESULT_TYPE_STORE:
			return "store"
		case SFH_RESULT_TYPE_PSX_EVENTS:
			return "psx events"
		case SFH_RESULT_TYPE_PSX_MISC:
			return "psx misc"
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
	numCursors      = ItemsInList(CURSOR_NAMES)
	numBasicEntries = 5
	numEntries      = numBasicEntries + numCursors + hasStoreEntry

	Make/T/FREE/N=(1, numEntries) keys
	Make/T/FREE/N=(1, numEntries, LABNOTEBOOK_LAYER_COUNT) values

	keys[0][0]                                                 = "Sweep Formula code"
	keys[0][1]                                                 = "Sweep Formula sweeps/channels"
	keys[0][2]                                                 = "Sweep Formula experiment"
	keys[0][3]                                                 = "Sweep Formula device"
	keys[0][4]                                                 = "Sweep Formula browser"
	keys[0][numBasicEntries, numBasicEntries + numCursors - 1] = "Sweep Formula cursor " + StringFromList(q - numBasicEntries, CURSOR_NAMES)

	if(hasStoreEntry)
		ASSERT(IsWaveRefWave(data), "Expected a wave reference wave")
		SFH_ASSERT(!ParamIsDefault(resultType), "Missing type")
		SFH_ASSERT(IsValidLiberalObjectName(name[0]), "Can not use the given name for the labnotebook key")
		keys[0][numEntries - 1] = SFH_FormatResultsKey(resultType, name)
	endif

	LBN_SetDimensionLabels(keys, values)

	values[0][%$"Sweep Formula code"][INDEP_HEADSTAGE] = NormalizeToEOL(TrimString(code), "\n")

	WAVE/Z/T cursorInfos = GetCursorInfos(graph)

	WAVE/Z/WAVE selectData = SF_ExecuteFormula(SFH_DEFAULT_SELECT_FORMULA, graph, useVariables = 0)
	if(WaveExists(selectData) && WaveExists(selectData[0]))
		values[0][%$"Sweep Formula sweeps/channels"][INDEP_HEADSTAGE] = NumericWaveToList(selectData[0], ",", colSep = ";")
	endif

	shPanel = LBV_GetSettingsHistoryPanel(graph)

	dataFolder                                               = GetPopupMenuString(shPanel, "popup_experiment")
	values[0][%$"Sweep Formula experiment"][INDEP_HEADSTAGE] = dataFolder

	device                                               = GetPopupMenuString(shPanel, "popup_Device")
	values[0][%$"Sweep Formula device"][INDEP_HEADSTAGE] = device

	values[0][%$"Sweep Formula browser"][INDEP_HEADSTAGE] = graph

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

	WAVE/T matches = SFH_GetFormulaGraphs()

	for(entry : matches)
		if(!cmpstr(SFH_GetBrowserForFormulaGraph(entry), browser))
			return entry
		endif
	endfor

	return ""
End

/// @brief Return a text wave with all formula graph windows
Function/WAVE SFH_GetFormulaGraphs()

	return ListToTextWave(WinList(CleanupName(SF_PLOT_NAME_TEMPLATE, 0) + "*", ";", "WIN:64"), ";") // only panels
End

/// @brief Create a new selectData wave
///        The row counts the selected combinations of sweep, channel type, channel number
///        The three columns per row store the sweep number, channel type, channel number
Function/WAVE SFH_NewSelectDataWave(variable numSweeps, variable numChannels)

	ASSERT(numSweeps >= 0 && numChannels >= 0, "Invalid wave size specified")

	Make/FREE/D/N=(numSweeps * numChannels, 4) selectData = NaN
	SetDimLabel COLS, 0, SWEEP, selectData
	SetDimLabel COLS, 1, CHANNELTYPE, selectData
	SetDimLabel COLS, 2, CHANNELNUMBER, selectData
	SetDimLabel COLS, 3, SWEEPMAPINDEX, selectData

	return selectData
End

/// @brief Parse the range stored in the JSON wavenote from SFH_GetSweepsForFormula()
Function/WAVE SFH_ParseSweepDataRange(WAVE sweepData)

	WAVE/Z range = JWN_GetNumericWaveFromWaveNote(sweepData, SF_META_RANGE)

	if(!WaveExists(range))
		WAVE/Z range = JWN_GetTextWaveFromWaveNote(sweepData, SF_META_RANGE)
	endif

	if(!WaveExists(range) || !HasOneValidEntry(range))
		return $""
	endif

	return range
End

/// @brief Recreate a **single** select data wave and range stored in the JSON wavenote from SFH_GetSweepsForFormula()
Function [WAVE selectData, WAVE range] SFH_ParseToSelectDataWaveAndRange(WAVE sweepData)

	WAVE/Z range = SFH_ParseSweepDataRange(sweepData)

	if(!WaveExists(range))
		return [$"", $""]
	endif

	WAVE selectData = SFH_NewSelectDataWave(1, 1)

	selectData[0][%SWEEP]         = JWN_GetNumberFromWaveNote(sweepData, SF_META_SWEEPNO)
	selectData[0][%CHANNELTYPE]   = JWN_GetNumberFromWaveNote(sweepData, SF_META_CHANNELTYPE)
	selectData[0][%CHANNELNUMBER] = JWN_GetNumberFromWaveNote(sweepData, SF_META_CHANNELNUMBER)
	selectData[0][%SWEEPMAPINDEX] = JWN_GetNumberFromWaveNote(sweepData, SF_META_SWEEPMAPINDEX)

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
	jsonIdOp    = JSON_Parse(argSetupStr)

	WAVE/Z/T keys = JSON_GetKeys(jsonIdOp, "")
	if(!WaveExists(keys))
		WAVE/T argSetup = SFH_GetNewArgSetupWave(0)
		return argSetup
	endif

	size = DimSize(keys, ROWS)
	WAVE/T argSetup = SFH_GetNewArgSetupWave(size)
	argSetup[][%KEY]   = keys[p]
	argSetup[][%VALUE] = JSON_GetString(jsonIdOp, "/" + keys[p])

	JSON_Release(jsonIdOp)

	return argSetup
End

Function SFH_ResetArgSetupStack(WAVE output, string opShort)

	string argSetupStr

	WAVE/T argSetup = SFH_GetNewArgSetupWave(1)
	argSetup[0][%KEY]   = SFH_ARGSETUP_OPERATION_KEY
	argSetup[0][%VALUE] = opShort
	argSetupStr         = SFH_SerializeArgSetup(argSetup)
	SFH_AddToArgSetupStack(output, $"", argSetupStr, resetStack = 1)
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

	jsonId  = JSON_New()
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
	endif

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
				testKey   = uniqueKeys[j]
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
		opStackStr[]      = shrinkedDiff[p][i] + " " + opStackStr[p]
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
			buildDiffArgsStr    = RemoveEnding(buildDiffArgsStr, " ")
			shrinkedDiff[j][i] += "(" + buildDiffArgsStr + ")"
		endfor
	endfor

	opStackStr[] = RemoveEnding(opStackStr[p], " ")
	for(i = 0; i < numFormulas; i += 1)
		newAnnotation = ""
		for(j = 0; j < numOps; j += 1)
			newAnnotation = shrinkedDiff[i][j] + " " + newAnnotation
		endfor
		newAnnotation  = RemoveEnding(newAnnotation, " ")
		annotations[i] = ReplaceString(opStackStr[i], annotations[i], newAnnotation)
	endfor

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
			idx                      += 1
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
	string   errMsg

	maxArgs = ParamIsDefault(maxArgs) ? Inf : maxArgs
	numArgs = SFH_GetNumberOfArguments(jsonID, jsonPath)
	sprintf errMsg, "%s has %d arguments at most.", opShort, maxArgs
	SFH_ASSERT(numArgs <= maxArgs, errMsg)
	sprintf errMsg, "%s needs at least %d argument(s).", opShort, minArgs
	SFH_ASSERT(numArgs >= minArgs, errMsg)

	return numArgs
End

/// @brief Return a SF range in ms with the stimset range
///
/// Prefers the `ST` epoch if present, otherwise it tries to deduce the
/// equivalent from labnotebook entries.
Function/WAVE SFH_GetStimsetRange(string graph, WAVE data, WAVE selectData)

	variable sweepNo, channel, chanType, mapIndex, dDAQ, oodDAQ, onsetDelay, terminationDelay, lengthInMS

	sweepNo  = selectData[0][%SWEEP]
	channel  = selectData[0][%CHANNELNUMBER]
	chanType = selectData[0][%CHANNELTYPE]
	mapIndex = selectData[0][%SWEEPMAPINDEX]

	// stimset epoch "ST" does not include any onset or termination delay and only the stimset epochs
	// and it also works with dDAQ/oodDAQ
	WAVE range = SFH_GetRangeFromEpoch(graph, "ST", sweepNo, chanType, channel, mapIndex)

	if(!SFH_IsEmptyRange(range))
		return range
	endif

	// data prior to 13b3499d (Add short names for Epochs stored in epoch name, 2021-09-06)
	// try the long name instead
	WAVE range = SFH_GetRangeFromEpoch(graph, "Stimset;", sweepNo, chanType, channel, mapIndex)

	if(!SFH_IsEmptyRange(range))
		return range
	endif

	// data prior to a2172f03 (Added generations of epoch information wave, 2019-05-22)
	// remove total onset delay and termination delay iff we have neither dDAQ nor oodDAQ enabled
	WAVE numericalValues = SFH_GetLabNoteBookForSweep(graph, sweepNo, mapIndex, LBN_NUMERICAL_VALUES)
	ASSERT(WaveExists(numericalValues), "Missing numerical labnotebook")

	// 778969b0 (DC_PlaceDataInITCDataWave: Document all other settings from the DAQ groupbox, 2015-11-26)
	dDAQ = GetLastSettingIndep(numericalValues, sweepNo, "Distributed DAQ", DATA_ACQUISITION_MODE)
	SFH_ASSERT(dDAQ != 1, "Can not gather stimset range with dDAQ data")

	// d102c07d (Add new data acquisition mode: Optimized overlap distributed acquisition, 2016-08-10)
	oodDAQ = GetLastSettingIndep(numericalValues, sweepNo, "Optimized Overlap dDAQ", DATA_ACQUISITION_MODE)
	SFH_ASSERT(oodDAQ != 1, "Can not gather stimset range with oodDAQ data")

	onsetDelay = GetTotalOnsetDelay(numericalValues, sweepNo)

	// 778969b0 (DC_PlaceDataInITCDataWave: Document all other settings from the DAQ groupbox, 2015-11-26)
	terminationDelay = GetLastSettingIndep(numericalValues, sweepNo, "Delay termination", DATA_ACQUISITION_MODE)

	lengthInMS = DimDelta(data, ROWS) * DimSize(data, ROWS)

	WAVE range = SFH_GetEmptyRange()

	range[0] = onsetDelay
	range[1] = lengthInMS - onsetDelay - terminationDelay

	ASSERT(range[0] < range[1], "Invalid range")

	return range
End

Function [WAVE adaptedRange, WAVE/T epochRangeNames] SFH_GetNumericRangeFromEpochFromSingleSelect(string graph, WAVE singleSelectData, WAVE range)

	variable sweepNo, chanNr, chanType, mapIndex

	sweepNo  = singleSelectData[0][%SWEEP]
	chanNr   = singleSelectData[0][%CHANNELNUMBER]
	chanType = singleSelectData[0][%CHANNELTYPE]
	mapIndex = singleSelectData[0][%SWEEPMAPINDEX]

	WAVE/Z numericalValues = SFH_GetLabNoteBookForSweep(graph, sweepNo, mapIndex, LBN_NUMERICAL_VALUES)
	WAVE/Z textualValues   = SFH_GetLabNoteBookForSweep(graph, sweepNo, mapIndex, LBN_TEXTUAL_VALUES)
	SFH_ASSERT(WaveExists(textualValues) && WaveExists(numericalValues), "LBN not found for sweep " + num2istr(sweepNo))

	[WAVE resolvedRanges, WAVE/T epochRangeNames] = SFH_GetNumericRangeFromEpoch(graph, numericalValues, textualValues, range, sweepNo, chanType, chanNr, mapIndex)

	return [resolvedRanges, epochRangeNames]
End

/// @brief From a single numeric/textual range wave we return a 2xN numeric range
///
/// Supports numeric ranges, epochs, and epochs with wildcards.
///
/// @param graph           name of graph window
/// @param numericalValues numeric labnotebok
/// @param textualValues   textual labnotebok
/// @param range           one numerical or one/multiple epoch ranges with optional wildcard, @see SFH_EvaluateRange
/// @param sweepNo         sweep number
/// @param chanType        channel type
/// @param chanNr          channel number
/// @param mapIndex        index in sweepMap if graph is a SweepBrowser
///
/// @retval adaptedRange    2xN numeric wave with the start/stop ranges [ms]
/// @retval epochRangeNames epoch names (wildcard expanded) in case range was textual, a null wave ref otherwise
Function [WAVE adaptedRange, WAVE/T epochRangeNames] SFH_GetNumericRangeFromEpoch(string graph, WAVE numericalValues, WAVE textualValues, WAVE range, variable sweepNo, variable chanType, variable chanNr, variable mapIndex)

	string epochTag, epochShortName
	variable numEpochs, epIndex, i, j
	string allEpochsRegex = "^.*$"

	if(IsNumericWave(range))
		ASSERT(IsDoubleFloatingPointWave(range), "Expected a double wave")

		Duplicate/FREE range, adaptedRange
		if(!DimSize(adaptedRange, COLS))
			Redimension/N=(-1, 1) adaptedRange
		endif

		SFH_ASSERT(!SFH_IsEmptyRange(adaptedRange), "Specified range not valid.")

		return [adaptedRange, $""]
	endif

	WAVE/T epochPatterns = range
	SFH_ASSERT(IsTextWave(epochPatterns) && !DimSize(epochPatterns, COLS), "Expected 1d text wave for epoch specification")

	if(BSP_IsSweepBrowser(graph))
		DFREF sweepBrowserDFR = SB_GetSweepBrowserFolder(graph)
		DFREF sweepDFR        = SB_GetSweepDataPathFromIndex(sweepBrowserDFR, mapIndex)
	else
		DFREF deviceDFR = DB_GetDeviceDF(graph)
		DFREF sweepDFR  = GetSingleSweepFolder(deviceDFR, sweepNo)
	endif
	SFH_ASSERT(DataFolderExistsDFR(sweepDFR), "Could not determine sweepDFR")
	WAVE/Z/T epochInfo = EP_GetEpochs(numericalValues, textualValues, sweepNo, chanType, chanNr, allEpochsRegex, sweepDFR = sweepDFR)
	if(!WaveExists(epochInfo))
		return [$"", $""]
	endif

	WAVE/T allEpNames = SFH_GetEpochNamesFromInfo(epochInfo)
	WAVE/Z epIndices  = SFH_GetEpochIndicesByWildcardPatterns(allEpNames, epochPatterns)
	if(!WaveExists(epIndices))
		return [$"", $""]
	endif

	numEpochs = DimSize(epIndices, ROWS)
	WAVE adaptedRange = SFH_GetEmptyRange()

	Redimension/N=(-1, numEpochs) adaptedRange
	for(j = 0; j < numEpochs; j += 1)
		epIndex            = epIndices[j]
		adaptedRange[0][j] = str2num(epochInfo[epIndex][EPOCH_COL_STARTTIME]) * ONE_TO_MILLI
		adaptedRange[1][j] = str2num(epochInfo[epIndex][EPOCH_COL_ENDTIME]) * ONE_TO_MILLI
	endfor

	Make/FREE/T/N=(numEpochs) epochRangeNames = allEpNames[epIndices[p]]

	return [adaptedRange, epochRangeNames]
End

/// @brief Attempt a resolution of a dataset based on a string input, returns null wave if not resolvable
Function/WAVE SFH_AttemptDatasetResolve(string ref, [variable checkWithSFHAssert])

	string   wName
	variable cond

	checkWithSFHAssert = ParamisDefault(checkWithSFHAssert) ? 0 : !!checkWithSFHAssert

	if(strsearch(ref, SF_WREF_MARKER, 0) != 0)
		return $""
	endif

	wName = ref[strlen(SF_WREF_MARKER), Inf]
	WAVE/Z out = $wName

	cond = WaveExists(out)
	if(checkWithSFHAssert)
		SFH_ASSERT(cond, "Referenced wave not found: " + wName)
	else
		ASSERT(cond, "Referenced wave not found: " + wName)
	endif

	return out
End

/// @brief Check if data wave refers to an array
///        Note: The check is rather weak, another option would be tagging in the wavenote by the executor?
Function SFH_IsArray(WAVE data)

	if(!IsWaveRefWave(data))
		return 0
	endif
	if(!DimSize(data, ROWS) == 1)
		return 0
	endif

	return 1
End

/// @brief Moves datasets from array elements to higher level
///        e.g. [dataset(1, 2), dataset(3, 4)] -> dataset([1, 3], [3, 4])
///        e.g. [dataset(1, 2, 3), dataset(4, 5, 6)] -> dataset([1, 4], [2, 5], [3, 6])
///        e.g. [dataset(1, 2), dataset(4, 5), dataset(6, 7)] -> dataset([1, 4, 6], [2, 5, 7])
///        Requirements that this is possible are:
///        - all initial array elements must resolve to datasets
///        - all dataset waves of the initial array elements must be non-null, have the same size and must be 1d
///        - all elements of these datasets must be non-null, have the same type and the same size and must be max 3d
///        - only numeric and text is supported as type, thus the datasets may not contain datasets themselves
///        If none of the requirements are met the input data is returned.
Function/WAVE SFH_MoveDatasetHigherIfCompatible(WAVE/WAVE data)

	variable i, j, numOldSets, numNewSets, singleElement

	if(!SFH_IsArray(data))
		return data
	endif

	WAVE array = data[0]
	if(!IsTextWave(array))
		return data
	endif
	if(DimSize(array, COLS))
		return data
	endif

	numOldSets = DimSize(array, ROWS)
	Make/FREE/WAVE/N=(numOldSets) resolved

	resolved[] = SFH_AttemptDatasetResolve(WaveText(array, row = p))

	// check pre-conditions
	WAVE/ZZ prevSets
	WAVE/ZZ prevElement
	for(WAVE/Z/WAVE sets : resolved)
		if(!WaveExists(sets))
			return data
		endif
		if(!DimSize(sets, ROWS))
			return data
		endif

		if(!WaveExists(prevSets))
			WAVE prevSets = sets
		elseif(!EqualWaves(sets, prevSets, EQWAVES_DATATYPE | EQWAVES_DIMSIZE))
			return data
		endif

		for(WAVE element : sets)
			if(!WaveExists(element))
				return data
			endif
			if(!DimSize(element, ROWS))
				return data
			endif

			if(!WaveExists(prevElement))
				WAVE prevElement = element
			elseif(!EqualWaves(element, prevElement, EQWAVES_DATATYPE | EQWAVES_DIMSIZE))
				return data
			endif
		endfor
	endfor

	if(DimSize(element, CHUNKS))
		return data
	endif

	// move datasets to higher level
	singleElement = WaveDims(element) == 1 && DimSize(element, ROWS) == 1

	Duplicate/FREE/WAVE sets, newSets
	numNewSets = DimSize(newSets, ROWS)
	if(IsNumericWave(element))
		for(i = 0; i < numNewSets; i += 1)

			Make/FREE/D/N=(numOldSets, DimSize(element, ROWS), DimSize(element, COLS), DimSize(element, LAYERS)) newElement
			MultiThread newElement[][][][] = WaveRef(WaveRef(resolved, row = p), row = i)[q][r][s]
			if(singleElement)
				Redimension/N=(-1, 0, 0, 0) newElement
			endif
			newSets[i] = newElement
		endfor

		return newSets
	endif

	if(IsTextWave(element))
		for(i = 0; i < numNewSets; i += 1)

			Make/FREE/T/N=(numOldSets, DimSize(element, ROWS), DimSize(element, COLS), DimSize(element, LAYERS)) newElementT
			MultiThread newElementT[][][][] = WaveText(WaveRef(WaveRef(resolved, row = p), row = i), row = q, col = r, layer = s)
			if(singleElement)
				Redimension/N=(-1, 0, 0, 0) newElementT
			endif
			newSets[i] = newElementT
		endfor
		return newSets
	endif

	return data
End

Function/WAVE SFH_CreateSelectDataComp(string graph, string opShort, WAVE singleSelect, WAVE range)

	WAVE/WAVE selectDataComp = GetSFSelectDataComp(graph, opShort)
	JWN_SetStringInWaveNote(selectDataComp, SF_META_DATATYPE, SF_DATATYPE_SELECTCOMP)
	JWN_SetStringInWaveNote(singleSelect, SF_META_DATATYPE, SF_DATATYPE_SELECT)
	JWN_SetStringInWaveNote(range, SF_META_DATATYPE, SF_DATATYPE_SELECTRANGE)
	selectDataComp[%SELECTION] = singleSelect
	selectDataComp[%RANGE]     = SFH_AsDataSet(range)

	Make/FREE/WAVE selectDataArray = {selectDataComp}

	return selectDataArray
End

Function/WAVE SFH_GetSingleSelect(string graph, string opShort, variable sweepNo, variable channelType, variable channelNumber, variable mapIndex)

	WAVE range        = SFH_GetFullRange()
	WAVE singleSelect = SFH_NewSelectDataWave(1, 1)
	singleSelect[0][%SWEEP]         = sweepNo
	singleSelect[0][%CHANNELTYPE]   = channelType
	singleSelect[0][%CHANNELNUMBER] = channelNumber
	singleSelect[0][%SWEEPMAPINDEX] = mapIndex

	WAVE selectDataArray = SFH_CreateSelectDataComp(graph, opShort, singleSelect, range)

	return selectDataArray
End

Function/S SFH_GetStimsetName(WAVE numericalValues, WAVE textualValues, variable sweepNo, variable channelNumber, variable channelType)

	variable index

	[WAVE settings, index] = GetLastSettingChannel(numericalValues, textualValues, sweepNo, STIM_WAVE_NAME_KEY, channelNumber, channelType, DATA_ACQUISITION_MODE)
	ASSERT(WaveExists(settings), "Could not retrieve setName")

	return WaveText(settings, row = index)
End

Function SFH_IsSetQCPassed(WAVE numericalValues, WAVE textualValues, variable sweepNo, variable channelNumber, variable channelType)

	return SFH_GetIndepPSQEntrySCI(numericalValues, textualValues, sweepNo, channelNumber, channelType, PSQ_FMT_LBN_SET_PASS)
End

Function SFH_IsSweepQCPassed(WAVE numericalValues, WAVE textualValues, variable sweepNo, variable channelNumber, variable channelType)

	return SFH_GetIndepPSQEntry(numericalValues, textualValues, sweepNo, channelNumber, channelType, PSQ_FMT_LBN_SWEEP_PASS)
End

static Function SFH_GetIndepPSQEntrySCI(WAVE numericalValues, WAVE textualValues, variable sweepNo, variable channelNumber, variable channelType, string psqLNBEntry)

	variable type, waMode, headstage
	string key

	[type, waMode, headstage] = GetAnalysisFunctionType(numericalValues, textualValues, sweepNo, channelNumber, channelType)
	if(IsNaN(type))
		return NaN
	endif

	key = CreateAnaFuncLBNKey(type, psqLNBEntry, query = 1, waMode = waMode)
	return GetLastSettingIndepSCI(numericalValues, sweepNo, key, headstage, UNKNOWN_MODE, defValue = 0)
End

static Function SFH_GetIndepPSQEntry(WAVE numericalValues, WAVE textualValues, variable sweepNo, variable channelNumber, variable channelType, string psqLNBEntry)

	variable type, waMode, headstage, passed
	string key

	[type, waMode, headstage] = GetAnalysisFunctionType(numericalValues, textualValues, sweepNo, channelNumber, channelType)
	if(IsNaN(type))
		return NaN
	endif

	if(type == PSQ_RHEOBASE && !CmpStr(psqLNBEntry, PSQ_FMT_LBN_SWEEP_PASS))
		passed = SFH_IsSetQCPassed(numericalValues, textualValues, sweepNo, channelNumber, channelType)
		WAVE sweepsSCI = AFH_GetSweepsFromSameSCI(numericalValues, sweepNo, headstage)
		[WAVE passingSweeps, WAVE failingSweeps] = AFH_GetRheobaseSweepsSCISweepQCSplitted(numericalValues, sweepNo, headstage, sweepsSCI, passed)
		if(WaveExists(passingSweeps))
			FindValue/V=(sweepNo) passingSweeps
			return V_value >= 0
		endif

		return 0
	endif

	key = CreateAnaFuncLBNKey(type, psqLNBEntry, query = 1, waMode = waMode)
	return GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE, defValue = 0)
End

Function/S SFH_CreateLegendFromRanges(WAVE selectData, WAVE/WAVE ranges)

	variable i, prefixPerSelect
	string prefix    = ""
	string legendStr = ""

	if(!DimSize(ranges, ROWS))
		return ""
	endif

	if(DimSize(ranges, ROWS) == 1)
		prefix = "All sweeps "
	elseif(DimSize(ranges, ROWS) == DimSize(selectData, ROWS))
		prefixPerSelect = 1
	else
		SFH_ASSERT(0, "selectData != ranges row number")
	endif
	WAVE fullRange = SFH_GetFullRange()

	for(WAVE range : ranges)
		if(!WaveExists(range))
			continue
		endif
		if(prefixPerSelect)
			sprintf prefix, "%d %s%d ", selectData[i][%SWEEP], ChannelTypeToString(selectData[i][%CHANNELTYPE]), selectData[i][%CHANNELNUMBER]
			i += 1
		endif
		if(IsNumericWave(range))
			if(SFH_IsFullRange(range))
				sprintf legendStr, "%s\r%sfull range", legendStr, prefix
				continue
			endif
			sprintf legendStr, "%s\r%s%.3f - %.3f ms", legendStr, prefix, range[0], range[1]
		elseif(IsTextWave(range))
			sprintf legendStr, "%s\r%sepoch %s", legendStr, prefix, WaveText(range, row = 0)
		else
			SFH_ASSERT(0, "Unsupported range format")
		endif
	endfor
	legendStr = ReplaceString("\r", legendStr, "Ranges:\r", 1, 1)

	return legendStr
End

/// @brief Function returns the correct numerical and textual LNB and sweepDFR for a given sweepNumber
///
/// @param graph    name of graph window
/// @param sweepNo  sweep number
/// @param mapIndex if graph is a SweepBrowser then a non-NaN mapIndex into sweepMap, otherwise must be NaN
Function [WAVE numericalValues, WAVE textualValues, DFREF sweepDFR] SFH_GetLabNoteBooksAndDFForSweep(string graph, variable sweepNo, variable mapIndex)

	WAVE numericalValues = SFH_GetLabNoteBookForSweep(graph, sweepNo, mapIndex, LBN_NUMERICAL_VALUES)
	WAVE textualValues   = SFH_GetLabNoteBookForSweep(graph, sweepNo, mapIndex, LBN_TEXTUAL_VALUES)

	if(BSP_IsSweepBrowser(graph))
		ASSERT(!IsNaN(mapIndex), "Can not work with NaN as mapIndex")
		DFREF sweepBrowserDFR = SB_GetSweepBrowserFolder(graph)
		DFREF sweepDFR        = SB_GetSweepDataPathFromIndex(sweepBrowserDFR, mapIndex)

		return [numericalValues, textualValues, sweepDFR]
	endif

	ASSERT(IsNaN(mapIndex), "Window is DataBrowser, but got a mapIndex into a sweepMap")
	DFREF deviceDFR = DB_GetDeviceDF(graph)
	DFREF sweepDFR  = GetSingleSweepFolder(deviceDFR, sweepNo)

	return [numericalValues, textualValues, sweepDFR]
End

/// @brief Function returns the correct numerical and textual LNB for a given sweepNumber
///
/// @param graph           name of graph window
/// @param sweepNo         sweep number
/// @param logbookWaveType one of @ref LabnotebookWaveTypes
/// @param mapIndex        if graph is a SweepBrowser then a non-NaN mapIndex into sweepMap, otherwise must be NaN
Function/WAVE SFH_GetLabNoteBookForSweep(string graph, variable sweepNo, variable mapIndex, variable logbookWaveType)

	string device, datafolder

	if(BSP_IsSweepBrowser(graph))
		ASSERT(!IsNaN(mapIndex), "Can not work with NaN as mapIndex")

		WAVE/T sweepMap = SB_GetSweepMap(graph)

		datafolder = sweepMap[mapIndex][%DataFolder]
		device     = sweepMap[mapIndex][%Device]

		return SB_GetLogbookWave(graph, LBT_LABNOTEBOOK, logbookWaveType, dataFolder = dataFolder, device = device)
	endif

	ASSERT(IsNaN(mapIndex), "Window is DataBrowser, but got a mapIndex into a sweepMap")
	return BSP_GetLogbookWave(graph, LBT_LABNOTEBOOK, logbookWaveType, sweepNumber = sweepNo)
End
