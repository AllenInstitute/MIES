#pragma rtGlobals=3		// Use modern global access method and strict wave access.

/// @file TJ_MIES_PanelITC.ipf
/// @brief __DAP__ Main data acuqisition panel DA_EPHYS

static Constant DATA_ACQU_TAB_NUM        = 0
static Constant HARDWARE_TAB_NUM         = 6

static StrConstant YOKE_LIST_OF_CONTROLS = "button_Hardware_Lead1600;button_Hardware_Independent;title_hardware_1600inst;title_hardware_Follow;button_Hardware_AddFollower;popup_Hardware_AvailITC1600s;title_hardware_Release;popup_Hardware_YokedDACs;button_Hardware_RemoveYoke"
static StrConstant FOLLOWER              = "Follower"
static StrConstant LEADER                = "Leader"

static StrConstant COMMENT_PANEL          = "UserComments"
static StrConstant COMMENT_PANEL_NOTEBOOK = "NB"

Window DA_Ephys() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(287,62,769,844)
	GroupBox group_DataAcq_WholeCell,pos={60,192},size={143,59},disable=1,title="       Whole Cell"
	GroupBox group_DataAcq_WholeCell,userdata(tabnum)=  "0"
	GroupBox group_DataAcq_WholeCell,userdata(tabcontrol)=  "tab_DataAcq_Amp"
	TitleBox Title_settings_SetManagement,pos={948,-100},size={392,213},disable=1,title="Set Management Decision Tree"
	TitleBox Title_settings_SetManagement,userdata(tabnum)=  "5"
	TitleBox Title_settings_SetManagement,userdata(tabcontrol)=  "ADC"
	TitleBox Title_settings_SetManagement,userdata(ResizeControlsInfo)= A"!!,K)!!'p6J,hsT!!#Adz!!,c)Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox Title_settings_SetManagement,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	TitleBox Title_settings_SetManagement,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	TitleBox Title_settings_SetManagement,font="Trebuchet MS",frame=4,fStyle=0
	TitleBox Title_settings_SetManagement,fixedSize=1
	TabControl ADC,pos={3,1},size={479,19},proc=ACL_DisplayTab
	TabControl ADC,userdata(currenttab)=  "6"
	TabControl ADC,userdata(initialhook)=  "DAP_TabTJHook1"
	TabControl ADC,userdata(finalhook)=  "DAP_TabControlFinalHook"
	TabControl ADC,userdata(ResizeControlsInfo)= A"!!,>Mz!!#CTJ,hm&z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TabControl ADC,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	TabControl ADC,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	TabControl ADC,userdata(tabcontrol)=  "ADC",tabLabel(0)="Data Acquisition"
	TabControl ADC,tabLabel(1)="DA",tabLabel(2)="AD",tabLabel(3)="TTL"
	TabControl ADC,tabLabel(4)="Asynchronous",tabLabel(5)="Settings"
	TabControl ADC,tabLabel(6)="Hardware",value= 6
	CheckBox Check_AD_00,pos={20,75},size={24,14},disable=1,title="0"
	CheckBox Check_AD_00,userdata(tabnum)=  "2",userdata(tabcontrol)=  "ADC"
	CheckBox Check_AD_00,userdata(ResizeControlsInfo)= A"!!,B)!!#>F!!#>6!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_AD_00,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_AD_00,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_AD_00,value= 0,side= 1
	CheckBox Check_AD_01,pos={20,121},size={24,14},disable=1,title="1"
	CheckBox Check_AD_01,userdata(tabnum)=  "2",userdata(tabcontrol)=  "ADC"
	CheckBox Check_AD_01,userdata(ResizeControlsInfo)= A"!!,B)!!#?q!!#>6!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_AD_01,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_AD_01,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_AD_01,value= 0,side= 1
	CheckBox Check_AD_02,pos={20,167},size={24,14},disable=1,title="2"
	CheckBox Check_AD_02,userdata(tabnum)=  "2",userdata(tabcontrol)=  "ADC"
	CheckBox Check_AD_02,userdata(ResizeControlsInfo)= A"!!,B)!!#@o!!#>6!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_AD_02,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_AD_02,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_AD_02,value= 0,side= 1
	CheckBox Check_AD_03,pos={20,214},size={24,14},disable=1,title="3"
	CheckBox Check_AD_03,userdata(tabnum)=  "2",userdata(tabcontrol)=  "ADC"
	CheckBox Check_AD_03,userdata(ResizeControlsInfo)= A"!!,B)!!#AI!!#>6!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_AD_03,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_AD_03,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_AD_03,value= 0,side= 1
	CheckBox Check_AD_04,pos={20,260},size={24,14},disable=1,title="4"
	CheckBox Check_AD_04,userdata(tabnum)=  "2",userdata(tabcontrol)=  "ADC"
	CheckBox Check_AD_04,userdata(ResizeControlsInfo)= A"!!,B)!!#B#!!#>6!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_AD_04,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_AD_04,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_AD_04,value= 0,side= 1
	CheckBox Check_AD_05,pos={20,307},size={24,14},disable=1,title="5"
	CheckBox Check_AD_05,userdata(tabnum)=  "2",userdata(tabcontrol)=  "ADC"
	CheckBox Check_AD_05,userdata(ResizeControlsInfo)= A"!!,B)!!#BF!!#>6!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_AD_05,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_AD_05,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_AD_05,value= 0,side= 1
	CheckBox Check_AD_06,pos={20,353},size={24,14},disable=1,title="6"
	CheckBox Check_AD_06,userdata(tabnum)=  "2",userdata(tabcontrol)=  "ADC"
	CheckBox Check_AD_06,userdata(ResizeControlsInfo)= A"!!,B)!!#B]J,hna!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_AD_06,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_AD_06,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_AD_06,value= 0,side= 1
	CheckBox Check_AD_07,pos={20,400},size={24,14},disable=1,title="7"
	CheckBox Check_AD_07,userdata(tabnum)=  "2",userdata(tabcontrol)=  "ADC"
	CheckBox Check_AD_07,userdata(ResizeControlsInfo)= A"!!,B)!!#Bu!!#>6!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_AD_07,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_AD_07,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_AD_07,value= 0,side= 1
	CheckBox Check_AD_08,pos={190,75},size={24,14},disable=1,title="8"
	CheckBox Check_AD_08,userdata(tabnum)=  "2",userdata(tabcontrol)=  "ADC"
	CheckBox Check_AD_08,userdata(ResizeControlsInfo)= A"!!,G9!!#>F!!#>6!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_AD_08,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_AD_08,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_AD_08,value= 0,side= 1
	CheckBox Check_AD_09,pos={190,121},size={24,14},disable=1,title="9"
	CheckBox Check_AD_09,userdata(tabnum)=  "2",userdata(tabcontrol)=  "ADC"
	CheckBox Check_AD_09,userdata(ResizeControlsInfo)= A"!!,G9!!#?s!!#>6!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_AD_09,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_AD_09,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_AD_09,value= 0,side= 1
	CheckBox Check_AD_10,pos={184,167},size={30,14},disable=1,title="10"
	CheckBox Check_AD_10,userdata(tabnum)=  "2",userdata(tabcontrol)=  "ADC"
	CheckBox Check_AD_10,userdata(ResizeControlsInfo)= A"!!,G9!!#@p!!#>N!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_AD_10,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_AD_10,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_AD_10,value= 0,side= 1
	CheckBox Check_AD_12,pos={184,260},size={30,14},disable=1,title="12"
	CheckBox Check_AD_12,userdata(tabnum)=  "2",userdata(tabcontrol)=  "ADC"
	CheckBox Check_AD_12,userdata(ResizeControlsInfo)= A"!!,G9!!#B$!!#>N!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_AD_12,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_AD_12,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_AD_12,value= 0,side= 1
	CheckBox Check_AD_11,pos={184,214},size={30,14},disable=1,title="11"
	CheckBox Check_AD_11,userdata(tabnum)=  "2",userdata(tabcontrol)=  "ADC"
	CheckBox Check_AD_11,userdata(ResizeControlsInfo)= A"!!,G9!!#AJ!!#>N!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_AD_11,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_AD_11,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_AD_11,value= 0,side= 1
	SetVariable Gain_AD_00,pos={49,74},size={50,16},disable=1,help={"hello"}
	SetVariable Gain_AD_00,userdata(tabnum)=  "2",userdata(tabcontrol)=  "ADC"
	SetVariable Gain_AD_00,userdata(ResizeControlsInfo)= A"!!,EF!!#>>!!#?O!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Gain_AD_00,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Gain_AD_00,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Gain_AD_00,limits={0,inf,1},value= _NUM:0
	SetVariable Gain_AD_01,pos={49,120},size={50,16},disable=1
	SetVariable Gain_AD_01,userdata(tabnum)=  "2",userdata(tabcontrol)=  "ADC"
	SetVariable Gain_AD_01,userdata(ResizeControlsInfo)= A"!!,EF!!#?o!!#?O!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Gain_AD_01,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Gain_AD_01,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Gain_AD_01,limits={0,inf,1},value= _NUM:0
	SetVariable Gain_AD_02,pos={49,166},size={50,16},disable=1
	SetVariable Gain_AD_02,userdata(tabnum)=  "2",userdata(tabcontrol)=  "ADC"
	SetVariable Gain_AD_02,userdata(ResizeControlsInfo)= A"!!,EF!!#@n!!#?O!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Gain_AD_02,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Gain_AD_02,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Gain_AD_02,limits={0,inf,1},value= _NUM:0
	SetVariable Gain_AD_03,pos={49,212},size={50,16},disable=1
	SetVariable Gain_AD_03,userdata(tabnum)=  "2",userdata(tabcontrol)=  "ADC"
	SetVariable Gain_AD_03,userdata(ResizeControlsInfo)= A"!!,EF!!#AH!!#?O!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Gain_AD_03,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Gain_AD_03,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Gain_AD_03,limits={0,inf,1},value= _NUM:0
	SetVariable Gain_AD_04,pos={49,259},size={50,16},disable=1
	SetVariable Gain_AD_04,userdata(tabnum)=  "2",userdata(tabcontrol)=  "ADC"
	SetVariable Gain_AD_04,userdata(ResizeControlsInfo)= A"!!,EF!!#B\"!!#?O!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Gain_AD_04,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Gain_AD_04,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Gain_AD_04,limits={0,inf,1},value= _NUM:0
	SetVariable Gain_AD_05,pos={49,305},size={50,16},disable=1
	SetVariable Gain_AD_05,userdata(tabnum)=  "2",userdata(tabcontrol)=  "ADC"
	SetVariable Gain_AD_05,userdata(ResizeControlsInfo)= A"!!,EF!!#BEJ,hp%!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Gain_AD_05,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Gain_AD_05,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Gain_AD_05,limits={0,inf,1},value= _NUM:0
	SetVariable Gain_AD_06,pos={49,351},size={50,16},disable=1
	SetVariable Gain_AD_06,userdata(tabnum)=  "2",userdata(tabcontrol)=  "ADC"
	SetVariable Gain_AD_06,userdata(ResizeControlsInfo)= A"!!,EF!!#B]!!#?O!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Gain_AD_06,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Gain_AD_06,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Gain_AD_06,limits={0,inf,1},value= _NUM:0
	SetVariable Gain_AD_07,pos={49,398},size={50,16},disable=1
	SetVariable Gain_AD_07,userdata(tabnum)=  "2",userdata(tabcontrol)=  "ADC"
	SetVariable Gain_AD_07,userdata(ResizeControlsInfo)= A"!!,EF!!#BtJ,hp%!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Gain_AD_07,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Gain_AD_07,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Gain_AD_07,limits={0,inf,1},value= _NUM:0
	SetVariable Gain_AD_08,pos={218,74},size={50,16},disable=1
	SetVariable Gain_AD_08,userdata(tabnum)=  "2",userdata(tabcontrol)=  "ADC"
	SetVariable Gain_AD_08,userdata(ResizeControlsInfo)= A"!!,Gp!!#>B!!#?O!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Gain_AD_08,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Gain_AD_08,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Gain_AD_08,limits={0,inf,1},value= _NUM:0
	SetVariable Gain_AD_09,pos={218,120},size={50,16},disable=1
	SetVariable Gain_AD_09,userdata(tabnum)=  "2",userdata(tabcontrol)=  "ADC"
	SetVariable Gain_AD_09,userdata(ResizeControlsInfo)= A"!!,Gp!!#?q!!#?O!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Gain_AD_09,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Gain_AD_09,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Gain_AD_09,limits={0,inf,1},value= _NUM:0
	SetVariable Gain_AD_10,pos={218,166},size={50,16},disable=1
	SetVariable Gain_AD_10,userdata(tabnum)=  "2",userdata(tabcontrol)=  "ADC"
	SetVariable Gain_AD_10,userdata(ResizeControlsInfo)= A"!!,Gp!!#@o!!#?O!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Gain_AD_10,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Gain_AD_10,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Gain_AD_10,limits={0,inf,1},value= _NUM:0
	SetVariable Gain_AD_11,pos={218,212},size={50,16},disable=1
	SetVariable Gain_AD_11,userdata(tabnum)=  "2",userdata(tabcontrol)=  "ADC"
	SetVariable Gain_AD_11,userdata(ResizeControlsInfo)= A"!!,Gp!!#AI!!#?O!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Gain_AD_11,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Gain_AD_11,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Gain_AD_11,limits={0,inf,1},value= _NUM:0
	SetVariable Gain_AD_12,pos={218,259},size={50,16},disable=1
	SetVariable Gain_AD_12,userdata(tabnum)=  "2",userdata(tabcontrol)=  "ADC"
	SetVariable Gain_AD_12,userdata(ResizeControlsInfo)= A"!!,Gp!!#B#!!#?O!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Gain_AD_12,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Gain_AD_12,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Gain_AD_12,limits={0,inf,1},value= _NUM:0
	CheckBox Check_AD_13,pos={184,307},size={30,14},disable=1,title="13"
	CheckBox Check_AD_13,userdata(tabnum)=  "2",userdata(tabcontrol)=  "ADC"
	CheckBox Check_AD_13,userdata(ResizeControlsInfo)= A"!!,G9!!#BFJ,ho$!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_AD_13,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_AD_13,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_AD_13,value= 0,side= 1
	CheckBox Check_AD_14,pos={184,353},size={30,14},disable=1,title="14"
	CheckBox Check_AD_14,userdata(tabnum)=  "2",userdata(tabcontrol)=  "ADC"
	CheckBox Check_AD_14,userdata(ResizeControlsInfo)= A"!!,G9!!#B^!!#>N!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_AD_14,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_AD_14,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_AD_14,value= 0,side= 1
	CheckBox Check_AD_15,pos={184,400},size={30,14},disable=1,title="15"
	CheckBox Check_AD_15,userdata(tabnum)=  "2",userdata(tabcontrol)=  "ADC"
	CheckBox Check_AD_15,userdata(ResizeControlsInfo)= A"!!,G9!!#BuJ,ho$!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_AD_15,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_AD_15,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_AD_15,value= 0,side= 1
	SetVariable Gain_AD_13,pos={218,305},size={50,16},disable=1
	SetVariable Gain_AD_13,userdata(tabnum)=  "2",userdata(tabcontrol)=  "ADC"
	SetVariable Gain_AD_13,userdata(ResizeControlsInfo)= A"!!,Gp!!#BF!!#?O!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Gain_AD_13,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Gain_AD_13,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Gain_AD_13,limits={0,inf,1},value= _NUM:0
	SetVariable Gain_AD_14,pos={218,351},size={50,16},disable=1
	SetVariable Gain_AD_14,userdata(tabnum)=  "2",userdata(tabcontrol)=  "ADC"
	SetVariable Gain_AD_14,userdata(ResizeControlsInfo)= A"!!,Gp!!#B]J,hp%!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Gain_AD_14,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Gain_AD_14,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Gain_AD_14,limits={0,inf,1},value= _NUM:0
	SetVariable Gain_AD_15,pos={218,398},size={50,16},disable=1
	SetVariable Gain_AD_15,userdata(tabnum)=  "2",userdata(tabcontrol)=  "ADC"
	SetVariable Gain_AD_15,userdata(ResizeControlsInfo)= A"!!,Gp!!#Bu!!#?O!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Gain_AD_15,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Gain_AD_15,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Gain_AD_15,limits={0,inf,1},value= _NUM:0
	CheckBox Check_DA_00,pos={20,75},size={24,14},disable=1,proc=DAP_DAorTTLCheckProc,title="0"
	CheckBox Check_DA_00,help={"hello!"},userdata(tabnum)=  "1"
	CheckBox Check_DA_00,userdata(tabcontrol)=  "ADC"
	CheckBox Check_DA_00,userdata(ResizeControlsInfo)= A"!!,B)!!#?M!!#>6!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_DA_00,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_DA_00,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_DA_00,value= 0,side= 1
	CheckBox Check_DA_01,pos={20,120},size={24,14},disable=1,proc=DAP_DAorTTLCheckProc,title="1"
	CheckBox Check_DA_01,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	CheckBox Check_DA_01,userdata(ResizeControlsInfo)= A"!!,B)!!#@T!!#>6!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_DA_01,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_DA_01,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_DA_01,value= 0,side= 1
	CheckBox Check_DA_02,pos={20,167},size={24,14},disable=1,proc=DAP_DAorTTLCheckProc,title="2"
	CheckBox Check_DA_02,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	CheckBox Check_DA_02,userdata(ResizeControlsInfo)= A"!!,B)!!#A6!!#>6!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_DA_02,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_DA_02,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_DA_02,value= 0,side= 1
	CheckBox Check_DA_03,pos={20,213},size={24,14},disable=1,proc=DAP_DAorTTLCheckProc,title="3"
	CheckBox Check_DA_03,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	CheckBox Check_DA_03,userdata(ResizeControlsInfo)= A"!!,B)!!#Ae!!#>6!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_DA_03,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_DA_03,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_DA_03,value= 0,side= 1
	CheckBox Check_DA_04,pos={20,258},size={24,14},disable=1,proc=DAP_DAorTTLCheckProc,title="4"
	CheckBox Check_DA_04,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	CheckBox Check_DA_04,userdata(ResizeControlsInfo)= A"!!,B)!!#B<!!#>6!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_DA_04,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_DA_04,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_DA_04,value= 0,side= 1
	CheckBox Check_DA_05,pos={20,305},size={24,14},disable=1,proc=DAP_DAorTTLCheckProc,title="5"
	CheckBox Check_DA_05,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	CheckBox Check_DA_05,userdata(ResizeControlsInfo)= A"!!,B)!!#BSJ,hna!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_DA_05,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_DA_05,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_DA_05,value= 0,side= 1
	CheckBox Check_DA_06,pos={20,352},size={24,14},disable=1,proc=DAP_DAorTTLCheckProc,title="6"
	CheckBox Check_DA_06,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	CheckBox Check_DA_06,userdata(ResizeControlsInfo)= A"!!,B)!!#Bk!!#>6!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_DA_06,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_DA_06,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_DA_06,value= 0,side= 1
	CheckBox Check_DA_07,pos={20,399},size={24,14},disable=1,proc=DAP_DAorTTLCheckProc,title="7"
	CheckBox Check_DA_07,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	CheckBox Check_DA_07,userdata(ResizeControlsInfo)= A"!!,B)!!#C-J,hna!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_DA_07,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_DA_07,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_DA_07,value= 0,side= 1
	SetVariable Gain_DA_00,pos={47,75},size={40,16},disable=1,help={"hello"}
	SetVariable Gain_DA_00,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	SetVariable Gain_DA_00,userdata(ResizeControlsInfo)= A"!!,EF!!#?M!!#>.!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Gain_DA_00,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Gain_DA_00,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Gain_DA_00,limits={0,inf,1},value= _NUM:0
	SetVariable Gain_DA_01,pos={47,120},size={40,16},disable=1
	SetVariable Gain_DA_01,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	SetVariable Gain_DA_01,userdata(ResizeControlsInfo)= A"!!,EF!!#@T!!#>.!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Gain_DA_01,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Gain_DA_01,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Gain_DA_01,limits={0,inf,1},value= _NUM:0
	SetVariable Gain_DA_02,pos={47,167},size={40,16},disable=1
	SetVariable Gain_DA_02,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	SetVariable Gain_DA_02,userdata(ResizeControlsInfo)= A"!!,EF!!#A6!!#>.!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Gain_DA_02,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Gain_DA_02,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Gain_DA_02,limits={0,inf,1},value= _NUM:0
	SetVariable Gain_DA_03,pos={47,213},size={40,16},disable=1
	SetVariable Gain_DA_03,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	SetVariable Gain_DA_03,userdata(ResizeControlsInfo)= A"!!,EF!!#Ae!!#>.!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Gain_DA_03,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Gain_DA_03,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Gain_DA_03,limits={0,inf,1},value= _NUM:0
	SetVariable Gain_DA_04,pos={47,258},size={40,16},disable=1
	SetVariable Gain_DA_04,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	SetVariable Gain_DA_04,userdata(ResizeControlsInfo)= A"!!,EF!!#B<!!#>.!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Gain_DA_04,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Gain_DA_04,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Gain_DA_04,limits={0,inf,1},value= _NUM:0
	SetVariable Gain_DA_05,pos={47,305},size={40,16},disable=1
	SetVariable Gain_DA_05,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	SetVariable Gain_DA_05,userdata(ResizeControlsInfo)= A"!!,EF!!#BSJ,hnY!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Gain_DA_05,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Gain_DA_05,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Gain_DA_05,limits={0,inf,1},value= _NUM:0
	SetVariable Gain_DA_06,pos={47,352},size={40,16},disable=1
	SetVariable Gain_DA_06,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	SetVariable Gain_DA_06,userdata(ResizeControlsInfo)= A"!!,EF!!#Bk!!#>.!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Gain_DA_06,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Gain_DA_06,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Gain_DA_06,limits={0,inf,1},value= _NUM:0
	SetVariable Gain_DA_07,pos={47,399},size={40,16},disable=1
	SetVariable Gain_DA_07,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	SetVariable Gain_DA_07,userdata(ResizeControlsInfo)= A"!!,EF!!#C-J,hnY!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Gain_DA_07,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Gain_DA_07,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Gain_DA_07,limits={0,inf,1},value= _NUM:0
	PopupMenu Wave_DA_00,pos={123,73},size={143,21},bodyWidth=125,disable=1,proc=DAP_PopMenuChkProc_StimSetList,title="/V "
	PopupMenu Wave_DA_00,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	PopupMenu Wave_DA_00,userdata(ResizeControlsInfo)= A"!!,FI!!#?I!!#@^!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Wave_DA_00,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Wave_DA_00,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Wave_DA_00,fSize=7
	PopupMenu Wave_DA_00,mode=1,popvalue="- none -",value= #"\"- none -;TestPulse;\"+WBP_ITCPanelPopUps(0,\"*DA*\")"
	PopupMenu Wave_DA_01,pos={123,118},size={143,21},bodyWidth=125,disable=1,proc=DAP_PopMenuChkProc_StimSetList,title="/V "
	PopupMenu Wave_DA_01,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	PopupMenu Wave_DA_01,userdata(ResizeControlsInfo)= A"!!,FI!!#@P!!#@^!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Wave_DA_01,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Wave_DA_01,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Wave_DA_01,fSize=7
	PopupMenu Wave_DA_01,mode=1,popvalue="- none -",value= #"\"- none -;TestPulse;\"+WBP_ITCPanelPopUps(0,\"*da*\")"
	PopupMenu Wave_DA_02,pos={123,165},size={143,21},bodyWidth=125,disable=1,proc=DAP_PopMenuChkProc_StimSetList,title="/V "
	PopupMenu Wave_DA_02,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	PopupMenu Wave_DA_02,userdata(ResizeControlsInfo)= A"!!,FI!!#A4!!#@^!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Wave_DA_02,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Wave_DA_02,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Wave_DA_02,fSize=7
	PopupMenu Wave_DA_02,mode=1,popvalue="- none -",value= #"\"- none -;TestPulse;\"+WBP_ITCPanelPopUps(0,\"*da*\")"
	PopupMenu Wave_DA_03,pos={123,211},size={143,21},bodyWidth=125,disable=1,proc=DAP_PopMenuChkProc_StimSetList,title="/V "
	PopupMenu Wave_DA_03,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	PopupMenu Wave_DA_03,userdata(ResizeControlsInfo)= A"!!,FI!!#Ac!!#@^!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Wave_DA_03,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Wave_DA_03,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Wave_DA_03,fSize=7
	PopupMenu Wave_DA_03,mode=1,popvalue="- none -",value= #"\"- none -;TestPulse;\"+WBP_ITCPanelPopUps(0,\"*da*\")"
	PopupMenu Wave_DA_04,pos={123,256},size={143,21},bodyWidth=125,disable=1,proc=DAP_PopMenuChkProc_StimSetList,title="/V "
	PopupMenu Wave_DA_04,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	PopupMenu Wave_DA_04,userdata(ResizeControlsInfo)= A"!!,FI!!#B;!!#@^!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Wave_DA_04,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Wave_DA_04,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Wave_DA_04,fSize=7
	PopupMenu Wave_DA_04,mode=1,popvalue="- none -",value= #"\"- none -;TestPulse;\"+WBP_ITCPanelPopUps(0,\"*da*\")"
	PopupMenu Wave_DA_05,pos={123,303},size={143,21},bodyWidth=125,disable=1,proc=DAP_PopMenuChkProc_StimSetList,title="/V "
	PopupMenu Wave_DA_05,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	PopupMenu Wave_DA_05,userdata(ResizeControlsInfo)= A"!!,FI!!#BRJ,hq4!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Wave_DA_05,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Wave_DA_05,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Wave_DA_05,fSize=7
	PopupMenu Wave_DA_05,mode=1,popvalue="- none -",value= #"\"- none -;TestPulse;\"+WBP_ITCPanelPopUps(0,\"*da*\")"
	PopupMenu Wave_DA_06,pos={123,350},size={143,21},bodyWidth=125,disable=1,proc=DAP_PopMenuChkProc_StimSetList,title="/V "
	PopupMenu Wave_DA_06,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	PopupMenu Wave_DA_06,userdata(ResizeControlsInfo)= A"!!,FI!!#Bj!!#@^!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Wave_DA_06,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Wave_DA_06,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Wave_DA_06,fSize=7
	PopupMenu Wave_DA_06,mode=1,popvalue="- none -",value= #"\"- none -;TestPulse;\"+WBP_ITCPanelPopUps(0,\"*da*\")"
	PopupMenu Wave_DA_07,pos={123,397},size={143,21},bodyWidth=125,disable=1,proc=DAP_PopMenuChkProc_StimSetList,title="/V "
	PopupMenu Wave_DA_07,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	PopupMenu Wave_DA_07,userdata(ResizeControlsInfo)= A"!!,FI!!#C,J,hq4!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Wave_DA_07,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Wave_DA_07,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Wave_DA_07,fSize=7
	PopupMenu Wave_DA_07,mode=1,popvalue="- none -",value= #"\"- none -;TestPulse;\"+WBP_ITCPanelPopUps(0,\"*da*\")"
	SetVariable Scale_DA_00,pos={272,75},size={40,16},disable=1
	SetVariable Scale_DA_00,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	SetVariable Scale_DA_00,userdata(ResizeControlsInfo)= A"!!,H0!!#?M!!#>.!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Scale_DA_00,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Scale_DA_00,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Scale_DA_00,limits={-inf,inf,10},value= _NUM:1
	SetVariable Scale_DA_01,pos={272,120},size={40,16},disable=1
	SetVariable Scale_DA_01,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	SetVariable Scale_DA_01,userdata(ResizeControlsInfo)= A"!!,H0!!#@T!!#>.!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Scale_DA_01,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Scale_DA_01,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Scale_DA_01,limits={-inf,inf,10},value= _NUM:1
	SetVariable Scale_DA_02,pos={272,167},size={40,16},disable=1
	SetVariable Scale_DA_02,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	SetVariable Scale_DA_02,userdata(ResizeControlsInfo)= A"!!,H0!!#A6!!#>.!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Scale_DA_02,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Scale_DA_02,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Scale_DA_02,limits={-inf,inf,10},value= _NUM:1
	SetVariable Scale_DA_03,pos={272,213},size={40,16},disable=1
	SetVariable Scale_DA_03,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	SetVariable Scale_DA_03,userdata(ResizeControlsInfo)= A"!!,H0!!#Ae!!#>.!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Scale_DA_03,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Scale_DA_03,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Scale_DA_03,limits={-inf,inf,10},value= _NUM:1
	SetVariable Scale_DA_04,pos={272,258},size={40,16},disable=1
	SetVariable Scale_DA_04,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	SetVariable Scale_DA_04,userdata(ResizeControlsInfo)= A"!!,H0!!#B<!!#>.!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Scale_DA_04,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Scale_DA_04,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Scale_DA_04,value= _NUM:1
	SetVariable Scale_DA_05,pos={272,305},size={40,16},disable=1
	SetVariable Scale_DA_05,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	SetVariable Scale_DA_05,userdata(ResizeControlsInfo)= A"!!,H0!!#BSJ,hnY!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Scale_DA_05,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Scale_DA_05,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Scale_DA_05,value= _NUM:1
	SetVariable Scale_DA_06,pos={272,352},size={40,16},disable=1
	SetVariable Scale_DA_06,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	SetVariable Scale_DA_06,userdata(ResizeControlsInfo)= A"!!,H0!!#Bk!!#>.!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Scale_DA_06,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Scale_DA_06,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Scale_DA_06,limits={-inf,inf,10},value= _NUM:1
	SetVariable Scale_DA_07,pos={272,399},size={40,16},bodyWidth=40,disable=1
	SetVariable Scale_DA_07,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	SetVariable Scale_DA_07,userdata(ResizeControlsInfo)= A"!!,H0!!#C-J,hnY!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Scale_DA_07,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Scale_DA_07,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Scale_DA_07,limits={-inf,inf,10},value= _NUM:1
	SetVariable SetVar_DataAcq_Comment,pos={47,692},size={362,16},disable=1,title="Comment"
	SetVariable SetVar_DataAcq_Comment,help={"Appends a comment to wave note of next sweep"}
	SetVariable SetVar_DataAcq_Comment,userdata(tabnum)=  "0"
	SetVariable SetVar_DataAcq_Comment,userdata(tabcontrol)=  "ADC"
	SetVariable SetVar_DataAcq_Comment,userdata(ResizeControlsInfo)= A"!!,Cp!!#C-J,hsP!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_DataAcq_Comment,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_DataAcq_Comment,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_DataAcq_Comment,fSize=8,value= _STR:""
	Button DataAcquireButton,pos={44,711},size={395,42},disable=1,proc=DAP_ButtonProc_AcquireData,title="\\Z14\\f01Acquire\rData"
	Button DataAcquireButton,userdata(tabnum)=  "0",userdata(tabcontrol)=  "ADC"
	Button DataAcquireButton,userdata(ResizeControlsInfo)= A"!!,Ch!!#C6J,hsRJ,ho(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button DataAcquireButton,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button DataAcquireButton,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	Button DataAcquireButton,labelBack=(60928,60928,60928)
	CheckBox Check_DataAcq1_RepeatAcq,pos={38,603},size={119,14},disable=1,proc=DAP_CheckProc_RepeatedAcq,title="Repeated Acquisition"
	CheckBox Check_DataAcq1_RepeatAcq,help={"Determines number of times a set is repeated, or if indexing is on, the number of times a group of sets in repeated"}
	CheckBox Check_DataAcq1_RepeatAcq,userdata(tabnum)=  "0"
	CheckBox Check_DataAcq1_RepeatAcq,userdata(tabcontrol)=  "ADC"
	CheckBox Check_DataAcq1_RepeatAcq,userdata(ResizeControlsInfo)= A"!!,D'!!#Bb!!#@R!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_DataAcq1_RepeatAcq,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_DataAcq1_RepeatAcq,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_DataAcq1_RepeatAcq,value= 0
	SetVariable SetVar_DataAcq_ITI,pos={87,659},size={77,16},bodyWidth=35,disable=3,proc=DAP_SetVarProc_ITI,title="\\JCITl (sec)"
	SetVariable SetVar_DataAcq_ITI,userdata(tabnum)=  "0"
	SetVariable SetVar_DataAcq_ITI,userdata(tabcontrol)=  "ADC"
	SetVariable SetVar_DataAcq_ITI,userdata(ResizeControlsInfo)= A"!!,GT!!#B\\!!#@6!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_DataAcq_ITI,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_DataAcq_ITI,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_DataAcq_ITI,limits={0,inf,1},value= _NUM:0
	Button StartTestPulseButton,pos={51,404},size={384,40},disable=1,proc=DAP_ButtonProc_TestPulse,title="\\Z14\\f01Start Test \rPulse"
	Button StartTestPulseButton,help={"Starts generating test pulses. Can be stopped by pressing space bar."}
	Button StartTestPulseButton,userdata(tabnum)=  "0",userdata(tabcontrol)=  "ADC"
	Button StartTestPulseButton,userdata(ResizeControlsInfo)= A"!!,Cp!!#B3!!#C%!!#>Nz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button StartTestPulseButton,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button StartTestPulseButton,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_DataAcq_HS_00,pos={145,86},size={24,14},disable=1,proc=DAP_CheckProc_HedstgeChck,title="0"
	CheckBox Check_DataAcq_HS_00,userdata(tabnum)=  "0",userdata(tabcontrol)=  "ADC"
	CheckBox Check_DataAcq_HS_00,userdata(ResizeControlsInfo)= A"!!,G$!!#?e!!#=#!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_DataAcq_HS_00,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_DataAcq_HS_00,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_DataAcq_HS_00,labelBack=(65280,0,0),value= 0
	SetVariable SetVar_DataAcq_TPDuration,pos={66,384},size={110,16},disable=1,proc=DAP_SetVarProc_TPDuration,title="Duration (ms)"
	SetVariable SetVar_DataAcq_TPDuration,userdata(tabnum)=  "0"
	SetVariable SetVar_DataAcq_TPDuration,userdata(tabcontrol)=  "ADC"
	SetVariable SetVar_DataAcq_TPDuration,userdata(ResizeControlsInfo)= A"!!,F)!!#Aq!!#@@!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_DataAcq_TPDuration,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_DataAcq_TPDuration,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_DataAcq_TPDuration,limits={1,inf,5},value= _NUM:10
	SetVariable SetVar_DataAcq_TPAmplitude,pos={194,384},size={100,16},disable=1,title="Amplitude VC"
	SetVariable SetVar_DataAcq_TPAmplitude,userdata(tabnum)=  "0"
	SetVariable SetVar_DataAcq_TPAmplitude,userdata(tabcontrol)=  "ADC"
	SetVariable SetVar_DataAcq_TPAmplitude,userdata(ResizeControlsInfo)= A"!!,Ge!!#Aq!!#@@!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_DataAcq_TPAmplitude,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_DataAcq_TPAmplitude,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_DataAcq_TPAmplitude,value= _NUM:10
	CheckBox Check_TTL_00,pos={24,72},size={47,14},disable=1,proc=DAP_DAorTTLCheckProc,title="TTL 0"
	CheckBox Check_TTL_00,userdata(tabnum)=  "3",userdata(tabcontrol)=  "ADC"
	CheckBox Check_TTL_00,userdata(ResizeControlsInfo)= A"!!,C$!!#?I!!#>J!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_TTL_00,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_TTL_00,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_TTL_00,value= 0
	CheckBox Check_TTL_01,pos={24,118},size={47,14},disable=1,proc=DAP_DAorTTLCheckProc,title="TTL 1"
	CheckBox Check_TTL_01,userdata(tabnum)=  "3",userdata(tabcontrol)=  "ADC"
	CheckBox Check_TTL_01,userdata(ResizeControlsInfo)= A"!!,C$!!#@P!!#>J!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_TTL_01,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_TTL_01,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_TTL_01,value= 0
	CheckBox Check_TTL_02,pos={24,164},size={47,14},disable=1,proc=DAP_DAorTTLCheckProc,title="TTL 2"
	CheckBox Check_TTL_02,userdata(tabnum)=  "3",userdata(tabcontrol)=  "ADC"
	CheckBox Check_TTL_02,userdata(ResizeControlsInfo)= A"!!,C$!!#A3!!#>J!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_TTL_02,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_TTL_02,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_TTL_02,value= 0
	CheckBox Check_TTL_03,pos={24,210},size={47,14},disable=1,proc=DAP_DAorTTLCheckProc,title="TTL 3"
	CheckBox Check_TTL_03,userdata(tabnum)=  "3",userdata(tabcontrol)=  "ADC"
	CheckBox Check_TTL_03,userdata(ResizeControlsInfo)= A"!!,C$!!#Aa!!#>J!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_TTL_03,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_TTL_03,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_TTL_03,value= 0
	CheckBox Check_TTL_04,pos={24,256},size={47,14},disable=1,proc=DAP_DAorTTLCheckProc,title="TTL 4"
	CheckBox Check_TTL_04,userdata(tabnum)=  "3",userdata(tabcontrol)=  "ADC"
	CheckBox Check_TTL_04,userdata(ResizeControlsInfo)= A"!!,C$!!#B:!!#>J!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_TTL_04,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_TTL_04,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_TTL_04,value= 0
	CheckBox Check_TTL_05,pos={24,302},size={47,14},disable=1,proc=DAP_DAorTTLCheckProc,title="TTL 5"
	CheckBox Check_TTL_05,userdata(tabnum)=  "3",userdata(tabcontrol)=  "ADC"
	CheckBox Check_TTL_05,userdata(ResizeControlsInfo)= A"!!,C$!!#BQ!!#>J!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_TTL_05,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_TTL_05,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_TTL_05,value= 0
	CheckBox Check_TTL_06,pos={24,348},size={47,14},disable=1,proc=DAP_DAorTTLCheckProc,title="TTL 6"
	CheckBox Check_TTL_06,userdata(tabnum)=  "3",userdata(tabcontrol)=  "ADC"
	CheckBox Check_TTL_06,userdata(ResizeControlsInfo)= A"!!,C$!!#Bh!!#>J!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_TTL_06,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_TTL_06,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_TTL_06,value= 0
	CheckBox Check_TTL_07,pos={24,395},size={47,14},disable=1,proc=DAP_DAorTTLCheckProc,title="TTL 7"
	CheckBox Check_TTL_07,userdata(tabnum)=  "3",userdata(tabcontrol)=  "ADC"
	CheckBox Check_TTL_07,userdata(ResizeControlsInfo)= A"!!,C$!!#C*J,hnu!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_TTL_07,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_TTL_07,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_TTL_07,value= 0
	PopupMenu Wave_TTL_00,pos={103,69},size={125,21},bodyWidth=125,disable=1,proc=DAP_PopMenuChkProc_StimSetList
	PopupMenu Wave_TTL_00,userdata(tabnum)=  "3",userdata(tabcontrol)=  "ADC"
	PopupMenu Wave_TTL_00,userdata(ResizeControlsInfo)= A"!!,F3!!#?C!!#@^!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Wave_TTL_00,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Wave_TTL_00,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Wave_TTL_00,mode=1,popvalue="- none -",value= #"\"- none -;\"+WBP_ITCPanelPopUps(1,\"*TTL*\")"
	PopupMenu Wave_TTL_01,pos={103,115},size={125,21},bodyWidth=125,disable=1,proc=DAP_PopMenuChkProc_StimSetList
	PopupMenu Wave_TTL_01,userdata(tabnum)=  "3",userdata(tabcontrol)=  "ADC"
	PopupMenu Wave_TTL_01,userdata(ResizeControlsInfo)= A"!!,F3!!#@J!!#@^!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Wave_TTL_01,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Wave_TTL_01,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Wave_TTL_01,mode=1,popvalue="- none -",value= #"\"- none -;\"+WBP_ITCPanelPopUps(1,\"*TTL*\")"
	PopupMenu Wave_TTL_02,pos={103,161},size={125,21},bodyWidth=125,disable=1,proc=DAP_PopMenuChkProc_StimSetList
	PopupMenu Wave_TTL_02,userdata(tabnum)=  "3",userdata(tabcontrol)=  "ADC"
	PopupMenu Wave_TTL_02,userdata(ResizeControlsInfo)= A"!!,F3!!#A0!!#@^!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Wave_TTL_02,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Wave_TTL_02,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Wave_TTL_02,mode=1,popvalue="- none -",value= #"\"- none -;\"+WBP_ITCPanelPopUps(1,\"*TTL*\")"
	PopupMenu Wave_TTL_03,pos={103,207},size={125,21},bodyWidth=125,disable=1,proc=DAP_PopMenuChkProc_StimSetList
	PopupMenu Wave_TTL_03,userdata(tabnum)=  "3",userdata(tabcontrol)=  "ADC"
	PopupMenu Wave_TTL_03,userdata(ResizeControlsInfo)= A"!!,F3!!#A^!!#@^!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Wave_TTL_03,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Wave_TTL_03,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Wave_TTL_03,mode=1,popvalue="- none -",value= #"\"- none -;\"+WBP_ITCPanelPopUps(1,\"*TTL*\")"
	PopupMenu Wave_TTL_04,pos={103,253},size={125,21},bodyWidth=125,disable=1,proc=DAP_PopMenuChkProc_StimSetList
	PopupMenu Wave_TTL_04,userdata(tabnum)=  "3",userdata(tabcontrol)=  "ADC"
	PopupMenu Wave_TTL_04,userdata(ResizeControlsInfo)= A"!!,F3!!#B7!!#@^!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Wave_TTL_04,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Wave_TTL_04,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Wave_TTL_04,mode=1,popvalue="- none -",value= #"\"- none -;\"+WBP_ITCPanelPopUps(1,\"*TTL*\")"
	PopupMenu Wave_TTL_05,pos={103,299},size={125,21},bodyWidth=125,disable=1,proc=DAP_PopMenuChkProc_StimSetList
	PopupMenu Wave_TTL_05,userdata(tabnum)=  "3",userdata(tabcontrol)=  "ADC"
	PopupMenu Wave_TTL_05,userdata(ResizeControlsInfo)= A"!!,F3!!#BOJ,hq4!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Wave_TTL_05,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Wave_TTL_05,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Wave_TTL_05,mode=1,popvalue="- none -",value= #"\"- none -;\"+WBP_ITCPanelPopUps(1,\"*TTL*\")"
	PopupMenu Wave_TTL_06,pos={103,345},size={125,21},bodyWidth=125,disable=1,proc=DAP_PopMenuChkProc_StimSetList
	PopupMenu Wave_TTL_06,userdata(tabnum)=  "3",userdata(tabcontrol)=  "ADC"
	PopupMenu Wave_TTL_06,userdata(ResizeControlsInfo)= A"!!,F3!!#BfJ,hq4!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Wave_TTL_06,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Wave_TTL_06,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Wave_TTL_06,mode=1,popvalue="- none -",value= #"\"- none -;\"+WBP_ITCPanelPopUps(1,\"*TTL*\")"
	PopupMenu Wave_TTL_07,pos={103,392},size={125,21},bodyWidth=125,disable=1,proc=DAP_PopMenuChkProc_StimSetList
	PopupMenu Wave_TTL_07,userdata(tabnum)=  "3",userdata(tabcontrol)=  "ADC"
	PopupMenu Wave_TTL_07,userdata(ResizeControlsInfo)= A"!!,F3!!#C)!!#@^!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Wave_TTL_07,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Wave_TTL_07,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Wave_TTL_07,mode=1,popvalue="- none -",value= #"\"- none -;\"+WBP_ITCPanelPopUps(1,\"*TTL*\")"
	CheckBox Check_Settings_TrigOut,pos={34,258},size={56,14},disable=1,title="\\JCTrig Out"
	CheckBox Check_Settings_TrigOut,help={"Turns on TTL pulse at onset of sweep"}
	CheckBox Check_Settings_TrigOut,userdata(tabnum)=  "5"
	CheckBox Check_Settings_TrigOut,userdata(tabcontrol)=  "ADC"
	CheckBox Check_Settings_TrigOut,userdata(ResizeControlsInfo)= A"!!,H&!!#>n!!#>n!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_Settings_TrigOut,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_Settings_TrigOut,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_Settings_TrigOut,fColor=(65280,43520,0),value= 0
	CheckBox Check_Settings_TrigIn,pos={34,277},size={48,14},disable=1,title="\\JCTrig In"
	CheckBox Check_Settings_TrigIn,help={"Starts Data Aquisition with TTL signal to trig in port on rack"}
	CheckBox Check_Settings_TrigIn,userdata(tabnum)=  "5"
	CheckBox Check_Settings_TrigIn,userdata(tabcontrol)=  "ADC"
	CheckBox Check_Settings_TrigIn,userdata(ResizeControlsInfo)= A"!!,H&!!#?K!!#>N!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_Settings_TrigIn,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_Settings_TrigIn,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_Settings_TrigIn,fColor=(65280,43520,0),value= 0
	SetVariable SetVar_DataAcq_SetRepeats,pos={60,639},size={104,16},bodyWidth=35,disable=1,proc=DAP_SetVarProc_TotSweepCount,title="Repeat Set(s)"
	SetVariable SetVar_DataAcq_SetRepeats,help={"This number is set automatically at based on the number of 1d waves contained in the largest set on active DA/TTL channels"}
	SetVariable SetVar_DataAcq_SetRepeats,userdata(tabnum)=  "0"
	SetVariable SetVar_DataAcq_SetRepeats,userdata(tabcontrol)=  "ADC"
	SetVariable SetVar_DataAcq_SetRepeats,userdata(ResizeControlsInfo)= A"!!,GX!!#BlJ,hpW!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_DataAcq_SetRepeats,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_DataAcq_SetRepeats,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_DataAcq_SetRepeats,limits={1,inf,1},value= _NUM:1
	ValDisplay ValDisp_DataAcq_SamplingInt,pos={218,538},size={30,17},bodyWidth=30,disable=1
	ValDisplay ValDisp_DataAcq_SamplingInt,userdata(tabnum)=  "0"
	ValDisplay ValDisp_DataAcq_SamplingInt,userdata(tabcontrol)=  "ADC"
	ValDisplay ValDisp_DataAcq_SamplingInt,userdata(ResizeControlsInfo)= A"!!,H>J,hqh!!#@,!!#=3z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	ValDisplay ValDisp_DataAcq_SamplingInt,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	ValDisplay ValDisp_DataAcq_SamplingInt,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	ValDisplay ValDisp_DataAcq_SamplingInt,fSize=14,fStyle=0
	ValDisplay ValDisp_DataAcq_SamplingInt,valueColor=(65535,65535,65535)
	ValDisplay ValDisp_DataAcq_SamplingInt,valueBackColor=(0,0,0)
	ValDisplay ValDisp_DataAcq_SamplingInt,limits={0,0,0},barmisc={0,1000}
	ValDisplay ValDisp_DataAcq_SamplingInt,value= _NUM:0
	SetVariable SetVar_Sweep,pos={200,496},size={75,32},bodyWidth=75,disable=1,proc=DAP_SetVarProc_NextSweepLimit
	SetVariable SetVar_Sweep,userdata(tabnum)=  "0",userdata(tabcontrol)=  "ADC"
	SetVariable SetVar_Sweep,userdata(ResizeControlsInfo)= A"!!,DW!!#A<!!#AO!!#=Cz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_Sweep,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_Sweep,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_Sweep,fSize=24,fStyle=1,valueColor=(65535,65535,65535)
	SetVariable SetVar_Sweep,valueBackColor=(0,0,0),limits={0,0,1},value= _NUM:0
	CheckBox Check_Settings_SaveData,pos={34,237},size={106,14},disable=1,proc=DAP_CheckProc_SaveData,title="Do Not Save Data"
	CheckBox Check_Settings_SaveData,help={"Use cautiously - intended primarily for software development"}
	CheckBox Check_Settings_SaveData,userdata(tabnum)=  "5"
	CheckBox Check_Settings_SaveData,userdata(tabcontrol)=  "ADC"
	CheckBox Check_Settings_SaveData,userdata(ResizeControlsInfo)= A"!!,HT!!#?-!!#?C!!#=3z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_Settings_SaveData,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_Settings_SaveData,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_Settings_SaveData,value= 0
	CheckBox Check_Settings_UseDoublePrec,pos={243,236},size={151,14},disable=1,title="Use Double Precision Floats"
	CheckBox Check_Settings_UseDoublePrec,help={"Enable the saving of the raw data in double precision. If unchecked the raw data will be saved in single precision, which should be good enough for most use cases"}
	CheckBox Check_Settings_UseDoublePrec,userdata(tabnum)=  "5"
	CheckBox Check_Settings_UseDoublePrec,userdata(tabcontrol)=  "ADC"
	CheckBox Check_Settings_UseDoublePrec,userdata(ResizeControlsInfo)= A"!!,HT!!#?-!!#?C!!#=3z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_Settings_UseDoublePrec,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_Settings_UseDoublePrec,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_Settings_UseDoublePrec,value= 0
	CheckBox Check_AsyncAD_00,pos={172,46},size={42,14},disable=1,title="AD 0"
	CheckBox Check_AsyncAD_00,help={"hello!"},userdata(tabnum)=  "4"
	CheckBox Check_AsyncAD_00,userdata(tabcontrol)=  "ADC"
	CheckBox Check_AsyncAD_00,userdata(ResizeControlsInfo)= A"!!,G<!!#>F!!#>6!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_AsyncAD_00,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_AsyncAD_00,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_AsyncAD_00,value= 0
	CheckBox Check_AsyncAD_01,pos={171,97},size={42,14},disable=1,title="AD 1"
	CheckBox Check_AsyncAD_01,userdata(tabnum)=  "4",userdata(tabcontrol)=  "ADC"
	CheckBox Check_AsyncAD_01,userdata(ResizeControlsInfo)= A"!!,G;!!#@&!!#>6!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_AsyncAD_01,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_AsyncAD_01,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_AsyncAD_01,value= 0
	CheckBox Check_AsyncAD_02,pos={171,148},size={42,14},disable=1,title="AD 2"
	CheckBox Check_AsyncAD_02,userdata(tabnum)=  "4",userdata(tabcontrol)=  "ADC"
	CheckBox Check_AsyncAD_02,userdata(ResizeControlsInfo)= A"!!,G;!!#A#!!#>6!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_AsyncAD_02,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_AsyncAD_02,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_AsyncAD_02,value= 0
	CheckBox Check_AsyncAD_03,pos={171,199},size={42,14},disable=1,title="AD 3"
	CheckBox Check_AsyncAD_03,userdata(tabnum)=  "4",userdata(tabcontrol)=  "ADC"
	CheckBox Check_AsyncAD_03,userdata(ResizeControlsInfo)= A"!!,G;!!#AV!!#>6!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_AsyncAD_03,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_AsyncAD_03,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_AsyncAD_03,value= 0
	CheckBox Check_AsyncAD_04,pos={171,250},size={42,14},disable=1,title="AD 4"
	CheckBox Check_AsyncAD_04,userdata(tabnum)=  "4",userdata(tabcontrol)=  "ADC"
	CheckBox Check_AsyncAD_04,userdata(ResizeControlsInfo)= A"!!,G;!!#B4!!#>6!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_AsyncAD_04,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_AsyncAD_04,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_AsyncAD_04,value= 0
	CheckBox Check_AsyncAD_05,pos={171,301},size={42,14},disable=1,title="AD 5"
	CheckBox Check_AsyncAD_05,userdata(tabnum)=  "4",userdata(tabcontrol)=  "ADC"
	CheckBox Check_AsyncAD_05,userdata(ResizeControlsInfo)= A"!!,G;!!#BPJ,hna!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_AsyncAD_05,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_AsyncAD_05,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_AsyncAD_05,value= 0
	CheckBox Check_AsyncAD_06,pos={171,352},size={42,14},disable=1,title="AD 6"
	CheckBox Check_AsyncAD_06,userdata(tabnum)=  "4",userdata(tabcontrol)=  "ADC"
	CheckBox Check_AsyncAD_06,userdata(ResizeControlsInfo)= A"!!,G;!!#Bj!!#>6!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_AsyncAD_06,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_AsyncAD_06,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_AsyncAD_06,value= 0
	CheckBox Check_AsyncAD_07,pos={171,404},size={42,14},disable=1,title="AD 7"
	CheckBox Check_AsyncAD_07,userdata(tabnum)=  "4",userdata(tabcontrol)=  "ADC"
	CheckBox Check_AsyncAD_07,userdata(ResizeControlsInfo)= A"!!,G;!!#C/!!#>6!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_AsyncAD_07,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_AsyncAD_07,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_AsyncAD_07,value= 0
	SetVariable SetVar_AsyncAD_Gain_00,pos={226,44},size={75,16},disable=1,title="gain"
	SetVariable SetVar_AsyncAD_Gain_00,help={"hello"},userdata(tabnum)=  "4"
	SetVariable SetVar_AsyncAD_Gain_00,userdata(tabcontrol)=  "ADC"
	SetVariable SetVar_AsyncAD_Gain_00,userdata(ResizeControlsInfo)= A"!!,Gr!!#>>!!#?O!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_AsyncAD_Gain_00,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_AsyncAD_Gain_00,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_AsyncAD_Gain_00,limits={0,inf,1},value= _NUM:1
	SetVariable SetVar_AsyncAD_Gain_01,pos={226,95},size={75,16},disable=1,title="gain"
	SetVariable SetVar_AsyncAD_Gain_01,userdata(tabnum)=  "4"
	SetVariable SetVar_AsyncAD_Gain_01,userdata(tabcontrol)=  "ADC"
	SetVariable SetVar_AsyncAD_Gain_01,userdata(ResizeControlsInfo)= A"!!,Gr!!#@\"!!#?O!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_AsyncAD_Gain_01,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_AsyncAD_Gain_01,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_AsyncAD_Gain_01,limits={0,inf,1},value= _NUM:1
	SetVariable SetVar_AsyncAD_Gain_02,pos={226,146},size={75,16},disable=1,title="gain"
	SetVariable SetVar_AsyncAD_Gain_02,userdata(tabnum)=  "4"
	SetVariable SetVar_AsyncAD_Gain_02,userdata(tabcontrol)=  "ADC"
	SetVariable SetVar_AsyncAD_Gain_02,userdata(ResizeControlsInfo)= A"!!,Gr!!#A!!!#?O!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_AsyncAD_Gain_02,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_AsyncAD_Gain_02,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_AsyncAD_Gain_02,limits={0,inf,1},value= _NUM:1
	SetVariable SetVar_AsyncAD_Gain_03,pos={226,197},size={75,16},disable=1,title="gain"
	SetVariable SetVar_AsyncAD_Gain_03,userdata(tabnum)=  "4"
	SetVariable SetVar_AsyncAD_Gain_03,userdata(tabcontrol)=  "ADC"
	SetVariable SetVar_AsyncAD_Gain_03,userdata(ResizeControlsInfo)= A"!!,Gr!!#AT!!#?O!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_AsyncAD_Gain_03,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_AsyncAD_Gain_03,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_AsyncAD_Gain_03,limits={0,inf,1},value= _NUM:1
	SetVariable SetVar_AsyncAD_Gain_04,pos={226,248},size={75,16},disable=1,title="gain"
	SetVariable SetVar_AsyncAD_Gain_04,userdata(tabnum)=  "4"
	SetVariable SetVar_AsyncAD_Gain_04,userdata(tabcontrol)=  "ADC"
	SetVariable SetVar_AsyncAD_Gain_04,userdata(ResizeControlsInfo)= A"!!,Gr!!#B2!!#?O!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_AsyncAD_Gain_04,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_AsyncAD_Gain_04,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_AsyncAD_Gain_04,limits={0,inf,1},value= _NUM:1
	SetVariable SetVar_AsyncAD_Gain_05,pos={226,299},size={75,16},disable=1,title="gain"
	SetVariable SetVar_AsyncAD_Gain_05,userdata(tabnum)=  "4"
	SetVariable SetVar_AsyncAD_Gain_05,userdata(tabcontrol)=  "ADC"
	SetVariable SetVar_AsyncAD_Gain_05,userdata(ResizeControlsInfo)= A"!!,Gr!!#BOJ,hp%!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_AsyncAD_Gain_05,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_AsyncAD_Gain_05,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_AsyncAD_Gain_05,limits={0,inf,1},value= _NUM:1
	SetVariable SetVar_AsyncAD_Gain_06,pos={226,350},size={75,16},disable=1,title="gain"
	SetVariable SetVar_AsyncAD_Gain_06,userdata(tabnum)=  "4"
	SetVariable SetVar_AsyncAD_Gain_06,userdata(tabcontrol)=  "ADC"
	SetVariable SetVar_AsyncAD_Gain_06,userdata(ResizeControlsInfo)= A"!!,Gr!!#Bi!!#?O!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_AsyncAD_Gain_06,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_AsyncAD_Gain_06,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_AsyncAD_Gain_06,limits={0,inf,1},value= _NUM:1
	SetVariable SetVar_AsyncAD_Gain_07,pos={226,402},size={75,16},disable=1,title="gain"
	SetVariable SetVar_AsyncAD_Gain_07,userdata(tabnum)=  "4"
	SetVariable SetVar_AsyncAD_Gain_07,userdata(tabcontrol)=  "ADC"
	SetVariable SetVar_AsyncAD_Gain_07,userdata(ResizeControlsInfo)= A"!!,Gr!!#C.!!#?O!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_AsyncAD_Gain_07,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_AsyncAD_Gain_07,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_AsyncAD_Gain_07,limits={0,inf,1},value= _NUM:1
	SetVariable SetVar_Async_Title_00,pos={14,44},size={150,16},disable=1,title="Title"
	SetVariable SetVar_Async_Title_00,userdata(tabnum)=  "4"
	SetVariable SetVar_Async_Title_00,userdata(tabcontrol)=  "ADC"
	SetVariable SetVar_Async_Title_00,userdata(ResizeControlsInfo)= A"!!,An!!#>>!!#A%!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_Async_Title_00,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_Async_Title_00,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_Async_Title_00,value= _STR:""
	SetVariable SetVar_Async_Title_01,pos={14,95},size={150,16},disable=1,title="Title"
	SetVariable SetVar_Async_Title_01,userdata(tabnum)=  "4"
	SetVariable SetVar_Async_Title_01,userdata(tabcontrol)=  "ADC"
	SetVariable SetVar_Async_Title_01,userdata(ResizeControlsInfo)= A"!!,An!!#@\"!!#A%!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_Async_Title_01,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_Async_Title_01,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_Async_Title_01,value= _STR:""
	SetVariable SetVar_Async_Title_02,pos={14,146},size={150,16},disable=1,title="Title"
	SetVariable SetVar_Async_Title_02,userdata(tabnum)=  "4"
	SetVariable SetVar_Async_Title_02,userdata(tabcontrol)=  "ADC"
	SetVariable SetVar_Async_Title_02,userdata(ResizeControlsInfo)= A"!!,An!!#A!!!#A%!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_Async_Title_02,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_Async_Title_02,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_Async_Title_02,value= _STR:""
	SetVariable SetVar_Async_Title_03,pos={14,197},size={150,16},disable=1,title="Title"
	SetVariable SetVar_Async_Title_03,userdata(tabnum)=  "4"
	SetVariable SetVar_Async_Title_03,userdata(tabcontrol)=  "ADC"
	SetVariable SetVar_Async_Title_03,userdata(ResizeControlsInfo)= A"!!,An!!#AT!!#A%!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_Async_Title_03,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_Async_Title_03,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_Async_Title_03,value= _STR:""
	SetVariable SetVar_Async_Title_04,pos={14,248},size={150,16},disable=1,title="Title"
	SetVariable SetVar_Async_Title_04,userdata(tabnum)=  "4"
	SetVariable SetVar_Async_Title_04,userdata(tabcontrol)=  "ADC"
	SetVariable SetVar_Async_Title_04,userdata(ResizeControlsInfo)= A"!!,An!!#B2!!#A%!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_Async_Title_04,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_Async_Title_04,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_Async_Title_04,value= _STR:""
	SetVariable SetVar_Async_Title_05,pos={14,299},size={150,16},disable=1,title="Title"
	SetVariable SetVar_Async_Title_05,userdata(tabnum)=  "4"
	SetVariable SetVar_Async_Title_05,userdata(tabcontrol)=  "ADC"
	SetVariable SetVar_Async_Title_05,userdata(ResizeControlsInfo)= A"!!,An!!#BOJ,hqP!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_Async_Title_05,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_Async_Title_05,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_Async_Title_05,value= _STR:""
	SetVariable SetVar_Async_Title_06,pos={14,350},size={150,16},disable=1,title="Title"
	SetVariable SetVar_Async_Title_06,userdata(tabnum)=  "4"
	SetVariable SetVar_Async_Title_06,userdata(tabcontrol)=  "ADC"
	SetVariable SetVar_Async_Title_06,userdata(ResizeControlsInfo)= A"!!,An!!#Bi!!#A%!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_Async_Title_06,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_Async_Title_06,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_Async_Title_06,value= _STR:""
	SetVariable SetVar_Async_Title_07,pos={14,402},size={150,16},disable=1,title="Title"
	SetVariable SetVar_Async_Title_07,userdata(tabnum)=  "4"
	SetVariable SetVar_Async_Title_07,userdata(tabcontrol)=  "ADC"
	SetVariable SetVar_Async_Title_07,userdata(ResizeControlsInfo)= A"!!,An!!#C.!!#A%!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_Async_Title_07,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_Async_Title_07,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_Async_Title_07,value= _STR:""
	SetVariable SetVar_Async_Unit_00,pos={315,44},size={75,16},disable=1,title="Unit"
	SetVariable SetVar_Async_Unit_00,userdata(tabnum)=  "4"
	SetVariable SetVar_Async_Unit_00,userdata(tabcontrol)=  "ADC"
	SetVariable SetVar_Async_Unit_00,userdata(ResizeControlsInfo)= A"!!,HXJ,hni!!#?O!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_Async_Unit_00,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_Async_Unit_00,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_Async_Unit_00,value= _STR:""
	SetVariable SetVar_Async_Unit_01,pos={315,95},size={75,16},disable=1,title="Unit"
	SetVariable SetVar_Async_Unit_01,userdata(tabnum)=  "4"
	SetVariable SetVar_Async_Unit_01,userdata(tabcontrol)=  "ADC"
	SetVariable SetVar_Async_Unit_01,userdata(ResizeControlsInfo)= A"!!,HXJ,hpM!!#?O!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_Async_Unit_01,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_Async_Unit_01,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_Async_Unit_01,value= _STR:""
	SetVariable SetVar_Async_Unit_02,pos={315,146},size={75,16},disable=1,title="Unit"
	SetVariable SetVar_Async_Unit_02,userdata(tabnum)=  "4"
	SetVariable SetVar_Async_Unit_02,userdata(tabcontrol)=  "ADC"
	SetVariable SetVar_Async_Unit_02,userdata(ResizeControlsInfo)= A"!!,HXJ,hqL!!#?O!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_Async_Unit_02,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_Async_Unit_02,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_Async_Unit_02,value= _STR:""
	SetVariable SetVar_Async_Unit_03,pos={315,197},size={75,16},disable=1,title="Unit"
	SetVariable SetVar_Async_Unit_03,userdata(tabnum)=  "4"
	SetVariable SetVar_Async_Unit_03,userdata(tabcontrol)=  "ADC"
	SetVariable SetVar_Async_Unit_03,userdata(ResizeControlsInfo)= A"!!,HXJ,hr*!!#?O!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_Async_Unit_03,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_Async_Unit_03,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_Async_Unit_03,value= _STR:""
	SetVariable SetVar_Async_Unit_04,pos={315,248},size={75,16},disable=1,title="Unit"
	SetVariable SetVar_Async_Unit_04,userdata(tabnum)=  "4"
	SetVariable SetVar_Async_Unit_04,userdata(tabcontrol)=  "ADC"
	SetVariable SetVar_Async_Unit_04,userdata(ResizeControlsInfo)= A"!!,HXJ,hr]!!#?O!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_Async_Unit_04,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_Async_Unit_04,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_Async_Unit_04,value= _STR:""
	SetVariable SetVar_Async_Unit_05,pos={315,299},size={75,16},disable=1,title="Unit"
	SetVariable SetVar_Async_Unit_05,userdata(tabnum)=  "4"
	SetVariable SetVar_Async_Unit_05,userdata(tabcontrol)=  "ADC"
	SetVariable SetVar_Async_Unit_05,userdata(ResizeControlsInfo)= A"!!,HXJ,hs%J,hp%!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_Async_Unit_05,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_Async_Unit_05,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_Async_Unit_05,value= _STR:""
	SetVariable SetVar_Async_Unit_06,pos={315,350},size={75,16},disable=1,title="Unit"
	SetVariable SetVar_Async_Unit_06,userdata(tabnum)=  "4"
	SetVariable SetVar_Async_Unit_06,userdata(tabcontrol)=  "ADC"
	SetVariable SetVar_Async_Unit_06,userdata(ResizeControlsInfo)= A"!!,HXJ,hs?!!#?O!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_Async_Unit_06,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_Async_Unit_06,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_Async_Unit_06,value= _STR:""
	SetVariable SetVar_Async_Unit_07,pos={315,402},size={75,16},disable=1,title="Unit"
	SetVariable SetVar_Async_Unit_07,userdata(tabnum)=  "4"
	SetVariable SetVar_Async_Unit_07,userdata(tabcontrol)=  "ADC"
	SetVariable SetVar_Async_Unit_07,userdata(ResizeControlsInfo)= A"!!,HXJ,hsY!!#?O!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_Async_Unit_07,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_Async_Unit_07,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_Async_Unit_07,value= _STR:""
	CheckBox Check_Settings_Append,pos={34,421},size={222,14},disable=1,title="\\JCAppend Asynchronus reading to wave note"
	CheckBox Check_Settings_Append,help={"Turns on TTL pulse at onset of sweep"}
	CheckBox Check_Settings_Append,userdata(tabnum)=  "5"
	CheckBox Check_Settings_Append,userdata(tabcontrol)=  "ADC"
	CheckBox Check_Settings_Append,userdata(ResizeControlsInfo)= A"!!,Ch!!#A-!!#Am!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_Settings_Append,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_Settings_Append,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_Settings_Append,value= 0
	CheckBox Check_Settings_BkgTP,pos={34,86},size={93,14},disable=1,title="Background TP"
	CheckBox Check_Settings_BkgTP,help={"Use cautiously - intended primarily for software development"}
	CheckBox Check_Settings_BkgTP,userdata(tabnum)=  "5"
	CheckBox Check_Settings_BkgTP,userdata(tabcontrol)=  "ADC"
	CheckBox Check_Settings_BkgTP,userdata(ResizeControlsInfo)= A"!!,Gn!!#?o!!#@e!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_Settings_BkgTP,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_Settings_BkgTP,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_Settings_BkgTP,value= 1
	CheckBox Check_Settings_BackgrndDataAcq,pos={34,193},size={156,14},disable=1,title="Background Data Acquisition"
	CheckBox Check_Settings_BackgrndDataAcq,help={"You may notice that onscreen update isn't as smooth with background data acquisition. This is normal and unavoidable."}
	CheckBox Check_Settings_BackgrndDataAcq,userdata(tabnum)=  "5"
	CheckBox Check_Settings_BackgrndDataAcq,userdata(tabcontrol)=  "ADC"
	CheckBox Check_Settings_BackgrndDataAcq,userdata(ResizeControlsInfo)= A"!!,Ch!!#?k!!#A+!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_Settings_BackgrndDataAcq,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_Settings_BackgrndDataAcq,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_Settings_BackgrndDataAcq,value= 1
	CheckBox Radio_ClampMode_0,pos={145,62},size={16,14},disable=1,proc=DAP_CheckProc_ClampMode,title=""
	CheckBox Radio_ClampMode_0,userdata(tabnum)=  "0",userdata(tabcontrol)=  "ADC"
	CheckBox Radio_ClampMode_0,userdata(ResizeControlsInfo)= A"!!,G$!!#?1!!#<8!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Radio_ClampMode_0,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Radio_ClampMode_0,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Radio_ClampMode_0,value= 1,mode=1
	TitleBox Title_DataAcq_VC,pos={62,65},size={68,13},disable=1,title="Voltage Clamp"
	TitleBox Title_DataAcq_VC,userdata(tabnum)=  "0",userdata(tabcontrol)=  "ADC"
	TitleBox Title_DataAcq_VC,userdata(ResizeControlsInfo)= A"!!,Ds!!#?;!!#?A!!#;]z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox Title_DataAcq_VC,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	TitleBox Title_DataAcq_VC,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	TitleBox Title_DataAcq_VC,frame=0
	TitleBox Title_DataAcq_IC,pos={62,109},size={66,13},disable=1,title="Current Clamp"
	TitleBox Title_DataAcq_IC,userdata(tabnum)=  "0",userdata(tabcontrol)=  "ADC"
	TitleBox Title_DataAcq_IC,userdata(ResizeControlsInfo)= A"!!,Ds!!#@>!!#?=!!#;]z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox Title_DataAcq_IC,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	TitleBox Title_DataAcq_IC,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	TitleBox Title_DataAcq_IC,frame=0
	TitleBox Title_DataAcq_CellSelection,pos={77,87},size={52,13},disable=1,title="Headstage"
	TitleBox Title_DataAcq_CellSelection,userdata(tabnum)=  "0"
	TitleBox Title_DataAcq_CellSelection,userdata(tabcontrol)=  "ADC"
	TitleBox Title_DataAcq_CellSelection,userdata(ResizeControlsInfo)= A"!!,EJ!!#?g!!#>^!!#;]z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox Title_DataAcq_CellSelection,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	TitleBox Title_DataAcq_CellSelection,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	TitleBox Title_DataAcq_CellSelection,frame=0
	CheckBox Check_DataAcq_HS_01,pos={178,86},size={24,14},disable=1,proc=DAP_CheckProc_HedstgeChck,title="1"
	CheckBox Check_DataAcq_HS_01,userdata(tabnum)=  "0",userdata(tabcontrol)=  "ADC"
	CheckBox Check_DataAcq_HS_01,userdata(ResizeControlsInfo)= A"!!,GE!!#?e!!#=#!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_DataAcq_HS_01,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_DataAcq_HS_01,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_DataAcq_HS_01,value= 0
	CheckBox Check_DataAcq_HS_02,pos={212,86},size={24,14},disable=1,proc=DAP_CheckProc_HedstgeChck,title="2"
	CheckBox Check_DataAcq_HS_02,userdata(tabnum)=  "0",userdata(tabcontrol)=  "ADC"
	CheckBox Check_DataAcq_HS_02,userdata(ResizeControlsInfo)= A"!!,Gg!!#?e!!#=#!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_DataAcq_HS_02,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_DataAcq_HS_02,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_DataAcq_HS_02,value= 0
	CheckBox Check_DataAcq_HS_03,pos={246,86},size={24,14},disable=1,proc=DAP_CheckProc_HedstgeChck,title="3"
	CheckBox Check_DataAcq_HS_03,userdata(tabnum)=  "0",userdata(tabcontrol)=  "ADC"
	CheckBox Check_DataAcq_HS_03,userdata(ResizeControlsInfo)= A"!!,H4!!#?e!!#=#!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_DataAcq_HS_03,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_DataAcq_HS_03,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_DataAcq_HS_03,value= 0
	CheckBox Check_DataAcq_HS_04,pos={280,86},size={24,14},disable=1,proc=DAP_CheckProc_HedstgeChck,title="4"
	CheckBox Check_DataAcq_HS_04,userdata(tabnum)=  "0",userdata(tabcontrol)=  "ADC"
	CheckBox Check_DataAcq_HS_04,userdata(ResizeControlsInfo)= A"!!,HHJ,hp;!!#=#!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_DataAcq_HS_04,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_DataAcq_HS_04,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_DataAcq_HS_04,value= 0
	CheckBox Check_DataAcq_HS_05,pos={314,86},size={24,14},disable=1,proc=DAP_CheckProc_HedstgeChck,title="5"
	CheckBox Check_DataAcq_HS_05,userdata(tabnum)=  "0",userdata(tabcontrol)=  "ADC"
	CheckBox Check_DataAcq_HS_05,userdata(ResizeControlsInfo)= A"!!,HYJ,hp;!!#=#!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_DataAcq_HS_05,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_DataAcq_HS_05,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_DataAcq_HS_05,value= 0
	CheckBox Check_DataAcq_HS_06,pos={348,86},size={24,14},disable=1,proc=DAP_CheckProc_HedstgeChck,title="6"
	CheckBox Check_DataAcq_HS_06,userdata(tabnum)=  "0",userdata(tabcontrol)=  "ADC"
	CheckBox Check_DataAcq_HS_06,userdata(ResizeControlsInfo)= A"!!,HjJ,hp;!!#=#!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_DataAcq_HS_06,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_DataAcq_HS_06,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_DataAcq_HS_06,value= 0
	CheckBox Check_DataAcq_HS_07,pos={382,85},size={24,14},disable=1,proc=DAP_CheckProc_HedstgeChck,title="7"
	CheckBox Check_DataAcq_HS_07,userdata(tabnum)=  "0",userdata(tabcontrol)=  "ADC"
	CheckBox Check_DataAcq_HS_07,userdata(ResizeControlsInfo)= A"!!,I&J,hp9!!#=#!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_DataAcq_HS_07,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_DataAcq_HS_07,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_DataAcq_HS_07,value= 0
	CheckBox Radio_ClampMode_1,pos={145,111},size={16,14},disable=1,proc=DAP_CheckProc_ClampMode,title=""
	CheckBox Radio_ClampMode_1,userdata(tabnum)=  "0",userdata(tabcontrol)=  "ADC"
	CheckBox Radio_ClampMode_1,userdata(ResizeControlsInfo)= A"!!,G$!!#@B!!#<8!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Radio_ClampMode_1,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Radio_ClampMode_1,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Radio_ClampMode_1,value= 0,mode=1
	CheckBox Radio_ClampMode_2,pos={178,62},size={16,14},disable=1,proc=DAP_CheckProc_ClampMode,title=""
	CheckBox Radio_ClampMode_2,userdata(tabnum)=  "0",userdata(tabcontrol)=  "ADC"
	CheckBox Radio_ClampMode_2,userdata(ResizeControlsInfo)= A"!!,GE!!#?1!!#<8!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Radio_ClampMode_2,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Radio_ClampMode_2,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Radio_ClampMode_2,value= 1,mode=1
	CheckBox Radio_ClampMode_3,pos={178,111},size={16,14},disable=1,proc=DAP_CheckProc_ClampMode,title=""
	CheckBox Radio_ClampMode_3,userdata(tabnum)=  "0",userdata(tabcontrol)=  "ADC"
	CheckBox Radio_ClampMode_3,userdata(ResizeControlsInfo)= A"!!,GE!!#@B!!#<8!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Radio_ClampMode_3,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Radio_ClampMode_3,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Radio_ClampMode_3,value= 0,mode=1
	CheckBox Radio_ClampMode_4,pos={212,62},size={16,14},disable=1,proc=DAP_CheckProc_ClampMode,title=""
	CheckBox Radio_ClampMode_4,userdata(tabnum)=  "0",userdata(tabcontrol)=  "ADC"
	CheckBox Radio_ClampMode_4,userdata(ResizeControlsInfo)= A"!!,Gg!!#?1!!#<8!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Radio_ClampMode_4,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Radio_ClampMode_4,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Radio_ClampMode_4,value= 1,mode=1
	CheckBox Radio_ClampMode_5,pos={212,111},size={16,14},disable=1,proc=DAP_CheckProc_ClampMode,title=""
	CheckBox Radio_ClampMode_5,userdata(tabnum)=  "0",userdata(tabcontrol)=  "ADC"
	CheckBox Radio_ClampMode_5,userdata(ResizeControlsInfo)= A"!!,Gg!!#@B!!#<8!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Radio_ClampMode_5,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Radio_ClampMode_5,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Radio_ClampMode_5,value= 0,mode=1
	CheckBox Radio_ClampMode_6,pos={246,62},size={16,14},disable=1,proc=DAP_CheckProc_ClampMode,title=""
	CheckBox Radio_ClampMode_6,userdata(tabnum)=  "0",userdata(tabcontrol)=  "ADC"
	CheckBox Radio_ClampMode_6,userdata(ResizeControlsInfo)= A"!!,H4!!#?1!!#<8!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Radio_ClampMode_6,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Radio_ClampMode_6,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Radio_ClampMode_6,value= 1,mode=1
	CheckBox Radio_ClampMode_7,pos={246,111},size={16,14},disable=1,proc=DAP_CheckProc_ClampMode,title=""
	CheckBox Radio_ClampMode_7,userdata(tabnum)=  "0",userdata(tabcontrol)=  "ADC"
	CheckBox Radio_ClampMode_7,userdata(ResizeControlsInfo)= A"!!,H4!!#@B!!#<8!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Radio_ClampMode_7,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Radio_ClampMode_7,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Radio_ClampMode_7,value= 0,mode=1
	CheckBox Radio_ClampMode_8,pos={280,62},size={16,14},disable=1,proc=DAP_CheckProc_ClampMode,title=""
	CheckBox Radio_ClampMode_8,userdata(tabnum)=  "0",userdata(tabcontrol)=  "ADC"
	CheckBox Radio_ClampMode_8,userdata(ResizeControlsInfo)= A"!!,HHJ,ho\\!!#<8!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Radio_ClampMode_8,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Radio_ClampMode_8,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Radio_ClampMode_8,value= 1,mode=1
	CheckBox Radio_ClampMode_9,pos={280,111},size={16,14},disable=1,proc=DAP_CheckProc_ClampMode,title=""
	CheckBox Radio_ClampMode_9,userdata(tabnum)=  "0",userdata(tabcontrol)=  "ADC"
	CheckBox Radio_ClampMode_9,userdata(ResizeControlsInfo)= A"!!,HHJ,hpm!!#<8!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Radio_ClampMode_9,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Radio_ClampMode_9,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Radio_ClampMode_9,value= 0,mode=1
	CheckBox Radio_ClampMode_10,pos={314,62},size={16,14},disable=1,proc=DAP_CheckProc_ClampMode,title=""
	CheckBox Radio_ClampMode_10,userdata(tabnum)=  "0",userdata(tabcontrol)=  "ADC"
	CheckBox Radio_ClampMode_10,userdata(ResizeControlsInfo)= A"!!,HYJ,ho\\!!#<8!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Radio_ClampMode_10,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Radio_ClampMode_10,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Radio_ClampMode_10,value= 1,mode=1
	CheckBox Radio_ClampMode_11,pos={314,111},size={16,14},disable=1,proc=DAP_CheckProc_ClampMode,title=""
	CheckBox Radio_ClampMode_11,userdata(tabnum)=  "0",userdata(tabcontrol)=  "ADC"
	CheckBox Radio_ClampMode_11,userdata(ResizeControlsInfo)= A"!!,HYJ,hpm!!#<8!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Radio_ClampMode_11,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Radio_ClampMode_11,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Radio_ClampMode_11,value= 0,mode=1
	CheckBox Radio_ClampMode_12,pos={348,62},size={16,14},disable=1,proc=DAP_CheckProc_ClampMode,title=""
	CheckBox Radio_ClampMode_12,userdata(tabnum)=  "0",userdata(tabcontrol)=  "ADC"
	CheckBox Radio_ClampMode_12,userdata(ResizeControlsInfo)= A"!!,HjJ,ho\\!!#<8!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Radio_ClampMode_12,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Radio_ClampMode_12,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Radio_ClampMode_12,value= 1,mode=1
	CheckBox Radio_ClampMode_13,pos={348,111},size={16,14},disable=1,proc=DAP_CheckProc_ClampMode,title=""
	CheckBox Radio_ClampMode_13,userdata(tabnum)=  "0",userdata(tabcontrol)=  "ADC"
	CheckBox Radio_ClampMode_13,userdata(ResizeControlsInfo)= A"!!,HjJ,hpm!!#<8!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Radio_ClampMode_13,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Radio_ClampMode_13,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Radio_ClampMode_13,value= 0,mode=1
	CheckBox Radio_ClampMode_14,pos={382,62},size={16,14},disable=1,proc=DAP_CheckProc_ClampMode,title=""
	CheckBox Radio_ClampMode_14,userdata(tabnum)=  "0",userdata(tabcontrol)=  "ADC"
	CheckBox Radio_ClampMode_14,userdata(ResizeControlsInfo)= A"!!,I&J,ho\\!!#<8!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Radio_ClampMode_14,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Radio_ClampMode_14,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Radio_ClampMode_14,value= 1,mode=1
	CheckBox Radio_ClampMode_15,pos={382,111},size={16,14},disable=1,proc=DAP_CheckProc_ClampMode,title=""
	CheckBox Radio_ClampMode_15,userdata(tabnum)=  "0",userdata(tabcontrol)=  "ADC"
	CheckBox Radio_ClampMode_15,userdata(ResizeControlsInfo)= A"!!,I&J,hpm!!#<8!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Radio_ClampMode_15,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Radio_ClampMode_15,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Radio_ClampMode_15,value= 0,mode=1
	PopupMenu Popup_Settings_VC_DA,pos={32,411},size={53,21},proc=DAP_PopMenuProc_CAA,title="DA"
	PopupMenu Popup_Settings_VC_DA,userdata(tabnum)=  "6"
	PopupMenu Popup_Settings_VC_DA,userdata(tabcontrol)=  "ADC"
	PopupMenu Popup_Settings_VC_DA,userdata(ResizeControlsInfo)= A"!!,Cp!!#BB!!#>b!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Popup_Settings_VC_DA,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Popup_Settings_VC_DA,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Popup_Settings_VC_DA,mode=1,popvalue="0",value= #"\"0;1;2;3;4;5;6;7\""
	PopupMenu Popup_Settings_VC_AD,pos={32,436},size={53,21},proc=DAP_PopMenuProc_CAA,title="AD"
	PopupMenu Popup_Settings_VC_AD,userdata(tabnum)=  "6"
	PopupMenu Popup_Settings_VC_AD,userdata(tabcontrol)=  "ADC"
	PopupMenu Popup_Settings_VC_AD,userdata(ResizeControlsInfo)= A"!!,Cp!!#BMJ,ho8!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Popup_Settings_VC_AD,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Popup_Settings_VC_AD,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Popup_Settings_VC_AD,mode=1,popvalue="0",value= #"\"0;1;2;3;4;5;6;7;8;9;10;11;12;13;14;15\""
	PopupMenu Popup_Settings_IC_AD,pos={212,436},size={53,21},proc=DAP_PopMenuProc_CAA,title="AD"
	PopupMenu Popup_Settings_IC_AD,userdata(tabnum)=  "6"
	PopupMenu Popup_Settings_IC_AD,userdata(tabcontrol)=  "ADC"
	PopupMenu Popup_Settings_IC_AD,userdata(ResizeControlsInfo)= A"!!,G%!!#BMJ,ho8!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Popup_Settings_IC_AD,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Popup_Settings_IC_AD,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Popup_Settings_IC_AD,mode=1,popvalue="0",value= #"\"0;1;2;3;4;5;6;7;8;9;10;11;12;13;14;15\""
	SetVariable setvar_Settings_VC_DAgain,pos={93,413},size={50,16},proc=DAP_SetVarProc_CAA
	SetVariable setvar_Settings_VC_DAgain,userdata(tabnum)=  "6"
	SetVariable setvar_Settings_VC_DAgain,userdata(tabcontrol)=  "ADC"
	SetVariable setvar_Settings_VC_DAgain,userdata(ResizeControlsInfo)= A"!!,F!!!#BCJ,ho,!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_Settings_VC_DAgain,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_Settings_VC_DAgain,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_Settings_VC_DAgain,value= _NUM:20
	SetVariable setvar_Settings_VC_ADgain,pos={93,438},size={50,16},proc=DAP_SetVarProc_CAA
	SetVariable setvar_Settings_VC_ADgain,userdata(tabnum)=  "6"
	SetVariable setvar_Settings_VC_ADgain,userdata(tabcontrol)=  "ADC"
	SetVariable setvar_Settings_VC_ADgain,userdata(ResizeControlsInfo)= A"!!,F!!!#BO!!#>V!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_Settings_VC_ADgain,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_Settings_VC_ADgain,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_Settings_VC_ADgain,value= _NUM:0.00999999977648258
	SetVariable setvar_Settings_IC_ADgain,pos={273,438},size={50,16},proc=DAP_SetVarProc_CAA
	SetVariable setvar_Settings_IC_ADgain,userdata(tabnum)=  "6"
	SetVariable setvar_Settings_IC_ADgain,userdata(tabcontrol)=  "ADC"
	SetVariable setvar_Settings_IC_ADgain,userdata(ResizeControlsInfo)= A"!!,G`!!#BO!!#>V!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_Settings_IC_ADgain,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_Settings_IC_ADgain,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_Settings_IC_ADgain,value= _NUM:0.00999999977648258
	PopupMenu Popup_Settings_HeadStage,pos={32,329},size={95,21},proc=DAP_PopMenuProc_Headstage,title="Head Stage"
	PopupMenu Popup_Settings_HeadStage,userdata(tabnum)=  "6"
	PopupMenu Popup_Settings_HeadStage,userdata(tabcontrol)=  "ADC"
	PopupMenu Popup_Settings_HeadStage,userdata(ResizeControlsInfo)= A"!!,Cp!!#As!!#@\"!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Popup_Settings_HeadStage,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Popup_Settings_HeadStage,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Popup_Settings_HeadStage,mode=1,popvalue="0",value= #"\"0;1;2;3;4;5;6;7\""
	PopupMenu popup_Settings_Amplifier,pos={32,358},size={224,21},bodyWidth=150,proc=DAP_PopMenuProc_CAA,title="Amplfier (700B)"
	PopupMenu popup_Settings_Amplifier,userdata(tabnum)=  "6"
	PopupMenu popup_Settings_Amplifier,userdata(tabcontrol)=  "ADC"
	PopupMenu popup_Settings_Amplifier,userdata(ResizeControlsInfo)= A"!!,G8!!#As!!#Ao!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu popup_Settings_Amplifier,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu popup_Settings_Amplifier,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu popup_Settings_Amplifier,mode=1,popvalue=" - none - ",value= #"\" - none - ;\""
	PopupMenu Popup_Settings_IC_DA,pos={212,411},size={53,21},proc=DAP_PopMenuProc_CAA,title="DA"
	PopupMenu Popup_Settings_IC_DA,userdata(tabnum)=  "6"
	PopupMenu Popup_Settings_IC_DA,userdata(tabcontrol)=  "ADC"
	PopupMenu Popup_Settings_IC_DA,userdata(ResizeControlsInfo)= A"!!,G%!!#BB!!#>b!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Popup_Settings_IC_DA,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Popup_Settings_IC_DA,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Popup_Settings_IC_DA,mode=1,popvalue="0",value= #"\"0;1;2;3;4;5;6;7\""
	SetVariable setvar_Settings_IC_DAgain,pos={274,413},size={50,16},proc=DAP_SetVarProc_CAA
	SetVariable setvar_Settings_IC_DAgain,userdata(tabnum)=  "6"
	SetVariable setvar_Settings_IC_DAgain,userdata(tabcontrol)=  "ADC"
	SetVariable setvar_Settings_IC_DAgain,userdata(ResizeControlsInfo)= A"!!,G`!!#BCJ,ho,!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_Settings_IC_DAgain,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_Settings_IC_DAgain,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_Settings_IC_DAgain,value= _NUM:400
	TitleBox Title_settings_Hardware_VC,pos={43,395},size={39,13},title="V-Clamp"
	TitleBox Title_settings_Hardware_VC,userdata(tabnum)=  "6"
	TitleBox Title_settings_Hardware_VC,userdata(tabcontrol)=  "ADC"
	TitleBox Title_settings_Hardware_VC,userdata(ResizeControlsInfo)= A"!!,EP!!#B7!!#>*!!#;]z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox Title_settings_Hardware_VC,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	TitleBox Title_settings_Hardware_VC,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	TitleBox Title_settings_Hardware_VC,frame=0
	TitleBox Title_settings_ChanlAssign_IC,pos={225,395},size={35,13},title="I-Clamp"
	TitleBox Title_settings_ChanlAssign_IC,userdata(tabnum)=  "6"
	TitleBox Title_settings_ChanlAssign_IC,userdata(tabcontrol)=  "ADC"
	TitleBox Title_settings_ChanlAssign_IC,userdata(ResizeControlsInfo)= A"!!,GF!!#B7!!#=o!!#;]z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox Title_settings_ChanlAssign_IC,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	TitleBox Title_settings_ChanlAssign_IC,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	TitleBox Title_settings_ChanlAssign_IC,frame=0
	Button button_Settings_UpdateAmpStatus,pos={262,358},size={150,20},proc=DAP_ButtonCtrlFindConnectedAmps,title="Query connected Amp(s)"
	Button button_Settings_UpdateAmpStatus,userdata(tabnum)=  "6"
	Button button_Settings_UpdateAmpStatus,userdata(tabcontrol)=  "ADC"
	Button button_Settings_UpdateAmpStatus,userdata(ResizeControlsInfo)= A"!!,HL!!#B8!!#@,!!#=Sz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_Settings_UpdateAmpStatus,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button button_Settings_UpdateAmpStatus,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Search_DA_00,pos={141,98},size={124,16},disable=1,proc=DAP_SetVarProc_DASearch,title="Search string"
	SetVariable Search_DA_00,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	SetVariable Search_DA_00,userdata(ResizeControlsInfo)= A"!!,FI!!#@&!!#@\\!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Search_DA_00,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Search_DA_00,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Search_DA_00,value= _STR:""
	SetVariable Search_DA_01,pos={141,145},size={124,16},disable=1,proc=DAP_SetVarProc_DASearch,title="Search string"
	SetVariable Search_DA_01,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	SetVariable Search_DA_01,userdata(ResizeControlsInfo)= A"!!,FI!!#@t!!#@\\!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Search_DA_01,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Search_DA_01,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Search_DA_01,value= _STR:""
	SetVariable Search_DA_02,pos={141,191},size={124,16},disable=1,proc=DAP_SetVarProc_DASearch,title="Search string"
	SetVariable Search_DA_02,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	SetVariable Search_DA_02,userdata(ResizeControlsInfo)= A"!!,FI!!#AN!!#@\\!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Search_DA_02,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Search_DA_02,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Search_DA_02,value= _STR:""
	SetVariable Search_DA_03,pos={141,237},size={124,16},disable=1,proc=DAP_SetVarProc_DASearch,title="Search string"
	SetVariable Search_DA_03,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	SetVariable Search_DA_03,userdata(ResizeControlsInfo)= A"!!,FI!!#B(!!#@\\!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Search_DA_03,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Search_DA_03,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Search_DA_03,value= _STR:""
	SetVariable Search_DA_04,pos={141,282},size={124,16},disable=1,proc=DAP_SetVarProc_DASearch,title="Search string"
	SetVariable Search_DA_04,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	SetVariable Search_DA_04,userdata(ResizeControlsInfo)= A"!!,FI!!#BH!!#@\\!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Search_DA_04,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Search_DA_04,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Search_DA_04,value= _STR:""
	SetVariable Search_DA_05,pos={141,329},size={124,16},disable=1,proc=DAP_SetVarProc_DASearch,title="Search string"
	SetVariable Search_DA_05,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	SetVariable Search_DA_05,userdata(ResizeControlsInfo)= A"!!,FI!!#B_J,hq2!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Search_DA_05,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Search_DA_05,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Search_DA_05,value= _STR:""
	SetVariable Search_DA_06,pos={141,376},size={124,16},disable=1,proc=DAP_SetVarProc_DASearch,title="Search string"
	SetVariable Search_DA_06,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	SetVariable Search_DA_06,userdata(ResizeControlsInfo)= A"!!,FI!!#C\"!!#@\\!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Search_DA_06,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Search_DA_06,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Search_DA_06,value= _STR:""
	SetVariable Search_DA_07,pos={141,424},size={124,16},disable=1,proc=DAP_SetVarProc_DASearch,title="Search string"
	SetVariable Search_DA_07,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	SetVariable Search_DA_07,userdata(ResizeControlsInfo)= A"!!,FI!!#C:!!#@\\!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Search_DA_07,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Search_DA_07,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Search_DA_07,value= _STR:""
	CheckBox SearchUniversal_DA_00,pos={273,99},size={69,14},disable=1,proc=DAP_CheckProc_UnivrslSrchStr,title="Apply to all"
	CheckBox SearchUniversal_DA_00,userdata(tabnum)=  "1"
	CheckBox SearchUniversal_DA_00,userdata(tabcontrol)=  "ADC"
	CheckBox SearchUniversal_DA_00,userdata(ResizeControlsInfo)= A"!!,H1!!#@(!!#?C!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox SearchUniversal_DA_00,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox SearchUniversal_DA_00,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox SearchUniversal_DA_00,value= 0
	SetVariable Search_TTL_00,pos={102,94},size={124,16},disable=1,proc=DAP_SetVarProc_TTLSearch,title="Search string"
	SetVariable Search_TTL_00,userdata(tabnum)=  "3",userdata(tabcontrol)=  "ADC"
	SetVariable Search_TTL_00,userdata(ResizeControlsInfo)= A"!!,F1!!#?u!!#@\\!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Search_TTL_00,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Search_TTL_00,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Search_TTL_00,value= _STR:""
	SetVariable Search_TTL_01,pos={102,140},size={124,16},disable=1,proc=DAP_SetVarProc_TTLSearch,title="Search string"
	SetVariable Search_TTL_01,userdata(tabnum)=  "3",userdata(tabcontrol)=  "ADC"
	SetVariable Search_TTL_01,userdata(ResizeControlsInfo)= A"!!,F1!!#@p!!#@\\!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Search_TTL_01,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Search_TTL_01,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Search_TTL_01,value= _STR:""
	SetVariable Search_TTL_02,pos={102,187},size={124,16},disable=1,proc=DAP_SetVarProc_TTLSearch,title="Search string"
	SetVariable Search_TTL_02,userdata(tabnum)=  "3",userdata(tabcontrol)=  "ADC"
	SetVariable Search_TTL_02,userdata(ResizeControlsInfo)= A"!!,F1!!#AJ!!#@\\!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Search_TTL_02,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Search_TTL_02,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Search_TTL_02,value= _STR:""
	SetVariable Search_TTL_03,pos={99,234},size={124,16},disable=1,proc=DAP_SetVarProc_TTLSearch,title="Search string"
	SetVariable Search_TTL_03,userdata(tabnum)=  "3",userdata(tabcontrol)=  "ADC"
	SetVariable Search_TTL_03,userdata(ResizeControlsInfo)= A"!!,F1!!#B#!!#@\\!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Search_TTL_03,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Search_TTL_03,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Search_TTL_03,value= _STR:""
	SetVariable Search_TTL_04,pos={102,279},size={124,16},disable=1,proc=DAP_SetVarProc_TTLSearch,title="Search string"
	SetVariable Search_TTL_04,userdata(tabnum)=  "3",userdata(tabcontrol)=  "ADC"
	SetVariable Search_TTL_04,userdata(ResizeControlsInfo)= A"!!,F1!!#BEJ,hq2!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Search_TTL_04,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Search_TTL_04,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Search_TTL_04,value= _STR:""
	SetVariable Search_TTL_05,pos={102,325},size={124,16},disable=1,proc=DAP_SetVarProc_TTLSearch,title="Search string"
	SetVariable Search_TTL_05,userdata(tabnum)=  "3",userdata(tabcontrol)=  "ADC"
	SetVariable Search_TTL_05,userdata(ResizeControlsInfo)= A"!!,F1!!#B\\J,hq2!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Search_TTL_05,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Search_TTL_05,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Search_TTL_05,value= _STR:""
	SetVariable Search_TTL_06,pos={102,371},size={124,16},disable=1,proc=DAP_SetVarProc_TTLSearch,title="Search string"
	SetVariable Search_TTL_06,userdata(tabnum)=  "3",userdata(tabcontrol)=  "ADC"
	SetVariable Search_TTL_06,userdata(ResizeControlsInfo)= A"!!,F1!!#BsJ,hq2!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Search_TTL_06,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Search_TTL_06,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Search_TTL_06,value= _STR:""
	SetVariable Search_TTL_07,pos={102,419},size={124,16},disable=1,proc=DAP_SetVarProc_TTLSearch,title="Search string"
	SetVariable Search_TTL_07,userdata(tabnum)=  "3",userdata(tabcontrol)=  "ADC"
	SetVariable Search_TTL_07,userdata(ResizeControlsInfo)= A"!!,F1!!#C6J,hq2!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Search_TTL_07,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Search_TTL_07,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Search_TTL_07,value= _STR:""
	CheckBox SearchUniversal_TTL_00,pos={235,96},size={69,14},disable=1,proc=DAP_CheckProc_UnivrslSrchTTL,title="Apply to all"
	CheckBox SearchUniversal_TTL_00,userdata(tabnum)=  "3"
	CheckBox SearchUniversal_TTL_00,userdata(tabcontrol)=  "ADC"
	CheckBox SearchUniversal_TTL_00,userdata(ResizeControlsInfo)= A"!!,H&!!#@\"!!#?C!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox SearchUniversal_TTL_00,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox SearchUniversal_TTL_00,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox SearchUniversal_TTL_00,value= 0
	CheckBox Check_DataAcq_Indexing,pos={178,619},size={58,14},disable=1,proc=DAP_CheckProc_IndexingState,title="Indexing"
	CheckBox Check_DataAcq_Indexing,help={"Data acquisition proceeds to next wave in DAC or TTL popup menu list"}
	CheckBox Check_DataAcq_Indexing,userdata(tabnum)=  "0"
	CheckBox Check_DataAcq_Indexing,userdata(tabcontrol)=  "ADC"
	CheckBox Check_DataAcq_Indexing,userdata(ResizeControlsInfo)= A"!!,F-!!#BjJ,hoL!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_DataAcq_Indexing,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_DataAcq_Indexing,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_DataAcq_Indexing,value= 0
	TitleBox Title_DA_IndexStartEnd,pos={319,50},size={111,13},disable=1,title="\\JCIndexing End Wave"
	TitleBox Title_DA_IndexStartEnd,userdata(tabnum)=  "1"
	TitleBox Title_DA_IndexStartEnd,userdata(tabcontrol)=  "ADC"
	TitleBox Title_DA_IndexStartEnd,userdata(ResizeControlsInfo)= A"!!,HM!!#>b!!#@B!!#;]z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox Title_DA_IndexStartEnd,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	TitleBox Title_DA_IndexStartEnd,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	TitleBox Title_DA_IndexStartEnd,frame=0,fStyle=1,anchor= LC
	TitleBox Title_DA_Gain,pos={51,50},size={26,13},disable=1,title="Gain"
	TitleBox Title_DA_Gain,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	TitleBox Title_DA_Gain,userdata(ResizeControlsInfo)= A"!!,EN!!#>^!!#=3!!#;]z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox Title_DA_Gain,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	TitleBox Title_DA_Gain,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	TitleBox Title_DA_Gain,frame=0,fStyle=1
	TitleBox Title_DA_DAWaveSelect,pos={157,50},size={94,13},disable=1,title="DA Wave Select"
	TitleBox Title_DA_DAWaveSelect,help={"Use the popup menus to select the stimulus set that will be output from the associated channel"}
	TitleBox Title_DA_DAWaveSelect,userdata(tabnum)=  "1"
	TitleBox Title_DA_DAWaveSelect,userdata(tabcontrol)=  "ADC"
	TitleBox Title_DA_DAWaveSelect,userdata(ResizeControlsInfo)= A"!!,FI!!#>^!!#@b!!#;]z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox Title_DA_DAWaveSelect,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	TitleBox Title_DA_DAWaveSelect,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	TitleBox Title_DA_DAWaveSelect,frame=0,fStyle=1
	TitleBox Title_DA_Scale,pos={274,50},size={32,13},disable=1,title="Scale"
	TitleBox Title_DA_Scale,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	TitleBox Title_DA_Scale,userdata(ResizeControlsInfo)= A"!!,H0!!#>b!!#=c!!#;]z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox Title_DA_Scale,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	TitleBox Title_DA_Scale,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	TitleBox Title_DA_Scale,frame=0,fStyle=1
	TitleBox Title_DA_Channel,pos={24,50},size={17,13},disable=1,title="DA"
	TitleBox Title_DA_Channel,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	TitleBox Title_DA_Channel,userdata(ResizeControlsInfo)= A"!!,BY!!#>^!!#=K!!#;]z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox Title_DA_Channel,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	TitleBox Title_DA_Channel,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	TitleBox Title_DA_Channel,frame=0,fStyle=1
	PopupMenu Popup_DA_IndexEnd_00,pos={316,73},size={125,21},bodyWidth=125,disable=1,proc=DAP_PopMenuChkProc_StimSetList
	PopupMenu Popup_DA_IndexEnd_00,userdata(tabnum)=  "1"
	PopupMenu Popup_DA_IndexEnd_00,userdata(tabcontrol)=  "ADC"
	PopupMenu Popup_DA_IndexEnd_00,userdata(ResizeControlsInfo)= A"!!,HKJ,hot!!#@^!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Popup_DA_IndexEnd_00,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Popup_DA_IndexEnd_00,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Popup_DA_IndexEnd_00,mode=1,popvalue="- none -",value= #"\"- none -;\"+WBP_ITCPanelPopUps(0,\"*DA*\")"
	PopupMenu Popup_DA_IndexEnd_01,pos={316,118},size={125,21},bodyWidth=125,disable=1,proc=DAP_PopMenuChkProc_StimSetList
	PopupMenu Popup_DA_IndexEnd_01,userdata(tabnum)=  "1"
	PopupMenu Popup_DA_IndexEnd_01,userdata(tabcontrol)=  "ADC"
	PopupMenu Popup_DA_IndexEnd_01,userdata(ResizeControlsInfo)= A"!!,HKJ,hq&!!#@^!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Popup_DA_IndexEnd_01,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Popup_DA_IndexEnd_01,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Popup_DA_IndexEnd_01,mode=1,popvalue="- none -",value= #"\"- none -;\"+WBP_ITCPanelPopUps(0,\"*da*\")"
	PopupMenu Popup_DA_IndexEnd_02,pos={316,165},size={125,21},bodyWidth=125,disable=1,proc=DAP_PopMenuChkProc_StimSetList
	PopupMenu Popup_DA_IndexEnd_02,userdata(tabnum)=  "1"
	PopupMenu Popup_DA_IndexEnd_02,userdata(tabcontrol)=  "ADC"
	PopupMenu Popup_DA_IndexEnd_02,userdata(ResizeControlsInfo)= A"!!,HKJ,hq_!!#@^!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Popup_DA_IndexEnd_02,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Popup_DA_IndexEnd_02,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Popup_DA_IndexEnd_02,mode=1,popvalue="- none -",value= #"\"- none -;\"+WBP_ITCPanelPopUps(0,\"*da*\")"
	PopupMenu Popup_DA_IndexEnd_03,pos={316,211},size={125,21},bodyWidth=125,disable=1,proc=DAP_PopMenuChkProc_StimSetList
	PopupMenu Popup_DA_IndexEnd_03,userdata(tabnum)=  "1"
	PopupMenu Popup_DA_IndexEnd_03,userdata(tabcontrol)=  "ADC"
	PopupMenu Popup_DA_IndexEnd_03,userdata(ResizeControlsInfo)= A"!!,HKJ,hr9!!#@^!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Popup_DA_IndexEnd_03,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Popup_DA_IndexEnd_03,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Popup_DA_IndexEnd_03,mode=1,popvalue="- none -",value= #"\"- none -;\"+WBP_ITCPanelPopUps(0,\"*da*\")"
	PopupMenu Popup_DA_IndexEnd_04,pos={316,256},size={125,21},bodyWidth=125,disable=1,proc=DAP_PopMenuChkProc_StimSetList
	PopupMenu Popup_DA_IndexEnd_04,userdata(tabnum)=  "1"
	PopupMenu Popup_DA_IndexEnd_04,userdata(tabcontrol)=  "ADC"
	PopupMenu Popup_DA_IndexEnd_04,userdata(ResizeControlsInfo)= A"!!,HKJ,hrf!!#@^!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Popup_DA_IndexEnd_04,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Popup_DA_IndexEnd_04,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Popup_DA_IndexEnd_04,mode=1,popvalue="- none -",value= #"\"- none -;\"+WBP_ITCPanelPopUps(0,\"*da*\")"
	PopupMenu Popup_DA_IndexEnd_05,pos={316,303},size={125,21},bodyWidth=125,disable=1,proc=DAP_PopMenuChkProc_StimSetList
	PopupMenu Popup_DA_IndexEnd_05,userdata(tabnum)=  "1"
	PopupMenu Popup_DA_IndexEnd_05,userdata(tabcontrol)=  "ADC"
	PopupMenu Popup_DA_IndexEnd_05,userdata(ResizeControlsInfo)= A"!!,HKJ,hs(J,hq4!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Popup_DA_IndexEnd_05,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Popup_DA_IndexEnd_05,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Popup_DA_IndexEnd_05,mode=1,popvalue="- none -",value= #"\"- none -;\"+WBP_ITCPanelPopUps(0,\"*da*\")"
	PopupMenu Popup_DA_IndexEnd_06,pos={316,350},size={125,21},bodyWidth=125,disable=1,proc=DAP_PopMenuChkProc_StimSetList
	PopupMenu Popup_DA_IndexEnd_06,userdata(tabnum)=  "1"
	PopupMenu Popup_DA_IndexEnd_06,userdata(tabcontrol)=  "ADC"
	PopupMenu Popup_DA_IndexEnd_06,userdata(ResizeControlsInfo)= A"!!,HKJ,hs@!!#@^!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Popup_DA_IndexEnd_06,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Popup_DA_IndexEnd_06,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Popup_DA_IndexEnd_06,mode=1,popvalue="- none -",value= #"\"- none -;\"+WBP_ITCPanelPopUps(0,\"*da*\")"
	PopupMenu Popup_DA_IndexEnd_07,pos={316,397},size={125,21},bodyWidth=125,disable=1,proc=DAP_PopMenuChkProc_StimSetList
	PopupMenu Popup_DA_IndexEnd_07,userdata(tabnum)=  "1"
	PopupMenu Popup_DA_IndexEnd_07,userdata(tabcontrol)=  "ADC"
	PopupMenu Popup_DA_IndexEnd_07,userdata(ResizeControlsInfo)= A"!!,HKJ,hsWJ,hq4!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Popup_DA_IndexEnd_07,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Popup_DA_IndexEnd_07,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Popup_DA_IndexEnd_07,mode=1,popvalue="- none -",value= #"\"- none -;\"+WBP_ITCPanelPopUps(0,\"*da*\")"
	PopupMenu Popup_TTL_IndexEnd_00,pos={242,69},size={125,21},bodyWidth=125,disable=1,proc=DAP_PopMenuChkProc_StimSetList
	PopupMenu Popup_TTL_IndexEnd_00,userdata(tabnum)=  "3"
	PopupMenu Popup_TTL_IndexEnd_00,userdata(tabcontrol)=  "ADC"
	PopupMenu Popup_TTL_IndexEnd_00,userdata(ResizeControlsInfo)= A"!!,H-!!#?C!!#@^!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Popup_TTL_IndexEnd_00,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Popup_TTL_IndexEnd_00,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Popup_TTL_IndexEnd_00,mode=1,popvalue="- none -",value= #"\"- none -;\"+WBP_ITCPanelPopUps(1,\"*TTL*\")"
	PopupMenu Popup_TTL_IndexEnd_01,pos={242,115},size={125,21},bodyWidth=125,disable=1,proc=DAP_PopMenuChkProc_StimSetList
	PopupMenu Popup_TTL_IndexEnd_01,userdata(tabnum)=  "3"
	PopupMenu Popup_TTL_IndexEnd_01,userdata(tabcontrol)=  "ADC"
	PopupMenu Popup_TTL_IndexEnd_01,userdata(ResizeControlsInfo)= A"!!,H-!!#@J!!#@^!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Popup_TTL_IndexEnd_01,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Popup_TTL_IndexEnd_01,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Popup_TTL_IndexEnd_01,mode=1,popvalue="- none -",value= #"\"- none -;\"+WBP_ITCPanelPopUps(1,\"*TTL*\")"
	PopupMenu Popup_TTL_IndexEnd_02,pos={242,161},size={125,21},bodyWidth=125,disable=1,proc=DAP_PopMenuChkProc_StimSetList
	PopupMenu Popup_TTL_IndexEnd_02,userdata(tabnum)=  "3"
	PopupMenu Popup_TTL_IndexEnd_02,userdata(tabcontrol)=  "ADC"
	PopupMenu Popup_TTL_IndexEnd_02,userdata(ResizeControlsInfo)= A"!!,H-!!#A0!!#@^!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Popup_TTL_IndexEnd_02,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Popup_TTL_IndexEnd_02,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Popup_TTL_IndexEnd_02,mode=1,popvalue="- none -",value= #"\"- none -;\"+WBP_ITCPanelPopUps(1,\"*TTL*\")"
	PopupMenu Popup_TTL_IndexEnd_03,pos={242,207},size={125,21},bodyWidth=125,disable=1,proc=DAP_PopMenuChkProc_StimSetList
	PopupMenu Popup_TTL_IndexEnd_03,userdata(tabnum)=  "3"
	PopupMenu Popup_TTL_IndexEnd_03,userdata(tabcontrol)=  "ADC"
	PopupMenu Popup_TTL_IndexEnd_03,userdata(ResizeControlsInfo)= A"!!,H-!!#A^!!#@^!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Popup_TTL_IndexEnd_03,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Popup_TTL_IndexEnd_03,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Popup_TTL_IndexEnd_03,mode=1,popvalue="- none -",value= #"\"- none -;\"+WBP_ITCPanelPopUps(1,\"*TTL*\")"
	PopupMenu Popup_TTL_IndexEnd_04,pos={242,253},size={125,21},bodyWidth=125,disable=1,proc=DAP_PopMenuChkProc_StimSetList
	PopupMenu Popup_TTL_IndexEnd_04,userdata(tabnum)=  "3"
	PopupMenu Popup_TTL_IndexEnd_04,userdata(tabcontrol)=  "ADC"
	PopupMenu Popup_TTL_IndexEnd_04,userdata(ResizeControlsInfo)= A"!!,H-!!#B7!!#@^!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Popup_TTL_IndexEnd_04,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Popup_TTL_IndexEnd_04,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Popup_TTL_IndexEnd_04,mode=1,popvalue="- none -",value= #"\"- none -;\"+WBP_ITCPanelPopUps(1,\"*TTL*\")"
	PopupMenu Popup_TTL_IndexEnd_05,pos={242,299},size={125,21},bodyWidth=125,disable=1,proc=DAP_PopMenuChkProc_StimSetList
	PopupMenu Popup_TTL_IndexEnd_05,userdata(tabnum)=  "3"
	PopupMenu Popup_TTL_IndexEnd_05,userdata(tabcontrol)=  "ADC"
	PopupMenu Popup_TTL_IndexEnd_05,userdata(ResizeControlsInfo)= A"!!,H-!!#BOJ,hq4!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Popup_TTL_IndexEnd_05,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Popup_TTL_IndexEnd_05,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Popup_TTL_IndexEnd_05,mode=1,popvalue="- none -",value= #"\"- none -;\"+WBP_ITCPanelPopUps(1,\"*TTL*\")"
	PopupMenu Popup_TTL_IndexEnd_06,pos={242,345},size={125,21},bodyWidth=125,disable=1,proc=DAP_PopMenuChkProc_StimSetList
	PopupMenu Popup_TTL_IndexEnd_06,userdata(tabnum)=  "3"
	PopupMenu Popup_TTL_IndexEnd_06,userdata(tabcontrol)=  "ADC"
	PopupMenu Popup_TTL_IndexEnd_06,userdata(ResizeControlsInfo)= A"!!,H-!!#BfJ,hq4!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Popup_TTL_IndexEnd_06,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Popup_TTL_IndexEnd_06,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Popup_TTL_IndexEnd_06,mode=1,popvalue="- none -",value= #"\"- none -;\"+WBP_ITCPanelPopUps(1,\"*TTL*\")"
	PopupMenu Popup_TTL_IndexEnd_07,pos={242,392},size={125,21},bodyWidth=125,disable=1,proc=DAP_PopMenuChkProc_StimSetList
	PopupMenu Popup_TTL_IndexEnd_07,userdata(tabnum)=  "3"
	PopupMenu Popup_TTL_IndexEnd_07,userdata(tabcontrol)=  "ADC"
	PopupMenu Popup_TTL_IndexEnd_07,userdata(ResizeControlsInfo)= A"!!,H-!!#C)!!#@^!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Popup_TTL_IndexEnd_07,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Popup_TTL_IndexEnd_07,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Popup_TTL_IndexEnd_07,mode=1,popvalue="- none -",value= #"\"- none -;\"+WBP_ITCPanelPopUps(1,\"*TTL*\")"
	CheckBox check_Settings_ShowScopeWindow,pos={34,517},size={121,14},disable=1,proc=DAP_CheckProc_ShowScopeWin,title="Show Scope Window"
	CheckBox check_Settings_ShowScopeWindow,help={"Enable the scope window to view ongoing acquistion"}
	CheckBox check_Settings_ShowScopeWindow,userdata(tabnum)=  "5"
	CheckBox check_Settings_ShowScopeWindow,userdata(tabcontrol)=  "ADC"
	CheckBox check_Settings_ShowScopeWindow,userdata(ResizeControlsInfo)= A"!!,C<!!#CBJ,hq,!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_Settings_ShowScopeWindow,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_Settings_ShowScopeWindow,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_Settings_ShowScopeWindow,value= 0
	Button Button_TTL_TurnOffAllTTLs,pos={21,422},size={67,40},disable=1,proc=DAP_ButtonProc_TTLOff,title="Turn off\rall TTLs"
	Button Button_TTL_TurnOffAllTTLs,userdata(tabnum)=  "3"
	Button Button_TTL_TurnOffAllTTLs,userdata(tabcontrol)=  "ADC"
	Button Button_TTL_TurnOffAllTTLs,userdata(ResizeControlsInfo)= A"!!,Ba!!#C8!!#??!!#>.z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button Button_TTL_TurnOffAllTTLs,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button Button_TTL_TurnOffAllTTLs,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	Button Button_DAC_TurnOFFDACs,pos={19,420},size={115,20},disable=1,proc=DAP_ButtonProc_DAOff,title="Turn Off alll DAs"
	Button Button_DAC_TurnOFFDACs,userdata(tabnum)=  "1"
	Button Button_DAC_TurnOFFDACs,userdata(tabcontrol)=  "ADC"
	Button Button_DAC_TurnOFFDACs,userdata(ResizeControlsInfo)= A"!!,B9!!#C:!!#?K!!#>\"z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button Button_DAC_TurnOFFDACs,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button Button_DAC_TurnOFFDACs,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	Button Button_ADC_TurnOffAllADCs,pos={20,420},size={115,20},disable=1,proc=DAP_ButtonProc_ADOff,title="Turn off alll ADs"
	Button Button_ADC_TurnOffAllADCs,userdata(tabnum)=  "2"
	Button Button_ADC_TurnOffAllADCs,userdata(tabcontrol)=  "ADC"
	Button Button_ADC_TurnOffAllADCs,userdata(ResizeControlsInfo)= A"!!,AN!!#C.J,hoP!!#>2z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button Button_ADC_TurnOffAllADCs,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button Button_ADC_TurnOffAllADCs,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	Button button_DataAcq_TurnOffAllChan,pos={412,73},size={30,40},disable=1,proc=DAP_ButtonProc_AllChanOff,title="OFF"
	Button button_DataAcq_TurnOffAllChan,userdata(tabnum)=  "0"
	Button button_DataAcq_TurnOffAllChan,userdata(tabcontrol)=  "ADC"
	Button button_DataAcq_TurnOffAllChan,userdata(ResizeControlsInfo)= A"!!,Ht!!#CEJ,hpo!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_DataAcq_TurnOffAllChan,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button button_DataAcq_TurnOffAllChan,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_Settings_ITITP,pos={34,108},size={122,14},disable=1,title="Activate TP during ITI"
	CheckBox check_Settings_ITITP,userdata(tabnum)=  "5"
	CheckBox check_Settings_ITITP,userdata(tabcontrol)=  "ADC"
	CheckBox check_Settings_ITITP,userdata(ResizeControlsInfo)= A"!!,Ch!!#@F!!#A,!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_Settings_ITITP,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_Settings_ITITP,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_Settings_ITITP,value= 1
	ValDisplay valdisp_DataAcq_ITICountdown,pos={60,530},size={129,17},bodyWidth=30,disable=1,title="ITI remaining (s)"
	ValDisplay valdisp_DataAcq_ITICountdown,userdata(tabnum)=  "0"
	ValDisplay valdisp_DataAcq_ITICountdown,userdata(tabcontrol)=  "ADC"
	ValDisplay valdisp_DataAcq_ITICountdown,userdata(ResizeControlsInfo)= A"!!,HVJ,hs5!!#@,!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	ValDisplay valdisp_DataAcq_ITICountdown,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	ValDisplay valdisp_DataAcq_ITICountdown,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	ValDisplay valdisp_DataAcq_ITICountdown,fSize=14,format="%1g",fStyle=0
	ValDisplay valdisp_DataAcq_ITICountdown,valueColor=(65535,65535,65535)
	ValDisplay valdisp_DataAcq_ITICountdown,valueBackColor=(0,0,0)
	ValDisplay valdisp_DataAcq_ITICountdown,limits={0,0,0},barmisc={0,1000}
	ValDisplay valdisp_DataAcq_ITICountdown,value= _NUM:0
	ValDisplay valdisp_DataAcq_TrialsCountdown,pos={45,503},size={145,17},bodyWidth=30,disable=1,title="Sweeps remaining"
	ValDisplay valdisp_DataAcq_TrialsCountdown,userdata(tabnum)=  "0"
	ValDisplay valdisp_DataAcq_TrialsCountdown,userdata(tabcontrol)=  "ADC"
	ValDisplay valdisp_DataAcq_TrialsCountdown,userdata(ResizeControlsInfo)= A"!!,HVJ,hsAJ,hpk!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	ValDisplay valdisp_DataAcq_TrialsCountdown,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	ValDisplay valdisp_DataAcq_TrialsCountdown,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	ValDisplay valdisp_DataAcq_TrialsCountdown,fSize=14,fStyle=0
	ValDisplay valdisp_DataAcq_TrialsCountdown,valueColor=(65535,65535,65535)
	ValDisplay valdisp_DataAcq_TrialsCountdown,valueBackColor=(0,0,0)
	ValDisplay valdisp_DataAcq_TrialsCountdown,limits={0,0,0},barmisc={0,1000}
	ValDisplay valdisp_DataAcq_TrialsCountdown,value= _NUM:1
	CheckBox check_Settings_Overwrite,pos={34,215},size={294,14},disable=1,title="Overwrite history and data waves on Next Sweep roll back"
	CheckBox check_Settings_Overwrite,help={"Overwrite occurs on next data acquisition cycle"}
	CheckBox check_Settings_Overwrite,userdata(tabnum)=  "5"
	CheckBox check_Settings_Overwrite,userdata(tabcontrol)=  "ADC"
	CheckBox check_Settings_Overwrite,userdata(ResizeControlsInfo)= A"!!,Ch!!#@l!!#BM!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_Settings_Overwrite,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_Settings_Overwrite,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_Settings_Overwrite,value= 1
	SetVariable setvar_Async_min_00,pos={113,66},size={71,16},disable=1,title="min"
	SetVariable setvar_Async_min_00,userdata(tabnum)=  "4"
	SetVariable setvar_Async_min_00,userdata(tabcontrol)=  "ADC"
	SetVariable setvar_Async_min_00,userdata(ResizeControlsInfo)= A"!!,FG!!#?=!!#?G!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_Async_min_00,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_Async_min_00,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_Async_min_00,value= _NUM:0
	SetVariable setvar_Async_max_00,pos={197,66},size={76,16},disable=1,title="max"
	SetVariable setvar_Async_max_00,userdata(tabnum)=  "4"
	SetVariable setvar_Async_max_00,userdata(tabcontrol)=  "ADC"
	SetVariable setvar_Async_max_00,userdata(ResizeControlsInfo)= A"!!,GU!!#?=!!#?Q!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_Async_max_00,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_Async_max_00,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_Async_max_00,value= _NUM:0
	CheckBox check_Async_Alarm_00,pos={61,68},size={44,14},disable=1,title="Alarm"
	CheckBox check_Async_Alarm_00,userdata(tabnum)=  "4"
	CheckBox check_Async_Alarm_00,userdata(tabcontrol)=  "ADC"
	CheckBox check_Async_Alarm_00,userdata(ResizeControlsInfo)= A"!!,E.!!#?A!!#>>!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_Async_Alarm_00,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_Async_Alarm_00,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_Async_Alarm_00,value= 0
	SetVariable setvar_Async_min_01,pos={113,117},size={71,16},disable=1,title="min"
	SetVariable setvar_Async_min_01,userdata(tabnum)=  "4"
	SetVariable setvar_Async_min_01,userdata(tabcontrol)=  "ADC"
	SetVariable setvar_Async_min_01,userdata(ResizeControlsInfo)= A"!!,FG!!#@N!!#?G!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_Async_min_01,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_Async_min_01,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_Async_min_01,value= _NUM:0
	SetVariable setvar_Async_max_01,pos={197,117},size={76,16},disable=1,title="max"
	SetVariable setvar_Async_max_01,userdata(tabnum)=  "4"
	SetVariable setvar_Async_max_01,userdata(tabcontrol)=  "ADC"
	SetVariable setvar_Async_max_01,userdata(ResizeControlsInfo)= A"!!,GU!!#@N!!#?Q!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_Async_max_01,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_Async_max_01,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_Async_max_01,value= _NUM:0
	CheckBox check_Async_Alarm_01,pos={61,119},size={44,14},disable=1,title="Alarm"
	CheckBox check_Async_Alarm_01,userdata(tabnum)=  "4"
	CheckBox check_Async_Alarm_01,userdata(tabcontrol)=  "ADC"
	CheckBox check_Async_Alarm_01,userdata(ResizeControlsInfo)= A"!!,E.!!#@R!!#>>!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_Async_Alarm_01,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_Async_Alarm_01,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_Async_Alarm_01,value= 0
	SetVariable setvar_Async_min_02,pos={113,169},size={71,16},disable=1,title="min"
	SetVariable setvar_Async_min_02,userdata(tabnum)=  "4"
	SetVariable setvar_Async_min_02,userdata(tabcontrol)=  "ADC"
	SetVariable setvar_Async_min_02,userdata(ResizeControlsInfo)= A"!!,FG!!#A8!!#?G!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_Async_min_02,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_Async_min_02,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_Async_min_02,value= _NUM:0
	SetVariable setvar_Async_max_02,pos={197,169},size={76,16},disable=1,title="max"
	SetVariable setvar_Async_max_02,userdata(tabnum)=  "4"
	SetVariable setvar_Async_max_02,userdata(tabcontrol)=  "ADC"
	SetVariable setvar_Async_max_02,userdata(ResizeControlsInfo)= A"!!,GU!!#A8!!#?Q!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_Async_max_02,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_Async_max_02,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_Async_max_02,value= _NUM:0
	CheckBox check_Async_Alarm_02,pos={61,171},size={44,14},disable=1,title="Alarm"
	CheckBox check_Async_Alarm_02,userdata(tabnum)=  "4"
	CheckBox check_Async_Alarm_02,userdata(tabcontrol)=  "ADC"
	CheckBox check_Async_Alarm_02,userdata(ResizeControlsInfo)= A"!!,E.!!#A:!!#>>!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_Async_Alarm_02,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_Async_Alarm_02,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_Async_Alarm_02,value= 0
	SetVariable setvar_Async_min_03,pos={113,220},size={71,16},disable=1,title="min"
	SetVariable setvar_Async_min_03,userdata(tabnum)=  "4"
	SetVariable setvar_Async_min_03,userdata(tabcontrol)=  "ADC"
	SetVariable setvar_Async_min_03,userdata(ResizeControlsInfo)= A"!!,FG!!#Ak!!#?G!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_Async_min_03,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_Async_min_03,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_Async_min_03,value= _NUM:0
	SetVariable setvar_Async_max_03,pos={197,220},size={76,16},disable=1,title="max"
	SetVariable setvar_Async_max_03,userdata(tabnum)=  "4"
	SetVariable setvar_Async_max_03,userdata(tabcontrol)=  "ADC"
	SetVariable setvar_Async_max_03,userdata(ResizeControlsInfo)= A"!!,GU!!#Ak!!#?Q!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_Async_max_03,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_Async_max_03,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_Async_max_03,value= _NUM:0
	CheckBox check_Async_Alarm_03,pos={61,222},size={44,14},disable=1,title="Alarm"
	CheckBox check_Async_Alarm_03,userdata(tabnum)=  "4"
	CheckBox check_Async_Alarm_03,userdata(tabcontrol)=  "ADC"
	CheckBox check_Async_Alarm_03,userdata(ResizeControlsInfo)= A"!!,E.!!#Am!!#>>!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_Async_Alarm_03,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_Async_Alarm_03,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_Async_Alarm_03,value= 0
	SetVariable setvar_Async_min_04,pos={113,272},size={71,16},disable=1,title="min"
	SetVariable setvar_Async_min_04,userdata(tabnum)=  "4"
	SetVariable setvar_Async_min_04,userdata(tabcontrol)=  "ADC"
	SetVariable setvar_Async_min_04,userdata(ResizeControlsInfo)= A"!!,FG!!#BB!!#?G!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_Async_min_04,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_Async_min_04,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_Async_min_04,value= _NUM:0
	SetVariable setvar_Async_max_04,pos={197,272},size={76,16},disable=1,title="max"
	SetVariable setvar_Async_max_04,userdata(tabnum)=  "4"
	SetVariable setvar_Async_max_04,userdata(tabcontrol)=  "ADC"
	SetVariable setvar_Async_max_04,userdata(ResizeControlsInfo)= A"!!,GU!!#BB!!#?Q!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_Async_max_04,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_Async_max_04,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_Async_max_04,value= _NUM:0
	CheckBox check_Async_Alarm_04,pos={61,274},size={44,14},disable=1,title="Alarm"
	CheckBox check_Async_Alarm_04,userdata(tabnum)=  "4"
	CheckBox check_Async_Alarm_04,userdata(tabcontrol)=  "ADC"
	CheckBox check_Async_Alarm_04,userdata(ResizeControlsInfo)= A"!!,E.!!#BC!!#>>!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_Async_Alarm_04,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_Async_Alarm_04,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_Async_Alarm_04,value= 0
	SetVariable setvar_Async_min_05,pos={113,323},size={71,16},disable=1,title="min"
	SetVariable setvar_Async_min_05,userdata(tabnum)=  "4"
	SetVariable setvar_Async_min_05,userdata(tabcontrol)=  "ADC"
	SetVariable setvar_Async_min_05,userdata(ResizeControlsInfo)= A"!!,FG!!#B[J,hor!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_Async_min_05,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_Async_min_05,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_Async_min_05,value= _NUM:0
	SetVariable setvar_Async_max_05,pos={197,323},size={76,16},disable=1,title="max"
	SetVariable setvar_Async_max_05,userdata(tabnum)=  "4"
	SetVariable setvar_Async_max_05,userdata(tabcontrol)=  "ADC"
	SetVariable setvar_Async_max_05,userdata(ResizeControlsInfo)= A"!!,GU!!#B[J,hp'!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_Async_max_05,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_Async_max_05,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_Async_max_05,value= _NUM:0
	CheckBox check_Async_Alarm_05,pos={61,325},size={44,14},disable=1,title="Alarm"
	CheckBox check_Async_Alarm_05,userdata(tabnum)=  "4"
	CheckBox check_Async_Alarm_05,userdata(tabcontrol)=  "ADC"
	CheckBox check_Async_Alarm_05,userdata(ResizeControlsInfo)= A"!!,E.!!#B\\J,hni!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_Async_Alarm_05,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_Async_Alarm_05,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_Async_Alarm_05,value= 0
	SetVariable setvar_Async_min_06,pos={113,375},size={71,16},disable=1,title="min"
	SetVariable setvar_Async_min_06,userdata(tabnum)=  "4"
	SetVariable setvar_Async_min_06,userdata(tabcontrol)=  "ADC"
	SetVariable setvar_Async_min_06,userdata(ResizeControlsInfo)= A"!!,FG!!#BuJ,hor!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_Async_min_06,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_Async_min_06,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_Async_min_06,value= _NUM:0
	SetVariable setvar_Async_max_06,pos={197,375},size={76,16},disable=1,title="max"
	SetVariable setvar_Async_max_06,userdata(tabnum)=  "4"
	SetVariable setvar_Async_max_06,userdata(tabcontrol)=  "ADC"
	SetVariable setvar_Async_max_06,userdata(ResizeControlsInfo)= A"!!,GU!!#BuJ,hp'!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_Async_max_06,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_Async_max_06,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_Async_max_06,value= _NUM:0
	CheckBox check_Async_Alarm_06,pos={61,378},size={44,14},disable=1,title="Alarm"
	CheckBox check_Async_Alarm_06,userdata(tabnum)=  "4"
	CheckBox check_Async_Alarm_06,userdata(tabcontrol)=  "ADC"
	CheckBox check_Async_Alarm_06,userdata(ResizeControlsInfo)= A"!!,E.!!#C\"!!#>>!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_Async_Alarm_06,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_Async_Alarm_06,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_Async_Alarm_06,value= 0
	SetVariable setvar_Async_min_07,pos={113,427},size={71,16},disable=1,title="min"
	SetVariable setvar_Async_min_07,userdata(tabnum)=  "4"
	SetVariable setvar_Async_min_07,userdata(tabcontrol)=  "ADC"
	SetVariable setvar_Async_min_07,userdata(ResizeControlsInfo)= A"!!,FG!!#C:J,hor!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_Async_min_07,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_Async_min_07,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_Async_min_07,value= _NUM:0
	SetVariable setvar_Async_max_07,pos={197,427},size={76,16},disable=1,title="max"
	SetVariable setvar_Async_max_07,userdata(tabnum)=  "4"
	SetVariable setvar_Async_max_07,userdata(tabcontrol)=  "ADC"
	SetVariable setvar_Async_max_07,userdata(ResizeControlsInfo)= A"!!,GU!!#C:J,hp'!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_Async_max_07,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_Async_max_07,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_Async_max_07,value= _NUM:0
	CheckBox check_Async_Alarm_07,pos={61,429},size={44,14},disable=1,title="Alarm"
	CheckBox check_Async_Alarm_07,userdata(tabnum)=  "4"
	CheckBox check_Async_Alarm_07,userdata(tabcontrol)=  "ADC"
	CheckBox check_Async_Alarm_07,userdata(ResizeControlsInfo)= A"!!,E.!!#C;J,hni!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_Async_Alarm_07,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_Async_Alarm_07,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_Async_Alarm_07,value= 0
	TitleBox Title_TTL_IndexStartEnd,pos={254,53},size={111,13},disable=1,title="\\JCIndexing End Wave"
	TitleBox Title_TTL_IndexStartEnd,userdata(tabnum)=  "3"
	TitleBox Title_TTL_IndexStartEnd,userdata(tabcontrol)=  "ADC"
	TitleBox Title_TTL_IndexStartEnd,userdata(ResizeControlsInfo)= A"!!,H9!!#>b!!#@B!!#;]z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox Title_TTL_IndexStartEnd,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	TitleBox Title_TTL_IndexStartEnd,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	TitleBox Title_TTL_IndexStartEnd,frame=0,fStyle=1,anchor= LC
	TitleBox Title_TTL_TTLWaveSelect,pos={101,52},size={133,13},disable=1,title="(first) TTL Wave Select"
	TitleBox Title_TTL_TTLWaveSelect,userdata(tabnum)=  "3"
	TitleBox Title_TTL_TTLWaveSelect,userdata(tabcontrol)=  "ADC"
	TitleBox Title_TTL_TTLWaveSelect,userdata(ResizeControlsInfo)= A"!!,F/!!#>^!!#@i!!#;]z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox Title_TTL_TTLWaveSelect,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	TitleBox Title_TTL_TTLWaveSelect,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	TitleBox Title_TTL_TTLWaveSelect,frame=0,fStyle=1
	TitleBox Title_TTL_Channel,pos={28,52},size={29,13},disable=1,title="Chan"
	TitleBox Title_TTL_Channel,userdata(tabnum)=  "3",userdata(tabcontrol)=  "ADC"
	TitleBox Title_TTL_Channel,userdata(ResizeControlsInfo)= A"!!,CD!!#>^!!#=K!!#;]z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox Title_TTL_Channel,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	TitleBox Title_TTL_Channel,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	TitleBox Title_TTL_Channel,frame=0,fStyle=1
	CheckBox check_DataAcq_RepAcqRandom,pos={72,619},size={58,14},disable=1,title="Random"
	CheckBox check_DataAcq_RepAcqRandom,help={"Randomly selects wave from set selected for DAC channel on each trial. Doesn't repeat waves."}
	CheckBox check_DataAcq_RepAcqRandom,userdata(tabnum)=  "0"
	CheckBox check_DataAcq_RepAcqRandom,userdata(tabcontrol)=  "ADC"
	CheckBox check_DataAcq_RepAcqRandom,userdata(ResizeControlsInfo)= A"!!,D'!!#Bj!!#?!!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_DataAcq_RepAcqRandom,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_DataAcq_RepAcqRandom,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_DataAcq_RepAcqRandom,value= 0
	TitleBox title_Settings_SetCondition,pos={61,314},size={64,13},disable=1,title="Set A > Set B"
	TitleBox title_Settings_SetCondition,userdata(tabnum)=  "5"
	TitleBox title_Settings_SetCondition,userdata(tabcontrol)=  "ADC"
	TitleBox title_Settings_SetCondition,userdata(ResizeControlsInfo)= A"!!,C$!!#B,!!#?u!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox title_Settings_SetCondition,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	TitleBox title_Settings_SetCondition,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	TitleBox title_Settings_SetCondition,frame=0
	CheckBox check_Settings_Option_3,pos={280,330},size={120,26},disable=1,title="Repeat set B\runtil set A is complete"
	CheckBox check_Settings_Option_3,help={"This mode is useful when Set B contains a single wave."}
	CheckBox check_Settings_Option_3,userdata(tabnum)=  "5"
	CheckBox check_Settings_Option_3,userdata(tabcontrol)=  "ADC"
	CheckBox check_Settings_Option_3,userdata(ResizeControlsInfo)= A"!!,HC!!#B<!!#@T!!#=3z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_Settings_Option_3,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_Settings_Option_3,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_Settings_Option_3,fColor=(65280,43520,0),value= 0
	CheckBox check_Settings_ScalingZero,pos={280,273},size={132,14},disable=1,title="Set channel scaling to 0"
	CheckBox check_Settings_ScalingZero,help={"Applies to DA channel outputting Set B"}
	CheckBox check_Settings_ScalingZero,userdata(tabnum)=  "5"
	CheckBox check_Settings_ScalingZero,userdata(tabcontrol)=  "ADC"
	CheckBox check_Settings_ScalingZero,userdata(ResizeControlsInfo)= A"!!,HC!!#AZ!!#?K!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_Settings_ScalingZero,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_Settings_ScalingZero,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_Settings_ScalingZero,value= 0
	CheckBox check_Settings_SetOption_04,pos={280,303},size={108,14},disable=3,title="Turn off headstage"
	CheckBox check_Settings_SetOption_04,help={"Turns off AD associated with DA via Channel and Amplifier Assignments"}
	CheckBox check_Settings_SetOption_04,userdata(tabnum)=  "5"
	CheckBox check_Settings_SetOption_04,userdata(tabcontrol)=  "ADC"
	CheckBox check_Settings_SetOption_04,userdata(ResizeControlsInfo)= A"!!,HC!!#B#!!#@<!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_Settings_SetOption_04,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_Settings_SetOption_04,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_Settings_SetOption_04,fColor=(65280,43520,0),value= 0
	TitleBox title_Settings_SetCondition_00,pos={124,298},size={6,13},disable=1,title="\\f01/"
	TitleBox title_Settings_SetCondition_00,userdata(tabnum)=  "5"
	TitleBox title_Settings_SetCondition_00,userdata(tabcontrol)=  "ADC"
	TitleBox title_Settings_SetCondition_00,userdata(ResizeControlsInfo)= A"!!,FM!!#As!!#:\"!!#;]z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox title_Settings_SetCondition_00,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	TitleBox title_Settings_SetCondition_00,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	TitleBox title_Settings_SetCondition_00,frame=0
	TitleBox title_Settings_SetCondition_01,pos={124,335},size={6,13},disable=1,title="\\f01\\"
	TitleBox title_Settings_SetCondition_01,userdata(tabnum)=  "5"
	TitleBox title_Settings_SetCondition_01,userdata(tabcontrol)=  "ADC"
	TitleBox title_Settings_SetCondition_01,userdata(ResizeControlsInfo)= A"!!,FM!!#B>J,hjM!!#;]z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox title_Settings_SetCondition_01,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	TitleBox title_Settings_SetCondition_01,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	TitleBox title_Settings_SetCondition_01,frame=0
	TitleBox title_Settings_SetCondition_04,pos={272,298},size={6,13},disable=1,title="\\f01\\"
	TitleBox title_Settings_SetCondition_04,userdata(tabnum)=  "5"
	TitleBox title_Settings_SetCondition_04,userdata(tabcontrol)=  "ADC"
	TitleBox title_Settings_SetCondition_04,userdata(ResizeControlsInfo)= A"!!,H?!!#As!!#:\"!!#;]z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox title_Settings_SetCondition_04,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	TitleBox title_Settings_SetCondition_04,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	TitleBox title_Settings_SetCondition_04,frame=0
	TitleBox title_Settings_SetCondition_02,pos={272,277},size={6,13},disable=1,title="\\f01/"
	TitleBox title_Settings_SetCondition_02,userdata(tabnum)=  "5"
	TitleBox title_Settings_SetCondition_02,userdata(tabcontrol)=  "ADC"
	TitleBox title_Settings_SetCondition_02,userdata(ResizeControlsInfo)= A"!!,H?!!#A^!!#:\"!!#;]z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox title_Settings_SetCondition_02,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	TitleBox title_Settings_SetCondition_02,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	TitleBox title_Settings_SetCondition_02,frame=0
	TitleBox title_Settings_SetCondition_03,pos={240,287},size={28,13},disable=1,title="\\f01-------"
	TitleBox title_Settings_SetCondition_03,userdata(tabnum)=  "5"
	TitleBox title_Settings_SetCondition_03,userdata(tabcontrol)=  "ADC"
	TitleBox title_Settings_SetCondition_03,userdata(ResizeControlsInfo)= A"!!,H#!!#Ah!!#=C!!#;]z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox title_Settings_SetCondition_03,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	TitleBox title_Settings_SetCondition_03,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	TitleBox title_Settings_SetCondition_03,frame=0
	PopupMenu popup_MoreSettings_DeviceType,pos={33,73},size={160,21},bodyWidth=100,proc=DAP_PopMenuProc_DevTypeChk,title="Device type"
	PopupMenu popup_MoreSettings_DeviceType,help={"Step 1. Select device type. Available number of devies for selected type are printed to history window."}
	PopupMenu popup_MoreSettings_DeviceType,userdata(tabnum)=  "6"
	PopupMenu popup_MoreSettings_DeviceType,userdata(tabcontrol)=  "ADC"
	PopupMenu popup_MoreSettings_DeviceType,userdata(ResizeControlsInfo)= A"!!,E.!!#?k!!#A/!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu popup_MoreSettings_DeviceType,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu popup_MoreSettings_DeviceType,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu popup_MoreSettings_DeviceType,mode=1,popvalue="ITC16",value= #"\"ITC16;ITC18;ITC1600;ITC00;ITC16USB;ITC18USB;\""
	PopupMenu popup_moreSettings_DeviceNo,pos={60,100},size={133,21},bodyWidth=58,title="Device number"
	PopupMenu popup_moreSettings_DeviceNo,help={"Step 2. Guess a device number. 0 is a good initial guess. Device number is determined in hardware. Unfortunately, it cannot be predetermined. "}
	PopupMenu popup_moreSettings_DeviceNo,userdata(tabnum)=  "6"
	PopupMenu popup_moreSettings_DeviceNo,userdata(tabcontrol)=  "ADC"
	PopupMenu popup_moreSettings_DeviceNo,userdata(ResizeControlsInfo)= A"!!,Ej!!#@L!!#@i!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu popup_moreSettings_DeviceNo,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu popup_moreSettings_DeviceNo,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu popup_moreSettings_DeviceNo,mode=1,popvalue="0",value= #"\"0;1;2;3;4;5;6;7;8;9;10\""
	SetVariable setvar_DataAcq_OnsetDelay,pos={315,605},size={117,16},bodyWidth=35,disable=1,title="Onset delay (ms)"
	SetVariable setvar_DataAcq_OnsetDelay,help={"A global parameter that delays the onset time of a set after the initiation of data acquistion. Data acquisition start time is NOT delayed. Useful when set(s) have insufficient baseline epoch."}
	SetVariable setvar_DataAcq_OnsetDelay,userdata(tabnum)=  "0"
	SetVariable setvar_DataAcq_OnsetDelay,userdata(tabcontrol)=  "ADC"
	SetVariable setvar_DataAcq_OnsetDelay,userdata(ResizeControlsInfo)= A"!!,D/!!#C#!!#A>!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_DataAcq_OnsetDelay,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_DataAcq_OnsetDelay,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_DataAcq_OnsetDelay,limits={20,inf,1},value= _NUM:1
	SetVariable setvar_DataAcq_TerminationDelay,pos={288,626},size={144,16},bodyWidth=35,disable=1,title="Termination delay (ms)"
	SetVariable setvar_DataAcq_TerminationDelay,help={"Global set(s) termination delay. Continues recording after set sweep is complete. Useful when recorded phenomena continues after termination of final set epoch."}
	SetVariable setvar_DataAcq_TerminationDelay,userdata(tabnum)=  "0"
	SetVariable setvar_DataAcq_TerminationDelay,userdata(tabcontrol)=  "ADC"
	SetVariable setvar_DataAcq_TerminationDelay,userdata(ResizeControlsInfo)= A"!!,Go!!#C#!!#A>!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_DataAcq_TerminationDelay,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_DataAcq_TerminationDelay,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_DataAcq_TerminationDelay,value= _NUM:0
	GroupBox group_Hardware_FolderPath,pos={23,49},size={400,105},title="Lock a device to generate device folder structure"
	GroupBox group_Hardware_FolderPath,userdata(tabnum)=  "6"
	GroupBox group_Hardware_FolderPath,userdata(tabcontrol)=  "ADC"
	GroupBox group_Hardware_FolderPath,userdata(ResizeControlsInfo)= A"!!,Bq!!#?;!!#B`J,hq.z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	GroupBox group_Hardware_FolderPath,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	GroupBox group_Hardware_FolderPath,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	GroupBox group_Hardware_FolderPath,fSize=12
	Button button_SettingsPlus_PingDevice,pos={43,126},size={150,20},disable=2,proc=HSU_ButtonProc_Settings_OpenDev,title="Open device"
	Button button_SettingsPlus_PingDevice,help={"Step 3. Use to determine device number for connected device. Look for device with Ready light ON. Device numbers are determined in hardware and do not change over time. "}
	Button button_SettingsPlus_PingDevice,userdata(tabnum)=  "6"
	Button button_SettingsPlus_PingDevice,userdata(tabcontrol)=  "ADC"
	Button button_SettingsPlus_PingDevice,userdata(ResizeControlsInfo)= A"!!,Fe!!#@r!!#?s!!#=Cz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_SettingsPlus_PingDevice,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	Button button_SettingsPlus_PingDevice,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	Button button_SettingsPlus_LockDevice,pos={203,73},size={85,46},proc=HSU_ButtonProc_LockDev,title="Lock device\r selection"
	Button button_SettingsPlus_LockDevice,help={"Device must be locked to acquire data. Locking can take a few seconds (calls to amp hardware are slow)."}
	Button button_SettingsPlus_LockDevice,userdata(tabnum)=  "6"
	Button button_SettingsPlus_LockDevice,userdata(tabcontrol)=  "ADC"
	Button button_SettingsPlus_LockDevice,userdata(ResizeControlsInfo)= A"!!,H$!!#?g!!#?c!!#>Fz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_SettingsPlus_LockDevice,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	Button button_SettingsPlus_LockDevice,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	Button button_SettingsPlus_unLockDevic,pos={295,73},size={85,46},disable=2,proc=HSU_ButProc_Hrdwr_UnlckDev,title="Unlock device\r selection"
	Button button_SettingsPlus_unLockDevic,userdata(tabnum)=  "6"
	Button button_SettingsPlus_unLockDevic,userdata(tabcontrol)=  "ADC"
	Button button_SettingsPlus_unLockDevic,userdata(ResizeControlsInfo)= A"!!,H$!!#@j!!#?c!!#>Fz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_SettingsPlus_unLockDevic,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	Button button_SettingsPlus_unLockDevic,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	TitleBox title_Settings_SetCondition_1,pos={240,350},size={28,13},disable=1,title="\\f01-------"
	TitleBox title_Settings_SetCondition_1,userdata(tabnum)=  "5"
	TitleBox title_Settings_SetCondition_1,userdata(tabcontrol)=  "ADC"
	TitleBox title_Settings_SetCondition_1,userdata(ResizeControlsInfo)= A"!!,H#!!#BF!!#=C!!#;]z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox title_Settings_SetCondition_1,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	TitleBox title_Settings_SetCondition_1,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	TitleBox title_Settings_SetCondition_1,frame=0
	TitleBox title_Settings_SetCondition_2,pos={272,361},size={6,13},disable=1,title="\\f01\\"
	TitleBox title_Settings_SetCondition_2,userdata(tabnum)=  "5"
	TitleBox title_Settings_SetCondition_2,userdata(tabcontrol)=  "ADC"
	TitleBox title_Settings_SetCondition_2,userdata(ResizeControlsInfo)= A"!!,H?!!#BKJ,hjM!!#;]z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox title_Settings_SetCondition_2,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	TitleBox title_Settings_SetCondition_2,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	TitleBox title_Settings_SetCondition_2,frame=0
	TitleBox title_Settings_SetCondition_3,pos={272,340},size={6,13},disable=1,title="\\f01/"
	TitleBox title_Settings_SetCondition_3,userdata(tabnum)=  "5"
	TitleBox title_Settings_SetCondition_3,userdata(tabcontrol)=  "ADC"
	TitleBox title_Settings_SetCondition_3,userdata(ResizeControlsInfo)= A"!!,H?!!#BA!!#:\"!!#;]z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox title_Settings_SetCondition_3,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	TitleBox title_Settings_SetCondition_3,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	TitleBox title_Settings_SetCondition_3,frame=0
	CheckBox check_Settings_SetOption_5,pos={280,360},size={97,26},disable=1,title="Index to next set\ron DA with set B"
	CheckBox check_Settings_SetOption_5,help={"This mode is useful when Set B contains a single wave."}
	CheckBox check_Settings_SetOption_5,userdata(tabnum)=  "5"
	CheckBox check_Settings_SetOption_5,userdata(tabcontrol)=  "ADC"
	CheckBox check_Settings_SetOption_5,userdata(ResizeControlsInfo)= A"!!,HC!!#BN!!#@&!!#=3z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_Settings_SetOption_5,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_Settings_SetOption_5,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox check_Settings_SetOption_5,fColor=(65280,43520,0),value= 0
	TitleBox title_Settings_SetCondition1,pos={134,338},size={95,26},disable=1,title="Continue acquisition\ron DA with set B"
	TitleBox title_Settings_SetCondition1,userdata(tabnum)=  "5"
	TitleBox title_Settings_SetCondition1,userdata(tabcontrol)=  "ADC"
	TitleBox title_Settings_SetCondition1,userdata(ResizeControlsInfo)= A"!!,Fa!!#B@!!#@2!!#=kz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox title_Settings_SetCondition1,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	TitleBox title_Settings_SetCondition1,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	TitleBox title_Settings_SetCondition1,frame=0
	TitleBox title_Settings_SetCondition2,pos={136,278},size={91,26},disable=1,title="\\Z08Stop Acquisition on\rDA with Set B"
	TitleBox title_Settings_SetCondition2,userdata(tabnum)=  "5"
	TitleBox title_Settings_SetCondition2,userdata(tabcontrol)=  "ADC"
	TitleBox title_Settings_SetCondition2,userdata(ResizeControlsInfo)= A"!!,Fe!!#A_!!#@*!!#=kz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox title_Settings_SetCondition2,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	TitleBox title_Settings_SetCondition2,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	TitleBox title_Settings_SetCondition2,frame=0
	ValDisplay valdisp_DataAcq_SweepsInSet,pos={287,503},size={30,17},bodyWidth=30,disable=1
	ValDisplay valdisp_DataAcq_SweepsInSet,userdata(tabnum)=  "0"
	ValDisplay valdisp_DataAcq_SweepsInSet,userdata(tabcontrol)=  "ADC"
	ValDisplay valdisp_DataAcq_SweepsInSet,userdata(ResizeControlsInfo)= A"!!,GL!!#BdJ,hpk!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	ValDisplay valdisp_DataAcq_SweepsInSet,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	ValDisplay valdisp_DataAcq_SweepsInSet,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	ValDisplay valdisp_DataAcq_SweepsInSet,fSize=14,fStyle=0
	ValDisplay valdisp_DataAcq_SweepsInSet,valueColor=(65535,65535,65535)
	ValDisplay valdisp_DataAcq_SweepsInSet,valueBackColor=(0,0,0)
	ValDisplay valdisp_DataAcq_SweepsInSet,limits={0,0,0},barmisc={0,1000}
	ValDisplay valdisp_DataAcq_SweepsInSet,value= _NUM:1
	CheckBox Check_DataAcq1_IndexingLocked,pos={204,653},size={54,14},disable=1,proc=DAP_CheckProc_IndexingState,title="Locked"
	CheckBox Check_DataAcq1_IndexingLocked,help={"Data acquisition proceeds to next wave in DAC or TTL popup menu list"}
	CheckBox Check_DataAcq1_IndexingLocked,userdata(tabnum)=  "0"
	CheckBox Check_DataAcq1_IndexingLocked,userdata(tabcontrol)=  "ADC",value= 0
	SetVariable SetVar_DataAcq_ListRepeats,pos={178,669},size={104,16},bodyWidth=35,disable=1,proc=DAP_SetVarProc_TotSweepCount,title="Repeat List(s)"
	SetVariable SetVar_DataAcq_ListRepeats,help={"This number is set automatically at based on the number of 1d waves contained in the largest set on active DA/TTL channels"}
	SetVariable SetVar_DataAcq_ListRepeats,userdata(tabnum)=  "0"
	SetVariable SetVar_DataAcq_ListRepeats,userdata(tabcontrol)=  "ADC"
	SetVariable SetVar_DataAcq_ListRepeats,fColor=(65280,43520,0)
	SetVariable SetVar_DataAcq_ListRepeats,limits={1,inf,1},value= _NUM:1
	CheckBox check_DataAcq_IndexRandom,pos={204,636},size={58,14},disable=1,title="Random"
	CheckBox check_DataAcq_IndexRandom,help={"Randomly selects wave from set selected for DAC channel on each trial. Doesn't repeat waves."}
	CheckBox check_DataAcq_IndexRandom,userdata(tabnum)=  "0"
	CheckBox check_DataAcq_IndexRandom,userdata(tabcontrol)=  "ADC"
	CheckBox check_DataAcq_IndexRandom,fColor=(65280,43520,0),value= 0
	ValDisplay valdisp_DataAcq_SweepsActiveSet,pos={287,530},size={30,17},bodyWidth=30,disable=1
	ValDisplay valdisp_DataAcq_SweepsActiveSet,help={"Displays the number of steps in the set with the most steps on active DA and TTL channels"}
	ValDisplay valdisp_DataAcq_SweepsActiveSet,userdata(tabnum)=  "0"
	ValDisplay valdisp_DataAcq_SweepsActiveSet,userdata(tabcontrol)=  "ADC",fSize=14
	ValDisplay valdisp_DataAcq_SweepsActiveSet,fStyle=0
	ValDisplay valdisp_DataAcq_SweepsActiveSet,valueColor=(65535,65535,65535)
	ValDisplay valdisp_DataAcq_SweepsActiveSet,valueBackColor=(0,0,0)
	ValDisplay valdisp_DataAcq_SweepsActiveSet,limits={0,0,0},barmisc={0,1000}
	ValDisplay valdisp_DataAcq_SweepsActiveSet,value= _NUM:1
	SetVariable SetVar_DataAcq_TPAmplitudeIC,pos={316,384},size={105,16},disable=1,title="Amplitude IC"
	SetVariable SetVar_DataAcq_TPAmplitudeIC,userdata(tabnum)=  "0"
	SetVariable SetVar_DataAcq_TPAmplitudeIC,userdata(tabcontrol)=  "ADC"
	SetVariable SetVar_DataAcq_TPAmplitudeIC,value= _NUM:-50
	SetVariable SetVar_Hardware_VC_DA_Unit,pos={151,413},size={30,16},proc=DAP_SetVarProc_CAA
	SetVariable SetVar_Hardware_VC_DA_Unit,userdata(tabnum)=  "6"
	SetVariable SetVar_Hardware_VC_DA_Unit,userdata(tabcontrol)=  "ADC"
	SetVariable SetVar_Hardware_VC_DA_Unit,value= _STR:"mV"
	SetVariable SetVar_Hardware_IC_DA_Unit,pos={330,414},size={30,16},proc=DAP_SetVarProc_CAA
	SetVariable SetVar_Hardware_IC_DA_Unit,userdata(tabnum)=  "6"
	SetVariable SetVar_Hardware_IC_DA_Unit,userdata(tabcontrol)=  "ADC"
	SetVariable SetVar_Hardware_IC_DA_Unit,value= _STR:"pA"
	SetVariable SetVar_Hardware_VC_AD_Unit,pos={172,438},size={30,16},proc=DAP_SetVarProc_CAA
	SetVariable SetVar_Hardware_VC_AD_Unit,userdata(tabnum)=  "6"
	SetVariable SetVar_Hardware_VC_AD_Unit,userdata(tabcontrol)=  "ADC"
	SetVariable SetVar_Hardware_VC_AD_Unit,value= _STR:"pA"
	SetVariable SetVar_Hardware_IC_AD_Unit,pos={353,438},size={30,16},proc=DAP_SetVarProc_CAA
	SetVariable SetVar_Hardware_IC_AD_Unit,userdata(tabnum)=  "6"
	SetVariable SetVar_Hardware_IC_AD_Unit,userdata(tabcontrol)=  "ADC"
	SetVariable SetVar_Hardware_IC_AD_Unit,value= _STR:"mV"
	TitleBox Title_Hardware_VC_gain,pos={93,395},size={20,13},title="gain"
	TitleBox Title_Hardware_VC_gain,userdata(tabnum)=  "6"
	TitleBox Title_Hardware_VC_gain,userdata(tabcontrol)=  "ADC",frame=0
	TitleBox Title_Hardware_VC_unit,pos={169,395},size={17,13},title="unit"
	TitleBox Title_Hardware_VC_unit,userdata(tabnum)=  "6"
	TitleBox Title_Hardware_VC_unit,userdata(tabcontrol)=  "ADC",frame=0
	TitleBox Title_Hardware_IC_gain,pos={275,395},size={20,13},title="gain"
	TitleBox Title_Hardware_IC_gain,userdata(tabnum)=  "6"
	TitleBox Title_Hardware_IC_gain,userdata(tabcontrol)=  "ADC",frame=0
	TitleBox Title_Hardware_IC_unit,pos={331,395},size={17,13},title="unit"
	TitleBox Title_Hardware_IC_unit,userdata(tabnum)=  "6"
	TitleBox Title_Hardware_IC_unit,userdata(tabcontrol)=  "ADC",frame=0
	SetVariable Unit_DA_00,pos={92,75},size={30,16},disable=1,help={"hello"}
	SetVariable Unit_DA_00,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	SetVariable Unit_DA_00,limits={0,inf,1},value= _STR:""
	TitleBox Title_DA_Unit,pos={95,50},size={23,13},disable=1,title="Unit"
	TitleBox Title_DA_Unit,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	TitleBox Title_DA_Unit,frame=0,fStyle=1
	SetVariable Unit_DA_01,pos={91,120},size={30,16},disable=1,help={"hello"}
	SetVariable Unit_DA_01,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	SetVariable Unit_DA_01,limits={0,inf,1},value= _STR:""
	SetVariable Unit_DA_02,pos={91,167},size={30,16},disable=1,help={"hello"}
	SetVariable Unit_DA_02,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	SetVariable Unit_DA_02,limits={0,inf,1},value= _STR:""
	SetVariable Unit_DA_03,pos={91,214},size={30,16},disable=1,help={"hello"}
	SetVariable Unit_DA_03,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	SetVariable Unit_DA_03,limits={0,inf,1},value= _STR:""
	SetVariable Unit_DA_04,pos={91,258},size={30,16},disable=1,help={"hello"}
	SetVariable Unit_DA_04,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	SetVariable Unit_DA_04,limits={0,inf,1},value= _STR:""
	SetVariable Unit_DA_05,pos={91,305},size={30,16},disable=1,help={"hello"}
	SetVariable Unit_DA_05,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	SetVariable Unit_DA_05,limits={0,inf,1},value= _STR:""
	SetVariable Unit_DA_06,pos={91,352},size={30,16},disable=1,help={"hello"}
	SetVariable Unit_DA_06,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	SetVariable Unit_DA_06,limits={0,inf,1},value= _STR:""
	SetVariable Unit_DA_07,pos={91,399},size={30,16},disable=1,help={"hello"}
	SetVariable Unit_DA_07,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	SetVariable Unit_DA_07,limits={0,inf,1},value= _STR:""
	SetVariable Unit_AD_00,pos={106,74},size={40,16},disable=1,title="V/"
	SetVariable Unit_AD_00,help={"hello"},userdata(tabnum)=  "2"
	SetVariable Unit_AD_00,userdata(tabcontrol)=  "ADC"
	SetVariable Unit_AD_00,limits={0,inf,1},value= _STR:""
	SetVariable Unit_AD_01,pos={106,120},size={40,16},disable=1,title="V/"
	SetVariable Unit_AD_01,help={"hello"},userdata(tabnum)=  "2"
	SetVariable Unit_AD_01,userdata(tabcontrol)=  "ADC"
	SetVariable Unit_AD_01,limits={0,inf,1},value= _STR:""
	SetVariable Unit_AD_02,pos={106,166},size={40,16},disable=1,title="V/"
	SetVariable Unit_AD_02,help={"hello"},userdata(tabnum)=  "2"
	SetVariable Unit_AD_02,userdata(tabcontrol)=  "ADC"
	SetVariable Unit_AD_02,limits={0,inf,1},value= _STR:""
	SetVariable Unit_AD_03,pos={106,212},size={40,16},disable=1,title="V/"
	SetVariable Unit_AD_03,help={"hello"},userdata(tabnum)=  "2"
	SetVariable Unit_AD_03,userdata(tabcontrol)=  "ADC"
	SetVariable Unit_AD_03,limits={0,inf,1},value= _STR:""
	SetVariable Unit_AD_04,pos={106,259},size={40,16},disable=1,title="V/"
	SetVariable Unit_AD_04,help={"hello"},userdata(tabnum)=  "2"
	SetVariable Unit_AD_04,userdata(tabcontrol)=  "ADC"
	SetVariable Unit_AD_04,limits={0,inf,1},value= _STR:""
	SetVariable Unit_AD_05,pos={106,305},size={40,16},disable=1,title="V/"
	SetVariable Unit_AD_05,help={"hello"},userdata(tabnum)=  "2"
	SetVariable Unit_AD_05,userdata(tabcontrol)=  "ADC"
	SetVariable Unit_AD_05,limits={0,inf,1},value= _STR:""
	SetVariable Unit_AD_06,pos={106,351},size={40,16},disable=1,title="V/"
	SetVariable Unit_AD_06,help={"hello"},userdata(tabnum)=  "2"
	SetVariable Unit_AD_06,userdata(tabcontrol)=  "ADC"
	SetVariable Unit_AD_06,limits={0,inf,1},value= _STR:""
	SetVariable Unit_AD_07,pos={106,398},size={40,16},disable=1,title="V/"
	SetVariable Unit_AD_07,help={"hello"},userdata(tabnum)=  "2"
	SetVariable Unit_AD_07,userdata(tabcontrol)=  "ADC"
	SetVariable Unit_AD_07,limits={0,inf,1},value= _STR:""
	SetVariable Unit_AD_08,pos={278,74},size={40,16},disable=1,title="V/"
	SetVariable Unit_AD_08,help={"hello"},userdata(tabnum)=  "2"
	SetVariable Unit_AD_08,userdata(tabcontrol)=  "ADC"
	SetVariable Unit_AD_08,limits={0,inf,1},value= _STR:""
	SetVariable Unit_AD_09,pos={278,120},size={40,16},disable=1,title="V/"
	SetVariable Unit_AD_09,help={"hello"},userdata(tabnum)=  "2"
	SetVariable Unit_AD_09,userdata(tabcontrol)=  "ADC"
	SetVariable Unit_AD_09,limits={0,inf,1},value= _STR:""
	SetVariable Unit_AD_10,pos={278,166},size={40,16},disable=1,title="V/"
	SetVariable Unit_AD_10,help={"hello"},userdata(tabnum)=  "2"
	SetVariable Unit_AD_10,userdata(tabcontrol)=  "ADC"
	SetVariable Unit_AD_10,limits={0,inf,1},value= _STR:""
	SetVariable Unit_AD_11,pos={278,212},size={40,16},disable=1,title="V/"
	SetVariable Unit_AD_11,help={"hello"},userdata(tabnum)=  "2"
	SetVariable Unit_AD_11,userdata(tabcontrol)=  "ADC"
	SetVariable Unit_AD_11,limits={0,inf,1},value= _STR:""
	SetVariable Unit_AD_12,pos={278,259},size={40,16},disable=1,title="V/"
	SetVariable Unit_AD_12,help={"hello"},userdata(tabnum)=  "2"
	SetVariable Unit_AD_12,userdata(tabcontrol)=  "ADC"
	SetVariable Unit_AD_12,limits={0,inf,1},value= _STR:""
	SetVariable Unit_AD_13,pos={278,305},size={40,16},disable=1,title="V/"
	SetVariable Unit_AD_13,help={"hello"},userdata(tabnum)=  "2"
	SetVariable Unit_AD_13,userdata(tabcontrol)=  "ADC"
	SetVariable Unit_AD_13,limits={0,inf,1},value= _STR:""
	SetVariable Unit_AD_14,pos={278,351},size={40,16},disable=1,title="V/"
	SetVariable Unit_AD_14,help={"hello"},userdata(tabnum)=  "2"
	SetVariable Unit_AD_14,userdata(tabcontrol)=  "ADC"
	SetVariable Unit_AD_14,limits={0,inf,1},value= _STR:""
	SetVariable Unit_AD_15,pos={278,398},size={40,16},disable=1,title="V/"
	SetVariable Unit_AD_15,help={"hello"},userdata(tabnum)=  "2"
	SetVariable Unit_AD_15,userdata(tabcontrol)=  "ADC"
	SetVariable Unit_AD_15,limits={0,inf,1},value= _STR:""
	TitleBox Title_AD_Unit,pos={122,50},size={23,13},disable=1,title="Unit"
	TitleBox Title_AD_Unit,userdata(tabnum)=  "2",userdata(tabcontrol)=  "ADC"
	TitleBox Title_AD_Unit,frame=0,fStyle=1
	TitleBox Title_AD_Gain,pos={61,50},size={26,13},disable=1,title="Gain"
	TitleBox Title_AD_Gain,userdata(tabnum)=  "2",userdata(tabcontrol)=  "ADC"
	TitleBox Title_AD_Gain,frame=0,fStyle=1
	TitleBox Title_AD_Channel,pos={23,50},size={17,13},disable=1,title="AD"
	TitleBox Title_AD_Channel,userdata(tabnum)=  "2",userdata(tabcontrol)=  "ADC"
	TitleBox Title_AD_Channel,frame=0,fStyle=1
	TitleBox Title_AD_Channel1,pos={195,50},size={17,13},disable=1,title="AD"
	TitleBox Title_AD_Channel1,userdata(tabnum)=  "2",userdata(tabcontrol)=  "ADC"
	TitleBox Title_AD_Channel1,frame=0,fStyle=1
	TitleBox Title_AD_Gain1,pos={233,50},size={26,13},disable=1,title="Gain"
	TitleBox Title_AD_Gain1,userdata(tabnum)=  "2",userdata(tabcontrol)=  "ADC"
	TitleBox Title_AD_Gain1,frame=0,fStyle=1
	TitleBox Title_AD_Unit1,pos={294,50},size={23,13},disable=1,title="Unit"
	TitleBox Title_AD_Unit1,userdata(tabnum)=  "2",userdata(tabcontrol)=  "ADC"
	TitleBox Title_AD_Unit1,frame=0,fStyle=1
	TitleBox Title_Hardware_VC_DA_Div,pos={185,415},size={15,13},title="/ V"
	TitleBox Title_Hardware_VC_DA_Div,userdata(tabnum)=  "6"
	TitleBox Title_Hardware_VC_DA_Div,userdata(tabcontrol)=  "ADC",frame=0
	TitleBox Title_Hardware_IC_DA_Div,pos={362,415},size={15,13},title="/ V"
	TitleBox Title_Hardware_IC_DA_Div,userdata(tabnum)=  "6"
	TitleBox Title_Hardware_IC_DA_Div,userdata(tabcontrol)=  "ADC",frame=0
	TitleBox Title_Hardware_IC_AD_Div,pos={335,440},size={15,13},title="V /"
	TitleBox Title_Hardware_IC_AD_Div,userdata(tabnum)=  "6"
	TitleBox Title_Hardware_IC_AD_Div,userdata(tabcontrol)=  "ADC",frame=0
	TitleBox Title_Hardware_IC_AD_Div1,pos={153,440},size={15,13},title="V /"
	TitleBox Title_Hardware_IC_AD_Div1,userdata(tabnum)=  "6"
	TitleBox Title_Hardware_IC_AD_Div1,userdata(tabcontrol)=  "ADC",frame=0
	GroupBox GroupBox_Hardware_Associations,pos={23,305},size={400,300},title="DAC Channel and Device Associations"
	GroupBox GroupBox_Hardware_Associations,userdata(tabnum)=  "6"
	GroupBox GroupBox_Hardware_Associations,userdata(tabcontrol)=  "ADC"
	GroupBox group_Settings_DatAcq,pos={20,169},size={425,223},disable=1,title="Data Acquisition"
	GroupBox group_Settings_DatAcq,userdata(tabnum)=  "5"
	GroupBox group_Settings_DatAcq,userdata(tabcontrol)=  "ADC"
	GroupBox group_Settings_Asynch,pos={21,401},size={425,90},disable=1,title="Asynchronous"
	GroupBox group_Settings_Asynch,userdata(tabnum)=  "5"
	GroupBox group_Settings_Asynch,userdata(tabcontrol)=  "ADC"
	GroupBox group_Settings_TP,pos={21,68},size={425,90},disable=1,title="Test Pulse"
	GroupBox group_Settings_TP,userdata(tabnum)=  "5",userdata(tabcontrol)=  "ADC"
	GroupBox group_Settings_Asynch1,pos={21,498},size={425,40},disable=1,title="Oscilloscope"
	GroupBox group_Settings_Asynch1,userdata(tabnum)=  "5"
	GroupBox group_Settings_Asynch1,userdata(tabcontrol)=  "ADC"
	GroupBox group_DataAcq_ClampMode,pos={30,39},size={422,320},disable=1,title="Headstage"
	GroupBox group_DataAcq_ClampMode,userdata(tabnum)=  "0"
	GroupBox group_DataAcq_ClampMode,userdata(tabcontrol)=  "ADC"
	GroupBox group_DataAcq_ClampMode1,pos={30,366},size={422,90},disable=1,title="Test Pulse"
	GroupBox group_DataAcq_ClampMode1,userdata(tabnum)=  "0"
	GroupBox group_DataAcq_ClampMode1,userdata(tabcontrol)=  "ADC"
	GroupBox group_DataAcq_ClampMode2,pos={30,462},size={422,115},disable=1,title="Status Information"
	GroupBox group_DataAcq_ClampMode2,userdata(tabnum)=  "0"
	GroupBox group_DataAcq_ClampMode2,userdata(tabcontrol)=  "ADC"
	TitleBox title_DataAcq_NextSweep,pos={200,477},size={72,16},disable=1,title="Next Sweep"
	TitleBox title_DataAcq_NextSweep,userdata(tabnum)=  "0"
	TitleBox title_DataAcq_NextSweep,userdata(tabcontrol)=  "ADC",fSize=14,frame=0
	TitleBox title_DataAcq_NextSweep,fStyle=0
	TitleBox title_DataAcq_NextSweep1,pos={324,504},size={83,16},disable=1,title="Total Sweeps"
	TitleBox title_DataAcq_NextSweep1,userdata(tabnum)=  "0"
	TitleBox title_DataAcq_NextSweep1,userdata(tabcontrol)=  "ADC",fSize=14,frame=0
	TitleBox title_DataAcq_NextSweep1,fStyle=0
	TitleBox title_DataAcq_NextSweep2,pos={324,531},size={100,16},disable=1,title="Set Max Sweeps"
	TitleBox title_DataAcq_NextSweep2,userdata(tabnum)=  "0"
	TitleBox title_DataAcq_NextSweep2,userdata(tabcontrol)=  "ADC",fSize=14,frame=0
	TitleBox title_DataAcq_NextSweep2,fStyle=0
	TitleBox title_DataAcq_NextSweep3,pos={171,556},size={128,16},disable=1,title="Sampling Interval (µs)"
	TitleBox title_DataAcq_NextSweep3,userdata(tabnum)=  "0"
	TitleBox title_DataAcq_NextSweep3,userdata(tabcontrol)=  "ADC",fSize=14,frame=0
	TitleBox title_DataAcq_NextSweep3,fStyle=0
	GroupBox group_DataAcq_DataAcq,pos={30,585},size={422,175},disable=1,title="Data Acquisition"
	GroupBox group_DataAcq_DataAcq,userdata(tabnum)=  "0"
	GroupBox group_DataAcq_DataAcq,userdata(tabcontrol)=  "ADC"
	GroupBox group_Hardware_Yoke,pos={24,155},size={400,145},title="Yoke"
	GroupBox group_Hardware_Yoke,help={"Yoking is only available for >1 ITC1600, however, It is not a requirement for the use of multiple ITC1600s asyncronously."}
	GroupBox group_Hardware_Yoke,userdata(tabnum)=  "6",userdata(tabcontrol)=  "ADC"
	GroupBox group_Hardware_Yoke,fSize=12
	Button button_Hardware_Lead1600,pos={29,195},size={80,21},disable=3,proc=DAP_ButtonProc_Lead,title="Lead"
	Button button_Hardware_Lead1600,help={"For ITC1600 devices only. Sets locked ITC device as the lead. User must now assign follower devices."}
	Button button_Hardware_Lead1600,userdata(tabnum)=  "6"
	Button button_Hardware_Lead1600,userdata(tabcontrol)=  "ADC"
	PopupMenu popup_Hardware_AvailITC1600s,pos={29,240},size={110,21},bodyWidth=110,disable=3,title="Locked ITC1600s"
	PopupMenu popup_Hardware_AvailITC1600s,userdata(tabnum)=  "6"
	PopupMenu popup_Hardware_AvailITC1600s,userdata(tabcontrol)=  "ADC"
	PopupMenu popup_Hardware_AvailITC1600s,mode=0,value= #"DAP_ListOfITCDevices()"
	Button button_Hardware_AddFollower,pos={141,240},size={80,21},disable=3,proc=DAP_ButtonProc_Follow,title="Follow"
	Button button_Hardware_AddFollower,help={"For ITC1600 devices only. Sets locked ITC device as a follower. Select leader from other locked ITC1600s panel. This will disable data aquistion directly from this panel."}
	Button button_Hardware_AddFollower,userdata(tabnum)=  "6"
	Button button_Hardware_AddFollower,userdata(tabcontrol)=  "ADC"
	TitleBox title_hardware_1600inst,pos={29,176},size={220,13},disable=3,title="To yoke devices go to panel: ITC1600_Dev_0"
	TitleBox title_hardware_1600inst,help={"If the device is designated to follow, the test pulse and data aquisition will be triggered from the lead panel."}
	TitleBox title_hardware_1600inst,userdata(tabnum)=  "6"
	TitleBox title_hardware_1600inst,userdata(tabcontrol)=  "ADC",frame=0
	Button button_Hardware_Independent,pos={111,195},size={80,21},disable=3,proc=DAP_ButtonProc_Independent,title="Independent"
	Button button_Hardware_Independent,help={"For ITC1600 devices only. Sets locked ITC device as the lead. User must now assign follower devices."}
	Button button_Hardware_Independent,userdata(tabnum)=  "6"
	Button button_Hardware_Independent,userdata(tabcontrol)=  "ADC"
	SetVariable setvar_Hardware_Status,pos={145,763},size={196,16},bodyWidth=99,title="ITC DAC Status:"
	SetVariable setvar_Hardware_Status,frame=0,fStyle=1,fColor=(65280,0,0)
	SetVariable setvar_Hardware_Status,valueBackColor=(60928,60928,60928)
	SetVariable setvar_Hardware_Status,value= _STR:"Independent",noedit= 1
	TitleBox title_hardware_Follow,pos={29,222},size={163,13},disable=3,title="Assign ITC1600 DACs as followers"
	TitleBox title_hardware_Follow,help={"If the device is designated to follow, the test pulse and data aquisition will be triggered from the lead panel."}
	TitleBox title_hardware_Follow,userdata(tabnum)=  "6"
	TitleBox title_hardware_Follow,userdata(tabcontrol)=  "ADC",frame=0
	SetVariable setvar_Hardware_YokeList,pos={29,272},size={300,16},title="Yoked DACs:"
	SetVariable setvar_Hardware_YokeList,userdata(tabnum)=  "6"
	SetVariable setvar_Hardware_YokeList,userdata(tabcontrol)=  "ADC"
	SetVariable setvar_Hardware_YokeList,labelBack=(60928,60928,60928),frame=0
	SetVariable setvar_Hardware_YokeList,value= _STR:"Device is not yokeable",noedit= 1
	Button button_Hardware_RemoveYoke,pos={335,240},size={80,21},disable=3,proc=DAP_ButtonProc_YokeRelease,title="Release"
	Button button_Hardware_RemoveYoke,userdata(tabnum)=  "6"
	Button button_Hardware_RemoveYoke,userdata(tabcontrol)=  "ADC"
	PopupMenu popup_Hardware_YokedDACs,pos={223,240},size={110,21},bodyWidth=110,disable=3,title="Yoked ITC1600s"
	PopupMenu popup_Hardware_YokedDACs,userdata(tabnum)=  "6"
	PopupMenu popup_Hardware_YokedDACs,userdata(tabcontrol)=  "ADC"
	PopupMenu popup_Hardware_YokedDACs,mode=0,value= #"DAP_GUIListOfYokedDevices()"
	TitleBox title_hardware_Release,pos={225,222},size={152,13},disable=3,title="Release follower ITC1600 DACs"
	TitleBox title_hardware_Release,help={"If the device is designated to follow, the test pulse and data aquisition will be triggered from the lead panel."}
	TitleBox title_hardware_Release,userdata(tabnum)=  "6"
	TitleBox title_hardware_Release,userdata(tabcontrol)=  "ADC",frame=0
	TitleBox Title_DataAcq_Hold_IC,pos={70,174},size={58,13},disable=1,title="Holding (pA)"
	TitleBox Title_DataAcq_Hold_IC,userdata(tabnum)=  "1"
	TitleBox Title_DataAcq_Hold_IC,userdata(tabcontrol)=  "tab_DataAcq_Amp",frame=0
	TitleBox Title_DataAcq_Bridge,pos={42,193},size={100,15},disable=1,title="Bridge Balance (M\\F'Symbol'W\\F]0)"
	TitleBox Title_DataAcq_Bridge,userdata(tabnum)=  "1"
	TitleBox Title_DataAcq_Bridge,userdata(tabcontrol)=  "tab_DataAcq_Amp",frame=0
	SetVariable setvar_DataAcq_Hold_IC,pos={152,173},size={36,16},disable=1,proc=DAP_SetVarProc_AmpCntrls
	SetVariable setvar_DataAcq_Hold_IC,userdata(tabnum)=  "1"
	SetVariable setvar_DataAcq_Hold_IC,userdata(tabcontrol)=  "tab_DataAcq_Amp"
	SetVariable setvar_DataAcq_Hold_IC,value= _NUM:0
	SetVariable setvar_DataAcq_BB,pos={152,192},size={36,16},disable=1,proc=DAP_SetVarProc_AmpCntrls
	SetVariable setvar_DataAcq_BB,userdata(tabnum)=  "1"
	SetVariable setvar_DataAcq_BB,userdata(tabcontrol)=  "tab_DataAcq_Amp"
	SetVariable setvar_DataAcq_BB,limits={0,inf,1},value= _NUM:0
	SetVariable setvar_DataAcq_CN,pos={152,211},size={36,16},disable=1,proc=DAP_SetVarProc_AmpCntrls
	SetVariable setvar_DataAcq_CN,userdata(tabnum)=  "1"
	SetVariable setvar_DataAcq_CN,userdata(tabcontrol)=  "tab_DataAcq_Amp"
	SetVariable setvar_DataAcq_CN,limits={-8,16,1},value= _NUM:0
	CheckBox check_DatAcq_HoldEnable,pos={195,174},size={51,14},disable=1,proc=DAP_CheckProc_AmpCntrls,title="Enable"
	CheckBox check_DatAcq_HoldEnable,userdata(tabnum)=  "1"
	CheckBox check_DatAcq_HoldEnable,userdata(tabcontrol)=  "tab_DataAcq_Amp"
	CheckBox check_DatAcq_HoldEnable,value= 0
	CheckBox check_DatAcq_BBEnable,pos={195,193},size={51,14},disable=1,proc=DAP_CheckProc_AmpCntrls,title="Enable"
	CheckBox check_DatAcq_BBEnable,userdata(tabnum)=  "1"
	CheckBox check_DatAcq_BBEnable,userdata(tabcontrol)=  "tab_DataAcq_Amp",value= 0
	CheckBox check_DatAcq_CNEnable,pos={195,212},size={51,14},disable=1,proc=DAP_CheckProc_AmpCntrls,title="Enable"
	CheckBox check_DatAcq_CNEnable,userdata(tabnum)=  "1"
	CheckBox check_DatAcq_CNEnable,userdata(tabcontrol)=  "tab_DataAcq_Amp",value= 0
	TitleBox Title_DataAcq_CN,pos={41,211},size={107,13},disable=1,title="Cap Neutralization (pF)"
	TitleBox Title_DataAcq_CN,userdata(tabnum)=  "1"
	TitleBox Title_DataAcq_CN,userdata(tabcontrol)=  "tab_DataAcq_Amp",frame=0
	Slider slider_DataAcq_ActiveHeadstage,pos={145,128},size={255,19},disable=1,proc=DAP_SliderProc_MIESHeadStage
	Slider slider_DataAcq_ActiveHeadstage,userdata(tabnum)=  "0"
	Slider slider_DataAcq_ActiveHeadstage,userdata(tabcontrol)=  "ADC"
	Slider slider_DataAcq_ActiveHeadstage,labelBack=(60928,60928,60928)
	Slider slider_DataAcq_ActiveHeadstage,limits={0,7,1},value= 0,side= 2,vert= 0,ticks= 0,thumbColor= (43520,43520,43520)
	TabControl tab_DataAcq_Amp,pos={38,148},size={408,110},disable=1,proc=ACL_DisplayTab
	TabControl tab_DataAcq_Amp,help={"Entries into these tabs update the MCC only when in the active mode. On mode switching, the parameters will be passed to the MCC."}
	TabControl tab_DataAcq_Amp,userdata(tabnum)=  "0",userdata(tabcontrol)=  "ADC"
	TabControl tab_DataAcq_Amp,userdata(currenttab)=  "0"
	TabControl tab_DataAcq_Amp,labelBack=(60928,60928,60928),fSize=10
	TabControl tab_DataAcq_Amp,tabLabel(0)="V-Clamp",tabLabel(1)="I-Clamp"
	TabControl tab_DataAcq_Amp,tabLabel(2)="I = 0",value= 0
	SetVariable setvar_DataAcq_AutoBiasV,pos={309,188},size={80,16},disable=1,proc=DAP_SetVarProc_AmpCntrls,title="Vm (mV)"
	SetVariable setvar_DataAcq_AutoBiasV,userdata(tabnum)=  "1"
	SetVariable setvar_DataAcq_AutoBiasV,userdata(tabcontrol)=  "tab_DataAcq_Amp"
	SetVariable setvar_DataAcq_AutoBiasV,value= _NUM:0
	CheckBox check_DataAcq_AutoBias,pos={304,171},size={63,14},disable=1,proc=DAP_CheckProc_AmpCntrls,title="Auto Bias"
	CheckBox check_DataAcq_AutoBias,help={"Just prior to a sweep the Vm is checked and the bias current is adjusted to maintain desired Vm."}
	CheckBox check_DataAcq_AutoBias,userdata(tabnum)=  "1"
	CheckBox check_DataAcq_AutoBias,userdata(tabcontrol)=  "tab_DataAcq_Amp"
	CheckBox check_DataAcq_AutoBias,value= 0,side= 1
	SetVariable setvar_DataAcq_IbiasMax,pos={310,209},size={120,20},disable=1,proc=DAP_SetVarProc_AmpCntrls,title="max I \\Bbias\\M (pA) ±"
	SetVariable setvar_DataAcq_IbiasMax,userdata(tabcontrol)=  "tab_DataAcq_Amp"
	SetVariable setvar_DataAcq_IbiasMax,userdata(tabnum)=  "1",value= _NUM:0
	SetVariable setvar_DataAcq_AutoBiasVrange,pos={391,188},size={46,16},disable=1,proc=DAP_SetVarProc_AmpCntrls,title="±"
	SetVariable setvar_DataAcq_AutoBiasVrange,userdata(tabcontrol)=  "tab_DataAcq_Amp"
	SetVariable setvar_DataAcq_AutoBiasVrange,userdata(tabnum)=  "1"
	SetVariable setvar_DataAcq_AutoBiasVrange,limits={0,inf,1},value= _NUM:0
	TitleBox Title_DataAcq_Hold_VC,pos={1,209},size={50,20},disable=1
	TitleBox Title_DataAcq_Hold_VC,userdata(tabnum)=  "0"
	TitleBox Title_DataAcq_Hold_VC,userdata(tabcontrol)=  "tab_DataAcq_Amp",frame=0
	SetVariable setvar_DataAcq_Hold_VC,pos={135,171},size={36,16},disable=1,proc=DAP_SetVarProc_AmpCntrls
	SetVariable setvar_DataAcq_Hold_VC,userdata(tabnum)=  "0"
	SetVariable setvar_DataAcq_Hold_VC,userdata(tabcontrol)=  "tab_DataAcq_Amp"
	SetVariable setvar_DataAcq_Hold_VC,value= _NUM:0
	TitleBox Title_DataAcq_PipOffset_VC,pos={267,173},size={88,13},disable=1,title="Pipette Offset (mV)"
	TitleBox Title_DataAcq_PipOffset_VC,userdata(tabnum)=  "0"
	TitleBox Title_DataAcq_PipOffset_VC,userdata(tabcontrol)=  "tab_DataAcq_Amp"
	TitleBox Title_DataAcq_PipOffset_VC,frame=0
	SetVariable setvar_DataAcq_PipetteOffset_VC,pos={359,172},size={36,16},disable=1,proc=DAP_SetVarProc_AmpCntrls
	SetVariable setvar_DataAcq_PipetteOffset_VC,userdata(tabnum)=  "0"
	SetVariable setvar_DataAcq_PipetteOffset_VC,userdata(tabcontrol)=  "tab_DataAcq_Amp"
	SetVariable setvar_DataAcq_PipetteOffset_VC,value= _NUM:0
	Button button_DataAcq_AutoPipOffset_VC,pos={398,172},size={40,15},disable=1,proc=DAP_ButtonProc_AmpCntrls,title="Auto"
	Button button_DataAcq_AutoPipOffset_VC,help={"Automatically calculate the pipette offset"}
	Button button_DataAcq_AutoPipOffset_VC,userdata(tabnum)=  "0"
	Button button_DataAcq_AutoPipOffset_VC,userdata(tabcontrol)=  "tab_DataAcq_Amp"
	GroupBox group_pipette_offset,pos={261,168},size={179,24},disable=1
	GroupBox group_pipette_offset,userdata(tabnum)=  "0"
	GroupBox group_pipette_offset,userdata(tabcontrol)=  "tab_DataAcq_Amp"
	CheckBox check_DatAcq_HoldEnableVC,pos={178,172},size={51,14},disable=1,proc=DAP_CheckProc_AmpCntrls,title="Enable"
	CheckBox check_DatAcq_HoldEnableVC,userdata(tabnum)=  "0"
	CheckBox check_DatAcq_HoldEnableVC,userdata(tabcontrol)=  "tab_DataAcq_Amp"
	CheckBox check_DatAcq_HoldEnableVC,value= 0
	SetVariable setvar_DataAcq_WCR,pos={136,211},size={60,18},disable=1,proc=DAP_SetVarProc_AmpCntrls,title="M\\F'Symbol'W"
	SetVariable setvar_DataAcq_WCR,userdata(tabnum)=  "0"
	SetVariable setvar_DataAcq_WCR,userdata(tabcontrol)=  "tab_DataAcq_Amp"
	SetVariable setvar_DataAcq_WCR,value= _NUM:0
	CheckBox check_DatAcq_WholeCellEnable,pos={82,191},size={16,14},disable=1,proc=DAP_CheckProc_AmpCntrls,title=""
	CheckBox check_DatAcq_WholeCellEnable,userdata(tabnum)=  "0"
	CheckBox check_DatAcq_WholeCellEnable,userdata(tabcontrol)=  "tab_DataAcq_Amp"
	CheckBox check_DatAcq_WholeCellEnable,value= 0
	SetVariable setvar_DataAcq_WCC,pos={73,212},size={60,16},disable=1,proc=DAP_SetVarProc_AmpCntrls,title="pF"
	SetVariable setvar_DataAcq_WCC,userdata(tabnum)=  "0"
	SetVariable setvar_DataAcq_WCC,userdata(tabcontrol)=  "tab_DataAcq_Amp"
	SetVariable setvar_DataAcq_WCC,limits={1,inf,1},value= _NUM:0
	Button button_DataAcq_WCAuto,pos={116,231},size={40,15},disable=1,title="Auto"
	Button button_DataAcq_WCAuto,userdata(tabnum)=  "0"
	Button button_DataAcq_WCAuto,userdata(tabcontrol)=  "tab_DataAcq_Amp"
	GroupBox group_DataAcq_RsCompensation,pos={210,192},size={168,61},disable=1,title="       Rs Compensation"
	GroupBox group_DataAcq_RsCompensation,userdata(tabnum)=  "0"
	GroupBox group_DataAcq_RsCompensation,userdata(tabcontrol)=  "tab_DataAcq_Amp"
	CheckBox check_DatAcq_RsCompEnable,pos={232,191},size={16,14},disable=1,proc=DAP_CheckProc_AmpCntrls,title=""
	CheckBox check_DatAcq_RsCompEnable,userdata(tabnum)=  "0"
	CheckBox check_DatAcq_RsCompEnable,userdata(tabcontrol)=  "tab_DataAcq_Amp"
	CheckBox check_DatAcq_RsCompEnable,value= 0
	SetVariable setvar_DataAcq_RsCorr,pos={215,212},size={104,16},disable=1,proc=DAP_SetVarProc_AmpCntrls,title="Correction (%)"
	SetVariable setvar_DataAcq_RsCorr,userdata(tabnum)=  "0"
	SetVariable setvar_DataAcq_RsCorr,userdata(tabcontrol)=  "tab_DataAcq_Amp"
	SetVariable setvar_DataAcq_RsCorr,limits={0,100,1},value= _NUM:0
	SetVariable setvar_DataAcq_RsPred,pos={216,232},size={103,16},disable=1,proc=DAP_SetVarProc_AmpCntrls,title="Prediction (%)"
	SetVariable setvar_DataAcq_RsPred,userdata(tabnum)=  "0"
	SetVariable setvar_DataAcq_RsPred,userdata(tabcontrol)=  "tab_DataAcq_Amp"
	SetVariable setvar_DataAcq_RsPred,limits={0,100,1},value= _NUM:0
	Button button_DataAcq_FastComp_VC,pos={388,204},size={45,20},disable=1,proc=DAP_ButtonProc_AmpCntrls,title="Cp Fast"
	Button button_DataAcq_FastComp_VC,help={"Activates MCC auto fast capacitance compensation"}
	Button button_DataAcq_FastComp_VC,userdata(tabnum)=  "0"
	Button button_DataAcq_FastComp_VC,userdata(tabcontrol)=  "tab_DataAcq_Amp"
	Button button_Hardware_AutoGainAndUnit,pos={385,409},size={31,47},proc=DAP_ButtonProc_AutoFillGain,title="Auto\rFill"
	Button button_Hardware_AutoGainAndUnit,help={"A amplifier channel needs to be selected from the popup menu prior to auto filling gain and units."}
	Button button_Hardware_AutoGainAndUnit,userdata(tabnum)=  "6"
	Button button_Hardware_AutoGainAndUnit,userdata(tabcontrol)=  "ADC"
	CheckBox check_DataAcq_IzeroEnable,pos={52,185},size={51,14},disable=1,proc=DAP_CheckProc_AmpCntrls,title="Enable"
	CheckBox check_DataAcq_IzeroEnable,userdata(tabnum)=  "2"
	CheckBox check_DataAcq_IzeroEnable,userdata(tabcontrol)=  "tab_DataAcq_Amp"
	CheckBox check_DataAcq_IzeroEnable,fColor=(65280,43520,0),value= 0
	CheckBox Check_Settings_AlarmPauseAcq,pos={34,443},size={166,14},disable=1,title="\\JCPause acquisition in alarm state"
	CheckBox Check_Settings_AlarmPauseAcq,help={"Pauses acquisition until user continues or cancels acquisition"}
	CheckBox Check_Settings_AlarmPauseAcq,userdata(tabnum)=  "5"
	CheckBox Check_Settings_AlarmPauseAcq,userdata(tabcontrol)=  "ADC"
	CheckBox Check_Settings_AlarmPauseAcq,fColor=(65280,43520,0),value= 0
	CheckBox Check_Settings_AlarmAutoRepeat,pos={34,464},size={250,14},disable=1,title="\\JCAuto repeat last sweep until alarm state is cleared"
	CheckBox Check_Settings_AlarmAutoRepeat,help={"Turns on TTL pulse at onset of sweep"}
	CheckBox Check_Settings_AlarmAutoRepeat,userdata(tabnum)=  "5"
	CheckBox Check_Settings_AlarmAutoRepeat,userdata(tabcontrol)=  "ADC"
	CheckBox Check_Settings_AlarmAutoRepeat,fColor=(65280,43520,0),value= 0
	GroupBox group_Settings_Amplifier,pos={21,543},size={425,80},disable=1,title="Amplifier"
	GroupBox group_Settings_Amplifier,userdata(tabnum)=  "5"
	GroupBox group_Settings_Amplifier,userdata(tabcontrol)=  "ADC"
	CheckBox check_Settings_AmpMCCdefault,pos={34,566},size={174,14},disable=1,proc=DAP_CheckProc_ShowScopeWin,title="Default to MCC parameter values"
	CheckBox check_Settings_AmpMCCdefault,help={"Enable the scope window to view ongoing acquistion"}
	CheckBox check_Settings_AmpMCCdefault,userdata(tabnum)=  "5"
	CheckBox check_Settings_AmpMCCdefault,userdata(tabcontrol)=  "ADC"
	CheckBox check_Settings_AmpMCCdefault,fColor=(65280,43520,0),value= 0
	CheckBox check_Settings_AmpMIESdefault,pos={34,586},size={249,14},disable=1,proc=DAP_CheckProc_ShowScopeWin,title="Default amplifier parameter values stored in MIES"
	CheckBox check_Settings_AmpMIESdefault,help={"Enable the scope window to view ongoing acquistion"}
	CheckBox check_Settings_AmpMIESdefault,userdata(tabnum)=  "5"
	CheckBox check_Settings_AmpMIESdefault,userdata(tabcontrol)=  "ADC"
	CheckBox check_Settings_AmpMIESdefault,fColor=(65280,43520,0),value= 0
	CheckBox check_DataAcq_Amp_Chain,pos={324,222},size={45,14},disable=1,proc=DAP_CheckProc_AmpCntrls,title="Chain"
	CheckBox check_DataAcq_Amp_Chain,userdata(tabnum)=  "0"
	CheckBox check_DataAcq_Amp_Chain,userdata(tabcontrol)=  "tab_DataAcq_Amp"
	CheckBox check_DataAcq_Amp_Chain,value= 0
	GroupBox group_Settings_MDSupport,pos={21,26},size={425,40},disable=1,title="Multiple Device Support"
	GroupBox group_Settings_MDSupport,help={"Multiple device support includes yoking and multiple independent devices"}
	GroupBox group_Settings_MDSupport,userdata(tabnum)=  "5"
	GroupBox group_Settings_MDSupport,userdata(tabcontrol)=  "ADC"
	CheckBox check_Settings_MD,pos={34,44},size={51,14},disable=1,proc=DAP_CheckProc_MDEnable,title="Enable"
	CheckBox check_Settings_MD,userdata(tabnum)=  "5",userdata(tabcontrol)=  "ADC"
	CheckBox check_Settings_MD,value= 0
	CheckBox Check_Settings_InsertTP,pos={172,86},size={61,14},disable=1,proc=DAP_CheckProc_InsertTP,title="Insert TP"
	CheckBox Check_Settings_InsertTP,help={"Inserts a test pulse at the front of each sweep in a set."}
	CheckBox Check_Settings_InsertTP,userdata(tabnum)=  "5"
	CheckBox Check_Settings_InsertTP,userdata(tabcontrol)=  "ADC",value= 0
	CheckBox Check_Settings_Override_Set_ITI,pos={243,194},size={182,14},disable=1,proc=DAP_CheckProc_Override_ITI,title="Allow to override the calculated ITI"
	CheckBox Check_Settings_Override_Set_ITI,help={"The total ITI is calculated as the minimum of all ITIs involved in the aquisition. Checking allows the user to override the calculated value."}
	CheckBox Check_Settings_Override_Set_ITI,userdata(tabnum)=  "5"
	CheckBox Check_Settings_Override_Set_ITI,userdata(tabcontrol)=  "ADC"
	CheckBox Check_Settings_Override_Set_ITI,userdata(ResizeControlsInfo)= A"!!,H.!!#A1!!#A4!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_Settings_Override_Set_ITI,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox Check_Settings_Override_Set_ITI,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox Check_Settings_Override_Set_ITI,value= 0
	SetVariable setvar_Settings_TPBuffer,pos={326,109},size={103,16},disable=1,title="TP Buffer size"
	SetVariable setvar_Settings_TPBuffer,userdata(tabnum)=  "5"
	SetVariable setvar_Settings_TPBuffer,userdata(tabcontrol)=  "ADC"
	SetVariable setvar_Settings_TPBuffer,limits={1,inf,1},value= _NUM:1
	CheckBox check_Settings_SaveAmpSettings,pos={306,566},size={108,14},disable=1,title="Save Amp Settings"
	CheckBox check_Settings_SaveAmpSettings,help={"Adds amplifier settings to lab note book for Multiclamp 700Bs ONLY!"}
	CheckBox check_Settings_SaveAmpSettings,userdata(tabnum)=  "5"
	CheckBox check_Settings_SaveAmpSettings,userdata(tabcontrol)=  "ADC",value= 1
	SetVariable setvar_Settings_TP_RTolerance,pos={310,84},size={121,18},disable=1,title="Min delta R (M\\F'Symbol'W\\F]0)"
	SetVariable setvar_Settings_TP_RTolerance,help={"Sets the minimum delta required forTP resistance values to be appended as a wave note to the data sweep. TP resistance values are always documented in the Lab Note Book."}
	SetVariable setvar_Settings_TP_RTolerance,userdata(tabnum)=  "5"
	SetVariable setvar_Settings_TP_RTolerance,userdata(tabcontrol)=  "ADC"
	SetVariable setvar_Settings_TP_RTolerance,limits={1,inf,1},value= _NUM:5
	CheckBox check_Settings_TP_SaveTPRecord,pos={336,135},size={93,14},disable=1,title="Save TP record"
	CheckBox check_Settings_TP_SaveTPRecord,help={"When unchecked, the TP analysis record (from the previous TP run), is overwritten on the initiation of of the TP"}
	CheckBox check_Settings_TP_SaveTPRecord,userdata(tabnum)=  "5"
	CheckBox check_Settings_TP_SaveTPRecord,userdata(tabcontrol)=  "ADC",value= 0
	Button button_DataAcq_AutoBridgeBal_IC,pos={251,194},size={40,15},disable=1,proc=DAP_ButtonProc_AmpCntrls,title="Auto"
	Button button_DataAcq_AutoBridgeBal_IC,help={"Automatically calculate the bridge balance"}
	Button button_DataAcq_AutoBridgeBal_IC,userdata(tabnum)=  "1"
	Button button_DataAcq_AutoBridgeBal_IC,userdata(tabcontrol)=  "tab_DataAcq_Amp"
	CheckBox Check_DataAcq_SendToAllAmp,pos={345,147},size={97,14},disable=1,title="Send to all Amps"
	CheckBox Check_DataAcq_SendToAllAmp,userdata(tabnum)=  "0"
	CheckBox Check_DataAcq_SendToAllAmp,userdata(tabcontrol)=  "ADC",value= 0
	Button button_DataAcq_Seal,pos={147,281},size={84,27},disable=3,proc=ButtonProc_Seal,title="Seal"
	Button button_DataAcq_Seal,help={"Sets the I-clamp holding current based on the V-clamp holding potential"}
	Button button_DataAcq_Seal,userdata(tabnum)=  "0"
	Button button_DataAcq_Seal,userdata(tabcontrol)=  "tab_DataAcq_Pressure"
	Button button_DataAcq_BreakIn,pos={252,281},size={84,27},disable=3,proc=ButtonProc_BreakIn,title="Break In"
	Button button_DataAcq_BreakIn,help={"Sets the I-clamp holding current based on the V-clamp holding potential"}
	Button button_DataAcq_BreakIn,userdata(tabnum)=  "0"
	Button button_DataAcq_BreakIn,userdata(tabcontrol)=  "tab_DataAcq_Pressure"
	Button button_DataAcq_Clear,pos={358,281},size={84,27},disable=3,proc=ButtonProc_Clear,title="Clear"
	Button button_DataAcq_Clear,help={"Attempts to clear the pipette tip to improve access resistance"}
	Button button_DataAcq_Clear,userdata(tabnum)=  "0"
	Button button_DataAcq_Clear,userdata(tabcontrol)=  "tab_DataAcq_Pressure"
	CheckBox check_DatAcq_ClearEnable,pos={372,311},size={51,14},disable=1,proc=CheckProc_ClearEnable,title="Enable"
	CheckBox check_DatAcq_ClearEnable,userdata(tabnum)=  "0"
	CheckBox check_DatAcq_ClearEnable,userdata(tabcontrol)=  "tab_DataAcq_Pressure"
	CheckBox check_DatAcq_ClearEnable,value= 0
	CheckBox check_DatAcq_SealALl,pos={150,311},size={29,14},disable=1,title="All"
	CheckBox check_DatAcq_SealALl,help={"Seals all headstates with active test pulse"}
	CheckBox check_DatAcq_SealALl,userdata(tabnum)=  "0"
	CheckBox check_DatAcq_SealALl,userdata(tabcontrol)=  "tab_DataAcq_Pressure"
	CheckBox check_DatAcq_SealALl,value= 0
	CheckBox check_DatAcq_BreakInAll,pos={273,311},size={29,14},disable=1,title="All"
	CheckBox check_DatAcq_BreakInAll,help={"Break in to all headstates with active test pulse"}
	CheckBox check_DatAcq_BreakInAll,userdata(tabnum)=  "0"
	CheckBox check_DatAcq_BreakInAll,userdata(tabcontrol)=  "tab_DataAcq_Pressure"
	CheckBox check_DatAcq_BreakInAll,value= 0
	Button button_DataAcq_Approach,pos={42,281},size={84,27},disable=1,proc=ButtonProc_Approach,title="Approach"
	Button button_DataAcq_Approach,help={"Applies positive pressure to the pipette"}
	Button button_DataAcq_Approach,userdata(tabnum)=  "0"
	Button button_DataAcq_Approach,userdata(tabcontrol)=  "tab_DataAcq_Pressure"
	CheckBox check_DatAcq_ApproachAll,pos={45,311},size={29,14},disable=1,title="All"
	CheckBox check_DatAcq_ApproachAll,help={"Apply postive pressure to all headstages"}
	CheckBox check_DatAcq_ApproachAll,userdata(tabnum)=  "0"
	CheckBox check_DatAcq_ApproachAll,userdata(tabcontrol)=  "tab_DataAcq_Pressure"
	CheckBox check_DatAcq_ApproachAll,value= 0
	PopupMenu popup_Settings_Pressure_ITCdev,pos={40,501},size={210,21},bodyWidth=150,proc=DAP_PopMenuProc_CAA,title="ITC devices"
	PopupMenu popup_Settings_Pressure_ITCdev,help={"List of available ITC devices for pressure control"}
	PopupMenu popup_Settings_Pressure_ITCdev,userdata(tabnum)=  "6"
	PopupMenu popup_Settings_Pressure_ITCdev,userdata(tabcontrol)=  "ADC"
	PopupMenu popup_Settings_Pressure_ITCdev,mode=3,popvalue="ITC1600_Dev_2",value= #"\"- none -;ITC1600_Dev_1;ITC1600_Dev_2;ITC1600_Dev_3;\""
	TitleBox Title_settings_Hardware_Pressur,pos={31,481},size={41,13},title="Pressure"
	TitleBox Title_settings_Hardware_Pressur,userdata(tabnum)=  "6"
	TitleBox Title_settings_Hardware_Pressur,userdata(tabcontrol)=  "ADC",frame=0
	PopupMenu Popup_Settings_Pressure_DA,pos={37,530},size={53,21},proc=DAP_PopMenuProc_CAA,title="DA"
	PopupMenu Popup_Settings_Pressure_DA,userdata(tabnum)=  "6"
	PopupMenu Popup_Settings_Pressure_DA,userdata(tabcontrol)=  "ADC"
	PopupMenu Popup_Settings_Pressure_DA,mode=1,popvalue="0",value= #"\"0;1;2;3;4;5;6;7\""
	PopupMenu Popup_Settings_Pressure_AD,pos={37,555},size={53,21},proc=DAP_PopMenuProc_CAA,title="AD"
	PopupMenu Popup_Settings_Pressure_AD,userdata(tabnum)=  "6"
	PopupMenu Popup_Settings_Pressure_AD,userdata(tabcontrol)=  "ADC"
	PopupMenu Popup_Settings_Pressure_AD,mode=5,popvalue="4",value= #"\"0;1;2;3;4;5;6;7;8;9;10;11;12;13;14;15\""
	SetVariable setvar_Settings_Pressure_DAgain,pos={98,532},size={50,16},proc=DAP_SetVarProc_CAA
	SetVariable setvar_Settings_Pressure_DAgain,userdata(tabnum)=  "6"
	SetVariable setvar_Settings_Pressure_DAgain,userdata(tabcontrol)=  "ADC"
	SetVariable setvar_Settings_Pressure_DAgain,value= _NUM:2
	SetVariable setvar_Settings_Pressure_ADgain,pos={98,557},size={50,16},proc=DAP_SetVarProc_CAA
	SetVariable setvar_Settings_Pressure_ADgain,userdata(tabnum)=  "6"
	SetVariable setvar_Settings_Pressure_ADgain,userdata(tabcontrol)=  "ADC"
	SetVariable setvar_Settings_Pressure_ADgain,value= _NUM:0.5
	SetVariable SetVar_Hardware_Pressur_DA_Unit,pos={156,532},size={30,16},proc=DAP_SetVarProc_CAA
	SetVariable SetVar_Hardware_Pressur_DA_Unit,userdata(tabnum)=  "6"
	SetVariable SetVar_Hardware_Pressur_DA_Unit,userdata(tabcontrol)=  "ADC"
	SetVariable SetVar_Hardware_Pressur_DA_Unit,value= _STR:"psi"
	SetVariable SetVar_Hardware_Pressur_AD_Unit,pos={177,557},size={30,16},proc=DAP_SetVarProc_CAA
	SetVariable SetVar_Hardware_Pressur_AD_Unit,userdata(tabnum)=  "6"
	SetVariable SetVar_Hardware_Pressur_AD_Unit,userdata(tabcontrol)=  "ADC"
	SetVariable SetVar_Hardware_Pressur_AD_Unit,value= _STR:"psi"
	TitleBox Title_Hardware_Pressure_DA_Div,pos={190,534},size={15,13},title="/ V"
	TitleBox Title_Hardware_Pressure_DA_Div,userdata(tabnum)=  "6"
	TitleBox Title_Hardware_Pressure_DA_Div,userdata(tabcontrol)=  "ADC",frame=0
	TitleBox Title_Hardware_Pressure_AD_Div,pos={158,559},size={15,13},title="V /"
	TitleBox Title_Hardware_Pressure_AD_Div,userdata(tabnum)=  "6"
	TitleBox Title_Hardware_Pressure_AD_Div,userdata(tabcontrol)=  "ADC",frame=0
	PopupMenu Popup_Settings_Pressure_TTL,pos={219,530},size={58,21},proc=DAP_PopMenuProc_CAA,title="TTL"
	PopupMenu Popup_Settings_Pressure_TTL,help={"Select TTL channel for solenoid command"}
	PopupMenu Popup_Settings_Pressure_TTL,userdata(tabnum)=  "6"
	PopupMenu Popup_Settings_Pressure_TTL,userdata(tabcontrol)=  "ADC"
	PopupMenu Popup_Settings_Pressure_TTL,mode=1,popvalue="0",value= #"\"0;1;2;3;4;5;6;7\""
	GroupBox group_Settings_Pressure,pos={23,628},size={425,100},disable=1,title="Pressure"
	GroupBox group_Settings_Pressure,userdata(tabnum)=  "5"
	GroupBox group_Settings_Pressure,userdata(tabcontrol)=  "ADC"
	SetVariable setvar_Settings_InAirP,pos={59,650},size={92,16},disable=1,proc=DAP_SetVarProc_CAA,title="In air P (psi)"
	SetVariable setvar_Settings_InAirP,help={"Set the (positive) pressure applied to the pipette when the pipette is out of the bath."}
	SetVariable setvar_Settings_InAirP,userdata(tabnum)=  "5"
	SetVariable setvar_Settings_InAirP,userdata(tabcontrol)=  "ADC"
	SetVariable setvar_Settings_InAirP,limits={-10,10,0.1},value= _NUM:3.79999995231628
	SetVariable setvar_Settings_InBathP,pos={162,651},size={105,16},disable=1,proc=DAP_SetVarProc_CAA,title="In bath P (psi)"
	SetVariable setvar_Settings_InBathP,help={"Set the (positive) pressure applied to the pipette when the pipette is in the bath."}
	SetVariable setvar_Settings_InBathP,userdata(tabnum)=  "5"
	SetVariable setvar_Settings_InBathP,userdata(tabcontrol)=  "ADC"
	SetVariable setvar_Settings_InBathP,limits={-10,10,0.1},value= _NUM:0.549999952316284
	SetVariable setvar_Settings_InSliceP,pos={287,649},size={105,16},disable=1,proc=DAP_SetVarProc_CAA,title="In slice P (psi)"
	SetVariable setvar_Settings_InSliceP,help={"Set the (positive) pressure applied to the pipette when the pipette is in the tissue specimen."}
	SetVariable setvar_Settings_InSliceP,userdata(tabnum)=  "5"
	SetVariable setvar_Settings_InSliceP,userdata(tabcontrol)=  "ADC"
	SetVariable setvar_Settings_InSliceP,limits={-10,10,0.1},value= _NUM:0.200000002980232
	SetVariable setvar_Settings_NearCellP,pos={40,670},size={111,16},disable=1,proc=DAP_SetVarProc_CAA,title="Near cell P (psi)"
	SetVariable setvar_Settings_NearCellP,help={"Set the (positive) pressure applied to the pipette when the pipette is close to the target neuron."}
	SetVariable setvar_Settings_NearCellP,userdata(tabnum)=  "5"
	SetVariable setvar_Settings_NearCellP,userdata(tabcontrol)=  "ADC"
	SetVariable setvar_Settings_NearCellP,limits={-1,1,0.1},value= _NUM:0.600000023841858
	SetVariable setvar_Settings_SealStartP,pos={157,670},size={110,16},disable=1,proc=DAP_SetVarProc_CAA,title="Seal Init P (psi)"
	SetVariable setvar_Settings_SealStartP,help={"Set the starting negative pressure used to form a seal."}
	SetVariable setvar_Settings_SealStartP,userdata(tabnum)=  "5"
	SetVariable setvar_Settings_SealStartP,userdata(tabcontrol)=  "ADC"
	SetVariable setvar_Settings_SealStartP,limits={-10,0,0.1},value= _NUM:-0.600000023841858
	SetVariable setvar_Settings_SealMaxP,pos={277,669},size={115,16},disable=1,proc=DAP_SetVarProc_CAA,title="Seal max P (psi)"
	SetVariable setvar_Settings_SealMaxP,help={"Set the maximum negative pressure used to form a seal."}
	SetVariable setvar_Settings_SealMaxP,userdata(tabnum)=  "5"
	SetVariable setvar_Settings_SealMaxP,userdata(tabcontrol)=  "ADC"
	SetVariable setvar_Settings_SealMaxP,limits={-10,0,0.1},value= _NUM:-1.39999997615814
	SetVariable setvar_Settings_SurfaceHeight,pos={36,691},size={165,16},disable=1,proc=DAP_SetVarProc_CAA,title="Sol surface height\\Z11 (\\F'Symbol'm\\F'MS Sans Serif'm)"
	SetVariable setvar_Settings_SurfaceHeight,help={"Set the maximum negative pressure used to form a seal."}
	SetVariable setvar_Settings_SurfaceHeight,userdata(tabnum)=  "5"
	SetVariable setvar_Settings_SurfaceHeight,userdata(tabcontrol)=  "ADC"
	SetVariable setvar_Settings_SurfaceHeight,limits={0,inf,100},value= _NUM:3500
	SetVariable setvar_Settings_SliceSurfHeight,pos={226,691},size={166,16},disable=1,proc=DAP_SetVarProc_CAA,title="Slice surface height\\Z11 (\\F'Symbol'm\\F'MS Sans Serif'm)"
	SetVariable setvar_Settings_SliceSurfHeight,help={"Set the maximum negative pressure used to form a seal."}
	SetVariable setvar_Settings_SliceSurfHeight,userdata(tabnum)=  "5"
	SetVariable setvar_Settings_SliceSurfHeight,userdata(tabcontrol)=  "ADC"
	SetVariable setvar_Settings_SliceSurfHeight,limits={0,inf,100},value= _NUM:350
	Button button_Settings_UpdateDACList,pos={262,501},size={150,20},proc=ButtonProc_Hrdwr_P_UpdtDAClist,title="Query connected DAC(s)"
	Button button_Settings_UpdateDACList,help={"Updates the popup menu contents to show the available ITC devices"}
	Button button_Settings_UpdateDACList,userdata(tabnum)=  "6"
	Button button_Settings_UpdateDACList,userdata(tabcontrol)=  "ADC"
	Button button_Hardware_P_Enable,pos={285,527},size={60,46},proc=P_ButtonProc_Enable,title="Enable"
	Button button_Hardware_P_Enable,help={"Enable ITC devices used for pressure regulation."}
	Button button_Hardware_P_Enable,userdata(tabnum)=  "6"
	Button button_Hardware_P_Enable,userdata(tabcontrol)=  "ADC",fSize=14
	Button button_Hardware_P_Disable,pos={352,527},size={60,46},disable=2,proc=P_ButtonProc_Disable,title="Disable"
	Button button_Hardware_P_Disable,help={"Enable ITC devices used for pressure regulation."}
	Button button_Hardware_P_Disable,userdata(tabnum)=  "6"
	Button button_Hardware_P_Disable,userdata(tabcontrol)=  "ADC",fSize=14
	ValDisplay valdisp_DataAcq_P_0,pos={53,331},size={102,17},bodyWidth=35,disable=1,title="\\Z10Pressure (psi)"
	ValDisplay valdisp_DataAcq_P_0,userdata(tabcontrol)=  "tab_DataAcq_Pressure"
	ValDisplay valdisp_DataAcq_P_0,fSize=14,fStyle=0,valueColor=(65535,65535,65535)
	ValDisplay valdisp_DataAcq_P_0,valueBackColor=(0,0,0)
	ValDisplay valdisp_DataAcq_P_0,limits={0,0,0},barmisc={0,1000},value= #"0.00"
	ValDisplay valdisp_DataAcq_P_1,pos={158,331},size={35,17},bodyWidth=35,disable=1
	ValDisplay valdisp_DataAcq_P_1,userdata(tabcontrol)=  "tab_DataAcq_Pressure"
	ValDisplay valdisp_DataAcq_P_1,fSize=14,fStyle=0
	ValDisplay valdisp_DataAcq_P_1,valueBackColor=(65535,65535,65535)
	ValDisplay valdisp_DataAcq_P_1,limits={0,0,0},barmisc={0,1000},value= #"0.00"
	ValDisplay valdisp_DataAcq_P_2,pos={198,331},size={35,17},bodyWidth=35,disable=1
	ValDisplay valdisp_DataAcq_P_2,userdata(tabcontrol)=  "tab_DataAcq_Pressure"
	ValDisplay valdisp_DataAcq_P_2,fSize=14,fStyle=0
	ValDisplay valdisp_DataAcq_P_2,valueBackColor=(65535,65535,65535)
	ValDisplay valdisp_DataAcq_P_2,limits={0,0,0},barmisc={0,1000},value= #"0.00"
	ValDisplay valdisp_DataAcq_P_3,pos={239,331},size={35,17},bodyWidth=35,disable=1
	ValDisplay valdisp_DataAcq_P_3,userdata(tabcontrol)=  "tab_DataAcq_Pressure"
	ValDisplay valdisp_DataAcq_P_3,fSize=14,fStyle=0
	ValDisplay valdisp_DataAcq_P_3,valueBackColor=(65535,65535,65535)
	ValDisplay valdisp_DataAcq_P_3,limits={0,0,0},barmisc={0,1000},value= #"0.00"
	ValDisplay valdisp_DataAcq_P_4,pos={279,331},size={35,17},bodyWidth=35,disable=1
	ValDisplay valdisp_DataAcq_P_4,userdata(tabcontrol)=  "tab_DataAcq_Pressure"
	ValDisplay valdisp_DataAcq_P_4,fSize=14,fStyle=0
	ValDisplay valdisp_DataAcq_P_4,valueBackColor=(65535,65535,65535)
	ValDisplay valdisp_DataAcq_P_4,limits={0,0,0},barmisc={0,1000},value= #"0.00"
	ValDisplay valdisp_DataAcq_P_5,pos={320,331},size={35,17},bodyWidth=35,disable=1
	ValDisplay valdisp_DataAcq_P_5,userdata(tabcontrol)=  "tab_DataAcq_Pressure"
	ValDisplay valdisp_DataAcq_P_5,fSize=14,fStyle=0
	ValDisplay valdisp_DataAcq_P_5,valueBackColor=(65535,65535,65535)
	ValDisplay valdisp_DataAcq_P_5,limits={0,0,0},barmisc={0,1000},value= #"0.00"
	ValDisplay valdisp_DataAcq_P_6,pos={360,331},size={35,17},bodyWidth=35,disable=1
	ValDisplay valdisp_DataAcq_P_6,userdata(tabcontrol)=  "tab_DataAcq_Pressure"
	ValDisplay valdisp_DataAcq_P_6,fSize=14,fStyle=0
	ValDisplay valdisp_DataAcq_P_6,valueBackColor=(65535,65535,65535)
	ValDisplay valdisp_DataAcq_P_6,limits={0,0,0},barmisc={0,1000},value= #"0.00"
	ValDisplay valdisp_DataAcq_P_7,pos={401,331},size={35,17},bodyWidth=35,disable=1
	ValDisplay valdisp_DataAcq_P_7,userdata(tabcontrol)=  "tab_DataAcq_Pressure"
	ValDisplay valdisp_DataAcq_P_7,fSize=14,fStyle=0
	ValDisplay valdisp_DataAcq_P_7,valueBackColor=(65535,65535,65535)
	ValDisplay valdisp_DataAcq_P_7,limits={0,0,0},barmisc={0,1000},value= #"0.00"
	TabControl tab_DataAcq_Pressure,pos={38,260},size={410,94},disable=1,proc=ACL_DisplayTab
	TabControl tab_DataAcq_Pressure,help={"Entries into these tabs update the MCC only when in the active mode. On mode switching, the parameters will be passed to the MCC."}
	TabControl tab_DataAcq_Pressure,userdata(tabnum)=  "0"
	TabControl tab_DataAcq_Pressure,userdata(tabcontrol)=  "ADC"
	TabControl tab_DataAcq_Pressure,userdata(currenttab)=  "0"
	TabControl tab_DataAcq_Pressure,labelBack=(60928,60928,60928),fSize=10
	TabControl tab_DataAcq_Pressure,tabLabel(0)="Auto",tabLabel(1)="Manual",value= 0
	Button button_DataAcq_SSSetPressureMan,pos={42,281},size={84,27},disable=1,proc=ButtonProc_DataAcq_ManPressSet,title=""
	Button button_DataAcq_SSSetPressureMan,userdata(tabnum)=  "1"
	Button button_DataAcq_SSSetPressureMan,userdata(tabcontrol)=  "tab_DataAcq_Pressure"
	Button button_DataAcq_PPSetPressureMan,pos={196,281},size={84,27},disable=1,proc=ButtonProc_ManPP,title="Pressure Pulse"
	Button button_DataAcq_PPSetPressureMan,userdata(tabnum)=  "1"
	Button button_DataAcq_PPSetPressureMan,userdata(tabcontrol)=  "tab_DataAcq_Pressure"
	SetVariable setvar_DataAcq_SSPressure,pos={131,288},size={58,16},disable=1,proc=DAP_SetVarProc_CAA,title="psi"
	SetVariable setvar_DataAcq_SSPressure,userdata(tabnum)=  "1"
	SetVariable setvar_DataAcq_SSPressure,userdata(tabcontrol)=  "tab_DataAcq_Pressure"
	SetVariable setvar_DataAcq_SSPressure,limits={-10,10,1},value= _NUM:0
	SetVariable setvar_DataAcq_PPPressure,pos={283,286},size={58,16},disable=1,proc=DAP_SetVarProc_CAA,title="psi"
	SetVariable setvar_DataAcq_PPPressure,userdata(tabnum)=  "1"
	SetVariable setvar_DataAcq_PPPressure,userdata(tabcontrol)=  "tab_DataAcq_Pressure"
	SetVariable setvar_DataAcq_PPPressure,limits={-10,10,1},value= _NUM:5
	SetVariable setvar_DataAcq_PPDuration,pos={346,287},size={88,16},disable=1,proc=DAP_SetVarProc_CAA,title="Dur(ms)"
	SetVariable setvar_DataAcq_PPDuration,userdata(tabnum)=  "1"
	SetVariable setvar_DataAcq_PPDuration,userdata(tabcontrol)=  "tab_DataAcq_Pressure"
	SetVariable setvar_DataAcq_PPDuration,limits={0,300,1},value= _NUM:300
	CheckBox check_DataAcq_ManPressureAll,pos={55,311},size={29,14},disable=1,title="All"
	CheckBox check_DataAcq_ManPressureAll,userdata(tabnum)=  "1"
	CheckBox check_DataAcq_ManPressureAll,userdata(tabcontrol)=  "tab_DataAcq_Pressure"
	CheckBox check_DataAcq_ManPressureAll,value= 0
	CheckBox check_settings_TP_show_peak,pos={35,132},size={123,14},disable=1,title="Show peak resistance"
	CheckBox check_settings_TP_show_peak,help={"Show the peak resistance curve during the testpulse"}
	CheckBox check_settings_TP_show_peak,userdata(tabnum)=  "5"
	CheckBox check_settings_TP_show_peak,userdata(tabcontrol)=  "ADC",value= 1
	CheckBox check_settings_TP_show_steady,pos={172,133},size={156,14},disable=1,title="Show steady state resistance"
	CheckBox check_settings_TP_show_steady,help={"Show the steady state resistance curve during the testpulse"}
	CheckBox check_settings_TP_show_steady,userdata(tabnum)=  "5"
	CheckBox check_settings_TP_show_steady,userdata(tabcontrol)=  "ADC",value= 1
	CheckBox check_DatAcq_ApproachNear,pos={84,311},size={41,14},disable=1,proc=P_Check_ApproachNear,title="Near"
	CheckBox check_DatAcq_ApproachNear,help={"Apply postive pressure to all headstages"}
	CheckBox check_DatAcq_ApproachNear,userdata(tabnum)=  "0"
	CheckBox check_DatAcq_ApproachNear,userdata(tabcontrol)=  "tab_DataAcq_Pressure"
	Button button_DataAcq_SlowComp_VC,pos={388,226},size={45,20},disable=1,proc=DAP_ButtonProc_AmpCntrls,title="Cp Slow"
	Button button_DataAcq_SlowComp_VC,help={"Activates MCC auto slow capacitance compensation"}
	Button button_DataAcq_SlowComp_VC,userdata(tabnum)=  "0"
	Button button_DataAcq_SlowComp_VC,userdata(tabcontrol)=  "tab_DataAcq_Amp"
	CheckBox check_DatAcq_ApproachNear,value= 0
	CheckBox check_DatAcq_SealAtm,pos={188,311},size={39,14},disable=1,proc=P_Check_SealAtm,title="Atm."
	CheckBox check_DatAcq_SealAtm,help={"Seals all headstates with active test pulse"}
	CheckBox check_DatAcq_SealAtm,userdata(tabnum)=  "0"
	CheckBox check_DatAcq_SealAtm,userdata(tabcontrol)=  "tab_DataAcq_Pressure"
	CheckBox check_DatAcq_SealAtm,value= 0
	CheckBox Check_DataAcq1_DistribDaq,pos={168,603},size={122,14},disable=1,proc=DAP_CheckProc_RepeatedAcq,title="Distributed Acquisition"
	CheckBox Check_DataAcq1_DistribDaq,help={"Determines if distributed acquisition is used."}
	CheckBox Check_DataAcq1_DistribDaq,userdata(tabnum)=  "0"
	CheckBox Check_DataAcq1_DistribDaq,userdata(tabcontrol)=  "ADC"
	CheckBox Check_DataAcq1_DistribDaq,userdata(ResizeControlsInfo)= A"!!,D'!!#Bb!!#@R!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_DataAcq1_DistribDaq,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_DataAcq1_DistribDaq,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_DataAcq1_DistribDaq,value= 0
	SetVariable setvar_DataAcq_dDAQDelay,pos={314,647},size={118,16},bodyWidth=35,disable=1,title="dDAQ delay (ms)"
	SetVariable setvar_DataAcq_dDAQDelay,help={"Delay between the sets during distributed DAQ."}
	SetVariable setvar_DataAcq_dDAQDelay,userdata(tabnum)=  "0"
	SetVariable setvar_DataAcq_dDAQDelay,userdata(tabcontrol)=  "ADC"
	SetVariable setvar_DataAcq_dDAQDelay,userdata(ResizeControlsInfo)= A"!!,D/!!#C#!!#A>!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_DataAcq_dDAQDelay,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_DataAcq_dDAQDelay,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_DataAcq_dDAQDelay,limits={0,inf,1},value= _NUM:0
	Button button_DataAcq_OpenCommentNB,pos={409,691},size={30,18},disable=1,proc=DAP_ButtonProc_OpenCommentNB,title="NB"
	Button button_DataAcq_OpenCommentNB,help={"Open a notebook displaying the comments of all sweeps and allowing free form additions by the user."}
	Button button_DataAcq_OpenCommentNB,userdata(tabnum)=  "0"
	Button button_DataAcq_OpenCommentNB,userdata(tabcontrol)=  "ADC"
	CheckBox check_Settings_TPAfterDAQ,pos={172,109},size={124,14},disable=1,title="Activate TP after DAQ"
	CheckBox check_Settings_TPAfterDAQ,help={"Immediately start a test pulse after DAQ finishes"}
	CheckBox check_Settings_TPAfterDAQ,userdata(tabnum)=  "5"
	CheckBox check_Settings_TPAfterDAQ,userdata(tabcontrol)=  "ADC"
	CheckBox check_Settings_TPAfterDAQ,userdata(ResizeControlsInfo)= A"!!,Ch!!#@F!!#A,!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_Settings_TPAfterDAQ,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_Settings_TPAfterDAQ,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_Settings_TPAfterDAQ,value= 0
	DefineGuide UGV0={FR,-25},UGH0={FB,-27},UGV1={FL,481}
	SetWindow kwTopWin,hook(cleanup)=DAP_WindowHook
	SetWindow kwTopWin,userdata(ResizeControlsInfo)= A"!!*'\"z!!#Du5QF1NJ,fQL!!*'\"zzzzzzzzzzzzzzzzzzz"
	SetWindow kwTopWin,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzzzzzzzzzzzzzzz"
	SetWindow kwTopWin,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzzzzzzzzz!!!"
	SetWindow kwTopWin,userdata(ResizeControlsGuides)=  "UGV0;UGH0;"
	SetWindow kwTopWin,userdata(ResizeControlsInfoUGV0)= A":-hTC3`S[N0KW?-:-(sG6SUJQ0OI4ZG$cpb<*<$d3`U64E]Zff;Ft%f:/jMQ3\\WWl:K'ha8P`)B3&r`U7o`,K756hm;EIBK8OQ!&3]g5.9MeM`8Q88W:-'s^2*1"
	SetWindow kwTopWin,userdata(ResizeControlsInfoUGH0)= A":-hTC3`S[@0KW?-:-(sG6SUJQ0OI4ZG$cpb<*<$d3`U64E]Zff;Ft%f:/jMQ3\\`]m:K'ha8P`)B1cR6P7o`,K756hm69@\\;8OQ!&3]g5.9MeM`8Q88W:-'s^2`h"
