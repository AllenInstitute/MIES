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
/// UTF_NOINSTRUMENTATION
threadsafe Function IsFinite(var)
	variable var

	return numType(var) == 0
End

/// @brief Returns 1 if var is a NaN, 0 otherwise
///
/// @hidecallgraph
/// @hidecallergraph
/// UTF_NOINSTRUMENTATION
threadsafe Function IsNaN(var)
	variable var

	return numType(var) == 2
End

/// @brief Returns 1 if var is +/- inf, 0 otherwise
///
/// @hidecallgraph
/// @hidecallergraph
/// UTF_NOINSTRUMENTATION
threadsafe Function IsInf(variable var)

	return numType(var) == 1
End

/// @brief Returns 1 if str is null, 0 otherwise
/// @param str must not be a SVAR
///
/// @hidecallgraph
/// @hidecallergraph
/// UTF_NOINSTRUMENTATION
threadsafe Function IsNull(str)
	string& str

	variable len = strlen(str)
	return numtype(len) == 2
End

/// @brief Returns one if str is empty, zero otherwise.
/// @param str any non-null string variable or text wave element
///
/// @hidecallgraph
/// @hidecallergraph
/// UTF_NOINSTRUMENTATION
threadsafe Function IsEmpty(string str)

	return !(strlen(str) > 0)
End

/// @brief Low overhead function to check assertions
///
/// @param var            if zero an error message is printed into the history and procedure execution is aborted,
///                       nothing is done otherwise.  If the debugger is enabled, it also steps into it.
/// @param errorMsg       error message to output in failure case
/// @param extendedOutput [optional, defaults to true] Output additional information on failure
///
/// Example usage:
/// \rst
/// .. code-block:: igorpro
///
/// 	ControlInfo/W = $device popup_MoreSettings_DeviceType
/// 	ASSERT(V_flag > 0, "Non-existing control or window")
/// 	do something with S_value
/// \endrst
///
/// @hidecallgraph
/// @hidecallergraph
/// UTF_NOINSTRUMENTATION
Function ASSERT(variable var, string errorMsg, [variable extendedOutput])
	string stracktrace, miesVersionStr, lockedDevicesStr, device
	string stacktrace = ""
	variable i, numLockedDevices, doCallDebugger

	try
		AbortOnValue var==0, 1
	catch
		if(ParamIsDefault(extendedOutput))
			extendedOutput = 1
		else
			extendedOutput = !!extendedOutput
		endif

		doCallDebugger = 1

#ifdef AUTOMATED_TESTING
		doCallDebugger = 0
		extendedOutput = 0
#ifdef AUTOMATED_TESTING_DEBUGGING
		doCallDebugger = 1
		extendedOutput = 1
#endif // AUTOMATED_TESTING_DEBUGGING
#endif // AUTOMATED_TESTING

		// Recursion detection, if ASSERT appears multiple times in StackTrace
		if(IsFunctionCalledRecursively())

			// Happens e.g. when ASSERT is encounterd in cleanup functions
			print "Double Assertion Fail encountered !"

			if(doCallDebugger)
				ControlWindowToFront()
				Debugger
			endif

			Abort
		endif

		print "!!! Assertion FAILED !!!"
		printf "Message: \"%s\"\r", RemoveEnding(errorMsg, "\r")

		if(extendedOutput)
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

			if(!SVAR_Exists(lockedDevices) || IsEmpty(lockedDevices))
				lockedDevicesStr = NONE
			else
				lockedDevicesStr = lockedDevices

				numLockedDevices = ItemsInList(lockedDevicesStr)

				Redimension/N=(numLockedDevices) sweeps, daqStates, tpStates

				for(i = 0; i < numLockedDevices; i += 1)
					device = StringFromList(i, lockedDevicesStr)
					NVAR runMode = $GetDataAcqRunMode(device)
					NVAR testpulseMode = $GetTestpulseRunMode(device)

					sweeps[i]    = num2str(AFH_GetLastSweepAcquired(device))
					tpStates[i]  = TestPulseRunModeToString(testpulseMode)
					daqStates[i] = DAQRunModeToString(runMode)
				endfor
			endif

			print "Please provide the following information if you contact the MIES developers:"
			print "################################"
			print "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"

			stacktrace = GetStackTrace()
			print "Stacktrace:"
			print stacktrace

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

			LOG_AddEntry(PACKAGE_MIES, LOG_ACTION_ASSERT, stacktrace = 1, keys = {LOG_MESSAGE_KEY}, values = {errorMsg})

			ControlWindowToFront()
		endif

		if(doCallDebugger)
			Debugger
		endif

		Abort
	endtry
End

/// @brief Low overhead function to check assertions (threadsafe variant)
///
/// @param var            if zero an error message is printed into the history and procedure
///                       execution is aborted, nothing is done otherwise.
/// @param errorMsg       error message to output in failure case
/// @param extendedOutput [optional, defaults to true] Output additional information on failure
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
/// UTF_NOINSTRUMENTATION
threadsafe Function ASSERT_TS(variable var, string errorMsg, [variable extendedOutput])
	string stacktrace

	try
		AbortOnValue var==0, 1
	catch
		if(ParamIsDefault(extendedOutput))
			extendedOutput = 1
		else
			extendedOutput = !!extendedOutput
		endif

#ifdef AUTOMATED_TESTING
		extendedOutput = 0
#ifdef AUTOMATED_TESTING_DEBUGGING
		extendedOutput = 1
#endif // AUTOMATED_TESTING_DEBUGGING
#endif // AUTOMATED_TESTING

		// Recursion detection, if ASSERT_TS appears multiple times in StackTrace
		if(IsFunctionCalledRecursively())

			print "Double threadsafe assertion Fail encountered !"

			AbortOnValue 1, 1
		endif

		print "!!! Threadsafe assertion FAILED !!!"
		printf "Message: \"%s\"\r", RemoveEnding(errorMsg, "\r")

		if(extendedOutput)
			print "Please provide the following information if you contact the MIES developers:"
			print "################################"
			print "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
			stacktrace = GetStackTrace()
			print "Stacktrace:"
			print stacktrace

			print "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
			printf "Time: %s\r", GetIso8601TimeStamp(localTimeZone = 1)
			printf "Experiment: %s (%s)\r", GetExperimentName(), GetExperimentFileType()
			printf "Igor Pro version: %s (%s)\r", GetIgorProVersion(), StringByKey("BUILD", IgorInfo(0))
			print "################################"

			LOG_AddEntry(PACKAGE_MIES, LOG_ACTION_ASSERT, stacktrace = 1, keys = {LOG_MESSAGE_KEY}, values = {errorMsg})
		endif

		AbortOnValue 1, 1
	endtry
End

/// @brief Checks if the given name exists as window
///
/// @hidecallgraph
/// @hidecallergraph
/// UTF_NOINSTRUMENTATION
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
threadsafe Function/S GetListOfObjects(dfr, matchExpr, [typeFlag, fullPath, recursive, exprType])
	dfref dfr
	string matchExpr
	variable fullPath, recursive, typeFlag, exprType

	variable i, numFolders
	string name, folders, basePath, subList, freeDFName
	string list = ""

	ASSERT_TS(DataFolderExistsDFR(dfr),"Non-existing datafolder")
	ASSERT_TS(!isEmpty(matchExpr),"matchExpr is empty or null")

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
		ASSERT_TS(exprType == MATCH_REGEXP || exprType == MATCH_WILDCARD, "Invalid exprType")
	endif

	list = ListMatchesExpr(GetAllObjects(dfr, typeFlag), matchExpr, exprType)

	if(fullPath)
		basePath = GetDataFolder(1, dfr)
		if(IsFreeDataFolder(dfr))
			freeDFName = StringFromList(0, basePath, ":") + ":"
			basePath = ReplaceString(freeDFName, basePath, "", 0, 1)
		endif
		list = AddPrefixToEachListItem(basePath, list)
	endif

	if(recursive)
		folders = GetAllObjects(dfr, COUNTOBJECTS_DATAFOLDER)
		numFolders = ItemsInList(folders)
		for(i = 0; i < numFolders; i+=1)
			DFREF subFolder = dfr:$StringFromList(i, folders)
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
threadsafe static Function/S GetAllObjects(dfr, typeFlag)
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
			list = DataFolderList("*", ";")
			break
		default:
			SetDataFolder oldDFR
			ASSERT_TS(0, "Invalid type flag")
	endswitch

	SetDataFolder oldDFR

	return list
End

/// @brief Matches `list` against the expression `matchExpr` using the given
///        convention in `exprType`
threadsafe Function/S ListMatchesExpr(list, matchExpr, exprType)
	string list, matchExpr
	variable exprType

	switch(exprType)
		case MATCH_REGEXP:
			return GrepList(list, matchExpr)
		case MATCH_WILDCARD:
			return ListMatch(list, matchExpr)
		default:
			ASSERT_TS(0, "invalid exprType")
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
/// 		EnsureLargeEnoughWave(data, dimension = ROWS, indexShouldExist = index)
/// 		data[index] = ...
/// 		// ...
/// 	    SetNumberInWaveNote(data, NOTE_INDEX, ++index)
/// 	endfor
/// \endrst
///
/// @param wv               wave to redimension
/// @param indexShouldExist [optional, default is implementation defined] the minimum size of the wave.
///                         The actual size of the wave after the function returns might be larger.
/// @param dimension        [optional, defaults to ROWS] dimension to resize, all other dimensions are left untouched.
/// @param initialValue     [optional, defaults to zero] initialValue of the new wave points
/// @param checkFreeMemory  [optional, defaults to false] check if the free memory is enough for increasing the size
///
/// @return 0 on success, (only for checkFreeMemory = True) 1 if increasing the wave's size would fail due to out of memory
threadsafe Function EnsureLargeEnoughWave(WAVE wv, [variable indexShouldExist, variable dimension, variable initialValue, variable checkFreeMemory])

	if(ParamIsDefault(dimension))
		dimension = ROWS
	endif

	if(ParamIsDefault(checkFreeMemory))
		checkFreeMemory = 0
	else
		checkFreeMemory = !!checkFreeMemory
	endif

	ASSERT_TS(dimension == ROWS || dimension == COLS || dimension == LAYERS || dimension == CHUNKS, "Invalid dimension")
	ASSERT_TS(WaveExists(wv), "Wave does not exist")
	ASSERT_TS(IsFinite(indexShouldExist) && indexShouldExist >= 0, "Invalid minimum size")

	if(ParamIsDefault(indexShouldExist))
		indexShouldExist = MINIMUM_WAVE_SIZE - 1
	else
		indexShouldExist = max(MINIMUM_WAVE_SIZE - 1, indexShouldExist)
	endif

	if(indexShouldExist < DimSize(wv, dimension))
		return 0
	endif

	indexShouldExist *= 2

	if(checkFreeMemory)
		if(GetWaveSize(wv) * (indexShouldExist / DimSize(wv, dimension)) / 1024 / 1024 / 1024 >= GetFreeMemory())
			return 1
		endif
	endif

	Make/FREE/L/N=(MAX_DIMENSION_COUNT) targetSizes = -1
	targetSizes[dimension] = indexShouldExist

	Make/FREE/L/N=(MAX_DIMENSION_COUNT) oldSizes = DimSize(wv,p)

	Redimension/N=(targetSizes[ROWS], targetSizes[COLS], targetSizes[LAYERS], targetSizes[CHUNKS]) wv

	if(!ParamIsDefault(initialValue))
		ASSERT_TS(ValueCanBeWritten(wv, initialValue), "initialValue can not be stored in wv")
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
threadsafe Function ValueCanBeWritten(wv, value)
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

