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

		SVAR/Z lockedDevices = root:MIES:HardwareDevices:lockedDevices

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
#endif // AUTOMATED_TESTING

#if !defined(AUTOMATED_TESTING) || defined(AUTOMATED_TESTING_DEBUGGING)
		print GetStackTrace()
#endif

#ifndef AUTOMATED_TESTING
		print "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
		printf "Time: %s\r", GetIso8601TimeStamp(localTimeZone = 1)
		printf "Locked device: [%s]\r", RemoveEnding(lockedDevicesStr, ";")
		printf "Current sweep: [%s]\r", RemoveEnding(TextWaveToList(sweeps, ";"), ";")
		printf "DAQ: [%s]\r", RemoveEnding(TextWaveToList(daqStates, ";"), ";")
		printf "Testpulse: [%s]\r", RemoveEnding(TextWaveToList(tpStates, ";"), ";")
		printf "Experiment: %s (%s)\r", GetExperimentName(), GetExperimentFileType()
		printf "Igor Pro version: %s (%s)\r", GetIgorProVersion(), StringByKey("BUILD", IgorInfo(0))
		print "MIES version:"
		print miesVersionStr
		print "################################"

		ControlWindowToFront()
		Debugger
#endif // AUTOMATED_TESTING

#ifdef AUTOMATED_TESTING_DEBUGGING
		Debugger
#endif

		Abort
	endtry
End

/// @brief Low overhead function to check assertions (threadsafe variant)
///
/// @param var      if zero an error message is printed into the history and procedure
///                 execution is aborted, nothing is done otherwise.
/// @param errorMsg error message to output in failure case
///
/// Example usage:
/// \rst
///  .. code-block:: igorpro
///
///		ASSERT_TS(DataFolderExistsDFR(dfr), "dfr does not exist")
///		do something with dfr
/// \endrst
///
/// Unlike ASSERT() this function does not jump into the debugger (Igor Pro limitation).
///
/// @hidecallgraph
/// @hidecallergraph
threadsafe Function ASSERT_TS(var, errorMsg)
	variable var
	string errorMsg

	try
		AbortOnValue var==0, 1
	catch
#if IgorVersion() >= 9.0
		// Recursion detection, if ASSERT_TS appears multiple times in StackTrace
		if (ItemsInList(ListMatch(GetRTStackInfo(0), GetRTStackInfo(1))) > 1)

			print "Double threadsafe assertion Fail encountered !"

			AbortOnValue 1, 1
		endif
#endif

		print "!!! Threadsafe assertion FAILED !!!"
		printf "Message: \"%s\"\r", RemoveEnding(errorMsg, "\r")

#ifndef AUTOMATED_TESTING

		print "Please provide the following information if you contact the MIES developers:"
		print "################################"
		print "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
#endif // AUTOMATED_TESTING

#if !defined(AUTOMATED_TESTING) || defined(AUTOMATED_TESTING_DEBUGGING)

#if IgorVersion() >= 9.0
		print GetStackTrace()
#else
		print "stacktrace not available"
#endif

#endif // !AUTOMATED_TESTING || AUTOMATED_TESTING_DEBUGGING

#ifndef AUTOMATED_TESTING

		print "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
		printf "Time: %s\r", GetIso8601TimeStamp(localTimeZone = 1)
		printf "Experiment: %s (%s)\r", GetExperimentName(), GetExperimentFileType()
		printf "Igor Pro version: %s (%s)\r", GetIgorProVersion(), StringByKey("BUILD", IgorInfo(0))
		print "################################"

		printf "Assertion FAILED with message %s\r", errorMsg

#endif // AUTOMATED_TESTING

		AbortOnValue 1, 1
	endtry
End

/// @brief Checks if the given name exists as window
///
/// @hidecallgraph
/// @hidecallergraph
Function WindowExists(win)
	string win

	return WinType(win) != 0
End

/// @brief Alternative implementation for WaveList/VariableList/etc. which honours a dfref and thus
/// does not require SetDataFolder calls.
///
/// @param dfr                                  datafolder reference to search for the objects
/// @param matchExpr                            expression matching the objects, either a regular (exprType == MATCH_REGEXP)
///                                             or wildcard (exprType == MATCH_WILDCARD) expression
/// @param typeFlag [optional, default: COUNTOBJECTS_WAVES] One of @ref TypeFlags
/// @param fullPath [optional, default: false]  should only the object name or the absolute path of the object be returned
/// @param recursive [optional, default: false] descent into all subfolders recursively
/// @param exprType [optional, defaults: MATCH_REGEXP] convention used for matchExpr, one of @ref MatchExpressions
///
/// @returns list of object names matching matchExpr
Function/S GetListOfObjects(dfr, matchExpr, [typeFlag, fullPath, recursive, exprType])
	dfref dfr
	string matchExpr
	variable fullPath, recursive, typeFlag, exprType

	variable i, numFolders
	string name, folders, basePath, subList
	string list = ""

	ASSERT(DataFolderExistsDFR(dfr),"Non-existing datafolder")
	ASSERT(!isEmpty(matchExpr),"matchExpr is empty or null")

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

	if(ParamIsDefault(exprType))
		exprType = MATCH_REGEXP
	else
		ASSERT(exprType == MATCH_REGEXP || exprType == MATCH_WILDCARD, "Invalid exprType")
	endif

	basePath = GetDataFolder(1, dfr)

	list = ListMatchesExpr(GetAllObjects(dfr, typeFlag), matchExpr, exprType)

	if(fullPath)
		list = AddPrefixToEachListItem(basePath, list)
	endif

	if(recursive)
		folders = GetAllObjects(dfr, COUNTOBJECTS_DATAFOLDER)
		numFolders = ItemsInList(folders)
		for(i = 0; i < numFolders; i+=1)
			name = basePath + StringFromList(i, folders)
			DFREF subFolder = $name
			subList = GetListOfObjects(subFolder, matchExpr, typeFlag = typeFlag, fullPath=fullPath, recursive=recursive, exprType=exprType)
			if(!IsEmpty(subList))
				list = AddListItem(RemoveEnding(subList, ";"), list)
			endif
		endfor
	endif

	return list
End

/// @brief Return a list of all objects of the given type from dfr
///
/// Does not work for datafolders which have a comma (`,`) in them.
static Function/S GetAllObjects(dfr, typeFlag)
	DFREF dfr
	variable typeFlag

	string list

	DFREF oldDFR = GetDataFolderDFR()

	SetDataFolder dfr

	switch(typeFlag)
		case COUNTOBJECTS_WAVES:
			list = WaveList("*", ";", "")
			break
		case COUNTOBJECTS_VAR:
			list = VariableList("*", ";", 11)
			break
		case COUNTOBJECTS_STR:
			list = StringList("*", ";")
			break
		case COUNTOBJECTS_DATAFOLDER:
			list = DataFolderDir(2^0)
			list = StringByKey("FOLDERS", list)
			list = ReplaceString(",", list, ";")
			break
		default:
			SetDataFolder oldDFR
			ASSERT(0, "Invalid type flag")
	endswitch

	SetDataFolder oldDFR

	return list
End

/// @brief Matches `list` against the expression `matchExpr` using the given
///        convention in `exprType`
Function/S ListMatchesExpr(list, matchExpr, exprType)
	string list, matchExpr
	variable exprType

	switch(exprType)
		case MATCH_REGEXP:
			return GrepList(list, matchExpr)
		case MATCH_WILDCARD:
			return ListMatch(list, matchExpr)
		default:
			ASSERT(0, "invalid exprType")
	endswitch
End

/// @brief Redimension the wave to at least the given size.
///
/// The redimensioning is only done if it is required.
///
/// Can be used to fill a wave one at a time with the minimum number of
/// redimensions. In the following example `NOTE_INDEX` is the index of the
/// next free row *and* the total number of rows filled with data.
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
/// @param[in] dfr data folder to test
/// @returns one if dfr is valid and references an existing or free datafolder, zero otherwise
threadsafe Function DataFolderExistsDFR(DFREF dfr)

	return DataFolderRefStatus(dfr) != 0
End

/// @brief Check if the passed datafolder reference is a global/permanent datafolder
threadsafe Function IsGlobalDataFolder(DFREF dfr)

	return DataFolderExistsDFR(dfr) && DataFolderRefStatus(dfr) != 3
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
threadsafe Function IsInteger(var)
	variable var

	return IsFinite(var) && trunc(var) == var
End

threadsafe Function IsEven(variable var)

	return IsInteger(var) && mod(var, 2) == 0
End

threadsafe Function IsOdd(variable var)

	return IsInteger(var) && mod(var, 2) != 0
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

	/// @todo this should be removed as it does not belong into this function
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
threadsafe Function SetNumberInWaveNote(wv, key, val, [format])
	Wave wv
	string key
	variable val
	string format

	string str

	ASSERT_TS(WaveExists(wv), "Missing wave")
	ASSERT_TS(!IsEmpty(key), "Empty key")

	if(!ParamIsDefault(format))
		ASSERT_TS(!IsEmpty(format), "Empty format")
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
threadsafe Function SetStringInWaveNote(wv, key, str)
	Wave wv
	string key, str

	ASSERT_TS(WaveExists(wv), "Missing wave")
	ASSERT_TS(!IsEmpty(key), "Empty key")

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
/// @todo make this a generic cursor getter function and merge with
///       `cursors()` in @see SF_FormulaExecutor
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

	DeleteAnnotations/W=$graph/A
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

