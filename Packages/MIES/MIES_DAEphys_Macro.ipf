#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors = 1

#ifdef AUTOMATED_TESTING
#pragma ModuleName = MIES_DAPM
#endif // AUTOMATED_TESTING

/// @file MIES_DAEphys_Macro.ipf
/// @brief __DA__ DA_Ephys panel macro

Window DA_Ephys() : Panel
	PauseUpdate; Silent 1 // building window...
	NewPanel/K=1/W=(1315, 92, 1818, 968)
	GroupBox group_pipette_offset_VC, pos={237.00, 171.00}, size={210.00, 27.00}, disable=1
	GroupBox group_pipette_offset_VC, userdata(tabnum)="0"
	GroupBox group_pipette_offset_VC, userdata(tabcontrol)="tab_DataAcq_Amp"
	GroupBox group_pipette_offset_VC, userdata(ResizeControlsInfo)=A"!!,H)!!#A:!!#Aa!!#=Cz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	GroupBox group_pipette_offset_VC, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	GroupBox group_pipette_offset_VC, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	GroupBox group_pipette_offset_VC, userdata(Config_DontRestore)="1"
	GroupBox group_pipette_offset_VC, userdata(Config_DontSave)="1"
	ValDisplay valdisp_DataAcq_P_LED_Clear, pos={366.00, 297.00}, size={84.00, 27.00}, disable=1
	ValDisplay valdisp_DataAcq_P_LED_Clear, help={"red:user"}, userdata(tabnum)="0"
	ValDisplay valdisp_DataAcq_P_LED_Clear, userdata(tabcontrol)="tab_DataAcq_Pressure"
	ValDisplay valdisp_DataAcq_P_LED_Clear, userdata(ResizeControlsInfo)=A"!!,Hr!!#BO!!#?e!!#=K!!!!\"!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	ValDisplay valdisp_DataAcq_P_LED_Clear, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	ValDisplay valdisp_DataAcq_P_LED_Clear, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	ValDisplay valdisp_DataAcq_P_LED_Clear, frame=0
	ValDisplay valdisp_DataAcq_P_LED_Clear, limits={0, 1, 0.5}, barmisc={0, 0}, mode=2, highColor=(65535, 16385, 16385), lowColor=(61423, 61423, 61423), zeroColor=(65535, 16385, 16385)
	ValDisplay valdisp_DataAcq_P_LED_Clear, value=_NUM:0
	ValDisplay valdisp_DataAcq_P_LED_BreakIn, pos={255.00, 297.00}, size={84.00, 27.00}, disable=1
	ValDisplay valdisp_DataAcq_P_LED_BreakIn, help={"red:user"}, userdata(tabnum)="0"
	ValDisplay valdisp_DataAcq_P_LED_BreakIn, userdata(tabcontrol)="tab_DataAcq_Pressure"
	ValDisplay valdisp_DataAcq_P_LED_BreakIn, userdata(ResizeControlsInfo)=A"!!,H;!!#BO!!#?e!!#=K!!!!\"!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	ValDisplay valdisp_DataAcq_P_LED_BreakIn, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	ValDisplay valdisp_DataAcq_P_LED_BreakIn, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	ValDisplay valdisp_DataAcq_P_LED_BreakIn, frame=0
	ValDisplay valdisp_DataAcq_P_LED_BreakIn, limits={0, 1, 0.5}, barmisc={0, 0}, mode=2, highColor=(65535, 16385, 16385), lowColor=(61423, 61423, 61423), zeroColor=(65535, 16385, 16385)
	ValDisplay valdisp_DataAcq_P_LED_BreakIn, value=_NUM:0
	ValDisplay valdisp_DataAcq_P_LED_Seal, pos={147.00, 297.00}, size={84.00, 27.00}, disable=1
	ValDisplay valdisp_DataAcq_P_LED_Seal, help={"red:user"}, userdata(tabnum)="0"
	ValDisplay valdisp_DataAcq_P_LED_Seal, userdata(tabcontrol)="tab_DataAcq_Pressure"
	ValDisplay valdisp_DataAcq_P_LED_Seal, userdata(ResizeControlsInfo)=A"!!,G\"!!#BO!!#?e!!#=K!!!!\"!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	ValDisplay valdisp_DataAcq_P_LED_Seal, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	ValDisplay valdisp_DataAcq_P_LED_Seal, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	ValDisplay valdisp_DataAcq_P_LED_Seal, frame=0
	ValDisplay valdisp_DataAcq_P_LED_Seal, limits={0, 1, 0.5}, barmisc={0, 0}, mode=2, highColor=(65535, 16385, 16385), lowColor=(61423, 61423, 61423), zeroColor=(65535, 16385, 16385)
	ValDisplay valdisp_DataAcq_P_LED_Seal, value=_NUM:0
	ValDisplay valdisp_DataAcq_P_LED_Approach, pos={36.00, 297.00}, size={84.00, 27.00}, disable=1
	ValDisplay valdisp_DataAcq_P_LED_Approach, help={"red:user"}, userdata(tabnum)="0"
	ValDisplay valdisp_DataAcq_P_LED_Approach, userdata(tabcontrol)="tab_DataAcq_Pressure"
	ValDisplay valdisp_DataAcq_P_LED_Approach, userdata(ResizeControlsInfo)=A"!!,Ct!!#BO!!#?e!!#=K!!!!\"!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	ValDisplay valdisp_DataAcq_P_LED_Approach, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	ValDisplay valdisp_DataAcq_P_LED_Approach, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	ValDisplay valdisp_DataAcq_P_LED_Approach, frame=0
	ValDisplay valdisp_DataAcq_P_LED_Approach, limits={0, 1, 0.5}, barmisc={0, 0}, mode=2, highColor=(65535, 16385, 16385), lowColor=(61423, 61423, 61423), zeroColor=(65535, 16385, 16385)
	ValDisplay valdisp_DataAcq_P_LED_Approach, value=_NUM:0
	ValDisplay valdisp_DataAcq_P_LED_7, pos={405.00, 345.00}, size={42.00, 27.00}, disable=1
	ValDisplay valdisp_DataAcq_P_LED_7, help={"Blue:Automated mode, Purple:Manual, Red:User"}
	ValDisplay valdisp_DataAcq_P_LED_7, userdata(tabnum)="0"
	ValDisplay valdisp_DataAcq_P_LED_7, userdata(tabcontrol)="ADC"
	ValDisplay valdisp_DataAcq_P_LED_7, userdata(ResizeControlsInfo)=A"!!,I1J,hs=J,hne!!#=K!!!!\"!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	ValDisplay valdisp_DataAcq_P_LED_7, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	ValDisplay valdisp_DataAcq_P_LED_7, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	ValDisplay valdisp_DataAcq_P_LED_7, userdata(ControlArray)="valdisp_DataAcq_P_LED"
	ValDisplay valdisp_DataAcq_P_LED_7, userdata(ControlArrayIndex)="7", frame=5
	ValDisplay valdisp_DataAcq_P_LED_7, limits={-1, 2, 0}, barmisc={0, 0}, mode=2, highColor=(65535, 49000, 49000), lowColor=(65535, 65535, 65535), zeroColor=(49151, 53155, 65535)
	ValDisplay valdisp_DataAcq_P_LED_7, value=_NUM:-1
	ValDisplay valdisp_DataAcq_P_LED_6, pos={362.00, 345.00}, size={42.00, 27.00}, disable=1
	ValDisplay valdisp_DataAcq_P_LED_6, help={"Blue:Automated mode, Purple:Manual, Red:User"}
	ValDisplay valdisp_DataAcq_P_LED_6, userdata(tabnum)="0"
	ValDisplay valdisp_DataAcq_P_LED_6, userdata(tabcontrol)="ADC"
	ValDisplay valdisp_DataAcq_P_LED_6, userdata(ResizeControlsInfo)=A"!!,Hq!!#BgJ,hne!!#=K!!!!\"!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	ValDisplay valdisp_DataAcq_P_LED_6, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	ValDisplay valdisp_DataAcq_P_LED_6, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	ValDisplay valdisp_DataAcq_P_LED_6, userdata(ControlArray)="valdisp_DataAcq_P_LED"
	ValDisplay valdisp_DataAcq_P_LED_6, userdata(ControlArrayIndex)="6", frame=5
	ValDisplay valdisp_DataAcq_P_LED_6, limits={-1, 2, 0}, barmisc={0, 0}, mode=2, highColor=(65535, 49000, 49000), lowColor=(65535, 65535, 65535), zeroColor=(49151, 53155, 65535)
	ValDisplay valdisp_DataAcq_P_LED_6, value=_NUM:-1
	ValDisplay valdisp_DataAcq_P_LED_5, pos={319.00, 345.00}, size={42.00, 27.00}, disable=1
	ValDisplay valdisp_DataAcq_P_LED_5, help={"Blue:Automated mode, Purple:Manual, Red:User"}
	ValDisplay valdisp_DataAcq_P_LED_5, userdata(tabnum)="0"
	ValDisplay valdisp_DataAcq_P_LED_5, userdata(tabcontrol)="ADC"
	ValDisplay valdisp_DataAcq_P_LED_5, userdata(ResizeControlsInfo)=A"!!,H[J,hs=J,hne!!#=K!!!!\"!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	ValDisplay valdisp_DataAcq_P_LED_5, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	ValDisplay valdisp_DataAcq_P_LED_5, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	ValDisplay valdisp_DataAcq_P_LED_5, userdata(ControlArray)="valdisp_DataAcq_P_LED"
	ValDisplay valdisp_DataAcq_P_LED_5, userdata(ControlArrayIndex)="5", frame=5
	ValDisplay valdisp_DataAcq_P_LED_5, limits={-1, 2, 0}, barmisc={0, 0}, mode=2, highColor=(65535, 49000, 49000), lowColor=(65535, 65535, 65535), zeroColor=(49151, 53155, 65535)
	ValDisplay valdisp_DataAcq_P_LED_5, value=_NUM:-1
	ValDisplay valdisp_DataAcq_P_LED_4, pos={276.00, 345.00}, size={42.00, 27.00}, disable=1
	ValDisplay valdisp_DataAcq_P_LED_4, help={"Blue:Automated mode, Purple:Manual, Red:User"}
	ValDisplay valdisp_DataAcq_P_LED_4, userdata(tabnum)="0"
	ValDisplay valdisp_DataAcq_P_LED_4, userdata(tabcontrol)="ADC"
	ValDisplay valdisp_DataAcq_P_LED_4, userdata(ResizeControlsInfo)=A"!!,HF!!#BgJ,hne!!#=K!!!!\"!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	ValDisplay valdisp_DataAcq_P_LED_4, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	ValDisplay valdisp_DataAcq_P_LED_4, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	ValDisplay valdisp_DataAcq_P_LED_4, userdata(ControlArray)="valdisp_DataAcq_P_LED"
	ValDisplay valdisp_DataAcq_P_LED_4, userdata(ControlArrayIndex)="4", frame=5
	ValDisplay valdisp_DataAcq_P_LED_4, valueBackColor=(61423, 61423, 61423)
	ValDisplay valdisp_DataAcq_P_LED_4, limits={-1, 2, 0}, barmisc={0, 0}, mode=2, highColor=(65535, 49000, 49000), lowColor=(65535, 65535, 65535), zeroColor=(49151, 53155, 65535)
	ValDisplay valdisp_DataAcq_P_LED_4, value=_NUM:-1
	ValDisplay valdisp_DataAcq_P_LED_4, limitsBackColor=(61423, 61423, 61423)
	ValDisplay valdisp_DataAcq_P_LED_3, pos={233.00, 345.00}, size={42.00, 27.00}, disable=1
	ValDisplay valdisp_DataAcq_P_LED_3, help={"Blue:Automated mode, Purple:Manual, Red:User"}
	ValDisplay valdisp_DataAcq_P_LED_3, userdata(tabnum)="0"
	ValDisplay valdisp_DataAcq_P_LED_3, userdata(tabcontrol)="ADC"
	ValDisplay valdisp_DataAcq_P_LED_3, userdata(ResizeControlsInfo)=A"!!,H&!!#BgJ,hne!!#=K!!!!\"!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	ValDisplay valdisp_DataAcq_P_LED_3, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	ValDisplay valdisp_DataAcq_P_LED_3, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	ValDisplay valdisp_DataAcq_P_LED_3, userdata(ControlArray)="valdisp_DataAcq_P_LED"
	ValDisplay valdisp_DataAcq_P_LED_3, userdata(ControlArrayIndex)="3", frame=5
	ValDisplay valdisp_DataAcq_P_LED_3, limits={-1, 2, 0}, barmisc={0, 0}, mode=2, highColor=(65535, 49000, 49000), lowColor=(65535, 65535, 65535), zeroColor=(49151, 53155, 65535)
	ValDisplay valdisp_DataAcq_P_LED_3, value=_NUM:-1
	ValDisplay valdisp_DataAcq_P_LED_2, pos={190.00, 345.00}, size={42.00, 27.00}, disable=1
	ValDisplay valdisp_DataAcq_P_LED_2, help={"Blue:Automated mode, Purple:Manual, Red:User"}
	ValDisplay valdisp_DataAcq_P_LED_2, userdata(tabnum)="0"
	ValDisplay valdisp_DataAcq_P_LED_2, userdata(tabcontrol)="ADC"
	ValDisplay valdisp_DataAcq_P_LED_2, userdata(ResizeControlsInfo)=A"!!,GP!!#BgJ,hne!!#=K!!!!\"!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	ValDisplay valdisp_DataAcq_P_LED_2, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	ValDisplay valdisp_DataAcq_P_LED_2, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	ValDisplay valdisp_DataAcq_P_LED_2, userdata(ControlArray)="valdisp_DataAcq_P_LED"
	ValDisplay valdisp_DataAcq_P_LED_2, userdata(ControlArrayIndex)="2", frame=5
	ValDisplay valdisp_DataAcq_P_LED_2, limits={-1, 2, 0}, barmisc={0, 0}, mode=2, highColor=(65535, 49000, 49000), lowColor=(65535, 65535, 65535), zeroColor=(49151, 53155, 65535)
	ValDisplay valdisp_DataAcq_P_LED_2, value=_NUM:-1
	ValDisplay valdisp_DataAcq_P_LED_0, pos={105.00, 345.00}, size={42.00, 27.00}, disable=1
	ValDisplay valdisp_DataAcq_P_LED_0, help={"Blue:Automated mode, Purple:Manual, Red:User"}
	ValDisplay valdisp_DataAcq_P_LED_0, userdata(tabnum)="0"
	ValDisplay valdisp_DataAcq_P_LED_0, userdata(tabcontrol)="ADC"
	ValDisplay valdisp_DataAcq_P_LED_0, userdata(ResizeControlsInfo)=A"!!,F9!!#BgJ,hne!!#=K!!!!\"!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	ValDisplay valdisp_DataAcq_P_LED_0, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	ValDisplay valdisp_DataAcq_P_LED_0, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	ValDisplay valdisp_DataAcq_P_LED_0, userdata(ControlArray)="valdisp_DataAcq_P_LED"
	ValDisplay valdisp_DataAcq_P_LED_0, userdata(ControlArrayIndex)="0", frame=5
	ValDisplay valdisp_DataAcq_P_LED_0, limits={-1, 2, 0}, barmisc={0, 0}, mode=2, highColor=(65535, 49000, 49000), lowColor=(65535, 65535, 65535), zeroColor=(49151, 53155, 65535)
	ValDisplay valdisp_DataAcq_P_LED_0, value=_NUM:-1
	ValDisplay valdisp_DataAcq_P_LED_1, pos={147.00, 345.00}, size={42.00, 27.00}, disable=1
	ValDisplay valdisp_DataAcq_P_LED_1, help={"Blue:Automated mode, Purple:Manual, Red:User"}
	ValDisplay valdisp_DataAcq_P_LED_1, userdata(tabnum)="0"
	ValDisplay valdisp_DataAcq_P_LED_1, userdata(tabcontrol)="ADC"
	ValDisplay valdisp_DataAcq_P_LED_1, userdata(ResizeControlsInfo)=A"!!,G%!!#BgJ,hne!!#=K!!!!\"!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	ValDisplay valdisp_DataAcq_P_LED_1, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	ValDisplay valdisp_DataAcq_P_LED_1, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	ValDisplay valdisp_DataAcq_P_LED_1, userdata(ControlArray)="valdisp_DataAcq_P_LED"
	ValDisplay valdisp_DataAcq_P_LED_1, userdata(ControlArrayIndex)="1", frame=5
	ValDisplay valdisp_DataAcq_P_LED_1, limits={-1, 2, 0}, barmisc={0, 0}, mode=2, highColor=(65535, 49000, 49000), lowColor=(65535, 65535, 65535), zeroColor=(49151, 53155, 65535)
	ValDisplay valdisp_DataAcq_P_LED_1, value=_NUM:-1
	ValDisplay valdisp_DataAcq_P_3, pos={238.00, 351.00}, size={35.00, 21.00}, bodyWidth=35, disable=1
	ValDisplay valdisp_DataAcq_P_3, userdata(tabcontrol)="tab_DataAcq_Pressure"
	ValDisplay valdisp_DataAcq_P_3, userdata(ResizeControlsInfo)=A"!!,H*!!#BiJ,hnE!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	ValDisplay valdisp_DataAcq_P_3, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	ValDisplay valdisp_DataAcq_P_3, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	ValDisplay valdisp_DataAcq_P_3, userdata(ControlArray)="valdisp_DataAcq_P"
	ValDisplay valdisp_DataAcq_P_3, userdata(ControlArrayIndex)="3", fSize=14, frame=0
	ValDisplay valdisp_DataAcq_P_3, fStyle=0, valueBackColor=(65535, 65535, 65535, 0)
	ValDisplay valdisp_DataAcq_P_3, limits={0, 0, 0}, barmisc={0, 1000}, value=#"0.00"
	GroupBox group_DataAcq_WholeCell, pos={39.00, 198.00}, size={150.00, 60.00}, disable=1
	GroupBox group_DataAcq_WholeCell, title="       Whole Cell", userdata(tabnum)="0"
	GroupBox group_DataAcq_WholeCell, userdata(tabcontrol)="tab_DataAcq_Amp"
	GroupBox group_DataAcq_WholeCell, userdata(ResizeControlsInfo)=A"!!,D3!!#AW!!#A%!!#?1z!!,c)Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	GroupBox group_DataAcq_WholeCell, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	GroupBox group_DataAcq_WholeCell, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	GroupBox group_DataAcq_WholeCell, userdata(Config_DontRestore)="1"
	GroupBox group_DataAcq_WholeCell, userdata(Config_DontSave)="1"
	TitleBox Title_settings_SetManagement, pos={948.00, -99.00}, size={390.00, 213.00}, disable=1
	TitleBox Title_settings_SetManagement, title="Set Management Decision Tree"
	TitleBox Title_settings_SetManagement, userdata(tabnum)="5"
	TitleBox Title_settings_SetManagement, userdata(tabcontrol)="ADC"
	TitleBox Title_settings_SetManagement, userdata(ResizeControlsInfo)=A"!!,K)!!'mW!!#C)!!#Adz!!,c)Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox Title_settings_SetManagement, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	TitleBox Title_settings_SetManagement, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	TitleBox Title_settings_SetManagement, font="Trebuchet MS", frame=4, fStyle=0
	TitleBox Title_settings_SetManagement, fixedSize=1
	TabControl ADC, pos={3.00, 0.00}, size={477.00, 18.00}, proc=ACL_DisplayTab
	TabControl ADC, userdata(currenttab)="6"
	TabControl ADC, userdata(finalhook)="DAP_TabControlFinalHook"
	TabControl ADC, userdata(ResizeControlsInfo)=A"!!,>M!!#66!!#CTJ,hm&z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TabControl ADC, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	TabControl ADC, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	TabControl ADC, userdata(tabcontrol)="ADC", tabLabel(0)="Data Acquisition"
	TabControl ADC, tabLabel(1)="DA", tabLabel(2)="AD", tabLabel(3)="TTL"
	TabControl ADC, tabLabel(4)="Asynchronous", tabLabel(5)="Settings"
	TabControl ADC, tabLabel(6)="Hardware", value=6
	CheckBox Check_AD_00, pos={18.00, 75.00}, size={22.00, 15.00}, disable=1, proc=DAP_CheckProc_AD
	CheckBox Check_AD_00, title="0", userdata(tabnum)="2", userdata(tabcontrol)="ADC"
	CheckBox Check_AD_00, userdata(ResizeControlsInfo)=A"!!,BY!!#?O!!#<`!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_AD_00, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_AD_00, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_AD_00, userdata(ControlArray)="Check_AD"
	CheckBox Check_AD_00, userdata(ControlArrayIndex)="0", value=0, side=1
	CheckBox Check_AD_01, pos={18.00, 120.00}, size={22.00, 15.00}, disable=1, proc=DAP_CheckProc_AD
	CheckBox Check_AD_01, title="1", userdata(tabnum)="2", userdata(tabcontrol)="ADC"
	CheckBox Check_AD_01, userdata(ResizeControlsInfo)=A"!!,BY!!#@V!!#<`!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_AD_01, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_AD_01, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_AD_01, userdata(ControlArray)="Check_AD"
	CheckBox Check_AD_01, userdata(ControlArrayIndex)="1", value=0, side=1
	CheckBox Check_AD_02, pos={18.00, 165.00}, size={22.00, 15.00}, disable=1, proc=DAP_CheckProc_AD
	CheckBox Check_AD_02, title="2", userdata(tabnum)="2", userdata(tabcontrol)="ADC"
	CheckBox Check_AD_02, userdata(ResizeControlsInfo)=A"!!,BY!!#A6!!#<`!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_AD_02, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_AD_02, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_AD_02, userdata(ControlArray)="Check_AD"
	CheckBox Check_AD_02, userdata(ControlArrayIndex)="2", value=0, side=1
	CheckBox Check_AD_03, pos={18.00, 213.00}, size={22.00, 15.00}, disable=1, proc=DAP_CheckProc_AD
	CheckBox Check_AD_03, title="3", userdata(tabnum)="2", userdata(tabcontrol)="ADC"
	CheckBox Check_AD_03, userdata(ResizeControlsInfo)=A"!!,BY!!#Ae!!#<`!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_AD_03, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_AD_03, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_AD_03, userdata(ControlArray)="Check_AD"
	CheckBox Check_AD_03, userdata(ControlArrayIndex)="3", value=0, side=1
	CheckBox Check_AD_04, pos={18.00, 258.00}, size={22.00, 15.00}, disable=1, proc=DAP_CheckProc_AD
	CheckBox Check_AD_04, title="4", userdata(tabnum)="2", userdata(tabcontrol)="ADC"
	CheckBox Check_AD_04, userdata(ResizeControlsInfo)=A"!!,BY!!#B<!!#<`!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_AD_04, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_AD_04, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_AD_04, userdata(ControlArray)="Check_AD"
	CheckBox Check_AD_04, userdata(ControlArrayIndex)="4", value=0, side=1
	CheckBox Check_AD_05, pos={18.00, 306.00}, size={22.00, 15.00}, disable=1, proc=DAP_CheckProc_AD
	CheckBox Check_AD_05, title="5", userdata(tabnum)="2", userdata(tabcontrol)="ADC"
	CheckBox Check_AD_05, userdata(ResizeControlsInfo)=A"!!,BY!!#BSJ,hm6!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_AD_05, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_AD_05, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_AD_05, userdata(ControlArray)="Check_AD"
	CheckBox Check_AD_05, userdata(ControlArrayIndex)="5", value=0, side=1
	CheckBox Check_AD_06, pos={18.00, 351.00}, size={22.00, 15.00}, disable=1, proc=DAP_CheckProc_AD
	CheckBox Check_AD_06, title="6", userdata(tabnum)="2", userdata(tabcontrol)="ADC"
	CheckBox Check_AD_06, userdata(ResizeControlsInfo)=A"!!,BY!!#BjJ,hm6!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_AD_06, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_AD_06, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_AD_06, userdata(ControlArray)="Check_AD"
	CheckBox Check_AD_06, userdata(ControlArrayIndex)="6", value=0, side=1
	CheckBox Check_AD_07, pos={18.00, 399.00}, size={22.00, 15.00}, disable=1, proc=DAP_CheckProc_AD
	CheckBox Check_AD_07, title="7", userdata(tabnum)="2", userdata(tabcontrol)="ADC"
	CheckBox Check_AD_07, userdata(ResizeControlsInfo)=A"!!,BY!!#C-!!#<`!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_AD_07, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_AD_07, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_AD_07, userdata(ControlArray)="Check_AD"
	CheckBox Check_AD_07, userdata(ControlArrayIndex)="7", value=0, side=1
	CheckBox Check_AD_08, pos={198.00, 75.00}, size={22.00, 15.00}, disable=1, proc=DAP_CheckProc_AD
	CheckBox Check_AD_08, title="8", userdata(tabnum)="2", userdata(tabcontrol)="ADC"
	CheckBox Check_AD_08, userdata(ResizeControlsInfo)=A"!!,GX!!#?O!!#<`!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_AD_08, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_AD_08, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_AD_08, userdata(ControlArray)="Check_AD"
	CheckBox Check_AD_08, userdata(ControlArrayIndex)="8", value=0, side=1
	CheckBox Check_AD_09, pos={198.00, 120.00}, size={22.00, 15.00}, disable=1, proc=DAP_CheckProc_AD
	CheckBox Check_AD_09, title="9", userdata(tabnum)="2", userdata(tabcontrol)="ADC"
	CheckBox Check_AD_09, userdata(ResizeControlsInfo)=A"!!,GX!!#@V!!#<`!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_AD_09, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_AD_09, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_AD_09, userdata(ControlArray)="Check_AD"
	CheckBox Check_AD_09, userdata(ControlArrayIndex)="9", value=0, side=1
	CheckBox Check_AD_10, pos={192.00, 165.00}, size={28.00, 15.00}, disable=1, proc=DAP_CheckProc_AD
	CheckBox Check_AD_10, title="10", userdata(tabnum)="2", userdata(tabcontrol)="ADC"
	CheckBox Check_AD_10, userdata(ResizeControlsInfo)=A"!!,GR!!#A6!!#=;!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_AD_10, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_AD_10, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_AD_10, userdata(ControlArray)="Check_AD"
	CheckBox Check_AD_10, userdata(ControlArrayIndex)="10", value=0, side=1
	CheckBox Check_AD_12, pos={192.00, 258.00}, size={28.00, 15.00}, disable=1, proc=DAP_CheckProc_AD
	CheckBox Check_AD_12, title="12", userdata(tabnum)="2", userdata(tabcontrol)="ADC"
	CheckBox Check_AD_12, userdata(ResizeControlsInfo)=A"!!,GR!!#B<!!#=;!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_AD_12, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_AD_12, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_AD_12, userdata(ControlArray)="Check_AD"
	CheckBox Check_AD_12, userdata(ControlArrayIndex)="12", value=0, side=1
	CheckBox Check_AD_11, pos={192.00, 213.00}, size={28.00, 15.00}, disable=1, proc=DAP_CheckProc_AD
	CheckBox Check_AD_11, title="11", userdata(tabnum)="2", userdata(tabcontrol)="ADC"
	CheckBox Check_AD_11, userdata(ResizeControlsInfo)=A"!!,GR!!#Ae!!#=;!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_AD_11, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_AD_11, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_AD_11, userdata(ControlArray)="Check_AD"
	CheckBox Check_AD_11, userdata(ControlArrayIndex)="11", value=0, side=1
	SetVariable Gain_AD_00, pos={43.00, 75.00}, size={58.00, 18.00}, bodyWidth=58, disable=1, proc=DAP_SetVar_UpdateGuiState
	SetVariable Gain_AD_00, userdata(tabnum)="2", userdata(tabcontrol)="ADC"
	SetVariable Gain_AD_00, userdata(ResizeControlsInfo)=A"!!,DW!!#?O!!#>V!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Gain_AD_00, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Gain_AD_00, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Gain_AD_00, userdata(ControlArray)="Gain_AD"
	SetVariable Gain_AD_00, userdata(ControlArrayIndex)="0"
	SetVariable Gain_AD_00, limits={0, Inf, 1}, value=_NUM:0
	SetVariable Gain_AD_01, pos={43.00, 120.00}, size={58.00, 18.00}, bodyWidth=58, disable=1, proc=DAP_SetVar_UpdateGuiState
	SetVariable Gain_AD_01, userdata(tabnum)="2", userdata(tabcontrol)="ADC"
	SetVariable Gain_AD_01, userdata(ResizeControlsInfo)=A"!!,DW!!#@V!!#>V!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Gain_AD_01, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Gain_AD_01, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Gain_AD_01, userdata(ControlArray)="Gain_AD"
	SetVariable Gain_AD_01, userdata(ControlArrayIndex)="1"
	SetVariable Gain_AD_01, limits={0, Inf, 1}, value=_NUM:0
	SetVariable Gain_AD_02, pos={43.00, 165.00}, size={58.00, 18.00}, bodyWidth=58, disable=1, proc=DAP_SetVar_UpdateGuiState
	SetVariable Gain_AD_02, userdata(tabnum)="2", userdata(tabcontrol)="ADC"
	SetVariable Gain_AD_02, userdata(ResizeControlsInfo)=A"!!,DW!!#A6!!#>V!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Gain_AD_02, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Gain_AD_02, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Gain_AD_02, userdata(ControlArray)="Gain_AD"
	SetVariable Gain_AD_02, userdata(ControlArrayIndex)="2"
	SetVariable Gain_AD_02, limits={0, Inf, 1}, value=_NUM:0
	SetVariable Gain_AD_03, pos={43.00, 213.00}, size={58.00, 18.00}, bodyWidth=58, disable=1, proc=DAP_SetVar_UpdateGuiState
	SetVariable Gain_AD_03, userdata(tabnum)="2", userdata(tabcontrol)="ADC"
	SetVariable Gain_AD_03, userdata(ResizeControlsInfo)=A"!!,DW!!#Ae!!#>V!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Gain_AD_03, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Gain_AD_03, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Gain_AD_03, userdata(ControlArray)="Gain_AD"
	SetVariable Gain_AD_03, userdata(ControlArrayIndex)="3"
	SetVariable Gain_AD_03, limits={0, Inf, 1}, value=_NUM:0
	SetVariable Gain_AD_04, pos={43.00, 258.00}, size={58.00, 18.00}, bodyWidth=58, disable=1, proc=DAP_SetVar_UpdateGuiState
	SetVariable Gain_AD_04, userdata(tabnum)="2", userdata(tabcontrol)="ADC"
	SetVariable Gain_AD_04, userdata(ResizeControlsInfo)=A"!!,DW!!#B<!!#>V!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Gain_AD_04, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Gain_AD_04, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Gain_AD_04, userdata(ControlArray)="Gain_AD"
	SetVariable Gain_AD_04, userdata(ControlArrayIndex)="4"
	SetVariable Gain_AD_04, limits={0, Inf, 1}, value=_NUM:0
	SetVariable Gain_AD_05, pos={43.00, 306.00}, size={58.00, 18.00}, bodyWidth=58, disable=1, proc=DAP_SetVar_UpdateGuiState
	SetVariable Gain_AD_05, userdata(tabnum)="2", userdata(tabcontrol)="ADC"
	SetVariable Gain_AD_05, userdata(ResizeControlsInfo)=A"!!,DW!!#BSJ,ho,!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Gain_AD_05, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Gain_AD_05, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Gain_AD_05, userdata(ControlArray)="Gain_AD"
	SetVariable Gain_AD_05, userdata(ControlArrayIndex)="5"
	SetVariable Gain_AD_05, limits={0, Inf, 1}, value=_NUM:0
	SetVariable Gain_AD_06, pos={43.00, 351.00}, size={58.00, 18.00}, bodyWidth=58, disable=1, proc=DAP_SetVar_UpdateGuiState
	SetVariable Gain_AD_06, userdata(tabnum)="2", userdata(tabcontrol)="ADC"
	SetVariable Gain_AD_06, userdata(ResizeControlsInfo)=A"!!,DW!!#BjJ,ho,!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Gain_AD_06, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Gain_AD_06, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Gain_AD_06, userdata(ControlArray)="Gain_AD"
	SetVariable Gain_AD_06, userdata(ControlArrayIndex)="6"
	SetVariable Gain_AD_06, limits={0, Inf, 1}, value=_NUM:0
	SetVariable Gain_AD_07, pos={43.00, 399.00}, size={58.00, 18.00}, bodyWidth=58, disable=1, proc=DAP_SetVar_UpdateGuiState
	SetVariable Gain_AD_07, userdata(tabnum)="2", userdata(tabcontrol)="ADC"
	SetVariable Gain_AD_07, userdata(ResizeControlsInfo)=A"!!,DW!!#C-!!#>V!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Gain_AD_07, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Gain_AD_07, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Gain_AD_07, userdata(ControlArray)="Gain_AD"
	SetVariable Gain_AD_07, userdata(ControlArrayIndex)="7"
	SetVariable Gain_AD_07, limits={0, Inf, 1}, value=_NUM:0
	SetVariable Gain_AD_08, pos={223.00, 75.00}, size={58.00, 18.00}, bodyWidth=58, disable=1, proc=DAP_SetVar_UpdateGuiState
	SetVariable Gain_AD_08, userdata(tabnum)="2", userdata(tabcontrol)="ADC"
	SetVariable Gain_AD_08, userdata(ResizeControlsInfo)=A"!!,Gu!!#?O!!#>V!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Gain_AD_08, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Gain_AD_08, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Gain_AD_08, userdata(ControlArray)="Gain_AD"
	SetVariable Gain_AD_08, userdata(ControlArrayIndex)="8"
	SetVariable Gain_AD_08, limits={0, Inf, 1}, value=_NUM:0
	SetVariable Gain_AD_09, pos={223.00, 120.00}, size={58.00, 18.00}, bodyWidth=58, disable=1, proc=DAP_SetVar_UpdateGuiState
	SetVariable Gain_AD_09, userdata(tabnum)="2", userdata(tabcontrol)="ADC"
	SetVariable Gain_AD_09, userdata(ResizeControlsInfo)=A"!!,Gu!!#@V!!#>V!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Gain_AD_09, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Gain_AD_09, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Gain_AD_09, userdata(ControlArray)="Gain_AD"
	SetVariable Gain_AD_09, userdata(ControlArrayIndex)="9"
	SetVariable Gain_AD_09, limits={0, Inf, 1}, value=_NUM:0
	SetVariable Gain_AD_10, pos={223.00, 165.00}, size={58.00, 18.00}, bodyWidth=58, disable=1, proc=DAP_SetVar_UpdateGuiState
	SetVariable Gain_AD_10, userdata(tabnum)="2", userdata(tabcontrol)="ADC"
	SetVariable Gain_AD_10, userdata(ResizeControlsInfo)=A"!!,Gu!!#A6!!#>V!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Gain_AD_10, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Gain_AD_10, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Gain_AD_10, userdata(ControlArray)="Gain_AD"
	SetVariable Gain_AD_10, userdata(ControlArrayIndex)="10"
	SetVariable Gain_AD_10, limits={0, Inf, 1}, value=_NUM:0
	SetVariable Gain_AD_11, pos={223.00, 213.00}, size={58.00, 18.00}, bodyWidth=58, disable=1, proc=DAP_SetVar_UpdateGuiState
	SetVariable Gain_AD_11, userdata(tabnum)="2", userdata(tabcontrol)="ADC"
	SetVariable Gain_AD_11, userdata(ResizeControlsInfo)=A"!!,Gu!!#Ae!!#>V!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Gain_AD_11, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Gain_AD_11, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Gain_AD_11, userdata(ControlArray)="Gain_AD"
	SetVariable Gain_AD_11, userdata(ControlArrayIndex)="11"
	SetVariable Gain_AD_11, limits={0, Inf, 1}, value=_NUM:0
	SetVariable Gain_AD_12, pos={223.00, 258.00}, size={58.00, 18.00}, bodyWidth=58, disable=1, proc=DAP_SetVar_UpdateGuiState
	SetVariable Gain_AD_12, userdata(tabnum)="2", userdata(tabcontrol)="ADC"
	SetVariable Gain_AD_12, userdata(ResizeControlsInfo)=A"!!,Gu!!#B<!!#>V!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Gain_AD_12, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Gain_AD_12, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Gain_AD_12, userdata(ControlArray)="Gain_AD"
	SetVariable Gain_AD_12, userdata(ControlArrayIndex)="12"
	SetVariable Gain_AD_12, limits={0, Inf, 1}, value=_NUM:0
	CheckBox Check_AD_13, pos={192.00, 306.00}, size={28.00, 15.00}, disable=1, proc=DAP_CheckProc_AD
	CheckBox Check_AD_13, title="13", userdata(tabnum)="2", userdata(tabcontrol)="ADC"
	CheckBox Check_AD_13, userdata(ResizeControlsInfo)=A"!!,GR!!#BSJ,hmf!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_AD_13, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_AD_13, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_AD_13, userdata(ControlArray)="Check_AD"
	CheckBox Check_AD_13, userdata(ControlArrayIndex)="13", value=0, side=1
	CheckBox Check_AD_14, pos={192.00, 351.00}, size={28.00, 15.00}, disable=1, proc=DAP_CheckProc_AD
	CheckBox Check_AD_14, title="14", userdata(tabnum)="2", userdata(tabcontrol)="ADC"
	CheckBox Check_AD_14, userdata(ResizeControlsInfo)=A"!!,GR!!#BjJ,hmf!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_AD_14, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_AD_14, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_AD_14, userdata(ControlArray)="Check_AD"
	CheckBox Check_AD_14, userdata(ControlArrayIndex)="14", value=0, side=1
	CheckBox Check_AD_15, pos={192.00, 399.00}, size={28.00, 15.00}, disable=1, proc=DAP_CheckProc_AD
	CheckBox Check_AD_15, title="15", userdata(tabnum)="2", userdata(tabcontrol)="ADC"
	CheckBox Check_AD_15, userdata(ResizeControlsInfo)=A"!!,GR!!#C-!!#=;!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_AD_15, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_AD_15, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_AD_15, userdata(ControlArray)="Check_AD"
	CheckBox Check_AD_15, userdata(ControlArrayIndex)="15", value=0, side=1
	SetVariable Gain_AD_13, pos={223.00, 306.00}, size={58.00, 18.00}, bodyWidth=58, disable=1, proc=DAP_SetVar_UpdateGuiState
	SetVariable Gain_AD_13, userdata(tabnum)="2", userdata(tabcontrol)="ADC"
	SetVariable Gain_AD_13, userdata(ResizeControlsInfo)=A"!!,Gu!!#BSJ,ho,!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Gain_AD_13, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Gain_AD_13, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Gain_AD_13, userdata(ControlArray)="Gain_AD"
	SetVariable Gain_AD_13, userdata(ControlArrayIndex)="13"
	SetVariable Gain_AD_13, limits={0, Inf, 1}, value=_NUM:0
	SetVariable Gain_AD_14, pos={223.00, 351.00}, size={58.00, 18.00}, bodyWidth=58, disable=1, proc=DAP_SetVar_UpdateGuiState
	SetVariable Gain_AD_14, userdata(tabnum)="2", userdata(tabcontrol)="ADC"
	SetVariable Gain_AD_14, userdata(ResizeControlsInfo)=A"!!,Gu!!#BjJ,ho,!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Gain_AD_14, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Gain_AD_14, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Gain_AD_14, userdata(ControlArray)="Gain_AD"
	SetVariable Gain_AD_14, userdata(ControlArrayIndex)="14"
	SetVariable Gain_AD_14, limits={0, Inf, 1}, value=_NUM:0
	SetVariable Gain_AD_15, pos={223.00, 399.00}, size={58.00, 18.00}, bodyWidth=58, disable=1, proc=DAP_SetVar_UpdateGuiState
	SetVariable Gain_AD_15, userdata(tabnum)="2", userdata(tabcontrol)="ADC"
	SetVariable Gain_AD_15, userdata(ResizeControlsInfo)=A"!!,Gu!!#C-!!#>V!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Gain_AD_15, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Gain_AD_15, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Gain_AD_15, userdata(ControlArray)="Gain_AD"
	SetVariable Gain_AD_15, userdata(ControlArrayIndex)="15"
	SetVariable Gain_AD_15, limits={0, Inf, 1}, value=_NUM:0
	CheckBox Check_DA_00, pos={18.00, 75.00}, size={22.00, 15.00}, disable=1, proc=DAP_DAorTTLCheckProc
	CheckBox Check_DA_00, title="0", userdata(tabnum)="1", userdata(tabcontrol)="ADC"
	CheckBox Check_DA_00, userdata(ResizeControlsInfo)=A"!!,BY!!#?O!!#<`!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_DA_00, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_DA_00, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_DA_00, userdata(ControlArray)="Check_DA"
	CheckBox Check_DA_00, userdata(ControlArrayIndex)="0", value=0, side=1
	CheckBox Check_DA_01, pos={18.00, 120.00}, size={22.00, 15.00}, disable=1, proc=DAP_DAorTTLCheckProc
	CheckBox Check_DA_01, title="1", userdata(tabnum)="1", userdata(tabcontrol)="ADC"
	CheckBox Check_DA_01, userdata(ResizeControlsInfo)=A"!!,BY!!#@V!!#<`!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_DA_01, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_DA_01, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_DA_01, userdata(ControlArray)="Check_DA"
	CheckBox Check_DA_01, userdata(ControlArrayIndex)="1", value=0, side=1
	CheckBox Check_DA_02, pos={18.00, 165.00}, size={22.00, 15.00}, disable=1, proc=DAP_DAorTTLCheckProc
	CheckBox Check_DA_02, title="2", userdata(tabnum)="1", userdata(tabcontrol)="ADC"
	CheckBox Check_DA_02, userdata(ResizeControlsInfo)=A"!!,BY!!#A6!!#<`!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_DA_02, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_DA_02, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_DA_02, userdata(ControlArray)="Check_DA"
	CheckBox Check_DA_02, userdata(ControlArrayIndex)="2", value=0, side=1
	CheckBox Check_DA_03, pos={18.00, 213.00}, size={22.00, 15.00}, disable=1, proc=DAP_DAorTTLCheckProc
	CheckBox Check_DA_03, title="3", userdata(tabnum)="1", userdata(tabcontrol)="ADC"
	CheckBox Check_DA_03, userdata(ResizeControlsInfo)=A"!!,BY!!#Ae!!#<`!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_DA_03, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_DA_03, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_DA_03, userdata(ControlArray)="Check_DA"
	CheckBox Check_DA_03, userdata(ControlArrayIndex)="3", value=0, side=1
	CheckBox Check_DA_04, pos={18.00, 258.00}, size={22.00, 15.00}, disable=1, proc=DAP_DAorTTLCheckProc
	CheckBox Check_DA_04, title="4", userdata(tabnum)="1", userdata(tabcontrol)="ADC"
	CheckBox Check_DA_04, userdata(ResizeControlsInfo)=A"!!,BY!!#B<!!#<`!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_DA_04, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_DA_04, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_DA_04, userdata(ControlArray)="Check_DA"
	CheckBox Check_DA_04, userdata(ControlArrayIndex)="4", value=0, side=1
	CheckBox Check_DA_05, pos={18.00, 306.00}, size={22.00, 15.00}, disable=1, proc=DAP_DAorTTLCheckProc
	CheckBox Check_DA_05, title="5", userdata(tabnum)="1", userdata(tabcontrol)="ADC"
	CheckBox Check_DA_05, userdata(ResizeControlsInfo)=A"!!,BY!!#BSJ,hm6!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_DA_05, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_DA_05, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_DA_05, userdata(ControlArray)="Check_DA"
	CheckBox Check_DA_05, userdata(ControlArrayIndex)="5", value=0, side=1
	CheckBox Check_DA_06, pos={18.00, 351.00}, size={22.00, 15.00}, disable=1, proc=DAP_DAorTTLCheckProc
	CheckBox Check_DA_06, title="6", userdata(tabnum)="1", userdata(tabcontrol)="ADC"
	CheckBox Check_DA_06, userdata(ResizeControlsInfo)=A"!!,BY!!#BjJ,hm6!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_DA_06, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_DA_06, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_DA_06, userdata(ControlArray)="Check_DA"
	CheckBox Check_DA_06, userdata(ControlArrayIndex)="6", value=0, side=1
	CheckBox Check_DA_07, pos={18.00, 399.00}, size={22.00, 15.00}, disable=1, proc=DAP_DAorTTLCheckProc
	CheckBox Check_DA_07, title="7", userdata(tabnum)="1", userdata(tabcontrol)="ADC"
	CheckBox Check_DA_07, userdata(ResizeControlsInfo)=A"!!,BY!!#C-!!#<`!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_DA_07, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_DA_07, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_DA_07, userdata(ControlArray)="Check_DA"
	CheckBox Check_DA_07, userdata(ControlArrayIndex)="7", value=0, side=1
	SetVariable Gain_DA_00, pos={43.00, 75.00}, size={58.00, 18.00}, disable=1, proc=DAP_SetVar_UpdateGuiState
	SetVariable Gain_DA_00, userdata(tabnum)="1", userdata(tabcontrol)="ADC"
	SetVariable Gain_DA_00, userdata(ResizeControlsInfo)=A"!!,DW!!#?O!!#>V!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Gain_DA_00, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Gain_DA_00, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Gain_DA_00, userdata(ControlArray)="Gain_DA"
	SetVariable Gain_DA_00, userdata(ControlArrayIndex)="0"
	SetVariable Gain_DA_00, limits={0, Inf, 1}, value=_NUM:0
	SetVariable Gain_DA_01, pos={43.00, 120.00}, size={58.00, 18.00}, disable=1, proc=DAP_SetVar_UpdateGuiState
	SetVariable Gain_DA_01, userdata(tabnum)="1", userdata(tabcontrol)="ADC"
	SetVariable Gain_DA_01, userdata(ResizeControlsInfo)=A"!!,DW!!#@V!!#>V!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Gain_DA_01, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Gain_DA_01, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Gain_DA_01, userdata(ControlArray)="Gain_DA"
	SetVariable Gain_DA_01, userdata(ControlArrayIndex)="1"
	SetVariable Gain_DA_01, limits={0, Inf, 1}, value=_NUM:0
	SetVariable Gain_DA_02, pos={43.00, 165.00}, size={58.00, 18.00}, disable=1, proc=DAP_SetVar_UpdateGuiState
	SetVariable Gain_DA_02, userdata(tabnum)="1", userdata(tabcontrol)="ADC"
	SetVariable Gain_DA_02, userdata(ResizeControlsInfo)=A"!!,DW!!#A6!!#>V!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Gain_DA_02, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Gain_DA_02, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Gain_DA_02, userdata(ControlArray)="Gain_DA"
	SetVariable Gain_DA_02, userdata(ControlArrayIndex)="2"
	SetVariable Gain_DA_02, limits={0, Inf, 1}, value=_NUM:0
	SetVariable Gain_DA_03, pos={43.00, 213.00}, size={58.00, 18.00}, disable=1, proc=DAP_SetVar_UpdateGuiState
	SetVariable Gain_DA_03, userdata(tabnum)="1", userdata(tabcontrol)="ADC"
	SetVariable Gain_DA_03, userdata(ResizeControlsInfo)=A"!!,DW!!#Ae!!#>V!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Gain_DA_03, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Gain_DA_03, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Gain_DA_03, userdata(ControlArray)="Gain_DA"
	SetVariable Gain_DA_03, userdata(ControlArrayIndex)="3"
	SetVariable Gain_DA_03, limits={0, Inf, 1}, value=_NUM:0
	SetVariable Gain_DA_04, pos={43.00, 258.00}, size={58.00, 18.00}, disable=1, proc=DAP_SetVar_UpdateGuiState
	SetVariable Gain_DA_04, userdata(tabnum)="1", userdata(tabcontrol)="ADC"
	SetVariable Gain_DA_04, userdata(ResizeControlsInfo)=A"!!,DW!!#B<!!#>V!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Gain_DA_04, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Gain_DA_04, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Gain_DA_04, userdata(ControlArray)="Gain_DA"
	SetVariable Gain_DA_04, userdata(ControlArrayIndex)="4"
	SetVariable Gain_DA_04, limits={0, Inf, 1}, value=_NUM:0
	SetVariable Gain_DA_05, pos={43.00, 306.00}, size={58.00, 18.00}, disable=1, proc=DAP_SetVar_UpdateGuiState
	SetVariable Gain_DA_05, userdata(tabnum)="1", userdata(tabcontrol)="ADC"
	SetVariable Gain_DA_05, userdata(ResizeControlsInfo)=A"!!,DW!!#BSJ,ho,!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Gain_DA_05, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Gain_DA_05, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Gain_DA_05, userdata(ControlArray)="Gain_DA"
	SetVariable Gain_DA_05, userdata(ControlArrayIndex)="5"
	SetVariable Gain_DA_05, limits={0, Inf, 1}, value=_NUM:0
	SetVariable Gain_DA_06, pos={43.00, 351.00}, size={58.00, 18.00}, disable=1, proc=DAP_SetVar_UpdateGuiState
	SetVariable Gain_DA_06, userdata(tabnum)="1", userdata(tabcontrol)="ADC"
	SetVariable Gain_DA_06, userdata(ResizeControlsInfo)=A"!!,DW!!#BjJ,ho,!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Gain_DA_06, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Gain_DA_06, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Gain_DA_06, userdata(ControlArray)="Gain_DA"
	SetVariable Gain_DA_06, userdata(ControlArrayIndex)="6"
	SetVariable Gain_DA_06, limits={0, Inf, 1}, value=_NUM:0
	SetVariable Gain_DA_07, pos={43.00, 399.00}, size={58.00, 18.00}, disable=1, proc=DAP_SetVar_UpdateGuiState
	SetVariable Gain_DA_07, userdata(tabnum)="1", userdata(tabcontrol)="ADC"
	SetVariable Gain_DA_07, userdata(ResizeControlsInfo)=A"!!,DW!!#C-!!#>V!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Gain_DA_07, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Gain_DA_07, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Gain_DA_07, userdata(ControlArray)="Gain_DA"
	SetVariable Gain_DA_07, userdata(ControlArrayIndex)="7"
	SetVariable Gain_DA_07, limits={0, Inf, 1}, value=_NUM:0
	PopupMenu Wave_DA_00, pos={135.00, 75.00}, size={138.00, 19.00}, bodyWidth=125, disable=1, proc=DAP_PopMenuChkProc_StimSetList
	PopupMenu Wave_DA_00, title="/V", userdata(tabnum)="1", userdata(tabcontrol)="ADC"
	PopupMenu Wave_DA_00, userdata(ResizeControlsInfo)=A"!!,Fq!!#?O!!#@n!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Wave_DA_00, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Wave_DA_00, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Wave_DA_00, userdata(ControlArray)="Wave_DA"
	PopupMenu Wave_DA_00, userdata(ControlArrayIndex)="0", fSize=10
	PopupMenu Wave_DA_00, mode=1, popvalue="- none -", value=#"\"- none -;\"+ST_GetStimsetList(channelType = 0, searchString = \"*\")"
	PopupMenu Wave_DA_01, pos={135.00, 120.00}, size={138.00, 19.00}, bodyWidth=125, disable=1, proc=DAP_PopMenuChkProc_StimSetList
	PopupMenu Wave_DA_01, title="/V", userdata(tabnum)="1", userdata(tabcontrol)="ADC"
	PopupMenu Wave_DA_01, userdata(ResizeControlsInfo)=A"!!,Fq!!#@V!!#@n!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Wave_DA_01, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Wave_DA_01, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Wave_DA_01, userdata(ControlArray)="Wave_DA"
	PopupMenu Wave_DA_01, userdata(ControlArrayIndex)="1", fSize=10
	PopupMenu Wave_DA_01, mode=1, popvalue="- none -", value=#"\"- none -;\"+ST_GetStimsetList(channelType = 0, searchString = \"*\")"
	PopupMenu Wave_DA_02, pos={135.00, 165.00}, size={138.00, 19.00}, bodyWidth=125, disable=1, proc=DAP_PopMenuChkProc_StimSetList
	PopupMenu Wave_DA_02, title="/V", userdata(tabnum)="1", userdata(tabcontrol)="ADC"
	PopupMenu Wave_DA_02, userdata(ResizeControlsInfo)=A"!!,Fq!!#A6!!#@n!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Wave_DA_02, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Wave_DA_02, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Wave_DA_02, userdata(ControlArray)="Wave_DA"
	PopupMenu Wave_DA_02, userdata(ControlArrayIndex)="2", fSize=10
	PopupMenu Wave_DA_02, mode=1, popvalue="- none -", value=#"\"- none -;\"+ST_GetStimsetList(channelType = 0, searchString = \"*\")"
	PopupMenu Wave_DA_03, pos={135.00, 213.00}, size={138.00, 19.00}, bodyWidth=125, disable=1, proc=DAP_PopMenuChkProc_StimSetList
	PopupMenu Wave_DA_03, title="/V", userdata(tabnum)="1", userdata(tabcontrol)="ADC"
	PopupMenu Wave_DA_03, userdata(ResizeControlsInfo)=A"!!,Fq!!#Ae!!#@n!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Wave_DA_03, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Wave_DA_03, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Wave_DA_03, userdata(ControlArray)="Wave_DA"
	PopupMenu Wave_DA_03, userdata(ControlArrayIndex)="3", fSize=10
	PopupMenu Wave_DA_03, mode=1, popvalue="- none -", value=#"\"- none -;\"+ST_GetStimsetList(channelType = 0, searchString = \"*\")"
	PopupMenu Wave_DA_04, pos={135.00, 258.00}, size={138.00, 19.00}, bodyWidth=125, disable=1, proc=DAP_PopMenuChkProc_StimSetList
	PopupMenu Wave_DA_04, title="/V", userdata(tabnum)="1", userdata(tabcontrol)="ADC"
	PopupMenu Wave_DA_04, userdata(ResizeControlsInfo)=A"!!,Fq!!#B<!!#@n!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Wave_DA_04, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Wave_DA_04, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Wave_DA_04, userdata(ControlArray)="Wave_DA"
	PopupMenu Wave_DA_04, userdata(ControlArrayIndex)="4", fSize=10
	PopupMenu Wave_DA_04, mode=1, popvalue="- none -", value=#"\"- none -;\"+ST_GetStimsetList(channelType = 0, searchString = \"*\")"
	PopupMenu Wave_DA_05, pos={135.00, 306.00}, size={138.00, 19.00}, bodyWidth=125, disable=1, proc=DAP_PopMenuChkProc_StimSetList
	PopupMenu Wave_DA_05, title="/V", userdata(tabnum)="1", userdata(tabcontrol)="ADC"
	PopupMenu Wave_DA_05, userdata(ResizeControlsInfo)=A"!!,Fq!!#BSJ,hqD!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Wave_DA_05, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Wave_DA_05, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Wave_DA_05, userdata(ControlArray)="Wave_DA"
	PopupMenu Wave_DA_05, userdata(ControlArrayIndex)="5", fSize=10
	PopupMenu Wave_DA_05, mode=1, popvalue="- none -", value=#"\"- none -;\"+ST_GetStimsetList(channelType = 0, searchString = \"*\")"
	PopupMenu Wave_DA_06, pos={135.00, 351.00}, size={138.00, 19.00}, bodyWidth=125, disable=1, proc=DAP_PopMenuChkProc_StimSetList
	PopupMenu Wave_DA_06, title="/V", userdata(tabnum)="1", userdata(tabcontrol)="ADC"
	PopupMenu Wave_DA_06, userdata(ResizeControlsInfo)=A"!!,Fq!!#BjJ,hqD!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Wave_DA_06, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Wave_DA_06, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Wave_DA_06, userdata(ControlArray)="Wave_DA"
	PopupMenu Wave_DA_06, userdata(ControlArrayIndex)="6", fSize=10
	PopupMenu Wave_DA_06, mode=1, popvalue="- none -", value=#"\"- none -;\"+ST_GetStimsetList(channelType = 0, searchString = \"*\")"
	PopupMenu Wave_DA_07, pos={135.00, 399.00}, size={138.00, 19.00}, bodyWidth=125, disable=1, proc=DAP_PopMenuChkProc_StimSetList
	PopupMenu Wave_DA_07, title="/V", userdata(tabnum)="1", userdata(tabcontrol)="ADC"
	PopupMenu Wave_DA_07, userdata(ResizeControlsInfo)=A"!!,Fq!!#C-!!#@n!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Wave_DA_07, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Wave_DA_07, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Wave_DA_07, userdata(ControlArray)="Wave_DA"
	PopupMenu Wave_DA_07, userdata(ControlArrayIndex)="7", fSize=10
	PopupMenu Wave_DA_07, mode=1, popvalue="- none -", value=#"\"- none -;\"+ST_GetStimsetList(channelType = 0, searchString = \"*\")"
	SetVariable Scale_DA_00, pos={288.00, 75.00}, size={48.00, 18.00}, disable=1, proc=DAP_SetVar_SetScale
	SetVariable Scale_DA_00, userdata(tabnum)="1", userdata(tabcontrol)="ADC"
	SetVariable Scale_DA_00, userdata(ResizeControlsInfo)=A"!!,HL!!#?O!!#>V!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Scale_DA_00, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Scale_DA_00, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Scale_DA_00, userdata(ControlArray)="Scale_DA"
	SetVariable Scale_DA_00, userdata(ControlArrayIndex)="0"
	SetVariable Scale_DA_00, userdata(DefaultIncrement)="10"
	SetVariable Scale_DA_00, limits={-Inf, Inf, 10}, value=_NUM:1
	SetVariable Scale_DA_01, pos={288.00, 120.00}, size={48.00, 18.00}, disable=1, proc=DAP_SetVar_SetScale
	SetVariable Scale_DA_01, userdata(tabnum)="1", userdata(tabcontrol)="ADC"
	SetVariable Scale_DA_01, userdata(ResizeControlsInfo)=A"!!,HL!!#@V!!#>V!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Scale_DA_01, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Scale_DA_01, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Scale_DA_01, userdata(ControlArray)="Scale_DA"
	SetVariable Scale_DA_01, userdata(ControlArrayIndex)="1"
	SetVariable Scale_DA_01, userdata(DefaultIncrement)="10"
	SetVariable Scale_DA_01, limits={-Inf, Inf, 10}, value=_NUM:1
	SetVariable Scale_DA_02, pos={288.00, 165.00}, size={48.00, 18.00}, disable=1, proc=DAP_SetVar_SetScale
	SetVariable Scale_DA_02, userdata(tabnum)="1", userdata(tabcontrol)="ADC"
	SetVariable Scale_DA_02, userdata(ResizeControlsInfo)=A"!!,HL!!#A6!!#>V!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Scale_DA_02, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Scale_DA_02, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Scale_DA_02, userdata(ControlArray)="Scale_DA"
	SetVariable Scale_DA_02, userdata(ControlArrayIndex)="2"
	SetVariable Scale_DA_02, userdata(DefaultIncrement)="10"
	SetVariable Scale_DA_02, limits={-Inf, Inf, 10}, value=_NUM:1
	SetVariable Scale_DA_03, pos={288.00, 213.00}, size={48.00, 18.00}, disable=1, proc=DAP_SetVar_SetScale
	SetVariable Scale_DA_03, userdata(tabnum)="1", userdata(tabcontrol)="ADC"
	SetVariable Scale_DA_03, userdata(ResizeControlsInfo)=A"!!,HL!!#Ae!!#>V!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Scale_DA_03, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Scale_DA_03, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Scale_DA_03, userdata(ControlArray)="Scale_DA"
	SetVariable Scale_DA_03, userdata(ControlArrayIndex)="3"
	SetVariable Scale_DA_03, userdata(DefaultIncrement)="10"
	SetVariable Scale_DA_03, limits={-Inf, Inf, 10}, value=_NUM:1
	SetVariable Scale_DA_04, pos={288.00, 258.00}, size={48.00, 18.00}, disable=1, proc=DAP_SetVar_SetScale
	SetVariable Scale_DA_04, userdata(tabnum)="1", userdata(tabcontrol)="ADC"
	SetVariable Scale_DA_04, userdata(ResizeControlsInfo)=A"!!,HL!!#B<!!#>V!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Scale_DA_04, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Scale_DA_04, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Scale_DA_04, userdata(ControlArray)="Scale_DA"
	SetVariable Scale_DA_04, userdata(ControlArrayIndex)="4"
	SetVariable Scale_DA_04, userdata(DefaultIncrement)="10"
	SetVariable Scale_DA_04, limits={-Inf, Inf, 10}, value=_NUM:1
	SetVariable Scale_DA_05, pos={288.00, 306.00}, size={48.00, 18.00}, disable=1, proc=DAP_SetVar_SetScale
	SetVariable Scale_DA_05, userdata(tabnum)="1", userdata(tabcontrol)="ADC"
	SetVariable Scale_DA_05, userdata(ResizeControlsInfo)=A"!!,HL!!#BSJ,ho,!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Scale_DA_05, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Scale_DA_05, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Scale_DA_05, userdata(ControlArray)="Scale_DA"
	SetVariable Scale_DA_05, userdata(ControlArrayIndex)="5"
	SetVariable Scale_DA_05, userdata(DefaultIncrement)="10"
	SetVariable Scale_DA_05, limits={-Inf, Inf, 10}, value=_NUM:1
	SetVariable Scale_DA_06, pos={288.00, 351.00}, size={48.00, 18.00}, disable=1, proc=DAP_SetVar_SetScale
	SetVariable Scale_DA_06, userdata(tabnum)="1", userdata(tabcontrol)="ADC"
	SetVariable Scale_DA_06, userdata(ResizeControlsInfo)=A"!!,HL!!#BjJ,ho,!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Scale_DA_06, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Scale_DA_06, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Scale_DA_06, userdata(ControlArray)="Scale_DA"
	SetVariable Scale_DA_06, userdata(ControlArrayIndex)="6"
	SetVariable Scale_DA_06, userdata(DefaultIncrement)="10"
	SetVariable Scale_DA_06, limits={-Inf, Inf, 10}, value=_NUM:1
	SetVariable Scale_DA_07, pos={283.00, 399.00}, size={50.00, 18.00}, bodyWidth=50, disable=1, proc=DAP_SetVar_SetScale
	SetVariable Scale_DA_07, userdata(tabnum)="1", userdata(tabcontrol)="ADC"
	SetVariable Scale_DA_07, userdata(ResizeControlsInfo)=A"!!,HL!!#C-!!#>V!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Scale_DA_07, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Scale_DA_07, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Scale_DA_07, userdata(ControlArray)="Scale_DA"
	SetVariable Scale_DA_07, userdata(ControlArrayIndex)="7"
	SetVariable Scale_DA_07, userdata(DefaultIncrement)="10"
	SetVariable Scale_DA_07, limits={-Inf, Inf, 10}, value=_NUM:1
	SetVariable SetVar_DataAcq_Comment, pos={42.00, 775.00}, size={373.00, 22.00}, disable=1, proc=DAP_SetVar_UpdateGuiState
	SetVariable SetVar_DataAcq_Comment, title="Comment"
	SetVariable SetVar_DataAcq_Comment, help={"Appends a comment to wave note of next sweep"}
	SetVariable SetVar_DataAcq_Comment, userdata(tabnum)="0"
	SetVariable SetVar_DataAcq_Comment, userdata(tabcontrol)="ADC"
	SetVariable SetVar_DataAcq_Comment, userdata(ResizeControlsInfo)=A"!!,DO!!#DS5QF0Z!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_DataAcq_Comment, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_DataAcq_Comment, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_DataAcq_Comment, fSize=14, value=_STR:""
	Button DataAcquireButton, pos={42.00, 798.00}, size={405.00, 42.00}, disable=1, proc=DAP_ButtonProc_TPDAQ
	Button DataAcquireButton, title="\\Z14\\f01Acquire\rData", userdata(tabnum)="0"
	Button DataAcquireButton, userdata(tabcontrol)="ADC"
	Button DataAcquireButton, userdata(ResizeControlsInfo)=A"!!,D?!!#DW^]6aEJ,hnaz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button DataAcquireButton, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button DataAcquireButton, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	Button DataAcquireButton, labelBack=(60928, 60928, 60928)
	CheckBox Check_DataAcq1_RepeatAcq, pos={46.00, 637.00}, size={89.00, 15.00}, disable=1, proc=DAP_CheckProc_RepeatedAcq
	CheckBox Check_DataAcq1_RepeatAcq, title="Repeated Acq"
	CheckBox Check_DataAcq1_RepeatAcq, help={"Determines number of times a set is repeated, or if indexing is on, the number of times a group of sets in repeated"}
	CheckBox Check_DataAcq1_RepeatAcq, userdata(tabnum)="0"
	CheckBox Check_DataAcq1_RepeatAcq, userdata(tabcontrol)="ADC"
	CheckBox Check_DataAcq1_RepeatAcq, userdata(ResizeControlsInfo)=A"!!,Cd!!#D1!!#?i!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_DataAcq1_RepeatAcq, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_DataAcq1_RepeatAcq, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_DataAcq1_RepeatAcq, value=1
	SetVariable SetVar_DataAcq_ITI, pos={57.00, 711.00}, size={79.00, 18.00}, bodyWidth=35, disable=1, proc=DAP_SetVarProc_SyncCtrl
	SetVariable SetVar_DataAcq_ITI, title="\\JCITl (sec)"
	SetVariable SetVar_DataAcq_ITI, help={"Sweep start to start interval"}
	SetVariable SetVar_DataAcq_ITI, userdata(tabnum)="0", userdata(tabcontrol)="ADC"
	SetVariable SetVar_DataAcq_ITI, userdata(ResizeControlsInfo)=A"!!,E*!!#D?!!#?Y!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_DataAcq_ITI, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_DataAcq_ITI, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_DataAcq_ITI, limits={0, Inf, 1}, value=_NUM:0
	Button StartTestPulseButton, pos={42.00, 450.00}, size={405.00, 39.00}, disable=1, proc=DAP_ButtonProc_TPDAQ
	Button StartTestPulseButton, title="\\Z14\\f01Start Test \rPulse"
	Button StartTestPulseButton, help={"Starts generating test pulses. Can be stopped by pressing the Escape key."}
	Button StartTestPulseButton, userdata(tabnum)="0", userdata(tabcontrol)="ADC"
	Button StartTestPulseButton, userdata(ResizeControlsInfo)=A"!!,D;!!#CC!!#C/J,hnYz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button StartTestPulseButton, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button StartTestPulseButton, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_DataAcqHS_00, pos={129.00, 84.00}, size={22.00, 15.00}, disable=1, proc=DAP_CheckProc_HedstgeChck
	CheckBox Check_DataAcqHS_00, title="0", userdata(tabnum)="0"
	CheckBox Check_DataAcqHS_00, userdata(tabcontrol)="ADC"
	CheckBox Check_DataAcqHS_00, userdata(ResizeControlsInfo)=A"!!,Ff!!#?e!!#<`!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_DataAcqHS_00, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_DataAcqHS_00, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_DataAcqHS_00, userdata(ControlArray)="Check_DataAcqHS"
	CheckBox Check_DataAcqHS_00, userdata(ControlArrayIndex)="0", value=0
	SetVariable SetVar_DataAcq_TPDuration, pos={31.00, 405.00}, size={127.00, 18.00}, bodyWidth=50, disable=1, proc=DAP_SetVarProc_TestPulseSett
	SetVariable SetVar_DataAcq_TPDuration, title="Duration (ms)"
	SetVariable SetVar_DataAcq_TPDuration, help={"Duration of the testpulse in milliseconds"}
	SetVariable SetVar_DataAcq_TPDuration, userdata(tabnum)="0"
	SetVariable SetVar_DataAcq_TPDuration, userdata(tabcontrol)="ADC"
	SetVariable SetVar_DataAcq_TPDuration, userdata(ResizeControlsInfo)=A"!!,DG!!#C5J,hq8!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_DataAcq_TPDuration, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_DataAcq_TPDuration, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_DataAcq_TPDuration, userdata(Config_GroupPath)="Test Pulse"
	SetVariable SetVar_DataAcq_TPDuration, limits={1, Inf, 5}, value=_NUM:10
	SetVariable SetVar_DataAcq_TPBaselinePerc, pos={40.00, 428.00}, size={118.00, 18.00}, bodyWidth=50, disable=1, proc=DAP_SetVarProc_TestPulseSett
	SetVariable SetVar_DataAcq_TPBaselinePerc, title="Baseline (%)"
	SetVariable SetVar_DataAcq_TPBaselinePerc, help={"Length of the baseline before and after the testpulse, in parts of the total testpulse duration"}
	SetVariable SetVar_DataAcq_TPBaselinePerc, userdata(tabnum)="0"
	SetVariable SetVar_DataAcq_TPBaselinePerc, userdata(tabcontrol)="ADC"
	SetVariable SetVar_DataAcq_TPBaselinePerc, userdata(ResizeControlsInfo)=A"!!,GC!!#C5J,hq&!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_DataAcq_TPBaselinePerc, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_DataAcq_TPBaselinePerc, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_DataAcq_TPBaselinePerc, userdata(Config_GroupPath)="Test Pulse"
	SetVariable SetVar_DataAcq_TPBaselinePerc, limits={25, 49, 1}, value=_NUM:35
	SetVariable SetVar_DataAcq_TPAmplitude, pos={201.00, 405.00}, size={69.00, 18.00}, bodyWidth=50, disable=1, proc=DAP_SetVarProc_TestPulseSett
	SetVariable SetVar_DataAcq_TPAmplitude, title="VC"
	SetVariable SetVar_DataAcq_TPAmplitude, help={"Amplitude of the testpulse in voltage clamp mode"}
	SetVariable SetVar_DataAcq_TPAmplitude, userdata(tabnum)="0"
	SetVariable SetVar_DataAcq_TPAmplitude, userdata(tabcontrol)="ADC"
	SetVariable SetVar_DataAcq_TPAmplitude, userdata(ResizeControlsInfo)=A"!!,HU!!#C5J,hon!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_DataAcq_TPAmplitude, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_DataAcq_TPAmplitude, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_DataAcq_TPAmplitude, userdata(Config_GroupPath)="Test Pulse"
	SetVariable SetVar_DataAcq_TPAmplitude, value=_NUM:10
	CheckBox Check_TTL_00, pos={18.00, 75.00}, size={22.00, 15.00}, disable=1, proc=DAP_DAorTTLCheckProc
	CheckBox Check_TTL_00, title="0", userdata(tabnum)="3", userdata(tabcontrol)="ADC"
	CheckBox Check_TTL_00, userdata(ResizeControlsInfo)=A"!!,BY!!#?O!!#<`!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_TTL_00, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_TTL_00, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_TTL_00, userdata(ControlArray)="Check_TTL"
	CheckBox Check_TTL_00, userdata(ControlArrayIndex)="0", value=0
	CheckBox Check_TTL_01, pos={18.00, 120.00}, size={22.00, 15.00}, disable=1, proc=DAP_DAorTTLCheckProc
	CheckBox Check_TTL_01, title="1", userdata(tabnum)="3", userdata(tabcontrol)="ADC"
	CheckBox Check_TTL_01, userdata(ResizeControlsInfo)=A"!!,BY!!#@V!!#<`!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_TTL_01, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_TTL_01, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_TTL_01, userdata(ControlArray)="Check_TTL"
	CheckBox Check_TTL_01, userdata(ControlArrayIndex)="1", value=0
	CheckBox Check_TTL_02, pos={18.00, 165.00}, size={22.00, 15.00}, disable=1, proc=DAP_DAorTTLCheckProc
	CheckBox Check_TTL_02, title="2", userdata(tabnum)="3", userdata(tabcontrol)="ADC"
	CheckBox Check_TTL_02, userdata(ResizeControlsInfo)=A"!!,BY!!#A6!!#<`!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_TTL_02, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_TTL_02, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_TTL_02, userdata(ControlArray)="Check_TTL"
	CheckBox Check_TTL_02, userdata(ControlArrayIndex)="2", value=0
	CheckBox Check_TTL_03, pos={18.00, 213.00}, size={22.00, 15.00}, disable=1, proc=DAP_DAorTTLCheckProc
	CheckBox Check_TTL_03, title="3", userdata(tabnum)="3", userdata(tabcontrol)="ADC"
	CheckBox Check_TTL_03, userdata(ResizeControlsInfo)=A"!!,BY!!#Ae!!#<`!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_TTL_03, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_TTL_03, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_TTL_03, userdata(ControlArray)="Check_TTL"
	CheckBox Check_TTL_03, userdata(ControlArrayIndex)="3", value=0
	CheckBox Check_TTL_04, pos={18.00, 258.00}, size={22.00, 15.00}, disable=1, proc=DAP_DAorTTLCheckProc
	CheckBox Check_TTL_04, title="4", userdata(tabnum)="3", userdata(tabcontrol)="ADC"
	CheckBox Check_TTL_04, userdata(ResizeControlsInfo)=A"!!,BY!!#B<!!#<`!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_TTL_04, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_TTL_04, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_TTL_04, userdata(ControlArray)="Check_TTL"
	CheckBox Check_TTL_04, userdata(ControlArrayIndex)="4", value=0
	CheckBox Check_TTL_05, pos={18.00, 306.00}, size={22.00, 15.00}, disable=1, proc=DAP_DAorTTLCheckProc
	CheckBox Check_TTL_05, title="5", userdata(tabnum)="3", userdata(tabcontrol)="ADC"
	CheckBox Check_TTL_05, userdata(ResizeControlsInfo)=A"!!,BY!!#BSJ,hm6!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_TTL_05, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_TTL_05, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_TTL_05, userdata(ControlArray)="Check_TTL"
	CheckBox Check_TTL_05, userdata(ControlArrayIndex)="5", value=0
	CheckBox Check_TTL_06, pos={18.00, 351.00}, size={22.00, 15.00}, disable=1, proc=DAP_DAorTTLCheckProc
	CheckBox Check_TTL_06, title="6", userdata(tabnum)="3", userdata(tabcontrol)="ADC"
	CheckBox Check_TTL_06, userdata(ResizeControlsInfo)=A"!!,BY!!#BjJ,hm6!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_TTL_06, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_TTL_06, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_TTL_06, userdata(ControlArray)="Check_TTL"
	CheckBox Check_TTL_06, userdata(ControlArrayIndex)="6", value=0
	CheckBox Check_TTL_07, pos={18.00, 399.00}, size={22.00, 15.00}, disable=1, proc=DAP_DAorTTLCheckProc
	CheckBox Check_TTL_07, title="7", userdata(tabnum)="3", userdata(tabcontrol)="ADC"
	CheckBox Check_TTL_07, userdata(ResizeControlsInfo)=A"!!,BY!!#C-!!#<`!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_TTL_07, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_TTL_07, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_TTL_07, userdata(ControlArray)="Check_TTL"
	CheckBox Check_TTL_07, userdata(ControlArrayIndex)="7", value=0
	PopupMenu Wave_TTL_00, pos={100.00, 75.00}, size={125.00, 19.00}, bodyWidth=125, disable=1, proc=DAP_PopMenuChkProc_StimSetList
	PopupMenu Wave_TTL_00, userdata(tabnum)="3", userdata(tabcontrol)="ADC"
	PopupMenu Wave_TTL_00, userdata(ResizeControlsInfo)=A"!!,F3!!#?O!!#@^!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Wave_TTL_00, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Wave_TTL_00, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Wave_TTL_00, userdata(ControlArray)="Wave_TTL"
	PopupMenu Wave_TTL_00, userdata(ControlArrayIndex)="0"
	PopupMenu Wave_TTL_00, mode=1, popvalue="- none -", value=#"\"- none -;\"+ST_GetStimsetList(channelType = 1, searchString = \"*\")"
	PopupMenu Wave_TTL_01, pos={100.00, 120.00}, size={125.00, 19.00}, bodyWidth=125, disable=1, proc=DAP_PopMenuChkProc_StimSetList
	PopupMenu Wave_TTL_01, userdata(tabnum)="3", userdata(tabcontrol)="ADC"
	PopupMenu Wave_TTL_01, userdata(ResizeControlsInfo)=A"!!,F3!!#@V!!#@^!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Wave_TTL_01, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Wave_TTL_01, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Wave_TTL_01, userdata(ControlArray)="Wave_TTL"
	PopupMenu Wave_TTL_01, userdata(ControlArrayIndex)="1"
	PopupMenu Wave_TTL_01, mode=1, popvalue="- none -", value=#"\"- none -;\"+ST_GetStimsetList(channelType = 1, searchString = \"*\")"
	PopupMenu Wave_TTL_02, pos={100.00, 165.00}, size={125.00, 19.00}, bodyWidth=125, disable=1, proc=DAP_PopMenuChkProc_StimSetList
	PopupMenu Wave_TTL_02, userdata(tabnum)="3", userdata(tabcontrol)="ADC"
	PopupMenu Wave_TTL_02, userdata(ResizeControlsInfo)=A"!!,F3!!#A6!!#@^!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Wave_TTL_02, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Wave_TTL_02, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Wave_TTL_02, userdata(ControlArray)="Wave_TTL"
	PopupMenu Wave_TTL_02, userdata(ControlArrayIndex)="2"
	PopupMenu Wave_TTL_02, mode=1, popvalue="- none -", value=#"\"- none -;\"+ST_GetStimsetList(channelType = 1, searchString = \"*\")"
	PopupMenu Wave_TTL_03, pos={100.00, 213.00}, size={125.00, 19.00}, bodyWidth=125, disable=1, proc=DAP_PopMenuChkProc_StimSetList
	PopupMenu Wave_TTL_03, userdata(tabnum)="3", userdata(tabcontrol)="ADC"
	PopupMenu Wave_TTL_03, userdata(ResizeControlsInfo)=A"!!,F3!!#Ae!!#@^!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Wave_TTL_03, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Wave_TTL_03, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Wave_TTL_03, userdata(ControlArray)="Wave_TTL"
	PopupMenu Wave_TTL_03, userdata(ControlArrayIndex)="3"
	PopupMenu Wave_TTL_03, mode=1, popvalue="- none -", value=#"\"- none -;\"+ST_GetStimsetList(channelType = 1, searchString = \"*\")"
	PopupMenu Wave_TTL_04, pos={100.00, 258.00}, size={125.00, 19.00}, bodyWidth=125, disable=1, proc=DAP_PopMenuChkProc_StimSetList
	PopupMenu Wave_TTL_04, userdata(tabnum)="3", userdata(tabcontrol)="ADC"
	PopupMenu Wave_TTL_04, userdata(ResizeControlsInfo)=A"!!,F3!!#B<!!#@^!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Wave_TTL_04, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Wave_TTL_04, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Wave_TTL_04, userdata(ControlArray)="Wave_TTL"
	PopupMenu Wave_TTL_04, userdata(ControlArrayIndex)="4"
	PopupMenu Wave_TTL_04, mode=1, popvalue="- none -", value=#"\"- none -;\"+ST_GetStimsetList(channelType = 1, searchString = \"*\")"
	PopupMenu Wave_TTL_05, pos={100.00, 306.00}, size={125.00, 19.00}, bodyWidth=125, disable=1, proc=DAP_PopMenuChkProc_StimSetList
	PopupMenu Wave_TTL_05, userdata(tabnum)="3", userdata(tabcontrol)="ADC"
	PopupMenu Wave_TTL_05, userdata(ResizeControlsInfo)=A"!!,F3!!#BSJ,hq4!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Wave_TTL_05, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Wave_TTL_05, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Wave_TTL_05, userdata(ControlArray)="Wave_TTL"
	PopupMenu Wave_TTL_05, userdata(ControlArrayIndex)="5"
	PopupMenu Wave_TTL_05, mode=1, popvalue="- none -", value=#"\"- none -;\"+ST_GetStimsetList(channelType = 1, searchString = \"*\")"
	PopupMenu Wave_TTL_06, pos={100.00, 351.00}, size={125.00, 19.00}, bodyWidth=125, disable=1, proc=DAP_PopMenuChkProc_StimSetList
	PopupMenu Wave_TTL_06, userdata(tabnum)="3", userdata(tabcontrol)="ADC"
	PopupMenu Wave_TTL_06, userdata(ResizeControlsInfo)=A"!!,F3!!#BjJ,hq4!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Wave_TTL_06, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Wave_TTL_06, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Wave_TTL_06, userdata(ControlArray)="Wave_TTL"
	PopupMenu Wave_TTL_06, userdata(ControlArrayIndex)="6"
	PopupMenu Wave_TTL_06, mode=1, popvalue="- none -", value=#"\"- none -;\"+ST_GetStimsetList(channelType = 1, searchString = \"*\")"
	PopupMenu Wave_TTL_07, pos={100.00, 399.00}, size={125.00, 19.00}, bodyWidth=125, disable=1, proc=DAP_PopMenuChkProc_StimSetList
	PopupMenu Wave_TTL_07, userdata(tabnum)="3", userdata(tabcontrol)="ADC"
	PopupMenu Wave_TTL_07, userdata(ResizeControlsInfo)=A"!!,F3!!#C-!!#@^!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Wave_TTL_07, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Wave_TTL_07, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Wave_TTL_07, userdata(ControlArray)="Wave_TTL"
	PopupMenu Wave_TTL_07, userdata(ControlArrayIndex)="7"
	PopupMenu Wave_TTL_07, mode=1, popvalue="- none -", value=#"\"- none -;\"+ST_GetStimsetList(channelType = 1, searchString = \"*\")"
	CheckBox Check_Settings_TrigOut, pos={33.00, 255.00}, size={59.00, 15.00}, disable=1, proc=DAP_CheckProc_UpdateGuiState
	CheckBox Check_Settings_TrigOut, title="\\JCTrig Out"
	CheckBox Check_Settings_TrigOut, help={"Turns on TTL pulse at onset of sweep"}
	CheckBox Check_Settings_TrigOut, userdata(tabnum)="5", userdata(tabcontrol)="ADC"
	CheckBox Check_Settings_TrigOut, userdata(ResizeControlsInfo)=A"!!,Cl!!#B)!!#?%!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_Settings_TrigOut, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_Settings_TrigOut, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_Settings_TrigOut, fColor=(65280, 43520, 0), value=0
	CheckBox Check_Settings_TrigIn, pos={33.00, 276.00}, size={49.00, 15.00}, disable=1, proc=DAP_CheckProc_UpdateGuiState
	CheckBox Check_Settings_TrigIn, title="\\JCTrig In"
	CheckBox Check_Settings_TrigIn, help={"Starts Data Aquisition with TTL signal to trig in port on rack"}
	CheckBox Check_Settings_TrigIn, userdata(tabnum)="5", userdata(tabcontrol)="ADC"
	CheckBox Check_Settings_TrigIn, userdata(ResizeControlsInfo)=A"!!,Cl!!#B=!!#>R!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_Settings_TrigIn, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_Settings_TrigIn, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_Settings_TrigIn, fColor=(65280, 43520, 0), value=0
	SetVariable SetVar_DataAcq_SetRepeats, pos={29.00, 690.00}, size={107.00, 18.00}, bodyWidth=35, disable=1, proc=DAP_SetVarProc_TotSweepCount
	SetVariable SetVar_DataAcq_SetRepeats, title="Repeat Set(s)"
	SetVariable SetVar_DataAcq_SetRepeats, help={"This number is set automatically at based on the number of 1d waves contained in the largest set on active DA/TTL channels"}
	SetVariable SetVar_DataAcq_SetRepeats, userdata(tabnum)="0"
	SetVariable SetVar_DataAcq_SetRepeats, userdata(tabcontrol)="ADC"
	SetVariable SetVar_DataAcq_SetRepeats, userdata(ResizeControlsInfo)=A"!!,Ch!!#D:!!#@:!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_DataAcq_SetRepeats, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_DataAcq_SetRepeats, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_DataAcq_SetRepeats, limits={1, Inf, 1}, value=_NUM:1
	ValDisplay ValDisp_DataAcq_SamplingInt, pos={228.00, 576.00}, size={30.00, 21.00}, bodyWidth=30, disable=1
	ValDisplay ValDisp_DataAcq_SamplingInt, userdata(tabnum)="0"
	ValDisplay ValDisp_DataAcq_SamplingInt, userdata(tabcontrol)="ADC"
	ValDisplay ValDisp_DataAcq_SamplingInt, userdata(ResizeControlsInfo)=A"!!,Gu!!#CtJ,hn)!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	ValDisplay ValDisp_DataAcq_SamplingInt, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	ValDisplay ValDisp_DataAcq_SamplingInt, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	ValDisplay ValDisp_DataAcq_SamplingInt, fSize=14, fStyle=0
	ValDisplay ValDisp_DataAcq_SamplingInt, valueColor=(65535, 65535, 65535)
	ValDisplay ValDisp_DataAcq_SamplingInt, valueBackColor=(0, 0, 0)
	ValDisplay ValDisp_DataAcq_SamplingInt, limits={0, 0, 0}, barmisc={0, 1000}
	ValDisplay ValDisp_DataAcq_SamplingInt, value=_NUM:0
	SetVariable SetVar_Sweep, pos={210.00, 534.00}, size={75.00, 35.00}, bodyWidth=75, disable=1, proc=DAP_SetVar_UpdateGuiState
	SetVariable SetVar_Sweep, help={"Shows the sweep number of the next acquired sweep. Can not be changed."}
	SetVariable SetVar_Sweep, userdata(tabnum)="0", userdata(tabcontrol)="ADC"
	SetVariable SetVar_Sweep, userdata(ResizeControlsInfo)=A"!!,Gc!!#Cj!!#?O!!#=oz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_Sweep, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_Sweep, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_Sweep, userdata(Config_DontRestore)="1"
	SetVariable SetVar_Sweep, userdata(Config_DontSave)="1", fSize=24, fStyle=1
	SetVariable SetVar_Sweep, valueColor=(65535, 65535, 65535), valueBackColor=(0, 0, 0)
	SetVariable SetVar_Sweep, limits={0, Inf, 0}, value=_NUM:0, noedit=1
	CheckBox Check_Settings_UseDoublePrec, pos={246.00, 258.00}, size={161.00, 15.00}, disable=1, proc=DAP_CheckProc_UpdateGuiState
	CheckBox Check_Settings_UseDoublePrec, title="Use Double Precision Floats"
	CheckBox Check_Settings_UseDoublePrec, help={"Enable the saving of the raw data in double precision. If unchecked the raw data will be saved in single precision, which should be good enough for most use cases"}
	CheckBox Check_Settings_UseDoublePrec, userdata(tabnum)="5"
	CheckBox Check_Settings_UseDoublePrec, userdata(tabcontrol)="ADC"
	CheckBox Check_Settings_UseDoublePrec, userdata(ResizeControlsInfo)=A"!!,H.!!#Ai!!#A/!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_Settings_UseDoublePrec, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_Settings_UseDoublePrec, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_Settings_UseDoublePrec, value=0
	CheckBox Check_Settings_SkipAnalysFuncs, pos={246.00, 285.00}, size={156.00, 15.00}, disable=1, proc=DAP_CheckProc_UpdateGuiState
	CheckBox Check_Settings_SkipAnalysFuncs, title="Skip analysis function calls"
	CheckBox Check_Settings_SkipAnalysFuncs, help={"Should the analysis functions defined in the stim sets not be called?"}
	CheckBox Check_Settings_SkipAnalysFuncs, userdata(tabnum)="5"
	CheckBox Check_Settings_SkipAnalysFuncs, userdata(tabcontrol)="ADC"
	CheckBox Check_Settings_SkipAnalysFuncs, userdata(ResizeControlsInfo)=A"!!,H.!!#B@!!#A*!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_Settings_SkipAnalysFuncs, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_Settings_SkipAnalysFuncs, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_Settings_SkipAnalysFuncs, value=0
	CheckBox Check_AsyncAD_00, pos={171.00, 45.00}, size={41.00, 15.00}, disable=1, proc=DAP_CheckProc_UpdateGuiState
	CheckBox Check_AsyncAD_00, title="AD 0", userdata(tabnum)="4"
	CheckBox Check_AsyncAD_00, userdata(tabcontrol)="ADC"
	CheckBox Check_AsyncAD_00, userdata(ResizeControlsInfo)=A"!!,G<!!#>F!!#>.!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_AsyncAD_00, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_AsyncAD_00, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_AsyncAD_00, userdata(ControlArray)="Check_AsyncAD"
	CheckBox Check_AsyncAD_00, userdata(ControlArrayIndex)="0", value=0
	CheckBox Check_AsyncAD_01, pos={171.00, 96.00}, size={41.00, 15.00}, disable=1, proc=DAP_CheckProc_UpdateGuiState
	CheckBox Check_AsyncAD_01, title="AD 1", userdata(tabnum)="4"
	CheckBox Check_AsyncAD_01, userdata(tabcontrol)="ADC"
	CheckBox Check_AsyncAD_01, userdata(ResizeControlsInfo)=A"!!,G;!!#@&!!#>.!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_AsyncAD_01, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_AsyncAD_01, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_AsyncAD_01, userdata(ControlArray)="Check_AsyncAD"
	CheckBox Check_AsyncAD_01, userdata(ControlArrayIndex)="1", value=0
	CheckBox Check_AsyncAD_02, pos={171.00, 147.00}, size={41.00, 15.00}, disable=1, proc=DAP_CheckProc_UpdateGuiState
	CheckBox Check_AsyncAD_02, title="AD 2", userdata(tabnum)="4"
	CheckBox Check_AsyncAD_02, userdata(tabcontrol)="ADC"
	CheckBox Check_AsyncAD_02, userdata(ResizeControlsInfo)=A"!!,G;!!#A#!!#>.!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_AsyncAD_02, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_AsyncAD_02, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_AsyncAD_02, userdata(ControlArray)="Check_AsyncAD"
	CheckBox Check_AsyncAD_02, userdata(ControlArrayIndex)="2", value=0
	CheckBox Check_AsyncAD_03, pos={171.00, 198.00}, size={41.00, 15.00}, disable=1, proc=DAP_CheckProc_UpdateGuiState
	CheckBox Check_AsyncAD_03, title="AD 3", userdata(tabnum)="4"
	CheckBox Check_AsyncAD_03, userdata(tabcontrol)="ADC"
	CheckBox Check_AsyncAD_03, userdata(ResizeControlsInfo)=A"!!,G;!!#AV!!#>.!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_AsyncAD_03, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_AsyncAD_03, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_AsyncAD_03, userdata(ControlArray)="Check_AsyncAD"
	CheckBox Check_AsyncAD_03, userdata(ControlArrayIndex)="3", value=0
	CheckBox Check_AsyncAD_04, pos={171.00, 249.00}, size={41.00, 15.00}, disable=1, proc=DAP_CheckProc_UpdateGuiState
	CheckBox Check_AsyncAD_04, title="AD 4", userdata(tabnum)="4"
	CheckBox Check_AsyncAD_04, userdata(tabcontrol)="ADC"
	CheckBox Check_AsyncAD_04, userdata(ResizeControlsInfo)=A"!!,G;!!#B4!!#>.!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_AsyncAD_04, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_AsyncAD_04, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_AsyncAD_04, userdata(ControlArray)="Check_AsyncAD"
	CheckBox Check_AsyncAD_04, userdata(ControlArrayIndex)="4", value=0
	CheckBox Check_AsyncAD_05, pos={171.00, 300.00}, size={41.00, 15.00}, disable=1, proc=DAP_CheckProc_UpdateGuiState
	CheckBox Check_AsyncAD_05, title="AD 5", userdata(tabnum)="4"
	CheckBox Check_AsyncAD_05, userdata(tabcontrol)="ADC"
	CheckBox Check_AsyncAD_05, userdata(ResizeControlsInfo)=A"!!,G;!!#BPJ,hnY!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_AsyncAD_05, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_AsyncAD_05, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_AsyncAD_05, userdata(ControlArray)="Check_AsyncAD"
	CheckBox Check_AsyncAD_05, userdata(ControlArrayIndex)="5", value=0
	CheckBox Check_AsyncAD_06, pos={171.00, 351.00}, size={41.00, 15.00}, disable=1, proc=DAP_CheckProc_UpdateGuiState
	CheckBox Check_AsyncAD_06, title="AD 6", userdata(tabnum)="4"
	CheckBox Check_AsyncAD_06, userdata(tabcontrol)="ADC"
	CheckBox Check_AsyncAD_06, userdata(ResizeControlsInfo)=A"!!,G;!!#Bj!!#>.!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_AsyncAD_06, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_AsyncAD_06, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_AsyncAD_06, userdata(ControlArray)="Check_AsyncAD"
	CheckBox Check_AsyncAD_06, userdata(ControlArrayIndex)="6", value=0
	CheckBox Check_AsyncAD_07, pos={171.00, 402.00}, size={41.00, 15.00}, disable=1, proc=DAP_CheckProc_UpdateGuiState
	CheckBox Check_AsyncAD_07, title="AD 7", userdata(tabnum)="4"
	CheckBox Check_AsyncAD_07, userdata(tabcontrol)="ADC"
	CheckBox Check_AsyncAD_07, userdata(ResizeControlsInfo)=A"!!,G;!!#C/!!#>.!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_AsyncAD_07, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_AsyncAD_07, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_AsyncAD_07, userdata(ControlArray)="Check_AsyncAD"
	CheckBox Check_AsyncAD_07, userdata(ControlArrayIndex)="7", value=0
	SetVariable Gain_AsyncAD_00, pos={217.00, 42.00}, size={77.00, 18.00}, bodyWidth=50, disable=1, proc=DAP_SetVar_UpdateGuiState
	SetVariable Gain_AsyncAD_00, title="gain", userdata(tabnum)="4"
	SetVariable Gain_AsyncAD_00, userdata(tabcontrol)="ADC"
	SetVariable Gain_AsyncAD_00, userdata(ResizeControlsInfo)=A"!!,Gp!!#>>!!#?S!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Gain_AsyncAD_00, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Gain_AsyncAD_00, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Gain_AsyncAD_00, userdata(ControlArray)="Gain_AsyncAD"
	SetVariable Gain_AsyncAD_00, userdata(ControlArrayIndex)="0"
	SetVariable Gain_AsyncAD_00, limits={0, Inf, 1}, value=_NUM:1
	SetVariable Gain_AsyncAD_01, pos={217.00, 93.00}, size={77.00, 18.00}, bodyWidth=50, disable=1, proc=DAP_SetVar_UpdateGuiState
	SetVariable Gain_AsyncAD_01, title="gain", userdata(tabnum)="4"
	SetVariable Gain_AsyncAD_01, userdata(tabcontrol)="ADC"
	SetVariable Gain_AsyncAD_01, userdata(ResizeControlsInfo)=A"!!,Gp!!#@\"!!#?S!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Gain_AsyncAD_01, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Gain_AsyncAD_01, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Gain_AsyncAD_01, userdata(ControlArray)="Gain_AsyncAD"
	SetVariable Gain_AsyncAD_01, userdata(ControlArrayIndex)="1"
	SetVariable Gain_AsyncAD_01, limits={0, Inf, 1}, value=_NUM:1
	SetVariable Gain_AsyncAD_02, pos={217.00, 144.00}, size={77.00, 18.00}, bodyWidth=50, disable=1, proc=DAP_SetVar_UpdateGuiState
	SetVariable Gain_AsyncAD_02, title="gain", userdata(tabnum)="4"
	SetVariable Gain_AsyncAD_02, userdata(tabcontrol)="ADC"
	SetVariable Gain_AsyncAD_02, userdata(ResizeControlsInfo)=A"!!,Gp!!#A!!!#?S!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Gain_AsyncAD_02, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Gain_AsyncAD_02, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Gain_AsyncAD_02, userdata(ControlArray)="Gain_AsyncAD"
	SetVariable Gain_AsyncAD_02, userdata(ControlArrayIndex)="2"
	SetVariable Gain_AsyncAD_02, limits={0, Inf, 1}, value=_NUM:1
	SetVariable Gain_AsyncAD_03, pos={217.00, 195.00}, size={77.00, 18.00}, bodyWidth=50, disable=1, proc=DAP_SetVar_UpdateGuiState
	SetVariable Gain_AsyncAD_03, title="gain", userdata(tabnum)="4"
	SetVariable Gain_AsyncAD_03, userdata(tabcontrol)="ADC"
	SetVariable Gain_AsyncAD_03, userdata(ResizeControlsInfo)=A"!!,Gp!!#AT!!#?S!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Gain_AsyncAD_03, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Gain_AsyncAD_03, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Gain_AsyncAD_03, userdata(ControlArray)="Gain_AsyncAD"
	SetVariable Gain_AsyncAD_03, userdata(ControlArrayIndex)="3"
	SetVariable Gain_AsyncAD_03, limits={0, Inf, 1}, value=_NUM:1
	SetVariable Gain_AsyncAD_04, pos={217.00, 246.00}, size={77.00, 18.00}, bodyWidth=50, disable=1, proc=DAP_SetVar_UpdateGuiState
	SetVariable Gain_AsyncAD_04, title="gain", userdata(tabnum)="4"
	SetVariable Gain_AsyncAD_04, userdata(tabcontrol)="ADC"
	SetVariable Gain_AsyncAD_04, userdata(ResizeControlsInfo)=A"!!,Gp!!#B2!!#?S!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Gain_AsyncAD_04, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Gain_AsyncAD_04, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Gain_AsyncAD_04, userdata(ControlArray)="Gain_AsyncAD"
	SetVariable Gain_AsyncAD_04, userdata(ControlArrayIndex)="4"
	SetVariable Gain_AsyncAD_04, limits={0, Inf, 1}, value=_NUM:1
	SetVariable Gain_AsyncAD_05, pos={217.00, 297.00}, size={77.00, 18.00}, bodyWidth=50, disable=1, proc=DAP_SetVar_UpdateGuiState
	SetVariable Gain_AsyncAD_05, title="gain", userdata(tabnum)="4"
	SetVariable Gain_AsyncAD_05, userdata(tabcontrol)="ADC"
	SetVariable Gain_AsyncAD_05, userdata(ResizeControlsInfo)=A"!!,Gp!!#BOJ,hp)!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Gain_AsyncAD_05, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Gain_AsyncAD_05, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Gain_AsyncAD_05, userdata(ControlArray)="Gain_AsyncAD"
	SetVariable Gain_AsyncAD_05, userdata(ControlArrayIndex)="5"
	SetVariable Gain_AsyncAD_05, limits={0, Inf, 1}, value=_NUM:1
	SetVariable Gain_AsyncAD_06, pos={217.00, 348.00}, size={77.00, 18.00}, bodyWidth=50, disable=1, proc=DAP_SetVar_UpdateGuiState
	SetVariable Gain_AsyncAD_06, title="gain", userdata(tabnum)="4"
	SetVariable Gain_AsyncAD_06, userdata(tabcontrol)="ADC"
	SetVariable Gain_AsyncAD_06, userdata(ResizeControlsInfo)=A"!!,Gp!!#Bi!!#?S!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Gain_AsyncAD_06, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Gain_AsyncAD_06, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Gain_AsyncAD_06, userdata(ControlArray)="Gain_AsyncAD"
	SetVariable Gain_AsyncAD_06, userdata(ControlArrayIndex)="6"
	SetVariable Gain_AsyncAD_06, limits={0, Inf, 1}, value=_NUM:1
	SetVariable Gain_AsyncAD_07, pos={217.00, 402.00}, size={77.00, 18.00}, bodyWidth=50, disable=1, proc=DAP_SetVar_UpdateGuiState
	SetVariable Gain_AsyncAD_07, title="gain", userdata(tabnum)="4"
	SetVariable Gain_AsyncAD_07, userdata(tabcontrol)="ADC"
	SetVariable Gain_AsyncAD_07, userdata(ResizeControlsInfo)=A"!!,Gp!!#C.!!#?S!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Gain_AsyncAD_07, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Gain_AsyncAD_07, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Gain_AsyncAD_07, userdata(ControlArray)="Gain_AsyncAD"
	SetVariable Gain_AsyncAD_07, userdata(ControlArrayIndex)="7"
	SetVariable Gain_AsyncAD_07, limits={0, Inf, 1}, value=_NUM:1
	SetVariable Title_AsyncAD_00, pos={12.00, 42.00}, size={150.00, 18.00}, disable=1, proc=DAP_SetVar_UpdateGuiState
	SetVariable Title_AsyncAD_00, title="Title", userdata(tabnum)="4"
	SetVariable Title_AsyncAD_00, userdata(tabcontrol)="ADC"
	SetVariable Title_AsyncAD_00, userdata(ResizeControlsInfo)=A"!!,An!!#>>!!#A%!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Title_AsyncAD_00, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Title_AsyncAD_00, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Title_AsyncAD_00, userdata(ControlArray)="Title_AsyncAD"
	SetVariable Title_AsyncAD_00, userdata(ControlArrayIndex)="0", value=_STR:""
	SetVariable Title_AsyncAD_01, pos={12.00, 93.00}, size={150.00, 18.00}, disable=1, proc=DAP_SetVar_UpdateGuiState
	SetVariable Title_AsyncAD_01, title="Title", userdata(tabnum)="4"
	SetVariable Title_AsyncAD_01, userdata(tabcontrol)="ADC"
	SetVariable Title_AsyncAD_01, userdata(ResizeControlsInfo)=A"!!,An!!#@\"!!#A%!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Title_AsyncAD_01, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Title_AsyncAD_01, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Title_AsyncAD_01, userdata(ControlArray)="Title_AsyncAD"
	SetVariable Title_AsyncAD_01, userdata(ControlArrayIndex)="1", value=_STR:""
	SetVariable Title_AsyncAD_02, pos={12.00, 144.00}, size={150.00, 18.00}, disable=1, proc=DAP_SetVar_UpdateGuiState
	SetVariable Title_AsyncAD_02, title="Title", userdata(tabnum)="4"
	SetVariable Title_AsyncAD_02, userdata(tabcontrol)="ADC"
	SetVariable Title_AsyncAD_02, userdata(ResizeControlsInfo)=A"!!,An!!#A!!!#A%!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Title_AsyncAD_02, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Title_AsyncAD_02, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Title_AsyncAD_02, userdata(ControlArray)="Title_AsyncAD"
	SetVariable Title_AsyncAD_02, userdata(ControlArrayIndex)="2", value=_STR:""
	SetVariable Title_AsyncAD_03, pos={12.00, 195.00}, size={150.00, 18.00}, disable=1, proc=DAP_SetVar_UpdateGuiState
	SetVariable Title_AsyncAD_03, title="Title", userdata(tabnum)="4"
	SetVariable Title_AsyncAD_03, userdata(tabcontrol)="ADC"
	SetVariable Title_AsyncAD_03, userdata(ResizeControlsInfo)=A"!!,An!!#AT!!#A%!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Title_AsyncAD_03, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Title_AsyncAD_03, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Title_AsyncAD_03, userdata(ControlArray)="Title_AsyncAD"
	SetVariable Title_AsyncAD_03, userdata(ControlArrayIndex)="3", value=_STR:""
	SetVariable Title_AsyncAD_04, pos={9.00, 246.00}, size={150.00, 18.00}, disable=1, proc=DAP_SetVar_UpdateGuiState
	SetVariable Title_AsyncAD_04, title="Title", userdata(tabnum)="4"
	SetVariable Title_AsyncAD_04, userdata(tabcontrol)="ADC"
	SetVariable Title_AsyncAD_04, userdata(ResizeControlsInfo)=A"!!,A>!!#B2!!#A%!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Title_AsyncAD_04, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Title_AsyncAD_04, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Title_AsyncAD_04, userdata(ControlArray)="Title_AsyncAD"
	SetVariable Title_AsyncAD_04, userdata(ControlArrayIndex)="4", value=_STR:""
	SetVariable Title_AsyncAD_05, pos={12.00, 297.00}, size={150.00, 18.00}, disable=1, proc=DAP_SetVar_UpdateGuiState
	SetVariable Title_AsyncAD_05, title="Title", userdata(tabnum)="4"
	SetVariable Title_AsyncAD_05, userdata(tabcontrol)="ADC"
	SetVariable Title_AsyncAD_05, userdata(ResizeControlsInfo)=A"!!,An!!#BOJ,hqP!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Title_AsyncAD_05, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Title_AsyncAD_05, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Title_AsyncAD_05, userdata(ControlArray)="Title_AsyncAD"
	SetVariable Title_AsyncAD_05, userdata(ControlArrayIndex)="5", value=_STR:""
	SetVariable Title_AsyncAD_06, pos={12.00, 348.00}, size={150.00, 18.00}, disable=1, proc=DAP_SetVar_UpdateGuiState
	SetVariable Title_AsyncAD_06, title="Title", userdata(tabnum)="4"
	SetVariable Title_AsyncAD_06, userdata(tabcontrol)="ADC"
	SetVariable Title_AsyncAD_06, userdata(ResizeControlsInfo)=A"!!,An!!#Bi!!#A%!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Title_AsyncAD_06, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Title_AsyncAD_06, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Title_AsyncAD_06, userdata(ControlArray)="Title_AsyncAD"
	SetVariable Title_AsyncAD_06, userdata(ControlArrayIndex)="6", value=_STR:""
	SetVariable Title_AsyncAD_07, pos={12.00, 402.00}, size={150.00, 18.00}, disable=1, proc=DAP_SetVar_UpdateGuiState
	SetVariable Title_AsyncAD_07, title="Title", userdata(tabnum)="4"
	SetVariable Title_AsyncAD_07, userdata(tabcontrol)="ADC"
	SetVariable Title_AsyncAD_07, userdata(ResizeControlsInfo)=A"!!,An!!#C.!!#A%!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Title_AsyncAD_07, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Title_AsyncAD_07, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Title_AsyncAD_07, userdata(ControlArray)="Title_AsyncAD"
	SetVariable Title_AsyncAD_07, userdata(ControlArrayIndex)="7", value=_STR:""
	SetVariable Unit_AsyncAD_00, pos={315.00, 42.00}, size={75.00, 18.00}, disable=1, proc=DAP_SetVar_UpdateGuiState
	SetVariable Unit_AsyncAD_00, title="Unit", userdata(tabnum)="4"
	SetVariable Unit_AsyncAD_00, userdata(tabcontrol)="ADC"
	SetVariable Unit_AsyncAD_00, userdata(ResizeControlsInfo)=A"!!,HXJ,hni!!#?O!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Unit_AsyncAD_00, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Unit_AsyncAD_00, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Unit_AsyncAD_00, userdata(ControlArray)="Unit_AsyncAD"
	SetVariable Unit_AsyncAD_00, userdata(ControlArrayIndex)="0", value=_STR:""
	SetVariable Unit_AsyncAD_01, pos={315.00, 93.00}, size={75.00, 18.00}, disable=1, proc=DAP_SetVar_UpdateGuiState
	SetVariable Unit_AsyncAD_01, title="Unit", userdata(tabnum)="4"
	SetVariable Unit_AsyncAD_01, userdata(tabcontrol)="ADC"
	SetVariable Unit_AsyncAD_01, userdata(ResizeControlsInfo)=A"!!,HXJ,hpM!!#?O!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Unit_AsyncAD_01, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Unit_AsyncAD_01, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Unit_AsyncAD_01, userdata(ControlArray)="Unit_AsyncAD"
	SetVariable Unit_AsyncAD_01, userdata(ControlArrayIndex)="1", value=_STR:""
	SetVariable Unit_AsyncAD_02, pos={315.00, 144.00}, size={75.00, 18.00}, disable=1, proc=DAP_SetVar_UpdateGuiState
	SetVariable Unit_AsyncAD_02, title="Unit", userdata(tabnum)="4"
	SetVariable Unit_AsyncAD_02, userdata(tabcontrol)="ADC"
	SetVariable Unit_AsyncAD_02, userdata(ResizeControlsInfo)=A"!!,HXJ,hqL!!#?O!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Unit_AsyncAD_02, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Unit_AsyncAD_02, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Unit_AsyncAD_02, userdata(ControlArray)="Unit_AsyncAD"
	SetVariable Unit_AsyncAD_02, userdata(ControlArrayIndex)="2", value=_STR:""
	SetVariable Unit_AsyncAD_03, pos={315.00, 195.00}, size={75.00, 18.00}, disable=1, proc=DAP_SetVar_UpdateGuiState
	SetVariable Unit_AsyncAD_03, title="Unit", userdata(tabnum)="4"
	SetVariable Unit_AsyncAD_03, userdata(tabcontrol)="ADC"
	SetVariable Unit_AsyncAD_03, userdata(ResizeControlsInfo)=A"!!,HXJ,hr*!!#?O!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Unit_AsyncAD_03, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Unit_AsyncAD_03, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Unit_AsyncAD_03, userdata(ControlArray)="Unit_AsyncAD"
	SetVariable Unit_AsyncAD_03, userdata(ControlArrayIndex)="3", value=_STR:""
	SetVariable Unit_AsyncAD_04, pos={315.00, 246.00}, size={75.00, 18.00}, disable=1, proc=DAP_SetVar_UpdateGuiState
	SetVariable Unit_AsyncAD_04, title="Unit", userdata(tabnum)="4"
	SetVariable Unit_AsyncAD_04, userdata(tabcontrol)="ADC"
	SetVariable Unit_AsyncAD_04, userdata(ResizeControlsInfo)=A"!!,HXJ,hr]!!#?O!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Unit_AsyncAD_04, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Unit_AsyncAD_04, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Unit_AsyncAD_04, userdata(ControlArray)="Unit_AsyncAD"
	SetVariable Unit_AsyncAD_04, userdata(ControlArrayIndex)="4", value=_STR:""
	SetVariable Unit_AsyncAD_05, pos={315.00, 297.00}, size={75.00, 18.00}, disable=1, proc=DAP_SetVar_UpdateGuiState
	SetVariable Unit_AsyncAD_05, title="Unit", userdata(tabnum)="4"
	SetVariable Unit_AsyncAD_05, userdata(tabcontrol)="ADC"
	SetVariable Unit_AsyncAD_05, userdata(ResizeControlsInfo)=A"!!,HXJ,hs%!!#?O!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Unit_AsyncAD_05, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Unit_AsyncAD_05, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Unit_AsyncAD_05, userdata(ControlArray)="Unit_AsyncAD"
	SetVariable Unit_AsyncAD_05, userdata(ControlArrayIndex)="5", value=_STR:""
	SetVariable Unit_AsyncAD_06, pos={315.00, 348.00}, size={75.00, 18.00}, disable=1, proc=DAP_SetVar_UpdateGuiState
	SetVariable Unit_AsyncAD_06, title="Unit", userdata(tabnum)="4"
	SetVariable Unit_AsyncAD_06, userdata(tabcontrol)="ADC"
	SetVariable Unit_AsyncAD_06, userdata(ResizeControlsInfo)=A"!!,HXJ,hs?!!#?O!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Unit_AsyncAD_06, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Unit_AsyncAD_06, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Unit_AsyncAD_06, userdata(ControlArray)="Unit_AsyncAD"
	SetVariable Unit_AsyncAD_06, userdata(ControlArrayIndex)="6", value=_STR:""
	SetVariable Unit_AsyncAD_07, pos={315.00, 402.00}, size={75.00, 18.00}, disable=1, proc=DAP_SetVar_UpdateGuiState
	SetVariable Unit_AsyncAD_07, title="Unit", userdata(tabnum)="4"
	SetVariable Unit_AsyncAD_07, userdata(tabcontrol)="ADC"
	SetVariable Unit_AsyncAD_07, userdata(ResizeControlsInfo)=A"!!,HXJ,hsY!!#?O!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Unit_AsyncAD_07, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Unit_AsyncAD_07, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Unit_AsyncAD_07, userdata(ControlArray)="Unit_AsyncAD"
	SetVariable Unit_AsyncAD_07, userdata(ControlArrayIndex)="7", value=_STR:""
	CheckBox Check_Settings_BkgTP, pos={27.00, 84.00}, size={97.00, 15.00}, disable=3, proc=DAP_CheckProc_UpdateGuiState
	CheckBox Check_Settings_BkgTP, title="Background TP"
	CheckBox Check_Settings_BkgTP, help={"Perform testpulse in the background, keeping the GUI responsive."}
	CheckBox Check_Settings_BkgTP, userdata(tabnum)="5", userdata(tabcontrol)="ADC"
	CheckBox Check_Settings_BkgTP, userdata(ResizeControlsInfo)=A"!!,Cl!!#?e!!#@$!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_Settings_BkgTP, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_Settings_BkgTP, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_Settings_BkgTP, value=1
	CheckBox Check_Settings_BackgrndDataAcq, pos={33.00, 210.00}, size={170.00, 15.00}, disable=3, proc=DAP_CheckProc_UpdateGuiState
	CheckBox Check_Settings_BackgrndDataAcq, title="Background Data Acquisition"
	CheckBox Check_Settings_BackgrndDataAcq, help={"Perform data acquisition in the background, keeping the GUI responsive."}
	CheckBox Check_Settings_BackgrndDataAcq, userdata(tabnum)="5"
	CheckBox Check_Settings_BackgrndDataAcq, userdata(tabcontrol)="ADC"
	CheckBox Check_Settings_BackgrndDataAcq, userdata(ResizeControlsInfo)=A"!!,Cl!!#AP!!#A8!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_Settings_BackgrndDataAcq, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_Settings_BackgrndDataAcq, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_Settings_BackgrndDataAcq, value=1
	CheckBox Radio_ClampMode_0, pos={129.00, 60.00}, size={14.00, 14.00}, disable=1, proc=DAP_CheckProc_ClampMode
	CheckBox Radio_ClampMode_0, title="", userdata(tabnum)="0"
	CheckBox Radio_ClampMode_0, userdata(tabcontrol)="ADC"
	CheckBox Radio_ClampMode_0, userdata(ResizeControlsInfo)=A"!!,Ff!!#?1!!#;]!!#;]z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Radio_ClampMode_0, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Radio_ClampMode_0, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Radio_ClampMode_0, userdata(Config_RestorePriority)="30"
	CheckBox Radio_ClampMode_0, userdata(Config_NiceName)="Headstage_0_VC"
	CheckBox Radio_ClampMode_0, value=1, mode=1
	TitleBox Title_DataAcq_VC, pos={42.00, 60.00}, size={77.00, 15.00}, disable=1
	TitleBox Title_DataAcq_VC, title="Voltage Clamp", userdata(tabnum)="0"
	TitleBox Title_DataAcq_VC, userdata(tabcontrol)="ADC"
	TitleBox Title_DataAcq_VC, userdata(ResizeControlsInfo)=A"!!,D;!!#?)!!#?U!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox Title_DataAcq_VC, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	TitleBox Title_DataAcq_VC, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	TitleBox Title_DataAcq_VC, frame=0
	TitleBox Title_DataAcq_IC, pos={42.00, 108.00}, size={78.00, 15.00}, disable=1
	TitleBox Title_DataAcq_IC, title="Current Clamp", userdata(tabnum)="0"
	TitleBox Title_DataAcq_IC, userdata(tabcontrol)="ADC"
	TitleBox Title_DataAcq_IC, userdata(ResizeControlsInfo)=A"!!,D;!!#@>!!#?U!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox Title_DataAcq_IC, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	TitleBox Title_DataAcq_IC, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	TitleBox Title_DataAcq_IC, frame=0
	TitleBox Title_DataAcq_CellSelection, pos={57.00, 84.00}, size={56.00, 15.00}, disable=1
	TitleBox Title_DataAcq_CellSelection, title="Headstage", userdata(tabnum)="0"
	TitleBox Title_DataAcq_CellSelection, userdata(tabcontrol)="ADC"
	TitleBox Title_DataAcq_CellSelection, userdata(ResizeControlsInfo)=A"!!,E\"!!#?c!!#>n!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox Title_DataAcq_CellSelection, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	TitleBox Title_DataAcq_CellSelection, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	TitleBox Title_DataAcq_CellSelection, frame=0
	CheckBox Check_DataAcqHS_01, pos={162.00, 84.00}, size={22.00, 15.00}, disable=1, proc=DAP_CheckProc_HedstgeChck
	CheckBox Check_DataAcqHS_01, title="1", userdata(tabnum)="0"
	CheckBox Check_DataAcqHS_01, userdata(tabcontrol)="ADC"
	CheckBox Check_DataAcqHS_01, userdata(ResizeControlsInfo)=A"!!,G2!!#?e!!#<`!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_DataAcqHS_01, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_DataAcqHS_01, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_DataAcqHS_01, userdata(ControlArray)="Check_DataAcqHS"
	CheckBox Check_DataAcqHS_01, userdata(ControlArrayIndex)="1", value=0
	CheckBox Check_DataAcqHS_02, pos={195.00, 84.00}, size={22.00, 15.00}, disable=1, proc=DAP_CheckProc_HedstgeChck
	CheckBox Check_DataAcqHS_02, title="2", userdata(tabnum)="0"
	CheckBox Check_DataAcqHS_02, userdata(tabcontrol)="ADC"
	CheckBox Check_DataAcqHS_02, userdata(ResizeControlsInfo)=A"!!,GT!!#?e!!#<`!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_DataAcqHS_02, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_DataAcqHS_02, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_DataAcqHS_02, userdata(ControlArray)="Check_DataAcqHS"
	CheckBox Check_DataAcqHS_02, userdata(ControlArrayIndex)="2", value=0
	CheckBox Check_DataAcqHS_03, pos={228.00, 84.00}, size={22.00, 15.00}, disable=1, proc=DAP_CheckProc_HedstgeChck
	CheckBox Check_DataAcqHS_03, title="3", userdata(tabnum)="0"
	CheckBox Check_DataAcqHS_03, userdata(tabcontrol)="ADC"
	CheckBox Check_DataAcqHS_03, userdata(ResizeControlsInfo)=A"!!,H!!!#?e!!#<`!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_DataAcqHS_03, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_DataAcqHS_03, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_DataAcqHS_03, userdata(ControlArray)="Check_DataAcqHS"
	CheckBox Check_DataAcqHS_03, userdata(ControlArrayIndex)="3", value=0
	CheckBox Check_DataAcqHS_04, pos={264.00, 84.00}, size={22.00, 15.00}, disable=1, proc=DAP_CheckProc_HedstgeChck
	CheckBox Check_DataAcqHS_04, title="4", userdata(tabnum)="0"
	CheckBox Check_DataAcqHS_04, userdata(tabcontrol)="ADC"
	CheckBox Check_DataAcqHS_04, userdata(ResizeControlsInfo)=A"!!,H?!!#?e!!#<`!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_DataAcqHS_04, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_DataAcqHS_04, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_DataAcqHS_04, userdata(ControlArray)="Check_DataAcqHS"
	CheckBox Check_DataAcqHS_04, userdata(ControlArrayIndex)="4", value=0
	CheckBox Check_DataAcqHS_05, pos={297.00, 84.00}, size={22.00, 15.00}, disable=1, proc=DAP_CheckProc_HedstgeChck
	CheckBox Check_DataAcqHS_05, title="5", userdata(tabnum)="0"
	CheckBox Check_DataAcqHS_05, userdata(tabcontrol)="ADC"
	CheckBox Check_DataAcqHS_05, userdata(ResizeControlsInfo)=A"!!,HP!!#?e!!#<`!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_DataAcqHS_05, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_DataAcqHS_05, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_DataAcqHS_05, userdata(ControlArray)="Check_DataAcqHS"
	CheckBox Check_DataAcqHS_05, userdata(ControlArrayIndex)="5", value=0
	CheckBox Check_DataAcqHS_06, pos={330.00, 84.00}, size={22.00, 15.00}, disable=1, proc=DAP_CheckProc_HedstgeChck
	CheckBox Check_DataAcqHS_06, title="6", userdata(tabnum)="0"
	CheckBox Check_DataAcqHS_06, userdata(tabcontrol)="ADC"
	CheckBox Check_DataAcqHS_06, userdata(ResizeControlsInfo)=A"!!,Ha!!#?e!!#<`!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_DataAcqHS_06, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_DataAcqHS_06, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_DataAcqHS_06, userdata(ControlArray)="Check_DataAcqHS"
	CheckBox Check_DataAcqHS_06, userdata(ControlArrayIndex)="6", value=0
	CheckBox Check_DataAcqHS_07, pos={366.00, 84.00}, size={22.00, 15.00}, disable=1, proc=DAP_CheckProc_HedstgeChck
	CheckBox Check_DataAcqHS_07, title="7", userdata(tabnum)="0"
	CheckBox Check_DataAcqHS_07, userdata(tabcontrol)="ADC"
	CheckBox Check_DataAcqHS_07, userdata(ResizeControlsInfo)=A"!!,Hr!!#?c!!#<`!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_DataAcqHS_07, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_DataAcqHS_07, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_DataAcqHS_07, userdata(ControlArray)="Check_DataAcqHS"
	CheckBox Check_DataAcqHS_07, userdata(ControlArrayIndex)="7", value=0
	CheckBox Radio_ClampMode_2, pos={162.00, 60.00}, size={14.00, 14.00}, disable=1, proc=DAP_CheckProc_ClampMode
	CheckBox Radio_ClampMode_2, title="", userdata(tabnum)="0"
	CheckBox Radio_ClampMode_2, userdata(tabcontrol)="ADC"
	CheckBox Radio_ClampMode_2, userdata(ResizeControlsInfo)=A"!!,G2!!#?1!!#;]!!#;]z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Radio_ClampMode_2, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Radio_ClampMode_2, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Radio_ClampMode_2, userdata(Config_RestorePriority)="30"
	CheckBox Radio_ClampMode_2, userdata(Config_NiceName)="Headstage_1_VC"
	CheckBox Radio_ClampMode_2, value=1, mode=1
	CheckBox Radio_ClampMode_4, pos={195.00, 60.00}, size={14.00, 14.00}, disable=1, proc=DAP_CheckProc_ClampMode
	CheckBox Radio_ClampMode_4, title="", userdata(tabnum)="0"
	CheckBox Radio_ClampMode_4, userdata(tabcontrol)="ADC"
	CheckBox Radio_ClampMode_4, userdata(ResizeControlsInfo)=A"!!,GT!!#?1!!#;]!!#;]z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Radio_ClampMode_4, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Radio_ClampMode_4, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Radio_ClampMode_4, userdata(Config_RestorePriority)="30"
	CheckBox Radio_ClampMode_4, userdata(Config_NiceName)="Headstage_2_VC"
	CheckBox Radio_ClampMode_4, value=1, mode=1
	CheckBox Radio_ClampMode_6, pos={228.00, 60.00}, size={14.00, 14.00}, disable=1, proc=DAP_CheckProc_ClampMode
	CheckBox Radio_ClampMode_6, title="", userdata(tabnum)="0"
	CheckBox Radio_ClampMode_6, userdata(tabcontrol)="ADC"
	CheckBox Radio_ClampMode_6, userdata(ResizeControlsInfo)=A"!!,H!!!#?1!!#;]!!#;]z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Radio_ClampMode_6, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Radio_ClampMode_6, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Radio_ClampMode_6, userdata(Config_RestorePriority)="30"
	CheckBox Radio_ClampMode_6, userdata(Config_NiceName)="Headstage_3_VC"
	CheckBox Radio_ClampMode_6, value=1, mode=1
	CheckBox Radio_ClampMode_8, pos={264.00, 60.00}, size={14.00, 14.00}, disable=1, proc=DAP_CheckProc_ClampMode
	CheckBox Radio_ClampMode_8, title="", userdata(tabnum)="0"
	CheckBox Radio_ClampMode_8, userdata(tabcontrol)="ADC"
	CheckBox Radio_ClampMode_8, userdata(ResizeControlsInfo)=A"!!,H?!!#?1!!#;]!!#;]z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Radio_ClampMode_8, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Radio_ClampMode_8, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Radio_ClampMode_8, userdata(Config_RestorePriority)="30"
	CheckBox Radio_ClampMode_8, userdata(Config_NiceName)="Headstage_4_VC"
	CheckBox Radio_ClampMode_8, value=1, mode=1
	CheckBox Radio_ClampMode_10, pos={297.00, 60.00}, size={14.00, 14.00}, disable=1, proc=DAP_CheckProc_ClampMode
	CheckBox Radio_ClampMode_10, title="", userdata(tabnum)="0"
	CheckBox Radio_ClampMode_10, userdata(tabcontrol)="ADC"
	CheckBox Radio_ClampMode_10, userdata(ResizeControlsInfo)=A"!!,HP!!#?1!!#;]!!#;]z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Radio_ClampMode_10, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Radio_ClampMode_10, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Radio_ClampMode_10, userdata(Config_RestorePriority)="30"
	CheckBox Radio_ClampMode_10, userdata(Config_NiceName)="Headstage_5_VC"
	CheckBox Radio_ClampMode_10, value=1, mode=1
	CheckBox Radio_ClampMode_12, pos={330.00, 60.00}, size={14.00, 14.00}, disable=1, proc=DAP_CheckProc_ClampMode
	CheckBox Radio_ClampMode_12, title="", userdata(tabnum)="0"
	CheckBox Radio_ClampMode_12, userdata(tabcontrol)="ADC"
	CheckBox Radio_ClampMode_12, userdata(ResizeControlsInfo)=A"!!,Ha!!#?1!!#;]!!#;]z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Radio_ClampMode_12, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Radio_ClampMode_12, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Radio_ClampMode_12, userdata(Config_RestorePriority)="30"
	CheckBox Radio_ClampMode_12, userdata(Config_NiceName)="Headstage_6_VC"
	CheckBox Radio_ClampMode_12, value=1, mode=1
	CheckBox Radio_ClampMode_14, pos={366.00, 60.00}, size={14.00, 14.00}, disable=1, proc=DAP_CheckProc_ClampMode
	CheckBox Radio_ClampMode_14, title="", userdata(tabnum)="0"
	CheckBox Radio_ClampMode_14, userdata(tabcontrol)="ADC"
	CheckBox Radio_ClampMode_14, userdata(ResizeControlsInfo)=A"!!,Hr!!#?1!!#;]!!#;]z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Radio_ClampMode_14, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Radio_ClampMode_14, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Radio_ClampMode_14, userdata(Config_RestorePriority)="30"
	CheckBox Radio_ClampMode_14, userdata(Config_NiceName)="Headstage_7_VC"
	CheckBox Radio_ClampMode_14, value=1, mode=1
	CheckBox Radio_ClampMode_1IZ, pos={129.00, 180.00}, size={14.00, 14.00}, disable=1, proc=DAP_CheckProc_ClampMode
	CheckBox Radio_ClampMode_1IZ, title="", userdata(tabnum)="2"
	CheckBox Radio_ClampMode_1IZ, userdata(tabcontrol)="tab_DataAcq_Amp"
	CheckBox Radio_ClampMode_1IZ, userdata(ResizeControlsInfo)=A"!!,G!!!#AD!!#;]!!#;]z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Radio_ClampMode_1IZ, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Radio_ClampMode_1IZ, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Radio_ClampMode_1IZ, userdata(Config_RestorePriority)="30"
	CheckBox Radio_ClampMode_1IZ, userdata(Config_NiceName)="Headstage_0_IZero"
	CheckBox Radio_ClampMode_1IZ, value=0, mode=1
	CheckBox Radio_ClampMode_3IZ, pos={162.00, 180.00}, size={14.00, 14.00}, disable=1, proc=DAP_CheckProc_ClampMode
	CheckBox Radio_ClampMode_3IZ, title="", userdata(tabnum)="2"
	CheckBox Radio_ClampMode_3IZ, userdata(tabcontrol)="tab_DataAcq_Amp"
	CheckBox Radio_ClampMode_3IZ, userdata(ResizeControlsInfo)=A"!!,GB!!#AD!!#;]!!#;]z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Radio_ClampMode_3IZ, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Radio_ClampMode_3IZ, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Radio_ClampMode_3IZ, userdata(Config_RestorePriority)="30"
	CheckBox Radio_ClampMode_3IZ, userdata(Config_NiceName)="Headstage_1_IZero"
	CheckBox Radio_ClampMode_3IZ, value=0, mode=1
	CheckBox Radio_ClampMode_5IZ, pos={195.00, 180.00}, size={14.00, 14.00}, disable=1, proc=DAP_CheckProc_ClampMode
	CheckBox Radio_ClampMode_5IZ, title="", userdata(tabnum)="2"
	CheckBox Radio_ClampMode_5IZ, userdata(tabcontrol)="tab_DataAcq_Amp"
	CheckBox Radio_ClampMode_5IZ, userdata(ResizeControlsInfo)=A"!!,Gd!!#AD!!#;]!!#;]z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Radio_ClampMode_5IZ, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Radio_ClampMode_5IZ, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Radio_ClampMode_5IZ, userdata(Config_RestorePriority)="30"
	CheckBox Radio_ClampMode_5IZ, userdata(Config_NiceName)="Headstage_2_IZero"
	CheckBox Radio_ClampMode_5IZ, value=0, mode=1
	CheckBox Radio_ClampMode_7IZ, pos={231.00, 180.00}, size={14.00, 14.00}, disable=1, proc=DAP_CheckProc_ClampMode
	CheckBox Radio_ClampMode_7IZ, title="", userdata(tabnum)="2"
	CheckBox Radio_ClampMode_7IZ, userdata(tabcontrol)="tab_DataAcq_Amp"
	CheckBox Radio_ClampMode_7IZ, userdata(ResizeControlsInfo)=A"!!,H1!!#AD!!#;]!!#;]z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Radio_ClampMode_7IZ, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Radio_ClampMode_7IZ, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Radio_ClampMode_7IZ, userdata(Config_RestorePriority)="30"
	CheckBox Radio_ClampMode_7IZ, userdata(Config_NiceName)="Headstage_3_IZero"
	CheckBox Radio_ClampMode_7IZ, value=0, mode=1
	CheckBox Radio_ClampMode_9IZ, pos={264.00, 180.00}, size={14.00, 14.00}, disable=1, proc=DAP_CheckProc_ClampMode
	CheckBox Radio_ClampMode_9IZ, title="", userdata(tabnum)="2"
	CheckBox Radio_ClampMode_9IZ, userdata(tabcontrol)="tab_DataAcq_Amp"
	CheckBox Radio_ClampMode_9IZ, userdata(ResizeControlsInfo)=A"!!,HG!!#AD!!#;]!!#;]z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Radio_ClampMode_9IZ, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Radio_ClampMode_9IZ, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Radio_ClampMode_9IZ, userdata(Config_RestorePriority)="30"
	CheckBox Radio_ClampMode_9IZ, userdata(Config_NiceName)="Headstage_4_IZero"
	CheckBox Radio_ClampMode_9IZ, value=0, mode=1
	CheckBox Radio_ClampMode_11IZ, pos={297.00, 180.00}, size={14.00, 14.00}, disable=1, proc=DAP_CheckProc_ClampMode
	CheckBox Radio_ClampMode_11IZ, title="", userdata(tabnum)="2"
	CheckBox Radio_ClampMode_11IZ, userdata(tabcontrol)="tab_DataAcq_Amp"
	CheckBox Radio_ClampMode_11IZ, userdata(ResizeControlsInfo)=A"!!,HX!!#AD!!#;]!!#;]z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Radio_ClampMode_11IZ, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Radio_ClampMode_11IZ, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Radio_ClampMode_11IZ, userdata(Config_RestorePriority)="30"
	CheckBox Radio_ClampMode_11IZ, userdata(Config_NiceName)="Headstage_5_IZero"
	CheckBox Radio_ClampMode_11IZ, value=0, mode=1
	CheckBox Radio_ClampMode_13IZ, pos={333.00, 180.00}, size={14.00, 14.00}, disable=1, proc=DAP_CheckProc_ClampMode
	CheckBox Radio_ClampMode_13IZ, title="", userdata(tabnum)="2"
	CheckBox Radio_ClampMode_13IZ, userdata(tabcontrol)="tab_DataAcq_Amp"
	CheckBox Radio_ClampMode_13IZ, userdata(ResizeControlsInfo)=A"!!,Hi!!#AD!!#;]!!#;]z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Radio_ClampMode_13IZ, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Radio_ClampMode_13IZ, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Radio_ClampMode_13IZ, userdata(Config_RestorePriority)="30"
	CheckBox Radio_ClampMode_13IZ, userdata(Config_NiceName)="Headstage_6_IZero"
	CheckBox Radio_ClampMode_13IZ, value=0, mode=1
	CheckBox Radio_ClampMode_15IZ, pos={366.00, 180.00}, size={14.00, 14.00}, disable=1, proc=DAP_CheckProc_ClampMode
	CheckBox Radio_ClampMode_15IZ, title="", userdata(tabnum)="2"
	CheckBox Radio_ClampMode_15IZ, userdata(tabcontrol)="tab_DataAcq_Amp"
	CheckBox Radio_ClampMode_15IZ, userdata(ResizeControlsInfo)=A"!!,I%!!#AD!!#;]!!#;]z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Radio_ClampMode_15IZ, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Radio_ClampMode_15IZ, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Radio_ClampMode_15IZ, userdata(Config_RestorePriority)="30"
	CheckBox Radio_ClampMode_15IZ, userdata(Config_NiceName)="Headstage_7_IZero"
	CheckBox Radio_ClampMode_15IZ, value=0, mode=1
	TitleBox Title_DataAcq_IE0, pos={66.00, 177.00}, size={55.00, 15.00}, disable=1
	TitleBox Title_DataAcq_IE0, title="I=0 Clamp", userdata(tabnum)="2"
	TitleBox Title_DataAcq_IE0, userdata(tabcontrol)="tab_DataAcq_Amp"
	TitleBox Title_DataAcq_IE0, userdata(ResizeControlsInfo)=A"!!,E^!!#AB!!#>j!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox Title_DataAcq_IE0, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	TitleBox Title_DataAcq_IE0, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	TitleBox Title_DataAcq_IE0, frame=0
	PopupMenu Popup_Settings_VC_DA, pos={25.00, 411.00}, size={47.00, 19.00}, proc=DAP_PopMenuProc_CAA
	PopupMenu Popup_Settings_VC_DA, title="DA", userdata(tabnum)="6"
	PopupMenu Popup_Settings_VC_DA, userdata(tabcontrol)="ADC"
	PopupMenu Popup_Settings_VC_DA, userdata(ResizeControlsInfo)=A"!!,DG!!#C2J,hnu!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Popup_Settings_VC_DA, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Popup_Settings_VC_DA, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Popup_Settings_VC_DA, userdata(Config_DontRestore)="1"
	PopupMenu Popup_Settings_VC_DA, userdata(Config_DontSave)="1"
	PopupMenu Popup_Settings_VC_DA, mode=1, popvalue="0", value=#"\"0;1;2;3;4;5;6;7;- none -\""
	PopupMenu Popup_Settings_VC_AD, pos={25.00, 438.00}, size={47.00, 19.00}, proc=DAP_PopMenuProc_CAA
	PopupMenu Popup_Settings_VC_AD, title="AD", userdata(tabnum)="6"
	PopupMenu Popup_Settings_VC_AD, userdata(tabcontrol)="ADC"
	PopupMenu Popup_Settings_VC_AD, userdata(ResizeControlsInfo)=A"!!,DG!!#C?!!#>J!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Popup_Settings_VC_AD, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Popup_Settings_VC_AD, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Popup_Settings_VC_AD, userdata(Config_DontRestore)="1"
	PopupMenu Popup_Settings_VC_AD, userdata(Config_DontSave)="1"
	PopupMenu Popup_Settings_VC_AD, mode=1, popvalue="0", value=#"\"0;1;2;3;4;5;6;7;8;9;10;11;12;13;14;15;- none -\""
	PopupMenu Popup_Settings_IC_AD, pos={225.00, 438.00}, size={47.00, 19.00}, proc=DAP_PopMenuProc_CAA
	PopupMenu Popup_Settings_IC_AD, title="AD", userdata(tabnum)="6"
	PopupMenu Popup_Settings_IC_AD, userdata(tabcontrol)="ADC"
	PopupMenu Popup_Settings_IC_AD, userdata(ResizeControlsInfo)=A"!!,Gr!!#C?!!#>J!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Popup_Settings_IC_AD, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Popup_Settings_IC_AD, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Popup_Settings_IC_AD, userdata(Config_DontRestore)="1"
	PopupMenu Popup_Settings_IC_AD, userdata(Config_DontSave)="1"
	PopupMenu Popup_Settings_IC_AD, mode=1, popvalue="0", value=#"\"0;1;2;3;4;5;6;7;8;9;10;11;12;13;14;15;- none -\""
	SetVariable setvar_Settings_VC_DAgain, pos={110.00, 411.00}, size={58.00, 18.00}, proc=DAP_SetVarProc_CAA
	SetVariable setvar_Settings_VC_DAgain, userdata(tabnum)="6"
	SetVariable setvar_Settings_VC_DAgain, userdata(tabcontrol)="ADC"
	SetVariable setvar_Settings_VC_DAgain, userdata(ResizeControlsInfo)=A"!!,F;!!#C3J,ho,!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_Settings_VC_DAgain, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_Settings_VC_DAgain, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_Settings_VC_DAgain, userdata(Config_DontRestore)="1"
	SetVariable setvar_Settings_VC_DAgain, userdata(Config_DontSave)="1"
	SetVariable setvar_Settings_VC_DAgain, value=_NUM:20
	SetVariable setvar_Settings_VC_ADgain, pos={110.00, 438.00}, size={58.00, 18.00}, proc=DAP_SetVarProc_CAA
	SetVariable setvar_Settings_VC_ADgain, userdata(tabnum)="6"
	SetVariable setvar_Settings_VC_ADgain, userdata(tabcontrol)="ADC"
	SetVariable setvar_Settings_VC_ADgain, userdata(ResizeControlsInfo)=A"!!,F;!!#C@!!#>V!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_Settings_VC_ADgain, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_Settings_VC_ADgain, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_Settings_VC_ADgain, userdata(Config_DontRestore)="1"
	SetVariable setvar_Settings_VC_ADgain, userdata(Config_DontSave)="1"
	SetVariable setvar_Settings_VC_ADgain, value=_NUM:0.00999999977648258
	SetVariable setvar_Settings_IC_ADgain, pos={311.00, 438.00}, size={58.00, 18.00}, proc=DAP_SetVarProc_CAA
	SetVariable setvar_Settings_IC_ADgain, userdata(tabnum)="6"
	SetVariable setvar_Settings_IC_ADgain, userdata(tabcontrol)="ADC"
	SetVariable setvar_Settings_IC_ADgain, userdata(ResizeControlsInfo)=A"!!,HJJ,hsk!!#>V!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_Settings_IC_ADgain, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_Settings_IC_ADgain, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_Settings_IC_ADgain, userdata(Config_DontRestore)="1"
	SetVariable setvar_Settings_IC_ADgain, userdata(Config_DontSave)="1"
	SetVariable setvar_Settings_IC_ADgain, value=_NUM:0.00999999977648258
	PopupMenu Popup_Settings_HeadStage, pos={64.00, 327.00}, size={91.00, 19.00}, proc=DAP_PopMenuProc_Headstage
	PopupMenu Popup_Settings_HeadStage, title="Head Stage", userdata(tabnum)="6"
	PopupMenu Popup_Settings_HeadStage, userdata(tabcontrol)="ADC"
	PopupMenu Popup_Settings_HeadStage, userdata(ResizeControlsInfo)=A"!!,DG!!#B^J,hpE!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Popup_Settings_HeadStage, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Popup_Settings_HeadStage, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Popup_Settings_HeadStage, userdata(Config_DontSave)="1"
	PopupMenu Popup_Settings_HeadStage, userdata(Config_DontRestore)="1"
	PopupMenu Popup_Settings_HeadStage, mode=1, popvalue="0", value=#"\"0;1;2;3;4;5;6;7\""
	PopupMenu popup_Settings_Amplifier, pos={34.00, 357.00}, size={235.00, 19.00}, bodyWidth=150, proc=DAP_PopMenuProc_CAA
	PopupMenu popup_Settings_Amplifier, title="Amplfier (700B)", userdata(tabnum)="6"
	PopupMenu popup_Settings_Amplifier, userdata(tabcontrol)="ADC"
	PopupMenu popup_Settings_Amplifier, userdata(ResizeControlsInfo)=A"!!,Cp!!#Bm!!#B%!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu popup_Settings_Amplifier, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu popup_Settings_Amplifier, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu popup_Settings_Amplifier, userdata(Config_DontSave)="1"
	PopupMenu popup_Settings_Amplifier, userdata(Config_DontRestore)="1"
	PopupMenu popup_Settings_Amplifier, mode=1, popvalue="- none -", value=#"DAP_GetNiceAmplifierChannelList()"
	PopupMenu Popup_Settings_IC_DA, pos={225.00, 411.00}, size={47.00, 19.00}, proc=DAP_PopMenuProc_CAA
	PopupMenu Popup_Settings_IC_DA, title="DA", userdata(tabnum)="6"
	PopupMenu Popup_Settings_IC_DA, userdata(tabcontrol)="ADC"
	PopupMenu Popup_Settings_IC_DA, userdata(ResizeControlsInfo)=A"!!,Gr!!#C2J,hnu!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Popup_Settings_IC_DA, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Popup_Settings_IC_DA, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Popup_Settings_IC_DA, userdata(Config_DontRestore)="1"
	PopupMenu Popup_Settings_IC_DA, userdata(Config_DontSave)="1"
	PopupMenu Popup_Settings_IC_DA, mode=1, popvalue="0", value=#"\"0;1;2;3;4;5;6;7;- none -\""
	SetVariable setvar_Settings_IC_DAgain, pos={311.00, 411.00}, size={58.00, 18.00}, proc=DAP_SetVarProc_CAA
	SetVariable setvar_Settings_IC_DAgain, userdata(tabnum)="6"
	SetVariable setvar_Settings_IC_DAgain, userdata(tabcontrol)="ADC"
	SetVariable setvar_Settings_IC_DAgain, userdata(ResizeControlsInfo)=A"!!,HK!!#C3J,ho,!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_Settings_IC_DAgain, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_Settings_IC_DAgain, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_Settings_IC_DAgain, userdata(Config_DontRestore)="1"
	SetVariable setvar_Settings_IC_DAgain, userdata(Config_DontSave)="1"
	SetVariable setvar_Settings_IC_DAgain, value=_NUM:400
	TitleBox Title_settings_Hardware_VC, pos={23.00, 393.00}, size={47.00, 15.00}
	TitleBox Title_settings_Hardware_VC, title="V-Clamp", userdata(tabnum)="6"
	TitleBox Title_settings_Hardware_VC, userdata(tabcontrol)="ADC"
	TitleBox Title_settings_Hardware_VC, userdata(ResizeControlsInfo)=A"!!,Ds!!#C*J,hnu!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox Title_settings_Hardware_VC, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	TitleBox Title_settings_Hardware_VC, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	TitleBox Title_settings_Hardware_VC, frame=0
	TitleBox Title_settings_ChanlAssign_IC, pos={225.00, 393.00}, size={43.00, 15.00}
	TitleBox Title_settings_ChanlAssign_IC, title="I-Clamp", userdata(tabnum)="6"
	TitleBox Title_settings_ChanlAssign_IC, userdata(tabcontrol)="ADC"
	TitleBox Title_settings_ChanlAssign_IC, userdata(ResizeControlsInfo)=A"!!,H*!!#C*J,hne!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox Title_settings_ChanlAssign_IC, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	TitleBox Title_settings_ChanlAssign_IC, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	TitleBox Title_settings_ChanlAssign_IC, frame=0
	Button button_Settings_UpdateAmpStatus, pos={292.00, 357.00}, size={150.00, 18.00}, proc=DAP_ButtonCtrlFindConnectedAmps
	Button button_Settings_UpdateAmpStatus, title="Query connected Amp(s)"
	Button button_Settings_UpdateAmpStatus, userdata(tabnum)="6"
	Button button_Settings_UpdateAmpStatus, userdata(tabcontrol)="ADC"
	Button button_Settings_UpdateAmpStatus, userdata(ResizeControlsInfo)=A"!!,HE!!#Bm!!#A%!!#<Xz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_Settings_UpdateAmpStatus, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button button_Settings_UpdateAmpStatus, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Search_DA_00, pos={153.00, 96.00}, size={123.00, 18.00}, disable=1, proc=DAP_SetVarProc_Channel_Search
	SetVariable Search_DA_00, title="Search filter", userdata(tabnum)="1"
	SetVariable Search_DA_00, userdata(tabcontrol)="ADC"
	SetVariable Search_DA_00, userdata(ResizeControlsInfo)=A"!!,G)!!#@&!!#@\\!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Search_DA_00, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Search_DA_00, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Search_DA_00, userdata(ControlArray)="Search_DA"
	SetVariable Search_DA_00, userdata(ControlArrayIndex)="0", value=_STR:""
	SetVariable Search_DA_01, pos={153.00, 141.00}, size={123.00, 18.00}, disable=1, proc=DAP_SetVarProc_Channel_Search
	SetVariable Search_DA_01, title="Search filter", userdata(tabnum)="1"
	SetVariable Search_DA_01, userdata(tabcontrol)="ADC"
	SetVariable Search_DA_01, userdata(ResizeControlsInfo)=A"!!,G)!!#@s!!#@\\!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Search_DA_01, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Search_DA_01, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Search_DA_01, userdata(ControlArray)="Search_DA"
	SetVariable Search_DA_01, userdata(ControlArrayIndex)="1", value=_STR:""
	SetVariable Search_DA_02, pos={153.00, 189.00}, size={123.00, 18.00}, disable=1, proc=DAP_SetVarProc_Channel_Search
	SetVariable Search_DA_02, title="Search filter", userdata(tabnum)="1"
	SetVariable Search_DA_02, userdata(tabcontrol)="ADC"
	SetVariable Search_DA_02, userdata(ResizeControlsInfo)=A"!!,G)!!#AL!!#@\\!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Search_DA_02, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Search_DA_02, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Search_DA_02, userdata(ControlArray)="Search_DA"
	SetVariable Search_DA_02, userdata(ControlArrayIndex)="2", value=_STR:""
	SetVariable Search_DA_03, pos={153.00, 234.00}, size={123.00, 18.00}, disable=1, proc=DAP_SetVarProc_Channel_Search
	SetVariable Search_DA_03, title="Search filter", userdata(tabnum)="1"
	SetVariable Search_DA_03, userdata(tabcontrol)="ADC"
	SetVariable Search_DA_03, userdata(ResizeControlsInfo)=A"!!,G)!!#B&!!#@\\!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Search_DA_03, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Search_DA_03, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Search_DA_03, userdata(ControlArray)="Search_DA"
	SetVariable Search_DA_03, userdata(ControlArrayIndex)="3", value=_STR:""
	SetVariable Search_DA_04, pos={153.00, 282.00}, size={123.00, 18.00}, disable=1, proc=DAP_SetVarProc_Channel_Search
	SetVariable Search_DA_04, title="Search filter", userdata(tabnum)="1"
	SetVariable Search_DA_04, userdata(tabcontrol)="ADC"
	SetVariable Search_DA_04, userdata(ResizeControlsInfo)=A"!!,G)!!#BG!!#@\\!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Search_DA_04, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Search_DA_04, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Search_DA_04, userdata(ControlArray)="Search_DA"
	SetVariable Search_DA_04, userdata(ControlArrayIndex)="4", value=_STR:""
	SetVariable Search_DA_05, pos={153.00, 327.00}, size={123.00, 18.00}, disable=1, proc=DAP_SetVarProc_Channel_Search
	SetVariable Search_DA_05, title="Search filter", userdata(tabnum)="1"
	SetVariable Search_DA_05, userdata(tabcontrol)="ADC"
	SetVariable Search_DA_05, userdata(ResizeControlsInfo)=A"!!,G)!!#B^J,hq2!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Search_DA_05, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Search_DA_05, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Search_DA_05, userdata(ControlArray)="Search_DA"
	SetVariable Search_DA_05, userdata(ControlArrayIndex)="5", value=_STR:""
	SetVariable Search_DA_06, pos={153.00, 375.00}, size={123.00, 18.00}, disable=1, proc=DAP_SetVarProc_Channel_Search
	SetVariable Search_DA_06, title="Search filter", userdata(tabnum)="1"
	SetVariable Search_DA_06, userdata(tabcontrol)="ADC"
	SetVariable Search_DA_06, userdata(ResizeControlsInfo)=A"!!,G)!!#BuJ,hq2!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Search_DA_06, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Search_DA_06, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Search_DA_06, userdata(ControlArray)="Search_DA"
	SetVariable Search_DA_06, userdata(ControlArrayIndex)="6", value=_STR:""
	SetVariable Search_DA_07, pos={153.00, 420.00}, size={123.00, 18.00}, disable=1, proc=DAP_SetVarProc_Channel_Search
	SetVariable Search_DA_07, title="Search filter", userdata(tabnum)="1"
	SetVariable Search_DA_07, userdata(tabcontrol)="ADC"
	SetVariable Search_DA_07, userdata(ResizeControlsInfo)=A"!!,G)!!#C8!!#@\\!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Search_DA_07, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Search_DA_07, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Search_DA_07, userdata(ControlArray)="Search_DA"
	SetVariable Search_DA_07, userdata(ControlArrayIndex)="7", value=_STR:""
	SetVariable Search_TTL_00, pos={102.00, 96.00}, size={123.00, 18.00}, disable=1, proc=DAP_SetVarProc_Channel_Search
	SetVariable Search_TTL_00, title="Search filter", userdata(tabnum)="3"
	SetVariable Search_TTL_00, userdata(tabcontrol)="ADC"
	SetVariable Search_TTL_00, userdata(ResizeControlsInfo)=A"!!,F1!!#@&!!#@\\!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Search_TTL_00, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Search_TTL_00, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Search_TTL_00, userdata(ControlArray)="Search_TTL"
	SetVariable Search_TTL_00, userdata(ControlArrayIndex)="0", value=_STR:""
	SetVariable Search_TTL_01, pos={102.00, 141.00}, size={123.00, 18.00}, disable=1, proc=DAP_SetVarProc_Channel_Search
	SetVariable Search_TTL_01, title="Search filter", userdata(tabnum)="3"
	SetVariable Search_TTL_01, userdata(tabcontrol)="ADC"
	SetVariable Search_TTL_01, userdata(ResizeControlsInfo)=A"!!,F1!!#@s!!#@\\!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Search_TTL_01, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Search_TTL_01, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Search_TTL_01, userdata(ControlArray)="Search_TTL"
	SetVariable Search_TTL_01, userdata(ControlArrayIndex)="1", value=_STR:""
	SetVariable Search_TTL_02, pos={102.00, 189.00}, size={123.00, 18.00}, disable=1, proc=DAP_SetVarProc_Channel_Search
	SetVariable Search_TTL_02, title="Search filter", userdata(tabnum)="3"
	SetVariable Search_TTL_02, userdata(tabcontrol)="ADC"
	SetVariable Search_TTL_02, userdata(ResizeControlsInfo)=A"!!,F1!!#AM!!#@\\!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Search_TTL_02, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Search_TTL_02, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Search_TTL_02, userdata(ControlArray)="Search_TTL"
	SetVariable Search_TTL_02, userdata(ControlArrayIndex)="2", value=_STR:""
	SetVariable Search_TTL_03, pos={102.00, 237.00}, size={123.00, 18.00}, disable=1, proc=DAP_SetVarProc_Channel_Search
	SetVariable Search_TTL_03, title="Search filter", userdata(tabnum)="3"
	SetVariable Search_TTL_03, userdata(tabcontrol)="ADC"
	SetVariable Search_TTL_03, userdata(ResizeControlsInfo)=A"!!,F1!!#B'!!#@\\!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Search_TTL_03, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Search_TTL_03, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Search_TTL_03, userdata(ControlArray)="Search_TTL"
	SetVariable Search_TTL_03, userdata(ControlArrayIndex)="3", value=_STR:""
	SetVariable Search_TTL_04, pos={102.00, 282.00}, size={123.00, 18.00}, disable=1, proc=DAP_SetVarProc_Channel_Search
	SetVariable Search_TTL_04, title="Search filter", userdata(tabnum)="3"
	SetVariable Search_TTL_04, userdata(tabcontrol)="ADC"
	SetVariable Search_TTL_04, userdata(ResizeControlsInfo)=A"!!,F1!!#BH!!#@\\!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Search_TTL_04, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Search_TTL_04, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Search_TTL_04, userdata(ControlArray)="Search_TTL"
	SetVariable Search_TTL_04, userdata(ControlArrayIndex)="4", value=_STR:""
	SetVariable Search_TTL_05, pos={102.00, 330.00}, size={123.00, 18.00}, disable=1, proc=DAP_SetVarProc_Channel_Search
	SetVariable Search_TTL_05, title="Search filter", userdata(tabnum)="3"
	SetVariable Search_TTL_05, userdata(tabcontrol)="ADC"
	SetVariable Search_TTL_05, userdata(ResizeControlsInfo)=A"!!,F1!!#B_J,hq2!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Search_TTL_05, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Search_TTL_05, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Search_TTL_05, userdata(ControlArray)="Search_TTL"
	SetVariable Search_TTL_05, userdata(ControlArrayIndex)="5", value=_STR:""
	SetVariable Search_TTL_06, pos={102.00, 378.00}, size={123.00, 18.00}, disable=1, proc=DAP_SetVarProc_Channel_Search
	SetVariable Search_TTL_06, title="Search filter", userdata(tabnum)="3"
	SetVariable Search_TTL_06, userdata(tabcontrol)="ADC"
	SetVariable Search_TTL_06, userdata(ResizeControlsInfo)=A"!!,F1!!#C\"!!#@\\!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Search_TTL_06, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Search_TTL_06, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Search_TTL_06, userdata(ControlArray)="Search_TTL"
	SetVariable Search_TTL_06, userdata(ControlArrayIndex)="6", value=_STR:""
	SetVariable Search_TTL_07, pos={102.00, 423.00}, size={123.00, 18.00}, disable=1, proc=DAP_SetVarProc_Channel_Search
	SetVariable Search_TTL_07, title="Search filter", userdata(tabnum)="3"
	SetVariable Search_TTL_07, userdata(tabcontrol)="ADC"
	SetVariable Search_TTL_07, userdata(ResizeControlsInfo)=A"!!,F1!!#C9J,hq2!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Search_TTL_07, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Search_TTL_07, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Search_TTL_07, userdata(ControlArray)="Search_TTL"
	SetVariable Search_TTL_07, userdata(ControlArrayIndex)="7", value=_STR:""
	CheckBox Check_DataAcq_Indexing, pos={179.00, 637.00}, size={61.00, 15.00}, disable=1, proc=DAP_CheckProc_IndexingState
	CheckBox Check_DataAcq_Indexing, title="Indexing"
	CheckBox Check_DataAcq_Indexing, help={"Data acquisition proceeds to next wave in DAC or TTL popup menu list"}
	CheckBox Check_DataAcq_Indexing, userdata(tabnum)="0", userdata(tabcontrol)="ADC"
	CheckBox Check_DataAcq_Indexing, userdata(ResizeControlsInfo)=A"!!,GR!!#D:!!#?)!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_DataAcq_Indexing, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_DataAcq_Indexing, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_DataAcq_Indexing, value=0
	TitleBox Title_DA_IndexStartEnd, pos={348.00, 47.00}, size={94.00, 15.00}, disable=1
	TitleBox Title_DA_IndexStartEnd, title="\\JCIndexing End Set"
	TitleBox Title_DA_IndexStartEnd, userdata(tabnum)="1", userdata(tabcontrol)="ADC"
	TitleBox Title_DA_IndexStartEnd, userdata(ResizeControlsInfo)=A"!!,HiJ,ho,!!#?u!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox Title_DA_IndexStartEnd, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	TitleBox Title_DA_IndexStartEnd, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	TitleBox Title_DA_IndexStartEnd, frame=0, fStyle=1, anchor=LC
	TitleBox Title_DA_Gain, pos={54.00, 48.00}, size={25.00, 15.00}, disable=1
	TitleBox Title_DA_Gain, title="Gain", userdata(tabnum)="1"
	TitleBox Title_DA_Gain, userdata(tabcontrol)="ADC"
	TitleBox Title_DA_Gain, userdata(ResizeControlsInfo)=A"!!,Dk!!#>V!!#=+!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox Title_DA_Gain, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	TitleBox Title_DA_Gain, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	TitleBox Title_DA_Gain, frame=0, fStyle=1
	TitleBox Title_DA_DAWaveSelect, pos={153.00, 48.00}, size={111.00, 15.00}, disable=1
	TitleBox Title_DA_DAWaveSelect, title="(first) DA Set Select"
	TitleBox Title_DA_DAWaveSelect, help={"Use the popup menus to select the stimulus set that will be output from the associated channel"}
	TitleBox Title_DA_DAWaveSelect, userdata(tabnum)="1", userdata(tabcontrol)="ADC"
	TitleBox Title_DA_DAWaveSelect, userdata(ResizeControlsInfo)=A"!!,G*!!#>V!!#@B!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox Title_DA_DAWaveSelect, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	TitleBox Title_DA_DAWaveSelect, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	TitleBox Title_DA_DAWaveSelect, frame=0, fStyle=1
	TitleBox Title_DA_Scale, pos={291.00, 48.00}, size={29.00, 15.00}, disable=1
	TitleBox Title_DA_Scale, title="Scale", userdata(tabnum)="1"
	TitleBox Title_DA_Scale, userdata(tabcontrol)="ADC"
	TitleBox Title_DA_Scale, userdata(ResizeControlsInfo)=A"!!,HMJ,ho,!!#=K!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox Title_DA_Scale, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	TitleBox Title_DA_Scale, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	TitleBox Title_DA_Scale, frame=0, fStyle=1
	TitleBox Title_DA_Channel, pos={24.00, 48.00}, size={17.00, 15.00}, disable=1
	TitleBox Title_DA_Channel, title="DA", userdata(tabnum)="1"
	TitleBox Title_DA_Channel, userdata(tabcontrol)="ADC"
	TitleBox Title_DA_Channel, userdata(ResizeControlsInfo)=A"!!,C,!!#>V!!#<@!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox Title_DA_Channel, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	TitleBox Title_DA_Channel, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	TitleBox Title_DA_Channel, frame=0, fStyle=1
	PopupMenu IndexEnd_DA_00, pos={346.00, 75.00}, size={125.00, 19.00}, bodyWidth=125, disable=1, proc=DAP_PopMenuChkProc_StimSetList
	PopupMenu IndexEnd_DA_00, userdata(tabnum)="1", userdata(tabcontrol)="ADC"
	PopupMenu IndexEnd_DA_00, userdata(ResizeControlsInfo)=A"!!,HkJ,hp%!!#@^!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu IndexEnd_DA_00, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu IndexEnd_DA_00, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu IndexEnd_DA_00, userdata(ControlArray)="IndexEnd_DA"
	PopupMenu IndexEnd_DA_00, userdata(ControlArrayIndex)="0"
	PopupMenu IndexEnd_DA_00, mode=1, popvalue="- none -", value=#"\"- none -;\"+ST_GetStimsetList(channelType = 0, searchString = \"*\")"
	PopupMenu IndexEnd_DA_01, pos={346.00, 120.00}, size={125.00, 19.00}, bodyWidth=125, disable=1, proc=DAP_PopMenuChkProc_StimSetList
	PopupMenu IndexEnd_DA_01, userdata(tabnum)="1", userdata(tabcontrol)="ADC"
	PopupMenu IndexEnd_DA_01, userdata(ResizeControlsInfo)=A"!!,HkJ,hq,!!#@^!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu IndexEnd_DA_01, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu IndexEnd_DA_01, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu IndexEnd_DA_01, userdata(ControlArray)="IndexEnd_DA"
	PopupMenu IndexEnd_DA_01, userdata(ControlArrayIndex)="1"
	PopupMenu IndexEnd_DA_01, mode=1, popvalue="- none -", value=#"\"- none -;\"+ST_GetStimsetList(channelType = 0, searchString = \"*\")"
	PopupMenu IndexEnd_DA_02, pos={346.00, 165.00}, size={125.00, 19.00}, bodyWidth=125, disable=1, proc=DAP_PopMenuChkProc_StimSetList
	PopupMenu IndexEnd_DA_02, userdata(tabnum)="1", userdata(tabcontrol)="ADC"
	PopupMenu IndexEnd_DA_02, userdata(ResizeControlsInfo)=A"!!,HkJ,hqa!!#@^!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu IndexEnd_DA_02, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu IndexEnd_DA_02, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu IndexEnd_DA_02, userdata(ControlArray)="IndexEnd_DA"
	PopupMenu IndexEnd_DA_02, userdata(ControlArrayIndex)="2"
	PopupMenu IndexEnd_DA_02, mode=1, popvalue="- none -", value=#"\"- none -;\"+ST_GetStimsetList(channelType = 0, searchString = \"*\")"
	PopupMenu IndexEnd_DA_03, pos={346.00, 213.00}, size={125.00, 19.00}, bodyWidth=125, disable=1, proc=DAP_PopMenuChkProc_StimSetList
	PopupMenu IndexEnd_DA_03, userdata(tabnum)="1", userdata(tabcontrol)="ADC"
	PopupMenu IndexEnd_DA_03, userdata(ResizeControlsInfo)=A"!!,HkJ,hr;!!#@^!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu IndexEnd_DA_03, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu IndexEnd_DA_03, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu IndexEnd_DA_03, userdata(ControlArray)="IndexEnd_DA"
	PopupMenu IndexEnd_DA_03, userdata(ControlArrayIndex)="3"
	PopupMenu IndexEnd_DA_03, mode=1, popvalue="- none -", value=#"\"- none -;\"+ST_GetStimsetList(channelType = 0, searchString = \"*\")"
	PopupMenu IndexEnd_DA_04, pos={346.00, 258.00}, size={125.00, 19.00}, bodyWidth=125, disable=1, proc=DAP_PopMenuChkProc_StimSetList
	PopupMenu IndexEnd_DA_04, userdata(tabnum)="1", userdata(tabcontrol)="ADC"
	PopupMenu IndexEnd_DA_04, userdata(ResizeControlsInfo)=A"!!,HkJ,hrg!!#@^!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu IndexEnd_DA_04, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu IndexEnd_DA_04, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu IndexEnd_DA_04, userdata(ControlArray)="IndexEnd_DA"
	PopupMenu IndexEnd_DA_04, userdata(ControlArrayIndex)="4"
	PopupMenu IndexEnd_DA_04, mode=1, popvalue="- none -", value=#"\"- none -;\"+ST_GetStimsetList(channelType = 0, searchString = \"*\")"
	PopupMenu IndexEnd_DA_05, pos={346.00, 306.00}, size={125.00, 19.00}, bodyWidth=125, disable=1, proc=DAP_PopMenuChkProc_StimSetList
	PopupMenu IndexEnd_DA_05, userdata(tabnum)="1", userdata(tabcontrol)="ADC"
	PopupMenu IndexEnd_DA_05, userdata(ResizeControlsInfo)=A"!!,HkJ,hs)J,hq4!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu IndexEnd_DA_05, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu IndexEnd_DA_05, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu IndexEnd_DA_05, userdata(ControlArray)="IndexEnd_DA"
	PopupMenu IndexEnd_DA_05, userdata(ControlArrayIndex)="5"
	PopupMenu IndexEnd_DA_05, mode=1, popvalue="- none -", value=#"\"- none -;\"+ST_GetStimsetList(channelType = 0, searchString = \"*\")"
	PopupMenu IndexEnd_DA_06, pos={346.00, 351.00}, size={125.00, 19.00}, bodyWidth=125, disable=1, proc=DAP_PopMenuChkProc_StimSetList
	PopupMenu IndexEnd_DA_06, userdata(tabnum)="1", userdata(tabcontrol)="ADC"
	PopupMenu IndexEnd_DA_06, userdata(ResizeControlsInfo)=A"!!,HkJ,hs@J,hq4!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu IndexEnd_DA_06, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu IndexEnd_DA_06, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu IndexEnd_DA_06, userdata(ControlArray)="IndexEnd_DA"
	PopupMenu IndexEnd_DA_06, userdata(ControlArrayIndex)="6"
	PopupMenu IndexEnd_DA_06, mode=1, popvalue="- none -", value=#"\"- none -;\"+ST_GetStimsetList(channelType = 0, searchString = \"*\")"
	PopupMenu IndexEnd_DA_07, pos={346.00, 399.00}, size={125.00, 19.00}, bodyWidth=125, disable=1, proc=DAP_PopMenuChkProc_StimSetList
	PopupMenu IndexEnd_DA_07, userdata(tabnum)="1", userdata(tabcontrol)="ADC"
	PopupMenu IndexEnd_DA_07, userdata(ResizeControlsInfo)=A"!!,HkJ,hsX!!#@^!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu IndexEnd_DA_07, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu IndexEnd_DA_07, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu IndexEnd_DA_07, userdata(ControlArray)="IndexEnd_DA"
	PopupMenu IndexEnd_DA_07, userdata(ControlArrayIndex)="7"
	PopupMenu IndexEnd_DA_07, mode=1, popvalue="- none -", value=#"\"- none -;\"+ST_GetStimsetList(channelType = 0, searchString = \"*\")"
	PopupMenu IndexEnd_TTL_00, pos={241.00, 75.00}, size={125.00, 19.00}, bodyWidth=125, disable=1, proc=DAP_PopMenuChkProc_StimSetList
	PopupMenu IndexEnd_TTL_00, userdata(tabnum)="3", userdata(tabcontrol)="ADC"
	PopupMenu IndexEnd_TTL_00, userdata(ResizeControlsInfo)=A"!!,H.!!#?O!!#@^!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu IndexEnd_TTL_00, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu IndexEnd_TTL_00, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu IndexEnd_TTL_00, userdata(ControlArray)="IndexEnd_TTL"
	PopupMenu IndexEnd_TTL_00, userdata(ControlArrayIndex)="0"
	PopupMenu IndexEnd_TTL_00, mode=1, popvalue="- none -", value=#"\"- none -;\"+ST_GetStimsetList(channelType = 1, searchString = \"*\")"
	PopupMenu IndexEnd_TTL_01, pos={238.00, 120.00}, size={125.00, 19.00}, bodyWidth=125, disable=1, proc=DAP_PopMenuChkProc_StimSetList
	PopupMenu IndexEnd_TTL_01, userdata(tabnum)="3", userdata(tabcontrol)="ADC"
	PopupMenu IndexEnd_TTL_01, userdata(ResizeControlsInfo)=A"!!,H-!!#@V!!#@^!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu IndexEnd_TTL_01, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu IndexEnd_TTL_01, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu IndexEnd_TTL_01, userdata(ControlArray)="IndexEnd_TTL"
	PopupMenu IndexEnd_TTL_01, userdata(ControlArrayIndex)="1"
	PopupMenu IndexEnd_TTL_01, mode=1, popvalue="- none -", value=#"\"- none -;\"+ST_GetStimsetList(channelType = 1, searchString = \"*\")"
	PopupMenu IndexEnd_TTL_02, pos={238.00, 165.00}, size={125.00, 19.00}, bodyWidth=125, disable=1, proc=DAP_PopMenuChkProc_StimSetList
	PopupMenu IndexEnd_TTL_02, userdata(tabnum)="3", userdata(tabcontrol)="ADC"
	PopupMenu IndexEnd_TTL_02, userdata(ResizeControlsInfo)=A"!!,H-!!#A6!!#@^!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu IndexEnd_TTL_02, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu IndexEnd_TTL_02, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu IndexEnd_TTL_02, userdata(ControlArray)="IndexEnd_TTL"
	PopupMenu IndexEnd_TTL_02, userdata(ControlArrayIndex)="2"
	PopupMenu IndexEnd_TTL_02, mode=1, popvalue="- none -", value=#"\"- none -;\"+ST_GetStimsetList(channelType = 1, searchString = \"*\")"
	PopupMenu IndexEnd_TTL_03, pos={238.00, 213.00}, size={125.00, 19.00}, bodyWidth=125, disable=1, proc=DAP_PopMenuChkProc_StimSetList
	PopupMenu IndexEnd_TTL_03, userdata(tabnum)="3", userdata(tabcontrol)="ADC"
	PopupMenu IndexEnd_TTL_03, userdata(ResizeControlsInfo)=A"!!,H-!!#Ae!!#@^!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu IndexEnd_TTL_03, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu IndexEnd_TTL_03, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu IndexEnd_TTL_03, userdata(ControlArray)="IndexEnd_TTL"
	PopupMenu IndexEnd_TTL_03, userdata(ControlArrayIndex)="3"
	PopupMenu IndexEnd_TTL_03, mode=1, popvalue="- none -", value=#"\"- none -;\"+ST_GetStimsetList(channelType = 1, searchString = \"*\")"
	PopupMenu IndexEnd_TTL_04, pos={238.00, 258.00}, size={125.00, 19.00}, bodyWidth=125, disable=1, proc=DAP_PopMenuChkProc_StimSetList
	PopupMenu IndexEnd_TTL_04, userdata(tabnum)="3", userdata(tabcontrol)="ADC"
	PopupMenu IndexEnd_TTL_04, userdata(ResizeControlsInfo)=A"!!,H-!!#B<!!#@^!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu IndexEnd_TTL_04, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu IndexEnd_TTL_04, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu IndexEnd_TTL_04, userdata(ControlArray)="IndexEnd_TTL"
	PopupMenu IndexEnd_TTL_04, userdata(ControlArrayIndex)="4"
	PopupMenu IndexEnd_TTL_04, mode=1, popvalue="- none -", value=#"\"- none -;\"+ST_GetStimsetList(channelType = 1, searchString = \"*\")"
	PopupMenu IndexEnd_TTL_05, pos={238.00, 306.00}, size={125.00, 19.00}, bodyWidth=125, disable=1, proc=DAP_PopMenuChkProc_StimSetList
	PopupMenu IndexEnd_TTL_05, userdata(tabnum)="3", userdata(tabcontrol)="ADC"
	PopupMenu IndexEnd_TTL_05, userdata(ResizeControlsInfo)=A"!!,H-!!#BSJ,hq4!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu IndexEnd_TTL_05, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu IndexEnd_TTL_05, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu IndexEnd_TTL_05, userdata(ControlArray)="IndexEnd_TTL"
	PopupMenu IndexEnd_TTL_05, userdata(ControlArrayIndex)="5"
	PopupMenu IndexEnd_TTL_05, mode=1, popvalue="- none -", value=#"\"- none -;\"+ST_GetStimsetList(channelType = 1, searchString = \"*\")"
	PopupMenu IndexEnd_TTL_06, pos={238.00, 351.00}, size={125.00, 19.00}, bodyWidth=125, disable=1, proc=DAP_PopMenuChkProc_StimSetList
	PopupMenu IndexEnd_TTL_06, userdata(tabnum)="3", userdata(tabcontrol)="ADC"
	PopupMenu IndexEnd_TTL_06, userdata(ResizeControlsInfo)=A"!!,H-!!#BjJ,hq4!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu IndexEnd_TTL_06, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu IndexEnd_TTL_06, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu IndexEnd_TTL_06, userdata(ControlArray)="IndexEnd_TTL"
	PopupMenu IndexEnd_TTL_06, userdata(ControlArrayIndex)="6"
	PopupMenu IndexEnd_TTL_06, mode=1, popvalue="- none -", value=#"\"- none -;\"+ST_GetStimsetList(channelType = 1, searchString = \"*\")"
	PopupMenu IndexEnd_TTL_07, pos={241.00, 399.00}, size={125.00, 19.00}, bodyWidth=125, disable=1, proc=DAP_PopMenuChkProc_StimSetList
	PopupMenu IndexEnd_TTL_07, userdata(tabnum)="3", userdata(tabcontrol)="ADC"
	PopupMenu IndexEnd_TTL_07, userdata(ResizeControlsInfo)=A"!!,H.!!#C-!!#@^!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu IndexEnd_TTL_07, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu IndexEnd_TTL_07, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu IndexEnd_TTL_07, userdata(ControlArray)="IndexEnd_TTL"
	PopupMenu IndexEnd_TTL_07, userdata(ControlArrayIndex)="7"
	PopupMenu IndexEnd_TTL_07, mode=1, popvalue="- none -", value=#"\"- none -;\"+ST_GetStimsetList(channelType = 1, searchString = \"*\")"
	CheckBox check_Settings_ShowScopeWindow, pos={33.00, 622.00}, size={127.00, 15.00}, disable=1, proc=DAP_CheckProc_ShowScopeWin
	CheckBox check_Settings_ShowScopeWindow, title="Show Scope Window"
	CheckBox check_Settings_ShowScopeWindow, help={"Enable the scope window to view ongoing acquistion"}
	CheckBox check_Settings_ShowScopeWindow, userdata(tabnum)="5"
	CheckBox check_Settings_ShowScopeWindow, userdata(tabcontrol)="ADC"
	CheckBox check_Settings_ShowScopeWindow, userdata(ResizeControlsInfo)=A"!!,Cl!!#CmJ,hq6!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_Settings_ShowScopeWindow, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_Settings_ShowScopeWindow, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_Settings_ShowScopeWindow, value=1
	Button button_DataAcq_TurnOffAllChan, pos={435.00, 72.00}, size={30.00, 39.00}, disable=1, proc=DAP_ButtonProc_AllChanOff
	Button button_DataAcq_TurnOffAllChan, title="OFF", userdata(tabnum)="0"
	Button button_DataAcq_TurnOffAllChan, userdata(tabcontrol)="ADC"
	Button button_DataAcq_TurnOffAllChan, userdata(ResizeControlsInfo)=A"!!,I?J,hp!!!#=S!!#>.z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_DataAcq_TurnOffAllChan, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button button_DataAcq_TurnOffAllChan, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_Settings_ITITP, pos={27.00, 108.00}, size={130.00, 15.00}, disable=1, proc=DAP_CheckProc_UpdateGuiState
	CheckBox check_Settings_ITITP, title="Activate TP during ITI"
	CheckBox check_Settings_ITITP, userdata(tabnum)="5", userdata(tabcontrol)="ADC"
	CheckBox check_Settings_ITITP, userdata(ResizeControlsInfo)=A"!!,Cl!!#@>!!#@e!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_Settings_ITITP, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_Settings_ITITP, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_Settings_ITITP, value=1
	ValDisplay valdisp_DataAcq_ITICountdown, pos={57.00, 567.00}, size={132.00, 21.00}, bodyWidth=30, disable=1
	ValDisplay valdisp_DataAcq_ITICountdown, title="ITI remaining (s)"
	ValDisplay valdisp_DataAcq_ITICountdown, userdata(tabnum)="0"
	ValDisplay valdisp_DataAcq_ITICountdown, userdata(tabcontrol)="ADC"
	ValDisplay valdisp_DataAcq_ITICountdown, userdata(ResizeControlsInfo)=A"!!,EB!!#CrJ,hq>!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	ValDisplay valdisp_DataAcq_ITICountdown, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	ValDisplay valdisp_DataAcq_ITICountdown, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	ValDisplay valdisp_DataAcq_ITICountdown, fSize=14, format="%.1f", fStyle=0
	ValDisplay valdisp_DataAcq_ITICountdown, valueColor=(65535, 65535, 65535)
	ValDisplay valdisp_DataAcq_ITICountdown, valueBackColor=(0, 0, 0)
	ValDisplay valdisp_DataAcq_ITICountdown, limits={0, 0, 0}, barmisc={0, 1000}
	ValDisplay valdisp_DataAcq_ITICountdown, value=_NUM:0
	ValDisplay valdisp_DataAcq_TrialsCountdown, pos={51.00, 540.00}, size={144.00, 21.00}, bodyWidth=30, disable=1
	ValDisplay valdisp_DataAcq_TrialsCountdown, title="Sweeps remaining"
	ValDisplay valdisp_DataAcq_TrialsCountdown, userdata(tabnum)="0"
	ValDisplay valdisp_DataAcq_TrialsCountdown, userdata(tabcontrol)="ADC"
	ValDisplay valdisp_DataAcq_TrialsCountdown, userdata(ResizeControlsInfo)=A"!!,Ds!!#Ck^]6_5!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	ValDisplay valdisp_DataAcq_TrialsCountdown, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	ValDisplay valdisp_DataAcq_TrialsCountdown, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	ValDisplay valdisp_DataAcq_TrialsCountdown, fSize=14, fStyle=0
	ValDisplay valdisp_DataAcq_TrialsCountdown, valueColor=(65535, 65535, 65535)
	ValDisplay valdisp_DataAcq_TrialsCountdown, valueBackColor=(0, 0, 0)
	ValDisplay valdisp_DataAcq_TrialsCountdown, limits={0, 0, 0}, barmisc={0, 1000}
	ValDisplay valdisp_DataAcq_TrialsCountdown, value=_NUM:1
	SetVariable min_AsyncAD_00, pos={105.00, 66.00}, size={75.00, 18.00}, bodyWidth=50, disable=1, proc=DAP_SetVar_UpdateGuiState
	SetVariable min_AsyncAD_00, title="min", userdata(tabnum)="4"
	SetVariable min_AsyncAD_00, userdata(tabcontrol)="ADC"
	SetVariable min_AsyncAD_00, userdata(ResizeControlsInfo)=A"!!,F?!!#?=!!#?O!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable min_AsyncAD_00, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable min_AsyncAD_00, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable min_AsyncAD_00, userdata(ControlArray)="min_AsyncAD"
	SetVariable min_AsyncAD_00, userdata(ControlArrayIndex)="0", value=_NUM:0
	SetVariable max_AsyncAD_00, pos={191.00, 66.00}, size={76.00, 18.00}, bodyWidth=50, disable=1, proc=DAP_SetVar_UpdateGuiState
	SetVariable max_AsyncAD_00, title="max", userdata(tabnum)="4"
	SetVariable max_AsyncAD_00, userdata(tabcontrol)="ADC"
	SetVariable max_AsyncAD_00, userdata(ResizeControlsInfo)=A"!!,GU!!#?=!!#?Q!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable max_AsyncAD_00, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable max_AsyncAD_00, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable max_AsyncAD_00, userdata(ControlArray)="max_AsyncAD"
	SetVariable max_AsyncAD_00, userdata(ControlArrayIndex)="0", value=_NUM:0
	CheckBox check_AsyncAlarm_00, pos={48.00, 66.00}, size={48.00, 15.00}, disable=1, proc=DAP_CheckProc_UpdateGuiState
	CheckBox check_AsyncAlarm_00, title="Alarm", userdata(tabnum)="4"
	CheckBox check_AsyncAlarm_00, userdata(tabcontrol)="ADC"
	CheckBox check_AsyncAlarm_00, userdata(ResizeControlsInfo)=A"!!,DW!!#?A!!#>J!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_AsyncAlarm_00, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_AsyncAlarm_00, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_AsyncAlarm_00, userdata(ControlArray)="check_AsyncAlarm"
	CheckBox check_AsyncAlarm_00, userdata(ControlArrayIndex)="0", value=0
	SetVariable min_AsyncAD_01, pos={105.00, 117.00}, size={75.00, 18.00}, bodyWidth=50, disable=1, proc=DAP_SetVar_UpdateGuiState
	SetVariable min_AsyncAD_01, title="min", userdata(tabnum)="4"
	SetVariable min_AsyncAD_01, userdata(tabcontrol)="ADC"
	SetVariable min_AsyncAD_01, userdata(ResizeControlsInfo)=A"!!,F?!!#@N!!#?O!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable min_AsyncAD_01, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable min_AsyncAD_01, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable min_AsyncAD_01, userdata(ControlArray)="min_AsyncAD"
	SetVariable min_AsyncAD_01, userdata(ControlArrayIndex)="1", value=_NUM:0
	SetVariable max_AsyncAD_01, pos={191.00, 117.00}, size={76.00, 18.00}, bodyWidth=50, disable=1, proc=DAP_SetVar_UpdateGuiState
	SetVariable max_AsyncAD_01, title="max", userdata(tabnum)="4"
	SetVariable max_AsyncAD_01, userdata(tabcontrol)="ADC"
	SetVariable max_AsyncAD_01, userdata(ResizeControlsInfo)=A"!!,GU!!#@N!!#?Q!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable max_AsyncAD_01, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable max_AsyncAD_01, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable max_AsyncAD_01, userdata(ControlArray)="max_AsyncAD"
	SetVariable max_AsyncAD_01, userdata(ControlArrayIndex)="1", value=_NUM:0
	CheckBox check_AsyncAlarm_01, pos={48.00, 117.00}, size={48.00, 15.00}, disable=1, proc=DAP_CheckProc_UpdateGuiState
	CheckBox check_AsyncAlarm_01, title="Alarm", userdata(tabnum)="4"
	CheckBox check_AsyncAlarm_01, userdata(tabcontrol)="ADC"
	CheckBox check_AsyncAlarm_01, userdata(ResizeControlsInfo)=A"!!,DW!!#@R!!#>J!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_AsyncAlarm_01, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_AsyncAlarm_01, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_AsyncAlarm_01, userdata(ControlArray)="check_AsyncAlarm"
	CheckBox check_AsyncAlarm_01, userdata(ControlArrayIndex)="1", value=0
	SetVariable min_AsyncAD_02, pos={105.00, 168.00}, size={75.00, 18.00}, bodyWidth=50, disable=1, proc=DAP_SetVar_UpdateGuiState
	SetVariable min_AsyncAD_02, title="min", userdata(tabnum)="4"
	SetVariable min_AsyncAD_02, userdata(tabcontrol)="ADC"
	SetVariable min_AsyncAD_02, userdata(ResizeControlsInfo)=A"!!,F?!!#A8!!#?O!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable min_AsyncAD_02, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable min_AsyncAD_02, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable min_AsyncAD_02, userdata(ControlArray)="min_AsyncAD"
	SetVariable min_AsyncAD_02, userdata(ControlArrayIndex)="2", value=_NUM:0
	SetVariable max_AsyncAD_02, pos={191.00, 168.00}, size={76.00, 18.00}, bodyWidth=50, disable=1, proc=DAP_SetVar_UpdateGuiState
	SetVariable max_AsyncAD_02, title="max", userdata(tabnum)="4"
	SetVariable max_AsyncAD_02, userdata(tabcontrol)="ADC"
	SetVariable max_AsyncAD_02, userdata(ResizeControlsInfo)=A"!!,GU!!#A8!!#?Q!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable max_AsyncAD_02, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable max_AsyncAD_02, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable max_AsyncAD_02, userdata(ControlArray)="max_AsyncAD"
	SetVariable max_AsyncAD_02, userdata(ControlArrayIndex)="2", value=_NUM:0
	CheckBox check_AsyncAlarm_02, pos={48.00, 171.00}, size={48.00, 15.00}, disable=1, proc=DAP_CheckProc_UpdateGuiState
	CheckBox check_AsyncAlarm_02, title="Alarm", userdata(tabnum)="4"
	CheckBox check_AsyncAlarm_02, userdata(tabcontrol)="ADC"
	CheckBox check_AsyncAlarm_02, userdata(ResizeControlsInfo)=A"!!,DW!!#A:!!#>J!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_AsyncAlarm_02, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_AsyncAlarm_02, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_AsyncAlarm_02, userdata(ControlArray)="check_AsyncAlarm"
	CheckBox check_AsyncAlarm_02, userdata(ControlArrayIndex)="2", value=0
	SetVariable min_AsyncAD_03, pos={105.00, 219.00}, size={75.00, 18.00}, bodyWidth=50, disable=1, proc=DAP_SetVar_UpdateGuiState
	SetVariable min_AsyncAD_03, title="min", userdata(tabnum)="4"
	SetVariable min_AsyncAD_03, userdata(tabcontrol)="ADC"
	SetVariable min_AsyncAD_03, userdata(ResizeControlsInfo)=A"!!,F?!!#Ak!!#?O!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable min_AsyncAD_03, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable min_AsyncAD_03, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable min_AsyncAD_03, userdata(ControlArray)="min_AsyncAD"
	SetVariable min_AsyncAD_03, userdata(ControlArrayIndex)="3", value=_NUM:0
	SetVariable max_AsyncAD_03, pos={191.00, 219.00}, size={76.00, 18.00}, bodyWidth=50, disable=1, proc=DAP_SetVar_UpdateGuiState
	SetVariable max_AsyncAD_03, title="max", userdata(tabnum)="4"
	SetVariable max_AsyncAD_03, userdata(tabcontrol)="ADC"
	SetVariable max_AsyncAD_03, userdata(ResizeControlsInfo)=A"!!,GU!!#Ak!!#?Q!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable max_AsyncAD_03, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable max_AsyncAD_03, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable max_AsyncAD_03, userdata(ControlArray)="max_AsyncAD"
	SetVariable max_AsyncAD_03, userdata(ControlArrayIndex)="3", value=_NUM:0
	CheckBox check_AsyncAlarm_03, pos={48.00, 222.00}, size={48.00, 15.00}, disable=1, proc=DAP_CheckProc_UpdateGuiState
	CheckBox check_AsyncAlarm_03, title="Alarm", userdata(tabnum)="4"
	CheckBox check_AsyncAlarm_03, userdata(tabcontrol)="ADC"
	CheckBox check_AsyncAlarm_03, userdata(ResizeControlsInfo)=A"!!,DW!!#Am!!#>J!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_AsyncAlarm_03, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_AsyncAlarm_03, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_AsyncAlarm_03, userdata(ControlArray)="check_AsyncAlarm"
	CheckBox check_AsyncAlarm_03, userdata(ControlArrayIndex)="3", value=0
	SetVariable min_AsyncAD_04, pos={105.00, 270.00}, size={75.00, 18.00}, bodyWidth=50, disable=1, proc=DAP_SetVar_UpdateGuiState
	SetVariable min_AsyncAD_04, title="min", userdata(tabnum)="4"
	SetVariable min_AsyncAD_04, userdata(tabcontrol)="ADC"
	SetVariable min_AsyncAD_04, userdata(ResizeControlsInfo)=A"!!,F?!!#BB!!#?O!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable min_AsyncAD_04, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable min_AsyncAD_04, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable min_AsyncAD_04, userdata(ControlArray)="min_AsyncAD"
	SetVariable min_AsyncAD_04, userdata(ControlArrayIndex)="4", value=_NUM:0
	SetVariable max_AsyncAD_04, pos={191.00, 270.00}, size={76.00, 18.00}, bodyWidth=50, disable=1, proc=DAP_SetVar_UpdateGuiState
	SetVariable max_AsyncAD_04, title="max", userdata(tabnum)="4"
	SetVariable max_AsyncAD_04, userdata(tabcontrol)="ADC"
	SetVariable max_AsyncAD_04, userdata(ResizeControlsInfo)=A"!!,GU!!#BB!!#?Q!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable max_AsyncAD_04, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable max_AsyncAD_04, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable max_AsyncAD_04, userdata(ControlArray)="max_AsyncAD"
	SetVariable max_AsyncAD_04, userdata(ControlArrayIndex)="4", value=_NUM:0
	CheckBox check_AsyncAlarm_04, pos={48.00, 273.00}, size={48.00, 15.00}, disable=1, proc=DAP_CheckProc_UpdateGuiState
	CheckBox check_AsyncAlarm_04, title="Alarm", userdata(tabnum)="4"
	CheckBox check_AsyncAlarm_04, userdata(tabcontrol)="ADC"
	CheckBox check_AsyncAlarm_04, userdata(ResizeControlsInfo)=A"!!,DW!!#BC!!#>J!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_AsyncAlarm_04, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_AsyncAlarm_04, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_AsyncAlarm_04, userdata(ControlArray)="check_AsyncAlarm"
	CheckBox check_AsyncAlarm_04, userdata(ControlArrayIndex)="4", value=0
	SetVariable min_AsyncAD_05, pos={105.00, 321.00}, size={75.00, 18.00}, bodyWidth=50, disable=1, proc=DAP_SetVar_UpdateGuiState
	SetVariable min_AsyncAD_05, title="min", userdata(tabnum)="4"
	SetVariable min_AsyncAD_05, userdata(tabcontrol)="ADC"
	SetVariable min_AsyncAD_05, userdata(ResizeControlsInfo)=A"!!,F?!!#B[J,hp%!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable min_AsyncAD_05, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable min_AsyncAD_05, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable min_AsyncAD_05, userdata(ControlArray)="min_AsyncAD"
	SetVariable min_AsyncAD_05, userdata(ControlArrayIndex)="5", value=_NUM:0
	SetVariable max_AsyncAD_05, pos={191.00, 321.00}, size={76.00, 18.00}, bodyWidth=50, disable=1, proc=DAP_SetVar_UpdateGuiState
	SetVariable max_AsyncAD_05, title="max", userdata(tabnum)="4"
	SetVariable max_AsyncAD_05, userdata(tabcontrol)="ADC"
	SetVariable max_AsyncAD_05, userdata(ResizeControlsInfo)=A"!!,GU!!#B[J,hp'!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable max_AsyncAD_05, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable max_AsyncAD_05, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable max_AsyncAD_05, userdata(ControlArray)="max_AsyncAD"
	SetVariable max_AsyncAD_05, userdata(ControlArrayIndex)="5", value=_NUM:0
	CheckBox check_AsyncAlarm_05, pos={48.00, 324.00}, size={48.00, 15.00}, disable=1, proc=DAP_CheckProc_UpdateGuiState
	CheckBox check_AsyncAlarm_05, title="Alarm", userdata(tabnum)="4"
	CheckBox check_AsyncAlarm_05, userdata(tabcontrol)="ADC"
	CheckBox check_AsyncAlarm_05, userdata(ResizeControlsInfo)=A"!!,DW!!#B\\J,hnu!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_AsyncAlarm_05, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_AsyncAlarm_05, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_AsyncAlarm_05, userdata(ControlArray)="check_AsyncAlarm"
	CheckBox check_AsyncAlarm_05, userdata(ControlArrayIndex)="5", value=0
	SetVariable min_AsyncAD_06, pos={105.00, 375.00}, size={75.00, 18.00}, bodyWidth=50, disable=1, proc=DAP_SetVar_UpdateGuiState
	SetVariable min_AsyncAD_06, title="min", userdata(tabnum)="4"
	SetVariable min_AsyncAD_06, userdata(tabcontrol)="ADC"
	SetVariable min_AsyncAD_06, userdata(ResizeControlsInfo)=A"!!,F?!!#BuJ,hp%!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable min_AsyncAD_06, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable min_AsyncAD_06, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable min_AsyncAD_06, userdata(ControlArray)="min_AsyncAD"
	SetVariable min_AsyncAD_06, userdata(ControlArrayIndex)="6", value=_NUM:0
	SetVariable max_AsyncAD_06, pos={191.00, 375.00}, size={76.00, 18.00}, bodyWidth=50, disable=1, proc=DAP_SetVar_UpdateGuiState
	SetVariable max_AsyncAD_06, title="max", userdata(tabnum)="4"
	SetVariable max_AsyncAD_06, userdata(tabcontrol)="ADC"
	SetVariable max_AsyncAD_06, userdata(ResizeControlsInfo)=A"!!,GU!!#BuJ,hp'!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable max_AsyncAD_06, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable max_AsyncAD_06, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable max_AsyncAD_06, userdata(ControlArray)="max_AsyncAD"
	SetVariable max_AsyncAD_06, userdata(ControlArrayIndex)="6", value=_NUM:0
	CheckBox check_AsyncAlarm_06, pos={48.00, 378.00}, size={48.00, 15.00}, disable=1, proc=DAP_CheckProc_UpdateGuiState
	CheckBox check_AsyncAlarm_06, title="Alarm", userdata(tabnum)="4"
	CheckBox check_AsyncAlarm_06, userdata(tabcontrol)="ADC"
	CheckBox check_AsyncAlarm_06, userdata(ResizeControlsInfo)=A"!!,DW!!#C\"!!#>J!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_AsyncAlarm_06, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_AsyncAlarm_06, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_AsyncAlarm_06, userdata(ControlArray)="check_AsyncAlarm"
	CheckBox check_AsyncAlarm_06, userdata(ControlArrayIndex)="6", value=0
	SetVariable min_AsyncAD_07, pos={105.00, 426.00}, size={75.00, 18.00}, bodyWidth=50, disable=1, proc=DAP_SetVar_UpdateGuiState
	SetVariable min_AsyncAD_07, title="min", userdata(tabnum)="4"
	SetVariable min_AsyncAD_07, userdata(tabcontrol)="ADC"
	SetVariable min_AsyncAD_07, userdata(ResizeControlsInfo)=A"!!,F?!!#C:J,hp%!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable min_AsyncAD_07, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable min_AsyncAD_07, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable min_AsyncAD_07, userdata(ControlArray)="min_AsyncAD"
	SetVariable min_AsyncAD_07, userdata(ControlArrayIndex)="7", value=_NUM:0
	SetVariable max_AsyncAD_07, pos={191.00, 426.00}, size={76.00, 18.00}, bodyWidth=50, disable=1, proc=DAP_SetVar_UpdateGuiState
	SetVariable max_AsyncAD_07, title="max", userdata(tabnum)="4"
	SetVariable max_AsyncAD_07, userdata(tabcontrol)="ADC"
	SetVariable max_AsyncAD_07, userdata(ResizeControlsInfo)=A"!!,GU!!#C:J,hp'!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable max_AsyncAD_07, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable max_AsyncAD_07, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable max_AsyncAD_07, userdata(ControlArray)="max_AsyncAD"
	SetVariable max_AsyncAD_07, userdata(ControlArrayIndex)="7", value=_NUM:0
	CheckBox check_AsyncAlarm_07, pos={48.00, 429.00}, size={48.00, 15.00}, disable=1, proc=DAP_CheckProc_UpdateGuiState
	CheckBox check_AsyncAlarm_07, title="Alarm", userdata(tabnum)="4"
	CheckBox check_AsyncAlarm_07, userdata(tabcontrol)="ADC"
	CheckBox check_AsyncAlarm_07, userdata(ResizeControlsInfo)=A"!!,DW!!#C;J,hnu!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_AsyncAlarm_07, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_AsyncAlarm_07, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_AsyncAlarm_07, userdata(ControlArray)="check_AsyncAlarm"
	CheckBox check_AsyncAlarm_07, userdata(ControlArrayIndex)="7", value=0
	TitleBox Title_TTL_IndexStartEnd, pos={255.00, 48.00}, size={94.00, 15.00}, disable=1
	TitleBox Title_TTL_IndexStartEnd, title="\\JCIndexing End Set"
	TitleBox Title_TTL_IndexStartEnd, userdata(tabnum)="3", userdata(tabcontrol)="ADC"
	TitleBox Title_TTL_IndexStartEnd, userdata(ResizeControlsInfo)=A"!!,H:!!#>V!!#?u!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox Title_TTL_IndexStartEnd, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	TitleBox Title_TTL_IndexStartEnd, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	TitleBox Title_TTL_IndexStartEnd, frame=0, fStyle=1, anchor=LC
	TitleBox Title_TTL_TTLWaveSelect, pos={99.00, 48.00}, size={114.00, 15.00}, disable=1
	TitleBox Title_TTL_TTLWaveSelect, title="(first) TTL Set Select"
	TitleBox Title_TTL_TTLWaveSelect, userdata(tabnum)="3", userdata(tabcontrol)="ADC"
	TitleBox Title_TTL_TTLWaveSelect, userdata(ResizeControlsInfo)=A"!!,F-!!#>V!!#@H!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox Title_TTL_TTLWaveSelect, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	TitleBox Title_TTL_TTLWaveSelect, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	TitleBox Title_TTL_TTLWaveSelect, frame=0, fStyle=1
	TitleBox Title_TTL_Channel, pos={24.00, 48.00}, size={47.00, 15.00}, disable=1
	TitleBox Title_TTL_Channel, title="TTL(out)", userdata(tabnum)="3"
	TitleBox Title_TTL_Channel, userdata(tabcontrol)="ADC"
	TitleBox Title_TTL_Channel, userdata(ResizeControlsInfo)=A"!!,C,!!#>V!!#>J!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox Title_TTL_Channel, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	TitleBox Title_TTL_Channel, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	TitleBox Title_TTL_Channel, frame=0, fStyle=1
	CheckBox check_DataAcq_RepAcqRandom, pos={72.00, 654.00}, size={61.00, 15.00}, disable=1, proc=DAP_CheckProc_RandomRA
	CheckBox check_DataAcq_RepAcqRandom, title="Random"
	CheckBox check_DataAcq_RepAcqRandom, help={"Randomly selects wave from set selected for DAC channel on each sweep. Doesn't repeat waves."}
	CheckBox check_DataAcq_RepAcqRandom, userdata(tabnum)="0"
	CheckBox check_DataAcq_RepAcqRandom, userdata(tabcontrol)="ADC"
	CheckBox check_DataAcq_RepAcqRandom, userdata(ResizeControlsInfo)=A"!!,E>!!#D5!!#?)!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_DataAcq_RepAcqRandom, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_DataAcq_RepAcqRandom, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_DataAcq_RepAcqRandom, value=0
	TitleBox title_Settings_SetCondition, pos={29.00, 361.00}, size={57.00, 12.00}, disable=1
	TitleBox title_Settings_SetCondition, title="\\Z10Set A > Set B"
	TitleBox title_Settings_SetCondition, userdata(tabnum)="5"
	TitleBox title_Settings_SetCondition, userdata(tabcontrol)="ADC"
	TitleBox title_Settings_SetCondition, userdata(ResizeControlsInfo)=A"!!,E*!!#Bg!!#>r!!#;Mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox title_Settings_SetCondition, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	TitleBox title_Settings_SetCondition, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	TitleBox title_Settings_SetCondition, frame=0
	CheckBox check_Settings_Option_3, pos={215.00, 376.00}, size={133.00, 30.00}, disable=1, proc=DAP_CheckProc_LockedLogic
	CheckBox check_Settings_Option_3, title="Repeat set B\runtil set A is complete"
	CheckBox check_Settings_Option_3, help={"This mode is useful when Set B contains a single wave."}
	CheckBox check_Settings_Option_3, userdata(tabnum)="5", userdata(tabcontrol)="ADC"
	CheckBox check_Settings_Option_3, userdata(ResizeControlsInfo)=A"!!,H1!!#Bn!!#@h!!#=Sz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_Settings_Option_3, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_Settings_Option_3, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_Settings_Option_3, value=0
	CheckBox check_Settings_ScalingZero, pos={215.00, 319.00}, size={140.00, 15.00}, disable=1, proc=DAP_CheckProc_UpdateGuiState
	CheckBox check_Settings_ScalingZero, title="Set channel scaling to 0"
	CheckBox check_Settings_ScalingZero, help={"Applies to DA channel outputting Set B"}
	CheckBox check_Settings_ScalingZero, userdata(tabnum)="5"
	CheckBox check_Settings_ScalingZero, userdata(tabcontrol)="ADC"
	CheckBox check_Settings_ScalingZero, userdata(ResizeControlsInfo)=A"!!,H1!!#BQJ,hqE!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_Settings_ScalingZero, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_Settings_ScalingZero, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_Settings_ScalingZero, value=0
	CheckBox check_Settings_SetOption_04, pos={215.00, 349.00}, size={116.00, 15.00}, disable=3, proc=DAP_CheckProc_UpdateGuiState
	CheckBox check_Settings_SetOption_04, title="Turn off headstage"
	CheckBox check_Settings_SetOption_04, help={"Turns off AD associated with DA via Channel and Amplifier Assignments"}
	CheckBox check_Settings_SetOption_04, userdata(tabnum)="5"
	CheckBox check_Settings_SetOption_04, userdata(tabcontrol)="ADC"
	CheckBox check_Settings_SetOption_04, userdata(ResizeControlsInfo)=A"!!,H1!!#B`J,hpu!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_Settings_SetOption_04, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_Settings_SetOption_04, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_Settings_SetOption_04, fColor=(65280, 43520, 0), value=0
	TitleBox title_Settings_SetCondition_00, pos={83.00, 343.00}, size={5.00, 15.00}, disable=1
	TitleBox title_Settings_SetCondition_00, title="\\f01/", userdata(tabnum)="5"
	TitleBox title_Settings_SetCondition_00, userdata(tabcontrol)="ADC"
	TitleBox title_Settings_SetCondition_00, userdata(ResizeControlsInfo)=A"!!,FI!!#B^!!#9W!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox title_Settings_SetCondition_00, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	TitleBox title_Settings_SetCondition_00, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	TitleBox title_Settings_SetCondition_00, frame=0
	TitleBox title_Settings_SetCondition_01, pos={83.00, 379.00}, size={5.00, 15.00}, disable=1
	TitleBox title_Settings_SetCondition_01, title="\\f01\\", userdata(tabnum)="5"
	TitleBox title_Settings_SetCondition_01, userdata(tabcontrol)="ADC"
	TitleBox title_Settings_SetCondition_01, userdata(ResizeControlsInfo)=A"!!,FI!!#BpJ,hj-!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox title_Settings_SetCondition_01, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	TitleBox title_Settings_SetCondition_01, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	TitleBox title_Settings_SetCondition_01, frame=0
	TitleBox title_Settings_SetCondition_04, pos={206.00, 343.00}, size={5.00, 15.00}, disable=1
	TitleBox title_Settings_SetCondition_04, title="\\f01\\", userdata(tabnum)="5"
	TitleBox title_Settings_SetCondition_04, userdata(tabcontrol)="ADC"
	TitleBox title_Settings_SetCondition_04, userdata(ResizeControlsInfo)=A"!!,H*!!#B^!!#9W!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox title_Settings_SetCondition_04, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	TitleBox title_Settings_SetCondition_04, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	TitleBox title_Settings_SetCondition_04, frame=0
	TitleBox title_Settings_SetCondition_02, pos={206.00, 322.00}, size={5.00, 15.00}, disable=1
	TitleBox title_Settings_SetCondition_02, title="\\f01/", userdata(tabnum)="5"
	TitleBox title_Settings_SetCondition_02, userdata(tabcontrol)="ADC"
	TitleBox title_Settings_SetCondition_02, userdata(ResizeControlsInfo)=A"!!,H)!!#BSJ,hj-!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox title_Settings_SetCondition_02, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	TitleBox title_Settings_SetCondition_02, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	TitleBox title_Settings_SetCondition_02, frame=0
	TitleBox title_Settings_SetCondition_03, pos={173.00, 331.00}, size={35.00, 15.00}, disable=1
	TitleBox title_Settings_SetCondition_03, title="\\f01-------"
	TitleBox title_Settings_SetCondition_03, userdata(tabnum)="5"
	TitleBox title_Settings_SetCondition_03, userdata(tabcontrol)="ADC"
	TitleBox title_Settings_SetCondition_03, userdata(ResizeControlsInfo)=A"!!,G^!!#BXJ,hnE!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox title_Settings_SetCondition_03, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	TitleBox title_Settings_SetCondition_03, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	TitleBox title_Settings_SetCondition_03, frame=0
	PopupMenu popup_MoreSettings_Devices, pos={81.00, 82.00}, size={182.00, 19.00}, bodyWidth=139
	PopupMenu popup_MoreSettings_Devices, title="Devices"
	PopupMenu popup_MoreSettings_Devices, help={"List of available devices for data acquisition"}
	PopupMenu popup_MoreSettings_Devices, userdata(tabnum)="6"
	PopupMenu popup_MoreSettings_Devices, userdata(tabcontrol)="ADC"
	PopupMenu popup_MoreSettings_Devices, userdata(ResizeControlsInfo)=A"!!,CL!!#?K!!#A3!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu popup_MoreSettings_Devices, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu popup_MoreSettings_Devices, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu popup_MoreSettings_Devices, userdata(Config_RestorePriority)="10"
	PopupMenu popup_MoreSettings_Devices, mode=1, popvalue="- none -", value=#"DAP_GetDACDeviceList()"
	SetVariable setvar_DataAcq_TerminationDelay, pos={288.00, 675.00}, size={175.00, 18.00}, bodyWidth=50, disable=1, proc=DAP_SetVar_UpdateGuiState
	SetVariable setvar_DataAcq_TerminationDelay, title="Termination delay (ms)"
	SetVariable setvar_DataAcq_TerminationDelay, help={"Global set(s) termination delay. Continues recording after set sweep is complete. Useful when recorded phenomena continues after termination of final set epoch."}
	SetVariable setvar_DataAcq_TerminationDelay, userdata(tabnum)="0"
	SetVariable setvar_DataAcq_TerminationDelay, userdata(tabcontrol)="ADC"
	SetVariable setvar_DataAcq_TerminationDelay, userdata(ResizeControlsInfo)=A"!!,HJJ,ht_5QF/+!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_DataAcq_TerminationDelay, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_DataAcq_TerminationDelay, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_DataAcq_TerminationDelay, value=_NUM:0
	GroupBox group_Hardware_FolderPath, pos={21.00, 48.00}, size={443.00, 76.00}
	GroupBox group_Hardware_FolderPath, title="Lock a device to generate device folder structure"
	GroupBox group_Hardware_FolderPath, userdata(tabnum)="6"
	GroupBox group_Hardware_FolderPath, userdata(tabcontrol)="ADC"
	GroupBox group_Hardware_FolderPath, userdata(ResizeControlsInfo)=A"!!,Bq!!#>R!!#CCJ,hpaz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	GroupBox group_Hardware_FolderPath, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	GroupBox group_Hardware_FolderPath, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	GroupBox group_Hardware_FolderPath, fSize=12
	Button button_SettingsPlus_LockDevice, pos={276.00, 69.00}, size={84.00, 45.00}, proc=DAP_ButtonProc_LockDev
	Button button_SettingsPlus_LockDevice, title="Lock device\r selection"
	Button button_SettingsPlus_LockDevice, help={"Device must be locked to acquire data. Locking can take a few seconds (calls to amp hardware are slow)."}
	Button button_SettingsPlus_LockDevice, userdata(tabnum)="6"
	Button button_SettingsPlus_LockDevice, userdata(tabcontrol)="ADC"
	Button button_SettingsPlus_LockDevice, userdata(ResizeControlsInfo)=A"!!,G[!!#?K!!#?c!!#>Fz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_SettingsPlus_LockDevice, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	Button button_SettingsPlus_LockDevice, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	Button button_SettingsPlus_LockDevice, userdata(Config_RestorePriority)="20"
	Button button_SettingsPlus_LockDevice, userdata(Config_PushButtonOnRestore)="1"
	Button button_SettingsPlus_unLockDevic, pos={369.00, 69.00}, size={84.00, 45.00}, disable=2, proc=DAP_ButProc_Hrdwr_UnlckDev
	Button button_SettingsPlus_unLockDevic, title="Unlock device\r selection"
	Button button_SettingsPlus_unLockDevic, userdata(tabnum)="6"
	Button button_SettingsPlus_unLockDevic, userdata(tabcontrol)="ADC"
	Button button_SettingsPlus_unLockDevic, userdata(ResizeControlsInfo)=A"!!,HNJ,hp!!!#?c!!#>Fz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_SettingsPlus_unLockDevic, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	Button button_SettingsPlus_unLockDevic, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	TitleBox title_Settings_SetCondition_1, pos={176.00, 394.00}, size={35.00, 15.00}, disable=1
	TitleBox title_Settings_SetCondition_1, title="\\f01-------", userdata(tabnum)="5"
	TitleBox title_Settings_SetCondition_1, userdata(tabcontrol)="ADC"
	TitleBox title_Settings_SetCondition_1, userdata(ResizeControlsInfo)=A"!!,G_!!#C#!!#=o!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox title_Settings_SetCondition_1, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	TitleBox title_Settings_SetCondition_1, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	TitleBox title_Settings_SetCondition_1, frame=0
	TitleBox title_Settings_SetCondition_2, pos={206.00, 406.00}, size={5.00, 15.00}, disable=1
	TitleBox title_Settings_SetCondition_2, title="\\f01\\", userdata(tabnum)="5"
	TitleBox title_Settings_SetCondition_2, userdata(tabcontrol)="ADC"
	TitleBox title_Settings_SetCondition_2, userdata(ResizeControlsInfo)=A"!!,H*!!#C(J,hj-!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox title_Settings_SetCondition_2, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	TitleBox title_Settings_SetCondition_2, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	TitleBox title_Settings_SetCondition_2, frame=0
	TitleBox title_Settings_SetCondition_3, pos={206.00, 385.00}, size={5.00, 15.00}, disable=1
	TitleBox title_Settings_SetCondition_3, title="\\f01/", userdata(tabnum)="5"
	TitleBox title_Settings_SetCondition_3, userdata(tabcontrol)="ADC"
	TitleBox title_Settings_SetCondition_3, userdata(ResizeControlsInfo)=A"!!,H*!!#Bs!!#9W!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox title_Settings_SetCondition_3, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	TitleBox title_Settings_SetCondition_3, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	TitleBox title_Settings_SetCondition_3, frame=0
	CheckBox check_Settings_SetOption_5, pos={215.00, 406.00}, size={103.00, 30.00}, disable=1, proc=DAP_CheckProc_LockedLogic
	CheckBox check_Settings_SetOption_5, title="Index to next set\ron DA with set B"
	CheckBox check_Settings_SetOption_5, help={"This mode is useful when Set B contains a single wave."}
	CheckBox check_Settings_SetOption_5, userdata(tabnum)="5"
	CheckBox check_Settings_SetOption_5, userdata(tabcontrol)="ADC"
	CheckBox check_Settings_SetOption_5, userdata(ResizeControlsInfo)=A"!!,H1!!#C(!!#@0!!#=Sz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_Settings_SetOption_5, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_Settings_SetOption_5, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox check_Settings_SetOption_5, value=1
	TitleBox title_Settings_SetCondition1, pos={92.00, 382.00}, size={90.00, 24.00}, disable=1
	TitleBox title_Settings_SetCondition1, title="\\Z10Continue acquisition\ron DA with set B"
	TitleBox title_Settings_SetCondition1, userdata(tabnum)="5"
	TitleBox title_Settings_SetCondition1, userdata(tabcontrol)="ADC"
	TitleBox title_Settings_SetCondition1, userdata(ResizeControlsInfo)=A"!!,F]!!#Br!!#?m!!#=#z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox title_Settings_SetCondition1, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	TitleBox title_Settings_SetCondition1, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	TitleBox title_Settings_SetCondition1, frame=0
	TitleBox title_Settings_SetCondition2, pos={95.00, 322.00}, size={86.00, 24.00}, disable=1
	TitleBox title_Settings_SetCondition2, title="\\Z10Stop Acquisition on\rDA with Set B"
	TitleBox title_Settings_SetCondition2, userdata(tabnum)="5"
	TitleBox title_Settings_SetCondition2, userdata(tabcontrol)="ADC"
	TitleBox title_Settings_SetCondition2, userdata(ResizeControlsInfo)=A"!!,Fa!!#BT!!#?e!!#=#z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox title_Settings_SetCondition2, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	TitleBox title_Settings_SetCondition2, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	TitleBox title_Settings_SetCondition2, fSize=12, frame=0
	ValDisplay valdisp_DataAcq_SweepsInSet, pos={297.00, 540.00}, size={30.00, 21.00}, bodyWidth=30, disable=1
	ValDisplay valdisp_DataAcq_SweepsInSet, userdata(tabnum)="0"
	ValDisplay valdisp_DataAcq_SweepsInSet, userdata(tabcontrol)="ADC"
	ValDisplay valdisp_DataAcq_SweepsInSet, userdata(ResizeControlsInfo)=A"!!,HP!!#Ck^]6[i!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	ValDisplay valdisp_DataAcq_SweepsInSet, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	ValDisplay valdisp_DataAcq_SweepsInSet, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	ValDisplay valdisp_DataAcq_SweepsInSet, fSize=14, fStyle=0
	ValDisplay valdisp_DataAcq_SweepsInSet, valueColor=(65535, 65535, 65535)
	ValDisplay valdisp_DataAcq_SweepsInSet, valueBackColor=(0, 0, 0)
	ValDisplay valdisp_DataAcq_SweepsInSet, limits={0, 0, 0}, barmisc={0, 1000}
	ValDisplay valdisp_DataAcq_SweepsInSet, value=_NUM:1
	CheckBox Check_DataAcq1_IndexingLocked, pos={191.00, 674.00}, size={54.00, 15.00}, disable=1, proc=DAP_CheckProc_IndexingState
	CheckBox Check_DataAcq1_IndexingLocked, title="Locked"
	CheckBox Check_DataAcq1_IndexingLocked, help={"Data acquisition proceeds to next wave in DAC or TTL popup menu list"}
	CheckBox Check_DataAcq1_IndexingLocked, userdata(tabnum)="0"
	CheckBox Check_DataAcq1_IndexingLocked, userdata(tabcontrol)="ADC"
	CheckBox Check_DataAcq1_IndexingLocked, userdata(ResizeControlsInfo)=A"!!,Gb!!#DBJ,ho8!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_DataAcq1_IndexingLocked, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox Check_DataAcq1_IndexingLocked, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox Check_DataAcq1_IndexingLocked, userdata(Config_DontRestore)="1"
	CheckBox Check_DataAcq1_IndexingLocked, userdata(Config_DontSave)="1", value=0
	SetVariable SetVar_DataAcq_ListRepeats, pos={173.00, 689.00}, size={109.00, 18.00}, bodyWidth=35, disable=1, proc=DAP_SetVarProc_TotSweepCount
	SetVariable SetVar_DataAcq_ListRepeats, title="Repeat List(s)"
	SetVariable SetVar_DataAcq_ListRepeats, help={"This number is set automatically at based on the number of 1d waves contained in the largest set on active DA/TTL channels"}
	SetVariable SetVar_DataAcq_ListRepeats, userdata(tabnum)="0"
	SetVariable SetVar_DataAcq_ListRepeats, userdata(tabcontrol)="ADC"
	SetVariable SetVar_DataAcq_ListRepeats, userdata(ResizeControlsInfo)=A"!!,Fk!!#DGJ,hpi!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_DataAcq_ListRepeats, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable SetVar_DataAcq_ListRepeats, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable SetVar_DataAcq_ListRepeats, fColor=(65280, 43520, 0)
	SetVariable SetVar_DataAcq_ListRepeats, limits={1, Inf, 1}, value=_NUM:1
	CheckBox check_DataAcq_IndexRandom, pos={191.00, 656.00}, size={61.00, 15.00}, disable=1, proc=DAP_CheckProc_UpdateGuiState
	CheckBox check_DataAcq_IndexRandom, title="Random"
	CheckBox check_DataAcq_IndexRandom, help={"Randomly selects wave from set selected for DAC channel on each sweep. Doesn't repeat waves."}
	CheckBox check_DataAcq_IndexRandom, userdata(tabnum)="0"
	CheckBox check_DataAcq_IndexRandom, userdata(tabcontrol)="ADC"
	CheckBox check_DataAcq_IndexRandom, userdata(ResizeControlsInfo)=A"!!,Gb!!#D>5QF,i!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_DataAcq_IndexRandom, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_DataAcq_IndexRandom, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox check_DataAcq_IndexRandom, fColor=(65280, 43520, 0), value=0
	ValDisplay valdisp_DataAcq_SweepsActiveSet, pos={297.00, 567.00}, size={30.00, 21.00}, bodyWidth=30, disable=1
	ValDisplay valdisp_DataAcq_SweepsActiveSet, help={"Displays the number of steps in the set with the most steps on active DA and TTL channels"}
	ValDisplay valdisp_DataAcq_SweepsActiveSet, userdata(tabnum)="0"
	ValDisplay valdisp_DataAcq_SweepsActiveSet, userdata(tabcontrol)="ADC"
	ValDisplay valdisp_DataAcq_SweepsActiveSet, userdata(ResizeControlsInfo)=A"!!,HP!!#CrJ,hn)!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	ValDisplay valdisp_DataAcq_SweepsActiveSet, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	ValDisplay valdisp_DataAcq_SweepsActiveSet, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	ValDisplay valdisp_DataAcq_SweepsActiveSet, fSize=14, fStyle=0
	ValDisplay valdisp_DataAcq_SweepsActiveSet, valueColor=(65535, 65535, 65535)
	ValDisplay valdisp_DataAcq_SweepsActiveSet, valueBackColor=(0, 0, 0)
	ValDisplay valdisp_DataAcq_SweepsActiveSet, limits={0, 0, 0}, barmisc={0, 1000}
	ValDisplay valdisp_DataAcq_SweepsActiveSet, value=_NUM:1
	SetVariable SetVar_DataAcq_TPAmplitudeIC, pos={205.00, 427.00}, size={65.00, 18.00}, bodyWidth=50, disable=1, proc=DAP_SetVarProc_TestPulseSett
	SetVariable SetVar_DataAcq_TPAmplitudeIC, title="IC"
	SetVariable SetVar_DataAcq_TPAmplitudeIC, help={"Amplitude of the testpulse in current clamp mode"}
	SetVariable SetVar_DataAcq_TPAmplitudeIC, userdata(tabnum)="0"
	SetVariable SetVar_DataAcq_TPAmplitudeIC, userdata(tabcontrol)="ADC"
	SetVariable SetVar_DataAcq_TPAmplitudeIC, userdata(ResizeControlsInfo)=A"!!,I$J,hs`J,hof!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_DataAcq_TPAmplitudeIC, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable SetVar_DataAcq_TPAmplitudeIC, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable SetVar_DataAcq_TPAmplitudeIC, userdata(Config_GroupPath)="Test Pulse"
	SetVariable SetVar_DataAcq_TPAmplitudeIC, value=_NUM:-50
	SetVariable SetVar_Hardware_VC_DA_Unit, pos={169.00, 411.00}, size={30.00, 18.00}, proc=DAP_SetVarProc_CAA
	SetVariable SetVar_Hardware_VC_DA_Unit, userdata(tabnum)="6"
	SetVariable SetVar_Hardware_VC_DA_Unit, userdata(tabcontrol)="ADC"
	SetVariable SetVar_Hardware_VC_DA_Unit, userdata(ResizeControlsInfo)=A"!!,G5!!#C3J,hn)!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_Hardware_VC_DA_Unit, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable SetVar_Hardware_VC_DA_Unit, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable SetVar_Hardware_VC_DA_Unit, userdata(Config_DontRestore)="1"
	SetVariable SetVar_Hardware_VC_DA_Unit, userdata(Config_DontSave)="1"
	SetVariable SetVar_Hardware_VC_DA_Unit, value=_STR:"mV"
	SetVariable SetVar_Hardware_IC_DA_Unit, pos={374.00, 411.00}, size={30.00, 18.00}, proc=DAP_SetVarProc_CAA
	SetVariable SetVar_Hardware_IC_DA_Unit, userdata(tabnum)="6"
	SetVariable SetVar_Hardware_IC_DA_Unit, userdata(tabcontrol)="ADC"
	SetVariable SetVar_Hardware_IC_DA_Unit, userdata(ResizeControlsInfo)=A"!!,Hg!!#C4!!#=S!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_Hardware_IC_DA_Unit, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable SetVar_Hardware_IC_DA_Unit, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable SetVar_Hardware_IC_DA_Unit, userdata(Config_DontRestore)="1"
	SetVariable SetVar_Hardware_IC_DA_Unit, userdata(Config_DontSave)="1"
	SetVariable SetVar_Hardware_IC_DA_Unit, value=_STR:"pA"
	SetVariable SetVar_Hardware_VC_AD_Unit, pos={191.00, 438.00}, size={30.00, 18.00}, proc=DAP_SetVarProc_CAA
	SetVariable SetVar_Hardware_VC_AD_Unit, userdata(tabnum)="6"
	SetVariable SetVar_Hardware_VC_AD_Unit, userdata(tabcontrol)="ADC"
	SetVariable SetVar_Hardware_VC_AD_Unit, userdata(ResizeControlsInfo)=A"!!,GJ!!#C@!!#=S!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_Hardware_VC_AD_Unit, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable SetVar_Hardware_VC_AD_Unit, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable SetVar_Hardware_VC_AD_Unit, userdata(Config_DontRestore)="1"
	SetVariable SetVar_Hardware_VC_AD_Unit, userdata(Config_DontSave)="1"
	SetVariable SetVar_Hardware_VC_AD_Unit, value=_STR:"pA"
	SetVariable SetVar_Hardware_IC_AD_Unit, pos={395.00, 438.00}, size={30.00, 18.00}, proc=DAP_SetVarProc_CAA
	SetVariable SetVar_Hardware_IC_AD_Unit, userdata(tabnum)="6"
	SetVariable SetVar_Hardware_IC_AD_Unit, userdata(tabcontrol)="ADC"
	SetVariable SetVar_Hardware_IC_AD_Unit, userdata(ResizeControlsInfo)=A"!!,HrJ,hsk!!#=S!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_Hardware_IC_AD_Unit, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable SetVar_Hardware_IC_AD_Unit, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable SetVar_Hardware_IC_AD_Unit, userdata(Config_DontRestore)="1"
	SetVariable SetVar_Hardware_IC_AD_Unit, userdata(Config_DontSave)="1"
	SetVariable SetVar_Hardware_IC_AD_Unit, value=_STR:"mV"
	TitleBox Title_Hardware_VC_gain, pos={110.00, 393.00}, size={23.00, 15.00}
	TitleBox Title_Hardware_VC_gain, title="gain", userdata(tabnum)="6"
	TitleBox Title_Hardware_VC_gain, userdata(tabcontrol)="ADC"
	TitleBox Title_Hardware_VC_gain, userdata(ResizeControlsInfo)=A"!!,F;!!#C*J,hmF!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox Title_Hardware_VC_gain, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	TitleBox Title_Hardware_VC_gain, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	TitleBox Title_Hardware_VC_gain, frame=0
	TitleBox Title_Hardware_VC_unit, pos={170.00, 393.00}, size={21.00, 15.00}
	TitleBox Title_Hardware_VC_unit, title="unit", userdata(tabnum)="6"
	TitleBox Title_Hardware_VC_unit, userdata(tabcontrol)="ADC"
	TitleBox Title_Hardware_VC_unit, userdata(ResizeControlsInfo)=A"!!,GG!!#C*J,hm6!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox Title_Hardware_VC_unit, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	TitleBox Title_Hardware_VC_unit, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	TitleBox Title_Hardware_VC_unit, frame=0
	TitleBox Title_Hardware_IC_gain, pos={311.00, 393.00}, size={23.00, 15.00}
	TitleBox Title_Hardware_IC_gain, title="gain", userdata(tabnum)="6"
	TitleBox Title_Hardware_IC_gain, userdata(tabcontrol)="ADC"
	TitleBox Title_Hardware_IC_gain, userdata(ResizeControlsInfo)=A"!!,HKJ,hsUJ,hmF!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox Title_Hardware_IC_gain, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	TitleBox Title_Hardware_IC_gain, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	TitleBox Title_Hardware_IC_gain, frame=0
	TitleBox Title_Hardware_IC_unit, pos={363.00, 393.00}, size={21.00, 15.00}
	TitleBox Title_Hardware_IC_unit, title="unit", userdata(tabnum)="6"
	TitleBox Title_Hardware_IC_unit, userdata(tabcontrol)="ADC"
	TitleBox Title_Hardware_IC_unit, userdata(ResizeControlsInfo)=A"!!,HgJ,hsUJ,hm6!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox Title_Hardware_IC_unit, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	TitleBox Title_Hardware_IC_unit, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	TitleBox Title_Hardware_IC_unit, frame=0
	SetVariable Unit_DA_00, pos={105.00, 75.00}, size={30.00, 18.00}, disable=1, proc=DAP_SetVar_UpdateGuiState
	SetVariable Unit_DA_00, userdata(tabnum)="1", userdata(tabcontrol)="ADC"
	SetVariable Unit_DA_00, userdata(ResizeControlsInfo)=A"!!,F7!!#?O!!#=S!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Unit_DA_00, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable Unit_DA_00, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable Unit_DA_00, userdata(ControlArray)="Unit_DA"
	SetVariable Unit_DA_00, userdata(ControlArrayIndex)="0"
	SetVariable Unit_DA_00, limits={0, Inf, 1}, value=_STR:""
	TitleBox Title_DA_Unit, pos={105.00, 48.00}, size={24.00, 15.00}, disable=1
	TitleBox Title_DA_Unit, title="Unit", userdata(tabnum)="1"
	TitleBox Title_DA_Unit, userdata(tabcontrol)="ADC"
	TitleBox Title_DA_Unit, userdata(ResizeControlsInfo)=A"!!,F7!!#>V!!#=#!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox Title_DA_Unit, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	TitleBox Title_DA_Unit, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	TitleBox Title_DA_Unit, frame=0, fStyle=1
	SetVariable Unit_DA_01, pos={105.00, 120.00}, size={30.00, 18.00}, disable=1, proc=DAP_SetVar_UpdateGuiState
	SetVariable Unit_DA_01, userdata(tabnum)="1", userdata(tabcontrol)="ADC"
	SetVariable Unit_DA_01, userdata(ResizeControlsInfo)=A"!!,F7!!#@V!!#=S!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Unit_DA_01, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable Unit_DA_01, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable Unit_DA_01, userdata(ControlArray)="Unit_DA"
	SetVariable Unit_DA_01, userdata(ControlArrayIndex)="1"
	SetVariable Unit_DA_01, limits={0, Inf, 1}, value=_STR:""
	SetVariable Unit_DA_02, pos={105.00, 165.00}, size={30.00, 18.00}, disable=1, proc=DAP_SetVar_UpdateGuiState
	SetVariable Unit_DA_02, userdata(tabnum)="1", userdata(tabcontrol)="ADC"
	SetVariable Unit_DA_02, userdata(ResizeControlsInfo)=A"!!,F7!!#A6!!#=S!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Unit_DA_02, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable Unit_DA_02, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable Unit_DA_02, userdata(ControlArray)="Unit_DA"
	SetVariable Unit_DA_02, userdata(ControlArrayIndex)="2"
	SetVariable Unit_DA_02, limits={0, Inf, 1}, value=_STR:""
	SetVariable Unit_DA_03, pos={105.00, 213.00}, size={30.00, 18.00}, disable=1, proc=DAP_SetVar_UpdateGuiState
	SetVariable Unit_DA_03, userdata(tabnum)="1", userdata(tabcontrol)="ADC"
	SetVariable Unit_DA_03, userdata(ResizeControlsInfo)=A"!!,F7!!#Ae!!#=S!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Unit_DA_03, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable Unit_DA_03, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable Unit_DA_03, userdata(ControlArray)="Unit_DA"
	SetVariable Unit_DA_03, userdata(ControlArrayIndex)="3"
	SetVariable Unit_DA_03, limits={0, Inf, 1}, value=_STR:""
	SetVariable Unit_DA_04, pos={105.00, 258.00}, size={30.00, 18.00}, disable=1, proc=DAP_SetVar_UpdateGuiState
	SetVariable Unit_DA_04, userdata(tabnum)="1", userdata(tabcontrol)="ADC"
	SetVariable Unit_DA_04, userdata(ResizeControlsInfo)=A"!!,F7!!#B<!!#=S!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Unit_DA_04, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable Unit_DA_04, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable Unit_DA_04, userdata(ControlArray)="Unit_DA"
	SetVariable Unit_DA_04, userdata(ControlArrayIndex)="4"
	SetVariable Unit_DA_04, limits={0, Inf, 1}, value=_STR:""
	SetVariable Unit_DA_05, pos={105.00, 306.00}, size={30.00, 18.00}, disable=1, proc=DAP_SetVar_UpdateGuiState
	SetVariable Unit_DA_05, userdata(tabnum)="1", userdata(tabcontrol)="ADC"
	SetVariable Unit_DA_05, userdata(ResizeControlsInfo)=A"!!,F7!!#BSJ,hn)!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Unit_DA_05, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable Unit_DA_05, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable Unit_DA_05, userdata(ControlArray)="Unit_DA"
	SetVariable Unit_DA_05, userdata(ControlArrayIndex)="5"
	SetVariable Unit_DA_05, limits={0, Inf, 1}, value=_STR:""
	SetVariable Unit_DA_06, pos={105.00, 351.00}, size={30.00, 18.00}, disable=1, proc=DAP_SetVar_UpdateGuiState
	SetVariable Unit_DA_06, userdata(tabnum)="1", userdata(tabcontrol)="ADC"
	SetVariable Unit_DA_06, userdata(ResizeControlsInfo)=A"!!,F7!!#BjJ,hn)!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Unit_DA_06, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable Unit_DA_06, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable Unit_DA_06, userdata(ControlArray)="Unit_DA"
	SetVariable Unit_DA_06, userdata(ControlArrayIndex)="6"
	SetVariable Unit_DA_06, limits={0, Inf, 1}, value=_STR:""
	SetVariable Unit_DA_07, pos={105.00, 399.00}, size={30.00, 18.00}, disable=1, proc=DAP_SetVar_UpdateGuiState
	SetVariable Unit_DA_07, userdata(tabnum)="1", userdata(tabcontrol)="ADC"
	SetVariable Unit_DA_07, userdata(ResizeControlsInfo)=A"!!,F7!!#C-!!#=S!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Unit_DA_07, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable Unit_DA_07, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable Unit_DA_07, userdata(ControlArray)="Unit_DA"
	SetVariable Unit_DA_07, userdata(ControlArrayIndex)="7"
	SetVariable Unit_DA_07, limits={0, Inf, 1}, value=_STR:""
	SetVariable Unit_AD_00, pos={108.00, 75.00}, size={39.00, 18.00}, disable=1, proc=DAP_SetVar_UpdateGuiState
	SetVariable Unit_AD_00, title="V/", userdata(tabnum)="2"
	SetVariable Unit_AD_00, userdata(tabcontrol)="ADC"
	SetVariable Unit_AD_00, userdata(ResizeControlsInfo)=A"!!,FA!!#?O!!#>.!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Unit_AD_00, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable Unit_AD_00, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable Unit_AD_00, userdata(ControlArray)="Unit_AD"
	SetVariable Unit_AD_00, userdata(ControlArrayIndex)="0"
	SetVariable Unit_AD_00, limits={0, Inf, 1}, value=_STR:""
	SetVariable Unit_AD_01, pos={108.00, 120.00}, size={39.00, 18.00}, disable=1, proc=DAP_SetVar_UpdateGuiState
	SetVariable Unit_AD_01, title="V/", userdata(tabnum)="2"
	SetVariable Unit_AD_01, userdata(tabcontrol)="ADC"
	SetVariable Unit_AD_01, userdata(ResizeControlsInfo)=A"!!,FA!!#@V!!#>.!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Unit_AD_01, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable Unit_AD_01, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable Unit_AD_01, userdata(ControlArray)="Unit_AD"
	SetVariable Unit_AD_01, userdata(ControlArrayIndex)="1"
	SetVariable Unit_AD_01, limits={0, Inf, 1}, value=_STR:""
	SetVariable Unit_AD_02, pos={108.00, 165.00}, size={39.00, 18.00}, disable=1, proc=DAP_SetVar_UpdateGuiState
	SetVariable Unit_AD_02, title="V/", userdata(tabnum)="2"
	SetVariable Unit_AD_02, userdata(tabcontrol)="ADC"
	SetVariable Unit_AD_02, userdata(ResizeControlsInfo)=A"!!,FA!!#A6!!#>.!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Unit_AD_02, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable Unit_AD_02, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable Unit_AD_02, userdata(ControlArray)="Unit_AD"
	SetVariable Unit_AD_02, userdata(ControlArrayIndex)="2"
	SetVariable Unit_AD_02, limits={0, Inf, 1}, value=_STR:""
	SetVariable Unit_AD_03, pos={108.00, 213.00}, size={39.00, 18.00}, disable=1, proc=DAP_SetVar_UpdateGuiState
	SetVariable Unit_AD_03, title="V/", userdata(tabnum)="2"
	SetVariable Unit_AD_03, userdata(tabcontrol)="ADC"
	SetVariable Unit_AD_03, userdata(ResizeControlsInfo)=A"!!,FA!!#Ae!!#>.!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Unit_AD_03, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable Unit_AD_03, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable Unit_AD_03, userdata(ControlArray)="Unit_AD"
	SetVariable Unit_AD_03, userdata(ControlArrayIndex)="3"
	SetVariable Unit_AD_03, limits={0, Inf, 1}, value=_STR:""
	SetVariable Unit_AD_04, pos={108.00, 258.00}, size={39.00, 18.00}, disable=1, proc=DAP_SetVar_UpdateGuiState
	SetVariable Unit_AD_04, title="V/", userdata(tabnum)="2"
	SetVariable Unit_AD_04, userdata(tabcontrol)="ADC"
	SetVariable Unit_AD_04, userdata(ResizeControlsInfo)=A"!!,FA!!#B<!!#>.!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Unit_AD_04, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable Unit_AD_04, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable Unit_AD_04, userdata(ControlArray)="Unit_AD"
	SetVariable Unit_AD_04, userdata(ControlArrayIndex)="4"
	SetVariable Unit_AD_04, limits={0, Inf, 1}, value=_STR:""
	SetVariable Unit_AD_05, pos={108.00, 306.00}, size={39.00, 18.00}, disable=1, proc=DAP_SetVar_UpdateGuiState
	SetVariable Unit_AD_05, title="V/", userdata(tabnum)="2"
	SetVariable Unit_AD_05, userdata(tabcontrol)="ADC"
	SetVariable Unit_AD_05, userdata(ResizeControlsInfo)=A"!!,FA!!#BSJ,hnY!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Unit_AD_05, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable Unit_AD_05, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable Unit_AD_05, userdata(ControlArray)="Unit_AD"
	SetVariable Unit_AD_05, userdata(ControlArrayIndex)="5"
	SetVariable Unit_AD_05, limits={0, Inf, 1}, value=_STR:""
	SetVariable Unit_AD_06, pos={108.00, 351.00}, size={39.00, 18.00}, disable=1, proc=DAP_SetVar_UpdateGuiState
	SetVariable Unit_AD_06, title="V/", userdata(tabnum)="2"
	SetVariable Unit_AD_06, userdata(tabcontrol)="ADC"
	SetVariable Unit_AD_06, userdata(ResizeControlsInfo)=A"!!,FA!!#BjJ,hnY!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Unit_AD_06, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable Unit_AD_06, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable Unit_AD_06, userdata(ControlArray)="Unit_AD"
	SetVariable Unit_AD_06, userdata(ControlArrayIndex)="6"
	SetVariable Unit_AD_06, limits={0, Inf, 1}, value=_STR:""
	SetVariable Unit_AD_07, pos={108.00, 399.00}, size={39.00, 18.00}, disable=1, proc=DAP_SetVar_UpdateGuiState
	SetVariable Unit_AD_07, title="V/", userdata(tabnum)="2"
	SetVariable Unit_AD_07, userdata(tabcontrol)="ADC"
	SetVariable Unit_AD_07, userdata(ResizeControlsInfo)=A"!!,FA!!#C-!!#>.!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Unit_AD_07, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable Unit_AD_07, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable Unit_AD_07, userdata(ControlArray)="Unit_AD"
	SetVariable Unit_AD_07, userdata(ControlArrayIndex)="7"
	SetVariable Unit_AD_07, limits={0, Inf, 1}, value=_STR:""
	SetVariable Unit_AD_08, pos={288.00, 75.00}, size={39.00, 18.00}, disable=1, proc=DAP_SetVar_UpdateGuiState
	SetVariable Unit_AD_08, title="V/", userdata(tabnum)="2"
	SetVariable Unit_AD_08, userdata(tabcontrol)="ADC"
	SetVariable Unit_AD_08, userdata(ResizeControlsInfo)=A"!!,HL!!#?O!!#>.!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Unit_AD_08, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable Unit_AD_08, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable Unit_AD_08, userdata(ControlArray)="Unit_AD"
	SetVariable Unit_AD_08, userdata(ControlArrayIndex)="8"
	SetVariable Unit_AD_08, limits={0, Inf, 1}, value=_STR:""
	SetVariable Unit_AD_09, pos={288.00, 120.00}, size={39.00, 18.00}, disable=1, proc=DAP_SetVar_UpdateGuiState
	SetVariable Unit_AD_09, title="V/", userdata(tabnum)="2"
	SetVariable Unit_AD_09, userdata(tabcontrol)="ADC"
	SetVariable Unit_AD_09, userdata(ResizeControlsInfo)=A"!!,HL!!#@V!!#>.!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Unit_AD_09, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable Unit_AD_09, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable Unit_AD_09, userdata(ControlArray)="Unit_AD"
	SetVariable Unit_AD_09, userdata(ControlArrayIndex)="9"
	SetVariable Unit_AD_09, limits={0, Inf, 1}, value=_STR:""
	SetVariable Unit_AD_10, pos={288.00, 165.00}, size={39.00, 18.00}, disable=1, proc=DAP_SetVar_UpdateGuiState
	SetVariable Unit_AD_10, title="V/", userdata(tabnum)="2"
	SetVariable Unit_AD_10, userdata(tabcontrol)="ADC"
	SetVariable Unit_AD_10, userdata(ResizeControlsInfo)=A"!!,HL!!#A6!!#>.!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Unit_AD_10, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable Unit_AD_10, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable Unit_AD_10, userdata(ControlArray)="Unit_AD"
	SetVariable Unit_AD_10, userdata(ControlArrayIndex)="10"
	SetVariable Unit_AD_10, limits={0, Inf, 1}, value=_STR:""
	SetVariable Unit_AD_11, pos={288.00, 213.00}, size={39.00, 18.00}, disable=1, proc=DAP_SetVar_UpdateGuiState
	SetVariable Unit_AD_11, title="V/", userdata(tabnum)="2"
	SetVariable Unit_AD_11, userdata(tabcontrol)="ADC"
	SetVariable Unit_AD_11, userdata(ResizeControlsInfo)=A"!!,HL!!#Ae!!#>.!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Unit_AD_11, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable Unit_AD_11, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable Unit_AD_11, userdata(ControlArray)="Unit_AD"
	SetVariable Unit_AD_11, userdata(ControlArrayIndex)="11"
	SetVariable Unit_AD_11, limits={0, Inf, 1}, value=_STR:""
	SetVariable Unit_AD_12, pos={288.00, 258.00}, size={39.00, 18.00}, disable=1, proc=DAP_SetVar_UpdateGuiState
	SetVariable Unit_AD_12, title="V/", userdata(tabnum)="2"
	SetVariable Unit_AD_12, userdata(tabcontrol)="ADC"
	SetVariable Unit_AD_12, userdata(ResizeControlsInfo)=A"!!,HL!!#B<!!#>.!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Unit_AD_12, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable Unit_AD_12, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable Unit_AD_12, userdata(ControlArray)="Unit_AD"
	SetVariable Unit_AD_12, userdata(ControlArrayIndex)="12"
	SetVariable Unit_AD_12, limits={0, Inf, 1}, value=_STR:""
	SetVariable Unit_AD_13, pos={288.00, 306.00}, size={39.00, 18.00}, disable=1, proc=DAP_SetVar_UpdateGuiState
	SetVariable Unit_AD_13, title="V/", userdata(tabnum)="2"
	SetVariable Unit_AD_13, userdata(tabcontrol)="ADC"
	SetVariable Unit_AD_13, userdata(ResizeControlsInfo)=A"!!,HL!!#BSJ,hnY!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Unit_AD_13, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable Unit_AD_13, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable Unit_AD_13, userdata(ControlArray)="Unit_AD"
	SetVariable Unit_AD_13, userdata(ControlArrayIndex)="13"
	SetVariable Unit_AD_13, limits={0, Inf, 1}, value=_STR:""
	SetVariable Unit_AD_14, pos={288.00, 351.00}, size={39.00, 18.00}, disable=1, proc=DAP_SetVar_UpdateGuiState
	SetVariable Unit_AD_14, title="V/", userdata(tabnum)="2"
	SetVariable Unit_AD_14, userdata(tabcontrol)="ADC"
	SetVariable Unit_AD_14, userdata(ResizeControlsInfo)=A"!!,HL!!#BjJ,hnY!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Unit_AD_14, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable Unit_AD_14, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable Unit_AD_14, userdata(ControlArray)="Unit_AD"
	SetVariable Unit_AD_14, userdata(ControlArrayIndex)="14"
	SetVariable Unit_AD_14, limits={0, Inf, 1}, value=_STR:""
	SetVariable Unit_AD_15, pos={288.00, 399.00}, size={39.00, 18.00}, disable=1, proc=DAP_SetVar_UpdateGuiState
	SetVariable Unit_AD_15, title="V/", userdata(tabnum)="2"
	SetVariable Unit_AD_15, userdata(tabcontrol)="ADC"
	SetVariable Unit_AD_15, userdata(ResizeControlsInfo)=A"!!,HL!!#C-!!#>.!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Unit_AD_15, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable Unit_AD_15, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable Unit_AD_15, userdata(ControlArray)="Unit_AD"
	SetVariable Unit_AD_15, userdata(ControlArrayIndex)="15"
	SetVariable Unit_AD_15, limits={0, Inf, 1}, value=_STR:""
	TitleBox Title_AD_Unit, pos={120.00, 48.00}, size={24.00, 15.00}, disable=1
	TitleBox Title_AD_Unit, title="Unit", userdata(tabnum)="2"
	TitleBox Title_AD_Unit, userdata(tabcontrol)="ADC"
	TitleBox Title_AD_Unit, userdata(ResizeControlsInfo)=A"!!,FY!!#>V!!#=#!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox Title_AD_Unit, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	TitleBox Title_AD_Unit, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	TitleBox Title_AD_Unit, frame=0, fStyle=1
	TitleBox Title_AD_Gain, pos={54.00, 48.00}, size={25.00, 15.00}, disable=1
	TitleBox Title_AD_Gain, title="Gain", userdata(tabnum)="2"
	TitleBox Title_AD_Gain, userdata(tabcontrol)="ADC"
	TitleBox Title_AD_Gain, userdata(ResizeControlsInfo)=A"!!,Dk!!#>V!!#=+!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox Title_AD_Gain, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	TitleBox Title_AD_Gain, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	TitleBox Title_AD_Gain, frame=0, fStyle=1
	TitleBox Title_AD_Channel, pos={24.00, 48.00}, size={17.00, 15.00}, disable=1
	TitleBox Title_AD_Channel, title="AD", userdata(tabnum)="2"
	TitleBox Title_AD_Channel, userdata(tabcontrol)="ADC"
	TitleBox Title_AD_Channel, userdata(ResizeControlsInfo)=A"!!,C,!!#>V!!#<@!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox Title_AD_Channel, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	TitleBox Title_AD_Channel, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	TitleBox Title_AD_Channel, frame=0, fStyle=1
	TitleBox Title_AD_Channel1, pos={195.00, 48.00}, size={17.00, 15.00}, disable=1
	TitleBox Title_AD_Channel1, title="AD", userdata(tabnum)="2"
	TitleBox Title_AD_Channel1, userdata(tabcontrol)="ADC"
	TitleBox Title_AD_Channel1, userdata(ResizeControlsInfo)=A"!!,GS!!#>V!!#<@!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox Title_AD_Channel1, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	TitleBox Title_AD_Channel1, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	TitleBox Title_AD_Channel1, frame=0, fStyle=1
	TitleBox Title_AD_Gain1, pos={231.00, 48.00}, size={25.00, 15.00}, disable=1
	TitleBox Title_AD_Gain1, title="Gain", userdata(tabnum)="2"
	TitleBox Title_AD_Gain1, userdata(tabcontrol)="ADC"
	TitleBox Title_AD_Gain1, userdata(ResizeControlsInfo)=A"!!,H$!!#>V!!#=+!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox Title_AD_Gain1, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	TitleBox Title_AD_Gain1, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	TitleBox Title_AD_Gain1, frame=0, fStyle=1
	TitleBox Title_AD_Unit1, pos={294.00, 48.00}, size={24.00, 15.00}, disable=1
	TitleBox Title_AD_Unit1, title="Unit", userdata(tabnum)="2"
	TitleBox Title_AD_Unit1, userdata(tabcontrol)="ADC"
	TitleBox Title_AD_Unit1, userdata(ResizeControlsInfo)=A"!!,HN!!#>V!!#=#!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox Title_AD_Unit1, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	TitleBox Title_AD_Unit1, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	TitleBox Title_AD_Unit1, frame=0, fStyle=1
	TitleBox Title_Hardware_VC_DA_Div, pos={202.00, 414.00}, size={15.00, 15.00}
	TitleBox Title_Hardware_VC_DA_Div, title="/ V", userdata(tabnum)="6"
	TitleBox Title_Hardware_VC_DA_Div, userdata(tabcontrol)="ADC"
	TitleBox Title_Hardware_VC_DA_Div, userdata(ResizeControlsInfo)=A"!!,GW!!#C4J,hlS!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox Title_Hardware_VC_DA_Div, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	TitleBox Title_Hardware_VC_DA_Div, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	TitleBox Title_Hardware_VC_DA_Div, frame=0
	TitleBox Title_Hardware_IC_DA_Div, pos={402.00, 414.00}, size={15.00, 15.00}
	TitleBox Title_Hardware_IC_DA_Div, title="/ V", userdata(tabnum)="6"
	TitleBox Title_Hardware_IC_DA_Div, userdata(tabcontrol)="ADC"
	TitleBox Title_Hardware_IC_DA_Div, userdata(ResizeControlsInfo)=A"!!,I\"!!#C4J,hlS!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox Title_Hardware_IC_DA_Div, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	TitleBox Title_Hardware_IC_DA_Div, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	TitleBox Title_Hardware_IC_DA_Div, frame=0
	TitleBox Title_Hardware_IC_AD_Div, pos={375.00, 438.00}, size={15.00, 15.00}
	TitleBox Title_Hardware_IC_AD_Div, title="V /", userdata(tabnum)="6"
	TitleBox Title_Hardware_IC_AD_Div, userdata(tabcontrol)="ADC"
	TitleBox Title_Hardware_IC_AD_Div, userdata(ResizeControlsInfo)=A"!!,HiJ,hsl!!#<(!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox Title_Hardware_IC_AD_Div, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	TitleBox Title_Hardware_IC_AD_Div, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	TitleBox Title_Hardware_IC_AD_Div, frame=0
	TitleBox Title_Hardware_IC_AD_Div1, pos={170.00, 438.00}, size={15.00, 15.00}
	TitleBox Title_Hardware_IC_AD_Div1, title="V /", userdata(tabnum)="6"
	TitleBox Title_Hardware_IC_AD_Div1, userdata(tabcontrol)="ADC"
	TitleBox Title_Hardware_IC_AD_Div1, userdata(ResizeControlsInfo)=A"!!,G7!!#CA!!#<(!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox Title_Hardware_IC_AD_Div1, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	TitleBox Title_Hardware_IC_AD_Div1, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	TitleBox Title_Hardware_IC_AD_Div1, frame=0
	GroupBox GroupBox_Hardware_Associations, pos={13.00, 303.00}, size={463.00, 348.00}
	GroupBox GroupBox_Hardware_Associations, title="DAC Channel and Device Associations"
	GroupBox GroupBox_Hardware_Associations, userdata(tabnum)="6"
	GroupBox GroupBox_Hardware_Associations, userdata(tabcontrol)="ADC"
	GroupBox GroupBox_Hardware_Associations, userdata(ResizeControlsInfo)=A"!!,C$!!#BRJ,hsnJ,hs?z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	GroupBox GroupBox_Hardware_Associations, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	GroupBox GroupBox_Hardware_Associations, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	GroupBox group_Settings_DatAcq, pos={21.00, 186.00}, size={440.00, 257.00}, disable=1
	GroupBox group_Settings_DatAcq, title="Data Acquisition", userdata(tabnum)="5"
	GroupBox group_Settings_DatAcq, userdata(tabcontrol)="ADC"
	GroupBox group_Settings_DatAcq, userdata(ResizeControlsInfo)=A"!!,BY!!#A8!!#CCJ,hrfz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	GroupBox group_Settings_DatAcq, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	GroupBox group_Settings_DatAcq, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	GroupBox group_Settings_Asynch, pos={21.00, 445.00}, size={442.00, 90.00}, disable=1
	GroupBox group_Settings_Asynch, title="Asynchronous", userdata(tabnum)="5"
	GroupBox group_Settings_Asynch, userdata(tabcontrol)="ADC"
	GroupBox group_Settings_Asynch, userdata(ResizeControlsInfo)=A"!!,Ba!!#C<J,hsnJ,hpCz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	GroupBox group_Settings_Asynch, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	GroupBox group_Settings_Asynch, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	GroupBox group_Settings_TP, pos={21.00, 66.00}, size={441.00, 114.00}, disable=1
	GroupBox group_Settings_TP, title="Test Pulse", userdata(tabnum)="5"
	GroupBox group_Settings_TP, userdata(tabcontrol)="ADC"
	GroupBox group_Settings_TP, userdata(ResizeControlsInfo)=A"!!,Ba!!#?A!!#CCJ,hpCz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	GroupBox group_Settings_TP, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	GroupBox group_Settings_TP, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	GroupBox group_Settings_Asynch1, pos={22.00, 538.00}, size={443.00, 109.00}, disable=1
	GroupBox group_Settings_Asynch1, title="Oscilloscope", userdata(tabnum)="5"
	GroupBox group_Settings_Asynch1, userdata(tabcontrol)="ADC"
	GroupBox group_Settings_Asynch1, userdata(ResizeControlsInfo)=A"!!,Ba!!#Ci!!#CCJ,hnYz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	GroupBox group_Settings_Asynch1, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	GroupBox group_Settings_Asynch1, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	GroupBox group_DataAcq_ClampMode, pos={20.00, 39.00}, size={454.00, 461.00}, disable=1
	GroupBox group_DataAcq_ClampMode, title="Headstage", userdata(tabnum)="0"
	GroupBox group_DataAcq_ClampMode, userdata(tabcontrol)="ADC"
	GroupBox group_DataAcq_ClampMode, userdata(ResizeControlsInfo)=A"!!,C$!!#>*!!#CCJ,hs?z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	GroupBox group_DataAcq_ClampMode, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	GroupBox group_DataAcq_ClampMode, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	GroupBox group_DataAcq_ClampMode1, pos={25.00, 380.00}, size={444.00, 114.00}, disable=1
	GroupBox group_DataAcq_ClampMode1, title="Test Pulse", userdata(tabnum)="0"
	GroupBox group_DataAcq_ClampMode1, userdata(tabcontrol)="ADC"
	GroupBox group_DataAcq_ClampMode1, userdata(ResizeControlsInfo)=A"!!,C$!!#C*!!#CCJ,hpWz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	GroupBox group_DataAcq_ClampMode1, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	GroupBox group_DataAcq_ClampMode1, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	GroupBox group_DataAcq_ClampMode2, pos={20.00, 501.00}, size={454.00, 120.00}, disable=1
	GroupBox group_DataAcq_ClampMode2, title="Status Information"
	GroupBox group_DataAcq_ClampMode2, userdata(tabnum)="0"
	GroupBox group_DataAcq_ClampMode2, userdata(tabcontrol)="ADC"
	GroupBox group_DataAcq_ClampMode2, userdata(ResizeControlsInfo)=A"!!,C$!!#C^!!#CCJ,hq*z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	GroupBox group_DataAcq_ClampMode2, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	GroupBox group_DataAcq_ClampMode2, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	TitleBox title_DataAcq_NextSweep, pos={210.00, 516.00}, size={71.00, 19.00}, disable=1
	TitleBox title_DataAcq_NextSweep, title="Next Sweep", userdata(tabnum)="0"
	TitleBox title_DataAcq_NextSweep, userdata(tabcontrol)="ADC"
	TitleBox title_DataAcq_NextSweep, userdata(ResizeControlsInfo)=A"!!,Gc!!#Ce5QF-2!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox title_DataAcq_NextSweep, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	TitleBox title_DataAcq_NextSweep, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	TitleBox title_DataAcq_NextSweep, fSize=14, frame=0, fStyle=0
	TitleBox title_DataAcq_NextSweep1, pos={333.00, 543.00}, size={78.00, 19.00}, disable=1
	TitleBox title_DataAcq_NextSweep1, title="Total Sweeps", userdata(tabnum)="0"
	TitleBox title_DataAcq_NextSweep1, userdata(tabcontrol)="ADC"
	TitleBox title_DataAcq_NextSweep1, userdata(ResizeControlsInfo)=A"!!,HbJ,htB!!#?W!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox title_DataAcq_NextSweep1, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	TitleBox title_DataAcq_NextSweep1, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	TitleBox title_DataAcq_NextSweep1, fSize=14, frame=0, fStyle=0
	TitleBox title_DataAcq_NextSweep2, pos={333.00, 570.00}, size={98.00, 19.00}, disable=1
	TitleBox title_DataAcq_NextSweep2, title="Set Max Sweeps", userdata(tabnum)="0"
	TitleBox title_DataAcq_NextSweep2, userdata(tabcontrol)="ADC"
	TitleBox title_DataAcq_NextSweep2, userdata(ResizeControlsInfo)=A"!!,HbJ,htH^]6^>!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox title_DataAcq_NextSweep2, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	TitleBox title_DataAcq_NextSweep2, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	TitleBox title_DataAcq_NextSweep2, fSize=14, frame=0, fStyle=0
	TitleBox title_DataAcq_NextSweep3, pos={180.00, 594.00}, size={132.00, 19.00}, disable=1
	TitleBox title_DataAcq_NextSweep3, title="Sampling Interval (µs)"
	TitleBox title_DataAcq_NextSweep3, userdata(tabnum)="0"
	TitleBox title_DataAcq_NextSweep3, userdata(tabcontrol)="ADC"
	TitleBox title_DataAcq_NextSweep3, userdata(ResizeControlsInfo)=A"!!,GF!!#D$!!#@h!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox title_DataAcq_NextSweep3, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	TitleBox title_DataAcq_NextSweep3, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	TitleBox title_DataAcq_NextSweep3, fSize=14, frame=0, fStyle=0
	GroupBox group_DataAcq_DataAcq, pos={20.00, 621.00}, size={454.00, 228.00}, disable=1
	GroupBox group_DataAcq_DataAcq, title="Data Acquisition", userdata(tabnum)="0"
	GroupBox group_DataAcq_DataAcq, userdata(tabcontrol)="ADC"
	GroupBox group_DataAcq_DataAcq, userdata(ResizeControlsInfo)=A"!!,C$!!#D+J,hso!!#Asz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	GroupBox group_DataAcq_DataAcq, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	GroupBox group_DataAcq_DataAcq, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	TabControl tab_DataAcq_Amp, pos={30.00, 147.00}, size={423.00, 120.00}, disable=1, proc=ACL_DisplayTab
	TabControl tab_DataAcq_Amp, userdata(tabnum)="0", userdata(tabcontrol)="ADC"
	TabControl tab_DataAcq_Amp, userdata(currenttab)="0"
	TabControl tab_DataAcq_Amp, userdata(ResizeControlsInfo)=A"!!,Cd!!#A#!!#C9J,hq*z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TabControl tab_DataAcq_Amp, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	TabControl tab_DataAcq_Amp, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	TabControl tab_DataAcq_Amp, userdata(Config_DontRestore)="1"
	TabControl tab_DataAcq_Amp, userdata(Config_DontSave)="1"
	TabControl tab_DataAcq_Amp, labelBack=(60928, 60928, 60928), fSize=10
	TabControl tab_DataAcq_Amp, tabLabel(0)="V-Clamp", tabLabel(1)="\f01\Z11I-Clamp"
	TabControl tab_DataAcq_Amp, tabLabel(2)="I = 0", value=0
	TitleBox Title_DataAcq_Hold_IC, pos={87.00, 184.00}, size={64.00, 15.00}, disable=1
	TitleBox Title_DataAcq_Hold_IC, title="\\[0Holding \\Z10(pA)\\]0"
	TitleBox Title_DataAcq_Hold_IC, userdata(tabnum)="1"
	TitleBox Title_DataAcq_Hold_IC, userdata(tabcontrol)="tab_DataAcq_Amp"
	TitleBox Title_DataAcq_Hold_IC, userdata(ResizeControlsInfo)=A"!!,F'!!#AI!!#?C!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox Title_DataAcq_Hold_IC, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	TitleBox Title_DataAcq_Hold_IC, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	TitleBox Title_DataAcq_Hold_IC, frame=0
	TitleBox Title_DataAcq_Bridge, pos={49.00, 209.00}, size={104.00, 15.00}, disable=1
	TitleBox Title_DataAcq_Bridge, title="\\[0Bridge Balance \\Z10(MΩ)\\]0"
	TitleBox Title_DataAcq_Bridge, userdata(tabnum)="1"
	TitleBox Title_DataAcq_Bridge, userdata(tabcontrol)="tab_DataAcq_Amp"
	TitleBox Title_DataAcq_Bridge, userdata(ResizeControlsInfo)=A"!!,Do!!#A_!!#@>!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox Title_DataAcq_Bridge, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	TitleBox Title_DataAcq_Bridge, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	TitleBox Title_DataAcq_Bridge, frame=0
	SetVariable setvar_DataAcq_Hold_IC, pos={158.00, 183.00}, size={50.00, 18.00}, bodyWidth=50, disable=1, proc=DAP_SetVarProc_AmpCntrls
	SetVariable setvar_DataAcq_Hold_IC, userdata(tabnum)="1"
	SetVariable setvar_DataAcq_Hold_IC, userdata(tabcontrol)="tab_DataAcq_Amp"
	SetVariable setvar_DataAcq_Hold_IC, userdata(ResizeControlsInfo)=A"!!,G7!!#AH!!#>V!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_DataAcq_Hold_IC, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable setvar_DataAcq_Hold_IC, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable setvar_DataAcq_Hold_IC, userdata(Config_DontRestore)="1"
	SetVariable setvar_DataAcq_Hold_IC, userdata(Config_DontSave)="1", value=_NUM:0
	SetVariable setvar_DataAcq_BB, pos={158.00, 207.00}, size={50.00, 18.00}, bodyWidth=50, disable=1, proc=DAP_SetVarProc_AmpCntrls
	SetVariable setvar_DataAcq_BB, userdata(tabnum)="1"
	SetVariable setvar_DataAcq_BB, userdata(tabcontrol)="tab_DataAcq_Amp"
	SetVariable setvar_DataAcq_BB, userdata(ResizeControlsInfo)=A"!!,G7!!#A_!!#>V!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_DataAcq_BB, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable setvar_DataAcq_BB, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable setvar_DataAcq_BB, userdata(Config_DontRestore)="1"
	SetVariable setvar_DataAcq_BB, userdata(Config_DontSave)="1"
	SetVariable setvar_DataAcq_BB, limits={0, Inf, 1}, value=_NUM:0
	SetVariable setvar_DataAcq_CN, pos={158.00, 231.00}, size={50.00, 18.00}, bodyWidth=50, disable=1, proc=DAP_SetVarProc_AmpCntrls
	SetVariable setvar_DataAcq_CN, userdata(tabnum)="1"
	SetVariable setvar_DataAcq_CN, userdata(tabcontrol)="tab_DataAcq_Amp"
	SetVariable setvar_DataAcq_CN, userdata(ResizeControlsInfo)=A"!!,G7!!#B!!!#>V!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_DataAcq_CN, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable setvar_DataAcq_CN, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable setvar_DataAcq_CN, userdata(Config_DontRestore)="1"
	SetVariable setvar_DataAcq_CN, userdata(Config_DontSave)="1"
	SetVariable setvar_DataAcq_CN, limits={-8, 16, 1}, value=_NUM:0
	CheckBox check_DatAcq_HoldEnable, pos={217.00, 186.00}, size={14.00, 14.00}, disable=1, proc=DAP_CheckProc_AmpCntrls
	CheckBox check_DatAcq_HoldEnable, title="", userdata(tabnum)="1"
	CheckBox check_DatAcq_HoldEnable, userdata(tabcontrol)="tab_DataAcq_Amp"
	CheckBox check_DatAcq_HoldEnable, userdata(ResizeControlsInfo)=A"!!,Go!!#AJ!!#;]!!#;]z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_DatAcq_HoldEnable, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_DatAcq_HoldEnable, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox check_DatAcq_HoldEnable, userdata(Config_DontRestore)="1"
	CheckBox check_DatAcq_HoldEnable, userdata(Config_DontSave)="1", value=0
	CheckBox check_DatAcq_BBEnable, pos={217.00, 209.00}, size={14.00, 14.00}, disable=1, proc=DAP_CheckProc_AmpCntrls
	CheckBox check_DatAcq_BBEnable, title="", userdata(tabnum)="1"
	CheckBox check_DatAcq_BBEnable, userdata(tabcontrol)="tab_DataAcq_Amp"
	CheckBox check_DatAcq_BBEnable, userdata(ResizeControlsInfo)=A"!!,Go!!#Aa!!#;]!!#;]z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_DatAcq_BBEnable, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_DatAcq_BBEnable, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox check_DatAcq_BBEnable, userdata(Config_DontRestore)="1"
	CheckBox check_DatAcq_BBEnable, userdata(Config_DontSave)="1", value=0
	CheckBox check_DatAcq_CNEnable, pos={217.00, 231.00}, size={14.00, 14.00}, disable=1, proc=DAP_CheckProc_AmpCntrls
	CheckBox check_DatAcq_CNEnable, title="", userdata(tabnum)="1"
	CheckBox check_DatAcq_CNEnable, userdata(tabcontrol)="tab_DataAcq_Amp"
	CheckBox check_DatAcq_CNEnable, userdata(ResizeControlsInfo)=A"!!,Go!!#B#!!#;]!!#;]z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_DatAcq_CNEnable, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_DatAcq_CNEnable, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox check_DatAcq_CNEnable, userdata(Config_DontRestore)="1"
	CheckBox check_DatAcq_CNEnable, userdata(Config_DontSave)="1", value=0
	TitleBox Title_DataAcq_CN, pos={35.00, 233.00}, size={118.00, 15.00}, disable=1
	TitleBox Title_DataAcq_CN, title="\\[0Cap Neutralization \\Z10(pF)\\]0"
	TitleBox Title_DataAcq_CN, userdata(tabnum)="1"
	TitleBox Title_DataAcq_CN, userdata(tabcontrol)="tab_DataAcq_Amp"
	TitleBox Title_DataAcq_CN, userdata(ResizeControlsInfo)=A"!!,D?!!#B\"!!#@X!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox Title_DataAcq_CN, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	TitleBox Title_DataAcq_CN, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	TitleBox Title_DataAcq_CN, frame=0
	Slider slider_DataAcq_ActiveHeadstage, pos={128.00, 123.00}, size={255.00, 16.00}, disable=1, proc=DAP_SliderProc_MIESHeadStage
	Slider slider_DataAcq_ActiveHeadstage, userdata(tabnum)="0"
	Slider slider_DataAcq_ActiveHeadstage, userdata(tabcontrol)="ADC"
	Slider slider_DataAcq_ActiveHeadstage, userdata(Config_DontRestore)="1"
	Slider slider_DataAcq_ActiveHeadstage, userdata(Config_DontSave)="1"
	Slider slider_DataAcq_ActiveHeadstage, userdata(ResizeControlsInfo)=A"!!,Ff!!#@e!!#B9!!#<Xz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Slider slider_DataAcq_ActiveHeadstage, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	Slider slider_DataAcq_ActiveHeadstage, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	Slider slider_DataAcq_ActiveHeadstage, labelBack=(60928, 60928, 60928)
	Slider slider_DataAcq_ActiveHeadstage, limits={0, 7, 1}, value=0, live=0, side=2, vert=0, ticks=0
	SetVariable setvar_DataAcq_AutoBiasV, pos={278.00, 216.00}, size={96.00, 18.00}, bodyWidth=50, disable=1, proc=DAP_SetVarProc_AmpCntrls
	SetVariable setvar_DataAcq_AutoBiasV, title="\\[0Vm \\Z10(mV)\\]0"
	SetVariable setvar_DataAcq_AutoBiasV, userdata(tabnum)="1"
	SetVariable setvar_DataAcq_AutoBiasV, userdata(tabcontrol)="tab_DataAcq_Amp"
	SetVariable setvar_DataAcq_AutoBiasV, userdata(ResizeControlsInfo)=A"!!,HJJ,hr?!!#@.!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_DataAcq_AutoBiasV, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable setvar_DataAcq_AutoBiasV, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable setvar_DataAcq_AutoBiasV, userdata(Config_DontRestore)="1"
	SetVariable setvar_DataAcq_AutoBiasV, userdata(Config_DontSave)="1"
	SetVariable setvar_DataAcq_AutoBiasV, limits={-99, 99, 1}, value=_NUM:-70
	CheckBox check_DataAcq_AutoBias, pos={321.00, 198.00}, size={66.00, 15.00}, disable=1, proc=DAP_CheckProc_AmpCntrls
	CheckBox check_DataAcq_AutoBias, title="Auto Bias"
	CheckBox check_DataAcq_AutoBias, help={"Just prior to a sweep the Vm is checked and the bias current is adjusted to maintain desired Vm."}
	CheckBox check_DataAcq_AutoBias, userdata(tabnum)="1"
	CheckBox check_DataAcq_AutoBias, userdata(tabcontrol)="tab_DataAcq_Amp"
	CheckBox check_DataAcq_AutoBias, userdata(ResizeControlsInfo)=A"!!,H[J,hr+!!#?;!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_DataAcq_AutoBias, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_DataAcq_AutoBias, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox check_DataAcq_AutoBias, userdata(Config_DontRestore)="1"
	CheckBox check_DataAcq_AutoBias, userdata(Config_DontSave)="1", value=0, side=1
	SetVariable setvar_DataAcq_IbiasMax, pos={305.00, 236.00}, size={132.00, 20.00}, bodyWidth=50, disable=1, proc=DAP_SetVarProc_AmpCntrls
	SetVariable setvar_DataAcq_IbiasMax, title="\\[0max I \\Bbias\\M \\Z10(pA)\\]0 ±"
	SetVariable setvar_DataAcq_IbiasMax, userdata(tabcontrol)="tab_DataAcq_Amp"
	SetVariable setvar_DataAcq_IbiasMax, userdata(tabnum)="1"
	SetVariable setvar_DataAcq_IbiasMax, userdata(ResizeControlsInfo)=A"!!,HP!!#B+!!#@l!!#<Xz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_DataAcq_IbiasMax, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable setvar_DataAcq_IbiasMax, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable setvar_DataAcq_IbiasMax, userdata(Config_DontRestore)="1"
	SetVariable setvar_DataAcq_IbiasMax, userdata(Config_DontSave)="1"
	SetVariable setvar_DataAcq_IbiasMax, limits={1, 1500, 1}, value=_NUM:200
	SetVariable setvar_DataAcq_AutoBiasVrange, pos={375.00, 216.00}, size={62.00, 18.00}, bodyWidth=50, disable=1, proc=DAP_SetVarProc_AmpCntrls
	SetVariable setvar_DataAcq_AutoBiasVrange, title="±"
	SetVariable setvar_DataAcq_AutoBiasVrange, userdata(tabcontrol)="tab_DataAcq_Amp"
	SetVariable setvar_DataAcq_AutoBiasVrange, userdata(tabnum)="1"
	SetVariable setvar_DataAcq_AutoBiasVrange, userdata(ResizeControlsInfo)=A"!!,I*!!#Ai!!#?1!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_DataAcq_AutoBiasVrange, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable setvar_DataAcq_AutoBiasVrange, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable setvar_DataAcq_AutoBiasVrange, userdata(Config_DontRestore)="1"
	SetVariable setvar_DataAcq_AutoBiasVrange, userdata(Config_DontSave)="1"
	SetVariable setvar_DataAcq_AutoBiasVrange, limits={0, Inf, 1}, value=_NUM:0.5
	TitleBox Title_DataAcq_Hold_VC, pos={0.00, 207.00}, size={48.00, 18.00}, disable=1
	TitleBox Title_DataAcq_Hold_VC, userdata(tabnum)="0"
	TitleBox Title_DataAcq_Hold_VC, userdata(tabcontrol)="tab_DataAcq_Amp"
	TitleBox Title_DataAcq_Hold_VC, userdata(ResizeControlsInfo)=A"!!,<7!!#A`!!#>V!!#<Xz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox Title_DataAcq_Hold_VC, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	TitleBox Title_DataAcq_Hold_VC, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	TitleBox Title_DataAcq_Hold_VC, frame=0
	SetVariable setvar_DataAcq_Hold_VC, pos={35.00, 171.00}, size={93.00, 18.00}, bodyWidth=46, disable=1, proc=DAP_SetVarProc_AmpCntrls
	SetVariable setvar_DataAcq_Hold_VC, title="Holding", userdata(tabnum)="0"
	SetVariable setvar_DataAcq_Hold_VC, userdata(tabcontrol)="tab_DataAcq_Amp"
	SetVariable setvar_DataAcq_Hold_VC, userdata(ResizeControlsInfo)=A"!!,D7!!#A<!!#?s!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_DataAcq_Hold_VC, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable setvar_DataAcq_Hold_VC, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable setvar_DataAcq_Hold_VC, userdata(Config_DontRestore)="1"
	SetVariable setvar_DataAcq_Hold_VC, userdata(Config_DontSave)="1", value=_NUM:0
	TitleBox Title_DataAcq_PipOffset_VC, pos={243.00, 175.00}, size={96.00, 15.00}, disable=1
	TitleBox Title_DataAcq_PipOffset_VC, title="\\[0Pipette Offset \\Z10(mV)\\]0"
	TitleBox Title_DataAcq_PipOffset_VC, userdata(tabnum)="0"
	TitleBox Title_DataAcq_PipOffset_VC, userdata(tabcontrol)="tab_DataAcq_Amp"
	TitleBox Title_DataAcq_PipOffset_VC, userdata(ResizeControlsInfo)=A"!!,H0!!#A?!!#@.!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox Title_DataAcq_PipOffset_VC, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	TitleBox Title_DataAcq_PipOffset_VC, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	TitleBox Title_DataAcq_PipOffset_VC, frame=0
	SetVariable setvar_DataAcq_PipetteOffset_VC, pos={343.00, 175.00}, size={50.00, 18.00}, bodyWidth=50, disable=1, proc=DAP_SetVarProc_AmpCntrls
	SetVariable setvar_DataAcq_PipetteOffset_VC, userdata(tabnum)="0"
	SetVariable setvar_DataAcq_PipetteOffset_VC, userdata(tabcontrol)="tab_DataAcq_Amp"
	SetVariable setvar_DataAcq_PipetteOffset_VC, userdata(ResizeControlsInfo)=A"!!,Hi!!#A>!!#>V!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_DataAcq_PipetteOffset_VC, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable setvar_DataAcq_PipetteOffset_VC, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable setvar_DataAcq_PipetteOffset_VC, userdata(Config_DontRestore)="1"
	SetVariable setvar_DataAcq_PipetteOffset_VC, userdata(Config_DontSave)="1"
	SetVariable setvar_DataAcq_PipetteOffset_VC, value=_NUM:0
	Button button_DataAcq_AutoPipOffset_VC, pos={399.00, 175.00}, size={39.00, 18.00}, disable=1, proc=DAP_ButtonProc_AmpCntrls
	Button button_DataAcq_AutoPipOffset_VC, title="Auto"
	Button button_DataAcq_AutoPipOffset_VC, help={"Automatically calculate the pipette offset"}
	Button button_DataAcq_AutoPipOffset_VC, userdata(tabnum)="0"
	Button button_DataAcq_AutoPipOffset_VC, userdata(tabcontrol)="tab_DataAcq_Amp"
	Button button_DataAcq_AutoPipOffset_VC, userdata(ResizeControlsInfo)=A"!!,I.J,hqi!!#>.!!#<Xz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_DataAcq_AutoPipOffset_VC, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	Button button_DataAcq_AutoPipOffset_VC, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	Button button_DataAcq_AutoPipOffset_VC, userdata(Config_DontRestore)="1"
	Button button_DataAcq_AutoPipOffset_VC, userdata(Config_DontSave)="1"
	GroupBox group_pipette_offset_IC, pos={237.00, 168.00}, size={210.00, 27.00}, disable=1
	GroupBox group_pipette_offset_IC, userdata(tabnum)="1"
	GroupBox group_pipette_offset_IC, userdata(tabcontrol)="tab_DataAcq_Amp"
	GroupBox group_pipette_offset_IC, userdata(ResizeControlsInfo)=A"!!,H/!!#A:!!#Aa!!#=Cz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	GroupBox group_pipette_offset_IC, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	GroupBox group_pipette_offset_IC, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	GroupBox group_pipette_offset_IC, userdata(Config_DontRestore)="1"
	GroupBox group_pipette_offset_IC, userdata(Config_DontSave)="1"
	Button button_DataAcq_AutoPipOffset_IC, pos={399.00, 171.00}, size={39.00, 18.00}, disable=1, proc=DAP_ButtonProc_AmpCntrls
	Button button_DataAcq_AutoPipOffset_IC, title="Auto"
	Button button_DataAcq_AutoPipOffset_IC, help={"Automatically calculate the pipette offset"}
	Button button_DataAcq_AutoPipOffset_IC, userdata(tabnum)="1"
	Button button_DataAcq_AutoPipOffset_IC, userdata(tabcontrol)="tab_DataAcq_Amp"
	Button button_DataAcq_AutoPipOffset_IC, userdata(ResizeControlsInfo)=A"!!,I1J,hqi!!#>.!!#<Xz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_DataAcq_AutoPipOffset_IC, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	Button button_DataAcq_AutoPipOffset_IC, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	Button button_DataAcq_AutoPipOffset_IC, userdata(Config_DontRestore)="1"
	Button button_DataAcq_AutoPipOffset_IC, userdata(Config_DontSave)="1"
	TitleBox Title_DataAcq_PipOffset_IC, pos={241.00, 172.00}, size={96.00, 15.00}, disable=1
	TitleBox Title_DataAcq_PipOffset_IC, title="\\[0Pipette Offset \\Z10(mV)\\]0"
	TitleBox Title_DataAcq_PipOffset_IC, userdata(tabnum)="1"
	TitleBox Title_DataAcq_PipOffset_IC, userdata(tabcontrol)="tab_DataAcq_Amp"
	TitleBox Title_DataAcq_PipOffset_IC, userdata(ResizeControlsInfo)=A"!!,H6!!#A?!!#@.!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox Title_DataAcq_PipOffset_IC, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	TitleBox Title_DataAcq_PipOffset_IC, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	TitleBox Title_DataAcq_PipOffset_IC, frame=0
	SetVariable setvar_DataAcq_PipetteOffset_IC, pos={340.00, 171.00}, size={50.00, 18.00}, bodyWidth=50, disable=1, proc=DAP_SetVarProc_AmpCntrls
	SetVariable setvar_DataAcq_PipetteOffset_IC, userdata(tabnum)="1"
	SetVariable setvar_DataAcq_PipetteOffset_IC, userdata(tabcontrol)="tab_DataAcq_Amp"
	SetVariable setvar_DataAcq_PipetteOffset_IC, userdata(ResizeControlsInfo)=A"!!,Hl!!#A>!!#>V!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_DataAcq_PipetteOffset_IC, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable setvar_DataAcq_PipetteOffset_IC, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable setvar_DataAcq_PipetteOffset_IC, userdata(Config_DontRestore)="1"
	SetVariable setvar_DataAcq_PipetteOffset_IC, userdata(Config_DontSave)="1"
	SetVariable setvar_DataAcq_PipetteOffset_IC, value=_NUM:0
	CheckBox check_DatAcq_HoldEnableVC, pos={137.00, 172.00}, size={51.00, 15.00}, disable=1, proc=DAP_CheckProc_AmpCntrls
	CheckBox check_DatAcq_HoldEnableVC, title="Enable", userdata(tabnum)="0"
	CheckBox check_DatAcq_HoldEnableVC, userdata(tabcontrol)="tab_DataAcq_Amp"
	CheckBox check_DatAcq_HoldEnableVC, userdata(ResizeControlsInfo)=A"!!,Fs!!#A=!!#>V!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_DatAcq_HoldEnableVC, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_DatAcq_HoldEnableVC, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox check_DatAcq_HoldEnableVC, userdata(Config_DontRestore)="1"
	CheckBox check_DatAcq_HoldEnableVC, userdata(Config_DontSave)="1", value=0
	SetVariable setvar_DataAcq_WCR, pos={112.00, 219.00}, size={74.00, 18.00}, bodyWidth=50, disable=1, proc=DAP_SetVarProc_AmpCntrls
	SetVariable setvar_DataAcq_WCR, title="MΩ", userdata(tabnum)="0"
	SetVariable setvar_DataAcq_WCR, userdata(tabcontrol)="tab_DataAcq_Amp"
	SetVariable setvar_DataAcq_WCR, userdata(ResizeControlsInfo)=A"!!,FE!!#Aj!!#?M!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_DataAcq_WCR, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable setvar_DataAcq_WCR, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable setvar_DataAcq_WCR, userdata(Config_DontRestore)="1"
	SetVariable setvar_DataAcq_WCR, limits={1, Inf, 1}, userdata(Config_DontSave)="1", value=_NUM:1
	CheckBox check_DatAcq_WholeCellEnable, pos={63.00, 198.00}, size={14.00, 14.00}, disable=1, proc=DAP_CheckProc_AmpCntrls
	CheckBox check_DatAcq_WholeCellEnable, title="", userdata(tabnum)="0"
	CheckBox check_DatAcq_WholeCellEnable, userdata(tabcontrol)="tab_DataAcq_Amp"
	CheckBox check_DatAcq_WholeCellEnable, userdata(ResizeControlsInfo)=A"!!,E6!!#AV!!#;]!!#;]z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_DatAcq_WholeCellEnable, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_DatAcq_WholeCellEnable, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox check_DatAcq_WholeCellEnable, userdata(Config_DontRestore)="1"
	CheckBox check_DatAcq_WholeCellEnable, userdata(Config_DontSave)="1", value=0
	SetVariable setvar_DataAcq_WCC, pos={41.00, 219.00}, size={67.00, 18.00}, bodyWidth=50, disable=1, proc=DAP_SetVarProc_AmpCntrls
	SetVariable setvar_DataAcq_WCC, title="pF", userdata(tabnum)="0"
	SetVariable setvar_DataAcq_WCC, userdata(tabcontrol)="tab_DataAcq_Amp"
	SetVariable setvar_DataAcq_WCC, userdata(ResizeControlsInfo)=A"!!,D;!!#Ak!!#??!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_DataAcq_WCC, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable setvar_DataAcq_WCC, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable setvar_DataAcq_WCC, userdata(Config_DontRestore)="1"
	SetVariable setvar_DataAcq_WCC, userdata(Config_DontSave)="1"
	SetVariable setvar_DataAcq_WCC, limits={1, Inf, 1}, value=_NUM:1
	Button button_DataAcq_WCAuto, pos={108.00, 237.00}, size={39.00, 15.00}, disable=1, proc=DAP_ButtonProc_AmpCntrls
	Button button_DataAcq_WCAuto, title="Auto", userdata(tabnum)="0"
	Button button_DataAcq_WCAuto, userdata(tabcontrol)="tab_DataAcq_Amp"
	Button button_DataAcq_WCAuto, userdata(ResizeControlsInfo)=A"!!,F'!!#B)!!#>.!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_DataAcq_WCAuto, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	Button button_DataAcq_WCAuto, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	Button button_DataAcq_WCAuto, userdata(Config_DontRestore)="1"
	Button button_DataAcq_WCAuto, userdata(Config_DontSave)="1"
	GroupBox group_DataAcq_RsCompensation, pos={198.00, 198.00}, size={183.00, 60.00}, disable=1
	GroupBox group_DataAcq_RsCompensation, title="       Rs Compensation"
	GroupBox group_DataAcq_RsCompensation, userdata(tabnum)="0"
	GroupBox group_DataAcq_RsCompensation, userdata(tabcontrol)="tab_DataAcq_Amp"
	GroupBox group_DataAcq_RsCompensation, userdata(ResizeControlsInfo)=A"!!,GX!!#AW!!#AH!!#?1z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	GroupBox group_DataAcq_RsCompensation, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	GroupBox group_DataAcq_RsCompensation, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	GroupBox group_DataAcq_RsCompensation, userdata(Config_DontRestore)="1"
	GroupBox group_DataAcq_RsCompensation, userdata(Config_DontSave)="1"
	CheckBox check_DatAcq_RsCompEnable, pos={222.00, 198.00}, size={14.00, 14.00}, disable=1, proc=DAP_CheckProc_AmpCntrls
	CheckBox check_DatAcq_RsCompEnable, title="", userdata(tabnum)="0"
	CheckBox check_DatAcq_RsCompEnable, userdata(tabcontrol)="tab_DataAcq_Amp"
	CheckBox check_DatAcq_RsCompEnable, userdata(ResizeControlsInfo)=A"!!,Go!!#AV!!#;]!!#;]z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_DatAcq_RsCompEnable, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_DatAcq_RsCompEnable, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox check_DatAcq_RsCompEnable, userdata(Config_DontRestore)="1"
	CheckBox check_DatAcq_RsCompEnable, userdata(Config_DontSave)="1", value=0
	SetVariable setvar_DataAcq_RsCorr, pos={200.00, 216.00}, size={121.00, 18.00}, bodyWidth=40, disable=1, proc=DAP_SetVarProc_AmpCntrls
	SetVariable setvar_DataAcq_RsCorr, title="Correction (%)", userdata(tabnum)="0"
	SetVariable setvar_DataAcq_RsCorr, userdata(tabcontrol)="tab_DataAcq_Amp"
	SetVariable setvar_DataAcq_RsCorr, userdata(ResizeControlsInfo)=A"!!,G^!!#Ai!!#@V!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_DataAcq_RsCorr, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable setvar_DataAcq_RsCorr, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable setvar_DataAcq_RsCorr, userdata(Config_DontRestore)="1"
	SetVariable setvar_DataAcq_RsCorr, userdata(Config_DontSave)="1"
	SetVariable setvar_DataAcq_RsCorr, limits={0, 100, 1}, value=_NUM:0
	SetVariable setvar_DataAcq_RsPred, pos={202.00, 237.00}, size={119.00, 18.00}, bodyWidth=40, disable=1, proc=DAP_SetVarProc_AmpCntrls
	SetVariable setvar_DataAcq_RsPred, title="Prediction (%)", userdata(tabnum)="0"
	SetVariable setvar_DataAcq_RsPred, userdata(tabcontrol)="tab_DataAcq_Amp"
	SetVariable setvar_DataAcq_RsPred, userdata(ResizeControlsInfo)=A"!!,G`!!#B(!!#@R!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_DataAcq_RsPred, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable setvar_DataAcq_RsPred, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable setvar_DataAcq_RsPred, userdata(Config_DontRestore)="1"
	SetVariable setvar_DataAcq_RsPred, userdata(Config_DontSave)="1"
	SetVariable setvar_DataAcq_RsPred, limits={0, 100, 1}, value=_NUM:0
	Button button_DataAcq_FastComp_VC, pos={393.00, 213.00}, size={54.00, 18.00}, disable=1, proc=DAP_ButtonProc_AmpCntrls
	Button button_DataAcq_FastComp_VC, title="Cp Fast"
	Button button_DataAcq_FastComp_VC, help={"Activates MCC auto fast capacitance compensation"}
	Button button_DataAcq_FastComp_VC, userdata(tabnum)="0"
	Button button_DataAcq_FastComp_VC, userdata(tabcontrol)="tab_DataAcq_Amp"
	Button button_DataAcq_FastComp_VC, userdata(ResizeControlsInfo)=A"!!,I+!!#Ae!!#>j!!#<Xz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_DataAcq_FastComp_VC, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	Button button_DataAcq_FastComp_VC, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	Button button_DataAcq_FastComp_VC, userdata(Config_DontRestore)="1"
	Button button_DataAcq_FastComp_VC, userdata(Config_DontSave)="1"
	Button button_Hardware_AutoGainAndUnit, pos={428.00, 408.00}, size={39.00, 45.00}, proc=DAP_ButtonProc_AutoFillGain
	Button button_Hardware_AutoGainAndUnit, title="Auto\rFill"
	Button button_Hardware_AutoGainAndUnit, help={"Queries the MultiClamp Commander for the gains of all connected amplifiers of this device."}
	Button button_Hardware_AutoGainAndUnit, userdata(tabnum)="6"
	Button button_Hardware_AutoGainAndUnit, userdata(tabcontrol)="ADC"
	Button button_Hardware_AutoGainAndUnit, userdata(ResizeControlsInfo)=A"!!,I-J,hs\\J,hnY!!#>Jz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_Hardware_AutoGainAndUnit, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	Button button_Hardware_AutoGainAndUnit, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox Check_Settings_AlarmPauseAcq, pos={33.00, 475.00}, size={182.00, 15.00}, disable=1, proc=DAP_CheckProc_UpdateGuiState
	CheckBox Check_Settings_AlarmPauseAcq, title="\\JCPause acquisition in alarm state"
	CheckBox Check_Settings_AlarmPauseAcq, help={"Pauses acquisition until user continues or cancels acquisition"}
	CheckBox Check_Settings_AlarmPauseAcq, userdata(tabnum)="5"
	CheckBox Check_Settings_AlarmPauseAcq, userdata(tabcontrol)="ADC"
	CheckBox Check_Settings_AlarmPauseAcq, userdata(ResizeControlsInfo)=A"!!,Cl!!#CR!!#AD!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_Settings_AlarmPauseAcq, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox Check_Settings_AlarmPauseAcq, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox Check_Settings_AlarmPauseAcq, fColor=(65280, 43520, 0), value=0
	CheckBox Check_Settings_AlarmAutoRepeat, pos={33.00, 498.00}, size={275.00, 15.00}, disable=1, proc=DAP_CheckProc_UpdateGuiState
	CheckBox Check_Settings_AlarmAutoRepeat, title="Auto repeat last sweep until alarm state is cleared"
	CheckBox Check_Settings_AlarmAutoRepeat, help={"Repeat the last sweep if one of the asynchronous channels is in alarm state"}
	CheckBox Check_Settings_AlarmAutoRepeat, userdata(tabnum)="5"
	CheckBox Check_Settings_AlarmAutoRepeat, userdata(tabcontrol)="ADC"
	CheckBox Check_Settings_AlarmAutoRepeat, userdata(ResizeControlsInfo)=A"!!,Cl!!#C\\J,hrn!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_Settings_AlarmAutoRepeat, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox Check_Settings_AlarmAutoRepeat, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox Check_Settings_AlarmAutoRepeat, value=0
	GroupBox group_Settings_Amplifier, pos={21.00, 648.00}, size={444.00, 99.00}, disable=1
	GroupBox group_Settings_Amplifier, title="Amplifier", userdata(tabnum)="5"
	GroupBox group_Settings_Amplifier, userdata(tabcontrol)="ADC"
	GroupBox group_Settings_Amplifier, userdata(ResizeControlsInfo)=A"!!,Ba!!#CtJ,hsn!!#@,z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	GroupBox group_Settings_Amplifier, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	GroupBox group_Settings_Amplifier, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox check_Settings_AmpMCCdefault, pos={33.00, 666.00}, size={191.00, 15.00}, disable=1, proc=DAP_CheckProc_UpdateGuiState
	CheckBox check_Settings_AmpMCCdefault, title="Default to MCC parameter values"
	CheckBox check_Settings_AmpMCCdefault, help={"FIXME"}, userdata(tabnum)="5"
	CheckBox check_Settings_AmpMCCdefault, userdata(tabcontrol)="ADC"
	CheckBox check_Settings_AmpMCCdefault, userdata(ResizeControlsInfo)=A"!!,Cl!!#D%J,hr#!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_Settings_AmpMCCdefault, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_Settings_AmpMCCdefault, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox check_Settings_AmpMCCdefault, fColor=(65280, 43520, 0), value=0
	CheckBox check_Settings_SyncMiesToMCC, pos={33.00, 687.00}, size={153.00, 15.00}, disable=1, proc=DAP_CheckProc_SyncMiesToMCC
	CheckBox check_Settings_SyncMiesToMCC, title="Synchronize MIES to MCC"
	CheckBox check_Settings_SyncMiesToMCC, help={"Send the GUI values to the MCC on mode switch/headstage activation"}
	CheckBox check_Settings_SyncMiesToMCC, userdata(tabnum)="5"
	CheckBox check_Settings_SyncMiesToMCC, userdata(tabcontrol)="ADC"
	CheckBox check_Settings_SyncMiesToMCC, userdata(ResizeControlsInfo)=A"!!,Cl!!#D*^]6_=!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_Settings_SyncMiesToMCC, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_Settings_SyncMiesToMCC, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox check_Settings_SyncMiesToMCC, userdata(Config_RestorePriority)="25"
	CheckBox check_Settings_SyncMiesToMCC, value=0
	CheckBox check_DataAcq_Amp_Chain, pos={330.00, 228.00}, size={47.00, 15.00}, disable=1, proc=DAP_CheckProc_AmpCntrls
	CheckBox check_DataAcq_Amp_Chain, title="Chain", userdata(tabnum)="0"
	CheckBox check_DataAcq_Amp_Chain, userdata(tabcontrol)="tab_DataAcq_Amp"
	CheckBox check_DataAcq_Amp_Chain, userdata(ResizeControlsInfo)=A"!!,H`J,hrK!!#>F!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_DataAcq_Amp_Chain, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_DataAcq_Amp_Chain, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox check_DataAcq_Amp_Chain, userdata(Config_DontRestore)="1"
	CheckBox check_DataAcq_Amp_Chain, userdata(Config_DontSave)="1", value=0
	GroupBox group_Settings_MDSupport, pos={21.00, 24.00}, size={444.00, 39.00}, disable=1
	GroupBox group_Settings_MDSupport, title="Multiple Device Support"
	GroupBox group_Settings_MDSupport, help={"Support multiple independent devices"}
	GroupBox group_Settings_MDSupport, userdata(tabnum)="5"
	GroupBox group_Settings_MDSupport, userdata(tabcontrol)="ADC"
	GroupBox group_Settings_MDSupport, userdata(ResizeControlsInfo)=A"!!,Ba!!#=3!!#CCJ,hnYz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	GroupBox group_Settings_MDSupport, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	GroupBox group_Settings_MDSupport, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox check_Settings_MD, pos={33.00, 42.00}, size={51.00, 15.00}, disable=1, proc=DAP_CheckProc_MDEnable
	CheckBox check_Settings_MD, title="Enable", userdata(tabnum)="5"
	CheckBox check_Settings_MD, userdata(tabcontrol)="ADC"
	CheckBox check_Settings_MD, userdata(ResizeControlsInfo)=A"!!,Cl!!#>>!!#>V!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_Settings_MD, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_Settings_MD, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox check_Settings_MD, userdata(oldDisabledState)="2", value=1
	CheckBox Check_Settings_InsertTP, pos={127.00, 84.00}, size={62.00, 15.00}, disable=1, proc=DAP_CheckProc_InsertTP
	CheckBox Check_Settings_InsertTP, title="Insert TP"
	CheckBox Check_Settings_InsertTP, help={"Inserts a test pulse at the front of each sweep in a set."}
	CheckBox Check_Settings_InsertTP, userdata(tabnum)="5", userdata(tabcontrol)="ADC"
	CheckBox Check_Settings_InsertTP, userdata(ResizeControlsInfo)=A"!!,G<!!#?c!!#?-!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_Settings_InsertTP, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox Check_Settings_InsertTP, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox Check_Settings_InsertTP, value=1
	CheckBox Check_DataAcq_Get_Set_ITI, pos={141.00, 705.00}, size={47.00, 30.00}, disable=1, proc=DAP_CheckProc_UpdateGuiState
	CheckBox Check_DataAcq_Get_Set_ITI, title="Get\rset ITI"
	CheckBox Check_DataAcq_Get_Set_ITI, help={"When checked the stimulus set ITIs are used. The ITI is calculated as the maximum of all active stimulus set ITIs."}
	CheckBox Check_DataAcq_Get_Set_ITI, userdata(tabnum)="0"
	CheckBox Check_DataAcq_Get_Set_ITI, userdata(tabcontrol)="ADC"
	CheckBox Check_DataAcq_Get_Set_ITI, userdata(ResizeControlsInfo)=A"!!,Fu!!#D=J,hnq!!#=Sz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_DataAcq_Get_Set_ITI, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox Check_DataAcq_Get_Set_ITI, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox Check_DataAcq_Get_Set_ITI, value=1
	SetVariable setvar_Settings_TPBuffer, pos={334.00, 108.00}, size={124.00, 18.00}, bodyWidth=50, disable=1, proc=DAP_SetVarProc_TestPulseSett
	SetVariable setvar_Settings_TPBuffer, title="TP Buffer size", userdata(tabnum)="5"
	SetVariable setvar_Settings_TPBuffer, userdata(tabcontrol)="ADC"
	SetVariable setvar_Settings_TPBuffer, userdata(ResizeControlsInfo)=A"!!,H]J,hpi!!#@^!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_Settings_TPBuffer, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable setvar_Settings_TPBuffer, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable setvar_Settings_TPBuffer, limits={1, Inf, 1}, value=_NUM:1
	CheckBox check_Settings_SaveAmpSettings, pos={324.00, 672.00}, size={114.00, 15.00}, disable=1, proc=DAP_CheckProc_UpdateGuiState
	CheckBox check_Settings_SaveAmpSettings, title="Save Amp Settings"
	CheckBox check_Settings_SaveAmpSettings, help={"Adds amplifier settings to lab note book for Multiclamp 700Bs ONLY!"}
	CheckBox check_Settings_SaveAmpSettings, userdata(tabnum)="5"
	CheckBox check_Settings_SaveAmpSettings, userdata(tabcontrol)="ADC"
	CheckBox check_Settings_SaveAmpSettings, userdata(ResizeControlsInfo)=A"!!,H^!!#D%5QF.1!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_Settings_SaveAmpSettings, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_Settings_SaveAmpSettings, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox check_Settings_SaveAmpSettings, value=1
	SetVariable setvar_Settings_TP_RTolerance, pos={313.00, 84.00}, size={145.00, 18.00}, bodyWidth=50, disable=1, proc=DAP_SetVarProc_TestPulseSett
	SetVariable setvar_Settings_TP_RTolerance, title="Min delta R (MΩ)"
	SetVariable setvar_Settings_TP_RTolerance, help={"Sets the minimum delta required for TP resistance values to be appended as a wave note to the data sweep. TP resistance values are always documented in the Lab Note Book."}
	SetVariable setvar_Settings_TP_RTolerance, userdata(tabnum)="5"
	SetVariable setvar_Settings_TP_RTolerance, userdata(tabcontrol)="ADC"
	SetVariable setvar_Settings_TP_RTolerance, userdata(ResizeControlsInfo)=A"!!,HSJ,hp7!!#@u!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_Settings_TP_RTolerance, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable setvar_Settings_TP_RTolerance, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable setvar_Settings_TP_RTolerance, limits={1, Inf, 1}, value=_NUM:1
	Button button_DataAcq_AutoBridgeBal_IC, pos={234.00, 209.00}, size={39.00, 15.00}, disable=1, proc=DAP_ButtonProc_AmpCntrls
	Button button_DataAcq_AutoBridgeBal_IC, title="Auto"
	Button button_DataAcq_AutoBridgeBal_IC, help={"Automatically calculate the bridge balance"}
	Button button_DataAcq_AutoBridgeBal_IC, userdata(tabnum)="1"
	Button button_DataAcq_AutoBridgeBal_IC, userdata(tabcontrol)="tab_DataAcq_Amp"
	Button button_DataAcq_AutoBridgeBal_IC, userdata(ResizeControlsInfo)=A"!!,H+!!#A`!!#>.!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_DataAcq_AutoBridgeBal_IC, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	Button button_DataAcq_AutoBridgeBal_IC, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	Button button_DataAcq_AutoBridgeBal_IC, userdata(Config_DontRestore)="1"
	Button button_DataAcq_AutoBridgeBal_IC, userdata(Config_DontSave)="1"
	CheckBox Check_DataAcq_SendToAllAmp, pos={339.00, 147.00}, size={105.00, 15.00}, disable=1, proc=DAP_CheckProc_UpdateGuiState
	CheckBox Check_DataAcq_SendToAllAmp, title="Send to all Amps"
	CheckBox Check_DataAcq_SendToAllAmp, userdata(tabnum)="0"
	CheckBox Check_DataAcq_SendToAllAmp, userdata(tabcontrol)="ADC"
	CheckBox Check_DataAcq_SendToAllAmp, userdata(ResizeControlsInfo)=A"!!,HdJ,hqM!!#@4!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_DataAcq_SendToAllAmp, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox Check_DataAcq_SendToAllAmp, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox Check_DataAcq_SendToAllAmp, value=0
	Button button_DataAcq_Seal, pos={147.00, 297.00}, size={84.00, 27.00}, disable=3, proc=ButtonProc_Seal
	Button button_DataAcq_Seal, title="Seal"
	Button button_DataAcq_Seal, help={"Sets the I-clamp holding current based on the V-clamp holding potential"}
	Button button_DataAcq_Seal, userdata(tabnum)="0"
	Button button_DataAcq_Seal, userdata(tabcontrol)="tab_DataAcq_Pressure"
	Button button_DataAcq_Seal, userdata(ResizeControlsInfo)=A"!!,G#!!#BOJ,hp7!!#=;z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_DataAcq_Seal, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	Button button_DataAcq_Seal, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	Button button_DataAcq_BreakIn, pos={255.00, 297.00}, size={84.00, 27.00}, disable=3, proc=ButtonProc_BreakIn
	Button button_DataAcq_BreakIn, title="Break In"
	Button button_DataAcq_BreakIn, help={"Sets the I-clamp holding current based on the V-clamp holding potential"}
	Button button_DataAcq_BreakIn, userdata(tabnum)="0"
	Button button_DataAcq_BreakIn, userdata(tabcontrol)="tab_DataAcq_Pressure"
	Button button_DataAcq_BreakIn, userdata(ResizeControlsInfo)=A"!!,H;J,hs%J,hp7!!#=;z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_DataAcq_BreakIn, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	Button button_DataAcq_BreakIn, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	Button button_DataAcq_Clear, pos={366.00, 297.00}, size={84.00, 27.00}, disable=3, proc=ButtonProc_Clear
	Button button_DataAcq_Clear, title="Clear"
	Button button_DataAcq_Clear, help={"Attempts to clear the pipette tip to improve access resistance"}
	Button button_DataAcq_Clear, userdata(tabnum)="0"
	Button button_DataAcq_Clear, userdata(tabcontrol)="tab_DataAcq_Pressure"
	Button button_DataAcq_Clear, userdata(ResizeControlsInfo)=A"!!,HrJ,hs%J,hp7!!#=;z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_DataAcq_Clear, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	Button button_DataAcq_Clear, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox check_DatAcq_ClearEnable, pos={369.00, 327.00}, size={51.00, 15.00}, disable=3, proc=CheckProc_ClearEnable
	CheckBox check_DatAcq_ClearEnable, title="Enable", userdata(tabnum)="0"
	CheckBox check_DatAcq_ClearEnable, userdata(tabcontrol)="tab_DataAcq_Pressure"
	CheckBox check_DatAcq_ClearEnable, userdata(ResizeControlsInfo)=A"!!,Ht!!#B^J,ho,!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_DatAcq_ClearEnable, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_DatAcq_ClearEnable, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox check_DatAcq_ClearEnable, value=0
	CheckBox check_DatAcq_SealALl, pos={150.00, 327.00}, size={30.00, 15.00}, disable=3, proc=DAP_CheckProc_UpdateGuiState
	CheckBox check_DatAcq_SealALl, title="All"
	CheckBox check_DatAcq_SealALl, help={"Seals all headstates with active test pulse"}
	CheckBox check_DatAcq_SealALl, userdata(tabnum)="0"
	CheckBox check_DatAcq_SealALl, userdata(tabcontrol)="tab_DataAcq_Pressure"
	CheckBox check_DatAcq_SealALl, userdata(ResizeControlsInfo)=A"!!,G&!!#B^J,hn!!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_DatAcq_SealALl, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_DatAcq_SealALl, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox check_DatAcq_SealALl, value=0
	CheckBox check_DatAcq_BreakInAll, pos={258.00, 327.00}, size={30.00, 15.00}, disable=3, proc=DAP_CheckProc_UpdateGuiState
	CheckBox check_DatAcq_BreakInAll, title="All"
	CheckBox check_DatAcq_BreakInAll, help={"Break in to all headstates with active test pulse"}
	CheckBox check_DatAcq_BreakInAll, userdata(tabnum)="0"
	CheckBox check_DatAcq_BreakInAll, userdata(tabcontrol)="tab_DataAcq_Pressure"
	CheckBox check_DatAcq_BreakInAll, userdata(ResizeControlsInfo)=A"!!,H=!!#B^J,hn!!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_DatAcq_BreakInAll, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_DatAcq_BreakInAll, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox check_DatAcq_BreakInAll, value=0
	Button button_DataAcq_Approach, pos={36.00, 297.00}, size={84.00, 27.00}, disable=3, proc=ButtonProc_Approach
	Button button_DataAcq_Approach, title="Approach"
	Button button_DataAcq_Approach, help={"Applies positive pressure to the pipette"}
	Button button_DataAcq_Approach, userdata(tabnum)="0"
	Button button_DataAcq_Approach, userdata(tabcontrol)="tab_DataAcq_Pressure"
	Button button_DataAcq_Approach, userdata(ResizeControlsInfo)=A"!!,D#!!#BOJ,hp7!!#=;z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_DataAcq_Approach, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	Button button_DataAcq_Approach, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox check_DatAcq_ApproachAll, pos={39.00, 327.00}, size={30.00, 15.00}, disable=3, proc=DAP_CheckProc_UpdateGuiState
	CheckBox check_DatAcq_ApproachAll, title="All"
	CheckBox check_DatAcq_ApproachAll, help={"Apply postive pressure to all headstages"}
	CheckBox check_DatAcq_ApproachAll, userdata(tabnum)="0"
	CheckBox check_DatAcq_ApproachAll, userdata(tabcontrol)="tab_DataAcq_Pressure"
	CheckBox check_DatAcq_ApproachAll, userdata(ResizeControlsInfo)=A"!!,D3!!#B^J,hn!!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_DatAcq_ApproachAll, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_DatAcq_ApproachAll, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox check_DatAcq_ApproachAll, value=0
	PopupMenu popup_Settings_Pressure_dev, pos={35.00, 495.00}, size={219.00, 19.00}, bodyWidth=150, proc=DAP_PopMenuProc_CAA
	PopupMenu popup_Settings_Pressure_dev, title="DAC devices"
	PopupMenu popup_Settings_Pressure_dev, help={"List of available DAC devices for pressure control"}
	PopupMenu popup_Settings_Pressure_dev, userdata(tabnum)="6"
	PopupMenu popup_Settings_Pressure_dev, userdata(tabcontrol)="ADC"
	PopupMenu popup_Settings_Pressure_dev, userdata(ResizeControlsInfo)=A"!!,DC!!#C\\J,hr@!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu popup_Settings_Pressure_dev, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	PopupMenu popup_Settings_Pressure_dev, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	PopupMenu popup_Settings_Pressure_dev, userdata(Config_DontRestore)="1"
	PopupMenu popup_Settings_Pressure_dev, userdata(Config_DontSave)="1"
	PopupMenu popup_Settings_Pressure_dev, mode=1, popvalue="- none -", value=#"\"- none -\""
	TitleBox Title_settings_Hardware_Pressur, pos={45.00, 474.00}, size={44.00, 15.00}
	TitleBox Title_settings_Hardware_Pressur, title="Pressure", userdata(tabnum)="6"
	TitleBox Title_settings_Hardware_Pressur, userdata(tabcontrol)="ADC"
	TitleBox Title_settings_Hardware_Pressur, userdata(ResizeControlsInfo)=A"!!,DC!!#CRJ,hni!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox Title_settings_Hardware_Pressur, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	TitleBox Title_settings_Hardware_Pressur, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	TitleBox Title_settings_Hardware_Pressur, frame=0
	PopupMenu Popup_Settings_Pressure_DA, pos={48.00, 528.00}, size={47.00, 19.00}, proc=DAP_PopMenuProc_CAA
	PopupMenu Popup_Settings_Pressure_DA, title="DA", userdata(tabnum)="6"
	PopupMenu Popup_Settings_Pressure_DA, userdata(tabcontrol)="ADC"
	PopupMenu Popup_Settings_Pressure_DA, userdata(ResizeControlsInfo)=A"!!,D[!!#Ch!!#>J!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Popup_Settings_Pressure_DA, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	PopupMenu Popup_Settings_Pressure_DA, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	PopupMenu Popup_Settings_Pressure_DA, userdata(Config_DontRestore)="1"
	PopupMenu Popup_Settings_Pressure_DA, userdata(Config_DontSave)="1"
	PopupMenu Popup_Settings_Pressure_DA, mode=1, popvalue="0", value=#"\"0;1;2;3;4;5;6;7\""
	PopupMenu Popup_Settings_Pressure_AD, pos={48.00, 555.00}, size={47.00, 19.00}, proc=DAP_PopMenuProc_CAA
	PopupMenu Popup_Settings_Pressure_AD, title="AD", userdata(tabnum)="6"
	PopupMenu Popup_Settings_Pressure_AD, userdata(tabcontrol)="ADC"
	PopupMenu Popup_Settings_Pressure_AD, userdata(ResizeControlsInfo)=A"!!,D[!!#Cn5QF,5!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Popup_Settings_Pressure_AD, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	PopupMenu Popup_Settings_Pressure_AD, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	PopupMenu Popup_Settings_Pressure_AD, userdata(Config_DontRestore)="1"
	PopupMenu Popup_Settings_Pressure_AD, userdata(Config_DontSave)="1"
	PopupMenu Popup_Settings_Pressure_AD, mode=1, popvalue="0", value=#"\"0;1;2;3;4;5;6;7;8;9;10;11;12;13;14;15\""
	SetVariable setvar_Settings_Pressure_DAgain, pos={111.00, 528.00}, size={48.00, 18.00}, proc=DAP_SetVarProc_CAA
	SetVariable setvar_Settings_Pressure_DAgain, userdata(tabnum)="6"
	SetVariable setvar_Settings_Pressure_DAgain, userdata(tabcontrol)="ADC"
	SetVariable setvar_Settings_Pressure_DAgain, userdata(ResizeControlsInfo)=A"!!,FE!!#ChJ,ho,!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_Settings_Pressure_DAgain, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable setvar_Settings_Pressure_DAgain, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable setvar_Settings_Pressure_DAgain, value=_NUM:2
	SetVariable setvar_Settings_Pressure_ADgain, pos={111.00, 555.00}, size={48.00, 18.00}, proc=DAP_SetVarProc_CAA
	SetVariable setvar_Settings_Pressure_ADgain, userdata(tabnum)="6"
	SetVariable setvar_Settings_Pressure_ADgain, userdata(tabcontrol)="ADC"
	SetVariable setvar_Settings_Pressure_ADgain, userdata(ResizeControlsInfo)=A"!!,FE!!#Cn^]6\\l!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_Settings_Pressure_ADgain, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable setvar_Settings_Pressure_ADgain, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable setvar_Settings_Pressure_ADgain, value=_NUM:0.5
	SetVariable SetVar_Hardware_Pressur_DA_Unit, pos={168.00, 528.00}, size={30.00, 18.00}, proc=DAP_SetVarProc_CAA
	SetVariable SetVar_Hardware_Pressur_DA_Unit, userdata(tabnum)="6"
	SetVariable SetVar_Hardware_Pressur_DA_Unit, userdata(tabcontrol)="ADC"
	SetVariable SetVar_Hardware_Pressur_DA_Unit, userdata(ResizeControlsInfo)=A"!!,G:!!#ChJ,hn)!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_Hardware_Pressur_DA_Unit, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable SetVar_Hardware_Pressur_DA_Unit, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable SetVar_Hardware_Pressur_DA_Unit, value=_STR:"psi"
	SetVariable SetVar_Hardware_Pressur_AD_Unit, pos={189.00, 555.00}, size={30.00, 18.00}, proc=DAP_SetVarProc_CAA
	SetVariable SetVar_Hardware_Pressur_AD_Unit, userdata(tabnum)="6"
	SetVariable SetVar_Hardware_Pressur_AD_Unit, userdata(tabcontrol)="ADC"
	SetVariable SetVar_Hardware_Pressur_AD_Unit, userdata(ResizeControlsInfo)=A"!!,GO!!#Cn^]6[i!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_Hardware_Pressur_AD_Unit, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable SetVar_Hardware_Pressur_AD_Unit, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable SetVar_Hardware_Pressur_AD_Unit, value=_STR:"psi"
	TitleBox Title_Hardware_Pressure_DA_Div, pos={201.00, 528.00}, size={15.00, 15.00}
	TitleBox Title_Hardware_Pressure_DA_Div, title="/ V", userdata(tabnum)="6"
	TitleBox Title_Hardware_Pressure_DA_Div, userdata(tabcontrol)="ADC"
	TitleBox Title_Hardware_Pressure_DA_Div, userdata(ResizeControlsInfo)=A"!!,G\\!!#Ci!!#<(!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox Title_Hardware_Pressure_DA_Div, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	TitleBox Title_Hardware_Pressure_DA_Div, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	TitleBox Title_Hardware_Pressure_DA_Div, frame=0
	TitleBox Title_Hardware_Pressure_AD_Div, pos={171.00, 555.00}, size={15.00, 15.00}
	TitleBox Title_Hardware_Pressure_AD_Div, title="V /", userdata(tabnum)="6"
	TitleBox Title_Hardware_Pressure_AD_Div, userdata(tabcontrol)="ADC"
	TitleBox Title_Hardware_Pressure_AD_Div, userdata(ResizeControlsInfo)=A"!!,G<!!#Co5QF)h!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox Title_Hardware_Pressure_AD_Div, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	TitleBox Title_Hardware_Pressure_AD_Div, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	TitleBox Title_Hardware_Pressure_AD_Div, frame=0
	PopupMenu Popup_Settings_Pressure_TTLA, pos={218.00, 528.00}, size={104.00, 19.00}, bodyWidth=70, proc=DAP_PopMenuProc_CAA
	PopupMenu Popup_Settings_Pressure_TTLA, title="TTL A"
	PopupMenu Popup_Settings_Pressure_TTLA, help={"Select TTL channel for solenoid command"}
	PopupMenu Popup_Settings_Pressure_TTLA, userdata(tabnum)="6"
	PopupMenu Popup_Settings_Pressure_TTLA, userdata(tabcontrol)="ADC"
	PopupMenu Popup_Settings_Pressure_TTLA, userdata(ResizeControlsInfo)=A"!!,H#!!#Cg^]6^J!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Popup_Settings_Pressure_TTLA, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	PopupMenu Popup_Settings_Pressure_TTLA, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	PopupMenu Popup_Settings_Pressure_TTLA, userdata(Config_DontRestore)="1"
	PopupMenu Popup_Settings_Pressure_TTLA, userdata(Config_DontSave)="1"
	PopupMenu Popup_Settings_Pressure_TTLA, mode=2, popvalue="0", value=#"\"- none -;0;1;2;3;4;5;6;7\""
	GroupBox group_Settings_Pressure, pos={21.00, 750.00}, size={444.00, 99.00}, disable=1
	GroupBox group_Settings_Pressure, title="Pressure", userdata(tabnum)="5"
	GroupBox group_Settings_Pressure, userdata(tabcontrol)="ADC"
	GroupBox group_Settings_Pressure, userdata(ResizeControlsInfo)=A"!!,Bq!!#D95QF1.J,hq<z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	GroupBox group_Settings_Pressure, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	GroupBox group_Settings_Pressure, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable setvar_Settings_InAirP, pos={46.00, 771.00}, size={116.00, 18.00}, bodyWidth=50, disable=1, proc=DAP_SetVarProc_CAA
	SetVariable setvar_Settings_InAirP, title="In air P (psi)"
	SetVariable setvar_Settings_InAirP, help={"Set the (positive) pressure applied to the pipette when the pipette is out of the bath."}
	SetVariable setvar_Settings_InAirP, userdata(tabnum)="5"
	SetVariable setvar_Settings_InAirP, userdata(tabcontrol)="ADC"
	SetVariable setvar_Settings_InAirP, userdata(ResizeControlsInfo)=A"!!,DO!!#D>5QF.7!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_Settings_InAirP, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable setvar_Settings_InAirP, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable setvar_Settings_InAirP, limits={-10, 10, 0.1}, value=_NUM:3.8
	SetVariable setvar_Settings_InBathP, pos={186.00, 771.00}, size={127.00, 18.00}, bodyWidth=50, disable=1, proc=DAP_SetVarProc_CAA
	SetVariable setvar_Settings_InBathP, title="In bath P (psi)"
	SetVariable setvar_Settings_InBathP, help={"Set the (positive) pressure applied to the pipette when the pipette is in the bath."}
	SetVariable setvar_Settings_InBathP, userdata(tabnum)="5"
	SetVariable setvar_Settings_InBathP, userdata(tabcontrol)="ADC"
	SetVariable setvar_Settings_InBathP, userdata(ResizeControlsInfo)=A"!!,G<!!#D>J,hq8!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_Settings_InBathP, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable setvar_Settings_InBathP, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable setvar_Settings_InBathP, limits={-10, 10, 0.1}, value=_NUM:0.55
	SetVariable setvar_Settings_InSliceP, pos={330.00, 771.00}, size={126.00, 18.00}, bodyWidth=50, disable=1, proc=DAP_SetVarProc_CAA
	SetVariable setvar_Settings_InSliceP, title="In slice P (psi)"
	SetVariable setvar_Settings_InSliceP, help={"Set the (positive) pressure applied to the pipette when the pipette is in the tissue specimen."}
	SetVariable setvar_Settings_InSliceP, userdata(tabnum)="5"
	SetVariable setvar_Settings_InSliceP, userdata(tabcontrol)="ADC"
	SetVariable setvar_Settings_InSliceP, userdata(ResizeControlsInfo)=A"!!,H^!!#D>J,hq6!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_Settings_InSliceP, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable setvar_Settings_InSliceP, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable setvar_Settings_InSliceP, limits={-10, 10, 0.1}, value=_NUM:0.2
	SetVariable setvar_Settings_NearCellP, pos={26.00, 798.00}, size={136.00, 18.00}, bodyWidth=50, disable=1, proc=DAP_SetVarProc_CAA
	SetVariable setvar_Settings_NearCellP, title="Near cell P (psi)"
	SetVariable setvar_Settings_NearCellP, help={"Set the (positive) pressure applied to the pipette when the pipette is close to the target neuron."}
	SetVariable setvar_Settings_NearCellP, userdata(tabnum)="5"
	SetVariable setvar_Settings_NearCellP, userdata(tabcontrol)="ADC"
	SetVariable setvar_Settings_NearCellP, userdata(ResizeControlsInfo)=A"!!,CD!!#DE!!#@l!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_Settings_NearCellP, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable setvar_Settings_NearCellP, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable setvar_Settings_NearCellP, limits={-1, 1, 0.1}, value=_NUM:0.6
	SetVariable setvar_Settings_SealStartP, pos={182.00, 798.00}, size={131.00, 18.00}, bodyWidth=50, disable=1, proc=DAP_SetVarProc_CAA
	SetVariable setvar_Settings_SealStartP, title="Seal Init P (psi)"
	SetVariable setvar_Settings_SealStartP, help={"Set the starting negative pressure used to form a seal."}
	SetVariable setvar_Settings_SealStartP, userdata(tabnum)="5"
	SetVariable setvar_Settings_SealStartP, userdata(tabcontrol)="ADC"
	SetVariable setvar_Settings_SealStartP, userdata(ResizeControlsInfo)=A"!!,G8!!#DE5QF.R!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_Settings_SealStartP, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable setvar_Settings_SealStartP, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable setvar_Settings_SealStartP, limits={-10, 0, 0.1}, value=_NUM:-0.2
	SetVariable setvar_Settings_SealMaxP, pos={319.00, 798.00}, size={137.00, 18.00}, bodyWidth=50, disable=1, proc=DAP_SetVarProc_CAA
	SetVariable setvar_Settings_SealMaxP, title="Seal max P (psi)"
	SetVariable setvar_Settings_SealMaxP, help={"Set the maximum negative pressure used to form a seal."}
	SetVariable setvar_Settings_SealMaxP, userdata(tabnum)="5"
	SetVariable setvar_Settings_SealMaxP, userdata(tabcontrol)="ADC"
	SetVariable setvar_Settings_SealMaxP, userdata(ResizeControlsInfo)=A"!!,HY!!#DE5QF.W!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_Settings_SealMaxP, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable setvar_Settings_SealMaxP, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable setvar_Settings_SealMaxP, limits={-10, 0, 0.1}, value=_NUM:-1.4
	SetVariable setvar_Settings_SurfaceHeight, pos={26.00, 825.00}, size={136.00, 18.00}, bodyWidth=50, disable=1, proc=DAP_SetVarProc_CAA
	SetVariable setvar_Settings_SurfaceHeight, title="Sol surface\\Z11 (µm)"
	SetVariable setvar_Settings_SurfaceHeight, help={"Distance from the bottom of the recording chamber to the surface of the recording chamber solution."}
	SetVariable setvar_Settings_SurfaceHeight, userdata(tabnum)="5"
	SetVariable setvar_Settings_SurfaceHeight, userdata(tabcontrol)="ADC"
	SetVariable setvar_Settings_SurfaceHeight, userdata(ResizeControlsInfo)=A"!!,CD!!#DK^]6_-!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_Settings_SurfaceHeight, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable setvar_Settings_SurfaceHeight, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable setvar_Settings_SurfaceHeight, limits={0, Inf, 100}, value=_NUM:3500
	SetVariable setvar_Settings_SliceSurfHeight, pos={169.00, 825.00}, size={144.00, 18.00}, bodyWidth=50, disable=1, proc=DAP_SetVarProc_CAA
	SetVariable setvar_Settings_SliceSurfHeight, title="Slice surface\\Z11 (µm)"
	SetVariable setvar_Settings_SliceSurfHeight, help={"Distance from the bottom of the recording chamber to the top surface of the slice."}
	SetVariable setvar_Settings_SliceSurfHeight, userdata(tabnum)="5"
	SetVariable setvar_Settings_SliceSurfHeight, userdata(tabcontrol)="ADC"
	SetVariable setvar_Settings_SliceSurfHeight, userdata(ResizeControlsInfo)=A"!!,G8!!#DK^]6_5!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_Settings_SliceSurfHeight, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable setvar_Settings_SliceSurfHeight, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable setvar_Settings_SliceSurfHeight, limits={0, Inf, 100}, value=_NUM:350
	Button button_Settings_UpdateDACList, pos={270.00, 492.00}, size={189.00, 21.00}, proc=ButtonProc_Hrdwr_P_UpdtDAClist
	Button button_Settings_UpdateDACList, title="Query connected DAC(s)"
	Button button_Settings_UpdateDACList, help={"Updates the popup menu contents to show the available ITC devices"}
	Button button_Settings_UpdateDACList, userdata(tabnum)="6"
	Button button_Settings_UpdateDACList, userdata(tabcontrol)="ADC"
	Button button_Settings_UpdateDACList, userdata(ResizeControlsInfo)=A"!!,HBJ,ht2!!#AN!!#<hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_Settings_UpdateDACList, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	Button button_Settings_UpdateDACList, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	Button button_Settings_UpdateDACList, userdata(Config_RestorePriority)="25"
	Button button_Hardware_P_Enable, pos={336.00, 528.00}, size={60.00, 45.00}, proc=P_ButtonProc_Enable
	Button button_Hardware_P_Enable, title="Enable"
	Button button_Hardware_P_Enable, help={"Enable DAQ devices used for pressure regulation."}
	Button button_Hardware_P_Enable, userdata(tabnum)="6", userdata(tabcontrol)="ADC"
	Button button_Hardware_P_Enable, userdata(ResizeControlsInfo)=A"!!,HbJ,ht=5QF,i!!#>Fz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_Hardware_P_Enable, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	Button button_Hardware_P_Enable, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	Button button_Hardware_P_Enable, fSize=14
	Button button_Hardware_P_Disable, pos={399.00, 528.00}, size={60.00, 45.00}, disable=2, proc=P_ButtonProc_Disable
	Button button_Hardware_P_Disable, title="Disable"
	Button button_Hardware_P_Disable, help={"Enable DAQ devices used for pressure regulation."}
	Button button_Hardware_P_Disable, userdata(tabnum)="6", userdata(tabcontrol)="ADC"
	Button button_Hardware_P_Disable, userdata(ResizeControlsInfo)=A"!!,I/!!#Cg5QF,i!!#>Fz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_Hardware_P_Disable, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	Button button_Hardware_P_Disable, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	Button button_Hardware_P_Disable, fSize=14
	ValDisplay valdisp_DataAcq_P_0, pos={42.00, 351.00}, size={99.00, 21.00}, bodyWidth=35, disable=1
	ValDisplay valdisp_DataAcq_P_0, title="\\Z10Pressure (psi) "
	ValDisplay valdisp_DataAcq_P_0, help={"black background:user selected headstage"}
	ValDisplay valdisp_DataAcq_P_0, userdata(tabcontrol)="tab_DataAcq_Pressure"
	ValDisplay valdisp_DataAcq_P_0, userdata(ResizeControlsInfo)=A"!!,DG!!#BiJ,hpU!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	ValDisplay valdisp_DataAcq_P_0, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	ValDisplay valdisp_DataAcq_P_0, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	ValDisplay valdisp_DataAcq_P_0, userdata(ControlArray)="valdisp_DataAcq_P"
	ValDisplay valdisp_DataAcq_P_0, userdata(ControlArrayIndex)="0", fSize=14, frame=0
	ValDisplay valdisp_DataAcq_P_0, fStyle=0, valueColor=(65000, 65000, 65000)
	ValDisplay valdisp_DataAcq_P_0, valueBackColor=(65535, 65535, 65535, 0)
	ValDisplay valdisp_DataAcq_P_0, limits={0, 0, 0}, barmisc={0, 1000}, value=#"0.00"
	ValDisplay valdisp_DataAcq_P_1, pos={149.00, 351.00}, size={35.00, 21.00}, bodyWidth=35, disable=1
	ValDisplay valdisp_DataAcq_P_1, userdata(tabcontrol)="tab_DataAcq_Pressure"
	ValDisplay valdisp_DataAcq_P_1, userdata(ResizeControlsInfo)=A"!!,G)!!#BiJ,hnE!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	ValDisplay valdisp_DataAcq_P_1, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	ValDisplay valdisp_DataAcq_P_1, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	ValDisplay valdisp_DataAcq_P_1, userdata(ControlArray)="valdisp_DataAcq_P"
	ValDisplay valdisp_DataAcq_P_1, userdata(ControlArrayIndex)="1", fSize=14, frame=0
	ValDisplay valdisp_DataAcq_P_1, fStyle=0, valueColor=(65000, 65000, 65000)
	ValDisplay valdisp_DataAcq_P_1, valueBackColor=(65535, 65535, 65535, 0)
	ValDisplay valdisp_DataAcq_P_1, limits={0, 0, 0}, barmisc={0, 1000}, value=#"0.00"
	ValDisplay valdisp_DataAcq_P_2, pos={193.00, 351.00}, size={35.00, 21.00}, bodyWidth=35, disable=1
	ValDisplay valdisp_DataAcq_P_2, help={"black background:user selected headstage"}
	ValDisplay valdisp_DataAcq_P_2, userdata(tabcontrol)="tab_DataAcq_Pressure"
	ValDisplay valdisp_DataAcq_P_2, userdata(ResizeControlsInfo)=A"!!,GT!!#BiJ,hnE!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	ValDisplay valdisp_DataAcq_P_2, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	ValDisplay valdisp_DataAcq_P_2, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	ValDisplay valdisp_DataAcq_P_2, userdata(ControlArray)="valdisp_DataAcq_P"
	ValDisplay valdisp_DataAcq_P_2, userdata(ControlArrayIndex)="2", fSize=14, frame=0
	ValDisplay valdisp_DataAcq_P_2, fStyle=0, valueBackColor=(65535, 65535, 65535, 0)
	ValDisplay valdisp_DataAcq_P_2, limits={0, 0, 0}, barmisc={0, 1000}, value=#"0.00"
	ValDisplay valdisp_DataAcq_P_4, pos={280.00, 351.00}, size={35.00, 21.00}, bodyWidth=35, disable=1
	ValDisplay valdisp_DataAcq_P_4, help={"black background:user selected headstage"}
	ValDisplay valdisp_DataAcq_P_4, userdata(tabcontrol)="tab_DataAcq_Pressure"
	ValDisplay valdisp_DataAcq_P_4, userdata(ResizeControlsInfo)=A"!!,HH!!#BiJ,hnE!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	ValDisplay valdisp_DataAcq_P_4, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	ValDisplay valdisp_DataAcq_P_4, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	ValDisplay valdisp_DataAcq_P_4, userdata(ControlArray)="valdisp_DataAcq_P"
	ValDisplay valdisp_DataAcq_P_4, userdata(ControlArrayIndex)="4", fSize=14, frame=0
	ValDisplay valdisp_DataAcq_P_4, fStyle=0, valueBackColor=(65535, 65535, 65535, 0)
	ValDisplay valdisp_DataAcq_P_4, limits={0, 0, 0}, barmisc={0, 1000}, value=#"0.00"
	ValDisplay valdisp_DataAcq_P_5, pos={322.00, 351.00}, size={35.00, 21.00}, bodyWidth=35, disable=1
	ValDisplay valdisp_DataAcq_P_5, userdata(tabcontrol)="tab_DataAcq_Pressure"
	ValDisplay valdisp_DataAcq_P_5, userdata(ResizeControlsInfo)=A"!!,H]J,hs?J,hnE!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	ValDisplay valdisp_DataAcq_P_5, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	ValDisplay valdisp_DataAcq_P_5, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	ValDisplay valdisp_DataAcq_P_5, userdata(ControlArray)="valdisp_DataAcq_P"
	ValDisplay valdisp_DataAcq_P_5, userdata(ControlArrayIndex)="5", fSize=14, frame=0
	ValDisplay valdisp_DataAcq_P_5, fStyle=0, valueBackColor=(65535, 65535, 65535, 0)
	ValDisplay valdisp_DataAcq_P_5, limits={0, 0, 0}, barmisc={0, 1000}, value=#"0.00"
	ValDisplay valdisp_DataAcq_P_6, pos={367.00, 351.00}, size={35.00, 21.00}, bodyWidth=35, disable=1
	ValDisplay valdisp_DataAcq_P_6, help={"black background:user selected headstage"}
	ValDisplay valdisp_DataAcq_P_6, userdata(tabcontrol)="tab_DataAcq_Pressure"
	ValDisplay valdisp_DataAcq_P_6, userdata(ResizeControlsInfo)=A"!!,Hs!!#BiJ,hnE!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	ValDisplay valdisp_DataAcq_P_6, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	ValDisplay valdisp_DataAcq_P_6, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	ValDisplay valdisp_DataAcq_P_6, userdata(ControlArray)="valdisp_DataAcq_P"
	ValDisplay valdisp_DataAcq_P_6, userdata(ControlArrayIndex)="6", fSize=14, frame=0
	ValDisplay valdisp_DataAcq_P_6, fStyle=0, valueBackColor=(65535, 65535, 65535, 0)
	ValDisplay valdisp_DataAcq_P_6, limits={0, 0, 0}, barmisc={0, 1000}, value=#"0.00"
	ValDisplay valdisp_DataAcq_P_7, pos={409.00, 351.00}, size={35.00, 21.00}, bodyWidth=35, disable=1
	ValDisplay valdisp_DataAcq_P_7, userdata(tabcontrol)="tab_DataAcq_Pressure"
	ValDisplay valdisp_DataAcq_P_7, userdata(ResizeControlsInfo)=A"!!,I3J,hs?J,hnE!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	ValDisplay valdisp_DataAcq_P_7, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	ValDisplay valdisp_DataAcq_P_7, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	ValDisplay valdisp_DataAcq_P_7, userdata(ControlArray)="valdisp_DataAcq_P"
	ValDisplay valdisp_DataAcq_P_7, userdata(ControlArrayIndex)="7", fSize=14, frame=0
	ValDisplay valdisp_DataAcq_P_7, fStyle=0, valueBackColor=(65535, 65535, 65535, 0)
	ValDisplay valdisp_DataAcq_P_7, limits={0, 0, 0}, barmisc={0, 1000}, value=#"0.00"
	TabControl tab_DataAcq_Pressure, pos={31.00, 269.00}, size={423.00, 108.00}, disable=1, proc=ACL_DisplayTab
	TabControl tab_DataAcq_Pressure, userdata(tabnum)="0", userdata(tabcontrol)="ADC"
	TabControl tab_DataAcq_Pressure, userdata(currenttab)="0"
	TabControl tab_DataAcq_Pressure, userdata(ResizeControlsInfo)=A"!!,Cd!!#BB!!#C9J,hpkz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TabControl tab_DataAcq_Pressure, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	TabControl tab_DataAcq_Pressure, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	TabControl tab_DataAcq_Pressure, labelBack=(60928, 60928, 60928), fSize=10
	TabControl tab_DataAcq_Pressure, tabLabel(0)="Auto", tabLabel(1)="Manual"
	TabControl tab_DataAcq_Pressure, tabLabel(2)="User", value=0
	Button button_DataAcq_SSSetPressureMan, pos={39.00, 300.00}, size={84.00, 27.00}, disable=3, proc=ButtonProc_DataAcq_ManPressSet
	Button button_DataAcq_SSSetPressureMan, title="Apply", userdata(tabnum)="1"
	Button button_DataAcq_SSSetPressureMan, userdata(tabcontrol)="tab_DataAcq_Pressure"
	Button button_DataAcq_SSSetPressureMan, userdata(ResizeControlsInfo)=A"!!,D+!!#BQ!!#?a!!#=;z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_DataAcq_SSSetPressureMan, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	Button button_DataAcq_SSSetPressureMan, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	Button button_DataAcq_PPSetPressureMan, pos={198.00, 300.00}, size={90.00, 27.00}, disable=1, proc=ButtonProc_ManPP
	Button button_DataAcq_PPSetPressureMan, title="Pressure Pulse"
	Button button_DataAcq_PPSetPressureMan, userdata(tabnum)="1"
	Button button_DataAcq_PPSetPressureMan, userdata(tabcontrol)="tab_DataAcq_Pressure"
	Button button_DataAcq_PPSetPressureMan, userdata(ResizeControlsInfo)=A"!!,GX!!#BQ!!#?m!!#=;z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_DataAcq_PPSetPressureMan, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	Button button_DataAcq_PPSetPressureMan, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable setvar_DataAcq_SSPressure, pos={123.00, 306.00}, size={69.00, 18.00}, bodyWidth=50, disable=1, proc=DAP_SetVarProc_CAA
	SetVariable setvar_DataAcq_SSPressure, title="psi", userdata(tabnum)="1"
	SetVariable setvar_DataAcq_SSPressure, userdata(tabcontrol)="tab_DataAcq_Pressure"
	SetVariable setvar_DataAcq_SSPressure, userdata(ResizeControlsInfo)=A"!!,F_!!#BSJ,hon!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_DataAcq_SSPressure, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable setvar_DataAcq_SSPressure, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable setvar_DataAcq_SSPressure, userdata(DefaultIncrement)="1"
	SetVariable setvar_DataAcq_SSPressure, limits={-10, 10, 1}, value=_NUM:0
	SetVariable setvar_DataAcq_PPPressure, pos={291.00, 306.00}, size={69.00, 18.00}, bodyWidth=50, disable=1, proc=DAP_SetVarProc_CAA
	SetVariable setvar_DataAcq_PPPressure, title="psi", userdata(tabnum)="1"
	SetVariable setvar_DataAcq_PPPressure, userdata(tabcontrol)="tab_DataAcq_Pressure"
	SetVariable setvar_DataAcq_PPPressure, userdata(ResizeControlsInfo)=A"!!,HLJ,hs)J,hon!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_DataAcq_PPPressure, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable setvar_DataAcq_PPPressure, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable setvar_DataAcq_PPPressure, userdata(DefaultIncrement)="1"
	SetVariable setvar_DataAcq_PPPressure, limits={-10, 10, 1}, value=_NUM:0
	SetVariable setvar_DataAcq_PPDuration, pos={360.00, 306.00}, size={87.00, 18.00}, bodyWidth=40, disable=1, proc=DAP_SetVarProc_CAA
	SetVariable setvar_DataAcq_PPDuration, title="Dur(ms)", userdata(tabnum)="1"
	SetVariable setvar_DataAcq_PPDuration, userdata(tabcontrol)="tab_DataAcq_Pressure"
	SetVariable setvar_DataAcq_PPDuration, userdata(ResizeControlsInfo)=A"!!,Hp!!#BSJ,hp=!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_DataAcq_PPDuration, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable setvar_DataAcq_PPDuration, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable setvar_DataAcq_PPDuration, userdata(DefaultIncrement)="1"
	SetVariable setvar_DataAcq_PPDuration, limits={0, 300, 1}, value=_NUM:0
	CheckBox check_DataAcq_ManPressureAll, pos={69.00, 330.00}, size={30.00, 15.00}, disable=3, proc=DAP_CheckProc_UpdateGuiState
	CheckBox check_DataAcq_ManPressureAll, title="All", userdata(tabnum)="1"
	CheckBox check_DataAcq_ManPressureAll, userdata(tabcontrol)="tab_DataAcq_Pressure"
	CheckBox check_DataAcq_ManPressureAll, userdata(ResizeControlsInfo)=A"!!,ED!!#B`!!#=K!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_DataAcq_ManPressureAll, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_DataAcq_ManPressureAll, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox check_DataAcq_ManPressureAll, value=0
	CheckBox check_settings_TP_show_peak, pos={27.00, 132.00}, size={128.00, 15.00}, disable=1, proc=DAP_CheckProc_UpdateGuiState
	CheckBox check_settings_TP_show_peak, title="Show peak resistance"
	CheckBox check_settings_TP_show_peak, help={"Show the peak resistance curve during the testpulse"}
	CheckBox check_settings_TP_show_peak, userdata(tabnum)="5"
	CheckBox check_settings_TP_show_peak, userdata(tabcontrol)="ADC"
	CheckBox check_settings_TP_show_peak, userdata(ResizeControlsInfo)=A"!!,Cl!!#@h!!#@b!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_settings_TP_show_peak, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_settings_TP_show_peak, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox check_settings_TP_show_peak, value=1
	CheckBox check_settings_TP_show_steady, pos={160.00, 132.00}, size={165.00, 15.00}, disable=1, proc=DAP_CheckProc_UpdateGuiState
	CheckBox check_settings_TP_show_steady, title="Show steady state resistance"
	CheckBox check_settings_TP_show_steady, help={"Show the steady state resistance curve during the testpulse"}
	CheckBox check_settings_TP_show_steady, userdata(tabnum)="5"
	CheckBox check_settings_TP_show_steady, userdata(tabcontrol)="ADC"
	CheckBox check_settings_TP_show_steady, userdata(ResizeControlsInfo)=A"!!,G<!!#@i!!#A3!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_settings_TP_show_steady, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_settings_TP_show_steady, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox check_settings_TP_show_steady, value=1
	CheckBox check_DatAcq_ApproachNear, pos={78.00, 327.00}, size={41.00, 15.00}, disable=1, proc=P_Check_ApproachNear
	CheckBox check_DatAcq_ApproachNear, title="Near"
	CheckBox check_DatAcq_ApproachNear, help={"Apply postive pressure to all headstages"}
	CheckBox check_DatAcq_ApproachNear, userdata(tabnum)="0"
	CheckBox check_DatAcq_ApproachNear, userdata(tabcontrol)="tab_DataAcq_Pressure"
	CheckBox check_DatAcq_ApproachNear, userdata(ResizeControlsInfo)=A"!!,EZ!!#B^J,hnY!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_DatAcq_ApproachNear, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_DatAcq_ApproachNear, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox check_DatAcq_ApproachNear, value=0
	Button button_DataAcq_SlowComp_VC, pos={393.00, 234.00}, size={54.00, 18.00}, disable=1, proc=DAP_ButtonProc_AmpCntrls
	Button button_DataAcq_SlowComp_VC, title="Cp Slow"
	Button button_DataAcq_SlowComp_VC, help={"Activates MCC auto slow capacitance compensation"}
	Button button_DataAcq_SlowComp_VC, userdata(tabnum)="0"
	Button button_DataAcq_SlowComp_VC, userdata(tabcontrol)="tab_DataAcq_Amp"
	Button button_DataAcq_SlowComp_VC, userdata(ResizeControlsInfo)=A"!!,I+!!#B&!!#>j!!#<Xz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_DataAcq_SlowComp_VC, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	Button button_DataAcq_SlowComp_VC, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	Button button_DataAcq_SlowComp_VC, userdata(Config_DontRestore)="1"
	Button button_DataAcq_SlowComp_VC, userdata(Config_DontSave)="1"
	CheckBox check_DatAcq_SealAtm, pos={186.00, 327.00}, size={42.00, 15.00}, disable=1, proc=P_Check_SealAtm
	CheckBox check_DatAcq_SealAtm, title="Atm."
	CheckBox check_DatAcq_SealAtm, help={"Seals all headstates with active test pulse"}
	CheckBox check_DatAcq_SealAtm, userdata(tabnum)="0"
	CheckBox check_DatAcq_SealAtm, userdata(tabcontrol)="tab_DataAcq_Pressure"
	CheckBox check_DatAcq_SealAtm, userdata(ResizeControlsInfo)=A"!!,GJ!!#B^J,hn]!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_DatAcq_SealAtm, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_DatAcq_SealAtm, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox check_DatAcq_SealAtm, value=0
	CheckBox Check_DataAcq1_DistribDaq, pos={290.00, 637.00}, size={101.00, 15.00}, disable=1, proc=DAP_CheckProc_SyncCtrl
	CheckBox Check_DataAcq1_DistribDaq, title="distributed DAQ"
	CheckBox Check_DataAcq1_DistribDaq, help={"Determines if distributed acquisition is used."}
	CheckBox Check_DataAcq1_DistribDaq, userdata(tabnum)="0"
	CheckBox Check_DataAcq1_DistribDaq, userdata(tabcontrol)="ADC"
	CheckBox Check_DataAcq1_DistribDaq, userdata(ResizeControlsInfo)=A"!!,Fi!!#D1!!#@,!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_DataAcq1_DistribDaq, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_DataAcq1_DistribDaq, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_DataAcq1_DistribDaq, value=0
	CheckBox Check_DataAcq1_dDAQOptOv, pos={400.00, 637.00}, size={62.00, 15.00}, bodyWidth=50, disable=1, proc=DAP_CheckProc_SyncCtrl
	CheckBox Check_DataAcq1_dDAQOptOv, title="oodDAQ"
	CheckBox Check_DataAcq1_dDAQOptOv, help={"Optimizes the stim set layout for minimum length and no overlap."}
	CheckBox Check_DataAcq1_dDAQOptOv, userdata(tabnum)="0"
	CheckBox Check_DataAcq1_dDAQOptOv, userdata(tabcontrol)="ADC"
	CheckBox Check_DataAcq1_dDAQOptOv, userdata(ResizeControlsInfo)=A"!!,G$!!#D5!!#?-!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_DataAcq1_dDAQOptOv, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_DataAcq1_dDAQOptOv, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_DataAcq1_dDAQOptOv, value=0
	SetVariable Setvar_DataAcq_dDAQDelay, pos={319.00, 695.00}, size={144.00, 18.00}, bodyWidth=50, disable=1, proc=DAP_SetVarProc_SyncCtrl
	SetVariable Setvar_DataAcq_dDAQDelay, title="dDAQ delay (ms)"
	SetVariable Setvar_DataAcq_dDAQDelay, help={"Delay between the sets during distributed DAQ."}
	SetVariable Setvar_DataAcq_dDAQDelay, userdata(tabnum)="0"
	SetVariable Setvar_DataAcq_dDAQDelay, userdata(tabcontrol)="ADC"
	SetVariable Setvar_DataAcq_dDAQDelay, userdata(ResizeControlsInfo)=A"!!,H[!!#D95QF._!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Setvar_DataAcq_dDAQDelay, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Setvar_DataAcq_dDAQDelay, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Setvar_DataAcq_dDAQDelay, limits={0, Inf, 1}, value=_NUM:0
	SetVariable setvar_DataAcq_dDAQOptOvPost, pos={279.00, 734.00}, size={184.00, 18.00}, bodyWidth=50, disable=1, proc=DAP_SetVarProc_SyncCtrl
	SetVariable setvar_DataAcq_dDAQOptOvPost, title="oodDAQ post delay (ms)"
	SetVariable setvar_DataAcq_dDAQOptOvPost, help={"Timespan in ms after features in stimset not filled with another's stimset data. Used only for optimized overlay dDAQ."}
	SetVariable setvar_DataAcq_dDAQOptOvPost, userdata(tabnum)="0"
	SetVariable setvar_DataAcq_dDAQOptOvPost, userdata(tabcontrol)="ADC"
	SetVariable setvar_DataAcq_dDAQOptOvPost, userdata(ResizeControlsInfo)=A"!!,HG!!#DC!!#AG!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_DataAcq_dDAQOptOvPost, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_DataAcq_dDAQOptOvPost, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_DataAcq_dDAQOptOvPost, limits={0, Inf, 1}, value=_NUM:0
	SetVariable setvar_DataAcq_dDAQOptOvPre, pos={285.00, 714.00}, size={178.00, 18.00}, bodyWidth=50, disable=1, proc=DAP_SetVarProc_SyncCtrl
	SetVariable setvar_DataAcq_dDAQOptOvPre, title="oodDAQ pre delay (ms)"
	SetVariable setvar_DataAcq_dDAQOptOvPre, help={"Timespan in ms before features in stimset not filled with another's stimset data. Used only for optimized overlay dDAQ."}
	SetVariable setvar_DataAcq_dDAQOptOvPre, userdata(tabnum)="0"
	SetVariable setvar_DataAcq_dDAQOptOvPre, userdata(tabcontrol)="ADC"
	SetVariable setvar_DataAcq_dDAQOptOvPre, userdata(ResizeControlsInfo)=A"!!,HJ!!#D>!!#AA!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_DataAcq_dDAQOptOvPre, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_DataAcq_dDAQOptOvPre, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_DataAcq_dDAQOptOvPre, limits={0, Inf, 1}, value=_NUM:0
	Button button_DataAcq_OpenCommentNB, pos={415.00, 777.00}, size={41.00, 19.00}, disable=1, proc=DAP_ButtonProc_OpenCommentNB
	Button button_DataAcq_OpenCommentNB, title="NB"
	Button button_DataAcq_OpenCommentNB, help={"Open a notebook displaying the comments of all sweeps and allowing free form additions by the user."}
	Button button_DataAcq_OpenCommentNB, userdata(tabnum)="0"
	Button button_DataAcq_OpenCommentNB, userdata(tabcontrol)="ADC"
	Button button_DataAcq_OpenCommentNB, userdata(ResizeControlsInfo)=A"!!,I3!!#DR^]6\\4!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_DataAcq_OpenCommentNB, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button button_DataAcq_OpenCommentNB, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_Settings_TPAfterDAQ, pos={160.00, 108.00}, size={131.00, 15.00}, disable=1, proc=DAP_CheckProc_UpdateGuiState
	CheckBox check_Settings_TPAfterDAQ, title="Activate TP after DAQ"
	CheckBox check_Settings_TPAfterDAQ, help={"Immediately start a test pulse after DAQ finishes"}
	CheckBox check_Settings_TPAfterDAQ, userdata(tabnum)="5"
	CheckBox check_Settings_TPAfterDAQ, userdata(tabcontrol)="ADC"
	CheckBox check_Settings_TPAfterDAQ, userdata(ResizeControlsInfo)=A"!!,G<!!#@>!!#@f!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_Settings_TPAfterDAQ, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_Settings_TPAfterDAQ, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_Settings_TPAfterDAQ, value=0
	PopupMenu Popup_Settings_SampIntMult, pos={246.00, 231.00}, size={189.00, 19.00}, bodyWidth=40, disable=1, proc=DAP_PopMenuProc_SampMult
	PopupMenu Popup_Settings_SampIntMult, title="Sampling interval multiplier"
	PopupMenu Popup_Settings_SampIntMult, help={"Multiplier for the sampling interval. Higher values result in lower frequency, effectively acting as a frequency divider.\rNI and ITC hardware:\r\tAll channels sample at the set interval.\rSUTTER hardware:\r\tAD channels sample at the set interval. DA and TTL channels sample at the lowest possible interval.\rThe testpulse will always be sampled at the lowest possible interval.."}
	PopupMenu Popup_Settings_SampIntMult, userdata(tabnum)="5"
	PopupMenu Popup_Settings_SampIntMult, userdata(tabcontrol)="ADC"
	PopupMenu Popup_Settings_SampIntMult, userdata(ResizeControlsInfo)=A"!!,Go!!#B)!!#AL!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Popup_Settings_SampIntMult, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Popup_Settings_SampIntMult, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Popup_Settings_SampIntMult, mode=1, popvalue="1", value=#"DAP_GetSamplingMultiplier()"
	CheckBox Check_Settings_NwbExport, pos={33.00, 231.00}, size={103.00, 15.00}, disable=1, proc=DAP_CheckProc_UpdateGuiState
	CheckBox Check_Settings_NwbExport, title="Export into NWB"
	CheckBox Check_Settings_NwbExport, help={"Export all data including sweeps into a file in the NeurodataWithoutBorders fornat,"}
	CheckBox Check_Settings_NwbExport, userdata(tabnum)="5"
	CheckBox Check_Settings_NwbExport, userdata(tabcontrol)="ADC"
	CheckBox Check_Settings_NwbExport, userdata(ResizeControlsInfo)=A"!!,Cl!!#Ag!!#@0!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_Settings_NwbExport, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_Settings_NwbExport, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_Settings_NwbExport, value=0
	PopupMenu Popup_Settings_NwbVersion, pos={139.00, 229.00}, size={69.00, 19.00}, disable=1, proc=DAP_PopMenuProc_UpdateGuiState
	PopupMenu Popup_Settings_NwbVersion, title="version"
	PopupMenu Popup_Settings_NwbVersion, help={"Set the NWB Version of the export when using triggered export from DA_Ephys"}
	PopupMenu Popup_Settings_NwbVersion, userdata(tabcontrol)="ADC"
	PopupMenu Popup_Settings_NwbVersion, userdata(tabnum)="5"
	PopupMenu Popup_Settings_NwbVersion, mode=2, popvalue="2", value=#"\"1;2\""
	SetVariable setvar_DataAcq_OnsetDelayUser, pos={296.00, 656.00}, size={167.00, 18.00}, bodyWidth=50, disable=1, proc=DAP_SetVar_UpdateGuiState
	SetVariable setvar_DataAcq_OnsetDelayUser, title="User onset delay (ms)"
	SetVariable setvar_DataAcq_OnsetDelayUser, help={"A global parameter that delays the onset time of a set after the initiation of data acquistion. Data acquisition start time is NOT delayed. Useful when set(s) have insufficient baseline epoch."}
	SetVariable setvar_DataAcq_OnsetDelayUser, userdata(tabnum)="0"
	SetVariable setvar_DataAcq_OnsetDelayUser, userdata(tabcontrol)="ADC"
	SetVariable setvar_DataAcq_OnsetDelayUser, userdata(ResizeControlsInfo)=A"!!,HOJ,htZJ,hqa!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_DataAcq_OnsetDelayUser, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_DataAcq_OnsetDelayUser, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_DataAcq_OnsetDelayUser, limits={0, Inf, 1}, value=_NUM:0
	ValDisplay valdisp_DataAcq_OnsetDelayAuto, pos={320.00, 755.00}, size={143.00, 17.00}, bodyWidth=50, disable=1
	ValDisplay valdisp_DataAcq_OnsetDelayAuto, title="Onset delay (ms)"
	ValDisplay valdisp_DataAcq_OnsetDelayAuto, help={"The additional onset delay required by the \"Insert TP\" setting."}
	ValDisplay valdisp_DataAcq_OnsetDelayAuto, userdata(tabnum)="0"
	ValDisplay valdisp_DataAcq_OnsetDelayAuto, userdata(tabcontrol)="ADC"
	ValDisplay valdisp_DataAcq_OnsetDelayAuto, userdata(ResizeControlsInfo)=A"!!,H[J,hu#!!#@s!!#<@z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	ValDisplay valdisp_DataAcq_OnsetDelayAuto, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	ValDisplay valdisp_DataAcq_OnsetDelayAuto, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	ValDisplay valdisp_DataAcq_OnsetDelayAuto, limits={0, 0, 0}, barmisc={0, 1000}
	ValDisplay valdisp_DataAcq_OnsetDelayAuto, value=_NUM:0
	Button button_Hardware_ClearChanConn, pos={292.00, 327.00}, size={150.00, 18.00}, proc=DAP_ButtonProc_ClearChanCon
	Button button_Hardware_ClearChanConn, title="Clear Associations"
	Button button_Hardware_ClearChanConn, help={"Clear the channel/amplifier association of the current headstage."}
	Button button_Hardware_ClearChanConn, userdata(tabnum)="6"
	Button button_Hardware_ClearChanConn, userdata(tabcontrol)="ADC"
	Button button_Hardware_ClearChanConn, userdata(ResizeControlsInfo)=A"!!,HDJ,hs4J,hqP!!#<Xz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_Hardware_ClearChanConn, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button button_Hardware_ClearChanConn, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_Settings_DisablePressure, pos={323.00, 824.00}, size={132.00, 15.00}, disable=1, proc=DAP_CheckProc_UpdateGuiState
	CheckBox check_Settings_DisablePressure, title="Stop pressure on DAQ"
	CheckBox check_Settings_DisablePressure, help={"Turn off all pressure modes when data aquisition is initiated"}
	CheckBox check_Settings_DisablePressure, userdata(tabnum)="5"
	CheckBox check_Settings_DisablePressure, userdata(tabcontrol)="ADC"
	CheckBox check_Settings_DisablePressure, userdata(ResizeControlsInfo)=A"!!,HqJ,hu!5QF-P!!#=Sz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_Settings_DisablePressure, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_Settings_DisablePressure, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_Settings_DisablePressure, value=0, side=1
	CheckBox check_Settings_AmpIEQZstep, pos={324.00, 714.00}, size={122.00, 15.00}, disable=1, proc=DAP_CheckProc_UpdateGuiState
	CheckBox check_Settings_AmpIEQZstep, title="Mode switch via I=0"
	CheckBox check_Settings_AmpIEQZstep, help={"Always switch from V-Clamp to I-Clamp and vice versa via I=0"}
	CheckBox check_Settings_AmpIEQZstep, userdata(tabnum)="5"
	CheckBox check_Settings_AmpIEQZstep, userdata(tabcontrol)="ADC"
	CheckBox check_Settings_AmpIEQZstep, userdata(ResizeControlsInfo)=A"!!,H^!!#D05QF.A!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_Settings_AmpIEQZstep, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_Settings_AmpIEQZstep, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox check_Settings_AmpIEQZstep, value=0
	CheckBox check_Settings_RequireAmpConn, pos={324.00, 693.00}, size={108.00, 15.00}, disable=1, proc=DAP_CheckProc_RequireAmplifier
	CheckBox check_Settings_RequireAmpConn, title="Require Amplifier"
	CheckBox check_Settings_RequireAmpConn, help={"Require that every active headstage is connected to an amplifier for TP/DAQ."}
	CheckBox check_Settings_RequireAmpConn, userdata(tabnum)="5"
	CheckBox check_Settings_RequireAmpConn, userdata(tabcontrol)="ADC"
	CheckBox check_Settings_RequireAmpConn, userdata(ResizeControlsInfo)=A"!!,H]J,htU^]6^P!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_Settings_RequireAmpConn, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_Settings_RequireAmpConn, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox check_Settings_RequireAmpConn, value=1
	CheckBox Check_AD_All, pos={18.00, 435.00}, size={23.00, 15.00}, disable=1, proc=DAP_CheckProc_Channel_All
	CheckBox Check_AD_All, title="X", help={"Set the active state of all AD channels"}
	CheckBox Check_AD_All, userdata(tabnum)="2", userdata(tabcontrol)="ADC"
	CheckBox Check_AD_All, userdata(ResizeControlsInfo)=A"!!,BQ!!#C?J,hm>!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_AD_All, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_AD_All, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_AD_All, userdata(Config_RestorePriority)="60", value=0, side=1
	GroupBox Group_AD_all, pos={18.00, 426.00}, size={309.00, 4.00}, disable=1
	GroupBox Group_AD_all, userdata(tabnum)="2", userdata(tabcontrol)="ADC"
	GroupBox Group_AD_all, userdata(ResizeControlsInfo)=A"!!,BY!!#C;!!#BU!!#97z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	GroupBox Group_AD_all, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	GroupBox Group_AD_all, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_DA_ALL, pos={18.00, 459.00}, size={23.00, 15.00}, disable=1, proc=DAP_CheckProc_Channel_All
	CheckBox Check_DA_ALL, title="X", userdata(tabnum)="1", userdata(tabcontrol)="ADC"
	CheckBox Check_DA_ALL, userdata(ResizeControlsInfo)=A"!!,BQ!!#CKJ,hm>!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_DA_ALL, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_DA_ALL, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_DA_ALL, userdata(Config_RestorePriority)="60", value=0, side=1
	PopupMenu Wave_DA_All, pos={145.00, 456.00}, size={125.00, 19.00}, bodyWidth=125, disable=1, proc=DAP_PopMenuChkProc_StimSetList
	PopupMenu Wave_DA_All, userdata(tabnum)="1", userdata(tabcontrol)="ADC"
	PopupMenu Wave_DA_All, userdata(ResizeControlsInfo)=A"!!,G)!!#CJ!!#@^!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Wave_DA_All, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Wave_DA_All, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Wave_DA_All, userdata(Config_RestorePriority)="60", fSize=10
	PopupMenu Wave_DA_All, mode=1, popvalue="- none -", value=#"\"- none -;\"+ST_GetStimsetList(channelType = 0, searchString = \"*\")"
	SetVariable Search_DA_All, pos={153.00, 480.00}, size={123.00, 18.00}, disable=1, proc=DAP_SetVarProc_Channel_Search
	SetVariable Search_DA_All, title="Search filter", userdata(tabnum)="1"
	SetVariable Search_DA_All, userdata(tabcontrol)="ADC"
	SetVariable Search_DA_All, userdata(ResizeControlsInfo)=A"!!,G)!!#CV!!#@\\!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Search_DA_All, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Search_DA_All, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Search_DA_All, userdata(Config_RestorePriority)="60", value=_STR:""
	SetVariable Scale_DA_All, pos={283.00, 456.00}, size={50.00, 18.00}, bodyWidth=50, disable=1, proc=DAP_SetVarProc_DA_Scale
	SetVariable Scale_DA_All, userdata(tabnum)="1", userdata(tabcontrol)="ADC"
	SetVariable Scale_DA_All, userdata(ResizeControlsInfo)=A"!!,HL!!#CJ!!#>V!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Scale_DA_All, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Scale_DA_All, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Scale_DA_All, userdata(Config_RestorePriority)="60"
	SetVariable Scale_DA_All, userdata(DefaultIncrement)="10"
	SetVariable Scale_DA_All, limits={-Inf, Inf, 10}, value=_NUM:1
	PopupMenu IndexEnd_DA_All, pos={346.00, 456.00}, size={125.00, 19.00}, bodyWidth=125, disable=1, proc=DAP_PopMenuChkProc_StimSetList
	PopupMenu IndexEnd_DA_All, userdata(tabnum)="1", userdata(tabcontrol)="ADC"
	PopupMenu IndexEnd_DA_All, userdata(ResizeControlsInfo)=A"!!,HkJ,hsu!!#@^!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu IndexEnd_DA_All, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu IndexEnd_DA_All, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu IndexEnd_DA_All, userdata(Config_RestorePriority)="60"
	PopupMenu IndexEnd_DA_All, mode=1, popvalue="- none -", value=#"\"- none -;\"+ST_GetStimsetList(channelType = 0, searchString = \"*\")"
	GroupBox Group_TTL_all, pos={18.00, 447.00}, size={345.00, 4.00}, disable=1
	GroupBox Group_TTL_all, userdata(tabnum)="3", userdata(tabcontrol)="ADC"
	GroupBox Group_TTL_all, userdata(ResizeControlsInfo)=A"!!,BY!!#CDJ,hs<J,hj-z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	GroupBox Group_TTL_all, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	GroupBox Group_TTL_all, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Wave_TTL_All, pos={100.00, 459.00}, size={125.00, 19.00}, bodyWidth=125, disable=1, proc=DAP_PopMenuChkProc_StimSetList
	PopupMenu Wave_TTL_All, userdata(tabnum)="3", userdata(tabcontrol)="ADC"
	PopupMenu Wave_TTL_All, userdata(ResizeControlsInfo)=A"!!,F3!!#CK!!#@^!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Wave_TTL_All, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Wave_TTL_All, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Wave_TTL_All, userdata(Config_RestorePriority)="60", fSize=10
	PopupMenu Wave_TTL_All, mode=1, popvalue="- none -", value=#"\"- none -;\"+ST_GetStimsetList(channelType = 1, searchString = \"*\")"
	SetVariable Search_TTL_All, pos={102.00, 480.00}, size={123.00, 18.00}, disable=1, proc=DAP_SetVarProc_Channel_Search
	SetVariable Search_TTL_All, title="Search filter", userdata(tabnum)="3"
	SetVariable Search_TTL_All, userdata(tabcontrol)="ADC"
	SetVariable Search_TTL_All, userdata(ResizeControlsInfo)=A"!!,F3!!#CV!!#@\\!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Search_TTL_All, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Search_TTL_All, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Search_TTL_All, value=_STR:""
	PopupMenu IndexEnd_TTL_All, pos={241.00, 459.00}, size={125.00, 19.00}, bodyWidth=125, disable=1, proc=DAP_PopMenuChkProc_StimSetList
	PopupMenu IndexEnd_TTL_All, userdata(tabnum)="3", userdata(tabcontrol)="ADC"
	PopupMenu IndexEnd_TTL_All, userdata(ResizeControlsInfo)=A"!!,H.!!#CK!!#@^!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu IndexEnd_TTL_All, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu IndexEnd_TTL_All, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu IndexEnd_TTL_All, userdata(Config_RestorePriority)="60"
	PopupMenu IndexEnd_TTL_All, mode=1, popvalue="- none -", value=#"\"- none -;\"+ST_GetStimsetList(channelType = 1, searchString = \"*\")"
	CheckBox Check_TTL_ALL, pos={18.00, 459.00}, size={23.00, 15.00}, disable=1, proc=DAP_CheckProc_Channel_All
	CheckBox Check_TTL_ALL, title="X", userdata(tabnum)="3", userdata(tabcontrol)="ADC"
	CheckBox Check_TTL_ALL, userdata(ResizeControlsInfo)=A"!!,BY!!#CKJ,hm>!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_TTL_ALL, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_TTL_ALL, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_TTL_ALL, userdata(Config_RestorePriority)="60", value=0
	CheckBox check_settings_show_power, pos={27.00, 156.00}, size={134.00, 15.00}, disable=1, proc=DAP_CheckProc_PowerSpectrum
	CheckBox check_settings_show_power, title="Show power spectrum"
	CheckBox check_settings_show_power, help={"Show the power spectrum (Fourier Transform) of the testpulse"}
	CheckBox check_settings_show_power, userdata(tabnum)="5"
	CheckBox check_settings_show_power, userdata(tabcontrol)="ADC"
	CheckBox check_settings_show_power, userdata(ResizeControlsInfo)=A"!!,G9!!#CmJ,hq?!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_settings_show_power, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_settings_show_power, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox check_settings_show_power, value=0
	PopupMenu Popup_Settings_Pressure_TTLB, pos={224.00, 555.00}, size={103.00, 19.00}, bodyWidth=70, proc=DAP_PopMenuProc_CAA
	PopupMenu Popup_Settings_Pressure_TTLB, title="TTL B"
	PopupMenu Popup_Settings_Pressure_TTLB, help={"Select TTL channel for solenoid command"}
	PopupMenu Popup_Settings_Pressure_TTLB, userdata(tabnum)="6"
	PopupMenu Popup_Settings_Pressure_TTLB, userdata(tabcontrol)="ADC"
	PopupMenu Popup_Settings_Pressure_TTLB, userdata(ResizeControlsInfo)=A"!!,H!!!#Cn5QF-r!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Popup_Settings_Pressure_TTLB, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Popup_Settings_Pressure_TTLB, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Popup_Settings_Pressure_TTLB, userdata(Config_DontRestore)="1"
	PopupMenu Popup_Settings_Pressure_TTLB, userdata(Config_DontSave)="1"
	PopupMenu Popup_Settings_Pressure_TTLB, mode=1, popvalue="- none -", value=#"\"- none -;0;1;2;3;4;5;6;7\""
	CheckBox check_Settings_UserP_Approach, pos={228.00, 321.00}, size={68.00, 15.00}, disable=1, proc=DAP_CheckProc_Settings_PUser
	CheckBox check_Settings_UserP_Approach, title="Approach"
	CheckBox check_Settings_UserP_Approach, help={"User applied pressure during approach mode "}
	CheckBox check_Settings_UserP_Approach, userdata(tabnum)="2"
	CheckBox check_Settings_UserP_Approach, userdata(tabcontrol)="tab_DataAcq_Pressure"
	CheckBox check_Settings_UserP_Approach, userdata(ResizeControlsInfo)=A"!!,H!!!#BZJ,hoj!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_Settings_UserP_Approach, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_Settings_UserP_Approach, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_Settings_UserP_Approach, value=0
	CheckBox check_Settings_UserP_Seal, pos={300.00, 321.00}, size={37.00, 15.00}, disable=1, proc=DAP_CheckProc_Settings_PUser
	CheckBox check_Settings_UserP_Seal, title="Seal"
	CheckBox check_Settings_UserP_Seal, help={"User applied pressure during seal mode - holding potential and switch to atmospheric pressure remain automated"}
	CheckBox check_Settings_UserP_Seal, userdata(tabnum)="2"
	CheckBox check_Settings_UserP_Seal, userdata(tabcontrol)="tab_DataAcq_Pressure"
	CheckBox check_Settings_UserP_Seal, userdata(ResizeControlsInfo)=A"!!,HQ!!#BZJ,hnI!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_Settings_UserP_Seal, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_Settings_UserP_Seal, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_Settings_UserP_Seal, value=0
	CheckBox check_Settings_UserP_BreakIn, pos={342.00, 321.00}, size={63.00, 15.00}, disable=1, proc=DAP_CheckProc_Settings_PUser
	CheckBox check_Settings_UserP_BreakIn, title="Break-In "
	CheckBox check_Settings_UserP_BreakIn, help={"User access during Break-in - pressure is set to atmospheric when the steady state resistance drops below 1 GΩ"}
	CheckBox check_Settings_UserP_BreakIn, userdata(tabnum)="2"
	CheckBox check_Settings_UserP_BreakIn, userdata(tabcontrol)="tab_DataAcq_Pressure"
	CheckBox check_Settings_UserP_BreakIn, userdata(ResizeControlsInfo)=A"!!,HfJ,hs0J,ho\\!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_Settings_UserP_BreakIn, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_Settings_UserP_BreakIn, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_Settings_UserP_BreakIn, value=0
	CheckBox check_Settings_UserP_Clear, pos={405.00, 321.00}, size={43.00, 15.00}, disable=1, proc=DAP_CheckProc_Settings_PUser
	CheckBox check_Settings_UserP_Clear, title="Clear"
	CheckBox check_Settings_UserP_Clear, help={"User applied pressure during clear - user pressure access is turned OFF after 10% decrease in steady state resistance"}
	CheckBox check_Settings_UserP_Clear, userdata(tabnum)="2"
	CheckBox check_Settings_UserP_Clear, userdata(tabcontrol)="tab_DataAcq_Pressure"
	CheckBox check_Settings_UserP_Clear, userdata(ResizeControlsInfo)=A"!!,I1J,hs0J,hna!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_Settings_UserP_Clear, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_Settings_UserP_Clear, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_Settings_UserP_Clear, value=0
	TitleBox title_Settings_Pressure_UserP, pos={225.00, 300.00}, size={125.00, 15.00}, disable=1
	TitleBox title_Settings_Pressure_UserP, title="User pressure in modes:"
	TitleBox title_Settings_Pressure_UserP, userdata(tabnum)="2"
	TitleBox title_Settings_Pressure_UserP, userdata(tabcontrol)="tab_DataAcq_Pressure"
	TitleBox title_Settings_Pressure_UserP, userdata(ResizeControlsInfo)=A"!!,Gs!!#BQ!!#@^!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox title_Settings_Pressure_UserP, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	TitleBox title_Settings_Pressure_UserP, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	TitleBox title_Settings_Pressure_UserP, frame=0
	CheckBox check_DataACq_Pressure_User, pos={187.00, 268.00}, size={79.00, 15.00}, disable=1, proc=DAP_CheckProc_Settings_PUser
	CheckBox check_DataACq_Pressure_User, title=" User access"
	CheckBox check_DataACq_Pressure_User, help={"Routes pressure access between the user and the active headstage (selected by the slider)."}
	CheckBox check_DataACq_Pressure_User, userdata(tabcontrol)="tab_DataAcq_Pressure"
	CheckBox check_DataACq_Pressure_User, userdata(ResizeControlsInfo)=A"!!,GR!!#BCJ,hp+!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_DataACq_Pressure_User, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_DataACq_Pressure_User, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_DataACq_Pressure_User, value=0
	CheckBox check_DataACq_Pressure_AutoOFF, pos={105.00, 321.00}, size={92.00, 15.00}, disable=1, proc=DAP_CheckProc_Settings_PUser
	CheckBox check_DataACq_Pressure_AutoOFF, title="Auto User OFF"
	CheckBox check_DataACq_Pressure_AutoOFF, help={"Turns OFF user access when a new HS is selected by the user."}
	CheckBox check_DataACq_Pressure_AutoOFF, userdata(tabnum)="2"
	CheckBox check_DataACq_Pressure_AutoOFF, userdata(tabcontrol)="tab_DataAcq_Pressure"
	CheckBox check_DataACq_Pressure_AutoOFF, userdata(ResizeControlsInfo)=A"!!,F9!!#BZJ,hpE!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_DataACq_Pressure_AutoOFF, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_DataACq_Pressure_AutoOFF, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_DataACq_Pressure_AutoOFF, value=0
	GroupBox group_DA_All, pos={12.00, 441.00}, size={471.00, 72.00}, disable=1
	GroupBox group_DA_All, title="All", userdata(tabnum)="1"
	GroupBox group_DA_All, userdata(tabcontrol)="ADC"
	GroupBox group_DA_All, userdata(ResizeControlsInfo)=A"!!,A>!!#CB!!#CPJ,hp#z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	GroupBox group_DA_All, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	GroupBox group_DA_All, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_DA_AllVClamp, pos={18.00, 543.00}, size={23.00, 15.00}, disable=1, proc=DAP_CheckProc_Channel_All
	CheckBox Check_DA_AllVClamp, title="X", userdata(tabnum)="1"
	CheckBox Check_DA_AllVClamp, userdata(tabcontrol)="ADC"
	CheckBox Check_DA_AllVClamp, userdata(ResizeControlsInfo)=A"!!,BQ!!#Cl^]6[)!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_DA_AllVClamp, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_DA_AllVClamp, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_DA_AllVClamp, userdata(Config_RestorePriority)="60", value=0, side=1
	PopupMenu Wave_DA_AllVClamp, pos={145.00, 543.00}, size={125.00, 19.00}, bodyWidth=125, disable=1, proc=DAP_PopMenuChkProc_StimSetList
	PopupMenu Wave_DA_AllVClamp, userdata(tabnum)="1", userdata(tabcontrol)="ADC"
	PopupMenu Wave_DA_AllVClamp, userdata(ResizeControlsInfo)=A"!!,G)!!#Cm5QF.I!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Wave_DA_AllVClamp, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Wave_DA_AllVClamp, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Wave_DA_AllVClamp, userdata(Config_RestorePriority)="60", fSize=10
	PopupMenu Wave_DA_AllVClamp, mode=1, popvalue="- none -", value=#"\"- none -;\"+ST_GetStimsetList(channelType = 0, searchString = \"*\")"
	SetVariable Search_DA_AllVClamp, pos={153.00, 567.00}, size={123.00, 18.00}, disable=1, proc=DAP_SetVarProc_Channel_Search
	SetVariable Search_DA_AllVClamp, title="Search filter", userdata(tabnum)="1"
	SetVariable Search_DA_AllVClamp, userdata(tabcontrol)="ADC"
	SetVariable Search_DA_AllVClamp, userdata(ResizeControlsInfo)=A"!!,G*!!#Cs5QF.G!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Search_DA_AllVClamp, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Search_DA_AllVClamp, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Search_DA_AllVClamp, userdata(Config_RestorePriority)="60"
	SetVariable Search_DA_AllVClamp, value=_STR:""
	SetVariable Scale_DA_AllVClamp, pos={280.00, 543.00}, size={50.00, 18.00}, bodyWidth=50, disable=1, proc=DAP_SetVarProc_DA_Scale
	SetVariable Scale_DA_AllVClamp, userdata(tabnum)="1", userdata(tabcontrol)="ADC"
	SetVariable Scale_DA_AllVClamp, userdata(ResizeControlsInfo)=A"!!,HK!!#Cm5QF,A!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Scale_DA_AllVClamp, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Scale_DA_AllVClamp, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Scale_DA_AllVClamp, userdata(Config_RestorePriority)="60"
	SetVariable Scale_DA_AllVClamp, userdata(DefaultIncrement)="10"
	SetVariable Scale_DA_AllVClamp, limits={-Inf, Inf, 10}, value=_NUM:1
	PopupMenu IndexEnd_DA_AllVClamp, pos={346.00, 543.00}, size={125.00, 19.00}, bodyWidth=125, disable=1, proc=DAP_PopMenuChkProc_StimSetList
	PopupMenu IndexEnd_DA_AllVClamp, userdata(tabnum)="1", userdata(tabcontrol)="ADC"
	PopupMenu IndexEnd_DA_AllVClamp, userdata(ResizeControlsInfo)=A"!!,HkJ,htC5QF.I!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu IndexEnd_DA_AllVClamp, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu IndexEnd_DA_AllVClamp, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu IndexEnd_DA_AllVClamp, userdata(Config_RestorePriority)="60"
	PopupMenu IndexEnd_DA_AllVClamp, mode=1, popvalue="- none -", value=#"\"- none -;\"+ST_GetStimsetList(channelType = 0, searchString = \"*\")"
	GroupBox group_DA_AllVClamp, pos={12.00, 522.00}, size={471.00, 72.00}, disable=1
	GroupBox group_DA_AllVClamp, title="V-Clamp", userdata(tabnum)="1"
	GroupBox group_DA_AllVClamp, userdata(tabcontrol)="ADC"
	GroupBox group_DA_AllVClamp, userdata(ResizeControlsInfo)=A"!!,A>!!#Ch!!#CPJ,hp#z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	GroupBox group_DA_AllVClamp, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	GroupBox group_DA_AllVClamp, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_DA_AllIClamp, pos={18.00, 624.00}, size={23.00, 15.00}, disable=1, proc=DAP_CheckProc_Channel_All
	CheckBox Check_DA_AllIClamp, title="X", userdata(tabnum)="1"
	CheckBox Check_DA_AllIClamp, userdata(tabcontrol)="ADC"
	CheckBox Check_DA_AllIClamp, userdata(ResizeControlsInfo)=A"!!,BQ!!#D,J,hm>!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_DA_AllIClamp, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_DA_AllIClamp, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_DA_AllIClamp, userdata(Config_RestorePriority)="60", value=0, side=1
	PopupMenu Wave_DA_AllIClamp, pos={145.00, 627.00}, size={125.00, 19.00}, bodyWidth=125, disable=1, proc=DAP_PopMenuChkProc_StimSetList
	PopupMenu Wave_DA_AllIClamp, userdata(tabnum)="1", userdata(tabcontrol)="ADC"
	PopupMenu Wave_DA_AllIClamp, userdata(ResizeControlsInfo)=A"!!,G)!!#D-!!#@^!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Wave_DA_AllIClamp, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Wave_DA_AllIClamp, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Wave_DA_AllIClamp, userdata(Config_RestorePriority)="60", fSize=10
	PopupMenu Wave_DA_AllIClamp, mode=1, popvalue="- none -", value=#"\"- none -;\"+ST_GetStimsetList(channelType = 0, searchString = \"*\")"
	SetVariable Search_DA_AllIClamp, pos={153.00, 651.00}, size={123.00, 18.00}, disable=1, proc=DAP_SetVarProc_Channel_Search
	SetVariable Search_DA_AllIClamp, title="Search filter", userdata(tabnum)="1"
	SetVariable Search_DA_AllIClamp, userdata(tabcontrol)="ADC"
	SetVariable Search_DA_AllIClamp, userdata(ResizeControlsInfo)=A"!!,G*!!#D3!!#@\\!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Search_DA_AllIClamp, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Search_DA_AllIClamp, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Search_DA_AllIClamp, userdata(Config_RestorePriority)="60"
	SetVariable Search_DA_AllIClamp, value=_STR:""
	SetVariable Scale_DA_AllIClamp, pos={280.00, 627.00}, size={50.00, 18.00}, bodyWidth=50, disable=1, proc=DAP_SetVarProc_DA_Scale
	SetVariable Scale_DA_AllIClamp, userdata(tabnum)="1", userdata(tabcontrol)="ADC"
	SetVariable Scale_DA_AllIClamp, userdata(ResizeControlsInfo)=A"!!,HK!!#D-!!#>V!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Scale_DA_AllIClamp, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Scale_DA_AllIClamp, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Scale_DA_AllIClamp, userdata(Config_RestorePriority)="60"
	SetVariable Scale_DA_AllIClamp, userdata(DefaultIncrement)="10"
	SetVariable Scale_DA_AllIClamp, limits={-Inf, Inf, 10}, value=_NUM:1
	PopupMenu IndexEnd_DA_AllIClamp, pos={346.00, 627.00}, size={125.00, 19.00}, bodyWidth=125, disable=1, proc=DAP_PopMenuChkProc_StimSetList
	PopupMenu IndexEnd_DA_AllIClamp, userdata(tabnum)="1", userdata(tabcontrol)="ADC"
	PopupMenu IndexEnd_DA_AllIClamp, userdata(ResizeControlsInfo)=A"!!,Hl!!#D-!!#@^!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu IndexEnd_DA_AllIClamp, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu IndexEnd_DA_AllIClamp, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu IndexEnd_DA_AllIClamp, userdata(Config_RestorePriority)="60"
	PopupMenu IndexEnd_DA_AllIClamp, mode=1, popvalue="- none -", value=#"\"- none -;\"+ST_GetStimsetList(channelType = 0, searchString = \"*\")"
	GroupBox group_DA_AllIClamp, pos={12.00, 606.00}, size={471.00, 72.00}, disable=1
	GroupBox group_DA_AllIClamp, title="I-Clamp", userdata(tabnum)="1"
	GroupBox group_DA_AllIClamp, userdata(tabcontrol)="ADC"
	GroupBox group_DA_AllIClamp, userdata(ResizeControlsInfo)=A"!!,AN!!#D'^]6afJ,hp#z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	GroupBox group_DA_AllIClamp, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	GroupBox group_DA_AllIClamp, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Radio_ClampMode_AllVClamp, pos={399.00, 60.00}, size={14.00, 14.00}, disable=1, proc=DAP_CheckProc_ClampMode
	CheckBox Radio_ClampMode_AllVClamp, title="", userdata(tabnum)="0"
	CheckBox Radio_ClampMode_AllVClamp, userdata(tabcontrol)="ADC"
	CheckBox Radio_ClampMode_AllVClamp, userdata(ResizeControlsInfo)=A"!!,I.!!#?1!!#;]!!#;]z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Radio_ClampMode_AllVClamp, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Radio_ClampMode_AllVClamp, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Radio_ClampMode_AllVClamp, userdata(Config_RestorePriority)="29"
	CheckBox Radio_ClampMode_AllVClamp, userdata(Config_NiceName)="Headstage_All_VC"
	CheckBox Radio_ClampMode_AllVClamp, value=0, mode=1
	CheckBox Radio_ClampMode_AllIZero, pos={399.00, 180.00}, size={14.00, 14.00}, disable=1, proc=DAP_CheckProc_ClampMode
	CheckBox Radio_ClampMode_AllIZero, title="", userdata(tabnum)="2"
	CheckBox Radio_ClampMode_AllIZero, userdata(tabcontrol)="tab_DataAcq_Amp"
	CheckBox Radio_ClampMode_AllIZero, userdata(ResizeControlsInfo)=A"!!,I6!!#AF!!#;]!!#;]z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Radio_ClampMode_AllIZero, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Radio_ClampMode_AllIZero, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Radio_ClampMode_AllIZero, userdata(Config_RestorePriority)="29"
	CheckBox Radio_ClampMode_AllIZero, userdata(Config_NiceName)="Headstage_All_IZero"
	CheckBox Radio_ClampMode_AllIZero, value=0, mode=1
	CheckBox Check_DataAcqHS_All, pos={399.00, 84.00}, size={30.00, 15.00}, disable=1, proc=DAP_CheckProc_HedstgeChck
	CheckBox Check_DataAcqHS_All, title="All", userdata(tabnum)="0"
	CheckBox Check_DataAcqHS_All, userdata(tabcontrol)="ADC"
	CheckBox Check_DataAcqHS_All, userdata(ResizeControlsInfo)=A"!!,I.!!#?c!!#=K!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_DataAcqHS_All, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_DataAcqHS_All, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_DataAcqHS_All, userdata(Config_RestorePriority)="60", value=0
	CheckBox check_Settings_TP_SaveTP, pos={340.00, 132.00}, size={118.00, 15.00}, disable=1, proc=DAP_CheckProc_UpdateGuiState
	CheckBox check_Settings_TP_SaveTP, title="Save each testpulse"
	CheckBox check_Settings_TP_SaveTP, help={"Store the complete scaled testpulse for each run (requires loads of RAM)"}
	CheckBox check_Settings_TP_SaveTP, userdata(tabnum)="5"
	CheckBox check_Settings_TP_SaveTP, userdata(tabcontrol)="ADC"
	CheckBox check_Settings_TP_SaveTP, userdata(ResizeControlsInfo)=A"!!,HmJ,hq?!!#?s!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_Settings_TP_SaveTP, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_Settings_TP_SaveTP, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox check_Settings_TP_SaveTP, value=0
	Button Button_DataAcq_SkipForward, pos={342.00, 591.00}, size={50.00, 18.00}, disable=1, proc=DAP_ButtonProc_skipSweep
	Button Button_DataAcq_SkipForward, title="Skip\\Z12 >>", userdata(tabnum)="0"
	Button Button_DataAcq_SkipForward, userdata(tabcontrol)="ADC", labelBack=(0, 0, 0)
	Button Button_DataAcq_SkipForward, fStyle=1, fColor=(4369, 4369, 4369, 6554)
	Button Button_DataAcq_SkipForward, valueColor=(65535, 65535, 65535)
	Button Button_DataAcq_SkipBackwards, pos={105.00, 591.00}, size={50.00, 18.00}, disable=1, proc=DAP_ButtonProc_skipBack
	Button Button_DataAcq_SkipBackwards, title="<<Skip", userdata(tabnum)="0"
	Button Button_DataAcq_SkipBackwards, userdata(tabcontrol)="ADC", labelBack=(0, 0, 0)
	Button Button_DataAcq_SkipBackwards, fStyle=1, fColor=(4369, 4369, 4369)
	Button Button_DataAcq_SkipBackwards, valueColor=(65535, 65535, 65535)
	SetVariable SetVar_DataAcq_skipAhead, pos={40.00, 732.00}, size={96.00, 33.00}, bodyWidth=35, disable=1, proc=DAP_SetVarProc_skipAhead
	SetVariable SetVar_DataAcq_skipAhead, title="Skip ahead\r(sweeps)"
	SetVariable SetVar_DataAcq_skipAhead, help={"Skip sweeps in selected stimulus set(s) on data acquisition initialization."}
	SetVariable SetVar_DataAcq_skipAhead, userdata(tabnum)="0"
	SetVariable SetVar_DataAcq_skipAhead, userdata(tabcontrol)="ADC"
	SetVariable SetVar_DataAcq_skipAhead, limits={0, 0, 1}, value=_NUM:0
	CheckBox check_DA_applyOnModeSwitch, pos={345.00, 690.00}, size={135.00, 15.00}, disable=1, proc=DAP_CheckProc_UpdateGuiState
	CheckBox check_DA_applyOnModeSwitch, title="Apply on mode switch"
	CheckBox check_DA_applyOnModeSwitch, help={"Apply clamp mode all-channel DA settings on mode switch"}
	CheckBox check_DA_applyOnModeSwitch, userdata(tabnum)="1"
	CheckBox check_DA_applyOnModeSwitch, userdata(tabcontrol)="ADC", value=0, side=1
	SetVariable setvar_Settings_AutoBiasPerc, pos={75.00, 703.00}, size={111.00, 18.00}, disable=1, proc=DAP_SetVar_UpdateGuiState
	SetVariable setvar_Settings_AutoBiasPerc, title="Autobias (%)"
	SetVariable setvar_Settings_AutoBiasPerc, help={"Autobias percentage"}
	SetVariable setvar_Settings_AutoBiasPerc, userdata(tabnum)="5"
	SetVariable setvar_Settings_AutoBiasPerc, userdata(tabcontrol)="ADC"
	SetVariable setvar_Settings_AutoBiasPerc, limits={1, 100, 1}, value=_NUM:15
	SetVariable setvar_Settings_AutoBiasInt, pos={30.00, 723.00}, size={156.00, 18.00}, disable=1, proc=DAP_SetVar_UpdateGuiState
	SetVariable setvar_Settings_AutoBiasInt, title="Autobias interval (s)"
	SetVariable setvar_Settings_AutoBiasInt, help={"Autobias interval"}
	SetVariable setvar_Settings_AutoBiasInt, userdata(tabnum)="5"
	SetVariable setvar_Settings_AutoBiasInt, userdata(tabcontrol)="ADC"
	SetVariable setvar_Settings_AutoBiasInt, limits={0.25, 1000, 0.25}, value=_NUM:1
	CheckBox Check_Settings_ITImanualStart, pos={33.00, 300.00}, size={201.00, 15.00}, disable=1, proc=DAP_CheckProc_UpdateGuiState
	CheckBox Check_Settings_ITImanualStart, title="Respect ITI for manual initialization"
	CheckBox Check_Settings_ITImanualStart, help={"Ensure that the ITI is reached even when manually stopping and starting sweeps."}
	CheckBox Check_Settings_ITImanualStart, userdata(tabnum)="5"
	CheckBox Check_Settings_ITImanualStart, userdata(tabcontrol)="ADC", value=0
	PopupMenu Popup_Settings_FixedFreq, pos={218.00, 210.00}, size={220.00, 19.00}, bodyWidth=80, disable=1, proc=DAP_PopMenuProc_FixedSampInt
	PopupMenu Popup_Settings_FixedFreq, title="Sampling frequency [kHz]"
	PopupMenu Popup_Settings_FixedFreq, help={"NI and ITC hardware:\r\tAcquire all channels with the given fixed sampling frequency.\rSUTTER hardware:\r\tAD channels are acquired with the given fixed frequency.\r\tDA and TTL channels run with the maximum supported frequency\rWhen \"Maximum\" is selected the \"Sampling interval multiplier\" may be applied to reduce the frequency.\rThe testpulse will always be sampled at the highest possible frequency."}
	PopupMenu Popup_Settings_FixedFreq, userdata(tabnum)="5"
	PopupMenu Popup_Settings_FixedFreq, userdata(tabcontrol)="ADC"
	PopupMenu Popup_Settings_FixedFreq, mode=1, popvalue="Maximum", value=#"DAP_GetSamplingFrequencies()"
	TitleBox Title_settings_Hardware_UPress, pos={42.00, 597.00}, size={70.00, 15.00}
	TitleBox Title_settings_Hardware_UPress, title="User Pressure"
	TitleBox Title_settings_Hardware_UPress, userdata(tabnum)="6"
	TitleBox Title_settings_Hardware_UPress, userdata(tabcontrol)="ADC", frame=0
	PopupMenu popup_Settings_UserPressure, pos={32.00, 618.00}, size={219.00, 19.00}, bodyWidth=150, proc=DAP_PopMenuProc_UpdateGuiState
	PopupMenu popup_Settings_UserPressure, title="DAC devices"
	PopupMenu popup_Settings_UserPressure, help={"List of available DAC devices for pressure control"}
	PopupMenu popup_Settings_UserPressure, userdata(tabnum)="6"
	PopupMenu popup_Settings_UserPressure, userdata(tabcontrol)="ADC"
	PopupMenu popup_Settings_UserPressure, userdata(Config_RestorePriority)="60"
	PopupMenu popup_Settings_UserPressure, userdata(Config_DontSave)="1"
	PopupMenu popup_Settings_UserPressure, userdata(Config_DontRestore)="1"
	PopupMenu popup_Settings_UserPressure, mode=1, popvalue="- none -", value=#"\"- none -;\""
	PopupMenu Popup_Settings_UserPressure_ADC, pos={267.00, 618.00}, size={47.00, 19.00}, proc=DAP_PopMenuProc_UpdateGuiState
	PopupMenu Popup_Settings_UserPressure_ADC, title="AD", userdata(tabnum)="6"
	PopupMenu Popup_Settings_UserPressure_ADC, userdata(tabcontrol)="ADC"
	PopupMenu Popup_Settings_UserPressure_ADC, userdata(Config_DontSave)="1"
	PopupMenu Popup_Settings_UserPressure_ADC, userdata(Config_DontRestore)="1"
	PopupMenu Popup_Settings_UserPressure_ADC, mode=1, popvalue="0", value=#"\"0;1;2;3;4;5;6;7;8;9;10;11;12;13;14;15\""
	Button button_Hardware_PUser_Enable, pos={336.00, 597.00}, size={60.00, 45.00}, proc=P_ButtonProc_UserPressure
	Button button_Hardware_PUser_Enable, title="Enable"
	Button button_Hardware_PUser_Enable, help={"Enable device for user pressure acquisition"}
	Button button_Hardware_PUser_Enable, userdata(tabnum)="6"
	Button button_Hardware_PUser_Enable, userdata(tabcontrol)="ADC", fSize=14
	Button button_Hardware_PUser_Disable, pos={399.00, 597.00}, size={60.00, 45.00}, disable=2, proc=P_ButtonProc_UserPressure
	Button button_Hardware_PUser_Disable, title="Disable"
	Button button_Hardware_PUser_Disable, help={"Disable device for user pressure acquisition"}
	Button button_Hardware_PUser_Disable, userdata(tabnum)="6"
	Button button_Hardware_PUser_Disable, userdata(tabcontrol)="ADC", fSize=14
	PopupMenu Popup_Settings_OsciUpdMode, pos={260.00, 576.00}, size={160.00, 19.00}, bodyWidth=80, disable=1, proc=DAP_PopMenuProc_OsciUpdMode
	PopupMenu Popup_Settings_OsciUpdMode, title="Update Y scale"
	PopupMenu Popup_Settings_OsciUpdMode, help={"Update mode of Y scale of graphs in oscilloscope window with TP"}
	PopupMenu Popup_Settings_OsciUpdMode, userdata(tabnum)="5"
	PopupMenu Popup_Settings_OsciUpdMode, userdata(tabcontrol)="ADC"
	PopupMenu Popup_Settings_OsciUpdMode, mode=3, popvalue="Interval", value=#"DAP_GetOsciUpdModes()"
	SetVariable setvar_Settings_OsciUpdInt, pos={260.00, 618.00}, size={161.00, 18.00}, bodyWidth=50, disable=1, proc=DAP_SetVar_UpdateGuiState
	SetVariable setvar_Settings_OsciUpdInt, title="Update interval [ms]"
	SetVariable setvar_Settings_OsciUpdInt, help={"Oscilloscope update interval for scales\r Y scale is updated depending on selected mode"}
	SetVariable setvar_Settings_OsciUpdInt, userdata(tabnum)="5"
	SetVariable setvar_Settings_OsciUpdInt, userdata(tabcontrol)="ADC"
	SetVariable setvar_Settings_OsciUpdInt, limits={0, 60000, 50}, value=_NUM:500
	SetVariable setvar_Settings_OsciUpdExt, pos={262.00, 597.00}, size={181.00, 18.00}, bodyWidth=45, disable=1, proc=DAP_SetVar_UpdateGuiState
	SetVariable setvar_Settings_OsciUpdExt, title="Y axis scale extension [%]"
	SetVariable setvar_Settings_OsciUpdExt, help={"Oscilloscope update axis extension for Interval mode"}
	SetVariable setvar_Settings_OsciUpdExt, userdata(tabnum)="5"
	SetVariable setvar_Settings_OsciUpdExt, userdata(tabcontrol)="ADC"
	SetVariable setvar_Settings_OsciUpdExt, limits={0, 1000, 1}, value=_NUM:10
	PopupMenu Popup_Settings_DecMethod, pos={40.00, 582.00}, size={189.00, 19.00}, bodyWidth=80, disable=1, proc=DAP_PopMenuProc_UpdateGuiState
	PopupMenu Popup_Settings_DecMethod, title="Decimation Method"
	PopupMenu Popup_Settings_DecMethod, help={"Decimation methods for speeding up the display"}
	PopupMenu Popup_Settings_DecMethod, userdata(tabnum)="5"
	PopupMenu Popup_Settings_DecMethod, userdata(tabcontrol)="ADC"
	PopupMenu Popup_Settings_DecMethod, mode=2, popvalue="MinMax", value=#"\"None;MinMax\""
	GroupBox group_acq_tp, pos={243.00, 554.00}, size={212.00, 87.00}, disable=1
	GroupBox group_acq_tp, title="Testpulse", userdata(tabnum)="5"
	GroupBox group_acq_tp, userdata(tabcontrol)="ADC"
	GroupBox group_acq_daq, pos={31.00, 554.00}, size={208.00, 62.00}, disable=1
	GroupBox group_acq_daq, title="Data Acquisition", userdata(tabnum)="5"
	GroupBox group_acq_daq, userdata(tabcontrol)="ADC"
	Button button_hardware_rescan, pos={32.00, 72.00}, size={42.00, 39.00}, proc=ButtonProc_Hardware_rescan
	Button button_hardware_rescan, title=""
	Button button_hardware_rescan, help={"Rescan the PC for ITC and NI DAQ hardware"}
	Button button_hardware_rescan, userdata(tabnum)="6", userdata(tabcontrol)="ADC"
	Button button_hardware_rescan, userdata(Config_RestorePriority)="1"
	Button button_hardware_rescan, fColor=(65535, 65535, 65535)
	Button button_hardware_rescan, picture=ProcGlobal#HardwareScanButton
	SetVariable setvar_Settings_autoTP_perc, pos={164.00, 154.00}, size={137.00, 18.00}, disable=1, proc=DAP_SetVarProc_TestPulseSett
	SetVariable setvar_Settings_autoTP_perc, title="Auto TP Amp (%)"
	SetVariable setvar_Settings_autoTP_perc, help={"Automatic amplitude percentage"}
	SetVariable setvar_Settings_autoTP_perc, userdata(tabnum)="5"
	SetVariable setvar_Settings_autoTP_perc, userdata(tabcontrol)="ADC"
	SetVariable setvar_Settings_autoTP_perc, limits={1, 100, 1}, value=_NUM:90
	SetVariable setvar_Settings_autoTP_int, pos={303.00, 154.00}, size={156.00, 18.00}, disable=1, proc=DAP_SetVarProc_TestPulseSett
	SetVariable setvar_Settings_autoTP_int, title="Auto TP interval (s)"
	SetVariable setvar_Settings_autoTP_int, help={"Auto TP Amplitude and baseline interval"}
	SetVariable setvar_Settings_autoTP_int, userdata(tabnum)="5"
	SetVariable setvar_Settings_autoTP_int, userdata(tabcontrol)="ADC"
	SetVariable setvar_Settings_autoTP_int, limits={0, 1000, 0.25}, value=_NUM:0
	SetVariable setvar_DataAcq_targetVoltage, pos={303.00, 427.00}, size={96.00, 18.00}, bodyWidth=50, disable=1, proc=DAP_SetVarProc_TestPulseSett
	SetVariable setvar_DataAcq_targetVoltage, title="\\[0Vm \\Z10(mV)\\]0"
	SetVariable setvar_DataAcq_targetVoltage, help={"Target voltage for auto amplitude"}
	SetVariable setvar_DataAcq_targetVoltage, userdata(tabnum)="0"
	SetVariable setvar_DataAcq_targetVoltage, userdata(tabcontrol)="ADC"
	SetVariable setvar_DataAcq_targetVoltage, userdata(ResizeControlsInfo)=A"!!,HJJ,hr?!!#@.!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_DataAcq_targetVoltage, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable setvar_DataAcq_targetVoltage, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable setvar_DataAcq_targetVoltage, userdata(Config_DontRestore)="1"
	SetVariable setvar_DataAcq_targetVoltage, userdata(Config_DontSave)="1"
	SetVariable setvar_DataAcq_targetVoltage, limits={-99, 99, 1}, value=_NUM:-5
	SetVariable setvar_DataAcq_targetVoltageRange, pos={402.00, 427.00}, size={62.00, 18.00}, bodyWidth=50, disable=1, proc=DAP_SetVarProc_TestPulseSett
	SetVariable setvar_DataAcq_targetVoltageRange, title="±"
	SetVariable setvar_DataAcq_targetVoltageRange, help={"± voltage range for auto amplitude"}
	SetVariable setvar_DataAcq_targetVoltageRange, userdata(tabcontrol)="ADC"
	SetVariable setvar_DataAcq_targetVoltageRange, userdata(tabnum)="0"
	SetVariable setvar_DataAcq_targetVoltageRange, userdata(ResizeControlsInfo)=A"!!,I*!!#Ai!!#?1!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_DataAcq_targetVoltageRange, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable setvar_DataAcq_targetVoltageRange, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable setvar_DataAcq_targetVoltageRange, userdata(Config_DontRestore)="1"
	SetVariable setvar_DataAcq_targetVoltageRange, userdata(Config_DontSave)="1"
	SetVariable setvar_DataAcq_targetVoltageRange, limits={0, Inf, 1}, value=_NUM:0.5
	SetVariable setvar_DataAcq_IinjMax, pos={337.00, 405.00}, size={127.00, 20.00}, bodyWidth=50, disable=1, proc=DAP_SetVarProc_TestPulseSett
	SetVariable setvar_DataAcq_IinjMax, title="\\[0max I \\Binj\\M \\Z10(pA)\\]0 ±"
	SetVariable setvar_DataAcq_IinjMax, help={"Maximum current to inject for auto amplitude"}
	SetVariable setvar_DataAcq_IinjMax, userdata(tabcontrol)="ADC"
	SetVariable setvar_DataAcq_IinjMax, userdata(tabnum)="0"
	SetVariable setvar_DataAcq_IinjMax, userdata(ResizeControlsInfo)=A"!!,HP!!#B+!!#@l!!#<Xz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_DataAcq_IinjMax, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable setvar_DataAcq_IinjMax, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable setvar_DataAcq_IinjMax, userdata(Config_DontRestore)="1"
	SetVariable setvar_DataAcq_IinjMax, userdata(Config_DontSave)="1"
	SetVariable setvar_DataAcq_IinjMax, limits={1, 1500, 1}, value=_NUM:200
	CheckBox check_DataAcq_AutoTP, pos={275.00, 407.00}, size={59.00, 15.00}, disable=1, proc=DAP_CheckProc_TestPulseSett
	CheckBox check_DataAcq_AutoTP, title="Auto TP"
	CheckBox check_DataAcq_AutoTP, help={"Auto TP amplitude and baseline tuning. Green background indicates active TP tuning on at least one headstage."}
	CheckBox check_DataAcq_AutoTP, userdata(tabnum)="0", userdata(tabcontrol)="ADC"
	CheckBox check_DataAcq_AutoTP, userdata(ResizeControlsInfo)=A"!!,H[J,hr+!!#?;!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_DataAcq_AutoTP, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_DataAcq_AutoTP, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox check_DataAcq_AutoTP, userdata(Config_DontRestore)="1"
	CheckBox check_DataAcq_AutoTP, userdata(Config_DontSave)="1", value=0, side=1
	CheckBox Check_TP_SendToAllHS, pos={184.00, 417.00}, size={14.00, 14.00}, disable=1, proc=DAP_CheckProc_TestPulseSett
	CheckBox Check_TP_SendToAllHS, title=""
	CheckBox Check_TP_SendToAllHS, help={"Set Testpulse settings from this group to all headstages (checked) or only the currently selected one (unchecked)."}
	CheckBox Check_TP_SendToAllHS, userdata(tabnum)="0", userdata(tabcontrol)="ADC"
	CheckBox Check_TP_SendToAllHS, userdata(ResizeControlsInfo)=A"!!,Ff!!#?e!!#<`!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_TP_SendToAllHS, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_TP_SendToAllHS, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_TP_SendToAllHS, value=1, side=1
	GroupBox group_testpulse_indep_headstage_sep, pos={162.00, 404.00}, size={4.00, 43.00}, disable=1
	GroupBox group_testpulse_indep_headstage_sep, userdata(tabnum)="0"
	GroupBox group_testpulse_indep_headstage_sep, userdata(tabcontrol)="ADC", frame=0
	GroupBox group_autobias, pos={277.00, 196.00}, size={165.00, 66.00}, disable=1
	GroupBox group_autobias, userdata(tabnum)="1"
	GroupBox group_autobias, userdata(tabcontrol)="tab_DataAcq_Amp"
	GroupBox group_autobias, userdata(ResizeControlsInfo)=A"!!,H/!!#A:!!#Aa!!#=Cz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	GroupBox group_autobias, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	GroupBox group_autobias, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	GroupBox group_autobias, userdata(Config_DontRestore)="1"
	GroupBox group_autobias, userdata(Config_DontSave)="1"
	CheckBox Radio_ClampMode_1, pos={129.00, 111.00}, size={14.00, 14.00}, disable=1, proc=DAP_CheckProc_ClampMode
	CheckBox Radio_ClampMode_1, title="", userdata(tabnum)="0"
	CheckBox Radio_ClampMode_1, userdata(tabcontrol)="ADC"
	CheckBox Radio_ClampMode_1, userdata(ResizeControlsInfo)=A"!!,Ff!!#@B!!#;]!!#;]z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Radio_ClampMode_1, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Radio_ClampMode_1, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Radio_ClampMode_1, userdata(Config_RestorePriority)="30"
	CheckBox Radio_ClampMode_1, userdata(Config_NiceName)="Headstage_0_IC"
	CheckBox Radio_ClampMode_1, value=0, mode=1
	CheckBox Radio_ClampMode_3, pos={162.00, 111.00}, size={14.00, 14.00}, disable=1, proc=DAP_CheckProc_ClampMode
	CheckBox Radio_ClampMode_3, title="", userdata(tabnum)="0"
	CheckBox Radio_ClampMode_3, userdata(tabcontrol)="ADC"
	CheckBox Radio_ClampMode_3, userdata(ResizeControlsInfo)=A"!!,G2!!#@B!!#;]!!#;]z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Radio_ClampMode_3, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Radio_ClampMode_3, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Radio_ClampMode_3, userdata(Config_RestorePriority)="30"
	CheckBox Radio_ClampMode_3, userdata(Config_NiceName)="Headstage_1_IC"
	CheckBox Radio_ClampMode_3, value=0, mode=1
	CheckBox Radio_ClampMode_5, pos={195.00, 111.00}, size={14.00, 14.00}, disable=1, proc=DAP_CheckProc_ClampMode
	CheckBox Radio_ClampMode_5, title="", userdata(tabnum)="0"
	CheckBox Radio_ClampMode_5, userdata(tabcontrol)="ADC"
	CheckBox Radio_ClampMode_5, userdata(ResizeControlsInfo)=A"!!,GT!!#@B!!#;]!!#;]z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Radio_ClampMode_5, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Radio_ClampMode_5, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Radio_ClampMode_5, userdata(Config_RestorePriority)="30"
	CheckBox Radio_ClampMode_5, userdata(Config_NiceName)="Headstage_2_IC"
	CheckBox Radio_ClampMode_5, value=0, mode=1
	CheckBox Radio_ClampMode_7, pos={228.00, 111.00}, size={14.00, 14.00}, disable=1, proc=DAP_CheckProc_ClampMode
	CheckBox Radio_ClampMode_7, title="", userdata(tabnum)="0"
	CheckBox Radio_ClampMode_7, userdata(tabcontrol)="ADC"
	CheckBox Radio_ClampMode_7, userdata(ResizeControlsInfo)=A"!!,H!!!#@B!!#;]!!#;]z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Radio_ClampMode_7, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Radio_ClampMode_7, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Radio_ClampMode_7, userdata(Config_RestorePriority)="30"
	CheckBox Radio_ClampMode_7, userdata(Config_NiceName)="Headstage_3_IC"
	CheckBox Radio_ClampMode_7, value=0, mode=1
	CheckBox Radio_ClampMode_9, pos={264.00, 111.00}, size={14.00, 14.00}, disable=1, proc=DAP_CheckProc_ClampMode
	CheckBox Radio_ClampMode_9, title="", userdata(tabnum)="0"
	CheckBox Radio_ClampMode_9, userdata(tabcontrol)="ADC"
	CheckBox Radio_ClampMode_9, userdata(ResizeControlsInfo)=A"!!,H?!!#@B!!#;]!!#;]z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Radio_ClampMode_9, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Radio_ClampMode_9, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Radio_ClampMode_9, userdata(Config_RestorePriority)="30"
	CheckBox Radio_ClampMode_9, userdata(Config_NiceName)="Headstage_4_IC"
	CheckBox Radio_ClampMode_9, value=0, mode=1
	CheckBox Radio_ClampMode_11, pos={297.00, 111.00}, size={14.00, 14.00}, disable=1, proc=DAP_CheckProc_ClampMode
	CheckBox Radio_ClampMode_11, title="", userdata(tabnum)="0"
	CheckBox Radio_ClampMode_11, userdata(tabcontrol)="ADC"
	CheckBox Radio_ClampMode_11, userdata(ResizeControlsInfo)=A"!!,HP!!#@B!!#;]!!#;]z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Radio_ClampMode_11, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Radio_ClampMode_11, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Radio_ClampMode_11, userdata(Config_RestorePriority)="30"
	CheckBox Radio_ClampMode_11, userdata(Config_NiceName)="Headstage_5_IC"
	CheckBox Radio_ClampMode_11, value=0, mode=1
	CheckBox Radio_ClampMode_13, pos={330.00, 111.00}, size={14.00, 14.00}, disable=1, proc=DAP_CheckProc_ClampMode
	CheckBox Radio_ClampMode_13, title="", userdata(tabnum)="0"
	CheckBox Radio_ClampMode_13, userdata(tabcontrol)="ADC"
	CheckBox Radio_ClampMode_13, userdata(ResizeControlsInfo)=A"!!,Ha!!#@B!!#;]!!#;]z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Radio_ClampMode_13, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Radio_ClampMode_13, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Radio_ClampMode_13, userdata(Config_RestorePriority)="30"
	CheckBox Radio_ClampMode_13, userdata(Config_NiceName)="Headstage_6_IC"
	CheckBox Radio_ClampMode_13, value=0, mode=1
	CheckBox Radio_ClampMode_15, pos={366.00, 111.00}, size={14.00, 14.00}, disable=1, proc=DAP_CheckProc_ClampMode
	CheckBox Radio_ClampMode_15, title="", userdata(tabnum)="0"
	CheckBox Radio_ClampMode_15, userdata(tabcontrol)="ADC"
	CheckBox Radio_ClampMode_15, userdata(ResizeControlsInfo)=A"!!,Hr!!#@B!!#;]!!#;]z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Radio_ClampMode_15, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Radio_ClampMode_15, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Radio_ClampMode_15, userdata(Config_RestorePriority)="30"
	CheckBox Radio_ClampMode_15, userdata(Config_NiceName)="Headstage_7_IC"
	CheckBox Radio_ClampMode_15, value=0, mode=1
	CheckBox Radio_ClampMode_AllIClamp, pos={399.00, 111.00}, size={14.00, 14.00}, disable=1, proc=DAP_CheckProc_ClampMode
	CheckBox Radio_ClampMode_AllIClamp, title="", userdata(tabnum)="0"
	CheckBox Radio_ClampMode_AllIClamp, userdata(tabcontrol)="ADC"
	CheckBox Radio_ClampMode_AllIClamp, userdata(ResizeControlsInfo)=A"!!,I.!!#@B!!#;]!!#;]z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Radio_ClampMode_AllIClamp, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Radio_ClampMode_AllIClamp, userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Radio_ClampMode_AllIClamp, userdata(Config_RestorePriority)="29"
	CheckBox Radio_ClampMode_AllIClamp, userdata(Config_NiceName)="Headstage_All_IC"
	CheckBox Radio_ClampMode_AllIClamp, value=0, mode=1
	DefineGuide UGV0={FR, -25}, UGH0={FB, -27}, UGV1={FL, 481}
	SetWindow kwTopWin, hook(cleanup)=DAP_WindowHook
	SetWindow kwTopWin, hook(windowCoordinateSaving)=StoreWindowCoordinatesHook
	SetWindow kwTopWin, userdata(ResizeControlsInfo)=A"!!*'\"z!!#CW!!#Dl5QCcbzzzzzzzzzzzzzzzzzzzz"
	SetWindow kwTopWin, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzzzzzzzzzzzzzzz"
	SetWindow kwTopWin, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzzzzzzzzz!!!"
	SetWindow kwTopWin, userdata(ResizeControlsGuides)="UGV0;UGH0;UGV1;"
	SetWindow kwTopWin, userdata(ResizeControlsInfoUGV0)="NAME:UGV0;WIN:DA_Ephys;TYPE:User;HORIZONTAL:0;POSITION:459.00;GUIDE1:FR;GUIDE2:;RELPOSITION:-25;"
	SetWindow kwTopWin, userdata(ResizeControlsInfoUGH0)="NAME:UGH0;WIN:DA_Ephys;TYPE:User;HORIZONTAL:1;POSITION:854.00;GUIDE1:FB;GUIDE2:;RELPOSITION:-27;"
	SetWindow kwTopWin, userdata(ResizeControlsInfoUGV1)="NAME:UGV1;WIN:DA_Ephys;TYPE:User;HORIZONTAL:0;POSITION:481.00;GUIDE1:FL;GUIDE2:;RELPOSITION:481;"
	SetWindow kwTopWin, userdata(Config_PanelType)="DA_Ephys"
	SetWindow kwTopWin, userdata(Config_RadioCouplingFunc)="DAP_GetRadioButtonCoupling"
	SetWindow kwTopWin, userdata(JSONSettings_StoreCoordinates)="1"
	SetWindow kwTopWin, userdata(JSONSettings_WindowName)="daephys"
EndMacro
