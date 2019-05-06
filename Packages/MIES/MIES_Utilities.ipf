#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_UTILS
#endif

/// @file MIES_Utilities.ipf
/// @brief General utility functions

/// @brief Returns 1 if var is a finite/normal number, 0 otherwise
///
/// @hidecallgraph
/// @hidecallergraph
threadsafe Function IsFinite(var)
	variable var

	return numType(var) == 0
End

/// @brief Returns 1 if var is a NaN, 0 otherwise
///
/// @hidecallgraph
/// @hidecallergraph
threadsafe Function IsNaN(var)
	variable var

	return numType(var) == 2
End

/// @brief Returns 1 if str is null, 0 otherwise
/// @param str must not be a SVAR
///
/// @hidecallgraph
/// @hidecallergraph
threadsafe Function IsNull(str)
	string& str

	variable len = strlen(str)
	return numtype(len) == 2
End

/// @brief Returns one if str is empty or null, zero otherwise.
/// @param str must not be a SVAR
///
/// @hidecallgraph
/// @hidecallergraph
threadsafe Function IsEmpty(str)
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
/// \rst
/// .. code-block:: igorpro
///
/// 	ControlInfo/W = $panelTitle popup_MoreSettings_DeviceType
/// 	ASSERT(V_flag > 0, "Non-existing control or window")
/// 	do something with S_value
/// \endrst
///
/// @hidecallgraph
/// @hidecallergraph
Function ASSERT(var, errorMsg)
	variable var
	string errorMsg

	string stracktrace, miesVersionStr, lockedDevicesStr, device
	variable i, numLockedDevices

	try
		AbortOnValue var==0, 1
	catch
		// Recursion detection, if ASSERT appears multiple times in StackTrace
		if (ItemsInList(ListMatch(GetRTStackInfo(0), GetRTStackInfo(1))) > 1)

			// Happens e.g. when ASSERT is encounterd in cleanup functions
			print "Double Assertion Fail encountered !"
#ifndef AUTOMATED_TESTING
			ControlWindowToFront()
			Debugger
#endif // AUTOMATED_TESTING

			Abort
		endif

		print "!!! Assertion FAILED !!!"
		printf "Message: \"%s\"\r", RemoveEnding(errorMsg, "\r")

#ifndef AUTOMATED_TESTING
		// hard coding the path here so that we don't depend on GetMiesVersion()
		// in MIES_GlobalStringAndVariableAccess.ipf
		SVAR/Z miesVersion = root:MIES:version

		if(SVAR_Exists(miesVersion))
			miesVersionStr = miesVersion
		else
			miesVersionStr = ""
		endif

		SVAR/Z lockedDevices = root:MIES:HardwareDevices:ITCPanelTitleList

		Make/FREE/T sweeps = { NONE }
		Make/FREE/T tpStates = { NONE }
		Make/FREE/T daqStates = { NONE }

		if(!SVAR_Exists(lockedDevices) || strlen(lockedDevices) == 0)
			lockedDevicesStr = NONE
		else
			lockedDevicesStr = lockedDevices

			numLockedDevices = ItemsInList(lockedDevicesStr)

#if exists("AFH_GetLastSweepAcquired")
			Redimension/N=(numLockedDevices) sweeps, daqStates, tpStates

			for(i = 0; i < numLockedDevices; i += 1)
				device = StringFromList(i, lockedDevicesStr)
				NVAR runMode = $GetDataAcqRunMode(device)
				NVAR testpulseMode = $GetTestpulseRunMode(device)

				sweeps[i]    = num2str(AFH_GetLastSweepAcquired(device))
				tpStates[i]  = TestPulseRunModeToString(testpulseMode)
				daqStates[i] = DAQRunModeToString(runMode)
			endfor
#endif
		endif

		print "Please provide the following information if you contact the MIES developers:"
		print "################################"
		print "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
		print GetStackTrace()
		print "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
		printf "Time: %s\r", GetIso8601TimeStamp(localTimeZone = 1)
		printf "Locked device: [%s]\r", RemoveEnding(lockedDevicesStr, ";")
		printf "Current sweep: [%s]\r", RemoveEnding(TextWaveToList(sweeps, ";"), ";")
		printf "DAQ: [%s]\r", RemoveEnding(TextWaveToList(daqStates, ";"), ";")
		printf "Testpulse: [%s]\r", RemoveEnding(TextWaveToList(tpStates, ";"), ";")
		printf "Experiment: %s.pxp\r", GetExperimentName()
		printf "Igor Pro version: %s (%s)\r", GetIgorProVersion(), StringByKey("BUILD", IgorInfo(0))
		print "MIES version:"
		print miesVersionStr
		print "################################"
#endif // AUTOMATED_TESTING

		// --- Cleanup functions
#if !(IgorVersion() >= 8.04 && NumberByKey("BUILD", IgorInfo(0)) >= 33703)
		ASYNC_Stop(timeout=1, fromAssert=1)
#endif
		// --- End of cleanup functions

#ifndef AUTOMATED_TESTING
		ControlWindowToFront()
		Debugger
#endif // AUTOMATED_TESTING

		Abort
	endtry
End

/// @brief Low overhead function to check assertions (threadsafe variant)
///
/// @param var      if zero an error message is printed into the history and procedure execution is aborted,
///                 nothing is done otherwise.
/// @param errorMsg error message to output in failure case
///
/// Example usage:
/// \rst
///  .. code-block:: igorpro
///
///		ASSERT(DataFolderExistsDFR(dfr), "MyFunc: dfr does not exist")
///		do something with dfr
/// \endrst
///
/// Unlike ASSERT() this function does not print a stacktrace or jumps into the debugger. The reasons are Igor Pro limitations.
/// Therefore it is advised to prefix `errorMsg` with the current function name.
///
/// @hidecallgraph
/// @hidecallergraph
threadsafe Function ASSERT_TS(var, errorMsg)
	variable var
	string errorMsg

	try
		AbortOnValue var==0, 1
	catch
		printf "Assertion FAILED with message %s\r", errorMsg
		AbortOnValue 1, 1
	endtry
End

/// @brief Checks if the given name exists as window
///
/// @hidecallgraph
/// @hidecallergraph
Function windowExists(win)
	string win

	if(isNull(win) || WinType(win) == 0)
		return 0
	endif

	return 1
End

/// @brief Alternative implementation for WaveList/VariableList/etc. which honours a dfref and thus
/// does not require SetDataFolder calls.
///
/// @param dfr                                  datafolder reference to search for the waves
/// @param regExpStr                            regular expression matching the waves, see the help of GrepString
///                                             for an introduction to regular expressions
/// @param typeFlag [optional, default: COUNTOBJECTS_WAVES] One of @ref TypeFlags
/// @param matchList [optional, empty]          additional semicolon delimited list of wave names, allows to further
///                                             qualify the returned wave names.
/// @param waveProperty [optional, empty]       additional properties of matching waves, inspired by WaveList,
///                                             currently implemented are `MINCOLS` and `TEXT`
/// @param fullPath [optional, default: false]  should only the wavename or the absolute path of the wave be returned.
/// @param recursive [optional, default: false] descent into all subfolders recursively
///
/// @returns list of wave names matching regExpStr located in dfr
Function/S GetListOfObjects(dfr, regExpStr, [typeFlag, matchList, waveProperty, fullPath, recursive])
	dfref dfr
	string regExpStr, matchList, waveProperty
	variable fullPath, recursive, typeFlag

	variable i, j, numWaveProperties, numWaves, matches, val, numFolders
	string name, str, prop, subList, basePath
	string list = ""

	ASSERT(DataFolderExistsDFR(dfr),"Non-existing datafolder")
	ASSERT(!isEmpty(regExpStr),"regexpStr is empty or null")

	if(ParamIsDefault(fullPath))
		fullPath = 0
	else
		fullPath = !!fullPath
	endif

	if(ParamIsDefault(recursive))
		recursive = 0
	else
		recursive = !!recursive
	endif

	if(ParamIsDefault(typeFlag))
		typeFlag = COUNTOBJECTS_WAVES
	endif

	if(ParamIsDefault(waveProperty))
		waveProperty = ""
	endif

	if(ParamIsDefault(matchList))
		matchList = ""
	endif

	basePath = GetDataFolder(1, dfr)

	if(recursive)
		numFolders = CountObjectsDFR(dfr, COUNTOBJECTS_DATAFOLDER)
		for(i = 0; i < numFolders; i+=1)
			name = basePath + GetIndexedObjNameDFR(dfr, COUNTOBJECTS_DATAFOLDER, i)
			DFREF subFolder = $name
			subList = GetListOfObjects(subFolder, regExpStr, matchList=matchList, waveProperty=waveProperty, \
						               fullPath=fullPath, recursive=recursive)
			if(!IsEmpty(subList))
				list = AddListItem(RemoveEnding(subList, ";"), list)
			endif
		endfor
	endif

	numWaves = CountObjectsDFR(dfr, typeFlag)
	for(i=0; i<numWaves; i+=1)
		name = GetIndexedObjNameDFR(dfr, typeFlag, i)

		if(!GrepString(name,regExpStr))
			continue
		endif

		if(!IsEmpty(matchList) && WhichListItem(name, matchList, ";", 0, 0) == -1)
			continue
		endif

		matches = 1
		if(!isEmpty(waveProperty))
			ASSERT(typeFlag == COUNTOBJECTS_WAVES, "waveProperty does not make sense for type flags other than COUNTOBJECTS_WAVES")
			WAVE/SDFR=dfr wv = $name
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
						matches = matches & IsTextWave(wv) == !!val
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
				list = AddListItem(basePath + name, list, ";", Inf)
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
///
/// Can be used to fill a wave one at a time with the minimum number of
/// redimensions.
///
/// \rst
/// .. code-block:: igorpro
///
/// 	Make/FREE/N=(MINIMUM_WAVE_SIZE) data
/// 	SetNumberInWaveNote(data, NOTE_INDEX, 0)
/// 	// ...
/// 	for(...)
/// 		index = GetNumberFromWaveNote(data, NOTE_INDEX)
/// 		// ...
/// 		EnsureLargeEnoughWave(data, dimension = ROWS, minimumSize = index)
/// 		data[index] = ...
/// 		// ...
/// 	    SetNumberInWaveNote(data, NOTE_INDEX, ++index)
/// 	endfor
/// \endrst
///
/// @param wv              wave to redimension
/// @param minimumSize 	   [optional, default is implementation defined] the minimum size of the wave.
///                        The actual size of the wave after the function returns might be larger.
/// @param dimension       [optional, defaults to ROWS] dimension to resize, all other dimensions are left untouched.
/// @param initialValue    [optional, defaults to zero] initialValue of the new wave points
/// @param checkFreeMemory [optional, defaults to false] check if the free memory is enough for increasing the size
///
/// @return 0 on success, (only for checkFreeMemory = True) 1 if increasing the wave's size would fail due to little memory
Function EnsureLargeEnoughWave(wv, [minimumSize, dimension, initialValue, checkFreeMemory])
	Wave wv
	variable minimumSize, dimension, initialValue, checkFreeMemory

	if(ParamIsDefault(dimension))
		dimension = ROWS
	endif

	if(ParamIsDefault(checkFreeMemory))
		checkFreeMemory = 0
	else
		checkFreeMemory = !!checkFreeMemory
	endif

	ASSERT(dimension == ROWS || dimension == COLS || dimension == LAYERS || dimension == CHUNKS, "Invalid dimension")
	ASSERT(WaveExists(wv), "Wave does not exist")
	ASSERT(IsFinite(minimumSize) && minimumSize >= 0, "Invalid minimum size")

	if(ParamIsDefault(minimumSize))
		minimumSize = MINIMUM_WAVE_SIZE - 1
	else
		minimumSize = max(MINIMUM_WAVE_SIZE - 1, minimumSize)
	endif

	if(minimumSize < DimSize(wv, dimension))
		return 0
	endif

	minimumSize *= 2

	if(checkFreeMemory)
		if(GetWaveSize(wv) * (minimumSize / DimSize(wv, dimension)) / 1024 / 1024 / 1024 >= GetFreeMemory())
			return 1
		endif
	endif

	Make/FREE/L/N=(MAX_DIMENSION_COUNT) targetSizes = -1
	targetSizes[dimension] = minimumSize

	Make/FREE/L/N=(MAX_DIMENSION_COUNT) oldSizes = DimSize(wv,p)

	Redimension/N=(targetSizes[ROWS], targetSizes[COLS], targetSizes[LAYERS], targetSizes[CHUNKS]) wv

	if(!ParamIsDefault(initialValue))
		ASSERT(ValueCanBeWritten(wv, initialValue), "initialValue can not be stored in wv")
		switch(dimension)
			case ROWS:
				wv[oldSizes[ROWS],][][][] = initialValue
			break
			case COLS:
				wv[][oldSizes[COLS],][][] = initialValue
			break
			case LAYERS:
				wv[][][oldSizes[LAYERS],][] = initialValue
			break
			case CHUNKS:
				wv[][][][oldSizes[CHUNKS],] = initialValue
			break
		endswitch
	endif

	return 0