/// @brief Break a string into multiple lines
///
/// All spaces and tabs which are not followed by numbers are
/// replace by carriage returns (\\r) if the minimum width was reached.
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
///
/// @param str          string to break into lines
/// @param minimumWidth [optional, defaults to zero] Each line, except the last one,
///                     will have at least this length
Function/S LineBreakingIntoPar(str, [minimumWidth])
	string str
	variable minimumWidth

	variable len, i, width
	string output = ""
	string curr, next

	if(ParamIsDefault(minimumWidth))
		minimumWidth = 0
	else
		ASSERT(IsFinite(minimumWidth), "Non finite minimum width")
	endif

	len = strlen(str)
	for(i = 0; i < len; i += 1, width += 1)
		curr = str[i]
		next = SelectString(i < len, "", str[i + 1])

		// str2num skips leading spaces and tabs
		if((!cmpstr(curr, " ") || !cmpstr(curr, "\t"))                            \
		   && IsNaN(str2numSafe(next)) && cmpstr(next, " ") && cmpstr(next, "\t") \
		   && width >= minimumWidth)
				output += "\r"
				width = 0
				continue
		endif

		output += curr
	endfor

	return output
End

/// @brief Returns a reference to a newly created datafolder
///
/// Basically a datafolder aware version of UniqueName for datafolders
///
/// @param dfr 	    datafolder reference where the new datafolder should be created
/// @param baseName first part of the datafolder, might be shortend due to Igor Pro limitations
threadsafe Function/DF UniqueDataFolder(dfr, baseName)
	dfref dfr
	string baseName

	string path

	ASSERT_TS(!isEmpty(baseName), "baseName must not be empty" )

	path = UniqueDataFolderName(dfr, basename)

	if(isEmpty(path))
		return $""
	endif

	NewDataFolder $path
	return $path
End

/// @brief Return an absolute unique data folder name which does not exist in dfr
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
	ASSERT_TS(DataFolderRefStatus(dfr) != 3, "dfr can not be a free DF")

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
	baseName = CleanupName(baseName[0, MAX_OBJECT_NAME_LENGTH_IN_BYTES - 5], 0)
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

/// @brief Remove a prefix from a string
///
/// Same semantics as the RemoveEnding builtin for regExp == 0.
///
/// @param str    string to potentially remove something from its beginning
/// @param start  [optional, defaults to the first character] Remove this from
///               the begin pf str
/// @param regExp [optional, defaults to false] If start is a simple string (false)
///               or a regular expression (true)
threadsafe Function/S RemovePrefix(string str, [string start, variable regExp])
	variable length, pos, skipLength, err
	string regExpResult

	if(ParamIsDefault(regExp))
		regExp = 0
	else
		regExp = !!regExp
	endif

	length = strlen(str)

	if(ParamIsDefault(start))
		if(length <= 0)
			return str
		endif

		return str[1, length - 1]
	endif

	if(regExp)
		SplitString/E="^(" + start + ")" str, regExpResult; err = GetRTError(1)

		if(V_flag == 1 && err == 0)
			skipLength = strlen(regExpResult)
		else
			return str
		endif
	else
		pos = strsearch(str, start, 0)

		if(pos != 0)
			return str
		endif

		skipLength = strlen(start)
	endif

	return str[skipLength, length - 1]
End

/// @brief Returns a unique and non-existing file or folder name
///
/// @warning This function must *not* be used for security relevant purposes,
/// as for that the check-and-file-creation must be an atomic operation.
///
/// @param symbPath  symbolic path
/// @param baseName  base name of the file, must not be empty
/// @param suffix    file/folder suffix
Function/S UniqueFileOrFolder(symbPath, baseName, [suffix])
	string symbPath, baseName, suffix

	string file
	variable i = 1

	PathInfo $symbPath
	ASSERT(V_flag == 1, "Symbolic path does not exist")
	ASSERT(!isEmpty(baseName), "baseName must not be empty")

	if(ParamIsDefault(suffix))
		suffix = ""
	endif

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
threadsafe Function/S GetExperimentName()
	return IgorInfo(1)
End

/// @brief Return the experiment file type
threadsafe Function/S GetExperimentFileType()

#if IgorVersion() >= 9.0
	return IgorInfo(11)
#else
	if(!cmpstr(GetExperimentName(), UNTITLED_EXPERIMENT))
		return ""
	else
		// hardcoded to pxp
		return "Packed"
	endif
#endif

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

/// @brief Function prototype for use with #CallFunctionForEachListItem
threadsafe Function CALL_FUNCTION_LIST_PROTOTYPE_TS(str)
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

/// Compatibility wrapper for threadsafe functions `f`
///
/// @see CallFunctionForEachListItem()
threadsafe Function CallFunctionForEachListItem_TS(f, list, [sep])
	FUNCREF CALL_FUNCTION_LIST_PROTOTYPE_TS f
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

	string drive

	drive = GetDrive(absPath)
	return FolderExists(drive)
End

/// @brief Return the windows drive letter of the given path
Function/S GetDrive(string path)

	string drive

	path  = GetHFSPath(path)
	drive = StringFromList(0, path, ":")
	ASSERT(strlen(drive) == 1, "Expected a single letter for the drive")

	return drive
end

/// @brief Create a folder recursively on disk given an absolute path
///
/// If you pass windows style paths using backslashes remember to always *double* them.
Function CreateFolderOnDisk(absPath)
	string absPath

	string path, partialPath, tempPath
	variable numParts, i

	path = GetHFSPath(absPath)
	ASSERT(!FileExists(path), "The path which we should create exists, but points to a file")

	tempPath = UniqueName("tempPath", 12, 0)
	numParts = ItemsInList(path, ":")
	partialPath = GetDrive(path)

	// we skip the first one as that is the drive letter
	for(i = 1; i < numParts; i += 1)
		partialPath += ":" + StringFromList(i, path, ":")

		ASSERT(!FileExists(partialPath), "The path which we should create exists, but points to a file")

		NewPath/O/C/Q/Z $tempPath partialPath
	endfor

	KillPath/Z $tempPath

	ASSERT(FolderExists(partialPath), "Could not create the path, maybe the permissions were insufficient")
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
		ASSERT(IsWaveRefWave(wv), "wv must be a wave holding wave references")
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

/// @brief Return the minimum and maximum of both values
Function [variable minimum, variable maximum] MinMax(variable a, variable b)

	minimum = min(a, b)
	maximum = max(a, b)
End

/// @brief Return a new wave from the subrange of the given 1D wave
Function/WAVE DuplicateSubRange(wv, first, last)
	WAVE wv
	variable first, last

	ASSERT(DimSize(wv, COLS) == 0, "Requires 1D wave")

	Duplicate/RMD=[first, last]/FREE wv, result

	return result
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

/// @brief Return the path converted to a HFS style (aka ":" separated) path
Function/S GetHFSPath(string path)
	return ParseFilePath(5, path, ":", 0, 0)
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
		j =  floor(emax + enoise(emax, noiseGenMode))		//	random index
// 		emax + enoise(emax) ranges in random value from 0 to 2*emax = i
		temp		= inwave[j]
		inwave[j]	= inwave[i-1]
		inwave[i-1]	= temp
	endfor
end

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
///        return the new list
threadsafe Function/S RemovePrefixFromListItem(string prefix, string list, [string listSep, variable regExp])
	string result, entry
	variable numEntries, i

	if(ParamIsDefault(listSep))
		listSep = ";"
	endif

	if(ParamIsDefault(regExp))
		regExp = 0
	else
		regExp = !!regExp
	endif

	result = ""
	numEntries = ItemsInList(list, listSep)
	for(i = 0; i < numEntries; i += 1)
		entry = StringFromList(i, list, listSep)
		result = AddListItem(RemovePrefix(entry, start = prefix, regExp = regExp), result, listSep, inf)
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
threadsafe Function DateTimeInUTC()
	return DateTime - date2secs(-1, -1, -1)
End

