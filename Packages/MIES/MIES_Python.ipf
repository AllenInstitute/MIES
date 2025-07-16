#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors = 1

#ifdef AUTOMATED_TESTING
#pragma ModuleName = MIES_PY
#endif // AUTOMATED_TESTING

Function/WAVE PY_CallSpikeExtractor(string device, variable sweepNo, variable channelType, variable channelNumber)

	string code, resultWaveName

	DFREF deviceDFR = GetDeviceDataPath(device)
	DFREF sweepDFR  = GetSingleSweepFolder(deviceDFR, sweepNo)

	WAVE numericalValues = GetLBNumericalValues(device)
	WAVE textualValues   = GetLBTextualValues(device)

	WAVE/Z single_v = GetDAQDataSingleColumnWaveNG(numericalValues, textualValues, sweepNo, sweepDFR, channelType, channelNumber)
	ASSERT(WaveExists(single_v), "Missing wave")
	ASSERT(!cmpstr(WaveUnits(single_v, -1), "mV"), "Unexpected AD Unit")

	DFREF dfr = GetUniqueTempPath()
	Make/N=(DimSize(single_v, ROWS)) dfr:single_t/WAVE=single_t
	single_t[] = DimOffset(single_v, ROWS) + DimDelta(single_v, ROWS) * p

	Python execute="import ipfx_helpers as ih"
	Python execute="import importlib"

	sprintf code, "importlib.reload(ih); result = ih.extract_spikes('%s', '%s', '%s')", GetWavesDataFolder(single_t, 2), GetWavesDataFolder(single_v, 2), GetDataFolder(1, dfr)
	Python execute=code, var={"result", resultWaveName}

	if(!IsEmpty(resultWaveName))
		WAVE/SDFR=dfr result = $resultWaveName
		MakeWaveFree(result)
	endif

	KillOrMoveToTrash(dfr = dfr)

	return result
End
