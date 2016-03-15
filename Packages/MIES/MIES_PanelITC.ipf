#pragma rtGlobals=3		// Use modern global access method and strict wave access.

/// @file MIES_PanelITC.ipf
/// @brief __DAP__ Main data acquisition panel DA_EPHYS

static Constant DATA_ACQU_TAB_NUM         = 0
static Constant HARDWARE_TAB_NUM          = 6

static StrConstant YOKE_LIST_OF_CONTROLS  = "button_Hardware_Lead1600;button_Hardware_Independent;title_hardware_1600inst;title_hardware_Follow;button_Hardware_AddFollower;popup_Hardware_AvailITC1600s;title_hardware_Release;popup_Hardware_YokedDACs;button_Hardware_RemoveYoke"
static StrConstant FOLLOWER               = "Follower"
static StrConstant LEADER                 = "Leader"

static StrConstant COMMENT_PANEL          = "UserComments"
static StrConstant COMMENT_PANEL_NOTEBOOK = "NB"

static Constant DA_EPHYS_PANEL_VERSION    = 1

Window DA_Ephys() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /K=1 /W=(9,53,501,889)
	GroupBox group_DataAcq_WholeCell,pos={47.00,200.00},size={150.00,62.00},disable=1,title="       Whole Cell"
	GroupBox group_DataAcq_WholeCell,userdata(tabnum)=  "0"
	GroupBox group_DataAcq_WholeCell,userdata(tabcontrol)=  "tab_DataAcq_Amp"
	GroupBox group_DataAcq_WholeCell,userdata(ResizeControlsInfo)= A"!!,DK!!#AW!!#A%!!#?1z!!,c)Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	GroupBox group_DataAcq_WholeCell,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	GroupBox group_DataAcq_WholeCell,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	TitleBox Title_settings_SetManagement,pos={948.00,-100.00},size={392.00,213.00},disable=1,title="Set Management Decision Tree"
	TitleBox Title_settings_SetManagement,userdata(tabnum)=  "5"
	TitleBox Title_settings_SetManagement,userdata(tabcontrol)=  "ADC"
	TitleBox Title_settings_SetManagement,userdata(ResizeControlsInfo)= A"!!,K)!!'mW!!#C)!!#Adz!!,c)Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox Title_settings_SetManagement,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	TitleBox Title_settings_SetManagement,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	TitleBox Title_settings_SetManagement,font="Trebuchet MS",frame=4,fStyle=0
	TitleBox Title_settings_SetManagement,fixedSize=1
	TabControl ADC,pos={3.00,1.00},size={479.00,19.00},proc=ACL_DisplayTab
	TabControl ADC,userdata(currenttab)=  "6"
	TabControl ADC,userdata(finalhook)=  "DAP_TabControlFinalHook"
	TabControl ADC,userdata(ResizeControlsInfo)= A"!!,>M!!#66!!#CTJ,hm&z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TabControl ADC,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	TabControl ADC,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	TabControl ADC,userdata(tabcontrol)=  "ADC",tabLabel(0)="Data Acquisition"
	TabControl ADC,tabLabel(1)="DA",tabLabel(2)="AD",tabLabel(3)="TTL"
	TabControl ADC,tabLabel(4)="Asynchronous",tabLabel(5)="Settings"
	TabControl ADC,tabLabel(6)="Hardware",value= 6
	CheckBox Check_AD_00,pos={20.00,75.00},size={21.00,15.00},disable=1,proc=DAP_CheckProc_AD,title="0"
	CheckBox Check_AD_00,userdata(tabnum)=  "2",userdata(tabcontrol)=  "ADC"
	CheckBox Check_AD_00,userdata(ResizeControlsInfo)= A"!!,BY!!#?O!!#<`!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_AD_00,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_AD_00,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_AD_00,value= 0,side= 1
	CheckBox Check_AD_01,pos={20.00,121.00},size={21.00,15.00},disable=1,proc=DAP_CheckProc_AD,title="1"
	CheckBox Check_AD_01,userdata(tabnum)=  "2",userdata(tabcontrol)=  "ADC"
	CheckBox Check_AD_01,userdata(ResizeControlsInfo)= A"!!,BY!!#@V!!#<`!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_AD_01,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_AD_01,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_AD_01,value= 0,side= 1
	CheckBox Check_AD_02,pos={20.00,167.00},size={21.00,15.00},disable=1,proc=DAP_CheckProc_AD,title="2"
	CheckBox Check_AD_02,userdata(tabnum)=  "2",userdata(tabcontrol)=  "ADC"
	CheckBox Check_AD_02,userdata(ResizeControlsInfo)= A"!!,BY!!#A6!!#<`!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_AD_02,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_AD_02,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_AD_02,value= 0,side= 1
	CheckBox Check_AD_03,pos={20.00,214.00},size={21.00,15.00},disable=1,proc=DAP_CheckProc_AD,title="3"
	CheckBox Check_AD_03,userdata(tabnum)=  "2",userdata(tabcontrol)=  "ADC"
	CheckBox Check_AD_03,userdata(ResizeControlsInfo)= A"!!,BY!!#Ae!!#<`!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_AD_03,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_AD_03,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_AD_03,value= 0,side= 1
	CheckBox Check_AD_04,pos={20.00,260.00},size={21.00,15.00},disable=1,proc=DAP_CheckProc_AD,title="4"
	CheckBox Check_AD_04,userdata(tabnum)=  "2",userdata(tabcontrol)=  "ADC"
	CheckBox Check_AD_04,userdata(ResizeControlsInfo)= A"!!,BY!!#B<!!#<`!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_AD_04,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_AD_04,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_AD_04,value= 0,side= 1
	CheckBox Check_AD_05,pos={20.00,307.00},size={21.00,15.00},disable=1,proc=DAP_CheckProc_AD,title="5"
	CheckBox Check_AD_05,userdata(tabnum)=  "2",userdata(tabcontrol)=  "ADC"
	CheckBox Check_AD_05,userdata(ResizeControlsInfo)= A"!!,BY!!#BSJ,hm6!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_AD_05,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_AD_05,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_AD_05,value= 0,side= 1
	CheckBox Check_AD_06,pos={20.00,353.00},size={21.00,15.00},disable=1,proc=DAP_CheckProc_AD,title="6"
	CheckBox Check_AD_06,userdata(tabnum)=  "2",userdata(tabcontrol)=  "ADC"
	CheckBox Check_AD_06,userdata(ResizeControlsInfo)= A"!!,BY!!#BjJ,hm6!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_AD_06,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_AD_06,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_AD_06,value= 0,side= 1
	CheckBox Check_AD_07,pos={20.00,400.00},size={21.00,15.00},disable=1,proc=DAP_CheckProc_AD,title="7"
	CheckBox Check_AD_07,userdata(tabnum)=  "2",userdata(tabcontrol)=  "ADC"
	CheckBox Check_AD_07,userdata(ResizeControlsInfo)= A"!!,BY!!#C-!!#<`!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_AD_07,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_AD_07,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_AD_07,value= 0,side= 1
	CheckBox Check_AD_08,pos={200.00,75.00},size={21.00,15.00},disable=1,proc=DAP_CheckProc_AD,title="8"
	CheckBox Check_AD_08,userdata(tabnum)=  "2",userdata(tabcontrol)=  "ADC"
	CheckBox Check_AD_08,userdata(ResizeControlsInfo)= A"!!,GX!!#?O!!#<`!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_AD_08,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_AD_08,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_AD_08,value= 0,side= 1
	CheckBox Check_AD_09,pos={200.00,121.00},size={21.00,15.00},disable=1,proc=DAP_CheckProc_AD,title="9"
	CheckBox Check_AD_09,userdata(tabnum)=  "2",userdata(tabcontrol)=  "ADC"
	CheckBox Check_AD_09,userdata(ResizeControlsInfo)= A"!!,GX!!#@V!!#<`!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_AD_09,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_AD_09,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_AD_09,value= 0,side= 1
	CheckBox Check_AD_10,pos={194.00,167.00},size={27.00,15.00},disable=1,proc=DAP_CheckProc_AD,title="10"
	CheckBox Check_AD_10,userdata(tabnum)=  "2",userdata(tabcontrol)=  "ADC"
	CheckBox Check_AD_10,userdata(ResizeControlsInfo)= A"!!,GR!!#A6!!#=;!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_AD_10,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_AD_10,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_AD_10,value= 0,side= 1
	CheckBox Check_AD_12,pos={194.00,260.00},size={27.00,15.00},disable=1,proc=DAP_CheckProc_AD,title="12"
	CheckBox Check_AD_12,userdata(tabnum)=  "2",userdata(tabcontrol)=  "ADC"
	CheckBox Check_AD_12,userdata(ResizeControlsInfo)= A"!!,GR!!#B<!!#=;!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_AD_12,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_AD_12,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_AD_12,value= 0,side= 1
	CheckBox Check_AD_11,pos={194.00,214.00},size={27.00,15.00},disable=1,proc=DAP_CheckProc_AD,title="11"
	CheckBox Check_AD_11,userdata(tabnum)=  "2",userdata(tabcontrol)=  "ADC"
	CheckBox Check_AD_11,userdata(ResizeControlsInfo)= A"!!,GR!!#Ae!!#=;!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_AD_11,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_AD_11,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_AD_11,value= 0,side= 1
	SetVariable Gain_AD_00,pos={50.00,75.00},size={50.00,18.00},bodyWidth=50,disable=1
	SetVariable Gain_AD_00,userdata(tabnum)=  "2",userdata(tabcontrol)=  "ADC"
	SetVariable Gain_AD_00,userdata(ResizeControlsInfo)= A"!!,DW!!#?O!!#>V!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Gain_AD_00,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Gain_AD_00,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Gain_AD_00,limits={0,inf,1},value= _NUM:0
	SetVariable Gain_AD_01,pos={50.00,121.00},size={50.00,18.00},bodyWidth=50,disable=1
	SetVariable Gain_AD_01,userdata(tabnum)=  "2",userdata(tabcontrol)=  "ADC"
	SetVariable Gain_AD_01,userdata(ResizeControlsInfo)= A"!!,DW!!#@V!!#>V!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Gain_AD_01,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Gain_AD_01,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Gain_AD_01,limits={0,inf,1},value= _NUM:0
	SetVariable Gain_AD_02,pos={50.00,167.00},size={50.00,18.00},bodyWidth=50,disable=1
	SetVariable Gain_AD_02,userdata(tabnum)=  "2",userdata(tabcontrol)=  "ADC"
	SetVariable Gain_AD_02,userdata(ResizeControlsInfo)= A"!!,DW!!#A6!!#>V!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Gain_AD_02,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Gain_AD_02,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Gain_AD_02,limits={0,inf,1},value= _NUM:0
	SetVariable Gain_AD_03,pos={50.00,214.00},size={50.00,18.00},bodyWidth=50,disable=1
	SetVariable Gain_AD_03,userdata(tabnum)=  "2",userdata(tabcontrol)=  "ADC"
	SetVariable Gain_AD_03,userdata(ResizeControlsInfo)= A"!!,DW!!#Ae!!#>V!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Gain_AD_03,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Gain_AD_03,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Gain_AD_03,limits={0,inf,1},value= _NUM:0
	SetVariable Gain_AD_04,pos={50.00,260.00},size={50.00,18.00},bodyWidth=50,disable=1
	SetVariable Gain_AD_04,userdata(tabnum)=  "2",userdata(tabcontrol)=  "ADC"
	SetVariable Gain_AD_04,userdata(ResizeControlsInfo)= A"!!,DW!!#B<!!#>V!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Gain_AD_04,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Gain_AD_04,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Gain_AD_04,limits={0,inf,1},value= _NUM:0
	SetVariable Gain_AD_05,pos={50.00,307.00},size={50.00,18.00},bodyWidth=50,disable=1
	SetVariable Gain_AD_05,userdata(tabnum)=  "2",userdata(tabcontrol)=  "ADC"
	SetVariable Gain_AD_05,userdata(ResizeControlsInfo)= A"!!,DW!!#BSJ,ho,!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Gain_AD_05,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Gain_AD_05,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Gain_AD_05,limits={0,inf,1},value= _NUM:0
	SetVariable Gain_AD_06,pos={50.00,353.00},size={50.00,18.00},bodyWidth=50,disable=1
	SetVariable Gain_AD_06,userdata(tabnum)=  "2",userdata(tabcontrol)=  "ADC"
	SetVariable Gain_AD_06,userdata(ResizeControlsInfo)= A"!!,DW!!#BjJ,ho,!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Gain_AD_06,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Gain_AD_06,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Gain_AD_06,limits={0,inf,1},value= _NUM:0
	SetVariable Gain_AD_07,pos={50.00,400.00},size={50.00,18.00},bodyWidth=50,disable=1
	SetVariable Gain_AD_07,userdata(tabnum)=  "2",userdata(tabcontrol)=  "ADC"
	SetVariable Gain_AD_07,userdata(ResizeControlsInfo)= A"!!,DW!!#C-!!#>V!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Gain_AD_07,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Gain_AD_07,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Gain_AD_07,limits={0,inf,1},value= _NUM:0
	SetVariable Gain_AD_08,pos={229.00,75.00},size={50.00,18.00},bodyWidth=50,disable=1
	SetVariable Gain_AD_08,userdata(tabnum)=  "2",userdata(tabcontrol)=  "ADC"
	SetVariable Gain_AD_08,userdata(ResizeControlsInfo)= A"!!,Gu!!#?O!!#>V!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Gain_AD_08,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Gain_AD_08,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Gain_AD_08,limits={0,inf,1},value= _NUM:0
	SetVariable Gain_AD_09,pos={229.00,121.00},size={50.00,18.00},bodyWidth=50,disable=1
	SetVariable Gain_AD_09,userdata(tabnum)=  "2",userdata(tabcontrol)=  "ADC"
	SetVariable Gain_AD_09,userdata(ResizeControlsInfo)= A"!!,Gu!!#@V!!#>V!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Gain_AD_09,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Gain_AD_09,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Gain_AD_09,limits={0,inf,1},value= _NUM:0
	SetVariable Gain_AD_10,pos={229.00,167.00},size={50.00,18.00},bodyWidth=50,disable=1
	SetVariable Gain_AD_10,userdata(tabnum)=  "2",userdata(tabcontrol)=  "ADC"
	SetVariable Gain_AD_10,userdata(ResizeControlsInfo)= A"!!,Gu!!#A6!!#>V!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Gain_AD_10,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Gain_AD_10,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Gain_AD_10,limits={0,inf,1},value= _NUM:0
	SetVariable Gain_AD_11,pos={229.00,214.00},size={50.00,18.00},bodyWidth=50,disable=1
	SetVariable Gain_AD_11,userdata(tabnum)=  "2",userdata(tabcontrol)=  "ADC"
	SetVariable Gain_AD_11,userdata(ResizeControlsInfo)= A"!!,Gu!!#Ae!!#>V!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Gain_AD_11,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Gain_AD_11,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Gain_AD_11,limits={0,inf,1},value= _NUM:0
	SetVariable Gain_AD_12,pos={229.00,260.00},size={50.00,18.00},bodyWidth=50,disable=1
	SetVariable Gain_AD_12,userdata(tabnum)=  "2",userdata(tabcontrol)=  "ADC"
	SetVariable Gain_AD_12,userdata(ResizeControlsInfo)= A"!!,Gu!!#B<!!#>V!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Gain_AD_12,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Gain_AD_12,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Gain_AD_12,limits={0,inf,1},value= _NUM:0
	CheckBox Check_AD_13,pos={194.00,307.00},size={27.00,15.00},disable=1,proc=DAP_CheckProc_AD,title="13"
	CheckBox Check_AD_13,userdata(tabnum)=  "2",userdata(tabcontrol)=  "ADC"
	CheckBox Check_AD_13,userdata(ResizeControlsInfo)= A"!!,GR!!#BSJ,hmf!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_AD_13,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_AD_13,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_AD_13,value= 0,side= 1
	CheckBox Check_AD_14,pos={194.00,353.00},size={27.00,15.00},disable=1,proc=DAP_CheckProc_AD,title="14"
	CheckBox Check_AD_14,userdata(tabnum)=  "2",userdata(tabcontrol)=  "ADC"
	CheckBox Check_AD_14,userdata(ResizeControlsInfo)= A"!!,GR!!#BjJ,hmf!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_AD_14,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_AD_14,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_AD_14,value= 0,side= 1
	CheckBox Check_AD_15,pos={194.00,400.00},size={27.00,15.00},disable=1,proc=DAP_CheckProc_AD,title="15"
	CheckBox Check_AD_15,userdata(tabnum)=  "2",userdata(tabcontrol)=  "ADC"
	CheckBox Check_AD_15,userdata(ResizeControlsInfo)= A"!!,GR!!#C-!!#=;!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_AD_15,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_AD_15,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_AD_15,value= 0,side= 1
	SetVariable Gain_AD_13,pos={229.00,307.00},size={50.00,18.00},bodyWidth=50,disable=1
	SetVariable Gain_AD_13,userdata(tabnum)=  "2",userdata(tabcontrol)=  "ADC"
	SetVariable Gain_AD_13,userdata(ResizeControlsInfo)= A"!!,Gu!!#BSJ,ho,!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Gain_AD_13,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Gain_AD_13,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Gain_AD_13,limits={0,inf,1},value= _NUM:0
	SetVariable Gain_AD_14,pos={229.00,353.00},size={50.00,18.00},bodyWidth=50,disable=1
	SetVariable Gain_AD_14,userdata(tabnum)=  "2",userdata(tabcontrol)=  "ADC"
	SetVariable Gain_AD_14,userdata(ResizeControlsInfo)= A"!!,Gu!!#BjJ,ho,!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Gain_AD_14,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Gain_AD_14,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Gain_AD_14,limits={0,inf,1},value= _NUM:0
	SetVariable Gain_AD_15,pos={229.00,400.00},size={50.00,18.00},bodyWidth=50,disable=1
	SetVariable Gain_AD_15,userdata(tabnum)=  "2",userdata(tabcontrol)=  "ADC"
	SetVariable Gain_AD_15,userdata(ResizeControlsInfo)= A"!!,Gu!!#C-!!#>V!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Gain_AD_15,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Gain_AD_15,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Gain_AD_15,limits={0,inf,1},value= _NUM:0
	CheckBox Check_DA_00,pos={20.00,75.00},size={21.00,15.00},disable=1,proc=DAP_DAorTTLCheckProc,title="0"
	CheckBox Check_DA_00,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	CheckBox Check_DA_00,userdata(ResizeControlsInfo)= A"!!,BY!!#?O!!#<`!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_DA_00,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_DA_00,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_DA_00,value= 0,side= 1
	CheckBox Check_DA_01,pos={20.00,121.00},size={21.00,15.00},disable=1,proc=DAP_DAorTTLCheckProc,title="1"
	CheckBox Check_DA_01,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	CheckBox Check_DA_01,userdata(ResizeControlsInfo)= A"!!,BY!!#@V!!#<`!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_DA_01,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_DA_01,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_DA_01,value= 0,side= 1
	CheckBox Check_DA_02,pos={20.00,167.00},size={21.00,15.00},disable=1,proc=DAP_DAorTTLCheckProc,title="2"
	CheckBox Check_DA_02,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	CheckBox Check_DA_02,userdata(ResizeControlsInfo)= A"!!,BY!!#A6!!#<`!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_DA_02,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_DA_02,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_DA_02,value= 0,side= 1
	CheckBox Check_DA_03,pos={20.00,214.00},size={21.00,15.00},disable=1,proc=DAP_DAorTTLCheckProc,title="3"
	CheckBox Check_DA_03,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	CheckBox Check_DA_03,userdata(ResizeControlsInfo)= A"!!,BY!!#Ae!!#<`!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_DA_03,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_DA_03,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_DA_03,value= 0,side= 1
	CheckBox Check_DA_04,pos={20.00,260.00},size={21.00,15.00},disable=1,proc=DAP_DAorTTLCheckProc,title="4"
	CheckBox Check_DA_04,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	CheckBox Check_DA_04,userdata(ResizeControlsInfo)= A"!!,BY!!#B<!!#<`!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_DA_04,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_DA_04,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_DA_04,value= 0,side= 1
	CheckBox Check_DA_05,pos={20.00,307.00},size={21.00,15.00},disable=1,proc=DAP_DAorTTLCheckProc,title="5"
	CheckBox Check_DA_05,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	CheckBox Check_DA_05,userdata(ResizeControlsInfo)= A"!!,BY!!#BSJ,hm6!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_DA_05,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_DA_05,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_DA_05,value= 0,side= 1
	CheckBox Check_DA_06,pos={20.00,353.00},size={21.00,15.00},disable=1,proc=DAP_DAorTTLCheckProc,title="6"
	CheckBox Check_DA_06,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	CheckBox Check_DA_06,userdata(ResizeControlsInfo)= A"!!,BY!!#BjJ,hm6!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_DA_06,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_DA_06,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_DA_06,value= 0,side= 1
	CheckBox Check_DA_07,pos={20.00,400.00},size={21.00,15.00},disable=1,proc=DAP_DAorTTLCheckProc,title="7"
	CheckBox Check_DA_07,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	CheckBox Check_DA_07,userdata(ResizeControlsInfo)= A"!!,BY!!#C-!!#<`!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_DA_07,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_DA_07,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_DA_07,value= 0,side= 1
	SetVariable Gain_DA_00,pos={50.00,75.00},size={50.00,18.00},disable=1
	SetVariable Gain_DA_00,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	SetVariable Gain_DA_00,userdata(ResizeControlsInfo)= A"!!,DW!!#?O!!#>V!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Gain_DA_00,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Gain_DA_00,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Gain_DA_00,limits={0,inf,1},value= _NUM:0
	SetVariable Gain_DA_01,pos={50.00,121.00},size={50.00,18.00},disable=1
	SetVariable Gain_DA_01,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	SetVariable Gain_DA_01,userdata(ResizeControlsInfo)= A"!!,DW!!#@V!!#>V!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Gain_DA_01,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Gain_DA_01,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Gain_DA_01,limits={0,inf,1},value= _NUM:0
	SetVariable Gain_DA_02,pos={50.00,167.00},size={50.00,18.00},disable=1
	SetVariable Gain_DA_02,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	SetVariable Gain_DA_02,userdata(ResizeControlsInfo)= A"!!,DW!!#A6!!#>V!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Gain_DA_02,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Gain_DA_02,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Gain_DA_02,limits={0,inf,1},value= _NUM:0
	SetVariable Gain_DA_03,pos={50.00,214.00},size={50.00,18.00},disable=1
	SetVariable Gain_DA_03,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	SetVariable Gain_DA_03,userdata(ResizeControlsInfo)= A"!!,DW!!#Ae!!#>V!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Gain_DA_03,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Gain_DA_03,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Gain_DA_03,limits={0,inf,1},value= _NUM:0
	SetVariable Gain_DA_04,pos={50.00,260.00},size={50.00,18.00},disable=1
	SetVariable Gain_DA_04,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	SetVariable Gain_DA_04,userdata(ResizeControlsInfo)= A"!!,DW!!#B<!!#>V!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Gain_DA_04,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Gain_DA_04,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Gain_DA_04,limits={0,inf,1},value= _NUM:0
	SetVariable Gain_DA_05,pos={50.00,307.00},size={50.00,18.00},disable=1
	SetVariable Gain_DA_05,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	SetVariable Gain_DA_05,userdata(ResizeControlsInfo)= A"!!,DW!!#BSJ,ho,!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Gain_DA_05,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Gain_DA_05,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Gain_DA_05,limits={0,inf,1},value= _NUM:0
	SetVariable Gain_DA_06,pos={50.00,353.00},size={50.00,18.00},disable=1
	SetVariable Gain_DA_06,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	SetVariable Gain_DA_06,userdata(ResizeControlsInfo)= A"!!,DW!!#BjJ,ho,!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Gain_DA_06,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Gain_DA_06,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Gain_DA_06,limits={0,inf,1},value= _NUM:0
	SetVariable Gain_DA_07,pos={50.00,400.00},size={50.00,18.00},disable=1
	SetVariable Gain_DA_07,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	SetVariable Gain_DA_07,userdata(ResizeControlsInfo)= A"!!,DW!!#C-!!#>V!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Gain_DA_07,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Gain_DA_07,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Gain_DA_07,limits={0,inf,1},value= _NUM:0
	PopupMenu Wave_DA_00,pos={140.00,75.00},size={138.00,19.00},bodyWidth=125,disable=1,proc=DAP_PopMenuChkProc_StimSetList,title="/V"
	PopupMenu Wave_DA_00,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	PopupMenu Wave_DA_00,userdata(ResizeControlsInfo)= A"!!,Fq!!#?O!!#@n!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Wave_DA_00,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Wave_DA_00,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Wave_DA_00,fSize=10
	PopupMenu Wave_DA_00,mode=1,popvalue="- none -",value= #"\"- none -;TestPulse;\"+ReturnListOfAllStimSets(0,\"*DA*\")"
	PopupMenu Wave_DA_01,pos={140.00,121.00},size={138.00,19.00},bodyWidth=125,disable=1,proc=DAP_PopMenuChkProc_StimSetList,title="/V"
	PopupMenu Wave_DA_01,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	PopupMenu Wave_DA_01,userdata(ResizeControlsInfo)= A"!!,Fq!!#@V!!#@n!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Wave_DA_01,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Wave_DA_01,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Wave_DA_01,fSize=10
	PopupMenu Wave_DA_01,mode=1,popvalue="- none -",value= #"\"- none -;TestPulse;\"+ReturnListOfAllStimSets(0,\"*DA*\")"
	PopupMenu Wave_DA_02,pos={140.00,167.00},size={138.00,19.00},bodyWidth=125,disable=1,proc=DAP_PopMenuChkProc_StimSetList,title="/V"
	PopupMenu Wave_DA_02,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	PopupMenu Wave_DA_02,userdata(ResizeControlsInfo)= A"!!,Fq!!#A6!!#@n!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Wave_DA_02,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Wave_DA_02,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Wave_DA_02,fSize=10
	PopupMenu Wave_DA_02,mode=1,popvalue="- none -",value= #"\"- none -;TestPulse;\"+ReturnListOfAllStimSets(0,\"*DA*\")"
	PopupMenu Wave_DA_03,pos={140.00,214.00},size={138.00,19.00},bodyWidth=125,disable=1,proc=DAP_PopMenuChkProc_StimSetList,title="/V"
	PopupMenu Wave_DA_03,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	PopupMenu Wave_DA_03,userdata(ResizeControlsInfo)= A"!!,Fq!!#Ae!!#@n!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Wave_DA_03,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Wave_DA_03,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Wave_DA_03,fSize=10
	PopupMenu Wave_DA_03,mode=1,popvalue="- none -",value= #"\"- none -;TestPulse;\"+ReturnListOfAllStimSets(0,\"*DA*\")"
	PopupMenu Wave_DA_04,pos={140.00,260.00},size={138.00,19.00},bodyWidth=125,disable=1,proc=DAP_PopMenuChkProc_StimSetList,title="/V"
	PopupMenu Wave_DA_04,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	PopupMenu Wave_DA_04,userdata(ResizeControlsInfo)= A"!!,Fq!!#B<!!#@n!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Wave_DA_04,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Wave_DA_04,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Wave_DA_04,fSize=10
	PopupMenu Wave_DA_04,mode=1,popvalue="- none -",value= #"\"- none -;TestPulse;\"+ReturnListOfAllStimSets(0,\"*DA*\")"
	PopupMenu Wave_DA_05,pos={140.00,307.00},size={138.00,19.00},bodyWidth=125,disable=1,proc=DAP_PopMenuChkProc_StimSetList,title="/V"
	PopupMenu Wave_DA_05,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	PopupMenu Wave_DA_05,userdata(ResizeControlsInfo)= A"!!,Fq!!#BSJ,hqD!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Wave_DA_05,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Wave_DA_05,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Wave_DA_05,fSize=10
	PopupMenu Wave_DA_05,mode=1,popvalue="- none -",value= #"\"- none -;TestPulse;\"+ReturnListOfAllStimSets(0,\"*DA*\")"
	PopupMenu Wave_DA_06,pos={140.00,353.00},size={138.00,19.00},bodyWidth=125,disable=1,proc=DAP_PopMenuChkProc_StimSetList,title="/V"
	PopupMenu Wave_DA_06,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	PopupMenu Wave_DA_06,userdata(ResizeControlsInfo)= A"!!,Fq!!#BjJ,hqD!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Wave_DA_06,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Wave_DA_06,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Wave_DA_06,fSize=10
	PopupMenu Wave_DA_06,mode=1,popvalue="- none -",value= #"\"- none -;TestPulse;\"+ReturnListOfAllStimSets(0,\"*DA*\")"
	PopupMenu Wave_DA_07,pos={140.00,400.00},size={138.00,19.00},bodyWidth=125,disable=1,proc=DAP_PopMenuChkProc_StimSetList,title="/V"
	PopupMenu Wave_DA_07,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	PopupMenu Wave_DA_07,userdata(ResizeControlsInfo)= A"!!,Fq!!#C-!!#@n!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Wave_DA_07,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Wave_DA_07,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Wave_DA_07,fSize=10
	PopupMenu Wave_DA_07,mode=1,popvalue="- none -",value= #"\"- none -;TestPulse;\"+ReturnListOfAllStimSets(0,\"*DA*\")"
	SetVariable Scale_DA_00,pos={290.00,75.00},size={50.00,18.00},disable=1
	SetVariable Scale_DA_00,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	SetVariable Scale_DA_00,userdata(ResizeControlsInfo)= A"!!,HL!!#?O!!#>V!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Scale_DA_00,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Scale_DA_00,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Scale_DA_00,limits={-inf,inf,10},value= _NUM:1
	SetVariable Scale_DA_01,pos={290.00,121.00},size={50.00,18.00},disable=1
	SetVariable Scale_DA_01,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	SetVariable Scale_DA_01,userdata(ResizeControlsInfo)= A"!!,HL!!#@V!!#>V!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Scale_DA_01,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Scale_DA_01,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Scale_DA_01,limits={-inf,inf,10},value= _NUM:1
	SetVariable Scale_DA_02,pos={290.00,167.00},size={50.00,18.00},disable=1
	SetVariable Scale_DA_02,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	SetVariable Scale_DA_02,userdata(ResizeControlsInfo)= A"!!,HL!!#A6!!#>V!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Scale_DA_02,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Scale_DA_02,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Scale_DA_02,limits={-inf,inf,10},value= _NUM:1
	SetVariable Scale_DA_03,pos={290.00,214.00},size={50.00,18.00},disable=1
	SetVariable Scale_DA_03,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	SetVariable Scale_DA_03,userdata(ResizeControlsInfo)= A"!!,HL!!#Ae!!#>V!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Scale_DA_03,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Scale_DA_03,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Scale_DA_03,limits={-inf,inf,10},value= _NUM:1
	SetVariable Scale_DA_04,pos={290.00,260.00},size={50.00,18.00},disable=1
	SetVariable Scale_DA_04,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	SetVariable Scale_DA_04,userdata(ResizeControlsInfo)= A"!!,HL!!#B<!!#>V!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Scale_DA_04,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Scale_DA_04,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Scale_DA_04,value= _NUM:1
	SetVariable Scale_DA_05,pos={290.00,307.00},size={50.00,18.00},disable=1
	SetVariable Scale_DA_05,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	SetVariable Scale_DA_05,userdata(ResizeControlsInfo)= A"!!,HL!!#BSJ,ho,!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Scale_DA_05,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Scale_DA_05,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Scale_DA_05,value= _NUM:1
	SetVariable Scale_DA_06,pos={290.00,353.00},size={50.00,18.00},disable=1
	SetVariable Scale_DA_06,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	SetVariable Scale_DA_06,userdata(ResizeControlsInfo)= A"!!,HL!!#BjJ,ho,!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Scale_DA_06,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Scale_DA_06,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Scale_DA_06,limits={-inf,inf,10},value= _NUM:1
	SetVariable Scale_DA_07,pos={290.00,400.00},size={50.00,18.00},bodyWidth=50,disable=1
	SetVariable Scale_DA_07,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	SetVariable Scale_DA_07,userdata(ResizeControlsInfo)= A"!!,HL!!#C-!!#>V!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Scale_DA_07,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Scale_DA_07,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Scale_DA_07,limits={-inf,inf,10},value= _NUM:1
	SetVariable SetVar_DataAcq_Comment,pos={54.00,737.00},size={362.00,14.00},disable=1,title="Comment"
	SetVariable SetVar_DataAcq_Comment,help={"Appends a comment to wave note of next sweep"}
	SetVariable SetVar_DataAcq_Comment,userdata(tabnum)=  "0"
	SetVariable SetVar_DataAcq_Comment,userdata(tabcontrol)=  "ADC"
	SetVariable SetVar_DataAcq_Comment,userdata(ResizeControlsInfo)= A"!!,Dg!!#DH5QF0Z!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_DataAcq_Comment,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_DataAcq_Comment,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_DataAcq_Comment,fSize=8,value= _STR:""
	Button DataAcquireButton,pos={50.00,755.00},size={405.00,42.00},disable=1,proc=DAP_ButtonProc_AcquireData,title="\\Z14\\f01Acquire\rData"
	Button DataAcquireButton,userdata(tabnum)=  "0",userdata(tabcontrol)=  "ADC"
	Button DataAcquireButton,userdata(ResizeControlsInfo)= A"!!,DW!!#DL^]6aEJ,hnaz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button DataAcquireButton,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button DataAcquireButton,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	Button DataAcquireButton,labelBack=(60928,60928,60928)
	CheckBox Check_DataAcq1_RepeatAcq,pos={38.00,644.00},size={88.00,15.00},disable=1,proc=DAP_CheckProc_RepeatedAcq,title="Repeated Acq"
	CheckBox Check_DataAcq1_RepeatAcq,help={"Determines number of times a set is repeated, or if indexing is on, the number of times a group of sets in repeated"}
	CheckBox Check_DataAcq1_RepeatAcq,userdata(tabnum)=  "0"
	CheckBox Check_DataAcq1_RepeatAcq,userdata(tabcontrol)=  "ADC"
	CheckBox Check_DataAcq1_RepeatAcq,userdata(ResizeControlsInfo)= A"!!,D'!!#D1!!#?i!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_DataAcq1_RepeatAcq,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_DataAcq1_RepeatAcq,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_DataAcq1_RepeatAcq,value= 1
	SetVariable SetVar_DataAcq_ITI,pos={66.00,700.00},size={80.00,18.00},bodyWidth=35,disable=1,proc=DAP_SetVarProc_ITI,title="\\JCITl (sec)"
	SetVariable SetVar_DataAcq_ITI,userdata(tabnum)=  "0"
	SetVariable SetVar_DataAcq_ITI,userdata(tabcontrol)=  "ADC"
	SetVariable SetVar_DataAcq_ITI,userdata(ResizeControlsInfo)= A"!!,Eb!!#D?!!#?Y!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_DataAcq_ITI,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_DataAcq_ITI,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_DataAcq_ITI,limits={0,inf,1},value= _NUM:0
	Button StartTestPulseButton,pos={50.00,444.00},size={405.00,40.00},disable=1,proc=DAP_ButtonProc_TestPulse,title="\\Z14\\f01Start Test \rPulse"
	Button StartTestPulseButton,help={"Starts generating test pulses. Can be stopped by pressing the Escape key."}
	Button StartTestPulseButton,userdata(tabnum)=  "0",userdata(tabcontrol)=  "ADC"
	Button StartTestPulseButton,userdata(ResizeControlsInfo)= A"!!,DW!!#CC!!#C/J,hnYz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button StartTestPulseButton,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button StartTestPulseButton,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_DataAcqHS_00,pos={145.00,86.00},size={21.00,15.00},disable=1,proc=DAP_CheckProc_HedstgeChck,title="0"
	CheckBox Check_DataAcqHS_00,userdata(tabnum)=  "0",userdata(tabcontrol)=  "ADC"
	CheckBox Check_DataAcqHS_00,userdata(ResizeControlsInfo)= A"!!,G!!!#?e!!#<`!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_DataAcqHS_00,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_DataAcqHS_00,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_DataAcqHS_00,labelBack=(65280,0,0),value= 0
	SetVariable SetVar_DataAcq_TPDuration,pos={53.00,417.00},size={127.00,18.00},bodyWidth=50,disable=1,proc=DAP_SetVarProc_TestPulseSett,title="Duration (ms)"
	SetVariable SetVar_DataAcq_TPDuration,help={"Duration of the testpulse in milliseconds"}
	SetVariable SetVar_DataAcq_TPDuration,userdata(tabnum)=  "0"
	SetVariable SetVar_DataAcq_TPDuration,userdata(tabcontrol)=  "ADC"
	SetVariable SetVar_DataAcq_TPDuration,userdata(ResizeControlsInfo)= A"!!,Dc!!#C5J,hq8!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_DataAcq_TPDuration,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_DataAcq_TPDuration,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_DataAcq_TPDuration,limits={1,inf,5},value= _NUM:10
	SetVariable SetVar_DataAcq_TPBaselinePerc,pos={186.00,417.00},size={118.00,18.00},bodyWidth=50,disable=1,proc=DAP_SetVarProc_TestPulseSett,title="Baseline (%)"
	SetVariable SetVar_DataAcq_TPBaselinePerc,help={"Length of the baseline before and after the testpulse, in parts of the total testpulse duration"}
	SetVariable SetVar_DataAcq_TPBaselinePerc,userdata(tabnum)=  "0"
	SetVariable SetVar_DataAcq_TPBaselinePerc,userdata(tabcontrol)=  "ADC"
	SetVariable SetVar_DataAcq_TPBaselinePerc,userdata(ResizeControlsInfo)= A"!!,GJ!!#C5J,hq&!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_DataAcq_TPBaselinePerc,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_DataAcq_TPBaselinePerc,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_DataAcq_TPBaselinePerc,limits={25,49,1},value= _NUM:25
	SetVariable SetVar_DataAcq_TPAmplitude,pos={315.00,417.00},size={69.00,18.00},bodyWidth=50,disable=1,proc=DAP_SetVarProc_TPAmp,title="VC"
	SetVariable SetVar_DataAcq_TPAmplitude,help={"Amplitude of the testpulse in voltage clamp mode"}
	SetVariable SetVar_DataAcq_TPAmplitude,userdata(tabnum)=  "0"
	SetVariable SetVar_DataAcq_TPAmplitude,userdata(tabcontrol)=  "ADC"
	SetVariable SetVar_DataAcq_TPAmplitude,userdata(ResizeControlsInfo)= A"!!,HXJ,hs`J,hon!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_DataAcq_TPAmplitude,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_DataAcq_TPAmplitude,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_DataAcq_TPAmplitude,value= _NUM:10
	CheckBox Check_TTL_00,pos={20.00,75.00},size={21.00,15.00},disable=1,proc=DAP_DAorTTLCheckProc,title="0"
	CheckBox Check_TTL_00,userdata(tabnum)=  "3",userdata(tabcontrol)=  "ADC"
	CheckBox Check_TTL_00,userdata(ResizeControlsInfo)= A"!!,BY!!#?O!!#<`!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_TTL_00,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_TTL_00,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_TTL_00,value= 0
	CheckBox Check_TTL_01,pos={20.00,121.00},size={21.00,15.00},disable=1,proc=DAP_DAorTTLCheckProc,title="1"
	CheckBox Check_TTL_01,userdata(tabnum)=  "3",userdata(tabcontrol)=  "ADC"
	CheckBox Check_TTL_01,userdata(ResizeControlsInfo)= A"!!,BY!!#@V!!#<`!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_TTL_01,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_TTL_01,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_TTL_01,value= 0
	CheckBox Check_TTL_02,pos={20.00,167.00},size={21.00,15.00},disable=1,proc=DAP_DAorTTLCheckProc,title="2"
	CheckBox Check_TTL_02,userdata(tabnum)=  "3",userdata(tabcontrol)=  "ADC"
	CheckBox Check_TTL_02,userdata(ResizeControlsInfo)= A"!!,BY!!#A6!!#<`!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_TTL_02,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_TTL_02,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_TTL_02,value= 0
	CheckBox Check_TTL_03,pos={20.00,214.00},size={21.00,15.00},disable=1,proc=DAP_DAorTTLCheckProc,title="3"
	CheckBox Check_TTL_03,userdata(tabnum)=  "3",userdata(tabcontrol)=  "ADC"
	CheckBox Check_TTL_03,userdata(ResizeControlsInfo)= A"!!,BY!!#Ae!!#<`!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_TTL_03,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_TTL_03,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_TTL_03,value= 0
	CheckBox Check_TTL_04,pos={20.00,260.00},size={21.00,15.00},disable=1,proc=DAP_DAorTTLCheckProc,title="4"
	CheckBox Check_TTL_04,userdata(tabnum)=  "3",userdata(tabcontrol)=  "ADC"
	CheckBox Check_TTL_04,userdata(ResizeControlsInfo)= A"!!,BY!!#B<!!#<`!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_TTL_04,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_TTL_04,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_TTL_04,value= 0
	CheckBox Check_TTL_05,pos={20.00,307.00},size={21.00,15.00},disable=1,proc=DAP_DAorTTLCheckProc,title="5"
	CheckBox Check_TTL_05,userdata(tabnum)=  "3",userdata(tabcontrol)=  "ADC"
	CheckBox Check_TTL_05,userdata(ResizeControlsInfo)= A"!!,BY!!#BSJ,hm6!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_TTL_05,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_TTL_05,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_TTL_05,value= 0
	CheckBox Check_TTL_06,pos={20.00,353.00},size={21.00,15.00},disable=1,proc=DAP_DAorTTLCheckProc,title="6"
	CheckBox Check_TTL_06,userdata(tabnum)=  "3",userdata(tabcontrol)=  "ADC"
	CheckBox Check_TTL_06,userdata(ResizeControlsInfo)= A"!!,BY!!#BjJ,hm6!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_TTL_06,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_TTL_06,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_TTL_06,value= 0
	CheckBox Check_TTL_07,pos={20.00,400.00},size={21.00,15.00},disable=1,proc=DAP_DAorTTLCheckProc,title="7"
	CheckBox Check_TTL_07,userdata(tabnum)=  "3",userdata(tabcontrol)=  "ADC"
	CheckBox Check_TTL_07,userdata(ResizeControlsInfo)= A"!!,BY!!#C-!!#<`!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_TTL_07,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_TTL_07,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_TTL_07,value= 0
	PopupMenu Wave_TTL_00,pos={103.00,75.00},size={125.00,19.00},bodyWidth=125,disable=1,proc=DAP_PopMenuChkProc_StimSetList
	PopupMenu Wave_TTL_00,userdata(tabnum)=  "3",userdata(tabcontrol)=  "ADC"
	PopupMenu Wave_TTL_00,userdata(ResizeControlsInfo)= A"!!,F-!!#?O!!#@d!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Wave_TTL_00,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Wave_TTL_00,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Wave_TTL_00,mode=1,popvalue="- none -",value= #"\"- none -;\"+ReturnListOfAllStimSets(1,\"*TTL*\")"
	PopupMenu Wave_TTL_01,pos={103.00,121.00},size={125.00,19.00},bodyWidth=125,disable=1,proc=DAP_PopMenuChkProc_StimSetList
	PopupMenu Wave_TTL_01,userdata(tabnum)=  "3",userdata(tabcontrol)=  "ADC"
	PopupMenu Wave_TTL_01,userdata(ResizeControlsInfo)= A"!!,F-!!#@V!!#@d!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Wave_TTL_01,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Wave_TTL_01,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Wave_TTL_01,mode=1,popvalue="- none -",value= #"\"- none -;\"+ReturnListOfAllStimSets(1,\"*TTL*\")"
	PopupMenu Wave_TTL_02,pos={103.00,167.00},size={125.00,19.00},bodyWidth=125,disable=1,proc=DAP_PopMenuChkProc_StimSetList
	PopupMenu Wave_TTL_02,userdata(tabnum)=  "3",userdata(tabcontrol)=  "ADC"
	PopupMenu Wave_TTL_02,userdata(ResizeControlsInfo)= A"!!,F-!!#A6!!#@d!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Wave_TTL_02,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Wave_TTL_02,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Wave_TTL_02,mode=1,popvalue="- none -",value= #"\"- none -;\"+ReturnListOfAllStimSets(1,\"*TTL*\")"
	PopupMenu Wave_TTL_03,pos={103.00,214.00},size={125.00,19.00},bodyWidth=125,disable=1,proc=DAP_PopMenuChkProc_StimSetList
	PopupMenu Wave_TTL_03,userdata(tabnum)=  "3",userdata(tabcontrol)=  "ADC"
	PopupMenu Wave_TTL_03,userdata(ResizeControlsInfo)= A"!!,F-!!#Ae!!#@d!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Wave_TTL_03,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Wave_TTL_03,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Wave_TTL_03,mode=1,popvalue="- none -",value= #"\"- none -;\"+ReturnListOfAllStimSets(1,\"*TTL*\")"
	PopupMenu Wave_TTL_04,pos={103.00,260.00},size={125.00,19.00},bodyWidth=125,disable=1,proc=DAP_PopMenuChkProc_StimSetList
	PopupMenu Wave_TTL_04,userdata(tabnum)=  "3",userdata(tabcontrol)=  "ADC"
	PopupMenu Wave_TTL_04,userdata(ResizeControlsInfo)= A"!!,F-!!#B<!!#@d!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Wave_TTL_04,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Wave_TTL_04,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Wave_TTL_04,mode=1,popvalue="- none -",value= #"\"- none -;\"+ReturnListOfAllStimSets(1,\"*TTL*\")"
	PopupMenu Wave_TTL_05,pos={103.00,307.00},size={125.00,19.00},bodyWidth=125,disable=1,proc=DAP_PopMenuChkProc_StimSetList
	PopupMenu Wave_TTL_05,userdata(tabnum)=  "3",userdata(tabcontrol)=  "ADC"
	PopupMenu Wave_TTL_05,userdata(ResizeControlsInfo)= A"!!,F-!!#BSJ,hq:!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Wave_TTL_05,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Wave_TTL_05,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Wave_TTL_05,mode=1,popvalue="- none -",value= #"\"- none -;\"+ReturnListOfAllStimSets(1,\"*TTL*\")"
	PopupMenu Wave_TTL_06,pos={103.00,353.00},size={125.00,19.00},bodyWidth=125,disable=1,proc=DAP_PopMenuChkProc_StimSetList
	PopupMenu Wave_TTL_06,userdata(tabnum)=  "3",userdata(tabcontrol)=  "ADC"
	PopupMenu Wave_TTL_06,userdata(ResizeControlsInfo)= A"!!,F-!!#BjJ,hq:!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Wave_TTL_06,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Wave_TTL_06,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Wave_TTL_06,mode=1,popvalue="- none -",value= #"\"- none -;\"+ReturnListOfAllStimSets(1,\"*TTL*\")"
	PopupMenu Wave_TTL_07,pos={103.00,400.00},size={125.00,19.00},bodyWidth=125,disable=1,proc=DAP_PopMenuChkProc_StimSetList
	PopupMenu Wave_TTL_07,userdata(tabnum)=  "3",userdata(tabcontrol)=  "ADC"
	PopupMenu Wave_TTL_07,userdata(ResizeControlsInfo)= A"!!,F-!!#C-!!#@d!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Wave_TTL_07,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Wave_TTL_07,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Wave_TTL_07,mode=1,popvalue="- none -",value= #"\"- none -;\"+ReturnListOfAllStimSets(1,\"*TTL*\")"
	CheckBox Check_Settings_TrigOut,pos={34.00,263.00},size={59.00,15.00},disable=1,title="\\JCTrig Out"
	CheckBox Check_Settings_TrigOut,help={"Turns on TTL pulse at onset of sweep"}
	CheckBox Check_Settings_TrigOut,userdata(tabnum)=  "5"
	CheckBox Check_Settings_TrigOut,userdata(tabcontrol)=  "ADC"
	CheckBox Check_Settings_TrigOut,userdata(ResizeControlsInfo)= A"!!,Cl!!#B=J,hoP!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_Settings_TrigOut,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_Settings_TrigOut,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_Settings_TrigOut,fColor=(65280,43520,0),value= 0
	CheckBox Check_Settings_TrigIn,pos={34.00,287.00},size={49.00,15.00},disable=1,title="\\JCTrig In"
	CheckBox Check_Settings_TrigIn,help={"Starts Data Aquisition with TTL signal to trig in port on rack"}
	CheckBox Check_Settings_TrigIn,userdata(tabnum)=  "5"
	CheckBox Check_Settings_TrigIn,userdata(tabcontrol)=  "ADC"
	CheckBox Check_Settings_TrigIn,userdata(ResizeControlsInfo)= A"!!,Cl!!#BIJ,ho(!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_Settings_TrigIn,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_Settings_TrigIn,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_Settings_TrigIn,fColor=(65280,43520,0),value= 0
	SetVariable SetVar_DataAcq_SetRepeats,pos={39.00,680.00},size={107.00,18.00},bodyWidth=35,disable=1,proc=DAP_SetVarProc_TotSweepCount,title="Repeat Set(s)"
	SetVariable SetVar_DataAcq_SetRepeats,help={"This number is set automatically at based on the number of 1d waves contained in the largest set on active DA/TTL channels"}
	SetVariable SetVar_DataAcq_SetRepeats,userdata(tabnum)=  "0"
	SetVariable SetVar_DataAcq_SetRepeats,userdata(tabcontrol)=  "ADC"
	SetVariable SetVar_DataAcq_SetRepeats,userdata(ResizeControlsInfo)= A"!!,Ds!!#D:!!#@:!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_DataAcq_SetRepeats,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_DataAcq_SetRepeats,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_DataAcq_SetRepeats,limits={1,inf,1},value= _NUM:1
	ValDisplay ValDisp_DataAcq_SamplingInt,pos={235.00,574.00},size={30.00,21.00},bodyWidth=30,disable=1
	ValDisplay ValDisp_DataAcq_SamplingInt,userdata(tabnum)=  "0"
	ValDisplay ValDisp_DataAcq_SamplingInt,userdata(tabcontrol)=  "ADC"
	ValDisplay ValDisp_DataAcq_SamplingInt,userdata(ResizeControlsInfo)= A"!!,H&!!#CtJ,hn)!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	ValDisplay ValDisp_DataAcq_SamplingInt,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	ValDisplay ValDisp_DataAcq_SamplingInt,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	ValDisplay ValDisp_DataAcq_SamplingInt,fSize=14,fStyle=0
	ValDisplay ValDisp_DataAcq_SamplingInt,valueColor=(65535,65535,65535)
	ValDisplay ValDisp_DataAcq_SamplingInt,valueBackColor=(0,0,0)
	ValDisplay ValDisp_DataAcq_SamplingInt,limits={0,0,0},barmisc={0,1000}
	ValDisplay ValDisp_DataAcq_SamplingInt,value= _NUM:0
	SetVariable SetVar_Sweep,pos={217.00,532.00},size={75.00,35.00},bodyWidth=75,disable=1,proc=DAP_SetVarProc_NextSweepLimit
	SetVariable SetVar_Sweep,userdata(tabnum)=  "0",userdata(tabcontrol)=  "ADC"
	SetVariable SetVar_Sweep,userdata(ResizeControlsInfo)= A"!!,Gi!!#Cj!!#?O!!#=oz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_Sweep,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_Sweep,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_Sweep,fSize=24,fStyle=1,valueColor=(65535,65535,65535)
	SetVariable SetVar_Sweep,valueBackColor=(0,0,0),limits={0,0,1},value= _NUM:0
	CheckBox Check_Settings_UseDoublePrec,pos={243.00,218.00},size={160.00,15.00},disable=1,title="Use Double Precision Floats"
	CheckBox Check_Settings_UseDoublePrec,help={"Enable the saving of the raw data in double precision. If unchecked the raw data will be saved in single precision, which should be good enough for most use cases"}
	CheckBox Check_Settings_UseDoublePrec,userdata(tabnum)=  "5"
	CheckBox Check_Settings_UseDoublePrec,userdata(tabcontrol)=  "ADC"
	CheckBox Check_Settings_UseDoublePrec,userdata(ResizeControlsInfo)= A"!!,H.!!#Ai!!#A/!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_Settings_UseDoublePrec,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_Settings_UseDoublePrec,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_Settings_UseDoublePrec,value= 0
	CheckBox Check_Settings_SkipAnalysFuncs,pos={243.00,268.00},size={155.00,15.00},disable=1,title="Skip analysis function calls"
	CheckBox Check_Settings_SkipAnalysFuncs,help={"Should the analysis functions defined in the stim sets not be called? Mostly useful for testing/debugging."}
	CheckBox Check_Settings_SkipAnalysFuncs,userdata(tabnum)=  "5"
	CheckBox Check_Settings_SkipAnalysFuncs,userdata(tabcontrol)=  "ADC"
	CheckBox Check_Settings_SkipAnalysFuncs,userdata(ResizeControlsInfo)= A"!!,H.!!#B@!!#A*!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_Settings_SkipAnalysFuncs,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_Settings_SkipAnalysFuncs,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_Settings_SkipAnalysFuncs,value= 0
	CheckBox Check_AsyncAD_00,pos={172.00,46.00},size={40.00,15.00},disable=1,title="AD 0"
	CheckBox Check_AsyncAD_00,userdata(tabnum)=  "4",userdata(tabcontrol)=  "ADC"
	CheckBox Check_AsyncAD_00,userdata(ResizeControlsInfo)= A"!!,G<!!#>F!!#>.!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_AsyncAD_00,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_AsyncAD_00,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_AsyncAD_00,value= 0
	CheckBox Check_AsyncAD_01,pos={171.00,97.00},size={40.00,15.00},disable=1,title="AD 1"
	CheckBox Check_AsyncAD_01,userdata(tabnum)=  "4",userdata(tabcontrol)=  "ADC"
	CheckBox Check_AsyncAD_01,userdata(ResizeControlsInfo)= A"!!,G;!!#@&!!#>.!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_AsyncAD_01,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_AsyncAD_01,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_AsyncAD_01,value= 0
	CheckBox Check_AsyncAD_02,pos={171.00,148.00},size={40.00,15.00},disable=1,title="AD 2"
	CheckBox Check_AsyncAD_02,userdata(tabnum)=  "4",userdata(tabcontrol)=  "ADC"
	CheckBox Check_AsyncAD_02,userdata(ResizeControlsInfo)= A"!!,G;!!#A#!!#>.!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_AsyncAD_02,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_AsyncAD_02,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_AsyncAD_02,value= 0
	CheckBox Check_AsyncAD_03,pos={171.00,199.00},size={40.00,15.00},disable=1,title="AD 3"
	CheckBox Check_AsyncAD_03,userdata(tabnum)=  "4",userdata(tabcontrol)=  "ADC"
	CheckBox Check_AsyncAD_03,userdata(ResizeControlsInfo)= A"!!,G;!!#AV!!#>.!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_AsyncAD_03,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_AsyncAD_03,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_AsyncAD_03,value= 0
	CheckBox Check_AsyncAD_04,pos={171.00,250.00},size={40.00,15.00},disable=1,title="AD 4"
	CheckBox Check_AsyncAD_04,userdata(tabnum)=  "4",userdata(tabcontrol)=  "ADC"
	CheckBox Check_AsyncAD_04,userdata(ResizeControlsInfo)= A"!!,G;!!#B4!!#>.!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_AsyncAD_04,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_AsyncAD_04,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_AsyncAD_04,value= 0
	CheckBox Check_AsyncAD_05,pos={171.00,301.00},size={40.00,15.00},disable=1,title="AD 5"
	CheckBox Check_AsyncAD_05,userdata(tabnum)=  "4",userdata(tabcontrol)=  "ADC"
	CheckBox Check_AsyncAD_05,userdata(ResizeControlsInfo)= A"!!,G;!!#BPJ,hnY!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_AsyncAD_05,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_AsyncAD_05,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_AsyncAD_05,value= 0
	CheckBox Check_AsyncAD_06,pos={171.00,352.00},size={40.00,15.00},disable=1,title="AD 6"
	CheckBox Check_AsyncAD_06,userdata(tabnum)=  "4",userdata(tabcontrol)=  "ADC"
	CheckBox Check_AsyncAD_06,userdata(ResizeControlsInfo)= A"!!,G;!!#Bj!!#>.!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_AsyncAD_06,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_AsyncAD_06,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_AsyncAD_06,value= 0
	CheckBox Check_AsyncAD_07,pos={171.00,404.00},size={40.00,15.00},disable=1,title="AD 7"
	CheckBox Check_AsyncAD_07,userdata(tabnum)=  "4",userdata(tabcontrol)=  "ADC"
	CheckBox Check_AsyncAD_07,userdata(ResizeControlsInfo)= A"!!,G;!!#C/!!#>.!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_AsyncAD_07,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_AsyncAD_07,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_AsyncAD_07,value= 0
	SetVariable Gain_AsyncAD_00,pos={224.00,44.00},size={77.00,18.00},bodyWidth=50,disable=1,title="gain"
	SetVariable Gain_AsyncAD_00,userdata(tabnum)=  "4"
	SetVariable Gain_AsyncAD_00,userdata(tabcontrol)=  "ADC"
	SetVariable Gain_AsyncAD_00,userdata(ResizeControlsInfo)= A"!!,Gp!!#>>!!#?S!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Gain_AsyncAD_00,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Gain_AsyncAD_00,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Gain_AsyncAD_00,limits={0,inf,1},value= _NUM:1
	SetVariable Gain_AsyncAD_01,pos={224.00,95.00},size={77.00,18.00},bodyWidth=50,disable=1,title="gain"
	SetVariable Gain_AsyncAD_01,userdata(tabnum)=  "4"
	SetVariable Gain_AsyncAD_01,userdata(tabcontrol)=  "ADC"
	SetVariable Gain_AsyncAD_01,userdata(ResizeControlsInfo)= A"!!,Gp!!#@\"!!#?S!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Gain_AsyncAD_01,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Gain_AsyncAD_01,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Gain_AsyncAD_01,limits={0,inf,1},value= _NUM:1
	SetVariable Gain_AsyncAD_02,pos={224.00,146.00},size={77.00,18.00},bodyWidth=50,disable=1,title="gain"
	SetVariable Gain_AsyncAD_02,userdata(tabnum)=  "4"
	SetVariable Gain_AsyncAD_02,userdata(tabcontrol)=  "ADC"
	SetVariable Gain_AsyncAD_02,userdata(ResizeControlsInfo)= A"!!,Gp!!#A!!!#?S!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Gain_AsyncAD_02,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Gain_AsyncAD_02,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Gain_AsyncAD_02,limits={0,inf,1},value= _NUM:1
	SetVariable Gain_AsyncAD_03,pos={224.00,197.00},size={77.00,18.00},bodyWidth=50,disable=1,title="gain"
	SetVariable Gain_AsyncAD_03,userdata(tabnum)=  "4"
	SetVariable Gain_AsyncAD_03,userdata(tabcontrol)=  "ADC"
	SetVariable Gain_AsyncAD_03,userdata(ResizeControlsInfo)= A"!!,Gp!!#AT!!#?S!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Gain_AsyncAD_03,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Gain_AsyncAD_03,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Gain_AsyncAD_03,limits={0,inf,1},value= _NUM:1
	SetVariable Gain_AsyncAD_04,pos={224.00,248.00},size={77.00,18.00},bodyWidth=50,disable=1,title="gain"
	SetVariable Gain_AsyncAD_04,userdata(tabnum)=  "4"
	SetVariable Gain_AsyncAD_04,userdata(tabcontrol)=  "ADC"
	SetVariable Gain_AsyncAD_04,userdata(ResizeControlsInfo)= A"!!,Gp!!#B2!!#?S!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Gain_AsyncAD_04,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Gain_AsyncAD_04,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Gain_AsyncAD_04,limits={0,inf,1},value= _NUM:1
	SetVariable Gain_AsyncAD_05,pos={224.00,299.00},size={77.00,18.00},bodyWidth=50,disable=1,title="gain"
	SetVariable Gain_AsyncAD_05,userdata(tabnum)=  "4"
	SetVariable Gain_AsyncAD_05,userdata(tabcontrol)=  "ADC"
	SetVariable Gain_AsyncAD_05,userdata(ResizeControlsInfo)= A"!!,Gp!!#BOJ,hp)!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Gain_AsyncAD_05,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Gain_AsyncAD_05,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Gain_AsyncAD_05,limits={0,inf,1},value= _NUM:1
	SetVariable Gain_AsyncAD_06,pos={224.00,350.00},size={77.00,18.00},bodyWidth=50,disable=1,title="gain"
	SetVariable Gain_AsyncAD_06,userdata(tabnum)=  "4"
	SetVariable Gain_AsyncAD_06,userdata(tabcontrol)=  "ADC"
	SetVariable Gain_AsyncAD_06,userdata(ResizeControlsInfo)= A"!!,Gp!!#Bi!!#?S!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Gain_AsyncAD_06,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Gain_AsyncAD_06,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Gain_AsyncAD_06,limits={0,inf,1},value= _NUM:1
	SetVariable Gain_AsyncAD_07,pos={224.00,402.00},size={77.00,18.00},bodyWidth=50,disable=1,title="gain"
	SetVariable Gain_AsyncAD_07,userdata(tabnum)=  "4"
	SetVariable Gain_AsyncAD_07,userdata(tabcontrol)=  "ADC"
	SetVariable Gain_AsyncAD_07,userdata(ResizeControlsInfo)= A"!!,Gp!!#C.!!#?S!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Gain_AsyncAD_07,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Gain_AsyncAD_07,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Gain_AsyncAD_07,limits={0,inf,1},value= _NUM:1
	SetVariable SetVar_AsyncAD_Title_00,pos={14.00,44.00},size={150.00,18.00},disable=1,title="Title"
	SetVariable SetVar_AsyncAD_Title_00,userdata(tabnum)=  "4"
	SetVariable SetVar_AsyncAD_Title_00,userdata(tabcontrol)=  "ADC"
	SetVariable SetVar_AsyncAD_Title_00,userdata(ResizeControlsInfo)= A"!!,An!!#>>!!#A%!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_AsyncAD_Title_00,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_AsyncAD_Title_00,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_AsyncAD_Title_00,value= _STR:""
	SetVariable SetVar_AsyncAD_Title_01,pos={14.00,95.00},size={150.00,18.00},disable=1,title="Title"
	SetVariable SetVar_AsyncAD_Title_01,userdata(tabnum)=  "4"
	SetVariable SetVar_AsyncAD_Title_01,userdata(tabcontrol)=  "ADC"
	SetVariable SetVar_AsyncAD_Title_01,userdata(ResizeControlsInfo)= A"!!,An!!#@\"!!#A%!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_AsyncAD_Title_01,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_AsyncAD_Title_01,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_AsyncAD_Title_01,value= _STR:""
	SetVariable SetVar_AsyncAD_Title_02,pos={14.00,146.00},size={150.00,18.00},disable=1,title="Title"
	SetVariable SetVar_AsyncAD_Title_02,userdata(tabnum)=  "4"
	SetVariable SetVar_AsyncAD_Title_02,userdata(tabcontrol)=  "ADC"
	SetVariable SetVar_AsyncAD_Title_02,userdata(ResizeControlsInfo)= A"!!,An!!#A!!!#A%!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_AsyncAD_Title_02,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_AsyncAD_Title_02,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_AsyncAD_Title_02,value= _STR:""
	SetVariable SetVar_AsyncAD_Title_03,pos={14.00,197.00},size={150.00,18.00},disable=1,title="Title"
	SetVariable SetVar_AsyncAD_Title_03,userdata(tabnum)=  "4"
	SetVariable SetVar_AsyncAD_Title_03,userdata(tabcontrol)=  "ADC"
	SetVariable SetVar_AsyncAD_Title_03,userdata(ResizeControlsInfo)= A"!!,An!!#AT!!#A%!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_AsyncAD_Title_03,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_AsyncAD_Title_03,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_AsyncAD_Title_03,value= _STR:""
	SetVariable SetVar_AsyncAD_Title_04,pos={11.00,248.00},size={150.00,18.00},disable=1,title="Title"
	SetVariable SetVar_AsyncAD_Title_04,userdata(tabnum)=  "4"
	SetVariable SetVar_AsyncAD_Title_04,userdata(tabcontrol)=  "ADC"
	SetVariable SetVar_AsyncAD_Title_04,userdata(ResizeControlsInfo)= A"!!,A>!!#B2!!#A%!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_AsyncAD_Title_04,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_AsyncAD_Title_04,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_AsyncAD_Title_04,value= _STR:""
	SetVariable SetVar_AsyncAD_Title_05,pos={14.00,299.00},size={150.00,18.00},disable=1,title="Title"
	SetVariable SetVar_AsyncAD_Title_05,userdata(tabnum)=  "4"
	SetVariable SetVar_AsyncAD_Title_05,userdata(tabcontrol)=  "ADC"
	SetVariable SetVar_AsyncAD_Title_05,userdata(ResizeControlsInfo)= A"!!,An!!#BOJ,hqP!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_AsyncAD_Title_05,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_AsyncAD_Title_05,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_AsyncAD_Title_05,value= _STR:""
	SetVariable SetVar_AsyncAD_Title_06,pos={14.00,350.00},size={150.00,18.00},disable=1,title="Title"
	SetVariable SetVar_AsyncAD_Title_06,userdata(tabnum)=  "4"
	SetVariable SetVar_AsyncAD_Title_06,userdata(tabcontrol)=  "ADC"
	SetVariable SetVar_AsyncAD_Title_06,userdata(ResizeControlsInfo)= A"!!,An!!#Bi!!#A%!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_AsyncAD_Title_06,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_AsyncAD_Title_06,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_AsyncAD_Title_06,value= _STR:""
	SetVariable SetVar_AsyncAD_Title_07,pos={14.00,402.00},size={150.00,18.00},disable=1,title="Title"
	SetVariable SetVar_AsyncAD_Title_07,userdata(tabnum)=  "4"
	SetVariable SetVar_AsyncAD_Title_07,userdata(tabcontrol)=  "ADC"
	SetVariable SetVar_AsyncAD_Title_07,userdata(ResizeControlsInfo)= A"!!,An!!#C.!!#A%!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_AsyncAD_Title_07,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_AsyncAD_Title_07,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_AsyncAD_Title_07,value= _STR:""
	SetVariable Unit_AsyncAD_00,pos={315.00,44.00},size={75.00,18.00},disable=1,title="Unit"
	SetVariable Unit_AsyncAD_00,userdata(tabnum)=  "4"
	SetVariable Unit_AsyncAD_00,userdata(tabcontrol)=  "ADC"
	SetVariable Unit_AsyncAD_00,userdata(ResizeControlsInfo)= A"!!,HXJ,hni!!#?O!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Unit_AsyncAD_00,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Unit_AsyncAD_00,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Unit_AsyncAD_00,value= _STR:""
	SetVariable Unit_AsyncAD_01,pos={315.00,95.00},size={75.00,18.00},disable=1,title="Unit"
	SetVariable Unit_AsyncAD_01,userdata(tabnum)=  "4"
	SetVariable Unit_AsyncAD_01,userdata(tabcontrol)=  "ADC"
	SetVariable Unit_AsyncAD_01,userdata(ResizeControlsInfo)= A"!!,HXJ,hpM!!#?O!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Unit_AsyncAD_01,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Unit_AsyncAD_01,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Unit_AsyncAD_01,value= _STR:""
	SetVariable Unit_AsyncAD_02,pos={315.00,146.00},size={75.00,18.00},disable=1,title="Unit"
	SetVariable Unit_AsyncAD_02,userdata(tabnum)=  "4"
	SetVariable Unit_AsyncAD_02,userdata(tabcontrol)=  "ADC"
	SetVariable Unit_AsyncAD_02,userdata(ResizeControlsInfo)= A"!!,HXJ,hqL!!#?O!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Unit_AsyncAD_02,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Unit_AsyncAD_02,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Unit_AsyncAD_02,value= _STR:""
	SetVariable Unit_AsyncAD_03,pos={315.00,197.00},size={75.00,18.00},disable=1,title="Unit"
	SetVariable Unit_AsyncAD_03,userdata(tabnum)=  "4"
	SetVariable Unit_AsyncAD_03,userdata(tabcontrol)=  "ADC"
	SetVariable Unit_AsyncAD_03,userdata(ResizeControlsInfo)= A"!!,HXJ,hr*!!#?O!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Unit_AsyncAD_03,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Unit_AsyncAD_03,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Unit_AsyncAD_03,value= _STR:""
	SetVariable Unit_AsyncAD_04,pos={315.00,248.00},size={75.00,18.00},disable=1,title="Unit"
	SetVariable Unit_AsyncAD_04,userdata(tabnum)=  "4"
	SetVariable Unit_AsyncAD_04,userdata(tabcontrol)=  "ADC"
	SetVariable Unit_AsyncAD_04,userdata(ResizeControlsInfo)= A"!!,HXJ,hr]!!#?O!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Unit_AsyncAD_04,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Unit_AsyncAD_04,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Unit_AsyncAD_04,value= _STR:""
	SetVariable Unit_AsyncAD_05,pos={315.00,298.00},size={75.00,18.00},disable=1,title="Unit"
	SetVariable Unit_AsyncAD_05,userdata(tabnum)=  "4"
	SetVariable Unit_AsyncAD_05,userdata(tabcontrol)=  "ADC"
	SetVariable Unit_AsyncAD_05,userdata(ResizeControlsInfo)= A"!!,HXJ,hs%!!#?O!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Unit_AsyncAD_05,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Unit_AsyncAD_05,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Unit_AsyncAD_05,value= _STR:""
	SetVariable Unit_AsyncAD_06,pos={315.00,350.00},size={75.00,18.00},disable=1,title="Unit"
	SetVariable Unit_AsyncAD_06,userdata(tabnum)=  "4"
	SetVariable Unit_AsyncAD_06,userdata(tabcontrol)=  "ADC"
	SetVariable Unit_AsyncAD_06,userdata(ResizeControlsInfo)= A"!!,HXJ,hs?!!#?O!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Unit_AsyncAD_06,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Unit_AsyncAD_06,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Unit_AsyncAD_06,value= _STR:""
	SetVariable Unit_AsyncAD_07,pos={315.00,402.00},size={75.00,18.00},disable=1,title="Unit"
	SetVariable Unit_AsyncAD_07,userdata(tabnum)=  "4"
	SetVariable Unit_AsyncAD_07,userdata(tabcontrol)=  "ADC"
	SetVariable Unit_AsyncAD_07,userdata(ResizeControlsInfo)= A"!!,HXJ,hsY!!#?O!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Unit_AsyncAD_07,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Unit_AsyncAD_07,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Unit_AsyncAD_07,value= _STR:""
	CheckBox Check_Settings_Append,pos={34.00,452.00},size={243.00,15.00},disable=1,title="\\JCAppend Asynchronus reading to wave note"
	CheckBox Check_Settings_Append,help={"Turns on TTL pulse at onset of sweep"}
	CheckBox Check_Settings_Append,userdata(tabnum)=  "5"
	CheckBox Check_Settings_Append,userdata(tabcontrol)=  "ADC"
	CheckBox Check_Settings_Append,userdata(ResizeControlsInfo)= A"!!,Cl!!#CG!!#B-!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_Settings_Append,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_Settings_Append,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_Settings_Append,value= 0
	CheckBox Check_Settings_BkgTP,pos={34.00,86.00},size={96.00,15.00},disable=1,title="Background TP"
	CheckBox Check_Settings_BkgTP,help={"Perform testpulse in the background, keeping the GUI responsive."}
	CheckBox Check_Settings_BkgTP,userdata(tabnum)=  "5"
	CheckBox Check_Settings_BkgTP,userdata(tabcontrol)=  "ADC"
	CheckBox Check_Settings_BkgTP,userdata(ResizeControlsInfo)= A"!!,Cl!!#?e!!#@$!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_Settings_BkgTP,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_Settings_BkgTP,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_Settings_BkgTP,value= 1
	CheckBox Check_Settings_BackgrndDataAcq,pos={34.00,193.00},size={169.00,15.00},disable=1,title="Background Data Acquisition"
	CheckBox Check_Settings_BackgrndDataAcq,help={"Perform data acquisition in the background, keeping the GUI responsive."}
	CheckBox Check_Settings_BackgrndDataAcq,userdata(tabnum)=  "5"
	CheckBox Check_Settings_BackgrndDataAcq,userdata(tabcontrol)=  "ADC"
	CheckBox Check_Settings_BackgrndDataAcq,userdata(ResizeControlsInfo)= A"!!,Cl!!#AP!!#A8!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_Settings_BackgrndDataAcq,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_Settings_BackgrndDataAcq,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_Settings_BackgrndDataAcq,value= 1
	CheckBox Radio_ClampMode_0,pos={145.00,62.00},size={13.00,13.00},disable=1,proc=DAP_CheckProc_ClampMode,title=""
	CheckBox Radio_ClampMode_0,userdata(tabnum)=  "0",userdata(tabcontrol)=  "ADC"
	CheckBox Radio_ClampMode_0,userdata(ResizeControlsInfo)= A"!!,G!!!#?1!!#;]!!#;]z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Radio_ClampMode_0,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Radio_ClampMode_0,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Radio_ClampMode_0,value= 1,mode=1
	TitleBox Title_DataAcq_VC,pos={59.00,60.00},size={78.00,15.00},disable=1,title="Voltage Clamp"
	TitleBox Title_DataAcq_VC,userdata(tabnum)=  "0",userdata(tabcontrol)=  "ADC"
	TitleBox Title_DataAcq_VC,userdata(ResizeControlsInfo)= A"!!,E&!!#?)!!#?U!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox Title_DataAcq_VC,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	TitleBox Title_DataAcq_VC,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	TitleBox Title_DataAcq_VC,frame=0
	TitleBox Title_DataAcq_IC,pos={59.00,109.00},size={78.00,15.00},disable=1,title="Current Clamp"
	TitleBox Title_DataAcq_IC,userdata(tabnum)=  "0",userdata(tabcontrol)=  "ADC"
	TitleBox Title_DataAcq_IC,userdata(ResizeControlsInfo)= A"!!,E&!!#@>!!#?U!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox Title_DataAcq_IC,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	TitleBox Title_DataAcq_IC,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	TitleBox Title_DataAcq_IC,frame=0
	TitleBox Title_DataAcq_CellSelection,pos={74.00,85.00},size={56.00,15.00},disable=1,title="Headstage"
	TitleBox Title_DataAcq_CellSelection,userdata(tabnum)=  "0"
	TitleBox Title_DataAcq_CellSelection,userdata(tabcontrol)=  "ADC"
	TitleBox Title_DataAcq_CellSelection,userdata(ResizeControlsInfo)= A"!!,EN!!#?c!!#>n!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox Title_DataAcq_CellSelection,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	TitleBox Title_DataAcq_CellSelection,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	TitleBox Title_DataAcq_CellSelection,frame=0
	CheckBox Check_DataAcqHS_01,pos={178.00,86.00},size={21.00,15.00},disable=1,proc=DAP_CheckProc_HedstgeChck,title="1"
	CheckBox Check_DataAcqHS_01,userdata(tabnum)=  "0",userdata(tabcontrol)=  "ADC"
	CheckBox Check_DataAcqHS_01,userdata(ResizeControlsInfo)= A"!!,GB!!#?e!!#<`!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_DataAcqHS_01,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_DataAcqHS_01,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_DataAcqHS_01,value= 0
	CheckBox Check_DataAcqHS_02,pos={212.00,86.00},size={21.00,15.00},disable=1,proc=DAP_CheckProc_HedstgeChck,title="2"
	CheckBox Check_DataAcqHS_02,userdata(tabnum)=  "0",userdata(tabcontrol)=  "ADC"
	CheckBox Check_DataAcqHS_02,userdata(ResizeControlsInfo)= A"!!,Gd!!#?e!!#<`!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_DataAcqHS_02,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_DataAcqHS_02,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_DataAcqHS_02,value= 0
	CheckBox Check_DataAcqHS_03,pos={246.00,86.00},size={21.00,15.00},disable=1,proc=DAP_CheckProc_HedstgeChck,title="3"
	CheckBox Check_DataAcqHS_03,userdata(tabnum)=  "0",userdata(tabcontrol)=  "ADC"
	CheckBox Check_DataAcqHS_03,userdata(ResizeControlsInfo)= A"!!,H1!!#?e!!#<`!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_DataAcqHS_03,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_DataAcqHS_03,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_DataAcqHS_03,value= 0
	CheckBox Check_DataAcqHS_04,pos={280.00,86.00},size={21.00,15.00},disable=1,proc=DAP_CheckProc_HedstgeChck,title="4"
	CheckBox Check_DataAcqHS_04,userdata(tabnum)=  "0",userdata(tabcontrol)=  "ADC"
	CheckBox Check_DataAcqHS_04,userdata(ResizeControlsInfo)= A"!!,HG!!#?e!!#<`!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_DataAcqHS_04,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_DataAcqHS_04,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_DataAcqHS_04,value= 0
	CheckBox Check_DataAcqHS_05,pos={314.00,86.00},size={21.00,15.00},disable=1,proc=DAP_CheckProc_HedstgeChck,title="5"
	CheckBox Check_DataAcqHS_05,userdata(tabnum)=  "0",userdata(tabcontrol)=  "ADC"
	CheckBox Check_DataAcqHS_05,userdata(ResizeControlsInfo)= A"!!,HX!!#?e!!#<`!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_DataAcqHS_05,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_DataAcqHS_05,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_DataAcqHS_05,value= 0
	CheckBox Check_DataAcqHS_06,pos={348.00,86.00},size={21.00,15.00},disable=1,proc=DAP_CheckProc_HedstgeChck,title="6"
	CheckBox Check_DataAcqHS_06,userdata(tabnum)=  "0",userdata(tabcontrol)=  "ADC"
	CheckBox Check_DataAcqHS_06,userdata(ResizeControlsInfo)= A"!!,Hi!!#?e!!#<`!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_DataAcqHS_06,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_DataAcqHS_06,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_DataAcqHS_06,value= 0
	CheckBox Check_DataAcqHS_07,pos={382.00,85.00},size={21.00,15.00},disable=1,proc=DAP_CheckProc_HedstgeChck,title="7"
	CheckBox Check_DataAcqHS_07,userdata(tabnum)=  "0",userdata(tabcontrol)=  "ADC"
	CheckBox Check_DataAcqHS_07,userdata(ResizeControlsInfo)= A"!!,I%!!#?c!!#<`!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_DataAcqHS_07,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_DataAcqHS_07,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_DataAcqHS_07,value= 0
	CheckBox Radio_ClampMode_1,pos={145.00,111.00},size={13.00,13.00},disable=1,proc=DAP_CheckProc_ClampMode,title=""
	CheckBox Radio_ClampMode_1,userdata(tabnum)=  "0",userdata(tabcontrol)=  "ADC"
	CheckBox Radio_ClampMode_1,userdata(ResizeControlsInfo)= A"!!,G!!!#@B!!#;]!!#;]z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Radio_ClampMode_1,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Radio_ClampMode_1,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Radio_ClampMode_1,value= 0,mode=1
	CheckBox Radio_ClampMode_2,pos={178.00,62.00},size={13.00,13.00},disable=1,proc=DAP_CheckProc_ClampMode,title=""
	CheckBox Radio_ClampMode_2,userdata(tabnum)=  "0",userdata(tabcontrol)=  "ADC"
	CheckBox Radio_ClampMode_2,userdata(ResizeControlsInfo)= A"!!,GB!!#?1!!#;]!!#;]z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Radio_ClampMode_2,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Radio_ClampMode_2,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Radio_ClampMode_2,value= 1,mode=1
	CheckBox Radio_ClampMode_3,pos={178.00,111.00},size={13.00,13.00},disable=1,proc=DAP_CheckProc_ClampMode,title=""
	CheckBox Radio_ClampMode_3,userdata(tabnum)=  "0",userdata(tabcontrol)=  "ADC"
	CheckBox Radio_ClampMode_3,userdata(ResizeControlsInfo)= A"!!,GB!!#@B!!#;]!!#;]z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Radio_ClampMode_3,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Radio_ClampMode_3,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Radio_ClampMode_3,value= 0,mode=1
	CheckBox Radio_ClampMode_4,pos={212.00,62.00},size={13.00,13.00},disable=1,proc=DAP_CheckProc_ClampMode,title=""
	CheckBox Radio_ClampMode_4,userdata(tabnum)=  "0",userdata(tabcontrol)=  "ADC"
	CheckBox Radio_ClampMode_4,userdata(ResizeControlsInfo)= A"!!,Gd!!#?1!!#;]!!#;]z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Radio_ClampMode_4,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Radio_ClampMode_4,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Radio_ClampMode_4,value= 1,mode=1
	CheckBox Radio_ClampMode_5,pos={212.00,111.00},size={13.00,13.00},disable=1,proc=DAP_CheckProc_ClampMode,title=""
	CheckBox Radio_ClampMode_5,userdata(tabnum)=  "0",userdata(tabcontrol)=  "ADC"
	CheckBox Radio_ClampMode_5,userdata(ResizeControlsInfo)= A"!!,Gd!!#@B!!#;]!!#;]z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Radio_ClampMode_5,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Radio_ClampMode_5,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Radio_ClampMode_5,value= 0,mode=1
	CheckBox Radio_ClampMode_6,pos={246.00,62.00},size={13.00,13.00},disable=1,proc=DAP_CheckProc_ClampMode,title=""
	CheckBox Radio_ClampMode_6,userdata(tabnum)=  "0",userdata(tabcontrol)=  "ADC"
	CheckBox Radio_ClampMode_6,userdata(ResizeControlsInfo)= A"!!,H1!!#?1!!#;]!!#;]z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Radio_ClampMode_6,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Radio_ClampMode_6,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Radio_ClampMode_6,value= 1,mode=1
	CheckBox Radio_ClampMode_7,pos={246.00,111.00},size={13.00,13.00},disable=1,proc=DAP_CheckProc_ClampMode,title=""
	CheckBox Radio_ClampMode_7,userdata(tabnum)=  "0",userdata(tabcontrol)=  "ADC"
	CheckBox Radio_ClampMode_7,userdata(ResizeControlsInfo)= A"!!,H1!!#@B!!#;]!!#;]z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Radio_ClampMode_7,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Radio_ClampMode_7,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Radio_ClampMode_7,value= 0,mode=1
	CheckBox Radio_ClampMode_8,pos={280.00,62.00},size={13.00,13.00},disable=1,proc=DAP_CheckProc_ClampMode,title=""
	CheckBox Radio_ClampMode_8,userdata(tabnum)=  "0",userdata(tabcontrol)=  "ADC"
	CheckBox Radio_ClampMode_8,userdata(ResizeControlsInfo)= A"!!,HG!!#?1!!#;]!!#;]z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Radio_ClampMode_8,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Radio_ClampMode_8,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Radio_ClampMode_8,value= 1,mode=1
	CheckBox Radio_ClampMode_9,pos={280.00,111.00},size={13.00,13.00},disable=1,proc=DAP_CheckProc_ClampMode,title=""
	CheckBox Radio_ClampMode_9,userdata(tabnum)=  "0",userdata(tabcontrol)=  "ADC"
	CheckBox Radio_ClampMode_9,userdata(ResizeControlsInfo)= A"!!,HG!!#@B!!#;]!!#;]z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Radio_ClampMode_9,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Radio_ClampMode_9,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Radio_ClampMode_9,value= 0,mode=1
	CheckBox Radio_ClampMode_10,pos={314.00,62.00},size={13.00,13.00},disable=1,proc=DAP_CheckProc_ClampMode,title=""
	CheckBox Radio_ClampMode_10,userdata(tabnum)=  "0",userdata(tabcontrol)=  "ADC"
	CheckBox Radio_ClampMode_10,userdata(ResizeControlsInfo)= A"!!,HX!!#?1!!#;]!!#;]z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Radio_ClampMode_10,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Radio_ClampMode_10,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Radio_ClampMode_10,value= 1,mode=1
	CheckBox Radio_ClampMode_11,pos={314.00,111.00},size={13.00,13.00},disable=1,proc=DAP_CheckProc_ClampMode,title=""
	CheckBox Radio_ClampMode_11,userdata(tabnum)=  "0",userdata(tabcontrol)=  "ADC"
	CheckBox Radio_ClampMode_11,userdata(ResizeControlsInfo)= A"!!,HX!!#@B!!#;]!!#;]z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Radio_ClampMode_11,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Radio_ClampMode_11,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Radio_ClampMode_11,value= 0,mode=1
	CheckBox Radio_ClampMode_12,pos={348.00,62.00},size={13.00,13.00},disable=1,proc=DAP_CheckProc_ClampMode,title=""
	CheckBox Radio_ClampMode_12,userdata(tabnum)=  "0",userdata(tabcontrol)=  "ADC"
	CheckBox Radio_ClampMode_12,userdata(ResizeControlsInfo)= A"!!,Hi!!#?1!!#;]!!#;]z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Radio_ClampMode_12,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Radio_ClampMode_12,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Radio_ClampMode_12,value= 1,mode=1
	CheckBox Radio_ClampMode_13,pos={348.00,111.00},size={13.00,13.00},disable=1,proc=DAP_CheckProc_ClampMode,title=""
	CheckBox Radio_ClampMode_13,userdata(tabnum)=  "0",userdata(tabcontrol)=  "ADC"
	CheckBox Radio_ClampMode_13,userdata(ResizeControlsInfo)= A"!!,Hi!!#@B!!#;]!!#;]z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Radio_ClampMode_13,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Radio_ClampMode_13,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Radio_ClampMode_13,value= 0,mode=1
	CheckBox Radio_ClampMode_14,pos={382.00,62.00},size={13.00,13.00},disable=1,proc=DAP_CheckProc_ClampMode,title=""
	CheckBox Radio_ClampMode_14,userdata(tabnum)=  "0",userdata(tabcontrol)=  "ADC"
	CheckBox Radio_ClampMode_14,userdata(ResizeControlsInfo)= A"!!,I%!!#?1!!#;]!!#;]z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Radio_ClampMode_14,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Radio_ClampMode_14,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Radio_ClampMode_14,value= 1,mode=1
	CheckBox Radio_ClampMode_15,pos={382.00,111.00},size={13.00,13.00},disable=1,proc=DAP_CheckProc_ClampMode,title=""
	CheckBox Radio_ClampMode_15,userdata(tabnum)=  "0",userdata(tabcontrol)=  "ADC"
	CheckBox Radio_ClampMode_15,userdata(ResizeControlsInfo)= A"!!,I%!!#@B!!#;]!!#;]z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Radio_ClampMode_15,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Radio_ClampMode_15,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Radio_ClampMode_15,value= 0,mode=1
	CheckBox Radio_ClampMode_1IZ,pos={145.00,181.00},size={13.00,13.00},disable=1,proc=DAP_CheckProc_ClampMode,title=""
	CheckBox Radio_ClampMode_1IZ,value= 0,mode=1
	CheckBox Radio_ClampMode_1IZ,userdata(tabnum)=  "2",userdata(tabcontrol)=  "tab_DataAcq_Amp"
	CheckBox Radio_ClampMode_1IZ,userdata(ResizeControlsInfo)= A"!!,I%!!#@B!!#;]!!#;]z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Radio_ClampMode_1IZ,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Radio_ClampMode_1IZ,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Radio_ClampMode_3IZ,pos={178.00,181.00},size={13.00,13.00},disable=1,proc=DAP_CheckProc_ClampMode,title=""
	CheckBox Radio_ClampMode_3IZ,value= 0,mode=1
	CheckBox Radio_ClampMode_3IZ,userdata(tabnum)=  "2",userdata(tabcontrol)=  "tab_DataAcq_Amp"
	CheckBox Radio_ClampMode_3IZ,userdata(ResizeControlsInfo)= A"!!,I%!!#@B!!#;]!!#;]z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Radio_ClampMode_3IZ,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Radio_ClampMode_3IZ,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Radio_ClampMode_5IZ,pos={212.00,181.00},size={13.00,13.00},disable=1,proc=DAP_CheckProc_ClampMode,title=""
	CheckBox Radio_ClampMode_5IZ,value= 0,mode=1
	CheckBox Radio_ClampMode_5IZ,userdata(tabnum)=  "2",userdata(tabcontrol)=  "tab_DataAcq_Amp"
	CheckBox Radio_ClampMode_5IZ,userdata(ResizeControlsInfo)= A"!!,I%!!#@B!!#;]!!#;]z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Radio_ClampMode_5IZ,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Radio_ClampMode_5IZ,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Radio_ClampMode_7IZ,pos={246.00,181.00},size={13.00,13.00},disable=1,proc=DAP_CheckProc_ClampMode,title=""
	CheckBox Radio_ClampMode_7IZ,value= 0,mode=1
	CheckBox Radio_ClampMode_7IZ,userdata(tabnum)=  "2",userdata(tabcontrol)=  "tab_DataAcq_Amp"
	CheckBox Radio_ClampMode_7IZ,userdata(ResizeControlsInfo)= A"!!,I%!!#@B!!#;]!!#;]z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Radio_ClampMode_7IZ,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Radio_ClampMode_7IZ,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Radio_ClampMode_9IZ,pos={280.00,181.00},size={13.00,13.00},disable=1,proc=DAP_CheckProc_ClampMode,title=""
	CheckBox Radio_ClampMode_9IZ,value= 0,mode=1
	CheckBox Radio_ClampMode_9IZ,userdata(tabnum)=  "2",userdata(tabcontrol)=  "tab_DataAcq_Amp"
	CheckBox Radio_ClampMode_9IZ,userdata(ResizeControlsInfo)= A"!!,I%!!#@B!!#;]!!#;]z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Radio_ClampMode_9IZ,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Radio_ClampMode_9IZ,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Radio_ClampMode_11IZ,pos={314.00,181.00},size={13.00,13.00},disable=1,proc=DAP_CheckProc_ClampMode,title=""
	CheckBox Radio_ClampMode_11IZ,value= 0,mode=1
	CheckBox Radio_ClampMode_11IZ,userdata(tabnum)=  "2",userdata(tabcontrol)=  "tab_DataAcq_Amp"
	CheckBox Radio_ClampMode_11IZ,userdata(ResizeControlsInfo)= A"!!,I%!!#@B!!#;]!!#;]z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Radio_ClampMode_11IZ,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Radio_ClampMode_11IZ,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Radio_ClampMode_13IZ,pos={348.00,181.00},size={13.00,13.00},disable=1,proc=DAP_CheckProc_ClampMode,title=""
	CheckBox Radio_ClampMode_13IZ,value= 0,mode=1
	CheckBox Radio_ClampMode_13IZ,userdata(tabnum)=  "2",userdata(tabcontrol)=  "tab_DataAcq_Amp"
	CheckBox Radio_ClampMode_13IZ,userdata(ResizeControlsInfo)= A"!!,I%!!#@B!!#;]!!#;]z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Radio_ClampMode_13IZ,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Radio_ClampMode_13IZ,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Radio_ClampMode_15IZ,pos={382.00,181.00},size={13.00,13.00},disable=1,proc=DAP_CheckProc_ClampMode,title=""
	CheckBox Radio_ClampMode_15IZ,value= 0,mode=1
	CheckBox Radio_ClampMode_15IZ,userdata(tabnum)=  "2",userdata(tabcontrol)=  "tab_DataAcq_Amp"
	CheckBox Radio_ClampMode_15IZ,userdata(ResizeControlsInfo)= A"!!,I%!!#@B!!#;]!!#;]z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Radio_ClampMode_15IZ,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Radio_ClampMode_15IZ,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	TitleBox Title_DataAcq_IE0,pos={82.00,179.00},size={55.00,15.00},disable=1,title="I=0 Clamp"
	TitleBox Title_DataAcq_IE0,frame=0
	TitleBox Title_DataAcq_IE0,userdata(tabnum)=  "2",userdata(tabcontrol)=  "tab_DataAcq_Amp"
	PopupMenu Popup_Settings_VC_DA,pos={46.00,411.00},size={47.00,19.00},proc=DAP_PopMenuProc_CAA,title="DA"
	PopupMenu Popup_Settings_VC_DA,userdata(tabnum)=  "6"
	PopupMenu Popup_Settings_VC_DA,userdata(tabcontrol)=  "ADC"
	PopupMenu Popup_Settings_VC_DA,userdata(ResizeControlsInfo)= A"!!,DG!!#C2J,hnu!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Popup_Settings_VC_DA,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Popup_Settings_VC_DA,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Popup_Settings_VC_DA,mode=1,popvalue="0",value= #"\"0;1;2;3;4;5;6;7\""
	PopupMenu Popup_Settings_VC_AD,pos={46.00,436.00},size={47.00,19.00},proc=DAP_PopMenuProc_CAA,title="AD"
	PopupMenu Popup_Settings_VC_AD,userdata(tabnum)=  "6"
	PopupMenu Popup_Settings_VC_AD,userdata(tabcontrol)=  "ADC"
	PopupMenu Popup_Settings_VC_AD,userdata(ResizeControlsInfo)= A"!!,DG!!#C?!!#>J!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Popup_Settings_VC_AD,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Popup_Settings_VC_AD,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Popup_Settings_VC_AD,mode=1,popvalue="0",value= #"\"0;1;2;3;4;5;6;7;8;9;10;11;12;13;14;15\""
	PopupMenu Popup_Settings_IC_AD,pos={226.00,436.00},size={47.00,19.00},proc=DAP_PopMenuProc_CAA,title="AD"
	PopupMenu Popup_Settings_IC_AD,userdata(tabnum)=  "6"
	PopupMenu Popup_Settings_IC_AD,userdata(tabcontrol)=  "ADC"
	PopupMenu Popup_Settings_IC_AD,userdata(ResizeControlsInfo)= A"!!,Gr!!#C?!!#>J!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Popup_Settings_IC_AD,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Popup_Settings_IC_AD,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Popup_Settings_IC_AD,mode=1,popvalue="0",value= #"\"0;1;2;3;4;5;6;7;8;9;10;11;12;13;14;15\""
	SetVariable setvar_Settings_VC_DAgain,pos={107.00,413.00},size={50.00,18.00},proc=DAP_SetVarProc_CAA
	SetVariable setvar_Settings_VC_DAgain,userdata(tabnum)=  "6"
	SetVariable setvar_Settings_VC_DAgain,userdata(tabcontrol)=  "ADC"
	SetVariable setvar_Settings_VC_DAgain,userdata(ResizeControlsInfo)= A"!!,F;!!#C3J,ho,!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_Settings_VC_DAgain,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_Settings_VC_DAgain,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_Settings_VC_DAgain,value= _NUM:20
	SetVariable setvar_Settings_VC_ADgain,pos={107.00,438.00},size={50.00,18.00},proc=DAP_SetVarProc_CAA
	SetVariable setvar_Settings_VC_ADgain,userdata(tabnum)=  "6"
	SetVariable setvar_Settings_VC_ADgain,userdata(tabcontrol)=  "ADC"
	SetVariable setvar_Settings_VC_ADgain,userdata(ResizeControlsInfo)= A"!!,F;!!#C@!!#>V!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_Settings_VC_ADgain,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_Settings_VC_ADgain,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_Settings_VC_ADgain,value= _NUM:0.00999999977648258
	SetVariable setvar_Settings_IC_ADgain,pos={287.00,438.00},size={50.00,18.00},proc=DAP_SetVarProc_CAA
	SetVariable setvar_Settings_IC_ADgain,userdata(tabnum)=  "6"
	SetVariable setvar_Settings_IC_ADgain,userdata(tabcontrol)=  "ADC"
	SetVariable setvar_Settings_IC_ADgain,userdata(ResizeControlsInfo)= A"!!,HJJ,hsk!!#>V!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_Settings_IC_ADgain,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_Settings_IC_ADgain,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_Settings_IC_ADgain,value= _NUM:0.00999999977648258
	PopupMenu Popup_Settings_HeadStage,pos={46.00,329.00},size={91.00,19.00},proc=DAP_PopMenuProc_Headstage,title="Head Stage"
	PopupMenu Popup_Settings_HeadStage,userdata(tabnum)=  "6"
	PopupMenu Popup_Settings_HeadStage,userdata(tabcontrol)=  "ADC"
	PopupMenu Popup_Settings_HeadStage,userdata(ResizeControlsInfo)= A"!!,DG!!#B^J,hpE!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Popup_Settings_HeadStage,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Popup_Settings_HeadStage,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Popup_Settings_HeadStage,mode=1,popvalue="0",value= #"\"0;1;2;3;4;5;6;7\""
	PopupMenu popup_Settings_Amplifier,pos={35.00,358.00},size={235.00,19.00},bodyWidth=150,proc=DAP_PopMenuProc_CAA,title="Amplfier (700B)"
	PopupMenu popup_Settings_Amplifier,userdata(tabnum)=  "6"
	PopupMenu popup_Settings_Amplifier,userdata(tabcontrol)=  "ADC"
	PopupMenu popup_Settings_Amplifier,userdata(ResizeControlsInfo)= A"!!,Cp!!#Bm!!#B%!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu popup_Settings_Amplifier,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu popup_Settings_Amplifier,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu popup_Settings_Amplifier,mode=1, value=DAP_GetNiceAmplifierChannelList()
	PopupMenu Popup_Settings_IC_DA,pos={226.00,411.00},size={47.00,19.00},proc=DAP_PopMenuProc_CAA,title="DA"
	PopupMenu Popup_Settings_IC_DA,userdata(tabnum)=  "6"
	PopupMenu Popup_Settings_IC_DA,userdata(tabcontrol)=  "ADC"
	PopupMenu Popup_Settings_IC_DA,userdata(ResizeControlsInfo)= A"!!,Gr!!#C2J,hnu!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Popup_Settings_IC_DA,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Popup_Settings_IC_DA,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Popup_Settings_IC_DA,mode=1,popvalue="0",value= #"\"0;1;2;3;4;5;6;7\""
	SetVariable setvar_Settings_IC_DAgain,pos={288.00,413.00},size={50.00,18.00},proc=DAP_SetVarProc_CAA
	SetVariable setvar_Settings_IC_DAgain,userdata(tabnum)=  "6"
	SetVariable setvar_Settings_IC_DAgain,userdata(tabcontrol)=  "ADC"
	SetVariable setvar_Settings_IC_DAgain,userdata(ResizeControlsInfo)= A"!!,HK!!#C3J,ho,!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_Settings_IC_DAgain,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_Settings_IC_DAgain,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_Settings_IC_DAgain,value= _NUM:400
	TitleBox Title_settings_Hardware_VC,pos={57.00,395.00},size={47.00,15.00},title="V-Clamp"
	TitleBox Title_settings_Hardware_VC,userdata(tabnum)=  "6"
	TitleBox Title_settings_Hardware_VC,userdata(tabcontrol)=  "ADC"
	TitleBox Title_settings_Hardware_VC,userdata(ResizeControlsInfo)= A"!!,Ds!!#C*J,hnu!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox Title_settings_Hardware_VC,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	TitleBox Title_settings_Hardware_VC,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	TitleBox Title_settings_Hardware_VC,frame=0
	TitleBox Title_settings_ChanlAssign_IC,pos={239.00,395.00},size={43.00,15.00},title="I-Clamp"
	TitleBox Title_settings_ChanlAssign_IC,userdata(tabnum)=  "6"
	TitleBox Title_settings_ChanlAssign_IC,userdata(tabcontrol)=  "ADC"
	TitleBox Title_settings_ChanlAssign_IC,userdata(ResizeControlsInfo)= A"!!,H*!!#C*J,hne!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox Title_settings_ChanlAssign_IC,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	TitleBox Title_settings_ChanlAssign_IC,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	TitleBox Title_settings_ChanlAssign_IC,frame=0
	Button button_Settings_UpdateAmpStatus,pos={276.00,358.00},size={150.00,20.00},proc=DAP_ButtonCtrlFindConnectedAmps,title="Query connected Amp(s)"
	Button button_Settings_UpdateAmpStatus,userdata(tabnum)=  "6"
	Button button_Settings_UpdateAmpStatus,userdata(tabcontrol)=  "ADC"
	Button button_Settings_UpdateAmpStatus,userdata(ResizeControlsInfo)= A"!!,HE!!#Bm!!#A%!!#<Xz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_Settings_UpdateAmpStatus,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button button_Settings_UpdateAmpStatus,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Search_DA_00,pos={153.00,97.00},size={124.00,18.00},disable=1,proc=DAP_SetVarProc_DASearch,title="Search string"
	SetVariable Search_DA_00,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	SetVariable Search_DA_00,userdata(ResizeControlsInfo)= A"!!,G)!!#@&!!#@\\!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Search_DA_00,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Search_DA_00,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Search_DA_00,value= _STR:""
	SetVariable Search_DA_01,pos={153.00,143.00},size={124.00,18.00},disable=1,proc=DAP_SetVarProc_DASearch,title="Search string"
	SetVariable Search_DA_01,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	SetVariable Search_DA_01,userdata(ResizeControlsInfo)= A"!!,G)!!#@s!!#@\\!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Search_DA_01,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Search_DA_01,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Search_DA_01,value= _STR:""
	SetVariable Search_DA_02,pos={153.00,189.00},size={124.00,18.00},disable=1,proc=DAP_SetVarProc_DASearch,title="Search string"
	SetVariable Search_DA_02,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	SetVariable Search_DA_02,userdata(ResizeControlsInfo)= A"!!,G)!!#AL!!#@\\!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Search_DA_02,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Search_DA_02,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Search_DA_02,value= _STR:""
	SetVariable Search_DA_03,pos={153.00,236.00},size={124.00,18.00},disable=1,proc=DAP_SetVarProc_DASearch,title="Search string"
	SetVariable Search_DA_03,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	SetVariable Search_DA_03,userdata(ResizeControlsInfo)= A"!!,G)!!#B&!!#@\\!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Search_DA_03,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Search_DA_03,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Search_DA_03,value= _STR:""
	SetVariable Search_DA_04,pos={153.00,282.00},size={124.00,18.00},disable=1,proc=DAP_SetVarProc_DASearch,title="Search string"
	SetVariable Search_DA_04,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	SetVariable Search_DA_04,userdata(ResizeControlsInfo)= A"!!,G)!!#BG!!#@\\!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Search_DA_04,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Search_DA_04,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Search_DA_04,value= _STR:""
	SetVariable Search_DA_05,pos={153.00,329.00},size={124.00,18.00},disable=1,proc=DAP_SetVarProc_DASearch,title="Search string"
	SetVariable Search_DA_05,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	SetVariable Search_DA_05,userdata(ResizeControlsInfo)= A"!!,G)!!#B^J,hq2!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Search_DA_05,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Search_DA_05,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Search_DA_05,value= _STR:""
	SetVariable Search_DA_06,pos={153.00,375.00},size={124.00,18.00},disable=1,proc=DAP_SetVarProc_DASearch,title="Search string"
	SetVariable Search_DA_06,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	SetVariable Search_DA_06,userdata(ResizeControlsInfo)= A"!!,G)!!#BuJ,hq2!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Search_DA_06,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Search_DA_06,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Search_DA_06,value= _STR:""
	SetVariable Search_DA_07,pos={153.00,422.00},size={124.00,18.00},disable=1,proc=DAP_SetVarProc_DASearch,title="Search string"
	SetVariable Search_DA_07,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	SetVariable Search_DA_07,userdata(ResizeControlsInfo)= A"!!,G)!!#C8!!#@\\!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Search_DA_07,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Search_DA_07,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Search_DA_07,value= _STR:""
	CheckBox SearchUniversal_DA_00,pos={281.00,98.00},size={75.00,15.00},disable=1,proc=DAP_CheckProc_UnivrslSrchStr,title="Apply to all"
	CheckBox SearchUniversal_DA_00,userdata(tabnum)=  "1"
	CheckBox SearchUniversal_DA_00,userdata(tabcontrol)=  "ADC"
	CheckBox SearchUniversal_DA_00,userdata(ResizeControlsInfo)= A"!!,HGJ,hpS!!#?O!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox SearchUniversal_DA_00,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox SearchUniversal_DA_00,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox SearchUniversal_DA_00,value= 0
	SetVariable Search_TTL_00,pos={102.00,97.00},size={124.00,18.00},disable=1,proc=DAP_SetVarProc_TTLSearch,title="Search string"
	SetVariable Search_TTL_00,userdata(tabnum)=  "3",userdata(tabcontrol)=  "ADC"
	SetVariable Search_TTL_00,userdata(ResizeControlsInfo)= A"!!,F1!!#@&!!#@\\!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Search_TTL_00,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Search_TTL_00,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Search_TTL_00,value= _STR:""
	SetVariable Search_TTL_01,pos={102.00,143.00},size={124.00,18.00},disable=1,proc=DAP_SetVarProc_TTLSearch,title="Search string"
	SetVariable Search_TTL_01,userdata(tabnum)=  "3",userdata(tabcontrol)=  "ADC"
	SetVariable Search_TTL_01,userdata(ResizeControlsInfo)= A"!!,F1!!#@s!!#@\\!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Search_TTL_01,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Search_TTL_01,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Search_TTL_01,value= _STR:""
	SetVariable Search_TTL_02,pos={102.00,190.00},size={124.00,18.00},disable=1,proc=DAP_SetVarProc_TTLSearch,title="Search string"
	SetVariable Search_TTL_02,userdata(tabnum)=  "3",userdata(tabcontrol)=  "ADC"
	SetVariable Search_TTL_02,userdata(ResizeControlsInfo)= A"!!,F1!!#AM!!#@\\!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Search_TTL_02,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Search_TTL_02,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Search_TTL_02,value= _STR:""
	SetVariable Search_TTL_03,pos={102.00,237.00},size={124.00,18.00},disable=1,proc=DAP_SetVarProc_TTLSearch,title="Search string"
	SetVariable Search_TTL_03,userdata(tabnum)=  "3",userdata(tabcontrol)=  "ADC"
	SetVariable Search_TTL_03,userdata(ResizeControlsInfo)= A"!!,F1!!#B'!!#@\\!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Search_TTL_03,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Search_TTL_03,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Search_TTL_03,value= _STR:""
	SetVariable Search_TTL_04,pos={102.00,284.00},size={124.00,18.00},disable=1,proc=DAP_SetVarProc_TTLSearch,title="Search string"
	SetVariable Search_TTL_04,userdata(tabnum)=  "3",userdata(tabcontrol)=  "ADC"
	SetVariable Search_TTL_04,userdata(ResizeControlsInfo)= A"!!,F1!!#BH!!#@\\!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Search_TTL_04,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Search_TTL_04,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Search_TTL_04,value= _STR:""
	SetVariable Search_TTL_05,pos={102.00,331.00},size={124.00,18.00},disable=1,proc=DAP_SetVarProc_TTLSearch,title="Search string"
	SetVariable Search_TTL_05,userdata(tabnum)=  "3",userdata(tabcontrol)=  "ADC"
	SetVariable Search_TTL_05,userdata(ResizeControlsInfo)= A"!!,F1!!#B_J,hq2!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Search_TTL_05,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Search_TTL_05,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Search_TTL_05,value= _STR:""
	SetVariable Search_TTL_06,pos={102.00,378.00},size={124.00,18.00},disable=1,proc=DAP_SetVarProc_TTLSearch,title="Search string"
	SetVariable Search_TTL_06,userdata(tabnum)=  "3",userdata(tabcontrol)=  "ADC"
	SetVariable Search_TTL_06,userdata(ResizeControlsInfo)= A"!!,F1!!#C\"!!#@\\!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Search_TTL_06,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Search_TTL_06,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Search_TTL_06,value= _STR:""
	SetVariable Search_TTL_07,pos={102.00,425.00},size={124.00,18.00},disable=1,proc=DAP_SetVarProc_TTLSearch,title="Search string"
	SetVariable Search_TTL_07,userdata(tabnum)=  "3",userdata(tabcontrol)=  "ADC"
	SetVariable Search_TTL_07,userdata(ResizeControlsInfo)= A"!!,F1!!#C9J,hq2!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Search_TTL_07,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Search_TTL_07,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Search_TTL_07,value= _STR:""
	CheckBox SearchUniversal_TTL_00,pos={234.00,98.00},size={75.00,15.00},disable=1,proc=DAP_CheckProc_UnivrslSrchTTL,title="Apply to all"
	CheckBox SearchUniversal_TTL_00,userdata(tabnum)=  "3"
	CheckBox SearchUniversal_TTL_00,userdata(tabcontrol)=  "ADC"
	CheckBox SearchUniversal_TTL_00,userdata(ResizeControlsInfo)= A"!!,H%!!#@(!!#?O!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox SearchUniversal_TTL_00,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox SearchUniversal_TTL_00,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox SearchUniversal_TTL_00,value= 0
	CheckBox Check_DataAcq_Indexing,pos={190.00,660.00},size={60.00,15.00},disable=1,proc=DAP_CheckProc_IndexingState,title="Indexing"
	CheckBox Check_DataAcq_Indexing,help={"Data acquisition proceeds to next wave in DAC or TTL popup menu list"}
	CheckBox Check_DataAcq_Indexing,userdata(tabnum)=  "0"
	CheckBox Check_DataAcq_Indexing,userdata(tabcontrol)=  "ADC"
	CheckBox Check_DataAcq_Indexing,userdata(ResizeControlsInfo)= A"!!,GN!!#D5!!#?)!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_DataAcq_Indexing,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_DataAcq_Indexing,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_DataAcq_Indexing,value= 0
	TitleBox Title_DA_IndexStartEnd,pos={349.00,50.00},size={94.00,15.00},disable=1,title="\\JCIndexing End Set"
	TitleBox Title_DA_IndexStartEnd,userdata(tabnum)=  "1"
	TitleBox Title_DA_IndexStartEnd,userdata(tabcontrol)=  "ADC"
	TitleBox Title_DA_IndexStartEnd,userdata(ResizeControlsInfo)= A"!!,HiJ,ho,!!#?u!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox Title_DA_IndexStartEnd,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	TitleBox Title_DA_IndexStartEnd,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	TitleBox Title_DA_IndexStartEnd,frame=0,fStyle=1,anchor= LC
	TitleBox Title_DA_Gain,pos={55.00,50.00},size={25.00,15.00},disable=1,title="Gain"
	TitleBox Title_DA_Gain,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	TitleBox Title_DA_Gain,userdata(ResizeControlsInfo)= A"!!,Dk!!#>V!!#=+!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox Title_DA_Gain,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	TitleBox Title_DA_Gain,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	TitleBox Title_DA_Gain,frame=0,fStyle=1
	TitleBox Title_DA_DAWaveSelect,pos={154.00,50.00},size={111.00,15.00},disable=1,title="(first) DA Set Select"
	TitleBox Title_DA_DAWaveSelect,help={"Use the popup menus to select the stimulus set that will be output from the associated channel"}
	TitleBox Title_DA_DAWaveSelect,userdata(tabnum)=  "1"
	TitleBox Title_DA_DAWaveSelect,userdata(tabcontrol)=  "ADC"
	TitleBox Title_DA_DAWaveSelect,userdata(ResizeControlsInfo)= A"!!,G*!!#>V!!#@B!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox Title_DA_DAWaveSelect,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	TitleBox Title_DA_DAWaveSelect,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	TitleBox Title_DA_DAWaveSelect,frame=0,fStyle=1
	TitleBox Title_DA_Scale,pos={293.00,50.00},size={29.00,15.00},disable=1,title="Scale"
	TitleBox Title_DA_Scale,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	TitleBox Title_DA_Scale,userdata(ResizeControlsInfo)= A"!!,HMJ,ho,!!#=K!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox Title_DA_Scale,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	TitleBox Title_DA_Scale,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	TitleBox Title_DA_Scale,frame=0,fStyle=1
	TitleBox Title_DA_Channel,pos={25.00,50.00},size={17.00,15.00},disable=1,title="DA"
	TitleBox Title_DA_Channel,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	TitleBox Title_DA_Channel,userdata(ResizeControlsInfo)= A"!!,C,!!#>V!!#<@!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox Title_DA_Channel,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	TitleBox Title_DA_Channel,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	TitleBox Title_DA_Channel,frame=0,fStyle=1
	PopupMenu IndexEnd_DA_00,pos={350.00,75.00},size={128.00,19.00},bodyWidth=125,disable=1,proc=DAP_PopMenuChkProc_StimSetList
	PopupMenu IndexEnd_DA_00,userdata(tabnum)=  "1"
	PopupMenu IndexEnd_DA_00,userdata(tabcontrol)=  "ADC"
	PopupMenu IndexEnd_DA_00,userdata(ResizeControlsInfo)= A"!!,Hj!!#?O!!#@d!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu IndexEnd_DA_00,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu IndexEnd_DA_00,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu IndexEnd_DA_00,mode=1,popvalue="- none -",value= #"\"- none -;\"+ReturnListOfAllStimSets(0,\"*DA*\")"
	PopupMenu IndexEnd_DA_01,pos={350.00,121.00},size={128.00,19.00},bodyWidth=125,disable=1,proc=DAP_PopMenuChkProc_StimSetList
	PopupMenu IndexEnd_DA_01,userdata(tabnum)=  "1"
	PopupMenu IndexEnd_DA_01,userdata(tabcontrol)=  "ADC"
	PopupMenu IndexEnd_DA_01,userdata(ResizeControlsInfo)= A"!!,Hj!!#@V!!#@d!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu IndexEnd_DA_01,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu IndexEnd_DA_01,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu IndexEnd_DA_01,mode=1,popvalue="- none -",value= #"\"- none -;\"+ReturnListOfAllStimSets(0,\"*DA*\")"
	PopupMenu IndexEnd_DA_02,pos={350.00,167.00},size={128.00,19.00},bodyWidth=125,disable=1,proc=DAP_PopMenuChkProc_StimSetList
	PopupMenu IndexEnd_DA_02,userdata(tabnum)=  "1"
	PopupMenu IndexEnd_DA_02,userdata(tabcontrol)=  "ADC"
	PopupMenu IndexEnd_DA_02,userdata(ResizeControlsInfo)= A"!!,Hj!!#A6!!#@d!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu IndexEnd_DA_02,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu IndexEnd_DA_02,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu IndexEnd_DA_02,mode=1,popvalue="- none -",value= #"\"- none -;\"+ReturnListOfAllStimSets(0,\"*DA*\")"
	PopupMenu IndexEnd_DA_03,pos={350.00,214.00},size={128.00,19.00},bodyWidth=125,disable=1,proc=DAP_PopMenuChkProc_StimSetList
	PopupMenu IndexEnd_DA_03,userdata(tabnum)=  "1"
	PopupMenu IndexEnd_DA_03,userdata(tabcontrol)=  "ADC"
	PopupMenu IndexEnd_DA_03,userdata(ResizeControlsInfo)= A"!!,Hj!!#Ae!!#@d!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu IndexEnd_DA_03,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu IndexEnd_DA_03,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu IndexEnd_DA_03,mode=1,popvalue="- none -",value= #"\"- none -;\"+ReturnListOfAllStimSets(0,\"*DA*\")"
	PopupMenu IndexEnd_DA_04,pos={350.00,260.00},size={128.00,19.00},bodyWidth=125,disable=1,proc=DAP_PopMenuChkProc_StimSetList
	PopupMenu IndexEnd_DA_04,userdata(tabnum)=  "1"
	PopupMenu IndexEnd_DA_04,userdata(tabcontrol)=  "ADC"
	PopupMenu IndexEnd_DA_04,userdata(ResizeControlsInfo)= A"!!,Hj!!#B<!!#@d!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu IndexEnd_DA_04,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu IndexEnd_DA_04,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu IndexEnd_DA_04,mode=1,popvalue="- none -",value= #"\"- none -;\"+ReturnListOfAllStimSets(0,\"*DA*\")"
	PopupMenu IndexEnd_DA_05,pos={350.00,307.00},size={128.00,19.00},bodyWidth=125,disable=1,proc=DAP_PopMenuChkProc_StimSetList
	PopupMenu IndexEnd_DA_05,userdata(tabnum)=  "1"
	PopupMenu IndexEnd_DA_05,userdata(tabcontrol)=  "ADC"
	PopupMenu IndexEnd_DA_05,userdata(ResizeControlsInfo)= A"!!,Hj!!#BSJ,hq:!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu IndexEnd_DA_05,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu IndexEnd_DA_05,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu IndexEnd_DA_05,mode=1,popvalue="- none -",value= #"\"- none -;\"+ReturnListOfAllStimSets(0,\"*DA*\")"
	PopupMenu IndexEnd_DA_06,pos={350.00,353.00},size={128.00,19.00},bodyWidth=125,disable=1,proc=DAP_PopMenuChkProc_StimSetList
	PopupMenu IndexEnd_DA_06,userdata(tabnum)=  "1"
	PopupMenu IndexEnd_DA_06,userdata(tabcontrol)=  "ADC"
	PopupMenu IndexEnd_DA_06,userdata(ResizeControlsInfo)= A"!!,Hj!!#BjJ,hq:!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu IndexEnd_DA_06,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu IndexEnd_DA_06,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu IndexEnd_DA_06,mode=1,popvalue="- none -",value= #"\"- none -;\"+ReturnListOfAllStimSets(0,\"*DA*\")"
	PopupMenu IndexEnd_DA_07,pos={350.00,400.00},size={128.00,19.00},bodyWidth=125,disable=1,proc=DAP_PopMenuChkProc_StimSetList
	PopupMenu IndexEnd_DA_07,userdata(tabnum)=  "1"
	PopupMenu IndexEnd_DA_07,userdata(tabcontrol)=  "ADC"
	PopupMenu IndexEnd_DA_07,userdata(ResizeControlsInfo)= A"!!,Hj!!#C-!!#@d!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu IndexEnd_DA_07,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu IndexEnd_DA_07,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu IndexEnd_DA_07,mode=1,popvalue="- none -",value= #"\"- none -;\"+ReturnListOfAllStimSets(0,\"*DA*\")"
	PopupMenu IndexEnd_TTL_00,pos={243.00,75.00},size={125.00,19.00},bodyWidth=125,disable=1,proc=DAP_PopMenuChkProc_StimSetList
	PopupMenu IndexEnd_TTL_00,userdata(tabnum)=  "3"
	PopupMenu IndexEnd_TTL_00,userdata(tabcontrol)=  "ADC"
	PopupMenu IndexEnd_TTL_00,userdata(ResizeControlsInfo)= A"!!,H+!!#?O!!#@d!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu IndexEnd_TTL_00,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu IndexEnd_TTL_00,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu IndexEnd_TTL_00,mode=1,popvalue="- none -",value= #"\"- none -;\"+ReturnListOfAllStimSets(1,\"*TTL*\")"
	PopupMenu IndexEnd_TTL_01,pos={242.00,121.00},size={125.00,19.00},bodyWidth=125,disable=1,proc=DAP_PopMenuChkProc_StimSetList
	PopupMenu IndexEnd_TTL_01,userdata(tabnum)=  "3"
	PopupMenu IndexEnd_TTL_01,userdata(tabcontrol)=  "ADC"
	PopupMenu IndexEnd_TTL_01,userdata(ResizeControlsInfo)= A"!!,H*!!#@V!!#@d!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu IndexEnd_TTL_01,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu IndexEnd_TTL_01,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu IndexEnd_TTL_01,mode=1,popvalue="- none -",value= #"\"- none -;\"+ReturnListOfAllStimSets(1,\"*TTL*\")"
	PopupMenu IndexEnd_TTL_02,pos={242.00,167.00},size={125.00,19.00},bodyWidth=125,disable=1,proc=DAP_PopMenuChkProc_StimSetList
	PopupMenu IndexEnd_TTL_02,userdata(tabnum)=  "3"
	PopupMenu IndexEnd_TTL_02,userdata(tabcontrol)=  "ADC"
	PopupMenu IndexEnd_TTL_02,userdata(ResizeControlsInfo)= A"!!,H*!!#A6!!#@d!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu IndexEnd_TTL_02,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu IndexEnd_TTL_02,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu IndexEnd_TTL_02,mode=1,popvalue="- none -",value= #"\"- none -;\"+ReturnListOfAllStimSets(1,\"*TTL*\")"
	PopupMenu IndexEnd_TTL_03,pos={242.00,214.00},size={125.00,19.00},bodyWidth=125,disable=1,proc=DAP_PopMenuChkProc_StimSetList
	PopupMenu IndexEnd_TTL_03,userdata(tabnum)=  "3"
	PopupMenu IndexEnd_TTL_03,userdata(tabcontrol)=  "ADC"
	PopupMenu IndexEnd_TTL_03,userdata(ResizeControlsInfo)= A"!!,H*!!#Ae!!#@d!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu IndexEnd_TTL_03,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu IndexEnd_TTL_03,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu IndexEnd_TTL_03,mode=1,popvalue="- none -",value= #"\"- none -;\"+ReturnListOfAllStimSets(1,\"*TTL*\")"
	PopupMenu IndexEnd_TTL_04,pos={242.00,260.00},size={125.00,19.00},bodyWidth=125,disable=1,proc=DAP_PopMenuChkProc_StimSetList
	PopupMenu IndexEnd_TTL_04,userdata(tabnum)=  "3"
	PopupMenu IndexEnd_TTL_04,userdata(tabcontrol)=  "ADC"
	PopupMenu IndexEnd_TTL_04,userdata(ResizeControlsInfo)= A"!!,H*!!#B<!!#@d!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu IndexEnd_TTL_04,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu IndexEnd_TTL_04,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu IndexEnd_TTL_04,mode=1,popvalue="- none -",value= #"\"- none -;\"+ReturnListOfAllStimSets(1,\"*TTL*\")"
	PopupMenu IndexEnd_TTL_05,pos={242.00,307.00},size={125.00,19.00},bodyWidth=125,disable=1,proc=DAP_PopMenuChkProc_StimSetList
	PopupMenu IndexEnd_TTL_05,userdata(tabnum)=  "3"
	PopupMenu IndexEnd_TTL_05,userdata(tabcontrol)=  "ADC"
	PopupMenu IndexEnd_TTL_05,userdata(ResizeControlsInfo)= A"!!,H*!!#BSJ,hq:!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu IndexEnd_TTL_05,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu IndexEnd_TTL_05,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu IndexEnd_TTL_05,mode=1,popvalue="- none -",value= #"\"- none -;\"+ReturnListOfAllStimSets(1,\"*TTL*\")"
	PopupMenu IndexEnd_TTL_06,pos={242.00,353.00},size={125.00,19.00},bodyWidth=125,disable=1,proc=DAP_PopMenuChkProc_StimSetList
	PopupMenu IndexEnd_TTL_06,userdata(tabnum)=  "3"
	PopupMenu IndexEnd_TTL_06,userdata(tabcontrol)=  "ADC"
	PopupMenu IndexEnd_TTL_06,userdata(ResizeControlsInfo)= A"!!,H*!!#BjJ,hq:!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu IndexEnd_TTL_06,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu IndexEnd_TTL_06,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu IndexEnd_TTL_06,mode=1,popvalue="- none -",value= #"\"- none -;\"+ReturnListOfAllStimSets(1,\"*TTL*\")"
	PopupMenu IndexEnd_TTL_07,pos={243.00,400.00},size={125.00,19.00},bodyWidth=125,disable=1,proc=DAP_PopMenuChkProc_StimSetList
	PopupMenu IndexEnd_TTL_07,userdata(tabnum)=  "3"
	PopupMenu IndexEnd_TTL_07,userdata(tabcontrol)=  "ADC"
	PopupMenu IndexEnd_TTL_07,userdata(ResizeControlsInfo)= A"!!,H+!!#C-!!#@d!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu IndexEnd_TTL_07,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu IndexEnd_TTL_07,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu IndexEnd_TTL_07,mode=1,popvalue="- none -",value= #"\"- none -;\"+ReturnListOfAllStimSets(1,\"*TTL*\")"
	CheckBox check_Settings_ShowScopeWindow,pos={34.00,546.00},size={126.00,15.00},disable=1,proc=DAP_CheckProc_ShowScopeWin,title="Show Scope Window"
	CheckBox check_Settings_ShowScopeWindow,help={"Enable the scope window to view ongoing acquistion"}
	CheckBox check_Settings_ShowScopeWindow,userdata(tabnum)=  "5"
	CheckBox check_Settings_ShowScopeWindow,userdata(tabcontrol)=  "ADC"
	CheckBox check_Settings_ShowScopeWindow,userdata(ResizeControlsInfo)= A"!!,Cl!!#CmJ,hq6!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_Settings_ShowScopeWindow,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_Settings_ShowScopeWindow,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_Settings_ShowScopeWindow,value= 1
	Button Button_TTL_TurnOffAllTTLs,pos={21.00,422.00},size={67.00,40.00},disable=1,proc=DAP_ButtonProc_TTLOff,title="Turn off\rall TTLs"
	Button Button_TTL_TurnOffAllTTLs,userdata(tabnum)=  "3"
	Button Button_TTL_TurnOffAllTTLs,userdata(tabcontrol)=  "ADC"
	Button Button_TTL_TurnOffAllTTLs,userdata(ResizeControlsInfo)= A"!!,Ba!!#C8!!#??!!#>.z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button Button_TTL_TurnOffAllTTLs,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button Button_TTL_TurnOffAllTTLs,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	Button Button_DAC_TurnOFFDACs,pos={19.00,423.00},size={115.00,20.00},disable=1,proc=DAP_ButtonProc_DAOff,title="Turn Off alll DAs"
	Button Button_DAC_TurnOFFDACs,userdata(tabnum)=  "1"
	Button Button_DAC_TurnOFFDACs,userdata(tabcontrol)=  "ADC"
	Button Button_DAC_TurnOFFDACs,userdata(ResizeControlsInfo)= A"!!,BQ!!#C8J,hpu!!#<Xz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button Button_DAC_TurnOFFDACs,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button Button_DAC_TurnOFFDACs,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	Button Button_ADC_TurnOffAllADCs,pos={20.00,425.00},size={115.00,20.00},disable=1,proc=DAP_ButtonProc_ADOff,title="Turn off alll ADs"
	Button Button_ADC_TurnOffAllADCs,userdata(tabnum)=  "2"
	Button Button_ADC_TurnOffAllADCs,userdata(tabcontrol)=  "ADC"
	Button Button_ADC_TurnOffAllADCs,userdata(ResizeControlsInfo)= A"!!,BY!!#C9J,hpu!!#<Xz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button Button_ADC_TurnOffAllADCs,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button Button_ADC_TurnOffAllADCs,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	Button button_DataAcq_TurnOffAllChan,pos={417.00,73.00},size={35.00,40.00},disable=1,proc=DAP_ButtonProc_AllChanOff,title="OFF"
	Button button_DataAcq_TurnOffAllChan,userdata(tabnum)=  "0"
	Button button_DataAcq_TurnOffAllChan,userdata(tabcontrol)=  "ADC"
	Button button_DataAcq_TurnOffAllChan,userdata(ResizeControlsInfo)= A"!!,I6J,hp!!!#=o!!#>.z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_DataAcq_TurnOffAllChan,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button button_DataAcq_TurnOffAllChan,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_Settings_ITITP,pos={34.00,109.00},size={129.00,15.00},disable=1,title="Activate TP during ITI"
	CheckBox check_Settings_ITITP,userdata(tabnum)=  "5"
	CheckBox check_Settings_ITITP,userdata(tabcontrol)=  "ADC"
	CheckBox check_Settings_ITITP,userdata(ResizeControlsInfo)= A"!!,Cl!!#@>!!#@e!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_Settings_ITITP,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_Settings_ITITP,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_Settings_ITITP,value= 1
	ValDisplay valdisp_DataAcq_ITICountdown,pos={74.00,566.00},size={132.00,21.00},bodyWidth=30,disable=1,title="ITI remaining (s)"
	ValDisplay valdisp_DataAcq_ITICountdown,userdata(tabnum)=  "0"
	ValDisplay valdisp_DataAcq_ITICountdown,userdata(tabcontrol)=  "ADC"
	ValDisplay valdisp_DataAcq_ITICountdown,userdata(ResizeControlsInfo)= A"!!,EN!!#CrJ,hq>!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	ValDisplay valdisp_DataAcq_ITICountdown,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	ValDisplay valdisp_DataAcq_ITICountdown,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	ValDisplay valdisp_DataAcq_ITICountdown,fSize=14,format="%1g",fStyle=0
	ValDisplay valdisp_DataAcq_ITICountdown,valueColor=(65535,65535,65535)
	ValDisplay valdisp_DataAcq_ITICountdown,valueBackColor=(0,0,0)
	ValDisplay valdisp_DataAcq_ITICountdown,limits={0,0,0},barmisc={0,1000}
	ValDisplay valdisp_DataAcq_ITICountdown,value= _NUM:0
	ValDisplay valdisp_DataAcq_TrialsCountdown,pos={63.00,539.00},size={144.00,21.00},bodyWidth=30,disable=1,title="Sweeps remaining"
	ValDisplay valdisp_DataAcq_TrialsCountdown,userdata(tabnum)=  "0"
	ValDisplay valdisp_DataAcq_TrialsCountdown,userdata(tabcontrol)=  "ADC"
	ValDisplay valdisp_DataAcq_TrialsCountdown,userdata(ResizeControlsInfo)= A"!!,E6!!#Ck^]6_5!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	ValDisplay valdisp_DataAcq_TrialsCountdown,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	ValDisplay valdisp_DataAcq_TrialsCountdown,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	ValDisplay valdisp_DataAcq_TrialsCountdown,fSize=14,fStyle=0
	ValDisplay valdisp_DataAcq_TrialsCountdown,valueColor=(65535,65535,65535)
	ValDisplay valdisp_DataAcq_TrialsCountdown,valueBackColor=(0,0,0)
	ValDisplay valdisp_DataAcq_TrialsCountdown,limits={0,0,0},barmisc={0,1000}
	ValDisplay valdisp_DataAcq_TrialsCountdown,value= #"0"
	CheckBox check_Settings_Overwrite,pos={34.00,208.00},size={144.00,30.00},disable=1,title="Overwrite data waves on\rNext Sweep roll back"
	CheckBox check_Settings_Overwrite,help={"Overwrite occurs on next data acquisition cycle"}
	CheckBox check_Settings_Overwrite,userdata(tabnum)=  "5"
	CheckBox check_Settings_Overwrite,userdata(tabcontrol)=  "ADC"
	CheckBox check_Settings_Overwrite,userdata(ResizeControlsInfo)= A"!!,Cl!!#A_!!#@t!!#=Sz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_Settings_Overwrite,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_Settings_Overwrite,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_Settings_Overwrite,value= 1
	SetVariable min_AsyncAD_00,pos={109.00,66.00},size={75.00,18.00},bodyWidth=50,disable=1,title="min"
	SetVariable min_AsyncAD_00,userdata(tabnum)=  "4"
	SetVariable min_AsyncAD_00,userdata(tabcontrol)=  "ADC"
	SetVariable min_AsyncAD_00,userdata(ResizeControlsInfo)= A"!!,F?!!#?=!!#?O!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable min_AsyncAD_00,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable min_AsyncAD_00,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable min_AsyncAD_00,value= _NUM:0
	SetVariable max_AsyncAD_00,pos={197.00,66.00},size={76.00,18.00},bodyWidth=50,disable=1,title="max"
	SetVariable max_AsyncAD_00,userdata(tabnum)=  "4"
	SetVariable max_AsyncAD_00,userdata(tabcontrol)=  "ADC"
	SetVariable max_AsyncAD_00,userdata(ResizeControlsInfo)= A"!!,GU!!#?=!!#?Q!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable max_AsyncAD_00,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable max_AsyncAD_00,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable max_AsyncAD_00,value= _NUM:0
	CheckBox check_AsyncAlarm_00,pos={50.00,68.00},size={47.00,15.00},disable=1,title="Alarm"
	CheckBox check_AsyncAlarm_00,userdata(tabnum)=  "4"
	CheckBox check_AsyncAlarm_00,userdata(tabcontrol)=  "ADC"
	CheckBox check_AsyncAlarm_00,userdata(ResizeControlsInfo)= A"!!,DW!!#?A!!#>J!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_AsyncAlarm_00,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_AsyncAlarm_00,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_AsyncAlarm_00,value= 0
	SetVariable min_AsyncAD_01,pos={109.00,117.00},size={75.00,18.00},bodyWidth=50,disable=1,title="min"
	SetVariable min_AsyncAD_01,userdata(tabnum)=  "4"
	SetVariable min_AsyncAD_01,userdata(tabcontrol)=  "ADC"
	SetVariable min_AsyncAD_01,userdata(ResizeControlsInfo)= A"!!,F?!!#@N!!#?O!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable min_AsyncAD_01,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable min_AsyncAD_01,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable min_AsyncAD_01,value= _NUM:0
	SetVariable max_AsyncAD_01,pos={197.00,117.00},size={76.00,18.00},bodyWidth=50,disable=1,title="max"
	SetVariable max_AsyncAD_01,userdata(tabnum)=  "4"
	SetVariable max_AsyncAD_01,userdata(tabcontrol)=  "ADC"
	SetVariable max_AsyncAD_01,userdata(ResizeControlsInfo)= A"!!,GU!!#@N!!#?Q!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable max_AsyncAD_01,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable max_AsyncAD_01,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable max_AsyncAD_01,value= _NUM:0
	CheckBox check_AsyncAlarm_01,pos={50.00,119.00},size={47.00,15.00},disable=1,title="Alarm"
	CheckBox check_AsyncAlarm_01,userdata(tabnum)=  "4"
	CheckBox check_AsyncAlarm_01,userdata(tabcontrol)=  "ADC"
	CheckBox check_AsyncAlarm_01,userdata(ResizeControlsInfo)= A"!!,DW!!#@R!!#>J!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_AsyncAlarm_01,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_AsyncAlarm_01,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_AsyncAlarm_01,value= 0
	SetVariable min_AsyncAD_02,pos={109.00,169.00},size={75.00,18.00},bodyWidth=50,disable=1,title="min"
	SetVariable min_AsyncAD_02,userdata(tabnum)=  "4"
	SetVariable min_AsyncAD_02,userdata(tabcontrol)=  "ADC"
	SetVariable min_AsyncAD_02,userdata(ResizeControlsInfo)= A"!!,F?!!#A8!!#?O!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable min_AsyncAD_02,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable min_AsyncAD_02,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable min_AsyncAD_02,value= _NUM:0
	SetVariable max_AsyncAD_02,pos={197.00,169.00},size={76.00,18.00},bodyWidth=50,disable=1,title="max"
	SetVariable max_AsyncAD_02,userdata(tabnum)=  "4"
	SetVariable max_AsyncAD_02,userdata(tabcontrol)=  "ADC"
	SetVariable max_AsyncAD_02,userdata(ResizeControlsInfo)= A"!!,GU!!#A8!!#?Q!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable max_AsyncAD_02,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable max_AsyncAD_02,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable max_AsyncAD_02,value= _NUM:0
	CheckBox check_AsyncAlarm_02,pos={50.00,171.00},size={47.00,15.00},disable=1,title="Alarm"
	CheckBox check_AsyncAlarm_02,userdata(tabnum)=  "4"
	CheckBox check_AsyncAlarm_02,userdata(tabcontrol)=  "ADC"
	CheckBox check_AsyncAlarm_02,userdata(ResizeControlsInfo)= A"!!,DW!!#A:!!#>J!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_AsyncAlarm_02,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_AsyncAlarm_02,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_AsyncAlarm_02,value= 0
	SetVariable min_AsyncAD_03,pos={109.00,220.00},size={75.00,18.00},bodyWidth=50,disable=1,title="min"
	SetVariable min_AsyncAD_03,userdata(tabnum)=  "4"
	SetVariable min_AsyncAD_03,userdata(tabcontrol)=  "ADC"
	SetVariable min_AsyncAD_03,userdata(ResizeControlsInfo)= A"!!,F?!!#Ak!!#?O!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable min_AsyncAD_03,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable min_AsyncAD_03,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable min_AsyncAD_03,value= _NUM:0
	SetVariable max_AsyncAD_03,pos={197.00,220.00},size={76.00,18.00},bodyWidth=50,disable=1,title="max"
	SetVariable max_AsyncAD_03,userdata(tabnum)=  "4"
	SetVariable max_AsyncAD_03,userdata(tabcontrol)=  "ADC"
	SetVariable max_AsyncAD_03,userdata(ResizeControlsInfo)= A"!!,GU!!#Ak!!#?Q!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable max_AsyncAD_03,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable max_AsyncAD_03,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable max_AsyncAD_03,value= _NUM:0
	CheckBox check_AsyncAlarm_03,pos={50.00,222.00},size={47.00,15.00},disable=1,title="Alarm"
	CheckBox check_AsyncAlarm_03,userdata(tabnum)=  "4"
	CheckBox check_AsyncAlarm_03,userdata(tabcontrol)=  "ADC"
	CheckBox check_AsyncAlarm_03,userdata(ResizeControlsInfo)= A"!!,DW!!#Am!!#>J!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_AsyncAlarm_03,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_AsyncAlarm_03,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_AsyncAlarm_03,value= 0
	SetVariable min_AsyncAD_04,pos={109.00,272.00},size={75.00,18.00},bodyWidth=50,disable=1,title="min"
	SetVariable min_AsyncAD_04,userdata(tabnum)=  "4"
	SetVariable min_AsyncAD_04,userdata(tabcontrol)=  "ADC"
	SetVariable min_AsyncAD_04,userdata(ResizeControlsInfo)= A"!!,F?!!#BB!!#?O!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable min_AsyncAD_04,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable min_AsyncAD_04,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable min_AsyncAD_04,value= _NUM:0
	SetVariable max_AsyncAD_04,pos={197.00,272.00},size={76.00,18.00},bodyWidth=50,disable=1,title="max"
	SetVariable max_AsyncAD_04,userdata(tabnum)=  "4"
	SetVariable max_AsyncAD_04,userdata(tabcontrol)=  "ADC"
	SetVariable max_AsyncAD_04,userdata(ResizeControlsInfo)= A"!!,GU!!#BB!!#?Q!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable max_AsyncAD_04,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable max_AsyncAD_04,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable max_AsyncAD_04,value= _NUM:0
	CheckBox check_AsyncAlarm_04,pos={50.00,274.00},size={47.00,15.00},disable=1,title="Alarm"
	CheckBox check_AsyncAlarm_04,userdata(tabnum)=  "4"
	CheckBox check_AsyncAlarm_04,userdata(tabcontrol)=  "ADC"
	CheckBox check_AsyncAlarm_04,userdata(ResizeControlsInfo)= A"!!,DW!!#BC!!#>J!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_AsyncAlarm_04,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_AsyncAlarm_04,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_AsyncAlarm_04,value= 0
	SetVariable min_AsyncAD_05,pos={109.00,323.00},size={75.00,18.00},bodyWidth=50,disable=1,title="min"
	SetVariable min_AsyncAD_05,userdata(tabnum)=  "4"
	SetVariable min_AsyncAD_05,userdata(tabcontrol)=  "ADC"
	SetVariable min_AsyncAD_05,userdata(ResizeControlsInfo)= A"!!,F?!!#B[J,hp%!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable min_AsyncAD_05,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable min_AsyncAD_05,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable min_AsyncAD_05,value= _NUM:0
	SetVariable max_AsyncAD_05,pos={197.00,323.00},size={76.00,18.00},bodyWidth=50,disable=1,title="max"
	SetVariable max_AsyncAD_05,userdata(tabnum)=  "4"
	SetVariable max_AsyncAD_05,userdata(tabcontrol)=  "ADC"
	SetVariable max_AsyncAD_05,userdata(ResizeControlsInfo)= A"!!,GU!!#B[J,hp'!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable max_AsyncAD_05,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable max_AsyncAD_05,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable max_AsyncAD_05,value= _NUM:0
	CheckBox check_AsyncAlarm_05,pos={50.00,325.00},size={47.00,15.00},disable=1,title="Alarm"
	CheckBox check_AsyncAlarm_05,userdata(tabnum)=  "4"
	CheckBox check_AsyncAlarm_05,userdata(tabcontrol)=  "ADC"
	CheckBox check_AsyncAlarm_05,userdata(ResizeControlsInfo)= A"!!,DW!!#B\\J,hnu!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_AsyncAlarm_05,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_AsyncAlarm_05,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_AsyncAlarm_05,value= 0
	SetVariable min_AsyncAD_06,pos={109.00,375.00},size={75.00,18.00},bodyWidth=50,disable=1,title="min"
	SetVariable min_AsyncAD_06,userdata(tabnum)=  "4"
	SetVariable min_AsyncAD_06,userdata(tabcontrol)=  "ADC"
	SetVariable min_AsyncAD_06,userdata(ResizeControlsInfo)= A"!!,F?!!#BuJ,hp%!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable min_AsyncAD_06,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable min_AsyncAD_06,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable min_AsyncAD_06,value= _NUM:0
	SetVariable max_AsyncAD_06,pos={197.00,375.00},size={76.00,18.00},bodyWidth=50,disable=1,title="max"
	SetVariable max_AsyncAD_06,userdata(tabnum)=  "4"
	SetVariable max_AsyncAD_06,userdata(tabcontrol)=  "ADC"
	SetVariable max_AsyncAD_06,userdata(ResizeControlsInfo)= A"!!,GU!!#BuJ,hp'!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable max_AsyncAD_06,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable max_AsyncAD_06,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable max_AsyncAD_06,value= _NUM:0
	CheckBox check_AsyncAlarm_06,pos={50.00,378.00},size={47.00,15.00},disable=1,title="Alarm"
	CheckBox check_AsyncAlarm_06,userdata(tabnum)=  "4"
	CheckBox check_AsyncAlarm_06,userdata(tabcontrol)=  "ADC"
	CheckBox check_AsyncAlarm_06,userdata(ResizeControlsInfo)= A"!!,DW!!#C\"!!#>J!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_AsyncAlarm_06,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_AsyncAlarm_06,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_AsyncAlarm_06,value= 0
	SetVariable min_AsyncAD_07,pos={109.00,427.00},size={75.00,18.00},bodyWidth=50,disable=1,title="min"
	SetVariable min_AsyncAD_07,userdata(tabnum)=  "4"
	SetVariable min_AsyncAD_07,userdata(tabcontrol)=  "ADC"
	SetVariable min_AsyncAD_07,userdata(ResizeControlsInfo)= A"!!,F?!!#C:J,hp%!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable min_AsyncAD_07,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable min_AsyncAD_07,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable min_AsyncAD_07,value= _NUM:0
	SetVariable max_AsyncAD_07,pos={197.00,427.00},size={76.00,18.00},bodyWidth=50,disable=1,title="max"
	SetVariable max_AsyncAD_07,userdata(tabnum)=  "4"
	SetVariable max_AsyncAD_07,userdata(tabcontrol)=  "ADC"
	SetVariable max_AsyncAD_07,userdata(ResizeControlsInfo)= A"!!,GU!!#C:J,hp'!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable max_AsyncAD_07,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable max_AsyncAD_07,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable max_AsyncAD_07,value= _NUM:0
	CheckBox check_AsyncAlarm_07,pos={50.00,429.00},size={47.00,15.00},disable=1,title="Alarm"
	CheckBox check_AsyncAlarm_07,userdata(tabnum)=  "4"
	CheckBox check_AsyncAlarm_07,userdata(tabcontrol)=  "ADC"
	CheckBox check_AsyncAlarm_07,userdata(ResizeControlsInfo)= A"!!,DW!!#C;J,hnu!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_AsyncAlarm_07,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_AsyncAlarm_07,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_AsyncAlarm_07,value= 0
	TitleBox Title_TTL_IndexStartEnd,pos={255.00,50.00},size={94.00,15.00},disable=1,title="\\JCIndexing End Set"
	TitleBox Title_TTL_IndexStartEnd,userdata(tabnum)=  "3"
	TitleBox Title_TTL_IndexStartEnd,userdata(tabcontrol)=  "ADC"
	TitleBox Title_TTL_IndexStartEnd,userdata(ResizeControlsInfo)= A"!!,H:!!#>V!!#?u!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox Title_TTL_IndexStartEnd,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	TitleBox Title_TTL_IndexStartEnd,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	TitleBox Title_TTL_IndexStartEnd,frame=0,fStyle=1,anchor= LC
	TitleBox Title_TTL_TTLWaveSelect,pos={100.00,50.00},size={114.00,15.00},disable=1,title="(first) TTL Set Select"
	TitleBox Title_TTL_TTLWaveSelect,userdata(tabnum)=  "3"
	TitleBox Title_TTL_TTLWaveSelect,userdata(tabcontrol)=  "ADC"
	TitleBox Title_TTL_TTLWaveSelect,userdata(ResizeControlsInfo)= A"!!,F-!!#>V!!#@H!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox Title_TTL_TTLWaveSelect,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	TitleBox Title_TTL_TTLWaveSelect,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	TitleBox Title_TTL_TTLWaveSelect,frame=0,fStyle=1
	TitleBox Title_TTL_Channel,pos={25.00,50.00},size={47.00,15.00},disable=1,title="TTL(out)"
	TitleBox Title_TTL_Channel,userdata(tabnum)=  "3",userdata(tabcontrol)=  "ADC"
	TitleBox Title_TTL_Channel,userdata(ResizeControlsInfo)= A"!!,C,!!#>V!!#>J!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox Title_TTL_Channel,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	TitleBox Title_TTL_Channel,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	TitleBox Title_TTL_Channel,frame=0,fStyle=1
	CheckBox check_DataAcq_RepAcqRandom,pos={72.00,660.00},size={60.00,15.00},disable=1,title="Random"
	CheckBox check_DataAcq_RepAcqRandom,help={"Randomly selects wave from set selected for DAC channel on each trial. Doesn't repeat waves."}
	CheckBox check_DataAcq_RepAcqRandom,userdata(tabnum)=  "0"
	CheckBox check_DataAcq_RepAcqRandom,userdata(tabcontrol)=  "ADC"
	CheckBox check_DataAcq_RepAcqRandom,userdata(ResizeControlsInfo)= A"!!,EJ!!#D5!!#?)!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_DataAcq_RepAcqRandom,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_DataAcq_RepAcqRandom,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_DataAcq_RepAcqRandom,value= 0
	TitleBox title_Settings_SetCondition,pos={60.00,346.00},size={57.00,12.00},disable=1,title="\\Z10Set A > Set B"
	TitleBox title_Settings_SetCondition,userdata(tabnum)=  "5"
	TitleBox title_Settings_SetCondition,userdata(tabcontrol)=  "ADC"
	TitleBox title_Settings_SetCondition,userdata(ResizeControlsInfo)= A"!!,D[!!#Bf!!#??!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox title_Settings_SetCondition,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	TitleBox title_Settings_SetCondition,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	TitleBox title_Settings_SetCondition,frame=0
	CheckBox check_Settings_Option_3,pos={246.00,360.00},size={132.00,30.00},disable=1,proc=DAP_CheckProc_LockedLogic,title="Repeat set B\runtil set A is complete"
	CheckBox check_Settings_Option_3,help={"This mode is useful when Set B contains a single wave."}
	CheckBox check_Settings_Option_3,userdata(tabnum)=  "5"
	CheckBox check_Settings_Option_3,userdata(tabcontrol)=  "ADC"
	CheckBox check_Settings_Option_3,userdata(ResizeControlsInfo)= A"!!,HAJ,hsD!!#@h!!#=Sz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_Settings_Option_3,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_Settings_Option_3,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_Settings_Option_3,value= 0
	CheckBox check_Settings_ScalingZero,pos={246.00,303.00},size={139.00,15.00},disable=1,title="Set channel scaling to 0"
	CheckBox check_Settings_ScalingZero,help={"Applies to DA channel outputting Set B"}
	CheckBox check_Settings_ScalingZero,userdata(tabnum)=  "5"
	CheckBox check_Settings_ScalingZero,userdata(tabcontrol)=  "ADC"
	CheckBox check_Settings_ScalingZero,userdata(ResizeControlsInfo)= A"!!,HAJ,hs'J,hqE!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_Settings_ScalingZero,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_Settings_ScalingZero,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_Settings_ScalingZero,value= 0
	CheckBox check_Settings_SetOption_04,pos={246.00,333.00},size={115.00,15.00},disable=3,title="Turn off headstage"
	CheckBox check_Settings_SetOption_04,help={"Turns off AD associated with DA via Channel and Amplifier Assignments"}
	CheckBox check_Settings_SetOption_04,userdata(tabnum)=  "5"
	CheckBox check_Settings_SetOption_04,userdata(tabcontrol)=  "ADC"
	CheckBox check_Settings_SetOption_04,userdata(ResizeControlsInfo)= A"!!,HAJ,hs6J,hpu!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_Settings_SetOption_04,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_Settings_SetOption_04,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_Settings_SetOption_04,fColor=(65280,43520,0),value= 0
	TitleBox title_Settings_SetCondition_00,pos={114.00,328.00},size={5.00,15.00},disable=1,title="\\f01/"
	TitleBox title_Settings_SetCondition_00,userdata(tabnum)=  "5"
	TitleBox title_Settings_SetCondition_00,userdata(tabcontrol)=  "ADC"
	TitleBox title_Settings_SetCondition_00,userdata(ResizeControlsInfo)= A"!!,FI!!#B^!!#9W!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox title_Settings_SetCondition_00,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	TitleBox title_Settings_SetCondition_00,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	TitleBox title_Settings_SetCondition_00,frame=0
	TitleBox title_Settings_SetCondition_01,pos={114.00,365.00},size={5.00,15.00},disable=1,title="\\f01\\"
	TitleBox title_Settings_SetCondition_01,userdata(tabnum)=  "5"
	TitleBox title_Settings_SetCondition_01,userdata(tabcontrol)=  "ADC"
	TitleBox title_Settings_SetCondition_01,userdata(ResizeControlsInfo)= A"!!,FI!!#BpJ,hj-!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox title_Settings_SetCondition_01,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	TitleBox title_Settings_SetCondition_01,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	TitleBox title_Settings_SetCondition_01,frame=0
	TitleBox title_Settings_SetCondition_04,pos={239.00,328.00},size={5.00,15.00},disable=1,title="\\f01\\"
	TitleBox title_Settings_SetCondition_04,userdata(tabnum)=  "5"
	TitleBox title_Settings_SetCondition_04,userdata(tabcontrol)=  "ADC"
	TitleBox title_Settings_SetCondition_04,userdata(ResizeControlsInfo)= A"!!,H>!!#B^!!#9W!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox title_Settings_SetCondition_04,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	TitleBox title_Settings_SetCondition_04,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	TitleBox title_Settings_SetCondition_04,frame=0
	TitleBox title_Settings_SetCondition_02,pos={238.00,307.00},size={5.00,15.00},disable=1,title="\\f01/"
	TitleBox title_Settings_SetCondition_02,userdata(tabnum)=  "5"
	TitleBox title_Settings_SetCondition_02,userdata(tabcontrol)=  "ADC"
	TitleBox title_Settings_SetCondition_02,userdata(ResizeControlsInfo)= A"!!,H=J,hs)J,hj-!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox title_Settings_SetCondition_02,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	TitleBox title_Settings_SetCondition_02,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	TitleBox title_Settings_SetCondition_02,frame=0
	TitleBox title_Settings_SetCondition_03,pos={206.00,317.00},size={35.00,15.00},disable=1,title="\\f01-------"
	TitleBox title_Settings_SetCondition_03,userdata(tabnum)=  "5"
	TitleBox title_Settings_SetCondition_03,userdata(tabcontrol)=  "ADC"
	TitleBox title_Settings_SetCondition_03,userdata(ResizeControlsInfo)= A"!!,Gu!!#BXJ,hnE!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox title_Settings_SetCondition_03,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	TitleBox title_Settings_SetCondition_03,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	TitleBox title_Settings_SetCondition_03,frame=0
	PopupMenu popup_MoreSettings_DeviceType,pos={29.00,73.00},size={164.00,19.00},bodyWidth=100,proc=DAP_PopMenuProc_DevTypeChk,title="Device type"
	PopupMenu popup_MoreSettings_DeviceType,help={"Step 1. Select device type. Available number of devies for selected type are printed to history window."}
	PopupMenu popup_MoreSettings_DeviceType,userdata(tabnum)=  "6"
	PopupMenu popup_MoreSettings_DeviceType,userdata(tabcontrol)=  "ADC"
	PopupMenu popup_MoreSettings_DeviceType,userdata(ResizeControlsInfo)= A"!!,CL!!#?K!!#A3!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu popup_MoreSettings_DeviceType,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu popup_MoreSettings_DeviceType,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu popup_MoreSettings_DeviceType,mode=1,popvalue="ITC16",value= #"\"ITC16;ITC18;ITC1600;\\M1(ITC00;ITC16USB;ITC18USB;\""
	PopupMenu popup_moreSettings_DeviceNo,pos={52.00,100.00},size={141.00,19.00},bodyWidth=58,title="Device number"
	PopupMenu popup_moreSettings_DeviceNo,help={"Step 2. Guess a device number. 0 is a good initial guess. Device number is determined in hardware. Unfortunately, it cannot be predetermined. "}
	PopupMenu popup_moreSettings_DeviceNo,userdata(tabnum)=  "6"
	PopupMenu popup_moreSettings_DeviceNo,userdata(tabcontrol)=  "ADC"
	PopupMenu popup_moreSettings_DeviceNo,userdata(ResizeControlsInfo)= A"!!,D_!!#@,!!#@q!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu popup_moreSettings_DeviceNo,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu popup_moreSettings_DeviceNo,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu popup_moreSettings_DeviceNo,mode=1,popvalue="0",value= #"\"0;1;2;3;4;5;6;7;8;9;10\""
	SetVariable setvar_DataAcq_TerminationDelay,pos={289.00,662.00},size={177.00,18.00},bodyWidth=50,disable=1,title="Termination delay (ms)"
	SetVariable setvar_DataAcq_TerminationDelay,help={"Global set(s) termination delay. Continues recording after set sweep is complete. Useful when recorded phenomena continues after termination of final set epoch."}
	SetVariable setvar_DataAcq_TerminationDelay,userdata(tabnum)=  "0"
	SetVariable setvar_DataAcq_TerminationDelay,userdata(tabcontrol)=  "ADC"
	SetVariable setvar_DataAcq_TerminationDelay,userdata(ResizeControlsInfo)= A"!!,HKJ,ht`J,hqk!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_DataAcq_TerminationDelay,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_DataAcq_TerminationDelay,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_DataAcq_TerminationDelay,value= _NUM:0
	GroupBox group_Hardware_FolderPath,pos={23.00,49.00},size={445.00,105.00},title="Lock a device to generate device folder structure"
	GroupBox group_Hardware_FolderPath,userdata(tabnum)=  "6"
	GroupBox group_Hardware_FolderPath,userdata(tabcontrol)=  "ADC"
	GroupBox group_Hardware_FolderPath,userdata(ResizeControlsInfo)= A"!!,Bq!!#>R!!#CCJ,hpaz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	GroupBox group_Hardware_FolderPath,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	GroupBox group_Hardware_FolderPath,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	GroupBox group_Hardware_FolderPath,fSize=12
	Button button_SettingsPlus_PingDevice,pos={43.00,126.00},size={150.00,20.00},proc=HSU_ButtonProc_Settings_OpenDev,title="Open device"
	Button button_SettingsPlus_PingDevice,help={"Step 3. Use to determine device number for connected device. Look for device with Ready light ON. Device numbers are determined in hardware and do not change over time. "}
	Button button_SettingsPlus_PingDevice,userdata(tabnum)=  "6"
	Button button_SettingsPlus_PingDevice,userdata(tabcontrol)=  "ADC"
	Button button_SettingsPlus_PingDevice,userdata(ResizeControlsInfo)= A"!!,D;!!#@`!!#A%!!#<Xz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_SettingsPlus_PingDevice,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	Button button_SettingsPlus_PingDevice,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	Button button_SettingsPlus_LockDevice,pos={203.00,73.00},size={85.00,46.00},proc=HSU_ButtonProc_LockDev,title="Lock device\r selection"
	Button button_SettingsPlus_LockDevice,help={"Device must be locked to acquire data. Locking can take a few seconds (calls to amp hardware are slow)."}
	Button button_SettingsPlus_LockDevice,userdata(tabnum)=  "6"
	Button button_SettingsPlus_LockDevice,userdata(tabcontrol)=  "ADC"
	Button button_SettingsPlus_LockDevice,userdata(ResizeControlsInfo)= A"!!,G[!!#?K!!#?c!!#>Fz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_SettingsPlus_LockDevice,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	Button button_SettingsPlus_LockDevice,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	Button button_SettingsPlus_unLockDevic,pos={295.00,73.00},size={85.00,46.00},disable=2,proc=HSU_ButProc_Hrdwr_UnlckDev,title="Unlock device\r selection"
	Button button_SettingsPlus_unLockDevic,userdata(tabnum)=  "6"
	Button button_SettingsPlus_unLockDevic,userdata(tabcontrol)=  "ADC"
	Button button_SettingsPlus_unLockDevic,userdata(ResizeControlsInfo)= A"!!,HNJ,hp!!!#?c!!#>Fz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_SettingsPlus_unLockDevic,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	Button button_SettingsPlus_unLockDevic,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	TitleBox title_Settings_SetCondition_1,pos={207.00,380.00},size={35.00,15.00},disable=1,title="\\f01-------"
	TitleBox title_Settings_SetCondition_1,userdata(tabnum)=  "5"
	TitleBox title_Settings_SetCondition_1,userdata(tabcontrol)=  "ADC"
	TitleBox title_Settings_SetCondition_1,userdata(ResizeControlsInfo)= A"!!,H!!!#C#!!#=o!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox title_Settings_SetCondition_1,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	TitleBox title_Settings_SetCondition_1,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	TitleBox title_Settings_SetCondition_1,frame=0
	TitleBox title_Settings_SetCondition_2,pos={239.00,391.00},size={5.00,15.00},disable=1,title="\\f01\\"
	TitleBox title_Settings_SetCondition_2,userdata(tabnum)=  "5"
	TitleBox title_Settings_SetCondition_2,userdata(tabcontrol)=  "ADC"
	TitleBox title_Settings_SetCondition_2,userdata(ResizeControlsInfo)= A"!!,H>!!#C(J,hj-!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox title_Settings_SetCondition_2,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	TitleBox title_Settings_SetCondition_2,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	TitleBox title_Settings_SetCondition_2,frame=0
	TitleBox title_Settings_SetCondition_3,pos={239.00,370.00},size={5.00,15.00},disable=1,title="\\f01/"
	TitleBox title_Settings_SetCondition_3,userdata(tabnum)=  "5"
	TitleBox title_Settings_SetCondition_3,userdata(tabcontrol)=  "ADC"
	TitleBox title_Settings_SetCondition_3,userdata(ResizeControlsInfo)= A"!!,H>!!#Bs!!#9W!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox title_Settings_SetCondition_3,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	TitleBox title_Settings_SetCondition_3,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	TitleBox title_Settings_SetCondition_3,frame=0
	CheckBox check_Settings_SetOption_5,pos={246.00,390.00},size={102.00,30.00},disable=1,proc=DAP_CheckProc_LockedLogic,title="Index to next set\ron DA with set B"
	CheckBox check_Settings_SetOption_5,help={"This mode is useful when Set B contains a single wave."}
	CheckBox check_Settings_SetOption_5,userdata(tabnum)=  "5"
	CheckBox check_Settings_SetOption_5,userdata(tabcontrol)=  "ADC"
	CheckBox check_Settings_SetOption_5,userdata(ResizeControlsInfo)= A"!!,HAJ,hsS!!#@0!!#=Sz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_Settings_SetOption_5,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_Settings_SetOption_5,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox check_Settings_SetOption_5,value= 1
	TitleBox title_Settings_SetCondition1,pos={124.00,368.00},size={90.00,24.00},disable=1,title="\\Z10Continue acquisition\ron DA with set B"
	TitleBox title_Settings_SetCondition1,userdata(tabnum)=  "5"
	TitleBox title_Settings_SetCondition1,userdata(tabcontrol)=  "ADC"
	TitleBox title_Settings_SetCondition1,userdata(ResizeControlsInfo)= A"!!,F]!!#Br!!#@@!!#=Sz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox title_Settings_SetCondition1,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	TitleBox title_Settings_SetCondition1,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	TitleBox title_Settings_SetCondition1,frame=0
	TitleBox title_Settings_SetCondition2,pos={126.00,308.00},size={86.00,24.00},disable=1,title="\\Z10Stop Acquisition on\rDA with Set B"
	TitleBox title_Settings_SetCondition2,userdata(tabnum)=  "5"
	TitleBox title_Settings_SetCondition2,userdata(tabcontrol)=  "ADC"
	TitleBox title_Settings_SetCondition2,userdata(ResizeControlsInfo)= A"!!,Fa!!#BT!!#?I!!#<hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox title_Settings_SetCondition2,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	TitleBox title_Settings_SetCondition2,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	TitleBox title_Settings_SetCondition2,fSize=12,frame=0
	ValDisplay valdisp_DataAcq_SweepsInSet,pos={304.00,539.00},size={30.00,21.00},bodyWidth=30,disable=1
	ValDisplay valdisp_DataAcq_SweepsInSet,userdata(tabnum)=  "0"
	ValDisplay valdisp_DataAcq_SweepsInSet,userdata(tabcontrol)=  "ADC"
	ValDisplay valdisp_DataAcq_SweepsInSet,userdata(ResizeControlsInfo)= A"!!,HS!!#Ck^]6[i!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	ValDisplay valdisp_DataAcq_SweepsInSet,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	ValDisplay valdisp_DataAcq_SweepsInSet,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	ValDisplay valdisp_DataAcq_SweepsInSet,fSize=14,fStyle=0
	ValDisplay valdisp_DataAcq_SweepsInSet,valueColor=(65535,65535,65535)
	ValDisplay valdisp_DataAcq_SweepsInSet,valueBackColor=(0,0,0)
	ValDisplay valdisp_DataAcq_SweepsInSet,limits={0,0,0},barmisc={0,1000}
	ValDisplay valdisp_DataAcq_SweepsInSet,value= #"0"
	CheckBox Check_DataAcq1_IndexingLocked,pos={216.00,694.00},size={53.00,15.00},disable=1,proc=DAP_CheckProc_IndexingState,title="Locked"
	CheckBox Check_DataAcq1_IndexingLocked,help={"Data acquisition proceeds to next wave in DAC or TTL popup menu list"}
	CheckBox Check_DataAcq1_IndexingLocked,userdata(tabnum)=  "0"
	CheckBox Check_DataAcq1_IndexingLocked,userdata(tabcontrol)=  "ADC"
	CheckBox Check_DataAcq1_IndexingLocked,userdata(ResizeControlsInfo)= A"!!,Gh!!#D=J,ho8!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_DataAcq1_IndexingLocked,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox Check_DataAcq1_IndexingLocked,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox Check_DataAcq1_IndexingLocked,value= 0
	SetVariable SetVar_DataAcq_ListRepeats,pos={204.00,710.00},size={109.00,18.00},bodyWidth=35,disable=1,proc=DAP_SetVarProc_TotSweepCount,title="Repeat List(s)"
	SetVariable SetVar_DataAcq_ListRepeats,help={"This number is set automatically at based on the number of 1d waves contained in the largest set on active DA/TTL channels"}
	SetVariable SetVar_DataAcq_ListRepeats,userdata(tabnum)=  "0"
	SetVariable SetVar_DataAcq_ListRepeats,userdata(tabcontrol)=  "ADC"
	SetVariable SetVar_DataAcq_ListRepeats,userdata(ResizeControlsInfo)= A"!!,GI!!#DAJ,hpi!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_DataAcq_ListRepeats,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable SetVar_DataAcq_ListRepeats,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable SetVar_DataAcq_ListRepeats,fColor=(65280,43520,0)
	SetVariable SetVar_DataAcq_ListRepeats,limits={1,inf,1},value= _NUM:1
	CheckBox check_DataAcq_IndexRandom,pos={216.00,677.00},size={60.00,15.00},disable=1,title="Random"
	CheckBox check_DataAcq_IndexRandom,help={"Randomly selects wave from set selected for DAC channel on each trial. Doesn't repeat waves."}
	CheckBox check_DataAcq_IndexRandom,userdata(tabnum)=  "0"
	CheckBox check_DataAcq_IndexRandom,userdata(tabcontrol)=  "ADC"
	CheckBox check_DataAcq_IndexRandom,userdata(ResizeControlsInfo)= A"!!,Gh!!#D95QF,i!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_DataAcq_IndexRandom,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_DataAcq_IndexRandom,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox check_DataAcq_IndexRandom,fColor=(65280,43520,0),value= 0
	ValDisplay valdisp_DataAcq_SweepsActiveSet,pos={304.00,566.00},size={30.00,21.00},bodyWidth=30,disable=1
	ValDisplay valdisp_DataAcq_SweepsActiveSet,help={"Displays the number of steps in the set with the most steps on active DA and TTL channels"}
	ValDisplay valdisp_DataAcq_SweepsActiveSet,userdata(tabnum)=  "0"
	ValDisplay valdisp_DataAcq_SweepsActiveSet,userdata(tabcontrol)=  "ADC"
	ValDisplay valdisp_DataAcq_SweepsActiveSet,userdata(ResizeControlsInfo)= A"!!,HS!!#CrJ,hn)!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	ValDisplay valdisp_DataAcq_SweepsActiveSet,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	ValDisplay valdisp_DataAcq_SweepsActiveSet,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	ValDisplay valdisp_DataAcq_SweepsActiveSet,fSize=14,fStyle=0
	ValDisplay valdisp_DataAcq_SweepsActiveSet,valueColor=(65535,65535,65535)
	ValDisplay valdisp_DataAcq_SweepsActiveSet,valueBackColor=(0,0,0)
	ValDisplay valdisp_DataAcq_SweepsActiveSet,limits={0,0,0},barmisc={0,1000}
	ValDisplay valdisp_DataAcq_SweepsActiveSet,value= #"0"
	SetVariable SetVar_DataAcq_TPAmplitudeIC,pos={388.00,417.00},size={65.00,18.00},bodyWidth=50,disable=1,proc=DAP_SetVarProc_TPAmp,title="IC"
	SetVariable SetVar_DataAcq_TPAmplitudeIC,help={"Amplitude of the testpulse in current clamp mode"}
	SetVariable SetVar_DataAcq_TPAmplitudeIC,userdata(tabnum)=  "0"
	SetVariable SetVar_DataAcq_TPAmplitudeIC,userdata(tabcontrol)=  "ADC"
	SetVariable SetVar_DataAcq_TPAmplitudeIC,userdata(ResizeControlsInfo)= A"!!,I(!!#C5J,hof!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_DataAcq_TPAmplitudeIC,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable SetVar_DataAcq_TPAmplitudeIC,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable SetVar_DataAcq_TPAmplitudeIC,value= _NUM:-50
	SetVariable SetVar_Hardware_VC_DA_Unit,pos={165.00,413.00},size={30.00,18.00},proc=DAP_SetVarProc_CAA
	SetVariable SetVar_Hardware_VC_DA_Unit,userdata(tabnum)=  "6"
	SetVariable SetVar_Hardware_VC_DA_Unit,userdata(tabcontrol)=  "ADC"
	SetVariable SetVar_Hardware_VC_DA_Unit,userdata(ResizeControlsInfo)= A"!!,G5!!#C3J,hn)!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_Hardware_VC_DA_Unit,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable SetVar_Hardware_VC_DA_Unit,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable SetVar_Hardware_VC_DA_Unit,value= _STR:"mV"
	SetVariable SetVar_Hardware_IC_DA_Unit,pos={344.00,414.00},size={30.00,18.00},proc=DAP_SetVarProc_CAA
	SetVariable SetVar_Hardware_IC_DA_Unit,userdata(tabnum)=  "6"
	SetVariable SetVar_Hardware_IC_DA_Unit,userdata(tabcontrol)=  "ADC"
	SetVariable SetVar_Hardware_IC_DA_Unit,userdata(ResizeControlsInfo)= A"!!,Hg!!#C4!!#=S!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_Hardware_IC_DA_Unit,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable SetVar_Hardware_IC_DA_Unit,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable SetVar_Hardware_IC_DA_Unit,value= _STR:"pA"
	SetVariable SetVar_Hardware_VC_AD_Unit,pos={186.00,438.00},size={30.00,18.00},proc=DAP_SetVarProc_CAA
	SetVariable SetVar_Hardware_VC_AD_Unit,userdata(tabnum)=  "6"
	SetVariable SetVar_Hardware_VC_AD_Unit,userdata(tabcontrol)=  "ADC"
	SetVariable SetVar_Hardware_VC_AD_Unit,userdata(ResizeControlsInfo)= A"!!,GJ!!#C@!!#=S!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_Hardware_VC_AD_Unit,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable SetVar_Hardware_VC_AD_Unit,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable SetVar_Hardware_VC_AD_Unit,value= _STR:"pA"
	SetVariable SetVar_Hardware_IC_AD_Unit,pos={367.00,438.00},size={30.00,18.00},proc=DAP_SetVarProc_CAA
	SetVariable SetVar_Hardware_IC_AD_Unit,userdata(tabnum)=  "6"
	SetVariable SetVar_Hardware_IC_AD_Unit,userdata(tabcontrol)=  "ADC"
	SetVariable SetVar_Hardware_IC_AD_Unit,userdata(ResizeControlsInfo)= A"!!,HrJ,hsk!!#=S!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_Hardware_IC_AD_Unit,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable SetVar_Hardware_IC_AD_Unit,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable SetVar_Hardware_IC_AD_Unit,value= _STR:"mV"
	TitleBox Title_Hardware_VC_gain,pos={107.00,395.00},size={23.00,15.00},title="gain"
	TitleBox Title_Hardware_VC_gain,userdata(tabnum)=  "6"
	TitleBox Title_Hardware_VC_gain,userdata(tabcontrol)=  "ADC"
	TitleBox Title_Hardware_VC_gain,userdata(ResizeControlsInfo)= A"!!,F;!!#C*J,hmF!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox Title_Hardware_VC_gain,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	TitleBox Title_Hardware_VC_gain,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	TitleBox Title_Hardware_VC_gain,frame=0
	TitleBox Title_Hardware_VC_unit,pos={183.00,395.00},size={21.00,15.00},title="unit"
	TitleBox Title_Hardware_VC_unit,userdata(tabnum)=  "6"
	TitleBox Title_Hardware_VC_unit,userdata(tabcontrol)=  "ADC"
	TitleBox Title_Hardware_VC_unit,userdata(ResizeControlsInfo)= A"!!,GG!!#C*J,hm6!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox Title_Hardware_VC_unit,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	TitleBox Title_Hardware_VC_unit,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	TitleBox Title_Hardware_VC_unit,frame=0
	TitleBox Title_Hardware_IC_gain,pos={289.00,395.00},size={23.00,15.00},title="gain"
	TitleBox Title_Hardware_IC_gain,userdata(tabnum)=  "6"
	TitleBox Title_Hardware_IC_gain,userdata(tabcontrol)=  "ADC"
	TitleBox Title_Hardware_IC_gain,userdata(ResizeControlsInfo)= A"!!,HKJ,hsUJ,hmF!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox Title_Hardware_IC_gain,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	TitleBox Title_Hardware_IC_gain,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	TitleBox Title_Hardware_IC_gain,frame=0
	TitleBox Title_Hardware_IC_unit,pos={345.00,395.00},size={21.00,15.00},title="unit"
	TitleBox Title_Hardware_IC_unit,userdata(tabnum)=  "6"
	TitleBox Title_Hardware_IC_unit,userdata(tabcontrol)=  "ADC"
	TitleBox Title_Hardware_IC_unit,userdata(ResizeControlsInfo)= A"!!,HgJ,hsUJ,hm6!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox Title_Hardware_IC_unit,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	TitleBox Title_Hardware_IC_unit,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	TitleBox Title_Hardware_IC_unit,frame=0
	SetVariable Unit_DA_00,pos={105.00,75.00},size={30.00,18.00},disable=1
	SetVariable Unit_DA_00,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	SetVariable Unit_DA_00,userdata(ResizeControlsInfo)= A"!!,F7!!#?O!!#=S!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Unit_DA_00,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable Unit_DA_00,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable Unit_DA_00,limits={0,inf,1},value= _STR:""
	TitleBox Title_DA_Unit,pos={105.00,50.00},size={24.00,15.00},disable=1,title="Unit"
	TitleBox Title_DA_Unit,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	TitleBox Title_DA_Unit,userdata(ResizeControlsInfo)= A"!!,F7!!#>V!!#=#!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox Title_DA_Unit,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	TitleBox Title_DA_Unit,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	TitleBox Title_DA_Unit,frame=0,fStyle=1
	SetVariable Unit_DA_01,pos={105.00,121.00},size={30.00,18.00},disable=1
	SetVariable Unit_DA_01,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	SetVariable Unit_DA_01,userdata(ResizeControlsInfo)= A"!!,F7!!#@V!!#=S!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Unit_DA_01,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable Unit_DA_01,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable Unit_DA_01,limits={0,inf,1},value= _STR:""
	SetVariable Unit_DA_02,pos={105.00,167.00},size={30.00,18.00},disable=1
	SetVariable Unit_DA_02,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	SetVariable Unit_DA_02,userdata(ResizeControlsInfo)= A"!!,F7!!#A6!!#=S!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Unit_DA_02,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable Unit_DA_02,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable Unit_DA_02,limits={0,inf,1},value= _STR:""
	SetVariable Unit_DA_03,pos={105.00,214.00},size={30.00,18.00},disable=1
	SetVariable Unit_DA_03,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	SetVariable Unit_DA_03,userdata(ResizeControlsInfo)= A"!!,F7!!#Ae!!#=S!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Unit_DA_03,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable Unit_DA_03,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable Unit_DA_03,limits={0,inf,1},value= _STR:""
	SetVariable Unit_DA_04,pos={105.00,260.00},size={30.00,18.00},disable=1
	SetVariable Unit_DA_04,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	SetVariable Unit_DA_04,userdata(ResizeControlsInfo)= A"!!,F7!!#B<!!#=S!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Unit_DA_04,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable Unit_DA_04,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable Unit_DA_04,limits={0,inf,1},value= _STR:""
	SetVariable Unit_DA_05,pos={105.00,307.00},size={30.00,18.00},disable=1
	SetVariable Unit_DA_05,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	SetVariable Unit_DA_05,userdata(ResizeControlsInfo)= A"!!,F7!!#BSJ,hn)!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Unit_DA_05,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable Unit_DA_05,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable Unit_DA_05,limits={0,inf,1},value= _STR:""
	SetVariable Unit_DA_06,pos={105.00,353.00},size={30.00,18.00},disable=1
	SetVariable Unit_DA_06,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	SetVariable Unit_DA_06,userdata(ResizeControlsInfo)= A"!!,F7!!#BjJ,hn)!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Unit_DA_06,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable Unit_DA_06,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable Unit_DA_06,limits={0,inf,1},value= _STR:""
	SetVariable Unit_DA_07,pos={105.00,400.00},size={30.00,18.00},disable=1
	SetVariable Unit_DA_07,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	SetVariable Unit_DA_07,userdata(ResizeControlsInfo)= A"!!,F7!!#C-!!#=S!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Unit_DA_07,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable Unit_DA_07,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable Unit_DA_07,limits={0,inf,1},value= _STR:""
	SetVariable Unit_AD_00,pos={110.00,75.00},size={40.00,18.00},disable=1,title="V/"
	SetVariable Unit_AD_00,userdata(tabnum)=  "2",userdata(tabcontrol)=  "ADC"
	SetVariable Unit_AD_00,userdata(ResizeControlsInfo)= A"!!,FA!!#?O!!#>.!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Unit_AD_00,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable Unit_AD_00,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable Unit_AD_00,limits={0,inf,1},value= _STR:""
	SetVariable Unit_AD_01,pos={110.00,121.00},size={40.00,18.00},disable=1,title="V/"
	SetVariable Unit_AD_01,userdata(tabnum)=  "2",userdata(tabcontrol)=  "ADC"
	SetVariable Unit_AD_01,userdata(ResizeControlsInfo)= A"!!,FA!!#@V!!#>.!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Unit_AD_01,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable Unit_AD_01,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable Unit_AD_01,limits={0,inf,1},value= _STR:""
	SetVariable Unit_AD_02,pos={110.00,167.00},size={40.00,18.00},disable=1,title="V/"
	SetVariable Unit_AD_02,userdata(tabnum)=  "2",userdata(tabcontrol)=  "ADC"
	SetVariable Unit_AD_02,userdata(ResizeControlsInfo)= A"!!,FA!!#A6!!#>.!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Unit_AD_02,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable Unit_AD_02,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable Unit_AD_02,limits={0,inf,1},value= _STR:""
	SetVariable Unit_AD_03,pos={110.00,214.00},size={40.00,18.00},disable=1,title="V/"
	SetVariable Unit_AD_03,userdata(tabnum)=  "2",userdata(tabcontrol)=  "ADC"
	SetVariable Unit_AD_03,userdata(ResizeControlsInfo)= A"!!,FA!!#Ae!!#>.!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Unit_AD_03,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable Unit_AD_03,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable Unit_AD_03,limits={0,inf,1},value= _STR:""
	SetVariable Unit_AD_04,pos={110.00,260.00},size={40.00,18.00},disable=1,title="V/"
	SetVariable Unit_AD_04,userdata(tabnum)=  "2",userdata(tabcontrol)=  "ADC"
	SetVariable Unit_AD_04,userdata(ResizeControlsInfo)= A"!!,FA!!#B<!!#>.!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Unit_AD_04,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable Unit_AD_04,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable Unit_AD_04,limits={0,inf,1},value= _STR:""
	SetVariable Unit_AD_05,pos={110.00,307.00},size={40.00,18.00},disable=1,title="V/"
	SetVariable Unit_AD_05,userdata(tabnum)=  "2",userdata(tabcontrol)=  "ADC"
	SetVariable Unit_AD_05,userdata(ResizeControlsInfo)= A"!!,FA!!#BSJ,hnY!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Unit_AD_05,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable Unit_AD_05,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable Unit_AD_05,limits={0,inf,1},value= _STR:""
	SetVariable Unit_AD_06,pos={110.00,353.00},size={40.00,18.00},disable=1,title="V/"
	SetVariable Unit_AD_06,userdata(tabnum)=  "2",userdata(tabcontrol)=  "ADC"
	SetVariable Unit_AD_06,userdata(ResizeControlsInfo)= A"!!,FA!!#BjJ,hnY!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Unit_AD_06,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable Unit_AD_06,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable Unit_AD_06,limits={0,inf,1},value= _STR:""
	SetVariable Unit_AD_07,pos={110.00,400.00},size={40.00,18.00},disable=1,title="V/"
	SetVariable Unit_AD_07,userdata(tabnum)=  "2",userdata(tabcontrol)=  "ADC"
	SetVariable Unit_AD_07,userdata(ResizeControlsInfo)= A"!!,FA!!#C-!!#>.!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Unit_AD_07,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable Unit_AD_07,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable Unit_AD_07,limits={0,inf,1},value= _STR:""
	SetVariable Unit_AD_08,pos={290.00,75.00},size={40.00,18.00},disable=1,title="V/"
	SetVariable Unit_AD_08,userdata(tabnum)=  "2",userdata(tabcontrol)=  "ADC"
	SetVariable Unit_AD_08,userdata(ResizeControlsInfo)= A"!!,HL!!#?O!!#>.!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Unit_AD_08,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable Unit_AD_08,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable Unit_AD_08,limits={0,inf,1},value= _STR:""
	SetVariable Unit_AD_09,pos={290.00,121.00},size={40.00,18.00},disable=1,title="V/"
	SetVariable Unit_AD_09,userdata(tabnum)=  "2",userdata(tabcontrol)=  "ADC"
	SetVariable Unit_AD_09,userdata(ResizeControlsInfo)= A"!!,HL!!#@V!!#>.!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Unit_AD_09,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable Unit_AD_09,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable Unit_AD_09,limits={0,inf,1},value= _STR:""
	SetVariable Unit_AD_10,pos={290.00,167.00},size={40.00,18.00},disable=1,title="V/"
	SetVariable Unit_AD_10,userdata(tabnum)=  "2",userdata(tabcontrol)=  "ADC"
	SetVariable Unit_AD_10,userdata(ResizeControlsInfo)= A"!!,HL!!#A6!!#>.!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Unit_AD_10,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable Unit_AD_10,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable Unit_AD_10,limits={0,inf,1},value= _STR:""
	SetVariable Unit_AD_11,pos={290.00,214.00},size={40.00,18.00},disable=1,title="V/"
	SetVariable Unit_AD_11,userdata(tabnum)=  "2",userdata(tabcontrol)=  "ADC"
	SetVariable Unit_AD_11,userdata(ResizeControlsInfo)= A"!!,HL!!#Ae!!#>.!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Unit_AD_11,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable Unit_AD_11,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable Unit_AD_11,limits={0,inf,1},value= _STR:""
	SetVariable Unit_AD_12,pos={290.00,260.00},size={40.00,18.00},disable=1,title="V/"
	SetVariable Unit_AD_12,userdata(tabnum)=  "2",userdata(tabcontrol)=  "ADC"
	SetVariable Unit_AD_12,userdata(ResizeControlsInfo)= A"!!,HL!!#B<!!#>.!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Unit_AD_12,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable Unit_AD_12,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable Unit_AD_12,limits={0,inf,1},value= _STR:""
	SetVariable Unit_AD_13,pos={290.00,307.00},size={40.00,18.00},disable=1,title="V/"
	SetVariable Unit_AD_13,userdata(tabnum)=  "2",userdata(tabcontrol)=  "ADC"
	SetVariable Unit_AD_13,userdata(ResizeControlsInfo)= A"!!,HL!!#BSJ,hnY!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Unit_AD_13,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable Unit_AD_13,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable Unit_AD_13,limits={0,inf,1},value= _STR:""
	SetVariable Unit_AD_14,pos={290.00,353.00},size={40.00,18.00},disable=1,title="V/"
	SetVariable Unit_AD_14,userdata(tabnum)=  "2",userdata(tabcontrol)=  "ADC"
	SetVariable Unit_AD_14,userdata(ResizeControlsInfo)= A"!!,HL!!#BjJ,hnY!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Unit_AD_14,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable Unit_AD_14,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable Unit_AD_14,limits={0,inf,1},value= _STR:""
	SetVariable Unit_AD_15,pos={290.00,400.00},size={40.00,18.00},disable=1,title="V/"
	SetVariable Unit_AD_15,userdata(tabnum)=  "2",userdata(tabcontrol)=  "ADC"
	SetVariable Unit_AD_15,userdata(ResizeControlsInfo)= A"!!,HL!!#C-!!#>.!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Unit_AD_15,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable Unit_AD_15,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable Unit_AD_15,limits={0,inf,1},value= _STR:""
	TitleBox Title_AD_Unit,pos={122.00,50.00},size={24.00,15.00},disable=1,title="Unit"
	TitleBox Title_AD_Unit,userdata(tabnum)=  "2",userdata(tabcontrol)=  "ADC"
	TitleBox Title_AD_Unit,userdata(ResizeControlsInfo)= A"!!,FY!!#>V!!#=#!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox Title_AD_Unit,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	TitleBox Title_AD_Unit,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	TitleBox Title_AD_Unit,frame=0,fStyle=1
	TitleBox Title_AD_Gain,pos={55.00,50.00},size={25.00,15.00},disable=1,title="Gain"
	TitleBox Title_AD_Gain,userdata(tabnum)=  "2",userdata(tabcontrol)=  "ADC"
	TitleBox Title_AD_Gain,userdata(ResizeControlsInfo)= A"!!,Dk!!#>V!!#=+!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox Title_AD_Gain,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	TitleBox Title_AD_Gain,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	TitleBox Title_AD_Gain,frame=0,fStyle=1
	TitleBox Title_AD_Channel,pos={25.00,50.00},size={17.00,15.00},disable=1,title="AD"
	TitleBox Title_AD_Channel,userdata(tabnum)=  "2",userdata(tabcontrol)=  "ADC"
	TitleBox Title_AD_Channel,userdata(ResizeControlsInfo)= A"!!,C,!!#>V!!#<@!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox Title_AD_Channel,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	TitleBox Title_AD_Channel,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	TitleBox Title_AD_Channel,frame=0,fStyle=1
	TitleBox Title_AD_Channel1,pos={195.00,50.00},size={17.00,15.00},disable=1,title="AD"
	TitleBox Title_AD_Channel1,userdata(tabnum)=  "2",userdata(tabcontrol)=  "ADC"
	TitleBox Title_AD_Channel1,userdata(ResizeControlsInfo)= A"!!,GS!!#>V!!#<@!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox Title_AD_Channel1,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	TitleBox Title_AD_Channel1,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	TitleBox Title_AD_Channel1,frame=0,fStyle=1
	TitleBox Title_AD_Gain1,pos={233.00,50.00},size={25.00,15.00},disable=1,title="Gain"
	TitleBox Title_AD_Gain1,userdata(tabnum)=  "2",userdata(tabcontrol)=  "ADC"
	TitleBox Title_AD_Gain1,userdata(ResizeControlsInfo)= A"!!,H$!!#>V!!#=+!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox Title_AD_Gain1,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	TitleBox Title_AD_Gain1,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	TitleBox Title_AD_Gain1,frame=0,fStyle=1
	TitleBox Title_AD_Unit1,pos={294.00,50.00},size={24.00,15.00},disable=1,title="Unit"
	TitleBox Title_AD_Unit1,userdata(tabnum)=  "2",userdata(tabcontrol)=  "ADC"
	TitleBox Title_AD_Unit1,userdata(ResizeControlsInfo)= A"!!,HN!!#>V!!#=#!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox Title_AD_Unit1,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	TitleBox Title_AD_Unit1,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	TitleBox Title_AD_Unit1,frame=0,fStyle=1
	TitleBox Title_Hardware_VC_DA_Div,pos={199.00,415.00},size={15.00,15.00},title="/ V"
	TitleBox Title_Hardware_VC_DA_Div,userdata(tabnum)=  "6"
	TitleBox Title_Hardware_VC_DA_Div,userdata(tabcontrol)=  "ADC"
	TitleBox Title_Hardware_VC_DA_Div,userdata(ResizeControlsInfo)= A"!!,GW!!#C4J,hlS!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox Title_Hardware_VC_DA_Div,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	TitleBox Title_Hardware_VC_DA_Div,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	TitleBox Title_Hardware_VC_DA_Div,frame=0
	TitleBox Title_Hardware_IC_DA_Div,pos={376.00,415.00},size={15.00,15.00},title="/ V"
	TitleBox Title_Hardware_IC_DA_Div,userdata(tabnum)=  "6"
	TitleBox Title_Hardware_IC_DA_Div,userdata(tabcontrol)=  "ADC"
	TitleBox Title_Hardware_IC_DA_Div,userdata(ResizeControlsInfo)= A"!!,I\"!!#C4J,hlS!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox Title_Hardware_IC_DA_Div,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	TitleBox Title_Hardware_IC_DA_Div,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	TitleBox Title_Hardware_IC_DA_Div,frame=0
	TitleBox Title_Hardware_IC_AD_Div,pos={349.00,440.00},size={15.00,15.00},title="V /"
	TitleBox Title_Hardware_IC_AD_Div,userdata(tabnum)=  "6"
	TitleBox Title_Hardware_IC_AD_Div,userdata(tabcontrol)=  "ADC"
	TitleBox Title_Hardware_IC_AD_Div,userdata(ResizeControlsInfo)= A"!!,HiJ,hsl!!#<(!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox Title_Hardware_IC_AD_Div,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	TitleBox Title_Hardware_IC_AD_Div,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	TitleBox Title_Hardware_IC_AD_Div,frame=0
	TitleBox Title_Hardware_IC_AD_Div1,pos={167.00,440.00},size={15.00,15.00},title="V /"
	TitleBox Title_Hardware_IC_AD_Div1,userdata(tabnum)=  "6"
	TitleBox Title_Hardware_IC_AD_Div1,userdata(tabcontrol)=  "ADC"
	TitleBox Title_Hardware_IC_AD_Div1,userdata(ResizeControlsInfo)= A"!!,G7!!#CA!!#<(!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox Title_Hardware_IC_AD_Div1,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	TitleBox Title_Hardware_IC_AD_Div1,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	TitleBox Title_Hardware_IC_AD_Div1,frame=0
	GroupBox GroupBox_Hardware_Associations,pos={24.00,305.00},size={445.00,350.00},title="DAC Channel and Device Associations"
	GroupBox GroupBox_Hardware_Associations,userdata(tabnum)=  "6"
	GroupBox GroupBox_Hardware_Associations,userdata(tabcontrol)=  "ADC"
	GroupBox GroupBox_Hardware_Associations,userdata(ResizeControlsInfo)= A"!!,C$!!#BRJ,hsnJ,hs?z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	GroupBox GroupBox_Hardware_Associations,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	GroupBox GroupBox_Hardware_Associations,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	GroupBox group_Settings_DatAcq,pos={20.00,169.00},size={445.00,258.00},disable=1,title="Data Acquisition"
	GroupBox group_Settings_DatAcq,userdata(tabnum)=  "5"
	GroupBox group_Settings_DatAcq,userdata(tabcontrol)=  "ADC"
	GroupBox group_Settings_DatAcq,userdata(ResizeControlsInfo)= A"!!,BY!!#A8!!#CCJ,hrfz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	GroupBox group_Settings_DatAcq,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	GroupBox group_Settings_DatAcq,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	GroupBox group_Settings_Asynch,pos={21.00,431.00},size={445.00,90.00},disable=1,title="Asynchronous"
	GroupBox group_Settings_Asynch,userdata(tabnum)=  "5"
	GroupBox group_Settings_Asynch,userdata(tabcontrol)=  "ADC"
	GroupBox group_Settings_Asynch,userdata(ResizeControlsInfo)= A"!!,Ba!!#C<J,hsnJ,hpCz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	GroupBox group_Settings_Asynch,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	GroupBox group_Settings_Asynch,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	GroupBox group_Settings_TP,pos={21.00,68.00},size={445.00,90.00},disable=1,title="Test Pulse"
	GroupBox group_Settings_TP,userdata(tabnum)=  "5",userdata(tabcontrol)=  "ADC"
	GroupBox group_Settings_TP,userdata(ResizeControlsInfo)= A"!!,Ba!!#?A!!#CCJ,hpCz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	GroupBox group_Settings_TP,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	GroupBox group_Settings_TP,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	GroupBox group_Settings_Asynch1,pos={21.00,528.00},size={445.00,40.00},disable=1,title="Oscilloscope"
	GroupBox group_Settings_Asynch1,userdata(tabnum)=  "5"
	GroupBox group_Settings_Asynch1,userdata(tabcontrol)=  "ADC"
	GroupBox group_Settings_Asynch1,userdata(ResizeControlsInfo)= A"!!,Ba!!#Ci!!#CCJ,hnYz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	GroupBox group_Settings_Asynch1,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	GroupBox group_Settings_Asynch1,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	GroupBox group_DataAcq_ClampMode,pos={30.00,39.00},size={445.00,350.00},disable=1,title="Headstage"
	GroupBox group_DataAcq_ClampMode,userdata(tabnum)=  "0"
	GroupBox group_DataAcq_ClampMode,userdata(tabcontrol)=  "ADC"
	GroupBox group_DataAcq_ClampMode,userdata(ResizeControlsInfo)= A"!!,CT!!#>*!!#CCJ,hs?z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	GroupBox group_DataAcq_ClampMode,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	GroupBox group_DataAcq_ClampMode,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	GroupBox group_DataAcq_ClampMode1,pos={30.00,394.00},size={445.00,100.00},disable=1,title="Test Pulse"
	GroupBox group_DataAcq_ClampMode1,userdata(tabnum)=  "0"
	GroupBox group_DataAcq_ClampMode1,userdata(tabcontrol)=  "ADC"
	GroupBox group_DataAcq_ClampMode1,userdata(ResizeControlsInfo)= A"!!,CT!!#C*!!#CCJ,hpWz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	GroupBox group_DataAcq_ClampMode1,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	GroupBox group_DataAcq_ClampMode1,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	GroupBox group_DataAcq_ClampMode2,pos={30.00,498.00},size={445.00,120.00},disable=1,title="Status Information"
	GroupBox group_DataAcq_ClampMode2,userdata(tabnum)=  "0"
	GroupBox group_DataAcq_ClampMode2,userdata(tabcontrol)=  "ADC"
	GroupBox group_DataAcq_ClampMode2,userdata(ResizeControlsInfo)= A"!!,CT!!#C^!!#CCJ,hq*z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	GroupBox group_DataAcq_ClampMode2,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	GroupBox group_DataAcq_ClampMode2,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	TitleBox title_DataAcq_NextSweep,pos={217.00,513.00},size={71.00,19.00},disable=1,title="Next Sweep"
	TitleBox title_DataAcq_NextSweep,userdata(tabnum)=  "0"
	TitleBox title_DataAcq_NextSweep,userdata(tabcontrol)=  "ADC"
	TitleBox title_DataAcq_NextSweep,userdata(ResizeControlsInfo)= A"!!,Gi!!#Ce5QF-2!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox title_DataAcq_NextSweep,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	TitleBox title_DataAcq_NextSweep,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	TitleBox title_DataAcq_NextSweep,fSize=14,frame=0,fStyle=0
	TitleBox title_DataAcq_NextSweep1,pos={341.00,540.00},size={79.00,19.00},disable=1,title="Total Sweeps"
	TitleBox title_DataAcq_NextSweep1,userdata(tabnum)=  "0"
	TitleBox title_DataAcq_NextSweep1,userdata(tabcontrol)=  "ADC"
	TitleBox title_DataAcq_NextSweep1,userdata(ResizeControlsInfo)= A"!!,HeJ,htB!!#?W!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox title_DataAcq_NextSweep1,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	TitleBox title_DataAcq_NextSweep1,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	TitleBox title_DataAcq_NextSweep1,fSize=14,frame=0,fStyle=0
	TitleBox title_DataAcq_NextSweep2,pos={341.00,567.00},size={98.00,19.00},disable=1,title="Set Max Sweeps"
	TitleBox title_DataAcq_NextSweep2,userdata(tabnum)=  "0"
	TitleBox title_DataAcq_NextSweep2,userdata(tabcontrol)=  "ADC"
	TitleBox title_DataAcq_NextSweep2,userdata(ResizeControlsInfo)= A"!!,HeJ,htH^]6^>!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox title_DataAcq_NextSweep2,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	TitleBox title_DataAcq_NextSweep2,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	TitleBox title_DataAcq_NextSweep2,fSize=14,frame=0,fStyle=0
	TitleBox title_DataAcq_NextSweep3,pos={188.00,592.00},size={132.00,19.00},disable=1,title="Sampling Interval (µs)"
	TitleBox title_DataAcq_NextSweep3,userdata(tabnum)=  "0"
	TitleBox title_DataAcq_NextSweep3,userdata(tabcontrol)=  "ADC"
	TitleBox title_DataAcq_NextSweep3,userdata(ResizeControlsInfo)= A"!!,GL!!#D$!!#@h!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox title_DataAcq_NextSweep3,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	TitleBox title_DataAcq_NextSweep3,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	TitleBox title_DataAcq_NextSweep3,fSize=14,frame=0,fStyle=0
	GroupBox group_DataAcq_DataAcq,pos={30.00,622.00},size={445.00,185.00},disable=1,title="Data Acquisition"
	GroupBox group_DataAcq_DataAcq,userdata(tabnum)=  "0"
	GroupBox group_DataAcq_DataAcq,userdata(tabcontrol)=  "ADC"
	GroupBox group_DataAcq_DataAcq,userdata(ResizeControlsInfo)= A"!!,CT!!#D+J,hsnJ,hqsz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	GroupBox group_DataAcq_DataAcq,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	GroupBox group_DataAcq_DataAcq,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	GroupBox group_Hardware_Yoke,pos={24.00,155.00},size={445.00,145.00},title="Yoke"
	GroupBox group_Hardware_Yoke,help={"Yoking is only available for >1 ITC1600, however, It is not a requirement for the use of multiple ITC1600s asyncronously."}
	GroupBox group_Hardware_Yoke,userdata(tabnum)=  "6",userdata(tabcontrol)=  "ADC"
	GroupBox group_Hardware_Yoke,userdata(ResizeControlsInfo)= A"!!,C$!!#A*!!#CCJ,hqKz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	GroupBox group_Hardware_Yoke,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	GroupBox group_Hardware_Yoke,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	GroupBox group_Hardware_Yoke,fSize=12
	Button button_Hardware_Lead1600,pos={29.00,195.00},size={80.00,21.00},disable=3,proc=DAP_ButtonProc_Lead,title="Lead"
	Button button_Hardware_Lead1600,help={"For ITC1600 devices only. Sets locked ITC device as the lead. User must now assign follower devices."}
	Button button_Hardware_Lead1600,userdata(tabnum)=  "6"
	Button button_Hardware_Lead1600,userdata(tabcontrol)=  "ADC"
	Button button_Hardware_Lead1600,userdata(ResizeControlsInfo)= A"!!,CL!!#AR!!#?Y!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_Hardware_Lead1600,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	Button button_Hardware_Lead1600,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	PopupMenu popup_Hardware_AvailITC1600s,pos={26.00,240.00},size={113.00,19.00},bodyWidth=110,disable=3,title="Locked ITC1600s"
	PopupMenu popup_Hardware_AvailITC1600s,userdata(tabnum)=  "6"
	PopupMenu popup_Hardware_AvailITC1600s,userdata(tabcontrol)=  "ADC"
	PopupMenu popup_Hardware_AvailITC1600s,userdata(ResizeControlsInfo)= A"!!,CL!!#B*!!#@@!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu popup_Hardware_AvailITC1600s,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	PopupMenu popup_Hardware_AvailITC1600s,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	PopupMenu popup_Hardware_AvailITC1600s,mode=0,value= #"DAP_ListOfITCDevices()"
	Button button_Hardware_AddFollower,pos={141.00,240.00},size={80.00,21.00},disable=3,proc=DAP_ButtonProc_Follow,title="Follow"
	Button button_Hardware_AddFollower,help={"For ITC1600 devices only. Sets locked ITC device as a follower. Select leader from other locked ITC1600s panel. This will disable data aquistion directly from this panel."}
	Button button_Hardware_AddFollower,userdata(tabnum)=  "6"
	Button button_Hardware_AddFollower,userdata(tabcontrol)=  "ADC"
	Button button_Hardware_AddFollower,userdata(ResizeControlsInfo)= A"!!,Fr!!#B*!!#?Y!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_Hardware_AddFollower,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	Button button_Hardware_AddFollower,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	TitleBox title_hardware_1600inst,pos={29.00,176.00},size={231.00,15.00},disable=3,title="To yoke devices go to panel: ITC1600_Dev_0"
	TitleBox title_hardware_1600inst,help={"If the device is designated to follow, the test pulse and data aquisition will be triggered from the lead panel."}
	TitleBox title_hardware_1600inst,userdata(tabnum)=  "6"
	TitleBox title_hardware_1600inst,userdata(tabcontrol)=  "ADC"
	TitleBox title_hardware_1600inst,userdata(ResizeControlsInfo)= A"!!,CL!!#A?!!#Ak!!#;]z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox title_hardware_1600inst,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	TitleBox title_hardware_1600inst,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	TitleBox title_hardware_1600inst,frame=0
	Button button_Hardware_Independent,pos={111.00,195.00},size={80.00,21.00},disable=3,proc=DAP_ButtonProc_Independent,title="Independent"
	Button button_Hardware_Independent,help={"For ITC1600 devices only. Sets locked ITC device as the lead. User must now assign follower devices."}
	Button button_Hardware_Independent,userdata(tabnum)=  "6"
	Button button_Hardware_Independent,userdata(tabcontrol)=  "ADC"
	Button button_Hardware_Independent,userdata(ResizeControlsInfo)= A"!!,FC!!#AR!!#?Y!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_Hardware_Independent,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	Button button_Hardware_Independent,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable setvar_Hardware_Status,pos={152.00,812.00},size={189.00,18.00},bodyWidth=99,title="ITC DAC Status:"
	SetVariable setvar_Hardware_Status,userdata(ResizeControlsInfo)= A"!!,G(!!#D[!!#AL!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_Hardware_Status,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable setvar_Hardware_Status,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable setvar_Hardware_Status,frame=0,fStyle=1,fColor=(65280,0,0)
	SetVariable setvar_Hardware_Status,valueBackColor=(60928,60928,60928)
	SetVariable setvar_Hardware_Status,value= _STR:"Independent",noedit= 1
	TitleBox title_hardware_Follow,pos={29.00,222.00},size={177.00,15.00},disable=3,title="Assign ITC1600 DACs as followers"
	TitleBox title_hardware_Follow,help={"If the device is designated to follow, the test pulse and data aquisition will be triggered from the lead panel."}
	TitleBox title_hardware_Follow,userdata(tabnum)=  "6"
	TitleBox title_hardware_Follow,userdata(tabcontrol)=  "ADC"
	TitleBox title_hardware_Follow,userdata(ResizeControlsInfo)= A"!!,CL!!#Am!!#A2!!#;]z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox title_hardware_Follow,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	TitleBox title_hardware_Follow,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	TitleBox title_hardware_Follow,frame=0
	SetVariable setvar_Hardware_YokeList,pos={29.00,272.00},size={300.00,18.00},title="Yoked DACs:"
	SetVariable setvar_Hardware_YokeList,userdata(tabnum)=  "6"
	SetVariable setvar_Hardware_YokeList,userdata(tabcontrol)=  "ADC"
	SetVariable setvar_Hardware_YokeList,userdata(ResizeControlsInfo)= A"!!,CL!!#BB!!#BP!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_Hardware_YokeList,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable setvar_Hardware_YokeList,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable setvar_Hardware_YokeList,labelBack=(60928,60928,60928),frame=0
	SetVariable setvar_Hardware_YokeList,value= _STR:"Device is not yokeable",noedit= 1
	Button button_Hardware_RemoveYoke,pos={335.00,240.00},size={80.00,21.00},disable=3,proc=DAP_ButtonProc_YokeRelease,title="Release"
	Button button_Hardware_RemoveYoke,userdata(tabnum)=  "6"
	Button button_Hardware_RemoveYoke,userdata(tabcontrol)=  "ADC"
	Button button_Hardware_RemoveYoke,userdata(ResizeControlsInfo)= A"!!,HbJ,hrU!!#?Y!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_Hardware_RemoveYoke,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	Button button_Hardware_RemoveYoke,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	PopupMenu popup_Hardware_YokedDACs,pos={220.00,240.00},size={113.00,19.00},bodyWidth=110,disable=3,title="Yoked ITC1600s"
	PopupMenu popup_Hardware_YokedDACs,userdata(tabnum)=  "6"
	PopupMenu popup_Hardware_YokedDACs,userdata(tabcontrol)=  "ADC"
	PopupMenu popup_Hardware_YokedDACs,userdata(ResizeControlsInfo)= A"!!,Go!!#B*!!#@@!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu popup_Hardware_YokedDACs,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	PopupMenu popup_Hardware_YokedDACs,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	PopupMenu popup_Hardware_YokedDACs,mode=0,value= #"DAP_GUIListOfYokedDevices()"
	TitleBox title_hardware_Release,pos={225.00,222.00},size={162.00,15.00},disable=3,title="Release follower ITC1600 DACs"
	TitleBox title_hardware_Release,help={"If the device is designated to follow, the test pulse and data aquisition will be triggered from the lead panel."}
	TitleBox title_hardware_Release,userdata(tabnum)=  "6"
	TitleBox title_hardware_Release,userdata(tabcontrol)=  "ADC"
	TitleBox title_hardware_Release,userdata(ResizeControlsInfo)= A"!!,Gq!!#Am!!#A'!!#;]z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox title_hardware_Release,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	TitleBox title_hardware_Release,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	TitleBox title_hardware_Release,frame=0
	TabControl tab_DataAcq_Amp,pos={38.00,148.00},size={425.00,120.00},disable=1,proc=ACL_DisplayTab
	TabControl tab_DataAcq_Amp,userdata(tabnum)=  "0",userdata(tabcontrol)=  "ADC"
	TabControl tab_DataAcq_Amp,userdata(currenttab)=  "0"
	TabControl tab_DataAcq_Amp,userdata(ResizeControlsInfo)= A"!!,D'!!#A#!!#C9J,hq*z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TabControl tab_DataAcq_Amp,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	TabControl tab_DataAcq_Amp,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	TabControl tab_DataAcq_Amp,labelBack=(60928,60928,60928),fSize=10
	TabControl tab_DataAcq_Amp,tabLabel(0)="V-Clamp",tabLabel(1)="I-Clamp"
	TabControl tab_DataAcq_Amp,tabLabel(2)="\f01\Z11I = 0",value= 0
	TitleBox Title_DataAcq_Hold_IC,pos={97.00,186.00},size={69.00,15.00},disable=1,title="Holding (pA)"
	TitleBox Title_DataAcq_Hold_IC,userdata(tabnum)=  "1"
	TitleBox Title_DataAcq_Hold_IC,userdata(tabcontrol)=  "tab_DataAcq_Amp"
	TitleBox Title_DataAcq_Hold_IC,userdata(ResizeControlsInfo)= A"!!,EF!!#A=!!#?!!!#;]z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox Title_DataAcq_Hold_IC,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	TitleBox Title_DataAcq_Hold_IC,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	TitleBox Title_DataAcq_Hold_IC,frame=0
	TitleBox Title_DataAcq_Bridge,pos={56.00,208.00},size={110.00,16.00},disable=1,title="Bridge Balance (M\\F'Symbol'W\\F]0)"
	TitleBox Title_DataAcq_Bridge,userdata(tabnum)=  "1"
	TitleBox Title_DataAcq_Bridge,userdata(tabcontrol)=  "tab_DataAcq_Amp"
	TitleBox Title_DataAcq_Bridge,userdata(ResizeControlsInfo)= A"!!,D7!!#AP!!#@,!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox Title_DataAcq_Bridge,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	TitleBox Title_DataAcq_Bridge,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	TitleBox Title_DataAcq_Bridge,frame=0
	SetVariable setvar_DataAcq_Hold_IC,pos={167.00,185.00},size={50.00,18.00},bodyWidth=50,disable=1,proc=DAP_SetVarProc_AmpCntrls
	SetVariable setvar_DataAcq_Hold_IC,userdata(tabnum)=  "1"
	SetVariable setvar_DataAcq_Hold_IC,userdata(tabcontrol)=  "tab_DataAcq_Amp"
	SetVariable setvar_DataAcq_Hold_IC,userdata(ResizeControlsInfo)= A"!!,G(!!#A<!!#=s!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_DataAcq_Hold_IC,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable setvar_DataAcq_Hold_IC,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable setvar_DataAcq_Hold_IC,value= _NUM:0
	SetVariable setvar_DataAcq_BB,pos={167.00,208.00},size={50.00,18.00},bodyWidth=50,disable=1,proc=DAP_SetVarProc_AmpCntrls
	SetVariable setvar_DataAcq_BB,userdata(tabnum)=  "1"
	SetVariable setvar_DataAcq_BB,userdata(tabcontrol)=  "tab_DataAcq_Amp"
	SetVariable setvar_DataAcq_BB,userdata(ResizeControlsInfo)= A"!!,G(!!#AO!!#=s!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_DataAcq_BB,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable setvar_DataAcq_BB,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable setvar_DataAcq_BB,limits={0,inf,1},value= _NUM:0
	SetVariable setvar_DataAcq_CN,pos={167.00,231.00},size={50.00,18.00},bodyWidth=50,disable=1,proc=DAP_SetVarProc_AmpCntrls
	SetVariable setvar_DataAcq_CN,userdata(tabnum)=  "1"
	SetVariable setvar_DataAcq_CN,userdata(tabcontrol)=  "tab_DataAcq_Amp"
	SetVariable setvar_DataAcq_CN,userdata(ResizeControlsInfo)= A"!!,G(!!#Ab!!#=s!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_DataAcq_CN,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable setvar_DataAcq_CN,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable setvar_DataAcq_CN,limits={-8,16,1},value= _NUM:0
	CheckBox check_DatAcq_HoldEnable,pos={223.00,187.00},size={13.00,13.00},disable=1,proc=DAP_CheckProc_AmpCntrls,title=""
	CheckBox check_DatAcq_HoldEnable,userdata(tabnum)=  "1"
	CheckBox check_DatAcq_HoldEnable,userdata(tabcontrol)=  "tab_DataAcq_Amp"
	CheckBox check_DatAcq_HoldEnable,userdata(ResizeControlsInfo)= A"!!,GS!!#A=!!#>Z!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_DatAcq_HoldEnable,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_DatAcq_HoldEnable,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox check_DatAcq_HoldEnable,value= 0
	CheckBox check_DatAcq_BBEnable,pos={223.00,210.00},size={13.00,13.00},disable=1,proc=DAP_CheckProc_AmpCntrls,title=""
	CheckBox check_DatAcq_BBEnable,userdata(tabnum)=  "1"
	CheckBox check_DatAcq_BBEnable,userdata(tabcontrol)=  "tab_DataAcq_Amp"
	CheckBox check_DatAcq_BBEnable,userdata(ResizeControlsInfo)= A"!!,GS!!#AP!!#>Z!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_DatAcq_BBEnable,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_DatAcq_BBEnable,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox check_DatAcq_BBEnable,value= 0
	CheckBox check_DatAcq_CNEnable,pos={223.00,233.00},size={13.00,13.00},disable=1,proc=DAP_CheckProc_AmpCntrls,title=""
	CheckBox check_DatAcq_CNEnable,userdata(tabnum)=  "1"
	CheckBox check_DatAcq_CNEnable,userdata(tabcontrol)=  "tab_DataAcq_Amp"
	CheckBox check_DatAcq_CNEnable,userdata(ResizeControlsInfo)= A"!!,GS!!#Ac!!#>Z!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_DatAcq_CNEnable,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_DatAcq_CNEnable,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox check_DatAcq_CNEnable,value= 0
	TitleBox Title_DataAcq_CN,pos={44.00,232.00},size={122.00,15.00},disable=1,title="Cap Neutralization (pF)"
	TitleBox Title_DataAcq_CN,userdata(tabnum)=  "1"
	TitleBox Title_DataAcq_CN,userdata(tabcontrol)=  "tab_DataAcq_Amp"
	TitleBox Title_DataAcq_CN,userdata(ResizeControlsInfo)= A"!!,D3!!#Ab!!#@:!!#;]z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox Title_DataAcq_CN,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	TitleBox Title_DataAcq_CN,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	TitleBox Title_DataAcq_CN,frame=0
	Slider slider_DataAcq_ActiveHeadstage,pos={145.00,129.00},size={255.00,20.00},disable=1,proc=DAP_SliderProc_MIESHeadStage
	Slider slider_DataAcq_ActiveHeadstage,userdata(tabnum)=  "0"
	Slider slider_DataAcq_ActiveHeadstage,userdata(tabcontrol)=  "ADC"
	Slider slider_DataAcq_ActiveHeadstage,userdata(ResizeControlsInfo)= A"!!,G!!!#@e!!#B9!!#<Xz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Slider slider_DataAcq_ActiveHeadstage,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	Slider slider_DataAcq_ActiveHeadstage,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	Slider slider_DataAcq_ActiveHeadstage,labelBack=(60928,60928,60928)
	Slider slider_DataAcq_ActiveHeadstage,limits={0,7,1},value= 0,side= 2,vert= 0,ticks= 0,thumbColor= (43520,43520,43520)
	SetVariable setvar_DataAcq_AutoBiasV,pos={287.00,206.00},size={101.00,18.00},bodyWidth=50,disable=1,proc=DAP_SetVarProc_AmpCntrls,title="Vm (mV)"
	SetVariable setvar_DataAcq_AutoBiasV,userdata(tabnum)=  "1"
	SetVariable setvar_DataAcq_AutoBiasV,userdata(tabcontrol)=  "tab_DataAcq_Amp"
	SetVariable setvar_DataAcq_AutoBiasV,userdata(ResizeControlsInfo)= A"!!,HUJ,hr!!!#?Y!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_DataAcq_AutoBiasV,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable setvar_DataAcq_AutoBiasV,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable setvar_DataAcq_AutoBiasV,value= _NUM:-70
	CheckBox check_DataAcq_AutoBias,pos={321.00,186.00},size={65.00,15.00},disable=1,proc=DAP_CheckProc_AmpCntrls,title="Auto Bias"
	CheckBox check_DataAcq_AutoBias,help={"Just prior to a sweep the Vm is checked and the bias current is adjusted to maintain desired Vm."}
	CheckBox check_DataAcq_AutoBias,userdata(tabnum)=  "1"
	CheckBox check_DataAcq_AutoBias,userdata(tabcontrol)=  "tab_DataAcq_Amp"
	CheckBox check_DataAcq_AutoBias,userdata(ResizeControlsInfo)= A"!!,HS!!#A:!!#?5!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_DataAcq_AutoBias,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_DataAcq_AutoBias,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox check_DataAcq_AutoBias,value= 0,side= 1
	SetVariable setvar_DataAcq_IbiasMax,pos={298.00,229.00},size={136.00,20.00},bodyWidth=50,disable=1,proc=DAP_SetVarProc_AmpCntrls,title="max I \\Bbias\\M (pA) ±"
	SetVariable setvar_DataAcq_IbiasMax,userdata(tabcontrol)=  "tab_DataAcq_Amp"
	SetVariable setvar_DataAcq_IbiasMax,userdata(tabnum)=  "1"
	SetVariable setvar_DataAcq_IbiasMax,userdata(ResizeControlsInfo)= A"!!,HV!!#A`!!#@T!!#<Xz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_DataAcq_IbiasMax,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable setvar_DataAcq_IbiasMax,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable setvar_DataAcq_IbiasMax,value= _NUM:200
	SetVariable setvar_DataAcq_AutoBiasVrange,pos={392.00,206.00},size={62.00,18.00},bodyWidth=50,disable=1,proc=DAP_SetVarProc_AmpCntrls,title="±"
	SetVariable setvar_DataAcq_AutoBiasVrange,userdata(tabcontrol)=  "tab_DataAcq_Amp"
	SetVariable setvar_DataAcq_AutoBiasVrange,userdata(tabnum)=  "1"
	SetVariable setvar_DataAcq_AutoBiasVrange,userdata(ResizeControlsInfo)= A"!!,I)J,hr!!!#>F!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_DataAcq_AutoBiasVrange,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable setvar_DataAcq_AutoBiasVrange,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable setvar_DataAcq_AutoBiasVrange,limits={0,inf,1},value= _NUM:0.5
	TitleBox Title_DataAcq_Hold_VC,pos={1.00,209.00},size={50.00,20.00},disable=1
	TitleBox Title_DataAcq_Hold_VC,userdata(tabnum)=  "0"
	TitleBox Title_DataAcq_Hold_VC,userdata(tabcontrol)=  "tab_DataAcq_Amp"
	TitleBox Title_DataAcq_Hold_VC,userdata(ResizeControlsInfo)= A"!!,<7!!#A`!!#>V!!#<Xz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox Title_DataAcq_Hold_VC,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	TitleBox Title_DataAcq_Hold_VC,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	TitleBox Title_DataAcq_Hold_VC,frame=0
	SetVariable setvar_DataAcq_Hold_VC,pos={48.00,173.00},size={93.00,18.00},bodyWidth=46,disable=1,proc=DAP_SetVarProc_AmpCntrls,title="Holding"
	SetVariable setvar_DataAcq_Hold_VC,userdata(tabnum)=  "0"
	SetVariable setvar_DataAcq_Hold_VC,userdata(tabcontrol)=  "tab_DataAcq_Amp"
	SetVariable setvar_DataAcq_Hold_VC,userdata(ResizeControlsInfo)= A"!!,DO!!#A<!!#?s!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_DataAcq_Hold_VC,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable setvar_DataAcq_Hold_VC,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable setvar_DataAcq_Hold_VC,value= _NUM:0
	TitleBox Title_DataAcq_PipOffset_VC,pos={244.00,173.00},size={101.00,15.00},disable=1,title="Pipette Offset (mV)"
	TitleBox Title_DataAcq_PipOffset_VC,userdata(tabnum)=  "0"
	TitleBox Title_DataAcq_PipOffset_VC,userdata(tabcontrol)=  "tab_DataAcq_Amp"
	TitleBox Title_DataAcq_PipOffset_VC,userdata(ResizeControlsInfo)= A"!!,H/!!#A<!!#@.!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox Title_DataAcq_PipOffset_VC,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	TitleBox Title_DataAcq_PipOffset_VC,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	TitleBox Title_DataAcq_PipOffset_VC,frame=0
	SetVariable setvar_DataAcq_PipetteOffset_VC,pos={351.00,172.00},size={50.00,18.00},bodyWidth=50,disable=1,proc=DAP_SetVarProc_AmpCntrls
	SetVariable setvar_DataAcq_PipetteOffset_VC,userdata(tabnum)=  "0"
	SetVariable setvar_DataAcq_PipetteOffset_VC,userdata(tabcontrol)=  "tab_DataAcq_Amp"
	SetVariable setvar_DataAcq_PipetteOffset_VC,userdata(ResizeControlsInfo)= A"!!,HjJ,hqf!!#>V!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_DataAcq_PipetteOffset_VC,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable setvar_DataAcq_PipetteOffset_VC,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable setvar_DataAcq_PipetteOffset_VC,value= _NUM:0
	Button button_DataAcq_AutoPipOffset_VC,pos={404.00,171.00},size={40.00,20.00},disable=1,proc=DAP_ButtonProc_AmpCntrls,title="Auto"
	Button button_DataAcq_AutoPipOffset_VC,help={"Automatically calculate the pipette offset"}
	Button button_DataAcq_AutoPipOffset_VC,userdata(tabnum)=  "0"
	Button button_DataAcq_AutoPipOffset_VC,userdata(tabcontrol)=  "tab_DataAcq_Amp"
	Button button_DataAcq_AutoPipOffset_VC,userdata(ResizeControlsInfo)= A"!!,I0!!#A:!!#>.!!#<Xz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_DataAcq_AutoPipOffset_VC,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	Button button_DataAcq_AutoPipOffset_VC,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	GroupBox group_pipette_offset,pos={240.00,168.00},size={210.00,28.00},disable=1
	GroupBox group_pipette_offset,userdata(tabnum)=  "0"
	GroupBox group_pipette_offset,userdata(tabcontrol)=  "tab_DataAcq_Amp"
	GroupBox group_pipette_offset,userdata(ResizeControlsInfo)= A"!!,H+!!#A7!!#Aa!!#=Cz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	GroupBox group_pipette_offset,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	GroupBox group_pipette_offset,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox check_DatAcq_HoldEnableVC,pos={148.00,174.00},size={50.00,15.00},disable=1,proc=DAP_CheckProc_AmpCntrls,title="Enable"
	CheckBox check_DatAcq_HoldEnableVC,userdata(tabnum)=  "0"
	CheckBox check_DatAcq_HoldEnableVC,userdata(tabcontrol)=  "tab_DataAcq_Amp"
	CheckBox check_DatAcq_HoldEnableVC,userdata(ResizeControlsInfo)= A"!!,G$!!#A=!!#>V!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_DatAcq_HoldEnableVC,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_DatAcq_HoldEnableVC,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox check_DatAcq_HoldEnableVC,value= 0
	SetVariable setvar_DataAcq_WCR,pos={117.00,219.00},size={75.00,19.00},bodyWidth=50,disable=1,proc=DAP_SetVarProc_AmpCntrls,title="M\\F'Symbol'W\\F]0"
	SetVariable setvar_DataAcq_WCR,userdata(tabnum)=  "0"
	SetVariable setvar_DataAcq_WCR,userdata(tabcontrol)=  "tab_DataAcq_Amp"
	SetVariable setvar_DataAcq_WCR,userdata(ResizeControlsInfo)= A"!!,FO!!#Aj!!#?O!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_DataAcq_WCR,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable setvar_DataAcq_WCR,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable setvar_DataAcq_WCR,value= _NUM:0
	CheckBox check_DatAcq_WholeCellEnable,pos={69.00,199.00},size={13.00,13.00},disable=1,proc=DAP_CheckProc_AmpCntrls,title=""
	CheckBox check_DatAcq_WholeCellEnable,userdata(tabnum)=  "0"
	CheckBox check_DatAcq_WholeCellEnable,userdata(tabcontrol)=  "tab_DataAcq_Amp"
	CheckBox check_DatAcq_WholeCellEnable,userdata(ResizeControlsInfo)= A"!!,ED!!#AV!!#;]!!#;]z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_DatAcq_WholeCellEnable,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_DatAcq_WholeCellEnable,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox check_DatAcq_WholeCellEnable,value= 0
	SetVariable setvar_DataAcq_WCC,pos={49.00,220.00},size={67.00,18.00},bodyWidth=50,disable=1,proc=DAP_SetVarProc_AmpCntrls,title="pF"
	SetVariable setvar_DataAcq_WCC,userdata(tabnum)=  "0"
	SetVariable setvar_DataAcq_WCC,userdata(tabcontrol)=  "tab_DataAcq_Amp"
	SetVariable setvar_DataAcq_WCC,userdata(ResizeControlsInfo)= A"!!,DS!!#Ak!!#??!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_DataAcq_WCC,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable setvar_DataAcq_WCC,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable setvar_DataAcq_WCC,limits={1,inf,1},value= _NUM:0
	Button button_DataAcq_WCAuto,pos={103.00,239.00},size={40.00,15.00},disable=1,proc=DAP_ButtonProc_AmpCntrls,title="Auto"
	Button button_DataAcq_WCAuto,userdata(tabnum)=  "0"
	Button button_DataAcq_WCAuto,userdata(tabcontrol)=  "tab_DataAcq_Amp"
	Button button_DataAcq_WCAuto,userdata(ResizeControlsInfo)= A"!!,F3!!#B)!!#>.!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_DataAcq_WCAuto,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	Button button_DataAcq_WCAuto,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	GroupBox group_DataAcq_RsCompensation,pos={206.00,200.00},size={185.00,62.00},disable=1,title="       Rs Compensation"
	GroupBox group_DataAcq_RsCompensation,userdata(tabnum)=  "0"
	GroupBox group_DataAcq_RsCompensation,userdata(tabcontrol)=  "tab_DataAcq_Amp"
	GroupBox group_DataAcq_RsCompensation,userdata(ResizeControlsInfo)= A"!!,G^!!#AW!!#AH!!#?1z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	GroupBox group_DataAcq_RsCompensation,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	GroupBox group_DataAcq_RsCompensation,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox check_DatAcq_RsCompEnable,pos={229.00,199.00},size={13.00,13.00},disable=1,proc=DAP_CheckProc_AmpCntrls,title=""
	CheckBox check_DatAcq_RsCompEnable,userdata(tabnum)=  "0"
	CheckBox check_DatAcq_RsCompEnable,userdata(tabcontrol)=  "tab_DataAcq_Amp"
	CheckBox check_DatAcq_RsCompEnable,userdata(ResizeControlsInfo)= A"!!,H#!!#AV!!#;]!!#;]z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_DatAcq_RsCompEnable,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_DatAcq_RsCompEnable,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox check_DatAcq_RsCompEnable,value= 0
	SetVariable setvar_DataAcq_RsCorr,pos={212.00,218.00},size={121.00,18.00},bodyWidth=40,disable=1,proc=DAP_SetVarProc_AmpCntrls,title="Correction (%)"
	SetVariable setvar_DataAcq_RsCorr,userdata(tabnum)=  "0"
	SetVariable setvar_DataAcq_RsCorr,userdata(tabcontrol)=  "tab_DataAcq_Amp"
	SetVariable setvar_DataAcq_RsCorr,userdata(ResizeControlsInfo)= A"!!,Gd!!#Ai!!#@V!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_DataAcq_RsCorr,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable setvar_DataAcq_RsCorr,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable setvar_DataAcq_RsCorr,limits={0,100,1},value= _NUM:0
	SetVariable setvar_DataAcq_RsPred,pos={214.00,238.00},size={119.00,18.00},bodyWidth=40,disable=1,proc=DAP_SetVarProc_AmpCntrls,title="Prediction (%)"
	SetVariable setvar_DataAcq_RsPred,userdata(tabnum)=  "0"
	SetVariable setvar_DataAcq_RsPred,userdata(tabcontrol)=  "tab_DataAcq_Amp"
	SetVariable setvar_DataAcq_RsPred,userdata(ResizeControlsInfo)= A"!!,Gf!!#B(!!#@R!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_DataAcq_RsPred,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable setvar_DataAcq_RsPred,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable setvar_DataAcq_RsPred,limits={0,100,1},value= _NUM:0
	Button button_DataAcq_FastComp_VC,pos={400.00,214.00},size={55.00,20.00},disable=1,proc=DAP_ButtonProc_AmpCntrls,title="Cp Fast"
	Button button_DataAcq_FastComp_VC,help={"Activates MCC auto fast capacitance compensation"}
	Button button_DataAcq_FastComp_VC,userdata(tabnum)=  "0"
	Button button_DataAcq_FastComp_VC,userdata(tabcontrol)=  "tab_DataAcq_Amp"
	Button button_DataAcq_FastComp_VC,userdata(ResizeControlsInfo)= A"!!,I.!!#Ae!!#>j!!#<Xz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_DataAcq_FastComp_VC,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	Button button_DataAcq_FastComp_VC,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	Button button_Hardware_AutoGainAndUnit,pos={399.00,409.00},size={40.00,47.00},proc=DAP_ButtonProc_AutoFillGain,title="Auto\rFill"
	Button button_Hardware_AutoGainAndUnit,help={"A amplifier channel needs to be selected from the popup menu prior to auto filling gain and units."}
	Button button_Hardware_AutoGainAndUnit,userdata(tabnum)=  "6"
	Button button_Hardware_AutoGainAndUnit,userdata(tabcontrol)=  "ADC"
	Button button_Hardware_AutoGainAndUnit,userdata(ResizeControlsInfo)= A"!!,I-J,hs\\J,hnY!!#>Jz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_Hardware_AutoGainAndUnit,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	Button button_Hardware_AutoGainAndUnit,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox Check_Settings_AlarmPauseAcq,pos={34.00,474.00},size={181.00,15.00},disable=1,title="\\JCPause acquisition in alarm state"
	CheckBox Check_Settings_AlarmPauseAcq,help={"Pauses acquisition until user continues or cancels acquisition"}
	CheckBox Check_Settings_AlarmPauseAcq,userdata(tabnum)=  "5"
	CheckBox Check_Settings_AlarmPauseAcq,userdata(tabcontrol)=  "ADC"
	CheckBox Check_Settings_AlarmPauseAcq,userdata(ResizeControlsInfo)= A"!!,Cl!!#CR!!#AD!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_Settings_AlarmPauseAcq,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox Check_Settings_AlarmPauseAcq,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox Check_Settings_AlarmPauseAcq,fColor=(65280,43520,0),value= 0
	CheckBox Check_Settings_AlarmAutoRepeat,pos={34.00,495.00},size={274.00,15.00},disable=1,title="\\JCAuto repeat last sweep until alarm state is cleared"
	CheckBox Check_Settings_AlarmAutoRepeat,help={"Turns on TTL pulse at onset of sweep"}
	CheckBox Check_Settings_AlarmAutoRepeat,userdata(tabnum)=  "5"
	CheckBox Check_Settings_AlarmAutoRepeat,userdata(tabcontrol)=  "ADC"
	CheckBox Check_Settings_AlarmAutoRepeat,userdata(ResizeControlsInfo)= A"!!,Cl!!#C\\J,hrn!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_Settings_AlarmAutoRepeat,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox Check_Settings_AlarmAutoRepeat,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox Check_Settings_AlarmAutoRepeat,fColor=(65280,43520,0),value= 0
	GroupBox group_Settings_Amplifier,pos={21.00,574.00},size={445.00,80.00},disable=1,title="Amplifier"
	GroupBox group_Settings_Amplifier,userdata(tabnum)=  "5"
	GroupBox group_Settings_Amplifier,userdata(tabcontrol)=  "ADC"
	GroupBox group_Settings_Amplifier,userdata(ResizeControlsInfo)= A"!!,Ba!!#CtJ,hsnJ,hp/z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	GroupBox group_Settings_Amplifier,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	GroupBox group_Settings_Amplifier,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox check_Settings_AmpMCCdefault,pos={34.00,598.00},size={190.00,15.00},disable=1,proc=DAP_CheckProc_ShowScopeWin,title="Default to MCC parameter values"
	CheckBox check_Settings_AmpMCCdefault,help={"Enable the scope window to view ongoing acquistion"}
	CheckBox check_Settings_AmpMCCdefault,userdata(tabnum)=  "5"
	CheckBox check_Settings_AmpMCCdefault,userdata(tabcontrol)=  "ADC"
	CheckBox check_Settings_AmpMCCdefault,userdata(ResizeControlsInfo)= A"!!,Cl!!#D%J,hr#!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_Settings_AmpMCCdefault,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_Settings_AmpMCCdefault,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox check_Settings_AmpMCCdefault,fColor=(65280,43520,0),value= 0
	CheckBox check_Settings_AmpMIESdefault,pos={34.00,619.00},size={274.00,15.00},disable=1,proc=DAP_CheckProc_ShowScopeWin,title="Default amplifier parameter values stored in MIES"
	CheckBox check_Settings_AmpMIESdefault,help={"Enable the scope window to view ongoing acquistion"}
	CheckBox check_Settings_AmpMIESdefault,userdata(tabnum)=  "5"
	CheckBox check_Settings_AmpMIESdefault,userdata(tabcontrol)=  "ADC"
	CheckBox check_Settings_AmpMIESdefault,userdata(ResizeControlsInfo)= A"!!,Cl!!#D*^]6`Y!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_Settings_AmpMIESdefault,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_Settings_AmpMIESdefault,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox check_Settings_AmpMIESdefault,fColor=(65280,43520,0),value= 0
	CheckBox check_DataAcq_Amp_Chain,pos={337.00,230.00},size={46.00,15.00},disable=1,proc=DAP_CheckProc_AmpCntrls,title="Chain"
	CheckBox check_DataAcq_Amp_Chain,userdata(tabnum)=  "0"
	CheckBox check_DataAcq_Amp_Chain,userdata(tabcontrol)=  "tab_DataAcq_Amp"
	CheckBox check_DataAcq_Amp_Chain,userdata(ResizeControlsInfo)= A"!!,HcJ,hrK!!#>F!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_DataAcq_Amp_Chain,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_DataAcq_Amp_Chain,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox check_DataAcq_Amp_Chain,value= 0
	GroupBox group_Settings_MDSupport,pos={21.00,26.00},size={445.00,40.00},disable=1,title="Multiple Device Support"
	GroupBox group_Settings_MDSupport,help={"Multiple device support includes yoking and multiple independent devices"}
	GroupBox group_Settings_MDSupport,userdata(tabnum)=  "5"
	GroupBox group_Settings_MDSupport,userdata(tabcontrol)=  "ADC"
	GroupBox group_Settings_MDSupport,userdata(ResizeControlsInfo)= A"!!,Ba!!#=3!!#CCJ,hnYz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	GroupBox group_Settings_MDSupport,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	GroupBox group_Settings_MDSupport,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox check_Settings_MD,pos={34.00,44.00},size={50.00,15.00},disable=1,proc=DAP_CheckProc_MDEnable,title="Enable"
	CheckBox check_Settings_MD,userdata(tabnum)=  "5",userdata(tabcontrol)=  "ADC"
	CheckBox check_Settings_MD,userdata(ResizeControlsInfo)= A"!!,Cl!!#>>!!#>V!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_Settings_MD,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_Settings_MD,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox check_Settings_MD,value= 0
	CheckBox Check_Settings_InsertTP,pos={172.00,85.00},size={61.00,15.00},disable=1,proc=DAP_CheckProc_InsertTP,title="Insert TP"
	CheckBox Check_Settings_InsertTP,help={"Inserts a test pulse at the front of each sweep in a set."}
	CheckBox Check_Settings_InsertTP,userdata(tabnum)=  "5"
	CheckBox Check_Settings_InsertTP,userdata(tabcontrol)=  "ADC"
	CheckBox Check_Settings_InsertTP,userdata(ResizeControlsInfo)= A"!!,G<!!#?c!!#?-!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_Settings_InsertTP,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox Check_Settings_InsertTP,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox Check_Settings_InsertTP,value= 1
	CheckBox Check_DataAcq_Get_Set_ITI,pos={150.00,694.00},size={46.00,30.00},disable=1,proc=DAP_CheckProc_GetSet_ITI,title="Get\rset ITI"
	CheckBox Check_DataAcq_Get_Set_ITI,help={"When checked the stimulus set ITIs are used. The ITI is calculated as the maximum of all active stimulus set ITIs"}
	CheckBox Check_DataAcq_Get_Set_ITI,userdata(tabnum)=  "0"
	CheckBox Check_DataAcq_Get_Set_ITI,userdata(tabcontrol)=  "ADC"
	CheckBox Check_DataAcq_Get_Set_ITI,userdata(ResizeControlsInfo)= A"!!,H.!!#AQ!!#AU!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_DataAcq_Get_Set_ITI,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox Check_DataAcq_Get_Set_ITI,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox Check_DataAcq_Get_Set_ITI,value= 0
	SetVariable setvar_Settings_TPBuffer,pos={325.00,109.00},size={125.00,18.00},bodyWidth=50,disable=1,title="TP Buffer size"
	SetVariable setvar_Settings_TPBuffer,userdata(tabnum)=  "5"
	SetVariable setvar_Settings_TPBuffer,userdata(tabcontrol)=  "ADC"
	SetVariable setvar_Settings_TPBuffer,userdata(ResizeControlsInfo)= A"!!,H]J,hpi!!#@^!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_Settings_TPBuffer,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable setvar_Settings_TPBuffer,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable setvar_Settings_TPBuffer,limits={1,inf,1},value= _NUM:1
	CheckBox check_Settings_SaveAmpSettings,pos={306.00,597.00},size={113.00,15.00},disable=1,title="Save Amp Settings"
	CheckBox check_Settings_SaveAmpSettings,help={"Adds amplifier settings to lab note book for Multiclamp 700Bs ONLY!"}
	CheckBox check_Settings_SaveAmpSettings,userdata(tabnum)=  "5"
	CheckBox check_Settings_SaveAmpSettings,userdata(tabcontrol)=  "ADC"
	CheckBox check_Settings_SaveAmpSettings,userdata(ResizeControlsInfo)= A"!!,HT!!#D%5QF.1!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_Settings_SaveAmpSettings,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_Settings_SaveAmpSettings,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox check_Settings_SaveAmpSettings,value= 1
	SetVariable setvar_Settings_TP_RTolerance,pos={304.00,84.00},size={146.00,19.00},bodyWidth=50,disable=1,title="Min delta R (M\\F'Symbol'W\\F]0)"
	SetVariable setvar_Settings_TP_RTolerance,help={"Sets the minimum delta required forTP resistance values to be appended as a wave note to the data sweep. TP resistance values are always documented in the Lab Note Book."}
	SetVariable setvar_Settings_TP_RTolerance,userdata(tabnum)=  "5"
	SetVariable setvar_Settings_TP_RTolerance,userdata(tabcontrol)=  "ADC"
	SetVariable setvar_Settings_TP_RTolerance,userdata(ResizeControlsInfo)= A"!!,HS!!#?a!!#A!!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_Settings_TP_RTolerance,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable setvar_Settings_TP_RTolerance,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable setvar_Settings_TP_RTolerance,limits={1,inf,1},value= _NUM:5
	CheckBox check_Settings_TP_SaveTPRecord,pos={357.00,133.00},size={93.00,15.00},disable=1,title="Save TP record"
	CheckBox check_Settings_TP_SaveTPRecord,help={"When unchecked, the TP analysis record (from the previous TP run), is overwritten on the initiation of of the TP"}
	CheckBox check_Settings_TP_SaveTPRecord,userdata(tabnum)=  "5"
	CheckBox check_Settings_TP_SaveTPRecord,userdata(tabcontrol)=  "ADC"
	CheckBox check_Settings_TP_SaveTPRecord,userdata(ResizeControlsInfo)= A"!!,HmJ,hq?!!#?s!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_Settings_TP_SaveTPRecord,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_Settings_TP_SaveTPRecord,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox check_Settings_TP_SaveTPRecord,value= 0
	Button button_DataAcq_AutoBridgeBal_IC,pos={240.00,209.00},size={40.00,15.00},disable=1,proc=DAP_ButtonProc_AmpCntrls,title="Auto"
	Button button_DataAcq_AutoBridgeBal_IC,help={"Automatically calculate the bridge balance"}
	Button button_DataAcq_AutoBridgeBal_IC,userdata(tabnum)=  "1"
	Button button_DataAcq_AutoBridgeBal_IC,userdata(tabcontrol)=  "tab_DataAcq_Amp"
	Button button_DataAcq_AutoBridgeBal_IC,userdata(ResizeControlsInfo)= A"!!,H6!!#AQ!!#>.!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_DataAcq_AutoBridgeBal_IC,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	Button button_DataAcq_AutoBridgeBal_IC,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox Check_DataAcq_SendToAllAmp,pos={345.00,147.00},size={104.00,15.00},disable=1,title="Send to all Amps"
	CheckBox Check_DataAcq_SendToAllAmp,userdata(tabnum)=  "0"
	CheckBox Check_DataAcq_SendToAllAmp,userdata(tabcontrol)=  "ADC"
	CheckBox Check_DataAcq_SendToAllAmp,userdata(ResizeControlsInfo)= A"!!,HgJ,hqM!!#@4!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_DataAcq_SendToAllAmp,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox Check_DataAcq_SendToAllAmp,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox Check_DataAcq_SendToAllAmp,value= 0
	Button button_DataAcq_Seal,pos={154.00,299.00},size={84.00,27.00},disable=3,proc=ButtonProc_Seal,title="Seal"
	Button button_DataAcq_Seal,help={"Sets the I-clamp holding current based on the V-clamp holding potential"}
	Button button_DataAcq_Seal,userdata(tabnum)=  "0"
	Button button_DataAcq_Seal,userdata(tabcontrol)=  "tab_DataAcq_Pressure"
	Button button_DataAcq_Seal,userdata(ResizeControlsInfo)= A"!!,G*!!#BOJ,hp7!!#=;z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_DataAcq_Seal,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	Button button_DataAcq_Seal,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	Button button_DataAcq_BreakIn,pos={264.00,299.00},size={84.00,27.00},disable=3,proc=ButtonProc_BreakIn,title="Break In"
	Button button_DataAcq_BreakIn,help={"Sets the I-clamp holding current based on the V-clamp holding potential"}
	Button button_DataAcq_BreakIn,userdata(tabnum)=  "0"
	Button button_DataAcq_BreakIn,userdata(tabcontrol)=  "tab_DataAcq_Pressure"
	Button button_DataAcq_BreakIn,userdata(ResizeControlsInfo)= A"!!,H?!!#BOJ,hp7!!#=;z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_DataAcq_BreakIn,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	Button button_DataAcq_BreakIn,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	Button button_DataAcq_Clear,pos={374.00,299.00},size={84.00,27.00},disable=3,proc=ButtonProc_Clear,title="Clear"
	Button button_DataAcq_Clear,help={"Attempts to clear the pipette tip to improve access resistance"}
	Button button_DataAcq_Clear,userdata(tabnum)=  "0"
	Button button_DataAcq_Clear,userdata(tabcontrol)=  "tab_DataAcq_Pressure"
	Button button_DataAcq_Clear,userdata(ResizeControlsInfo)= A"!!,I!!!#BOJ,hp7!!#=;z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_DataAcq_Clear,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	Button button_DataAcq_Clear,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox check_DatAcq_ClearEnable,pos={376.00,329.00},size={50.00,15.00},disable=3,proc=CheckProc_ClearEnable,title="Enable"
	CheckBox check_DatAcq_ClearEnable,userdata(tabnum)=  "0"
	CheckBox check_DatAcq_ClearEnable,userdata(tabcontrol)=  "tab_DataAcq_Pressure"
	CheckBox check_DatAcq_ClearEnable,userdata(ResizeControlsInfo)= A"!!,I\"!!#B^J,ho,!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_DatAcq_ClearEnable,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_DatAcq_ClearEnable,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox check_DatAcq_ClearEnable,value= 0
	CheckBox check_DatAcq_SealALl,pos={156.00,329.00},size={29.00,15.00},disable=3,title="All"
	CheckBox check_DatAcq_SealALl,help={"Seals all headstates with active test pulse"}
	CheckBox check_DatAcq_SealALl,userdata(tabnum)=  "0"
	CheckBox check_DatAcq_SealALl,userdata(tabcontrol)=  "tab_DataAcq_Pressure"
	CheckBox check_DatAcq_SealALl,userdata(ResizeControlsInfo)= A"!!,G,!!#B^J,hn!!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_DatAcq_SealALl,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_DatAcq_SealALl,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox check_DatAcq_SealALl,value= 0
	CheckBox check_DatAcq_BreakInAll,pos={266.00,329.00},size={29.00,15.00},disable=3,title="All"
	CheckBox check_DatAcq_BreakInAll,help={"Break in to all headstates with active test pulse"}
	CheckBox check_DatAcq_BreakInAll,userdata(tabnum)=  "0"
	CheckBox check_DatAcq_BreakInAll,userdata(tabcontrol)=  "tab_DataAcq_Pressure"
	CheckBox check_DatAcq_BreakInAll,userdata(ResizeControlsInfo)= A"!!,H@!!#B^J,hn!!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_DatAcq_BreakInAll,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_DatAcq_BreakInAll,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox check_DatAcq_BreakInAll,value= 0
	Button button_DataAcq_Approach,pos={44.00,299.00},size={84.00,27.00},disable=3,proc=ButtonProc_Approach,title="Approach"
	Button button_DataAcq_Approach,help={"Applies positive pressure to the pipette"}
	Button button_DataAcq_Approach,userdata(tabnum)=  "0"
	Button button_DataAcq_Approach,userdata(tabcontrol)=  "tab_DataAcq_Pressure"
	Button button_DataAcq_Approach,userdata(ResizeControlsInfo)= A"!!,D?!!#BOJ,hp7!!#=;z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_DataAcq_Approach,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	Button button_DataAcq_Approach,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox check_DatAcq_ApproachAll,pos={47.00,329.00},size={29.00,15.00},disable=3,title="All"
	CheckBox check_DatAcq_ApproachAll,help={"Apply postive pressure to all headstages"}
	CheckBox check_DatAcq_ApproachAll,userdata(tabnum)=  "0"
	CheckBox check_DatAcq_ApproachAll,userdata(tabcontrol)=  "tab_DataAcq_Pressure"
	CheckBox check_DatAcq_ApproachAll,userdata(ResizeControlsInfo)= A"!!,DK!!#B^J,hn!!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_DatAcq_ApproachAll,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_DatAcq_ApproachAll,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox check_DatAcq_ApproachAll,value= 0
	PopupMenu popup_Settings_Pressure_ITCdev,pos={51.00,495.00},size={213.00,19.00},bodyWidth=150,proc=DAP_PopMenuProc_CAA,title="ITC devices"
	PopupMenu popup_Settings_Pressure_ITCdev,help={"List of available ITC devices for pressure control"}
	PopupMenu popup_Settings_Pressure_ITCdev,userdata(tabnum)=  "6"
	PopupMenu popup_Settings_Pressure_ITCdev,userdata(tabcontrol)=  "ADC"
	PopupMenu popup_Settings_Pressure_ITCdev,userdata(ResizeControlsInfo)= A"!!,D[!!#C\\J,hr:!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu popup_Settings_Pressure_ITCdev,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	PopupMenu popup_Settings_Pressure_ITCdev,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	PopupMenu popup_Settings_Pressure_ITCdev,mode=1,popvalue="- none -",value= #"\"- none -;ITC1600_Dev_1;ITC1600_Dev_2;ITC1600_Dev_3;\""
	TitleBox Title_settings_Hardware_Pressur,pos={45.00,475.00},size={44.00,15.00},title="Pressure"
	TitleBox Title_settings_Hardware_Pressur,userdata(tabnum)=  "6"
	TitleBox Title_settings_Hardware_Pressur,userdata(tabcontrol)=  "ADC"
	TitleBox Title_settings_Hardware_Pressur,userdata(ResizeControlsInfo)= A"!!,DC!!#CRJ,hni!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox Title_settings_Hardware_Pressur,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	TitleBox Title_settings_Hardware_Pressur,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	TitleBox Title_settings_Hardware_Pressur,frame=0
	PopupMenu Popup_Settings_Pressure_DA,pos={51.00,524.00},size={47.00,19.00},proc=DAP_PopMenuProc_CAA,title="DA"
	PopupMenu Popup_Settings_Pressure_DA,userdata(tabnum)=  "6"
	PopupMenu Popup_Settings_Pressure_DA,userdata(tabcontrol)=  "ADC"
	PopupMenu Popup_Settings_Pressure_DA,userdata(ResizeControlsInfo)= A"!!,D[!!#Ch!!#>J!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Popup_Settings_Pressure_DA,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	PopupMenu Popup_Settings_Pressure_DA,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	PopupMenu Popup_Settings_Pressure_DA,mode=1,popvalue="0",value= #"\"0;1;2;3;4;5;6;7\""
	PopupMenu Popup_Settings_Pressure_AD,pos={51.00,549.00},size={47.00,19.00},proc=DAP_PopMenuProc_CAA,title="AD"
	PopupMenu Popup_Settings_Pressure_AD,userdata(tabnum)=  "6"
	PopupMenu Popup_Settings_Pressure_AD,userdata(tabcontrol)=  "ADC"
	PopupMenu Popup_Settings_Pressure_AD,userdata(ResizeControlsInfo)= A"!!,D[!!#Cn5QF,5!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Popup_Settings_Pressure_AD,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	PopupMenu Popup_Settings_Pressure_AD,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	PopupMenu Popup_Settings_Pressure_AD,mode=1,popvalue="0",value= #"\"0;1;2;3;4;5;6;7;8;9;10;11;12;13;14;15\""
	SetVariable setvar_Settings_Pressure_DAgain,pos={112.00,526.00},size={50.00,18.00},proc=DAP_SetVarProc_CAA
	SetVariable setvar_Settings_Pressure_DAgain,userdata(tabnum)=  "6"
	SetVariable setvar_Settings_Pressure_DAgain,userdata(tabcontrol)=  "ADC"
	SetVariable setvar_Settings_Pressure_DAgain,userdata(ResizeControlsInfo)= A"!!,FE!!#ChJ,ho,!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_Settings_Pressure_DAgain,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable setvar_Settings_Pressure_DAgain,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable setvar_Settings_Pressure_DAgain,value= _NUM:2
	SetVariable setvar_Settings_Pressure_ADgain,pos={112.00,551.00},size={50.00,18.00},proc=DAP_SetVarProc_CAA
	SetVariable setvar_Settings_Pressure_ADgain,userdata(tabnum)=  "6"
	SetVariable setvar_Settings_Pressure_ADgain,userdata(tabcontrol)=  "ADC"
	SetVariable setvar_Settings_Pressure_ADgain,userdata(ResizeControlsInfo)= A"!!,FE!!#Cn^]6\\l!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_Settings_Pressure_ADgain,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable setvar_Settings_Pressure_ADgain,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable setvar_Settings_Pressure_ADgain,value= _NUM:0.5
	SetVariable SetVar_Hardware_Pressur_DA_Unit,pos={170.00,526.00},size={30.00,18.00},proc=DAP_SetVarProc_CAA
	SetVariable SetVar_Hardware_Pressur_DA_Unit,userdata(tabnum)=  "6"
	SetVariable SetVar_Hardware_Pressur_DA_Unit,userdata(tabcontrol)=  "ADC"
	SetVariable SetVar_Hardware_Pressur_DA_Unit,userdata(ResizeControlsInfo)= A"!!,G:!!#ChJ,hn)!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_Hardware_Pressur_DA_Unit,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable SetVar_Hardware_Pressur_DA_Unit,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable SetVar_Hardware_Pressur_DA_Unit,value= _STR:"psi"
	SetVariable SetVar_Hardware_Pressur_AD_Unit,pos={191.00,551.00},size={30.00,18.00},proc=DAP_SetVarProc_CAA
	SetVariable SetVar_Hardware_Pressur_AD_Unit,userdata(tabnum)=  "6"
	SetVariable SetVar_Hardware_Pressur_AD_Unit,userdata(tabcontrol)=  "ADC"
	SetVariable SetVar_Hardware_Pressur_AD_Unit,userdata(ResizeControlsInfo)= A"!!,GO!!#Cn^]6[i!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_Hardware_Pressur_AD_Unit,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable SetVar_Hardware_Pressur_AD_Unit,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable SetVar_Hardware_Pressur_AD_Unit,value= _STR:"psi"
	TitleBox Title_Hardware_Pressure_DA_Div,pos={204.00,528.00},size={15.00,15.00},title="/ V"
	TitleBox Title_Hardware_Pressure_DA_Div,userdata(tabnum)=  "6"
	TitleBox Title_Hardware_Pressure_DA_Div,userdata(tabcontrol)=  "ADC"
	TitleBox Title_Hardware_Pressure_DA_Div,userdata(ResizeControlsInfo)= A"!!,G\\!!#Ci!!#<(!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox Title_Hardware_Pressure_DA_Div,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	TitleBox Title_Hardware_Pressure_DA_Div,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	TitleBox Title_Hardware_Pressure_DA_Div,frame=0
	TitleBox Title_Hardware_Pressure_AD_Div,pos={172.00,553.00},size={15.00,15.00},title="V /"
	TitleBox Title_Hardware_Pressure_AD_Div,userdata(tabnum)=  "6"
	TitleBox Title_Hardware_Pressure_AD_Div,userdata(tabcontrol)=  "ADC"
	TitleBox Title_Hardware_Pressure_AD_Div,userdata(ResizeControlsInfo)= A"!!,G<!!#Co5QF)h!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox Title_Hardware_Pressure_AD_Div,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	TitleBox Title_Hardware_Pressure_AD_Div,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	TitleBox Title_Hardware_Pressure_AD_Div,frame=0
	PopupMenu Popup_Settings_Pressure_TTL,pos={233.00,524.00},size={51.00,19.00},proc=DAP_PopMenuProc_CAA,title="TTL"
	PopupMenu Popup_Settings_Pressure_TTL,help={"Select TTL channel for solenoid command"}
	PopupMenu Popup_Settings_Pressure_TTL,userdata(tabnum)=  "6"
	PopupMenu Popup_Settings_Pressure_TTL,userdata(tabcontrol)=  "ADC"
	PopupMenu Popup_Settings_Pressure_TTL,userdata(ResizeControlsInfo)= A"!!,H$!!#Ch!!#>Z!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Popup_Settings_Pressure_TTL,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	PopupMenu Popup_Settings_Pressure_TTL,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	PopupMenu Popup_Settings_Pressure_TTL,mode=1,popvalue="0",value= #"\"0;1;2;3;4;5;6;7\""
	GroupBox group_Settings_Pressure,pos={23.00,658.00},size={445.00,130.00},disable=1,title="Pressure"
	GroupBox group_Settings_Pressure,userdata(tabnum)=  "5"
	GroupBox group_Settings_Pressure,userdata(tabcontrol)=  "ADC"
	GroupBox group_Settings_Pressure,userdata(ResizeControlsInfo)= A"!!,Bq!!#D4J,hsnJ,hpWz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	GroupBox group_Settings_Pressure,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	GroupBox group_Settings_Pressure,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable setvar_Settings_InAirP,pos={48.00,678.00},size={116.00,18.00},bodyWidth=50,disable=1,proc=DAP_SetVarProc_CAA,title="In air P (psi)"
	SetVariable setvar_Settings_InAirP,help={"Set the (positive) pressure applied to the pipette when the pipette is out of the bath."}
	SetVariable setvar_Settings_InAirP,userdata(tabnum)=  "5"
	SetVariable setvar_Settings_InAirP,userdata(tabcontrol)=  "ADC"
	SetVariable setvar_Settings_InAirP,userdata(ResizeControlsInfo)= A"!!,DO!!#D9J,hq\"!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_Settings_InAirP,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable setvar_Settings_InAirP,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable setvar_Settings_InAirP,limits={-10,10,0.1},value= _NUM:3.8
	SetVariable setvar_Settings_InBathP,pos={172.00,678.00},size={127.00,18.00},bodyWidth=50,disable=1,proc=DAP_SetVarProc_CAA,title="In bath P (psi)"
	SetVariable setvar_Settings_InBathP,help={"Set the (positive) pressure applied to the pipette when the pipette is in the bath."}
	SetVariable setvar_Settings_InBathP,userdata(tabnum)=  "5"
	SetVariable setvar_Settings_InBathP,userdata(tabcontrol)=  "ADC"
	SetVariable setvar_Settings_InBathP,userdata(ResizeControlsInfo)= A"!!,G<!!#D9J,hq8!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_Settings_InBathP,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable setvar_Settings_InBathP,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable setvar_Settings_InBathP,limits={-10,10,0.1},value= _NUM:0.55
	SetVariable setvar_Settings_InSliceP,pos={326.00,678.00},size={126.00,18.00},bodyWidth=50,disable=1,proc=DAP_SetVarProc_CAA,title="In slice P (psi)"
	SetVariable setvar_Settings_InSliceP,help={"Set the (positive) pressure applied to the pipette when the pipette is in the tissue specimen."}
	SetVariable setvar_Settings_InSliceP,userdata(tabnum)=  "5"
	SetVariable setvar_Settings_InSliceP,userdata(tabcontrol)=  "ADC"
	SetVariable setvar_Settings_InSliceP,userdata(ResizeControlsInfo)= A"!!,H^!!#D9J,hq6!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_Settings_InSliceP,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable setvar_Settings_InSliceP,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable setvar_Settings_InSliceP,limits={-10,10,0.1},value= _NUM:0.2
	SetVariable setvar_Settings_NearCellP,pos={28.00,705.00},size={136.00,18.00},bodyWidth=50,disable=1,proc=DAP_SetVarProc_CAA,title="Near cell P (psi)"
	SetVariable setvar_Settings_NearCellP,help={"Set the (positive) pressure applied to the pipette when the pipette is close to the target neuron."}
	SetVariable setvar_Settings_NearCellP,userdata(tabnum)=  "5"
	SetVariable setvar_Settings_NearCellP,userdata(tabcontrol)=  "ADC"
	SetVariable setvar_Settings_NearCellP,userdata(ResizeControlsInfo)= A"!!,CD!!#D@5QF.W!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_Settings_NearCellP,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable setvar_Settings_NearCellP,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable setvar_Settings_NearCellP,limits={-1,1,0.1},value= _NUM:0.6
	SetVariable setvar_Settings_SealStartP,pos={168.00,705.00},size={131.00,18.00},bodyWidth=50,disable=1,proc=DAP_SetVarProc_CAA,title="Seal Init P (psi)"
	SetVariable setvar_Settings_SealStartP,help={"Set the starting negative pressure used to form a seal."}
	SetVariable setvar_Settings_SealStartP,userdata(tabnum)=  "5"
	SetVariable setvar_Settings_SealStartP,userdata(tabcontrol)=  "ADC"
	SetVariable setvar_Settings_SealStartP,userdata(ResizeControlsInfo)= A"!!,G8!!#D@5QF.R!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_Settings_SealStartP,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable setvar_Settings_SealStartP,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable setvar_Settings_SealStartP,limits={-10,0,0.1},value= _NUM:-0.6
	SetVariable setvar_Settings_SealMaxP,pos={316.00,705.00},size={136.00,18.00},bodyWidth=50,disable=1,proc=DAP_SetVarProc_CAA,title="Seal max P (psi)"
	SetVariable setvar_Settings_SealMaxP,help={"Set the maximum negative pressure used to form a seal."}
	SetVariable setvar_Settings_SealMaxP,userdata(tabnum)=  "5"
	SetVariable setvar_Settings_SealMaxP,userdata(tabcontrol)=  "ADC"
	SetVariable setvar_Settings_SealMaxP,userdata(ResizeControlsInfo)= A"!!,HY!!#D@5QF.W!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_Settings_SealMaxP,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable setvar_Settings_SealMaxP,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable setvar_Settings_SealMaxP,limits={-10,0,0.1},value= _NUM:-1.4
	SetVariable setvar_Settings_SurfaceHeight,pos={28.00,732.00},size={172.00,18.00},bodyWidth=50,disable=1,proc=DAP_SetVarProc_CAA,title="Sol surface height\\Z11 (\\F'Symbol'm\\F]0\\F'MS Sans Serif'm)"
	SetVariable setvar_Settings_SurfaceHeight,help={"Set the maximum negative pressure used to form a seal."}
	SetVariable setvar_Settings_SurfaceHeight,userdata(tabnum)=  "5"
	SetVariable setvar_Settings_SurfaceHeight,userdata(tabcontrol)=  "ADC"
	SetVariable setvar_Settings_SurfaceHeight,userdata(ResizeControlsInfo)= A"!!,CD!!#DG!!#A;!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_Settings_SurfaceHeight,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable setvar_Settings_SurfaceHeight,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable setvar_Settings_SurfaceHeight,limits={0,inf,100},value= _NUM:3500
	SetVariable setvar_Settings_SliceSurfHeight,pos={272.00,732.00},size={180.00,18.00},bodyWidth=50,disable=1,proc=DAP_SetVarProc_CAA,title="Slice surface height\\Z11 (\\F'Symbol'm\\F]0\\F'MS Sans Serif'm)"
	SetVariable setvar_Settings_SliceSurfHeight,help={"Set the maximum negative pressure used to form a seal."}
	SetVariable setvar_Settings_SliceSurfHeight,userdata(tabnum)=  "5"
	SetVariable setvar_Settings_SliceSurfHeight,userdata(tabcontrol)=  "ADC"
	SetVariable setvar_Settings_SliceSurfHeight,userdata(ResizeControlsInfo)= A"!!,HC!!#DG!!#AC!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_Settings_SliceSurfHeight,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable setvar_Settings_SliceSurfHeight,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable setvar_Settings_SliceSurfHeight,limits={0,inf,100},value= _NUM:350
	Button button_Settings_UpdateDACList,pos={276.00,495.00},size={150.00,20.00},proc=ButtonProc_Hrdwr_P_UpdtDAClist,title="Query connected DAC(s)"
	Button button_Settings_UpdateDACList,help={"Updates the popup menu contents to show the available ITC devices"}
	Button button_Settings_UpdateDACList,userdata(tabnum)=  "6"
	Button button_Settings_UpdateDACList,userdata(tabcontrol)=  "ADC"
	Button button_Settings_UpdateDACList,userdata(ResizeControlsInfo)= A"!!,HE!!#C\\J,hqP!!#<Xz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_Settings_UpdateDACList,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	Button button_Settings_UpdateDACList,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	Button button_Hardware_P_Enable,pos={299.00,521.00},size={60.00,46.00},proc=P_ButtonProc_Enable,title="Enable"
	Button button_Hardware_P_Enable,help={"Enable ITC devices used for pressure regulation."}
	Button button_Hardware_P_Enable,userdata(tabnum)=  "6"
	Button button_Hardware_P_Enable,userdata(tabcontrol)=  "ADC"
	Button button_Hardware_P_Enable,userdata(ResizeControlsInfo)= A"!!,HPJ,ht=5QF,i!!#>Fz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_Hardware_P_Enable,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	Button button_Hardware_P_Enable,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	Button button_Hardware_P_Enable,fSize=14
	Button button_Hardware_P_Disable,pos={366.00,521.00},size={60.00,46.00},disable=2,proc=P_ButtonProc_Disable,title="Disable"
	Button button_Hardware_P_Disable,help={"Enable ITC devices used for pressure regulation."}
	Button button_Hardware_P_Disable,userdata(tabnum)=  "6"
	Button button_Hardware_P_Disable,userdata(tabcontrol)=  "ADC"
	Button button_Hardware_P_Disable,userdata(ResizeControlsInfo)= A"!!,Hr!!#Cg5QF,i!!#>Fz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_Hardware_P_Disable,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	Button button_Hardware_P_Disable,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	Button button_Hardware_P_Disable,fSize=14
	ValDisplay valdisp_DataAcq_P_0,pos={61.00,353.00},size={96.00,21.00},bodyWidth=35,disable=1,title="\\Z10Pressure (psi)"
	ValDisplay valdisp_DataAcq_P_0,userdata(tabcontrol)=  "tab_DataAcq_Pressure"
	ValDisplay valdisp_DataAcq_P_0,userdata(ResizeControlsInfo)= A"!!,E.!!#BjJ,hpO!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	ValDisplay valdisp_DataAcq_P_0,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	ValDisplay valdisp_DataAcq_P_0,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	ValDisplay valdisp_DataAcq_P_0,fSize=14,fStyle=0,valueColor=(65535,65535,65535)
	ValDisplay valdisp_DataAcq_P_0,valueBackColor=(0,0,0)
	ValDisplay valdisp_DataAcq_P_0,limits={0,0,0},barmisc={0,1000},value= #"0.00"
	ValDisplay valdisp_DataAcq_P_1,pos={163.00,353.00},size={35.00,21.00},bodyWidth=35,disable=1
	ValDisplay valdisp_DataAcq_P_1,userdata(tabcontrol)=  "tab_DataAcq_Pressure"
	ValDisplay valdisp_DataAcq_P_1,userdata(ResizeControlsInfo)= A"!!,G3!!#BjJ,hnE!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	ValDisplay valdisp_DataAcq_P_1,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	ValDisplay valdisp_DataAcq_P_1,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	ValDisplay valdisp_DataAcq_P_1,fSize=14,fStyle=0
	ValDisplay valdisp_DataAcq_P_1,valueBackColor=(65535,65535,65535)
	ValDisplay valdisp_DataAcq_P_1,limits={0,0,0},barmisc={0,1000},value= #"0.00"
	ValDisplay valdisp_DataAcq_P_2,pos={204.00,353.00},size={35.00,21.00},bodyWidth=35,disable=1
	ValDisplay valdisp_DataAcq_P_2,userdata(tabcontrol)=  "tab_DataAcq_Pressure"
	ValDisplay valdisp_DataAcq_P_2,userdata(ResizeControlsInfo)= A"!!,G\\!!#BjJ,hnE!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	ValDisplay valdisp_DataAcq_P_2,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	ValDisplay valdisp_DataAcq_P_2,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	ValDisplay valdisp_DataAcq_P_2,fSize=14,fStyle=0
	ValDisplay valdisp_DataAcq_P_2,valueBackColor=(65535,65535,65535)
	ValDisplay valdisp_DataAcq_P_2,limits={0,0,0},barmisc={0,1000},value= #"0.00"
	ValDisplay valdisp_DataAcq_P_3,pos={246.00,353.00},size={35.00,21.00},bodyWidth=35,disable=1
	ValDisplay valdisp_DataAcq_P_3,userdata(tabcontrol)=  "tab_DataAcq_Pressure"
	ValDisplay valdisp_DataAcq_P_3,userdata(ResizeControlsInfo)= A"!!,H1!!#BjJ,hnE!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	ValDisplay valdisp_DataAcq_P_3,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	ValDisplay valdisp_DataAcq_P_3,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	ValDisplay valdisp_DataAcq_P_3,fSize=14,fStyle=0
	ValDisplay valdisp_DataAcq_P_3,valueBackColor=(65535,65535,65535)
	ValDisplay valdisp_DataAcq_P_3,limits={0,0,0},barmisc={0,1000},value= #"0.00"
	ValDisplay valdisp_DataAcq_P_4,pos={288.00,353.00},size={35.00,21.00},bodyWidth=35,disable=1
	ValDisplay valdisp_DataAcq_P_4,userdata(tabcontrol)=  "tab_DataAcq_Pressure"
	ValDisplay valdisp_DataAcq_P_4,userdata(ResizeControlsInfo)= A"!!,HK!!#BjJ,hnE!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	ValDisplay valdisp_DataAcq_P_4,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	ValDisplay valdisp_DataAcq_P_4,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	ValDisplay valdisp_DataAcq_P_4,fSize=14,fStyle=0
	ValDisplay valdisp_DataAcq_P_4,valueBackColor=(65535,65535,65535)
	ValDisplay valdisp_DataAcq_P_4,limits={0,0,0},barmisc={0,1000},value= #"0.00"
	ValDisplay valdisp_DataAcq_P_5,pos={329.00,353.00},size={35.00,21.00},bodyWidth=35,disable=1
	ValDisplay valdisp_DataAcq_P_5,userdata(tabcontrol)=  "tab_DataAcq_Pressure"
	ValDisplay valdisp_DataAcq_P_5,userdata(ResizeControlsInfo)= A"!!,H_J,hs@J,hnE!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	ValDisplay valdisp_DataAcq_P_5,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	ValDisplay valdisp_DataAcq_P_5,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	ValDisplay valdisp_DataAcq_P_5,fSize=14,fStyle=0
	ValDisplay valdisp_DataAcq_P_5,valueBackColor=(65535,65535,65535)
	ValDisplay valdisp_DataAcq_P_5,limits={0,0,0},barmisc={0,1000},value= #"0.00"
	ValDisplay valdisp_DataAcq_P_6,pos={371.00,353.00},size={35.00,21.00},bodyWidth=35,disable=1
	ValDisplay valdisp_DataAcq_P_6,userdata(tabcontrol)=  "tab_DataAcq_Pressure"
	ValDisplay valdisp_DataAcq_P_6,userdata(ResizeControlsInfo)= A"!!,HtJ,hs@J,hnE!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	ValDisplay valdisp_DataAcq_P_6,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	ValDisplay valdisp_DataAcq_P_6,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	ValDisplay valdisp_DataAcq_P_6,fSize=14,fStyle=0
	ValDisplay valdisp_DataAcq_P_6,valueBackColor=(65535,65535,65535)
	ValDisplay valdisp_DataAcq_P_6,limits={0,0,0},barmisc={0,1000},value= #"0.00"
	ValDisplay valdisp_DataAcq_P_7,pos={414.00,353.00},size={35.00,21.00},bodyWidth=35,disable=1
	ValDisplay valdisp_DataAcq_P_7,userdata(tabcontrol)=  "tab_DataAcq_Pressure"
	ValDisplay valdisp_DataAcq_P_7,userdata(ResizeControlsInfo)= A"!!,I5!!#BjJ,hnE!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	ValDisplay valdisp_DataAcq_P_7,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	ValDisplay valdisp_DataAcq_P_7,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	ValDisplay valdisp_DataAcq_P_7,fSize=14,fStyle=0
	ValDisplay valdisp_DataAcq_P_7,valueBackColor=(65535,65535,65535)
	ValDisplay valdisp_DataAcq_P_7,limits={0,0,0},barmisc={0,1000},value= #"0.00"
	TabControl tab_DataAcq_Pressure,pos={38.00,272.00},size={425.00,110.00},disable=1,proc=ACL_DisplayTab
	TabControl tab_DataAcq_Pressure,userdata(tabnum)=  "0"
	TabControl tab_DataAcq_Pressure,userdata(tabcontrol)=  "ADC"
	TabControl tab_DataAcq_Pressure,userdata(currenttab)=  "0"
	TabControl tab_DataAcq_Pressure,userdata(ResizeControlsInfo)= A"!!,D'!!#BB!!#C9J,hpkz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TabControl tab_DataAcq_Pressure,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	TabControl tab_DataAcq_Pressure,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	TabControl tab_DataAcq_Pressure,labelBack=(60928,60928,60928),fSize=10
	TabControl tab_DataAcq_Pressure,tabLabel(0)="Auto",tabLabel(1)="Manual",value= 0
	Button button_DataAcq_SSSetPressureMan,pos={46.00,302.00},size={84.00,27.00},disable=3,proc=ButtonProc_DataAcq_ManPressSet,title="Apply"
	Button button_DataAcq_SSSetPressureMan,userdata(tabnum)=  "1"
	Button button_DataAcq_SSSetPressureMan,userdata(tabcontrol)=  "tab_DataAcq_Pressure"
	Button button_DataAcq_SSSetPressureMan,userdata(ResizeControlsInfo)= A"!!,D7!!#BFJ,hp7!!#=;z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_DataAcq_SSSetPressureMan,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	Button button_DataAcq_SSSetPressureMan,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	Button button_DataAcq_PPSetPressureMan,pos={207.00,302.00},size={90.00,27.00},disable=1,proc=ButtonProc_ManPP,title="Pressure Pulse"
	Button button_DataAcq_PPSetPressureMan,userdata(tabnum)=  "1"
	Button button_DataAcq_PPSetPressureMan,userdata(tabcontrol)=  "tab_DataAcq_Pressure"
	Button button_DataAcq_PPSetPressureMan,userdata(ResizeControlsInfo)= A"!!,GT!!#BFJ,hp7!!#=;z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_DataAcq_PPSetPressureMan,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	Button button_DataAcq_PPSetPressureMan,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable setvar_DataAcq_SSPressure,pos={132.00,307.00},size={69.00,18.00},bodyWidth=50,disable=1,proc=DAP_SetVarProc_CAA,title="psi"
	SetVariable setvar_DataAcq_SSPressure,userdata(tabnum)=  "1"
	SetVariable setvar_DataAcq_SSPressure,userdata(tabcontrol)=  "tab_DataAcq_Pressure"
	SetVariable setvar_DataAcq_SSPressure,userdata(ResizeControlsInfo)= A"!!,Fh!!#BJ!!#?!!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_DataAcq_SSPressure,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable setvar_DataAcq_SSPressure,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable setvar_DataAcq_SSPressure,limits={-10,10,1},value= _NUM:0
	SetVariable setvar_DataAcq_PPPressure,pos={298.00,307.00},size={69.00,18.00},bodyWidth=50,disable=1,proc=DAP_SetVarProc_CAA,title="psi"
	SetVariable setvar_DataAcq_PPPressure,userdata(tabnum)=  "1"
	SetVariable setvar_DataAcq_PPPressure,userdata(tabcontrol)=  "tab_DataAcq_Pressure"
	SetVariable setvar_DataAcq_PPPressure,userdata(ResizeControlsInfo)= A"!!,HHJ,hrt!!#?!!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_DataAcq_PPPressure,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable setvar_DataAcq_PPPressure,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable setvar_DataAcq_PPPressure,limits={-10,10,1},value= _NUM:5
	SetVariable setvar_DataAcq_PPDuration,pos={369.00,307.00},size={87.00,18.00},bodyWidth=40,disable=1,proc=DAP_SetVarProc_CAA,title="Dur(ms)"
	SetVariable setvar_DataAcq_PPDuration,userdata(tabnum)=  "1"
	SetVariable setvar_DataAcq_PPDuration,userdata(tabcontrol)=  "tab_DataAcq_Pressure"
	SetVariable setvar_DataAcq_PPDuration,userdata(ResizeControlsInfo)= A"!!,Hh!!#BIJ,hp?!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_DataAcq_PPDuration,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable setvar_DataAcq_PPDuration,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable setvar_DataAcq_PPDuration,limits={0,300,1},value= _NUM:300
	CheckBox check_DataAcq_ManPressureAll,pos={69.00,332.00},size={29.00,15.00},disable=3,title="All"
	CheckBox check_DataAcq_ManPressureAll,userdata(tabnum)=  "1"
	CheckBox check_DataAcq_ManPressureAll,userdata(tabcontrol)=  "tab_DataAcq_Pressure"
	CheckBox check_DataAcq_ManPressureAll,userdata(ResizeControlsInfo)= A"!!,Dk!!#BUJ,hn!!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_DataAcq_ManPressureAll,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_DataAcq_ManPressureAll,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox check_DataAcq_ManPressureAll,value= 0
	CheckBox check_settings_TP_show_peak,pos={34.00,132.00},size={127.00,15.00},disable=1,title="Show peak resistance"
	CheckBox check_settings_TP_show_peak,help={"Show the peak resistance curve during the testpulse"}
	CheckBox check_settings_TP_show_peak,userdata(tabnum)=  "5"
	CheckBox check_settings_TP_show_peak,userdata(tabcontrol)=  "ADC"
	CheckBox check_settings_TP_show_peak,userdata(ResizeControlsInfo)= A"!!,Cl!!#@h!!#@b!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_settings_TP_show_peak,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_settings_TP_show_peak,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox check_settings_TP_show_peak,value= 1
	CheckBox check_settings_TP_show_steady,pos={172.00,133.00},size={164.00,15.00},disable=1,title="Show steady state resistance"
	CheckBox check_settings_TP_show_steady,help={"Show the steady state resistance curve during the testpulse"}
	CheckBox check_settings_TP_show_steady,userdata(tabnum)=  "5"
	CheckBox check_settings_TP_show_steady,userdata(tabcontrol)=  "ADC"
	CheckBox check_settings_TP_show_steady,userdata(ResizeControlsInfo)= A"!!,G<!!#@i!!#A3!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_settings_TP_show_steady,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_settings_TP_show_steady,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox check_settings_TP_show_steady,value= 1
	CheckBox check_DatAcq_ApproachNear,pos={86.00,329.00},size={40.00,15.00},disable=1,proc=P_Check_ApproachNear,title="Near"
	CheckBox check_DatAcq_ApproachNear,help={"Apply postive pressure to all headstages"}
	CheckBox check_DatAcq_ApproachNear,userdata(tabnum)=  "0"
	CheckBox check_DatAcq_ApproachNear,userdata(tabcontrol)=  "tab_DataAcq_Pressure"
	CheckBox check_DatAcq_ApproachNear,userdata(ResizeControlsInfo)= A"!!,Ef!!#B^J,hnY!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_DatAcq_ApproachNear,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_DatAcq_ApproachNear,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox check_DatAcq_ApproachNear,value= 0
	Button button_DataAcq_SlowComp_VC,pos={400.00,236.00},size={55.00,20.00},disable=1,proc=DAP_ButtonProc_AmpCntrls,title="Cp Slow"
	Button button_DataAcq_SlowComp_VC,help={"Activates MCC auto slow capacitance compensation"}
	Button button_DataAcq_SlowComp_VC,userdata(tabnum)=  "0"
	Button button_DataAcq_SlowComp_VC,userdata(tabcontrol)=  "tab_DataAcq_Amp"
	Button button_DataAcq_SlowComp_VC,userdata(ResizeControlsInfo)= A"!!,I.!!#B&!!#>j!!#<Xz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_DataAcq_SlowComp_VC,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	Button button_DataAcq_SlowComp_VC,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox check_DatAcq_SealAtm,pos={192.00,329.00},size={41.00,15.00},disable=1,proc=P_Check_SealAtm,title="Atm."
	CheckBox check_DatAcq_SealAtm,help={"Seals all headstates with active test pulse"}
	CheckBox check_DatAcq_SealAtm,userdata(tabnum)=  "0"
	CheckBox check_DatAcq_SealAtm,userdata(tabcontrol)=  "tab_DataAcq_Pressure"
	CheckBox check_DatAcq_SealAtm,userdata(ResizeControlsInfo)= A"!!,GP!!#B^J,hn]!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_DatAcq_SealAtm,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_DatAcq_SealAtm,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox check_DatAcq_SealAtm,value= 0
	CheckBox Check_DataAcq1_DistribDaq,pos={180.00,644.00},size={97.00,15.00},disable=1,proc=DAP_CheckProc_DistributedAcq,title="Distributed Acq"
	CheckBox Check_DataAcq1_DistribDaq,help={"Determines if distributed acquisition is used."}
	CheckBox Check_DataAcq1_DistribDaq,userdata(tabnum)=  "0"
	CheckBox Check_DataAcq1_DistribDaq,userdata(tabcontrol)=  "ADC"
	CheckBox Check_DataAcq1_DistribDaq,userdata(ResizeControlsInfo)= A"!!,GD!!#D1!!#@&!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_DataAcq1_DistribDaq,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_DataAcq1_DistribDaq,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_DataAcq1_DistribDaq,value= 0
	SetVariable setvar_DataAcq_dDAQDelay,pos={322.00,683.00},size={144.00,18.00},bodyWidth=50,disable=1,title="dDAQ delay (ms)"
	SetVariable setvar_DataAcq_dDAQDelay,help={"Delay between the sets during distributed DAQ."}
	SetVariable setvar_DataAcq_dDAQDelay,userdata(tabnum)=  "0"
	SetVariable setvar_DataAcq_dDAQDelay,userdata(tabcontrol)=  "ADC"
	SetVariable setvar_DataAcq_dDAQDelay,userdata(ResizeControlsInfo)= A"!!,H\\!!#D:^]6_5!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_DataAcq_dDAQDelay,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_DataAcq_dDAQDelay,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_DataAcq_dDAQDelay,limits={0,inf,1},value= _NUM:0
	Button button_DataAcq_OpenCommentNB,pos={416.00,735.00},size={36.00,19.00},disable=1,proc=DAP_ButtonProc_OpenCommentNB,title="NB"
	Button button_DataAcq_OpenCommentNB,help={"Open a notebook displaying the comments of all sweeps and allowing free form additions by the user."}
	Button button_DataAcq_OpenCommentNB,userdata(tabnum)=  "0"
	Button button_DataAcq_OpenCommentNB,userdata(tabcontrol)=  "ADC"
	Button button_DataAcq_OpenCommentNB,userdata(ResizeControlsInfo)= A"!!,I6!!#DG^]6\\4!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_DataAcq_OpenCommentNB,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button button_DataAcq_OpenCommentNB,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_Settings_TPAfterDAQ,pos={172.00,109.00},size={130.00,15.00},disable=1,title="Activate TP after DAQ"
	CheckBox check_Settings_TPAfterDAQ,help={"Immediately start a test pulse after DAQ finishes"}
	CheckBox check_Settings_TPAfterDAQ,userdata(tabnum)=  "5"
	CheckBox check_Settings_TPAfterDAQ,userdata(tabcontrol)=  "ADC"
	CheckBox check_Settings_TPAfterDAQ,userdata(ResizeControlsInfo)= A"!!,G<!!#@>!!#@f!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_Settings_TPAfterDAQ,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_Settings_TPAfterDAQ,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_Settings_TPAfterDAQ,value= 0
	PopupMenu Popup_Settings_SampIntMult,pos={223.00,239.00},size={189.00,19.00},bodyWidth=40,disable=1,title="Sampling interval multiplier"
	PopupMenu Popup_Settings_SampIntMult,help={"Multiplier for the dataacquisition sampling interval (higher values mean lower resolution). The testpulse will always be sampled at the lowest possible interval."}
	PopupMenu Popup_Settings_SampIntMult,userdata(tabnum)=  "5"
	PopupMenu Popup_Settings_SampIntMult,userdata(tabcontrol)=  "ADC"
	PopupMenu Popup_Settings_SampIntMult,userdata(ResizeControlsInfo)= A"!!,Go!!#B)!!#AL!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Popup_Settings_SampIntMult,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Popup_Settings_SampIntMult,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Popup_Settings_SampIntMult,mode=1,popvalue="1",value= #"\"1;2;4;8;16;32;64\""
	TitleBox Title_settings_Hardware_Manipul,pos={45.00,588.00},size={70.00,15.00},title="Manipulators"
	TitleBox Title_settings_Hardware_Manipul,userdata(tabnum)=  "6"
	TitleBox Title_settings_Hardware_Manipul,userdata(tabcontrol)=  "ADC"
	TitleBox Title_settings_Hardware_Manipul,userdata(ResizeControlsInfo)= A"!!,DC!!#D#!!#?E!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox Title_settings_Hardware_Manipul,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	TitleBox Title_settings_Hardware_Manipul,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	TitleBox Title_settings_Hardware_Manipul,frame=0
	PopupMenu popup_Settings_Manip_MSSMnipLst,pos={112.00,604.00},size={150.00,19.00},bodyWidth=150,disable=2,proc=DAP_PopMenuProc_CAA
	PopupMenu popup_Settings_Manip_MSSMnipLst,help={"List of available Scientifica micromanipulators"}
	PopupMenu popup_Settings_Manip_MSSMnipLst,userdata(tabnum)=  "6"
	PopupMenu popup_Settings_Manip_MSSMnipLst,userdata(tabcontrol)=  "ADC"
	PopupMenu popup_Settings_Manip_MSSMnipLst,userdata(ResizeControlsInfo)= A"!!,F?!!#D'!!#A(!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu popup_Settings_Manip_MSSMnipLst,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu popup_Settings_Manip_MSSMnipLst,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu popup_Settings_Manip_MSSMnipLst,mode=1,popvalue="- none -",value= #"\"- none -;\" + M_GetListOfAttachedManipulators()"
	CheckBox Check_Hardware_UseManip,pos={48.00,607.00},size={50.00,15.00},proc=DAP_Activate_Manips,title="Enable"
	CheckBox Check_Hardware_UseManip,help={"Try to establish communication with the manipulators."}
	CheckBox Check_Hardware_UseManip,userdata(tabnum)=  "6"
	CheckBox Check_Hardware_UseManip,userdata(tabcontrol)=  "ADC"
	CheckBox Check_Hardware_UseManip,userdata(ResizeControlsInfo)= A"!!,DO!!#D'^]6\\l!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_Hardware_UseManip,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_Hardware_UseManip,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_Hardware_UseManip,value= 0
	CheckBox Check_Settings_NwbExport,pos={34.00,240.00},size={102.00,15.00},disable=1,title="Export into NWB"
	CheckBox Check_Settings_NwbExport,help={"Export all data including sweeps into a file in the NeurodataWithoutBorders fornat,"}
	CheckBox Check_Settings_NwbExport,userdata(tabnum)=  "5"
	CheckBox Check_Settings_NwbExport,userdata(tabcontrol)=  "ADC"
	CheckBox Check_Settings_NwbExport,userdata(ResizeControlsInfo)= A"!!,Cl!!#B*!!#@0!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_Settings_NwbExport,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_Settings_NwbExport,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_Settings_NwbExport,value= 0
	SetVariable setvar_DataAcq_OnsetDelayUser,pos={299.00,642.00},size={167.00,18.00},bodyWidth=50,disable=1,title="User onset delay (ms)"
	SetVariable setvar_DataAcq_OnsetDelayUser,help={"A global parameter that delays the onset time of a set after the initiation of data acquistion. Data acquisition start time is NOT delayed. Useful when set(s) have insufficient baseline epoch."}
	SetVariable setvar_DataAcq_OnsetDelayUser,userdata(tabnum)=  "0"
	SetVariable setvar_DataAcq_OnsetDelayUser,userdata(tabcontrol)=  "ADC"
	SetVariable setvar_DataAcq_OnsetDelayUser,userdata(ResizeControlsInfo)= A"!!,HPJ,ht[J,hqa!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_DataAcq_OnsetDelayUser,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_DataAcq_OnsetDelayUser,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_DataAcq_OnsetDelayUser,limits={0,inf,1},value= _NUM:1
	ValDisplay valdisp_DataAcq_OnsetDelayAuto,pos={323.00,705.00},size={143.00,17.00},bodyWidth=50,disable=1,title="Onset delay (ms)"
	ValDisplay valdisp_DataAcq_OnsetDelayAuto,help={"The additional onset delay required by the \"Insert TP\" setting."}
	ValDisplay valdisp_DataAcq_OnsetDelayAuto,userdata(tabnum)=  "0"
	ValDisplay valdisp_DataAcq_OnsetDelayAuto,userdata(tabcontrol)=  "ADC"
	ValDisplay valdisp_DataAcq_OnsetDelayAuto,userdata(ResizeControlsInfo)= A"!!,H\\J,htk5QF.^!!#<@z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	ValDisplay valdisp_DataAcq_OnsetDelayAuto,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	ValDisplay valdisp_DataAcq_OnsetDelayAuto,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	ValDisplay valdisp_DataAcq_OnsetDelayAuto,limits={0,0,0},barmisc={0,1000}
	ValDisplay valdisp_DataAcq_OnsetDelayAuto,value= _NUM:0
	Button button_Hardware_ClearChanConn,pos={275.00,329.00},size={150.00,20.00},proc=DAP_ButtonProc_ClearChanCon,title="Clear Associations"
	Button button_Hardware_ClearChanConn,help={"Clear the channel/amplifier association of the current headstage."}
	Button button_Hardware_ClearChanConn,userdata(tabnum)=  "6"
	Button button_Hardware_ClearChanConn,userdata(tabcontrol)=  "ADC"
	CheckBox check_Settings_DisablePressure,pos={150.00,760.00},size={190.00,15.00},disable=1,title="Stop pressure on data acquisition"
	CheckBox check_Settings_DisablePressure,userdata(tabnum)=  "5"
	CheckBox check_Settings_DisablePressure,userdata(tabcontrol)=  "ADC",value= 0
	DefineGuide UGV0={FR,-25},UGH0={FB,-27},UGV1={FL,481}
	SetWindow kwTopWin,hook(cleanup)=DAP_WindowHook
	SetWindow kwTopWin,userdata(ResizeControlsInfo)= A"!!*'\"z!!#C[!!#Da!!!!\"zzzzzzzzzzzzzzzzzzzz"
	SetWindow kwTopWin,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzzzzzzzzzzzzzzz"
	SetWindow kwTopWin,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzzzzzzzzz!!!"
	SetWindow kwTopWin,userdata(ResizeControlsGuides)=  "UGV0;UGH0;UGV1;"
	SetWindow kwTopWin,userdata(ResizeControlsInfoUGV0)= A":-hTC3`S[N0KW?-:-(d/?U\\pIH#m=a:cCI8=\\qOJ<HD_l4%N.F8Qnnb<'a2=0KW*,;b9q[:JNr-2E*6B0KVd)8OQ!%3_!\"/7o`,K75?nc;FO8U:K'ha8P`)B/M]1F"
	SetWindow kwTopWin,userdata(ResizeControlsInfoUGH0)= A":-hTC3`S[@0KW?-:-(d/?U\\pIH#m=a:cCI8=\\qOJ<HD_l4%N.F8Qnnb<'a2=0fr3-;b9q[:JNr10KCa>0KVd)8OQ!%3^uFt7o`,K75?nc;FO8U:K'ha8P`)B/M]7H"
	SetWindow kwTopWin,userdata(ResizeControlsInfoUGV1)= A":-hTC3`S[N0frH.:-(d/?U\\pIH#m=a:cCI8=\\qOJ<HD_l4%N.F8Qnnb<'a2=0KW*,;b9q[:JNr-3&*$>0KVd)8OQ!%3^ue)7o`,K75?nc;FO8U:K'ha8P`)B1cR3O"
EndMacro

/// @brief Restores the base state of the DA_Ephys panel.
/// Useful when adding controls to GUI. Facilitates use of auto generation of GUI code. 
/// Useful when template experiment file has been overwritten.
Function DAP_EphysPanelStartUpSettings(panelTitle)
	string panelTitle

	if(!windowExists(panelTitle))
		print "Panel has to exist"
		return NaN
	endif

	if(!HSU_DeviceIsUnlocked(panelTitle, silentCheck=1))
		print "The Panel has to be unlocked"
		return NaN
	endif

	// remove tools
	HideTools/W=$panelTitle/A

	SetWindow $panelTitle, userData(panelVersion) = ""

	DAP_TurnOffAllHeadstages(panelTitle)
	DAP_TurnOffAllDACs(panelTitle)
	DAP_TurnOffAllADCs(panelTitle)
	DAP_TurnOffAllTTLs(panelTitle)

	ChangeTab(panelTitle, "ADC", 0)
	DAP_UpdateClampmodeTabs(panelTitle, 0, V_CLAMP_MODE)
	ChangeTab(panelTitle, "ADC", 6)
	DoUpdate/W=$panelTitle

	SetVariable Gain_AD_00 WIN = $panelTitle, value = _NUM:0.00
	SetVariable Gain_AD_01 WIN = $panelTitle, value = _NUM:0.00
	SetVariable Gain_AD_02 WIN = $panelTitle, value = _NUM:0.00
	SetVariable Gain_AD_03 WIN = $panelTitle, value = _NUM:0.00
	SetVariable Gain_AD_04 WIN = $panelTitle, value = _NUM:0.00
	SetVariable Gain_AD_05 WIN = $panelTitle, value = _NUM:0.00
	SetVariable Gain_AD_06 WIN = $panelTitle, value = _NUM:0.00
	SetVariable Gain_AD_07 WIN = $panelTitle, value = _NUM:0.00
	SetVariable Gain_AD_08 WIN = $panelTitle, value = _NUM:0.00
	SetVariable Gain_AD_09 WIN = $panelTitle, value = _NUM:0.00
	SetVariable Gain_AD_10 WIN = $panelTitle, value = _NUM:0.00
	SetVariable Gain_AD_11 WIN = $panelTitle, value = _NUM:0.00
	SetVariable Gain_AD_12 WIN = $panelTitle, value = _NUM:0.00
	SetVariable Gain_AD_13 WIN = $panelTitle, value = _NUM:0.00
	SetVariable Gain_AD_14 WIN = $panelTitle, value = _NUM:0.00
	SetVariable Gain_AD_15 WIN = $panelTitle, value = _NUM:0.00

	SetVariable Gain_DA_00 WIN = $panelTitle, value = _NUM:0.00
	SetVariable Gain_DA_01 WIN = $panelTitle, value = _NUM:0.00
	SetVariable Gain_DA_02 WIN = $panelTitle, value = _NUM:0.00
	SetVariable Gain_DA_03 WIN = $panelTitle, value = _NUM:0.00
	SetVariable Gain_DA_04 WIN = $panelTitle, value = _NUM:0.00
	SetVariable Gain_DA_05 WIN = $panelTitle, value = _NUM:0.00
	SetVariable Gain_DA_06 WIN = $panelTitle, value = _NUM:0.00
	SetVariable Gain_DA_07 WIN = $panelTitle, value = _NUM:0.00
	
	PopupMenu Wave_DA_00 WIN = $panelTitle,mode=1, userdata(MenuExp) = ""
	PopupMenu Wave_DA_01 WIN = $panelTitle,mode=1, userdata(MenuExp) = ""
	PopupMenu Wave_DA_02 WIN = $panelTitle,mode=1, userdata(MenuExp) = ""
	PopupMenu Wave_DA_03 WIN = $panelTitle,mode=1, userdata(MenuExp) = ""
	PopupMenu Wave_DA_04 WIN = $panelTitle,mode=1, userdata(MenuExp) = ""
	PopupMenu Wave_DA_05 WIN = $panelTitle,mode=1, userdata(MenuExp) = ""
	PopupMenu Wave_DA_06 WIN = $panelTitle,mode=1, userdata(MenuExp) = ""
	PopupMenu Wave_DA_07 WIN = $panelTitle,mode=1, userdata(MenuExp) = ""

	SetVariable Scale_DA_00 WIN = $panelTitle, value = _NUM:1
	SetVariable Scale_DA_01 WIN = $panelTitle, value = _NUM:1
	SetVariable Scale_DA_02 WIN = $panelTitle, value = _NUM:1
	SetVariable Scale_DA_03 WIN = $panelTitle, value = _NUM:1
	SetVariable Scale_DA_04 WIN = $panelTitle, value = _NUM:1
	SetVariable Scale_DA_05 WIN = $panelTitle, value = _NUM:1
	SetVariable Scale_DA_06 WIN = $panelTitle, value = _NUM:1
	SetVariable Scale_DA_07 WIN = $panelTitle, value = _NUM:1

	SetVariable SetVar_DataAcq_Comment WIN = $panelTitle,fSize=8,value= _STR:""

	CheckBox Check_DataAcq1_RepeatAcq Win = $panelTitle, value = 1
	CheckBox Check_DataAcq1_DistribDaq Win = $panelTitle, value = 0

	SetVariable SetVar_DataAcq_ITI WIN = $panelTitle, value = _NUM:0

	SetVariable SetVar_DataAcq_TPDuration  WIN = $panelTitle,value= _NUM:10
	SetVariable SetVar_DataAcq_TPAmplitude  WIN = $panelTitle,value= _NUM:10
	SetVariable SetVar_DataAcq_TPBaselinePerc  WIN = $panelTitle,value= _NUM:25

	PopupMenu Wave_TTL_00 Win = $panelTitle ,mode=1, userdata(MenuExp) = ""
	PopupMenu Wave_TTL_01 Win = $panelTitle ,mode=1, userdata(MenuExp) = ""
	PopupMenu Wave_TTL_02 Win = $panelTitle ,mode=1, userdata(MenuExp) = ""
	PopupMenu Wave_TTL_03 Win = $panelTitle ,mode=1, userdata(MenuExp) = ""
	PopupMenu Wave_TTL_04 Win = $panelTitle ,mode=1, userdata(MenuExp) = ""
	PopupMenu Wave_TTL_05 Win = $panelTitle ,mode=1, userdata(MenuExp) = ""
	PopupMenu Wave_TTL_06 Win = $panelTitle ,mode=1, userdata(MenuExp) = ""
	PopupMenu Wave_TTL_07 Win = $panelTitle ,mode=1, userdata(MenuExp) = ""
	
	CheckBox Check_Settings_TrigOut Win = $panelTitle, value = 0
	CheckBox Check_Settings_TrigIn Win = $panelTitle, value = 0

	SetVariable SetVar_DataAcq_SetRepeats WIN = $panelTitle,value= _NUM:1

	CheckBox Check_Settings_UseDoublePrec WIN = $panelTitle, value= 0
	CheckBox Check_Settings_SkipAnalysFuncs WIN = $panelTitle, value= 0
	PopupMenu Popup_Settings_SampIntMult WIN = $panelTitle, mode = 1

	CheckBox Check_AsyncAD_00 WIN = $panelTitle,value= 0
	CheckBox Check_AsyncAD_01 WIN = $panelTitle,value= 0
	CheckBox Check_AsyncAD_02 WIN = $panelTitle,value= 0
	CheckBox Check_AsyncAD_03 WIN = $panelTitle,value= 0
	CheckBox Check_AsyncAD_04 WIN = $panelTitle,value= 0
	CheckBox Check_AsyncAD_05 WIN = $panelTitle,value= 0
	CheckBox Check_AsyncAD_06 WIN = $panelTitle,value= 0
	CheckBox Check_AsyncAD_07 WIN = $panelTitle,value= 0
	
	SetVariable Gain_AsyncAD_00 WIN = $panelTitle,value= _NUM:1
	SetVariable Gain_AsyncAD_01 WIN = $panelTitle,value= _NUM:1
	SetVariable Gain_AsyncAD_02 WIN = $panelTitle,value= _NUM:1
	SetVariable Gain_AsyncAD_03 WIN = $panelTitle,value= _NUM:1
	SetVariable Gain_AsyncAD_04 WIN = $panelTitle,value= _NUM:1
	SetVariable Gain_AsyncAD_05 WIN = $panelTitle,value= _NUM:1
	SetVariable Gain_AsyncAD_06 WIN = $panelTitle,value= _NUM:1
	SetVariable Gain_AsyncAD_07 WIN = $panelTitle,value= _NUM:1
	
	SetVariable SetVar_AsyncAD_Title_00 WIN = $panelTitle,value= _STR:""
	SetVariable SetVar_AsyncAD_Title_01 WIN = $panelTitle,value= _STR:""
	SetVariable SetVar_AsyncAD_Title_02 WIN = $panelTitle,value= _STR:""
	SetVariable SetVar_AsyncAD_Title_03 WIN = $panelTitle,value= _STR:""
	SetVariable SetVar_AsyncAD_Title_04 WIN = $panelTitle,value= _STR:""
	SetVariable SetVar_AsyncAD_Title_05 WIN = $panelTitle,value= _STR:""
	SetVariable SetVar_AsyncAD_Title_06 WIN = $panelTitle,value= _STR:""
	SetVariable SetVar_AsyncAD_Title_07 WIN = $panelTitle,value= _STR:""
	
	SetVariable Unit_AsyncAD_00 WIN = $panelTitle,value= _STR:""
	SetVariable Unit_AsyncAD_01 WIN = $panelTitle,value= _STR:""
	SetVariable Unit_AsyncAD_02 WIN = $panelTitle,value= _STR:""
	SetVariable Unit_AsyncAD_03 WIN = $panelTitle,value= _STR:""
	SetVariable Unit_AsyncAD_04 WIN = $panelTitle,value= _STR:""
	SetVariable Unit_AsyncAD_05 WIN = $panelTitle,value= _STR:""
	SetVariable Unit_AsyncAD_06 WIN = $panelTitle,value= _STR:""
	SetVariable Unit_AsyncAD_07 WIN = $panelTitle,value= _STR:""
	
	CheckBox Check_Settings_Append WIN = $panelTitle,value= 0
	CheckBox Radio_ClampMode_0 WIN = $panelTitle,value= 1,mode=1
	
	// Sets MIES headstage to V-Clamp
	CheckBox Radio_ClampMode_0 WIN = $panelTitle, value= 1,mode=1
	CheckBox Radio_ClampMode_1 WIN = $panelTitle, value= 0,mode=1
	CheckBox Radio_ClampMode_2 WIN = $panelTitle, value= 1,mode=1
	CheckBox Radio_ClampMode_3 WIN = $panelTitle, value= 0,mode=1
	CheckBox Radio_ClampMode_4 WIN = $panelTitle, value= 1,mode=1
	CheckBox Radio_ClampMode_5 WIN = $panelTitle, value= 0,mode=1
	CheckBox Radio_ClampMode_6 WIN = $panelTitle, value= 1,mode=1
	CheckBox Radio_ClampMode_7 WIN = $panelTitle, value= 0,mode=1
	CheckBox Radio_ClampMode_8 WIN = $panelTitle, value= 1,mode=1
	CheckBox Radio_ClampMode_9 WIN = $panelTitle, value= 0,mode=1
	CheckBox Radio_ClampMode_10 WIN = $panelTitle, value= 1,mode=1
	CheckBox Radio_ClampMode_11 WIN = $panelTitle, value= 0,mode=1
	CheckBox Radio_ClampMode_12 WIN = $panelTitle, value= 1,mode=1
	CheckBox Radio_ClampMode_13 WIN = $panelTitle, value= 0,mode=1
	CheckBox Radio_ClampMode_14 WIN = $panelTitle, value= 1,mode=1
	CheckBox Radio_ClampMode_15 WIN = $panelTitle, value= 0,mode=1
	CheckBox Radio_ClampMode_1IZ WIN = $panelTitle, value= 0,mode=1
	CheckBox Radio_ClampMode_3IZ WIN = $panelTitle, value= 0,mode=1
	CheckBox Radio_ClampMode_5IZ WIN = $panelTitle, value= 0,mode=1
	CheckBox Radio_ClampMode_7IZ WIN = $panelTitle, value= 0,mode=1
	CheckBox Radio_ClampMode_9IZ WIN = $panelTitle, value= 0,mode=1
	CheckBox Radio_ClampMode_11IZ WIN = $panelTitle, value= 0,mode=1
	CheckBox Radio_ClampMode_13IZ WIN = $panelTitle, value= 0,mode=1
	CheckBox Radio_ClampMode_15IZ WIN = $panelTitle, value= 0,mode=1

	CheckBox Check_DataAcq_SendToAllAmp WIN = $panelTitle, value= 0

	SetVariable SetVar_Settings_VC_DAgain WIN = $panelTitle, value= _NUM:20
	SetVariable SetVar_Settings_VC_ADgain WIN = $panelTitle, value= _NUM:0.00999999977648258
	SetVariable SetVar_Settings_IC_ADgain WIN = $panelTitle, value= _NUM:0.00999999977648258

	PopupMenu Popup_Settings_VC_DA WIN = $panelTitle, mode=1
	PopupMenu Popup_Settings_VC_AD WIN = $panelTitle, mode=1
	PopupMenu Popup_Settings_IC_AD WIN = $panelTitle, mode=1
	PopupMenu Popup_Settings_HeadStage WIN = $panelTitle, mode=1
	PopupMenu Popup_Settings_IC_DA WIN = $panelTitle, mode=1
	PopupMenu Popup_Settings_IC_DA WIN = $panelTitle, mode=1

	SetVariable SetVar_Settings_IC_DAgain WIN = $panelTitle, value= _NUM:400

	SetVariable Search_DA_00 WIN = $panelTitle, value= _STR:""
	SetVariable Search_DA_01 WIN = $panelTitle, value= _STR:""
	SetVariable Search_DA_02 WIN = $panelTitle, value= _STR:""
	SetVariable Search_DA_03 WIN = $panelTitle, value= _STR:""
	SetVariable Search_DA_04 WIN = $panelTitle, value= _STR:""
	SetVariable Search_DA_05 WIN = $panelTitle, value= _STR:""
	SetVariable Search_DA_06 WIN = $panelTitle, value= _STR:""
	SetVariable Search_DA_07 WIN = $panelTitle, value= _STR:""

	CheckBox SearchUniversal_DA_00 WIN = $panelTitle, value= 0

	SetVariable Search_TTL_00 WIN = $panelTitle, value= _STR:""
	SetVariable Search_TTL_01 WIN = $panelTitle, value= _STR:""
	SetVariable Search_TTL_02 WIN = $panelTitle, value= _STR:""
	SetVariable Search_TTL_03 WIN = $panelTitle, value= _STR:""
	SetVariable Search_TTL_04 WIN = $panelTitle, value= _STR:""
	SetVariable Search_TTL_05 WIN = $panelTitle, value= _STR:""
	SetVariable Search_TTL_06 WIN = $panelTitle, value= _STR:""
	SetVariable Search_TTL_07 WIN = $panelTitle, value= _STR:""

	CheckBox SearchUniversal_TTL_00 WIN = $panelTitle, value= 0

	PopupMenu IndexEnd_DA_00 WIN = $panelTitle, mode=1, userdata(MenuExp) = ""
	PopupMenu IndexEnd_DA_01 WIN = $panelTitle, mode=1, userdata(MenuExp) = ""
	PopupMenu IndexEnd_DA_02 WIN = $panelTitle, mode=1, userdata(MenuExp) = ""
	PopupMenu IndexEnd_DA_03 WIN = $panelTitle, mode=1, userdata(MenuExp) = ""
	PopupMenu IndexEnd_DA_04 WIN = $panelTitle, mode=1, userdata(MenuExp) = ""
	PopupMenu IndexEnd_DA_05 WIN = $panelTitle, mode=1, userdata(MenuExp) = ""
	PopupMenu IndexEnd_DA_06 WIN = $panelTitle, mode=1, userdata(MenuExp) = ""
	PopupMenu IndexEnd_DA_07 WIN = $panelTitle, mode=1, userdata(MenuExp) = ""

	PopupMenu IndexEnd_TTL_00 WIN = $panelTitle, mode=1, userdata(MenuExp) = ""
	PopupMenu IndexEnd_TTL_01 WIN = $panelTitle, mode=1, userdata(MenuExp) = ""
	PopupMenu IndexEnd_TTL_02 WIN = $panelTitle, mode=1, userdata(MenuExp) = ""
	PopupMenu IndexEnd_TTL_03 WIN = $panelTitle, mode=1, userdata(MenuExp) = ""
	PopupMenu IndexEnd_TTL_04 WIN = $panelTitle, mode=1, userdata(MenuExp) = ""
	PopupMenu IndexEnd_TTL_05 WIN = $panelTitle, mode=1, userdata(MenuExp) = ""
	PopupMenu IndexEnd_TTL_06 WIN = $panelTitle, mode=1, userdata(MenuExp) = ""
	PopupMenu IndexEnd_TTL_07 WIN = $panelTitle, mode=1, userdata(MenuExp) = ""

	// don't make the scope subwindow part of the recreation macro
	CheckBox check_Settings_ShowScopeWindow WIN = $panelTitle, value= 0
	SCOPE_KillScopeWindowIfRequest(panelTitle)
	CheckBox check_Settings_ShowScopeWindow WIN = $panelTitle, value= 1

	CheckBox check_Settings_ITITP WIN = $panelTitle, value= 1
	CheckBox check_Settings_TPAfterDAQ WIN = $panelTitle, value= 0

	CheckBox check_Settings_Overwrite WIN = $panelTitle,value= 1
	CheckBox Check_Settings_NwbExport WIN = $panelTitle,value= 0

	SetVariable min_AsyncAD_00 WIN = $panelTitle,value= _NUM:0
	SetVariable max_AsyncAD_00 WIN = $panelTitle,value= _NUM:0
	CheckBox check_AsyncAlarm_00  WIN = $panelTitle,value= 0

	SetVariable min_AsyncAD_01 WIN = $panelTitle,value= _NUM:0
	SetVariable max_AsyncAD_01 WIN = $panelTitle,value= _NUM:0
	CheckBox check_AsyncAlarm_01  WIN = $panelTitle,value= 0

	SetVariable min_AsyncAD_02 WIN = $panelTitle,value= _NUM:0
	SetVariable max_AsyncAD_02 WIN = $panelTitle,value= _NUM:0
	CheckBox check_AsyncAlarm_02  WIN = $panelTitle,value= 0

	SetVariable min_AsyncAD_03 WIN = $panelTitle,value= _NUM:0
	SetVariable max_AsyncAD_03 WIN = $panelTitle,value= _NUM:0
	CheckBox check_AsyncAlarm_03  WIN = $panelTitle,value= 0

	SetVariable min_AsyncAD_04 WIN = $panelTitle,value= _NUM:0
	SetVariable max_AsyncAD_04 WIN = $panelTitle,value= _NUM:0
	CheckBox check_AsyncAlarm_04  WIN = $panelTitle,value= 0

	SetVariable min_AsyncAD_05 WIN = $panelTitle,value= _NUM:0
	SetVariable max_AsyncAD_05 WIN = $panelTitle,value= _NUM:0
	CheckBox check_AsyncAlarm_05  WIN = $panelTitle,value= 0

	SetVariable min_AsyncAD_06 WIN = $panelTitle,value= _NUM:0
	SetVariable max_AsyncAD_06 WIN = $panelTitle,value= _NUM:0
	CheckBox check_AsyncAlarm_06  WIN = $panelTitle,value= 0

	SetVariable min_AsyncAD_07 WIN = $panelTitle,value= _NUM:0
	SetVariable max_AsyncAD_07 WIN = $panelTitle,value= _NUM:0
	CheckBox check_AsyncAlarm_07  WIN = $panelTitle,value= 0

	CheckBox check_DataAcq_RepAcqRandom WIN = $panelTitle,value= 0
	CheckBox check_Settings_Option_3 WIN = $panelTitle,value= 0
	CheckBox check_Settings_ScalingZero WIN = $panelTitle,value= 0
	CheckBox check_Settings_SetOption_04 WIN = $panelTitle,fColor=(65280,43520,0),value= 0

	PopupMenu popup_MoreSettings_DeviceType WIN = $panelTitle,mode=1 // ,popvalue="ITC1600",value= #"\"ITC16;ITC18;ITC1600;ITC00;ITC16USB;ITC18USB;\""
	PopupMenu popup_moreSettings_DeviceNo WIN = $panelTitle,mode=1 // ,popvalue="0",value= #"\"0;1;2;3;4;5;6;7;8;9;10\""

	SetVariable SetVar_Sweep WIN = $panelTitle, limits={0,0,1}, value= _NUM:0

	SetVariable SetVar_DataAcq_dDAQDelay WIN = $panelTitle,value= _NUM:0
	SetVariable SetVar_DataAcq_OnsetDelayUser WIN = $panelTitle,value= _NUM:1
	ValDisplay valdisp_DataAcq_OnsetDelayAuto WIN = $panelTitle,value= _NUM:0
	ValDisplay valdisp_DataAcq_SweepsInSet WIN = $panelTitle,value= _NUM:1
	ValDisplay valdisp_DataAcq_SweepsActiveSet WIN = $panelTitle,value= _NUM:1
	ValDisplay valdisp_DataAcq_TrialsCountdown WIN = $panelTitle,value= _NUM:1
	ValDisplay valdisp_DataAcq_ITICountdown WIN = $panelTitle,value= _NUM:0

	SetVariable SetVar_DataAcq_TerminationDelay WIN = $panelTitle,value= _NUM:0

	CheckBox check_Settings_SetOption_5 WIN = $panelTitle,value= 1
	CheckBox Check_DataAcq1_IndexingLocked WIN = $panelTitle, value= 0

	SetVariable SetVar_DataAcq_ListRepeats WIN = $panelTitle,limits={1,inf,1},value= _NUM:1

	SetVariable setvar_Settings_TPBuffer WIN = $panelTitle, value= _NUM:1

	CheckBox check_DataAcq_IndexRandom WIN = $panelTitle, fColor=(65280,43520,0),value= 0

	ValDisplay ValDisp_DataAcq_SamplingInt win = $panelTitle, value= _NUM:0

	SetVariable SetVar_DataAcq_TPAmplitudeIC WIN = $panelTitle,value= _NUM:-50
	SetVariable SetVar_Hardware_VC_DA_Unit WIN = $panelTitle,value= _STR:"mV"
	SetVariable SetVar_Hardware_IC_DA_Unit WIN = $panelTitle,value= _STR:"pA"
	SetVariable SetVar_Hardware_VC_AD_Unit WIN = $panelTitle,value= _STR:"pA"
	SetVariable SetVar_Hardware_IC_AD_Unit WIN = $panelTitle,value= _STR:"mV"

	SetVariable Unit_DA_00 WIN = $panelTitle,limits={0,inf,1},value= _STR:""
	SetVariable Unit_DA_01 WIN = $panelTitle,limits={0,inf,1},value= _STR:""
	SetVariable Unit_DA_02 WIN = $panelTitle,limits={0,inf,1},value= _STR:""
	SetVariable Unit_DA_03 WIN = $panelTitle,limits={0,inf,1},value= _STR:""
	SetVariable Unit_DA_04 WIN = $panelTitle,limits={0,inf,1},value= _STR:""
	SetVariable Unit_DA_05 WIN = $panelTitle,limits={0,inf,1},value= _STR:""
	SetVariable Unit_DA_06 WIN = $panelTitle,limits={0,inf,1},value= _STR:""
	SetVariable Unit_DA_07 WIN = $panelTitle,limits={0,inf,1},value= _STR:""

	SetVariable Unit_AD_00 WIN = $panelTitle,limits={0,inf,1},value= _STR:""
	SetVariable Unit_AD_01 WIN = $panelTitle,limits={0,inf,1},value= _STR:""
	SetVariable Unit_AD_02 WIN = $panelTitle,limits={0,inf,1},value= _STR:""
	SetVariable Unit_AD_03 WIN = $panelTitle,limits={0,inf,1},value= _STR:""
	SetVariable Unit_AD_04 WIN = $panelTitle,limits={0,inf,1},value= _STR:""
	SetVariable Unit_AD_05 WIN = $panelTitle,limits={0,inf,1},value= _STR:""
	SetVariable Unit_AD_06 WIN = $panelTitle,limits={0,inf,1},value= _STR:""
	SetVariable Unit_AD_07 WIN = $panelTitle,limits={0,inf,1},value= _STR:""
	SetVariable Unit_AD_08 WIN = $panelTitle,limits={0,inf,1},value= _STR:""
	SetVariable Unit_AD_09 WIN = $panelTitle,limits={0,inf,1},value= _STR:""
	SetVariable Unit_AD_10 WIN = $panelTitle,limits={0,inf,1},value= _STR:""
	SetVariable Unit_AD_11 WIN = $panelTitle,limits={0,inf,1},value= _STR:""
	SetVariable Unit_AD_12 WIN = $panelTitle,limits={0,inf,1},value= _STR:""
	SetVariable Unit_AD_13 WIN = $panelTitle,limits={0,inf,1},value= _STR:""
	SetVariable Unit_AD_14 WIN = $panelTitle,limits={0,inf,1},value= _STR:""
	SetVariable Unit_AD_15 WIN = $panelTitle,limits={0,inf,1},value= _STR:""

	PopupMenu popup_Hardware_AvailITC1600s WIN = $panelTitle,mode=0 // ,value= #"DAP_ListOfITCDevices()"

	SetVariable SetVar_Hardware_Status WIN = $panelTitle,value= _STR:"Independent",noedit= 1
	SetVariable SetVar_Hardware_YokeList WIN = $panelTitle,value= _STR:"No Yoked Devices",noedit= 1
	PopupMenu popup_Hardware_YokedDACs WIN = $panelTitle, mode=0,value=DAP_GUIListOfYokedDevices()

	DisableControl(panelTitle, "popup_Settings_Manip_MSSMnipLst")
	SetCheckBoxState(panelTitle, "Check_Hardware_UseManip", 0)

	SetVariable SetVar_DataAcq_Hold_IC WIN = $panelTitle, value= _NUM:0
	SetVariable Setvar_DataAcq_PipetteOffset_VC WIN = $panelTitle, value= _NUM:0
	SetVariable SetVar_DataAcq_BB WIN = $panelTitle,limits={0,inf,1},value= _NUM:0
	SetVariable SetVar_DataAcq_CN WIN = $panelTitle,limits={-8,16,1},value= _NUM:0

	CheckBox check_DatAcq_HoldEnable WIN = $panelTitle,value= 0
	CheckBox check_DatAcq_RsCompEnable WIN = $panelTitle,value= 0
	CheckBox check_DatAcq_CNEnable WIN = $panelTitle,value= 0

	Slider slider_DataAcq_ActiveHeadstage  WIN = $panelTitle,value= 0
	CheckBox check_DataAcq_AutoBias WIN = $panelTitle,value= 0

	// auto bias default: -70 plus/minus 0.5 mV @ 200 pA
	SetVariable SetVar_DataAcq_AutoBiasV      WIN = $panelTitle, value = _NUM:-70
	SetVariable SetVar_DataAcq_AutoBiasVrange WIN = $panelTitle, value = _NUM:0.5
	SetVariable setvar_DataAcq_IbiasMax       WIN = $panelTitle, value = _NUM:200

	SetVariable SetVar_DataAcq_Hold_VC WIN = $panelTitle,value= _NUM:0
	CheckBox check_DatAcq_HoldEnableVC WIN = $panelTitle,value= 0
	SetVariable SetVar_DataAcq_WCR WIN = $panelTitle,value= _NUM:0
	CheckBox check_DatAcq_WholeCellEnable WIN = $panelTitle,value= 0
	SetVariable SetVar_DataAcq_WCC  WIN = $panelTitle,value= _NUM:0
	SetVariable SetVar_DataAcq_RsCorr WIN = $panelTitle,value= _NUM:0
	SetVariable SetVar_DataAcq_RsPred WIN = $panelTitle,value= _NUM:0
	CheckBox Check_Settings_AlarmPauseAcq WIN = $panelTitle,value= 0
	CheckBox Check_Settings_AlarmAutoRepeat WIN = $panelTitle,value= 0
	CheckBox check_Settings_AmpMCCdefault WIN = $panelTitle,value= 0
	CheckBox check_Settings_AmpMIESdefault WIN = $panelTitle,value= 0
	CheckBox check_DataAcq_Amp_Chain WIN = $panelTitle,value= 0
	CheckBox check_Settings_MD WIN = $panelTitle,value= 0

	DAP_SwitchSingleMultiMode(panelTitle, 0)
	CheckBox Check_Settings_BkgTP WIN = $panelTitle,value= 1
	CheckBox Check_Settings_BackgrndDataAcq WIN = $panelTitle, value= 1

	CheckBox Check_Settings_InsertTP WIN = $panelTitle,value= 1
	CheckBox Check_DataAcq_Get_Set_ITI WIN = $panelTitle, value = 1
	CheckBox check_Settings_TP_SaveTPRecord WIN = $panelTitle, value = 0
	CheckBox check_settings_TP_show_steady WIN = $panelTitle, value = 1
	CheckBox check_settings_TP_show_peak WIN = $panelTitle, value = 1
	CheckBox check_Settings_DisablePressure WIN = $panelTitle, value = 0

	SetPopupMenuIndex(panelTitle, "Popup_Settings_Pressure_DA", 0)
	SetPopupMenuIndex(panelTitle, "Popup_Settings_Pressure_AD", 0)
	SetPopupMenuIndex(panelTitle, "Popup_Settings_Pressure_TTL", 0)
	SetSetVariable(panelTitle, "setvar_Settings_Pressure_DAgain", 2)
	SetSetVariable(panelTitle, "setvar_Settings_Pressure_ADgain", 0.5)
	SetSetVariableString(panelTitle, "SetVar_Hardware_Pressur_DA_Unit", "psi")
	SetSetVariableString(panelTitle, "SetVar_Hardware_Pressur_AD_Unit", "psi")

	EnableControl(panelTitle, "button_Hardware_P_Enable")
	DisableControl(panelTitle, "button_Hardware_P_Disable")

	return 0
End

Function DAP_WindowHook(s)
	STRUCT WMWinHookStruct &s

	string panelTitle

	switch(s.eventCode)
		case EVENT_KILL_WINDOW_HOOK:
			panelTitle = s.winName
			if(!HSU_DeviceIsUnlocked(panelTitle,silentCheck=1))
				HSU_UnlockDevice(panelTitle)
			endif
			return 1
		break
	endswitch

	return 0
End

Function DAP_CheckProc_UnivrslSrchStr(cba) : CheckBoxControl
	struct WMCheckboxAction &cba

	string panelTitle
	variable i
	string popupValue
	string SearchString
	string DAPopUpMenuName
	string IndexEndPopUpMenuName
	string FirstTwoMenuItems = "\"- none -;TestPulse;\""
	string SearchSetVarName
	string ListOfWaves

	switch(cba.eventCode)
		case 2:
			panelTitle = cba.win
			DFREF saveDFR = GetDataFolderDFR()
			SetDataFolder GetWBSvdStimSetDAPath()

			if(!cba.checked)
				SearchString = "*da*"
				sprintf popupValue, "%s+%s%s%s" FirstTwoMenuItems, "ReturnListOfAllStimSets(0,\"", SearchString,"\")"
				ListOfWaves = wavelist(searchstring,";","")

				do
					if(i > 0) // disables search inputs except for Search_DA_00
						sprintf SearchSetVarName, "Search_DA_%.2d" i
						SetVariable $SearchSetVarName WIN = $panelTitle, disable = 0

						sprintf DAPopUpMenuName, "Wave_DA_%.2d" i
						PopupMenu $DAPopUpMenuName win = $panelTitle, value = #popupValue, userData(menuExp) = ListOfWaves		// user data is accessed during indexing to determine next set
					endif
					i += 1
				while(i < NUM_DA_TTL_CHANNELS)

				i = 0
				sprintf popupValue, "\"- none -;\"+%s%s%s"  "ReturnListOfAllStimSets(0,\"", SearchString,"\")"
				do
					indexEndPopUpMenuName = GetPanelControl(i, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_INDEX_END)
					PopupMenu $IndexEndPopUpMenuName win = $panelTitle, value = #popupValue

					i += 1
				while(i < NUM_DA_TTL_CHANNELS)
			else
				controlinfo /w = $panelTitle Search_DA_00
				if(strlen(s_value) == 0)
					SearchString = "*da*"
				else
					SearchString = s_value
				endif

				sprintf popupValue, "%s+%s%s%s" FirstTwoMenuItems, "ReturnListOfAllStimSets(0,\"", SearchString,"\")"
				ListOfWaves = wavelist(searchstring,";","")
				do
					sprintf DAPopUpMenuName, "Wave_DA_%.2d" i
					PopupMenu $DAPopUpMenuName win = $panelTitle, value = #popupValue, userData(menuExp) = ListOfWaves

					if(i > 0) // disables search inputs except for Search_DA_00
						sprintf SearchSetVarName, "Search_DA_%.2d" i
						SetVariable $SearchSetVarName WIN = $panelTitle, disable = 2, value =_STR:""
					endif
					i += 1
				while(i < NUM_DA_TTL_CHANNELS)

				i = 0
				sprintf popupValue, "\"- none -;\"+%s%s%s"  "ReturnListOfAllStimSets(0,\"", SearchString,"\")"
				do
					indexEndPopUpMenuName = GetPanelControl(i, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_INDEX_END)
					PopupMenu $IndexEndPopUpMenuName win = $panelTitle, value = #popupValue
					i += 1
				while(i < NUM_DA_TTL_CHANNELS)
			endif
			Setdatafolder saveDFR
			break
	endswitch

	return 0
End

Function DAP_SetVarProc_TTLSearch(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	variable TTL_No
	string TTLPopUpMenuName
	string panelTitle, ctrlName, varstr
	string IndexEndPopUpMenuName
	string FirstMenuItem = "\"- none -;\""
	string SearchString
	string popupValue, ListOfWaves
	variable i

	switch(sva.eventCode)
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			panelTitle = sva.win
			ctrlName   = sva.ctrlName
			varstr     = sva.sval
			sscanf ctrlName, "Search_TTL_%d", TTL_No
			TTLPopUpMenuName      = GetPanelControl(TTL_No, CHANNEL_TYPE_TTL, CHANNEL_CONTROL_WAVE)
			indexEndPopUpMenuName = GetPanelControl(TTL_No, CHANNEL_TYPE_TTL, CHANNEL_CONTROL_INDEX_END)

			DFREF saveDFR = GetDataFolderDFR()
			SetDataFolder GetWBSvdStimSetTTLPath()
			controlinfo /w = $panelTitle SearchUniversal_TTL_00

			if(v_value == 1)
				controlinfo /w = $panelTitle Search_TTL_00
				If(strlen(s_value) == 0)
					sprintf SearchString, "*TTL*"
				else
					sprintf SearchString, "%s" s_value
				endif

				do
					TTLPopUpMenuName = GetPanelControl(i, CHANNEL_TYPE_TTL, CHANNEL_CONTROL_WAVE)
					sprintf popupValue, "%s+%s%s%s" FirstMenuItem, "ReturnListOfAllStimSets(1,\"", SearchString,"\")"
					listOfWaves = wavelist(searchstring,";","")
					popupmenu $TTLPopUpMenuName win = $panelTitle, value = #popupValue, userdata(MenuExp) = ListOfWaves
					controlupdate /w =  $panelTitle $TTLPopUpMenuName
					indexEndPopUpMenuName = GetPanelControl(i, CHANNEL_TYPE_TTL, CHANNEL_CONTROL_INDEX_END)
					sprintf popupValue, "%s+%s%s%s" "\"- none -;\"", "ReturnListOfAllStimSets(1,\"", SearchString,"\")"
					popupmenu $IndexEndPopUpMenuName win = $panelTitle, value = #popupValue
					controlupdate /w =  $panelTitle $IndexEndPopUpMenuName
					i += 1
				while(i < NUM_DA_TTL_CHANNELS)
			else
				if(strlen(varstr) == 0)
					sprintf SearchString, "*TTL*"
					sprintf popupValue, "%s+%s%s%s" FirstMenuItem, "ReturnListOfAllStimSets(1,\"", SearchString,"\")"
					listOfWaves = wavelist(searchstring,";","")
					popupmenu $TTLPopUpMenuName win = $panelTitle, value = #popupValue, userdata(MenuExp) = ListOfWaves
					controlupdate /w =  $panelTitle $TTLPopUpMenuName
					sprintf popupValue, "%s+%s%s%s" "\"- none -;\"", "ReturnListOfAllStimSets(1,\"", SearchString,"\")"
					popupmenu $IndexEndPopUpMenuName win = $panelTitle, value = #popupValue
					controlupdate /w =  $panelTitle $IndexEndPopUpMenuName
				else
					sprintf popupValue, "%s+%s%s%s" FirstMenuItem, "ReturnListOfAllStimSets(1,\"", varstr,"\")"
					popupmenu $TTLPopUpMenuName win = $panelTitle, value = #popupValue, userdata(MenuExp) = popupValue
					controlupdate /w =  $panelTitle $TTLPopUpMenuName
					sprintf popupValue, "%s+%s%s%s" "\"- none -;\"", "ReturnListOfAllStimSets(1,\"", varStr,"\")"
					popupmenu $IndexEndPopUpMenuName win = $panelTitle, value = #popupValue
					controlupdate /w =  $panelTitle $IndexEndPopUpMenuName
				endif
			endif
			SetDataFolder saveDFR
			break
		endswitch
	return 0
End

Function DAP_CheckProc_UnivrslSrchTTL(cba) : CheckBoxControl
	struct WMCheckboxAction &cba

	string panelTitle
	string SearchString
	string TTLPopUpMenuName
	string IndexEndPopUpMenuName
	string FirstTwoMenuItems = "\"- none -;\""
	string SearchSetVarName
	string ListOfWaves, popupValue
	variable i

	switch(cba.eventCode)
		case 2:
			panelTitle = cba.win

			DFREF saveDFR = GetDataFolderDFR()// creates a data folder reference that is later used to access the folder
			SetDataFolder GetWBSvdStimSetTTLPath()

			if(!cba.checked)
				SearchString = "*TTL*"
				sprintf popupValue, "%s+%s%s%s" FirstTwoMenuItems, "ReturnListOfAllStimSets(1,\"", SearchString,"\")"
				ListOfWaves = wavelist(searchstring,";","")

				do
					if(i > 0) // disables search inputs except for Search_TTL_00
						sprintf SearchSetVarName, "Search_TTL_%.2d" i
						SetVariable $SearchSetVarName WIN = $panelTitle, disable = 0

						TTLPopUpMenuName = GetPanelControl(i, CHANNEL_TYPE_TTL, CHANNEL_CONTROL_WAVE)
						PopupMenu $TTLPopUpMenuName win = $panelTitle, value = #popupValue, userData(menuExp) = ListOfWaves
					endif
					i += 1
				while(i < NUM_DA_TTL_CHANNELS)

				i = 0
				sprintf popupValue, "\"- none -;\"+%s%s%s"  "ReturnListOfAllStimSets(1,\"", SearchString,"\")"
				do
					indexEndPopUpMenuName = GetPanelControl(i, CHANNEL_TYPE_TTL, CHANNEL_CONTROL_INDEX_END)
					PopupMenu $IndexEndPopUpMenuName win = $panelTitle, value = #popupValue

					i += 1
				while(i < NUM_DA_TTL_CHANNELS)
			else
				controlinfo /w = $panelTitle Search_TTL_00
				if(strlen(s_value) == 0)
					SearchString = "*TTL*"
				else
					SearchString = s_value
				endif

				sprintf popupValue, "%s+%s%s%s" FirstTwoMenuItems, "ReturnListOfAllStimSets(1,\"", SearchString,"\")"
				ListOfWaves = wavelist(searchstring,";","")
				do
					TTLPopUpMenuName = GetPanelControl(i, CHANNEL_TYPE_TTL, CHANNEL_CONTROL_WAVE)
					PopupMenu $TTLPopUpMenuName win = $panelTitle, value = #popupValue, userData(menuExp) = ListOfWaves
					if(i > 0) // disables search inputs except for Search_TTL_00
						sprintf SearchSetVarName, "Search_TTL_%.2d" i
						SetVariable $SearchSetVarName WIN = $panelTitle, disable = 2, value =_STR:""
					endif
					i += 1
				while(i < NUM_DA_TTL_CHANNELS)

				i = 0
				sprintf popupValue, "\"- none -;\"+%s%s%s"  "ReturnListOfAllStimSets(1,\"", SearchString,"\")"
				do
					indexEndPopUpMenuName = GetPanelControl(i, CHANNEL_TYPE_TTL, CHANNEL_CONTROL_INDEX_END)
					PopupMenu $IndexEndPopUpMenuName win = $panelTitle, value = #popupValue
					i += 1
				while(i < NUM_DA_TTL_CHANNELS)
			endif
			SetDatafolder saveDFR
			break
	endswitch

	return 0
End

/// @returns 1 if the device is a "ITC1600"
Function DAP_DeviceIsYokeable(panelTitle)
  string panelTitle

  string deviceType, deviceNumber
  if(!ParseDeviceString(panelTitle, deviceType, deviceNumber))
	deviceType = HSU_GetDeviceType(panelTitle)
  endif

  return !cmpstr(deviceType, "ITC1600")
End

Function DAP_DeviceIsFollower(panelTitle)
	string panelTitle

	ControlInfo/W=$panelTitle setvar_Hardware_Status
	ASSERT(V_flag != 0, "Non-existing control or window")

	return cmpstr(S_value,FOLLOWER) == 0
End

Function DAP_DeviceCanLead(panelTitle)
	string panelTitle

	return !cmpstr(panelTitle, "ITC1600_Dev_0")
End

Function DAP_DeviceIsLeader(panelTitle)
	string panelTitle

	ControlInfo/W=$panelTitle setvar_Hardware_Status
	ASSERT(V_flag != 0, "Non-existing control or window")

	return cmpstr(S_value,LEADER) == 0
End

Function DAP_DeviceHasFollower(panelTitle)
	string panelTitle

	SVAR/Z listOfFollowerDevices = $GetFollowerList(doNotCreateSVAR=1)

	return DAP_DeviceIsLeader(panelTitle) && SVAR_Exists(listOfFollowerDevices) && ItemsInList(listOfFollowerDevices) > 0
End

/// @brief Updates the yoking controls on all locked/unlocked panels
Function DAP_UpdateAllYokeControls()

	string   ListOfLockedITC1600    = GetListOfLockedITC1600Devices()
	variable ListOfLockedITC1600Num = ItemsInList(ListOfLockedITC1600)
	string   ListOfLockedITC        = GetListOfLockedDevices()
	variable ListOfLockedITCNum     = ItemsInList(ListOfLockedITC1600)

	string panelTitle
	variable i
	for(i=0; i<ListOfLockedITCNum; i+=1)
		panelTitle = StringFromList(i,ListOfLockedITC)

		// don't touch the current leader
		if(DAP_DeviceIsLeader(panelTitle))
			continue
		endif

		DisableListOfControls(panelTitle,YOKE_LIST_OF_CONTROLS)
		DAP_UpdateYokeControls(panelTitle)

		if(ListOfLockedITC1600Num >= 2 && DAP_DeviceCanLead(panelTitle))
			// ensures yoking controls are only enabled on the ITC1600_Dev_0
			// a requirement of the ITC XOP
			EnableControl(panelTitle,"button_Hardware_Lead1600")
		endif
	endfor

	string   ListOfUnlockedITC     = GetListOfUnlockedDevices()
	variable ListOfUnlockedITCNum  = ItemsInList(ListOfUnlockedITC)

	for(i=0; i<ListOfUnLockedITCNum; i+=1)
		panelTitle = StringFromList(i,ListOfUnLockedITC)
		DisableListOfControls(panelTitle,YOKE_LIST_OF_CONTROLS)
	endfor
End

Function/S DAP_GUIListOfYokedDevices()

	SVAR/Z listOfFollowerDevices = $GetFollowerList(doNotCreateSVAR=1)
	if(SVAR_Exists(listOfFollowerDevices) && cmpstr(listOfFollowerDevices, "") != 0)
		return listOfFollowerDevices
	endif

	return "No Yoked Devices"
End

Function DAP_UpdateYokeControls(panelTitle)
	string panelTitle

	if(GetTabID(panelTitle, "ADC") != HARDWARE_TAB_NUM)
		return NaN
	endif

	if(!DAP_DeviceIsYokeable(panelTitle))
		HideListOfControls(panelTitle,YOKE_LIST_OF_CONTROLS)
		SetVariable setvar_Hardware_YokeList win = $panelTitle, value = _STR:"Device is not yokeable"
	elseif(DAP_DeviceIsFollower(panelTitle))
		HideListOfControls(panelTitle,YOKE_LIST_OF_CONTROLS)
	else
		ShowListOfControls(panelTitle,YOKE_LIST_OF_CONTROLS)
		if(DAP_DeviceCanLead(panelTitle))
			TitleBox title_hardware_1600inst win = $panelTitle, title = "Designate the status of the ITC1600 assigned to this device"
		else
			TitleBox title_hardware_1600inst win = $panelTitle, title = "To yoke devices go to panel: " + ITC1600_FIRST_DEVICE
		endif
		SetVariable setvar_Hardware_YokeList win = $panelTitle, value = _STR:DAP_GUIListOfYokedDevices()
	endif
End

/// @brief Called by ACL tab control after the tab is updated.
/// see line 257 of ACL_TabUtilities.ipf
Function DAP_TabControlFinalHook(tca)
	STRUCT WMTabControlAction &tca

	if(HSU_DeviceIsUnLocked(tca.win,silentCheck=1))
		print "Please lock the panel to a DAC in the Hardware tab"
		return 0
	endif

	DAP_UpdateYokeControls(tca.win)

	if(tca.tab == DATA_ACQU_TAB_NUM)
		DAP_UpdateITIAcrossSets(tca.win)
		DAP_UpdateSweepSetVariables(tca.win)
		DAP_UpdateITCSampIntDisplay(tca.win)
	endif

	return 0
End

Function DAP_SetVarProc_DASearch(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	variable DA_No
	string DAPopUpMenuName
	string IndexEndPopUpMenuName
	string FirstTwoMenuItems = "\"- none -;TestPulse;\""
	string SearchString
	string popupValue, ListOfWaves
	string panelTitle, ctrlName, varstr
	variable i

	switch(sva.eventCode)
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update

			panelTitle = sva.win
			ctrlName   = sva.ctrlName
			varstr     = sva.sval

			sscanf ctrlName, "Search_DA_%d", DA_No
			DAPopUpMenuName       = GetPanelControl(DA_No, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE)
			IndexEndPopUpMenuName = GetPanelControl(DA_No, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_INDEX_END)

			DFREF saveDFR = GetDataFolderDFR()
			SetDataFolder GetWBSvdStimSetDAPath()
			controlinfo /w = $panelTitle SearchUniversal_DA_00

			if(v_value == 1) // apply search string to all channels
				controlinfo /w = $panelTitle Search_DA_00
				If(strlen(s_value) == 0)
					sprintf SearchString, "*DA*"
				else
					sprintf SearchString, "%s" s_value
				endif

				do
					sprintf DAPopUpMenuName, "Wave_DA_%.2d" i
					sprintf popupValue, "%s+%s%s%s" FirstTwoMenuItems, "ReturnListOfAllStimSets(0,\"", SearchString,"\")"
					listOfWaves = wavelist(searchstring,";","")
					popupmenu $DAPopUpMenuName win = $panelTitle, value = #popupValue, userdata(MenuExp) = ListOfWaves
					controlupdate /w =  $panelTitle $DAPopUpMenuName
					IndexEndPopUpMenuName = GetPanelControl(i, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_INDEX_END)
					sprintf popupValue, "%s+%s%s%s" "\"- none -;\"", "ReturnListOfAllStimSets(0,\"", SearchString,"\")"
					popupmenu $IndexEndPopUpMenuName win = $panelTitle, value = #popupValue
					controlupdate /w =  $panelTitle $IndexEndPopUpMenuName
					i += 1
				while(i < NUM_DA_TTL_CHANNELS)

			else // apply search string to associated channel
				if(strlen(varstr) == 0)
					sprintf SearchString, "*DA*"
					sprintf popupValue, "%s+%s%s%s" FirstTwoMenuItems, "ReturnListOfAllStimSets(0,\"", SearchString,"\")"
					listOfWaves = wavelist(searchstring,";","")
					popupmenu $DAPopUpMenuName win = $panelTitle, value = #popupValue, userdata(MenuExp) = ListOfWaves
					controlupdate /w =  $panelTitle $DAPopUpMenuName
					sprintf popupValue, "%s+%s%s%s" "\"- none -;\"", "ReturnListOfAllStimSets(0,\"", SearchString,"\")"
					popupmenu $IndexEndPopUpMenuName win = $panelTitle, value = #popupValue
					controlupdate /w =  $panelTitle $IndexEndPopUpMenuName
				else
					sprintf popupValue, "%s+%s%s%s" FirstTwoMenuItems, "ReturnListOfAllStimSets(0,\"", varstr,"\")"
					searchString = varStr
					listOfWaves = wavelist(searchstring,";","")
					popupmenu $DAPopUpMenuName win = $panelTitle, value = #popupValue, userdata(MenuExp) = listOfWaves
					controlupdate /w =  $panelTitle $DAPopUpMenuName
					sprintf popupValue, "%s+%s%s%s" "\"- none -;\"", "ReturnListOfAllStimSets(0,\"", varStr,"\")"
					popupmenu $IndexEndPopUpMenuName win = $panelTitle, value = #popupValue
					controlupdate /w =  $panelTitle $IndexEndPopUpMenuName
				endif
			endif
			SetDataFolder saveDFR
			break
	endswitch

	return 0
End

Function DAP_DAorTTLCheckProc(cba) : CheckBoxControl
	struct WMCheckboxAction &cba

	string panelTitle

	switch(cba.eventCode)
		case 2:
			paneltitle = cba.win
			DAP_AdaptAssocHeadstageState(panelTitle, cba.ctrlName)
			DAP_UpdateITIAcrossSets(panelTitle)
			DAP_UpdateSweepSetVariables(panelTitle)
			break
	endswitch
End

Function DAP_CheckProc_AD(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	switch(cba.eventCode)
		case 2: // mouse up
			DAP_AdaptAssocHeadstageState(cba.win, cba.ctrlName)
			break
	endswitch

	return 0
End

/// @brief Adapt the state of the associated headstage on DA/AD channel change
///
static Function DAP_AdaptAssocHeadstageState(panelTitle, checkboxCtrl)
	string panelTitle
	string checkboxCtrl

	string headStageCheckBox
	variable headstage, idx, channelType, controlType

	DAP_ParsePanelControl(checkboxCtrl, idx, channelType, controlType)
	ASSERT(CHANNEL_CONTROL_CHECK == controlType, "Not a valid control type")

	if(channelType == CHANNEL_TYPE_DAC)
		headStage = AFH_GetHeadstageFromDAC(panelTitle, idx)
	elseif(channelType == CHANNEL_TYPE_ADC)
		headStage = AFH_GetHeadstageFromADC(panelTitle, idx)
	elseif(channelType == CHANNEL_TYPE_TTL)
		// nothing to do
		return NaN
	endif

	// headStage can be NaN for non associated DA/AD channels
	if(!IsFinite(headStage))
		return NaN
	endif

	headStageCheckBox = GetPanelControl(headstage, CHANNEL_TYPE_HEADSTAGE, CHANNEL_CONTROL_CHECK)
	PGC_SetAndActivateControl(panelTitle, headStageCheckBox, val=!GetCheckBoxState(panelTitle, headStageCheckBox))
End

/// @brief One time initialization before data acquisition
Function DAP_OneTimeCallBeforeDAQ(panelTitle)
	string panelTitle

	variable numHS, i

	NVAR/Z/SDFR=GetDevicePath(panelTitle) count
	if(NVAR_Exists(count))
		KillVariables count
	endif

	if(GetCheckBoxState(panelTitle, "Check_DataAcq_Indexing"))
		IDX_StoreStartFinishForIndexing(panelTitle)
	endif

	if(GetCheckboxState(panelTitle, "check_Settings_Overwrite"))
		DM_DeleteDataWaves(panelTitle)
	endif

	// disable the clamp mode checkboxes of all active headstages
	WAVE statusHS = DC_ControlStatusWave(panelTitle, CHANNEL_TYPE_HEADSTAGE)

	numHS = DimSize(statusHS, ROWS)
	for(i = 0; i < numHS; i += 1)
		if(!statusHS[i])
			continue
		endif

		EnableControl(panelTitle, GetPanelControl(i, CHANNEL_TYPE_HEADSTAGE, CHANNEL_CONTROL_CHECK))
		DisableControl(panelTitle, DAP_GetClampModeControl(I_CLAMP_MODE, i))
		DisableControl(panelTitle, DAP_GetClampModeControl(V_CLAMP_MODE, i))
		DisableControl(panelTitle, DAP_GetClampModeControl(I_EQUAL_ZERO_MODE, i))
	endfor

	NVAR DataAcqState = $GetDataAcqState(panelTitle)
	DataAcqState = 1
	DAP_ToggleAcquisitionButton(panelTitle, DATA_ACQ_BUTTON_TO_STOP)
	
	// turn off active pressure control modes
	if(getCheckboxState(panelTitle, "check_Settings_DisablePressure", allowMissingControl = 1))
		P_SetAllHStoAtmospheric(panelTitle)
	endif
End

/// @brief Enable all controls which were disabled before DAQ by #DAP_OneTimeCallBeforeDAQ
Function DAP_ResetGUIAfterDAQ(panelTitle)
	string panelTitle

	variable i

	for(i = 0; i < NUM_HEADSTAGES; i += 1)
		EnableControl(panelTitle, GetPanelControl(i, CHANNEL_TYPE_HEADSTAGE, CHANNEL_CONTROL_CHECK))
		EnableControl(panelTitle, DAP_GetClampModeControl(I_CLAMP_MODE, i))
		EnableControl(panelTitle, DAP_GetClampModeControl(V_CLAMP_MODE, i))
		EnableControl(panelTitle, DAP_GetClampModeControl(I_EQUAL_ZERO_MODE, i))
	endfor

	DAP_ToggleAcquisitionButton(panelTitle, DATA_ACQ_BUTTON_TO_DAQ)
End

/// @brief One time cleaning up after data acquisition
Function DAP_OneTimeCallAfterDAQ(panelTitle)
	string panelTitle

	DAP_ResetGUIAfterDAQ(panelTitle)

	DM_CallAnalysisFunctions(panelTitle, POST_SET_EVENT)
	DM_CallAnalysisFunctions(panelTitle, POST_DAQ_EVENT)

	NVAR DataAcqState = $GetDataAcqState(panelTitle)
	DataAcqState = 0

	NVAR count = $GetCount(panelTitle)
	KillVariables count

	// restore the selected sets before DAQ
	if(GetCheckBoxState(panelTitle, "Check_DataAcq_Indexing"))
		IDX_ResetStartFinishForIndexing(panelTitle)
	endif

	DAP_UpdateSweepSetVariables(panelTitle)

	if(!GetCheckBoxState(panelTitle, "check_Settings_TPAfterDAQ", allowMissingControl=1))
		return NaN
	endif

	// 0: holds all calling functions
	// 1: is the current function
	ASSERT(ItemsInList(ListMatch(GetRTStackInfo(0), GetRTStackInfo(1))) == 1 , "Recursion detected, aborting")

	if(GetCheckBoxState(panelTitle, "check_Settings_MD"))
		TP_StartTestPulseMultiDevice(panelTitle)
	else
		TP_StartTestPulseSingleDevice(panelTitle)
	endif
End

Function DAP_ButtonProc_AcquireData(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	string panelTitle

	switch(ba.eventcode)
		case EVENT_MOUSE_UP:
			panelTitle = ba.win

			AbortOnValue HSU_DeviceIsUnlocked(panelTitle), 1

			if(GetCheckBoxState(panelTitle, "check_Settings_MD"))
				ITC_StartDAQMultiDevice(panelTitle)
			else
				ITC_StartDAQSingleDevice(panelTitle)
			endif
		break
	endswitch

	return 0
End

Function DAP_CheckProc_IndexingState(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	string panelTitle

	switch(cba.eventCode)
		case EVENT_MOUSE_UP:

		panelTitle = cba.win
		// makes sure user data for controls is up to date
		WBP_UpdateITCPanelPopUps(panelTitle=panelTitle)
		DAP_UpdateSweepSetVariables(panelTitle)
		DAP_UpdateITIAcrossSets(panelTitle)

		if(cmpstr(cba.ctrlname, "Check_DataAcq1_IndexingLocked") == 0)
			ToggleCheckBoxes(panelTitle, "Check_DataAcq1_IndexingLocked", "check_Settings_SetOption_5", cba.checked)
			EqualizeCheckBoxes(panelTitle, "Check_DataAcq1_IndexingLocked", "check_Settings_Option_3", cba.checked)
		endif

		break
	endswitch

	return 0
End

Function DAP_CheckProc_ShowScopeWin(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	string panelTitle

	switch(cba.eventCode)
		case 2: // mouse up
			panelTitle = cba.win

			if(cba.checked)
				SCOPE_OpenScopeWindow(panelTitle)
			else
				SCOPE_KillScopeWindowIfRequest(panelTitle)
			endif

			break
	endswitch

	return 0
End

Function DAP_TurnOffAllTTLs(panelTitle)
	string panelTitle

	variable i
	string ctrl

	for(i = 0; i < NUM_DA_TTL_CHANNELS; i += 1)
		ctrl = GetPanelControl(i, CHANNEL_TYPE_TTL, CHANNEL_CONTROL_CHECK)
		SetCheckBoxState(panelTitle, ctrl, CHECKBOX_UNSELECTED)
	endfor
End

Function DAP_ButtonProc_TTLOff(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch(ba.eventcode)
		case 2:
			DAP_TurnOffAllTTLs(ba.win)
			break
	endswitch

	return 0
End

Function DAP_TurnOffAllDACs(panelTitle)
	string panelTitle

	variable i
	string ctrl

	for(i = 0; i < NUM_DA_TTL_CHANNELS; i += 1)
		ctrl = GetPanelControl(i, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_CHECK)
		SetCheckBoxState(panelTitle, ctrl, CHECKBOX_UNSELECTED)
	endfor
End

Function DAP_ButtonProc_DAOff(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch(ba.eventcode)
		case 2:
			DAP_TurnOffAllDACs(ba.win)
			break
	endswitch

	return 0
End

Function DAP_TurnOffAllADCs(panelTitle)
	string panelTitle

	variable i
	string ctrl

	for(i = 0; i < NUM_AD_CHANNELS;i += 1)
		ctrl = GetPanelControl(i, CHANNEL_TYPE_ADC, CHANNEL_CONTROL_CHECK)
		SetCheckBoxState(panelTitle, ctrl, CHECKBOX_UNSELECTED)
	endfor
End

Function DAP_ButtonProc_ADOff(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch(ba.eventcode)
		case 2:
			DAP_TurnOffAllADCs(ba.win)
			break
	endswitch

	return 0
End

static Function DAP_TurnOffAllHeadstages(panelTitle)
	string panelTitle

	variable i
	string ctrl

	if(HSU_DeviceIsUnLocked(panelTitle, silentCheck=1))
		return NaN
	endif

	for(i = 0; i < NUM_HEADSTAGES; i += 1)
		ctrl = GetPanelControl(i, CHANNEL_TYPE_HEADSTAGE, CHANNEL_CONTROL_CHECK)
		PGC_SetAndActivateControl(panelTitle, ctrl, val=CHECKBOX_UNSELECTED)
	endfor
End

Function DAP_ButtonProc_AllChanOff(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	string panelTitle

	switch(ba.eventcode)
		case EVENT_MOUSE_UP:
			panelTitle = ba.win
			DAP_TurnOffAllHeadstages(panelTitle)
			DAP_TurnOffAllDACs(panelTitle)
			DAP_TurnOffAllADCs(panelTitle)
			DAP_TurnOffAllTTLs(panelTitle)
			break
	endswitch
End

Function DAP_UpdateITIAcrossSets(panelTitle)
	string panelTitle

	variable numActiveDAChannels, maxITI

	if(DAP_DeviceIsFollower(panelTitle) && DAP_DeviceIsLeader(ITC1600_FIRST_DEVICE))
		DAP_UpdateITIAcrossSets(ITC1600_FIRST_DEVICE)
		return 0
	endif

	maxITI = IDX_LongestITI(panelTitle, numActiveDAChannels)
	DEBUGPRINT("Maximum ITI across sets=", var=maxITI)

	if(GetCheckBoxState(panelTitle, "Check_DataAcq_Get_Set_ITI", allowMissingControl=1))
		SetSetVariable(panelTitle, "SetVar_DataAcq_ITI", maxITI)
	elseif(maxITI == 0 && numActiveDAChannels > 0)
		ControlInfo/W=$panelTitle Check_DataAcq_Get_Set_ITI
		if(V_flag != 0)
			SetCheckBoxState(panelTitle, "Check_DataAcq_Get_Set_ITI", CHECKBOX_SELECTED)
		endif
	endif

	if(DAP_DeviceIsLeader(panelTitle))
		DAP_SyncGuiFromLeaderToFollower(panelTitle)
	endif
End

/// @brief Procedure for DA/TTL popupmenus including indexing wave popupmenus
Function DAP_PopMenuChkProc_StimSetList(pa) : PopupMenuControl
	STRUCT WMPopupAction& pa

	string stimSetCtrl, list
	string panelTitle, stimSet

	switch(pa.eventCode)
		case 2:
			stimSetCtrl = pa.ctrlName
			panelTitle  = pa.win
			stimSet     = pa.popStr

			// check if this is a third party stim set which
			// is not yet reflected in the "MenuExp" user data
			list = GetUserData(panelTitle, stimSetCtrl, "MenuExp")
			if(FindListItem(stimSet, list) == -1)
				WBP_UpdateITCPanelPopUps()
			endif

			DAP_UpdateITIAcrossSets(panelTitle)
			DAP_UpdateSweepSetVariables(panelTitle)
			break
		endswitch
	return 0
End

Function DAP_SetVarProc_NextSweepLimit(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	switch( sva.eventCode )
		case 1:
		case 2:
		case 3:
			DAP_UpdateSweepLimitsAndDisplay(sva.win)
			break
	endswitch

	return 0
End

static Function DAP_UpdateSweepLimitsAndDisplay(panelTitle)
	string panelTitle

	string panelList
	variable sweep, nextSweep, maxNextSweep, numPanels, i

	panelList = panelTitle

	if(DAP_DeviceIsLeader(panelTitle))

		SVAR/Z listOfFollowerDevices = $GetFollowerList(doNotCreateSVAR=1)
		if(SVAR_Exists(listOfFollowerDevices) && strlen(listOfFollowerDevices) > 0)
			panelList = AddListItem(panelList, listOfFollowerDevices, ";", 0)
		endif
		sweep = GetSetVariable(panelTitle, "SetVar_Sweep")
	else
		sweep = NaN
	endif

	// query maximum next sweep
	maxNextSweep = 0
	numPanels = ItemsInList(panelList)
	for(i = 0; i < numPanels; i += 1)
		panelTitle = StringFromList(i, panelList)

		if(IsFinite(sweep) && DAP_DeviceIsFollower(panelTitle))
			SetSetVariable(panelTitle, "SetVar_Sweep", sweep)
		endif

		nextSweep = GetSetVariable(panelTitle, "SetVar_Sweep")
		maxNextSweep = max(maxNextSweep, nextSweep)
	endfor

	for(i = 0; i < numPanels; i += 1)
		panelTitle = StringFromList(i, panelList)

		if(DAP_DeviceIsFollower(panelTitle))
			SetVariable SetVar_Sweep win = $panelTitle, noEdit=1, limits = {0, maxNextSweep, 0}
		else
			SetVariable SetVar_Sweep win = $panelTitle, noEdit=0, limits = {0, maxNextSweep, 1}
		endif
	endfor
End

Function DAP_UpdateITCSampIntDisplay(panelTitle)
	string panelTitle

	SetValDisplaySingleVariable(panelTitle, "ValDisp_DataAcq_SamplingInt", DAP_GetITCSampInt(panelTitle, DATA_ACQUISITION_MODE))
End

/// @brief Return the ITC sampling interval with taking the mode and
/// the multiplier into account
Function DAP_GetITCSampInt(panelTitle, dataAcqOrTP)
	string panelTitle
	variable dataAcqOrTP

	variable multiplier

	if(dataAcqOrTP == DATA_ACQUISITION_MODE)
		multiplier = str2num(GetPopupMenuString(panelTitle, "Popup_Settings_SampIntMult"))
	elseif(dataAcqOrTP == TEST_PULSE_MODE)
		multiplier = 1
	else
		ASSERT(0, "unknown mode")
	endif

	return SI_CalculateMinSampInterval(panelTitle, dataAcqOrTP) * multiplier
End

/// @todo display correct values for yoked devices using #RA_GetTotalNumberOfSets
Function DAP_UpdateSweepSetVariables(panelTitle)
	string panelTitle

	variable numSetRepeats

	if(GetCheckBoxState(panelTitle, "Check_DataAcq1_RepeatAcq"))
		numSetRepeats = GetSetVariable(panelTitle, "SetVar_DataAcq_SetRepeats")

		if(GetCheckBoxState(panelTitle, "Check_DataAcq1_IndexingLocked"))
			numSetRepeats *= IDX_MaxSweepsLockedIndexing(panelTitle)
		else
			numSetRepeats *= IDX_MaxNoOfSweeps(panelTitle, 0)
		endif
	else
		numSetRepeats = 1
	endif

	SetValDisplaySingleVariable(panelTitle, "valdisp_DataAcq_TrialsCountdown", numSetRepeats)
	SetValDisplaySingleVariable(panelTitle, "valdisp_DataAcq_SweepsInSet", numSetRepeats)
	SetValDisplaySingleVariable(panelTitle, "valdisp_DataAcq_SweepsActiveSet", IDX_MaxNoOfSweeps(panelTitle, 1))
End

Function DAP_SetVarProc_TotSweepCount(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	string panelTitle

	switch(sva.eventCode)
		case 1:
		case 2:
		case 3:
			panelTitle = sva.win
			DAP_UpdateSweepSetVariables(panelTitle)
			DAP_SyncGuiFromLeaderToFollower(panelTitle)
			break
	endswitch

	return 0
End

Function DAP_PopMenuProc_DevTypeChk(s) : PopupMenuControl
	struct WMPopupAction& s

	if(s.eventCode != EVENT_MOUSE_UP)
		return 0
	endif

	HSU_IsDeviceTypeConnected(s.win)
	DAP_UpdateYokeControls(s.win)
End

Function DAP_ButtonCtrlFindConnectedAmps(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch(ba.eventcode)
		case EVENT_MOUSE_UP:
			AI_FindConnectedAmps(ba.win)
			break
	endswitch
End

Function DAP_CheckProc_GetSet_ITI(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	switch(cba.eventCode)
		case EVENT_MOUSE_UP:
			if(cba.checked)
				DAP_UpdateITIAcrossSets(cba.win)
			else
				DAP_SyncGuiFromLeaderToFollower(cba.win)
			endif

			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

/// @brief Return a nicely layouted list of amplifier channels
Function/S DAP_GetNiceAmplifierChannelList()

	variable i, numRows
	string str
	string list = NONE
	string panelTitle = GetCurrentWindow()

	Wave/Z/SDFR=GetAmplifierFolder() W_TelegraphServers

	numRows = WaveExists(W_TelegraphServers) ? DimSize(W_TelegraphServers, ROWS) : 0
	if(!numRows)
		print "Activate Multiclamp Commander software to populate list of available amplifiers"
		list = AddListItem("\\M1(MC not available;", list, ";", inf)
		return list
	endif

	for(i=0; i < numRows; i+=1)
		sprintf str, "AmpNo %d Chan %d", W_TelegraphServers[i][0], W_TelegraphServers[i][1]
		list = AddListItem(str, list, ";", inf)
	endfor

	return list
End

Function DAP_PopMenuProc_Headstage(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	string panelTitle

	switch(pa.eventCode)
		case 2: // mouse up
			panelTitle = pa.win
			if(HSU_DeviceIsUnlocked(panelTitle, silentCheck=1))
				break
			endif

			HSU_UpdateChanAmpAssignPanel(panelTitle)
			P_UpdatePressureControls(panelTitle, pa.popNum - 1)

			if(GetCheckBoxState(panelTitle, "Check_Hardware_UseManip"))
				M_SetManipulatorAssocControls(panelTitle, pa.popNum - 1)
			endif
			break
	endswitch

	return 0
End

Function DAP_PopMenuProc_CAA(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	string panelTitle

	switch(pa.eventCode)
		case 2: // mouse up
			panelTitle = pa.win
			if(HSU_DeviceIsUnlocked(panelTitle, silentCheck=1))
				break
			endif

			HSU_UpdateChanAmpAssignStorWv(panelTitle)
			P_UpdatePressureDataStorageWv(panelTitle)

			if(GetCheckBoxState(panelTitle, "Check_Hardware_UseManip"))
				M_SetManipulatorAssociation(panelTitle)
			endif
			break
	endswitch

	return 0
End

Function DAP_SetVarProc_CAA(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	string panelTitle

	switch(sva.eventCode)
		case 1: // mouse up
		case 2: // Enter key
			panelTitle = sva.win
			if(HSU_DeviceIsUnlocked(panelTitle, silentCheck=1))
				break
			endif

			HSU_UpdateChanAmpAssignStorWv(panelTitle)
			P_UpdatePressureDataStorageWv(panelTitle)
			break
	endswitch

	return 0
End

Function DAP_ButtonProc_ClearChanCon(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	string panelTitle
	variable headStage

	switch(ba.eventCode)
		case 2: // mouse up
			panelTitle = ba.win
			WAVE ChanAmpAssign = GetChanAmpAssign(panelTitle)

			headStage = str2num(GetPopupMenuString(panelTitle,"Popup_Settings_HeadStage"))

			// set all DA/AD channels for both clamp modes to an invalid channel number
			ChanAmpAssign[0, 6;2][headStage] = NaN
			ChanAmpAssign[8, 10][headStage]  = NaN

			HSU_UpdateChanAmpAssignPanel(panelTitle)
			break
	endswitch

	return 0
End

/// @brief Check the settings across yoked devices
static Function DAP_CheckSettingsAcrossYoked(listOfFollowerDevices, mode)
	string listOfFollowerDevices
	variable mode

	string panelTitle
	variable leaderRepeatAcq, leaderIndexing, leaderITI, leaderRepeatSets, leaderdDAQDelay
	variable leaderdDAQ
	variable i, numEntries
	string leaderSampInt

	if(!WindowExists("ArduinoSeq_Panel"))
		printf "(%s) The Arduino sequencer panel does not exist. Please open it and load the default sequence.\r", ITC1600_FIRST_DEVICE
		return 1
	endif

	if(IsControlDisabled("ArduinoSeq_Panel", "ArduinoStartButton"))
		printf "(%s) The Arduino sequencer panel has a disabled \"Start\" button. Is it connected? Have you loaded the default sequence?\r", ITC1600_FIRST_DEVICE
		return 1
	endif

	if(mode == TEST_PULSE_MODE)
		return 0
	endif

	leaderdDAQ       = GetCheckBoxState(ITC1600_FIRST_DEVICE, "Check_DataAcq1_DistribDaq")
	leaderRepeatAcq  = GetCheckBoxState(ITC1600_FIRST_DEVICE, "Check_DataAcq1_RepeatAcq")
	leaderIndexing   = GetCheckBoxState(ITC1600_FIRST_DEVICE, "Check_DataAcq_Indexing")
	leaderITI        = GetSetVariable(ITC1600_FIRST_DEVICE, "SetVar_DataAcq_ITI")
	leaderRepeatSets = GetSetVariable(ITC1600_FIRST_DEVICE, "SetVar_DataAcq_SetRepeats")
	leaderdDAQDelay  = GetSetVariable(ITC1600_FIRST_DEVICE, "SetVar_DataAcq_dDAQDelay")
	leaderSampInt    = GetValDisplayAsString(ITC1600_FIRST_DEVICE, "ValDisp_DataAcq_SamplingInt")

	numEntries = ItemsInList(listOfFollowerDevices)
	for(i = 0; i < numEntries; i += 1)
		panelTitle = StringFromList(i, listOfFollowerDevices)
		if(leaderRepeatAcq != GetCheckBoxState(panelTitle, "Check_DataAcq1_RepeatAcq"))
			printf "(%s) Repeat acquisition setting does not match leader panel\r", panelTitle
			return 1
		endif
		if(leaderIndexing != GetCheckBoxState(panelTitle, "Check_DataAcq_Indexing"))
			printf "(%s) Indexing setting does not match leader panel\r", panelTitle
			return 1
		endif
		if(leaderdDAQ != GetCheckBoxState(panelTitle, "Check_DataAcq1_DistribDaq"))
			printf "(%s) Distributed acquisition setting does not match leader panel\r", panelTitle
			return 1
		endif
		if(leaderITI != GetSetVariable(panelTitle, "SetVar_DataAcq_ITI"))
			printf "(%s) ITI does not match leader panel\r", panelTitle
			return 1
		endif
		if(leaderRepeatSets != GetSetVariable(panelTitle, "SetVar_DataAcq_SetRepeats"))
			printf "(%s) Repeat sets does not match leader panel\r", panelTitle
			return 1
		endif
		if(leaderdDAQDelay != GetSetVariable(panelTitle, "SetVar_DataAcq_dDAQDelay"))
			printf "(%s) Distributed acquisition delay does not match leader panel\r", panelTitle
			return 1
		endif
		if(CmpStr(leaderSampInt,GetValDisplayAsString(panelTitle, "ValDisp_DataAcq_SamplingInt")))
			// this is no fatal error, we just inform the user
			printf "(%s) Sampling interval does not match leader panel\r", panelTitle
			ValDisplay ValDisp_DataAcq_SamplingInt win=$panelTitle, valueBackColor=(0,65280,33024)
		else
			ValDisplay ValDisp_DataAcq_SamplingInt win=$panelTitle, valueBackColor=(0,0,0)
		endif
	endfor

	return 0
End

/// @brief Check if all settings are valid to send a test pulse or acquire data
///
/// For invalid settings an informative message is printed into the history area.
/// @param panelTitle device
/// @param mode       One of @ref DataAcqModes
/// @return 0 for valid settings, 1 for invalid settings
Function DAP_CheckSettings(panelTitle, mode)
	string panelTitle
	variable mode

	variable numDACs, numADCs, numHS, numEntries, i, indexingEnabled, clampMode
	string ctrl, endWave, ttlWave, dacWave, refDacWave
	string list, msg

	if(isEmpty(panelTitle))
		print "Invalid empty string for panelTitle, can not proceed"
		return 1
	endif

	ASSERT(mode == DATA_ACQUISITION_MODE || mode == TEST_PULSE_MODE, "Invalid mode")

	if(mode == DATA_ACQUISITION_MODE && DM_CallAnalysisFunctions(panelTitle, PRE_DAQ_EVENT))
		printf "%s: Pre DAQ analysis function requested an abort\r", panelTitle
		return 1
	endif

	if(GetFreeMemory() < FREE_MEMORY_LOWER_LIMIT)
		DFREF dfr = GetMiesPath()
		NVAR/Z/SDFR=dfr skip_free_memory_warning

		if(!NVAR_Exists(skip_free_memory_warning) || !skip_free_memory_warning)
			sprintf msg, "The amount of free memory is below %gGB,\r would you like to start a new experiment?", FREE_MEMORY_LOWER_LIMIT
			DoAlert/T="Low memory warning" 1, msg
			if(V_flag == 1)
				SaveExperimentSpecial(SAVE_AND_SPLIT)
				print "Please restart data acquisition"
				return 1
			else
				variable/G dfr:skip_free_memory_warning = 1
			endif
		endif
	endif

	// check that if multiple devices are locked we are in multi device mode
	if(ItemsInList(GetListOfLockedDevices()) > 1 && !GetCheckBoxState(panelTitle, "check_Settings_MD"))
		print "If multiple devices are locked, DAQ/TP is only possible in multi device mode"
		return 1
	endif

	list = panelTitle

	if(DAP_DeviceHasFollower(panelTitle))
		SVAR listOfFollowerDevices = $GetFollowerList(doNotCreateSVAR=1)
		if(DAP_CheckSettingsAcrossYoked(listOfFollowerDevices, mode))
			return 1
		endif
		list = AddListItem(list, listOfFollowerDevices, ";", inf)
	endif
	DEBUGPRINT("Checking the panelTitle list: ", str=list)

	numEntries = ItemsInList(list)
	for(i = 0; i < numEntries; i += 1)

		panelTitle = StringFromList(i, list)

		AbortOnValue HSU_DeviceIsUnlocked(panelTitle),1

		if(HSU_CanSelectDevice(panelTitle))
			printf "(%s) Device can not be selected. Please unlock and lock the device.\r", panelTitle
			return 1
		endif

		if(!DAP_PanelIsUpToDate(panelTitle))
			printf "(%s) The DA_Ephys panel is too old to be usable. Please close it and open a new one.\r", panelTitle
			return 1
		endif

		numHS = sum(DC_ControlStatusWave(panelTitle, CHANNEL_TYPE_HEADSTAGE))
		if(!numHS)
			printf "(%s) Please activate at least one headstage\r", panelTitle
			return 1
		endif

		WAVE statusDA = DC_ControlStatusWave(panelTitle, CHANNEL_TYPE_DAC)
		numDACs = sum(statusDA)
		if(!numDACS)
			printf "(%s) Please activate at least one DA channel\r", panelTitle
			return 1
		endif

		numADCs = sum(DC_ControlStatusWave(panelTitle, CHANNEL_TYPE_ADC))
		if(!numADCs)
			printf "(%s) Please activate at least one AD channel\r", panelTitle
			return 1
		endif

		WAVE statusHS = DC_ControlStatusWave(panelTitle, CHANNEL_TYPE_HEADSTAGE)

		if(mode == DATA_ACQUISITION_MODE)
			// check all selected TTLs
			indexingEnabled = GetCheckBoxState(panelTitle, "Check_DataAcq_Indexing")
			Wave statusTTL = DC_ControlStatusWave(panelTitle, CHANNEL_TYPE_TTL)
			numEntries = DimSize(statusTTL, ROWS)
			for(i=0; i < numEntries; i+=1)
				if(!DC_ChannelIsActive(panelTitle, mode, CHANNEL_TYPE_TTL, i, statusTTL, statusHS))
					continue
				endif

				ctrl = GetPanelControl(i, CHANNEL_TYPE_TTL, CHANNEL_CONTROL_WAVE)
				ttlWave = GetPopupMenuString(panelTitle, ctrl)
				if(!CmpStr(ttlWave, NONE))
					printf "(%s) Please select a valid wave for TTL channel %d\r", panelTitle, i
					return 1
				endif

				if(indexingEnabled)
					ctrl = GetPanelControl(i, CHANNEL_TYPE_TTL, CHANNEL_CONTROL_INDEX_END)
					endWave = GetPopupMenuString(panelTitle, ctrl)
					if(!CmpStr(endWave, NONE))
						printf "(%s) Please select a valid indexing end wave for TTL channel %d\r", panelTitle, i
						return 1
					elseif(!CmpStr(ttlWave, endWave))
						printf "(%s) Please select a indexing end wave different as the main wave for TTL channel %d\r", panelTitle, i
						return 1
					endif
				endif
			endfor

			// for distributed acquisition all stim sets must be the same
			if(GetCheckBoxState(panelTitle, "Check_DataAcq1_DistribDaq"))
				numEntries = DimSize(statusDA, ROWS)
				for(i=0; i < numEntries; i+=1)
					if(!DC_ChannelIsActive(panelTitle, mode, CHANNEL_TYPE_DAC, i, statusDA, statusHS))
						continue
					endif

					ctrl = GetPanelControl(i, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE)
					dacWave = GetPopupMenuString(panelTitle, ctrl)
					if(isEmpty(refDacWave))
						refDacWave = dacWave
					elseif(CmpStr(refDacWave, dacWave))
						printf "(%s) Please select the same stim sets for all DACs when distributed acquisition is used\r", panelTitle
						return 1
					endif
				endfor
			endif
		endif

		// avoid having different headstages reference the same amplifiers
		// and/or DA/AD channels in the "DAC Channel and Device Associations" menu
		Make/FREE/N=(NUM_HEADSTAGES) DACs, ADCs

		WAVE chanAmpAssign = GetChanAmpAssign(panelTitle)

		for(i = 0; i < NUM_HEADSTAGES; i += 1)

			clampMode = DAP_MIESHeadstageMode(panelTitle, i)

			if(clampMode == V_CLAMP_MODE)
				DACs[i] = ChanAmpAssign[0][i]
				ADCs[i] = ChanAmpAssign[2][i]
			elseif(clampMode == I_CLAMP_MODE || clampMode == I_EQUAL_ZERO_MODE)
				DACs[i] = ChanAmpAssign[4][i]
				ADCs[i] = ChanAmpAssign[6][i]
			else
				printf "(%s) Unhandled mode %d\r", panelTitle, clampMode
				return 1
			endif
		endfor

		if(SearchForDuplicates(DACs))
			printf "(%s) Different headstages in the \"DAC Channel and Device Associations\" menu reference the same DA channels.\r", panelTitle
			printf "Please clear the associations for unused headstages.\r"
			return 1
		endif

		if(SearchForDuplicates(ADCs))
			printf "(%s) Different headstages in the \"DAC Channel and Device Associations\" menu reference the same AD channels.\r", panelTitle
			printf "Please clear the associations for unused headstages.\r"
			return 1
		endif

		MatrixOP/FREE ampIndex = row(chanAmpAssign, 10)^t

		if(SearchForDuplicates(ampIndex))
			printf "(%s) Different headstages in the \"DAC Channel and Device Associations\" menu reference the same amplifier-channel-combination.\r", panelTitle
			printf "Please clear the associations for unused headstages.\r"
			return 1
		endif

		// check all active headstages
		numEntries = DimSize(statusHS, ROWS)
		for(i=0; i < numEntries; i+=1)
			if(!statusHS[i])
				continue
			endif

			if(DAP_CheckHeadStage(panelTitle, i, mode))
				return 1
			endif
		endfor

		if(GetSetVariable(panelTitle, "SetVar_DataAcq_TPDuration") <= 0)
			print "The testpulse duration must be greater than 0 ms"
			return 1
		endif

		// unlock ITCDataWave, this happens if user functions error out and we don't catch it
		WAVE ITCDataWave = GetITCDataWave(panelTitle)
		if(NumberByKey("LOCK", WaveInfo(ITCDataWave, 0)))
			printf "(%s) Removing leftover lock on ITCDataWave\r", panelTitle
			SetWaveLock 0, ITCDataWave
		endif
	endfor

	return 0
End

/// @brief Returns 1 if the headstage has invalid settings, and zero if everything is okay
static Function DAP_CheckHeadStage(panelTitle, headStage, mode)
	string panelTitle
	variable headStage, mode

	string ctrl, dacWave, endWave, unit, func, info, str
	variable DACchannel, ADCchannel, DAheadstage, ADheadstage, realMode
	variable gain, scale, clampMode, i, valid_f1, valid_f2

	if(HSU_DeviceisUnlocked(panelTitle, silentCheck=1))
		return 1
	endif

	Wave ChanAmpAssign    = GetChanAmpAssign(panelTitle)
	Wave channelClampMode = GetChannelClampMode(panelTitle)

	if(headstage < 0 || headStage >= DimSize(ChanAmpAssign, COLS))
		printf "(%s) Invalid headstage %d\r", panelTitle, headStage
		return 1
	endif

	clampMode = DAP_MIESHeadstageMode(panelTitle, headstage)

	if(clampMode == V_CLAMP_MODE)
		DACchannel = ChanAmpAssign[0][headStage]
		ADCchannel = ChanAmpAssign[2][headStage]
	elseif(clampMode == I_CLAMP_MODE || clampMode == I_EQUAL_ZERO_MODE)
		DACchannel = ChanAmpAssign[4][headStage]
		ADCchannel = ChanAmpAssign[6][headStage]
	else
		printf "(%s) Unhandled mode %d\r", panelTitle, clampMode
		return 1
	endif

	if(!IsFinite(DACchannel) || !IsFinite(ADCchannel))
		printf "(%s) Please select a valid DA and AD channel in \"DAC Channel and Device Associations\" in the Hardware tab.\r", panelTitle
		return 1
	endif

	realMode = channelClampMode[DACchannel][%DAC]
	if(realMode != clampMode)
		printf "(%s) The clamp mode of DA %d is %s and differs from the requested mode %s.\r", panelTitle, DACchannel, AI_ConvertAmplifierModeToString(realMode), AI_ConvertAmplifierModeToString(clampMode)
		return 1
	endif

	realMode = channelClampMode[ADCchannel][%ADC]
	if(realMode != clampMode)
		printf "(%s) The clamp mode of AD %d is %s and differs from the requested mode %s.\r", panelTitle, ADCchannel, AI_ConvertAmplifierModeToString(realMode), AI_ConvertAmplifierModeToString(clampMode)
		return 1
	endif

	ADheadstage = AFH_GetHeadstageFromADC(panelTitle, ADCchannel)
	if(!IsFinite(ADheadstage))
		printf "(%s) Could not determine the headstage for the ADChannel %d.\r", panelTitle, ADCchannel
		return 1
	endif

	DAheadstage = AFH_GetHeadstageFromDAC(panelTitle, DACchannel)
	if(!IsFinite(DAheadstage))
		printf "(%s) Could not determine the headstage for the DACchannel %d.\r", panelTitle, DACchannel
		return 1
	endif

	if(DAheadstage != ADheadstage)
		printf "(%s) The configured headstages for the DA channel %d and the AD channel %d differ (%d vs %d).\r", panelTitle, DACchannel, ADCchannel, DAheadstage, ADheadstage
		return 1
	endif

	ctrl = GetPanelControl(DACchannel, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_UNIT)
	unit = GetSetVariableString(panelTitle, ctrl)
	if(isEmpty(unit))
		printf "(%s) The unit for DACchannel %d is empty.\r", panelTitle, DACchannel
		return 1
	endif

	ctrl = GetPanelControl(DACchannel, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_GAIN)
	gain = GetSetVariable(panelTitle, ctrl)
	if(!isFinite(gain) || gain == 0)
		printf "(%s) The gain for DACchannel %d must be finite and non-zero.\r", panelTitle, DACchannel
		return 1
	endif

	// we allow the scale being zero
	ctrl = GetPanelControl(DACchannel, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_SCALE)
	scale = GetSetVariable(panelTitle, ctrl)
	if(!isFinite(scale))
		printf "(%s) The scale for DACchannel %d must be finite.\r", panelTitle, DACchannel
		return 1
	endif

	ctrl = GetPanelControl(ADCchannel, CHANNEL_TYPE_ADC, CHANNEL_CONTROL_UNIT)
	unit = GetSetVariableString(panelTitle, ctrl)
	if(isEmpty(unit))
		printf "(%s) The unit for ADCchannel %d is empty.\r", panelTitle, ADCchannel
		return 1
	endif

	ctrl = GetPanelControl(ADCchannel, CHANNEL_TYPE_ADC, CHANNEL_CONTROL_GAIN)
	gain = GetSetVariable(panelTitle, ctrl)
	if(!isFinite(gain) || gain == 0)
		printf "(%s) The gain for ADCchannel %d must be finite and non-zero.\r", panelTitle, ADCchannel
		return 1
	endif

	if(mode == DATA_ACQUISITION_MODE)
		ctrl = GetPanelControl(DACchannel, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE)
		dacWave = GetPopupMenuString(panelTitle, ctrl)
		if(!CmpStr(dacWave, NONE) || IsTestPulseSet(dacWave))
			printf "(%s) Please select a stimulus set for DA channel %d referenced by Headstage %d\r", panelTitle, DACchannel, headStage
			return 1
		endif

		// third party stim sets might not match our expectations
		WAVE/Z stimSet = WB_CreateAndGetStimSet(dacWave)

		if(!WaveExists(stimSet))
			printf "(%s) The stim set %s of headstage %d does not exist or could not be created..\r", panelTitle, dacWave, headstage
			return 1
		elseif(DimSize(stimSet, ROWS) == 0)
			printf "(%s) The stim set %s of headstage %d is empty, but must have at least one row.\r", panelTitle, dacWave, headstage
			return 1
		endif

		// non fatal errors which we fix ourselves
		if(DimDelta(stimSet, ROWS) != MINIMUM_SAMPLING_INTERVAL || DimOffset(stimSet, ROWS) != 0.0 || cmpstr(WaveUnits(stimSet, ROWS), "ms"))
			sprintf str, "(%s) The stim set %s of headstage %d must have a row dimension delta of %g, row dimension offset of zero and row unit \"ms\".\r", panelTitle, dacWave, headstage, MINIMUM_SAMPLING_INTERVAL
			DEBUGPRINT(str)
			DEBUGPRINT("The stim set is now automatically fixed")
			SetScale/P x 0, MINIMUM_SAMPLING_INTERVAL, "ms", stimSet
		endif

		if(!GetCheckBoxState(panelTitle, "Check_Settings_SkipAnalysFuncs"))
			for(i = 0; i < TOTAL_NUM_EVENTS; i += 1)
				func = ExtractAnalysisFuncFromStimSet(stimSet, i)

				if(isEmpty(func)) // none set
					continue
				endif

				info = FunctionInfo(func)

				if(isEmpty(info))
					printf "(%s) Warning: The analysis function %s for stim set %s and event type \"%s\" could not be found\r", panelTitle, func, dacWave, StringFromList(i, EVENT_NAME_LIST)
					continue
				endif

				FUNCREF AF_PROTO_ANALYSIS_FUNC_V1 f1 = $func
				FUNCREF AF_PROTO_ANALYSIS_FUNC_V2 f2 = $func

				valid_f1 = FuncRefIsAssigned(FuncRefInfo(f1))
				valid_f2 = FuncRefIsAssigned(FuncRefInfo(f2))

				if(!valid_f1 && !valid_f2) // not a valid analysis function
					printf "(%s) The analysis function %s for stim set %s and event type \"%s\" has an invalid signature\r", panelTitle, func, dacWave, StringFromList(i, EVENT_NAME_LIST)
					return 1
				endif

				if(i == MID_SWEEP_EVENT && !GetCheckBoxState(panelTitle, "Check_Settings_BackgrndDataAcq"))
					printf "(%s) The event type \"%s\" for stim set %s can not be used together with foreground DAQ\r", panelTitle, StringFromList(i, EVENT_NAME_LIST), dacWave
				endif
			endfor
		endif

		if(GetCheckBoxState(panelTitle, "Check_DataAcq_Indexing"))
			ctrl = GetPanelControl(DACchannel, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_INDEX_END)
			endWave = GetPopupMenuString(panelTitle, ctrl)
			if(!CmpStr(endWave, NONE))
				printf "(%s) Please select a valid indexing end wave for DA channel %d referenced by HeadStage %d\r", panelTitle, DACchannel, headStage
				return 1
			elseif(!CmpStr(dacWave, endWave))
				printf "(%s) Please select a different indexing end wave than the DAC wave for DA channel %d referenced by HeadStage %d\r", panelTitle, DACchannel, headStage
				return 1
			endif
		endif
	endif

	if(AI_SelectMultiClamp(panelTitle, headStage, verbose=0) == 2)
		printf "(%s) The amplifier of the headstage %d can not be selected, please call \"Query connected Amps\" from the Hardware Tab\r", panelTitle, headStage
		printf " and ensure that the \"Multiclamp 700B Commander\" application is open.\r"
		return 1
	endif

	if(AI_MIESHeadstageMatchesMCCMode(panelTitle, headStage) == 0)
		return 1
	endif

	return 0
End

/// @brief Reads the channel amp waves and inserts that info into the DA_EPHYS panel
static Function DAP_ApplyClmpModeSavdSettngs(panelTitle, headStage, clampMode)
	string panelTitle
	variable headStage, clampMode

	string ctrl, ADUnit, DAUnit
	variable DAGain, ADGain
	variable DACchannel, ADCchannel

	Wave ChanAmpAssign       = GetChanAmpAssign(panelTitle)
	Wave ChannelClampMode    = GetChannelClampMode(panelTitle)
	Wave/T ChanAmpAssignUnit = GetChanAmpAssignUnit(panelTitle)

	if(clampMode == V_CLAMP_MODE)
		DACchannel = ChanAmpAssign[0][headStage]
		ADCchannel = ChanAmpAssign[2][headStage]
		DAGain     = ChanAmpAssign[1][headStage]
		ADGain     = ChanAmpAssign[3][headStage]
		DAUnit     = ChanAmpAssignUnit[0][headStage]
		ADUnit     = ChanAmpAssignUnit[1][headStage]
	elseif(ClampMode == I_CLAMP_MODE || clampMode == I_EQUAL_ZERO_MODE)
		DACchannel = ChanAmpAssign[4][headStage]
		ADCchannel = ChanAmpAssign[6][headStage]
		DAGain     = ChanAmpAssign[5][headStage]
		ADGain     = ChanAmpAssign[7][headStage]
		DAUnit     = ChanAmpAssignUnit[2][headStage]
		ADUnit     = ChanAmpAssignUnit[3][headStage]
	endif

	if(!IsFinite(DACchannel) || !IsFinite(ADCchannel))
		return NaN
	endif

	// DAC channels
	ctrl = GetPanelControl(DACchannel, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_CHECK)
	SetCheckBoxState(panelTitle, 	ctrl, CHECKBOX_SELECTED)
	ctrl = GetPanelControl(DACchannel, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_GAIN)
	SetSetVariable(panelTitle, ctrl, DaGain)
	ctrl = GetPanelControl(DACchannel, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_UNIT)
	SetSetVariableString(panelTitle, ctrl, DaUnit)
	ChannelClampMode[DACchannel][%DAC] = clampMode

	// ADC channels
	ctrl = GetPanelControl(ADCchannel, CHANNEL_TYPE_ADC, CHANNEL_CONTROL_CHECK)
	SetCheckBoxState(panelTitle, ctrl, CHECKBOX_SELECTED)
	ctrl = GetPanelControl(ADCchannel, CHANNEL_TYPE_ADC, CHANNEL_CONTROL_GAIN)
	SetSetVariable(panelTitle, ctrl, ADGain)
	ctrl = GetPanelControl(ADCchannel, CHANNEL_TYPE_ADC, CHANNEL_CONTROL_UNIT)
	SetSetVariableString(panelTitle, ctrl, ADUnit)
	ChannelClampMode[ADCchannel][%ADC] = clampMode
End

static Function DAP_RemoveClampModeSettings(panelTitle, headStage, clampMode)
	string panelTitle
	variable headStage, clampMode

	string ctrl
	variable DACchannel, ADCchannel

	Wave ChanAmpAssign    = GetChanAmpAssign(panelTitle)
	Wave ChannelClampMode = GetChannelClampMode(panelTitle)

	if(ClampMode == V_CLAMP_MODE)
		DACchannel = ChanAmpAssign[0][headStage]
		ADCchannel = ChanAmpAssign[2][headStage]
	elseif(ClampMode == I_CLAMP_MODE || clampMode == I_EQUAL_ZERO_MODE)
		DACchannel = ChanAmpAssign[4][headStage]
		ADCchannel = ChanAmpAssign[6][headStage]
	endIf

	if(!IsFinite(DACchannel) || !IsFinite(ADCchannel))
		return NaN
	endif

	ctrl = GetPanelControl(DACchannel, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_CHECK)
	SetCheckBoxState(panelTitle, ctrl, CHECKBOX_UNSELECTED)
	ChannelClampMode[DACchannel][%DAC] = nan

	ctrl = GetPanelControl(ADCchannel, CHANNEL_TYPE_ADC, CHANNEL_CONTROL_CHECK)
	SetCheckBoxState(panelTitle, ctrl, CHECKBOX_UNSELECTED)
	ChannelClampMode[ADCchannel][%ADC] = nan
End

/// @brief Return the name of the checkbox control handling the clamp mode of the given headstage
Function/S DAP_GetClampModeControl(mode, headstage)
	variable mode, headstage

	ASSERT(headStage >= 0 && headStage < NUM_HEADSTAGES, "invalid headStage index")

	switch(mode)
		case V_CLAMP_MODE:
			return "Radio_ClampMode_" + num2str(headStage * 2)
		case I_CLAMP_MODE:
			return "Radio_ClampMode_" + num2str(headStage * 2 + 1)
		case I_EQUAL_ZERO_MODE:
			return "Radio_ClampMode_" + num2str(headStage * 2 + 1) + "IZ"
		default:
			ASSERT(0, "invalid mode")
			break
	endswitch
End

/// @brief Return information readout from headstage and clamp mode controls
///
/// Users interested in the clamp mode of a known headstage should prefer DAP_MIESHeadstageMode() instead.
///
/// @param[in]  panelTitle  panel
/// @param[in]  ctrl        control can be either `Radio_ClampMode_*` or `Check_DataAcqHS_*`
///                         referring to an existing control
/// @param[out] mode        I_CLAMP_MODE, V_CLAMP_MODE or I_EQUAL_ZERO_MODE, the currently active mode for headstage controls
///                         and the clamp mode of the control for clamp mode controls
/// @param[out] headStage   number of the headstage
static Function DAP_GetInfoFromControl(panelTitle, ctrl, mode, headStage)
	string panelTitle, ctrl
	variable &mode, &headStage

	string clampMode     = "Radio_ClampMode_"
	string headStageCtrl = "Check_DataAcqHS_"
	variable pos1, pos2, ctrlNo
	string ICctrl, VCctrl, iZeroCtrl, ctrlClean

	mode      = NaN
	headStage = NaN

	ASSERT(!isEmpty(ctrl), "Empty control")

	pos1 = strsearch(ctrl, clampMode, 0)
	pos2 = strsearch(ctrl, headStageCtrl, 0)

	if(pos1 != -1)
		ctrlClean = RemoveEnding(ctrl, "IZ")
		ctrlNo = str2num(ctrlClean[pos1 + strlen(clampMode), inf])
		ASSERT(IsFinite(ctrlNo), "non finite number parsed from control")
		if(mod(ctrlNo, 2) == 0)
			mode = V_CLAMP_MODE
			headStage = ctrlNo / 2
		else
			if(!cmpstr(ctrlClean, ctrl))
				mode = I_CLAMP_MODE
			else
				mode = I_EQUAL_ZERO_MODE
			endif
			headStage = (ctrlNo - 1) / 2
		endif
	elseif(pos2 != -1)
		ctrlNo = str2num(ctrl[pos2 + strlen(headStageCtrl), inf])
		ASSERT(IsFinite(ctrlNo), "non finite number parsed from control")
		headStage = ctrlNo

		VCctrl    = DAP_GetClampModeControl(V_CLAMP_MODE, headstage)
		ICctrl    = DAP_GetClampModeControl(I_CLAMP_MODE, headstage)
		iZeroCtrl = DAP_GetClampModeControl(I_EQUAL_ZERO_MODE, headstage)

		mode = V_CLAMP_MODE // safe default

		if(GetCheckBoxState(panelTitle, VCctrl))
			mode = V_CLAMP_MODE
		elseif(GetCheckBoxState(panelTitle, ICctrl))
			mode = I_CLAMP_MODE
		elseif(GetCheckBoxState(panelTitle, iZeroCtrl))
			mode = I_EQUAL_ZERO_MODE
		endif
	else
		ASSERT(0, "unhandled control")
	endif

	AI_AssertOnInvalidClampMode(mode)
End

Function DAP_CheckProc_ClampMode(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	variable mode, headStage
	string panelTitle

	switch(cba.eventCode)
		case EVENT_MOUSE_UP:
			panelTitle = cba.win
			DAP_GetInfoFromControl(panelTitle, cba.ctrlName, mode, headStage)
			DAP_ChangeHeadStageMode(panelTitle, mode, headstage)
		break
	endswitch

	return 0
End

Function DAP_CheckProc_HedstgeChck(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	switch( cba.eventCode )
		case EVENT_MOUSE_UP:
			DAP_ChangeHeadstageState(cba.win, cba.ctrlName, cba.checked)
			break
	endswitch

	return 0
End

/// @brief Change the clamp mode of the given headstage
/// @param panelTitle device
/// @param clampMode  clamp mode to activate
/// @param headStage  Headstage [0, 8[
static Function DAP_ChangeHeadStageMode(panelTitle, clampMode, headStage)
	string panelTitle
	variable headStage, clampMode

	string iZeroCtrl, VCctrl, ICctrl, headStageCtrl, ctrl
	variable activeHS, testPulseMode, oppositeMode

	AI_AssertOnInvalidClampMode(clampMode)

	headStageCtrl = GetPanelControl(headStage, CHANNEL_TYPE_HEADSTAGE, CHANNEL_CONTROL_CHECK)
	activeHS = GetCheckBoxState(panelTitle, headStageCtrl)
	if(activeHS)
		testPulseMode = TP_StopTestPulse(panelTitle)
	endif

	VCctrl    = DAP_GetClampModeControl(V_CLAMP_MODE, headStage)
	ICctrl    = DAP_GetClampModeControl(I_CLAMP_MODE, headStage)
	iZeroCtrl = DAP_GetClampModeControl(I_EQUAL_ZERO_MODE, headStage)
	ctrl      = DAP_GetClampModeControl(clampMode, headStage)

	SetCheckboxState(panelTitle, VCctrl, CHECKBOX_UNSELECTED)
	SetCheckboxState(panelTitle, ICctrl, CHECKBOX_UNSELECTED)
	SetCheckboxState(panelTitle, iZeroCtrl, CHECKBOX_UNSELECTED)

	SetCheckboxState(panelTitle, ctrl, CHECKBOX_SELECTED)

	if(activeHS)
		oppositeMode = (clampMode == I_CLAMP_MODE || clampMode == I_EQUAL_ZERO_MODE ? V_CLAMP_MODE : I_CLAMP_MODE)
		DAP_RemoveClampModeSettings(panelTitle, headStage, oppositeMode)
		DAP_ApplyClmpModeSavdSettngs(panelTitle, headStage, clampMode)
		AI_SetClampMode(panelTitle, headStage, clampMode)
	endif

	DAP_UpdateClampmodeTabs(panelTitle, headStage, clampMode)
	DAP_UpdateITCSampIntDisplay(panelTitle)

	WAVE GUIState = GetDA_EphysGuiStateNum(panelTitle)
	GuiState[headStage][%HSmode] = clampMode

	if(activeHS)
		TP_RestartTestPulse(panelTitle, testPulseMode)
	endif
End

static Function DAP_UpdateClampmodeTabs(panelTitle, headStage, clampMode)
	string panelTitle
	variable headStage, clampMode

	string highlightSpec = "\\f01\\Z11"

	AI_AssertOnInvalidClampMode(clampMode)

	AI_SyncAmpStorageToGUI(panelTitle, headStage)
	ChangeTab(panelTitle, "tab_DataAcq_Amp", clampMode)

	TabControl tab_DataAcq_Amp win=$panelTitle, tabLabel(V_CLAMP_MODE)      = SelectString(clampMode == V_CLAMP_MODE,      "", highlightSpec) + "V-Clamp"
	TabControl tab_DataAcq_Amp win=$panelTitle, tabLabel(I_CLAMP_MODE)      = SelectString(clampMode == I_CLAMP_MODE,      "", highlightSpec) + "I-Clamp"
	TabControl tab_DataAcq_Amp win=$panelTitle, tabLabel(I_EQUAL_ZERO_MODE) = SelectString(clampMode == I_EQUAL_ZERO_MODE, "", highlightSpec) + "I = 0"
End

static Function DAP_ChangeHeadstageState(panelTitle, headStageCtrl, enabled)
	string panelTitle, headStageCtrl
	variable enabled

	WAVE GUIState = GetDA_EphysGuiStateNum(panelTitle)
	variable clampMode, headStage, TPState, ICstate, VCstate, IZeroState
	variable channelType, controlType
	string VCctrl, ICctrl, IZeroCtrl

	DAP_ParsePanelControl(headStageCtrl, headstage, channelType, controlType)
	ASSERT(channelType == CHANNEL_TYPE_HEADSTAGE && controlType == CHANNEL_CONTROL_CHECK, "Expected headstage checkbox control")

	TPState = TP_StopTestPulse(panelTitle)
	GuiState[headStage][%HSState] = enabled

	clampMode = GuiState[headStage][%HSmode]
	if(!enabled)
		DAP_RemoveClampModeSettings(panelTitle, headStage, clampMode)
	else
		DAP_ApplyClmpModeSavdSettngs(panelTitle, headStage, clampMode)
	endif

	DAP_UpdateITCSampIntDisplay(panelTitle)
	DAP_UpdateITIAcrossSets(panelTitle)
	DAP_UpdateSweepSetVariables(panelTitle)

	VCctrl    = DAP_GetClampModeControl(V_CLAMP_MODE, headstage)
	ICctrl    = DAP_GetClampModeControl(I_CLAMP_MODE, headstage)
	IZeroCtrl = DAP_GetClampModeControl(I_EQUAL_ZERO_MODE, headstage)

	VCstate    = GetCheckBoxState(panelTitle, VCctrl)
	ICstate    = GetCheckBoxState(panelTitle, ICctrl)
	IZeroState = GetCheckBoxState(panelTitle, IZeroCtrl)

	if(VCstate + ICstate + IZeroState != 1) // someone messed up the radio button logic, reset to V_CLAMP_MODE
		PGC_SetAndActivateControl(panelTitle, VCctrl, val=CHECKBOX_SELECTED)
	else
		TP_RestartTestPulse(panelTitle, TPState)
	endif
End

/// @brief Stop the testpulse and data acquisition
///
/// Should be used if `Multi Device Support` is not checked
Function DAP_StopOngoingDataAcquisition(panelTitle)
	string panelTitle

	string cmd
	variable needsOTCAfterDAQ = 0
	variable discardData      = 0

	if(IsDeviceActiveWithBGTask(panelTitle, "Testpulse"))
		ITC_StopTestPulseSingleDevice(panelTitle)

		needsOTCAfterDAQ = needsOTCAfterDAQ | 0
		discardData      = discardData      | 1
	endif

	if(IsDeviceActiveWithBGTask(panelTitle, "ITC_Timer"))
		ITC_StopBackgroundTimerTask()

		needsOTCAfterDAQ = needsOTCAfterDAQ | 0
		discardData      = discardData      | 1
	endif

	if(IsDeviceActiveWithBGTask(panelTitle, "ITC_FIFOMonitor"))
		ITC_STOPFifoMonitor()

		sprintf cmd, "ITCStopAcq /z = 0"
		ExecuteITCOperation(cmd)
		// zero channels that may be left high
		ITC_ZeroITCOnActiveChan(panelTitle)

		if(!discardData)
			DM_SaveAndScaleITCData(panelTitle)
		endif

		needsOTCAfterDAQ = needsOTCAfterDAQ | 1
	else
		// force a stop if invoked during a 'down' time, with nothing happening.
		NVAR count = $GetCount(panelTitle)

		if(IsFinite(count))
			count = GetValDisplayAsNum(panelTitle, "valdisp_DataAcq_SweepsInSet")
			needsOTCAfterDAQ = needsOTCAfterDAQ | 1
		endif
	endif

	if(needsOTCAfterDAQ)
		DAP_OneTimeCallAfterDAQ(panelTitle)
	endif
End

/// @brief Set the acquisition button text
///
/// @param panelTitle device
/// @param mode       One of @ref ToggleAcquisitionButtonConstants
Function DAP_ToggleAcquisitionButton(panelTitle, mode)
	string panelTitle
	variable mode

	ASSERT(mode == DATA_ACQ_BUTTON_TO_STOP || mode == DATA_ACQ_BUTTON_TO_DAQ, "Invalid mode")

	string text

	if(mode == DATA_ACQ_BUTTON_TO_STOP)
		text = "\\Z14\\f01Stop\rAcquistion"
	elseif(mode == DATA_ACQ_BUTTON_TO_DAQ)
		text = "\\Z14\\f01Acquire\rData"
	endif

	Button DataAcquireButton title=text, win = $panelTitle
End

/// @brief Set the testpulse button text
///
/// @param panelTitle device
/// @param mode       One of @ref ToggleTestpulseButtonConstants
Function DAP_ToggleTestpulseButton(panelTitle, mode)
	string panelTitle
	variable mode

	ASSERT(mode == TESTPULSE_BUTTON_TO_STOP || mode == TESTPULSE_BUTTON_TO_START, "Invalid mode")

	string text

	if(mode == TESTPULSE_BUTTON_TO_STOP)
		text = "\\Z14\\f01Stop Test \rPulse"
	elseif(mode == TESTPULSE_BUTTON_TO_START)
		text = "\\Z14\\f01Start Test \rPulse"
	endif

	Button StartTestPulseButton title=text, win = $panelTitle
End

/// Returns the list of potential followers for yoking.
///
/// Used by popup_Hardware_AvailITC1600s from the hardware tab
Function /s DAP_ListOfITCDevices()

	string listOfPotentialFollowerDevices = RemoveFromList(ITC1600_FIRST_DEVICE,GetListOfLockedITC1600Devices())
	return SortList(listOfPotentialFollowerDevices, ";", 16)
End

/// @brief The Lead button in the yoking controls sets the attached ITC1600 as the device that will trigger all the other devices yoked to it.
Function DAP_ButtonProc_Lead(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	string panelTitle

	switch(ba.eventcode)
		case 2:
			panelTitle = ba.win
			ASSERT(DAP_DeviceCanLead(panelTitle),"This device can not lead")

			EnableListOfControls(panelTitle,"button_Hardware_Independent;button_Hardware_AddFollower;title_hardware_Follow;popup_Hardware_AvailITC1600s")
			DisableControl(panelTitle,"button_Hardware_Lead1600")
			SetVariable setvar_Hardware_Status Win = $panelTitle, value= _STR:LEADER
			createDFWithAllParents("root:ImageHardware:Arduino")
			break
	endswitch

	return 0
End

Function DAP_ButtonProc_Independent(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	string panelTitle

	switch(ba.eventcode)
		case 2:
			panelTitle = ba.win

			DisableListOfControls(panelTitle,"button_Hardware_Independent;button_Hardware_AddFollower;popup_Hardware_YokedDACs;button_Hardware_RemoveYoke;title_hardware_Follow;title_hardware_Release;popup_Hardware_AvailITC1600s")
			EnableControl(panelTitle,"button_Hardware_Lead1600")
			SetVariable setvar_Hardware_Status Win = $panelTitle, value= _STR:"Independent"

			DAP_RemoveAllYokedDACs(panelTitle)
			DAP_UpdateAllYokeControls()
			break
	endswitch

	return 0
End

Function DAP_ButtonProc_Follow(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	string leadPanel, panelToYoke

	switch(ba.eventcode)
		case EVENT_MOUSE_UP:

			leadPanel = ba.win

			ControlUpdate/W=$leadPanel popup_Hardware_AvailITC1600s
			ControlInfo/W=$leadPanel popup_Hardware_AvailITC1600s
			if(V_flag > 0 && V_Value >= 1)
				panelToYoke = S_Value
			endif

			if(!windowExists(panelToYoke))
				break
			endif

			ASSERT(CmpStr(panelToYoke, ITC1600_FIRST_DEVICE) != 0, "Can't follow the lead device")

			HSU_SetITCDACasFollower(leadPanel, panelToYoke)
			DAP_UpdateFollowerControls(leadPanel, panelToYoke)
			DAP_SwitchSingleMultiMode(leadpanel, 1)
			DAP_SwitchSingleMultiMode(panelToYoke, 1)

			DAP_UpdateITIAcrossSets(leadPanel)
			DisableListOfControls(panelToYoke, "StartTestPulseButton;DataAcquireButton;Check_DataAcq1_RepeatAcq;Check_DataAcq1_DistribDaq;SetVar_DataAcq_dDAQDelay;Check_DataAcq_Indexing;SetVar_DataAcq_ITI;SetVar_DataAcq_SetRepeats;Check_DataAcq_Get_Set_ITI")
			EnableControl(leadPanel, "button_Hardware_RemoveYoke")
			EnableControl(leadPanel, "popup_Hardware_YokedDACs")
			EnableControl(leadPanel, "title_hardware_Release")
			break
	endswitch

	return 0
End

static Function DAP_SyncGuiFromLeaderToFollower(panelTitle)
	string panelTitle

	variable leaderRepeatAcq, leaderIndexing, leaderITI, leaderOverrrideITI
	variable leaderdDAQDelay, leaderRepeatSets, leaderdDAQ
	variable numPanels, i
	string panelList, leadPanel

	if(!windowExists(panelTitle) || !DAP_DeviceIsLeader(panelTitle))
		return NaN
	endif

	leadPanel = panelTitle
	DAP_UpdateSweepLimitsAndDisplay(leadPanel)

	panelList = leadPanel
	SVAR/Z ListOfFollowerDevices = $GetFollowerList(doNotCreateSVAR=1)
	if(SVAR_Exists(listOfFollowerDevices) && strlen(listOfFollowerDevices) > 0)
		panelList = AddListItem(panelList, listOfFollowerDevices, ";", 0)
	endif

	leaderdDAQ         = GetCheckBoxState(leadPanel, "Check_DataAcq1_DistribDaq")
	leaderRepeatAcq    = GetCheckBoxState(leadPanel, "Check_DataAcq1_RepeatAcq")
	leaderIndexing     = GetCheckBoxState(leadPanel, "Check_DataAcq_Indexing")
	leaderOverrrideITI = GetCheckBoxState(panelTitle, "Check_DataAcq_Get_Set_ITI", allowMissingControl=1)
	leaderITI          = GetSetVariable(leadPanel, "SetVar_DataAcq_ITI")
	leaderRepeatSets   = GetSetVariable(leadPanel, "SetVar_DataAcq_SetRepeats")
	leaderdDAQDelay    = GetSetVariable(leadPanel, "SetVar_DataAcq_dDAQDelay")

	numPanels = ItemsInList(panelList)
	for(i = 1; i < numPanels; i += 1)
		// i = 1 so that we don't set the values
		// for the lead panel again
		panelTitle = StringFromList(i, panelList)

		SetCheckBoxState(panelTitle, "Check_DataAcq1_RepeatAcq", leaderRepeatAcq)
		SetCheckBoxState(panelTitle, "Check_DataAcq_Indexing", leaderIndexing)
		SetSetVariable(panelTitle, "SetVar_DataAcq_ITI", leaderITI)
		SetSetVariable(panelTitle, "SetVar_DataAcq_SetRepeats", leaderRepeatSets)
		SetSetVariable(panelTitle, "SetVar_DataAcq_dDAQDelay", leaderdDAQDelay)
		if(IsFinite(leaderOverrrideITI))
			SetCheckBoxState(panelTitle, "Check_DataAcq_Get_Set_ITI", leaderOverrrideITI)
		endif
	endfor
End

Function DAP_ButtonProc_YokeRelease(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	string panelTitle
	string panelToDeYoke

	switch(ba.eventcode)
		case 2:
			panelTitle = ba.win

			ControlUpdate/W=$panelTitle popup_Hardware_YokedDACs
			ControlInfo/W=$panelTitle popup_Hardware_YokedDACs
			if(V_flag > 0 && V_Value >= 1)
				panelToDeYoke = S_Value
			endif

			if(!windowExists(panelToDeYoke))
				return 0
			endif

			DAP_RemoveYokedDAC(panelToDeYoke)
			DAP_UpdateYokeControls(panelToDeYoke)
			break
	endswitch

	return 0
End

Function DAP_RemoveYokedDAC(panelToDeYoke)
	string panelToDeYoke
	
	string leadPanel = ITC1600_FIRST_DEVICE
	string str

	if(!windowExists(leadPanel))
		return 0
	endif

	SVAR/Z listOfFollowerDevices = $GetFollowerList(doNotCreateSVAR=1)
	if(!SVAR_Exists(listOfFollowerDevices))
		return 0
	endif
	
	if(WhichListItem(panelToDeYoke, listOfFollowerDevices) == -1)
		return 0
	endif

	listOfFollowerDevices = RemoveFromList(panelToDeYoke, listOfFollowerDevices)

	str = listOfFollowerDevices
	if(ItemsInList(listOfFollowerDevices) == 0 )
		// there are no more followers, disable the release button and its popup menu
		DisableControl(leadPanel,"popup_Hardware_YokedDACs")
		DisableControl(leadPanel,"button_Hardware_RemoveYoke")
		/// @todo don't rely on the svar existence
		/// instead query the contents only
		KillStrings listOfFollowerDevices
		str = "No Yoked Devices"
	endif
	SetVariable setvar_Hardware_YokeList Win=$leadPanel, value=_STR:str

	SetVariable setvar_Hardware_Status   Win=$panelToDeYoke, value=_STR:"Independent"

	DisableControl(panelToDeYoke,"setvar_Hardware_YokeList")
	EnableListOfControls(panelToDeYoke, "StartTestPulseButton;DataAcquireButton;Check_DataAcq1_RepeatAcq;Check_DataAcq1_DistribDaq;SetVar_DataAcq_dDAQDelay;Check_DataAcq_Indexing;SetVar_DataAcq_ITI;SetVar_DataAcq_SetRepeats;Check_DataAcq_Get_Set_ITI")
	DAP_UpdateITIAcrossSets(panelToDeYoke)

	SetVariable setvar_Hardware_YokeList Win=$panelToDeYoke, value=_STR:"None"

	string cmd
	NVAR followerITCDeviceIDGlobal = $GetITCDeviceIDGlobal(panelToDeYoke)
	sprintf cmd, "ITCSelectDevice %d" followerITCDeviceIDGlobal
	ExecuteITCOperation(cmd)
	sprintf cmd, "ITCInitialize /M = 0"
	ExecuteITCOperation(cmd)
End

Function DAP_RemoveAllYokedDACs(panelTitle)
	string panelTitle

	string panelToDeYoke, list
	variable i, listNum

	SVAR/Z listOfFollowerDevices = $GetFollowerList(doNotCreateSVAR=1)
	if(!SVAR_Exists(listOfFollowerDevices))
		return 0
	endif

	list = listOfFollowerDevices

	// we have to operate on a copy of ListOfFollowerITC1600s as
	// DAP_RemoveYokedDAC modifies it.

	listNum = ItemsInList(list)

	for(i=0; i < listNum; i+=1)
		panelToDeYoke =  StringFromList(i, list)
		DAP_RemoveYokedDAC(panelToDeYoke)
	endfor
End

/// Sets the lists and buttons on the follower device actively being yoked
Function DAP_UpdateFollowerControls(panelTitle, panelToYoke)
	string panelTitle, panelToYoke
	
	SetVariable setvar_Hardware_Status win = $panelToYoke, value = _STR:FOLLOWER
	EnableControl(panelToYoke,"setvar_Hardware_YokeList")
	SetVariable setvar_Hardware_YokeList  win=$panelToYoke, value = _STR:"Lead device = " + panelTitle
	DAP_UpdateYokeControls(panelToYoke)
End

Function DAP_ButtonProc_AutoFillGain(ba) : ButtonControl
	struct WMButtonAction &ba

	string panelTitle
	variable headStage, axonSerial

	switch( ba.eventCode )
		case 2: // mouse up
			panelTitle = ba.win
			Wave ChanAmpAssign = GetChanAmpAssign(panelTitle)
			Wave/SDFR=GetAmplifierFolder() W_TelegraphServers

			// Is an amp associated with the headstage?
			headStage  = GetPopupMenuIndex(panelTitle, "Popup_Settings_HeadStage")
			axonSerial = ChanAmpAssign[8][headStage]

			if(!IsFinite(axonSerial))
				print "An amp channel has not been assigned to this headstage therefore gains cannot be imported"
				break
			endif

			// Is the amp still connected?
			FindValue/I=(axonSerial)/T=0 W_TelegraphServers
			if(V_Value != -1)
				AI_AutoFillGain(panelTitle)
				HSU_UpdateChanAmpAssignStorWv(panelTitle)
			endif
			break
	endswitch

	return 0
End

Function DAP_SliderProc_MIESHeadStage(sc) : SliderControl
	struct WMSliderAction &sc

	string panelTitle
	variable mode, headStage

	// eventCode is a bitmask as opposed to a plain value
	// compared to other controls
	if(sc.eventCode > 0 && sc.eventCode & 0x1)
		panelTitle = sc.win
		headStage  = sc.curVal
		mode = DAP_MIESHeadstageMode(panelTitle, headStage)
		P_LoadPressureButtonState(panelTitle, headStage)
		P_SaveUserSelectedHeadstage(panelTitle, headStage)
		DAP_UpdateClampmodeTabs(panelTitle, headStage, mode)
	endif

	return 0
End

Function DAP_SetVarProc_AmpCntrls(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	string panelTitle, ctrl
	variable headStage

	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
			panelTitle = sva.win
			ctrl       = sva.ctrlName
			headStage =  GetSliderPositionIndex(panelTitle, "slider_DataAcq_ActiveHeadstage")
			AI_UpdateAmpModel(panelTitle, ctrl, headStage)
			break
		case 3: // Live update
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function DAP_ButtonProc_AmpCntrls(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	string panelTitle, ctrl
	variable headStage

	switch( ba.eventCode )
		case 2: // mouse up
			panelTitle = ba.win
			ctrl       = ba.ctrlName

			headStage =  GetSliderPositionIndex(panelTitle, "slider_DataAcq_ActiveHeadstage")
			AI_UpdateAmpModel(panelTitle, ctrl, headstage)
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function DAP_CheckProc_AmpCntrls(cba) : CheckBoxControl
	struct WMCheckboxAction &cba

	string panelTitle, ctrl
	variable headStage

	switch( cba.eventCode )
		case EVENT_MOUSE_UP:
			panelTitle = cba.win
			ctrl       = cba.ctrlName

			headStage =  GetSliderPositionIndex(panelTitle, "slider_DataAcq_ActiveHeadstage")
			AI_UpdateAmpModel(panelTitle, ctrl, headStage)
			break
	endswitch

	return 0
End

/// @brief Check box procedure for multiple device (MD) support
Function DAP_CheckProc_MDEnable(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	switch(cba.eventCode)
		case EVENT_MOUSE_UP:
			DAP_SwitchSingleMultiMode(cba.win, cba.checked)
			break
	endswitch

	return 0
End

/// @brief Enable/Disable the related controls for single and multi device DAQ
///
/// @param panelTitle     device
/// @param useMultiDevice disable(0) or enable(1) the multi device support
static Function DAP_SwitchSingleMultiMode(panelTitle, useMultiDevice)
	string panelTitle
	variable useMultiDevice

	variable checkedState

	if(useMultiDevice)
		DisableListOfControls(panelTitle, "Check_Settings_BkgTP;Check_Settings_BackgrndDataAcq")
		checkedState = GetCheckBoxState(panelTitle, "Check_Settings_BkgTP")
		SetControlUserData(panelTitle, "Check_Settings_BkgTP", "oldState", num2str(checkedState))
		checkedState = GetCheckBoxState(panelTitle, "Check_Settings_BackgrndDataAcq")
		SetControlUserData(panelTitle, "Check_Settings_BackgrndDataAcq", "oldState", num2str(checkedState))

		SetCheckBoxState(panelTitle, "Check_Settings_BkgTP", CHECKBOX_SELECTED)
		SetCheckBoxState(panelTitle, "Check_Settings_BackgrndDataAcq", CHECKBOX_SELECTED)
	else
		EnableListOfControls(panelTitle, "Check_Settings_BkgTP;Check_Settings_BackgrndDataAcq")
		checkedState = str2num(GetUserData(panelTitle, "Check_Settings_BkgTP", "oldState"))
		SetCheckBoxState(panelTitle, "Check_Settings_BkgTP", checkedState)
		checkedState = str2num(GetUserData(panelTitle, "Check_Settings_BackgrndDataAcq", "oldState"))
		SetCheckBoxState(panelTitle, "Check_Settings_BackgrndDataAcq", checkedState)
	endif

	SetCheckBoxState(panelTitle, "check_Settings_MD", useMultiDevice)
End

/// @brief Controls TP Insertion into set sweeps before the sweep begins
Function DAP_CheckProc_InsertTP(cba) : CheckBoxControl
	struct WMCheckBoxAction &cba

	string panelTitle

	switch(cba.eventCode)
		case 2:
			DAP_UpdateOnsetDelay(cba.win)
		break
	endswitch

	return 0
End

/// @brief Update the onset delay due to the `Insert TP` setting
Function DAP_UpdateOnsetDelay(panelTitle)
	string panelTitle

	variable pulseDuration, baselineFrac
	variable testPulseDurWithBL

	if(GetCheckBoxState(panelTitle, "Check_Settings_InsertTP"))
		pulseDuration = GetSetVariable(panelTitle, "SetVar_DataAcq_TPDuration")
		baselineFrac = GetSetVariable(panelTitle, "SetVar_DataAcq_TPBaselinePerc") / 100
		testPulseDurWithBL = TP_CalculateTestPulseLength(pulseDuration, baselineFrac)
	else
		testPulseDurWithBL = 0
	endif

	SetValDisplaySingleVariable(paneltitle, "valdisp_DataAcq_OnsetDelayAuto", testPulseDurWithBL)
End

Function DAP_SetVarProc_TestPulseSett(sva) : SetVariableControl
	struct WMSetVariableAction &sva
	
	variable TPState
	
	switch(sva.eventCode)
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			TPState = TP_StopTestPulse(sva.win)
			DAP_UpdateOnsetDelay(sva.win)
			TP_RestartTestPulse(sva.win, TPState)
			break
	endswitch

	return 0
End

Function DAP_UnlockAllDevices()

	string list = GetListOfLockedDevices()
	string win
	variable i, numItems

	// unlock the first ITC1600 device as that might be yoking other devices
	if(WhichListItem(ITC1600_FIRST_DEVICE,list) != -1)
		HSU_UnlockDevice(ITC1600_FIRST_DEVICE)
	endif

	// refetch the, possibly changed, list of locked devices and unlock them all
	list = GetListOfLockedDevices()
	numItems = ItemsInList(list)
	for(i=0; i < numItems; i+=1)
		win = StringFromList(i, list)
		HSU_UnlockDevice(win)
	endfor
End

Function DAP_CheckProc_RepeatedAcq(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	switch(cba.eventCode)
		case 2: // mouse up
			DAP_UpdateSweepSetVariables(cba.win)
			DAP_SyncGuiFromLeaderToFollower(cba.win)
			break
	endswitch

	return 0
End

Function DAP_CheckProc_DistributedAcq(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	switch(cba.eventCode)
		case 2: // mouse up
			DAP_SyncGuiFromLeaderToFollower(cba.win)
			break
	endswitch

	return 0
End

Function DAP_SetVarProc_ITI(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			DAP_SyncGuiFromLeaderToFollower(sva.win)
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function DAP_ButtonProc_TestPulse(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	string panelTitle

	switch(ba.eventcode)
		case 2:
			panelTitle = ba.win

			AbortOnValue HSU_DeviceIsUnlocked(panelTitle), 1

			NVAR DataAcqState = $GetDataAcqState(panelTitle)

			// if data acquisition is currently running we just
			// want just call TP_StartTestPulse* which automatically
			// ends DAQ
			if(!DataAcqState && TP_CheckIfTestpulseIsRunning(panelTitle))
				TP_StopTestPulse(panelTitle)
			elseif(GetCheckBoxState(panelTitle, "check_Settings_MD"))
				TP_StartTestPulseMultiDevice(panelTitle)
			else
				TP_StartTestPulseSingleDevice(panelTitle)
			endif
			break
	endswitch

	return 0
End

/// @brief Return the comment panel name
Function/S DAP_GetCommentPanel(panelTitle)
	string panelTitle

	return panelTitle + "#" + COMMENT_PANEL
End

/// @brief Return the full window path to the comment notebook
Function/S  DAP_GetCommentNotebook(panelTitle)
	string panelTitle

	return DAP_GetCommentPanel(panelTitle) + "#" + COMMENT_PANEL_NOTEBOOK
End

/// @brief Create the comment panel
static Function DAP_OpenCommentPanel(panelTitle)
	string panelTitle

	string commentPanel, commentNotebook

	AbortOnValue HSU_DeviceIsUnlocked(panelTitle), 1

	commentPanel = DAP_GetCommentPanel(panelTitle)
	if(windowExists(commentPanel))
		return NaN
	endif

	commentNotebook = DAP_GetCommentNotebook(panelTitle)

	NewPanel/HOST=$panelTitle/N=$COMMENT_PANEL/EXT=2/W=(0,0,483,373)
	NewNotebook/HOST=$commentPanel/F=0/N=$COMMENT_PANEL_NOTEBOOK/FG=(FL,FT,FR,FB)
	SetWindow $commentPanel, hook(mainHook)=DAP_CommentPanelHook

	SVAR userComment = $GetUserComment(panelTitle)
	Notebook $commentNotebook, text=userComment
End

Function DAP_ButtonProc_OpenCommentNB(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	string panelTitle

	switch(ba.eventCode)
		case 2: // mouse up
			panelTitle = ba.win

			AbortOnValue HSU_DeviceIsUnlocked(panelTitle), 1
			DAP_AddUserComment(panelTitle)
			break
	endswitch

	return 0
End

static Function/S DAP_FormatCommentString(panelTitle, comment, sweepNo)
	string panelTitle
	string comment
	variable sweepNo

	string str, contents, commentNotebook
	variable length

	ASSERT(!IsEmpty(comment), "Comment can not be empty")

	sprintf str, "%s, % 5d: %s\r", GetTimeStamp(humanReadable=1), sweepNo, comment

	DAP_OpenCommentPanel(panelTitle)
	commentNotebook = DAP_GetCommentNotebook(panelTitle)
	Notebook $commentNotebook selection={endOfFile,endOfFile}, findText={"",1}
	Notebook $commentNotebook getData=2
	contents = S_value

	// add a carriage return if the last line does not end with one
	length = strlen(contents)
	if(length > 0 && cmpstr(contents[length - 1], "\r"))
		str = "\r" + str
	endif

	return str
End

/// @brief Add the current user comment of the previous sweep
///        to the comment notebook and to the labnotebook.
///
/// The `SetVariable` for the user comment is also cleared
Function DAP_AddUserComment(panelTitle)
	string panelTitle

	string commentNotebook, comment, formattedComment
	variable sweepNo

	DAP_OpenCommentPanel(panelTitle)

	sweepNo = AFH_GetLastSweepAcquired(panelTitle)
	comment = GetSetVariableString(panelTitle, "SetVar_DataAcq_Comment")

	if(isEmpty(comment))
		return NaN
	endif

	formattedComment = DAP_FormatCommentString(panelTitle, comment, sweepNo)

	commentNotebook = DAP_GetCommentNotebook(panelTitle)
	Notebook $commentNotebook text=formattedComment
	Notebook $commentNotebook selection={endOfFile,endOfFile}, findText={"",1}

	// after writing the user comment, clear it
	ED_WriteUserCommentToLabNB(panelTitle, comment, sweepNo)
	SetSetVariableString(panelTitle, "SetVar_DataAcq_Comment", "")
End

/// @brief Make the comment notebook read-only
Function DAP_LockCommentNotebook(panelTitle)
	string panelTitle

	string commentPanel, commentNotebook

	commentPanel = DAP_GetCommentPanel(panelTitle)
	if(!windowExists(commentPanel))
		return NaN
	endif

	commentNotebook = DAP_GetCommentNotebook(panelTitle)
	Notebook $commentNotebook, writeProtect=1, changeableByCommandOnly=1
	DoWindow/W=$commentPanel/T $COMMENT_PANEL, COMMENT_PANEL + " (Lock device to make it writeable again)"
End

/// @brief Make the comment notebook writeable
Function DAP_UnlockCommentNotebook(panelTitle)
	string panelTitle

	string commentPanel, commentNotebook

	commentPanel = DAP_GetCommentPanel(panelTitle)
	if(!windowExists(commentPanel))
		return NaN
	endif

	commentNotebook = DAP_GetCommentNotebook(panelTitle)
	Notebook $commentNotebook, writeProtect=0, changeableByCommandOnly=0

	DoWindow/W=$commentPanel/T $COMMENT_PANEL, COMMENT_PANEL
End

/// @brief Clear the comment notebook's content and the serialized string
Function DAP_ClearCommentNotebook(panelTitle)
	string panelTitle

	string commentPanel, commentNotebook

	SVAR userComment = $GetUserComment(panelTitle)
	userComment = ""

	commentPanel = DAP_GetCommentPanel(panelTitle)
	if(!windowExists(commentPanel))
		return NaN
	endif

	commentNotebook = DAP_GetCommentNotebook(panelTitle)
	Notebook $commentNotebook selection={startOfFile, endOfFile}
	Notebook $commentNotebook, text=""
End

/// @brief Serialize all comment notebooks
Function DAP_SerializeAllCommentNBs()

	string list = GetListOfLockedDevices()
	CallFunctionForEachListItem(DAP_SerializeCommentNotebook, list)
End

/// @brief Copy the contents of the comment notebook to the user comment string
Function DAP_SerializeCommentNotebook(panelTitle)
	string panelTitle

	string commentPanel, commentNotebook

	commentPanel = DAP_GetCommentPanel(panelTitle)
	if(!windowExists(commentPanel))
		return NaN
	endif

	commentNotebook = DAP_GetCommentNotebook(panelTitle)
	Notebook $commentNotebook selection={startOfFile, endOfFile}
	GetSelection notebook, $commentNotebook, 2

	if(isEmpty(S_Selection))
		return NaN
	endif

	SVAR userComment = $GetUserComment(panelTitle)
	userComment = S_Selection

	// move selection to end of file
	Notebook $commentNotebook selection={endOfFile,endOfFile}, findText={"",1}
End

Function DAP_CommentPanelHook(s)
	STRUCT WMWinHookStruct &s

	variable hookResult
	string panelTitle

	switch(s.eventCode)
		case 2: // kill
			hookResult = 1
			panelTitle = GetMainWindow(s.winName)

			if(!HSU_DeviceIsUnlocked(panelTitle, silentCheck=1))
				DAP_SerializeCommentNotebook(panelTitle)
			endif
			break
	endswitch

	return hookResult		// 0 if nothing done, else 1
End

Function DAP_SetVarProc_TPAmp(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			Variable TPState = TP_StopTestPulse(sva.win)
			TP_RestartTestPulse(sva.win, TPState)
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

/// @brief Records the state of the DA_ephys panel into the GUI state wave
Function DAP_RecordDA_EphysGuiState(panelTitle)
	string panelTitle
	Wave GUIState = GetDA_EphysGuiStateNum(panelTitle)

	GUIState[0, NUM_HEADSTAGES - 1][%HSState] = DC_ControlStatusWave(panelTitle, CHANNEL_TYPE_HEADSTAGE)[p]
	GUIState[0, NUM_HEADSTAGES - 1][%HSMode] = DAP_GetAllHSMode(panelTitle)[p]
	
	GUIState[0, NUM_DA_TTL_CHANNELS - 1][%DAState] = DC_ControlStatusWave(panelTitle, CHANNEL_TYPE_DAC)[p]
	GUIState[0, NUM_DA_TTL_CHANNELS - 1][%DAGain] = GetAllDAEphysSetVar(panelTitle, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_GAIN)[p]
	GUIState[0, NUM_DA_TTL_CHANNELS - 1][%DAScale] = GetAllDAEphysSetVar(panelTitle, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_SCALE)[p]
	GUIState[0, NUM_DA_TTL_CHANNELS - 1][%DAStartIndex] = GetAllDAEphysPopMenuIndex(panelTitle, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE)[p]
	GUIState[0, NUM_DA_TTL_CHANNELS - 1][%DAEndIndex] = GetAllDAEphysPopMenuIndex(panelTitle, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_INDEX_END)[p]
	
	GUIState[0, NUM_AD_CHANNELS - 1][%ADState] = DC_ControlStatusWave(panelTitle, CHANNEL_TYPE_ADC)[p]
	GUIState[0, NUM_AD_CHANNELS - 1][%ADGain] = GetAllDAEphysSetVar(panelTitle, CHANNEL_TYPE_ADC, CHANNEL_CONTROL_GAIN)[p]
	
	GUIState[0, NUM_DA_TTL_CHANNELS - 1][%TTLState] = DC_ControlStatusWave(panelTitle, CHANNEL_TYPE_TTL)[p]
	GUIState[0, NUM_DA_TTL_CHANNELS - 1][%TTLStartIndex] = GetAllDAEphysPopMenuIndex(panelTitle, CHANNEL_TYPE_TTL, CHANNEL_CONTROL_WAVE)[p]
	GUIState[0, NUM_DA_TTL_CHANNELS - 1][%TTLEndIndex] = GetAllDAEphysPopMenuIndex(panelTitle, CHANNEL_TYPE_TTL, CHANNEL_CONTROL_INDEX_END)[p]

	GUIState[0, NUM_ASYNC_CHANNELS - 1][%AsyncState] = DC_ControlStatusWave(panelTitle, CHANNEL_TYPE_ASYNC)[p]
	GUIState[0, NUM_ASYNC_CHANNELS - 1][%AsyncGain] = GetAllDAEphysSetVar(panelTitle, CHANNEL_TYPE_ASYNC, CHANNEL_CONTROL_GAIN)[p]

	GUIState[0, NUM_ASYNC_CHANNELS - 1][%AlarmState] = DC_ControlStatusWave(panelTitle, CHANNEL_TYPE_ALARM)[p]
	GUIState[0, NUM_ASYNC_CHANNELS - 1][%AlarmMin] = GetAllDAEphysSetVar(panelTitle, CHANNEL_TYPE_ASYNC, CHANNEL_CONTROL_ALARM_MIN)[p]
	GUIState[0, NUM_ASYNC_CHANNELS - 1][%AlarmMax] = GetAllDAEphysSetVar(panelTitle, CHANNEL_TYPE_ASYNC, CHANNEL_CONTROL_ALARM_MAX)[p]
End

/// @brief Return the mode of all DA_Ephys panel headstages
Function/Wave DAP_GetAllHSMode(panelTitle)
	string panelTitle

	variable i, headStage, clampMode
	string ctrl

	Make/FREE/N=(NUM_HEADSTAGES) Mode
	for(i = 0; i < NUM_HEADSTAGES; i+=1)
		ctrl = GetPanelControl(i, CHANNEL_TYPE_HEADSTAGE, CHANNEL_CONTROL_CHECK)
		DAP_GetInfoFromControl(panelTitle, ctrl, clampMode, headStage)
		ASSERT(headStage == i, "Unexpected value")
		Mode[i] = clampMode
	endfor

	return Mode
End

/// @returns the mode of the headstage defined in the locked DA_ephys panel,
///          can be V_CLAMP_MODE or I_CLAMP_MODE or NC
Function DAP_MIESHeadstageMode(panelTitle, headStage)
	string panelTitle
	variable headStage  // range: [0, NUM_HEADSTAGES[
						
	return GetDA_EphysGuiStateNum(panelTitle)[headStage][%HSMode]
End

Function DAP_Activate_Manips(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	string panelTitle

	switch(cba.eventCode)
		case 2: // mouse up
			panelTitle = cba.win
			if(cba.checked)
				EnableControl(panelTitle, "popup_Settings_Manip_MSSMnipLst")
			else
				DisableControl(panelTitle, "popup_Settings_Manip_MSSMnipLst")
			endif
			break
	endswitch

	return 0
End

/// @brief Create a new DA_Ephys panel
///
/// @returns panel name
Function/S DAP_CreateDAEphysPanel()

	string panel

	Execute "DA_Ephys()"

	panel = GetCurrentWindow()
	SCOPE_OpenScopeWindow(panel)
	SetWindow $panel, userData(panelVersion) = num2str(DA_EPHYS_PANEL_VERSION)

	return panel
End

/// @brief Returns the headstage State
Function DAP_GetHSState(panelTitle, headStage)
	string panelTitle
	variable headStage

	WAVE wv = GetDA_EphysGuiStateNum(panelTitle)
	return wv[headStage][%HSState]
End

/// @brief	Sets the locked indexing logic checkbox states
Function DAP_CheckProc_LockedLogic(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	switch( cba.eventCode )
		case 2: // mouse up
			string checkBoxPartener = SelectString(cmpstr(cba.ctrlName, "check_Settings_Option_3"),"check_Settings_SetOption_5","check_Settings_Option_3")
			ToggleCheckBoxes(cba.win, cba.ctrlName, checkBoxPartener, cba.checked)
			EqualizeCheckBoxes(cba.win, "check_Settings_Option_3", "Check_DataAcq1_IndexingLocked", getCheckBoxState(cba.win, "check_Settings_Option_3"))
			if(cmpstr(cba.win, "check_Settings_Option_3") == 0 && cba.checked)
				SetCheckBoxState(cba.win, "Check_DataAcq_Indexing", 1)
			endif
			break
	endswitch

	return 0
End

/// @brief Extracts `channelType`, `controlType` and the control index from `ctrl`
///
/// Counterpart to GetPanelControl()
Function DAP_ParsePanelControl(ctrl, idx, channelType, controlType)
	string ctrl
	variable &idx, &channelType, &controlType

	string elem0, elem1
	variable numUnderlines

	idx         = NaN
	channelType = NaN
	controlType = NaN

	ASSERT(!isEmpty(ctrl), "Empty control")
	numUnderlines = ItemsInList(ctrl, "_")
	ASSERT(numUnderlines >= 2, "Unexpected control naming scheme")

	idx = str2num(StringFromList(numUnderlines - 1, ctrl, "_"))
	ASSERT(IsFinite(idx), "Non-finite control index")

	elem0 = StringFromList(0, ctrl, "_")
	elem1 = StringFromList(1, ctrl, "_")

	strswitch(elem0)
		case "Wave":
			controlType = CHANNEL_CONTROL_WAVE
			break
		case "IndexEnd":
			controlType = CHANNEL_CONTROL_INDEX_END
			break
		case "Unit":
			controlType = CHANNEL_CONTROL_UNIT
			break
		case "Gain":
			controlType = CHANNEL_CONTROL_GAIN
			break
		case "Scale":
			controlType = CHANNEL_CONTROL_SCALE
			break
		case "Check":
			controlType = CHANNEL_CONTROL_CHECK
			break
		case "Min":
			controlType = CHANNEL_CONTROL_ALARM_MIN
			break
		case "Max":
			controlType = CHANNEL_CONTROL_ALARM_MAX
			break
		default:
			ASSERT(0, "Invalid controlType")
			break
	endswitch

	strswitch(elem1)
		case "DataAcqHS":
			channelType = CHANNEL_TYPE_HEADSTAGE
			break
		case "DA":
			channelType = CHANNEL_TYPE_DAC
			break
		case "AD":
			channelType = CHANNEL_TYPE_ADC
			break
		case "TTL":
			channelType = CHANNEL_TYPE_TTL
			break
		case "AsyncAlarm":
			channelType = CHANNEL_TYPE_ALARM
			break
		case "AsyncAD":
			channelType = CHANNEL_TYPE_ASYNC
			break
		default:
			ASSERT(0, "Invalid channelType")
			break
	endswitch
End

/// @brief Update the list of available pressure devices on all locked device panels
Function DAP_UpdateListOfPressureDevices()

	string list, panelTitle
	variable i, numItems

	list = GetListOfLockedDevices()
	numItems = ItemsInList(list)

	for(i = 0; i < numItems; i += 1)
		panelTitle = StringFromList(i, list)
		PGC_SetAndActivateControl(panelTitle, "button_Settings_UpdateDACList")
	endfor
End

/// @brief Return 1 if the DA_Ephys panel is up to date, zero otherwise
Function DAP_PanelIsUpToDate(panelTitle)
	string panelTitle

	variable version

	ASSERT(windowExists(panelTitle), "Non existent window")
	version = str2num(GetUserData(panelTitle, "", "panelVersion"))

	return version == DA_EPHYS_PANEL_VERSION
end