/// @brief Return a string in ISO 8601 format with timezone UTC
/// @param secondsSinceIgorEpoch [optional, defaults to number of seconds until now] Seconds since the Igor Pro epoch (1/1/1904)
///                              in UTC (or local time zone depending on `localTimeZone`)
/// @param numFracSecondsDigits  [optional, defaults to zero] Number of sub-second digits
/// @param localTimeZone         [optional, defaults to false] Use the local time zone instead of UTC
threadsafe Function/S GetISO8601TimeStamp([secondsSinceIgorEpoch, numFracSecondsDigits, localTimeZone])
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
		ASSERT_TS(IsInteger(numFracSecondsDigits) && numFracSecondsDigits >= 0, "Invalid value for numFracSecondsDigits")
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

	string year, month, day, hour, minute, second, regexp, fracSeconds, tzOffsetSign, tzOffsetHour, tzOffsetMinute
	variable secondsSinceEpoch, timeOffset

	regexp = "^([[:digit:]]+)-([[:digit:]]+)-([[:digit:]]+)[T ]{1}([[:digit:]]+):([[:digit:]]+)(?::([[:digit:]]+)([.,][[:digit:]]+)?)?(?:Z|([\+-])([[:digit:]]+)(?::([[:digit:]]+))?)?$"
	SplitString/E=regexp timestamp, year, month, day, hour, minute, second, fracSeconds, tzOffsetSign, tzOffsetHour, tzOffsetMinute

	if(V_flag < 5)
		return NaN
	endif

	secondsSinceEpoch  = date2secs(str2num(year), str2num(month), str2num(day))
	secondsSinceEpoch += 60 * 60 * str2num(hour) + 60 * str2num(minute)
	if(!IsEmpty(second))
		secondsSinceEpoch += str2num(second)
	endif

	if(!IsEmpty(tzOffsetSign) && !IsEmpty(tzOffsetHour))
		timeOffset = str2num(tzOffsetHour) * 3600
		if(!IsEmpty(tzOffsetMinute))
			timeOffset -= str2num(tzOffsetMinute) * 60
		endif

		if(!cmpstr(tzOffsetSign, "+"))
			secondsSinceEpoch -= timeOffset
		elseif(!cmpstr(tzOffsetSign, "-"))
			secondsSinceEpoch += timeOffset
		else
			ASSERT(0, "Invalid case")
		endif
	endif

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

/// @brief Return an Igor-style path to the Igor Pro executable
Function/S GetIgorExecutable()
	string path = SpecialDirPath("Igor Executable", 0, 0, 0)

#ifdef IGOR64
	return path + "Igor64.exe"
#else
	return path + "Igor.exe"
#endif
End

/// @brief Recursively resolve shortcuts to files/directories
///
/// @return full path or an empty string if the file does not exist or the
/// 		shortcut points to a non existing file/folder
Function/S ResolveAlias(path, [pathName])
	string pathName, path

	if(ParamIsDefault(pathName))
		GetFileFolderInfo/Q/Z path
	else
		GetFileFolderInfo/P=$pathName/Q/Z path
	endif

	if(V_flag)
		return ""
	endif

	if(!V_IsAliasShortcut)
		return path
	endif

	if(ParamIsDefault(pathName))
		return ResolveAlias(S_aliasPath)
	else
		return ResolveAlias(S_aliasPath, pathName = pathName)
	endif
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
threadsafe Function/S GetIgorProVersion()
	return StringByKey("IGORFILEVERSION", IgorInfo(3))
End

/// @brief Return the Igor Pro build version string
///
/// This allows to distinguish different builds from the same major/minor
/// version.
Function/S GetIgorProBuildVersion()
	return StringByKey("BUILD", IgorInfo(0))
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
	else
		prefix = CleanupName(prefix, 0)
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

		fileOrPath = ResolveAlias(fileOrPath, pathName = pathName)

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
Function/S TextWaveToList(WAVE/T/Z txtWave, string sep, [string colSep, variable stopOnEmpty])
	string entry, colList
	string list = ""
	variable i, j, numRows, numCols

	if(!WaveExists(txtWave))
		return ""
	endif

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
Function/WAVE ListToTextWaveMD(list, dims, [rowSep, colSep, laySep, chuSep])
	string list
	variable dims
	string rowSep, colSep, laySep, chuSep

	variable colSize, laySize, chuSize
	variable rowMaxSize, colMaxSize, layMaxSize, chuMaxSize
	variable rowNr, colNr, layNr

	ASSERT(!isNull(list), "list input string is null")
	ASSERT(dims > 0 && dims <= 4, "number of dimensions must be > 0 and < 5")

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

/// @brief Convert a numeric wave to string list
///
/// Counterpart @see ListToNumericWave
/// @see TextWaveToList
///
/// @param wv     numeric wave
/// @param sep    separator
/// @param format [optional, defaults to `%g`] sprintf conversion specifier
threadsafe Function/S NumericWaveToList(WAVE/Z wv, string sep, [string format])

	string list = ""

	if(!WaveExists(wv))
		return ""
	endif

	if(ParamIsDefault(format))
		format = "%g"
	endif

	ASSERT_TS(IsNumericWave(wv), "Expected a numeric wave")
	ASSERT_TS(DimSize(wv, COLS) == 0, "Expected a 1D wave")

	if(IsFloatingPointWave(wv))
		ASSERT_TS(!GrepString(format, "%.*d"), "%d triggers an Igor bug")
	endif

	wfprintf list, format + sep, wv

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
Function/WAVE GetColfromWavewithDimLabel(wv, dimLabel)
	WAVE wv
	string dimLabel

	variable column = FindDimLabel(wv, COLS, dimLabel)
	ASSERT(column != -2, "dimLabel:" + dimLabel + "cannot be found")
	matrixOp/FREE OneDWv = col(wv, column)
	return OneDWv
End

/// @brief Turn a persistent wave into a free wave
Function/Wave MakeWaveFree(wv)
	WAVE wv

	DFREF dfr = NewFreeDataFolder()

	MoveWave wv, dfr

	return wv
End

/// @brief Sets the dimension labels of a wave
///
/// @param wv       Wave to add dim labels
/// @param list     List of dimension labels, semicolon separated.
/// @param dim      Wave dimension, see, @ref WaveDimensions
/// @param startPos [optional, defaults to 0] First dimLabel index
threadsafe Function SetDimensionLabels(wv, list, dim, [startPos])
	WAVE wv
	string list
	variable dim
	variable startPos

	string labelName
	variable i
	variable dimlabelCount = ItemsInlist(list)

	if(ParamIsDefault(startPos))
		startPos = 0
	endif

	ASSERT_TS(startPos >= 0, "Illegal negative startPos")
	ASSERT_TS(dimlabelCount <= DimSize(wv, dim) + startPos, "Dimension label count exceeds dimension size")
	for(i = 0; i < dimlabelCount;i += 1)
		labelName = StringFromList(i, list)
		SetDimLabel dim, i + startPos, $labelName, Wv
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
/// 	WAVE ranges = ExtractFromSubrange("[3,4]_[*]_[1, *;4]_[]_[5][]", 0)
/// \endrst
///
/// @param listOfRanges list of subrange specifications separated by **_**
/// @param dim          dimension to extract
///
/// @returns 2-dim wave with the start, stop, step as columns and rows as
///          number of elements. Returns -1 instead of `*` or ``. An invalid
///          wave reference is returned on parsing errors.
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
				return $""
			endif
		endif
	endfor

	return ranges
End

/// @brief Check if a name for an object adheres to the strict naming rules
///
/// @see `DisplayHelpTopic "ObjectName"`
threadsafe Function IsValidObjectName(name)
	string name

	return !cmpstr(name, CleanupName(name, 0, MAX_OBJECT_NAME_LENGTH_IN_BYTES))
End

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

/// @brief Find an integer `x` which is smaller than `a` but the
/// largest possible power of `p`.
///
/// @f$ x < a @f$ where @f$ x = c^p @f$ holds and @f$ x @f$ is
/// the largest possible value.
Function FindPreviousPower(a, p)
	variable a, p

	ASSERT(p > 1, "Invalid power")
	ASSERT(a > 0, "Invalid value")
	ASSERT(IsInteger(a), "Value has to be an integer")

	return floor(log(a)/log(p))
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

/// @brief Return 1 if the wave is a complex wave
threadsafe Function IsComplexWave(wv)
	WAVE wv

	return WaveType(wv) & IGOR_TYPE_COMPLEX
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

/// @brief Return a wave were all elements which are in both wave1 and wave2 have been removed from wave1
///
/// @sa GetListDifference for string lists
Function/WAVE GetSetDifference(wave1, wave2)
	WAVE wave1
	WAVE wave2

	variable numEntries, i, j, value

	ASSERT(IsFloatingPointWave(wave1) && IsFloatingPointWave(wave2), "Can only work with floating point waves.")
	ASSERT(WaveType(wave1) == WaveType(wave2), "Wave type mismatch")

	Duplicate/FREE wave1, result

	numEntries = DimSize(wave1, ROWS)
	for(i = 0; i < numEntries; i += 1)
		value = wave1[i]
		FindValue/UOFV/V=(value) wave2
		if(V_Value == -1)
			result[j++] = value
		endif
	endfor

	if(j == 0)
		return $""
	endif

	Redimension/N=(j) result

	return result
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
	elseif(WaveRefsEqual(wave1, wave2))
		Duplicate/FREE wave1, matches
		return matches
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
Function GetNumFromModifyStr(info, key, listChar, item)
	string info
	string key
	string listChar
	variable item

	string list, escapedListChar, regexp

	escapedListChar = "\\Q" + listChar + "\\E"

	sprintf regexp, "(?i)\\b\\Q%s\\E\([^=]+\)=%s([^});]+)", key, escapedListChar

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
		ASSERT(numMinSignDigits >= 0 && Isfinite(numMinSignDigits), "Invalid numDecimalDigits")
	endif

	numMag = ceil(log(abs(var)))

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

