#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_MIESUTILS_SWEEP
#endif // AUTOMATED_TESTING

/// @file MIES_MiesUtilities_Sweep.ipf
/// @brief This file holds MIES utility functions for working with sweeps

/// @brief Return a wave reference wave with all single column waves of the given channel type
///
/// Holds invalid wave refs for non-existing entries.
///
/// @param sweepDFR    datafolder reference with 1D sweep data
/// @param channelType One of @ref XopChannelConstants
///
/// @see GetDAQDataSingleColumnWave() or SplitSweepIntoComponents()
Function/WAVE GetDAQDataSingleColumnWaves(DFREF sweepDFR, variable channelType)

	ASSERT(DataFolderExistsDFR(sweepDFR), "sweepDFR is invalid")

	Make/FREE/WAVE/N=(GetNumberFromType(xopVar = channelType)) matches = GetDAQDataSingleColumnWave(sweepDFR, channelType, p)

	return matches
End

/// @brief Return a 1D sweep data wave previously created by SplitSweepIntoComponents()
///
/// Returned wave reference can be null.
///
/// @param numericalValues  numerical labnotebook
/// @param textualValues    textual labnotebook
/// @param sweepNo          sweep number
/// @param sweepDFR         datafolder holding 1D waves
/// @param channelType      One of @ref XopChannelConstants
/// @param GUIchannelNumber GUI channel number
threadsafe Function/WAVE GetDAQDataSingleColumnWaveNG(WAVE numericalValues, WAVE/T textualValues, variable sweepNo, DFREF sweepDFR, variable channelType, variable GUIchannelNumber)

	variable hwChannelNumber, ttlBit, hwDACType

	if(channelType == XOP_CHANNEL_TYPE_TTL)
		WAVE/Z guiToHWChannelMap = GetActiveChannels(numericalValues, textualValues, sweepNo, channelType, TTLMode = TTL_GUITOHW_CHANNEL)
		if(!WaveExists(guiToHWChannelMap))
			return $""
		endif

		hwChannelNumber = guiToHWChannelMap[GUIchannelNumber][%HWCHANNEL]
		hwDACType       = GetUsedHWDACFromLNB(numericalValues, sweepNo)
		ASSERT_TS(hwDACType == HARDWARE_ITC_DAC || hwDACType == HARDWARE_NI_DAC, "Unsupported hardware dac type")

		if(hwDACType == HARDWARE_NI_DAC)
			return GetDAQDataSingleColumnWave(sweepDFR, channelType, hwChannelNumber)
		endif

		ttlBit = guiToHWChannelMap[GUIchannelNumber][%TTLBITNR]
		return GetDAQDataSingleColumnWave(sweepDFR, channelType, hwChannelNumber, splitTTLBits = 1, ttlBit = ttlBit)
	endif

	hwChannelNumber = GUIchannelNumber
	return GetDAQDataSingleColumnWave(sweepDFR, channelType, hwChannelNumber)
End

/// @brief Return a 1D data wave previously created by SplitSweepIntoComponents()
///
/// Returned wave reference can be invalid.
///
/// @param sweepDFR      datafolder holding 1D waves
/// @param channelType   One of @ref XopChannelConstants
/// @param channelNumber hardware channel number
/// @param splitTTLBits  [optional, defaults to false] return a single bit of the TTL wave
/// @param ttlBit        [optional] number specifying the TTL bit
threadsafe Function/WAVE GetDAQDataSingleColumnWave(DFREF sweepDFR, variable channelType, variable channelNumber, [variable splitTTLBits, variable ttlBit])

	string wvName

	if(ParamIsDefault(splitTTLBits))
		splitTTLBits = 0
	else
		splitTTLBits = !!splitTTLBits
	endif

	ASSERT_TS(ParamIsDefault(splitTTLBits) + ParamIsDefault(ttlBit) != 1, "Expected both or none of splitTTLBits and ttlBit")
	ASSERT_TS(channelNumber < GetNumberFromType(xopVar = channelType), "Invalid channel index")

	wvName = StringFromList(channelType, XOP_CHANNEL_NAMES) + "_" + num2str(channelNumber)

	if(channelType == XOP_CHANNEL_TYPE_TTL && splitTTLBits)
		wvName += "_" + num2str(ttlBit)
	endif

	WAVE/Z/SDFR=sweepDFR wv = $wvName

	return wv
