#pragma rtGlobals=3		// Use modern global access method and strict wave access.

/// @file TJ_MIES_Utilities.ipf
/// This file holds general utility functions available for all other procedures.

/// @brief Returns 1 if var is a finite/normal number, 0 otherwise
Function IsFinite(var)
	variable var

	return numType(var) == 0
End

/// @brief Returns 1 if str is null, 0 otherwise
/// @param str must not be a SVAR
Function isNull(str)
	string& str

	variable len = strlen(str)
	return numtype(len) == 2
End

/// @brief Returns one if str is empty or null, zero otherwise.
/// @param str must not be a SVAR
Function isEmpty(str)
	string& str

	variable len = strlen(str)
	return numtype(len) == 2 || len <= 0
End

/// @brief Low overhead function to check assertions
///
/// @param var      if zero an error message is printed into the history and procedure execution is aborted,
///                 nothing is done otherwise.  If the debugger is enabled, it also steps into it.
/// @param errorMsg error message to output in failure case
///
/// Example usage:
///@code
///ControlInfo/W = $panelTitle popup_MoreSettings_DeviceType
///ASSERT(V_flag > 0, "Non-existing control or window")
///do something with S_value
///@endcode
Function ASSERT(var, errorMsg)
	variable var
	string errorMsg

	string file, line, func, caller, stacktrace
	string abortMsg
	variable numCallers

	try
		AbortOnValue var==0, 1
	catch
		stacktrace = GetRTStackInfo(3)
		numCallers = ItemsInList(stacktrace)

		if(numCallers >= 2)
			caller     = StringFromList(numCallers-2,stacktrace)
			func       = StringFromList(0,caller,",")
			file       = StringFromList(1,caller,",")
			line       = StringFromList(2,caller,",")
		else
			func = ""
			file = ""
			line = ""
		endif

		sprintf abortMsg, "Assertion FAILED in function %s(...) %s:%s.\rMessage: %s\r", func, file, line, errorMsg
		printf abortMsg
		Debugger
		Abort
	endtry
End

/// @brief Checks if the given name exists as window
Function windowExists(win)
	string win

	if(isNull(win) || WinType(win) == 0)
		return 0
	endif

	return 1
End

/// @brief Alternative implementation for WaveList which honours a dfref and thus
/// does not require SetDataFolder calls.
///
/// @param dfr                                 datafolder reference to search for the waves
/// @param regExpStr                           regular expression matching the waves, see the help of GrepString for an introduction to regular expressions
/// @param waveProperty [optional, empty]      additional properties of matching waves, inspired by WaveList, currently implemented are `MINCOLS` and `TEXT`
/// @param fullPath [optional, default: false] should only the wavename or the absolute path of the wave be returned.
///
/// @returns list of wave names matching regExpStr located in dfr
Function/S GetListOfWaves(dfr, regExpStr, [waveProperty, fullPath])
	dfref dfr
	string regExpStr, waveProperty
	variable fullPath

	variable i, j, numWaveProperties, numWaves, matches, val
	string name, str, prop
	string list = ""

	ASSERT(DataFolderExistsDFR(dfr),"Non-existing datafolder")
	ASSERT(!isEmpty(regExpStr),"regexpStr is empty or null")

	if(ParamIsDefault(fullPath))
		fullPath = 0
	endif

	numWaves = CountObjectsDFR(dfr, COUNTOBJECTS_WAVES)
	for(i=0; i<numWaves; i+=1)
		Wave wv = WaveRefIndexedDFR(dfr, i)
		name = NameOfWave(wv)

		if(!GrepString(name,regExpStr))
			continue
		endif

		matches = 1
		if(!ParamIsDefault(waveProperty) && !isEmpty(waveProperty))
			numWaveProperties = ItemsInList(waveProperty)
			for(j = 0; j < numWaveProperties; j += 1)
				str  = StringFromList(j, waveProperty)
				prop = StringFromList(0, str, ":")
				val  = str2num(StringFromList(1, str, ":"))
				ASSERT(IsFinite(val), "non finite value")
				ASSERT(!IsEmpty(prop), "empty option")

				strswitch(prop)
					case "MINCOLS":
						matches = matches & DimSize(wv, COLS) >= val
						break
					case "TEXT":
						matches = matches & (WaveType(wv, 1) == 2) == !!val
						break
					default:
						ASSERT(0, "property not implemented")
						break
				endswitch

				if(!matches) // no need to check the other properties
					break
				endif
			endfor
		endif

		if(matches)
			if(fullPath)
				list = AddListItem(GetWavesDataFolder(wv, 2), list, ";", Inf)
			else
				list = AddListItem(name, list, ";", Inf)
			endif
		endif
	endfor

	return list
End

/// @brief Redimension the wave to at least the given size.
///
/// The redimensioning is only done if it is required.
/// @param wv		 	wave to redimension
/// @param minimumSize 	the minimum size of the wave. Defaults to @ref MINIMUM_WAVE_SIZE.
///                     The actual size of the wave after the function returns might be larger.
/// @param dimension 	dimension to resize, all other dimensions are left untouched.
///                     Defaults to @ref ROWS.
/// @param initialValue initialValue of the new wave points
Function EnsureLargeEnoughWave(wv, [minimumSize, dimension, initialValue])
	Wave wv
	variable minimumSize, dimension, initialValue

	if(ParamIsDefault(dimension))
		dimension = ROWS
	endif

	ASSERT(dimension == ROWS || dimension == COLS || dimension == LAYERS || dimension == CHUNKS, "Invalid dimension")
	ASSERT(WaveExists(wv), "Wave does not exist")

	if(ParamIsDefault(minimumSize))
		minimumSize = MINIMUM_WAVE_SIZE
	endif

	minimumSize = max(MINIMUM_WAVE_SIZE,minimumSize)

	Make/FREE/I/N=(MAX_DIMENSION_COUNT) oldSizes
	oldSizes[] = DimSize(wv,p)

	if(minimumSize < oldSizes[dimension])
		return NaN
	endif

	minimumSize *= 2

	Make/FREE/I/N=(MAX_DIMENSION_COUNT) targetSizes = -1
	targetSizes[dimension] = minimumSize

	Redimension/N=(targetSizes[ROWS], targetSizes[COLS], targetSizes[LAYERS], targetSizes[CHUNKS]) wv

	if(!ParamIsDefault(initialValue))
		switch(dimension)
			case ROWS:
				wv[oldSizes[ROWS],] = initialValue
			break
			case COLS:
				wv[][oldSizes[COLS],] = initialValue
			break
			case LAYERS:
				wv[][][oldSizes[LAYERS],] = initialValue
			break
			case CHUNKS:
				wv[][][][oldSizes[CHUNKS],] = initialValue
			break
		endswitch
	endif
End

/// @brief Resize the number of rows to maximumSize if it is larger than that
///
/// @param wv          wave to redimension
/// @param maximumSize maximum number of the rows, defaults to MAXIMUM_SIZE
Function EnsureSmallEnoughWave(wv, [maximumSize])
	Wave wv
	variable maximumSize

	if(ParamIsDefault(maximumSize))
		maximumSize = MAXIMUM_WAVE_SIZE
	endif

	Make/FREE/I/N=(MAX_DIMENSION_COUNT) oldSizes
	oldSizes[] = DimSize(wv, p)

	if(oldSizes[ROWS] > maximumSize)
		Redimension/N=(maximumSize, -1, -1, -1) wv
	endif