#if IgorVersion() >= 9.0

/// @brief Return a nicely formatted multiline stacktrace
threadsafe Function/S GetStackTrace([prefix])
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

#else

/// @brief Return a nicely formatted multiline stacktrace
Function/S GetStackTrace([prefix])
	string prefix

	string stacktrace, entry, func, line, file, str
	string output, module
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
		module = StringByKey("MODULE", FunctionInfo(func))

		if(!IsEmpty(module))
			func = module + "#" + func
		endif

		file  = StringFromList(1, entry, ",")
		line  = StringFromList(2, entry, ",")
		sprintf str, "%s%s(...)#L%s [%s]\r", prefix, func, line, file
		output += str
	endfor

	return output
End

#endif

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

	return WaveModCount(wv)
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

	numEntries = numpnts(wv)

	if(IsNumericWave(wv))
		ASSERT(IsFloatingPointWave(wv), "Requires floating point type or text wave")
		WAVE stats = wv
	else
		ASSERT(IsTextWave(wv), "Expected a text wave")
		WAVE/T wvText = wv
		Make/FREE/N=(numEntries) stats = strlen(wvText[p]) == 0 ? NaN : 1
	endif

	ASSERT(numEntries > 0, "Empty wave")

	WaveStats/Q/M=1 stats
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
	NewNotebook/K=2/V=0/F=0/N=HistoryCarbonCopy
End

/// @brief Return the text of the history notebook
Function/S GetHistoryNotebookText()

	if(!WindowExists("HistoryCarbonCopy"))
		return ""
	endif

	return GetNotebookText("HistoryCarbonCopy")
End

/// @brief Helper function for try/catch with AbortOnRTE
///
/// Not clearing the RTE before calling `AbortOnRTE` will always trigger the
/// RTE no matter what you do in that line. Any call to GetRTErrMessage() must
/// be done prior to clearing the runtime error in the catch block.
///
/// Usage:
/// \rst
/// .. code-block:: igorpro
///
///    try
///       ClearRTError()
///       myFunc(); AbortOnRTE
///    catch
///      err = ClearRTError()
///    endtry
///
/// \endrst
threadsafe Function ClearRTError()

	return GetRTError(1)
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

/// @brief Converts a number to a string with specified precision (digits after decimal dot).
/// This function is an extension for the regular num2str that is limited to 5 digits.
/// Input numbers are rounded using the "round-half-to-even" rule to the given precision.
/// The default precision is 5.
/// If val is complex only the real part is converted to a string.
/// @param[in] val       number that should be converted to a string
/// @param[in] precision [optional, default 5] number of precision digits after the decimal dot using "round-half-to-even" rounding rule.
///                      Precision must be in the range 0 to #MAX_DOUBLE_PRECISION.
/// @return string with textual number representation
Function/S num2strHighPrec(val, [precision])
	variable val, precision

	string str

	precision = ParamIsDefault(precision) ? 5 : precision
	ASSERT(precision >= 0 && precision <= MAX_DOUBLE_PRECISION, "Invalid precision, must be >= 0 and <= MAX_DOUBLE_PRECISION")

	sprintf str, "%.*f", precision, val

	return str
End

/// @brief Return the per application setting of ASLR for the Igor Pro executable
///
/// See https://docs.microsoft.com/en-us/windows/security/threat-protection/windows-defender-exploit-guard/enable-exploit-protection
/// for the powershell cmdlet documentation.
///
/// @returns 0 or 1
Function GetASLREnabledState()

	string cmd, entry, list, setting, result

	sprintf cmd, "powershell.exe -nologo -noprofile -command \"Get-ProcessMitigation -Name '%s'\"", GetWindowsPath(GetIgorExecutable())

#ifdef IGOR64
	ExecuteScriptText/B/Z cmd
#else
	ExecuteScriptText/Z cmd
#endif

	ASSERT(!V_flag, "Error executing process mitigation querying script.")
	result = S_Value

	if(IsEmpty(S_Value))
		return 1 // assuming system default is on
	endif

	entry = GrepList(S_value, "^[[:space:]]*BottomUp", 0, "\r\n")

	SplitString/E="^[[:space:]]*BottomUp[[:space:]]*: ([[:alnum:]]+)$" trimstring(entry), setting
	ASSERT(V_flag == 1, "Unexpected string")

	return !cmpstr(setting, "OFF") ? 0 : 1
End

/// @brief Turn off ASLR
///
/// Requires administrative privileges via UAC. Only required once for ITC hardware.
Function TurnOffASLR()
	string cmd, path

	path = GetFolder(FunctionPath("")) + "..:ITCXOP2:tools:Disable-ASLR-for-IP7-and-8.ps1"
	ASSERT(FileExists(path), "Could not locate powershell script")
	sprintf cmd, "powershell.exe -ExecutionPolicy Bypass \"%s\"", GetWindowsPath(path)
	ExecuteScriptText/B/Z cmd
	ASSERT(!V_flag, "Error executing ASLR script")
End

/// @brief Check if we are running on Windows 10
Function IsWindows10()
	string info, os

	info = IgorInfo(3)
	os = StringByKey("OS", info)
	return GrepString(os, "^Windows 10 ")
End

Function/WAVE WaveGetterPrototype()
	ASSERT(0, "Prototype called")
End

Function/WAVE GetElapsedTimeWaveWrapper()

	FUNCREF WaveGetterPrototype f = $"GetElapsedTimeWave"

	return f()
End

/// @brief Start a timer for performance measurements
///
/// Usage:
/// \rst
/// .. code-block:: igorpro
///
/// 	variable referenceTime = GetReferenceTime()
/// 	// part one to benchmark
/// 	print GetReferenceTime(referenceTime)
/// 	// part two to benchmark
/// 	print GetReferenceTime(referenceTime)
/// 	// you can also store all times via
/// 	StoreElapsedTime(referenceTime)
/// \endrst
Function GetReferenceTime()
	return stopmstimer(-2)
End

/// @brief Get the elapsed time in seconds
Function GetElapsedTime(referenceTime)
	variable referenceTime

	return (stopmstimer(-2) - referenceTime) / 1e6
End

/// @brief Store the elapsed time in a wave
Function StoreElapsedTime(referenceTime)
	variable referenceTime

	variable count, elapsed

	WAVE/D elapsedTime = GetElapsedTimeWaveWrapper()

	count = GetNumberFromWaveNote(elapsedTime, NOTE_INDEX)
	EnsureLargeEnoughWave(elapsedTime, minimumSize=count, initialValue = NaN)

	elapsed = GetElapsedTime(referenceTime)
	elapsedTime[count] = elapsed
	SetNumberInWaveNote(elapsedTime, NOTE_INDEX, count + 1)

	DEBUGPRINT("timestamp: ", var=elapsed)

	return elapsed
End

Function GetPlotArea(win, s)
	string win
	STRUCT RectD &s

	InitRectD(s)

	if(!WindowExists(win))
		return NaN
	endif

	GetWindow $win psizeDC

	s.left   = V_left
	s.right  = V_right
	s.top    = V_top
	s.bottom = V_bottom
End

/// @brief Check that the given path on disk has enough free space
///
/// @param diskPath          path on disk to check
/// @param requiredFreeSpace required free space in GB
Function HasEnoughDiskspaceFree(diskPath, requiredFreeSpace)
	string diskPath
	variable requiredFreeSpace

	variable leftOverBytes

	ASSERT(FolderExists(diskPath), "discPath does not point to an existing folder")

	leftOverBytes = MU_GetFreeDiskSpace(GetWindowsPath(diskPath))

	return IsFinite(leftOverBytes) && leftOverBytes >= requiredFreeSpace
End

threadsafe static Function FindLevelSingle(WAVE data, variable level, variable edge, variable first, variable last)

	variable found, numLevels

	FindLevel/Q/EDGE=(edge)/R=[first, last] data, level
	found = !V_flag

	if(!found)
		return NaN
	endif

	return V_LevelX - DimDelta(data, ROWS) * first
End

threadsafe static Function/WAVE FindLevelsMult(WAVE data, variable level, variable edge, variable first, variable last, variable maxNumLevels)
	variable found, numLevels

	Make/FREE/D/N=0 levels
	FindLevels/Q/DEST=levels/EDGE=(edge)/R=[first, last]/N=(maxNumLevels) data, level
	found = V_flag != 2
	numLevels = found ? DimSize(levels, ROWS) : 0

	Redimension/N=(numLevels) levels

	if(numLevels > 0)
		levels[] = levels[p] - DimDelta(data, ROWS) * first
	endif

	return levels
End