End

/// @brief Check if the given sweep number is valid
///
/// UTF_NOINSTRUMENTATION
threadsafe Function IsValidSweepNumber(variable sweepNo)

	return IsInteger(sweepNo) && sweepNo >= 0
End

/// @brief Extract an one dimensional wave from the given sweep/hardware data wave and column
///
/// @param config config wave
/// @param sweep  sweep wave or hardware data wave from all hardware types
/// @param index  index into `sweep`, can be queried with #AFH_GetDAQDataColumn
///
/// @returns a reference to a free wave with the single channel data
threadsafe Function/WAVE ExtractOneDimDataFromSweep(WAVE config, WAVE sweep, variable index)

	ASSERT_TS(IsValidSweepAndConfig(sweep, config, configVersion = 0), "Sweep and config are not compatible")

	WAVE/T units = AFH_GetChannelUnits(config)
	if(IsWaveRefWave(sweep))
		ASSERT_TS(index < DimSize(sweep, ROWS), "The index is out of range")
		WAVE/WAVE sweepRef = sweep
		Duplicate/FREE sweepRef[index], data
		if(index < DimSize(units, ROWS))
			ASSERT_TS(!CmpStr(WaveUnits(data, DATADIMENSION), units[index]), "wave units for data in config wave are different from wave units in channel wave (" + WaveUnits(data, DATADIMENSION) + " and " + units[index] + ")")
		endif
	elseif(IsTextWave(sweep))
		ASSERT_TS(index < DimSize(sweep, ROWS), "The index is out of range")
		WAVE channel = ResolveSweepChannel(sweep, index)
		Duplicate/FREE channel, data
		if(index < DimSize(units, ROWS))
			ASSERT_TS(!CmpStr(WaveUnits(data, DATADIMENSION), units[index]), "wave units for data in config wave are different from wave units in channel wave (" + WaveUnits(data, DATADIMENSION) + " and " + units[index] + ")")
		endif
	else
		ASSERT_TS(index < DimSize(sweep, COLS), "The index is out of range")
		MatrixOP/FREE data = col(sweep, index)
		SetScale/P x, DimOffset(sweep, ROWS), DimDelta(sweep, ROWS), WaveUnits(sweep, ROWS), data
		if(index < DimSize(units, ROWS))
			SetScale d, 0, 0, units[index], data
		endif
	endif
	Note/K data, note(sweep)

	return data
End

/// @brief Creates a copy of the sweep data and returns it in wRef format
threadsafe Function/WAVE CopySweepToWRef(WAVE sweep, WAVE config)

	Make/FREE/WAVE/N=(DimSize(config, ROWS)) sweepRef
	sweepRef[] = ExtractOneDimDataFromSweep(config, sweep, p)
	Note/K sweepRef, note(sweep)

	return sweepRef
End