End

/// @brief Convert Bytes to MiBs, a mebibyte being 2^20.
Function ConvertFromBytesToMiB(var)
	variable var

	return var / 1024 / 1024
End

/// The size in bytes of a wave with zero points. Experimentally determined in Igor Pro 6.34 under windows.
static Constant PROPRIETARY_HEADER_SIZE = 320

/// @brief Returns the size of the wave in bytes. Currently ignores dimension labels.
Function GetWaveSize(wv)
	Wave wv

	ASSERT(WaveExists(wv),"missing wave")
	return PROPRIETARY_HEADER_SIZE + GetSizeOfType(WaveType(wv)) * numpnts(wv) + strlen(note(wv))
End

/// @brief Return the size in bytes of a given type
///
/// Inspired by http://www.igorexchange.com/node/1845
Function GetSizeOfType(type)
	variable type

	variable size=1

	if(type & 0x01)
		size*=2
	endif

	if(type & 0x02)
		size*=4
	elseif(type & 0x04)
		size*=8
	elseif(type & 0x10)
		size*=2
	elseif(type & 0x20)
		size*=4
	else
		size=nan
	endif

	return size
End

/// @brief Convert the sampling interval in microseconds (1e-6s) to the rate in kHz
Function ConvertSamplingIntervalToRate(val)
	variable val

	return 1 / val * 1e3
End

/// @brief Convert the rate in kHz to the sampling interval in microseconds (1e-6s)
Function ConvertRateToSamplingInterval(val)
	variable val

	return 1 / val * 1e3
End

/// @brief Create a backup of the wave wv if it does not already
/// exist or if `forceCreation` is true.
///
/// The backup wave will be located in the same data folder and
/// its name will be the original name with #WAVE_BACKUP_SUFFIX
/// appended.
Function/Wave CreateBackupWave(wv, [forceCreation])
	Wave wv
	variable forceCreation

	string backupname
	dfref dfr

	ASSERT(WaveExists(wv), "missing wave")
	backupname = NameOfWave(wv) + WAVE_BACKUP_SUFFIX
	dfr        = GetWavesDataFolderDFR(wv)

	if(ParamIsDefault(forceCreation))
		forceCreation = 0
	else
		forceCreation = !!forceCreation
	endif

	Wave/Z/SDFR=dfr backup = $backupname

	if(WaveExists(backup) && !forceCreation)
		return backup
	endif

	Duplicate/O wv, dfr:$backupname/Wave=backup

	return backup
End

/// @brief Replace the wave wv with its backup. If possible the backup wave will be killed afterwards.
///
/// @param wv                       wave to replace by its backup
/// @param nonExistingBackupIsFatal [optional, defaults to true] behaviour for the case that there is no backup. Passing a non-zero value
///                                 will abort if the backup wave does not exist, for zero it will just do nothing.
/// @returns one if the original wave was successfully replaced, zero otherwise.
Function ReplaceWaveWithBackup(wv, [nonExistingBackupIsFatal])
	Wave wv
	variable nonExistingBackupIsFatal

	string backupname
	dfref dfr

	if(ParamIsDefault(nonExistingBackupIsFatal))
		nonExistingBackupIsFatal = 1
	endif

	ASSERT(WaveExists(wv), "Found no original wave")

	backupname = NameOfWave(wv) + WAVE_BACKUP_SUFFIX
	dfr        = GetWavesDataFolderDFR(wv)

	Wave/Z/SDFR=dfr backup = $backupname

	if(!WaveExists(backup))
		if(nonExistingBackupIsFatal)
			Abort "Backup wave does not exist"
		endif
		return 0
	endif

	Duplicate/O backup, wv
	KillWaves/Z backup
	return 1
End

/// @brief Checks if the datafolder referenced by dfr exists.
///
/// Unlike DataFolderExists() a dfref pointing to an empty ("") dataFolder is considered non-existing here.
/// @returns one if dfr is valid and references an existing datafolder, zero otherwise
/// Taken from http://www.igorexchange.com/node/2055
Function DataFolderExistsDFR(dfr)
	dfref dfr

	string dataFolder

	// invalid dfrefs don't exist
	if(DataFolderRefStatus(dfr) == 0)
		return 0
	else
		dataFolder = GetDataFolder(1,dfr)
		if( cmpstr(dataFolder,"") != 0 && DataFolderExists(dataFolder))
			return 1
		endif
	endif

	return 0
End

/// @brief Create a datafolder and all its parents,
///
/// Includes fast handling of the common case that the datafolder exists.
/// @returns reference to the datafolder
Function/DF createDFWithAllParents(dataFolder)
    string dataFolder

    variable i, numItems
    string partialPath = "root"

    if(DataFolderExists(dataFolder))
        return $dataFolder
    endif

     // i=1 because we want to skip root, as this exists always
	numItems = ItemsInList(dataFolder,":")
    for(i=1; i < numItems ; i+=1)
        partialPath += ":"
        partialPath += StringFromList(i,dataFolder,":")
        if(!DataFolderExists(partialPath))
            NewDataFolder $partialPath
        endif
    endfor

    return $dataFolder
end

/// @brief Returns one if var is an integer and zero otherwise
Function IsInteger(var)
	variable var

	return trunc(var) == var
End

