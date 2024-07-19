#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma ModuleName=UTILSTEST_MIES_CONFIG

// Missing Tests for:
// GetSamplingInterval
// GetDataOffset
// UpdateSweepConfig
// GetDefaultElectrodeName
// GetConfigWaveDims
// GetFirstADCChannelIndex

/// ITCConfig Wave querying, IsValidConfigWave
/// @{

Function ITCC_WorksLegacy()

	variable type, i
	string actual, expected

	WAVE/SDFR=root:ITCWaves config = ITCChanConfigWave_legacy
	CHECK(IsValidConfigWave(config, version = 0))

	WAVE/T/Z units = AFH_GetChannelUnits(config)
	CHECK_WAVE(units, TEXT_WAVE)
	// we have one TTL channel which does not have a unit
	CHECK_EQUAL_VAR(DimSize(units, ROWS) + 1, DimSize(config, ROWS))
	CHECK_EQUAL_TEXTWAVES(units, {"DA0", "DA1", "DA2", "AD0", "AD1", "AD2"})

	for(i = 0; i < 3; i += 1)
		type     = XOP_CHANNEL_TYPE_DAC
		expected = StringFromList(type, XOP_CHANNEL_NAMES) + num2str(i)
		actual   = AFH_GetChannelUnit(config, i, type)
		CHECK_EQUAL_STR(expected, actual)

		type     = XOP_CHANNEL_TYPE_ADC
		expected = StringFromList(type, XOP_CHANNEL_NAMES) + num2str(i)
		actual   = AFH_GetChannelUnit(config, i, type)
		CHECK_EQUAL_STR(expected, actual)
	endfor

	WAVE/Z DACs = GetDACListFromConfig(config)
	CHECK_WAVE(DACs, NUMERIC_WAVE)
	CHECK_EQUAL_WAVES(DACs, {0, 1, 2}, mode = WAVE_DATA)

	WAVE/Z ADCs = GetADCListFromConfig(config)
	CHECK_WAVE(ADCs, NUMERIC_WAVE)
	CHECK_EQUAL_WAVES(ADCs, {0, 1, 2}, mode = WAVE_DATA)

	WAVE/Z TTLs = GetTTLListFromConfig(config)
	CHECK_WAVE(TTLs, NUMERIC_WAVE)
	CHECK_EQUAL_WAVES(TTLS, {1}, mode = WAVE_DATA)
End

Function ITCC_WorksVersion1()

	variable type, i
	string actual, expected

	WAVE/SDFR=root:ITCWaves config = ITCChanConfigWave_Version1
	CHECK(IsValidConfigWave(config, version = 1))

	WAVE/T/Z units = AFH_GetChannelUnits(config)
	CHECK_WAVE(units, TEXT_WAVE)
	// we have one TTL channel which does not have a unit
	CHECK_EQUAL_VAR(DimSize(units, ROWS) + 1, DimSize(config, ROWS))
	CHECK_EQUAL_TEXTWAVES(units, {"DA0", "DA1", "DA2", "AD0", "AD1", "AD2"})

	for(i = 0; i < 3; i += 1)
		type     = XOP_CHANNEL_TYPE_DAC
		expected = StringFromList(type, XOP_CHANNEL_NAMES) + num2str(i)
		actual   = AFH_GetChannelUnit(config, i, type)
		CHECK_EQUAL_STR(expected, actual)

		type     = XOP_CHANNEL_TYPE_ADC
		expected = StringFromList(type, XOP_CHANNEL_NAMES) + num2str(i)
		actual   = AFH_GetChannelUnit(config, i, type)
		CHECK_EQUAL_STR(expected, actual)
	endfor

	WAVE/Z DACs = GetDACListFromConfig(config)
	CHECK_WAVE(DACs, NUMERIC_WAVE)
	CHECK_EQUAL_WAVES(DACs, {0, 1, 2}, mode = WAVE_DATA)

	WAVE/Z ADCs = GetADCListFromConfig(config)
	CHECK_WAVE(ADCs, NUMERIC_WAVE)
	CHECK_EQUAL_WAVES(ADCs, {0, 1, 2}, mode = WAVE_DATA)

	WAVE/Z TTLs = GetTTLListFromConfig(config)
	CHECK_WAVE(TTLs, NUMERIC_WAVE)
	CHECK_EQUAL_WAVES(TTLS, {1}, mode = WAVE_DATA)
End

Function ITCC_WorksVersion2()

	variable type, i
	string actual, expected

	WAVE/SDFR=root:ITCWaves config = ITCChanConfigWave_Version2
	CHECK(IsValidConfigWave(config, version = 2))

	WAVE/T/Z units = AFH_GetChannelUnits(config)
	CHECK(WaveExists(units))
	// we have one TTL channel which does not have a unit
	CHECK_EQUAL_VAR(DimSize(units, ROWS) + 1, DimSize(config, ROWS))
	CHECK_EQUAL_TEXTWAVES(units, {"DA0", "DA1", "DA2", "AD0", "AD1", "AD2"})

	for(i = 0; i < 3; i += 1)
		type     = XOP_CHANNEL_TYPE_DAC
		expected = StringFromList(type, XOP_CHANNEL_NAMES) + num2str(i)
		actual   = AFH_GetChannelUnit(config, i, type)
		CHECK_EQUAL_STR(expected, actual)

		type     = XOP_CHANNEL_TYPE_ADC
		expected = StringFromList(type, XOP_CHANNEL_NAMES) + num2str(i)
		actual   = AFH_GetChannelUnit(config, i, type)
		CHECK_EQUAL_STR(expected, actual)
	endfor

	WAVE/Z DACs = GetDACListFromConfig(config)
	CHECK_WAVE(DACs, NUMERIC_WAVE)
	CHECK_EQUAL_WAVES(DACs, {0, 1, 2}, mode = WAVE_DATA)

	WAVE/Z ADCs = GetADCListFromConfig(config)
	CHECK_WAVE(ADCs, NUMERIC_WAVE)
	CHECK_EQUAL_WAVES(ADCs, {0, 1, 2}, mode = WAVE_DATA)

	WAVE/Z TTLs = GetTTLListFromConfig(config)
	CHECK_WAVE(TTLs, NUMERIC_WAVE)
	CHECK_EQUAL_WAVES(TTLS, {1}, mode = WAVE_DATA)

	WAVE/Z DACmode = GetDACTypesFromConfig(config)
	CHECK_WAVE(DACmode, NUMERIC_WAVE)
	CHECK_EQUAL_WAVES(DACmode, {1, 2, 2}, mode = WAVE_DATA)

	WAVE/Z ADCmode = GetADCTypesFromConfig(config)
	CHECK_WAVE(ADCmode, NUMERIC_WAVE)
	CHECK_EQUAL_WAVES(ADCmode, {2, 1, 2}, mode = WAVE_DATA)
End

/// @}