EndMacro



///@brief Restores the base state of the DA_Ephys panel.

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

	// activate only the first headstage
	DAP_TurnOffAllHeadstages(panelTitle)
	CheckBox Check_DataAcq_HS_00 WIN = $panelTitle,value= 0

	DAP_TurnOffAllDACs(panelTitle)
	DAP_TurnOffAllADCs(panelTitle)
	DAP_TurnOffAllTTLs(panelTitle)

	ChangeTab(panelTitle, "ADC", 0)
	ChangeTab(panelTitle, "tab_DataAcq_Amp", 0)
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

	CheckBox Check_DataAcq1_RepeatAcq Win = $panelTitle, value = 0
	CheckBox Check_DataAcq1_DistribDaq Win = $panelTitle, value = 0

	SetVariable SetVar_DataAcq_ITI WIN = $panelTitle, value = _NUM:0

	SetVariable SetVar_DataAcq_TPDuration  WIN = $panelTitle,value= _NUM:10
	SetVariable SetVar_DataAcq_TPAmplitude  WIN = $panelTitle,value= _NUM:10
	
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

	CheckBox Check_Settings_SaveData WIN = $panelTitle, value= 0
	CheckBox Check_Settings_UseDoublePrec WIN = $panelTitle, value= 0
	CheckBox Check_AsyncAD_00 WIN = $panelTitle,value= 0
	CheckBox Check_AsyncAD_01 WIN = $panelTitle,value= 0
	CheckBox Check_AsyncAD_02 WIN = $panelTitle,value= 0
	CheckBox Check_AsyncAD_03 WIN = $panelTitle,value= 0
	CheckBox Check_AsyncAD_04 WIN = $panelTitle,value= 0
	CheckBox Check_AsyncAD_05 WIN = $panelTitle,value= 0
	CheckBox Check_AsyncAD_06 WIN = $panelTitle,value= 0
	CheckBox Check_AsyncAD_07 WIN = $panelTitle,value= 0
	
	SetVariable SetVar_AsyncAD_Gain_00 WIN = $panelTitle,value= _NUM:1
	SetVariable SetVar_AsyncAD_Gain_01 WIN = $panelTitle,value= _NUM:1
	SetVariable SetVar_AsyncAD_Gain_02 WIN = $panelTitle,value= _NUM:1
	SetVariable SetVar_AsyncAD_Gain_03 WIN = $panelTitle,value= _NUM:1
	SetVariable SetVar_AsyncAD_Gain_04 WIN = $panelTitle,value= _NUM:1
	SetVariable SetVar_AsyncAD_Gain_05 WIN = $panelTitle,value= _NUM:1
	SetVariable SetVar_AsyncAD_Gain_06 WIN = $panelTitle,value= _NUM:1
	SetVariable SetVar_AsyncAD_Gain_07 WIN = $panelTitle,value= _NUM:1
	
	SetVariable SetVar_Async_Title_00 WIN = $panelTitle,value= _STR:""
	SetVariable SetVar_Async_Title_01 WIN = $panelTitle,value= _STR:""
	SetVariable SetVar_Async_Title_02 WIN = $panelTitle,value= _STR:""
	SetVariable SetVar_Async_Title_03 WIN = $panelTitle,value= _STR:""
	SetVariable SetVar_Async_Title_04 WIN = $panelTitle,value= _STR:""
	SetVariable SetVar_Async_Title_05 WIN = $panelTitle,value= _STR:""
	SetVariable SetVar_Async_Title_06 WIN = $panelTitle,value= _STR:""
	SetVariable SetVar_Async_Title_07 WIN = $panelTitle,value= _STR:""
	
	SetVariable SetVar_Async_Unit_00 WIN = $panelTitle,value= _STR:""
	SetVariable SetVar_Async_Unit_01 WIN = $panelTitle,value= _STR:""
	SetVariable SetVar_Async_Unit_02 WIN = $panelTitle,value= _STR:""
	SetVariable SetVar_Async_Unit_03 WIN = $panelTitle,value= _STR:""
	SetVariable SetVar_Async_Unit_04 WIN = $panelTitle,value= _STR:""
	SetVariable SetVar_Async_Unit_05 WIN = $panelTitle,value= _STR:""
	SetVariable SetVar_Async_Unit_06 WIN = $panelTitle,value= _STR:""
	SetVariable SetVar_Async_Unit_07 WIN = $panelTitle,value= _STR:""
	
	CheckBox Check_Settings_Append WIN = $panelTitle,value= 0
	CheckBox Check_Settings_BkgTP WIN = $panelTitle,value= 1
	CheckBox Check_Settings_BackgrndDataAcq WIN = $panelTitle, value= 1
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

	CheckBox Check_DataAcq_SendToAllAmp WIN = $panelTitle, value= 0

	SetVariable SetVar_Settings_VC_DAgain WIN = $panelTitle, value= _NUM:20
	SetVariable SetVar_Settings_VC_ADgain WIN = $panelTitle, value= _NUM:0.00999999977648258
	SetVariable SetVar_Settings_IC_ADgain WIN = $panelTitle, value= _NUM:0.00999999977648258

	PopupMenu Popup_Settings_VC_DA WIN = $panelTitle, mode=1
	PopupMenu Popup_Settings_VC_AD WIN = $panelTitle, mode=1
	PopupMenu Popup_Settings_IC_AD WIN = $panelTitle, mode=1
	PopupMenu Popup_Settings_HeadStage WIN = $panelTitle, mode=1
	PopupMenu popup_Settings_Amplifier WIN = $panelTitle, mode=1, value= #"\" - none - ;\""
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

	PopupMenu Popup_DA_IndexEnd_00 WIN = $panelTitle, mode=1, userdata(MenuExp) = ""
	PopupMenu Popup_DA_IndexEnd_01 WIN = $panelTitle, mode=1, userdata(MenuExp) = ""
	PopupMenu Popup_DA_IndexEnd_02 WIN = $panelTitle, mode=1, userdata(MenuExp) = ""
	PopupMenu Popup_DA_IndexEnd_03 WIN = $panelTitle, mode=1, userdata(MenuExp) = ""
	PopupMenu Popup_DA_IndexEnd_04 WIN = $panelTitle, mode=1, userdata(MenuExp) = ""
	PopupMenu Popup_DA_IndexEnd_05 WIN = $panelTitle, mode=1, userdata(MenuExp) = ""
	PopupMenu Popup_DA_IndexEnd_06 WIN = $panelTitle, mode=1, userdata(MenuExp) = ""
	PopupMenu Popup_DA_IndexEnd_07 WIN = $panelTitle, mode=1, userdata(MenuExp) = ""

	PopupMenu Popup_TTL_IndexEnd_00 WIN = $panelTitle, mode=1, userdata(MenuExp) = ""
	PopupMenu Popup_TTL_IndexEnd_01 WIN = $panelTitle, mode=1, userdata(MenuExp) = ""
	PopupMenu Popup_TTL_IndexEnd_02 WIN = $panelTitle, mode=1, userdata(MenuExp) = ""
	PopupMenu Popup_TTL_IndexEnd_03 WIN = $panelTitle, mode=1, userdata(MenuExp) = ""
	PopupMenu Popup_TTL_IndexEnd_04 WIN = $panelTitle, mode=1, userdata(MenuExp) = ""
	PopupMenu Popup_TTL_IndexEnd_05 WIN = $panelTitle, mode=1, userdata(MenuExp) = ""
	PopupMenu Popup_TTL_IndexEnd_06 WIN = $panelTitle, mode=1, userdata(MenuExp) = ""
	PopupMenu Popup_TTL_IndexEnd_07 WIN = $panelTitle, mode=1, userdata(MenuExp) = ""

	CheckBox check_Settings_ShowScopeWindow WIN = $panelTitle,value= 0

	CheckBox check_Settings_ITITP WIN = $panelTitle, value= 0
	CheckBox check_Settings_TPAfterDAQ WIN = $panelTitle, value= 0

	CheckBox check_Settings_Overwrite WIN = $panelTitle,value= 1

	SetVariable SetVar_Async_min_00 WIN = $panelTitle,value= _NUM:0
	SetVariable SetVar_Async_max_00 WIN = $panelTitle,value= _NUM:0
	CheckBox check_Async_Alarm_00  WIN = $panelTitle,value= 0

	SetVariable SetVar_Async_min_01 WIN = $panelTitle,value= _NUM:0
	SetVariable SetVar_Async_max_01 WIN = $panelTitle,value= _NUM:0
	CheckBox check_Async_Alarm_01  WIN = $panelTitle,value= 0

	SetVariable SetVar_Async_min_02 WIN = $panelTitle,value= _NUM:0
	SetVariable SetVar_Async_max_02 WIN = $panelTitle,value= _NUM:0
	CheckBox check_Async_Alarm_02  WIN = $panelTitle,value= 0

	SetVariable SetVar_Async_min_03 WIN = $panelTitle,value= _NUM:0
	SetVariable SetVar_Async_max_03 WIN = $panelTitle,value= _NUM:0
	CheckBox check_Async_Alarm_03  WIN = $panelTitle,value= 0

	SetVariable SetVar_Async_min_04 WIN = $panelTitle,value= _NUM:0
	SetVariable SetVar_Async_max_04 WIN = $panelTitle,value= _NUM:0
	CheckBox check_Async_Alarm_04  WIN = $panelTitle,value= 0

	SetVariable SetVar_Async_min_05 WIN = $panelTitle,value= _NUM:0
	SetVariable SetVar_Async_max_05 WIN = $panelTitle,value= _NUM:0
	CheckBox check_Async_Alarm_05  WIN = $panelTitle,value= 0

	SetVariable SetVar_Async_min_06 WIN = $panelTitle,value= _NUM:0
	SetVariable SetVar_Async_max_06 WIN = $panelTitle,value= _NUM:0
	CheckBox check_Async_Alarm_06  WIN = $panelTitle,value= 0

	SetVariable SetVar_Async_min_07 WIN = $panelTitle,value= _NUM:0
	SetVariable SetVar_Async_max_07 WIN = $panelTitle,value= _NUM:0
	CheckBox check_Async_Alarm_07  WIN = $panelTitle,value= 0

	CheckBox check_DataAcq_RepAcqRandom WIN = $panelTitle,value= 0
	CheckBox check_Settings_Option_3 WIN = $panelTitle,fColor=(65280,43520,0),value= 0
	CheckBox check_Settings_ScalingZero WIN = $panelTitle,value= 0
	CheckBox check_Settings_SetOption_04 WIN = $panelTitle,fColor=(65280,43520,0),value= 0

	PopupMenu popup_MoreSettings_DeviceType WIN = $panelTitle,mode=1 // ,popvalue="ITC1600",value= #"\"ITC16;ITC18;ITC1600;ITC00;ITC16USB;ITC18USB;\""
	PopupMenu popup_moreSettings_DeviceNo WIN = $panelTitle,mode=1 // ,popvalue="0",value= #"\"0;1;2;3;4;5;6;7;8;9;10\""

	SetVariable SetVar_Sweep WIN = $panelTitle, limits={0,0,1}, value= _NUM:0

	SetVariable SetVar_DataAcq_dDAQDelay WIN = $panelTitle,value= _NUM:0
	SetVariable SetVar_DataAcq_OnsetDelay WIN = $panelTitle,value= _NUM:1
	ValDisplay valdisp_DataAcq_SweepsInSet WIN = $panelTitle,value= _NUM:1
	ValDisplay valdisp_DataAcq_SweepsActiveSet WIN = $panelTitle,value= _NUM:1
	ValDisplay valdisp_DataAcq_TrialsCountdown WIN = $panelTitle,value= _NUM:1
	ValDisplay valdisp_DataAcq_ITICountdown WIN = $panelTitle,value= _NUM:0

	SetVariable SetVar_DataAcq_TerminationDelay WIN = $panelTitle,value= _NUM:0

	CheckBox check_Settings_SetOption_5 WIN = $panelTitle,fColor=(65280,43520,0),value= 0
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

	SetVariable SetVar_DataAcq_Hold_IC WIN = $panelTitle, value= _NUM:0
	SetVariable Setvar_DataAcq_PipetteOffset_VC WIN = $panelTitle, value= _NUM:0
	SetVariable SetVar_DataAcq_BB WIN = $panelTitle,limits={0,inf,1},value= _NUM:0
	SetVariable SetVar_DataAcq_CN WIN = $panelTitle,limits={-8,16,1},value= _NUM:0

	CheckBox check_DatAcq_HoldEnable WIN = $panelTitle,value= 0
	CheckBox check_DatAcq_RsCompEnable WIN = $panelTitle,value= 0
	CheckBox check_DatAcq_CNEnable WIN = $panelTitle,value= 0

	Slider slider_DataAcq_ActiveHeadstage  WIN = $panelTitle,value= 0
	SetVariable SetVar_DataAcq_AutoBiasV WIN = $panelTitle,value= _NUM:0
	CheckBox check_DataAcq_AutoBias WIN = $panelTitle,value= 0
	SetVariable setvar_DataAcq_IbiasMax WIN = $panelTitle,value= _NUM:0
	SetVariable SetVar_DataAcq_AutoBiasVrange WIN = $panelTitle,value= _NUM:0
	SetVariable SetVar_DataAcq_Hold_VC WIN = $panelTitle,value= _NUM:0
	CheckBox check_DatAcq_HoldEnableVC WIN = $panelTitle,value= 0
	SetVariable SetVar_DataAcq_WCR WIN = $panelTitle,value= _NUM:0
	CheckBox check_DatAcq_WholeCellEnable WIN = $panelTitle,value= 0
	SetVariable SetVar_DataAcq_WCC  WIN = $panelTitle,value= _NUM:0
	SetVariable SetVar_DataAcq_RsCorr WIN = $panelTitle,value= _NUM:0
	SetVariable SetVar_DataAcq_RsPred WIN = $panelTitle,value= _NUM:0
	CheckBox check_DataAcq_IzeroEnable WIN = $panelTitle,value= 0
	CheckBox Check_Settings_AlarmPauseAcq WIN = $panelTitle,value= 0
	CheckBox Check_Settings_AlarmAutoRepeat WIN = $panelTitle,value= 0
	CheckBox check_Settings_AmpMCCdefault WIN = $panelTitle,value= 0
	CheckBox check_Settings_AmpMIESdefault WIN = $panelTitle,value= 0
	CheckBox check_DataAcq_Amp_Chain WIN = $panelTitle,value= 0
	CheckBox check_Settings_MD WIN = $panelTitle,value= 0
	CheckBox Check_Settings_InsertTP WIN = $panelTitle,value= 0
	CheckBox check_Settings_Override_Set_ITI WIN = $panelTitle, value = 0
	CheckBox check_Settings_TP_SaveTPRecord WIN = $panelTitle, value = 0
	CheckBox check_settings_TP_show_steady WIN = $panelTitle, value = 1
	CheckBox check_settings_TP_show_peak WIN = $panelTitle, value = 1

	SCOPE_KillScopeWindowIfRequest(panelTitle)

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
				sprintf popupValue, "%s+%s%s%s" FirstTwoMenuItems, "WBP_ITCPanelPopUps(0,\"", SearchString,"\")"
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
				sprintf popupValue, "\"- none -;\"+%s%s%s"  "WBP_ITCPanelPopUps(0,\"", SearchString,"\")"
				do
					sprintf IndexEndPopUpMenuName "Popup_DA_IndexEnd_%.2d" i
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

				sprintf popupValue, "%s+%s%s%s" FirstTwoMenuItems, "WBP_ITCPanelPopUps(0,\"", SearchString,"\")"
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
				sprintf popupValue, "\"- none -;\"+%s%s%s"  "WBP_ITCPanelPopUps(0,\"", SearchString,"\")"
				do
					sprintf IndexEndPopUpMenuName "Popup_DA_IndexEnd_%.2d" i
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
			sprintf TTLPopUpMenuName, "Wave_TTL_%0.2d" TTL_No
			sprintf IndexEndPopUpMenuName "Popup_TTL_IndexEnd_%0.2d" TTL_No

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
					sprintf TTLPopUpMenuName, "Wave_TTL_%.2d" i
					sprintf popupValue, "%s+%s%s%s" FirstMenuItem, "WBP_ITCPanelPopUps(1,\"", SearchString,"\")"
					listOfWaves = wavelist(searchstring,";","")
					popupmenu $TTLPopUpMenuName win = $panelTitle, value = #popupValue, userdata(MenuExp) = ListOfWaves
					controlupdate /w =  $panelTitle $TTLPopUpMenuName
					sprintf IndexEndPopUpMenuName,  "Popup_TTL_IndexEnd_%.2d" i
					sprintf popupValue, "%s+%s%s%s" "\"- none -;\"", "WBP_ITCPanelPopUps(1,\"", SearchString,"\")"
					popupmenu $IndexEndPopUpMenuName win = $panelTitle, value = #popupValue
					controlupdate /w =  $panelTitle $IndexEndPopUpMenuName
					i += 1
				while(i < NUM_DA_TTL_CHANNELS)
			else
				if(strlen(varstr) == 0)
					sprintf SearchString, "*TTL*"
					sprintf popupValue, "%s+%s%s%s" FirstMenuItem, "WBP_ITCPanelPopUps(1,\"", SearchString,"\")"
					listOfWaves = wavelist(searchstring,";","")
					popupmenu $TTLPopUpMenuName win = $panelTitle, value = #popupValue, userdata(MenuExp) = ListOfWaves
					controlupdate /w =  $panelTitle $TTLPopUpMenuName
					sprintf popupValue, "%s+%s%s%s" "\"- none -;\"", "WBP_ITCPanelPopUps(1,\"", SearchString,"\")"
					popupmenu $IndexEndPopUpMenuName win = $panelTitle, value = #popupValue
					controlupdate /w =  $panelTitle $IndexEndPopUpMenuName
				else
					sprintf popupValue, "%s+%s%s%s" FirstMenuItem, "WBP_ITCPanelPopUps(1,\"", varstr,"\")"
					popupmenu $TTLPopUpMenuName win = $panelTitle, value = #popupValue, userdata(MenuExp) = popupValue
					controlupdate /w =  $panelTitle $TTLPopUpMenuName
					sprintf popupValue, "%s+%s%s%s" "\"- none -;\"", "WBP_ITCPanelPopUps(1,\"", varStr,"\")"
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
				sprintf popupValue, "%s+%s%s%s" FirstTwoMenuItems, "WBP_ITCPanelPopUps(1,\"", SearchString,"\")"
				ListOfWaves = wavelist(searchstring,";","")

				do
					if(i > 0) // disables search inputs except for Search_TTL_00
						sprintf SearchSetVarName, "Search_TTL_%.2d" i
						SetVariable $SearchSetVarName WIN = $panelTitle, disable = 0

						sprintf TTLPopUpMenuName, "Wave_TTL_%.2d" i
						PopupMenu $TTLPopUpMenuName win = $panelTitle, value = #popupValue, userData(menuExp) = ListOfWaves
					endif
					i += 1
				while(i < NUM_DA_TTL_CHANNELS)

				i = 0
				sprintf popupValue, "\"- none -;\"+%s%s%s"  "WBP_ITCPanelPopUps(1,\"", SearchString,"\")"
				do
					sprintf IndexEndPopUpMenuName "Popup_TTL_IndexEnd_%.2d" i
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

				sprintf popupValue, "%s+%s%s%s" FirstTwoMenuItems, "WBP_ITCPanelPopUps(1,\"", SearchString,"\")"
				ListOfWaves = wavelist(searchstring,";","")
				do
					sprintf TTLPopUpMenuName, "Wave_TTL_%.2d" i
					PopupMenu $TTLPopUpMenuName win = $panelTitle, value = #popupValue, userData(menuExp) = ListOfWaves
					if(i > 0) // disables search inputs except for Search_TTL_00
						sprintf SearchSetVarName, "Search_TTL_%.2d" i
						SetVariable $SearchSetVarName WIN = $panelTitle, disable = 2, value =_STR:""
					endif
					i += 1
				while(i < NUM_DA_TTL_CHANNELS)

				i = 0
				sprintf popupValue, "\"- none -;\"+%s%s%s"  "WBP_ITCPanelPopUps(1,\"", SearchString,"\")"
				do
					sprintf IndexEndPopUpMenuName "Popup_TTL_IndexEnd_%.2d" i
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


