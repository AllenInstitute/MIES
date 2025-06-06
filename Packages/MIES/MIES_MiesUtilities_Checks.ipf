#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3
#pragma rtFunctionErrors = 1

#ifdef AUTOMATED_TESTING
#pragma ModuleName = MIES_MIESUTILS_CHECKS
#endif // AUTOMATED_TESTING

/// @file MIES_MiesUtilities_Checks.ipf
/// @brief This file holds MIES utility functions for checks

/// @brief Check if the given epoch number is valid
Function IsValidEpochNumber(variable epochNo)

	return IsInteger(epochNo) && epochNo >= 0 && epochNo < WB_TOTAL_NUMBER_OF_EPOCHS
End

/// @brief Check if the two waves are valid and compatible
///
/// @param sweep         sweep wave
/// @param config        config wave
/// @param configVersion [optional, defaults to #DAQ_CONFIG_WAVE_VERSION] minimum required version of the config wave
threadsafe Function IsValidSweepAndConfig(WAVE/Z sweep, WAVE/Z config, [variable configVersion])

	if(ParamIsDefault(configVersion))
		configVersion = DAQ_CONFIG_WAVE_VERSION
	endif

	if(!WaveExists(sweep))
		return 0
	endif

	if(IsWaveRefWave(sweep))
		return IsValidConfigWave(config, version = configVersion) && \
		       IsValidSweepWave(sweep) &&                            \
		       DimSize(sweep, ROWS) == DimSize(config, ROWS)
	elseif(IsTextWave(sweep))
		return IsValidConfigWave(config, version = configVersion) && \
		       IsValidSweepWave(sweep) &&                            \
		       DimSize(sweep, ROWS) == DimSize(config, ROWS)
	else
		return IsValidConfigWave(config, version = configVersion) && \
		       IsValidSweepWave(sweep) &&                            \
		       DimSize(sweep, COLS) == DimSize(config, ROWS)
	endif
End

/// @brief Check if the given multiplier is a valid sampling interval multiplier
///
/// UTF_NOINSTRUMENTATION
Function IsValidSamplingMultiplier(variable multiplier)

	return IsFinite(multiplier) && WhichListItem(num2str(multiplier), DAP_GetSamplingMultiplier()) != -1
End

/// @brief Check if the given headstage index is valid
///
/// UTF_NOINSTRUMENTATION
threadsafe Function IsValidHeadstage(variable headstage)

	return IsInteger(headstage) && headstage >= 0 && headstage < NUM_HEADSTAGES
End

/// @brief Check if the given headstage index belongs to an associated channel
///
/// UTF_NOINSTRUMENTATION
threadsafe Function IsAssociatedChannel(variable headstage)

	return IsValidHeadstage(headstage)
End