End

/// @brief Check that the given value can be stored in the wave
///
/// Does currently ignore floating point precision and ranges for integer waves
Function ValueCanBeWritten(wv, value)
	WAVE/Z wv
	variable value

	variable type

	if(!WaveExists(wv))
		return 0
	endif

	if(!IsNumericWave(wv))
		return 0
	endif

	type = WaveType(wv)

	// non-finite values must have a float wave
	if(!IsFinite(value))
		return (type & IGOR_TYPE_32BIT_FLOAT) || (type & IGOR_TYPE_64BIT_FLOAT)
	endif

	return 1
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

/// @brief Returns the size of the wave in bytes.
Function GetWaveSize(wv, [recursive])
	WAVE/Z wv
	variable recursive

	if(ParamIsDefault(recursive))
		recursive = 0
	else
		recursive = !!recursive
	endif

	if(!WaveExists(wv))
		return 0
	endif

	if(!recursive || !IsWaveRefWave(wv))
		return NumberByKey("SizeInBytes", WaveInfo(wv, 0))
	endif

	WAVE/WAVE waveRefs = wv

	Make/FREE/L/U/N=(DimSize(wv, ROWS)) sizes = GetWaveSize(waveRefs[p], recursive = 1)

	return GetWaveSize(wv, recursive = 0) + Sum(sizes)
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

/// @brief Checks if the datafolder referenced by dfr exists.
///
/// Unlike DataFolderExists() a dfref pointing to an empty ("") dataFolder is considered non-existing here.
/// @returns one if dfr is valid and references an existing or free datafolder, zero otherwise
/// Taken from http://www.igorexchange.com/node/2055
threadsafe Function DataFolderExistsDFR(dfr)
	dfref dfr

	string dataFolder

	switch(DataFolderRefStatus(dfr))
		case 0: // invalid ref, does not exist
			return 0
		case 1: // might be valid
			dataFolder = GetDataFolder(1,dfr)
			return cmpstr(dataFolder,"") != 0 && DataFolderExists(dataFolder)
		case 3: // free data folders always exist
			return 1
		default:
			ASSERT_TS(0, "impossible case")
			return 0
	endswitch
End

/// @brief Create a datafolder and all its parents,
///
/// @hidecallgraph
/// @hidecallergraph
///
/// Includes fast handling of the common case that the datafolder exists.
/// @returns reference to the datafolder
threadsafe Function/DF createDFWithAllParents(dataFolder)
	string dataFolder

	variable i, numItems
	string partialPath
	DFREF dfr = $dataFolder

	if(DataFolderRefStatus(dfr))
		return dfr
	endif

	partialPath = "root"

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

	return IsFinite(var) && trunc(var) == var
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
		ControlWindowToFront()
		return 1
	elseif(downsampleFactor <= 0 || downsampleFactor >= DimSize(wv,ROWS))
		print "Parameter downsampleFactor must be strictly positive and strictly smaller than the number of rows in wv."
		ControlWindowToFront()
		return 1
	elseif(!IsInteger(downsampleFactor))
		print "Parameter downsampleFactor must be an integer."
		ControlWindowToFront()
		return 1
	elseif(upsampleFactor <= 0 )
		print "Parameter upsampleFactor must be strictly positive."
		ControlWindowToFront()
		return 1
	elseif(!IsInteger(upsampleFactor))
		print "Parameter upsampleFactor must be an integer."
		ControlWindowToFront()
		return 1
	elseif(mode != DECIMATION_BY_SMOOTHING && !ParamIsDefault(winFunction))
		print "Invalid combination of a window function and mode."
		ControlWindowToFront()
		return 1
	elseif(!ParamIsDefault(winFunction) && FindListItem(winFunction, ALL_WINDOW_FUNCTIONS) == -1)
		print "Unknown windowing function: " + winFunction
		ControlWindowToFront()
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
			ControlWindowToFront()
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

/// @brief Returns an unsorted free wave with all unique entries from wv neglecting NaN/Inf.
///
/// uses built-in igor function FindDuplicates. Entries are deleted from left to right.
Function/Wave GetUniqueEntries(wv, [caseSensitive])
	Wave wv
	variable caseSensitive

	variable numRows, i

	if(IsTextWave(wv))
		if(ParamIsDefault(caseSensitive))
			caseSensitive = 1
		else
			caseSensitive = !!caseSensitive
		endif

		return GetUniqueTextEntries(wv, caseSensitive=caseSensitive)
	endif

	numRows = DimSize(wv, ROWS)
	ASSERT(numRows == numpnts(wv), "Wave must be 1D")

	Duplicate/FREE wv, result

	if(numRows <= 1)
		return result
	endif

	FindDuplicates/RN=result wv

	WaveTransform/O zapNaNs wv
	WaveTransform/O zapINFs wv

	return result
End

/// @brief Convenience wrapper around GetUniqueTextEntries() for string lists
Function/S GetUniqueTextEntriesFromList(list, [sep, caseSensitive])
	string list, sep
	variable caseSensitive

	if(ParamIsDefault(sep))
		sep = ";"
	else
		ASSERT(strlen(sep) == 1, "Separator should be one byte long")
	endif

	if(ParamIsDefault(caseSensitive))
		caseSensitive = 1
	else
		caseSensitive = !!caseSensitive
	endif

	WAVE/T wv = ListToTextWave(list, sep)
	WAVE/T unique = GetUniqueTextEntries(wv, caseSensitive=caseSensitive)

	return TextWaveToList(unique, sep)
End

/// @brief Search and Remove Duplicates from Text Wave wv
///
/// Duplicates are removed from left to right
///
/// @param wv             text wave reference
/// @param caseSensitive  [optional] Indicates whether comparison should be case sensitive. defaults to True
///
/// @return free wave with unique entries
static Function/Wave GetUniqueTextEntries(wv, [caseSensitive])
	Wave/T wv
	variable caseSensitive

	variable numEntries, numDuplicates, i

	if(ParamIsDefault(caseSensitive))
		caseSensitive = 1
	else
		caseSensitive = !!caseSensitive
	endif

	numEntries = DimSize(wv, ROWS)
	ASSERT(numEntries == numpnts(wv), "Wave must be 1D.")

	Duplicate/T/FREE wv result
	if(numEntries <= 1)
		return result
	endif

	if(caseSensitive)
		FindDuplicates/RT=result wv
	else
		Make/I/FREE index
		MAKE/T/FREE/N=(numEntries) duplicates = LowerStr(wv[p])
		FindDuplicates/INDX=index duplicates
		numDuplicates = DimSize(index, ROWS)
		for(i = numDuplicates - 1; i >= 0; i -= 1)
			DeletePoints index[i], 1, result
		endfor
	endif

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

/// @brief Removes all empty datafolders in the passed datafolder reference
Function RemoveAllEmptyDataFolders(sourceDFR)
	DFREF sourceDFR

	variable numFolder, i
	string folder

	if(!DataFolderExistsDFR(sourceDFR))
		return NaN
	endif

	numFolder = CountObjectsDFR(sourceDFR, COUNTOBJECTS_DATAFOLDER)

	if(!numFolder)
		return NaN
	endif

	for(i = numFolder - 1; i >= 0; i -= 1)
		folder = GetDataFolder(1, sourceDFR) + GetIndexedObjNameDFR(sourceDFR, COUNTOBJECTS_DATAFOLDER, i)
		RemoveEmptyDataFolder($folder)
	endfor
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
/// \rst
/// .. code-block:: igorpro
///
/// 	variable debuggerState = DisableDebugger()
/// 	// code which might trigger the debugger, e.g. CurveFit
/// 	ResetDebuggerState(debuggerState)
/// 	// now the debugger is in the same state as before
/// \endrst
Function ResetDebuggerState(debuggerState)
	variable debuggerState

	variable debugOnError, nvarChecking

	if(debuggerState & DEBUGGER_ENABLED)
		debugOnError = debuggerState & DEBUGGER_DEBUG_ON_ERROR
		nvarChecking = debuggerState & DEBUGGER_NVAR_CHECKING
		DebuggerOptions enable=1, debugOnError=debugOnError, NVAR_SVAR_WAVE_Checking=nvarChecking
	endif
End

/// @brief Disable Debug on Error
///
/// @returns 1 if it was enabled, 0 if not, pass this value to ResetDebugOnError()
Function DisableDebugOnError()

	DebuggerOptions
	if(V_enable && V_debugOnError)
		DebuggerOptions enable=1, debugOnError=0
		return 1
	endif

	return 0
End

/// @brief Reset Debug on Error state
///
/// @param debugOnError state before, usually the same value as DisableDebugOnError() returned
Function ResetDebugOnError(debugOnError)
	variable debugOnError

	if(!debugOnError)
		return NaN
	endif

	DebuggerOptions enable=1, debugOnError=debugOnError
End

/// @brief Returns the numeric value of `key` found in the wave note,
/// returns NaN if it could not be found
///
/// The expected wave note format is: `key1:val1;key2:val2;`
threadsafe Function GetNumberFromWaveNote(wv, key)
	Wave wv
	string key

	ASSERT_TS(WaveExists(wv), "Missing wave")
	ASSERT_TS(!IsEmpty(key), "Empty key")

	return NumberByKey(key, note(wv))
End

/// @brief Updates the numeric value of `key` found in the wave note to `val`
///
/// @param wv     wave
/// @param key    key of the Key/Value pair
/// @param val    value of the Key/Value pair
/// @param format [optional] printf compatible format string to set
///               the conversion to string for `val`
///
/// The expected wave note format is: `key1:val1;key2:val2;`
Function SetNumberInWaveNote(wv, key, val, [format])
	Wave wv
	string key
	variable val
	string format

	string str

	ASSERT(WaveExists(wv), "Missing wave")
	ASSERT(!IsEmpty(key), "Empty key")

	if(!ParamIsDefault(format))
		ASSERT(!IsEmpty(format), "Empty format")
		sprintf str, format, val
		Note/K wv, ReplaceStringByKey(key, note(wv), str)
	else
		Note/K wv, ReplaceNumberByKey(key, note(wv), val)
	endif
End

/// @brief Return the string value of `key` found in the wave note
/// default expected wave note format: `key1:val1;key2:str2;`
/// counterpart of AddEntryIntoWaveNoteAsList when supplied with keySep = "="
///
/// @param wv   wave reference where the WaveNote is taken from
/// @param key  search for the value at key:value;
/// @param keySep  [optional, defaults to `:`] separation character for (key, value) pairs
/// @param listSep [optional, defaults to `;`] list separation character
///
/// @returns the value on success. An empty string is returned if it could not be found
Function/S GetStringFromWaveNote(wv, key, [keySep, listSep])
	Wave wv
	string key
	string keySep, listSep

	if(ParamIsDefault(keySep) && ParamIsDefault(listSep))
		return ExtractStringFromPair(note(wv), key)
	elseif(ParamIsDefault(keySep))
		return ExtractStringFromPair(note(wv), key, listSep = listSep)
	elseif(ParamIsDefault(listSep))
		return ExtractStringFromPair(note(wv), key, keySep = keySep)
	else
		return ExtractStringFromPair(note(wv), key, keySep = keySep, listSep = listSep)
	endif
End

/// @brief Same functionality as GetStringFromWaveNote() but accepts a string
///
/// @sa GetStringFromWaveNote()
Function/S ExtractStringFromPair(str, key, [keySep, listSep])
	string str
	string key
	string keySep, listSep

	if(ParamIsDefault(keySep))
		keySep = ":"
	endif
	if(ParamIsDefault(listSep))
		listSep = ";"
	endif

	ASSERT(!IsEmpty(str), "Empty string")
	ASSERT(!IsEmpty(key), "Empty key")

	// AddEntryIntoWaveNoteAsList creates whitespaces "key = value;"
	str = ReplaceString(" " + keySep + " ", str, keySep)

	return StringByKey(key, str, keySep, listSep)
End

