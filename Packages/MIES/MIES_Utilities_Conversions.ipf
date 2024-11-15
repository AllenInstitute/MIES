#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_UTILS_CONVERSIONS
#endif

/// @file MIES_Utilities_Conversions.ipf
/// @brief Utility functions for conversions

/// @brief Convert Bytes to MiBs, a mebibyte being 2^20.
Function ConvertFromBytesToMiB(variable var)

	return var / 1024 / 1024
End

/// @brief Convert the sampling interval in microseconds (1e-6s) to the rate in kHz
threadsafe Function ConvertSamplingIntervalToRate(variable val)

	return 1 / (val * MICRO_TO_ONE) * ONE_TO_KILO
End

/// @brief Convert the rate in kHz to the sampling interval in microseconds (1e-6s)
threadsafe Function ConvertRateToSamplingInterval(variable val)

	return 1 / (val * KILO_TO_ONE) * ONE_TO_MICRO
End

/// @brief Convert a text wave to string list
///
/// @param txtWave     input text wave
/// @param rowSep      separator for row entries
/// @param colSep      [optional, default = ","] separator for column entries
/// @param layerSep    [optional, default = ":"] separator for layer entries
/// @param chunkSep    [optional, default = "/"] separator for chunk entries
/// @param stopOnEmpty [optional, default = 0] when 1 stops generating the list when an empty string entry in txtWave is encountered
/// @param maxElements [optional, defaults to inf] output only the first `maxElements` entries
/// @param trailSep    [optional, defaults to true] add trailing separators at the very end
///
/// @return string with wave entries separated as list using given separators
///
/// Counterpart @see ConvertListToTextWave
/// @see NumericWaveToList
threadsafe Function/S TextWaveToList(WAVE/Z/T txtWave, string rowSep, [string colSep, string layerSep, string chunkSep, variable stopOnEmpty, variable maxElements, variable trailSep])

	string entry, seps
	string list = ""
	variable i, j, k, l, lasti, lastj, lastk, lastl, numRows, numCols, numLayers, numChunks, count, done
	variable numColsLoop, numLayersLoop, numChunksLoop

	if(!WaveExists(txtWave))
		return ""
	endif

	ASSERT_TS(IsTextWave(txtWave), "Expected a text wave")
	ASSERT_TS(!IsEmpty(rowSep), "Expected a non-empty row list separator")

	if(ParamIsDefault(colSep))
		colSep = ","
	else
		ASSERT_TS(!IsEmpty(colSep), "Expected a non-empty column list separator")
	endif

	if(ParamIsDefault(layerSep))
		layerSep = ":"
	else
		ASSERT_TS(!IsEmpty(layerSep), "Expected a non-empty layer list separator")
	endif

	if(ParamIsDefault(chunkSep))
		chunkSep = "/"
	else
		ASSERT_TS(!IsEmpty(chunkSep), "Expected a non-empty chunk list separator")
	endif

	if(ParamIsDefault(maxElements))
		maxElements = Inf
	else
		ASSERT_TS((IsInteger(maxElements) && maxElements >= 0) || maxElements == Inf, "maxElements must be >=0 and an integer")
	endif

	if(ParamIsDefault(trailSep))
		trailSep = 1
	else
		trailSep = !!trailSep
	endif

	stopOnEmpty = ParamIsDefault(stopOnEmpty) ? 0 : !!stopOnEmpty

	numRows = DimSize(txtWave, ROWS)
	if(numRows == 0)
		return list
	endif
	numCols   = DimSize(txtWave, COLS)
	numLayers = DimSize(txtWave, LAYERS)
	numChunks = DimSize(txtWave, CHUNKS)

	if(!stopOnEmpty && maxElements == Inf && !numLayers && !numChunks)
		return WaveToListFast(txtWave, "%s", rowSep, colSep, trailSep)
	endif

	numColsLoop   = max(1, numCols)
	numLayersLoop = max(1, numLayers)
	numChunksLoop = max(1, numChunks)

	for(i = 0; i < numRows; i += 1)
		for(j = 0; j < numColsLoop; j += 1)
			for(k = 0; k < numLayersLoop; k += 1)
				for(l = 0; l < numChunksLoop; l += 1)
					entry = txtWave[i][j][k][l]

					if(stopOnEmpty && IsEmpty(entry))
						done = 1
					elseif(count >= maxElements)
						done = 1
					endif

					if(done)
						break
					endif

					seps = ""

					if(lastl != l)
						lastl = l
						seps += chunkSep
					endif

					if(lastk != k)
						lastk = k
						seps += layerSep
					endif

					if(lastj != j)
						lastj = j
						seps += colSep
					endif

					if(lasti != i)
						lasti = i
						seps += rowSep
					endif

					list  += seps + entry
					count += 1
				endfor

				if(done)
					break
				endif
			endfor

			if(done)
				break
			endif
		endfor

		if(done)
			break
		endif
	endfor

	if(IsEmpty(list))
		return list
	endif

	if(trailSep)

		if(numChunks)
			list += chunkSep
		endif

		if(numLayers)
			list += layerSep
		endif

		if(numCols)
			list += colSep
		endif

		list += rowSep
	endif

	return list