/// @brief Split a sweep wave into one 1D-wave per channel/ttlBit and convert the sweep wave to the current text sweep format.
///        Sweeps already in text format are not split (because that already part of their format).
///        When attempted to split, already existing single channel waves are preserved.
///        The old 2D sweep format is converted automatically to the current text sweep format.
///        If targetDFR is a free DF then only splitting is done.
///        The sweepWave can get invalid and must be reobtained after calling.
///        See @ref GetSweepWave for detailed documentation of the sweep format.
///
/// @param numericalValues numerical labnotebook
/// @param sweep           sweep number
/// @param sweepWave       sweep wave, either old 2D numerical sweep wave, wave ref wave or text sweep wave
/// @param configWave      config wave
/// @param rescale         One of @ref TTLRescalingOptions
/// @param doUpgrade       When this flag is set, then the sweep wave is upgraded to the latest format. When set, createBackup must be set and targetDFR must not be a free DF.
/// @param targetDFR       [optional, defaults to the sweep wave DFR] datafolder where to put the waves, can be a free datafolder
/// @param createBackup    [optional, defaults 1] flag to enable/disable backup creation of single channel sweep waves
threadsafe Function SplitAndUpgradeSweep(WAVE numericalValues, variable sweep, WAVE sweepWave, WAVE configWave, variable rescale, variable doUpgrade, [DFREF targetDFR, variable createBackup])

	variable numRows, i, ttlBits
	variable channelsPresent

	if(ParamIsDefault(targetDFR))
		DFREF targetDFR = GetWavesDataFolderDFR(sweepWave)
	endif

	createBackup = ParamIsDefault(createBackup) ? 1 : !!createBackup
	doUpgrade    = !!doUpgrade

	ASSERT_TS(IsFinite(sweep), "Sweep number must be finite")
	ASSERT_TS(IsValidSweepAndConfig(sweepWave, configWave, configVersion = 0), "Sweep and config waves are not compatible")
	if(doUpgrade)
		ASSERT_TS(!IsFreeDatafolder(targetDFR), "Can not upgrade sweep wave because targetDFR is a free datafolder")
		ASSERT_TS(createBackup == 1, "createBackup == 1 is required if doUpgrade is set.")
	endif

	if(IsTextWave(sweepWave) && !IsFreeDatafolder(targetDFR))
		DFREF parentDF = GetParentDFR(targetDFR)
		if(DataFolderRefsEqual(parentDF, GetWavesDataFolderDFR(sweepWave)))
			return NaN
		endif
	endif

	numRows = DimSize(configWave, ROWS)
	Make/FREE/T/N=(numRows) componentNames = GetSweepComponentWaveName(configWave, p)
	channelsPresent = AreAllSingleSweepWavesPresent(targetDFR, componentNames, backupMustExist = !IsNumericWave(sweepWave))

	// for 2D sweepWaves input assume that existing single channel waves are from input wave
	ASSERT_TS(!(channelsPresent && IsWaveRefWave(sweepWave)), "Can not split sweep from waveRef wave because in targetDFR is already single channel sweep data")

	if(!channelsPresent)
		SplitSweepWave(numericalValues, sweep, sweepWave, configWave, rescale, targetDFR, componentNames, createBackup)
	endif

	if(doUpgrade)
		UpgradeSweepWave(sweepWave, componentNames, targetDFR)
	endif
End

threadsafe static Function/DF GetParentDFR(DFREF dfr)

	string path = GetDataFolder(1, dfr)
	path = RemoveEnding(path, ParseFilePath(0, path, ":", 1, 0) + ":")
	DFREF parent = $path
	ASSERT_TS(DataFolderExistsDFR(parent), "Could not resolve parent of " + GetDataFolder(1, dfr))

	return parent
End

threadsafe static Function AreAllSingleSweepWavesPresent(DFREF targetDFR, WAVE/T componentNames, [variable backupMustExist])

	variable chanMissing, chanPresent
	string wName

	backupMustExist = ParamIsDefault(backupMustExist) ? 1 : !!backupMustExist

	for(wName : componentNames)
		WAVE/Z channel = targetDFR:$wName
		if(WaveExists(channel))
			WAVE/Z channelBak = GetBackupWave_TS(channel)
		else
			WAVE/Z channelBak = $""
		endif

		if(backupMustExist)
			if(WaveExists(channel) && WaveExists(channelBak))
				chanPresent = 1
			elseif(!WaveExists(channel) && !WaveExists(channelBak))
				chanMissing = 1
			else
				ASSERT_TS(0, "Found sweep single channel wave without backup (or vice versa) for sweep in " + GetDataFolder(1, targetDFR) + " channel " + wName)
			endif
		else
			if(WaveExists(channel))
				chanPresent = 1
			else
				chanMissing = 1
			endif
		endif
		ASSERT_TS(chanPresent + chanMissing == 1, "For sweep in " + GetDataFolder(1, targetDFR) + " some single channels are missing, some are present.")
	endfor

	return chanPresent
End

threadsafe static Function SplitSweepWave(WAVE numericalValues, variable sweep, WAVE sweepWave, WAVE configWave, variable rescale, DFREF targetDFR, WAVE/T componentNames, variable createBackup)

	variable numRows, i, ttlBits, dChannelType, dChannelNumber

	WAVE/WAVE sweepRef = CopySweepToWRef(sweepWave, configWave)

	[dChannelType, dChannelNumber] = GetConfigWaveDims(configWave)
	numRows                        = DimSize(configWave, ROWS)
	for(i = 0; i < numRows; i += 1)
		WAVE/Z wv = targetDFR:$componentNames[i]
		KillOrMoveToTrash(wv = wv)
		MoveWave sweepRef[i], targetDFR:$componentNames[i]
		if(createBackup)
			CreateBackupWave(sweepRef[i], forceCreation = 1)
		endif

		if(configWave[i][dChannelType] == XOP_CHANNEL_TYPE_TTL)
			ttlBits = GetTTLBits(numericalValues, sweep, configWave[i][dChannelNumber])
			if(IsFinite(ttlBits))
				SplitTTLWaveIntoComponents(sweepRef[i], ttlBits, targetDFR, componentNames[i] + "_", rescale, createBackup)
			endif
		endif
	endfor
	string/G targetDFR:note = note(sweepWave)