/// @brief Returns the size of the wave in bytes
threadsafe static Function GetWaveSizeImplementation(wv)
	Wave wv

	return NumberByKey("SizeInBytes", WaveInfo(wv, 0))
End

/// @brief Return the size in bytes of a given type
///
/// Inspired by http://www.igorexchange.com/node/1845
threadsafe Function GetSizeOfType(WAVE wv)
	variable type, size

	type = WaveType(wv)

	if(type == 0)
		// text waves, wave reference wave, dfref wave
		// we just return the size of a pointer on 64bit as
		// everything else would be too expensive to calculate
		return 8
	endif

	size = 1

	if(type & IGOR_TYPE_COMPLEX)
		size *= 2
	endif

	if(type & IGOR_TYPE_32BIT_FLOAT)
		size *= 4
	elseif(type & IGOR_TYPE_64BIT_FLOAT)
		size *= 8
	elseif(type & IGOR_TYPE_8BIT_INT)
		// do nothing
	elseif(type & IGOR_TYPE_16BIT_INT)
		size *= 2
	elseif(type & IGOR_TYPE_32BIT_INT)
		size *= 4
	elseif(type & IGOR_TYPE_64BIT_INT)
		size *= 8
	else
		ASSERT_TS(0, "Unexpected type")
	endif

	return size
End

/// @brief Returns the size of the wave in bytes.
threadsafe Function GetWaveSize(wv, [recursive])
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
		return GetWaveSizeImplementation(wv)
	endif

	WAVE/WAVE waveRefs = wv

	Make/FREE/L/U/N=(DimSize(wv, ROWS)) sizes = GetWaveSize(waveRefs[p], recursive = 1)

	return GetWaveSize(wv, recursive = 0) + Sum(sizes)
End

/// @brief Return the lock state of the passed wave
threadsafe Function GetLockState(WAVE wv)

	ASSERT_TS(WaveExists(wv), "Invalid wave")

	return NumberByKey("LOCK", WaveInfo(wv, 0))
End

/// @brief Convert the sampling interval in microseconds (1e-6s) to the rate in kHz
threadsafe Function ConvertSamplingIntervalToRate(val)
	variable val

	return 1 / (val * MICRO_TO_ONE) * ONE_TO_KILO
End

/// @brief Convert the rate in kHz to the sampling interval in microseconds (1e-6s)
threadsafe Function ConvertRateToSamplingInterval(val)
	variable val

	return 1 / (val * KILO_TO_ONE) * ONE_TO_MICRO
End

/// @brief Checks if the datafolder referenced by dfr exists.
///
/// @param[in] dfr data folder to test
/// @returns one if dfr is valid and references an existing or free datafolder, zero otherwise
/// UTF_NOINSTRUMENTATION
threadsafe Function DataFolderExistsDFR(DFREF dfr)

	return DataFolderRefStatus(dfr) != 0
End

/// @brief Check if the passed datafolder reference is a global/permanent datafolder
///
/// UTF_NOINSTRUMENTATION
threadsafe Function IsGlobalDataFolder(DFREF dfr)

	return (DataFolderRefStatus(dfr) & (DFREF_VALID | DFREF_FREE)) == DFREF_VALID
End

/// @brief Returns 1 if dfr is a valid free datafolder, 0 otherwise
///
/// UTF_NOINSTRUMENTATION
threadsafe Function IsFreeDatafolder(DFREF dfr)

	return (DataFolderRefStatus(dfr) & (DFREF_VALID | DFREF_FREE)) == (DFREF_VALID | DFREF_FREE)
End

/// @brief Create a datafolder and all its parents,
///
/// @hidecallgraph
/// @hidecallergraph
///
/// Includes fast handling of the common case that the datafolder exists.
/// @returns reference to the datafolder
/// UTF_NOINSTRUMENTATION
threadsafe Function/DF createDFWithAllParents(dataFolder)
	string dataFolder

	variable i, numItems
	string partialPath, component
	DFREF dfr = $dataFolder

	if(DataFolderRefStatus(dfr))
		return dfr
	endif

	partialPath = "root"

	// i=1 because we want to skip root, as this exists always
	numItems = ItemsInList(dataFolder,":")
	for(i=1; i < numItems ; i+=1)
		component = StringFromList(i,dataFolder,":")
		ASSERT_TS(IsValidObjectName(component), "dataFolder must follow strict object naming rules.")

		partialPath += ":" + component
		if(!DataFolderExists(partialPath))
			NewDataFolder $partialPath
		endif
	endfor

	return $dataFolder
end

/// @brief Returns one if var is an integer and zero otherwise
/// UTF_NOINSTRUMENTATION
threadsafe Function IsInteger(var)
	variable var

	return IsFinite(var) && trunc(var) == var
End

/// UTF_NOINSTRUMENTATION
threadsafe Function IsEven(variable var)

	return IsInteger(var) && mod(var, 2) == 0
End

/// UTF_NOINSTRUMENTATION
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
///                         @ref DECIMATION_BY_AVERAGING
///                         or @ref DECIMATION_BY_SMOOTHING.
/// @param winFunction 		Windowing function for @ref DECIMATION_BY_SMOOTHING mode,
///                    		must be one of @ref FFT_WINF.
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
	elseif(!ParamIsDefault(winFunction) && FindListItem(winFunction, FFT_WINF) == -1)
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

/// @brief Returns an unsorted free wave with all unique entries from wv
///        If dontDuplicate is set, then for a single element input wave no new free wave is created but the input wave is returned.
///
/// uses built-in igor function FindDuplicates. Entries are deleted from left to right.
///
/// @param wv             wave reference, can be numeric or text
/// @param caseSensitive  [optional, default = 1] Indicates whether comparison should be case sensitive. Applies only if the input wave is a text wave
/// @param dontDuplicate  [optional, default = 0] for a single element input wave no new free wave is created but the input wave is returned.
threadsafe Function/WAVE GetUniqueEntries(WAVE wv, [variable caseSensitive, variable dontDuplicate])

	variable numRows

	ASSERT_TS(WaveExists(wv), "Wave must exist")

	numRows = DimSize(wv, ROWS)
	ASSERT_TS(numRows == numpnts(wv), "Wave must be 1D")

	dontDuplicate = ParamIsDefault(dontDuplicate) ? 0 : !!dontDuplicate

	if(numRows <= 1)
		if(dontDuplicate)
			return wv
		endif

		Duplicate/FREE wv, result
		return result
	endif

	if(IsTextWave(wv))
		caseSensitive = ParamIsDefault(caseSensitive) ? 1 : !!caseSensitive

		return GetUniqueTextEntries(wv, caseSensitive=caseSensitive)
	endif

	FindDuplicates/FREE/RN=result wv

	return result
End

/// @brief Convenience wrapper around GetUniqueTextEntries() for string lists
threadsafe Function/S GetUniqueTextEntriesFromList(list, [sep, caseSensitive])
	string list, sep
	variable caseSensitive

	if(ParamIsDefault(sep))
		sep = ";"
	else
		ASSERT_TS(strlen(sep) == 1, "Separator should be one byte long")
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
/// @param caseSensitive  [optional, default = 1] Indicates whether comparison should be case sensitive.
/// @param dontDuplicate  [optional, default = 0] for a single element input wave no new free wave is created but the input wave is returned.
///
/// @return free wave with unique entries
threadsafe static Function/WAVE GetUniqueTextEntries(WAVE/T wv, [variable caseSensitive, variable dontDuplicate])

	variable numEntries, numDuplicates, i

	dontDuplicate = ParamIsDefault(dontDuplicate) ? 0 : !!dontDuplicate
	caseSensitive = ParamIsDefault(caseSensitive) ? 1 : !!caseSensitive

	numEntries = DimSize(wv, ROWS)
	ASSERT_TS(numEntries == numpnts(wv), "Wave must be 1D.")

	if(numEntries <= 1)
		if(dontDuplicate)
			return wv
		endif
		Duplicate/T/FREE wv result
		return result
	endif

	if(caseSensitive)
		FindDuplicates/FREE/RT=result wv
	else
		Duplicate/T/FREE wv result

		MAKE/T/FREE/N=(numEntries) duplicates = LowerStr(wv[p])
		FindDuplicates/FREE/INDX=index duplicates
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
/// @returns 1 in case the folder was removed and 0 in all other cases
Function RemoveEmptyDataFolder(dfr)
	dfref dfr

	if(!DataFolderExistsDFR(dfr))
		return 0
	endif

	if(IsDataFolderEmpty(dfr))
		KillDataFolder dfr
		return 1
	endif

	return 0
end

/// @brief Return 1 if the datafolder is empty, zero if not
Function IsDataFolderEmpty(DFREF dfr)

	ASSERT(DataFolderExistsDFR(dfr), "Missing dfr")

	return (CountObjectsDFR(dfr, COUNTOBJECTS_WAVES)        \
	        + CountObjectsDFR(dfr, COUNTOBJECTS_VAR)        \
	        + CountObjectsDFR(dfr, COUNTOBJECTS_STR)        \
	        + CountObjectsDFR(dfr, COUNTOBJECTS_DATAFOLDER) \
	       ) == 0
End

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
/// UTF_NOINSTRUMENTATION
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
/// @param keySep  [optional, defaults to #DEFAULT_KEY_SEP] separation character for (key, value) pairs
/// @param listSep [optional, defaults to #DEFAULT_LIST_SEP] list separation character
/// @param recursive [optional, defaults to false] checks all wave notes in referenced waves from wave reference waves
///
/// @returns the value on success. An empty string is returned if it could not be found
threadsafe Function/S GetStringFromWaveNote(WAVE wv, string key, [string keySep, string listSep, variable recursive])
	variable numEntries = numpnts(wv)
	string result

	if(ParamIsDefault(recursive))
		recursive = 0
	else
		recursive = !!recursive
	endif

	if(ParamIsDefault(keySep))
		keySep = DEFAULT_KEY_SEP
	endif

	if(ParamIsDefault(listSep))
		listSep = DEFAULT_LIST_SEP
	endif

	result = ExtractStringFromPair(note(wv), key, keySep = keySep, listSep = listSep)

	if(!recursive || !IsWaveRefWave(wv) || numEntries == 0)
		return result
	endif

	Make/FREE/T/N=(numEntries) notes = ExtractStringFromPair(note(WaveRef(wv, row = p)), key, keySep = keySep, listSep = listSep)

	WAVE/T/Z uniqueEntries = GetUniqueEntries(notes)
	ASSERT_TS(WaveExists(uniqueEntries), "Missing unique entries")

	if(DimSize(uniqueEntries, ROWS) == 1 && !cmpstr(uniqueEntries[0], result))
		return result
	endif

	return ""
End

/// @brief Same functionality as GetStringFromWaveNote() but accepts a string
///
/// @sa GetStringFromWaveNote()
threadsafe Function/S ExtractStringFromPair(string str, string key, [string keySep, string listSep])
	if(ParamIsDefault(keySep))
		keySep = DEFAULT_KEY_SEP
	endif

	if(ParamIsDefault(listSep))
		listSep = DEFAULT_LIST_SEP
	endif

	ASSERT_TS(!IsEmpty(key), "Empty key")

	// AddEntryIntoWaveNoteAsList creates whitespaces "key = value;"
	str = ReplaceString(" " + keySep + " ", str, keySep)

	return StringByKey(key, str, keySep, listSep)