/// @brief FindLevel wrapper which handles 2D data without copying data
///
/// @param data         input data, can be either 1D or 2D
/// @param level        level to search
/// @param edge         type of the edge, one of @ref FindLevelEdgeTypes
/// @param mode         mode, one of @ref FindLevelModes
/// @param maxNumLevels [optional, defaults to number of points/rows] maximum number of levels to find
///
/// The returned levels are in the wave's row units.
///
/// FINDLEVEL_MODE_SINGLE:
/// - Return a 1D wave with as many rows as columns in the input data
/// - Contents are the x values of the first level or NaN if none could be found
///
/// FINDLEVEL_MODE_MULTI:
/// - Returns a 2D WAVE rows being the number of columns in the input
///   data and columns holding all found x values of the levels per data column.
///
/// In both cases the dimension label of the each column holds the number of found levels
/// in each data colum. This will be always 1 for FINDLEVEL_MODE_SINGLE.
threadsafe Function/WAVE FindLevelWrapper(WAVE data, variable level, variable edge, variable mode, [variable maxNumLevels])
	variable numCols, numColsFixed, numRows, xDelta, maxLevels, numLevels
	variable first, last, i, xLevel, found, columnOffset

	numCols = DimSize(data, COLS)
	numRows = DimSize(data, ROWS)
	numColsFixed = max(1, numCols)
	xDelta = DimDelta(data, ROWS)

	if(ParamIsDefault(maxNumLevels))
		maxNumLevels = numRows
	else
		ASSERT_TS(IsInteger(maxNumLevels) && maxNumLevels > 0, "maxNumLevels has to be a positive integer")
		ASSERT_TS(mode == FINDLEVEL_MODE_MULTI, "maxNumLevels can only be combined with FINDLEVEL_MODE_MULTI mode")
	endif

	ASSERT_TS(IsNumericWave(data), "Expected numeric wave")
	ASSERT_TS(numRows >= 2, "Expected wave with more than two rows")
	ASSERT_TS(IsFinite(level), "Expected finite level")
	ASSERT_TS(edge == FINDLEVEL_EDGE_INCREASING || edge == FINDLEVEL_EDGE_DECREASING || edge == FINDLEVEL_EDGE_BOTH, "Invalid edge type")
	ASSERT_TS(mode == FINDLEVEL_MODE_SINGLE || mode == FINDLEVEL_MODE_MULTI, "Invalid mode type")

	ASSERT_TS(DimSize(data, LAYERS) <= 1, "Unexpected input dimension")

	Redimension/N=(numColsFixed * numRows)/E=1 data

	// Algorithm:
	//
	// Both:
	// - Find the linearized slice of data which represents one column in the input wave
	//   and run a multi threaded function on it.
	//
	// FINDLEVEL_MODE_SINGLE:
	// - Run FindLevel on that slice
	//
	// FINDLEVEL_MODE_MULTI:
	// - Run FindLevels on that slice

	if(mode == FINDLEVEL_MODE_SINGLE)
		Make/D/FREE/N=(numColsFixed) resultSingle
		Multithread resultSingle[] = FindLevelSingle(data, level, edge, p * numRows, (p + 1) * numRows - 1)
	elseif(mode == FINDLEVEL_MODE_MULTI)
		Make/WAVE/FREE/N=(numColsFixed) allLevels
		Multithread allLevels[] = FindLevelsMult(data, level, edge, p * numRows, (p + 1) * numRows - 1, maxNumLevels)

		Make/D/FREE/N=(numColsFixed) numMaxLevels = DimSize(allLevels[p], ROWS)

		maxLevels = WaveMax(numMaxLevels)
		Make/D/FREE/N=(numColsFixed, maxLevels) resultMulti

		resultMulti[][] = q < numMaxLevels[p] ? WaveRef(allLevels[p])[q] : NaN
	endif

	// don't use numColsFixed here as we want to have the original shape
	Redimension/N=(numRows, numCols)/E=1 data

	switch(mode)
		case FINDLEVEL_MODE_SINGLE:
			Make/D/FREE/N=(DimSize(resultSingle, ROWS)) numMaxLevels = 1
			SetDimensionLabels(resultSingle, NumericWaveToList(numMaxLevels, ";"), ROWS)
			return resultSingle
		case FINDLEVEL_MODE_MULTI:
			SetDimensionLabels(resultMulti, NumericWaveToList(numMaxLevels, ";"), ROWS)

			// avoid single column waves
			if(DimSize(resultMulti, COLS) == 1)
				Redimension/N=(-1, 0) resultMulti
			endif

			return resultMulti
		default:
			ASSERT_TS(0, "Impossible case")
	endswitch
End

/// @brief Return a `/Z` flag value for the `Open` operation which works with
/// automated testing
Function GetOpenZFlag()
#ifdef AUTOMATED_TESTING
	return 1 // no dialog if the file does not exist
#else
	return 2
#endif
End

/// @brief Saves string data to a file
///
/// @param[in] data string containing data to save
/// @param[in] fileName fileName to use. If the fileName is empty or invalid a file save dialog will be shown.
/// @param[in] fileFilter [optional, default = "Plain Text Files (*.txt):.txt;All Files:.*;"] file filter string in Igor specific notation.
/// @param[in] message [optional, default = "Create file"] window title of the save file dialog.
/// @returns NaN if file open dialog was aborted or an error was encountered, 0 otherwise
Function SaveTextFile(data, fileName,[ fileFilter, message])
	string data, fileName, fileFilter, message

	variable fNum

	if(ParamIsDefault(fileFilter) && ParamIsDefault(message))
		Open/D=2 fnum as fileName
	elseif(ParamIsDefault(fileFilter) && !ParamIsDefault(message))
		Open/D=2/M=message fnum as fileName
	elseif(!ParamIsDefault(fileFilter) && ParamIsDefault(message))
		Open/D=2/F=fileFilter fnum as fileName
	else
		Open/D=2/F=fileFilter/M=message fnum as fileName
	endif

	if(IsEmpty(S_fileName))
		return NaN
	endif

	Open/Z fnum as S_fileName
	ASSERT(!V_flag, "Could not open file for writing!")

	FBinWrite fnum, data
	Close fnum

	return 0
End

/// @brief Load string data from file
///
/// @param[in] fileName fileName to use. If the fileName is empty or invalid a file load dialog will be shown.
/// @param[in] fileFilter [optional, default = "Plain Text Files (*.txt):.txt;All Files:.*;"] file filter string in Igor specific notation.
/// @param[in] message [optional, default = "Select file"] window title of the save file dialog.
/// @returns loaded string data and full path fileName
Function [string data, string fName] LoadTextFile(string fileName[, string fileFilter, string message])

	variable fNum, zFlag

	zFlag = GetOpenZFlag()

	if(ParamIsDefault(fileFilter) && ParamIsDefault(message))
		Open/R/Z=(zFlag) fnum as fileName
	elseif(ParamIsDefault(fileFilter) && !ParamIsDefault(message))
		Open/R/Z=(zFlag)/M=message fnum as fileName
	elseif(!ParamIsDefault(fileFilter) && ParamIsDefault(message))
		Open/R/Z=(zFlag)/F=fileFilter fnum as fileName
	else
		Open/R/Z=(zFlag)/F=fileFilter/M=message fnum as fileName
	endif

	if(IsEmpty(S_fileName) || V_flag)
		return ["", ""]
	endif

	FStatus fnum
	data = ""
	data = PadString(data, V_logEOF, 0x20)
	FBinRead fnum, data
	Close fnum

	return [data, S_Path + S_fileName]
End

/// @brief Removes first found entry from a 1D text wave
///
/// @param w 1D text wave
/// @param[in] entry element content to compare
Function RemoveTextWaveEntry1D(w, entry)
	WAVE/T w
	string entry

	if(IsNull(entry))
		return NaN
	endif

	ASSERT(IsTextWave(w), "Input wave must be a text wave")

	FindValue/TXOP=4/TEXT=entry w
	if(V_Value >= 0)
		DeletePoints V_Value, 1, w
	endif
End

/// @brief Checks if a string ends with a specific suffix
///
/// @param[in] str string to check for suffix
/// @param[in] suffix to check for
/// @returns 1 if str ends with suffix, 0 otherwise. If str and/or suffix are empty or null 0 is returned.
Function StringEndsWith(str, suffix)
	string str, suffix

	variable pos

	if(IsNull(str) || IsNull(suffix))
		return 0
	endif

	pos = strsearch(str, suffix, Inf, 1)
	if(pos == -1)
		return 0
	endif

	if(pos == strlen(str) - strlen(suffix))
		return 1
	endif

	return 0
End

/// @brief Splits a 1d text wave into two waves. The first contains elements with a suffix, the second elements without.
///
/// @param[in] source 1d text wave
/// @param[in] suffix string suffix to distinguish elements
/// @returns two 1d text waves, the first contains all elements with the suffix, the second all elements without
Function [WAVE/T withSuffix, WAVE/T woSuffix] SplitTextWaveBySuffix(WAVE/T source, string suffix)

	variable i, numElems

	if(IsNull(suffix))
		Make/FREE/T woSuffix = {""}
		return [source, woSuffix]
	endif

	Duplicate/FREE/T source, withSuffix, woSuffix

	numElems = DimSize(source, ROWS)
	for(i = numElems - 1; i >= 0; i -= 1)
		if(!StringEndsWith(withSuffix[i], suffix))
			DeletePoints i, 1, withSuffix
		endif
		if(StringEndsWith(woSuffix[i], suffix))
			DeletePoints i, 1, woSuffix
		endif
	endfor

	return [withSuffix, woSuffix]