End

threadsafe static Function UpgradeSweepWave(WAVE sweepWave, WAVE/T componentNames, DFREF targetDFR)

	string sweepWaveName, sweepWaveNameBak, tgtDFName, oldSweepName, str
	variable sweepCreationTimeUTC = NaN
	string   modTimeStr           = ""

	tgtDFName = GetDataFolder(0, targetDFR)
	Make/FREE/T/N=(DimSize(componentNames, ROWS)) sweepT
	sweepT[] = tgtDFName + ":" + componentNames[p]
	note/K sweepT, note(sweepWave)
	CopyScales sweepWave, sweepT

	Duplicate/FREE/T sweepT, sweepTBak
	sweepTBak[] = tgtDFName + ":" + componentNames[p] + WAVE_BACKUP_SUFFIX

	sweepWaveName = NameOfWave(sweepWave)
	DFREF sweepWaveDFR = GetParentDFR(targetDFR)
	if(IsNumericWave(sweepWave))
		// we also have to preserve the original modification time
		ASSERT_TS(!CmpStr(WaveUnits(sweepWave, ROWS), "ms"), "Expected ms as wave units")
		modTimeStr            = StringByKeY("MODTIME", WaveInfo(sweepWave, 0))
		sweepCreationTimeUTC  = str2num(modTimeStr) - date2secs(-1, -1, -1)
		sweepCreationTimeUTC -= DimSize(sweepWave, ROWS) * DimDelta(sweepWave, ROWS) * MILLI_TO_ONE

		oldSweepName = UniqueWaveName(sweepWaveDFR, sweepWaveName + "_preUpgrade")
		Duplicate sweepWave, sweepWaveDFR:$oldSweepName
	endif

	WAVE/Z wv = sweepWaveDFR:$sweepWaveName
	KillOrMoveToTrash(wv = wv)
	MoveWave sweepT, sweepWaveDFR:$sweepWaveName

	sweepWaveNameBak = sweepWaveName + WAVE_BACKUP_SUFFIX
	WAVE/Z wv = sweepWaveDFR:$sweepWaveNameBak
	KillOrMoveToTrash(wv = wv)
	MoveWave sweepTBak, sweepWaveDFR:$sweepWaveNameBak

	if(!IsNaN(sweepCreationTimeUTC))
		sprintf str, "%d", sweepCreationTimeUTC
		WAVE wv = sweepWaveDFR:$sweepWaveName
		SetStringInWaveNote(wv, SWEEP_NOTE_KEY_ORIGCREATIONTIME_UTC, str, keySep = ":", listSep = "\r")
		WAVE wv = sweepWaveDFR:$sweepWaveNameBak
		SetStringInWaveNote(wv, SWEEP_NOTE_KEY_ORIGCREATIONTIME_UTC, str, keySep = ":", listSep = "\r")
	endif
End

/// @brief Split TTL data into a single wave for each bit
///
/// This function is only for data from ITC hardware.
///
/// @param data         1D channel data extracted by #ExtractOneDimDataFromSweep
/// @param ttlBits      bit mask of the active TTL channels form e.g. #GetTTLBits
/// @param targetDFR    datafolder where to put the waves, can be a free datafolder
/// @param wavePrefix   prefix of the created wave names
/// @param rescale      One of @ref TTLRescalingOptions. Rescales the data to be in the range [0, 1]
///                     when on, does no rescaling when off.
/// @param createBackup when set then backups are created
///
/// The created waves will be named `TTL_3_3` so the final suffix is the running TTL Bit.
threadsafe static Function SplitTTLWaveIntoComponents(WAVE data, variable ttlBits, DFREF targetDFR, string wavePrefix, variable rescale, variable createBackup)

	variable i, bit

	if(!IsFinite(ttlBits))
		return NaN
	endif

	for(i = 0; i < NUM_ITC_TTL_BITS_PER_RACK; i += 1)

		bit = 2^i
		if(!(ttlBits & bit))
			continue
		endif

		Duplicate data, targetDFR:$(wavePrefix + num2str(i))/WAVE=dest
		if(rescale == TTL_RESCALE_ON)
			MultiThread dest[] = (dest[p] & bit) / bit
		elseif(rescale == TTL_RESCALE_OFF)
			MultiThread dest[] = dest[p] & bit
		else
			ASSERT_TS(0, "Invalid rescale parameter")
		endif
		if(createBackup)
			CreateBackupWave(dest, forceCreation = 1)
		endif
	endfor
