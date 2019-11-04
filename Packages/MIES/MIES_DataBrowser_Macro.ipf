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
	Display /W=(361.5,362,794.25,667.25)/K=1  as "DataBrowser"
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
	GroupBox group_properties_sweepFormula,pos={5.00,85.00},size={380.00,320.00},disable=3
	GroupBox group_properties_sweepFormula,userdata(tabnum)=  "5"
	GroupBox group_properties_sweepFormula,userdata(tabcontrol)=  "Settings"
	GroupBox group_properties_sweepFormula,userdata(ResizeControlsInfo)= A"!!,?X!!#?c!!#C#!!#BZz!!#](Aon#azzzzzzzzzzzzzz!!#o2B4uAeBk2=!z"
	GroupBox group_properties_sweepFormula,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#N3Bk1ct9jqaR6>q*JDf>[Vzzzzzzzz"
	GroupBox group_properties_sweepFormula,userdata(ResizeControlsInfo) += A"zzz!!#N3Bk1ct9jqaR6>q*8Dfg)>D#aP9zzzzzzzzzz!!!"
	GroupBox group_calc,pos={24.00,195.00},size={288.00,51.00}
	GroupBox group_calc,userdata(tabnum)=  "0",userdata(tabcontrol)=  "Settings"
	GroupBox group_calc,userdata(ResizeControlsInfo)= A"!!,C$!!#AR!!#BJ!!#>Zz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	GroupBox group_calc,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	GroupBox group_calc,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	TabControl Settings,pos={0.00,0.00},size={392.00,21.00},proc=ACL_DisplayTab
	TabControl Settings,userdata(currenttab)=  "0"
	TabControl Settings,userdata(ResizeControlsInfo)= A"!!*'\"z!!#C)!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#o2B4uAeBE3-fz"
	TabControl Settings,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	TabControl Settings,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	TabControl Settings,tabLabel(0)="Settings",tabLabel(1)="OVS",tabLabel(2)="CS"
	TabControl Settings,tabLabel(3)="AR",tabLabel(4)="PA",tabLabel(5)="SF"
	TabControl Settings,tabLabel(6)="Note",tabLabel(7)="Dashboard",value= 0
	ListBox list_of_ranges,pos={81.00,198.00},size={215.00,201.00},disable=3,proc=OVS_MainListBoxProc
	ListBox list_of_ranges,help={"Select sweeps for overlay; The second column (\"Headstages\") allows to ignore some headstages for the graphing. Syntax is a semicolon \";\" separated list of subranges, e.g. \"0\", \"0,2\", \"1;4;2\""}
	ListBox list_of_ranges,userdata(tabnum)=  "1",userdata(tabcontrol)=  "Settings"
	ListBox list_of_ranges,userdata(ResizeControlsInfo)= A"!!,E\\!!#AU!!#Af!!#AXz!!#](Aon\"Qzzzzzzzzzzzzzz!!#o2B4uAezz"
	ListBox list_of_ranges,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	ListBox list_of_ranges,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	ListBox list_of_ranges,widths={50,50}
	PopupMenu popup_overlaySweeps_select,pos={119.00,99.00},size={143.00,19.00},bodyWidth=109,disable=3,proc=OVS_PopMenuProc_Select,title="Select"
	PopupMenu popup_overlaySweeps_select,help={"Select sweeps according to various properties"}
	PopupMenu popup_overlaySweeps_select,userdata(tabnum)=  "1"
	PopupMenu popup_overlaySweeps_select,userdata(tabcontrol)=  "Settings"
	PopupMenu popup_overlaySweeps_select,userdata(ResizeControlsInfo)= A"!!,FS!!#@*!!#@s!!#<Pz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	PopupMenu popup_overlaySweeps_select,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu popup_overlaySweeps_select,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu popup_overlaySweeps_select,mode=1,popvalue="- none -",value= #"\"\""
	CheckBox check_overlaySweeps_disableHS,pos={68.00,159.00},size={121.00,15.00},disable=3,proc=OVS_CheckBoxProc_HS_Select,title="Headstage Removal"
	CheckBox check_overlaySweeps_disableHS,help={"Toggle headstage removal"}
	CheckBox check_overlaySweeps_disableHS,userdata(tabnum)=  "1"
	CheckBox check_overlaySweeps_disableHS,userdata(tabcontrol)=  "Settings"
	CheckBox check_overlaySweeps_disableHS,userdata(ResizeControlsInfo)= A"!!,EB!!#A.!!#@V!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_overlaySweeps_disableHS,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_overlaySweeps_disableHS,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_overlaySweeps_disableHS,value= 0
	CheckBox check_overlaySweeps_non_commula,pos={68.00,180.00},size={154.00,15.00},disable=3,title="Non-commulative update"
	CheckBox check_overlaySweeps_non_commula,help={"If \"Display Last sweep acquired\" is checked, this checkbox here allows to only add the newly acquired sweep and will remove the currently added last sweep."}
	CheckBox check_overlaySweeps_non_commula,userdata(tabcontrol)=  "Settings"
	CheckBox check_overlaySweeps_non_commula,userdata(tabnum)=  "1"
	CheckBox check_overlaySweeps_non_commula,userdata(ResizeControlsInfo)= A"!!,EB!!#AC!!#A)!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_overlaySweeps_non_commula,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_overlaySweeps_non_commula,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_overlaySweeps_non_commula,value= 0
	SetVariable setvar_overlaySweeps_offset,pos={106.00,126.00},size={81.00,18.00},bodyWidth=45,disable=3,proc=OVS_SetVarProc_SelectionRange,title="Offset"
	SetVariable setvar_overlaySweeps_offset,help={"Offsets the first selected sweep from the selection menu"}
	SetVariable setvar_overlaySweeps_offset,userdata(tabnum)=  "1"
	SetVariable setvar_overlaySweeps_offset,userdata(tabcontrol)=  "Settings"
	SetVariable setvar_overlaySweeps_offset,userdata(ResizeControlsInfo)= A"!!,F9!!#@`!!#?[!!#<Hz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	SetVariable setvar_overlaySweeps_offset,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_overlaySweeps_offset,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_overlaySweeps_offset,limits={0,inf,1},value= _NUM:0
	SetVariable setvar_overlaySweeps_step,pos={193.00,126.00},size={72.00,18.00},bodyWidth=45,disable=3,proc=OVS_SetVarProc_SelectionRange,title="Step"
	SetVariable setvar_overlaySweeps_step,help={"Selects every `step` sweep from the selection menu"}
	SetVariable setvar_overlaySweeps_step,userdata(tabnum)=  "1"
	SetVariable setvar_overlaySweeps_step,userdata(tabcontrol)=  "Settings"
	SetVariable setvar_overlaySweeps_step,userdata(ResizeControlsInfo)= A"!!,GQ!!#@`!!#?I!!#<Hz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	SetVariable setvar_overlaySweeps_step,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_overlaySweeps_step,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_overlaySweeps_step,limits={1,inf,1},value= _NUM:1
	GroupBox group_enable_sweeps,pos={5.00,25.00},size={380.00,50.00},disable=1,title="Overlay Sweeps"
	GroupBox group_enable_sweeps,userdata(tabnum)=  "1"
	GroupBox group_enable_sweeps,userdata(tabcontrol)=  "Settings"
	GroupBox group_enable_sweeps,userdata(ResizeControlsInfo)= A"!!,?X!!#=+!!#C#!!#>Vz!!#](Aon\"Qzzzzzzzzzzzzzz!!#o2B4uAezz"
	GroupBox group_enable_sweeps,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:DuaGlAStpcCh5qOGZ8U#zzzzzzzz"
	GroupBox group_enable_sweeps,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafn!,c4SCh5qOGX?=jFDl!rzzzzzzzzzz!!!"
	GroupBox group_enable_channels,pos={5.00,25.00},size={380.00,380.00},disable=1,title="Channel Selection"
	GroupBox group_enable_channels,userdata(tabnum)=  "2"
	GroupBox group_enable_channels,userdata(tabcontrol)=  "Settings"
	GroupBox group_enable_channels,userdata(ResizeControlsInfo)= A"!!,?X!!#=+!!#C#!!#C#z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	GroupBox group_enable_channels,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	GroupBox group_enable_channels,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	GroupBox group_enable_artifact,pos={5.00,25.00},size={380.00,50.00},disable=1,title="Artefact Removal"
	GroupBox group_enable_artifact,userdata(tabnum)=  "3"
	GroupBox group_enable_artifact,userdata(tabcontrol)=  "Settings"
	GroupBox group_enable_artifact,userdata(ResizeControlsInfo)= A"!!,?X!!#=+!!#C#!!#>Vz!!#](Aon#azzzzzzzzzzzzzz!!#o2B4uAeBk2=!z"
	GroupBox group_enable_artifact,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	GroupBox group_enable_artifact,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	GroupBox group_properties_sweeps,pos={5.00,85.00},size={380.00,320.00},disable=3
	GroupBox group_properties_sweeps,userdata(tabnum)=  "1"
	GroupBox group_properties_sweeps,userdata(tabcontrol)=  "Settings"
	GroupBox group_properties_sweeps,userdata(ResizeControlsInfo)= A"!!,?X!!#?c!!#C#!!#BZz!!#](Aon\"Qzzzzzzzzzzzzzz!!#o2B4uAezz"
	GroupBox group_properties_sweeps,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	GroupBox group_properties_sweeps,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	GroupBox group_properties_artefact,pos={5.00,85.00},size={380.00,320.00},disable=3
	GroupBox group_properties_artefact,userdata(tabnum)=  "3"
	GroupBox group_properties_artefact,userdata(tabcontrol)=  "Settings"
	GroupBox group_properties_artefact,userdata(ResizeControlsInfo)= A"!!,?X!!#?c!!#C#!!#BZz!!#](Aon\"Qzzzzzzzzzzzzzz!!#o2B4uAezz"
	GroupBox group_properties_artefact,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	GroupBox group_properties_artefact,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	GroupBox group_channelSel_DA,pos={105.00,42.00},size={42.00,198.00},disable=1,title="DA"
	GroupBox group_channelSel_DA,userdata(tabnum)=  "2"
	GroupBox group_channelSel_DA,userdata(tabcontrol)=  "Settings"
	GroupBox group_channelSel_DA,userdata(ResizeControlsInfo)= A"!!,F7!!#>6!!#>6!!#AUz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	GroupBox group_channelSel_DA,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	GroupBox group_channelSel_DA,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	GroupBox group_properties_pulse,pos={5.00,85.00},size={380.00,320.00},disable=3
	GroupBox group_properties_pulse,userdata(tabnum)=  "4"
	GroupBox group_properties_pulse,userdata(tabcontrol)=  "Settings"
	GroupBox group_properties_pulse,userdata(ResizeControlsInfo)= A"!!,?X!!#?c!!#C#!!#BZz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	GroupBox group_properties_pulse,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	GroupBox group_properties_pulse,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	GroupBox group_enable_pulse,pos={5.00,25.00},size={380.00,50.00},disable=1,title="Pulse Averaging"
	GroupBox group_enable_pulse,userdata(tabnum)=  "4"
	GroupBox group_enable_pulse,userdata(tabcontrol)=  "Settings"
	GroupBox group_enable_pulse,userdata(ResizeControlsInfo)= A"!!,?X!!#=+!!#C#!!#>Vz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	GroupBox group_enable_pulse,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	GroupBox group_enable_pulse,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_DA_0,pos={117.00,60.00},size={22.00,15.00},disable=1,proc=DB_CheckProc_ChangedSetting,title="0"
	CheckBox check_channelSel_DA_0,userdata(tabnum)=  "2"
	CheckBox check_channelSel_DA_0,userdata(tabcontrol)=  "Settings"
	CheckBox check_channelSel_DA_0,userdata(ResizeControlsInfo)= A"!!,FO!!#?)!!#<h!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_DA_0,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_DA_0,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_DA_0,value= 1
	CheckBox check_channelSel_DA_1,pos={117.00,81.00},size={22.00,15.00},disable=1,proc=DB_CheckProc_ChangedSetting,title="1"
	CheckBox check_channelSel_DA_1,userdata(tabnum)=  "2"
	CheckBox check_channelSel_DA_1,userdata(tabcontrol)=  "Settings"
	CheckBox check_channelSel_DA_1,userdata(ResizeControlsInfo)= A"!!,FO!!#?[!!#<h!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_DA_1,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_DA_1,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_DA_1,value= 1
	CheckBox check_channelSel_DA_2,pos={117.00,102.00},size={22.00,15.00},disable=1,proc=DB_CheckProc_ChangedSetting,title="2"
	CheckBox check_channelSel_DA_2,userdata(tabnum)=  "2"
	CheckBox check_channelSel_DA_2,userdata(tabcontrol)=  "Settings"
	CheckBox check_channelSel_DA_2,userdata(ResizeControlsInfo)= A"!!,FO!!#@0!!#<h!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_DA_2,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_DA_2,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_DA_2,value= 1
	CheckBox check_channelSel_DA_3,pos={117.00,123.00},size={22.00,15.00},disable=1,proc=DB_CheckProc_ChangedSetting,title="3"
	CheckBox check_channelSel_DA_3,userdata(tabnum)=  "2"
	CheckBox check_channelSel_DA_3,userdata(tabcontrol)=  "Settings"
	CheckBox check_channelSel_DA_3,userdata(ResizeControlsInfo)= A"!!,FO!!#@Z!!#<h!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_DA_3,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_DA_3,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_DA_3,value= 1
	CheckBox check_channelSel_DA_4,pos={117.00,144.00},size={22.00,15.00},disable=1,proc=DB_CheckProc_ChangedSetting,title="4"
	CheckBox check_channelSel_DA_4,userdata(tabnum)=  "2"
	CheckBox check_channelSel_DA_4,userdata(tabcontrol)=  "Settings"
	CheckBox check_channelSel_DA_4,userdata(ResizeControlsInfo)= A"!!,FO!!#@t!!#<h!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_DA_4,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_DA_4,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_DA_4,value= 1
	CheckBox check_channelSel_DA_5,pos={117.00,165.00},size={22.00,15.00},disable=1,proc=DB_CheckProc_ChangedSetting,title="5"
	CheckBox check_channelSel_DA_5,userdata(tabnum)=  "2"
	CheckBox check_channelSel_DA_5,userdata(tabcontrol)=  "Settings"
	CheckBox check_channelSel_DA_5,userdata(ResizeControlsInfo)= A"!!,FO!!#A4!!#<h!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_DA_5,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_DA_5,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_DA_5,value= 1
	CheckBox check_channelSel_DA_6,pos={117.00,186.00},size={22.00,15.00},disable=1,proc=DB_CheckProc_ChangedSetting,title="6"
	CheckBox check_channelSel_DA_6,userdata(tabnum)=  "2"
	CheckBox check_channelSel_DA_6,userdata(tabcontrol)=  "Settings"
	CheckBox check_channelSel_DA_6,userdata(ResizeControlsInfo)= A"!!,FO!!#AI!!#<h!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_DA_6,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_DA_6,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_DA_6,value= 1
	CheckBox check_channelSel_DA_7,pos={117.00,207.00},size={22.00,15.00},disable=1,proc=DB_CheckProc_ChangedSetting,title="7"
	CheckBox check_channelSel_DA_7,userdata(tabnum)=  "2"
	CheckBox check_channelSel_DA_7,userdata(tabcontrol)=  "Settings"
	CheckBox check_channelSel_DA_7,userdata(ResizeControlsInfo)= A"!!,FO!!#A^!!#<h!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_DA_7,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_DA_7,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_DA_7,value= 1
	GroupBox group_channelSel_HEADSTAGE,pos={45.00,42.00},size={42.00,198.00},disable=1,title="HS"
	GroupBox group_channelSel_HEADSTAGE,userdata(tabnum)=  "2"
	GroupBox group_channelSel_HEADSTAGE,userdata(tabcontrol)=  "Settings"
	GroupBox group_channelSel_HEADSTAGE,userdata(ResizeControlsInfo)= A"!!,DC!!#>6!!#>6!!#AUz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	GroupBox group_channelSel_HEADSTAGE,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	GroupBox group_channelSel_HEADSTAGE,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_HEADSTAGE_0,pos={54.00,60.00},size={22.00,15.00},disable=1,proc=DB_CheckProc_ChangedSetting,title="0"
	CheckBox check_channelSel_HEADSTAGE_0,userdata(tabnum)=  "2"
	CheckBox check_channelSel_HEADSTAGE_0,userdata(tabcontrol)=  "Settings"
	CheckBox check_channelSel_HEADSTAGE_0,userdata(ResizeControlsInfo)= A"!!,Dg!!#?)!!#<h!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_HEADSTAGE_0,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_HEADSTAGE_0,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_HEADSTAGE_0,value= 1
	CheckBox check_channelSel_HEADSTAGE_1,pos={54.00,81.00},size={22.00,15.00},disable=1,proc=DB_CheckProc_ChangedSetting,title="1"
	CheckBox check_channelSel_HEADSTAGE_1,userdata(tabnum)=  "2"
	CheckBox check_channelSel_HEADSTAGE_1,userdata(tabcontrol)=  "Settings"
	CheckBox check_channelSel_HEADSTAGE_1,userdata(ResizeControlsInfo)= A"!!,Dg!!#?[!!#<h!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_HEADSTAGE_1,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_HEADSTAGE_1,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_HEADSTAGE_1,value= 1
	CheckBox check_channelSel_HEADSTAGE_2,pos={54.00,102.00},size={22.00,15.00},disable=1,proc=DB_CheckProc_ChangedSetting,title="2"
	CheckBox check_channelSel_HEADSTAGE_2,userdata(tabnum)=  "2"
	CheckBox check_channelSel_HEADSTAGE_2,userdata(tabcontrol)=  "Settings"
	CheckBox check_channelSel_HEADSTAGE_2,userdata(ResizeControlsInfo)= A"!!,Dg!!#@0!!#<h!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_HEADSTAGE_2,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_HEADSTAGE_2,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_HEADSTAGE_2,value= 1
	CheckBox check_channelSel_HEADSTAGE_3,pos={54.00,123.00},size={22.00,15.00},disable=1,proc=DB_CheckProc_ChangedSetting,title="3"
	CheckBox check_channelSel_HEADSTAGE_3,userdata(tabnum)=  "2"
	CheckBox check_channelSel_HEADSTAGE_3,userdata(tabcontrol)=  "Settings"
	CheckBox check_channelSel_HEADSTAGE_3,userdata(ResizeControlsInfo)= A"!!,Dg!!#@Z!!#<h!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_HEADSTAGE_3,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_HEADSTAGE_3,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_HEADSTAGE_3,value= 1
	CheckBox check_channelSel_HEADSTAGE_4,pos={54.00,144.00},size={22.00,15.00},disable=1,proc=DB_CheckProc_ChangedSetting,title="4"
	CheckBox check_channelSel_HEADSTAGE_4,userdata(tabnum)=  "2"
	CheckBox check_channelSel_HEADSTAGE_4,userdata(tabcontrol)=  "Settings"
	CheckBox check_channelSel_HEADSTAGE_4,userdata(ResizeControlsInfo)= A"!!,Dg!!#@t!!#<h!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_HEADSTAGE_4,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_HEADSTAGE_4,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_HEADSTAGE_4,value= 1
	CheckBox check_channelSel_HEADSTAGE_5,pos={54.00,165.00},size={22.00,15.00},disable=1,proc=DB_CheckProc_ChangedSetting,title="5"
	CheckBox check_channelSel_HEADSTAGE_5,userdata(tabnum)=  "2"
	CheckBox check_channelSel_HEADSTAGE_5,userdata(tabcontrol)=  "Settings"
	CheckBox check_channelSel_HEADSTAGE_5,userdata(ResizeControlsInfo)= A"!!,Dg!!#A4!!#<h!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_HEADSTAGE_5,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_HEADSTAGE_5,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_HEADSTAGE_5,value= 1
	CheckBox check_channelSel_HEADSTAGE_6,pos={54.00,186.00},size={22.00,15.00},disable=1,proc=DB_CheckProc_ChangedSetting,title="6"
	CheckBox check_channelSel_HEADSTAGE_6,userdata(tabnum)=  "2"
	CheckBox check_channelSel_HEADSTAGE_6,userdata(tabcontrol)=  "Settings"
	CheckBox check_channelSel_HEADSTAGE_6,userdata(ResizeControlsInfo)= A"!!,Dg!!#AI!!#<h!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_HEADSTAGE_6,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_HEADSTAGE_6,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_HEADSTAGE_6,value= 1
	CheckBox check_channelSel_HEADSTAGE_7,pos={54.00,207.00},size={22.00,15.00},disable=1,proc=DB_CheckProc_ChangedSetting,title="7"
	CheckBox check_channelSel_HEADSTAGE_7,userdata(tabnum)=  "2"
	CheckBox check_channelSel_HEADSTAGE_7,userdata(tabcontrol)=  "Settings"
	CheckBox check_channelSel_HEADSTAGE_7,userdata(ResizeControlsInfo)= A"!!,Dg!!#A^!!#<h!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_HEADSTAGE_7,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_HEADSTAGE_7,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_HEADSTAGE_7,value= 1
	GroupBox group_channelSel_AD,pos={168.00,42.00},size={45.00,360.00},disable=1,title="AD"
	GroupBox group_channelSel_AD,userdata(tabnum)=  "2"
	GroupBox group_channelSel_AD,userdata(tabcontrol)=  "Settings"
	GroupBox group_channelSel_AD,userdata(ResizeControlsInfo)= A"!!,G8!!#>6!!#>B!!#Bnz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	GroupBox group_channelSel_AD,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	GroupBox group_channelSel_AD,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_AD_0,pos={174.00,60.00},size={22.00,15.00},disable=1,proc=DB_CheckProc_ChangedSetting,title="0"
	CheckBox check_channelSel_AD_0,userdata(tabnum)=  "2"
	CheckBox check_channelSel_AD_0,userdata(tabcontrol)=  "Settings"
	CheckBox check_channelSel_AD_0,userdata(ResizeControlsInfo)= A"!!,G>!!#?)!!#<h!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_AD_0,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_AD_0,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_AD_0,value= 1
	CheckBox check_channelSel_AD_1,pos={174.00,81.00},size={22.00,15.00},disable=1,proc=DB_CheckProc_ChangedSetting,title="1"
	CheckBox check_channelSel_AD_1,userdata(tabnum)=  "2"
	CheckBox check_channelSel_AD_1,userdata(tabcontrol)=  "Settings"
	CheckBox check_channelSel_AD_1,userdata(ResizeControlsInfo)= A"!!,G>!!#?[!!#<h!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_AD_1,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_AD_1,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_AD_1,value= 1
	CheckBox check_channelSel_AD_2,pos={174.00,102.00},size={22.00,15.00},disable=1,proc=DB_CheckProc_ChangedSetting,title="2"
	CheckBox check_channelSel_AD_2,userdata(tabnum)=  "2"
	CheckBox check_channelSel_AD_2,userdata(tabcontrol)=  "Settings"
	CheckBox check_channelSel_AD_2,userdata(ResizeControlsInfo)= A"!!,G>!!#@0!!#<h!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_AD_2,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_AD_2,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_AD_2,value= 1
	CheckBox check_channelSel_AD_3,pos={174.00,123.00},size={22.00,15.00},disable=1,proc=DB_CheckProc_ChangedSetting,title="3"
	CheckBox check_channelSel_AD_3,userdata(tabnum)=  "2"
	CheckBox check_channelSel_AD_3,userdata(tabcontrol)=  "Settings"
	CheckBox check_channelSel_AD_3,userdata(ResizeControlsInfo)= A"!!,G>!!#@Z!!#<h!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_AD_3,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_AD_3,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_AD_3,value= 1
	CheckBox check_channelSel_AD_4,pos={174.00,144.00},size={22.00,15.00},disable=1,proc=DB_CheckProc_ChangedSetting,title="4"
	CheckBox check_channelSel_AD_4,userdata(tabnum)=  "2"
	CheckBox check_channelSel_AD_4,userdata(tabcontrol)=  "Settings"
	CheckBox check_channelSel_AD_4,userdata(ResizeControlsInfo)= A"!!,G>!!#@t!!#<h!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_AD_4,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_AD_4,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_AD_4,value= 1
	CheckBox check_channelSel_AD_5,pos={174.00,165.00},size={22.00,15.00},disable=1,proc=DB_CheckProc_ChangedSetting,title="5"
	CheckBox check_channelSel_AD_5,userdata(tabnum)=  "2"
	CheckBox check_channelSel_AD_5,userdata(tabcontrol)=  "Settings"
	CheckBox check_channelSel_AD_5,userdata(ResizeControlsInfo)= A"!!,G>!!#A4!!#<h!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_AD_5,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_AD_5,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_AD_5,value= 1
	CheckBox check_channelSel_AD_6,pos={174.00,186.00},size={22.00,15.00},disable=1,proc=DB_CheckProc_ChangedSetting,title="6"
	CheckBox check_channelSel_AD_6,userdata(tabnum)=  "2"
	CheckBox check_channelSel_AD_6,userdata(tabcontrol)=  "Settings"
	CheckBox check_channelSel_AD_6,userdata(ResizeControlsInfo)= A"!!,G>!!#AI!!#<h!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_AD_6,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_AD_6,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_AD_6,value= 1
	CheckBox check_channelSel_AD_7,pos={174.00,207.00},size={22.00,15.00},disable=1,proc=DB_CheckProc_ChangedSetting,title="7"
	CheckBox check_channelSel_AD_7,userdata(tabnum)=  "2"
	CheckBox check_channelSel_AD_7,userdata(tabcontrol)=  "Settings"
	CheckBox check_channelSel_AD_7,userdata(ResizeControlsInfo)= A"!!,G>!!#A^!!#<h!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_AD_7,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_AD_7,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_AD_7,value= 1
	CheckBox check_channelSel_AD_8,pos={174.00,228.00},size={22.00,15.00},disable=1,proc=DB_CheckProc_ChangedSetting,title="8"
	CheckBox check_channelSel_AD_8,userdata(tabnum)=  "2"
	CheckBox check_channelSel_AD_8,userdata(tabcontrol)=  "Settings"
	CheckBox check_channelSel_AD_8,userdata(ResizeControlsInfo)= A"!!,G>!!#As!!#<h!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_AD_8,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_AD_8,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_AD_8,value= 1
	CheckBox check_channelSel_AD_9,pos={174.00,249.00},size={22.00,15.00},disable=1,proc=DB_CheckProc_ChangedSetting,title="9"
	CheckBox check_channelSel_AD_9,userdata(tabnum)=  "2"
	CheckBox check_channelSel_AD_9,userdata(tabcontrol)=  "Settings"
	CheckBox check_channelSel_AD_9,userdata(ResizeControlsInfo)= A"!!,G>!!#B3!!#<h!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_AD_9,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_AD_9,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_AD_9,value= 1
	CheckBox check_channelSel_AD_10,pos={174.00,270.00},size={28.00,15.00},disable=1,proc=DB_CheckProc_ChangedSetting,title="10"
	CheckBox check_channelSel_AD_10,userdata(tabnum)=  "2"
	CheckBox check_channelSel_AD_10,userdata(tabcontrol)=  "Settings"
	CheckBox check_channelSel_AD_10,userdata(ResizeControlsInfo)= A"!!,G>!!#BA!!#=C!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_AD_10,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_AD_10,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_AD_10,value= 1
	CheckBox check_channelSel_AD_11,pos={174.00,291.00},size={28.00,15.00},disable=1,proc=DB_CheckProc_ChangedSetting,title="11"
	CheckBox check_channelSel_AD_11,userdata(tabnum)=  "2"
	CheckBox check_channelSel_AD_11,userdata(tabcontrol)=  "Settings"
	CheckBox check_channelSel_AD_11,userdata(ResizeControlsInfo)= A"!!,G>!!#BKJ,hmn!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_AD_11,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_AD_11,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_AD_11,value= 1
	CheckBox check_channelSel_AD_12,pos={174.00,312.00},size={28.00,15.00},disable=1,proc=DB_CheckProc_ChangedSetting,title="12"
	CheckBox check_channelSel_AD_12,userdata(tabnum)=  "2"
	CheckBox check_channelSel_AD_12,userdata(tabcontrol)=  "Settings"
	CheckBox check_channelSel_AD_12,userdata(ResizeControlsInfo)= A"!!,G>!!#BV!!#=C!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_AD_12,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_AD_12,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_AD_12,value= 1
	CheckBox check_channelSel_AD_13,pos={174.00,333.00},size={28.00,15.00},disable=1,proc=DB_CheckProc_ChangedSetting,title="13"
	CheckBox check_channelSel_AD_13,userdata(tabnum)=  "2"
	CheckBox check_channelSel_AD_13,userdata(tabcontrol)=  "Settings"
	CheckBox check_channelSel_AD_13,userdata(ResizeControlsInfo)= A"!!,G>!!#B`J,hmn!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_AD_13,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_AD_13,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_AD_13,value= 1
	CheckBox check_channelSel_AD_14,pos={174.00,354.00},size={28.00,15.00},disable=1,proc=DB_CheckProc_ChangedSetting,title="14"
	CheckBox check_channelSel_AD_14,userdata(tabnum)=  "2"
	CheckBox check_channelSel_AD_14,userdata(tabcontrol)=  "Settings"
	CheckBox check_channelSel_AD_14,userdata(ResizeControlsInfo)= A"!!,G>!!#Bk!!#=C!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_AD_14,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_AD_14,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_AD_14,value= 1
	CheckBox check_channelSel_AD_15,pos={174.00,375.00},size={28.00,15.00},disable=1,proc=DB_CheckProc_ChangedSetting,title="15"
	CheckBox check_channelSel_AD_15,userdata(tabnum)=  "2"
	CheckBox check_channelSel_AD_15,userdata(tabcontrol)=  "Settings"
	CheckBox check_channelSel_AD_15,userdata(ResizeControlsInfo)= A"!!,G>!!#BuJ,hmn!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_AD_15,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_AD_15,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_AD_15,value= 1
	ListBox list_of_ranges1,pos={75.00,156.00},size={227.00,242.00},disable=3,proc=AR_MainListBoxProc
	ListBox list_of_ranges1,userdata(tabnum)=  "3",userdata(tabcontrol)=  "Settings"
	ListBox list_of_ranges1,userdata(ResizeControlsInfo)= A"!!,EP!!#A+!!#Ar!!#B,z!!#](Aon\"Qzzzzzzzzzzzzzz!!#o2B4uAezz"
	ListBox list_of_ranges1,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	ListBox list_of_ranges1,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	ListBox list_of_ranges1,mode= 1,selRow= 0,widths={54,50,66}
	Button button_RemoveRanges,pos={87.00,126.00},size={54.00,21.00},disable=3,proc=AR_ButtonProc_RemoveRanges,title="Remove"
	Button button_RemoveRanges,userdata(tabnum)=  "3"
	Button button_RemoveRanges,userdata(tabcontrol)=  "Settings"
	Button button_RemoveRanges,userdata(ResizeControlsInfo)= A"!!,Eh!!#@`!!#>f!!#<`z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	Button button_RemoveRanges,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button button_RemoveRanges,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_cutoff_length_after,pos={243.00,96.00},size={45.00,18.00},disable=3,proc=AR_SetVarProcCutoffLength
	SetVariable setvar_cutoff_length_after,help={"Time in ms which should be cutoff *after* the artefact."}
	SetVariable setvar_cutoff_length_after,userdata(tabnum)=  "3"
	SetVariable setvar_cutoff_length_after,userdata(tabcontrol)=  "Settings"
	SetVariable setvar_cutoff_length_after,userdata(ResizeControlsInfo)= A"!!,H.!!#@$!!#>B!!#<Hz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	SetVariable setvar_cutoff_length_after,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_cutoff_length_after,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_cutoff_length_after,limits={0,inf,0.1},value= _NUM:0.2
	SetVariable setvar_cutoff_length_before,pos={90.00,96.00},size={150.00,18.00},disable=3,proc=AR_SetVarProcCutoffLength,title="Cutoff length [ms]:"
	SetVariable setvar_cutoff_length_before,help={"Time in ms which should be cutoff *before* the artefact."}
	SetVariable setvar_cutoff_length_before,userdata(tabnum)=  "3"
	SetVariable setvar_cutoff_length_before,userdata(tabcontrol)=  "Settings"
	SetVariable setvar_cutoff_length_before,userdata(ResizeControlsInfo)= A"!!,En!!#@$!!#A%!!#<Hz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	SetVariable setvar_cutoff_length_before,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_cutoff_length_before,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_cutoff_length_before,limits={0,inf,0.1},value= _NUM:0.1
	CheckBox check_auto_remove,pos={156.00,129.00},size={85.00,15.00},disable=3,proc=AR_CheckProc_Update,title="Auto remove"
	CheckBox check_auto_remove,help={"Automatically remove the found ranges on sweep plotting"}
	CheckBox check_auto_remove,userdata(tabnum)=  "3"
	CheckBox check_auto_remove,userdata(tabcontrol)=  "Settings"
	CheckBox check_auto_remove,userdata(ResizeControlsInfo)= A"!!,G,!!#@e!!#?c!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_auto_remove,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_auto_remove,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_auto_remove,value= 0
	CheckBox check_highlightRanges,pos={258.00,129.00},size={31.00,15.00},disable=3,proc=AR_CheckProc_Update,title="HL"
	CheckBox check_highlightRanges,help={"Visualize the found ranges in the graph (*might* slowdown graphing)"}
	CheckBox check_highlightRanges,userdata(tabnum)=  "3"
	CheckBox check_highlightRanges,userdata(tabcontrol)=  "Settings"
	CheckBox check_highlightRanges,userdata(ResizeControlsInfo)= A"!!,H<!!#@e!!#=[!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_highlightRanges,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_highlightRanges,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_highlightRanges,value= 0
	SetVariable setvar_pulseAver_fallbackLength,pos={110.00,225.00},size={137.00,18.00},bodyWidth=50,disable=3,proc=PA_SetVarProc_Common,title="Fallback Length"
	SetVariable setvar_pulseAver_fallbackLength,help={"Pulse To Pulse Length in ms for edge cases which can not be computed."}
	SetVariable setvar_pulseAver_fallbackLength,userdata(tabnum)=  "4"
	SetVariable setvar_pulseAver_fallbackLength,userdata(tabcontrol)=  "Settings"
	SetVariable setvar_pulseAver_fallbackLength,userdata(ResizeControlsInfo)= A"!!,FA!!#Ap!!#@m!!#<Hz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	SetVariable setvar_pulseAver_fallbackLength,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_pulseAver_fallbackLength,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_pulseAver_fallbackLength,value= _NUM:100
	SetVariable setvar_pulseAver_endPulse,pos={128.00,204.00},size={122.00,18.00},bodyWidth=50,disable=3,proc=PA_SetVarProc_Common,title="Ending Pulse"
	SetVariable setvar_pulseAver_endPulse,userdata(tabnum)=  "4"
	SetVariable setvar_pulseAver_endPulse,userdata(tabcontrol)=  "Settings"
	SetVariable setvar_pulseAver_endPulse,userdata(ResizeControlsInfo)= A"!!,Fe!!#A[!!#@X!!#<Hz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	SetVariable setvar_pulseAver_endPulse,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_pulseAver_endPulse,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_pulseAver_endPulse,value= _NUM:inf
	SetVariable setvar_pulseAver_startPulse,pos={123.00,180.00},size={126.00,18.00},bodyWidth=50,disable=3,proc=PA_SetVarProc_Common,title="Starting Pulse"
	SetVariable setvar_pulseAver_startPulse,userdata(tabnum)=  "4"
	SetVariable setvar_pulseAver_startPulse,userdata(tabcontrol)=  "Settings"
	SetVariable setvar_pulseAver_startPulse,userdata(ResizeControlsInfo)= A"!!,F[!!#AC!!#@`!!#<Hz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	SetVariable setvar_pulseAver_startPulse,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_pulseAver_startPulse,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_pulseAver_startPulse,value= _NUM:0
	CheckBox check_pulseAver_multGraphs,pos={120.00,162.00},size={121.00,15.00},disable=3,proc=PA_CheckProc_Common,title="Use multiple graphs"
	CheckBox check_pulseAver_multGraphs,help={"Show the single pulses in multiple graphs or only one graph with mutiple axis."}
	CheckBox check_pulseAver_multGraphs,userdata(tabnum)=  "4"
	CheckBox check_pulseAver_multGraphs,userdata(tabcontrol)=  "Settings"
	CheckBox check_pulseAver_multGraphs,userdata(ResizeControlsInfo)= A"!!,FU!!#A1!!#@V!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_pulseAver_multGraphs,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_pulseAver_multGraphs,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_pulseAver_multGraphs,value= 0
	CheckBox check_pulseAver_zeroTrac,pos={120.00,120.00},size={74.00,15.00},disable=3,proc=PA_CheckProc_Common,title="Zero traces"
	CheckBox check_pulseAver_zeroTrac,help={"Zero the individual traces using subsequent differentiation and integration"}
	CheckBox check_pulseAver_zeroTrac,userdata(tabnum)=  "4"
	CheckBox check_pulseAver_zeroTrac,userdata(tabcontrol)=  "Settings"
	CheckBox check_pulseAver_zeroTrac,userdata(ResizeControlsInfo)= A"!!,FU!!#@T!!#?M!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_pulseAver_zeroTrac,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_pulseAver_zeroTrac,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_pulseAver_zeroTrac,value= 0
	CheckBox check_pulseAver_showAver,pos={120.00,141.00},size={118.00,15.00},disable=3,proc=PA_CheckProc_Average,title="Show average trace"
	CheckBox check_pulseAver_showAver,help={"Show the average trace"}
	CheckBox check_pulseAver_showAver,userdata(tabnum)=  "4"
	CheckBox check_pulseAver_showAver,userdata(tabcontrol)=  "Settings"
	CheckBox check_pulseAver_showAver,userdata(ResizeControlsInfo)= A"!!,FU!!#@q!!#@P!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_pulseAver_showAver,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_pulseAver_showAver,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_pulseAver_showAver,value= 0
	CheckBox check_pulseAver_indTraces,pos={120.00,99.00},size={134.00,15.00},disable=3,proc=PA_CheckProc_Individual,title="Show individual traces"
	CheckBox check_pulseAver_indTraces,help={"Show the individual traces"}
	CheckBox check_pulseAver_indTraces,userdata(tabnum)=  "4"
	CheckBox check_pulseAver_indTraces,userdata(tabcontrol)=  "Settings"
	CheckBox check_pulseAver_indTraces,userdata(ResizeControlsInfo)= A"!!,FU!!#@*!!#@j!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_pulseAver_indTraces,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_pulseAver_indTraces,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_pulseAver_indTraces,value= 1
	CheckBox check_pulseAver_deconv,pos={120.00,249.00},size={94.00,15.00},disable=3,proc=PA_CheckProc_Deconvolution,title="Deconvolution"
	CheckBox check_pulseAver_deconv,help={"Show Deconvolution: tau * dV/dt + V"}
	CheckBox check_pulseAver_deconv,userdata(tabnum)=  "4"
	CheckBox check_pulseAver_deconv,userdata(tabcontrol)=  "Settings"
	CheckBox check_pulseAver_deconv,userdata(ResizeControlsInfo)= A"!!,FU!!#B3!!#?u!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_pulseAver_deconv,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_pulseAver_deconv,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_pulseAver_deconv,value= 0
	CheckBox check_pulseAver_timeAlign,pos={120.00,348.00},size={102.00,15.00},disable=3,proc=PA_CheckProc_Common,title="Time Alignment"
	CheckBox check_pulseAver_timeAlign,help={"Automatically align all traces in the PA graph to a reference trace from the diagonal element"}
	CheckBox check_pulseAver_timeAlign,userdata(tabnum)=  "4"
	CheckBox check_pulseAver_timeAlign,userdata(tabcontrol)=  "Settings"
	CheckBox check_pulseAver_timeAlign,userdata(ResizeControlsInfo)= A"!!,FU!!#Bh!!#@0!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_pulseAver_timeAlign,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_pulseAver_timeAlign,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_pulseAver_timeAlign,value= 0
	SetVariable setvar_pulseAver_deconv_tau,pos={152.00,270.00},size={98.00,18.00},bodyWidth=50,disable=3,proc=PA_SetVarProc_Common,title="tau [ms]"
	SetVariable setvar_pulseAver_deconv_tau,help={"Deconvolution time tau: tau * dV/dt + V"}
	SetVariable setvar_pulseAver_deconv_tau,userdata(tabnum)=  "4"
	SetVariable setvar_pulseAver_deconv_tau,userdata(tabcontrol)=  "Settings"
	SetVariable setvar_pulseAver_deconv_tau,userdata(ResizeControlsInfo)= A"!!,G(!!#BA!!#@(!!#<Hz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	SetVariable setvar_pulseAver_deconv_tau,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_pulseAver_deconv_tau,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_pulseAver_deconv_tau,limits={0,inf,0},value= _NUM:15
	SetVariable setvar_pulseAver_deconv_smth,pos={134.00,294.00},size={112.00,18.00},bodyWidth=50,disable=3,proc=PA_SetVarProc_Common,title="smoothing"
	SetVariable setvar_pulseAver_deconv_smth,help={"Smoothing factor to use before the deconvolution is calculated. Set to 1 to do the calculation without smoothing."}
	SetVariable setvar_pulseAver_deconv_smth,userdata(tabnum)=  "4"
	SetVariable setvar_pulseAver_deconv_smth,userdata(tabcontrol)=  "Settings"
	SetVariable setvar_pulseAver_deconv_smth,userdata(ResizeControlsInfo)= A"!!,Fk!!#BM!!#@D!!#<Hz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	SetVariable setvar_pulseAver_deconv_smth,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_pulseAver_deconv_smth,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_pulseAver_deconv_smth,limits={1,inf,0},value= _NUM:1000
	SetVariable setvar_pulseAver_deconv_range,pos={131.00,315.00},size={118.00,18.00},bodyWidth=50,disable=3,proc=PA_SetVarProc_Common,title="display [ms]"
	SetVariable setvar_pulseAver_deconv_range,help={"Time in ms from the beginning of the pulse that is used for the calculation"}
	SetVariable setvar_pulseAver_deconv_range,userdata(tabnum)=  "4"
	SetVariable setvar_pulseAver_deconv_range,userdata(tabcontrol)=  "Settings"
	SetVariable setvar_pulseAver_deconv_range,userdata(ResizeControlsInfo)= A"!!,Fh!!#BWJ,hq&!!#<Hz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	SetVariable setvar_pulseAver_deconv_range,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_pulseAver_deconv_range,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_pulseAver_deconv_range,limits={0,inf,0},value= _NUM:inf
	GroupBox group_pulseAver_deconv,pos={111.00,246.00},size={153.00,96.00},disable=3
	GroupBox group_pulseAver_deconv,userdata(tabnum)=  "4"
	GroupBox group_pulseAver_deconv,userdata(tabcontrol)=  "Settings"
	GroupBox group_pulseAver_deconv,userdata(ResizeControlsInfo)= A"!!,FC!!#B0!!#A(!!#@$z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	GroupBox group_pulseAver_deconv,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	GroupBox group_pulseAver_deconv,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_BrowserSettings_OVS,pos={160.00,47.00},size={51.00,15.00},disable=1,proc=DB_CheckProc_OverlaySweeps,title="enable"
	CheckBox check_BrowserSettings_OVS,help={"Adds unplotted sweep to graph. Removes plotted sweep from graph."}
	CheckBox check_BrowserSettings_OVS,userdata(tabnum)=  "1"
	CheckBox check_BrowserSettings_OVS,userdata(tabcontrol)=  "Settings"
	CheckBox check_BrowserSettings_OVS,userdata(ResizeControlsInfo)= A"!!,G0!!#>J!!#>Z!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_BrowserSettings_OVS,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_BrowserSettings_OVS,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_BrowserSettings_OVS,value= 0
	CheckBox check_BrowserSettings_AR,pos={160.00,47.00},size={51.00,15.00},disable=1,proc=BSP_CheckBoxProc_ArtRemoval,title="enable"
	CheckBox check_BrowserSettings_AR,help={"Open the artefact removal dialog"}
	CheckBox check_BrowserSettings_AR,userdata(tabnum)=  "3"
	CheckBox check_BrowserSettings_AR,userdata(tabcontrol)=  "Settings"
	CheckBox check_BrowserSettings_AR,userdata(ResizeControlsInfo)= A"!!,G0!!#>J!!#>Z!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_BrowserSettings_AR,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_BrowserSettings_AR,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_BrowserSettings_AR,value= 0
	CheckBox check_BrowserSettings_PA,pos={160.00,47.00},size={51.00,15.00},disable=1,proc=BSP_CheckBoxProc_PerPulseAver,title="enable"
	CheckBox check_BrowserSettings_PA,help={"Allows to average multiple pulses from pulse train epochs"}
	CheckBox check_BrowserSettings_PA,userdata(tabnum)=  "4"
	CheckBox check_BrowserSettings_PA,userdata(tabcontrol)=  "Settings"
	CheckBox check_BrowserSettings_PA,userdata(ResizeControlsInfo)= A"!!,G0!!#>J!!#>Z!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_BrowserSettings_PA,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_BrowserSettings_PA,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_BrowserSettings_PA,value= 0
	CheckBox check_BrowserSettings_DAC,pos={24.00,36.00},size={32.00,15.00},title="DA"
	CheckBox check_BrowserSettings_DAC,help={"Display the DA channel data"}
	CheckBox check_BrowserSettings_DAC,userdata(tabnum)=  "0"
	CheckBox check_BrowserSettings_DAC,userdata(tabcontrol)=  "Settings"
	CheckBox check_BrowserSettings_DAC,userdata(ResizeControlsInfo)= A"!!,C$!!#=s!!#=c!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_BrowserSettings_DAC,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_BrowserSettings_DAC,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_BrowserSettings_DAC,value= 0
	CheckBox check_BrowserSettings_ADC,pos={87.00,36.00},size={32.00,15.00},title="AD"
	CheckBox check_BrowserSettings_ADC,help={"Display the AD channels"}
	CheckBox check_BrowserSettings_ADC,userdata(tabnum)=  "0"
	CheckBox check_BrowserSettings_ADC,userdata(tabcontrol)=  "Settings"
	CheckBox check_BrowserSettings_ADC,userdata(ResizeControlsInfo)= A"!!,Eh!!#=s!!#=c!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_BrowserSettings_ADC,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_BrowserSettings_ADC,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_BrowserSettings_ADC,value= 1
	CheckBox check_BrowserSettings_TTL,pos={144.00,36.00},size={36.00,15.00},title="TTL"
	CheckBox check_BrowserSettings_TTL,help={"Display the TTL channels"}
	CheckBox check_BrowserSettings_TTL,userdata(tabnum)=  "0"
	CheckBox check_BrowserSettings_TTL,userdata(tabcontrol)=  "Settings"
	CheckBox check_BrowserSettings_TTL,userdata(ResizeControlsInfo)= A"!!,Fu!!#=s!!#=s!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_BrowserSettings_TTL,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_BrowserSettings_TTL,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_BrowserSettings_TTL,value= 0
	CheckBox check_BrowserSettings_OChan,pos={24.00,60.00},size={65.00,15.00},title="Channels"
	CheckBox check_BrowserSettings_OChan,help={"Overlay the data from multiple channels in one graph"}
	CheckBox check_BrowserSettings_OChan,userdata(tabnum)=  "0"
	CheckBox check_BrowserSettings_OChan,userdata(tabcontrol)=  "Settings"
	CheckBox check_BrowserSettings_OChan,userdata(ResizeControlsInfo)= A"!!,C$!!#?)!!#?;!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_BrowserSettings_OChan,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_BrowserSettings_OChan,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_BrowserSettings_OChan,value= 0
	CheckBox check_BrowserSettings_dDAQ,pos={144.00,60.00},size={48.00,15.00},title="dDAQ"
	CheckBox check_BrowserSettings_dDAQ,help={"Enable dedicated support for viewing distributed DAQ data"}
	CheckBox check_BrowserSettings_dDAQ,userdata(tabnum)=  "0"
	CheckBox check_BrowserSettings_dDAQ,userdata(tabcontrol)=  "Settings"
	CheckBox check_BrowserSettings_dDAQ,userdata(ResizeControlsInfo)= A"!!,Fu!!#?)!!#>N!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_BrowserSettings_dDAQ,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_BrowserSettings_dDAQ,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_BrowserSettings_dDAQ,value= 0
	CheckBox check_Calculation_ZeroTraces,pos={36.00,219.00},size={76.00,15.00},title="Zero Traces"
	CheckBox check_Calculation_ZeroTraces,help={"Remove the offset of all traces"}
	CheckBox check_Calculation_ZeroTraces,userdata(tabnum)=  "0"
	CheckBox check_Calculation_ZeroTraces,userdata(tabcontrol)=  "Settings"
	CheckBox check_Calculation_ZeroTraces,userdata(ResizeControlsInfo)= A"!!,Ct!!#Aj!!#?Q!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_Calculation_ZeroTraces,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_Calculation_ZeroTraces,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_Calculation_ZeroTraces,value= 0
	CheckBox check_Calculation_AverageTraces,pos={36.00,198.00},size={95.00,15.00},title="Average Traces"
	CheckBox check_Calculation_AverageTraces,help={"Average all traces which belong to the same y axis"}
	CheckBox check_Calculation_AverageTraces,userdata(tabnum)=  "0"
	CheckBox check_Calculation_AverageTraces,userdata(tabcontrol)=  "Settings"
	CheckBox check_Calculation_AverageTraces,userdata(ResizeControlsInfo)= A"!!,Ct!!#AU!!#@\"!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_Calculation_AverageTraces,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_Calculation_AverageTraces,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_Calculation_AverageTraces,value= 0
	CheckBox check_BrowserSettings_TA,pos={150.00,111.00},size={51.00,15.00},proc=BSP_TimeAlignmentProc,title="enable"
	CheckBox check_BrowserSettings_TA,help={"Activate time alignment"}
	CheckBox check_BrowserSettings_TA,userdata(tabnum)=  "0"
	CheckBox check_BrowserSettings_TA,userdata(tabcontrol)=  "Settings"
	CheckBox check_BrowserSettings_TA,userdata(ResizeControlsInfo)= A"!!,G&!!#@B!!#>Z!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_BrowserSettings_TA,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_BrowserSettings_TA,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_BrowserSettings_TA,value= 0
	CheckBox check_ovs_clear_on_new_ra_cycle,pos={231.00,161.00},size={111.00,15.00},disable=3,title="Clear on new RAC"
	CheckBox check_ovs_clear_on_new_ra_cycle,help={"Clear the list of overlayed sweeps when a new repeated acquisition cycle has begun."}
	CheckBox check_ovs_clear_on_new_ra_cycle,userdata(tabnum)=  "1"
	CheckBox check_ovs_clear_on_new_ra_cycle,userdata(tabcontrol)=  "Settings"
	CheckBox check_ovs_clear_on_new_ra_cycle,userdata(ResizeControlsInfo)= A"!!,H\"!!#A0!!#@B!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_ovs_clear_on_new_ra_cycle,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_ovs_clear_on_new_ra_cycle,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_ovs_clear_on_new_ra_cycle,value= 0
	CheckBox check_ovs_clear_on_new_stimset_cycle,pos={231.00,181.00},size={105.00,15.00},disable=3,title="Clear on new SCI"
	CheckBox check_ovs_clear_on_new_stimset_cycle,help={"Clear the list of overlayed sweeps when a new simset cycle has begun."}
	CheckBox check_ovs_clear_on_new_stimset_cycle,userdata(tabnum)=  "1"
	CheckBox check_ovs_clear_on_new_stimset_cycle,userdata(tabcontrol)=  "Settings"
	CheckBox check_ovs_clear_on_new_stimset_cycle,userdata(ResizeControlsInfo)= A"!!,H\"!!#AD!!#@6!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_ovs_clear_on_new_stimset_cycle,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_ovs_clear_on_new_stimset_cycle,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_ovs_clear_on_new_stimset_cycle,value= 0
	PopupMenu popup_TimeAlignment_Mode,pos={27.00,135.00},size={143.00,19.00},bodyWidth=50,disable=2,proc=BSP_TimeAlignmentPopup,title="Alignment Mode"
	PopupMenu popup_TimeAlignment_Mode,help={"Select the alignment mode"}
	PopupMenu popup_TimeAlignment_Mode,userdata(tabnum)=  "0"
	PopupMenu popup_TimeAlignment_Mode,userdata(tabcontrol)=  "Settings"
	PopupMenu popup_TimeAlignment_Mode,userdata(ResizeControlsInfo)= A"!!,C<!!#@k!!#@s!!#<Pz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	PopupMenu popup_TimeAlignment_Mode,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu popup_TimeAlignment_Mode,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu popup_TimeAlignment_Mode,mode=1,popvalue="Level (Raising)",value= #"\"Level (Raising);Level (Falling);Min;Max\""
	SetVariable setvar_TimeAlignment_LevelCross,pos={183.00,135.00},size={48.00,18.00},disable=2,proc=BSP_TimeAlignmentLevel,title="Level"
	SetVariable setvar_TimeAlignment_LevelCross,help={"Select the level (for rising and falling alignment mode) at which traces are aligned"}
	SetVariable setvar_TimeAlignment_LevelCross,userdata(tabnum)=  "0"
	SetVariable setvar_TimeAlignment_LevelCross,userdata(tabcontrol)=  "Settings"
	SetVariable setvar_TimeAlignment_LevelCross,userdata(ResizeControlsInfo)= A"!!,GG!!#@k!!#>N!!#<Hz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	SetVariable setvar_TimeAlignment_LevelCross,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_TimeAlignment_LevelCross,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_TimeAlignment_LevelCross,limits={-inf,inf,0},value= _NUM:0
	Button button_TimeAlignment_Action,pos={204.00,159.00},size={30.00,18.00},disable=2,title="Do!"
	Button button_TimeAlignment_Action,help={"Perform the time alignment, needs the cursors A and B to have a selected feature"}
	Button button_TimeAlignment_Action,userdata(tabnum)=  "0"
	Button button_TimeAlignment_Action,userdata(tabcontrol)=  "Settings"
	Button button_TimeAlignment_Action,userdata(ResizeControlsInfo)= A"!!,G\\!!#A.!!#=S!!#<Hz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	Button button_TimeAlignment_Action,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button button_TimeAlignment_Action,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	GroupBox group_SB_axes_scaling,pos={24.00,246.00},size={285.00,51.00},title="Axes Scaling"
	GroupBox group_SB_axes_scaling,userdata(tabnum)=  "0"
	GroupBox group_SB_axes_scaling,userdata(tabcontrol)=  "Settings"
	GroupBox group_SB_axes_scaling,userdata(ResizeControlsInfo)= A"!!,C$!!#B0!!#BHJ,ho0z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	GroupBox group_SB_axes_scaling,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	GroupBox group_SB_axes_scaling,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_Display_VisibleXrange,pos={36.00,270.00},size={41.00,15.00},title="Vis X"
	CheckBox check_Display_VisibleXrange,help={"Scale the y axis to the visible x data range"}
	CheckBox check_Display_VisibleXrange,userdata(tabnum)=  "0"
	CheckBox check_Display_VisibleXrange,userdata(tabcontrol)=  "Settings"
	CheckBox check_Display_VisibleXrange,userdata(ResizeControlsInfo)= A"!!,Ct!!#BA!!#>2!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_Display_VisibleXrange,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_Display_VisibleXrange,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_Display_VisibleXrange,value= 0
	CheckBox check_Display_EqualYrange,pos={90.00,270.00},size={55.00,15.00},disable=2,title="Equal Y"
	CheckBox check_Display_EqualYrange,help={"Equalize the vertical axes ranges"}
	CheckBox check_Display_EqualYrange,userdata(tabnum)=  "0"
	CheckBox check_Display_EqualYrange,userdata(tabcontrol)=  "Settings"
	CheckBox check_Display_EqualYrange,userdata(ResizeControlsInfo)= A"!!,En!!#BA!!#>j!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_Display_EqualYrange,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_Display_EqualYrange,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_Display_EqualYrange,value= 0
	CheckBox check_Display_EqualYignore,pos={150.00,270.00},size={36.00,15.00},disable=2,title="ign."
	CheckBox check_Display_EqualYignore,help={"Equalize the vertical axes ranges but ignore all traces with level crossings"}
	CheckBox check_Display_EqualYignore,userdata(tabnum)=  "0"
	CheckBox check_Display_EqualYignore,userdata(tabcontrol)=  "Settings"
	CheckBox check_Display_EqualYignore,userdata(ResizeControlsInfo)= A"!!,G&!!#BA!!#=s!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_Display_EqualYignore,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_Display_EqualYignore,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_Display_EqualYignore,value= 0
	SetVariable setvar_Display_EqualYlevel,pos={189.00,270.00},size={24.00,18.00},disable=2,proc=SB_AxisScalingLevelCross
	SetVariable setvar_Display_EqualYlevel,help={"Crossing level value for 'Equal Y ign.\""}
	SetVariable setvar_Display_EqualYlevel,userdata(tabnum)=  "0"
	SetVariable setvar_Display_EqualYlevel,userdata(tabcontrol)=  "Settings"
	SetVariable setvar_Display_EqualYlevel,userdata(ResizeControlsInfo)= A"!!,GM!!#BA!!#=#!!#<Hz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	SetVariable setvar_Display_EqualYlevel,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_Display_EqualYlevel,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_Display_EqualYlevel,limits={-inf,inf,0},value= _NUM:0
	PopupMenu popup_TimeAlignment_Master,pos={40.00,159.00},size={134.00,19.00},bodyWidth=50,disable=2,proc=BSP_TimeAlignmentPopup,title="Reference trace"
	PopupMenu popup_TimeAlignment_Master,help={"Select the reference trace to which all other traces should be aligned to"}
	PopupMenu popup_TimeAlignment_Master,userdata(tabnum)=  "0"
	PopupMenu popup_TimeAlignment_Master,userdata(tabcontrol)=  "Settings"
	PopupMenu popup_TimeAlignment_Master,userdata(ResizeControlsInfo)= A"!!,D/!!#A.!!#@j!!#<Pz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	PopupMenu popup_TimeAlignment_Master,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu popup_TimeAlignment_Master,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu popup_TimeAlignment_Master,mode=1,popvalue="AD0",value= #"\"\""
	Button button_Calculation_RestoreData,pos={147.00,210.00},size={75.00,24.00},title="Restore"
	Button button_Calculation_RestoreData,help={"Restore the data in its pristine state without any modifications"}
	Button button_Calculation_RestoreData,userdata(tabnum)=  "0"
	Button button_Calculation_RestoreData,userdata(tabcontrol)=  "Settings"
	Button button_Calculation_RestoreData,userdata(ResizeControlsInfo)= A"!!,G#!!#Aa!!#?O!!#=#z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	Button button_Calculation_RestoreData,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button button_Calculation_RestoreData,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	Button button_BrowserSettings_Export,pos={78.00,333.00},size={99.00,24.00},proc=SB_ButtonProc_ExportTraces,title="Export Traces"
	Button button_BrowserSettings_Export,help={"Export the traces for further processing"}
	Button button_BrowserSettings_Export,userdata(tabnum)=  "0"
	Button button_BrowserSettings_Export,userdata(tabcontrol)=  "Settings"
	Button button_BrowserSettings_Export,userdata(ResizeControlsInfo)= A"!!,EV!!#B`J,hpU!!#=#z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	Button button_BrowserSettings_Export,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	Button button_BrowserSettings_Export,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	GroupBox group_timealignment,pos={24.00,87.00},size={285.00,99.00},title="Time Alignment"
	GroupBox group_timealignment,userdata(tabnum)=  "0"
	GroupBox group_timealignment,userdata(tabcontrol)=  "Settings"
	GroupBox group_timealignment,userdata(ResizeControlsInfo)= A"!!,C$!!#?g!!#BHJ,hpUz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	GroupBox group_timealignment,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	GroupBox group_timealignment,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	Slider slider_BrowserSettings_dDAQ,pos={312.00,36.00},size={56.00,300.00},disable=2
	Slider slider_BrowserSettings_dDAQ,help={"Allows to view only regions from the selected headstage (oodDAQ) resp. the selected headstage (dDAQ). Choose -1 to display all."}
	Slider slider_BrowserSettings_dDAQ,userdata(tabnum)=  "0"
	Slider slider_BrowserSettings_dDAQ,userdata(tabcontrol)=  "Settings"
	Slider slider_BrowserSettings_dDAQ,userdata(ResizeControlsInfo)= A"!!,HW!!#=s!!#>n!!#BPz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	Slider slider_BrowserSettings_dDAQ,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Slider slider_BrowserSettings_dDAQ,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	Slider slider_BrowserSettings_dDAQ,limits={-1,7,1},value= -1
	CheckBox check_SweepControl_HideSweep,pos={249.00,60.00},size={41.00,15.00},title="Hide"
	CheckBox check_SweepControl_HideSweep,help={"Hide sweep traces. Usually combined with \"Average traces\"."}
	CheckBox check_SweepControl_HideSweep,userdata(tabnum)=  "0"
	CheckBox check_SweepControl_HideSweep,userdata(tabcontrol)=  "Settings"
	CheckBox check_SweepControl_HideSweep,userdata(ResizeControlsInfo)= A"!!,H4!!#?)!!#>2!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_SweepControl_HideSweep,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_SweepControl_HideSweep,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_SweepControl_HideSweep,value= 0
	CheckBox check_BrowserSettings_splitTTL,pos={249.00,36.00},size={60.00,15.00},title="sep. TTL"
	CheckBox check_BrowserSettings_splitTTL,help={"Display the TTL channel data as single traces for each TTL bit"}
	CheckBox check_BrowserSettings_splitTTL,userdata(tabnum)=  "0"
	CheckBox check_BrowserSettings_splitTTL,userdata(tabcontrol)=  "Settings"
	CheckBox check_BrowserSettings_splitTTL,userdata(ResizeControlsInfo)= A"!!,H4!!#=s!!#?)!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_BrowserSettings_splitTTL,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_BrowserSettings_splitTTL,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_BrowserSettings_splitTTL,value= 0
	PopupMenu popup_DB_lockedDevices,pos={20.00,303.00},size={205.00,19.00},bodyWidth=100,proc=DB_PopMenuProc_LockDBtoDevice,title="Device assignment:"
	PopupMenu popup_DB_lockedDevices,help={"Select a data acquistion device to display data"}
	PopupMenu popup_DB_lockedDevices,userdata(tabnum)=  "0"
	PopupMenu popup_DB_lockedDevices,userdata(tabcontrol)=  "Settings"
	PopupMenu popup_DB_lockedDevices,userdata(ResizeControlsInfo)= A"!!,BY!!#BQJ,hr2!!#<Pz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	PopupMenu popup_DB_lockedDevices,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu popup_DB_lockedDevices,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu popup_DB_lockedDevices,mode=1,popvalue="- none -",value= #"DB_GetAllDevicesWithData()"
	GroupBox group_enable_sweepFormula,pos={5.00,25.00},size={380.00,50.00},disable=1,title="SweepFormula"
	GroupBox group_enable_sweepFormula,userdata(tabnum)=  "5"
	GroupBox group_enable_sweepFormula,userdata(tabcontrol)=  "Settings"
	GroupBox group_enable_sweepFormula,userdata(ResizeControlsInfo)= A"!!,?X!!#=+!!#C#!!#>Vz!!#](Aon#azzzzzzzzzzzzzz!!#o2B4uAeBk2=!z"
	GroupBox group_enable_sweepFormula,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#N3Bk1ctAStpcCh5qOGZ8U#zzzzzzzz"
	GroupBox group_enable_sweepFormula,userdata(ResizeControlsInfo) += A"zzz!!#N3Bk1ctAStpcCh5qOGX?=jFDl!rzzzzzzzzzz!!!"
	SetVariable setvar_sweepFormula_parseResult,pos={118.00,377.00},size={255.00,18.00},disable=3,title="◀"
	SetVariable setvar_sweepFormula_parseResult,help={"Error Message from Formula Parsing"}
	SetVariable setvar_sweepFormula_parseResult,userdata(tabnum)=  "5"
	SetVariable setvar_sweepFormula_parseResult,userdata(tabcontrol)=  "Settings"
	SetVariable setvar_sweepFormula_parseResult,userdata(ResizeControlsInfo)= A"!!,FQ!!#C!J,hrd!!#<Hz!!#](Aon#azzzzzzzzzzzzzz!!#](Aon#SBk2=!z"
	SetVariable setvar_sweepFormula_parseResult,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#?(FEDG<zzzzzzzzzzz"
	SetVariable setvar_sweepFormula_parseResult,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_sweepFormula_parseResult,frame=0
	SetVariable setvar_sweepFormula_parseResult,limits={-inf,inf,0},value= _STR:"",noedit= 1,live= 1
	ValDisplay status_sweepFormula_parser,pos={369.00,380.00},size={10.00,8.00},bodyWidth=10,disable=3
	ValDisplay status_sweepFormula_parser,help={"Current parsing status of the entered formula."}
	ValDisplay status_sweepFormula_parser,userdata(tabnum)=  "5"
	ValDisplay status_sweepFormula_parser,userdata(tabcontrol)=  "Settings"
	ValDisplay status_sweepFormula_parser,userdata(ResizeControlsInfo)= A"!!,HsJ,hsN!!#;-!!#:bz!!#o2B4uAezzzzzzzzzzzzzz!!#o2B4uAeBk2=!z"
	ValDisplay status_sweepFormula_parser,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#?(FEDG<zzzzzzzzzzz"
	ValDisplay status_sweepFormula_parser,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	ValDisplay status_sweepFormula_parser,limits={-1,1,0},barmisc={0,0},mode= 1,highColor= (0,65535,0),lowColor= (0,0,0),zeroColor= (65535,0,0)
	ValDisplay status_sweepFormula_parser,value= #"1"
	Button button_sweepFormula_display,pos={4.00,374.00},size={55.00,22.00},disable=3,proc=SF_button_sweepFormula_display,title="Display"
	Button button_sweepFormula_display,userdata(tabnum)=  "5"
	Button button_sweepFormula_display,userdata(tabcontrol)=  "Settings"
	Button button_sweepFormula_display,userdata(ResizeControlsInfo)= A"!!,?8!!#Bu!!#>j!!#<hz!!#](Aon#azzzzzzzzzzzzzz!!#](Aon#SBk2=!z"
	Button button_sweepFormula_display,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#?(FEDG<zzzzzzzzzzz"
	Button button_sweepFormula_display,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	Button button_sweepFormula_check,pos={61.00,374.00},size={55.00,22.00},disable=3,proc=SF_button_sweepFormula_check,title="Check"
	Button button_sweepFormula_check,userdata(tabnum)=  "5"
	Button button_sweepFormula_check,userdata(tabcontrol)=  "Settings"
	Button button_sweepFormula_check,userdata(ResizeControlsInfo)= A"!!,E.!!#Bu!!#>j!!#<hz!!#](Aon#azzzzzzzzzzzzzz!!#](Aon#SBk2=!z"
	Button button_sweepFormula_check,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#?(FEDG<zzzzzzzzzzz"
	Button button_sweepFormula_check,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	TabControl SF_InfoTab,pos={7.00,90.00},size={369.00,279.00},disable=3,proc=ACL_DisplayTab
	TabControl SF_InfoTab,userdata(finalhook)=  "SF_TabProc_Formula"
	TabControl SF_InfoTab,userdata(currenttab)=  "0",userdata(tabnum)=  "5"
	TabControl SF_InfoTab,userdata(tabcontrol)=  "Settings"
	TabControl SF_InfoTab,userdata(ResizeControlsInfo)= A"!!,@C!!#?m!!#BrJ,hrpJ,fQL!!#](Aon#azzzzzzzzzzzzzz!!#o2B4uAeBk2=!z"
	TabControl SF_InfoTab,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	TabControl SF_InfoTab,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	TabControl SF_InfoTab,tabLabel(0)="Formula",tabLabel(1)="JSON"
	TabControl SF_InfoTab,tabLabel(2)="Help",value= 0
	ListBox list_dashboard,pos={5.00,90.00},size={380.00,310.00},disable=1,proc=AD_ListBoxProc
	ListBox list_dashboard,userdata(tabnum)=  "7",userdata(tabcontrol)=  "Settings"
	ListBox list_dashboard,userdata(ResizeControlsInfo)= A"!!,?X!!#?m!!#C#!!#BUz!!#](Aon\"Qzzzzzzzzzzzzzz!!#o2B4uAezz"
	ListBox list_dashboard,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	ListBox list_dashboard,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	ListBox list_dashboard,fSize=12,mode= 1,selRow= -1,widths={141,109,77}
	ListBox list_dashboard,userColumnResize= 1
	GroupBox group_enable_dashboard,pos={5.00,25.00},size={380.00,60.00},disable=1
	GroupBox group_enable_dashboard,userdata(tabnum)=  "7"
	GroupBox group_enable_dashboard,userdata(tabcontrol)=  "Settings"
	GroupBox group_enable_dashboard,userdata(ResizeControlsInfo)= A"!!,?X!!#=+!!#C#!!#?)z!!#](Aon\"Qzzzzzzzzzzzzzz!!#o2B4uAezz"
	GroupBox group_enable_dashboard,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	GroupBox group_enable_dashboard,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_BrowserSettings_DB_Passed,pos={171.00,39.00},size={52.00,15.00},disable=1,proc=AD_CheckProc_PassedSweeps,title="Passed"
	CheckBox check_BrowserSettings_DB_Passed,help={"Show passed sweeps on double click into ListBox "}
	CheckBox check_BrowserSettings_DB_Passed,userdata(tabnum)=  "7"
	CheckBox check_BrowserSettings_DB_Passed,userdata(tabcontrol)=  "Settings"
	CheckBox check_BrowserSettings_DB_Passed,userdata(ResizeControlsInfo)= A"!!,G;!!#>*!!#>^!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_BrowserSettings_DB_Passed,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_BrowserSettings_DB_Passed,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_BrowserSettings_DB_Passed,value= 0
	CheckBox check_BrowserSettings_DB_Failed,pos={171.00,60.00},size={47.00,15.00},disable=1,proc=AD_CheckProc_FailedSweeps,title="Failed"
	CheckBox check_BrowserSettings_DB_Failed,help={"Show failed sweeps on double click into ListBox "}
	CheckBox check_BrowserSettings_DB_Failed,userdata(tabnum)=  "7"
	CheckBox check_BrowserSettings_DB_Failed,userdata(tabcontrol)=  "Settings"
	CheckBox check_BrowserSettings_DB_Failed,userdata(ResizeControlsInfo)= A"!!,G;!!#?)!!#>J!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_BrowserSettings_DB_Failed,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_BrowserSettings_DB_Failed,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_BrowserSettings_DB_Failed,value= 0
	CheckBox check_BrowserSettings_SF,pos={160.00,47.00},size={51.00,15.00},disable=1,proc=BSP_CheckBoxProc_SweepFormula,title="enable"
	CheckBox check_BrowserSettings_SF,userdata(tabnum)=  "5"
	CheckBox check_BrowserSettings_SF,userdata(tabcontrol)=  "Settings"
	CheckBox check_BrowserSettings_SF,userdata(ResizeControlsInfo)= A"!!,G0!!#>J!!#>Z!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_BrowserSettings_SF,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#N3Bk1ctAStpcCh5qOGZ8U#zzzzzzzz"
	CheckBox check_BrowserSettings_SF,userdata(ResizeControlsInfo) += A"zzz!!#N3Bk1ctAStpcCh5qOGX?=jFDl!rzzzzzzzzzz!!!"
	CheckBox check_BrowserSettings_SF,value= 0
	DefineGuide UGVL={FL,15},UGVR={FR,-20},UGVT={FT,113},UGVB={FB,-50},enableBoxTop={FT,25}
	DefineGuide enableBoxBottom={enableBoxTop,50},MainBoxBottom={FB,3},MainBoxTop={enableBoxBottom,10}
	SetWindow kwTopWin,hook(ResizeControls)=ResizeControls#ResizeControlsHook
	SetWindow kwTopWin,userdata(ResizeControlsInfo)= A"!!*'\"z!!#C(J,hs[zzzzzzzzzzzzzzzzzzzzz"
	SetWindow kwTopWin,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzzzzzzzzzzzzzzz"
	SetWindow kwTopWin,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzzzzzzzzz!!!"
	SetWindow kwTopWin,userdata(ResizeControlsGuides)=  "UGVL;UGVR;UGVT;UGVB;enableBoxTop;enableBoxBottom;MainBoxBottom;MainBoxTop;"
	SetWindow kwTopWin,userdata(ResizeControlsInfoUGVL)=  "NAME:UGVL;WIN:Databrowser#BrowserSettingsPanel;TYPE:User;HORIZONTAL:0;POSITION:15.00;GUIDE1:FL;GUIDE2:;RELPOSITION:15;"
	SetWindow kwTopWin,userdata(ResizeControlsInfoUGVR)=  "NAME:UGVR;WIN:Databrowser#BrowserSettingsPanel;TYPE:User;HORIZONTAL:0;POSITION:371.00;GUIDE1:FR;GUIDE2:;RELPOSITION:-20;"
	SetWindow kwTopWin,userdata(ResizeControlsInfoUGVT)=  "NAME:UGVT;WIN:Databrowser#BrowserSettingsPanel;TYPE:User;HORIZONTAL:1;POSITION:113.00;GUIDE1:FT;GUIDE2:;RELPOSITION:113;"
	SetWindow kwTopWin,userdata(ResizeControlsInfoUGVB)=  "NAME:UGVB;WIN:Databrowser#BrowserSettingsPanel;TYPE:User;HORIZONTAL:1;POSITION:356.00;GUIDE1:FB;GUIDE2:;RELPOSITION:-50;"
	SetWindow kwTopWin,userdata(ResizeControlsInfoenableBoxTop)=  "NAME:enableBoxTop;WIN:Databrowser#BrowserSettingsPanel;TYPE:User;HORIZONTAL:1;POSITION:25.00;GUIDE1:FT;GUIDE2:;RELPOSITION:25;"
	SetWindow kwTopWin,userdata(ResizeControlsInfoenableBoxBottom)=  "NAME:enableBoxBottom;WIN:Databrowser#BrowserSettingsPanel;TYPE:User;HORIZONTAL:1;POSITION:75.00;GUIDE1:enableBoxTop;GUIDE2:;RELPOSITION:50;"
	SetWindow kwTopWin,userdata(ResizeControlsInfoMainBoxBottom)=  "NAME:MainBoxBottom;WIN:Databrowser#BrowserSettingsPanel;TYPE:User;HORIZONTAL:1;POSITION:406.00;GUIDE1:FB;GUIDE2:;RELPOSITION:3;"
	SetWindow kwTopWin,userdata(ResizeControlsInfoMainBoxTop)=  "NAME:MainBoxTop;WIN:Databrowser#BrowserSettingsPanel;TYPE:User;HORIZONTAL:1;POSITION:85.00;GUIDE1:enableBoxBottom;GUIDE2:;RELPOSITION:10;"
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
	Notebook kwTopWin, zdata= "GaqDU%ejN7!Z*!1@=S>)+F`2^BZWLb84b@(eDO%R/Lo%!.b8RgERN@q:!Q;Rb=g(\\Ea=4.iptUKJmo0`?;1F7@M*q"
	Notebook kwTopWin, zdataEnd= 1
	SetWindow kwTopWin,hook(ResizeControls)=ResizeControls#ResizeControlsHook
	SetWindow kwTopWin,userdata(tabnum)=  "0"
	SetWindow kwTopWin,userdata(tabcontrol)=  "SF_InfoTab"
	SetWindow kwTopWin,userdata(ResizeControlsInfo)= A"!!,@C!!#>F!!#C#!!#B[J,fQL!!#](Aon#azzzzzzzzzzzzzz!!#o2B4uAeBk2=!z"
	SetWindow kwTopWin,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetWindow kwTopWin,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	RenameWindow #,sweepFormula_formula
	SetActiveSubwindow ##
	NewNotebook /F=1 /N=sweepFormula_help /W=(12,71,378,358)/FG=(UGVL,UGVT,UGVR,UGVB) /HOST=# /V=0 /OPTS=4
	Notebook kwTopWin, defaultTab=36, autoSave= 1, magnification=100, writeProtect=1, showRuler=0, rulerUnits=2
	Notebook kwTopWin newRuler=Normal, justification=0, margins={0,0,245}, spacing={0,0,0}, tabs={}, rulerDefaults={"Arial",11,0,(0,0,0)}
	Notebook kwTopWin, zdata= "Gb!Smc#;CW'rPlgG3[\"@S03ULUP#41<tW-ob48&S(8r5'NJ^+^l8h5B=?n*O\\2su<@5u/iA>$&#]bCVWo\\*PklebO3Vk/L1gRD\"7#C>X.mX&kC/pB<kMae4G$1'9ghOBT#S)=)[1=VqFm(p(3T1dE\"<oE]dI/`umh]I(j]N,s.eV0QTiFCg;gG_7`?Z4RTo;:^DiV+@[jDWrI]^r!!2fQM8^Lrr4O1uL&0]snR1=#]ik<4:,![%;Tf7=PG1aKNU\"d7Z_7*^ckWHRN:hKAVm`C)DDbGjPW;megL\\R92:]Ag/@"
	Notebook kwTopWin, zdata= "ICA!FTQX\"gTnm5/65HPjnMk-.b%8d-@Z\\Z!UtYN;6RJZm0\";KE:iVVnm!rj`p;mZSB'X]4>#r:=b<%;HVPWmI(J$;hCM^e8`.jbVEe`_$QYW/N^u$,oSq#:eq'p*Af%TVn^I>_<rcORqLJ;&Pp4q6bQ21moCKLJZ[;4-T(3.!qjjR!Oh=>KK&o&N!`p_[PB`apHa*DV.IsAlG=cRU[+)F3[9n0D3*+_-NYE@n;JK<?3#-e-:M_qBrZH/?n>dHMRaHX+riCDDpbacsQ5\\j,Mjh_^WapcW-RUoABQ&+j.\"FkuA"
	Notebook kwTopWin, zdata= "3BupnX?,1Ck'Thb63e:>?J3\\p_g<+A`rB&2k4ilJ55_A2m^KclM\\k]I2F2&Fek<E:<?dTJg>*Q:_P^lOX5Ku-RbsG@g6\\ZP\"!Rk:N/igC_l\"%Y`o=b<+\"q`gO3?)=H[r,Goa+1^C<[p$_A6t`[?LCSNQSu^G-`->09[Y_b#i'D(Bjq,2i?K_bs]mndtHRek9c-86?2hd^1162k[)=>?gVCW.jUPR>k0]_[.W.+@d:8d2DM#0]>0Uj\"`2NimW]d>_LUEn;8pMDo+'WcU\\Dl-\\MRr%%?6!uW(2S)\"+HQ,]44B_"
	Notebook kwTopWin, zdata= "GB:_ec$9M]ZWkqd)*/InH3'S9P?0qZkkc:)DPbC4JkR+P+r@5@#X=AM3X2T)C0,RAj+orJa7JDH<A$f6BhXek&S%alKHiSV_c@r]UNiGBa=:I<%6Ked_F07r#1O?$GU692B&c3k/^lFS-7gV[=.*'io4acr3/K+M*W1ro6\"se^1<g0D%O&LL52.qgg?&CC7@s&)&C<5c%mW9/#_#a+Q.Q[OQ7H'AJr@oS=9RRYOc!XkGbrJ`'Q^l</QD`%6L`/.qsr/tVU*%dlN(B.R!YcP1NDd)0'OLo%6YKK)\"(P#_:%(["
	Notebook kwTopWin, zdata= "^UsAa(?I#S[7amAhuU\\X8'VS[rciF2A>@HNfXkDS%go)+BK,nZJ^5Z`4BZK!3UC$17*_\"W#g68B*GGArqdkURW<8><\"%@-tI[lc/Ce>.liW]r:6:/c3HQ_@-JnPlR&7CL*9+Sk>bO&GpmDQ?umHlCe;G62<%f::OM:*C4g<gAGR?&14S)\\c5SV9?TS<<@9P]82_a@21i_pG,a_.Sja%7^Yf,F0gV!7[NiMaMkW,(o2o\\^1m_IDU>KO@.Y82AV#NZ%)spcTS3aL7jXR[\\N;KM='Z<gu]Ps2A9gm+31kJGG5@R"
	Notebook kwTopWin, zdata= "p3oNM,V2i-7W=n@*]GBh]GSBK1!*Lt;=SnOMjT+R#\"]\"_4.OCEApKmYnIeE*NnM6gV=(_iGmAO/F^AkJ>\\iT:f9nY8KVtf*[>R%P'6>W4FA\\uU0i5+hp^j`/@cNl2PHe[s=sO?7iYU#P%g%l%B<:>-Urdn2gdjHf32:Op2($VA=Y)cRCjUrah:]4CNl+2H\".@l5#@5OK5];0]VB2FI`iprZ8=M!-X.FK4W\"A4\\CchH7EF*F-B;8[QrUi;@^nY&:\"KNZm#.?-Rl\\EAUE=WWP/*lrNpsIe$\\B#,Kn4'\"Q*H=9Z"
	Notebook kwTopWin, zdata= "QQ*I,gsQA(F4N\\hKufe.H>$e$aX^\\KEEXVC:p=;GLI&r\\a^R5LQgr2Or0]$N&<!s5b\\@5E:WEpMa]'4q6c@#?!bXk;,KL$gJN/[5fm'rXNSeU*fV;Hp]gZ6l90NfB>cZYF:UObeQ.nRYGUROL.)f.WY]NW<\"se!jL4U\"B7r&i1JsBStb.&Y9nsJ7MgaVf@_AJqs^<;'rc<,4lF6uu1]/SNZo!?`4$^k)ZoX=^&X)&+QmGI2^icDO0LNMJ6g_]W>4Oe%`V(--L)Spd1Oge>^^nD2CG_!&V$BN=?5Ml@\\4f1\"I"
	Notebook kwTopWin, zdata= "a9[1@Ne]p)#q/)g_TJX3Df+!)p8gUmp\\iN%Wi/en\\,:V7)k3!t;>&KoG;utIN2fu9)V%hg-*!>5/n:TF6_1d#TF-<;#J_GEWlT^Q#IDB2;7k1Yk?BO/+1-.@4!8<7?]e%\"=A20MnAF@9^T$Q!])R^uD26B#Q<!q$Q3d%(`&d/f_!^[]]mV64\"u?nq&Ir#\"5ZB4:#Xo\"B&+ZS_'P@RRbGD($%Kf2)6[7MChq2</bAp?hZffo9DJt$/^PW]N3c+5f]$AAmMhe_5pl(&HqX!LgB7p2kDXm41On'0W93$(\\MK%-1"
	Notebook kwTopWin, zdata= "\"[ZjAm-NOh3\\7-@^fKP.*3l/*+4#tl\"H$:i#N@-6PVju;3,ll:R%hRYHkq.9n$d)IO%M%@eFbT^N!C>QU_dM.L8Of)`%7QGHMFC.&&3G_nB4_.no\"@\"jp\\/Z2K66_nlZosd>uA7eBeue6,2=7la5-L+4N-m?&9uuOVI`64u(u3o1E<*5fIC=%O\"&U#dd99b]?b)7A?[?)W6W:S\"KjKC_&^bPJm?Y<Bo(92)_cCR85J1r2oOH.QqX&J\";Z]6]tQ2*Ou$8Duggra66A0`=SG)&L(\\HLpEmqA>:%hS*Q4?_ZRE["
	Notebook kwTopWin, zdata= "I9Mh#APbRGV'@\"BX3_#X=E[6SOdU3kH3sd;N!b(J;aDfAMX_P\"L\"]1S:iLL2[)aRkmAqSE4Ms<`U!Xg$4N!_lH4DhQ8H*QTARHU_fA[@!J;96AHh]@V%5q6)-pcK?'7/[_NOEtN^V*[ogOipZln,oP^?>H9\\]U)9HMdO52_O>%j=n794_jljp@PhlpV$N[p8RW]m!2d`^E5]>bF+&C[f?BZf.0sQHJYFFE;[]LhA(c_/H>II4\"7`3NX?+%!9C,fW5\"tFm-TWaR=9X6*FbX3nU)TV@75SRKJ!c2;QXG']ABW:"
	Notebook kwTopWin, zdata= "q\\,13DmO3VdpDD>!U?3B>QV;t.KUK.p&Pj?.MglR\"oBa7.KR/rbO32$/sbOS.G'5Go)8_Vr2G#"
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