End

/// @brief Check wether the given path points to an existing file
///
/// Resolves shortcuts and symlinks recursively.
Function FileExists(filepath)
	string filepath

	filepath = ResolveAlias(filepath)
	GetFileFolderInfo/Q/Z filepath

	return !V_Flag && V_IsFile
End

/// @brief Check wether the given path points to an existing folder
Function FolderExists(folderpath)
	string folderpath

	folderpath = ResolveAlias(folderpath)
	GetFileFolderInfo/Q/Z folderpath

	return !V_Flag && V_isFolder
End

/// @brief Return the file version
Function/S GetFileVersion(filepath)
	string filepath

	filepath = ResolveAlias(filepath)
	GetFileFolderInfo/Q/Z filepath

	if(V_flag || !V_isFile)
		return ""
	endif

	return S_FileVersion
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
Function ScaleToIndexWrapper(wv, scale, dim)
	WAVE wv
	variable scale, dim

	variable index

	ASSERT(dim >= 0 && dim < 4, "Dimension out of range")
	ASSERT(trunc(dim) == dim, "invalid format for dimension")

	if(IsFinite(scale))
		index = ScaleToIndex(wv, scale, dim)
	else
		index = sign(scale) * sign(DimDelta(wv, dim)) * inf
	endif

	if(dim >= WaveDims(wv))
		return 0
	endif

	return min(DimSize(wv, dim) - 1, max(0, trunc(index)))
End

/// @brief Syncs data from a source json into a target json.
/// @param[in] srcJsonID json Id of source object
/// @param[in] tgtJsonID json Id of target object
/// @param[in] srcPath root path for sync in source object
/// @param[in] tgtPath root path for sync in target
/// @param[in] srcFile file name of source JSON rig file, used for more specific error message
///                    in case of conflict. If "" is given then a more unspecific error message is given.
Function SyncJSON(srcJsonID, tgtJsonID, srcPath, tgtPath, srcFile)
	variable srcJsonID, tgtJsonID
	string srcPath, tgtPath, srcFile

	variable type, i, numKeys, arraySize, parentIsArray
	string localTgtPath

	ASSERT(!IsNull(srcPath), "Invalid source path")
	ASSERT(!IsNull(tgtPath), "Invalid target path")

	localTgtPath = tgtPath + srcPath
	parentIsArray = IsJsonParentArray(srcJsonID, srcPath)
	type = JSON_GetType(srcJsonID, srcPath)
	if(type != JSON_OBJECT && !parentIsArray)
		if(JSON_Exists(tgtJsonID, localTgtPath))
			if(IsEmpty(srcFile))
				printf "Aborting: JSON element in source at\r%s\rconflicts with element at\r%s\rin main file.\r", srcPath, localTgtPath
			else
				printf "Aborting: Found conflict in file %s.\r", srcFile
				printf "JSON element in source at\r%s\rconflicts with element at\r%s\rin main file.\r", srcPath, localTgtPath
			endif
			ControlWindowToFront()
			Abort
		endif
	endif

	if(type == JSON_OBJECT)
		if(parentIsArray)
			JSON_SetObjects(tgtJsonID, localTgtPath)
		else
			JSON_AddTreeObject(tgtJsonID, localTgtPath)
		endif

		WAVE/T keys = JSON_GetKeys(srcJsonID, srcPath)
		numKeys = DimSize(keys, ROWS)
		for(i = 0; i < numKeys; i += 1)
			SyncJSON(srcJsonID, tgtJsonID, srcPath + "/" + keys[i], tgtPath, srcFile)
		endfor
	elseif(type == JSON_ARRAY)
		if(parentIsArray)
			JsonSetEmptyArray(tgtJsonID, localTgtPath)
		else
			if(JSON_Exists(tgtJsonID, localTgtPath))
				if(IsEmpty(srcFile))
					printf "Aborting: JSON array in source at\r%s\rconflicts with element at\r%s\rin main file.\r", srcPath, localTgtPath
				else
					printf "Aborting: Found conflict in file %s.\r", srcFile
					printf "JSON array in source at\r%s\rconflicts with element at\r%s\rin main file.\r", srcPath, localTgtPath
				endif
				ControlWindowToFront()
				Abort
			endif
			JSON_AddTreeArray(tgtJsonID, localTgtPath)
		endif

		arraySize = JSON_GetArraySize(srcJsonID, srcPath)
		JSON_AddObjects(tgtJsonID, localTgtPath, objCount = arraySize)
		for(i = 0; i < arraySize; i += 1)
			SyncJSON(srcJsonID, tgtJsonID, srcPath + "/" + num2istr(i), tgtPath, srcFile)
		endfor
	elseif(type == JSON_NUMERIC)
		JSON_SetVariable(tgtJsonID, localTgtPath, JSON_GetVariable(srcJsonID, srcPath))
	elseif(type == JSON_STRING)
		JSON_SetString(tgtJsonID, localTgtPath, JSON_GetString(srcJsonID, srcPath))
	elseif(type == JSON_BOOL)
		JSON_SetBoolean(tgtJsonID, localTgtPath, JSON_GetVariable(srcJsonID, srcPath))
	elseif(type == JSON_NULL)
		JSON_SetNull(tgtJsonID, localTgtPath)
	else
		ASSERT(0, "Invalid type")
	endif

End

/// @brief Returns true if the parent path is an array.
/// @param[in] jsonID Id of json
/// @param[in] path location where parent is checked, for path "/parent/data" the location "/parent" is checked. For path "" the location "" is checked.
static Function IsJsonParentArray(jsonID, path)
	variable jsonID
	string path

	variable pos = strsearch(path, "/", Inf, 1)
	if(pos >= 0)
		path = path[0, pos - 1]
	endif
	return JSON_GetType(jsonID, path) == JSON_ARRAY
End

/// @brief Sets an empty array in a json
/// @param[in] jsonID Id of json
/// @param[in] path location where empty array is placed
static Function JsonSetEmptyArray(jsonID, path)
	variable jsonID
	string path

	Make/FREE/N=1 w

	JSON_SetWave(jsonID, path, w)
	JSON_Remove(jsonID, path + "/0")
End

/// @brief Return the name of a symbolic path which points to the crash dump
/// directory on windows
Function/S GetSymbolicPathForDiagnosticsDirectory()

	string userName, path, symbPath

	userName = GetSystemUserName()

	sprintf path, "C:Users:%s:AppData:Roaming:WaveMetrics:Igor Pro %s:Diagnostics:", userName, GetIgorProVersion()[0]

	if(!FolderExists(path))
		CreateFolderOnDisk(path)
	endif

	symbPath = "crashInfo"

	NewPath/O/Q $symbPath, path

	return symbPath
End

Function ShowDiagnosticsDirectory()

	string symbPath = GetSymbolicPathForDiagnosticsDirectory()
	PathInfo/SHOW $symbPath
End

/// @brief Helper structure for GenerateRFC4122UUID()
static Structure Uuid
	uint32  time_low
	uint16  time_mid
	uint16  time_hi_and_version
	uint16  clock_seq
	uint16  node0
	uint16  node1
	uint16  node2
EndStructure