End

/// @brief Resolves a single channel of a text sweep wave and returns a reference to it.
///
/// @param sweepWave text sweep wave
/// @param index     index of the channel
/// @param allowFail [optional: default = 0] when set a null wave ref is returned if the channel could not be resolved,
///                  e.g. through a missing single channel wave. On default the function checks for a valid wave and asserts if none was found.
threadsafe Function/WAVE ResolveSweepChannel(WAVE/T sweepWave, variable index, [variable allowFail])

	variable sweepNo
	string singleSweepSub, channelName

	allowFail = ParamIsDefault(allowFail) ? 0 : !!allowFail

	ASSERT_TS(index >= 0 && index < DimSize(sweepWave, ROWS), "Invalid index")
	ASSERT_TS(IsTextWave(sweepWave), "Unsupported sweep wave format")
	DFREF sweepDF = GetWavesDataFolderDFR(sweepWave)
	[singleSweepSub, channelName] = SplitTextSweepElement(sweepWave[index])
	DFREF singleSweepDF = sweepDF:$singleSweepSub
	ASSERT_TS(DataFolderExistsDFR(singleSweepDF), "Can not resolve single sweep DF at " + GetDataFolder(1, sweepDF) + ":" + singleSweepSub)
	WAVE/Z channel = singleSweepDF:$channelName
	if(!allowFail)
		ASSERT_TS(WaveExists(channel), "Can not resolve sweep wave " + channelName + " in " + GetDataFolder(1, singleSweepDF))
	endif

	return channel
End

/// @brief Splits a text sweep wave element into the DF and wave name part
threadsafe Function [string singleChannelDF, string wvName] SplitTextSweepElement(string element)

	ASSERT_TS(ItemsInList(element, ":") == 2, "Invalid sweep location specification in sweep: " + element)
	return [StringFromList(0, element, ":"), StringFromList(1, element, ":")]
End

/// @brief Returns a wave name for a single channel sweep wave. The wave name is based on the channel type and channel number and is
///        built from the XOP_CHANNEL_NAMES in the form DA_0, DA_1, AD_0, AD_1, TTL_0 and so on.
/// @param config       config wave
/// @param channelIndex index in config wave
/// @returns string with a constructed wave name
threadsafe Function/S GetSweepComponentWaveName(WAVE config, variable channelIndex)

	string channelType
	variable channelNumber, dChannelType, dChannelNumber

	[dChannelType, dChannelNumber] = GetConfigWaveDims(config)
	channelType                    = StringFromList(config[channelIndex][dChannelType], XOP_CHANNEL_NAMES)
	ASSERT_TS(!isEmpty(channelType), "empty channel type")
	channelNumber = config[channelIndex][dChannelNumber]
	ASSERT_TS(IsFinite(channelNumber), "non-finite channel number")

	return channelType + "_" + num2istr(channelNumber)
End

/// @brief Update the repurposed sweep time global variable
///
/// Currently only useful for handling mid sweep analysis functions.
Function UpdateLeftOverSweepTime(string device, variable fifoPos)

	string msg

	NVAR repurposedTime = $GetRepurposedSweepTime(device)

	repurposedTime += LeftOverSweepTime(device, fifoPos)

	sprintf msg, "Repurposed time in seconds due to premature sweep stopping: %g\r", repurposedTime
	DEBUGPRINT(msg)
End

