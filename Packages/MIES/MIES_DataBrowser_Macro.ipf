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
	Display /W=(989.25,136.25,1421.25,571.25)/K=1  as "DataBrowser"
	Button button_BSP_open,pos={3.00,3.00},size={24.00,24.00},disable=1,proc=DB_ButtonProc_Panel
	Button button_BSP_open,title="<<",help={"Open Side Panel"}
	Button button_BSP_open,userdata(ResizeControlsInfo)=A"!!,>M!!#8L!!#=#!!#=#z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_BSP_open,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button button_BSP_open,userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetWindow kwTopWin,hook(TA_CURSOR_MOVED)=TimeAlignCursorMovedHook
	SetWindow kwTopWin,hook(cleanup)=DB_WindowHook
	SetWindow kwTopWin,hook(traceUserDataCleanup)=TUD_RemoveUserDataWave
	SetWindow kwTopWin,userdata(BROWSER)= "D"
	SetWindow kwTopWin,userdata(DEVICE)= "- none -"
	SetWindow kwTopWin,userdata(Config_PanelType)= "DataBrowser"
	SetWindow kwTopWin,userdata(ResizeControlsInfo)=A"!!*'\"z!!#C=!!#C?5QCcazzzzzzzzzzzzzzzzzzzz"
	SetWindow kwTopWin,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzzzzzzzzzzzzzzz"
	SetWindow kwTopWin,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzzzzzzzzz!!!"
	SetWindow kwTopWin,userdata(ResizeControlsHookStash)= "ResizeControls#ResizeControlsHook"
	SetWindow kwTopWin,userdata(JSONSettings_StoreCoordinates)= "1"
	SetWindow kwTopWin,userdata(JSONSettings_WindowName)= "datasweepbrowser"
	Execute/Q/Z "SetWindow kwTopWin sizeLimit={324,327,inf,inf}" // sizeLimit requires Igor 7 or later
	NewPanel/HOST=#/EXT=2/W=(0,0,580,70)  as "Sweep Control"
	Button button_SweepControl_NextSweep,pos={331.00,4.00},size={150.00,36.00},proc=BSP_ButtonProc_ChangeSweep
	Button button_SweepControl_NextSweep,title="Next  \\W649"
	Button button_SweepControl_NextSweep,help={"Displays the next sweep (sweep no. = last sweep number + step)"}
	Button button_SweepControl_NextSweep,fSize=20
	ValDisplay valdisp_SweepControl_LastSweep,pos={237.00,4.00},size={89.00,34.00},bodyWidth=60
	ValDisplay valdisp_SweepControl_LastSweep,title="of"
	ValDisplay valdisp_SweepControl_LastSweep,help={"The number of the last sweep acquired for the device assigned to the data browser"}
	ValDisplay valdisp_SweepControl_LastSweep,userdata(Config_DontRestore)="1"
	ValDisplay valdisp_SweepControl_LastSweep,userdata(Config_DontSave)="1",fSize=24
	ValDisplay valdisp_SweepControl_LastSweep,frame=2,fStyle=1
	ValDisplay valdisp_SweepControl_LastSweep,limits={0,0,0},barmisc={0,1000}
	ValDisplay valdisp_SweepControl_LastSweep,value=#"nan"
	ValDisplay valdisp_SweepControl_LastSweep,barBackColor=(56576,56576,56576)
	SetVariable setvar_SweepControl_SweepNo,pos={158.00,4.00},size={72.00,35.00},proc=DB_SetVarProc_SweepNo
	SetVariable setvar_SweepControl_SweepNo,help={"Sweep number of last sweep plotted"}
	SetVariable setvar_SweepControl_SweepNo,userdata(lastSweep)="NaN"
	SetVariable setvar_SweepControl_SweepNo,userdata(Config_DontRestore)="1"
	SetVariable setvar_SweepControl_SweepNo,userdata(Config_DontSave)="1",fSize=24
	SetVariable setvar_SweepControl_SweepNo,limits={0,0,1},value=_NUM:0,live=1
	SetVariable setvar_SweepControl_SweepStep,pos={486.00,4.00},size={91.00,35.00},bodyWidth=40
	SetVariable setvar_SweepControl_SweepStep,title="Step"
	SetVariable setvar_SweepControl_SweepStep,help={"Set the increment between sweeps"}
	SetVariable setvar_SweepControl_SweepStep,userdata(lastSweep)="0"
	SetVariable setvar_SweepControl_SweepStep,userdata(Config_DontRestore)="1"
	SetVariable setvar_SweepControl_SweepStep,userdata(Config_DontSave)="1",fSize=24
	SetVariable setvar_SweepControl_SweepStep,limits={1,inf,1},value=_NUM:1
	Button button_SweepControl_PrevSweep,pos={3.00,4.00},size={150.00,36.00},proc=BSP_ButtonProc_ChangeSweep
	Button button_SweepControl_PrevSweep,title="\\W646 Previous"
	Button button_SweepControl_PrevSweep,help={"Displays the previous sweep (sweep no. = last sweep number - step)"}
	Button button_SweepControl_PrevSweep,fSize=20
	PopupMenu Popup_SweepControl_Selector,pos={154.00,42.00},size={175.00,19.00},bodyWidth=175,disable=2
	PopupMenu Popup_SweepControl_Selector,help={"List of sweeps in this sweep browser"}
	PopupMenu Popup_SweepControl_Selector,userdata(tabnum)="0"
	PopupMenu Popup_SweepControl_Selector,userdata(tabcontrol)="Settings"
	PopupMenu Popup_SweepControl_Selector,userdata(Config_DontRestore)="1"
	PopupMenu Popup_SweepControl_Selector,userdata(Config_DontSave)="1"
	PopupMenu Popup_SweepControl_Selector,mode=1,popvalue=" ",value=#"\" \""
	CheckBox check_SweepControl_AutoUpdate,pos={343.00,44.00},size={160.00,15.00}
	CheckBox check_SweepControl_AutoUpdate,title="Display last sweep acquired"
	CheckBox check_SweepControl_AutoUpdate,help={"Displays the last sweep acquired when data acquistion is ongoing"}
	CheckBox check_SweepControl_AutoUpdate,value=1
	RenameWindow #,SweepControl
	SetActiveSubwindow ##
	NewPanel/HOST=#/EXT=1/W=(399,0,0,585)  as " "
	ModifyPanel fixedSize=0
	GroupBox group_properties_sweepFormula,pos={5.00,85.00},size={388.00,499.00},disable=1
	GroupBox group_properties_sweepFormula,userdata(tabnum)="5"
	GroupBox group_properties_sweepFormula,userdata(tabcontrol)="Settings"
	GroupBox group_properties_sweepFormula,userdata(ResizeControlsInfo)=A"!!,?X!!#?c!!#C'!!#C^J,fQL!!#](Aon#azzzzzzzzzzzzzz!!#o2B4uAeBk2=!z"
	GroupBox group_properties_sweepFormula,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#N3Bk1ct9jqaR6>q*JDf>[Vzzzzzzzz"
	GroupBox group_properties_sweepFormula,userdata(ResizeControlsInfo)+=A"zzz!!#N3Bk1ct9jqaR6>q*8Dfg)>D#aP9zzzzzzzzzz!!!"
	GroupBox group_calc,pos={28.00,195.00},size={288.00,51.00},userdata(tabnum)="0"
	GroupBox group_calc,userdata(tabcontrol)="Settings"
	GroupBox group_calc,userdata(ResizeControlsInfo)=A"!!,CD!!#AR!!#BJ!!#>Zz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	GroupBox group_calc,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	GroupBox group_calc,userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	TabControl Settings,pos={0.00,0.00},size={400.00,21.00},proc=ACL_DisplayTab
	TabControl Settings,help={"Main navigation tab"},userdata(currenttab)="0"
	TabControl Settings,userdata(finalhook)="BSP_MainTabControlFinal"
	TabControl Settings,userdata(ResizeControlsInfo)=A"!!*'\"z!!#C-!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#o2B4uAeBE3-fz"
	TabControl Settings,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	TabControl Settings,userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	TabControl Settings,tabLabel(0)="Settings",tabLabel(1)="OVS",tabLabel(2)="CS"
	TabControl Settings,tabLabel(3)="AR",tabLabel(4)="PA",tabLabel(5)="SF"
	TabControl Settings,tabLabel(6)="Note",tabLabel(7)="DS",value=0
	ListBox list_of_ranges,pos={81.00,198.00},size={223.00,380.00},disable=3,proc=OVS_MainListBoxProc
	ListBox list_of_ranges,help={"Select sweeps for overlay; The second column (\"Headstages\") allows to ignore some headstages for the graphing. Syntax is a semicolon \";\" separated list of subranges, e.g. \"0\", \"0,2\", \"1;4;2\""}
	ListBox list_of_ranges,userdata(tabnum)="1",userdata(tabcontrol)="Settings"
	ListBox list_of_ranges,userdata(ResizeControlsInfo)=A"!!,E\\!!#AU!!#An!!#C#z!!#](Aon\"Qzzzzzzzzzzzzzz!!#o2B4uAezz"
	ListBox list_of_ranges,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	ListBox list_of_ranges,userdata(ResizeControlsInfo)+=A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	ListBox list_of_ranges,userdata(Config_DontRestore)="1"
	ListBox list_of_ranges,userdata(Config_DontSave)="1",row=58,widths={50,50}
	PopupMenu popup_overlaySweeps_select,pos={123.00,99.00},size={143.00,19.00},bodyWidth=109,disable=3,proc=OVS_PopMenuProc_Select
	PopupMenu popup_overlaySweeps_select,title="Select"
	PopupMenu popup_overlaySweeps_select,help={"Select sweeps according to various properties"}
	PopupMenu popup_overlaySweeps_select,userdata(tabnum)="1"
	PopupMenu popup_overlaySweeps_select,userdata(tabcontrol)="Settings"
	PopupMenu popup_overlaySweeps_select,userdata(ResizeControlsInfo)=A"!!,F[!!#@*!!#@s!!#<Pz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	PopupMenu popup_overlaySweeps_select,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu popup_overlaySweeps_select,userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu popup_overlaySweeps_select,mode=1,popvalue="",value=#"\"\""
	CheckBox check_overlaySweeps_disableHS,pos={72.00,159.00},size={121.00,15.00},disable=3,proc=OVS_CheckBoxProc_HS_Select
	CheckBox check_overlaySweeps_disableHS,title="Headstage Removal"
	CheckBox check_overlaySweeps_disableHS,help={"Toggle headstage removal"}
	CheckBox check_overlaySweeps_disableHS,userdata(tabnum)="1"
	CheckBox check_overlaySweeps_disableHS,userdata(tabcontrol)="Settings"
	CheckBox check_overlaySweeps_disableHS,userdata(ResizeControlsInfo)=A"!!,EJ!!#A.!!#@V!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_overlaySweeps_disableHS,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_overlaySweeps_disableHS,userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_overlaySweeps_disableHS,value=0
	CheckBox check_overlaySweeps_non_commula,pos={72.00,180.00},size={154.00,15.00},disable=3
	CheckBox check_overlaySweeps_non_commula,title="Non-commulative update"
	CheckBox check_overlaySweeps_non_commula,help={"If \"Display Last sweep acquired\" is checked, this checkbox here allows to only add the newly acquired sweep and will remove the currently added last sweep."}
	CheckBox check_overlaySweeps_non_commula,userdata(tabcontrol)="Settings"
	CheckBox check_overlaySweeps_non_commula,userdata(tabnum)="1"
	CheckBox check_overlaySweeps_non_commula,userdata(ResizeControlsInfo)=A"!!,EJ!!#AC!!#A)!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_overlaySweeps_non_commula,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_overlaySweeps_non_commula,userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_overlaySweeps_non_commula,value=0
	SetVariable setvar_overlaySweeps_offset,pos={110.00,126.00},size={81.00,18.00},bodyWidth=45,disable=3,proc=OVS_SetVarProc_SelectionRange
	SetVariable setvar_overlaySweeps_offset,title="Offset"
	SetVariable setvar_overlaySweeps_offset,help={"Offsets the first selected sweep from the selection menu"}
	SetVariable setvar_overlaySweeps_offset,userdata(tabnum)="1"
	SetVariable setvar_overlaySweeps_offset,userdata(tabcontrol)="Settings"
	SetVariable setvar_overlaySweeps_offset,userdata(ResizeControlsInfo)=A"!!,FA!!#@`!!#?[!!#<Hz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	SetVariable setvar_overlaySweeps_offset,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_overlaySweeps_offset,userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_overlaySweeps_offset,limits={0,inf,1},value=_NUM:0
	SetVariable setvar_overlaySweeps_step,pos={197.00,126.00},size={72.00,18.00},bodyWidth=45,disable=3,proc=OVS_SetVarProc_SelectionRange
	SetVariable setvar_overlaySweeps_step,title="Step"
	SetVariable setvar_overlaySweeps_step,help={"Selects every `step` sweep from the selection menu"}
	SetVariable setvar_overlaySweeps_step,userdata(tabnum)="1"
	SetVariable setvar_overlaySweeps_step,userdata(tabcontrol)="Settings"
	SetVariable setvar_overlaySweeps_step,userdata(ResizeControlsInfo)=A"!!,GU!!#@`!!#?I!!#<Hz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	SetVariable setvar_overlaySweeps_step,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_overlaySweeps_step,userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_overlaySweeps_step,limits={1,inf,1},value=_NUM:1
	GroupBox group_enable_sweeps,pos={5.00,25.00},size={388.00,50.00},disable=1
	GroupBox group_enable_sweeps,title="Overlay Sweeps",userdata(tabnum)="1"
	GroupBox group_enable_sweeps,userdata(tabcontrol)="Settings"
	GroupBox group_enable_sweeps,userdata(ResizeControlsInfo)=A"!!,?X!!#=+!!#C'!!#>Vz!!#](Aon\"Qzzzzzzzzzzzzzz!!#o2B4uAezz"
	GroupBox group_enable_sweeps,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:DuaGlAStpcCh5qOGZ8U#zzzzzzzz"
	GroupBox group_enable_sweeps,userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafn!,c4SCh5qOGX?=jFDl!rzzzzzzzzzz!!!"
	GroupBox group_enable_channels,pos={9.00,25.00},size={380.00,380.00},disable=1
	GroupBox group_enable_channels,title="Channel Selection",userdata(tabnum)="2"
	GroupBox group_enable_channels,userdata(tabcontrol)="Settings"
	GroupBox group_enable_channels,userdata(ResizeControlsInfo)=A"!!,@s!!#=+!!#C#!!#C#z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	GroupBox group_enable_channels,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	GroupBox group_enable_channels,userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	GroupBox group_enable_artifact,pos={5.00,25.00},size={388.00,50.00},disable=1
	GroupBox group_enable_artifact,title="Artefact Removal",userdata(tabnum)="3"
	GroupBox group_enable_artifact,userdata(tabcontrol)="Settings"
	GroupBox group_enable_artifact,userdata(ResizeControlsInfo)=A"!!,?X!!#=+!!#C'!!#>Vz!!#](Aon#azzzzzzzzzzzzzz!!#o2B4uAeBk2=!z"
	GroupBox group_enable_artifact,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	GroupBox group_enable_artifact,userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	GroupBox group_properties_sweeps,pos={5.00,85.00},size={388.00,499.00},disable=3
	GroupBox group_properties_sweeps,userdata(tabnum)="1"
	GroupBox group_properties_sweeps,userdata(tabcontrol)="Settings"
	GroupBox group_properties_sweeps,userdata(ResizeControlsInfo)=A"!!,?X!!#?c!!#C'!!#C^J,fQL!!#](Aon\"Qzzzzzzzzzzzzzz!!#o2B4uAezz"
	GroupBox group_properties_sweeps,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	GroupBox group_properties_sweeps,userdata(ResizeControlsInfo)+=A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	GroupBox group_properties_artefact,pos={5.00,85.00},size={388.00,499.00},disable=3
	GroupBox group_properties_artefact,userdata(tabnum)="3"
	GroupBox group_properties_artefact,userdata(tabcontrol)="Settings"
	GroupBox group_properties_artefact,userdata(ResizeControlsInfo)=A"!!,?X!!#?c!!#C'!!#C^J,fQL!!#](Aon\"Qzzzzzzzzzzzzzz!!#o2B4uAezz"
	GroupBox group_properties_artefact,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	GroupBox group_properties_artefact,userdata(ResizeControlsInfo)+=A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	GroupBox group_channelSel_DA,pos={113.00,41.00},size={44.00,206.00},disable=1
	GroupBox group_channelSel_DA,title="DA",userdata(tabnum)="2"
	GroupBox group_channelSel_DA,userdata(tabcontrol)="Settings"
	GroupBox group_channelSel_DA,userdata(ResizeControlsInfo)=A"!!,FG!!#>2!!#>>!!#A]z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	GroupBox group_channelSel_DA,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	GroupBox group_channelSel_DA,userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	GroupBox group_properties_pulse,pos={9.00,84.00},size={379.00,361.00},disable=3
	GroupBox group_properties_pulse,userdata(tabnum)="4"
	GroupBox group_properties_pulse,userdata(tabcontrol)="Settings"
	GroupBox group_properties_pulse,userdata(ResizeControlsInfo)=A"!!,@s!!#?a!!#C\"J,hsDJ,fQL!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	GroupBox group_properties_pulse,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	GroupBox group_properties_pulse,userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	GroupBox group_enable_pulse,pos={9.00,25.00},size={380.00,50.00},disable=1
	GroupBox group_enable_pulse,title="Pulse Averaging",userdata(tabnum)="4"
	GroupBox group_enable_pulse,userdata(tabcontrol)="Settings"
	GroupBox group_enable_pulse,userdata(ResizeControlsInfo)=A"!!,@s!!#=+!!#C#!!#>Vz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	GroupBox group_enable_pulse,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	GroupBox group_enable_pulse,userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_DA_0,pos={121.00,60.00},size={22.00,15.00},disable=1,proc=BSP_CheckProc_ChangedSetting
	CheckBox check_channelSel_DA_0,title="0",help={"Toggle the DA channel display"}
	CheckBox check_channelSel_DA_0,userdata(tabnum)="2"
	CheckBox check_channelSel_DA_0,userdata(tabcontrol)="Settings"
	CheckBox check_channelSel_DA_0,userdata(ResizeControlsInfo)=A"!!,FW!!#?)!!#<h!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_DA_0,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_DA_0,userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_DA_0,userdata(ControlArray)="DA Channel selection"
	CheckBox check_channelSel_DA_0,userdata(ControlArrayIndex)="0",value=1
	CheckBox check_channelSel_DA_1,pos={121.00,81.00},size={22.00,15.00},disable=1,proc=BSP_CheckProc_ChangedSetting
	CheckBox check_channelSel_DA_1,title="1",help={"Toggle the DA channel display"}
	CheckBox check_channelSel_DA_1,userdata(tabnum)="2"
	CheckBox check_channelSel_DA_1,userdata(tabcontrol)="Settings"
	CheckBox check_channelSel_DA_1,userdata(ResizeControlsInfo)=A"!!,FW!!#?[!!#<h!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_DA_1,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_DA_1,userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_DA_1,userdata(ControlArray)="DA Channel selection"
	CheckBox check_channelSel_DA_1,userdata(ControlArrayIndex)="1",value=1
	CheckBox check_channelSel_DA_2,pos={121.00,102.00},size={22.00,15.00},disable=1,proc=BSP_CheckProc_ChangedSetting
	CheckBox check_channelSel_DA_2,title="2",help={"Toggle the DA channel display"}
	CheckBox check_channelSel_DA_2,userdata(tabnum)="2"
	CheckBox check_channelSel_DA_2,userdata(tabcontrol)="Settings"
	CheckBox check_channelSel_DA_2,userdata(ResizeControlsInfo)=A"!!,FW!!#@0!!#<h!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_DA_2,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_DA_2,userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_DA_2,userdata(ControlArray)="DA Channel selection"
	CheckBox check_channelSel_DA_2,userdata(ControlArrayIndex)="2",value=1
	CheckBox check_channelSel_DA_3,pos={121.00,123.00},size={22.00,15.00},disable=1,proc=BSP_CheckProc_ChangedSetting
	CheckBox check_channelSel_DA_3,title="3",help={"Toggle the DA channel display"}
	CheckBox check_channelSel_DA_3,userdata(tabnum)="2"
	CheckBox check_channelSel_DA_3,userdata(tabcontrol)="Settings"
	CheckBox check_channelSel_DA_3,userdata(ResizeControlsInfo)=A"!!,FW!!#@Z!!#<h!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_DA_3,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_DA_3,userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_DA_3,userdata(ControlArray)="DA Channel selection"
	CheckBox check_channelSel_DA_3,userdata(ControlArrayIndex)="3",value=1
	CheckBox check_channelSel_DA_4,pos={121.00,144.00},size={22.00,15.00},disable=1,proc=BSP_CheckProc_ChangedSetting
	CheckBox check_channelSel_DA_4,title="4",help={"Toggle the DA channel display"}
	CheckBox check_channelSel_DA_4,userdata(tabnum)="2"
	CheckBox check_channelSel_DA_4,userdata(tabcontrol)="Settings"
	CheckBox check_channelSel_DA_4,userdata(ResizeControlsInfo)=A"!!,FW!!#@t!!#<h!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_DA_4,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_DA_4,userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_DA_4,userdata(ControlArray)="DA Channel selection"
	CheckBox check_channelSel_DA_4,userdata(ControlArrayIndex)="4",value=1
	CheckBox check_channelSel_DA_5,pos={121.00,165.00},size={22.00,15.00},disable=1,proc=BSP_CheckProc_ChangedSetting
	CheckBox check_channelSel_DA_5,title="5",help={"Toggle the DA channel display"}
	CheckBox check_channelSel_DA_5,userdata(tabnum)="2"
	CheckBox check_channelSel_DA_5,userdata(tabcontrol)="Settings"
	CheckBox check_channelSel_DA_5,userdata(ResizeControlsInfo)=A"!!,FW!!#A4!!#<h!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_DA_5,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_DA_5,userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_DA_5,userdata(ControlArray)="DA Channel selection"
	CheckBox check_channelSel_DA_5,userdata(ControlArrayIndex)="5",value=1
	CheckBox check_channelSel_DA_6,pos={121.00,186.00},size={22.00,15.00},disable=1,proc=BSP_CheckProc_ChangedSetting
	CheckBox check_channelSel_DA_6,title="6",help={"Toggle the DA channel display"}
	CheckBox check_channelSel_DA_6,userdata(tabnum)="2"
	CheckBox check_channelSel_DA_6,userdata(tabcontrol)="Settings"
	CheckBox check_channelSel_DA_6,userdata(ResizeControlsInfo)=A"!!,FW!!#AI!!#<h!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_DA_6,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_DA_6,userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_DA_6,userdata(ControlArray)="DA Channel selection"
	CheckBox check_channelSel_DA_6,userdata(ControlArrayIndex)="6",value=1
	CheckBox check_channelSel_DA_7,pos={121.00,207.00},size={22.00,15.00},disable=1,proc=BSP_CheckProc_ChangedSetting
	CheckBox check_channelSel_DA_7,title="7",help={"Toggle the DA channel display"}
	CheckBox check_channelSel_DA_7,userdata(tabnum)="2"
	CheckBox check_channelSel_DA_7,userdata(tabcontrol)="Settings"
	CheckBox check_channelSel_DA_7,userdata(ResizeControlsInfo)=A"!!,FW!!#A^!!#<h!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_DA_7,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_DA_7,userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_DA_7,userdata(ControlArray)="DA Channel selection"
	CheckBox check_channelSel_DA_7,userdata(ControlArrayIndex)="7",value=1
	GroupBox group_channelSel_HEADSTAGE,pos={49.00,42.00},size={46.00,206.00},disable=1
	GroupBox group_channelSel_HEADSTAGE,title="HS",userdata(tabnum)="2"
	GroupBox group_channelSel_HEADSTAGE,userdata(tabcontrol)="Settings"
	GroupBox group_channelSel_HEADSTAGE,userdata(ResizeControlsInfo)=A"!!,DS!!#>6!!#>F!!#A]z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	GroupBox group_channelSel_HEADSTAGE,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	GroupBox group_channelSel_HEADSTAGE,userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_HEADSTAGE_0,pos={58.00,60.00},size={22.00,15.00},disable=1,proc=BSP_CheckProc_ChangedSetting
	CheckBox check_channelSel_HEADSTAGE_0,title="0"
	CheckBox check_channelSel_HEADSTAGE_0,help={"Toggle the headstage display"}
	CheckBox check_channelSel_HEADSTAGE_0,userdata(tabnum)="2"
	CheckBox check_channelSel_HEADSTAGE_0,userdata(tabcontrol)="Settings"
	CheckBox check_channelSel_HEADSTAGE_0,userdata(ResizeControlsInfo)=A"!!,E\"!!#?)!!#<h!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_HEADSTAGE_0,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_HEADSTAGE_0,userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_HEADSTAGE_0,userdata(ControlArrayIndex)="0"
	CheckBox check_channelSel_HEADSTAGE_0,userdata(ControlArray)="Headstage Channel selection"
	CheckBox check_channelSel_HEADSTAGE_0,value=1
	CheckBox check_channelSel_HEADSTAGE_1,pos={58.00,81.00},size={22.00,15.00},disable=1,proc=BSP_CheckProc_ChangedSetting
	CheckBox check_channelSel_HEADSTAGE_1,title="1"
	CheckBox check_channelSel_HEADSTAGE_1,help={"Toggle the headstage display"}
	CheckBox check_channelSel_HEADSTAGE_1,userdata(tabnum)="2"
	CheckBox check_channelSel_HEADSTAGE_1,userdata(tabcontrol)="Settings"
	CheckBox check_channelSel_HEADSTAGE_1,userdata(ResizeControlsInfo)=A"!!,E\"!!#?[!!#<h!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_HEADSTAGE_1,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_HEADSTAGE_1,userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_HEADSTAGE_1,userdata(ControlArrayIndex)="1"
	CheckBox check_channelSel_HEADSTAGE_1,userdata(ControlArray)="Headstage Channel selection"
	CheckBox check_channelSel_HEADSTAGE_1,value=1
	CheckBox check_channelSel_HEADSTAGE_2,pos={58.00,102.00},size={22.00,15.00},disable=1,proc=BSP_CheckProc_ChangedSetting
	CheckBox check_channelSel_HEADSTAGE_2,title="2"
	CheckBox check_channelSel_HEADSTAGE_2,help={"Toggle the headstage display"}
	CheckBox check_channelSel_HEADSTAGE_2,userdata(tabnum)="2"
	CheckBox check_channelSel_HEADSTAGE_2,userdata(tabcontrol)="Settings"
	CheckBox check_channelSel_HEADSTAGE_2,userdata(ResizeControlsInfo)=A"!!,E\"!!#@0!!#<h!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_HEADSTAGE_2,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_HEADSTAGE_2,userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_HEADSTAGE_2,userdata(ControlArrayIndex)="2"
	CheckBox check_channelSel_HEADSTAGE_2,userdata(ControlArray)="Headstage Channel selection"
	CheckBox check_channelSel_HEADSTAGE_2,value=1
	CheckBox check_channelSel_HEADSTAGE_3,pos={58.00,123.00},size={22.00,15.00},disable=1,proc=BSP_CheckProc_ChangedSetting
	CheckBox check_channelSel_HEADSTAGE_3,title="3"
	CheckBox check_channelSel_HEADSTAGE_3,help={"Toggle the headstage display"}
	CheckBox check_channelSel_HEADSTAGE_3,userdata(tabnum)="2"
	CheckBox check_channelSel_HEADSTAGE_3,userdata(tabcontrol)="Settings"
	CheckBox check_channelSel_HEADSTAGE_3,userdata(ResizeControlsInfo)=A"!!,E\"!!#@Z!!#<h!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_HEADSTAGE_3,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_HEADSTAGE_3,userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_HEADSTAGE_3,userdata(ControlArrayIndex)="3"
	CheckBox check_channelSel_HEADSTAGE_3,userdata(ControlArray)="Headstage Channel selection"
	CheckBox check_channelSel_HEADSTAGE_3,value=1
	CheckBox check_channelSel_HEADSTAGE_4,pos={58.00,144.00},size={22.00,15.00},disable=1,proc=BSP_CheckProc_ChangedSetting
	CheckBox check_channelSel_HEADSTAGE_4,title="4"
	CheckBox check_channelSel_HEADSTAGE_4,help={"Toggle the headstage display"}
	CheckBox check_channelSel_HEADSTAGE_4,userdata(tabnum)="2"
	CheckBox check_channelSel_HEADSTAGE_4,userdata(tabcontrol)="Settings"
	CheckBox check_channelSel_HEADSTAGE_4,userdata(ResizeControlsInfo)=A"!!,E\"!!#@t!!#<h!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_HEADSTAGE_4,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_HEADSTAGE_4,userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_HEADSTAGE_4,userdata(ControlArrayIndex)="4"
	CheckBox check_channelSel_HEADSTAGE_4,userdata(ControlArray)="Headstage Channel selection"
	CheckBox check_channelSel_HEADSTAGE_4,value=1
	CheckBox check_channelSel_HEADSTAGE_5,pos={58.00,165.00},size={22.00,15.00},disable=1,proc=BSP_CheckProc_ChangedSetting
	CheckBox check_channelSel_HEADSTAGE_5,title="5"
	CheckBox check_channelSel_HEADSTAGE_5,help={"Toggle the headstage display"}
	CheckBox check_channelSel_HEADSTAGE_5,userdata(tabnum)="2"
	CheckBox check_channelSel_HEADSTAGE_5,userdata(tabcontrol)="Settings"
	CheckBox check_channelSel_HEADSTAGE_5,userdata(ResizeControlsInfo)=A"!!,E\"!!#A4!!#<h!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_HEADSTAGE_5,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_HEADSTAGE_5,userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_HEADSTAGE_5,userdata(ControlArrayIndex)="5"
	CheckBox check_channelSel_HEADSTAGE_5,userdata(ControlArray)="Headstage Channel selection"
	CheckBox check_channelSel_HEADSTAGE_5,value=1
	CheckBox check_channelSel_HEADSTAGE_6,pos={58.00,186.00},size={22.00,15.00},disable=1,proc=BSP_CheckProc_ChangedSetting
	CheckBox check_channelSel_HEADSTAGE_6,title="6"
	CheckBox check_channelSel_HEADSTAGE_6,help={"Toggle the headstage display"}
	CheckBox check_channelSel_HEADSTAGE_6,userdata(tabnum)="2"
	CheckBox check_channelSel_HEADSTAGE_6,userdata(tabcontrol)="Settings"
	CheckBox check_channelSel_HEADSTAGE_6,userdata(ResizeControlsInfo)=A"!!,E\"!!#AI!!#<h!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_HEADSTAGE_6,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_HEADSTAGE_6,userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_HEADSTAGE_6,userdata(ControlArrayIndex)="6"
	CheckBox check_channelSel_HEADSTAGE_6,userdata(ControlArray)="Headstage Channel selection"
	CheckBox check_channelSel_HEADSTAGE_6,value=1
	CheckBox check_channelSel_HEADSTAGE_7,pos={58.00,207.00},size={22.00,15.00},disable=1,proc=BSP_CheckProc_ChangedSetting
	CheckBox check_channelSel_HEADSTAGE_7,title="7"
	CheckBox check_channelSel_HEADSTAGE_7,help={"Toggle the headstage display"}
	CheckBox check_channelSel_HEADSTAGE_7,userdata(tabnum)="2"
	CheckBox check_channelSel_HEADSTAGE_7,userdata(tabcontrol)="Settings"
	CheckBox check_channelSel_HEADSTAGE_7,userdata(ResizeControlsInfo)=A"!!,E\"!!#A^!!#<h!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_HEADSTAGE_7,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_HEADSTAGE_7,userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_HEADSTAGE_7,userdata(ControlArrayIndex)="7"
	CheckBox check_channelSel_HEADSTAGE_7,userdata(ControlArray)="Headstage Channel selection"
	CheckBox check_channelSel_HEADSTAGE_7,value=1
	GroupBox group_channelSel_AD,pos={171.00,42.00},size={65.00,204.00},disable=1
	GroupBox group_channelSel_AD,title="AD",userdata(tabnum)="2"
	GroupBox group_channelSel_AD,userdata(tabcontrol)="Settings"
	GroupBox group_channelSel_AD,userdata(ResizeControlsInfo)=A"!!,G;!!#>6!!#?;!!#A[z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	GroupBox group_channelSel_AD,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	GroupBox group_channelSel_AD,userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_AD_0,pos={178.00,60.00},size={22.00,15.00},disable=1,proc=BSP_CheckProc_ChangedSetting
	CheckBox check_channelSel_AD_0,title="0",help={"Toggle the AD channel display"}
	CheckBox check_channelSel_AD_0,userdata(tabnum)="2"
	CheckBox check_channelSel_AD_0,userdata(tabcontrol)="Settings"
	CheckBox check_channelSel_AD_0,userdata(ResizeControlsInfo)=A"!!,GB!!#?)!!#<h!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_AD_0,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_AD_0,userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_AD_0,userdata(ControlArray)="AD Channel selection"
	CheckBox check_channelSel_AD_0,userdata(ControlArrayIndex)="0",value=1
	CheckBox check_channelSel_AD_1,pos={178.00,81.00},size={22.00,15.00},disable=1,proc=BSP_CheckProc_ChangedSetting
	CheckBox check_channelSel_AD_1,title="1",help={"Toggle the AD channel display"}
	CheckBox check_channelSel_AD_1,userdata(tabnum)="2"
	CheckBox check_channelSel_AD_1,userdata(tabcontrol)="Settings"
	CheckBox check_channelSel_AD_1,userdata(ResizeControlsInfo)=A"!!,GB!!#?[!!#<h!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_AD_1,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_AD_1,userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_AD_1,userdata(ControlArray)="AD Channel selection"
	CheckBox check_channelSel_AD_1,userdata(ControlArrayIndex)="1",value=1
	CheckBox check_channelSel_AD_2,pos={178.00,102.00},size={22.00,15.00},disable=1,proc=BSP_CheckProc_ChangedSetting
	CheckBox check_channelSel_AD_2,title="2",help={"Toggle the AD channel display"}
	CheckBox check_channelSel_AD_2,userdata(tabnum)="2"
	CheckBox check_channelSel_AD_2,userdata(tabcontrol)="Settings"
	CheckBox check_channelSel_AD_2,userdata(ResizeControlsInfo)=A"!!,GB!!#@0!!#<h!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_AD_2,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_AD_2,userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_AD_2,userdata(ControlArray)="AD Channel selection"
	CheckBox check_channelSel_AD_2,userdata(ControlArrayIndex)="2",value=1
	CheckBox check_channelSel_AD_3,pos={178.00,123.00},size={22.00,15.00},disable=1,proc=BSP_CheckProc_ChangedSetting
	CheckBox check_channelSel_AD_3,title="3",help={"Toggle the AD channel display"}
	CheckBox check_channelSel_AD_3,userdata(tabnum)="2"
	CheckBox check_channelSel_AD_3,userdata(tabcontrol)="Settings"
	CheckBox check_channelSel_AD_3,userdata(ResizeControlsInfo)=A"!!,GB!!#@Z!!#<h!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_AD_3,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_AD_3,userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_AD_3,userdata(ControlArray)="AD Channel selection"
	CheckBox check_channelSel_AD_3,userdata(ControlArrayIndex)="3",value=1
	CheckBox check_channelSel_AD_4,pos={178.00,144.00},size={22.00,15.00},disable=1,proc=BSP_CheckProc_ChangedSetting
	CheckBox check_channelSel_AD_4,title="4",help={"Toggle the AD channel display"}
	CheckBox check_channelSel_AD_4,userdata(tabnum)="2"
	CheckBox check_channelSel_AD_4,userdata(tabcontrol)="Settings"
	CheckBox check_channelSel_AD_4,userdata(ResizeControlsInfo)=A"!!,GB!!#@t!!#<h!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_AD_4,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_AD_4,userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_AD_4,userdata(ControlArray)="AD Channel selection"
	CheckBox check_channelSel_AD_4,userdata(ControlArrayIndex)="4",value=1
	CheckBox check_channelSel_AD_5,pos={178.00,165.00},size={22.00,15.00},disable=1,proc=BSP_CheckProc_ChangedSetting
	CheckBox check_channelSel_AD_5,title="5",help={"Toggle the AD channel display"}
	CheckBox check_channelSel_AD_5,userdata(tabnum)="2"
	CheckBox check_channelSel_AD_5,userdata(tabcontrol)="Settings"
	CheckBox check_channelSel_AD_5,userdata(ResizeControlsInfo)=A"!!,GB!!#A4!!#<h!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_AD_5,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_AD_5,userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_AD_5,userdata(ControlArray)="AD Channel selection"
	CheckBox check_channelSel_AD_5,userdata(ControlArrayIndex)="5",value=1
	CheckBox check_channelSel_AD_6,pos={178.00,186.00},size={22.00,15.00},disable=1,proc=BSP_CheckProc_ChangedSetting
	CheckBox check_channelSel_AD_6,title="6",help={"Toggle the AD channel display"}
	CheckBox check_channelSel_AD_6,userdata(tabnum)="2"
	CheckBox check_channelSel_AD_6,userdata(tabcontrol)="Settings"
	CheckBox check_channelSel_AD_6,userdata(ResizeControlsInfo)=A"!!,GB!!#AI!!#<h!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_AD_6,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_AD_6,userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_AD_6,userdata(ControlArray)="AD Channel selection"
	CheckBox check_channelSel_AD_6,userdata(ControlArrayIndex)="6",value=1
	CheckBox check_channelSel_AD_7,pos={178.00,207.00},size={22.00,15.00},disable=1,proc=BSP_CheckProc_ChangedSetting
	CheckBox check_channelSel_AD_7,title="7",help={"Toggle the AD channel display"}
	CheckBox check_channelSel_AD_7,userdata(tabnum)="2"
	CheckBox check_channelSel_AD_7,userdata(tabcontrol)="Settings"
	CheckBox check_channelSel_AD_7,userdata(ResizeControlsInfo)=A"!!,GB!!#A^!!#<h!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_AD_7,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_AD_7,userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_AD_7,userdata(ControlArray)="AD Channel selection"
	CheckBox check_channelSel_AD_7,userdata(ControlArrayIndex)="7",value=1
	CheckBox check_channelSel_AD_8,pos={203.00,60.00},size={22.00,15.00},disable=1,proc=BSP_CheckProc_ChangedSetting
	CheckBox check_channelSel_AD_8,title="8",help={"Toggle the AD channel display"}
	CheckBox check_channelSel_AD_8,userdata(tabnum)="2"
	CheckBox check_channelSel_AD_8,userdata(tabcontrol)="Settings"
	CheckBox check_channelSel_AD_8,userdata(ResizeControlsInfo)=A"!!,G[!!#?)!!#<h!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_AD_8,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_AD_8,userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_AD_8,userdata(ControlArray)="AD Channel selection"
	CheckBox check_channelSel_AD_8,userdata(ControlArrayIndex)="8",value=1
	CheckBox check_channelSel_AD_9,pos={203.00,81.00},size={22.00,15.00},disable=1,proc=BSP_CheckProc_ChangedSetting
	CheckBox check_channelSel_AD_9,title="9",help={"Toggle the AD channel display"}
	CheckBox check_channelSel_AD_9,userdata(tabnum)="2"
	CheckBox check_channelSel_AD_9,userdata(tabcontrol)="Settings"
	CheckBox check_channelSel_AD_9,userdata(ResizeControlsInfo)=A"!!,G[!!#?[!!#<h!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_AD_9,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_AD_9,userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_AD_9,userdata(ControlArray)="AD Channel selection"
	CheckBox check_channelSel_AD_9,userdata(ControlArrayIndex)="9",value=1
	CheckBox check_channelSel_AD_10,pos={203.00,102.00},size={28.00,15.00},disable=1,proc=BSP_CheckProc_ChangedSetting
	CheckBox check_channelSel_AD_10,title="10"
	CheckBox check_channelSel_AD_10,help={"Toggle the AD channel display"}
	CheckBox check_channelSel_AD_10,userdata(tabnum)="2"
	CheckBox check_channelSel_AD_10,userdata(tabcontrol)="Settings"
	CheckBox check_channelSel_AD_10,userdata(ResizeControlsInfo)=A"!!,G[!!#@0!!#=C!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_AD_10,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_AD_10,userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_AD_10,userdata(ControlArray)="AD Channel selection"
	CheckBox check_channelSel_AD_10,userdata(ControlArrayIndex)="10",value=1
	CheckBox check_channelSel_AD_11,pos={203.00,123.00},size={28.00,15.00},disable=1,proc=BSP_CheckProc_ChangedSetting
	CheckBox check_channelSel_AD_11,title="11"
	CheckBox check_channelSel_AD_11,help={"Toggle the AD channel display"}
	CheckBox check_channelSel_AD_11,userdata(tabnum)="2"
	CheckBox check_channelSel_AD_11,userdata(tabcontrol)="Settings"
	CheckBox check_channelSel_AD_11,userdata(ResizeControlsInfo)=A"!!,G[!!#@Z!!#=C!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_AD_11,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_AD_11,userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_AD_11,userdata(ControlArray)="AD Channel selection"
	CheckBox check_channelSel_AD_11,userdata(ControlArrayIndex)="11",value=1
	CheckBox check_channelSel_AD_12,pos={203.00,144.00},size={28.00,15.00},disable=1,proc=BSP_CheckProc_ChangedSetting
	CheckBox check_channelSel_AD_12,title="12"
	CheckBox check_channelSel_AD_12,help={"Toggle the AD channel display"}
	CheckBox check_channelSel_AD_12,userdata(tabnum)="2"
	CheckBox check_channelSel_AD_12,userdata(tabcontrol)="Settings"
	CheckBox check_channelSel_AD_12,userdata(ResizeControlsInfo)=A"!!,G[!!#@t!!#=C!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_AD_12,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_AD_12,userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_AD_12,userdata(ControlArray)="AD Channel selection"
	CheckBox check_channelSel_AD_12,userdata(ControlArrayIndex)="12",value=1
	CheckBox check_channelSel_AD_13,pos={203.00,165.00},size={28.00,15.00},disable=1,proc=BSP_CheckProc_ChangedSetting
	CheckBox check_channelSel_AD_13,title="13"
	CheckBox check_channelSel_AD_13,help={"Toggle the AD channel display"}
	CheckBox check_channelSel_AD_13,userdata(tabnum)="2"
	CheckBox check_channelSel_AD_13,userdata(tabcontrol)="Settings"
	CheckBox check_channelSel_AD_13,userdata(ResizeControlsInfo)=A"!!,G[!!#A4!!#=C!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_AD_13,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_AD_13,userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_AD_13,userdata(ControlArray)="AD Channel selection"
	CheckBox check_channelSel_AD_13,userdata(ControlArrayIndex)="13",value=1
	CheckBox check_channelSel_AD_14,pos={203.00,186.00},size={28.00,15.00},disable=1,proc=BSP_CheckProc_ChangedSetting
	CheckBox check_channelSel_AD_14,title="14"
	CheckBox check_channelSel_AD_14,help={"Toggle the AD channel display"}
	CheckBox check_channelSel_AD_14,userdata(tabnum)="2"
	CheckBox check_channelSel_AD_14,userdata(tabcontrol)="Settings"
	CheckBox check_channelSel_AD_14,userdata(ResizeControlsInfo)=A"!!,G[!!#AI!!#=C!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_AD_14,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_AD_14,userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_AD_14,userdata(ControlArray)="AD Channel selection"
	CheckBox check_channelSel_AD_14,userdata(ControlArrayIndex)="14",value=1
	CheckBox check_channelSel_AD_15,pos={203.00,207.00},size={28.00,15.00},disable=1,proc=BSP_CheckProc_ChangedSetting
	CheckBox check_channelSel_AD_15,title="15"
	CheckBox check_channelSel_AD_15,help={"Toggle the AD channel display"}
	CheckBox check_channelSel_AD_15,userdata(tabnum)="2"
	CheckBox check_channelSel_AD_15,userdata(tabcontrol)="Settings"
	CheckBox check_channelSel_AD_15,userdata(ResizeControlsInfo)=A"!!,G[!!#A^!!#=C!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_AD_15,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_AD_15,userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_AD_15,userdata(ControlArray)="AD Channel selection"
	CheckBox check_channelSel_AD_15,userdata(ControlArrayIndex)="15",value=1
	ListBox list_of_ranges1,pos={75.00,156.00},size={235.00,421.00},disable=3,proc=AR_MainListBoxProc
	ListBox list_of_ranges1,help={"List of artefact ranges"},userdata(tabnum)="3"
	ListBox list_of_ranges1,userdata(tabcontrol)="Settings"
	ListBox list_of_ranges1,userdata(ResizeControlsInfo)=A"!!,EP!!#A+!!#B%!!#C7J,fQL!!#](Aon\"Qzzzzzzzzzzzzzz!!#o2B4uAezz"
	ListBox list_of_ranges1,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	ListBox list_of_ranges1,userdata(ResizeControlsInfo)+=A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	ListBox list_of_ranges1,userdata(Config_DontRestore)="1"
	ListBox list_of_ranges1,userdata(Config_DontSave)="1",mode=1,selRow=0
	ListBox list_of_ranges1,widths={54,50,66}
	Button button_RemoveRanges,pos={91.00,126.00},size={54.00,21.00},disable=3,proc=AR_ButtonProc_RemoveRanges
	Button button_RemoveRanges,title="Remove",help={"Remove the found artefacts"}
	Button button_RemoveRanges,userdata(tabnum)="3",userdata(tabcontrol)="Settings"
	Button button_RemoveRanges,userdata(ResizeControlsInfo)=A"!!,Ep!!#@`!!#>f!!#<`z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	Button button_RemoveRanges,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button button_RemoveRanges,userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_cutoff_length_after,pos={247.00,96.00},size={45.00,18.00},disable=3,proc=AR_SetVarProcCutoffLength
	SetVariable setvar_cutoff_length_after,help={"Time in ms which should be cutoff *after* the artefact."}
	SetVariable setvar_cutoff_length_after,userdata(tabnum)="3"
	SetVariable setvar_cutoff_length_after,userdata(tabcontrol)="Settings"
	SetVariable setvar_cutoff_length_after,userdata(ResizeControlsInfo)=A"!!,H2!!#@$!!#>B!!#<Hz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	SetVariable setvar_cutoff_length_after,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_cutoff_length_after,userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_cutoff_length_after,limits={0,inf,0.1},value=_NUM:0.2
	SetVariable setvar_cutoff_length_before,pos={94.00,96.00},size={150.00,18.00},disable=3,proc=AR_SetVarProcCutoffLength
	SetVariable setvar_cutoff_length_before,title="Cutoff length [ms]:"
	SetVariable setvar_cutoff_length_before,help={"Time in ms which should be cutoff *before* the artefact."}
	SetVariable setvar_cutoff_length_before,userdata(tabnum)="3"
	SetVariable setvar_cutoff_length_before,userdata(tabcontrol)="Settings"
	SetVariable setvar_cutoff_length_before,userdata(ResizeControlsInfo)=A"!!,F!!!#@$!!#A%!!#<Hz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	SetVariable setvar_cutoff_length_before,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_cutoff_length_before,userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_cutoff_length_before,limits={0,inf,0.1},value=_NUM:0.1
	CheckBox check_auto_remove,pos={160.00,129.00},size={85.00,15.00},disable=3,proc=AR_CheckProc_Update
	CheckBox check_auto_remove,title="Auto remove"
	CheckBox check_auto_remove,help={"Automatically remove the found ranges on sweep plotting"}
	CheckBox check_auto_remove,userdata(tabnum)="3",userdata(tabcontrol)="Settings"
	CheckBox check_auto_remove,userdata(ResizeControlsInfo)=A"!!,G0!!#@e!!#?c!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_auto_remove,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_auto_remove,userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_auto_remove,value=0
	CheckBox check_highlightRanges,pos={262.00,129.00},size={31.00,15.00},disable=3,proc=AR_CheckProc_Update
	CheckBox check_highlightRanges,title="HL"
	CheckBox check_highlightRanges,help={"Visualize the found ranges in the graph (*might* slowdown graphing)"}
	CheckBox check_highlightRanges,userdata(tabnum)="3"
	CheckBox check_highlightRanges,userdata(tabcontrol)="Settings"
	CheckBox check_highlightRanges,userdata(ResizeControlsInfo)=A"!!,H>!!#@e!!#=[!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_highlightRanges,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_highlightRanges,userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_highlightRanges,value=0
	SetVariable setvar_pulseAver_overridePulseLength,pos={214.00,296.00},size={136.00,18.00},bodyWidth=50,disable=1,proc=PA_SetVarProc_Common
	SetVariable setvar_pulseAver_overridePulseLength,title="Override length"
	SetVariable setvar_pulseAver_overridePulseLength,help={"Pulse To Pulse length in ms for edge cases which can not be computed or when the override checkbox is active."}
	SetVariable setvar_pulseAver_overridePulseLength,userdata(tabnum)="4"
	SetVariable setvar_pulseAver_overridePulseLength,userdata(tabcontrol)="Settings"
	SetVariable setvar_pulseAver_overridePulseLength,userdata(ResizeControlsInfo)=A"!!,Gf!!#BN!!#@l!!#<Hz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	SetVariable setvar_pulseAver_overridePulseLength,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_pulseAver_overridePulseLength,userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_pulseAver_overridePulseLength,limits={0,inf,1},value=_NUM:10
	SetVariable setvar_pulseAver_endPulse,pos={218.00,254.00},size={122.00,18.00},bodyWidth=50,disable=1,proc=PA_SetVarProc_Common
	SetVariable setvar_pulseAver_endPulse,title="Ending pulse"
	SetVariable setvar_pulseAver_endPulse,help={"Index of the last pulse to display"}
	SetVariable setvar_pulseAver_endPulse,userdata(tabnum)="4"
	SetVariable setvar_pulseAver_endPulse,userdata(tabcontrol)="Settings"
	SetVariable setvar_pulseAver_endPulse,userdata(ResizeControlsInfo)=A"!!,Gj!!#B8!!#@X!!#<Hz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	SetVariable setvar_pulseAver_endPulse,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_pulseAver_endPulse,userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_pulseAver_endPulse,limits={0,inf,1},value=_NUM:inf
	SetVariable setvar_pulseAver_startPulse,pos={214.00,232.00},size={126.00,18.00},bodyWidth=50,disable=1,proc=PA_SetVarProc_Common
	SetVariable setvar_pulseAver_startPulse,title="Starting pulse"
	SetVariable setvar_pulseAver_startPulse,help={"Index of the first pulse to display"}
	SetVariable setvar_pulseAver_startPulse,userdata(tabnum)="4"
	SetVariable setvar_pulseAver_startPulse,userdata(tabcontrol)="Settings"
	SetVariable setvar_pulseAver_startPulse,userdata(ResizeControlsInfo)=A"!!,Gf!!#B\"!!#@`!!#<Hz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	SetVariable setvar_pulseAver_startPulse,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_pulseAver_startPulse,userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_pulseAver_startPulse,limits={0,inf,1},value=_NUM:0
	CheckBox check_pulseAver_multGraphs,pos={212.00,165.00},size={121.00,15.00},disable=1,proc=PA_CheckProc_Common
	CheckBox check_pulseAver_multGraphs,title="Use multiple graphs"
	CheckBox check_pulseAver_multGraphs,help={"Show the single pulses in multiple graphs or only one graph with mutiple axis."}
	CheckBox check_pulseAver_multGraphs,userdata(tabnum)="4"
	CheckBox check_pulseAver_multGraphs,userdata(tabcontrol)="Settings"
	CheckBox check_pulseAver_multGraphs,userdata(ResizeControlsInfo)=A"!!,Gd!!#A4!!#@V!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_pulseAver_multGraphs,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_pulseAver_multGraphs,userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_pulseAver_multGraphs,value=0
	CheckBox check_pulseAver_zero,pos={212.00,108.00},size={76.00,15.00},disable=1,proc=PA_CheckProc_Common
	CheckBox check_pulseAver_zero,title="Zero pulses"
	CheckBox check_pulseAver_zero,help={"Zero the individual traces using subsequent differentiation and integration"}
	CheckBox check_pulseAver_zero,userdata(tabnum)="4"
	CheckBox check_pulseAver_zero,userdata(tabcontrol)="Settings"
	CheckBox check_pulseAver_zero,userdata(ResizeControlsInfo)=A"!!,Gd!!#@<!!#?Q!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_pulseAver_zero,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_pulseAver_zero,userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_pulseAver_zero,value=0
	CheckBox check_pulseAver_showAver,pos={212.00,146.00},size={89.00,15.00},disable=1,proc=PA_CheckProc_Common
	CheckBox check_pulseAver_showAver,title="Show average"
	CheckBox check_pulseAver_showAver,help={"Show the average trace"}
	CheckBox check_pulseAver_showAver,userdata(tabnum)="4"
	CheckBox check_pulseAver_showAver,userdata(tabcontrol)="Settings"
	CheckBox check_pulseAver_showAver,userdata(ResizeControlsInfo)=A"!!,Gd!!#A!!!#?k!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_pulseAver_showAver,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_pulseAver_showAver,userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_pulseAver_showAver,value=0
	CheckBox check_pulseAver_indPulses,pos={212.00,183.00},size={136.00,15.00},disable=1,proc=PA_CheckProc_Common
	CheckBox check_pulseAver_indPulses,title="Show individual pulses"
	CheckBox check_pulseAver_indPulses,help={"Show the individual pulses in the plot"}
	CheckBox check_pulseAver_indPulses,userdata(tabnum)="4"
	CheckBox check_pulseAver_indPulses,userdata(tabcontrol)="Settings"
	CheckBox check_pulseAver_indPulses,userdata(ResizeControlsInfo)=A"!!,Gd!!#AF!!#@l!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_pulseAver_indPulses,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_pulseAver_indPulses,userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_pulseAver_indPulses,value=1
	CheckBox check_pulseAver_deconv,pos={71.00,340.00},size={94.00,15.00},disable=1,proc=PA_CheckProc_Common
	CheckBox check_pulseAver_deconv,title="Deconvolution"
	CheckBox check_pulseAver_deconv,help={"Show Deconvolution: tau * dV/dt + V "}
	CheckBox check_pulseAver_deconv,userdata(tabnum)="4"
	CheckBox check_pulseAver_deconv,userdata(tabcontrol)="Settings"
	CheckBox check_pulseAver_deconv,userdata(ResizeControlsInfo)=A"!!,EH!!#Bd!!#?u!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_pulseAver_deconv,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_pulseAver_deconv,userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_pulseAver_deconv,value=0
	CheckBox check_pulseAver_timeAlign,pos={212.00,127.00},size={99.00,15.00},disable=1,proc=PA_CheckProc_Common
	CheckBox check_pulseAver_timeAlign,title="Time alignment"
	CheckBox check_pulseAver_timeAlign,help={"Align all traces of a set to the first pulse of the same sweep from the diagonal element"}
	CheckBox check_pulseAver_timeAlign,userdata(tabnum)="4"
	CheckBox check_pulseAver_timeAlign,userdata(tabcontrol)="Settings"
	CheckBox check_pulseAver_timeAlign,userdata(ResizeControlsInfo)=A"!!,Gd!!#@b!!#@*!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_pulseAver_timeAlign,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_pulseAver_timeAlign,userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_pulseAver_timeAlign,value=0
	SetVariable setvar_pulseAver_deconv_tau,pos={79.00,359.00},size={98.00,18.00},bodyWidth=50,disable=1,proc=PA_SetVarProc_Common
	SetVariable setvar_pulseAver_deconv_tau,title="Tau [ms]"
	SetVariable setvar_pulseAver_deconv_tau,help={"Deconvolution time tau: tau * dV/dt + V"}
	SetVariable setvar_pulseAver_deconv_tau,userdata(tabnum)="4"
	SetVariable setvar_pulseAver_deconv_tau,userdata(tabcontrol)="Settings"
	SetVariable setvar_pulseAver_deconv_tau,userdata(ResizeControlsInfo)=A"!!,EX!!#BmJ,hpS!!#<Hz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	SetVariable setvar_pulseAver_deconv_tau,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_pulseAver_deconv_tau,userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_pulseAver_deconv_tau,limits={0,inf,0},value=_NUM:15
	SetVariable setvar_pulseAver_deconv_smth,pos={65.00,383.00},size={112.00,18.00},bodyWidth=50,disable=1,proc=PA_SetVarProc_Common
	SetVariable setvar_pulseAver_deconv_smth,title="Smoothing"
	SetVariable setvar_pulseAver_deconv_smth,help={"Smoothing factor to use before the deconvolution is calculated. Set to 1 to do the calculation without smoothing."}
	SetVariable setvar_pulseAver_deconv_smth,userdata(tabnum)="4"
	SetVariable setvar_pulseAver_deconv_smth,userdata(tabcontrol)="Settings"
	SetVariable setvar_pulseAver_deconv_smth,userdata(ResizeControlsInfo)=A"!!,E<!!#C$J,hpo!!#<Hz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	SetVariable setvar_pulseAver_deconv_smth,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_pulseAver_deconv_smth,userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_pulseAver_deconv_smth,limits={1,inf,0},value=_NUM:1000
	SetVariable setvar_pulseAver_deconv_range,pos={59.00,404.00},size={118.00,18.00},bodyWidth=50,disable=1,proc=PA_SetVarProc_Common
	SetVariable setvar_pulseAver_deconv_range,title="Display [ms]"
	SetVariable setvar_pulseAver_deconv_range,help={"Time in ms from the beginning of the pulse that is used for the calculation"}
	SetVariable setvar_pulseAver_deconv_range,userdata(tabnum)="4"
	SetVariable setvar_pulseAver_deconv_range,userdata(tabcontrol)="Settings"
	SetVariable setvar_pulseAver_deconv_range,userdata(ResizeControlsInfo)=A"!!,E&!!#C/!!#@P!!#<Hz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	SetVariable setvar_pulseAver_deconv_range,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_pulseAver_deconv_range,userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_pulseAver_deconv_range,limits={0,inf,0},value=_NUM:inf
	GroupBox group_pulseAver_deconv,pos={39.00,323.00},size={155.00,117.00},disable=3
	GroupBox group_pulseAver_deconv,userdata(tabnum)="4"
	GroupBox group_pulseAver_deconv,userdata(tabcontrol)="Settings"
	GroupBox group_pulseAver_deconv,userdata(ResizeControlsInfo)=A"!!,D+!!#B[J,hqU!!#@Nz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	GroupBox group_pulseAver_deconv,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	GroupBox group_pulseAver_deconv,userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_BrowserSettings_OVS,pos={164.00,47.00},size={51.00,15.00},disable=1,proc=BSP_CheckProc_OverlaySweeps
	CheckBox check_BrowserSettings_OVS,title="enable"
	CheckBox check_BrowserSettings_OVS,help={"Toggle plotting plot multiple sweeps overlayed in the same graph"}
	CheckBox check_BrowserSettings_OVS,userdata(tabnum)="1"
	CheckBox check_BrowserSettings_OVS,userdata(tabcontrol)="Settings"
	CheckBox check_BrowserSettings_OVS,userdata(ResizeControlsInfo)=A"!!,G4!!#>J!!#>Z!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_BrowserSettings_OVS,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_BrowserSettings_OVS,userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_BrowserSettings_OVS,value=0
	CheckBox check_BrowserSettings_AR,pos={164.00,47.00},size={51.00,15.00},disable=1,proc=BSP_CheckBoxProc_ArtRemoval
	CheckBox check_BrowserSettings_AR,title="enable"
	CheckBox check_BrowserSettings_AR,help={"Open the artefact removal dialog"}
	CheckBox check_BrowserSettings_AR,userdata(tabnum)="3"
	CheckBox check_BrowserSettings_AR,userdata(tabcontrol)="Settings"
	CheckBox check_BrowserSettings_AR,userdata(ResizeControlsInfo)=A"!!,G4!!#>J!!#>Z!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_BrowserSettings_AR,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_BrowserSettings_AR,userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_BrowserSettings_AR,value=0
	CheckBox check_BrowserSettings_PA,pos={164.00,47.00},size={51.00,15.00},disable=1,proc=BSP_CheckBoxProc_PerPulseAver
	CheckBox check_BrowserSettings_PA,title="enable"
	CheckBox check_BrowserSettings_PA,help={"Allows to average multiple pulses from pulse train epochs"}
	CheckBox check_BrowserSettings_PA,userdata(tabnum)="4"
	CheckBox check_BrowserSettings_PA,userdata(tabcontrol)="Settings"
	CheckBox check_BrowserSettings_PA,userdata(ResizeControlsInfo)=A"!!,G4!!#>J!!#>Z!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_BrowserSettings_PA,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_BrowserSettings_PA,userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_BrowserSettings_PA,value=0
	CheckBox check_BrowserSettings_DAC,pos={28.00,36.00},size={32.00,15.00},proc=BSP_CheckProc_ChangedSetting
	CheckBox check_BrowserSettings_DAC,title="DA"
	CheckBox check_BrowserSettings_DAC,help={"Display the DA channel data"}
	CheckBox check_BrowserSettings_DAC,userdata(tabnum)="0"
	CheckBox check_BrowserSettings_DAC,userdata(tabcontrol)="Settings"
	CheckBox check_BrowserSettings_DAC,userdata(ResizeControlsInfo)=A"!!,CD!!#=s!!#=c!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_BrowserSettings_DAC,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_BrowserSettings_DAC,userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_BrowserSettings_DAC,value=0
	CheckBox check_BrowserSettings_ADC,pos={91.00,36.00},size={32.00,15.00},proc=BSP_CheckProc_ChangedSetting
	CheckBox check_BrowserSettings_ADC,title="AD",help={"Display the AD channels"}
	CheckBox check_BrowserSettings_ADC,userdata(tabnum)="0"
	CheckBox check_BrowserSettings_ADC,userdata(tabcontrol)="Settings"
	CheckBox check_BrowserSettings_ADC,userdata(ResizeControlsInfo)=A"!!,Ep!!#=s!!#=c!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_BrowserSettings_ADC,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_BrowserSettings_ADC,userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_BrowserSettings_ADC,value=1
	CheckBox check_BrowserSettings_TTL,pos={148.00,36.00},size={34.00,15.00},proc=BSP_CheckProc_ChangedSetting
	CheckBox check_BrowserSettings_TTL,title="TTL",help={"Display the TTL channels"}
	CheckBox check_BrowserSettings_TTL,userdata(tabnum)="0"
	CheckBox check_BrowserSettings_TTL,userdata(tabcontrol)="Settings"
	CheckBox check_BrowserSettings_TTL,userdata(ResizeControlsInfo)=A"!!,G$!!#=s!!#=k!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_BrowserSettings_TTL,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_BrowserSettings_TTL,userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_BrowserSettings_TTL,value=0
	CheckBox check_BrowserSettings_OChan,pos={28.00,60.00},size={65.00,15.00},proc=BSP_CheckProc_ChangedSetting
	CheckBox check_BrowserSettings_OChan,title="Channels"
	CheckBox check_BrowserSettings_OChan,help={"Overlay the data from multiple channels in one graph"}
	CheckBox check_BrowserSettings_OChan,userdata(tabnum)="0"
	CheckBox check_BrowserSettings_OChan,userdata(tabcontrol)="Settings"
	CheckBox check_BrowserSettings_OChan,userdata(ResizeControlsInfo)=A"!!,CD!!#?)!!#?;!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_BrowserSettings_OChan,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_BrowserSettings_OChan,userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_BrowserSettings_OChan,value=0
	CheckBox check_BrowserSettings_dDAQ,pos={148.00,60.00},size={48.00,15.00},proc=BSP_CheckProc_ChangedSetting
	CheckBox check_BrowserSettings_dDAQ,title="dDAQ"
	CheckBox check_BrowserSettings_dDAQ,help={"Enable dedicated support for viewing distributed DAQ data"}
	CheckBox check_BrowserSettings_dDAQ,userdata(tabnum)="0"
	CheckBox check_BrowserSettings_dDAQ,userdata(tabcontrol)="Settings"
	CheckBox check_BrowserSettings_dDAQ,userdata(ResizeControlsInfo)=A"!!,G$!!#?)!!#>N!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_BrowserSettings_dDAQ,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_BrowserSettings_dDAQ,userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_BrowserSettings_dDAQ,value=0
	CheckBox check_Calculation_ZeroTraces,pos={40.00,219.00},size={75.00,15.00},proc=BSP_CheckProc_ChangedSetting
	CheckBox check_Calculation_ZeroTraces,title="Zero Traces"
	CheckBox check_Calculation_ZeroTraces,help={"Remove the offset of all traces"}
	CheckBox check_Calculation_ZeroTraces,userdata(tabnum)="0"
	CheckBox check_Calculation_ZeroTraces,userdata(tabcontrol)="Settings"
	CheckBox check_Calculation_ZeroTraces,userdata(ResizeControlsInfo)=A"!!,D/!!#Aj!!#?O!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_Calculation_ZeroTraces,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_Calculation_ZeroTraces,userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_Calculation_ZeroTraces,value=0
	CheckBox check_Calculation_AverageTraces,pos={40.00,198.00},size={94.00,15.00},proc=BSP_CheckProc_ChangedSetting
	CheckBox check_Calculation_AverageTraces,title="Average Traces"
	CheckBox check_Calculation_AverageTraces,help={"Average all traces which belong to the same y axis"}
	CheckBox check_Calculation_AverageTraces,userdata(tabnum)="0"
	CheckBox check_Calculation_AverageTraces,userdata(tabcontrol)="Settings"
	CheckBox check_Calculation_AverageTraces,userdata(ResizeControlsInfo)=A"!!,D/!!#AU!!#?u!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_Calculation_AverageTraces,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_Calculation_AverageTraces,userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_Calculation_AverageTraces,value=0
	CheckBox check_BrowserSettings_TA,pos={154.00,111.00},size={51.00,15.00},proc=BSP_TimeAlignmentProc
	CheckBox check_BrowserSettings_TA,title="enable"
	CheckBox check_BrowserSettings_TA,help={"Activate time alignment"}
	CheckBox check_BrowserSettings_TA,userdata(tabnum)="0"
	CheckBox check_BrowserSettings_TA,userdata(tabcontrol)="Settings"
	CheckBox check_BrowserSettings_TA,userdata(ResizeControlsInfo)=A"!!,G*!!#@B!!#>Z!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_BrowserSettings_TA,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_BrowserSettings_TA,userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_BrowserSettings_TA,value=0
	CheckBox check_ovs_clear_on_new_ra_cycle,pos={235.00,161.00},size={111.00,15.00},disable=3
	CheckBox check_ovs_clear_on_new_ra_cycle,title="Clear on new RAC"
	CheckBox check_ovs_clear_on_new_ra_cycle,help={"Clear the list of overlayed sweeps when a new repeated acquisition cycle has begun."}
	CheckBox check_ovs_clear_on_new_ra_cycle,userdata(tabnum)="1"
	CheckBox check_ovs_clear_on_new_ra_cycle,userdata(tabcontrol)="Settings"
	CheckBox check_ovs_clear_on_new_ra_cycle,userdata(ResizeControlsInfo)=A"!!,H&!!#A0!!#@B!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_ovs_clear_on_new_ra_cycle,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_ovs_clear_on_new_ra_cycle,userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_ovs_clear_on_new_ra_cycle,value=0
	CheckBox check_ovs_clear_on_new_stimset_cycle,pos={235.00,181.00},size={105.00,15.00},disable=3
	CheckBox check_ovs_clear_on_new_stimset_cycle,title="Clear on new SCI"
	CheckBox check_ovs_clear_on_new_stimset_cycle,help={"Clear the list of overlayed sweeps when a new simset cycle has begun."}
	CheckBox check_ovs_clear_on_new_stimset_cycle,userdata(tabnum)="1"
	CheckBox check_ovs_clear_on_new_stimset_cycle,userdata(tabcontrol)="Settings"
	CheckBox check_ovs_clear_on_new_stimset_cycle,userdata(ResizeControlsInfo)=A"!!,H&!!#AD!!#@6!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_ovs_clear_on_new_stimset_cycle,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_ovs_clear_on_new_stimset_cycle,userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_ovs_clear_on_new_stimset_cycle,value=0
	PopupMenu popup_TimeAlignment_Mode,pos={31.00,135.00},size={143.00,19.00},bodyWidth=50,disable=2,proc=BSP_TimeAlignmentPopup
	PopupMenu popup_TimeAlignment_Mode,title="Alignment Mode"
	PopupMenu popup_TimeAlignment_Mode,help={"Select the alignment mode"}
	PopupMenu popup_TimeAlignment_Mode,userdata(tabnum)="0"
	PopupMenu popup_TimeAlignment_Mode,userdata(tabcontrol)="Settings"
	PopupMenu popup_TimeAlignment_Mode,userdata(ResizeControlsInfo)=A"!!,C\\!!#@k!!#@s!!#<Pz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	PopupMenu popup_TimeAlignment_Mode,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu popup_TimeAlignment_Mode,userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu popup_TimeAlignment_Mode,mode=1,popvalue="Level (Raising)",value=#"\"Level (Raising);Level (Falling);Min;Max\""
	SetVariable setvar_TimeAlignment_LevelCross,pos={187.00,135.00},size={48.00,18.00},disable=2,proc=BSP_TimeAlignmentLevel
	SetVariable setvar_TimeAlignment_LevelCross,title="Level"
	SetVariable setvar_TimeAlignment_LevelCross,help={"Select the level (for rising and falling alignment mode) at which traces are aligned"}
	SetVariable setvar_TimeAlignment_LevelCross,userdata(tabnum)="0"
	SetVariable setvar_TimeAlignment_LevelCross,userdata(tabcontrol)="Settings"
	SetVariable setvar_TimeAlignment_LevelCross,userdata(ResizeControlsInfo)=A"!!,GK!!#@k!!#>N!!#<Hz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	SetVariable setvar_TimeAlignment_LevelCross,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_TimeAlignment_LevelCross,userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_TimeAlignment_LevelCross,limits={-inf,inf,0},value=_NUM:0
	Button button_TimeAlignment_Action,pos={208.00,159.00},size={30.00,18.00},disable=2,proc=BSP_DoTimeAlignment
	Button button_TimeAlignment_Action,title="Do!"
	Button button_TimeAlignment_Action,help={"Perform the time alignment, needs the cursors A and B to have a selected feature"}
	Button button_TimeAlignment_Action,userdata(tabnum)="0"
	Button button_TimeAlignment_Action,userdata(tabcontrol)="Settings"
	Button button_TimeAlignment_Action,userdata(ResizeControlsInfo)=A"!!,G`!!#A.!!#=S!!#<Hz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	Button button_TimeAlignment_Action,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button button_TimeAlignment_Action,userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	GroupBox group_SB_axes_scaling,pos={28.00,245.00},size={285.00,51.00}
	GroupBox group_SB_axes_scaling,title="Axes Scaling",userdata(tabnum)="0"
	GroupBox group_SB_axes_scaling,userdata(tabcontrol)="Settings"
	GroupBox group_SB_axes_scaling,userdata(ResizeControlsInfo)=A"!!,CD!!#B/!!#BHJ,ho0z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	GroupBox group_SB_axes_scaling,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	GroupBox group_SB_axes_scaling,userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_Display_VisibleXrange,pos={40.00,270.00},size={41.00,15.00},proc=BSP_CheckProc_ChangedSetting
	CheckBox check_Display_VisibleXrange,title="Vis X"
	CheckBox check_Display_VisibleXrange,help={"Scale the y axis to the visible x data range"}
	CheckBox check_Display_VisibleXrange,userdata(tabnum)="0"
	CheckBox check_Display_VisibleXrange,userdata(tabcontrol)="Settings"
	CheckBox check_Display_VisibleXrange,userdata(ResizeControlsInfo)=A"!!,D/!!#BA!!#>2!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_Display_VisibleXrange,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_Display_VisibleXrange,userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_Display_VisibleXrange,value=0
	CheckBox check_Display_EqualYrange,pos={94.00,270.00},size={55.00,15.00},proc=BSP_CheckProc_ScaleAxes
	CheckBox check_Display_EqualYrange,title="Equal Y"
	CheckBox check_Display_EqualYrange,help={"Equalize the vertical axes ranges"}
	CheckBox check_Display_EqualYrange,userdata(tabnum)="0"
	CheckBox check_Display_EqualYrange,userdata(tabcontrol)="Settings"
	CheckBox check_Display_EqualYrange,userdata(ResizeControlsInfo)=A"!!,F!!!#BA!!#>j!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_Display_EqualYrange,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_Display_EqualYrange,userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_Display_EqualYrange,value=0
	CheckBox check_Display_EqualYignore,pos={154.00,270.00},size={84.00,15.00},proc=BSP_CheckProc_ScaleAxes
	CheckBox check_Display_EqualYignore,title="Ignore traces"
	CheckBox check_Display_EqualYignore,help={"Equalize the vertical axes ranges but ignore all traces with level crossings"}
	CheckBox check_Display_EqualYignore,userdata(tabnum)="0"
	CheckBox check_Display_EqualYignore,userdata(tabcontrol)="Settings"
	CheckBox check_Display_EqualYignore,userdata(ResizeControlsInfo)=A"!!,G*!!#BA!!#?a!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_Display_EqualYignore,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_Display_EqualYignore,userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_Display_EqualYignore,value=0
	SetVariable setvar_Display_EqualYlevel,pos={243.00,269.00},size={24.00,18.00},disable=2,proc=BSP_AxisScalingLevelCross
	SetVariable setvar_Display_EqualYlevel,help={"Crossing level value for 'Equal Y ign.\""}
	SetVariable setvar_Display_EqualYlevel,userdata(tabnum)="0"
	SetVariable setvar_Display_EqualYlevel,userdata(tabcontrol)="Settings"
	SetVariable setvar_Display_EqualYlevel,userdata(ResizeControlsInfo)=A"!!,H.!!#B@J,hmN!!#<Hz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	SetVariable setvar_Display_EqualYlevel,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_Display_EqualYlevel,userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_Display_EqualYlevel,limits={-inf,inf,0},value=_NUM:0
	PopupMenu popup_TimeAlignment_Master,pos={44.00,159.00},size={134.00,19.00},bodyWidth=50,disable=2,proc=BSP_TimeAlignmentPopup
	PopupMenu popup_TimeAlignment_Master,title="Reference trace"
	PopupMenu popup_TimeAlignment_Master,help={"Select the reference trace to which all other traces should be aligned to"}
	PopupMenu popup_TimeAlignment_Master,userdata(tabnum)="0"
	PopupMenu popup_TimeAlignment_Master,userdata(tabcontrol)="Settings"
	PopupMenu popup_TimeAlignment_Master,userdata(ResizeControlsInfo)=A"!!,D?!!#A.!!#@j!!#<Pz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	PopupMenu popup_TimeAlignment_Master,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu popup_TimeAlignment_Master,userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu popup_TimeAlignment_Master,mode=1,popvalue="AD0",value=#"\"\""
	Button button_Calculation_RestoreData,pos={151.00,210.00},size={75.00,24.00},proc=BSP_ButtonProc_RestoreData
	Button button_Calculation_RestoreData,title="Restore"
	Button button_Calculation_RestoreData,help={"Restore the data in its pristine state without any modifications"}
	Button button_Calculation_RestoreData,userdata(tabnum)="0"
	Button button_Calculation_RestoreData,userdata(tabcontrol)="Settings"
	Button button_Calculation_RestoreData,userdata(ResizeControlsInfo)=A"!!,G'!!#Aa!!#?O!!#=#z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	Button button_Calculation_RestoreData,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button button_Calculation_RestoreData,userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	Button button_BrowserSettings_Export,pos={90.00,377.00},size={99.00,24.00},proc=SB_ButtonProc_ExportTraces
	Button button_BrowserSettings_Export,title="Export Traces"
	Button button_BrowserSettings_Export,help={"Export the traces for further processing"}
	Button button_BrowserSettings_Export,userdata(tabnum)="0"
	Button button_BrowserSettings_Export,userdata(tabcontrol)="Settings"
	Button button_BrowserSettings_Export,userdata(ResizeControlsInfo)=A"!!,En!!#C!J,hpU!!#=#z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	Button button_BrowserSettings_Export,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	Button button_BrowserSettings_Export,userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	GroupBox group_timealignment,pos={28.00,87.00},size={285.00,99.00}
	GroupBox group_timealignment,title="Time Alignment",userdata(tabnum)="0"
	GroupBox group_timealignment,userdata(tabcontrol)="Settings"
	GroupBox group_timealignment,userdata(ResizeControlsInfo)=A"!!,CD!!#?g!!#BHJ,hpUz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	GroupBox group_timealignment,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	GroupBox group_timealignment,userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	Slider slider_BrowserSettings_dDAQ,pos={316.00,36.00},size={56.00,300.00},disable=2,proc=BSP_SliderProc_ChangedSetting
	Slider slider_BrowserSettings_dDAQ,help={"Allows to view only regions from the selected headstage (oodDAQ) resp. the selected headstage (dDAQ). Choose -1 to display all."}
	Slider slider_BrowserSettings_dDAQ,userdata(tabnum)="0"
	Slider slider_BrowserSettings_dDAQ,userdata(tabcontrol)="Settings"
	Slider slider_BrowserSettings_dDAQ,userdata(ResizeControlsInfo)=A"!!,HY!!#=s!!#>n!!#BPz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	Slider slider_BrowserSettings_dDAQ,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Slider slider_BrowserSettings_dDAQ,userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	Slider slider_BrowserSettings_dDAQ,limits={-1,7,1},value=-1
	CheckBox check_SweepControl_HideSweep,pos={253.00,60.00},size={41.00,15.00},proc=BSP_CheckProc_ChangedSetting
	CheckBox check_SweepControl_HideSweep,title="Hide"
	CheckBox check_SweepControl_HideSweep,help={"Hide sweep traces. Usually combined with \"Average traces\"."}
	CheckBox check_SweepControl_HideSweep,userdata(tabnum)="0"
	CheckBox check_SweepControl_HideSweep,userdata(tabcontrol)="Settings"
	CheckBox check_SweepControl_HideSweep,userdata(ResizeControlsInfo)=A"!!,H8!!#?)!!#>2!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_SweepControl_HideSweep,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_SweepControl_HideSweep,userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_SweepControl_HideSweep,value=0
	CheckBox check_BrowserSettings_splitTTL,pos={253.00,36.00},size={58.00,15.00},proc=BSP_CheckProc_ChangedSetting
	CheckBox check_BrowserSettings_splitTTL,title="sep. TTL"
	CheckBox check_BrowserSettings_splitTTL,help={"Display the TTL channel data as single traces for each TTL bit"}
	CheckBox check_BrowserSettings_splitTTL,userdata(tabnum)="0"
	CheckBox check_BrowserSettings_splitTTL,userdata(tabcontrol)="Settings"
	CheckBox check_BrowserSettings_splitTTL,userdata(ResizeControlsInfo)=A"!!,H8!!#=s!!#?!!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_BrowserSettings_splitTTL,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_BrowserSettings_splitTTL,userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_BrowserSettings_splitTTL,value=0
	PopupMenu popup_DB_lockedDevices,pos={32.00,351.00},size={205.00,19.00},bodyWidth=100,proc=DB_PopMenuProc_LockDBtoDevice
	PopupMenu popup_DB_lockedDevices,title="Device assignment:"
	PopupMenu popup_DB_lockedDevices,help={"Select a data acquistion device to display data"}
	PopupMenu popup_DB_lockedDevices,userdata(tabnum)="0"
	PopupMenu popup_DB_lockedDevices,userdata(tabcontrol)="Settings"
	PopupMenu popup_DB_lockedDevices,userdata(Config_RestorePriority)="0"
	PopupMenu popup_DB_lockedDevices,userdata(ResizeControlsInfo)=A"!!,Cd!!#BiJ,hr2!!#<Pz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	PopupMenu popup_DB_lockedDevices,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu popup_DB_lockedDevices,userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu popup_DB_lockedDevices,mode=1,popvalue="- none -",value=#"DB_GetAllDevicesWithData()"
	GroupBox group_enable_sweepFormula,pos={5.00,25.00},size={388.00,50.00},disable=1
	GroupBox group_enable_sweepFormula,title="SweepFormula",userdata(tabnum)="5"
	GroupBox group_enable_sweepFormula,userdata(tabcontrol)="Settings"
	GroupBox group_enable_sweepFormula,userdata(ResizeControlsInfo)=A"!!,?X!!#=+!!#C'!!#>Vz!!#](Aon#azzzzzzzzzzzzzz!!#o2B4uAeBk2=!z"
	GroupBox group_enable_sweepFormula,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#N3Bk1ctAStpcCh5qOGZ8U#zzzzzzzz"
	GroupBox group_enable_sweepFormula,userdata(ResizeControlsInfo)+=A"zzz!!#N3Bk1ctAStpcCh5qOGX?=jFDl!rzzzzzzzzzz!!!"
	SetVariable setvar_sweepFormula_parseResult,pos={135.00,555.00},size={255.00,18.00},disable=1
	SetVariable setvar_sweepFormula_parseResult,help={"Error message of SweepFormula execution."}
	SetVariable setvar_sweepFormula_parseResult,userdata(tabnum)="5"
	SetVariable setvar_sweepFormula_parseResult,userdata(tabcontrol)="Settings"
	SetVariable setvar_sweepFormula_parseResult,userdata(ResizeControlsInfo)=A"!!,Fl!!#Co^]6`O!!#<Hz!!#](Aon#azzzzzzzzzzzzzz!!#](Aon#SBk2=!z"
	SetVariable setvar_sweepFormula_parseResult,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#?(FEDG<zzzzzzzzzzz"
	SetVariable setvar_sweepFormula_parseResult,userdata(ResizeControlsInfo)+=A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_sweepFormula_parseResult,frame=0
	SetVariable setvar_sweepFormula_parseResult,limits={-inf,inf,0},value=_STR:"",noedit=1,live=1
	ValDisplay status_sweepFormula_parser,pos={121.00,560.00},size={10.00,8.00},bodyWidth=10,disable=1
	ValDisplay status_sweepFormula_parser,help={"Current parsing status of the entered formula."}
	ValDisplay status_sweepFormula_parser,userdata(tabnum)="5"
	ValDisplay status_sweepFormula_parser,userdata(tabcontrol)="Settings"
	ValDisplay status_sweepFormula_parser,userdata(ResizeControlsInfo)=A"!!,FW!!#Cq!!#;-!!#:bz!!#o2B4uAezzzzzzzzzzzzzz!!#o2B4uAeBk2=!z"
	ValDisplay status_sweepFormula_parser,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#?(FEDG<zzzzzzzzzzz"
	ValDisplay status_sweepFormula_parser,userdata(ResizeControlsInfo)+=A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	ValDisplay status_sweepFormula_parser,limits={-1,1,0},barmisc={0,0},mode=1,highColor=(0,65535,0),lowColor=(0,0,0),zeroColor=(65535,0,0)
	ValDisplay status_sweepFormula_parser,value=#"1"
	Button button_sweepFormula_display,pos={9.00,553.00},size={51.00,22.00},disable=1,proc=SF_button_sweepFormula_display
	Button button_sweepFormula_display,title="Display"
	Button button_sweepFormula_display,help={"Display the given sweep formula in a graph"}
	Button button_sweepFormula_display,userdata(tabnum)="5"
	Button button_sweepFormula_display,userdata(tabcontrol)="Settings"
	Button button_sweepFormula_display,userdata(ResizeControlsInfo)=A"!!,@s!!#Co5QF,E!!#<hz!!#](Aon#azzzzzzzzzzzzzz!!#](Aon#SBk2=!z"
	Button button_sweepFormula_display,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#?(FEDG<zzzzzzzzzzz"
	Button button_sweepFormula_display,userdata(ResizeControlsInfo)+=A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	Button button_sweepFormula_check,pos={65.00,553.00},size={46.00,22.00},disable=1,proc=SF_button_sweepFormula_check
	Button button_sweepFormula_check,title="Check"
	Button button_sweepFormula_check,help={"Check the sweep formula for syntax errors"}
	Button button_sweepFormula_check,userdata(tabnum)="5"
	Button button_sweepFormula_check,userdata(tabcontrol)="Settings"
	Button button_sweepFormula_check,userdata(ResizeControlsInfo)=A"!!,E<!!#Co5QF,1!!#<hz!!#](Aon#azzzzzzzzzzzzzz!!#](Aon#SBk2=!z"
	Button button_sweepFormula_check,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#?(FEDG<zzzzzzzzzzz"
	Button button_sweepFormula_check,userdata(ResizeControlsInfo)+=A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	TabControl SF_InfoTab,pos={7.00,90.00},size={377.00,458.00},disable=3,proc=ACL_DisplayTab
	TabControl SF_InfoTab,help={"Choose between sweep formula input, JSON representation and the help notebook"}
	TabControl SF_InfoTab,userdata(finalhook)="SF_TabProc_Formula"
	TabControl SF_InfoTab,userdata(currenttab)="0",userdata(tabnum)="5"
	TabControl SF_InfoTab,userdata(tabcontrol)="Settings"
	TabControl SF_InfoTab,userdata(ResizeControlsInfo)=A"!!,@C!!#?m!!#C!J,hsuz!!#](Aon#azzzzzzzzzzzzzz!!#o2B4uAeBk2=!z"
	TabControl SF_InfoTab,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	TabControl SF_InfoTab,userdata(ResizeControlsInfo)+=A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	TabControl SF_InfoTab,userdata(Config_DontRestore)="1"
	TabControl SF_InfoTab,userdata(Config_DontSave)="1",tabLabel(0)="Formula"
	TabControl SF_InfoTab,tabLabel(1)="JSON",tabLabel(2)="Help",value=0
	ListBox list_dashboard,pos={5.00,90.00},size={388.00,489.00},disable=1,proc=AD_ListBoxProc
	ListBox list_dashboard,help={"Show the triplett of stimulus set, analysis function and result for supported analysis functions."}
	ListBox list_dashboard,userdata(tabnum)="7",userdata(tabcontrol)="Settings"
	ListBox list_dashboard,userdata(ResizeControlsInfo)=A"!!,?X!!#?m!!#C'!!#CYJ,fQL!!#](Aon\"Qzzzzzzzzzzzzzz!!#o2B4uAezz"
	ListBox list_dashboard,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	ListBox list_dashboard,userdata(ResizeControlsInfo)+=A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	ListBox list_dashboard,userdata(Config_DontRestore)="1"
	ListBox list_dashboard,userdata(Config_DontSave)="1",fSize=12,mode=1,selRow=-1
	ListBox list_dashboard,widths={141,109,77},userColumnResize=1
	CheckBox check_BrowserSettings_DS,pos={164.00,47.00},size={51.00,15.00},disable=1,proc=AD_CheckProc_Toggle
	CheckBox check_BrowserSettings_DS,title="enable"
	CheckBox check_BrowserSettings_DS,help={"Enable the dashboard support"}
	CheckBox check_BrowserSettings_DS,userdata(tabnum)="7"
	CheckBox check_BrowserSettings_DS,userdata(tabcontrol)="Settings"
	CheckBox check_BrowserSettings_DS,userdata(ResizeControlsInfo)=A"!!,G4!!#>J!!#>Z!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_BrowserSettings_DS,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#N3Bk1ctAStpcCh5qOGZ8U#zzzzzzzz"
	CheckBox check_BrowserSettings_DS,userdata(ResizeControlsInfo)+=A"zzz!!#N3Bk1ctAStpcCh5qOGX?=jFDl!rzzzzzzzzzz!!!"
	CheckBox check_BrowserSettings_DS,value=0
	GroupBox group_enable_dashboard,pos={5.00,25.00},size={388.00,60.00},disable=1
	GroupBox group_enable_dashboard,userdata(tabnum)="7"
	GroupBox group_enable_dashboard,userdata(tabcontrol)="Settings"
	GroupBox group_enable_dashboard,userdata(ResizeControlsInfo)=A"!!,?X!!#=+!!#C'!!#?)z!!#](Aon\"Qzzzzzzzzzzzzzz!!#o2B4uAezz"
	GroupBox group_enable_dashboard,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	GroupBox group_enable_dashboard,userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_BrowserSettings_DB_Passed,pos={15.00,35.00},size={52.00,15.00},disable=3,proc=AD_CheckProc_PassedSweeps
	CheckBox check_BrowserSettings_DB_Passed,title="Passed"
	CheckBox check_BrowserSettings_DB_Passed,help={"Show passed sweeps on double click into ListBox "}
	CheckBox check_BrowserSettings_DB_Passed,userdata(tabnum)="7"
	CheckBox check_BrowserSettings_DB_Passed,userdata(tabcontrol)="Settings"
	CheckBox check_BrowserSettings_DB_Passed,userdata(ResizeControlsInfo)=A"!!,B)!!#=o!!#>^!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_BrowserSettings_DB_Passed,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_BrowserSettings_DB_Passed,userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_BrowserSettings_DB_Passed,value=0
	CheckBox check_BrowserSettings_DB_Failed,pos={15.00,56.00},size={47.00,15.00},disable=3,proc=AD_CheckProc_FailedSweeps
	CheckBox check_BrowserSettings_DB_Failed,title="Failed"
	CheckBox check_BrowserSettings_DB_Failed,help={"Show failed sweeps on double click into ListBox "}
	CheckBox check_BrowserSettings_DB_Failed,userdata(tabnum)="7"
	CheckBox check_BrowserSettings_DB_Failed,userdata(tabcontrol)="Settings"
	CheckBox check_BrowserSettings_DB_Failed,userdata(ResizeControlsInfo)=A"!!,B)!!#>n!!#>J!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_BrowserSettings_DB_Failed,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_BrowserSettings_DB_Failed,userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_BrowserSettings_DB_Failed,value=0
	CheckBox check_BrowserSettings_SF,pos={164.00,47.00},size={51.00,15.00},disable=1,proc=BSP_CheckBoxProc_SweepFormula
	CheckBox check_BrowserSettings_SF,title="enable"
	CheckBox check_BrowserSettings_SF,help={"Enable the sweep formula support"}
	CheckBox check_BrowserSettings_SF,userdata(tabnum)="5"
	CheckBox check_BrowserSettings_SF,userdata(tabcontrol)="Settings"
	CheckBox check_BrowserSettings_SF,userdata(ResizeControlsInfo)=A"!!,G4!!#>J!!#>Z!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_BrowserSettings_SF,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#N3Bk1ctAStpcCh5qOGZ8U#zzzzzzzz"
	CheckBox check_BrowserSettings_SF,userdata(ResizeControlsInfo)+=A"zzz!!#N3Bk1ctAStpcCh5qOGX?=jFDl!rzzzzzzzzzz!!!"
	CheckBox check_BrowserSettings_SF,value=0
	CheckBox check_channelSel_HEADSTAGE_ALL,pos={57.00,225.00},size={30.00,15.00},disable=1,proc=BSP_CheckProc_ChangedSetting
	CheckBox check_channelSel_HEADSTAGE_ALL,title="All"
	CheckBox check_channelSel_HEADSTAGE_ALL,help={"Toggle the display of all headstages"}
	CheckBox check_channelSel_HEADSTAGE_ALL,userdata(tabcontrol)="Settings"
	CheckBox check_channelSel_HEADSTAGE_ALL,userdata(tabnum)="2"
	CheckBox check_channelSel_HEADSTAGE_ALL,userdata(ResizeControlsInfo)=A"!!,Ds!!#Ap!!#=S!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_HEADSTAGE_ALL,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:DuaGlAStpcCh5qOGZ8U#zzzzzzzz"
	CheckBox check_channelSel_HEADSTAGE_ALL,userdata(ResizeControlsInfo)+=A"zzz!!#u:DuaGlAStpcCh5qOGX?=jFDl!rzzzzzzzzzz!!!"
	CheckBox check_channelSel_HEADSTAGE_ALL,value=0
	CheckBox check_channelSel_DA_All,pos={121.00,225.00},size={30.00,15.00},disable=1,proc=BSP_CheckProc_ChangedSetting
	CheckBox check_channelSel_DA_All,title="All"
	CheckBox check_channelSel_DA_All,help={"Toggle the display of all DA channels"}
	CheckBox check_channelSel_DA_All,userdata(tabcontrol)="Settings"
	CheckBox check_channelSel_DA_All,userdata(tabnum)="2"
	CheckBox check_channelSel_DA_All,userdata(ResizeControlsInfo)=A"!!,FW!!#Ap!!#=S!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_DA_All,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:DuaGlAStpcCh5qOGZ8U#zzzzzzzz"
	CheckBox check_channelSel_DA_All,userdata(ResizeControlsInfo)+=A"zzz!!#u:DuaGlAStpcCh5qOGX?=jFDl!rzzzzzzzzzz!!!"
	CheckBox check_channelSel_DA_All,value=0
	CheckBox check_channelSel_AD_All,pos={188.00,225.00},size={30.00,15.00},disable=1,proc=BSP_CheckProc_ChangedSetting
	CheckBox check_channelSel_AD_All,title="All"
	CheckBox check_channelSel_AD_All,help={"Toggle the display of all AD channels"}
	CheckBox check_channelSel_AD_All,userdata(tabcontrol)="Settings"
	CheckBox check_channelSel_AD_All,userdata(tabnum)="2"
	CheckBox check_channelSel_AD_All,userdata(ResizeControlsInfo)=A"!!,GL!!#Ap!!#=S!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_AD_All,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:DuaGlAStpcCh5qOGZ8U#zzzzzzzz"
	CheckBox check_channelSel_AD_All,userdata(ResizeControlsInfo)+=A"zzz!!#u:DuaGlAStpcCh5qOGX?=jFDl!rzzzzzzzzzz!!!"
	CheckBox check_channelSel_AD_All,value=0
	CheckBox check_pulseAver_searchFailedPulses,pos={214.00,340.00},size={119.00,15.00},disable=1,proc=PA_CheckProc_Common
	CheckBox check_pulseAver_searchFailedPulses,title="Search failed pulses"
	CheckBox check_pulseAver_searchFailedPulses,help={"Failed pulses don't have a signal above the given level in the diagonal elements"}
	CheckBox check_pulseAver_searchFailedPulses,userdata(tabnum)="4"
	CheckBox check_pulseAver_searchFailedPulses,userdata(tabcontrol)="Settings"
	CheckBox check_pulseAver_searchFailedPulses,userdata(ResizeControlsInfo)=A"!!,Gf!!#Bd!!#@R!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_pulseAver_searchFailedPulses,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_pulseAver_searchFailedPulses,userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_pulseAver_searchFailedPulses,value=0
	CheckBox check_pulseAver_hideFailedPulses,pos={214.00,361.00},size={109.00,15.00},disable=1,proc=PA_CheckProc_Common
	CheckBox check_pulseAver_hideFailedPulses,title="Hide failed pulses"
	CheckBox check_pulseAver_hideFailedPulses,help={"Hide the failed pulses"}
	CheckBox check_pulseAver_hideFailedPulses,userdata(tabnum)="4"
	CheckBox check_pulseAver_hideFailedPulses,userdata(tabcontrol)="Settings"
	CheckBox check_pulseAver_hideFailedPulses,userdata(ResizeControlsInfo)=A"!!,Gf!!#BnJ,hpi!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_pulseAver_hideFailedPulses,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_pulseAver_hideFailedPulses,userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_pulseAver_hideFailedPulses,value=0
	SetVariable setvar_pulseAver_failedPulses_level,pos={214.00,383.00},size={81.00,18.00},bodyWidth=50,disable=1,proc=PA_SetVarProc_Common
	SetVariable setvar_pulseAver_failedPulses_level,title="Level"
	SetVariable setvar_pulseAver_failedPulses_level,help={"Signal level for failed pulses search, every pulse not reaching that level is considered as failed."}
	SetVariable setvar_pulseAver_failedPulses_level,userdata(tabnum)="4"
	SetVariable setvar_pulseAver_failedPulses_level,userdata(tabcontrol)="Settings"
	SetVariable setvar_pulseAver_failedPulses_level,userdata(ResizeControlsInfo)=A"!!,Gf!!#C$J,hp1!!#<Hz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	SetVariable setvar_pulseAver_failedPulses_level,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_pulseAver_failedPulses_level,userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_pulseAver_failedPulses_level,limits={-inf,inf,0},value=_NUM:0
	SetVariable setvar_pulseAver_vert_scale_bar,pos={45.00,129.00},size={142.00,18.00},bodyWidth=50,disable=1,proc=PA_SetVarProc_Common
	SetVariable setvar_pulseAver_vert_scale_bar,title="Vertical scale bar"
	SetVariable setvar_pulseAver_vert_scale_bar,help={"Length of the vertical scale bar in data units."}
	SetVariable setvar_pulseAver_vert_scale_bar,userdata(tabnum)="4"
	SetVariable setvar_pulseAver_vert_scale_bar,userdata(tabcontrol)="Settings"
	SetVariable setvar_pulseAver_vert_scale_bar,userdata(ResizeControlsInfo)=A"!!,DC!!#@e!!#@r!!#<Hz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	SetVariable setvar_pulseAver_vert_scale_bar,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_pulseAver_vert_scale_bar,userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_pulseAver_vert_scale_bar,value=_NUM:1
	CheckBox check_pulseAver_ShowImage,pos={52.00,225.00},size={111.00,15.00},disable=1,proc=PA_CheckProc_Common
	CheckBox check_pulseAver_ShowImage,title="Enable image plot"
	CheckBox check_pulseAver_ShowImage,help={"Enable the image plot which is *much* faster than the trace plot"}
	CheckBox check_pulseAver_ShowImage,userdata(tabnum)="4"
	CheckBox check_pulseAver_ShowImage,userdata(tabcontrol)="Settings"
	CheckBox check_pulseAver_ShowImage,userdata(ResizeControlsInfo)=A"!!,D_!!#Ap!!#@B!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_pulseAver_ShowImage,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_pulseAver_ShowImage,userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_pulseAver_ShowImage,value=0
	GroupBox group_pulseAver_general,pos={199.00,89.00},size={175.00,350.00},disable=3
	GroupBox group_pulseAver_general,title="General",userdata(tabnum)="4"
	GroupBox group_pulseAver_general,userdata(tabcontrol)="Settings"
	GroupBox group_pulseAver_general,userdata(ResizeControlsInfo)=A"!!,GW!!#?k!!#A>!!#Biz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	GroupBox group_pulseAver_general,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	GroupBox group_pulseAver_general,userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	GroupBox group_pulseAver_trace_settings,pos={39.00,90.00},size={155.00,96.00},disable=3
	GroupBox group_pulseAver_trace_settings,title="Trace settings"
	GroupBox group_pulseAver_trace_settings,userdata(tabnum)="4"
	GroupBox group_pulseAver_trace_settings,userdata(tabcontrol)="Settings"
	GroupBox group_pulseAver_trace_settings,userdata(ResizeControlsInfo)=A"!!,D+!!#?m!!#A*!!#@$z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	GroupBox group_pulseAver_trace_settings,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	GroupBox group_pulseAver_trace_settings,userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	GroupBox group_pulseAver_image_settings,pos={39.00,186.00},size={154.00,131.00},disable=3
	GroupBox group_pulseAver_image_settings,title="Image settings"
	GroupBox group_pulseAver_image_settings,userdata(tabnum)="4"
	GroupBox group_pulseAver_image_settings,userdata(tabcontrol)="Settings"
	GroupBox group_pulseAver_image_settings,userdata(ResizeControlsInfo)=A"!!,D+!!#AI!!#A)!!#@gz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	GroupBox group_pulseAver_image_settings,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	GroupBox group_pulseAver_image_settings,userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_pulseAver_showTraces,pos={48.00,109.00},size={104.00,15.00},disable=1,proc=PA_CheckProc_Common
	CheckBox check_pulseAver_showTraces,title="Enable trace plot"
	CheckBox check_pulseAver_showTraces,help={"Enable the trace plot"}
	CheckBox check_pulseAver_showTraces,userdata(tabnum)="4"
	CheckBox check_pulseAver_showTraces,userdata(tabcontrol)="Settings"
	CheckBox check_pulseAver_showTraces,userdata(ResizeControlsInfo)=A"!!,DO!!#@>!!#@4!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_pulseAver_showTraces,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_pulseAver_showTraces,userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_pulseAver_showTraces,value=1
	PopupMenu popup_pulseAver_colorscales,pos={46.00,244.00},size={140.00,19.00},bodyWidth=140,disable=1,proc=PA_PopMenuProc_ColorScale
	PopupMenu popup_pulseAver_colorscales,help={"Select the color scale used for the image display"}
	PopupMenu popup_pulseAver_colorscales,userdata(ResizeControlsInfo)=A"!!,DG!!#B.!!#@p!!#<Pz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	PopupMenu popup_pulseAver_colorscales,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu popup_pulseAver_colorscales,userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu popup_pulseAver_colorscales,userdata(tabnum)="4"
	PopupMenu popup_pulseAver_colorscales,userdata(tabcontrol)="Settings"
	PopupMenu popup_pulseAver_colorscales,mode=8,value=#"\"*COLORTABLEPOP*\""
	CheckBox check_pulseAver_drawXZeroLine,pos={213.00,202.00},size={100.00,15.00},disable=1,proc=PA_CheckProc_Common
	CheckBox check_pulseAver_drawXZeroLine,title="Draw X zero line"
	CheckBox check_pulseAver_drawXZeroLine,help={"Draw a vertical line at the X=0 crossing (only available with time alignment)"}
	CheckBox check_pulseAver_drawXZeroLine,userdata(tabnum)="4"
	CheckBox check_pulseAver_drawXZeroLine,userdata(tabcontrol)="Settings"
	CheckBox check_pulseAver_drawXZeroLine,userdata(ResizeControlsInfo)=A"!!,Ge!!#AY!!#@,!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_pulseAver_drawXZeroLine,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_pulseAver_drawXZeroLine,userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_pulseAver_drawXZeroLine,value=0
	CheckBox check_pulseAver_fixedPulseLength,pos={217.00,277.00},size={112.00,15.00},disable=1,proc=PA_CheckProc_Common
	CheckBox check_pulseAver_fixedPulseLength,title="Fixed pulse length"
	CheckBox check_pulseAver_fixedPulseLength,help={"Use the fixed pulse length instead of the computed one"}
	CheckBox check_pulseAver_fixedPulseLength,userdata(tabnum)="4"
	CheckBox check_pulseAver_fixedPulseLength,userdata(tabcontrol)="Settings"
	CheckBox check_pulseAver_fixedPulseLength,userdata(ResizeControlsInfo)=A"!!,Gi!!#BDJ,hpo!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_pulseAver_fixedPulseLength,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_pulseAver_fixedPulseLength,userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_pulseAver_fixedPulseLength,value=0
	PopupMenu popup_pulseAver_pulseSortOrder,pos={48.00,266.00},size={137.00,19.00},bodyWidth=82,disable=1,proc=PA_PopMenuProc_Common
	PopupMenu popup_pulseAver_pulseSortOrder,title="Sort order"
	PopupMenu popup_pulseAver_pulseSortOrder,help={"Sorting order for the pulses"}
	PopupMenu popup_pulseAver_pulseSortOrder,userdata(ResizeControlsInfo)=A"!!,DO!!#B?!!#@m!!#<Pz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	PopupMenu popup_pulseAver_pulseSortOrder,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu popup_pulseAver_pulseSortOrder,userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu popup_pulseAver_pulseSortOrder,userdata(tabnum)="4"
	PopupMenu popup_pulseAver_pulseSortOrder,userdata(tabcontrol)="Settings"
	PopupMenu popup_pulseAver_pulseSortOrder,mode=1,popvalue="Sweep",value=#"\"Sweep;PulseIndex\""
	GroupBox group_pulseAver_failedPulses,pos={206.00,324.00},size={157.00,111.00},disable=3
	GroupBox group_pulseAver_failedPulses,title="Failed Pulses",userdata(tabnum)="4"
	GroupBox group_pulseAver_failedPulses,userdata(tabcontrol)="Settings"
	GroupBox group_pulseAver_failedPulses,userdata(ResizeControlsInfo)=A"!!,G^!!#B\\!!#A,!!#@Bz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	GroupBox group_pulseAver_failedPulses,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	GroupBox group_pulseAver_failedPulses,userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	GroupBox group_pulseAver_singlePulse,pos={205.00,216.00},size={158.00,107.00},disable=3
	GroupBox group_pulseAver_singlePulse,title=" Pulses",userdata(tabnum)="4"
	GroupBox group_pulseAver_singlePulse,userdata(tabcontrol)="Settings"
	GroupBox group_pulseAver_singlePulse,userdata(ResizeControlsInfo)=A"!!,G]!!#Ag!!#A-!!#@:z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	GroupBox group_pulseAver_singlePulse,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	GroupBox group_pulseAver_singlePulse,userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_pulseAver_numberOfSpikes,pos={211.00,407.00},size={148.00,18.00},bodyWidth=50,disable=1,proc=PA_SetVarProc_Common
	SetVariable setvar_pulseAver_numberOfSpikes,title="Number of Spikes"
	SetVariable setvar_pulseAver_numberOfSpikes,help={"Number of expected spikes, a pulse can only pass if it has exactly these many spikes. A value of \"NaN\" means the number of spikes is ignored."}
	SetVariable setvar_pulseAver_numberOfSpikes,userdata(tabnum)="4"
	SetVariable setvar_pulseAver_numberOfSpikes,userdata(tabcontrol)="Settings"
	SetVariable setvar_pulseAver_numberOfSpikes,userdata(ResizeControlsInfo)=A"!!,Gc!!#C0J,hqN!!#<Hz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	SetVariable setvar_pulseAver_numberOfSpikes,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_pulseAver_numberOfSpikes,userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_pulseAver_numberOfSpikes,limits={1,inf,1},value=_NUM:NaN
	GroupBox group_epochs,pos={28.00,296.00},size={285.00,51.00},title="Epochs"
	GroupBox group_epochs,userdata(tabnum)="0",userdata(tabcontrol)="Settings"
	GroupBox group_epochs,userdata(ResizeControlsInfo)=A"!!,CD!!#BN!!#BHJ,ho0z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	GroupBox group_epochs,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	GroupBox group_epochs,userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_BrowserSettings_VisEpochs,pos={38.00,317.00},size={61.00,15.00},proc=BSP_CheckProc_ChangedSetting
	CheckBox check_BrowserSettings_VisEpochs,title="Visualize"
	CheckBox check_BrowserSettings_VisEpochs,help={"Visualize epoch information with additional traces (Igor Pro 9 only)"}
	CheckBox check_BrowserSettings_VisEpochs,userdata(tabnum)="0"
	CheckBox check_BrowserSettings_VisEpochs,userdata(tabcontrol)="Settings"
	CheckBox check_BrowserSettings_VisEpochs,userdata(ResizeControlsInfo)=A"!!,D'!!#BXJ,hoX!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_BrowserSettings_VisEpochs,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_BrowserSettings_VisEpochs,userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_BrowserSettings_VisEpochs,value=0
	DefineGuide UGVL={FL,15},UGVR={FR,-20},UGVT={FT,113},UGVB={FB,-50},enableBoxTop={FT,25}
	DefineGuide enableBoxBottom={enableBoxTop,50},MainBoxBottom={FB,3},MainBoxTop={enableBoxBottom,10}
	SetWindow kwTopWin,hook(ResizeControls)=ResizeControls#ResizeControlsHook
	SetWindow kwTopWin,hook(sweepFormula)=BSP_SweepFormulaHook
	SetWindow kwTopWin,userdata(ResizeControlsInfo)=A"!!*'\"z!!#C,J,htM5QCcazzzzzzzzzzzzzzzzzzzz"
	SetWindow kwTopWin,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzzzzzzzzzzzzzzz"
	SetWindow kwTopWin,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzzzzzzzzz!!!"
	SetWindow kwTopWin,userdata(ResizeControlsGuides)= "UGVL;UGVR;UGVT;UGVB;enableBoxTop;enableBoxBottom;MainBoxBottom;MainBoxTop;"
	SetWindow kwTopWin,userdata(ResizeControlsInfoUGVL)= "NAME:UGVL;WIN:DataBrowser#BrowserSettingsPanel;TYPE:User;HORIZONTAL:0;POSITION:15.00;GUIDE1:FL;GUIDE2:;RELPOSITION:15;"
	SetWindow kwTopWin,userdata(ResizeControlsInfoUGVR)= "NAME:UGVR;WIN:DataBrowser#BrowserSettingsPanel;TYPE:User;HORIZONTAL:0;POSITION:379.00;GUIDE1:FR;GUIDE2:;RELPOSITION:-20;"
	SetWindow kwTopWin,userdata(ResizeControlsInfoUGVT)= "NAME:UGVT;WIN:DataBrowser#BrowserSettingsPanel;TYPE:User;HORIZONTAL:1;POSITION:113.00;GUIDE1:FT;GUIDE2:;RELPOSITION:113;"
	SetWindow kwTopWin,userdata(ResizeControlsInfoUGVB)= "NAME:UGVB;WIN:DataBrowser#BrowserSettingsPanel;TYPE:User;HORIZONTAL:1;POSITION:535.00;GUIDE1:FB;GUIDE2:;RELPOSITION:-50;"
	SetWindow kwTopWin,userdata(ResizeControlsInfoenableBoxTop)= "NAME:enableBoxTop;WIN:DataBrowser#BrowserSettingsPanel;TYPE:User;HORIZONTAL:1;POSITION:25.00;GUIDE1:FT;GUIDE2:;RELPOSITION:25;"
	SetWindow kwTopWin,userdata(ResizeControlsInfoenableBoxBottom)= "NAME:enableBoxBottom;WIN:DataBrowser#BrowserSettingsPanel;TYPE:User;HORIZONTAL:1;POSITION:75.00;GUIDE1:enableBoxTop;GUIDE2:;RELPOSITION:50;"
	SetWindow kwTopWin,userdata(ResizeControlsInfoMainBoxBottom)= "NAME:MainBoxBottom;WIN:DataBrowser#BrowserSettingsPanel;TYPE:User;HORIZONTAL:1;POSITION:585.00;GUIDE1:FB;GUIDE2:;RELPOSITION:3;"
	SetWindow kwTopWin,userdata(ResizeControlsInfoMainBoxTop)= "NAME:MainBoxTop;WIN:DataBrowser#BrowserSettingsPanel;TYPE:User;HORIZONTAL:1;POSITION:85.00;GUIDE1:enableBoxBottom;GUIDE2:;RELPOSITION:10;"
	Execute/Q/Z "SetWindow kwTopWin sizeLimit={305.25,330,inf,inf}" // sizeLimit requires Igor 7 or later
	NewNotebook /F=0 /N=sweepFormula_json /W=(12,71,378,358)/FG=(UGVL,UGVT,UGVR,UGVB) /HOST=# /V=0 /OPTS=12
	Notebook kwTopWin, defaultTab=10, autoSave= 0, magnification=100, writeProtect=1
	Notebook kwTopWin font="Lucida Console", fSize=11, fStyle=0, textRGB=(0,0,0)
	SetWindow kwTopWin,hook(ResizeControls)=ResizeControls#ResizeControlsHook
	SetWindow kwTopWin,userdata(tabnum)= "1"
	SetWindow kwTopWin,userdata(tabcontrol)= "SF_InfoTab"
	SetWindow kwTopWin,userdata(ResizeControlsInfo)=A"!!,@C!!#>F!!#C#!!#B[J,fQL!!#](Aon#azzzzzzzzzzzzzz!!#o2B4uAeBk2=!z"
	SetWindow kwTopWin,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetWindow kwTopWin,userdata(ResizeControlsInfo)+=A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	RenameWindow #,sweepFormula_json
	SetActiveSubwindow ##
	NewNotebook /F=0 /N=sweepFormula_formula /W=(12,71,378,358)/FG=(UGVL,UGVT,UGVR,UGVB) /HOST=# /V=0
	Notebook kwTopWin, defaultTab=20, autoSave= 1, magnification=100
	Notebook kwTopWin font="Lucida Console", fSize=11, fStyle=0, textRGB=(0,0,0)
	Notebook kwTopWin, zdata= "GaqDU%ejN7!Z*!1@=S>)+F`2^BZWLb84b@(eDO%R/Lo%!.b8RgERN@q:!Q;Rb=g(\\Ea=4.iptUKJmo0`?;1F7@M*q"
	Notebook kwTopWin, zdataEnd= 1
	SetWindow kwTopWin,hook(ResizeControls)=ResizeControls#ResizeControlsHook
	SetWindow kwTopWin,userdata(tabnum)= "0"
	SetWindow kwTopWin,userdata(tabcontrol)= "SF_InfoTab"
	SetWindow kwTopWin,userdata(ResizeControlsInfo)=A"!!,@C!!#>F!!#C#!!#B[J,fQL!!#](Aon#azzzzzzzzzzzzzz!!#o2B4uAeBk2=!z"
	SetWindow kwTopWin,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetWindow kwTopWin,userdata(ResizeControlsInfo)+=A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	RenameWindow #,sweepFormula_formula
	SetActiveSubwindow ##
	NewNotebook /F=1 /N=sweepFormula_help /W=(12,71,378,358)/FG=(UGVL,UGVT,UGVR,UGVB) /HOST=# /V=0 /OPTS=4
	Notebook kwTopWin, defaultTab=10, autoSave= 0, magnification=100, writeProtect=1, showRuler=0, rulerUnits=2
	Notebook kwTopWin newRuler=Normal, justification=0, margins={0,0,245}, spacing={0,0,0}, tabs={}, rulerDefaults={"Arial",11,0,(0,0,0)}
	SetWindow kwTopWin,hook(ResizeControls)=ResizeControls#ResizeControlsHook
	SetWindow kwTopWin,userdata(tabnum)= "2"
	SetWindow kwTopWin,userdata(tabcontrol)= "SF_InfoTab"
	SetWindow kwTopWin,userdata(ResizeControlsInfo)=A"!!,@C!!#>F!!#C#!!#B[J,fQL!!#](Aon#azzzzzzzzzzzzzz!!#o2B4uAeBk2=!z"
	SetWindow kwTopWin,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetWindow kwTopWin,userdata(ResizeControlsInfo)+=A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	RenameWindow #,sweepFormula_help
	SetActiveSubwindow ##
	NewNotebook /F=0 /N=WaveNoteDisplay /W=(200,24,600,561)/FG=(FL,$"",FR,FB) /HOST=# /V=0 /OPTS=10
	Notebook kwTopWin, defaultTab=36, autoSave= 0, magnification=100
	Notebook kwTopWin font="Lucida Console", fSize=11, fStyle=0, textRGB=(0,0,0)
	SetWindow kwTopWin,hook(ResizeControls)=ResizeControls#ResizeControlsHook
	SetWindow kwTopWin,userdata(tabnum)= "6"
	SetWindow kwTopWin,userdata(tabcontrol)= "Settings"
	SetWindow kwTopWin,userdata(ResizeControlsInfo)=A"!!,@C!!#>F!!#C#!!#B[J,fQL!!#](Aon#azzzzzzzzzzzzzz!!#o2B4uAeBk2=!z"
	SetWindow kwTopWin,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetWindow kwTopWin,userdata(ResizeControlsInfo)+=A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	RenameWindow #,WaveNoteDisplay
	SetActiveSubwindow ##
	RenameWindow #,BrowserSettingsPanel
	SetActiveSubwindow ##
	NewPanel/HOST=#/EXT=2/W=(0,0,580,180)  as " "
	ModifyPanel fixedSize=0
	Button popupext_TPStorageKeys,pos={413.00,67.00},size={150.00,19.00},bodyWidth=150,proc=PEXT_ButtonProc
	Button popupext_TPStorageKeys,title="Testpulse Storage Entries ▼"
	Button popupext_TPStorageKeys,help={"Select TPStorage data to display"}
	Button popupext_TPStorageKeys,userdata(popupProc)="LBV_PopMenuProc_TPStorage"
	Button popupext_TPStorageKeys,userdata(Items)="LBV_PopupExtGetTPStorageKeys"
	Button popupext_TPStorageKeys,userdata(ResizeControlsInfo)=A"!!,I4J,hoj!!#A%!!#<Pz!!#N3Bk1ct<C^(Dzzzzzzzzzzzzz!!#N3Bk1ct<C^(Dz"
	Button popupext_TPStorageKeys,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:DuaGl<C]S6zzzzzzzzzz"
	Button popupext_TPStorageKeys,userdata(ResizeControlsInfo)+=A"zzz!!#u:DuaGl<C]S6zzzzzzzzzzzzz!!!"
	Button button_clearlabnotebookgraph,pos={401.00,122.00},size={80.00,25.00},proc=LBV_ButtonProc_ClearGraph
	Button button_clearlabnotebookgraph,title="Clear graph"
	Button button_clearlabnotebookgraph,help={"Clear the labnotebook visualization graph"}
	Button button_clearlabnotebookgraph,userdata(ResizeControlsInfo)=A"!!,I.J,hq.!!#?Y!!#=+z!!#N3Bk1ct<C^(Dzzzzzzzzzzzzz!!#N3Bk1ct<C^(Dz"
	Button button_clearlabnotebookgraph,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:DuaGl<C]S6zzzzzzzzzz"
	Button button_clearlabnotebookgraph,userdata(ResizeControlsInfo)+=A"zzz!!#u:DuaGl<C]S6zzzzzzzzzzzzz!!!"
	Button button_switchxaxis,pos={493.00,122.00},size={80.00,25.00},proc=LBV_ButtonProc_SwitchXAxis
	Button button_switchxaxis,title="Switch X-axis"
	Button button_switchxaxis,help={"Toggle lab notebook horizontal axis between time of day or sweep number"}
	Button button_switchxaxis,userdata(ResizeControlsInfo)=A"!!,I\\J,hq.!!#?Y!!#=+z!!#N3Bk1ct<C^(Dzzzzzzzzzzzzz!!#N3Bk1ct<C^(Dz"
	Button button_switchxaxis,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:DuaGl<C]S6zzzzzzzzzz"
	Button button_switchxaxis,userdata(ResizeControlsInfo)+=A"zzz!!#u:DuaGl<C]S6zzzzzzzzzzzzz!!!"
	Button button_DataBrowser_setaxis,pos={400.00,151.00},size={171.00,25.00},proc=LBV_ButtonProc_AutoScale
	Button button_DataBrowser_setaxis,title="Autoscale"
	Button button_DataBrowser_setaxis,help={"Autoscale sweep data"}
	Button button_DataBrowser_setaxis,userdata(ResizeControlsInfo)=A"!!,I.!!#A&!!#A:!!#=+z!!#N3Bk1ct<C^(Dzzzzzzzzzzzzz!!#N3Bk1ct<C^(Dz"
	Button button_DataBrowser_setaxis,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	Button button_DataBrowser_setaxis,userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	GroupBox group_labnotebook_experiment_device,pos={402.00,5.00},size={173.00,55.00}
	GroupBox group_labnotebook_experiment_device,userdata(ResizeControlsInfo)=A"!!,I/!!#9W!!#A<!!#>jz!!#N3Bk1ct<C^(Dzzzzzzzzzzzzz!!#N3Bk1ct<C^(Dz"
	GroupBox group_labnotebook_experiment_device,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:DuaGl<C]S6zzzzzzzzzz"
	GroupBox group_labnotebook_experiment_device,userdata(ResizeControlsInfo)+=A"zzz!!#u:DuaGl<C]S6zzzzzzzzzzzzz!!!"
	PopupMenu popup_experiment,pos={405.00,11.00},size={164.00,19.00},bodyWidth=95
	PopupMenu popup_experiment,title="Experiment: "
	PopupMenu popup_experiment,help={"Experiment selection (SweepBrowser only)"}
	PopupMenu popup_experiment,userdata(ResizeControlsInfo)=A"!!,I0J,hkh!!#A3!!#<Pz!!#N3Bk1ct<C^(Dzzzzzzzzzzzzz!!#N3Bk1ct<C^(Dz"
	PopupMenu popup_experiment,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:DuaGl<C]S6zzzzzzzzzz"
	PopupMenu popup_experiment,userdata(ResizeControlsInfo)+=A"zzz!!#u:DuaGl<C]S6zzzzzzzzzzzzz!!!"
	PopupMenu popup_experiment,mode=1,popvalue="- none -",value=#"\"- none -\""
	PopupMenu popup_Device,pos={430.00,34.00},size={139.00,19.00},bodyWidth=95
	PopupMenu popup_Device,title="Device: "
	PopupMenu popup_Device,help={"Device selection (SweepBrowser only)"}
	PopupMenu popup_Device,userdata(ResizeControlsInfo)=A"!!,I=!!#=k!!#@o!!#<Pz!!#N3Bk1ct<C^(Dzzzzzzzzzzzzz!!#N3Bk1ct<C^(Dz"
	PopupMenu popup_Device,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:DuaGl<C]S6zzzzzzzzzz"
	PopupMenu popup_Device,userdata(ResizeControlsInfo)+=A"zzz!!#u:DuaGl<C]S6zzzzzzzzzzzzz!!!"
	PopupMenu popup_Device,mode=1,popvalue="- none -",value=#"\"- none -\""
	Button popupext_LBKeys,pos={413.00,92.00},size={150.00,19.00},bodyWidth=150,proc=PEXT_ButtonProc
	Button popupext_LBKeys,title="Lab Notebook Entries ▼"
	Button popupext_LBKeys,help={"Select lab notebook data to display"}
	Button popupext_LBKeys,userdata(popupProc)="LBV_PopMenuProc_LabNotebook"
	Button popupext_LBKeys,userdata(Items)="LBV_PopupExtGetLBKeys"
	Button popupext_LBKeys,userdata(ResizeControlsInfo)=A"!!,I4J,hpG!!#A%!!#<Pz!!#N3Bk1ct<C^(Dzzzzzzzzzzzzz!!#N3Bk1ct<C^(Dz"
	Button popupext_LBKeys,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:DuaGl<C]S6zzzzzzzzzz"
	Button popupext_LBKeys,userdata(ResizeControlsInfo)+=A"zzz!!#u:DuaGl<C]S6zzzzzzzzzzzzz!!!"
	GroupBox group_labnotebook_experiment_device1,pos={402.00,61.00},size={173.00,59.00}
	GroupBox group_labnotebook_experiment_device1,userdata(ResizeControlsInfo)=A"!!,I/!!#?-!!#A<!!#?%z!!#N3Bk1ct<C^(Dzzzzzzzzzzzzz!!#N3Bk1ct<C^(Dz"
	GroupBox group_labnotebook_experiment_device1,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:DuaGl<C]S6zzzzzzzzzz"
	GroupBox group_labnotebook_experiment_device1,userdata(ResizeControlsInfo)+=A"zzz!!#u:DuaGl<C]S6zzzzzzzzzzzzz!!!"
	DefineGuide UGV0={FR,-187}
	SetWindow kwTopWin,hook(ResizeControls)=ResizeControls#ResizeControlsHook
	SetWindow kwTopWin,userdata(ResizeControlsInfo)=A"!!*'\"z!!#D!!!#ACzzzzzzzzzzzzzzzzzzzzz"
	SetWindow kwTopWin,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzzzzzzzzzzzzzzz"
	SetWindow kwTopWin,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzzzzzzzzz!!!"
	SetWindow kwTopWin,userdata(ResizeControlsGuides)= "UGV0;"
	SetWindow kwTopWin,userdata(ResizeControlsInfoUGV0)= "NAME:UGV0;WIN:DB_ITC18USB_Dev_0#SettingsHistoryPanel;TYPE:User;HORIZONTAL:0;POSITION:393.00;GUIDE1:FR;GUIDE2:;RELPOSITION:-187;"
	Execute/Q/Z "SetWindow kwTopWin sizeLimit={441,105,inf,inf}" // sizeLimit requires Igor 7 or later
	Display/W=(200,187,395,501)/FG=(FL,FT,UGV0,FB)/HOST=#
	ModifyGraph margin(right)=74
	TextBox/C/N=text0/F=0/B=1/X=0.50/Y=2.02/E=2 ""
	SetWindow kwTopWin,userdata(ResizeControlsInfo)=A"!!*'\"z!!#C)J,hrfJ,fQLzzzzzzzzzzzzzzzzzzzz"
	SetWindow kwTopWin,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzzzzzzzzzzzzzzz"
	SetWindow kwTopWin,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzzzzzzzzz!!!"
	RenameWindow #,LabNoteBook
	SetActiveSubwindow ##
	RenameWindow #,SettingsHistoryPanel
	SetActiveSubwindow ##
EndMacro
