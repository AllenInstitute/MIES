#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3
#pragma rtFunctionErrors = 1

#ifdef AUTOMATED_TESTING
#pragma ModuleName = MIES_ID
#endif // AUTOMATED_TESTING

/// @file MIES_InputDialog.ipf
/// @brief __ID__ Input dialog handling for numeric entries

/// @brief Shows a dialog and queries numeric values from the user
///
/// We currently ask for #NUM_HEADSTAGES headstage dependent entries and one independent value when mode = ID_HEADSTAGE_SETTINGS.
/// All values must be numeric. For ID_POPUPMENU_SETTINGS the row dimension labels of data fill the popup menu, and on return
/// data will have a 1 at the selected entry.
///
/// @param mode  One of @ref AskUserSettingsModeFlag
/// @param title dialog title
/// @param data  1D numeric wave, which must be permanent and
///              in an otherwise empty folder
/// @param mock  This is mock data for testing which is written into data when
///              GetInteractiveMode() is false
///
/// @return 0 on success, 1 if the user cancelled the dialog
Function ID_AskUserForSettings(variable mode, string title, WAVE data, WAVE mock)

	string win, ctrl
	variable i, state_var

	ASSERT(!IsFreeWave(data), "Can only work with permanent waves")
	ASSERT(EqualWaves(data, mock, EQWAVES_DATATYPE + EQWAVES_DIMSIZE), "Mismatched types or dimension sizes")
	ASSERT(mode == ID_HEADSTAGE_SETTINGS || mode == ID_POPUPMENU_SETTINGS, "Invalid mode")
	ASSERT(DimSize(data, ROWS) > 0, "Empty wave")

	if(mode == ID_HEADSTAGE_SETTINGS)
		Execute "IDM_Headstage_Panel()"
	elseif(mode == ID_POPUPMENU_SETTINGS)
		Execute "IDM_Popup_Panel()"
	endif

	win = GetCurrentWindow()
	DFREF dfr = GetWavesDataFolderDFR(data)
	SetWindow $win, userdata(folder)=GetDataFolder(1, dfr)

	ID_SetTitle(win, title)

	if(mode == ID_HEADSTAGE_SETTINGS)
		for(i = 0; i < LABNOTEBOOK_LAYER_COUNT; i += 1)
			ctrl = ID_GetControl(i)

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
	endif

	if(ROVar(GetInteractiveMode()))
		PauseForUser $win
	else
		data = mock
		PGC_SetAndActivateControl(win, "button_continue")
	endif

	NVAR/Z/SDFR=dfr state
	ASSERT(NVAR_Exists(state), "Missing state variable")
	state_var = state
	KillVariables state

	return state_var
End

static Function ID_SetTitle(string win, string title)

	SetDrawLayer/W=$win UserBack
	SetDrawEnv/W=$win xcoord=rel, ycoord=abs
	SetDrawEnv/W=$win textxjust=1, textyjust=1
	DrawText/W=$win 0.5, 15, title
End

static Function/S ID_GetControl(variable index)

	string ctrl

	if(index < NUM_HEADSTAGES)
		sprintf ctrl, "setvar_HS%d", index
	else
		ctrl = "setvar_INDEP"
	endif

	return ctrl
End

static Function/DF ID_GetFolder(string win)

	DFREF dfr = $GetUserData(win, "", "folder")
	ASSERT(DataFolderExistsDFR(dfr), "Missing folder user data")

	return dfr
End

static Function/WAVE ID_GetWave(string win)

	DFREF dfr = ID_GetFolder(win)

	WAVE/WAVE waves = ListToWaveRefWave(GetListOfObjects(dfr, ".*", fullPath = 1), 1)
	ASSERT(DimSize(waves, ROWS) == 1, "Expected only one wave")

	return waves[0]
End

Function ID_ButtonProc(STRUCT WMButtonAction &ba) : ButtonControl

	switch(ba.eventCode)
		case 2: // mouse up
			DFREF dfr = ID_GetFolder(ba.win)

			strswitch(ba.ctrlName)
				case "button_continue":
					variable/G dfr:state = 0
					break
				case "button_cancel":
					variable/G dfr:state = 1
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

			WAVE data = ID_GetWave(sva.win)
			data[idx] = sva.dval
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