/// @brief Update the string value of `key` found in the wave note to `str`
///
/// The expected wave note format is: `key1:val1;key2:str2;`
Function SetStringInWaveNote(wv, key, str)
	Wave wv
	string key, str

	ASSERT(WaveExists(wv), "Missing wave")
	ASSERT(!IsEmpty(key), "Empty key")

	Note/K wv, ReplaceStringByKey(key, note(wv), str)
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
/// @param wv            wave to add the wave note to
/// @param key           string identifier
/// @param var           variable to output
/// @param str           string to output
/// @param appendCR      0 (default) or 1, should a carriage return ("\r") be appended to the note
/// @param replaceEntry  0 (default) or 1, should existing keys named `key` be replaced (does only work reliable
///                      in wave note lists without carriage returns).
/// @param format        [optional, defaults to `%g`] format string used for converting `var` to `str`
Function AddEntryIntoWaveNoteAsList(wv, key, [var, str, appendCR, replaceEntry, format])
	Wave wv
	string key
	variable var
	string str
	variable appendCR, replaceEntry
	string format

	string formattedString, formatString

	ASSERT(WaveExists(wv), "missing wave")
	ASSERT(!IsEmpty(key), "empty key")
	ASSERT(strsearch(key, ";", 0) == -1, "key can not contain a semicolon")

	if(ParamIsDefault(format))
		formatString = "%s = %g;"
	else
		ASSERT(strsearch(format, ";", 0) == -1, "format can not contain a semicolon")
		formatString = "%s = " + format + ";"
	endif

	if(!ParamIsDefault(var))
		sprintf formattedString, formatString, key, var
	elseif(!ParamIsDefault(str))
		ASSERT(strsearch(str, ";", 0) == -1, "str can not contain a semicolon")
		formattedString = key + " = " + str + ";"
	else
		formattedString = key + ";"
	endif

	appendCR     = ParamIsDefault(appendCR)     ? 0 : appendCR
	replaceEntry = ParamIsDefault(replaceEntry) ? 0 : replaceEntry

	if(replaceEntry)
		Note/K wv, RemoveByKey(key + " ", note(wv), "=")
	endif

	if(appendCR)
		Note/NOCR wv, formattedString + "\r"
	else
		Note/NOCR wv, formattedString
	endif
End

/// @brief Checks if `key = value;` can be found in the wave note
///
/// Ignores spaces around the equal ("=") sign.
///
/// @sa AddEntryIntoWaveNoteAsList()
Function HasEntryInWaveNoteList(wv, key, value)
	WAVE wv
	string key, value

	return GrepString(note(wv), "\\Q" + key + "\\E\\s*=\\s*\\Q" + value + "\\E\\s*;")
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

		WAVE candidates = ConvertListOfWaves(GetListOfObjects(dfr, ".*", fullpath=1))
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

/// @brief Kill all cursors in a given list of graphs
///
/// @param graphs     semicolon separated list of graph names
/// @param cursorName name of cursor as string
Function KillCursorInGraphs(graphs, cursorName)
	String graphs, cursorName

	string graph
	variable i, numGraphs

	ASSERT(strlen(cursorName) == 1, "Invalid Cursor Name.")
	ASSERT(char2num(cursorName) > 64 && char2num(cursorName) < 75, "Cursor name out of range.")

	numGraphs = ItemsInList(graphs)
	for(i = 0; i < numGraphs; i += 1)
		graph = StringFromList(i, graphs)
		if(!WindowExists(graph))
			continue
		endif
		Cursor/K/W=$graph $cursorName
	endfor
End

/// @brief Find the first match for a given cursor in a list of graph names
///
/// @param graphs     semicolon separated list of graph names
/// @param cursorName name of cursor as string
///
/// @return graph where cursor was found
Function/S FindCursorInGraphs(graphs, cursorName)
	String graphs, cursorName

	string graph, csr
	variable i, numGraphs

	ASSERT(strlen(cursorName) == 1, "Invalid Cursor Name.")
	ASSERT(char2num(cursorName) > 64 && char2num(cursorName) < 75, "Cursor name out of range.")

	numGraphs = ItemsInList(graphs)
	for(i = 0; i < numGraphs; i += 1)
		graph = StringFromList(i, graphs)
		if(!WindowExists(graph))
			continue
		endif
		csr = CsrInfo($cursorName, graph)
		if(!IsEmpty(csr))
			return graph
		endif
	endfor
End

/// @brief get the x value of the cursors A and B
///
/// @param[in]  graph where the cursor are
/// @param[out] csrAx Position of cursor A
/// @param[out] csrBx Position of cursor B
Function GetCursorXPositionAB(graph, csrAx, csrBx)
	string graph
	variable &csrAx, &csrBx

	string csrA, csrB

	ASSERT(WindowExists(graph), "Graph for given cursors does not exist.")

	csrA = CsrInfo(A, graph)
	csrB = CsrInfo(B, graph)

	if(isEmpty(csrA) || isEmpty(csrB))
		csrAx = -inf
		csrBx = inf
	else
		csrAx = xcsr(A, graph)
		csrBx = xcsr(B, graph)
	endif
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
	elseif(!ParamIsDefault(keyColSecondary) && ParamIsDefault(keyColTertiary))
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
		MultiThread indirectSourceText = newtoInsertText
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
		if((!cmpstr(curr, " ") || !cmpstr(curr, "\t")) && !IsFinite(str2numSafe(next)) && cmpstr(next, " ") && cmpstr(next, "\t"))
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
/// and returns all matching row indizes in a wave. By defaults only looks into the first layer
/// for backward compatibility reasons.
///
/// Exactly one of `var`/`str`/`prop` has to be given except for
/// `prop == PROP_MATCHES_VAR_BIT_MASK` and `prop == PROP_NOT_MATCHES_VAR_BIT_MASK`
/// which requires a `var`/`str` parameter as well.
///
/// Exactly one of `col`/`colLabel` has to be given.
///
/// @param numericOrTextWave   wave to search in
/// @param col [optional]      column to search in only
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
Function/Wave FindIndizes(numericOrTextWave, [col, colLabel, var, str, prop, startRow, endRow, startLayer, endLayer])
	WAVE numericOrTextWave
	variable col, var, prop
	string str, colLabel
	variable startRow, endRow
	variable startLayer, endLayer

	variable numCols, numRows, numLayers

	ASSERT(ParamIsDefault(col) + ParamIsDefault(colLabel) == 1, "Expected exactly one col/colLabel argument")
	ASSERT(ParamIsDefault(prop) + ParamIsDefault(var) + ParamIsDefault(str) == 2              \
		   || (!ParamIsDefault(prop)                                                          \
			  && (prop == PROP_MATCHES_VAR_BIT_MASK || prop == PROP_NOT_MATCHES_VAR_BIT_MASK) \
			  && (ParamIsDefault(var) + ParamIsDefault(str)) == 1),                           \
			  "Invalid combination of var/str/prop arguments")

	ASSERT(WaveExists(numericOrTextWave), "numericOrTextWave does not exist")

	if(DimSize(numericOrTextWave, ROWS) == 0)
		return $""
	endif

	numRows   = DimSize(numericOrTextWave, ROWS)
	numCols   = DimSize(numericOrTextWave, COLS)
	numLayers = DimSize(numericOrTextWave, LAYERS)
	ASSERT(DimSize(numericOrTextWave, CHUNKS) <= 1, "No support for chunks")

	if(!ParamIsDefault(colLabel))
		col = FindDimLabel(numericOrTextWave, COLS, colLabel)
		ASSERT(col >= 0, "invalid column label")
	endif

	ASSERT(col == 0 || (col > 0 && col < numCols), "Invalid column")

	if(IsTextWave(numericOrTextWave))
		WAVE/T wvText = numericOrTextWave
		WAVE/Z wv     = $""
	else
		WAVE/T/Z wvText = $""
		WAVE wv         = numericOrTextWave
	endif

	if(!ParamIsDefault(prop))
		ASSERT(prop == PROP_NON_EMPTY                    \
			   || prop == PROP_EMPTY                     \
			   || prop == PROP_MATCHES_VAR_BIT_MASK      \
			   || prop == PROP_NOT_MATCHES_VAR_BIT_MASK, \
			   "Invalid property")

		if(prop == PROP_MATCHES_VAR_BIT_MASK || prop == PROP_NOT_MATCHES_VAR_BIT_MASK)
			if(ParamIsDefault(var))
				var = str2numSafe(str)
			elseif(ParamIsDefault(str))
				str = num2str(var)
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
		ASSERT(startRow >= 0 && startRow < numRows, "Invalid startRow")
	endif

	if(ParamIsDefault(endRow))
		endRow  = inf
	else
		ASSERT(endRow >= 0 && endRow < numRows, "Invalid endRow")
	endif

	ASSERT(startRow <= endRow, "endRow must be larger than startRow")

	if(ParamIsDefault(startLayer))
		startLayer = 0
	else
		ASSERT(startLayer >= 0 && (numLayers == 0 || startLayer < numLayers), "Invalid startLayer")
	endif

	if(ParamIsDefault(endLayer))
		// only look in the first layer by default
		endLayer = 0
	else
		ASSERT(endLayer >= 0 && (numLayers == 0 || endLayer < numLayers), "Invalid endLayer")
	endif

	ASSERT(startLayer <= endLayer, "endLayer must be larger than startLayer")

	// Algorithm:
	// * The matches wave has the same size as one column of the input wave
	// * -1 means no match, every value larger or equal than zero is the row index of the match
	// * There is no distinction between different layers matching
	// * After the matches have been calculated we take the maximum of the transposed matches
	//   wave in each colum transpose back and replace -1 with NaN
	// * This gives a 1D wave with NaN in the rows with no match, and the row index of the match otherwise
	// * Delete all NaNs in the wave and return it
	Make/FREE/R/N=(numRows, numLayers) matches = -1

	if(WaveExists(wv))
		if(!ParamIsDefault(prop))
			if(prop == PROP_EMPTY)
				MultiThread matches[startRow, endRow][startLayer, endLayer] = (numtype(wv[p][col][q]) == 2 ? p : -1)
			elseif(prop == PROP_NON_EMPTY)
				MultiThread matches[startRow, endRow][startLayer, endLayer] = (numtype(wv[p][col][q]) != 2 ? p : -1)
			elseif(prop == PROP_MATCHES_VAR_BIT_MASK)
				MultiThread matches[startRow, endRow][startLayer, endLayer] = (wv[p][col][q] & var ? p : -1)
			elseif(prop == PROP_NOT_MATCHES_VAR_BIT_MASK)
				MultiThread matches[startRow, endRow][startLayer, endLayer] = (!(wv[p][col][q] & var) ? p : -1)
			endif
		else
			ASSERT(!IsNaN(var), "Use PROP_EMPTY to search for NaN")
			MultiThread matches[startRow, endRow][startLayer, endLayer] = ((wv[p][col][q] == var) ? p : -1)
		endif
	else
		if(!ParamIsDefault(prop))
			if(prop == PROP_EMPTY)
				MultiThread matches[startRow, endRow][startLayer, endLayer] = (!cmpstr(wvText[p][col][q], "") ? p : -1)
			elseif(prop == PROP_NON_EMPTY)
				MultiThread matches[startRow, endRow][startLayer, endLayer] = (cmpstr(wvText[p][col][q], "") ? p : -1)
			elseif(prop == PROP_MATCHES_VAR_BIT_MASK)
				MultiThread matches[startRow, endRow][startLayer, endLayer] = (str2num(wvText[p][col][q]) & var ? p : -1)
			elseif(prop == PROP_NOT_MATCHES_VAR_BIT_MASK)
				MultiThread matches[startRow, endRow][startLayer, endLayer] = (!(str2num(wvText[p][col][q]) & var) ? p : -1)
			endif
		else
			MultiThread matches[startRow, endRow][startLayer, endLayer] = (!cmpstr(wvText[p][col][q], str) ? p : -1)
		endif
	endif

	MatrixOp/Free result = replace(maxCols(matches^t)^t, -1, NaN)
	WaveTransform/O zapNaNs, result

	if(DimSize(result, ROWS) == 0)
		return $""
	endif

	return result
End

#if (IgorVersion() >= 8.00)

/// @brief Returns a reference to a newly created datafolder
///
/// Basically a datafolder aware version of UniqueName for datafolders
///
/// @param dfr 	    datafolder reference where the new datafolder should be created
/// @param baseName first part of the datafolder, might be shortend due to Igor Pro limitations
Function/DF UniqueDataFolder(dfr, baseName)
	dfref dfr
	string baseName

	string path

	ASSERT(!isEmpty(baseName), "baseName must not be empty" )

	path = UniqueDataFolderName(dfr, basename)

	if(isEmpty(path))
		return $""
	endif

	NewDataFolder $path
	return $path
End

/// @brief Return a unique data folder name which does not exist in dfr
///
/// If you want to have the datafolder created for you and don't need a
/// threadsafe function, use UniqueDataFolder() instead.
///
/// @param dfr      datafolder to search
/// @param baseName first part of the datafolder, must be a *valid* Igor Pro object name
threadsafe Function/S UniqueDataFolderName(dfr, baseName)
	DFREF dfr
	string baseName

	variable index, numRuns
	string basePath, path

	ASSERT_TS(!isEmpty(baseName), "baseName must not be empty" )
	ASSERT_TS(DataFolderExistsDFR(dfr), "dfr does not exist")

	numRuns = 10000
	// shorten basename so that we can attach some numbers
	baseName = baseName[0, MAX_OBJECT_NAME_LENGTH_IN_BYTES - (ceil(log(numRuns)) + 1)]
	baseName = CleanupName(baseName, 0)
	basePath = GetDataFolder(1, dfr)
	path = basePath + baseName

	do
		if(!DataFolderExists(path))
			return path
		endif

		path = basePath + baseName + "_" + num2istr(index)

		index += 1
	while(index < numRuns)

	DEBUGPRINT_TS("Could not find a unique folder with trials:", var = numRuns)

	return ""