/// Updates the yoking controls on all locked/unlocked panels
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

Function DAP_GetTabNumber(panelTitle)
	string panelTitle

	ControlInfo/W=$panelTitle ADC
	ASSERT(V_flag > 0,"Missing control ADC")
	return V_value
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

	if(DAP_GetTabNumber(panelTitle) != HARDWARE_TAB_NUM)
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


Function DAP_TabControlFinalHook(tca)
	STRUCT WMTabControlAction &tca

	DAP_UpdateYokeControls(tca.win)

	// Maybe the user changed the stimulus ITI behind our back
	// here we try to catch that case
	if(tca.tab == DATA_ACQU_TAB_NUM)
		DAP_UpdateITIAcrossSets(tca.win)
	endif

End

/// This is a function that gets run by ACLight's tab control function every time a tab is selected,
/// but before the internal tabs hook is called

Function DAP_TabTJHook1(tca)
	STRUCT WMTabControlAction &tca

	variable tabnum , i, numItems, minSampInt
	string panelTitle
	panelTitle = tca.win
	tabnum     = tca.tab

	if(HSU_DeviceIsUnLocked(panelTitle,silentCheck=1))
		print "Please lock the panel to a ITC device in the Hardware tab"
		return 0
	endif

	SVAR/Z ITCPanelTitleList = root:MIES:ITCDevices:ITCPanelTitleList
	ASSERT(SVAR_exists(ITCPanelTitleList), "missing SVAR ITCPanelTitleList")
	if(tabnum == 0)
		numItems = ItemsInList(ITCPanelTitleList)
		for(i=0; i < numItems; i+=1)
			panelTitle = StringFromList(i, ITCPanelTitleList,";")
			DAP_UpdateITCMinSampIntDisplay(panelTitle)
			ControlUpdate/W=$panelTitle ValDisp_DataAcq_SamplingInt
		endfor
	endif
	return 0

