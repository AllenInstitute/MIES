#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_DBM
#endif

/// @file MIES_DataBrowser_Macro.ipf
/// @brief __DB__ Macro for DataBrowser

Window DataBrowser() : Graph
	PauseUpdate; Silent 1		// building window...
	Display /W=(363,179,795.75,484.25)/K=1  as "DataBrowser"
	Button button_BSP_open,pos={3.00,3.00},size={24.00,24.00},disable=1,proc=DB_ButtonProc_Panel,title="<<"
	Button button_BSP_open,help={"Open Side Panel"}
	Button button_BSP_open,userdata(ResizeControlsInfo)= A"!!,>M!!#8L!!#=#!!#=#z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_BSP_open,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button button_BSP_open,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetWindow kwTopWin,hook(TA_CURSOR_MOVED)=TimeAlignCursorMovedHook
	SetWindow kwTopWin,hook(ResizeControls)=ResizeControls#ResizeControlsHook
	SetWindow kwTopWin,userdata(BROWSER)=  "D"
	SetWindow kwTopWin,userdata(DEVICE)=  "- none -"
	SetWindow kwTopWin,userdata(ResizeControlsInfo)= A"!!*'\"z!!#C=?iWQ]TE\"rlzzzzzzzzzzzzzzzzzzzz"
	SetWindow kwTopWin,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzzzzzzzzzzzzzzz"
	SetWindow kwTopWin,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzzzzzzzzz!!!"
	Execute/Q/Z "SetWindow kwTopWin sizeLimit={324,228,inf,inf}" // sizeLimit requires Igor 7 or later
	NewPanel/HOST=#/EXT=2/W=(0,0,580,66)  as "Sweep Control"
	Button button_SweepControl_NextSweep,pos={333.00,0.00},size={150.00,36.00},title="Next  \\W649"
	Button button_SweepControl_NextSweep,help={"Displays the next sweep (sweep no. = last sweep number + step)"}
	Button button_SweepControl_NextSweep,fSize=20
	ValDisplay valdisp_SweepControl_LastSweep,pos={231.00,3.00},size={89.00,34.00},bodyWidth=60,title="of"
	ValDisplay valdisp_SweepControl_LastSweep,help={"The number of the last sweep acquired for the device assigned to the data browser"}
	ValDisplay valdisp_SweepControl_LastSweep,fSize=24,frame=2,fStyle=1
	ValDisplay valdisp_SweepControl_LastSweep,limits={0,0,0},barmisc={0,1000}
	ValDisplay valdisp_SweepControl_LastSweep,value= #"0"
	ValDisplay valdisp_SweepControl_LastSweep,barBackColor= (56576,56576,56576)
	SetVariable setvar_SweepControl_SweepNo,pos={153.00,0.00},size={72.00,35.00}
	SetVariable setvar_SweepControl_SweepNo,help={"Sweep number of last sweep plotted"}
	SetVariable setvar_SweepControl_SweepNo,userdata(lastSweep)=  "NaN",fSize=24
	SetVariable setvar_SweepControl_SweepNo,limits={0,0,1},value= _NUM:0,live= 1
	SetVariable setvar_SweepControl_SweepStep,pos={479.00,0.00},size={91.00,35.00},bodyWidth=40,title="Step"
	SetVariable setvar_SweepControl_SweepStep,help={"Set the increment between sweeps"}
	SetVariable setvar_SweepControl_SweepStep,userdata(lastSweep)=  "0",fSize=24
	SetVariable setvar_SweepControl_SweepStep,limits={1,inf,1},value= _NUM:1
	Button button_SweepControl_PrevSweep,pos={0.00,0.00},size={150.00,36.00},title="\\W646 Previous"
	Button button_SweepControl_PrevSweep,help={"Displays the previous sweep (sweep no. = last sweep number - step)"}
	Button button_SweepControl_PrevSweep,fSize=20
	PopupMenu Popup_SweepControl_Selector,pos={144.00,39.00},size={175.00,19.00},bodyWidth=175,disable=2
	PopupMenu Popup_SweepControl_Selector,help={"List of sweeps in this sweep browser"}
	PopupMenu Popup_SweepControl_Selector,userdata(tabnum)=  "0"
	PopupMenu Popup_SweepControl_Selector,userdata(tabcontrol)=  "Settings"
	PopupMenu Popup_SweepControl_Selector,mode=1,popvalue=" ",value= #"\" \""
	CheckBox check_SweepControl_AutoUpdate,pos={345.00,42.00},size={160.00,15.00},title="Display last sweep acquired"
	CheckBox check_SweepControl_AutoUpdate,help={"Displays the last sweep acquired when data acquistion is ongoing"}
	CheckBox check_SweepControl_AutoUpdate,value= 0
	RenameWindow #,SweepControl
	SetActiveSubwindow ##
	NewPanel/HOST=#/EXT=1/W=(391,0,0,406)  as " "
	ModifyPanel fixedSize=0
	GroupBox group_calc,pos={24.00,195.00},size={288.00,51.00}
	GroupBox group_calc,userdata(tabnum)=  "0",userdata(tabcontrol)=  "Settings"
	GroupBox group_calc,userdata(ResizeControlsInfo)= A"!!,CD!!#AR!!#BJ!!#>Zz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	GroupBox group_calc,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	GroupBox group_calc,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	TabControl Settings,pos={0.00,0.00},size={392.00,21.00},proc=ACL_DisplayTab
	TabControl Settings,userdata(currenttab)=  "0"
	TabControl Settings,userdata(ResizeControlsInfo)= A"!!*'\"z!!#C,J,hm6z!!#](Aon\"Qzzzzzzzzzzzzzz!!#o2B4uAeBE3-fz"
	TabControl Settings,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	TabControl Settings,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	TabControl Settings,tabLabel(0)="Settings",tabLabel(1)="OVS",tabLabel(2)="CS"
	TabControl Settings,tabLabel(3)="AR",tabLabel(4)="PA",tabLabel(5)="SF"
	TabControl Settings,tabLabel(6)="Note",tabLabel(7)="Dashboard",value= 0
	ListBox list_of_ranges,pos={81.00,198.00},size={215.00,201.00},disable=3,proc=OVS_MainListBoxProc
	ListBox list_of_ranges,help={"Select sweeps for overlay; The second column (\"Headstages\") allows to ignore some headstages for the graphing. Syntax is a semicolon \";\" separated list of subranges, e.g. \"0\", \"0,2\", \"1;4;2\""}
	ListBox list_of_ranges,userdata(tabnum)=  "1",userdata(tabcontrol)=  "Settings"
	ListBox list_of_ranges,userdata(ResizeControlsInfo)= A"!!,E\\!!#AU!!#Am!!#AYz!!#](Aon\"Qzzzzzzzzzzzzzz!!#o2B4uAezz"
	ListBox list_of_ranges,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	ListBox list_of_ranges,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	ListBox list_of_ranges,widths={50,50}
	PopupMenu popup_overlaySweeps_select,pos={119.00,99.00},size={143.00,19.00},bodyWidth=109,disable=3,proc=OVS_PopMenuProc_Select,title="Select"
	PopupMenu popup_overlaySweeps_select,help={"Select sweeps according to various properties"}
	PopupMenu popup_overlaySweeps_select,userdata(tabnum)=  "1"
	PopupMenu popup_overlaySweeps_select,userdata(tabcontrol)=  "Settings"
	PopupMenu popup_overlaySweeps_select,userdata(ResizeControlsInfo)= A"!!,F[!!#@*!!#@s!!#<Pz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	PopupMenu popup_overlaySweeps_select,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu popup_overlaySweeps_select,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu popup_overlaySweeps_select,mode=1,popvalue="- none -",value= #"\"\""
	CheckBox check_overlaySweeps_disableHS,pos={68.00,159.00},size={121.00,15.00},disable=3,proc=OVS_CheckBoxProc_HS_Select,title="Headstage Removal"
	CheckBox check_overlaySweeps_disableHS,help={"Toggle headstage removal"}
	CheckBox check_overlaySweeps_disableHS,userdata(tabnum)=  "1"
	CheckBox check_overlaySweeps_disableHS,userdata(tabcontrol)=  "Settings"
	CheckBox check_overlaySweeps_disableHS,userdata(ResizeControlsInfo)= A"!!,EJ!!#A.!!#@V!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_overlaySweeps_disableHS,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_overlaySweeps_disableHS,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_overlaySweeps_disableHS,value= 0
	CheckBox check_overlaySweeps_non_commula,pos={68.00,180.00},size={154.00,15.00},disable=3,title="Non-commulative update"
	CheckBox check_overlaySweeps_non_commula,help={"If \"Display Last sweep acquired\" is checked, this checkbox here allows to only add the newly acquired sweep and will remove the currently added last sweep."}
	CheckBox check_overlaySweeps_non_commula,userdata(tabcontrol)=  "Settings"
	CheckBox check_overlaySweeps_non_commula,userdata(tabnum)=  "1"
	CheckBox check_overlaySweeps_non_commula,userdata(ResizeControlsInfo)= A"!!,EJ!!#AC!!#A)!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_overlaySweeps_non_commula,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_overlaySweeps_non_commula,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_overlaySweeps_non_commula,value= 0
	SetVariable setvar_overlaySweeps_offset,pos={106.00,126.00},size={81.00,18.00},bodyWidth=45,disable=3,proc=OVS_SetVarProc_SelectionRange,title="Offset"
	SetVariable setvar_overlaySweeps_offset,help={"Offsets the first selected sweep from the selection menu"}
	SetVariable setvar_overlaySweeps_offset,userdata(tabnum)=  "1"
	SetVariable setvar_overlaySweeps_offset,userdata(tabcontrol)=  "Settings"
	SetVariable setvar_overlaySweeps_offset,userdata(ResizeControlsInfo)= A"!!,FA!!#@`!!#?[!!#<Hz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	SetVariable setvar_overlaySweeps_offset,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_overlaySweeps_offset,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_overlaySweeps_offset,limits={0,inf,1},value= _NUM:0
	SetVariable setvar_overlaySweeps_step,pos={193.00,126.00},size={72.00,18.00},bodyWidth=45,disable=3,proc=OVS_SetVarProc_SelectionRange,title="Step"
	SetVariable setvar_overlaySweeps_step,help={"Selects every `step` sweep from the selection menu"}
	SetVariable setvar_overlaySweeps_step,userdata(tabnum)=  "1"
	SetVariable setvar_overlaySweeps_step,userdata(tabcontrol)=  "Settings"
	SetVariable setvar_overlaySweeps_step,userdata(ResizeControlsInfo)= A"!!,GU!!#@`!!#?I!!#<Hz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	SetVariable setvar_overlaySweeps_step,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_overlaySweeps_step,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_overlaySweeps_step,limits={1,inf,1},value= _NUM:1
	GroupBox group_enable_sweeps,pos={3.00,30.00},size={383.00,51.00},disable=1,title="Overlay Sweeps"
	GroupBox group_enable_sweeps,userdata(tabnum)=  "1"
	GroupBox group_enable_sweeps,userdata(tabcontrol)=  "Settings"
	GroupBox group_enable_sweeps,userdata(ResizeControlsInfo)= A"!!,>M!!#=S!!#C(!!#>Zz!!#](Aon\"Qzzzzzzzzzzzzzz!!#o2B4uAezz"
	GroupBox group_enable_sweeps,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	GroupBox group_enable_sweeps,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	GroupBox group_enable_channels,pos={18.00,24.00},size={351.00,381.00},disable=1,title="Channel Selection"
	GroupBox group_enable_channels,userdata(tabnum)=  "2"
	GroupBox group_enable_channels,userdata(tabcontrol)=  "Settings"
	GroupBox group_enable_channels,userdata(ResizeControlsInfo)= A"!!,Bi!!#=#!!#BiJ,hsNJ,fQL!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	GroupBox group_enable_channels,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	GroupBox group_enable_channels,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	GroupBox group_enable_artifact,pos={3.00,27.00},size={383.00,54.00},disable=1,title="Artefact Removal"
	GroupBox group_enable_artifact,userdata(tabnum)=  "3"
	GroupBox group_enable_artifact,userdata(tabcontrol)=  "Settings"
	GroupBox group_enable_artifact,userdata(ResizeControlsInfo)= A"!!,>M!!#=;!!#C(!!#>fz!!#](Aon#azzzzzzzzzzzzzz!!#o2B4uAeBk2=!z"
	GroupBox group_enable_artifact,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	GroupBox group_enable_artifact,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	GroupBox group_properties_sweeps,pos={3.00,93.00},size={383.00,311.00},disable=3
	GroupBox group_properties_sweeps,userdata(tabnum)=  "1"
	GroupBox group_properties_sweeps,userdata(tabcontrol)=  "Settings"
	GroupBox group_properties_sweeps,userdata(ResizeControlsInfo)= A"!!,>M!!#?s!!#C(!!#BVz!!#](Aon\"Qzzzzzzzzzzzzzz!!#o2B4uAezz"
	GroupBox group_properties_sweeps,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	GroupBox group_properties_sweeps,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	GroupBox group_properties_artefact,pos={3.00,84.00},size={383.00,323.00},disable=3
	GroupBox group_properties_artefact,userdata(tabnum)=  "3"
	GroupBox group_properties_artefact,userdata(tabcontrol)=  "Settings"
	GroupBox group_properties_artefact,userdata(ResizeControlsInfo)= A"!!,>M!!#?a!!#C(!!#B\\z!!#](Aon\"Qzzzzzzzzzzzzzz!!#o2B4uAezz"
	GroupBox group_properties_artefact,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	GroupBox group_properties_artefact,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	GroupBox group_channelSel_DA,pos={105.00,42.00},size={42.00,198.00},disable=1,title="DA"
	GroupBox group_channelSel_DA,userdata(tabnum)=  "2"
	GroupBox group_channelSel_DA,userdata(tabcontrol)=  "Settings"
	GroupBox group_channelSel_DA,userdata(ResizeControlsInfo)= A"!!,F?!!#>6!!#>6!!#AUz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	GroupBox group_channelSel_DA,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	GroupBox group_channelSel_DA,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	GroupBox group_properties_pulse,pos={15.00,87.00},size={354.00,315.00},disable=3
	GroupBox group_properties_pulse,userdata(tabnum)=  "4"
	GroupBox group_properties_pulse,userdata(tabcontrol)=  "Settings"
	GroupBox group_properties_pulse,userdata(ResizeControlsInfo)= A"!!,BQ!!#?g!!#Bk!!#BWJ,fQL!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	GroupBox group_properties_pulse,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	GroupBox group_properties_pulse,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	GroupBox group_enable_pulse,pos={15.00,27.00},size={354.00,57.00},disable=1,title="Pulse Averaging"
	GroupBox group_enable_pulse,userdata(tabnum)=  "4"
	GroupBox group_enable_pulse,userdata(tabcontrol)=  "Settings"
	GroupBox group_enable_pulse,userdata(ResizeControlsInfo)= A"!!,BQ!!#=;!!#Bk!!#>rz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	GroupBox group_enable_pulse,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	GroupBox group_enable_pulse,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_DA_0,pos={117.00,60.00},size={22.00,15.00},disable=1,proc=DB_CheckProc_ChangedSetting,title="0"
	CheckBox check_channelSel_DA_0,userdata(tabnum)=  "2"
	CheckBox check_channelSel_DA_0,userdata(tabcontrol)=  "Settings"
	CheckBox check_channelSel_DA_0,userdata(ResizeControlsInfo)= A"!!,FW!!#?)!!#<h!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_DA_0,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_DA_0,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_DA_0,value= 1
	CheckBox check_channelSel_DA_1,pos={117.00,81.00},size={22.00,15.00},disable=1,proc=DB_CheckProc_ChangedSetting,title="1"
	CheckBox check_channelSel_DA_1,userdata(tabnum)=  "2"
	CheckBox check_channelSel_DA_1,userdata(tabcontrol)=  "Settings"
	CheckBox check_channelSel_DA_1,userdata(ResizeControlsInfo)= A"!!,FW!!#?[!!#<h!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_DA_1,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_DA_1,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_DA_1,value= 1
	CheckBox check_channelSel_DA_2,pos={117.00,102.00},size={22.00,15.00},disable=1,proc=DB_CheckProc_ChangedSetting,title="2"
	CheckBox check_channelSel_DA_2,userdata(tabnum)=  "2"
	CheckBox check_channelSel_DA_2,userdata(tabcontrol)=  "Settings"
	CheckBox check_channelSel_DA_2,userdata(ResizeControlsInfo)= A"!!,FW!!#@0!!#<h!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_DA_2,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_DA_2,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_DA_2,value= 1
	CheckBox check_channelSel_DA_3,pos={117.00,123.00},size={22.00,15.00},disable=1,proc=DB_CheckProc_ChangedSetting,title="3"
	CheckBox check_channelSel_DA_3,userdata(tabnum)=  "2"
	CheckBox check_channelSel_DA_3,userdata(tabcontrol)=  "Settings"
	CheckBox check_channelSel_DA_3,userdata(ResizeControlsInfo)= A"!!,FW!!#@Z!!#<h!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_DA_3,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_DA_3,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_DA_3,value= 1
	CheckBox check_channelSel_DA_4,pos={117.00,144.00},size={22.00,15.00},disable=1,proc=DB_CheckProc_ChangedSetting,title="4"
	CheckBox check_channelSel_DA_4,userdata(tabnum)=  "2"
	CheckBox check_channelSel_DA_4,userdata(tabcontrol)=  "Settings"
	CheckBox check_channelSel_DA_4,userdata(ResizeControlsInfo)= A"!!,FW!!#@t!!#<h!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_DA_4,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_DA_4,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_DA_4,value= 1
	CheckBox check_channelSel_DA_5,pos={117.00,165.00},size={22.00,15.00},disable=1,proc=DB_CheckProc_ChangedSetting,title="5"
	CheckBox check_channelSel_DA_5,userdata(tabnum)=  "2"
	CheckBox check_channelSel_DA_5,userdata(tabcontrol)=  "Settings"
	CheckBox check_channelSel_DA_5,userdata(ResizeControlsInfo)= A"!!,FW!!#A4!!#<h!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_DA_5,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_DA_5,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_DA_5,value= 1
	CheckBox check_channelSel_DA_6,pos={117.00,186.00},size={22.00,15.00},disable=1,proc=DB_CheckProc_ChangedSetting,title="6"
	CheckBox check_channelSel_DA_6,userdata(tabnum)=  "2"
	CheckBox check_channelSel_DA_6,userdata(tabcontrol)=  "Settings"
	CheckBox check_channelSel_DA_6,userdata(ResizeControlsInfo)= A"!!,FW!!#AI!!#<h!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_DA_6,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_DA_6,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_DA_6,value= 1
	CheckBox check_channelSel_DA_7,pos={117.00,207.00},size={22.00,15.00},disable=1,proc=DB_CheckProc_ChangedSetting,title="7"
	CheckBox check_channelSel_DA_7,userdata(tabnum)=  "2"
	CheckBox check_channelSel_DA_7,userdata(tabcontrol)=  "Settings"
	CheckBox check_channelSel_DA_7,userdata(ResizeControlsInfo)= A"!!,FW!!#A^!!#<h!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_DA_7,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_DA_7,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_DA_7,value= 1
	GroupBox group_channelSel_HEADSTAGE,pos={45.00,42.00},size={42.00,198.00},disable=1,title="HS"
	GroupBox group_channelSel_HEADSTAGE,userdata(tabnum)=  "2"
	GroupBox group_channelSel_HEADSTAGE,userdata(tabcontrol)=  "Settings"
	GroupBox group_channelSel_HEADSTAGE,userdata(ResizeControlsInfo)= A"!!,DS!!#>6!!#>6!!#AUz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	GroupBox group_channelSel_HEADSTAGE,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	GroupBox group_channelSel_HEADSTAGE,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_HEADSTAGE_0,pos={54.00,60.00},size={22.00,15.00},disable=1,proc=DB_CheckProc_ChangedSetting,title="0"
	CheckBox check_channelSel_HEADSTAGE_0,userdata(tabnum)=  "2"
	CheckBox check_channelSel_HEADSTAGE_0,userdata(tabcontrol)=  "Settings"
	CheckBox check_channelSel_HEADSTAGE_0,userdata(ResizeControlsInfo)= A"!!,E\"!!#?)!!#<h!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_HEADSTAGE_0,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_HEADSTAGE_0,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_HEADSTAGE_0,value= 1
	CheckBox check_channelSel_HEADSTAGE_1,pos={54.00,81.00},size={22.00,15.00},disable=1,proc=DB_CheckProc_ChangedSetting,title="1"
	CheckBox check_channelSel_HEADSTAGE_1,userdata(tabnum)=  "2"
	CheckBox check_channelSel_HEADSTAGE_1,userdata(tabcontrol)=  "Settings"
	CheckBox check_channelSel_HEADSTAGE_1,userdata(ResizeControlsInfo)= A"!!,E\"!!#?[!!#<h!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_HEADSTAGE_1,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_HEADSTAGE_1,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_HEADSTAGE_1,value= 1
	CheckBox check_channelSel_HEADSTAGE_2,pos={54.00,102.00},size={22.00,15.00},disable=1,proc=DB_CheckProc_ChangedSetting,title="2"
	CheckBox check_channelSel_HEADSTAGE_2,userdata(tabnum)=  "2"
	CheckBox check_channelSel_HEADSTAGE_2,userdata(tabcontrol)=  "Settings"
	CheckBox check_channelSel_HEADSTAGE_2,userdata(ResizeControlsInfo)= A"!!,E\"!!#@0!!#<h!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_HEADSTAGE_2,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_HEADSTAGE_2,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_HEADSTAGE_2,value= 1
	CheckBox check_channelSel_HEADSTAGE_3,pos={54.00,123.00},size={22.00,15.00},disable=1,proc=DB_CheckProc_ChangedSetting,title="3"
	CheckBox check_channelSel_HEADSTAGE_3,userdata(tabnum)=  "2"
	CheckBox check_channelSel_HEADSTAGE_3,userdata(tabcontrol)=  "Settings"
	CheckBox check_channelSel_HEADSTAGE_3,userdata(ResizeControlsInfo)= A"!!,E\"!!#@Z!!#<h!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_HEADSTAGE_3,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_HEADSTAGE_3,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_HEADSTAGE_3,value= 1
	CheckBox check_channelSel_HEADSTAGE_4,pos={54.00,144.00},size={22.00,15.00},disable=1,proc=DB_CheckProc_ChangedSetting,title="4"
	CheckBox check_channelSel_HEADSTAGE_4,userdata(tabnum)=  "2"
	CheckBox check_channelSel_HEADSTAGE_4,userdata(tabcontrol)=  "Settings"
	CheckBox check_channelSel_HEADSTAGE_4,userdata(ResizeControlsInfo)= A"!!,E\"!!#@t!!#<h!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_HEADSTAGE_4,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_HEADSTAGE_4,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_HEADSTAGE_4,value= 1
	CheckBox check_channelSel_HEADSTAGE_5,pos={54.00,165.00},size={22.00,15.00},disable=1,proc=DB_CheckProc_ChangedSetting,title="5"
	CheckBox check_channelSel_HEADSTAGE_5,userdata(tabnum)=  "2"
	CheckBox check_channelSel_HEADSTAGE_5,userdata(tabcontrol)=  "Settings"
	CheckBox check_channelSel_HEADSTAGE_5,userdata(ResizeControlsInfo)= A"!!,E\"!!#A4!!#<h!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_HEADSTAGE_5,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_HEADSTAGE_5,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_HEADSTAGE_5,value= 1
	CheckBox check_channelSel_HEADSTAGE_6,pos={54.00,186.00},size={22.00,15.00},disable=1,proc=DB_CheckProc_ChangedSetting,title="6"
	CheckBox check_channelSel_HEADSTAGE_6,userdata(tabnum)=  "2"
	CheckBox check_channelSel_HEADSTAGE_6,userdata(tabcontrol)=  "Settings"
	CheckBox check_channelSel_HEADSTAGE_6,userdata(ResizeControlsInfo)= A"!!,E\"!!#AI!!#<h!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_HEADSTAGE_6,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_HEADSTAGE_6,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_HEADSTAGE_6,value= 1
	CheckBox check_channelSel_HEADSTAGE_7,pos={54.00,207.00},size={22.00,15.00},disable=1,proc=DB_CheckProc_ChangedSetting,title="7"
	CheckBox check_channelSel_HEADSTAGE_7,userdata(tabnum)=  "2"
	CheckBox check_channelSel_HEADSTAGE_7,userdata(tabcontrol)=  "Settings"
	CheckBox check_channelSel_HEADSTAGE_7,userdata(ResizeControlsInfo)= A"!!,E\"!!#A^!!#<h!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_HEADSTAGE_7,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_HEADSTAGE_7,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_HEADSTAGE_7,value= 1
	GroupBox group_channelSel_AD,pos={168.00,42.00},size={45.00,360.00},disable=1,title="AD"
	GroupBox group_channelSel_AD,userdata(tabnum)=  "2"
	GroupBox group_channelSel_AD,userdata(tabcontrol)=  "Settings"
	GroupBox group_channelSel_AD,userdata(ResizeControlsInfo)= A"!!,G<!!#>6!!#>B!!#Bnz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	GroupBox group_channelSel_AD,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	GroupBox group_channelSel_AD,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_AD_0,pos={174.00,60.00},size={22.00,15.00},disable=1,proc=DB_CheckProc_ChangedSetting,title="0"
	CheckBox check_channelSel_AD_0,userdata(tabnum)=  "2"
	CheckBox check_channelSel_AD_0,userdata(tabcontrol)=  "Settings"
	CheckBox check_channelSel_AD_0,userdata(ResizeControlsInfo)= A"!!,GB!!#?)!!#<h!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_AD_0,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_AD_0,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_AD_0,value= 1
	CheckBox check_channelSel_AD_1,pos={174.00,81.00},size={22.00,15.00},disable=1,proc=DB_CheckProc_ChangedSetting,title="1"
	CheckBox check_channelSel_AD_1,userdata(tabnum)=  "2"
	CheckBox check_channelSel_AD_1,userdata(tabcontrol)=  "Settings"
	CheckBox check_channelSel_AD_1,userdata(ResizeControlsInfo)= A"!!,GB!!#?[!!#<h!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_AD_1,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_AD_1,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_AD_1,value= 1
	CheckBox check_channelSel_AD_2,pos={174.00,102.00},size={22.00,15.00},disable=1,proc=DB_CheckProc_ChangedSetting,title="2"
	CheckBox check_channelSel_AD_2,userdata(tabnum)=  "2"
	CheckBox check_channelSel_AD_2,userdata(tabcontrol)=  "Settings"
	CheckBox check_channelSel_AD_2,userdata(ResizeControlsInfo)= A"!!,GB!!#@0!!#<h!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_AD_2,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_AD_2,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_AD_2,value= 1
	CheckBox check_channelSel_AD_3,pos={174.00,123.00},size={22.00,15.00},disable=1,proc=DB_CheckProc_ChangedSetting,title="3"
	CheckBox check_channelSel_AD_3,userdata(tabnum)=  "2"
	CheckBox check_channelSel_AD_3,userdata(tabcontrol)=  "Settings"
	CheckBox check_channelSel_AD_3,userdata(ResizeControlsInfo)= A"!!,GB!!#@Z!!#<h!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_AD_3,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_AD_3,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_AD_3,value= 1
	CheckBox check_channelSel_AD_4,pos={174.00,144.00},size={22.00,15.00},disable=1,proc=DB_CheckProc_ChangedSetting,title="4"
	CheckBox check_channelSel_AD_4,userdata(tabnum)=  "2"
	CheckBox check_channelSel_AD_4,userdata(tabcontrol)=  "Settings"
	CheckBox check_channelSel_AD_4,userdata(ResizeControlsInfo)= A"!!,GB!!#@t!!#<h!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_AD_4,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_AD_4,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_AD_4,value= 1
	CheckBox check_channelSel_AD_5,pos={174.00,165.00},size={22.00,15.00},disable=1,proc=DB_CheckProc_ChangedSetting,title="5"
	CheckBox check_channelSel_AD_5,userdata(tabnum)=  "2"
	CheckBox check_channelSel_AD_5,userdata(tabcontrol)=  "Settings"
	CheckBox check_channelSel_AD_5,userdata(ResizeControlsInfo)= A"!!,GB!!#A4!!#<h!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_AD_5,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_AD_5,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_AD_5,value= 1
	CheckBox check_channelSel_AD_6,pos={174.00,186.00},size={22.00,15.00},disable=1,proc=DB_CheckProc_ChangedSetting,title="6"
	CheckBox check_channelSel_AD_6,userdata(tabnum)=  "2"
	CheckBox check_channelSel_AD_6,userdata(tabcontrol)=  "Settings"
	CheckBox check_channelSel_AD_6,userdata(ResizeControlsInfo)= A"!!,GB!!#AI!!#<h!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_AD_6,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_AD_6,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_AD_6,value= 1
	CheckBox check_channelSel_AD_7,pos={174.00,207.00},size={22.00,15.00},disable=1,proc=DB_CheckProc_ChangedSetting,title="7"
	CheckBox check_channelSel_AD_7,userdata(tabnum)=  "2"
	CheckBox check_channelSel_AD_7,userdata(tabcontrol)=  "Settings"
	CheckBox check_channelSel_AD_7,userdata(ResizeControlsInfo)= A"!!,GB!!#A^!!#<h!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_AD_7,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_AD_7,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_AD_7,value= 1
	CheckBox check_channelSel_AD_8,pos={174.00,228.00},size={22.00,15.00},disable=1,proc=DB_CheckProc_ChangedSetting,title="8"
	CheckBox check_channelSel_AD_8,userdata(tabnum)=  "2"
	CheckBox check_channelSel_AD_8,userdata(tabcontrol)=  "Settings"
	CheckBox check_channelSel_AD_8,userdata(ResizeControlsInfo)= A"!!,GB!!#As!!#<h!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_AD_8,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_AD_8,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_AD_8,value= 1
	CheckBox check_channelSel_AD_9,pos={174.00,249.00},size={22.00,15.00},disable=1,proc=DB_CheckProc_ChangedSetting,title="9"
	CheckBox check_channelSel_AD_9,userdata(tabnum)=  "2"
	CheckBox check_channelSel_AD_9,userdata(tabcontrol)=  "Settings"
	CheckBox check_channelSel_AD_9,userdata(ResizeControlsInfo)= A"!!,GB!!#B3!!#<h!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_AD_9,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_AD_9,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_AD_9,value= 1
	CheckBox check_channelSel_AD_10,pos={174.00,270.00},size={28.00,15.00},disable=1,proc=DB_CheckProc_ChangedSetting,title="10"
	CheckBox check_channelSel_AD_10,userdata(tabnum)=  "2"
	CheckBox check_channelSel_AD_10,userdata(tabcontrol)=  "Settings"
	CheckBox check_channelSel_AD_10,userdata(ResizeControlsInfo)= A"!!,GB!!#BA!!#=C!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_AD_10,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_AD_10,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_AD_10,value= 1
	CheckBox check_channelSel_AD_11,pos={174.00,291.00},size={28.00,15.00},disable=1,proc=DB_CheckProc_ChangedSetting,title="11"
	CheckBox check_channelSel_AD_11,userdata(tabnum)=  "2"
	CheckBox check_channelSel_AD_11,userdata(tabcontrol)=  "Settings"
	CheckBox check_channelSel_AD_11,userdata(ResizeControlsInfo)= A"!!,GB!!#BKJ,hmn!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_AD_11,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_AD_11,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_AD_11,value= 1
	CheckBox check_channelSel_AD_12,pos={174.00,312.00},size={28.00,15.00},disable=1,proc=DB_CheckProc_ChangedSetting,title="12"
	CheckBox check_channelSel_AD_12,userdata(tabnum)=  "2"
	CheckBox check_channelSel_AD_12,userdata(tabcontrol)=  "Settings"
	CheckBox check_channelSel_AD_12,userdata(ResizeControlsInfo)= A"!!,GB!!#BV!!#=C!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_AD_12,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_AD_12,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_AD_12,value= 1
	CheckBox check_channelSel_AD_13,pos={174.00,333.00},size={28.00,15.00},disable=1,proc=DB_CheckProc_ChangedSetting,title="13"
	CheckBox check_channelSel_AD_13,userdata(tabnum)=  "2"
	CheckBox check_channelSel_AD_13,userdata(tabcontrol)=  "Settings"
	CheckBox check_channelSel_AD_13,userdata(ResizeControlsInfo)= A"!!,GB!!#B`J,hmn!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_AD_13,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_AD_13,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_AD_13,value= 1
	CheckBox check_channelSel_AD_14,pos={174.00,354.00},size={28.00,15.00},disable=1,proc=DB_CheckProc_ChangedSetting,title="14"
	CheckBox check_channelSel_AD_14,userdata(tabnum)=  "2"
	CheckBox check_channelSel_AD_14,userdata(tabcontrol)=  "Settings"
	CheckBox check_channelSel_AD_14,userdata(ResizeControlsInfo)= A"!!,GB!!#Bk!!#=C!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_AD_14,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_AD_14,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_AD_14,value= 1
	CheckBox check_channelSel_AD_15,pos={174.00,375.00},size={28.00,15.00},disable=1,proc=DB_CheckProc_ChangedSetting,title="15"
	CheckBox check_channelSel_AD_15,userdata(tabnum)=  "2"
	CheckBox check_channelSel_AD_15,userdata(tabcontrol)=  "Settings"
	CheckBox check_channelSel_AD_15,userdata(ResizeControlsInfo)= A"!!,GB!!#BuJ,hmn!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_AD_15,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_AD_15,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_AD_15,value= 1
	ListBox list_of_ranges1,pos={75.00,156.00},size={227.00,242.00},disable=3,proc=AR_MainListBoxProc
	ListBox list_of_ranges1,userdata(tabnum)=  "3",userdata(tabcontrol)=  "Settings"
	ListBox list_of_ranges1,userdata(ResizeControlsInfo)= A"!!,EP!!#A+!!#B$!!#B-z!!#](Aon\"Qzzzzzzzzzzzzzz!!#o2B4uAezz"
	ListBox list_of_ranges1,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	ListBox list_of_ranges1,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	ListBox list_of_ranges1,mode= 1,selRow= 0,widths={54,50,66}
	Button button_RemoveRanges,pos={87.00,126.00},size={54.00,21.00},disable=3,proc=AR_ButtonProc_RemoveRanges,title="Remove"
	Button button_RemoveRanges,userdata(tabnum)=  "3"
	Button button_RemoveRanges,userdata(tabcontrol)=  "Settings"
	Button button_RemoveRanges,userdata(ResizeControlsInfo)= A"!!,Ep!!#@`!!#>f!!#<`z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	Button button_RemoveRanges,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button button_RemoveRanges,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_cutoff_length_after,pos={243.00,96.00},size={45.00,18.00},disable=3,proc=AR_SetVarProcCutoffLength
	SetVariable setvar_cutoff_length_after,help={"Time in ms which should be cutoff *after* the artefact."}
	SetVariable setvar_cutoff_length_after,userdata(tabnum)=  "3"
	SetVariable setvar_cutoff_length_after,userdata(tabcontrol)=  "Settings"
	SetVariable setvar_cutoff_length_after,userdata(ResizeControlsInfo)= A"!!,H2!!#@$!!#>B!!#<Hz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	SetVariable setvar_cutoff_length_after,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_cutoff_length_after,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_cutoff_length_after,limits={0,inf,0.1},value= _NUM:0.2
	SetVariable setvar_cutoff_length_before,pos={90.00,96.00},size={150.00,18.00},disable=3,proc=AR_SetVarProcCutoffLength,title="Cutoff length [ms]:"
	SetVariable setvar_cutoff_length_before,help={"Time in ms which should be cutoff *before* the artefact."}
	SetVariable setvar_cutoff_length_before,userdata(tabnum)=  "3"
	SetVariable setvar_cutoff_length_before,userdata(tabcontrol)=  "Settings"
	SetVariable setvar_cutoff_length_before,userdata(ResizeControlsInfo)= A"!!,F!!!#@$!!#A%!!#<Hz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	SetVariable setvar_cutoff_length_before,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_cutoff_length_before,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_cutoff_length_before,limits={0,inf,0.1},value= _NUM:0.1
	CheckBox check_auto_remove,pos={156.00,129.00},size={85.00,15.00},disable=3,proc=AR_CheckProc_Update,title="Auto remove"
	CheckBox check_auto_remove,help={"Automatically remove the found ranges on sweep plotting"}
	CheckBox check_auto_remove,userdata(tabnum)=  "3"
	CheckBox check_auto_remove,userdata(tabcontrol)=  "Settings"
	CheckBox check_auto_remove,userdata(ResizeControlsInfo)= A"!!,G0!!#@e!!#?c!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_auto_remove,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_auto_remove,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_auto_remove,value= 0
	CheckBox check_highlightRanges,pos={258.00,129.00},size={31.00,15.00},disable=3,proc=AR_CheckProc_Update,title="HL"
	CheckBox check_highlightRanges,help={"Visualize the found ranges in the graph (*might* slowdown graphing)"}
	CheckBox check_highlightRanges,userdata(tabnum)=  "3"
	CheckBox check_highlightRanges,userdata(tabcontrol)=  "Settings"
	CheckBox check_highlightRanges,userdata(ResizeControlsInfo)= A"!!,H>!!#@e!!#=[!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_highlightRanges,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_highlightRanges,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_highlightRanges,value= 0
	SetVariable setvar_pulseAver_fallbackLength,pos={135.00,225.00},size={112.00,12.00},bodyWidth=50,disable=3,proc=PA_SetVarProc_Common,title="Fallback Length"
	SetVariable setvar_pulseAver_fallbackLength,help={"Pulse To Pulse Length in ms for edge cases which can not be computed."}
	SetVariable setvar_pulseAver_fallbackLength,userdata(tabnum)=  "4"
	SetVariable setvar_pulseAver_fallbackLength,userdata(tabcontrol)=  "Settings"
	SetVariable setvar_pulseAver_fallbackLength,userdata(ResizeControlsInfo)= A"!!,Fp!!#Ap!!#@D!!#;Mz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	SetVariable setvar_pulseAver_fallbackLength,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_pulseAver_fallbackLength,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_pulseAver_fallbackLength,value= _NUM:100
	SetVariable setvar_pulseAver_endPulse,pos={148.00,204.00},size={102.00,12.00},bodyWidth=50,disable=3,proc=PA_SetVarProc_Common,title="Ending Pulse"
	SetVariable setvar_pulseAver_endPulse,userdata(tabnum)=  "4"
	SetVariable setvar_pulseAver_endPulse,userdata(tabcontrol)=  "Settings"
	SetVariable setvar_pulseAver_endPulse,userdata(ResizeControlsInfo)= A"!!,G(!!#A[!!#@0!!#;Mz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	SetVariable setvar_pulseAver_endPulse,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_pulseAver_endPulse,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_pulseAver_endPulse,value= _NUM:inf
	SetVariable setvar_pulseAver_startPulse,pos={144.00,180.00},size={105.00,12.00},bodyWidth=50,disable=3,proc=PA_SetVarProc_Common,title="Starting Pulse"
	SetVariable setvar_pulseAver_startPulse,userdata(tabnum)=  "4"
	SetVariable setvar_pulseAver_startPulse,userdata(tabcontrol)=  "Settings"
	SetVariable setvar_pulseAver_startPulse,userdata(ResizeControlsInfo)= A"!!,G$!!#AC!!#@6!!#;Mz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	SetVariable setvar_pulseAver_startPulse,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_pulseAver_startPulse,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_pulseAver_startPulse,value= _NUM:0
	CheckBox check_pulseAver_multGraphs,pos={120.00,162.00},size={90.00,12.00},disable=3,proc=PA_CheckProc_Common,title="Use multiple graphs"
	CheckBox check_pulseAver_multGraphs,help={"Show the single pulses in multiple graphs or only one graph with mutiple axis."}
	CheckBox check_pulseAver_multGraphs,userdata(tabnum)=  "4"
	CheckBox check_pulseAver_multGraphs,userdata(tabcontrol)=  "Settings"
	CheckBox check_pulseAver_multGraphs,userdata(ResizeControlsInfo)= A"!!,F]!!#A1!!#?m!!#;Mz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_pulseAver_multGraphs,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_pulseAver_multGraphs,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_pulseAver_multGraphs,value= 0
	CheckBox check_pulseAver_zeroTrac,pos={120.00,120.00},size={54.00,12.00},disable=3,proc=PA_CheckProc_Common,title="Zero traces"
	CheckBox check_pulseAver_zeroTrac,help={"Zero the individual traces using subsequent differentiation and integration"}
	CheckBox check_pulseAver_zeroTrac,userdata(tabnum)=  "4"
	CheckBox check_pulseAver_zeroTrac,userdata(tabcontrol)=  "Settings"
	CheckBox check_pulseAver_zeroTrac,userdata(ResizeControlsInfo)= A"!!,F]!!#@T!!#>f!!#;Mz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_pulseAver_zeroTrac,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_pulseAver_zeroTrac,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_pulseAver_zeroTrac,value= 0
	CheckBox check_pulseAver_showAver,pos={120.00,141.00},size={88.00,12.00},disable=3,proc=PA_CheckProc_Average,title="Show average trace"
	CheckBox check_pulseAver_showAver,help={"Show the average trace"}
	CheckBox check_pulseAver_showAver,userdata(tabnum)=  "4"
	CheckBox check_pulseAver_showAver,userdata(tabcontrol)=  "Settings"
	CheckBox check_pulseAver_showAver,userdata(ResizeControlsInfo)= A"!!,F]!!#@q!!#?i!!#;Mz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_pulseAver_showAver,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_pulseAver_showAver,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_pulseAver_showAver,value= 0
	CheckBox check_pulseAver_indTraces,pos={120.00,99.00},size={99.00,12.00},disable=3,proc=PA_CheckProc_Individual,title="Show individual traces"
	CheckBox check_pulseAver_indTraces,help={"Show the individual traces"}
	CheckBox check_pulseAver_indTraces,userdata(tabnum)=  "4"
	CheckBox check_pulseAver_indTraces,userdata(tabcontrol)=  "Settings"
	CheckBox check_pulseAver_indTraces,userdata(ResizeControlsInfo)= A"!!,F]!!#@*!!#@*!!#;Mz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_pulseAver_indTraces,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_pulseAver_indTraces,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_pulseAver_indTraces,value= 1
	CheckBox check_pulseAver_deconv,pos={120.00,249.00},size={69.00,12.00},disable=3,proc=PA_CheckProc_Deconvolution,title="Deconvolution"
	CheckBox check_pulseAver_deconv,help={"Show Deconvolution: tau * dV/dt + V"}
	CheckBox check_pulseAver_deconv,userdata(tabnum)=  "4"
	CheckBox check_pulseAver_deconv,userdata(tabcontrol)=  "Settings"
	CheckBox check_pulseAver_deconv,userdata(ResizeControlsInfo)= A"!!,F]!!#B3!!#?C!!#;Mz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_pulseAver_deconv,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_pulseAver_deconv,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_pulseAver_deconv,value= 0
	CheckBox check_pulseAver_timeAlign,pos={120.00,348.00},size={75.00,12.00},disable=3,proc=PA_CheckProc_Common,title="Time Alignment"
	CheckBox check_pulseAver_timeAlign,help={"Automatically align all traces in the PA graph to a reference trace from the diagonal element"}
	CheckBox check_pulseAver_timeAlign,userdata(tabnum)=  "4"
	CheckBox check_pulseAver_timeAlign,userdata(tabcontrol)=  "Settings"
	CheckBox check_pulseAver_timeAlign,userdata(ResizeControlsInfo)= A"!!,F]!!#Bh!!#?O!!#;Mz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_pulseAver_timeAlign,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_pulseAver_timeAlign,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_pulseAver_timeAlign,value= 0
	SetVariable setvar_pulseAver_deconv_tau,pos={166.00,270.00},size={84.00,12.00},bodyWidth=50,disable=3,proc=PA_SetVarProc_Common,title="tau [ms]"
	SetVariable setvar_pulseAver_deconv_tau,help={"Deconvolution time tau: tau * dV/dt + V"}
	SetVariable setvar_pulseAver_deconv_tau,userdata(tabnum)=  "4"
	SetVariable setvar_pulseAver_deconv_tau,userdata(tabcontrol)=  "Settings"
	SetVariable setvar_pulseAver_deconv_tau,userdata(ResizeControlsInfo)= A"!!,G:!!#BA!!#?a!!#;Mz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	SetVariable setvar_pulseAver_deconv_tau,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_pulseAver_deconv_tau,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_pulseAver_deconv_tau,limits={0,inf,0},value= _NUM:15
	SetVariable setvar_pulseAver_deconv_smth,pos={153.00,294.00},size={93.00,12.00},bodyWidth=50,disable=3,proc=PA_SetVarProc_Common,title="smoothing"
	SetVariable setvar_pulseAver_deconv_smth,help={"Smoothing factor to use before the deconvolution is calculated. Set to 1 to do the calculation without smoothing."}
	SetVariable setvar_pulseAver_deconv_smth,userdata(tabnum)=  "4"
	SetVariable setvar_pulseAver_deconv_smth,userdata(tabcontrol)=  "Settings"
	SetVariable setvar_pulseAver_deconv_smth,userdata(ResizeControlsInfo)= A"!!,G-!!#BM!!#?s!!#;Mz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	SetVariable setvar_pulseAver_deconv_smth,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_pulseAver_deconv_smth,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_pulseAver_deconv_smth,limits={1,inf,0},value= _NUM:1000
	SetVariable setvar_pulseAver_deconv_range,pos={150.00,315.00},size={99.00,12.00},bodyWidth=50,disable=3,proc=PA_SetVarProc_Common,title="display [ms]"
	SetVariable setvar_pulseAver_deconv_range,help={"Time in ms from the beginning of the pulse that is used for the calculation"}
	SetVariable setvar_pulseAver_deconv_range,userdata(tabnum)=  "4"
	SetVariable setvar_pulseAver_deconv_range,userdata(tabcontrol)=  "Settings"
	SetVariable setvar_pulseAver_deconv_range,userdata(ResizeControlsInfo)= A"!!,G*!!#BWJ,hpU!!#;Mz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	SetVariable setvar_pulseAver_deconv_range,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_pulseAver_deconv_range,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_pulseAver_deconv_range,limits={0,inf,0},value= _NUM:inf
	GroupBox group_pulseAver_deconv,pos={111.00,246.00},size={153.00,96.00},disable=3
	GroupBox group_pulseAver_deconv,userdata(tabnum)=  "4"
	GroupBox group_pulseAver_deconv,userdata(tabcontrol)=  "Settings"
	GroupBox group_pulseAver_deconv,userdata(ResizeControlsInfo)= A"!!,FK!!#B0!!#A(!!#@$z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	GroupBox group_pulseAver_deconv,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	GroupBox group_pulseAver_deconv,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_BrowserSettings_OVS,pos={168.00,48.00},size={51.00,15.00},disable=1,proc=DB_CheckProc_OverlaySweeps,title="enable"
	CheckBox check_BrowserSettings_OVS,help={"Adds unplotted sweep to graph. Removes plotted sweep from graph."}
	CheckBox check_BrowserSettings_OVS,userdata(tabnum)=  "1"
	CheckBox check_BrowserSettings_OVS,userdata(tabcontrol)=  "Settings"
	CheckBox check_BrowserSettings_OVS,userdata(ResizeControlsInfo)= A"!!,G<!!#>N!!#>Z!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_BrowserSettings_OVS,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_BrowserSettings_OVS,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_BrowserSettings_OVS,value= 0
	CheckBox check_BrowserSettings_AR,pos={162.00,48.00},size={51.00,15.00},disable=1,proc=BSP_CheckBoxProc_ArtRemoval,title="enable"
	CheckBox check_BrowserSettings_AR,help={"Open the artefact removal dialog"}
	CheckBox check_BrowserSettings_AR,userdata(tabnum)=  "3"
	CheckBox check_BrowserSettings_AR,userdata(tabcontrol)=  "Settings"
	CheckBox check_BrowserSettings_AR,userdata(ResizeControlsInfo)= A"!!,G6!!#>N!!#>Z!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_BrowserSettings_AR,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_BrowserSettings_AR,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_BrowserSettings_AR,value= 0
	CheckBox check_BrowserSettings_PA,pos={162.00,48.00},size={37.00,12.00},disable=1,proc=BSP_CheckBoxProc_PerPulseAver,title="enable"
	CheckBox check_BrowserSettings_PA,help={"Allows to average multiple pulses from pulse train epochs"}
	CheckBox check_BrowserSettings_PA,userdata(tabnum)=  "4"
	CheckBox check_BrowserSettings_PA,userdata(tabcontrol)=  "Settings"
	CheckBox check_BrowserSettings_PA,userdata(ResizeControlsInfo)= A"!!,G6!!#>N!!#>\"!!#;Mz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_BrowserSettings_PA,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_BrowserSettings_PA,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_BrowserSettings_PA,value= 0
	CheckBox check_BrowserSettings_DAC,pos={24.00,36.00},size={32.00,15.00},title="DA"
	CheckBox check_BrowserSettings_DAC,help={"Display the DA channel data"}
	CheckBox check_BrowserSettings_DAC,userdata(tabnum)=  "0"
	CheckBox check_BrowserSettings_DAC,userdata(tabcontrol)=  "Settings"
	CheckBox check_BrowserSettings_DAC,userdata(ResizeControlsInfo)= A"!!,CD!!#=s!!#=c!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_BrowserSettings_DAC,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_BrowserSettings_DAC,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_BrowserSettings_DAC,value= 0
	CheckBox check_BrowserSettings_ADC,pos={87.00,36.00},size={32.00,15.00},title="AD"
	CheckBox check_BrowserSettings_ADC,help={"Display the AD channels"}
	CheckBox check_BrowserSettings_ADC,userdata(tabnum)=  "0"
	CheckBox check_BrowserSettings_ADC,userdata(tabcontrol)=  "Settings"
	CheckBox check_BrowserSettings_ADC,userdata(ResizeControlsInfo)= A"!!,Ep!!#=s!!#=c!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_BrowserSettings_ADC,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_BrowserSettings_ADC,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_BrowserSettings_ADC,value= 1
	CheckBox check_BrowserSettings_TTL,pos={144.00,36.00},size={34.00,15.00},title="TTL"
	CheckBox check_BrowserSettings_TTL,help={"Display the TTL channels"}
	CheckBox check_BrowserSettings_TTL,userdata(tabnum)=  "0"
	CheckBox check_BrowserSettings_TTL,userdata(tabcontrol)=  "Settings"
	CheckBox check_BrowserSettings_TTL,userdata(ResizeControlsInfo)= A"!!,G$!!#=s!!#=k!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_BrowserSettings_TTL,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_BrowserSettings_TTL,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_BrowserSettings_TTL,value= 0
	CheckBox check_BrowserSettings_OChan,pos={24.00,60.00},size={65.00,15.00},title="Channels"
	CheckBox check_BrowserSettings_OChan,help={"Overlay the data from multiple channels in one graph"}
	CheckBox check_BrowserSettings_OChan,userdata(tabnum)=  "0"
	CheckBox check_BrowserSettings_OChan,userdata(tabcontrol)=  "Settings"
	CheckBox check_BrowserSettings_OChan,userdata(ResizeControlsInfo)= A"!!,CD!!#?)!!#?;!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_BrowserSettings_OChan,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_BrowserSettings_OChan,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_BrowserSettings_OChan,value= 0
	CheckBox check_BrowserSettings_dDAQ,pos={144.00,60.00},size={48.00,15.00},title="dDAQ"
	CheckBox check_BrowserSettings_dDAQ,help={"Enable dedicated support for viewing distributed DAQ data"}
	CheckBox check_BrowserSettings_dDAQ,userdata(tabnum)=  "0"
	CheckBox check_BrowserSettings_dDAQ,userdata(tabcontrol)=  "Settings"
	CheckBox check_BrowserSettings_dDAQ,userdata(ResizeControlsInfo)= A"!!,G$!!#?)!!#>N!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_BrowserSettings_dDAQ,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_BrowserSettings_dDAQ,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_BrowserSettings_dDAQ,value= 0
	CheckBox check_Calculation_ZeroTraces,pos={36.00,219.00},size={75.00,15.00},title="Zero Traces"
	CheckBox check_Calculation_ZeroTraces,help={"Remove the offset of all traces"}
	CheckBox check_Calculation_ZeroTraces,userdata(tabnum)=  "0"
	CheckBox check_Calculation_ZeroTraces,userdata(tabcontrol)=  "Settings"
	CheckBox check_Calculation_ZeroTraces,userdata(ResizeControlsInfo)= A"!!,D/!!#Aj!!#?O!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_Calculation_ZeroTraces,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_Calculation_ZeroTraces,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_Calculation_ZeroTraces,value= 0
	CheckBox check_Calculation_AverageTraces,pos={36.00,198.00},size={94.00,15.00},title="Average Traces"
	CheckBox check_Calculation_AverageTraces,help={"Average all traces which belong to the same y axis"}
	CheckBox check_Calculation_AverageTraces,userdata(tabnum)=  "0"
	CheckBox check_Calculation_AverageTraces,userdata(tabcontrol)=  "Settings"
	CheckBox check_Calculation_AverageTraces,userdata(ResizeControlsInfo)= A"!!,D/!!#AU!!#?u!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_Calculation_AverageTraces,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_Calculation_AverageTraces,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_Calculation_AverageTraces,value= 0
	CheckBox check_BrowserSettings_TA,pos={150.00,111.00},size={51.00,15.00},proc=BSP_TimeAlignmentProc,title="enable"
	CheckBox check_BrowserSettings_TA,help={"Activate time alignment"}
	CheckBox check_BrowserSettings_TA,userdata(tabnum)=  "0"
	CheckBox check_BrowserSettings_TA,userdata(tabcontrol)=  "Settings"
	CheckBox check_BrowserSettings_TA,userdata(ResizeControlsInfo)= A"!!,G*!!#@B!!#>Z!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_BrowserSettings_TA,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_BrowserSettings_TA,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_BrowserSettings_TA,value= 0
	CheckBox check_ovs_clear_on_new_ra_cycle,pos={231.00,161.00},size={111.00,15.00},disable=3,title="Clear on new RAC"
	CheckBox check_ovs_clear_on_new_ra_cycle,help={"Clear the list of overlayed sweeps when a new repeated acquisition cycle has begun."}
	CheckBox check_ovs_clear_on_new_ra_cycle,userdata(tabnum)=  "1"
	CheckBox check_ovs_clear_on_new_ra_cycle,userdata(tabcontrol)=  "Settings"
	CheckBox check_ovs_clear_on_new_ra_cycle,userdata(ResizeControlsInfo)= A"!!,H&!!#A0!!#@B!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_ovs_clear_on_new_ra_cycle,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_ovs_clear_on_new_ra_cycle,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_ovs_clear_on_new_ra_cycle,value= 0
	CheckBox check_ovs_clear_on_new_stimset_cycle,pos={231.00,181.00},size={105.00,15.00},disable=3,title="Clear on new SCI"
	CheckBox check_ovs_clear_on_new_stimset_cycle,help={"Clear the list of overlayed sweeps when a new simset cycle has begun."}
	CheckBox check_ovs_clear_on_new_stimset_cycle,userdata(tabnum)=  "1"
	CheckBox check_ovs_clear_on_new_stimset_cycle,userdata(tabcontrol)=  "Settings"
	CheckBox check_ovs_clear_on_new_stimset_cycle,userdata(ResizeControlsInfo)= A"!!,H&!!#AD!!#@6!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_ovs_clear_on_new_stimset_cycle,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_ovs_clear_on_new_stimset_cycle,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_ovs_clear_on_new_stimset_cycle,value= 0
	PopupMenu popup_TimeAlignment_Mode,pos={27.00,135.00},size={143.00,19.00},bodyWidth=50,disable=2,proc=BSP_TimeAlignmentPopup,title="Alignment Mode"
	PopupMenu popup_TimeAlignment_Mode,help={"Select the alignment mode"}
	PopupMenu popup_TimeAlignment_Mode,userdata(tabnum)=  "0"
	PopupMenu popup_TimeAlignment_Mode,userdata(tabcontrol)=  "Settings"
	PopupMenu popup_TimeAlignment_Mode,userdata(ResizeControlsInfo)= A"!!,C\\!!#@k!!#@s!!#<Pz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	PopupMenu popup_TimeAlignment_Mode,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu popup_TimeAlignment_Mode,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu popup_TimeAlignment_Mode,mode=1,popvalue="Level (Raising)",value= #"\"Level (Raising);Level (Falling);Min;Max\""
	SetVariable setvar_TimeAlignment_LevelCross,pos={183.00,135.00},size={48.00,18.00},disable=2,proc=BSP_TimeAlignmentLevel,title="Level"
	SetVariable setvar_TimeAlignment_LevelCross,help={"Select the level (for rising and falling alignment mode) at which traces are aligned"}
	SetVariable setvar_TimeAlignment_LevelCross,userdata(tabnum)=  "0"
	SetVariable setvar_TimeAlignment_LevelCross,userdata(tabcontrol)=  "Settings"
	SetVariable setvar_TimeAlignment_LevelCross,userdata(ResizeControlsInfo)= A"!!,GK!!#@k!!#>N!!#<Hz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	SetVariable setvar_TimeAlignment_LevelCross,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_TimeAlignment_LevelCross,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_TimeAlignment_LevelCross,limits={-inf,inf,0},value= _NUM:0
	Button button_TimeAlignment_Action,pos={204.00,159.00},size={30.00,18.00},disable=2,title="Do!"
	Button button_TimeAlignment_Action,help={"Perform the time alignment, needs the cursors A and B to have a selected feature"}
	Button button_TimeAlignment_Action,userdata(tabnum)=  "0"
	Button button_TimeAlignment_Action,userdata(tabcontrol)=  "Settings"
	Button button_TimeAlignment_Action,userdata(ResizeControlsInfo)= A"!!,G`!!#A.!!#=S!!#<Hz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	Button button_TimeAlignment_Action,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button button_TimeAlignment_Action,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	GroupBox group_SB_axes_scaling,pos={24.00,246.00},size={285.00,51.00},title="Axes Scaling"
	GroupBox group_SB_axes_scaling,userdata(tabnum)=  "0"
	GroupBox group_SB_axes_scaling,userdata(tabcontrol)=  "Settings"
	GroupBox group_SB_axes_scaling,userdata(ResizeControlsInfo)= A"!!,CD!!#B0!!#BHJ,ho0z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	GroupBox group_SB_axes_scaling,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	GroupBox group_SB_axes_scaling,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_Display_VisibleXrange,pos={36.00,270.00},size={41.00,15.00},title="Vis X"
	CheckBox check_Display_VisibleXrange,help={"Scale the y axis to the visible x data range"}
	CheckBox check_Display_VisibleXrange,userdata(tabnum)=  "0"
	CheckBox check_Display_VisibleXrange,userdata(tabcontrol)=  "Settings"
	CheckBox check_Display_VisibleXrange,userdata(ResizeControlsInfo)= A"!!,D/!!#BA!!#>2!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_Display_VisibleXrange,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_Display_VisibleXrange,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_Display_VisibleXrange,value= 0
	CheckBox check_Display_EqualYrange,pos={90.00,270.00},size={55.00,15.00},disable=2,title="Equal Y"
	CheckBox check_Display_EqualYrange,help={"Equalize the vertical axes ranges"}
	CheckBox check_Display_EqualYrange,userdata(tabnum)=  "0"
	CheckBox check_Display_EqualYrange,userdata(tabcontrol)=  "Settings"
	CheckBox check_Display_EqualYrange,userdata(ResizeControlsInfo)= A"!!,F!!!#BA!!#>j!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_Display_EqualYrange,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_Display_EqualYrange,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_Display_EqualYrange,value= 0
	CheckBox check_Display_EqualYignore,pos={150.00,270.00},size={36.00,15.00},disable=2,title="ign."
	CheckBox check_Display_EqualYignore,help={"Equalize the vertical axes ranges but ignore all traces with level crossings"}
	CheckBox check_Display_EqualYignore,userdata(tabnum)=  "0"
	CheckBox check_Display_EqualYignore,userdata(tabcontrol)=  "Settings"
	CheckBox check_Display_EqualYignore,userdata(ResizeControlsInfo)= A"!!,G*!!#BA!!#=s!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_Display_EqualYignore,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_Display_EqualYignore,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_Display_EqualYignore,value= 0
	SetVariable setvar_Display_EqualYlevel,pos={189.00,270.00},size={24.00,18.00},disable=2,proc=SB_AxisScalingLevelCross
	SetVariable setvar_Display_EqualYlevel,help={"Crossing level value for 'Equal Y ign.\""}
	SetVariable setvar_Display_EqualYlevel,userdata(tabnum)=  "0"
	SetVariable setvar_Display_EqualYlevel,userdata(tabcontrol)=  "Settings"
	SetVariable setvar_Display_EqualYlevel,userdata(ResizeControlsInfo)= A"!!,GQ!!#BA!!#=#!!#<Hz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	SetVariable setvar_Display_EqualYlevel,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_Display_EqualYlevel,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_Display_EqualYlevel,limits={-inf,inf,0},value= _NUM:0
	PopupMenu popup_TimeAlignment_Master,pos={40.00,159.00},size={134.00,19.00},bodyWidth=50,disable=2,proc=BSP_TimeAlignmentPopup,title="Reference trace"
	PopupMenu popup_TimeAlignment_Master,help={"Select the reference trace to which all other traces should be aligned to"}
	PopupMenu popup_TimeAlignment_Master,userdata(tabnum)=  "0"
	PopupMenu popup_TimeAlignment_Master,userdata(tabcontrol)=  "Settings"
	PopupMenu popup_TimeAlignment_Master,userdata(ResizeControlsInfo)= A"!!,D?!!#A.!!#@j!!#<Pz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	PopupMenu popup_TimeAlignment_Master,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu popup_TimeAlignment_Master,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu popup_TimeAlignment_Master,mode=1,popvalue="AD0",value= #"\"\""
	Button button_Calculation_RestoreData,pos={147.00,210.00},size={75.00,24.00},title="Restore"
	Button button_Calculation_RestoreData,help={"Restore the data in its pristine state without any modifications"}
	Button button_Calculation_RestoreData,userdata(tabnum)=  "0"
	Button button_Calculation_RestoreData,userdata(tabcontrol)=  "Settings"
	Button button_Calculation_RestoreData,userdata(ResizeControlsInfo)= A"!!,G'!!#Aa!!#?O!!#=#z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	Button button_Calculation_RestoreData,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button button_Calculation_RestoreData,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	Button button_BrowserSettings_Export,pos={78.00,333.00},size={99.00,24.00},proc=SB_ButtonProc_ExportTraces,title="Export Traces"
	Button button_BrowserSettings_Export,help={"Export the traces for further processing"}
	Button button_BrowserSettings_Export,userdata(tabnum)=  "0"
	Button button_BrowserSettings_Export,userdata(tabcontrol)=  "Settings"
	Button button_BrowserSettings_Export,userdata(ResizeControlsInfo)= A"!!,E^!!#B`J,hpU!!#=#z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	Button button_BrowserSettings_Export,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	Button button_BrowserSettings_Export,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	GroupBox group_timealignment,pos={24.00,87.00},size={285.00,99.00},title="Time Alignment"
	GroupBox group_timealignment,userdata(tabnum)=  "0"
	GroupBox group_timealignment,userdata(tabcontrol)=  "Settings"
	GroupBox group_timealignment,userdata(ResizeControlsInfo)= A"!!,CD!!#?g!!#BHJ,hpUz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	GroupBox group_timealignment,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	GroupBox group_timealignment,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	Slider slider_BrowserSettings_dDAQ,pos={312.00,36.00},size={56.00,300.00},disable=2
	Slider slider_BrowserSettings_dDAQ,help={"Allows to view only regions from the selected headstage (oodDAQ) resp. the selected headstage (dDAQ). Choose -1 to display all."}
	Slider slider_BrowserSettings_dDAQ,userdata(tabnum)=  "0"
	Slider slider_BrowserSettings_dDAQ,userdata(tabcontrol)=  "Settings"
	Slider slider_BrowserSettings_dDAQ,userdata(ResizeControlsInfo)= A"!!,HY!!#=s!!#>n!!#BPz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	Slider slider_BrowserSettings_dDAQ,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Slider slider_BrowserSettings_dDAQ,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	Slider slider_BrowserSettings_dDAQ,limits={-1,7,1},value= -1
	CheckBox check_SweepControl_HideSweep,pos={249.00,60.00},size={41.00,15.00},title="Hide"
	CheckBox check_SweepControl_HideSweep,help={"Hide sweep traces. Usually combined with \"Average traces\"."}
	CheckBox check_SweepControl_HideSweep,userdata(tabnum)=  "0"
	CheckBox check_SweepControl_HideSweep,userdata(tabcontrol)=  "Settings"
	CheckBox check_SweepControl_HideSweep,userdata(ResizeControlsInfo)= A"!!,H8!!#?)!!#>2!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_SweepControl_HideSweep,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_SweepControl_HideSweep,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_SweepControl_HideSweep,value= 0
	CheckBox check_BrowserSettings_splitTTL,pos={249.00,36.00},size={58.00,15.00},title="sep. TTL"
	CheckBox check_BrowserSettings_splitTTL,help={"Display the TTL channel data as single traces for each TTL bit"}
	CheckBox check_BrowserSettings_splitTTL,userdata(tabnum)=  "0"
	CheckBox check_BrowserSettings_splitTTL,userdata(tabcontrol)=  "Settings"
	CheckBox check_BrowserSettings_splitTTL,userdata(ResizeControlsInfo)= A"!!,H8!!#=s!!#?!!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_BrowserSettings_splitTTL,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_BrowserSettings_splitTTL,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_BrowserSettings_splitTTL,value= 0
	PopupMenu popup_DB_lockedDevices,pos={20.00,303.00},size={205.00,19.00},bodyWidth=100,proc=DB_PopMenuProc_LockDBtoDevice,title="Device assignment:"
	PopupMenu popup_DB_lockedDevices,help={"Select a data acquistion device to display data"}
	PopupMenu popup_DB_lockedDevices,userdata(tabnum)=  "0"
	PopupMenu popup_DB_lockedDevices,userdata(tabcontrol)=  "Settings"
	PopupMenu popup_DB_lockedDevices,userdata(ResizeControlsInfo)= A"!!,C$!!#BQJ,hr2!!#<Pz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	PopupMenu popup_DB_lockedDevices,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu popup_DB_lockedDevices,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu popup_DB_lockedDevices,mode=2,popvalue="- none -",value= #"DB_GetAllDevicesWithData()"
	GroupBox group_sweepFormula,pos={3.00,27.00},size={385.00,374.00},disable=1,title="SweepFormula"
	GroupBox group_sweepFormula,userdata(tabnum)=  "5"
	GroupBox group_sweepFormula,userdata(tabcontrol)=  "Settings"
	GroupBox group_sweepFormula,userdata(ResizeControlsInfo)= A"!!,>M!!#=;!!#C)!!#BuJ,fQL!!#](Aon#azzzzzzzzzzzzzz!!#o2B4uAeBk2=!z"
	GroupBox group_sweepFormula,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	GroupBox group_sweepFormula,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_sweepFormula_parseResult,pos={118.00,377.00},size={255.00,18.00},disable=1,title="◀"
	SetVariable setvar_sweepFormula_parseResult,help={"Error Message from Formula Parsing"}
	SetVariable setvar_sweepFormula_parseResult,userdata(tabnum)=  "5"
	SetVariable setvar_sweepFormula_parseResult,userdata(tabcontrol)=  "Settings"
	SetVariable setvar_sweepFormula_parseResult,userdata(ResizeControlsInfo)= A"!!,FQ!!#C\"!!#B9!!#<Hz!!#](Aon#azzzzzzzzzzzzzz!!#](Aon#SBk2=!z"
	SetVariable setvar_sweepFormula_parseResult,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#?(FEDG<zzzzzzzzzzz"
	SetVariable setvar_sweepFormula_parseResult,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_sweepFormula_parseResult,frame=0
	SetVariable setvar_sweepFormula_parseResult,limits={-inf,inf,0},value= _STR:"",noedit= 1,live= 1
	ValDisplay status_sweepFormula_parser,pos={369.00,380.00},size={10.00,8.00},bodyWidth=10,disable=1
	ValDisplay status_sweepFormula_parser,help={"Current parsing status of the entered formula."}
	ValDisplay status_sweepFormula_parser,userdata(tabnum)=  "5"
	ValDisplay status_sweepFormula_parser,userdata(tabcontrol)=  "Settings"
	ValDisplay status_sweepFormula_parser,userdata(ResizeControlsInfo)= A"!!,I\"!!#C#J,hkX!!#:bz!!#o2B4uAezzzzzzzzzzzzzz!!#o2B4uAeBk2=!z"
	ValDisplay status_sweepFormula_parser,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#?(FEDG<zzzzzzzzzzz"
	ValDisplay status_sweepFormula_parser,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	ValDisplay status_sweepFormula_parser,limits={-1,1,0},barmisc={0,0},mode= 1,highColor= (0,65535,0),lowColor= (0,0,0),zeroColor= (65535,0,0)
	ValDisplay status_sweepFormula_parser,value= #"1"
	Button button_sweepFormula_display,pos={4.00,374.00},size={55.00,22.00},disable=1,proc=SF_button_sweepFormula_display,title="Display"
	Button button_sweepFormula_display,userdata(tabnum)=  "5"
	Button button_sweepFormula_display,userdata(tabcontrol)=  "Settings"
	Button button_sweepFormula_display,userdata(ResizeControlsInfo)= A"!!,?8!!#BuJ,ho@!!#<hz!!#](Aon#azzzzzzzzzzzzzz!!#](Aon#SBk2=!z"
	Button button_sweepFormula_display,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#?(FEDG<zzzzzzzzzzz"
	Button button_sweepFormula_display,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	Button button_sweepFormula_check,pos={61.00,374.00},size={55.00,22.00},disable=1,proc=SF_button_sweepFormula_check,title="Check"
	Button button_sweepFormula_check,userdata(tabnum)=  "5"
	Button button_sweepFormula_check,userdata(tabcontrol)=  "Settings"
	Button button_sweepFormula_check,userdata(ResizeControlsInfo)= A"!!,E.!!#BuJ,ho@!!#<hz!!#](Aon#azzzzzzzzzzzzzz!!#](Aon#SBk2=!z"
	Button button_sweepFormula_check,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#?(FEDG<zzzzzzzzzzz"
	Button button_sweepFormula_check,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	TabControl SF_InfoTab,pos={7.00,46.00},size={376.00,323.00},disable=1,proc=ACL_DisplayTab
	TabControl SF_InfoTab,userdata(finalhook)=  "SF_TabProc_Formula"
	TabControl SF_InfoTab,userdata(currenttab)=  "2",userdata(tabnum)=  "5"
	TabControl SF_InfoTab,userdata(tabcontrol)=  "Settings"
	TabControl SF_InfoTab,userdata(ResizeControlsInfo)= A"!!,@C!!#>F!!#C$J,hs2z!!#](Aon#azzzzzzzzzzzzzz!!#o2B4uAeBk2=!z"
	TabControl SF_InfoTab,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	TabControl SF_InfoTab,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	TabControl SF_InfoTab,tabLabel(0)="Formula",tabLabel(1)="JSON"
	TabControl SF_InfoTab,tabLabel(2)="Help",value= 2
	ListBox list_dashboard,pos={3.00,90.00},size={380.00,311.00},disable=1,proc=AD_ListBoxProc
	ListBox list_dashboard,userdata(tabnum)=  "7",userdata(tabcontrol)=  "Settings"
	ListBox list_dashboard,userdata(ResizeControlsInfo)= A"!!,>M!!#?m!!#C&J,hs,z!!#](Aon\"Qzzzzzzzzzzzzzz!!#o2B4uAezz"
	ListBox list_dashboard,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	ListBox list_dashboard,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	ListBox list_dashboard,fSize=12,mode= 1,selRow= -1,widths={141,109,77}
	ListBox list_dashboard,userColumnResize= 1
	GroupBox group_enable_dashboard,pos={3.00,27.00},size={383.00,57.00},disable=1
	GroupBox group_enable_dashboard,userdata(tabnum)=  "7"
	GroupBox group_enable_dashboard,userdata(tabcontrol)=  "Settings"
	GroupBox group_enable_dashboard,userdata(ResizeControlsInfo)= A"!!,>M!!#=;!!#C(!!#>rz!!#](Aon\"Qzzzzzzzzzzzzzz!!#o2B4uAezz"
	GroupBox group_enable_dashboard,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	GroupBox group_enable_dashboard,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_BrowserSettings_DB_Passed,pos={171.00,39.00},size={36.00,12.00},disable=1,proc=AD_CheckProc_PassedSweeps,title="Passed"
	CheckBox check_BrowserSettings_DB_Passed,help={"Show passed sweeps on double click into ListBox "}
	CheckBox check_BrowserSettings_DB_Passed,userdata(tabnum)=  "7"
	CheckBox check_BrowserSettings_DB_Passed,userdata(tabcontrol)=  "Settings"
	CheckBox check_BrowserSettings_DB_Passed,userdata(ResizeControlsInfo)= A"!!,G?!!#>*!!#=s!!#;Mz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_BrowserSettings_DB_Passed,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_BrowserSettings_DB_Passed,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_BrowserSettings_DB_Passed,value= 0
	CheckBox check_BrowserSettings_DB_Failed,pos={171.00,60.00},size={33.00,12.00},disable=1,proc=AD_CheckProc_FailedSweeps,title="Failed"
	CheckBox check_BrowserSettings_DB_Failed,help={"Show failed sweeps on double click into ListBox "}
	CheckBox check_BrowserSettings_DB_Failed,userdata(tabnum)=  "7"
	CheckBox check_BrowserSettings_DB_Failed,userdata(tabcontrol)=  "Settings"
	CheckBox check_BrowserSettings_DB_Failed,userdata(ResizeControlsInfo)= A"!!,G?!!#?)!!#=g!!#;Mz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_BrowserSettings_DB_Failed,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_BrowserSettings_DB_Failed,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_BrowserSettings_DB_Failed,value= 0
	DefineGuide UGVL={FL,15},UGVR={FR,-20},UGVT={FT,75},UGVB={FB,-50}
	SetWindow kwTopWin,hook(ResizeControls)=ResizeControls#ResizeControlsHook
	SetWindow kwTopWin,userdata(ResizeControlsInfo)= A"!!*'\"z!!#C,!!#C0J,fQLzzzzzzzzzzzzzzzzzzzz"
	SetWindow kwTopWin,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzzzzzzzzzzzzzzz"
	SetWindow kwTopWin,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzzzzzzzzz!!!"
	SetWindow kwTopWin,userdata(ResizeControlsGuides)=  "UGVL;UGVR;UGVT;UGVB;"
	SetWindow kwTopWin,userdata(ResizeControlsInfoUGVL)=  "NAME:UGVL;WIN:DB_ITC18USB_Dev_0#BrowserSettingsPanel;TYPE:User;HORIZONTAL:0;POSITION:15.00;GUIDE1:FL;GUIDE2:;RELPOSITION:15;"
	SetWindow kwTopWin,userdata(ResizeControlsInfoUGVR)=  "NAME:UGVR;WIN:DB_ITC18USB_Dev_0#BrowserSettingsPanel;TYPE:User;HORIZONTAL:0;POSITION:378.00;GUIDE1:FR;GUIDE2:;RELPOSITION:-20;"
	SetWindow kwTopWin,userdata(ResizeControlsInfoUGVT)=  "NAME:UGVT;WIN:DB_ITC18USB_Dev_0#BrowserSettingsPanel;TYPE:User;HORIZONTAL:1;POSITION:75.00;GUIDE1:FT;GUIDE2:;RELPOSITION:75;"
	SetWindow kwTopWin,userdata(ResizeControlsInfoUGVB)=  "NAME:UGVB;WIN:DB_ITC18USB_Dev_0#BrowserSettingsPanel;TYPE:User;HORIZONTAL:1;POSITION:357.00;GUIDE1:FB;GUIDE2:;RELPOSITION:-50;"
	Execute/Q/Z "SetWindow kwTopWin sizeLimit={305.25,330,inf,inf}" // sizeLimit requires Igor 7 or later
	NewNotebook /F=0 /N=sweepFormula_json /W=(12,71,378,358)/FG=(UGVL,UGVT,UGVR,UGVB) /HOST=# /V=0 /OPTS=12
	Notebook kwTopWin, defaultTab=20, autoSave= 0, magnification=100, writeProtect=1
	Notebook kwTopWin font="Lucida Console", fSize=11, fStyle=0, textRGB=(0,0,0)
	SetWindow kwTopWin,hook(ResizeControls)=ResizeControls#ResizeControlsHook
	SetWindow kwTopWin,userdata(tabnum)=  "1"
	SetWindow kwTopWin,userdata(tabcontrol)=  "SF_InfoTab"
	SetWindow kwTopWin,userdata(ResizeControlsInfo)= A"!!,@C!!#>F!!#C#!!#B[J,fQL!!#](Aon#azzzzzzzzzzzzzz!!#o2B4uAeBk2=!z"
	SetWindow kwTopWin,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetWindow kwTopWin,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	RenameWindow #,sweepFormula_json
	SetActiveSubwindow ##
	NewNotebook /F=0 /N=sweepFormula_formula /W=(12,71,378,358)/FG=(UGVL,UGVT,UGVR,UGVB) /HOST=# /V=0
	Notebook kwTopWin, defaultTab=20, autoSave= 1, magnification=100
	Notebook kwTopWin font="Lucida Console", fSize=11, fStyle=0, textRGB=(0,0,0)
	Notebook kwTopWin, zdata= "GaqDU%ejN7!Z)t;B7Kt/+?%qo07\\UEOHN_/W54s.>#_#!<35&Wj.rZlS\",V.Q^=-CjLP>:`T=(u\"iVAaeqVaFf#H8feu\"nKRK/mk'D2"
	Notebook kwTopWin, zdataEnd= 1
	SetWindow kwTopWin,hook(ResizeControls)=ResizeControls#ResizeControlsHook
	SetWindow kwTopWin,userdata(tabnum)=  "0"
	SetWindow kwTopWin,userdata(tabcontrol)=  "SF_InfoTab"
	SetWindow kwTopWin,userdata(ResizeControlsInfo)= A"!!,@C!!#>F!!#C#!!#B[J,fQL!!#](Aon#azzzzzzzzzzzzzz!!#o2B4uAeBk2=!z"
	SetWindow kwTopWin,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetWindow kwTopWin,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	RenameWindow #,sweepFormula_formula
	SetActiveSubwindow ##
	NewNotebook /F=1 /N=sweepFormula_help /W=(12,71,378,358)/FG=(UGVL,UGVT,UGVR,UGVB) /HOST=# /V=0
	Notebook kwTopWin, defaultTab=36, autoSave= 1, magnification=100, showRuler=0, rulerUnits=2
	Notebook kwTopWin newRuler=Normal, justification=0, margins={0,0,245}, spacing={0,0,0}, tabs={}, rulerDefaults={"Arial",11,0,(0,0,0)}
	Notebook kwTopWin, zdata= "Gb!Smc#;CW'rPlgQK,nTS03S(2$RcVXt\"1_Q\"=/+>+fn82[U2PW9ONM@KFf<Zb(l^%PoojLOlnJ(Bk0<g0B!jhpDBGaLsO'ndk@rot<:0Qb/cq7AGX4\"EqoKHh6cVo6VQ8)sXW@nDN#Sc]]<>[flGHn4C'<I+^UA[8d#U0+B!,*s8.!pH7ofl^mhbT\"g&-([`B^+<SCDbD!Y@cWb@<I)Gs'qj$?'H-X$VA%qAVVl*2WZ$/8?P^oDRZ#-Y*j?Y+,2j$eA9.0=K_tS'rJf,:D6p,(edUuek[d(1VTDd8PlWj^0"
	Notebook kwTopWin, zdata= "a7M,$UF6j#)bJ\"n*&E&ZUR2R%O@4pr[;DIh9H<O]k=2[@`d*`Q+kIq)Oqi49kAd'L/:#]'+#\\6+QHi*/,>!ruZ6&m'lYd8j&aK=#X*\"2$Irdl$r_8aA4/>GOX8SOe(?o`4[p?S;eoaR;n)\"1HC=DXRhXia.Do'%BO5nbBT5LKIbJ-tHkl&<IJ(OBi\"8LA1Ne8SOrB(\"%dF2sI[fJ.jrSFEXQc7%Z99O]*/$;S\\_\"us3e\"EM[4BiSBc)s;EV6oRq5GH^FAotH^XVi.VKZR6:%+#Mk7nK;:,'oP\"p^)UPr4)'s"
	Notebook kwTopWin, zdata= "l?pL<jbD'G(+d%'g<c8(HNbS4hdr:'s#4a5Iai)?>?T%dX49b1TX78Ubt?//&P60.mcu.W#@e.Bi2P7q?'c\"(Qb!q7+p<1MNf.\\j%j3-V`IDA\\?>Heef?2cj!*0']F-,ZdRXJ(f-.qc=-h0D>'Q)gbFuoia,)MK2=CCb[3<VT+MBAL'U8Qp`6>sSX*QBn/\\9N2#g=[d`'6:ul>$:PW8Ii7fGT$ikH>Pugi3M_k0r1d1a-.AEI%_!3E>:gWJD>`R`Pn<X#B-*Zqs:8o0k4>iNJ!.f7u\"YZI[6OO@n;.]Q\"45N"
	Notebook kwTopWin, zdata= "SjDLT(H$&a%L&Y75j,r)/\"\\Th,E5j8e71s7VB(YL&ug^!INH[S$rf=<Y3^JN&V85fk?E#6>`@m)Ql;ejN1mfoNpQ72>DW?=ii.l'<pBa#fO8;;9Vbd!5Y[AqCRG;[)s9QR-ll5t_F?uR.^FqS50X`@-]pEfKATNf-r$cs9!d<W6O7VAbOu@&m-=YZL!$n\\\"S<E%+fL/V_2jI-'AFbTP_?Rn3,'\\V493tTaZ,TACO*oh0t5?S5ijX.\"M\\fY/oT$Eq@XdV*WT5l\\VF(NM.9ib8-]0ul*4)\"__]In=F-%\"p\\''\\"
	Notebook kwTopWin, zdata= "7S5#/EX@[+4@$DhaP\"GI?d-iWD\"JSFqiGUl8T*U&[$Q7<e7XtY4IL[H's(\\&7$^DbKOq42%Q+1KrO+tdd\"+KMJYKVF5>KE(2Pl-qE<?IX+X(CU1QZTK6*uLd#dD>&V2*u/jn?(&G2h3Ip1>'37RQA+(@-\"KNm\\@)RaDS\\R>i%r)rn5`cGC\\:cH,c.b.+8Pj<@-p@;&LkiA4$BR\\Ku-,F1qK!E@%R`?@DfOhp]H,rC9RTCAH:j:G@GNJ1e,/0KMuI1L(P+Xj/8jlj9b@PbVJ[e\\4-c%K9Xa8YK#K@'s8p3B`X"
	Notebook kwTopWin, zdata= ",g=`Y%,a064K_<uGVOSII?Le\"^#JaGk:m.T%?g@2FuY=fS)nWX`(MAD3G-1h;Vc'cAI!GAFl%!!ghQ&#e=&D6KVtf*[>R'&&T^PRFA\\uU0i5+hp^j_t@cNl2SZua(RO:HnnT3rL#D't#1\"LHaa=+3OCFR:DB=+ilqns('Mk_YOmHbIs]/qpeEL99PN)H/:TP6,%kk-XR<':r!0rt`:e)o?KWYb%:8jk_P4&.tFS^lHIh.RU1Im8iQn7W^k_(&!_JZXjXqL61U]FThoV=jT)pqc4q\\B#,Kn62Ee*-!mQ(CR`l"
	Notebook kwTopWin, zdata= "hpM_,9@cH@Kufe.H=gY\"a\\,rkEEXVb+CVtA$%n6=P/XZc0&i)&q.lDQ+;SaLRFMLjSrRSsMc+Bp%hTmF#j`\"oO$F#O!jNj7ZLMB3)rI^LfV)HrZUJ389Kio+V584o;f*C\\jYkK:%L%k0V3j\"E(=#LoJ:nBJ:b[LeBJ\"jm?mSmK1+lX1*j`JG4,)B)`W-J?6OkYf`i;\\6CTh4(Sc6pgB7j2#1@NHNmJ(m,fE!t=J%$/MYLj1%dXd<thc+65W);SI=jF#S_0oS0HVu/oB`eDH0ih01;>T5fHb\\?K3YOe9!ai>5"
	Notebook kwTopWin, zdata= "@1]LB8s#[Mnn@&f)jQ[/lO_!_^[R7=C6ZIb5@;XS]&\\'7^\"(?opMDjA1=cj<<L$RA8u<?PQn.>rB-o:QggJJ0nAe/`))-(jS\\,WD.uei2B^#AiTsNSW=mLcK_N%a\\m<5EEm0NkIKYr-Y<m7$D;jn/l!lr2f$2Kc*RgBd\"82YCO6.XMdW1RMu+u0\"R_q>=oHsS\\rMU.3/$4L37UPbp9JH7XH]E#.8,OT9M3-k5LP@oA,H1l(uPfbkE`<cKWMGm\"afJu94VN&g`-F*gJR74U:m<7s-M?gR1j@e[9N$tQd'SpXN"
	Notebook kwTopWin, zdata= "URZ2(<Tt*q&PH_&^?6'k.#DE9:dKq+*`2h=T?u6o:TtsZ\"Ab[_rR`jj='D9:VKUn>*?E5u>K(:sS`IVj<leMg8M%ml>lIL.J.,%u3X3BR+%6MLS:Jkr.-e3DUoR=tEAU7k>_=VZ4UK1PlP*uZZs<ZPjZ3VTM[$.?1/k?@-Odf.;%?E3QjL_c+-.\"=aQl\\/`>loe)qb4nSQVu;q;A(^ND?\\=rnq8=ZFAdXnn1lM\"8d&O(5G]h4G:Z#_*<6JDdrsZl=1)]AjWEkOjUTalSdqkH2\"!O*d\\8JX7(?6>-,$f.fWX5"
	Notebook kwTopWin, zdata= "rI[bSjLn00r/\\\"+rG_ako8gT*2=5J(It,WuVgk>1ro:lN^OcFbf69kigN_RH@6!-65LgB62jXJjf7T=CGuk21\"p\"3n>;/6=0meCZ9Vt$\\?\\d8];QRPVP8hmi\"/5<p2j3K/0<Nj,Wp[eNnb]ESs#fYSs6P1&mAL;hrHTGP+_RFg<6JBg?g$cWdS.G`*pp4\\fHS8]G[cOjiKV\"T!.UO\\NW"
	Notebook kwTopWin, zdataEnd= 1
	SetWindow kwTopWin,hook(ResizeControls)=ResizeControls#ResizeControlsHook
	SetWindow kwTopWin,userdata(tabnum)=  "2"
	SetWindow kwTopWin,userdata(tabcontrol)=  "SF_InfoTab"
	SetWindow kwTopWin,userdata(ResizeControlsInfo)= A"!!,@C!!#>F!!#C#!!#B[J,fQL!!#](Aon#azzzzzzzzzzzzzz!!#o2B4uAeBk2=!z"
	SetWindow kwTopWin,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetWindow kwTopWin,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	RenameWindow #,sweepFormula_help
	SetActiveSubwindow ##
	NewNotebook /F=0 /N=WaveNoteDisplay /W=(200,24,600,561)/FG=(FL,$"",FR,FB) /HOST=# /V=0 /OPTS=10 
	Notebook kwTopWin, defaultTab=36, autoSave= 0, magnification=100
	Notebook kwTopWin font="Lucida Console", fSize=11, fStyle=0, textRGB=(0,0,0)
	SetWindow kwTopWin,hook(ResizeControls)=ResizeControls#ResizeControlsHook
	SetWindow kwTopWin,userdata(tabnum)=  "6"
	SetWindow kwTopWin,userdata(tabcontrol)=  "Settings"
	SetWindow kwTopWin,userdata(ResizeControlsInfo)= A"!!,@C!!#>F!!#C#!!#B[J,fQL!!#](Aon#azzzzzzzzzzzzzz!!#o2B4uAeBk2=!z"
	SetWindow kwTopWin,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetWindow kwTopWin,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	RenameWindow #,WaveNoteDisplay
	SetActiveSubwindow ##
	RenameWindow #,BrowserSettingsPanel
	SetActiveSubwindow ##
	NewPanel/HOST=#/EXT=2/W=(0,0,580,147)  as " "
	ModifyPanel fixedSize=0
	PopupMenu popup_LBNumericalKeys,pos={408.00,26.00},size={150.00,19.00},bodyWidth=150,proc=DB_PopMenuProc_LabNotebook
	PopupMenu popup_LBNumericalKeys,help={"Select numeric lab notebook data to display"}
	PopupMenu popup_LBNumericalKeys,userdata(ResizeControlsInfo)= A"!!,I3J,hm^!!#A%!!#<Pz!!#N3Bk1ct<C^(Dzzzzzzzzzzzzz!!#N3Bk1ct<C^(Dz"
	PopupMenu popup_LBNumericalKeys,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:DuaGl<C]S6zzzzzzzzzz"
	PopupMenu popup_LBNumericalKeys,userdata(ResizeControlsInfo) += A"zzz!!#u:DuaGl<C]S6zzzzzzzzzzzzz!!!"
	PopupMenu popup_LBNumericalKeys,mode=1,popvalue="- none -",value= #"\"- none -\""
	PopupMenu popup_LBTextualKeys,pos={408.00,55.00},size={150.00,19.00},bodyWidth=150,proc=DB_PopMenuProc_LabNotebook
	PopupMenu popup_LBTextualKeys,help={"Select textual lab notebook data to display"}
	PopupMenu popup_LBTextualKeys,userdata(ResizeControlsInfo)= A"!!,I3J,ho@!!#A%!!#<Pz!!#N3Bk1ct<C^(Dzzzzzzzzzzzzz!!#N3Bk1ct<C^(Dz"
	PopupMenu popup_LBTextualKeys,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:DuaGl<C]S6zzzzzzzzzz"
	PopupMenu popup_LBTextualKeys,userdata(ResizeControlsInfo) += A"zzz!!#u:DuaGl<C]S6zzzzzzzzzzzzz!!!"
	PopupMenu popup_LBTextualKeys,mode=1,popvalue="- none -",value= #"\"- none -\""
	Button button_clearlabnotebookgraph,pos={399.00,85.00},size={80.00,25.00},proc=DB_ButtonProc_ClearGraph,title="Clear graph"
	Button button_clearlabnotebookgraph,userdata(ResizeControlsInfo)= A"!!,I/!!#?c!!#?Y!!#=+z!!#N3Bk1ct<C^(Dzzzzzzzzzzzzz!!#N3Bk1ct<C^(Dz"
	Button button_clearlabnotebookgraph,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:DuaGl<C]S6zzzzzzzzzz"
	Button button_clearlabnotebookgraph,userdata(ResizeControlsInfo) += A"zzz!!#u:DuaGl<C]S6zzzzzzzzzzzzz!!!"
	Button button_switchxaxis,pos={491.00,85.00},size={80.00,25.00},proc=DB_ButtonProc_SwitchXAxis,title="Switch X-axis"
	Button button_switchxaxis,help={"Toggle lab notebook horizontal axis between time of day or sweep number"}
	Button button_switchxaxis,userdata(ResizeControlsInfo)= A"!!,I]!!#?c!!#?Y!!#=+z!!#N3Bk1ct<C^(Dzzzzzzzzzzzzz!!#N3Bk1ct<C^(Dz"
	Button button_switchxaxis,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:DuaGl<C]S6zzzzzzzzzz"
	Button button_switchxaxis,userdata(ResizeControlsInfo) += A"zzz!!#u:DuaGl<C]S6zzzzzzzzzzzzz!!!"
	GroupBox group_labnotebook_ctrls,pos={400.00,5.00},size={170.00,78.00},title="Settings History Column"
	GroupBox group_labnotebook_ctrls,userdata(ResizeControlsInfo)= A"!!,I/J,hj-!!#A9!!#?Uz!!#N3Bk1ct<C^(Dzzzzzzzzzzzzz!!#N3Bk1ct<C^(Dz"
	GroupBox group_labnotebook_ctrls,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:DuaGl<C]S6zzzzzzzzzz"
	GroupBox group_labnotebook_ctrls,userdata(ResizeControlsInfo) += A"zzz!!#u:DuaGl<C]S6zzzzzzzzzzzzz!!!"
	Button button_DataBrowser_setaxis,pos={398.00,114.00},size={171.00,25.00},proc=DB_ButtonProc_AutoScale,title="Autoscale"
	Button button_DataBrowser_setaxis,help={"Autoscale sweep data"}
	Button button_DataBrowser_setaxis,userdata(ResizeControlsInfo)= A"!!,I.J,hps!!#A:!!#=+z!!#N3Bk1ct<C^(Dzzzzzzzzzzzzz!!#N3Bk1ct<C^(Dz"
	Button button_DataBrowser_setaxis,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	Button button_DataBrowser_setaxis,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	DefineGuide UGV0={FR,-187}
	SetWindow kwTopWin,hook(ResizeControls)=ResizeControls#ResizeControlsHook
	SetWindow kwTopWin,userdata(ResizeControlsInfo)= A"!!*'\"z!!#D!^]6_8zzzzzzzzzzzzzzzzzzzzz"
	SetWindow kwTopWin,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzzzzzzzzzzzzzzz"
	SetWindow kwTopWin,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzzzzzzzzz!!!"
	SetWindow kwTopWin,userdata(ResizeControlsGuides)=  "UGV0;"
	SetWindow kwTopWin,userdata(ResizeControlsInfoUGV0)=  "NAME:UGV0;WIN:SettingsHistory;TYPE:User;HORIZONTAL:0;POSITION:396.00;GUIDE1:FR;GUIDE2:;RELPOSITION:-187;"
	Execute/Q/Z "SetWindow kwTopWin sizeLimit={447,135,inf,inf}" // sizeLimit requires Igor 7 or later
	Display/W=(200,187,395,501)/FG=(FL,FT,UGV0,FB)/HOST=# 
	ModifyGraph margin(right)=74
	TextBox/C/N=text0/F=0/B=1/X=0.50/Y=2.02/E=2 ""
	RenameWindow #,LabNoteBook
	SetActiveSubwindow ##
	RenameWindow #,SettingsHistoryPanel
	SetActiveSubwindow ##
EndMacro