End

/// @brief Converts a list to a multi dimensional text wave, treating it row major order
/// The output wave does not contain unused dimensions, so if dims = 4 is specified but no
/// chunk separator is found then the returned wave is 3 dimensional.
/// An empty list results in a zero dimensional wave.
///
/// @param[in] list   input string with list
/// @param[in] dims   number of dimensions the output text wave should have
/// @param[in] rowSep [optional, default = ";"] row separator
/// @param[in] colSep [optional, default = ","] column separator
/// @param[in] laySep [optional, default = ":"] layer separator
/// @param[in] chuSep [optional, default = "/"] chunk separator
/// @return text wave with at least dims dimensions
///
/// The following call
/// ListToTextWaveMD("1/5/6/:8/:,;2/:,;3/7/:,;4/:,;", 4, rowSep=";", colSep=",",laySep=":", chuSep="/")
/// returns
/// '_free_'[0][0][0][0]= {"1","2","3","4"}
/// '_free_'[0][0][1][0]= {"8","","",""}
/// '_free_'[0][0][0][1]= {"5","","7",""}
/// '_free_'[0][0][1][1]= {"","","",""}
/// '_free_'[0][0][0][2]= {"6","","",""}
/// '_free_'[0][0][1][2]= {"","","",""}
threadsafe Function/WAVE ListToTextWaveMD(string list, variable dims, [string rowSep, string colSep, string laySep, string chuSep])

	variable colSize, laySize, chuSize
	variable rowMaxSize, colMaxSize, layMaxSize, chuMaxSize
	variable rowNr, colNr, layNr

	ASSERT_TS(!isNull(list), "list input string is null")
	ASSERT_TS(dims > 0 && dims <= 4, "number of dimensions must be > 0 and < 5")

	if(ParamIsDefault(rowSep))
		rowSep = ";"
	endif
	if(ParamIsDefault(colSep))
		colSep = ","
	endif
	if(ParamIsDefault(laySep))
		laySep = ":"
	endif
	if(ParamIsDefault(chuSep))
		chuSep = "/"
	endif

	if(dims == 1)
		return ListToTextWave(list, rowSep)
	endif

	WAVE/T rowEntries = ListToTextWave(list, rowSep)
	rowMaxSize = DimSize(rowEntries, ROWS)
	if(!rowMaxSize)
		Make/FREE/T/N=0 emptyList
		return emptyList
	endif

	Make/FREE/N=(rowMaxSize) colSizes
	colSizes[] = ItemsInList(rowEntries[p], colSep)
	colMaxSize = WaveMax(colSizes)

	if(dims == 2)
		Make/T/FREE/N=(rowMaxSize, colMaxSize) output
		for(rowNr = 0; rowNr < rowMaxSize; rowNr += 1)
			WAVE/T colEntries = ListToTextWave(rowEntries[rowNr], colSep)
			output[rowNr][0, DimSize(colEntries, ROWS) - 1] = colEntries[q]
		endfor
		return output
	endif

	for(rowNr = 0; rowNr < rowMaxSize; rowNr += 1)
		WAVE/T colEntries = ListToTextWave(rowEntries[rowNr], colSep)
		colSize = DimSize(colEntries, ROWS)
		for(colNr = 0; colNr < colSize; colNr += 1)
			layMaxSize = Max(layMaxSize, ItemsInList(colEntries[colNr], laySep))

			if(dims == 4)
				WAVE/T layEntries = ListToTextWave(colEntries[colNr], laySep)
				laySize = DimSize(layEntries, ROWS)
				for(layNr = 0; layNr < laySize; layNr += 1)
					chuMaxSize = Max(chuMaxSize, ItemsInList(layEntries[layNr], chuSep))
				endfor
			endif

		endfor
	endfor

	if(dims == 3)
		Make/T/FREE/N=(rowMaxSize, colMaxSize, layMaxSize) output
		for(rowNr = 0; rowNr < rowMaxSize; rowNr += 1)
			WAVE/T colEntries = ListToTextWave(rowEntries[rowNr], colSep)
			colSize = DimSize(colEntries, ROWS)
			for(colNr = 0; colNr < colSize; colNr += 1)
				WAVE/T layEntries = ListToTextWave(colEntries[colNr], laySep)
				output[rowNr][colNr][0, DimSize(layEntries, ROWS) - 1] = layEntries[r]
			endfor
		endfor
		return output
	endif

	Make/T/FREE/N=(rowMaxSize, colMaxSize, layMaxSize, chuMaxSize) output
	for(rowNr = 0; rowNr < rowMaxSize; rowNr += 1)
		WAVE/T colEntries = ListToTextWave(rowEntries[rowNr], colSep)
		colSize = DimSize(colEntries, ROWS)
		for(colNr = 0; colNr < colSize; colNr += 1)
			WAVE/T layEntries = ListToTextWave(colEntries[colNr], laySep)
			laySize = DimSize(layEntries, ROWS)
			for(layNr = 0; layNr < laySize; layNr += 1)
				WAVE/T chuEntries = ListToTextWave(layEntries[layNr], chuSep)
				output[rowNr][colNr][layNr][0, DimSize(chuEntries, ROWS) - 1] = chuEntries[s]
			endfor
		endfor
	endfor
	return output
