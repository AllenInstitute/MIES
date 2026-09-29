#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors = 1
#pragma ModuleName       = DAEphysPanel

/// @name Regular expressions for the labnotebook entries of Sutter amplifiers
///@{
static StrConstant SUTTER_HARDWARE_TYPE_REGEXP = "^Sutter d?IPA$" ///< single and double IPA
static StrConstant SUTTER_SERIAL_REGEXP        = "^IPA_"
///@}

static Function GlobalPreInit(string device)

	PASS()
End

static Function GlobalPreAcq(string device)

	PASS()
End

// UTF_TD_GENERATOR DataGenerators#DeviceNameGeneratorMD1
Function CheckIfAllControlsReferStateWv([string str])

	string list, ctrl, stri, expected, lbl, uniqueControls
	variable i, numEntries, val, channelIndex, channelType, controlType, index, oldVal
	variable err, inputModified, mode

	ACD_CreateLockedDAEphys(str)

	list = ControlNameList(str, ";")

	uniqueControls = MIES_DAG#DAG_GetUniqueCtrlList(str)

	numEntries = ItemsInList(list)
	CHECK_GT_VAR(numEntries, 0)
	for(i = 0; i < numEntries; i += 1)
		ctrl = StringFromList(i, list)
		ControlInfo/W=$str $ctrl

		if(!DAP_ParsePanelControl(ctrl, channelIndex, channelType, controlType) && channelIndex >= 0)
			index = channelIndex
			lbl   = GetSpecialControlLabel(channelType, controlType)
		else
			index = NaN
			lbl   = ctrl

			// ignore controls we don't store
			if(WhichListItem(ctrl, uniqueControls) == -1)
				continue
			endif
		endif

		// ignore turned off controls
		if(IsControlDisabled(str, ctrl))
			continue
		endif

		switch(abs(V_Flag))
			case CONTROL_TYPE_BUTTON: // fallthrough
			case CONTROL_TYPE_LISTBOX: // fallthrough
			case CONTROL_TYPE_TAB: // fallthrough
			case CONTROL_TYPE_VALDISPLAY: // fallthrough
			case CONTROL_TYPE_GROUPBOX: // fallthrough
			case CONTROL_TYPE_TITLEBOX:
				// nothing to do
				break
			case CONTROL_TYPE_CHECKBOX:
				oldVal = V_Value
				val    = !oldVal

				try
					PGC_SetAndActivateControl(str, ctrl, val = val); err = GetRTError(1)
				catch
					// do nothing
				endtry

				CHECK_EQUAL_VAR(GetCheckBoxState(str, ctrl), val)
				CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, lbl, index = index), val)
				// undo
				PGC_SetAndActivateControl(str, ctrl, val = oldVal)
				break
			case CONTROL_TYPE_SETVARIABLE:
				if(GetControlSettingVar(S_recreation, "noEdit") == 1)
					mode = PGC_MODE_FORCE_ON_DISABLED
				else
					mode = PGC_MODE_ASSERT_ON_DISABLED
				endif

				if(DoesControlHaveInternalString(S_recreation))
					stri = NONE
					KillOrMoveToTrash(wv = GetDA_EphysGuiStateTxT(str))

					try
						PGC_SetAndActivateControl(str, ctrl, str = stri, mode = mode); err = GetRTError(1)
					catch
						// do nothing
					endtry

					// if the gui state wave exists we wrote into it
					WAVE/Z/SDFR=GetDevicePath(str) DA_EphysGuiStateTxT
					CHECK_WAVE(DA_EphysGuiStateTxT, TEXT_WAVE)
					expected = DAG_GetTextualValue(str, lbl, index = index)
					CHECK_EQUAL_STR(expected, stri)
				else
					val = 0
					KillOrMoveToTrash(wv = GetDA_EphysGuiStateNum(str))

					try
						inputModified = PGC_SetAndActivateControl(str, ctrl, val = val, mode = mode); err = GetRTError(1)
					catch
						// do nothing
					endtry

					// if the gui state wave exists we wrote into it
					WAVE/Z/SDFR=GetDevicePath(str) DA_EphysGuiStateNum
					CHECK_WAVE(DA_EphysGuiStateNum, NUMERIC_WAVE)

					if(inputModified)
						val = GetLimitConstrainedSetVar(S_recreation, val)
					endif

					CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, lbl, index = index), val)
				endif

				break
			case CONTROL_TYPE_SLIDER:

				val = 0
				KillOrMoveToTrash(wv = GetDA_EphysGuiStateNum(str))

				try
					PGC_SetAndActivateControl(str, ctrl, val = val); err = GetRTError(1)
				catch
					// do nothing
				endtry

				// if the gui state wave exists we wrote into it
				WAVE/Z/SDFR=GetDevicePath(str) DA_EphysGuiStateNum
				CHECK_WAVE(DA_EphysGuiStateNum, NUMERIC_WAVE)
				CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, lbl, index = index), val)

				break
			case CONTROL_TYPE_POPUPMENU:

				oldVal = GetPopupMenuIndex(str, ctrl)
				val    = 0
				KillOrMoveToTrash(wv = GetDA_EphysGuiStateNum(str))
				KillOrMoveToTrash(wv = GetDA_EphysGuiStateTxT(str))

				try
					PGC_SetAndActivateControl(str, ctrl, val = val); err = GetRTError(1)
				catch
					// do nothing
				endtry

				stri = GetPopupMenuString(str, ctrl)
				// if the gui state wave exists we wrote into it
				WAVE/Z/SDFR=GetDevicePath(str) DA_EphysGuiStateNum
				CHECK_WAVE(DA_EphysGuiStateNum, NUMERIC_WAVE)

				WAVE/Z/SDFR=GetDevicePath(str) DA_EphysGuiStateTxT
				CHECK_WAVE(DA_EphysGuiStateTxT, TEXT_WAVE)

				CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, lbl, index = index), val)

				expected = DAG_GetTextualValue(str, lbl, index = index)
				CHECK_EQUAL_STR(expected, stri)
				// undo
				PGC_SetAndActivateControl(str, ctrl, val = oldVal)
				break
			default:
				INFO("Control type = %d", n0 = V_Flag)
				FAIL()
		endswitch
	endfor
End