End

/// @brief Update the string value of `key` found in the wave note to `str`
///
/// The expected wave note format is: `key1:val1;key2:str2;`
threadsafe Function SetStringInWaveNote(WAVE wv, string key, string str, [variable recursive])

	variable numEntries

	if(ParamIsDefault(recursive))
		recursive = 0
	else
		recursive = !!recursive
	endif

	ASSERT_TS(WaveExists(wv), "Missing wave")
	ASSERT_TS(!IsEmpty(key), "Empty key")

	Note/K wv, ReplaceStringByKey(key, note(wv), str)

	numEntries = numpnts(wv)
	if(!recursive || !IsWaveRefWave(wv) || numEntries == 0)
		return NaN
	endif

	Make/FREE/N=(numEntries) junk = SetStringInWaveNote(WaveRef(wv, row = p), key, str, recursive = 1)
End

/// @brief Remove the surrounding quotes from the string if they are present
Function/S PossiblyUnquoteName(string name, string quote)
	variable len

	if(isEmpty(name))
		return name
	endif

	len = strlen(name)

	ASSERT(strlen(quote) == 1, "Invalid quote string")

	if(!CmpStr(name[0], quote) && !CmpStr(name[len - 1], quote))
		ASSERT(len > 1, "name is too short")
		return name[1, len - 2]
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

		WAVE/WAVE candidates = ListToWaveRefWave(GetListOfObjects(dfr, ".*", fullpath=1))
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
/// @param dfr      datafolder to search
/// @param baseName first part of the datafolder, must be a *valid* Igor Pro object name
threadsafe Function/S UniqueDataFolderName(dfr, baseName)
	DFREF dfr
	string baseName

	variable index, numRuns
	string basePath, path

	ASSERT_TS(!isEmpty(baseName), "baseName must not be empty" )
	ASSERT_TS(DataFolderExistsDFR(dfr), "dfr does not exist")
	ASSERT_TS(!IsFreeDatafolder(dfr), "dfr can not be a free DF")

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
///               the begin of str
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
		AssertOnAndClearRTError()
		SplitString/E=("^(" + start + ")") str, regExpResult; err = GetRTError(1) // see developer docu section Preventing Debugger Popup

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

	return IgorInfo(11)

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

		NewPath/O/C/Q/Z $tempPath, partialPath
	endfor

	KillPath/Z $tempPath

	ASSERT(FolderExists(partialPath), "Could not create the path, maybe the permissions were insufficient")
End

/// @brief Return the row index of the given value, string converted to a variable, or wv
///
/// Assumes wv being one dimensional
threadsafe Function GetRowIndex(wv, [val, str, refWave])
	WAVE wv
	variable val
	string str
	WAVE/Z refWave

	variable numEntries, i

	ASSERT_TS(ParamIsDefault(val) + ParamIsDefault(str) + ParamIsDefault(refWave) == 2, "Expected exactly one argument")

	if(!ParamIsDefault(refWave))
		ASSERT_TS(IsWaveRefWave(wv), "wv must be a wave holding wave references")
		numEntries = DimSize(wv, ROWS)
		WAVE/WAVE cmpWave = wv

		for(i = 0; i < numEntries; i += 1)
			if(WaveRefsEqual(cmpWave[i], refWave)                   \
			   || (!WaveExists(cmpWave[i]) && !WaveExists(refWave)))
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

/// @brief Return the base name of the file
///
/// Given `path/file.suffix` this gives `file`.
///
/// @param filePathWithSuffix full path
/// @param sep                [optional, defaults to ":"] character
///                           separating the path components
threadsafe Function/S GetBaseName(filePathWithSuffix, [sep])
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
threadsafe Function/S GetFileSuffix(filePathWithSuffix, [sep])
	string filePathWithSuffix, sep

	if(ParamIsDefault(sep))
		sep = ":"
	endif

	return ParseFilePath(4, filePathWithSuffix, sep, 0, 0)
End

/// @brief Return the folder of the file
///
/// Given `path/file.suffix` this gives `path`.
/// The returned result has a trailing separator.
///
/// @param filePathWithSuffix full path
/// @param sep                [optional, defaults to ":"] character
///                           separating the path components
threadsafe Function/S GetFolder(filePathWithSuffix, [sep])
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
threadsafe Function/S GetFile(filePathWithSuffix, [sep])
	string filePathWithSuffix, sep

	if(ParamIsDefault(sep))
		sep = ":"
	endif

	return ParseFilePath(0, filePathWithSuffix, sep, 1, 0)
End

/// @brief Return the path converted to a windows style path
threadsafe Function/S GetWindowsPath(path)
	string path

	return ParseFilepath(5, path, "\\", 0, 0)
End

/// @brief Return the path converted to a HFS style (aka ":" separated) path
threadsafe Function/S GetHFSPath(string path)
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
threadsafe Function GetFreeMemory()
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
threadsafe Function/S RemoveEndingRegExp(str, endingRegExp)
	string str, endingRegExp

	string endStr
	variable err

	if(isEmpty(str) || isEmpty(endingRegExp))
		return str
	endif

	SplitString/E=("(" + endingRegExp + ")$") str, endStr; err = GetRTError(1)
	ASSERT_TS((V_flag == 0 || V_flag == 1) && err == 0, "Unexpected number of matches or invalid regex")

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
/// 		ASSERT(!IsEmpty(substring), "supplied substring is empty")
/// 		WAVE/Z/T wv = SearchStringBase(str, "(.*)\\Q" + substring + "\\E(.*)")
///
/// 		return WaveExists(wv)
/// 	End
/// \endrst
///
/// @return 1 if word was found in str and word was not "". 0 if not.
Function SearchWordInString(string str, string word, [string &prefix, string &suffix])

	string prefixParam, suffixParam
	variable ret

	[ret, prefixParam, suffixParam] = SearchRegexInString(str, "\\b\\Q" + word + "\\E\\b")

	if(!ret)
		return ret
	endif

	if(!ParamIsDefault(prefix))
		prefix = prefixParam
	endif

	if(!ParamIsDefault(suffix))
		suffix = suffixParam
	endif

	return ret
End

static Function [variable ret, string prefix, string suffix] SearchRegexInString(string str, string regex)

	ASSERT(IsValidRegexp(regex), "Empty regex")

	WAVE/Z/T wv = SearchStringBase(str, "(.*)" + regex + "(.*)")

	if(!WaveExists(wv))
		return [0, "", ""]
	endif

	return [1, wv[0], wv[1]]
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
/// @param noiseGenMode [optional, defaults to #NOISE_GEN_XOSHIRO] type of RNG to use
Function InPlaceRandomShuffle(inwave, [noiseGenMode])
	wave inwave
	variable noiseGenMode

	variable i, j, emax, temp
	variable N = DimSize(inwave, ROWS)

	if(ParamIsDefault(noiseGenMode))
		noiseGenMode = NOISE_GEN_XOSHIRO
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

	SetRandomSeed/BETR=1 ((stopmstimer(-2) * 10 ) & 0xffffffff) / 2^32 // NOLINT

End

/// @brief Return a random value in the range (0,1] which can be used as a seed for `SetRandomSeed`
///
/// Return a reproducible random number depending on the RNG seed.
threadsafe Function GetReproducibleRandom([variable noiseGenMode])
	variable randomSeed

	if(ParamIsDefault(noiseGenMode))
		noiseGenMode = NOISE_GEN_XOSHIRO
	endif

	do
		randomSeed = abs(enoise(1, noiseGenMode))
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
threadsafe Function/S AddPrefixToEachListItem(string prefix, string list, [string sep])
	string result = ""
	variable numEntries, i

	if(ParamIsDefault(sep))
		sep = ";"
	endif

	numEntries = ItemsInList(list, sep)
	for(i = 0; i < numEntries; i += 1)
		result = AddListItem(prefix + StringFromList(i, list, sep), result, sep, inf)
	endfor

	return result
End

/// @brief Add a string suffix to each list item and
/// return the new list
threadsafe Function/S AddSuffixToEachListItem(string suffix, string list, [string sep])
	string result = ""
	variable numEntries, i

	if(ParamIsDefault(sep))
		sep = ";"
	endif

	numEntries = ItemsInList(list, sep)
	for(i = 0; i < numEntries; i += 1)
		result = AddListItem(StringFromList(i, list, sep) + suffix, result, sep, inf)
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
///
/// UTF_NOINSTRUMENTATION
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
threadsafe Function ParseUnit(unitWithPrefix, prefix, numPrefix, unit)
	string unitWithPrefix
	string &prefix
	variable &numPrefix
	string &unit

	string expr, unitInt, prefixInt

	prefix    = ""
	numPrefix = NaN
	unit      = ""

	ASSERT_TS(!isEmpty(unitWithPrefix), "empty unit")

	expr = "^(Y|Z|E|P|T|G|M|k|h|d|c|m|mu|n|p|f|a|z|y)?[[:space:]]*(m|kg|s|A|K|mol|cd|Hz|V|N|W|J|F|Ω|a.u.)$"

	SplitString/E=(expr) unitWithPrefix, prefixInt, unitInt
	ASSERT_TS(V_flag >= 1, "Could not parse unit string")
	ASSERT_TS(!IsEmpty(unitInt), "Could not find a unit")

	prefix = prefixInt
	numPrefix = GetDecimalMultiplierValue(prefix)
	unit = unitInt
End

/// @brief Return the numerical value of a SI decimal multiplier
///
/// @see ParseUnit
threadsafe Function GetDecimalMultiplierValue(prefix)
	string prefix

	if(isEmpty(prefix))
		return 1
	endif

	WAVE/T prefixes = ListToTextWave(PREFIX_SHORT_LIST, ";")
	WAVE/D values   = ListToNumericWave(PREFIX_VALUE_LIST, ";")

	FindValue/Z/TXOP=(1 + 4)/TEXT=(prefix) prefixes
	ASSERT_TS(V_Value != -1, "Could not find prefix")

	ASSERT_TS(DimSize(prefixes, ROWS) == DimSize(values, ROWS), "prefixes and values wave sizes must match")
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

/// @brief Force recompilation of all procedure files
///
/// Uses the "Operation Queue".
Function ForceRecompile()
	Execute/P/Q/Z "Silent 100"
End

/// @brief Parse a ISO8601 timestamp, e.g. created by GetISO8601TimeStamp(), and returns the number
/// of seconds, including fractional parts, since Igor Pro epoch (1/1/1904) in UTC time zone
///
/// Accepts also the following specialities:
/// - no UTC timezone specifier (UTC timezone is still used)
/// - ` `/`T` between date and time
/// - fractional seconds
/// - `,`/`.` as decimal separator
threadsafe Function ParseISO8601TimeStamp(timestamp)
	string timestamp

	string year, month, day, hour, minute, second, regexp, fracSeconds, tzOffsetSign, tzOffsetHour, tzOffsetMinute
	variable secondsSinceEpoch, timeOffset, err

	if(IsEmpty(timestamp))
		return NaN
	endif

	[err, year, month, day, hour, minute, second, fracSeconds, tzOffsetSign, tzOffsetHour, tzOffsetMinute] = ParseISO8601TimeStampToComponents(timestamp)
	if(err)
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
			ASSERT_TS(0, "Invalid case")
		endif
	endif

	if(!IsEmpty(fracSeconds))
		secondsSinceEpoch += str2num(ReplaceString(",", fracSeconds, "."))
	endif

	return secondsSinceEpoch
