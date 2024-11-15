#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_MIESUTILS_GETTER
#endif

/// @file MIES_MiesUtilities_Getter.ipf
/// @brief This file holds MIES utility functions that get names/objects

/// @brief Returns the config wave for a given sweep wave
Function/WAVE GetConfigWave(WAVE sweepWave)

	WAVE/Z/SDFR=GetWavesDataFolderDFR(sweepWave) config = $GetConfigWaveName(ExtractSweepNumber(NameOfWave(sweepWave)))

	return config
End

/// @brief Returns the, possibly non existing, sweep data wave for the given sweep number
///        There are two persistent formats how sweep data is stored.
///
///        The current format is:
///        The sweep wave is a 1D text wave. Each entry contains the relative path to a single channel wave, including the wave name.
///        The reference data folder for the relative path is the data folder where the sweep wave is located.
///        The number of rows of the sweep wave equals the number of columns of the config wave and indexes the channels.
///        Thus, the sweep wave can not be a free wave.
///
///        The deprecated format is:
///        A 2D numeric wave, where the rows are the sample points and the columns the sweep channels.
///        In that format all channels have the same number of points and the same sample interval.
///        The sample interval is saved a ROW DimDelta. The number of columns equals the number of columns of the config waves and
///        indexes the channels.
///
///        Intermediate sweep wave format:
///        Intermediate sweep format is used in some parts of MIES, e.g. NWB saving as it is easier to handle.
///        The sweep wave is a wave reference wave, where each element refers to a channel. It can be a free wave.
///        The number of rows of the sweep wave equals the number of columns of the config wave and indexes the channels.
///        To convert a text sweep wave to a waveRef sweep wave use @ref TextSweepToWaveRef
///        The programmer has to consider if pure references to channels are good enough (TextSweepToWaveRef) or if the channels
///        should be duplicated.
Function/WAVE GetSweepWave(string device, variable sweepNo)

	WAVE/Z/SDFR=GetDeviceDataPath(device) wv = $GetSweepWaveName(sweepNo)

	return wv
End

/// @brief Return the config wave name
Function/S GetConfigWaveName(variable sweepNo)

	return "Config_" + GetSweepWaveName(sweepNo)
End

/// @brief Return the sweep wave name
Function/S GetSweepWaveName(variable sweepNo)

	return "Sweep_" + num2str(sweepNo)
End

/// @brief constructs a fifo name for NI device ADC operations from the deviceID
///
/// UTF_NOINSTRUMENTATION
Function/S GetNIFIFOName(variable deviceID)

	return HARDWARE_NI_ADC_FIFO + num2str(deviceID)
End

/// @brief Return the MIES version with canonical EOLs
Function/S GetMIESVersionAsString()

	SVAR miesVersion = $GetMiesVersion()
	return NormalizeToEOL(miesVersion, "\n")
End

/// @brief Return the current version of the analysis functions
Function GetAnalysisFunctionVersion(variable type)

	switch(type)
		// PSQ
		case PSQ_ACC_RES_SMOKE:
			return PSQ_ACC_RES_SMOKE_VERSION
		case PSQ_CHIRP:
			return PSQ_CHIRP_VERSION
		case PSQ_DA_SCALE:
			return PSQ_DA_SCALE_VERSION
		case PSQ_PIPETTE_BATH:
			return PSQ_PIPETTE_BATH_VERSION
		case PSQ_RAMP:
			return PSQ_RAMP_VERSION
		case PSQ_RHEOBASE:
			return PSQ_RHEOBASE_VERSION
		case PSQ_SQUARE_PULSE:
			return PSQ_SQUARE_PULSE_VERSION
		case PSQ_SEAL_EVALUATION:
			return PSQ_SEAL_EVALUATION_VERSION
		case PSQ_TRUE_REST_VM:
			return PSQ_TRUE_REST_VM_VERSION
		// MSQ
		case MSQ_FAST_RHEO_EST:
			return MSQ_FAST_RHEO_EST_VERSION
		case MSQ_DA_SCALE:
			return MSQ_DA_SCALE_VERSION
		case SC_SPIKE_CONTROL:
			return SC_SPIKE_CONTROL_VERSION
	endswitch

	ASSERT(0, "Invalid type")
End

Function [WAVE sweepWave, WAVE config] GetSweepAndConfigWaveFromDevice(string device, variable sweepNo)

	WAVE/Z sweepWave = GetSweepWave(device, sweepNo)
	if(!WaveExists(sweepWave))
		return [$"", $""]
	endif

	WAVE config = GetConfigWave(sweepWave)

	return [sweepWave, config]
End

Function/S GetWorkLoadName(string workload, string device)

	return workload + "_" + device
End