///@todo we can move that stuff into DAP_TabControlFinalHook
//	if(tabnum==1)// this does not work because hook function runs prior to adams tab functions (i assume)
//	controlinfo/w=datapro_itc1600 Check_DataAcq_Indexing
//		if(v_value==0)
//		TitleBox Title_DAC_IndexStartEnd disable=1, win=datapro_itc1600
//		DAP_ChangePopUpState("Popup_DA_IndexEnd_0",1)
//		endif
//	endif
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
			sprintf DAPopUpMenuName,  "Wave_DA_%0.2d"  DA_No
			sprintf IndexEndPopUpMenuName, "Popup_DA_IndexEnd_%0.2d" DA_No

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
					sprintf popupValue, "%s+%s%s%s" FirstTwoMenuItems, "WBP_ITCPanelPopUps(0,\"", SearchString,"\")"
					listOfWaves = wavelist(searchstring,";","")
					popupmenu $DAPopUpMenuName win = $panelTitle, value = #popupValue, userdata(MenuExp) = ListOfWaves
					controlupdate /w =  $panelTitle $DAPopUpMenuName
					sprintf IndexEndPopUpMenuName,  "Popup_DA_IndexEnd_%.2d" i
					sprintf popupValue, "%s+%s%s%s" "\"- none -;\"", "WBP_ITCPanelPopUps(0,\"", SearchString,"\")"
					popupmenu $IndexEndPopUpMenuName win = $panelTitle, value = #popupValue
					controlupdate /w =  $panelTitle $IndexEndPopUpMenuName
					i += 1
				while(i < NUM_DA_TTL_CHANNELS)

			else // apply search string to associated channel
				if(strlen(varstr) == 0)
					sprintf SearchString, "*DA*"
					sprintf popupValue, "%s+%s%s%s" FirstTwoMenuItems, "WBP_ITCPanelPopUps(0,\"", SearchString,"\")"
					listOfWaves = wavelist(searchstring,";","")
					popupmenu $DAPopUpMenuName win = $panelTitle, value = #popupValue, userdata(MenuExp) = ListOfWaves
					controlupdate /w =  $panelTitle $DAPopUpMenuName
					sprintf popupValue, "%s+%s%s%s" "\"- none -;\"", "WBP_ITCPanelPopUps(0,\"", SearchString,"\")"
					popupmenu $IndexEndPopUpMenuName win = $panelTitle, value = #popupValue
					controlupdate /w =  $panelTitle $IndexEndPopUpMenuName
				else
					sprintf popupValue, "%s+%s%s%s" FirstTwoMenuItems, "WBP_ITCPanelPopUps(0,\"", varstr,"\")"
					searchString = varStr
					listOfWaves = wavelist(searchstring,";","")
					popupmenu $DAPopUpMenuName win = $panelTitle, value = #popupValue, userdata(MenuExp) = listOfWaves
					controlupdate /w =  $panelTitle $DAPopUpMenuName
					sprintf popupValue, "%s+%s%s%s" "\"- none -;\"", "WBP_ITCPanelPopUps(0,\"", varStr,"\")"
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

	string DACWave, panelTitle

	switch(cba.eventCode)
		case 2:
		paneltitle   = cba.win
		DACWave      = cba.ctrlName
		DACwave[0,4] = "wave"

		Controlinfo/W=$panelTitle $DACWave
		if(stringmatch(s_value,"- none -"))
			SetCheckBoxState(panelTitle, cba.ctrlName, 0)
			print "Select " + DACwave[5,7] + " Wave"
		endif

		DAP_UpdateITIAcrossSets(panelTitle)

		Controlinfo/W=$panelTitle SetVar_DataAcq_SetRepeats
		ValDisplay valdisp_DataAcq_SweepsInSet win = $panelTitle, value = _NUM:(IDX_MaxNoOfSweeps(panelTitle,0) * v_value)
		Valdisplay valdisp_DataAcq_SweepsActiveSet win = $panelTitle, value = _NUM:IDX_MaxNoOfSweeps(panelTitle,1)
		break
	endswitch