End

/// @brief Parses a ISO8601 timestamp to its components, year, month, day, hour, minute are required and the remaining components are optional and can be returned as empty strings.
///
threadsafe Function [variable err, string year, string month, string day, string hour, string minute, string second, string fracSeconds, string tzOffsetSign, string tzOffsetHour, string tzOffsetMinute] ParseISO8601TimeStampToComponents(string timestamp)

	string regexp

	regexp = "^([[:digit:]]+)-([[:digit:]]+)-([[:digit:]]+)[T ]{1}([[:digit:]]+):([[:digit:]]+)(?::([[:digit:]]+)([.,][[:digit:]]+)?)?(?:Z|([\+-])([[:digit:]]{2})(?::?([[:digit:]]{2}))?)?$"
	SplitString/E=regexp timestamp, year, month, day, hour, minute, second, fracSeconds, tzOffsetSign, tzOffsetHour, tzOffsetMinute

	if(V_flag < 5)
		return [1, year, month, day, hour, minute, second, fracSeconds, tzOffsetSign, tzOffsetHour, tzOffsetMinute]
	endif

	return [0, year, month, day, hour, minute, second, fracSeconds, tzOffsetSign, tzOffsetHour, tzOffsetMinute]
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
	return prefix + num2istr(GetUniqueInteger())
End

/// @brief Return a list of all files from the given symbolic path
///        and its subfolders. The list is pipe (`FILE_LIST_SEP`) separated as
///        the semicolon (`;`) is a valid character in filenames.
///
/// Note: This function does *not* work on MacOSX as there filenames are allowed
///       to have pipe symbols in them.
///
/// @param pathName igor symbolic path to search recursively
/// @param extension [optional, defaults to all files] file suffixes to search for
Function/S GetAllFilesRecursivelyFromPath(pathName, [extension])
	string pathName, extension

	string fileOrPath, folders, subFolderPathName, fileName
	string files, allFilesList
	string allFiles = ""
	string foldersFromAlias = ""
	variable err

	PathInfo $pathName
	ASSERT(V_flag, "Given symbolic path does not exist")

	if(ParamIsDefault(extension))
		extension = "????"
	endif

	AssertOnAndClearRTError()
	allFilesList = IndexedFile($pathName, -1, extension, "????", FILE_LIST_SEP); err = GetRTError(1)
	WAVE/T allFilesInDir = ListToTextWave(allFilesList, FILE_LIST_SEP)
	for(fileName : allFilesInDir)

		fileOrPath = ResolveAlias(fileName, pathName = pathName)

		if(isEmpty(fileOrPath))
			// invalid shortcut, try next file
			continue
		endif

		GetFileFolderInfo/P=$pathName/Q/Z fileOrPath
		ASSERT(!V_Flag, "Error in GetFileFolderInfo")

		if(V_isFile)
			allFiles = AddListItem(S_path, allFiles, FILE_LIST_SEP, Inf)
		elseif(V_isFolder)
			foldersFromAlias = AddListItem(S_path, foldersFromAlias, FILE_LIST_SEP, Inf)
		else
			ASSERT(0, "Unexpected file type")
		endif
	endfor

	AssertOnAndClearRTError()
	folders = IndexedDir($pathName, -1, 1, FILE_LIST_SEP); err = GetRTError(1)
	folders = folders + foldersFromAlias
	WAVE/T wFolders = ListToTextWave(folders, FILE_LIST_SEP)
	for(folder : wFolders)

		subFolderPathName = GetUniqueSymbolicPath()

		NewPath/Q/O $subFolderPathName, folder
		files = GetAllFilesRecursivelyFromPath(subFolderPathName, extension=extension)
		KillPath/Z $subFolderPathName

		if(!isEmpty(files))
			allFiles = AddListItem(RemoveEnding(files, FILE_LIST_SEP), allFiles, FILE_LIST_SEP, Inf)
		endif
	endfor

	return allFiles
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
///
/// @return string with wave entries separated as list using given separators
///
/// Counterpart @see ConvertListToTextWave
/// @see NumericWaveToList
threadsafe Function/S TextWaveToList(WAVE/T/Z txtWave, string rowSep, [string colSep, string layerSep, string chunkSep, variable stopOnEmpty, variable maxElements])
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
		maxElements = inf
	else
		ASSERT_TS((IsInteger(maxElements) && maxElements >= 0) || maxElements == inf, "maxElements must be >=0 and an integer")
	endif

	stopOnEmpty = ParamIsDefault(stopOnEmpty) ? 0 : !!stopOnEmpty

	numRows = DimSize(txtWave, ROWS)
	if(numRows == 0)
		return list
	endif
	numCols = DimSize(txtWave, COLS)
	numLayers = DimSize(txtWave, LAYERS)
	numChunks = DimSize(txtWave, CHUNKS)

	if(!stopOnEmpty && maxElements == inf && !numLayers && !numChunks)
		return WaveToListFast(txtWave, "%s", rowSep, colSep)
	endif

	numColsLoop = max(1, numCols)
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

					list += seps + entry
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
threadsafe Function/WAVE ListToTextWaveMD(list, dims, [rowSep, colSep, laySep, chuSep])
	string list
	variable dims
	string rowSep, colSep, laySep, chuSep

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
/// @param wv     numeric wave
/// @param sep    separator
/// @param colSep [optional, default = `,`] separator for column entries
/// @param format [optional, defaults to `%g`] sprintf conversion specifier
threadsafe Function/S NumericWaveToList(WAVE/Z wv, string sep, [string format, string colSep])

	if(!WaveExists(wv))
		return ""
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

	return WaveToListFast(wv, format, sep, colSep)
End

threadsafe static Function/S WaveToListFast(WAVE wv, string format, string sep, string colSep)

	string list

	if(DimSize(wv, COLS) > 0)
		format = ReplicateString(format + colSep, DimSize(wv, COLS)) + sep
	else
		format += sep
	endif

	wfprintf list, format, wv

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
threadsafe Function/WAVE ListToNumericWave(list, sep, [type])
	string list, sep
	variable type

	if(ParamIsDefault(type))
		type = IGOR_TYPE_64BIT_FLOAT
	endif

	Make/FREE/Y=(type)/N=(ItemsInList(list, sep)) wv
	MultiThread wv = str2num(StringFromList(p, list, sep))

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

/// @brief Find an integer `x` which is larger than `a` but the
/// smallest possible power of `p`.
///
/// @f$ x > a @f$ where @f$ x = c^p @f$ holds and @f$ x @f$ is
/// the smallest possible value.
threadsafe Function FindNextPower(a, p)
	variable a, p

	ASSERT_TS(p > 1, "Invalid power")
	ASSERT_TS(a > 0, "Invalid value")
	ASSERT_TS(IsInteger(a), "Value has to be an integer")

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
/// @param index     [optional] specifies the index into `dimension`, index is not checked
/// @param indexWave [optional] specifies the indizes into `dimension`, allows for
///                  differing indizes per `src` entry, indices are not checked
threadsafe Function/WAVE DeepCopyWaveRefWave(WAVE/WAVE src, [variable dimension, variable index, WAVE indexWave])

	variable i, numEntries

	ASSERT_TS(IsWaveRefWave(src), "Expected wave ref wave")
	ASSERT_TS(DimSize(src, COLS) <= 1, "Expected a 1D wave for src")

	if(!ParamIsDefault(dimension))
		ASSERT_TS(dimension >= ROWS && dimension <= CHUNKS, "Invalid dimension")
		ASSERT_TS(ParamIsDefault(index) + ParamIsDefault(indexWave) == 1, "Need exactly one of parameter of type index or indexWave")
	endif

	if(!ParamIsDefault(indexWave) || !ParamIsDefault(index))
		ASSERT_TS(!ParamIsDefault(dimension), "Missing optional parameter dimension")
	endif

	Duplicate/WAVE/FREE src, dst

	numEntries = DimSize(src, ROWS)

	if(!ParamIsDefault(indexWave))
		ASSERT_TS(IsNumericWave(indexWave), "Expected numeric wave")
		ASSERT_TS(numEntries == numpnts(indexWave), "indexWave and src must have the same number of points")
	endif

	for(i = 0; i < numEntries; i += 1)
		WAVE/Z srcWave = dst[i]
		ASSERT_TS(WaveExists(srcWave), "Missing wave at linear index" + num2str(i))

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
			ReduceWaveDimensionality(dstWave, minDimension=dimension)
		endif

		dst[i] = dstWave
	endfor

	return dst
End

/// @brief Shrinks a waves dimensionality if higher dimensions have size 1
///
/// @param wv           Wave that should be shrinked
/// @param minDimension [optional, default COLS] shrinks a wave only up to this dimension, e.g. with minDimension = LAYERS
///                     a wave of size (1,1,1,1) is shrinked to (1,1,1,0).
threadsafe Function ReduceWaveDimensionality(WAVE/Z wv, [variable minDimension])

	variable i, shrink

	if(!WaveExists(wv))
		return NaN
	endif

	if(!numpnts(wv))
		return NaN
	endif

	minDimension = ParamIsDefault(minDimension) ? COLS : minDimension
	ASSERT_TS(IsInteger(minDimension) && minDimension >= ROWS && minDimension < MAX_DIMENSION_COUNT, "Invalid minDimension")
	minDimension = limit(minDimension, COLS, MAX_DIMENSION_COUNT - 1)
	Make/FREE/N=(MAX_DIMENSION_COUNT) waveSize
	waveSize[] = DimSize(wv, p)
	for(i = MAX_DIMENSION_COUNT - 1; i >= minDimension; i -= 1)
		if(waveSize[i] == 1)
			waveSize[i] = 0
			shrink = 1
		elseif(waveSize[i] > 1)
			break
		endif
	endfor
	if(shrink)
		Redimension/N=(waveSize[0], waveSize[1], waveSize[2], waveSize[3]) wv
	endif
End

/// @brief Return 1 if the wave is a text wave, zero otherwise
/// UTF_NOINSTRUMENTATION
threadsafe Function IsTextWave(wv)
	WAVE wv

	return WaveType(wv, 1) == 2
End

/// @brief Return 1 if the wave is a numeric wave, zero otherwise
/// UTF_NOINSTRUMENTATION
threadsafe Function IsNumericWave(wv)
	WAVE wv

	return WaveType(wv, 1) == 1
End

/// @brief Return 1 if the wave is a wave reference wave, zero otherwise
/// UTF_NOINSTRUMENTATION
threadsafe Function IsWaveRefWave(wv)
	WAVE wv

	return WaveType(wv, 1) == IGOR_TYPE_WAVEREF_WAVE
End

/// @brief Return 1 if the wave is a floating point wave
/// UTF_NOINSTRUMENTATION
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