// UTF_TD_GENERATOR DataGenerators#DeviceNameGeneratorMD1
Function CheckStartupSettings([string str])

	string unlockedDevice, list, ctrl, expected, lbl
	variable i, numEntries, val, channelIndex, channelType, controlType, index, oldVal

	SetRandomSeed/BETR=1 1

	unlockedDevice = DAP_CreateDAEphysPanel()

	ACD_CreateLockedDAEphys(str, unlockedDevice = unlockedDevice)

	Duplicate/FREE GetDA_EphysGuiStateNum(str), guiStateNumRef
	Duplicate/FREE GetDA_EphysGuiStateTxT(str), guiStateTxTRef

	PGC_SetAndActivateControl(str, "button_SettingsPlus_unLockDevic")
	unlockedDevice = GetCurrentWindow()

	list = ControlNameList(unlockedDevice, ";")

	numEntries = ItemsInList(list)
	CHECK_GT_VAR(numEntries, 0)
	for(i = 0; i < numEntries; i += 1)
		ctrl = StringFromList(i, list)
		ControlInfo/W=$unlockedDevice $ctrl

		switch(abs(V_Flag))
			case CONTROL_TYPE_BUTTON: // fallthrough
			case CONTROL_TYPE_LISTBOX: // fallthrough
			case CONTROL_TYPE_TAB: // fallthrough
			case CONTROL_TYPE_VALDISPLAY: // fallthrough
			case CONTROL_TYPE_GROUPBOX: // fallthrough
			case CONTROL_TYPE_TITLEBOX:
				// nothing to do
				break
			case CONTROL_TYPE_CHECKBOX:
				oldVal = V_Value
				val    = !oldVal
				SetCheckBoxState(unlockedDevice, ctrl, val)
				break
			case CONTROL_TYPE_SETVARIABLE:
				if(DoesControlHaveInternalString(S_recreation))
					SetSetVariableString(unlockedDevice, ctrl, num2str(enoise(1, 2)))
				else
					SetSetVariable(unlockedDevice, ctrl, enoise(5, 2))
				endif
				break
			case CONTROL_TYPE_SLIDER:

				oldVal = V_Value
				SetSliderPositionIndex(unlockedDevice, ctrl, oldVal + 1)

				break
			case CONTROL_TYPE_POPUPMENU:

				SetPopupMenuIndex(unlockedDevice, ctrl, 1 + enoise(2, 2))
				break
			default:
				FAIL()
		endswitch
	endfor

	DAP_EphysPanelStartUpSettings()

	SCOPE_OpenScopeWindow(unlockedDevice)
	AddVersionToPanel(unlockedDevice, DA_EPHYS_PANEL_VERSION)

	ACD_CreateLockedDAEphys(str, unlockedDevice = unlockedDevice)

	Duplicate/FREE GetDA_EphysGuiStateNum(str), guiStateNumNew
	Duplicate/FREE GetDA_EphysGuiStateTxT(str), guiStateTxTNew

	CHECK_EQUAL_WAVES(guiStateNumRef, guiStateNumNew, mode = WAVE_DATA | DIMENSION_LABELS)
	CHECK_EQUAL_WAVES(guiStateTxTRef, guiStateTxTNew, mode = WAVE_DATA | DIMENSION_LABELS)
End

// UTF_TD_GENERATOR DataGenerators#DeviceNameGeneratorMD1
Function CheckStimsetPopupMetadata([string str])

	string controls, stimsetlist, ctrl, menuExp
	variable i, numControls, channelIndex, channelType, controlType

	ACD_CreateLockedDAEphys(str)

	controls    = ControlNameList(str)
	numControls = ItemsInList(controls)
	for(i = 0; i < numControls; i += 1)
		ctrl = StringFromList(i, controls)

		// ignore non-popup menues
		if(GetControlType(str, ctrl) != CONTROL_TYPE_POPUPMENU)
			continue
		endif

		// ignore non-parseable controls
		if(DAP_ParsePanelControl(ctrl, channelIndex, channelType, controlType))
			continue
		endif

		if(DAP_IsAllControl(channelIndex))
			menuExp = GetUserData(str, ctrl, USER_DATA_MENU_EXP)

			stimsetlist = ST_GetStimsetList(channelType = channelType)
			CHECK_EQUAL_STR(menuExp, stimsetlist)
		endif
	endfor
End

// UTF_TD_GENERATOR DataGenerators#DeviceNameGeneratorMD1
Function AllChannelControlsWork([string str])

	string   ctrl
	variable channelType

	ACD_CreateLockedDAEphys(str)

	Make/FREE channelTypes = {CHANNEL_TYPE_ADC, CHANNEL_TYPE_DAC, CHANNEL_TYPE_TTL}

	for(channelType : channelTypes)
		ctrl = GetPanelControl(CHANNEL_INDEX_ALL, channelType, CHANNEL_CONTROL_CHECK)
		CHECK_EQUAL_VAR(GetCheckBoxState(str, ctrl), CHECKBOX_UNSELECTED)
		PGC_SetAndActivateControl(str, ctrl, val = CHECKBOX_SELECTED)
	endfor
End

// UTF_TD_GENERATOR DataGenerators#DeviceNameGeneratorMD1
Function CheckIfConfigurationRestoresMCCFilterGain([string str])

	string rewrittenConfig, fName
	variable val, gain, filterFreq, headStage, jsonID

	PrepareForPublishTest()

	fName = PrependExperimentFolder_IGNORE("CheckIfConfigurationRestoresMCCFilterGain.json")

	[STRUCT ACD_DAQSettings s] = ACD_InitDAQSettingsFromString("MD1_RA1_I0_L0_BKG1_DAQ0_TP0"                + \
	                                                           "__HS0_DA0_AD0_CM:VC:_ST:StimulusSetA_DA_0:" + \
	                                                           "__HS1_DA1_AD1_CM:IC:_ST:StimulusSetB_DA_0:")

	ACD_AcquireData(s, str)

	gain       = 5
	filterFreq = 6
	AI_WriteToAmplifier(str, headStage, V_CLAMP_MODE, MCC_PRIMARYSIGNALLPF_FUNC, filterFreq)
	AI_WriteToAmplifier(str, headStage, V_CLAMP_MODE, MCC_PRIMARYSIGNALGAIN_FUNC, gain)
	AI_WriteToAmplifier(str, headStage + 1, I_CLAMP_MODE, MCC_PRIMARYSIGNALLPF_FUNC, filterFreq)
	AI_WriteToAmplifier(str, headStage + 1, I_CLAMP_MODE, MCC_PRIMARYSIGNALGAIN_FUNC, gain)

	PGC_SetAndActivateControl(str, "check_Settings_SyncMiesToMCC", val = 1)

	CONF_SaveWindow(fName)

	[jsonID, rewrittenConfig] = FixupJSONConfig_IGNORE(fName, str)
	JSON_Release(jsonID)

	gain       = 1
	filterFreq = 2
	AI_WriteToAmplifier(str, headStage, V_CLAMP_MODE, MCC_PRIMARYSIGNALLPF_FUNC, filterFreq)
	AI_WriteToAmplifier(str, headStage, V_CLAMP_MODE, MCC_PRIMARYSIGNALGAIN_FUNC, gain)
	AI_WriteToAmplifier(str, headStage + 1, I_CLAMP_MODE, MCC_PRIMARYSIGNALLPF_FUNC, filterFreq)
	AI_WriteToAmplifier(str, headStage + 1, I_CLAMP_MODE, MCC_PRIMARYSIGNALGAIN_FUNC, gain)

	KillWindow $str

	CONF_RestoreWindow(rewrittenConfig)

	gain       = 5
	filterFreq = 6
	val        = AI_ReadFromAmplifier(str, headStage, V_CLAMP_MODE, MCC_PRIMARYSIGNALLPF_FUNC)
	CHECK_EQUAL_VAR(val, filterFreq)
	val = AI_ReadFromAmplifier(str, headStage, V_CLAMP_MODE, MCC_PRIMARYSIGNALGAIN_FUNC)
	CHECK_EQUAL_VAR(val, gain)
	val = AI_ReadFromAmplifier(str, headStage + 1, I_CLAMP_MODE, MCC_PRIMARYSIGNALLPF_FUNC)
	CHECK_EQUAL_VAR(val, filterFreq)
	val = AI_ReadFromAmplifier(str, headStage + 1, I_CLAMP_MODE, MCC_PRIMARYSIGNALGAIN_FUNC)
	CHECK_EQUAL_VAR(val, gain)
End