End

#else

/// @brief Returns a reference to a newly created datafolder
///
/// Basically a datafolder aware version of UniqueName for datafolders
///
/// @param dfr 	    datafolder reference where the new datafolder should be created
/// @param baseName first part of the datafolder, might be shortend due to Igor Pro limitations
Function/DF UniqueDataFolder(dfr, baseName)
	dfref dfr
	string baseName

	string path

	ASSERT(!isEmpty(baseName), "baseName must not be empty" )

	// shorten basename so that we can attach some numbers
	baseName = CleanupName(baseName[0, 26], 0)

	path = UniqueDataFolderName(dfr, basename)

	if(isEmpty(path))
		return $""
	endif

	NewDataFolder $path
	return $path
End

/// @brief Return a unique data folder name which does not exist in dfr
///
/// If you want to have the datafolder created for you and don't need a
/// threadsafe function, use UniqueDataFolder() instead.
///
/// @param dfr      datafolder to search
/// @param baseName first part of the datafolder, must be a *valid* Igor Pro object name
///
/// @todo use CleanupName for baseName once that is threadsafe
threadsafe Function/S UniqueDataFolderName(dfr, baseName)
	DFREF dfr
	string baseName

	variable index
	string basePath, path

	ASSERT_TS(!isEmpty(baseName), "baseName must not be empty" )
	ASSERT_TS(DataFolderExistsDFR(dfr), "dfr does not exist")

	basePath = GetDataFolder(1, dfr)
	path = basePath + baseName

	do
		if(!DataFolderExists(path))
			return path
		endif

		path = basePath + baseName + "_" + num2istr(index)

		index += 1
	while(index < 10000)

	DEBUGPRINT_TS("Could not find a unique folder with 10000 trials")

	return ""
End

#endif

/// @brief Returns a wave name not used in the given datafolder
///
/// Basically a datafolder aware version of UniqueName for datafolders
///
/// @param dfr 	    datafolder reference where the new datafolder should be created
/// @param baseName first part of the wave name, might be shorted due to Igor Pro limitations
Function/S UniqueWaveName(dfr, baseName)
	dfref dfr
	string baseName

	variable index
	string name
	string path

	ASSERT(!isEmpty(baseName), "baseName must not be empty" )
	ASSERT(DataFolderExistsDFR(dfr), "dfr does not exist")

	// shorten basename so that we can attach some numbers
	baseName = CleanupName(baseName[0, 26], 0)
	path = GetDataFolder(1, dfr)
	name = baseName

	do
		if(!WaveExists($(path + name)))
			return name
		endif

		name = baseName + "_" + num2istr(index)

		index += 1
	while(index < 10000)

	DEBUGPRINT("Could not find a unique folder with 10000 trials")

	return ""
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
		text = text[0,MAX_OBJECT_NAME_LENGTH_IN_BYTES - 1]
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

/// @brief Return a formatted timestamp of the form `YY_MM_DD_HHMMSS`
///
/// Uses the local time zone and *not* UTC.
///
/// @param humanReadable [optional, default to false]                                Return a format viable for display in a GUI
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

/// @brief Return true if the given absolute path refers to an existing drive letter
Function IsDriveValid(absPath)
	string absPath

	string path, drive

	// convert to ":" folder separators
	path  = ParseFilePath(5, absPath, ":", 0, 0)
	drive = StringFromList(0, path, ":")

	GetFileFolderInfo/Q/Z drive

	return !V_flag
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
		ASSERT(IsWaveRefWave(refWave), "wv must be a wave holding wave references")
		numEntries = DimSize(wv, ROWS)
		for(i = 0; i < numEntries; i += 1)
			WAVE/WAVE cmpWave = wv
			if(WaveRefsEqual(cmpWave[i], refWave))
				return i
			endif
		endfor
	else
		if(IsNumericWave(wv))
			if(!ParamIsDefault(str))
				val = str2num(str)
			endif

			FindValue/V=(val) wv

			if(V_Value >= 0)
				return V_Value
			endif
		elseif(IsTextWave(wv))
			if(!ParamIsDefault(val))
				str = num2str(val)
			endif

			FindValue/TEXT=(str)/TXOP=4 wv

			if(V_Value >= 0)
				return V_Value
			endif
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

/// @brief Convert a list of strings to a text wave.
///
/// Counterpart @see TextWaveToList
/// @see ListToNumericWave
Function/WAVE ConvertListToTextWave(list, [listSepString])
	string list, listSepString
	if(ParamIsDefault(listSepString))
		listSepString = ";"
	endif

	return ListToTextWave(list, listSepString)
End

/// @brief return a subset of the input list
///
/// @param list       input list
/// @param itemBegin  first item
/// @param itemEnd    last item
/// @param listSep    [optional] list Separation character. default is ";"
///
/// @return a list with elements ranging from itemBegin to itemEnd of the input list
Function/S ListFromList(list, itemBegin, itemEnd, [listSep])
	string list, listSep
	variable itemBegin, itemEnd

	variable i,  numItems, start, stop

	if(ParamIsDefault(listSep))
		listSep = ";"
	endif

	ASSERT(itemBegin <= itemEnd, "SubSet missmatch")

	numItems = ItemsInList(list, listSep)
	if(itemBegin >= numItems)
		return ""
	endif
	if(itemEnd >= numItems)
		itemEnd = numItems - 1
	endif

	if(itemBegin == itemEnd)
		return StringFromList(itemBegin, list, listSep) + listSep
	endif

	for(i = 0; i < itemBegin; i += 1)
		start = strsearch(list, listSep, start) + 1
	endfor

	stop = start
	for(i = itemBegin; i < itemEnd + 1; i += 1)
		stop = strsearch(list, listSep, stop) + 1
	endfor

	return list[start, stop - 1]
End

/// @brief calculates the relative complement of list2 in list1
///
/// Every list item of `list1` must be in `list2`.
///
/// also called the set-theoretic difference of list1 and list2
/// @returns difference as list
Function/S GetListDifference(list1, list2)
	string list1, list2

	variable i, numList1
	string item
	string result = ""

	numList1 = ItemsInList(list1)
	for(i = 0; i < numList1; i += 1)
		item = StringFromList(i, list1)
		if(WhichlistItem(item, list2) == -1)
			result = AddListItem(item, result)
		endif
	endfor

	return result
End

/// @brief Return a list of datafolders located in `dfr`
///
/// @param dfr base folder
/// @param absolute [optional, defaults to false] return absolute paths
Function/S GetListOfDataFolders(dfr, [absolute])
	DFREF dfr
	variable absolute

	string list, datafolder

	if(ParamIsDefault(absolute))
		absolute = 0
	else
		absolute = !!absolute
	endif

	list = DataFolderDir(0x01, dfr)
	list = StringByKey("FOLDERS", list , ":")
	list = ReplaceString(",", list, ";")

	if(!absolute)
		return list
	endif

	datafolder = GetDataFolder(1, dfr)
	return AddPrefixToEachListItem(datafolder, list)
End

/// @brief Return the base name of the file
///
/// Given `path/file.suffix` this gives `file`.
///
/// @param filePathWithSuffix full path
/// @param sep                [optional, defaults to ":"] character
///                           separating the path components
Function/S GetBaseName(filePathWithSuffix, [sep])
	string filePathWithSuffix, sep

	if(ParamIsDefault(sep))
		sep = ":"
	endif

	return ParseFilePath(3, filePathWithSuffix, sep, 1, 0)
End

/// @brief Return the file extension (suffix)
///
/// Given `path/file.suffix` this gives `suffix`.
///
/// @param filePathWithSuffix full path
/// @param sep                [optional, defaults to ":"] character
///                           separating the path components
Function/S GetFileSuffix(filePathWithSuffix, [sep])
	string filePathWithSuffix, sep

	if(ParamIsDefault(sep))
		sep = ":"
	endif

	return ParseFilePath(4, filePathWithSuffix, sep, 0, 0)
End

/// @brief Return the folder of the file
///
/// Given `path/file.suffix` this gives `path`.
///
/// @param filePathWithSuffix full path
/// @param sep                [optional, defaults to ":"] character
///                           separating the path components
Function/S GetFolder(filePathWithSuffix, [sep])
	string filePathWithSuffix, sep

	if(ParamIsDefault(sep))
		sep = ":"
	endif

	return ParseFilePath(1, filePathWithSuffix, sep, 1, 0)
End

/// @brief Return the filename with extension
///
/// Given `path/file.suffix` this gives `file.suffix`.
///
/// @param filePathWithSuffix full path
/// @param sep                [optional, defaults to ":"] character
///                           separating the path components
Function/S GetFile(filePathWithSuffix, [sep])
	string filePathWithSuffix, sep

	if(ParamIsDefault(sep))
		sep = ":"
	endif

	return ParseFilePath(0, filePathWithSuffix, sep, 1, 0)
End

/// @brief Return the path converted to a windows style path
Function/S GetWindowsPath(path)
	string path

	return ParseFilepath(5, path, "\\", 0, 0)
End

/// @brief Set the given bit mask in var
threadsafe Function SetBit(var, bit)
	variable var, bit

	return var | bit
End

/// @brief Clear the given bit mask in var
threadsafe Function ClearBit(var, bit)
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
/// Return an empty string if nothing could be found.
///
/// @param wv         text wave to search in
/// @param colLabel   column label from wv
/// @param endRow     maximum row index to consider
Function/S GetLastNonEmptyEntry(wv, colLabel, endRow)
	Wave/T wv
	string colLabel
	variable endRow

	WAVE/Z indizes = FindIndizes(wv, colLabel=colLabel, prop=PROP_NON_EMPTY, endRow=endRow)

	if(!WaveExists(indizes))
		return ""
	endif

	return wv[indizes[DimSize(indizes, ROWS) - 1]][%$colLabel]
End

/// @brief Return the amount of free memory in GB
///
/// Due to memory fragmentation you can not assume that you can still create a wave
/// occupying as much space as returned.
Function GetFreeMemory()
	variable freeMem

#if defined(IGOR64)
	freeMem = NumberByKey("PHYSMEM", IgorInfo(0)) - NumberByKey("USEDPHYSMEM", IgorInfo(0))
#else
	freeMem = NumberByKey("FREEMEM", IgorInfo(0))
#endif

	return freeMem / 1024 / 1024 / 1024
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

/// @brief Search for a Word inside a String
///
/// @param[in]  str    input text in which word should be searched
/// @param[in]  word   searchpattern (non-regex-sensitive)
/// @param[out] prefix (optional) string preceding word. ("" for unmatched pattern)
/// @param[out] suffix (optional) string succeeding word.
///
/// example of the usage of SearchStringBase (basically the same as WM GrepString())
/// \rst
/// .. code-block:: igorpro
///
/// 	Function SearchString(str, substring)
/// 		string str, substring
///
/// 		ASSERT(strlen(substring) > 0, "supplied substring has zero length")
/// 		WAVE/Z/T wv = SearchStringBase(str, "(.*)\\Q" + substring + "\\E(.*)")
///
/// 		return WaveExists(wv)
/// 	End
/// \endrst
///
/// @return 1 if word was found in str and word was not "". 0 if not.
Function SearchWordInString(str, word, [prefix, suffix])
	string str, word
	string &prefix, &suffix

	WAVE/Z/T wv = SearchStringBase(str, "(.*)\\b\\Q" + word + "\\E\\b(.*)")
	if(!WaveExists(wv))
		return 0
	endif

	if(!ParamIsDefault(prefix))
		prefix = wv[0]
	endif

	if(!ParamIsDefault(suffix))
		suffix = wv[1]
	endif

	return 1
End

/// @brief More advanced version of SplitString
///
/// supports 6 subpatterns, specified by curly brackets in regex
///
/// @returns text wave containing subpatterns of regex call
Function/WAVE SearchStringBase(str, regex)
	string str, regex

	string command
	variable i, numBrackets
	string str0, str1, str2, str3, str4, str5

	// create wave for storing parsing results
	ASSERT(!GrepString(regex, "\\\\[\\(|\\)]"), "unsupported escaped brackets in regex pattern")
	numBrackets = CountSubstrings(regex, "(")
	ASSERT(numBrackets == CountSubstrings(regex, ")"), "missing bracket in regex pattern")
	ASSERT(numBrackets < 7, "maximum 6 subpatterns are supported")
	Make/N=(6)/FREE/T wv

	// call SplitString
	SplitString/E=regex str, str0, str1, str2, str3, str4, str5
	wv[0] = str0
	wv[1] = str1
	wv[2] = str2
	wv[3] = str3
	wv[4] = str4
	wv[5] = str5

	// return wv on success
	if(V_flag  == numBrackets)
		Redimension/N=(numbrackets) wv
		return wv
	endif
	return $""
