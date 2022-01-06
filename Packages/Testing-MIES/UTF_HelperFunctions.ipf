#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma ModuleName=TestHelperFunctions

/// @file UTF_HelperFunctions.ipf
/// @brief This file holds helper functions for the tests

Function/S PrependExperimentFolder_IGNORE(filename)
	string filename

	PathInfo home
	CHECK(V_flag)

	return S_path + filename
End

/// Kill all left-over windows and remove the trash
Function AdditionalExperimentCleanup()

	string win, list, name
	variable i, numWindows

	list = WinList("*", ";", "WIN:67") // Panels, Graphs and tables

	numWindows = ItemsInList(list)
	for(i = 0; i < numWindows; i += 1)
		win = StringFromList(i, list)

		if(!cmpstr(win, "BW_MiesBackgroundWatchPanel") || !cmpstr(win, "DP_DebugPanel"))
			continue
		endif

		KillWindow $win
	endfor

	DFREF dfr = GetDebugPanelFolder()
	name = GetDataFolder(0, dfr)
	MoveDataFolder/O=1 dfr, root:

	CloseNWBFile()
	HDF5CloseFile/A/Z 0

	KillOrMoveToTrash(dfr=root:MIES)

	NewDataFolder root:MIES
	MoveDataFolder root:$name, root:MIES

	// currently superfluous as we remove root:MIES above
	// but might be needed in the future and helps in understanding the code
	CA_FlushCache()

	NVAR interactiveMode = $GetInteractiveMode()
	interactiveMode = 0

	NVAR bugCount = $GetBugCount()
	KillVariables bugCount
End

Function WaitForPubSubHeartbeat()
	variable i, foundHeart
	string msg, filter

	// wait until we get the first heartbeat
	for(i = 0; i < 200; i += 1)
		msg = zeromq_sub_recv(filter)
		if(!cmpstr(filter, ZEROMQ_HEARTBEAT))
			PASS()
			return NaN
		endif

		Sleep/S 0.1
	endfor

	FAIL()
End

Function AdjustAnalysisParamsForPSQ(string device, string stimset)

	variable samplingFrequency

	switch(GetHardwareType(device))
		case HARDWARE_ITC_DAC:
			samplingFrequency = 50
			break
		case HARDWARE_NI_DAC:
			samplingFrequency = 125
			break
		default:
			ASSERT(0, "Unknown hardware")
	endswitch

	AFH_AddAnalysisParameter(stimset, "SamplingMultiplier", var = 4)
	AFH_AddAnalysisParameter(stimset, "SamplingFrequency", var = samplingFrequency)
End

Function DoInstrumentation()
#if IgorVersion() >= 9.0
	variable instru = str2numSafe(GetEnvironmentVariable("BAMBOO_INSTRUMENT_TESTS")) == 1           \
	                  || !cmpstr(GetEnvironmentVariable("bamboo_repository_git_branch"), "main")

	return instru
#else
	// no support in IP8
	return 0
#endif
End

