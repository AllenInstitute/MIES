#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3
#pragma rtFunctionErrors = 1

#ifdef AUTOMATED_TESTING
#pragma ModuleName = MIES_MIESUTILS_ALGORITHM
#endif // AUTOMATED_TESTING

/// @file MIES_MiesUtilities_Algorithm.ipf
/// @brief This file holds MIES utility functions implementing various algorithms

/// @brief Calculate the average of a list of waves, wrapper for MIES_fWaveAverage().
///
/// For performance enhancements:
/// - The average waves are cached
/// - References to existing average waves are returned in case they already exist
///
/// @param waveRefs          waves to average in a wave reference wave
/// @param averageDataFolder folder where the data is to be stored
/// @param averageWaveName   base name of the averaged data
/// @param skipCRC           [optional, defaults to false] Add the average wave CRC as suffix to its name
/// @param writeSourcePaths  [optional, defaults to true] Write the full paths of the source waves into the average wave note
/// @param inputAverage      [optional, defaults to invalid wave ref] Override the average calculation and use the given
///                          wave as result. This is relevant for callers which want to leverage `MultiThread` statements
///                          together with `MIES_fWaveAverage`.
///
/// @return wave reference to the average wave
Function/WAVE CalculateAverage(WAVE/WAVE waveRefs, DFREF averageDataFolder, string averageWaveName, [variable skipCRC, variable writeSourcePaths, WAVE inputAverage])

	variable crc
	string key, wvName, dataUnit

	skipCRC          = ParamIsDefault(skipCRC) ? 0 : !!skipCRC
	writeSourcePaths = ParamIsDefault(writeSourcePaths) ? 0 : !!writeSourcePaths

	key = CA_AveragingKey(waveRefs)

	wvName = averageWaveName

	if(ParamIsDefault(inputAverage))

		WAVE/Z freeAverageWave = CA_TryFetchingEntryFromCache(key, options = CA_OPTS_NO_DUPLICATE)
		if(WaveExists(freeAverageWave)) // found in the cache

			if(!skipCRC)
				wvName += "_" + num2istr(GetNumberFromWaveNote(freeAverageWave, "DataCRC"))

				WAVE/Z/SDFR=averageDataFolder permAverageWave = $wvName
				if(WaveExists(permAverageWave))
					return permAverageWave
				endif
			endif

			Duplicate/O freeAverageWave, averageDataFolder:$wvName/WAVE=permAverageWave

			return permAverageWave
		endif

		WAVE/WAVE aveResult       = MIES_fWaveAverage(waveRefs, 1, IGOR_TYPE_64BIT_FLOAT)
		WAVE      freeAverageWave = aveResult[0]
		ASSERT(ClearRTError() == 0, "Unexpected RTE")
		ASSERT(WaveExists(freeAverageWave), "Wave averaging failed")
	else
		WAVE freeAverageWave = inputAverage
	endif

	dataUnit = WaveUnits(waveRefs[0], -1)
	SetScale d, 0, 0, dataUnit, freeAverageWave

	if(!skipCRC)
		crc     = WaveCRC(0, freeAverageWave)
		wvName += "_" + num2istr(crc)
		SetNumberInWaveNote(freeAverageWave, "DataCRC", crc)
	endif

	if(writeSourcePaths)
		AddEntryIntoWaveNoteAsList(freeAverageWave, "SourceWavesForAverage", str = ReplaceString(";", WaveRefWaveToList(waveRefs, 0), "|"))
	endif
	SetNumberInWaveNote(freeAverageWave, NOTE_KEY_WAVE_MAXIMUM, WaveMax(freeAverageWave), format = PERCENT_F_MAX_PREC)

	CA_StoreEntryIntoCache(key, freeAverageWave, options = CA_OPTS_NO_DUPLICATE)

	return ConvertFreeWaveToPermanent(freeAverageWave, averageDataFolder, wvName)
End