static Function ComplainsAboutVanishingEpoch_preAcq(string device)

	string setname = "StimulusSetA_DA_0"

	ST_SetStimsetParameter(setname, "Total number of epochs", var = 2)
	ST_SetStimsetParameter(setname, "Total number of sweeps", var = 1)

	ST_SetStimsetParameter(setname, "Type of Epoch 0", var = EPOCH_TYPE_SQUARE_PULSE)
	ST_SetStimsetParameter(setname, "Duration", epochIndex = 0, var = 0.010) // 10us
	ST_SetStimsetParameter(setname, "Amplitude", epochIndex = 0, var = 1)

	// second epoch is required as the stimset itself must have a certain length
	ST_SetStimsetParameter(setname, "Type of Epoch 1", var = EPOCH_TYPE_SQUARE_PULSE)
	ST_SetStimsetParameter(setname, "Duration", epochIndex = 1, var = 10)
	ST_SetStimsetParameter(setname, "Amplitude", epochIndex = 1, var = 0)
End

// UTF_TD_GENERATOR s0:DataGenerators#DeviceNameGeneratorMD1
static Function ComplainsAboutVanishingEpoch([STRUCT IUTF_MDATA &md])

	variable refNum
	string   history

	[STRUCT ACD_DAQSettings s] = ACD_InitDAQSettingsFromString("MD1_RA0_I0_L0_BKG1_SIM8"                 + \
	                                                           "__HS0_DA0_AD0_CM:IC:_ST:StimulusSetA_DA_0:")

	refNum = CaptureHistoryStart()
	ACD_AcquireData(s, md.s0)
	history = CaptureHistory(refNum, 1)

	CHECK_PROPER_STR(history)
	CHECK_GT_VAR(strsearch(history, "shorter than the sampling interval", 0), 0)
End

static Function ComplainsAboutVanishingEpoch_REENTRY([STRUCT IUTF_MDATA &md])

	string   device  = md.s0
	variable DAC     = 0
	variable sweepNo = 0

	CHECK_EQUAL_VAR(AFH_GetLastSweepAcquired(device), sweepNo)

	WAVE/Z numericalValues = GetLBNumericalValues(device)
	CHECK_WAVE(numericalValues, NUMERIC_WAVE)

	WAVE/Z textualValues = GetLBTextualValues(device)
	CHECK_WAVE(textualValues, TEXT_WAVE)

	// check that we have info for the vanished epoch
	WAVE/Z/T e0 = EP_GetEpochs(numericalValues, textualValues, sweepNo, XOP_CHANNEL_TYPE_DAC, DAC, "E0")
	CHECK_WAVE(e0, FREE_WAVE | TEXT_WAVE)

	WAVE/Z/T e1 = EP_GetEpochs(numericalValues, textualValues, sweepNo, XOP_CHANNEL_TYPE_DAC, DAC, "E1")
	CHECK_WAVE(e1, FREE_WAVE | TEXT_WAVE)

	// remove left over from ???
	KillVariables/Z V_flag
End

static Function SyncMIESMccWorksOutoftheBox_preAcq(string device)

	/// desync MCC and MIES
	AI_SendToAmp(device, 0, V_CLAMP_MODE, MCC_HOLDING_FUNC, MCC_WRITE, value = 5)

	PGC_SetAndActivateControl(device, "check_Settings_SyncMiesToMCC", val = 1)
End

// UTF_TD_GENERATOR s0:DataGenerators#DeviceNameGeneratorMD1
static Function SyncMIESMccWorksOutoftheBox([STRUCT IUTF_MDATA &md])

	variable headstage, func, clampMode, val, expected, actual
	string device, rowLabel

	device = md.s0

	[STRUCT ACD_DAQSettings s] = ACD_InitDAQSettingsFromString("MD1_RA0_I0_L0_BKG1_TP0_DAQ0"             + \
	                                                           "__HS0_DA0_AD0_CM:VC:_ST:StimulusSetA_DA_0:")
	ACD_AcquireData(s, device)

	WAVE ampStorageWave = GetAmplifierParamStorageWave(device)

	headstage = GetSliderPositionIndex(device, "slider_DataAcq_ActiveHeadstage")
	clampMode = DAG_GetHeadstageMode(device, headstage)
	func      = MCC_HOLDING_FUNC

	// initial read from hardware
	actual = AI_ReadFromAmplifier(device, headstage, clampMode, func)
	CHECK(IsFinite(actual))

	// comparison with MIES internal state in wave
	rowLabel = "HoldingPotential"
	expected = ampStorageWave[%$rowLabel][0][headstage]
	CHECK_EQUAL_VAR(expected, actual)
End

/// @brief Return true if the amplifier function has no Sutter counterpart
static Function IsUnsupportedSutterFunc(variable func)

	Make/FREE unsupported = {MCC_AUTOBRIDGEBALANCE_FUNC, MCC_RSCOMPBANDWIDTH_FUNC, MCC_OSCKILLERENABLE_FUNC, MCC_SLOWCOMPCAP_FUNC, MCC_SLOWCOMPTAU_FUNC, MCC_SLOWCOMPTAUX20ENAB_FUNC, MCC_AUTOSLOWCOMP_FUNC, MCC_SLOWCURRENTINJENABL_FUNC, MCC_SLOWCURRENTINJLEVEL_FUNC, MCC_SLOWCURRENTINJSETLT_FUNC, MCC_PRIMARYSIGNALGAIN_FUNC, MCC_SECONDARYSIGNALGAIN_FUNC, MCC_PRIMARYSIGNALHPF_FUNC, MCC_SECONDARYSIGNALLPF_FUNC}

	return IsFinite(GetRowIndex(unsupported, val = func))
End

static Function CheckAmplifierReadAndWrite_preAcq(string device)

	PGC_SetAndActivateControl(device, "check_Settings_SyncMiesToMCC", val = 1)
End

// UTF_TD_GENERATOR s0:DataGenerators#DeviceNameGeneratorMD1
// UTF_TD_GENERATOR v0:DataGenerators#GetClampModesWithoutIZero
Function CheckAmplifierReadAndWrite([STRUCT IUTF_MDATA &md])

	variable refNum, headstage, func, clampMode, val, expected, actual, newValue
	variable ret, readFunc
	string history, device, rowLabel, ctrl, clampModeStr

	if(md.v0 == V_CLAMP_MODE)
		clampModeStr = "VC"
	elseif(md.v0 == I_CLAMP_MODE)
		clampModeStr = "IC"
	else
		INFO("Unknown clamp mode: %n", n0 = md.v0)
		FAIL()
	endif

	device    = md.s0
	headstage = 0

	[STRUCT ACD_DAQSettings s] = ACD_InitDAQSettingsFromString("MD1_RA0_I0_L0_BKG1_TP0_DAQ0"                                                        + \
	                                                           "__HS" + num2str(headstage) + "_DA0_AD0_CM:" + clampModeStr + ":_ST:StimulusSetA_DA_0:")
	ACD_AcquireData(s, device)

	clampMode = DAG_GetHeadstageMode(device, headstage)

	WAVE ampStorageWave = GetAmplifierParamStorageWave(device)

	WAVE funcs = DataGenerators#GetAmplifierFuncs()

	for(func : funcs)
#ifdef TESTS_WITH_SUTTER_HARDWARE
		if(IsUnsupportedSutterFunc(func))
			continue
		endif