End

/// @brief One time initialization before data acquisition
Function DAP_OneTimeCallBeforeDAQ(panelTitle)
	string panelTitle

	variable numHS, i
	string ctrl

	NVAR/Z/SDFR=GetDevicePath(panelTitle) count
	if(NVAR_Exists(count))
		KillVariables count
	endif

	TP_UpdateTPBufferSizeGlobal(panelTitle)

	if(GetCheckboxState(panelTitle, "check_Settings_Overwrite"))
		DM_DeleteDataWaves(panelTitle, GetSetVariable(panelTitle, "SetVar_Sweep"))
	endif

	// disable the clamp mode checkboxes of all active headstages
	WAVE statusHS = DC_ControlStatusWave(panelTitle, HEADSTAGE)

	numHS = DimSize(statusHS, ROWS)
	for(i = 0; i < numHS; i += 1)
		if(!statusHS[i])
			continue
		endif

		sprintf ctrl, "Check_DataAcq_HS_%02d", i
		EnableControl(panelTitle, ctrl)
		DisableControl(panelTitle, "Radio_ClampMode_" + num2str(i * 2))
		DisableControl(panelTitle, "Radio_ClampMode_" + num2str(i * 2 + 1))
	endfor

	NVAR DataAcqState = $GetDataAcqState(panelTitle)
	DataAcqState = 1
	DAP_ToggleAcquisitionButton(panelTitle, DATA_ACQ_BUTTON_TO_STOP)
