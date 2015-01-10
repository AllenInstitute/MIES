#pragma rtGlobals=3		// Use modern global access method and strict wave access.

/// @file TJ_MIES_Utilities.ipf
/// This file holds general utility functions available for all other procedures.

/// Convenience definition to nicify expressions like DimSize(wv, ROWS)
/// easier to read than DimSize(wv, 0).
/// @{
Constant ROWS                = 0
Constant COLS                = 1
Constant LAYERS              = 2
Constant CHUNKS              = 3
/// @}
Constant MAX_DIMENSION_COUNT = 4

/// @name Constants used by Downsample
/// @{
Constant DECIMATION_BY_OMISSION  = 1
Constant DECIMATION_BY_SMOOTHING = 2
Constant DECIMATION_BY_AVERAGING = 4
StrConstant ALL_WINDOW_FUNCTIONS = "Bartlett;Blackman367;Blackman361;Blackman492;Blackman474;Cos1;Cos2;Cos3;Cos4;Hamming;Hanning;KaiserBessel20;KaiserBessel25;KaiserBessel30;None;Parzen;Poisson2;Poisson3;Poisson4;Riemann"
/// @}

/// Common string to denote an invalid entry in a popupmenu
StrConstant NONE = "- none -"

/// Hook events constants
Constant EVENT_KILL_WINDOW_HOOK = 2

/// Used by CheckName and UniqueName
Constant CONTROL_PANEL_TYPE = 9

/// @name CountObjects and CountObjectsDFR constant
/// @{
Constant COUNTOBJECTS_WAVES      = 1
Constant COUNTOBJECTS_VAR        = 2
Constant COUNTOBJECTS_STR        = 3
Constant COUNTOBJECTS_DATAFOLDER = 4
/// @}

/// See "Control Structure eventMod Field"
Constant EVENT_MOUSE_UP = 2

// Conversion factor from ticks to seconds, exact value is 1/60
Constant TICKS_TO_SECONDS = 0.0166666666666667

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
/// @param var if zero an error message is printed into the history, nothing is done otherwise.
/// If the debugger is enabled, it also steps into it.
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
/// @returns list of wave names matching regExpStr located in dfr
Function/S GetListOfWaves(dfr, regExpStr, [options])
	dfref dfr
	string regExpStr, options

	variable i, j, numOptions, numWaves, matches, val
	// todo think about using PadString here for increased speed
	string list = "", name, str, opt

	ASSERT(DataFolderExistsDFR(dfr),"Non-existing datafolder")
	ASSERT(!isEmpty(regExpStr),"regexpStr is empty or null")

	numWaves = CountObjectsDFR(dfr, COUNTOBJECTS_WAVES)
	for(i=0; i<numWaves; i+=1)
		Wave wv = WaveRefIndexedDFR(dfr, i)
		name = NameOfWave(wv)

		if(!GrepString(name,regExpStr))
			continue
		endif

		matches = 1
		if(!ParamIsDefault(options) && !isEmpty(options))
			numOptions = ItemsInList(options)
			for(j = 0; j < numOptions; j += 1)
				str = StringFromList(j, options)
				opt = StringFromList(0, str, ":")
				val = str2num(StringFromList(1, str, ":"))
				ASSERT(IsFinite(val), "non finite value")
				ASSERT(!IsEmpty(opt), "empty option")

				strswitch(opt)
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
			list = AddListItem(name, list, ";", Inf)
		endif
	endfor

	return list
End

static Constant MINIMUM_WAVE_SIZE   = 64

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

static Constant MAXIMUM_WAVE_SIZE = 16384 // 2^14

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

/// @brief Returns the config wave for a given sweep wave
Function/Wave GetConfigWave(sweepWave)
    Wave sweepWave

	string name = "Config_" + NameOfWave(sweepWave)
	Wave/SDFR=GetWavesDataFolderDFR(sweepWave) config = $name
	ASSERT(DimSize(config,COLS)==4,"Unexpected number of columns")
	return config
End

/// @brief Returns the sampling interval of the sweep
/// in microseconds (1e-6s)
Function GetSamplingInterval(sweepWave)
    Wave sweepWave

	Wave config = GetConfigWave(sweepWave)

	// from ITCConfigAllChannels help file:
	// Third Column  = SamplingInterval:  integer value for sampling interval in microseconds (minimum value - 5 us)
	Duplicate/D/R=[][2]/FREE config samplingInterval

	// The sampling interval is the same for all channels
	ASSERT(numpnts(samplingInterval),"Expected non-empty wave")
	ASSERT(WaveMax(samplingInterval) == WaveMin(samplingInterval),"Expected constant sample interval for all channels")
	return samplingInterval[0]
End

