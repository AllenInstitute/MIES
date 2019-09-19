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
	Display /W=(372,276.5,804.75,581.75)/K=1  as "DataBrowser"
	Button button_BSP_open,pos={3.00,3.00},size={24.00,24.00},disable=1,proc=DB_ButtonProc_Panel,title="<<"
	Button button_BSP_open,help={"Open Side Panel"}
	Button button_BSP_open,userdata(ResizeControlsInfo)= A"!!,>M!!#8L!!#=#!!#=#z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_BSP_open,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button button_BSP_open,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetDrawLayer UserBack
	SetDrawEnv linethick= 2,linefgc= (65535,0,0),dash= 3
	SetDrawEnv save
	SetDrawEnv fillpat= 0
	SetDrawEnv save
	SetDrawEnv xcoord= abs,ycoord= abs
	SetDrawEnv save
	DrawRect -1,-1,31,31
	SetDrawEnv gstop
	SetDrawLayer UserFront
	SetDrawEnv gstart,gname= ResizeControlsIndicator
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
	NewPanel/HOST=#/EXT=1/W=(398,0,0,407)  as " "
	ModifyPanel fixedSize=0
	ShowTools/A
	SetDrawLayer UserBack
	GroupBox group_calc,pos={28.00,195.00},size={288.00,51.00}
	GroupBox group_calc,userdata(tabnum)=  "0",userdata(tabcontrol)=  "Settings"
	GroupBox group_calc,userdata(ResizeControlsInfo)= A"!!,C<!!#AR!!#BJ!!#>Zz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	GroupBox group_calc,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	GroupBox group_calc,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	TabControl Settings,pos={0.00,0.00},size={399.00,21.00},proc=ACL_DisplayTab
	TabControl Settings,userdata(currenttab)=  "0"
	TabControl Settings,userdata(ResizeControlsInfo)= A"!!*'\"z!!#C+!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#o2B4uAeBE3-fz"
	TabControl Settings,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	TabControl Settings,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	TabControl Settings,tabLabel(0)="Settings",tabLabel(1)="OVS",tabLabel(2)="CS"
	TabControl Settings,tabLabel(3)="AR",tabLabel(4)="PA",tabLabel(5)="SF"
	TabControl Settings,tabLabel(6)="Note",tabLabel(7)="Dashboard",value= 0
	ListBox list_of_ranges,pos={81.00,198.00},size={222.00,202.00},disable=3,proc=OVS_MainListBoxProc
	ListBox list_of_ranges,help={"Select sweeps for overlay; The second column (\"Headstages\") allows to ignore some headstages for the graphing. Syntax is a semicolon \";\" separated list of subranges, e.g. \"0\", \"0,2\", \"1;4;2\""}
	ListBox list_of_ranges,userdata(tabnum)=  "1",userdata(tabcontrol)=  "Settings"
	ListBox list_of_ranges,userdata(ResizeControlsInfo)= A"!!,E\\!!#AU!!#Aj!!#AXz!!#](Aon\"Qzzzzzzzzzzzzzz!!#o2B4uAezz"
	ListBox list_of_ranges,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	ListBox list_of_ranges,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	ListBox list_of_ranges,widths={50,50}
	PopupMenu popup_overlaySweeps_select,pos={123.00,99.00},size={143.00,19.00},bodyWidth=109,disable=3,proc=OVS_PopMenuProc_Select,title="Select"
	PopupMenu popup_overlaySweeps_select,help={"Select sweeps according to various properties"}
	PopupMenu popup_overlaySweeps_select,userdata(tabnum)=  "1"
	PopupMenu popup_overlaySweeps_select,userdata(tabcontrol)=  "Settings"
	PopupMenu popup_overlaySweeps_select,userdata(ResizeControlsInfo)= A"!!,FY!!#@*!!#@s!!#<Pz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	PopupMenu popup_overlaySweeps_select,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu popup_overlaySweeps_select,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu popup_overlaySweeps_select,mode=1,popvalue="- none -",value= #"\"\""
	CheckBox check_overlaySweeps_disableHS,pos={72.00,159.00},size={121.00,15.00},disable=3,proc=OVS_CheckBoxProc_HS_Select,title="Headstage Removal"
	CheckBox check_overlaySweeps_disableHS,help={"Toggle headstage removal"}
	CheckBox check_overlaySweeps_disableHS,userdata(tabnum)=  "1"
	CheckBox check_overlaySweeps_disableHS,userdata(tabcontrol)=  "Settings"
	CheckBox check_overlaySweeps_disableHS,userdata(ResizeControlsInfo)= A"!!,EH!!#A.!!#@V!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_overlaySweeps_disableHS,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_overlaySweeps_disableHS,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_overlaySweeps_disableHS,value= 0
	CheckBox check_overlaySweeps_non_commula,pos={72.00,180.00},size={154.00,15.00},disable=3,title="Non-commulative update"
	CheckBox check_overlaySweeps_non_commula,help={"If \"Display Last sweep acquired\" is checked, this checkbox here allows to only add the newly acquired sweep and will remove the currently added last sweep."}
	CheckBox check_overlaySweeps_non_commula,userdata(tabcontrol)=  "Settings"
	CheckBox check_overlaySweeps_non_commula,userdata(tabnum)=  "1"
	CheckBox check_overlaySweeps_non_commula,userdata(ResizeControlsInfo)= A"!!,EH!!#AC!!#A)!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_overlaySweeps_non_commula,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_overlaySweeps_non_commula,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_overlaySweeps_non_commula,value= 0
	SetVariable setvar_overlaySweeps_offset,pos={110.00,126.00},size={81.00,18.00},bodyWidth=45,disable=3,proc=OVS_SetVarProc_SelectionRange,title="Offset"
	SetVariable setvar_overlaySweeps_offset,help={"Offsets the first selected sweep from the selection menu"}
	SetVariable setvar_overlaySweeps_offset,userdata(tabnum)=  "1"
	SetVariable setvar_overlaySweeps_offset,userdata(tabcontrol)=  "Settings"
	SetVariable setvar_overlaySweeps_offset,userdata(ResizeControlsInfo)= A"!!,F?!!#@`!!#?[!!#<Hz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	SetVariable setvar_overlaySweeps_offset,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_overlaySweeps_offset,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_overlaySweeps_offset,limits={0,inf,1},value= _NUM:0
	SetVariable setvar_overlaySweeps_step,pos={197.00,126.00},size={72.00,18.00},bodyWidth=45,disable=3,proc=OVS_SetVarProc_SelectionRange,title="Step"
	SetVariable setvar_overlaySweeps_step,help={"Selects every `step` sweep from the selection menu"}
	SetVariable setvar_overlaySweeps_step,userdata(tabnum)=  "1"
	SetVariable setvar_overlaySweeps_step,userdata(tabcontrol)=  "Settings"
	SetVariable setvar_overlaySweeps_step,userdata(ResizeControlsInfo)= A"!!,GT!!#@`!!#?I!!#<Hz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	SetVariable setvar_overlaySweeps_step,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_overlaySweeps_step,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_overlaySweeps_step,limits={1,inf,1},value= _NUM:1
	GroupBox group_enable_sweeps,pos={3.00,30.00},size={390.00,51.00},disable=1,title="Overlay Sweeps"
	GroupBox group_enable_sweeps,userdata(tabnum)=  "1"
	GroupBox group_enable_sweeps,userdata(tabcontrol)=  "Settings"
	GroupBox group_enable_sweeps,userdata(ResizeControlsInfo)= A"!!,>M!!#=S!!#C&J,ho0z!!#](Aon\"Qzzzzzzzzzzzzzz!!#o2B4uAezz"
	GroupBox group_enable_sweeps,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	GroupBox group_enable_sweeps,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	GroupBox group_enable_channels,pos={22.00,24.00},size={351.00,381.00},disable=1,title="Channel Selection"
	GroupBox group_enable_channels,userdata(tabnum)=  "2"
	GroupBox group_enable_channels,userdata(tabcontrol)=  "Settings"
	GroupBox group_enable_channels,userdata(ResizeControlsInfo)= A"!!,Ba!!#=#!!#BiJ,hsNJ,fQL!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	GroupBox group_enable_channels,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	GroupBox group_enable_channels,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	GroupBox group_enable_artifact,pos={3.00,27.00},size={390.00,54.00},disable=1,title="Artefact Removal"
	GroupBox group_enable_artifact,userdata(tabnum)=  "3"
	GroupBox group_enable_artifact,userdata(tabcontrol)=  "Settings"
	GroupBox group_enable_artifact,userdata(ResizeControlsInfo)= A"!!,>M!!#=;!!#C&J,ho<z!!#](Aon#azzzzzzzzzzzzzz!!#o2B4uAeBk2=!z"
	GroupBox group_enable_artifact,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	GroupBox group_enable_artifact,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	GroupBox group_properties_sweeps,pos={3.00,93.00},size={390.00,312.00},disable=3
	GroupBox group_properties_sweeps,userdata(tabnum)=  "1"
	GroupBox group_properties_sweeps,userdata(tabcontrol)=  "Settings"
	GroupBox group_properties_sweeps,userdata(ResizeControlsInfo)= A"!!,>M!!#?s!!#C&J,hs+J,fQL!!#](Aon\"Qzzzzzzzzzzzzzz!!#o2B4uAezz"
	GroupBox group_properties_sweeps,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	GroupBox group_properties_sweeps,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	GroupBox group_properties_artefact,pos={3.00,84.00},size={390.00,324.00},disable=3
	GroupBox group_properties_artefact,userdata(tabnum)=  "3"
	GroupBox group_properties_artefact,userdata(tabcontrol)=  "Settings"
	GroupBox group_properties_artefact,userdata(ResizeControlsInfo)= A"!!,>M!!#?a!!#C&J,hs1J,fQL!!#](Aon\"Qzzzzzzzzzzzzzz!!#o2B4uAezz"
	GroupBox group_properties_artefact,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	GroupBox group_properties_artefact,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	GroupBox group_channelSel_DA,pos={109.00,42.00},size={42.00,198.00},disable=1,title="DA"
	GroupBox group_channelSel_DA,userdata(tabnum)=  "2"
	GroupBox group_channelSel_DA,userdata(tabcontrol)=  "Settings"
	GroupBox group_channelSel_DA,userdata(ResizeControlsInfo)= A"!!,F=!!#>6!!#>6!!#AUz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	GroupBox group_channelSel_DA,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	GroupBox group_channelSel_DA,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	GroupBox group_properties_pulse,pos={19.00,87.00},size={354.00,315.00},disable=3
	GroupBox group_properties_pulse,userdata(tabnum)=  "4"
	GroupBox group_properties_pulse,userdata(tabcontrol)=  "Settings"
	GroupBox group_properties_pulse,userdata(ResizeControlsInfo)= A"!!,BI!!#?g!!#Bk!!#BWJ,fQL!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	GroupBox group_properties_pulse,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	GroupBox group_properties_pulse,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	GroupBox group_enable_pulse,pos={19.00,27.00},size={354.00,57.00},disable=1,title="Pulse Averaging"
	GroupBox group_enable_pulse,userdata(tabnum)=  "4"
	GroupBox group_enable_pulse,userdata(tabcontrol)=  "Settings"
	GroupBox group_enable_pulse,userdata(ResizeControlsInfo)= A"!!,BI!!#=;!!#Bk!!#>rz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	GroupBox group_enable_pulse,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	GroupBox group_enable_pulse,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_DA_0,pos={121.00,60.00},size={22.00,15.00},disable=1,proc=DB_CheckProc_ChangedSetting,title="0"
	CheckBox check_channelSel_DA_0,userdata(tabnum)=  "2"
	CheckBox check_channelSel_DA_0,userdata(tabcontrol)=  "Settings"
	CheckBox check_channelSel_DA_0,userdata(ResizeControlsInfo)= A"!!,FU!!#?)!!#<h!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_DA_0,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_DA_0,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_DA_0,value= 1
	CheckBox check_channelSel_DA_1,pos={121.00,81.00},size={22.00,15.00},disable=1,proc=DB_CheckProc_ChangedSetting,title="1"
	CheckBox check_channelSel_DA_1,userdata(tabnum)=  "2"
	CheckBox check_channelSel_DA_1,userdata(tabcontrol)=  "Settings"
	CheckBox check_channelSel_DA_1,userdata(ResizeControlsInfo)= A"!!,FU!!#?[!!#<h!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_DA_1,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_DA_1,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_DA_1,value= 1
	CheckBox check_channelSel_DA_2,pos={121.00,102.00},size={22.00,15.00},disable=1,proc=DB_CheckProc_ChangedSetting,title="2"
	CheckBox check_channelSel_DA_2,userdata(tabnum)=  "2"
	CheckBox check_channelSel_DA_2,userdata(tabcontrol)=  "Settings"
	CheckBox check_channelSel_DA_2,userdata(ResizeControlsInfo)= A"!!,FU!!#@0!!#<h!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_DA_2,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_DA_2,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_DA_2,value= 1
	CheckBox check_channelSel_DA_3,pos={121.00,123.00},size={22.00,15.00},disable=1,proc=DB_CheckProc_ChangedSetting,title="3"
	CheckBox check_channelSel_DA_3,userdata(tabnum)=  "2"
	CheckBox check_channelSel_DA_3,userdata(tabcontrol)=  "Settings"
	CheckBox check_channelSel_DA_3,userdata(ResizeControlsInfo)= A"!!,FU!!#@Z!!#<h!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_DA_3,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_DA_3,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_DA_3,value= 1
	CheckBox check_channelSel_DA_4,pos={121.00,144.00},size={22.00,15.00},disable=1,proc=DB_CheckProc_ChangedSetting,title="4"
	CheckBox check_channelSel_DA_4,userdata(tabnum)=  "2"
	CheckBox check_channelSel_DA_4,userdata(tabcontrol)=  "Settings"
	CheckBox check_channelSel_DA_4,userdata(ResizeControlsInfo)= A"!!,FU!!#@t!!#<h!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_DA_4,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_DA_4,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_DA_4,value= 1
	CheckBox check_channelSel_DA_5,pos={121.00,165.00},size={22.00,15.00},disable=1,proc=DB_CheckProc_ChangedSetting,title="5"
	CheckBox check_channelSel_DA_5,userdata(tabnum)=  "2"
	CheckBox check_channelSel_DA_5,userdata(tabcontrol)=  "Settings"
	CheckBox check_channelSel_DA_5,userdata(ResizeControlsInfo)= A"!!,FU!!#A4!!#<h!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_DA_5,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_DA_5,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_DA_5,value= 1
	CheckBox check_channelSel_DA_6,pos={121.00,186.00},size={22.00,15.00},disable=1,proc=DB_CheckProc_ChangedSetting,title="6"
	CheckBox check_channelSel_DA_6,userdata(tabnum)=  "2"
	CheckBox check_channelSel_DA_6,userdata(tabcontrol)=  "Settings"
	CheckBox check_channelSel_DA_6,userdata(ResizeControlsInfo)= A"!!,FU!!#AI!!#<h!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_DA_6,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_DA_6,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_DA_6,value= 1
	CheckBox check_channelSel_DA_7,pos={121.00,207.00},size={22.00,15.00},disable=1,proc=DB_CheckProc_ChangedSetting,title="7"
	CheckBox check_channelSel_DA_7,userdata(tabnum)=  "2"
	CheckBox check_channelSel_DA_7,userdata(tabcontrol)=  "Settings"
	CheckBox check_channelSel_DA_7,userdata(ResizeControlsInfo)= A"!!,FU!!#A^!!#<h!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_DA_7,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_DA_7,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_DA_7,value= 1
	GroupBox group_channelSel_HEADSTAGE,pos={49.00,42.00},size={42.00,198.00},disable=1,title="HS"
	GroupBox group_channelSel_HEADSTAGE,userdata(tabnum)=  "2"
	GroupBox group_channelSel_HEADSTAGE,userdata(tabcontrol)=  "Settings"
	GroupBox group_channelSel_HEADSTAGE,userdata(ResizeControlsInfo)= A"!!,DO!!#>6!!#>6!!#AUz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	GroupBox group_channelSel_HEADSTAGE,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	GroupBox group_channelSel_HEADSTAGE,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_HEADSTAGE_0,pos={58.00,60.00},size={22.00,15.00},disable=1,proc=DB_CheckProc_ChangedSetting,title="0"
	CheckBox check_channelSel_HEADSTAGE_0,userdata(tabnum)=  "2"
	CheckBox check_channelSel_HEADSTAGE_0,userdata(tabcontrol)=  "Settings"
	CheckBox check_channelSel_HEADSTAGE_0,userdata(ResizeControlsInfo)= A"!!,Ds!!#?)!!#<h!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_HEADSTAGE_0,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_HEADSTAGE_0,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_HEADSTAGE_0,value= 1
	CheckBox check_channelSel_HEADSTAGE_1,pos={58.00,81.00},size={22.00,15.00},disable=1,proc=DB_CheckProc_ChangedSetting,title="1"
	CheckBox check_channelSel_HEADSTAGE_1,userdata(tabnum)=  "2"
	CheckBox check_channelSel_HEADSTAGE_1,userdata(tabcontrol)=  "Settings"
	CheckBox check_channelSel_HEADSTAGE_1,userdata(ResizeControlsInfo)= A"!!,Ds!!#?[!!#<h!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_HEADSTAGE_1,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_HEADSTAGE_1,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_HEADSTAGE_1,value= 1
	CheckBox check_channelSel_HEADSTAGE_2,pos={58.00,102.00},size={22.00,15.00},disable=1,proc=DB_CheckProc_ChangedSetting,title="2"
	CheckBox check_channelSel_HEADSTAGE_2,userdata(tabnum)=  "2"
	CheckBox check_channelSel_HEADSTAGE_2,userdata(tabcontrol)=  "Settings"
	CheckBox check_channelSel_HEADSTAGE_2,userdata(ResizeControlsInfo)= A"!!,Ds!!#@0!!#<h!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_HEADSTAGE_2,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_HEADSTAGE_2,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_HEADSTAGE_2,value= 1
	CheckBox check_channelSel_HEADSTAGE_3,pos={58.00,123.00},size={22.00,15.00},disable=1,proc=DB_CheckProc_ChangedSetting,title="3"
	CheckBox check_channelSel_HEADSTAGE_3,userdata(tabnum)=  "2"
	CheckBox check_channelSel_HEADSTAGE_3,userdata(tabcontrol)=  "Settings"
	CheckBox check_channelSel_HEADSTAGE_3,userdata(ResizeControlsInfo)= A"!!,Ds!!#@Z!!#<h!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_HEADSTAGE_3,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_HEADSTAGE_3,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_HEADSTAGE_3,value= 1
	CheckBox check_channelSel_HEADSTAGE_4,pos={58.00,144.00},size={22.00,15.00},disable=1,proc=DB_CheckProc_ChangedSetting,title="4"
	CheckBox check_channelSel_HEADSTAGE_4,userdata(tabnum)=  "2"
	CheckBox check_channelSel_HEADSTAGE_4,userdata(tabcontrol)=  "Settings"
	CheckBox check_channelSel_HEADSTAGE_4,userdata(ResizeControlsInfo)= A"!!,Ds!!#@t!!#<h!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_HEADSTAGE_4,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_HEADSTAGE_4,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_HEADSTAGE_4,value= 1
	CheckBox check_channelSel_HEADSTAGE_5,pos={58.00,165.00},size={22.00,15.00},disable=1,proc=DB_CheckProc_ChangedSetting,title="5"
	CheckBox check_channelSel_HEADSTAGE_5,userdata(tabnum)=  "2"
	CheckBox check_channelSel_HEADSTAGE_5,userdata(tabcontrol)=  "Settings"
	CheckBox check_channelSel_HEADSTAGE_5,userdata(ResizeControlsInfo)= A"!!,Ds!!#A4!!#<h!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_HEADSTAGE_5,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_HEADSTAGE_5,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_HEADSTAGE_5,value= 1
	CheckBox check_channelSel_HEADSTAGE_6,pos={58.00,186.00},size={22.00,15.00},disable=1,proc=DB_CheckProc_ChangedSetting,title="6"
	CheckBox check_channelSel_HEADSTAGE_6,userdata(tabnum)=  "2"
	CheckBox check_channelSel_HEADSTAGE_6,userdata(tabcontrol)=  "Settings"
	CheckBox check_channelSel_HEADSTAGE_6,userdata(ResizeControlsInfo)= A"!!,Ds!!#AI!!#<h!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_HEADSTAGE_6,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_HEADSTAGE_6,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_HEADSTAGE_6,value= 1
	CheckBox check_channelSel_HEADSTAGE_7,pos={58.00,207.00},size={22.00,15.00},disable=1,proc=DB_CheckProc_ChangedSetting,title="7"
	CheckBox check_channelSel_HEADSTAGE_7,userdata(tabnum)=  "2"
	CheckBox check_channelSel_HEADSTAGE_7,userdata(tabcontrol)=  "Settings"
	CheckBox check_channelSel_HEADSTAGE_7,userdata(ResizeControlsInfo)= A"!!,Ds!!#A^!!#<h!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_HEADSTAGE_7,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_HEADSTAGE_7,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_HEADSTAGE_7,value= 1
	GroupBox group_channelSel_AD,pos={172.00,42.00},size={45.00,360.00},disable=1,title="AD"
	GroupBox group_channelSel_AD,userdata(tabnum)=  "2"
	GroupBox group_channelSel_AD,userdata(tabcontrol)=  "Settings"
	GroupBox group_channelSel_AD,userdata(ResizeControlsInfo)= A"!!,G;!!#>6!!#>B!!#Bnz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	GroupBox group_channelSel_AD,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	GroupBox group_channelSel_AD,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_AD_0,pos={178.00,60.00},size={22.00,15.00},disable=1,proc=DB_CheckProc_ChangedSetting,title="0"
	CheckBox check_channelSel_AD_0,userdata(tabnum)=  "2"
	CheckBox check_channelSel_AD_0,userdata(tabcontrol)=  "Settings"
	CheckBox check_channelSel_AD_0,userdata(ResizeControlsInfo)= A"!!,GA!!#?)!!#<h!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_AD_0,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_AD_0,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_AD_0,value= 1
	CheckBox check_channelSel_AD_1,pos={178.00,81.00},size={22.00,15.00},disable=1,proc=DB_CheckProc_ChangedSetting,title="1"
	CheckBox check_channelSel_AD_1,userdata(tabnum)=  "2"
	CheckBox check_channelSel_AD_1,userdata(tabcontrol)=  "Settings"
	CheckBox check_channelSel_AD_1,userdata(ResizeControlsInfo)= A"!!,GA!!#?[!!#<h!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_AD_1,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_AD_1,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_AD_1,value= 1
	CheckBox check_channelSel_AD_2,pos={178.00,102.00},size={22.00,15.00},disable=1,proc=DB_CheckProc_ChangedSetting,title="2"
	CheckBox check_channelSel_AD_2,userdata(tabnum)=  "2"
	CheckBox check_channelSel_AD_2,userdata(tabcontrol)=  "Settings"
	CheckBox check_channelSel_AD_2,userdata(ResizeControlsInfo)= A"!!,GA!!#@0!!#<h!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_AD_2,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_AD_2,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_AD_2,value= 1
	CheckBox check_channelSel_AD_3,pos={178.00,123.00},size={22.00,15.00},disable=1,proc=DB_CheckProc_ChangedSetting,title="3"
	CheckBox check_channelSel_AD_3,userdata(tabnum)=  "2"
	CheckBox check_channelSel_AD_3,userdata(tabcontrol)=  "Settings"
	CheckBox check_channelSel_AD_3,userdata(ResizeControlsInfo)= A"!!,GA!!#@Z!!#<h!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_AD_3,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_AD_3,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_AD_3,value= 1
	CheckBox check_channelSel_AD_4,pos={178.00,144.00},size={22.00,15.00},disable=1,proc=DB_CheckProc_ChangedSetting,title="4"
	CheckBox check_channelSel_AD_4,userdata(tabnum)=  "2"
	CheckBox check_channelSel_AD_4,userdata(tabcontrol)=  "Settings"
	CheckBox check_channelSel_AD_4,userdata(ResizeControlsInfo)= A"!!,GA!!#@t!!#<h!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_AD_4,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_AD_4,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_AD_4,value= 1
	CheckBox check_channelSel_AD_5,pos={178.00,165.00},size={22.00,15.00},disable=1,proc=DB_CheckProc_ChangedSetting,title="5"
	CheckBox check_channelSel_AD_5,userdata(tabnum)=  "2"
	CheckBox check_channelSel_AD_5,userdata(tabcontrol)=  "Settings"
	CheckBox check_channelSel_AD_5,userdata(ResizeControlsInfo)= A"!!,GA!!#A4!!#<h!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_AD_5,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_AD_5,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_AD_5,value= 1
	CheckBox check_channelSel_AD_6,pos={178.00,186.00},size={22.00,15.00},disable=1,proc=DB_CheckProc_ChangedSetting,title="6"
	CheckBox check_channelSel_AD_6,userdata(tabnum)=  "2"
	CheckBox check_channelSel_AD_6,userdata(tabcontrol)=  "Settings"
	CheckBox check_channelSel_AD_6,userdata(ResizeControlsInfo)= A"!!,GA!!#AI!!#<h!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_AD_6,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_AD_6,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_AD_6,value= 1
	CheckBox check_channelSel_AD_7,pos={178.00,207.00},size={22.00,15.00},disable=1,proc=DB_CheckProc_ChangedSetting,title="7"
	CheckBox check_channelSel_AD_7,userdata(tabnum)=  "2"
	CheckBox check_channelSel_AD_7,userdata(tabcontrol)=  "Settings"
	CheckBox check_channelSel_AD_7,userdata(ResizeControlsInfo)= A"!!,GA!!#A^!!#<h!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_AD_7,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_AD_7,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_AD_7,value= 1
	CheckBox check_channelSel_AD_8,pos={178.00,228.00},size={22.00,15.00},disable=1,proc=DB_CheckProc_ChangedSetting,title="8"
	CheckBox check_channelSel_AD_8,userdata(tabnum)=  "2"
	CheckBox check_channelSel_AD_8,userdata(tabcontrol)=  "Settings"
	CheckBox check_channelSel_AD_8,userdata(ResizeControlsInfo)= A"!!,GA!!#As!!#<h!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_AD_8,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_AD_8,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_AD_8,value= 1
	CheckBox check_channelSel_AD_9,pos={178.00,249.00},size={22.00,15.00},disable=1,proc=DB_CheckProc_ChangedSetting,title="9"
	CheckBox check_channelSel_AD_9,userdata(tabnum)=  "2"
	CheckBox check_channelSel_AD_9,userdata(tabcontrol)=  "Settings"
	CheckBox check_channelSel_AD_9,userdata(ResizeControlsInfo)= A"!!,GA!!#B3!!#<h!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_AD_9,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_AD_9,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_AD_9,value= 1
	CheckBox check_channelSel_AD_10,pos={178.00,270.00},size={28.00,15.00},disable=1,proc=DB_CheckProc_ChangedSetting,title="10"
	CheckBox check_channelSel_AD_10,userdata(tabnum)=  "2"
	CheckBox check_channelSel_AD_10,userdata(tabcontrol)=  "Settings"
	CheckBox check_channelSel_AD_10,userdata(ResizeControlsInfo)= A"!!,GA!!#BA!!#=C!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_AD_10,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_AD_10,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_AD_10,value= 1
	CheckBox check_channelSel_AD_11,pos={178.00,291.00},size={28.00,15.00},disable=1,proc=DB_CheckProc_ChangedSetting,title="11"
	CheckBox check_channelSel_AD_11,userdata(tabnum)=  "2"
	CheckBox check_channelSel_AD_11,userdata(tabcontrol)=  "Settings"
	CheckBox check_channelSel_AD_11,userdata(ResizeControlsInfo)= A"!!,GA!!#BKJ,hmn!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_AD_11,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_AD_11,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_AD_11,value= 1
	CheckBox check_channelSel_AD_12,pos={178.00,312.00},size={28.00,15.00},disable=1,proc=DB_CheckProc_ChangedSetting,title="12"
	CheckBox check_channelSel_AD_12,userdata(tabnum)=  "2"
	CheckBox check_channelSel_AD_12,userdata(tabcontrol)=  "Settings"
	CheckBox check_channelSel_AD_12,userdata(ResizeControlsInfo)= A"!!,GA!!#BV!!#=C!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_AD_12,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_AD_12,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_AD_12,value= 1
	CheckBox check_channelSel_AD_13,pos={178.00,333.00},size={28.00,15.00},disable=1,proc=DB_CheckProc_ChangedSetting,title="13"
	CheckBox check_channelSel_AD_13,userdata(tabnum)=  "2"
	CheckBox check_channelSel_AD_13,userdata(tabcontrol)=  "Settings"
	CheckBox check_channelSel_AD_13,userdata(ResizeControlsInfo)= A"!!,GA!!#B`J,hmn!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_AD_13,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_AD_13,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_AD_13,value= 1
	CheckBox check_channelSel_AD_14,pos={178.00,354.00},size={28.00,15.00},disable=1,proc=DB_CheckProc_ChangedSetting,title="14"
	CheckBox check_channelSel_AD_14,userdata(tabnum)=  "2"
	CheckBox check_channelSel_AD_14,userdata(tabcontrol)=  "Settings"
	CheckBox check_channelSel_AD_14,userdata(ResizeControlsInfo)= A"!!,GA!!#Bk!!#=C!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_AD_14,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_AD_14,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_AD_14,value= 1
	CheckBox check_channelSel_AD_15,pos={178.00,375.00},size={28.00,15.00},disable=1,proc=DB_CheckProc_ChangedSetting,title="15"
	CheckBox check_channelSel_AD_15,userdata(tabnum)=  "2"
	CheckBox check_channelSel_AD_15,userdata(tabcontrol)=  "Settings"
	CheckBox check_channelSel_AD_15,userdata(ResizeControlsInfo)= A"!!,GA!!#BuJ,hmn!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_AD_15,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_AD_15,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_AD_15,value= 1
	ListBox list_of_ranges1,pos={75.00,156.00},size={234.00,243.00},disable=3,proc=AR_MainListBoxProc
	ListBox list_of_ranges1,userdata(tabnum)=  "3",userdata(tabcontrol)=  "Settings"
	ListBox list_of_ranges1,userdata(ResizeControlsInfo)= A"!!,EP!!#A+!!#B!!!#B,z!!#](Aon\"Qzzzzzzzzzzzzzz!!#o2B4uAezz"
	ListBox list_of_ranges1,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	ListBox list_of_ranges1,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	ListBox list_of_ranges1,mode= 1,selRow= 0,widths={54,50,66}
	Button button_RemoveRanges,pos={91.00,126.00},size={54.00,21.00},disable=3,proc=AR_ButtonProc_RemoveRanges,title="Remove"
	Button button_RemoveRanges,userdata(tabnum)=  "3"
	Button button_RemoveRanges,userdata(tabcontrol)=  "Settings"
	Button button_RemoveRanges,userdata(ResizeControlsInfo)= A"!!,En!!#@`!!#>f!!#<`z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	Button button_RemoveRanges,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button button_RemoveRanges,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_cutoff_length_after,pos={247.00,96.00},size={45.00,18.00},disable=3,proc=AR_SetVarProcCutoffLength
	SetVariable setvar_cutoff_length_after,help={"Time in ms which should be cutoff *after* the artefact."}
	SetVariable setvar_cutoff_length_after,userdata(tabnum)=  "3"
	SetVariable setvar_cutoff_length_after,userdata(tabcontrol)=  "Settings"
	SetVariable setvar_cutoff_length_after,userdata(ResizeControlsInfo)= A"!!,H1!!#@$!!#>B!!#<Hz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	SetVariable setvar_cutoff_length_after,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_cutoff_length_after,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_cutoff_length_after,limits={0,inf,0.1},value= _NUM:0.2
	SetVariable setvar_cutoff_length_before,pos={94.00,96.00},size={150.00,18.00},disable=3,proc=AR_SetVarProcCutoffLength,title="Cutoff length [ms]:"
	SetVariable setvar_cutoff_length_before,help={"Time in ms which should be cutoff *before* the artefact."}
	SetVariable setvar_cutoff_length_before,userdata(tabnum)=  "3"
	SetVariable setvar_cutoff_length_before,userdata(tabcontrol)=  "Settings"
	SetVariable setvar_cutoff_length_before,userdata(ResizeControlsInfo)= A"!!,Et!!#@$!!#A%!!#<Hz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	SetVariable setvar_cutoff_length_before,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_cutoff_length_before,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_cutoff_length_before,limits={0,inf,0.1},value= _NUM:0.1
	CheckBox check_auto_remove,pos={160.00,129.00},size={85.00,15.00},disable=3,proc=AR_CheckProc_Update,title="Auto remove"
	CheckBox check_auto_remove,help={"Automatically remove the found ranges on sweep plotting"}
	CheckBox check_auto_remove,userdata(tabnum)=  "3"
	CheckBox check_auto_remove,userdata(tabcontrol)=  "Settings"
	CheckBox check_auto_remove,userdata(ResizeControlsInfo)= A"!!,G/!!#@e!!#?c!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_auto_remove,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_auto_remove,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_auto_remove,value= 0
	CheckBox check_highlightRanges,pos={262.00,129.00},size={31.00,15.00},disable=3,proc=AR_CheckProc_Update,title="HL"
	CheckBox check_highlightRanges,help={"Visualize the found ranges in the graph (*might* slowdown graphing)"}
	CheckBox check_highlightRanges,userdata(tabnum)=  "3"
	CheckBox check_highlightRanges,userdata(tabcontrol)=  "Settings"
	CheckBox check_highlightRanges,userdata(ResizeControlsInfo)= A"!!,H=J,hq;!!#=[!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_highlightRanges,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_highlightRanges,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_highlightRanges,value= 0
	SetVariable setvar_pulseAver_fallbackLength,pos={139.00,225.00},size={112.00,12.00},bodyWidth=50,disable=3,proc=PA_SetVarProc_Common,title="Fallback Length"
	SetVariable setvar_pulseAver_fallbackLength,help={"Pulse To Pulse Length in ms for edge cases which can not be computed."}
	SetVariable setvar_pulseAver_fallbackLength,userdata(tabnum)=  "4"
	SetVariable setvar_pulseAver_fallbackLength,userdata(tabcontrol)=  "Settings"
	SetVariable setvar_pulseAver_fallbackLength,userdata(ResizeControlsInfo)= A"!!,Fo!!#Ap!!#@D!!#;Mz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	SetVariable setvar_pulseAver_fallbackLength,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_pulseAver_fallbackLength,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_pulseAver_fallbackLength,value= _NUM:100
	SetVariable setvar_pulseAver_endPulse,pos={152.00,204.00},size={102.00,12.00},bodyWidth=50,disable=3,proc=PA_SetVarProc_Common,title="Ending Pulse"
	SetVariable setvar_pulseAver_endPulse,userdata(tabnum)=  "4"
	SetVariable setvar_pulseAver_endPulse,userdata(tabcontrol)=  "Settings"
	SetVariable setvar_pulseAver_endPulse,userdata(ResizeControlsInfo)= A"!!,G'!!#A[!!#@0!!#;Mz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	SetVariable setvar_pulseAver_endPulse,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_pulseAver_endPulse,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_pulseAver_endPulse,value= _NUM:inf
	SetVariable setvar_pulseAver_startPulse,pos={148.00,180.00},size={105.00,12.00},bodyWidth=50,disable=3,proc=PA_SetVarProc_Common,title="Starting Pulse"
	SetVariable setvar_pulseAver_startPulse,userdata(tabnum)=  "4"
	SetVariable setvar_pulseAver_startPulse,userdata(tabcontrol)=  "Settings"
	SetVariable setvar_pulseAver_startPulse,userdata(ResizeControlsInfo)= A"!!,G#!!#AC!!#@6!!#;Mz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	SetVariable setvar_pulseAver_startPulse,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_pulseAver_startPulse,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_pulseAver_startPulse,value= _NUM:0
	CheckBox check_pulseAver_multGraphs,pos={124.00,162.00},size={90.00,12.00},disable=3,proc=PA_CheckProc_Common,title="Use multiple graphs"
	CheckBox check_pulseAver_multGraphs,help={"Show the single pulses in multiple graphs or only one graph with mutiple axis."}
	CheckBox check_pulseAver_multGraphs,userdata(tabnum)=  "4"
	CheckBox check_pulseAver_multGraphs,userdata(tabcontrol)=  "Settings"
	CheckBox check_pulseAver_multGraphs,userdata(ResizeControlsInfo)= A"!!,F[!!#A1!!#?m!!#;Mz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_pulseAver_multGraphs,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_pulseAver_multGraphs,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_pulseAver_multGraphs,value= 0
	CheckBox check_pulseAver_zeroTrac,pos={124.00,120.00},size={54.00,12.00},disable=3,proc=PA_CheckProc_Common,title="Zero traces"
	CheckBox check_pulseAver_zeroTrac,help={"Zero the individual traces using subsequent differentiation and integration"}
	CheckBox check_pulseAver_zeroTrac,userdata(tabnum)=  "4"
	CheckBox check_pulseAver_zeroTrac,userdata(tabcontrol)=  "Settings"
	CheckBox check_pulseAver_zeroTrac,userdata(ResizeControlsInfo)= A"!!,F[!!#@T!!#>f!!#;Mz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_pulseAver_zeroTrac,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_pulseAver_zeroTrac,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_pulseAver_zeroTrac,value= 0
	CheckBox check_pulseAver_showAver,pos={124.00,141.00},size={88.00,12.00},disable=3,proc=PA_CheckProc_Average,title="Show average trace"
	CheckBox check_pulseAver_showAver,help={"Show the average trace"}
	CheckBox check_pulseAver_showAver,userdata(tabnum)=  "4"
	CheckBox check_pulseAver_showAver,userdata(tabcontrol)=  "Settings"
	CheckBox check_pulseAver_showAver,userdata(ResizeControlsInfo)= A"!!,F[!!#@q!!#?i!!#;Mz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_pulseAver_showAver,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_pulseAver_showAver,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_pulseAver_showAver,value= 0
	CheckBox check_pulseAver_indTraces,pos={124.00,99.00},size={99.00,12.00},disable=3,proc=PA_CheckProc_Individual,title="Show individual traces"
	CheckBox check_pulseAver_indTraces,help={"Show the individual traces"}
	CheckBox check_pulseAver_indTraces,userdata(tabnum)=  "4"
	CheckBox check_pulseAver_indTraces,userdata(tabcontrol)=  "Settings"
	CheckBox check_pulseAver_indTraces,userdata(ResizeControlsInfo)= A"!!,F[!!#@*!!#@*!!#;Mz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_pulseAver_indTraces,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_pulseAver_indTraces,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_pulseAver_indTraces,value= 1
	CheckBox check_pulseAver_deconv,pos={124.00,249.00},size={69.00,12.00},disable=3,proc=PA_CheckProc_Deconvolution,title="Deconvolution"
	CheckBox check_pulseAver_deconv,help={"Show Deconvolution: tau * dV/dt + V"}
	CheckBox check_pulseAver_deconv,userdata(tabnum)=  "4"
	CheckBox check_pulseAver_deconv,userdata(tabcontrol)=  "Settings"
	CheckBox check_pulseAver_deconv,userdata(ResizeControlsInfo)= A"!!,F[!!#B3!!#?C!!#;Mz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_pulseAver_deconv,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_pulseAver_deconv,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_pulseAver_deconv,value= 0
	CheckBox check_pulseAver_timeAlign,pos={124.00,348.00},size={75.00,12.00},disable=3,proc=PA_CheckProc_Common,title="Time Alignment"
	CheckBox check_pulseAver_timeAlign,help={"Automatically align all traces in the PA graph to a reference trace from the diagonal element"}
	CheckBox check_pulseAver_timeAlign,userdata(tabnum)=  "4"
	CheckBox check_pulseAver_timeAlign,userdata(tabcontrol)=  "Settings"
	CheckBox check_pulseAver_timeAlign,userdata(ResizeControlsInfo)= A"!!,F[!!#Bh!!#?O!!#;Mz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_pulseAver_timeAlign,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_pulseAver_timeAlign,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_pulseAver_timeAlign,value= 0
	SetVariable setvar_pulseAver_deconv_tau,pos={170.00,270.00},size={84.00,12.00},bodyWidth=50,disable=3,proc=PA_SetVarProc_Common,title="tau [ms]"
	SetVariable setvar_pulseAver_deconv_tau,help={"Deconvolution time tau: tau * dV/dt + V"}
	SetVariable setvar_pulseAver_deconv_tau,userdata(tabnum)=  "4"
	SetVariable setvar_pulseAver_deconv_tau,userdata(tabcontrol)=  "Settings"
	SetVariable setvar_pulseAver_deconv_tau,userdata(ResizeControlsInfo)= A"!!,G9!!#BA!!#?a!!#;Mz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	SetVariable setvar_pulseAver_deconv_tau,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_pulseAver_deconv_tau,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_pulseAver_deconv_tau,limits={0,inf,0},value= _NUM:15
	SetVariable setvar_pulseAver_deconv_smth,pos={157.00,294.00},size={93.00,12.00},bodyWidth=50,disable=3,proc=PA_SetVarProc_Common,title="smoothing"
	SetVariable setvar_pulseAver_deconv_smth,help={"Smoothing factor to use before the deconvolution is calculated. Set to 1 to do the calculation without smoothing."}
	SetVariable setvar_pulseAver_deconv_smth,userdata(tabnum)=  "4"
	SetVariable setvar_pulseAver_deconv_smth,userdata(tabcontrol)=  "Settings"
	SetVariable setvar_pulseAver_deconv_smth,userdata(ResizeControlsInfo)= A"!!,G,!!#BM!!#?s!!#;Mz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	SetVariable setvar_pulseAver_deconv_smth,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_pulseAver_deconv_smth,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_pulseAver_deconv_smth,limits={1,inf,0},value= _NUM:1000
	SetVariable setvar_pulseAver_deconv_range,pos={154.00,315.00},size={99.00,12.00},bodyWidth=50,disable=3,proc=PA_SetVarProc_Common,title="display [ms]"
	SetVariable setvar_pulseAver_deconv_range,help={"Time in ms from the beginning of the pulse that is used for the calculation"}
	SetVariable setvar_pulseAver_deconv_range,userdata(tabnum)=  "4"
	SetVariable setvar_pulseAver_deconv_range,userdata(tabcontrol)=  "Settings"
	SetVariable setvar_pulseAver_deconv_range,userdata(ResizeControlsInfo)= A"!!,G)!!#BWJ,hpU!!#;Mz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	SetVariable setvar_pulseAver_deconv_range,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_pulseAver_deconv_range,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_pulseAver_deconv_range,limits={0,inf,0},value= _NUM:inf
	GroupBox group_pulseAver_deconv,pos={115.00,246.00},size={153.00,96.00},disable=3
	GroupBox group_pulseAver_deconv,userdata(tabnum)=  "4"
	GroupBox group_pulseAver_deconv,userdata(tabcontrol)=  "Settings"
	GroupBox group_pulseAver_deconv,userdata(ResizeControlsInfo)= A"!!,FI!!#B0!!#A(!!#@$z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	GroupBox group_pulseAver_deconv,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	GroupBox group_pulseAver_deconv,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_BrowserSettings_OVS,pos={172.00,48.00},size={51.00,15.00},disable=1,proc=DB_CheckProc_OverlaySweeps,title="enable"
	CheckBox check_BrowserSettings_OVS,help={"Adds unplotted sweep to graph. Removes plotted sweep from graph."}
	CheckBox check_BrowserSettings_OVS,userdata(tabnum)=  "1"
	CheckBox check_BrowserSettings_OVS,userdata(tabcontrol)=  "Settings"
	CheckBox check_BrowserSettings_OVS,userdata(ResizeControlsInfo)= A"!!,G;!!#>N!!#>Z!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_BrowserSettings_OVS,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_BrowserSettings_OVS,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_BrowserSettings_OVS,value= 0
	CheckBox check_BrowserSettings_AR,pos={166.00,48.00},size={51.00,15.00},disable=1,proc=BSP_CheckBoxProc_ArtRemoval,title="enable"
	CheckBox check_BrowserSettings_AR,help={"Open the artefact removal dialog"}
	CheckBox check_BrowserSettings_AR,userdata(tabnum)=  "3"
	CheckBox check_BrowserSettings_AR,userdata(tabcontrol)=  "Settings"
	CheckBox check_BrowserSettings_AR,userdata(ResizeControlsInfo)= A"!!,G5!!#>N!!#>Z!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_BrowserSettings_AR,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_BrowserSettings_AR,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_BrowserSettings_AR,value= 0
	CheckBox check_BrowserSettings_PA,pos={166.00,48.00},size={37.00,12.00},disable=1,proc=BSP_CheckBoxProc_PerPulseAver,title="enable"
	CheckBox check_BrowserSettings_PA,help={"Allows to average multiple pulses from pulse train epochs"}
	CheckBox check_BrowserSettings_PA,userdata(tabnum)=  "4"
	CheckBox check_BrowserSettings_PA,userdata(tabcontrol)=  "Settings"
	CheckBox check_BrowserSettings_PA,userdata(ResizeControlsInfo)= A"!!,G5!!#>N!!#>\"!!#;Mz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_BrowserSettings_PA,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_BrowserSettings_PA,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_BrowserSettings_PA,value= 0
	CheckBox check_BrowserSettings_DAC,pos={28.00,36.00},size={32.00,15.00},title="DA"
	CheckBox check_BrowserSettings_DAC,help={"Display the DA channel data"}
	CheckBox check_BrowserSettings_DAC,userdata(tabnum)=  "0"
	CheckBox check_BrowserSettings_DAC,userdata(tabcontrol)=  "Settings"
	CheckBox check_BrowserSettings_DAC,userdata(ResizeControlsInfo)= A"!!,C<!!#=s!!#=c!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_BrowserSettings_DAC,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_BrowserSettings_DAC,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_BrowserSettings_DAC,value= 0
	CheckBox check_BrowserSettings_ADC,pos={91.00,36.00},size={32.00,15.00},title="AD"
	CheckBox check_BrowserSettings_ADC,help={"Display the AD channels"}
	CheckBox check_BrowserSettings_ADC,userdata(tabnum)=  "0"
	CheckBox check_BrowserSettings_ADC,userdata(tabcontrol)=  "Settings"
	CheckBox check_BrowserSettings_ADC,userdata(ResizeControlsInfo)= A"!!,En!!#=s!!#=c!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_BrowserSettings_ADC,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_BrowserSettings_ADC,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_BrowserSettings_ADC,value= 1
	CheckBox check_BrowserSettings_TTL,pos={148.00,36.00},size={34.00,15.00},title="TTL"
	CheckBox check_BrowserSettings_TTL,help={"Display the TTL channels"}
	CheckBox check_BrowserSettings_TTL,userdata(tabnum)=  "0"
	CheckBox check_BrowserSettings_TTL,userdata(tabcontrol)=  "Settings"
	CheckBox check_BrowserSettings_TTL,userdata(ResizeControlsInfo)= A"!!,G#!!#=s!!#=k!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_BrowserSettings_TTL,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_BrowserSettings_TTL,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_BrowserSettings_TTL,value= 0
	CheckBox check_BrowserSettings_OChan,pos={28.00,60.00},size={65.00,15.00},title="Channels"
	CheckBox check_BrowserSettings_OChan,help={"Overlay the data from multiple channels in one graph"}
	CheckBox check_BrowserSettings_OChan,userdata(tabnum)=  "0"
	CheckBox check_BrowserSettings_OChan,userdata(tabcontrol)=  "Settings"
	CheckBox check_BrowserSettings_OChan,userdata(ResizeControlsInfo)= A"!!,C<!!#?)!!#?;!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_BrowserSettings_OChan,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_BrowserSettings_OChan,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_BrowserSettings_OChan,value= 0
	CheckBox check_BrowserSettings_dDAQ,pos={148.00,60.00},size={48.00,15.00},title="dDAQ"
	CheckBox check_BrowserSettings_dDAQ,help={"Enable dedicated support for viewing distributed DAQ data"}
	CheckBox check_BrowserSettings_dDAQ,userdata(tabnum)=  "0"
	CheckBox check_BrowserSettings_dDAQ,userdata(tabcontrol)=  "Settings"
	CheckBox check_BrowserSettings_dDAQ,userdata(ResizeControlsInfo)= A"!!,G#!!#?)!!#>N!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_BrowserSettings_dDAQ,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_BrowserSettings_dDAQ,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_BrowserSettings_dDAQ,value= 0
	CheckBox check_Calculation_ZeroTraces,pos={40.00,219.00},size={75.00,15.00},title="Zero Traces"
	CheckBox check_Calculation_ZeroTraces,help={"Remove the offset of all traces"}
	CheckBox check_Calculation_ZeroTraces,userdata(tabnum)=  "0"
	CheckBox check_Calculation_ZeroTraces,userdata(tabcontrol)=  "Settings"
	CheckBox check_Calculation_ZeroTraces,userdata(ResizeControlsInfo)= A"!!,D+!!#Aj!!#?O!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_Calculation_ZeroTraces,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_Calculation_ZeroTraces,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_Calculation_ZeroTraces,value= 0
	CheckBox check_Calculation_AverageTraces,pos={40.00,198.00},size={94.00,15.00},title="Average Traces"
	CheckBox check_Calculation_AverageTraces,help={"Average all traces which belong to the same y axis"}
	CheckBox check_Calculation_AverageTraces,userdata(tabnum)=  "0"
	CheckBox check_Calculation_AverageTraces,userdata(tabcontrol)=  "Settings"
	CheckBox check_Calculation_AverageTraces,userdata(ResizeControlsInfo)= A"!!,D+!!#AU!!#?u!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_Calculation_AverageTraces,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_Calculation_AverageTraces,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_Calculation_AverageTraces,value= 0
	CheckBox check_BrowserSettings_TA,pos={154.00,111.00},size={51.00,15.00},proc=BSP_TimeAlignmentProc,title="enable"
	CheckBox check_BrowserSettings_TA,help={"Activate time alignment"}
	CheckBox check_BrowserSettings_TA,userdata(tabnum)=  "0"
	CheckBox check_BrowserSettings_TA,userdata(tabcontrol)=  "Settings"
	CheckBox check_BrowserSettings_TA,userdata(ResizeControlsInfo)= A"!!,G)!!#@B!!#>Z!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_BrowserSettings_TA,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_BrowserSettings_TA,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_BrowserSettings_TA,value= 0
	CheckBox check_ovs_clear_on_new_ra_cycle,pos={235.00,161.00},size={111.00,15.00},disable=3,title="Clear on new RAC"
	CheckBox check_ovs_clear_on_new_ra_cycle,help={"Clear the list of overlayed sweeps when a new repeated acquisition cycle has begun."}
	CheckBox check_ovs_clear_on_new_ra_cycle,userdata(tabnum)=  "1"
	CheckBox check_ovs_clear_on_new_ra_cycle,userdata(tabcontrol)=  "Settings"
	CheckBox check_ovs_clear_on_new_ra_cycle,userdata(ResizeControlsInfo)= A"!!,H%!!#A0!!#@B!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_ovs_clear_on_new_ra_cycle,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_ovs_clear_on_new_ra_cycle,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_ovs_clear_on_new_ra_cycle,value= 0
	CheckBox check_ovs_clear_on_new_stimset_cycle,pos={235.00,181.00},size={105.00,15.00},disable=3,title="Clear on new SCI"
	CheckBox check_ovs_clear_on_new_stimset_cycle,help={"Clear the list of overlayed sweeps when a new simset cycle has begun."}
	CheckBox check_ovs_clear_on_new_stimset_cycle,userdata(tabnum)=  "1"
	CheckBox check_ovs_clear_on_new_stimset_cycle,userdata(tabcontrol)=  "Settings"
	CheckBox check_ovs_clear_on_new_stimset_cycle,userdata(ResizeControlsInfo)= A"!!,H%!!#AD!!#@6!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_ovs_clear_on_new_stimset_cycle,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_ovs_clear_on_new_stimset_cycle,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_ovs_clear_on_new_stimset_cycle,value= 0
	PopupMenu popup_TimeAlignment_Mode,pos={31.00,135.00},size={143.00,19.00},bodyWidth=50,disable=2,proc=BSP_TimeAlignmentPopup,title="Alignment Mode"
	PopupMenu popup_TimeAlignment_Mode,help={"Select the alignment mode"}
	PopupMenu popup_TimeAlignment_Mode,userdata(tabnum)=  "0"
	PopupMenu popup_TimeAlignment_Mode,userdata(tabcontrol)=  "Settings"
	PopupMenu popup_TimeAlignment_Mode,userdata(ResizeControlsInfo)= A"!!,CT!!#@k!!#@s!!#<Pz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	PopupMenu popup_TimeAlignment_Mode,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu popup_TimeAlignment_Mode,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu popup_TimeAlignment_Mode,mode=1,popvalue="Level (Raising)",value= #"\"Level (Raising);Level (Falling);Min;Max\""
	SetVariable setvar_TimeAlignment_LevelCross,pos={187.00,135.00},size={48.00,18.00},disable=2,proc=BSP_TimeAlignmentLevel,title="Level"
	SetVariable setvar_TimeAlignment_LevelCross,help={"Select the level (for rising and falling alignment mode) at which traces are aligned"}
	SetVariable setvar_TimeAlignment_LevelCross,userdata(tabnum)=  "0"
	SetVariable setvar_TimeAlignment_LevelCross,userdata(tabcontrol)=  "Settings"
	SetVariable setvar_TimeAlignment_LevelCross,userdata(ResizeControlsInfo)= A"!!,GJ!!#@k!!#>N!!#<Hz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	SetVariable setvar_TimeAlignment_LevelCross,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_TimeAlignment_LevelCross,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_TimeAlignment_LevelCross,limits={-inf,inf,0},value= _NUM:0
	Button button_TimeAlignment_Action,pos={208.00,159.00},size={30.00,18.00},disable=2,title="Do!"
	Button button_TimeAlignment_Action,help={"Perform the time alignment, needs the cursors A and B to have a selected feature"}
	Button button_TimeAlignment_Action,userdata(tabnum)=  "0"
	Button button_TimeAlignment_Action,userdata(tabcontrol)=  "Settings"
	Button button_TimeAlignment_Action,userdata(ResizeControlsInfo)= A"!!,G_!!#A.!!#=S!!#<Hz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	Button button_TimeAlignment_Action,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button button_TimeAlignment_Action,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	GroupBox group_SB_axes_scaling,pos={28.00,246.00},size={285.00,51.00},title="Axes Scaling"
	GroupBox group_SB_axes_scaling,userdata(tabnum)=  "0"
	GroupBox group_SB_axes_scaling,userdata(tabcontrol)=  "Settings"
	GroupBox group_SB_axes_scaling,userdata(ResizeControlsInfo)= A"!!,C<!!#B0!!#BHJ,ho0z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	GroupBox group_SB_axes_scaling,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	GroupBox group_SB_axes_scaling,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_Display_VisibleXrange,pos={40.00,270.00},size={41.00,15.00},title="Vis X"
	CheckBox check_Display_VisibleXrange,help={"Scale the y axis to the visible x data range"}
	CheckBox check_Display_VisibleXrange,userdata(tabnum)=  "0"
	CheckBox check_Display_VisibleXrange,userdata(tabcontrol)=  "Settings"
	CheckBox check_Display_VisibleXrange,userdata(ResizeControlsInfo)= A"!!,D+!!#BA!!#>2!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_Display_VisibleXrange,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_Display_VisibleXrange,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_Display_VisibleXrange,value= 0
	CheckBox check_Display_EqualYrange,pos={94.00,270.00},size={55.00,15.00},disable=2,title="Equal Y"
	CheckBox check_Display_EqualYrange,help={"Equalize the vertical axes ranges"}
	CheckBox check_Display_EqualYrange,userdata(tabnum)=  "0"
	CheckBox check_Display_EqualYrange,userdata(tabcontrol)=  "Settings"
	CheckBox check_Display_EqualYrange,userdata(ResizeControlsInfo)= A"!!,Et!!#BA!!#>j!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_Display_EqualYrange,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_Display_EqualYrange,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_Display_EqualYrange,value= 0
	CheckBox check_Display_EqualYignore,pos={154.00,270.00},size={36.00,15.00},disable=2,title="ign."
	CheckBox check_Display_EqualYignore,help={"Equalize the vertical axes ranges but ignore all traces with level crossings"}
	CheckBox check_Display_EqualYignore,userdata(tabnum)=  "0"
	CheckBox check_Display_EqualYignore,userdata(tabcontrol)=  "Settings"
	CheckBox check_Display_EqualYignore,userdata(ResizeControlsInfo)= A"!!,G)!!#BA!!#=s!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_Display_EqualYignore,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_Display_EqualYignore,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_Display_EqualYignore,value= 0
	SetVariable setvar_Display_EqualYlevel,pos={193.00,270.00},size={24.00,18.00},disable=2,proc=SB_AxisScalingLevelCross
	SetVariable setvar_Display_EqualYlevel,help={"Crossing level value for 'Equal Y ign.\""}
	SetVariable setvar_Display_EqualYlevel,userdata(tabnum)=  "0"
	SetVariable setvar_Display_EqualYlevel,userdata(tabcontrol)=  "Settings"
	SetVariable setvar_Display_EqualYlevel,userdata(ResizeControlsInfo)= A"!!,GP!!#BA!!#=#!!#<Hz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	SetVariable setvar_Display_EqualYlevel,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_Display_EqualYlevel,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_Display_EqualYlevel,limits={-inf,inf,0},value= _NUM:0
	PopupMenu popup_TimeAlignment_Master,pos={44.00,159.00},size={134.00,19.00},bodyWidth=50,disable=2,proc=BSP_TimeAlignmentPopup,title="Reference trace"
	PopupMenu popup_TimeAlignment_Master,help={"Select the reference trace to which all other traces should be aligned to"}
	PopupMenu popup_TimeAlignment_Master,userdata(tabnum)=  "0"
	PopupMenu popup_TimeAlignment_Master,userdata(tabcontrol)=  "Settings"
	PopupMenu popup_TimeAlignment_Master,userdata(ResizeControlsInfo)= A"!!,D;!!#A.!!#@j!!#<Pz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	PopupMenu popup_TimeAlignment_Master,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu popup_TimeAlignment_Master,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu popup_TimeAlignment_Master,mode=1,popvalue="AD0",value= #"\"\""
	Button button_Calculation_RestoreData,pos={151.00,210.00},size={75.00,24.00},title="Restore"
	Button button_Calculation_RestoreData,help={"Restore the data in its pristine state without any modifications"}
	Button button_Calculation_RestoreData,userdata(tabnum)=  "0"
	Button button_Calculation_RestoreData,userdata(tabcontrol)=  "Settings"
	Button button_Calculation_RestoreData,userdata(ResizeControlsInfo)= A"!!,G&!!#Aa!!#?O!!#=#z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	Button button_Calculation_RestoreData,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button button_Calculation_RestoreData,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	Button button_BrowserSettings_Export,pos={82.00,333.00},size={99.00,24.00},proc=SB_ButtonProc_ExportTraces,title="Export Traces"
	Button button_BrowserSettings_Export,help={"Export the traces for further processing"}
	Button button_BrowserSettings_Export,userdata(tabnum)=  "0"
	Button button_BrowserSettings_Export,userdata(tabcontrol)=  "Settings"
	Button button_BrowserSettings_Export,userdata(ResizeControlsInfo)= A"!!,E\\!!#B`J,hpU!!#=#z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	Button button_BrowserSettings_Export,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	Button button_BrowserSettings_Export,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	GroupBox group_timealignment,pos={28.00,87.00},size={285.00,99.00},title="Time Alignment"
	GroupBox group_timealignment,userdata(tabnum)=  "0"
	GroupBox group_timealignment,userdata(tabcontrol)=  "Settings"
	GroupBox group_timealignment,userdata(ResizeControlsInfo)= A"!!,C<!!#?g!!#BHJ,hpUz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	GroupBox group_timealignment,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	GroupBox group_timealignment,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	Slider slider_BrowserSettings_dDAQ,pos={316.00,36.00},size={56.00,300.00},disable=2
	Slider slider_BrowserSettings_dDAQ,help={"Allows to view only regions from the selected headstage (oodDAQ) resp. the selected headstage (dDAQ). Choose -1 to display all."}
	Slider slider_BrowserSettings_dDAQ,userdata(tabnum)=  "0"
	Slider slider_BrowserSettings_dDAQ,userdata(tabcontrol)=  "Settings"
	Slider slider_BrowserSettings_dDAQ,userdata(ResizeControlsInfo)= A"!!,HXJ,hnI!!#>n!!#BPz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	Slider slider_BrowserSettings_dDAQ,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Slider slider_BrowserSettings_dDAQ,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	Slider slider_BrowserSettings_dDAQ,limits={-1,7,1},value= -1
	CheckBox check_SweepControl_HideSweep,pos={253.00,60.00},size={41.00,15.00},title="Hide"
	CheckBox check_SweepControl_HideSweep,help={"Hide sweep traces. Usually combined with \"Average traces\"."}
	CheckBox check_SweepControl_HideSweep,userdata(tabnum)=  "0"
	CheckBox check_SweepControl_HideSweep,userdata(tabcontrol)=  "Settings"
	CheckBox check_SweepControl_HideSweep,userdata(ResizeControlsInfo)= A"!!,H7!!#?)!!#>2!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_SweepControl_HideSweep,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_SweepControl_HideSweep,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_SweepControl_HideSweep,value= 0
	CheckBox check_BrowserSettings_splitTTL,pos={253.00,36.00},size={58.00,15.00},title="sep. TTL"
	CheckBox check_BrowserSettings_splitTTL,help={"Display the TTL channel data as single traces for each TTL bit"}
	CheckBox check_BrowserSettings_splitTTL,userdata(tabnum)=  "0"
	CheckBox check_BrowserSettings_splitTTL,userdata(tabcontrol)=  "Settings"
	CheckBox check_BrowserSettings_splitTTL,userdata(ResizeControlsInfo)= A"!!,H7!!#=s!!#?!!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_BrowserSettings_splitTTL,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_BrowserSettings_splitTTL,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_BrowserSettings_splitTTL,value= 0
	PopupMenu popup_DB_lockedDevices,pos={24.00,303.00},size={205.00,19.00},bodyWidth=100,proc=DB_PopMenuProc_LockDBtoDevice,title="Device assignment:"
	PopupMenu popup_DB_lockedDevices,help={"Select a data acquistion device to display data"}
	PopupMenu popup_DB_lockedDevices,userdata(tabnum)=  "0"
	PopupMenu popup_DB_lockedDevices,userdata(tabcontrol)=  "Settings"
	PopupMenu popup_DB_lockedDevices,userdata(ResizeControlsInfo)= A"!!,Bq!!#BQJ,hr2!!#<Pz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	PopupMenu popup_DB_lockedDevices,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu popup_DB_lockedDevices,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu popup_DB_lockedDevices,mode=2,popvalue="- none -",value= #"DB_GetAllDevicesWithData()"
	GroupBox group_sweepFormula,pos={3.00,27.00},size={392.00,375.00},disable=1,title="SweepFormula"
	GroupBox group_sweepFormula,userdata(tabnum)=  "5"
	GroupBox group_sweepFormula,userdata(tabcontrol)=  "Settings"
	GroupBox group_sweepFormula,userdata(ResizeControlsInfo)= A"!!,>M!!#=;!!#C'J,hsKz!!#](Aon#azzzzzzzzzzzzzz!!#o2B4uAeBk2=!z"
	GroupBox group_sweepFormula,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	GroupBox group_sweepFormula,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_sweepFormula_parseResult,pos={118.00,378.00},size={255.00,18.00},disable=1,title="◀"
	SetVariable setvar_sweepFormula_parseResult,help={"Error Message from Formula Parsing"}
	SetVariable setvar_sweepFormula_parseResult,userdata(tabnum)=  "5"
	SetVariable setvar_sweepFormula_parseResult,userdata(tabcontrol)=  "Settings"
	SetVariable setvar_sweepFormula_parseResult,userdata(ResizeControlsInfo)= A"!!,FO!!#C!J,hrd!!#<Hz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	SetVariable setvar_sweepFormula_parseResult,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#?(FEDG<zzzzzzzzzzz"
	SetVariable setvar_sweepFormula_parseResult,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_sweepFormula_parseResult,frame=0
	SetVariable setvar_sweepFormula_parseResult,limits={-inf,inf,0},value= root:MIES:HardwareDevices:ITC18USB:Device0:DataBrowser:sweepFormulaParseResult,noedit= 1,live= 1
	ValDisplay status_sweepFormula_parser,pos={376.00,381.00},size={10.00,8.00},bodyWidth=10,disable=1
	ValDisplay status_sweepFormula_parser,help={"Current parsing status of the entered formula."}
	ValDisplay status_sweepFormula_parser,userdata(tabnum)=  "5"
	ValDisplay status_sweepFormula_parser,userdata(tabcontrol)=  "Settings"
	ValDisplay status_sweepFormula_parser,userdata(ResizeControlsInfo)= A"!!,I!J,hsN!!#;-!!#:bz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	ValDisplay status_sweepFormula_parser,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#?(FEDG<zzzzzzzzzzz"
	ValDisplay status_sweepFormula_parser,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	ValDisplay status_sweepFormula_parser,limits={-1,1,0},barmisc={0,0},mode= 1,highColor= (0,65535,0),lowColor= (0,0,0),zeroColor= (65535,0,0)
	ValDisplay status_sweepFormula_parser,value= #"root:MIES:HardwareDevices:ITC18USB:Device0:DataBrowser:sweepFormulaParse == 0"
	Button button_sweepFormula_display,pos={4.00,375.00},size={55.00,22.00},disable=1,proc=button_sweepFormula_display,title="Display"
	Button button_sweepFormula_display,userdata(tabnum)=  "5"
	Button button_sweepFormula_display,userdata(tabcontrol)=  "Settings"
	Button button_sweepFormula_display,userdata(ResizeControlsInfo)= A"!!,?8!!#Bu!!#>j!!#<hz!!#](Aon#azzzzzzzzzzzzzz!!#](Aon#SBk2=!z"
	Button button_sweepFormula_display,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#?(FEDG<zzzzzzzzzzz"
	Button button_sweepFormula_display,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	Button button_sweepFormula_check,pos={61.00,375.00},size={55.00,22.00},disable=1,proc=button_sweepFormula_check,title="Check"
	Button button_sweepFormula_check,userdata(tabnum)=  "5"
	Button button_sweepFormula_check,userdata(tabcontrol)=  "Settings"
	Button button_sweepFormula_check,userdata(ResizeControlsInfo)= A"!!,E.!!#Bu!!#>j!!#<hz!!#](Aon#azzzzzzzzzzzzzz!!#](Aon#SBk2=!z"
	Button button_sweepFormula_check,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#?(FEDG<zzzzzzzzzzz"
	Button button_sweepFormula_check,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	TabControl SF_InfoTab,pos={7.00,46.00},size={383.00,324.00},disable=1,proc=SF_TabProc_Formula
	TabControl SF_InfoTab,userdata(currenttab)=  "0",userdata(tabnum)=  "5"
	TabControl SF_InfoTab,userdata(tabcontrol)=  "Settings"
	TabControl SF_InfoTab,userdata(ResizeControlsInfo)= A"!!,@C!!#>F!!#C#!!#B[J,fQL!!#](Aon#azzzzzzzzzzzzzz!!#o2B4uAeBk2=!z"
	TabControl SF_InfoTab,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	TabControl SF_InfoTab,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	TabControl SF_InfoTab,tabLabel(0)="Formula",tabLabel(1)="JSON"
	TabControl SF_InfoTab,tabLabel(2)="Help",value= 0
	ListBox list_dashboard,pos={3.00,90.00},size={387.00,312.00},disable=1,proc=AD_ListBoxProc
	ListBox list_dashboard,userdata(tabnum)=  "7",userdata(tabcontrol)=  "Settings"
	ListBox list_dashboard,userdata(ResizeControlsInfo)= A"!!,>M!!#?m!!#C%!!#BUJ,fQL!!#](Aon\"Qzzzzzzzzzzzzzz!!#o2B4uAezz"
	ListBox list_dashboard,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	ListBox list_dashboard,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	ListBox list_dashboard,fSize=12,mode= 1,selRow= -1,widths={141,109,77}
	ListBox list_dashboard,userColumnResize= 1
	GroupBox group_enable_dashboard,pos={3.00,27.00},size={390.00,57.00},disable=1
	GroupBox group_enable_dashboard,userdata(tabnum)=  "7"
	GroupBox group_enable_dashboard,userdata(tabcontrol)=  "Settings"
	GroupBox group_enable_dashboard,userdata(ResizeControlsInfo)= A"!!,>M!!#=;!!#C&J,hoHz!!#](Aon\"Qzzzzzzzzzzzzzz!!#o2B4uAezz"
	GroupBox group_enable_dashboard,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	GroupBox group_enable_dashboard,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_BrowserSettings_DB_Passed,pos={175.00,39.00},size={52.00,15.00},disable=1,proc=AD_CheckProc_PassedSweeps,title="Passed"
	CheckBox check_BrowserSettings_DB_Passed,help={"Show passed sweeps on double click into ListBox "}
	CheckBox check_BrowserSettings_DB_Passed,userdata(tabnum)=  "7"
	CheckBox check_BrowserSettings_DB_Passed,userdata(tabcontrol)=  "Settings"
	CheckBox check_BrowserSettings_DB_Passed,userdata(ResizeControlsInfo)= A"!!,G>!!#>*!!#=s!!#;Mz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_BrowserSettings_DB_Passed,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_BrowserSettings_DB_Passed,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_BrowserSettings_DB_Passed,value= 0
	CheckBox check_BrowserSettings_DB_Failed,pos={175.00,60.00},size={47.00,15.00},disable=1,proc=AD_CheckProc_FailedSweeps,title="Failed"
	CheckBox check_BrowserSettings_DB_Failed,help={"Show failed sweeps on double click into ListBox "}
	CheckBox check_BrowserSettings_DB_Failed,userdata(tabnum)=  "7"
	CheckBox check_BrowserSettings_DB_Failed,userdata(tabcontrol)=  "Settings"
	CheckBox check_BrowserSettings_DB_Failed,userdata(ResizeControlsInfo)= A"!!,G>!!#?)!!#=g!!#;Mz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_BrowserSettings_DB_Failed,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_BrowserSettings_DB_Failed,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_BrowserSettings_DB_Failed,value= 0
	SetWindow kwTopWin,hook(ResizeControls)=ResizeControls#ResizeControlsHook
	SetWindow kwTopWin,userdata(ResizeControlsInfo)= A"!!*'\"z!!#C*J,hs[zzzzzzzzzzzzzzzzzzzzz"
	SetWindow kwTopWin,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzzzzzzzzzzzzzzz"
	SetWindow kwTopWin,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzzzzzzzzz!!!"
	Execute/Q/Z "SetWindow kwTopWin sizeLimit={279,330,inf,inf}" // sizeLimit requires Igor 7 or later
	NewNotebook /F=0 /N=sweepFormula_json /W=(12,72,379,358) /HOST=# /V=0 
	Notebook kwTopWin, defaultTab=20, autoSave= 1, magnification=100
	Notebook kwTopWin font="Lucida Console", fSize=11, fStyle=0, textRGB=(0,0,0)
	Notebook kwTopWin, zdata= "GaqDU%ejN7!Z)%D?io>lbN?PWL]d_/WWX="
	Notebook kwTopWin, zdataEnd= 1
	SetWindow kwTopWin,hook(ResizeControls)=ResizeControls#ResizeControlsHook
	SetWindow kwTopWin,userdata(tabnum)=  "1"
	SetWindow kwTopWin,userdata(tabcontrol)=  "SF_InfoTab"
	SetWindow kwTopWin,userdata(ResizeControlsInfo)= A"!!,@C!!#>F!!#C#!!#B[J,fQL!!#](Aon#azzzzzzzzzzzzzz!!#o2B4uAeBk2=!z"
	SetWindow kwTopWin,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetWindow kwTopWin,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	RenameWindow #,sweepFormula_json
	SetActiveSubwindow ##
	NewNotebook /F=0 /N=sweepFormula_formula /W=(12,71,378,358) /HOST=# /V=0 
	Notebook kwTopWin, defaultTab=20, autoSave= 1, magnification=100
	Notebook kwTopWin font="Lucida Console", fSize=11, fStyle=0, textRGB=(0,0,0)
	Notebook kwTopWin, zdata= "GaqDU%ejN7!Z)ufAq0k.+RVB3m`%L;84b@(eDTF^/hJQu0.POle8`pd!HKt/oC>e#J:&.E\\%\"OX[@gX>^tR/haP,;#`7e1S=-FF#b9@W'"
	Notebook kwTopWin, zdataEnd= 1
	SetWindow kwTopWin,hook(ResizeControls)=ResizeControls#ResizeControlsHook
	SetWindow kwTopWin,userdata(tabnum)=  "0"
	SetWindow kwTopWin,userdata(tabcontrol)=  "SF_InfoTab"
	SetWindow kwTopWin,userdata(ResizeControlsInfo)= A"!!,@C!!#>F!!#C#!!#B[J,fQL!!#](Aon#azzzzzzzzzzzzzz!!#o2B4uAeBk2=!z"
	SetWindow kwTopWin,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetWindow kwTopWin,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	RenameWindow #,sweepFormula_formula
	SetActiveSubwindow ##
	NewNotebook /F=1 /N=sweepFormula_help /W=(12,74,379,353) /HOST=# /V=0 
	Notebook kwTopWin, defaultTab=36, autoSave= 1, magnification=100, showRuler=0, rulerUnits=2
	Notebook kwTopWin newRuler=Normal, justification=0, margins={0,0,253}, spacing={0,0,0}, tabs={}, rulerDefaults={"Arial",11,0,(0,0,0)}
	Notebook kwTopWin, zdata= "Gatm<9on&K)<TM1j4&'4SA7DW2OHkZBX:rT[9hUW!'RFD]%nR8NGd2f&TekH6\\u,k@:k8BDLf+.[tb$u2V6f3n#n-cn'.d0L&s[;bW@(=M,^d&8jF$.GrV>gH(Xh@)!I#En8R1'kJoMED[X<E^ut$5ls9,+H#2$FbMuNK,('e_s8A)CV)LO*$_77[`Y,V,ISd,^X8QosY'ARfr?r>:Rn0FQ.fOkfbn`JaII*)AGOYRcR:&KQo8(F\\<d;WL?opR,p\"<P5Hb7T(4/7^b#bt?%/<l%^3+dQ`UR7*PN'rLn[C\\L0"
	Notebook kwTopWin, zdata= "R$dJ)k=2\\4N:S<+A$/8I^M9BZO6&E?dZlD&H0&ZJbSJmlXB6KgO[]OkLCMn^fl2F?4J=sr[0e]0q\"l;Qq7#(>Y7m'q42Y;%!FZN:4)NVWeZf8NLUR;\\H\\R0D>Q4WID-Ta*38Q[bl),LanF%,;FFDXsJ)ALH&+F:^q],J9IsBR0/7uKR&,'u$cl_V`cE`kKlSNWki,NV.$2jfG:FDuDf%!ZjB6D.<+Gj!:HbrSCmY`T_6a3tM@7lnlV9D2R\\/Zf?;@_*b%.P-c;uE`S@b$0e24#8L.ihT2Za?F8_Y:L8f`!Pm"
	Notebook kwTopWin, zdata= "WR(U!]8*$PReLZ;eDa-OPP,%2KR0I]3=q%CPBX4Y#bOm5Xb*G\\[Ha)Ank1\"B+G<<-gVC52iH(fJWVCu<j2DN-\\5ocH#?Le-hni?r64O;/(EE3MOSJ:'ML0@1YT&4udYO(73+DOC3>,^]Ma+Vj6nc[2`8:@8FW/TFio\\eid&eqJ]mq'9h8utSBOoCg`7'Pcf4u%UH(/X]80L^oRSHl`p4>1^j!m=15]*c/V+in8>BJWDhWJP5jV>rgC0IuXEFd-HnE8;H4@KR(X<d[6nI1\\h>Lmm23Y3^Q?t\\>rX-bC/LY>eb"
	Notebook kwTopWin, zdata= "'$#r!V%#ec6u!o=5EBA:L\"$m,MXk/a.`=mBei<5W6b-CeJGTd`>BR[4P/5H4O&sr7h!C0l;L4QG0h$:1>,oc\\>pf_5LbE9QYS%>efHN(,-;rTlTI3<`h+V:F9lm\"NPYS3a@:<%.MQ5`h=7ZRU-8GfGED-&\"[;ggrRcT8UO</P:*?,d)b7fdL.c\\[5UR#d:\"!6Oa4q#;$gl*d_&o1/,U6Q/XM6PinA%C7:1D[uXU&/].r2%6f<uq50ass=8&-FP:?kpmk87cBbI`Vk*$*N5h(r\\II\\V?pkkkt5N2_7o`@9#j\\"
	Notebook kwTopWin, zdata= "@OIK0V786Zau9kL#_`)B9Pa(KUuBR!*3NL39_]%g5NZ.aQQ$fs5+>!i=oH*7n8(%t0%7n@D2O$biTcK\\-O!QT`nG2>TM9EHdN-D\"%7f^e(.bT!aM^WZcA:!u8<7m4Y0%]lR:!DlXdX%fJnC):EWbo:#CjDEo!0rmQ*!(::K2+&\"KE$UBb36n9%/_6:b>)O5fcjF,Rd]^_267A&k()Y8n]JJT=A!kA-'^&<#@NMKrnjN,7BqaRaWQ]kGr?e/\\\\i+1!+@tgZdPgUG0WR423FX)U-[ON,Y:3O4HfBTq3ACQZH&`"
	Notebook kwTopWin, zdata= "Q*]1]*RA4f>'i(]nC_7d`NHf,-X*rHP*n*a4tGUj[cb<MYjnOok'@,N]7G7*ZYh*GSu*^_D7]Njl)$l$i'D!k'+@O-L4C!`/e;[_Ln0RS4;jp$YE]DXR>B)DCjW^4A/&*X[8LGY1>5NhF4r!T(.Xu'G''A/]mo)M'?<G&EKn%<Kj0Ju!B6[)=3aWI[cpVuRJ+D!nuf08ef2J>>3T^u>A!d2.^Mso1/VK9.\"N&`nQPgE_ZKTE:\\%0U*g1fDSIsAk%@clk\"g0%d[Ib4eg:/Bl_Sl$u\"rBU:XkJ'[EXn(qb(4P9"
	Notebook kwTopWin, zdata= ",S;L=<i1RF.L%YcZ'R*6O0eXlRCa^ZCM@RU9=d6Vf&ROAg'Aa%Ib[;plba\\U-)eSboB8(O06OMh7a8poXcgsMoD2U)fd'X&WjZ*.SKck!9;Ju_r[FTD<u.GQr!3]X>`M6'LZ$N_:*QEtJqY,E>hR,`h6V5sW\"WSJA=t#cW2MQm4l<e#.b<Dp*prs<4Vh@2_&`@G[b2WDleh$HicD7]7`')mgum5B3GRN>=t(Cb<AA`-*Vht#\"PYX:E,;im(&]lt5</Y]$.G<06m6$ec\"GL1SPZ'YS5m<sD!b5'p09kEpAH0r"
	Notebook kwTopWin, zdata= "b,eJ>GP_5T2:b:3Us>rOmVqBe)3qaE1o`U,Ei;r@Z&H(kb$nC,^W_[33ZrpPA=c)Lj5o9)=hE*ak8OlSRgmTr*LLtHpcIhbA_q:mH-*`]Y`<CRhT(oPf$fjqA#U#ap@YW>:Ng>^k^]ba`+at;VHM<Y@V6j$qA5(?%/oS)C3C*U(HVmb\\lqRg9uk*teA0W=>cM+:09aB(-\\$R@jDRhdHrUSIeSTO\"P9j!fD6Tp*o;.GjkXT/&3\\\\VBT\\o3&m$&%9IAiL7?3r'YdO9e:p5+06&+@G1bR[k]FHf0J<u.Gs,3Moi"
	Notebook kwTopWin, zdata= "&JI3pflpB9)jAUpLVDNKlK:44`g1f#GB3>Uh*3=E_pLP,r9M;F72h$E[\"Xj]'/(1i.o.++lhE/3-u]7BC/K(`[7jZ,jRQuIfS0ed^Y>MrW&hoP45(00>e/.r@<\"Xa:<c[Pjk_(?%!,6ZdnCn(q/gAn79trUZtnGX/T_;&[oTI\\DuMASD\"Iqdc'^]_+WeR3Dr]ego=V7c6T,ocar13*2L5E$Ma)Rgnr?\\&a1n6BU4BTEYa:TZn35.N0<tIBq>'NISY0t[Z)'A8rr=M3ZH*"
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
