#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_ID
#endif

/// @file MIES_InputDialog.ipf
/// @brief __ID__ Input dialog handling for numeric entries

/// @brief Shows a dialog and queries numeric values from the user
///
/// We currently ask for #NUM_HEADSTAGES headstage dependent entries and one independent value.
/// All values must be numeric.
///
/// @param title dialog title
/// @param data  1D numeric wave, which must be permanent and
///              in an otherwise empty folder of size #LABNOTEBOOK_LAYER_COUNT
/// @param mock  This is mock data for testing which is written into data when
///              GetInteractiveMode() is false
///
/// @return 0 on success, 1 if the user cancelled the dialog
Function ID_AskUserForHeadstageSettings(string title, WAVE data, WAVE mock)
	string win, ctrl
	variable i, state_var

	ASSERT(!IsFreeWave(data), "Can only work with permanent waves")
	ASSERT(EqualWaves(data, mock, 2 + 512), "Mismatched types or dimension sizes")

	Execute "ID_Panel()"
	win = GetCurrentWindow()
	DFREF dfr = GetWavesDataFolderDFR(data)
	SetWindow $win, userdata(folder) = GetDataFolder(1, dfr)

	SetDrawLayer/W=$win UserBack
	SetDrawEnv/W=$win textxjust= 1,textyjust= 1
	DrawText/W=$win 45,15,title

	for(i = 0; i < LABNOTEBOOK_LAYER_COUNT; i += 1)
		ctrl = ID_GetControl(i)

		if(IsNaN(data[i]))
			DisableControl(win, ctrl)
		else
			SetSetVariable(win, ctrl, data[i])
		endif
	endfor

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

static Function/S ID_GetControl(variable index)
	string ctrl

	if(index < NUM_HEADSTAGES)
		sprintf ctrl, "setvar_HS%d", index
	else
		ctrl = "setvar_INDEP"
	endif

	return ctrl
End

Function ID_ButtonProc(STRUCT WMButtonAction &ba) : ButtonControl

	switch(ba.eventCode)
		case 2: // mouse up
			DFREF dfr = $GetUserData(ba.win, "", "folder")
			ASSERT(DataFolderExistsDFR(dfr), "Missing folder user data")

			strswitch(ba.ctrlName)
				case "button_continue":
					variable/G dfr:state = 0
					break
				case "button_cancel":
					variable/G dfr:state = 1
					break
				default:
					ASSERT(0, "Unknown control")
					break
			endswitch
			KillWindow/Z $(ba.win)
			break
	endswitch
End

Function ID_SetVarProc(STRUCT WMSetVariableAction &sva) : SetVariableControl
	variable idx

	switch(sva.eventCode)
		case 1:
		case 2:
		case 3:
			DFREF dfr = $GetUserData(sva.win, "", "folder")
			ASSERT(DataFolderExistsDFR(dfr), "Missing folder user data")

			WAVE/WAVE waves = ListToWaveRefWave(GetListOfObjects(dfr, ".*", fullPath = 1), 1)
			ASSERT(DimSize(waves, ROWS) == 1, "Expected only one wave")

			WAVE data = waves[0]
			idx = str2num(GetUserData(sva.win, sva.ctrlName, "index"))
			ASSERT(IsFinite(idx), "Invalid index")

			data[idx] = sva.dval
			break
	endswitch
End