/// @brief Return a wave of the union of all entries from both waves with duplicates removed.
///
/// Given {1, 2, 10} and {2, 5, 11} this will return {1, 2, 5, 10, 11}.
/// The order of the returned entries is not defined.
threadsafe Function/WAVE GetSetUnion(WAVE wave1, WAVE wave2)
	variable type, wave1Points, wave2Points, totalPoints

	ASSERT_TS((IsNumericWave(wave1) && IsNumericWave(wave2))                   \
	          || (IsTextWave(wave1) && IsTextWave(wave2)), "Invalid wave type")

	type = WaveType(wave1)
	ASSERT_TS(type == WaveType(wave2), "Wave type mismatch")

	wave1Points = numpnts(wave1)
	wave2Points = numpnts(wave2)

	totalPoints = wave1Points + wave2Points

	if(totalPoints == 0)
		return $""
	endif

	if(WaveRefsEqual(wave1, wave2))
		Duplicate/FREE wave1, result
		return GetUniqueEntries(result)
	endif

	if(IsNumericWave(wave1))
		Concatenate/NP/FREE {wave1, wave2}, result
	else
		WAVE/T wave1Text = wave1
		WAVE/T wave2Text = wave2

		Make/T/N=(totalPoints)/FREE resultText

		if(wave1Points > 0)
			Multithread/NT=(totalPoints < 1024) resultText[0, wave1Points - 1] = wave1Text[p]
		endif

		if(wave2Points > 0)
			Multithread/NT=(totalPoints < 1024) resultText[wave1Points, inf] = wave2Text[p - wave1Points]
		endif

		WAVE result = resultText
	endif

	return GetUniqueEntries(result)
End

/// @brief Return a wave were all elements which are in both wave1 and wave2 have been removed from wave1
///
/// @sa GetListDifference for string lists
threadsafe Function/WAVE GetSetDifference(wave1, wave2)
	WAVE wave1
	WAVE wave2

	variable isText, index

	isText = (IsTextWave(wave1) && IsTextWave(wave2))

	ASSERT_TS((IsFloatingPointWave(wave1) && IsFloatingPointWave(wave2)) || isText, "Non matching wave types (both float or both text).")
	ASSERT_TS(WaveType(wave1) == WaveType(wave2), "Wave type mismatch")

	WAVE/Z result

	if(isText)
		[result, index] = GetSetDifferenceText(wave1, wave2)
	else
		[result, index] = GetSetDifferenceNumeric(wave1, wave2)
	endif

	if(index == 0)
		return $""
	endif

	Redimension/N=(index) result

	return result
End

threadsafe static Function [WAVE result, variable index] GetSetDifferenceNumeric(WAVE wave1, WAVE wave2)
	variable numEntries, i, j, value

	Duplicate/FREE wave1, result

	numEntries = DimSize(wave1, ROWS)
	for(i = 0; i < numEntries; i += 1)
		value = wave1[i]

		FindValue/UOFV/V=(value) wave2
		if(V_Value == -1)
			result[j++] = value
		endif
	endfor

	return [result, j]
End

threadsafe static Function [WAVE result, variable index] GetSetDifferenceText(WAVE/T wave1, WAVE/T wave2)
	variable numEntries, i, j
	string str

	Duplicate/FREE/T wave1, resultTxT

	numEntries = DimSize(wave1, ROWS)
	for(i = 0; i < numEntries; i += 1)
		str = wave1[i]

		FindValue/UOFV/TEXT=(str)/TXOP=4 wave2
		if(V_Value == -1)
			resultTxT[j++] = str
		endif
	endfor

	WAVE result = resultTxT

	return [result, j]
End

/// @brief Return a wave with the set theory style intersection of wave1 and wave2
///
/// Given {1, 2, 4, 10} and {2, 5, 11} this will return {2}.
///
/// Inspired by http://www.igorexchange.com/node/366 but adapted to modern Igor Pro
/// It does work with text waves as well, there it performs case sensitive comparions
///
/// @return free wave with the set intersection or an invalid wave reference
/// if the intersection is an empty set
threadsafe Function/WAVE GetSetIntersection(wave1, wave2)
	WAVE wave1
	WAVE wave2

	variable type, wave1Rows, wave2Rows
	variable longRows, shortRows, entry
	variable i, j, longWaveRow
	string strEntry

	ASSERT_TS((IsNumericWave(wave1) && IsNumericWave(wave2))                   \
	       || (IsTextWave(wave1) && IsTextWave(wave2)), "Invalid wave type")

	type = WaveType(wave1)
	ASSERT_TS(type == WaveType(wave2), "Wave type mismatch")

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
	Sort/C longWave, longWave
	Make/FREE/N=(shortRows)/Y=(type) resultWave

	if(type == 0)
		WAVE/T shortWaveText = shortWave
		WAVE/T longWaveText  = longWave
		WAVE/T resultWaveText = resultWave
		for(i = 0; i < shortRows; i += 1)
			strEntry = shortWaveText[i]
			longWaveRow = BinarySearchText(longWave, strEntry, caseSensitive = 1)
			if(longWaveRow >= 0 && !cmpstr(longWaveText[longWaveRow], strEntry))
				resultWaveText[j++] = strEntry
			endif
		endfor
	else
		for(i = 0; i < shortRows; i += 1)
			entry = shortWave[i]
			longWaveRow = BinarySearch(longWave, entry)
			if(longWaveRow >= 0 && longWave[longWaveRow] == entry)
				resultWave[j++] = entry
			endif
		endfor
	endif

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
///
/// UTF_NOINSTRUMENTATION
threadsafe Function str2numSafe(string str)

	variable var, err

	AssertOnAndClearRTError()
	var = str2num(str); err = GetRTError(1) // see developer docu section Preventing Debugger Popup

	return var
End

/// @brief Open a folder selection dialog
///
/// @return a string denoting the selected folder, or an empty string if
/// nothing was supplied.
Function/S AskUserForExistingFolder(string baseFolder)

	string symbPath, selectedFolder

	symbPath = GetUniqueSymbolicPath()

	NewPath/O/Q/Z $symbPath, baseFolder
	// preset next undirected NewPath/Open call using the contents of a
	// *symbolic* folder
	PathInfo/S $symbPath

	// let the user choose a folder, starts in $baseFolder if supplied
	NewPath/O/Q/Z $symbPath
	if(V_flag == -1)
		return ""
	endif
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

Function/S ReplaceWordInString(string word, string str, string replacement)

	ASSERT(!IsEmpty(word), "Empty word")

	if(!cmpstr(word, replacement, 0))
		return str
	endif

	return ReplaceRegexInString("\\b\\Q" + word + "\\E\\b", str, replacement)
End

/// @brief Replaces all occurences of the regular expression `regex` in `str` with `replacement`
Function/S ReplaceRegexInString(string regex, string str, string replacement)

	variable ret
	string result, prefix, suffix

	result = str

	for(;;)
		[ret, prefix, suffix] = SearchRegexInString(result, regex)

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

/// @brief Wrapper function for `Abort` which honours our interactive mode setting
Function DoAbortNow(msg)
	string msg

	DEBUGPRINTSTACKINFO()

	if(IsEmpty(msg))
		Abort
	endif

	NVAR/Z interactiveMode = $GetInteractiveMode()

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
threadsafe Function/S NormalizeToEOL(str, eol)
	string str, eol

	str = ReplaceString("\r\n", str, eol)

	if(!cmpstr(eol, "\r"))
		str = ReplaceString("\n", str, eol)
	elseif(!cmpstr(eol, "\n"))
		str = ReplaceString("\r", str, eol)
	else
		ASSERT_TS(0, "unsupported EOL character")
	endif

	return str
End

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
		return "Not available"
	endif

	if(IsEmpty(prefix))
		output = prefix
	else
		output = prefix + "\r"
	endif

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
	return stopmstimer(-2) * MICRO_TO_ONE
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
///
/// UTF_NOINSTRUMENTATION
threadsafe Function IsFreeWave(wv)
	Wave wv

	return WaveType(wv, 2) == 2
End

/// @brief Return the modification count of the (permanent) wave
///
/// Returns NaN when running in a preemptive thread
///
/// UTF_NOINSTRUMENTATION
threadsafe Function WaveModCountWrapper(WAVE wv)

	if(MU_RunningInMainThread())
		ASSERT_TS(!IsFreeWave(wv), "Can not work with free waves")

		return WaveModCount(wv)
	else
		ASSERT_TS(IsFreeWave(wv), "Can only work with free waves")

		return NaN
	endif
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

// @brief Convert a number to the strings `On` (!= 0) or `Off` (0).
Function/S ToOnOff(var)
	variable var

	return SelectString(var, "Off", "On")
End

/// @brief Return true if not all wave entries are NaN, false otherwise.
///
/// UTF_NOINSTRUMENTATION
threadsafe Function HasOneValidEntry(WAVE wv)

	string str
	variable val

	ASSERT_TS(numpnts(wv) > 0, "Expected non-empty wave")

	if(IsFloatingPointWave(wv))
		return numType(WaveMin(wv)) != 2
	elseif(IsTextWave(wv))
		WAVE/T wvText = wv

		for(str : wvText)
			if(strlen(str) > 0)
				return 1
			endif
		endfor
	else
		ASSERT_TS(0, "Unsupported wave type")
	endif

	return 0
End

/// @brief Merge two floating point waves labnotebook waves
///
/// The result will hold the finite row entry of either `wv1` or `wv2`.
Function/WAVE MergeTwoWaves(wv1, wv2)
	WAVE wv1, wv2

	variable numEntries, i, validEntryOne, validEntryTwo

	ASSERT(EqualWaves(wv1, wv2, EQWAVES_DIMSIZE), "Non matching wave dim sizes")
	ASSERT(EqualWaves(wv1, wv2, EQWAVES_DATATYPE), "Non matching wave types")
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

/// @brief Helper function to ensure that there is no pending RTE before entering a critical section.
///        If there is a pending RTE then a BUG message is output (which is a CI error).
///
///        Not catching any pending RTE would clear this condition silently and valid errors would be
///        suppressed. This is dangerous in regards of data consistency.
///
///        Not clearing the RTE before calling `AbortOnRTE` will always trigger the
///        RTE no matter what you do in that line. Any call to GetRTErrMessage() must
///        be done prior to clearing the runtime error in the catch block.
///
/// Usage:
/// \rst
/// .. code-block:: igorpro
///
/// 	AssertOnAndClearRTError()
///    try
///      CriticalFunc(); AbortOnRTE
///    catch
///      msg = GetRTErrMessage()
///      err = ClearRTError()
///    endtry
///
/// \endrst
///
/// UTF_NOINSTRUMENTATION
threadsafe Function AssertOnAndClearRTError()

	string msg
	variable err

	msg = GetRTErrMessage()
	err = ClearRTError()

	if(err)
		BUG_TS("Encountered pending RTE: " + num2istr(err) + ", " + msg)
	endif
End

/// @brief Helper function to unconditionally clear a RTE condition
///	        It is generally strongly recommended to use @sa AssertOnAndClearRTError
///        before critical code sections. For detailed description of the implications @sa AssertOnAndClearRTError
///
/// UTF_NOINSTRUMENTATION
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
threadsafe Function ChangeWaveLock(wv, val)
	WAVE/WAVE wv
	variable val

	variable numEntries, i

	val = !!val

	SetWaveLock val, wv

	if(!IsWaveRefWave(wv))
		return NaN
	endif

	ASSERT_TS(DimSize(wv, ROWS) == numpnts(wv), "Expected a 1D wave")
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