/// @brief Downsample data
///
/// Downsampling is performed on each @b column of the input wave.
/// Edge-points of the output wave are by default set to zero.
/// @param wv numeric wave, its row must hold more points than downsampleFactor.
///           Will hold the downsampled data on successfull return, in the
///           error case the contents are undetermined
/// @param downsampleFactor positive non-zero integer by which the wave should
///                         be downsampled
/// @param upsampleFactor   positive non-zero integer by which the wave should
///                         be upsampled
/// @param mode 			decimation mode, one of @ref DECIMATION_BY_OMISSION,
///							@ref DECIMATION_BY_AVERAGING
///                         or @ref DECIMATION_BY_SMOOTHING.
/// @param winFunction 		Windowing function for @ref DECIMATION_BY_SMOOTHING mode,
///                    		must be one of @ref ALL_WINDOW_FUNCTIONS.
/// @returns One on error, zero otherwise
Function Downsample(wv, downsampleFactor, upsampleFactor, mode, [winFunction])
	Wave/Z wv
	variable downsampleFactor, upsampleFactor, mode
	string winFunction

	variable numReconstructionSamples = -1

	// parameter checking
	if(!WaveExists(wv))
		print "Wave wv does not exist"
		return 1
	elseif(downsampleFactor <= 0 || downsampleFactor >= DimSize(wv,ROWS))
		print "Parameter downsampleFactor must be strictly positive and strictly smaller than the number of rows in wv."
		return 1
	elseif(!IsInteger(downsampleFactor))
		print "Parameter downsampleFactor must be an integer."
		return 1
	elseif(upsampleFactor <= 0 )
		print "Parameter upsampleFactor must be strictly positive."
		return 1
	elseif(!IsInteger(upsampleFactor))
		print "Parameter upsampleFactor must be an integer."
		return 1
	elseif(mode != DECIMATION_BY_SMOOTHING && !ParamIsDefault(winFunction))
		print "Invalid combination of a window function and mode."
		return 1
	elseif(!ParamIsDefault(winFunction) && FindListItem(winFunction, ALL_WINDOW_FUNCTIONS) == -1)
		print "Unknown windowing function: " + winFunction
		return 1
	endif

	switch(mode)
		case DECIMATION_BY_OMISSION:
			// N=3 is compatible with pre IP 6.01 versions and current versions
			// In principle we want to use N=1 here, which is equivalent with N=3 for the default windowing function
			// See also the Igor Manual page III-141
			numReconstructionSamples = 3
			Resample/DOWN=(downsampleFactor)/UP=(upsampleFactor)/N=(numReconstructionSamples) wv
			break
		case DECIMATION_BY_SMOOTHING:
			numReconstructionSamples = 21 // empirically determined
			if(ParamIsDefault(winFunction))
				Resample/DOWN=(downsampleFactor)/UP=(upsampleFactor)/N=(numReconstructionSamples) wv
			else
				Resample/DOWN=(downsampleFactor)/UP=(upsampleFactor)/N=(numReconstructionSamples)/WINF=$winFunction wv
			endif
			break
		case DECIMATION_BY_AVERAGING:
			// See again the Igor Manual page III-141
			// take the next odd number
			numReconstructionSamples = mod(downSampleFactor,2) == 0 ? downSampleFactor + 1 : downSampleFactor
			Resample/DOWN=(downsampleFactor)/UP=(upsampleFactor)/N=(numReconstructionSamples)/WINF=None wv
			break
		default:
			print "Invalid mode: " + num2str(mode)
			return 1
	endswitch

	return 0
End

/// @brief Compute the least common multiplier of two variables
Function CalculateLCM(a,b)
	Variable a, b

	return (a * b) / gcd(a, b)
End

/// @brief Compute the least common multiplier of all entries in the 1D-wave
Function CalculateLCMOfWave(wv)
	Wave wv

	variable i, result
	variable numRows = DimSize(wv,ROWS)
	if( numRows <= 1)
		return NaN
	endif

	result = CalculateLCM(wv[0],wv[1])
	for(i=2; i < numRows; i+=1)
		result = CalculateLCM(result,wv[i])
	endfor

	return result
End

/// @brief Returns an unsorted free wave with all unique entries from wv.
///
/// This is not the best possible implementation but should
/// suffice for our needs.
Function/Wave GetUniqueEntries(wv)
	Wave wv

	variable numRows, i, idx

	numRows = DimSize(wv,ROWS)
	ASSERT(numRows == numpnts(wv), "Wave must be 1D")

	Duplicate/O/FREE wv, result

	if(numRows == 0)
		return result
	endif

	result  = NaN
	idx     = numRows - 1
	for(i=0; i < numRows; i+=1 )
		FindValue/V=(wv[i])/S=(idx) result
		if(V_Value == -1)
			result[idx] = wv[i]
			idx -= 1
		endif
	endfor

	DeletePoints 0, idx+1, result

	return result
End

/// @brief Removes the datafolder reference if there are no objects in it anymore
///
/// @param dfr data folder reference to kill
/// @returns 	1 in case the folder was removed and 0 in all other cases
Function RemoveEmptyDataFolder(dfr)
    dfref dfr

    variable objectsInFolder

    if(!DataFolderExistsDFR(dfr))
        return 0
    endif

    objectsInFolder = CountObjectsDFR(dfr, COUNTOBJECTS_WAVES) + CountObjectsDFR(dfr, COUNTOBJECTS_VAR) + CountObjectsDFR(dfr, COUNTOBJECTS_STR) + CountObjectsDFR(dfr, COUNTOBJECTS_DATAFOLDER)

    if(objectsInFolder == 0)
        KillDataFolder dfr
        return 1
    endif

    return 0
end

/// @brief Recursively remove all folders from the datafolder path,
/// if and only if all are empty.
Function RecursiveRemoveEmptyDataFolder(dfr)
    dfref dfr

    variable numItems, i
    string path, partialPath

    if(!DataFolderExistsDFR(dfr))
        return 0
    endif

    path = GetDataFolder(1, dfr)
    path = RemoveEnding(path, ":")
    numItems = ItemsInList(path, ":")
    partialPath = path
    for(i=numItems-1; i >= 1; i-=1)
		if(!RemoveEmptyDataFolder($partialPath))
			break
		endif
		partialPath = RemoveEnding(partialPath, ":" + StringFromList(i, path, ":"))
	endfor
End

/// @name Debugger state constants for DisableDebugger and ResetDebuggerState
/// @{
static Constant DEBUGGER_ENABLED        = 0x01
static Constant DEBUGGER_DEBUG_ON_ERROR = 0x02
static Constant DEBUGGER_NVAR_CHECKING  = 0x04
/// @}

/// @brief Disable the debugger
///
/// @returns the full debugger state binary encoded. first bit: on/off, second bit: debugOnError on/off, third bit: nvar/svar/wave checking on/off
Function DisableDebugger()

	variable debuggerState
	DebuggerOptions
	debuggerState = V_enable * DEBUGGER_ENABLED + V_debugOnError * DEBUGGER_DEBUG_ON_ERROR + V_NVAR_SVAR_WAVE_Checking * DEBUGGER_NVAR_CHECKING

	if(V_enable)
		DebuggerOptions enable=0
	endif

	return debuggerState
End

/// @brief Reset the debugger to the given state
///
/// Useful in conjunction with DisableDebugger() to temporarily disable the debugger
///@code
/// variable debuggerState = DisableDebugger()
/// // code which might trigger the debugger, e.g. CurveFit
/// ResetDebuggerState(debuggerState)
/// // now the debugger is in the same state as before
///@endcode
Function ResetDebuggerState(debuggerState)
	variable debuggerState

	variable debugOnError, nvarChecking

	if(debuggerState & DEBUGGER_ENABLED)
		debugOnError = debuggerState & DEBUGGER_DEBUG_ON_ERROR
		nvarChecking = debuggerState & DEBUGGER_NVAR_CHECKING
		DebuggerOptions enable=1, debugOnError=debugOnError, NVAR_SVAR_WAVE_Checking=nvarChecking
	endif
End

/// @brief Returns the numeric value of `key` found in the wave note,
/// returns NaN if it could not be found
///
/// The expected wave note format is: `key1:val1;key2:val2;`
Function GetNumberFromWaveNote(wv, key)
	Wave wv
	string key

	ASSERT(WaveExists(wv), "Missing wave")
	ASSERT(!IsEmpty(key), "Empty key")

	return NumberByKey(key, note(wv))
End

/// @brief Updates the numeric value of `key` found in the wave note to `val`
///
/// The expected wave note format is: `key1:val1;key2:val2;`
Function SetNumberInWaveNote(wv, key, val)
	Wave wv
	string key
	variable val

	ASSERT(WaveExists(wv), "Missing wave")
	ASSERT(!IsEmpty(key), "Empty key")

	Note/K wv, ReplaceNumberByKey(key, note(wv), val)
