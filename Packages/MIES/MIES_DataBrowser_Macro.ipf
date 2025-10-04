#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors = 1

#ifdef AUTOMATED_TESTING
#pragma ModuleName = MIES_DBM
#endif // AUTOMATED_TESTING

/// @file MIES_DataBrowser_Macro.ipf
/// @brief __DBM__ Macro for DataBrowser

Window DataBrowser() : Graph
	PauseUpdate; Silent 1 // building window...
	Display/W=(399.75, 331.25, 888.75, 703.25)/K=1
	Button button_BSP_open, pos={3.00, 3.00}, size={24.00, 24.00}, disable=1, proc=BSP_ButtonProc_Panel
	Button button_BSP_open, title="<<", help={"Restore side panels"}
	Button button_BSP_open, userdata(ResizeControlsInfo)=A"!!,>M!!#8L!!#=#!!#=#z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_BSP_open, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button button_BSP_open, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetWindow kwTopWin, hook(TA_CURSOR_MOVED)=TimeAlignCursorMovedHook
	SetWindow kwTopWin, hook(traceUserDataCleanup)=TUD_RemoveUserDataWave
	SetWindow kwTopWin, hook(sweepScrolling)=BSP_SweepsAndMouseWheel
	SetWindow kwTopWin, hook(ResizeControls)=ResizeControlsSafe
	SetWindow kwTopWin, userdata(BROWSER)="D"
	SetWindow kwTopWin, userdata(DEVICE)="- none -"
	SetWindow kwTopWin, userdata(Config_PanelType)="DataBrowser"
	SetWindow kwTopWin, userdata(ResizeControlsInfo)=A"!!*'\"z!!#CYJ,hsJzzzzzzzzzzzzzzzzzzzzz"
	SetWindow kwTopWin, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzzzzzzzzzzzzzzz"
	SetWindow kwTopWin, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzzzzzzzzz!!!"
	SetWindow kwTopWin, userdata(BROWSERMODE)="User"
	SetWindow kwTopWin, userdata(SweepFormulaContentCRC)="1827768143"
	SetWindow kwTopWin, userdata(JSONSettings_WindowGroup)="databrowser"
	Execute/Q/Z "SetWindow kwTopWin sizeLimit={366,279,inf,inf}" // sizeLimit requires Igor 7 or later
	NewPanel/HOST=#/EXT=2/W=(0, 0, 580, 70) as "Sweep Control"
	Button button_SweepControl_NextSweep, pos={330.00, 3.00}, size={150.00, 36.00}, proc=BSP_ButtonProc_ChangeSweep
	Button button_SweepControl_NextSweep, title="Next  \\W649"
	Button button_SweepControl_NextSweep, help={"Displays the next sweep (sweep no. = last sweep number + step)"}
	Button button_SweepControl_NextSweep, fSize=20
	ValDisplay valdisp_SweepControl_LastSweep, pos={236.00, 3.00}, size={89.00, 34.00}, bodyWidth=60
	ValDisplay valdisp_SweepControl_LastSweep, title="of"
	ValDisplay valdisp_SweepControl_LastSweep, help={"The number of the last sweep acquired for the device assigned to the data browser"}
	ValDisplay valdisp_SweepControl_LastSweep, userdata(Config_DontRestore)="1"
	ValDisplay valdisp_SweepControl_LastSweep, userdata(Config_DontSave)="1", fSize=24
	ValDisplay valdisp_SweepControl_LastSweep, frame=2, fStyle=1
	ValDisplay valdisp_SweepControl_LastSweep, limits={0, 0, 0}, barmisc={0, 1000}
	ValDisplay valdisp_SweepControl_LastSweep, value=#"nan"
	ValDisplay valdisp_SweepControl_LastSweep, barBackColor=(56576, 56576, 56576)
	SetVariable setvar_SweepControl_SweepNo, pos={157.00, 3.00}, size={72.00, 35.00}, proc=DB_SetVarProc_SweepNo
	SetVariable setvar_SweepControl_SweepNo, help={"Sweep number of last sweep plotted"}
	SetVariable setvar_SweepControl_SweepNo, userdata(lastSweep)="NaN"
	SetVariable setvar_SweepControl_SweepNo, userdata(Config_DontRestore)="1"
	SetVariable setvar_SweepControl_SweepNo, userdata(Config_DontSave)="1", fSize=24
	SetVariable setvar_SweepControl_SweepNo, limits={0, 0, 1}, value=_NUM:0, live=1
	SetVariable setvar_SweepControl_SweepStep, pos={486.00, 3.00}, size={90.00, 35.00}, bodyWidth=40
	SetVariable setvar_SweepControl_SweepStep, title="Step"
	SetVariable setvar_SweepControl_SweepStep, help={"Set the increment between sweeps"}
	SetVariable setvar_SweepControl_SweepStep, userdata(lastSweep)="0"
	SetVariable setvar_SweepControl_SweepStep, userdata(Config_DontRestore)="1"
	SetVariable setvar_SweepControl_SweepStep, userdata(Config_DontSave)="1", fSize=24
	SetVariable setvar_SweepControl_SweepStep, limits={1, Inf, 1}, value=_NUM:1
	Button button_SweepControl_PrevSweep, pos={3.00, 3.00}, size={150.00, 36.00}, proc=BSP_ButtonProc_ChangeSweep
	Button button_SweepControl_PrevSweep, title="\\W646 Previous"
	Button button_SweepControl_PrevSweep, help={"Displays the previous sweep (sweep no. = last sweep number - step)"}
	Button button_SweepControl_PrevSweep, fSize=20
	PopupMenu Popup_SweepControl_Selector, pos={152.00, 42.00}, size={175.00, 19.00}, bodyWidth=175, disable=2
	PopupMenu Popup_SweepControl_Selector, help={"List of sweeps in this sweep browser"}
	PopupMenu Popup_SweepControl_Selector, userdata(tabnum)="0"
	PopupMenu Popup_SweepControl_Selector, userdata(tabcontrol)="Settings"
	PopupMenu Popup_SweepControl_Selector, userdata(Config_DontRestore)="1"
	PopupMenu Popup_SweepControl_Selector, userdata(Config_DontSave)="1"
	PopupMenu Popup_SweepControl_Selector, mode=1, popvalue=" ", value=#"\" \""
	CheckBox check_SweepControl_AutoUpdate, pos={342.00, 43.00}, size={160.00, 15.00}
	CheckBox check_SweepControl_AutoUpdate, title="Display last sweep acquired"
	CheckBox check_SweepControl_AutoUpdate, help={"Displays the last sweep acquired when data acquistion is ongoing"}
	CheckBox check_SweepControl_AutoUpdate, value=1
	RenameWindow #, SweepControl
	SetActiveSubwindow ##
	NewPanel/HOST=#/EXT=1/W=(445, 0, 0, 500) as " "
	ModifyPanel fixedSize=0
	GroupBox group_dDAQ, pos={342.00, 27.00}, size={70.00, 323.00}
	GroupBox group_dDAQ, userdata(ResizeControlsInfo)=A"!!,Hf!!#=;!!#?E!!#B[J,fQL!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	GroupBox group_dDAQ, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	GroupBox group_dDAQ, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	GroupBox group_dDAQ, userdata(tabnum)="0", userdata(tabcontrol)="Settings"
	Slider slider_BrowserSettings_dDAQ, pos={348.00, 59.00}, size={53.00, 278.00}, disable=2, proc=BSP_SliderProc_ChangedSetting
	Slider slider_BrowserSettings_dDAQ, help={"Allows to view only regions from the selected headstage (oodDAQ) resp. the selected headstage (dDAQ). Choose -1 to display all."}
	Slider slider_BrowserSettings_dDAQ, userdata(tabnum)="0"
	Slider slider_BrowserSettings_dDAQ, userdata(tabcontrol)="Settings"
	Slider slider_BrowserSettings_dDAQ, userdata(ResizeControlsInfo)=A"!!,Hi!!#?%!!#>b!!#BEz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	Slider slider_BrowserSettings_dDAQ, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Slider slider_BrowserSettings_dDAQ, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	Slider slider_BrowserSettings_dDAQ, limits={-1, 7, 1}, value=-1
	GroupBox group_SB_axes_scaling, pos={50.00, 245.00}, size={285.00, 51.00}
	GroupBox group_SB_axes_scaling, title="Axes Scaling", userdata(tabnum)="0"
	GroupBox group_SB_axes_scaling, userdata(tabcontrol)="Settings"
	GroupBox group_SB_axes_scaling, userdata(ResizeControlsInfo)=A"!!,DW!!#B/!!#BHJ,ho0z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	GroupBox group_SB_axes_scaling, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	GroupBox group_SB_axes_scaling, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	GroupBox group_calc, pos={50.00, 195.00}, size={288.00, 51.00}, userdata(tabnum)="0"
	GroupBox group_calc, userdata(tabcontrol)="Settings"
	GroupBox group_calc, userdata(ResizeControlsInfo)=A"!!,DW!!#AR!!#BJ!!#>Zz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	GroupBox group_calc, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	GroupBox group_calc, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	GroupBox group_timealignment, pos={50.00, 87.00}, size={285.00, 99.00}
	GroupBox group_timealignment, title="Time Alignment", userdata(tabnum)="0"
	GroupBox group_timealignment, userdata(tabcontrol)="Settings"
	GroupBox group_timealignment, userdata(ResizeControlsInfo)=A"!!,DW!!#?g!!#BHJ,hpUz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	GroupBox group_timealignment, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	GroupBox group_timealignment, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	GroupBox group_channels, pos={52.00, 27.00}, size={284.00, 59.00}
	GroupBox group_channels, userdata(tabnum)="0", userdata(tabcontrol)="Settings"
	GroupBox group_channels, userdata(ResizeControlsInfo)=A"!!,D_!!#=;!!#BH!!#?%z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	GroupBox group_channels, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	GroupBox group_channels, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	GroupBox group_properties_sweepFormula, pos={5.00, 85.00}, size={434.00, 414.00}, disable=3
	GroupBox group_properties_sweepFormula, userdata(tabnum)="5"
	GroupBox group_properties_sweepFormula, userdata(tabcontrol)="Settings"
	GroupBox group_properties_sweepFormula, userdata(ResizeControlsInfo)=A"!!,?X!!#?c!!#C>!!#C4z!!#](Aon#azzzzzzzzzzzzzz!!#o2B4uAeBk2=!z"
	GroupBox group_properties_sweepFormula, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#N3Bk1ct9jqaR6>q*JDf>[Vzzzzzzzz"
	GroupBox group_properties_sweepFormula, userdata(ResizeControlsInfo)+=A"zzz!!#N3Bk1ct9jqaR6>q*8Dfg)>D#aP9zzzzzzzzzz!!!"
	TabControl Settings, pos={0.00, 0.00}, size={446.00, 21.00}, proc=ACL_DisplayTab
	TabControl Settings, help={"Main navigation tab"}, userdata(currenttab)="0"
	TabControl Settings, userdata(finalhook)="BSP_MainTabControlFinal"
	TabControl Settings, userdata(ResizeControlsInfo)=A"!!*'\"z!!#CD!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#o2B4uAeBE3-fz"
	TabControl Settings, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	TabControl Settings, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	TabControl Settings, tabLabel(0)="Settings", tabLabel(1)="OVS", tabLabel(2)="CS"
	TabControl Settings, tabLabel(3)="AR", tabLabel(4)="PA", tabLabel(5)="SF"
	TabControl Settings, tabLabel(6)="Note", tabLabel(7)="DS", value=0
	ListBox list_of_ranges, pos={81.00, 198.00}, size={269.00, 295.00}, disable=3, proc=OVS_MainListBoxProc
	ListBox list_of_ranges, help={"Select sweeps for overlay; The second column (\"Headstages\") allows to ignore some headstages for the graphing. Syntax is a semicolon \";\" separated list of subranges, e.g. \"0\", \"0,2\", \"1;4;2\""}
	ListBox list_of_ranges, userdata(tabnum)="1", userdata(tabcontrol)="Settings"
	ListBox list_of_ranges, userdata(ResizeControlsInfo)=A"!!,E\\!!#AU!!#B@J,hs#J,fQL!!#](Aon\"Qzzzzzzzzzzzzzz!!#o2B4uAezz"
	ListBox list_of_ranges, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	ListBox list_of_ranges, userdata(ResizeControlsInfo)+=A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	ListBox list_of_ranges, userdata(Config_DontRestore)="1"
	ListBox list_of_ranges, userdata(Config_DontSave)="1", widths={50, 50}
	PopupMenu popup_overlaySweeps_select, pos={145.00, 99.00}, size={143.00, 19.00}, bodyWidth=109, disable=3, proc=OVS_PopMenuProc_Select
	PopupMenu popup_overlaySweeps_select, title="Select"
	PopupMenu popup_overlaySweeps_select, help={"Select sweeps according to various properties"}
	PopupMenu popup_overlaySweeps_select, userdata(tabnum)="1"
	PopupMenu popup_overlaySweeps_select, userdata(tabcontrol)="Settings"
	PopupMenu popup_overlaySweeps_select, userdata(ResizeControlsInfo)=A"!!,G!!!#@*!!#@s!!#<Pz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	PopupMenu popup_overlaySweeps_select, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu popup_overlaySweeps_select, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu popup_overlaySweeps_select, mode=1, popvalue="", value=#"\"\""
	CheckBox check_overlaySweeps_disableHS, pos={94.00, 159.00}, size={121.00, 15.00}, disable=3, proc=OVS_CheckBoxProc_HS_Select
	CheckBox check_overlaySweeps_disableHS, title="Headstage Removal"
	CheckBox check_overlaySweeps_disableHS, help={"Toggle headstage removal"}
	CheckBox check_overlaySweeps_disableHS, userdata(tabnum)="1"
	CheckBox check_overlaySweeps_disableHS, userdata(tabcontrol)="Settings"
	CheckBox check_overlaySweeps_disableHS, userdata(ResizeControlsInfo)=A"!!,F!!!#A.!!#@V!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_overlaySweeps_disableHS, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_overlaySweeps_disableHS, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_overlaySweeps_disableHS, value=0
	CheckBox check_overlaySweeps_non_commula, pos={94.00, 180.00}, size={154.00, 15.00}, disable=3
	CheckBox check_overlaySweeps_non_commula, title="Non-commulative update"
	CheckBox check_overlaySweeps_non_commula, help={"If \"Display Last sweep acquired\" is checked, this checkbox here allows to only add the newly acquired sweep and will remove the currently added last sweep."}
	CheckBox check_overlaySweeps_non_commula, userdata(tabcontrol)="Settings"
	CheckBox check_overlaySweeps_non_commula, userdata(tabnum)="1"
	CheckBox check_overlaySweeps_non_commula, userdata(ResizeControlsInfo)=A"!!,F!!!#AC!!#A)!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_overlaySweeps_non_commula, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_overlaySweeps_non_commula, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_overlaySweeps_non_commula, value=0
	SetVariable setvar_overlaySweeps_offset, pos={132.00, 126.00}, size={81.00, 18.00}, bodyWidth=45, disable=3, proc=OVS_SetVarProc_SelectionRange
	SetVariable setvar_overlaySweeps_offset, title="Offset"
	SetVariable setvar_overlaySweeps_offset, help={"Offsets the first selected sweep from the selection menu"}
	SetVariable setvar_overlaySweeps_offset, userdata(tabnum)="1"
	SetVariable setvar_overlaySweeps_offset, userdata(tabcontrol)="Settings"
	SetVariable setvar_overlaySweeps_offset, userdata(ResizeControlsInfo)=A"!!,Fi!!#@`!!#?[!!#<Hz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	SetVariable setvar_overlaySweeps_offset, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_overlaySweeps_offset, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_overlaySweeps_offset, limits={0, Inf, 1}, value=_NUM:0
	SetVariable setvar_overlaySweeps_step, pos={219.00, 126.00}, size={72.00, 18.00}, bodyWidth=45, disable=3, proc=OVS_SetVarProc_SelectionRange
	SetVariable setvar_overlaySweeps_step, title="Step"
	SetVariable setvar_overlaySweeps_step, help={"Selects every `step` sweep from the selection menu"}
	SetVariable setvar_overlaySweeps_step, userdata(tabnum)="1"
	SetVariable setvar_overlaySweeps_step, userdata(tabcontrol)="Settings"
	SetVariable setvar_overlaySweeps_step, userdata(ResizeControlsInfo)=A"!!,Gk!!#@`!!#?I!!#<Hz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	SetVariable setvar_overlaySweeps_step, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_overlaySweeps_step, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_overlaySweeps_step, limits={1, Inf, 1}, value=_NUM:1
	GroupBox group_enable_sweeps, pos={5.00, 25.00}, size={434.00, 50.00}, disable=1
	GroupBox group_enable_sweeps, title="Overlay Sweeps", userdata(tabnum)="1"
	GroupBox group_enable_sweeps, userdata(tabcontrol)="Settings"
	GroupBox group_enable_sweeps, userdata(ResizeControlsInfo)=A"!!,?X!!#=+!!#C>!!#>Vz!!#](Aon\"Qzzzzzzzzzzzzzz!!#o2B4uAezz"
	GroupBox group_enable_sweeps, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:DuaGlAStpcCh5qOGZ8U#zzzzzzzz"
	GroupBox group_enable_sweeps, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafn!,c4SCh5qOGX?=jFDl!rzzzzzzzzzz!!!"
	GroupBox group_enable_channels, pos={31.00, 25.00}, size={380.00, 380.00}, disable=1
	GroupBox group_enable_channels, title="Channel Selection", userdata(tabnum)="2"
	GroupBox group_enable_channels, userdata(tabcontrol)="Settings"
	GroupBox group_enable_channels, userdata(ResizeControlsInfo)=A"!!,C\\!!#=+!!#C#!!#C#z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	GroupBox group_enable_channels, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	GroupBox group_enable_channels, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	GroupBox group_enable_artifact, pos={5.00, 25.00}, size={434.00, 50.00}, disable=1
	GroupBox group_enable_artifact, title="Artefact Removal", userdata(tabnum)="3"
	GroupBox group_enable_artifact, userdata(tabcontrol)="Settings"
	GroupBox group_enable_artifact, userdata(ResizeControlsInfo)=A"!!,?X!!#=+!!#C>!!#>Vz!!#](Aon#azzzzzzzzzzzzzz!!#o2B4uAeBk2=!z"
	GroupBox group_enable_artifact, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	GroupBox group_enable_artifact, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	GroupBox group_properties_sweeps, pos={5.00, 85.00}, size={434.00, 414.00}, disable=3
	GroupBox group_properties_sweeps, userdata(tabnum)="1"
	GroupBox group_properties_sweeps, userdata(tabcontrol)="Settings"
	GroupBox group_properties_sweeps, userdata(ResizeControlsInfo)=A"!!,?X!!#?c!!#C>!!#C4z!!#](Aon\"Qzzzzzzzzzzzzzz!!#o2B4uAezz"
	GroupBox group_properties_sweeps, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	GroupBox group_properties_sweeps, userdata(ResizeControlsInfo)+=A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	GroupBox group_properties_artefact, pos={5.00, 85.00}, size={434.00, 414.00}, disable=3
	GroupBox group_properties_artefact, userdata(tabnum)="3"
	GroupBox group_properties_artefact, userdata(tabcontrol)="Settings"
	GroupBox group_properties_artefact, userdata(ResizeControlsInfo)=A"!!,?X!!#?c!!#C>!!#C4z!!#](Aon\"Qzzzzzzzzzzzzzz!!#o2B4uAezz"
	GroupBox group_properties_artefact, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	GroupBox group_properties_artefact, userdata(ResizeControlsInfo)+=A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	GroupBox group_channelSel_DA, pos={135.00, 41.00}, size={44.00, 206.00}, disable=1
	GroupBox group_channelSel_DA, title="DA", userdata(tabnum)="2"
	GroupBox group_channelSel_DA, userdata(tabcontrol)="Settings"
	GroupBox group_channelSel_DA, userdata(ResizeControlsInfo)=A"!!,Fl!!#>2!!#>>!!#A]z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	GroupBox group_channelSel_DA, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	GroupBox group_channelSel_DA, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	GroupBox group_properties_pulse, pos={31.00, 84.00}, size={379.00, 361.00}, disable=3
	GroupBox group_properties_pulse, userdata(tabnum)="4"
	GroupBox group_properties_pulse, userdata(tabcontrol)="Settings"
	GroupBox group_properties_pulse, userdata(ResizeControlsInfo)=A"!!,C\\!!#?a!!#C\"J,hsDJ,fQL!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	GroupBox group_properties_pulse, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	GroupBox group_properties_pulse, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	GroupBox group_enable_pulse, pos={31.00, 25.00}, size={380.00, 50.00}, disable=1
	GroupBox group_enable_pulse, title="Pulse Averaging", userdata(tabnum)="4"
	GroupBox group_enable_pulse, userdata(tabcontrol)="Settings"
	GroupBox group_enable_pulse, userdata(ResizeControlsInfo)=A"!!,C\\!!#=+!!#C#!!#>Vz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	GroupBox group_enable_pulse, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	GroupBox group_enable_pulse, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_DA_0, pos={143.00, 60.00}, size={22.00, 15.00}, disable=1, proc=BSP_CheckProc_ChangedSetting
	CheckBox check_channelSel_DA_0, title="0", help={"Toggle the DA channel display"}
	CheckBox check_channelSel_DA_0, userdata(tabnum)="2"
	CheckBox check_channelSel_DA_0, userdata(tabcontrol)="Settings"
	CheckBox check_channelSel_DA_0, userdata(ResizeControlsInfo)=A"!!,Ft!!#?)!!#<h!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_DA_0, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_DA_0, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_DA_0, userdata(ControlArray)="DA Channel selection"
	CheckBox check_channelSel_DA_0, userdata(ControlArrayIndex)="0", value=1
	CheckBox check_channelSel_DA_1, pos={143.00, 81.00}, size={22.00, 15.00}, disable=1, proc=BSP_CheckProc_ChangedSetting
	CheckBox check_channelSel_DA_1, title="1", help={"Toggle the DA channel display"}
	CheckBox check_channelSel_DA_1, userdata(tabnum)="2"
	CheckBox check_channelSel_DA_1, userdata(tabcontrol)="Settings"
	CheckBox check_channelSel_DA_1, userdata(ResizeControlsInfo)=A"!!,Ft!!#?[!!#<h!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_DA_1, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_DA_1, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_DA_1, userdata(ControlArray)="DA Channel selection"
	CheckBox check_channelSel_DA_1, userdata(ControlArrayIndex)="1", value=1
	CheckBox check_channelSel_DA_2, pos={143.00, 102.00}, size={22.00, 15.00}, disable=1, proc=BSP_CheckProc_ChangedSetting
	CheckBox check_channelSel_DA_2, title="2", help={"Toggle the DA channel display"}
	CheckBox check_channelSel_DA_2, userdata(tabnum)="2"
	CheckBox check_channelSel_DA_2, userdata(tabcontrol)="Settings"
	CheckBox check_channelSel_DA_2, userdata(ResizeControlsInfo)=A"!!,Ft!!#@0!!#<h!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_DA_2, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_DA_2, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_DA_2, userdata(ControlArray)="DA Channel selection"
	CheckBox check_channelSel_DA_2, userdata(ControlArrayIndex)="2", value=1
	CheckBox check_channelSel_DA_3, pos={143.00, 123.00}, size={22.00, 15.00}, disable=1, proc=BSP_CheckProc_ChangedSetting
	CheckBox check_channelSel_DA_3, title="3", help={"Toggle the DA channel display"}
	CheckBox check_channelSel_DA_3, userdata(tabnum)="2"
	CheckBox check_channelSel_DA_3, userdata(tabcontrol)="Settings"
	CheckBox check_channelSel_DA_3, userdata(ResizeControlsInfo)=A"!!,Ft!!#@Z!!#<h!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_DA_3, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_DA_3, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_DA_3, userdata(ControlArray)="DA Channel selection"
	CheckBox check_channelSel_DA_3, userdata(ControlArrayIndex)="3", value=1
	CheckBox check_channelSel_DA_4, pos={143.00, 144.00}, size={22.00, 15.00}, disable=1, proc=BSP_CheckProc_ChangedSetting
	CheckBox check_channelSel_DA_4, title="4", help={"Toggle the DA channel display"}
	CheckBox check_channelSel_DA_4, userdata(tabnum)="2"
	CheckBox check_channelSel_DA_4, userdata(tabcontrol)="Settings"
	CheckBox check_channelSel_DA_4, userdata(ResizeControlsInfo)=A"!!,Ft!!#@t!!#<h!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_DA_4, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_DA_4, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_DA_4, userdata(ControlArray)="DA Channel selection"
	CheckBox check_channelSel_DA_4, userdata(ControlArrayIndex)="4", value=1
	CheckBox check_channelSel_DA_5, pos={143.00, 165.00}, size={22.00, 15.00}, disable=1, proc=BSP_CheckProc_ChangedSetting
	CheckBox check_channelSel_DA_5, title="5", help={"Toggle the DA channel display"}
	CheckBox check_channelSel_DA_5, userdata(tabnum)="2"
	CheckBox check_channelSel_DA_5, userdata(tabcontrol)="Settings"
	CheckBox check_channelSel_DA_5, userdata(ResizeControlsInfo)=A"!!,Ft!!#A4!!#<h!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_DA_5, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_DA_5, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_DA_5, userdata(ControlArray)="DA Channel selection"
	CheckBox check_channelSel_DA_5, userdata(ControlArrayIndex)="5", value=1
	CheckBox check_channelSel_DA_6, pos={143.00, 186.00}, size={22.00, 15.00}, disable=1, proc=BSP_CheckProc_ChangedSetting
	CheckBox check_channelSel_DA_6, title="6", help={"Toggle the DA channel display"}
	CheckBox check_channelSel_DA_6, userdata(tabnum)="2"
	CheckBox check_channelSel_DA_6, userdata(tabcontrol)="Settings"
	CheckBox check_channelSel_DA_6, userdata(ResizeControlsInfo)=A"!!,Ft!!#AI!!#<h!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_DA_6, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_DA_6, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_DA_6, userdata(ControlArray)="DA Channel selection"
	CheckBox check_channelSel_DA_6, userdata(ControlArrayIndex)="6", value=1
	CheckBox check_channelSel_DA_7, pos={143.00, 207.00}, size={22.00, 15.00}, disable=1, proc=BSP_CheckProc_ChangedSetting
	CheckBox check_channelSel_DA_7, title="7", help={"Toggle the DA channel display"}
	CheckBox check_channelSel_DA_7, userdata(tabnum)="2"
	CheckBox check_channelSel_DA_7, userdata(tabcontrol)="Settings"
	CheckBox check_channelSel_DA_7, userdata(ResizeControlsInfo)=A"!!,Ft!!#A^!!#<h!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_DA_7, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_DA_7, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_DA_7, userdata(ControlArray)="DA Channel selection"
	CheckBox check_channelSel_DA_7, userdata(ControlArrayIndex)="7", value=1
	GroupBox group_channelSel_HEADSTAGE, pos={71.00, 42.00}, size={46.00, 206.00}, disable=1
	GroupBox group_channelSel_HEADSTAGE, title="HS", userdata(tabnum)="2"
	GroupBox group_channelSel_HEADSTAGE, userdata(tabcontrol)="Settings"
	GroupBox group_channelSel_HEADSTAGE, userdata(ResizeControlsInfo)=A"!!,EH!!#>6!!#>F!!#A]z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	GroupBox group_channelSel_HEADSTAGE, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	GroupBox group_channelSel_HEADSTAGE, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_HEADSTAGE_0, pos={80.00, 60.00}, size={22.00, 15.00}, disable=1, proc=BSP_CheckProc_ChangedSetting
	CheckBox check_channelSel_HEADSTAGE_0, title="0"
	CheckBox check_channelSel_HEADSTAGE_0, help={"Toggle the headstage display"}
	CheckBox check_channelSel_HEADSTAGE_0, userdata(tabnum)="2"
	CheckBox check_channelSel_HEADSTAGE_0, userdata(tabcontrol)="Settings"
	CheckBox check_channelSel_HEADSTAGE_0, userdata(ResizeControlsInfo)=A"!!,EZ!!#?)!!#<h!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_HEADSTAGE_0, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_HEADSTAGE_0, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_HEADSTAGE_0, userdata(ControlArrayIndex)="0"
	CheckBox check_channelSel_HEADSTAGE_0, userdata(ControlArray)="Headstage Channel selection"
	CheckBox check_channelSel_HEADSTAGE_0, value=1
	CheckBox check_channelSel_HEADSTAGE_1, pos={80.00, 81.00}, size={22.00, 15.00}, disable=1, proc=BSP_CheckProc_ChangedSetting
	CheckBox check_channelSel_HEADSTAGE_1, title="1"
	CheckBox check_channelSel_HEADSTAGE_1, help={"Toggle the headstage display"}
	CheckBox check_channelSel_HEADSTAGE_1, userdata(tabnum)="2"
	CheckBox check_channelSel_HEADSTAGE_1, userdata(tabcontrol)="Settings"
	CheckBox check_channelSel_HEADSTAGE_1, userdata(ResizeControlsInfo)=A"!!,EZ!!#?[!!#<h!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_HEADSTAGE_1, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_HEADSTAGE_1, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_HEADSTAGE_1, userdata(ControlArrayIndex)="1"
	CheckBox check_channelSel_HEADSTAGE_1, userdata(ControlArray)="Headstage Channel selection"
	CheckBox check_channelSel_HEADSTAGE_1, value=1
	CheckBox check_channelSel_HEADSTAGE_2, pos={80.00, 102.00}, size={22.00, 15.00}, disable=1, proc=BSP_CheckProc_ChangedSetting
	CheckBox check_channelSel_HEADSTAGE_2, title="2"
	CheckBox check_channelSel_HEADSTAGE_2, help={"Toggle the headstage display"}
	CheckBox check_channelSel_HEADSTAGE_2, userdata(tabnum)="2"
	CheckBox check_channelSel_HEADSTAGE_2, userdata(tabcontrol)="Settings"
	CheckBox check_channelSel_HEADSTAGE_2, userdata(ResizeControlsInfo)=A"!!,EZ!!#@0!!#<h!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_HEADSTAGE_2, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_HEADSTAGE_2, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_HEADSTAGE_2, userdata(ControlArrayIndex)="2"
	CheckBox check_channelSel_HEADSTAGE_2, userdata(ControlArray)="Headstage Channel selection"
	CheckBox check_channelSel_HEADSTAGE_2, value=1
	CheckBox check_channelSel_HEADSTAGE_3, pos={80.00, 123.00}, size={22.00, 15.00}, disable=1, proc=BSP_CheckProc_ChangedSetting
	CheckBox check_channelSel_HEADSTAGE_3, title="3"
	CheckBox check_channelSel_HEADSTAGE_3, help={"Toggle the headstage display"}
	CheckBox check_channelSel_HEADSTAGE_3, userdata(tabnum)="2"
	CheckBox check_channelSel_HEADSTAGE_3, userdata(tabcontrol)="Settings"
	CheckBox check_channelSel_HEADSTAGE_3, userdata(ResizeControlsInfo)=A"!!,EZ!!#@Z!!#<h!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_HEADSTAGE_3, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_HEADSTAGE_3, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_HEADSTAGE_3, userdata(ControlArrayIndex)="3"
	CheckBox check_channelSel_HEADSTAGE_3, userdata(ControlArray)="Headstage Channel selection"
	CheckBox check_channelSel_HEADSTAGE_3, value=1
	CheckBox check_channelSel_HEADSTAGE_4, pos={80.00, 144.00}, size={22.00, 15.00}, disable=1, proc=BSP_CheckProc_ChangedSetting
	CheckBox check_channelSel_HEADSTAGE_4, title="4"
	CheckBox check_channelSel_HEADSTAGE_4, help={"Toggle the headstage display"}
	CheckBox check_channelSel_HEADSTAGE_4, userdata(tabnum)="2"
	CheckBox check_channelSel_HEADSTAGE_4, userdata(tabcontrol)="Settings"
	CheckBox check_channelSel_HEADSTAGE_4, userdata(ResizeControlsInfo)=A"!!,EZ!!#@t!!#<h!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_HEADSTAGE_4, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_HEADSTAGE_4, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_HEADSTAGE_4, userdata(ControlArrayIndex)="4"
	CheckBox check_channelSel_HEADSTAGE_4, userdata(ControlArray)="Headstage Channel selection"
	CheckBox check_channelSel_HEADSTAGE_4, value=1
	CheckBox check_channelSel_HEADSTAGE_5, pos={80.00, 165.00}, size={22.00, 15.00}, disable=1, proc=BSP_CheckProc_ChangedSetting
	CheckBox check_channelSel_HEADSTAGE_5, title="5"
	CheckBox check_channelSel_HEADSTAGE_5, help={"Toggle the headstage display"}
	CheckBox check_channelSel_HEADSTAGE_5, userdata(tabnum)="2"
	CheckBox check_channelSel_HEADSTAGE_5, userdata(tabcontrol)="Settings"
	CheckBox check_channelSel_HEADSTAGE_5, userdata(ResizeControlsInfo)=A"!!,EZ!!#A4!!#<h!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_HEADSTAGE_5, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_HEADSTAGE_5, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_HEADSTAGE_5, userdata(ControlArrayIndex)="5"
	CheckBox check_channelSel_HEADSTAGE_5, userdata(ControlArray)="Headstage Channel selection"
	CheckBox check_channelSel_HEADSTAGE_5, value=1
	CheckBox check_channelSel_HEADSTAGE_6, pos={80.00, 186.00}, size={22.00, 15.00}, disable=1, proc=BSP_CheckProc_ChangedSetting
	CheckBox check_channelSel_HEADSTAGE_6, title="6"
	CheckBox check_channelSel_HEADSTAGE_6, help={"Toggle the headstage display"}
	CheckBox check_channelSel_HEADSTAGE_6, userdata(tabnum)="2"
	CheckBox check_channelSel_HEADSTAGE_6, userdata(tabcontrol)="Settings"
	CheckBox check_channelSel_HEADSTAGE_6, userdata(ResizeControlsInfo)=A"!!,EZ!!#AI!!#<h!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_HEADSTAGE_6, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_HEADSTAGE_6, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_HEADSTAGE_6, userdata(ControlArrayIndex)="6"
	CheckBox check_channelSel_HEADSTAGE_6, userdata(ControlArray)="Headstage Channel selection"
	CheckBox check_channelSel_HEADSTAGE_6, value=1
	CheckBox check_channelSel_HEADSTAGE_7, pos={80.00, 207.00}, size={22.00, 15.00}, disable=1, proc=BSP_CheckProc_ChangedSetting
	CheckBox check_channelSel_HEADSTAGE_7, title="7"
	CheckBox check_channelSel_HEADSTAGE_7, help={"Toggle the headstage display"}
	CheckBox check_channelSel_HEADSTAGE_7, userdata(tabnum)="2"
	CheckBox check_channelSel_HEADSTAGE_7, userdata(tabcontrol)="Settings"
	CheckBox check_channelSel_HEADSTAGE_7, userdata(ResizeControlsInfo)=A"!!,EZ!!#A^!!#<h!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_HEADSTAGE_7, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_HEADSTAGE_7, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_HEADSTAGE_7, userdata(ControlArrayIndex)="7"
	CheckBox check_channelSel_HEADSTAGE_7, userdata(ControlArray)="Headstage Channel selection"
	CheckBox check_channelSel_HEADSTAGE_7, value=1
	GroupBox group_channelSel_AD, pos={193.00, 42.00}, size={65.00, 204.00}, disable=1
	GroupBox group_channelSel_AD, title="AD", userdata(tabnum)="2"
	GroupBox group_channelSel_AD, userdata(tabcontrol)="Settings"
	GroupBox group_channelSel_AD, userdata(ResizeControlsInfo)=A"!!,GQ!!#>6!!#?;!!#A[z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	GroupBox group_channelSel_AD, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	GroupBox group_channelSel_AD, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_AD_0, pos={200.00, 60.00}, size={22.00, 15.00}, disable=1, proc=BSP_CheckProc_ChangedSetting
	CheckBox check_channelSel_AD_0, title="0", help={"Toggle the AD channel display"}
	CheckBox check_channelSel_AD_0, userdata(tabnum)="2"
	CheckBox check_channelSel_AD_0, userdata(tabcontrol)="Settings"
	CheckBox check_channelSel_AD_0, userdata(ResizeControlsInfo)=A"!!,GX!!#?)!!#<h!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_AD_0, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_AD_0, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_AD_0, userdata(ControlArray)="AD Channel selection"
	CheckBox check_channelSel_AD_0, userdata(ControlArrayIndex)="0", value=1
	CheckBox check_channelSel_AD_1, pos={200.00, 81.00}, size={22.00, 15.00}, disable=1, proc=BSP_CheckProc_ChangedSetting
	CheckBox check_channelSel_AD_1, title="1", help={"Toggle the AD channel display"}
	CheckBox check_channelSel_AD_1, userdata(tabnum)="2"
	CheckBox check_channelSel_AD_1, userdata(tabcontrol)="Settings"
	CheckBox check_channelSel_AD_1, userdata(ResizeControlsInfo)=A"!!,GX!!#?[!!#<h!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_AD_1, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_AD_1, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_AD_1, userdata(ControlArray)="AD Channel selection"
	CheckBox check_channelSel_AD_1, userdata(ControlArrayIndex)="1", value=1
	CheckBox check_channelSel_AD_2, pos={200.00, 102.00}, size={22.00, 15.00}, disable=1, proc=BSP_CheckProc_ChangedSetting
	CheckBox check_channelSel_AD_2, title="2", help={"Toggle the AD channel display"}
	CheckBox check_channelSel_AD_2, userdata(tabnum)="2"
	CheckBox check_channelSel_AD_2, userdata(tabcontrol)="Settings"
	CheckBox check_channelSel_AD_2, userdata(ResizeControlsInfo)=A"!!,GX!!#@0!!#<h!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_AD_2, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_AD_2, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_AD_2, userdata(ControlArray)="AD Channel selection"
	CheckBox check_channelSel_AD_2, userdata(ControlArrayIndex)="2", value=1
	CheckBox check_channelSel_AD_3, pos={200.00, 123.00}, size={22.00, 15.00}, disable=1, proc=BSP_CheckProc_ChangedSetting
	CheckBox check_channelSel_AD_3, title="3", help={"Toggle the AD channel display"}
	CheckBox check_channelSel_AD_3, userdata(tabnum)="2"
	CheckBox check_channelSel_AD_3, userdata(tabcontrol)="Settings"
	CheckBox check_channelSel_AD_3, userdata(ResizeControlsInfo)=A"!!,GX!!#@Z!!#<h!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_AD_3, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_AD_3, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_AD_3, userdata(ControlArray)="AD Channel selection"
	CheckBox check_channelSel_AD_3, userdata(ControlArrayIndex)="3", value=1
	CheckBox check_channelSel_AD_4, pos={200.00, 144.00}, size={22.00, 15.00}, disable=1, proc=BSP_CheckProc_ChangedSetting
	CheckBox check_channelSel_AD_4, title="4", help={"Toggle the AD channel display"}
	CheckBox check_channelSel_AD_4, userdata(tabnum)="2"
	CheckBox check_channelSel_AD_4, userdata(tabcontrol)="Settings"
	CheckBox check_channelSel_AD_4, userdata(ResizeControlsInfo)=A"!!,GX!!#@t!!#<h!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_AD_4, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_AD_4, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_AD_4, userdata(ControlArray)="AD Channel selection"
	CheckBox check_channelSel_AD_4, userdata(ControlArrayIndex)="4", value=1
	CheckBox check_channelSel_AD_5, pos={200.00, 165.00}, size={22.00, 15.00}, disable=1, proc=BSP_CheckProc_ChangedSetting
	CheckBox check_channelSel_AD_5, title="5", help={"Toggle the AD channel display"}
	CheckBox check_channelSel_AD_5, userdata(tabnum)="2"
	CheckBox check_channelSel_AD_5, userdata(tabcontrol)="Settings"
	CheckBox check_channelSel_AD_5, userdata(ResizeControlsInfo)=A"!!,GX!!#A4!!#<h!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_AD_5, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_AD_5, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_AD_5, userdata(ControlArray)="AD Channel selection"
	CheckBox check_channelSel_AD_5, userdata(ControlArrayIndex)="5", value=1
	CheckBox check_channelSel_AD_6, pos={200.00, 186.00}, size={22.00, 15.00}, disable=1, proc=BSP_CheckProc_ChangedSetting
	CheckBox check_channelSel_AD_6, title="6", help={"Toggle the AD channel display"}
	CheckBox check_channelSel_AD_6, userdata(tabnum)="2"
	CheckBox check_channelSel_AD_6, userdata(tabcontrol)="Settings"
	CheckBox check_channelSel_AD_6, userdata(ResizeControlsInfo)=A"!!,GX!!#AI!!#<h!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_AD_6, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_AD_6, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_AD_6, userdata(ControlArray)="AD Channel selection"
	CheckBox check_channelSel_AD_6, userdata(ControlArrayIndex)="6", value=1
	CheckBox check_channelSel_AD_7, pos={200.00, 207.00}, size={22.00, 15.00}, disable=1, proc=BSP_CheckProc_ChangedSetting
	CheckBox check_channelSel_AD_7, title="7", help={"Toggle the AD channel display"}
	CheckBox check_channelSel_AD_7, userdata(tabnum)="2"
	CheckBox check_channelSel_AD_7, userdata(tabcontrol)="Settings"
	CheckBox check_channelSel_AD_7, userdata(ResizeControlsInfo)=A"!!,GX!!#A^!!#<h!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_AD_7, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_AD_7, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_AD_7, userdata(ControlArray)="AD Channel selection"
	CheckBox check_channelSel_AD_7, userdata(ControlArrayIndex)="7", value=1
	CheckBox check_channelSel_AD_8, pos={225.00, 60.00}, size={22.00, 15.00}, disable=1, proc=BSP_CheckProc_ChangedSetting
	CheckBox check_channelSel_AD_8, title="8", help={"Toggle the AD channel display"}
	CheckBox check_channelSel_AD_8, userdata(tabnum)="2"
	CheckBox check_channelSel_AD_8, userdata(tabcontrol)="Settings"
	CheckBox check_channelSel_AD_8, userdata(ResizeControlsInfo)=A"!!,Gq!!#?)!!#<h!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_AD_8, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_AD_8, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_AD_8, userdata(ControlArray)="AD Channel selection"
	CheckBox check_channelSel_AD_8, userdata(ControlArrayIndex)="8", value=1
	CheckBox check_channelSel_AD_9, pos={225.00, 81.00}, size={22.00, 15.00}, disable=1, proc=BSP_CheckProc_ChangedSetting
	CheckBox check_channelSel_AD_9, title="9", help={"Toggle the AD channel display"}
	CheckBox check_channelSel_AD_9, userdata(tabnum)="2"
	CheckBox check_channelSel_AD_9, userdata(tabcontrol)="Settings"
	CheckBox check_channelSel_AD_9, userdata(ResizeControlsInfo)=A"!!,Gq!!#?[!!#<h!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_AD_9, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_AD_9, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_AD_9, userdata(ControlArray)="AD Channel selection"
	CheckBox check_channelSel_AD_9, userdata(ControlArrayIndex)="9", value=1
	CheckBox check_channelSel_AD_10, pos={225.00, 102.00}, size={28.00, 15.00}, disable=1, proc=BSP_CheckProc_ChangedSetting
	CheckBox check_channelSel_AD_10, title="10"
	CheckBox check_channelSel_AD_10, help={"Toggle the AD channel display"}
	CheckBox check_channelSel_AD_10, userdata(tabnum)="2"
	CheckBox check_channelSel_AD_10, userdata(tabcontrol)="Settings"
	CheckBox check_channelSel_AD_10, userdata(ResizeControlsInfo)=A"!!,Gq!!#@0!!#=C!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_AD_10, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_AD_10, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_AD_10, userdata(ControlArray)="AD Channel selection"
	CheckBox check_channelSel_AD_10, userdata(ControlArrayIndex)="10", value=1
	CheckBox check_channelSel_AD_11, pos={225.00, 123.00}, size={28.00, 15.00}, disable=1, proc=BSP_CheckProc_ChangedSetting
	CheckBox check_channelSel_AD_11, title="11"
	CheckBox check_channelSel_AD_11, help={"Toggle the AD channel display"}
	CheckBox check_channelSel_AD_11, userdata(tabnum)="2"
	CheckBox check_channelSel_AD_11, userdata(tabcontrol)="Settings"
	CheckBox check_channelSel_AD_11, userdata(ResizeControlsInfo)=A"!!,Gq!!#@Z!!#=C!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_AD_11, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_AD_11, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_AD_11, userdata(ControlArray)="AD Channel selection"
	CheckBox check_channelSel_AD_11, userdata(ControlArrayIndex)="11", value=1
	CheckBox check_channelSel_AD_12, pos={225.00, 144.00}, size={28.00, 15.00}, disable=1, proc=BSP_CheckProc_ChangedSetting
	CheckBox check_channelSel_AD_12, title="12"
	CheckBox check_channelSel_AD_12, help={"Toggle the AD channel display"}
	CheckBox check_channelSel_AD_12, userdata(tabnum)="2"
	CheckBox check_channelSel_AD_12, userdata(tabcontrol)="Settings"
	CheckBox check_channelSel_AD_12, userdata(ResizeControlsInfo)=A"!!,Gq!!#@t!!#=C!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_AD_12, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_AD_12, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_AD_12, userdata(ControlArray)="AD Channel selection"
	CheckBox check_channelSel_AD_12, userdata(ControlArrayIndex)="12", value=1
	CheckBox check_channelSel_AD_13, pos={225.00, 165.00}, size={28.00, 15.00}, disable=1, proc=BSP_CheckProc_ChangedSetting
	CheckBox check_channelSel_AD_13, title="13"
	CheckBox check_channelSel_AD_13, help={"Toggle the AD channel display"}
	CheckBox check_channelSel_AD_13, userdata(tabnum)="2"
	CheckBox check_channelSel_AD_13, userdata(tabcontrol)="Settings"
	CheckBox check_channelSel_AD_13, userdata(ResizeControlsInfo)=A"!!,Gq!!#A4!!#=C!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_AD_13, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_AD_13, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_AD_13, userdata(ControlArray)="AD Channel selection"
	CheckBox check_channelSel_AD_13, userdata(ControlArrayIndex)="13", value=1
	CheckBox check_channelSel_AD_14, pos={225.00, 186.00}, size={28.00, 15.00}, disable=1, proc=BSP_CheckProc_ChangedSetting
	CheckBox check_channelSel_AD_14, title="14"
	CheckBox check_channelSel_AD_14, help={"Toggle the AD channel display"}
	CheckBox check_channelSel_AD_14, userdata(tabnum)="2"
	CheckBox check_channelSel_AD_14, userdata(tabcontrol)="Settings"
	CheckBox check_channelSel_AD_14, userdata(ResizeControlsInfo)=A"!!,Gq!!#AI!!#=C!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_AD_14, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_AD_14, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_AD_14, userdata(ControlArray)="AD Channel selection"
	CheckBox check_channelSel_AD_14, userdata(ControlArrayIndex)="14", value=1
	CheckBox check_channelSel_AD_15, pos={225.00, 207.00}, size={28.00, 15.00}, disable=1, proc=BSP_CheckProc_ChangedSetting
	CheckBox check_channelSel_AD_15, title="15"
	CheckBox check_channelSel_AD_15, help={"Toggle the AD channel display"}
	CheckBox check_channelSel_AD_15, userdata(tabnum)="2"
	CheckBox check_channelSel_AD_15, userdata(tabcontrol)="Settings"
	CheckBox check_channelSel_AD_15, userdata(ResizeControlsInfo)=A"!!,Gq!!#A^!!#=C!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_AD_15, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_channelSel_AD_15, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_channelSel_AD_15, userdata(ControlArray)="AD Channel selection"
	CheckBox check_channelSel_AD_15, userdata(ControlArrayIndex)="15", value=1
	ListBox list_of_ranges1, pos={75.00, 156.00}, size={281.00, 336.00}, disable=3, proc=AR_MainListBoxProc
	ListBox list_of_ranges1, help={"List of artefact ranges"}, userdata(tabnum)="3"
	ListBox list_of_ranges1, userdata(tabcontrol)="Settings"
	ListBox list_of_ranges1, userdata(ResizeControlsInfo)=A"!!,EP!!#A+!!#BFJ,hs8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#o2B4uAezz"
	ListBox list_of_ranges1, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	ListBox list_of_ranges1, userdata(ResizeControlsInfo)+=A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	ListBox list_of_ranges1, userdata(Config_DontRestore)="1"
	ListBox list_of_ranges1, userdata(Config_DontSave)="1", mode=1, selRow=0
	ListBox list_of_ranges1, widths={54, 50, 66}
	Button button_RemoveRanges, pos={113.00, 126.00}, size={54.00, 21.00}, disable=3, proc=AR_ButtonProc_RemoveRanges
	Button button_RemoveRanges, title="Remove", help={"Remove the found artefacts"}
	Button button_RemoveRanges, userdata(tabnum)="3", userdata(tabcontrol)="Settings"
	Button button_RemoveRanges, userdata(ResizeControlsInfo)=A"!!,FG!!#@`!!#>f!!#<`z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	Button button_RemoveRanges, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button button_RemoveRanges, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_cutoff_length_after, pos={269.00, 96.00}, size={45.00, 18.00}, disable=3, proc=AR_SetVarProcCutoffLength
	SetVariable setvar_cutoff_length_after, help={"Time in ms which should be cutoff *after* the artefact."}
	SetVariable setvar_cutoff_length_after, userdata(tabnum)="3"
	SetVariable setvar_cutoff_length_after, userdata(tabcontrol)="Settings"
	SetVariable setvar_cutoff_length_after, userdata(ResizeControlsInfo)=A"!!,HAJ,hpO!!#>B!!#<Hz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	SetVariable setvar_cutoff_length_after, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_cutoff_length_after, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_cutoff_length_after, limits={0, Inf, 0.1}, value=_NUM:0.2
	SetVariable setvar_cutoff_length_before, pos={116.00, 96.00}, size={150.00, 18.00}, disable=3, proc=AR_SetVarProcCutoffLength
	SetVariable setvar_cutoff_length_before, title="Cutoff length [ms]:"
	SetVariable setvar_cutoff_length_before, help={"Time in ms which should be cutoff *before* the artefact."}
	SetVariable setvar_cutoff_length_before, userdata(tabnum)="3"
	SetVariable setvar_cutoff_length_before, userdata(tabcontrol)="Settings"
	SetVariable setvar_cutoff_length_before, userdata(ResizeControlsInfo)=A"!!,FM!!#@$!!#A%!!#<Hz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	SetVariable setvar_cutoff_length_before, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_cutoff_length_before, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_cutoff_length_before, limits={0, Inf, 0.1}, value=_NUM:0.1
	CheckBox check_auto_remove, pos={182.00, 129.00}, size={85.00, 15.00}, disable=3, proc=AR_CheckProc_Update
	CheckBox check_auto_remove, title="Auto remove"
	CheckBox check_auto_remove, help={"Automatically remove the found ranges on sweep plotting"}
	CheckBox check_auto_remove, userdata(tabnum)="3", userdata(tabcontrol)="Settings"
	CheckBox check_auto_remove, userdata(ResizeControlsInfo)=A"!!,GF!!#@e!!#?c!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_auto_remove, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_auto_remove, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_auto_remove, value=0
	CheckBox check_highlightRanges, pos={284.00, 129.00}, size={31.00, 15.00}, disable=3, proc=AR_CheckProc_Update
	CheckBox check_highlightRanges, title="HL"
	CheckBox check_highlightRanges, help={"Visualize the found ranges in the graph (*might* slowdown graphing)"}
	CheckBox check_highlightRanges, userdata(tabnum)="3"
	CheckBox check_highlightRanges, userdata(tabcontrol)="Settings"
	CheckBox check_highlightRanges, userdata(ResizeControlsInfo)=A"!!,HI!!#@e!!#=[!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_highlightRanges, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_highlightRanges, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_highlightRanges, value=0
	SetVariable setvar_pulseAver_overridePulseLength, pos={236.00, 296.00}, size={136.00, 18.00}, bodyWidth=50, disable=1, proc=PA_SetVarProc_Common
	SetVariable setvar_pulseAver_overridePulseLength, title="Override length"
	SetVariable setvar_pulseAver_overridePulseLength, help={"Pulse To Pulse length in ms for edge cases which can not be computed or when the fixed pulse length checkbox is active. Shorter pulses are dropped."}
	SetVariable setvar_pulseAver_overridePulseLength, userdata(tabnum)="4"
	SetVariable setvar_pulseAver_overridePulseLength, userdata(tabcontrol)="Settings"
	SetVariable setvar_pulseAver_overridePulseLength, userdata(ResizeControlsInfo)=A"!!,H'!!#BN!!#@l!!#<Hz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	SetVariable setvar_pulseAver_overridePulseLength, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_pulseAver_overridePulseLength, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_pulseAver_overridePulseLength, limits={0, Inf, 1}, value=_NUM:10
	SetVariable setvar_pulseAver_endPulse, pos={240.00, 254.00}, size={122.00, 18.00}, bodyWidth=50, disable=1, proc=PA_SetVarProc_Common
	SetVariable setvar_pulseAver_endPulse, title="Ending pulse"
	SetVariable setvar_pulseAver_endPulse, help={"Index of the last pulse to display"}
	SetVariable setvar_pulseAver_endPulse, userdata(tabnum)="4"
	SetVariable setvar_pulseAver_endPulse, userdata(tabcontrol)="Settings"
	SetVariable setvar_pulseAver_endPulse, userdata(ResizeControlsInfo)=A"!!,H+!!#B8!!#@X!!#<Hz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	SetVariable setvar_pulseAver_endPulse, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_pulseAver_endPulse, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_pulseAver_endPulse, limits={0, Inf, 1}, value=_NUM:Inf
	SetVariable setvar_pulseAver_startPulse, pos={236.00, 232.00}, size={126.00, 18.00}, bodyWidth=50, disable=1, proc=PA_SetVarProc_Common
	SetVariable setvar_pulseAver_startPulse, title="Starting pulse"
	SetVariable setvar_pulseAver_startPulse, help={"Index of the first pulse to display"}
	SetVariable setvar_pulseAver_startPulse, userdata(tabnum)="4"
	SetVariable setvar_pulseAver_startPulse, userdata(tabcontrol)="Settings"
	SetVariable setvar_pulseAver_startPulse, userdata(ResizeControlsInfo)=A"!!,H'!!#B\"!!#@`!!#<Hz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	SetVariable setvar_pulseAver_startPulse, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_pulseAver_startPulse, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_pulseAver_startPulse, limits={0, Inf, 1}, value=_NUM:0
	CheckBox check_pulseAver_multGraphs, pos={234.00, 165.00}, size={121.00, 15.00}, disable=1, proc=PA_CheckProc_Common
	CheckBox check_pulseAver_multGraphs, title="Use multiple graphs"
	CheckBox check_pulseAver_multGraphs, help={"Show the single pulses in multiple graphs or only one graph with multiple axis."}
	CheckBox check_pulseAver_multGraphs, userdata(tabnum)="4"
	CheckBox check_pulseAver_multGraphs, userdata(tabcontrol)="Settings"
	CheckBox check_pulseAver_multGraphs, userdata(ResizeControlsInfo)=A"!!,H%!!#A4!!#@V!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_pulseAver_multGraphs, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_pulseAver_multGraphs, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_pulseAver_multGraphs, value=0
	CheckBox check_pulseAver_zero, pos={234.00, 108.00}, size={76.00, 15.00}, disable=1, proc=PA_CheckProc_Common
	CheckBox check_pulseAver_zero, title="Zero pulses"
	CheckBox check_pulseAver_zero, help={"Zero the individual traces using subsequent differentiation and integration"}
	CheckBox check_pulseAver_zero, userdata(tabnum)="4"
	CheckBox check_pulseAver_zero, userdata(tabcontrol)="Settings"
	CheckBox check_pulseAver_zero, userdata(ResizeControlsInfo)=A"!!,H%!!#@<!!#?Q!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_pulseAver_zero, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_pulseAver_zero, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_pulseAver_zero, value=0
	CheckBox check_pulseAver_showAver, pos={234.00, 146.00}, size={89.00, 15.00}, disable=1, proc=PA_CheckProc_Common
	CheckBox check_pulseAver_showAver, title="Show average"
	CheckBox check_pulseAver_showAver, help={"Show the average trace"}
	CheckBox check_pulseAver_showAver, userdata(tabnum)="4"
	CheckBox check_pulseAver_showAver, userdata(tabcontrol)="Settings"
	CheckBox check_pulseAver_showAver, userdata(ResizeControlsInfo)=A"!!,H%!!#A!!!#?k!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_pulseAver_showAver, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_pulseAver_showAver, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_pulseAver_showAver, value=0
	CheckBox check_pulseAver_indPulses, pos={234.00, 183.00}, size={136.00, 15.00}, disable=1, proc=PA_CheckProc_Common
	CheckBox check_pulseAver_indPulses, title="Show individual pulses"
	CheckBox check_pulseAver_indPulses, help={"Show the individual pulses in the plot"}
	CheckBox check_pulseAver_indPulses, userdata(tabnum)="4"
	CheckBox check_pulseAver_indPulses, userdata(tabcontrol)="Settings"
	CheckBox check_pulseAver_indPulses, userdata(ResizeControlsInfo)=A"!!,H%!!#AF!!#@l!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_pulseAver_indPulses, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_pulseAver_indPulses, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_pulseAver_indPulses, value=1
	CheckBox check_pulseAver_deconv, pos={93.00, 340.00}, size={94.00, 15.00}, disable=1, proc=PA_CheckProc_Common
	CheckBox check_pulseAver_deconv, title="Deconvolution"
	CheckBox check_pulseAver_deconv, help={"Show Deconvolution: tau * dV/dt + V "}
	CheckBox check_pulseAver_deconv, userdata(tabnum)="4"
	CheckBox check_pulseAver_deconv, userdata(tabcontrol)="Settings"
	CheckBox check_pulseAver_deconv, userdata(ResizeControlsInfo)=A"!!,Et!!#Bd!!#?u!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_pulseAver_deconv, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_pulseAver_deconv, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_pulseAver_deconv, value=0
	CheckBox check_pulseAver_timeAlign, pos={234.00, 127.00}, size={99.00, 15.00}, disable=1, proc=PA_CheckProc_Common
	CheckBox check_pulseAver_timeAlign, title="Time alignment"
	CheckBox check_pulseAver_timeAlign, help={"Align all traces of a set to the first pulse of the same sweep from the diagonal element"}
	CheckBox check_pulseAver_timeAlign, userdata(tabnum)="4"
	CheckBox check_pulseAver_timeAlign, userdata(tabcontrol)="Settings"
	CheckBox check_pulseAver_timeAlign, userdata(ResizeControlsInfo)=A"!!,H%!!#@b!!#@*!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_pulseAver_timeAlign, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_pulseAver_timeAlign, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_pulseAver_timeAlign, value=0
	SetVariable setvar_pulseAver_deconv_tau, pos={101.00, 359.00}, size={98.00, 18.00}, bodyWidth=50, disable=1, proc=PA_SetVarProc_Common
	SetVariable setvar_pulseAver_deconv_tau, title="Tau [ms]"
	SetVariable setvar_pulseAver_deconv_tau, help={"Deconvolution time tau: tau * dV/dt + V"}
	SetVariable setvar_pulseAver_deconv_tau, userdata(tabnum)="4"
	SetVariable setvar_pulseAver_deconv_tau, userdata(tabcontrol)="Settings"
	SetVariable setvar_pulseAver_deconv_tau, userdata(ResizeControlsInfo)=A"!!,F/!!#BmJ,hpS!!#<Hz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	SetVariable setvar_pulseAver_deconv_tau, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_pulseAver_deconv_tau, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_pulseAver_deconv_tau, limits={0, Inf, 0}, value=_NUM:15
	SetVariable setvar_pulseAver_deconv_smth, pos={87.00, 383.00}, size={112.00, 18.00}, bodyWidth=50, disable=1, proc=PA_SetVarProc_Common
	SetVariable setvar_pulseAver_deconv_smth, title="Smoothing"
	SetVariable setvar_pulseAver_deconv_smth, help={"Smoothing factor to use before the deconvolution is calculated. Set to 1 to do the calculation without smoothing."}
	SetVariable setvar_pulseAver_deconv_smth, userdata(tabnum)="4"
	SetVariable setvar_pulseAver_deconv_smth, userdata(tabcontrol)="Settings"
	SetVariable setvar_pulseAver_deconv_smth, userdata(ResizeControlsInfo)=A"!!,Eh!!#C$J,hpo!!#<Hz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	SetVariable setvar_pulseAver_deconv_smth, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_pulseAver_deconv_smth, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_pulseAver_deconv_smth, limits={1, Inf, 0}, value=_NUM:1000
	SetVariable setvar_pulseAver_deconv_range, pos={81.00, 404.00}, size={118.00, 18.00}, bodyWidth=50, disable=1, proc=PA_SetVarProc_Common
	SetVariable setvar_pulseAver_deconv_range, title="Display [ms]"
	SetVariable setvar_pulseAver_deconv_range, help={"Time in ms from the beginning of the pulse that is used for the calculation"}
	SetVariable setvar_pulseAver_deconv_range, userdata(tabnum)="4"
	SetVariable setvar_pulseAver_deconv_range, userdata(tabcontrol)="Settings"
	SetVariable setvar_pulseAver_deconv_range, userdata(ResizeControlsInfo)=A"!!,E\\!!#C/!!#@P!!#<Hz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	SetVariable setvar_pulseAver_deconv_range, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_pulseAver_deconv_range, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_pulseAver_deconv_range, limits={0, Inf, 0}, value=_NUM:Inf
	GroupBox group_pulseAver_deconv, pos={61.00, 323.00}, size={155.00, 117.00}, disable=3
	GroupBox group_pulseAver_deconv, userdata(tabnum)="4"
	GroupBox group_pulseAver_deconv, userdata(tabcontrol)="Settings"
	GroupBox group_pulseAver_deconv, userdata(ResizeControlsInfo)=A"!!,E.!!#B[J,hqU!!#@Nz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	GroupBox group_pulseAver_deconv, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	GroupBox group_pulseAver_deconv, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_BrowserSettings_OVS, pos={186.00, 47.00}, size={51.00, 15.00}, disable=1, proc=BSP_CheckProc_OverlaySweeps
	CheckBox check_BrowserSettings_OVS, title="enable"
	CheckBox check_BrowserSettings_OVS, help={"Toggle plotting plot multiple sweeps overlayed in the same graph"}
	CheckBox check_BrowserSettings_OVS, userdata(tabnum)="1"
	CheckBox check_BrowserSettings_OVS, userdata(tabcontrol)="Settings"
	CheckBox check_BrowserSettings_OVS, userdata(ResizeControlsInfo)=A"!!,GJ!!#>J!!#>Z!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_BrowserSettings_OVS, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_BrowserSettings_OVS, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_BrowserSettings_OVS, value=0
	CheckBox check_BrowserSettings_AR, pos={186.00, 47.00}, size={51.00, 15.00}, disable=1, proc=BSP_CheckBoxProc_ArtRemoval
	CheckBox check_BrowserSettings_AR, title="enable"
	CheckBox check_BrowserSettings_AR, help={"Open the artefact removal dialog"}
	CheckBox check_BrowserSettings_AR, userdata(tabnum)="3"
	CheckBox check_BrowserSettings_AR, userdata(tabcontrol)="Settings"
	CheckBox check_BrowserSettings_AR, userdata(ResizeControlsInfo)=A"!!,GJ!!#>J!!#>Z!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_BrowserSettings_AR, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_BrowserSettings_AR, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_BrowserSettings_AR, value=0
	CheckBox check_BrowserSettings_PA, pos={186.00, 47.00}, size={51.00, 15.00}, disable=1, proc=BSP_CheckBoxProc_PerPulseAver
	CheckBox check_BrowserSettings_PA, title="enable"
	CheckBox check_BrowserSettings_PA, help={"Allows to average multiple pulses from pulse train epochs"}
	CheckBox check_BrowserSettings_PA, userdata(tabnum)="4"
	CheckBox check_BrowserSettings_PA, userdata(tabcontrol)="Settings"
	CheckBox check_BrowserSettings_PA, userdata(ResizeControlsInfo)=A"!!,GJ!!#>J!!#>Z!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_BrowserSettings_PA, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_BrowserSettings_PA, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_BrowserSettings_PA, value=0
	CheckBox check_BrowserSettings_DAC, pos={58.00, 36.00}, size={32.00, 15.00}, proc=BSP_CheckProc_ChangedSetting
	CheckBox check_BrowserSettings_DAC, title="DA"
	CheckBox check_BrowserSettings_DAC, help={"Display the DA channel data"}
	CheckBox check_BrowserSettings_DAC, userdata(tabnum)="0"
	CheckBox check_BrowserSettings_DAC, userdata(tabcontrol)="Settings"
	CheckBox check_BrowserSettings_DAC, userdata(ResizeControlsInfo)=A"!!,E\"!!#=s!!#=c!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_BrowserSettings_DAC, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_BrowserSettings_DAC, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_BrowserSettings_DAC, userdata(Config_RestorePriority)="10", value=0
	CheckBox check_BrowserSettings_ADC, pos={113.00, 36.00}, size={32.00, 15.00}, proc=BSP_CheckProc_ChangedSetting
	CheckBox check_BrowserSettings_ADC, title="AD", help={"Display the AD channels"}
	CheckBox check_BrowserSettings_ADC, userdata(tabnum)="0"
	CheckBox check_BrowserSettings_ADC, userdata(tabcontrol)="Settings"
	CheckBox check_BrowserSettings_ADC, userdata(ResizeControlsInfo)=A"!!,FG!!#=s!!#=c!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_BrowserSettings_ADC, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_BrowserSettings_ADC, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_BrowserSettings_ADC, userdata(Config_RestorePriority)="10", value=1
	CheckBox check_BrowserSettings_TTL, pos={170.00, 36.00}, size={36.00, 15.00}, proc=BSP_CheckProc_ChangedSetting
	CheckBox check_BrowserSettings_TTL, title="TTL", help={"Display the TTL channels"}
	CheckBox check_BrowserSettings_TTL, userdata(tabnum)="0"
	CheckBox check_BrowserSettings_TTL, userdata(tabcontrol)="Settings"
	CheckBox check_BrowserSettings_TTL, userdata(ResizeControlsInfo)=A"!!,G:!!#=s!!#=s!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_BrowserSettings_TTL, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_BrowserSettings_TTL, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_BrowserSettings_TTL, userdata(Config_RestorePriority)="10", value=0
	CheckBox check_BrowserSettings_OChan, pos={224.00, 36.00}, size={106.00, 15.00}, proc=BSP_CheckProc_ChangedSetting
	CheckBox check_BrowserSettings_OChan, title="Overlay channels"
	CheckBox check_BrowserSettings_OChan, help={"Overlay the data from multiple channels in one graph"}
	CheckBox check_BrowserSettings_OChan, userdata(tabnum)="0"
	CheckBox check_BrowserSettings_OChan, userdata(tabcontrol)="Settings"
	CheckBox check_BrowserSettings_OChan, userdata(ResizeControlsInfo)=A"!!,Gp!!#=s!!#@8!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_BrowserSettings_OChan, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_BrowserSettings_OChan, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_BrowserSettings_OChan, value=0
	CheckBox check_BrowserSettings_dDAQ, pos={352.00, 35.00}, size={48.00, 15.00}, proc=BSP_CheckProc_ChangedSetting
	CheckBox check_BrowserSettings_dDAQ, title="dDAQ"
	CheckBox check_BrowserSettings_dDAQ, help={"Enable dedicated support for viewing distributed DAQ data"}
	CheckBox check_BrowserSettings_dDAQ, userdata(tabnum)="0"
	CheckBox check_BrowserSettings_dDAQ, userdata(tabcontrol)="Settings"
	CheckBox check_BrowserSettings_dDAQ, userdata(ResizeControlsInfo)=A"!!,Hk!!#=o!!#>N!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_BrowserSettings_dDAQ, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_BrowserSettings_dDAQ, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_BrowserSettings_dDAQ, userdata(Config_RestorePriority)="10"
	CheckBox check_BrowserSettings_dDAQ, value=0
	CheckBox check_Calculation_ZeroTraces, pos={165.00, 200.00}, size={76.00, 15.00}, proc=BSP_CheckProc_ChangedSetting
	CheckBox check_Calculation_ZeroTraces, title="Zero Traces"
	CheckBox check_Calculation_ZeroTraces, help={"Remove the offset of all traces"}
	CheckBox check_Calculation_ZeroTraces, userdata(tabnum)="0"
	CheckBox check_Calculation_ZeroTraces, userdata(tabcontrol)="Settings"
	CheckBox check_Calculation_ZeroTraces, userdata(ResizeControlsInfo)=A"!!,G5!!#AW!!#?Q!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_Calculation_ZeroTraces, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_Calculation_ZeroTraces, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_Calculation_ZeroTraces, value=0
	CheckBox check_Calculation_AverageTraces, pos={62.00, 199.00}, size={95.00, 15.00}, proc=BSP_CheckProc_ChangedSetting
	CheckBox check_Calculation_AverageTraces, title="Average Traces"
	CheckBox check_Calculation_AverageTraces, help={"Average all traces which belong to the same y axis"}
	CheckBox check_Calculation_AverageTraces, userdata(tabnum)="0"
	CheckBox check_Calculation_AverageTraces, userdata(tabcontrol)="Settings"
	CheckBox check_Calculation_AverageTraces, userdata(ResizeControlsInfo)=A"!!,E2!!#AV!!#@\"!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_Calculation_AverageTraces, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_Calculation_AverageTraces, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_Calculation_AverageTraces, value=0
	CheckBox check_BrowserSettings_TA, pos={176.00, 111.00}, size={51.00, 15.00}, proc=BSP_TimeAlignmentProc
	CheckBox check_BrowserSettings_TA, title="enable"
	CheckBox check_BrowserSettings_TA, help={"Activate time alignment"}
	CheckBox check_BrowserSettings_TA, userdata(tabnum)="0"
	CheckBox check_BrowserSettings_TA, userdata(tabcontrol)="Settings"
	CheckBox check_BrowserSettings_TA, userdata(ResizeControlsInfo)=A"!!,G@!!#@B!!#>Z!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_BrowserSettings_TA, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_BrowserSettings_TA, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_BrowserSettings_TA, userdata(Config_RestorePriority)="10", value=0
	CheckBox check_ovs_clear_on_new_ra_cycle, pos={257.00, 161.00}, size={111.00, 15.00}, disable=3
	CheckBox check_ovs_clear_on_new_ra_cycle, title="Clear on new RAC"
	CheckBox check_ovs_clear_on_new_ra_cycle, help={"Clear the list of overlayed sweeps when a new repeated acquisition cycle has begun."}
	CheckBox check_ovs_clear_on_new_ra_cycle, userdata(tabnum)="1"
	CheckBox check_ovs_clear_on_new_ra_cycle, userdata(tabcontrol)="Settings"
	CheckBox check_ovs_clear_on_new_ra_cycle, userdata(ResizeControlsInfo)=A"!!,H;J,hq[!!#@B!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_ovs_clear_on_new_ra_cycle, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_ovs_clear_on_new_ra_cycle, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_ovs_clear_on_new_ra_cycle, value=0
	CheckBox check_ovs_clear_on_new_stimset_cycle, pos={257.00, 181.00}, size={105.00, 15.00}, disable=3
	CheckBox check_ovs_clear_on_new_stimset_cycle, title="Clear on new SCI"
	CheckBox check_ovs_clear_on_new_stimset_cycle, help={"Clear the list of overlayed sweeps when a new simset cycle has begun."}
	CheckBox check_ovs_clear_on_new_stimset_cycle, userdata(tabnum)="1"
	CheckBox check_ovs_clear_on_new_stimset_cycle, userdata(tabcontrol)="Settings"
	CheckBox check_ovs_clear_on_new_stimset_cycle, userdata(ResizeControlsInfo)=A"!!,H;J,hqo!!#@6!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_ovs_clear_on_new_stimset_cycle, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_ovs_clear_on_new_stimset_cycle, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_ovs_clear_on_new_stimset_cycle, value=0
	PopupMenu popup_TimeAlignment_Mode, pos={53.00, 135.00}, size={143.00, 19.00}, bodyWidth=50, disable=2, proc=BSP_TimeAlignmentPopup
	PopupMenu popup_TimeAlignment_Mode, title="Alignment Mode"
	PopupMenu popup_TimeAlignment_Mode, help={"Select the alignment mode"}
	PopupMenu popup_TimeAlignment_Mode, userdata(tabnum)="0"
	PopupMenu popup_TimeAlignment_Mode, userdata(tabcontrol)="Settings"
	PopupMenu popup_TimeAlignment_Mode, userdata(ResizeControlsInfo)=A"!!,Dc!!#@k!!#@s!!#<Pz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	PopupMenu popup_TimeAlignment_Mode, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu popup_TimeAlignment_Mode, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu popup_TimeAlignment_Mode, userdata(Config_RestorePriority)="20"
	PopupMenu popup_TimeAlignment_Mode, mode=1, popvalue="Level (Raising)", value=#"\"Level (Raising);Level (Falling);Min;Max\""
	SetVariable setvar_TimeAlignment_LevelCross, pos={209.00, 135.00}, size={48.00, 18.00}, disable=2, proc=BSP_TimeAlignmentLevel
	SetVariable setvar_TimeAlignment_LevelCross, title="Level"
	SetVariable setvar_TimeAlignment_LevelCross, help={"Select the level (for rising and falling alignment mode) at which traces are aligned"}
	SetVariable setvar_TimeAlignment_LevelCross, userdata(tabnum)="0"
	SetVariable setvar_TimeAlignment_LevelCross, userdata(tabcontrol)="Settings"
	SetVariable setvar_TimeAlignment_LevelCross, userdata(ResizeControlsInfo)=A"!!,Ga!!#@k!!#>N!!#<Hz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	SetVariable setvar_TimeAlignment_LevelCross, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_TimeAlignment_LevelCross, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_TimeAlignment_LevelCross, userdata(Config_RestorePriority)="20"
	SetVariable setvar_TimeAlignment_LevelCross, limits={-Inf, Inf, 0}, value=_NUM:0
	Button button_TimeAlignment_Action, pos={230.00, 159.00}, size={30.00, 18.00}, disable=2, proc=BSP_DoTimeAlignment
	Button button_TimeAlignment_Action, title="Do!"
	Button button_TimeAlignment_Action, help={"Perform the time alignment, needs the cursors A and B to have a selected feature"}
	Button button_TimeAlignment_Action, userdata(tabnum)="0"
	Button button_TimeAlignment_Action, userdata(tabcontrol)="Settings"
	Button button_TimeAlignment_Action, userdata(ResizeControlsInfo)=A"!!,H!!!#A.!!#=S!!#<Hz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	Button button_TimeAlignment_Action, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button button_TimeAlignment_Action, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	Button button_TimeAlignment_Action, userdata(Config_RestorePriority)="20"
	CheckBox check_Display_VisibleXrange, pos={62.00, 270.00}, size={41.00, 15.00}, proc=BSP_CheckProc_ChangedSetting
	CheckBox check_Display_VisibleXrange, title="Vis X"
	CheckBox check_Display_VisibleXrange, help={"Scale the y axis to the visible x data range"}
	CheckBox check_Display_VisibleXrange, userdata(tabnum)="0"
	CheckBox check_Display_VisibleXrange, userdata(tabcontrol)="Settings"
	CheckBox check_Display_VisibleXrange, userdata(ResizeControlsInfo)=A"!!,E2!!#BA!!#>2!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_Display_VisibleXrange, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_Display_VisibleXrange, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_Display_VisibleXrange, value=0
	CheckBox check_Display_EqualYrange, pos={116.00, 270.00}, size={55.00, 15.00}, proc=BSP_CheckProc_ScaleAxes
	CheckBox check_Display_EqualYrange, title="Equal Y"
	CheckBox check_Display_EqualYrange, help={"Equalize the vertical axes ranges"}
	CheckBox check_Display_EqualYrange, userdata(tabnum)="0"
	CheckBox check_Display_EqualYrange, userdata(tabcontrol)="Settings"
	CheckBox check_Display_EqualYrange, userdata(ResizeControlsInfo)=A"!!,FM!!#BA!!#>j!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_Display_EqualYrange, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_Display_EqualYrange, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_Display_EqualYrange, value=0
	CheckBox check_Display_EqualYignore, pos={176.00, 270.00}, size={84.00, 15.00}, proc=BSP_CheckProc_ScaleAxes
	CheckBox check_Display_EqualYignore, title="Ignore traces"
	CheckBox check_Display_EqualYignore, help={"Equalize the vertical axes ranges but ignore all traces with level crossings"}
	CheckBox check_Display_EqualYignore, userdata(tabnum)="0"
	CheckBox check_Display_EqualYignore, userdata(tabcontrol)="Settings"
	CheckBox check_Display_EqualYignore, userdata(ResizeControlsInfo)=A"!!,G@!!#BA!!#?a!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_Display_EqualYignore, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_Display_EqualYignore, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_Display_EqualYignore, value=0
	SetVariable setvar_Display_EqualYlevel, pos={265.00, 269.00}, size={24.00, 18.00}, disable=2, proc=BSP_AxisScalingLevelCross
	SetVariable setvar_Display_EqualYlevel, help={"Crossing level value for 'Equal Y ign.\""}
	SetVariable setvar_Display_EqualYlevel, userdata(tabnum)="0"
	SetVariable setvar_Display_EqualYlevel, userdata(tabcontrol)="Settings"
	SetVariable setvar_Display_EqualYlevel, userdata(ResizeControlsInfo)=A"!!,H?J,hrkJ,hmN!!#<Hz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	SetVariable setvar_Display_EqualYlevel, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_Display_EqualYlevel, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_Display_EqualYlevel, limits={-Inf, Inf, 0}, value=_NUM:0
	PopupMenu popup_TimeAlignment_Master, pos={66.00, 159.00}, size={134.00, 19.00}, bodyWidth=50, disable=2, proc=BSP_TimeAlignmentPopup
	PopupMenu popup_TimeAlignment_Master, title="Reference trace"
	PopupMenu popup_TimeAlignment_Master, help={"Select the reference trace to which all other traces should be aligned to"}
	PopupMenu popup_TimeAlignment_Master, userdata(tabnum)="0"
	PopupMenu popup_TimeAlignment_Master, userdata(tabcontrol)="Settings"
	PopupMenu popup_TimeAlignment_Master, userdata(ResizeControlsInfo)=A"!!,E>!!#A.!!#@j!!#<Pz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	PopupMenu popup_TimeAlignment_Master, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu popup_TimeAlignment_Master, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu popup_TimeAlignment_Master, userdata(Config_RestorePriority)="20"
	PopupMenu popup_TimeAlignment_Master, mode=1, popvalue="AD0", value=#"\"\""
	Button button_Calculation_RestoreData, pos={253.00, 208.00}, size={75.00, 24.00}, proc=BSP_ButtonProc_RestoreData
	Button button_Calculation_RestoreData, title="Restore"
	Button button_Calculation_RestoreData, help={"Restore the data in its pristine state without any modifications"}
	Button button_Calculation_RestoreData, userdata(tabnum)="0"
	Button button_Calculation_RestoreData, userdata(tabcontrol)="Settings"
	Button button_Calculation_RestoreData, userdata(ResizeControlsInfo)=A"!!,H8!!#A_!!#?O!!#=#z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	Button button_Calculation_RestoreData, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button button_Calculation_RestoreData, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	Button button_BrowserSettings_Export, pos={112.00, 327.00}, size={99.00, 24.00}, proc=SB_ButtonProc_ExportTraces
	Button button_BrowserSettings_Export, title="Export Traces"
	Button button_BrowserSettings_Export, help={"Export the traces for further processing"}
	Button button_BrowserSettings_Export, userdata(tabnum)="0"
	Button button_BrowserSettings_Export, userdata(tabcontrol)="Settings"
	Button button_BrowserSettings_Export, userdata(ResizeControlsInfo)=A"!!,FE!!#B]J,hpU!!#=#z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	Button button_BrowserSettings_Export, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	Button button_BrowserSettings_Export, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox check_SweepControl_HideSweep, pos={61.00, 219.00}, size={113.00, 15.00}, proc=BSP_CheckProc_ChangedSetting
	CheckBox check_SweepControl_HideSweep, title="Hide sweep Traces"
	CheckBox check_SweepControl_HideSweep, help={"Hide sweep traces. Usually combined with \"Average traces\"."}
	CheckBox check_SweepControl_HideSweep, userdata(tabnum)="0"
	CheckBox check_SweepControl_HideSweep, userdata(tabcontrol)="Settings"
	CheckBox check_SweepControl_HideSweep, userdata(ResizeControlsInfo)=A"!!,E.!!#Aj!!#@F!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_SweepControl_HideSweep, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_SweepControl_HideSweep, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_SweepControl_HideSweep, value=0
	CheckBox check_BrowserSettings_splitTTL, pos={170.00, 56.00}, size={60.00, 15.00}, disable=2, proc=BSP_CheckProc_ChangedSetting
	CheckBox check_BrowserSettings_splitTTL, title="sep. TTL"
	CheckBox check_BrowserSettings_splitTTL, help={"Display the TTL channel data as single traces for each TTL bit (ITC hardware only, for other hardware types this is always the case regardless of this checkbox)"}
	CheckBox check_BrowserSettings_splitTTL, userdata(tabnum)="0"
	CheckBox check_BrowserSettings_splitTTL, userdata(tabcontrol)="Settings"
	CheckBox check_BrowserSettings_splitTTL, userdata(ResizeControlsInfo)=A"!!,G:!!#>n!!#?)!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_BrowserSettings_splitTTL, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_BrowserSettings_splitTTL, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_BrowserSettings_splitTTL, userdata(Config_RestorePriority)="20"
	CheckBox check_BrowserSettings_splitTTL, value=1
	PopupMenu popup_DB_lockedDevices, pos={54.00, 301.00}, size={205.00, 19.00}, bodyWidth=100, proc=DB_PopMenuProc_LockDBtoDevice
	PopupMenu popup_DB_lockedDevices, title="Device assignment:"
	PopupMenu popup_DB_lockedDevices, help={"Select a data acquistion device to display data"}
	PopupMenu popup_DB_lockedDevices, userdata(tabnum)="0"
	PopupMenu popup_DB_lockedDevices, userdata(tabcontrol)="Settings"
	PopupMenu popup_DB_lockedDevices, userdata(Config_RestorePriority)="0"
	PopupMenu popup_DB_lockedDevices, userdata(ResizeControlsInfo)=A"!!,Dg!!#BPJ,hr2!!#<Pz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	PopupMenu popup_DB_lockedDevices, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu popup_DB_lockedDevices, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu popup_DB_lockedDevices, mode=1, popvalue="- none -", value=#"DB_GetAllDevicesWithData()"
	GroupBox group_enable_sweepFormula, pos={5.00, 25.00}, size={434.00, 50.00}, disable=1
	GroupBox group_enable_sweepFormula, title="SweepFormula", userdata(tabnum)="5"
	GroupBox group_enable_sweepFormula, userdata(tabcontrol)="Settings"
	GroupBox group_enable_sweepFormula, userdata(ResizeControlsInfo)=A"!!,?X!!#=+!!#C>!!#>Vz!!#](Aon#azzzzzzzzzzzzzz!!#o2B4uAeBk2=!z"
	GroupBox group_enable_sweepFormula, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#N3Bk1ctAStpcCh5qOGZ8U#zzzzzzzz"
	GroupBox group_enable_sweepFormula, userdata(ResizeControlsInfo)+=A"zzz!!#N3Bk1ctAStpcCh5qOGX?=jFDl!rzzzzzzzzzz!!!"
	Button button_sweepFormula_display, pos={9.00, 468.00}, size={51.00, 22.00}, disable=3, proc=SF_button_sweepFormula_display
	Button button_sweepFormula_display, title="Display"
	Button button_sweepFormula_display, help={"Display the given sweep formula in a graph"}
	Button button_sweepFormula_display, userdata(tabnum)="5"
	Button button_sweepFormula_display, userdata(tabcontrol)="Settings"
	Button button_sweepFormula_display, userdata(ResizeControlsInfo)=A"!!,@s!!#CO!!#>Z!!#<hz!!#](Aon#azzzzzzzzzzzzzz!!#](Aon#SBk2=!z"
	Button button_sweepFormula_display, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#?(FEDG<zzzzzzzzzzz"
	Button button_sweepFormula_display, userdata(ResizeControlsInfo)+=A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	Button button_sweepFormula_check, pos={65.00, 468.00}, size={46.00, 22.00}, disable=3, proc=SF_button_sweepFormula_check
	Button button_sweepFormula_check, title="Check"
	Button button_sweepFormula_check, help={"Check the sweep formula for syntax errors"}
	Button button_sweepFormula_check, userdata(tabnum)="5"
	Button button_sweepFormula_check, userdata(tabcontrol)="Settings"
	Button button_sweepFormula_check, userdata(ResizeControlsInfo)=A"!!,E<!!#CO!!#>F!!#<hz!!#](Aon#azzzzzzzzzzzzzz!!#](Aon#SBk2=!z"
	Button button_sweepFormula_check, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#?(FEDG<zzzzzzzzzzz"
	Button button_sweepFormula_check, userdata(ResizeControlsInfo)+=A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	TabControl SF_InfoTab, pos={8.00, 90.00}, size={424.00, 380.00}, disable=1, proc=ACL_DisplayTab
	TabControl SF_InfoTab, help={"Choose between sweep formula input, JSON representation and the help notebook"}
	TabControl SF_InfoTab, userdata(finalhook)="SF_TabProc_Formula"
	TabControl SF_InfoTab, userdata(currenttab)="0", userdata(tabnum)="5"
	TabControl SF_InfoTab, userdata(tabcontrol)="Settings"
	TabControl SF_InfoTab, userdata(ResizeControlsInfo)=A"!!,@c!!#?m!!#C9!!#C#z!!#](Aon#azzzzzzzzzzzzzz!!#o2B4uAeBk2=!z"
	TabControl SF_InfoTab, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	TabControl SF_InfoTab, userdata(ResizeControlsInfo)+=A"zzz!!#N3Bk1ct<C^(Vzzzzzzzzzzzzz!!!"
	TabControl SF_InfoTab, userdata(Config_DontRestore)="1"
	TabControl SF_InfoTab, userdata(Config_DontSave)="1", tabLabel(0)="Formula"
	TabControl SF_InfoTab, tabLabel(1)="JSON", tabLabel(2)="Help", value=0
	ListBox list_dashboard, pos={5.00, 90.00}, size={434.00, 404.00}, disable=1, proc=AD_ListBoxProc
	ListBox list_dashboard, help={"Show the triplett of stimulus set, analysis function and result for supported analysis functions."}
	ListBox list_dashboard, userdata(tabnum)="7", userdata(tabcontrol)="Settings"
	ListBox list_dashboard, userdata(ResizeControlsInfo)=A"!!,?X!!#?m!!#C>!!#C/z!!#](Aon\"Qzzzzzzzzzzzzzz!!#o2B4uAezz"
	ListBox list_dashboard, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	ListBox list_dashboard, userdata(ResizeControlsInfo)+=A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	ListBox list_dashboard, userdata(Config_DontRestore)="1"
	ListBox list_dashboard, userdata(Config_DontSave)="1", fSize=12, mode=9
	ListBox list_dashboard, widths={141, 109, 77}, userColumnResize=1
	CheckBox check_BrowserSettings_DS, pos={186.00, 47.00}, size={51.00, 15.00}, disable=1, proc=AD_CheckProc_Toggle
	CheckBox check_BrowserSettings_DS, title="enable"
	CheckBox check_BrowserSettings_DS, help={"Enable the dashboard support"}
	CheckBox check_BrowserSettings_DS, userdata(tabnum)="7"
	CheckBox check_BrowserSettings_DS, userdata(tabcontrol)="Settings"
	CheckBox check_BrowserSettings_DS, userdata(ResizeControlsInfo)=A"!!,GJ!!#>J!!#>Z!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_BrowserSettings_DS, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#N3Bk1ctAStpcCh5qOGZ8U#zzzzzzzz"
	CheckBox check_BrowserSettings_DS, userdata(ResizeControlsInfo)+=A"zzz!!#N3Bk1ctAStpcCh5qOGX?=jFDl!rzzzzzzzzzz!!!"
	CheckBox check_BrowserSettings_DS, value=0
	GroupBox group_enable_dashboard, pos={5.00, 25.00}, size={434.00, 60.00}, disable=1
	GroupBox group_enable_dashboard, userdata(tabnum)="7"
	GroupBox group_enable_dashboard, userdata(tabcontrol)="Settings"
	GroupBox group_enable_dashboard, userdata(ResizeControlsInfo)=A"!!,?X!!#=+!!#C>!!#?)z!!#](Aon\"Qzzzzzzzzzzzzzz!!#o2B4uAezz"
	GroupBox group_enable_dashboard, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	GroupBox group_enable_dashboard, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_BrowserSettings_DB_Passed, pos={37.00, 35.00}, size={52.00, 15.00}, disable=3, proc=AD_CheckProc_PassedSweeps
	CheckBox check_BrowserSettings_DB_Passed, title="Passed"
	CheckBox check_BrowserSettings_DB_Passed, help={"Show passed sweeps for selection"}
	CheckBox check_BrowserSettings_DB_Passed, userdata(tabnum)="7"
	CheckBox check_BrowserSettings_DB_Passed, userdata(tabcontrol)="Settings"
	CheckBox check_BrowserSettings_DB_Passed, userdata(ResizeControlsInfo)=A"!!,D#!!#=o!!#>^!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_BrowserSettings_DB_Passed, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_BrowserSettings_DB_Passed, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_BrowserSettings_DB_Passed, value=1
	CheckBox check_BrowserSettings_DB_Failed, pos={37.00, 56.00}, size={47.00, 15.00}, disable=3, proc=AD_CheckProc_FailedSweeps
	CheckBox check_BrowserSettings_DB_Failed, title="Failed"
	CheckBox check_BrowserSettings_DB_Failed, help={"Show failed sweeps for selection"}
	CheckBox check_BrowserSettings_DB_Failed, userdata(tabnum)="7"
	CheckBox check_BrowserSettings_DB_Failed, userdata(tabcontrol)="Settings"
	CheckBox check_BrowserSettings_DB_Failed, userdata(ResizeControlsInfo)=A"!!,D#!!#>n!!#>J!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_BrowserSettings_DB_Failed, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_BrowserSettings_DB_Failed, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_BrowserSettings_DB_Failed, value=0
	CheckBox check_BrowserSettings_SF, pos={186.00, 47.00}, size={51.00, 15.00}, disable=1, proc=BSP_CheckBoxProc_SweepFormula
	CheckBox check_BrowserSettings_SF, title="enable"
	CheckBox check_BrowserSettings_SF, help={"Enable the sweep formula support"}
	CheckBox check_BrowserSettings_SF, userdata(tabnum)="5"
	CheckBox check_BrowserSettings_SF, userdata(tabcontrol)="Settings"
	CheckBox check_BrowserSettings_SF, userdata(ResizeControlsInfo)=A"!!,GJ!!#>J!!#>Z!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_BrowserSettings_SF, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#N3Bk1ctAStpcCh5qOGZ8U#zzzzzzzz"
	CheckBox check_BrowserSettings_SF, userdata(ResizeControlsInfo)+=A"zzz!!#N3Bk1ctAStpcCh5qOGX?=jFDl!rzzzzzzzzzz!!!"
	CheckBox check_BrowserSettings_SF, value=0
	CheckBox check_channelSel_HEADSTAGE_ALL, pos={79.00, 225.00}, size={30.00, 15.00}, disable=1, proc=BSP_CheckProc_ChangedSetting
	CheckBox check_channelSel_HEADSTAGE_ALL, title="All"
	CheckBox check_channelSel_HEADSTAGE_ALL, help={"Toggle the display of all headstages"}
	CheckBox check_channelSel_HEADSTAGE_ALL, userdata(tabcontrol)="Settings"
	CheckBox check_channelSel_HEADSTAGE_ALL, userdata(tabnum)="2"
	CheckBox check_channelSel_HEADSTAGE_ALL, userdata(ResizeControlsInfo)=A"!!,EX!!#Ap!!#=S!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_HEADSTAGE_ALL, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:DuaGlAStpcCh5qOGZ8U#zzzzzzzz"
	CheckBox check_channelSel_HEADSTAGE_ALL, userdata(ResizeControlsInfo)+=A"zzz!!#u:DuaGlAStpcCh5qOGX?=jFDl!rzzzzzzzzzz!!!"
	CheckBox check_channelSel_HEADSTAGE_ALL, value=0
	CheckBox check_channelSel_DA_All, pos={143.00, 225.00}, size={30.00, 15.00}, disable=1, proc=BSP_CheckProc_ChangedSetting
	CheckBox check_channelSel_DA_All, title="All"
	CheckBox check_channelSel_DA_All, help={"Toggle the display of all DA channels"}
	CheckBox check_channelSel_DA_All, userdata(tabcontrol)="Settings"
	CheckBox check_channelSel_DA_All, userdata(tabnum)="2"
	CheckBox check_channelSel_DA_All, userdata(ResizeControlsInfo)=A"!!,Ft!!#Ap!!#=S!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_DA_All, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:DuaGlAStpcCh5qOGZ8U#zzzzzzzz"
	CheckBox check_channelSel_DA_All, userdata(ResizeControlsInfo)+=A"zzz!!#u:DuaGlAStpcCh5qOGX?=jFDl!rzzzzzzzzzz!!!"
	CheckBox check_channelSel_DA_All, value=0
	CheckBox check_channelSel_AD_All, pos={210.00, 225.00}, size={30.00, 15.00}, disable=1, proc=BSP_CheckProc_ChangedSetting
	CheckBox check_channelSel_AD_All, title="All"
	CheckBox check_channelSel_AD_All, help={"Toggle the display of all AD channels"}
	CheckBox check_channelSel_AD_All, userdata(tabcontrol)="Settings"
	CheckBox check_channelSel_AD_All, userdata(tabnum)="2"
	CheckBox check_channelSel_AD_All, userdata(ResizeControlsInfo)=A"!!,Gb!!#Ap!!#=S!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_channelSel_AD_All, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:DuaGlAStpcCh5qOGZ8U#zzzzzzzz"
	CheckBox check_channelSel_AD_All, userdata(ResizeControlsInfo)+=A"zzz!!#u:DuaGlAStpcCh5qOGX?=jFDl!rzzzzzzzzzz!!!"
	CheckBox check_channelSel_AD_All, value=0
	CheckBox check_pulseAver_searchFailedPulses, pos={236.00, 340.00}, size={119.00, 15.00}, disable=1, proc=PA_CheckProc_Common
	CheckBox check_pulseAver_searchFailedPulses, title="Search failed pulses"
	CheckBox check_pulseAver_searchFailedPulses, help={"Failed pulses don't have a signal above the given level in the diagonal elements"}
	CheckBox check_pulseAver_searchFailedPulses, userdata(tabnum)="4"
	CheckBox check_pulseAver_searchFailedPulses, userdata(tabcontrol)="Settings"
	CheckBox check_pulseAver_searchFailedPulses, userdata(ResizeControlsInfo)=A"!!,H'!!#Bd!!#@R!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_pulseAver_searchFailedPulses, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_pulseAver_searchFailedPulses, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_pulseAver_searchFailedPulses, value=0
	CheckBox check_pulseAver_hideFailedPulses, pos={236.00, 361.00}, size={109.00, 15.00}, disable=1, proc=PA_CheckProc_Common
	CheckBox check_pulseAver_hideFailedPulses, title="Hide failed pulses"
	CheckBox check_pulseAver_hideFailedPulses, help={"Hide the failed pulses"}
	CheckBox check_pulseAver_hideFailedPulses, userdata(tabnum)="4"
	CheckBox check_pulseAver_hideFailedPulses, userdata(tabcontrol)="Settings"
	CheckBox check_pulseAver_hideFailedPulses, userdata(ResizeControlsInfo)=A"!!,H'!!#BnJ,hpi!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_pulseAver_hideFailedPulses, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_pulseAver_hideFailedPulses, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_pulseAver_hideFailedPulses, value=0
	SetVariable setvar_pulseAver_failedPulses_level, pos={236.00, 383.00}, size={81.00, 18.00}, bodyWidth=50, disable=1, proc=PA_SetVarProc_Common
	SetVariable setvar_pulseAver_failedPulses_level, title="Level"
	SetVariable setvar_pulseAver_failedPulses_level, help={"Signal level for failed pulses search, every pulse not reaching that level is considered as failed."}
	SetVariable setvar_pulseAver_failedPulses_level, userdata(tabnum)="4"
	SetVariable setvar_pulseAver_failedPulses_level, userdata(tabcontrol)="Settings"
	SetVariable setvar_pulseAver_failedPulses_level, userdata(ResizeControlsInfo)=A"!!,H'!!#C$J,hp1!!#<Hz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	SetVariable setvar_pulseAver_failedPulses_level, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_pulseAver_failedPulses_level, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_pulseAver_failedPulses_level, limits={-Inf, Inf, 0}, value=_NUM:0
	SetVariable setvar_pulseAver_vert_scale_bar, pos={67.00, 129.00}, size={142.00, 18.00}, bodyWidth=50, disable=1, proc=PA_SetVarProc_Common
	SetVariable setvar_pulseAver_vert_scale_bar, title="Vertical scale bar"
	SetVariable setvar_pulseAver_vert_scale_bar, help={"Length of the vertical scale bar in data units."}
	SetVariable setvar_pulseAver_vert_scale_bar, userdata(tabnum)="4"
	SetVariable setvar_pulseAver_vert_scale_bar, userdata(tabcontrol)="Settings"
	SetVariable setvar_pulseAver_vert_scale_bar, userdata(ResizeControlsInfo)=A"!!,E@!!#@e!!#@r!!#<Hz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	SetVariable setvar_pulseAver_vert_scale_bar, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_pulseAver_vert_scale_bar, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_pulseAver_vert_scale_bar, value=_NUM:1
	CheckBox check_pulseAver_ShowImage, pos={74.00, 225.00}, size={111.00, 15.00}, disable=1, proc=PA_CheckProc_Common
	CheckBox check_pulseAver_ShowImage, title="Enable image plot"
	CheckBox check_pulseAver_ShowImage, help={"Enable the image plot which is *much* faster than the trace plot"}
	CheckBox check_pulseAver_ShowImage, userdata(tabnum)="4"
	CheckBox check_pulseAver_ShowImage, userdata(tabcontrol)="Settings"
	CheckBox check_pulseAver_ShowImage, userdata(ResizeControlsInfo)=A"!!,EN!!#Ap!!#@B!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_pulseAver_ShowImage, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_pulseAver_ShowImage, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_pulseAver_ShowImage, value=0
	GroupBox group_pulseAver_general, pos={221.00, 89.00}, size={175.00, 350.00}, disable=3
	GroupBox group_pulseAver_general, title="General", userdata(tabnum)="4"
	GroupBox group_pulseAver_general, userdata(tabcontrol)="Settings"
	GroupBox group_pulseAver_general, userdata(ResizeControlsInfo)=A"!!,Gm!!#?k!!#A>!!#Biz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	GroupBox group_pulseAver_general, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	GroupBox group_pulseAver_general, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	GroupBox group_pulseAver_trace_settings, pos={61.00, 90.00}, size={155.00, 96.00}, disable=3
	GroupBox group_pulseAver_trace_settings, title="Trace settings"
	GroupBox group_pulseAver_trace_settings, userdata(tabnum)="4"
	GroupBox group_pulseAver_trace_settings, userdata(tabcontrol)="Settings"
	GroupBox group_pulseAver_trace_settings, userdata(ResizeControlsInfo)=A"!!,E.!!#?m!!#A*!!#@$z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	GroupBox group_pulseAver_trace_settings, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	GroupBox group_pulseAver_trace_settings, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	GroupBox group_pulseAver_image_settings, pos={61.00, 186.00}, size={154.00, 131.00}, disable=3
	GroupBox group_pulseAver_image_settings, title="Image settings"
	GroupBox group_pulseAver_image_settings, userdata(tabnum)="4"
	GroupBox group_pulseAver_image_settings, userdata(tabcontrol)="Settings"
	GroupBox group_pulseAver_image_settings, userdata(ResizeControlsInfo)=A"!!,E.!!#AI!!#A)!!#@gz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	GroupBox group_pulseAver_image_settings, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	GroupBox group_pulseAver_image_settings, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_pulseAver_showTraces, pos={70.00, 109.00}, size={104.00, 15.00}, disable=1, proc=PA_CheckProc_Common
	CheckBox check_pulseAver_showTraces, title="Enable trace plot"
	CheckBox check_pulseAver_showTraces, help={"Enable the trace plot"}
	CheckBox check_pulseAver_showTraces, userdata(tabnum)="4"
	CheckBox check_pulseAver_showTraces, userdata(tabcontrol)="Settings"
	CheckBox check_pulseAver_showTraces, userdata(ResizeControlsInfo)=A"!!,EF!!#@>!!#@4!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_pulseAver_showTraces, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_pulseAver_showTraces, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_pulseAver_showTraces, value=1
	PopupMenu popup_pulseAver_colorscales, pos={68.00, 244.00}, size={140.00, 19.00}, bodyWidth=140, disable=1, proc=PA_PopMenuProc_ColorScale
	PopupMenu popup_pulseAver_colorscales, help={"Select the color scale used for the image display"}
	PopupMenu popup_pulseAver_colorscales, userdata(ResizeControlsInfo)=A"!!,EB!!#B.!!#@p!!#<Pz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	PopupMenu popup_pulseAver_colorscales, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu popup_pulseAver_colorscales, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu popup_pulseAver_colorscales, userdata(tabnum)="4"
	PopupMenu popup_pulseAver_colorscales, userdata(tabcontrol)="Settings"
	PopupMenu popup_pulseAver_colorscales, mode=8, value=#"\"*COLORTABLEPOP*\""
	CheckBox check_pulseAver_drawXZeroLine, pos={235.00, 202.00}, size={100.00, 15.00}, disable=1, proc=PA_CheckProc_Common
	CheckBox check_pulseAver_drawXZeroLine, title="Draw X zero line"
	CheckBox check_pulseAver_drawXZeroLine, help={"Draw a vertical line at the X=0 crossing (only available with time alignment)"}
	CheckBox check_pulseAver_drawXZeroLine, userdata(tabnum)="4"
	CheckBox check_pulseAver_drawXZeroLine, userdata(tabcontrol)="Settings"
	CheckBox check_pulseAver_drawXZeroLine, userdata(ResizeControlsInfo)=A"!!,H&!!#AY!!#@,!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_pulseAver_drawXZeroLine, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_pulseAver_drawXZeroLine, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_pulseAver_drawXZeroLine, value=0
	CheckBox check_pulseAver_fixedPulseLength, pos={239.00, 277.00}, size={112.00, 15.00}, disable=1, proc=PA_CheckProc_Common
	CheckBox check_pulseAver_fixedPulseLength, title="Fixed pulse length"
	CheckBox check_pulseAver_fixedPulseLength, help={"Use the fixed pulse length instead of the computed one"}
	CheckBox check_pulseAver_fixedPulseLength, userdata(tabnum)="4"
	CheckBox check_pulseAver_fixedPulseLength, userdata(tabcontrol)="Settings"
	CheckBox check_pulseAver_fixedPulseLength, userdata(ResizeControlsInfo)=A"!!,H*!!#BDJ,hpo!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_pulseAver_fixedPulseLength, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_pulseAver_fixedPulseLength, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_pulseAver_fixedPulseLength, value=0
	PopupMenu popup_pulseAver_pulseSortOrder, pos={70.00, 266.00}, size={137.00, 19.00}, bodyWidth=82, disable=1, proc=PA_PopMenuProc_Common
	PopupMenu popup_pulseAver_pulseSortOrder, title="Sort order"
	PopupMenu popup_pulseAver_pulseSortOrder, help={"Sorting order for the pulses"}
	PopupMenu popup_pulseAver_pulseSortOrder, userdata(ResizeControlsInfo)=A"!!,EF!!#B?!!#@m!!#<Pz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	PopupMenu popup_pulseAver_pulseSortOrder, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu popup_pulseAver_pulseSortOrder, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu popup_pulseAver_pulseSortOrder, userdata(tabnum)="4"
	PopupMenu popup_pulseAver_pulseSortOrder, userdata(tabcontrol)="Settings"
	PopupMenu popup_pulseAver_pulseSortOrder, mode=1, popvalue="Sweep", value=#"\"Sweep;PulseIndex\""
	GroupBox group_pulseAver_failedPulses, pos={228.00, 324.00}, size={157.00, 111.00}, disable=3
	GroupBox group_pulseAver_failedPulses, title="Failed Pulses", userdata(tabnum)="4"
	GroupBox group_pulseAver_failedPulses, userdata(tabcontrol)="Settings"
	GroupBox group_pulseAver_failedPulses, userdata(ResizeControlsInfo)=A"!!,Gt!!#B\\!!#A,!!#@Bz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	GroupBox group_pulseAver_failedPulses, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	GroupBox group_pulseAver_failedPulses, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	GroupBox group_pulseAver_singlePulse, pos={227.00, 216.00}, size={158.00, 107.00}, disable=3
	GroupBox group_pulseAver_singlePulse, title=" Pulses", userdata(tabnum)="4"
	GroupBox group_pulseAver_singlePulse, userdata(tabcontrol)="Settings"
	GroupBox group_pulseAver_singlePulse, userdata(ResizeControlsInfo)=A"!!,Gs!!#Ag!!#A-!!#@:z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	GroupBox group_pulseAver_singlePulse, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	GroupBox group_pulseAver_singlePulse, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_pulseAver_numberOfSpikes, pos={233.00, 407.00}, size={148.00, 18.00}, bodyWidth=50, disable=1, proc=PA_SetVarProc_Common
	SetVariable setvar_pulseAver_numberOfSpikes, title="Number of Spikes"
	SetVariable setvar_pulseAver_numberOfSpikes, help={"Number of expected spikes, a pulse can only pass if it has exactly these many spikes. A value of \"NaN\" means the number of spikes is ignored."}
	SetVariable setvar_pulseAver_numberOfSpikes, userdata(tabnum)="4"
	SetVariable setvar_pulseAver_numberOfSpikes, userdata(tabcontrol)="Settings"
	SetVariable setvar_pulseAver_numberOfSpikes, userdata(ResizeControlsInfo)=A"!!,H$!!#C0J,hqN!!#<Hz!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	SetVariable setvar_pulseAver_numberOfSpikes, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_pulseAver_numberOfSpikes, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_pulseAver_numberOfSpikes, limits={1, Inf, 1}, value=_NUM:NaN
	CheckBox check_BrowserSettings_VisEpochs, pos={59.00, 56.00}, size={102.00, 15.00}, proc=BSP_CheckProc_ChangedSetting
	CheckBox check_BrowserSettings_VisEpochs, title="Visualize Epochs"
	CheckBox check_BrowserSettings_VisEpochs, help={"Visualize epoch information with additional traces (Igor Pro 9 only)."}
	CheckBox check_BrowserSettings_VisEpochs, userdata(tabnum)="0"
	CheckBox check_BrowserSettings_VisEpochs, userdata(tabcontrol)="Settings"
	CheckBox check_BrowserSettings_VisEpochs, userdata(ResizeControlsInfo)=A"!!,E&!!#>n!!#@0!!#<(z!!#`-A7TLfzzzzzzzzzzzzzz!!#r+D.OhkBk2=!z"
	CheckBox check_BrowserSettings_VisEpochs, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_BrowserSettings_VisEpochs, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_BrowserSettings_VisEpochs, userdata(Config_RestorePriority)="20"
	CheckBox check_BrowserSettings_VisEpochs, value=0
	Button button_sweepFormula_tofront, pos={115.00, 468.00}, size={51.00, 22.00}, disable=3, proc=SF_button_sweepFormula_tofront
	Button button_sweepFormula_tofront, title="To Front"
	Button button_sweepFormula_tofront, help={"Check the sweep formula for syntax errors"}
	Button button_sweepFormula_tofront, userdata(ResizeControlsInfo)=A"!!,FK!!#CO!!#>Z!!#<hz!!#](Aon#azzzzzzzzzzzzzz!!#](Aon#SBk2=!z"
	Button button_sweepFormula_tofront, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#?(FEDG<zzzzzzzzzzz"
	Button button_sweepFormula_tofront, userdata(ResizeControlsInfo)+=A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	Button button_sweepFormula_tofront, userdata(tabnum)="5"
	Button button_sweepFormula_tofront, userdata(tabcontrol)="Settings"
	Button button_sweepformula_all_code, pos={237.00, 468.00}, size={195.00, 19.00}, bodyWidth=80, disable=3, proc=PEXT_ButtonProc
	Button button_sweepformula_all_code, title="Formerly executed code ▼"
	Button button_sweepformula_all_code, help={"All formerly executed code from this session can be executed again by selecting it."}
	Button button_sweepformula_all_code, userdata(popupProc)="SF_PopMenuProc_OldCode"
	Button button_sweepformula_all_code, userdata(Items)="SF_GetAllOldCodeForGUI"
	Button button_sweepformula_all_code, userdata(tabnum)="5"
	Button button_sweepformula_all_code, userdata(tabcontrol)="Settings"
	Button button_sweepformula_all_code, userdata(ResizeControlsInfo)=A"!!,H(!!#CO!!#AR!!#<Pz!!#o2B4uAezzzzzzzzzzzzzz!!#o2B4uAeBk2=!z"
	Button button_sweepformula_all_code, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#?(FEDG<zzzzzzzzzzz"
	Button button_sweepformula_all_code, userdata(ResizeControlsInfo)+=A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	DefineGuide UGVL={FL, 15}, UGVR={FR, -20}, UGVT={FT, 113}, UGVM={FB, -120}, UGVB={FB, -35}
	DefineGuide enableBoxTop={FT, 25}, enableBoxBottom={enableBoxTop, 50}, MainBoxBottom={FB, 3}
	DefineGuide MainBoxTop={enableBoxBottom, 10}
	SetWindow kwTopWin, hook(ResizeControls)=ResizeControlsSafe
	SetWindow kwTopWin, userdata(ResizeControlsInfo)=A"!!*'\"z!!#CCJ,ht5zzzzzzzzzzzzzzzzzzzzz"
	SetWindow kwTopWin, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzzzzzzzzzzzzzzz"
	SetWindow kwTopWin, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzzzzzzzzz!!!"
	SetWindow kwTopWin, userdata(ResizeControlsGuides)="UGVL;UGVR;UGVT;UGVM;UGVB;enableBoxTop;enableBoxBottom;MainBoxBottom;MainBoxTop;"
	SetWindow kwTopWin, userdata(ResizeControlsInfoUGVL)="NAME:UGVL;WIN:DataBrowser#BrowserSettingsPanel;TYPE:User;HORIZONTAL:0;POSITION:15.00;GUIDE1:FL;GUIDE2:;RELPOSITION:15;"
	SetWindow kwTopWin, userdata(ResizeControlsInfoUGVR)="NAME:UGVR;WIN:DataBrowser#BrowserSettingsPanel;TYPE:User;HORIZONTAL:0;POSITION:425.00;GUIDE1:FR;GUIDE2:;RELPOSITION:-20;"
	SetWindow kwTopWin, userdata(ResizeControlsInfoUGVT)="NAME:UGVT;WIN:DataBrowser#BrowserSettingsPanel;TYPE:User;HORIZONTAL:1;POSITION:113.00;GUIDE1:FT;GUIDE2:;RELPOSITION:113;"
	SetWindow kwTopWin, userdata(ResizeControlsInfoUGVB)="NAME:UGVB;WIN:DataBrowser#BrowserSettingsPanel;TYPE:User;HORIZONTAL:1;POSITION:465.00;GUIDE1:FB;GUIDE2:;RELPOSITION:-35;"
	SetWindow kwTopWin, userdata(ResizeControlsInfoenableBoxTop)="NAME:enableBoxTop;WIN:DataBrowser#BrowserSettingsPanel;TYPE:User;HORIZONTAL:1;POSITION:25.00;GUIDE1:FT;GUIDE2:;RELPOSITION:25;"
	SetWindow kwTopWin, userdata(ResizeControlsInfoenableBoxBottom)="NAME:enableBoxBottom;WIN:DataBrowser#BrowserSettingsPanel;TYPE:User;HORIZONTAL:1;POSITION:75.00;GUIDE1:enableBoxTop;GUIDE2:;RELPOSITION:50;"
	SetWindow kwTopWin, userdata(ResizeControlsInfoMainBoxBottom)="NAME:MainBoxBottom;WIN:DataBrowser#BrowserSettingsPanel;TYPE:User;HORIZONTAL:1;POSITION:500.00;GUIDE1:FB;GUIDE2:;RELPOSITION:3;"
	SetWindow kwTopWin, userdata(ResizeControlsInfoMainBoxTop)="NAME:MainBoxTop;WIN:DataBrowser#BrowserSettingsPanel;TYPE:User;HORIZONTAL:1;POSITION:85.00;GUIDE1:enableBoxBottom;GUIDE2:;RELPOSITION:10;"
	SetWindow kwTopWin, userdata(ResizeControlsInfoUGVM)="NAME:UGVM;WIN:DataBrowser#BrowserSettingsPanel;TYPE:User;HORIZONTAL:1;POSITION:380.00;GUIDE1:FB;GUIDE2:;RELPOSITION:-120;"
	Execute/Q/Z "SetWindow kwTopWin sizeLimit={303,330,inf,inf}" // sizeLimit requires Igor 7 or later
	NewNotebook/F=0/N=sweepFormula_json/W=(12, 71, 378, 358)/FG=(UGVL, UGVT, UGVR, UGVB)/HOST=#/V=0/OPTS=12
	Notebook kwTopWin, defaultTab=10, autoSave=0, magnification=100, writeProtect=1
	Notebook kwTopWin, font="Lucida Console", fSize=11, fStyle=0, textRGB=(0, 0, 0)
	SetWindow kwTopWin, hook(ResizeControls)=ResizeControlsSafe
	SetWindow kwTopWin, userdata(tabnum)="1"
	SetWindow kwTopWin, userdata(tabcontrol)="SF_InfoTab"
	SetWindow kwTopWin, userdata(ResizeControlsInfo)=A"!!,@C!!#>F!!#C#!!#B[J,fQL!!#](Aon#azzzzzzzzzzzzzz!!#o2B4uAeBk2=!z"
	SetWindow kwTopWin, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetWindow kwTopWin, userdata(ResizeControlsInfo)+=A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	SetWindow kwTopWin, userdata(Config_DontRestore)="1"
	SetWindow kwTopWin, userdata(Config_DontSave)="1"
	RenameWindow #, sweepFormula_json
	SetActiveSubwindow ##
	NewNotebook/F=1/N=sweepFormula_formula/W=(12, 71, 378, 402)/FG=(UGVL, UGVT, UGVR, UGVM)/HOST=#/V=0
	Notebook kwTopWin, defaultTab=10, autoSave=1, magnification=100, showRuler=0, rulerUnits=2
	Notebook kwTopWin, newRuler=Normal, justification=0, margins={0, 0, 285}, spacing={0, 0, 0}, tabs={}, rulerDefaults={"Arial", 11, 0, (0, 0, 0)}
	Notebook kwTopWin, zdata="GaqDU%ejN7!Z)u.`Q5gp6juaSXS'k!L4Mn2Ld])[.hK#eE=!1@!9+Q_F;9m$LSP?L/Ich)!tpS$#QZ*qoV0::oMbuuKkLQ/L!73:=C)2ds$-S4r;SuLV(Ge\\EG>t[)3@Nd0$sYs@#Z'S&-Fb3J0N)QM0XBG3Q2ns/t+gDQ,VjaW<L6ZR[UktR&14B9he21!La?@'/`a>3j>Vp\"KTHf_ZH-$!G]Z>@pnfL0?R#5_&WS\"*?\\OO5Y,;bDO:b'fOUBeEYp,W3#6',/b^\\gc:gf/E6cc[cHf'nfFIs=Jm3O"
	Notebook kwTopWin, zdataEnd=1
	SetWindow kwTopWin, hook(ResizeControls)=ResizeControlsSafe
	SetWindow kwTopWin, userdata(tabnum)="0"
	SetWindow kwTopWin, userdata(tabcontrol)="SF_InfoTab"
	SetWindow kwTopWin, userdata(ResizeControlsInfo)=A"!!,@C!!#>F!!#C#!!#B[J,fQL!!#](Aon#azzzzzzzzzzzzzz!!#o2B4uAeBk2=!z"
	SetWindow kwTopWin, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetWindow kwTopWin, userdata(ResizeControlsInfo)+=A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	RenameWindow #, sweepFormula_formula
	SetActiveSubwindow ##
	NewNotebook/F=1/N=sweepFormula_error/W=(111, 125, 334, 375)/FG=(UGVL, UGVM, UGVR, UGVB)/HOST=#/V=0/OPTS=12
	Notebook kwTopWin, defaultTab=10, autoSave=1, magnification=100, writeProtect=1, showRuler=0, rulerUnits=2
	Notebook kwTopWin, newRuler=Normal, justification=0, margins={0, 0, 285}, spacing={0, 0, 0}, tabs={}, rulerDefaults={"Arial", 11, 0, (0, 0, 0)}
	Notebook kwTopWin, zdata="GaqDU%ejN7!Z)uN!5sg]bQPlL()o:PL]iZ-,W[?i6\"=Ct6f#P.7,n>B$opR1N^]@m3=J*JadFT7$I8Hm`VDNn$k*-6]FUA"
	Notebook kwTopWin, zdataEnd=1
	SetWindow kwTopWin, userdata(tabcontrol)="SF_InfoTab"
	SetWindow kwTopWin, userdata(tabnum)="0"
	RenameWindow #, sweepFormula_error
	SetActiveSubwindow ##
	NewNotebook/F=1/N=sweepFormula_help/W=(10, 71, 378, 358)/FG=(UGVL, UGVT, UGVR, UGVB)/HOST=#/V=0/OPTS=4
	Notebook kwTopWin, defaultTab=10, autoSave=0, magnification=100, writeProtect=1, showRuler=0, rulerUnits=2
	Notebook kwTopWin, newRuler=Normal, justification=0, margins={0, 0, 251}, spacing={0, 0, 0}, tabs={}, rulerDefaults={"Arial", 11, 0, (0, 0, 0)}
	SetWindow kwTopWin, hook(ResizeControls)=ResizeControlsSafe
	SetWindow kwTopWin, userdata(tabnum)="2"
	SetWindow kwTopWin, userdata(tabcontrol)="SF_InfoTab"
	SetWindow kwTopWin, userdata(ResizeControlsInfo)=A"!!,@C!!#>F!!#C#!!#B[J,fQL!!#](Aon#azzzzzzzzzzzzzz!!#o2B4uAeBk2=!z"
	SetWindow kwTopWin, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetWindow kwTopWin, userdata(ResizeControlsInfo)+=A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	SetWindow kwTopWin, userdata(Config_DontRestore)="1"
	SetWindow kwTopWin, userdata(Config_DontSave)="1"
	RenameWindow #, sweepFormula_help
	SetActiveSubwindow ##
	NewNotebook/F=0/N=WaveNoteDisplay/W=(200, 24, 600, 561)/FG=(FL, $"", FR, FB)/HOST=#/V=0/OPTS=10
	Notebook kwTopWin, defaultTab=36, autoSave=0, magnification=100
	Notebook kwTopWin, font="Lucida Console", fSize=11, fStyle=0, textRGB=(0, 0, 0)
	SetWindow kwTopWin, hook(ResizeControls)=ResizeControlsSafe
	SetWindow kwTopWin, userdata(tabnum)="6"
	SetWindow kwTopWin, userdata(tabcontrol)="Settings"
	SetWindow kwTopWin, userdata(ResizeControlsInfo)=A"!!,@C!!#>F!!#C#!!#B[J,fQL!!#](Aon#azzzzzzzzzzzzzz!!#o2B4uAeBk2=!z"
	SetWindow kwTopWin, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetWindow kwTopWin, userdata(ResizeControlsInfo)+=A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	RenameWindow #, WaveNoteDisplay
	SetActiveSubwindow ##
	RenameWindow #, BrowserSettingsPanel
	SetActiveSubwindow ##
	NewPanel/HOST=#/EXT=2/W=(0, 0, 580, 357) as " "
	ModifyPanel fixedSize=0
	GroupBox group_graph_x_axis, pos={478.00, 140.00}, size={98.00, 59.00}
	GroupBox group_graph_x_axis, userdata(ResizeControlsInfo)=A"!!,IUJ,hqF!!#@(!!#?%z!!#N3Bk1ct<C^(W9`P.nzzzzzzzzzzzz!!#o2B4uAe<C^(fz"
	GroupBox group_graph_x_axis, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:DuaGl<C]S6zzzzzzzzzz"
	GroupBox group_graph_x_axis, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafn!(TR6zzzzzzzzzzzzz!!!"
	Button button_clearlabnotebookgraph, pos={384.00, 144.00}, size={90.00, 25.00}, proc=LBV_ButtonProc_ClearGraph
	Button button_clearlabnotebookgraph, title="Clear graph"
	Button button_clearlabnotebookgraph, help={"Clear the labnotebook visualization graph"}
	Button button_clearlabnotebookgraph, userdata(ResizeControlsInfo)=A"!!,I&J,hqJ!!#?m!!#=+z!!#N3Bk1ct<C^(fzzzzzzzzzzzzz!!#N3Bk1ct<C^(W9`P.n"
	Button button_clearlabnotebookgraph, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:DuaGl<C]S6zzzzzzzzzz"
	Button button_clearlabnotebookgraph, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafn!(TR6zzzzzzzzzzzzz!!!"
	Button button_switchxaxis, pos={482.00, 144.00}, size={87.00, 25.00}, proc=LBV_ButtonProc_SwitchXAxis
	Button button_switchxaxis, title="Switch X-axis"
	Button button_switchxaxis, help={"Toggle lab notebook horizontal axis between time of day or sweep number"}
	Button button_switchxaxis, userdata(ResizeControlsInfo)=A"!!,IWJ,hqJ!!#?g!!#=+z!!#N3Bk1ct<C^(W9`P.nzzzzzzzzzzzz!!#o2B4uAe<C^(fz"
	Button button_switchxaxis, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:DuaGl<C]S6zzzzzzzzzz"
	Button button_switchxaxis, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafn!(TR6zzzzzzzzzzzzz!!!"
	Button popupext_TPStorageKeys, pos={397.00, 67.00}, size={167.00, 19.00}, bodyWidth=150, proc=PEXT_ButtonProc
	Button popupext_TPStorageKeys, title="Testpulse Storage Entries ▼"
	Button popupext_TPStorageKeys, help={"Select TPStorage data to display"}
	Button popupext_TPStorageKeys, userdata(popupProc)="LBV_PopMenuProc_TPStorage"
	Button popupext_TPStorageKeys, userdata(Items)="LBV_PopupExtGetTPStorageKeys"
	Button popupext_TPStorageKeys, userdata(ResizeControlsInfo)=A"!!,I-!!#??!!#A6!!#<Pz!!#N3Bk1ct<C^(fzzzzzzzzzzzzz!!#o2B4uAe<C^(fz"
	Button popupext_TPStorageKeys, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:DuaGl<C]S6zzzzzzzzzz"
	Button popupext_TPStorageKeys, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafn!(TR6zzzzzzzzzzzzz!!!"
	GroupBox group_labnotebook_experiment_device, pos={386.00, 5.00}, size={190.00, 55.00}
	GroupBox group_labnotebook_experiment_device, userdata(ResizeControlsInfo)=A"!!,I'J,hj-!!#AM!!#>jz!!#N3Bk1ct<C^(fzzzzzzzzzzzzz!!#o2B4uAe<C^(fz"
	GroupBox group_labnotebook_experiment_device, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:DuaGl<C]S6zzzzzzzzzz"
	GroupBox group_labnotebook_experiment_device, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafn!(TR6zzzzzzzzzzzzz!!!"
	PopupMenu popup_experiment, pos={407.00, 11.00}, size={163.00, 19.00}, bodyWidth=95
	PopupMenu popup_experiment, title="Experiment: "
	PopupMenu popup_experiment, help={"Experiment selection (SweepBrowser only)"}
	PopupMenu popup_experiment, userdata(ResizeControlsInfo)=A"!!,I1J,hkh!!#A3!!#<Pz!!#N3Bk1ct<C^(fzzzzzzzzzzzzz!!#o2B4uAe<C^(fz"
	PopupMenu popup_experiment, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:DuaGl<C]S6zzzzzzzzzz"
	PopupMenu popup_experiment, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafn!(TR6zzzzzzzzzzzzz!!!"
	PopupMenu popup_experiment, mode=1, popvalue="- none -", value=#"\"- none -\""
	PopupMenu popup_Device, pos={431.00, 34.00}, size={139.00, 19.00}, bodyWidth=95
	PopupMenu popup_Device, title="Device: "
	PopupMenu popup_Device, help={"Device selection (SweepBrowser only)"}
	PopupMenu popup_Device, userdata(ResizeControlsInfo)=A"!!,I>!!#=k!!#@o!!#<Pz!!#N3Bk1ct<C^(fzzzzzzzzzzzzz!!#o2B4uAe<C^(fz"
	PopupMenu popup_Device, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:DuaGl<C]S6zzzzzzzzzz"
	PopupMenu popup_Device, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafn!(TR6zzzzzzzzzzzzz!!!"
	PopupMenu popup_Device, mode=1, popvalue="- none -", value=#"\"- none -\""
	Button popupext_LBKeys, pos={397.00, 91.00}, size={167.00, 19.00}, bodyWidth=150, proc=PEXT_ButtonProc
	Button popupext_LBKeys, title="Lab Notebook Entries ▼"
	Button popupext_LBKeys, help={"Select lab notebook data to display"}
	Button popupext_LBKeys, userdata(popupProc)="LBV_PopMenuProc_LabNotebookAndResults"
	Button popupext_LBKeys, userdata(Items)="LBV_PopupExtGetLBKeys"
	Button popupext_LBKeys, userdata(ResizeControlsInfo)=A"!!,I-!!#?o!!#A6!!#<Pz!!#N3Bk1ct<C^(fzzzzzzzzzzzzz!!#o2B4uAe<C^(fz"
	Button popupext_LBKeys, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:DuaGl<C]S6zzzzzzzzzz"
	Button popupext_LBKeys, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafn!(TR6zzzzzzzzzzzzz!!!"
	GroupBox group_labnotebook_experiment_device1, pos={385.00, 61.00}, size={191.00, 78.00}
	GroupBox group_labnotebook_experiment_device1, userdata(ResizeControlsInfo)=A"!!,I'!!#?-!!#AN!!#?Uz!!#N3Bk1ct<C^(fzzzzzzzzzzzzz!!#o2B4uAe<C^(fz"
	GroupBox group_labnotebook_experiment_device1, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:DuaGl<C]S6zzzzzzzzzz"
	GroupBox group_labnotebook_experiment_device1, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafn!(TR6zzzzzzzzzzzzz!!!"
	Button popupext_resultsKeys, pos={397.00, 115.00}, size={167.00, 19.00}, bodyWidth=150, proc=PEXT_ButtonProc
	Button popupext_resultsKeys, title="Results Entries ▼"
	Button popupext_resultsKeys, help={"Select results data to display"}
	Button popupext_resultsKeys, userdata(popupProc)="LBV_PopMenuProc_LabNotebookAndResults"
	Button popupext_resultsKeys, userdata(Items)="LBV_PopupExtGetResultsKeys"
	Button popupext_resultsKeys, userdata(ResizeControlsInfo)=A"!!,I-!!#@J!!#A6!!#<Pz!!#N3Bk1ct<C^(fzzzzzzzzzzzzz!!#o2B4uAe<C^(fz"
	Button popupext_resultsKeys, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:DuaGl<C]S6zzzzzzzzzz"
	Button popupext_resultsKeys, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafn!(TR6zzzzzzzzzzzzz!!!"
	CheckBox check_limit_x_selected_sweeps, pos={485.00, 174.00}, size={60.00, 15.00}, proc=LBV_CheckProc_XRangeSelected
	CheckBox check_limit_x_selected_sweeps, title="Selected"
	CheckBox check_limit_x_selected_sweeps, help={"Limit the x range of the logbook graph to the selected sweeps"}
	CheckBox check_limit_x_selected_sweeps, userdata(ResizeControlsInfo)=A"!!,IY!!#A=!!#?)!!#<(z!!#N3Bk1ct<C^(W9`P.nzzzzzzzzzzzz!!#o2B4uAe<C^(fz"
	CheckBox check_limit_x_selected_sweeps, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:DuaGl<C]S6zzzzzzzzzz"
	CheckBox check_limit_x_selected_sweeps, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafn!(TR6zzzzzzzzzzzzz!!!"
	CheckBox check_limit_x_selected_sweeps, value=0
	DefineGuide UGVL={FL, 125}, UGVR={FR, -200}, UGVCM={FR, -100}
	SetWindow kwTopWin, hook(ResizeControls)=ResizeControlsSafe
	SetWindow kwTopWin, userdata(ResizeControlsInfo)=A"!!*'\"z!!#D!5QF/Czzzzzzzzzzzzzzzzzzzzz"
	SetWindow kwTopWin, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzzzzzzzzzzzzzzz"
	SetWindow kwTopWin, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzzzzzzzzz!!!"
	SetWindow kwTopWin, userdata(ResizeControlsGuides)="UGVL;UGVR;UGVCM;"
	SetWindow kwTopWin, userdata(ResizeControlsInfoUGVL)="NAME:UGVL;WIN:DB_Dev1#SettingsHistoryPanel;TYPE:User;HORIZONTAL:0;POSITION:125.00;GUIDE1:FL;GUIDE2:;RELPOSITION:125;"
	SetWindow kwTopWin, userdata(ResizeControlsInfoUGVR)="NAME:UGVR;WIN:DB_Dev1#SettingsHistoryPanel;TYPE:User;HORIZONTAL:0;POSITION:381.00;GUIDE1:FR;GUIDE2:;RELPOSITION:-200;"
	SetWindow kwTopWin, userdata(ResizeControlsInfoUGVCM)="NAME:UGVCM;WIN:DB_Dev1#SettingsHistoryPanel;TYPE:User;HORIZONTAL:0;POSITION:481.00;GUIDE1:FR;GUIDE2:;RELPOSITION:-100;"
	Execute/Q/Z "SetWindow kwTopWin sizeLimit={441,168,inf,inf}" // sizeLimit requires Igor 7 or later
	Display/W=(200, 187, 353, 501)/FG=(UGVL, FT, UGVR, FB)/HOST=#
	ModifyGraph margin(right)=74, gfSize=10
	TextBox/C/N=text0/F=0/B=1/X=0.50/Y=2.02/E=2 ""
	RenameWindow #, LabNoteBook
	SetActiveSubwindow ##
	NewNotebook/F=1/N=Description/W=(145, 49, 436, 148)/FG=(FL, FT, UGVL, FB)/HOST=#/OPTS=11
	Notebook kwTopWin, defaultTab=10, autoSave=0, magnification=1, showRuler=0, rulerUnits=0
	Notebook kwTopWin, newRuler=Normal, justification=0, margins={0, 0, 86}, spacing={0, 0, 0}, tabs={}, rulerDefaults={"Arial", 11, 0, (0, 0, 0)}
	SetWindow kwTopWin, userdata(Config_DontRestore)="1"
	SetWindow kwTopWin, userdata(Config_DontSave)="1"
	RenameWindow #, Description
	SetActiveSubwindow ##
	RenameWindow #, SettingsHistoryPanel
	SetActiveSubwindow ##
EndMacro