End

/// @brief Search for the occurence of pattern in string
///
/// @returns number of occurences
Function CountSubstrings(str, pattern)
	string str, pattern

	variable i = -1, position = -1

	do
		i += 1
		position += 1
		position = strsearch(str, pattern, position)
	while(position != -1)

	return i
end

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
/// @param noiseGenMode [optional, defaults to #NOISE_GEN_LINEAR_CONGRUENTIAL] type of RNG to use
Function InPlaceRandomShuffle(inwave, [noiseGenMode])
	wave inwave
	variable noiseGenMode

	variable i, j, emax, temp
	variable N = DimSize(inwave, ROWS)

	if(ParamIsDefault(noiseGenMode))
		noiseGenMode = NOISE_GEN_LINEAR_CONGRUENTIAL
	endif

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
///
/// Counterpart @see ListToNumericWave
/// Similar @see NumericWaveToList
/// @see ListToNumericWave
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

/// @brief Check wether the given background task is currently running
///
/// Note:
/// Background functions which are currently waiting for their
/// period to be reached are also running.
///
/// @param task Named background task identifier, this is *not* the function set with `proc=`
Function IsBackgroundTaskRunning(task)
	string task

	CtrlNamedBackground $task, status
	return NumberByKey("RUN", s_info)
End

/// @brief Count the number of ones in `value`
///
/// @param value will be truncated to an integer value
Function PopCount(value)
	variable value

	variable count

	value = trunc(value)
	do
		if(value & 1)
			count += 1
		endif
		value = trunc(value / 2^1) // shift one to the right
	while(value > 0)

	return count
End

/// @brief Initializes the random number generator with a new seed between (0,1]
/// The time base is assumed to be at least 0.1 microsecond precise, so a new seed
/// is available every 0.1 microsecond.
///
/// Usage example for the case that one needs n non reproducible random numbers.
/// Whenever the following code block is executed a new seed is set, resulting in a different series of numbers
///
/// \rst
/// .. code-block:: igorpro
///
///		Make/D/N=(n) newRandoms
///		NewRandomSeed() // Initialize random number series with a new seed
///		newRandoms[] = GetReproducibleRandom() // Get n randoms from the new series
///
/// \endrst
Function NewRandomSeed()

	SetRandomSeed/BETR=1 ((stopmstimer(-2) * 10 ) & 0xffffffff) / 2^32

End

/// @brief Return a random value in the range (0,1] which can be used as a seed for `SetRandomSeed`
///
/// Return a reproducible random number depending on the RNG seed.
threadsafe Function GetReproducibleRandom()

	variable randomSeed

	do
		randomSeed = abs(enoise(1, NOISE_GEN_MERSENNE_TWISTER))
	while(randomSeed == 0)

	return randomSeed
End

/// @brief Return a unique integer
///
/// The returned values can *not* be used for statistical purposes
/// as the distribution is not uniform anymore.
Function GetUniqueInteger()
	return (GetReproducibleRandom() * 2^33) & 0xFFFFFFFF
End

/// @brief Add a string prefix to each list item and
/// return the new list
Function/S AddPrefixToEachListItem(prefix, list)
	string prefix, list

	string result = ""
	variable numEntries, i

	numEntries = ItemsInList(list)
	for(i = 0; i < numEntries; i += 1)
		result = AddListItem(prefix + StringFromList(i, list), result, ";", inf)
	endfor

	return result
End

/// @brief Remove a string prefix from each list item and
/// return the new list
Function/S RemovePrefixFromListItem(prefix, list, [listSep])
	string prefix, list
	string listSep
	if(ParamIsDefault(listSep))
		listSep = ";"
	endif

	string result, entry
	variable numEntries, i, len

	result = ""
	len = strlen(prefix)
	numEntries = ItemsInList(list, listSep)
	for(i = 0; i < numEntries; i += 1)
		entry = StringFromList(i, list, listSep)
		if(!cmpstr(entry[0,(len-1)], prefix))
			entry = entry[(len),inf]
		endif
		result = AddListItem(entry, result, listSep, inf)
	endfor

	return result
End

/// @brief Check wether the function reference points to
/// the prototype function or to an assigned function
///
/// Due to Igor Pro limitations you need to pass the function
/// info from `FuncRefInfo` and not the function reference itself.
///
/// @return 1 if pointing to prototype function, 0 otherwise
threadsafe Function FuncRefIsAssigned(funcInfo)
	string funcInfo

	variable result

	ASSERT_TS(!isEmpty(funcInfo), "Empty function info")
	result = NumberByKey("ISPROTO", funcInfo)
	ASSERT_TS(IsFinite(result), "funcInfo does not look like a FuncRefInfo string")

	return result == 0
End

/// @brief Return the seconds, including fractional part, since Igor Pro epoch (1/1/1904) in UTC time zone
Function DateTimeInUTC()
	return DateTime - date2secs(-1, -1, -1)
End

/// @brief Return a string in ISO 8601 format with timezone UTC
/// @param secondsSinceIgorEpoch [optional, defaults to number of seconds until now] Seconds since the Igor Pro epoch (1/1/1904) in UTC
/// @param numFracSecondsDigits  [optional, defaults to zero] Number of sub-second digits
/// @param localTimeZone         [optional, defaults to false] Use the local time zone instead of UTC
Function/S GetISO8601TimeStamp([secondsSinceIgorEpoch, numFracSecondsDigits, localTimeZone])
	variable secondsSinceIgorEpoch, numFracSecondsDigits, localTimeZone

	string str
	variable timezone

	if(ParamIsDefault(localTimeZone))
		localTimeZone = 0
	else
		localTimeZone = !!localTimeZone
	endif

	if(ParamIsDefault(numFracSecondsDigits))
		numFracSecondsDigits = 0
	else
		ASSERT(IsInteger(numFracSecondsDigits) && numFracSecondsDigits >= 0, "Invalid value for numFracSecondsDigits")
	endif

	if(ParamIsDefault(secondsSinceIgorEpoch))
		if(localTimeZone)
			secondsSinceIgorEpoch = DateTime
		else
			secondsSinceIgorEpoch = DateTimeInUTC()
		endif
	endif

	if(localTimeZone)
		timezone = Date2Secs(-1,-1,-1)
		sprintf str, "%sT%s%+03d:%02d", Secs2Date(secondsSinceIgorEpoch, -2), Secs2Time(secondsSinceIgorEpoch, 3, numFracSecondsDigits), trunc(timezone / 3600), abs(mod(timezone / 60, 60))
	else
		sprintf str, "%sT%sZ", Secs2Date(secondsSinceIgorEpoch, -2), Secs2Time(secondsSinceIgorEpoch, 3, numFracSecondsDigits)
	endif

	return str
End

/// @brief Parses a simple unit with prefix into its prefix and unit.
///
/// Note: The currently allowed units are the SI base units [1] and other common derived units.
/// And in accordance to SI definitions, "kg" is a *base* unit.
///
/// @param[in]  unitWithPrefix string to parse, examples are "ms" or "kHz"
/// @param[out] prefix         symbol of decimal multipler of the unit,
///                            see below or [1] chapter 3 for the full list
/// @param[out] numPrefix      numerical value of the decimal multiplier
/// @param[out] unit           unit
///
/// \rst
///
/// =====  ======  ===============
/// Name   Symbol  Numerical value
/// =====  ======  ===============
/// yotta    Y        1e24
/// zetta    Z        1e21
/// exa      E        1e18
/// peta     P        1e15
/// tera     T        1e12
/// giga     G        1e9
/// mega     M        1e6
/// kilo     k        1e3
/// hecto    h        1e2
/// deca     da       1e1
/// deci     d        1e-1
/// centi    c        1e-2
/// milli    m        1e-3
/// micro    mu       1e-6
/// nano     n        1e-9
/// pico     p        1e-12
/// femto    f        1e-15
/// atto     a        1e-18
/// zepto    z        1e-21
/// yocto    y        1e-24
/// =====  ======  ===============
///
/// \endrst
///
/// [1]: 8th edition of the SI Brochure (2014), http://www.bipm.org/en/publications/si-brochure
Function ParseUnit(unitWithPrefix, prefix, numPrefix, unit)
	string unitWithPrefix
	string &prefix
	variable &numPrefix
	string &unit

	string expr

	ASSERT(!isEmpty(unitWithPrefix), "empty unit")

	prefix    = ""
	numPrefix = NaN
	unit      = ""

	expr = "(Y|Z|E|P|T|G|M|k|h|d|c|m|mu|n|p|f|a|z|y)?[[:space:]]*(m|kg|s|A|K|mol|cd|Hz|V|N|W|J|a.u.)"

	SplitString/E=(expr) unitWithPrefix, prefix, unit
	ASSERT(V_flag >= 1, "Could not parse unit string")

	numPrefix = GetDecimalMultiplierValue(prefix)
End

/// @brief Return the numerical value of a SI decimal multiplier
///
/// @see ParseUnit
Function GetDecimalMultiplierValue(prefix)
	string prefix

	if(isEmpty(prefix))
		return 1
	endif

	Make/FREE/T prefixes = {"Y", "Z", "E", "P", "T", "G", "M", "k", "h", "da", "d", "c", "m", "mu", "n", "p", "f", "a", "z", "y"}
	Make/FREE/D values   = {1e24, 1e21, 1e18, 1e15, 1e12, 1e9, 1e6, 1e3, 1e2, 1e1, 1e-1, 1e-2, 1e-3, 1e-6, 1e-9, 1e-12, 1e-15, 1e-18, 1e-21, 1e-24}

	FindValue/Z/TXOP=(1 + 4)/TEXT=(prefix) prefixes
	ASSERT(V_Value != -1, "Could not find prefix")

	ASSERT(DimSize(prefixes, ROWS) == DimSize(values, ROWS), "prefixes and values wave sizes must match")
	return values[V_Value]
End

/// @brief Query a numeric option settable with `SetIgorOption`
///
/// @param name         name of the keyword/setting
/// @param globalSymbol [optional, defaults to false] `name` refers to a global
///                     symbol set via `poundDefine`
Function QuerySetIgorOption(name, [globalSymbol])
	string name
	variable globalSymbol

	string cmd
	variable result

	if(ParamIsDefault(globalSymbol))
		globalSymbol = 0
	else
		globalSymbol = !!globalSymbol
	endif

	DFREF dfr = GetDataFolderDFR()

	// we remove V_flag as the existence of it determines
	// if the operation was successfull
	KillVariables/Z V_Flag

	if(globalSymbol)
		sprintf cmd, "SetIgorOption poundDefine=%s?", name
	else
		sprintf cmd, "SetIgorOption %s=?", name
	endif

	Execute/Q/Z cmd

	NVAR/Z/SDFR=dfr flag = V_Flag
	if(!NVAR_Exists(flag))
		return NaN
	endif

	result = flag
	KillVariables/Z flag

	return result
End

/// @brief Parse a ISO8601 timestamp, e.g. created by GetISO8601TimeStamp(), and returns the number
/// of seconds, including fractional parts, since Igor Pro epoch (1/1/1904) in UTC time zone
///
/// Accepts also the following specialities:
/// - no UTC timezone specifier (UTC timezone is still used)
/// - ` `/`T` between date and time
/// - fractional seconds
/// - `,`/`.` as decimal separator
Function ParseISO8601TimeStamp(timestamp)
	string timestamp

	string year, month, day, hour, minute, second, regexp, fracSeconds
	variable secondsSinceEpoch

	regexp = "^([[:digit:]]+)-([[:digit:]]+)-([[:digit:]]+)[T ]{1}([[:digit:]]+):([[:digit:]]+):([[:digit:]]+)([.,][[:digit:]]+)?Z?$"
	SplitString/E=regexp timestamp, year, month, day, hour, minute, second, fracSeconds

	if(V_flag < 6)
		return NaN
	endif

	secondsSinceEpoch  = date2secs(str2num(year), str2num(month), str2num(day))          // date
	secondsSinceEpoch += 60 * 60* str2num(hour) + 60 * str2num(minute) + str2num(second) // time
	// timetstamp is in UTC so we don't need to add/subtract anything

	if(!IsEmpty(fracSeconds))
		secondsSinceEpoch += str2num(ReplaceString(",", fracSeconds, "."))
	endif

	return secondsSinceEpoch
End

/// @brief Return the disc folder name where the XOPs are located
///
/// Distinguishes between i386 and x64 Igor versions
Function/S GetIgorExtensionFolderName()