End

/// @brief One time cleaning up after data acquisition
Function DAP_OneTimeCallAfterDAQ(panelTitle)
	string panelTitle

	string ctrl
	variable numHS, i

	WAVE statusHS = DC_ControlStatusWave(panelTitle, HEADSTAGE)

	numHS = DimSize(statusHS, ROWS)
	for(i = 0; i < numHS; i += 1)

		sprintf ctrl, "Check_DataAcq_HS_%02d", i
		EnableControl(panelTitle, ctrl)
		EnableControl(panelTitle, "Radio_ClampMode_" + num2str(i * 2))
		EnableControl(panelTitle, "Radio_ClampMode_" + num2str(i * 2 + 1))
	endfor

	NVAR DataAcqState = $GetDataAcqState(panelTitle)
	DataAcqState = 0
	DAP_ToggleAcquisitionButton(panelTitle, DATA_ACQ_BUTTON_TO_DAQ)

	NVAR count = $GetCount(panelTitle)
	KillVariables count

	// restore the selected sets before DAQ
	if(GetCheckBoxState(panelTitle, "Check_DataAcq_Indexing"))
		IDX_ResetStartFinshForIndexing(panelTitle)
	endif

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
			SetDataFolder root:
			panelTitle = ba.win

			AbortOnValue DAP_CheckSettings(panelTitle, DATA_ACQUISITION_MODE),1

			NVAR DataAcqState = $GetDataAcqState(panelTitle)

			if(!DataAcqState) // data aquisition is stopped

				// stops test pulse if it is running
				if(IsBackgroundTaskRunning("testpulse"))
					ITC_StopTestPulseSingleDevice(panelTitle)
				endif

				DAP_OneTimeCallBeforeDAQ(panelTitle)

				// Data collection
				// Function that assess how many 1d waves in set??
				// Function that passes column to configdataForITCfunction?
				// If a set with multiple 1d waves is chosen, repeated aquisition should be activated automatically. globals should be used to keep track of columns
				DC_ConfigureDataForITC(panelTitle, DATA_ACQUISITION_MODE)
				Wave/SDFR=GetDevicePath(panelTitle) ITCDataWave
				SCOPE_CreateGraph(ITCDataWave, panelTitle)
				if(!GetCheckBoxState(panelTitle, "Check_Settings_BackgrndDataAcq"))
					ITC_DataAcq(panelTitle)
					if(GetCheckBoxState(panelTitle, "Check_DataAcq1_RepeatAcq"))
						RA_Start(panelTitle)
					else
						DAP_OneTimeCallAfterDAQ(panelTitle)
					endif
				else
					ITC_BkrdDataAcq(panelTitle)
				endif
			else // data aquistion is ongoing
				DataAcqState = 0
				DAP_StopOngoingDataAcquisition(panelTitle)
				ITC_StopITCDeviceTimer(panelTitle)
			endif
		break
	endswitch

	return 0