/// @brief Generate a version 4 UUID according to https://tools.ietf.org/html/rfc4122
///
/// \rst
/// .. code-block:: text
///
///     4.4.  Algorithms for Creating a UUID from Truly Random or
///           Pseudo-Random Numbers
///
///        The version 4 UUID is meant for generating UUIDs from truly-random or
///        pseudo-random numbers.
///
///        The algorithm is as follows:
///
///        o  Set the two most significant bits (bits 6 and 7) of the
///           clock_seq_hi_and_reserved to zero and one, respectively.
///
///        o  Set the four most significant bits (bits 12 through 15) of the
///           time_hi_and_version field to the 4-bit version number from
///           Section 4.1.3.
///
///        o  Set all the other bits to randomly (or pseudo-randomly) chosen
///           values.
///
///     See Section 4.5 for a discussion on random numbers.
///
///     [...]
///
///      In the absence of explicit application or presentation protocol
///      specification to the contrary, a UUID is encoded as a 128-bit object,
///      as follows:
///
///      The fields are encoded as 16 octets, with the sizes and order of the
///      fields defined above, and with each field encoded with the Most
///      Significant Byte first (known as network byte order).  Note that the
///      field names, particularly for multiplexed fields, follow historical
///      practice.
///
///      0                   1                   2                   3
///       0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
///      +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
///      |                          time_low                             |
///      +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
///      |       time_mid                |         time_hi_and_version   |
///      +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
///      |clk_seq_hi_res |  clk_seq_low  |         node (0-1)            |
///      +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
///      |                         node (2-5)                            |
///      +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
///
///     [...]
///
///     4.1.3.  Version
///
///        The version number is in the most significant 4 bits of the time
///        stamp (bits 4 through 7 of the time_hi_and_version field).
///
///        The following table lists the currently-defined versions for this
///        UUID variant.
///
///        Msb0  Msb1  Msb2  Msb3   Version  Description
///
///         0     0     0     1        1     The time-based version
///                                          specified in this document.
///
///         0     0     1     0        2     DCE Security version, with
///                                          embedded POSIX UIDs.
///
///         0     0     1     1        3     The name-based version
///                                          specified in this document
///                                          that uses MD5 hashing.
///
///         0     1     0     0        4     The randomly or pseudo-
///                                          randomly generated version
///                                          specified in this document.
///
///         0     1     0     1        5     The name-based version
///                                          specified in this document
///                                          that uses SHA-1 hashing.
///
///        The version is more accurately a sub-type; again, we retain the term
///        for compatibility.
///
/// \endrst
///
/// See also https://www.rfc-editor.org/errata/eid3546 and https://www.rfc-editor.org/errata/eid1957
/// for some clarifications.
Function/S GenerateRFC4122UUID()

	string str, randomness
	STRUCT Uuid uu

	randomness = Hash(num2strHighPrec(GetReproducibleRandom(), precision=15), 1)

	WAVE binary = HexToBinary(randomness)

	uu.time_low = binary[0] | (binary[1] << 8) | (binary[2] << 16) | (binary[3] << 24)
	uu.time_mid = binary[4] | (binary[5] << 8)
	uu.time_hi_and_version = binary[6] | (binary[7] << 8)
	uu.clock_seq = binary[8] | (binary[9] << 8)

	uu.node0 = binary[10] | (binary[11] << 8)
	uu.node1 = binary[12] | (binary[13] << 8)
	uu.node2 = binary[14] | (binary[15] << 8)

	// set the version
	uu.clock_seq = (uu.clock_seq & 0x3FFF) | 0x8000
	uu.time_hi_and_version = (uu.time_hi_and_version & 0x0FFF) | 0x4000

	sprintf str, "%8.8x-%4.4x-%4.4x-%4.4x-%4.4x%4.4x%4.4x", uu.time_low, uu.time_mid, uu.time_hi_and_version, uu.clock_seq, uu.node0, uu.node1, uu.node2

	return str
End

/// @brief Convert a hexadecimal character into a number
Function HexToNumber(ch)
	string ch

	variable var

	ASSERT(strlen(ch) <= 2, "Expected only up to two characters")

	sscanf ch, "%x", var
	ASSERT(V_flag == 1, "Unexpected string")

	return var
End

/// @brief Convert a number into hexadecimal
Function/S NumberToHex(var)
	variable var

	string str

	ASSERT(IsInteger(var) && var >= 0 && var < 256 , "Invalid input")

	sprintf str, "%02x", var

	return str
End

/// @brief Convert a string in hex format to an unsigned binary wave
///
/// This function works on a byte level so it does not care about endianess.
Function/WAVE HexToBinary(str)
	string str

	variable length

	length = strlen(str)
	ASSERT(mod(length, 2) == 0, "Expected a string with a power of 2 length")

	Make/N=(length / 2)/FREE/B/U bin = HexToNumber(str[p * 2]) | (HexToNumber(str[p * 2 + 1]) << 4)

	return bin
End

/// @brief Turn a list of entries into a regular expression with alternations.
///
/// Can be used for GetListOfObjects() if you know in advance which entries to filter out.
Function/S ConvertListToRegexpWithAlternations(list)
	string list

	variable i, numEntries
	string entry
	string regexpList = ""

	numEntries = ItemsInList(list)
	for(i = 0; i < numEntries; i += 1)
		regexpList = AddListItem("\\Q" + StringFromList(i, list) + "\\E", regexpList, "|", inf)
	endfor

	regexpList = "(?:" + RemoveEnding(regexpList, "|") + ")"

	return regexpList
End

/// @brief Helper function for UploadCrashDumps
///
/// Fill `payload` array with content from files
Function AddPayloadEntriesFromFiles(variable jsonID, WAVE/T paths, [variable isBinary])
	string data, fName, filepath, jsonpath
	variable numEntries, i, offset

	numEntries = DimSize(paths, ROWS)
	Make/FREE/N=(numEntries)/T values, keys

	for(i = 0; i < numEntries; i += 1)
		[data, fName] = LoadTextFile(paths[i])
		values[i] = data

		keys[i] = GetFile(paths[i])
	endfor

	AddPayloadEntries(jsonID, keys, values, isBinary = isBinary)
End

/// @brief Helper function for UploadCrashDumps
///
/// Fill `payload` array
Function AddPayloadEntries(variable jsonID, WAVE/T keys, WAVE/T values, [variable isBinary])
	string jsonpath
	variable numEntries, i, offset

	numEntries = DimSize(keys, ROWS)
	ASSERT(numEntries == DimSize(values, ROWS), "Mismatched dimensions")

	if(ParamIsDefault(isBinary))
		isBinary = 0
	else
		isBinary = !!isBinary
	endif

	if(!JSON_Exists(jsonID, "/payload"))
		JSON_AddTreeArray(jsonID, "/payload")
	endif

	if(!numEntries)
		return NaN
	endif

	offset = JSON_GetArraySize(jsonID, "/payload")
	JSON_AddObjects(jsonID, "/payload", objCount = numEntries)

	for(i = 0; i < numEntries; i += 1)
		jsonpath = "/payload/" + num2str(offset + i) + "/"

		JSON_AddString(jsonID, jsonpath + "name", keys[i])

		if(isBinary)
			JSON_AddString(jsonID, jsonpath + "encoding", "base64")
			JSON_AddString(jsonID, jsonpath + "contents", Base64Encode(values[i]))
		else
			JSON_AddString(jsonID, jsonpath + "contents", values[i])
		endif
	endfor
End

/// @brief Upload the given JSON document
///
/// See `tools/http-upload/upload-json-payload-v1.php` for the JSON format description.
Function UploadJSONPayload(jsonID)
	variable jsonID

	URLrequest/DSTR=JSON_Dump(jsonID) url="https://ai.customers.byte-physics.de/upload-json-payload-v1.php", method=put
	ASSERT(!V_Flag, "URLrequest did not succeed due to: " + S_ServerResponse)
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

/// @brief Wrapper for `Grep` which uses a textwave for input and ouput
Function/WAVE GrepWave(WAVE/T wv, string regex)

	Make/FREE/T/N=0 result
	Grep/E=regex wv as result

	if(DimSize(result, ROWS) == 0)
		return $""
	endif

	return result
End

/// @brief Parse a color specification as used by ModifyGraph having an optionl
/// translucency part
Function [STRUCT RGBAColor result] ParseColorSpec(string str)

	string str1, str2, str3, str4

	SplitString/E="^[[:space:]]*\([[:space:]]*([[:digit:]]+)[[:space:]]*,[[:space:]]*([[:digit:]]+)[[:space:]]*,[[:space:]]*([[:digit:]]+)[[:space:]]*(?:,[[:space:]]*([[:digit:]]+))*[[:space:]]*\)$" str, str1, str2, str3, str4
	ASSERT(V_Flag == 3 || V_Flag == 4, "Invalid color spec")

	result.red   = str2num(str1)
	result.green = str2num(str2)
	result.blue  = str2num(str3)
	result.alpha = (V_Flag == 4) ? str2num(str4) : 655356
End

/// @brief Determine min and max
threadsafe Function [variable minimum, variable maximum] WaveMinAndMaxWrapper(WAVE wv, [variable x1, variable x2])

	if(ParamIsDefault(x1) && ParamIsDefault(x2))
#if IgorVersion() < 9.0
		minimum = WaveMin(wv)
		maximum = WaveMax(wv)
#else
	   [minimum, maximum] = WaveMinAndMax(wv)
#endif
	elseif(!ParamIsDefault(x1) && !ParamIsDefault(x2))
#if IgorVersion() < 9.0
		minimum = WaveMin(wv, x1, x2)
		maximum = WaveMax(wv, x1, x2)
#else
	   [minimum, maximum] = WaveMinAndMax(wv, x1, x2)
#endif
	else
		ASSERT_TS(0, "Unsupported case")
	endif
End

