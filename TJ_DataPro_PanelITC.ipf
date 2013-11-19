#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Window datapro_itc1600() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(176,120,651,631)
	ShowTools/A
	TitleBox Title_settings_SetManagement,pos={15,184},size={390,113},title="Set Management Decision Tree"
	TitleBox Title_settings_SetManagement,userdata(tabnum)=  "5"
	TitleBox Title_settings_SetManagement,userdata(tabcontrol)=  "ADC"
	TitleBox Title_settings_SetManagement,font="Trebuchet MS",frame=4,fStyle=0
	TitleBox Title_settings_SetManagement,fixedSize=1
	TitleBox Tiitle_DataAcq_ClampMode,pos={29,30},size={430,106},disable=1,title="Clamp mode"
	TitleBox Tiitle_DataAcq_ClampMode,userdata(tabnum)=  "0"
	TitleBox Tiitle_DataAcq_ClampMode,userdata(tabcontrol)=  "ADC"
	TitleBox Tiitle_DataAcq_ClampMode,userdata(ResizeControlsInfo)= A"!!,Bi!!#>*!!#BqJ,hpcz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox Tiitle_DataAcq_ClampMode,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	TitleBox Tiitle_DataAcq_ClampMode,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	TitleBox Tiitle_DataAcq_ClampMode,font="Trebuchet MS",fSize=13,frame=4,fStyle=1
	TitleBox Tiitle_DataAcq_ClampMode,fixedSize=1
	TitleBox Tiitle_DataAcq_StatusInfo,pos={29,143},size={430,72},disable=1,title="Status Information"
	TitleBox Tiitle_DataAcq_StatusInfo,userdata(tabnum)=  "0"
	TitleBox Tiitle_DataAcq_StatusInfo,userdata(tabcontrol)=  "ADC"
	TitleBox Tiitle_DataAcq_StatusInfo,userdata(ResizeControlsInfo)= A"!!,Ba!!#A'!!#Br!!#?Iz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox Tiitle_DataAcq_StatusInfo,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	TitleBox Tiitle_DataAcq_StatusInfo,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	TitleBox Tiitle_DataAcq_StatusInfo,font="Trebuchet MS",fSize=13,frame=4,fStyle=1
	TitleBox Tiitle_DataAcq_StatusInfo,fixedSize=1
	TitleBox Tiitle_DataAcq_AcqData,pos={28,314},size={430,160},disable=1,title="Data Acquisition"
	TitleBox Tiitle_DataAcq_AcqData,userdata(tabnum)=  "0"
	TitleBox Tiitle_DataAcq_AcqData,userdata(tabcontrol)=  "ADC"
	TitleBox Tiitle_DataAcq_AcqData,userdata(ResizeControlsInfo)= A"!!,BY!!#B\\!!#BrJ,hq@z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox Tiitle_DataAcq_AcqData,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	TitleBox Tiitle_DataAcq_AcqData,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	TitleBox Tiitle_DataAcq_AcqData,labelBack=(60928,60928,60928)
	TitleBox Tiitle_DataAcq_AcqData,font="Trebuchet MS",frame=4,fStyle=1,fixedSize=1
	TitleBox Tiitle_DataAcq_TP,pos={28,221},size={430,87},disable=1,title="Test Pulse"
	TitleBox Tiitle_DataAcq_TP,userdata(tabnum)=  "0",userdata(tabcontrol)=  "ADC"
	TitleBox Tiitle_DataAcq_TP,userdata(ResizeControlsInfo)= A"!!,BY!!#Au!!#BrJ,hp=z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox Tiitle_DataAcq_TP,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	TitleBox Tiitle_DataAcq_TP,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	TitleBox Tiitle_DataAcq_TP,font="Trebuchet MS",frame=4,fStyle=1,fixedSize=1
	TitleBox title_settings_03,pos={15,32},size={390,145},title="Data Acquisition"
	TitleBox title_settings_03,userdata(tabnum)=  "5",userdata(tabcontrol)=  "ADC"
	TitleBox title_settings_03,userdata(ResizeControlsInfo)= A"!!,A.!!#=c!!#Bs!!#?qz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox title_settings_03,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	TitleBox title_settings_03,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	TitleBox title_settings_03,font="Trebuchet MS",frame=4,fStyle=1,fixedSize=1
	TabControl ADC,pos={3,0},size={479,19},proc=ACL_DisplayTab
	TabControl ADC,userdata(currenttab)=  "5",userdata(initialhook)=  "TabTJHook1"
	TabControl ADC,userdata(ResizeControlsInfo)= A"!!,>Mz!!#C:J,hlsz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TabControl ADC,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	TabControl ADC,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	TabControl ADC,tabLabel(0)="Data Acquisition",tabLabel(1)="DAC"
	TabControl ADC,tabLabel(2)="ADC",tabLabel(3)="TTL",tabLabel(4)="Asynchronous"
	TabControl ADC,tabLabel(5)="Settings",tabLabel(6)="Hardware",value= 5
	CheckBox Check_AD_00,pos={15,46},size={42,14},disable=1,title="AD 0"
	CheckBox Check_AD_00,help={"hello!"},userdata(tabnum)=  "2"
	CheckBox Check_AD_00,userdata(tabcontrol)=  "ADC"
	CheckBox Check_AD_00,userdata(ResizeControlsInfo)= A"!!,B)!!#>F!!#>6!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_AD_00,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_AD_00,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_AD_00,value= 1
	CheckBox Check_AD_01,pos={15,92},size={42,14},disable=1,title="AD 1"
	CheckBox Check_AD_01,userdata(tabnum)=  "2",userdata(tabcontrol)=  "ADC"
	CheckBox Check_AD_01,userdata(ResizeControlsInfo)= A"!!,B)!!#?q!!#>6!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_AD_01,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_AD_01,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_AD_01,value= 0
	CheckBox Check_AD_02,pos={15,139},size={42,14},disable=1,title="AD 2"
	CheckBox Check_AD_02,userdata(tabnum)=  "2",userdata(tabcontrol)=  "ADC"
	CheckBox Check_AD_02,userdata(ResizeControlsInfo)= A"!!,B)!!#@o!!#>6!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_AD_02,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_AD_02,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_AD_02,value= 0
	CheckBox Check_AD_03,pos={15,186},size={42,14},disable=1,title="AD 3"
	CheckBox Check_AD_03,userdata(tabnum)=  "2",userdata(tabcontrol)=  "ADC"
	CheckBox Check_AD_03,userdata(ResizeControlsInfo)= A"!!,B)!!#AI!!#>6!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_AD_03,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_AD_03,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_AD_03,value= 0
	CheckBox Check_AD_04,pos={15,233},size={42,14},disable=1,title="AD 4"
	CheckBox Check_AD_04,userdata(tabnum)=  "2",userdata(tabcontrol)=  "ADC"
	CheckBox Check_AD_04,userdata(ResizeControlsInfo)= A"!!,B)!!#B#!!#>6!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_AD_04,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_AD_04,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_AD_04,value= 0
	CheckBox Check_AD_05,pos={15,280},size={42,14},disable=1,title="AD 5"
	CheckBox Check_AD_05,userdata(tabnum)=  "2",userdata(tabcontrol)=  "ADC"
	CheckBox Check_AD_05,userdata(ResizeControlsInfo)= A"!!,B)!!#BF!!#>6!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_AD_05,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_AD_05,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_AD_05,value= 0
	CheckBox Check_AD_06,pos={15,327},size={42,14},disable=1,title="AD 6"
	CheckBox Check_AD_06,userdata(tabnum)=  "2",userdata(tabcontrol)=  "ADC"
	CheckBox Check_AD_06,userdata(ResizeControlsInfo)= A"!!,B)!!#B]J,hna!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_AD_06,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_AD_06,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_AD_06,value= 0
	CheckBox Check_AD_07,pos={15,374},size={42,14},disable=1,title="AD 7"
	CheckBox Check_AD_07,userdata(tabnum)=  "2",userdata(tabcontrol)=  "ADC"
	CheckBox Check_AD_07,userdata(ResizeControlsInfo)= A"!!,B)!!#Bu!!#>6!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_AD_07,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_AD_07,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_AD_07,value= 0
	CheckBox Check_AD_08,pos={169,46},size={42,14},disable=1,title="AD 8"
	CheckBox Check_AD_08,userdata(tabnum)=  "2",userdata(tabcontrol)=  "ADC"
	CheckBox Check_AD_08,userdata(ResizeControlsInfo)= A"!!,G9!!#>F!!#>6!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_AD_08,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_AD_08,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_AD_08,value= 0
	CheckBox Check_AD_09,pos={169,93},size={42,14},disable=1,title="AD 9"
	CheckBox Check_AD_09,userdata(tabnum)=  "2",userdata(tabcontrol)=  "ADC"
	CheckBox Check_AD_09,userdata(ResizeControlsInfo)= A"!!,G9!!#?s!!#>6!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_AD_09,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_AD_09,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_AD_09,value= 0
	CheckBox Check_AD_10,pos={169,140},size={48,14},disable=1,title="AD 10"
	CheckBox Check_AD_10,userdata(tabnum)=  "2",userdata(tabcontrol)=  "ADC"
	CheckBox Check_AD_10,userdata(ResizeControlsInfo)= A"!!,G9!!#@p!!#>N!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_AD_10,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_AD_10,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_AD_10,value= 1
	CheckBox Check_AD_12,pos={169,234},size={48,14},disable=1,title="AD 12"
	CheckBox Check_AD_12,userdata(tabnum)=  "2",userdata(tabcontrol)=  "ADC"
	CheckBox Check_AD_12,userdata(ResizeControlsInfo)= A"!!,G9!!#B$!!#>N!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_AD_12,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_AD_12,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_AD_12,value= 0
	CheckBox Check_AD_11,pos={169,187},size={48,14},disable=1,title="AD 11"
	CheckBox Check_AD_11,userdata(tabnum)=  "2",userdata(tabcontrol)=  "ADC"
	CheckBox Check_AD_11,userdata(ResizeControlsInfo)= A"!!,G9!!#AJ!!#>N!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_AD_11,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_AD_11,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_AD_11,value= 0
	SetVariable Gain_AD_00,pos={70,44},size={75,16},disable=1,title="gain"
	SetVariable Gain_AD_00,help={"hello"},userdata(tabnum)=  "2"
	SetVariable Gain_AD_00,userdata(tabcontrol)=  "ADC"
	SetVariable Gain_AD_00,userdata(ResizeControlsInfo)= A"!!,EF!!#>>!!#?O!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Gain_AD_00,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Gain_AD_00,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Gain_AD_00,limits={0,inf,1},value= _NUM:0.5
	SetVariable Gain_AD_01,pos={70,91},size={75,16},disable=1,title="gain"
	SetVariable Gain_AD_01,userdata(tabnum)=  "2",userdata(tabcontrol)=  "ADC"
	SetVariable Gain_AD_01,userdata(ResizeControlsInfo)= A"!!,EF!!#?o!!#?O!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Gain_AD_01,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Gain_AD_01,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Gain_AD_01,limits={0,inf,1},value= _NUM:0.5
	SetVariable Gain_AD_02,pos={70,138},size={75,16},disable=1,title="gain"
	SetVariable Gain_AD_02,userdata(tabnum)=  "2",userdata(tabcontrol)=  "ADC"
	SetVariable Gain_AD_02,userdata(ResizeControlsInfo)= A"!!,EF!!#@n!!#?O!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Gain_AD_02,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Gain_AD_02,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Gain_AD_02,limits={0,inf,1},value= _NUM:0.5
	SetVariable Gain_AD_03,pos={70,185},size={75,16},disable=1,title="gain"
	SetVariable Gain_AD_03,userdata(tabnum)=  "2",userdata(tabcontrol)=  "ADC"
	SetVariable Gain_AD_03,userdata(ResizeControlsInfo)= A"!!,EF!!#AH!!#?O!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Gain_AD_03,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Gain_AD_03,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Gain_AD_03,limits={0,inf,1},value= _NUM:0.5
	SetVariable Gain_AD_04,pos={70,232},size={75,16},disable=1,title="gain"
	SetVariable Gain_AD_04,userdata(tabnum)=  "2",userdata(tabcontrol)=  "ADC"
	SetVariable Gain_AD_04,userdata(ResizeControlsInfo)= A"!!,EF!!#B\"!!#?O!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Gain_AD_04,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Gain_AD_04,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Gain_AD_04,limits={0,inf,1},value= _NUM:0.5
	SetVariable Gain_AD_05,pos={70,279},size={75,16},disable=1,title="gain"
	SetVariable Gain_AD_05,userdata(tabnum)=  "2",userdata(tabcontrol)=  "ADC"
	SetVariable Gain_AD_05,userdata(ResizeControlsInfo)= A"!!,EF!!#BEJ,hp%!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Gain_AD_05,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Gain_AD_05,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Gain_AD_05,limits={0,inf,1},value= _NUM:0.5
	SetVariable Gain_AD_06,pos={70,326},size={75,16},disable=1,title="gain"
	SetVariable Gain_AD_06,userdata(tabnum)=  "2",userdata(tabcontrol)=  "ADC"
	SetVariable Gain_AD_06,userdata(ResizeControlsInfo)= A"!!,EF!!#B]!!#?O!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Gain_AD_06,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Gain_AD_06,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Gain_AD_06,limits={0,inf,1},value= _NUM:0.5
	SetVariable Gain_AD_07,pos={70,373},size={75,16},disable=1,title="gain"
	SetVariable Gain_AD_07,userdata(tabnum)=  "2",userdata(tabcontrol)=  "ADC"
	SetVariable Gain_AD_07,userdata(ResizeControlsInfo)= A"!!,EF!!#BtJ,hp%!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Gain_AD_07,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Gain_AD_07,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Gain_AD_07,limits={0,inf,1},value= _NUM:0.5
	SetVariable Gain_AD_08,pos={224,45},size={75,16},disable=1,title="gain"
	SetVariable Gain_AD_08,userdata(tabnum)=  "2",userdata(tabcontrol)=  "ADC"
	SetVariable Gain_AD_08,userdata(ResizeControlsInfo)= A"!!,Gp!!#>B!!#?O!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Gain_AD_08,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Gain_AD_08,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Gain_AD_08,limits={0,inf,1},value= _NUM:0.5
	SetVariable Gain_AD_09,pos={224,92},size={75,16},disable=1,title="gain"
	SetVariable Gain_AD_09,userdata(tabnum)=  "2",userdata(tabcontrol)=  "ADC"
	SetVariable Gain_AD_09,userdata(ResizeControlsInfo)= A"!!,Gp!!#?q!!#?O!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Gain_AD_09,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Gain_AD_09,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Gain_AD_09,limits={0,inf,1},value= _NUM:0.5
	SetVariable Gain_AD_10,pos={224,139},size={75,16},disable=1,title="gain"
	SetVariable Gain_AD_10,userdata(tabnum)=  "2",userdata(tabcontrol)=  "ADC"
	SetVariable Gain_AD_10,userdata(ResizeControlsInfo)= A"!!,Gp!!#@o!!#?O!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Gain_AD_10,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Gain_AD_10,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Gain_AD_10,limits={0,inf,1},value= _NUM:0.5
	SetVariable Gain_AD_11,pos={224,186},size={75,16},disable=1,title="gain"
	SetVariable Gain_AD_11,userdata(tabnum)=  "2",userdata(tabcontrol)=  "ADC"
	SetVariable Gain_AD_11,userdata(ResizeControlsInfo)= A"!!,Gp!!#AI!!#?O!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Gain_AD_11,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Gain_AD_11,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Gain_AD_11,limits={0,inf,1},value= _NUM:0.5
	SetVariable Gain_AD_12,pos={224,233},size={75,16},disable=1,title="gain"
	SetVariable Gain_AD_12,userdata(tabnum)=  "2",userdata(tabcontrol)=  "ADC"
	SetVariable Gain_AD_12,userdata(ResizeControlsInfo)= A"!!,Gp!!#B#!!#?O!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Gain_AD_12,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Gain_AD_12,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Gain_AD_12,limits={0,inf,1},value= _NUM:0
	CheckBox Check_AD_13,pos={169,281},size={48,14},disable=1,title="AD 13"
	CheckBox Check_AD_13,userdata(tabnum)=  "2",userdata(tabcontrol)=  "ADC"
	CheckBox Check_AD_13,userdata(ResizeControlsInfo)= A"!!,G9!!#BFJ,ho$!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_AD_13,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_AD_13,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_AD_13,value= 0
	CheckBox Check_AD_14,pos={169,328},size={48,14},disable=1,title="AD 14"
	CheckBox Check_AD_14,userdata(tabnum)=  "2",userdata(tabcontrol)=  "ADC"
	CheckBox Check_AD_14,userdata(ResizeControlsInfo)= A"!!,G9!!#B^!!#>N!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_AD_14,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_AD_14,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_AD_14,value= 0
	CheckBox Check_AD_15,pos={169,375},size={48,14},disable=1,title="AD 15"
	CheckBox Check_AD_15,userdata(tabnum)=  "2",userdata(tabcontrol)=  "ADC"
	CheckBox Check_AD_15,userdata(ResizeControlsInfo)= A"!!,G9!!#BuJ,ho$!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_AD_15,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_AD_15,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_AD_15,value= 0
	SetVariable Gain_AD_13,pos={224,280},size={75,16},disable=1,title="gain"
	SetVariable Gain_AD_13,userdata(tabnum)=  "2",userdata(tabcontrol)=  "ADC"
	SetVariable Gain_AD_13,userdata(ResizeControlsInfo)= A"!!,Gp!!#BF!!#?O!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Gain_AD_13,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Gain_AD_13,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Gain_AD_13,limits={0,inf,1},value= _NUM:0
	SetVariable Gain_AD_14,pos={224,327},size={75,16},disable=1,title="gain"
	SetVariable Gain_AD_14,userdata(tabnum)=  "2",userdata(tabcontrol)=  "ADC"
	SetVariable Gain_AD_14,userdata(ResizeControlsInfo)= A"!!,Gp!!#B]J,hp%!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Gain_AD_14,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Gain_AD_14,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Gain_AD_14,limits={0,inf,1},value= _NUM:0
	SetVariable Gain_AD_15,pos={224,374},size={75,16},disable=1,title="gain"
	SetVariable Gain_AD_15,userdata(tabnum)=  "2",userdata(tabcontrol)=  "ADC"
	SetVariable Gain_AD_15,userdata(ResizeControlsInfo)= A"!!,Gp!!#Bu!!#?O!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Gain_AD_15,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Gain_AD_15,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Gain_AD_15,limits={0,inf,1},value= _NUM:0
	CheckBox Check_DA_00,pos={15,74},size={42,14},disable=1,proc=DAorTTLCheckProc,title="DA 0"
	CheckBox Check_DA_00,help={"hello!"},userdata(tabnum)=  "1"
	CheckBox Check_DA_00,userdata(tabcontrol)=  "ADC"
	CheckBox Check_DA_00,userdata(ResizeControlsInfo)= A"!!,B)!!#?M!!#>6!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_DA_00,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_DA_00,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_DA_00,value= 0
	CheckBox Check_DA_01,pos={15,120},size={42,14},disable=1,proc=DAorTTLCheckProc,title="DA 1"
	CheckBox Check_DA_01,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	CheckBox Check_DA_01,userdata(ResizeControlsInfo)= A"!!,B)!!#@T!!#>6!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_DA_01,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_DA_01,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_DA_01,value= 0
	CheckBox Check_DA_02,pos={15,167},size={42,14},disable=1,proc=DAorTTLCheckProc,title="DA 2"
	CheckBox Check_DA_02,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	CheckBox Check_DA_02,userdata(ResizeControlsInfo)= A"!!,B)!!#A6!!#>6!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_DA_02,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_DA_02,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_DA_02,value= 0
	CheckBox Check_DA_03,pos={15,214},size={42,14},disable=1,proc=DAorTTLCheckProc,title="DA 3"
	CheckBox Check_DA_03,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	CheckBox Check_DA_03,userdata(ResizeControlsInfo)= A"!!,B)!!#Ae!!#>6!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_DA_03,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_DA_03,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_DA_03,value= 0
	CheckBox Check_DA_04,pos={15,260},size={42,14},disable=1,proc=DAorTTLCheckProc,title="DA 4"
	CheckBox Check_DA_04,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	CheckBox Check_DA_04,userdata(ResizeControlsInfo)= A"!!,B)!!#B<!!#>6!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_DA_04,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_DA_04,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_DA_04,value= 0
	CheckBox Check_DA_05,pos={15,307},size={42,14},disable=1,proc=DAorTTLCheckProc,title="DA 5"
	CheckBox Check_DA_05,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	CheckBox Check_DA_05,userdata(ResizeControlsInfo)= A"!!,B)!!#BSJ,hna!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_DA_05,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_DA_05,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_DA_05,value= 0
	CheckBox Check_DA_06,pos={15,354},size={42,14},disable=1,proc=DAorTTLCheckProc,title="DA 6"
	CheckBox Check_DA_06,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	CheckBox Check_DA_06,userdata(ResizeControlsInfo)= A"!!,B)!!#Bk!!#>6!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_DA_06,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_DA_06,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_DA_06,value= 0
	CheckBox Check_DA_07,pos={15,401},size={42,14},disable=1,proc=DAorTTLCheckProc,title="DA 7"
	CheckBox Check_DA_07,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	CheckBox Check_DA_07,userdata(ResizeControlsInfo)= A"!!,B)!!#C-J,hna!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_DA_07,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_DA_07,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_DA_07,value= 0
	SetVariable Gain_DA_00,pos={70,74},size={40,16},disable=1,help={"hello"}
	SetVariable Gain_DA_00,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	SetVariable Gain_DA_00,userdata(ResizeControlsInfo)= A"!!,EF!!#?M!!#>.!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Gain_DA_00,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Gain_DA_00,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Gain_DA_00,limits={0,inf,1},value= _NUM:20
	SetVariable Gain_DA_01,pos={70,120},size={40,16},disable=1
	SetVariable Gain_DA_01,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	SetVariable Gain_DA_01,userdata(ResizeControlsInfo)= A"!!,EF!!#@T!!#>.!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Gain_DA_01,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Gain_DA_01,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Gain_DA_01,limits={0,inf,1},value= _NUM:20
	SetVariable Gain_DA_02,pos={70,167},size={40,16},disable=1
	SetVariable Gain_DA_02,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	SetVariable Gain_DA_02,userdata(ResizeControlsInfo)= A"!!,EF!!#A6!!#>.!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Gain_DA_02,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Gain_DA_02,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Gain_DA_02,limits={0,inf,1},value= _NUM:20
	SetVariable Gain_DA_03,pos={70,214},size={40,16},disable=1
	SetVariable Gain_DA_03,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	SetVariable Gain_DA_03,userdata(ResizeControlsInfo)= A"!!,EF!!#Ae!!#>.!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Gain_DA_03,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Gain_DA_03,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Gain_DA_03,limits={0,inf,1},value= _NUM:20
	SetVariable Gain_DA_04,pos={70,260},size={40,16},disable=1
	SetVariable Gain_DA_04,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	SetVariable Gain_DA_04,userdata(ResizeControlsInfo)= A"!!,EF!!#B<!!#>.!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Gain_DA_04,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Gain_DA_04,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Gain_DA_04,limits={0,inf,1},value= _NUM:20
	SetVariable Gain_DA_05,pos={70,307},size={40,16},disable=1
	SetVariable Gain_DA_05,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	SetVariable Gain_DA_05,userdata(ResizeControlsInfo)= A"!!,EF!!#BSJ,hnY!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Gain_DA_05,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Gain_DA_05,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Gain_DA_05,limits={0,inf,1},value= _NUM:20
	SetVariable Gain_DA_06,pos={70,354},size={40,16},disable=1
	SetVariable Gain_DA_06,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	SetVariable Gain_DA_06,userdata(ResizeControlsInfo)= A"!!,EF!!#Bk!!#>.!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Gain_DA_06,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Gain_DA_06,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Gain_DA_06,limits={0,inf,1},value= _NUM:20
	SetVariable Gain_DA_07,pos={70,401},size={40,16},disable=1
	SetVariable Gain_DA_07,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	SetVariable Gain_DA_07,userdata(ResizeControlsInfo)= A"!!,EF!!#C-J,hnY!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Gain_DA_07,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Gain_DA_07,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Gain_DA_07,limits={0,inf,1},value= _NUM:400
	PopupMenu Wave_DA_00,pos={114,72},size={125,21},bodyWidth=125,disable=1,proc=ITCP_PopMenuCheckProc_DAC
	PopupMenu Wave_DA_00,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	PopupMenu Wave_DA_00,userdata(ResizeControlsInfo)= A"!!,FI!!#?I!!#@^!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Wave_DA_00,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Wave_DA_00,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Wave_DA_00,fSize=7
	PopupMenu Wave_DA_00,mode=1,popvalue="- none -",value= #"\"- none -; TestPulse;alpha_DAC_1;\""
	PopupMenu Wave_DA_01,pos={114,118},size={125,21},bodyWidth=125,disable=1,proc=ITCP_PopMenuCheckProc_DAC
	PopupMenu Wave_DA_01,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	PopupMenu Wave_DA_01,userdata(ResizeControlsInfo)= A"!!,FI!!#@P!!#@^!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Wave_DA_01,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Wave_DA_01,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Wave_DA_01,fSize=7
	PopupMenu Wave_DA_01,mode=1,popvalue="- none -",value= #"\"- none -; TestPulse;alpha_DAC_1;\""
	PopupMenu Wave_DA_02,pos={114,165},size={125,21},bodyWidth=125,disable=1,proc=ITCP_PopMenuCheckProc_DAC
	PopupMenu Wave_DA_02,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	PopupMenu Wave_DA_02,userdata(ResizeControlsInfo)= A"!!,FI!!#A4!!#@^!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Wave_DA_02,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Wave_DA_02,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Wave_DA_02,fSize=7
	PopupMenu Wave_DA_02,mode=1,popvalue="- none -",value= #"\"- none -; TestPulse;alpha_DAC_1;\""
	PopupMenu Wave_DA_03,pos={114,212},size={125,21},bodyWidth=125,disable=1,proc=ITCP_PopMenuCheckProc_DAC
	PopupMenu Wave_DA_03,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	PopupMenu Wave_DA_03,userdata(ResizeControlsInfo)= A"!!,FI!!#Ac!!#@^!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Wave_DA_03,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Wave_DA_03,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Wave_DA_03,fSize=7
	PopupMenu Wave_DA_03,mode=1,popvalue="- none -",value= #"\"- none -; TestPulse;alpha_DAC_1;\""
	PopupMenu Wave_DA_04,pos={114,258},size={125,21},bodyWidth=125,disable=1,proc=ITCP_PopMenuCheckProc_DAC
	PopupMenu Wave_DA_04,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	PopupMenu Wave_DA_04,userdata(ResizeControlsInfo)= A"!!,FI!!#B;!!#@^!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Wave_DA_04,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Wave_DA_04,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Wave_DA_04,fSize=7
	PopupMenu Wave_DA_04,mode=1,popvalue="- none -",value= #"\"- none -; TestPulse;alpha_DAC_1;\""
	PopupMenu Wave_DA_05,pos={114,305},size={125,21},bodyWidth=125,disable=1,proc=ITCP_PopMenuCheckProc_DAC
	PopupMenu Wave_DA_05,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	PopupMenu Wave_DA_05,userdata(ResizeControlsInfo)= A"!!,FI!!#BRJ,hq4!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Wave_DA_05,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Wave_DA_05,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Wave_DA_05,fSize=7
	PopupMenu Wave_DA_05,mode=1,popvalue="- none -",value= #"\"- none -; TestPulse;alpha_DAC_1;\""
	PopupMenu Wave_DA_06,pos={114,352},size={125,21},bodyWidth=125,disable=1,proc=ITCP_PopMenuCheckProc_DAC
	PopupMenu Wave_DA_06,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	PopupMenu Wave_DA_06,userdata(ResizeControlsInfo)= A"!!,FI!!#Bj!!#@^!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Wave_DA_06,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Wave_DA_06,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Wave_DA_06,fSize=7
	PopupMenu Wave_DA_06,mode=1,popvalue="- none -",value= #"\"- none -; TestPulse;alpha_DAC_1;\""
	PopupMenu Wave_DA_07,pos={114,399},size={125,21},bodyWidth=125,disable=1,proc=ITCP_PopMenuCheckProc_DAC
	PopupMenu Wave_DA_07,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	PopupMenu Wave_DA_07,userdata(ResizeControlsInfo)= A"!!,FI!!#C,J,hq4!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Wave_DA_07,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Wave_DA_07,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Wave_DA_07,fSize=7
	PopupMenu Wave_DA_07,mode=1,popvalue="- none -",value= #"\"- none -; TestPulse;alpha_DAC_1;\""
	SetVariable Scale_DA_00,pos={245,74},size={40,16},disable=1
	SetVariable Scale_DA_00,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	SetVariable Scale_DA_00,userdata(ResizeControlsInfo)= A"!!,H0!!#?M!!#>.!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Scale_DA_00,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Scale_DA_00,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Scale_DA_00,value= _NUM:2
	SetVariable Scale_DA_01,pos={245,120},size={40,16},disable=1
	SetVariable Scale_DA_01,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	SetVariable Scale_DA_01,userdata(ResizeControlsInfo)= A"!!,H0!!#@T!!#>.!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Scale_DA_01,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Scale_DA_01,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Scale_DA_01,value= _NUM:2
	SetVariable Scale_DA_02,pos={245,167},size={40,16},disable=1
	SetVariable Scale_DA_02,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	SetVariable Scale_DA_02,userdata(ResizeControlsInfo)= A"!!,H0!!#A6!!#>.!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Scale_DA_02,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Scale_DA_02,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Scale_DA_02,value= _NUM:10
	SetVariable Scale_DA_03,pos={245,214},size={40,16},disable=1
	SetVariable Scale_DA_03,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	SetVariable Scale_DA_03,userdata(ResizeControlsInfo)= A"!!,H0!!#Ae!!#>.!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Scale_DA_03,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Scale_DA_03,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Scale_DA_03,value= _NUM:1
	SetVariable Scale_DA_04,pos={245,260},size={40,16},disable=1
	SetVariable Scale_DA_04,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	SetVariable Scale_DA_04,userdata(ResizeControlsInfo)= A"!!,H0!!#B<!!#>.!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Scale_DA_04,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Scale_DA_04,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Scale_DA_04,value= _NUM:2
	SetVariable Scale_DA_05,pos={245,307},size={40,16},disable=1
	SetVariable Scale_DA_05,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	SetVariable Scale_DA_05,userdata(ResizeControlsInfo)= A"!!,H0!!#BSJ,hnY!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Scale_DA_05,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Scale_DA_05,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Scale_DA_05,value= _NUM:2
	SetVariable Scale_DA_06,pos={245,354},size={40,16},disable=1
	SetVariable Scale_DA_06,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	SetVariable Scale_DA_06,userdata(ResizeControlsInfo)= A"!!,H0!!#Bk!!#>.!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Scale_DA_06,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Scale_DA_06,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Scale_DA_06,value= _NUM:2
	SetVariable Scale_DA_07,pos={245,401},size={40,16},disable=1
	SetVariable Scale_DA_07,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	SetVariable Scale_DA_07,userdata(ResizeControlsInfo)= A"!!,H0!!#C-J,hnY!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Scale_DA_07,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Scale_DA_07,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Scale_DA_07,value= _NUM:1
	SetVariable SetVar_DataAcq_Comment,pos={35,401},size={384,16},disable=1,title="Comment"
	SetVariable SetVar_DataAcq_Comment,help={"Appends a comment to wave note of next sweep"}
	SetVariable SetVar_DataAcq_Comment,userdata(tabnum)=  "0"
	SetVariable SetVar_DataAcq_Comment,userdata(tabcontrol)=  "ADC"
	SetVariable SetVar_DataAcq_Comment,userdata(ResizeControlsInfo)= A"!!,CL!!#C$J,hs?!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_DataAcq_Comment,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_DataAcq_Comment,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_DataAcq_Comment,fSize=8,value= _STR:""
	Button DataAcquireButton,pos={33,419},size={389,49},disable=1,proc=ButtonProc_AcquireData,title="\\Z14\\f01Acquire Data\r * DATA WILL NOT BE SAVED *\r\\Z08\\f00 (autosave state is in settings tab)"
	Button DataAcquireButton,userdata(tabnum)=  "0",userdata(tabcontrol)=  "ADC"
	Button DataAcquireButton,userdata(ResizeControlsInfo)= A"!!,C,!!#C.J,hsAJ,ho,z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button DataAcquireButton,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button DataAcquireButton,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	Button DataAcquireButton,labelBack=(60928,60928,60928),fColor=(52224,0,0)
	CheckBox Check_DataAcq1_RepeatAcq,pos={38,336},size={119,14},disable=1,title="Repeated Acquisition"
	CheckBox Check_DataAcq1_RepeatAcq,help={"Determines number of times a set is repeated, or if indexing is on, the number of times a group of sets in repeated"}
	CheckBox Check_DataAcq1_RepeatAcq,userdata(tabnum)=  "0"
	CheckBox Check_DataAcq1_RepeatAcq,userdata(tabcontrol)=  "ADC"
	CheckBox Check_DataAcq1_RepeatAcq,userdata(ResizeControlsInfo)= A"!!,CT!!#Bh!!#@R!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_DataAcq1_RepeatAcq,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_DataAcq1_RepeatAcq,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_DataAcq1_RepeatAcq,value= 0
	SetVariable SetVar_DataAcq_ITI,pos={196,329},size={105,16},disable=1,title="\\JCITl (sec)"
	SetVariable SetVar_DataAcq_ITI,userdata(tabnum)=  "0"
	SetVariable SetVar_DataAcq_ITI,userdata(tabcontrol)=  "ADC"
	SetVariable SetVar_DataAcq_ITI,userdata(ResizeControlsInfo)= A"!!,G,!!#BfJ,hpa!!#=Sz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_DataAcq_ITI,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_DataAcq_ITI,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_DataAcq_ITI,limits={0,inf,1},value= _NUM:5
	Button StartTestPulseButton,pos={35,249},size={384,48},disable=1,proc=ButtonProc_1,title="\\Z14\\f01Start Test \rPulse"
	Button StartTestPulseButton,userdata(tabnum)=  "0",userdata(tabcontrol)=  "ADC"
	Button StartTestPulseButton,userdata(ResizeControlsInfo)= A"!!,C4!!#B;!!#Bk!!#>Nz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button StartTestPulseButton,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button StartTestPulseButton,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_DataAcq_00,pos={148,86},size={24,14},disable=1,proc=CheckProc_HeadstageCheck,title="0"
	CheckBox Check_DataAcq_00,userdata(tabnum)=  "0",userdata(tabcontrol)=  "ADC"
	CheckBox Check_DataAcq_00,userdata(ResizeControlsInfo)= A"!!,FS!!#?m!!#=#!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_DataAcq_00,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_DataAcq_00,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_DataAcq_00,value= 1
	SetVariable SetVar_DataAcq_TPDuration,pos={98,226},size={110,16},disable=1,title="Duration (ms)"
	SetVariable SetVar_DataAcq_TPDuration,userdata(tabnum)=  "0"
	SetVariable SetVar_DataAcq_TPDuration,userdata(tabcontrol)=  "ADC"
	SetVariable SetVar_DataAcq_TPDuration,userdata(ResizeControlsInfo)= A"!!,En!!#B%!!#@@!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_DataAcq_TPDuration,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_DataAcq_TPDuration,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_DataAcq_TPDuration,value= _NUM:10
	SetVariable SetVar_DataAcq_TPAmplitude,pos={213,226},size={110,16},disable=1,title="Amplitude"
	SetVariable SetVar_DataAcq_TPAmplitude,userdata(tabnum)=  "0"
	SetVariable SetVar_DataAcq_TPAmplitude,userdata(tabcontrol)=  "ADC"
	SetVariable SetVar_DataAcq_TPAmplitude,userdata(ResizeControlsInfo)= A"!!,G]!!#B%!!#@@!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_DataAcq_TPAmplitude,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_DataAcq_TPAmplitude,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_DataAcq_TPAmplitude,value= _NUM:2
	CheckBox Check_TTL_00,pos={24,72},size={47,14},disable=1,proc=DAorTTLCheckProc,title="TTL 0"
	CheckBox Check_TTL_00,userdata(tabnum)=  "3",userdata(tabcontrol)=  "ADC"
	CheckBox Check_TTL_00,userdata(ResizeControlsInfo)= A"!!,C$!!#?I!!#>J!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_TTL_00,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_TTL_00,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_TTL_00,value= 0
	CheckBox Check_TTL_01,pos={24,118},size={47,14},disable=1,proc=DAorTTLCheckProc,title="TTL 1"
	CheckBox Check_TTL_01,userdata(tabnum)=  "3",userdata(tabcontrol)=  "ADC"
	CheckBox Check_TTL_01,userdata(ResizeControlsInfo)= A"!!,C$!!#@P!!#>J!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_TTL_01,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_TTL_01,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_TTL_01,value= 0
	CheckBox Check_TTL_02,pos={24,164},size={47,14},disable=1,proc=DAorTTLCheckProc,title="TTL 2"
	CheckBox Check_TTL_02,userdata(tabnum)=  "3",userdata(tabcontrol)=  "ADC"
	CheckBox Check_TTL_02,userdata(ResizeControlsInfo)= A"!!,C$!!#A3!!#>J!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_TTL_02,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_TTL_02,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_TTL_02,value= 0
	CheckBox Check_TTL_03,pos={24,210},size={47,14},disable=1,proc=DAorTTLCheckProc,title="TTL 3"
	CheckBox Check_TTL_03,userdata(tabnum)=  "3",userdata(tabcontrol)=  "ADC"
	CheckBox Check_TTL_03,userdata(ResizeControlsInfo)= A"!!,C$!!#Aa!!#>J!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_TTL_03,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_TTL_03,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_TTL_03,value= 0
	CheckBox Check_TTL_04,pos={24,256},size={47,14},disable=1,proc=DAorTTLCheckProc,title="TTL 4"
	CheckBox Check_TTL_04,userdata(tabnum)=  "3",userdata(tabcontrol)=  "ADC"
	CheckBox Check_TTL_04,userdata(ResizeControlsInfo)= A"!!,C$!!#B:!!#>J!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_TTL_04,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_TTL_04,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_TTL_04,value= 0
	CheckBox Check_TTL_05,pos={24,302},size={47,14},disable=1,proc=DAorTTLCheckProc,title="TTL 5"
	CheckBox Check_TTL_05,userdata(tabnum)=  "3",userdata(tabcontrol)=  "ADC"
	CheckBox Check_TTL_05,userdata(ResizeControlsInfo)= A"!!,C$!!#BQ!!#>J!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_TTL_05,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_TTL_05,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_TTL_05,value= 0
	CheckBox Check_TTL_06,pos={24,348},size={47,14},disable=1,proc=DAorTTLCheckProc,title="TTL 6"
	CheckBox Check_TTL_06,userdata(tabnum)=  "3",userdata(tabcontrol)=  "ADC"
	CheckBox Check_TTL_06,userdata(ResizeControlsInfo)= A"!!,C$!!#Bh!!#>J!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_TTL_06,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_TTL_06,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_TTL_06,value= 0
	CheckBox Check_TTL_07,pos={24,395},size={47,14},disable=1,proc=DAorTTLCheckProc,title="TTL 7"
	CheckBox Check_TTL_07,userdata(tabnum)=  "3",userdata(tabcontrol)=  "ADC"
	CheckBox Check_TTL_07,userdata(ResizeControlsInfo)= A"!!,C$!!#C*J,hnu!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_TTL_07,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_TTL_07,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_TTL_07,value= 0
	PopupMenu Wave_TTL_00,pos={103,69},size={125,21},bodyWidth=125,disable=1,proc=ITCP_PopMenuCheckProc_DAC
	PopupMenu Wave_TTL_00,userdata(tabnum)=  "3",userdata(tabcontrol)=  "ADC"
	PopupMenu Wave_TTL_00,userdata(ResizeControlsInfo)= A"!!,F3!!#?C!!#@^!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Wave_TTL_00,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Wave_TTL_00,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Wave_TTL_00,mode=1,popvalue="- none -",value= #"\"- none -;doit_TTL_1;\""
	PopupMenu Wave_TTL_01,pos={103,115},size={125,21},bodyWidth=125,disable=1,proc=ITCP_PopMenuCheckProc_DAC
	PopupMenu Wave_TTL_01,userdata(tabnum)=  "3",userdata(tabcontrol)=  "ADC"
	PopupMenu Wave_TTL_01,userdata(ResizeControlsInfo)= A"!!,F3!!#@J!!#@^!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Wave_TTL_01,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Wave_TTL_01,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Wave_TTL_01,mode=1,popvalue="- none -",value= #"\"- none -;doit_TTL_1;\""
	PopupMenu Wave_TTL_02,pos={103,161},size={125,21},bodyWidth=125,disable=1,proc=ITCP_PopMenuCheckProc_DAC
	PopupMenu Wave_TTL_02,userdata(tabnum)=  "3",userdata(tabcontrol)=  "ADC"
	PopupMenu Wave_TTL_02,userdata(ResizeControlsInfo)= A"!!,F3!!#A0!!#@^!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Wave_TTL_02,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Wave_TTL_02,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Wave_TTL_02,mode=1,popvalue="- none -",value= #"\"- none -;doit_TTL_1;\""
	PopupMenu Wave_TTL_03,pos={103,207},size={125,21},bodyWidth=125,disable=1,proc=ITCP_PopMenuCheckProc_DAC
	PopupMenu Wave_TTL_03,userdata(tabnum)=  "3",userdata(tabcontrol)=  "ADC"
	PopupMenu Wave_TTL_03,userdata(ResizeControlsInfo)= A"!!,F3!!#A^!!#@^!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Wave_TTL_03,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Wave_TTL_03,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Wave_TTL_03,mode=1,popvalue="- none -",value= #"\"- none -;doit_TTL_1;\""
	PopupMenu Wave_TTL_04,pos={103,253},size={125,21},bodyWidth=125,disable=1,proc=ITCP_PopMenuCheckProc_DAC
	PopupMenu Wave_TTL_04,userdata(tabnum)=  "3",userdata(tabcontrol)=  "ADC"
	PopupMenu Wave_TTL_04,userdata(ResizeControlsInfo)= A"!!,F3!!#B7!!#@^!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Wave_TTL_04,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Wave_TTL_04,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Wave_TTL_04,mode=1,popvalue="- none -",value= #"\"- none -;doit_TTL_1;\""
	PopupMenu Wave_TTL_05,pos={103,299},size={125,21},bodyWidth=125,disable=1,proc=ITCP_PopMenuCheckProc_DAC
	PopupMenu Wave_TTL_05,userdata(tabnum)=  "3",userdata(tabcontrol)=  "ADC"
	PopupMenu Wave_TTL_05,userdata(ResizeControlsInfo)= A"!!,F3!!#BOJ,hq4!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Wave_TTL_05,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Wave_TTL_05,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Wave_TTL_05,mode=1,popvalue="- none -",value= #"\"- none -;doit_TTL_1;\""
	PopupMenu Wave_TTL_06,pos={103,345},size={125,21},bodyWidth=125,disable=1,proc=ITCP_PopMenuCheckProc_DAC
	PopupMenu Wave_TTL_06,userdata(tabnum)=  "3",userdata(tabcontrol)=  "ADC"
	PopupMenu Wave_TTL_06,userdata(ResizeControlsInfo)= A"!!,F3!!#BfJ,hq4!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Wave_TTL_06,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Wave_TTL_06,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Wave_TTL_06,mode=1,popvalue="- none -",value= #"\"- none -;doit_TTL_1;\""
	PopupMenu Wave_TTL_07,pos={103,392},size={125,21},bodyWidth=125,disable=1,proc=ITCP_PopMenuCheckProc_DAC
	PopupMenu Wave_TTL_07,userdata(tabnum)=  "3",userdata(tabcontrol)=  "ADC"
	PopupMenu Wave_TTL_07,userdata(ResizeControlsInfo)= A"!!,F3!!#C)!!#@^!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Wave_TTL_07,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Wave_TTL_07,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Wave_TTL_07,mode=1,popvalue="- none -",value= #"\"- none -;doit_TTL_1;\""
	CheckBox Check_TP_TrigOut,pos={330,227},size={56,14},disable=1,title="\\JCTrig Out"
	CheckBox Check_TP_TrigOut,userdata(tabnum)=  "0",userdata(tabcontrol)=  "ADC"
	CheckBox Check_TP_TrigOut,userdata(ResizeControlsInfo)= A"!!,H\\!!#B&!!#>n!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_TP_TrigOut,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_TP_TrigOut,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_TP_TrigOut,value= 0
	CheckBox Check_Settings_TrigOut,pos={235,56},size={56,14},title="\\JCTrig Out"
	CheckBox Check_Settings_TrigOut,help={"Turns on TTL pulse at onset of sweep"}
	CheckBox Check_Settings_TrigOut,userdata(tabnum)=  "5"
	CheckBox Check_Settings_TrigOut,userdata(tabcontrol)=  "ADC"
	CheckBox Check_Settings_TrigOut,userdata(ResizeControlsInfo)= A"!!,Gh!!#>n!!#>n!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_Settings_TrigOut,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_Settings_TrigOut,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_Settings_TrigOut,value= 0
	CheckBox Check_Settings_TrigIn,pos={235,73},size={48,14},title="\\JCTrig In"
	CheckBox Check_Settings_TrigIn,help={"Starts Data Aquisition with TTL signal to trig in port on rack"}
	CheckBox Check_Settings_TrigIn,userdata(tabnum)=  "5"
	CheckBox Check_Settings_TrigIn,userdata(tabcontrol)=  "ADC"
	CheckBox Check_Settings_TrigIn,userdata(ResizeControlsInfo)= A"!!,Gh!!#?K!!#>N!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_Settings_TrigIn,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_Settings_TrigIn,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_Settings_TrigIn,value= 0
	SetVariable SetVar_DataAcq_TotTrial,pos={200,353},size={100,16},disable=1,title="\\JCSet Trial No."
	SetVariable SetVar_DataAcq_TotTrial,help={"This number is set automatically at based on the number of 1d waves contained in the largest set on active DA/TTL channels"}
	SetVariable SetVar_DataAcq_TotTrial,userdata(tabnum)=  "0"
	SetVariable SetVar_DataAcq_TotTrial,userdata(tabcontrol)=  "ADC"
	SetVariable SetVar_DataAcq_TotTrial,userdata(ResizeControlsInfo)= A"!!,H@!!#Bf!!#?E!!#=Sz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_DataAcq_TotTrial,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_DataAcq_TotTrial,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_DataAcq_TotTrial,limits={0,inf,1},value= _NUM:20
	ValDisplay ValDisp_DataAcq_SamplingInt,pos={263,174},size={100,26},disable=1,title="Sampling \rInterval (µS)"
	ValDisplay ValDisp_DataAcq_SamplingInt,userdata(tabnum)=  "0"
	ValDisplay ValDisp_DataAcq_SamplingInt,userdata(tabcontrol)=  "ADC"
	ValDisplay ValDisp_DataAcq_SamplingInt,userdata(ResizeControlsInfo)= A"!!,H:!!#AF!!#@,!!#=3z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	ValDisplay ValDisp_DataAcq_SamplingInt,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	ValDisplay ValDisp_DataAcq_SamplingInt,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	ValDisplay ValDisp_DataAcq_SamplingInt,limits={0,0,0},barmisc={0,1000}
	ValDisplay ValDisp_DataAcq_SamplingInt,value= #"ITCMinSamplingInterval()"
	CheckBox Check_Settings_DownSamp,pos={33,56},size={53,26},proc=CheckProc,title="Down\rSample"
	CheckBox Check_Settings_DownSamp,userdata(tabnum)=  "5"
	CheckBox Check_Settings_DownSamp,userdata(tabcontrol)=  "ADC"
	CheckBox Check_Settings_DownSamp,userdata(ResizeControlsInfo)= A"!!,An!!#>n!!#>b!!#=3z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_Settings_DownSamp,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_Settings_DownSamp,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_Settings_DownSamp,value= 0
	SetVariable SetVar_DownSamp,pos={97,56},size={120,30},proc=SetVarProc,title="Desired Sample\rInterval (µS)"
	SetVariable SetVar_DownSamp,userdata(tabnum)=  "5",userdata(tabcontrol)=  "ADC"
	SetVariable SetVar_DownSamp,userdata(ResizeControlsInfo)= A"!!,EV!!#>n!!#@T!!#=Sz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_DownSamp,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_DownSamp,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_DownSamp,limits={20,inf,1},value= _NUM:23
	SetVariable SetVar_Sweep,pos={50,173},size={192,28},bodyWidth=75,disable=1,proc=SetVarProc_NextSweep,title="Next Sweep"
	SetVariable SetVar_Sweep,userdata(tabnum)=  "0",userdata(tabcontrol)=  "ADC"
	SetVariable SetVar_Sweep,userdata(ResizeControlsInfo)= A"!!,D7!!#AF!!#AO!!#=Cz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_Sweep,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_Sweep,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_Sweep,fSize=18,fStyle=1,valueColor=(65535,65535,65535)
	SetVariable SetVar_Sweep,valueBackColor=(0,0,0),limits={0,15,1},value= _NUM:15
	CheckBox Check_Settings_SaveData,pos={306,61},size={69,26},proc=CheckProc_1,title="Do Not\rSave Data"
	CheckBox Check_Settings_SaveData,help={"Use cautiously - intended primarily for software development"}
	CheckBox Check_Settings_SaveData,userdata(tabnum)=  "5"
	CheckBox Check_Settings_SaveData,userdata(tabcontrol)=  "ADC"
	CheckBox Check_Settings_SaveData,userdata(ResizeControlsInfo)= A"!!,HJJ,hoX!!#?C!!#=3z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_Settings_SaveData,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_Settings_SaveData,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_Settings_SaveData,value= 1
	CheckBox Check_AsyncAD_00,pos={172,46},size={42,14},disable=1,title="AD 0"
	CheckBox Check_AsyncAD_00,help={"hello!"},userdata(tabnum)=  "4"
	CheckBox Check_AsyncAD_00,userdata(tabcontrol)=  "ADC"
	CheckBox Check_AsyncAD_00,userdata(ResizeControlsInfo)= A"!!,G<!!#>F!!#>6!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_AsyncAD_00,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_AsyncAD_00,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_AsyncAD_00,value= 0
	CheckBox Check_AsyncAD_01,pos={171,97},size={42,14},disable=1,title="AD 1"
	CheckBox Check_AsyncAD_01,userdata(tabnum)=  "4",userdata(tabcontrol)=  "ADC"
	CheckBox Check_AsyncAD_01,userdata(ResizeControlsInfo)= A"!!,G;!!#?]!!#>6!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_AsyncAD_01,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_AsyncAD_01,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_AsyncAD_01,value= 0
	CheckBox Check_AsyncAD_02,pos={171,148},size={42,14},disable=1,title="AD 2"
	CheckBox Check_AsyncAD_02,userdata(tabnum)=  "4",userdata(tabcontrol)=  "ADC"
	CheckBox Check_AsyncAD_02,userdata(ResizeControlsInfo)= A"!!,G;!!#@P!!#>6!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_AsyncAD_02,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_AsyncAD_02,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_AsyncAD_02,value= 0
	CheckBox Check_AsyncAD_03,pos={171,199},size={42,14},disable=1,title="AD 3"
	CheckBox Check_AsyncAD_03,userdata(tabnum)=  "4",userdata(tabcontrol)=  "ADC"
	CheckBox Check_AsyncAD_03,userdata(ResizeControlsInfo)= A"!!,G;!!#A*!!#>6!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_AsyncAD_03,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_AsyncAD_03,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_AsyncAD_03,value= 0
	CheckBox Check_AsyncAD_04,pos={171,250},size={42,14},disable=1,title="AD 4"
	CheckBox Check_AsyncAD_04,userdata(tabnum)=  "4",userdata(tabcontrol)=  "ADC"
	CheckBox Check_AsyncAD_04,userdata(ResizeControlsInfo)= A"!!,G;!!#AN!!#>6!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_AsyncAD_04,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_AsyncAD_04,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_AsyncAD_04,value= 0
	CheckBox Check_AsyncAD_05,pos={171,301},size={42,14},disable=1,title="AD 5"
	CheckBox Check_AsyncAD_05,userdata(tabnum)=  "4",userdata(tabcontrol)=  "ADC"
	CheckBox Check_AsyncAD_05,userdata(ResizeControlsInfo)= A"!!,G;!!#As!!#>6!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_AsyncAD_05,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_AsyncAD_05,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_AsyncAD_05,value= 0
	CheckBox Check_AsyncAD_06,pos={171,352},size={42,14},disable=1,title="AD 6"
	CheckBox Check_AsyncAD_06,userdata(tabnum)=  "4",userdata(tabcontrol)=  "ADC"
	CheckBox Check_AsyncAD_06,userdata(ResizeControlsInfo)= A"!!,G;!!#B>!!#>6!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_AsyncAD_06,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_AsyncAD_06,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_AsyncAD_06,value= 0
	CheckBox Check_AsyncAD_07,pos={171,404},size={42,14},disable=1,title="AD 7"
	CheckBox Check_AsyncAD_07,userdata(tabnum)=  "4",userdata(tabcontrol)=  "ADC"
	CheckBox Check_AsyncAD_07,userdata(ResizeControlsInfo)= A"!!,G;!!#BP!!#>6!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
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
	SetVariable SetVar_AsyncAD_Gain_01,userdata(ResizeControlsInfo)= A"!!,Gr!!#?Y!!#?O!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_AsyncAD_Gain_01,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_AsyncAD_Gain_01,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_AsyncAD_Gain_01,limits={0,inf,1},value= _NUM:10
	SetVariable SetVar_AsyncAD_Gain_02,pos={226,146},size={75,16},disable=1,title="gain"
	SetVariable SetVar_AsyncAD_Gain_02,userdata(tabnum)=  "4"
	SetVariable SetVar_AsyncAD_Gain_02,userdata(tabcontrol)=  "ADC"
	SetVariable SetVar_AsyncAD_Gain_02,userdata(ResizeControlsInfo)= A"!!,Gr!!#@N!!#?O!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_AsyncAD_Gain_02,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_AsyncAD_Gain_02,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_AsyncAD_Gain_02,limits={0,inf,1},value= _NUM:0
	SetVariable SetVar_AsyncAD_Gain_03,pos={226,197},size={75,16},disable=1,title="gain"
	SetVariable SetVar_AsyncAD_Gain_03,userdata(tabnum)=  "4"
	SetVariable SetVar_AsyncAD_Gain_03,userdata(tabcontrol)=  "ADC"
	SetVariable SetVar_AsyncAD_Gain_03,userdata(ResizeControlsInfo)= A"!!,Gr!!#A(!!#?O!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_AsyncAD_Gain_03,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_AsyncAD_Gain_03,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_AsyncAD_Gain_03,limits={0,inf,1},value= _NUM:0
	SetVariable SetVar_AsyncAD_Gain_04,pos={226,248},size={75,16},disable=1,title="gain"
	SetVariable SetVar_AsyncAD_Gain_04,userdata(tabnum)=  "4"
	SetVariable SetVar_AsyncAD_Gain_04,userdata(tabcontrol)=  "ADC"
	SetVariable SetVar_AsyncAD_Gain_04,userdata(ResizeControlsInfo)= A"!!,Gr!!#AM!!#?O!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_AsyncAD_Gain_04,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_AsyncAD_Gain_04,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_AsyncAD_Gain_04,limits={0,inf,1},value= _NUM:0
	SetVariable SetVar_AsyncAD_Gain_05,pos={226,299},size={75,16},disable=1,title="gain"
	SetVariable SetVar_AsyncAD_Gain_05,userdata(tabnum)=  "4"
	SetVariable SetVar_AsyncAD_Gain_05,userdata(tabcontrol)=  "ADC"
	SetVariable SetVar_AsyncAD_Gain_05,userdata(ResizeControlsInfo)= A"!!,Gr!!#Aq!!#?O!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_AsyncAD_Gain_05,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_AsyncAD_Gain_05,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_AsyncAD_Gain_05,limits={0,inf,1},value= _NUM:0
	SetVariable SetVar_AsyncAD_Gain_06,pos={226,350},size={75,16},disable=1,title="gain"
	SetVariable SetVar_AsyncAD_Gain_06,userdata(tabnum)=  "4"
	SetVariable SetVar_AsyncAD_Gain_06,userdata(tabcontrol)=  "ADC"
	SetVariable SetVar_AsyncAD_Gain_06,userdata(ResizeControlsInfo)= A"!!,Gr!!#B=J,hp%!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_AsyncAD_Gain_06,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_AsyncAD_Gain_06,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_AsyncAD_Gain_06,limits={0,inf,1},value= _NUM:0
	SetVariable SetVar_AsyncAD_Gain_07,pos={226,402},size={75,16},disable=1,title="gain"
	SetVariable SetVar_AsyncAD_Gain_07,userdata(tabnum)=  "4"
	SetVariable SetVar_AsyncAD_Gain_07,userdata(tabcontrol)=  "ADC"
	SetVariable SetVar_AsyncAD_Gain_07,userdata(ResizeControlsInfo)= A"!!,Gr!!#BOJ,hp%!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_AsyncAD_Gain_07,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_AsyncAD_Gain_07,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_AsyncAD_Gain_07,limits={0,inf,1},value= _NUM:100
	SetVariable SetVar_Async_Title_00,pos={14,44},size={150,16},disable=1,title="Title"
	SetVariable SetVar_Async_Title_00,userdata(tabnum)=  "4"
	SetVariable SetVar_Async_Title_00,userdata(tabcontrol)=  "ADC"
	SetVariable SetVar_Async_Title_00,userdata(ResizeControlsInfo)= A"!!,An!!#>>!!#A%!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_Async_Title_00,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_Async_Title_00,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_Async_Title_00,value= _STR:"temperature"
	SetVariable SetVar_Async_Title_01,pos={14,95},size={150,16},disable=1,title="Title"
	SetVariable SetVar_Async_Title_01,userdata(tabnum)=  "4"
	SetVariable SetVar_Async_Title_01,userdata(tabcontrol)=  "ADC"
	SetVariable SetVar_Async_Title_01,userdata(ResizeControlsInfo)= A"!!,An!!#?Y!!#A%!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_Async_Title_01,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_Async_Title_01,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_Async_Title_01,value= _STR:""
	SetVariable SetVar_Async_Title_02,pos={14,146},size={150,16},disable=1,title="Title"
	SetVariable SetVar_Async_Title_02,userdata(tabnum)=  "4"
	SetVariable SetVar_Async_Title_02,userdata(tabcontrol)=  "ADC"
	SetVariable SetVar_Async_Title_02,userdata(ResizeControlsInfo)= A"!!,An!!#@L!!#A%!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_Async_Title_02,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_Async_Title_02,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_Async_Title_02,value= _STR:""
	SetVariable SetVar_Async_Title_03,pos={14,197},size={150,16},disable=1,title="Title"
	SetVariable SetVar_Async_Title_03,userdata(tabnum)=  "4"
	SetVariable SetVar_Async_Title_03,userdata(tabcontrol)=  "ADC"
	SetVariable SetVar_Async_Title_03,userdata(ResizeControlsInfo)= A"!!,An!!#A'!!#A%!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_Async_Title_03,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_Async_Title_03,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_Async_Title_03,value= _STR:""
	SetVariable SetVar_Async_Title_04,pos={14,248},size={150,16},disable=1,title="Title"
	SetVariable SetVar_Async_Title_04,userdata(tabnum)=  "4"
	SetVariable SetVar_Async_Title_04,userdata(tabcontrol)=  "ADC"
	SetVariable SetVar_Async_Title_04,userdata(ResizeControlsInfo)= A"!!,An!!#AL!!#A%!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_Async_Title_04,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_Async_Title_04,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_Async_Title_04,value= _STR:""
	SetVariable SetVar_Async_Title_05,pos={14,299},size={150,16},disable=1,title="Title"
	SetVariable SetVar_Async_Title_05,userdata(tabnum)=  "4"
	SetVariable SetVar_Async_Title_05,userdata(tabcontrol)=  "ADC"
	SetVariable SetVar_Async_Title_05,userdata(ResizeControlsInfo)= A"!!,An!!#Ap!!#A%!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_Async_Title_05,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_Async_Title_05,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_Async_Title_05,value= _STR:""
	SetVariable SetVar_Async_Title_06,pos={14,350},size={150,16},disable=1,title="Title"
	SetVariable SetVar_Async_Title_06,userdata(tabnum)=  "4"
	SetVariable SetVar_Async_Title_06,userdata(tabcontrol)=  "ADC"
	SetVariable SetVar_Async_Title_06,userdata(ResizeControlsInfo)= A"!!,An!!#B<J,hqP!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_Async_Title_06,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_Async_Title_06,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_Async_Title_06,value= _STR:""
	SetVariable SetVar_Async_Title_07,pos={14,402},size={150,16},disable=1,title="Title"
	SetVariable SetVar_Async_Title_07,userdata(tabnum)=  "4"
	SetVariable SetVar_Async_Title_07,userdata(tabcontrol)=  "ADC"
	SetVariable SetVar_Async_Title_07,userdata(ResizeControlsInfo)= A"!!,An!!#BO!!#A%!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_Async_Title_07,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_Async_Title_07,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_Async_Title_07,value= _STR:""
	SetVariable SetVar_Async_Unit_00,pos={315,44},size={75,16},disable=1,title="Unit"
	SetVariable SetVar_Async_Unit_00,userdata(tabnum)=  "4"
	SetVariable SetVar_Async_Unit_00,userdata(tabcontrol)=  "ADC"
	SetVariable SetVar_Async_Unit_00,userdata(ResizeControlsInfo)= A"!!,HXJ,hne!!#?O!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_Async_Unit_00,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_Async_Unit_00,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_Async_Unit_00,value= _STR:"C"
	SetVariable SetVar_Async_Unit_01,pos={315,95},size={75,16},disable=1,title="Unit"
	SetVariable SetVar_Async_Unit_01,userdata(tabnum)=  "4"
	SetVariable SetVar_Async_Unit_01,userdata(tabcontrol)=  "ADC"
	SetVariable SetVar_Async_Unit_01,userdata(ResizeControlsInfo)= A"!!,HXJ,hp-!!#?O!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_Async_Unit_01,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_Async_Unit_01,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_Async_Unit_01,value= _STR:"mBar"
	SetVariable SetVar_Async_Unit_02,pos={315,146},size={75,16},disable=1,title="Unit"
	SetVariable SetVar_Async_Unit_02,userdata(tabnum)=  "4"
	SetVariable SetVar_Async_Unit_02,userdata(tabcontrol)=  "ADC"
	SetVariable SetVar_Async_Unit_02,userdata(ResizeControlsInfo)= A"!!,HXJ,hq\"!!#?O!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_Async_Unit_02,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_Async_Unit_02,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_Async_Unit_02,value= _STR:"pP"
	SetVariable SetVar_Async_Unit_03,pos={315,197},size={75,16},disable=1,title="Unit"
	SetVariable SetVar_Async_Unit_03,userdata(tabnum)=  "4"
	SetVariable SetVar_Async_Unit_03,userdata(tabcontrol)=  "ADC"
	SetVariable SetVar_Async_Unit_03,userdata(ResizeControlsInfo)= A"!!,HXJ,hqS!!#?O!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_Async_Unit_03,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_Async_Unit_03,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_Async_Unit_03,value= _STR:"sS"
	SetVariable SetVar_Async_Unit_04,pos={315,248},size={75,16},disable=1,title="Unit"
	SetVariable SetVar_Async_Unit_04,userdata(tabnum)=  "4"
	SetVariable SetVar_Async_Unit_04,userdata(tabcontrol)=  "ADC"
	SetVariable SetVar_Async_Unit_04,userdata(ResizeControlsInfo)= A"!!,HXJ,hr\"!!#?O!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_Async_Unit_04,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_Async_Unit_04,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_Async_Unit_04,value= _STR:"fF"
	SetVariable SetVar_Async_Unit_05,pos={315,299},size={75,16},disable=1,title="Unit"
	SetVariable SetVar_Async_Unit_05,userdata(tabnum)=  "4"
	SetVariable SetVar_Async_Unit_05,userdata(tabcontrol)=  "ADC"
	SetVariable SetVar_Async_Unit_05,userdata(ResizeControlsInfo)= A"!!,HXJ,hrG!!#?O!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_Async_Unit_05,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_Async_Unit_05,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_Async_Unit_05,value= _STR:"rR"
	SetVariable SetVar_Async_Unit_06,pos={315,350},size={75,16},disable=1,title="Unit"
	SetVariable SetVar_Async_Unit_06,userdata(tabnum)=  "4"
	SetVariable SetVar_Async_Unit_06,userdata(tabcontrol)=  "ADC"
	SetVariable SetVar_Async_Unit_06,userdata(ResizeControlsInfo)= A"!!,HXJ,hrhJ,hp%!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_Async_Unit_06,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_Async_Unit_06,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_Async_Unit_06,value= _STR:"nN"
	SetVariable SetVar_Async_Unit_07,pos={315,402},size={75,16},disable=1,title="Unit"
	SetVariable SetVar_Async_Unit_07,userdata(tabnum)=  "4"
	SetVariable SetVar_Async_Unit_07,userdata(tabcontrol)=  "ADC"
	SetVariable SetVar_Async_Unit_07,userdata(ResizeControlsInfo)= A"!!,HXJ,hs&!!#?O!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_Async_Unit_07,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_Async_Unit_07,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_Async_Unit_07,value= _STR:"Sc"
	CheckBox Check_Settings_Append,pos={33,158},size={222,14},title="\\JCAppend Asynchronus reading to wave note"
	CheckBox Check_Settings_Append,help={"Turns on TTL pulse at onset of sweep"}
	CheckBox Check_Settings_Append,userdata(tabnum)=  "5"
	CheckBox Check_Settings_Append,userdata(tabcontrol)=  "ADC"
	CheckBox Check_Settings_Append,userdata(ResizeControlsInfo)= A"!!,An!!#BKJ,hrC!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_Settings_Append,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_Settings_Append,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_Settings_Append,value= 0
	CheckBox Check_Settings_BkgTP,pos={222,91},size={129,14},title="Background Test Pulse"
	CheckBox Check_Settings_BkgTP,help={"Use cautiously - intended primarily for software development"}
	CheckBox Check_Settings_BkgTP,userdata(tabnum)=  "5"
	CheckBox Check_Settings_BkgTP,userdata(tabcontrol)=  "ADC"
	CheckBox Check_Settings_BkgTP,userdata(ResizeControlsInfo)= A"!!,G[!!#?o!!#@e!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_Settings_BkgTP,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_Settings_BkgTP,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_Settings_BkgTP,value= 1
	CheckBox Check_Settings_BackgrndDataAcq,pos={33,89},size={156,14},title="Background Data Acquisition"
	CheckBox Check_Settings_BackgrndDataAcq,help={"You may notice that onscreen update isn't as smooth with background data acquisition. This is normal and unavoidable."}
	CheckBox Check_Settings_BackgrndDataAcq,userdata(tabnum)=  "5"
	CheckBox Check_Settings_BackgrndDataAcq,userdata(tabcontrol)=  "ADC"
	CheckBox Check_Settings_BackgrndDataAcq,userdata(ResizeControlsInfo)= A"!!,An!!#?k!!#A+!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_Settings_BackgrndDataAcq,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_Settings_BackgrndDataAcq,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_Settings_BackgrndDataAcq,value= 0
	CheckBox Radio_ClampMode_0,pos={148,62},size={16,14},disable=1,proc=CheckProc_ClampMode,title=""
	CheckBox Radio_ClampMode_0,userdata(tabnum)=  "0",userdata(tabcontrol)=  "ADC"
	CheckBox Radio_ClampMode_0,userdata(ResizeControlsInfo)= A"!!,FS!!#?=!!#<8!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Radio_ClampMode_0,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Radio_ClampMode_0,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Radio_ClampMode_0,value= 1,mode=1
	TitleBox Title_DataAcq_VC,pos={57,65},size={68,13},disable=1,title="Voltage Clamp"
	TitleBox Title_DataAcq_VC,userdata(tabnum)=  "0",userdata(tabcontrol)=  "ADC"
	TitleBox Title_DataAcq_VC,userdata(ResizeControlsInfo)= A"!!,CD!!#?C!!#?A!!#;]z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox Title_DataAcq_VC,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	TitleBox Title_DataAcq_VC,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	TitleBox Title_DataAcq_VC,frame=0
	TitleBox Title_DataAcq_IC,pos={57,109},size={66,13},disable=1,title="Current Clamp"
	TitleBox Title_DataAcq_IC,userdata(tabnum)=  "0",userdata(tabcontrol)=  "ADC"
	TitleBox Title_DataAcq_IC,userdata(ResizeControlsInfo)= A"!!,CD!!#@F!!#?=!!#;]z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox Title_DataAcq_IC,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	TitleBox Title_DataAcq_IC,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	TitleBox Title_DataAcq_IC,frame=0
	TitleBox Title_DataAcq_CellSelection,pos={72,87},size={52,13},disable=1,title="Headstage"
	TitleBox Title_DataAcq_CellSelection,userdata(tabnum)=  "0"
	TitleBox Title_DataAcq_CellSelection,userdata(tabcontrol)=  "ADC"
	TitleBox Title_DataAcq_CellSelection,userdata(ResizeControlsInfo)= A"!!,D;!!#?o!!#>^!!#;]z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox Title_DataAcq_CellSelection,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	TitleBox Title_DataAcq_CellSelection,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	TitleBox Title_DataAcq_CellSelection,frame=0
	CheckBox Check_DataAcq_01,pos={181,86},size={24,14},disable=1,proc=CheckProc_HeadstageCheck,title="1"
	CheckBox Check_DataAcq_01,userdata(tabnum)=  "0",userdata(tabcontrol)=  "ADC"
	CheckBox Check_DataAcq_01,userdata(ResizeControlsInfo)= A"!!,G(!!#?m!!#=#!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_DataAcq_01,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_DataAcq_01,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_DataAcq_01,value= 0
	CheckBox Check_DataAcq_02,pos={215,86},size={24,14},disable=1,proc=CheckProc_HeadstageCheck,title="2"
	CheckBox Check_DataAcq_02,userdata(tabnum)=  "0",userdata(tabcontrol)=  "ADC"
	CheckBox Check_DataAcq_02,userdata(ResizeControlsInfo)= A"!!,GJ!!#?m!!#=#!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_DataAcq_02,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_DataAcq_02,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_DataAcq_02,value= 0
	CheckBox Check_DataAcq_03,pos={249,86},size={24,14},disable=1,proc=CheckProc_HeadstageCheck,title="3"
	CheckBox Check_DataAcq_03,userdata(tabnum)=  "0",userdata(tabcontrol)=  "ADC"
	CheckBox Check_DataAcq_03,userdata(ResizeControlsInfo)= A"!!,Gl!!#?m!!#=#!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_DataAcq_03,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_DataAcq_03,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_DataAcq_03,value= 0
	CheckBox Check_DataAcq_04,pos={283,86},size={24,14},disable=1,proc=CheckProc_HeadstageCheck,title="4"
	CheckBox Check_DataAcq_04,userdata(tabnum)=  "0",userdata(tabcontrol)=  "ADC"
	CheckBox Check_DataAcq_04,userdata(ResizeControlsInfo)= A"!!,H9!!#?m!!#=#!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_DataAcq_04,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_DataAcq_04,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_DataAcq_04,value= 0
	CheckBox Check_DataAcq_05,pos={317,86},size={24,14},disable=1,proc=CheckProc_HeadstageCheck,title="5"
	CheckBox Check_DataAcq_05,userdata(tabnum)=  "0",userdata(tabcontrol)=  "ADC"
	CheckBox Check_DataAcq_05,userdata(ResizeControlsInfo)= A"!!,HK!!#?m!!#=#!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_DataAcq_05,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_DataAcq_05,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_DataAcq_05,value= 1
	CheckBox Check_DataAcq_06,pos={351,86},size={24,14},disable=1,proc=CheckProc_HeadstageCheck,title="6"
	CheckBox Check_DataAcq_06,userdata(tabnum)=  "0",userdata(tabcontrol)=  "ADC"
	CheckBox Check_DataAcq_06,userdata(ResizeControlsInfo)= A"!!,H\\!!#?m!!#=#!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_DataAcq_06,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_DataAcq_06,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_DataAcq_06,value= 0
	CheckBox Check_DataAcq_07,pos={385,85},size={24,14},disable=1,proc=CheckProc_HeadstageCheck,title="7"
	CheckBox Check_DataAcq_07,userdata(tabnum)=  "0",userdata(tabcontrol)=  "ADC"
	CheckBox Check_DataAcq_07,userdata(ResizeControlsInfo)= A"!!,Hm!!#?k!!#=#!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_DataAcq_07,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_DataAcq_07,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_DataAcq_07,value= 0
	CheckBox Radio_ClampMode_1,pos={148,111},size={16,14},disable=1,proc=CheckProc_ClampMode,title=""
	CheckBox Radio_ClampMode_1,userdata(tabnum)=  "0",userdata(tabcontrol)=  "ADC"
	CheckBox Radio_ClampMode_1,userdata(ResizeControlsInfo)= A"!!,FS!!#@J!!#<8!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Radio_ClampMode_1,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Radio_ClampMode_1,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Radio_ClampMode_1,value= 0,mode=1
	CheckBox Radio_ClampMode_2,pos={181,62},size={16,14},disable=1,proc=CheckProc_ClampMode,title=""
	CheckBox Radio_ClampMode_2,userdata(tabnum)=  "0",userdata(tabcontrol)=  "ADC"
	CheckBox Radio_ClampMode_2,userdata(ResizeControlsInfo)= A"!!,G(!!#?=!!#<8!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Radio_ClampMode_2,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Radio_ClampMode_2,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Radio_ClampMode_2,value= 1,mode=1
	CheckBox Radio_ClampMode_3,pos={181,111},size={16,14},disable=1,proc=CheckProc_ClampMode,title=""
	CheckBox Radio_ClampMode_3,userdata(tabnum)=  "0",userdata(tabcontrol)=  "ADC"
	CheckBox Radio_ClampMode_3,userdata(ResizeControlsInfo)= A"!!,G(!!#@J!!#<8!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Radio_ClampMode_3,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Radio_ClampMode_3,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Radio_ClampMode_3,value= 0,mode=1
	CheckBox Radio_ClampMode_4,pos={215,62},size={16,14},disable=1,proc=CheckProc_ClampMode,title=""
	CheckBox Radio_ClampMode_4,userdata(tabnum)=  "0",userdata(tabcontrol)=  "ADC"
	CheckBox Radio_ClampMode_4,userdata(ResizeControlsInfo)= A"!!,GJ!!#?=!!#<8!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Radio_ClampMode_4,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Radio_ClampMode_4,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Radio_ClampMode_4,value= 1,mode=1
	CheckBox Radio_ClampMode_5,pos={215,111},size={16,14},disable=1,proc=CheckProc_ClampMode,title=""
	CheckBox Radio_ClampMode_5,userdata(tabnum)=  "0",userdata(tabcontrol)=  "ADC"
	CheckBox Radio_ClampMode_5,userdata(ResizeControlsInfo)= A"!!,GJ!!#@J!!#<8!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Radio_ClampMode_5,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Radio_ClampMode_5,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Radio_ClampMode_5,value= 0,mode=1
	CheckBox Radio_ClampMode_6,pos={249,62},size={16,14},disable=1,proc=CheckProc_ClampMode,title=""
	CheckBox Radio_ClampMode_6,userdata(tabnum)=  "0",userdata(tabcontrol)=  "ADC"
	CheckBox Radio_ClampMode_6,userdata(ResizeControlsInfo)= A"!!,Gl!!#?=!!#<8!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Radio_ClampMode_6,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Radio_ClampMode_6,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Radio_ClampMode_6,value= 1,mode=1
	CheckBox Radio_ClampMode_7,pos={249,111},size={16,14},disable=1,proc=CheckProc_ClampMode,title=""
	CheckBox Radio_ClampMode_7,userdata(tabnum)=  "0",userdata(tabcontrol)=  "ADC"
	CheckBox Radio_ClampMode_7,userdata(ResizeControlsInfo)= A"!!,Gl!!#@J!!#<8!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Radio_ClampMode_7,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Radio_ClampMode_7,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Radio_ClampMode_7,value= 0,mode=1
	CheckBox Radio_ClampMode_8,pos={283,62},size={16,14},disable=1,proc=CheckProc_ClampMode,title=""
	CheckBox Radio_ClampMode_8,userdata(tabnum)=  "0",userdata(tabcontrol)=  "ADC"
	CheckBox Radio_ClampMode_8,userdata(ResizeControlsInfo)= A"!!,H9!!#?=!!#<8!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Radio_ClampMode_8,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Radio_ClampMode_8,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Radio_ClampMode_8,value= 1,mode=1
	CheckBox Radio_ClampMode_9,pos={283,111},size={16,14},disable=1,proc=CheckProc_ClampMode,title=""
	CheckBox Radio_ClampMode_9,userdata(tabnum)=  "0",userdata(tabcontrol)=  "ADC"
	CheckBox Radio_ClampMode_9,userdata(ResizeControlsInfo)= A"!!,H9!!#@J!!#<8!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Radio_ClampMode_9,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Radio_ClampMode_9,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Radio_ClampMode_9,value= 0,mode=1
	CheckBox Radio_ClampMode_10,pos={317,62},size={16,14},disable=1,proc=CheckProc_ClampMode,title=""
	CheckBox Radio_ClampMode_10,userdata(tabnum)=  "0",userdata(tabcontrol)=  "ADC"
	CheckBox Radio_ClampMode_10,userdata(ResizeControlsInfo)= A"!!,HK!!#?=!!#<8!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Radio_ClampMode_10,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Radio_ClampMode_10,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Radio_ClampMode_10,value= 1,mode=1
	CheckBox Radio_ClampMode_11,pos={317,111},size={16,14},disable=1,proc=CheckProc_ClampMode,title=""
	CheckBox Radio_ClampMode_11,userdata(tabnum)=  "0",userdata(tabcontrol)=  "ADC"
	CheckBox Radio_ClampMode_11,userdata(ResizeControlsInfo)= A"!!,HK!!#@J!!#<8!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Radio_ClampMode_11,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Radio_ClampMode_11,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Radio_ClampMode_11,value= 0,mode=1
	CheckBox Radio_ClampMode_12,pos={351,62},size={16,14},disable=1,proc=CheckProc_ClampMode,title=""
	CheckBox Radio_ClampMode_12,userdata(tabnum)=  "0",userdata(tabcontrol)=  "ADC"
	CheckBox Radio_ClampMode_12,userdata(ResizeControlsInfo)= A"!!,H\\!!#?=!!#<8!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Radio_ClampMode_12,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Radio_ClampMode_12,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Radio_ClampMode_12,value= 1,mode=1
	CheckBox Radio_ClampMode_13,pos={351,111},size={16,14},disable=1,proc=CheckProc_ClampMode,title=""
	CheckBox Radio_ClampMode_13,userdata(tabnum)=  "0",userdata(tabcontrol)=  "ADC"
	CheckBox Radio_ClampMode_13,userdata(ResizeControlsInfo)= A"!!,H\\!!#@J!!#<8!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Radio_ClampMode_13,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Radio_ClampMode_13,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Radio_ClampMode_13,value= 0,mode=1
	CheckBox Radio_ClampMode_14,pos={385,62},size={16,14},disable=1,proc=CheckProc_ClampMode,title=""
	CheckBox Radio_ClampMode_14,userdata(tabnum)=  "0",userdata(tabcontrol)=  "ADC"
	CheckBox Radio_ClampMode_14,userdata(ResizeControlsInfo)= A"!!,Hm!!#?=!!#<8!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Radio_ClampMode_14,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Radio_ClampMode_14,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Radio_ClampMode_14,value= 1,mode=1
	CheckBox Radio_ClampMode_15,pos={385,111},size={16,14},disable=1,proc=CheckProc_ClampMode,title=""
	CheckBox Radio_ClampMode_15,userdata(tabnum)=  "0",userdata(tabcontrol)=  "ADC"
	CheckBox Radio_ClampMode_15,userdata(ResizeControlsInfo)= A"!!,Hm!!#@J!!#<8!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Radio_ClampMode_15,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Radio_ClampMode_15,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Radio_ClampMode_15,value= 0,mode=1
	TitleBox Title_settings_ChanlAssign,pos={15,200},size={390,135},disable=1,title="Channel and Amplifier Assignments"
	TitleBox Title_settings_ChanlAssign,userdata(tabnum)=  "6"
	TitleBox Title_settings_ChanlAssign,userdata(tabcontrol)=  "ADC"
	TitleBox Title_settings_ChanlAssign,userdata(ResizeControlsInfo)= A"!!,A.!!#@i!!#Bs!!#@kz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox Title_settings_ChanlAssign,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	TitleBox Title_settings_ChanlAssign,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	TitleBox Title_settings_ChanlAssign,font="Trebuchet MS",frame=4,fStyle=0
	TitleBox Title_settings_ChanlAssign,fixedSize=1
	PopupMenu Popup_Settings_VC_DA,pos={35,272},size={53,21},disable=1,proc=PopMenuProc,title="DA"
	PopupMenu Popup_Settings_VC_DA,userdata(tabnum)=  "6"
	PopupMenu Popup_Settings_VC_DA,userdata(tabcontrol)=  "ADC"
	PopupMenu Popup_Settings_VC_DA,userdata(ResizeControlsInfo)= A"!!,B9!!#Ab!!#>b!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Popup_Settings_VC_DA,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Popup_Settings_VC_DA,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Popup_Settings_VC_DA,mode=2,popvalue="1",value= #"\"0;1;2;3;4;5;6;7\""
	PopupMenu Popup_Settings_VC_AD,pos={35,295},size={53,21},disable=1,proc=PopMenuProc,title="AD"
	PopupMenu Popup_Settings_VC_AD,userdata(tabnum)=  "6"
	PopupMenu Popup_Settings_VC_AD,userdata(tabcontrol)=  "ADC"
	PopupMenu Popup_Settings_VC_AD,userdata(ResizeControlsInfo)= A"!!,B9!!#B$!!#>b!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Popup_Settings_VC_AD,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Popup_Settings_VC_AD,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Popup_Settings_VC_AD,mode=3,popvalue="2",value= #"\"0;1;2;3;4;5;6;7;8;9;10;11;12;13;14;15\""
	PopupMenu Popup_Settings_IC_AD,pos={149,295},size={53,21},disable=1,proc=PopMenuProc,title="AD"
	PopupMenu Popup_Settings_IC_AD,userdata(tabnum)=  "6"
	PopupMenu Popup_Settings_IC_AD,userdata(tabcontrol)=  "ADC"
	PopupMenu Popup_Settings_IC_AD,userdata(ResizeControlsInfo)= A"!!,Fg!!#B$!!#>b!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Popup_Settings_IC_AD,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Popup_Settings_IC_AD,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Popup_Settings_IC_AD,mode=5,popvalue="4",value= #"\"0;1;2;3;4;5;6;7;8;9;10;11;12;13;14;15\""
	SetVariable setvar_Settings_VC_DAgain,pos={94,275},size={50,16},disable=1,proc=SetVarProc_CAA
	SetVariable setvar_Settings_VC_DAgain,userdata(tabnum)=  "6"
	SetVariable setvar_Settings_VC_DAgain,userdata(tabcontrol)=  "ADC"
	SetVariable setvar_Settings_VC_DAgain,userdata(ResizeControlsInfo)= A"!!,EP!!#Ae!!#>V!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_Settings_VC_DAgain,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_Settings_VC_DAgain,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_Settings_VC_DAgain,value= _NUM:20
	SetVariable setvar_Settings_VC_ADgain_0,pos={94,298},size={50,16},disable=1,proc=SetVarProc_CAA
	SetVariable setvar_Settings_VC_ADgain_0,userdata(tabnum)=  "6"
	SetVariable setvar_Settings_VC_ADgain_0,userdata(tabcontrol)=  "ADC"
	SetVariable setvar_Settings_VC_ADgain_0,userdata(ResizeControlsInfo)= A"!!,EP!!#B'!!#>V!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_Settings_VC_ADgain_0,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_Settings_VC_ADgain_0,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_Settings_VC_ADgain_0,value= _NUM:0.5
	SetVariable setvar_Settings_IC_ADgain,pos={208,298},size={50,16},disable=1,proc=SetVarProc_CAA
	SetVariable setvar_Settings_IC_ADgain,userdata(tabnum)=  "6"
	SetVariable setvar_Settings_IC_ADgain,userdata(tabcontrol)=  "ADC"
	SetVariable setvar_Settings_IC_ADgain,userdata(ResizeControlsInfo)= A"!!,GM!!#B'!!#>V!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_Settings_IC_ADgain,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_Settings_IC_ADgain,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_Settings_IC_ADgain,value= _NUM:1
	PopupMenu Popup_Settings_HeadStage,pos={35,228},size={95,21},disable=1,proc=PopMenuProc_Headstage,title="Head Stage"
	PopupMenu Popup_Settings_HeadStage,userdata(tabnum)=  "6"
	PopupMenu Popup_Settings_HeadStage,userdata(tabcontrol)=  "ADC"
	PopupMenu Popup_Settings_HeadStage,userdata(ResizeControlsInfo)= A"!!,B9!!#A6!!#@\"!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Popup_Settings_HeadStage,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Popup_Settings_HeadStage,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Popup_Settings_HeadStage,mode=2,popvalue="1",value= #"\"0;1;2;3;4;5;6;7\""
	PopupMenu popup_Settings_Amplifier,pos={168,228},size={224,21},bodyWidth=150,disable=1,proc=PopMenuProc,title="Amplfier (700B)"
	PopupMenu popup_Settings_Amplifier,userdata(tabnum)=  "6"
	PopupMenu popup_Settings_Amplifier,userdata(tabcontrol)=  "ADC"
	PopupMenu popup_Settings_Amplifier,userdata(ResizeControlsInfo)= A"!!,G%!!#A6!!#Ao!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu popup_Settings_Amplifier,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu popup_Settings_Amplifier,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu popup_Settings_Amplifier,mode=5,popvalue="AmpNo 832774 Chan 2",value= #"\"- none -;\"+ ReturnListOf700BChannels()"
	PopupMenu Popup_Settings_IC_DA,pos={149,272},size={53,21},disable=1,proc=PopMenuProc,title="DA"
	PopupMenu Popup_Settings_IC_DA,userdata(tabnum)=  "6"
	PopupMenu Popup_Settings_IC_DA,userdata(tabcontrol)=  "ADC"
	PopupMenu Popup_Settings_IC_DA,userdata(ResizeControlsInfo)= A"!!,Fg!!#Ab!!#>b!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Popup_Settings_IC_DA,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Popup_Settings_IC_DA,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Popup_Settings_IC_DA,mode=4,popvalue="3",value= #"\"0;1;2;3;4;5;6;7\""
	SetVariable setvar_Settings_IC_DAgain,pos={208,275},size={50,16},disable=1,proc=SetVarProc_CAA
	SetVariable setvar_Settings_IC_DAgain,userdata(tabnum)=  "6"
	SetVariable setvar_Settings_IC_DAgain,userdata(tabcontrol)=  "ADC"
	SetVariable setvar_Settings_IC_DAgain,userdata(ResizeControlsInfo)= A"!!,GM!!#Ae!!#>V!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_Settings_IC_DAgain,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_Settings_IC_DAgain,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_Settings_IC_DAgain,value= _NUM:1
	TitleBox Title_settings_ChanlAssign_VC,pos={75,253},size={39,13},disable=1,title="V-Clamp"
	TitleBox Title_settings_ChanlAssign_VC,userdata(tabnum)=  "6"
	TitleBox Title_settings_ChanlAssign_VC,userdata(tabcontrol)=  "ADC"
	TitleBox Title_settings_ChanlAssign_VC,userdata(ResizeControlsInfo)= A"!!,Do!!#AO!!#>*!!#;]z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox Title_settings_ChanlAssign_VC,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	TitleBox Title_settings_ChanlAssign_VC,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	TitleBox Title_settings_ChanlAssign_VC,frame=0
	TitleBox Title_settings_ChanlAssign_IC,pos={182,253},size={35,13},disable=1,title="I-Clamp"
	TitleBox Title_settings_ChanlAssign_IC,userdata(tabnum)=  "6"
	TitleBox Title_settings_ChanlAssign_IC,userdata(tabcontrol)=  "ADC"
	TitleBox Title_settings_ChanlAssign_IC,userdata(ResizeControlsInfo)= A"!!,G3!!#AO!!#=o!!#;]z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox Title_settings_ChanlAssign_IC,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	TitleBox Title_settings_ChanlAssign_IC,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	TitleBox Title_settings_ChanlAssign_IC,frame=0
	Button button_Settings_UpdateAmpStatus,pos={290,254},size={100,30},disable=1,proc=ButtonProc,title="Query connected\rAmp(s)"
	Button button_Settings_UpdateAmpStatus,userdata(tabnum)=  "6"
	Button button_Settings_UpdateAmpStatus,userdata(tabcontrol)=  "ADC"
	Button button_Settings_UpdateAmpStatus,userdata(ResizeControlsInfo)= A"!!,HBJ,hr&!!#@,!!#=Sz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_Settings_UpdateAmpStatus,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button button_Settings_UpdateAmpStatus,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Search_DA_00,pos={114,97},size={124,16},disable=1,proc=SetVarProc_DASearch,title="Search string"
	SetVariable Search_DA_00,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	SetVariable Search_DA_00,userdata(ResizeControlsInfo)= A"!!,FI!!#@&!!#@\\!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Search_DA_00,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Search_DA_00,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Search_DA_00,value= _STR:""
	SetVariable Search_DA_01,pos={114,144},size={124,16},disable=1,proc=SetVarProc_DASearch,title="Search string"
	SetVariable Search_DA_01,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	SetVariable Search_DA_01,userdata(ResizeControlsInfo)= A"!!,FI!!#@t!!#@\\!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Search_DA_01,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Search_DA_01,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Search_DA_01,value= _STR:""
	SetVariable Search_DA_02,pos={114,191},size={124,16},disable=1,proc=SetVarProc_DASearch,title="Search string"
	SetVariable Search_DA_02,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	SetVariable Search_DA_02,userdata(ResizeControlsInfo)= A"!!,FI!!#AN!!#@\\!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Search_DA_02,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Search_DA_02,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Search_DA_02,value= _STR:""
	SetVariable Search_DA_03,pos={114,238},size={124,16},disable=1,proc=SetVarProc_DASearch,title="Search string"
	SetVariable Search_DA_03,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	SetVariable Search_DA_03,userdata(ResizeControlsInfo)= A"!!,FI!!#B(!!#@\\!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Search_DA_03,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Search_DA_03,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Search_DA_03,value= _STR:""
	SetVariable Search_DA_04,pos={114,284},size={124,16},disable=1,proc=SetVarProc_DASearch,title="Search string"
	SetVariable Search_DA_04,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	SetVariable Search_DA_04,userdata(ResizeControlsInfo)= A"!!,FI!!#BH!!#@\\!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Search_DA_04,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Search_DA_04,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Search_DA_04,value= _STR:""
	SetVariable Search_DA_05,pos={114,331},size={124,16},disable=1,proc=SetVarProc_DASearch,title="Search string"
	SetVariable Search_DA_05,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	SetVariable Search_DA_05,userdata(ResizeControlsInfo)= A"!!,FI!!#B_J,hq2!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Search_DA_05,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Search_DA_05,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Search_DA_05,value= _STR:""
	SetVariable Search_DA_06,pos={114,378},size={124,16},disable=1,proc=SetVarProc_DASearch,title="Search string"
	SetVariable Search_DA_06,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	SetVariable Search_DA_06,userdata(ResizeControlsInfo)= A"!!,FI!!#C\"!!#@\\!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Search_DA_06,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Search_DA_06,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Search_DA_06,value= _STR:""
	SetVariable Search_DA_07,pos={114,426},size={124,16},disable=1,proc=SetVarProc_DASearch,title="Search string"
	SetVariable Search_DA_07,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	SetVariable Search_DA_07,userdata(ResizeControlsInfo)= A"!!,FI!!#C:!!#@\\!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Search_DA_07,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Search_DA_07,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Search_DA_07,value= _STR:""
	CheckBox SearchUniversal_DA_00,pos={246,98},size={69,14},disable=1,proc=CheckProc_UniversalSearchString,title="Apply to all"
	CheckBox SearchUniversal_DA_00,userdata(tabnum)=  "1"
	CheckBox SearchUniversal_DA_00,userdata(tabcontrol)=  "ADC"
	CheckBox SearchUniversal_DA_00,userdata(ResizeControlsInfo)= A"!!,H1!!#@(!!#?C!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox SearchUniversal_DA_00,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox SearchUniversal_DA_00,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox SearchUniversal_DA_00,value= 1
	SetVariable Search_TTL_00,pos={102,94},size={124,16},disable=1,proc=SetVarProc_TTLSearch,title="Search string"
	SetVariable Search_TTL_00,userdata(tabnum)=  "3",userdata(tabcontrol)=  "ADC"
	SetVariable Search_TTL_00,userdata(ResizeControlsInfo)= A"!!,F1!!#?u!!#@\\!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Search_TTL_00,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Search_TTL_00,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Search_TTL_00,value= _STR:""
	SetVariable Search_TTL_01,pos={102,140},size={124,16},disable=1,proc=SetVarProc_TTLSearch,title="Search string"
	SetVariable Search_TTL_01,userdata(tabnum)=  "3",userdata(tabcontrol)=  "ADC"
	SetVariable Search_TTL_01,userdata(ResizeControlsInfo)= A"!!,F1!!#@p!!#@\\!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Search_TTL_01,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Search_TTL_01,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Search_TTL_01,value= _STR:""
	SetVariable Search_TTL_02,pos={102,187},size={124,16},disable=1,proc=SetVarProc_TTLSearch,title="Search string"
	SetVariable Search_TTL_02,userdata(tabnum)=  "3",userdata(tabcontrol)=  "ADC"
	SetVariable Search_TTL_02,userdata(ResizeControlsInfo)= A"!!,F1!!#AJ!!#@\\!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Search_TTL_02,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Search_TTL_02,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Search_TTL_02,value= _STR:""
	SetVariable Search_TTL_03,pos={102,233},size={124,16},disable=1,proc=SetVarProc_TTLSearch,title="Search string"
	SetVariable Search_TTL_03,userdata(tabnum)=  "3",userdata(tabcontrol)=  "ADC"
	SetVariable Search_TTL_03,userdata(ResizeControlsInfo)= A"!!,F1!!#B#!!#@\\!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Search_TTL_03,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Search_TTL_03,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Search_TTL_03,value= _STR:""
	SetVariable Search_TTL_04,pos={102,279},size={124,16},disable=1,proc=SetVarProc_TTLSearch,title="Search string"
	SetVariable Search_TTL_04,userdata(tabnum)=  "3",userdata(tabcontrol)=  "ADC"
	SetVariable Search_TTL_04,userdata(ResizeControlsInfo)= A"!!,F1!!#BEJ,hq2!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Search_TTL_04,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Search_TTL_04,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Search_TTL_04,value= _STR:""
	SetVariable Search_TTL_05,pos={102,325},size={124,16},disable=1,proc=SetVarProc_TTLSearch,title="Search string"
	SetVariable Search_TTL_05,userdata(tabnum)=  "3",userdata(tabcontrol)=  "ADC"
	SetVariable Search_TTL_05,userdata(ResizeControlsInfo)= A"!!,F1!!#B\\J,hq2!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Search_TTL_05,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Search_TTL_05,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Search_TTL_05,value= _STR:""
	SetVariable Search_TTL_06,pos={102,371},size={124,16},disable=1,proc=SetVarProc_TTLSearch,title="Search string"
	SetVariable Search_TTL_06,userdata(tabnum)=  "3",userdata(tabcontrol)=  "ADC"
	SetVariable Search_TTL_06,userdata(ResizeControlsInfo)= A"!!,F1!!#BsJ,hq2!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Search_TTL_06,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Search_TTL_06,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Search_TTL_06,value= _STR:""
	SetVariable Search_TTL_07,pos={102,419},size={124,16},disable=1,proc=SetVarProc_TTLSearch,title="Search string"
	SetVariable Search_TTL_07,userdata(tabnum)=  "3",userdata(tabcontrol)=  "ADC"
	SetVariable Search_TTL_07,userdata(ResizeControlsInfo)= A"!!,F1!!#C6J,hq2!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable Search_TTL_07,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable Search_TTL_07,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable Search_TTL_07,value= _STR:""
	CheckBox SearchUniversal_TTL_00,pos={235,95},size={69,14},disable=1,proc=CheckProc_UniversalSearchTTL,title="Apply to all"
	CheckBox SearchUniversal_TTL_00,userdata(tabnum)=  "3"
	CheckBox SearchUniversal_TTL_00,userdata(tabcontrol)=  "ADC"
	CheckBox SearchUniversal_TTL_00,userdata(ResizeControlsInfo)= A"!!,H&!!#@\"!!#?C!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox SearchUniversal_TTL_00,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox SearchUniversal_TTL_00,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox SearchUniversal_TTL_00,value= 1
	TitleBox Sensitivity_DA_00,pos={246,428},size={172,13},disable=1,title="V-Clamp: mV/V  I-Clamp: pA/V"
	TitleBox Sensitivity_DA_00,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	TitleBox Sensitivity_DA_00,userdata(ResizeControlsInfo)= A"!!,H1!!#C;!!#A;!!#;]z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox Sensitivity_DA_00,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	TitleBox Sensitivity_DA_00,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	TitleBox Sensitivity_DA_00,fSize=6,frame=0,fStyle=1
	CheckBox Check_DataAcq1_Indexing,pos={100,353},size={58,14},disable=1,proc=CheckProc_Indexing,title="Indexing"
	CheckBox Check_DataAcq1_Indexing,help={"Data acquisition proceeds to next wave in DAC or TTL popup menu list"}
	CheckBox Check_DataAcq1_Indexing,userdata(tabnum)=  "0"
	CheckBox Check_DataAcq1_Indexing,userdata(tabcontrol)=  "ADC"
	CheckBox Check_DataAcq1_Indexing,userdata(ResizeControlsInfo)= A"!!,CT!!#Bp!!#?!!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_DataAcq1_Indexing,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox Check_DataAcq1_Indexing,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox Check_DataAcq1_Indexing,value= 0
	TitleBox Title_DAC_IndexStartEnd,pos={292,53},size={111,13},disable=1,title="\\JCIndexing End Wave"
	TitleBox Title_DAC_IndexStartEnd,userdata(tabnum)=  "1"
	TitleBox Title_DAC_IndexStartEnd,userdata(tabcontrol)=  "ADC"
	TitleBox Title_DAC_IndexStartEnd,userdata(ResizeControlsInfo)= A"!!,HM!!#>b!!#@B!!#;]z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox Title_DAC_IndexStartEnd,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	TitleBox Title_DAC_IndexStartEnd,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	TitleBox Title_DAC_IndexStartEnd,frame=0,fStyle=1,anchor= LC
	TitleBox Title_DAC_Gain,pos={74,52},size={26,13},disable=1,title="Gain"
	TitleBox Title_DAC_Gain,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	TitleBox Title_DAC_Gain,userdata(ResizeControlsInfo)= A"!!,EN!!#>^!!#=3!!#;]z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox Title_DAC_Gain,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	TitleBox Title_DAC_Gain,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	TitleBox Title_DAC_Gain,frame=0,fStyle=1
	TitleBox Title_DAC_DAWaveSelect,pos={114,52},size={127,13},disable=1,title="(first) DA Wave Select"
	TitleBox Title_DAC_DAWaveSelect,userdata(tabnum)=  "1"
	TitleBox Title_DAC_DAWaveSelect,userdata(tabcontrol)=  "ADC"
	TitleBox Title_DAC_DAWaveSelect,userdata(ResizeControlsInfo)= A"!!,FI!!#>^!!#@b!!#;]z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox Title_DAC_DAWaveSelect,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	TitleBox Title_DAC_DAWaveSelect,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	TitleBox Title_DAC_DAWaveSelect,frame=0,fStyle=1
	TitleBox Title_DAC_Scale,pos={245,53},size={32,13},disable=1,title="Scale"
	TitleBox Title_DAC_Scale,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	TitleBox Title_DAC_Scale,userdata(ResizeControlsInfo)= A"!!,H0!!#>b!!#=c!!#;]z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox Title_DAC_Scale,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	TitleBox Title_DAC_Scale,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	TitleBox Title_DAC_Scale,frame=0,fStyle=1
	TitleBox Title_DAC_Channel,pos={20,52},size={29,13},disable=1,title="Chan"
	TitleBox Title_DAC_Channel,userdata(tabnum)=  "1",userdata(tabcontrol)=  "ADC"
	TitleBox Title_DAC_Channel,userdata(ResizeControlsInfo)= A"!!,BY!!#>^!!#=K!!#;]z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox Title_DAC_Channel,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	TitleBox Title_DAC_Channel,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	TitleBox Title_DAC_Channel,frame=0,fStyle=1
	PopupMenu Popup_DA_IndexEnd_00,pos={289,72},size={125,21},bodyWidth=125,disable=1,proc=ITCP_PopMenuCheckProc_DAC
	PopupMenu Popup_DA_IndexEnd_00,userdata(tabnum)=  "1"
	PopupMenu Popup_DA_IndexEnd_00,userdata(tabcontrol)=  "ADC"
	PopupMenu Popup_DA_IndexEnd_00,userdata(ResizeControlsInfo)= A"!!,HKJ,hot!!#@^!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Popup_DA_IndexEnd_00,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Popup_DA_IndexEnd_00,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Popup_DA_IndexEnd_00,mode=1,popvalue="- none -",value= #"\"- none -; TestPulse;alpha_DAC_1;\""
	PopupMenu Popup_DA_IndexEnd_01,pos={289,118},size={125,21},bodyWidth=125,disable=1,proc=ITCP_PopMenuCheckProc_DAC
	PopupMenu Popup_DA_IndexEnd_01,userdata(tabnum)=  "1"
	PopupMenu Popup_DA_IndexEnd_01,userdata(tabcontrol)=  "ADC"
	PopupMenu Popup_DA_IndexEnd_01,userdata(ResizeControlsInfo)= A"!!,HKJ,hq&!!#@^!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Popup_DA_IndexEnd_01,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Popup_DA_IndexEnd_01,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Popup_DA_IndexEnd_01,mode=1,popvalue="- none -",value= #"\"- none -; TestPulse;alpha_DAC_1;\""
	PopupMenu Popup_DA_IndexEnd_02,pos={289,165},size={125,21},bodyWidth=125,disable=1,proc=ITCP_PopMenuCheckProc_DAC
	PopupMenu Popup_DA_IndexEnd_02,userdata(tabnum)=  "1"
	PopupMenu Popup_DA_IndexEnd_02,userdata(tabcontrol)=  "ADC"
	PopupMenu Popup_DA_IndexEnd_02,userdata(ResizeControlsInfo)= A"!!,HKJ,hq_!!#@^!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Popup_DA_IndexEnd_02,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Popup_DA_IndexEnd_02,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Popup_DA_IndexEnd_02,mode=1,popvalue="- none -",value= #"\"- none -; TestPulse;alpha_DAC_1;\""
	PopupMenu Popup_DA_IndexEnd_03,pos={289,212},size={125,21},bodyWidth=125,disable=1,proc=ITCP_PopMenuCheckProc_DAC
	PopupMenu Popup_DA_IndexEnd_03,userdata(tabnum)=  "1"
	PopupMenu Popup_DA_IndexEnd_03,userdata(tabcontrol)=  "ADC"
	PopupMenu Popup_DA_IndexEnd_03,userdata(ResizeControlsInfo)= A"!!,HKJ,hr9!!#@^!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Popup_DA_IndexEnd_03,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Popup_DA_IndexEnd_03,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Popup_DA_IndexEnd_03,mode=1,popvalue="- none -",value= #"\"- none -; TestPulse;alpha_DAC_1;\""
	PopupMenu Popup_DA_IndexEnd_04,pos={289,258},size={125,21},bodyWidth=125,disable=1,proc=ITCP_PopMenuCheckProc_DAC
	PopupMenu Popup_DA_IndexEnd_04,userdata(tabnum)=  "1"
	PopupMenu Popup_DA_IndexEnd_04,userdata(tabcontrol)=  "ADC"
	PopupMenu Popup_DA_IndexEnd_04,userdata(ResizeControlsInfo)= A"!!,HKJ,hrf!!#@^!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Popup_DA_IndexEnd_04,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Popup_DA_IndexEnd_04,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Popup_DA_IndexEnd_04,mode=1,popvalue="- none -",value= #"\"- none -; TestPulse;alpha_DAC_1;\""
	PopupMenu Popup_DA_IndexEnd_05,pos={289,305},size={125,21},bodyWidth=125,disable=1,proc=ITCP_PopMenuCheckProc_DAC
	PopupMenu Popup_DA_IndexEnd_05,userdata(tabnum)=  "1"
	PopupMenu Popup_DA_IndexEnd_05,userdata(tabcontrol)=  "ADC"
	PopupMenu Popup_DA_IndexEnd_05,userdata(ResizeControlsInfo)= A"!!,HKJ,hs(J,hq4!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Popup_DA_IndexEnd_05,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Popup_DA_IndexEnd_05,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Popup_DA_IndexEnd_05,mode=1,popvalue="- none -",value= #"\"- none -; TestPulse;alpha_DAC_1;\""
	PopupMenu Popup_DA_IndexEnd_06,pos={289,352},size={125,21},bodyWidth=125,disable=1,proc=ITCP_PopMenuCheckProc_DAC
	PopupMenu Popup_DA_IndexEnd_06,userdata(tabnum)=  "1"
	PopupMenu Popup_DA_IndexEnd_06,userdata(tabcontrol)=  "ADC"
	PopupMenu Popup_DA_IndexEnd_06,userdata(ResizeControlsInfo)= A"!!,HKJ,hs@!!#@^!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Popup_DA_IndexEnd_06,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Popup_DA_IndexEnd_06,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Popup_DA_IndexEnd_06,mode=1,popvalue="- none -",value= #"\"- none -; TestPulse;alpha_DAC_1;\""
	PopupMenu Popup_DA_IndexEnd_07,pos={289,399},size={125,21},bodyWidth=125,disable=1,proc=ITCP_PopMenuCheckProc_DAC
	PopupMenu Popup_DA_IndexEnd_07,userdata(tabnum)=  "1"
	PopupMenu Popup_DA_IndexEnd_07,userdata(tabcontrol)=  "ADC"
	PopupMenu Popup_DA_IndexEnd_07,userdata(ResizeControlsInfo)= A"!!,HKJ,hsWJ,hq4!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Popup_DA_IndexEnd_07,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Popup_DA_IndexEnd_07,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Popup_DA_IndexEnd_07,mode=1,popvalue="- none -",value= #"\"- none -; TestPulse;alpha_DAC_1;\""
	PopupMenu Popup_TTL_IndexEnd_00,pos={242,69},size={125,21},bodyWidth=125,disable=1,proc=ITCP_PopMenuCheckProc_DAC
	PopupMenu Popup_TTL_IndexEnd_00,userdata(tabnum)=  "3"
	PopupMenu Popup_TTL_IndexEnd_00,userdata(tabcontrol)=  "ADC"
	PopupMenu Popup_TTL_IndexEnd_00,userdata(ResizeControlsInfo)= A"!!,H-!!#?C!!#@^!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Popup_TTL_IndexEnd_00,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Popup_TTL_IndexEnd_00,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Popup_TTL_IndexEnd_00,mode=1,popvalue="- none -",value= #"\"- none -;doit_TTL_1;\""
	PopupMenu Popup_TTL_IndexEnd_01,pos={242,115},size={125,21},bodyWidth=125,disable=1,proc=ITCP_PopMenuCheckProc_DAC
	PopupMenu Popup_TTL_IndexEnd_01,userdata(tabnum)=  "3"
	PopupMenu Popup_TTL_IndexEnd_01,userdata(tabcontrol)=  "ADC"
	PopupMenu Popup_TTL_IndexEnd_01,userdata(ResizeControlsInfo)= A"!!,H-!!#@J!!#@^!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Popup_TTL_IndexEnd_01,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Popup_TTL_IndexEnd_01,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Popup_TTL_IndexEnd_01,mode=1,popvalue="- none -",value= #"\"- none -;doit_TTL_1;\""
	PopupMenu Popup_TTL_IndexEnd_02,pos={242,161},size={125,21},bodyWidth=125,disable=1,proc=ITCP_PopMenuCheckProc_DAC
	PopupMenu Popup_TTL_IndexEnd_02,userdata(tabnum)=  "3"
	PopupMenu Popup_TTL_IndexEnd_02,userdata(tabcontrol)=  "ADC"
	PopupMenu Popup_TTL_IndexEnd_02,userdata(ResizeControlsInfo)= A"!!,H-!!#A0!!#@^!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Popup_TTL_IndexEnd_02,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Popup_TTL_IndexEnd_02,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Popup_TTL_IndexEnd_02,mode=1,popvalue="- none -",value= #"\"- none -;doit_TTL_1;\""
	PopupMenu Popup_TTL_IndexEnd_03,pos={242,207},size={125,21},bodyWidth=125,disable=1,proc=ITCP_PopMenuCheckProc_DAC
	PopupMenu Popup_TTL_IndexEnd_03,userdata(tabnum)=  "3"
	PopupMenu Popup_TTL_IndexEnd_03,userdata(tabcontrol)=  "ADC"
	PopupMenu Popup_TTL_IndexEnd_03,userdata(ResizeControlsInfo)= A"!!,H-!!#A^!!#@^!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Popup_TTL_IndexEnd_03,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Popup_TTL_IndexEnd_03,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Popup_TTL_IndexEnd_03,mode=1,popvalue="- none -",value= #"\"- none -;doit_TTL_1;\""
	PopupMenu Popup_TTL_IndexEnd_04,pos={242,253},size={125,21},bodyWidth=125,disable=1,proc=ITCP_PopMenuCheckProc_DAC
	PopupMenu Popup_TTL_IndexEnd_04,userdata(tabnum)=  "3"
	PopupMenu Popup_TTL_IndexEnd_04,userdata(tabcontrol)=  "ADC"
	PopupMenu Popup_TTL_IndexEnd_04,userdata(ResizeControlsInfo)= A"!!,H-!!#B7!!#@^!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Popup_TTL_IndexEnd_04,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Popup_TTL_IndexEnd_04,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Popup_TTL_IndexEnd_04,mode=1,popvalue="- none -",value= #"\"- none -;doit_TTL_1;\""
	PopupMenu Popup_TTL_IndexEnd_05,pos={242,299},size={125,21},bodyWidth=125,disable=1,proc=ITCP_PopMenuCheckProc_DAC
	PopupMenu Popup_TTL_IndexEnd_05,userdata(tabnum)=  "3"
	PopupMenu Popup_TTL_IndexEnd_05,userdata(tabcontrol)=  "ADC"
	PopupMenu Popup_TTL_IndexEnd_05,userdata(ResizeControlsInfo)= A"!!,H-!!#BOJ,hq4!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Popup_TTL_IndexEnd_05,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Popup_TTL_IndexEnd_05,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Popup_TTL_IndexEnd_05,mode=1,popvalue="- none -",value= #"\"- none -;doit_TTL_1;\""
	PopupMenu Popup_TTL_IndexEnd_06,pos={242,345},size={125,21},bodyWidth=125,disable=1,proc=ITCP_PopMenuCheckProc_DAC
	PopupMenu Popup_TTL_IndexEnd_06,userdata(tabnum)=  "3"
	PopupMenu Popup_TTL_IndexEnd_06,userdata(tabcontrol)=  "ADC"
	PopupMenu Popup_TTL_IndexEnd_06,userdata(ResizeControlsInfo)= A"!!,H-!!#BfJ,hq4!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Popup_TTL_IndexEnd_06,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Popup_TTL_IndexEnd_06,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Popup_TTL_IndexEnd_06,mode=1,popvalue="- none -",value= #"\"- none -;doit_TTL_1;\""
	PopupMenu Popup_TTL_IndexEnd_07,pos={242,392},size={125,21},bodyWidth=125,disable=1,proc=ITCP_PopMenuCheckProc_DAC
	PopupMenu Popup_TTL_IndexEnd_07,userdata(tabnum)=  "3"
	PopupMenu Popup_TTL_IndexEnd_07,userdata(tabcontrol)=  "ADC"
	PopupMenu Popup_TTL_IndexEnd_07,userdata(ResizeControlsInfo)= A"!!,H-!!#C)!!#@^!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu Popup_TTL_IndexEnd_07,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu Popup_TTL_IndexEnd_07,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu Popup_TTL_IndexEnd_07,mode=1,popvalue="- none -",value= #"\"- none -;doit_TTL_1;\""
	CheckBox check_Settings_ShowScopeWindow,pos={36,406},size={121,14},proc=CheckProc_2,title="Show Scope Window"
	CheckBox check_Settings_ShowScopeWindow,help={"Enable the scope window to view ongoing acquistion"}
	CheckBox check_Settings_ShowScopeWindow,userdata(tabnum)=  "5"
	CheckBox check_Settings_ShowScopeWindow,userdata(tabcontrol)=  "ADC",value= 0
	TitleBox Title_ADC_Sensitivity,pos={85,414},size={168,13},disable=1,title="V-Clamp: V/nA  I-Clamp:V/mV"
	TitleBox Title_ADC_Sensitivity,userdata(tabnum)=  "2"
	TitleBox Title_ADC_Sensitivity,userdata(tabcontrol)=  "ADC",fSize=6,frame=0
	TitleBox Title_ADC_Sensitivity,fStyle=1
	Button Button_TTL_TurnOffAllTTLs,pos={21,422},size={67,40},disable=1,proc=ButtonProc_2,title="Turn off\rall TTLs"
	Button Button_TTL_TurnOffAllTTLs,userdata(tabnum)=  "3"
	Button Button_TTL_TurnOffAllTTLs,userdata(tabcontrol)=  "ADC"
	Button Button_DAC_TurnOFFDACs,pos={16,426},size={73,37},disable=1,proc=ButtonProc_3,title="Turn Off\rAll DACs"
	Button Button_DAC_TurnOFFDACs,userdata(tabnum)=  "1"
	Button Button_DAC_TurnOFFDACs,userdata(tabcontrol)=  "ADC"
	Button Button_ADC_TurnOffAllADCs,pos={12,403},size={59,41},disable=1,proc=ButtonProc_4,title="Turn Off\rAll ADCs"
	Button Button_ADC_TurnOffAllADCs,userdata(tabnum)=  "2"
	Button Button_ADC_TurnOffAllADCs,userdata(tabcontrol)=  "ADC"
	Button button_DataAcq_TurnOffAllChan,pos={251,327},size={112,21},proc=ButtonProc_5,title="Turn Off All Channels"
	Button button_DataAcq_TurnOffAllChan,userdata(tabnum)=  "5"
	Button button_DataAcq_TurnOffAllChan,userdata(tabcontrol)=  "ADC"
	CheckBox check_Settings_ITITP,pos={33,113},size={157,14},title="Activate Test pulse during ITI"
	CheckBox check_Settings_ITITP,userdata(tabnum)=  "5"
	CheckBox check_Settings_ITITP,userdata(tabcontrol)=  "ADC",value= 1
	ValDisplay valdisp_DataAcq_ITICountdown,pos={311,330},size={100,14},disable=1,title="ITI remaining"
	ValDisplay valdisp_DataAcq_ITICountdown,userdata(tabnum)=  "0"
	ValDisplay valdisp_DataAcq_ITICountdown,userdata(tabcontrol)=  "ADC"
	ValDisplay valdisp_DataAcq_ITICountdown,format="%0.2g"
	ValDisplay valdisp_DataAcq_ITICountdown,limits={0,0,0},barmisc={0,1000}
	ValDisplay valdisp_DataAcq_ITICountdown,value= _NUM:0.1
	ValDisplay valdisp_DataAcq_TrialsCountdown,pos={311,355},size={100,14},disable=1,title="Trials remaining"
	ValDisplay valdisp_DataAcq_TrialsCountdown,userdata(tabnum)=  "0"
	ValDisplay valdisp_DataAcq_TrialsCountdown,userdata(tabcontrol)=  "ADC"
	ValDisplay valdisp_DataAcq_TrialsCountdown,limits={0,0,0},barmisc={0,1000}
	ValDisplay valdisp_DataAcq_TrialsCountdown,value= _NUM:0
	CheckBox check_Settings_Overwrite,pos={33,136},size={294,14},title="Overwrite history and data waves on Next Sweep roll back"
	CheckBox check_Settings_Overwrite,help={"Overwrite occurs on next data acquisition cycle"}
	CheckBox check_Settings_Overwrite,userdata(tabnum)=  "5"
	CheckBox check_Settings_Overwrite,userdata(tabcontrol)=  "ADC",value= 1
	SetVariable setvar_Async_min_00,pos={113,66},size={71,16},disable=1,title="min"
	SetVariable setvar_Async_min_00,userdata(tabnum)=  "4"
	SetVariable setvar_Async_min_00,userdata(tabcontrol)=  "ADC",value= _NUM:1
	SetVariable setvar_Async_max_00,pos={197,66},size={76,16},disable=1,title="max"
	SetVariable setvar_Async_max_00,userdata(tabnum)=  "4"
	SetVariable setvar_Async_max_00,userdata(tabcontrol)=  "ADC",value= _NUM:1
	CheckBox check_Async_Alarm_00,pos={61,68},size={44,14},disable=1,title="Alarm"
	CheckBox check_Async_Alarm_00,userdata(tabnum)=  "4"
	CheckBox check_Async_Alarm_00,userdata(tabcontrol)=  "ADC",value= 1
	SetVariable setvar_Async_min_01,pos={113,117},size={71,16},disable=1,title="min"
	SetVariable setvar_Async_min_01,userdata(tabnum)=  "4"
	SetVariable setvar_Async_min_01,userdata(tabcontrol)=  "ADC",value= _NUM:0
	SetVariable setvar_Async_max_01,pos={197,117},size={76,16},disable=1,title="max"
	SetVariable setvar_Async_max_01,userdata(tabnum)=  "4"
	SetVariable setvar_Async_max_01,userdata(tabcontrol)=  "ADC",value= _NUM:0
	CheckBox check_Async_Alarm_01,pos={61,119},size={44,14},disable=1,title="Alarm"
	CheckBox check_Async_Alarm_01,userdata(tabnum)=  "4"
	CheckBox check_Async_Alarm_01,userdata(tabcontrol)=  "ADC",value= 0
	SetVariable setvar_Async_min_02,pos={113,169},size={71,16},disable=1,title="min"
	SetVariable setvar_Async_min_02,userdata(tabnum)=  "4"
	SetVariable setvar_Async_min_02,userdata(tabcontrol)=  "ADC",value= _NUM:0
	SetVariable setvar_Async_max_02,pos={197,169},size={76,16},disable=1,title="max"
	SetVariable setvar_Async_max_02,userdata(tabnum)=  "4"
	SetVariable setvar_Async_max_02,userdata(tabcontrol)=  "ADC",value= _NUM:0
	CheckBox check_Async_Alarm_02,pos={61,171},size={44,14},disable=1,title="Alarm"
	CheckBox check_Async_Alarm_02,userdata(tabnum)=  "4"
	CheckBox check_Async_Alarm_02,userdata(tabcontrol)=  "ADC",value= 0
	SetVariable setvar_Async_min_03,pos={113,220},size={71,16},disable=1,title="min"
	SetVariable setvar_Async_min_03,userdata(tabnum)=  "4"
	SetVariable setvar_Async_min_03,userdata(tabcontrol)=  "ADC",value= _NUM:0
	SetVariable setvar_Async_max_03,pos={197,220},size={76,16},disable=1,title="max"
	SetVariable setvar_Async_max_03,userdata(tabnum)=  "4"
	SetVariable setvar_Async_max_03,userdata(tabcontrol)=  "ADC",value= _NUM:0
	CheckBox check_Async_Alarm_03,pos={61,222},size={44,14},disable=1,title="Alarm"
	CheckBox check_Async_Alarm_03,userdata(tabnum)=  "4"
	CheckBox check_Async_Alarm_03,userdata(tabcontrol)=  "ADC",value= 0
	SetVariable setvar_Async_min_04,pos={113,272},size={71,16},disable=1,title="min"
	SetVariable setvar_Async_min_04,userdata(tabnum)=  "4"
	SetVariable setvar_Async_min_04,userdata(tabcontrol)=  "ADC",value= _NUM:0
	SetVariable setvar_Async_max_04,pos={197,272},size={76,16},disable=1,title="max"
	SetVariable setvar_Async_max_04,userdata(tabnum)=  "4"
	SetVariable setvar_Async_max_04,userdata(tabcontrol)=  "ADC",value= _NUM:0
	CheckBox check_Async_Alarm_04,pos={61,274},size={44,14},disable=1,title="Alarm"
	CheckBox check_Async_Alarm_04,userdata(tabnum)=  "4"
	CheckBox check_Async_Alarm_04,userdata(tabcontrol)=  "ADC",value= 0
	SetVariable setvar_Async_min_05,pos={113,323},size={71,16},disable=1,title="min"
	SetVariable setvar_Async_min_05,userdata(tabnum)=  "4"
	SetVariable setvar_Async_min_05,userdata(tabcontrol)=  "ADC",value= _NUM:0
	SetVariable setvar_Async_max_05,pos={197,323},size={76,16},disable=1,title="max"
	SetVariable setvar_Async_max_05,userdata(tabnum)=  "4"
	SetVariable setvar_Async_max_05,userdata(tabcontrol)=  "ADC",value= _NUM:0
	CheckBox check_Async_Alarm_05,pos={61,325},size={44,14},disable=1,title="Alarm"
	CheckBox check_Async_Alarm_05,userdata(tabnum)=  "4"
	CheckBox check_Async_Alarm_05,userdata(tabcontrol)=  "ADC",value= 0
	SetVariable setvar_Async_min_06,pos={113,375},size={71,16},disable=1,title="min"
	SetVariable setvar_Async_min_06,userdata(tabnum)=  "4"
	SetVariable setvar_Async_min_06,userdata(tabcontrol)=  "ADC",value= _NUM:0
	SetVariable setvar_Async_max_06,pos={197,375},size={76,16},disable=1,title="max"
	SetVariable setvar_Async_max_06,userdata(tabnum)=  "4"
	SetVariable setvar_Async_max_06,userdata(tabcontrol)=  "ADC",value= _NUM:0
	CheckBox check_Async_Alarm_06,pos={61,378},size={44,14},disable=1,title="Alarm"
	CheckBox check_Async_Alarm_06,userdata(tabnum)=  "4"
	CheckBox check_Async_Alarm_06,userdata(tabcontrol)=  "ADC",value= 0
	SetVariable setvar_Async_min_07,pos={113,427},size={71,16},disable=1,title="min"
	SetVariable setvar_Async_min_07,userdata(tabnum)=  "4"
	SetVariable setvar_Async_min_07,userdata(tabcontrol)=  "ADC",value= _NUM:0
	SetVariable setvar_Async_max_07,pos={197,427},size={76,16},disable=1,title="max"
	SetVariable setvar_Async_max_07,userdata(tabnum)=  "4"
	SetVariable setvar_Async_max_07,userdata(tabcontrol)=  "ADC",value= _NUM:0
	CheckBox check_Async_Alarm_07,pos={61,429},size={44,14},disable=1,title="Alarm"
	CheckBox check_Async_Alarm_07,userdata(tabnum)=  "4"
	CheckBox check_Async_Alarm_07,userdata(tabcontrol)=  "ADC",value= 0
	TitleBox Title_TTL_IndexStartEnd,pos={254,53},size={111,13},disable=1,title="\\JCIndexing End Wave"
	TitleBox Title_TTL_IndexStartEnd,userdata(tabnum)=  "3"
	TitleBox Title_TTL_IndexStartEnd,userdata(tabcontrol)=  "ADC",frame=0,fStyle=1
	TitleBox Title_TTL_IndexStartEnd,anchor= LC
	TitleBox Title_TTL_TTLWaveSelect,pos={101,52},size={133,13},disable=1,title="(first) TTL Wave Select"
	TitleBox Title_TTL_TTLWaveSelect,userdata(tabnum)=  "3"
	TitleBox Title_TTL_TTLWaveSelect,userdata(tabcontrol)=  "ADC",frame=0,fStyle=1
	TitleBox Title_TTL_Channel,pos={28,52},size={29,13},disable=1,title="Chan"
	TitleBox Title_TTL_Channel,userdata(tabnum)=  "3",userdata(tabcontrol)=  "ADC"
	TitleBox Title_TTL_Channel,frame=0,fStyle=1
	CheckBox check_DataAcq_Random,pos={38,352},size={58,14},disable=1,title="Random"
	CheckBox check_DataAcq_Random,help={"Randomly selects wave from set selected for DAC channel on each trial. Doesn't repeat waves."}
	CheckBox check_DataAcq_Random,userdata(tabnum)=  "0"
	CheckBox check_DataAcq_Random,userdata(tabcontrol)=  "ADC",value= 0
	TitleBox title_Settings_SetCondition,pos={31,241},size={86,13},title="Set(s) A > Set(s) B"
	TitleBox title_Settings_SetCondition,userdata(tabnum)=  "5"
	TitleBox title_Settings_SetCondition,userdata(tabcontrol)=  "ADC",frame=0
	CheckBox check_Settings_Option_01,pos={122,260},size={131,26},title="Repeat Set(s) B until\rSet(s) A is/are complete"
	CheckBox check_Settings_Option_01,help={"This mode is useful when Set B contains a single wave."}
	CheckBox check_Settings_Option_01,userdata(tabnum)=  "5"
	CheckBox check_Settings_Option_01,userdata(tabcontrol)=  "ADC",value= 0
	CheckBox check_Settings_Option_00,pos={123,210},size={106,26},title="\\Z08Stop Acquisition of\rDA with Set(s) B"
	CheckBox check_Settings_Option_00,help={"Applies to DA channel outputting Set B"}
	CheckBox check_Settings_Option_00,userdata(tabnum)=  "5"
	CheckBox check_Settings_Option_00,userdata(tabcontrol)=  "ADC",fSize=8,value= 0
	CheckBox check_Settings_Option_03,pos={272,203},size={73,14},title="Turn off DA"
	CheckBox check_Settings_Option_03,help={"Applies to DA channel outputting Set B"}
	CheckBox check_Settings_Option_03,userdata(tabnum)=  "5"
	CheckBox check_Settings_Option_03,userdata(tabcontrol)=  "ADC",value= 0
	CheckBox check_Settings_Option_04,pos={272,233},size={108,14},title="Turn off headstage"
	CheckBox check_Settings_Option_04,help={"Turns off AD associated with DA via Channel and Amplifier Assignments"}
	CheckBox check_Settings_Option_04,userdata(tabnum)=  "5"
	CheckBox check_Settings_Option_04,userdata(tabcontrol)=  "ADC",value= 0
	TitleBox title_Settings_SetCondition_00,pos={116,228},size={6,13},title="\\f01/"
	TitleBox title_Settings_SetCondition_00,userdata(tabnum)=  "5"
	TitleBox title_Settings_SetCondition_00,userdata(tabcontrol)=  "ADC",frame=0
	TitleBox title_Settings_SetCondition_01,pos={116,254},size={6,13},title="\\f01\\"
	TitleBox title_Settings_SetCondition_01,userdata(tabnum)=  "5"
	TitleBox title_Settings_SetCondition_01,userdata(tabcontrol)=  "ADC",frame=0
	TitleBox title_Settings_SetCondition_04,pos={264,228},size={6,13},title="\\f01\\"
	TitleBox title_Settings_SetCondition_04,userdata(tabnum)=  "5"
	TitleBox title_Settings_SetCondition_04,userdata(tabcontrol)=  "ADC",frame=0
	TitleBox title_Settings_SetCondition_02,pos={264,207},size={6,13},title="\\f01/"
	TitleBox title_Settings_SetCondition_02,userdata(tabnum)=  "5"
	TitleBox title_Settings_SetCondition_02,userdata(tabcontrol)=  "ADC",frame=0
	TitleBox title_Settings_SetCondition_03,pos={232,217},size={28,13},title="\\f01-------"
	TitleBox title_Settings_SetCondition_03,userdata(tabnum)=  "5"
	TitleBox title_Settings_SetCondition_03,userdata(tabcontrol)=  "ADC",frame=0
	PopupMenu popup_MoreSettings_DeviceType,pos={61,89},size={160,21},bodyWidth=100,disable=3,title="Device type"
	PopupMenu popup_MoreSettings_DeviceType,userdata(tabnum)=  "6"
	PopupMenu popup_MoreSettings_DeviceType,userdata(tabcontrol)=  "ADC"
	PopupMenu popup_MoreSettings_DeviceType,mode=3,popvalue="ITC1600",value= #"\"ITC16;ITC18;ITC1600;ITC00;ITC16USB;ITC18USB;\""
	PopupMenu popup_moreSettings_DeviceNo,pos={88,116},size={133,21},bodyWidth=58,disable=3,title="Device number"
	PopupMenu popup_moreSettings_DeviceNo,userdata(tabnum)=  "6"
	PopupMenu popup_moreSettings_DeviceNo,userdata(tabcontrol)=  "ADC"
	PopupMenu popup_moreSettings_DeviceNo,mode=1,popvalue="0",value= #"\"0;1;2;3;4;5;6;7;8;9;10\""
	SetVariable setvar_DataAcq_StimDelay,pos={40,380},size={175,16},disable=1,title="Stimulus onset delay (ms)"
	SetVariable setvar_DataAcq_StimDelay,userdata(tabnum)=  "0"
	SetVariable setvar_DataAcq_StimDelay,userdata(tabcontrol)=  "ADC",value= _NUM:0
	SetVariable setvar_DataAcq_StimulusTail,pos={223,380},size={175,16},disable=1,title="post stimulus delay (ms)"
	SetVariable setvar_DataAcq_StimulusTail,userdata(tabnum)=  "0"
	SetVariable setvar_DataAcq_StimulusTail,userdata(tabcontrol)=  "ADC"
	SetVariable setvar_DataAcq_StimulusTail,value= _NUM:0
	GroupBox group_WaveBuilder_FolderPath,pos={515,34},size={269,127},title="root:"
	GroupBox group_WaveBuilder_FolderPath,userdata(tabnum)=  "7"
	GroupBox group_WaveBuilder_FolderPath,userdata(tabcontrol)=  "WBP_WaveType"
	GroupBox group_WaveBuilder_FolderPath,userdata(ResizeControlsInfo)= A"!!,If^]6\\,!!#B@J,hq8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	GroupBox group_WaveBuilder_FolderPath,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	GroupBox group_WaveBuilder_FolderPath,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	GroupBox group_SettingsPlus_FolderPath,pos={23,65},size={333,122},disable=1,title="Data folder path = root:ITC1600:Device0:"
	GroupBox group_SettingsPlus_FolderPath,userdata(tabnum)=  "6"
	GroupBox group_SettingsPlus_FolderPath,userdata(tabcontrol)=  "ADC"
	Button button_SettingsPlus_PingDevice,pos={128,142},size={93,28},disable=1,proc=HSU_ButtonProc_Settings_OpenDev,title="Open device"
	Button button_SettingsPlus_PingDevice,help={"Use to determine device number for connected device. Look for device with Ready light ON. Light will remain on for 60 s. Device numbers are determined in hardware and do not change over time. "}
	Button button_SettingsPlus_PingDevice,userdata(tabnum)=  "6"
	Button button_SettingsPlus_PingDevice,userdata(tabcontrol)=  "ADC"
	Button button_SettingsPlus_OpenWB,pos={32,321},size={76,45},title="Open Wave\r Builder"
	Button button_SettingsPlus_OpenWB,userdata(tabnum)=  "5"
	Button button_SettingsPlus_OpenWB,userdata(tabcontrol)=  "ADC"
	Button button_SettingsPlus_OpenDB,pos={134,322},size={76,45},title="Open Data\r Browser"
	Button button_SettingsPlus_OpenDB,userdata(tabnum)=  "5"
	Button button_SettingsPlus_OpenDB,userdata(tabcontrol)=  "ADC"
	Button button_SettingsPlus_LockDevice,pos={233,87},size={85,46},disable=3,proc=HSU_ButtonProc_LockDev,title="Lock device\r selection"
	Button button_SettingsPlus_LockDevice,help={"Device must be locked to acquire data."}
	Button button_SettingsPlus_LockDevice,userdata(tabnum)=  "6"
	Button button_SettingsPlus_LockDevice,userdata(tabcontrol)=  "ADC"
	Button button_SettingsPlus_unLockDevic,pos={233,134},size={85,46},disable=1,proc=HSU_ButtonProc_UnlockDev,title="Unlock device\r selection"
	Button button_SettingsPlus_unLockDevic,userdata(tabnum)=  "6"
	Button button_SettingsPlus_unLockDevic,userdata(tabcontrol)=  "ADC"
	DefineGuide UGV0={FR,-25},UGH0={FB,-27}
	SetWindow kwTopWin,userdata(ResizeControlsInfo)= A"!!*'\"z!!#DYJ,ht.J,fQL!!*'\"zzzzzzzzzzzzzzzzzzz"
	SetWindow kwTopWin,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzzzzzzzzzzzzzzz"
	SetWindow kwTopWin,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzzzzzzzzz!!!"
	Display/W=(491,34,852,438)/FG=(,,UGV0,UGH0)/HOST=# /L=AD0 TestPulseITC[*][2]
	AppendToGraph/L=AD10 TestPulseITC[*][3]
	ModifyGraph lblPosMode=1
	ModifyGraph freePos(AD0)=0
	ModifyGraph freePos(AD10)=0
	ModifyGraph axisEnab(AD0)={0.515,1}
	ModifyGraph axisEnab(AD10)={0.015,0.5}
	Label AD0 "AD0"
	Label AD10 "AD10"
	SetAxis bottom 0,20
	SetWindow kwTopWin,userdata(ResizeControlsInfo)= A"!!,I?!!#=k!!#Bd!!#C5J,fQL!!*'\"zzzzzzzzzzzzzzzzzzz"
	SetWindow kwTopWin,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzzzzzzzzzzzzzzz"
	SetWindow kwTopWin,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzzzzzzzzz!!!"
	RenameWindow #,Oscilloscope
	SetActiveSubwindow ##