/// @brief Round the given number to the given number of decimal digits
threadsafe Function RoundNumber(variable val, variable precision)

	return str2num(num2strHighPrec(val, precision = precision))
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

	ExecuteScriptText/B/Z cmd

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

	path = GetFolder(FunctionPath("")) + ":ITCXOP2:tools:Disable-ASLR-for-IP7-and-8.ps1"
	ASSERT(FileExists(path), "Could not locate powershell script")
	sprintf cmd, "powershell.exe -ExecutionPolicy Bypass \"%s\"", GetWindowsPath(path)
	ExecuteScriptText/B/Z cmd
	ASSERT(!V_flag, "Error executing ASLR script")

	printf "Please restart Igor Pro as normal user and execute \"Mies Panels\"->\"Check installation\" to see if ASLR is now turned off or not.\r See also https://github.com/AllenInstitute/ITCXOP2#windows-10 for further manual instructions.\r"
End

/// @brief Check if we are running on Windows 10
Function IsWindows10()
	string info, os

	info = IgorInfo(3)
	os = StringByKey("OS", info)
	return GrepString(os, "^(Microsoft )?Windows 10 ")
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

	return (stopmstimer(-2) - referenceTime) * MICRO_TO_ONE
End

/// @brief Store the elapsed time in a wave
Function StoreElapsedTime(referenceTime)
	variable referenceTime

	variable count, elapsed

	WAVE/D elapsedTime = GetElapsedTimeWave()

	count = GetNumberFromWaveNote(elapsedTime, NOTE_INDEX)
	EnsureLargeEnoughWave(elapsedTime, indexShouldExist=count, initialValue = NaN)

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

	GetWindow $win, psizeDC

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
	variable numCols, numColsFixed, numRows, numLayers, xDelta, maxLevels, numLevels
	variable first, last, i, xLevel, found, columnOffset

	numCols = DimSize(data, COLS)
	numRows = DimSize(data, ROWS)
	numLayers = DimSize(data, LAYERS)
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

	ASSERT_TS(numLayers <= 1, "Unexpected input dimension")

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
	Redimension/N=(numRows, numCols, numLayers)/E=1 data

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
/// @param[out] savedFileName [optional, default = ""] file name of the saved file
/// @param[in] showDialogOnOverwrite [optional, default = 0] opens save file dialog, if the current fileName would cause an overwrite, to allow user to change fileName
/// @returns NaN if file open dialog was aborted or an error was encountered, 0 otherwise
Function SaveTextFile(data, fileName,[ fileFilter, message, savedFileName, showDialogOnOverwrite])
	string data, fileName, fileFilter, message, &savedFileName
	variable showDialogOnOverwrite

	variable fNum, dialogCode

	if(!ParamIsDefault(savedFileName))
		savedFileName = ""
	endif

#ifdef AUTOMATED_TESTING
	string S_fileName = fileName
#else
	showDialogOnOverwrite = ParamIsDefault(showDialogOnOverwrite) ? 0: !!showDialogOnOverwrite
	dialogCode = showDialogOnOverwrite && FileExists(fileName) ? 1 : 2
	if(ParamIsDefault(fileFilter) && ParamIsDefault(message))
		Open/D=(dialogCode) fnum as fileName
	elseif(ParamIsDefault(fileFilter) && !ParamIsDefault(message))
		Open/D=(dialogCode)/M=message fnum as fileName
	elseif(!ParamIsDefault(fileFilter) && ParamIsDefault(message))
		Open/D=(dialogCode)/F=fileFilter fnum as fileName
	else
		Open/D=(dialogCode)/F=fileFilter/M=message fnum as fileName
	endif

	if(IsEmpty(S_fileName))
		return NaN
	endif
#endif

	Open/Z fnum as S_fileName
	ASSERT(!V_flag, "Could not open file for writing!")
	if(!ParamIsDefault(savedFileName))
		savedFileName = S_fileName
	endif

	FBinWrite fnum, data
	Close fnum

	return 0
End

/// @brief Load data from file to a string. The file size must be < 2GB.
///
/// @param[in] fileName fileName to use. If the fileName is empty or invalid a file load dialog will be shown.
/// @param[in] fileFilter [optional, default = "Plain Text Files (*.txt):.txt;All Files:.*;"] file filter string in Igor specific notation.
/// @param[in] message [optional, default = "Select file"] window title of the save file dialog.
/// @returns loaded string data and full path fileName
Function [string data, string fName] LoadTextFile(string fileName, [string fileFilter, string message])

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
	ASSERT(V_logEOF < STRING_MAX_SIZE, "Can't load " + num2istr(V_logEOF) + " bytes to string.")
	data = PadString("", V_logEOF, 0x20)
	FBinRead fnum, data
	Close fnum

	return [data, S_Path + S_fileName]
End

/// @brief Load data from a file to a text wave.
///
/// @param[in] fullFilePath full path to the file to be loaded
/// @param[in] sep          separator string that splits the file data to the wave cells, typically the line ending
/// @returns free text wave with the data, a null wave if the file could not be found or there was a problem reading the file
Function/WAVE LoadTextFileToWave(string fullFilePath, string sep)

	variable loadFlags, err

	if(!FileExists(fullFilePath))
		return $""
	endif

	loadFlags = LOADWAVE_V_FLAGS_DISABLELINEPRECOUNTING | LOADWAVE_V_FLAGS_DISABLEUNESCAPEBACKSLASH | LOADWAVE_V_FLAGS_DISABLESUPPORTQUOTEDSTRINGS
	AssertOnAndClearRTError()
	DFREF saveDFR = GetDataFolderDFR()
	SetDataFolder NewFreeDataFolder()

	LoadWave/Q/H/A/J/K=2/V={sep, "", 0, loadFlags} fullFilePath; err=GetRTError(1)
	if(!V_flag)
		SetDataFolder saveDFR
		return $""
	elseif(V_flag > 1)
		SetDataFolder saveDFR
		ASSERT(0, "Expected to load a single text wave")
	endif

	WAVE/T wv = $StringFromList(0, S_waveNames)
	SetDataFolder saveDFR

	return wv
End

/// @brief Removes found entry from a text wave
///
/// @param w       text wave
/// @param entry   element content to compare
/// @param options [optional, defaults to "whole wave element"] FindValue/TXOP options
/// @param all     [optional, defaults to false] removes all entries
///
/// @return 0 if at least one entry was found, 1 otherwise
Function RemoveTextWaveEntry1D(WAVE/T w, string entry, [variable options, variable all])
	ASSERT(IsTextWave(w), "Input wave must be a text wave")

	variable start, foundOnce

	if(ParamIsDefault(options))
		options = 4
	endif

	if(ParamIsDefault(all))
		all = 0
	else
		all = !!all
	endif

	for(;;)
		if(start >= DimSize(w, ROWS))
			break
		endif

		FindValue/S=(start)/TXOP=(options)/TEXT=entry/RMD=[][0][0][0] w

		if(V_Value >= 0)
			DeletePoints V_Value, 1, w

			if(all)
				start = V_Value
				foundOnce = 1
				continue
			endif

			return 0
		endif

		break
	endfor

	return foundOnce ? 0 : 1
End

/// @brief Checks if a string ends with a specific suffix. The check is case-insensitive.
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
	AssertOnAndClearRTError()
	try
		GetFileFolderInfo/Q/Z filepath; AbortOnRTE
	catch
		ASSERT(0, "Error: " + GetRTErrMessage())
	endtry

	return !V_Flag && V_IsFile
End

/// @brief Check wether the given path points to an existing folder
Function FolderExists(folderpath)
	string folderpath

	folderpath = ResolveAlias(folderpath)
	AssertOnAndClearRTError()
	try
		GetFileFolderInfo/Q/Z folderpath; AbortOnRTE
	catch
		ASSERT(0, "Error: " + GetRTErrMessage())
	endtry

	return !V_Flag && V_isFolder
End

/// @brief Return the file version
Function/S GetFileVersion(filepath)
	string filepath

	filepath = ResolveAlias(filepath)
	AssertOnAndClearRTError()
	try
		GetFileFolderInfo/Q/Z filepath; AbortOnRTE
	catch
		ASSERT(0, "Error: " + GetRTErrMessage())
	endtry

	if(V_flag || !V_isFile)
		return ""
	endif

	return S_FileVersion
End

/// @brief Return the file size in bytes
Function GetFileSize(string filepath)

	filepath = ResolveAlias(filepath)

	AssertOnAndClearRTError()
	try
		GetFileFolderInfo/Q/Z filepath; AbortOnRTE
	catch
		ASSERT(0, "Error: " + GetRTErrMessage())
	endtry

	if(V_flag || !V_isFile)
		return NaN
	endif

	return V_logEOF
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
threadsafe Function/S GenerateRFC4122UUID()

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
///
/// UTF_NOINSTRUMENTATION
threadsafe Function HexToNumber(ch)
	string ch

	variable var

	ASSERT_TS(strlen(ch) <= 2, "Expected only up to two characters")

	sscanf ch, "%x", var
	ASSERT_TS(V_flag == 1, "Unexpected string")

	return var
End

/// @brief Convert a number into hexadecimal
///
/// UTF_NOINSTRUMENTATION
threadsafe Function/S NumberToHex(var)
	variable var

	string str

	ASSERT_TS(IsInteger(var) && var >= 0 && var < 256 , "Invalid input")

	sprintf str, "%02x", var

	return str
End

/// @brief Convert a string in hex format to an unsigned binary wave
///
/// This function works on a byte level so it does not care about endianess.
///
/// UTF_NOINSTRUMENTATION
threadsafe Function/WAVE HexToBinary(str)
	string str

	variable length

	length = strlen(str)
	ASSERT_TS(mod(length, 2) == 0, "Expected a string with a power of 2 length")

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
			JSON_AddString(jsonID, jsonpath + "contents", Base64EncodeSafe(values[i]))
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
///
/// UTF_NOINSTRUMENTATION
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
Function/WAVE GrepTextWave(Wave/T in, string regexp, [variable invert])

	if(ParamIsDefault(invert))
		invert = 0
	else
		invert = !!invert
	endif

	Make/FREE/T/N=0 result
	Grep/E={regexp, invert} in as result

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
/// If the wave is empty with index being zero, we return a wave with one point
/// so that we:
/// - can store something non-empty
/// - preserve the dimension labels (this can get lost for empty waves when duplication/saving)
///
/// @see EnsureLargeEnoughWave()
threadsafe Function/WAVE RemoveUnusedRows(WAVE wv)

	variable index

	index = GetNumberFromWaveNote(wv, NOTE_INDEX)

	if(IsNaN(index))
		return wv
	endif

	ASSERT_TS(IsInteger(index) && index >= 0, "Expected non-negative and integer NOTE_INDEX")

	Duplicate/FREE/RMD=[0, max(0, index - 1)] wv, dup

	return dup
End

/// @brief Check wether `val1` and `val2` are equal or both NaN
threadsafe Function EqualValuesOrBothNaN(variable left, variable right)

	return (IsNaN(left) && IsNaN(right)) || (left == right)
End

