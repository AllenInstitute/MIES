#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_MIESUTILS_RECREATION
#endif // AUTOMATED_TESTING

/// @file MIES_MiesUtilities_Recreation.ipf
/// @brief This file holds MIES utility functions for sweep and config wave recreation

/// @brief Tries to find deleted sweep and config waves which are still present due to 1D waves from databrowser backups or
///        labnotebook entries
///
/// The result is placed in `root:reconstructed` which is overwritten.
///
/// For reconstructing single sweep or config waves, see RecreateSweepWaveFromBackupAndLBN() and
/// RecreateConfigWaveFromLBN().
///
/// Example invocation:
/// - RecreateMissingSweepAndConfigWaves("ITC18USB_DEV_0", root:MIES:HardwareDevices:ITC18USB:Device0:Data:)
/// - Inspect the results in `root:reconstructed`
/// - If you are satisfied, move the waves from root:reconstructed into e.g. `root:MIES:HardwareDevices:ITC18USB:Device0:Data:`
/// - Proceed with the data as usual
///
/// In case the routine throws an assertion, please open an issue so that we can investigate.
Function RecreateMissingSweepAndConfigWaves(string device, DFREF deviceDataDFR)

	printf "Trying to resurrect missing sweeps from device %s\r", device

	variable i, numEntries, sweepNo, samplingInterval, configVersion
	string path

	WAVE numericalKeys = GetLBTextualKeys(device)
	WAVE textualKeys   = GetLBNumericalKeys(device)

	// now the labnotebooks are upgraded to the latest version
	WAVE numericalValues = GetLBNumericalValues(device)
	WAVE textualValues   = GetLBTextualValues(device)

	WAVE/Z sweepsFromNum  = GetSweepsWithSetting(numericalValues, "SweepNum")
	WAVE/Z sweepsFromText = GetSweepsWithSetting(textualValues, "SweepNum")

	// consistency check
	ASSERT(WaveExists(sweepsFromNum) && WaveExists(sweepsFromText) && EqualWaves(sweepsFromNum, sweepsFromText, EQWAVES_DATA), "Unexpected numerical/textual LBN entries")

	WAVE sweeps = sweepsFromNum

	Duplicate/FREE sweeps, missingSweep, missingConfig

	missingSweep[]  = 1
	missingConfig[] = 1

	numEntries = DimSize(sweeps, ROWS)
	for(i = 0; i < numEntries; i += 1)
		sweepNo = sweepsFromNum[i]

		WAVE/Z/SDFR=deviceDataDFR sweepWave  = $GetSweepWaveName(sweepNo)
		WAVE/Z/SDFR=deviceDataDFR configWave = $GetConfigWaveName(sweepNo)

		if(WaveExists(sweepWave) && WaveExists(configWave))
			missingSweep[i]  = 0
			missingConfig[i] = 0
			continue
		endif

		if(WaveExists(sweepWave))
			missingSweep[i] = 0
		else
			printf "Sweep %d is missing its sweep wave\r", sweepNo
		endif

		if(WaveExists(configWave))
			missingConfig[i] = 0
		else
			printf "Sweep %d is missing its config wave\r", sweepNo
		endif
	endfor

	DFREF dest = createDFWithAllParents("root:reconstructed")
	MoveToTrash(dfr = dest)
	DFREF dest = createDFWithAllParents("root:reconstructed")

	// now try to reconstruct the sweep and config waves from the X_XXXX folders
	for(i = 0; i < numEntries; i += 1)
		if(!missingSweep[i] && !missingConfig[i])
			continue
		endif

		sweepNo = sweepsFromNum[i]

		printf "Trying to reconstruct sweep %d\r", sweepNo

		if(missingSweep[i])
			WAVE/Z sweepWave = RecreateSweepWaveFromBackupAndLBN(numericalValues, textualValues, sweepNo, deviceDataDFR)

			if(!WaveExists(sweepWave))
				printf "Could not reconstruct sweep\r"
				continue
			endif
		else
			WAVE/Z/SDFR=deviceDataDFR sweepWave = $GetSweepWaveName(sweepNo)
		endif

		if(missingConfig[i])
			WAVE configWave = RecreateConfigWaveFromLBN(device, numericalValues, textualValues, sweepNo)
		else
			WAVE/Z/SDFR=deviceDataDFR configWave = $GetConfigWaveName(sweepNo)
		endif

		if(WaveExists(sweepWave) && WaveExists(configWave))
			configVersion = GetWaveVersion(configWave)
			configVersion = IsNaN(configVersion) ? 0 : configVersion
			ASSERT(IsValidSweepAndConfig(sweepWave, configWave, configVersion = configVersion), "Recreation created incompatible sweep and config waves")
		endif

		if(WaveExists(configWave))
			MoveWave configWave, dest:$GetConfigWaveName(sweepNo)
		endif

		if(WaveExists(sweepWave))
			MoveWave sweepWave, dest:$GetSweepWaveName(sweepNo)
		endif

		DFREF singleSweepDFR = GetSingleSweepFolder(dest, sweepNo)
		SplitAndUpgradeSweep(numericalValues, sweepNo, sweepWave, configWave, TTL_RESCALE_OFF, 1, targetDFR = singleSweepDFR)

		printf "Reconstructed successfully.\r"
	endfor