#endif // TESTS_WITH_SUTTER_HARDWARE

		switch(func)
			case MCC_OSCKILLERENABLE_FUNC:
				// functions without controls
				break
			default:
				ctrl = AI_MapFunctionConstantToControl(func, clampMode)

				if(!AI_IsControlFromClampMode(ctrl, clampMode))
					continue
				endif
				break
		endswitch

		// initial read from hardware
		actual = AI_ReadFromAmplifier(device, headstage, clampMode, func, selectAmp = 1)
		CHECK(IsFinite(actual))

		switch(func)
			case MCC_OSCKILLERENABLE_FUNC: // fallthrough
			case MCC_AUTOBRIDGEBALANCE_FUNC: // fallthrough
			case MCC_AUTOWHOLECELLCOMP_FUNC: // fallthrough
			case MCC_AUTOPIPETTEOFFSET_FUNC:
				break
			default:
				// comparison with MIES internal state in wave
				rowLabel = AI_MapFunctionConstantToName(func, clampMode)
				CHECK_PROPER_STR(rowLabel)
				expected = ampStorageWave[%$rowLabel][0][headstage]
				INFO("func: %d, rowLabel: %s", n0 = func, s0 = rowLabel)
				REQUIRE_CLOSE_VAR(expected, actual, tol = 1e-3)
				break
		endswitch

		readFunc = NaN

		// writing works into
		switch(func)
			case MCC_PIPETTEOFFSET_FUNC:
				newValue = 50
				break
			case MCC_BRIDGEBALRESIST_FUNC: // fallthrough
			case MCC_HOLDING_FUNC: // fallthrough
			case MCC_WHOLECELLCOMPRESIST_FUNC:
				newValue = 100
				break
			case MCC_NEUTRALIZATIONCAP_FUNC: // fallthrough
			case MCC_WHOLECELLCOMPCAP_FUNC: // fallthrough
			case MCC_RSCOMPBANDWIDTH_FUNC:
				newValue = 10
				break
			case MCC_BRIDGEBALENABLE_FUNC: // fallthrough
			case MCC_HOLDINGENABLE_FUNC: // fallthrough
			case MCC_NEUTRALIZATIONENABL_FUNC: // fallthrough
			case MCC_WHOLECELLCOMPENABLE_FUNC: // fallthrough
			case MCC_RSCOMPENABLE_FUNC:
				newValue = 1
				break
			case MCC_OSCKILLERENABLE_FUNC:
				// enabling this can result in a popup in the MCC application
				// which we can't handle
				newValue = 0
				break
			case MCC_AUTOBRIDGEBALANCE_FUNC:
				// what we wrote earlier with MCC_BRIDGEBALRESIST_FUNC
				newValue = 100
				readFunc = MCC_BRIDGEBALRESIST_FUNC
				break
			case MCC_AUTOWHOLECELLCOMP_FUNC:
				// dito
				newValue = 10
				readFunc = MCC_WHOLECELLCOMPCAP_FUNC
				break
			case MCC_AUTOPIPETTEOFFSET_FUNC:
				// dito
				newValue = 10
				readFunc = MCC_PIPETTEOFFSET_FUNC
				break
			case MCC_RSCOMPCORRECTION_FUNC: // fallthrough
			case MCC_RSCOMPPREDICTION_FUNC:
				ret = AI_WriteToAmplifier(device, headstage, clampMode, MCC_NO_AMPCHAIN_FUNC, newValue, selectAmp = 0)
				CHECK_EQUAL_VAR(ret, 0)
				newValue = 10
				break
			case MCC_AUTOFASTCOMP_FUNC: // fallthrough
			case MCC_AUTOSLOWCOMP_FUNC:
				newValue = 0
				break
			default:
				INFO("func: %d", n0 = func)
				FAIL()
		endswitch

		ret = AI_WriteToAmplifier(device, headstage, clampMode, func, newValue, selectAmp = 0)
		CHECK_EQUAL_VAR(ret, 0)

		// the hardware
		actual   = AI_ReadFromAmplifier(device, headstage, clampMode, IsFinite(readFunc) ? readFunc : func, usePrefixes = 1, selectAmp = 0)
		expected = newValue

		switch(func)
			case MCC_AUTOBRIDGEBALANCE_FUNC: // fallthrough
			case MCC_AUTOWHOLECELLCOMP_FUNC: // fallthrough
			case MCC_AUTOPIPETTEOFFSET_FUNC: // fallthrough
			case MCC_RSCOMPCORRECTION_FUNC:
				CHECK(IsFinite(actual))
				break
			default:
				CHECK_CLOSE_VAR(expected, actual, tol = 1e-3)
				break
		endswitch

		// and what we wrote into the wave
		rowLabel = AI_MapFunctionConstantToName(func, clampMode)

		switch(func)
			case MCC_OSCKILLERENABLE_FUNC: // fallthrough
			case MCC_FASTCOMPTAU_FUNC: // fallthrough
			case MCC_SLOWCOMPTAU_FUNC: // fallthrough
			case MCC_AUTOPIPETTEOFFSET_FUNC:
				CHECK_PROPER_STR(rowLabel)
				break
			default:
				expected = ampStorageWave[%$rowLabel][0][headstage]
				INFO("rowLabel %s, func %d", s0 = rowLabel, n0 = func)
				REQUIRE_CLOSE_VAR(expected, actual, tol = 1e-3)
				break
		endswitch

#ifdef TESTS_WITH_SUTTER_HARDWARE
		// Sutter amplifiers have one pipette offset for both clamp modes
		if(func == MCC_PIPETTEOFFSET_FUNC)
			rowLabel = AI_MapFunctionConstantToName(func, (clampMode == V_CLAMP_MODE) ? I_CLAMP_MODE : V_CLAMP_MODE)
			expected = ampStorageWave[%$rowLabel][0][headstage]
			INFO("rowLabel %s, func %d", s0 = rowLabel, n0 = func)
			CHECK_CLOSE_VAR(expected, actual, tol = 1e-3)
		endif
#endif // TESTS_WITH_SUTTER_HARDWARE
	endfor

	// handle funcs which don't interact with the MCC
	WAVE funcs = DataGenerators#GetNoAmplifierFuncs()

	newValue = 0
	for(func : funcs)
		newValue += 1
		ret       = AI_WriteToAmplifier(device, headstage, clampMode, func, newValue, selectAmp = 0)
		CHECK_EQUAL_VAR(ret, 0)

		rowLabel = AI_MapFunctionConstantToName(func, clampMode)
		actual   = newValue
		expected = ampStorageWave[%$rowLabel][0][headstage]
		INFO("rowLabel %s, func %d", s0 = rowLabel, n0 = func)
		REQUIRE_CLOSE_VAR(expected, actual, tol = 1e-3)
	endfor
End

#ifdef TESTS_WITH_SUTTER_HARDWARE

static Function CheckSutterLBNEntry(WAVE numericalValues, variable sweepNo, string key, variable expected, [variable tol])

	tol = ParamIsDefault(tol) ? 1e-3 : tol

	WAVE/Z settings = GetLastSetting(numericalValues, sweepNo, key, DATA_ACQUISITION_MODE)

	INFO("key: %s", s0 = key)

	if(IsNaN(expected))
		CHECK_WAVE(settings, NULL_WAVE)
		return NaN
	endif

	CHECK_WAVE(settings, NUMERIC_WAVE)
	CHECK_CLOSE_VAR(settings[0], expected, tol = tol)
End

static Function CheckSutterLBNTextEntry(WAVE/T textualValues, variable sweepNo, string key, string expected)

	string actual

	WAVE/Z/T settings = GetLastSetting(textualValues, sweepNo, key, DATA_ACQUISITION_MODE)

	INFO("key: %s", s0 = key)

	CHECK_WAVE(settings, TEXT_WAVE)
	actual = settings[0]
	CHECK_EQUAL_STR(actual, expected)
End