End


Function DAP_ButtonProc_AcquireDataMD(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	string panelTitle
	variable nextSweep

	switch(ba.eventcode)
		case EVENT_MOUSE_UP:
			SetDataFolder root:
			panelTitle = ba.win

			AbortOnValue DAP_CheckSettings(panelTitle, DATA_ACQUISITION_MODE),1

			NVAR DataAcqState = $GetDataAcqState(panelTitle)

			if(!DataAcqState)
				 // stops test pulse if it is running
				if(IsBackgroundTaskRunning("TestPulseMD"))
					WAVE/T ActiveDeviceTextList = root:MIES:ITCDevices:ActiveITCDevices:testPulse:ActiveDeviceTextList
					variable NumberOfDevicesRunningTP = dimsize(ActiveDeviceTextList, 0)
					variable i = 0
					for(i = 0; i < NumberOfDevicesRunningTP; i += 1)
						if(stringmatch(ActiveDeviceTextList[i], panelTitle) == 1)
							 ITC_StopTPMD(panelTitle)
						endif
					endfor
				endif

				DAP_OneTimeCallBeforeDAQ(panelTitle)
				DAM_FunctionStartDataAcq(panelTitle) // initiates background aquisition
			else // data aquistion is ongoing, stop data acq
				DAM_StopDataAcq(panelTitle)
				ITC_StopITCDeviceTimer(panelTitle)
				DAP_OneTimeCallAfterDAQ(panelTitle)
			endif
		break
	endswitch
End


Function DAP_CheckProc_SaveData(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	string panelTitle, buttonText

	switch(cba.eventCode)
		case 2:
			panelTitle = cba.win

			if(cba.checked)
				Button DataAcquireButton fColor = (52224,0,0), win = $panelTitle
				buttonText = "\\Z12\\f01Acquire Data\r * DATA WILL NOT BE SAVED *"
				buttonText += "\r\\Z08\\f00 (autosave state is in settings tab)"
				Button DataAcquireButton title=buttonText
			else
				Button DataAcquireButton fColor = (0,0,0), win = $panelTitle
				Button DataAcquireButton title = "\\Z14\\f01Acquire\rData"
			endif
		break
	endswitch
End


Function DAP_CheckProc_IndexingState(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	string panelTitle
	variable setRepeats
	switch(cba.eventCode)
		case EVENT_MOUSE_UP:

		panelTitle = cba.win
		// makes sure user data for controls is up to date
		WBP_UpdateITCPanelPopUps(panelTitle)

		setRepeats = GetSetVariable(panelTitle, "SetVar_DataAcq_SetRepeats")
		// updates sweeps in cycle value - when indexing is off, only the start set is counted,
		// when indexing is on, all sets between start and end set are counted
		if(GetCheckBoxState(panelTitle, "Check_DataAcq1_IndexingLocked"))
			ValDisplay valdisp_DataAcq_SweepsInSet win = $panelTitle, value = _NUM:(IDX_MaxSweepsLockedIndexing(panelTitle) * setRepeats)
		else
			ValDisplay valdisp_DataAcq_SweepsInSet win = $panelTitle, value = _NUM:(IDX_MaxNoOfSweeps(panelTitle, 0) * setRepeats)
		endif
		ValDisplay valdisp_DataAcq_SweepsActiveSet win = $panelTitle, value = _NUM:IDX_MaxNoOfSweeps(panelTitle, 1)

		DAP_UpdateITIAcrossSets(panelTitle)
		break
	endswitch

	return 0
End


Function DAP_ChangePopUpState(BaseName, state, panelTitle)
	string BaseName, panelTitle// Popup_DA_IndexEnd_0
	variable state
	variable i = 0
	string CompleteName
	
	do
		CompleteName = Basename + num2str(i)
		PopupMenu $CompleteName disable = state, win = $panelTitle
		i += 1
	while(i < NUM_DA_TTL_CHANNELS)
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
	string TTLCheckBoxName

	for(i = 0; i < NUM_DA_TTL_CHANNELS; i += 1)
		TTLCheckBoxName = "Check_TTL_0" + num2str(i)
		CheckBox $TTLCheckBoxName win = $panelTitle, value = 0
	endfor
End

Function DAP_StoreTTLState(panelTitle)
	string panelTitle

	DFREF dfr = GetDevicePath(panelTitle)
	string/G dfr:StoredTTLState = Convert1DWaveToList(DC_ControlStatusWave(panelTitle, CHANNEL_TYPE_TTL))
End

Function DAP_RestoreTTLState(panelTitle)
	string panelTitle

	variable i, state
	string control

	SVAR/SDFR=GetDevicePath(panelTitle) StoredTTLState

	for(i = 0; i < NUM_DA_TTL_CHANNELS; i += 1)
		control = "Check_TTL_0" + num2str(i)
		state = str2num(StringFromList(i , StoredTTLState))
		SetCheckBoxState(panelTitle, control, state)
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
		ctrl = GetPanelControl(panelTitle, i, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_CHECK)
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
		ctrl = GetPanelControl(panelTitle, i, CHANNEL_TYPE_ADC, CHANNEL_CONTROL_CHECK)
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

Function DAP_TurnOffAllHeadstages(panelTitle)
	string panelTitle

	variable i, ctrlNo, mode, headStage
	string ctrl

	for(i = 0; i < NUM_HEADSTAGES; i += 1)
		sprintf ctrl, "Check_DataAcq_HS_%02d", i
		DAP_GetInfoFromControl(panelTitle, ctrl, ctrlNo, mode, headStage)
		ASSERT(i == ctrlNo, "invalid index")
		SetCheckBoxState(panelTitle, ctrl, CHECKBOX_UNSELECTED)
		if(!HSU_DeviceIsUnLocked(panelTitle, silentCheck=1))
			DAP_RemoveClampModeSettings(panelTitle, headStage, mode)
		endif
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

	if(GetCheckBoxState(panelTitle, "Check_Settings_Override_Set_ITI", allowMissingControl=1))
		EnableControl(panelTitle, "SetVar_DataAcq_ITI")
	elseif(maxITI == 0 && numActiveDAChannels > 0)
		EnableControl(panelTitle, "SetVar_DataAcq_ITI")
		ControlInfo/W=$panelTitle Check_Settings_Override_Set_ITI
		if(V_flag != 0)
			SetCheckBoxState(panelTitle, "Check_Settings_Override_Set_ITI", CHECKBOX_SELECTED)
		endif
	else
		DisableControl(panelTitle, "SetVar_DataAcq_ITI")
		SetSetVariable(panelTitle, "SetVar_DataAcq_ITI", maxITI)
	endif

	if(DAP_DeviceIsLeader(panelTitle))
		DAP_SyncGuiFromLeaderToFollower(panelTitle)
	endif
End

/// @brief Procedure for DA/TTL popupmenus including indexing wave popupmenus
Function DAP_PopMenuChkProc_StimSetList(pa) : PopupMenuControl
	STRUCT WMPopupAction& pa

	variable popNum
	string ctrlName
	string ListOfWavesInFolder
	string folderPath
	string folder, checkBoxName
	string panelTitle

	switch(pa.eventCode)
		case 2:
			ctrlName = pa.ctrlName
			panelTitle = pa.win
			popnum     = pa.popNum

			DFREF saveDFR = GetDataFolderDFR()

			if(StringMatch(ctrlName, "*indexEnd*") != 1)
				if(popnum == 1) //if the user selects "none" the channel is automatically turned off
					CheckBoxName = ctrlName
					CheckBoxName[0,3] = "check"
					Checkbox $Checkboxname win = $panelTitle, value = 0
				endif
			endif

			if(StringMatch(ctrlname, "Wave_DA_*"))
				if(popnum == 2)
					// prevents the user from selecting the testpulse
					PopupMenu $ctrlname win = $panelTitle, mode = 3
				endif
			endif

			DAP_UpdateITIAcrossSets(panelTitle)

			// makes sure data acq starts in the correct folder!!
			SetDataFolder saveDFR

			ControlInfo/W=$panelTitle Check_DataAcq1_IndexingLocked
			if(v_value == 0)
				ControlInfo/W=$panelTitle SetVar_DataAcq_SetRepeats
				ValDisplay valdisp_DataAcq_SweepsInSet win = $panelTitle, value = _NUM:(IDX_MaxNoOfSweeps(panelTitle,0) * v_value)
				ValDisplay valdisp_DataAcq_SweepsActiveSet win=$panelTitle, value=_NUM:IDX_MaxNoOfSweeps(panelTitle,1)
			else
				ControlInfo/W=$panelTitle SetVar_DataAcq_SetRepeats
				ValDisplay valdisp_DataAcq_SweepsInSet win = $panelTitle, value = _NUM:(IDX_MaxSweepsLockedIndexing(panelTitle) * v_value)
				ValDisplay valdisp_DataAcq_SweepsActiveSet win = $panelTitle, value = _NUM:IDX_MaxNoOfSweeps(panelTitle,1)
			endif
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

Function DAP_UpdateSweepLimitsAndDisplay(panelTitle)
	string panelTitle

	string panelList
	variable sweep, maxNextSweep, numPanels, i

	panelList = panelTitle

	if(!CmpStr(panelTitle, ITC1600_FIRST_DEVICE) && DAP_DeviceIsLeader(panelTitle))

		SVAR/Z listOfFollowerDevices = $GetFollowerList(doNotCreateSVAR=1)
		if(SVAR_Exists(listOfFollowerDevices) && strlen(listOfFollowerDevices) > 0)
			panelList = AddListItem(listOfFollowerDevices, panelList, ";", inf)
		endif
		sweep = GetSetVariable(ITC1600_FIRST_DEVICE, "SetVar_Sweep")
	else
		sweep = -INF
	endif

	// query maximum next sweep
	// the next sweep equals the number of data waves as these start counting with zero
	maxNextSweep = -INF
	numPanels = ItemsInList(panelList)
	for(i = 0; i < numPanels; i += 1)
		panelTitle = StringFromList(i, panelList)

		if(IsFinite(sweep) && i > 0) // panelTitle is a follower and we were called by the leader
			SetSetVariable(panelTitle, "SetVar_Sweep", sweep)
		endif

		dfref dfr = GetDeviceDataPath(panelTitle)
		maxNextSweep = max(maxNextSweep, ItemsInList(GetListOfWaves(dfr, DATA_SWEEP_REGEXP, waveProperty="MINCOLS:2")))
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



Function DAP_UpdateITCMinSampIntDisplay(panelTitle)
	string panelTitle

	SetValDisplaySingleVariable(panelTitle, "ValDisp_DataAcq_SamplingInt", SI_CalculateMinSampInterval(panelTitle))
End


Function DAP_SetVarProc_TotSweepCount(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	string panelTitle
	variable numSetRepeats

	switch(sva.eventCode)
		case 1:
		case 2:
		case 3:
			panelTitle = sva.win
			numSetRepeats = GetSetVariable(panelTitle, "SetVar_DataAcq_SetRepeats")

			if(GetCheckBoxState(panelTitle, "Check_DataAcq1_IndexingLocked"))
				numSetRepeats *= IDX_MaxSweepsLockedIndexing(panelTitle)
			else
				numSetRepeats *= IDX_MaxNoOfSweeps(panelTitle, 0)
			endif

			SetValDisplaySingleVariable(panelTitle, "valdisp_DataAcq_SweepsInSet", numSetRepeats)
			SetValDisplaySingleVariable(panelTitle, "valdisp_DataAcq_SweepsActiveSet", IDX_MaxNoOfSweeps(panelTitle, 1))
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
			DAP_FindConnectedAmps(ba.win)
			break
	endswitch
End

Function DAP_CheckProc_Override_ITI(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	switch(cba.eventCode)
		case EVENT_MOUSE_UP:
			if(!cba.checked)
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

static Function/S DAP_FormatAmplifierChannelList(panelTitle)
	string panelTitle

	variable numRows
	variable i
	string str
	string list = ""

	Wave/SDFR=GetAmplifierFolder() W_TelegraphServers

	numRows = DimSize(W_TelegraphServers, ROWS)
	if(!numRows)
		print "Activate Multiclamp Commander software to populate list of available amplifiers"
		return "MC not available;"
	endif

	for(i=0; i < numRows; i+=1)
		sprintf str, "AmpNo %d Chan %d", W_TelegraphServers[i][0], W_TelegraphServers[i][1]
		list = AddListItem(str, list, ";", inf)
	endfor

	return list
End

Function DAP_FindConnectedAmps(panelTitle)
	string panelTitle

	// compatibility fix
	// Old panels, created before this change, use
	// this function as button control and send the
	// name of the control instead of panelTitle
	if(!windowExists(panelTitle))
		GetWindow kwTopWin, activeSW
		panelTitle = S_value
	endif

	DFREF saveDFR = GetDataFolderDFR()
	SetDataFolder GetAmplifierFolder()

	// old axon interface settings wave
	Make/O/N=0 W_TelegraphServers
	AxonTelegraphFindServers

	MDSort(W_TelegraphServers, 0, keyColSecondary=1)

	// new mcc interface settings wave
	Make/O/N=(0,0)/I W_MultiClamps
	MCC_FindServers/Z=1

	SetDataFolder saveDFR

	PopupMenu  popup_Settings_Amplifier win = $panelTitle, value = #("\"" + NONE + ";" + DAP_FormatAmplifierChannelList(panelTitle) + "\"")
End

Function DAP_PopMenuProc_Headstage(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa
	
	switch( pa.eventCode )
		case 2: // mouse up
			if(!stringmatch(pa.win, "DA_*")) // only update parameter data storage waves if the panel is locked.
				HSU_UpdateChanAmpAssignPanel(pa.win)
				P_UpdatePressureControls(pa.win, (pa.popNum - 1))
			endif
			break
		case -1: // control being killed
			break
	endswitch
	
	return 0
End

Function DAP_PopMenuProc_CAA(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	switch( pa.eventCode )
		case 2: // mouse up
			if(!stringmatch(pa.win, "DA_*")) // only update parameter data storage waves if the panel is locked.
				HSU_UpdateChanAmpAssignStorWv(pa.win)
				P_UpdatePressureDataStorageWv(pa.win)
			endif
			break
		case -1: // control being killed
			break
	endswitch
	
	return 0
End

Function DAP_SetVarProc_CAA(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
			if(!stringmatch(sva.win, "DA_*")) // only update parameter data storage waves if the panel is locked.
				HSU_UpdateChanAmpAssignStorWv(sva.win)
				P_UpdatePressureDataStorageWv(sva.win)
			endif
			break
		case 3: // Live update
			break
		case -1: // control being killed
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
		if(leaderdDAQDelay != GetCheckBoxState(panelTitle, "SetVar_DataAcq_dDAQDelay"))
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

	variable numDACs, numADCs, numHS, numEntries, i, indexingEnabled
	string ctrl, endWave, ttlWave, dacWave, refDacWave
	string list, msg

	if(isEmpty(panelTitle))
		print "Invalid empty string for panelTitle, can not proceed"
		return 1
	endif

	ASSERT(mode == DATA_ACQUISITION_MODE || mode == TEST_PULSE_MODE, "Invalid mode")

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

	list = panelTitle

	if(DAP_DeviceCanLead(panelTitle))
		SVAR/Z listOfFollowerDevices = $GetFollowerList(doNotCreateSVAR=1)
		if(SVAR_Exists(listOfFollowerDevices))
			if(DAP_CheckSettingsAcrossYoked(listOfFollowerDevices, mode))
				return 1
			endif
			list = AddListItem(list, listOfFollowerDevices, ";", inf)
		endif
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

		numHS = sum(DC_ControlStatusWave(panelTitle, HEADSTAGE))
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

		if(mode == DATA_ACQUISITION_MODE)
			// check all selected TTLs
			indexingEnabled = GetCheckBoxState(panelTitle, "Check_DataAcq_Indexing")
			Wave statusTTL = DC_ControlStatusWave(panelTitle, CHANNEL_TYPE_TTL)
			numEntries = DimSize(statusTTL, ROWS)
			for(i=0; i < numEntries; i+=1)
				if(!statusTTL[i])
					continue
				endif

				ctrl = GetPanelControl(panelTitle, i, CHANNEL_TYPE_TTL, CHANNEL_CONTROL_WAVE)
				ttlWave = GetPopupMenuString(panelTitle, ctrl)
				if(!CmpStr(ttlWave, NONE))
					printf "(%s) Please select a valid wave for TTL channel %d\r", panelTitle, i
					return 1
				endif

				if(indexingEnabled)
					ctrl = GetPanelControl(panelTitle, i, CHANNEL_TYPE_TTL, CHANNEL_CONTROL_INDEX_END)
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
					if(!statusDA[i])
						continue
					endif

					ctrl = GetPanelControl(panelTitle, i, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE)
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

		// check all active headstages
		Wave statusHS = DC_ControlStatusWave(panelTitle, HEADSTAGE)
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
	endfor

	return 0
End

/// @brief Returns 1 if the headstage has invalid settings, and zero if everything is okay
static Function DAP_CheckHeadStage(panelTitle, headStage, mode)
	string panelTitle
	variable headStage, mode

	string ctrl, dacWave, endWave, unit
	variable DACchannel, ADCchannel, DAheadstage, ADheadstage, realMode
	variable gain, scale, ctrlNo, clampMode

	if(HSU_DeviceisUnlocked(panelTitle, silentCheck=1))
		return 1
	endif

	Wave ChanAmpAssign    = GetChanAmpAssign(panelTitle)
	Wave channelClampMode = GetChannelClampMode(panelTitle)

	if(headstage < 0 || headStage >= DimSize(ChanAmpAssign, COLS))
		printf "(%s) Invalid headstage %d\r", panelTitle, headStage
		return 1
	endif

	sprintf ctrl, "Check_DataAcq_HS_%02d", headStage
	DAP_GetInfoFromControl(panelTitle, ctrl, ctrlNo, clampMode, headStage)

	if(clampMode == V_CLAMP_MODE)
		DACchannel = ChanAmpAssign[0][headStage]
		ADCchannel = ChanAmpAssign[2][headStage]
	elseif(clampMode == I_CLAMP_MODE)
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

	ADheadstage = TP_HeadstageUsingADC(panelTitle, ADCchannel)
	if(!IsFinite(ADheadstage))
		printf "(%s) Could not determine the headstage for the ADChannel %d.\r", panelTitle, ADCchannel
		return 1
	endif

	DAheadstage = TP_HeadstageUsingDAC(panelTitle, DACchannel)
	if(!IsFinite(DAheadstage))
		printf "(%s) Could not determine the headstage for the DACchannel %d.\r", panelTitle, DACchannel
		return 1
	endif

	if(DAheadstage != ADheadstage)
		printf "(%s) The configured headstages for the DA channel %d and the AD channel %d differ (%d vs %d).\r", panelTitle, DACchannel, ADCchannel, DAheadstage, ADheadstage
		return 1
	endif

	ctrl = GetPanelControl(panelTitle, DACchannel, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_UNIT)
	unit = GetSetVariableString(panelTitle, ctrl)
	if(isEmpty(unit))
		printf "(%s) The unit for DACchannel %d is empty.\r", panelTitle, DACchannel
		return 1
	endif

	ctrl = GetPanelControl(panelTitle, DACchannel, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_GAIN)
	gain = GetSetVariable(panelTitle, ctrl)
	if(!isFinite(gain) || gain == 0)
		printf "(%s) The gain for DACchannel %d must be finite and non-zero.\r", panelTitle, DACchannel
		return 1
	endif

	// we allow the scale being zero
	ctrl = GetPanelControl(panelTitle, DACchannel, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_SCALE)
	scale = GetSetVariable(panelTitle, ctrl)
	if(!isFinite(scale))
		printf "(%s) The scale for DACchannel %d must be finite.\r", panelTitle, DACchannel
		return 1
	endif

	ctrl = GetPanelControl(panelTitle, ADCchannel, CHANNEL_TYPE_ADC, CHANNEL_CONTROL_UNIT)
	unit = GetSetVariableString(panelTitle, ctrl)
	if(isEmpty(unit))
		printf "(%s) The unit for ADCchannel %d is empty.\r", panelTitle, ADCchannel
		return 1
	endif

	ctrl = GetPanelControl(panelTitle, ADCchannel, CHANNEL_TYPE_ADC, CHANNEL_CONTROL_GAIN)
	gain = GetSetVariable(panelTitle, ctrl)
	if(!isFinite(gain) || gain == 0)
		printf "(%s) The gain for ADCchannel %d must be finite and non-zero.\r", panelTitle, ADCchannel
		return 1
	endif

	if(mode == DATA_ACQUISITION_MODE)
		ctrl = GetPanelControl(panelTitle, DACchannel, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE)
		dacWave = GetPopupMenuString(panelTitle, ctrl)
		if(!CmpStr(dacWave, NONE) || !CmpStr(dacWave, "TestPulse"))
			printf "(%s) Please select a valid DA wave for DA channel %d referenced by HeadStage %d\r", panelTitle, DACchannel, headStage
			return 1
		endif

		if(GetCheckBoxState(panelTitle, "Check_DataAcq_Indexing"))
			ctrl = GetPanelControl(panelTitle, DACchannel, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_INDEX_END)
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

	string ctrlSuffix, ADUnit, DAUnit
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
	elseif(clampMode == I_CLAMP_MODE)
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
	sprintf ctrlSuffix "_DA_%02d", DACchannel
	SetCheckBoxState(panelTitle, "Check" + ctrlSuffix, CHECKBOX_SELECTED)
	SetSetVariable(panelTitle, "Gain" + ctrlSuffix, DaGain)
	SetSetVariableString(panelTitle, "Unit" + ctrlSuffix, DaUnit)
	ChannelClampMode[DACchannel][%DAC] = clampMode

	// ADC channels
	sprintf ctrlSuffix "_AD_%02d", ADCchannel
	SetCheckBoxState(panelTitle, "Check" + ctrlSuffix, CHECKBOX_SELECTED)
	SetSetVariable(panelTitle, "Gain" + ctrlSuffix, ADGain)
	SetSetVariableString(panelTitle, "Unit" + ctrlSuffix, ADUnit)
	ChannelClampMode[ADCchannel][%ADC] = clampMode
End

static Function DAP_UpdateHeadstage(panelTitle, headStage)
	string panelTitle
	variable headStage

	string ctrl
	variable enabled

	ctrl  = "Check_DataAcq_HS_0" + num2str(headstage)
	enabled = GetCheckBoxState(panelTitle, ctrl)

	if(!enabled)
		HSU_UpdateChanAmpAssignStorWv(panelTitle)
		return NaN
	endif

	DAP_ChangeHeadstageState(panelTitle, ctrl, 0)
	HSU_UpdateChanAmpAssignStorWv(panelTitle)
	DAP_ChangeHeadstageState(panelTitle, ctrl, 1)
End


static Function DAP_RemoveClampModeSettings(panelTitle, headStage, clampMode)
	string panelTitle
	variable headStage, clampMode

	string ctrl
	variable DACchannel, ADCchannel

	Wave ChanAmpAssign    = GetChanAmpAssign(panelTitle)
	Wave ChannelClampMode = GetChannelClampMode(panelTitle)

	If(ClampMode == V_CLAMP_MODE)
		DACchannel = ChanAmpAssign[0][headStage]
		ADCchannel = ChanAmpAssign[2][headStage]
	elseif(ClampMode == I_CLAMP_MODE)
		DACchannel = ChanAmpAssign[4][headStage]
		ADCchannel = ChanAmpAssign[6][headStage]
	endIf

	if(!IsFinite(DACchannel) || !IsFinite(ADCchannel))
		return NaN
	endif

	sprintf ctrl, "Check_DA_%02d", DACchannel
	SetCheckBoxState(panelTitle, ctrl, CHECKBOX_UNSELECTED)
	ChannelClampMode[DACchannel][%DAC] = nan

	sprintf ctrl, "Check_AD_%02d", ADCchannel
	SetCheckBoxState(panelTitle, ctrl, CHECKBOX_UNSELECTED)
	ChannelClampMode[ADCchannel][%ADC] = nan
End


/// @brief Return information readout from various gui controls
///
/// @param[in]  panelTitle  panel
/// @param[in]  ctrl        control can be either `Radio_ClampMode_*` or `Check_DataAcq_HS_*`
///                         referring to an existing control
/// @param[out] ctrlNo      number of the control (everything behind the last "_" of ctrl)
/// @param[out] mode        I_CLAMP_MODE or V_CLAMP_MODE
/// @param[out] headStage   number of the headstage
static Function DAP_GetInfoFromControl(panelTitle, ctrl, ctrlNo, mode, headStage)
	string panelTitle, ctrl
	variable &ctrlNo, &mode, &headStage
	string clampMode     = "Radio_ClampMode_"
	string headStageCtrl = "Check_DataAcq_HS_"
	variable id, pos1, pos2

	ctrlNo    = NaN
	mode      = NaN
	headStage = NaN

	ASSERT(!isEmpty(ctrl), "Empty control")

	pos1 = strsearch(ctrl, clampMode, 0)
	pos2 = strsearch(ctrl, headStageCtrl, 0)

	if(pos1 != -1)
		ctrlNo = str2num(ctrl[pos1 + strlen(clampMode), inf])
		ASSERT(IsFinite(ctrlNo), "non finite number parsed from control")
		if(mod(ctrlNo, 2) == 0)
			mode = V_CLAMP_MODE
			headStage = ctrlNo / 2
		else
			mode = I_CLAMP_MODE
			headStage = (ctrlNo - 1) / 2
		endif
	elseif(pos2 != -1)
		ctrlNo = str2num(ctrl[pos2 + strlen(headStageCtrl), inf])
		ASSERT(IsFinite(ctrlNo), "non finite number parsed from control")
		headStage = ctrlNo
		// this is the current clamp control, if it is selected mode equals I_CLAMP_MODE, if not it equals V_CLAMP_MODE
		mode = GetCheckBoxState(panelTitle, "Radio_ClampMode_" + num2str(headStage * 2 + 1))
	else
		DEBUGPRINT("control", str=ctrl)
		ASSERT(0, "unhandled control")
	endif

	ASSERT(mode == V_CLAMP_MODE || mode == I_CLAMP_MODE, "unexpected mode")
End

Function DAP_CheckProc_ClampMode(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	string panelTitle
	variable ctrlNo, mode, oppositeMode, headStage, pairedRadioButtonNo
	variable testPulseMode

	switch( cba.eventCode )
		case EVENT_MOUSE_UP:
			panelTitle = cba.win

			testPulseMode = TP_StopTestPulse(panelTitle)
			DAP_GetInfoFromControl(panelTitle, cba.ctrlName, ctrlNo, mode, headStage)
			pairedRadioButtonNo = mode == V_CLAMP_MODE ? ctrlNo + 1 : ctrlNo - 1
			SetCheckboxState(panelTitle, "Radio_ClampMode_" + num2str(pairedRadioButtonNo), CHECKBOX_UNSELECTED)
			oppositeMode = mode == V_CLAMP_MODE ? I_CLAMP_MODE : V_CLAMP_MODE

			if(GetCheckBoxState(panelTitle, "Check_DataAcq_HS_0" + num2str(headStage)))
				DAP_RemoveClampModeSettings(panelTitle, headStage, oppositeMode)
				DAP_ApplyClmpModeSavdSettngs(panelTitle, headStage, mode)
				AI_SetClampMode(panelTitle, headStage, mode)
			endif

			AI_UpdateAmpView(panelTitle, headStage)
			ChangeTab(panelTitle, "tab_DataAcq_Amp", mode)

			DAP_UpdateITCMinSampIntDisplay(panelTitle)
			TP_RestartTestPulse(panelTitle, testPulseMode)
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

static Function DAP_ChangeHeadstageState(panelTitle, headStageCtrl, enabled)
	string panelTitle, headStageCtrl
	variable enabled

	variable mode, headStage, ctrlNo

	DAP_GetInfoFromControl(panelTitle, headStageCtrl, ctrlNo, mode, headStage)

	If(!enabled)
		DAP_RemoveClampModeSettings(panelTitle, headStage, mode)
	else
		DAP_ApplyClmpModeSavdSettngs(panelTitle, headStage, mode)
	endif

	DAP_UpdateITCMinSampIntDisplay(panelTitle)
	DAP_UpdateITIAcrossSets(panelTitle)
End

/// @brief Stop the testpulse and data acquisition
///
/// Should be used if `Multi Device Support` is not checked
Function DAP_StopOngoingDataAcquisition(panelTitle)
	string panelTitle

	string cmd
	variable needsOTCAfterDAQ = 0

	if(IsBackgroundTaskRunning("testpulse") == 1) // stops the testpulse
		ITC_StopTestPulseSingleDevice(panelTitle)
		needsOTCAfterDAQ = needsOTCAfterDAQ | 0
	endif

	if(IsBackgroundTaskRunning("ITC_Timer") == 1) // stops the background timer
		ITC_StopBackgroundTimerTask()
		needsOTCAfterDAQ = needsOTCAfterDAQ | 0
	endif

	if(IsBackgroundTaskRunning("ITC_FIFOMonitor") == 1) // stops ongoing background data aquistion
		ITC_STOPFifoMonitor()

		sprintf cmd, "ITCStopAcq /z = 0"
		ExecuteITCOperation(cmd)
		// zero channels that may be left high
		ITC_ZeroITCOnActiveChan(panelTitle)
		DM_SaveAndScaleITCData(panelTitle)

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

Function DAP_StopOngoingDataAcqMD(panelTitle)
	string panelTitle

	if(IsBackgroundTaskRunning("TestPulseMD")) // stops the testpulse
		 ITC_StopTPMD(panelTitle)
	endif

	if(IsBackgroundTaskRunning("ITC_TimerMD")) // stops the background timer
		ITC_StopTimerForDeviceMD(panelTitle)
	endif

	if(IsBackgroundTaskRunning("ITC_FIFOMonitorMD")) // stops ongoing background data aquistion
		ITC_TerminateOngoingDataAcqMD(panelTitle)
	endif

	NVAR/Z/SDFR=GetDevicePath(panelTitle) count
	KillVariables/Z count
	print "Data acquisition was manually terminated"
End

/// @brief Set the acquisition button text and color
///
/// @param panelTitle device
/// @param mode       One of @ref ToggleAcquisitionButtonConstants
Function DAP_ToggleAcquisitionButton(panelTitle, mode)
	string panelTitle
	variable mode

	ASSERT(mode == DATA_ACQ_BUTTON_TO_STOP || mode == DATA_ACQ_BUTTON_TO_DAQ, "Invalid mode")

	STRUCT RGBColor color
	string text

	if(!GetCheckBoxstate(panelTitle, "Check_Settings_SaveData"))
		if(mode == DATA_ACQ_BUTTON_TO_STOP)
			text = "\\Z14\\f01Stop\rAcquistion"
		elseif(mode == DATA_ACQ_BUTTON_TO_DAQ)
			text = "\\Z14\\f01Acquire\rData"
		endif
	else // Don't save data
		color.red = 52224

		if(mode == DATA_ACQ_BUTTON_TO_STOP)
			text  = "\\Z12\\f01Stop Acquisition\r * DATA WILL NOT BE SAVED *"
			text += "\r\\Z08\\f00 (autosave state is in settings tab)"
		elseif(mode == DATA_ACQ_BUTTON_TO_DAQ)
			text  = "\\Z12\\f01Acquire Data\r * DATA WILL NOT BE SAVED *"
			text += "\r\\Z08\\f00 (autosave state is in settings tab)"
		endif
	endif

	Button DataAcquireButton title=text, fcolor=(color.red, color.green, color.blue), win = $panelTitle
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
			DAP_BackgroundDA_EnableDisable(leadpanel, 1)
			DAP_BackgroundDA_EnableDisable(panelToYoke, 1)

			DAP_UpdateITIAcrossSets(leadPanel)
			DisableListOfControls(panelToYoke, "StartTestPulseButton;DataAcquireButton;Check_DataAcq1_RepeatAcq;Check_DataAcq1_DistribDaq;SetVar_DataAcq_dDAQDelay;Check_DataAcq_Indexing;SetVar_DataAcq_ITI;SetVar_DataAcq_SetRepeats;Check_Settings_Override_Set_ITI")
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
		panelList = AddListItem(listOfFollowerDevices, panelList, ";", inf)
	endif

	leaderdDAQ         = GetSetVariable(leadPanel, "Check_DataAcq1_DistribDaq")
	leaderRepeatAcq    = GetCheckBoxState(leadPanel, "Check_DataAcq1_RepeatAcq")
	leaderIndexing     = GetCheckBoxState(leadPanel, "Check_DataAcq_Indexing")
	leaderOverrrideITI = GetCheckBoxState(panelTitle, "Check_Settings_Override_Set_ITI", allowMissingControl=1)
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
			SetCheckBoxState(panelTitle, "Check_Settings_Override_Set_ITI", leaderOverrrideITI)
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
	EnableListOfControls(panelToDeYoke, "StartTestPulseButton;DataAcquireButton;Check_DataAcq1_RepeatAcq;Check_DataAcq1_DistribDaq;SetVar_DataAcq_dDAQDelay;Check_DataAcq_Indexing;SetVar_DataAcq_ITI;SetVar_DataAcq_SetRepeats;Check_Settings_Override_Set_ITI")
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
				HSU_AutoFillGain(panelTitle)
				HSU_UpdateChanAmpAssignStorWv(panelTitle)
			endif
			break
	endswitch

	return 0
End


// FUNCTION BELOW CONTROL THE GUI INTERACTIONS OF THE AMPLIFIER CONTROLS ON THE DATA ACQUISITION TAB OF THE DA_EPHYS PANEL


Function DAP_SliderProc_MIESHeadStage(sc) : SliderControl
	struct WMSliderAction &sc

	string panelTitle
	variable mode, headStage

	if(sc.eventCode & 0x1)
		panelTitle = sc.win
		headStage  = sc.curVal
		mode = AI_MIESHeadstageMode(panelTitle, headStage)
		AI_UpdateAmpView(panelTitle, headStage)
		P_LoadPressureButtonState(panelTitle, headStage)
		P_SaveUserSelectedHeadstage(panelTitle, headStage)
		// chooses the amp tab according to the MIES headstage clamp mode
		ChangeTab(panelTitle, "tab_DataAcq_Amp", mode)
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


// FUNCTION BELOW CONTROL THE GUI STATE FOR CHANGES RELATED TO MULTIPLE DEVICES

//	When multiple device support is not enabled there are two options for DAC operation: foreground and background
//	When multiple device support is enabled there are no options for DAC operation: it is always in the background
//	When multiple device support is enabled, and there are more than two ITC1600s, yoking controls are enabled.

/// Check box procedure for multiple device (MD) support
Function DAP_CheckProc_MDEnable(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	switch(cba.eventCode)
		case EVENT_MOUSE_UP:
			DAP_BackgroundDA_EnableDisable(cba.win, cba.checked)
			break
	endswitch

	return 0
End

/// @brief This function assigns the appropriate procedure to the TP and DataAcq
/// buttons in the Data Acquisition tab of the DA_Ephys panel
///
/// @param panelTitle device
/// @param disableOrEnable disable(0) or enable(1) the multi device support
Function DAP_BackgroundDA_EnableDisable(panelTitle, disableOrEnable)
	string panelTitle
	variable disableOrEnable

	SetCheckBoxState(panelTitle, "Check_Settings_BkgTP", disableOrEnable)
	SetCheckBoxState(panelTitle, "Check_Settings_BackgrndDataAcq", disableOrEnable)
	SetCheckBoxState(panelTitle, "Check_Settings_BackgrndDataAcq", disableOrEnable)
	SetCheckBoxState(panelTitle, "check_Settings_MD", disableOrEnable)

	if(disableOrEnable)
		DisableListOfControls(panelTitle, "Check_Settings_BkgTP;Check_Settings_BackgrndDataAcq")
		Button DataAcquireButton WIN=$panelTitle, proc=DAP_ButtonProc_AcquireDataMD
	else
		EnableListOfControls(panelTitle, "Check_Settings_BkgTP;Check_Settings_BackgrndDataAcq")
		Button DataAcquireButton WIN=$panelTitle, proc=DAP_ButtonProc_AcquireData
	endif
End


// FUNCTION BELOW CONTROLS TP INSERTION INTO SET SWEEPS BEFORE THE SWEEP BEGINSS

Function DAP_CheckProc_InsertTP(cba) : CheckBoxControl
	struct WMCheckBoxAction &cba

	string panelTitle
	variable testPulseDuration, existingOnsetDelay, onsetDelayResetValue

	switch(cba.eventCode)
		case 2:
			panelTitle = cba.win
			testPulseDuration = 2 * GetSetVariable(panelTitle, "SetVar_DataAcq_TPDuration")
			existingOnsetDelay = GetSetVariable(panelTitle, "setvar_DataAcq_OnsetDelay")

			if(cba.checked)
				if(ExistingOnsetDelay < testPulseDuration) // only increases onset delay if it is not big enough to for the TP
					Setvariable setvar_DataAcq_OnsetDelay WIN = $panelTitle, value =_NUM:testPulseDuration, limits = {testPulseDuration, inf, 1}
				endif
			else
				onsetDelayResetValue = max(0, (ExistingOnsetDelay - testPulseDuration)) // makes sure onset delay is never less than 0
				Setvariable setvar_DataAcq_OnsetDelay WIN = $panelTitle, value =_NUM:OnsetDelayResetValue, limits = {0, inf, 1}
			endif
		break
	endswitch

	return 0
End

Function DAP_SetVarProc_TPDuration(sva) : SetVariableControl
	struct WMSetVariableAction &sva

	string panelTitle
	variable val

	switch(sva.eventCode)
		case 2:
			panelTitle = sva.win
			val = sva.dval

			if(GetCheckBoxState(panelTitle, "Check_Settings_InsertTP"))
				Setvariable setvar_DataAcq_OnsetDelay WIN = $panelTitle, value =_NUM:(val * 2), limits = {(val * 2), inf, 1}
			endif
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
			if(GetCheckBoxState(panelTitle, "check_Settings_MD"))
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

	sweepNo = GetSetVariable(panelTitle, "SetVar_Sweep") - 1
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