Window ID_Panel() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel/K=1/W=(490,960,726,1225) as "InputPanelForHeadstages"
	Button button_continue,pos={22.00,227.00},size={92.00,20.00},proc=ID_ButtonProc
	Button button_continue,title="Continue"
	Button button_continue,userdata(ResizeControlsInfo)= A"!!,Bi!!#Ar!!#?q!!#<Xz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_continue,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button button_continue,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	Button button_cancel,pos={125.00,227.00},size={92.00,20.00},proc=ID_ButtonProc
	Button button_cancel,title="Cancel"
	Button button_cancel,userdata(ResizeControlsInfo)= A"!!,F_!!#Ar!!#?q!!#<Xz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_cancel,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button button_cancel,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_HS0,pos={78.00,28.00},size={85.00,18.00},bodyWidth=60,proc=ID_SetVarProc
	SetVariable setvar_HS0,title="HS0",userdata(index)=  "0"
	SetVariable setvar_HS0,userdata(ResizeControlsInfo)= A"!!,EV!!#=C!!#?c!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_HS0,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_HS0,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_HS0,value= _NUM:0
	SetVariable setvar_HS1,pos={78.00,50.00},size={85.00,18.00},bodyWidth=60,proc=ID_SetVarProc
	SetVariable setvar_HS1,title="HS1",userdata(index)=  "1"
	SetVariable setvar_HS1,userdata(ResizeControlsInfo)= A"!!,EV!!#>V!!#?c!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_HS1,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_HS1,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_HS1,value= _NUM:0
	SetVariable setvar_HS2,pos={78.00,71.00},size={85.00,18.00},bodyWidth=60,proc=ID_SetVarProc
	SetVariable setvar_HS2,title="HS2",userdata(index)=  "2"
	SetVariable setvar_HS2,userdata(ResizeControlsInfo)= A"!!,EV!!#?G!!#?c!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_HS2,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_HS2,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_HS2,value= _NUM:0
	SetVariable setvar_HS3,pos={78.00,92.00},size={85.00,18.00},bodyWidth=60,proc=ID_SetVarProc
	SetVariable setvar_HS3,title="HS3",userdata(index)=  "3"
	SetVariable setvar_HS3,userdata(ResizeControlsInfo)= A"!!,EV!!#?q!!#?c!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_HS3,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_HS3,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_HS3,value= _NUM:0
	SetVariable setvar_HS4,pos={78.00,114.00},size={85.00,18.00},bodyWidth=60,proc=ID_SetVarProc
	SetVariable setvar_HS4,title="HS4",userdata(index)=  "4"
	SetVariable setvar_HS4,userdata(ResizeControlsInfo)= A"!!,EV!!#@H!!#?c!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_HS4,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_HS4,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_HS4,value= _NUM:0
	SetVariable setvar_HS5,pos={78.00,135.00},size={85.00,18.00},bodyWidth=60,proc=ID_SetVarProc
	SetVariable setvar_HS5,title="HS5",userdata(index)=  "5"
	SetVariable setvar_HS5,userdata(ResizeControlsInfo)= A"!!,EV!!#@k!!#?c!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_HS5,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_HS5,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_HS5,value= _NUM:0
	SetVariable setvar_HS6,pos={78.00,157.00},size={85.00,18.00},bodyWidth=60,proc=ID_SetVarProc
	SetVariable setvar_HS6,title="HS6",userdata(index)=  "6"
	SetVariable setvar_HS6,userdata(ResizeControlsInfo)= A"!!,EV!!#A,!!#?c!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_HS6,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_HS6,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_HS6,value= _NUM:0
	SetVariable setvar_HS7,pos={78.00,178.00},size={85.00,18.00},bodyWidth=60,proc=ID_SetVarProc
	SetVariable setvar_HS7,title="HS7",userdata(index)=  "7"
	SetVariable setvar_HS7,userdata(ResizeControlsInfo)= A"!!,EV!!#AA!!#?c!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_HS7,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_HS7,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_HS7,value= _NUM:0
	SetVariable setvar_INDEP,pos={66.00,199.00},size={97.00,18.00},bodyWidth=60,proc=ID_SetVarProc
	SetVariable setvar_INDEP,title="INDEP",userdata(index)=  "8"
	SetVariable setvar_INDEP,userdata(ResizeControlsInfo)= A"!!,E>!!#AV!!#@&!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_INDEP,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_INDEP,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_INDEP,value= _NUM:0
	SetWindow kwTopWin,hook(ResizeControls)=ResizeControls#ResizeControlsHook
	SetWindow kwTopWin,userdata(ResizeControlsInfo)= A"!!*'\"z!!#B&!!#B>J,fQLzzzzzzzzzzzzzzzzzzzz"
	SetWindow kwTopWin,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzzzzzzzzzzzzzzz"
	SetWindow kwTopWin,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzzzzzzzzz!!!"
	Execute/Q/Z "SetWindow kwTopWin sizeLimit={177,198.75,inf,inf}" // sizeLimit requires Igor 7 or later
EndMacro