/// @brief Checks wether `wv` is constant and has the value `val`
///
/// @param wv        wave to check
/// @param val       value to check
/// @param ignoreNaN [optional, defaults to true] ignore NaN in wv
threadsafe Function IsConstant(WAVE wv, variable val, [variable ignoreNaN])

	variable minimum, maximum

	if(ParamIsDefault(ignoreNaN))
		ignoreNaN = 1
	else
		ignoreNaN = !!ignoreNaN
	endif

	if(DimSize(wv, ROWS) == 0)
		return NaN
	endif

	WaveStats/M=1/Q wv

	if(V_npnts == 0 && V_numInfs == 0)
		// complete input wave is NaN

		if(ignoreNaN)
			return NaN
		else
			return IsNaN(val)
		endif
	elseif(V_numNans > 0)
		// we have some NaNs
		 if(!ignoreNaN)
			// and don't ignore them, this is always false
			return 0
		endif
	endif

	[minimum, maximum] = WaveMinAndMax(wv)

	return minimum == val && maximum == val
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
threadsafe Function/WAVE ZapNaNs(WAVE data)

	ASSERT_TS(IsFloatingPointWave(data), "Can only work with floating point waves")

	if(DimSize(data, ROWS) == 0)
		return $""
	endif

	MatrixOP/FREE dup = zapNans(data)

	if(DimSize(dup, ROWS) == 0)
		return $""
	endif

	return dup
End

/// @brief Finds the first occurrence of a text within a range of points in a SORTED text wave
///
/// From https://www.wavemetrics.com/code-snippet/binary-search-pre-sorted-text-waves by Jamie Boyd
/// Completely reworked, fixed and removed unused features
threadsafe Function BinarySearchText(WAVE/T theWave, string theText, [variable caseSensitive, variable startPos, variable endPos])
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

	if(ParamIsDefault(caseSensitive))
		caseSensitive = 0
	else
		caseSensitive = !!caseSensitive
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
		theCmp = cmpstr(thetext, theWave[iPos], caseSensitive)

		if(theCmp ==0) //thetext is the same as theWave [iPos]
			if((iPos == startPos) || (cmpstr(theText, theWave[iPos -1], caseSensitive) == 1))
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

/// @brief Returns a hex string which is unique for the given Igor Pro session
///
/// It allows to distinguish multiple Igor instances, but is not globally unique.
threadsafe Function/S GetIgorInstanceID()
	return Hash(IgorInfo(-102), 1)
End

/// @brief Rename the given datafolder path to a unique name
///
/// With path `root:a:b:c` and suffix `_old` the datafolder is renamed to `root:a:b:c_old` or if that exists
/// `root:a:b:c_old_1` and so on.
Function RenameDataFolderToUniqueName(string path, string suffix)

	string name, folder

	if(!DataFolderExists(path))
		return NaN
	endif

	DFREF dfr = $path
	name = GetFile(path)
	folder = UniqueDataFolderName($path + "::", name + suffix)
	name = GetFile(folder)
	RenameDataFolder $path, $name
	ASSERT_TS(!DataFolderExists(path), "Could not move it of the way.")
	ASSERT_TS(DataFolderExists(folder), "Could not create it in the correct place.")
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

/// @brief If the layout of an panel was changed, this function calls the
///        ResizeControlsPanel module functions of the Igor Pro native package
///        to store the changed resize info. The originally intended way to do this
///        was through the Packages GUI, which is clunky for some workflows.
Function StoreCurrentPanelsResizeInfo(string panel)

	ASSERT(!IsEmpty(panel), "Panel name can not be empty.")

	ResizeControlsPanel#ResetListboxWaves()
	ResizeControlsPanel#SaveControlPositions(panel, 0)
End

/// @brief Elide the given string to the requested length
Function/S ElideText(string str, variable returnLength)
	variable length, totalLength, i, first, suffixLength
	string ch, suffix

	totalLength = strlen(str)

	ASSERT(IsInteger(returnLength), "Invalid return length")

	if(totalLength <= returnLength)
		return str
	endif

	suffix = "..."
	suffixLength = strlen(suffix)

	ASSERT(returnLength > suffixLength, "Invalid return length")

	first = returnLength - suffixLength - 1

	for(i = first; i > 0; i -= 1)
		ch = str[i]
		if(GrepString(ch, "^[[:space:]]$"))
			return str[0, i - 1] + suffix
		endif
	endfor

	// could not find any whitespace
	// just cut it off
	return str[0, first] + suffix
End

/// @brief Load the wave `$name.itx` from the folder of this procedure file and store
/// it in the static data folder.
Function/WAVE LoadWaveFromDisk(string name)
	string path

	path = GetFolder(FunctionPath("")) + name + ".itx"

	LoadWave/Q/C/T path
	if(!V_flag)
		return $""
	endif

	ASSERT(ItemsInList(S_waveNames) == 1, "Could not find exactly one wave")

	WAVE wv = $StringFromList(0, S_waveNames)

	DFREF dfr = GetStaticDataFolder()
	MoveWave wv, dfr

	return wv
End

/// @brief Store the given wave as `$name.itx` in the same folder as this
/// procedure file on disk.
Function StoreWaveOnDisk(WAVE wv, string name)
	string path

	ASSERT(IsValidObjectName(name), "Name is not a valid igor object name")

	DFREF dfr = GetUniqueTempPath()
	Duplicate wv, dfr:$name/WAVE=storedWave

	path = GetFolder(FunctionPath("")) + name + ".itx"
	Save/O/T/M="\n" storedWave as path
	KillOrMoveToTrash(wv = storedWave)
	RemoveEmptyDataFolder(dfr)
End

Function GenerateMultiplierConstants()
	variable numElements, i, j, maxLength
	string str

	WAVE/T prefixes = ListToTextWave(PREFIX_LONG_LIST, ";")
	WAVE/D values = ListToNumericWave(PREFIX_VALUE_LIST, ";")

	numElements = DimSize(prefixes, ROWS)
	ASSERT(DimSize(values, ROWS) == numElements, "Non matching list sizes")

	Make/FREE/N=(numElements) lengths = strlen(prefixes[p])
	maxLength = WaveMax(lengths)

	for(i = 0; i < numElements; i += 1)
		for(j = 0; j < numElements; j += 1)
			if( i == j)
				continue
			endif

			sprintf str, "Constant %*s_TO_%-*s = %.0e", maxLength, UpperStr(prefixes[i]), maxLength, UpperStr(prefixes[j]), (values[i] / values[j])
			print str
		endfor
	endfor
End

/// @brief Return true if the passed regular expression is well-formed
threadsafe Function IsValidRegexp(string regexp)
	variable err, result

	// GrepString and friends treat an empty regular expression as *valid*
	// although this seems to be standard behaviour, we don't allow that shortcut
	if(IsEmpty(regexp))
		return 0
	endif

	AssertOnAndClearRTError()
	result = GrepString("", regexp); err = GetRTError(1)

	return err == 0
End

/// @brief Calculate PowerSpectrum on a per column basis on each input[][col]
///        and write the result into output[][col]. The result is capped to the output rows.
///        No window function is applied.
threadsafe Function DoPowerSpectrum(WAVE input, WAVE output, variable col)
	variable numRows = DimSize(input, ROWS)

	Duplicate/FREE/RMD=[*][col] input, slice
	Redimension/N=(numRows) slice

	WAVE powerSpectrum = DoFFT(slice, winFunc = FFT_WINF_DEFAULT)

	output[][col] = magsqr(powerSpectrum[p])
End

/// @brief Perform FFT on input with optionally given window function
///
/// @param input   Wave to perform FFT on
/// @param winFunc [optional, defaults to NONE] FFT window function
/// @param padSize [optional, defaults to the next power of 2 of the input wave row size] Target size used for padding
threadsafe Function/WAVE DoFFT(WAVE input, [string winFunc, variable padSize])

	if(ParamIsDefault(padSize))
		padSize = TP_GetPowerSpectrumLength(DimSize(input, ROWS))
	else
		ASSERT_TS(IsFinite(padSize) && padSize >= DimSize(input, ROWS), "padSize must be finite and larger as the input row size")
	endif

	if(ParamIsDefault(winFunc))
		FFT/PAD={padSize}/DEST=result/FREE input
	else
		ASSERT_TS(WhichListItem(winFunc, FFT_WINF) >= 0, "Invalid window function for FFT")
		FFT/PAD={padSize}/WINF=$winFunc/DEST=result/FREE input
	endif

	return result
End

/// @brief Convert a numerical integer list seperated by sepChar to a list including a range sign ("-")
/// e. g. 1,2,3,4 -> 1-4
/// 1,2,4,5,6 -> 1-2,4-6
/// 1,1,1,2 -> 1-2
/// the input list does not have to be sorted
Function/S CompressNumericalList(string list, string sepChar)

	variable i, nextEntry, entry, nextEntryMinusOne, numItems
	variable firstConsecutiveEntry = NaN
	string resultList = ""

	ASSERT(!IsEmpty(sepChar), "Seperation character is empty.")

	if(IsEmpty(list))
		return ""
	endif

	list = SortList(list, sepChar, 2)
	numItems = ItemsInList(list, sepChar)

	for(i = 0; i < numItems; i += 1)

		entry = str2numSafe(StringFromList(i, list, sepChar))
		ASSERT(IsInteger(entry), "Number from list item must be integer")
		nextEntry = str2numSafe(StringFromList(i + 1, list, sepChar))

		if(entry == nextEntry)
			continue
		endif

		nextEntryMinusOne = str2numSafe(StringFromList(i + 1, list, sepChar)) - 1

		if(IsNaN(entry))
			continue
		endif

		// different entries and no range in progress
		if(entry != nextEntryMinusOne && IsNaN(firstConsecutiveEntry))
			resultList = AddListItem(num2istr(entry), resultList, sepChar, inf)
			// different entries but we have to finalize the last range
		elseif(entry != nextEntryMinusOne && !IsNaN(firstConsecutiveEntry))
			resultList	+= "-" + num2istr(entry) + sepChar
			firstConsecutiveEntry = NaN
			// same entries and we have to start a range
		elseif(entry == nextEntryMinusOne && IsNaN(firstConsecutiveEntry))
			resultList += num2istr(entry)
			firstConsecutiveEntry = entry
		// else
		// same entries and a range is in progress
		endif
	endfor

	return RemoveEnding(resultList, sepChar)
End

/// @brief Give the free wave `wv` the name `name`
threadsafe Function ChangeFreeWaveName(WAVE wv, string name)

	ASSERT_TS(IsFreeWave(wv), "Only works with free waves")
	ASSERT_TS(IsValidObjectName(name), "name is not a valid object name")

	DFREF dfr = NewFreeDataFolder()

	MoveWave wv, dfr:$name
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

	WAVE/D/Z dimSizes = JSON_GetWave(jsonID, path + "/dimension/size", waveMode = 1, ignoreErr = 1)
	ASSERT(WaveExists(dimSizes), "dimension sizes are missing")

	Make/D/FREE/N=(MAX_DIMENSION_COUNT) newSizes = -1
	newSizes[0, DimSize(dimSizes, ROWS) - 1] = dimSizes[p]
	Redimension/N=(newSizes[0], newSizes[1], newSizes[2], newSizes[3]) data

	WAVE/D/Z dimDeltas = JSON_GetWave(jsonID, path + "/dimension/delta", waveMode = 1, ignoreErr = 1)
	WAVE/D/Z dimOffsets = JSON_GetWave(jsonID, path + "/dimension/offset", waveMode = 1, ignoreErr = 1)
	WAVE/T/Z dimUnits = JSON_GetTextWave(jsonID, path + "/dimension/unit", ignoreErr = 1)

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

	WAVE/T/Z dimLabelsFull = JSON_GetTextWave(jsonID, path + "/dimension/label/full", ignoreErr = 1)

	if(WaveExists(dimLabelsFull))
		for(lbl : dimLabelsFull)
			SetDimLabel dim, -1, $lbl, data
			dim++
		endfor
	endif

	WAVE/T/Z dimLabelsEach = JSON_GetTextWave(jsonID, path + "/dimension/label/each", ignoreErr = 1)

	if(WaveExists(dimLabelsEach))
		ASSERT(DimSize(dimLabelsEach, ROWS) == Sum(dimSizes), "Mismatched dimension label each wave")

		for(i = 0; i < MAX_DIMENSION_COUNT; i += 1)
			for(j = 0; j < newSizes[i]; j += 1)
				SetDimLabel i, j, $dimLabelsEach[k++], data
			endfor
		endfor
	endif

	// no way to restore the modification date

	WAVE/D/Z dataFullScale = JSON_GetWave(jsonID, path + "/data/fullScale", waveMode = 1, ignoreErr = 1)

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

