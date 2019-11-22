#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

 // This file does not hold test suites
Function NoTestSuite()
	FAIL()
End

Function TestHistory(fileID)
	variable fileID

	WAVE/Z/T history = IPNWB#H5_LoadDataSet(fileID, "/general/history")
	CHECK_WAVE(history, TEXT_WAVE)
	CHECK(DimSize(history, ROWS) > 0)
end

Function TestLabnotebooks(fileID, device)
	variable fileID
	string device

	string lbnDevices, prefix

	WAVE numericalValues = GetLBNumericalValues(device)
	WAVE/T numericalKeys = GetLBNumericalKeys(device)
	WAVE/T textualValues = GetLBTextualValues(device)
	WAVE/T textualKeys = GetLBTextualKeys(device)

	lbnDevices = RemoveEnding(IPNWB#ReadLabNoteBooks(fileID), ";")
	CHECK_EQUAL_STR(lbnDevices, device)

	prefix = "/general/labnotebook/" + device + "/"

	WAVE/Z numericalKeysNWB = IPNWB#H5_LoadDataSet(fileID, prefix + "numericalKeys")
	CHECK_EQUAL_WAVES(numericalKeysNWB, numericalKeys)
	WAVE/Z numericalValuesNWB = IPNWB#H5_LoadDataSet(fileID, prefix + "numericalValues")
	CHECK_EQUAL_WAVES(numericalValuesNWB, numericalValues)
	WAVE/Z textualKeysNWB = IPNWB#H5_LoadDataSet(fileID, prefix + "textualKeys")
	CHECK_EQUAL_WAVES(textualKeysNWB, textualKeys)
	WAVE/Z textualValuesNWB = IPNWB#H5_LoadDataSet(fileID, prefix + "textualValues")
	CHECK_EQUAL_WAVES(textualValuesNWB, textualValues)
End

Function TestTPStorage(fileID, device)
	variable fileID
	string device

	string prefix

	prefix = "/general/testpulse/" + device + "/"
	WAVE/Z TPStorageNWB = IPNWB#H5_LoadDataSet(fileID, prefix + "TPStorage")
	WAVE TPStorage = GetTPStorage(device)
	CHECK_EQUAL_WAVES(TPStorageNWB, TPStorage)
End

Function TestStoredTestPulses(fileID, device)
	variable fileID
	string device

	string prefix, datasets, dataset, idxstr
	variable numPulses, i, numEntries, idx

	WAVE/WAVE storedTestPulses = GetStoredTestPulseWave(device)
	numPulses = GetNumberFromWaveNote(storedTestPulses, NOTE_INDEX)

	prefix = "/general/testpulse/" + device + "/"

	datasets = IPNWB#H5_ListGroupMembers(fileID, prefix)
	// remove TPStorage entries
	datasets = GrepList(datasets, TP_STORAGE_REGEXP, 1)

	numEntries = ItemsInList(datasets)
	CHECK_EQUAL_VAR(numEntries, numPulses)

	for(i = 0; i < numEntries; i += 1)
		dataset = StringFromList(i, datasets)

		WAVE/Z TestPulseNWB = IPNWB#H5_LoadDataSet(fileID, prefix + dataset)

		SplitString/E=STORED_TESTPULSES_REGEXP dataset, idxStr
		CHECK_EQUAL_VAR(V_Flag, 1)

		idx = str2num(idxStr)
		CHECK(idx >= 0)

		WAVE/Z TestPulsePXP = storedTestPulses[idx]
		CHECK_EQUAL_WAVES(TestPulseNWB, TestPulsePXP)
	endfor
End

Function TestStimsetParamWaves(fileID, device, sweeps)
	variable fileID
	string device
	WAVE sweeps

	variable i, j, numEntries, sweep
	string stimsetParamsNWB, stimset, prefix, name

	WAVE/T textualValues = GetLBTextualValues(device)

	stimsetParamsNWB = IPNWB#H5_ListGroupMembers(fileID, "/general/stimsets")
	CHECK(ItemsInList(stimsetParamsNWB) > 0)

	numEntries = DimSize(sweeps, ROWS)
	for(i = 0; i < numEntries; i += 1)
		sweep = sweeps[i]

		if(!IsValidSweepNumber(sweep))
			break
		endif

		WAVE/T/Z stimsets = GetLastSetting(textualValues, sweep, "Stim Wave Name", DATA_ACQUISITION_MODE)
		CHECK_WAVE(stimsets, TEXT_WAVE)

		for(j = 0; j < NUM_HEADSTAGES; j += 1)
			stimset = stimsets[j]

			if(IsEmpty(stimset))
				break
			endif

			if(!cmpstr(stimset, STIMSET_TP_WHILE_DAQ))
				continue
			endif

			WAVE/Z WP  = WB_GetWaveParamForSet(stimset)
			WAVE/Z WPT = WB_GetWaveTextParamForSet(stimset)
			WAVE/Z SegWvType = WB_GetSegWvTypeForSet(stimset)

			prefix = "/general/stimsets/"

			name = WB_GetParameterWaveName(stimset, STIMSET_PARAM_WP, nwbFormat = 1)
			WAVE/Z WP_NWB = IPNWB#H5_LoadDataSet(fileID, prefix + name)
			CHECK_EQUAL_WAVES(WP_NWB, WP)

			name = WB_GetParameterWaveName(stimset, STIMSET_PARAM_WPT, nwbFormat = 1)
			WAVE/Z WPT_NWB = IPNWB#H5_LoadDataSet(fileID, prefix + name)
			CHECK_EQUAL_WAVES(WPT_NWB, WPT)

			name =  WB_GetParameterWaveName(stimset, STIMSET_PARAM_SEGWVTYPE, nwbFormat = 1)
			WAVE/Z SegWvType_NWB = IPNWB#H5_LoadDataSet(fileID, prefix + name)
			CHECK_EQUAL_WAVES(SegWvType_NWB, SegWvType)
		endfor
	endfor
End

Function TestTimeSeriesProperties(groupID, channel)
	variable groupID
	string channel

	variable numEntries, i, value, channelGroupID
	string missing_fields_ref, missing_fields

	channelGroupID = IPNWB#H5_OpenGroup(groupID, channel)

	// TimeSeries properties
	STRUCT IPNWB#TimeSeriesProperties tsp
	IPNWB#ReadTimeSeriesProperties(groupID, channel, tsp)

	if(strlen(tsp.missing_fields) == 0)
		missing_fields = "PLACEHOLDER;"
	else
		missing_fields = tsp.missing_fields
	endif

	missing_fields_ref = IPNWB#ReadTextAttributeAsList(groupID, channel, "missing_fields")
	CHECK_EQUAL_STR(missing_fields, missing_fields_ref)

	numEntries = DimSize(tsp.names, ROWS)
	for(i = 0; i < numEntries; i += 1)
		value = IPNWB#ReadDatasetAsNumber(channelGroupID, tsp.names[i])
		CHECK_EQUAL_VAR(value, tsp.data[i])
	endfor

	HDF5CloseGroup/Z channelGroupID
End

Function/S GetChannelNameFromChannelType(groupID, device, channel, sweep, params)
	variable groupID
	string device
	string channel
	variable sweep
	STRUCT IPNWB#ReadChannelParams &params

	WAVE numericalValues = GetLBNumericalValues(device)

	string channelName, key
	variable entry

	switch(params.channelType)
		case ITC_XOP_CHANNEL_TYPE_DAC:
			channelName = "DA"
			WAVE loadedFromNWB = IPNWB#LoadStimulus(groupID, channel)
			channelName += "_" + num2str(params.channelNumber)

			if(IsNaN(params.electrodeNumber))
				key = CreateLBNUnassocKey("DAC", params.channelNumber, params.channelType)
				entry = GetLastSettingIndep(numericalValues, sweep, key, DATA_ACQUISITION_MODE)
			else
				WAVE/Z settings = GetLastSetting(numericalValues, sweep, "DAC", DATA_ACQUISITION_MODE)
				CHECK_WAVE(settings, NUMERIC_WAVE)
				entry = settings[params.electrodeNumber]
			endif

			CHECK_EQUAL_VAR(entry, params.channelNumber)
			break
		case ITC_XOP_CHANNEL_TYPE_ADC:
			channelName = "AD"
			WAVE loadedFromNWB = IPNWB#LoadTimeseries(groupID, channel)
			channelName += "_" + num2str(params.channelNumber)

			if(IsNaN(params.electrodeNumber))
				key = CreateLBNUnassocKey("ADC", params.channelNumber, params.channelType)
				entry = GetLastSettingIndep(numericalValues, sweep, key, DATA_ACQUISITION_MODE)
			else
				WAVE/Z settings = GetLastSetting(numericalValues, sweep, "ADC", DATA_ACQUISITION_MODE)
				CHECK_WAVE(settings, NUMERIC_WAVE)
				entry = settings[params.electrodeNumber]
			endif

			CHECK_EQUAL_VAR(entry, params.channelNumber)
			break
		case ITC_XOP_CHANNEL_TYPE_TTL:
			channelName  = "TTL"
			WAVE loadedFromNWB = IPNWB#LoadStimulus(groupID, channel)
			channelName += "_" + num2str(params.channelNumber)

			if(IsFinite(params.ttlBit))
				channelName += "_" + num2str(log(params.ttlBit)/log(2))
			endif

			CHECK_EQUAL_VAR(str2num(params.channelSuffix), params.ttlBit)
			break
		default:
			ASSERT(0, "unknown channel type " + num2str(params.channelType))
			break
	endswitch

	return channelName
End

Function/WAVE LoadTimeSeries(groupID, channel, channelType)
	variable groupID, channelType
	string channel

	switch(channelType)
		case ITC_XOP_CHANNEL_TYPE_DAC:
			return IPNWB#LoadStimulus(groupID, channel)
			break
		case ITC_XOP_CHANNEL_TYPE_ADC:
			return IPNWB#LoadTimeseries(groupID, channel)
			break
		case ITC_XOP_CHANNEL_TYPE_TTL:
			return IPNWB#LoadStimulus(groupID, channel)
			break
		default:
			ASSERT(0, "unknown channel type " + num2str(channelType))
			break
	endswitch
End

Function TestSourceAttribute(groupID, device, channel, sweep, pxpSweepsDFR)
	variable groupID, sweep
	string device, channel
	DFREF pxpSweepsDFR

	string deviceFromSource, channelName

	WAVE numericalValues = GetLBNumericalValues(device)

	STRUCT IPNWB#ReadChannelParams params
	IPNWB#InitReadChannelParams(params)
	IPNWB#AnalyseChannelName(channel, params)
	IPNWB#LoadSourceAttribute(groupID, channel, params)

	deviceFromSource = params.device
	CHECK_EQUAL_STR(deviceFromSource, device)
	CHECK_EQUAL_VAR(params.sweep, sweep)

	channelName = GetChannelNameFromChannelType(groupID, device, channel, sweep, params)

	// check that we stored it under the correct name
	WAVE/Z/SDFR=pxpSweepsDFR pxpWave = $channelName
	WAVE loadedFromNWB = LoadTimeSeries(groupID, channel, params.channelType)
	CHECK_EQUAL_WAVES(pxpWave, loadedFromNWB)

	// groupIndex is written by IPNWB#AnalyseChannelName
	CHECK(params.groupIndex >= 0)
End

Function TestTimeSeries(fileID, device, groupID, channel, sweep, pxpSweepsDFR)
	variable fileID, groupID, sweep
	string channel, device
	DFREF pxpSweepsDFR

	variable channelGroupID, num_samples, starting_time, session_start_time, actual, scale, scale_ref
	variable clampMode, gain, gain_ref, resolution, conversion, rate_ref, rate, samplingInterval, samplingInterval_ref
	string stimulus, stimulus_expected, neurodata_type_ref, neurodata_type, channelName
	string electrode_name, electrode_name_ref, key, unit_ref, unit, base_unit_ref

	STRUCT IPNWB#ReadChannelParams params
	IPNWB#InitReadChannelParams(params)
	IPNWB#AnalyseChannelName(channel, params)
	IPNWB#LoadSourceAttribute(groupID, channel, params)

	channelName = GetChannelNameFromChannelType(groupID, device, channel, sweep, params)

	channelGroupID = IPNWB#H5_OpenGroup(groupID, channel)

	WAVE numericalValues = GetLBNumericalValues(device)
	WAVE/T textualValues = GetLBTextualValues(device)

	// num_samples
	num_samples = IPNWB#ReadDataSetAsNumber(channelGroupID, "num_samples")
	WAVE loadedFromNWB = LoadTimeSeries(groupID, channel, params.channelType)
	CHECK_EQUAL_VAR(num_samples, DimSize(loadedFromNWB, ROWS))

	// starting_time
	starting_time = IPNWB#ReadDataSetAsNumber(channelGroupID, "starting_time")
	session_start_time = ParseISO8601Timestamp(IPNWB#ReadTextDataSetAsString(fileID, "/session_start_time"))
	actual = ParseISO8601Timestamp(GetLastSettingTextIndep(textualValues, sweep, HIGH_PREC_SWEEP_START_KEY, DATA_ACQUISITION_MODE))
	CHECK_EQUAL_VAR(session_start_time + starting_time, actual)

	// its attributes: unit
	unit = IPNWB#ReadTextAttributeAsString(groupID, channel + "/starting_time", "unit")
	unit_ref = "Seconds"
	CHECK_EQUAL_STR(unit, unit_ref)

	unit = WaveUnits(loadedFromNWB, ROWS)
	unit_ref = "ms"
	CHECK_EQUAL_STR(unit, unit_ref)

	// and rate
	rate = IPNWB#ReadAttributeAsNumber(groupID, channel + "/starting_time", "rate")
	rate_ref = 1 / (DimDelta(loadedFromNWB, ROWS)/1000)
	CHECK_CLOSE_VAR(rate, rate_ref, tol=1e-7)

	samplingInterval = GetLastSettingIndep(numericalValues, sweep, "Sampling interval", DATA_ACQUISITION_MODE)
	samplingInterval_ref = DimDelta(loadedFromNWB, ROWS)
	CHECK_CLOSE_VAR(samplingInterval, samplingInterval_ref, tol=1e-7)

	// stimulus_description
	stimulus = IPNWB#ReadTextDataSetAsString(channelGroupID, "stimulus_description")
	if(params.channelType == ITC_XOP_CHANNEL_TYPE_DAC)
		stimulus_expected = "PLACEHOLDER"
	elseif(params.channelType == ITC_XOP_CHANNEL_TYPE_ADC && IsNaN(params.electrodeNumber)) // unassoc AD
		stimulus_expected = "PLACEHOLDER"
	elseif(params.channelType == ITC_XOP_CHANNEL_TYPE_TTL)
		WAVE/T/Z TTLStimsets = GetTTLStimSets(numericalValues, textualValues, sweep)
		CHECK_WAVE(TTLStimsets, TEXT_WAVE)

		if(IsNaN(params.ttlBit))
			stimulus_expected = TTLStimsets[params.channelNumber]
		else
			stimulus_expected = TTLStimsets[log(params.ttlBit)/log(2)]
		endif
	else
		WAVE/Z/T wvText = GetLastSetting(textualValues, sweep, "Stim Wave Name", DATA_ACQUISITION_MODE)
		CHECK_WAVE(wvText, TEXT_WAVE)
		stimulus_expected = wvText[params.electrodeNumber]
	endif
	CHECK_EQUAL_STR(stimulus, stimulus_expected)

	// electrode_name, only present for associated channels
	if(IsFinite(params.electrodeNumber))
		electrode_name = IPNWB#ReadTextDataSetAsString(channelGroupID, "electrode_name")
		electrode_name_ref = "electrode_" + num2str(params.electrodeNumber)
		CHECK_EQUAL_STR(electrode_name, electrode_name_ref)
	endif

	// ancestry
	WAVE/Z wv = GetLastSetting(numericalValues, sweep, "Clamp Mode", DATA_ACQUISITION_MODE)
	CHECK_WAVE(wv, NUMERIC_WAVE)

	clampMode = IsFinite(params.electrodeNumber) ? wv[params.electrodeNumber] : NaN

	WAVE/T ancestry = IPNWB#ReadTextAttribute(groupID, channel, "ancestry")

	switch(clampMode)
		case V_CLAMP_MODE:
			if(params.channelType == ITC_XOP_CHANNEL_TYPE_ADC)
				CHECK_EQUAL_TEXTWAVES(ancestry, {"TimeSeries", "PatchClampSeries", "VoltageClampSeries"})
			elseif(params.channelType == ITC_XOP_CHANNEL_TYPE_DAC)
				CHECK_EQUAL_TEXTWAVES(ancestry, {"TimeSeries", "PatchClampSeries", "VoltageClampStimulusSeries"})
			else
				FAIL()
			endif
			break
		case  I_CLAMP_MODE:
			if(params.channelType == ITC_XOP_CHANNEL_TYPE_ADC)
				CHECK_EQUAL_TEXTWAVES(ancestry, {"TimeSeries", "PatchClampSeries", "CurrentClampSeries"})
			elseif(params.channelType == ITC_XOP_CHANNEL_TYPE_DAC)
				CHECK_EQUAL_TEXTWAVES(ancestry, {"TimeSeries", "PatchClampSeries", "CurrentClampStimulusSeries"})
			else
				FAIL()
			endif
			break
		case I_EQUAL_ZERO_MODE:
			if(params.channelType == ITC_XOP_CHANNEL_TYPE_ADC)
				CHECK_EQUAL_TEXTWAVES(ancestry, {"TimeSeries", "PatchClampSeries", "CurrentClampSeries", "IZeroClampSeries"})
			else
				FAIL()
			endif
			break
		default:
			if(IsNaN(clampMode))
				CHECK_EQUAL_TEXTWAVES(ancestry, {"TimeSeries"})
			else
				ASSERT(0, "unknown clamp mode")
			endif
			break
	endswitch

	// neurodata_type
	neurodata_type = IPNWB#ReadTextAttributeAsString(groupID, channel, "neurodata_type")
	neurodata_type_ref = "TimeSeries"
	CHECK_EQUAL_STR(neurodata_type, neurodata_type_ref)

	// gain
	if(IsFinite(params.electrodeNumber))
		key = StringFromList(params.channelType, ITC_CHANNEL_NAMES) + " Gain"
		WAVE/Z gains = GetLastSetting(numericalValues, sweep, key, DATA_ACQUISITION_MODE)
		CHECK_WAVE(gains, NUMERIC_WAVE)

		gain_ref = gains[params.electrodeNumber]
		gain = IPNWB#ReadDatasetAsNumber(channelGroupID, "gain")
		CHECK_EQUAL_VAR(gain, gain_ref)
	endif

	// scale
	if(params.channelType == ITC_XOP_CHANNEL_TYPE_DAC && IsFinite(params.electrodeNumber))
		WAVE/Z scales = GetLastSetting(numericalValues, sweep, STIMSET_SCALE_FACTOR_KEY, DATA_ACQUISITION_MODE)
		CHECK_WAVE(scales, NUMERIC_WAVE)

		scale_ref = scales[params.electrodeNumber]
		scale = IPNWB#ReadDatasetAsNumber(channelGroupID, "scale")
		CHECK_EQUAL_VAR(scale, scale_ref)
	endif

	// data.resolution
	resolution = IPNWB#ReadDatasetAsNumber(channelGroupID, "resolution")
	CHECK_EQUAL_VAR(resolution, NaN)

	// data.conversion
	// data.unit
	WAVE/Z/SDFR=pxpSweepsDFR pxpWave = $channelName
	REQUIRE_WAVE(pxpWave, NUMERIC_WAVE)
	unit_ref = WaveUnits(pxpWave, -1)

	if(!cmpstr(unit_ref, "pA"))
		conversion = IPNWB#ReadAttributeAsNumber(channelGroupID, "data", "conversion")
		CHECK_CLOSE_VAR(conversion, 1e-12)

		unit = IPNWB#ReadTextAttributeAsString(channelGroupID, "data", "unit")
		base_unit_ref = "A"
		CHECK_EQUAL_STR(unit, base_unit_ref)
	elseif(!cmpstr(unit_ref, "mV"))
		conversion = IPNWB#ReadAttributeAsNumber(channelGroupID, "data", "conversion")
		CHECK_CLOSE_VAR(conversion, 1e-3, tol = 1e-5)

		unit = IPNWB#ReadTextAttributeAsString(channelGroupID, "data", "unit")
		base_unit_ref = "V"
		CHECK_EQUAL_STR(unit, base_unit_ref)
	elseif(IsEmpty(unit_ref)) // TTL data
		conversion = IPNWB#ReadAttributeAsNumber(channelGroupID, "data", "conversion")
		CHECK_CLOSE_VAR(conversion, 1)

		unit = IPNWB#ReadTextAttributeAsString(channelGroupID, "data", "unit")
		base_unit_ref = "a.u."
		CHECK_EQUAL_STR(unit, base_unit_ref)
	else
		FAIL()
	endif
End

Function/DF TestSweepData(entry, device, sweep)
	WAVE/T entry
	string device
	variable sweep

	variable ret, i, numEntries, headstage
	string nwbSweeps, pxpSweeps, pxpSweepsClean, name, channelTypeStr, channelNumberStr, channelSuffix

	WAVE numericalValues = GetLBNumericalValues(device)
	WAVE/T textualValues = GetLBTextualValues(device)

	ret = MIES_AB#AB_LoadSweepFromFile(entry[%DiscLocation], entry[%DataFolder], entry[%FileType], device, sweep)
	CHECK_EQUAL_VAR(ret, 0)

	DFREF nwbSweepsDFR = GetAnalysisSweepDataPath(entry[%DataFolder], device, sweep)

	// sweep waves in the PXP
	WAVE/Z sweepWave = GetSweepWave(device, sweep)
	CHECK_WAVE(sweepWave, NORMAL_WAVE)

	WAVE/Z configWave = GetConfigWave(sweepWave)
	CHECK_WAVE(sweepWave, NORMAL_WAVE)

	DFREF pxpSweepsDFR = NewFreeDataFolder()
	SplitSweepIntoComponents(numericalValues, sweep, sweepWave, configWave, TTL_RESCALE_OFF, targetDFR=pxpSweepsDFR)

	nwbSweeps = SortList(GetListOfObjects(nwbSweepsDFR, ".*"))
	pxpSweeps = SortList(GetListOfObjects(pxpSweepsDFR, ".*"))

	// remove IZero DA channels as we don't save these in NWB
	pxpSweepsClean = ""
	numEntries = ItemsInList(pxpSweeps)
	for(i = 0; i < numEntries; i += 1)
		name = StringFromList(i, pxpSweeps)

		SplitString/E="^([[:alpha:]]+)_([[:digit:]]+)(?:_.*)?$" name, channelTypeStr, channelNumberStr, channelSuffix
		CHECK_EQUAL_VAR(V_Flag, 2)

		WAVE DAC = GetLastSetting(numericalValues, sweep, "DAC", DATA_ACQUISITION_MODE)
		headstage = GetRowIndex(DAC, val=str2num(channelNumberStr))
		if(IsFinite(headstage))
			WAVE clampMode = GetLastSetting(numericalValues, sweep, "Clamp Mode", DATA_ACQUISITION_MODE)

			if(clampMode[headstage] == I_EQUAL_ZERO_MODE \
			   && !cmpstr(channelTypeStr, StringFromList(ITC_XOP_CHANNEL_TYPE_DAC, ITC_CHANNEL_NAMES)))
				continue
			endif
		endif

		pxpSweepsClean = AddListItem(name, pxpSweepsClean, ";", inf)
	endfor

	CHECK_EQUAL_STR(nwbSweeps, pxpSweepsClean)

	numEntries = ItemsInList(nwbSweeps)
	for(i = 0; i < numEntries; i += 1)
		WAVE/Z/SDFR=nwbSweepsDFR nwbWave = $StringFromList(i, nwbSweeps)
		CHECK_WAVE(nwbWave, NORMAL_WAVE)
		WAVE/Z/SDFR=pxpSweepsDFR pxpWave = $StringFromList(i, pxpSweepsClean)
		CHECK_WAVE(pxpWave, FREE_WAVE)
		CHECK_EQUAL_WAVES(nwbWave, pxpWave, mode = WAVE_DATA | WAVE_DATA_TYPE | WAVE_SCALING | DATA_UNITS | DIMENSION_UNITS | DIMENSION_LABELS | DATA_FULL_SCALE | DIMENSION_SIZES) // all except WAVE_NOTE
	endfor

	return pxpSweepsDFR
End

Function/S TestFileExport()

	string baseFolder, nwbFile, discLocation

	PathInfo home
	baseFolder = S_path

	nwbFile = GetExperimentName() + ".nwb"
	discLocation = baseFolder + nwbFile

	HDF5CloseFile/Z/A 0
	DeleteFile/Z/P=home nwbFile
	KillOrMoveToTrash(dfr = GetAnalysisFolder())

	NWB_ExportAllData(compressionMode = IPNWB#GetNoCompression(), writeStoredTestPulses = 1)
	CloseNWBFile()

	GetFileFolderInfo/P=home/Q/Z nwbFile
	CHECK(V_IsFile)

	CHECK_EQUAL_VAR(MIES_AB#AB_AddFile(baseFolder, discLocation), 0)

	return discLocation
End

Function TestListOfGroups(groupList, wv)
	string groupList
	WAVE/T wv

	variable index
	string list

	index = GetNumberFromWaveNote(wv, NOTE_INDEX)
	CHECK(index >= 1)

	groupList = SortList(groupList)

	Duplicate/FREE/T/R=[0, index - 1] wv, wvFilled
	wvFilled[] = RemoveEnding(wvFilled[p], ";")
	list = SortList(TextWaveToList(wvFilled, ";"))
	CHECK_EQUAL_STR(groupList, list)
End

Function TestNwbExport()
	string discLocation, device, acquisition
	string channel
	variable fileID, numEntries, i, sweep, numGroups, j, groupID

	discLocation = TestFileExport()

	WAVE/T/Z entry = AB_GetMap(discLocation)
	CHECK_WAVE(entry, FREE_WAVE)

	WAVE/T/Z devices = GetAnalysisDeviceWave(entry[%DataFolder])
	CHECK_WAVE(devices, NORMAL_WAVE)
	CHECK_EQUAL_VAR(GetNumberFromWaveNote(devices, NOTE_INDEX), 1)

	device = devices[0]

	WAVE/Z sweeps = GetAnalysisChannelSweepWave(entry[%DataFolder], device)
	CHECK_WAVE(sweeps, NUMERIC_WAVE)
	CHECK(GetNumberFromWaveNote(sweeps, NOTE_INDEX) > 0)

	WAVE/Z/T acquisitions = GetAnalysisChannelAcqWave(entry[%DataFolder], device)
	CHECK_WAVE(acquisitions, TEXT_WAVE)

	WAVE/Z/T stimuluses = GetAnalysisChannelStimWave(entry[%DataFolder], device)
	CHECK_WAVE(stimuluses, TEXT_WAVE)

	fileID = IPNWB#H5_OpenFile(discLocation)

	// check history
	TestHistory(fileID)

	// check LBNs
	TestLabnotebooks(fileID, device)

	// check TPStorage
	TestTpStorage(fileID, device)

	// check stored test pulses (if available)
	TestStoredTestPulses(fileID, device)

	// check stimset parameter waves
	TestStimsetParamWaves(fileID, device, sweeps)

	// check all acquisitions
	TestListOfGroups(IPNWB#ReadAcquisition(fileID), acquisitions)

	// check all stimulus
	TestListOfGroups(IPNWB#ReadStimulus(fileID), stimuluses)

	// check sweep data
	numEntries = DimSize(sweeps, ROWS)
	for(i = 0; i < numEntries; i += 1)
		sweep = sweeps[i]

		if(!IsValidSweepNumber(sweep))
			break
		endif

		DFREF pxpSweepsDFR = TestSweepData(entry, device, sweep)

		// check acquisition TimeSeries of NWB
		numGroups = ItemsInList(acquisitions[i])
		for(j = 0; j < numGroups; j += 1)
			channel = StringFromList(j, acquisitions[i])
			groupID = IPNWB#OpenAcquisition(fileID)

			// test all of ReadChannelParams aka source
			TestSourceAttribute(groupID, device, channel, sweep, pxpSweepsDFR)

			// TimeSeries properties
			TestTimeSeriesProperties(groupID, channel)

			TestTimeSeries(fileID, device, groupID, channel, sweep, pxpSweepsDFR)
		endfor

		// check presentation/stimulus TimeSeries of NWB
		numGroups = ItemsInList(stimuluses[i])
		for(j = 0; j < numGroups; j += 1)
			channel = StringFromList(j, stimuluses[i])
			groupID = IPNWB#OpenStimulus(fileID)

			// test all of ReadChannelParams aka source
			TestSourceAttribute(groupID, device, channel, sweep, pxpSweepsDFR)

			// TimeSeries properties
			TestTimeSeriesProperties(groupID, channel)

			TestTimeSeries(fileID, device, groupID, channel, sweep, pxpSweepsDFR)
		endfor
	endfor

	HDF5CloseFile/Z fileID
End