EndMacro


//=========================================================================================

//=========================================================================================



Function CheckProc(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	switch( cba.eventCode )
		case 2: // mouse up
			Variable checked = cba.checked
			break
		case -1: // control being killed
			checked=0
			break
	endswitch

	return 0
End




Function SetVarProc(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	string cmd
	variable  minsampint
	getwindow kwTopWin wtitle
	string panelTitle=s_value
	sprintf cmd, " MinSampInt= ITCMinSamplingInterval()"
	execute cmd
	SetVariable SetVar_DownSamp limits={MinSampInt,inf,1}, win=$panelTitle
End




Function CheckProc_UniversalSearchString(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	String SearchString
	getwindow kwTopWin wtitle
	string panelTitle=s_value
	DFREF saveDFR = GetDataFolderDFR()// creates a data folder reference that is later used to access the folder
	
	SetDataFolder root:WaveBuilder:SavedStimulusSets:DA:
	
	controlinfo/w=$panelTitle Search_DA_00
	if(strlen(s_value)==0)
	SearchString="*da*"
	else
	SearchString = s_value
	endif
	
	String DAPopUpMenuName// = "Wave_DA_"
	string IndexEndPopUpMenuName
	String FirstTwoMenuItems = "\"- none -; TestPulse;"
	variable i = 0
	string popupValue=FirstTwoMenuItems+wavelist(searchstring,";","")+"\""
	print popupvalue
	
	do
	DAPopUpMenuName = "Wave_DA_0" + num2str(i)
	PopupMenu $DAPopUpMenuName win=$panelTitle, value=#popupValue, userData(menuExp) = popupValue
	
	IndexEndPopUpMenuName="Popup_DA_IndexEnd_0"+num2str(i)
	PopupMenu $IndexEndPopUpMenuName win=$panelTitle, value=#popupValue
	i+=1
	while(i<8)
	setdatafolder saveDFR
End


Function SetVarProc_TTLSearch(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName

	String TTL_No = ctrlName[11,inf]
	String TTLPopUpMenuName = "Wave_TTL_" + TTL_No
	String TTLIndexEndPopMenuName="Popup_TTL_IndexEnd_" + TTL_No
	String FirstTwoMenuItems = "\"- none -;"
	String SearchString
	String value
	variable i=0
	
	getwindow kwTopWin wtitle
	string panelTitle=s_value
	
	DFREF saveDFR = GetDataFolderDFR()// creates a data folder reference that is later used to access the folder
	SetDataFolder root:WaveBuilder:SavedStimulusSets:TTL:
	
	controlinfo/w=$panelTitle SearchUniversal_TTL_00
	if(v_value==1)
		controlinfo/w=$panelTitle Search_TTL_00
		If(strlen(s_value)==0)
		SearchString= "*TTL*"
		else
		SearchString= s_value
		endif
		
		value=FirstTwoMenuItems+wavelist(SearchString,";","")+"\""
		
		do
		TTLPopUpMenuName = "Wave_TTL_0" + num2str(i)
		popupmenu $TTLPopUpMenuName win=$panelTitle, value=#value, userdata(MenuExp)=Value
		TTLIndexEndPopMenuName = "Popup_TTL_IndexEnd_0" + num2str(i)
		popupmenu $TTLIndexEndPopMenuName win=$panelTitle, value=#value
		i+=1
		while(i<8)
	
	else
		If(strlen(varstr)==0)
		SearchString = "*TTL*"
		value=FirstTwoMenuItems+wavelist(SearchString,";","")+"\""
		TTLPopUpMenuName = "Wave_TTL_0" + num2str(i)
		popupmenu $TTLPopUpMenuName win=$panelTitle, value=#value, userdata(MenuExp)=Value
		TTLIndexEndPopMenuName = "Popup_TTL_IndexEnd_0" + num2str(i)
		popupmenu $TTLIndexEndPopMenuName win=$panelTitle, value=#value
		
		else
		SearchString= varstr
		value=FirstTwoMenuItems+wavelist(SearchString,";","")+"\""
		TTLPopUpMenuName = "Wave_TTL_0" + num2str(i)
		popupmenu $TTLPopUpMenuName win=$panelTitle, value=#value, userdata(MenuExp)=Value
		TTLIndexEndPopMenuName = "Popup_TTL_IndexEnd_0" + num2str(i)
		popupmenu $TTLIndexEndPopMenuName win=$panelTitle, value=#value
		endif
	endif
	
	setdatafolder saveDFR
End


Function CheckProc_UniversalSearchTTL(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	String SearchString
	
	getwindow kwTopWin wtitle
	string panelTitle=s_value
	
	DFREF saveDFR = GetDataFolderDFR()// creates a data folder reference that is later used to access the folder
	SetDataFolder root:WaveBuilder:SavedStimulusSets:TTL:
	
	controlinfo/w=$panelTitle Search_TTL_00
	if(strlen(s_value)==0)
		SearchString="*TTL*"
	else
		SearchString = s_value
	endif
	
	String TTLPopUpMenuName// = "Wave_DA_"
	String IndexEndPopUpMenuName
	String FirstTwoMenuItems = "\"- none -;"
	variable i = 0
	
	string popupValue=FirstTwoMenuItems+wavelist(searchstring,";","")+"\""
	do
		TTLPopUpMenuName = "Wave_TTL_0" + num2str(i)
		popupmenu $TTLPopUpMenuName win=$panelTitle, value=#popupValue
		IndexEndPopUpMenuName = "Popup_TTL_IndexEnd_0" + num2str(i)
		popupmenu $IndexEndPopUpMenuName win=$panelTitle, value=#popupValue
		i+=1
	while(i<8)

	setdatafolder saveDFR
End


Function TabTJHook1(tca)//This is a function that gets run by ACLight's tab control function every time a tab is selected
	STRUCT WMTabControlAction &tca
	variable tabnum , i = 0, MinSampInt
	SVAR ITCPanelTitleList
	string panelTitle
	tabnum=tca.tab
	if(tabnum==0)
	do
	panelTitle = stringfromlist(i, ITCPanelTitleList,";")
	MinSampInt = ITCMinSamplingInterval(PanelTitle)
	ValDisplay ValDisp_DataAcq_SamplingInt win = $PanelTitle, value=_NUM:MinSampInt
	controlUpdate/w=$PanelTitle ValDisp_DataAcq_SamplingInt
	i+=1
	while(i<itemsinlist(ITCPanelTitleList,";"))
	endif
	
//	if(tabnum==1)// this does not work because hook function runs prior to adams tab functions (i assume)
//	controlinfo/w=datapro_itc1600 Check_DataAcq_Indexing
//		if(v_value==0)
//		TitleBox Title_DAC_IndexStartEnd disable=1, win=datapro_itc1600
//		ChangePopUpState("Popup_DA_IndexEnd_0",1)
//		endif
//	endif
return 0
End

Function SetVarProc_DASearch(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName

	String DA_No = ctrlName[10,inf]
	String DAPopUpMenuName = "Wave_DA_" + DA_No
	String IndexEndPopUpMenuName="Popup_DA_IndexEnd_"+ DA_No
	String FirstTwoMenuItems = "\"- none -; TestPulse;"
	String SearchString
	string popupValue
	variable i=0
	
	getwindow kwTopWin wtitle
	string panelTitle=s_value
	
	DFREF saveDFR = GetDataFolderDFR()
	setdatafolder root:waveBuilder:savedStimulusSets:DA
	controlinfo/w=$panelTitle SearchUniversal_DA_00	
	
	
	if(v_value==1)
		controlinfo/w=$panelTitle Search_DA_00
		If(strlen(s_value)==0)
			SearchString= "*DAC*"
		else
			SearchString=s_value
		endif
		
		do
			DAPopUpMenuName = "Wave_DA_0" + num2str(i)
			popupValue=FirstTwoMenuItems+wavelist(searchstring,";","")+"\""
			popupmenu $DAPopUpMenuName win=$panelTitle, value=#popupValue, userdata(MenuExp)=popupValue
			IndexEndPopUpMenuName="Popup_DA_IndexEnd_0"+num2str(i)
			popupmenu $IndexEndPopUpMenuName win=$panelTitle, value=#popupValue
			i+=1
		while(i<8)
	
	else
		If(strlen(varstr)==0)
			SearchString= "*DAC*"
			DAPopUpMenuName = "Wave_DA_0" + num2str(i)
			popupValue=FirstTwoMenuItems+wavelist(searchstring,";","")+"\""
			popupmenu $DAPopUpMenuName win=$panelTitle, value=#popupValue, userdata(MenuExp)=popupValue
			IndexEndPopUpMenuName="Popup_DA_IndexEnd_0"+num2str(i)
			popupmenu $IndexEndPopUpMenuName win=$panelTitle, value=#popupValue
		else
			DAPopUpMenuName = "Wave_DA_0" + num2str(i)
			popupValue=FirstTwoMenuItems+wavelist(varstr,";","")+"\""
			popupmenu $DAPopUpMenuName win=$panelTitle, value=#popupValue, userdata(MenuExp)=popupValue
			IndexEndPopUpMenuName="Popup_DA_IndexEnd_0"+num2str(i)
			popupmenu $IndexEndPopUpMenuName win=$panelTitle, value=#popupValue
		endif
	endif
	setdatafolder saveDFR
End

Function DAorTTLCheckProc(ctrlName,checked) : CheckBoxControl//This procedure checks to see that a DAC or TTL wave is selected before turning on the corresponding channel
	String ctrlName
	Variable checked
	String DACWave = ctrlName
	DACwave[0,4] = "wave"

	getwindow kwTopWin wtitle
	string panelTitle=s_value
	
	controlinfo/w=$panelTitle $DACWave
	if(stringmatch(s_value,"- none -")==1)
	checkbox $ctrlName win=$panelTitle, value=0
	print "Select " + DACwave[5,7] + " Wave"
	endif

	variable MinSampInt = ITCMinSamplingInterval(PanelTitle)
	ValDisplay ValDisp_DataAcq_SamplingInt win = $PanelTitle, value=_NUM:MinSampInt
End

Function ButtonProc_AcquireData(ctrlName) : ButtonControl
	String ctrlName
	
	getwindow kwTopWin wtitle
	string panelTitle = s_value
	print panelTitle
	AbortOnValue HSU_DeviceLockCheck(panelTitle),1
	
	string WavePath = HSU_DataFullFolderPathString(PanelTitle)
	wave ITCDataWave = $WavePath + ":ITCDataWave"

	
	controlinfo/w=$panelTitle popup_MoreSettings_DeviceType
	variable DeviceType=v_value-1
	controlinfo/w=$panelTitle popup_moreSettings_DeviceNo
	variable DeviceNum=v_value-1
	
		//History management
		controlinfo check_Settings_Overwrite
		if(v_value==1)//if overwrite old waves is checked in datapro panel, the following code will delete the old waves and generate a new settings history wave 
			
			if(IsLastSweepGreaterThanNextSweep(panelTitle)==1)//Checks for manual roll back of Next Sweep
				controlinfo SetVar_Sweep
				variable NextSweep=v_value
				DeleteSettingsHistoryWaves(NextSweep, panelTitle)
				DeleteDataWaves(NextSweep)
				MakeSettingsHistoryWave(panelTitle)// generates new settings history wave
			endif
		
		endif
		
		//Data collection
		//Function that assess how many 1d waves in set??
		//Function that passes column to configdataForITCfunction?
		//If a set with multiple 1d waves is chosen, repeated aquisition should be activated automatically. globals should be used to keep track of columns
		//
		ConfigureDataForITC(PanelTitle)
		ITCOscilloscope(ITCDataWave, panelTitle)
		ControlInfo/w=$panelTitle Check_Settings_BackgrndDataAcq
		If(v_value==0)
		ITCDataAcq(DeviceType,DeviceNum, panelTitle)
			controlinfo/w=$panelTitle Check_DataAcq1_RepeatAcq
			if(v_value==1)//repeated aquisition is selected
				RepeatedAcquisition(PanelTitle)
			endif
		else
		ITCBkrdAcq(DeviceType,DeviceNum, panelTitle)
		endif	
End

Function CheckProc_1(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	getwindow kwTopWin wtitle
	string panelTitle=s_value

	If(Checked==1)
	Button DataAcquireButton fColor=(52224,0,0), win=$panelTitle
	string ButtonText = "\\Z14\\f01Acquire Data\r * DATA WILL NOT BE SAVED *"
	ButtonText+= "\r\\Z08\\f00 (autosave state is in settings tab)"
	Button DataAcquireButton title=ButtonText
	else
	Button DataAcquireButton fColor=(0,0,0), win=$panelTitle
	Button DataAcquireButton title="\\Z14\\f01Acquire\rData"
	endif
End



Function CheckProc_Indexing(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
//controlinfo ADC
//if(v_value==1)
//if(checked==0)
//TitleBox Title_DAC_IndexStartEnd disable=0, win=datapro_itc1600
//ChangePopUpState("Popup_DA_IndexEnd_0",0)
//else
//TitleBox Title_DAC_IndexStartEnd disable=1, win=datapro_itc1600
//ChangePopUpState("Popup_DA_IndexEnd_0",1)
//
//endif
//endif


End

Function ChangePopUpState(BaseName, state, panelTitle)
string BaseName, panelTitle// Popup_DA_IndexEnd_0
variable state
variable i=0
string CompleteName


do
CompleteName=Basename+num2str(i)

PopupMenu $CompleteName disable=state, win=$panelTitle
i+=1
while(i<8)

End




Function SmoothResizePanel(RightShift, panelTitle)
variable RightShift
string panelTitle
variable i
getwindow $panelTitle wsize

do
if(rightshift>=0)
movewindow/w=$panelTitle v_left, v_top, v_right+i, v_bottom
else
movewindow/w=$panelTitle v_left, v_top, v_right-i, v_bottom
endif

i+=4
while(i<(abs(rightshift)))

End


Function CheckProc_2(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	
	getwindow kwTopWin wtitle
	string panelTitle=s_value
	
	if(checked==1)
	smoothresizepanel(340, panelTitle)
	else
	smoothresizepanel(-340, panelTitle)
	endif
End


Function TurnOffAllTTLs(panelTitle)
	string panelTitle
	variable i, NoOfTTLs
	string TTLCheckBoxName
	
	NoOfTTLs=TotNoOfControlType("check", "TTL", panelTitle)
	
	for(i=0;i<NoOfTTLs;i+=1)
		TTLCheckBoxName="Check_TTL_0"+num2str(i)
		CheckBox $TTLCheckBoxName win=$panelTitle, value=0
	endfor
End

Function StoreTTLState(panelTitle)
string panelTitle
string/g StoredTTLState = ControlStatusListString("TTL", "Check", panelTitle)
End

Function RestoreTTLState(panelTitle)
string panelTitle
SVAR StoredTTLState
variable i, NoOfTTLs, CheckBoxState
string TTLCheckBoxName
	
	NoOfTTLs=TotNoOfControlType("check", "TTL", panelTitle)
	
	for(i=0;i<NoOfTTLs;i+=1)
		TTLCheckBoxName="Check_TTL_0"+num2str(i)
		CheckBoxState=str2num(stringfromlist(i,StoredTTLState,";"))
		CheckBox $TTLCheckBoxName win=$panelTitle, value=CheckBoxState
	endfor

killstrings StoredTTLState
End

Function ButtonProc_2(ctrlName) : ButtonControl
	String ctrlName
	getwindow kwTopWin wtitle
	string panelTitle=s_value
	
	TurnOffAllTTLs(panelTitle)
End


Function TurnOffAllDACs(panelTitle)
	string panelTitle
	variable i, NoOfDACs
	string DACCheckBoxName
	
	NoOfDACs=TotNoOfControlType("check", "DA", panelTitle)
	
	for(i=0;i<NoOfDACs;i+=1)
		DACCheckBoxName="Check_DA_0"+num2str(i)
		CheckBox $DACCheckBoxName win=$panelTitle, value=0
	endfor
End

Function ButtonProc_3(ctrlName) : ButtonControl
	String ctrlName
	
	getwindow kwTopWin wtitle
	string panelTitle=s_value
	TurnOffAllDACs(panelTitle)
End

Function TurnOffAllADCs(panelTitle)
	string panelTitle
	variable i, NoOfADCs
	string ADCCheckBoxName
	
	NoOfADCs=TotNoOfControlType("check", "AD", panelTitle)
	
	for(i=0;i<NoOfADCs;i+=1)
		if(i<10)
		ADCCheckBoxName="Check_AD_0"+num2str(i)
		CheckBox $ADCCheckBoxName win=$panelTitle, value=0
		else
		ADCCheckBoxName="Check_AD_"+num2str(i)
		CheckBox $ADCCheckBoxName win=$panelTitle, value=0
		endif
	endfor
End

Function ButtonProc_4(ctrlName) : ButtonControl
	String ctrlName
	
	getwindow kwTopWin wtitle
	string panelTitle=s_value
	TurnOffAllADCs(panelTitle)
End

Function TurnOffAllHeadstages(panelTitle)
	string panelTitle
//Check_DataAcq_Cell0
	variable i, NoOfHeadstages
	string DACCheckBoxName
	
	NoOfHeadstages=TotNoOfControlType("check", "DataAcq", panelTitle)
	
	for(i=0;i<NoOfHeadstages;i+=1)
		DACCheckBoxName="Check_DataAcq_0"+num2str(i)
		CheckBox $DACCheckBoxName win=$panelTitle, value=0
	endfor






End

Function ButtonProc_5(ctrlName) : ButtonControl
	String ctrlName
	
	getwindow kwTopWin wtitle
	string panelTitle=s_value
	TurnOffAllHeadstages(panelTitle)
	TurnOffAllDACs(panelTitle)
	TurnOffAllADCs(panelTitle)
	TurnOffAllTTLs(panelTitle)
End

Function ITCP_PopMenuCheckProc_DAC(ctrlName,popNum,popStr) : PopupMenuControl//Procedure for DA popupmenu's that show DA waveslist from wavebuilder
	String ctrlName
	Variable popNum
	String popStr
	string CheckBoxName=ctrlName
	string ListOfWavesInFolder
	string folderPath
	string folder
	
	getwindow kwTopWin wtitle
	string panelTitle=s_value
	
	if(stringmatch(ctrlName,"*indexEnd*")!=1)//makes sure it is the index start wave
		if(popnum==1)//if the user selects "none" the channel is automatically turned off
		CheckBoxName[0,3]="check"
		Checkbox $Checkboxname win=$panelTitle, value=0
		endif
	endif
	
	if(popnum==2)
		popupmenu $ctrlname win=$panelTitle, mode = 3// prevents the user from selecting the testpulse
	endif

	if(stringmatch(ctrlName,"*DA*")==1)// determines wether to a DA or TTL popup menu needs to be populated
		FolderPath= "root:waveBuilder:savedStimulusSets:DA"
		folder="*DA*"
	else
		FolderPath= "root:waveBuilder:savedStimulusSets:TTL"
		folder="*TTL*"
	endif
	
	setdatafolder FolderPath// sets the wavelist for the DA popup menu to show all waves in DAC folder
	ListOfWavesInFolder="\"- none -;TestPulse;\"" +"+"+"\""+ Wavelist(Folder,";","")+"\""
//	print ListOfWavesInFolder
	PopupMenu  $ctrlName win=$panelTitle, value=#ListOfWavesInFolder, userdata(MenExp)=ListOfWavesInFolder
	setdatafolder root:
	
End

Function SetVarProc_NextSweep(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	getwindow kwTopWin wtitle
	string PanelTitle=s_value
	string WavePath=HSU_DataFullFolderPathString(PanelTitle)
	DFREF saveDFR = GetDataFolderDFR()
	setDataFolder $WavePath+":data"
	string ListOfDataWaves=wavelist("Sweep_*",";","MINCOLS:2")
	setDataFolder saveDFR
	SetVariable SetVar_Sweep win=$panelTitle, limits={0,itemsinlist(ListOfDataWaves),1}
	
End

Function/t ITCP_PopupMenuWaveNameList(DAorTTL,StartOrEnd,panelTitle)// returns the names of the items in the popmenu controls in a list
	string DAorTTL, panelTitle
	variable StartOrEnd// 0 or 1, determines whether the start or end index popupmenu is updated
	string ListOfSelectedWaveNames=""
	string popupMenuName
	variable noOfPopups = TotNoOfControlType("Wave",DAorTTL, panelTitle)
	variable i
	delayupdate
	do
		switch(StartOrEnd)
			case 0:
			popupMenuName = "Wave_"+DAorTTL+"_0"+ num2str(i)
			break
			case 1:
			popupMenuName = "Popup_"+DAorTTL+"_IndexEnd_0"+num2str(i)
			break
		endswitch
		controlInfo/w=$panelTitle $popupMenuName
		ListOfSelectedWaveNames+=s_value + ";"
		i+=1
	while(i<noOfPopups)
	
	return ListOfSelectedWaveNames
End

Function ITCP_RestorePopupMenuSelection(ListOfSelections, DAorTTL, StartOrEnd, panelTitle)
	string ListOfSelections, DAorTTL, panelTitle
	variable StartOrEnd
	string popupMenuName
	string CheckBoxName
	variable noOfPopups = TotNoOfControlType("Wave",DAorTTL, panelTitle)
	variable i
	delayupdate
		do
			switch(StartOrEnd)
				case 0:
				popupMenuName = "Wave_"+DAorTTL+"_0"+ num2str(i)
				break
				case 1:
				popupMenuName = "Popup_"+DAorTTL+"_IndexEnd_0"+num2str(i)
				break
				endswitch
			controlinfo/w=$panelTitle $popupMenuName
			if(cmpstr(s_value, stringfromlist(i, ListOfSelections,";"))==1 || cmpstr(s_value,"")==0)
				PopupMenu  $popupMenuName win=$panelTitle, mode=v_value-1
				controlinfo/w=$panelTitle $popupMenuName
				if(cmpstr(s_value,"testpulse")==0)
				PopupMenu  $popupMenuName win=$panelTitle, mode=1
				CheckBoxName="Check_"+DAorTTL+"_0" + num2str(i)
				CheckBox Check_DA_00 win=$panelTitle, value=0
				endif
			endif
			i+=1
		while(i<noOfPopups)
		doupdate /W = $panelTitle
End

Function UpdateITCMinSampIntDisplay()
	getwindow kwTopWin wtitle
	string panelTitle=s_value
	variable MinSampInt = ITCMinSamplingInterval(PanelTitle)
	ValDisplay ValDisp_DataAcq_SamplingInt win = $PanelTitle, value=_NUM:MinSampInt
End

Function CheckProc_DataAcq_UpdateSampInt(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	UpdateITCMinSampIntDisplay()
End