/// @brief Calculate deltaI/deltaV from a testpulse like stimset in "Current Clamp" mode
/// @todo unify with TP_Delta code
/// @todo add support for evaluating "inserted TP" only
/// \rst
/// See :ref:`CalculateTPLikePropsFromSweep_doc` for the full documentation.
/// \endrst
Function CalculateTPLikePropsFromSweep(WAVE numericalValues, WAVE textualValues, WAVE sweep, WAVE deltaI, WAVE deltaV, WAVE resistance)

	variable i
	variable DAcol, ADcol, level, low, high, baseline, elevated, firstEdge, secondEdge, sweepNo
	variable totalOnsetDelay, first, last, onsetDelayPoint
	string msg

	sweepNo = ExtractSweepNumber(NameofWave(sweep))
	WAVE config = GetConfigWave(sweep)

	totalOnsetDelay = GetTotalOnsetDelay(numericalValues, sweepNo)

	WAVE ADCs = GetLastSetting(numericalValues, sweepNo, "ADC", DATA_ACQUISITION_MODE)
	WAVE DACs = GetLastSetting(numericalValues, sweepNo, "DAC", DATA_ACQUISITION_MODE)

	WAVE/T ADunit = GetLastSetting(textualValues, sweepNo, "AD Unit", DATA_ACQUISITION_MODE)
	WAVE/T DAunit = GetLastSetting(textualValues, sweepNo, "DA Unit", DATA_ACQUISITION_MODE)

	WAVE statusHS = GetLastSetting(numericalValues, sweepNo, "Headstage Active", DATA_ACQUISITION_MODE)

	for(i = 0; i < NUM_HEADSTAGES; i += 1)

		if(!statusHS[i])
			continue
		endif

		DAcol = AFH_GetDAQDataColumn(config, DACs[i], XOP_CHANNEL_TYPE_DAC)
		ADcol = AFH_GetDAQDataColumn(config, ADCs[i], XOP_CHANNEL_TYPE_ADC)

		WAVE DA = ExtractOneDimDataFromSweep(config, sweep, DACol)
		WAVE AD = ExtractOneDimDataFromSweep(config, sweep, ADcol)

		onsetDelayPoint = (totalOnsetDelay - DimOffset(DA, ROWS)) / DimDelta(DA, ROWS)

		first = totalOnsetDelay
		last  = IndexToScale(DA, DimSize(DA, ROWS) - 1, ROWS)

		[low, high] = WaveMinAndMax(DA, first, last)

		level = low + 0.1 * (high - low)

		Make/FREE/D levels
		FindLevels/Q/P/DEST=levels/R=(first, last)/N=2 DA, level
		ASSERT(V_LevelsFound >= 2, "Could not find enough levels")

		firstEdge  = trunc(levels[0])
		secondEdge = trunc(levels[1])

		high = firstEdge - 1
		low  = high - (firstEdge - onsetDelayPoint) * 0.1

		baseline = mean(AD, IndexToScale(AD, low, ROWS), IndexToScale(AD, high, ROWS))

		sprintf msg, "(%d) AD: low = %g (%g ms), high = %g (%g ms), baseline %g", i, low, IndexToScale(AD, low, ROWS), high, IndexToScale(AD, high, ROWS), baseline
		DEBUGPRINT(msg)

		high = secondEdge - 1
		low  = high - (secondEdge - firstEdge) * 0.1

		elevated = mean(AD, IndexToScale(AD, low, ROWS), IndexToScale(AD, high, ROWS))

		sprintf msg, "(%d) AD: low = %g (%g ms), high = %g (%g ms), elevated %g", i, low, IndexToScale(AD, low, ROWS), high, IndexToScale(AD, high, ROWS), elevated
		DEBUGPRINT(msg)

		// convert from mv to V
		ASSERT(!cmpstr(ADunit[i], "mV"), "Unexpected AD Unit")

		deltaV[i] = (elevated - baseline) * MILLI_TO_ONE

		high = firstEdge - 1
		low  = high - (firstEdge - onsetDelayPoint) * 0.1

		baseline = mean(DA, IndexToScale(DA, low, ROWS), IndexToScale(DA, high, ROWS))

		sprintf msg, "(%d) DA: low = %g (%g ms), high = %g (%g ms), baseline %g", i, low, IndexToScale(DA, low, ROWS), high, IndexToScale(DA, high, ROWS), elevated
		DEBUGPRINT(msg)

		high = secondEdge - 1
		low  = high - (secondEdge - firstEdge) * 0.1

		elevated = mean(DA, IndexToScale(DA, low, ROWS), IndexToScale(DA, high, ROWS))

		sprintf msg, "(%d) DA: low = %g (%g ms), high = %g (%g ms), elevated %g", i, low, IndexToScale(DA, low, ROWS), high, IndexToScale(DA, high, ROWS), elevated
		DEBUGPRINT(msg)

		// convert from pA to A
		ASSERT(!cmpstr(DAunit[i], "pA"), "Unexpected DA Unit")
		deltaI[i] = (elevated - baseline) * PICO_TO_ONE

		resistance[i] = deltaV[i] / deltaI[i]

		sprintf msg, "(%d): R = %.0W1PΩ, ΔU = %.0W1PV, ΔI = %.0W1PA", i, resistance[i], deltaV[i], deltaI[i]
		DEBUGPRINT(msg)
	endfor
