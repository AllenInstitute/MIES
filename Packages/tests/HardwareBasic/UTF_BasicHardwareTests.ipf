#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma ModuleName=BasicHardwareTests

/// @file UTF_BasicHardWareTests.ipf Implement some basic tests using the DAQ hardware.

/// Test matrix for DQ_STOP_REASON_XXX
///
/// DQ_STOP_REASON_DAQ_BUTTON
/// - Abort_ITI_TP_A_PressAcq
/// - Abort_ITI_PressAcq
///
/// DQ_STOP_REASON_CONFIG_FAILED
/// - ConfigureFails
///
/// DQ_STOP_REASON_FINISHED
/// - AllTests(...)
///
/// DQ_STOP_REASON_UNCOMPILED
/// - StopDAQDueToUncompiled
///
/// DQ_STOP_REASON_TP_STARTED
/// - Abort_ITI_TP_A_TP
/// - Abort_ITI_TP
///
/// DQ_STOP_REASON_STIMSET_SELECTION
/// - ChangeStimSetDuringDAQ
///
/// DQ_STOP_REASON_UNLOCKED_DEVICE
/// - StopDAQDueToUnlocking
///
/// DQ_STOP_REASON_OUT_OF_MEMORY
/// DQ_STOP_REASON_HW_ERROR
/// DQ_STOP_REASON_ESCAPE_KEY
/// - not tested

static Function GlobalPreInit(string device)
	PASS()
End

static Function GlobalPreAcq(string device)
	PASS()
End

// UTF_TD_GENERATOR v0:IndexingPossibilities
// UTF_TD_GENERATOR s0:DeviceNameGeneratorMD1
static Function CheckActiveSetCount([STRUCT IUTF_MDATA &md])

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I1_L" + num2str(md.v0) + "_BKG1"                           + \
	                             "__HS0_DA0_AD0_CM:IC:_ST:StimulusSetC_DA_0:_IST:StimulusSetD_DA_0:" + \
	                             "_AF:TrackActiveSetCount:_IAF:TrackActiveSetCount:")
	AcquireData_NG(s, md.s0)
End

static Function CheckActiveSetCount_REENTRY([STRUCT IUTF_MDATA &md])
	WAVE anaFuncActiveSetCount = GetTrackActiveSetCount()

	WaveTransform/O zapNans, anaFuncActiveSetCount
	CHECK_EQUAL_WAVES(anaFuncActiveSetCount, {2, 1, 3, 2, 1})
End

static Function CheckLastLBNEntryFromTP_IGNORE(device)
	string device

	variable index

	// last LBN entry is from TP
	WAVE numericalValues = GetLBNumericalValues(device)
	index = GetNumberFromWaveNote(numericalValues, NOTE_INDEX)
	CHECK_GE_VAR(index, 1)
	CHECK_EQUAL_VAR(numericalValues[index - 1][%EntrySourceType], TEST_PULSE_MODE)
End

static Function CheckThatTestpulseRan_IGNORE(device)
	string   device
	variable sweepNo

	WAVE numericalValues = GetLBNumericalValues(device)
	sweepNo = AFH_GetLastSweepAcquired(device)
	WAVE/Z settings = GetLastSetting(numericalValues, sweepNo, "ADC", TEST_PULSE_MODE)
	CHECK_WAVE(settings, NUMERIC_WAVE)
End

// UTF_TD_GENERATOR v0:SingleMultiDeviceDAQ
// UTF_TD_GENERATOR s0:DeviceNameGenerator
static Function Abort_ITI_TP([STRUCT IUTF_MDATA &md])

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD" + num2str(md.v0) + "_RA1_I1_L0_BKG1_GSI0_ITI5"              + \
	                             "__HS0_DA0_AD0_CM:IC:_ST:StimulusSetC_DA_0:_IST:StimulusSetD_DA_0:")
	AcquireData_NG(s, md.s0)

	CtrlNamedBackGround StopTPAfterSomeTime, start=(ticks + 420), period=60, proc=StopTP_IGNORE
	CtrlNamedBackGround Abort_ITI_TP, start, period=30, proc=StartTPDuringITI_IGNORE
End

static Function Abort_ITI_TP_REENTRY([STRUCT IUTF_MDATA &md])

	NVAR runModeDAQ = $GetDataAcqRunMode(md.s0)
	CHECK_EQUAL_VAR(runModeDAQ, DAQ_NOT_RUNNING)

	NVAR runModeTP = $GetTestpulseRunMode(md.s0)
	CHECK_EQUAL_VAR(runModeTP, TEST_PULSE_NOT_RUNNING)

	// check that TP after DAQ really ran
	CheckLastLBNEntryFromTP_IGNORE(md.s0)

	CheckDAQStopReason(md.s0, DQ_STOP_REASON_TP_STARTED)
End

// UTF_TD_GENERATOR v0:SingleMultiDeviceDAQ
// UTF_TD_GENERATOR s0:DeviceNameGenerator
static Function Abort_ITI_TP_A_TP([STRUCT IUTF_MDATA &md])

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD" + num2str(md.v0) + "_RA1_I1_L0_BKG1_GSI0_ITI5_RES5"         + \
	                             "__HS0_DA0_AD0_CM:IC:_ST:StimulusSetC_DA_0:_IST:StimulusSetD_DA_0:")
	AcquireData_NG(s, md.s0)

	CtrlNamedBackGround StopTPAfterSomeTime, start=(ticks + 420), period=60, proc=StopTP_IGNORE
	CtrlNamedBackGround Abort_ITI_TP, start, period=30, proc=StartTPDuringITI_IGNORE

	PGC_SetAndActivateControl(md.s0, "check_Settings_TPAfterDAQ", val = 1)
End

static Function Abort_ITI_TP_A_TP_REENTRY([STRUCT IUTF_MDATA &md])

	NVAR runModeDAQ = $GetDataAcqRunMode(md.s0)
	CHECK_EQUAL_VAR(runModeDAQ, DAQ_NOT_RUNNING)

	NVAR runModeTP = $GetTestpulseRunMode(md.s0)
	CHECK_EQUAL_VAR(runModeTP, TEST_PULSE_NOT_RUNNING)

	// check that TP after DAQ really ran
	CheckLastLBNEntryFromTP_IGNORE(md.s0)

	CheckDAQStopReason(md.s0, DQ_STOP_REASON_TP_STARTED)
End

// UTF_TD_GENERATOR v0:SingleMultiDeviceDAQ
// UTF_TD_GENERATOR s0:DeviceNameGenerator
static Function AbortTP([STRUCT IUTF_MDATA &md])

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD" + num2str(md.v0) + "_RA1_I1_L0_BKG1_TP1"                    + \
	                             "__HS0_DA0_AD0_CM:IC:_ST:StimulusSetC_DA_0:_IST:StimulusSetD_DA_0:")
	AcquireData_NG(s, md.s0)

	CtrlNamedBackGround DelayReentry, start=(ticks + 300), period=60, proc=JustDelay_IGNORE
	RegisterUTFMonitor("DelayReentry", BACKGROUNDMONMODE_AND, "BasicHardwareTests#AbortTP_REENTRY", timeout = 600, failOnTimeout = 1)
End

static Function AbortTP_REENTRY([STRUCT IUTF_MDATA &md])

	string device
	variable aborted, err

	device = StringFromList(0, md.s0)

	KillWindow $device
	try
		ASYNC_STOP(timeout = 5)
	catch
		err     = getRTError(1)
		aborted = 1
	endtry

	ASYNC_Start(threadprocessorCount, disableTask = 1)

	if(aborted)
		FAIL()
	else
		PASS()
	endif
End

// UTF_TD_GENERATOR v0:SingleMultiDeviceDAQ
// UTF_TD_GENERATOR s0:DeviceNameGenerator
static Function StartDAQDuringTP([STRUCT IUTF_MDATA &md])

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD" + num2str(md.v0) + "_RA0_I0_L0_BKG1_RES0_TP1"                 + \
	                             "__HS0_DA0_AD0_CM:IC:_ST:StimulusSetA_DA_0:_AF:WriteIntoLBNOnPreDAQ:")
	AcquireData_NG(s, md.s0)

	CtrlNamedBackGround StartDAQDuringTP, start=(ticks + 600), period=100, proc=StartAcq_IGNORE
End

static Function StartDAQDuringTP_REENTRY([STRUCT IUTF_MDATA &md])
	variable sweepNo
	string   device

	device = StringFromList(0, md.s0)

	NVAR runModeDAQ = $GetDataAcqRunMode(device)

	CHECK_EQUAL_VAR(runModeDAQ, DAQ_NOT_RUNNING)

	NVAR runModeTP = $GetTestpulseRunMode(device)
	CHECK_EQUAL_VAR(runModeTP, TEST_PULSE_NOT_RUNNING)

	sweepNo = AFH_GetLastSweepAcquired(device)
	CHECK_EQUAL_VAR(sweepNo, 0)

	WAVE   numericalValues = GetLBNumericalValues(device)
	WAVE/Z settings        = GetLastSetting(numericalValues, sweepNo, "USER_GARBAGE", UNKNOWN_MODE)
	CHECK_WAVE(settings, FREE_WAVE)
	CHECK_EQUAL_WAVES(settings, {0, 1, 2, 3, 4, 5, 6, 7, NaN}, mode = WAVE_DATA)

	// ascending sweep numbers are checked in TEST_CASE_BEGIN_OVERRIDE()
End

// UTF_TD_GENERATOR v0:SingleMultiDeviceDAQ
// UTF_TD_GENERATOR s0:DeviceNameGenerator
static Function Abort_ITI_PressAcq([STRUCT IUTF_MDATA &md])

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD" + num2str(md.v0) + "_RA1_I0_L0_BKG1_RES5_GSI0_ITI5" + \
	                             "__HS0_DA0_AD0_CM:IC:_ST:StimulusSetA_DA_0:")
	AcquireData_NG(s, md.s0)

	CtrlNamedBackGround StopTPAfterSomeTime, start=(ticks + 420), period=60, proc=StopTP_IGNORE
	CtrlNamedBackGround Abort_ITI_PressAcq, start, period=30, proc=StopAcqDuringITI_IGNORE
End

static Function Abort_ITI_PressAcq_REENTRY([STRUCT IUTF_MDATA &md])
	string device = md.s0

	NVAR runModeDAQ = $GetDataAcqRunMode(device)
	CHECK_EQUAL_VAR(runModeDAQ, DAQ_NOT_RUNNING)

	NVAR runModeTP = $GetTestpulseRunMode(device)
	CHECK_EQUAL_VAR(runModeTP, TEST_PULSE_NOT_RUNNING)

	CheckThatTestpulseRan_IGNORE(device)

	CheckDAQStopReason(device, DQ_STOP_REASON_DAQ_BUTTON)
End

// UTF_TD_GENERATOR v0:SingleMultiDeviceDAQ
// UTF_TD_GENERATOR s0:DeviceNameGenerator
static Function Abort_ITI_TP_A_PressAcq([STRUCT IUTF_MDATA &md])

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD" + num2str(md.v0) + "_RA1_I0_L0_BKG1_RES5_GSI0_ITI5" + \
	                             "__HS0_DA0_AD0_CM:IC:_ST:StimulusSetA_DA_0:")
	AcquireData_NG(s, md.s0)

	CtrlNamedBackGround StopTPAfterSomeTime, start=(ticks + 420), period=60, proc=StopTP_IGNORE
	CtrlNamedBackGround Abort_ITI_PressAcq, start, period=30, proc=StopAcqDuringITI_IGNORE

	PGC_SetAndActivateControl(md.s0, "check_Settings_TPAfterDAQ", val = 1)
End

static Function Abort_ITI_TP_A_PressAcq_REENTRY([STRUCT IUTF_MDATA &md])
	string device = md.s0

	NVAR runModeDAQ = $GetDataAcqRunMode(device)
	CHECK_EQUAL_VAR(runModeDAQ, DAQ_NOT_RUNNING)

	NVAR runModeTP = $GetTestpulseRunMode(device)
	CHECK_EQUAL_VAR(runModeTP, TEST_PULSE_NOT_RUNNING)

	// check that TP after DAQ really ran
	CheckLastLBNEntryFromTP_IGNORE(device)
End

static Function ChangeToOtherDeviceDAQ_PreAcq(device)
	string device

	WAVE/T wv = root:MIES:WaveBuilder:SavedStimulusSetParameters:DA:WPT_StimulusSetA_DA_0
	wv[][%Set]                              = ""
	wv[%$"Analysis pre DAQ function"][%Set] = "ChangeToOtherDeviceDAQAF"
End

// UTF_TD_GENERATOR v0:SingleMultiDeviceDAQ
// UTF_TD_GENERATOR s0:DeviceNameGeneratorMD0
static Function ChangeToOtherDeviceDAQ([STRUCT IUTF_MDATA &md])

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD" + num2str(md.v0) + "_RA0_I0_L0_BKG1" + \
	                             "__HS0_DA0_AD0_CM:IC:_ST:StimulusSetA_DA_0:")
	AcquireData_NG(s, md.s0)
End

static Function ChangeToOtherDeviceDAQ_REENTRY([STRUCT IUTF_MDATA &md])
	string device
	variable sweepNo, multiDeviceMode, multiDeviceModeRef

	device             = StringFromList(0, md.s0)
	multiDeviceModeRef = !md.v0

	CHECK_EQUAL_VAR(GetCheckBoxState(device, "check_Settings_MD"), multiDeviceModeRef ? CHECKBOX_SELECTED : CHECKBOX_UNSELECTED)

	sweepNo = AFH_GetLastSweepAcquired(device)
	CHECK(IsValidSweepNumber(sweepNo))
	WAVE numericalValues = GetLBNumericalValues(device)
	multiDeviceMode = GetLastSettingIndep(numericalValues, sweepNo, "Multi device mode", DATA_ACQUISITION_MODE)
	CHECK_EQUAL_VAR(multiDeviceMode, multiDeviceModeRef)
End