#if defined(IGOR64)
	return "Igor Extensions (64-bit)"
#else
	return "Igor Extensions"
#endif
End

/// @brief Recursively resolve shortcuts to files/directories
///
/// @return full path or an empty string if the file does not exist or the
/// 		shortcut points to a non existing file/folder
Function/S ResolveAlias(pathName, path)
	string pathName, path

	GetFileFolderInfo/P=$pathName/Q/Z path

	if(V_flag)
		return ""
	endif

	if(V_isAliasShortcut)
		return ResolveAlias(pathName, S_aliasPath)
	endif

	return path
End

/// @brief Return a text or numeric free wave with all duplicates deleted, might change the
/// relative order of the entries
Function/WAVE DeleteDuplicates(Wv)
	WAVE wv

	switch(WaveType(wv, 1))
		case 1: 
			return DeleteDuplicatesNum(wv)
			break
		case 2:
			return DeleteDuplicatesTxt(wv)
			break
		default:
			ASSERT(0, "Can not work with this wave type")
	endswitch
End

/// @brief Return a text free wave with all duplicates removed, might change the
/// relative order of the entries
static Function/WAVE DeleteDuplicatesTxt(txtWave)
	WAVE/T txtWave

	variable i, numRows
	numRows = DimSize(txtWave, ROWS)

	Duplicate/FREE/T txtWave, dest

	if(numRows <= 1)
		return dest
	endif

	FindDuplicates/RT=dest txtWave

	return dest
End

/// @brief Return a numeric free wave with all duplicates removed, might change the
/// relative order of the entries
static Function/WAVE DeleteDuplicatesNum(numWave)
	WAVE numWave

	variable i, numRows
	numRows = DimSize(numWave, ROWS)

	Duplicate/FREE numWave, dest
	if(numRows <= 1)
		return dest
	endif

	FindDuplicates/RN=dest numWave

	return dest
End

/// @brief Return the number of bits of the architecture
///        Igor Pro was built for.
Function GetArchitectureBits()

#if defined(IGOR64)
	return 64
#else
	return 32
#endif
End

/// @brief Return the Igor Pro version string
Function/S GetIgorProVersion()
	return StringByKey("IGORFILEVERSION", IgorInfo(3))
End

/// @brief Return a unique symbolic path name
///
/// \rst
/// .. code-block:: igorpro
///
///		string symbPath = GetUniqueSymbolicPath()
///		NewPath/Q/O $symbPath, "C:"
/// \endrst
Function/S GetUniqueSymbolicPath([prefix])
	string prefix

	if(ParamIsDefault(prefix))
		prefix = "temp_"
	endif

	NewRandomSeed()
	return prefix + num2istr(GetReproducibleRandom() * 1e6)
End

/// @brief Return a list of all files from the given symbolic path
///        and its subfolders. The list is pipe (`|`) separated as
///        the semicolon (`;`) is a valid character in filenames.
///
/// Note: This function does *not* work on MacOSX as there filenames are allowed
///       to have pipe symbols in them.
///
/// @param pathName igor symbolic path to search recursively
/// @param extension [optional, defaults to all files] file suffixes to search for
Function/S GetAllFilesRecursivelyFromPath(pathName, [extension])
	string pathName, extension

	string fileOrPath, directory, subFolderPathName
	string files
	string allFiles = ""
	string dirs = ""
	variable i, numDirs

	PathInfo $pathName
	ASSERT(V_flag, "Given symbolic path does not exist")

	if(ParamIsDefault(extension))
		extension = "????"
	endif

	for(i = 0; ;i += 1)
		fileOrPath = IndexedFile($pathName, i, extension)

		if(isEmpty(fileOrPath))
			// no more files
			break
		endif

		fileOrPath = ResolveAlias(pathName, fileOrPath)

		if(isEmpty(fileOrPath))
			// invalid shortcut, try next file
			continue
		endif

		GetFileFolderInfo/P=$pathName/Q/Z fileOrPath
		ASSERT(!V_Flag, "Error in GetFileFolderInfo")

		if(V_isFile)
			allFiles = AddListItem(S_path, allFiles, "|", INF)
		elseif(V_isFolder)
			dirs = AddListItem(S_path, dirs, "|", INF)
		else
			ASSERT(0, "Unexpected file type")
		endif
	endfor

	for(i = 0; ; i += 1)

		directory = IndexedDir($pathName, i, 1)

		if(isEmpty(directory))
			break
		endif

		dirs = AddListItem(directory, dirs, "|", INF)
	endfor

	numDirs = ItemsInList(dirs, "|")
	for(i = 0; i < numDirs; i += 1)

		directory = StringFromList(i, dirs, "|")
		subFolderPathName = GetUniqueSymbolicPath()

		NewPath/Q/O $subFolderPathName, directory
		files = GetAllFilesRecursivelyFromPath(subFolderPathName, extension=extension)
		KillPath/Z $subFolderPathName

		if(!isEmpty(files))
			allFiles = AddListItem(files, allFiles, "|", INF)
		endif
	endfor

	// remove empty entries
	return ListMatch(allFiles, "!", "|")
End

/// @brief Convert a text wave to string list
/// @param[in] txtWave     1D or 2D input text wave
/// @param[in] sep         separator for row entries
/// @param[in] colSep      [optional, default = ","] separator for column entries
/// @param[in] stopOnEmpty [optional, default = 0] when 1 stops generating the list when an empty string entry in txtWave is encountered
/// @return string with wave entries separated as list using given separators
///
/// Counterpart @see ConvertListToTextWave
/// @see NumericWaveToList
Function/S TextWaveToList(txtWave, sep[, colSep, stopOnEmpty])
	WAVE/T txtWave
	string sep, colSep
	variable stopOnEmpty

	string entry, colList
	string list = ""
	variable i, j, numRows, numCols

	ASSERT(IsTextWave(txtWave), "Expected a text wave")
	ASSERT(DimSize(txtWave, LAYERS) == 0, "Expected a 1D or 2D wave")
	ASSERT(!IsEmpty(sep), "Expected a non-empty row list separator")

	if(ParamIsDefault(colSep))
		colSep = ","
	else
		ASSERT(!IsEmpty(colSep), "Expected a non-empty column list separator")
	endif
	stopOnEmpty = ParamIsDefault(stopOnEmpty) ? 0 : !!stopOnEmpty

	numRows = DimSize(txtWave, ROWS)
	numCols = DimSize(txtWave, COLS)
	if(!numCols)
		for(i = 0; i < numRows; i += 1)
			entry = txtWave[i]
			if(stopOnEmpty && isEmpty(entry))
				return list
			endif
			list = AddListItem(entry, list, sep, Inf)
		endfor
	else
		for(i = 0; i < numRows; i += 1)
			colList = ""
			for(j = 0; j < numCols; j += 1)
				entry = txtWave[i][j]
				if(stopOnEmpty && isEmpty(entry))
					break
				endif
				colList = AddListItem(entry, colList, colSep, Inf)
			endfor
			if(!(stopOnEmpty && isEmpty(colList)))
				list = AddListItem(colList, list, sep, Inf)
			endif
			if(stopOnEmpty && isEmpty(entry))
				return list
			endif
		endfor
	endif

	return list
End

/// @brief Convert a numeric wave to string list
///
/// Counterpart @see ListToNumericWave
/// Similar @see Convert1DWaveToList
/// @see TextWaveToList
///
/// @param wv     numeric wave
/// @param sep    separator
/// @param format [optional, defaults to `%g`] sprintf conversion specifier
Function/S NumericWaveToList(wv, sep, [format])
	WAVE wv
	string sep, format

	string list = ""
	string str
	variable i, numRows

	if(ParamIsDefault(format))
		format = "%g"
	endif

	ASSERT(IsNumericWave(wv), "Expected a numeric wave")
	ASSERT(DimSize(wv, COLS) == 0, "Expected a 1D wave")

	numRows = DimSize(wv, ROWS)
	for(i = 0; i < numRows; i += 1)
		sprintf str, format, wv[i]
		list = AddListItem(str, list, sep, Inf)
	endfor

	return list
End

/// @brief Convert a list to a numeric wave
///
/// Counterpart @see NumericWaveToList().
/// @see TextWaveToList
///
/// @param list list with numeric entries
/// @param sep  separator
/// @param type [optional, defaults to double precision float (`IGOR_TYPE_64BIT_FLOAT`)] type of the created numeric wave
Function/WAVE ListToNumericWave(list, sep, [type])
	string list, sep
	variable type

	if(ParamIsDefault(type))
		type = IGOR_TYPE_64BIT_FLOAT
	endif

	list = RemoveEnding(list, sep)

	Make/FREE/Y=(type)/N=(ItemsInList(list, sep)) wv = str2num(StringFromList(p, list, sep))

	return wv
End

/// @brief Returns the column from a multidimensional wave using the dimlabel
Function/WAVE GetColfromWavewithDimLabel(waveRef, dimLabel)
	WAVE waveRef
	string dimLabel
	
	variable column = FindDimLabel(waveRef, COLS, dimLabel)
	ASSERT(column != -2, "dimLabel:" + dimLabel + "cannot be found")
	matrixOp/FREE OneDWv = col(waveRef, column)
	return OneDWv
End

/// @brief Turn a persistent wave into a free wave
Function/Wave MakeWaveFree(wv)
	WAVE wv

	DFREF dfr = NewFreeDataFolder()

	MoveWave wv, dfr

	return wv
End

/// @brief Sets the dimensionlabes of a wave
///
/// @param wv       Wave to add dimLables
/// @param list     List of dimension labels, semicolon separated.
/// @param dim      Wave dimension, see, @ref WaveDimensions
/// @param startPos [optional, defaults to 0] First dimLabel index
Function SetWaveDimLabel(wv, list, dim, [startPos])
	WAVE wv
	string list
	variable dim
	variable startPos

	string labelName
	variable i
	variable dimlabelCount = itemsinlist(list)

	if(paramIsDefault(startPos))
		startPos = 0
	endif

	ASSERT(startPos >= 0, "Illegal negative startPos")
	ASSERT(dimlabelCount <= dimsize(wv, dim) + startPos, "Dimension label count exceeds dimension size")
	for(i = 0; i < dimlabelCount;i += 1)
		labelName = stringfromlist(i, list)
		setDimLabel dim, i + startPos, $labelName, Wv
	endfor
End

/// @brief Compare two variables and determines if they are close.
///
/// Based on the implementation of "Floating-point comparison algorithms" in the C++ Boost unit testing framework.
///
/// Literature:<br>
/// The art of computer programming (Vol II). Donald. E. Knuth. 0-201-89684-2. Addison-Wesley Professional;
/// 3 edition, page 234 equation (34) and (35).
///
/// @param var1            first variable
/// @param var2            second variable
/// @param tol             [optional, defaults to 1e-8] tolerance
/// @param strong_or_weak  [optional, defaults to strong] type of condition, can be zero for weak or 1 for strong
Function CheckIfClose(var1, var2, [tol, strong_or_weak])
	variable var1, var2, tol, strong_or_weak

	if(ParamIsDefault(tol))
		tol = 1e-8
	endif

	if(ParamIsDefault(strong_or_weak))
		strong_or_weak = 1
	endif

	variable diff = abs(var1 - var2)
	variable d1   = diff / abs(var1)
	variable d2   = diff / abs(var2)

	if(strong_or_weak)
		return d1 <= tol && d2 <= tol
	else
		return d1 <= tol || d2 <= tol
	endif
End

/// @brief Test if a variable is small using the inequality @f$  | var | < | tol |  @f$
///
/// @param var  variable
/// @param tol  [optional, defaults to 1e-8] tolerance
Function CheckIfSmall(var, [tol])
	variable var
	variable tol

	if(ParamIsDefault(tol))
		tol = 1e-8
	endif

	return abs(var) < abs(tol)
End

/// @brief Check if all elements of the string list are the same
///
/// Returns true for lists with less than one element
Function ListHasOnlyOneUniqueEntry(list, [sep])
	string list, sep

	variable numElements, i
	string element, refElement

	if(ParamIsDefault(sep))
		sep = ";"
	else
		ASSERT(strlen(sep) == 1, "sep must be only one character")
	endif

	numElements = ItemsInList(list, sep)

	if(numElements <= 1)
		return	1
	endif

	refElement = StringFromList(0, list, sep)

	for(i = 1; i < numElements; i += 1)
		element = StringFromList(i, list, sep)
		if(cmpstr(refElement, element))
			return 0
		endif
	endfor

	return 1
End