End

/// @brief Decimate the the given input wave
///
/// This allows to decimate a given input row range into output rows using the
/// given method. The columns of input/output can be different. The input row
/// coordinates can be used to do a chunked conversion, e.g. when receiving
/// data from hardware. Incomplete chunks will be redone when necessary.
///
/// Algorithm visualized:
///
/// \rst
/// .. code-block:: text
///
///    Input (16 entries): [ | | | | | | | | | | | | | | | ]
///    Decimation factor: 4
///    Method: MinMax
///    Output (4 entries): [ min(input[0, 7]) | max(input[0, 7]) | min(input[8, 15]) | max(input[8, 15]) ]
///
/// \endrst
///
/// @param input             wave to decimate
/// @param output            target wave which will be around `decimationFactor` smaller than input
/// @param decimationFactor  decimation factor, must be an integer and larger than 1
/// @param method            one of @ref DecimationMethods
/// @param firstRowInp       [optional, defaults to 0] first row *input* coordinates
/// @param lastRowInp        [optional, defaults to last element] last row in *input* coordinates
/// @param firstColInp       [optional, defaults to 0] first col in *input* coordinates
/// @param lastColInp        [optional, defaults to last element] last col in *input* coordinates
/// @param firstColOut       [optional, defaults to firstColInp] first col in *output* coordinates
/// @param lastColOut        [optional, defaults to lastColInp] last col in *output* coordinates
/// @param factor            [optional, defaults to none] factor which is applied to
///                          all input columns and written into the output columns
Function DecimateWithMethod(WAVE input, WAVE output, variable decimationFactor, variable method, [variable firstRowInp, variable lastRowInp, variable firstColInp, variable lastColInp, variable firstColOut, variable lastColOut, WAVE/Z factor])

	variable numRowsInp, numColsInp, numRowsOut, numColsOut, targetFirst, targetLast, numOutputPairs, usedColumns, usedRows
	variable numRowsDecimated, first, last
	string msg, key

	// BEGIN parameter checking

	numRowsInp = DimSize(input, ROWS)
	numColsInp = DimSize(input, COLS)

	numRowsOut = DimSize(output, ROWS)
	numColsOut = DimSize(output, COLS)

	if(ParamIsDefault(firstRowInp))
		firstRowInp = 0
	else
		ASSERT(firstRowInp >= 0 && firstRowInp < numRowsInp, "Invalid firstRowInp value")
	endif

	if(ParamIsDefault(lastRowInp))
		lastRowInp = numRowsInp - 1
	else
		ASSERT(lastRowInp >= 0 && lastRowInp < numRowsInp, "Invalid lastRowInp value")
	endif

	[firstRowInp, lastRowInp] = MinMax(firstRowInp, lastRowInp)

	usedRows = lastRowInp - firstRowInp + 1

	if(ParamIsDefault(firstColInp))
		firstColInp = 0
	else
		ASSERT(firstColInp >= 0 && (firstColInp < numColsInp || (firstColInp == 0 && numColsInp <= 1)), "Invalid firstColInp value")
	endif

	if(ParamIsDefault(lastColInp))
		lastColInp = max(numColsInp - 1, 0)
	else
		ASSERT(lastColInp >= 0 && (lastColInp < numColsInp || (lastColInp == 0 && numColsInp <= 1)), "Invalid lastColInp value")
	endif

	[firstColInp, lastColInp] = MinMax(firstColInp, lastColInp)

	usedColumns = lastColInp - firstColInp + 1

	if(ParamIsDefault(firstColOut))
		firstColOut = firstColInp
	else
		ASSERT(firstColOut >= 0 && (firstColOut < numColsOut || (firstColOut == 0 && numColsOut <= 1)), "Invalid firstColOut value")
	endif

	if(ParamIsDefault(lastColOut))
		lastColOut = lastColInp
	else
		ASSERT(lastColOut >= 0 && (lastColOut < numColsOut || (lastColOut == 0 && numColsOut <= 1)), "Invalid lastColOut value")
	endif

	[firstColOut, lastColOut] = MinMax(firstColOut, lastColOut)

	ASSERT(usedColumns == (lastColOut - firstColOut + 1), "Non-matching column ranges")

	if(!ParamIsDefault(factor))
		ASSERT(WaveExists(factor) && usedColumns == DimSize(factor, ROWS), "Invalid size of factor")
	endif

	// END parameter checking

	numRowsDecimated = GetDecimatedWaveSize(numRowsInp, decimationFactor, method)
	ASSERT(IsEven(numRowsDecimated), "numRowsDecimated must be even")
	numOutputPairs = numRowsDecimated / 2

	ASSERT(DimSize(output, ROWS) == numRowsDecimated, "Output wave has the wrong size.")

	// This wave is only used to run the multithread assignment. We don't care about the values.

	key = CA_TemporaryWaveKey({numOutputPairs, usedColumns})
	WAVE/Z/B junkWave = CA_TryFetchingEntryFromCache(key, options = CA_OPTS_NO_DUPLICATE)

	if(!WaveExists(junkWave))
		Make/N=(numOutputPairs, usedColumns)/FREE/B junkWave
		CA_StoreEntryIntoCache(key, junkWave, options = CA_OPTS_NO_DUPLICATE)
	endif

	targetFirst = floor(firstRowInp / (decimationFactor * 2))
	targetLast  = min(ceil(lastRowInp / (decimationFactor * 2)), numOutputPairs - 1)

	if(targetFirst > targetLast)
		return NaN
	endif

	sprintf msg, "method %d, decFactor %d, numOutputPairs %d\r", method, decimationFactor, numOutputPairs
	DEBUGPRINT(msg)
	sprintf msg, "input[%08d][%08d], output[%08d][%08d]; rows [%08d, %08d] -> pairs [%08d, %08d]; cols [%d, %d] [%d, %d]\r", numRowsInp, numColsInp, DimSize(output, ROWS), DimSize(output, COLS), firstRowInp, lastRowInp, targetFirst, targetLast, firstColInp, lastColInp, firstColOut, lastColOut
	DEBUGPRINT(msg)

	switch(method)
		case DECIMATION_MINMAX:
			Multithread junkWave[targetFirst, targetLast][] = DecimateMinMax(input, output, p, firstRowInp, lastRowInp, firstColInp + q, firstColOut + q, decimationFactor)
			break
		default:
			ASSERT(0, "Unsupported method")
			break
	endswitch

	if(WaveExists(factor))
		// same formulas as in DecimateMinMax
		first = targetFirst * 2
		last  = targetLast * 2 + 1

		Multithread output[first, last][firstColOut, lastColOut] *= factor[q - firstColOut]
	endif