End

/// @brief Remove the single quotes from a liberal wave name if they can be found
Function/S PossiblyUnquoteName(name)
	string name

	if(isEmpty(name))
		return name
	endif

	if(!CmpStr(name[0], "'") && !CmpStr(name[strlen(name) - 1], "'"))
		ASSERT(strlen(name) > 1, "name is too short")
		return name[1, strlen(name) - 2]
	endif

	return name
End

/// @brief Structured writing of numerical values with names into wave notes
///
/// The general layout is `key1 = var;key2 = str;` and the note is never
/// prefixed with a carriage return ("\r").
/// @param wv       wave to add the wave note to
/// @param key      string identifier
/// @param var      variable to output
/// @param str      string to output
/// @param appendCR 0 (default) or 1, should a carriage return ("\r") be appended to the note
Function AddEntryIntoWaveNoteAsList(wv ,key, [var, str, appendCR])
	Wave wv
	string key
	variable var
	string str
	variable appendCR

	variable numOptParams
	string formattedString

	ASSERT(WaveExists(wv), "missing wave")
	ASSERT(!IsEmpty(key), "empty key")

	numOptParams = !ParamIsDefault(var) + !ParamIsDefault(str)
	ASSERT(numOptParams == 1, "invalid optional parameter combination")

	if(!ParamIsDefault(var))
		sprintf formattedString, "%s = %g;", key, var
	elseif(!ParamIsDefault(str))
		sprintf formattedString, "%s = %s;", key, str
	endif

	appendCR = ParamIsDefault(appendCR) ? 0 : appendCR

	if(appendCR)
		Note/NOCR wv, formattedString + "\r"
	else
		Note/NOCR wv, formattedString
	endif
End

/// @brief Check if a given wave, or at least one wave from the dfr, is displayed on a graph
///
/// @return one if one is displayed, zero otherwise
Function IsWaveDisplayedOnGraph(win, [wv, dfr])
	string win
	WAVE/Z wv
	DFREF dfr

	string traceList, trace, list
	variable numWaves, numTraces, i

	ASSERT(ParamIsDefault(wv) + ParamIsDefault(dfr) == 1, "Expected exactly one parameter of wv and dfr")

	if(!ParamIsDefault(wv))
		if(!WaveExists(wv))
			return 0
		endif

		MAKE/FREE/WAVE/N=1 candidates = wv
	else
		if(!DataFolderExistsDFR(dfr) || CountObjectsDFR(dfr, COUNTOBJECTS_WAVES) == 0)
			return 0
		endif

		WAVE candidates = ConvertListOfWaves(GetListOfWaves(dfr, ".*", fullpath=1))
		numWaves = DimSize(candidates, ROWS)
	endif

	traceList = TraceNameList(win, ";", 1)
	numTraces = ItemsInList(traceList)
	for(i = numTraces - 1; i >= 0; i -= 1)
		trace = StringFromList(i, traceList)
		WAVE traceWave = TraceNameToWaveRef(win, trace)

		if(GetRowIndex(candidates, refWave=traceWave) >= 0)
			return 1
		endif
	endfor

	return 0
End

/// @brief Remove traces from a graph and optionally try to kill their waves
///
/// @param graph                            graph
/// @param kill [optional, default: false]  try to kill the wave after it has been removed
/// @param trace [optional, default: all]   remove the given trace only
/// @param wv [optional, default: ignored]  remove all traces which stem from the given wave
/// @param dfr [optional, default: ignored] remove all traces which stem from one of the waves in dfr
///
/// Only one of trace/wv/dfr may be supplied.
///
/// @return number of traces/waves removed from the graph
Function RemoveTracesFromGraph(graph, [kill, trace, wv, dfr])
	string graph
	variable kill
	string trace
	WAVE/Z wv
	DFREF dfr

	variable i, numEntries, removals, tryKillingTheWave, numOptArgs
	string traceList, refTrace

	if(ParamIsDefault(kill))
		kill = 0
	endif

	numOptArgs = ParamIsDefault(trace) + ParamIsDefault(wv) + ParamIsDefault(dfr)
	ASSERT(numOptArgs == 3 || numOptArgs == 2, "Can only accept one of the trace/wv/dfr parameters")

	if(!ParamIsDefault(wv) && !WaveExists(wv) || !ParamIsDefault(dfr) && !DataFolderExistsDFR(dfr))
		return 0
	endif

	if(!ParamIsDefault(dfr))
		WAVE candidates = ConvertListOfWaves(GetListOfWaves(dfr, ".*", fullpath=1))
	endif

	traceList  = TraceNameList(graph, ";", 1 )
	numEntries = ItemsInList(traceList)

	// iterating backwards is required, see http://www.igorexchange.com/node/1677#comment-2315
	for(i = numEntries - 1; i >= 0; i -= 1)
		refTrace = StringFromList(i, traceList)

		Wave/Z refWave = TraceNameToWaveRef(graph, refTrace)

		if(ParamIsDefault(trace) && ParamIsDefault(wv) && ParamIsDefault(dfr))
			RemoveFromGraph/W=$graph $refTrace
			removals += 1
			tryKillingTheWave = 1
		elseif(!ParamIsDefault(trace))
			if(!cmpstr(refTrace, trace))
				RemoveFromGraph/W=$graph $refTrace
				removals += 1
				tryKillingTheWave = 1
			endif
		elseif(!ParamIsDefault(wv))
			if(WaveRefsEqual(refWave, wv))
				RemoveFromGraph/W=$graph $refTrace
				removals += 1
				tryKillingTheWave = 1
			endif
		elseif(!ParamIsDefault(dfr))
			if(GetRowIndex(candidates, refWave=refWave) >= 0)
				RemoveFromGraph/W=$graph $refTrace
				removals += 1
				tryKillingTheWave = 1
			endif
		endif

		if(kill && tryKillingTheWave)
			KillWaves/F/Z refWave
		endif

		tryKillingTheWave = 0
	endfor

	return removals
End

///@brief Removes all annotations from the graph
Function RemoveAnnotationsFromGraph(graph)
	string graph

	variable i, numEntries
	string list

	list = AnnotationList(graph)
	numEntries = ItemsInList(list)
	for(i = 0; i < numEntries; i += 1)
		Textbox/W=$graph/K/N=$StringFromList(i, list)
	endfor
End

