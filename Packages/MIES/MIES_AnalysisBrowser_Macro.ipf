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
	NewPanel/K=1/W=(103, 722, 1405, 1376) as "AnalysisBrowser"
	DefineGuide splitGuide={FT, 10}, UGVL={FL, 15}
	ListBox list_experiment_contents, pos={123, 264}, size={1175, 397}, proc=AB_ListBoxProc_ExpBrowser
	ListBox list_experiment_contents, help={"Various properties of the loaded sweep data"}
	ListBox list_experiment_contents, userdata(ResizeControlsInfo)=A"!!,F[!!#B>!!#EMhuH-aJ,fQL!!#](Aon\"Qzzzzzzzzzzzzzz!!#o2B4uAezz"
	ListBox list_experiment_contents, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	ListBox list_experiment_contents, userdata(ResizeControlsInfo)+=A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	ListBox list_experiment_contents, mode=9
	ListBox list_experiment_contents, widths={17, 250, 52, 15, 104, 54, 46, 77, 153, 58, 47, 43, 144, 44, 7}
	ListBox list_experiment_contents, userColumnResize=1
	Button button_select_same_stim_sets, pos={10, 262}, size={100, 30}, proc=AB_ButtonProc_SelectStimSets
	Button button_select_same_stim_sets, title="Select same\r stim sets sweeps"
	Button button_select_same_stim_sets, help={"Starting from one selected sweep, select all other sweeps which were acquired with the same stimset"}
	Button button_select_same_stim_sets, userdata(ResizeControlsInfo)=A"!!,A.!!#B=!!#@,!!#=Sz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_select_same_stim_sets, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button button_select_same_stim_sets, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	Button button_collapse_all, pos={10, 296}, size={100, 25}, proc=AB_ButtonProc_CollapseAll
	Button button_collapse_all, title="Collapse all"
	Button button_collapse_all, help={"Collapse all entries giving the most compact view"}
	Button button_collapse_all, userdata(ResizeControlsInfo)=A"!!,A.!!#BN!!#@,!!#=+z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_collapse_all, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button button_collapse_all, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	Button button_expand_all, pos={10, 324}, size={100, 25}, proc=AB_ButtonProc_ExpandAll
	Button button_expand_all, title="Expand all"
	Button button_expand_all, help={"Expand all entries giving the longest view"}
	Button button_expand_all, userdata(ResizeControlsInfo)=A"!!,A.!!#B\\!!#@,!!#=+z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_expand_all, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button button_expand_all, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	Button button_load_sweeps, pos={9, 500}, size={100, 25}, proc=AB_ButtonProc_LoadSweeps
	Button button_load_sweeps, title="Load Sweeps"
	Button button_load_sweeps, help={"Open a sweep browser panel from the selected sweeps. In case an experiment or device is selected, all sweeps are loaded from them."}
	Button button_load_sweeps, userdata(ResizeControlsInfo)=A"!!,@s!!#C_!!#@,!!#=+z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_load_sweeps, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button button_load_sweeps, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	Button button_load_stimsets, pos={9, 528}, size={100, 25}, proc=AB_ButtonProc_LoadStimsets
	Button button_load_stimsets, title="Load Stimsets"
	Button button_load_stimsets, help={"Open the wave builder panel with the selected stimset. All selected stimsets are loaded recursively."}
	Button button_load_stimsets, userdata(ResizeControlsInfo)=A"!!,@s!!#Ci!!#@,!!#=+z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_load_stimsets, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button button_load_stimsets, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	Button button_show_usercomments, pos={10, 352}, size={100, 25}, proc=AB_ButtonProc_OpenCommentNB
	Button button_show_usercomments, title="Open comment"
	Button button_show_usercomments, help={"Open a read-only notebook showing the user comment for the currently selected experiment."}
	Button button_show_usercomments, userdata(ResizeControlsInfo)=A"!!,A.!!#Bj!!#@,!!#=+z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_show_usercomments, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button button_show_usercomments, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	Button button_show_tagcontrol, pos={10, 380}, size={100, 25}, proc=AB_ButtonProc_ShowTagControl
	Button button_show_tagcontrol, title="Hide tag control"
	Button button_show_tagcontrol, help={"Open tag control side panel."}
	Button button_show_tagcontrol, userdata(ResizeControlsInfo)=A"!!,A.!!#C#!!#@,!!#=+z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_show_tagcontrol, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button button_show_tagcontrol, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	Button button_show_tagcontrol, userdata(hideState)="0"
	CheckBox checkbox_load_overwrite, pos={9, 444}, size={67, 16}, title="Overwrite"
	CheckBox checkbox_load_overwrite, help={"Overwrite existing stimsets on load or resaved NWBv2 files"}
	CheckBox checkbox_load_overwrite, userdata(ResizeControlsInfo)=A"!!,@s!!#CC!!#??!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox checkbox_load_overwrite, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox checkbox_load_overwrite, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox checkbox_load_overwrite, value=0
	Button button_show_resaveAsNWB, pos={9, 415}, size={100, 25}, proc=AB_ButtonProc_ResaveAsNWB
	Button button_show_resaveAsNWB, title="Resave as NWBv2"
	Button button_show_resaveAsNWB, help={"Save the loaded experiments as NWBv2 files"}
	Button button_show_resaveAsNWB, userdata(ResizeControlsInfo)=A"!!,@s!!#C4J,hpW!!#=+z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_show_resaveAsNWB, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button button_show_resaveAsNWB, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	ListBox listbox_AB_Folders, pos={123, 3}, size={1175, 253}, proc=AB_ListBoxProc_FileFolderList
	ListBox listbox_AB_Folders, help={"Source folders for sweep/stimset files"}
	ListBox listbox_AB_Folders, userdata(ResizeControlsInfo)=A"!!,F[!!#8L!!#EMhuH,mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#o2B4uAezz"
	ListBox listbox_AB_Folders, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	ListBox listbox_AB_Folders, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	ListBox listbox_AB_Folders, labelBack=(65535, 65535, 65535), mode=9, special={4, 0, 0}
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
	Button button_AB_open, pos={7, 147}, size={100, 25}, proc=AB_ButtonProc_OpenFolders
	Button button_AB_open, title="Open", help={"Opens selected folders in Explorer"}
	Button button_AB_open, userdata(ResizeControlsInfo)=A"!!,@C!!#A\"!!#@,!!#=+z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_AB_open, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button button_AB_open, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	Button button_AB_AddFiles, pos={7, 33}, size={100, 25}, proc=AB_ButtonProc_AddFiles
	Button button_AB_AddFiles, title="Add file(s)"
	Button button_AB_AddFiles, help={"Add a new files to the list"}
	Button button_AB_AddFiles, userdata(ResizeControlsInfo)=A"!!,@C!!#=g!!#@,!!#=+z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_AB_AddFiles, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button button_AB_AddFiles, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	Button button_load_sweepsAndStimsets, pos={9, 556}, size={100, 25}, proc=AB_ButtonProc_LoadBoth
	Button button_load_sweepsAndStimsets, title="Load Both"
	Button button_load_sweepsAndStimsets, help={"Open a sweep browser panel from the selected sweeps. In case an experiment or device is selected, all sweeps and stimsets are loaded from them."}
	Button button_load_sweepsAndStimsets, userdata(ResizeControlsInfo)=A"!!,@s!!#Cp!!#@,!!#=+z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_load_sweepsAndStimsets, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button button_load_sweepsAndStimsets, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_load_nwb, pos={12, 177}, size={43, 16}, proc=AB_CheckboxProc_NWB
	CheckBox check_load_nwb, title="NWB"
	CheckBox check_load_nwb, help={"Load NWB v1 and v2 files when iterating over folders"}
	CheckBox check_load_nwb, userdata(ResizeControlsInfo)=A"!!,AN!!#A@!!#>:!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_load_nwb, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_load_nwb, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_load_nwb, value=1
	CheckBox check_load_pxp, pos={61, 177}, size={37, 16}, proc=AB_CheckboxProc_PXP
	CheckBox check_load_pxp, title="PXP"
	CheckBox check_load_pxp, help={"Load PXP files (Igor Experiments) when iterating over folders"}
	CheckBox check_load_pxp, userdata(ResizeControlsInfo)=A"!!,E.!!#A@!!#>\"!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_load_pxp, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_load_pxp, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_load_pxp, value=0
	Button button_load_tpstorage, pos={9, 590}, size={100, 25}, proc=AB_ButtonProc_LoadTPStorage
	Button button_load_tpstorage, title="Load TPStorage"
	Button button_load_tpstorage, help={"Load the TPStorage waves from the selected experiments"}
	Button button_load_tpstorage, userdata(ResizeControlsInfo)=A"!!,@s!!#D#J,hpW!!#=+z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_load_tpstorage, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button button_load_tpstorage, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	GroupBox group0, pos={4, 4}, size={109, 252}
	GroupBox group0, userdata(ResizeControlsInfo)=A"!!,?8!!#97!!#@>!!#B6z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	GroupBox group0, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	GroupBox group0, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	GroupBox group1, pos={6, 409}, size={111, 57}
	GroupBox group1, userdata(ResizeControlsInfo)=A"!!,@#!!#C1J,hpm!!#>rz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	GroupBox group1, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	GroupBox group1, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	GroupBox group2, pos={6, 469}, size={111, 179}
	GroupBox group2, userdata(ResizeControlsInfo)=A"!!,@#!!#COJ,hpm!!#ABz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	GroupBox group2, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	GroupBox group2, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_load_results, pos={7, 198}, size={79, 16}, title="Load results"
	CheckBox check_load_results, help={"Load PXP files (Igor Experiments) when iterating over folders"}
	CheckBox check_load_results, userdata(ResizeControlsInfo)=A"!!,@C!!#AU!!#?W!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_load_results, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_load_results, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_load_results, value=0
	PopupMenu popup_SweepBrowserSelect, pos={10, 477}, size={99, 20}, bodyWidth=99
	PopupMenu popup_SweepBrowserSelect, userdata(ResizeControlsInfo)=A"!!,A.!!#CSJ,hpU!!#<Xz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu popup_SweepBrowserSelect, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu popup_SweepBrowserSelect, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu popup_SweepBrowserSelect, mode=1, popvalue="New", value=#"AB_GetSweepBrowserListForPopup()"
	Button button_load_history, pos={9, 618}, size={100, 25}, proc=AB_ButtonProc_LoadHistoryAndLogs
	Button button_load_history, title="Load History"
	Button button_load_history, help={"Load the experiment history and logs"}
	Button button_load_history, userdata(ResizeControlsInfo)=A"!!,@s!!#D*J,hpW!!#=+z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_load_history, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button button_load_history, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_load_comment, pos={7, 216}, size={102, 16}, title="Load comments"
	CheckBox check_load_comment, help={"Load user comments from files"}
	CheckBox check_load_comment, userdata(ResizeControlsInfo)=A"!!,@C!!#Ag!!#@0!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_load_comment, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_load_comment, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_load_comment, value=0
	Button button_show_pastewindow, pos={7, 118}, size={100, 25}, proc=AB_ButtonProc_ShowPasteWindow
	Button button_show_pastewindow, title="Hide paste window"
	Button button_show_pastewindow, help={"Allows to paste files/folders/cell names"}
	Button button_show_pastewindow, userdata(ResizeControlsInfo)=A"!!,@C!!#@P!!#@,!!#=+z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_show_pastewindow, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button button_show_pastewindow, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	Button button_show_pastewindow, userdata(hideState)="0"
	SetWindow kwTopWin, hook(ResizeControls)=ResizeControlsSafe
	SetWindow kwTopWin, hook(cleanup)=AB_WindowHook
	SetWindow kwTopWin, userdata(Config_PanelType)="AnalysisBrowser"
	SetWindow kwTopWin, userdata(JSONSettings_WindowGroup)="analysisbrowser"
	SetWindow kwTopWin, userdata(ResizeControlsGuides)="splitGuide;UGVL;"
	SetWindow kwTopWin, userdata(ResizeControlsInfosplitGuide)="NAME:splitGuide;WIN:AnalysisBrowser;TYPE:User;HORIZONTAL:1;POSITION:10.00;GUIDE1:FT;GUIDE2:;RELPOSITION:10;"
	SetWindow kwTopWin, userdata(ResizeControlsInfoUGVL)="NAME:UGVL;WIN:AnalysisBrowser;TYPE:User;HORIZONTAL:0;POSITION:15.00;GUIDE1:FL;GUIDE2:;RELPOSITION:15;"
	SetWindow kwTopWin, userdata(ResizeControlsInfo)=A"!!*'\"z!!#E]^]6bIJ,fQLzzzzzzzzzzzzzzzzzzzz"
	SetWindow kwTopWin, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzzzzzzzzzzzzzzz"
	SetWindow kwTopWin, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzzzzzzzzz!!!"
	Execute/Q/Z "SetWindow kwTopWin sizeLimit={975.75,489.75,inf,inf}" // sizeLimit requires Igor 7 or later
	NewPanel/HOST=#/EXT=0/W=(0, 0, 235, 297) as "Tag Control"
	ModifyPanel fixedSize=0
	SetVariable setvar_tagcontrol_tagname, pos={8, 8}, size={149, 19}, proc=AB_SetVarProc_TagNameControl
	SetVariable setvar_tagcontrol_tagname, title="Tag:"
	SetVariable setvar_tagcontrol_tagname, help={"Enter a single tag.\rPress enter to add this tag to selected experiments in the experiment browser."}
	SetVariable setvar_tagcontrol_tagname, userdata(ResizeControlsInfo)=A"!!,@c!!#:b!!#A$!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#o2B4uAezz"
	SetVariable setvar_tagcontrol_tagname, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_tagcontrol_tagname, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_tagcontrol_tagname, value=_STR:""
	Button button_tagcontrol_addtag, pos={163, 6}, size={61, 20}, proc=AB_ButtonProc_AddTagControl
	Button button_tagcontrol_addtag, title="Add"
	Button button_tagcontrol_addtag, help={"Add the entered tag to selected experiments"}
	Button button_tagcontrol_addtag, userdata(ResizeControlsInfo)=A"!!,G3!!#:\"!!#?-!!#<Xz!!#o2B4uAezzzzzzzzzzzzzz!!#o2B4uAezz"
	Button button_tagcontrol_addtag, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button button_tagcontrol_addtag, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	ListBox list_tagcontrol_taglist, pos={8, 32}, size={149, 259}, proc=AB_ListBoxProc_TagList
	ListBox list_tagcontrol_taglist, help={"List of tags of all experiments."}
	ListBox list_tagcontrol_taglist, userdata(ResizeControlsInfo)=A"!!,@c!!#=c!!#A$!!#B;J,fQL!!#](Aon\"Qzzzzzzzzzzzzzz!!#o2B4uAezz"
	ListBox list_tagcontrol_taglist, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	ListBox list_tagcontrol_taglist, userdata(ResizeControlsInfo)+=A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	ListBox list_tagcontrol_taglist, listWave=root:MIES:Analysis:AnaBrowserTagsList
	ListBox list_tagcontrol_taglist, selWave=root:MIES:Analysis:AnaBrowserTagsSelection
	ListBox list_tagcontrol_taglist, colorWave=root:MIES:Analysis:AnaBrowserTagsColors
	ListBox list_tagcontrol_taglist, mode=9
	Button button_tagcontrol_removetag, pos={162, 32}, size={63, 20}, proc=AB_ButtonProc_RemoveTags
	Button button_tagcontrol_removetag, title="Remove"
	Button button_tagcontrol_removetag, help={"Remove all tags from selected experiments."}
	Button button_tagcontrol_removetag, userdata(ResizeControlsInfo)=A"!!,G2!!#=c!!#?5!!#<Xz!!#o2B4uAezzzzzzzzzzzzzz!!#o2B4uAezz"
	Button button_tagcontrol_removetag, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button button_tagcontrol_removetag, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetWindow kwTopWin, hook(closeTag)=AB_TagControlHook
	SetWindow kwTopWin, hook(ResizeControls)=ResizeControlsSafe
	SetWindow kwTopWin, userdata(ResizeControlsInfo)=A"!!*'\"z!!#B%!!#BNJ,fQLzzzzzzzzzzzzzzzzzzzz"
	SetWindow kwTopWin, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzzzzzzzzzzzzzzz"
	SetWindow kwTopWin, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzzzzzzzzz!!!"
	Execute/Q/Z "SetWindow kwTopWin sizeLimit={27,42,inf,inf}" // sizeLimit requires Igor 7 or later
	RenameWindow #, TagControl
	SetActiveSubwindow ##
	NewPanel/HOST=#/EXT=3/W=(0, 582, 1302, 0) as "Paste entry panel"
	ModifyPanel fixedSize=0
	Button button_add, pos={554, 516}, size={179, 44}, title="Add entries", proc=AB_ButtonProc_AddEntriesFromPasteWindow
	Button button_paste_info, pos={50, 516}, size={19.00, 19.00}, proc=AB_ButtonProc_PasteWindowShowHelp
	Button button_paste_info, title="i"
	Button button_paste_info, userdata(ResizeControlsInfo)=A"!!,BI!!#CJ!!#<P!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_paste_info, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button button_paste_info, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetWindow kwTopWin, hook(closePasteWindow)=AB_PastePanelHook
	Execute/Q/Z "SetWindow kwTopWin sizeLimit={28.5,42,inf,inf}" // sizeLimit requires Igor 7 or later
	NewNotebook/F=0/N=data/W=(10, 6, 1285, 482)/FG=(FL, FT, FR, $"")/HOST=#/OPTS=3
	Notebook kwTopWin, defaultTab=20, autoSave=1, magnification=1
	Notebook kwTopWin, font="Lucida Console", fSize=11, fStyle=0, textRGB=(0, 0, 0)
	Notebook kwTopWin, zdata="GaqDU%ejN7!Z)%D?io>lbN?PWL]d_/WWX="
	Notebook kwTopWin, zdataEnd=1
	RenameWindow #, data
	SetActiveSubwindow ##
	RenameWindow #, PasteWindow
	SetActiveSubwindow ##
EndMacro