End

/// @brief Threadsafe helper function for DecimateWithMethod
///
/// @param input            input wave
/// @param output           output wave
/// @param idx              output pair index
/// @param firstRowInp      first row in *input* coordinates
/// @param lastRowInp       last row in *input* coordinates
/// @param colInp           column in *input* coordinates
/// @param colOut           column in *output* coordinates
/// @param decimationFactor decimation factor
threadsafe static Function DecimateMinMax(WAVE input, WAVE output, variable idx, variable firstRowInp, variable lastRowInp, variable colInp, variable colOut, variable decimationFactor)

	variable first, last, targetFirst, targetLast

	first = idx * decimationFactor * 2
	last  = (idx + 1) * decimationFactor * 2 - 1

	if(first > lastRowInp)
		return NaN
	endif

	last = min(last, lastRowInp)

	targetFirst = idx * 2
	targetLast  = (idx * 2) + 1

	WaveStats/Q/M=1/RMD=[first, last][colInp] input
	ASSERT_TS(V_numINFS == 0, "INFs are not supported.")
	ASSERT_TS(V_numNaNS == 0, "NaNs are not supported.")
	ASSERT_TS((last - first + 1) == V_npnts && V_npnts > 0, "Range got clipped")

	// comment in for debugging
	// #ifdef DEBUGGING_ENABLED
	//   if(DP_DebuggingEnabledForCaller())
	// 		printf "[%d, %d] -> [%d, %d]; min %g; max %g;\r", first, last, targetFirst, targetLast, V_min, V_max
	//   endif
	// #endif // DEBUGGING_ENABLED

	output[targetFirst][colOut] = V_min
	output[targetLast][colOut]  = V_max