End

/// @brief Try recreating a WaveRef sweep wave from its databrowser backup.
///        For a text sweep wave, call SplitSweepIntoComponents afterwards with a target DF.
///
/// @return $"" if reconstruction failed or a free wave with the sweep data and correct metadata
Function/WAVE RecreateSweepWaveFromBackupAndLBN(WAVE numericalValues, WAVE/T textualValues, variable sweepNo, DFREF deviceDataDFR)

	string path
	variable samplingInterval, numChannels, channelOffset

	path = GetSingleSweepFolderAsString(deviceDataDFR, sweepNo)

	if(!DataFolderExists(path))
		return $""
	endif

	DFREF singleSweepFolder = $path

	[WAVE DAChans, WAVE/WAVE DAWaves]   = GetSingleSweepWaves(singleSweepFolder, XOP_CHANNEL_TYPE_DAC)
	[WAVE ADChans, WAVE/WAVE ADWaves]   = GetSingleSweepWaves(singleSweepFolder, XOP_CHANNEL_TYPE_ADC)
	[WAVE TTLChans, WAVE/WAVE TTLWaves] = GetSingleSweepWaves(singleSweepFolder, XOP_CHANNEL_TYPE_TTL)

	// check that we have found all 1D waves of one sweep
	WAVE DAFromLBN      = GetActiveChannels(numericalValues, textualValues, sweepNo, XOP_CHANNEL_TYPE_DAC)
	WAVE DAFromLBNWoNaN = ZapNaNs(DAFromLBN)

	WAVE ADFromLBN      = GetActiveChannels(numericalValues, textualValues, sweepNo, XOP_CHANNEL_TYPE_ADC)
	WAVE ADFromLBNWoNaN = ZapNaNs(ADFromLBN)

	WAVE/Z TTLFromLBN = GetActiveChannels(numericalValues, textualValues, sweepNo, XOP_CHANNEL_TYPE_TTL, TTLmode = TTL_HARDWARE_CHANNEL)

	if(WaveExists(TTLFromLBN))
		WAVE/Z TTLFromLBNWoNaN = ZapNaNs(TTLFromLBN)
	endif

	if(!WaveExists(TTLFromLBNWoNaN))
		Make/FREE/N=0 TTLFromLBNWoNaN
	endif

	if(DimSize(DAFromLBNWoNaN, ROWS) != DimSize(DAChans, ROWS)     \
	   || DimSize(ADFromLBNWoNaN, ROWS) != DimSize(ADChans, ROWS)  \
	   || DimSize(TTLFromLBNWoNaN, ROWS) != DimSize(TTLChans, ROWS))
		return $""
	endif

	numChannels = DimSize(DAChans, ROWS) + DimSize(ADChans, ROWS) + DimSize(TTLChans, ROWS)
	Make/FREE/WAVE/N=(numChannels) sweepWave

	// Add DA/AD data with increasing channel numbers
	channelOffset = AddToSweepWave(DAWaves, DAChans, sweepWave, 0)
	channelOffset = AddToSweepWave(ADWaves, ADChans, sweepWave, channelOffset)
	channelOffset = AddToSweepWave(TTLWaves, TTLChans, sweepWave, channelOffset)
	ASSERT(channelOffset == numChannels, "channel filling mismatch on recreation of sweep")

	// Attach the wave note
	SVAR txt = singleSweepFolder:note
	Note/K sweepWave, txt

	ASSERT(IsValidSweepWave(sweepWave), "Recreation created an invalid wave")

	return sweepWave
End