Function [string key, string keyTxt] PrepareLBN_IGNORE(string device)

	variable sweepNo

	key    = "some key"
	keyTxt = "other key"

	WAVE numericalValues = GetLBNumericalValues(device)
	WAVE textualValues   = GetLBTextualValues(device)

	// prepare the LBN
	Make/FREE/N=(1, 1, LABNOTEBOOK_LAYER_COUNT) values, valuesDAC, valuesADC
	Make/T/FREE/N=(1, 1, LABNOTEBOOK_LAYER_COUNT) valuesTxt
	Make/T/FREE/N=(1, 1, 1) keys

	sweepNo = 0

	// HS 0: DAC 2 and ADC 6
	// HS 1: DAC 3 and ADC 7
	valuesDAC[]  = NaN
	valuesDAC[0][0][0] = 2
	valuesDAC[0][0][1] = 3
	keys[] = "DAC"
	ED_AddEntriesToLabnotebook(valuesDAC, keys, sweepNo, device, DATA_ACQUISITION_MODE)

	valuesADC[]  = NaN
	valuesADC[0][0][0] = 6
	valuesADC[0][0][1] = 7
	keys[] = "ADC"
	ED_AddEntriesToLabnotebook(valuesADC, keys, sweepNo, device, DATA_ACQUISITION_MODE)

	values[]  = 0
	values[0][0][0] = 1
	values[0][0][1] = 1
	keys[] = "Headstage Active"
	ED_AddEntriesToLabnotebook(valuesDAC, keys, sweepNo, device, DATA_ACQUISITION_MODE)

	// numerical entries

	// DAC 4: unassoc (old)
	values[] = NaN
	values[0][0][INDEP_HEADSTAGE] = 123
	keys[] = CreateLBNUnassocKey(key, 4, NaN) // old format does not include the channelType
	ED_AddEntriesToLabnotebook(values, keys, sweepNo, device, DATA_ACQUISITION_MODE)

	// ADC 8: unassoc (old)
	values[] = NaN
	values[0][0][INDEP_HEADSTAGE] = 789
	keys[] = CreateLBNUnassocKey(key, 8, NaN) // old format does not include the channelType
	ED_AddEntriesToLabnotebook(values, keys, sweepNo, device, DATA_ACQUISITION_MODE)

	// associated
	values[] = NaN
	values[0][0][0] = 131415
	values[0][0][1] = 161718
	keys[] = key
	ED_AddEntriesToLabnotebook(values, keys, sweepNo, device, DATA_ACQUISITION_MODE)

	values[] = NaN
	values[0][0][0] = I_CLAMP_MODE
	keys[] = CLAMPMODE_ENTRY_KEY
	ED_AddEntriesToLabnotebook(values, keys, sweepNo, device, DATA_ACQUISITION_MODE)

	// textual entries

	// DAC 4: unassoc (old)
	valuesTxt[] = ""
	valuesTxt[0][0][INDEP_HEADSTAGE] = "123"
	keys[] = CreateLBNUnassocKey(keyTxt, 4, NaN) // old format does not include the channelType
	ED_AddEntriesToLabnotebook(valuesTxt, keys, sweepNo, device, DATA_ACQUISITION_MODE)

	// ADC 8: unassoc (old)
	valuesTxt[] = ""
	valuesTxt[0][0][INDEP_HEADSTAGE] = "789"
	keys[] = CreateLBNUnassocKey(keyTxt, 8, NaN) // old format does not include the channelType
	ED_AddEntriesToLabnotebook(valuesTxt, keys, sweepNo, device, DATA_ACQUISITION_MODE)

	// associated
	valuesTxt[] = ""
	valuesTxt[0][0][0] = "131415"
	valuesTxt[0][0][1] = "161718"
	keys[] = keyTxt
	ED_AddEntriesToLabnotebook(valuesTxt, keys, sweepNo, device, DATA_ACQUISITION_MODE)

	sweepNo = 1

	valuesDAC[]  = NaN
	valuesDAC[0][0][0] = 2
	valuesDAC[0][0][1] = 3
	keys[] = "DAC"
	ED_AddEntriesToLabnotebook(valuesDAC, keys, sweepNo, device, DATA_ACQUISITION_MODE)

	valuesADC[]  = NaN
	valuesADC[0][0][0] = 6
	valuesADC[0][0][1] = 7
	keys[] = "ADC"
	ED_AddEntriesToLabnotebook(valuesADC, keys, sweepNo, device, DATA_ACQUISITION_MODE)

	values[]  = 0
	values[0][0][0] = 1
	values[0][0][1] = 1
	keys[] = "Headstage Active"
	ED_AddEntriesToLabnotebook(valuesDAC, keys, sweepNo, device, DATA_ACQUISITION_MODE)

	// numerical entries

	// DAC 5: unassoc (new)
	values[] = NaN
	values[0][0][INDEP_HEADSTAGE] = 456
	keys[] = CreateLBNUnassocKey(key, 5, XOP_CHANNEL_TYPE_DAC)
	ED_AddEntriesToLabnotebook(values, keys, sweepNo, device, DATA_ACQUISITION_MODE)

	// ADC 9: unassoc (new)
	values[] = NaN
	values[0][0][INDEP_HEADSTAGE] = 101112
	keys[] = CreateLBNUnassocKey(key, 9, XOP_CHANNEL_TYPE_ADC)
	ED_AddEntriesToLabnotebook(values, keys, sweepNo, device, DATA_ACQUISITION_MODE)

	// associated
	values[] = NaN
	values[0][0][0] = 192021
	values[0][0][1] = 222324
	keys[] = key
	ED_AddEntriesToLabnotebook(values, keys, sweepNo, device, DATA_ACQUISITION_MODE)

	values[] = NaN
	values[0][0][0] = V_CLAMP_MODE
	keys[] = CLAMPMODE_ENTRY_KEY
	ED_AddEntriesToLabnotebook(values, keys, sweepNo, device, DATA_ACQUISITION_MODE)

	// textual entries

	// DAC 5: unassoc (new)
	valuesTxt[] = ""
	valuesTxt[0][0][INDEP_HEADSTAGE] = "456"
	keys[]= CreateLBNUnassocKey(keyTxt, 5, XOP_CHANNEL_TYPE_DAC)
	ED_AddEntriesToLabnotebook(valuesTxt, keys, sweepNo, device, DATA_ACQUISITION_MODE)

	// ADC 9: unassoc (new)
	valuesTxT[] = ""
	valuesTxT[0][0][INDEP_HEADSTAGE] = "101112"
	keys[] = CreateLBNUnassocKey(keyTxt, 9, XOP_CHANNEL_TYPE_ADC)
	ED_AddEntriesToLabnotebook(valuesTxt, keys, sweepNo, device, DATA_ACQUISITION_MODE)

	// associated
	valuesTxT[] = ""
	valuesTxT[0][0][0] = "192021"
	valuesTxT[0][0][1] = "222324"
	keys[] = keyTxt
	ED_AddEntriesToLabnotebook(valuesTxt, keys, sweepNo, device, DATA_ACQUISITION_MODE)

	sweepNo = 2

	valuesDAC[]  = NaN
	valuesDAC[0][0][0] = 2
	valuesDAC[0][0][1] = 3
	keys[] = "DAC"
	ED_AddEntriesToLabnotebook(valuesDAC, keys, sweepNo, device, DATA_ACQUISITION_MODE)

	valuesADC[]  = NaN
	valuesADC[0][0][0] = 6
	valuesADC[0][0][1] = 7
	keys[] = "ADC"
	ED_AddEntriesToLabnotebook(valuesADC, keys, sweepNo, device, DATA_ACQUISITION_MODE)

	values[]  = 0
	values[0][0][0] = 1
	values[0][0][1] = 1
	keys[] = "Headstage Active"
	ED_AddEntriesToLabnotebook(valuesDAC, keys, sweepNo, device, DATA_ACQUISITION_MODE)

	values[] = NaN
	values[0][0][0] = I_EQUAL_ZERO_MODE
	keys[] = CLAMPMODE_ENTRY_KEY
	ED_AddEntriesToLabnotebook(values, keys, sweepNo, device, DATA_ACQUISITION_MODE)

	// indep headstage
	values[] = NaN
	values[0][0][INDEP_HEADSTAGE] = 252627
	keys[] = key
	ED_AddEntriesToLabnotebook(values, keys, sweepNo, device, DATA_ACQUISITION_MODE)

	valuesTxt[] = ""
	valuesTxt[0][0][INDEP_HEADSTAGE] = "252627"
	keys[] = keyTxt
	ED_AddEntriesToLabnotebook(valuesTxt, keys, sweepNo, device, DATA_ACQUISITION_MODE)

	return [key, keyTxt]
End