End

/// @brief Return the number of threads for `Multithread` given a problem with dimension `dims`
///
/// The algorithm was developed for "easy" problems on the RHS of MultiThread.
///
/// Example:
///
/// \rst
/// .. code-block:: igorpro
///
///    Make/FREE/N=(1025, 10) data
///    WAVE dims = GetWaveDimensions(data)
///    variable numThreads = GetNumberOfUsefulThreads(dims)
///    MultiThread/Y=(numThreads) data = ...
///
/// \endrst
threadsafe Function GetNumberOfUsefulThreads(WAVE dims)

	variable pointsPerThread, numCores, numPoints, numThreads, numRows, numCols, i

	ASSERT_TS(WaveExists(dims) && IsNumericWave(dims), "Needs a numeric wave")

	numRows = DimSize(dims, ROWS)
	ASSERT_TS(numRows <= MAX_DIMENSION_COUNT, "Expected at most MAX_DIMENSION_COUNT rows")

	numCols = DimSize(dims, COLS)
	ASSERT_TS(numCols <= 1, "Expected a 1D wave")

	pointsPerThread = 4096
	numCores        = TSDS_ReadVar(TSDS_PROCCOUNT)

	numPoints = 1
	for(i = 0; i < numRows; i += 1)
		numPoints *= max(1, dims[i])
	endfor

	numThreads = min(ceil(numPoints / pointsPerThread), numCores)

	ASSERT_TS(IsInteger(numThreads) && numThreads > 0, "Invalid thread count")

	return numThreads
End