End

/// @brief Convert a 1D or 2D numeric wave to string list
///
/// Counterpart @see ListToNumericWave
/// @see TextWaveToList
///
/// @param wv           numeric wave
/// @param sep          separator
/// @param colSep       [optional, default = `,`] separator for column entries
/// @param format       [optional, defaults to `%g`] sprintf conversion specifier
/// @param trailSep [optional, defaults to false] don't add a row separator after the last row
threadsafe Function/S NumericWaveToList(WAVE/Z wv, string sep, [string format, string colSep, variable trailSep])

	if(!WaveExists(wv))
		return ""
	endif

	if(ParamIsDefault(trailSep))
		trailSep = 1
	else
		trailSep = !!trailSep
	endif

	ASSERT_TS(IsNumericWave(wv), "Expected a numeric wave")
	ASSERT_TS(DimSize(wv, LAYERS) <= 1, "Unexpected layer count")
	ASSERT_TS(DimSize(wv, CHUNKS) <= 1, "Unexpected chunk count")
	if(!DimSize(wv, ROWS))
		return ""
	endif

	if(ParamIsDefault(format))
		format = "%g"
	endif

	ASSERT_TS(!IsEmpty(sep), "Expected a non-empty row list separator")
	if(ParamIsDefault(colSep))
		colSep = ","
	else
		ASSERT_TS(!IsEmpty(colSep), "Expected a non-empty column list separator")
	endif

	return WaveToListFast(wv, format, sep, colSep, trailSep)
End

threadsafe static Function/S WaveToListFast(WAVE wv, string format, string sep, string colSep, variable trailSep)

	string list

	if(DimSize(wv, COLS) > 0)
		format = ReplicateString(format + colSep, DimSize(wv, COLS)) + sep
	else
		format += sep
	endif

	wfprintf list, format, wv

	if(!trailSep)
		return RemoveEnding(RemoveEnding(list, sep), colSep)
	endif

	return list
End

/// @brief Convert a list to a numeric wave
///
/// Counterpart @see NumericWaveToList().
/// @see TextWaveToList
///
/// @param list      list with numeric entries
/// @param sep       separator
/// @param type      [optional, defaults to double precision float (`IGOR_TYPE_64BIT_FLOAT`)] type of the created numeric wave
/// @param ignoreErr [optional, defaults 0] when this flag is set conversion errors are ignored, the value placed is NaN (-9223372036854775808 for int type)
threadsafe Function/WAVE ListToNumericWave(string list, string sep, [variable type, variable ignoreErr])

	if(ParamIsDefault(type))
		type = IGOR_TYPE_64BIT_FLOAT
	endif
	ignoreErr = ParamIsDefault(ignoreErr) ? 0 : !!ignoreErr

	Make/FREE/Y=(type)/N=(ItemsInList(list, sep)) wv
	if(ignoreErr)
		MultiThread wv = str2numSafe(StringFromList(p, list, sep))
	else
		MultiThread wv = str2num(StringFromList(p, list, sep))
	endif

	return wv