/// @brief Sort 2D waves in-place with one column being the key
///
/// By default an alphanumeric sorting is performed.
/// @param w                          wave of arbitrary type
/// @param keyColPrimary              column of the primary key
/// @param keyColSecondary [optional] column of the secondary key
/// @param keyColTertiary [optional]  column of the tertiary key
/// @param reversed [optional]        do an descending sort instead of an ascending one
///
/// Taken from http://www.igorexchange.com/node/599 with some cosmetic changes and extended for
/// the two key
Function MDsort(w, keyColPrimary, [keyColSecondary, keyColTertiary, reversed])
	WAVE w
	variable keyColPrimary, keyColSecondary, keyColTertiary, reversed

	variable numRows, type

	type = WaveType(w)
	numRows = DimSize(w, 0)

	if(numRows == 0) // nothing to do
		return NaN
	endif

	Make/Y=(type)/Free/N=(numRows) keyPrimary, keySecondary, keyTertiary
	Make/Free/N=(numRows)/I/U valindex = p

	if(type == 0)
		WAVE/T indirectSourceText = w
		WAVE/T output = keyPrimary
		output[] = indirectSourceText[p][keyColPrimary]
		WAVE/T output = keySecondary
		output[] = indirectSourceText[p][keyColSecondary]
		WAVE/T output = keyTertiary
		output[] = indirectSourceText[p][keyColTertiary]
	else
		WAVE indirectSource        = w
		MultiThread keyPrimary[]   = indirectSource[p][keyColPrimary]
		MultiThread keySecondary[] = indirectSource[p][keyColSecondary]
		MultiThread keyTertiary[]  = indirectSource[p][keyColTertiary]
	endif

	if(ParamIsDefault(keyColSecondary) && ParamIsDefault(keyColTertiary))
		if(reversed)
			Sort/A/R keyPrimary, valindex
		else
			Sort/A keyPrimary, valindex
		endif
	elseif(!ParamIsDefault(keyColSecondary))
		if(reversed)
			Sort/A/R {keyPrimary, keySecondary}, valindex
		else
			Sort/A {keyPrimary, keySecondary}, valindex
		endif
	else
		if(reversed)
			Sort/A/R {keyPrimary, keySecondary, keyTertiary}, valindex
		else
			Sort/A {keyPrimary, keySecondary, keyTertiary}, valindex
		endif
	endif

	if(type == 0)
		Duplicate/FREE/T indirectSourceText, newtoInsertText
		newtoInsertText[][][][] = indirectSourceText[valindex[p]][q][r][s]
		indirectSourceText = newtoInsertText
	else
		Duplicate/FREE indirectSource, newtoInsert
		MultiThread newtoinsert[][][][] = indirectSource[valindex[p]][q][r][s]
		MultiThread indirectSource = newtoinsert
	endif
End

/// @brief Breaking a string into multiple lines
///
/// Currently all spaces and tabs which are not followed by numbers are
/// replace by carriage returns (\\r). Therefore the algorithm creates
/// a paragraph with minimum width.
///
/// A generic solution would either implement the real deal
///
/// Knuth, Donald E.; Plass, Michael F. (1981),
/// Breaking paragraphs into lines
/// Software: Practice and Experience 11 (11):
/// 1119-1184, doi:10.1002/spe.4380111102.
///
/// or translate [1] from C++ to Igor Pro.
///
/// [1]: http://api.kde.org/4.x-api/kdelibs-apidocs/kdeui/html/classKWordWrap.html
Function/S LineBreakingIntoParWithMinWidth(str)
	string str

	variable len, i
	string output = ""
	string curr, next

	len = strlen(str)
	for(i = 0; i < len; i += 1)
		curr = str[i]
		next = SelectString(i < len, "", str[i + 1])

		// str2num skips leading spaces and tabs
		if((!cmpstr(curr, " ") || !cmpstr(curr, "\t")) && !IsFinite(str2num(next)) && cmpstr(next, " ") && cmpstr(next, "\t"))
			output += "\r"
			continue
		endif

		output += curr
	endfor

	return output
End

/// @brief Extended version of `FindValue`
///
/// Allows to search only the specified column for a value
/// and returns all matching row indizes in a wave.
///
/// Exactly one of `var`/`str`/`prop` has to be given.
///
/// Exactly one of `wv`/`wvText` has to be given.
///
/// Exactly one of `col`/`colLabel` has to be given.
///
/// @param col [optional]      column to search in only
/// @param colLabel [optional] column label to search in only
/// @param var [optional]      numeric value to search
/// @param str [optional]      string value to search
/// @param prop [optional]     property to search, see @ref FindIndizesProps
/// @param wv [optional]       numeric wave to search
/// @param wvText [optional]   text wave to search
/// @param startRow [optional] starting row to restrict the search to
/// @param endRow [optional]   ending row to restrict the search to
///
/// @returns A wave with the row indizes of the found values. An invalid wave reference if the
/// value could not be found.
Function/Wave FindIndizes([col, colLabel, var, str, prop, wv, wvText, startRow, endRow])
	variable col, var, prop
	string str
	Wave wv
	Wave/T wvText
	string colLabel
	variable startRow, endRow

	variable numCols, numRows

	ASSERT(ParamIsDefault(col) + ParamIsDefault(colLabel) == 1, "Expected exactly one col/colLabel argument")
	ASSERT(ParamIsDefault(wv) + ParamIsDefault(wvText) == 1, "Expected exactly one optional wv/wvText argument")
	ASSERT(ParamIsDefault(prop) + ParamIsDefault(var) + ParamIsDefault(str) == 2 || (!ParamIsDefault(prop) && (prop == PROP_MATCHES_VAR_BIT_MASK || prop == PROP_NOT_MATCHES_VAR_BIT_MASK) && !ParamIsDefault(var) && ParamIsDefault(str)), "Expected exactly one optional var/str/prop argument")

	if(ParamIsDefault(var))
		var = str2num(str)
	elseif(ParamIsDefault(str))
		str = num2str(var)
	endif

	if(!ParamIsDefault(wv))
		ASSERT(WaveType(wv), "Expected numeric wave")

		if(DimSize(wv, ROWS) == 0)
			return $""
		endif

		numCols = DimSize(wv, COLS)
		numRows = DimSize(wv, ROWS)
		if(!ParamIsDefault(colLabel))
			col = FindDimLabel(wv, COLS, colLabel)
			ASSERT(col >= 0, "invalid column label")
		endif
	else
		ASSERT(!WaveType(wvText), "Expected text wave")

		if(DimSize(wvText, ROWS) == 0)
			return $""
		endif

		numCols = DimSize(wvText, COLS)
		numRows = DimSize(wvText, ROWS)
		if(!ParamIsDefault(colLabel))
			col = FindDimLabel(wvText, COLS, colLabel)
			ASSERT(col >= 0, "invalid column label")
		endif
	endif

	if(!ParamIsDefault(prop))
		ASSERT(prop == PROP_NON_EMPTY || prop == PROP_EMPTY || prop == PROP_MATCHES_VAR_BIT_MASK || prop == PROP_NOT_MATCHES_VAR_BIT_MASK, "Invalid property")
	endif

	if(ParamIsDefault(startRow))
		startRow = 0
	endif

	if(ParamIsDefault(endRow))
		endRow  = ParamIsDefault(wv) ? DimSize(wvText, ROWS) : DimSize(wv, ROWS)
		endRow -= 1
	endif

	ASSERT(col == 0 || (col > 0 && col < numCols), "Invalid column")
	ASSERT(endRow >= 0 && endRow < numRows, "Invalid endRow")
	ASSERT(startRow >= 0 && startRow < numRows, "Invalid startRow")
	ASSERT(startRow <= endRow, "endRow must be larger than startRow")

	Make/FREE/R/N=(numRows) matches = NaN

	if(!ParamIsDefault(wv))
		if(!ParamIsDefault(prop))
			if(prop == PROP_EMPTY)
				matches[startRow, endRow] = (numtype(wv[p][col]) == 2 ? p : NaN)
			elseif(prop == PROP_NON_EMPTY)
				matches[startRow, endRow] = (numtype(wv[p][col]) != 2 ? p : NaN)
			elseif(prop == PROP_MATCHES_VAR_BIT_MASK)
				matches[startRow, endRow] = (wv[p][col] & var ? p : NaN)
			elseif(prop == PROP_NOT_MATCHES_VAR_BIT_MASK)
				matches[startRow, endRow] = (!(wv[p][col] & var) ? p : NaN)
			endif
		else
			matches[startRow, endRow] = (wv[p][col] == var ? p : NaN)
		endif
	else
		if(!ParamIsDefault(prop))
			if(prop == PROP_EMPTY)
				matches[startRow, endRow] = (!cmpstr(wvText[p][col], "") ? p : NaN)
			elseif(prop == PROP_NON_EMPTY)
				matches[startRow, endRow] = (cmpstr(wvText[p][col], "") ? p : NaN)
			elseif(prop == PROP_MATCHES_VAR_BIT_MASK)
				matches[startRow, endRow] = (str2num(wvText[p][col]) & var ? p : NaN)
			elseif(prop == PROP_NOT_MATCHES_VAR_BIT_MASK)
				matches[startRow, endRow] = (!(str2num(wvText[p][col]) & var) ? p : NaN)
			endif
		else
			matches[startRow, endRow] = (!cmpstr(wvText[p][col], str) ? p : NaN)
		endif
	endif

	WaveTransform/O zapNaNs, matches

	if(DimSize(matches, ROWS) == 0)
		return $""
	endif

	return matches