/// @brief Check the labnotebook entries common to both clamp modes
static Function CheckSutterLBNCommon(string device, variable sweepNo, variable clampMode)

	string serial, str

	WAVE   numericalValues = GetLBNumericalValues(device)
	WAVE/T textualValues   = GetLBTextualValues(device)

	CheckSutterLBNEntry(numericalValues, sweepNo, "Operating Mode", clampMode)
	CheckSutterLBNEntry(numericalValues, sweepNo, "Channel ID", 1)

	WAVE/Z serialNumber = GetLastSetting(numericalValues, sweepNo, "Serial Number", DATA_ACQUISITION_MODE)
	CHECK_WAVE(serialNumber, NUMERIC_WAVE)

	WAVE/Z settings = GetLastSetting(numericalValues, sweepNo, "LPF Cutoff", DATA_ACQUISITION_MODE)
	CHECK_WAVE(settings, NUMERIC_WAVE)
	CHECK_GT_VAR(settings[0], 0)

	CheckSutterLBNTextEntry(textualValues, sweepNo, "OperatingModeString", SelectString(clampMode == V_CLAMP_MODE, "I-Clamp", "V-Clamp"))

	WAVE/Z/T settingsText = GetLastSetting(textualValues, sweepNo, "HardwareTypeString", DATA_ACQUISITION_MODE)
	CHECK_WAVE(settingsText, TEXT_WAVE)
	str = settingsText[0]
	CHECK_EQUAL_VAR(GrepString(str, SUTTER_HARDWARE_TYPE_REGEXP), 1)

	WAVE/Z/T settingsText = GetLastSetting(textualValues, sweepNo, "Amplifier Serial Number", DATA_ACQUISITION_MODE)
	CHECK_WAVE(settingsText, TEXT_WAVE)
	serial = settingsText[0]
	CHECK_EQUAL_VAR(GrepString(serial, SUTTER_SERIAL_REGEXP), 1)

	// the numeric serial number contains all digits of the serial, including the device type
	CHECK_EQUAL_VAR(serialNumber[0], str2num(StringFromList(ItemsInList(serial, "_") - 1, serial, "_")))

	// MCC only
	CheckSutterLBNEntry(numericalValues, sweepNo, "Osc Killer Enable", NaN)
	CheckSutterLBNEntry(numericalValues, sweepNo, "Slow compensation capacitance", NaN)
	CheckSutterLBNEntry(numericalValues, sweepNo, "Slow current injection", NaN)
End

static Function CheckSutterLabnotebookVC_preAcq(string device)

	PGC_SetAndActivateControl(device, "check_Settings_SyncMiesToMCC", val = 1)

	AI_WriteToAmplifier(device, 0, V_CLAMP_MODE, MCC_HOLDING_FUNC, 5, sendToAll = 0)
	AI_WriteToAmplifier(device, 0, V_CLAMP_MODE, MCC_HOLDINGENABLE_FUNC, 1, sendToAll = 0)
	AI_WriteToAmplifier(device, 0, V_CLAMP_MODE, MCC_WHOLECELLCOMPCAP_FUNC, 20, sendToAll = 0)
	AI_WriteToAmplifier(device, 0, V_CLAMP_MODE, MCC_WHOLECELLCOMPRESIST_FUNC, 8, sendToAll = 0)
	AI_WriteToAmplifier(device, 0, V_CLAMP_MODE, MCC_WHOLECELLCOMPENABLE_FUNC, 1, sendToAll = 0)
	AI_WriteToAmplifier(device, 0, V_CLAMP_MODE, MCC_RSCOMPCORRECTION_FUNC, 30, sendToAll = 0)
	AI_WriteToAmplifier(device, 0, V_CLAMP_MODE, MCC_PIPETTEOFFSET_FUNC, 3, sendToAll = 0)
End

// UTF_TD_GENERATOR s0:DataGenerators#DeviceNameGeneratorMD1
static Function CheckSutterLabnotebookVC([STRUCT IUTF_MDATA &md])

	[STRUCT ACD_DAQSettings s] = ACD_InitDAQSettingsFromString("MD1_RA0_I0_L0_BKG1"                      + \
	                                                           "__HS0_DA0_AD0_CM:VC:_ST:StimulusSetA_DA_0:")
	ACD_AcquireData(s, md.s0)
End

static Function CheckSutterLabnotebookVC_REENTRY([STRUCT IUTF_MDATA &md])

	string   device  = md.s0
	variable sweepNo = 0

	CHECK_EQUAL_VAR(AFH_GetLastSweepAcquired(device), sweepNo)

	WAVE numericalValues = GetLBNumericalValues(device)

	CheckSutterLBNEntry(numericalValues, sweepNo, "V-Clamp Holding Enable", 1)
	CheckSutterLBNEntry(numericalValues, sweepNo, "V-Clamp Holding Level", 5)
	CheckSutterLBNEntry(numericalValues, sweepNo, "Whole Cell Comp Enable", 1)
	CheckSutterLBNEntry(numericalValues, sweepNo, "Whole Cell Comp Cap", 20)
	CheckSutterLBNEntry(numericalValues, sweepNo, "Whole Cell Comp Resist", 8)
	CheckSutterLBNEntry(numericalValues, sweepNo, "Membrane Cap", 20)
	CheckSutterLBNEntry(numericalValues, sweepNo, "Series Resistance", 8)
	CheckSutterLBNEntry(numericalValues, sweepNo, "RsComp Correction", 30)
	// the offset DAC has a resolution of 15 uV
	CheckSutterLBNEntry(numericalValues, sweepNo, "Pipette Offset", 3, tol = 1e-2)

	WAVE/Z settings = GetLastSetting(numericalValues, sweepNo, "V-Clamp Output Gain", DATA_ACQUISITION_MODE)
	CHECK_WAVE(settings, NUMERIC_WAVE)
	CHECK_GT_VAR(settings[0], 0)

	WAVE/Z settings = GetLastSetting(numericalValues, sweepNo, "RsComp Lag", DATA_ACQUISITION_MODE)
	CHECK_WAVE(settings, NUMERIC_WAVE)
	CHECK_GT_VAR(settings[0], 0)

	// IC only
	CheckSutterLBNEntry(numericalValues, sweepNo, "I-Clamp Holding Level", NaN)
	CheckSutterLBNEntry(numericalValues, sweepNo, "I-Clamp Output Gain", NaN)
	CheckSutterLBNEntry(numericalValues, sweepNo, "Dynamic Hold Enable", NaN)

	CheckSutterLBNCommon(device, sweepNo, V_CLAMP_MODE)
End

static Function CheckSutterLabnotebookIC_preAcq(string device)

	PGC_SetAndActivateControl(device, "check_Settings_SyncMiesToMCC", val = 1)

	AI_WriteToAmplifier(device, 0, I_CLAMP_MODE, MCC_HOLDING_FUNC, 50, sendToAll = 0)
	AI_WriteToAmplifier(device, 0, I_CLAMP_MODE, MCC_HOLDINGENABLE_FUNC, 1, sendToAll = 0)
	AI_WriteToAmplifier(device, 0, I_CLAMP_MODE, MCC_BRIDGEBALRESIST_FUNC, 10, sendToAll = 0)
	AI_WriteToAmplifier(device, 0, I_CLAMP_MODE, MCC_BRIDGEBALENABLE_FUNC, 1, sendToAll = 0)
	AI_WriteToAmplifier(device, 0, I_CLAMP_MODE, MCC_NEUTRALIZATIONCAP_FUNC, 2, sendToAll = 0)
	AI_WriteToAmplifier(device, 0, I_CLAMP_MODE, MCC_NEUTRALIZATIONENABL_FUNC, 1, sendToAll = 0)
End

// UTF_TD_GENERATOR s0:DataGenerators#DeviceNameGeneratorMD1
static Function CheckSutterLabnotebookIC([STRUCT IUTF_MDATA &md])

	[STRUCT ACD_DAQSettings s] = ACD_InitDAQSettingsFromString("MD1_RA0_I0_L0_BKG1"                      + \
	                                                           "__HS0_DA0_AD0_CM:IC:_ST:StimulusSetA_DA_0:")
	ACD_AcquireData(s, md.s0)