/// @brief Try recreating the DAQ config wave from labnotebook entries
///
/// @return `$""` if recreation failed or a free wave on success.
Function/WAVE RecreateConfigWaveFromLBN(string device, WAVE numericalValues, WAVE textualValues, variable sweepNo)

	// ensure we start with a fresh config wave
	WAVE configWave = GetDAQConfigWave(device)
	MoveToTrash(wv = configWave)

	WAVE configWave = GetDAQConfigWave(device)
	Redimension/N=(0, -1) configWave

	ASSERT(GetWaveVersion(configWave) == 3, "Reconstruction might need adaptation for new config wave version")

	AddChannelPropertiesFromLBN(numericalValues, textualValues, sweepNo, configWave, XOP_CHANNEL_TYPE_DAC)
	AddChannelPropertiesFromLBN(numericalValues, textualValues, sweepNo, configWave, XOP_CHANNEL_TYPE_ADC)
	AddChannelPropertiesFromLBN(numericalValues, textualValues, sweepNo, configWave, XOP_CHANNEL_TYPE_TTL)

	configWave[][%SamplingInterval] = GetSamplingIntervalFromLBN(numericalValues, sweepNo, configWave[p][%ChannelType]) * MILLI_TO_MICRO

	// always 0, see DC_PlaceDataInDAQConfigWave
	configWave[][%DecimationMode] = 0

	// nearly always 0, except for PSQ_Ramp, use -1 to be really honest
	// as we don't really know the used offset anymore
	configWave[][%Offset] = -1

	AddDAQChannelTypeFromLBN(numericalValues, textualValues, sweepNo, configWave)
	AddHeadstageFromLBN(numericalValues, sweepNo, configWave)
	AddClampModeFromLBN(numericalValues, sweepNo, configWave)
	AddChannelUnitFromLBN(numericalValues, textualValues, sweepNo, configWave)

	ASSERT(IsValidSweepWave(configWave), "Recreation created an invalid wave")

	return configWave
End

/// @brief Return waves with the channel numbers and references to 1D waves from the `X_XXXX` folders
static Function [WAVE channelNumbers, WAVE/WAVE existingWaves] GetSingleSweepWaves(DFREF singleSweepFolder, variable channelType)

	variable numEntries, i, channelNumber, size

	WAVE/WAVE waves = GetDAQDataSingleColumnWaves(singleSweepFolder, channelType)

	Make/FREE/N=0 channelNumbers
	Make/FREE/N=0/WAVE existingWaves

	numEntries = DimSize(waves, ROWS)
	for(i = 0; i < numEntries; i += 1)
		if(!WaveExists(waves[i]))
			continue
		endif

		channelNumber = NumberFromList(1, NameOfWave(waves[i]), sep = "_")

		size = DimSize(channelNumbers, ROWS)
		Redimension/N=(size + 1) channelNumbers, existingWaves

		channelNumbers[size] = channelNumber
		existingWaves[size]  = waves[i]
	endfor

	return [channelNumbers, existingWaves]
End

/// @brief Add the returned 1D waves from GetSingleSweepWaves() into sweepWave. sweepWave must be WaveRef wave.
///        The size of sweepWave is increased if required.
/// @returns index of last row filled
static Function AddToSweepWave(WAVE/WAVE channelWaves, WAVE channelNumbers, WAVE/WAVE sweepWave, variable indexOffset)

	variable i, numEntries, requiredSize

	// sort channelNumbers and channelWaves ascending so that we start with the smallest channel numbers first
	Sort channelNumbers, channelNumbers, channelWaves

	numEntries   = DimSize(channelWaves, ROWS)
	requiredSize = indexOffset + numEntries
	if(DimSize(sweepWave, ROWS) < requiredSize)
		Redimension/N=(requiredSize) sweepWave
	endif

	for(i = 0; i < numEntries; i += 1)
		sweepWave[indexOffset + i] = channelWaves[i]
	endfor

	return requiredSize
End

/// @brief Set `ChannelNumber` and `ChannelType` in configWave
static Function AddChannelPropertiesFromLBN(WAVE numericalValues, WAVE textualValues, variable sweepNo, WAVE configWave, variable channelType)

	variable i, numEntries, offset

	WAVE/Z channelLBN = GetActiveChannels(numericalValues, textualValues, sweepNo, channelType, TTLmode = TTL_HARDWARE_CHANNEL)

	if(!WaveExists(channelLBN))
		// nothing to do
		return NaN
	endif

	WAVE/Z channelLBNWoNaN = ZapNaNs(channelLBN)

	if(!WaveExists(channelLBNWoNaN))
		// nothing to do
		return NaN
	endif

	// sort channelNumbers ascending so that we start with the smallest channel numbers first
	Sort channelLBNWoNaN, channelLBNWoNaN

	numEntries = DimSize(channelLBNWoNaN, ROWS)

	offset = DimSize(configWave, ROWS)
	Redimension/N=(offset + numEntries, -1) configWave

	for(i = 0; i < numEntries; i += 1)
		configWave[offset + i][%ChannelNumber] = channelLBNWoNaN[i]
		configWave[offset + i][%ChannelType]   = channelType
	endfor
End

