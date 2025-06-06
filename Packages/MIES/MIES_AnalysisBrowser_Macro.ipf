#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors = 1

#ifdef AUTOMATED_TESTING
#pragma ModuleName = MIES_ABMACRO
#endif // AUTOMATED_TESTING

/// @file MIES_AnalysisBrowser.ipf
/// @brief __ABM__ Analysis browser Macro

Window AnalysisBrowser() : Panel
	PauseUpdate; Silent 1 // building window...
	NewPanel/K=1/W=(12, 97, 1175, 689) as "AnalysisBrowser"
	DefineGuide splitGuide={FT, 10}, UGVL={FL, 15}
	ListBox list_experiment_contents, pos={120, 217}, size={1039, 372}, proc=AB_ListBoxProc_ExpBrowser
	ListBox list_experiment_contents, help={"Various properties of the loaded sweep data"}
	ListBox list_experiment_contents, userdata(ResizeControlsInfo)=A"!!,FU!!#Ah!!#E<huH-Uz!!#](Aon\"Qzzzzzzzzzzzzzz!!#o2B4uAezz"
	ListBox list_experiment_contents, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	ListBox list_experiment_contents, userdata(ResizeControlsInfo)+=A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	ListBox list_experiment_contents, mode=9
	ListBox list_experiment_contents, widths={15, 240, 50, 15, 100, 52, 50, 75, 141, 59, 42, 42, 150, 15}
	ListBox list_experiment_contents, userColumnResize=1
	Button button_select_same_stim_sets, pos={7, 223}, size={100, 30}, proc=AB_ButtonProc_SelectStimSets
	Button button_select_same_stim_sets, title="Select same\r stim sets sweeps"
	Button button_select_same_stim_sets, help={"Starting from one selected sweep, select all other sweeps which were acquired with the same stimset"}
	Button button_select_same_stim_sets, userdata(ResizeControlsInfo)=A"!!,@C!!#An!!#@,!!#=Sz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_select_same_stim_sets, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button button_select_same_stim_sets, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	Button button_collapse_all, pos={7, 256}, size={100, 25}, proc=AB_ButtonProc_CollapseAll
	Button button_collapse_all, title="Collapse all"
	Button button_collapse_all, help={"Collapse all entries giving the most compact view"}
	Button button_collapse_all, userdata(ResizeControlsInfo)=A"!!,@C!!#B:!!#@,!!#=+z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_collapse_all, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button button_collapse_all, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	Button button_expand_all, pos={7, 284}, size={100, 25}, proc=AB_ButtonProc_ExpandAll
	Button button_expand_all, title="Expand all"
	Button button_expand_all, help={"Expand all entries giving the longest view"}
	Button button_expand_all, userdata(ResizeControlsInfo)=A"!!,@C!!#BH!!#@,!!#=+z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_expand_all, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button button_expand_all, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	Button button_load_sweeps, pos={7, 437}, size={100, 25}, proc=AB_ButtonProc_LoadSweeps
	Button button_load_sweeps, title="Load Sweeps"
	Button button_load_sweeps, help={"Open a sweep browser panel from the selected sweeps. In case an experiment or device is selected, all sweeps are loaded from them."}
	Button button_load_sweeps, userdata(ResizeControlsInfo)=A"!!,@C!!#C?J,hpW!!#=+z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_load_sweeps, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button button_load_sweeps, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	Button button_load_stimsets, pos={7, 465}, size={100, 25}, proc=AB_ButtonProc_LoadStimsets
	Button button_load_stimsets, title="Load Stimsets"
	Button button_load_stimsets, help={"Open the wave builder panel with the selected stimset. All selected stimsets are loaded recursively."}
	Button button_load_stimsets, userdata(ResizeControlsInfo)=A"!!,@C!!#CMJ,hpW!!#=+z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_load_stimsets, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button button_load_stimsets, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	Button button_show_usercomments, pos={7, 312}, size={100, 25}, proc=AB_ButtonProc_OpenCommentNB
	Button button_show_usercomments, title="Open comment"
	Button button_show_usercomments, help={"Open a read-only notebook showing the user comment for the currently selected experiment."}
	Button button_show_usercomments, userdata(ResizeControlsInfo)=A"!!,@C!!#BV!!#@,!!#=+z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_show_usercomments, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button button_show_usercomments, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox checkbox_load_overwrite, pos={7, 381}, size={67, 16}, title="Overwrite"
	CheckBox checkbox_load_overwrite, help={"Overwrite existing stimsets on load or resaved NWBv2 files"}
	CheckBox checkbox_load_overwrite, userdata(ResizeControlsInfo)=A"!!,@C!!#C#J,hoj!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox checkbox_load_overwrite, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox checkbox_load_overwrite, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox checkbox_load_overwrite, value=0
	Button button_show_resaveAsNWB, pos={7, 352}, size={100, 25}, proc=AB_ButtonProc_ResaveAsNWB
	Button button_show_resaveAsNWB, title="Resave as NWBv2"
	Button button_show_resaveAsNWB, help={"Save the loaded experiments as NWBv2 files"}
	Button button_show_resaveAsNWB, userdata(ResizeControlsInfo)=A"!!,@C!!#Bj!!#@,!!#=+z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_show_resaveAsNWB, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button button_show_resaveAsNWB, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	ListBox listbox_AB_Folders, pos={120, 3}, size={1039, 199}, proc=AB_ListBoxProc_FileFolderList
	ListBox listbox_AB_Folders, help={"Source folders for sweep/stimset files"}
	ListBox listbox_AB_Folders, userdata(ResizeControlsInfo)=A"!!,FU!!#8L!!#E<huH,7z!!#](Aon\"Qzzzzzzzzzzzzzz!!#o2B4uAezz"
	ListBox listbox_AB_Folders, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	ListBox listbox_AB_Folders, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	ListBox listbox_AB_Folders, labelBack=(65535, 65535, 65535), mode=9
	Button button_AB_AddFolder, pos={7, 5}, size={100, 25}, proc=AB_ButtonProc_AddFolder
	Button button_AB_AddFolder, title="Add folder"
	Button button_AB_AddFolder, help={"Add a new folder to the list"}
	Button button_AB_AddFolder, userdata(ResizeControlsInfo)=A"!!,@C!!#9W!!#@,!!#=+z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_AB_AddFolder, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button button_AB_AddFolder, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	Button button_AB_Remove, pos={7, 61}, size={100, 25}, proc=AB_ButtonProc_Remove
	Button button_AB_Remove, title="Remove"
	Button button_AB_Remove, help={"Remove folders or files from the list"}
	Button button_AB_Remove, userdata(ResizeControlsInfo)=A"!!,@C!!#?-!!#@,!!#=+z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_AB_Remove, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button button_AB_Remove, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	Button button_AB_refresh, pos={7, 89}, size={100, 25}, proc=AB_ButtonProc_Refresh
	Button button_AB_refresh, title="Refresh", help={"Refresh stimset list"}
	Button button_AB_refresh, userdata(ResizeControlsInfo)=A"!!,@C!!#?k!!#@,!!#=+z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_AB_refresh, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button button_AB_refresh, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	Button button_AB_open, pos={7, 117}, size={100, 25}, proc=AB_ButtonProc_OpenFolders
	Button button_AB_open, title="Open", help={"Opens selected folders in Explorer"}
	Button button_AB_open, userdata(ResizeControlsInfo)=A"!!,@C!!#@N!!#@,!!#=+z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_AB_open, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button button_AB_open, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	Button button_AB_AddFiles, pos={7, 33}, size={100, 25}, proc=AB_ButtonProc_AddFiles
	Button button_AB_AddFiles, title="Add file(s)"
	Button button_AB_AddFiles, help={"Add a new files to the list"}
	Button button_AB_AddFiles, userdata(ResizeControlsInfo)=A"!!,@C!!#=g!!#@,!!#=+z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_AB_AddFiles, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button button_AB_AddFiles, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	Button button_load_sweepsAndStimsets, pos={7, 493}, size={100, 25}, proc=AB_ButtonProc_LoadBoth
	Button button_load_sweepsAndStimsets, title="Load Both"
	Button button_load_sweepsAndStimsets, help={"Open a sweep browser panel from the selected sweeps. In case an experiment or device is selected, all sweeps and stimsets are loaded from them."}
	Button button_load_sweepsAndStimsets, userdata(ResizeControlsInfo)=A"!!,@C!!#C[J,hpW!!#=+z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_load_sweepsAndStimsets, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button button_load_sweepsAndStimsets, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_load_nwb, pos={12, 147}, size={43, 16}, proc=AB_CheckboxProc_NWB
	CheckBox check_load_nwb, title="NWB"
	CheckBox check_load_nwb, help={"Load NWB v1 and v2 files when iterating over folders"}
	CheckBox check_load_nwb, userdata(ResizeControlsInfo)=A"!!,AN!!#A\"!!#>:!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_load_nwb, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_load_nwb, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_load_nwb, value=1
	CheckBox check_load_pxp, pos={61, 147}, size={37, 16}, proc=AB_CheckboxProc_PXP
	CheckBox check_load_pxp, title="PXP"
	CheckBox check_load_pxp, help={"Load PXP files (Igor Experiments) when iterating over folders"}
	CheckBox check_load_pxp, userdata(ResizeControlsInfo)=A"!!,E.!!#A\"!!#>\"!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_load_pxp, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_load_pxp, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_load_pxp, value=0
	Button button_load_tpstorage, pos={7, 529}, size={100, 25}, proc=AB_ButtonProc_LoadTPStorage
	Button button_load_tpstorage, title="Load TPStorage"
	Button button_load_tpstorage, help={"Load the TPStorage waves from the selected experiments"}
	Button button_load_tpstorage, userdata(ResizeControlsInfo)=A"!!,@C!!#Ci5QF-l!!#=+z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_load_tpstorage, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button button_load_tpstorage, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	GroupBox group0, pos={4, 2}, size={113, 202}
	GroupBox group0, userdata(ResizeControlsInfo)=A"!!,?8!!#7a!!#@F!!#AYz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	GroupBox group0, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	GroupBox group0, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	GroupBox group1, pos={4, 346}, size={111, 57}
	GroupBox group1, userdata(ResizeControlsInfo)=A"!!,?8!!#Bg!!#@B!!#>rz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	GroupBox group1, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	GroupBox group1, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	GroupBox group2, pos={4, 408}, size={111, 179}
	GroupBox group2, userdata(ResizeControlsInfo)=A"!!,?8!!#C1!!#@B!!#ABz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	GroupBox group2, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	GroupBox group2, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_load_results, pos={7, 168}, size={79, 16}, title="Load results"
	CheckBox check_load_results, help={"Load PXP files (Igor Experiments) when iterating over folders"}
	CheckBox check_load_results, userdata(ResizeControlsInfo)=A"!!,@C!!#A7!!#?W!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_load_results, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_load_results, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_load_results, value=0
	PopupMenu popup_SweepBrowserSelect, pos={8, 414}, size={99, 20}, bodyWidth=99
	PopupMenu popup_SweepBrowserSelect, userdata(ResizeControlsInfo)=A"!!,@c!!#C4!!#@*!!#<Xz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu popup_SweepBrowserSelect, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu popup_SweepBrowserSelect, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu popup_SweepBrowserSelect, mode=1, popvalue="New", value=#"AB_GetSweepBrowserListForPopup()"
	Button button_load_history, pos={7, 557}, size={100, 25}, proc=AB_ButtonProc_LoadHistoryAndLogs
	Button button_load_history, title="Load History"
	Button button_load_history, help={"Load the experiment history and logs"}
	Button button_load_history, userdata(ResizeControlsInfo)=A"!!,@C!!#Cp5QF-l!!#=+z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_load_history, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button button_load_history, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_load_comment, pos={7, 186}, size={102, 16}, title="Load comments"
	CheckBox check_load_comment, help={"Load user comments from files"}
	CheckBox check_load_comment, userdata(ResizeControlsInfo)=A"!!,@C!!#AI!!#@0!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_load_comment, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_load_comment, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_load_comment, value=0
	SetWindow kwTopWin, hook(windowCoordinateSaving)=StoreWindowCoordinatesHook
	SetWindow kwTopWin, hook(ResizeControls)=ResizeControlsSafe
	SetWindow kwTopWin, hook(cleanup)=AB_WindowHook
	SetWindow kwTopWin, userdata(Config_PanelType)="AnalysisBrowser"
	SetWindow kwTopWin, userdata(JSONSettings_StoreCoordinates)="1"
	SetWindow kwTopWin, userdata(JSONSettings_WindowName)="analysisbrowser"
	SetWindow kwTopWin, userdata(ResizeControlsGuides)="splitGuide;UGVL;"
	SetWindow kwTopWin, userdata(ResizeControlsInfosplitGuide)="NAME:splitGuide;WIN:AnalysisBrowser;TYPE:User;HORIZONTAL:1;POSITION:10.00;GUIDE1:FT;GUIDE2:;RELPOSITION:10;"
	SetWindow kwTopWin, userdata(ResizeControlsInfoUGVL)="NAME:UGVL;WIN:AnalysisBrowser;TYPE:User;HORIZONTAL:0;POSITION:15.00;GUIDE1:FL;GUIDE2:;RELPOSITION:15;"
	SetWindow kwTopWin, userdata(ResizeControlsInfo)=A"!!*'\"z!!#EL?iWS/zzzzzzzzzzzzzzzzzzzzz"
	SetWindow kwTopWin, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzzzzzzzzzzzzzzz"
	SetWindow kwTopWin, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzzzzzzzzz!!!"
	Execute/Q/Z "SetWindow kwTopWin sizeLimit={854.25,444,inf,inf}" // sizeLimit requires Igor 7 or later
EndMacro
