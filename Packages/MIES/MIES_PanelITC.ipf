#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_DAP
#endif

/// @file MIES_PanelITC.ipf
/// @brief __DAP__ Main data acquisition panel DA_EPHYS

static Constant DATA_ACQU_TAB_NUM         = 0
static Constant HARDWARE_TAB_NUM          = 6

static StrConstant YOKE_LIST_OF_CONTROLS  = "button_Hardware_Lead1600;button_Hardware_Independent;title_hardware_1600inst;title_hardware_Follow;button_Hardware_AddFollower;popup_Hardware_AvailITC1600s;title_hardware_Release;popup_Hardware_YokedDACs;button_Hardware_RemoveYoke"
static StrConstant YOKE_CONTROLS_DISABLE  = "StartTestPulseButton;DataAcquireButton;Button_DataAcq_SkipBackwards;Button_DataAcq_SkipForward"
/// Synced with `desc` in DAP_CheckSettingsAcrossYoked()
static StrConstant YOKE_CONTROLS_DISABLE_AND_LINK = "Check_DataAcq1_RepeatAcq;Check_DataAcq1_DistribDaq;SetVar_DataAcq_dDAQDelay;Check_DataAcq_Indexing;SetVar_DataAcq_ITI;SetVar_DataAcq_SetRepeats;Check_DataAcq_Get_Set_ITI;Setvar_DataAcq_dDAQOptOvPre;Setvar_DataAcq_dDAQOptOvPost;Check_DataAcq1_dDAQOptOv;setvar_DataAcq_dDAQOptOvRes"
static StrConstant FOLLOWER               = "Follower"
static StrConstant LEADER                 = "Leader"

static StrConstant COMMENT_PANEL          = "UserComments"
static StrConstant COMMENT_PANEL_NOTEBOOK = "NB"

static StrConstant AMPLIFIER_DEF_FORMAT   = "AmpNo %d Chan %d"

Window DA_Ephys() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /K=1 /W=(133,441,636,1321)
	ValDisplay valdisp_DataAcq_P_LED_Clear,pos={366.00,298.00},size={86.00,29.00},disable=1
	ValDisplay valdisp_DataAcq_P_LED_Clear,help={"red:user"},userdata(tabnum)=  "0"
	ValDisplay valdisp_DataAcq_P_LED_Clear,userdata(tabcontrol)=  "tab_DataAcq_Pressure"
	ValDisplay valdisp_DataAcq_P_LED_Clear,userdata(ResizeControlsInfo)= A"!!,Hr!!#BO!!#?e!!#=K!!!!\"!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	ValDisplay valdisp_DataAcq_P_LED_Clear,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	ValDisplay valdisp_DataAcq_P_LED_Clear,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	ValDisplay valdisp_DataAcq_P_LED_Clear,frame=0
	ValDisplay valdisp_DataAcq_P_LED_Clear,limits={0,1,0.5},barmisc={0,0},mode= 2,highColor= (65535,16385,16385),lowColor= (61423,61423,61423),zeroColor= (65535,16385,16385)
	ValDisplay valdisp_DataAcq_P_LED_Clear,value= _NUM:0
	ValDisplay valdisp_DataAcq_P_LED_BreakIn,pos={256.00,298.00},size={86.00,29.00},disable=1
	ValDisplay valdisp_DataAcq_P_LED_BreakIn,help={"red:user"}
	ValDisplay valdisp_DataAcq_P_LED_BreakIn,userdata(tabnum)=  "0"
	ValDisplay valdisp_DataAcq_P_LED_BreakIn,userdata(tabcontrol)=  "tab_DataAcq_Pressure"
	ValDisplay valdisp_DataAcq_P_LED_BreakIn,userdata(ResizeControlsInfo)= A"!!,H;!!#BO!!#?e!!#=K!!!!\"!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	ValDisplay valdisp_DataAcq_P_LED_BreakIn,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	ValDisplay valdisp_DataAcq_P_LED_BreakIn,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	ValDisplay valdisp_DataAcq_P_LED_BreakIn,frame=0
	ValDisplay valdisp_DataAcq_P_LED_BreakIn,limits={0,1,0.5},barmisc={0,0},mode= 2,highColor= (65535,16385,16385),lowColor= (61423,61423,61423),zeroColor= (65535,16385,16385)
	ValDisplay valdisp_DataAcq_P_LED_BreakIn,value= _NUM:0
	ValDisplay valdisp_DataAcq_P_LED_Seal,pos={146.00,298.00},size={86.00,29.00},disable=1
	ValDisplay valdisp_DataAcq_P_LED_Seal,help={"red:user"},userdata(tabnum)=  "0"
	ValDisplay valdisp_DataAcq_P_LED_Seal,userdata(tabcontrol)=  "tab_DataAcq_Pressure"
	ValDisplay valdisp_DataAcq_P_LED_Seal,userdata(ResizeControlsInfo)= A"!!,G\"!!#BO!!#?e!!#=K!!!!\"!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	ValDisplay valdisp_DataAcq_P_LED_Seal,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	ValDisplay valdisp_DataAcq_P_LED_Seal,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	ValDisplay valdisp_DataAcq_P_LED_Seal,frame=0
	ValDisplay valdisp_DataAcq_P_LED_Seal,limits={0,1,0.5},barmisc={0,0},mode= 2,highColor= (65535,16385,16385),lowColor= (61423,61423,61423),zeroColor= (65535,16385,16385)
	ValDisplay valdisp_DataAcq_P_LED_Seal,value= _NUM:0
	ValDisplay valdisp_DataAcq_P_LED_Approach,pos={36.00,298.00},size={86.00,29.00},disable=1
	ValDisplay valdisp_DataAcq_P_LED_Approach,help={"red:user"}
	ValDisplay valdisp_DataAcq_P_LED_Approach,userdata(tabnum)=  "0"
	ValDisplay valdisp_DataAcq_P_LED_Approach,userdata(tabcontrol)=  "tab_DataAcq_Pressure"
	ValDisplay valdisp_DataAcq_P_LED_Approach,userdata(ResizeControlsInfo)= A"!!,Ct!!#BO!!#?e!!#=K!!!!\"!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	ValDisplay valdisp_DataAcq_P_LED_Approach,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	ValDisplay valdisp_DataAcq_P_LED_Approach,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	ValDisplay valdisp_DataAcq_P_LED_Approach,frame=0
	ValDisplay valdisp_DataAcq_P_LED_Approach,limits={0,1,0.5},barmisc={0,0},mode= 2,highColor= (65535,16385,16385),lowColor= (61423,61423,61423),zeroColor= (65535,16385,16385)
	ValDisplay valdisp_DataAcq_P_LED_Approach,value= _NUM:0
	ValDisplay valdisp_DataAcq_P_LED_7,pos={407.00,347.00},size={43.00,29.00},disable=1
	ValDisplay valdisp_DataAcq_P_LED_7,help={"Blue:Automated mode, Purple:Manual, Red:User"}
	ValDisplay valdisp_DataAcq_P_LED_7,userdata(tabnum)=  "0"
	ValDisplay valdisp_DataAcq_P_LED_7,userdata(tabcontrol)=  "ADC"
	ValDisplay valdisp_DataAcq_P_LED_7,userdata(ResizeControlsInfo)= A"!!,I1J,hs=J,hne!!#=K!!!!\"!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	ValDisplay valdisp_DataAcq_P_LED_7,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	ValDisplay valdisp_DataAcq_P_LED_7,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	ValDisplay valdisp_DataAcq_P_LED_7,frame=5
	ValDisplay valdisp_DataAcq_P_LED_7,limits={-1,2,0},barmisc={0,0},mode= 2,highColor= (65535,49000,49000),lowColor= (65535,65535,65535),zeroColor= (49151,53155,65535)
	ValDisplay valdisp_DataAcq_P_LED_7,value= _NUM:-1
	ValDisplay valdisp_DataAcq_P_LED_6,pos={364.00,347.00},size={43.00,29.00},disable=1
	ValDisplay valdisp_DataAcq_P_LED_6,help={"Blue:Automated mode, Purple:Manual, Red:User"}
	ValDisplay valdisp_DataAcq_P_LED_6,userdata(tabnum)=  "0"
	ValDisplay valdisp_DataAcq_P_LED_6,userdata(tabcontrol)=  "ADC"
	ValDisplay valdisp_DataAcq_P_LED_6,userdata(ResizeControlsInfo)= A"!!,Hq!!#BgJ,hne!!#=K!!!!\"!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	ValDisplay valdisp_DataAcq_P_LED_6,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	ValDisplay valdisp_DataAcq_P_LED_6,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	ValDisplay valdisp_DataAcq_P_LED_6,frame=5
	ValDisplay valdisp_DataAcq_P_LED_6,limits={-1,2,0},barmisc={0,0},mode= 2,highColor= (65535,49000,49000),lowColor= (65535,65535,65535),zeroColor= (49151,53155,65535)
	ValDisplay valdisp_DataAcq_P_LED_6,value= _NUM:-1
	ValDisplay valdisp_DataAcq_P_LED_5,pos={321.00,347.00},size={43.00,29.00},disable=1
	ValDisplay valdisp_DataAcq_P_LED_5,help={"Blue:Automated mode, Purple:Manual, Red:User"}
	ValDisplay valdisp_DataAcq_P_LED_5,userdata(tabnum)=  "0"
	ValDisplay valdisp_DataAcq_P_LED_5,userdata(tabcontrol)=  "ADC"
	ValDisplay valdisp_DataAcq_P_LED_5,userdata(ResizeControlsInfo)= A"!!,H[J,hs=J,hne!!#=K!!!!\"!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	ValDisplay valdisp_DataAcq_P_LED_5,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	ValDisplay valdisp_DataAcq_P_LED_5,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	ValDisplay valdisp_DataAcq_P_LED_5,frame=5
	ValDisplay valdisp_DataAcq_P_LED_5,limits={-1,2,0},barmisc={0,0},mode= 2,highColor= (65535,49000,49000),lowColor= (65535,65535,65535),zeroColor= (49151,53155,65535)
	ValDisplay valdisp_DataAcq_P_LED_5,value= _NUM:-1
	ValDisplay valdisp_DataAcq_P_LED_4,pos={278.00,347.00},size={43.00,29.00},disable=1
	ValDisplay valdisp_DataAcq_P_LED_4,help={"Blue:Automated mode, Purple:Manual, Red:User"}
	ValDisplay valdisp_DataAcq_P_LED_4,userdata(tabnum)=  "0"
	ValDisplay valdisp_DataAcq_P_LED_4,userdata(tabcontrol)=  "ADC"
	ValDisplay valdisp_DataAcq_P_LED_4,userdata(ResizeControlsInfo)= A"!!,HF!!#BgJ,hne!!#=K!!!!\"!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	ValDisplay valdisp_DataAcq_P_LED_4,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	ValDisplay valdisp_DataAcq_P_LED_4,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	ValDisplay valdisp_DataAcq_P_LED_4,frame=5,valueBackColor=(61423,61423,61423)
	ValDisplay valdisp_DataAcq_P_LED_4,limits={-1,2,0},barmisc={10,0},mode= 2,highColor= (65535,49000,49000),lowColor= (65535,65535,65535),zeroColor= (49151,53155,65535)
	ValDisplay valdisp_DataAcq_P_LED_4,value= _NUM:-1
	ValDisplay valdisp_DataAcq_P_LED_4,limitsBackColor= (61423,61423,61423)
	ValDisplay valdisp_DataAcq_P_LED_3,pos={235.00,347.00},size={43.00,29.00},disable=1
	ValDisplay valdisp_DataAcq_P_LED_3,help={"Blue:Automated mode, Purple:Manual, Red:User"}
	ValDisplay valdisp_DataAcq_P_LED_3,userdata(tabnum)=  "0"
	ValDisplay valdisp_DataAcq_P_LED_3,userdata(tabcontrol)=  "ADC"
	ValDisplay valdisp_DataAcq_P_LED_3,userdata(ResizeControlsInfo)= A"!!,H&!!#BgJ,hne!!#=K!!!!\"!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	ValDisplay valdisp_DataAcq_P_LED_3,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	ValDisplay valdisp_DataAcq_P_LED_3,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	ValDisplay valdisp_DataAcq_P_LED_3,frame=5
	ValDisplay valdisp_DataAcq_P_LED_3,limits={-1,2,0},barmisc={0,0},mode= 2,highColor= (65535,49000,49000),lowColor= (65535,65535,65535),zeroColor= (49151,53155,65535)
	ValDisplay valdisp_DataAcq_P_LED_3,value= _NUM:-1
	ValDisplay valdisp_DataAcq_P_LED_2,pos={192.00,347.00},size={43.00,29.00},disable=1
	ValDisplay valdisp_DataAcq_P_LED_2,help={"Blue:Automated mode, Purple:Manual, Red:User"}
	ValDisplay valdisp_DataAcq_P_LED_2,userdata(tabnum)=  "0"
	ValDisplay valdisp_DataAcq_P_LED_2,userdata(tabcontrol)=  "ADC"
	ValDisplay valdisp_DataAcq_P_LED_2,userdata(ResizeControlsInfo)= A"!!,GP!!#BgJ,hne!!#=K!!!!\"!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	ValDisplay valdisp_DataAcq_P_LED_2,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	ValDisplay valdisp_DataAcq_P_LED_2,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	ValDisplay valdisp_DataAcq_P_LED_2,frame=5
	ValDisplay valdisp_DataAcq_P_LED_2,limits={-1,2,0},barmisc={0,0},mode= 2,highColor= (65278,0,0),lowColor= (0,0,0),zeroColor= (0,0,65535)
	ValDisplay valdisp_DataAcq_P_LED_2,value= _NUM:-1
	ValDisplay valdisp_DataAcq_P_LED_0,pos={106.00,347.00},size={43.00,29.00},disable=1
	ValDisplay valdisp_DataAcq_P_LED_0,help={"Blue:Automated mode, Purple:Manual, Red:User"}
	ValDisplay valdisp_DataAcq_P_LED_0,userdata(tabnum)=  "0"
	ValDisplay valdisp_DataAcq_P_LED_0,userdata(tabcontrol)=  "ADC"
	ValDisplay valdisp_DataAcq_P_LED_0,userdata(ResizeControlsInfo)= A"!!,F9!!#BgJ,hne!!#=K!!!!\"!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	ValDisplay valdisp_DataAcq_P_LED_0,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	ValDisplay valdisp_DataAcq_P_LED_0,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	ValDisplay valdisp_DataAcq_P_LED_0,frame=5
	ValDisplay valdisp_DataAcq_P_LED_0,limits={-1,2,0},barmisc={0,0},mode= 2,highColor= (65278,0,0),lowColor= (0,0,0),zeroColor= (0,0,65535)
	ValDisplay valdisp_DataAcq_P_LED_0,value= _NUM:-1
	ValDisplay valdisp_DataAcq_P_LED_1,pos={149.00,347.00},size={43.00,29.00},disable=1
	ValDisplay valdisp_DataAcq_P_LED_1,help={"Blue:Automated mode, Purple:Manual, Red:User"}
	ValDisplay valdisp_DataAcq_P_LED_1,userdata(tabnum)=  "0"
	ValDisplay valdisp_DataAcq_P_LED_1,userdata(tabcontrol)=  "ADC"
	ValDisplay valdisp_DataAcq_P_LED_1,userdata(ResizeControlsInfo)= A"!!,G%!!#BgJ,hne!!#=K!!!!\"!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	ValDisplay valdisp_DataAcq_P_LED_1,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	ValDisplay valdisp_DataAcq_P_LED_1,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	ValDisplay valdisp_DataAcq_P_LED_1,frame=5
	ValDisplay valdisp_DataAcq_P_LED_1,limits={-1,2,0},barmisc={0,0},mode= 2,highColor= (65278,0,0),lowColor= (0,0,0),zeroColor= (0,0,65535)
	ValDisplay valdisp_DataAcq_P_LED_1,value= _NUM:-1
	ValDisplay valdisp_DataAcq_P_3,pos={239.00,351.00},size={35.00,21.00},bodyWidth=35,disable=1
	ValDisplay valdisp_DataAcq_P_3,userdata(tabcontrol)=  "tab_DataAcq_Pressure"
	ValDisplay valdisp_DataAcq_P_3,userdata(ResizeControlsInfo)= A"!!,H*!!#BiJ,hnE!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	ValDisplay valdisp_DataAcq_P_3,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	ValDisplay valdisp_DataAcq_P_3,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	ValDisplay valdisp_DataAcq_P_3,fSize=14,frame=0,fStyle=0
	ValDisplay valdisp_DataAcq_P_3,valueBackColor=(65535,65535,65535,0)
	ValDisplay valdisp_DataAcq_P_3,limits={0,0,0},barmisc={0,1000},value= #"0.00"
	GroupBox group_DataAcq_WholeCell,pos={41.00,200.00},size={150.00,62.00},disable=1,title="       Whole Cell"
	GroupBox group_DataAcq_WholeCell,userdata(tabnum)=  "0"
	GroupBox group_DataAcq_WholeCell,userdata(tabcontrol)=  "tab_DataAcq_Amp"
	GroupBox group_DataAcq_WholeCell,userdata(ResizeControlsInfo)= A"!!,D3!!#AW!!#A%!!#?1z!!,c)Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
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
	PopupMenu Wave_DA_00,mode=1,popvalue="- none -",value= #"\"- none -;\"+ReturnListOfAllStimSets(0,\"*DA*\")"
	PopupMenu Wave_DA_01,pos={140.00,121.00},size={138.00,19.00},bodyWidth=125,disable=1,proc=DAP_PopMenuChkProc_StimSetList,title="/V"
	PopupMenu Wave_DA_01,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	PopupMenu Wave_DA_01,userdata(ResizeControlsInfo)= A"!!,Fq!!#@V!!#@n!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Wave_DA_01,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Wave_DA_01,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Wave_DA_01,fSize=10
	PopupMenu Wave_DA_01,mode=1,popvalue="- none -",value= #"\"- none -;\"+ReturnListOfAllStimSets(0,\"*DA*\")"
	PopupMenu Wave_DA_02,pos={140.00,167.00},size={138.00,19.00},bodyWidth=125,disable=1,proc=DAP_PopMenuChkProc_StimSetList,title="/V"
	PopupMenu Wave_DA_02,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	PopupMenu Wave_DA_02,userdata(ResizeControlsInfo)= A"!!,Fq!!#A6!!#@n!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Wave_DA_02,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Wave_DA_02,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Wave_DA_02,fSize=10
	PopupMenu Wave_DA_02,mode=1,popvalue="- none -",value= #"\"- none -;\"+ReturnListOfAllStimSets(0,\"*DA*\")"
	PopupMenu Wave_DA_03,pos={140.00,214.00},size={138.00,19.00},bodyWidth=125,disable=1,proc=DAP_PopMenuChkProc_StimSetList,title="/V"
	PopupMenu Wave_DA_03,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	PopupMenu Wave_DA_03,userdata(ResizeControlsInfo)= A"!!,Fq!!#Ae!!#@n!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Wave_DA_03,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Wave_DA_03,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Wave_DA_03,fSize=10
	PopupMenu Wave_DA_03,mode=1,popvalue="- none -",value= #"\"- none -;\"+ReturnListOfAllStimSets(0,\"*DA*\")"
	PopupMenu Wave_DA_04,pos={140.00,260.00},size={138.00,19.00},bodyWidth=125,disable=1,proc=DAP_PopMenuChkProc_StimSetList,title="/V"
	PopupMenu Wave_DA_04,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	PopupMenu Wave_DA_04,userdata(ResizeControlsInfo)= A"!!,Fq!!#B<!!#@n!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Wave_DA_04,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Wave_DA_04,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Wave_DA_04,fSize=10
	PopupMenu Wave_DA_04,mode=1,popvalue="- none -",value= #"\"- none -;\"+ReturnListOfAllStimSets(0,\"*DA*\")"
	PopupMenu Wave_DA_05,pos={140.00,307.00},size={138.00,19.00},bodyWidth=125,disable=1,proc=DAP_PopMenuChkProc_StimSetList,title="/V"
	PopupMenu Wave_DA_05,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	PopupMenu Wave_DA_05,userdata(ResizeControlsInfo)= A"!!,Fq!!#BSJ,hqD!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Wave_DA_05,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Wave_DA_05,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Wave_DA_05,fSize=10
	PopupMenu Wave_DA_05,mode=1,popvalue="- none -",value= #"\"- none -;\"+ReturnListOfAllStimSets(0,\"*DA*\")"
	PopupMenu Wave_DA_06,pos={140.00,353.00},size={138.00,19.00},bodyWidth=125,disable=1,proc=DAP_PopMenuChkProc_StimSetList,title="/V"
	PopupMenu Wave_DA_06,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	PopupMenu Wave_DA_06,userdata(ResizeControlsInfo)= A"!!,Fq!!#BjJ,hqD!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Wave_DA_06,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Wave_DA_06,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Wave_DA_06,fSize=10
	PopupMenu Wave_DA_06,mode=1,popvalue="- none -",value= #"\"- none -;\"+ReturnListOfAllStimSets(0,\"*DA*\")"
	PopupMenu Wave_DA_07,pos={140.00,400.00},size={138.00,19.00},bodyWidth=125,disable=1,proc=DAP_PopMenuChkProc_StimSetList,title="/V"
	PopupMenu Wave_DA_07,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	PopupMenu Wave_DA_07,userdata(ResizeControlsInfo)= A"!!,Fq!!#C-!!#@n!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Wave_DA_07,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Wave_DA_07,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Wave_DA_07,fSize=10
	PopupMenu Wave_DA_07,mode=1,popvalue="- none -",value= #"\"- none -;\"+ReturnListOfAllStimSets(0,\"*DA*\")"
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
	SetVariable SetVar_DataAcq_Comment,pos={48.00,781.00},size={362.00,14.00},disable=1,title="Comment"
	SetVariable SetVar_DataAcq_Comment,help={"Appends a comment to wave note of next sweep"}
	SetVariable SetVar_DataAcq_Comment,userdata(tabnum)=  "0"
	SetVariable SetVar_DataAcq_Comment,userdata(tabcontrol)=  "ADC"
	SetVariable SetVar_DataAcq_Comment,userdata(ResizeControlsInfo)= A"!!,DO!!#DS5QF0Z!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_DataAcq_Comment,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_DataAcq_Comment,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_DataAcq_Comment,fSize=8,value= _STR:""
	Button DataAcquireButton,pos={44.00,799.00},size={405.00,42.00},disable=1,proc=DAP_ButtonProc_AcquireData,title="\\Z14\\f01Acquire\rData"
	Button DataAcquireButton,userdata(tabnum)=  "0",userdata(tabcontrol)=  "ADC"
	Button DataAcquireButton,userdata(ResizeControlsInfo)= A"!!,D?!!#DW^]6aEJ,hnaz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button DataAcquireButton,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button DataAcquireButton,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	Button DataAcquireButton,labelBack=(60928,60928,60928)
	CheckBox Check_DataAcq1_RepeatAcq,pos={32.00,644.00},size={88.00,15.00},disable=1,proc=DAP_CheckProc_RepeatedAcq,title="Repeated Acq"
	CheckBox Check_DataAcq1_RepeatAcq,help={"Determines number of times a set is repeated, or if indexing is on, the number of times a group of sets in repeated"}
	CheckBox Check_DataAcq1_RepeatAcq,userdata(tabnum)=  "0"
	CheckBox Check_DataAcq1_RepeatAcq,userdata(tabcontrol)=  "ADC"
	CheckBox Check_DataAcq1_RepeatAcq,userdata(ResizeControlsInfo)= A"!!,Cd!!#D1!!#?i!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_DataAcq1_RepeatAcq,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_DataAcq1_RepeatAcq,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_DataAcq1_RepeatAcq,value= 1
	SetVariable SetVar_DataAcq_ITI,pos={60.00,700.00},size={80.00,18.00},bodyWidth=35,disable=1,proc=DAP_SetVarProc_SyncCtrl,title="\\JCITl (sec)"
	SetVariable SetVar_DataAcq_ITI,userdata(tabnum)=  "0"
	SetVariable SetVar_DataAcq_ITI,userdata(tabcontrol)=  "ADC"
	SetVariable SetVar_DataAcq_ITI,userdata(ResizeControlsInfo)= A"!!,E*!!#D?!!#?Y!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_DataAcq_ITI,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_DataAcq_ITI,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_DataAcq_ITI,limits={0,inf,1},value= _NUM:0
	Button StartTestPulseButton,pos={43.00,444.00},size={405.00,40.00},disable=1,proc=DAP_ButtonProc_TestPulse,title="\\Z14\\f01Start Test \rPulse"
	Button StartTestPulseButton,help={"Starts generating test pulses. Can be stopped by pressing the Escape key."}
	Button StartTestPulseButton,userdata(tabnum)=  "0",userdata(tabcontrol)=  "ADC"
	Button StartTestPulseButton,userdata(ResizeControlsInfo)= A"!!,D;!!#CC!!#C/J,hnYz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button StartTestPulseButton,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button StartTestPulseButton,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_DataAcqHS_00,pos={129.00,86.00},size={21.00,15.00},disable=1,proc=DAP_CheckProc_HedstgeChck,title="0"
	CheckBox Check_DataAcqHS_00,userdata(tabnum)=  "0",userdata(tabcontrol)=  "ADC"
	CheckBox Check_DataAcqHS_00,userdata(ResizeControlsInfo)= A"!!,Ff!!#?e!!#<`!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_DataAcqHS_00,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_DataAcqHS_00,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_DataAcqHS_00,labelBack=(65280,0,0),value= 0
	SetVariable SetVar_DataAcq_TPDuration,pos={46.00,417.00},size={127.00,18.00},bodyWidth=50,disable=1,proc=DAP_SetVarProc_TestPulseSett,title="Duration (ms)"
	SetVariable SetVar_DataAcq_TPDuration,help={"Duration of the testpulse in milliseconds"}
	SetVariable SetVar_DataAcq_TPDuration,userdata(tabnum)=  "0"
	SetVariable SetVar_DataAcq_TPDuration,userdata(tabcontrol)=  "ADC"
	SetVariable SetVar_DataAcq_TPDuration,userdata(ResizeControlsInfo)= A"!!,DG!!#C5J,hq8!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_DataAcq_TPDuration,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_DataAcq_TPDuration,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_DataAcq_TPDuration,limits={1,inf,5},value= _NUM:10
	SetVariable SetVar_DataAcq_TPBaselinePerc,pos={179.00,417.00},size={118.00,18.00},bodyWidth=50,disable=1,proc=DAP_SetVarProc_TestPulseSett,title="Baseline (%)"
	SetVariable SetVar_DataAcq_TPBaselinePerc,help={"Length of the baseline before and after the testpulse, in parts of the total testpulse duration"}
	SetVariable SetVar_DataAcq_TPBaselinePerc,userdata(tabnum)=  "0"
	SetVariable SetVar_DataAcq_TPBaselinePerc,userdata(tabcontrol)=  "ADC"
	SetVariable SetVar_DataAcq_TPBaselinePerc,userdata(ResizeControlsInfo)= A"!!,GC!!#C5J,hq&!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_DataAcq_TPBaselinePerc,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_DataAcq_TPBaselinePerc,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_DataAcq_TPBaselinePerc,limits={25,49,1},value= _NUM:25
	SetVariable SetVar_DataAcq_TPAmplitude,pos={308.00,417.00},size={69.00,18.00},bodyWidth=50,disable=1,proc=DAP_SetVarProc_TPAmp,title="VC"
	SetVariable SetVar_DataAcq_TPAmplitude,help={"Amplitude of the testpulse in voltage clamp mode"}
	SetVariable SetVar_DataAcq_TPAmplitude,userdata(tabnum)=  "0"
	SetVariable SetVar_DataAcq_TPAmplitude,userdata(tabcontrol)=  "ADC"
	SetVariable SetVar_DataAcq_TPAmplitude,userdata(ResizeControlsInfo)= A"!!,HU!!#C5J,hon!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
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
	PopupMenu Wave_TTL_00,userdata(ResizeControlsInfo)= A"!!,F3!!#?O!!#@^!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Wave_TTL_00,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Wave_TTL_00,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Wave_TTL_00,mode=1,popvalue="- none -",value= #"\"- none -;\"+ReturnListOfAllStimSets(1,\"*TTL*\")"
	PopupMenu Wave_TTL_01,pos={103.00,121.00},size={125.00,19.00},bodyWidth=125,disable=1,proc=DAP_PopMenuChkProc_StimSetList
	PopupMenu Wave_TTL_01,userdata(tabnum)=  "3",userdata(tabcontrol)=  "ADC"
	PopupMenu Wave_TTL_01,userdata(ResizeControlsInfo)= A"!!,F3!!#@V!!#@^!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Wave_TTL_01,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Wave_TTL_01,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Wave_TTL_01,mode=1,popvalue="- none -",value= #"\"- none -;\"+ReturnListOfAllStimSets(1,\"*TTL*\")"
	PopupMenu Wave_TTL_02,pos={103.00,167.00},size={125.00,19.00},bodyWidth=125,disable=1,proc=DAP_PopMenuChkProc_StimSetList
	PopupMenu Wave_TTL_02,userdata(tabnum)=  "3",userdata(tabcontrol)=  "ADC"
	PopupMenu Wave_TTL_02,userdata(ResizeControlsInfo)= A"!!,F3!!#A6!!#@^!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Wave_TTL_02,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Wave_TTL_02,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Wave_TTL_02,mode=1,popvalue="- none -",value= #"\"- none -;\"+ReturnListOfAllStimSets(1,\"*TTL*\")"
	PopupMenu Wave_TTL_03,pos={103.00,214.00},size={125.00,19.00},bodyWidth=125,disable=1,proc=DAP_PopMenuChkProc_StimSetList
	PopupMenu Wave_TTL_03,userdata(tabnum)=  "3",userdata(tabcontrol)=  "ADC"
	PopupMenu Wave_TTL_03,userdata(ResizeControlsInfo)= A"!!,F3!!#Ae!!#@^!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Wave_TTL_03,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Wave_TTL_03,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Wave_TTL_03,mode=1,popvalue="- none -",value= #"\"- none -;\"+ReturnListOfAllStimSets(1,\"*TTL*\")"
	PopupMenu Wave_TTL_04,pos={103.00,260.00},size={125.00,19.00},bodyWidth=125,disable=1,proc=DAP_PopMenuChkProc_StimSetList
	PopupMenu Wave_TTL_04,userdata(tabnum)=  "3",userdata(tabcontrol)=  "ADC"
	PopupMenu Wave_TTL_04,userdata(ResizeControlsInfo)= A"!!,F3!!#B<!!#@^!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Wave_TTL_04,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Wave_TTL_04,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Wave_TTL_04,mode=1,popvalue="- none -",value= #"\"- none -;\"+ReturnListOfAllStimSets(1,\"*TTL*\")"
	PopupMenu Wave_TTL_05,pos={103.00,307.00},size={125.00,19.00},bodyWidth=125,disable=1,proc=DAP_PopMenuChkProc_StimSetList
	PopupMenu Wave_TTL_05,userdata(tabnum)=  "3",userdata(tabcontrol)=  "ADC"
	PopupMenu Wave_TTL_05,userdata(ResizeControlsInfo)= A"!!,F3!!#BSJ,hq4!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Wave_TTL_05,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Wave_TTL_05,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Wave_TTL_05,mode=1,popvalue="- none -",value= #"\"- none -;\"+ReturnListOfAllStimSets(1,\"*TTL*\")"
	PopupMenu Wave_TTL_06,pos={103.00,353.00},size={125.00,19.00},bodyWidth=125,disable=1,proc=DAP_PopMenuChkProc_StimSetList
	PopupMenu Wave_TTL_06,userdata(tabnum)=  "3",userdata(tabcontrol)=  "ADC"
	PopupMenu Wave_TTL_06,userdata(ResizeControlsInfo)= A"!!,F3!!#BjJ,hq4!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Wave_TTL_06,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Wave_TTL_06,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Wave_TTL_06,mode=1,popvalue="- none -",value= #"\"- none -;\"+ReturnListOfAllStimSets(1,\"*TTL*\")"
	PopupMenu Wave_TTL_07,pos={103.00,400.00},size={125.00,19.00},bodyWidth=125,disable=1,proc=DAP_PopMenuChkProc_StimSetList
	PopupMenu Wave_TTL_07,userdata(tabnum)=  "3",userdata(tabcontrol)=  "ADC"
	PopupMenu Wave_TTL_07,userdata(ResizeControlsInfo)= A"!!,F3!!#C-!!#@^!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Wave_TTL_07,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Wave_TTL_07,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Wave_TTL_07,mode=1,popvalue="- none -",value= #"\"- none -;\"+ReturnListOfAllStimSets(1,\"*TTL*\")"
	CheckBox Check_Settings_TrigOut,pos={34.00,239.00},size={59.00,15.00},disable=1,title="\\JCTrig Out"
	CheckBox Check_Settings_TrigOut,help={"Turns on TTL pulse at onset of sweep"}
	CheckBox Check_Settings_TrigOut,userdata(tabnum)=  "5"
	CheckBox Check_Settings_TrigOut,userdata(tabcontrol)=  "ADC"
	CheckBox Check_Settings_TrigOut,userdata(ResizeControlsInfo)= A"!!,Cl!!#B)!!#?%!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_Settings_TrigOut,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_Settings_TrigOut,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_Settings_TrigOut,fColor=(65280,43520,0),value= 0
	CheckBox Check_Settings_TrigIn,pos={34.00,262.00},size={49.00,15.00},disable=1,title="\\JCTrig In"
	CheckBox Check_Settings_TrigIn,help={"Starts Data Aquisition with TTL signal to trig in port on rack"}
	CheckBox Check_Settings_TrigIn,userdata(tabnum)=  "5"
	CheckBox Check_Settings_TrigIn,userdata(tabcontrol)=  "ADC"
	CheckBox Check_Settings_TrigIn,userdata(ResizeControlsInfo)= A"!!,Cl!!#B=!!#>R!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_Settings_TrigIn,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_Settings_TrigIn,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_Settings_TrigIn,fColor=(65280,43520,0),value= 0
	SetVariable SetVar_DataAcq_SetRepeats,pos={33.00,680.00},size={107.00,18.00},bodyWidth=35,disable=1,proc=DAP_SetVarProc_TotSweepCount,title="Repeat Set(s)"
	SetVariable SetVar_DataAcq_SetRepeats,help={"This number is set automatically at based on the number of 1d waves contained in the largest set on active DA/TTL channels"}
	SetVariable SetVar_DataAcq_SetRepeats,userdata(tabnum)=  "0"
	SetVariable SetVar_DataAcq_SetRepeats,userdata(tabcontrol)=  "ADC"
	SetVariable SetVar_DataAcq_SetRepeats,userdata(ResizeControlsInfo)= A"!!,Ch!!#D:!!#@:!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_DataAcq_SetRepeats,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_DataAcq_SetRepeats,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_DataAcq_SetRepeats,limits={1,inf,1},value= _NUM:1
	ValDisplay ValDisp_DataAcq_SamplingInt,pos={229.00,574.00},size={30.00,21.00},bodyWidth=30,disable=1
	ValDisplay ValDisp_DataAcq_SamplingInt,userdata(tabnum)=  "0"
	ValDisplay ValDisp_DataAcq_SamplingInt,userdata(tabcontrol)=  "ADC"
	ValDisplay ValDisp_DataAcq_SamplingInt,userdata(ResizeControlsInfo)= A"!!,Gu!!#CtJ,hn)!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	ValDisplay ValDisp_DataAcq_SamplingInt,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	ValDisplay ValDisp_DataAcq_SamplingInt,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	ValDisplay ValDisp_DataAcq_SamplingInt,fSize=14,fStyle=0
	ValDisplay ValDisp_DataAcq_SamplingInt,valueColor=(65535,65535,65535)
	ValDisplay ValDisp_DataAcq_SamplingInt,valueBackColor=(0,0,0)
	ValDisplay ValDisp_DataAcq_SamplingInt,limits={0,0,0},barmisc={0,1000}
	ValDisplay ValDisp_DataAcq_SamplingInt,value= _NUM:0
	SetVariable SetVar_Sweep,pos={211.00,532.00},size={75.00,35.00},bodyWidth=75,disable=1,proc=DAP_SetVarProc_NextSweepLimit
	SetVariable SetVar_Sweep,userdata(tabnum)=  "0",userdata(tabcontrol)=  "ADC"
	SetVariable SetVar_Sweep,userdata(ResizeControlsInfo)= A"!!,Gc!!#Cj!!#?O!!#=oz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
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
	CheckBox Check_Settings_SkipAnalysFuncs,pos={243.00,268.00},size={155.00,15.00},disable=1,proc=DAP_CheckProc_RecordInGuiState,title="Skip analysis function calls"
	CheckBox Check_Settings_SkipAnalysFuncs,help={"Should the analysis functions defined in the stim sets not be called?"}
	CheckBox Check_Settings_SkipAnalysFuncs,userdata(tabnum)=  "5"
	CheckBox Check_Settings_SkipAnalysFuncs,userdata(tabcontrol)=  "ADC"
	CheckBox Check_Settings_SkipAnalysFuncs,userdata(ResizeControlsInfo)= A"!!,H.!!#B@!!#A*!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_Settings_SkipAnalysFuncs,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_Settings_SkipAnalysFuncs,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_Settings_SkipAnalysFuncs,value= 1
	CheckBox Check_AsyncAD_00,pos={172.00,46.00},size={40.00,15.00},disable=1,proc=DAP_CheckProc_RecordInGuiState,title="AD 0"
	CheckBox Check_AsyncAD_00,userdata(tabnum)=  "4",userdata(tabcontrol)=  "ADC"
	CheckBox Check_AsyncAD_00,userdata(ResizeControlsInfo)= A"!!,G<!!#>F!!#>.!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_AsyncAD_00,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_AsyncAD_00,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_AsyncAD_00,value= 0
	CheckBox Check_AsyncAD_01,pos={171.00,97.00},size={40.00,15.00},disable=1,proc=DAP_CheckProc_RecordInGuiState,title="AD 1"
	CheckBox Check_AsyncAD_01,userdata(tabnum)=  "4",userdata(tabcontrol)=  "ADC"
	CheckBox Check_AsyncAD_01,userdata(ResizeControlsInfo)= A"!!,G;!!#@&!!#>.!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_AsyncAD_01,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_AsyncAD_01,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_AsyncAD_01,value= 0
	CheckBox Check_AsyncAD_02,pos={171.00,148.00},size={40.00,15.00},disable=1,proc=DAP_CheckProc_RecordInGuiState,title="AD 2"
	CheckBox Check_AsyncAD_02,userdata(tabnum)=  "4",userdata(tabcontrol)=  "ADC"
	CheckBox Check_AsyncAD_02,userdata(ResizeControlsInfo)= A"!!,G;!!#A#!!#>.!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_AsyncAD_02,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_AsyncAD_02,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_AsyncAD_02,value= 0
	CheckBox Check_AsyncAD_03,pos={171.00,199.00},size={40.00,15.00},disable=1,proc=DAP_CheckProc_RecordInGuiState,title="AD 3"
	CheckBox Check_AsyncAD_03,userdata(tabnum)=  "4",userdata(tabcontrol)=  "ADC"
	CheckBox Check_AsyncAD_03,userdata(ResizeControlsInfo)= A"!!,G;!!#AV!!#>.!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_AsyncAD_03,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_AsyncAD_03,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_AsyncAD_03,value= 0
	CheckBox Check_AsyncAD_04,pos={171.00,250.00},size={40.00,15.00},disable=1,proc=DAP_CheckProc_RecordInGuiState,title="AD 4"
	CheckBox Check_AsyncAD_04,userdata(tabnum)=  "4",userdata(tabcontrol)=  "ADC"
	CheckBox Check_AsyncAD_04,userdata(ResizeControlsInfo)= A"!!,G;!!#B4!!#>.!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_AsyncAD_04,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_AsyncAD_04,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_AsyncAD_04,value= 0
	CheckBox Check_AsyncAD_05,pos={171.00,301.00},size={40.00,15.00},disable=1,proc=DAP_CheckProc_RecordInGuiState,title="AD 5"
	CheckBox Check_AsyncAD_05,userdata(tabnum)=  "4",userdata(tabcontrol)=  "ADC"
	CheckBox Check_AsyncAD_05,userdata(ResizeControlsInfo)= A"!!,G;!!#BPJ,hnY!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_AsyncAD_05,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_AsyncAD_05,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_AsyncAD_05,value= 0
	CheckBox Check_AsyncAD_06,pos={171.00,352.00},size={40.00,15.00},disable=1,proc=DAP_CheckProc_RecordInGuiState,title="AD 6"
	CheckBox Check_AsyncAD_06,userdata(tabnum)=  "4",userdata(tabcontrol)=  "ADC"
	CheckBox Check_AsyncAD_06,userdata(ResizeControlsInfo)= A"!!,G;!!#Bj!!#>.!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_AsyncAD_06,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_AsyncAD_06,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_AsyncAD_06,value= 0
	CheckBox Check_AsyncAD_07,pos={171.00,404.00},size={40.00,15.00},disable=1,proc=DAP_CheckProc_RecordInGuiState,title="AD 7"
	CheckBox Check_AsyncAD_07,userdata(tabnum)=  "4",userdata(tabcontrol)=  "ADC"
	CheckBox Check_AsyncAD_07,userdata(ResizeControlsInfo)= A"!!,G;!!#C/!!#>.!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_AsyncAD_07,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_AsyncAD_07,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_AsyncAD_07,value= 0
	SetVariable Gain_AsyncAD_00,pos={224.00,44.00},size={77.00,18.00},bodyWidth=50,disable=1,title="gain"
	SetVariable Gain_AsyncAD_00,userdata(tabnum)=  "4",userdata(tabcontrol)=  "ADC"
	SetVariable Gain_AsyncAD_00,userdata(ResizeControlsInfo)= A"!!,Gp!!#>>!!#?S!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Gain_AsyncAD_00,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Gain_AsyncAD_00,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Gain_AsyncAD_00,limits={0,inf,1},value= _NUM:1
	SetVariable Gain_AsyncAD_01,pos={224.00,95.00},size={77.00,18.00},bodyWidth=50,disable=1,title="gain"
	SetVariable Gain_AsyncAD_01,userdata(tabnum)=  "4",userdata(tabcontrol)=  "ADC"
	SetVariable Gain_AsyncAD_01,userdata(ResizeControlsInfo)= A"!!,Gp!!#@\"!!#?S!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Gain_AsyncAD_01,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Gain_AsyncAD_01,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Gain_AsyncAD_01,limits={0,inf,1},value= _NUM:1
	SetVariable Gain_AsyncAD_02,pos={224.00,146.00},size={77.00,18.00},bodyWidth=50,disable=1,title="gain"
	SetVariable Gain_AsyncAD_02,userdata(tabnum)=  "4",userdata(tabcontrol)=  "ADC"
	SetVariable Gain_AsyncAD_02,userdata(ResizeControlsInfo)= A"!!,Gp!!#A!!!#?S!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Gain_AsyncAD_02,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Gain_AsyncAD_02,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Gain_AsyncAD_02,limits={0,inf,1},value= _NUM:1
	SetVariable Gain_AsyncAD_03,pos={224.00,197.00},size={77.00,18.00},bodyWidth=50,disable=1,title="gain"
	SetVariable Gain_AsyncAD_03,userdata(tabnum)=  "4",userdata(tabcontrol)=  "ADC"
	SetVariable Gain_AsyncAD_03,userdata(ResizeControlsInfo)= A"!!,Gp!!#AT!!#?S!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Gain_AsyncAD_03,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Gain_AsyncAD_03,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Gain_AsyncAD_03,limits={0,inf,1},value= _NUM:1
	SetVariable Gain_AsyncAD_04,pos={224.00,248.00},size={77.00,18.00},bodyWidth=50,disable=1,title="gain"
	SetVariable Gain_AsyncAD_04,userdata(tabnum)=  "4",userdata(tabcontrol)=  "ADC"
	SetVariable Gain_AsyncAD_04,userdata(ResizeControlsInfo)= A"!!,Gp!!#B2!!#?S!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Gain_AsyncAD_04,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Gain_AsyncAD_04,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Gain_AsyncAD_04,limits={0,inf,1},value= _NUM:1
	SetVariable Gain_AsyncAD_05,pos={224.00,299.00},size={77.00,18.00},bodyWidth=50,disable=1,title="gain"
	SetVariable Gain_AsyncAD_05,userdata(tabnum)=  "4",userdata(tabcontrol)=  "ADC"
	SetVariable Gain_AsyncAD_05,userdata(ResizeControlsInfo)= A"!!,Gp!!#BOJ,hp)!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Gain_AsyncAD_05,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Gain_AsyncAD_05,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Gain_AsyncAD_05,limits={0,inf,1},value= _NUM:1
	SetVariable Gain_AsyncAD_06,pos={224.00,350.00},size={77.00,18.00},bodyWidth=50,disable=1,title="gain"
	SetVariable Gain_AsyncAD_06,userdata(tabnum)=  "4",userdata(tabcontrol)=  "ADC"
	SetVariable Gain_AsyncAD_06,userdata(ResizeControlsInfo)= A"!!,Gp!!#Bi!!#?S!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Gain_AsyncAD_06,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Gain_AsyncAD_06,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Gain_AsyncAD_06,limits={0,inf,1},value= _NUM:1
	SetVariable Gain_AsyncAD_07,pos={224.00,402.00},size={77.00,18.00},bodyWidth=50,disable=1,title="gain"
	SetVariable Gain_AsyncAD_07,userdata(tabnum)=  "4",userdata(tabcontrol)=  "ADC"
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
	SetVariable Unit_AsyncAD_00,userdata(tabnum)=  "4",userdata(tabcontrol)=  "ADC"
	SetVariable Unit_AsyncAD_00,userdata(ResizeControlsInfo)= A"!!,HXJ,hni!!#?O!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Unit_AsyncAD_00,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Unit_AsyncAD_00,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Unit_AsyncAD_00,value= _STR:""
	SetVariable Unit_AsyncAD_01,pos={315.00,95.00},size={75.00,18.00},disable=1,title="Unit"
	SetVariable Unit_AsyncAD_01,userdata(tabnum)=  "4",userdata(tabcontrol)=  "ADC"
	SetVariable Unit_AsyncAD_01,userdata(ResizeControlsInfo)= A"!!,HXJ,hpM!!#?O!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Unit_AsyncAD_01,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Unit_AsyncAD_01,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Unit_AsyncAD_01,value= _STR:""
	SetVariable Unit_AsyncAD_02,pos={315.00,146.00},size={75.00,18.00},disable=1,title="Unit"
	SetVariable Unit_AsyncAD_02,userdata(tabnum)=  "4",userdata(tabcontrol)=  "ADC"
	SetVariable Unit_AsyncAD_02,userdata(ResizeControlsInfo)= A"!!,HXJ,hqL!!#?O!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Unit_AsyncAD_02,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Unit_AsyncAD_02,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Unit_AsyncAD_02,value= _STR:""
	SetVariable Unit_AsyncAD_03,pos={315.00,197.00},size={75.00,18.00},disable=1,title="Unit"
	SetVariable Unit_AsyncAD_03,userdata(tabnum)=  "4",userdata(tabcontrol)=  "ADC"
	SetVariable Unit_AsyncAD_03,userdata(ResizeControlsInfo)= A"!!,HXJ,hr*!!#?O!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Unit_AsyncAD_03,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Unit_AsyncAD_03,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Unit_AsyncAD_03,value= _STR:""
	SetVariable Unit_AsyncAD_04,pos={315.00,248.00},size={75.00,18.00},disable=1,title="Unit"
	SetVariable Unit_AsyncAD_04,userdata(tabnum)=  "4",userdata(tabcontrol)=  "ADC"
	SetVariable Unit_AsyncAD_04,userdata(ResizeControlsInfo)= A"!!,HXJ,hr]!!#?O!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Unit_AsyncAD_04,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Unit_AsyncAD_04,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Unit_AsyncAD_04,value= _STR:""
	SetVariable Unit_AsyncAD_05,pos={315.00,298.00},size={75.00,18.00},disable=1,title="Unit"
	SetVariable Unit_AsyncAD_05,userdata(tabnum)=  "4",userdata(tabcontrol)=  "ADC"
	SetVariable Unit_AsyncAD_05,userdata(ResizeControlsInfo)= A"!!,HXJ,hs%!!#?O!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Unit_AsyncAD_05,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Unit_AsyncAD_05,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Unit_AsyncAD_05,value= _STR:""
	SetVariable Unit_AsyncAD_06,pos={315.00,350.00},size={75.00,18.00},disable=1,title="Unit"
	SetVariable Unit_AsyncAD_06,userdata(tabnum)=  "4",userdata(tabcontrol)=  "ADC"
	SetVariable Unit_AsyncAD_06,userdata(ResizeControlsInfo)= A"!!,HXJ,hs?!!#?O!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Unit_AsyncAD_06,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Unit_AsyncAD_06,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Unit_AsyncAD_06,value= _STR:""
	SetVariable Unit_AsyncAD_07,pos={315.00,402.00},size={75.00,18.00},disable=1,title="Unit"
	SetVariable Unit_AsyncAD_07,userdata(tabnum)=  "4",userdata(tabcontrol)=  "ADC"
	SetVariable Unit_AsyncAD_07,userdata(ResizeControlsInfo)= A"!!,HXJ,hsY!!#?O!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Unit_AsyncAD_07,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Unit_AsyncAD_07,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Unit_AsyncAD_07,value= _STR:""
	CheckBox Check_Settings_Append,pos={34.00,452.00},size={144.00,15.00},disable=1,title="Enable async acquisition"
	CheckBox Check_Settings_Append,help={"Enable querying and storing the asynchronous parameters in the labnotebook."}
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
	CheckBox Radio_ClampMode_0,pos={129.00,62.00},size={13.00,13.00},disable=1,proc=DAP_CheckProc_ClampMode,title=""
	CheckBox Radio_ClampMode_0,userdata(tabnum)=  "0",userdata(tabcontrol)=  "ADC"
	CheckBox Radio_ClampMode_0,userdata(ResizeControlsInfo)= A"!!,Ff!!#?1!!#;]!!#;]z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Radio_ClampMode_0,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Radio_ClampMode_0,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Radio_ClampMode_0,value= 1,mode=1
	TitleBox Title_DataAcq_VC,pos={43.00,60.00},size={78.00,15.00},disable=1,title="Voltage Clamp"
	TitleBox Title_DataAcq_VC,userdata(tabnum)=  "0",userdata(tabcontrol)=  "ADC"
	TitleBox Title_DataAcq_VC,userdata(ResizeControlsInfo)= A"!!,D;!!#?)!!#?U!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox Title_DataAcq_VC,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	TitleBox Title_DataAcq_VC,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	TitleBox Title_DataAcq_VC,frame=0
	TitleBox Title_DataAcq_IC,pos={43.00,109.00},size={78.00,15.00},disable=1,title="Current Clamp"
	TitleBox Title_DataAcq_IC,userdata(tabnum)=  "0",userdata(tabcontrol)=  "ADC"
	TitleBox Title_DataAcq_IC,userdata(ResizeControlsInfo)= A"!!,D;!!#@>!!#?U!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox Title_DataAcq_IC,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	TitleBox Title_DataAcq_IC,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	TitleBox Title_DataAcq_IC,frame=0
	TitleBox Title_DataAcq_CellSelection,pos={58.00,85.00},size={56.00,15.00},disable=1,title="Headstage"
	TitleBox Title_DataAcq_CellSelection,userdata(tabnum)=  "0"
	TitleBox Title_DataAcq_CellSelection,userdata(tabcontrol)=  "ADC"
	TitleBox Title_DataAcq_CellSelection,userdata(ResizeControlsInfo)= A"!!,E\"!!#?c!!#>n!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox Title_DataAcq_CellSelection,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	TitleBox Title_DataAcq_CellSelection,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	TitleBox Title_DataAcq_CellSelection,frame=0
	CheckBox Check_DataAcqHS_01,pos={162.00,86.00},size={21.00,15.00},disable=1,proc=DAP_CheckProc_HedstgeChck,title="1"
	CheckBox Check_DataAcqHS_01,userdata(tabnum)=  "0",userdata(tabcontrol)=  "ADC"
	CheckBox Check_DataAcqHS_01,userdata(ResizeControlsInfo)= A"!!,G2!!#?e!!#<`!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_DataAcqHS_01,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_DataAcqHS_01,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_DataAcqHS_01,value= 0
	CheckBox Check_DataAcqHS_02,pos={196.00,86.00},size={21.00,15.00},disable=1,proc=DAP_CheckProc_HedstgeChck,title="2"
	CheckBox Check_DataAcqHS_02,userdata(tabnum)=  "0",userdata(tabcontrol)=  "ADC"
	CheckBox Check_DataAcqHS_02,userdata(ResizeControlsInfo)= A"!!,GT!!#?e!!#<`!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_DataAcqHS_02,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_DataAcqHS_02,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_DataAcqHS_02,value= 0
	CheckBox Check_DataAcqHS_03,pos={230.00,86.00},size={21.00,15.00},disable=1,proc=DAP_CheckProc_HedstgeChck,title="3"
	CheckBox Check_DataAcqHS_03,userdata(tabnum)=  "0",userdata(tabcontrol)=  "ADC"
	CheckBox Check_DataAcqHS_03,userdata(ResizeControlsInfo)= A"!!,H!!!#?e!!#<`!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_DataAcqHS_03,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_DataAcqHS_03,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_DataAcqHS_03,value= 0
	CheckBox Check_DataAcqHS_04,pos={264.00,86.00},size={21.00,15.00},disable=1,proc=DAP_CheckProc_HedstgeChck,title="4"
	CheckBox Check_DataAcqHS_04,userdata(tabnum)=  "0",userdata(tabcontrol)=  "ADC"
	CheckBox Check_DataAcqHS_04,userdata(ResizeControlsInfo)= A"!!,H?!!#?e!!#<`!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_DataAcqHS_04,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_DataAcqHS_04,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_DataAcqHS_04,value= 0
	CheckBox Check_DataAcqHS_05,pos={298.00,86.00},size={21.00,15.00},disable=1,proc=DAP_CheckProc_HedstgeChck,title="5"
	CheckBox Check_DataAcqHS_05,userdata(tabnum)=  "0",userdata(tabcontrol)=  "ADC"
	CheckBox Check_DataAcqHS_05,userdata(ResizeControlsInfo)= A"!!,HP!!#?e!!#<`!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_DataAcqHS_05,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_DataAcqHS_05,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_DataAcqHS_05,value= 0
	CheckBox Check_DataAcqHS_06,pos={332.00,86.00},size={21.00,15.00},disable=1,proc=DAP_CheckProc_HedstgeChck,title="6"
	CheckBox Check_DataAcqHS_06,userdata(tabnum)=  "0",userdata(tabcontrol)=  "ADC"
	CheckBox Check_DataAcqHS_06,userdata(ResizeControlsInfo)= A"!!,Ha!!#?e!!#<`!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_DataAcqHS_06,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_DataAcqHS_06,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_DataAcqHS_06,value= 0
	CheckBox Check_DataAcqHS_07,pos={366.00,85.00},size={21.00,15.00},disable=1,proc=DAP_CheckProc_HedstgeChck,title="7"
	CheckBox Check_DataAcqHS_07,userdata(tabnum)=  "0",userdata(tabcontrol)=  "ADC"
	CheckBox Check_DataAcqHS_07,userdata(ResizeControlsInfo)= A"!!,Hr!!#?c!!#<`!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_DataAcqHS_07,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_DataAcqHS_07,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_DataAcqHS_07,value= 0
	CheckBox Radio_ClampMode_1,pos={129.00,111.00},size={13.00,13.00},disable=1,proc=DAP_CheckProc_ClampMode,title=""
	CheckBox Radio_ClampMode_1,userdata(tabnum)=  "0",userdata(tabcontrol)=  "ADC"
	CheckBox Radio_ClampMode_1,userdata(ResizeControlsInfo)= A"!!,Ff!!#@B!!#;]!!#;]z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Radio_ClampMode_1,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Radio_ClampMode_1,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Radio_ClampMode_1,value= 0,mode=1
	CheckBox Radio_ClampMode_2,pos={162.00,62.00},size={13.00,13.00},disable=1,proc=DAP_CheckProc_ClampMode,title=""
	CheckBox Radio_ClampMode_2,userdata(tabnum)=  "0",userdata(tabcontrol)=  "ADC"
	CheckBox Radio_ClampMode_2,userdata(ResizeControlsInfo)= A"!!,G2!!#?1!!#;]!!#;]z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Radio_ClampMode_2,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Radio_ClampMode_2,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Radio_ClampMode_2,value= 1,mode=1
	CheckBox Radio_ClampMode_3,pos={162.00,111.00},size={13.00,13.00},disable=1,proc=DAP_CheckProc_ClampMode,title=""
	CheckBox Radio_ClampMode_3,userdata(tabnum)=  "0",userdata(tabcontrol)=  "ADC"
	CheckBox Radio_ClampMode_3,userdata(ResizeControlsInfo)= A"!!,G2!!#@B!!#;]!!#;]z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Radio_ClampMode_3,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Radio_ClampMode_3,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Radio_ClampMode_3,value= 0,mode=1
	CheckBox Radio_ClampMode_4,pos={196.00,62.00},size={13.00,13.00},disable=1,proc=DAP_CheckProc_ClampMode,title=""
	CheckBox Radio_ClampMode_4,userdata(tabnum)=  "0",userdata(tabcontrol)=  "ADC"
	CheckBox Radio_ClampMode_4,userdata(ResizeControlsInfo)= A"!!,GT!!#?1!!#;]!!#;]z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Radio_ClampMode_4,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Radio_ClampMode_4,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Radio_ClampMode_4,value= 1,mode=1
	CheckBox Radio_ClampMode_5,pos={196.00,111.00},size={13.00,13.00},disable=1,proc=DAP_CheckProc_ClampMode,title=""
	CheckBox Radio_ClampMode_5,userdata(tabnum)=  "0",userdata(tabcontrol)=  "ADC"
	CheckBox Radio_ClampMode_5,userdata(ResizeControlsInfo)= A"!!,GT!!#@B!!#;]!!#;]z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Radio_ClampMode_5,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Radio_ClampMode_5,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Radio_ClampMode_5,value= 0,mode=1
	CheckBox Radio_ClampMode_6,pos={230.00,62.00},size={13.00,13.00},disable=1,proc=DAP_CheckProc_ClampMode,title=""
	CheckBox Radio_ClampMode_6,userdata(tabnum)=  "0",userdata(tabcontrol)=  "ADC"
	CheckBox Radio_ClampMode_6,userdata(ResizeControlsInfo)= A"!!,H!!!#?1!!#;]!!#;]z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Radio_ClampMode_6,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Radio_ClampMode_6,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Radio_ClampMode_6,value= 1,mode=1
	CheckBox Radio_ClampMode_7,pos={230.00,111.00},size={13.00,13.00},disable=1,proc=DAP_CheckProc_ClampMode,title=""
	CheckBox Radio_ClampMode_7,userdata(tabnum)=  "0",userdata(tabcontrol)=  "ADC"
	CheckBox Radio_ClampMode_7,userdata(ResizeControlsInfo)= A"!!,H!!!#@B!!#;]!!#;]z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Radio_ClampMode_7,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Radio_ClampMode_7,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Radio_ClampMode_7,value= 0,mode=1
	CheckBox Radio_ClampMode_8,pos={264.00,62.00},size={13.00,13.00},disable=1,proc=DAP_CheckProc_ClampMode,title=""
	CheckBox Radio_ClampMode_8,userdata(tabnum)=  "0",userdata(tabcontrol)=  "ADC"
	CheckBox Radio_ClampMode_8,userdata(ResizeControlsInfo)= A"!!,H?!!#?1!!#;]!!#;]z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Radio_ClampMode_8,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Radio_ClampMode_8,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Radio_ClampMode_8,value= 1,mode=1
	CheckBox Radio_ClampMode_9,pos={264.00,111.00},size={13.00,13.00},disable=1,proc=DAP_CheckProc_ClampMode,title=""
	CheckBox Radio_ClampMode_9,userdata(tabnum)=  "0",userdata(tabcontrol)=  "ADC"
	CheckBox Radio_ClampMode_9,userdata(ResizeControlsInfo)= A"!!,H?!!#@B!!#;]!!#;]z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Radio_ClampMode_9,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Radio_ClampMode_9,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Radio_ClampMode_9,value= 0,mode=1
	CheckBox Radio_ClampMode_10,pos={298.00,62.00},size={13.00,13.00},disable=1,proc=DAP_CheckProc_ClampMode,title=""
	CheckBox Radio_ClampMode_10,userdata(tabnum)=  "0",userdata(tabcontrol)=  "ADC"
	CheckBox Radio_ClampMode_10,userdata(ResizeControlsInfo)= A"!!,HP!!#?1!!#;]!!#;]z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Radio_ClampMode_10,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Radio_ClampMode_10,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Radio_ClampMode_10,value= 1,mode=1
	CheckBox Radio_ClampMode_11,pos={298.00,111.00},size={13.00,13.00},disable=1,proc=DAP_CheckProc_ClampMode,title=""
	CheckBox Radio_ClampMode_11,userdata(tabnum)=  "0",userdata(tabcontrol)=  "ADC"
	CheckBox Radio_ClampMode_11,userdata(ResizeControlsInfo)= A"!!,HP!!#@B!!#;]!!#;]z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Radio_ClampMode_11,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Radio_ClampMode_11,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Radio_ClampMode_11,value= 0,mode=1
	CheckBox Radio_ClampMode_12,pos={332.00,62.00},size={13.00,13.00},disable=1,proc=DAP_CheckProc_ClampMode,title=""
	CheckBox Radio_ClampMode_12,userdata(tabnum)=  "0",userdata(tabcontrol)=  "ADC"
	CheckBox Radio_ClampMode_12,userdata(ResizeControlsInfo)= A"!!,Ha!!#?1!!#;]!!#;]z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Radio_ClampMode_12,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Radio_ClampMode_12,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Radio_ClampMode_12,value= 1,mode=1
	CheckBox Radio_ClampMode_13,pos={332.00,111.00},size={13.00,13.00},disable=1,proc=DAP_CheckProc_ClampMode,title=""
	CheckBox Radio_ClampMode_13,userdata(tabnum)=  "0",userdata(tabcontrol)=  "ADC"
	CheckBox Radio_ClampMode_13,userdata(ResizeControlsInfo)= A"!!,Ha!!#@B!!#;]!!#;]z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Radio_ClampMode_13,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Radio_ClampMode_13,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Radio_ClampMode_13,value= 0,mode=1
	CheckBox Radio_ClampMode_14,pos={366.00,62.00},size={13.00,13.00},disable=1,proc=DAP_CheckProc_ClampMode,title=""
	CheckBox Radio_ClampMode_14,userdata(tabnum)=  "0",userdata(tabcontrol)=  "ADC"
	CheckBox Radio_ClampMode_14,userdata(ResizeControlsInfo)= A"!!,Hr!!#?1!!#;]!!#;]z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Radio_ClampMode_14,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Radio_ClampMode_14,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Radio_ClampMode_14,value= 1,mode=1
	CheckBox Radio_ClampMode_15,pos={366.00,111.00},size={13.00,13.00},disable=1,proc=DAP_CheckProc_ClampMode,title=""
	CheckBox Radio_ClampMode_15,userdata(tabnum)=  "0",userdata(tabcontrol)=  "ADC"
	CheckBox Radio_ClampMode_15,userdata(ResizeControlsInfo)= A"!!,Hr!!#@B!!#;]!!#;]z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Radio_ClampMode_15,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Radio_ClampMode_15,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Radio_ClampMode_15,value= 0,mode=1
	CheckBox Radio_ClampMode_1IZ,pos={130.00,181.00},size={13.00,13.00},disable=1,proc=DAP_CheckProc_ClampMode,title=""
	CheckBox Radio_ClampMode_1IZ,userdata(tabnum)=  "2"
	CheckBox Radio_ClampMode_1IZ,userdata(tabcontrol)=  "tab_DataAcq_Amp"
	CheckBox Radio_ClampMode_1IZ,userdata(ResizeControlsInfo)= A"!!,G!!!#AD!!#;]!!#;]z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Radio_ClampMode_1IZ,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Radio_ClampMode_1IZ,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Radio_ClampMode_1IZ,value= 0,mode=1
	CheckBox Radio_ClampMode_3IZ,pos={163.00,181.00},size={13.00,13.00},disable=1,proc=DAP_CheckProc_ClampMode,title=""
	CheckBox Radio_ClampMode_3IZ,userdata(tabnum)=  "2"
	CheckBox Radio_ClampMode_3IZ,userdata(tabcontrol)=  "tab_DataAcq_Amp"
	CheckBox Radio_ClampMode_3IZ,userdata(ResizeControlsInfo)= A"!!,GB!!#AD!!#;]!!#;]z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Radio_ClampMode_3IZ,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Radio_ClampMode_3IZ,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Radio_ClampMode_3IZ,value= 0,mode=1
	CheckBox Radio_ClampMode_5IZ,pos={197.00,181.00},size={13.00,13.00},disable=1,proc=DAP_CheckProc_ClampMode,title=""
	CheckBox Radio_ClampMode_5IZ,userdata(tabnum)=  "2"
	CheckBox Radio_ClampMode_5IZ,userdata(tabcontrol)=  "tab_DataAcq_Amp"
	CheckBox Radio_ClampMode_5IZ,userdata(ResizeControlsInfo)= A"!!,Gd!!#AD!!#;]!!#;]z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Radio_ClampMode_5IZ,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Radio_ClampMode_5IZ,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Radio_ClampMode_5IZ,value= 0,mode=1
	CheckBox Radio_ClampMode_7IZ,pos={231.00,181.00},size={13.00,13.00},disable=1,proc=DAP_CheckProc_ClampMode,title=""
	CheckBox Radio_ClampMode_7IZ,userdata(tabnum)=  "2"
	CheckBox Radio_ClampMode_7IZ,userdata(tabcontrol)=  "tab_DataAcq_Amp"
	CheckBox Radio_ClampMode_7IZ,userdata(ResizeControlsInfo)= A"!!,H1!!#AD!!#;]!!#;]z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Radio_ClampMode_7IZ,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Radio_ClampMode_7IZ,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Radio_ClampMode_7IZ,value= 0,mode=1
	CheckBox Radio_ClampMode_9IZ,pos={265.00,181.00},size={13.00,13.00},disable=1,proc=DAP_CheckProc_ClampMode,title=""
	CheckBox Radio_ClampMode_9IZ,userdata(tabnum)=  "2"
	CheckBox Radio_ClampMode_9IZ,userdata(tabcontrol)=  "tab_DataAcq_Amp"
	CheckBox Radio_ClampMode_9IZ,userdata(ResizeControlsInfo)= A"!!,HG!!#AD!!#;]!!#;]z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Radio_ClampMode_9IZ,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Radio_ClampMode_9IZ,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Radio_ClampMode_9IZ,value= 0,mode=1
	CheckBox Radio_ClampMode_11IZ,pos={299.00,181.00},size={13.00,13.00},disable=1,proc=DAP_CheckProc_ClampMode,title=""
	CheckBox Radio_ClampMode_11IZ,userdata(tabnum)=  "2"
	CheckBox Radio_ClampMode_11IZ,userdata(tabcontrol)=  "tab_DataAcq_Amp"
	CheckBox Radio_ClampMode_11IZ,userdata(ResizeControlsInfo)= A"!!,HX!!#AD!!#;]!!#;]z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Radio_ClampMode_11IZ,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Radio_ClampMode_11IZ,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Radio_ClampMode_11IZ,value= 0,mode=1
	CheckBox Radio_ClampMode_13IZ,pos={333.00,181.00},size={13.00,13.00},disable=1,proc=DAP_CheckProc_ClampMode,title=""
	CheckBox Radio_ClampMode_13IZ,userdata(tabnum)=  "2"
	CheckBox Radio_ClampMode_13IZ,userdata(tabcontrol)=  "tab_DataAcq_Amp"
	CheckBox Radio_ClampMode_13IZ,userdata(ResizeControlsInfo)= A"!!,Hi!!#AD!!#;]!!#;]z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Radio_ClampMode_13IZ,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Radio_ClampMode_13IZ,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Radio_ClampMode_13IZ,value= 0,mode=1
	CheckBox Radio_ClampMode_15IZ,pos={367.00,181.00},size={13.00,13.00},disable=1,proc=DAP_CheckProc_ClampMode,title=""
	CheckBox Radio_ClampMode_15IZ,userdata(tabnum)=  "2"
	CheckBox Radio_ClampMode_15IZ,userdata(tabcontrol)=  "tab_DataAcq_Amp"
	CheckBox Radio_ClampMode_15IZ,userdata(ResizeControlsInfo)= A"!!,I%!!#AD!!#;]!!#;]z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Radio_ClampMode_15IZ,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Radio_ClampMode_15IZ,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Radio_ClampMode_15IZ,value= 0,mode=1
	TitleBox Title_DataAcq_IE0,pos={67.00,179.00},size={55.00,15.00},disable=1,title="I=0 Clamp"
	TitleBox Title_DataAcq_IE0,userdata(tabnum)=  "2"
	TitleBox Title_DataAcq_IE0,userdata(tabcontrol)=  "tab_DataAcq_Amp"
	TitleBox Title_DataAcq_IE0,userdata(ResizeControlsInfo)= A"!!,E^!!#AB!!#>j!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox Title_DataAcq_IE0,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	TitleBox Title_DataAcq_IE0,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	TitleBox Title_DataAcq_IE0,frame=0
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
	PopupMenu popup_Settings_Amplifier,mode=1,popvalue="- none -",value= #"DAP_GetNiceAmplifierChannelList()"
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
	SetVariable Search_DA_00,pos={153.00,97.00},size={124.00,18.00},disable=1,proc=DAP_SetVarProc_Channel_Search,title="Search string"
	SetVariable Search_DA_00,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	SetVariable Search_DA_00,userdata(ResizeControlsInfo)= A"!!,G)!!#@&!!#@\\!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Search_DA_00,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Search_DA_00,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Search_DA_00,value= _STR:""
	SetVariable Search_DA_01,pos={153.00,143.00},size={124.00,18.00},disable=1,proc=DAP_SetVarProc_Channel_Search,title="Search string"
	SetVariable Search_DA_01,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	SetVariable Search_DA_01,userdata(ResizeControlsInfo)= A"!!,G)!!#@s!!#@\\!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Search_DA_01,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Search_DA_01,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Search_DA_01,value= _STR:""
	SetVariable Search_DA_02,pos={153.00,189.00},size={124.00,18.00},disable=1,proc=DAP_SetVarProc_Channel_Search,title="Search string"
	SetVariable Search_DA_02,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	SetVariable Search_DA_02,userdata(ResizeControlsInfo)= A"!!,G)!!#AL!!#@\\!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Search_DA_02,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Search_DA_02,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Search_DA_02,value= _STR:""
	SetVariable Search_DA_03,pos={153.00,236.00},size={124.00,18.00},disable=1,proc=DAP_SetVarProc_Channel_Search,title="Search string"
	SetVariable Search_DA_03,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	SetVariable Search_DA_03,userdata(ResizeControlsInfo)= A"!!,G)!!#B&!!#@\\!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Search_DA_03,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Search_DA_03,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Search_DA_03,value= _STR:""
	SetVariable Search_DA_04,pos={153.00,282.00},size={124.00,18.00},disable=1,proc=DAP_SetVarProc_Channel_Search,title="Search string"
	SetVariable Search_DA_04,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	SetVariable Search_DA_04,userdata(ResizeControlsInfo)= A"!!,G)!!#BG!!#@\\!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Search_DA_04,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Search_DA_04,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Search_DA_04,value= _STR:""
	SetVariable Search_DA_05,pos={153.00,329.00},size={124.00,18.00},disable=1,proc=DAP_SetVarProc_Channel_Search,title="Search string"
	SetVariable Search_DA_05,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	SetVariable Search_DA_05,userdata(ResizeControlsInfo)= A"!!,G)!!#B^J,hq2!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Search_DA_05,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Search_DA_05,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Search_DA_05,value= _STR:""
	SetVariable Search_DA_06,pos={153.00,375.00},size={124.00,18.00},disable=1,proc=DAP_SetVarProc_Channel_Search,title="Search string"
	SetVariable Search_DA_06,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	SetVariable Search_DA_06,userdata(ResizeControlsInfo)= A"!!,G)!!#BuJ,hq2!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Search_DA_06,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Search_DA_06,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Search_DA_06,value= _STR:""
	SetVariable Search_DA_07,pos={153.00,422.00},size={124.00,18.00},disable=1,proc=DAP_SetVarProc_Channel_Search,title="Search string"
	SetVariable Search_DA_07,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	SetVariable Search_DA_07,userdata(ResizeControlsInfo)= A"!!,G)!!#C8!!#@\\!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Search_DA_07,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Search_DA_07,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Search_DA_07,value= _STR:""
	SetVariable Search_TTL_00,pos={102.00,97.00},size={124.00,18.00},disable=1,proc=DAP_SetVarProc_Channel_Search,title="Search string"
	SetVariable Search_TTL_00,userdata(tabnum)=  "3",userdata(tabcontrol)=  "ADC"
	SetVariable Search_TTL_00,userdata(ResizeControlsInfo)= A"!!,F1!!#@&!!#@\\!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Search_TTL_00,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Search_TTL_00,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Search_TTL_00,value= _STR:""
	SetVariable Search_TTL_01,pos={102.00,143.00},size={124.00,18.00},disable=1,proc=DAP_SetVarProc_Channel_Search,title="Search string"
	SetVariable Search_TTL_01,userdata(tabnum)=  "3",userdata(tabcontrol)=  "ADC"
	SetVariable Search_TTL_01,userdata(ResizeControlsInfo)= A"!!,F1!!#@s!!#@\\!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Search_TTL_01,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Search_TTL_01,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Search_TTL_01,value= _STR:""
	SetVariable Search_TTL_02,pos={102.00,190.00},size={124.00,18.00},disable=1,proc=DAP_SetVarProc_Channel_Search,title="Search string"
	SetVariable Search_TTL_02,userdata(tabnum)=  "3",userdata(tabcontrol)=  "ADC"
	SetVariable Search_TTL_02,userdata(ResizeControlsInfo)= A"!!,F1!!#AM!!#@\\!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Search_TTL_02,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Search_TTL_02,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Search_TTL_02,value= _STR:""
	SetVariable Search_TTL_03,pos={102.00,237.00},size={124.00,18.00},disable=1,proc=DAP_SetVarProc_Channel_Search,title="Search string"
	SetVariable Search_TTL_03,userdata(tabnum)=  "3",userdata(tabcontrol)=  "ADC"
	SetVariable Search_TTL_03,userdata(ResizeControlsInfo)= A"!!,F1!!#B'!!#@\\!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Search_TTL_03,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Search_TTL_03,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Search_TTL_03,value= _STR:""
	SetVariable Search_TTL_04,pos={102.00,284.00},size={124.00,18.00},disable=1,proc=DAP_SetVarProc_Channel_Search,title="Search string"
	SetVariable Search_TTL_04,userdata(tabnum)=  "3",userdata(tabcontrol)=  "ADC"
	SetVariable Search_TTL_04,userdata(ResizeControlsInfo)= A"!!,F1!!#BH!!#@\\!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Search_TTL_04,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Search_TTL_04,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Search_TTL_04,value= _STR:""
	SetVariable Search_TTL_05,pos={102.00,331.00},size={124.00,18.00},disable=1,proc=DAP_SetVarProc_Channel_Search,title="Search string"
	SetVariable Search_TTL_05,userdata(tabnum)=  "3",userdata(tabcontrol)=  "ADC"
	SetVariable Search_TTL_05,userdata(ResizeControlsInfo)= A"!!,F1!!#B_J,hq2!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Search_TTL_05,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Search_TTL_05,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Search_TTL_05,value= _STR:""
	SetVariable Search_TTL_06,pos={102.00,378.00},size={124.00,18.00},disable=1,proc=DAP_SetVarProc_Channel_Search,title="Search string"
	SetVariable Search_TTL_06,userdata(tabnum)=  "3",userdata(tabcontrol)=  "ADC"
	SetVariable Search_TTL_06,userdata(ResizeControlsInfo)= A"!!,F1!!#C\"!!#@\\!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Search_TTL_06,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Search_TTL_06,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Search_TTL_06,value= _STR:""
	SetVariable Search_TTL_07,pos={102.00,425.00},size={124.00,18.00},disable=1,proc=DAP_SetVarProc_Channel_Search,title="Search string"
	SetVariable Search_TTL_07,userdata(tabnum)=  "3",userdata(tabcontrol)=  "ADC"
	SetVariable Search_TTL_07,userdata(ResizeControlsInfo)= A"!!,F1!!#C9J,hq2!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Search_TTL_07,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Search_TTL_07,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Search_TTL_07,value= _STR:""
	CheckBox Check_DataAcq_Indexing,pos={194.00,680.00},size={60.00,15.00},disable=1,proc=DAP_CheckProc_IndexingState,title="Indexing"
	CheckBox Check_DataAcq_Indexing,help={"Data acquisition proceeds to next wave in DAC or TTL popup menu list"}
	CheckBox Check_DataAcq_Indexing,userdata(tabnum)=  "0"
	CheckBox Check_DataAcq_Indexing,userdata(tabcontrol)=  "ADC"
	CheckBox Check_DataAcq_Indexing,userdata(ResizeControlsInfo)= A"!!,GR!!#D:!!#?)!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
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
	PopupMenu IndexEnd_DA_00,pos={353.00,75.00},size={125.00,19.00},bodyWidth=125,disable=1,proc=DAP_PopMenuChkProc_StimSetList
	PopupMenu IndexEnd_DA_00,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	PopupMenu IndexEnd_DA_00,userdata(ResizeControlsInfo)= A"!!,HkJ,hp%!!#@^!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu IndexEnd_DA_00,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu IndexEnd_DA_00,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu IndexEnd_DA_00,mode=1,popvalue="- none -",value= #"\"- none -;\"+ReturnListOfAllStimSets(0,\"*DA*\")"
	PopupMenu IndexEnd_DA_01,pos={353.00,121.00},size={125.00,19.00},bodyWidth=125,disable=1,proc=DAP_PopMenuChkProc_StimSetList
	PopupMenu IndexEnd_DA_01,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	PopupMenu IndexEnd_DA_01,userdata(ResizeControlsInfo)= A"!!,HkJ,hq,!!#@^!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu IndexEnd_DA_01,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu IndexEnd_DA_01,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu IndexEnd_DA_01,mode=1,popvalue="- none -",value= #"\"- none -;\"+ReturnListOfAllStimSets(0,\"*DA*\")"
	PopupMenu IndexEnd_DA_02,pos={353.00,167.00},size={125.00,19.00},bodyWidth=125,disable=1,proc=DAP_PopMenuChkProc_StimSetList
	PopupMenu IndexEnd_DA_02,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	PopupMenu IndexEnd_DA_02,userdata(ResizeControlsInfo)= A"!!,HkJ,hqa!!#@^!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu IndexEnd_DA_02,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu IndexEnd_DA_02,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu IndexEnd_DA_02,mode=1,popvalue="- none -",value= #"\"- none -;\"+ReturnListOfAllStimSets(0,\"*DA*\")"
	PopupMenu IndexEnd_DA_03,pos={353.00,214.00},size={125.00,19.00},bodyWidth=125,disable=1,proc=DAP_PopMenuChkProc_StimSetList
	PopupMenu IndexEnd_DA_03,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	PopupMenu IndexEnd_DA_03,userdata(ResizeControlsInfo)= A"!!,HkJ,hr;!!#@^!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu IndexEnd_DA_03,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu IndexEnd_DA_03,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu IndexEnd_DA_03,mode=1,popvalue="- none -",value= #"\"- none -;\"+ReturnListOfAllStimSets(0,\"*DA*\")"
	PopupMenu IndexEnd_DA_04,pos={353.00,260.00},size={125.00,19.00},bodyWidth=125,disable=1,proc=DAP_PopMenuChkProc_StimSetList
	PopupMenu IndexEnd_DA_04,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	PopupMenu IndexEnd_DA_04,userdata(ResizeControlsInfo)= A"!!,HkJ,hrg!!#@^!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu IndexEnd_DA_04,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu IndexEnd_DA_04,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu IndexEnd_DA_04,mode=1,popvalue="- none -",value= #"\"- none -;\"+ReturnListOfAllStimSets(0,\"*DA*\")"
	PopupMenu IndexEnd_DA_05,pos={353.00,307.00},size={125.00,19.00},bodyWidth=125,disable=1,proc=DAP_PopMenuChkProc_StimSetList
	PopupMenu IndexEnd_DA_05,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	PopupMenu IndexEnd_DA_05,userdata(ResizeControlsInfo)= A"!!,HkJ,hs)J,hq4!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu IndexEnd_DA_05,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu IndexEnd_DA_05,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu IndexEnd_DA_05,mode=1,popvalue="- none -",value= #"\"- none -;\"+ReturnListOfAllStimSets(0,\"*DA*\")"
	PopupMenu IndexEnd_DA_06,pos={353.00,353.00},size={125.00,19.00},bodyWidth=125,disable=1,proc=DAP_PopMenuChkProc_StimSetList
	PopupMenu IndexEnd_DA_06,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	PopupMenu IndexEnd_DA_06,userdata(ResizeControlsInfo)= A"!!,HkJ,hs@J,hq4!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu IndexEnd_DA_06,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu IndexEnd_DA_06,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu IndexEnd_DA_06,mode=1,popvalue="- none -",value= #"\"- none -;\"+ReturnListOfAllStimSets(0,\"*DA*\")"
	PopupMenu IndexEnd_DA_07,pos={353.00,400.00},size={125.00,19.00},bodyWidth=125,disable=1,proc=DAP_PopMenuChkProc_StimSetList
	PopupMenu IndexEnd_DA_07,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	PopupMenu IndexEnd_DA_07,userdata(ResizeControlsInfo)= A"!!,HkJ,hsX!!#@^!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu IndexEnd_DA_07,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu IndexEnd_DA_07,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu IndexEnd_DA_07,mode=1,popvalue="- none -",value= #"\"- none -;\"+ReturnListOfAllStimSets(0,\"*DA*\")"
	PopupMenu IndexEnd_TTL_00,pos={243.00,75.00},size={125.00,19.00},bodyWidth=125,disable=1,proc=DAP_PopMenuChkProc_StimSetList
	PopupMenu IndexEnd_TTL_00,userdata(tabnum)=  "3",userdata(tabcontrol)=  "ADC"
	PopupMenu IndexEnd_TTL_00,userdata(ResizeControlsInfo)= A"!!,H.!!#?O!!#@^!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu IndexEnd_TTL_00,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu IndexEnd_TTL_00,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu IndexEnd_TTL_00,mode=1,popvalue="- none -",value= #"\"- none -;\"+ReturnListOfAllStimSets(1,\"*TTL*\")"
	PopupMenu IndexEnd_TTL_01,pos={242.00,121.00},size={125.00,19.00},bodyWidth=125,disable=1,proc=DAP_PopMenuChkProc_StimSetList
	PopupMenu IndexEnd_TTL_01,userdata(tabnum)=  "3",userdata(tabcontrol)=  "ADC"
	PopupMenu IndexEnd_TTL_01,userdata(ResizeControlsInfo)= A"!!,H-!!#@V!!#@^!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu IndexEnd_TTL_01,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu IndexEnd_TTL_01,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu IndexEnd_TTL_01,mode=1,popvalue="- none -",value= #"\"- none -;\"+ReturnListOfAllStimSets(1,\"*TTL*\")"
	PopupMenu IndexEnd_TTL_02,pos={242.00,167.00},size={125.00,19.00},bodyWidth=125,disable=1,proc=DAP_PopMenuChkProc_StimSetList
	PopupMenu IndexEnd_TTL_02,userdata(tabnum)=  "3",userdata(tabcontrol)=  "ADC"
	PopupMenu IndexEnd_TTL_02,userdata(ResizeControlsInfo)= A"!!,H-!!#A6!!#@^!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu IndexEnd_TTL_02,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu IndexEnd_TTL_02,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu IndexEnd_TTL_02,mode=1,popvalue="- none -",value= #"\"- none -;\"+ReturnListOfAllStimSets(1,\"*TTL*\")"
	PopupMenu IndexEnd_TTL_03,pos={242.00,214.00},size={125.00,19.00},bodyWidth=125,disable=1,proc=DAP_PopMenuChkProc_StimSetList
	PopupMenu IndexEnd_TTL_03,userdata(tabnum)=  "3",userdata(tabcontrol)=  "ADC"
	PopupMenu IndexEnd_TTL_03,userdata(ResizeControlsInfo)= A"!!,H-!!#Ae!!#@^!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu IndexEnd_TTL_03,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu IndexEnd_TTL_03,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu IndexEnd_TTL_03,mode=1,popvalue="- none -",value= #"\"- none -;\"+ReturnListOfAllStimSets(1,\"*TTL*\")"
	PopupMenu IndexEnd_TTL_04,pos={242.00,260.00},size={125.00,19.00},bodyWidth=125,disable=1,proc=DAP_PopMenuChkProc_StimSetList
	PopupMenu IndexEnd_TTL_04,userdata(tabnum)=  "3",userdata(tabcontrol)=  "ADC"
	PopupMenu IndexEnd_TTL_04,userdata(ResizeControlsInfo)= A"!!,H-!!#B<!!#@^!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu IndexEnd_TTL_04,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu IndexEnd_TTL_04,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu IndexEnd_TTL_04,mode=1,popvalue="- none -",value= #"\"- none -;\"+ReturnListOfAllStimSets(1,\"*TTL*\")"
	PopupMenu IndexEnd_TTL_05,pos={242.00,307.00},size={125.00,19.00},bodyWidth=125,disable=1,proc=DAP_PopMenuChkProc_StimSetList
	PopupMenu IndexEnd_TTL_05,userdata(tabnum)=  "3",userdata(tabcontrol)=  "ADC"
	PopupMenu IndexEnd_TTL_05,userdata(ResizeControlsInfo)= A"!!,H-!!#BSJ,hq4!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu IndexEnd_TTL_05,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu IndexEnd_TTL_05,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu IndexEnd_TTL_05,mode=1,popvalue="- none -",value= #"\"- none -;\"+ReturnListOfAllStimSets(1,\"*TTL*\")"
	PopupMenu IndexEnd_TTL_06,pos={242.00,353.00},size={125.00,19.00},bodyWidth=125,disable=1,proc=DAP_PopMenuChkProc_StimSetList
	PopupMenu IndexEnd_TTL_06,userdata(tabnum)=  "3",userdata(tabcontrol)=  "ADC"
	PopupMenu IndexEnd_TTL_06,userdata(ResizeControlsInfo)= A"!!,H-!!#BjJ,hq4!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu IndexEnd_TTL_06,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu IndexEnd_TTL_06,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu IndexEnd_TTL_06,mode=1,popvalue="- none -",value= #"\"- none -;\"+ReturnListOfAllStimSets(1,\"*TTL*\")"
	PopupMenu IndexEnd_TTL_07,pos={243.00,400.00},size={125.00,19.00},bodyWidth=125,disable=1,proc=DAP_PopMenuChkProc_StimSetList
	PopupMenu IndexEnd_TTL_07,userdata(tabnum)=  "3",userdata(tabcontrol)=  "ADC"
	PopupMenu IndexEnd_TTL_07,userdata(ResizeControlsInfo)= A"!!,H.!!#C-!!#@^!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
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
	Button button_DataAcq_TurnOffAllChan,pos={435.00,73.00},size={30.00,40.00},disable=1,proc=DAP_ButtonProc_AllChanOff,title="OFF"
	Button button_DataAcq_TurnOffAllChan,userdata(tabnum)=  "0"
	Button button_DataAcq_TurnOffAllChan,userdata(tabcontrol)=  "ADC"
	Button button_DataAcq_TurnOffAllChan,userdata(ResizeControlsInfo)= A"!!,I?J,hp!!!#=S!!#>.z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_DataAcq_TurnOffAllChan,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button button_DataAcq_TurnOffAllChan,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_Settings_ITITP,pos={34.00,109.00},size={129.00,15.00},disable=1,title="Activate TP during ITI"
	CheckBox check_Settings_ITITP,userdata(tabnum)=  "5"
	CheckBox check_Settings_ITITP,userdata(tabcontrol)=  "ADC"
	CheckBox check_Settings_ITITP,userdata(ResizeControlsInfo)= A"!!,Cl!!#@>!!#@e!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_Settings_ITITP,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_Settings_ITITP,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_Settings_ITITP,value= 1
	ValDisplay valdisp_DataAcq_ITICountdown,pos={68.00,566.00},size={132.00,21.00},bodyWidth=30,disable=1,title="ITI remaining (s)"
	ValDisplay valdisp_DataAcq_ITICountdown,userdata(tabnum)=  "0"
	ValDisplay valdisp_DataAcq_ITICountdown,userdata(tabcontrol)=  "ADC"
	ValDisplay valdisp_DataAcq_ITICountdown,userdata(ResizeControlsInfo)= A"!!,EB!!#CrJ,hq>!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	ValDisplay valdisp_DataAcq_ITICountdown,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	ValDisplay valdisp_DataAcq_ITICountdown,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	ValDisplay valdisp_DataAcq_ITICountdown,fSize=14,format="%1g",fStyle=0
	ValDisplay valdisp_DataAcq_ITICountdown,valueColor=(65535,65535,65535)
	ValDisplay valdisp_DataAcq_ITICountdown,valueBackColor=(0,0,0)
	ValDisplay valdisp_DataAcq_ITICountdown,limits={0,0,0},barmisc={0,1000}
	ValDisplay valdisp_DataAcq_ITICountdown,value= _NUM:0
	ValDisplay valdisp_DataAcq_TrialsCountdown,pos={57.00,539.00},size={144.00,21.00},bodyWidth=30,disable=1,title="Sweeps remaining"
	ValDisplay valdisp_DataAcq_TrialsCountdown,userdata(tabnum)=  "0"
	ValDisplay valdisp_DataAcq_TrialsCountdown,userdata(tabcontrol)=  "ADC"
	ValDisplay valdisp_DataAcq_TrialsCountdown,userdata(ResizeControlsInfo)= A"!!,Ds!!#Ck^]6_5!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	ValDisplay valdisp_DataAcq_TrialsCountdown,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	ValDisplay valdisp_DataAcq_TrialsCountdown,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	ValDisplay valdisp_DataAcq_TrialsCountdown,fSize=14,fStyle=0
	ValDisplay valdisp_DataAcq_TrialsCountdown,valueColor=(65535,65535,65535)
	ValDisplay valdisp_DataAcq_TrialsCountdown,valueBackColor=(0,0,0)
	ValDisplay valdisp_DataAcq_TrialsCountdown,limits={0,0,0},barmisc={0,1000}
	ValDisplay valdisp_DataAcq_TrialsCountdown,value= _NUM:1
	SetVariable min_AsyncAD_00,pos={109.00,66.00},size={75.00,18.00},bodyWidth=50,disable=1,title="min"
	SetVariable min_AsyncAD_00,userdata(tabnum)=  "4",userdata(tabcontrol)=  "ADC"
	SetVariable min_AsyncAD_00,userdata(ResizeControlsInfo)= A"!!,F?!!#?=!!#?O!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable min_AsyncAD_00,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable min_AsyncAD_00,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable min_AsyncAD_00,value= _NUM:0
	SetVariable max_AsyncAD_00,pos={197.00,66.00},size={76.00,18.00},bodyWidth=50,disable=1,title="max"
	SetVariable max_AsyncAD_00,userdata(tabnum)=  "4",userdata(tabcontrol)=  "ADC"
	SetVariable max_AsyncAD_00,userdata(ResizeControlsInfo)= A"!!,GU!!#?=!!#?Q!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable max_AsyncAD_00,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable max_AsyncAD_00,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable max_AsyncAD_00,value= _NUM:0
	CheckBox check_AsyncAlarm_00,pos={50.00,68.00},size={47.00,15.00},disable=1,proc=DAP_CheckProc_RecordInGuiState,title="Alarm"
	CheckBox check_AsyncAlarm_00,userdata(tabnum)=  "4",userdata(tabcontrol)=  "ADC"
	CheckBox check_AsyncAlarm_00,userdata(ResizeControlsInfo)= A"!!,DW!!#?A!!#>J!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_AsyncAlarm_00,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_AsyncAlarm_00,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_AsyncAlarm_00,value= 0
	SetVariable min_AsyncAD_01,pos={109.00,117.00},size={75.00,18.00},bodyWidth=50,disable=1,title="min"
	SetVariable min_AsyncAD_01,userdata(tabnum)=  "4",userdata(tabcontrol)=  "ADC"
	SetVariable min_AsyncAD_01,userdata(ResizeControlsInfo)= A"!!,F?!!#@N!!#?O!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable min_AsyncAD_01,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable min_AsyncAD_01,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable min_AsyncAD_01,value= _NUM:0
	SetVariable max_AsyncAD_01,pos={197.00,117.00},size={76.00,18.00},bodyWidth=50,disable=1,title="max"
	SetVariable max_AsyncAD_01,userdata(tabnum)=  "4",userdata(tabcontrol)=  "ADC"
	SetVariable max_AsyncAD_01,userdata(ResizeControlsInfo)= A"!!,GU!!#@N!!#?Q!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable max_AsyncAD_01,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable max_AsyncAD_01,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable max_AsyncAD_01,value= _NUM:0
	CheckBox check_AsyncAlarm_01,pos={50.00,119.00},size={47.00,15.00},disable=1,proc=DAP_CheckProc_RecordInGuiState,title="Alarm"
	CheckBox check_AsyncAlarm_01,userdata(tabnum)=  "4",userdata(tabcontrol)=  "ADC"
	CheckBox check_AsyncAlarm_01,userdata(ResizeControlsInfo)= A"!!,DW!!#@R!!#>J!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_AsyncAlarm_01,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_AsyncAlarm_01,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_AsyncAlarm_01,value= 0
	SetVariable min_AsyncAD_02,pos={109.00,169.00},size={75.00,18.00},bodyWidth=50,disable=1,title="min"
	SetVariable min_AsyncAD_02,userdata(tabnum)=  "4",userdata(tabcontrol)=  "ADC"
	SetVariable min_AsyncAD_02,userdata(ResizeControlsInfo)= A"!!,F?!!#A8!!#?O!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable min_AsyncAD_02,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable min_AsyncAD_02,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable min_AsyncAD_02,value= _NUM:0
	SetVariable max_AsyncAD_02,pos={197.00,169.00},size={76.00,18.00},bodyWidth=50,disable=1,title="max"
	SetVariable max_AsyncAD_02,userdata(tabnum)=  "4",userdata(tabcontrol)=  "ADC"
	SetVariable max_AsyncAD_02,userdata(ResizeControlsInfo)= A"!!,GU!!#A8!!#?Q!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable max_AsyncAD_02,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable max_AsyncAD_02,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable max_AsyncAD_02,value= _NUM:0
	CheckBox check_AsyncAlarm_02,pos={50.00,171.00},size={47.00,15.00},disable=1,proc=DAP_CheckProc_RecordInGuiState,title="Alarm"
	CheckBox check_AsyncAlarm_02,userdata(tabnum)=  "4",userdata(tabcontrol)=  "ADC"
	CheckBox check_AsyncAlarm_02,userdata(ResizeControlsInfo)= A"!!,DW!!#A:!!#>J!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_AsyncAlarm_02,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_AsyncAlarm_02,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_AsyncAlarm_02,value= 0
	SetVariable min_AsyncAD_03,pos={109.00,220.00},size={75.00,18.00},bodyWidth=50,disable=1,title="min"
	SetVariable min_AsyncAD_03,userdata(tabnum)=  "4",userdata(tabcontrol)=  "ADC"
	SetVariable min_AsyncAD_03,userdata(ResizeControlsInfo)= A"!!,F?!!#Ak!!#?O!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable min_AsyncAD_03,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable min_AsyncAD_03,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable min_AsyncAD_03,value= _NUM:0
	SetVariable max_AsyncAD_03,pos={197.00,220.00},size={76.00,18.00},bodyWidth=50,disable=1,title="max"
	SetVariable max_AsyncAD_03,userdata(tabnum)=  "4",userdata(tabcontrol)=  "ADC"
	SetVariable max_AsyncAD_03,userdata(ResizeControlsInfo)= A"!!,GU!!#Ak!!#?Q!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable max_AsyncAD_03,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable max_AsyncAD_03,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable max_AsyncAD_03,value= _NUM:0
	CheckBox check_AsyncAlarm_03,pos={50.00,222.00},size={47.00,15.00},disable=1,proc=DAP_CheckProc_RecordInGuiState,title="Alarm"
	CheckBox check_AsyncAlarm_03,userdata(tabnum)=  "4",userdata(tabcontrol)=  "ADC"
	CheckBox check_AsyncAlarm_03,userdata(ResizeControlsInfo)= A"!!,DW!!#Am!!#>J!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_AsyncAlarm_03,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_AsyncAlarm_03,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_AsyncAlarm_03,value= 0
	SetVariable min_AsyncAD_04,pos={109.00,272.00},size={75.00,18.00},bodyWidth=50,disable=1,title="min"
	SetVariable min_AsyncAD_04,userdata(tabnum)=  "4",userdata(tabcontrol)=  "ADC"
	SetVariable min_AsyncAD_04,userdata(ResizeControlsInfo)= A"!!,F?!!#BB!!#?O!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable min_AsyncAD_04,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable min_AsyncAD_04,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable min_AsyncAD_04,value= _NUM:0
	SetVariable max_AsyncAD_04,pos={197.00,272.00},size={76.00,18.00},bodyWidth=50,disable=1,title="max"
	SetVariable max_AsyncAD_04,userdata(tabnum)=  "4",userdata(tabcontrol)=  "ADC"
	SetVariable max_AsyncAD_04,userdata(ResizeControlsInfo)= A"!!,GU!!#BB!!#?Q!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable max_AsyncAD_04,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable max_AsyncAD_04,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable max_AsyncAD_04,value= _NUM:0
	CheckBox check_AsyncAlarm_04,pos={50.00,274.00},size={47.00,15.00},disable=1,proc=DAP_CheckProc_RecordInGuiState,title="Alarm"
	CheckBox check_AsyncAlarm_04,userdata(tabnum)=  "4",userdata(tabcontrol)=  "ADC"
	CheckBox check_AsyncAlarm_04,userdata(ResizeControlsInfo)= A"!!,DW!!#BC!!#>J!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_AsyncAlarm_04,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_AsyncAlarm_04,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_AsyncAlarm_04,value= 0
	SetVariable min_AsyncAD_05,pos={109.00,323.00},size={75.00,18.00},bodyWidth=50,disable=1,title="min"
	SetVariable min_AsyncAD_05,userdata(tabnum)=  "4",userdata(tabcontrol)=  "ADC"
	SetVariable min_AsyncAD_05,userdata(ResizeControlsInfo)= A"!!,F?!!#B[J,hp%!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable min_AsyncAD_05,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable min_AsyncAD_05,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable min_AsyncAD_05,value= _NUM:0
	SetVariable max_AsyncAD_05,pos={197.00,323.00},size={76.00,18.00},bodyWidth=50,disable=1,title="max"
	SetVariable max_AsyncAD_05,userdata(tabnum)=  "4",userdata(tabcontrol)=  "ADC"
	SetVariable max_AsyncAD_05,userdata(ResizeControlsInfo)= A"!!,GU!!#B[J,hp'!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable max_AsyncAD_05,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable max_AsyncAD_05,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable max_AsyncAD_05,value= _NUM:0
	CheckBox check_AsyncAlarm_05,pos={50.00,325.00},size={47.00,15.00},disable=1,proc=DAP_CheckProc_RecordInGuiState,title="Alarm"
	CheckBox check_AsyncAlarm_05,userdata(tabnum)=  "4",userdata(tabcontrol)=  "ADC"
	CheckBox check_AsyncAlarm_05,userdata(ResizeControlsInfo)= A"!!,DW!!#B\\J,hnu!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_AsyncAlarm_05,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_AsyncAlarm_05,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_AsyncAlarm_05,value= 0
	SetVariable min_AsyncAD_06,pos={109.00,375.00},size={75.00,18.00},bodyWidth=50,disable=1,title="min"
	SetVariable min_AsyncAD_06,userdata(tabnum)=  "4",userdata(tabcontrol)=  "ADC"
	SetVariable min_AsyncAD_06,userdata(ResizeControlsInfo)= A"!!,F?!!#BuJ,hp%!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable min_AsyncAD_06,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable min_AsyncAD_06,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable min_AsyncAD_06,value= _NUM:0
	SetVariable max_AsyncAD_06,pos={197.00,375.00},size={76.00,18.00},bodyWidth=50,disable=1,title="max"
	SetVariable max_AsyncAD_06,userdata(tabnum)=  "4",userdata(tabcontrol)=  "ADC"
	SetVariable max_AsyncAD_06,userdata(ResizeControlsInfo)= A"!!,GU!!#BuJ,hp'!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable max_AsyncAD_06,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable max_AsyncAD_06,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable max_AsyncAD_06,value= _NUM:0
	CheckBox check_AsyncAlarm_06,pos={50.00,378.00},size={47.00,15.00},disable=1,proc=DAP_CheckProc_RecordInGuiState,title="Alarm"
	CheckBox check_AsyncAlarm_06,userdata(tabnum)=  "4",userdata(tabcontrol)=  "ADC"
	CheckBox check_AsyncAlarm_06,userdata(ResizeControlsInfo)= A"!!,DW!!#C\"!!#>J!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_AsyncAlarm_06,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_AsyncAlarm_06,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_AsyncAlarm_06,value= 0
	SetVariable min_AsyncAD_07,pos={109.00,427.00},size={75.00,18.00},bodyWidth=50,disable=1,title="min"
	SetVariable min_AsyncAD_07,userdata(tabnum)=  "4",userdata(tabcontrol)=  "ADC"
	SetVariable min_AsyncAD_07,userdata(ResizeControlsInfo)= A"!!,F?!!#C:J,hp%!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable min_AsyncAD_07,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable min_AsyncAD_07,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable min_AsyncAD_07,value= _NUM:0
	SetVariable max_AsyncAD_07,pos={197.00,427.00},size={76.00,18.00},bodyWidth=50,disable=1,title="max"
	SetVariable max_AsyncAD_07,userdata(tabnum)=  "4",userdata(tabcontrol)=  "ADC"
	SetVariable max_AsyncAD_07,userdata(ResizeControlsInfo)= A"!!,GU!!#C:J,hp'!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable max_AsyncAD_07,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable max_AsyncAD_07,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable max_AsyncAD_07,value= _NUM:0
	CheckBox check_AsyncAlarm_07,pos={50.00,429.00},size={47.00,15.00},disable=1,proc=DAP_CheckProc_RecordInGuiState,title="Alarm"
	CheckBox check_AsyncAlarm_07,userdata(tabnum)=  "4",userdata(tabcontrol)=  "ADC"
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
	CheckBox check_DataAcq_RepAcqRandom,pos={66.00,660.00},size={60.00,15.00},disable=1,title="Random"
	CheckBox check_DataAcq_RepAcqRandom,help={"Randomly selects wave from set selected for DAC channel on each trial. Doesn't repeat waves."}
	CheckBox check_DataAcq_RepAcqRandom,userdata(tabnum)=  "0"
	CheckBox check_DataAcq_RepAcqRandom,userdata(tabcontrol)=  "ADC"
	CheckBox check_DataAcq_RepAcqRandom,userdata(ResizeControlsInfo)= A"!!,E>!!#D5!!#?)!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_DataAcq_RepAcqRandom,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_DataAcq_RepAcqRandom,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_DataAcq_RepAcqRandom,value= 0
	TitleBox title_Settings_SetCondition,pos={60.00,346.00},size={57.00,12.00},disable=1,title="\\Z10Set A > Set B"
	TitleBox title_Settings_SetCondition,userdata(tabnum)=  "5"
	TitleBox title_Settings_SetCondition,userdata(tabcontrol)=  "ADC"
	TitleBox title_Settings_SetCondition,userdata(ResizeControlsInfo)= A"!!,E*!!#Bg!!#>r!!#;Mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox title_Settings_SetCondition,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	TitleBox title_Settings_SetCondition,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	TitleBox title_Settings_SetCondition,frame=0
	CheckBox check_Settings_Option_3,pos={246.00,360.00},size={132.00,30.00},disable=1,proc=DAP_CheckProc_LockedLogic,title="Repeat set B\runtil set A is complete"
	CheckBox check_Settings_Option_3,help={"This mode is useful when Set B contains a single wave."}
	CheckBox check_Settings_Option_3,userdata(tabnum)=  "5"
	CheckBox check_Settings_Option_3,userdata(tabcontrol)=  "ADC"
	CheckBox check_Settings_Option_3,userdata(ResizeControlsInfo)= A"!!,H1!!#Bn!!#@h!!#=Sz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_Settings_Option_3,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_Settings_Option_3,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_Settings_Option_3,value= 0
	CheckBox check_Settings_ScalingZero,pos={246.00,303.00},size={139.00,15.00},disable=1,title="Set channel scaling to 0"
	CheckBox check_Settings_ScalingZero,help={"Applies to DA channel outputting Set B"}
	CheckBox check_Settings_ScalingZero,userdata(tabnum)=  "5"
	CheckBox check_Settings_ScalingZero,userdata(tabcontrol)=  "ADC"
	CheckBox check_Settings_ScalingZero,userdata(ResizeControlsInfo)= A"!!,H1!!#BQJ,hqE!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_Settings_ScalingZero,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_Settings_ScalingZero,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_Settings_ScalingZero,value= 0
	CheckBox check_Settings_SetOption_04,pos={246.00,333.00},size={115.00,15.00},disable=3,title="Turn off headstage"
	CheckBox check_Settings_SetOption_04,help={"Turns off AD associated with DA via Channel and Amplifier Assignments"}
	CheckBox check_Settings_SetOption_04,userdata(tabnum)=  "5"
	CheckBox check_Settings_SetOption_04,userdata(tabcontrol)=  "ADC"
	CheckBox check_Settings_SetOption_04,userdata(ResizeControlsInfo)= A"!!,H1!!#B`J,hpu!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
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
	TitleBox title_Settings_SetCondition_04,userdata(ResizeControlsInfo)= A"!!,H*!!#B^!!#9W!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox title_Settings_SetCondition_04,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	TitleBox title_Settings_SetCondition_04,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	TitleBox title_Settings_SetCondition_04,frame=0
	TitleBox title_Settings_SetCondition_02,pos={238.00,307.00},size={5.00,15.00},disable=1,title="\\f01/"
	TitleBox title_Settings_SetCondition_02,userdata(tabnum)=  "5"
	TitleBox title_Settings_SetCondition_02,userdata(tabcontrol)=  "ADC"
	TitleBox title_Settings_SetCondition_02,userdata(ResizeControlsInfo)= A"!!,H)!!#BSJ,hj-!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox title_Settings_SetCondition_02,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	TitleBox title_Settings_SetCondition_02,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	TitleBox title_Settings_SetCondition_02,frame=0
	TitleBox title_Settings_SetCondition_03,pos={206.00,317.00},size={35.00,15.00},disable=1,title="\\f01-------"
	TitleBox title_Settings_SetCondition_03,userdata(tabnum)=  "5"
	TitleBox title_Settings_SetCondition_03,userdata(tabcontrol)=  "ADC"
	TitleBox title_Settings_SetCondition_03,userdata(ResizeControlsInfo)= A"!!,G^!!#BXJ,hnE!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
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
	SetVariable setvar_DataAcq_TerminationDelay,pos={287.00,657.00},size={177.00,18.00},bodyWidth=50,disable=1,title="Termination delay (ms)"
	SetVariable setvar_DataAcq_TerminationDelay,help={"Global set(s) termination delay. Continues recording after set sweep is complete. Useful when recorded phenomena continues after termination of final set epoch."}
	SetVariable setvar_DataAcq_TerminationDelay,userdata(tabnum)=  "0"
	SetVariable setvar_DataAcq_TerminationDelay,userdata(tabcontrol)=  "ADC"
	SetVariable setvar_DataAcq_TerminationDelay,userdata(ResizeControlsInfo)= A"!!,HJJ,ht_5QF/+!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
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
	Button button_SettingsPlus_PingDevice,pos={43.00,126.00},size={150.00,20.00},disable=2,proc=DAP_ButtonProc_Settings_OpenDev,title="Open device"
	Button button_SettingsPlus_PingDevice,help={"Step 3. Use to determine device number for connected device. Look for device with Ready light ON. Device numbers are determined in hardware and do not change over time. "}
	Button button_SettingsPlus_PingDevice,userdata(tabnum)=  "6"
	Button button_SettingsPlus_PingDevice,userdata(tabcontrol)=  "ADC"
	Button button_SettingsPlus_PingDevice,userdata(ResizeControlsInfo)= A"!!,D;!!#@`!!#A%!!#<Xz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_SettingsPlus_PingDevice,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	Button button_SettingsPlus_PingDevice,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	Button button_SettingsPlus_LockDevice,pos={203.00,73.00},size={85.00,46.00},proc=DAP_ButtonProc_LockDev,title="Lock device\r selection"
	Button button_SettingsPlus_LockDevice,help={"Device must be locked to acquire data. Locking can take a few seconds (calls to amp hardware are slow)."}
	Button button_SettingsPlus_LockDevice,userdata(tabnum)=  "6"
	Button button_SettingsPlus_LockDevice,userdata(tabcontrol)=  "ADC"
	Button button_SettingsPlus_LockDevice,userdata(ResizeControlsInfo)= A"!!,G[!!#?K!!#?c!!#>Fz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_SettingsPlus_LockDevice,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	Button button_SettingsPlus_LockDevice,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	Button button_SettingsPlus_unLockDevic,pos={295.00,73.00},size={85.00,46.00},disable=2,proc=DAP_ButProc_Hrdwr_UnlckDev,title="Unlock device\r selection"
	Button button_SettingsPlus_unLockDevic,userdata(tabnum)=  "6"
	Button button_SettingsPlus_unLockDevic,userdata(tabcontrol)=  "ADC"
	Button button_SettingsPlus_unLockDevic,userdata(ResizeControlsInfo)= A"!!,HNJ,hp!!!#?c!!#>Fz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_SettingsPlus_unLockDevic,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	Button button_SettingsPlus_unLockDevic,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	TitleBox title_Settings_SetCondition_1,pos={207.00,380.00},size={35.00,15.00},disable=1,title="\\f01-------"
	TitleBox title_Settings_SetCondition_1,userdata(tabnum)=  "5"
	TitleBox title_Settings_SetCondition_1,userdata(tabcontrol)=  "ADC"
	TitleBox title_Settings_SetCondition_1,userdata(ResizeControlsInfo)= A"!!,G_!!#C#!!#=o!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox title_Settings_SetCondition_1,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	TitleBox title_Settings_SetCondition_1,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	TitleBox title_Settings_SetCondition_1,frame=0
	TitleBox title_Settings_SetCondition_2,pos={239.00,391.00},size={5.00,15.00},disable=1,title="\\f01\\"
	TitleBox title_Settings_SetCondition_2,userdata(tabnum)=  "5"
	TitleBox title_Settings_SetCondition_2,userdata(tabcontrol)=  "ADC"
	TitleBox title_Settings_SetCondition_2,userdata(ResizeControlsInfo)= A"!!,H*!!#C(J,hj-!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox title_Settings_SetCondition_2,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	TitleBox title_Settings_SetCondition_2,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	TitleBox title_Settings_SetCondition_2,frame=0
	TitleBox title_Settings_SetCondition_3,pos={239.00,370.00},size={5.00,15.00},disable=1,title="\\f01/"
	TitleBox title_Settings_SetCondition_3,userdata(tabnum)=  "5"
	TitleBox title_Settings_SetCondition_3,userdata(tabcontrol)=  "ADC"
	TitleBox title_Settings_SetCondition_3,userdata(ResizeControlsInfo)= A"!!,H*!!#Bs!!#9W!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox title_Settings_SetCondition_3,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	TitleBox title_Settings_SetCondition_3,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	TitleBox title_Settings_SetCondition_3,frame=0
	CheckBox check_Settings_SetOption_5,pos={246.00,390.00},size={102.00,30.00},disable=1,proc=DAP_CheckProc_LockedLogic,title="Index to next set\ron DA with set B"
	CheckBox check_Settings_SetOption_5,help={"This mode is useful when Set B contains a single wave."}
	CheckBox check_Settings_SetOption_5,userdata(tabnum)=  "5"
	CheckBox check_Settings_SetOption_5,userdata(tabcontrol)=  "ADC"
	CheckBox check_Settings_SetOption_5,userdata(ResizeControlsInfo)= A"!!,H1!!#C(!!#@0!!#=Sz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_Settings_SetOption_5,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_Settings_SetOption_5,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox check_Settings_SetOption_5,value= 1
	TitleBox title_Settings_SetCondition1,pos={124.00,368.00},size={90.00,24.00},disable=1,title="\\Z10Continue acquisition\ron DA with set B"
	TitleBox title_Settings_SetCondition1,userdata(tabnum)=  "5"
	TitleBox title_Settings_SetCondition1,userdata(tabcontrol)=  "ADC"
	TitleBox title_Settings_SetCondition1,userdata(ResizeControlsInfo)= A"!!,F]!!#Br!!#?m!!#=#z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox title_Settings_SetCondition1,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	TitleBox title_Settings_SetCondition1,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	TitleBox title_Settings_SetCondition1,frame=0
	TitleBox title_Settings_SetCondition2,pos={126.00,308.00},size={86.00,24.00},disable=1,title="\\Z10Stop Acquisition on\rDA with Set B"
	TitleBox title_Settings_SetCondition2,userdata(tabnum)=  "5"
	TitleBox title_Settings_SetCondition2,userdata(tabcontrol)=  "ADC"
	TitleBox title_Settings_SetCondition2,userdata(ResizeControlsInfo)= A"!!,Fa!!#BT!!#?e!!#=#z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox title_Settings_SetCondition2,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	TitleBox title_Settings_SetCondition2,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	TitleBox title_Settings_SetCondition2,fSize=12,frame=0
	ValDisplay valdisp_DataAcq_SweepsInSet,pos={298.00,539.00},size={30.00,21.00},bodyWidth=30,disable=1
	ValDisplay valdisp_DataAcq_SweepsInSet,userdata(tabnum)=  "0"
	ValDisplay valdisp_DataAcq_SweepsInSet,userdata(tabcontrol)=  "ADC"
	ValDisplay valdisp_DataAcq_SweepsInSet,userdata(ResizeControlsInfo)= A"!!,HP!!#Ck^]6[i!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	ValDisplay valdisp_DataAcq_SweepsInSet,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	ValDisplay valdisp_DataAcq_SweepsInSet,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	ValDisplay valdisp_DataAcq_SweepsInSet,fSize=14,fStyle=0
	ValDisplay valdisp_DataAcq_SweepsInSet,valueColor=(65535,65535,65535)
	ValDisplay valdisp_DataAcq_SweepsInSet,valueBackColor=(0,0,0)
	ValDisplay valdisp_DataAcq_SweepsInSet,limits={0,0,0},barmisc={0,1000}
	ValDisplay valdisp_DataAcq_SweepsInSet,value= _NUM:1
	CheckBox Check_DataAcq1_IndexingLocked,pos={210.00,714.00},size={53.00,15.00},disable=1,proc=DAP_CheckProc_IndexingState,title="Locked"
	CheckBox Check_DataAcq1_IndexingLocked,help={"Data acquisition proceeds to next wave in DAC or TTL popup menu list"}
	CheckBox Check_DataAcq1_IndexingLocked,userdata(tabnum)=  "0"
	CheckBox Check_DataAcq1_IndexingLocked,userdata(tabcontrol)=  "ADC"
	CheckBox Check_DataAcq1_IndexingLocked,userdata(ResizeControlsInfo)= A"!!,Gb!!#DBJ,ho8!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_DataAcq1_IndexingLocked,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox Check_DataAcq1_IndexingLocked,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox Check_DataAcq1_IndexingLocked,value= 0
	SetVariable SetVar_DataAcq_ListRepeats,pos={134.00,734.00},size={109.00,18.00},bodyWidth=35,disable=1,proc=DAP_SetVarProc_TotSweepCount,title="Repeat List(s)"
	SetVariable SetVar_DataAcq_ListRepeats,help={"This number is set automatically at based on the number of 1d waves contained in the largest set on active DA/TTL channels"}
	SetVariable SetVar_DataAcq_ListRepeats,userdata(tabnum)=  "0"
	SetVariable SetVar_DataAcq_ListRepeats,userdata(tabcontrol)=  "ADC"
	SetVariable SetVar_DataAcq_ListRepeats,userdata(ResizeControlsInfo)= A"!!,Fk!!#DGJ,hpi!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_DataAcq_ListRepeats,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable SetVar_DataAcq_ListRepeats,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable SetVar_DataAcq_ListRepeats,fColor=(65280,43520,0)
	SetVariable SetVar_DataAcq_ListRepeats,limits={1,inf,1},value= _NUM:1
	CheckBox check_DataAcq_IndexRandom,pos={210.00,697.00},size={60.00,15.00},disable=1,title="Random"
	CheckBox check_DataAcq_IndexRandom,help={"Randomly selects wave from set selected for DAC channel on each trial. Doesn't repeat waves."}
	CheckBox check_DataAcq_IndexRandom,userdata(tabnum)=  "0"
	CheckBox check_DataAcq_IndexRandom,userdata(tabcontrol)=  "ADC"
	CheckBox check_DataAcq_IndexRandom,userdata(ResizeControlsInfo)= A"!!,Gb!!#D>5QF,i!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_DataAcq_IndexRandom,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_DataAcq_IndexRandom,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox check_DataAcq_IndexRandom,fColor=(65280,43520,0),value= 0
	ValDisplay valdisp_DataAcq_SweepsActiveSet,pos={298.00,566.00},size={30.00,21.00},bodyWidth=30,disable=1
	ValDisplay valdisp_DataAcq_SweepsActiveSet,help={"Displays the number of steps in the set with the most steps on active DA and TTL channels"}
	ValDisplay valdisp_DataAcq_SweepsActiveSet,userdata(tabnum)=  "0"
	ValDisplay valdisp_DataAcq_SweepsActiveSet,userdata(tabcontrol)=  "ADC"
	ValDisplay valdisp_DataAcq_SweepsActiveSet,userdata(ResizeControlsInfo)= A"!!,HP!!#CrJ,hn)!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	ValDisplay valdisp_DataAcq_SweepsActiveSet,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	ValDisplay valdisp_DataAcq_SweepsActiveSet,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	ValDisplay valdisp_DataAcq_SweepsActiveSet,fSize=14,fStyle=0
	ValDisplay valdisp_DataAcq_SweepsActiveSet,valueColor=(65535,65535,65535)
	ValDisplay valdisp_DataAcq_SweepsActiveSet,valueBackColor=(0,0,0)
	ValDisplay valdisp_DataAcq_SweepsActiveSet,limits={0,0,0},barmisc={0,1000}
	ValDisplay valdisp_DataAcq_SweepsActiveSet,value= _NUM:1
	SetVariable SetVar_DataAcq_TPAmplitudeIC,pos={381.00,417.00},size={65.00,18.00},bodyWidth=50,disable=1,proc=DAP_SetVarProc_TPAmp,title="IC"
	SetVariable SetVar_DataAcq_TPAmplitudeIC,help={"Amplitude of the testpulse in current clamp mode"}
	SetVariable SetVar_DataAcq_TPAmplitudeIC,userdata(tabnum)=  "0"
	SetVariable SetVar_DataAcq_TPAmplitudeIC,userdata(tabcontrol)=  "ADC"
	SetVariable SetVar_DataAcq_TPAmplitudeIC,userdata(ResizeControlsInfo)= A"!!,I$J,hs`J,hof!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
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
	GroupBox group_Settings_TP,pos={21.00,68.00},size={445.00,100.00},disable=1,title="Test Pulse"
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
	GroupBox group_DataAcq_ClampMode,pos={24.00,39.00},size={445.00,350.00},disable=1,title="Headstage"
	GroupBox group_DataAcq_ClampMode,userdata(tabnum)=  "0"
	GroupBox group_DataAcq_ClampMode,userdata(tabcontrol)=  "ADC"
	GroupBox group_DataAcq_ClampMode,userdata(ResizeControlsInfo)= A"!!,C$!!#>*!!#CCJ,hs?z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	GroupBox group_DataAcq_ClampMode,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	GroupBox group_DataAcq_ClampMode,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	GroupBox group_DataAcq_ClampMode1,pos={24.00,394.00},size={445.00,100.00},disable=1,title="Test Pulse"
	GroupBox group_DataAcq_ClampMode1,userdata(tabnum)=  "0"
	GroupBox group_DataAcq_ClampMode1,userdata(tabcontrol)=  "ADC"
	GroupBox group_DataAcq_ClampMode1,userdata(ResizeControlsInfo)= A"!!,C$!!#C*!!#CCJ,hpWz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	GroupBox group_DataAcq_ClampMode1,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	GroupBox group_DataAcq_ClampMode1,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	GroupBox group_DataAcq_ClampMode2,pos={24.00,498.00},size={445.00,120.00},disable=1,title="Status Information"
	GroupBox group_DataAcq_ClampMode2,userdata(tabnum)=  "0"
	GroupBox group_DataAcq_ClampMode2,userdata(tabcontrol)=  "ADC"
	GroupBox group_DataAcq_ClampMode2,userdata(ResizeControlsInfo)= A"!!,C$!!#C^!!#CCJ,hq*z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	GroupBox group_DataAcq_ClampMode2,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	GroupBox group_DataAcq_ClampMode2,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	TitleBox title_DataAcq_NextSweep,pos={211.00,513.00},size={71.00,19.00},disable=1,title="Next Sweep"
	TitleBox title_DataAcq_NextSweep,userdata(tabnum)=  "0"
	TitleBox title_DataAcq_NextSweep,userdata(tabcontrol)=  "ADC"
	TitleBox title_DataAcq_NextSweep,userdata(ResizeControlsInfo)= A"!!,Gc!!#Ce5QF-2!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox title_DataAcq_NextSweep,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	TitleBox title_DataAcq_NextSweep,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	TitleBox title_DataAcq_NextSweep,fSize=14,frame=0,fStyle=0
	TitleBox title_DataAcq_NextSweep1,pos={335.00,540.00},size={79.00,19.00},disable=1,title="Total Sweeps"
	TitleBox title_DataAcq_NextSweep1,userdata(tabnum)=  "0"
	TitleBox title_DataAcq_NextSweep1,userdata(tabcontrol)=  "ADC"
	TitleBox title_DataAcq_NextSweep1,userdata(ResizeControlsInfo)= A"!!,HbJ,htB!!#?W!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox title_DataAcq_NextSweep1,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	TitleBox title_DataAcq_NextSweep1,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	TitleBox title_DataAcq_NextSweep1,fSize=14,frame=0,fStyle=0
	TitleBox title_DataAcq_NextSweep2,pos={335.00,567.00},size={98.00,19.00},disable=1,title="Set Max Sweeps"
	TitleBox title_DataAcq_NextSweep2,userdata(tabnum)=  "0"
	TitleBox title_DataAcq_NextSweep2,userdata(tabcontrol)=  "ADC"
	TitleBox title_DataAcq_NextSweep2,userdata(ResizeControlsInfo)= A"!!,HbJ,htH^]6^>!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox title_DataAcq_NextSweep2,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	TitleBox title_DataAcq_NextSweep2,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	TitleBox title_DataAcq_NextSweep2,fSize=14,frame=0,fStyle=0
	TitleBox title_DataAcq_NextSweep3,pos={182.00,592.00},size={132.00,19.00},disable=1,title="Sampling Interval (µs)"
	TitleBox title_DataAcq_NextSweep3,userdata(tabnum)=  "0"
	TitleBox title_DataAcq_NextSweep3,userdata(tabcontrol)=  "ADC"
	TitleBox title_DataAcq_NextSweep3,userdata(ResizeControlsInfo)= A"!!,GF!!#D$!!#@h!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox title_DataAcq_NextSweep3,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	TitleBox title_DataAcq_NextSweep3,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	TitleBox title_DataAcq_NextSweep3,fSize=14,frame=0,fStyle=0
	GroupBox group_DataAcq_DataAcq,pos={24.00,622.00},size={446.00,228.00},disable=1,title="Data Acquisition"
	GroupBox group_DataAcq_DataAcq,userdata(tabnum)=  "0"
	GroupBox group_DataAcq_DataAcq,userdata(tabcontrol)=  "ADC"
	GroupBox group_DataAcq_DataAcq,userdata(ResizeControlsInfo)= A"!!,C$!!#D+J,hso!!#Asz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
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
	PopupMenu popup_Hardware_AvailITC1600s,pos={29.00,240.00},size={110.00,19.00},bodyWidth=110,disable=3,title="Locked ITC1600s"
	PopupMenu popup_Hardware_AvailITC1600s,userdata(tabnum)=  "6"
	PopupMenu popup_Hardware_AvailITC1600s,userdata(tabcontrol)=  "ADC"
	PopupMenu popup_Hardware_AvailITC1600s,userdata(ResizeControlsInfo)= A"!!,CL!!#B*!!#@@!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
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
	TitleBox title_hardware_1600inst,pos={29.00,176.00},size={307.00,15.00},disable=3,title="Designate the status of the ITC1600 assigned to this device"
	TitleBox title_hardware_1600inst,help={"If the device is designated to follow, the test pulse and data aquisition will be triggered from the lead panel."}
	TitleBox title_hardware_1600inst,userdata(tabnum)=  "6"
	TitleBox title_hardware_1600inst,userdata(tabcontrol)=  "ADC"
	TitleBox title_hardware_1600inst,userdata(ResizeControlsInfo)= A"!!,CL!!#A?!!#BSJ,hlSz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
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
	SetVariable setvar_Hardware_Status,pos={146.00,852.00},size={189.00,18.00},bodyWidth=99,title="ITC DAC Status:"
	SetVariable setvar_Hardware_Status,userdata(ResizeControlsInfo)= A"!!,G\"!!#De!!#AL!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_Hardware_Status,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable setvar_Hardware_Status,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable setvar_Hardware_Status,frame=0,fStyle=1,fColor=(65280,0,0)
	SetVariable setvar_Hardware_Status,valueBackColor=(60928,60928,60928)
	SetVariable setvar_Hardware_Status,value= _STR:"Independent",noedit= 1
	TitleBox title_hardware_Follow,pos={29.00,222.00},size={177.00,15.00},disable=3,title="Assign ITC1600 DACs as followers"
	TitleBox title_hardware_Follow,help={"If the device is designated to follow, the test pulse and data aquisition will be triggered from the lead panel."}
	TitleBox title_hardware_Follow,userdata(tabnum)=  "6"
	TitleBox title_hardware_Follow,userdata(tabcontrol)=  "ADC"
	TitleBox title_hardware_Follow,userdata(ResizeControlsInfo)= A"!!,CL!!#Am!!#A@!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
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
	SetVariable setvar_Hardware_YokeList,value= _STR:"No Yoked Devices",noedit= 1
	Button button_Hardware_RemoveYoke,pos={335.00,240.00},size={80.00,21.00},disable=3,proc=DAP_ButtonProc_YokeRelease,title="Release"
	Button button_Hardware_RemoveYoke,userdata(tabnum)=  "6"
	Button button_Hardware_RemoveYoke,userdata(tabcontrol)=  "ADC"
	Button button_Hardware_RemoveYoke,userdata(ResizeControlsInfo)= A"!!,HbJ,hrU!!#?Y!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_Hardware_RemoveYoke,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	Button button_Hardware_RemoveYoke,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	PopupMenu popup_Hardware_YokedDACs,pos={223.00,240.00},size={110.00,19.00},bodyWidth=110,disable=3,title="Yoked ITC1600s"
	PopupMenu popup_Hardware_YokedDACs,userdata(tabnum)=  "6"
	PopupMenu popup_Hardware_YokedDACs,userdata(tabcontrol)=  "ADC"
	PopupMenu popup_Hardware_YokedDACs,userdata(ResizeControlsInfo)= A"!!,Go!!#B*!!#@@!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu popup_Hardware_YokedDACs,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	PopupMenu popup_Hardware_YokedDACs,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	PopupMenu popup_Hardware_YokedDACs,mode=0,value= #"DAP_GUIListOfYokedDevices()"
	TitleBox title_hardware_Release,pos={225.00,222.00},size={162.00,15.00},disable=3,title="Release follower ITC1600 DACs"
	TitleBox title_hardware_Release,help={"If the device is designated to follow, the test pulse and data aquisition will be triggered from the lead panel."}
	TitleBox title_hardware_Release,userdata(tabnum)=  "6"
	TitleBox title_hardware_Release,userdata(tabcontrol)=  "ADC"
	TitleBox title_hardware_Release,userdata(ResizeControlsInfo)= A"!!,Gq!!#Am!!#A1!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox title_hardware_Release,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	TitleBox title_hardware_Release,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	TitleBox title_hardware_Release,frame=0
	TabControl tab_DataAcq_Amp,pos={32.00,148.00},size={425.00,120.00},disable=1,proc=ACL_DisplayTab
	TabControl tab_DataAcq_Amp,userdata(tabnum)=  "0",userdata(tabcontrol)=  "ADC"
	TabControl tab_DataAcq_Amp,userdata(currenttab)=  "0"
	TabControl tab_DataAcq_Amp,userdata(ResizeControlsInfo)= A"!!,Cd!!#A#!!#C9J,hq*z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TabControl tab_DataAcq_Amp,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	TabControl tab_DataAcq_Amp,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	TabControl tab_DataAcq_Amp,labelBack=(60928,60928,60928),fSize=10
	TabControl tab_DataAcq_Amp,tabLabel(0)="\f01\Z11V-Clamp",tabLabel(1)="I-Clamp"
	TabControl tab_DataAcq_Amp,tabLabel(2)="I = 0",value= 0
	TitleBox Title_DataAcq_Hold_IC,pos={97.00,186.00},size={69.00,15.00},disable=1,title="Holding (pA)"
	TitleBox Title_DataAcq_Hold_IC,userdata(tabnum)=  "1"
	TitleBox Title_DataAcq_Hold_IC,userdata(tabcontrol)=  "tab_DataAcq_Amp"
	TitleBox Title_DataAcq_Hold_IC,userdata(ResizeControlsInfo)= A"!!,F'!!#AI!!#?C!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox Title_DataAcq_Hold_IC,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	TitleBox Title_DataAcq_Hold_IC,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	TitleBox Title_DataAcq_Hold_IC,frame=0
	TitleBox Title_DataAcq_Bridge,pos={56.00,208.00},size={109.00,15.00},disable=1,title="Bridge Balance (MΩ)"
	TitleBox Title_DataAcq_Bridge,userdata(tabnum)=  "1"
	TitleBox Title_DataAcq_Bridge,userdata(tabcontrol)=  "tab_DataAcq_Amp"
	TitleBox Title_DataAcq_Bridge,userdata(ResizeControlsInfo)= A"!!,Do!!#A_!!#@>!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox Title_DataAcq_Bridge,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	TitleBox Title_DataAcq_Bridge,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	TitleBox Title_DataAcq_Bridge,frame=0
	SetVariable setvar_DataAcq_Hold_IC,pos={167.00,185.00},size={50.00,18.00},bodyWidth=50,disable=1,proc=DAP_SetVarProc_AmpCntrls
	SetVariable setvar_DataAcq_Hold_IC,userdata(tabnum)=  "1"
	SetVariable setvar_DataAcq_Hold_IC,userdata(tabcontrol)=  "tab_DataAcq_Amp"
	SetVariable setvar_DataAcq_Hold_IC,userdata(ResizeControlsInfo)= A"!!,G7!!#AH!!#>V!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_DataAcq_Hold_IC,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable setvar_DataAcq_Hold_IC,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable setvar_DataAcq_Hold_IC,value= _NUM:0
	SetVariable setvar_DataAcq_BB,pos={167.00,208.00},size={50.00,18.00},bodyWidth=50,disable=1,proc=DAP_SetVarProc_AmpCntrls
	SetVariable setvar_DataAcq_BB,userdata(tabnum)=  "1"
	SetVariable setvar_DataAcq_BB,userdata(tabcontrol)=  "tab_DataAcq_Amp"
	SetVariable setvar_DataAcq_BB,userdata(ResizeControlsInfo)= A"!!,G7!!#A_!!#>V!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_DataAcq_BB,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable setvar_DataAcq_BB,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable setvar_DataAcq_BB,limits={0,inf,1},value= _NUM:0
	SetVariable setvar_DataAcq_CN,pos={167.00,231.00},size={50.00,18.00},bodyWidth=50,disable=1,proc=DAP_SetVarProc_AmpCntrls
	SetVariable setvar_DataAcq_CN,userdata(tabnum)=  "1"
	SetVariable setvar_DataAcq_CN,userdata(tabcontrol)=  "tab_DataAcq_Amp"
	SetVariable setvar_DataAcq_CN,userdata(ResizeControlsInfo)= A"!!,G7!!#B!!!#>V!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_DataAcq_CN,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable setvar_DataAcq_CN,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable setvar_DataAcq_CN,limits={-8,16,1},value= _NUM:0
	CheckBox check_DatAcq_HoldEnable,pos={223.00,187.00},size={13.00,13.00},disable=1,proc=DAP_CheckProc_AmpCntrls,title=""
	CheckBox check_DatAcq_HoldEnable,userdata(tabnum)=  "1"
	CheckBox check_DatAcq_HoldEnable,userdata(tabcontrol)=  "tab_DataAcq_Amp"
	CheckBox check_DatAcq_HoldEnable,userdata(ResizeControlsInfo)= A"!!,Go!!#AJ!!#;]!!#;]z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_DatAcq_HoldEnable,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_DatAcq_HoldEnable,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox check_DatAcq_HoldEnable,value= 0
	CheckBox check_DatAcq_BBEnable,pos={223.00,210.00},size={13.00,13.00},disable=1,proc=DAP_CheckProc_AmpCntrls,title=""
	CheckBox check_DatAcq_BBEnable,userdata(tabnum)=  "1"
	CheckBox check_DatAcq_BBEnable,userdata(tabcontrol)=  "tab_DataAcq_Amp"
	CheckBox check_DatAcq_BBEnable,userdata(ResizeControlsInfo)= A"!!,Go!!#Aa!!#;]!!#;]z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_DatAcq_BBEnable,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_DatAcq_BBEnable,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox check_DatAcq_BBEnable,value= 0
	CheckBox check_DatAcq_CNEnable,pos={223.00,233.00},size={13.00,13.00},disable=1,proc=DAP_CheckProc_AmpCntrls,title=""
	CheckBox check_DatAcq_CNEnable,userdata(tabnum)=  "1"
	CheckBox check_DatAcq_CNEnable,userdata(tabcontrol)=  "tab_DataAcq_Amp"
	CheckBox check_DatAcq_CNEnable,userdata(ResizeControlsInfo)= A"!!,Go!!#B#!!#;]!!#;]z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_DatAcq_CNEnable,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_DatAcq_CNEnable,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox check_DatAcq_CNEnable,value= 0
	TitleBox Title_DataAcq_CN,pos={44.00,232.00},size={122.00,15.00},disable=1,title="Cap Neutralization (pF)"
	TitleBox Title_DataAcq_CN,userdata(tabnum)=  "1"
	TitleBox Title_DataAcq_CN,userdata(tabcontrol)=  "tab_DataAcq_Amp"
	TitleBox Title_DataAcq_CN,userdata(ResizeControlsInfo)= A"!!,D?!!#B\"!!#@X!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox Title_DataAcq_CN,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	TitleBox Title_DataAcq_CN,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	TitleBox Title_DataAcq_CN,frame=0
	Slider slider_DataAcq_ActiveHeadstage,pos={129.00,129.00},size={255.00,20.00},disable=1,proc=DAP_SliderProc_MIESHeadStage
	Slider slider_DataAcq_ActiveHeadstage,userdata(tabnum)=  "0"
	Slider slider_DataAcq_ActiveHeadstage,userdata(tabcontrol)=  "ADC"
	Slider slider_DataAcq_ActiveHeadstage,userdata(ResizeControlsInfo)= A"!!,Ff!!#@e!!#B9!!#<Xz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Slider slider_DataAcq_ActiveHeadstage,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	Slider slider_DataAcq_ActiveHeadstage,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	Slider slider_DataAcq_ActiveHeadstage,labelBack=(60928,60928,60928)
	Slider slider_DataAcq_ActiveHeadstage,limits={0,7,1},value= 0,live= 0,side= 2,vert= 0,ticks= 0,thumbColor= (43520,43520,43520)
	SetVariable setvar_DataAcq_AutoBiasV,pos={287.00,218.00},size={101.00,18.00},bodyWidth=50,disable=1,proc=DAP_SetVarProc_AmpCntrls,title="Vm (mV)"
	SetVariable setvar_DataAcq_AutoBiasV,userdata(tabnum)=  "1"
	SetVariable setvar_DataAcq_AutoBiasV,userdata(tabcontrol)=  "tab_DataAcq_Amp"
	SetVariable setvar_DataAcq_AutoBiasV,userdata(ResizeControlsInfo)= A"!!,HJJ,hr?!!#@.!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_DataAcq_AutoBiasV,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable setvar_DataAcq_AutoBiasV,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable setvar_DataAcq_AutoBiasV,value= _NUM:-70
	CheckBox check_DataAcq_AutoBias,pos={321.00,198.00},size={65.00,15.00},disable=1,proc=DAP_CheckProc_AmpCntrls,title="Auto Bias"
	CheckBox check_DataAcq_AutoBias,help={"Just prior to a sweep the Vm is checked and the bias current is adjusted to maintain desired Vm."}
	CheckBox check_DataAcq_AutoBias,userdata(tabnum)=  "1"
	CheckBox check_DataAcq_AutoBias,userdata(tabcontrol)=  "tab_DataAcq_Amp"
	CheckBox check_DataAcq_AutoBias,userdata(ResizeControlsInfo)= A"!!,H[J,hr+!!#?;!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_DataAcq_AutoBias,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_DataAcq_AutoBias,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox check_DataAcq_AutoBias,value= 0,side= 1
	SetVariable setvar_DataAcq_IbiasMax,pos={298.00,241.00},size={136.00,20.00},bodyWidth=50,disable=1,proc=DAP_SetVarProc_AmpCntrls,title="max I \\Bbias\\M (pA) ±"
	SetVariable setvar_DataAcq_IbiasMax,userdata(tabcontrol)=  "tab_DataAcq_Amp"
	SetVariable setvar_DataAcq_IbiasMax,userdata(tabnum)=  "1"
	SetVariable setvar_DataAcq_IbiasMax,userdata(ResizeControlsInfo)= A"!!,HP!!#B+!!#@l!!#<Xz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_DataAcq_IbiasMax,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable setvar_DataAcq_IbiasMax,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable setvar_DataAcq_IbiasMax,value= _NUM:200
	SetVariable setvar_DataAcq_AutoBiasVrange,pos={392.00,218.00},size={62.00,18.00},bodyWidth=50,disable=1,proc=DAP_SetVarProc_AmpCntrls,title="±"
	SetVariable setvar_DataAcq_AutoBiasVrange,userdata(tabcontrol)=  "tab_DataAcq_Amp"
	SetVariable setvar_DataAcq_AutoBiasVrange,userdata(tabnum)=  "1"
	SetVariable setvar_DataAcq_AutoBiasVrange,userdata(ResizeControlsInfo)= A"!!,I*!!#Ai!!#?1!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
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
	SetVariable setvar_DataAcq_Hold_VC,pos={42.00,173.00},size={93.00,18.00},bodyWidth=46,disable=1,proc=DAP_SetVarProc_AmpCntrls,title="Holding"
	SetVariable setvar_DataAcq_Hold_VC,userdata(tabnum)=  "0"
	SetVariable setvar_DataAcq_Hold_VC,userdata(tabcontrol)=  "tab_DataAcq_Amp"
	SetVariable setvar_DataAcq_Hold_VC,userdata(ResizeControlsInfo)= A"!!,D7!!#A<!!#?s!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_DataAcq_Hold_VC,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable setvar_DataAcq_Hold_VC,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable setvar_DataAcq_Hold_VC,value= _NUM:0
	TitleBox Title_DataAcq_PipOffset_VC,pos={245.00,176.00},size={101.00,15.00},disable=1,title="Pipette Offset (mV)"
	TitleBox Title_DataAcq_PipOffset_VC,userdata(tabnum)=  "0"
	TitleBox Title_DataAcq_PipOffset_VC,userdata(tabcontrol)=  "tab_DataAcq_Amp"
	TitleBox Title_DataAcq_PipOffset_VC,userdata(ResizeControlsInfo)= A"!!,H0!!#A?!!#@.!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox Title_DataAcq_PipOffset_VC,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	TitleBox Title_DataAcq_PipOffset_VC,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	TitleBox Title_DataAcq_PipOffset_VC,frame=0
	SetVariable setvar_DataAcq_PipetteOffset_VC,pos={348.00,175.00},size={50.00,18.00},bodyWidth=50,disable=1,proc=DAP_SetVarProc_AmpCntrls
	SetVariable setvar_DataAcq_PipetteOffset_VC,userdata(tabnum)=  "0"
	SetVariable setvar_DataAcq_PipetteOffset_VC,userdata(tabcontrol)=  "tab_DataAcq_Amp"
	SetVariable setvar_DataAcq_PipetteOffset_VC,userdata(ResizeControlsInfo)= A"!!,Hi!!#A>!!#>V!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_DataAcq_PipetteOffset_VC,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable setvar_DataAcq_PipetteOffset_VC,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable setvar_DataAcq_PipetteOffset_VC,value= _NUM:0
	Button button_DataAcq_AutoPipOffset_VC,pos={401.00,175.00},size={40.00,20.00},disable=1,proc=DAP_ButtonProc_AmpCntrls,title="Auto"
	Button button_DataAcq_AutoPipOffset_VC,help={"Automatically calculate the pipette offset"}
	Button button_DataAcq_AutoPipOffset_VC,userdata(tabnum)=  "0"
	Button button_DataAcq_AutoPipOffset_VC,userdata(tabcontrol)=  "tab_DataAcq_Amp"
	Button button_DataAcq_AutoPipOffset_VC,userdata(ResizeControlsInfo)= A"!!,I.J,hqi!!#>.!!#<Xz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_DataAcq_AutoPipOffset_VC,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	Button button_DataAcq_AutoPipOffset_VC,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	GroupBox group_pipette_offset_VC,pos={238.00,171.00},size={210.00,28.00},disable=1
	GroupBox group_pipette_offset_VC,userdata(tabnum)=  "0"
	GroupBox group_pipette_offset_VC,userdata(tabcontrol)=  "tab_DataAcq_Amp"
	GroupBox group_pipette_offset_VC,userdata(ResizeControlsInfo)= A"!!,H)!!#A:!!#Aa!!#=Cz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	GroupBox group_pipette_offset_VC,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	GroupBox group_pipette_offset_VC,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	GroupBox group_pipette_offset_IC,pos={244.00,171.00},size={210.00,28.00},disable=1
	GroupBox group_pipette_offset_IC,userdata(tabnum)=  "1"
	GroupBox group_pipette_offset_IC,userdata(tabcontrol)=  "tab_DataAcq_Amp"
	GroupBox group_pipette_offset_IC,userdata(ResizeControlsInfo)= A"!!,H/!!#A:!!#Aa!!#=Cz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	GroupBox group_pipette_offset_IC,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	GroupBox group_pipette_offset_IC,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	Button button_DataAcq_AutoPipOffset_IC,pos={407.00,175.00},size={40.00,20.00},disable=1,proc=DAP_ButtonProc_AmpCntrls,title="Auto"
	Button button_DataAcq_AutoPipOffset_IC,help={"Automatically calculate the pipette offset"}
	Button button_DataAcq_AutoPipOffset_IC,userdata(tabnum)=  "1"
	Button button_DataAcq_AutoPipOffset_IC,userdata(tabcontrol)=  "tab_DataAcq_Amp"
	Button button_DataAcq_AutoPipOffset_IC,userdata(ResizeControlsInfo)= A"!!,I1J,hqi!!#>.!!#<Xz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_DataAcq_AutoPipOffset_IC,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	Button button_DataAcq_AutoPipOffset_IC,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	TitleBox Title_DataAcq_PipOffset_IC,pos={251.00,176.00},size={101.00,15.00},disable=1,title="Pipette Offset (mV)"
	TitleBox Title_DataAcq_PipOffset_IC,userdata(tabnum)=  "1"
	TitleBox Title_DataAcq_PipOffset_IC,userdata(tabcontrol)=  "tab_DataAcq_Amp"
	TitleBox Title_DataAcq_PipOffset_IC,userdata(ResizeControlsInfo)= A"!!,H6!!#A?!!#@.!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox Title_DataAcq_PipOffset_IC,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	TitleBox Title_DataAcq_PipOffset_IC,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	TitleBox Title_DataAcq_PipOffset_IC,frame=0
	SetVariable setvar_DataAcq_PipetteOffset_IC,pos={354.00,175.00},size={50.00,18.00},bodyWidth=50,disable=1,proc=DAP_SetVarProc_AmpCntrls
	SetVariable setvar_DataAcq_PipetteOffset_IC,userdata(tabnum)=  "1"
	SetVariable setvar_DataAcq_PipetteOffset_IC,userdata(tabcontrol)=  "tab_DataAcq_Amp"
	SetVariable setvar_DataAcq_PipetteOffset_IC,userdata(ResizeControlsInfo)= A"!!,Hl!!#A>!!#>V!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_DataAcq_PipetteOffset_IC,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable setvar_DataAcq_PipetteOffset_IC,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable setvar_DataAcq_PipetteOffset_IC,value= _NUM:0
	CheckBox check_DatAcq_HoldEnableVC,pos={142.00,174.00},size={50.00,15.00},disable=1,proc=DAP_CheckProc_AmpCntrls,title="Enable"
	CheckBox check_DatAcq_HoldEnableVC,userdata(tabnum)=  "0"
	CheckBox check_DatAcq_HoldEnableVC,userdata(tabcontrol)=  "tab_DataAcq_Amp"
	CheckBox check_DatAcq_HoldEnableVC,userdata(ResizeControlsInfo)= A"!!,Fs!!#A=!!#>V!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_DatAcq_HoldEnableVC,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_DatAcq_HoldEnableVC,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox check_DatAcq_HoldEnableVC,value= 0
	SetVariable setvar_DataAcq_WCR,pos={112.00,219.00},size={74.00,18.00},bodyWidth=50,disable=1,proc=DAP_SetVarProc_AmpCntrls,title="MΩ"
	SetVariable setvar_DataAcq_WCR,userdata(tabnum)=  "0"
	SetVariable setvar_DataAcq_WCR,userdata(tabcontrol)=  "tab_DataAcq_Amp"
	SetVariable setvar_DataAcq_WCR,userdata(ResizeControlsInfo)= A"!!,FE!!#Aj!!#?M!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_DataAcq_WCR,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable setvar_DataAcq_WCR,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable setvar_DataAcq_WCR,value= _NUM:0
	CheckBox check_DatAcq_WholeCellEnable,pos={63.00,199.00},size={13.00,13.00},disable=1,proc=DAP_CheckProc_AmpCntrls,title=""
	CheckBox check_DatAcq_WholeCellEnable,userdata(tabnum)=  "0"
	CheckBox check_DatAcq_WholeCellEnable,userdata(tabcontrol)=  "tab_DataAcq_Amp"
	CheckBox check_DatAcq_WholeCellEnable,userdata(ResizeControlsInfo)= A"!!,E6!!#AV!!#;]!!#;]z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_DatAcq_WholeCellEnable,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_DatAcq_WholeCellEnable,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox check_DatAcq_WholeCellEnable,value= 0
	SetVariable setvar_DataAcq_WCC,pos={43.00,220.00},size={67.00,18.00},bodyWidth=50,disable=1,proc=DAP_SetVarProc_AmpCntrls,title="pF"
	SetVariable setvar_DataAcq_WCC,userdata(tabnum)=  "0"
	SetVariable setvar_DataAcq_WCC,userdata(tabcontrol)=  "tab_DataAcq_Amp"
	SetVariable setvar_DataAcq_WCC,userdata(ResizeControlsInfo)= A"!!,D;!!#Ak!!#??!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_DataAcq_WCC,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable setvar_DataAcq_WCC,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable setvar_DataAcq_WCC,limits={1,inf,1},value= _NUM:0
	Button button_DataAcq_WCAuto,pos={97.00,239.00},size={40.00,15.00},disable=1,proc=DAP_ButtonProc_AmpCntrls,title="Auto"
	Button button_DataAcq_WCAuto,userdata(tabnum)=  "0"
	Button button_DataAcq_WCAuto,userdata(tabcontrol)=  "tab_DataAcq_Amp"
	Button button_DataAcq_WCAuto,userdata(ResizeControlsInfo)= A"!!,F'!!#B)!!#>.!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_DataAcq_WCAuto,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	Button button_DataAcq_WCAuto,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	GroupBox group_DataAcq_RsCompensation,pos={200.00,200.00},size={185.00,62.00},disable=1,title="       Rs Compensation"
	GroupBox group_DataAcq_RsCompensation,userdata(tabnum)=  "0"
	GroupBox group_DataAcq_RsCompensation,userdata(tabcontrol)=  "tab_DataAcq_Amp"
	GroupBox group_DataAcq_RsCompensation,userdata(ResizeControlsInfo)= A"!!,GX!!#AW!!#AH!!#?1z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	GroupBox group_DataAcq_RsCompensation,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	GroupBox group_DataAcq_RsCompensation,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox check_DatAcq_RsCompEnable,pos={223.00,199.00},size={13.00,13.00},disable=1,proc=DAP_CheckProc_AmpCntrls,title=""
	CheckBox check_DatAcq_RsCompEnable,userdata(tabnum)=  "0"
	CheckBox check_DatAcq_RsCompEnable,userdata(tabcontrol)=  "tab_DataAcq_Amp"
	CheckBox check_DatAcq_RsCompEnable,userdata(ResizeControlsInfo)= A"!!,Go!!#AV!!#;]!!#;]z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_DatAcq_RsCompEnable,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_DatAcq_RsCompEnable,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox check_DatAcq_RsCompEnable,value= 0
	SetVariable setvar_DataAcq_RsCorr,pos={206.00,218.00},size={121.00,18.00},bodyWidth=40,disable=1,proc=DAP_SetVarProc_AmpCntrls,title="Correction (%)"
	SetVariable setvar_DataAcq_RsCorr,userdata(tabnum)=  "0"
	SetVariable setvar_DataAcq_RsCorr,userdata(tabcontrol)=  "tab_DataAcq_Amp"
	SetVariable setvar_DataAcq_RsCorr,userdata(ResizeControlsInfo)= A"!!,G^!!#Ai!!#@V!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_DataAcq_RsCorr,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable setvar_DataAcq_RsCorr,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable setvar_DataAcq_RsCorr,limits={0,100,1},value= _NUM:0
	SetVariable setvar_DataAcq_RsPred,pos={208.00,238.00},size={119.00,18.00},bodyWidth=40,disable=1,proc=DAP_SetVarProc_AmpCntrls,title="Prediction (%)"
	SetVariable setvar_DataAcq_RsPred,userdata(tabnum)=  "0"
	SetVariable setvar_DataAcq_RsPred,userdata(tabcontrol)=  "tab_DataAcq_Amp"
	SetVariable setvar_DataAcq_RsPred,userdata(ResizeControlsInfo)= A"!!,G`!!#B(!!#@R!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_DataAcq_RsPred,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable setvar_DataAcq_RsPred,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable setvar_DataAcq_RsPred,limits={0,100,1},value= _NUM:0
	Button button_DataAcq_FastComp_VC,pos={394.00,214.00},size={55.00,20.00},disable=1,proc=DAP_ButtonProc_AmpCntrls,title="Cp Fast"
	Button button_DataAcq_FastComp_VC,help={"Activates MCC auto fast capacitance compensation"}
	Button button_DataAcq_FastComp_VC,userdata(tabnum)=  "0"
	Button button_DataAcq_FastComp_VC,userdata(tabcontrol)=  "tab_DataAcq_Amp"
	Button button_DataAcq_FastComp_VC,userdata(ResizeControlsInfo)= A"!!,I+!!#Ae!!#>j!!#<Xz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_DataAcq_FastComp_VC,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	Button button_DataAcq_FastComp_VC,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	Button button_Hardware_AutoGainAndUnit,pos={399.00,409.00},size={40.00,47.00},proc=DAP_ButtonProc_AutoFillGain,title="Auto\rFill"
	Button button_Hardware_AutoGainAndUnit,help={"Queries the MultiClamp Commander for the gains of all connected amplifiers of this device."}
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
	GroupBox group_Settings_Amplifier,pos={21.00,574.00},size={444.00,100.00},disable=1,title="Amplifier"
	GroupBox group_Settings_Amplifier,userdata(tabnum)=  "5"
	GroupBox group_Settings_Amplifier,userdata(tabcontrol)=  "ADC"
	GroupBox group_Settings_Amplifier,userdata(ResizeControlsInfo)= A"!!,Ba!!#CtJ,hsn!!#@,z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	GroupBox group_Settings_Amplifier,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	GroupBox group_Settings_Amplifier,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox check_Settings_AmpMCCdefault,pos={34.00,598.00},size={190.00,15.00},disable=1,title="Default to MCC parameter values"
	CheckBox check_Settings_AmpMCCdefault,help={"FIXME"},userdata(tabnum)=  "5"
	CheckBox check_Settings_AmpMCCdefault,userdata(tabcontrol)=  "ADC"
	CheckBox check_Settings_AmpMCCdefault,userdata(ResizeControlsInfo)= A"!!,Cl!!#D%J,hr#!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_Settings_AmpMCCdefault,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_Settings_AmpMCCdefault,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox check_Settings_AmpMCCdefault,fColor=(65280,43520,0),value= 0
	CheckBox check_Settings_SyncMiesToMCC,pos={34.00,619.00},size={152.00,15.00},disable=1,title="Synchronize MIES to MCC"
	CheckBox check_Settings_SyncMiesToMCC,help={"Send the GUI values to the MCC on mode switch/headstage activation"}
	CheckBox check_Settings_SyncMiesToMCC,userdata(tabnum)=  "5"
	CheckBox check_Settings_SyncMiesToMCC,userdata(tabcontrol)=  "ADC"
	CheckBox check_Settings_SyncMiesToMCC,userdata(ResizeControlsInfo)= A"!!,Cl!!#D*^]6_=!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_Settings_SyncMiesToMCC,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_Settings_SyncMiesToMCC,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox check_Settings_SyncMiesToMCC,value= 0
	CheckBox check_DataAcq_Amp_Chain,pos={331.00,230.00},size={46.00,15.00},disable=1,proc=DAP_CheckProc_AmpCntrls,title="Chain"
	CheckBox check_DataAcq_Amp_Chain,userdata(tabnum)=  "0"
	CheckBox check_DataAcq_Amp_Chain,userdata(tabcontrol)=  "tab_DataAcq_Amp"
	CheckBox check_DataAcq_Amp_Chain,userdata(ResizeControlsInfo)= A"!!,H`J,hrK!!#>F!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
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
	CheckBox Check_DataAcq_Get_Set_ITI,pos={144.00,694.00},size={46.00,30.00},disable=1,proc=DAP_CheckProc_GetSet_ITI,title="Get\rset ITI"
	CheckBox Check_DataAcq_Get_Set_ITI,help={"When checked the stimulus set ITIs are used. The ITI is calculated as the maximum of all active stimulus set ITIs"}
	CheckBox Check_DataAcq_Get_Set_ITI,userdata(tabnum)=  "0"
	CheckBox Check_DataAcq_Get_Set_ITI,userdata(tabcontrol)=  "ADC"
	CheckBox Check_DataAcq_Get_Set_ITI,userdata(ResizeControlsInfo)= A"!!,Fu!!#D=J,hnq!!#=Sz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_DataAcq_Get_Set_ITI,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox Check_DataAcq_Get_Set_ITI,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox Check_DataAcq_Get_Set_ITI,value= 1
	SetVariable setvar_Settings_TPBuffer,pos={325.00,109.00},size={125.00,18.00},bodyWidth=50,disable=1,title="TP Buffer size"
	SetVariable setvar_Settings_TPBuffer,userdata(tabnum)=  "5"
	SetVariable setvar_Settings_TPBuffer,userdata(tabcontrol)=  "ADC"
	SetVariable setvar_Settings_TPBuffer,userdata(ResizeControlsInfo)= A"!!,H]J,hpi!!#@^!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_Settings_TPBuffer,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable setvar_Settings_TPBuffer,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable setvar_Settings_TPBuffer,limits={1,inf,1},value= _NUM:1
	CheckBox check_Settings_SaveAmpSettings,pos={326.00,597.00},size={113.00,15.00},disable=1,title="Save Amp Settings"
	CheckBox check_Settings_SaveAmpSettings,help={"Adds amplifier settings to lab note book for Multiclamp 700Bs ONLY!"}
	CheckBox check_Settings_SaveAmpSettings,userdata(tabnum)=  "5"
	CheckBox check_Settings_SaveAmpSettings,userdata(tabcontrol)=  "ADC"
	CheckBox check_Settings_SaveAmpSettings,userdata(ResizeControlsInfo)= A"!!,H^!!#D%5QF.1!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_Settings_SaveAmpSettings,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_Settings_SaveAmpSettings,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox check_Settings_SaveAmpSettings,value= 1
	SetVariable setvar_Settings_TP_RTolerance,pos={305.00,84.00},size={145.00,18.00},bodyWidth=50,disable=1,title="Min delta R (MΩ)"
	SetVariable setvar_Settings_TP_RTolerance,help={"Sets the minimum delta required forTP resistance values to be appended as a wave note to the data sweep. TP resistance values are always documented in the Lab Note Book."}
	SetVariable setvar_Settings_TP_RTolerance,userdata(tabnum)=  "5"
	SetVariable setvar_Settings_TP_RTolerance,userdata(tabcontrol)=  "ADC"
	SetVariable setvar_Settings_TP_RTolerance,userdata(ResizeControlsInfo)= A"!!,HSJ,hp7!!#@u!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_Settings_TP_RTolerance,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable setvar_Settings_TP_RTolerance,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable setvar_Settings_TP_RTolerance,limits={1,inf,1},value= _NUM:5
	CheckBox check_Settings_TP_SaveTPRecord,pos={342.00,133.00},size={93.00,15.00},disable=1,title="Save TP record"
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
	Button button_DataAcq_AutoBridgeBal_IC,userdata(ResizeControlsInfo)= A"!!,H+!!#A`!!#>.!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_DataAcq_AutoBridgeBal_IC,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	Button button_DataAcq_AutoBridgeBal_IC,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox Check_DataAcq_SendToAllAmp,pos={339.00,147.00},size={104.00,15.00},disable=1,title="Send to all Amps"
	CheckBox Check_DataAcq_SendToAllAmp,userdata(tabnum)=  "0"
	CheckBox Check_DataAcq_SendToAllAmp,userdata(tabcontrol)=  "ADC"
	CheckBox Check_DataAcq_SendToAllAmp,userdata(ResizeControlsInfo)= A"!!,HdJ,hqM!!#@4!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_DataAcq_SendToAllAmp,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox Check_DataAcq_SendToAllAmp,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox Check_DataAcq_SendToAllAmp,value= 0
	Button button_DataAcq_Seal,pos={147.00,299.00},size={84.00,27.00},disable=3,proc=ButtonProc_Seal,title="Seal"
	Button button_DataAcq_Seal,help={"Sets the I-clamp holding current based on the V-clamp holding potential"}
	Button button_DataAcq_Seal,userdata(tabnum)=  "0"
	Button button_DataAcq_Seal,userdata(tabcontrol)=  "tab_DataAcq_Pressure"
	Button button_DataAcq_Seal,userdata(ResizeControlsInfo)= A"!!,G#!!#BOJ,hp7!!#=;z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_DataAcq_Seal,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	Button button_DataAcq_Seal,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	Button button_DataAcq_BreakIn,pos={257.00,299.00},size={84.00,27.00},disable=3,proc=ButtonProc_BreakIn,title="Break In"
	Button button_DataAcq_BreakIn,help={"Sets the I-clamp holding current based on the V-clamp holding potential"}
	Button button_DataAcq_BreakIn,userdata(tabnum)=  "0"
	Button button_DataAcq_BreakIn,userdata(tabcontrol)=  "tab_DataAcq_Pressure"
	Button button_DataAcq_BreakIn,userdata(ResizeControlsInfo)= A"!!,H;J,hs%J,hp7!!#=;z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_DataAcq_BreakIn,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	Button button_DataAcq_BreakIn,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	Button button_DataAcq_Clear,pos={367.00,299.00},size={84.00,27.00},disable=3,proc=ButtonProc_Clear,title="Clear"
	Button button_DataAcq_Clear,help={"Attempts to clear the pipette tip to improve access resistance"}
	Button button_DataAcq_Clear,userdata(tabnum)=  "0"
	Button button_DataAcq_Clear,userdata(tabcontrol)=  "tab_DataAcq_Pressure"
	Button button_DataAcq_Clear,userdata(ResizeControlsInfo)= A"!!,HrJ,hs%J,hp7!!#=;z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_DataAcq_Clear,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	Button button_DataAcq_Clear,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox check_DatAcq_ClearEnable,pos={370.00,329.00},size={50.00,15.00},disable=3,proc=CheckProc_ClearEnable,title="Enable"
	CheckBox check_DatAcq_ClearEnable,userdata(tabnum)=  "0"
	CheckBox check_DatAcq_ClearEnable,userdata(tabcontrol)=  "tab_DataAcq_Pressure"
	CheckBox check_DatAcq_ClearEnable,userdata(ResizeControlsInfo)= A"!!,Ht!!#B^J,ho,!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_DatAcq_ClearEnable,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_DatAcq_ClearEnable,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox check_DatAcq_ClearEnable,value= 0
	CheckBox check_DatAcq_SealALl,pos={150.00,329.00},size={29.00,15.00},disable=3,title="All"
	CheckBox check_DatAcq_SealALl,help={"Seals all headstates with active test pulse"}
	CheckBox check_DatAcq_SealALl,userdata(tabnum)=  "0"
	CheckBox check_DatAcq_SealALl,userdata(tabcontrol)=  "tab_DataAcq_Pressure"
	CheckBox check_DatAcq_SealALl,userdata(ResizeControlsInfo)= A"!!,G&!!#B^J,hn!!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_DatAcq_SealALl,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_DatAcq_SealALl,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox check_DatAcq_SealALl,value= 0
	CheckBox check_DatAcq_BreakInAll,pos={260.00,329.00},size={29.00,15.00},disable=3,title="All"
	CheckBox check_DatAcq_BreakInAll,help={"Break in to all headstates with active test pulse"}
	CheckBox check_DatAcq_BreakInAll,userdata(tabnum)=  "0"
	CheckBox check_DatAcq_BreakInAll,userdata(tabcontrol)=  "tab_DataAcq_Pressure"
	CheckBox check_DatAcq_BreakInAll,userdata(ResizeControlsInfo)= A"!!,H=!!#B^J,hn!!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_DatAcq_BreakInAll,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_DatAcq_BreakInAll,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox check_DatAcq_BreakInAll,value= 0
	Button button_DataAcq_Approach,pos={37.00,299.00},size={84.00,27.00},disable=3,proc=ButtonProc_Approach,title="Approach"
	Button button_DataAcq_Approach,help={"Applies positive pressure to the pipette"}
	Button button_DataAcq_Approach,userdata(tabnum)=  "0"
	Button button_DataAcq_Approach,userdata(tabcontrol)=  "tab_DataAcq_Pressure"
	Button button_DataAcq_Approach,userdata(ResizeControlsInfo)= A"!!,D#!!#BOJ,hp7!!#=;z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_DataAcq_Approach,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	Button button_DataAcq_Approach,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox check_DatAcq_ApproachAll,pos={41.00,329.00},size={29.00,15.00},disable=3,title="All"
	CheckBox check_DatAcq_ApproachAll,help={"Apply postive pressure to all headstages"}
	CheckBox check_DatAcq_ApproachAll,userdata(tabnum)=  "0"
	CheckBox check_DatAcq_ApproachAll,userdata(tabcontrol)=  "tab_DataAcq_Pressure"
	CheckBox check_DatAcq_ApproachAll,userdata(ResizeControlsInfo)= A"!!,D3!!#B^J,hn!!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_DatAcq_ApproachAll,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_DatAcq_ApproachAll,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox check_DatAcq_ApproachAll,value= 0
	PopupMenu popup_Settings_Pressure_dev,pos={45.00,495.00},size={219.00,19.00},bodyWidth=150,proc=DAP_PopMenuProc_CAA,title="DAC devices"
	PopupMenu popup_Settings_Pressure_dev,help={"List of available DAC devices for pressure control"}
	PopupMenu popup_Settings_Pressure_dev,userdata(tabnum)=  "6"
	PopupMenu popup_Settings_Pressure_dev,userdata(tabcontrol)=  "ADC"
	PopupMenu popup_Settings_Pressure_dev,userdata(ResizeControlsInfo)= A"!!,DC!!#C\\J,hr@!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu popup_Settings_Pressure_dev,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	PopupMenu popup_Settings_Pressure_dev,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	PopupMenu popup_Settings_Pressure_dev,mode=1,popvalue="- none -",value= #"\"- none -\""
	TitleBox Title_settings_Hardware_Pressur,pos={45.00,475.00},size={44.00,15.00},title="Pressure"
	TitleBox Title_settings_Hardware_Pressur,userdata(tabnum)=  "6"
	TitleBox Title_settings_Hardware_Pressur,userdata(tabcontrol)=  "ADC"
	TitleBox Title_settings_Hardware_Pressur,userdata(ResizeControlsInfo)= A"!!,DC!!#CRJ,hni!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox Title_settings_Hardware_Pressur,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	TitleBox Title_settings_Hardware_Pressur,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	TitleBox Title_settings_Hardware_Pressur,frame=0
	PopupMenu Popup_Settings_Pressure_DA,pos={50.00,529.00},size={47.00,19.00},proc=DAP_PopMenuProc_CAA,title="DA"
	PopupMenu Popup_Settings_Pressure_DA,userdata(tabnum)=  "6"
	PopupMenu Popup_Settings_Pressure_DA,userdata(tabcontrol)=  "ADC"
	PopupMenu Popup_Settings_Pressure_DA,userdata(ResizeControlsInfo)= A"!!,D[!!#Ch!!#>J!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Popup_Settings_Pressure_DA,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	PopupMenu Popup_Settings_Pressure_DA,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	PopupMenu Popup_Settings_Pressure_DA,mode=1,popvalue="0",value= #"\"0;1;2;3;4;5;6;7\""
	PopupMenu Popup_Settings_Pressure_AD,pos={50.00,555.00},size={47.00,19.00},proc=DAP_PopMenuProc_CAA,title="AD"
	PopupMenu Popup_Settings_Pressure_AD,userdata(tabnum)=  "6"
	PopupMenu Popup_Settings_Pressure_AD,userdata(tabcontrol)=  "ADC"
	PopupMenu Popup_Settings_Pressure_AD,userdata(ResizeControlsInfo)= A"!!,D[!!#Cn5QF,5!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Popup_Settings_Pressure_AD,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	PopupMenu Popup_Settings_Pressure_AD,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	PopupMenu Popup_Settings_Pressure_AD,mode=1,popvalue="0",value= #"\"0;1;2;3;4;5;6;7;8;9;10;11;12;13;14;15\""
	SetVariable setvar_Settings_Pressure_DAgain,pos={111.00,529.00},size={50.00,18.00},proc=DAP_SetVarProc_CAA
	SetVariable setvar_Settings_Pressure_DAgain,userdata(tabnum)=  "6"
	SetVariable setvar_Settings_Pressure_DAgain,userdata(tabcontrol)=  "ADC"
	SetVariable setvar_Settings_Pressure_DAgain,userdata(ResizeControlsInfo)= A"!!,FE!!#ChJ,ho,!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_Settings_Pressure_DAgain,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable setvar_Settings_Pressure_DAgain,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable setvar_Settings_Pressure_DAgain,value= _NUM:2
	SetVariable setvar_Settings_Pressure_ADgain,pos={111.00,556.00},size={50.00,18.00},proc=DAP_SetVarProc_CAA
	SetVariable setvar_Settings_Pressure_ADgain,userdata(tabnum)=  "6"
	SetVariable setvar_Settings_Pressure_ADgain,userdata(tabcontrol)=  "ADC"
	SetVariable setvar_Settings_Pressure_ADgain,userdata(ResizeControlsInfo)= A"!!,FE!!#Cn^]6\\l!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_Settings_Pressure_ADgain,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable setvar_Settings_Pressure_ADgain,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable setvar_Settings_Pressure_ADgain,value= _NUM:0.5
	SetVariable SetVar_Hardware_Pressur_DA_Unit,pos={169.00,529.00},size={30.00,18.00},proc=DAP_SetVarProc_CAA
	SetVariable SetVar_Hardware_Pressur_DA_Unit,userdata(tabnum)=  "6"
	SetVariable SetVar_Hardware_Pressur_DA_Unit,userdata(tabcontrol)=  "ADC"
	SetVariable SetVar_Hardware_Pressur_DA_Unit,userdata(ResizeControlsInfo)= A"!!,G:!!#ChJ,hn)!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_Hardware_Pressur_DA_Unit,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable SetVar_Hardware_Pressur_DA_Unit,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable SetVar_Hardware_Pressur_DA_Unit,value= _STR:"psi"
	SetVariable SetVar_Hardware_Pressur_AD_Unit,pos={190.00,556.00},size={30.00,18.00},proc=DAP_SetVarProc_CAA
	SetVariable SetVar_Hardware_Pressur_AD_Unit,userdata(tabnum)=  "6"
	SetVariable SetVar_Hardware_Pressur_AD_Unit,userdata(tabcontrol)=  "ADC"
	SetVariable SetVar_Hardware_Pressur_AD_Unit,userdata(ResizeControlsInfo)= A"!!,GO!!#Cn^]6[i!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_Hardware_Pressur_AD_Unit,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable SetVar_Hardware_Pressur_AD_Unit,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable SetVar_Hardware_Pressur_AD_Unit,value= _STR:"psi"
	TitleBox Title_Hardware_Pressure_DA_Div,pos={203.00,529.00},size={15.00,15.00},title="/ V"
	TitleBox Title_Hardware_Pressure_DA_Div,userdata(tabnum)=  "6"
	TitleBox Title_Hardware_Pressure_DA_Div,userdata(tabcontrol)=  "ADC"
	TitleBox Title_Hardware_Pressure_DA_Div,userdata(ResizeControlsInfo)= A"!!,G\\!!#Ci!!#<(!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox Title_Hardware_Pressure_DA_Div,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	TitleBox Title_Hardware_Pressure_DA_Div,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	TitleBox Title_Hardware_Pressure_DA_Div,frame=0
	TitleBox Title_Hardware_Pressure_AD_Div,pos={171.00,557.00},size={15.00,15.00},title="V /"
	TitleBox Title_Hardware_Pressure_AD_Div,userdata(tabnum)=  "6"
	TitleBox Title_Hardware_Pressure_AD_Div,userdata(tabcontrol)=  "ADC"
	TitleBox Title_Hardware_Pressure_AD_Div,userdata(ResizeControlsInfo)= A"!!,G<!!#Co5QF)h!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox Title_Hardware_Pressure_AD_Div,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	TitleBox Title_Hardware_Pressure_AD_Div,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	TitleBox Title_Hardware_Pressure_AD_Div,frame=0
	PopupMenu Popup_Settings_Pressure_TTLA,pos={228.00,529.00},size={104.00,19.00},bodyWidth=70,proc=DAP_PopMenuProc_CAA,title="TTL A"
	PopupMenu Popup_Settings_Pressure_TTLA,help={"Select TTL channel for solenoid command"}
	PopupMenu Popup_Settings_Pressure_TTLA,userdata(tabnum)=  "6"
	PopupMenu Popup_Settings_Pressure_TTLA,userdata(tabcontrol)=  "ADC"
	PopupMenu Popup_Settings_Pressure_TTLA,userdata(ResizeControlsInfo)= A"!!,H#!!#Cg^]6^J!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Popup_Settings_Pressure_TTLA,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	PopupMenu Popup_Settings_Pressure_TTLA,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	PopupMenu Popup_Settings_Pressure_TTLA,mode=2,popvalue="0",value= #"\"\\\\M1(\\u200B- none -;0;1;2;3;4;5;6;7\""
	GroupBox group_Settings_Pressure,pos={23.00,677.00},size={445.00,130.00},disable=1,title="Pressure"
	GroupBox group_Settings_Pressure,userdata(tabnum)=  "5"
	GroupBox group_Settings_Pressure,userdata(tabcontrol)=  "ADC"
	GroupBox group_Settings_Pressure,userdata(ResizeControlsInfo)= A"!!,Bq!!#D95QF1.J,hq<z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	GroupBox group_Settings_Pressure,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	GroupBox group_Settings_Pressure,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable setvar_Settings_InAirP,pos={48.00,697.00},size={116.00,18.00},bodyWidth=50,disable=1,proc=DAP_SetVarProc_CAA,title="In air P (psi)"
	SetVariable setvar_Settings_InAirP,help={"Set the (positive) pressure applied to the pipette when the pipette is out of the bath."}
	SetVariable setvar_Settings_InAirP,userdata(tabnum)=  "5"
	SetVariable setvar_Settings_InAirP,userdata(tabcontrol)=  "ADC"
	SetVariable setvar_Settings_InAirP,userdata(ResizeControlsInfo)= A"!!,DO!!#D>5QF.7!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_Settings_InAirP,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable setvar_Settings_InAirP,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable setvar_Settings_InAirP,limits={-10,10,0.1},value= _NUM:3.8
	SetVariable setvar_Settings_InBathP,pos={172.00,698.00},size={127.00,18.00},bodyWidth=50,disable=1,proc=DAP_SetVarProc_CAA,title="In bath P (psi)"
	SetVariable setvar_Settings_InBathP,help={"Set the (positive) pressure applied to the pipette when the pipette is in the bath."}
	SetVariable setvar_Settings_InBathP,userdata(tabnum)=  "5"
	SetVariable setvar_Settings_InBathP,userdata(tabcontrol)=  "ADC"
	SetVariable setvar_Settings_InBathP,userdata(ResizeControlsInfo)= A"!!,G<!!#D>J,hq8!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_Settings_InBathP,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable setvar_Settings_InBathP,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable setvar_Settings_InBathP,limits={-10,10,0.1},value= _NUM:0.55
	SetVariable setvar_Settings_InSliceP,pos={326.00,698.00},size={126.00,18.00},bodyWidth=50,disable=1,proc=DAP_SetVarProc_CAA,title="In slice P (psi)"
	SetVariable setvar_Settings_InSliceP,help={"Set the (positive) pressure applied to the pipette when the pipette is in the tissue specimen."}
	SetVariable setvar_Settings_InSliceP,userdata(tabnum)=  "5"
	SetVariable setvar_Settings_InSliceP,userdata(tabcontrol)=  "ADC"
	SetVariable setvar_Settings_InSliceP,userdata(ResizeControlsInfo)= A"!!,H^!!#D>J,hq6!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_Settings_InSliceP,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable setvar_Settings_InSliceP,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable setvar_Settings_InSliceP,limits={-10,10,0.1},value= _NUM:0.2
	SetVariable setvar_Settings_NearCellP,pos={28.00,724.00},size={136.00,18.00},bodyWidth=50,disable=1,proc=DAP_SetVarProc_CAA,title="Near cell P (psi)"
	SetVariable setvar_Settings_NearCellP,help={"Set the (positive) pressure applied to the pipette when the pipette is close to the target neuron."}
	SetVariable setvar_Settings_NearCellP,userdata(tabnum)=  "5"
	SetVariable setvar_Settings_NearCellP,userdata(tabcontrol)=  "ADC"
	SetVariable setvar_Settings_NearCellP,userdata(ResizeControlsInfo)= A"!!,CD!!#DE!!#@l!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_Settings_NearCellP,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable setvar_Settings_NearCellP,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable setvar_Settings_NearCellP,limits={-1,1,0.1},value= _NUM:0.6
	SetVariable setvar_Settings_SealStartP,pos={168.00,725.00},size={131.00,18.00},bodyWidth=50,disable=1,proc=DAP_SetVarProc_CAA,title="Seal Init P (psi)"
	SetVariable setvar_Settings_SealStartP,help={"Set the starting negative pressure used to form a seal."}
	SetVariable setvar_Settings_SealStartP,userdata(tabnum)=  "5"
	SetVariable setvar_Settings_SealStartP,userdata(tabcontrol)=  "ADC"
	SetVariable setvar_Settings_SealStartP,userdata(ResizeControlsInfo)= A"!!,G8!!#DE5QF.R!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_Settings_SealStartP,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable setvar_Settings_SealStartP,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable setvar_Settings_SealStartP,limits={-10,0,0.1},value= _NUM:-0.2
	SetVariable setvar_Settings_SealMaxP,pos={316.00,725.00},size={136.00,18.00},bodyWidth=50,disable=1,proc=DAP_SetVarProc_CAA,title="Seal max P (psi)"
	SetVariable setvar_Settings_SealMaxP,help={"Set the maximum negative pressure used to form a seal."}
	SetVariable setvar_Settings_SealMaxP,userdata(tabnum)=  "5"
	SetVariable setvar_Settings_SealMaxP,userdata(tabcontrol)=  "ADC"
	SetVariable setvar_Settings_SealMaxP,userdata(ResizeControlsInfo)= A"!!,HY!!#DE5QF.W!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_Settings_SealMaxP,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable setvar_Settings_SealMaxP,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable setvar_Settings_SealMaxP,limits={-10,0,0.1},value= _NUM:-1.4
	SetVariable setvar_Settings_SurfaceHeight,pos={28.00,751.00},size={136.00,18.00},bodyWidth=50,disable=1,proc=DAP_SetVarProc_CAA,title="Sol surface\\Z11 (µm)"
	SetVariable setvar_Settings_SurfaceHeight,help={"Distance from the bottom of the recording chamber to the surface of the recording chamber solution."}
	SetVariable setvar_Settings_SurfaceHeight,userdata(tabnum)=  "5"
	SetVariable setvar_Settings_SurfaceHeight,userdata(tabcontrol)=  "ADC"
	SetVariable setvar_Settings_SurfaceHeight,userdata(ResizeControlsInfo)= A"!!,CD!!#DK^]6_-!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_Settings_SurfaceHeight,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable setvar_Settings_SurfaceHeight,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable setvar_Settings_SurfaceHeight,limits={0,inf,100},value= _NUM:3500
	SetVariable setvar_Settings_SliceSurfHeight,pos={168.00,751.00},size={144.00,18.00},bodyWidth=50,disable=1,proc=DAP_SetVarProc_CAA,title="Slice surface\\Z11 (µm)"
	SetVariable setvar_Settings_SliceSurfHeight,help={"Distance from the bottom of the recording chamber to the top surface of the slice."}
	SetVariable setvar_Settings_SliceSurfHeight,userdata(tabnum)=  "5"
	SetVariable setvar_Settings_SliceSurfHeight,userdata(tabcontrol)=  "ADC"
	SetVariable setvar_Settings_SliceSurfHeight,userdata(ResizeControlsInfo)= A"!!,G8!!#DK^]6_5!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_Settings_SliceSurfHeight,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable setvar_Settings_SliceSurfHeight,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable setvar_Settings_SliceSurfHeight,limits={0,inf,100},value= _NUM:350
	Button button_Settings_UpdateDACList,pos={271.00,494.00},size={191.00,22.00},proc=ButtonProc_Hrdwr_P_UpdtDAClist,title="Query connected DAC(s)"
	Button button_Settings_UpdateDACList,help={"Updates the popup menu contents to show the available ITC devices"}
	Button button_Settings_UpdateDACList,userdata(tabnum)=  "6"
	Button button_Settings_UpdateDACList,userdata(tabcontrol)=  "ADC"
	Button button_Settings_UpdateDACList,userdata(ResizeControlsInfo)= A"!!,HBJ,ht2!!#AN!!#<hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_Settings_UpdateDACList,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	Button button_Settings_UpdateDACList,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	Button button_Hardware_P_Enable,pos={337.00,529.00},size={60.00,46.00},proc=P_ButtonProc_Enable,title="Enable"
	Button button_Hardware_P_Enable,help={"Enable ITC devices used for pressure regulation."}
	Button button_Hardware_P_Enable,userdata(tabnum)=  "6"
	Button button_Hardware_P_Enable,userdata(tabcontrol)=  "ADC"
	Button button_Hardware_P_Enable,userdata(ResizeControlsInfo)= A"!!,HbJ,ht=5QF,i!!#>Fz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_Hardware_P_Enable,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	Button button_Hardware_P_Enable,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	Button button_Hardware_P_Enable,fSize=14
	Button button_Hardware_P_Disable,pos={401.00,529.00},size={60.00,46.00},disable=2,proc=P_ButtonProc_Disable,title="Disable"
	Button button_Hardware_P_Disable,help={"Enable ITC devices used for pressure regulation."}
	Button button_Hardware_P_Disable,userdata(tabnum)=  "6"
	Button button_Hardware_P_Disable,userdata(tabcontrol)=  "ADC"
	Button button_Hardware_P_Disable,userdata(ResizeControlsInfo)= A"!!,I/!!#Cg5QF,i!!#>Fz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_Hardware_P_Disable,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	Button button_Hardware_P_Disable,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	Button button_Hardware_P_Disable,fSize=14
	ValDisplay valdisp_DataAcq_P_0,pos={46.00,351.00},size={99.00,21.00},bodyWidth=35,disable=1,title="\\Z10Pressure (psi) "
	ValDisplay valdisp_DataAcq_P_0,help={"black background:user selected headstage"}
	ValDisplay valdisp_DataAcq_P_0,userdata(tabcontrol)=  "tab_DataAcq_Pressure"
	ValDisplay valdisp_DataAcq_P_0,userdata(ResizeControlsInfo)= A"!!,DG!!#BiJ,hpU!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	ValDisplay valdisp_DataAcq_P_0,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	ValDisplay valdisp_DataAcq_P_0,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	ValDisplay valdisp_DataAcq_P_0,fSize=14,frame=0,fStyle=0
	ValDisplay valdisp_DataAcq_P_0,valueColor=(65000,65000,65000)
	ValDisplay valdisp_DataAcq_P_0,valueBackColor=(65535,65535,65535,0)
	ValDisplay valdisp_DataAcq_P_0,limits={0,0,0},barmisc={0,1000},value= #"0.00"
	ValDisplay valdisp_DataAcq_P_1,pos={153.00,351.00},size={35.00,21.00},bodyWidth=35,disable=1
	ValDisplay valdisp_DataAcq_P_1,userdata(tabcontrol)=  "tab_DataAcq_Pressure"
	ValDisplay valdisp_DataAcq_P_1,userdata(ResizeControlsInfo)= A"!!,G)!!#BiJ,hnE!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	ValDisplay valdisp_DataAcq_P_1,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	ValDisplay valdisp_DataAcq_P_1,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	ValDisplay valdisp_DataAcq_P_1,fSize=14,frame=0,fStyle=0
	ValDisplay valdisp_DataAcq_P_1,valueColor=(65000,65000,65000)
	ValDisplay valdisp_DataAcq_P_1,valueBackColor=(65535,65535,65535,0)
	ValDisplay valdisp_DataAcq_P_1,limits={0,0,0},barmisc={0,1000},value= #"0.00"
	ValDisplay valdisp_DataAcq_P_2,pos={196.00,351.00},size={35.00,21.00},bodyWidth=35,disable=1
	ValDisplay valdisp_DataAcq_P_2,help={"black background:user selected headstage"}
	ValDisplay valdisp_DataAcq_P_2,userdata(tabcontrol)=  "tab_DataAcq_Pressure"
	ValDisplay valdisp_DataAcq_P_2,userdata(ResizeControlsInfo)= A"!!,GT!!#BiJ,hnE!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	ValDisplay valdisp_DataAcq_P_2,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	ValDisplay valdisp_DataAcq_P_2,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	ValDisplay valdisp_DataAcq_P_2,fSize=14,frame=0,fStyle=0
	ValDisplay valdisp_DataAcq_P_2,valueColor=(65000,65000,65000)
	ValDisplay valdisp_DataAcq_P_2,valueBackColor=(65535,65535,65535,0)
	ValDisplay valdisp_DataAcq_P_2,limits={0,0,0},barmisc={0,1000},value= #"0.00"
	ValDisplay valdisp_DataAcq_P_4,pos={282.00,351.00},size={35.00,21.00},bodyWidth=35,disable=1
	ValDisplay valdisp_DataAcq_P_4,help={"black background:user selected headstage"}
	ValDisplay valdisp_DataAcq_P_4,userdata(tabcontrol)=  "tab_DataAcq_Pressure"
	ValDisplay valdisp_DataAcq_P_4,userdata(ResizeControlsInfo)= A"!!,HH!!#BiJ,hnE!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	ValDisplay valdisp_DataAcq_P_4,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	ValDisplay valdisp_DataAcq_P_4,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	ValDisplay valdisp_DataAcq_P_4,fSize=14,frame=0,fStyle=0
	ValDisplay valdisp_DataAcq_P_4,valueBackColor=(65535,65535,65535,0)
	ValDisplay valdisp_DataAcq_P_4,limits={0,0,0},barmisc={0,1000},value= #"0.00"
	ValDisplay valdisp_DataAcq_P_5,pos={325.00,351.00},size={35.00,21.00},bodyWidth=35,disable=1
	ValDisplay valdisp_DataAcq_P_5,userdata(tabcontrol)=  "tab_DataAcq_Pressure"
	ValDisplay valdisp_DataAcq_P_5,userdata(ResizeControlsInfo)= A"!!,H]J,hs?J,hnE!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	ValDisplay valdisp_DataAcq_P_5,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	ValDisplay valdisp_DataAcq_P_5,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	ValDisplay valdisp_DataAcq_P_5,fSize=14,frame=0,fStyle=0
	ValDisplay valdisp_DataAcq_P_5,valueBackColor=(65535,65535,65535,0)
	ValDisplay valdisp_DataAcq_P_5,limits={0,0,0},barmisc={0,1000},value= #"0.00"
	ValDisplay valdisp_DataAcq_P_6,pos={368.00,351.00},size={35.00,21.00},bodyWidth=35,disable=1
	ValDisplay valdisp_DataAcq_P_6,help={"black background:user selected headstage"}
	ValDisplay valdisp_DataAcq_P_6,userdata(tabcontrol)=  "tab_DataAcq_Pressure"
	ValDisplay valdisp_DataAcq_P_6,userdata(ResizeControlsInfo)= A"!!,Hs!!#BiJ,hnE!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	ValDisplay valdisp_DataAcq_P_6,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	ValDisplay valdisp_DataAcq_P_6,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	ValDisplay valdisp_DataAcq_P_6,fSize=14,frame=0,fStyle=0
	ValDisplay valdisp_DataAcq_P_6,valueBackColor=(65535,65535,65535,0)
	ValDisplay valdisp_DataAcq_P_6,limits={0,0,0},barmisc={0,1000},value= #"0.00"
	ValDisplay valdisp_DataAcq_P_7,pos={411.00,351.00},size={35.00,21.00},bodyWidth=35,disable=1
	ValDisplay valdisp_DataAcq_P_7,userdata(tabcontrol)=  "tab_DataAcq_Pressure"
	ValDisplay valdisp_DataAcq_P_7,userdata(ResizeControlsInfo)= A"!!,I3J,hs?J,hnE!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	ValDisplay valdisp_DataAcq_P_7,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	ValDisplay valdisp_DataAcq_P_7,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	ValDisplay valdisp_DataAcq_P_7,fSize=14,frame=0,fStyle=0
	ValDisplay valdisp_DataAcq_P_7,valueBackColor=(65535,65535,65535,0)
	ValDisplay valdisp_DataAcq_P_7,limits={0,0,0},barmisc={0,1000},value= #"0.00"
	TabControl tab_DataAcq_Pressure,pos={32.00,272.00},size={425.00,110.00},disable=1,proc=ACL_DisplayTab
	TabControl tab_DataAcq_Pressure,userdata(tabnum)=  "0"
	TabControl tab_DataAcq_Pressure,userdata(tabcontrol)=  "ADC"
	TabControl tab_DataAcq_Pressure,userdata(currenttab)=  "1"
	TabControl tab_DataAcq_Pressure,userdata(ResizeControlsInfo)= A"!!,Cd!!#BB!!#C9J,hpkz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TabControl tab_DataAcq_Pressure,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	TabControl tab_DataAcq_Pressure,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	TabControl tab_DataAcq_Pressure,labelBack=(60928,60928,60928),fSize=10
	TabControl tab_DataAcq_Pressure,tabLabel(0)="Auto",tabLabel(1)="Manual"
	TabControl tab_DataAcq_Pressure,tabLabel(2)="User",value= 1
	Button button_DataAcq_SSSetPressureMan,pos={39.00,302.00},size={84.00,27.00},disable=3,proc=ButtonProc_DataAcq_ManPressSet,title="Apply"
	Button button_DataAcq_SSSetPressureMan,userdata(tabnum)=  "1"
	Button button_DataAcq_SSSetPressureMan,userdata(tabcontrol)=  "tab_DataAcq_Pressure"
	Button button_DataAcq_SSSetPressureMan,userdata(ResizeControlsInfo)= A"!!,D+!!#BQ!!#?a!!#=;z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_DataAcq_SSSetPressureMan,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	Button button_DataAcq_SSSetPressureMan,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	Button button_DataAcq_PPSetPressureMan,pos={200.00,302.00},size={90.00,27.00},disable=1,proc=ButtonProc_ManPP,title="Pressure Pulse"
	Button button_DataAcq_PPSetPressureMan,userdata(tabnum)=  "1"
	Button button_DataAcq_PPSetPressureMan,userdata(tabcontrol)=  "tab_DataAcq_Pressure"
	Button button_DataAcq_PPSetPressureMan,userdata(ResizeControlsInfo)= A"!!,GX!!#BQ!!#?m!!#=;z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_DataAcq_PPSetPressureMan,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	Button button_DataAcq_PPSetPressureMan,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable setvar_DataAcq_SSPressure,pos={125.00,307.00},size={69.00,18.00},bodyWidth=50,disable=1,proc=DAP_SetVarProc_CAA,title="psi"
	SetVariable setvar_DataAcq_SSPressure,userdata(tabnum)=  "1"
	SetVariable setvar_DataAcq_SSPressure,userdata(tabcontrol)=  "tab_DataAcq_Pressure"
	SetVariable setvar_DataAcq_SSPressure,userdata(ResizeControlsInfo)= A"!!,F_!!#BSJ,hon!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_DataAcq_SSPressure,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable setvar_DataAcq_SSPressure,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable setvar_DataAcq_SSPressure,limits={-10,10,1},value= _NUM:0
	SetVariable setvar_DataAcq_PPPressure,pos={291.00,307.00},size={69.00,18.00},bodyWidth=50,disable=1,proc=DAP_SetVarProc_CAA,title="psi"
	SetVariable setvar_DataAcq_PPPressure,userdata(tabnum)=  "1"
	SetVariable setvar_DataAcq_PPPressure,userdata(tabcontrol)=  "tab_DataAcq_Pressure"
	SetVariable setvar_DataAcq_PPPressure,userdata(ResizeControlsInfo)= A"!!,HLJ,hs)J,hon!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_DataAcq_PPPressure,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable setvar_DataAcq_PPPressure,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable setvar_DataAcq_PPPressure,limits={-10,10,1},value= _NUM:5
	SetVariable setvar_DataAcq_PPDuration,pos={362.00,307.00},size={87.00,18.00},bodyWidth=40,disable=1,proc=DAP_SetVarProc_CAA,title="Dur(ms)"
	SetVariable setvar_DataAcq_PPDuration,userdata(tabnum)=  "1"
	SetVariable setvar_DataAcq_PPDuration,userdata(tabcontrol)=  "tab_DataAcq_Pressure"
	SetVariable setvar_DataAcq_PPDuration,userdata(ResizeControlsInfo)= A"!!,Hp!!#BSJ,hp=!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_DataAcq_PPDuration,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable setvar_DataAcq_PPDuration,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable setvar_DataAcq_PPDuration,limits={0,300,1},value= _NUM:300
	CheckBox check_DataAcq_ManPressureAll,pos={69.00,332.00},size={29.00,15.00},disable=3,title="All"
	CheckBox check_DataAcq_ManPressureAll,userdata(tabnum)=  "1"
	CheckBox check_DataAcq_ManPressureAll,userdata(tabcontrol)=  "tab_DataAcq_Pressure"
	CheckBox check_DataAcq_ManPressureAll,userdata(ResizeControlsInfo)= A"!!,ED!!#B`!!#=K!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
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
	CheckBox check_DatAcq_ApproachNear,pos={80.00,329.00},size={40.00,15.00},disable=1,proc=P_Check_ApproachNear,title="Near"
	CheckBox check_DatAcq_ApproachNear,help={"Apply postive pressure to all headstages"}
	CheckBox check_DatAcq_ApproachNear,userdata(tabnum)=  "0"
	CheckBox check_DatAcq_ApproachNear,userdata(tabcontrol)=  "tab_DataAcq_Pressure"
	CheckBox check_DatAcq_ApproachNear,userdata(ResizeControlsInfo)= A"!!,EZ!!#B^J,hnY!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_DatAcq_ApproachNear,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_DatAcq_ApproachNear,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox check_DatAcq_ApproachNear,value= 0
	Button button_DataAcq_SlowComp_VC,pos={394.00,236.00},size={55.00,20.00},disable=1,proc=DAP_ButtonProc_AmpCntrls,title="Cp Slow"
	Button button_DataAcq_SlowComp_VC,help={"Activates MCC auto slow capacitance compensation"}
	Button button_DataAcq_SlowComp_VC,userdata(tabnum)=  "0"
	Button button_DataAcq_SlowComp_VC,userdata(tabcontrol)=  "tab_DataAcq_Amp"
	Button button_DataAcq_SlowComp_VC,userdata(ResizeControlsInfo)= A"!!,I+!!#B&!!#>j!!#<Xz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_DataAcq_SlowComp_VC,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	Button button_DataAcq_SlowComp_VC,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox check_DatAcq_SealAtm,pos={186.00,329.00},size={41.00,15.00},disable=1,proc=P_Check_SealAtm,title="Atm."
	CheckBox check_DatAcq_SealAtm,help={"Seals all headstates with active test pulse"}
	CheckBox check_DatAcq_SealAtm,userdata(tabnum)=  "0"
	CheckBox check_DatAcq_SealAtm,userdata(tabcontrol)=  "tab_DataAcq_Pressure"
	CheckBox check_DatAcq_SealAtm,userdata(ResizeControlsInfo)= A"!!,GJ!!#B^J,hn]!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_DatAcq_SealAtm,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_DatAcq_SealAtm,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox check_DatAcq_SealAtm,value= 0
	CheckBox Check_DataAcq1_DistribDaq,pos={132.00,644.00},size={100.00,15.00},disable=1,proc=DAP_CheckProc_SyncCtrl,title="distributed DAQ"
	CheckBox Check_DataAcq1_DistribDaq,help={"Determines if distributed acquisition is used."}
	CheckBox Check_DataAcq1_DistribDaq,userdata(tabnum)=  "0"
	CheckBox Check_DataAcq1_DistribDaq,userdata(tabcontrol)=  "ADC"
	CheckBox Check_DataAcq1_DistribDaq,userdata(ResizeControlsInfo)= A"!!,Fi!!#D1!!#@,!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_DataAcq1_DistribDaq,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_DataAcq1_DistribDaq,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_DataAcq1_DistribDaq,value= 0
	CheckBox Check_DataAcq1_dDAQOptOv,pos={148.00,660.00},size={61.00,15.00},bodyWidth=50,disable=1,proc=DAP_CheckProc_SyncCtrl,title="oodDAQ"
	CheckBox Check_DataAcq1_dDAQOptOv,help={"Optimizes the stim set layout for minimum length and no overlap."}
	CheckBox Check_DataAcq1_dDAQOptOv,userdata(tabnum)=  "0"
	CheckBox Check_DataAcq1_dDAQOptOv,userdata(tabcontrol)=  "ADC"
	CheckBox Check_DataAcq1_dDAQOptOv,userdata(ResizeControlsInfo)= A"!!,G$!!#D5!!#?-!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_DataAcq1_dDAQOptOv,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_DataAcq1_dDAQOptOv,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_DataAcq1_dDAQOptOv,value= 0
	SetVariable Setvar_DataAcq_dDAQDelay,pos={320.00,677.00},size={144.00,18.00},bodyWidth=50,disable=1,proc=DAP_SetVarProc_SyncCtrl,title="dDAQ delay (ms)"
	SetVariable Setvar_DataAcq_dDAQDelay,help={"Delay between the sets during distributed DAQ."}
	SetVariable Setvar_DataAcq_dDAQDelay,userdata(tabnum)=  "0"
	SetVariable Setvar_DataAcq_dDAQDelay,userdata(tabcontrol)=  "ADC"
	SetVariable Setvar_DataAcq_dDAQDelay,userdata(ResizeControlsInfo)= A"!!,H[!!#D95QF._!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Setvar_DataAcq_dDAQDelay,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Setvar_DataAcq_dDAQDelay,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Setvar_DataAcq_dDAQDelay,limits={0,inf,1},value= _NUM:0
	SetVariable setvar_DataAcq_dDAQOptOvPost,pos={280.00,716.00},size={184.00,18.00},bodyWidth=50,disable=1,proc=DAP_SetVarProc_SyncCtrl,title="oodDAQ post delay (ms)"
	SetVariable setvar_DataAcq_dDAQOptOvPost,help={"Timespan in ms after features in stimset not filled with another's stimset data. Used only for optimized overlay dDAQ."}
	SetVariable setvar_DataAcq_dDAQOptOvPost,userdata(tabnum)=  "0"
	SetVariable setvar_DataAcq_dDAQOptOvPost,userdata(tabcontrol)=  "ADC"
	SetVariable setvar_DataAcq_dDAQOptOvPost,userdata(ResizeControlsInfo)= A"!!,HG!!#DC!!#AG!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_DataAcq_dDAQOptOvPost,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_DataAcq_dDAQOptOvPost,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_DataAcq_dDAQOptOvPost,limits={0,inf,1},value= _NUM:0
	SetVariable setvar_DataAcq_dDAQOptOvPre,pos={286.00,696.00},size={178.00,18.00},bodyWidth=50,disable=1,proc=DAP_SetVarProc_SyncCtrl,title="oodDAQ pre delay (ms)"
	SetVariable setvar_DataAcq_dDAQOptOvPre,help={"Timespan in ms before features in stimset not filled with another's stimset data. Used only for optimized overlay dDAQ."}
	SetVariable setvar_DataAcq_dDAQOptOvPre,userdata(tabnum)=  "0"
	SetVariable setvar_DataAcq_dDAQOptOvPre,userdata(tabcontrol)=  "ADC"
	SetVariable setvar_DataAcq_dDAQOptOvPre,userdata(ResizeControlsInfo)= A"!!,HJ!!#D>!!#AA!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_DataAcq_dDAQOptOvPre,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_DataAcq_dDAQOptOvPre,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_DataAcq_dDAQOptOvPre,limits={0,inf,1},value= _NUM:0
	Button button_DataAcq_OpenCommentNB,pos={410.00,779.00},size={36.00,19.00},disable=1,proc=DAP_ButtonProc_OpenCommentNB,title="NB"
	Button button_DataAcq_OpenCommentNB,help={"Open a notebook displaying the comments of all sweeps and allowing free form additions by the user."}
	Button button_DataAcq_OpenCommentNB,userdata(tabnum)=  "0"
	Button button_DataAcq_OpenCommentNB,userdata(tabcontrol)=  "ADC"
	Button button_DataAcq_OpenCommentNB,userdata(ResizeControlsInfo)= A"!!,I3!!#DR^]6\\4!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
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
	PopupMenu popup_Settings_Manip_MSSMnipLst,userdata(ResizeControlsInfo)= A"!!,FE!!#D'!!#A%!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu popup_Settings_Manip_MSSMnipLst,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu popup_Settings_Manip_MSSMnipLst,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu popup_Settings_Manip_MSSMnipLst,mode=1,popvalue="- none -",value= #"\"- none -;\" + M_GetListOfAttachedManipulators()"
	CheckBox Check_Settings_NwbExport,pos={34.00,216.00},size={102.00,15.00},disable=1,title="Export into NWB"
	CheckBox Check_Settings_NwbExport,help={"Export all data including sweeps into a file in the NeurodataWithoutBorders fornat,"}
	CheckBox Check_Settings_NwbExport,userdata(tabnum)=  "5"
	CheckBox Check_Settings_NwbExport,userdata(tabcontrol)=  "ADC"
	CheckBox Check_Settings_NwbExport,userdata(ResizeControlsInfo)= A"!!,Cl!!#Ag!!#@0!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_Settings_NwbExport,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_Settings_NwbExport,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_Settings_NwbExport,value= 0
	SetVariable setvar_DataAcq_OnsetDelayUser,pos={297.00,638.00},size={167.00,18.00},bodyWidth=50,disable=1,title="User onset delay (ms)"
	SetVariable setvar_DataAcq_OnsetDelayUser,help={"A global parameter that delays the onset time of a set after the initiation of data acquistion. Data acquisition start time is NOT delayed. Useful when set(s) have insufficient baseline epoch."}
	SetVariable setvar_DataAcq_OnsetDelayUser,userdata(tabnum)=  "0"
	SetVariable setvar_DataAcq_OnsetDelayUser,userdata(tabcontrol)=  "ADC"
	SetVariable setvar_DataAcq_OnsetDelayUser,userdata(ResizeControlsInfo)= A"!!,HOJ,htZJ,hqa!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_DataAcq_OnsetDelayUser,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_DataAcq_OnsetDelayUser,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_DataAcq_OnsetDelayUser,limits={0,inf,1},value= _NUM:0
	ValDisplay valdisp_DataAcq_OnsetDelayAuto,pos={321.00,756.00},size={143.00,17.00},bodyWidth=50,disable=1,title="Onset delay (ms)"
	ValDisplay valdisp_DataAcq_OnsetDelayAuto,help={"The additional onset delay required by the \"Insert TP\" setting."}
	ValDisplay valdisp_DataAcq_OnsetDelayAuto,userdata(tabnum)=  "0"
	ValDisplay valdisp_DataAcq_OnsetDelayAuto,userdata(tabcontrol)=  "ADC"
	ValDisplay valdisp_DataAcq_OnsetDelayAuto,userdata(ResizeControlsInfo)= A"!!,H[J,hu#!!#@s!!#<@z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	ValDisplay valdisp_DataAcq_OnsetDelayAuto,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	ValDisplay valdisp_DataAcq_OnsetDelayAuto,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	ValDisplay valdisp_DataAcq_OnsetDelayAuto,limits={0,0,0},barmisc={0,1000}
	ValDisplay valdisp_DataAcq_OnsetDelayAuto,value= _NUM:0
	Button button_Hardware_ClearChanConn,pos={275.00,329.00},size={150.00,20.00},proc=DAP_ButtonProc_ClearChanCon,title="Clear Associations"
	Button button_Hardware_ClearChanConn,help={"Clear the channel/amplifier association of the current headstage."}
	Button button_Hardware_ClearChanConn,userdata(tabnum)=  "6"
	Button button_Hardware_ClearChanConn,userdata(tabcontrol)=  "ADC"
	Button button_Hardware_ClearChanConn,userdata(ResizeControlsInfo)= A"!!,HDJ,hs4J,hqP!!#<Xz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_Hardware_ClearChanConn,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button button_Hardware_ClearChanConn,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_Settings_DisablePressure,pos={365.00,749.00},size={86.00,30.00},disable=1,title="Stop pressure\ron data acq."
	CheckBox check_Settings_DisablePressure,help={"Turn off all pressure modes when data aquisition is initiated"}
	CheckBox check_Settings_DisablePressure,userdata(tabnum)=  "5"
	CheckBox check_Settings_DisablePressure,userdata(tabcontrol)=  "ADC"
	CheckBox check_Settings_DisablePressure,userdata(ResizeControlsInfo)= A"!!,HqJ,hu!5QF-P!!#=Sz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_Settings_DisablePressure,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_Settings_DisablePressure,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_Settings_DisablePressure,labelBack=(4369,4369,4369)
	CheckBox check_Settings_DisablePressure,value= 0,side= 1
	CheckBox check_Settings_AmpIEQZstep,pos={326.00,641.00},size={121.00,15.00},disable=1,title="Mode switch via I=0"
	CheckBox check_Settings_AmpIEQZstep,help={"Always switch from V-Clamp to I-Clamp and vice versa via I=0"}
	CheckBox check_Settings_AmpIEQZstep,userdata(tabnum)=  "5"
	CheckBox check_Settings_AmpIEQZstep,userdata(tabcontrol)=  "ADC"
	CheckBox check_Settings_AmpIEQZstep,userdata(ResizeControlsInfo)= A"!!,H^!!#D05QF.A!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_Settings_AmpIEQZstep,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_Settings_AmpIEQZstep,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox check_Settings_AmpIEQZstep,value= 0
	CheckBox check_Settings_RequireAmpConn,pos={325.00,619.00},size={107.00,15.00},disable=1,title="Require Amplifier"
	CheckBox check_Settings_RequireAmpConn,help={"Require that every active headstage is connected to an amplifier for TP/DAQ."}
	CheckBox check_Settings_RequireAmpConn,userdata(tabnum)=  "5"
	CheckBox check_Settings_RequireAmpConn,userdata(tabcontrol)=  "ADC"
	CheckBox check_Settings_RequireAmpConn,userdata(ResizeControlsInfo)= A"!!,H]J,htU^]6^P!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_Settings_RequireAmpConn,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_Settings_RequireAmpConn,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox check_Settings_RequireAmpConn,value= 1
	CheckBox Check_AD_All,pos={19.00,437.00},size={22.00,15.00},disable=1,proc=DAP_CheckProc_Channel_All,title="X"
	CheckBox Check_AD_All,help={"Set the active state of all AD channels"}
	CheckBox Check_AD_All,userdata(tabnum)=  "2",userdata(tabcontrol)=  "ADC"
	CheckBox Check_AD_All,userdata(ResizeControlsInfo)= A"!!,BQ!!#C?J,hm>!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_AD_All,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_AD_All,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_AD_All,value= 0,side= 1
	GroupBox Group_AD_all,pos={20.00,428.00},size={310.00,4.00},disable=1
	GroupBox Group_AD_all,userdata(tabnum)=  "2",userdata(tabcontrol)=  "ADC"
	GroupBox Group_AD_all,userdata(ResizeControlsInfo)= A"!!,BY!!#C;!!#BU!!#97z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	GroupBox Group_AD_all,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	GroupBox Group_AD_all,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_DA_ALL,pos={19.00,461.00},size={22.00,15.00},disable=1,proc=DAP_CheckProc_Channel_All,title="X"
	CheckBox Check_DA_ALL,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	CheckBox Check_DA_ALL,userdata(ResizeControlsInfo)= A"!!,BQ!!#CKJ,hm>!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_DA_ALL,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_DA_ALL,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_DA_ALL,value= 0,side= 1
	PopupMenu Wave_DA_All,pos={153.00,458.00},size={125.00,19.00},bodyWidth=125,disable=1,proc=DAP_PopMenuChkProc_StimSetList
	PopupMenu Wave_DA_All,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	PopupMenu Wave_DA_All,userdata(ResizeControlsInfo)= A"!!,G)!!#CJ!!#@^!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Wave_DA_All,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Wave_DA_All,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Wave_DA_All,fSize=10
	PopupMenu Wave_DA_All,mode=1,popvalue="- none -",value= #"\"- none -;\"+ReturnListOfAllStimSets(0,\"*DA*\")"
	SetVariable Search_DA_All,pos={153.00,482.00},size={124.00,18.00},disable=1,proc=DAP_SetVarProc_Channel_Search,title="Search string"
	SetVariable Search_DA_All,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	SetVariable Search_DA_All,userdata(ResizeControlsInfo)= A"!!,G)!!#CV!!#@\\!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Search_DA_All,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Search_DA_All,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Search_DA_All,value= _STR:""
	SetVariable Scale_DA_All,pos={290.00,458.00},size={50.00,18.00},bodyWidth=50,disable=1,proc=DAP_SetVarProc_DA_Scale
	SetVariable Scale_DA_All,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	SetVariable Scale_DA_All,userdata(ResizeControlsInfo)= A"!!,HL!!#CJ!!#>V!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Scale_DA_All,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Scale_DA_All,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Scale_DA_All,limits={-inf,inf,10},value= _NUM:1
	PopupMenu IndexEnd_DA_All,pos={353.00,458.00},size={125.00,19.00},bodyWidth=125,disable=1,proc=DAP_PopMenuChkProc_StimSetList
	PopupMenu IndexEnd_DA_All,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	PopupMenu IndexEnd_DA_All,userdata(ResizeControlsInfo)= A"!!,HkJ,hsu!!#@^!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu IndexEnd_DA_All,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu IndexEnd_DA_All,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu IndexEnd_DA_All,mode=1,popvalue="- none -",value= #"\"- none -;\"+ReturnListOfAllStimSets(0,\"*DA*\")"
	GroupBox Group_TTL_all,pos={20.00,447.00},size={345.00,5.00},disable=1
	GroupBox Group_TTL_all,userdata(tabnum)=  "3",userdata(tabcontrol)=  "ADC"
	GroupBox Group_TTL_all,userdata(ResizeControlsInfo)= A"!!,BY!!#CDJ,hs<J,hj-z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	GroupBox Group_TTL_all,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	GroupBox Group_TTL_all,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Wave_TTL_All,pos={103.00,460.00},size={125.00,19.00},bodyWidth=125,disable=1,proc=DAP_PopMenuChkProc_StimSetList
	PopupMenu Wave_TTL_All,userdata(tabnum)=  "3",userdata(tabcontrol)=  "ADC"
	PopupMenu Wave_TTL_All,userdata(ResizeControlsInfo)= A"!!,F3!!#CK!!#@^!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Wave_TTL_All,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Wave_TTL_All,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Wave_TTL_All,fSize=10
	PopupMenu Wave_TTL_All,mode=1,popvalue="- none -",value= #"\"- none -;\"+ReturnListOfAllStimSets(1,\"*TTL*\")"
	SetVariable Search_TTL_All,pos={103.00,482.00},size={124.00,18.00},disable=1,proc=DAP_SetVarProc_Channel_Search,title="Search string"
	SetVariable Search_TTL_All,userdata(tabnum)=  "3",userdata(tabcontrol)=  "ADC"
	SetVariable Search_TTL_All,userdata(ResizeControlsInfo)= A"!!,F3!!#CV!!#@\\!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Search_TTL_All,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Search_TTL_All,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Search_TTL_All,value= _STR:""
	PopupMenu IndexEnd_TTL_All,pos={243.00,460.00},size={125.00,19.00},bodyWidth=125,disable=1,proc=DAP_PopMenuChkProc_StimSetList
	PopupMenu IndexEnd_TTL_All,userdata(tabnum)=  "3",userdata(tabcontrol)=  "ADC"
	PopupMenu IndexEnd_TTL_All,userdata(ResizeControlsInfo)= A"!!,H.!!#CK!!#@^!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu IndexEnd_TTL_All,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu IndexEnd_TTL_All,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu IndexEnd_TTL_All,mode=1,popvalue="- none -",value= #"\"- none -;\"+ReturnListOfAllStimSets(1,\"*TTL*\")"
	CheckBox Check_TTL_ALL,pos={20.00,461.00},size={22.00,15.00},disable=1,proc=DAP_CheckProc_Channel_All,title="X"
	CheckBox Check_TTL_ALL,userdata(tabnum)=  "3"
	CheckBox Check_TTL_ALL,userdata(tabcontrol)=  "tab_DataAcq_Pressure"
	CheckBox Check_TTL_ALL,userdata(ResizeControlsInfo)= A"!!,BY!!#CKJ,hm>!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_TTL_ALL,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_TTL_ALL,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_TTL_ALL,value= 0
	CheckBox check_settings_show_power,pos={169.00,546.00},size={133.00,15.00},disable=1,title="Show power spectrum"
	CheckBox check_settings_show_power,help={"Show the power spectrum (Fourier Transform) of the testpulse"}
	CheckBox check_settings_show_power,userdata(tabnum)=  "5"
	CheckBox check_settings_show_power,userdata(tabcontrol)=  "ADC"
	CheckBox check_settings_show_power,userdata(ResizeControlsInfo)= A"!!,G9!!#CmJ,hq?!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_settings_show_power,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_settings_show_power,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox check_settings_show_power,value= 0
	SetVariable setvar_DataAcq_dDAQOptOvRes,pos={281.00,735.00},size={183.00,18.00},bodyWidth=50,disable=1,proc=DAP_SetVarProc_SyncCtrl,title="oodDAQ resolution (ms)"
	SetVariable setvar_DataAcq_dDAQOptOvRes,help={"The resolution used for finding an optimal offset. Processing time is linear with resolution, all feature in the stimset smaller than this value *might* be ignored."}
	SetVariable setvar_DataAcq_dDAQOptOvRes,userdata(tabnum)=  "0"
	SetVariable setvar_DataAcq_dDAQOptOvRes,userdata(tabcontrol)=  "ADC"
	SetVariable setvar_DataAcq_dDAQOptOvRes,userdata(ResizeControlsInfo)= A"!!,HGJ,htr^]6_\\!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_DataAcq_dDAQOptOvRes,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_DataAcq_dDAQOptOvRes,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_DataAcq_dDAQOptOvRes,limits={1,inf,1},value= _NUM:1
	PopupMenu Popup_Settings_Pressure_TTLB,pos={229.00,555.00},size={103.00,19.00},bodyWidth=70,proc=DAP_PopMenuProc_CAA,title="TTL B"
	PopupMenu Popup_Settings_Pressure_TTLB,help={"Select TTL channel for solenoid command"}
	PopupMenu Popup_Settings_Pressure_TTLB,userdata(tabnum)=  "6"
	PopupMenu Popup_Settings_Pressure_TTLB,userdata(tabcontrol)=  "ADC"
	PopupMenu Popup_Settings_Pressure_TTLB,userdata(ResizeControlsInfo)= A"!!,H!!!#Cn5QF-r!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Popup_Settings_Pressure_TTLB,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Popup_Settings_Pressure_TTLB,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Popup_Settings_Pressure_TTLB,mode=1,popvalue="- none -",value= #"\"- none -;0;1;2;3;4;5;6;7\""
	CheckBox check_Settings_UserP_Approach,pos={230.00,321.00},size={67.00,15.00},disable=1,proc=DAP_CheckProc_Settings_PUser,title="Approach"
	CheckBox check_Settings_UserP_Approach,help={"User applied pressure during approach mode "}
	CheckBox check_Settings_UserP_Approach,userdata(tabnum)=  "2"
	CheckBox check_Settings_UserP_Approach,userdata(tabcontrol)=  "tab_DataAcq_Pressure"
	CheckBox check_Settings_UserP_Approach,userdata(ResizeControlsInfo)= A"!!,H!!!#BZJ,hoj!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_Settings_UserP_Approach,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_Settings_UserP_Approach,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_Settings_UserP_Approach,value= 0
	CheckBox check_Settings_UserP_Seal,pos={300.00,321.00},size={36.00,15.00},disable=1,proc=DAP_CheckProc_Settings_PUser,title="Seal"
	CheckBox check_Settings_UserP_Seal,help={"User applied pressure during seal mode - holding potential and switch to atmospheric pressure remain automated"}
	CheckBox check_Settings_UserP_Seal,userdata(tabnum)=  "2"
	CheckBox check_Settings_UserP_Seal,userdata(tabcontrol)=  "tab_DataAcq_Pressure"
	CheckBox check_Settings_UserP_Seal,userdata(ResizeControlsInfo)= A"!!,HQ!!#BZJ,hnI!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_Settings_UserP_Seal,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_Settings_UserP_Seal,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_Settings_UserP_Seal,value= 0
	CheckBox check_Settings_UserP_BreakIn,pos={343.00,321.00},size={62.00,15.00},disable=1,proc=DAP_CheckProc_Settings_PUser,title="Break-In "
	CheckBox check_Settings_UserP_BreakIn,help={"User access during Break-in - pressure is set to atmospheric when the steady state resistance drops below 1 GΩ"}
	CheckBox check_Settings_UserP_BreakIn,userdata(tabnum)=  "2"
	CheckBox check_Settings_UserP_BreakIn,userdata(tabcontrol)=  "tab_DataAcq_Pressure"
	CheckBox check_Settings_UserP_BreakIn,userdata(ResizeControlsInfo)= A"!!,HfJ,hs0J,ho\\!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_Settings_UserP_BreakIn,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_Settings_UserP_BreakIn,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_Settings_UserP_BreakIn,value= 0
	CheckBox check_Settings_UserP_Clear,pos={407.00,321.00},size={42.00,15.00},disable=1,proc=DAP_CheckProc_Settings_PUser,title="Clear"
	CheckBox check_Settings_UserP_Clear,help={"User applied pressure during clear - user pressure access is turned OFF after 10% decrease in steady state resistance"}
	CheckBox check_Settings_UserP_Clear,userdata(tabnum)=  "2"
	CheckBox check_Settings_UserP_Clear,userdata(tabcontrol)=  "tab_DataAcq_Pressure"
	CheckBox check_Settings_UserP_Clear,userdata(ResizeControlsInfo)= A"!!,I1J,hs0J,hna!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_Settings_UserP_Clear,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_Settings_UserP_Clear,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_Settings_UserP_Clear,value= 0
	TitleBox title_Settings_Pressure_UserP,pos={227.00,302.00},size={125.00,15.00},disable=1,title="User pressure in modes:"
	TitleBox title_Settings_Pressure_UserP,userdata(tabnum)=  "2"
	TitleBox title_Settings_Pressure_UserP,userdata(tabcontrol)=  "tab_DataAcq_Pressure"
	TitleBox title_Settings_Pressure_UserP,userdata(ResizeControlsInfo)= A"!!,Gs!!#BQ!!#@^!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox title_Settings_Pressure_UserP,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	TitleBox title_Settings_Pressure_UserP,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	TitleBox title_Settings_Pressure_UserP,frame=0
	CheckBox check_DataACq_Pressure_User,pos={194.00,275.00},size={78.00,15.00},disable=1,proc=DAP_CheckProc_Settings_PUser,title=" User access"
	CheckBox check_DataACq_Pressure_User,help={"Routes pressure access between the user and the active headstage (selected by the slider)."}
	CheckBox check_DataACq_Pressure_User,userdata(tabcontrol)=  "tab_DataAcq_Pressure"
	CheckBox check_DataACq_Pressure_User,userdata(ResizeControlsInfo)= A"!!,GR!!#BCJ,hp+!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_DataACq_Pressure_User,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_DataACq_Pressure_User,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_DataACq_Pressure_User,value= 0
	CheckBox check_DataACq_Pressure_AutoOFF,pos={106.00,321.00},size={91.00,15.00},disable=1,proc=DAP_CheckProc_Settings_PUser,title="Auto User OFF"
	CheckBox check_DataACq_Pressure_AutoOFF,help={"Turns OFF user access when a new HS is selected by the user."}
	CheckBox check_DataACq_Pressure_AutoOFF,userdata(tabnum)=  "2"
	CheckBox check_DataACq_Pressure_AutoOFF,userdata(tabcontrol)=  "tab_DataAcq_Pressure"
	CheckBox check_DataACq_Pressure_AutoOFF,userdata(ResizeControlsInfo)= A"!!,F9!!#BZJ,hpE!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_DataACq_Pressure_AutoOFF,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_DataACq_Pressure_AutoOFF,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_DataACq_Pressure_AutoOFF,value= 0
	GroupBox group_DA_All,pos={11.00,442.00},size={471.00,74.00},disable=1,title="All"
	GroupBox group_DA_All,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	GroupBox group_DA_All,userdata(ResizeControlsInfo)= A"!!,A>!!#CB!!#CPJ,hp#z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	GroupBox group_DA_All,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	GroupBox group_DA_All,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_DA_AllVClamp,pos={19.00,543.00},size={22.00,15.00},disable=1,proc=DAP_CheckProc_Channel_All,title="X"
	CheckBox Check_DA_AllVClamp,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	CheckBox Check_DA_AllVClamp,userdata(ResizeControlsInfo)= A"!!,BQ!!#Cl^]6[)!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_DA_AllVClamp,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_DA_AllVClamp,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_DA_AllVClamp,value= 0,side= 1
	PopupMenu Wave_DA_AllVClamp,pos={153.00,545.00},size={125.00,19.00},bodyWidth=125,disable=1,proc=DAP_PopMenuChkProc_StimSetList
	PopupMenu Wave_DA_AllVClamp,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	PopupMenu Wave_DA_AllVClamp,userdata(ResizeControlsInfo)= A"!!,G)!!#Cm5QF.I!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Wave_DA_AllVClamp,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Wave_DA_AllVClamp,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Wave_DA_AllVClamp,fSize=10
	PopupMenu Wave_DA_AllVClamp,mode=1,popvalue="- none -",value= #"\"- none -;\"+ReturnListOfAllStimSets(0,\"*DA*\")"
	SetVariable Search_DA_AllVClamp,pos={154.00,569.00},size={124.00,18.00},disable=1,proc=DAP_SetVarProc_Channel_Search,title="Search string"
	SetVariable Search_DA_AllVClamp,userdata(tabnum)=  "1"
	SetVariable Search_DA_AllVClamp,userdata(tabcontrol)=  "ADC"
	SetVariable Search_DA_AllVClamp,userdata(ResizeControlsInfo)= A"!!,G*!!#Cs5QF.G!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Search_DA_AllVClamp,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Search_DA_AllVClamp,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Search_DA_AllVClamp,value= _STR:""
	SetVariable Scale_DA_AllVClamp,pos={288.00,545.00},size={50.00,18.00},bodyWidth=50,disable=1,proc=DAP_SetVarProc_DA_Scale
	SetVariable Scale_DA_AllVClamp,userdata(tabnum)=  "1"
	SetVariable Scale_DA_AllVClamp,userdata(tabcontrol)=  "ADC"
	SetVariable Scale_DA_AllVClamp,userdata(ResizeControlsInfo)= A"!!,HK!!#Cm5QF,A!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Scale_DA_AllVClamp,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Scale_DA_AllVClamp,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Scale_DA_AllVClamp,limits={-inf,inf,10},value= _NUM:1
	PopupMenu IndexEnd_DA_AllVClamp,pos={353.00,545.00},size={125.00,19.00},bodyWidth=125,disable=1,proc=DAP_PopMenuChkProc_StimSetList
	PopupMenu IndexEnd_DA_AllVClamp,userdata(tabnum)=  "1"
	PopupMenu IndexEnd_DA_AllVClamp,userdata(tabcontrol)=  "ADC"
	PopupMenu IndexEnd_DA_AllVClamp,userdata(ResizeControlsInfo)= A"!!,HkJ,htC5QF.I!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu IndexEnd_DA_AllVClamp,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu IndexEnd_DA_AllVClamp,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu IndexEnd_DA_AllVClamp,mode=1,popvalue="- none -",value= #"\"- none -;\"+ReturnListOfAllStimSets(0,\"*DA*\")"
	GroupBox group_DA_AllVClamp,pos={11.00,524.00},size={471.00,74.00},disable=1,title="V-Clamp"
	GroupBox group_DA_AllVClamp,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	GroupBox group_DA_AllVClamp,userdata(ResizeControlsInfo)= A"!!,A>!!#Ch!!#CPJ,hp#z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	GroupBox group_DA_AllVClamp,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	GroupBox group_DA_AllVClamp,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_DA_AllIClamp,pos={19.00,626.00},size={22.00,15.00},disable=3,proc=DAP_CheckProc_Channel_All,title="X"
	CheckBox Check_DA_AllIClamp,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	CheckBox Check_DA_AllIClamp,userdata(ResizeControlsInfo)= A"!!,BQ!!#D,J,hm>!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_DA_AllIClamp,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_DA_AllIClamp,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_DA_AllIClamp,value= 0,side= 1
	PopupMenu Wave_DA_AllIClamp,pos={153.00,628.00},size={125.00,19.00},bodyWidth=125,disable=3,proc=DAP_PopMenuChkProc_StimSetList
	PopupMenu Wave_DA_AllIClamp,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	PopupMenu Wave_DA_AllIClamp,userdata(ResizeControlsInfo)= A"!!,G)!!#D-!!#@^!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Wave_DA_AllIClamp,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Wave_DA_AllIClamp,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Wave_DA_AllIClamp,fSize=10
	PopupMenu Wave_DA_AllIClamp,mode=1,popvalue="- none -",value= #"\"- none -;\"+ReturnListOfAllStimSets(0,\"*DA*\")"
	SetVariable Search_DA_AllIClamp,pos={154.00,652.00},size={124.00,18.00},disable=3,proc=DAP_SetVarProc_Channel_Search,title="Search string"
	SetVariable Search_DA_AllIClamp,userdata(tabnum)=  "1"
	SetVariable Search_DA_AllIClamp,userdata(tabcontrol)=  "ADC"
	SetVariable Search_DA_AllIClamp,userdata(ResizeControlsInfo)= A"!!,G*!!#D3!!#@\\!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Search_DA_AllIClamp,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Search_DA_AllIClamp,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Search_DA_AllIClamp,value= _STR:""
	SetVariable Scale_DA_AllIClamp,pos={288.00,628.00},size={50.00,18.00},bodyWidth=50,disable=3,proc=DAP_SetVarProc_DA_Scale
	SetVariable Scale_DA_AllIClamp,userdata(tabnum)=  "1"
	SetVariable Scale_DA_AllIClamp,userdata(tabcontrol)=  "ADC"
	SetVariable Scale_DA_AllIClamp,userdata(ResizeControlsInfo)= A"!!,HK!!#D-!!#>V!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Scale_DA_AllIClamp,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Scale_DA_AllIClamp,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Scale_DA_AllIClamp,limits={-inf,inf,10},value= _NUM:1
	PopupMenu IndexEnd_DA_AllIClamp,pos={354.00,628.00},size={125.00,19.00},bodyWidth=125,disable=3,proc=DAP_PopMenuChkProc_StimSetList
	PopupMenu IndexEnd_DA_AllIClamp,userdata(tabnum)=  "1"
	PopupMenu IndexEnd_DA_AllIClamp,userdata(tabcontrol)=  "ADC"
	PopupMenu IndexEnd_DA_AllIClamp,userdata(ResizeControlsInfo)= A"!!,Hl!!#D-!!#@^!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu IndexEnd_DA_AllIClamp,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu IndexEnd_DA_AllIClamp,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu IndexEnd_DA_AllIClamp,mode=1,popvalue="- none -",value= #"\"- none -;\"+ReturnListOfAllStimSets(0,\"*DA*\")"
	GroupBox group_DA_AllIClamp,pos={12.00,607.00},size={471.00,74.00},disable=3,title="I-Clamp"
	GroupBox group_DA_AllIClamp,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	GroupBox group_DA_AllIClamp,userdata(ResizeControlsInfo)= A"!!,AN!!#D'^]6afJ,hp#z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	GroupBox group_DA_AllIClamp,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	GroupBox group_DA_AllIClamp,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Radio_ClampMode_AllVClamp,pos={400.00,62.00},size={13.00,13.00},disable=1,proc=DAP_CheckProc_ClampMode,title=""
	CheckBox Radio_ClampMode_AllVClamp,userdata(tabnum)=  "0"
	CheckBox Radio_ClampMode_AllVClamp,userdata(tabcontrol)=  "ADC"
	CheckBox Radio_ClampMode_AllVClamp,userdata(ResizeControlsInfo)= A"!!,I.!!#?1!!#;]!!#;]z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Radio_ClampMode_AllVClamp,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Radio_ClampMode_AllVClamp,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Radio_ClampMode_AllVClamp,value= 0,mode=1
	CheckBox Radio_ClampMode_AllIClamp,pos={400.00,111.00},size={13.00,13.00},disable=1,proc=DAP_CheckProc_ClampMode,title=""
	CheckBox Radio_ClampMode_AllIClamp,userdata(tabnum)=  "0"
	CheckBox Radio_ClampMode_AllIClamp,userdata(tabcontrol)=  "ADC"
	CheckBox Radio_ClampMode_AllIClamp,userdata(ResizeControlsInfo)= A"!!,I.!!#@B!!#;]!!#;]z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Radio_ClampMode_AllIClamp,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Radio_ClampMode_AllIClamp,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Radio_ClampMode_AllIClamp,value= 0,mode=1
	CheckBox Radio_ClampMode_AllIZero,pos={401.00,181.00},size={13.00,13.00},disable=1,proc=DAP_CheckProc_ClampMode,title=""
	CheckBox Radio_ClampMode_AllIZero,userdata(tabnum)=  "2"
	CheckBox Radio_ClampMode_AllIZero,userdata(tabcontrol)=  "tab_DataAcq_Amp"
	CheckBox Radio_ClampMode_AllIZero,userdata(ResizeControlsInfo)= A"!!,I6!!#AF!!#;]!!#;]z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Radio_ClampMode_AllIZero,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Radio_ClampMode_AllIZero,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Radio_ClampMode_AllIZero,value= 0,mode=1
	CheckBox Check_DataAcqHS_All,pos={400.00,85.00},size={29.00,15.00},disable=1,proc=DAP_CheckProc_HedstgeChck,title="All"
	CheckBox Check_DataAcqHS_All,userdata(tabnum)=  "0",userdata(tabcontrol)=  "ADC"
	CheckBox Check_DataAcqHS_All,userdata(ResizeControlsInfo)= A"!!,I.!!#?c!!#=K!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_DataAcqHS_All,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_DataAcqHS_All,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_DataAcqHS_All,value= 0
	CheckBox check_Settings_TP_SaveTP,pos={342.00,150.00},size={117.00,15.00},disable=1,title="Save each testpulse"
	CheckBox check_Settings_TP_SaveTP,help={"Store the complete scaled testpulse for each run (requires loads of RAM)"}
	CheckBox check_Settings_TP_SaveTP,userdata(tabnum)=  "5"
	CheckBox check_Settings_TP_SaveTP,userdata(tabcontrol)=  "ADC"
	CheckBox check_Settings_TP_SaveTP,userdata(ResizeControlsInfo)= A"!!,HmJ,hq?!!#?s!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_Settings_TP_SaveTP,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_Settings_TP_SaveTP,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox check_Settings_TP_SaveTP,value= 0
	Button Button_DataAcq_SkipForward,pos={343.00,590.00},size={50.00,20.00},disable=1,proc=DAP_ButtonProc_skipSweep,title="Skip\\Z12 >>"
	Button Button_DataAcq_SkipForward,userdata(tabnum)=  "0"
	Button Button_DataAcq_SkipForward,userdata(tabcontrol)=  "ADC",labelBack=(0,0,0)
	Button Button_DataAcq_SkipForward,fStyle=1,fColor=(4369,4369,4369,6554)
	Button Button_DataAcq_SkipForward,valueColor=(65535,65535,65535)
	Button Button_DataAcq_SkipBackwards,pos={105.00,590.00},size={50.00,20.00},disable=1,proc=DAP_ButtonProc_skipBack,title="<<Skip"
	Button Button_DataAcq_SkipBackwards,userdata(tabnum)=  "0"
	Button Button_DataAcq_SkipBackwards,userdata(tabcontrol)=  "ADC"
	Button Button_DataAcq_SkipBackwards,labelBack=(0,0,0),fStyle=1
	Button Button_DataAcq_SkipBackwards,fColor=(4369,4369,4369)
	Button Button_DataAcq_SkipBackwards,valueColor=(65535,65535,65535)
	DefineGuide UGV0={FR,-25},UGH0={FB,-27},UGV1={FL,481}
	SetWindow kwTopWin,hook(cleanup)=DAP_WindowHook
	SetWindow kwTopWin,userdata(ResizeControlsInfo)= A"!!*'\"z!!#CW!!#Dl5QCcbzzzzzzzzzzzzzzzzzzzz"
	SetWindow kwTopWin,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzzzzzzzzzzzzzzz"
	SetWindow kwTopWin,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzzzzzzzzz!!!"
	SetWindow kwTopWin,userdata(ResizeControlsGuides)=  "UGV0;UGH0;UGV1;"
	SetWindow kwTopWin,userdata(ResizeControlsInfoUGV0)= A":-hTC3`S[N0KW?-:-(sG6SUJQ0OI4ZG$cpb<*<$d3`U64E]Zff;Ft%f:/jMQ3\\WWl:K'ha8P`)B1c79G0JGRY<CoSI0fhd%4%E:B6q&jl4&SL@:et\"]<(Tk\\3\\<*E3r"
	SetWindow kwTopWin,userdata(ResizeControlsInfoUGH0)= A":-hTC3`S[@0KW?-:-(sG6SUJQ0OI4ZG$cpb<*<$d3`U64E]Zff;Ft%f:/jMQ3\\`]m:K'ha8P`)B3&NNF0JGRY<CoSI0fhcj4%E:B6q&jl4&SL@:et\"]<(Tk\\3\\<*G3r"
	SetWindow kwTopWin,userdata(ResizeControlsInfoUGV1)= A":-hTC3`S[N0frH.:-(sG6SUJQ0OI4ZG$cpb<*<$d3`U64E]Zff;Ft%f:/jMQ3\\WWl:K'ha8P`)B1cR3B0JGRY<CoSI0fhct4%E:B6q&jl4&SL@:et\"]<(Tk\\3]&fN3r"
EndMacro

/// @brief Restores the base state of the DA_Ephys panel.
/// Useful when adding controls to GUI. Facilitates use of auto generation of GUI code. 
/// Useful when template experiment file has been overwritten.
Function DAP_EphysPanelStartUpSettings()
	string panelTitle

	panelTitle = GetMainWindow(GetCurrentWindow())

	if(!windowExists(panelTitle))
		print "The top panel does not exist"
		ControlWindowToFront()
		return NaN
	endif

	DAP_UnlockDevice(panelTitle)

	panelTitle = GetMainWindow(GetCurrentWindow())

	if(cmpstr(panelTitle, BASE_WINDOW_TITLE))
		printf "The top window is not named \"%s\"\r", BASE_WINDOW_TITLE
		return NaN
	endif

	// remove tools
	HideTools/W=$panelTitle/A

	SetWindow $panelTitle, userData(panelVersion) = ""

	CheckBox Check_AD_00 WIN = $panelTitle,value= 0
	CheckBox Check_AD_01 WIN = $panelTitle,value= 0
	CheckBox Check_AD_02 WIN = $panelTitle,value= 0
	CheckBox Check_AD_03 WIN = $panelTitle,value= 0
	CheckBox Check_AD_04 WIN = $panelTitle,value= 0
	CheckBox Check_AD_05 WIN = $panelTitle,value= 0
	CheckBox Check_AD_06 WIN = $panelTitle,value= 0
	CheckBox Check_AD_07 WIN = $panelTitle,value= 0
	CheckBox Check_AD_08 WIN = $panelTitle,value= 0
	CheckBox Check_AD_09 WIN = $panelTitle,value= 0
	CheckBox Check_AD_10 WIN = $panelTitle,value= 0
	CheckBox Check_AD_11 WIN = $panelTitle,value= 0
	CheckBox Check_AD_12 WIN = $panelTitle,value= 0
	CheckBox Check_AD_13 WIN = $panelTitle,value= 0
	CheckBox Check_AD_14 WIN = $panelTitle,value= 0
	CheckBox Check_AD_15 WIN = $panelTitle,value= 0
	CheckBox Check_AD_All WIN = $panelTitle,value= 0

	CheckBox Check_DA_00 WIN = $panelTitle,value= 0
	CheckBox Check_DA_01 WIN = $panelTitle,value= 0
	CheckBox Check_DA_02 WIN = $panelTitle,value= 0
	CheckBox Check_DA_03 WIN = $panelTitle,value= 0
	CheckBox Check_DA_04 WIN = $panelTitle,value= 0
	CheckBox Check_DA_05 WIN = $panelTitle,value= 0
	CheckBox Check_DA_06 WIN = $panelTitle,value= 0
	CheckBox Check_DA_07 WIN = $panelTitle,value= 0
	CheckBox Check_DA_All WIN = $panelTitle,value= 0
	CheckBox Check_DA_AllVClamp WIN = $panelTitle,value= 0
	CheckBox Check_DA_AllIClamp WIN = $panelTitle,value= 0

	CheckBox Check_TTL_00 WIN = $panelTitle,value= 0
	CheckBox Check_TTL_01 WIN = $panelTitle,value= 0
	CheckBox Check_TTL_02 WIN = $panelTitle,value= 0
	CheckBox Check_TTL_03 WIN = $panelTitle,value= 0
	CheckBox Check_TTL_04 WIN = $panelTitle,value= 0
	CheckBox Check_TTL_05 WIN = $panelTitle,value= 0
	CheckBox Check_TTL_06 WIN = $panelTitle,value= 0
	CheckBox Check_TTL_07 WIN = $panelTitle,value= 0
	CheckBox Check_TTL_All WIN = $panelTitle,value= 0

	CheckBox Check_DataAcqHS_00 WIN = $panelTitle,value= 0
	CheckBox Check_DataAcqHS_01 WIN = $panelTitle,value= 0
	CheckBox Check_DataAcqHS_02 WIN = $panelTitle,value= 0
	CheckBox Check_DataAcqHS_03 WIN = $panelTitle,value= 0
	CheckBox Check_DataAcqHS_04 WIN = $panelTitle,value= 0
	CheckBox Check_DataAcqHS_05 WIN = $panelTitle,value= 0
	CheckBox Check_DataAcqHS_06 WIN = $panelTitle,value= 0
	CheckBox Check_DataAcqHS_07 WIN = $panelTitle,value= 0
	CheckBox Check_DataAcqHS_All WIN = $panelTitle,value= 0

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
	PopupMenu Wave_DA_All WIN = $panelTitle,mode=1, userdata(MenuExp) = ""
	PopupMenu Wave_DA_AllVClamp WIN = $panelTitle,mode=1, userdata(MenuExp) = ""
	PopupMenu Wave_DA_AllIClamp WIN = $panelTitle,mode=1, userdata(MenuExp) = ""

	SetVariable Scale_DA_00 WIN = $panelTitle, value = _NUM:1
	SetVariable Scale_DA_01 WIN = $panelTitle, value = _NUM:1
	SetVariable Scale_DA_02 WIN = $panelTitle, value = _NUM:1
	SetVariable Scale_DA_03 WIN = $panelTitle, value = _NUM:1
	SetVariable Scale_DA_04 WIN = $panelTitle, value = _NUM:1
	SetVariable Scale_DA_05 WIN = $panelTitle, value = _NUM:1
	SetVariable Scale_DA_06 WIN = $panelTitle, value = _NUM:1
	SetVariable Scale_DA_07 WIN = $panelTitle, value = _NUM:1
	SetVariable Scale_DA_All WIN = $panelTitle, value = _NUM:1
	SetVariable Scale_DA_AllVClamp WIN = $panelTitle, value = _NUM:1
	SetVariable Scale_DA_AllIClamp WIN = $panelTitle, value = _NUM:1

	SetVariable SetVar_DataAcq_Comment WIN = $panelTitle,fSize=8,value= _STR:""

	CheckBox Check_DataAcq1_RepeatAcq Win = $panelTitle, value = 1
	CheckBox Check_DataAcq1_DistribDaq Win = $panelTitle, value = 0
	CheckBox Check_DataAcq1_dDAQOptOv Win = $panelTitle, value = 0

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
	PopupMenu Wave_TTL_All Win = $panelTitle ,mode=1, userdata(MenuExp) = ""
	
	CheckBox Check_Settings_TrigOut Win = $panelTitle, value = 0
	CheckBox Check_Settings_TrigIn Win = $panelTitle, value = 0

	SetVariable SetVar_DataAcq_SetRepeats WIN = $panelTitle,value= _NUM:1

	CheckBox Check_Settings_UseDoublePrec WIN = $panelTitle, value= 0
	CheckBox Check_Settings_SkipAnalysFuncs WIN = $panelTitle, value= 1
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
	
	CheckBox Radio_ClampMode_AllVClamp WIN = $panelTitle, value= 0,mode=1
	CheckBox Radio_ClampMode_AllIClamp WIN = $panelTitle, value= 0,mode=1
	CheckBox Radio_ClampMode_AllIZero WIN = $panelTitle, value= 0,mode=1

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
	SetVariable Search_DA_All WIN = $panelTitle, value= _STR:""
	SetVariable Search_DA_AllVClamp WIN = $panelTitle, value= _STR:""
	SetVariable Search_DA_AllIClamp WIN = $panelTitle, value= _STR:""

	SetVariable Search_TTL_00 WIN = $panelTitle, value= _STR:""
	SetVariable Search_TTL_01 WIN = $panelTitle, value= _STR:""
	SetVariable Search_TTL_02 WIN = $panelTitle, value= _STR:""
	SetVariable Search_TTL_03 WIN = $panelTitle, value= _STR:""
	SetVariable Search_TTL_04 WIN = $panelTitle, value= _STR:""
	SetVariable Search_TTL_05 WIN = $panelTitle, value= _STR:""
	SetVariable Search_TTL_06 WIN = $panelTitle, value= _STR:""
	SetVariable Search_TTL_07 WIN = $panelTitle, value= _STR:""
	SetVariable Search_TTL_All WIN = $panelTitle, value= _STR:""

	PopupMenu IndexEnd_DA_00 WIN = $panelTitle, mode=1, userdata(MenuExp) = ""
	PopupMenu IndexEnd_DA_01 WIN = $panelTitle, mode=1, userdata(MenuExp) = ""
	PopupMenu IndexEnd_DA_02 WIN = $panelTitle, mode=1, userdata(MenuExp) = ""
	PopupMenu IndexEnd_DA_03 WIN = $panelTitle, mode=1, userdata(MenuExp) = ""
	PopupMenu IndexEnd_DA_04 WIN = $panelTitle, mode=1, userdata(MenuExp) = ""
	PopupMenu IndexEnd_DA_05 WIN = $panelTitle, mode=1, userdata(MenuExp) = ""
	PopupMenu IndexEnd_DA_06 WIN = $panelTitle, mode=1, userdata(MenuExp) = ""
	PopupMenu IndexEnd_DA_07 WIN = $panelTitle, mode=1, userdata(MenuExp) = ""
	PopupMenu IndexEnd_DA_All WIN = $panelTitle, mode=1, userdata(MenuExp) = ""
	PopupMenu IndexEnd_DA_AllVClamp WIN = $panelTitle, mode=1, userdata(MenuExp) = ""
	PopupMenu IndexEnd_DA_AllICLamp WIN = $panelTitle, mode=1, userdata(MenuExp) = ""

	PopupMenu IndexEnd_TTL_00 WIN = $panelTitle, mode=1, userdata(MenuExp) = ""
	PopupMenu IndexEnd_TTL_01 WIN = $panelTitle, mode=1, userdata(MenuExp) = ""
	PopupMenu IndexEnd_TTL_02 WIN = $panelTitle, mode=1, userdata(MenuExp) = ""
	PopupMenu IndexEnd_TTL_03 WIN = $panelTitle, mode=1, userdata(MenuExp) = ""
	PopupMenu IndexEnd_TTL_04 WIN = $panelTitle, mode=1, userdata(MenuExp) = ""
	PopupMenu IndexEnd_TTL_05 WIN = $panelTitle, mode=1, userdata(MenuExp) = ""
	PopupMenu IndexEnd_TTL_06 WIN = $panelTitle, mode=1, userdata(MenuExp) = ""
	PopupMenu IndexEnd_TTL_07 WIN = $panelTitle, mode=1, userdata(MenuExp) = ""
	PopupMenu IndexEnd_TTL_All WIN = $panelTitle, mode=1, userdata(MenuExp) = ""
	
	PopupMenu popup_Settings_Amplifier,mode=1,popvalue="- none -"
	// don't make the scope subwindow part of the recreation macro
	CheckBox check_Settings_ShowScopeWindow WIN = $panelTitle, value= 0
	SCOPE_KillScopeWindowIfRequest(panelTitle)
	CheckBox check_Settings_ShowScopeWindow WIN = $panelTitle, value= 1

	CheckBox check_Settings_ITITP WIN = $panelTitle, value= 1
	CheckBox check_Settings_TPAfterDAQ WIN = $panelTitle, value= 0

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

	PGC_SetAndActivateControl(panelTitle, "popup_MoreSettings_DeviceType", val=0)
	PGC_SetAndActivateControl(panelTitle, "popup_MoreSettings_DeviceNo", val=0)

	SetVariable SetVar_Sweep WIN = $panelTitle, limits={0,0,1}, value= _NUM:0

	SetVariable SetVar_DataAcq_dDAQDelay WIN = $panelTitle,value= _NUM:0
	SetVariable setvar_DataAcq_dDAQOptOvPost WIN = $panelTitle,value= _NUM:0
	SetVariable setvar_DataAcq_dDAQOptOvPre WIN = $panelTitle,value= _NUM:0
	SetVariable setvar_DataAcq_dDAQOptOvRes WIN = $panelTitle,value= _NUM:1
	SetVariable SetVar_DataAcq_OnsetDelayUser WIN = $panelTitle,value= _NUM:0
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

	PopupMenu popup_Hardware_AvailITC1600s WIN = $panelTitle,mode=0

	SetVariable SetVar_Hardware_Status WIN = $panelTitle,value= _STR:"Independent",noedit= 1
	SetVariable SetVar_Hardware_YokeList WIN = $panelTitle,value= _STR:"No Yoked Devices",noedit= 1
	PopupMenu popup_Hardware_YokedDACs WIN = $panelTitle, mode=0,value=DAP_GUIListOfYokedDevices()

	DisableControl(panelTitle, "popup_Settings_Manip_MSSMnipLst")
	SetCheckBoxState(panelTitle, "Check_Hardware_UseManip", 0)

	SetVariable SetVar_DataAcq_Hold_IC WIN = $panelTitle, value= _NUM:0
	SetVariable Setvar_DataAcq_PipetteOffset_VC WIN = $panelTitle, value= _NUM:0
	SetVariable Setvar_DataAcq_PipetteOffset_IC WIN = $panelTitle, value= _NUM:0
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
	CheckBox check_Settings_SyncMiesToMCC WIN = $panelTitle,value= 0
	CheckBox check_DataAcq_Amp_Chain WIN = $panelTitle,value= 0
	CheckBox check_DatAcq_BBEnable WIN = $panelTitle,value= 0
	CheckBox check_Settings_MD WIN = $panelTitle,value= 0

	DAP_SwitchSingleMultiMode(panelTitle, 0)
	SetControlUserData(panelTitle, "Check_Settings_BkgTP", "oldState", "")
	SetControlUserData(panelTitle, "Check_Settings_BackgrndDataAcq", "oldState", "")

	CheckBox Check_Settings_BkgTP WIN = $panelTitle,value= 1
	CheckBox Check_Settings_BackgrndDataAcq WIN = $panelTitle, value= 1

	CheckBox Check_Settings_InsertTP WIN = $panelTitle,value= 1
	CheckBox Check_DataAcq_Get_Set_ITI WIN = $panelTitle, value = 1
	CheckBox check_Settings_TP_SaveTPRecord WIN = $panelTitle, value = 0
	CheckBox check_Settings_TP_SaveTP WIN = $panelTitle, value = 0
	CheckBox check_settings_TP_show_steady WIN = $panelTitle, value = 1
	CheckBox check_settings_TP_show_peak WIN = $panelTitle, value = 1
	CheckBox check_settings_show_power WIN = $panelTitle, value = 0
	CheckBox check_Settings_DisablePressure WIN = $panelTitle, value = 0
	CheckBox check_Settings_RequireAmpConn WIN = $panelTitle, value = 1

	// defaults are also hardcoded in P_GetPressureDataWaveRef
	// and P_PressureDataTxtWaveRef
	SetPopupMenuVal(panelTitle, "popup_Settings_Pressure_dev", NONE)
	SetPopupMenuIndex(panelTitle, "popup_Settings_Pressure_dev", 0)
	SetPopupMenuIndex(panelTitle, "Popup_Settings_Pressure_DA", 0)
	SetPopupMenuIndex(panelTitle, "Popup_Settings_Pressure_AD", 0)
	SetPopupMenuIndex(panelTitle, "Popup_Settings_Pressure_TTLA", 1)
	SetPopupMenuIndex(panelTitle, "Popup_Settings_Pressure_TTLB", 0)
	SetSetVariable(panelTitle, "setvar_Settings_Pressure_DAgain", 2)
	SetSetVariable(panelTitle, "setvar_Settings_Pressure_ADgain", 0.5)
	SetSetVariableString(panelTitle, "SetVar_Hardware_Pressur_DA_Unit", "psi")
	SetSetVariableString(panelTitle, "SetVar_Hardware_Pressur_AD_Unit", "psi")
	SetVariable setvar_Settings_InAirP         , win=$panelTitle, value= _NUM:3.8
	SetVariable setvar_Settings_InBathP        , win=$panelTitle, value= _NUM:0.55
	SetVariable setvar_Settings_InSliceP       , win=$panelTitle, value= _NUM:0.2
	SetVariable setvar_Settings_NearCellP      , win=$panelTitle, value= _NUM:0.6
	SetVariable setvar_Settings_SealStartP     , win=$panelTitle, value= _NUM:-0.2
	SetVariable setvar_Settings_SealMaxP       , win=$panelTitle, value= _NUM:-1.4
	SetVariable setvar_Settings_SurfaceHeight  , win=$panelTitle, value= _NUM:3500
	SetVariable setvar_Settings_SliceSurfHeight, win=$panelTitle, value= _NUM:350
	CheckBox check_Settings_DisablePressure    , win=$panelTitle, value= 0
 
   ValDisplay valdisp_DataAcq_P_LED_0 WIN = $panelTitle, value= _NUM:-1
   ValDisplay valdisp_DataAcq_P_LED_1 WIN = $panelTitle, value= _NUM:-1
   ValDisplay valdisp_DataAcq_P_LED_2 WIN = $panelTitle, value= _NUM:-1
   ValDisplay valdisp_DataAcq_P_LED_3 WIN = $panelTitle, value= _NUM:-1
   ValDisplay valdisp_DataAcq_P_LED_4 WIN = $panelTitle, value= _NUM:-1
   ValDisplay valdisp_DataAcq_P_LED_5 WIN = $panelTitle, value= _NUM:-1
   ValDisplay valdisp_DataAcq_P_LED_6 WIN = $panelTitle, value= _NUM:-1
   ValDisplay valdisp_DataAcq_P_LED_7 WIN = $panelTitle, value= _NUM:-1
   
  	ValDisplay valdisp_DataAcq_P_LED_Approach WIN = $panelTitle, value= _NUM:0
	ValDisplay valdisp_DataAcq_P_LED_Seal WIN = $panelTitle, value= _NUM:0
	ValDisplay valdisp_DataAcq_P_LED_Breakin WIN = $panelTitle, value= _NUM:0
	ValDisplay valdisp_DataAcq_P_LED_Clear WIN = $panelTitle, value= _NUM:0
	
	CheckBox check_Settings_UserP_Approach WIN = $panelTitle, value=0
	CheckBox check_Settings_UserP_BreakIn WIN = $panelTitle, value=0
	CheckBox check_Settings_UserP_Seal WIN = $panelTitle, value=0
	CheckBox check_Settings_UserP_Clear WIN = $panelTitle, value=0
	CheckBox check_DataACq_Pressure_AutoOFF WIN = $panelTitle, value=0
	CheckBox check_DataACq_Pressure_User WIN = $panelTitle, value=0
	
	EnableControl(panelTitle, "button_Hardware_P_Enable")
	DisableControl(panelTitle, "button_Hardware_P_Disable")
	EnableControls(panelTitle, "Button_DataAcq_SkipBackwards;Button_DataAcq_SkipForward")

	SearchForInvalidControlProcs(panelTitle)

	Execute/P/Z "DoWindow/R " + BASE_WINDOW_TITLE
	Execute/P/Q/Z "COMPILEPROCEDURES "
End

Function DAP_WindowHook(s)
	STRUCT WMWinHookStruct &s

	string panelTitle

	switch(s.eventCode)
		case EVENT_KILL_WINDOW_HOOK:
			panelTitle = s.winName
			DAP_UnlockDevice(panelTitle)

			return 1
		break
	endswitch

	return 0
End

/// @brief Return a popValue string suitable for stimsets
/// @todo rework the code to have a fixed popValue
static Function/S DAP_FormatStimSetPopupValue(channelType, searchString)
	variable channelType
	string searchString

	string str
	sprintf str, "\"%s;\"+%s%s%s", NONE, "ReturnListOfAllStimSets(" + num2str(channelType) + ",\"", searchString,"\")"

	return str
End

/// @brief Check by querying the GUI if the device is a leader
///
/// Outside callers should use DeviceHasFollower() instead.
static Function DAP_DeviceIsLeader(panelTitle)
	string panelTitle

	ControlInfo/W=$panelTitle setvar_Hardware_Status
	ASSERT(V_flag != 0, "Non-existing control or window")

	return cmpstr(S_value,LEADER) == 0
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

		DisableControls(panelTitle,YOKE_LIST_OF_CONTROLS)
		DAP_UpdateYokeControls(panelTitle)

		if(ListOfLockedITC1600Num >= 2 && DeviceCanLead(panelTitle))
			// ensures yoking controls are only enabled on the ITC1600_Dev_0
			// a requirement of the ITC XOP
			EnableControl(panelTitle,"button_Hardware_Lead1600")
		endif
	endfor

	string   ListOfUnlockedITC     = GetListOfUnlockedDevices()
	variable ListOfUnlockedITCNum  = ItemsInList(ListOfUnlockedITC)

	for(i=0; i<ListOfUnLockedITCNum; i+=1)
		panelTitle = StringFromList(i,ListOfUnLockedITC)
		DisableControls(panelTitle,YOKE_LIST_OF_CONTROLS)
	endfor
End

Function/S DAP_GUIListOfYokedDevices()

	SVAR listOfFollowerDevices = $GetFollowerList(ITC1600_FIRST_DEVICE)
	if(cmpstr(listOfFollowerDevices, "") != 0)
		return listOfFollowerDevices
	endif

	return "No Yoked Devices"
End

Function DAP_UpdateYokeControls(panelTitle)
	string panelTitle

	if(GetTabID(panelTitle, "ADC") != HARDWARE_TAB_NUM)
		return NaN
	endif

	if(!DeviceCanFollow(panelTitle))
		HideControls(panelTitle,YOKE_LIST_OF_CONTROLS)
		SetVariable setvar_Hardware_YokeList win = $panelTitle, value = _STR:"Device is not yokeable"
	elseif(DeviceIsFollower(panelTitle))
		HideControls(panelTitle,YOKE_LIST_OF_CONTROLS)
	else
		ShowControls(panelTitle,YOKE_LIST_OF_CONTROLS)
		if(DeviceCanLead(panelTitle))
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

	if(DAP_DeviceIsUnLocked(tca.win))
		print "Please lock the panel to a DAC in the Hardware tab"
		ControlWindowToFront()
		return 0
	endif

	DAP_UpdateYokeControls(tca.win)

	if(tca.tab == DATA_ACQU_TAB_NUM)
		DAP_UpdateDAQControls(tca.win, REASON_STIMSET_CHANGE | REASON_HEADSTAGE_CHANGE)
	endif

	return 0
End

Function DAP_SetVarProc_Channel_Search(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	variable channelIndex, channelType, channelControl
	variable i, isCustomSearchString, first, last
	string ctrl, searchString
	string popupValue, listOfWaves
	string panelTitle, varstr

	switch(sva.eventCode)
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			panelTitle = sva.win
			ctrl       = sva.ctrlName
			varstr     = sva.sval

			DAP_ParsePanelControl(ctrl, channelIndex, channelType, channelControl)

			DFREF saveDFR = GetDataFolderDFR()
			SetDataFolder GetSetFolder(channelType)

			if(isEmpty(varstr))
				searchString = GetSearchStringForChannelType(channelType)
			else
				isCustomSearchString = 1
				searchString = varStr
			endif

			popupValue = DAP_FormatStimSetPopupValue(channelType, searchString)
			listOfWaves = WaveList(searchString, ";", "")
			SetDataFolder saveDFR

			if(DAP_IsAllControl(channelIndex))
				first = 0
				last  = GetNumberFromType(var=channelType)
			else
				first = channelIndex
				last  = channelIndex
			endif

			for(i = first; i < last; i+= 1)

				if(!DAP_DACHasExpectedClampMode(panelTitle, channelIndex, i, channelType))
					continue
				endif

				ctrl = GetPanelControl(i, channelType, CHANNEL_CONTROL_WAVE)
				PopupMenu $ctrl win=$panelTitle, value=#popupValue, userdata(MenuExp)=listOfWaves

				ctrl = GetPanelControl(i, channelType, CHANNEL_CONTROL_INDEX_END)
				PopupMenu $ctrl win=$panelTitle, value=#popupValue

				ctrl = GetPanelControl(i, channelType, CHANNEL_CONTROL_SEARCH)
				SetSetVariableString(panelTitle, ctrl, SelectString(isCustomSearchString, "", searchString))
			endfor
			break
	endswitch

	return 0
End

Function DAP_DAorTTLCheckProc(cba) : CheckBoxControl
	struct WMCheckboxAction &cba

	string panelTitle, control

	switch(cba.eventCode)
		case 2:
			try
				paneltitle = cba.win
				control    = cba.ctrlName
				DAP_AdaptAssocHeadstageState(panelTitle, control)
			catch
				SetCheckBoxState(panelTitle, control, !cba.checked)
				Abort
			endtry

			DAP_UpdateControlInGuiStateWv(cba.win, cba.ctrlName, cba.checked)
			break
	endswitch
End

Function DAP_CheckProc_Channel_All(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	string panelTitle, control
	variable i, checked, allChecked, channelIndex, channelType, controlType, numEntries

	switch(cba.eventCode)
		case 2: // mouse up
			paneltitle = cba.win
			allChecked = cba.checked
			DAP_ParsePanelControl(cba.ctrlName, channelIndex, channelType, controlType)
			ASSERT(controlType  == CHANNEL_CONTROL_CHECK, "Invalid control type")
			ASSERT(DAP_ISAllControl(channelIndex), "Invalid channel index")

			numEntries = GetNumberFromType(var=channelType)

			for(i = 0; i < numEntries; i += 1)
				control = GetPanelControl(i, channelType, CHANNEL_CONTROL_CHECK)
				checked = GetCheckBoxState(panelTitle, control)

				if(checked == allChecked)
					continue
				endif

				if(!DAP_DACHasExpectedClampMode(panelTitle, channelIndex, i, channelType))
					continue
				endif

				PGC_SetAndActivateControl(panelTitle, control, val=allChecked)
			endfor
			break
	endswitch

	return 0
End

/// @brief Determines if the control refers to an "All" control
Function DAP_IsAllControl(channelIndex)
	variable channelIndex

	return channelIndex == CHANNEL_INDEX_ALL \
	       || channelIndex == CHANNEL_INDEX_ALL_V_CLAMP \
	       || channelIndex == CHANNEL_INDEX_ALL_I_CLAMP
End

/// @brief Helper for "All" controls in the DA tab
///
/// @returns 0 if the given channel is a DA channel and not in the expected
///          clamp mode as determined by `controlChannelIndex`, 1 otherwise
Function DAP_DACHasExpectedClampMode(panelTitle, controlChannelIndex, channelNumber, channelType)
	string panelTitle
	variable controlChannelIndex, channelNumber, channelType

	variable headstage, clampMode

	ASSERT(DAP_IsAllControl(controlChannelIndex), "Invalid controlChannelIndex")

	if(channelType != CHANNEL_TYPE_DAC || controlChannelIndex == CHANNEL_INDEX_ALL)
		return 1 // don't care
	endif

	headstage = AFH_GetHeadstageFromDAC(panelTitle, channelNumber)

	if(!IsFinite(headstage)) // unassociated AD/DA channels
		return 0
	endif

	clampMode = DAP_MIESHeadstageMode(panelTitle, headStage)

	if(clampMode == V_CLAMP_MODE && controlChannelIndex == CHANNEL_INDEX_ALL_V_CLAMP)
		return 1
	endif

	if(clampMode == I_CLAMP_MODE && controlChannelIndex == CHANNEL_INDEX_ALL_I_CLAMP)
		return 1
	endif

	return 0
end

Function DAP_CheckProc_AD(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	string panelTitle, control

	switch(cba.eventCode)
		case 2: // mouse up
			try
				paneltitle = cba.win
				control    = cba.ctrlName
				DAP_AdaptAssocHeadstageState(panelTitle, control)
			catch
				SetCheckBoxState(panelTitle, control, !cba.checked)
				Abort
			endtry

			DAP_UpdateControlInGuiStateWv(cba.win, cba.ctrlName, cba.checked)

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

	DAP_AbortIfUnlocked(panelTitle)

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

	if(GetCheckBoxState(panelTitle, checkboxCtrl) == GetCheckBoxState(panelTitle, headStageCheckBox))
		// nothing to do
		return NaN
	endif

	PGC_SetAndActivateControl(panelTitle, headStageCheckBox, val=!GetCheckBoxState(panelTitle, headStageCheckBox))
End

/// @brief Return the repeated acquisition cycle ID for the given devide.
///
/// Follower and leader will have the same repeated acquisition cycle ID.
static Function DAP_GetRAAcquisitionCycleID(panelTitle)
	string panelTitle

	DAP_AbortIfUnlocked(panelTitle)

	if(DeviceIsFollower(panelTitle))
		NVAR raCycleIDLead = $GetRepeatedAcquisitionCycleID(ITC1600_FIRST_DEVICE)
		return raCycleIDLead
	else
		NVAR rngSeed = $GetRNGSeed(panelTitle)
		ASSERT(IsFinite(rngSeed), "Invalid rngSeed")
		SetRandomSeed/BETR=1 rngSeed
		rngSeed += 1
		// scale to the available mantissa bits in a single precision variable
		return trunc(GetReproducibleRandom() * 2^23)
	endif
End

/// @brief One time initialization before data acquisition
///
/// @param panelTitle device
/// @param runMode    One of @ref DAQRunModes except DAQ_NOT_RUNNING
Function DAP_OneTimeCallBeforeDAQ(panelTitle, runMode)
	string panelTitle
	variable runMode

	variable numHS, i

	ASSERT(runMode != DAQ_NOT_RUNNING, "Invalid running mode")

	NVAR count = $GetCount(panelTitle)
	count = 0

	NVAR raCycleID = $GetRepeatedAcquisitionCycleID(panelTitle)
	raCycleID = DAP_GetRAAcquisitionCycleID(panelTitle)

	if(GetCheckBoxState(panelTitle, "Check_DataAcq_Indexing"))
		IDX_StoreStartFinishForIndexing(panelTitle)
	endif

	SWS_DeleteDataWaves(panelTitle)

	// disable the clamp mode checkboxes of all active headstages
	WAVE statusHS = DAP_ControlStatusWaveCache(panelTitle, CHANNEL_TYPE_HEADSTAGE)

	numHS = DimSize(statusHS, ROWS)
	for(i = 0; i < numHS; i += 1)
		if(!statusHS[i])
			continue
		endif

		DisableControl(panelTitle, GetPanelControl(i, CHANNEL_TYPE_HEADSTAGE, CHANNEL_CONTROL_CHECK))
		DisableControl(panelTitle, DAP_GetClampModeControl(I_CLAMP_MODE, i))
		DisableControl(panelTitle, DAP_GetClampModeControl(V_CLAMP_MODE, i))
		DisableControl(panelTitle, DAP_GetClampModeControl(I_EQUAL_ZERO_MODE, i))
	endfor

	DisableControls(panelTitle, CONTROLS_DISABLE_DURING_DAQ)
		
	NVAR dataAcqRunMode = $GetDataAcqRunMode(panelTitle)
	dataAcqRunMode = runMode

	DAP_ToggleAcquisitionButton(panelTitle, DATA_ACQ_BUTTON_TO_STOP)
	DisableControls(panelTitle, CONTROLS_DISABLE_DURING_DAQ_TP)

	// turn off active pressure control modes
	if(GetCheckboxState(panelTitle, "check_Settings_DisablePressure"))
		P_SetAllHStoAtmospheric(panelTitle)
	endif

	RA_StepSweepsRemaining(panelTitle)
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

	EnableControls(panelTitle, CONTROLS_DISABLE_DURING_DAQ)

	DAP_ToggleAcquisitionButton(panelTitle, DATA_ACQ_BUTTON_TO_DAQ)
	EnableControls(panelTitle, CONTROLS_DISABLE_DURING_DAQ_TP)
End

/// @brief One time cleaning up after data acquisition
///
/// @param panelTitle device
/// @param forcedStop [optional, defaults to false] if DAQ was aborted (true) or stopped by itself (false)
Function DAP_OneTimeCallAfterDAQ(panelTitle, [forcedStop])
	string panelTitle
	variable forcedStop

	forcedStop = ParamIsDefault(forcedStop) ? 0 : !!forcedStop

	DAP_ResetGUIAfterDAQ(panelTitle)

	if(!forcedStop)
		AFM_CallAnalysisFunctions(panelTitle, POST_SET_EVENT)
		AFM_CallAnalysisFunctions(panelTitle, POST_DAQ_EVENT)
	endif

	NVAR dataAcqRunMode = $GetDataAcqRunMode(panelTitle)
	dataAcqRunMode = DAQ_NOT_RUNNING

	NVAR count = $GetCount(panelTitle)
	count = 0

	NVAR raCycleID = $GetRepeatedAcquisitionCycleID(panelTitle)
	raCycleID = NaN // invalidate

	// restore the selected sets before DAQ
	if(GetCheckBoxState(panelTitle, "Check_DataAcq_Indexing"))
		IDX_ResetStartFinishForIndexing(panelTitle)
	endif

	DAP_UpdateSweepSetVariables(panelTitle)

	if(!GetCheckBoxState(panelTitle, "check_Settings_TPAfterDAQ"))
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
		case 2: // mouse up
			panelTitle = ba.win

			DAP_AbortIfUnlocked(panelTitle)

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
		case 2: // mouse up

			DAP_UpdateDAQControls(panelTitle, REASON_STIMSET_CHANGE)

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

static Function DAP_TurnOffAllChannels(panelTitle, channelType)
	string panelTitle
	variable channelType

	variable i, numEntries
	string ctrl

	numEntries = GetNumberFromType(var=channelType)
	for(i = 0; i < numEntries; i += 1)
		ctrl = GetPanelControl(i, channelType, CHANNEL_CONTROL_CHECK)
		PGC_SetAndActivateControl(panelTitle, ctrl, val=CHECKBOX_UNSELECTED)
	endfor

	// we just called the control procedure for each channel, so we just have to set
	// the checkbox to unselected here
	if(channelType == CHANNEL_TYPE_ADC || channelType == CHANNEL_TYPE_DAC || channelType == CHANNEL_TYPE_TTL)
		ctrl = GetPanelControl(CHANNEL_INDEX_ALL, channelType, CHANNEL_CONTROL_CHECK)
		SetCheckBoxState(panelTitle, ctrl, CHECKBOX_UNSELECTED)
	endif
End

Function DAP_ButtonProc_AllChanOff(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	string panelTitle

	switch(ba.eventcode)
		case 2: // mouse up
			panelTitle = ba.win
			DAP_TurnOffAllChannels(panelTitle, CHANNEL_TYPE_HEADSTAGE)
			DAP_TurnOffAllChannels(panelTitle, CHANNEL_TYPE_ADC)
			DAP_TurnOffAllChannels(panelTitle, CHANNEL_TYPE_DAC)
			DAP_TurnOffAllChannels(panelTitle, CHANNEL_TYPE_TTL)
			break
	endswitch
End

Function DAP_UpdateITIAcrossSets(panelTitle)
	string panelTitle

	variable numActiveDAChannels, maxITI

	if(DeviceIsFollower(panelTitle) && DAP_DeviceIsLeader(ITC1600_FIRST_DEVICE))
		DAP_UpdateITIAcrossSets(ITC1600_FIRST_DEVICE)
		return 0
	endif

	maxITI = IDX_LongestITI(panelTitle, numActiveDAChannels)
	DEBUGPRINT("Maximum ITI across sets=", var=maxITI)

	if(GetCheckBoxState(panelTitle, "Check_DataAcq_Get_Set_ITI"))
		SetSetVariable(panelTitle, "SetVar_DataAcq_ITI", maxITI)
	elseif(maxITI == 0 && numActiveDAChannels > 0)
		ControlInfo/W=$panelTitle Check_DataAcq_Get_Set_ITI
		if(V_flag != 0)
			SetCheckBoxState(panelTitle, "Check_DataAcq_Get_Set_ITI", CHECKBOX_UNSELECTED)
		endif
	endif

	if(DAP_DeviceIsLeader(panelTitle))
		DAP_SyncGuiFromLeaderToFollower(panelTitle)
	endif
End

/// @brief Procedure for DA/TTL popupmenus including indexing wave popupmenus
Function DAP_PopMenuChkProc_StimSetList(pa) : PopupMenuControl
	STRUCT WMPopupAction& pa

	string ctrl, list
	string panelTitle, stimSet, checkCtrl
	variable channelIndex, channelType, channelControl, isAllControl, indexing
	variable i, numEntries, idx, dataAcqRunMode, headstage, activeChannel

	switch(pa.eventCode)
		case 2:
			panelTitle = pa.win
			ctrl       = pa.ctrlName
			stimSet    = pa.popStr
			idx        = pa.popNum

			DAP_AbortIfUnlocked(panelTitle)
			DAP_ParsePanelControl(ctrl, channelIndex, channelType, channelControl)

			checkCtrl     = GetPanelControl(channelIndex, channelType, CHANNEL_CONTROL_CHECK)
			indexing      = GetCheckBoxState(panelTitle, "Check_DataAcq_Indexing")
			isAllControl  = DAP_IsAllControl(channelIndex)
			activeChannel = isAllControl                                       \
			                || (GetCheckBoxState(panelTitle, checkCtrl)        \
			                   && (channelControl == CHANNEL_CONTROL_WAVE      \
			                   || (channelControl == CHANNEL_CONTROL_INDEX_END \
			                   && indexing)))

			if(activeChannel)
				dataAcqRunMode = ITC_StopDAQ(panelTitle)

				// stopping DAQ will reset the stimset popupmenu to its initial value
				// so we have to set the now old value again
				if(indexing && channelControl == CHANNEL_CONTROL_WAVE)
					SetPopupMenuIndex(panelTitle, ctrl, idx - 1)
				endif
			endif

			// check if this is a third party stim set which
			// is not yet reflected in the "MenuExp" user data
			list = GetUserData(panelTitle, ctrl, "MenuExp")
			if(FindListItem(stimSet, list) == -1)
				WBP_UpdateITCPanelPopUps()
			endif

			if(isAllControl)
				numEntries = GetNumberFromType(var=channelType)
				for(i = 0; i < numEntries; i += 1)
					ctrl = GetPanelControl(i, channelType, channelControl)

					if(!DAP_DACHasExpectedClampMode(panelTitle, channelIndex, i, channelType))
						continue
					endif

					SetPopupMenuIndex(panelTitle, ctrl, idx - 1)
				endfor
			endif

			DAP_UpdateDAQControls(panelTitle, REASON_STIMSET_CHANGE)

			if(activeChannel)
				ITC_RestartDAQ(panelTitle, dataAcqRunMode)
			endif

			break
		endswitch
	return 0
End

Function DAP_SetVarProc_DA_Scale(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	variable val, channelIndex, channelType, controlType, numEntries, i
	string panelTitle, ctrl

	switch(sva.eventCode)
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			val        = sva.dval
			ctrl       = sva.ctrlName
			panelTitle = sva.win

			DAP_ParsePanelControl(ctrl, channelIndex, channelType, controlType)
			ASSERT(DAP_IsAllControl(channelIndex), "Unexpected channel index")

			numEntries = GetNumberFromType(var=channelType)

			for(i = 0; i < numEntries; i+= 1)
				ctrl = GetPanelControl(i, channelType, controlType)

				if(!DAP_DACHasExpectedClampMode(panelTitle, channelIndex, i, channelType))
					continue
				endif

				SetSetVariable(panelTitle, ctrl, val)
			endfor
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

	panelList = GetListofLeaderAndPossFollower(panelTitle)

	if(DAP_DeviceIsLeader(panelTitle))
		sweep = GetSetVariable(panelTitle, "SetVar_Sweep")
	else
		sweep = NaN
	endif

	// query maximum next sweep
	maxNextSweep = 0
	numPanels = ItemsInList(panelList)
	for(i = 0; i < numPanels; i += 1)
		panelTitle = StringFromList(i, panelList)

		if(IsFinite(sweep) && DeviceIsFollower(panelTitle))
			SetSetVariable(panelTitle, "SetVar_Sweep", sweep)
		endif

		nextSweep = AFH_GetLastSweepAcquired(panelTitle) + 1
		if(IsFinite(nextSweep))
			maxNextSweep = max(maxNextSweep, nextSweep)
		endif
	endfor

	for(i = 0; i < numPanels; i += 1)
		panelTitle = StringFromList(i, panelList)

		if(DeviceIsFollower(panelTitle))
			SetVariable SetVar_Sweep win = $panelTitle, noEdit=1, limits = {0, maxNextSweep, 0}
		else
			SetVariable SetVar_Sweep win = $panelTitle, noEdit=0, limits = {0, maxNextSweep, 1}
		endif
	endfor
End

/// @brief Return the ITC sampling interval with taking the mode and
/// the multiplier into account
///
/// @see SI_CalculateMinSampInterval()
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

	SetValDisplay(panelTitle, "valdisp_DataAcq_TrialsCountdown", var=numSetRepeats)
	SetValDisplay(panelTitle, "valdisp_DataAcq_SweepsInSet", var=numSetRepeats)
	SetValDisplay(panelTitle, "valdisp_DataAcq_SweepsActiveSet", var=IDX_MaxNoOfSweeps(panelTitle, 1))
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

Function DAP_PopMenuProc_DevTypeChk(pa) : PopupMenuControl
	struct WMPopupAction& pa

	switch(pa.eventCode)
		case 2: // mouse up
			DAP_IsDeviceTypeConnected(pa.win)
			DAP_UpdateYokeControls(pa.win)
			break
	endswitch
End

Function DAP_ButtonCtrlFindConnectedAmps(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch(ba.eventcode)
		case 2: // mouse up
			AI_FindConnectedAmps()
			break
	endswitch
End

Function DAP_CheckProc_GetSet_ITI(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	switch(cba.eventCode)
		case 2: // mouse up
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

	WAVE telegraphServers = GetAmplifierTelegraphServers()

	numRows = DimSize(telegraphServers, ROWS)
	if(!numRows)
		print "Activate Multiclamp Commander software to populate list of available amplifiers"
		ControlWindowToFront()
		list = AddListItem("\\M1(MC not available", list, ";", inf)
		return list
	endif

	for(i=0; i < numRows; i+=1)
		str  = DAP_GetAmplifierDef(telegraphServers[i][0], telegraphServers[i][1])
		list = AddListItem(str, list, ";", inf)
	endfor

	return list
End

Function/S DAP_GetAmplifierDef(ampSerial, ampChannel)
	variable ampSerial, ampChannel

	string str

	sprintf str, AMPLIFIER_DEF_FORMAT, ampSerial, ampChannel

	return str
End

/// @brief Parse the entries which DAP_GetAmplifierDef() created
Function DAP_ParseAmplifierDef(amplifierDef, ampSerial, ampChannelID)
	string amplifierDef
	variable &ampSerial, &ampChannelID

	ampSerial    = NaN
	ampChannelID = NaN

	if(!cmpstr(amplifierDef, NONE))
		return NaN
	endif

	sscanf amplifierDef, AMPLIFIER_DEF_FORMAT, ampSerial, ampChannelID
	ASSERT(V_Flag == 2, "Unexpected amplifier popup list format")
End

Function DAP_SyncDeviceAssocSettToGUI(panelTitle, headStage)
	string panelTitle
	variable headStage

	DAP_AbortIfUnlocked(panelTitle)

	DAP_UpdateChanAmpAssignPanel(panelTitle)
	P_UpdatePressureControls(panelTitle, headStage)
End

Function DAP_PopMenuProc_Headstage(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	string panelTitle
	variable headStage

	switch(pa.eventCode)
		case 2: // mouse up
			panelTitle = pa.win
			headStage  = str2num(pa.popStr)

			DAP_SyncDeviceAssocSettToGUI(panelTitle, headStage)
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
			DAP_AbortIfUnlocked(panelTitle)

			DAP_UpdateChanAmpAssignStorWv(panelTitle)
			P_UpdatePressureDataStorageWv(panelTitle)
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
			DAP_AbortIfUnlocked(panelTitle)

			DAP_UpdateChanAmpAssignStorWv(panelTitle)
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
			DAP_AbortIfUnlocked(panelTitle)

			WAVE ChanAmpAssign = GetChanAmpAssign(panelTitle)

			headStage = str2num(GetPopupMenuString(panelTitle,"Popup_Settings_HeadStage"))

			// set all DA/AD channels for both clamp modes to an invalid channel number
			ChanAmpAssign[0, 6;2][headStage] = NaN
			ChanAmpAssign[8, 9][headStage]   = NaN

			DAP_UpdateChanAmpAssignPanel(panelTitle)
			break
	endswitch

	return 0
End

/// @brief Check the settings across yoked devices
static Function DAP_CheckSettingsAcrossYoked(listOfFollowerDevices, mode)
	string listOfFollowerDevices
	variable mode

	string panelTitle, leaderSampInt
	variable i, j, numEntries, numCtrls

	if(!WindowExists("ArduinoSeq_Panel"))
		printf "(%s) The Arduino sequencer panel does not exist. Please open it and load the default sequence.\r", ITC1600_FIRST_DEVICE
		ControlWindowToFront()
		return 1
	endif

	if(IsControlDisabled("ArduinoSeq_Panel", "ArduinoStartButton"))
		printf "(%s) The Arduino sequencer panel has a disabled \"Start\" button. Is it connected? Have you loaded the default sequence?\r", ITC1600_FIRST_DEVICE
		ControlWindowToFront()
		return 1
	endif

	if(mode == TEST_PULSE_MODE)
		return 0
	endif

	leaderSampInt = GetValDisplayAsString(ITC1600_FIRST_DEVICE, "ValDisp_DataAcq_SamplingInt")

	Make/T/FREE desc = {"Repeated Acquisition", "Distributed Acquisition", "Distributed DAQ delay",            \
						"Indexing", "ITI", "Number of repetitions", "Get ITI from stimset",                    \
						"Optimized overlap dDAQ pre feature time", "Optimized overlap dDAQ post feature time", \
						"Optimized overlap dDAQ", "Optimized overlap dDAQ resolution"}

	numCtrls = DimSize(desc, ROWS)
	ASSERT(ItemsInList(YOKE_CONTROLS_DISABLE_AND_LINK) == numCtrls, "Mismatched yoke linking lists")

	Make/FREE/T/N=(numCtrls) leadEntries = GetGuiControlValue(ITC1600_FIRST_DEVICE, StringFromList(p, YOKE_CONTROLS_DISABLE_AND_LINK))

	numEntries = ItemsInList(listOfFollowerDevices)
	for(i = 0; i < numEntries; i += 1)
		panelTitle = StringFromList(i, listOfFollowerDevices)

		if(cmpstr(leaderSampInt, GetValDisplayAsString(panelTitle, "ValDisp_DataAcq_SamplingInt")))
			// this is no fatal error, we just inform the user
			printf "(%s) Sampling interval does not match leader panel\r", panelTitle
			ValDisplay ValDisp_DataAcq_SamplingInt win=$panelTitle, valueBackColor=(0,65280,33024)
			ControlWindowToFront()
		else
			ValDisplay ValDisp_DataAcq_SamplingInt win=$panelTitle, valueBackColor=(0,0,0)
		endif

		Make/FREE/T/N=(numCtrls) followerEntries = GetGuiControlValue(panelTitle, StringFromList(p, YOKE_CONTROLS_DISABLE_AND_LINK))

		if(EqualWaves(leadEntries, followerEntries, 1))
			continue
		endif

		// find the differing control
		for(j = 0; j < numEntries; j +=1)
			if(!cmpstr(leadEntries[j], followerEntries[j]))
				continue
			endif

			printf "(%s) %s setting does not match leader panel\r", panelTitle, desc[i]
			ControlWindowToFront()
			return 1
		endfor
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
	variable ampSerial, ampChannelID
	string ctrl, endWave, ttlWave, dacWave, refDacWave
	string list

	ASSERT(mode == DATA_ACQUISITION_MODE || mode == TEST_PULSE_MODE, "Invalid mode")

	if(DAP_DeviceIsUnlocked(panelTitle))
		printf "(%s) Device is unlocked. Please lock the device.\r", panelTitle
		ControlWindowToFront()
		return 1
	endif

	if(mode == DATA_ACQUISITION_MODE && AFM_CallAnalysisFunctions(panelTitle, PRE_DAQ_EVENT))
		printf "%s: Pre DAQ analysis function requested an abort\r", panelTitle
		ControlWindowToFront()
		return 1
	endif

	// check that if multiple devices are locked we are in multi device mode
	if(ItemsInList(GetListOfLockedDevices()) > 1 && !GetCheckBoxState(panelTitle, "check_Settings_MD"))
		print "If multiple devices are locked, DAQ/TP is only possible in multi device mode"
		ControlWindowToFront()
		return 1
	endif

	list = panelTitle

	if(DeviceHasFollower(panelTitle))
		SVAR listOfFollowerDevices = $GetFollowerList(panelTitle)
		if(DAP_CheckSettingsAcrossYoked(listOfFollowerDevices, mode))
			return 1
		endif
		list = AddListItem(list, listOfFollowerDevices, ";", inf)
	endif
	DEBUGPRINT("Checking the panelTitle list: ", str=list)

	numEntries = ItemsInList(list)
	for(i = 0; i < numEntries; i += 1)

		panelTitle = StringFromList(i, list)

		if(DAP_DeviceIsUnlocked(panelTitle))
			printf "(%s) Device is unlocked. Please lock the device.\r", panelTitle
			ControlWindowToFront()
			return 1
		endif

		NVAR ITCDeviceIDGlobal = $GetITCDeviceIDGlobal(panelTitle)

#ifndef EVIL_KITTEN_EATING_MODE
		if(HW_SelectDevice(HARDWARE_ITC_DAC, ITCDeviceIDGlobal, flags=HARDWARE_PREVENT_ERROR_POPUP | HARDWARE_PREVENT_ERROR_MESSAGE))
			printf "(%s) Device can not be selected. Please unlock and lock the device.\r", panelTitle
			ControlWindowToFront()
			return 1
		endif
#endif

		if(!HasPanelLatestVersion(panelTitle, DA_EPHYS_PANEL_VERSION))
			printf "(%s) The DA_Ephys panel is too old to be usable. Please close it and open a new one.\r", panelTitle
			ControlWindowToFront()
			return 1
		endif

		numHS = sum(DAP_ControlStatusWaveCache(panelTitle, CHANNEL_TYPE_HEADSTAGE))
		if(!numHS)
			printf "(%s) Please activate at least one headstage\r", panelTitle
			ControlWindowToFront()
			return 1
		endif

		WAVE statusDA = DAP_ControlStatusWaveCache(panelTitle, CHANNEL_TYPE_DAC)
		numDACs = sum(statusDA)
		if(!numDACS)
			printf "(%s) Please activate at least one DA channel\r", panelTitle
			ControlWindowToFront()
			return 1
		endif

		numADCs = sum(DAP_ControlStatusWaveCache(panelTitle, CHANNEL_TYPE_ADC))
		if(!numADCs)
			printf "(%s) Please activate at least one AD channel\r", panelTitle
			ControlWindowToFront()
			return 1
		endif

		WAVE statusHS = DAP_ControlStatusWaveCache(panelTitle, CHANNEL_TYPE_HEADSTAGE)

		if(mode == DATA_ACQUISITION_MODE)
			// check all selected TTLs
			indexingEnabled = GetCheckBoxState(panelTitle, "Check_DataAcq_Indexing")
			Wave statusTTL = DAP_ControlStatusWaveCache(panelTitle, CHANNEL_TYPE_TTL)
			numEntries = DimSize(statusTTL, ROWS)
			for(i=0; i < numEntries; i+=1)
				if(!DC_ChannelIsActive(panelTitle, mode, CHANNEL_TYPE_TTL, i, statusTTL, statusHS))
					continue
				endif

				ctrl = GetPanelControl(i, CHANNEL_TYPE_TTL, CHANNEL_CONTROL_WAVE)
				ttlWave = GetPopupMenuString(panelTitle, ctrl)
				if(!CmpStr(ttlWave, NONE))
					printf "(%s) Please select a valid wave for TTL channel %d\r", panelTitle, i
					ControlWindowToFront()
					return 1
				endif

				if(indexingEnabled)
					ctrl = GetPanelControl(i, CHANNEL_TYPE_TTL, CHANNEL_CONTROL_INDEX_END)
					endWave = GetPopupMenuString(panelTitle, ctrl)
					if(!CmpStr(endWave, NONE))
						printf "(%s) Please select a valid indexing end wave for TTL channel %d\r", panelTitle, i
						ControlWindowToFront()
						return 1
					elseif(!CmpStr(ttlWave, endWave))
						printf "(%s) Please select a indexing end wave different as the main wave for TTL channel %d\r", panelTitle, i
						ControlWindowToFront()
						return 1
					endif
				endif
			endfor

			if(GetCheckBoxState(panelTitle, "Check_DataAcq1_RepeatAcq") && GetCheckBoxState(panelTitle, "check_DataAcq_RepAcqRandom") && indexingEnabled)
				printf "(%s) Repeated random acquisition can not be combined with indexing.\r", panelTitle
				printf "(%s) If you need this feature please contact the MIES developers.\r", panelTitle
				ControlWindowToFront()
				return 1
			endif

			if(GetCheckBoxState(panelTitle, "Check_DataAcq1_RepeatAcq") && !GetCheckBoxState(panelTitle, "Check_Settings_BackgrndDataAcq"))
				printf "(%s) Repeated random acquisition with foregound DAQ is currently brocken.\r", panelTitle
				printf "(%s) If you need this feature please contact the MIES developers.\r", panelTitle
				ControlWindowToFront()
				return 1
			endif

			if(GetCheckBoxState(panelTitle, "Check_DataAcq1_DistribDaq") && GetCheckBoxState(panelTitle, "Check_DataAcq1_dDAQOptOv"))
				printf "(%s) Only one of distributed DAQ and optimized overlap distributed DAQ can be checked.\r", panelTitle
				ControlWindowToFront()
				return 1
			endif

			// classic distributed acquisition requires that all stim sets are the same
			// oodDAQ allows different stim sets
			if(GetCheckBoxState(panelTitle, "Check_DataAcq1_DistribDaq") || GetCheckBoxState(panelTitle, "Check_DataAcq1_dDAQOptOv"))
				numEntries = DimSize(statusDA, ROWS)
				for(i=0; i < numEntries; i+=1)
					if(!DC_ChannelIsActive(panelTitle, mode, CHANNEL_TYPE_DAC, i, statusDA, statusHS))
						continue
					endif

					if(!IsFinite(AFH_GetHeadstagefromDAC(panelTitle, i)))
						printf "(%s) Distributed Acquisition does not work with unassociated DA channel %d.\r", panelTitle, i
						ControlWindowToFront()
						return 1
					endif

					if(GetCheckBoxState(panelTitle, "Check_DataAcq1_dDAQOptOv"))
						continue
					endif

					ctrl = GetPanelControl(i, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE)
					dacWave = GetPopupMenuString(panelTitle, ctrl)
					if(isEmpty(refDacWave))
						refDacWave = dacWave
					elseif(CmpStr(refDacWave, dacWave))
						printf "(%s) Please select the same stim sets for all DACs when distributed acquisition is used\r", panelTitle
						ControlWindowToFront()
						return 1
					endif
				endfor
			endif
		endif

		// avoid having different headstages reference the same amplifiers
		// and/or DA/AD channels in the "DAC Channel and Device Associations" menu
		Make/FREE/N=(NUM_HEADSTAGES) DACs, ADCs
		Make/FREE/N=(NUM_HEADSTAGES)/T ampSpec

		WAVE chanAmpAssign = GetChanAmpAssign(panelTitle)

		for(i = 0; i < NUM_HEADSTAGES; i += 1)

			ampSerial    = ChanAmpAssign[%AmpSerialNo][i]
			ampChannelID = ChanAmpAssign[%AmpChannelID][i]
			if(IsFinite(ampSerial) && IsFinite(ampChannelID))
				ampSpec[i] = DAP_GetAmplifierDef(ampSerial, ampChannelID)
			else
				// add a unique alternative entry
				ampSpec[i] = num2str(i)
			endif

			clampMode  = DAP_MIESHeadstageMode(panelTitle, i)

			if(clampMode == V_CLAMP_MODE)
				DACs[i] = ChanAmpAssign[%VC_DA][i]
				ADCs[i] = ChanAmpAssign[%VC_AD][i]
			elseif(clampMode == I_CLAMP_MODE || clampMode == I_EQUAL_ZERO_MODE)
				DACs[i] = ChanAmpAssign[%IC_DA][i]
				ADCs[i] = ChanAmpAssign[%IC_AD][i]
			else
				printf "(%s) Unhandled mode %d\r", panelTitle, clampMode
				ControlWindowToFront()
				return 1
			endif
		endfor

		if(SearchForDuplicates(DACs))
			printf "(%s) Different headstages in the \"DAC Channel and Device Associations\" menu reference the same DA channels.\r", panelTitle
			printf "Please clear the associations for unused headstages.\r"
			ControlWindowToFront()
			return 1
		endif

		if(SearchForDuplicates(ADCs))
			printf "(%s) Different headstages in the \"DAC Channel and Device Associations\" menu reference the same AD channels.\r", panelTitle
			printf "Please clear the associations for unused headstages.\r"
			ControlWindowToFront()
			return 1
		endif

		if(SearchForDuplicates(ampSpec))
			printf "(%s) Different headstages in the \"DAC Channel and Device Associations\" menu reference the same amplifier-channel-combination.\r", panelTitle
			printf "Please clear the associations for unused headstages.\r"
			ControlWindowToFront()
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
			ControlWindowToFront()
			return 1
		endif

		// unlock ITCDataWave, this happens if user functions error out and we don't catch it
		WAVE ITCDataWave = GetITCDataWave(panelTitle)
		if(NumberByKey("LOCK", WaveInfo(ITCDataWave, 0)))
			printf "(%s) Removing leftover lock on ITCDataWave\r", panelTitle
			ControlWindowToFront()
			SetWaveLock 0, ITCDataWave
		endif
	endfor

	if(GetCheckBoxState(panelTitle, "Check_Settings_NwbExport"))
		NWB_PrepareExport()
	endif

	return 0
End

/// @brief Returns 1 if the headstage has invalid settings, and zero if everything is okay
static Function DAP_CheckHeadStage(panelTitle, headStage, mode)
	string panelTitle
	variable headStage, mode

	string ctrl, dacWave, endWave, unit, func, info, str, ADUnit, DAUnit
	variable DACchannel, ADCchannel, DAheadstage, ADheadstage, DAGain, ADGain, realMode
	variable gain, scale, clampMode, i, valid_f1, valid_f2, ampConnState, needResetting
	variable DAGainMCC, ADGainMCC
	string DAUnitMCC, ADUnitMCC

	if(DAP_DeviceIsUnlocked(panelTitle))
		printf "(%s) Device is unlocked. Please lock the device.\r", panelTitle
		ControlWindowToFront()
		return 1
	endif

	Wave ChanAmpAssign       = GetChanAmpAssign(panelTitle)
	Wave/T ChanAmpAssignUnit = GetChanAmpAssignUnit(panelTitle)
	Wave channelClampMode    = GetChannelClampMode(panelTitle)

	if(headstage < 0 || headStage >= DimSize(ChanAmpAssign, COLS))
		printf "(%s) Invalid headstage %d\r", panelTitle, headStage
		ControlWindowToFront()
		return 1
	endif

	clampMode = DAP_MIESHeadstageMode(panelTitle, headstage)

	if(clampMode == V_CLAMP_MODE)
		DACchannel = ChanAmpAssign[%VC_DA][headStage]
		ADCchannel = ChanAmpAssign[%VC_AD][headStage]
		DAGain     = ChanAmpAssign[%VC_DAGain][headStage]
		ADGain     = ChanAmpAssign[%VC_ADGain][headStage]
		DAUnit     = ChanAmpAssignUnit[%VC_DAUnit][headStage]
		ADUnit     = ChanAmpAssignUnit[%VC_ADUnit][headStage]
	elseif(clampMode == I_CLAMP_MODE || clampMode == I_EQUAL_ZERO_MODE)
		DACchannel = ChanAmpAssign[%IC_DA][headStage]
		ADCchannel = ChanAmpAssign[%IC_AD][headStage]
		DAGain     = ChanAmpAssign[%IC_DAGain][headStage]
		ADGain     = ChanAmpAssign[%IC_ADGain][headStage]
		DAUnit     = ChanAmpAssignUnit[%IC_DAUnit][headStage]
		ADUnit     = ChanAmpAssignUnit[%IC_ADUnit][headStage]
	else
		printf "(%s) Unhandled mode %d\r", panelTitle, clampMode
		ControlWindowToFront()
		return 1
	endif

	ampConnState = AI_SelectMultiClamp(panelTitle, headStage, verbose=0)

	if(ampConnState == AMPLIFIER_CONNECTION_SUCCESS)

		if(AI_MIESHeadstageMatchesMCCMode(panelTitle, headStage) == 0)
			return 1
		endif

		AI_QueryGainsUnitsForClampMode(panelTitle, headStage, clampMode, DAGainMCC, ADGainMCC, DAUnitMCC, ADUnitMCC)

		if(cmpstr(DAUnit, DAUnitMCC))
			printf "(%s) The configured unit for the DA channel %d differs from the one in the \"DAC Channel and Device Associations\" menu (%s vs %s).\r", panelTitle, DACchannel, DAUnit, DAUnitMCC
			needResetting = 1
		endif

		if(!CheckIfClose(DAGain, DAGainMCC, tol=1e-4) || (clampMode == I_EQUAL_ZERO_MODE && DAGainMCC == 0.0))
			printf "(%s) The configured gain for the DA channel %d differs from the one in the \"DAC Channel and Device Associations\" menu (%g vs %g).\r", panelTitle, DACchannel, DAGain, DAGainMCC
			needResetting = 1
		endif

	   if(cmpstr(ADUnit, ADUnitMCC))
			printf "(%s) The configured unit for the AD channel %d differs from the one in the \"DAC Channel and Device Associations\" menu (%s vs %s).\r", panelTitle, ADCchannel, ADUnit, ADUnitMCC
			needResetting = 1
	   endif

		if(!CheckIfClose(ADGain, ADGainMCC, tol=1e-4))
			printf "(%s) The configured gain for the AD channel %d differs from the one in the \"DAC Channel and Device Associations\" menu (%g vs %g).\r", panelTitle, ADCchannel, ADGain, ADGainMCC
			needResetting = 1
	   endif

		if(needResetting)
			AI_UpdateChanAmpAssign(panelTitle, headStage, clampMode, DAGainMCC, ADGainMCC, DAUnitMCC, ADUnitMCC)
			printf "(%s) Please restart DAQ or TP to use the automatically imported gains from MCC.\r", panelTitle
			ControlWindowToFront()
			DAP_UpdateChanAmpAssignPanel(panelTitle)
			DAP_SyncChanAmpAssignToActiveHS(panelTitle)
			return 1
		endif
	endif

	if(!IsFinite(DACchannel) || !IsFinite(ADCchannel))
		printf "(%s) Please select a valid DA and AD channel in \"DAC Channel and Device Associations\" in the Hardware tab.\r", panelTitle
		ControlWindowToFront()
		return 1
	endif

	realMode = channelClampMode[DACchannel][%DAC]
	if(realMode != clampMode)
		printf "(%s) The clamp mode of DA %d is %s and differs from the requested mode %s.\r", panelTitle, DACchannel, ConvertAmplifierModeToString(realMode), ConvertAmplifierModeToString(clampMode)
		ControlWindowToFront()
		return 1
	endif

	realMode = channelClampMode[ADCchannel][%ADC]
	if(realMode != clampMode)
		printf "(%s) The clamp mode of AD %d is %s and differs from the requested mode %s.\r", panelTitle, ADCchannel, ConvertAmplifierModeToString(realMode), ConvertAmplifierModeToString(clampMode)
		ControlWindowToFront()
		return 1
	endif

	ADheadstage = AFH_GetHeadstageFromADC(panelTitle, ADCchannel)
	if(!IsFinite(ADheadstage))
		printf "(%s) Could not determine the headstage for the ADChannel %d.\r", panelTitle, ADCchannel
		ControlWindowToFront()
		return 1
	endif

	DAheadstage = AFH_GetHeadstageFromDAC(panelTitle, DACchannel)
	if(!IsFinite(DAheadstage))
		printf "(%s) Could not determine the headstage for the DACchannel %d.\r", panelTitle, DACchannel
		ControlWindowToFront()
		return 1
	endif

	if(DAheadstage != ADheadstage)
		printf "(%s) The configured headstages for the DA channel %d and the AD channel %d differ (%d vs %d).\r", panelTitle, DACchannel, ADCchannel, DAheadstage, ADheadstage
		ControlWindowToFront()
		return 1
	endif

	ctrl = GetPanelControl(DACchannel, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_UNIT)
	unit = GetSetVariableString(panelTitle, ctrl)
	if(isEmpty(unit))
		printf "(%s) The unit for DACchannel %d is empty.\r", panelTitle, DACchannel
		ControlWindowToFront()
		return 1
	endif

	if(ampConnState == AMPLIFIER_CONNECTION_SUCCESS && cmpstr(DAUnit, unit))
		printf "(%s) The configured unit for the DA channel %d differs from the one in the \"DAC Channel and Device Associations\" menu (%s vs %s).\r", panelTitle, DACchannel, DAUnit, unit
		ControlWindowToFront()
		return 1
	endif

	ctrl = GetPanelControl(DACchannel, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_GAIN)
	gain = GetSetVariable(panelTitle, ctrl)
	if(!isFinite(gain) || gain == 0)
		printf "(%s) The gain for DACchannel %d must be finite and non-zero.\r", panelTitle, DACchannel
		ControlWindowToFront()
		return 1
	endif

	if(ampConnState == AMPLIFIER_CONNECTION_SUCCESS && !CheckIfClose(DAGain, gain, tol=1e-4))
		printf "(%s) The configured gain for the DA channel %d differs from the one in the \"DAC Channel and Device Associations\" menu (%d vs %d).\r", panelTitle, DACchannel, DAGain, gain
		ControlWindowToFront()
		return 1
	endif

	// we allow the scale being zero
	ctrl = GetPanelControl(DACchannel, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_SCALE)
	scale = GetSetVariable(panelTitle, ctrl)
	if(!isFinite(scale))
		printf "(%s) The scale for DACchannel %d must be finite.\r", panelTitle, DACchannel
		ControlWindowToFront()
		return 1
	endif

	ctrl = GetPanelControl(ADCchannel, CHANNEL_TYPE_ADC, CHANNEL_CONTROL_UNIT)
	unit = GetSetVariableString(panelTitle, ctrl)
	if(isEmpty(unit))
		printf "(%s) The unit for ADCchannel %d is empty.\r", panelTitle, ADCchannel
		ControlWindowToFront()
		return 1
	endif

	if(ampConnState == AMPLIFIER_CONNECTION_SUCCESS && cmpstr(ADUnit, unit))
		printf "(%s) The configured unit for the AD channel %d differs from the one in the \"DAC Channel and Device Associations\" menu (%s vs %s).\r", panelTitle, ADCchannel, ADUnit, unit
		ControlWindowToFront()
		return 1
	endif

	ctrl = GetPanelControl(ADCchannel, CHANNEL_TYPE_ADC, CHANNEL_CONTROL_GAIN)
	gain = GetSetVariable(panelTitle, ctrl)
	if(!isFinite(gain) || gain == 0)
		printf "(%s) The gain for ADCchannel %d must be finite and non-zero.\r", panelTitle, ADCchannel
		ControlWindowToFront()
		return 1
	endif

	if(ampConnState == AMPLIFIER_CONNECTION_SUCCESS && !CheckIfClose(ADGain, gain, tol=1e-4))
		printf "(%s) The configured gain for the AD channel %d differs from the one in the \"DAC Channel and Device Associations\" menu (%d vs %d).\r", panelTitle, ADCchannel, ADGain, gain
		ControlWindowToFront()
		return 1
	endif

	if(mode == DATA_ACQUISITION_MODE)
		ctrl = GetPanelControl(DACchannel, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE)
		dacWave = GetPopupMenuString(panelTitle, ctrl)
		if(!CmpStr(dacWave, NONE))
			printf "(%s) Please select a stimulus set for DA channel %d referenced by Headstage %d\r", panelTitle, DACchannel, headStage
			ControlWindowToFront()
			return 1
		endif

		// third party stim sets might not match our expectations
		WAVE/Z stimSet = WB_CreateAndGetStimSet(dacWave)

		if(!WaveExists(stimSet))
			printf "(%s) The stim set %s of headstage %d does not exist or could not be created..\r", panelTitle, dacWave, headstage
			ControlWindowToFront()
			return 1
		elseif(DimSize(stimSet, ROWS) == 0)
			printf "(%s) The stim set %s of headstage %d is empty, but must have at least one row.\r", panelTitle, dacWave, headstage
			ControlWindowToFront()
			return 1
		endif

		// non fatal errors which we fix ourselves
		if(DimDelta(stimSet, ROWS) != HARDWARE_ITC_MIN_SAMPINT || DimOffset(stimSet, ROWS) != 0.0 || cmpstr(WaveUnits(stimSet, ROWS), "ms"))
			sprintf str, "(%s) The stim set %s of headstage %d must have a row dimension delta of %g, " + \
						 "row dimension offset of zero and row unit \"ms\".\r", panelTitle, dacWave, headstage, HARDWARE_ITC_MIN_SAMPINT
			DEBUGPRINT(str)
			DEBUGPRINT("The stim set is now automatically fixed")
			SetScale/P x 0, HARDWARE_ITC_MIN_SAMPINT, "ms", stimSet
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
					ControlWindowToFront()
					continue
				endif

				FUNCREF AF_PROTO_ANALYSIS_FUNC_V1 f1 = $func
				FUNCREF AF_PROTO_ANALYSIS_FUNC_V2 f2 = $func

				valid_f1 = FuncRefIsAssigned(FuncRefInfo(f1))
				valid_f2 = FuncRefIsAssigned(FuncRefInfo(f2))

				if(!valid_f1 && !valid_f2) // not a valid analysis function
					printf "(%s) The analysis function %s for stim set %s and event type \"%s\" has an invalid signature\r", panelTitle, func, dacWave, StringFromList(i, EVENT_NAME_LIST)
					ControlWindowToFront()
					return 1
				endif

				if(i == MID_SWEEP_EVENT && !GetCheckBoxState(panelTitle, "Check_Settings_BackgrndDataAcq"))
					printf "(%s) The event type \"%s\" for stim set %s can not be used together with foreground DAQ\r", panelTitle, StringFromList(i, EVENT_NAME_LIST), dacWave
					ControlWindowToFront()
					return 1
				endif
			endfor
		endif

		if(GetCheckBoxState(panelTitle, "Check_DataAcq_Indexing"))
			ctrl = GetPanelControl(DACchannel, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_INDEX_END)
			endWave = GetPopupMenuString(panelTitle, ctrl)
			if(!CmpStr(endWave, NONE))
				printf "(%s) Please select a valid indexing end wave for DA channel %d referenced by HeadStage %d\r", panelTitle, DACchannel, headStage
				ControlWindowToFront()
				return 1
			elseif(!CmpStr(dacWave, endWave))
				printf "(%s) Please select a different indexing end wave than the DAC wave for DA channel %d referenced by HeadStage %d\r", panelTitle, DACchannel, headStage
				return 1
			endif
		endif
	endif

	if(GetCheckBoxState(panelTitle, "check_Settings_RequireAmpConn") && ampConnState != AMPLIFIER_CONNECTION_SUCCESS || ampConnState == AMPLIFIER_CONNECTION_MCC_FAILED)
		printf "(%s) The amplifier of the headstage %d can not be selected, please call \"Query connected Amps\" from the Hardware Tab\r", panelTitle, headStage
		printf " and ensure that the \"Multiclamp 700B Commander\" application is open.\r"
		ControlWindowToFront()
		return 1
	endif

	return 0
End

/// @brief Synchronizes the contents of `ChanAmpAssign` and
/// `ChanAmpAssignUnit` to all active headstages
static Function DAP_SyncChanAmpAssignToActiveHS(panelTitle)
	string panelTitle

	variable i, clampMode
	WAVE statusHS = DAP_ControlStatusWaveCache(panelTitle, CHANNEL_TYPE_HEADSTAGE)

	for(i = 0; i < NUM_HEADSTAGES; i += 1)

		if(!statusHS[i])
			continue
		endif

		clampMode = DAP_MIESHeadstageMode(panelTitle, i)
		DAP_ApplyClmpModeSavdSettngs(panelTitle, i, clampMode)
	endfor
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
	WAVE GuiState            = GetDA_EphysGuiStateNum(panelTitle)

	if(clampMode == V_CLAMP_MODE)
		DACchannel = ChanAmpAssign[%VC_DA][headStage]
		ADCchannel = ChanAmpAssign[%VC_AD][headStage]
		DAGain     = ChanAmpAssign[%VC_DAGain][headStage]
		ADGain     = ChanAmpAssign[%VC_ADGain][headStage]
		DAUnit     = ChanAmpAssignUnit[%VC_DAUnit][headStage]
		ADUnit     = ChanAmpAssignUnit[%VC_ADUnit][headStage]
	elseif(ClampMode == I_CLAMP_MODE || clampMode == I_EQUAL_ZERO_MODE)
		DACchannel = ChanAmpAssign[%IC_DA][headStage]
		ADCchannel = ChanAmpAssign[%IC_AD][headStage]
		DAGain     = ChanAmpAssign[%IC_DAGain][headStage]
		ADGain     = ChanAmpAssign[%IC_ADGain][headStage]
		DAUnit     = ChanAmpAssignUnit[%IC_DAUnit][headStage]
		ADUnit     = ChanAmpAssignUnit[%IC_ADUnit][headStage]
	endif

	if(!IsFinite(DACchannel) || !IsFinite(ADCchannel))
		return NaN
	endif

	// DAC channels
	ctrl = GetPanelControl(DACchannel, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_CHECK)
	SetCheckBoxState(panelTitle, 	ctrl, CHECKBOX_SELECTED)
	GuiState[DACchannel][%DAState] = CHECKBOX_SELECTED
	ctrl = GetPanelControl(DACchannel, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_GAIN)
	SetSetVariable(panelTitle, ctrl, DaGain)
	ctrl = GetPanelControl(DACchannel, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_UNIT)
	SetSetVariableString(panelTitle, ctrl, DaUnit)
	ChannelClampMode[DACchannel][%DAC] = clampMode

	// ADC channels
	ctrl = GetPanelControl(ADCchannel, CHANNEL_TYPE_ADC, CHANNEL_CONTROL_CHECK)
	SetCheckBoxState(panelTitle, ctrl, CHECKBOX_SELECTED)
	GuiState[ADCchannel][%ADState] = CHECKBOX_SELECTED
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
	WAVE GuiState         = GetDA_EphysGuiStateNum(panelTitle)

	if(ClampMode == V_CLAMP_MODE)
		DACchannel = ChanAmpAssign[%VC_DA][headStage]
		ADCchannel = ChanAmpAssign[%VC_AD][headStage]
	elseif(ClampMode == I_CLAMP_MODE || clampMode == I_EQUAL_ZERO_MODE)
		DACchannel = ChanAmpAssign[%IC_DA][headStage]
		ADCchannel = ChanAmpAssign[%IC_AD][headStage]
	endIf

	if(!IsFinite(DACchannel) || !IsFinite(ADCchannel))
		return NaN
	endif

	ctrl = GetPanelControl(DACchannel, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_CHECK)
	SetCheckBoxState(panelTitle, ctrl, CHECKBOX_UNSELECTED)
	ChannelClampMode[DACchannel][%DAC] = nan
	GuiState[DACchannel][%DAState]     = CHECKBOX_UNSELECTED

	ctrl = GetPanelControl(ADCchannel, CHANNEL_TYPE_ADC, CHANNEL_CONTROL_CHECK)
	SetCheckBoxState(panelTitle, ctrl, CHECKBOX_UNSELECTED)
	ChannelClampMode[ADCchannel][%ADC] = nan
	GuiState[ADCchannel][%ADState]     = CHECKBOX_UNSELECTED
End

/// @brief Returns the name of the checkbox control (radio button) handling the clamp mode of the given headstage or all headstages
/// @param mode			One of the amplifier modes @ref AmplifierClampModes
/// @param headstage	number of the headstage or one of @ref AllHeadstageModeConstants
Function/S DAP_GetClampModeControl(mode, headstage)
	variable mode, headstage

	ASSERT(headStage >= CHANNEL_INDEX_ALL_I_ZERO && headStage < NUM_HEADSTAGES, "invalid headStage index")
	
	if(headstage >= 0)
		switch(mode)
			case V_CLAMP_MODE:
				return "Radio_ClampMode_" + num2str(headstage * 2)
			case I_CLAMP_MODE:
				return "Radio_ClampMode_" + num2str(headstage * 2 + 1)
			case I_EQUAL_ZERO_MODE:
				return "Radio_ClampMode_" + num2str(headstage * 2 + 1) + "IZ"
			default:
				ASSERT(0, "invalid mode")
			break
		endswitch
	else
		switch(mode)
			case V_CLAMP_MODE:
				return "Radio_ClampMode_AllVClamp"
			case I_CLAMP_MODE:
				return "Radio_ClampMode_AllIClamp"
			case I_EQUAL_ZERO_MODE:
				return "Radio_ClampMode_AllIZero"
			default:
				ASSERT(0, "invalid mode")
			break
		endswitch
	endif
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
/// @param[out] headStage   number of the headstage or one of @ref AllHeadstageModeConstants
static Function DAP_GetInfoFromControl(panelTitle, ctrl, mode, headStage)
	string panelTitle, ctrl
	variable &mode, &headStage

	string clampMode     = "Radio_ClampMode_"
	string headStageCtrl = "Check_DataAcqHS_"
	variable pos1, pos2, ctrlNo
	string ICctrl, VCctrl, iZeroCtrl, ctrlClean, ctrlSuffix

	mode      = NaN
	headStage = NaN

	ASSERT(!isEmpty(ctrl), "Empty control")

	pos1 = strsearch(ctrl, clampMode, 0)
	pos2 = strsearch(ctrl, headStageCtrl, 0)

	if(pos1 != -1)
		ctrlClean = RemoveEnding(ctrl, "IZ")
		ctrlSuffix = ctrlClean[pos1 + strlen(clampMode), inf]
			if(!cmpstr(ctrlSuffix, "AllVclamp"))
				headStage = CHANNEL_INDEX_ALL_V_CLAMP
				mode = V_CLAMP_MODE
			elseif(!cmpstr(ctrlSuffix, "AllIclamp"))
				headStage = CHANNEL_INDEX_ALL_I_CLAMP
				mode = I_CLAMP_MODE
			elseif(!cmpstr(ctrlSuffix, "AllIzero"))
				headStage = CHANNEL_INDEX_ALL_I_ZERO
				mode = I_EQUAL_ZERO_MODE			
			else
				ctrlNo = str2num(ctrlSuffix)
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
	string panelTitle, control

	switch(cba.eventCode)
		case 2: // mouse up
			try
				panelTitle = cba.win
				control    = cba.ctrlName
				DAP_GetInfoFromControl(panelTitle, control, mode, headStage)
				DAP_ChangeHeadStageMode(panelTitle, mode, headstage, DO_MCC_MIES_SYNCING)
			catch
				SetCheckBoxState(panelTitle, control, !cba.checked)
				Abort
			endtry
		break
	endswitch

	return 0
End

Function DAP_CheckProc_HedstgeChck(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	string panelTitle, control
	variable checked

	switch(cba.eventCode)
		case 2: // mouse up
			try
				panelTitle = cba.win
				control    = cba.ctrlName
				checked    = cba.checked
				DAP_ChangeHeadstageState(panelTitle, control, checked)
			catch
				SetCheckBoxState(panelTitle, control, !checked)
				Abort
			endtry
			break
	endswitch

	return 0
End

/// @brief Change the clamp mode of the given headstage
/// @param panelTitle          device
/// @param clampMode           clamp mode to activate
/// @param headstage           Headstage [0, 8[ or use one of @ref AllHeadstageModeConstants
/// @param mccMiesSyncOverride should be zero for normal callers, 1 for callers which
///                            are doing a auto MCC function and need to change the clamp mode temporarily.
///                            Use one of @ref MCCSyncOverrides for better readability.
Function DAP_ChangeHeadStageMode(panelTitle, clampMode, headstage, mccMiesSyncOverride)
	string panelTitle
	variable headstage, clampMode, mccMiesSyncOverride

	string iZeroCtrl, VCctrl, ICctrl, headstageCtrl, ctrl
	variable activeHS, testPulseMode, oppositeMode, DAC, ADC, i, loopMax, sliderPos

	AI_AssertOnInvalidClampMode(clampMode)
	DAP_AbortIfUnlocked(panelTitle)

	WAVE ChanAmpAssign = GetChanAmpAssign(panelTitle)
	WAVE GuiState = GetDA_EphysGuiStateNum(panelTitle)
   
   Make/FREE/N=(NUM_HEADSTAGES) changeHS = 0    
	if(headstage < 0)
		changeHS[] = 1
		DAP_SetAmpModeControls(panelTitle, headstage, clampMode)
	else
		changeHS[headstage] = 1
		activeHS = DAP_GetHSstate(panelTitle, headstage)
		DAP_Slider(panelTitle, headstage)
		SetSliderPositionIndex(panelTitle, "slider_DataAcq_ActiveHeadstage", headstage)
	endif
	
	sliderPos = GetSliderPositionIndex(panelTitle, "slider_DataAcq_ActiveHeadstage")
	
	if(activeHS || headstage < 0)
		testPulseMode = TP_StopTestPulse(panelTitle)
	endif

	for(i = 0; i < NUM_HEADSTAGES ; i +=1)
		if(!changeHS[i])
			continue
		endif
	
		if(clampMode == V_CLAMP_MODE)
			DAC = ChanAmpAssign[%VC_DA][i]
			ADC = ChanAmpAssign[%VC_AD][i]
		elseif(clampMode == I_CLAMP_MODE || clampMode == I_EQUAL_ZERO_MODE)
			DAC = ChanAmpAssign[%IC_DA][i]
			ADC = ChanAmpAssign[%IC_AD][i]
		endif
	
		if(!IsFinite(DAC) || !IsFinite(ADC))
			printf "(%s) Could not switch the clamp mode to %s as no DA and/or AD channels are associated with headstage %d.\r", panelTitle, ConvertAmplifierModeToString(clampMode), headstage
			continue
		endif
		GuiState[i][%HSmode] = clampMode 
		if(isFinite(DAP_IZeroSetClampMode(panelTitle, i, clampMode)))
			DAP_SetAmpModeControls(panelTitle, i, clampMode)
			DAP_SetHeadstageChanControls(panelTitle, i, clampMode)
			DAP_ConditionallySetAmpGui(panelTitle, i, clampMode, sliderPos, mccMiesSyncOverride)
		elseif(!getCheckboxState(panelTitle, "check_Settings_RequireAmpConn"))
			DAP_SetAmpModeControls(panelTitle, i, clampMode)
			DAP_SetHeadstageChanControls(panelTitle, i, clampMode)
		elseif(getCheckboxState(panelTitle, "check_Settings_RequireAmpConn"))
			DAP_SetAmpModeControls(panelTitle, i, clampMode)
		endif
		
	endfor

	DAP_UpdateDAQControls(panelTitle, REASON_HEADSTAGE_CHANGE)

	if(activeHS || headstage < 0)
		TP_RestartTestPulse(panelTitle, testPulseMode)
	endif

	DAP_UpdateAllCtrlsPerClampMode(panelTitle)
End

///@brief Sets the clamp mode by going through I=0 mode if check_Settings_AmpIEQZstep is checked
///			Stops the TP if changing mode for a single headstage
/// @param 	panelTitle		device
/// @param 	headstage			headstage to undergo mode switch
/// @param 	clampMode			clamp mode to activate
static Function DAP_IZeroSetClampMode(panelTitle, headstage, clampMode)
	string panelTitle
	variable headstage
	variable clampMode
			
	if(GetCheckBoxState(panelTitle, "check_Settings_AmpIEQZstep") && (clampMode == I_CLAMP_MODE || clampMode == V_CLAMP_MODE))
		AI_SetClampMode(panelTitle, headstage, I_EQUAL_ZERO_MODE)
		Sleep/Q/T/C=-1 6
	endif
	
	return AI_SetClampMode(panelTitle, headstage, clampMode)
End

///@brief Sets the control state of the radio buttons used for setting the clamp mode on the Data Acquisition Tab of the DA_Ephys panel
///@param panelTitle	device
///@param headstage		controls associated with headstage are set
///@param clampMode		clamp mode to activate
static Function DAP_SetAmpModeControls(panelTitle, headstage, clampMode)
	string panelTitle
	variable headstage
	variable clampMode
	
	string VCctrl    = DAP_GetClampModeControl(V_CLAMP_MODE, headstage)
	string ICctrl    = DAP_GetClampModeControl(I_CLAMP_MODE, headstage)
	string iZeroCtrl = DAP_GetClampModeControl(I_EQUAL_ZERO_MODE, headstage)
	string ctrl      = DAP_GetClampModeControl(clampMode, headstage)

	SetCheckboxState(panelTitle, VCctrl, CHECKBOX_UNSELECTED)
	SetCheckboxState(panelTitle, ICctrl, CHECKBOX_UNSELECTED)
	SetCheckboxState(panelTitle, iZeroCtrl, CHECKBOX_UNSELECTED)

	if(headstage >= 0)
		SetCheckboxState(panelTitle, ctrl, CHECKBOX_SELECTED)
	endif
End

///@brief Sets the DA and AD channel settings according to the headstage mode
///@param	panelTitle 	Device (used for data acquisition)
///@param	headstage		channels associated with headstage are set
///@param	clampMode		clamp mode to activate
static Function DAP_SetHeadstageChanControls(panelTitle, headstage, clampMode)
	string panelTitle
	variable headstage
	variable clampMode
	
	if(DAP_GetHSstate(panelTitle, headstage))
		variable oppositeMode = (clampMode == I_CLAMP_MODE || clampMode == I_EQUAL_ZERO_MODE ? V_CLAMP_MODE : I_CLAMP_MODE)
		DAP_RemoveClampModeSettings(panelTitle, headstage, oppositeMode)
		DAP_ApplyClmpModeSavdSettngs(panelTitle, headstage, clampMode)
	endif
End

///@brief Sets the amp GUI (updates the selected tab according to the clamp mode) if the headstage being set and the user selected headstage are the same.
///@param	panelTitle 	Device (used for data acquisition)
///@param	headstage		channels associated with headstage are set
///@param	clampMode		clamp mode to activate
///@param	sliderPos		index of the slider control: slider_DataAcq_ActiveHeadstage
///@param	mccMiesSyncOverride should be zero for normal callers, 1 for callers which
///                            are doing a auto MCC function and need to change the clamp mode temporarily.
///                            Use one of @ref MCCSyncOverrides for better readability.
static Function DAP_ConditionallySetAmpGui(panelTitle, headstage, clampMode, sliderPos, mccMiesSyncOverride)
	string panelTitle
	variable headstage
	variable clampMode
	variable sliderPos
	variable mccMiesSyncOverride
	
	if(sliderPos == headstage)
		DAP_UpdateClampmodeTabs(panelTitle, headstage, clampMode, mccMiesSyncOverride)
	endif
End

static Function DAP_UpdateAllCtrlsPerClampMode(panelTitle)
	string panelTitle

	variable i, numEntries
	variable clampMode, numVClamp, numIClamp

	WAVE GUIState = GetDA_EphysGuiStateNum(panelTitle)

	for(i = 0; i < NUM_HEADSTAGES; i += 1)
		clampMode = GuiState[i][%HSmode]

		numVClamp += (clampMode == V_CLAMP_MODE)
		numIClamp += (clampMode == I_CLAMP_MODE)
	endfor

	Make/FREE/T VControls = {"group_DA_AllVClamp",                                                                  \
							GetPanelControl(CHANNEL_INDEX_ALL_V_CLAMP, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_CHECK),    \
							GetPanelControl(CHANNEL_INDEX_ALL_V_CLAMP, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE),     \
							GetPanelControl(CHANNEL_INDEX_ALL_V_CLAMP, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_SCALE),    \
							GetPanelControl(CHANNEL_INDEX_ALL_V_CLAMP, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_SEARCH),   \
							GetPanelControl(CHANNEL_INDEX_ALL_V_CLAMP, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_INDEX_END) }

	Make/FREE/T IControls = {"group_DA_AllIClamp",                                                                  \
							GetPanelControl(CHANNEL_INDEX_ALL_I_CLAMP, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_CHECK),    \
							GetPanelControl(CHANNEL_INDEX_ALL_I_CLAMP, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE),     \
							GetPanelControl(CHANNEL_INDEX_ALL_I_CLAMP, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_SCALE),    \
							GetPanelControl(CHANNEL_INDEX_ALL_I_CLAMP, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_SEARCH),   \
							GetPanelControl(CHANNEL_INDEX_ALL_I_CLAMP, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_INDEX_END) }

	if(numVClamp)
		EnableControls(panelTitle, TextWaveToList(VControls, ";"))
	else
		DisableControls(panelTitle, TextWaveToList(VControls, ";"))
	endif

	if(numIClamp)
		EnableControls(panelTitle, TextWaveToList(IControls, ";"))
	else
		DisableControls(panelTitle, TextWaveToList(IControls, ";"))
	endif
End

/// See @ref MCCSyncOverrides for allowed values of `mccMiesSyncOverride`
static Function DAP_UpdateClampmodeTabs(panelTitle, headStage, clampMode, mccMiesSyncOverride)
	string panelTitle
	variable headStage, clampMode, mccMiesSyncOverride

	string highlightSpec = "\\f01\\Z11"

	AI_AssertOnInvalidClampMode(clampMode)

	AI_SyncAmpStorageToGUI(panelTitle, headStage)
	ChangeTab(panelTitle, "tab_DataAcq_Amp", clampMode)

	if(GetCheckBoxState(panelTitle, "check_Settings_SyncMiesToMCC") && mccMiesSyncOverride == DO_MCC_MIES_SYNCING)
		AI_SyncGUIToAmpStorageAndMCCApp(panelTitle, headStage, clampMode)
	endif

	TabControl tab_DataAcq_Amp win=$panelTitle, tabLabel(V_CLAMP_MODE)      = SelectString(clampMode == V_CLAMP_MODE,      "", highlightSpec) + "V-Clamp"
	TabControl tab_DataAcq_Amp win=$panelTitle, tabLabel(I_CLAMP_MODE)      = SelectString(clampMode == I_CLAMP_MODE,      "", highlightSpec) + "I-Clamp"
	TabControl tab_DataAcq_Amp win=$panelTitle, tabLabel(I_EQUAL_ZERO_MODE) = SelectString(clampMode == I_EQUAL_ZERO_MODE, "", highlightSpec) + "I = 0"
End

static Function DAP_ChangeHeadstageState(panelTitle, headStageCtrl, enabled)
	string panelTitle, headStageCtrl
	variable enabled
	
	variable clampMode, headStage, TPState, ICstate, VCstate, IZeroState
	variable channelType, controlType, i
	string VCctrl, ICctrl, IZeroCtrl

	DAP_AbortIfUnlocked(panelTitle)

	WAVE GUIState = GetDA_EphysGuiStateNum(panelTitle)

	DAP_ParsePanelControl(headStageCtrl, headstage, channelType, controlType)
	ASSERT(channelType == CHANNEL_TYPE_HEADSTAGE && controlType == CHANNEL_CONTROL_CHECK, "Expected headstage checkbox control")

	TPState = TP_StopTestPulse(panelTitle)
	
	Make/FREE/N=(NUM_HEADSTAGES) changeHS = 0    
	if(headstage >= 0)
		changeHS[headstage] = 1
	else
		changeHS[] = 1
	endif
	
	for(i = 0; i < NUM_HEADSTAGES ; i +=1)
		if(!changeHS[i])
			continue
		endif
		
		headStageCtrl = GetPanelControl(i, CHANNEL_TYPE_HEADSTAGE, CHANNEL_CONTROL_CHECK)
		SetCheckBoxState(panelTitle, headStageCtrl, enabled)

		GuiState[i][%HSState] = enabled
	
		clampMode = GuiState[i][%HSmode]
		if(!enabled)
			DAP_RemoveClampModeSettings(panelTitle, i, clampMode)
			P_SetPressureMode(panelTitle, i, PRESSURE_METHOD_ATM)
			P_GetPressureType(panelTitle)
		else
			DAP_ApplyClmpModeSavdSettngs(panelTitle, i, clampMode)
		endif

		VCctrl    = DAP_GetClampModeControl(V_CLAMP_MODE, i)
		ICctrl    = DAP_GetClampModeControl(I_CLAMP_MODE, i)
		IZeroCtrl = DAP_GetClampModeControl(I_EQUAL_ZERO_MODE, i)
	
		VCstate    = GetCheckBoxState(panelTitle, VCctrl)
		ICstate    = GetCheckBoxState(panelTitle, ICctrl)
		IZeroState = GetCheckBoxState(panelTitle, IZeroCtrl)

		if(VCstate + ICstate + IZeroState != 1) // someone messed up the radio button logic, reset to V_CLAMP_MODE
			PGC_SetAndActivateControl(panelTitle, VCctrl, val=CHECKBOX_SELECTED)
		else
			if(enabled && GetCheckBoxState(panelTitle, "check_Settings_SyncMiesToMCC"))
				PGC_SetAndActivateControl(panelTitle, DAP_GetClampModeControl(clampMode, i), val=CHECKBOX_SELECTED)
			endif
		endif
	endfor

	DAP_UpdateDAQControls(panelTitle, REASON_STIMSET_CHANGE | REASON_HEADSTAGE_CHANGE)

	WAVE statusHS = DAP_ControlStatusWaveCache(panelTitle, CHANNEL_TYPE_HEADSTAGE)
	if(Sum(statusHS) > 0 )
		TP_RestartTestPulse(panelTitle, TPState)
	endif
End

/// @brief Stop the testpulse and data acquisition
///
/// Should be used if `Multi Device Support` is not checked
Function DAP_StopOngoingDataAcquisition(panelTitle)
	string panelTitle

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
		ITC_StopITCDeviceTimer(panelTitle)

		HW_ITC_StopAcq()
		// zero channels that may be left high
		ITC_ZeroITCOnActiveChan(panelTitle)

		if(!discardData)
			SWS_SaveAndScaleITCData(panelTitle, forcedStop = 1)
		endif

		needsOTCAfterDAQ = needsOTCAfterDAQ | 1
	else
		// force a stop if invoked during a 'down' time, with nothing happening.
		if(!RA_IsFirstSweep(panelTitle))
			NVAR count = $GetCount(panelTitle)
			count = GetValDisplayAsNum(panelTitle, "valdisp_DataAcq_SweepsInSet")
			needsOTCAfterDAQ = needsOTCAfterDAQ | 1
		endif
	endif

	if(needsOTCAfterDAQ)
		DAP_OneTimeCallAfterDAQ(panelTitle, forcedStop = 1)
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
			ASSERT(DeviceCanLead(panelTitle),"This device can not lead")

			EnableControls(panelTitle,"button_Hardware_Independent;button_Hardware_AddFollower;title_hardware_Follow;popup_Hardware_AvailITC1600s")
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

			DisableControls(panelTitle,"button_Hardware_Independent;button_Hardware_AddFollower;popup_Hardware_YokedDACs;button_Hardware_RemoveYoke;title_hardware_Follow;title_hardware_Release;popup_Hardware_AvailITC1600s")
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
		case 2: // mouse up

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

			DAP_SetITCDACasFollower(leadPanel, panelToYoke)
			DAP_UpdateFollowerControls(leadPanel, panelToYoke)
			DAP_SwitchSingleMultiMode(leadpanel, 1)
			DAP_SwitchSingleMultiMode(panelToYoke, 1)

			DAP_UpdateITIAcrossSets(leadPanel)
			DisableControls(panelToYoke, YOKE_CONTROLS_DISABLE)
			DisableControls(panelToYoke, YOKE_CONTROLS_DISABLE_AND_LINK)
			EnableControl(leadPanel, "button_Hardware_RemoveYoke")
			EnableControl(leadPanel, "popup_Hardware_YokedDACs")
			EnableControl(leadPanel, "title_hardware_Release")
			break
	endswitch

	return 0
End

static Function DAP_SyncGuiFromLeaderToFollower(panelTitle)
	string panelTitle

	variable numPanels, numEntries
	string panelList

	if(!windowExists(panelTitle) || !DAP_DeviceIsLeader(panelTitle))
		return NaN
	endif

	panelList = GetListofLeaderAndPossFollower(panelTitle)
	DAP_UpdateSweepLimitsAndDisplay(panelTitle)

	numPanels = ItemsInList(panelList)

	if(!numPanels)
		return NaN
	endif

	numEntries = ItemsInList(YOKE_CONTROLS_DISABLE_AND_LINK)

	Make/FREE/T/N=(numEntries) leadEntries    = GetGuiControlValue(panelTitle, StringFromList(p, YOKE_CONTROLS_DISABLE_AND_LINK))
	Make/FREE/N=(numPanels, numEntries) dummy = SetGuiControlValue(StringFromList(p, panelList), StringFromList(q, YOKE_CONTROLS_DISABLE_AND_LINK), leadEntries[q])
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

	SVAR listOfFollowerDevices = $GetFollowerList(leadPanel)
	if(ItemsInList(listOfFollowerDevices) == 0)
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
		str = "No Yoked Devices"
	endif
	SetVariable setvar_Hardware_YokeList Win=$leadPanel, value=_STR:str

	SetVariable setvar_Hardware_Status   Win=$panelToDeYoke, value=_STR:"Independent"

	DisableControl(panelToDeYoke,"setvar_Hardware_YokeList")
	EnableControls(panelToDeYoke, YOKE_CONTROLS_DISABLE)
	EnableControls(panelToDeYoke, YOKE_CONTROLS_DISABLE_AND_LINK)
	DAP_UpdateITIAcrossSets(panelToDeYoke)

	SetVariable setvar_Hardware_YokeList Win=$panelToDeYoke, value=_STR:"None"

	NVAR followerITCDeviceIDGlobal = $GetITCDeviceIDGlobal(panelToDeYoke)
	HW_SelectDevice(HARDWARE_ITC_DAC, followerITCDeviceIDGlobal)
	HW_DisableYoking(HARDWARE_ITC_DAC, followerITCDeviceIDGlobal)
End

Function DAP_RemoveAllYokedDACs(panelTitle)
	string panelTitle

	string panelToDeYoke, list
	variable i, listNum

	SVAR listOfFollowerDevices = $GetFollowerList(ITC1600_FIRST_DEVICE)
	if(ItemsInList(listOfFollowerDevices) == 0)
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
	variable numConnAmplifiers

	switch(ba.eventCode)
		case 2: // mouse up
			panelTitle = ba.win

			DAP_AbortIfUnlocked(panelTitle)

			numConnAmplifiers = AI_QueryGainsFromMCC(panelTitle)

			if(numConnAmplifiers)
				DAP_UpdateChanAmpAssignPanel(panelTitle)
				DAP_SyncChanAmpAssignToActiveHS(panelTitle)
			else
				printf "(%s) Could not find any amplifiers connected with headstages.\r", panelTitle
			endif
			break
	endswitch

	return 0
End

Function DAP_SliderProc_MIESHeadStage(sc) : SliderControl
	struct WMSliderAction &sc

	// eventCode is a bitmask as opposed to a plain value
	// compared to other controls
	if(sc.eventCode > 0 && sc.eventCode & 0x1)
		DAP_Slider(sc.win, sc.curVal)
	endif

	return 0
End

///@brief User selected headstage function calls
///@param panelTitle Device
///@param headstage Headstage [0, 8[
Function DAP_Slider(panelTitle, headstage)
	string panelTitle
	variable headstage

	variable mode
	DAP_AbortIfUnlocked(panelTitle)
	mode = DAP_MIESHeadstageMode(panelTitle, headStage)
	P_PressureDisplayHighlite(panelTitle, 0)
	P_SaveUserSelectedHeadstage(panelTitle, headStage)
	P_GetAutoUserOff(panelTitle)
	P_GetPressureType(panelTitle)
	P_LoadPressureButtonState(panelTitle)
	P_UpdatePressureModeTabs(panelTitle, headStage)
	DAP_UpdateClampmodeTabs(panelTitle, headStage, mode, DO_MCC_MIES_SYNCING)
	SCOPE_SetADAxisLabel(panelTitle,HeadStage)
	P_RunP_ControlIfTPOFF(panelTitle)
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
		case 2: // mouse up
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
		case 2: // mouse up
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
		DisableControls(panelTitle, "Check_Settings_BkgTP;Check_Settings_BackgrndDataAcq")
		checkedState = GetCheckBoxState(panelTitle, "Check_Settings_BkgTP")
		SetControlUserData(panelTitle, "Check_Settings_BkgTP", "oldState", num2str(checkedState))
		checkedState = GetCheckBoxState(panelTitle, "Check_Settings_BackgrndDataAcq")
		SetControlUserData(panelTitle, "Check_Settings_BackgrndDataAcq", "oldState", num2str(checkedState))

		SetCheckBoxState(panelTitle, "Check_Settings_BkgTP", CHECKBOX_SELECTED)
		SetCheckBoxState(panelTitle, "Check_Settings_BackgrndDataAcq", CHECKBOX_SELECTED)
	else
		EnableControls(panelTitle, "Check_Settings_BkgTP;Check_Settings_BackgrndDataAcq")
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

	SetValDisplay(paneltitle, "valdisp_DataAcq_OnsetDelayAuto", var=testPulseDurWithBL)
End

Function DAP_SetVarProc_TestPulseSett(sva) : SetVariableControl
	struct WMSetVariableAction &sva
	
	variable TPState
	string panelTitle
	
	switch(sva.eventCode)
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			panelTitle = sva.win
			DAP_AbortIfUnlocked(panelTitle)
			TPState = TP_StopTestPulse(panelTitle)
			DAP_UpdateOnsetDelay(panelTitle)
			TP_RestartTestPulse(panelTitle, TPState)
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
		DAP_UnlockDevice(ITC1600_FIRST_DEVICE)
	endif

	// refetch the, possibly changed, list of locked devices and unlock them all
	list = GetListOfLockedDevices()
	numItems = ItemsInList(list)
	for(i=0; i < numItems; i+=1)
		win = StringFromList(i, list)
		DAP_UnlockDevice(win)
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

Function DAP_CheckProc_SyncCtrl(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	switch(cba.eventCode)
		case 2: // mouse up
			DAP_SyncGuiFromLeaderToFollower(cba.win)
			break
	endswitch

	return 0
End

Function DAP_SetVarProc_SyncCtrl(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	switch(sva.eventCode)
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			DAP_SyncGuiFromLeaderToFollower(sva.win)
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

			DAP_AbortIfUnlocked(panelTitle)

			NVAR dataAcqRunMode = $GetDataAcqRunMode(panelTitle)

			// if data acquisition is currently running we just
			// want just call TP_StartTestPulse* which automatically
			// ends DAQ
			if(dataAcqRunMode == DAQ_NOT_RUNNING && TP_CheckIfTestpulseIsRunning(panelTitle))
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

	DAP_AbortIfUnlocked(panelTitle)

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

			DAP_AbortIfUnlocked(panelTitle)
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

			if(!DAP_DeviceIsUnlocked(panelTitle))
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

/// @brief Returns a free wave of the status of the checkboxes specified by channelType
///
/// The only caller should be DAP_RecordDA_EphysGuiState.
////
/// @param type        one of the type constants from @ref ChannelTypeAndControlConstants
/// @param panelTitle  panel title
static Function/Wave DAP_ControlStatusWave(panelTitle, type)
	string panelTitle
	variable type

	string ctrl
	variable i, numEntries

	numEntries = GetNumberFromType(var=type)

	Make/FREE/U/B/N=(numEntries) wv

	for(i = 0; i < numEntries; i += 1)
		ctrl = GetPanelControl(i, type, CHANNEL_CONTROL_CHECK)
		wv[i] = GetCheckboxState(panelTitle, ctrl)
	endfor

	return wv
End

/// @brief Return a free wave of the status of the checkboxes specified by
///        channelType, uses GetDA_EphysGuiStateNum() instead of GUI queries.
///
/// @param type        one of the type constants from @ref ChannelTypeAndControlConstants
/// @param panelTitle  panel title
Function/Wave DAP_ControlStatusWaveCache(panelTitle, type)
	string panelTitle
	variable type

	variable numEntries, col

	WAVE GUIState = GetDA_EphysGuiStateNum(panelTitle)

	numEntries = GetNumberFromType(var=type)

	switch(type)
		case CHANNEL_TYPE_ASYNC:
			col = 12
			break
		case CHANNEL_TYPE_ALARM:
			col = 14
			break
		case CHANNEL_TYPE_TTL:
			col = 9
			break
		case CHANNEL_TYPE_DAC:
			col = 2
			break
		case CHANNEL_TYPE_HEADSTAGE:
			col = 0
			break
		case CHANNEL_TYPE_ADC:
			col = 7
			break
		default:
			ASSERT(0, "invalid type")
			break
	endswitch

	Make/FREE/U/B/N=(numEntries) wv = GUIState[p][col]

	return wv
End

/// @brief Records the state of the DA_ephys panel into the GUI state wave
Function DAP_RecordDA_EphysGuiState(panelTitle, [GUIState])
	string panelTitle
	WAVE GUIState

	if(ParamIsDefault(GuiState))
		Wave GUIState = GetDA_EphysGuiStateNum(panelTitle)
	endif

	WAVE state = DAP_ControlStatusWave(panelTitle, CHANNEL_TYPE_HEADSTAGE)
	GUIState[0, NUM_HEADSTAGES - 1][%HSState] = state[p]

	WAVE state = DAP_GetAllHSMode(panelTitle)
	GUIState[0, NUM_HEADSTAGES - 1][%HSMode] = state[p]
	
	WAVE state = DAP_ControlStatusWave(panelTitle, CHANNEL_TYPE_DAC)
	GUIState[0, NUM_DA_TTL_CHANNELS - 1][%DAState] = state[p]

	WAVE state = GetAllDAEphysSetVar(panelTitle, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_GAIN)
	GUIState[0, NUM_DA_TTL_CHANNELS - 1][%DAGain] = state[p]

	WAVE state = GetAllDAEphysSetVar(panelTitle, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_SCALE)
	GUIState[0, NUM_DA_TTL_CHANNELS - 1][%DAScale] = state[p]

	WAVE state = GetAllDAEphysPopMenuIndex(panelTitle, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE)
	GUIState[0, NUM_DA_TTL_CHANNELS - 1][%DAStartIndex] = state[p]

	WAVE state = GetAllDAEphysPopMenuIndex(panelTitle, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_INDEX_END)
	GUIState[0, NUM_DA_TTL_CHANNELS - 1][%DAEndIndex] = state[p]

	WAVE state = DAP_ControlStatusWave(panelTitle, CHANNEL_TYPE_ADC)
	GUIState[0, NUM_AD_CHANNELS - 1][%ADState] = state[p]

	WAVE state = GetAllDAEphysSetVar(panelTitle, CHANNEL_TYPE_ADC, CHANNEL_CONTROL_GAIN)
	GUIState[0, NUM_AD_CHANNELS - 1][%ADGain] = state[p]

	WAVE state = DAP_ControlStatusWave(panelTitle, CHANNEL_TYPE_TTL)
	GUIState[0, NUM_DA_TTL_CHANNELS - 1][%TTLState] = state[p]

	WAVE state = GetAllDAEphysPopMenuIndex(panelTitle, CHANNEL_TYPE_TTL, CHANNEL_CONTROL_WAVE)
	GUIState[0, NUM_DA_TTL_CHANNELS - 1][%TTLStartIndex] = state[p]

	WAVE state = GetAllDAEphysPopMenuIndex(panelTitle, CHANNEL_TYPE_TTL, CHANNEL_CONTROL_INDEX_END)
	GUIState[0, NUM_DA_TTL_CHANNELS - 1][%TTLEndIndex] = state[p]

	WAVE state = DAP_ControlStatusWave(panelTitle, CHANNEL_TYPE_ASYNC)
	GUIState[0, NUM_ASYNC_CHANNELS - 1][%AsyncState] = state[p]

	WAVE state = GetAllDAEphysSetVar(panelTitle, CHANNEL_TYPE_ASYNC, CHANNEL_CONTROL_GAIN)
	GUIState[0, NUM_ASYNC_CHANNELS - 1][%AsyncGain] = state[p]

	WAVE state = DAP_ControlStatusWave(panelTitle, CHANNEL_TYPE_ALARM)
	GUIState[0, NUM_ASYNC_CHANNELS - 1][%AlarmState] = state[p]

	WAVE state = GetAllDAEphysSetVar(panelTitle, CHANNEL_TYPE_ASYNC, CHANNEL_CONTROL_ALARM_MIN)
	GUIState[0, NUM_ASYNC_CHANNELS - 1][%AlarmMin] = state[p]

	WAVE state = GetAllDAEphysSetVar(panelTitle, CHANNEL_TYPE_ASYNC, CHANNEL_CONTROL_ALARM_MAX)
	GUIState[0, NUM_ASYNC_CHANNELS - 1][%AlarmMax] = state[p]

	DAP_GetDA_Ephys_UniqueCtrlState(panelTitle, GUIState)
End

/// @brief Records the state of unique controls in the DA_ephys panel into the GUI state wave
Static Function DAP_GetDA_Ephys_UniqueCtrlState(panelTitle, GuiState)
	string panelTitle
	WAVE GUIState

	string ctrlName
	variable col
	variable lastCol = dimSize(GuiState, COLS)
	for(col = COMMON_CONTROL_GROUP_COUNT; col < lastCol; col+=1)
		ctrlName = getDimLabel(GUIState, COLS, col)
		controlInfo/w=$panelTitle $ctrlName
		ASSERT(V_flag != 0, "invalid or non existing control")
		GUIState[0][col] = V_Value
	endfor

End

/// @brief Return the mode of all DA_Ephys panel headstages
///
/// All callers, except the ones updating the GUIState wave,
/// should prefer DAP_MIESHeadstageMode() instead.
static Function/Wave DAP_GetAllHSMode(panelTitle)
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
	AddVersionToPanel(panel, DA_EPHYS_PANEL_VERSION)

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

/// @brief Extracts `channelType`, `controlType` and `channelIndex` from `ctrl`
///
/// Counterpart to GetPanelControl()
Function DAP_ParsePanelControl(ctrl, channelIndex, channelType, controlType)
	string ctrl
	variable &channelIndex, &channelType, &controlType

	string elem0, elem1, elem2
	variable numUnderlines

	channelIndex = NaN
	channelType  = NaN
	controlType  = NaN

	ASSERT(!isEmpty(ctrl), "Empty control")
	numUnderlines = ItemsInList(ctrl, "_")
	ASSERT(numUnderlines >= 2, "Unexpected control naming scheme")

	elem0 = StringFromList(0, ctrl, "_")
	elem1 = StringFromList(1, ctrl, "_")
	elem2 = StringFromList(numUnderlines - 1, ctrl, "_")

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
		case "Search":
			controlType = CHANNEL_CONTROL_SEARCH
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

	strswitch(elem2)
		case "All":
			channelIndex = CHANNEL_INDEX_ALL
			break
		case "AllVClamp":
			channelIndex = CHANNEL_INDEX_ALL_V_CLAMP
			break
		case "AllIClamp":
			channelIndex = CHANNEL_INDEX_ALL_I_CLAMP
			break
		default:
			channelIndex = str2num(elem2)
			ASSERT(IsFinite(channelIndex), "Invalid channelIndex")
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

/// @brief Query the device lock status
///
/// @returns device lock status, 1 if unlocked, 0 if locked
Function DAP_DeviceIsUnlocked(panelTitle)
	string panelTitle

	string deviceType, deviceNumber
	return !(ParseDeviceString(panelTitle, deviceType, deviceNumber) && WhichListItem(deviceType, DEVICE_TYPES) != -1 && WhichListItem(deviceNumber, DEVICE_NUMBERS) != -1)
End

Function DAP_AbortIfUnlocked(panelTitle)
	string panelTitle

	if(DAP_DeviceIsUnlocked(panelTitle))
		Abort "A ITC device must be locked (see Hardware tab) to proceed"
	endif
End

/// @brief Updates the state of a control in the GUIState numeric wave
Function DAP_UpdateControlInGuiStateWv(panelTitle, controlName, state)
	string panelTitle
	string controlName
	variable state

	variable col, channelIndex, channelType, controlType

	WAVE GUIState = GetDA_EphysGuiStateNum(panelTitle)
	col = finddimlabel(GUIState, COLS, controlName)
	if(col != -2)
		GUIState[0][Col] = state
		return NaN
	endif

	// maybe it is one of the combined entries
	DAP_ParsePanelControl(controlName, channelIndex, channelType, controlType)
	if(controlType == CHANNEL_CONTROL_CHECK)
		switch(channelType)
			case CHANNEL_TYPE_DAC:
				GuiState[channelIndex][%DAState] = state
				break
			case CHANNEL_TYPE_ADC:
				GuiState[channelIndex][%ADState] = state
				break
			case CHANNEL_TYPE_TTL:
				GuiState[channelIndex][%TTLState] = state
				break
			case CHANNEL_TYPE_HEADSTAGE:
				GuiState[channelIndex][%HSState] = state
				break
			case CHANNEL_TYPE_ASYNC:
				GuiState[channelIndex][%AsyncState] = state
				break
			case CHANNEL_TYPE_ALARM:
				GuiState[channelIndex][%AlarmState] = state
				break
			default:
				ASSERT(0, "Unknown type")
				break
		endswitch
	endif
End

Function DAP_CheckProc_UpdateGuiState(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	switch( cba.eventCode )
		case 2: // mouse up
			Variable checked = cba.checked
			DAP_UpdateControlInGuiStateWv(cba.win, cba.ctrlName, cba.checked)
			P_RunP_ControlIfTPOFF(cba.win)
			break
	endswitch

	return 0
End

Function DAP_CheckProc_Settings_PUser(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	variable col
	switch( cba.eventCode )
		case 2: // mouse up
			DAP_AbortIfUnlocked(cba.win)
			WAVE pressureDataWv = P_GetPressureDataWaveRef(cba.win)
			WAVE GUIState = GetDA_EphysGuiStateNum(cba.win)
			DAP_UpdateControlInGuiStateWv(cba.win, cba.ctrlName, cba.checked)
			P_RunP_ControlIfTPOFF(cba.win)
			if(P_ValidatePressureSetHeadstage(cba.win, PressureDataWv[0][%UserSelectedHeadStage]))
				P_SetPressureValves(cba.win, PressureDataWv[0][%UserSelectedHeadStage], P_GetUserAccess(cba.win, PressureDataWv[0][%UserSelectedHeadStage],PressureDataWv[PressureDataWv[0][%UserSelectedHeadStage]][%Approach_Seal_BrkIn_Clear]))
			endif
			P_GetPressureType(cba.win)
			break
	endswitch

	return 0
End

Function DAP_ButtonProc_Settings_OpenDev(ba) : ButtonControl
	struct WMButtonAction& ba

	string panelTitle, deviceToOpen
	variable hwType, deviceID

	switch(ba.eventCode)
		case 2: // mouse up
			deviceToOpen = BuildDeviceString(DAP_GetDeviceType(ba.win), DAP_GetDeviceNumber(ba.win))
			deviceID = HW_OpenDevice(deviceToOpen, hwType)
			DoAlert/T="Ready light check" 0, "Click \"OK\" when finished checking device"
			HW_CloseDevice(hwType, deviceID)
			break
	endswitch

	return 0
End

Function DAP_ButtonProc_LockDev(ba) : ButtonControl
	struct WMButtonAction& ba

	switch(ba.eventCode)
		case 2: // mouse up
			ba.blockReentry = 1
			DAP_LockDevice(ba.win)
			break
	endswitch

	return 0
End

Function DAP_ButProc_Hrdwr_UnlckDev(ba) : ButtonControl
	struct WMButtonAction& ba

	switch(ba.eventCode)
		case 2: // mouse up
			ba.blockReentry = 1
			DAP_UnlockDevice(ba.win)
			break
	endswitch

	return 0
End

static Function DAP_UpdateDataFolderDisplay(panelTitle, locked)
	string panelTitle
	variable locked

	string title
	if(locked)
		title = "Data folder path = " + GetDevicePathAsString(panelTitle)
	else
		title = "Lock a device to generate device folder structure"
	endif

	GroupBox group_Hardware_FolderPath win = $panelTitle, title = title
End

Function DAP_LockDevice(panelTitle)
	string panelTitle

	variable locked, hardwareType, headstage
	string panelTitleLocked, msg

	SVAR miesVersion = $GetMiesVersion()

	if(!cmpstr(miesVersion, UNKNOWN_MIES_VERSION))
		DEBUGPRINT_OR_ABORT("The MIES version is unknown, locking devices is therefore only allowed in debug mode.")
	endif

	panelTitleLocked = BuildDeviceString(DAP_GetDeviceType(panelTitle), DAP_GetDeviceNumber(panelTitle))
	if(windowExists(panelTitleLocked))
		Abort "Attempt to duplicate device connection! Please choose another device number as that one is already in use."
	endif

	if(!HasPanelLatestVersion(panelTitle, DA_EPHYS_PANEL_VERSION))
		Abort "Can not lock the device. The DA_Ephys panel is too old to be usable. Please close it and open a new one."
	endif

	if(!DAP_GetNumITCDevicesPerType(panelTitle))
#ifndef EVIL_KITTEN_EATING_MODE
		sprintf msg, "Can not lock the device \"%s\" as no devices of type \"%s\" are connected.", panelTitleLocked, DAP_GetDeviceType(panelTitle)
		Abort msg
#else
		print "EVIL_KITTEN_EATING_MODE is ON: Allowing to lock altough no devices could be found."
#endif
	endif

	NVAR ITCDeviceIDGlobal = $GetITCDeviceIDGlobal(paneltitleLocked)
	ITCDeviceIDGlobal = HW_OpenDevice(paneltitleLocked, hardwareType)

	if(ITCDeviceIDGlobal < 0 || ITCDeviceIDGlobal >= HARDWARE_MAX_DEVICES)
#ifndef EVIL_KITTEN_EATING_MODE
		Abort "Can not lock the device."
#else
		print "EVIL_KITTEN_EATING_MODE is ON: Forcing ITCDeviceIDGlobal to zero"
		ControlWindowToFront()
		ITCDeviceIDGlobal = 0
#endif
	endif

	DisableControls(panelTitle,"popup_MoreSettings_DeviceType;popup_moreSettings_DeviceNo;button_SettingsPlus_PingDevice")
	EnableControl(panelTitle,"button_SettingsPlus_unLockDevic")
	DisableControl(panelTitle,"button_SettingsPlus_LockDevice")

	DoWindow/W=$panelTitle/C $panelTitleLocked

	locked = 1
	DAP_UpdateDataFolderDisplay(panelTitleLocked, locked)

	AI_FindConnectedAmps()
	DAP_UpdateListOfITCPanels()
	DAP_UpdateListOfPressureDevices()
	headstage = str2num(GetPopupMenuString(panelTitleLocked, "Popup_Settings_HeadStage"))
	DAP_SyncDeviceAssocSettToGUI(paneltitleLocked, headstage)

	DAP_UpdateAllYokeControls()
	// create the amplifier settings waves
	GetAmplifierParamStorageWave(panelTitleLocked)
	WBP_UpdateITCPanelPopUps(panelTitle=panelTitleLocked)
	DAP_UnlockCommentNotebook(panelTitleLocked)
	DAP_ToggleAcquisitionButton(panelTitleLocked, DATA_ACQ_BUTTON_TO_DAQ)
	SI_CalculateMinSampInterval(panelTitleLocked, DATA_ACQUISITION_MODE)
	DAP_RecordDA_EphysGuiState(panelTitleLocked)

	headstage = GetSliderPositionIndex(panelTitleLocked, "slider_DataAcq_ActiveHeadstage")
	P_SaveUserSelectedHeadstage(panelTitleLocked, headstage)

	// upgrade all four labnotebook waves in wanna-be atomic way
	GetLBNumericalKeys(panelTitleLocked)
	GetLBNumericalValues(panelTitleLocked)
	GetLBTextualKeys(panelTitleLocked)
	GetLBTextualValues(panelTitleLocked)

	NVAR sessionStartTime = $GetSessionStartTime()
	sessionStartTime = DateTimeInUTC()

	NVAR rngSeed = $GetRNGSeed(panelTitleLocked)
	rngSeed = GetNonReproducibleRandom()

	DAP_UpdateOnsetDelay(panelTitleLocked)

	HW_RegisterDevice(panelTitleLocked, HARDWARE_ITC_DAC, ITCDeviceIDGlobal)
End

/// @brief Returns the device type as string, readout from the popup menu in the Hardware tab
static Function/s DAP_GetDeviceType(panelTitle)
	string panelTitle

	ControlInfo /w = $panelTitle popup_MoreSettings_DeviceType
	ASSERT(V_flag != 0, "Non-existing control or window")
	return S_value
End

/// @brief Returns the device type as index into the popup menu in the Hardware tab
static Function DAP_GetDeviceTypeIndex(panelTitle)
	string panelTitle

	ControlInfo /w = $panelTitle popup_MoreSettings_DeviceType
	ASSERT(V_flag != 0, "Non-existing control or window")
	return V_value - 1
End

/// @brief Returns the selected ITC device number from a DA_Ephys panel (locked or unlocked)
static Function/s DAP_GetDeviceNumber(panelTitle)
	string panelTitle

	ControlInfo /w = $panelTitle popup_moreSettings_DeviceNo
	ASSERT(V_flag != 0, "Non-existing control or window")
	return S_value
End

static Function DAP_ClearWaveIfExists(wv)
	WAVE/Z wv

	if(WaveExists(wv))
		Redimension/N=(0, -1, -1, -1) wv
	endif
End

static Function DAP_UnlockDevice(panelTitle)
	string panelTitle

	variable flags, state

	if(!windowExists(panelTitle))
		DEBUGPRINT("Can not unlock the non-existing panel", str=panelTitle)
		return NaN
	endif

	if(DAP_DeviceIsUnlocked(panelTitle))
		DEBUGPRINT("Device is not locked, doing nothing", str=panelTitle)
		return NaN
	endif

	// we need to turn off TP after DAQ as this could prevent stopping the TP,
	// especially for foreground TP
	state = GetCheckBoxState(panelTitle, "check_Settings_TPAfterDAQ")
	SetCheckBoxState(panelTitle, "check_Settings_TPAfterDAQ", CHECKBOX_UNSELECTED)
	ITC_StopDAQ(panelTitle)
	TP_StopTestPulse(panelTitle)
	SetCheckBoxState(panelTitle, "check_Settings_TPAfterDAQ", state)

	DAP_SerializeCommentNotebook(panelTitle)
	DAP_LockCommentNotebook(panelTitle)
	P_Disable() // Closes DACs used for pressure regulation
	if(DeviceHasFollower(panelTitle))
		DAP_RemoveALLYokedDACs(panelTitle)
	else
		DAP_RemoveYokedDAC(panelTitle)
	endif

	EnableControls(panelTitle,"button_SettingsPlus_LockDevice;popup_MoreSettings_DeviceType;popup_moreSettings_DeviceNo;button_SettingsPlus_PingDevice")
	DisableControl(panelTitle,"button_SettingsPlus_unLockDevic")
	EnableControls(panelTitle, "StartTestPulseButton;DataAcquireButton;Check_DataAcq1_RepeatAcq;Check_DataAcq_Indexing;SetVar_DataAcq_ITI;SetVar_DataAcq_SetRepeats;Check_DataAcq_Get_Set_ITI")
	SetVariable setvar_Hardware_Status Win = $panelTitle, value= _STR:"Independent"
	DAP_ResetGUIAfterDAQ(panelTitle)
	DAP_ToggleTestpulseButton(panelTitle, TESTPULSE_BUTTON_TO_START)

	string panelTitleUnlocked = BASE_WINDOW_TITLE
	if(CheckName(panelTitleUnlocked,CONTROL_PANEL_TYPE))
		panelTitleUnlocked = UniqueName(BASE_WINDOW_TITLE + "_",CONTROL_PANEL_TYPE,1)
	endif
	DoWindow/W=$panelTitle/C $panelTitleUnlocked

	variable locked = 0
	DAP_UpdateDataFolderDisplay(panelTitleUnlocked,locked)

	NVAR/SDFR=GetDevicePath(panelTitle) ITCDeviceIDGlobal

	// shutdown the FIFO thread now in case it is still running (which should never be the case)
	TFH_StopFIFODaemon(HARDWARE_ITC_DAC, ITCDeviceIDGlobal)

	flags = HARDWARE_PREVENT_ERROR_POPUP | HARDWARE_PREVENT_ERROR_MESSAGE
	HW_SelectDevice(HARDWARE_ITC_DAC, ITCDeviceIDGlobal, flags=flags)
	HW_CloseDevice(HARDWARE_ITC_DAC, ITCDeviceIDGlobal, flags=flags)
	HW_DeRegisterDevice(HARDWARE_ITC_DAC, ITCDeviceIDGlobal, flags=flags)

	DAP_UpdateYokeControls(panelTitleUnlocked)
	DAP_UpdateListOfITCPanels()
	DAP_UpdateAllYokeControls()

	// reset our state variables to safe defaults
	NVAR dataAcqRunMode = $GetDataAcqRunMode(panelTitle)
	dataAcqRunMode = DAQ_NOT_RUNNING
	NVAR count = $GetCount(panelTitle)
	count = 0
	NVAR runMode = $GetTestpulseRunMode(panelTitle)
	runMode = TEST_PULSE_NOT_RUNNING

	SVAR/SDFR=GetITCDevicesFolder() ITCPanelTitleList
	if(!cmpstr(ITCPanelTitleList, ""))
		CloseNWBFile()

		WAVE ActiveDevicesTPMD = GetActiveDevicesTPMD()
		ActiveDevicesTPMD = NaN
		SetNumberInWaveNote(ActiveDevicesTPMD, NOTE_INDEX, 0)

		DFREF dfr = GetActiveITCDevicesFolder()
		WAVE/Z/SDFR=dfr ActiveDeviceList
		DAP_ClearWaveIfExists(ActiveDeviceList)

		DFREF dfr = GetActiveITCDevicesTimerFolder()
		WAVE/Z/SDFR=dfr ActiveDevTimeParam, TimerFunctionListWave
		DAP_ClearWaveIfExists(ActiveDevTimeParam)
		DAP_ClearWaveIfExists(TimerFunctionListWave)

		SVAR listOfFollowers = $GetFollowerList(ITC1600_FIRST_DEVICE)
		listOfFollowers = ""

		KillOrMoveToTrash(wv = GetDeviceMapping())
	endif
End

/// @brief Return the number of ITC devices of the given `type`
static Function DAP_GetNumITCDevicesPerType(panelTitle)
	string panelTitle

	return ItemsInList(ListMatch(HW_ITC_ListDevices(), DAP_GetDeviceType(panelTitle) + "_DEV_*"))
End

static Function DAP_IsDeviceTypeConnected(panelTitle)
	string panelTitle

	variable numDevices

	numDevices = DAP_GetNumITCDevicesPerType(panelTitle)

	if(!numDevices)
		DisableControl(panelTitle, "button_SettingsPlus_PingDevice")
	else
		EnableControl(panelTitle, "button_SettingsPlus_PingDevice")
	endif

	printf "Available number of specified ITC devices = %d\r" numDevices
End

/// @brief Update the list of locked devices
static Function DAP_UpdateListOfITCPanels()
	DFREF dfr = GetITCDevicesFolder()
	string/G dfr:ITCPanelTitleList = WinList("ITC*", ";", "WIN:64")
End

static Function DAP_UpdateChanAmpAssignStorWv(panelTitle)
	string panelTitle

	variable HeadStageNo, ampSerial, ampChannelID
	string amplifierDef
	Wave ChanAmpAssign       = GetChanAmpAssign(panelTitle)
	Wave/T ChanAmpAssignUnit = GetChanAmpAssignUnit(panelTitle)

	HeadStageNo = str2num(GetPopupMenuString(panelTitle,"Popup_Settings_HeadStage"))

	// Assigns V-clamp settings for a particular headstage
	ChanAmpAssign[%VC_DA][HeadStageNo]     = str2num(GetPopupMenuString(panelTitle, "Popup_Settings_VC_DA"))
	ChanAmpAssign[%VC_DAGain][HeadStageNo] = GetSetVariable(panelTitle, "setvar_Settings_VC_DAgain")
	ChanAmpAssignUnit[%VC_DAUnit][HeadStageNo]      = GetSetVariableString(panelTitle, "SetVar_Hardware_VC_DA_Unit")
	ChanAmpAssign[%VC_AD][HeadStageNo]     = str2num(GetPopupMenuString(panelTitle, "Popup_Settings_VC_AD"))
	ChanAmpAssign[%VC_ADGain][HeadStageNo] = GetSetVariable(panelTitle, "setvar_Settings_VC_ADgain")
	ChanAmpAssignUnit[%VC_ADUnit][HeadStageNo]      = GetSetVariableString(panelTitle, "SetVar_Hardware_VC_AD_Unit")

	//Assigns I-clamp settings for a particular headstage
	ChanAmpAssign[%IC_DA][HeadStageNo]     = str2num(GetPopupMenuString(panelTitle, "Popup_Settings_IC_DA"))
	ChanAmpAssign[%IC_DAGain][HeadStageNo] = GetSetVariable(panelTitle, "setvar_Settings_IC_DAgain")
	ChanAmpAssignUnit[%IC_DAUnit][HeadStageNo]      = GetSetVariableString(panelTitle, "SetVar_Hardware_IC_DA_Unit")
	ChanAmpAssign[%IC_AD][HeadStageNo]     = str2num(GetPopupMenuString(panelTitle, "Popup_Settings_IC_AD"))
	ChanAmpAssign[%IC_ADGain][HeadStageNo] = GetSetVariable(panelTitle, "setvar_Settings_IC_ADgain")
	ChanAmpAssignUnit[%IC_ADUnit][HeadStageNo]      = GetSetVariableString(panelTitle, "SetVar_Hardware_IC_AD_Unit")

	// Assigns amplifier to a particular headstage
	// sounds weird because this relationship is predetermined in hardware
	// but now you are telling the software what it is
	amplifierDef = GetPopupMenuString(panelTitle, "popup_Settings_Amplifier")
	DAP_ParseAmplifierDef(amplifierDef, ampSerial, ampChannelID)

	if(IsFinite(ampSerial) && IsFinite(ampChannelID))
		ChanAmpAssign[%AmpSerialNo][HeadStageNo]  = ampSerial
		ChanAmpAssign[%AmpChannelID][HeadStageNo] = ampChannelID
	else
		ChanAmpAssign[%AmpSerialNo][HeadStageNo]  = nan
		ChanAmpAssign[%AmpChannelID][HeadStageNo] = nan
	endif
End

static Function DAP_UpdateChanAmpAssignPanel(panelTitle)
	string panelTitle

	variable HeadStageNo, channel, ampSerial, ampChannelID
	string entry

	Wave ChanAmpAssign       = GetChanAmpAssign(panelTitle)
	Wave/T ChanAmpAssignUnit = GetChanAmpAssignUnit(panelTitle)

	HeadStageNo = str2num(GetPopupMenuString(panelTitle,"Popup_Settings_HeadStage"))

	// VC DA settings
	channel = ChanAmpAssign[%VC_DA][HeadStageNo]
	Popupmenu Popup_Settings_VC_DA win = $panelTitle, mode = (IsFinite(channel) ? channel : NUM_MAX_CHANNELS) + 1
	Setvariable setvar_Settings_VC_DAgain win = $panelTitle, value = _num:ChanAmpAssign[%VC_DAGain][HeadStageNo]
	Setvariable SetVar_Hardware_VC_DA_Unit win = $panelTitle, value = _str:ChanAmpAssignUnit[%VC_DAUnit][HeadStageNo]

	// VC AD settings
	channel = ChanAmpAssign[%VC_AD][HeadStageNo]
	Popupmenu Popup_Settings_VC_AD win = $panelTitle, mode = (IsFinite(channel) ? channel : NUM_MAX_CHANNELS) + 1
	Setvariable setvar_Settings_VC_ADgain win = $panelTitle, value = _num:ChanAmpAssign[%VC_ADGain][HeadStageNo]
	Setvariable SetVar_Hardware_VC_AD_Unit win = $panelTitle, value = _str:ChanAmpAssignUnit[%VC_ADUnit][HeadStageNo]

	// IC DA settings
	channel = ChanAmpAssign[%IC_DA][HeadStageNo]
	Popupmenu Popup_Settings_IC_DA win = $panelTitle, mode = (IsFinite(channel) ? channel : NUM_MAX_CHANNELS) + 1
	Setvariable setvar_Settings_IC_DAgain win = $panelTitle, value = _num:ChanAmpAssign[%IC_DAGain][HeadStageNo]
	Setvariable SetVar_Hardware_IC_DA_Unit win = $panelTitle, value = _str:ChanAmpAssignUnit[%IC_DAUnit][HeadStageNo]

	// IC AD settings
	channel = ChanAmpAssign[%IC_AD][HeadStageNo]
	Popupmenu  Popup_Settings_IC_AD win = $panelTitle, mode = (IsFinite(channel) ? channel : NUM_MAX_CHANNELS) + 1
	Setvariable setvar_Settings_IC_ADgain win = $panelTitle, value = _num:ChanAmpAssign[%IC_ADGain][HeadStageNo]
	Setvariable SetVar_Hardware_IC_AD_Unit win = $panelTitle, value = _str:ChanAmpAssignUnit[%IC_ADUnit][HeadStageNo]

	if(cmpstr(DAP_GetNiceAmplifierChannelList(), NONE))
		ampSerial    = ChanAmpAssign[%AmpSerialNo][HeadStageNo]
		ampChannelID = ChanAmpAssign[%AmpChannelID][HeadStageNo]
		if(isFinite(ampSerial) && isFinite(ampChannelID))
			entry = DAP_GetAmplifierDef(ampSerial, ampChannelID)
			Popupmenu popup_Settings_Amplifier win = $panelTitle, popmatch=entry
		else
			Popupmenu popup_Settings_Amplifier win = $panelTitle, popmatch=NONE
		endif
	endif
End

/// This function sets a ITC1600 device as a follower, ie. The internal clock is used to synchronize 2 or more PCI-1600
static Function DAP_SetITCDACasFollower(leadDAC, followerDAC)
	string leadDAC, followerDAC

	SVAR listOfFollowerDevices = $GetFollowerList(leadDAC)
	NVAR followerITCDeviceIDGlobal = $GetITCDeviceIDGlobal(followerDAC)

	if(WhichListItem(followerDAC, listOfFollowerDevices) == -1)
		listOfFollowerDevices = AddListItem(followerDAC, listOfFollowerDevices,";",inf)
		HW_SelectDevice(HARDWARE_ITC_DAC, followerITCDeviceIDGlobal)
		HW_EnableYoking(HARDWARE_ITC_DAC, followerITCDeviceIDGlobal)
		setvariable setvar_Hardware_YokeList Win = $leadDAC, value= _STR:listOfFollowerDevices, disable = 0
	endif
	// TB: what does this comment mean?
	// set the internal clock of the device
End

/// @brief Helper function to update all DAQ related controls after something changed.
///
/// @param panelTitle device
/// @param updateFlag One of @ref UpdateControlsFlags
Function DAP_UpdateDAQControls(panelTitle, updateFlag)
	string panelTitle
	variable updateFlag

	if(updateFlag & REASON_STIMSET_CHANGE)
		DAP_UpdateITIAcrossSets(panelTitle)
		DAP_UpdateSweepSetVariables(panelTitle)
	endif

	if(updateFlag & REASON_HEADSTAGE_CHANGE)
		SetValDisplay(panelTitle, "ValDisp_DataAcq_SamplingInt", var=DAP_GetITCSampInt(panelTitle, DATA_ACQUISITION_MODE))
	endif
End

Function DAP_ButtonProc_skipSweep(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2:
			RA_SkipSweeps(ba.win, 1)
			break
	endswitch

	return 0
End

Function DAP_ButtonProc_skipBack(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2:
			RA_SkipSweeps(ba.win, -1)
			break
	endswitch

	return 0
End

/// @brief GUI procedure which has the only purpose
///        of storing the control state in the GUI state wave
Function DAP_CheckProc_RecordInGuiState(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	switch(cba.eventCode)
		case 2: // mouse up
			DAP_UpdateControlInGuiStateWv(cba.win, cba.ctrlName, cba.checked)
			break
	endswitch

	return 0
End