End

/// @brief str2num variant with no runtime error on invalid conversions
///
/// UTF_NOINSTRUMENTATION
threadsafe Function str2numSafe(string str)

	variable var, err

	AssertOnAndClearRTError()
	var = str2num(str); err = GetRTError(1) // see developer docu section Preventing Debugger Popup

	return var
End

/// @brief Return a floating point value as string rounded
///        to the given number of minimum significant digits
///
/// This allows to specify the minimum number of significant digits.
/// The normal printf/sprintf specifier only allows the maximum number of significant digits for `%g`.
Function/S FloatWithMinSigDigits(variable var, [variable numMinSignDigits])

	variable numMag

	if(ParamIsDefault(numMinSignDigits))
		numMinSignDigits = 6
	else
		ASSERT(numMinSignDigits >= 0 && Isfinite(numMinSignDigits), "Invalid numDecimalDigits")
	endif

	numMag = ceil(log(abs(var)))

	string str
	sprintf str, "%.*g", max(numMag, numMinSignDigits), var

	return str
End

// @brief Convert a number to the strings `Passed` (!= 0) or `Failed` (0).
Function/S ToPassFail(variable passedOrFailed)

	return SelectString(passedOrFailed, "failed", "passed")
End

// @brief Convert a number to the strings `True` (!= 0) or `False` (0).
Function/S ToTrueFalse(variable var)

	return SelectString(var, "False", "True")
End

// @brief Convert a number to the strings `On` (!= 0) or `Off` (0).
Function/S ToOnOff(variable var)

	return SelectString(var, "Off", "On")
End

/// @brief Convert the DAQ run mode to a string
///
/// @param runMode One of @ref DAQRunModes
threadsafe Function/S DAQRunModeToString(variable runMode)

	switch(runMode)
		case DAQ_NOT_RUNNING:
			return "DAQ_NOT_RUNNING"
			break
		case DAQ_BG_SINGLE_DEVICE:
			return "DAQ_BG_SINGLE_DEVICE"
			break
		case DAQ_BG_MULTI_DEVICE:
			return "DAQ_BG_MULTI_DEVICE"
			break
		case DAQ_FG_SINGLE_DEVICE:
			return "DAQ_FG_SINGLE_DEVICE"
			break
		default:
			ASSERT_TS(0, "Unknown run mode")
			break
	endswitch
End

/// @brief Convert the Testpulse run mode to a string
///
/// @param runMode One of @ref TestPulseRunModes
threadsafe Function/S TestPulseRunModeToString(variable runMode)

	runMode = ClearBit(runMode, TEST_PULSE_DURING_RA_MOD)

	switch(runMode)
		case TEST_PULSE_NOT_RUNNING:
			return "TEST_PULSE_NOT_RUNNING"
			break
		case TEST_PULSE_BG_SINGLE_DEVICE:
			return "TEST_PULSE_BG_SINGLE_DEVICE"
			break
		case TEST_PULSE_BG_MULTI_DEVICE:
			return "TEST_PULSE_BG_MULTI_DEVICE"
			break
		case TEST_PULSE_FG_SINGLE_DEVICE:
			return "TEST_PULSE_FG_SINGLE_DEVICE"
			break
		default:
			ASSERT_TS(0, "Unknown run mode")
			break
	endswitch
End

/// @brief Converts a number to a string with specified precision (digits after decimal dot).
/// This function is an extension for the regular num2str that is limited to 5 digits.
/// Input numbers are rounded using the "round-half-to-even" rule to the given precision.
/// The default precision is 5.
/// If val is complex only the real part is converted to a string.
///
/// @param[in] val       number that should be converted to a string
/// @param[in] precision [optional, default 5] number of precision digits after the decimal dot using "round-half-to-even" rounding rule.
///                      Precision must be in the range 0 to #MAX_DOUBLE_PRECISION.
/// @param[in] shorten   [optional, defaults to false] Remove trailing zeros and optionally the decimal dot to get a minimum length string
///
/// @return string with textual number representation
threadsafe Function/S num2strHighPrec(variable val, [variable precision, variable shorten])

	string str

	precision = ParamIsDefault(precision) ? 5 : precision
	shorten   = ParamIsDefault(shorten) ? 0 : !!shorten
	ASSERT_TS(precision >= 0 && precision <= MAX_DOUBLE_PRECISION, "Invalid precision, must be >= 0 and <= MAX_DOUBLE_PRECISION")

	sprintf str, "%.*f", precision, val

	if(!shorten)
		return str
	endif

	return RemoveEndingRegExp(str, "\.?0+")
