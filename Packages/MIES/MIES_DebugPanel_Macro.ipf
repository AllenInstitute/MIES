#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_DPM
#endif

Window DebugPanel() : Panel
	PauseUpdate; Silent 1 // building window...
	NewPanel/K=1/W=(230, 184, 625, 648)
	SetDrawLayer UserBack
	CheckBox check_itc_xop_debug_mode, pos={254.00, 11.00}, size={121.00, 15.00}, proc=DP_CheckProc_Debug, title="ITC XOP Debugging"
	CheckBox check_itc_xop_debug_mode, userdata(ResizeControlsInfo)=A"!!,H9!!#;=!!#@V!!#<(z!!#o2B4uAezzzzzzzzzzzzzz!!#o2B4uAezz"
	CheckBox check_itc_xop_debug_mode, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_itc_xop_debug_mode, userdata(ResizeControlsInfo)+=A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	CheckBox check_itc_xop_debug_mode, value=0
	CheckBox check_debug_mode, pos={20.00, 11.00}, size={74.00, 15.00}, proc=DP_CheckProc_Debug, title="Debugging"
	CheckBox check_debug_mode, userdata(ResizeControlsInfo)=A"!!,BY!!#;=!!#?M!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_debug_mode, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_debug_mode, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_debug_mode, value=1
	ListBox listbox_mies_files, pos={19.00, 33.00}, size={356.00, 411.00}
	ListBox listbox_mies_files, userdata(ResizeControlsInfo)=A"!!,BQ!!#=g!!#Bl!!#C2J,fQL!!#](Aon\"Qzzzzzzzzzzzzzz!!#o2B4uAezz"
	ListBox listbox_mies_files, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	ListBox listbox_mies_files, userdata(ResizeControlsInfo)+=A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	PopupMenu popup_select_files, pos={106.00, 9.00}, size={90.00, 19.00}, proc=DP_PopMenuProc_Selection, title="Selection:"
	PopupMenu popup_select_files, userdata(ResizeControlsInfo)=A"!!,F9!!#:r!!#?m!!#<Pz!!#](Aon#azzzzzzzzzzzzzz!!#](Aon#azz"
	PopupMenu popup_select_files, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu popup_select_files, userdata(ResizeControlsInfo)+=A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	PopupMenu popup_select_files, mode=2, popvalue="All", value=#"\"- none -;All\""
	SetWindow kwTopWin, hook(ResizeControls)=ResizeControlsSafe
	SetWindow kwTopWin, userdata(ResizeControlsInfo)=A"!!*'\"z!!#C*J,ht#zzzzzzzzzzzzzzzzzzzzz"
	SetWindow kwTopWin, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzzzzzzzzzzzzzzz"
	SetWindow kwTopWin, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzzzzzzzzz!!!"
	Execute/Q/Z "SetWindow kwTopWin sizeLimit={296.25,348,inf,inf}" // sizeLimit requires Igor 7 or later
	SetWindow kwTopWin, hook(MainHook)=DP_WindowHook
EndMacro