/// @brief Return the sampling interval [ms] rounded to microseconds
static Function GetSamplingIntervalFromLBN(WAVE numericalValues, variable sweepNo, variable channelType)

	variable samplingInterval
	string   key

	switch(channelType)
		case XOP_CHANNEL_TYPE_DAC:
			key = "Sampling interval DA"
			break
		case XOP_CHANNEL_TYPE_ADC:
			key = "Sampling interval AD"
			break
		case XOP_CHANNEL_TYPE_TTL:
			key = "Sampling interval TTL"
			break
		default:
			ASSERT(0, "Invalid Channel Type")
	endswitch

	samplingInterval = GetLastSettingIndep(numericalValues, sweepNo, key, DATA_ACQUISITION_MODE)

	// round to full microseconds as that is stored in GetDAQConfigWave()
	return round(samplingInterval * 1000) / 1000 // NOLINT
End

/// @brief Set `DAQChannelType` in configWave
static Function AddDAQChannelTypeFromLBN(WAVE numericalValues, WAVE textualValues, variable sweepNo, WAVE configWave)

	variable i, numEntries, headstage, channelType, index

	Make/FREE validChannelTypes = {DAQ_CHANNEL_TYPE_DAQ, DAQ_CHANNEL_TYPE_TP, DAQ_CHANNEL_TYPE_UNKOWN}

	numEntries = DimSize(configWave, ROWS)
	for(i = 0; i < numEntries; i += 1)
		switch(configWave[i][%ChannelType])
			case XOP_CHANNEL_TYPE_DAC:
				[WAVE setting, index] = GetLastSettingChannel(numericalValues, $"", sweepNo, "DA ChannelType", configWave[i][%ChannelNumber], configWave[i][%ChannelType], DATA_ACQUISITION_MODE)
				channelType           = setting[index]
				break
			case XOP_CHANNEL_TYPE_ADC:
				[WAVE setting, index] = GetLastSettingChannel(numericalValues, $"", sweepNo, "AD ChannelType", configWave[i][%ChannelNumber], configWave[i][%ChannelType], DATA_ACQUISITION_MODE)
				channelType           = setting[index]
				break
			case XOP_CHANNEL_TYPE_TTL:
				channelType = DAQ_CHANNEL_TYPE_DAQ
				break
			default:
				ASSERT(0, "Unsupported channel type")
				break
		endswitch

		ASSERT(IsFinite(GetRowIndex(validChannelTypes, val = channelType)), "Invalid channel type")

		configWave[i][%DAQChannelType] = channelType
	endfor
End

/// @brief Set `Headstage` in configWave
static Function AddHeadstageFromLBN(WAVE numericalValues, variable sweepNo, WAVE configWave)

	variable i, numEntries, headstage, index

	numEntries = DimSize(configWave, ROWS)
	for(i = 0; i < numEntries; i += 1)
		[WAVE setting, index] = GetLastSettingChannel(numericalValues, $"", sweepNo, "Headstage Active", configWave[i][%ChannelNumber], configWave[i][%ChannelType], DATA_ACQUISITION_MODE)
		if(WaveExists(setting))
			configWave[i][%HEADSTAGE] = (setting[index] == 1) ? index : NaN
		else
			configWave[i][%HEADSTAGE] = NaN
		endif
	endfor
End

/// @brief Set `ClampMode` in configWave
static Function AddClampModeFromLBN(WAVE numericalValues, variable sweepNo, WAVE configWave)

	variable i, numEntries, clampMode, index

	numEntries = DimSize(configWave, ROWS)
	for(i = 0; i < numEntries; i += 1)
		[WAVE setting, index] = GetLastSettingChannel(numericalValues, $"", sweepNo, CLAMPMODE_ENTRY_KEY, configWave[i][%ChannelNumber], configWave[i][%ChannelType], DATA_ACQUISITION_MODE)
		if(WaveExists(setting))
			configWave[i][%CLAMPMODE] = setting[index]
		else
			configWave[i][%CLAMPMODE] = NaN
		endif
	endfor
End

/// @brief Add wave note entry #CHANNEL_UNIT_KEY for the used channel units
static Function AddChannelUnitFromLBN(WAVE numericalValues, WAVE/T textualValues, variable sweepNo, WAVE configWave)

	variable i, numEntries, index
	string key
	string unitList = ""

	numEntries = DimSize(configWave, ROWS)
	for(i = 0; i < numEntries; i += 1)

		if(configWave[i][%ChannelType] == XOP_CHANNEL_TYPE_TTL)
			// done
			break
		endif

		key                   = StringFromList(configWave[i][%ChannelType], XOP_CHANNEL_NAMES) + " Unit"
		[WAVE setting, index] = GetLastSettingChannel(numericalValues, textualValues, sweepNo, key, configWave[i][%ChannelNumber], configWave[i][%ChannelType], DATA_ACQUISITION_MODE)

		WAVE/T settingText = setting
		unitList = AddListItem(settingText[index], unitList, ",", Inf)
	endfor

	AddEntryIntoWaveNoteAsList(configWave, CHANNEL_UNIT_KEY, str = unitList, replaceEntry = 1)
End