End

/// @brief wrapper to `ScaleToIndex`
///
/// `ScaleToIndex` treats input `inf` to @p scale always as the last point in a
/// wave. `-inf` on the other hand is undefined. This wrapper function respects
/// the scaled point wave. `-inf` refers to the negative end of the scaled wave
/// and `+inf` is the positive end of the scaled wave.  This means that this
/// wrapper function also respects the `DimDelta` direction of the wave scaling.
/// and always returns the closest matching (existing) point in the wave. This
/// also means that the returned values cannot be negative or larger than the
/// numer of points in the wave.
///
/// @returns an existing index in @p wv between 0 and `DimSize(wv, dim) - 1`
Function ScaleToIndexWrapper(WAVE wv, variable scale, variable dim)

	variable index

	ASSERT(dim >= 0 && dim < 4, "Dimension out of range")
	ASSERT(trunc(dim) == dim, "invalid format for dimension")

	if(IsFinite(scale))
		index = ScaleToIndex(wv, scale, dim)
	else
		index = sign(scale) * sign(DimDelta(wv, dim)) * Inf
	endif

	if(dim >= WaveDims(wv))
		return 0
	endif

	return min(DimSize(wv, dim) - 1, max(0, trunc(index)))
End

/// @brief Convert a hexadecimal character into a number
///
/// UTF_NOINSTRUMENTATION
threadsafe Function HexToNumber(string ch)

	variable var

	ASSERT_TS(strlen(ch) <= 2, "Expected only up to two characters")

	sscanf ch, "%x", var
	ASSERT_TS(V_flag == 1, "Unexpected string")

	return var
End

/// @brief Convert a number into hexadecimal
///
/// UTF_NOINSTRUMENTATION
threadsafe Function/S NumberToHex(variable var)

	string str

	ASSERT_TS(IsInteger(var) && var >= 0 && var < 256, "Invalid input")

	sprintf str, "%02x", var

	return str
End

/// @brief Convert a string in hex format to an unsigned binary wave
///
/// This function works on a byte level so it does not care about endianess.
///
/// UTF_NOINSTRUMENTATION
threadsafe Function/WAVE HexToBinary(string str)

	variable length

	length = strlen(str)
	ASSERT_TS(mod(length, 2) == 0, "Expected a string with a power of 2 length")

	Make/N=(length / 2)/FREE/B/U bin = HexToNumber(str[p * 2]) | (HexToNumber(str[p * 2 + 1]) << 4)

	return bin
End

/// @brief Turn a list of entries into a regular expression with alternations.
///
/// Can be used for GetListOfObjects() if you know in advance which entries to filter out.
///
/// @param list    semicolon separated list of strings to match
/// @param literal [optional, default = 1] when this flag is cleared the string elements of the list are treated as regular expressions
/// @param sep     [optional, default = ";"] separator for list
Function/S ConvertListToRegexpWithAlternations(string list, [variable literal, string sep])

	variable i, numEntries
	string regexpList    = ""
	string literalPrefix = "\\Q"
	string literalSuffix = "\\E"

	literal = ParamIsDefault(literal) ? 1 : !!literal
	if(ParamIsDefault(sep))
		sep = ";"
	else
		ASSERT(!IsEmpty(sep), "separator can not be empty.")
	endif

	if(!literal)
		literalPrefix = ""
		literalSuffix = ""
	endif
	numEntries = ItemsInList(list, sep)
	for(i = 0; i < numEntries; i += 1)
		regexpList = AddListItem(literalPrefix + StringFromList(i, list, sep) + literalSuffix, regexpList, "|", Inf)
	endfor

	regexpList = "(?:" + RemoveEnding(regexpList, "|") + ")"

	return regexpList
End