End

static Function CheckSutterLabnotebookIC_REENTRY([STRUCT IUTF_MDATA &md])

	string   device  = md.s0
	variable sweepNo = 0

	CHECK_EQUAL_VAR(AFH_GetLastSweepAcquired(device), sweepNo)

	WAVE numericalValues = GetLBNumericalValues(device)

	CheckSutterLBNEntry(numericalValues, sweepNo, "I-Clamp Holding Enable", 1)
	CheckSutterLBNEntry(numericalValues, sweepNo, "I-Clamp Holding Level", 50)
	CheckSutterLBNEntry(numericalValues, sweepNo, "Bridge Bal Enable", 1)
	CheckSutterLBNEntry(numericalValues, sweepNo, "Bridge Bal Value", 10)
	CheckSutterLBNEntry(numericalValues, sweepNo, "Neut Cap Enabled", 1)
	CheckSutterLBNEntry(numericalValues, sweepNo, "Neut Cap Value", 2)

	WAVE/Z settings = GetLastSetting(numericalValues, sweepNo, "I-Clamp Output Gain", DATA_ACQUISITION_MODE)
	CHECK_WAVE(settings, NUMERIC_WAVE)
	CHECK_GT_VAR(settings[0], 0)

	// no MIES control, state of the IPA control package
	WAVE/Z settings = GetLastSetting(numericalValues, sweepNo, "Dynamic Hold Enable", DATA_ACQUISITION_MODE)
	CHECK_WAVE(settings, NUMERIC_WAVE)

	WAVE/Z settings = GetLastSetting(numericalValues, sweepNo, "Autobias", DATA_ACQUISITION_MODE)
	CHECK_WAVE(settings, NUMERIC_WAVE)

	// VC only
	CheckSutterLBNEntry(numericalValues, sweepNo, "V-Clamp Holding Level", NaN)
	CheckSutterLBNEntry(numericalValues, sweepNo, "V-Clamp Output Gain", NaN)
	CheckSutterLBNEntry(numericalValues, sweepNo, "RsComp Lag", NaN)

	CheckSutterLBNCommon(device, sweepNo, I_CLAMP_MODE)
End

#endif // TESTS_WITH_SUTTER_HARDWARE

static Function CheckRsCompSettings(string device, variable headstage, variable correction, variable prediction)

	variable actual

	WAVE ampStorageWave = GetAmplifierParamStorageWave(device)

	INFO("headstage %d", n0 = headstage)

	CHECK_CLOSE_VAR(ampStorageWave[%Correction][0][headstage], correction, tol = 1e-3)
	CHECK_CLOSE_VAR(ampStorageWave[%Prediction][0][headstage], prediction, tol = 1e-3)

	// only the prediction, which is always written last, as the MCC application
	// can change the correction when the prediction is set
	actual = AI_ReadFromAmplifier(device, headstage, V_CLAMP_MODE, MCC_RSCOMPPREDICTION_FUNC)
	CHECK_CLOSE_VAR(actual, prediction, tol = 1e-3)
End

static Function CheckSendToAllAmplifiers_preAcq(string device)

	PGC_SetAndActivateControl(device, "check_Settings_SyncMiesToMCC", val = 1)
End

/// Writing the Rs chaining or a chained Rs correction with "send to all" must apply the requested
/// function and value to every headstage
// UTF_TD_GENERATOR s0:DataGenerators#DeviceNameGeneratorMD1
static Function CheckSendToAllAmplifiers([STRUCT IUTF_MDATA &md])

	variable ret, headstage
	string device

	device = md.s0

	[STRUCT ACD_DAQSettings s] = ACD_InitDAQSettingsFromString("MD1_RA0_I0_L0_BKG1_TP0_DAQ0"                + \
	                                                           "__HS0_DA0_AD0_CM:VC:_ST:StimulusSetA_DA_0:" + \
	                                                           "__HS1_DA1_AD1_CM:VC:_ST:StimulusSetA_DA_0:")
	ACD_AcquireData(s, device)

	PGC_SetAndActivateControl(device, "slider_DataAcq_ActiveHeadstage", val = 0)
	PGC_SetAndActivateControl(device, "Check_DataAcq_SendToAllAmp", val = 0)

	// different settings per headstage
	Make/FREE/D correction = {10, 20}
	Make/FREE/D prediction = {10, 5}

	for(headstage = 0; headstage < 2; headstage += 1)
		ret = AI_WriteToAmplifier(device, headstage, V_CLAMP_MODE, MCC_NO_AMPCHAIN_FUNC, 0, sendToAll = 0)
		CHECK_EQUAL_VAR(ret, 0)
		ret = AI_WriteToAmplifier(device, headstage, V_CLAMP_MODE, MCC_RSCOMPCORRECTION_FUNC, correction[headstage], sendToAll = 0)
		CHECK_EQUAL_VAR(ret, 0)
		ret = AI_WriteToAmplifier(device, headstage, V_CLAMP_MODE, MCC_RSCOMPPREDICTION_FUNC, prediction[headstage], sendToAll = 0)
		CHECK_EQUAL_VAR(ret, 0)

		// enabling the chaining keeps the settings
		ret = AI_WriteToAmplifier(device, headstage, V_CLAMP_MODE, MCC_NO_AMPCHAIN_FUNC, 1, sendToAll = 0)
		CHECK_EQUAL_VAR(ret, 0)

		CheckRsCompSettings(device, headstage, correction[headstage], prediction[headstage])
	endfor

	PGC_SetAndActivateControl(device, "Check_DataAcq_SendToAllAmp", val = 1)

	// toggling the chaining on all headstages keeps the settings of each headstage
	ret = AI_WriteToAmplifier(device, 0, V_CLAMP_MODE, MCC_NO_AMPCHAIN_FUNC, 0)
	CHECK_EQUAL_VAR(ret, 0)
	ret = AI_WriteToAmplifier(device, 0, V_CLAMP_MODE, MCC_NO_AMPCHAIN_FUNC, 1)
	CHECK_EQUAL_VAR(ret, 0)

	for(headstage = 0; headstage < 2; headstage += 1)
		CheckRsCompSettings(device, headstage, correction[headstage], prediction[headstage])
	endfor

	// correction and with chaining also the prediction change by the same amount on each headstage
	ret = AI_WriteToAmplifier(device, 0, V_CLAMP_MODE, MCC_RSCOMPCORRECTION_FUNC, 30)
	CHECK_EQUAL_VAR(ret, 0)

	CheckRsCompSettings(device, 0, 30, 30)
	CheckRsCompSettings(device, 1, 30, 15)

	// GUI shows the settings of the selected headstage
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(device, "setvar_DataAcq_RsCorr"), 30)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(device, "setvar_DataAcq_RsPred"), 30)

	PGC_SetAndActivateControl(device, "Check_DataAcq_SendToAllAmp", val = 0)
End

// UTF_TD_GENERATOR v0:DataGenerators#GetClampModes
static Function CheckAmplifierScaling([STRUCT IUTF_MDATA &md])

	variable forward, backward, clampMode

	clampMode = md.v0
	WAVE funcs = DataGenerators#GetAmplifierFuncs()

	for(func : funcs)
		forward  = MIES_AIMCC#AIMCC_GetMCCScale(clampMode, func, MCC_READ)
		backward = MIES_AIMCC#AIMCC_GetMCCScale(clampMode, func, MCC_WRITE)

		CHECK_EQUAL_VAR(forward * backward, 1)
	endfor
