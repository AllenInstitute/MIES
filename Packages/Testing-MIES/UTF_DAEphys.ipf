#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma ModuleName=DAEphysPanel

Function CheckIfAllControlsReferStateWv()

	string unlockedPanelTitle, list, ctrl, str, expected, lbl, uniqueControls
	variable i, numEntries, val, channelIndex, channelType, controlType, index, oldVal
	variable err, inputModified

	Initialize_IGNORE()

	unlockedPanelTitle = DAP_CreateDAEphysPanel()

	ChooseCorrectDevice(unlockedPanelTitle, DEVICE)
	PGC_SetAndActivateControl(unlockedPanelTitle, "button_SettingsPlus_LockDevice")
	REQUIRE(WindowExists(DEVICE))

	list  = ControlNameList(DEVICE, ";")

	uniqueControls = MIES_DAG#DAG_GetUniqueCtrlList(DEVICE)

	numEntries = ItemsInList(list)
	CHECK(numEntries > 0)
	for(i = 0; i < numEntries; i += 1)
		ctrl = StringFromList(i, list)
		ControlInfo/W=$DEVICE $ctrl

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
		if(IsControlDisabled(DEVICE, ctrl))
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
					PGC_SetAndActivateControl(DEVICE, ctrl, val = val); err = GetRTError(1)
				catch
					// do nothing
				endtry

				CHECK_EQUAL_VAR(GetCheckBoxState(DEVICE, ctrl), val)
				CHECK_EQUAL_VAR(DAG_GetNumericalValue(DEVICE, lbl, index = index), val)
				// undo
				PGC_SetAndActivateControl(DEVICE, ctrl, val = oldVal)
				break
			case CONTROL_TYPE_SETVARIABLE:
				if(DoesControlHaveInternalString(DEVICE, ctrl))
					str = NONE
					KillOrMoveToTrash(wv = GetDA_EphysGuiStateTxT(DEVICE))

					try
						PGC_SetAndActivateControl(DEVICE, ctrl, str = str); err = GetRTError(1)
					catch
						// do nothing
					endtry

					// if the gui state wave exists we wrote into it
					WAVE/Z/SDFR=GetDevicePath(DEVICE) DA_EphysGuiStateTxT
					CHECK_WAVE(DA_EphysGuiStateTxT, TEXT_WAVE)
					expected = DAG_GetTextualValue(DEVICE, lbl, index = index)
					CHECK_EQUAL_STR(expected, str)
				else
					val = 0
					KillOrMoveToTrash(wv = GetDA_EphysGuiStateNum(DEVICE))

					try
						inputModified = PGC_SetAndActivateControl(DEVICE, ctrl, val = val); err = GetRTError(1)
					catch
						// do nothing
					endtry

					// if the gui state wave exists we wrote into it
					WAVE/Z/SDFR=GetDevicePath(DEVICE) DA_EphysGuiStateNum
					CHECK_WAVE(DA_EphysGuiStateNum, NUMERIC_WAVE)

					if(inputModified)
						val = GetLimitConstrainedSetVar(DEVICE, ctrl, val)
					endif

					CHECK_EQUAL_VAR(DAG_GetNumericalValue(DEVICE, lbl, index = index), val)
				endif

				break
			case CONTROL_TYPE_SLIDER:

				val = 0
				KillOrMoveToTrash(wv = GetDA_EphysGuiStateNum(DEVICE))

				try
					PGC_SetAndActivateControl(DEVICE, ctrl, val = val); err = GetRTError(1)
				catch
					// do nothing
				endtry

				// if the gui state wave exists we wrote into it
				WAVE/Z/SDFR=GetDevicePath(DEVICE) DA_EphysGuiStateNum
				CHECK_WAVE(DA_EphysGuiStateNum, NUMERIC_WAVE)
				CHECK_EQUAL_VAR(DAG_GetNumericalValue(DEVICE, lbl, index = index), val)

				break
			case CONTROL_TYPE_POPUPMENU:

				oldVal = GetPopupMenuIndex(DEVICE, ctrl)
				val = 1
				KillOrMoveToTrash(wv = GetDA_EphysGuiStateNum(DEVICE))
				KillOrMoveToTrash(wv = GetDA_EphysGuiStateTxT(DEVICE))

				try
					PGC_SetAndActivateControl(DEVICE, ctrl, val = val); err = GetRTError(1)
				catch
					// do nothing
				endtry

				str = GetPopupMenuString(DEVICE, ctrl)
				// if the gui state wave exists we wrote into it
				WAVE/Z/SDFR=GetDevicePath(DEVICE) DA_EphysGuiStateNum
				CHECK_WAVE(DA_EphysGuiStateNum, NUMERIC_WAVE)

				WAVE/Z/SDFR=GetDevicePath(DEVICE) DA_EphysGuiStateTxT
				CHECK_WAVE(DA_EphysGuiStateTxT, TEXT_WAVE)

				CHECK_EQUAL_VAR(DAG_GetNumericalValue(DEVICE, lbl, index = index), val)

				expected = DAG_GetTextualValue(DEVICE, lbl, index = index)
				CHECK_EQUAL_STR(expected, str)
				// undo
				PGC_SetAndActivateControl(DEVICE, ctrl, val = oldVal)
				break
		endswitch
	endfor