/// @brief Convert a text wave to a double wave with optional support for removing NaNs and sorting
Function/WAVE ConvertToUniqueNumber(WAVE/T wv, [variable doZapNaNs, variable doSort])

	if(ParamIsDefault(doZapNaNs))
		doZapNaNs = 0
	else
		doZapNaNs = !!doZapNaNs
	endif

	if(ParamIsDefault(doSort))
		doSort = 0
	else
		doSort = !!doSort
	endif

	WAVE/T unique = GetUniqueEntries(wv)

	Make/D/FREE/N=(DimSize(unique, ROWS)) numeric = str2num(unique[p])

	if(doZapNaNs)
		WAVE/Z numericReduced = ZapNaNs(numeric)

		if(!WaveExists(numericReduced))
			return $""
		endif

		WAVE numeric = numericReduced
	endif

	if(DoSort)
		Sort numeric, numeric
	endif

	return numeric
End

/// @brief Prepare wave for inline definition
///
/// Outputs a wave in a format so that it can be initialized
/// with these contents in an Igor Pro procedure file.
Function/S GetCodeForWaveContents(WAVE/T wv)

	string list

	ASSERT(DimSize(wv, COLS) <= 1, "Does only support 1D waves")
	ASSERT(DimSize(wv, ROWS) > 0, "Does not support empty waves")

	wv[] = "\"" + wv[p] + "\""

	list = TextWaveToList(wv, ", ")
	list = RemoveEnding(list, ", ")

	return "{" + list + "}"
End

/// @brief Returns the wave type as constant
///
/// Same constant as WaveType with selector zero (default) and Redimension/Y.
///
Function WaveTypeStringToNumber(string type)

	strswitch(type)
		case "NT_FP64":
			return 0x04
		case "NT_FP32":
			return 0x02
		case "NT_I32":
			return 0x20
		case "NT_I16":
			return 0x10
		case "NT_I8":
			return 0x08
		default:
			ASSERT(0, "Type is not supported: " + type)
	endswitch
End

/// @brief Serialize a wave as JSON and return it as string
///
/// The format is documented [here](https://github.com/AllenInstitute/ZeroMQ-XOP/#wave-serialization-format).
Function/S WaveToJSON(WAVE/Z wv)

	return zeromq_test_serializeWave(wv)
End