End

static Function CheckZeroAmps_preAcq(string device)

	variable ret

	PGC_SetAndActivateControl(device, "check_Settings_SyncMiesToMCC", val = 1)

	ret = AI_WriteToAmplifier(device, 0, V_CLAMP_MODE, MCC_PIPETTEOFFSET_FUNC, 0, sendToAll = 0)
	CHECK_EQUAL_VAR(ret, 0)
	ret = AI_WriteToAmplifier(device, 1, V_CLAMP_MODE, MCC_PIPETTEOFFSET_FUNC, 30, sendToAll = 0)
	CHECK_EQUAL_VAR(ret, 0)
End

/// AI_ZeroAmps corrects the pipette offset by the baseline current of the running test pulse,
/// but only for headstages with a baseline current above the zero tolerance
///
/// See ZeroAmpsAndStopTP_IGNORE() for the used test pulse results.
// UTF_TD_GENERATOR s0:DataGenerators#DeviceNameGeneratorMD1
// UTF_TD_GENERATOR v0:DataGenerators#ZeroAmpsHeadstageSelection
static Function CheckZeroAmps([STRUCT IUTF_MDATA &md])

	[STRUCT ACD_DAQSettings s] = ACD_InitDAQSettingsFromString("MD1_RA0_I0_L0_BKG1_TP1"                       \
	                                                           + "__HS0_DA0_AD0_CM:VC:_ST:StimulusSetA_DA_0:" \
	                                                           + "__HS1_DA1_AD1_CM:VC:_ST:StimulusSetA_DA_0:")

	variable/G root:zeroAmpsAllHeadstages = md.v0

	CtrlNamedBackGround ZeroAmps, start=(ticks + 180), period=30, proc=ZeroAmpsAndStopTP_IGNORE

	ACD_AcquireData(s, md.s0)
End

static Function CheckZeroAmps_REENTRY([STRUCT IUTF_MDATA &md])

	variable delta, expected, headstage, ret, storedOffsetVC, storedOffsetIC
	string rowLabel, device

	device = md.s0

	WAVE/Z results = root:zeroAmpsResults
	CHECK_WAVE(results, NUMERIC_WAVE)
	Duplicate/FREE results, zeroAmpsResults
	KillWaves results
	KillVariables root:zeroAmpsAllHeadstages

	// the offset of headstage 1 is set in both clamp modes
	WAVE ampStorageWave = GetAmplifierParamStorageWave(device)
	rowLabel       = AI_MapFunctionConstantToName(MCC_PIPETTEOFFSET_FUNC, V_CLAMP_MODE)
	storedOffsetVC = ampStorageWave[%$rowLabel][0][1]
	rowLabel       = AI_MapFunctionConstantToName(MCC_PIPETTEOFFSET_FUNC, I_CLAMP_MODE)
	storedOffsetIC = ampStorageWave[%$rowLabel][0][1]

	// reset the amplifier
	for(headstage = 0; headstage < 2; headstage += 1)
		ret = AI_WriteToAmplifier(device, headstage, V_CLAMP_MODE, MCC_PIPETTEOFFSET_FUNC, 0, sendToAll = 0)
		CHECK_EQUAL_VAR(ret, 0)
	endfor

	// headstage 0 is unchanged
	CHECK_CLOSE_VAR(zeroAmpsResults[%OffsetAfter][0], zeroAmpsResults[%OffsetBefore][0], tol = 1e-3)

	// headstage 1 is corrected, see AI_MIESAutoPipetteOffset
	headstage = 1
	delta     = zeroAmpsResults[%Baseline][headstage] * PICO_TO_ONE * zeroAmpsResults[%Resistance][headstage] * MEGA_TO_ONE * ONE_TO_MILLI
	expected  = zeroAmpsResults[%OffsetBefore][headstage] - delta
	CHECK_CLOSE_VAR(expected, 10, tol = 1e-3)

	CHECK_CLOSE_VAR(zeroAmpsResults[%OffsetAfter][headstage], expected, tol = 0.1)
	CHECK_CLOSE_VAR(storedOffsetVC, zeroAmpsResults[%OffsetAfter][headstage], tol = 1e-3)
	CHECK_CLOSE_VAR(storedOffsetIC, zeroAmpsResults[%OffsetAfter][headstage], tol = 1e-3)
End

static Function CheckAutoBridgeBalanceFailure_preAcq(string device)

	PGC_SetAndActivateControl(device, "check_Settings_SyncMiesToMCC", val = 1)
End

/// A failed automatic bridge balance must not enable the bridge balance
// UTF_TD_GENERATOR s0:DataGenerators#DeviceNameGeneratorMD1
static Function CheckAutoBridgeBalanceFailure([STRUCT IUTF_MDATA &md])

	variable ret
	string device, rowLabel

	device = md.s0

	[STRUCT ACD_DAQSettings s] = ACD_InitDAQSettingsFromString("MD1_RA0_I0_L0_BKG1_TP0_DAQ0"             + \
	                                                           "__HS0_DA0_AD0_CM:VC:_ST:StimulusSetA_DA_0:")
	ACD_AcquireData(s, device)

	PGC_SetAndActivateControl(device, "slider_DataAcq_ActiveHeadstage", val = 0)
	PGC_SetAndActivateControl(device, "Check_DataAcq_SendToAllAmp", val = 0)

	// the headstage is in voltage clamp, so the current clamp settings are only stored
	ret = AI_WriteToAmplifier(device, 0, I_CLAMP_MODE, MCC_BRIDGEBALRESIST_FUNC, 10)
	CHECK_EQUAL_VAR(ret, 0)
	ret = AI_WriteToAmplifier(device, 0, I_CLAMP_MODE, MCC_BRIDGEBALENABLE_FUNC, 0)
	CHECK_EQUAL_VAR(ret, 0)

	// fails as the headstage is in voltage clamp
	AI_WriteToAmplifier(device, 0, I_CLAMP_MODE, MCC_AUTOBRIDGEBALANCE_FUNC, 1, GUIWrite = 0)

	WAVE ampStorageWave = GetAmplifierParamStorageWave(device)
	rowLabel = AI_MapFunctionConstantToName(MCC_BRIDGEBALRESIST_FUNC, I_CLAMP_MODE)
	CHECK_CLOSE_VAR(ampStorageWave[%$rowLabel][0][0], 10, tol = 1e-3)
	rowLabel = AI_MapFunctionConstantToName(MCC_BRIDGEBALENABLE_FUNC, I_CLAMP_MODE)
	CHECK_EQUAL_VAR(ampStorageWave[%$rowLabel][0][0], 0)

	CHECK_CLOSE_VAR(DAG_GetNumericalValue(device, "setvar_DataAcq_BB"), 10, tol = 1e-3)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(device, "check_DatAcq_BBEnable"), 0)
End

static Function CheckAutoBridgeBalance_preAcq(string device)

	PGC_SetAndActivateControl(device, "check_Settings_SyncMiesToMCC", val = 1)
End