/// @brief Extract the values of a list of subrange specifications
/// See also DisplayHelpTopic "Subrange Display"
///
/// Example invocations:
/// \rst
/// .. code-block:: igorpro
///
/// 	wAVE ranges = ExtractFromSubrange("[3,4]_[*]_[1, *;4]_[]_[5][]", 0)
/// \endrst
///
/// @param listOfRanges list of subrange specifications separated by **_**
/// @param dim          dimension to extract
///
/// @returns 2-dim wave with the start, stop, step as columns and rows as
///          number of elements. Returns -1 instead of `*` or ``.
Function/WAVE ExtractFromSubrange(listOfRanges, dim)
	string listOfRanges
	variable dim

	variable numElements, i, start, stop, step
	string str, rdSpec, stopStr

	numElements = ItemsInList(listOfRanges, "_")

	Make/FREE/I/N=(numElements, 3) ranges

	for(i = 0; i < numElements; i += 1)
		str = StringFromList(i, listOfRanges, "_")
		str = ReplaceString(" ", str, "")
		str = ReplaceString("\t", str, "")
		str = ReplaceString("][", str, "#")
		str = ReplaceString("[", str, "#")
		str = ReplaceString("]", str, "#")

		rdSpec = StringFromList(dim + 1, str, "#")

		// possible options:
		// 1: "" (empty)
		// 2: *
		// 3: $index
		// 4: $start, *
		// 5: $start, $stop
		// 6: $start, $stop;$step

		if(isEmpty(rdSpec) || !cmpstr(rdSpec, "*")) // case 1 & 2
			ranges[i][0] = -1
			ranges[i][1] = -1
		else
			sscanf rdSpec, "%d,%[*0-9];%d ", start, stopStr, step

			if(V_Flag == 1) // case 3
				ranges[i][0] = start
				ranges[i][1] = start
				ranges[i][2] = 1
			elseif(V_Flag == 2)
				if(!cmpstr(stopstr, "*")) // case 4
					ranges[i][0] = start
					ranges[i][1] = -1
					ranges[i][2] = 1
				else
					stop = str2num(stopStr) // case 5
					ASSERT(IsFinite(stop), "stop is not finite")
					ranges[i][0] = start
					ranges[i][1] = stop
					ranges[i][2] = 1
				endif
			elseif(V_Flag == 3) // case 6
				stop = str2num(stopStr) // case 5
				ranges[i][0] = start
				ranges[i][1] = IsFinite(stop) ? stop : -1
				ranges[i][2] = step
			else
				ASSERT(0, "Unexpected state")
			endif
		endif
	endfor

	return ranges
End

#if (IgorVersion() >= 8.00)

/// @brief Check if a name for an object adheres to the strict naming rules
///
/// @see `DisplayHelpTopic "ObjectName"`
threadsafe Function IsValidObjectName(wvName)
	string wvName

	return !cmpstr(wvName, CleanupName(wvName, 0, MAX_OBJECT_NAME_LENGTH_IN_BYTES))
End

#else

/// @brief Check if a name for an object adheres to the strict naming rules
///
/// @see `DisplayHelpTopic "ObjectName"`
Function IsValidObjectName(wvName)
	string wvName

	return !cmpstr(wvName, CleanupName(wvName, 0))
End

#endif

/// @brief Find an integer `x` which is larger than `a` but the
/// smallest possible power of `p`.
///
/// @f$ x > a @f$ where @f$ x = c^p @f$ holds and @f$ x @f$ is
/// the smallest possible value.
Function FindNextPower(a, p)
	variable a, p

	ASSERT(p > 1, "Invalid power")
	ASSERT(a > 0, "Invalid value")
	ASSERT(IsInteger(a), "Value has to be an integer")

	return ceil(log(a)/log(p))
End

/// @brief Return a wave with deep copies of all referenced waves
///
/// The deep copied waves will be free waves.
/// Does not allow invalid wave references in `src`.
///
/// @param src       wave reference wave
/// @param dimension [optional] copy only a single dimension, requires `index` or
///                  `indexWave` as well
/// @param index     [optional] specifies the index into `dimension`
/// @param indexWave [optional] specifies the indizes into `dimension`, allows for
///                  differing indizes per `src` entry
Function/WAVE DeepCopyWaveRefWave(src, [dimension, index, indexWave])
	WAVE/WAVE src
	variable dimension, index
	WAVE indexWave

	variable i, numEntries

	ASSERT(IsWaveRefWave(src), "Expected wave ref wave")
	ASSERT(DimSize(src, COLS) <= 1, "Expected a 1D wave for src")

	if(!ParamIsDefault(dimension))
		ASSERT(dimension >= ROWS && dimension <= CHUNKS, "Invalid dimension")
		ASSERT(ParamIsDefault(index) + ParamIsDefault(indexWave) == 1, "Need exactly one of parameter of type index or indexWave")
	endif

	if(!ParamIsDefault(indexWave) || !ParamIsDefault(index))
		ASSERT(!ParamIsDefault(dimension), "Missing optional parameter dimension")
	endif

	Duplicate/WAVE/FREE src, dst

	numEntries = DimSize(src, ROWS)

	if(!ParamIsDefault(indexWave))
		ASSERT(numEntries == numpnts(indexWave), "indexWave and src must have the same number of points")
	endif

	for(i = 0; i < numEntries; i += 1)
		WAVE/Z srcWave = dst[i]
		ASSERT(WaveExists(srcWave), "Missing wave at linear index" + num2str(i))

		if(!ParamIsDefault(indexWave))
			index = indexWave[i]
		endif

		if(ParamIsDefault(dimension))
			Duplicate/FREE srcWave, dstWave
		else
			switch(dimension)
				case ROWS:
					Duplicate/FREE/R=[index][][][] srcWave, dstWave
					break
				case COLS:
					Duplicate/FREE/R=[][index][][] srcWave, dstWave
					break
				case LAYERS:
					Duplicate/FREE/R=[][][index][] srcWave, dstWave
					break
				case CHUNKS:
					Duplicate/FREE/R=[][][][index] srcWave, dstWave
					break
			endswitch
		endif

		dst[i] = dstWave
	endfor

	return dst
End

/// @brief Return 1 if the wave is a text wave, zero otherwise
threadsafe Function IsTextWave(wv)
	WAVE wv

	return WaveType(wv, 1) == 2
End

/// @brief Return 1 if the wave is a numeric wave, zero otherwise
threadsafe Function IsNumericWave(wv)
	WAVE wv

	return WaveType(wv, 1) == 1
End

/// @brief Return 1 if the wave is a wave reference wave, zero otherwise
threadsafe Function IsWaveRefWave(wv)
	WAVE wv

	return WaveType(wv, 1) == IGOR_TYPE_WAVEREF_WAVE
End

/// @brief Return 1 if the wave is a floating point wave
threadsafe Function IsFloatingPointWave(wv)
	WAVE wv

	variable type = WaveType(wv)

	return (type & IGOR_TYPE_32BIT_FLOAT) || (type & IGOR_TYPE_64BIT_FLOAT)
End

/// @brief Return 1 if the wave is a global wave (not a null wave and not a free wave)
threadsafe Function IsGlobalWave(wv)
	WAVE wv

	return WaveType(wv, 2) == 1
End

/// @brief Return the user name of the running user
Function/S GetSystemUserName()

	variable numElements
	string path

	// example: C:Users:thomas:AppData:Roaming:WaveMetrics:Igor Pro 7:Packages:
	path = SpecialDirPath("Packages", 0, 0, 0)
	numElements = ItemsInList(path, ":")
	ASSERT(numElements > 3, "Unexpected format")

	return StringFromList(2, path, ":")
End

/// @brief Bring the control window (the window with the command line) to the
///        front of the desktop
Function ControlWindowToFront()
	DoWindow/H
End

/// @brief Return the alignment of the decimal number (usually a 32bit/64bit pointer)
Function GetAlignment(val)
	variable val

	variable i

	for(i=1; i < 64; i+= 1)
		if(mod(val, 2^i) != 0)
			return 2^(i-1)
		endif
	endfor
End

/// @brief Remove the dimlabels of all dimensions with data
///
/// Due to no better solutions the dim labels are actually overwritten with an empty string
Function RemoveAllDimLabels(wv)
	WAVE/Z wv

	variable dims, i, j, numEntries

	dims = WaveDims(wv)

	for(i = 0; i < dims; i += 1)
		numEntries = DimSize(wv, i)
		for(j = -1; j < numEntries; j += 1)
			SetDimLabel i, j, $"", wv
		endfor
	endfor
End

/// @brief Calculate the value for `mskip` of `ModifyGraph`
///
/// @param numPoints  number of points shown
/// @param numMarkers desired number of markers
Function GetMarkerSkip(numPoints, numMarkers)
	variable numPoints, numMarkers

	if(!IsFinite(numPoints) || !IsFinite(numMarkers))
		return 1
	endif

	return trunc(limit(numPoints / numMarkers, 1, 2^15 - 1))
End

/// @brief Return a wave with the set theory style intersection of wave1 and wave2
///
/// Given {1, 2, 4, 10} and {2, 5, 11} this will return {2}.
///
/// Inspired by http://www.igorexchange.com/node/366 but adapted to modern Igor Pro
///
/// @return free wave with the set intersection or an invalid wave reference
/// if the intersection is an empty set
Function/WAVE GetSetIntersection(wave1, wave2)
	WAVE wave1
	WAVE wave2

	variable type, wave1Rows, wave2Rows
	variable longRows, shortRows, entry
	variable i, j, longWaveRow

	type = WaveType(wave1)
	ASSERT(type == WaveType(wave2), "Wave type mismatch")

	wave1Rows = DimSize(wave1, ROWS)
	wave2Rows = DimSize(wave2, ROWS)

	if(wave1Rows == 0 || wave2Rows == 0)
		return $""
	endif

	if(wave1Rows > wave2Rows)
		Duplicate/FREE wave1, longWave
		WAVE shortWave = wave2
		longRows  = wave1Rows
		shortRows = wave2Rows
	else
		Duplicate/FREE wave2, longWave
		WAVE shortWave = wave1
		longRows  = wave2Rows
		shortRows = wave1Rows
	endif

	// Sort values in longWave
	Sort longWave, longWave
	Make/FREE/N=(shortRows)/Y=(type) resultWave

	for(i = 0; i < shortRows; i += 1)
		entry = shortWave[i]
		longWaveRow = BinarySearch(longWave, entry)
		if(longWaveRow >= 0 && longWave[longWaveRow] == entry)
			resultWave[j] = entry
			j += 1
		endif
	endfor

	if(j == 0)
		return $""
	endif

	Redimension/N=(j) resultWave

	return resultWave
End

/// @brief Kill all passed windows
///
/// Silently ignore errors.
Function KillWindows(list)
	string list

	variable numEntries, i

	numEntries = ItemsInList(list)
	for(i = 0; i < numEntries; i += 1)
		KillWindow/Z $StringFromList(i, list)
	endfor
End

/// @brief str2num variant with no runtime error on invalid conversions
Function str2numSafe(str)
	string str

	variable err, var

	var = str2num(str); err = GetRTError(1)

	return var
End

/// @brief Open a folder selection dialog
///
/// @return a string denoting the selected folder, or an empty string if
/// nothing was supplied.
Function/S AskUserForExistingFolder([baseFolder])
	string baseFolder

	string symbPath, selectedFolder
	symbPath = GetUniqueSymbolicPath()

	if(!ParamIsDefault(baseFolder))
		NewPath/O/Q/Z $symbPath baseFolder
		// preset next undirected NewPath/Open call using the contents of a
		// *symbolic* folder
		PathInfo/S $symbPath
	endif

	// let the user choose a folder, starts in $baseFolder if supplied
	NewPath/O/Q/Z $symbPath
	PathInfo $symbPath
	selectedFolder = S_path
	KillPath/Z $symbPath

	return selectedFolder
End

/// @brief Return all axes with the given orientation
///
/// @param graph graph
/// @param axisOrientation One of @ref AxisOrientationConstants
Function/S GetAllAxesWithOrientation(graph, axisOrientation)
	string graph
	variable axisOrientation

	string axList, axis
	string list = ""
	variable numAxes, i

	axList  = AxisList(graph)
	numAxes = ItemsInList(axList)

	for(i = 0; i < numAxes; i += 1)
		axis = StringFromList(i, axList)

		if(axisOrientation & GetAxisOrientation(graph, axis))
			list = AddListItem(axis, list, ";", inf)
		endif
	endfor

	return list
End

/// @brief Polished version of `GetNumFromModifyStr` from `Readback ModifyStr.ipf`
///
/// @param info     string as returned by AxisInfo or TraceInfo
/// @param key      keyword
/// @param listChar empty, `{` or `(` depending on keyword style
/// @param item     return the given element from the extracted list
static Function GetNumFromModifyStr(info, key, listChar, item)
	string info
	string key
	string listChar
	variable item

	string list, escapedListChar, regexp

	escapedListChar = "\\Q" + listChar + "\\E"

	sprintf regexp, "(?i)\\Q%s\\E\([^=]+\)=%s([^});]+)", key, escapedListChar

	SplitString/E=regexp info, list

	if(V_Flag < 1)
		return NaN
	endif

	if(item == 0)
		return str2num(list)
	else
		ASSERT(item >= 0 && item < ItemsInList(list, ","), "Invalid index")
		return str2num(StringFromList(item, list, ","))
	endif