/// @brief Deserialize a JSON document generated by WaveToJSON()
///
/// Supports only a currently used subset.
///
/// @param str  serialized JSON document
/// @param path [optional, defaults to ""] json path with the serialized wave info
/// @sa WaveToJSON
Function/WAVE JSONToWave(string str, [string path])

	variable jsonID, dim, i, j, k, numEntries, size
	string unit, type, dataUnit, waveNote

	if(ParamIsDefault(path))
		path = ""
	else
		ASSERT(strlen(path) > 1 && !cmpstr(path[0], "/"), "Path must start with /")
	endif

	jsonID = JSON_Parse(str, ignoreErr = 1)

	if(!JSON_IsValid(jsonID))
		return $""
	endif

	if(JSON_GetType(jsonID, path) == JSON_NULL)
		// invalid wave reference
		JSON_Release(jsonID)
		return $""
	endif

	type = JSON_GetString(jsonID, path + "/type", ignoreErr = 1)

	strswitch(type)
		case "NT_FP64":
		case "NT_FP32":
		case "NT_I32":
		case "NT_I16":
		case "NT_I8":
			WAVE/Z data = JSON_GetWave(jsonID, path + "/data/raw", waveMode = 1)
			ASSERT(WaveExists(data), "Missing data")
			Redimension/Y=(WaveTypeStringToNumber(type)) data
			break
		case "TEXT_WAVE_TYPE":
			WAVE/Z data = JSON_GetTextWave(jsonID, path + "/data/raw")
			ASSERT(WaveExists(data), "Missing data")
			break
		case "WAVE_TYPE":
			size = JSON_GetArraySize(jsonID, path + "/data/raw")
			Make/N=(size)/FREE/WAVE container = JSONToWave(str, path = path + "/data/raw/" + num2str(p))
			WAVE data = container
			break
		default:
			ASSERT(0, "Type is not supported: " + type)
	endswitch

	WAVE/Z/D dimSizes = JSON_GetWave(jsonID, path + "/dimension/size", waveMode = 1, ignoreErr = 1)
	ASSERT(WaveExists(dimSizes), "dimension sizes are missing")

	Make/D/FREE/N=(MAX_DIMENSION_COUNT) newSizes = -1
	newSizes[0, DimSize(dimSizes, ROWS) - 1] = dimSizes[p]
	Redimension/N=(newSizes[0], newSizes[1], newSizes[2], newSizes[3]) data

	WAVE/Z/D dimDeltas  = JSON_GetWave(jsonID, path + "/dimension/delta", waveMode = 1, ignoreErr = 1)
	WAVE/Z/D dimOffsets = JSON_GetWave(jsonID, path + "/dimension/offset", waveMode = 1, ignoreErr = 1)
	WAVE/Z/T dimUnits   = JSON_GetTextWave(jsonID, path + "/dimension/unit", ignoreErr = 1)

	if(WaveExists(dimDeltas) || WaveExists(dimOffsets) || WaveExists(dimUnits))

		if(WaveExists(dimDeltas))
			numEntries = DimSize(dimDeltas, ROWS)
		elseif(WaveExists(dimOffsets))
			numEntries = DimSize(dimOffsets, ROWS)
		elseif(WaveExists(dimUnits))
			numEntries = DimSize(dimUnits, ROWS)
		endif

		if(!WaveExists(dimDeltas))
			Make/D/FREE/N=(numEntries) dimDeltas = 1
		endif

		if(!WaveExists(dimOffsets))
			Make/D/FREE/N=(numEntries) dimOffsets = 0
		endif

		if(!WaveExists(dimUnits))
			Make/T/FREE/N=(numEntries) dimUnits
		endif

		for(i = 0; i < numEntries; i += 1)

			// @todo avoid switch once SetScale supports strings for the dimension
			switch(i)
				case 0:
					SetScale/P x, dimOffsets[i], dimDeltas[i], dimUnits[i], data
					break
				case 1:
					SetScale/P y, dimOffsets[i], dimDeltas[i], dimUnits[i], data
					break
				case 2:
					SetScale/P z, dimOffsets[i], dimDeltas[i], dimUnits[i], data
					break
				case 3:
					SetScale/P t, dimOffsets[i], dimDeltas[i], dimUnits[i], data
					break
				default:
					ASSERT(0, "Unsupported dimension")
			endswitch
		endfor
	endif

	WAVE/Z/T dimLabelsFull = JSON_GetTextWave(jsonID, path + "/dimension/label/full", ignoreErr = 1)

	if(WaveExists(dimLabelsFull))
		for(lbl : dimLabelsFull)
			SetDimLabel dim, -1, $lbl, data
			dim++
		endfor
	endif

	WAVE/Z/T dimLabelsEach = JSON_GetTextWave(jsonID, path + "/dimension/label/each", ignoreErr = 1)

	if(WaveExists(dimLabelsEach))
		ASSERT(DimSize(dimLabelsEach, ROWS) == Sum(dimSizes), "Mismatched dimension label each wave")

		for(i = 0; i < MAX_DIMENSION_COUNT; i += 1)
			for(j = 0; j < newSizes[i]; j += 1)
				SetDimLabel i, j, $dimLabelsEach[k++], data
			endfor
		endfor
	endif

	// no way to restore the modification date

	WAVE/Z/D dataFullScale = JSON_GetWave(jsonID, path + "/data/fullScale", waveMode = 1, ignoreErr = 1)

	if(!WaveExists(dataFullScale))
		Make/FREE/D dataFullScale = {0, 0}
	endif

	dataUnit = JSON_GetString(jsonID, path + "/data/unit", ignoreErr = 1)

	SetScale d, dataFullScale[0], dataFullScale[1], dataUnit, data

	waveNote = JSON_GetString(jsonID, path + "/note", ignoreErr = 1)
	Note/K data, waveNote

	JSON_Release(jsonID)

	return data
End

/// @brief Converts a string in UTF8 encoding to a text wave where each wave element contains one UTF8 characters
Function/WAVE UTF8StringToTextWave(string str)

	variable charPos, byteOffset, numBytesInCharacter, numBytesInString

	ASSERT(!IsNull(str), "string is null")

	numBytesInString = strlen(str)
	Make/FREE/T/N=(numBytesInString) wv
	if(!numBytesInString)
		return wv
	endif

	do
		if(byteOffset >= numBytesInString)
			break
		endif

		numBytesInCharacter = NumBytesInUTF8Character(str, byteOffset)
		wv[charPos]         = str[byteOffset, byteOffset + numBytesInCharacter - 1]
		charPos            += 1
		byteOffset         += numBytesInCharacter
	while(1)
	Redimension/N=(charPos) wv

	return wv
End
