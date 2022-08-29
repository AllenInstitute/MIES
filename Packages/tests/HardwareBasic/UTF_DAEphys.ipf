#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma ModuleName=DAEphysPanel

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
Function CheckIfAllControlsReferStateWv([str])
	string str

	string unlockedDevice, list, ctrl, stri, expected, lbl, uniqueControls
	variable i, numEntries, val, channelIndex, channelType, controlType, index, oldVal
	variable err, inputModified

	unlockedDevice = DAP_CreateDAEphysPanel()

	PGC_SetAndActivateControl(unlockedDevice, "popup_MoreSettings_Devices", str=str)
	PGC_SetAndActivateControl(unlockedDevice, "button_SettingsPlus_LockDevice")
	REQUIRE(WindowExists(str))

	list  = ControlNameList(str, ";")

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

		// normal control
		print ctrl

		switch(abs(V_Flag))
			case CONTROL_TYPE_BUTTON:
			case CONTROL_TYPE_LISTBOX:
			case CONTROL_TYPE_TAB:
			case CONTROL_TYPE_VALDISPLAY:
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
				if(DoesControlHaveInternalString(S_recreation))
					stri = NONE
					KillOrMoveToTrash(wv = GetDA_EphysGuiStateTxT(str))

					try
						PGC_SetAndActivateControl(str, ctrl, str = stri); err = GetRTError(1)
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
						inputModified = PGC_SetAndActivateControl(str, ctrl, val = val); err = GetRTError(1)
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
				val = 0
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
		endswitch
	endfor
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
Function CheckStartupSettings([str])
	string str

	string unlockedDevice, list, ctrl, expected, lbl
	variable i, numEntries, val, channelIndex, channelType, controlType, index, oldVal

	SetRandomSeed/BETR=1 1

	unlockedDevice = DAP_CreateDAEphysPanel()

	PGC_SetAndActivateControl(unlockedDevice, "popup_MoreSettings_Devices", str=str)
	PGC_SetAndActivateControl(unlockedDevice, "button_SettingsPlus_LockDevice")
	REQUIRE(WindowExists(str))

	Duplicate/O GetDA_EphysGuiStateNum(str), guiStateNumRef
	Duplicate/O GetDA_EphysGuiStateTxT(str), guiStateTxTRef

	PGC_SetAndActivateControl(str, "button_SettingsPlus_unLockDevic")
	unlockedDevice = GetCurrentWindow()

	list  = ControlNameList(unlockedDevice, ";")

	numEntries = ItemsInList(list)
	CHECK_GT_VAR(numEntries, 0)
	for(i = 0; i < numEntries; i += 1)
		ctrl = StringFromList(i, list)
		ControlInfo/W=$unlockedDevice $ctrl

		switch(abs(V_Flag))
			case CONTROL_TYPE_BUTTON:
			case CONTROL_TYPE_LISTBOX:
			case CONTROL_TYPE_TAB:
			case CONTROL_TYPE_VALDISPLAY:
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
		endswitch
	endfor

	DAP_EphysPanelStartUpSettings()

	SCOPE_OpenScopeWindow(unlockedDevice)
	AddVersionToPanel(unlockedDevice, DA_EPHYS_PANEL_VERSION)

	PGC_SetAndActivateControl(unlockedDevice, "popup_MoreSettings_Devices", str=str)
	PGC_SetAndActivateControl(unlockedDevice, "button_SettingsPlus_LockDevice")
	REQUIRE(WindowExists(str))

	Duplicate/O GetDA_EphysGuiStateNum(str), guiStateNumNew
	Duplicate/O GetDA_EphysGuiStateTxT(str), guiStateTxTNew

	CHECK_EQUAL_WAVES(guiStateNumRef, guiStateNumNew, mode = WAVE_DATA | DIMENSION_LABELS)
	CHECK_EQUAL_WAVES(guiStateTxTRef, guiStateTxTNew, mode = WAVE_DATA | DIMENSION_LABELS)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
Function CheckStimsetPopupMetadata([str])
	string str

	string controls, stimsetlist, ctrl, menuExp
	variable i, numControls, channelIndex, channelType, controlType

	string unlockedDevice = DAP_CreateDAEphysPanel()

	PGC_SetAndActivateControl(unlockedDevice, "popup_MoreSettings_Devices", str=str)
	PGC_SetAndActivateControl(unlockedDevice, "button_SettingsPlus_LockDevice")

	controls = ControlNameList(str)
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