/// @brief Write the given property to the config wave
///
/// @note Please add new properties as required
/// @param config configuration wave
/// @param samplingInterval sampling interval in microseconds (1e-6s)
Function UpdateSweepConfig(config, [samplingInterval])
	Wave config
	variable samplingInterval

	ASSERT(IsFinite(samplingInterval), "samplingInterval must be finite")
	config[][2] = samplingInterval
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

/// @brief Create a backup of the wave wv if it does not already exist.
///
/// The backup wave will be located in the same data folder and
/// its name will be the original name with suffix "_bak".
Function CreateBackupWaveIfNeeded(wv)
	Wave wv

	string backupname
	dfref dfr

	ASSERT(WaveExists(wv), "missing wave")
	backupname = NameOfWave(wv) + "_bak"
	dfr        = GetWavesDataFolderDFR(wv)

	Wave/Z/SDFR=dfr backup = $backupname

	if(WaveExists(backup))
		return NaN
	endif

	Duplicate/O wv, dfr:$backupname
End

/// @brief Replace the wave wv with its backup. If possible the backup wave will be killed afterwards.
///
/// @param wv                        wave to replace by its backup
/// @param nonExistingBackupIsFatal  behaviour for the case that there is no backup. Passing a non-zero value
///                                  will abort if the backup wave does not exist, for zero it will just do nothing.
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

	backupname = NameOfWave(wv) + "_bak"
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

/// @brief Parse a device string of the form X_DEV_Y, where X is from @ref DEVICE_TYPES
/// and Y from @ref DEVICE_NUMBERS.
///
/// Returns the result in deviceType and deviceNumber.
/// Currently the parsing is successfull if X and Y are non-empty.
/// @param[in]  device       input device string X_DEV_Y
/// @param[out] deviceType   returns the device type X
/// @param[out] deviceNumber returns the device number Y
/// @returns one on successfull parsing, zero on error
/// @todo replace all similiar usages in the rest of the code
Function ParseDeviceString(device, deviceType, deviceNumber)
	string device
	string &deviceType, &deviceNumber

	if(isEmpty(device))
		return 0
	endif

	deviceType   = StringFromList(0,device,"_")
	deviceNumber = StringFromList(2,device,"_")

	return !isEmpty(deviceType) && !isEmpty(deviceNumber)
End

/// @brief Builds the common device string X_DEV_Y, e.g. ITC1600_DEV_O and friends
/// @todo replace all similiar usages in the rest of the code
Function/S BuildDeviceString(deviceType, deviceNumber)
	string deviceType, deviceNumber

	ASSERT(!isEmpty(deviceType) && !isEmpty(deviceNumber), "empty device type or number");
	return deviceType + "_Dev_" + deviceNumber
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

/// @brief Remove all traces from a graph and try to kill their waves
Function RemoveTracesFromGraph(graph, [kill])
	string graph
	variable kill

	variable i, numEntries
	string traceList, trace

	if(ParamIsDefault(kill))
		kill = 0
	endif

	traceList  = TraceNameList(graph, ";", 1 )
	numEntries = ItemsInList(traceList)

	// iterating backwards is required, see http://www.igorexchange.com/node/1677#comment-2315
	for(i = numEntries - 1; i >= 0; i -= 1)
		trace = StringFromList(i, traceList)
		Wave/Z wv = TraceNameToWaveRef(graph, trace)
		RemoveFromGraph/W=$graph $trace

		if(kill)
			KillWaves/F/Z wv
		endif
	endfor
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
/// By default an alphanumeric sorting is done.
/// @param w        wave of arbitrary type
/// @param keycol   column of the key for the sorting
/// @param reversed [optional] Do an descending sort instead of an ascending one
///
/// Taken from http://www.igorexchange.com/node/599 with some cosmetic changes
Function MDsort(w, keycol, [reversed])
	Wave w
	variable keycol, reversed

	variable numRows, type

	type = WaveType(w)
	numRows = DimSize(w, 0)

	if(numRows == 0) // nothing to do
		return NaN
	endif

	Make/Y=(type)/Free/n=(numRows) key
	Make/Free/n=(numRows) valindex

	if(type == 0)
		Wave/t indirectSource = w
		Wave/t output = key
		output[] = indirectSource[p][keycol]
	else
		Wave indirectSource2 = w
		MultiThread key[] = indirectSource2[p][keycol]
	endif

	valindex = p
	if(reversed)
		Sort/A/R key, key, valindex
	else
		Sort/A key, key, valindex
	endif

	if(type == 0)
		Duplicate/free indirectSource, M_newtoInsert
		Wave/t output = M_newtoInsert
		output[][] = indirectSource[valindex[p]][q]
		indirectSource = output
	else
		Duplicate/free indirectSource2, M_newtoInsert
		MultiThread M_newtoinsert[][] = indirectSource2[valindex[p]][q]
		MultiThread indirectSource2 = M_newtoinsert
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