/// The automatic bridge balance enables the bridge balance with the resistance of the amplifier
// UTF_TD_GENERATOR s0:DataGenerators#DeviceNameGeneratorMD1
static Function CheckAutoBridgeBalance([STRUCT IUTF_MDATA &md])

	variable ret, resistance
	string device, rowLabel

	device = md.s0

	[STRUCT ACD_DAQSettings s] = ACD_InitDAQSettingsFromString("MD1_RA0_I0_L0_BKG1_TP0_DAQ0" + "__HS0_DA0_AD0_CM:IC:_ST:StimulusSetA_DA_0:")
	ACD_AcquireData(s, device)

	PGC_SetAndActivateControl(device, "slider_DataAcq_ActiveHeadstage", val = 0)
	PGC_SetAndActivateControl(device, "Check_DataAcq_SendToAllAmp", val = 0)

	ret = AI_WriteToAmplifier(device, 0, I_CLAMP_MODE, MCC_BRIDGEBALENABLE_FUNC, 0)
	CHECK_EQUAL_VAR(ret, 0)

	ret = AI_WriteToAmplifier(device, 0, I_CLAMP_MODE, MCC_AUTOBRIDGEBALANCE_FUNC, 1, GUIWrite = 0)
	CHECK_EQUAL_VAR(ret, 0)

	resistance = AI_ReadFromAmplifier(device, 0, I_CLAMP_MODE, MCC_BRIDGEBALRESIST_FUNC)
	CHECK_EQUAL_VAR(IsFinite(resistance), 1)

	WAVE ampStorageWave = GetAmplifierParamStorageWave(device)
	rowLabel = AI_MapFunctionConstantToName(MCC_BRIDGEBALRESIST_FUNC, I_CLAMP_MODE)
	CHECK_CLOSE_VAR(ampStorageWave[%$rowLabel][0][0], resistance, tol = 1e-3)
	rowLabel = AI_MapFunctionConstantToName(MCC_BRIDGEBALENABLE_FUNC, I_CLAMP_MODE)
	CHECK_EQUAL_VAR(ampStorageWave[%$rowLabel][0][0], 1)

	CHECK_EQUAL_VAR(DAG_GetNumericalValue(device, "check_DatAcq_BBEnable"), 1)

	// reset the amplifier
	ret = AI_WriteToAmplifier(device, 0, I_CLAMP_MODE, MCC_BRIDGEBALENABLE_FUNC, 0)
	CHECK_EQUAL_VAR(ret, 0)
End

static Function CheckSendToAllAutoWholeCellComp_preAcq(string device)

	PGC_SetAndActivateControl(device, "check_Settings_SyncMiesToMCC", val = 1)
End

/// The automatic whole cell compensation with "send to all" must be executed for every headstage
// UTF_TD_GENERATOR s0:DataGenerators#DeviceNameGeneratorMD1
static Function CheckSendToAllAutoWholeCellComp([STRUCT IUTF_MDATA &md])

	variable ret, headstage, actual
	string device, rowLabel

	device = md.s0

	[STRUCT ACD_DAQSettings s] = ACD_InitDAQSettingsFromString("MD1_RA0_I0_L0_BKG1_TP0_DAQ0"                + \
	                                                           "__HS0_DA0_AD0_CM:VC:_ST:StimulusSetA_DA_0:" + \
	                                                           "__HS1_DA1_AD1_CM:VC:_ST:StimulusSetA_DA_0:")
	ACD_AcquireData(s, device)

	PGC_SetAndActivateControl(device, "slider_DataAcq_ActiveHeadstage", val = 0)
	PGC_SetAndActivateControl(device, "Check_DataAcq_SendToAllAmp", val = 1)

	// invalid capacitance, so that the update from the amplifier is visible
	WAVE ampStorageWave = GetAmplifierParamStorageWave(device)
	rowLabel                            = AI_MapFunctionConstantToName(MCC_WHOLECELLCOMPCAP_FUNC, V_CLAMP_MODE)
	ampStorageWave[%$rowLabel][0][0, 1] = -1

	ret = AI_WriteToAmplifier(device, 0, V_CLAMP_MODE, MCC_AUTOWHOLECELLCOMP_FUNC, 1, GUIWrite = 0)
	CHECK_EQUAL_VAR(ret, 0)

	for(headstage = 0; headstage < 2; headstage += 1)
		INFO("headstage %d", n0 = headstage)

		actual = AI_ReadFromAmplifier(device, headstage, V_CLAMP_MODE, MCC_WHOLECELLCOMPCAP_FUNC)
		CHECK_GE_VAR(actual, 0)
		CHECK_CLOSE_VAR(ampStorageWave[%$rowLabel][0][headstage], actual, tol = 1e-3)
	endfor

	// reset the amplifier
	ret = AI_WriteToAmplifier(device, 0, V_CLAMP_MODE, MCC_WHOLECELLCOMPENABLE_FUNC, 0)
	CHECK_EQUAL_VAR(ret, 0)

	PGC_SetAndActivateControl(device, "Check_DataAcq_SendToAllAmp", val = 0)
End

static Function CheckHoldingCommand_preAcq(string device)

	PGC_SetAndActivateControl(device, "check_Settings_SyncMiesToMCC", val = 1)
End

/// The holding command of the amplifier is returned in mV (VC) or pA (IC) and zero if disabled
// UTF_TD_GENERATOR s0:DataGenerators#DeviceNameGeneratorMD1
// UTF_TD_GENERATOR v0:DataGenerators#GetClampModesWithoutIZero
static Function CheckHoldingCommand([STRUCT IUTF_MDATA &md])

	variable ret, value, clampMode, headstage
	string device, clampModeStr

	device    = md.s0
	clampMode = md.v0
	headstage = 0

	clampModeStr = SelectString(clampMode == V_CLAMP_MODE, "IC", "VC")

	[STRUCT ACD_DAQSettings s] = ACD_InitDAQSettingsFromString("MD1_RA0_I0_L0_BKG1_TP0_DAQ0"                                                        + \
	                                                           "__HS" + num2str(headstage) + "_DA0_AD0_CM:" + clampModeStr + ":_ST:StimulusSetA_DA_0:")
	ACD_AcquireData(s, device)

	value = (clampMode == V_CLAMP_MODE) ? -20 : 50

	ret = AI_WriteToAmplifier(device, headstage, clampMode, MCC_HOLDING_FUNC, value)
	CHECK_EQUAL_VAR(ret, 0)
	ret = AI_WriteToAmplifier(device, headstage, clampMode, MCC_HOLDINGENABLE_FUNC, 1)
	CHECK_EQUAL_VAR(ret, 0)

	CHECK_CLOSE_VAR(AI_GetHoldingCommand(device, headstage), value, tol = 1e-2)

	ret = AI_WriteToAmplifier(device, headstage, clampMode, MCC_HOLDINGENABLE_FUNC, 0)
	CHECK_EQUAL_VAR(ret, 0)

	CHECK_SMALL_VAR(AI_GetHoldingCommand(device, headstage))
End

/// A different clamp mode of the amplifier is switched back to the one of MIES
// UTF_TD_GENERATOR s0:DataGenerators#DeviceNameGeneratorMD1
static Function CheckEnsureCorrectMode([STRUCT IUTF_MDATA &md])

	variable ret, headstage
	string device

	device    = md.s0
	headstage = 0

	[STRUCT ACD_DAQSettings s] = ACD_InitDAQSettingsFromString("MD1_RA0_I0_L0_BKG1_TP0_DAQ0"                 \
	                                                           + "__HS0_DA0_AD0_CM:VC:_ST:StimulusSetA_DA_0:")
	ACD_AcquireData(s, device)

	// only switch the amplifier
	AI_SetClampMode(device, headstage, I_CLAMP_MODE)
	CHECK_EQUAL_VAR(AI_GetMode(device, headstage), I_CLAMP_MODE)
	CHECK_EQUAL_VAR(DAG_GetHeadstageMode(device, headstage), V_CLAMP_MODE)

	ret = AI_EnsureCorrectMode(device, headstage, selectAmp = 1)
	CHECK_EQUAL_VAR(ret, 0)
	CHECK_EQUAL_VAR(AI_GetMode(device, headstage), V_CLAMP_MODE)
End