/// @brief Helper function to be able to index waves stored in wave reference
/// waves in wave assignment statements.
///
/// The case where wv contains wave references is also covered by the optional parameters.
/// While returned regular waves can be indexed within the assignment as shown in the first example,
/// this does not work for wave reference waves. Thus, the parameters allow to index through the function call.
///
/// Example for source containing regular waves:
/// \rst
/// .. code-block:: igorpro
///
/// Make/FREE data1 = p
/// Make/FREE data2 = p^2
/// Make/FREE/WAVE source = {data1, data2}
///
/// Make/FREE dest
/// dest[] = WaveRef(source[0])[p] + WaveRef(source[1])[p] // note the direct indexing [p] following WaveRef(...) here
///
/// \endrst
///
/// Example for source containing wave ref waves:
/// \rst
/// .. code-block:: igorpro
///
/// Make/FREE data1 = p
/// Make/FREE/WAVE interm = {data1, data1}
/// Make/FREE/WAVE source = {interm, interm}
///
/// Make/FREE/WAVE/N=2 dest
/// dest[] = WaveRef(source[p], row = 0) // direct indexing does not work here, so we index through the optional function parameter
///
/// \endrst
///
/// row, col, layer, chunk are evaluated in this order until one argument is not given.
///
/// @param w input wave ref wave
/// @param row [optional, default = n/a] when param set returns wv[row] typed
/// @param col [optional, default = n/a] when param row and this set returns wv[row][col] typed
/// @param layer [optional, default = n/a] when param row, col and this set returns wv[row][col][layer] typed
/// @param chunk [optional, default = n/a] when param row, col, layer and this set returns wv[row][layer][chunk] typed
/// @returns untyped waveref of wv or typed wave ref of wv when indexed
threadsafe Function/WAVE WaveRef(WAVE/Z w, [variable row, variable col, variable layer, variable chunk])

	if(!WaveExists(w))
		return $""
	endif

	WAVE/WAVE wv = w

	if(ParamIsDefault(row))
		return wv
	elseif(ParamIsDefault(col))
		return wv[row]
	elseif(ParamIsDefault(layer))
		return wv[row][col]
	elseif(ParamIsDefault(chunk))
		return wv[row][col][layer]
	else
		return wv[row][col][layer][chunk]
	endif
End

/// @brief Grep the given regular expression in the text wave
Function/WAVE GrepTextWave(Wave/T in, string regexp)

	Make/FREE/T/N=0 result
	Grep/E=regexp in as result

	if(DimSize(result, ROWS) == 0)
		return $""
	endif

	return result
End

/// @brief Given a range `[a, b]` this returns a symmetric range around zero including both elements
Function [variable minSym, variable maxSym] SymmetrizeRangeAroundZero(variable minimum, variable maximum)

	variable maxVal

	maxVal = max(abs(minimum), abs(maximum))
	return [-maxVal, +maxVal]
End

/// @brief Helper function for multithread statements where `? :` does not work with wave references
///
/// The order of arguments is modelled after SelectString/SelectNumber.
threadsafe Function/WAVE SelectWave(variable condition, WAVE/Z waveIfFalse, WAVE/Z waveIfTrue)
	if(!!condition != 0)
		return waveIfTrue
	else
		return waveIfFalse
	endif
End

/// @brief Distribute N elements over a range from 0.0 to 1.0 with spacing
Function [WAVE/D start, WAVE/D stop] DistributeElements(variable numElements, [variable offset])

	variable elementLength, spacing

	ASSERT(numElements > 0, "Invalid number of elements")

	if(!ParamIsDefault(offset))
		ASSERT(IsFinite(offset) && offset >= 0.0 && offset < 1.0, "Invalid offset")
	endif

	// limit the spacing for a lot of entries
	// we only want to use 20% for spacing in total
	if((numElements - 1) * GRAPH_DIV_SPACING > 0.20)
		spacing = 0.20 / (numElements - 1)
	else
		spacing = GRAPH_DIV_SPACING
	endif

	elementLength = (1.0 - offset - (numElements - 1) * spacing) / numElements

	Make/FREE/D/N=(numElements) start, stop

	start[] = limit(offset + p * (elementLength + spacing), 0.0, 1.0)
	stop[] = limit(start[p] + elementLength, 0.0, 1.0)

	return [start, stop]
End

/// @brief Calculate a nice length which is an integer number of `multiple` long
///
/// For small values @f$ 10^{-x} @f$ times `multiple` are returned
Function CalculateNiceLength(variable range , variable multiple)

	variable div, numDigits

	div = range / multiple
	numDigits = log(div)

	if(numDigits > 0)
		return round(div) * multiple
	endif

	return multiple * 10^(round(numDigits))
End

/// @brief Remove unused rows from the passed wave and return a copy of it.
///
/// @see EnsureLargeEnoughWave()
Function/WAVE RemoveUnusedRows(WAVE wv)

	variable index

	index = GetNumberFromWaveNote(wv, NOTE_INDEX)

	if(IsNaN(index))
		return wv
	elseif(index == 0)
		return $""
	endif

	ASSERT(IsInteger(index) && index > 0, "Expected strictly positive and integer NOTE_INDEX")

	Duplicate/FREE/RMD=[0, index - 1] wv, dup

	return dup
End

/// @brief Check wether `val1` and `val2` are equal or both NaN
threadsafe Function EqualValuesOrBothNaN(variable left, variable right)

	return (IsNaN(left) && IsNaN(right)) || (left == right)
End

/// @brief Checks wether `wv` is constant and has the value `val`
Function IsConstant(WAVE wv, variable val)

	variable minimum, maximum

	[minimum, maximum] = WaveMinAndMaxWrapper(wv)

	return (minimum == val && maximum == val) || (IsNaN(minimum) && IsNaN(maximum) && IsNaN(val))
End

/// @brief Sanitize the given name so that it is a nice file name
Function/S SanitizeFilename(string name)

	variable numChars, i
	string result, regexp

	numChars = strlen(name)

	ASSERT(numChars > 0, "name can not be empty")

	result	 = ""
	regexp = "^[A-Za-z_\-0-9\.]+$"

	for(i = 0; i < numChars; i += 1)
		if(GrepString(name[i], regexp))
			result[i] = name[i]
		else
			result[i] = "_"
		endif
	endfor

	ASSERT(GrepString(result, regexp), "Invalid file name")

	return result
End

/// @brief Merges list l1 into l2. Double entries in l2 are kept.
/// "a;b;c;" with "a;d;d;f;" -> "a;d;d;f;b;c;"
Function/S MergeLists(string l1, string l2, [string sep])

	variable numL1, i
	string item

	if(ParamIsDefault(sep))
		sep = ";"
	else
		ASSERT(!IsEmpty(sep), "separator string is empty")
	endif

	numL1 = ItemsInList(l1, sep)
	for(i = 0; i < numL1; i += 1)
		item = StringFromList(i, l1, sep)
		if(WhichListItem(item, l2, sep) == -1)
			l2 = AddListItem(item, l2, sep, inf)
		endif
	endfor

	return l2
End

/// @brief Duplicates the input wave to a free wave and returns the free wave reference.
threadsafe Function/WAVE DuplicateWaveToFree(Wave w)

	Duplicate/FREE w, wFree

	return wFree
End

/// @brief Removes all NaNs from the input wave
Function/WAVE ZapNaNs(WAVE data)

	ASSERT(IsFloatingPointWave(data), "Can only work with floating point waves")

	if(DimSize(data, ROWS) == 0)
		return $""
	endif

#if IgorVersion() >= 9
	MatrixOP/FREE dup = zapNans(data)
#else
	Duplicate/FREE data, dup
	WaveTransform/O zapNans, dup
#endif

	if(DimSize(dup, ROWS) == 0)
		return $""
	endif

	return dup
End

/// @brief Finds the first occurrence of a text within a range of points in a SORTED text wave
///
/// From https://www.wavemetrics.com/code-snippet/binary-search-pre-sorted-text-waves by Jamie Boyd
/// Completely reworked, fixed and removed unused features
Function BinarySearchText(WAVE/T theWave, string theText, [variable caseSensitive, variable startPos, variable endPos])
	variable iPos // the point to be compared
	variable theCmp // the result of the comparison
	variable firstPt
	variable lastPt
	variable i
	variable numRows

	numRows = DimSize(theWave, ROWS)

	ASSERT_TS(DimSize(theWave, COLS) <= 1, "Only works with 1D waves")
	ASSERT_TS(IsTextWave(theWave), "Only works with text waves")

	if(numRows == 0)
		// always no match
		return NaN
	endif

	if(ParamIsDefault(startPos))
		startPos = 0
	else
		ASSERT_TS(startPos >= 0 && startPos < numRows, "Invalid startPos")
	endif

	if(ParamIsDefault(endPos))
		endPos = numRows - 1
	else
		ASSERT_TS(endPos >= 0 && endPos < numRows, "Invalid endPos")
	endif

	ASSERT_TS(startPos <= endPos, "startPos is larger than endPos")

	firstPt = startPos
	lastPt  = endPos

	for(i = 0; firstPt <= lastPt; i +=1)
		iPos = trunc((firstPt + lastPt) / 2)
		theCmp = cmpstr(thetext, theWave[iPos])

		if(theCmp ==0) //thetext is the same as theWave [iPos]
			if((iPos == startPos) || (cmpstr(theText, theWave[iPos -1]) == 1))
				// then iPos is the first occurence of thetext in theWave from startPos to endPos
				return iPos
			else //  there are more copies of theText in theWave before iPos
				lastPt = iPos-1
			endif
		elseif (theCmp == 1) //thetext is alphabetically after theWave [iPos]
			firstPt = iPos +1
		else // thetext is alphabetically before theWave [iPos]
			lastPt = iPos -1
		endif
	endfor

	return NaN
end
