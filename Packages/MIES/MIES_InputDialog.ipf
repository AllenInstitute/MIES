#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3
#pragma rtFunctionErrors = 1

#ifdef AUTOMATED_TESTING
#pragma ModuleName = MIES_ID
#endif // AUTOMATED_TESTING

/// @file MIES_InputDialog.ipf
/// @brief __ID__ Input dialog handling for numeric/text entries

/// @brief Shows a dialog and queries values from the user
///
/// ## Different modes
///
/// - ID_HEADSTAGE_SETTINGS
///   Ask for #NUM_HEADSTAGES headstage dependent entries and one independent value. All numeric.
/// - ID_POPUPMENU_SETTINGS
///   The row dimension labels of data fill the popup menu, and on return data will have a 1 at the selected entry. All numeric.
/// - ID_KVPAIRS_SETTINGS
///   Pairs of keys and values, values being the wave element and the key the dimension label. Supports 1 to #ID_KVPAIRS_MAX_VALUES text entries.
///
/// @param mode  One of @ref AskUserSettingsModeFlag
/// @param title dialog title
/// @param data  1D wave, which must be permanent
/// @param mock  This is mock data for testing which is written into data when
///              GetInteractiveMode() is false
///
/// @return 0 on success, 1 if the user cancelled the dialog
Function ID_AskUserForSettings(variable mode, string title, WAVE data, WAVE mock)

	string win, ctrl, ctrlTitle
	variable i, numEntries

	PerformSubsystemEntry()

	numEntries = DimSize(data, ROWS)

	ASSERT(IsGlobalWave(data), "Can only work with permanent waves")
	ASSERT(EqualWaves(data, mock, EQWAVES_DATATYPE + EQWAVES_DIMSIZE), "Mismatched types or dimension sizes")
	ASSERT(numEntries > 0, "Empty wave")
	ASSERT(GetWaveDimensionality(data) == ROWS, "Expected a 1D wave")

	if(mode == ID_HEADSTAGE_SETTINGS)
		ASSERT(IsFloatingPointWave(data), "Expected a floating point wave for data")
		Execute "IDM_Headstage_Panel()"
	elseif(mode == ID_POPUPMENU_SETTINGS)
		Execute "IDM_Popup_Panel()"
	elseif(mode == ID_KVPAIRS_SETTINGS)
		ASSERT(IsTextWave(data), "Expected a text wave for data")
		ASSERT(numEntries <= ID_KVPAIRS_MAX_VALUES, "Can only show up to 10 entries with mode ID_KVPAIRS_SETTINGS")
		Execute "IDM_KVPairs_Panel()"
	else
		FATAL_ERROR("Unknown mode: " + num2str(mode))
	endif

	win = GetCurrentWindow()
	DFREF dfr = GetUniqueTempPath()
	SetWindow $win, userdata(folder)=GetDataFolder(1, dfr)
	SetWindow $win, userdata(wave)=GetWavesDataFolder(data, 2)

	ID_SetTitle(win, title)

	if(mode == ID_HEADSTAGE_SETTINGS)
		for(i = 0; i < LABNOTEBOOK_LAYER_COUNT; i += 1)
			ctrl = ID_GetControl(mode, i)

			if(IsNaN(data[i]))
				DisableControl(win, ctrl)
			else
				SetSetVariable(win, ctrl, data[i])
			endif
		endfor
	elseif(mode == ID_POPUPMENU_SETTINGS)
		PopupMenu popup0, mode=1, win=$win, popvalue="", value=#"ID_GetPopupEntries()"
		// select the first entry
		PGC_SetAndActivateControl(win, "popup0", val = 0)
	elseif(mode == ID_KVPAIRS_SETTINGS)
		WAVE/T dataTXT = data

		for(i = 0; i < ID_KVPAIRS_MAX_VALUES; i += 1)
			ctrl = ID_GetControl(mode, i)

			if(i >= numEntries)
				DisableControl(win, ctrl)
				continue
			endif

			SetSetVariableString(win, ctrl, dataTXT[i])

			ctrlTitle = GetDimlabel(dataTXT, ROWS, i)
			ASSERT(!IsEmpty(ctrlTitle), "Title for entry can not be empty")
			SetControlTitle(win, ctrl, ctrlTitle)
		endfor
	endif

	if(ROVar(GetInteractiveMode()))
		PauseForUser $win
	else
		if(IsTextWave(mock))
			WAVE/T dataTXT = data
			WAVE/T mockTXT = mock

			dataTXT = mockTXT
		else
			data = mock
		endif

		PGC_SetAndActivateControl(win, "button_continue")
	endif

	NVAR state = $GetInputDialogState(dfr)
	ASSERT(IsFinite(state), "Missing state variable")

	return state