End

Function CheckStartupSettings()

	string unlockedPanelTitle, list, ctrl, str, expected, lbl
	variable i, numEntries, val, channelIndex, channelType, controlType, index, oldVal

	Initialize_IGNORE()

	SetRandomSeed/BETR=1 1

	unlockedPanelTitle = DAP_CreateDAEphysPanel()

	ChooseCorrectDevice(unlockedPanelTitle, DEVICE)
	PGC_SetAndActivateControl(unlockedPanelTitle, "button_SettingsPlus_LockDevice")
	REQUIRE(WindowExists(DEVICE))

	Duplicate/O GetDA_EphysGuiStateNum(DEVICE), guiStateNumRef
	Duplicate/O GetDA_EphysGuiStateTxT(DEVICE), guiStateTxTRef

	PGC_SetAndActivateControl(DEVICE, "button_SettingsPlus_unLockDevic")
	unlockedPanelTitle = GetCurrentWindow()

	list  = ControlNameList(unlockedPanelTitle, ";")

	numEntries = ItemsInList(list)
	CHECK(numEntries > 0)
	for(i = 0; i < numEntries; i += 1)
		ctrl = StringFromList(i, list)
		ControlInfo/W=$unlockedPanelTitle $ctrl

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
				SetCheckBoxState(unlockedPanelTitle, ctrl, val)
				break
			case CONTROL_TYPE_SETVARIABLE:
				if(DoesControlHaveInternalString(unlockedPanelTitle, ctrl))
					SetSetVariableString(unlockedPanelTitle, ctrl, num2str(enoise(1, 2)))
				else
					SetSetVariable(unlockedPanelTitle, ctrl, enoise(5, 2))
				endif
				break
			case CONTROL_TYPE_SLIDER:

				oldVal = V_Value
				SetSliderPositionIndex(unlockedPanelTitle, ctrl, oldVal + 1)

				break
			case CONTROL_TYPE_POPUPMENU:

				SetPopupMenuIndex(unlockedPanelTitle, ctrl, 1 + enoise(2, 2))
				break
		endswitch
	endfor

	DAP_EphysPanelStartUpSettings()

	SCOPE_OpenScopeWindow(unlockedPanelTitle)
	AddVersionToPanel(unlockedPanelTitle, DA_EPHYS_PANEL_VERSION)

	ChooseCorrectDevice(unlockedPanelTitle, DEVICE)
	PGC_SetAndActivateControl(unlockedPanelTitle, "button_SettingsPlus_LockDevice")
	REQUIRE(WindowExists(DEVICE))

	Duplicate/O GetDA_EphysGuiStateNum(DEVICE), guiStateNumNew
	Duplicate/O GetDA_EphysGuiStateTxT(DEVICE), guiStateTxTNew

	CHECK_EQUAL_WAVES(guiStateNumRef, guiStateNumNew, mode = WAVE_DATA | DIMENSION_LABELS)
	CHECK_EQUAL_WAVES(guiStateTxTRef, guiStateTxTNew, mode = WAVE_DATA | DIMENSION_LABELS)
End