static Function ChangeStimSetDuringDAQ_PreAcq(string device)

	PGC_SetAndActivateControl(device, "check_Settings_TPAfterDAQ", val = 1)

	CtrlNamedBackGround StopTPAfterSomeTime, start=(ticks + 600), period=60, proc=StopTP_IGNORE
	CtrlNamedBackGround ChangeStimsetDuringDAQ, start, period=30, proc=ChangeStimSet_IGNORE
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function ChangeStimSetDuringDAQ([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG1_RES1"                    + \
	                             "__HS0_DA0_AD0_CM:IC:_ST:StimulusSetA_DA_0:" + \
	                             "__HS1_DA1_AD1_CM:VC:_ST:StimulusSetC_DA_0:")
	AcquireData_NG(s, str)
End

static Function ChangeStimSetDuringDAQ_REENTRY([str])
	string str

	string device
	variable numEntries, i

	numEntries = ItemsInList(str)
	for(i = 0; i < numEntries; i += 1)
		device = stringFromList(i, str)

		NVAR runModeDAQ = $GetDataAcqRunMode(device)
		CHECK_EQUAL_VAR(runModeDAQ, DAQ_NOT_RUNNING)

		NVAR runModeTP = $GetTestpulseRunMode(device)
		CHECK_EQUAL_VAR(runModeTP, TEST_PULSE_NOT_RUNNING)
	endfor

	CheckDAQStopReason(str, DQ_STOP_REASON_STIMSET_SELECTION)

	// even with TP after DAQ we have "finished" as reason
	CheckDAQStopReason(str, DQ_STOP_REASON_FINISHED, sweepNo = 2)
End

// UTF_TD_GENERATOR v0:SingleMultiDeviceDAQ
// UTF_TD_GENERATOR s0:DeviceNameGenerator
static Function DAQZerosDAC([STRUCT IUTF_MDATA &md])
	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD" + num2str(md.v0) + "_RA0_I0_L0_BKG1" + \
	                             "__HS0_DA0_AD0_CM:IC:_ST:StimulusSetA_DA_0:")

	AcquireData_NG(s, md.s0)
End

static Function DAQZerosDAC_REENTRY([STRUCT IUTF_MDATA &md])

	variable deviceID, hardwareType, sweepNo, index, ADC, DAC
	string device

	device = md.s0

	CHECK_EQUAL_VAR(ROVar(GetDataAcqRunMode(device)), DAQ_NOT_RUNNING)
	CHECK_EQUAL_VAR(ROVar(GetTestpulseRunMode(device)), TEST_PULSE_NOT_RUNNING)

	sweepNo = AFH_GetLastSweepAcquired(device)
	CHECK_EQUAL_VAR(sweepNo, 0)

	WAVE numericalValues = GetLBNumericalValues(device)

	[WAVE settings, index] = GetLastSettingChannel(numericalValues, $"", sweepNo, "ADC", 0, XOP_CHANNEL_TYPE_ADC, DATA_ACQUISITION_MODE)
	CHECK_WAVE(settings, NUMERIC_WAVE)
	ADC = settings[index]

	[WAVE settings, index] = GetLastSettingChannel(numericalValues, $"", sweepNo, "DAC", 0, XOP_CHANNEL_TYPE_DAC, DATA_ACQUISITION_MODE)
	CHECK_WAVE(settings, NUMERIC_WAVE)
	DAC = settings[index]

	DFREF dataDFR  = GetDeviceDataPath(device)
	DFREF sweepDFR = GetSingleSweepFolder(dataDFR, sweepNo)

	// we end the DAC data with high
	WAVE/Z DACWave = GetDAQDataSingleColumnWave(sweepDFR, XOP_CHANNEL_TYPE_DAC, DAC)
	CHECK_GE_VAR(DACWave[Inf], 0.9)

	deviceID     = ROVar(GetDAQDeviceID(device))
	hardwareType = GetHardwareType(device)

	// but due to zeroDAC being on we end with around zero
	CHECK_LE_VAR(HW_ReadADC(hardwareType, deviceID, ADC), 0.01)
End

// Using unassociated channels works
// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function UnassociatedChannelsAndTTLs([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG1"                              + \
	                             "__HS0_DA0_AD0_CM:VC:_ST:StimulusSetA_DA_0:"      + \
	                             "__HS1_DA1_AD1_CM:VC:_ST:StimulusSetC_DA_0:"      + \
	                             "__HS2_DA2_AD2_CM:VC:_ST:StimulusSetA_DA_0:_ASO0" + \
	                             "__TTL1_ST:StimulusSetA_TTL_0:"                   + \
	                             "__TTL3_ST:StimulusSetB_TTL_0:"                   + \
	                             "__TTL5_ST:StimulusSetC_TTL_0:"                   + \
	                             "__TTL6_ST:StimulusSetD_TTL_0:")

	AcquireData_NG(s, str)
End

static Function UnassociatedChannelsAndTTLs_REENTRY([str])
	string str

	string device, sweeps, configs, unit, expectedStr, stimSetLengths2
	variable numEntries, i, j, k, numSweeps, numRacks, hardwareType, index

	numSweeps = 1

	numEntries = ItemsInList(str)
	for(i = 0; i < numEntries; i += 1)
		device = stringFromList(i, str)

		hardwareType = GetHardwareType(device)
		numRacks     = hardwareType == HARDWARE_ITC_DAC ? HW_ITC_GetNumberOfRacks(device) : NaN

		CHECK_EQUAL_VAR(GetSetVariable(device, "SetVar_Sweep"), numSweeps)
		sweeps  = GetListOfObjects(GetDeviceDataPath(device), DATA_SWEEP_REGEXP, fullPath = 1)
		configs = GetListOfObjects(GetDeviceDataPath(device), DATA_CONFIG_REGEXP, fullPath = 1)

		CHECK_EQUAL_VAR(ItemsInList(sweeps), numSweeps)
		CHECK_EQUAL_VAR(ItemsInList(configs), numSweeps)

		WAVE/T textualValues   = GetLBTextualValues(device)
		WAVE   numericalValues = GetLBNumericalValues(device)

		for(j = 0; j < numSweeps; j += 1)
			WAVE/Z sweep = $StringFromList(j, sweeps)
			CHECK_WAVE(sweep, TEXT_WAVE)
			WAVE/Z config = $StringFromList(j, configs)
			CHECK_WAVE(config, NUMERIC_WAVE)

			WAVE channelDA = ResolveSweepChannel(sweep, 0)
			CHECK_WAVE(channelDA, NUMERIC_WAVE, minorType = FLOAT_WAVE)

			CHECK_EQUAL_VAR(DimSize(config, ROWS), DimSize(sweep, ROWS))

			switch(hardwareType)
				case HARDWARE_ITC_DAC:
					if(numRacks == 2)
						CHECK_EQUAL_VAR(DimSize(config, ROWS), 3 + 3 + 2)
					else
						CHECK_EQUAL_VAR(DimSize(config, ROWS), 3 + 3 + 1)
					endif
					break
				case HARDWARE_NI_DAC:
					CHECK_EQUAL_VAR(DimSize(config, ROWS), 3 + 3 + 4)
					break
			endswitch

			// check channel types
			CHECK_EQUAL_VAR(config[0][%ChannelType], XOP_CHANNEL_TYPE_DAC)
			CHECK_EQUAL_VAR(config[1][%ChannelType], XOP_CHANNEL_TYPE_DAC)
			CHECK_EQUAL_VAR(config[2][%ChannelType], XOP_CHANNEL_TYPE_DAC)
			CHECK_EQUAL_VAR(config[3][%ChannelType], XOP_CHANNEL_TYPE_ADC)
			CHECK_EQUAL_VAR(config[4][%ChannelType], XOP_CHANNEL_TYPE_ADC)
			CHECK_EQUAL_VAR(config[5][%ChannelType], XOP_CHANNEL_TYPE_ADC)
			if(hardwareType == HARDWARE_ITC_DAC && numRacks == 1)
				CHECK_EQUAL_VAR(config[6][%ChannelType], XOP_CHANNEL_TYPE_TTL)
			elseif(hardwareType == HARDWARE_ITC_DAC && numRacks == 2)
				CHECK_EQUAL_VAR(config[6][%ChannelType], XOP_CHANNEL_TYPE_TTL)
				CHECK_EQUAL_VAR(config[7][%ChannelType], XOP_CHANNEL_TYPE_TTL)
			elseif(hardwareType == HARDWARE_NI_DAC)
				CHECK_EQUAL_VAR(config[6][%ChannelType], XOP_CHANNEL_TYPE_TTL)
				CHECK_EQUAL_VAR(config[7][%ChannelType], XOP_CHANNEL_TYPE_TTL)
				CHECK_EQUAL_VAR(config[8][%ChannelType], XOP_CHANNEL_TYPE_TTL)
				CHECK_EQUAL_VAR(config[9][%ChannelType], XOP_CHANNEL_TYPE_TTL)
			endif

			// check channel numbers
			WAVE DACs = GetDACListFromConfig(config)
			CHECK_EQUAL_WAVES(DACs, {0, 1, 2}, mode = WAVE_DATA)

			WAVE ADCs = GetADCListFromConfig(config)
			CHECK_EQUAL_WAVES(ADCs, {0, 1, 2}, mode = WAVE_DATA)

			WAVE TTLs = GetTTLListFromConfig(config)

			// check headstage numbers
			CHECK_EQUAL_VAR(config[0][%HEADSTAGE], 0)
			CHECK_EQUAL_VAR(config[1][%HEADSTAGE], 1)
			CHECK_EQUAL_VAR(config[2][%HEADSTAGE], NaN)
			CHECK_EQUAL_VAR(config[3][%HEADSTAGE], 0)
			CHECK_EQUAL_VAR(config[4][%HEADSTAGE], 1)
			CHECK_EQUAL_VAR(config[5][%HEADSTAGE], NaN)
			if(hardwareType == HARDWARE_ITC_DAC && numRacks == 1)
				CHECK_EQUAL_VAR(config[6][%HEADSTAGE], NaN)
			elseif(hardwareType == HARDWARE_ITC_DAC && numRacks == 2)
				CHECK_EQUAL_VAR(config[6][%HEADSTAGE], NaN)
				CHECK_EQUAL_VAR(config[7][%HEADSTAGE], NaN)
			elseif(hardwareType == HARDWARE_NI_DAC)
				CHECK_EQUAL_VAR(config[6][%HEADSTAGE], NaN)
				CHECK_EQUAL_VAR(config[7][%HEADSTAGE], NaN)
				CHECK_EQUAL_VAR(config[8][%HEADSTAGE], NaN)
				CHECK_EQUAL_VAR(config[9][%HEADSTAGE], NaN)
			endif

			// check clampMode numbers
			CHECK_EQUAL_VAR(config[0][%CLAMPMODE], V_CLAMP_MODE)
			CHECK_EQUAL_VAR(config[1][%CLAMPMODE], V_CLAMP_MODE)
			CHECK_EQUAL_VAR(config[2][%CLAMPMODE], NaN)
			CHECK_EQUAL_VAR(config[3][%CLAMPMODE], V_CLAMP_MODE)
			CHECK_EQUAL_VAR(config[4][%CLAMPMODE], V_CLAMP_MODE)
			CHECK_EQUAL_VAR(config[5][%CLAMPMODE], NaN)
			if(hardwareType == HARDWARE_ITC_DAC && numRacks == 1)
				CHECK_EQUAL_VAR(config[6][%CLAMPMODE], NaN)
			elseif(hardwareType == HARDWARE_ITC_DAC && numRacks == 2)
				CHECK_EQUAL_VAR(config[6][%CLAMPMODE], NaN)
				CHECK_EQUAL_VAR(config[7][%CLAMPMODE], NaN)
			elseif(hardwareType == HARDWARE_NI_DAC)
				CHECK_EQUAL_VAR(config[6][%CLAMPMODE], NaN)
				CHECK_EQUAL_VAR(config[7][%CLAMPMODE], NaN)
				CHECK_EQUAL_VAR(config[8][%CLAMPMODE], NaN)
				CHECK_EQUAL_VAR(config[9][%CLAMPMODE], NaN)
			endif

			WAVE/Z   ttlStimSets              = GetTTLLabnotebookEntry(textualValues, LABNOTEBOOK_TTL_STIMSETS, j)
			WAVE/T/Z foundIndexingEndStimSets = GetLastSetting(textualValues, j, "TTL Indexing End stimset", DATA_ACQUISITION_MODE)
			WAVE/T/Z stimWaveChecksums        = GetLastSetting(textualValues, j, "TTL Stim Wave Checksum", DATA_ACQUISITION_MODE)

			WAVE/Z stimSetLengths = GetLastSetting(textualValues, j, "TTL Stim set length", DATA_ACQUISITION_MODE)
			[WAVE settings, index] = GetLastSettingChannel(numericalValues, textualValues, j, "TTL Stim set length", 1, XOP_CHANNEL_TYPE_TTL, DATA_ACQUISITION_MODE)
			CHECK_WAVE(settings, TEXT_WAVE)
			CHECK_EQUAL_VAR(index, INDEP_HEADSTAGE)
			WAVE/T settingsT = settings
			stimSetLengths2 = settingsT[index]
			WAVE/T stimSetLengthsT = stimSetLengths
			CHECK_EQUAL_STR(stimSetLengths2, stimSetLengthsT[INDEP_HEADSTAGE])

			switch(hardwareType)
				case HARDWARE_ITC_DAC:
					if(numRacks == 2)
						CHECK_EQUAL_TEXTWAVES(ttlStimSets, {"", "StimulusSetA_TTL_0", "", "StimulusSetB_TTL_0", "", "StimulusSetC_TTL_0", "StimulusSetD_TTL_0", ""})
					else
						CHECK_EQUAL_TEXTWAVES(ttlStimSets, {"", "StimulusSetA_TTL_0", "", "StimulusSetB_TTL_0", "", "", "", ""})
					endif

					// check TTL LBN keys
					if(numRacks == 2)
						CHECK_EQUAL_WAVES(TTLs, {HW_ITC_GetITCXOPChannelForRack(device, RACK_ZERO),                 \
						                         HW_ITC_GetITCXOPChannelForRack(device, RACK_ONE)}, mode = WAVE_DATA)
					else
						CHECK_EQUAL_WAVES(TTLs, {HW_ITC_GetITCXOPChannelForRack(device, RACK_ZERO)}, mode = WAVE_DATA)
					endif

					WAVE/T/Z foundStimSetsRackZero = GetLastSetting(textualValues, j, "TTL rack zero stim sets", DATA_ACQUISITION_MODE)
					CHECK_EQUAL_TEXTWAVES(foundStimSetsRackZero, {"", "", "", "", "", "", "", "", ";StimulusSetA_TTL_0;;StimulusSetB_TTL_0;"})
					WAVE/T/Z foundStimSetsRackOne = GetLastSetting(textualValues, j, "TTL rack one stim sets", DATA_ACQUISITION_MODE)

					if(numRacks == 2)
						CHECK_EQUAL_TEXTWAVES(foundStimSetsRackOne, {"", "", "", "", "", "", "", "", ";StimulusSetC_TTL_0;StimulusSetD_TTL_0;;"})
					else
						CHECK_WAVE(foundStimSetsRackOne, NULL_WAVE)
					endif

					CHECK_EQUAL_VAR(NUM_ITC_TTL_BITS_PER_RACK, 4)

					WAVE/Z bits = GetLastSetting(numericalValues, j, "TTL rack zero bits", DATA_ACQUISITION_MODE)
					// TTL 1 and 3 are active -> 2^1 + 2^3 = 10
					CHECK_EQUAL_WAVES(bits, {NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, 10}, mode = WAVE_DATA)
					WAVE/Z bits = GetLastSetting(numericalValues, j, "TTL rack one bits", DATA_ACQUISITION_MODE)

					if(numRacks == 2)
						// TTL 5 and 5 are active -> 2^(5 - 4) + 2^(6 - 4) = 6
						CHECK_EQUAL_WAVES(bits, {NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, 6}, mode = WAVE_DATA)
					else
						CHECK_WAVE(bits, NULL_WAVE)
					endif

					WAVE/Z channels = GetLastSetting(numericalValues, j, "TTL rack zero channel", DATA_ACQUISITION_MODE)

					if(numRacks == 2)
						CHECK_EQUAL_VAR(DimSize(TTLs, ROWS), 2)
					else
						CHECK_EQUAL_VAR(DimSize(TTLs, ROWS), 1)
					endif

					CHECK_EQUAL_WAVES(channels, {NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, TTLs[0]}, mode = WAVE_DATA)
					WAVE/Z channels = GetLastSetting(numericalValues, j, "TTL rack one channel", DATA_ACQUISITION_MODE)
					if(numRacks == 2)
						CHECK_EQUAL_WAVES(channels, {NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, TTLs[1]}, mode = WAVE_DATA)
					else
						CHECK_WAVE(channels, NULL_WAVE)
					endif

					// set sweep count
					WAVE/T/Z sweepCounts = GetLastSetting(textualValues, j, "TTL rack zero set sweep counts", DATA_ACQUISITION_MODE)
					CHECK_EQUAL_TEXTWAVES(sweepCounts, {"", "", "", "", "", "", "", "", ";0;;0;"})
					WAVE/T/Z sweepCounts = GetLastSetting(textualValues, j, "TTL rack one set sweep counts", DATA_ACQUISITION_MODE)
					if(numRacks == 2)
						CHECK_EQUAL_TEXTWAVES(sweepCounts, {"", "", "", "", "", "", "", "", ";0;0;;"})
					else
						CHECK_WAVE(sweepCounts, NULL_WAVE)
					endif

					// set cycle count
					WAVE/T/Z cycleCounts = GetLastSetting(textualValues, j, "TTL rack zero set cycle counts", DATA_ACQUISITION_MODE)
					CHECK_EQUAL_TEXTWAVES(cycleCounts, {"", "", "", "", "", "", "", "", ";0;;0;"})
					WAVE/T/Z cycleCounts = GetLastSetting(textualValues, j, "TTL rack one set cycle counts", DATA_ACQUISITION_MODE)
					if(numRacks == 2)
						CHECK_EQUAL_TEXTWAVES(cycleCounts, {"", "", "", "", "", "", "", "", ";0;0;;"})
					else
						CHECK_WAVE(cycleCounts, NULL_WAVE)
					endif

					// Indexing End stimset
					if(numRacks == 2)
						CHECK_EQUAL_TEXTWAVES(foundIndexingEndStimSets, {"", "", "", "", "", "", "", "", ";- none -;;- none -;;- none -;- none -;;"})
					else
						CHECK_EQUAL_TEXTWAVES(foundIndexingEndStimSets, {"", "", "", "", "", "", "", "", ";- none -;;- none -;;;;;"})
					endif

					// Stim Wave Checksum
					if(numRacks == 2)
						CHECK(GrepString(stimWaveChecksums[INDEP_HEADSTAGE], ";[[:digit:]]+;;[[:digit:]]+;;[[:digit:]]+;[[:digit:]]+;;"))
					else
						CHECK(GrepString(stimWaveChecksums[INDEP_HEADSTAGE], ";[[:digit:]]+;;[[:digit:]]+;;;;;"))
					endif

					// Stim set length
					if(numRacks == 2)
						CHECK_EQUAL_TEXTWAVES(stimSetLengths, {"", "", "", "", "", "", "", "", ";47499;;46249;;50624;65249;;"})
					else
						CHECK_EQUAL_TEXTWAVES(stimSetLengths, {"", "", "", "", "", "", "", "", ";37999;;36999;;;;;"})
					endif

					break
				case HARDWARE_NI_DAC:
					CHECK_EQUAL_TEXTWAVES(ttlStimSets, {"", "StimulusSetA_TTL_0", "", "StimulusSetB_TTL_0", "", "StimulusSetC_TTL_0", "StimulusSetD_TTL_0", ""})
					CHECK_EQUAL_WAVES(TTLs, {1, 3, 5, 6}, mode = WAVE_DATA)

					WAVE/T/Z channelsTxT = GetLastSetting(textualValues, j, "TTL channels", DATA_ACQUISITION_MODE)
					CHECK_EQUAL_TEXTWAVES(channelsTxT, {"", "", "", "", "", "", "", "", ";1;;3;;5;6;;"}, mode = WAVE_DATA)

					WAVE/T/Z foundStimSets = GetLastSetting(textualValues, j, "TTL stim sets", DATA_ACQUISITION_MODE)
					CHECK_EQUAL_TEXTWAVES(foundStimSets, {"", "", "", "", "", "", "", "", ";StimulusSetA_TTL_0;;StimulusSetB_TTL_0;;StimulusSetC_TTL_0;StimulusSetD_TTL_0;;"})

					WAVE/T/Z sweepCounts = GetLastSetting(textualValues, j, "TTL set sweep counts", DATA_ACQUISITION_MODE)
					CHECK_EQUAL_TEXTWAVES(sweepCounts, {"", "", "", "", "", "", "", "", ";0;;0;;0;0;;"})

					WAVE/T/Z cycleCounts = GetLastSetting(textualValues, j, "TTL set cycle counts", DATA_ACQUISITION_MODE)
					CHECK_EQUAL_TEXTWAVES(cycleCounts, {"", "", "", "", "", "", "", "", ";0;;0;;0;0;;"})

					CHECK_EQUAL_TEXTWAVES(foundIndexingEndStimSets, {"", "", "", "", "", "", "", "", ";- none -;;- none -;;- none -;- none -;;"})
					CHECK(GrepString(stimWaveChecksums[INDEP_HEADSTAGE], ";[[:digit:]]+;;[[:digit:]]+;;[[:digit:]]+;[[:digit:]]+;;"))
					CHECK_EQUAL_TEXTWAVES(stimSetLengths, {"", "", "", "", "", "", "", "", ";158333;;154166;;168749;217499;;"})
					break
			endswitch

			// hardware agnostic TTL entries
			WAVE/Z settings = GetLastSetting(textualValues, j, "TTL Stimset wave note", DATA_ACQUISITION_MODE)
			CHECK_WAVE(settings, TEXT_WAVE)

			// fetch some labnotebook entries, the last channel is unassociated
			Make/FREE/T expectedUnits = {"pA", "pA", "V"}
			for(k = 0; k < DimSize(ADCs, ROWS); k += 1)
				[WAVE settings, index] = GetLastSettingChannel(numericalValues, $"", j, "AD ChannelType", ADCs[k], XOP_CHANNEL_TYPE_ADC, DATA_ACQUISITION_MODE)
				CHECK_EQUAL_VAR(settings[index], DAQ_CHANNEL_TYPE_DAQ)

				[WAVE settings, index] = GetLastSettingChannel(numericalValues, textualValues, j, "AD Unit", ADCs[k], XOP_CHANNEL_TYPE_ADC, DATA_ACQUISITION_MODE)
				WAVE/T settingsText = settings
				str = settingsText[index]
				CHECK_EQUAL_STR(str, expectedUnits[k])
			endfor

			Make/FREE/T expectedUnits = {"mV", "mV", "V"}
			for(k = 0; k < DimSize(DACs, ROWS); k += 1)
				[WAVE settings, index] = GetLastSettingChannel(numericalValues, $"", j, "DA ChannelType", DACs[k], XOP_CHANNEL_TYPE_DAC, DATA_ACQUISITION_MODE)
				CHECK_EQUAL_VAR(settings[index], DAQ_CHANNEL_TYPE_DAQ)

				[WAVE settings, index] = GetLastSettingChannel(numericalValues, textualValues, j, "DA Unit", DACs[k], XOP_CHANNEL_TYPE_DAC, DATA_ACQUISITION_MODE)
				WAVE/T settingsText = settings
				str = settingsText[index]
				CHECK_EQUAL_STR(str, expectedUnits[k])
			endfor

			// test GetActiveChannels
			WAVE DA = GetActiveChannels(numericalValues, textualValues, j, XOP_CHANNEL_TYPE_DAC)
			CHECK_EQUAL_WAVES(DA, {0, 1, 2, NaN, NaN, NaN, NaN, NaN})

			WAVE AD = GetActiveChannels(numericalValues, textualValues, j, XOP_CHANNEL_TYPE_ADC)
			CHECK_EQUAL_WAVES(AD, {0, 1, 2, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN})

			WAVE guiTTLChannels = GetActiveChannels(numericalValues, textualValues, j, XOP_CHANNEL_TYPE_TTL, TTLmode = TTL_DAEPHYS_CHANNEL)
			WAVE hwTTLChannels  = GetActiveChannels(numericalValues, textualValues, j, XOP_CHANNEL_TYPE_TTL, TTLmode = TTL_HARDWARE_CHANNEL)

			if(hardwareType == HARDWARE_NI_DAC)
				Make/FREE/D hwTTLRef = {NaN, 1, NaN, 3, NaN, 5, 6, NaN}
				WAVE/D guiTTLRef = hwTTLRef
			else
				Make/FREE/D/N=(NUM_DA_TTL_CHANNELS) hwTTLRef = NaN
				index           = HW_ITC_GetITCXOPChannelForRack(device, RACK_ZERO)
				hwTTLRef[index] = index

				if(numRacks == 2)
					index           = HW_ITC_GetITCXOPChannelForRack(device, RACK_ONE)
					hwTTLRef[index] = index
					Make/FREE/D guiTTLRef = {NaN, 1, NaN, 3, NaN, 5, 6, NaN}
				else
					Make/FREE/D guiTTLRef = {NaN, 1, NaN, 3, NaN, NaN, NaN, NaN}
				endif
			endif

			CHECK_EQUAL_WAVES(guiTTLChannels, guiTTLRef)
			CHECK_EQUAL_WAVES(hwTTLChannels, hwTTLRef)
		endfor
	endfor

	WAVE channelGUItoHW    = GetActiveChannels(numericalValues, textualValues, 0, XOP_CHANNEL_TYPE_TTL, TTLmode = TTL_GUITOHW_CHANNEL)
	WAVE channelGUItoHWRef = GetActiveChannelMapTTLGUIToHW()
	WAVE channelHWtoGUI    = GetActiveChannels(numericalValues, textualValues, 0, XOP_CHANNEL_TYPE_TTL, TTLmode = TTL_HWTOGUI_CHANNEL)
	WAVE channelHWtoGUIRef = GetActiveChannelMapTTLHWToGUI()
	if(hardwareType == HARDWARE_NI_DAC)
		channelGUItoHWRef[1][%HWCHANNEL] = 1
		channelGUItoHWRef[3][%HWCHANNEL] = 3
		channelGUItoHWRef[5][%HWCHANNEL] = 5
		channelGUItoHWRef[6][%HWCHANNEL] = 6
		CHECK_EQUAL_WAVES(channelGUItoHWRef, channelGUItoHW)
		channelHWtoGUIRef[1][] = 1
		channelHWtoGUIRef[3][] = 3
		channelHWtoGUIRef[5][] = 5
		channelHWtoGUIRef[6][] = 6
		CHECK_EQUAL_WAVES(channelHWtoGUIRef, channelHWtoGUI)
	elseif(hardwareType == HARDWARE_ITC_DAC)
		if(IsITC1600(device))
			channelGUItoHWRef[1][%HWCHANNEL] = HARDWARE_ITC_TTL_1600_RACK_ZERO
			channelGUItoHWRef[3][%HWCHANNEL] = HARDWARE_ITC_TTL_1600_RACK_ZERO
			channelGUItoHWRef[5][%HWCHANNEL] = HARDWARE_ITC_TTL_1600_RACK_ONE
			channelGUItoHWRef[6][%HWCHANNEL] = HARDWARE_ITC_TTL_1600_RACK_ONE
			channelGUItoHWRef[1][%TTLBITNR]  = 1
			channelGUItoHWRef[3][%TTLBITNR]  = 3
			channelGUItoHWRef[5][%TTLBITNR]  = 1
			channelGUItoHWRef[6][%TTLBITNR]  = 2
			CHECK_EQUAL_WAVES(channelGUItoHWRef, channelGUItoHW)
			channelHWtoGUIRef[HARDWARE_ITC_TTL_1600_RACK_ZERO][1] = 1
			channelHWtoGUIRef[HARDWARE_ITC_TTL_1600_RACK_ZERO][3] = 3
			channelHWtoGUIRef[HARDWARE_ITC_TTL_1600_RACK_ONE][1]  = 5
			channelHWtoGUIRef[HARDWARE_ITC_TTL_1600_RACK_ONE][2]  = 6
			CHECK_EQUAL_WAVES(channelHWtoGUIRef, channelHWtoGUI)
		else
			channelGUItoHWRef[1][%HWCHANNEL] = HARDWARE_ITC_TTL_DEF_RACK_ZERO
			channelGUItoHWRef[3][%HWCHANNEL] = HARDWARE_ITC_TTL_DEF_RACK_ZERO
			channelGUItoHWRef[1][%TTLBITNR]  = 1
			channelGUItoHWRef[3][%TTLBITNR]  = 3
			CHECK_EQUAL_WAVES(channelGUItoHWRef, channelGUItoHW)
			channelHWtoGUIRef[HARDWARE_ITC_TTL_DEF_RACK_ZERO][1] = 1
			channelHWtoGUIRef[HARDWARE_ITC_TTL_DEF_RACK_ZERO][3] = 3
			CHECK_EQUAL_WAVES(channelHWtoGUIRef, channelHWtoGUI)
		endif
	endif

	if(DoExpensiveChecks())
		TestNwbExportV1()
		TestNwbExportV2()
	endif
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function CheckSamplingInterval1([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG1"                      + \
	                             "__HS0_DA0_AD0_CM:VC:_ST:StimulusSetA_DA_0:")

	AcquireData_NG(s, str)
End

static Function CheckSamplingInterval1_REENTRY([str])
	string str

	variable sweepNo, sampInt, sampIntMult, fixedFreqAcq, expectedSampInt

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 1)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, 0)

	WAVE/Z sweepWave = GetSweepWave(str, sweepNo)
	CHECK_WAVE(sweepWave, NORMAL_WAVE)

	WAVE/Z configWave = GetConfigWave(sweepWave)
	CHECK_WAVE(configWave, NORMAL_WAVE)

	sampInt = GetSamplingInterval(configWave, XOP_CHANNEL_TYPE_ADC)
	CHECK_CLOSE_VAR(sampInt, GetMinSamplingInterval(unit = "µs"), tol = 1e-6)

	WAVE numericalValues = GetLBNumericalValues(str)

	sampInt         = GetLastSettingIndep(numericalValues, sweepNo, "Sampling interval AD", DATA_ACQUISITION_MODE)
	expectedSampInt = GetMinSamplingInterval(unit = "ms")
	CHECK_CLOSE_VAR(sampInt, expectedSampInt, tol = 1e-6)

	sampIntMult = GetLastSettingIndep(numericalValues, sweepNo, "Sampling interval multiplier", DATA_ACQUISITION_MODE)
	CHECK_EQUAL_VAR(sampIntMult, 1)

	fixedFreqAcq = GetLastSettingIndep(numericalValues, sweepNo, "Fixed frequency acquisition", DATA_ACQUISITION_MODE)
	CHECK_EQUAL_VAR(fixedFreqAcq, NaN)

	WAVE channelAD = ResolveSweepChannel(sweepWave, GetFirstADCChannelIndex(configWave))
	CHECK_EQUAL_VAR(DimOffset(channelAD, ROWS), 0)
	CHECK_CLOSE_VAR(DimDelta(channelAD, ROWS), expectedSampInt, tol = 1e-6)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function CheckSamplingInterval2([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG1_SIM8"                 + \
	                             "__HS0_DA0_AD0_CM:VC:_ST:StimulusSetA_DA_0:")

	AcquireData_NG(s, str)
End

static Function CheckSamplingInterval2_REENTRY([str])
	string str

	variable sweepNo, sampInt, sampIntMult, fixedFreqAcq, expectedSampInt

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 1)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, 0)

	WAVE/Z sweepWave = GetSweepWave(str, sweepNo)
	CHECK_WAVE(sweepWave, NORMAL_WAVE)

	WAVE/Z configWave = GetConfigWave(sweepWave)
	CHECK_WAVE(configWave, NORMAL_WAVE)

	sampInt = GetSamplingInterval(configWave, XOP_CHANNEL_TYPE_ADC)
	CHECK_CLOSE_VAR(sampInt, GetMinSamplingInterval(unit = "µs") * 8, tol = 1e-6)

	WAVE numericalValues = GetLBNumericalValues(str)

	sampInt         = GetLastSettingIndep(numericalValues, sweepNo, "Sampling interval AD", DATA_ACQUISITION_MODE)
	expectedSampInt = GetMinSamplingInterval(unit = "ms") * 8
	CHECK_CLOSE_VAR(sampInt, expectedSampInt, tol = 1e-6)

	sampIntMult = GetLastSettingIndep(numericalValues, sweepNo, "Sampling interval multiplier", DATA_ACQUISITION_MODE)
	CHECK_EQUAL_VAR(sampIntMult, 8)

	fixedFreqAcq = GetLastSettingIndep(numericalValues, sweepNo, "Fixed frequency acquisition", DATA_ACQUISITION_MODE)
	CHECK_EQUAL_VAR(fixedFreqAcq, NaN)

	WAVE channelAD = ResolveSweepChannel(sweepWave, GetFirstADCChannelIndex(configWave))
	CHECK_EQUAL_VAR(DimOffset(channelAD, ROWS), 0)
	CHECK_CLOSE_VAR(DimDelta(channelAD, ROWS), expectedSampInt, tol = 1e-6)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function CheckSamplingInterval3([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG1_FFR:25:"              + \
	                             "__HS0_DA0_AD0_CM:VC:_ST:StimulusSetA_DA_0:")

	AcquireData_NG(s, str)
End

static Function CheckSamplingInterval3_REENTRY([str])
	string str

	variable sweepNo, sampInt, sampIntMult, fixedFreqAcq, expectedSampInt
	variable FFR = 25

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 1)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, 0)

	WAVE/Z sweepWave = GetSweepWave(str, sweepNo)
	CHECK_WAVE(sweepWave, NORMAL_WAVE)

	WAVE/Z configWave = GetConfigWave(sweepWave)
	CHECK_WAVE(configWave, NORMAL_WAVE)

	sampInt = GetSamplingInterval(configWave, XOP_CHANNEL_TYPE_ADC)
	CHECK_CLOSE_VAR(sampInt, 1 / FFR * MILLI_TO_MICRO, tol = 1e-6)

	WAVE numericalValues = GetLBNumericalValues(str)

	sampInt         = GetLastSettingIndep(numericalValues, sweepNo, "Sampling interval AD", DATA_ACQUISITION_MODE)
	expectedSampInt = 1 / FFR
	CHECK_CLOSE_VAR(sampInt, expectedSampInt, tol = 1e-6)

	sampIntMult = GetLastSettingIndep(numericalValues, sweepNo, "Sampling interval multiplier", DATA_ACQUISITION_MODE)
	CHECK_EQUAL_VAR(sampIntMult, 1)

	fixedFreqAcq = GetLastSettingIndep(numericalValues, sweepNo, "Fixed frequency acquisition", DATA_ACQUISITION_MODE)
	CHECK_EQUAL_VAR(fixedFreqAcq, FFR)

	WAVE channelAD = ResolveSweepChannel(sweepWave, GetFirstADCChannelIndex(configWave))
	CHECK_EQUAL_VAR(DimOffset(channelAD, ROWS), 0)
	CHECK_CLOSE_VAR(DimDelta(channelAD, ROWS), expectedSampInt, tol = 1e-6)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function ChangeCMDuringSweep([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG1"                         + \
	                             "__HS0_DA0_AD0_CM:VC:_ST:StimulusSetA_DA_0:" + \
	                             "__HS1_DA1_AD1_CM:VC:_ST:StimulusSetC_DA_0:")

	CtrlNamedBackGround ChangeClampModeDuringSweep, start, period=30, proc=ClampModeDuringSweep_IGNORE

	AcquireData_NG(s, str)
End

static Function ChangeCMDuringSweep_REENTRY([str])
	string str

	variable sweepNo
	string   ctrl

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 3)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, 2)

	ctrl = DAP_GetClampModeControl(V_CLAMP_MODE, 0)
	CHECK_EQUAL_VAR(GetCheckBoxState(str, ctrl), 1)

	ctrl = DAP_GetClampModeControl(I_CLAMP_MODE, 1)
	CHECK_EQUAL_VAR(GetCheckBoxState(str, ctrl), 1)

	WAVE numericalValues = GetLBNumericalValues(str)

	WAVE clampMode = GetLastSetting(numericalValues, 0, CLAMPMODE_ENTRY_KEY, DATA_ACQUISITION_MODE)
	CHECK_EQUAL_WAVES(clampMode, {V_CLAMP_MODE, V_CLAMP_MODE, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	WAVE clampMode = GetLastSetting(numericalValues, 1, CLAMPMODE_ENTRY_KEY, DATA_ACQUISITION_MODE)
	CHECK_EQUAL_WAVES(clampMode, {V_CLAMP_MODE, I_CLAMP_MODE, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	WAVE clampMode = GetLastSetting(numericalValues, 2, CLAMPMODE_ENTRY_KEY, DATA_ACQUISITION_MODE)
	CHECK_EQUAL_WAVES(clampMode, {V_CLAMP_MODE, I_CLAMP_MODE, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)
End

static Function ChangeCMDuringSweepWMS_PreAcq(device)
	string device

	string ctrl

	ctrl = GetPanelControl(CHANNEL_INDEX_ALL_I_CLAMP, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE)
	PGC_SetAndActivateControl(device, ctrl, str = "StimulusSetE_DA_0")

	ctrl = GetPanelControl(CHANNEL_INDEX_ALL_V_CLAMP, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE)
	PGC_SetAndActivateControl(device, ctrl, str = "StimulusSetF_DA_0")

	// reset to original stimulus sets
	ctrl = GetPanelControl(0, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE)
	PGC_SetAndActivateControl(device, ctrl, str = "StimulusSetA_DA_0")

	ctrl = GetPanelControl(1, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE)
	PGC_SetAndActivateControl(device, ctrl, str = "StimulusSetC_DA_0")

	PGC_SetAndActivateControl(device, "check_DA_applyOnModeSwitch", val = 1)

	CtrlNamedBackGround ChangeClampModeDuringSweep, start, period=30, proc=ClampModeDuringSweep_IGNORE
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function ChangeCMDuringSweepWMS([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG1"                         + \
	                             "__HS0_DA0_AD0_CM:VC:_ST:StimulusSetA_DA_0:" + \
	                             "__HS1_DA1_AD1_CM:VC:_ST:StimulusSetC_DA_0:")

	AcquireData_NG(s, str)
End

static Function ChangeCMDuringSweepWMS_REENTRY([str])
	string str

	variable sweepNo
	string   ctrl

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 3)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, 2)

	ctrl = DAP_GetClampModeControl(V_CLAMP_MODE, 0)
	CHECK_EQUAL_VAR(GetCheckBoxState(str, ctrl), 1)

	ctrl = DAP_GetClampModeControl(I_CLAMP_MODE, 1)
	CHECK_EQUAL_VAR(GetCheckBoxState(str, ctrl), 1)

	WAVE numericalValues = GetLBNumericalValues(str)

	WAVE clampMode = GetLastSetting(numericalValues, 0, CLAMPMODE_ENTRY_KEY, DATA_ACQUISITION_MODE)
	CHECK_EQUAL_WAVES(clampMode, {V_CLAMP_MODE, V_CLAMP_MODE, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	WAVE clampMode = GetLastSetting(numericalValues, 1, CLAMPMODE_ENTRY_KEY, DATA_ACQUISITION_MODE)
	CHECK_EQUAL_WAVES(clampMode, {V_CLAMP_MODE, I_CLAMP_MODE, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	WAVE clampMode = GetLastSetting(numericalValues, 2, CLAMPMODE_ENTRY_KEY, DATA_ACQUISITION_MODE)
	CHECK_EQUAL_WAVES(clampMode, {V_CLAMP_MODE, I_CLAMP_MODE, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	WAVE/T textualValues   = GetLBTextualValues(str)
	WAVE   numericalValues = GetLBNumericalValues(str)

	// the stimsets are not changed as this is delayed clamp mode change in action
	WAVE/T/Z foundStimSets = GetLastSettingTextEachRAC(numericalValues, textualValues, sweepNo, STIM_WAVE_NAME_KEY, 0, DATA_ACQUISITION_MODE)
	REQUIRE_WAVE(foundStimSets, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(foundStimSets, {"StimulusSetA_DA_0", "StimulusSetA_DA_0", "StimulusSetA_DA_0"})

	WAVE/T/Z foundStimSets = GetLastSettingTextEachRAC(numericalValues, textualValues, sweepNo, STIM_WAVE_NAME_KEY, 1, DATA_ACQUISITION_MODE)
	REQUIRE_WAVE(foundStimSets, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(foundStimSets, {"StimulusSetC_DA_0", "StimulusSetC_DA_0", "StimulusSetC_DA_0"})
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function ChangeCMDuringSweepNoRA([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG1"                         + \
	                             "__HS0_DA0_AD0_CM:VC:_ST:StimulusSetA_DA_0:" + \
	                             "__HS1_DA1_AD1_CM:VC:_ST:StimulusSetC_DA_0:")

	CtrlNamedBackGround ChangeClampModeDuringSweep, start, period=30, proc=ClampModeDuringSweep_IGNORE

	AcquireData_NG(s, str)
End

static Function ChangeCMDuringSweepNoRA_REENTRY([str])
	string str

	variable sweepNo
	string   ctrl

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 1)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, 0)

	ctrl = DAP_GetClampModeControl(V_CLAMP_MODE, 0)
	CHECK_EQUAL_VAR(GetCheckBoxState(str, ctrl), 1)

	ctrl = DAP_GetClampModeControl(I_CLAMP_MODE, 1)
	CHECK_EQUAL_VAR(GetCheckBoxState(str, ctrl), 1)

	WAVE numericalValues = GetLBNumericalValues(str)

	WAVE clampMode = GetLastSetting(numericalValues, 0, CLAMPMODE_ENTRY_KEY, DATA_ACQUISITION_MODE)
	CHECK_EQUAL_WAVES(clampMode, {V_CLAMP_MODE, V_CLAMP_MODE, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)
End

static Function ChangeCMDuringITI_PreAcq(device)
	string device

	CtrlNamedBackGround ChangeClampModeDuringSweep, start, period=30, proc=ClampModeDuringITI_IGNORE
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function ChangeCMDuringITI([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG1_GSI0_ITI5_TPI0"          + \
	                             "__HS0_DA0_AD0_CM:VC:_ST:StimulusSetA_DA_0:" + \
	                             "__HS1_DA1_AD1_CM:VC:_ST:StimulusSetC_DA_0:")

	AcquireData_NG(s, str)
End

static Function ChangeCMDuringITI_REENTRY([str])
	string str

	variable sweepNo
	string   ctrl

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 3)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, 2)

	ctrl = DAP_GetClampModeControl(V_CLAMP_MODE, 0)
	CHECK_EQUAL_VAR(GetCheckBoxState(str, ctrl), 1)

	ctrl = DAP_GetClampModeControl(I_CLAMP_MODE, 1)
	CHECK_EQUAL_VAR(GetCheckBoxState(str, ctrl), 1)

	WAVE numericalValues = GetLBNumericalValues(str)

	WAVE clampMode = GetLastSetting(numericalValues, 0, CLAMPMODE_ENTRY_KEY, DATA_ACQUISITION_MODE)
	CHECK_EQUAL_WAVES(clampMode, {V_CLAMP_MODE, V_CLAMP_MODE, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	WAVE clampMode = GetLastSetting(numericalValues, 1, CLAMPMODE_ENTRY_KEY, DATA_ACQUISITION_MODE)
	CHECK_EQUAL_WAVES(clampMode, {V_CLAMP_MODE, I_CLAMP_MODE, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	WAVE clampMode = GetLastSetting(numericalValues, 2, CLAMPMODE_ENTRY_KEY, DATA_ACQUISITION_MODE)
	CHECK_EQUAL_WAVES(clampMode, {V_CLAMP_MODE, I_CLAMP_MODE, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function ChangeCMDuringITIWithTP([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG1_GSI0_ITI5_TPI1"          + \
	                             "__HS0_DA0_AD0_CM:VC:_ST:StimulusSetA_DA_0:" + \
	                             "__HS1_DA1_AD1_CM:VC:_ST:StimulusSetC_DA_0:")

	RegisterUTFMonitor(TASKNAMES + "DAQWatchdog;TPWatchdog;ChangeClampModeDuringSweep", BACKGROUNDMONMODE_AND, \
	                   "BasicHardwareTests#ChangeCMDuringITIWithTP_REENTRY", timeout = 600)

	CtrlNamedBackGround ChangeClampModeDuringSweep, start, period=10, proc=ClampModeDuringITI_IGNORE

	AcquireData_NG(s, str)
End

static Function ChangeCMDuringITIWithTP_REENTRY([str])
	string str

	variable sweepNo
	string   ctrl

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 3)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, 2)

	ctrl = DAP_GetClampModeControl(V_CLAMP_MODE, 0)
	CHECK_EQUAL_VAR(GetCheckBoxState(str, ctrl), 1)

	ctrl = DAP_GetClampModeControl(I_CLAMP_MODE, 1)
	CHECK_EQUAL_VAR(GetCheckBoxState(str, ctrl), 1)

	WAVE numericalValues = GetLBNumericalValues(str)

	WAVE clampMode = GetLastSetting(numericalValues, 0, CLAMPMODE_ENTRY_KEY, DATA_ACQUISITION_MODE)
	CHECK_EQUAL_WAVES(clampMode, {V_CLAMP_MODE, V_CLAMP_MODE, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	WAVE clampMode = GetLastSetting(numericalValues, 1, CLAMPMODE_ENTRY_KEY, DATA_ACQUISITION_MODE)
	CHECK_EQUAL_WAVES(clampMode, {V_CLAMP_MODE, I_CLAMP_MODE, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	WAVE clampMode = GetLastSetting(numericalValues, 2, CLAMPMODE_ENTRY_KEY, DATA_ACQUISITION_MODE)
	CHECK_EQUAL_WAVES(clampMode, {V_CLAMP_MODE, I_CLAMP_MODE, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)
End

static Function AutoPipetteOffsetIgnoresApplyOnModeSwitch_PreAcq(device)
	string device

	string ctrl

	ctrl = GetPanelControl(CHANNEL_INDEX_ALL_I_CLAMP, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE)
	PGC_SetAndActivateControl(device, ctrl, str = "StimulusSetE_DA_0")

	ctrl = GetPanelControl(CHANNEL_INDEX_ALL_V_CLAMP, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE)
	PGC_SetAndActivateControl(device, ctrl, str = "StimulusSetF_DA_0")

	// reset to original stimulus sets
	ctrl = GetPanelControl(0, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE)
	PGC_SetAndActivateControl(device, ctrl, str = "StimulusSetA_DA_0")

	ctrl = GetPanelControl(1, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE)
	PGC_SetAndActivateControl(device, ctrl, str = "StimulusSetC_DA_0")

	PGC_SetAndActivateControl(device, "check_DA_applyOnModeSwitch", val = 1)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function AutoPipetteOffsetIgnoresApplyOnModeSwitch([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG1_TP1"                     + \
	                             "__HS0_DA0_AD0_CM:VC:_ST:StimulusSetA_DA_0:" + \
	                             "__HS1_DA1_AD1_CM:VC:_ST:StimulusSetC_DA_0:")

	CtrlNamedBackGround DelayReentry, start=(ticks + 300), period=60, proc=AutoPipetteOffsetAndStopTP_IGNORE
	RegisterUTFMonitor("DelayReentry", BACKGROUNDMONMODE_AND, "BasicHardwareTests#AutoPipetteOffsetIgnoresApplyOnModeSwitch_REENTRY", timeout = 600, failOnTimeout = 1)

	AcquireData_NG(s, str)
End

static Function AutoPipetteOffsetIgnoresApplyOnModeSwitch_REENTRY([str])
	string str

	variable sweepNo
	string ctrl, stimset, expected

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 0)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, NaN)

	CHECK_EQUAL_VAR(GetCheckBoxState(str, "check_DA_applyOnModeSwitch"), 1)

	ctrl     = GetPanelControl(0, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE)
	stimset  = GetPopupMenuString(str, ctrl)
	expected = "StimulusSetA_DA_0"
	CHECK_EQUAL_STR(stimset, expected)

	ctrl     = GetPanelControl(1, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE)
	stimset  = GetPopupMenuString(str, ctrl)
	expected = "StimulusSetC_DA_0"
	CHECK_EQUAL_STR(stimset, expected)
End

static Function HasNaNAsDefaultWhenAborted_PreAcq(device)
	string device

	CtrlNamedBackGround Abort_ITI_PressAcq, start, period=30, proc=StopAcq_IGNORE
End

// check default values for data when aborting DAQ
// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function HasNaNAsDefaultWhenAborted([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG1"                         + \
	                             "__HS0_DA0_AD0_CM:VC:_ST:StimulusSetA_DA_0:" + \
	                             "__HS1_DA1_AD1_CM:VC:_ST:StimulusSetC_DA_0:" + \
	                             "__TTL1_ST:StimulusSetA_TTL_0:")

	AcquireData_NG(s, str)
End

static Function HasNaNAsDefaultWhenAborted_REENTRY([str])
	string str

	variable sweepNo, i, numChannels, startIndexNaN

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 1)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, 0)

	WAVE/Z sweepWave = GetSweepWave(str, sweepNo)
	CHECK_WAVE(sweepWave, TEXT_WAVE)

	WAVE config    = GetConfigWave(sweepWave)
	WAVE channelAD = ResolveSweepChannel(sweepWave, GetFirstADCChannelIndex(config))
	FindValue/FNAN/RMD=[][0] channelAD
	startIndexNaN = V_row
	CHECK_GE_VAR(startIndexNaN, 0)

	// check that we have NaNs for all columns starting from the first unacquired point
	numChannels = DimSize(sweepWave, ROWS)
	for(i = 0; i < numChannels; i += 1)
		WAVE channel = ResolveSweepChannel(sweepWave, i)
		Duplicate/FREE/RMD=[startIndexNaN,] channel, unacquiredData
		WaveStats/Q/M=1 unacquiredData
		CHECK_EQUAL_VAR(V_numNans, DimSize(unacquiredData, ROWS))
		CHECK_EQUAL_VAR(V_npnts, 0)
	endfor
End

static Function UnassocChannelsDuplicatedEntry_PreAcq(device)
	string device

	// enable HS1 with associated DA/AD channels
	PGC_SetAndActivateControl(device, GetPanelControl(1, CHANNEL_TYPE_HEADSTAGE, CHANNEL_CONTROL_CHECK), val = 1)

	// cut assocication
	PGC_SetAndActivateControl(device, "Popup_Settings_HeadStage", str = "1")
	PGC_SetAndActivateControl(device, "button_Hardware_ClearChanConn")

	// disable HS1
	PGC_SetAndActivateControl(device, GetPanelControl(1, CHANNEL_TYPE_HEADSTAGE, CHANNEL_CONTROL_CHECK), val = 0)

	// enable HS2 with associated DA/AD channels
	PGC_SetAndActivateControl(device, GetPanelControl(2, CHANNEL_TYPE_HEADSTAGE, CHANNEL_CONTROL_CHECK), val = 1)

	// cut assocication
	PGC_SetAndActivateControl(device, "Popup_Settings_HeadStage", str = "2")
	PGC_SetAndActivateControl(device, "button_Hardware_ClearChanConn")

	// disable HS2
	PGC_SetAndActivateControl(device, GetPanelControl(2, CHANNEL_TYPE_HEADSTAGE, CHANNEL_CONTROL_CHECK), val = 0)

	PGC_SetAndActivateControl(device, GetPanelControl(1, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE), str = "StimulusSetA*")

	// disable AD1
	PGC_SetAndActivateControl(device, GetPanelControl(1, CHANNEL_TYPE_ADC, CHANNEL_CONTROL_CHECK), val = 0)

	// disable DA2
	PGC_SetAndActivateControl(device, GetPanelControl(2, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_CHECK), val = 0)
End

// Check that unassociated LBN entries for DA/AD don't overlap
//
// 1 HS
// DA1 unassociated
// AD2 unsassociated
//
// Now we should not find any unassoc labnotebook keys which only differ in the channel number.
//
// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function UnassocChannelsDuplicatedEntry([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG1"                         + \
	                             "__HS0_DA0_AD0_CM:VC:_ST:StimulusSetA_DA_0:" + \
	                             "__HS1_DA1_AD1_CM:VC:_ST:StimulusSetC_DA_0:")

	AcquireData_NG(s, str)
End

static Function UnassocChannelsDuplicatedEntry_REENTRY([str])
	string str

	variable sweepNo, i, numEntries
	string unassoc

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 1)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, 0)

	Make/WAVE/FREE keys = {GetLBNumericalKeys(str), GetLBTextualKeys(str)}

	numEntries = DimSize(keys, ROWS)
	for(i = 0; i < numEntries; i += 1)
		WAVE/T wv = keys[i]
		Duplicate/T/RMD=[0]/FREE wv, singleRow
		Redimension/N=(DimSize(singleRow, ROWS) * DimSize(singleRow, COLS))/E=1 singleRow
		Make/FREE/T unassocEntries
		Grep/E=".* u_(AD|DA)\d$" singleRow as unassocEntries
		CHECK(!V_Flag)
		CHECK_GT_VAR(V_Value, 0)

		unassocEntries[] = RemoveTrailingNumber_IGNORE(unassocEntries[p])

		FindDuplicates/FREE/Z/DT=dups unassocEntries
		CHECK_EQUAL_VAR(DimSize(dups, ROWS), 0)
	endfor
End

static Function/S RemoveTrailingNumber_IGNORE(str)
	string str

	CHECK_EQUAL_VAR(ItemsInList(str, "_"), 2)

	return StringFromList(0, str, "_")
End

static Function CheckLabnotebookKeys_IGNORE(keys, values)
	WAVE/T keys
	WAVE   values

	string lblKeys, lblValues, entry
	variable i, numKeys

	numKeys = DimSize(keys, COLS)
	for(i = 0; i < numKeys; i += 1)
		entry     = keys[0][i]
		lblKeys   = GetDimLabel(keys, COLS, i)
		lblValues = GetDimLabel(values, COLS, i)
		CHECK_EQUAL_STR(entry, lblValues)
		CHECK_EQUAL_STR(entry, lblKeys)
	endfor
End

static Function LabnotebookEntriesCanBeQueried_PreAcq(device)
	string device

	PGC_SetAndActivateControl(device, DAP_GetClampModeControl(I_CLAMP_MODE, 1), val = 1)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function LabnotebookEntriesCanBeQueried([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG1"                         + \
	                             "__HS0_DA0_AD0_CM:VC:_ST:StimulusSetA_DA_0:" + \
	                             "__HS1_DA1_AD1_CM:VC:_ST:StimulusSetC_DA_0:")

	AcquireData_NG(s, str)
End

static Function LabnotebookEntriesCanBeQueried_REENTRY([str])
	string str

	variable sweepNo, numKeys, i, j

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 1)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, 0)

	WAVE numericalKeys   = GetLBNumericalKeys(str)
	WAVE numericalValues = GetLBNumericalValues(str)

	CheckLabnotebookKeys_IGNORE(numericalKeys, numericalValues)

	WAVE textualKeys   = GetLBTextualKeys(str)
	WAVE textualValues = GetLBTextualValues(str)

	CheckLabnotebookKeys_IGNORE(textualKeys, textualValues)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function DataBrowserCreatesBackupsByDefault([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG1_DB1"                     + \
	                             "__HS0_DA0_AD0_CM:VC:_ST:StimulusSetA_DA_0:" + \
	                             "__HS1_DA1_AD1_CM:VC:_ST:StimulusSetC_DA_0:")

	AcquireData_NG(s, str)
End

static Function DataBrowserCreatesBackupsByDefault_REENTRY([str])
	string str

	variable sweepNo, numEntries, i
	string list, name

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 1)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, 0)

	WAVE  sweepWave         = GetSweepWave(str, 0)
	DFREF sweepFolder       = GetWavesDataFolderDFR(sweepWave)
	DFREF singleSweepFolder = GetSingleSweepFolder(sweepFolder, 0)

	// check that all non-backup waves in singleSweepFolder have a backup
	list       = GetListOfObjects(singleSweepFolder, "^[A-Za-z]{1,}_[0-9]$")
	numEntries = ItemsInList(list)
	CHECK_GT_VAR(numEntries, 0)

	for(i = 0; i < numEntries; i += 1)
		name = StringFromList(i, list)
		WAVE/SDFR=singleSweepFolder/Z wv = $name
		CHECK_WAVE(wv, NORMAL_WAVE)
		WAVE/Z bak = GetBackupWave(wv)
		CHECK_WAVE(bak, NORMAL_WAVE)
	endfor
End

/// Test incremental labnotebook cache updates
/// We have two sweeps in total. After the first sweeps we query LBN settings
/// for the next sweep, we get all no-matches. But some of these no-matches are stored in
/// the LBN cache waves. After the second sweep these LBN entries can now be queried thus "proving"
/// that the LBN caches were successfully updated.
///
/// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function IncrementalLabnotebookCacheUpdate([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG1"                          + \
	                             "__HS0_DA0_AD0_CM:VC:_ST:IncLabCacheUpdat_DA_0:")

	AcquireData_NG(s, str)
End

static Function IncrementalLabnotebookCacheUpdate_REENTRY([str])
	string str

	variable sweepNo

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 2)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, 1)

	WAVE anaFuncTracker = TrackAnalysisFunctionCalls()

	CHECK_EQUAL_VAR(anaFuncTracker[POST_SWEEP_EVENT], 2)
End

/// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function TestAcquiringNewDataOnOldData([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG1"                         + \
	                             "__HS0_DA0_AD0_CM:VC:_ST:StimulusSetA_DA_0:" + \
	                             "__HS1_DA1_AD1_CM:VC:_ST:StimulusSetC_DA_0:")

	AcquireData_NG(s, str)
End

static Function TestAcquiringNewDataOnOldData_REENTRY([str])
	string str

	variable sweepNo

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 3)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, 2)

	KillWindow $str

	// restart data acquisition
	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG1"                         + \
	                             "__HS0_DA0_AD0_CM:VC:_ST:StimulusSetA_DA_0:" + \
	                             "__HS1_DA1_AD1_CM:VC:_ST:StimulusSetC_DA_0:")
	AcquireData_NG(s, str)

	RegisterReentryFunction("BasicHardwareTests#" + GetRTStackInfo(1))
End

static Function TestAcquiringNewDataOnOldData_REENTRY_REENTRY([str])
	string str

	variable sweepNo

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 6)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, 5)
End

static Function AsyncAcquisitionLBN_PreAcq(string device)

	string ctrl
	variable channel = 2

	ctrl = GetPanelControl(channel, CHANNEL_TYPE_ASYNC, CHANNEL_CONTROL_CHECK)
	PGC_SetAndActivateControl(device, ctrl, val = CHECKBOX_SELECTED)

	ctrl = GetPanelControl(channel, CHANNEL_TYPE_ALARM, CHANNEL_CONTROL_CHECK)
	PGC_SetAndActivateControl(device, ctrl, val = CHECKBOX_SELECTED)

	ctrl = GetPanelControl(channel, CHANNEL_TYPE_ASYNC, CHANNEL_CONTROL_GAIN)
	PGC_SetAndActivateControl(device, ctrl, val = 5)

	ctrl = GetPanelControl(channel, CHANNEL_TYPE_ASYNC, CHANNEL_CONTROL_ALARM_MIN)
	PGC_SetAndActivateControl(device, ctrl, val = 0.1)

	ctrl = GetPanelControl(channel, CHANNEL_TYPE_ASYNC, CHANNEL_CONTROL_ALARM_MAX)
	PGC_SetAndActivateControl(device, ctrl, val = 0.5)

	ctrl = GetPanelControl(channel, CHANNEL_TYPE_ASYNC, CHANNEL_CONTROL_TITLE)
	PGC_SetAndActivateControl(device, ctrl, str = "myTitle")

	ctrl = GetPanelControl(channel, CHANNEL_TYPE_ASYNC, CHANNEL_CONTROL_UNIT)
	PGC_SetAndActivateControl(device, ctrl, str = "myUnit")
End

/// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function AsyncAcquisitionLBN([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG1_DAQ1_TP0"                     + \
	                             "__HS0_DA0_AD0_CM:VC:_ST:StimulusSetA_DA_0:"      + \
	                             "__HS1_DA1_AD1_CM:IC:_ST:StimulusSetC_DA_0:_ASO0" + \
	                             "__TTL1_ST:StimulusSetA_TTL_0:"                   + \
	                             "__TTL3_ST:StimulusSetB_TTL_0:"                   + \
	                             "__TTL5_ST:StimulusSetC_TTL_0:"                   + \
	                             "__TTL6_ST:StimulusSetD_TTL_0:")

	AcquireData_NG(s, str)
End

static Function AsyncAcquisitionLBN_REENTRY([str])
	string str

	variable sweepNo, var
	string refStr, readStr

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 1)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, 0)

	WAVE numericalValues = GetLBNumericalValues(str)
	WAVE textualValues   = GetLBTextualValues(str)

	var = GetLastSettingIndep(numericalValues, 0, "Async 2 On/Off", DATA_ACQUISITION_MODE)
	CHECK_EQUAL_VAR(var, CHECKBOX_SELECTED)

	var = GetLastSettingIndep(numericalValues, 0, "Async 2 Gain", DATA_ACQUISITION_MODE)
	CHECK_EQUAL_VAR(var, 5)

	var = GetLastSettingIndep(numericalValues, 0, "Async Alarm 2 On/Off", DATA_ACQUISITION_MODE)
	CHECK_EQUAL_VAR(var, CHECKBOX_SELECTED)

	var = GetLastSettingIndep(numericalValues, 0, "Async Alarm 2 Min", DATA_ACQUISITION_MODE)
	CHECK_EQUAL_VAR(var, 0.1)

	var = GetLastSettingIndep(numericalValues, 0, "Async Alarm  2 Max", DATA_ACQUISITION_MODE)
	CHECK_EQUAL_VAR(var, 0.5)

	var = GetLastSettingIndep(numericalValues, 0, "Async Alarm 2 State", DATA_ACQUISITION_MODE)
	CHECK(IsFinite(var))

	var = GetLastSettingIndep(numericalValues, 0, "Async AD 2 [myTitle]", DATA_ACQUISITION_MODE)
	// we don't know if the alarm was triggered or not
	// but we also only care that the value is finite
	CHECK(IsFinite(var))

	readStr = GetLastSettingTextIndep(textualValues, 0, "Async AD2 Title", DATA_ACQUISITION_MODE)
	refStr  = "myTitle"
	CHECK_EQUAL_STR(refStr, readStr)

	readStr = GetLastSettingTextIndep(textualValues, 0, "Async AD2 Unit", DATA_ACQUISITION_MODE)
	refStr  = "myUnit"
	CHECK_EQUAL_STR(refStr, readStr)
End

/// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function CheckSettingsFails([str])
	string str

	STRUCT DAQSettings s
	// No active headstages
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG1_FAR0")

	try
		AcquireData_NG(s, str)
	catch
		PASS()
	endtry
End

static Function CheckSettingsFails_REENTRY([str])
	string   str
	variable sweepNo

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 0)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, NaN)
End

// // UTF_TD_GENERATOR v0:SingleMultiDeviceDAQ
// // UTF_TD_GENERATOR s0:DeviceNameGeneratorMD1
static Function CheckAcquisitionStates([STRUCT IUTF_MDATA &md])
	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD" + num2str(md.v0) + "_RA1_I0_L0_BKG1_GSI0_ITI5"                        + \
	                             "__HS0_DA0_AD0_CM:VC:_ST:StimulusSetC_DA_0:_AF:AcquisitionStateTrackingFunc:")

	CtrlNamedBackGround ExecuteDuringITI, start, period=30, proc=AddLabnotebookEntries_IGNORE

	AcquireData_NG(s, md.s0)
End

static Function CheckAcquisitionStates_REENTRY([STRUCT IUTF_MDATA &md])
	variable sweepNo, i
	string device

	device = md.s0

	CHECK_EQUAL_VAR(GetSetVariable(device, "SetVar_Sweep"), 2)

	sweepNo = AFH_GetLastSweepAcquired(device)
	CHECK_EQUAL_VAR(sweepNo, 1)

	// add entry for AS_INACTIVE
	Make/D/FREE/N=(LABNOTEBOOK_LAYER_COUNT) values = NaN
	Make/T/FREE/N=(LABNOTEBOOK_LAYER_COUNT) valuesText = ""
	values[0] = AS_INACTIVE
	ED_AddEntryToLabnotebook(device, "AcqStateTrackingValue_AS_INACTIVE", values)
	valuesText[0] = AS_StateToString(AS_INACTIVE)
	ED_AddEntryToLabnotebook(device, "AcqStateTrackingValue_AS_INACTIVE", valuesText)

	for(i = 0; i < AS_NUM_STATES; i += 1)
		switch(i)
			case AS_INACTIVE:
				CheckLBNEntries_IGNORE(device, 0, i, missing = 1)
				CheckLBNEntries_IGNORE(device, 1, i)
				break
			case AS_EARLY_CHECK:
				// no check possible for AS_EARLY_CHECK
				break
			case AS_PRE_DAQ:
				CheckLBNEntries_IGNORE(device, 0, i)
				CheckLBNEntries_IGNORE(device, 1, i, missing = 1)
				break
			case AS_PRE_SWEEP_CONFIG:
				CheckLBNEntries_IGNORE(device, 0, i)
				CheckLBNEntries_IGNORE(device, 1, i)
				break
			case AS_PRE_SWEEP:
				CheckLBNEntries_IGNORE(device, 0, i, missing = 1)
				CheckLBNEntries_IGNORE(device, 1, i, missing = 1)
				break
			case AS_MID_SWEEP:
				CheckLBNEntries_IGNORE(device, 0, i)
				CheckLBNEntries_IGNORE(device, 1, i)
				break
			case AS_POST_SWEEP:
				CheckLBNEntries_IGNORE(device, 0, i)
				CheckLBNEntries_IGNORE(device, 1, i)
				break
			case AS_ITI:
				CheckLBNEntries_IGNORE(device, 0, i)
				CheckLBNEntries_IGNORE(device, 1, i, missing = 1)
				break
			case AS_POST_DAQ:
				CheckLBNEntries_IGNORE(device, 0, i, missing = 1)
				CheckLBNEntries_IGNORE(device, 1, i)
				break
			default:
				FAIL()
		endswitch
	endfor

	CHECK_EQUAL_VAR(ROVar(GetAcquisitionState(device)), AS_INACTIVE)
	CHECK_EQUAL_VAR(AS_GetSweepNumber(device), NaN)
	CHECK_EQUAL_VAR(AS_GetSweepNumber(device, allowFallback = 1), sweepNo)
End

static Function CheckLBNEntries_IGNORE(string device, variable sweepNo, variable acqState, [variable missing])

	string name
	variable i, numEntries

	name = "USER_AcqStateTrackingValue_" + AS_StateToString(acqState)

	WAVE/T textualValues   = GetLBTextualValues(device)
	WAVE   numericalValues = GetLBNumericalValues(device)

	WAVE/Z entry     = GetLastSetting(numericalValues, sweepNo, name, UNKNOWN_MODE)
	WAVE/Z entryText = GetLastSetting(textualValues, sweepNo, name, UNKNOWN_MODE)

	if(!ParamIsDefault(missing) && missing == 1)
		CHECK_WAVE(entry, NULL_WAVE)
		CHECK_WAVE(entryText, NULL_WAVE)
		return NaN
	endif

	CHECK_WAVE(entry, NUMERIC_WAVE)
	CHECK_WAVE(entryText, TEXT_WAVE)

	CHECK_EQUAL_WAVES(entry, {acqState, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)
	CHECK_EQUAL_TEXTWAVES(entryText, {AS_StateToString(acqState), "", "", "", "", "", "", "", ""}, mode = WAVE_DATA)

	// check that the written entries have the correct acquisition state in the new AcquisitionState column
	Make/FREE/WAVE waves = {numericalValues, textualValues}

	numEntries = DimSize(waves, ROWS)
	for(i = 0; i < 2; i += 1)
		WAVE wv = waves[i]

		WAVE/Z indizesSweeps = FindIndizes(wv, colLabel = "SweepNum", var = sweepNo)
		CHECK_WAVE(indizesSweeps, FREE_WAVE)

		if(IsNumericWave(wv))
			WAVE/Z indizesEntry = FindIndizes(wv, colLabel = name, var = acqState)
		else
			WAVE/Z indizesEntry = FindIndizes(wv, colLabel = name, str = AS_StateToString(acqState))
		endif

		CHECK_WAVE(indizesEntry, FREE_WAVE)
		WAVE indizesEntryOneSweep = GetSetIntersection(indizesSweeps, indizesEntry)
		CHECK_GT_VAR(DimSize(indizesEntryOneSweep, ROWS), 0)

		// all entries in indizesEntryOneSweep must be in indizesAcqState
		WAVE/Z indizesAcqState = FindIndizes(wv, colLabel = "AcquisitionState", var = acqState)

		CHECK_WAVE(indizesAcqState, FREE_WAVE)
		WAVE/Z matches = GetSetIntersection(indizesEntryOneSweep, indizesAcqState)

		CHECK_EQUAL_WAVES(indizesEntryOneSweep, matches)
	endfor
End

static Function ConfigureFails_PreAcq(string device)

	string ctrl

	ctrl = GetPanelControl(0, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_SCALE)
	PGC_SetAndActivateControl(device, ctrl, val = 10000)
End

/// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function ConfigureFails([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG1"                         + \
	                             "__HS0_DA0_AD0_CM:VC:_ST:StimulusSetA_DA_0:" + \
	                             "__HS1_DA1_AD1_CM:VC:_ST:StimulusSetC_DA_0:")

	AcquireData_NG(s, str)
End

static Function ConfigureFails_REENTRY([str])
	string   str
	variable sweepNo

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 0)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, NaN)

	CheckDAQStopReason(str, DQ_STOP_REASON_CONFIG_FAILED)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function StopDAQDueToUnlocking([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG1_RES5_GSI0_ITI5"          + \
	                             "__HS0_DA0_AD0_CM:VC:_ST:StimulusSetA_DA_0:" + \
	                             "__HS1_DA1_AD1_CM:VC:_ST:StimulusSetC_DA_0:")

	AcquireData_NG(s, str)

	CtrlNamedBackGround UnlockDevice, start, period=30, proc=StopAcqByUnlocking_IGNORE
End

static Function StopDAQDueToUnlocking_REENTRY([str])
	string str

	NVAR runModeDAQ = $GetDataAcqRunMode(str)
	CHECK_EQUAL_VAR(runModeDAQ, DAQ_NOT_RUNNING)

	NVAR runModeTP = $GetTestpulseRunMode(str)
	CHECK_EQUAL_VAR(runModeTP, TEST_PULSE_NOT_RUNNING)

	CheckThatTestpulseRan_IGNORE(str)

	CheckDAQStopReason(str, DQ_STOP_REASON_UNLOCKED_DEVICE)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function StopDAQDueToUncompiled([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG1_RES5_GSI0_ITI5"          + \
	                             "__HS0_DA0_AD0_CM:VC:_ST:StimulusSetA_DA_0:" + \
	                             "__HS1_DA1_AD1_CM:VC:_ST:StimulusSetC_DA_0:")

	AcquireData_NG(s, str)

	CtrlNamedBackGround UncompileProcedures, start, period=30, proc=StopAcqByUncompiled_IGNORE
End

static Function StopDAQDueToUncompiled_REENTRY([str])
	string str

	NVAR runModeDAQ = $GetDataAcqRunMode(str)
	CHECK_EQUAL_VAR(runModeDAQ, DAQ_NOT_RUNNING)

	NVAR runModeTP = $GetTestpulseRunMode(str)
	CHECK_EQUAL_VAR(runModeTP, TEST_PULSE_NOT_RUNNING)

	CheckThatTestpulseRan_IGNORE(str)

	CheckDAQStopReason(str, DQ_STOP_REASON_UNCOMPILED)
End

// Roundtrip stimsets, this also leaves the NWBv2 file lying around
// for later validation.
//
// UTF_TD_GENERATOR MajorNWBVersions
static Function ExportStimsetsAndRoundtripThem([variable var])

	string baseFolder, nwbFile, discLocation
	variable numEntries, i

	[baseFolder, nwbFile] = GetUniqueNWBFileForExport(var)
	discLocation = baseFolder + nwbFile

	MIES_NWB#NWB_ExportAllStimsets(var, discLocation)

	GetFileFolderInfo/Q/Z discLocation
	REQUIRE(V_IsFile)

	DFREF dfr = GetWaveBuilderPath()
	KillOrMoveToTrash(dfr = GetWaveBuilderDataPath())
	MoveDataFolder dfr, :
	RenameDataFolder WaveBuilder, old

	KillOrMoveToTrash(dfr = GetMiesPath())

	NWB_LoadAllStimsets(filename = discLocation)

	DFREF dfr = GetWaveBuilderPath()
	KillOrMoveToTrash(dfr = GetWaveBuilderDataPath())
	MoveDataFolder dfr, :
	RenameDataFolder WaveBuilder, new

	WAVE/T oldWaves = ListToTextWave(GetListOfObjects(old, ".*", recursive = 1, fullPath = 1), ";")
	WAVE/T newWaves = ListToTextWave(GetListOfObjects(new, ".*", recursive = 1, fullPath = 1), ";")
	CHECK_EQUAL_VAR(DimSize(oldWaves, ROWS), DimSize(newWaves, ROWS))

	numEntries = DimSize(oldWaves, ROWS)
	CHECK_GT_VAR(numEntries, 0)

	for(i = 0; i < numEntries; i += 1)
		WAVE oldWave = $oldWaves[i]
		WAVE newWave = $newWaves[i]

		CHECK_EQUAL_WAVES(oldWave, newWave)
	endfor

	KillDataFolder/Z old
	KillDataFolder/Z new
End

static Function ExportIntoNWBSweepBySweep_PreAcq(string device)

	CHECK_EQUAL_VAR(GetCheckBoxState(device, "Check_Settings_NwbExport"), CHECKBOX_UNSELECTED)
	PGC_SetAndActivateControl(device, "Check_Settings_NwbExport", val = CHECKBOX_SELECTED)
End

/// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function ExportIntoNWBSweepBySweep([str])
	string str

	variable ref
	string   history

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG1"                         + \
	                             "__HS0_DA0_AD0_CM:VC:_ST:StimulusSetA_DA_0:" + \
	                             "__HS1_DA1_AD1_CM:VC:_ST:StimulusSetC_DA_0:")

	ref = CaptureHistoryStart()
	AcquireData_NG(s, str)
	history = CaptureHistory(ref, 1)
	CHECK_EMPTY_STR(history)
End

static Function ExportIntoNWBSweepBySweep_REENTRY([str])
	string str

	string experimentNwbFile, stimsets, acquisition, stimulus
	variable fileID, nwbVersion

	NWB_CloseNWBFile(str)
	experimentNwbFile = GetExperimentNWBFileForExport()
	REQUIRE(FileExists(experimentNwbFile))

	fileID     = H5_OpenFile(experimentNWBFile)
	nwbVersion = GetNWBMajorVersion(ReadNWBVersion(fileID))
	CHECK_EQUAL_VAR(nwbVersion, 2)

	stimsets = ReadStimsets(fileID)
	CHECK_PROPER_STR(stimsets)

	acquisition = ReadAcquisition(fileID, nwbVersion)
	CHECK_PROPER_STR(acquisition)

	stimulus = ReadStimulus(fileID)
	CHECK_PROPER_STR(stimulus)
	HDF5CloseFile fileID
End

static Function ExportOnlyCommentsIntoNWB_PreAcq(string device)

	PGC_SetAndActivateControl(device, "SetVar_DataAcq_Comment", str = "abcdefgh ijjkl")
End

/// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function ExportOnlyCommentsIntoNWB([string str])

	string discLocation, userComment, userCommentRef
	variable fileID

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG1_TP0_DAQ0"                + \
	                             "__HS0_DA0_AD0_CM:VC:_ST:StimulusSetA_DA_0:" + \
	                             "__HS1_DA1_AD1_CM:VC:_ST:StimulusSetC_DA_0:")

	AcquireData_NG(s, str)

	discLocation = TestNWBExportV2#TestFileExport()
	REQUIRE(FileExists(discLocation))

	fileID         = H5_OpenFile(discLocation)
	userComment    = TestNWBExportV2#TestUserComment(fileID, str)
	userCommentRef = "abcdefgh ijjkl"
	CHECK_GE_VAR(strsearch(userComment, userCommentRef, 0), 0)

	H5_CloseFile(fileID)
End

/// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function CheckPulseInfoGathering([string str])

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG1_TBP25"                    + \
	                             "__HS0_DA0_AD0_CM:VC:_ST:Y4_SRecovery_50H_DA_0:")

	AcquireData_NG(s, str)
End

static Function CheckPulseInfoGathering_REENTRY([string str])
	variable sweepNo

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 1)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, 0)

	WAVE/T   textualValues = GetLBTextualValues(str)
	WAVE/T/Z epochs        = GetLastSetting(textualValues, sweepNo, EPOCHS_ENTRY_KEY, DATA_ACQUISITION_MODE)

	WAVE/Z pulseInfos = MIES_PA#PA_RetrievePulseInfosFromEpochs(epochs[0])
	CHECK_WAVE(pulseInfos, NUMERIC_WAVE)

	// no zeros
	FindValue/V=0 pulseInfos
	CHECK_EQUAL_VAR(V_Value, -1)

	// no infinite values
	Wavestats/Q/M=1 pulseInfos
	CHECK_EQUAL_VAR(V_numInfs, 0)
	CHECK_EQUAL_VAR(V_numNaNs, 0)

	// check some values
	Duplicate/FREE/RMD=[9][] pulseInfos, pulseInfo_row9
	Redimension/N=(numpnts(pulseInfo_row9)) pulseInfo_row9
	CHECK_EQUAL_WAVES(pulseInfo_row9, {20, 826.505, 828.005}, mode = WAVE_DATA, tol = 1e-4)

	Duplicate/FREE/RMD=[25][] pulseInfos, pulseInfo_row25
	Redimension/N=(numpnts(pulseInfo_row25)) pulseInfo_row25
	CHECK_EQUAL_WAVES(pulseInfo_row25, {26.5433, 1373.55, 1375.05}, mode = WAVE_DATA, tol = 1e-4)

	Duplicate/FREE/RMD=[55][] pulseInfos, pulseInfo_row55
	Redimension/N=(numpnts(pulseInfo_row55)) pulseInfo_row55
	CHECK_EQUAL_WAVES(pulseInfo_row55, {29.6455, 2505.13, 2506.63}, mode = WAVE_DATA, tol = 1e-4)

	// check total number of pulses
	CHECK_EQUAL_VAR(DimSize(pulseInfos, ROWS), 60)
End

// // UTF_TD_GENERATOR v0:SingleMultiDeviceDAQ
// // UTF_TD_GENERATOR s0:DeviceNameGenerator
static Function RepeatedAcquisitionWithOneSweep([STRUCT IUTF_MDATA &md])
	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD" + num2str(md.v0) + "_RA1_I0_L0_BKG1" + \
	                             "__HS0_DA0_AD0_CM:VC:_ST:StimulusSetA_DA_0:")

	ST_SetStimsetParameter("StimulusSetA_DA_0", "Total number of steps", var = 1)

	AcquireData_NG(s, md.s0)
End

static Function RepeatedAcquisitionWithOneSweep_REENTRY([STRUCT IUTF_MDATA &md])

	CHECK_EQUAL_VAR(GetSetVariable(md.s0, "SetVar_Sweep"), 1)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function EnableIndexingInPostDAQ([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG1"                                         + \
	                             "__HS0_DA0_AD0_CM:VC:_ST:StimulusSetA_DA_0:_AF:EnableIndexing:")

	AcquireData_NG(s, str)
End

static Function EnableIndexingInPostDAQ_REENTRY([string str])
	string ctrl, stimset, expected

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 1)

	ctrl = GetSpecialControlLabel(CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE)

	stimset  = DAG_GetTextualValue(str, ctrl, index = 0)
	expected = "StimulusSetA_DA_0"
	CHECK_EQUAL_STR(stimset, expected)
End

static Function ScaleZeroWithCycling_PreAcq(string device)

	PGC_SetAndActivateControl(device, "check_Settings_ScalingZero", val = CHECKBOX_SELECTED)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function ScaleZeroWithCycling([string str])

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG1_RES2"                    + \
	                             "__HS0_DA0_AD0_CM:VC:_ST:StimulusSetA_DA_0:" + \
	                             "__HS1_DA1_AD1_CM:VC:_ST:StimulusSetC_DA_0:")

	AcquireData_NG(s, str)
End

static Function ScaleZeroWithCycling_REENTRY([string str])
	variable sweepNo

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 6)

	WAVE numericalValues = GetLBNumericalValues(str)
	sweepNo = 0

	WAVE/Z stimScale_HS0 = GetLastSettingEachRAC(numericalValues, sweepNo, "Stim Scale Factor", 0, DATA_ACQUISITION_MODE)
	CHECK_EQUAL_WAVES(stimScale_HS0, {1, 1, 1, 0, 0, 0}, mode = WAVE_DATA)
	WAVE/Z stimScale_HS1 = GetLastSettingEachRAC(numericalValues, sweepNo, "Stim Scale Factor", 1, DATA_ACQUISITION_MODE)
	CHECK_EQUAL_WAVES(stimScale_HS1, {1, 1, 0, 0, 0, 0}, mode = WAVE_DATA)
End

static Function AcquireWithoutAmplifier_PreAcq(string device)

	PGC_SetAndActivateControl(device, "Popup_Settings_HeadStage", val = 0)

	PGC_SetAndActivateControl(device, "setvar_Settings_VC_DAgain", val = 11)
	PGC_SetAndActivateControl(device, "setvar_Settings_VC_ADgain", val = 21e-5)
	PGC_SetAndActivateControl(device, "setvar_Settings_IC_DAgain", val = 31)
	PGC_SetAndActivateControl(device, "setvar_Settings_IC_ADgain", val = 41e-5)

	// toggle headstage to use the newly changed gains
	PGC_SetAndActivateControl(device, GetPanelControl(0, CHANNEL_TYPE_HEADSTAGE, CHANNEL_CONTROL_CHECK), val = 0)
	PGC_SetAndActivateControl(device, GetPanelControl(0, CHANNEL_TYPE_HEADSTAGE, CHANNEL_CONTROL_CHECK), val = 1)

	PGC_SetAndActivateControl(device, "Popup_Settings_HeadStage", val = 1)

	PGC_SetAndActivateControl(device, "setvar_Settings_VC_DAgain", val = 10)
	PGC_SetAndActivateControl(device, "setvar_Settings_VC_ADgain", val = 20e-5)
	PGC_SetAndActivateControl(device, "setvar_Settings_IC_DAgain", val = 30)
	PGC_SetAndActivateControl(device, "setvar_Settings_IC_ADgain", val = 40e-5)

	PGC_SetAndActivateControl(device, GetPanelControl(1, CHANNEL_TYPE_HEADSTAGE, CHANNEL_CONTROL_CHECK), val = 0)
	PGC_SetAndActivateControl(device, GetPanelControl(1, CHANNEL_TYPE_HEADSTAGE, CHANNEL_CONTROL_CHECK), val = 1)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function AcquireWithoutAmplifier([string str])

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG1_RES0_AMP0"               + \
	                             "__HS0_DA0_AD0_CM:VC:_ST:StimulusSetA_DA_0:" + \
	                             "__HS1_DA1_AD1_CM:IC:_ST:StimulusSetC_DA_0:")

	AcquireData_NG(s, str)
End

static Function AcquireWithoutAmplifier_REENTRY([string str])
	variable sweepNo

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 1)

	WAVE numericalValues = GetLBNumericalValues(str)
	sweepNo = 0

	WAVE/Z DAGain = GetLastSetting(numericalValues, sweepNo, "DA Gain", DATA_ACQUISITION_MODE)
	CHECK_EQUAL_WAVES(DAGain, {11, 30, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	WAVE/Z ADGain = GetLastSetting(numericalValues, sweepNo, "AD Gain", DATA_ACQUISITION_MODE)
	CHECK_EQUAL_WAVES(ADGain, {21e-5, 40e-5, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA, tol = 1e-8)

	WAVE/Z operationMode = GetLastSetting(numericalValues, sweepNo, "Operating Mode", DATA_ACQUISITION_MODE)
	CHECK_WAVE(operationMode, NULL_WAVE)

	WAVE/Z requireAmplifier = GetLastSetting(numericalValues, sweepNo, "Require amplifier", DATA_ACQUISITION_MODE)
	CHECK_EQUAL_WAVES(requireAmplifier, {NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, CHECKBOX_UNSELECTED}, mode = WAVE_DATA)

	WAVE/Z saveAmpSettings = GetLastSetting(numericalValues, sweepNo, "Save amplifier settings", DATA_ACQUISITION_MODE)
	CHECK_EQUAL_WAVES(saveAmpSettings, {NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, CHECKBOX_SELECTED}, mode = WAVE_DATA)
End

// UTF_TD_GENERATOR GetITCDevices
Function HandlesFIFOTimeoutProperly([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG1_RES0"                    + \
	                             "__HS0_DA0_AD0_CM:VC:_ST:StimulusSetA_DA_0:" + \
	                             "__HS1_DA1_AD1_CM:IC:_ST:StimulusSetC_DA_0:")

	AcquireData_NG(s, str)

	CtrlNamedBackGround ExecuteDuringDAQ, start, period=30, proc=UseFakeFIFOThreadWithTimeout_IGNORE
End

Function HandlesFIFOTimeoutProperly_REENTRY([str])
	string str

	variable stopReason

	WAVE numericalValues = GetLBNumericalValues(str)

	stopReason = GetLastSettingIndep(numericalValues, 0, "DAQ stop reason", UNKNOWN_MODE)
	CHECK_EQUAL_VAR(stopReason, DQ_STOP_REASON_FIFO_TIMEOUT)

	stopReason = GetLastSettingIndep(numericalValues, 1, "DAQ stop reason", UNKNOWN_MODE)
	CHECK_EQUAL_VAR(stopReason, DQ_STOP_REASON_FINISHED)
End

// UTF_TD_GENERATOR GetITCDevices
Function HandlesStuckFIFOProperly([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG1_RES0"                    + \
	                             "__HS0_DA0_AD0_CM:VC:_ST:StimulusSetA_DA_0:" + \
	                             "__HS1_DA1_AD1_CM:IC:_ST:StimulusSetC_DA_0:")

	AcquireData_NG(s, str)

	CtrlNamedBackGround ExecuteDuringDAQ, start, period=30, proc=UseFakeFIFOThreadBeingStuck_IGNORE
End

Function HandlesStuckFIFOProperly_REENTRY([str])
	string str

	variable stopReason

	WAVE numericalValues = GetLBNumericalValues(str)

	stopReason = GetLastSettingIndep(numericalValues, 0, "DAQ stop reason", UNKNOWN_MODE)
	CHECK_EQUAL_VAR(stopReason, DQ_STOP_REASON_STUCK_FIFO)

	stopReason = GetLastSettingIndep(numericalValues, 1, "DAQ stop reason", UNKNOWN_MODE)
	CHECK_EQUAL_VAR(stopReason, DQ_STOP_REASON_FINISHED)
End

// UTF_TD_GENERATOR v0:InsertedTPPossibilities
// UTF_TD_GENERATOR s0:DeviceNameGeneratorMD1
static Function CheckDelays([STRUCT IUTF_MDATA &md])

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG1_RES1_ITP" + num2str(md.v0) + "_TD100_OD50_dDAQ1_DDL10_TBP25" + \
	                             "__HS0_DA0_AD0_CM:IC:_ST:StimulusSetA_DA_0:"                                     + \
	                             "__HS1_DA1_AD1_CM:VC:_ST:StimulusSetA_DA_0:")
	AcquireData_NG(s, md.s0)
End

static Function CheckDelays_REENTRY([STRUCT IUTF_MDATA &md])
	variable sweepNo, val

	sweepNo = 0
	CHECK_EQUAL_VAR(GetSetVariable(md.s0, "SetVar_Sweep"), sweepNo + 1)

	WAVE numericalValues = GetLBNumericalValues(md.s0)

	val = GetLastSettingIndep(numericalValues, sweepNo, "TP insert checkbox", DATA_ACQUISITION_MODE)
	CHECK_EQUAL_VAR(val, md.v0)

	val = GetLastSettingIndep(numericalValues, sweepNo, "Delay onset user", DATA_ACQUISITION_MODE)
	CHECK_EQUAL_VAR(val, 50)

	val = GetLastSettingIndep(numericalValues, sweepNo, "Delay onset auto", DATA_ACQUISITION_MODE)

	if(md.v0)
		CHECK_EQUAL_VAR(val, 20)
	else
		CHECK_EQUAL_VAR(val, 0)
	endif

	val = GetLastSettingIndep(numericalValues, sweepNo, "Delay termination", DATA_ACQUISITION_MODE)
	CHECK_EQUAL_VAR(val, 100)

	val = GetLastSettingIndep(numericalValues, sweepNo, "Delay distributed DAQ", DATA_ACQUISITION_MODE)
	CHECK_EQUAL_VAR(val, 10)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function CheckSweepOrdering([string str])

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG1"                      + \
	                             "__HS0_DA0_AD0_CM:IC:_ST:StimulusSetA_DA_0:")
	AcquireData_NG(s, str)
End

static Function CheckSweepOrdering_REENTRY_preAcq(string device)

	// now turn back the sweep counter and try again
	PGC_SetAndActivateControl(device, "SetVar_Sweep", val = 0)
End

static Function CheckSweepOrdering_REENTRY([string str])

	STRUCT DAQSettings s

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 1)

	// close device
	KillWindow $str
	CHECK_NO_RTE()

	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG1_FAR0"                 + \
	                             "__HS0_DA0_AD0_CM:IC:_ST:StimulusSetA_DA_0:")

	try
		AcquireData_NG(s, str)
		FAIL()
	catch
		PASS()
	endtry
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function DoNotAllowTestPulseOnUnassocDA([string str])

	STRUCT DAQSettings s

	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG1_FAR0"                    + \
	                             "__HS0_DA0_AD0_CM:VC:_ST:StimulusSetA_DA_0:" + \
	                             "__HS1_DA1_AD1_CM:VC:_ST:TestPulse:_ASO0")

	try
		AcquireData_NG(s, str)
		FAIL()
	catch
		PASS()
	endtry
End

static Function RandomAcq_preAcq(string device)

	PGC_SetAndActivateControl(device, "check_DataAcq_RepAcqRandom", val = 1)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function RandomAcq([string str])

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG1_ITP0"                 + \
	                             "__HS0_DA0_AD0_CM:IC:_ST:StimulusSetA_DA_0:")
	AcquireData_NG(s, str)
End

static Function RandomAcq_REENTRY([string str])

	variable numSweeps = 3
	variable i

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), numSweeps)

	Make/FREE/N=(numSweeps) maxDA = NaN

	for(i = 0; i < 3; i += 1)
		WAVE/Z sweep = GetSweepWave(str, i)
		CHECK_WAVE(sweep, TEXT_WAVE)

		WAVE/Z DA = AFH_ExtractOneDimDataFromSweep(str, sweep, 0, XOP_CHANNEL_TYPE_DAC)
		maxDA[i] = WaveMax(DA)
	endfor

	// check that we acquired every sweep of the stimulus set exactly once
	Sort maxDA, maxDA
	CHECK_EQUAL_WAVES(maxDA, {1, 2, 3})
End

static Function CheckIfNoTTLonTP_preAcq(string device)

	PGC_SetAndActivateControl(device, GetPanelControl(0, CHANNEL_TYPE_TTL, CHANNEL_CONTROL_CHECK), val = 1)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function CheckIfNoTTLonTP([string str])

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG1_TP1"                  + \
	                             "__HS0_DA0_AD0_CM:VC:_ST:StimulusSetA_DA_0:")
	AcquireData_NG(s, str)
	CtrlNamedBackGround StopTPAfterSomeTime, start=(ticks + 60 * 3), period=60, proc=StopTP_IGNORE
End

static Function CheckIfNoTTLonTP_REENTRY([string str])
	PASS()
End

#ifdef TESTS_WITH_NI_HARDWARE
// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function TestNIAcquisitionReliability([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG1_FFR:10:_RES1000"    + \
	                             "__HS0_DA0_AD0_CM:VC:_ST:EpochTest6_DA_0:")

	AcquireData_NG(s, str)
End

static Function TestNIAcquisitionReliability_REENTRY([str])
	string str

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 1000)
End
#endif

// IUTF_TD_GENERATOR s0:DeviceNameGeneratorMD1
// IUTF_TD_GENERATOR s1:DataGenerators#RoundTripStimsetFileType
static Function RoundTripDepStimsetsRecursionThroughSweeps([STRUCT IUTF_mData &mData])

	string refList, setNameB, customWavePath
	variable amplitude
	string device = mData.s0
	STRUCT DAQSettings s

	[setNameB, refList, customWavePath, amplitude] = CreateDependentStimset()

	string/G   m_setNameB       = setNameB
	string/G   m_refList        = refList
	string/G   m_customWavePath = customWavePath
	variable/G m_amplitude      = amplitude

	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG1"                     + \
	                             "__HS0_DA0_AD0_CM:VC:_ST:" + setNameB + ":")

	AcquireData_NG(s, device)
End

static Function RoundTripDepStimsetsRecursionThroughSweeps_REENTRY([STRUCT IUTF_mData &mData])

	string fName, abWin, sweepBrowsers, stimsets
	string   device       = mData.s0
	string   suffix       = mData.s1
	string   baseFileName = "RoundTripDepStimsetsRecursionThroughSweeps-" + device + "." + suffix
	variable nwbVersion   = GetNWBVersion()

	SVAR setNameB       = m_setNameB
	SVAR refList        = m_refList
	SVAR customWavePath = m_customWavePath
	NVAR amplitude      = m_amplitude

	PathInfo home
	fName = S_path + baseFileName

	if(!CmpStr(suffix, "nwb"))
		NWB_ExportAllData(nwbVersion, overrideFullFilePath = fName, writeStoredTestPulses = 1, writeIgorHistory = 1)
	elseif(!CmpStr(suffix, "pxp"))
		SaveExperiment/C as fName
	else
		FAIL()
	endif

	DFREF dfr = GetWaveBuilderPath()
	KillDataFolder dfr
	KillWaves $customWavePath

	[abWin, sweepBrowsers] = OpenAnalysisBrowser({baseFileName}, loadSweeps = 1, loadStimsets = 1)

	stimsets = ST_GetStimsetList()
	stimsets = SortList(stimsets, ";", 16)
	refList  = AddListItem(STIMSET_TP_WHILE_DAQ, refList)
	refList  = SortList(refList, ";", 16)
	CHECK_EQUAL_STR(stimsets, refList, case_sensitive = 0)
	WAVE/T wStimsets = ListToTextWave(stimsets, ";")
	for(set : wStimsets)
		if(CmpStr(set, STIMSET_TP_WHILE_DAQ))
			INFO("Stimset %s should not be third party.\r", s0 = set)
			CHECK_EQUAL_VAR(WB_StimsetIsFromThirdParty(set), 0)
		endif
	endfor

	WAVE baseSet = WB_CreateAndGetStimSet(setNameB)
	CHECK_WAVE(baseSet, NUMERIC_WAVE)
	CHECK_GT_VAR(DimSize(baseSet, ROWS), 0)
	WaveStats/Q baseSet
	CHECK_EQUAL_VAR(V_max, amplitude)
	CHECK_EQUAL_VAR(V_min, amplitude)

	KillVariables/Z m_amplitude
	KillStrings/Z m_setNameB, m_refList, m_customWavePath
End

static Function TestCustomElectrodeNamesInNWB_preAcq(string device)

	FFI_SetCellElectrodeName(device, 0, "Electric Dreams of Voltage")
	FFI_SetCellElectrodeName(device, 1, "Electric Dreams of Current")
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function TestCustomElectrodeNamesInNWB([string str])

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG1"                       + \
	                             "__HS0_DA0_AD0_CM:VC:_ST:EpochTest6_DA_0:" + \
	                             "__HS1_DA1_AD1_CM:IC:_ST:EpochTest6_DA_0:")

	AcquireData_NG(s, str)
End

static Function TestCustomElectrodeNamesInNWB_REENTRY([string str])

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 1)
	TestNwbExportV2()
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function GetDataLimitsChecksWorks([string str])

	variable minimum, maximum

	// unlocked device
	[minimum, maximum] = DAP_GetDataLimits(str, 1, "StimulusSetA_DA_0", 0)
	CHECK(IsNaN(minimum))
	CHECK(IsNaN(maximum))

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG1_TP1"                  + \
	                             "__HS1_DA1_AD2_CM:IC:_ST:StimulusSetA_DA_0:")

	AcquireData_NG(s, str)

	CtrlNamedBackGround StopTPAfterSomeTime, start=(ticks + 120), period=60, proc=StopTP_IGNORE
End

static Function GetDataLimitsChecksWorks_REENTRY([string str])

	string stimset
	variable minimum, maximum, headstage

	headstage = 1
	stimset   = "StimulusSetA_DA_0"

	// unassociated/unused headstage
	[minimum, maximum] = DAP_GetDataLimits(str, 0, stimset, 0)
	CHECK(IsNaN(minimum))
	CHECK(IsNaN(maximum))

	// invalid setColumn
	try
		[minimum, maximum] = DAP_GetDataLimits(str, headstage, stimset, 4711)
		FAIL()
	catch
		CHECK_NO_RTE()
	endtry

	[minimum, maximum] = DAP_GetDataLimits(str, headstage, stimset, 0)
	CHECK_EQUAL_VAR(minimum, -Inf)
	CHECK_EQUAL_VAR(maximum, 4095)

	// @todo more proper test cases

	// third party
	WB_MakeStimsetThirdParty(stimset)

	try
		[minimum, maximum] = DAP_GetDataLimits(str, headstage, stimset, 0)
		FAIL()
	catch
		CHECK_NO_RTE()
	endtry
End