/// @brief Return the CRC of the contents of the plain/formatted notebook
///
/// Takes into account formatting but ignores selection.
Function GetNotebookCRC(string win)

	string content

	content = WinRecreation(win, 1)

	// Filter out // lines which contain the selection
	content = GrepList(content, "//.*", 1, "\r")

	return StringCRC(0, content)
End

///@brief Format the 2D text wave into a string usable for a legend
Function/S FormatTextWaveForLegend(WAVE/T input)

	variable i, j, numRows, numCols, length
	variable spacing = 2
	string str = ""
	string line

	numRows = DimSize(input, ROWS)
	numCols = DimSize(input, COLS)

	// determine the maximum length of each column
	Make/FREE/N=(numRows, numCols) totalLength = strlen(input[p][q])

	MatrixOp/FREE maxColLength = maxCols(totalLength)^t

	for(i = 0; i < numRows; i += 1)
		line = ""

		for(j = 0; j < numCols; j += 1)
			length = maxColLength[j] - totalLength[i][j]

			if(j < numCols - 1)
				length += spacing
			endif

			line += input[i][j] + PadString("", length, 0x20) // space
		endfor

		str += line + "\r"
	endfor

	return RemoveEndingRegExp(str, "[[:space:]]*\\r+$")
End

/// @brief Checks if given lineStyle code is valid (as of Igor Pro 9)
///
/// @param lineStyleCode line style code value for a trace
/// @returns 1 if valid, 0 otherwise
Function IsValidTraceLineStyle(variable lineStyleCode)

	return IsFinite(lineStyleCode) && lineStyleCode >= 0 && lineStyleCode <= 17
End

/// @brief Checks if given trace display code is valid (as of Igor Pro 9)
///
/// @param traceDisplayCode line style code value for a trace
/// @returns 1 if valid, 0 otherwise
Function IsValidTraceDisplayMode(variable traceDisplayCode)

	return IsFinite(traceDisplayCode) && traceDisplayCode >= TRACE_DISPLAY_MODE_LINES && traceDisplayCode <= TRACE_DISPLAY_MODE_LAST_VALID
End

/// From DisplayHelpTopic "Character-by-Character Operations"
/// @brief Returns the number of bytes in the UTF-8 character that starts byteOffset
///        bytes from the start of str.
///        NOTE: If byteOffset is invalid this routine returns 0.
///              Also, if str is not valid UTF-8 text, this routine return 1.
Function NumBytesInUTF8Character(string str, variable byteOffset)

	variable firstByte
	variable numBytesInString = strlen(str)

	ASSERT(byteOffset >= 0 || byteOffset < numBytesInString, "Invalid byte offset")

	firstByte = char2num(str[byteOffset]) & 0x00FF

	if(firstByte < 0x80)
		return 1
	endif

	if(firstByte >= 0xC2 && firstByte <= 0xDF)
		return 2
	endif

	if(firstByte >= 0xE0 && firstByte <= 0xEF)
		return 3
	endif

	if(firstByte >= 0xF0 && firstByte <= 0xF4)
		return 4
	endif

	// If we are here, str is not valid UTF-8. Treat the first byte as a 1-byte character.
	return 1
End

/// From DisplayHelpTopic "Character-by-Character Operations"
/// @brief Returns the number of UTF8 characters in a string
Function UTF8CharactersInString(string str)

	variable numCharacters, byteOffset, numBytesInCharacter
	variable length = strlen(str)

	do
		if(byteOffset >= length)
			break
		endif
		numBytesInCharacter = NumBytesInUTF8Character(str, byteOffset)
		ASSERT(numBytesInCharacter > 0, "Bug in CharactersInUTF8String")
		numCharacters += 1
		byteOffset += numBytesInCharacter
	while(1)

	return numCharacters
End

/// From DisplayHelpTopic "Character-by-Character Operations"
/// @brief Returns the UTF8 characters in a string at position charPos
Function/S UTF8CharacterAtPosition(string str, variable charPos)

	variable length, byteOffset, numBytesInCharacter

	if(charPos < 0)
		return ""
	endif

	length = strlen(str)
	do
		if(byteOffset >= length)
			return ""
		endif
		if(charPos == 0)
			break
		endif
		numBytesInCharacter = NumBytesInUTF8Character(str, byteOffset)
		byteOffset += numBytesInCharacter
		charPos -= 1
	while(1)

	numBytesInCharacter = NumBytesInUTF8Character(str, byteOffset)
	return str[byteOffset, byteOffset + numBytesInCharacter - 1]
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
		wv[charPos] = str[byteOffset, byteOffset + numBytesInCharacter - 1]
		charPos += 1
		byteOffset += numBytesInCharacter
	while(1)
	Redimension/N=(charPos) wv

	return wv
End

/// @brief Returns the path to the users documents folder
Function/S GetUserDocumentsFolderPath()

	string userDir = GetEnvironmentVariable("USERPROFILE")

	userDir = ParseFilePath(2, ParseFilePath(5, userDir, ":", 0, 0), ":", 0, 0)

	return userDir + "Documents:"
End

/// @brief For DF memory management, increase reference count
///
/// @param dfr data folder reference of the target df
Function RefCounterDFIncrease(DFREF dfr)

	NVAR rc = $GetDFReferenceCount(dfr)
	rc += 1
End

/// @brief For DF memory management, decrease reference count and kill DF if zero is reached
///
/// @param dfr data folder reference of the target df
Function RefCounterDFDecrease(DFREF dfr)

	NVAR rc = $GetDFReferenceCount(dfr)
	rc -= 1

	if(rc == 0)
		KillOrMoveToTrash(dfr=dfr)
	endif
End

/// @brief Update the help and user data of a button used as info/copy button
Function UpdateInfoButtonHelp(string win, string ctrl, string content)

	string htmlStr = "<pre>" + content + "</pre>"

	Button $ctrl, win=$win,help={htmlStr},userdata=content
End

/// @brief Acts like the `limit` builtin but replaces values outside the valid range instead of clipping them
threadsafe Function LimitWithReplace(variable val, variable low, variable high, variable replacement)
	return (val >= low && val <= high) ? val : replacement
End

/// @brief Return true if the calling function is called recursively, i.e. it
///        is present multiple times in the call stack
threadsafe Function IsFunctionCalledRecursively()
	return ItemsInList(ListMatch(GetRTStackInfo(0), GetRTStackInfo(2))) > 1
End

/// @brief Splits a text wave (with e.g. log entries) into parts. The parts are limited by a size in bytes such that each part
///        contains only complete lines and is smaller than the given size limit. A possible separator for line endings
///        is considered in the size calculation.
///
/// @param logData       text wave
/// @param sep           separator string that is considered in the length calculation. This is useful if the resulting waves are later converted
///                      to strings with TextWaveToList, where the size grows by lines * separatorLength.
/// @param lim           size limit for each part in bytes
/// @param lastIndex     [optional, default DimSize(logData, ROWS) - 1] When set, only elements in logData from index 0 to lastIndex are considered. lastIndex is included.
///                      lastIndex is limited between 0 and DimSize(logData, ROWS) - 1.
/// @param firstPartSize [optional, default lim] When set then the first parts size limit is firstPartSize instead of lim
/// @returns wave reference wave containing text waves that are consecutive and sequential parts of logdata
Function/WAVE SplitLogDataBySize(WAVE/T logData, string sep, variable lim, [variable lastIndex, variable firstPartSize])

	variable lineCnt, sepLen, i, size, elemSize
	variable first, sizeLimit, resultCnt

	lineCnt = DimSize(logData, ROWS)
	firstPartSize = ParamIsDefault(firstPartSize) ? lim : firstPartSize
	lastIndex = ParamIsDefault(lastIndex) ? lineCnt - 1 : limit(lastIndex, 0, lineCnt - 1)
	sepLen = strlen(sep)
	Make/FREE/D/N=(lastIndex + 1) logSizes
	MultiThread logSizes[0, lastIndex] = strlen(logData[p])

	Make/FREE/WAVE/N=(MINIMUM_WAVE_SIZE) result

	sizeLimit = firstPartSize
	for(i = 0; i <= lastIndex; i += 1)
		elemSize = logSizes[i] + sepLen
		ASSERT(elemSize <= sizeLimit, "input element larger than size limit " + num2istr(elemSize) + " / " + num2istr(sizeLimit))
		size += elemSize
		if(size > sizeLimit)

			Duplicate/FREE/T/RMD=[first, i - 1] logData, logPart
			EnsureLargeEnoughWave(result, indexShouldExist=resultCnt)
			result[resultCnt] = logPart
			resultCnt += 1

			sizeLimit = lim
			first = i
			size = elemSize
		endif
	endfor

	Duplicate/FREE/T/RMD=[first, i - 1] logData, logPart
	EnsureLargeEnoughWave(result, indexShouldExist=resultCnt)
	result[resultCnt] = logPart
	resultCnt += 1

	Redimension/N=(resultCnt) result

	return result
End

threadsafe Function/S Base64EncodeSafe(string data)

	ASSERT_TS(strlen(data) <= BASE64ENCODE_INPUT_MAX_SIZE, "Input string too larger for Base64Encode")

	return Base64Encode(data)
End

/// @brief Calculated the size of Base64 encoded data from the unencoded size
///
/// @param unencodedSize unencoded size
/// @returns encoded size
threadsafe Function Base64EncodeSize(variable unencodedSize)

	return (unencodedSize + 2 - mod(unencodedSize + 2, 3)) / 3 * 4
End

/// @brief Returns the day of the week, where 1 == Sunday, 2 == Monday ... 7 == Saturday
Function GetDayOfWeek(variable seconds)

	string dat, regex, dayOfWeek

	ASSERT(seconds >= -1094110934400 && seconds <= 973973807999, "seconds input out of range")
	dat = Secs2Date(seconds, -1)

	regex = "^.*\(([0-9])\)"
	SplitString/E=regex dat, dayOfWeek
	ASSERT(V_flag == 1, "Error parsing date: " + dat)

	return str2num(dayOfWeek)
End

/// @brief Upper case the first character in an ASCII string
threadsafe Function/S UpperCaseFirstChar(string str)

	variable len

	len = strlen(str)

	if(len == 0)
		return str
	endif

	return UpperStr(str[0]) + str[1, len - 1]
End