/// @brief Extended version of `FindValue`
///
/// Allows to search only the specified column for a value
/// and returns all matching row indizes in a wave. By defaults only looks into the first layer
/// for backward compatibility reasons. When multiple layers are searched `startLayer`/`endLayer` the
/// result contains matches from all layers, and this also means the resulting wave is still 1D.
///
/// Exactly one of `var`/`str`/`prop` has to be given except for
/// `prop == PROP_MATCHES_VAR_BIT_MASK`
/// which requires a `var`/`str` parameter as well.
/// `prop == PROP_GREP` requires `str`.
/// `prop == PROP_WILDCARD` requires `str`.
/// `PROP_NOT` can be set by logical ORing it to one of the other PROP_* constants
/// `prop == PROP_NOT` can also be set solely to invert the matching of the default behavior
///
/// Exactly one of `col`/`colLabel` has to be given.
///
/// @param numericOrTextWave   wave to search in
/// @param col [optional, default=0] column to search in only
/// @param colLabel [optional] column label to search in only
/// @param var [optional]      numeric value to search
/// @param str [optional]      string value to search
/// @param prop [optional]     property to search, see @ref FindIndizesProps
/// @param startRow [optional] starting row to restrict the search to
/// @param endRow [optional]   ending row to restrict the search to
/// @param startLayer [optional, defaults to zero] starting layer to restrict search to
/// @param endLayer [optional, defaults to zero] ending layer to restrict search to
///
/// @returns A wave with the row indizes of the found values. An invalid wave reference if the
/// value could not be found.
threadsafe Function/WAVE FindIndizes(WAVE numericOrTextWave, [variable col, string colLabel, variable var, string str, variable prop, variable startRow, variable endRow, variable startLayer, variable endLayer])

	variable numCols, numRows, numLayers, maskedProp, numThreads, numRowsEffective, numLayersEffective
	string key

	ASSERT_TS((ParamIsDefault(prop) && (ParamIsDefault(var) + ParamIsDefault(str)) == 1)                  \
	          || ((prop & PROP_EMPTY) && (ParamIsDefault(var) + ParamIsDefault(str)) == 2)                \
	          || ((prop & PROP_NOT) && (ParamIsDefault(var) + ParamIsDefault(str)) == 1)                  \
	          || ((prop & PROP_MATCHES_VAR_BIT_MASK) && (ParamIsDefault(var) + ParamIsDefault(str)) == 1) \
	          || ((prop & PROP_GREP) && !ParamIsDefault(str) && ParamIsDefault(var))                      \
	          || ((prop & PROP_WILDCARD) && !ParamIsDefault(str) && ParamIsDefault(var)),                 \
	          "Invalid combination of var/str/prop arguments")

	ASSERT_TS(WaveExists(numericOrTextWave), "numericOrTextWave does not exist")

	if(DimSize(numericOrTextWave, ROWS) == 0)
		return $""
	endif

	numRows   = DimSize(numericOrTextWave, ROWS)
	numCols   = DimSize(numericOrTextWave, COLS)
	numLayers = DimSize(numericOrTextWave, LAYERS)
	ASSERT_TS(DimSize(numericOrTextWave, CHUNKS) <= 1, "No support for chunks")

	ASSERT_TS((!ParamIsDefault(col) + !ParamIsDefault(colLabel)) < 2, "Ambiguous input. Col and ColLabel is set.")
	if(!ParamIsDefault(col))
		// do nothing
	elseif(!ParamIsDefault(colLabel))
		col = FindDimLabel(numericOrTextWave, COLS, colLabel)
		ASSERT_TS(col >= 0, "invalid column label")
	else
		col = 0
	endif

	ASSERT_TS(col == 0 || (col > 0 && col < numCols), "Invalid column")

	if(IsTextWave(numericOrTextWave))
		WAVE/T wvText = numericOrTextWave
		WAVE/Z wv     = $""
	else
		WAVE/Z/T wvText = $""
		WAVE     wv     = numericOrTextWave
	endif

	if(!ParamIsDefault(prop))
		maskedProp = prop & (PROP_NOT %^ -1)
		if(maskedProp)
			ASSERT_TS(maskedProp == PROP_EMPTY                   \
			          || maskedProp == PROP_MATCHES_VAR_BIT_MASK \
			          || maskedProp == PROP_GREP                 \
			          || maskedProp == PROP_WILDCARD,            \
			          "Invalid property")

			if(prop & PROP_MATCHES_VAR_BIT_MASK)
				if(ParamIsDefault(var))
					var = str2numSafe(str)
				elseif(ParamIsDefault(str))
					str = num2str(var)
				endif
			elseif(prop & PROP_GREP)
				ASSERT_TS(IsValidRegexp(str), "Invalid regular expression")
			endif
		endif
	elseif(!ParamIsDefault(var))
		str = num2str(var)
	elseif(!ParamIsDefault(str))
		var = str2numSafe(str)
	endif

	if(ParamIsDefault(startRow))
		startRow = 0
	else
		ASSERT_TS(startRow >= 0 && startRow < numRows, "Invalid startRow")
	endif

	if(ParamIsDefault(endRow))
		endRow = numRows - 1
	else
		ASSERT_TS(endRow >= 0 && endRow < numRows, "Invalid endRow")
	endif

	ASSERT_TS(startRow <= endRow, "endRow must be larger than startRow")
	numRowsEffective = (endRow - startRow) + 1

	if(ParamIsDefault(startLayer))
		startLayer = 0
	else
		ASSERT_TS(startLayer >= 0 && (numLayers == 0 || startLayer < numLayers), "Invalid startLayer")
	endif

	if(ParamIsDefault(endLayer))
		// only look in the first layer by default
		endLayer = 0
	else
		ASSERT_TS(endLayer >= 0 && (numLayers == 0 || endLayer < numLayers), "Invalid endLayer")
	endif

	ASSERT_TS(startLayer <= endLayer, "endLayer must be larger than startLayer")
	numLayersEffective = (endLayer - startLayer) + 1

	// Algorithm:
	// * The matches wave has the same size as one column of the input wave
	// * -1 means no match, every value larger or equal than zero is the row index of the match
	// * There is no distinction between different layers matching
	// * After the matches have been calculated we take the maximum of the transposed matches
	//   wave in each colum transpose back and replace -1 with NaN. This multiple layer matching algorithm
	//   using maxCols is also the reason why we can't start with NaN on no match but have to use -1
	// * This gives a 1D wave with NaN in the rows with no match, and the row index of the match otherwise
	// * Delete all NaNs in the wave and return it

	key = CA_FindIndizesKey({numRows, numLayers})
	WAVE/Z/D matches = CA_TryFetchingEntryFromCache(key, options = CA_OPTS_NO_DUPLICATE)

	if(!WaveExists(matches))
		Make/N=(numRows, numLayers)/FREE/D matches
		CA_StoreEntryIntoCache(key, matches, options = CA_OPTS_NO_DUPLICATE)
	endif

	numThreads = GetNumberOfUsefulThreads({numRowsEffective, numLayersEffective})

	FastOp matches = -1

	if(WaveExists(wv))
		if(!ParamIsDefault(prop))
			if(prop & PROP_EMPTY)
				if(prop & PROP_NOT)
					MultiThread/NT=(numThreads) matches[startRow, endRow][startLayer, endLayer] = (numtype(wv[p][col][q]) != 2) ? p : -1
				else
					MultiThread/NT=(numThreads) matches[startRow, endRow][startLayer, endLayer] = (numtype(wv[p][col][q]) == 2) ? p : -1
				endif
			elseif(prop & PROP_MATCHES_VAR_BIT_MASK)
				if(prop & PROP_NOT)
					MultiThread/NT=(numThreads) matches[startRow, endRow][startLayer, endLayer] = !(wv[p][col][q] & var) ? p : -1
				else
					MultiThread/NT=(numThreads) matches[startRow, endRow][startLayer, endLayer] = (wv[p][col][q] & var) ? p : -1
				endif
			elseif(prop & PROP_GREP)
				if(prop & PROP_NOT)
					MultiThread/NT=(numThreads) matches[startRow, endRow][startLayer, endLayer] = !GrepString(num2strHighPrec(wv[p][col][q]), str) ? p : -1
				else
					MultiThread/NT=(numThreads) matches[startRow, endRow][startLayer, endLayer] = GrepString(num2strHighPrec(wv[p][col][q]), str) ? p : -1
				endif
			elseif(prop & PROP_WILDCARD)
				if(prop & PROP_NOT)
					MultiThread/NT=(numThreads) matches[startRow, endRow][startLayer, endLayer] = !StringMatch(num2strHighPrec(wv[p][col][q]), str) ? p : -1
				else
					MultiThread/NT=(numThreads) matches[startRow, endRow][startLayer, endLayer] = StringMatch(num2strHighPrec(wv[p][col][q]), str) ? p : -1
				endif
			elseif(prop & PROP_NOT)
				MultiThread/NT=(numThreads) matches[startRow, endRow][startLayer, endLayer] = (wv[p][col][q] != var) ? p : -1
			endif
		else
			ASSERT_TS(!IsNaN(var), "Use PROP_EMPTY to search for NaN")
			MultiThread/NT=(numThreads) matches[startRow, endRow][startLayer, endLayer] = (wv[p][col][q] == var) ? p : -1
		endif
	else
		if(!ParamIsDefault(prop))
			if(prop & PROP_EMPTY)
				if(prop & PROP_NOT)
					MultiThread/NT=(numThreads) matches[startRow, endRow][startLayer, endLayer] = strlen(wvText[p][col][q]) ? p : -1
				else
					MultiThread/NT=(numThreads) matches[startRow, endRow][startLayer, endLayer] = !strlen(wvText[p][col][q]) ? p : -1
				endif
			elseif(prop & PROP_MATCHES_VAR_BIT_MASK)
				if(prop & PROP_NOT)
					MultiThread/NT=(numThreads) matches[startRow, endRow][startLayer, endLayer] = !(str2num(wvText[p][col][q]) & var) ? p : -1
				else
					MultiThread/NT=(numThreads) matches[startRow, endRow][startLayer, endLayer] = (str2num(wvText[p][col][q]) & var) ? p : -1
				endif
			elseif(prop & PROP_GREP)
				if(prop & PROP_NOT)
					MultiThread/NT=(numThreads) matches[startRow, endRow][startLayer, endLayer] = !GrepString(wvText[p][col][q], str) ? p : -1
				else
					MultiThread/NT=(numThreads) matches[startRow, endRow][startLayer, endLayer] = GrepString(wvText[p][col][q], str) ? p : -1
				endif
			elseif(prop & PROP_WILDCARD)
				if(prop & PROP_NOT)
					MultiThread/NT=(numThreads) matches[startRow, endRow][startLayer, endLayer] = !StringMatch(wvText[p][col][q], str) ? p : -1
				else
					MultiThread/NT=(numThreads) matches[startRow, endRow][startLayer, endLayer] = StringMatch(wvText[p][col][q], str) ? p : -1
				endif
			elseif(prop & PROP_NOT)
				MultiThread/NT=(numThreads) matches[startRow, endRow][startLayer, endLayer] = CmpStr(wvText[p][col][q], str) ? p : -1
			endif
		else
			MultiThread/NT=(numThreads) matches[startRow, endRow][startLayer, endLayer] = !CmpStr(wvText[p][col][q], str) ? p : -1
		endif
	endif

	MatrixOp/FREE result = zapNans(replace(maxCols(subRange(matches, startRow, endRow, startLayer, endLayer)^t)^t, -1, NaN))

	if(DimSize(result, ROWS) == 0)
		return $""
	endif

	return result
