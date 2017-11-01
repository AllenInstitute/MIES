#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma ModuleName=DAEphysPanel

static StrConstant panelTitle = "ITC18USB_DEV_0"

Function CheckIfAllControlsReferStateWv()

	string unlockedPanelTitle, list, ctrl, str, expected, lbl
	variable i, numEntries, val, channelIndex, channelType, controlType, index, oldVal
	variable err, inputModified

	Initialize_IGNORE()

	unlockedPanelTitle = DAP_CreateDAEphysPanel()

	PGC_SetAndActivateControl(unlockedPanelTitle, "popup_MoreSettings_DeviceType", val=5)
	PGC_SetAndActivateControl(unlockedPanelTitle, "button_SettingsPlus_LockDevice")
	REQUIRE(WindowExists(panelTitle))

	list  = ControlNameList(panelTitle, ";")

	numEntries = ItemsInList(list)
	CHECK(numEntries > 0)
	for(i = 0; i < numEntries; i += 1)
		ctrl = StringFromList(i, list)
		ControlInfo/W=$panelTitle $ctrl

		if(!DAP_ParsePanelControl(ctrl, channelIndex, channelType, controlType) && channelIndex >= 0)
			index = channelIndex
			lbl   = GetSpecialControlLabel(channelType, controlType)
		else
			index = 0
			lbl   = ctrl
		endif

		// another special control
		if(GrepString(ctrl, "^Radio_ClampMode.*"))
			continue
		endif

		// ignore turned off controls
		if(IsControlDisabled(panelTitle, ctrl))
			continue
		endif

		// normal control

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
					PGC_SetAndActivateControl(panelTitle, ctrl, val = val); err = GetRTError(1)
				catch
					// do nothing
				endtry

				CHECK_EQUAL_VAR(GetCheckBoxState(panelTitle, ctrl), val)
				CHECK_EQUAL_VAR(DAP_GetValueFromNumStateWave(panelTitle, lbl, index = index), val)
				// undo
				PGC_SetAndActivateControl(panelTitle, ctrl, val = oldVal)
				break
			case CONTROL_TYPE_SETVARIABLE:
				if(DoesControlHaveInternalString(panelTitle, ctrl))
					str = NONE
					KillOrMoveToTrash(wv = GetDA_EphysGuiStateTxT(panelTitle))

					try
						PGC_SetAndActivateControl(panelTitle, ctrl, str = str); err = GetRTError(1)
					catch
						// do nothing
					endtry

					// if the gui state wave exists we wrote into it
					WAVE/Z/SDFR=GetDevicePath(panelTitle) DA_EphysGuiStateTxT
					CHECK_WAVE(DA_EphysGuiStateTxT, TEXT_WAVE)
					expected = DAP_GetValueFromTxTStateWave(panelTitle, lbl, index = index)
					CHECK_EQUAL_STR(expected, str)
				else
					val = 0
					KillOrMoveToTrash(wv = GetDA_EphysGuiStateNum(panelTitle))

					try
						inputModified = PGC_SetAndActivateControl(panelTitle, ctrl, val = val); err = GetRTError(1)
					catch
						// do nothing
					endtry

					// if the gui state wave exists we wrote into it
					WAVE/Z/SDFR=GetDevicePath(panelTitle) DA_EphysGuiStateNum
					CHECK_WAVE(DA_EphysGuiStateNum, NUMERIC_WAVE)

					if(inputModified)
						val = GetLimitConstrainedSetVar(panelTitle, ctrl, val)
					endif

					CHECK_EQUAL_VAR(DAG_GetNumericalValue(panelTitle, lbl, index = index), val)
				endif

				break
			case CONTROL_TYPE_SLIDER:

				val = 0
				KillOrMoveToTrash(wv = GetDA_EphysGuiStateNum(panelTitle))

				try
					PGC_SetAndActivateControl(panelTitle, ctrl, val = val); err = GetRTError(1)
				catch
					// do nothing
				endtry

				// if the gui state wave exists we wrote into it
				WAVE/Z/SDFR=GetDevicePath(panelTitle) DA_EphysGuiStateNum
				CHECK_WAVE(DA_EphysGuiStateNum, NUMERIC_WAVE)
				CHECK_EQUAL_VAR(DAP_GetValueFromNumStateWave(panelTitle, lbl, index = index), val)

				break
			case CONTROL_TYPE_POPUPMENU:

				oldVal = GetPopupMenuIndex(panelTitle, ctrl)
				val = 1
				KillOrMoveToTrash(wv = GetDA_EphysGuiStateNum(panelTitle))
				KillOrMoveToTrash(wv = GetDA_EphysGuiStateTxT(panelTitle))

				try
					PGC_SetAndActivateControl(panelTitle, ctrl, val = val); err = GetRTError(1)
				catch
					// do nothing
				endtry

				str = GetPopupMenuString(panelTitle, ctrl)
				// if the gui state wave exists we wrote into it
				WAVE/Z/SDFR=GetDevicePath(panelTitle) DA_EphysGuiStateNum
				CHECK_WAVE(DA_EphysGuiStateNum, NUMERIC_WAVE)

				WAVE/Z/SDFR=GetDevicePath(panelTitle) DA_EphysGuiStateTxT
				CHECK_WAVE(DA_EphysGuiStateTxT, TEXT_WAVE)

				CHECK_EQUAL_VAR(DAP_GetValueFromNumStateWave(panelTitle, lbl, index = index), val)

				expected = DAP_GetValueFromTxTStateWave(panelTitle, lbl, index = index)
				CHECK_EQUAL_STR(expected, str)
				// undo
				PGC_SetAndActivateControl(panelTitle, ctrl, val = oldVal)
				break
		endswitch
	endfor
End
