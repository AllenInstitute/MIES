#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors = 1
#pragma ModuleName       = DAEphysPanel

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

	CreateLockedDAEphys(str)

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

	CreateLockedDAEphys(str, unlockedDevice = unlockedDevice)

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

	CreateLockedDAEphys(str, unlockedDevice = unlockedDevice)

	Duplicate/FREE GetDA_EphysGuiStateNum(str), guiStateNumNew
	Duplicate/FREE GetDA_EphysGuiStateTxT(str), guiStateTxTNew

	CHECK_EQUAL_WAVES(guiStateNumRef, guiStateNumNew, mode = WAVE_DATA | DIMENSION_LABELS)
	CHECK_EQUAL_WAVES(guiStateTxTRef, guiStateTxTNew, mode = WAVE_DATA | DIMENSION_LABELS)
End

// UTF_TD_GENERATOR DataGenerators#DeviceNameGeneratorMD1
Function CheckStimsetPopupMetadata([string str])

	string controls, stimsetlist, ctrl, menuExp
	variable i, numControls, channelIndex, channelType, controlType

	CreateLockedDAEphys(str)

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

	CreateLockedDAEphys(str)

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

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG1_DAQ0_TP0"                + \
	                             "__HS0_DA0_AD0_CM:VC:_ST:StimulusSetA_DA_0:" + \
	                             "__HS1_DA1_AD1_CM:IC:_ST:StimulusSetB_DA_0:")

	AcquireData_NG(s, str)

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

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG1_SIM8"                 + \
	                             "__HS0_DA0_AD0_CM:IC:_ST:StimulusSetA_DA_0:")

	refNum = CaptureHistoryStart()
	AcquireData_NG(s, md.s0)
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
	MIES_AI#AI_SendToAmp(device, 0, V_CLAMP_MODE, MCC_HOLDING_FUNC, MCC_WRITE, value = 5)

	PGC_SetAndActivateControl(device, "check_Settings_SyncMiesToMCC", val = 1)
End

// UTF_TD_GENERATOR s0:DataGenerators#DeviceNameGeneratorMD1
static Function SyncMIESMccWorksOutoftheBox([STRUCT IUTF_MDATA &md])

	variable headstage, func, clampMode, val, expected, actual
	string device, rowLabel

	device = md.s0

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG1_TP0_DAQ0"             + \
	                             "__HS0_DA0_AD0_CM:VC:_ST:StimulusSetA_DA_0:")
	AcquireData_NG(s, device)

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

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG1_TP0_DAQ0"                                                        + \
	                             "__HS" + num2str(headstage) + "_DA0_AD0_CM:" + clampModeStr + ":_ST:StimulusSetA_DA_0:")
	AcquireData_NG(s, device)

	clampMode = DAG_GetHeadstageMode(device, headstage)

	WAVE ampStorageWave = GetAmplifierParamStorageWave(device)

	WAVE funcs = DataGenerators#GetAmplifierFuncs()

	for(func : funcs)
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

// UTF_TD_GENERATOR v0:DataGenerators#GetClampModes
static Function CheckAmplifierScaling([STRUCT IUTF_MDATA &md])

	variable forward, backward, clampMode

	clampMode = md.v0
	WAVE funcs = DataGenerators#GetAmplifierFuncs()

	for(func : funcs)
		forward  = AI_GetMCCScale(clampMode, func, MCC_READ)
		backward = AI_GetMCCScale(clampMode, func, MCC_WRITE)

		CHECK_EQUAL_VAR(forward * backward, 1)
	endfor
End