End

/// @brief Find the first and last point index of a consecutive range of values
///
/// @param[in]  wv                wave to search
/// @param[in]  col               column to look for
/// @param[in]  val               value to search
/// @param[in]  forwardORBackward find the first(1) or last(0) range
/// @param[out] first             point index of the beginning of the range
/// @param[out] last              point index of the end of the range
Function FindRange(wv, col, val, forwardORBackward, first, last)
	WAVE wv
	variable col, val, forwardORBackward
	variable &first, &last

	variable numRows, i

	first = NaN
	last  = NaN

	if(!WaveType(wv))
		WAVE/Z indizes = FindIndizes(col=col, var=val, wvText=wv)
	else
		WAVE/Z indizes = FindIndizes(col=col, var=val, wv=wv)
	endif

	if(!WaveExists(indizes))
		return NaN
	endif

	numRows = DimSize(indizes, ROWS)

	if(numRows == 1)
		first = indizes[0]
		last  = indizes[0]
		return NaN
	endif

	if(forwardORBackward)

		first = indizes[0]
		last  = indizes[0]

		for(i = 1; i < numRows; i += 1)
			// a forward search stops after the end of the first sequence
			if(indizes[i] > last + 1)
				return NaN
			endif

			last = indizes[i]
		endfor
	else

		first = indizes[numRows - 1]
		last  = indizes[numRows - 1]

		for(i = numRows - 2; i >= 0; i -= 1)
			// a backward search stops when the beginning of the last sequence was found
			if(indizes[i] < first - 1)
				return NaN
			endif

			first = indizes[i]
		endfor
	endif
End

/// @brief Returns a list of all files with the extension given in the symbolic path pathName
///
/// Adapted from the example in the `IndexedDir` documentation
///
/// Warning! This function uses recursion, so it might take some time
///
/// @param pathName                   Name of symbolic path in which to look for folders and files
/// @param extension                  File name extension (e.g., ".txt") or "????" for all files
/// @param level [optional, don't use] Indicate level of recursion
Function/S GetFilesRecursively(pathName, extension, [level])
	string pathName
	string extension
	variable level

	variable fileIndex, folderIndex, levelValue
	string path, fileName, fileNames, subFolderPathName, subFolderPath
	string foundFilesList = ""
	string recursFoundFilesList = ""

	if(ParamIsDefault(level))
		levelValue = 0
	else
		levelValue = level
	endif

	levelValue += 1

	// get folder name from symbolic path
	PathInfo $pathName
	path = S_path
	ASSERT(V_flag != 0 , "path does not exist")

	fileNames = IndexedFile($pathName, -1, extension)
	fileIndex = 0

	// get all files in the folder pathName
	do
		fileName = StringFromList(fileIndex, fileNames)

		if (isEmpty(fileName))
			break // No more files
		endif

		foundFilesList = AddListItem(path + fileName, foundFilesList, ";", inf)
		fileIndex += 1
	while(1)

	// traverse into the first subfolder and call this function recursively
	string paths = IndexedDir($pathName, -1, 1)
	folderIndex = 0
	do
		path = StringFromList(folderIndex, paths)

		if(isEmpty(path))
			break // No more folders
		endif

		// name of the new symbolic path
		subFolderPathName =  UniqueName("tempPrintFoldersPath_", 12, levelValue)
		// Now we get the path to the new parent folder
		subFolderPath = path

		NewPath/Q/O $subFolderPathName, subFolderPath
		recursFoundFilesList = GetFilesRecursively(subFolderPathName, extension, level = levelValue)
		KillPath/Z $subFolderPathName

		if(!isEmpty(recursFoundFilesList))
			foundFilesList += recursFoundFilesList
		endif

		folderIndex += 1
	while(1)

	return foundFilesList
End

/// @brief Returns a reference to a newly created datafolder
///
/// Basically a datafolder aware version of UniqueName for datafolders
///
/// @param dfr 	    datafolder reference where the new datafolder should be created
/// @param baseName first part of the datafolder, might be shorted due to Igor Pro limitations
Function/DF UniqueDataFolder(dfr, baseName)
	dfref dfr
	string baseName

	variable index
	string name = ""
	string basePath, path

	ASSERT(!isEmpty(baseName), "baseName must not be empty" )
	ASSERT(DataFolderExistsDFR(dfr), "dfr does not exist")

	// shorten basename so that we can attach some numbers
	baseName = CleanupName(baseName[0, 26], 0)
	basePath = GetDataFolder(1, dfr)
	path = basePath + baseName

	do
		if(!DataFolderExists(path))
			NewDataFolder $path
			return $path
		endif

		path = basePath + baseName + "_" + num2istr(index)

		index += 1
	while(index < 10000)

	DEBUGPRINT("Could not find a unique folder with 10000 trials")

	return $""
End

/// @brief Remove str with the first character removed, or
/// if given with startStr removed
///
/// Same semantics as the RemoveEnding builtin
Function/S RemovePrefix(str, [startStr])
	string str, startStr

	variable length, pos

	length = strlen(str)

	if(ParamIsDefault(startStr))

		if(length <= 0)
			return str
		endif

		return str[1, length - 1]
	endif

	pos = strsearch(str, startStr, 0)

	if(pos != 0)
		return str
	endif

	return 	str[strlen(startStr), length - 1]
End