End

/// @brief Band‑pass filters a wave while automatically reducing IIR filter
/// order until the output contains no NaNs/Infs and its SEM is not larger than
/// the original (simple ringing detection).
///
/// @param src      – input wave
/// @param fHigh    – pass‑band edge frequencies in Hz (Igor’s band‑pass requires fLow > fHigh; the routine swaps them if needed)
/// @param fLow     – low part
/// @param maxOrder – starting (maximum) IIR filter order to try (>0)
///
///  Logic: iteratively lowers the filter order until three conditions are met:
///           1. FilterIIR executes without error.
///           2. WaveStats reports       V_numNaNs = 0 and V_numInfs = 0.
///           3. SEM(filtered) ≤ SEM(original).
///
/// @retval curOrder filter order that finally succeeded (0 if every order failed)
/// @retval filtered filtered data
Function [variable curOrder, WAVE filtered] BandPassWithRingingDetection(WAVE src, variable fHigh, variable fLow, variable maxOrder)

	variable err, samp, semOrig, offset

	ASSERT(maxOrder > 0, "maxOrder must be positive")
	// Igor band‑pass expects fLow > fHigh
	[fHigh, fLow] = MinMax(fLow, fHigh)

	// Sampling rate (Hz) – assumes X scaling is in milliseconds
	samp = 1 / (DeltaX(src) * MILLI_TO_ONE)

	// Pre-compute SEM(original) once
	WaveStats/Q src
	semOrig = V_sem
	offset  = v_avg

	// Prepare destination wave
	duplicate/FREE src, filtered

	curOrder = maxOrder
	do
		// -------- copy fresh data into filtered ------------------------------
		filtered = src - offset

		// -------- attempt current order --------------------------------------
		FilterIIR/LO=(fLow / samp)/HI=(fHigh / samp)/DIM=(ROWS)/ORD=(curOrder) filtered
		err = GetRTError(1)
		if(err)
			Print "FilterIIR failed (order=" + num2str(curOrder) + "): " + GetErrMessage(err)
			curOrder -= 1
			continue
		endif

		// -------- WaveStats: NaN/Inf + SEM in one call ------------------------
		WaveStats/Q filtered
		if(V_numNaNs > 0 || V_numInfs > 0)
			curOrder -= 1
			continue // bad numerical output → lower order
		endif

		if(V_sem > semOrig) // noisier than original → ringing
			curOrder -= 1
			continue
		endif

		// -------- success -----------------------------------------------------

		break
	while(curOrder > 0)

	if(curOrder <= 0)
		Print "bandpass_with_RingingDetection(): all orders down to 1 produced NaNs/Infs or increased SEM."
	endif

	// add offset back to filtered wave
	filtered += offset

	return [curOrder, filtered]
End