/// @brief Returns the numerical index for the sweep number column
/// in the settings history wave
Function GetSweepColumn(settingsHistory)
	Wave settingsHistory

	variable sweepCol

	// new label
	sweepCol = FindDimLabel(settingsHistory, COLS, "SweepNum")

	if(sweepCol >= 0)
		return sweepCol
	endif

	// Old label prior to 276b5cf6
	// was normally overwritten by SweepNum later in the code
	// but not always as it turned out
	sweepCol = FindDimLabel(settingsHistory, COLS, "SweepNumber")

	if(sweepCol >= 0)
		return sweepCol
	endif

	DEBUGPRINT("Could not find sweep number dimension label, trying with column zero")

	return 0
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

	Make/FREE/B/U/N=(DimSize(wv, ROWS)) matches = wv[p][col] == val

	Make/FREE levels
	FindLevels/P/Q/DEST=levels matches, 1

	if(V_flag == 2)
		return NaN
	endif

	numRows = DimSize(levels, ROWS)

	if(numRows == 1)
		first = levels[0]
		last  = levels[0]
		return NaN
	endif

	if(forwardORBackward)

		first = levels[0]
		last  = levels[0]

		for(i = 1; i < numRows; i += 1)
			// a forward search stops after the end of the first sequence
			if(levels[i] > last + 1)
				return NaN
			endif

			last = levels[i]
		endfor
	else

		first = levels[numRows - 1]
		last  = levels[numRows - 1]

		for(i = numRows - 2; i >= 0; i -= 1)
			// a backward search stops when the beginning of the last sequence was found
			if(levels[i] < first - 1)
				return NaN
			endif

			first = levels[i]
		endfor

	endif
End

/// @brief Returns a wave with all values of a setting from the settingsHistory wave
/// for a given sweep number.
///
/// Entries which are NaN for all headstages are ignored.
/// @returns a 2D wave where the columns are the setting for each headstage and the rows the different values. In case
/// the setting could not be found a invalid wave reference is returned.
Function/WAVE GetHistoryOfSetting(settingsHistory, sweepNo, setting)
	Wave settingsHistory
	variable sweepNo
	string setting

	variable settingCol, numHeadstages, i, sweepCol, entries
	variable first, last

	numHeadstages = DimSize(settingsHistory, LAYERS)

	settingCol = FindDimLabel(settingsHistory, COLS, setting)

	if(settingCol <= 0)
		DEBUGPRINT("Could not find the setting", str=setting)
		return $""
	endif

	sweepCol = GetSweepColumn(settingsHistory)
	FindRange(settingsHistory, sweepCol, sweepNo, 0, first, last)

	if(!IsFinite(first) || !IsFinite(last)) // sweep number is unknown
		return $""
	endif

	Make/FREE/D/N=(last - first + 1, numHeadstages) status = NaN
	Make/FREE/D/N=(numHeadstages) singleLayer

	SetDimLabel COLS, -1, Headstage, status

	for(i = first; i <= last; i += 1)

		singleLayer[] = settingsHistory[i][settingCol][p]
		WaveStats/Q/M=1 singleLayer

		// only add a new row to the result wave if the setting in question
		// was set in that row, which means that at least one value is not NaN
		if(V_numNaNs == numHeadstages)
			continue
		endif

		status[entries][] = singleLayer[q]
		entries += 1
	endfor

	Redimension/N=(entries, -1) status

	return status
End

/// @brief Returns a list of all devices, e.g. "ITC18USB_Dev_0;", which have acquired data.
Function/S GetAllDevicesWithData()

	variable i, j, numTypes, numNumbers
	string type, number, device
	string path, list = ""

	path = GetITCDevicesFolderAsString()

	if(!DataFolderExists(path))
		return ""
	endif

	numTypes   = ItemsInList(DEVICE_TYPES)
	numNumbers = ItemsInList(DEVICE_NUMBERS)
	for(i = 0; i < numTypes; i += 1)
		type = StringFromList(i, DEVICE_TYPES)

		path = GetDeviceTypePathAsString(type)

		if(!DataFolderExists(path))
			continue
		endif

		for(j = 0; j < numNumbers ; j += 1)
			number = StringFromList(j, DEVICE_NUMBERS)
			device = BuildDeviceString(type, number)
			path   = GetDeviceDataPathAsString(device)

			if(!DataFolderExists(path))
				continue
			endif

			if(CountObjects(path, COUNTOBJECTS_WAVES) == 0)
				continue
			endif

			list = AddListItem(device, list, ";", inf)
		endfor
	endfor

	return list
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