/// @brief Set column dimension labels from the first row of the key wave
///
/// Specialized function from the experiment documentation file needed also in other places.
Function SetDimensionLabels(keys, values)
	Wave/T keys
	Wave values

	variable i, numCols
	string text

	numCols = DimSize(values, COLS)
	ASSERT(DimSize(keys, COLS) == numCols, "Mismatched column sizes")
	ASSERT(DimSize(keys, ROWS) > 0 , "Expected at least one row in the key wave")

	for(i = 0; i < numCols; i += 1)
		text = keys[0][i]
		ASSERT(!isEmpty(text), "Empty key")
		SetDimLabel COLS, i, $text, keys, values
	endfor
End

/// @brief Returns a unique and non-existing file name
///
/// @warning This function must *not* be used for security relevant purposes,
/// as for that the check-and-file-creation must be an atomic operation.
///
/// @param symbPath		symbolic path
/// @param baseName		base name of the file, must not be empty
/// @param suffix		file suffix, e.g. ".txt", must not be empty
Function/S UniqueFile(symbPath, baseName, suffix)
	string symbPath, baseName, suffix

	string file
	variable i = 1

	PathInfo $symbPath
	ASSERT(V_flag == 1, "Symbolic path does not exist")
	ASSERT(!isEmpty(baseName), "baseName must not be empty")
	ASSERT(!isEmpty(suffix), "suffix must not be empty")

	file = baseName + suffix

	do
		GetFileFolderInfo/Q/Z/P=$symbPath file

		if(V_flag)
			return file
		endif

		file = baseName + "_" + num2str(i) + suffix
		i += 1

	while(i < 10000)

	ASSERT(0, "Could not find a unique file with 10000 trials")
End

/// @brief Return the name of the experiment without the file suffix
Function/S GetExperimentName()
	return IgorInfo(1)
End

/// @brief Return a formatted timestamp of the form "YY_MM_DD_HHMMSS"
///
/// @param humanReadable [optional, default to false]                                Returns a format viable for display in a GUI
/// @param secondsSinceIgorEpoch [optional, defaults to number of seconds until now] Seconds since the Igor Pro epoch (1/1/1904)
Function/S GetTimeStamp([secondsSinceIgorEpoch, humanReadable])
	variable secondsSinceIgorEpoch, humanReadable

	if(ParamIsDefault(secondsSinceIgorEpoch))
		secondsSinceIgorEpoch = DateTime
	endif

	if(ParamIsDefault(humanReadable))
		humanReadable = 0
	else
		humanReadable = !!humanReadable
	endif

	if(humanReadable)
		return Secs2Time(secondsSinceIgorEpoch, 1)  + " " + Secs2Date(secondsSinceIgorEpoch, -2, "/")
	else
		return Secs2Date(secondsSinceIgorEpoch, -2, "_") + "_" + ReplaceString(":", Secs2Time(secondsSinceIgorEpoch, 3), "")
	endif
End

/// @brief Function prototype for use with #CallFunctionForEachListItem
Function CALL_FUNCTION_LIST_PROTOTYPE(str)
	string str
End

/// @brief Convenience function to call the function f with each list item
///
/// The function's type must be #CALL_FUNCTION_LIST_PROTOTYPE where the return
/// type is ignored.
Function CallFunctionForEachListItem(f, list, [sep])
	FUNCREF CALL_FUNCTION_LIST_PROTOTYPE f
	string list, sep

	variable i, numEntries
	string entry

	if(ParamIsDefault(sep))
		sep = ";"
	endif

	numEntries = ItemsInList(list, sep)
	for(i = 0; i < numEntries; i += 1)
		entry = StringFromList(i, list, sep)

		f(entry)
	endfor
End

/// @brief Create a folder recursively on disk given an absolute path
///
/// If you pass windows style paths using backslashes remember to always *double* them.
Function CreateFolderOnDisk(absPath)
	string absPath

	string path, partialPath, tempPath
	variable numParts, i

	// convert to ":" folder separators
	path = ParseFilePath(5, absPath, ":", 0, 0)

	GetFileFolderInfo/Q/Z path
	if(!V_flag)
		ASSERT(V_isFolder, "The path which we should create exists, but points to a file")
		return NaN
	endif

	tempPath = UniqueName("tempPath", 12, 0)

	numParts = ItemsInList(path, ":")
	partialPath = StringFromList(0, path, ":")
	ASSERT(strlen(partialPath) == 1, "Expected a single drive letter for the first path component")

	// we skip the first one as that is the drive letter
	for(i = 1; i < numParts; i += 1)
		partialPath += ":" + StringFromList(i, path, ":")

		GetFileFolderInfo/Q/Z partialPath
		if(!V_flag)
			ASSERT(V_isFolder, "The partial path which we should create exists, but points to a file")
			continue
		endif

		NewPath/O/C/Q/Z $tempPath partialPath
	endfor

	KillPath/Z $tempPath

	GetFileFolderInfo/Q/Z partialPath
	if(!V_flag)
		ASSERT(V_isFolder, "The path which we should create exists, but points to a file")
		return NaN
	endif

	ASSERT(0, "Could not create the path, maybe the permissions were insufficient")
End

/// @brief Return the row index of the given value, string converted to a variable, or wv
///
/// Assumes wv being one dimensional
Function GetRowIndex(wv, [val, str, refWave])
	WAVE wv
	variable val
	string str
	WAVE/Z refWave

	variable numEntries, i

	ASSERT(ParamIsDefault(val) + ParamIsDefault(str) + ParamIsDefault(refWave) == 2, "Expected exactly one argument")

	if(!ParamIsDefault(refWave))
		ASSERT(WaveType(wv, 1) == 4, "wv must be a wave holding wave references")
		numEntries = DimSize(wv, ROWS)
		for(i = 0; i < numEntries; i += 1)
			WAVE/WAVE cmpWave = wv
			if(WaveRefsEqual(cmpWave[i], refWave))
				return i
			endif
		endfor
	else
		if(!ParamIsDefault(str))
			val = str2num(str)
		endif

		FindValue/V=(val) wv

		if(V_Value >= 0)
			return V_Value
		endif
	endif

	return NaN
End

/// @brief Converts a list of strings referencing waves with full paths to a wave of wave references
///
/// It is assumed that all created wave references refer to an *existing* wave
Function/WAVE ConvertListOfWaves(list)
	string list

	variable i, numEntries
	numEntries = ItemsInList(list)
	MAKE/FREE/WAVE/N=(numEntries) waves

	for(i = 0; i < numEntries; i += 1)
		WAVE/Z wv = $StringFromList(i, list)
		ASSERT(WaveExists(wv), "The wave does not exist")
		waves[i] = wv
	endfor

	return waves
End

/// @brief Return a list of datafolders located in `dfr`
Function/S GetListOfDataFolders(dfr)
	DFREF dfr

	string list = DataFolderDir(0x01, dfr)
	list = StringByKey("FOLDERS", list , ":")
	list = ReplaceString(",", list, ";")

	return list
End

/// @brief Return the base name of the file
///
/// Given `path/file.suffix` this gives `file`.
Function/S GetBaseName(filePathWithSuffix)
	string filePathWithSuffix

	return ParseFilePath(3, filePathWithSuffix, ":", 1, 0)
