#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_ABMACRO
#endif // AUTOMATED_TESTING

/// @file MIES_AnalysisBrowser.ipf
/// @brief __ABM__ Analysis browser Macro

Window AnalysisBrowser() : Panel
	PauseUpdate; Silent 1 // building window...
	NewPanel/K=1/W=(608, 61, 1747, 627) as "AnalysisBrowser"
	SetDrawLayer UserBack
	ListBox list_experiment_contents, pos={120.00, 200.00}, size={1015.00, 363.00}, proc=AB_ListBoxProc_ExpBrowser
	ListBox list_experiment_contents, help={"Various properties of the loaded sweep data"}
	ListBox list_experiment_contents, userdata(ResizeControlsInfo)=A"!!,FU!!#AW!!#E8^]6a0J,fQL!!#](Aon\"Qzzzzzzzzzzzzzz!!#o2B4uAezz"
	ListBox list_experiment_contents, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	ListBox list_experiment_contents, userdata(ResizeControlsInfo)+=A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	ListBox list_experiment_contents, mode=9
	ListBox list_experiment_contents, widths={29, 285, 42, 27, 114, 62, 51, 78, 160, 63, 42, 42}
	ListBox list_experiment_contents, userColumnResize=1
	Button button_select_same_stim_sets, pos={7.00, 201.00}, size={100.00, 30.00}, proc=AB_ButtonProc_SelectStimSets
	Button button_select_same_stim_sets, title="Select same\r stim sets sweeps"
	Button button_select_same_stim_sets, help={"Starting from one selected sweep, select all other sweeps which were acquired with the same stimset"}
	Button button_select_same_stim_sets, userdata(ResizeControlsInfo)=A"!!,@C!!#AX!!#@,!!#=Sz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_select_same_stim_sets, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button button_select_same_stim_sets, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	Button button_collapse_all, pos={7.00, 234.00}, size={100.00, 25.00}, proc=AB_ButtonProc_CollapseAll
	Button button_collapse_all, title="Collapse all"
	Button button_collapse_all, help={"Collapse all entries giving the most compact view"}
	Button button_collapse_all, userdata(ResizeControlsInfo)=A"!!,@C!!#B$!!#@,!!#=+z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_collapse_all, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button button_collapse_all, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	Button button_expand_all, pos={7.00, 262.00}, size={100.00, 25.00}, proc=AB_ButtonProc_ExpandAll
	Button button_expand_all, title="Expand all"
	Button button_expand_all, help={"Expand all entries giving the longest view"}
	Button button_expand_all, userdata(ResizeControlsInfo)=A"!!,@C!!#B=!!#@,!!#=+z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_expand_all, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button button_expand_all, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	Button button_load_sweeps, pos={7.00, 415.00}, size={100.00, 25.00}, proc=AB_ButtonProc_LoadSweeps
	Button button_load_sweeps, title="Load Sweeps"
	Button button_load_sweeps, help={"Open a sweep browser panel from the selected sweeps. In case an experiment or device is selected, all sweeps are loaded from them."}
	Button button_load_sweeps, userdata(ResizeControlsInfo)=A"!!,@C!!#C4J,hpW!!#=+z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_load_sweeps, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button button_load_sweeps, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	Button button_load_stimsets, pos={7.00, 443.00}, size={100.00, 25.00}, proc=AB_ButtonProc_LoadStimsets
	Button button_load_stimsets, title="Load Stimsets"
	Button button_load_stimsets, help={"Open the wave builder panel with the selected stimset. All selected stimsets are loaded recursively."}
	Button button_load_stimsets, userdata(ResizeControlsInfo)=A"!!,@C!!#CBJ,hpW!!#=+z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_load_stimsets, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button button_load_stimsets, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	Button button_show_usercomments, pos={7.00, 290.00}, size={100.00, 25.00}, proc=AB_ButtonProc_OpenCommentNB
	Button button_show_usercomments, title="Open comment"
	Button button_show_usercomments, help={"Open a read-only notebook showing the user comment for the currently selected experiment."}
	Button button_show_usercomments, userdata(ResizeControlsInfo)=A"!!,@C!!#BK!!#@,!!#=+z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_show_usercomments, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button button_show_usercomments, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox checkbox_load_overwrite, pos={19.00, 359.00}, size={67.00, 15.00}
	CheckBox checkbox_load_overwrite, title="Overwrite"
	CheckBox checkbox_load_overwrite, help={"Overwrite existing stimsets on load or resaved NWBv2 files"}
	CheckBox checkbox_load_overwrite, userdata(ResizeControlsInfo)=A"!!,BQ!!#BmJ,hoj!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox checkbox_load_overwrite, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox checkbox_load_overwrite, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox checkbox_load_overwrite, value=0
	Button button_show_resaveAsNWB, pos={8.00, 330.00}, size={100.00, 25.00}, proc=AB_ButtonProc_ResaveAsNWB
	Button button_show_resaveAsNWB, title="Resave as NWBv2"
	Button button_show_resaveAsNWB, help={"Save the loaded experiments as NWBv2 files"}
	Button button_show_resaveAsNWB, userdata(ResizeControlsInfo)=A"!!,@c!!#B_!!#@,!!#=+z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_show_resaveAsNWB, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button button_show_resaveAsNWB, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	ListBox listbox_AB_Folders, pos={120.00, 3.00}, size={1015.00, 182.00}
	ListBox listbox_AB_Folders, help={"Source folders for sweep/stimset files"}
	ListBox listbox_AB_Folders, userdata(ResizeControlsInfo)=A"!!,FU!!#8L!!#E8^]6_[z!!#](Aon\"Qzzzzzzzzzzzzzz!!#o2B4uAezz"
	ListBox listbox_AB_Folders, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	ListBox listbox_AB_Folders, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	ListBox listbox_AB_Folders, labelBack=(65535, 65535, 65535), mode=9
	Button button_AB_AddFolder, pos={7.00, 5.00}, size={100.00, 25.00}, proc=AB_ButtonProc_AddFolder
	Button button_AB_AddFolder, title="Add folder"
	Button button_AB_AddFolder, help={"Add a new folder to the list"}
	Button button_AB_AddFolder, userdata(ResizeControlsInfo)=A"!!,@C!!#9W!!#@,!!#=+z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_AB_AddFolder, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button button_AB_AddFolder, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	Button button_AB_Remove, pos={7.00, 61.00}, size={100.00, 25.00}, proc=AB_ButtonProc_Remove
	Button button_AB_Remove, title="Remove"
	Button button_AB_Remove, help={"Remove folders or files from the list"}
	Button button_AB_Remove, userdata(ResizeControlsInfo)=A"!!,@C!!#?-!!#@,!!#=+z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_AB_Remove, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button button_AB_Remove, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	Button button_AB_refresh, pos={7.00, 89.00}, size={100.00, 25.00}, proc=AB_ButtonProc_Refresh
	Button button_AB_refresh, title="Refresh", help={"Refresh stimset list"}
	Button button_AB_refresh, userdata(ResizeControlsInfo)=A"!!,@C!!#?k!!#@,!!#=+z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_AB_refresh, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button button_AB_refresh, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	Button button_AB_open, pos={7.00, 117.00}, size={100.00, 25.00}, proc=AB_ButtonProc_OpenFolders
	Button button_AB_open, title="Open", help={"Opens selected folders in Explorer"}
	Button button_AB_open, userdata(ResizeControlsInfo)=A"!!,@C!!#@N!!#@,!!#=+z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_AB_open, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button button_AB_open, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	Button button_AB_AddFiles, pos={7.00, 33.00}, size={100.00, 25.00}, proc=AB_ButtonProc_AddFiles
	Button button_AB_AddFiles, title="Add file(s)"
	Button button_AB_AddFiles, help={"Add a new files to the list"}
	Button button_AB_AddFiles, userdata(ResizeControlsInfo)=A"!!,@C!!#=g!!#@,!!#=+z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_AB_AddFiles, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button button_AB_AddFiles, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	Button button_load_sweepsAndStimsets, pos={7.00, 471.00}, size={100.00, 25.00}, proc=AB_ButtonProc_LoadBoth
	Button button_load_sweepsAndStimsets, title="Load Both"
	Button button_load_sweepsAndStimsets, help={"Open a sweep browser panel from the selected sweeps. In case an experiment or device is selected, all sweeps and stimsets are loaded from them."}
	Button button_load_sweepsAndStimsets, userdata(ResizeControlsInfo)=A"!!,@C!!#CPJ,hpW!!#=+z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_load_sweepsAndStimsets, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button button_load_sweepsAndStimsets, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_load_nwb, pos={12.00, 147.00}, size={43.00, 15.00}, proc=AB_CheckboxProc_NWB
	CheckBox check_load_nwb, title="NWB"
	CheckBox check_load_nwb, help={"Load NWB v1 and v2 files when iterating over folders"}
	CheckBox check_load_nwb, userdata(ResizeControlsInfo)=A"!!,AN!!#A\"!!#>:!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_load_nwb, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_load_nwb, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_load_nwb, value=1
	CheckBox check_load_pxp, pos={61.00, 147.00}, size={37.00, 15.00}, proc=AB_CheckboxProc_PXP
	CheckBox check_load_pxp, title="PXP"
	CheckBox check_load_pxp, help={"Load PXP files (Igor Experiments) when iterating over folders"}
	CheckBox check_load_pxp, userdata(ResizeControlsInfo)=A"!!,E.!!#A\"!!#>\"!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_load_pxp, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_load_pxp, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_load_pxp, value=0
	Button button_load_tpstorage, pos={7.00, 507.00}, size={100.00, 25.00}, proc=AB_ButtonProc_LoadTPStorage
	Button button_load_tpstorage, title="Load TPStorage"
	Button button_load_tpstorage, help={"Load the TPStorage waves from the selected experiments"}
	Button button_load_tpstorage, userdata(ResizeControlsInfo)=A"!!,@C!!#CbJ,hpW!!#=+z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_load_tpstorage, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button button_load_tpstorage, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	GroupBox group0, pos={4.00, 2.00}, size={111.00, 187.00}
	GroupBox group0, userdata(ResizeControlsInfo)=A"!!,?8!!#7a!!#@B!!#AJz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	GroupBox group0, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	GroupBox group0, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	GroupBox group1, pos={4.00, 324.00}, size={111.00, 57.00}
	GroupBox group1, userdata(ResizeControlsInfo)=A"!!,?8!!#B\\!!#@B!!#>rz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	GroupBox group1, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	GroupBox group1, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	GroupBox group2, pos={4.00, 386.00}, size={111.00, 179.00}
	GroupBox group2, userdata(ResizeControlsInfo)=A"!!,?8!!#C&!!#@B!!#ABz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	GroupBox group2, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	GroupBox group2, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_load_results, pos={15.00, 168.00}, size={79.00, 15.00}
	CheckBox check_load_results, title="Load results"
	CheckBox check_load_results, help={"Load PXP files (Igor Experiments) when iterating over folders"}
	CheckBox check_load_results, userdata(ResizeControlsInfo)=A"!!,B)!!#A7!!#?W!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_load_results, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_load_results, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_load_results, value=0
	PopupMenu popup_SweepBrowserSelect, pos={8.00, 392.00}, size={99.00, 19.00}, bodyWidth=99
	PopupMenu popup_SweepBrowserSelect, userdata(ResizeControlsInfo)=A"!!,@c!!#C)!!#@*!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu popup_SweepBrowserSelect, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu popup_SweepBrowserSelect, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu popup_SweepBrowserSelect, mode=1, popvalue="New", value=#"AB_GetSweepBrowserListForPopup()"
	Button button_load_history, pos={7.00, 535.00}, size={100.00, 25.00}, proc=AB_ButtonProc_LoadHistoryAndLogs
	Button button_load_history, title="Load History"
	Button button_load_history, help={"Load the experiment history and logs"}
	Button button_load_history, userdata(ResizeControlsInfo)=A"!!,@C!!#Cj^]6^B!!#=+z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_load_history, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button button_load_history, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	DefineGuide splitGuide={FT, 10}, UGVL={FL, 15}
	SetWindow kwTopWin, hook(windowCoordinateSaving)=StoreWindowCoordinatesHook
	SetWindow kwTopWin, hook(ResizeControls)=ResizeControlsSafe
	SetWindow kwTopWin, hook(cleanup)=AB_WindowHook
	SetWindow kwTopWin, userdata(Config_PanelType)="AnalysisBrowser"
	SetWindow kwTopWin, userdata(JSONSettings_StoreCoordinates)="1"
	SetWindow kwTopWin, userdata(JSONSettings_WindowName)="analysisbrowser"
	SetWindow kwTopWin, userdata(ResizeControlsGuides)="splitGuide;UGVL;"
	SetWindow kwTopWin, userdata(ResizeControlsInfosplitGuide)="NAME:splitGuide;WIN:AnalysisBrowser;TYPE:User;HORIZONTAL:1;POSITION:10.00;GUIDE1:FT;GUIDE2:;RELPOSITION:10;"
	SetWindow kwTopWin, userdata(ResizeControlsInfoUGVL)="NAME:UGVL;WIN:AnalysisBrowser;TYPE:User;HORIZONTAL:0;POSITION:15.00;GUIDE1:FL;GUIDE2:;RELPOSITION:15;"
	SetWindow kwTopWin, userdata(ResizeControlsInfo)=A"!!*'\"z!!#EI?iWS(J,fQLzzzzzzzzzzzzzzzzzzzz"
	SetWindow kwTopWin, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzzzzzzzzzzzzzzz"
	SetWindow kwTopWin, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzzzzzzzzz!!!"
	Execute/Q/Z "SetWindow kwTopWin sizeLimit={854.25,405,inf,inf}" // sizeLimit requires Igor 7 or later
EndMacro
