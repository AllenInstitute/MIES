#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_ABMACRO
#endif

/// @file MIES_AnalysisBrowser.ipf
/// @brief __ABM__ Analysis browser Macro

Window AnalysisBrowser() : Panel
	PauseUpdate; Silent 1 // building window...
	NewPanel/K=1/W=(48, 425, 1188, 1257) as "AnalysisBrowser"
	ListBox list_experiment_contents, pos={120.00, 173.00}, size={1013.00, 653.00}, proc=AB_ListBoxProc_ExpBrowser
	ListBox list_experiment_contents, help={"Various properties of the loaded sweep data"}
	ListBox list_experiment_contents, userdata(ResizeControlsInfo)=A"!!,FU!!#A<!!#E85QF1s5QCca!!#](Aon\"Qzzzzzzzzzzzzzz!!#o2B4uAezz"
	ListBox list_experiment_contents, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	ListBox list_experiment_contents, userdata(ResizeControlsInfo)+=A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	ListBox list_experiment_contents, mode=4
	ListBox list_experiment_contents, widths={29, 285, 42, 27, 114, 62, 51, 78, 160, 63, 42, 42}
	ListBox list_experiment_contents, userColumnResize=1
	Button button_select_same_stim_sets, pos={6.00, 172.00}, size={100.00, 30.00}, proc=AB_ButtonProc_SelectStimSets
	Button button_select_same_stim_sets, title="Select same\r stim sets sweeps"
	Button button_select_same_stim_sets, help={"Starting from one selected sweep, select all other sweeps which were acquired with the same stimset"}
	Button button_select_same_stim_sets, userdata(ResizeControlsInfo)=A"!!,@#!!#A;!!#@,!!#=Sz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_select_same_stim_sets, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button button_select_same_stim_sets, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	Button button_collapse_all, pos={6.00, 206.00}, size={100.00, 25.00}, proc=AB_ButtonProc_CollapseAll
	Button button_collapse_all, title="Collapse all"
	Button button_collapse_all, help={"Collapse all entries giving the most compact view"}
	Button button_collapse_all, userdata(ResizeControlsInfo)=A"!!,@#!!#A]!!#@,!!#=+z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_collapse_all, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button button_collapse_all, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	Button button_expand_all, pos={6.00, 236.00}, size={100.00, 25.00}, proc=AB_ButtonProc_ExpandAll
	Button button_expand_all, title="Expand all"
	Button button_expand_all, help={"Expand all entries giving the longest view"}
	Button button_expand_all, userdata(ResizeControlsInfo)=A"!!,@#!!#B&!!#@,!!#=+z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_expand_all, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button button_expand_all, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	Button button_load_sweeps, pos={5.00, 412.00}, size={100.00, 25.00}, proc=AB_ButtonProc_LoadSweeps
	Button button_load_sweeps, title="Load Sweeps"
	Button button_load_sweeps, help={"Open a sweep browser panel from the selected sweeps. In case an experiment or device is selected, all sweeps are loaded from them."}
	Button button_load_sweeps, userdata(ResizeControlsInfo)=A"!!,?X!!#C3!!#@,!!#=+z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_load_sweeps, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button button_load_sweeps, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	Button button_load_stimsets, pos={5.00, 349.00}, size={100.00, 25.00}, proc=AB_ButtonProc_LoadStimsets
	Button button_load_stimsets, title="Load Stimsets"
	Button button_load_stimsets, help={"Open the wave builder panel with the selected stimset. All selected stimsets are loaded recursively."}
	Button button_load_stimsets, userdata(ResizeControlsInfo)=A"!!,?X!!#BhJ,hpW!!#=+z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_load_stimsets, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button button_load_stimsets, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	Button button_show_usercomments, pos={6.00, 266.00}, size={100.00, 25.00}, proc=AB_ButtonProc_OpenCommentNB
	Button button_show_usercomments, title="Open comment"
	Button button_show_usercomments, help={"Open a read-only notebook showing the user comment for the currently selected experiment."}
	Button button_show_usercomments, userdata(ResizeControlsInfo)=A"!!,@#!!#B?!!#@,!!#=+z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_show_usercomments, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button button_show_usercomments, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox checkbox_load_overwrite, pos={19.00, 302.00}, size={67.00, 15.00}
	CheckBox checkbox_load_overwrite, title="Overwrite"
	CheckBox checkbox_load_overwrite, help={"Overwrite existing stimsets on load or resaved NWBv2 files"}
	CheckBox checkbox_load_overwrite, userdata(ResizeControlsInfo)=A"!!,BQ!!#BQ!!#??!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox checkbox_load_overwrite, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox checkbox_load_overwrite, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox checkbox_load_overwrite, value=0
	Button button_show_resaveAsNWB, pos={6.00, 320.00}, size={100.00, 25.00}, proc=AB_ButtonProc_ResaveAsNWB
	Button button_show_resaveAsNWB, title="Resave as NWBv2"
	Button button_show_resaveAsNWB, help={"Save the loaded experiments as NWBv2 files"}
	Button button_show_resaveAsNWB, userdata(ResizeControlsInfo)=A"!!,@#!!#BZ!!#@,!!#=+z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_show_resaveAsNWB, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button button_show_resaveAsNWB, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	ListBox listbox_AB_Folders, pos={122.00, 4.00}, size={1010.00, 151.00}
	ListBox listbox_AB_Folders, help={"Source folders for sweep/stimset files"}
	ListBox listbox_AB_Folders, userdata(ResizeControlsInfo)=A"!!,FY!!#97!!#E7J,hqQz!!#](Aon\"Qzzzzzzzzzzzzzz!!#o2B4uAezz"
	ListBox listbox_AB_Folders, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	ListBox listbox_AB_Folders, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	ListBox listbox_AB_Folders, labelBack=(65535, 65535, 65535), mode=4
	Button button_AB_AddFolder, pos={7.00, 5.00}, size={100.00, 25.00}, proc=AB_ButtonProc_AddFolder
	Button button_AB_AddFolder, title="Add folder"
	Button button_AB_AddFolder, help={"Add a new folder to the list"}
	Button button_AB_AddFolder, userdata(ResizeControlsInfo)=A"!!,@C!!#9W!!#@,!!#=+z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_AB_AddFolder, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button button_AB_AddFolder, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	Button button_AB_Remove, pos={7.00, 60.00}, size={100.00, 25.00}, proc=AB_ButtonProc_Remove
	Button button_AB_Remove, title="Remove"
	Button button_AB_Remove, help={"Remove folders or files from the list"}
	Button button_AB_Remove, userdata(ResizeControlsInfo)=A"!!,@C!!#?)!!#@,!!#=+z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_AB_Remove, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button button_AB_Remove, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	Button button_AB_refresh, pos={7.00, 88.00}, size={100.00, 25.00}, proc=AB_ButtonProc_Refresh
	Button button_AB_refresh, title="Refresh", help={"Refresh stimset list"}
	Button button_AB_refresh, userdata(ResizeControlsInfo)=A"!!,@C!!#?i!!#@,!!#=+z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_AB_refresh, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button button_AB_refresh, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	Button button_AB_open, pos={7.00, 116.00}, size={100.00, 25.00}, proc=AB_ButtonProc_OpenFolders
	Button button_AB_open, title="Open", help={"Opens selected folders in Explorer"}
	Button button_AB_open, userdata(ResizeControlsInfo)=A"!!,@C!!#@L!!#@,!!#=+z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_AB_open, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button button_AB_open, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	Button button_AB_AddFiles, pos={7.00, 33.00}, size={100.00, 25.00}, proc=AB_ButtonProc_AddFiles
	Button button_AB_AddFiles, title="Add file(s)"
	Button button_AB_AddFiles, help={"Add a new files to the list"}
	Button button_AB_AddFiles, userdata(ResizeControlsInfo)=A"!!,@C!!#=g!!#@,!!#=+z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_AB_AddFiles, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button button_AB_AddFiles, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	Button button_load_sweepsAndStimsets, pos={6.00, 391.00}, size={100.00, 25.00}, proc=AB_ButtonProc_LoadBoth
	Button button_load_sweepsAndStimsets, title="Load Both"
	Button button_load_sweepsAndStimsets, help={"Open a sweep browser panel from the selected sweeps. In case an experiment or device is selected, all sweeps and stimsets are loaded from them."}
	Button button_load_sweepsAndStimsets, userdata(ResizeControlsInfo)=A"!!,@#!!#C(J,hpW!!#=+z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_load_sweepsAndStimsets, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button button_load_sweepsAndStimsets, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_load_nwb, pos={12.00, 147.00}, size={43.00, 15.00}, title="NWB"
	CheckBox check_load_nwb, help={"Load NWB v1 and v2 files when iterating over folders"}
	CheckBox check_load_nwb, userdata(ResizeControlsInfo)=A"!!,AN!!#A\"!!#>:!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_load_nwb, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_load_nwb, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_load_nwb, value=0
	CheckBox check_load_pxp, pos={61.00, 147.00}, size={37.00, 15.00}, title="PXP"
	CheckBox check_load_pxp, help={"Load PXP files (Igor Experiments) when iterating over folders"}
	CheckBox check_load_pxp, userdata(ResizeControlsInfo)=A"!!,E.!!#A\"!!#>\"!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_load_pxp, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_load_pxp, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_load_pxp, value=0
	Button button_load_tpstorage, pos={6.00, 383.00}, size={100.00, 25.00}, proc=AB_ButtonProc_LoadTPStorage
	Button button_load_tpstorage, title="Load TPStorage"
	Button button_load_tpstorage, help={"Load the TPStorage waves from the selected experiments"}
	Button button_load_tpstorage, userdata(ResizeControlsInfo)=A"!!,@#!!#C$J,hpW!!#=+z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_load_tpstorage, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button button_load_tpstorage, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	GroupBox group0, pos={4.00, 2.00}, size={111.00, 168.00}
	GroupBox group0, userdata(ResizeControlsInfo)=A"!!,?8!!#7a!!#@B!!#A7z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	GroupBox group0, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	GroupBox group0, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	GroupBox group1, pos={4.00, 298.00}, size={110.00, 82.00}
	GroupBox group1, userdata(ResizeControlsInfo)=A"!!,?8!!#BO!!#@@!!#?]z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	GroupBox group1, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	GroupBox group1, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	DefineGuide splitGuide={FT, 10}, UGVL={FL, 15}
	SetWindow kwTopWin, hook(windowCoordinateSaving)=StoreWindowCoordinatesHook
	SetWindow kwTopWin, hook(ResizeControls)=ResizeControlsSafe
	SetWindow kwTopWin, hook(cleanup)=AB_WindowHook
	SetWindow kwTopWin, userdata(ResizeControlsInfo)=A"!!*'\"z!!#EIJ,hu6zzzzzzzzzzzzzzzzzzzzz"
	SetWindow kwTopWin, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzzzzzzzzzzzzzzz"
	SetWindow kwTopWin, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzzzzzzzzz!!!"
	SetWindow kwTopWin, userdata(Config_PanelType)="AnalysisBrowser"
	SetWindow kwTopWin, userdata(JSONSettings_StoreCoordinates)="1"
	SetWindow kwTopWin, userdata(JSONSettings_WindowName)="analysisbrowser"
	SetWindow kwTopWin, userdata(ResizeControlsGuides)="splitGuide;UGVL;"
	SetWindow kwTopWin, userdata(ResizeControlsInfosplitGuide)="NAME:splitGuide;WIN:AnalysisBrowser;TYPE:User;HORIZONTAL:1;POSITION:10.00;GUIDE1:FT;GUIDE2:;RELPOSITION:10;"
	SetWindow kwTopWin, userdata(ResizeControlsInfoUGVL)="NAME:UGVL;WIN:AnalysisBrowser;TYPE:User;HORIZONTAL:0;POSITION:15.00;GUIDE1:FL;GUIDE2:;RELPOSITION:15;"
	Execute/Q/Z "SetWindow kwTopWin sizeLimit={855,624,inf,inf}" // sizeLimit requires Igor 7 or later
EndMacro