End

/// @brief Set the given bit mask in var
Function SetBit(var, bit)
	variable var, bit

	return var | bit
End

/// @brief Clear the given bit mask in var
Function ClearBit(var, bit)
	variable var, bit

	return var & ~bit
End

/// @brief Create a list of strings using the given format in the given range
///
/// @param format   formatting string, must have exactly one specifier which accepts a number
/// @param start	first point of the range
/// @param step	    step size for iterating over the range
/// @param stop 	last point of the range
Function/S BuildList(format, start, step, stop)
	string format
	variable start, step, stop

	string str
	string list = ""
	variable i

	ASSERT(start < stop, "Invalid range")
	ASSERT(step > 0, "Invalid step")

	for(i = start; i < stop; i += step)
		sprintf str, format, i
		list = AddListItem(str, list, ";", inf)
	endfor

	return list
End

/// @brief Searches the column colLabel in wv for an non-empty
/// entry with a row number smaller or equal to endRow
///
/// @param wv         text wave to search in
/// @param colLabel   column label from wv
/// @param endRow     maximum row index to consider
Function/S GetLastNonEmptyEntry(wv, colLabel, endRow)
	Wave/T wv
	string colLabel
	variable endRow

	WAVE/Z indizes = FindIndizes(colLabel=colLabel, wvText=wv, prop=PROP_NON_EMPTY, endRow=endRow)
	ASSERT(WaveExists(indizes), "expected a indizes wave")
	return wv[indizes[DimSize(indizes, ROWS) - 1]][%$colLabel]
End

/// @brief Return the amount of free memory in GB
///
/// Due to memory fragmentation you can not assume that you can still create a wave
/// occupying as much space as returned.
Function GetFreeMemory()
	string memStr = StringByKey("FREEMEM", IgorInfo(0))

	return str2num(memStr) / 1024 / 1024 / 1024
End

/// @brief Remove the given reguluar expression from the end of the string
///
/// In case the regular expression does not match, the string is returned unaltered.
///
/// See also `DisplayHelpTopic "Regular Expressions"`.
Function/S RemoveEndingRegExp(str, endingRegExp)
	string str, endingRegExp

	string endStr

	if(isEmpty(str) || isEmpty(endingRegExp))
		return str
	endif

	SplitString/E="(" + endingRegExp + ")$" str, endStr
	ASSERT(V_flag == 0 || V_flag == 1, "Unexpected number of matches")

	return RemoveEnding(str, endStr)
End

/// @brief Returns 1 if the user cancelled, zero if SaveExperiment was called
///
/// It is currently not possible to check if SaveExperiment was successfull
/// (E-Mail from Howard Rodstein WaveMetrics, 30 Jan 2015)
Function SaveExperimentWithDialog(path, filename)
	string path, filename

	variable refNum

	Open/D/M="Save experiment"/F="All Files:.*;"/P=$path refNum as filename

	if(isEmpty(S_fileName))
		return 1
	endif

	SaveExperiment as S_fileName
	return 0
End

/// @brief Search the row in refWave which has the same contents as the given row in the sourceWave
Function GetRowWithSameContent(refWave, sourceWave, row)
	Wave/T refWave, sourceWave
	variable row

	variable i, j, numRows, numCols
	numRows = DimSize(refWave, ROWS)
	numCols = DimSize(refWave, COLS)

	ASSERT(numCOLS == DimSize(sourceWave, COLS), "mismatched column sizes")

	for(i = 0; i < numRows; i += 1)
		for(j = 0; j < numCols; j += 1)
			if(!cmpstr(refWave[i][j], sourceWave[row][j]))
				if(j == numCols - 1)
					return i
				endif

				continue
			endif

			break
		endfor
	endfor

	return NaN
End

/// @brief Random shuffle of the wave contents
///
/// Function was taken from: http://www.igorexchange.com/node/1614
/// author s.r.chinn
///
/// @param inwave The wave that will have its rows shuffled.
Function InPlaceRandomShuffle(inwave)
	wave inwave

	variable N = numpnts(inwave)
	variable i, j, emax, temp
	for(i = N; i>1; i-=1)
		emax = i / 2
		j =  floor(emax + enoise(emax))		//	random index
// 		emax + enoise(emax) ranges in random value from 0 to 2*emax = i
		temp		= inwave[j]
		inwave[j]	= inwave[i-1]
		inwave[i-1]	= temp
	endfor
end

/// @brief Convert a 1D numeric wave to a list
Function/S Convert1DWaveToList(wv)
	Wave wv

	variable numEntries, i
	string list = ""

	numEntries = DimSize(wv, ROWS)
	for(i = 0; i < numEntries; i += 1)
		list = AddListItem(num2str(wv[i]), list, ";", Inf)
	endfor

	return list
End

/// @brief Return a unique trace name in the graph
///
/// Remember that it might be necessary to call `DoUpdate`
/// if you added possibly colliding trace names in the current
/// function run.
///
/// @param graph existing graph
/// @param baseName base name of the trace, must not be empty
Function/S UniqueTraceName(graph, baseName)
	string graph, baseName

	variable i = 1
	variable numTrials
	string trace, traceList

	ASSERT(windowExists(graph), "graph must exist")
	ASSERT(!isEmpty(baseName), "baseName must not be empty")

	traceList = TraceNameList(graph, ";", 0+1)
	// use an upper limit of trials to ease calculation
	numTrials = 2 * ItemsInList(traceList) + 1

	trace = baseName
	do
		if(WhichListItem(trace, traceList) == -1)
			return trace
		endif

		trace = baseName + "_" + num2str(i)
		i += 1

	while(i < numTrials)

	ASSERT(0, "Could not find a trace name")
End

/// @brief Checks wether the wave names of all waves in the list are equal
/// Returns 1 if true, 0 if false and NaN for empty lists
///
/// @param      listOfWaves list of waves with full path
/// @param[out] baseName    Returns the common baseName if the list has one,
///                         otherwise this will be an empty string.
Function WaveListHasSameWaveNames(listOfWaves, baseName)
	string listOfWaves
	string &baseName

	baseName = ""

	string str, firstBaseName
	variable numWaves, i
	numWaves = ItemsInList(listOfWaves)

	if(numWaves == 0)
		return NaN
	endif

	firstBaseName = GetBaseName(StringFromList(0, listOfWaves))
	for(i = 1; i < numWaves; i += 1)
		str = GetBaseName(StringFromList(i, listOfWaves))
		if(cmpstr(firstBaseName, str))
			return 0
		endif
	endfor

	baseName = firstBaseName
	return 1
End

/// @brief Zero the wave using differentiation and integration
///
/// Overwrites the input wave
///
/// 2D waves are zeroed along each row
Function ZeroWave(wv)
	WAVE wv

	Differentiate/DIM=0/EP=1 wv/D=wv
	Integrate/DIM=0 wv/D=wv
End

/// @brief Check wether the given background task is currently running
Function IsBackgroundTaskRunning(func)
	string func

	CtrlNamedBackground $func, status
	return NumberByKey("RUN", s_info)
End
