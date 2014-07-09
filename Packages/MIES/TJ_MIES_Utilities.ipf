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

	if(isNull(win) || cmpstr(CleanupName(win,0),win) != 0)
		return 0
	endif

	DoWindow $win
	return V_flag != 0
End

/// @brief Alternative implementation for WaveList which honours a dfref and thus
/// does not require SetDataFolder calls.
/// @returns list of wave names matching regExpStr located in dfr
Function/S GetListOfWaves(dfr, regExpStr)
	dfref dfr
	string regExpStr

	variable i, numWaves
	// todo think about using PadString here for increased speed
	string list = "", name

	ASSERT(DataFolderExistsDFR(dfr),"Non-existing datafolder")
	ASSERT(!isEmpty(regExpStr),"regexpStr is empty or null")

	numWaves = CountObjectsDFR(dfr, COUNTOBJECTS_WAVES)
	for(i=0; i<numWaves; i+=1)
		Wave wv = WaveRefIndexedDFR(dfr, i)
		name = NameOfWave(wv)

		if(GrepString(name,regExpStr))
			list = AddListItem(name,list,";",Inf)
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
Function EnsureLargeEnoughWave(wv, [minimumSize, dimension])
	Wave wv
	variable minimumSize, dimension

	if(ParamIsDefault(dimension))
		dimension = ROWS
	endif

	ASSERT(dimension == ROWS || dimension == COLS || dimension == LAYERS || dimension == CHUNKS, "Invalid dimension")
	ASSERT(WaveExists(wv), "Wave does not exist")

	if(ParamIsDefault(minimumSize))
		minimumSize = MINIMUM_WAVE_SIZE
	endif

	minimumSize = max(MINIMUM_WAVE_SIZE,minimumSize)

	if(minimumSize < DimSize(wv,dimension))
		return NaN
	endif

	minimumSize *= 2

	Make/FREE/I/N=(MAX_DIMENSION_COUNT) targetSizes = -1
	targetSizes[dimension] = minimumSize

	Redimension/N=(targetSizes[ROWS], targetSizes[COLS], targetSizes[LAYERS], targetSizes[CHUNKS]) wv
End

/// @brief Convert Bytes to MiBs, a mebibyte being @f$ 2^{20} @f$.
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


/// @brief Recursively removes the all folders from the datafolder path,
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

/// @brief Returns a datafolder reference to the device type folder
Function/DF GetDeviceTypePath(deviceType)
	string deviceType

	return createDFWithAllParents(GetDeviceTypePathAsString(deviceType))
End

/// @brief Returns the path to the device type folder, e.g. root:mies::ITCDevices:ITC1600:
Function/S GetDeviceTypePathAsString(deviceType)
	string deviceType

	return Path_ITCDevicesFolder("") + ":" + deviceType + ":"
End

/// @brief Returns a datafolder reference to the device folder
Function/DF GetDevicePath(deviceType, deviceNumber)
	string deviceType, deviceNumber

	return createDFWithAllParents(GetDevicePathAsString(deviceType, deviceNumber))
End

/// @brief Returns the path to the device folder, e.g. root:mies::ITCDevices:ITC1600:Device0:
Function/S GetDevicePathAsString(deviceType, deviceNumber)
	string deviceType, deviceNumber

	return GetDeviceTypePathAsString(deviceType) + "Device" + deviceNumber + ":"
End

/// @brief Returns a datafolder reference to the device data folder
Function/DF GetDeviceDataPath(deviceType, deviceNumber)
	string deviceType, deviceNumber

	return createDFWithAllParents(GetDeviceDataPathAsString(deviceType, deviceNumber))
End

/// @brief Returns the path to the device folder, e.g. root:mies::ITCDevices:ITC1600:Device0:Data:
Function/S GetDeviceDataPathAsString(deviceType, deviceNumber)
	string deviceType, deviceNumber

	return GetDevicePathAsString(deviceType, deviceNumber) + "Data" + ":"
End