End

static Function ID_SetTitle(string win, string title)

	SetDrawLayer/W=$win UserBack
	SetDrawEnv/W=$win xcoord=rel, ycoord=abs
	SetDrawEnv/W=$win textxjust=1, textyjust=1
	DrawText/W=$win 0.5, 15, title
End

static Function/S ID_GetControl(variable mode, variable index)

	string ctrl

	if(mode == ID_HEADSTAGE_SETTINGS)
		if(index < NUM_HEADSTAGES)
			sprintf ctrl, "setvar_HS%d", index
		else
			ctrl = "setvar_INDEP"
		endif
	elseif(mode == ID_KVPAIRS_SETTINGS)
		sprintf ctrl, "setvar_%d", index
	else
		FATAL_ERROR("Unsupported mode")
	endif

	return ctrl
End

static Function/DF ID_GetFolder(string win)

	DFREF dfr = $GetUserData(win, "", "folder")
	ASSERT(DataFolderExistsDFR(dfr), "Missing folder user data")

	return dfr
End

static Function/WAVE ID_GetWave(string win)

	WAVE/Z wv = $GetUserData(win, "", "wave")
	ASSERT(WaveExists(wv), "wv does not exist")

	return wv
End

Function ID_ButtonProc(STRUCT WMButtonAction &ba) : ButtonControl

	switch(ba.eventCode)
		case 2: // mouse up
			DFREF dfr   = ID_GetFolder(ba.win)
			NVAR  state = $GetInputDialogState(dfr)

			strswitch(ba.ctrlName)
				case "button_continue":
					state = 0
					break
				case "button_cancel":
					state = 1
					break
				default:
					FATAL_ERROR("Unknown control")
					break
			endswitch
			KillWindow/Z $(ba.win)
			break
		default:
			break
	endswitch
End

Function ID_SetVarProc(STRUCT WMSetVariableAction &sva) : SetVariableControl

	variable idx

	switch(sva.eventCode)
		case 1: // fallthrough
		case 2: // fallthrough
		case 3:
			idx = str2num(GetUserData(sva.win, sva.ctrlName, "index"))
			ASSERT(IsFinite(idx), "Invalid index")

			if(sva.isStr)
				WAVE/T dataTXT = ID_GetWave(sva.win)
				dataTXT[idx] = sva.sval
			else
				WAVE data = ID_GetWave(sva.win)
				data[idx] = sva.dval
			endif
			break
		default:
			break
	endswitch
End

Function ID_PopMenuProc(STRUCT WMPopupAction &pa) : PopupMenuControl

	switch(pa.eventCode)
		case 2: // mouse up
			WAVE data = ID_GetWave(pa.win)
			data[]            = 0
			data[%$pa.popStr] = 1

			break
		default:
			break
	endswitch

	return 0
End

Function/S ID_GetPopupEntries()

	string win

	win = GetCurrentWindow()
	WAVE data = ID_GetWave(win)

	Make/T/FREE/N=(DimSize(data, ROWS)) items = GetDimLabel(data, ROWS, p)

	return TextWaveToList(items, ";")
End