Function LeftOverSweepTime(string device, variable fifoPos)

	ASSERT(IsFinite(fifoPos), "Unexpected non-finite fifoPos")

	WAVE DAQDataWave         = GetDAQDataWave(device, DATA_ACQUISITION_MODE)
	NVAR stopCollectionPoint = $GetStopCollectionPoint(device)

	switch(GetHardwareType(device))
		case HARDWARE_ITC_DAC:
			// nothing to do
			break
		case HARDWARE_NI_DAC: // intended drop-through
		case HARDWARE_SUTTER_DAC:
			// we need to use one of the channel waves
			WAVE/WAVE ref         = DAQDataWave
			WAVE      DAQDataWave = ref[0]
			break
		default:
			ASSERT(0, "Invalid hardware type")
	endswitch

	variable lastAcquiredPoint = IndexToScale(DAQDataWave, stopCollectionPoint - fifoPos, ROWS)

	return max(0, lastAcquiredPoint) * MILLI_TO_ONE
End

/// @brief Check if the given wave is a valid DAQDataWave
threadsafe Function IsValidSweepWave(WAVE/Z sweep)

	if(!WaveExists(sweep))
		return 0
	endif

	if(IsWaveRefWave(sweep))
		if(DimSize(sweep, ROWS) > 0)
			WAVE/Z/WAVE sweepWREF = sweep
			WAVE/Z      channel   = sweepWREF[0]
			return WaveExists(channel) && DimSize(channel, ROWS) > 0
		endif
	elseif(IsTextWave(sweep))
		if(DimSize(sweep, ROWS) > 1)
			WAVE/Z channel = ResolveSweepChannel(sweep, 0, allowFail = 1)
			return WaveExists(channel) && DimSize(channel, ROWS) > 0
		endif
	else
		return DimSize(sweep, COLS) > 0 && \
		       DimSize(sweep, ROWS) > 0
	endif

	return 0
End

/// @brief Return the total onset delay of the given sweep from the labnotebook
///
/// UTF_NOINSTRUMENTATION
Function GetTotalOnsetDelay(WAVE numericalValues, variable sweepNo)

	// present since 778969b0 (DC_PlaceDataInITCDataWave: Document all other settings from the DAQ groupbox, 2015-11-26)
	return GetLastSettingIndep(numericalValues, sweepNo, "Delay onset auto", DATA_ACQUISITION_MODE) + \
	       GetLastSettingIndep(numericalValues, sweepNo, "Delay onset user", DATA_ACQUISITION_MODE)
End

Function SplitAndUpgradeSweepGlobal(string device, variable sweepNo)

	[WAVE sweepWave, WAVE configWave] = GetSweepAndConfigWaveFromDevice(device, sweepNo)
	if(!WaveExists(sweepWave))
		return 1
	endif

	DFREF deviceDFR       = GetDeviceDataPath(device)
	DFREF singleSweepDFR  = GetSingleSweepFolder(deviceDFR, sweepNo)
	WAVE  numericalValues = GetLogbookWaves(LBT_LABNOTEBOOK, LBN_NUMERICAL_VALUES, device = device)
	SplitAndUpgradeSweep(numericalValues, sweepNo, sweepWave, configWave, TTL_RESCALE_ON, 1, targetDFR = singleSweepDFR)

	return 0
End

/// @brief Converts a text sweep wave to a free waveRef sweep wave. The waveRef sweep wave contains references to the
///        channels from the text sweep wave, that are local or global waves.
///        See also @ref GetSweepWave docu on "intermediate sweep format".
///        Generally waveRef waves are easier to handle. It is currently used for NWB saving where the sweep channel
///        data needs to be available in a preemptive thread.
Function/WAVE TextSweepToWaveRef(WAVE sweepWave)

	ASSERT(IsTextWave(sweepWave), "Unsupported sweep wave format")
	Make/FREE/WAVE/N=(DimSize(sweepWave, ROWS)) sweepRef
	sweepRef[] = ResolveSweepChannel(sweepWave, p)
	Note sweepRef, note(sweepWave)

	return sweepRef
End

/// @brief Extract the sweep number from a `$something_*` string
threadsafe Function ExtractSweepNumber(string str)

	variable numElements, sweepNo

	str         = RemoveEnding(str, WAVE_BACKUP_SUFFIX)
	numElements = ItemsInList(str, "_")
	ASSERT_TS(numElements > 1, "Invalid string with sweep number")
	sweepNo = NumberFromList(numElements - 1, str, sep = "_")
	ASSERT_TS(IsValidSweepNumber(sweepNo), "Invalid sweep numer extracted")

	return sweepNo
End
