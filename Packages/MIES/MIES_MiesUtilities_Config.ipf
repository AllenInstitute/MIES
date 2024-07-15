#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_MIESUTILS_CONFIG
#endif

/// @file MIES_MiesUtilities_Config.ipf
/// @brief This file holds MIES utility functions for the config wave

/// @brief Returns the sampling interval of the sweep
/// in microseconds (1e-6s)
threadsafe Function GetSamplingInterval(WAVE config, variable channelType)

	variable i, numChannels, colSamplingInterval, colChannelType, colChannelNumber

	ASSERT_TS(IsValidConfigWave(config, version = 0), "Expected a valid config wave")
	[colChannelType, colChannelNumber] = GetConfigWaveDims(config)
	colSamplingInterval = FindDimLabel(config, COLS, "SamplingInterval")
	colSamplingInterval = colSamplingInterval == -2 ? 2 : colSamplingInterval

	numChannels = DimSize(config, ROWS)
	for(i = 0; i < numChannels; i += 1)
		if(config[i][colChannelType] == channelType)
			return config[i][colSamplingInterval]
		endif
	endfor

	return NaN
End

/// @brief Returns the data offset of the sweep in points
threadsafe Function GetDataOffset(config)
	WAVE config

	ASSERT_TS(IsValidConfigWave(config, version = 1), "Expected a valid config wave")

	Duplicate/D/R=[][4]/FREE config, offsets

	// The data offset is the same for all channels
	ASSERT_TS(IsConstant(offsets, offsets[0]), "Expected constant data offset for all channels")
	return offsets[0]
End

/// @brief Write the given property to the config wave
///
/// @note Please add new properties as required
/// @param config configuration wave
/// @param samplingInterval sampling interval in microseconds (1e-6s)
Function UpdateSweepConfig(config, [samplingInterval])
	WAVE     config
	variable samplingInterval

	ASSERT(IsFinite(samplingInterval), "samplingInterval must be finite")
	config[][2] = samplingInterval
End

/// @brief Return the default name of a electrode
threadsafe Function/S GetDefaultElectrodeName(headstage)
	variable headstage

	ASSERT_TS(headstage >= 0 && headstage < NUM_HEADSTAGES, "Invalid headstage")

	return num2str(headstage)
End

threadsafe Function [variable dChannelType, variable dChannelNumber] GetConfigWaveDims(WAVE config)

	variable dimType, dimNumber

	dimType   = FindDimlabel(config, COLS, "ChannelType")
	dimNumber = FindDimlabel(config, COLS, "ChannelNumber")
	if(dimType == -2)
		// try AB config wave format, @sa GetAnalysisConfigWave
		dimType   = FindDimlabel(config, COLS, "type")
		dimNumber = FindDimlabel(config, COLS, "number")
		if(dimType == -2)
			// from docu of @ref GetDAQConfigWave for unversioned config wave format
			return [0, 1]
		endif
	endif

	return [dimType, dimNumber]
End

/// @brief Check if the given wave is a valid ITCConfigWave
///
/// The optional version parameter allows to check if the wave is at least comaptible with this version.
/// The function assumes that higher versions are compatible with lower versions which is for most callers true.
/// For a special case see AFH_GetChannelUnits.
///
/// @param config wave reference to a ITCConfigWave
///
/// @param version [optional, default=DAQ_CONFIG_WAVE_VERSION], check against a specific version
///                current versions known are 0 (equals NaN), 1, 2, 3
threadsafe Function IsValidConfigWave(config, [version])
	WAVE/Z   config
	variable version

	variable waveVersion

	if(!WaveExists(config))
		return 0
	endif

	if(ParamIsDefault(version))
		version = DAQ_CONFIG_WAVE_VERSION
	endif

	waveVersion = GetWaveVersion(config)

	// we know version NaN, 1, 2 and 3 see GetDAQConfigWave()
	if(version == 3 && waveVersion >= 3)
		return DimSize(config, ROWS) > 0 && DimSize(config, COLS) >= 8
	elseif(version == 2 && waveVersion >= 2)
		return DimSize(config, ROWS) > 0 && DimSize(config, COLS) >= 6
	elseif(version == 1 && waveVersion >= 1)
		return DimSize(config, ROWS) > 0 && DimSize(config, COLS) >= 5
	elseif(version == 0 && (isNaN(waveVersion) || waveVersion >= 1))
		return DimSize(config, ROWS) > 0 && DimSize(config, COLS) >= 4
	endif

	return 0
End

Function GetFirstADCChannelIndex(WAVE config)

	variable col

	col = FindDimlabel(config, COLS, "ChannelType")
	ASSERT(col >= 0, "Could not find ChannelType column in config wave")
	FindValue/RMD=[][col]/V=(XOP_CHANNEL_TYPE_ADC) config
	ASSERT(V_value >= 0, "Could not find any XOP_CHANNEL_TYPE_ADC channel")

	return V_row
End