End

/// @brief Return the list of axis sorted from highest
///        to lowest starting value of the `axisEnab` keyword.
///
/// `list` must be from one orientation, usually something returned by GetAllAxesWithOrientation()
Function/S SortAxisList(graph, list)
	string graph, list

	variable numAxes, i
	string axis

	numAxes = ItemsInList(list)

	if(numAxes < 2)
		return list
	endif

	Make/FREE/D/N=(numAxes) axisStart

	for(i = 0; i < numAxes; i += 1)
		axis         = StringFromList(i, list)
		axisStart[i] = GetNumFromModifyStr(AxisInfo(graph, axis), "axisEnab", "{", 0)
	endfor

	WAVE/T axisListWave = ListToTextWave(list, ";")

	Sort/R axisStart, axisListWave

	return TextWaveToList(axisListWave, ";")
End

/// @brief Replaces all occurences of the string `word`, treated as regexp word,
///        in `str` with `replacement`. Does not ignore case.
Function/S ReplaceWordInString(word, str, replacement)
	string word, str, replacement

	ASSERT(!IsEmpty(word), "Empty regex")

	variable ret
	string result, prefix, suffix

	if(!cmpstr(word, replacement, 0))
		return str
	endif

	result = str

	for(;;)
		ret = SearchWordInString(result, word, prefix = prefix, suffix = suffix)

		if(!ret)
			break
		endif

		result = prefix + replacement + suffix
	endfor

	return result
End

/// @brief Execute a list of functions via the Operation Queue
///
/// Special purpose function. Not intended for normal use.
Function ExecuteListOfFunctions(funcList)
	string funcList

	variable i, numEntries
	string func

	numEntries = ItemsInList(funcList)
	for(i = 0; i < numEntries; i += 1)
		func = StringFromList(i, funcList)

		if(IsEmpty(func))
			continue
		endif

		Execute/P/Q func
	endfor
End

Function/S GetInteractiveMode_PROTO()

	return ""
End

/// @brief Wrapper function for GetInteractiveMode in case it is not available
Function/S GetInteractiveModeWrapper()

	FUNCREF GetInteractiveMode_PROTO f = $"GetInteractiveMode"

	return f()
End

/// @brief Wrapper function for `Abort` which honours our interactive mode setting
Function DoAbortNow(msg)
	string msg

	DEBUGPRINTSTACKINFO()

	if(IsEmpty(msg))
		Abort
	endif

	NVAR/Z interactiveMode = $GetInteractiveModeWrapper()

	if(NVAR_Exists(interactiveMode) && interactiveMode)
		Abort msg
	else
		printf "Abort: %s\r", RemoveEnding(msg, "\r")
		Abort
	endif
End

/// @brief Return a floating point value as string rounded
///        to the given number of minimum significant digits
///
/// This allows to specify the minimum number of significant digits.
/// The normal printf/sprintf specifier only allows the maximum number of significant digits for `%g`.
Function/S FloatWithMinSigDigits(var, [numMinSignDigits])
	variable var, numMinSignDigits

	variable numMag

	if(ParamIsDefault(numMinSignDigits))
		numMinSignDigits = 6
	else
		ASSERT(numMinSignDigits >= 0, "Invalid numDecimalDigits")
	endif

	numMag = ceil(log(var))

	string str
	sprintf str, "%.*g", max(numMag, numMinSignDigits), var

	return str
End

/// @brief Normalize the line endings in the given string to either classic Mac OS/Igor Pro EOLs (`\r`)
///        or Unix EOLs (`\n`)
Function/S NormalizeToEOL(str, eol)
	string str, eol

	str = ReplaceString("\r\n", str, eol)

	if(!cmpstr(eol, "\r"))
		str = ReplaceString("\n", str, eol)
	elseif(!cmpstr(eol, "\n"))
		str = ReplaceString("\r", str, eol)
	else
		ASSERT(0, "unsupported EOL character")
	endif

	return str
End

/// @brief Return a nicely formatted multiline stacktrace
Function/S GetStackTrace([prefix])
	string prefix

	string stacktrace, entry, func, line, file, str
	string output
	variable i, numCallers

	if(ParamIsDefault(prefix))
		prefix = ""
	endif

	stacktrace = GetRTStackInfo(3)
	numCallers = ItemsInList(stacktrace)

	if(numCallers < 3)
		// our caller was called directly
		return "Stacktrace not available"
	endif

	output = prefix + "Stacktrace:\r"

	for(i = 0; i < numCallers - 2; i += 1)
		entry = StringFromList(i, stacktrace)
		func  = StringFromList(0, entry, ",")
		file  = StringFromList(1, entry, ",")
		line  = StringFromList(2, entry, ",")
		sprintf str, "%s%s(...)#L%s [%s]\r", prefix, func, line, file
		output += str
	endfor

	return output
End

/// @brief Stop all millisecond Igor Pro timers
Function StopAllMSTimers()
	variable i

	for(i = 0; i < MAX_NUM_MS_TIMERS; i += 1)
		printf "ms timer %d stopped. Elapsed time: %g\r", i, stopmstimer(i)
	endfor
End

/// @brief Return a time in seconds with high precision, microsecond resolution, using an
///        arbitrary zero point.
Function RelativeNowHighPrec()
	return stopmstimer(-2)/1e6
End

/// @brief High precision version of the builtin Sleep command
///
/// @param var time in seconds to busy-sleep (current precision is around 0.1ms)
Function SleepHighPrecision(var)
	variable var

	ASSERT(var >= 0, "Invalid duration")

	variable refTime = RelativeNowHighPrec() + var
	for(;;)
		if(abs(RelativeNowHighPrec() - refTime) < 100e-6)
			break
		endif
	endfor
End

/// @brief Return the machine epsilon for the given wave type
///
/// Experimentally determined with Igor Pro 7.08
Function GetMachineEpsilon(type)
	variable type

	type = ClearBit(type, IGOR_TYPE_UNSIGNED)
	ASSERT((type & IGOR_TYPE_COMPLEX) == 0, "Complex waves are not supported")

	switch(type)
		case IGOR_TYPE_64BIT_FLOAT:
			return 2^-52
		case IGOR_TYPE_32BIT_FLOAT:
			return 2^-23
		case IGOR_TYPE_64BIT_INT:
		case IGOR_TYPE_32BIT_INT:
		case IGOR_TYPE_16BIT_INT:
		case IGOR_TYPE_8BIT_INT:
			return 1
		default:
			ASSERT(0, "Unsupported wave type")
	endswitch
End

/// @brief Return true if wv is a free wave, false otherwise
Function IsFreeWave(wv)
	Wave wv

	return WaveType(wv, 2) == 2
End

/// @brief Return the modification count of the (permanent) wave
Function WaveModCountWrapper(wv)
	Wave wv

	ASSERT(!IsFreeWave(wv), "Can not work with free waves")

#if (IgorVersion() >= 8.00)
	return WaveModCount(wv)
#else
	return MU_WaveModCount(wv)
#endif

End

// @brief Convert a number to the strings `Passed` (!= 0) or `Failed` (0).
Function/S ToPassFail(passedOrFailed)
	variable passedOrFailed

	return SelectString(passedOrFailed, "failed", "passed")
End

// @brief Convert a number to the strings `True` (!= 0) or `False` (0).
Function/S ToTrueFalse(var)
	variable var

	return SelectString(var, "False", "True")
End

/// @brief Return true if not all wave entries are NaN, false otherwise.
///
Function HasOneValidEntry(wv)
	WAVE wv

	variable numEntries

	ASSERT(IsFloatingPointWave(wv), "Unexpected wave type")

	numEntries = numpnts(wv)
	ASSERT(numEntries > 0, "Empty wave")

	WaveStats/Q/M=1 wv
	return V_numNaNs != numEntries
End

/// @brief Merge two floating point waves labnotebook waves
///
/// The result will hold the finite row entry of either `wv1` or `wv2`.
Function/WAVE MergeTwoWaves(wv1, wv2)
	WAVE wv1, wv2

	variable numEntries, i, validEntryOne, validEntryTwo

	ASSERT(EqualWaves(wv1, wv2, 512), "Non matching wave dim sizes")
	ASSERT(EqualWaves(wv1, wv2, 2), "Non matching wave types")
	ASSERT(IsFloatingPointWave(wv1), "Expected floating point wave")
	ASSERT(DimSize(wv1, COLS) <= 1, "Expected 1D wave")

	Make/FREE/Y=(WaveType(wv1)) result = NaN

	numEntries = DimSize(wv1, ROWS)
	for(i = 0; i < numEntries; i +=1)

		validEntryOne = IsFinite(wv1[i])
		validEntryTwo = IsFinite(wv2[i])

		if(!validEntryOne && !validEntryTwo)
			continue
		elseif(validEntryOne)
			result[i] = wv1[i]
		elseif(validEntryTwo)
			result[i] = wv2[i]
		else
			ASSERT(0, "Both entries can not be valid.")
		endif
	endfor

	return result
End

/// @brief Create the special Notebook "HistoryCarbonCopy" which will hold
///        a readable copy of the history starting from the time of the
///        notebook creation.
Function CreateHistoryNotebook()
	NewNotebook/V=0/F=0/N=HistoryCarbonCopy
End

/// @brief Return the text of the history notebook
Function/S GetHistoryNotebookText()

	if(!WindowExists("HistoryCarbonCopy"))
		return ""
	endif

	Notebook HistoryCarbonCopy selection={startOfFile, endOfFile}
	ASSERT(!V_Flag, "Illegal selection")

	GetSelection notebook, HistoryCarbonCopy, 2
	ASSERT(V_Flag, "Illegal selection")

	return S_Selection
End

/// @brief Helper function for try/catch with AbortOnRTE
///
/// Not clearing the RTE before calling `AbortOnRTE` will always trigger the RTE no
/// matter what you do in that line.
///
/// Usage:
/// \rst
/// .. code-block:: igorpro
///
///    try
///       ClearRTError()
///       myFunc(); AbortOnRTE
///    catch
///      err = GetRTError(1)
///    endtry
///
/// \endrst
threadsafe Function ClearRTError()

	variable err = GetRTError(1)
	DEBUGPRINT_TS("Clearing RTE", var = err)
End

/// @brief Convert the DAQ run mode to a string
///
/// @param runMode One of @ref DAQRunModes
threadsafe Function/S DAQRunModeToString(runMode)
	variable runMode

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
threadsafe Function/S TestPulseRunModeToString(runMode)
	variable runMode

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

/// @brief Adapt the wave lock status on the wave and its contained waves
Function ChangeWaveLock(wv, val)
	WAVE/WAVE wv
	variable val

	variable numEntries, i

	val = !!val

	SetWaveLock val, wv

	if(!IsWaveRefWave(wv))
		return NaN
	endif

	ASSERT(DimSize(wv, ROWS) == numpnts(wv), "Expected a 1D wave")
	numEntries = DimSize(wv, ROWS)

	for(i = 0; i < numEntries; i += 1)
		WAVE/Z subWave = wv[i]

		if(WaveExists(subWave))
			ChangeWaveLock(subWave, val)
		endif
	endfor
End

/// @brief Deletes one row, column, layer or chunk from a wave
/// Advantages over DeletePoints:
/// Keeps the dimensionality of the wave when deleting the last row, column, layer or chunk in a wave
/// Implements range check
/// Advantages over DeletePoints + KillWaves:
/// The wave reference stays valid
///
/// @param wv wave where the row, column, layer or chunk should be deleted
///
/// @param dim dimension 0 - rows, 1 - column, 2 - layer, 3 - chunk
///
/// @param index index where one point in the given dimension is deleted
Function DeleteWavePoint(wv, dim, index)
   WAVE wv
   variable dim, index

   variable size

   ASSERT(WaveExists(wv), "wave does not exist")
   ASSERT(dim >= 0 && dim < 4, "dim must be 0, 1, 2 or 3")
   size = DimSize(wv, dim)
   if(index >= 0 && index < size)
	   if(size > 1)
		   DeletePoints/M=(dim) index, 1, wv
	   else
		   switch(dim)
			   case 0:
				   Redimension/N=(0, -1, -1, -1) wv
				   break
			   case 1:
				   Redimension/N=(-1, 0, -1, -1) wv
				   break
			   case 2:
				   Redimension/N=(-1, -1, 0, -1) wv
				   break
			   case 3:
				   Redimension/N=(-1, -1, -1, 0) wv
				   break
		   endswitch
	   endif
   else
	   ASSERT(0, "index out of range")
   endif
End
