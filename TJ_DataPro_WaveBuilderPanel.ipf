#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#include <Resize Controls>
#include <FilterDialog> menus=0

Window wavebuilder() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(394,202,1372,667)
	SetDrawLayer UserBack
	SetVariable SetVar_WaveBuilder_NoOfSegments,pos={142,35},size={150,16},proc=WBP_SetVarProc_1,title="Total Epochs"
	SetVariable SetVar_WaveBuilder_NoOfSegments,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_NoOfSegments,userdata(ResizeControlsInfo)= A"!!,Fs!!#=o!!#A%!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_NoOfSegments,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_NoOfSegments,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_NoOfSegments,limits={1,101,1},value= _NUM:3
	SetVariable SetVar_WaveBuilder_P0,pos={311,34},size={150,16},proc=WBP_SetVarProc_2,title="Duration"
	SetVariable SetVar_WaveBuilder_P0,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P0,userdata(ResizeControlsInfo)= A"!!,HVJ,hnA!!#A%!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P0,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P0,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P0,limits={0,inf,1},value= _NUM:100
	SetVariable SetVar_WaveBuilder_P1,pos={466,34},size={150,16},proc=WBP_SetVarProc_2,title="Delta"
	SetVariable SetVar_WaveBuilder_P1,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P1,userdata(ResizeControlsInfo)= A"!!,IO!!#=k!!#A%!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P1,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P1,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P1,value= _NUM:0
	SetVariable SetVar_WaveBuilder_StepCount,pos={142,58},size={150,16},proc=SetVarProc_4,title="Total Steps"
	SetVariable SetVar_WaveBuilder_StepCount,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_StepCount,userdata(ResizeControlsInfo)= A"!!,Fs!!#?!!!#A%!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_StepCount,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_StepCount,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_StepCount,limits={1,99,1},value= _NUM:2
	SetVariable setvar_WaveBuilder_P10,pos={692,34},size={100,16},disable=1,proc=WBP_SetVarProc_2,title="Tau Rise"
	SetVariable setvar_WaveBuilder_P10,userdata(tabnum)=  "6"
	SetVariable setvar_WaveBuilder_P10,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable setvar_WaveBuilder_P10,userdata(ResizeControlsInfo)= A"!!,J>!!#=k!!#@,!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_WaveBuilder_P10,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_WaveBuilder_P10,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_WaveBuilder_P10,value= _NUM:0
	SetVariable setvar_WaveBuilder_P12,pos={692,56},size={100,16},disable=1,proc=WBP_SetVarProc_2,title="Tau Decay 1"
	SetVariable setvar_WaveBuilder_P12,userdata(tabnum)=  "6"
	SetVariable setvar_WaveBuilder_P12,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable setvar_WaveBuilder_P12,userdata(ResizeControlsInfo)= A"!!,J>!!#>n!!#@,!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_WaveBuilder_P12,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_WaveBuilder_P12,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_WaveBuilder_P12,value= _NUM:0
	SetVariable setvar_WaveBuilder_P14,pos={692,80},size={100,16},disable=1,proc=WBP_SetVarProc_2,title="Tau Decay 2"
	SetVariable setvar_WaveBuilder_P14,userdata(tabnum)=  "6"
	SetVariable setvar_WaveBuilder_P14,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable setvar_WaveBuilder_P14,userdata(ResizeControlsInfo)= A"!!,J>!!#?Y!!#@,!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_WaveBuilder_P14,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_WaveBuilder_P14,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_WaveBuilder_P14,value= _NUM:0
	SetVariable setvar_WaveBuilder_P16,pos={692,103},size={100,16},disable=1,proc=WBP_SetVarProc_2,title="Tau 2 weight"
	SetVariable setvar_WaveBuilder_P16,userdata(tabnum)=  "6"
	SetVariable setvar_WaveBuilder_P16,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable setvar_WaveBuilder_P16,userdata(ResizeControlsInfo)= A"!!,J>!!#@2!!#@,!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_WaveBuilder_P16,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_WaveBuilder_P16,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_WaveBuilder_P16,limits={0,1,0.1},value= _NUM:50
	SetVariable SetVar_WaveBuilder_P2,pos={311,57},size={150,16},proc=WBP_SetVarProc_2,title="Amplitude"
	SetVariable SetVar_WaveBuilder_P2,help={"For G-Noise wave, amplitude = Standard deviation"}
	SetVariable SetVar_WaveBuilder_P2,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P2,userdata(ResizeControlsInfo)= A"!!,HVJ,hoH!!#A%!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P2,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P2,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P2,value= _NUM:5
	SetVariable SetVar_WaveBuilder_P3,pos={466,57},size={150,16},proc=WBP_SetVarProc_2,title="Delta"
	SetVariable SetVar_WaveBuilder_P3,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P3,userdata(ResizeControlsInfo)= A"!!,IO!!#>r!!#A%!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P3,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P3,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P3,value= _NUM:5
	SetVariable setvar_WaveBuilder_SetNumber,pos={9,78},size={120,16},proc=SetVarProc_3,title="Set Number"
	SetVariable setvar_WaveBuilder_SetNumber,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable setvar_WaveBuilder_SetNumber,userdata(ResizeControlsInfo)= A"!!,@s!!#?U!!#@T!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_WaveBuilder_SetNumber,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_WaveBuilder_SetNumber,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_WaveBuilder_SetNumber,value= _NUM:1
	SetVariable SetVar_WaveBuilder_P4,pos={311,81},size={150,16},disable=1,proc=WBP_SetVarProc_2,title="Offset"
	SetVariable SetVar_WaveBuilder_P4,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P4,userdata(ResizeControlsInfo)= A"!!,HVJ,hp1!!#A%!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P4,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P4,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P4,userdata(tabnum)=  "1",value= _NUM:0
	SetVariable SetVar_WaveBuilder_P6,pos={311,105},size={150,16},disable=1,proc=WBP_SetVarProc_2,title="Frequency"
	SetVariable SetVar_WaveBuilder_P6,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P6,userdata(ResizeControlsInfo)= A"!!,HVJ,hpa!!#A%!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P6,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P6,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P6,userdata(tabnum)=  "3",value= _NUM:0
	TabControl WBP_WaveType,pos={303,3},size={600,20},proc=ACL_DisplayTab
	TabControl WBP_WaveType,userdata(tabcontrol)=  "WBP_WaveType"
	TabControl WBP_WaveType,userdata(currenttab)=  "0"
	TabControl WBP_WaveType,userdata(initialhook)=  "TabTJHook"
	TabControl WBP_WaveType,userdata(ResizeControlsInfo)= A"!!,HRJ,hi\"!!#D&!!#<Xz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TabControl WBP_WaveType,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	TabControl WBP_WaveType,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	TabControl WBP_WaveType,tabLabel(0)="Square pulse",tabLabel(1)="Ramp"
	TabControl WBP_WaveType,tabLabel(2)="G-Noise",tabLabel(3)="Sin"
	TabControl WBP_WaveType,tabLabel(4)="Saw tooth",tabLabel(5)="Square pulse train"
	TabControl WBP_WaveType,tabLabel(6)="PSC",tabLabel(7)="Load custom wave"
	TabControl WBP_WaveType,value= 0
	SetVariable setvar_WaveBuilder_SegmentEdit,pos={167,82},size={125,16},proc=WBP_SetVarProc,title="Epoch to edit"
	SetVariable setvar_WaveBuilder_SegmentEdit,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable setvar_WaveBuilder_SegmentEdit,userdata(ResizeControlsInfo)= A"!!,G7!!#?]!!#@^!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_WaveBuilder_SegmentEdit,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_WaveBuilder_SegmentEdit,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_WaveBuilder_SegmentEdit,limits={0,2,1},value= _NUM:1
	SetVariable SetVar_WaveBuilder_P5,pos={466,81},size={150,16},disable=1,proc=WBP_SetVarProc_2,title="Delta"
	SetVariable SetVar_WaveBuilder_P5,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P5,userdata(ResizeControlsInfo)= A"!!,IO!!#?[!!#A%!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P5,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P5,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P5,userdata(tabnum)=  "1",value= _NUM:0
	SetVariable SetVar_WaveBuilder_P7,pos={466,105},size={150,16},disable=1,proc=WBP_SetVarProc_2,title="Delta"
	SetVariable SetVar_WaveBuilder_P7,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P7,userdata(ResizeControlsInfo)= A"!!,IO!!#@6!!#A%!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P7,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P7,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P7,userdata(tabnum)=  "3",value= _NUM:0
	SetVariable SetVar_WaveBuilder_P8,pos={311,129},size={150,16},disable=1,proc=WBP_SetVarProc_2,title="Pulse Duration"
	SetVariable SetVar_WaveBuilder_P8,userdata(tabnum)=  "5"
	SetVariable SetVar_WaveBuilder_P8,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P8,userdata(ResizeControlsInfo)= A"!!,HVJ,hq;!!#A%!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P8,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P8,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P8,value= _NUM:0
	SetVariable SetVar_WaveBuilder_P9,pos={466,129},size={150,16},disable=1,proc=WBP_SetVarProc_2,title="Delta"
	SetVariable SetVar_WaveBuilder_P9,userdata(tabnum)=  "5"
	SetVariable SetVar_WaveBuilder_P9,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P9,userdata(ResizeControlsInfo)= A"!!,IO!!#@e!!#A%!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P9,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P9,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P9,value= _NUM:0
	SetVariable setvar_WaveBuilder_baseName,pos={9,100},size={119,16},proc=SetVarProc_3,title="Base Name"
	SetVariable setvar_WaveBuilder_baseName,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable setvar_WaveBuilder_baseName,userdata(ResizeControlsInfo)= A"!!,@s!!#@,!!#@R!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_WaveBuilder_baseName,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_WaveBuilder_baseName,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_WaveBuilder_baseName,fSize=8,value= _STR:"ladida"
	PopupMenu popup_WaveBuilder_SetList,pos={63,433},size={150,21},bodyWidth=150
	PopupMenu popup_WaveBuilder_SetList,userdata(tabcontrol)=  "WBP_WaveType"
	PopupMenu popup_WaveBuilder_SetList,userdata(ResizeControlsInfo)= A"!!,E6!!#C=J,hqP!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu popup_WaveBuilder_SetList,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#?(FEDG<zzzzzzzzzzz"
	PopupMenu popup_WaveBuilder_SetList,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	PopupMenu popup_WaveBuilder_SetList,mode=1,popvalue="- none -",value= #"DeleteListPopUp()"
	Button button_WaveBuilder_KillSet,pos={219,431},size={148,23},proc=ButtonProc,title="Delete Set"
	Button button_WaveBuilder_KillSet,help={"If set isn't removed from list after deleting, a wave from the set must be in use, kill the appropriate graph or table and retry."}
	Button button_WaveBuilder_KillSet,userdata(tabcontrol)=  "WBP_WaveType"
	Button button_WaveBuilder_KillSet,userdata(ResizeControlsInfo)= A"!!,Gk!!#C<J,hqN!!#<pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_WaveBuilder_KillSet,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#?(FEDG<zzzzzzzzzzz"
	Button button_WaveBuilder_KillSet,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	CheckBox check_WaveBuilder_exp,pos={623,32},size={49,20},proc=WBP_CheckProc,title="Delta\\S2"
	CheckBox check_WaveBuilder_exp,userdata(tabcontrol)=  "WBP_WaveType"
	CheckBox check_WaveBuilder_exp,userdata(ResizeControlsInfo)= A"!!,J,^]6\\$!!#>R!!#<Xz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_WaveBuilder_exp,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_WaveBuilder_exp,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_WaveBuilder_exp,value= 0
	Button button_WaveBuilder_setaxisA,pos={806,437},size={75,20},proc=ButtonProc_1,title="Autoscale"
	Button button_WaveBuilder_setaxisA,userdata(tabcontrol)=  "WBP_WaveType"
	Button button_WaveBuilder_setaxisA,userdata(ResizeControlsInfo)= A"!!,JZJ,hsjJ,hp%!!#<Xz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_WaveBuilder_setaxisA,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#?(FEDG<zzzzzzzzzzz"
	Button button_WaveBuilder_setaxisA,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	PopupMenu popup_WaveBuilder_OutputType,pos={7,4},size={124,21},bodyWidth=65,proc=WBP_PopMenuProc,title="Wave Type"
	PopupMenu popup_WaveBuilder_OutputType,help={"TTL selection results in automatic changes to the set being created in the Wave Builder that cannot be recovered. "}
	PopupMenu popup_WaveBuilder_OutputType,userdata(ResizeControlsInfo)= A"!!,@C!!#97!!#@\\!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu popup_WaveBuilder_OutputType,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu popup_WaveBuilder_OutputType,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu popup_WaveBuilder_OutputType,mode=1,popvalue="DAC",value= #"\"DAC;TTL\""
	Button button_WaveBuilder_SaveSet,pos={7,29},size={123,45},proc=ButtonProc_2,title="Save Set"
	Button button_WaveBuilder_SaveSet,help={"Saving a set is not required to use the set"}
	Button button_WaveBuilder_SaveSet,userdata(ResizeControlsInfo)= A"!!,@C!!#=K!!#@Z!!#>Bz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_WaveBuilder_SaveSet,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button button_WaveBuilder_SaveSet,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_FD00,pos={311,105},size={150,16},disable=1,proc=WBP_SetVarProc_5,title="Frequency"
	SetVariable SetVar_WaveBuilder_FD00,userdata(tabnum)=  "4"
	SetVariable SetVar_WaveBuilder_FD00,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_FD00,userdata(ResizeControlsInfo)= A"!!,HVJ,hpa!!#A%!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_FD00,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_FD00,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_FD00,value= _NUM:100
	SetVariable SetVar_WaveBuilder_DD00,pos={466,105},size={150,16},disable=1,proc=WBP_SetVarProc_6,title="Delta"
	SetVariable SetVar_WaveBuilder_DD00,userdata(tabnum)=  "4"
	SetVariable SetVar_WaveBuilder_DD00,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_DD00,userdata(ResizeControlsInfo)= A"!!,IO!!#@6!!#A%!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_DD00,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_DD00,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_DD00,value= _NUM:50
	SetVariable SetVar_WaveBuilder_FD01,pos={311,105},size={150,16},disable=1,proc=WBP_SetVarProc_5,title="Frequency"
	SetVariable SetVar_WaveBuilder_FD01,userdata(tabnum)=  "5"
	SetVariable SetVar_WaveBuilder_FD01,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_FD01,userdata(ResizeControlsInfo)= A"!!,HVJ,hpa!!#A%!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_FD01,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_FD01,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_FD01,value= _NUM:100
	SetVariable SetVar_WaveBuilder_DD01,pos={466,105},size={150,16},disable=1,proc=WBP_SetVarProc_6,title="Delta"
	SetVariable SetVar_WaveBuilder_DD01,userdata(tabnum)=  "5"
	SetVariable SetVar_WaveBuilder_DD01,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_DD01,userdata(ResizeControlsInfo)= A"!!,IO!!#@6!!#A%!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_DD01,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_DD01,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_DD01,value= _NUM:100
	SetVariable SetVar_WaveBuilder_OD00,pos={311,81},size={150,16},disable=1,proc=WBP_SetVarProc_7,title="Offset"
	SetVariable SetVar_WaveBuilder_OD00,userdata(tabnum)=  "2"
	SetVariable SetVar_WaveBuilder_OD00,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_OD00,userdata(ResizeControlsInfo)= A"!!,HVJ,hp1!!#A%!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_OD00,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_OD00,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_OD00,value= _NUM:0
	SetVariable SetVar_WaveBuilder_DD02,pos={466,81},size={150,16},disable=1,proc=WBP_SetVarProc_8,title="Delta"
	SetVariable SetVar_WaveBuilder_DD02,userdata(tabnum)=  "2"
	SetVariable SetVar_WaveBuilder_DD02,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_DD02,userdata(ResizeControlsInfo)= A"!!,IO!!#?[!!#A%!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_DD02,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_DD02,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_DD02,value= _NUM:0
	SetVariable SetVar_WaveBuilder_DD03,pos={466,81},size={150,16},disable=1,proc=WBP_SetVarProc_8,title="Delta"
	SetVariable SetVar_WaveBuilder_DD03,userdata(tabnum)=  "3"
	SetVariable SetVar_WaveBuilder_DD03,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_DD03,userdata(ResizeControlsInfo)= A"!!,IO!!#?[!!#A%!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_DD03,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_DD03,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_DD03,value= _NUM:0
	SetVariable SetVar_WaveBuilder_OD01,pos={311,81},size={150,16},disable=1,proc=WBP_SetVarProc_7,title="Offset"
	SetVariable SetVar_WaveBuilder_OD01,userdata(tabnum)=  "3"
	SetVariable SetVar_WaveBuilder_OD01,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_OD01,userdata(ResizeControlsInfo)= A"!!,HVJ,hp1!!#A%!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_OD01,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_OD01,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_OD01,value= _NUM:0
	SetVariable SetVar_WaveBuilder_DD04,pos={466,81},size={150,16},disable=1,proc=WBP_SetVarProc_8,title="Delta"
	SetVariable SetVar_WaveBuilder_DD04,userdata(tabnum)=  "4"
	SetVariable SetVar_WaveBuilder_DD04,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_DD04,userdata(ResizeControlsInfo)= A"!!,IO!!#?[!!#A%!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_DD04,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_DD04,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_DD04,value= _NUM:0
	SetVariable SetVar_WaveBuilder_OD02,pos={311,81},size={150,16},disable=1,proc=WBP_SetVarProc_7,title="Offset"
	SetVariable SetVar_WaveBuilder_OD02,userdata(tabnum)=  "4"
	SetVariable SetVar_WaveBuilder_OD02,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_OD02,userdata(ResizeControlsInfo)= A"!!,HVJ,hp1!!#A%!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_OD02,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_OD02,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_OD02,value= _NUM:0
	SetVariable SetVar_WaveBuilder_DD05,pos={466,82},size={150,16},disable=1,proc=WBP_SetVarProc_8,title="Delta"
	SetVariable SetVar_WaveBuilder_DD05,userdata(tabnum)=  "5"
	SetVariable SetVar_WaveBuilder_DD05,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_DD05,userdata(ResizeControlsInfo)= A"!!,IO!!#?]!!#A%!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_DD05,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_DD05,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_DD05,value= _NUM:0
	SetVariable SetVar_WaveBuilder_OD03,pos={311,81},size={150,16},disable=1,proc=WBP_SetVarProc_7,title="Offset"
	SetVariable SetVar_WaveBuilder_OD03,userdata(tabnum)=  "5"
	SetVariable SetVar_WaveBuilder_OD03,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_OD03,userdata(ResizeControlsInfo)= A"!!,HVJ,hp1!!#A%!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_OD03,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_OD03,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_OD03,value= _NUM:0
	SetVariable SetVar_WaveBuilder_DD06,pos={466,81},size={150,16},disable=1,proc=WBP_SetVarProc_8,title="Delta"
	SetVariable SetVar_WaveBuilder_DD06,userdata(tabnum)=  "6"
	SetVariable SetVar_WaveBuilder_DD06,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_DD06,userdata(ResizeControlsInfo)= A"!!,IO!!#?[!!#A%!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_DD06,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_DD06,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_DD06,value= _NUM:0
	SetVariable SetVar_WaveBuilder_OD04,pos={312,81},size={150,16},disable=1,proc=WBP_SetVarProc_7,title="Offset"
	SetVariable SetVar_WaveBuilder_OD04,userdata(tabnum)=  "6"
	SetVariable SetVar_WaveBuilder_OD04,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_OD04,userdata(ResizeControlsInfo)= A"!!,HW!!#?[!!#A%!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_OD04,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_OD04,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_OD04,value= _NUM:0
	SetVariable SetVar_WaveBuilder_P18,pos={311,81},size={150,16},disable=1,proc=WBP_SetVarProc_2,title="Offset"
	SetVariable SetVar_WaveBuilder_P18,userdata(tabnum)=  "7"
	SetVariable SetVar_WaveBuilder_P18,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P18,userdata(ResizeControlsInfo)= A"!!,HVJ,hp1!!#A%!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P18,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P18,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P18,value= _NUM:0
	SetVariable SetVar_WaveBuilder_P19,pos={466,81},size={150,16},disable=1,proc=WBP_SetVarProc_2,title="Delta"
	SetVariable SetVar_WaveBuilder_P19,userdata(tabnum)=  "7"
	SetVariable SetVar_WaveBuilder_P19,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P19,userdata(ResizeControlsInfo)= A"!!,IO!!#?[!!#A%!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P19,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P19,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P19,value= _NUM:0
	SetVariable setvar_WaveBuilder_SearchString,pos={688,35},size={216,30},disable=1,proc=WBP_SetVarProc_SetSearchString,title="Search\rstring"
	SetVariable setvar_WaveBuilder_SearchString,help={"Include asterisk where appropriate"}
	SetVariable setvar_WaveBuilder_SearchString,userdata(tabnum)=  "7"
	SetVariable setvar_WaveBuilder_SearchString,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable setvar_WaveBuilder_SearchString,userdata(ResizeControlsInfo)= A"!!,J=!!#=o!!#Ag!!#=Sz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_WaveBuilder_SearchString,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_WaveBuilder_SearchString,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_WaveBuilder_SearchString,value= _STR:"*dac*"
	PopupMenu popup_WaveBuilder_ListOfWaves,pos={691,70},size={212,26},bodyWidth=177,disable=1,proc=WBP_PopMenuProc_1,title="Wave\rto load"
	PopupMenu popup_WaveBuilder_ListOfWaves,userdata(tabnum)=  "7"
	PopupMenu popup_WaveBuilder_ListOfWaves,userdata(tabcontrol)=  "WBP_WaveType"
	PopupMenu popup_WaveBuilder_ListOfWaves,userdata(ResizeControlsInfo)= A"!!,J=^]6][!!#Ac!!#=3z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu popup_WaveBuilder_ListOfWaves,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu popup_WaveBuilder_ListOfWaves,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu popup_WaveBuilder_ListOfWaves,mode=1,popvalue="- none -",value= #"RemoveGraphTracesFromList()"
	SetVariable SetVar_WaveBuilder_P20,pos={685,32},size={150,30},disable=1,proc=WBP_SetVarProc_2,title="Low pass cut \roff frequency"
	SetVariable SetVar_WaveBuilder_P20,help={"Set to 100001 to turn off low pass filter"}
	SetVariable SetVar_WaveBuilder_P20,userdata(tabnum)=  "2"
	SetVariable SetVar_WaveBuilder_P20,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P20,userdata(ResizeControlsInfo)= A"!!,J<5QF+N!!#A%!!#=Sz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P20,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P20,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P20,limits={0,100001,1},value= _NUM:0
	SetVariable SetVar_WaveBuilder_P21,pos={840,32},size={91,16},disable=1,proc=WBP_SetVarProc_2,title="Delta"
	SetVariable SetVar_WaveBuilder_P21,userdata(tabnum)=  "2"
	SetVariable SetVar_WaveBuilder_P21,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P21,userdata(ResizeControlsInfo)= A"!!,Jc!!#=c!!#?o!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P21,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P21,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P21,limits={-inf,100000,1},value= _NUM:0
	SetVariable SetVar_WaveBuilder_P22,pos={685,71},size={150,30},disable=1,proc=WBP_SetVarProc_2,title="High pass cut \roff frequency"
	SetVariable SetVar_WaveBuilder_P22,help={"Set to zero to turn off high pass filter"}
	SetVariable SetVar_WaveBuilder_P22,userdata(tabnum)=  "2"
	SetVariable SetVar_WaveBuilder_P22,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P22,userdata(ResizeControlsInfo)= A"!!,J<5QF-2!!#A%!!#=Sz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P22,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P22,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P22,limits={0,100000,1},value= _NUM:0
	SetVariable SetVar_WaveBuilder_P23,pos={841,71},size={91,16},disable=1,proc=WBP_SetVarProc_2,title="Delta"
	SetVariable SetVar_WaveBuilder_P23,userdata(tabnum)=  "2"
	SetVariable SetVar_WaveBuilder_P23,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P23,userdata(ResizeControlsInfo)= A"!!,Jc5QF-2!!#?o!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P23,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P23,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P23,limits={-inf,99999,1},value= _NUM:0
	SetVariable setvar_WaveBuilder_P11,pos={397,123},size={50,16},disable=1
	SetVariable setvar_WaveBuilder_P11,userdata(ResizeControlsInfo)= A"!!,I,J,hq0!!#>V!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_WaveBuilder_P11,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_WaveBuilder_P11,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_WaveBuilder_P11,value= _NUM:0
	SetVariable setvar_WaveBuilder_P13,pos={399,100},size={50,16},disable=1
	SetVariable setvar_WaveBuilder_P13,userdata(ResizeControlsInfo)= A"!!,I-J,hpW!!#>V!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_WaveBuilder_P13,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_WaveBuilder_P13,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_WaveBuilder_P13,value= _NUM:0
	SetVariable setvar_WaveBuilder_P15,pos={467,122},size={50,16},disable=1
	SetVariable setvar_WaveBuilder_P15,userdata(ResizeControlsInfo)= A"!!,IOJ,hq.!!#>V!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_WaveBuilder_P15,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_WaveBuilder_P15,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_WaveBuilder_P15,value= _NUM:0
	SetVariable setvar_WaveBuilder_P17,pos={465,100},size={50,16},disable=1
	SetVariable setvar_WaveBuilder_P17,userdata(ResizeControlsInfo)= A"!!,INJ,hpW!!#>V!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_WaveBuilder_P17,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_WaveBuilder_P17,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_WaveBuilder_P17,value= _NUM:0
	TitleBox Title_Wavebuilder,pos={175,8},size={84,16},title="Set parmeters"
	TitleBox Title_Wavebuilder,userdata(ResizeControlsInfo)= A"!!,G?!!#:b!!#?a!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox Title_Wavebuilder,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	TitleBox Title_Wavebuilder,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	TitleBox Title_Wavebuilder,fSize=14,frame=0
	DefineGuide UGH0={FB,-42}
	SetWindow kwTopWin,hook(ResizeControls)=ResizeControls#ResizeControlsHook
	SetWindow kwTopWin,userdata(ResizeControlsInfo)= A"!!*'\"z!!#E/J,ht#J,fQLzzzzzzzzzzzzzzzzzzzz"
	SetWindow kwTopWin,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzzzzzzzzzzzzzzz"
	SetWindow kwTopWin,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzzzzzzzzz!!!"
	Display/W=(0,159,671,402)/FG=(,,FR,UGH0)/HOST=#  '1_ladida_DAC_Set_1','2_ladida_DAC_Set_1'
	ModifyGraph frameInset=2
	ModifyGraph rgb('1_ladida_DAC_Set_1')=(13056,13056,13056)
	SetDrawLayer UserFront
	SetWindow kwTopWin,userdata(tabcontrol)=  "WBP_WaveType"
	SetWindow kwTopWin,userdata(ResizeControlsInfo)= A"!!,Ct!!#A/!!#E!5QF0#!!!!\"zzzzzzzzzzzzzzzzzzzz"
	SetWindow kwTopWin,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzzzzzzzzzzzzzzz"
	SetWindow kwTopWin,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzzzzzzzzz!!!"
	RenameWindow #,WaveBuilderGraph
	SetActiveSubwindow ##
EndMacro




Function WBP_SetVarProc_1(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	wave segmentwavetype
variable SegmentNo, SegmentToEdit
controlinfo SetVar_WaveBuilder_NoOfSegments
SegmentNo=v_value
controlinfo Setvar_WaveBuilder_SegmentEdit
SegmentToEdit=v_value

if(SegmentNo<=SegmentToEdit)// This prevents the segment to edit from being larger than the max number of segements
SetVariable setvar_WaveBuilder_SegmentEdit value=_num:SegmentNo-1


	TabControl WBP_WaveType value=SegmentWaveType[SegmentNo-1]// this selects the correct tab based on changes to the segment to edit value
	ExecuteAdamsTabcontrol(SegmentWaveType[SegmentNo-1])
endif

MakeStimSet()
DisplaySetInPanel()
End


Function WBP_SetVarProc(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	controlinfo SetVar_WaveBuilder_NoOfSegments
	SetVariable setvar_WaveBuilder_SegmentEdit ,limits={0,v_value-1,1}// sets the maximum segment to edit number to be equal to the numbeer of segments specified
	
	wave SegmentWaveType
	variable StimulusType
	StimulusType=SegmentWaveType[varNum]//selects the appropriate tab based on the data in the segmentwavetype wave
	TabControl WBP_WaveType value=StimulusType
	ExecuteAdamsTabcontrol(StimulusType)

	
	variable ParamWaveType=StimulusType
	ParamToPanel(ParamWaveType)
	
	MakeStimSet()
	DisplaySetInPanel()
End




Function SetVarProc_3(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	MakeStimSet()
	DisplaySetInPanel()
	End
	
	Function ButtonProc(ctrlName) : ButtonControl
		String ctrlName
		variable i=0
	string ListOfWavesToKill
	controlinfo popup_WaveBuilder_SetList
	string SearchString = s_value
	string WaveNameFromList, cmd
	ListOfWavesToKill=wavelist("*"+SearchString[2,inf],";","")
	
		do
			WaveNameFromList=stringfromlist(i,listofwavestokill,";")
				if(strlen(WaveNameFromList) != 0)
				sprintf cmd, "killwaves/f/z  %s" "'"+WaveNameFromList+"'"
				execute cmd
				endif
			i+=1
		while(i<(itemsinlist(listofwavestokill,";")))
End

Function SetVarProc_4(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	LowPassDeltaLimits()
	HighPassDeltaLimits()
	MakeStimSet()
	DisplaySetInPanel()
End

Function ButtonProc_1(ctrlName) : ButtonControl
	String ctrlName
SetAxis/A/w=wavebuilder#wavebuildergraph
End

Function WBP_CheckProc(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	MakeStimSet()
	DisplaySetInPanel()
End




Function TabTJHook(tca)//This is a function that gets run by ACLight's tab control function every time a tab is selected
	STRUCT WMTabControlAction &tca
	variable tabnum
	wave segmentwavetype
	//controlinfo WBP_WaveType
	tabnum=tca.tab


	controlinfo popup_WaveBuilder_OutputType
	if(cmpstr(s_value,"TTL")==0)
		if(tabnum==1 || tabnum==2|| tabnum==3|| tabnum==4|| tabnum==6)
			return 1
		else
			controlinfo setvar_WaveBuilder_SegmentEdit
			segmentwavetype[v_value]=tabnum
	
			variable ParamWaveType=tabnum
			ParamToPanel(ParamWaveType)

			MakeStimSet()
			DisplaySetInPanel()
	
			return 0
		endif
	else
			
	if(tabnum==7)
	SetVariable SetVar_WaveBuilder_P0 disable=2,value= _NUM:0
	SetVariable SetVar_WaveBuilder_P1 disable=2,value= _NUM:0
	SetVariable SetVar_WaveBuilder_P2 disable=2,value= _NUM:0
	SetVariable SetVar_WaveBuilder_P3 disable=2,value= _NUM:0
	else
	SetVariable SetVar_WaveBuilder_P0 disable=0
	SetVariable SetVar_WaveBuilder_P1 disable=0
	SetVariable SetVar_WaveBuilder_P2 disable=0
	SetVariable SetVar_WaveBuilder_P3 disable=0
	endif
	
	controlinfo setvar_WaveBuilder_SegmentEdit// Assings wave type to segment
	segmentwavetype[v_value]=tabnum
	
	ParamWaveType=tabnum
	ParamToPanel(ParamWaveType)// passed parameters from appropriate parameter wave to panel
	
	MakeStimSet()
	DisplaySetInPanel()
	
	return 0
	endif
End


Function/s DeleteListPopUp()
	
	string ListItemToRemove = stringfromlist(0,tracenamelist("WaveBuilder#WaveBuilderGraph", ";",0+1 ),";")
	ListItemToRemove= ListItemToRemove[1,(strlen(ListItemToRemove)-2)]
	
	string ListString ="- none -;"+WaveList("1_*DAC_Set*", ";","" )+WaveList("1_*TTL_Set*", ";","" )
	
	ListString=Removefromlist( ListItemToRemove, ListString,";")
	return liststring
End


Function ButtonProc_2(ctrlName) : ButtonControl
	String ctrlName

	string ListOfTracesOnGraph
	ListOfTracesOnGraph=TraceNameList("WaveBuilder#WaveBuilderGraph", ",",0+1 )
	variable i=0
	
	if(itemsinlist(ListOfTracesOnGraph,",")!=0)
	do

	removefromgraph/w=WaveBuilder#WaveBuilderGraph $stringfromlist(i,ListOfTracesOnGraph,",")
	//doupdate
	i+=1
	while(i<(itemsinlist(ListOfTracesOnGraph,",")))
	endif
	SetVariable setvar_WaveBuilder_baseName value= _STR:"Insert Base Name"

End


Function WBP_SetVarProc_5(ctrlName,varNum,varStr,varName) : SetVariableControl// setvarproc 5-8 pass data from one setvariable control to another, they also run a version of the other controls procedures
	String ctrlName
	Variable varNum
	String varStr
	String varName
	
	Setvariable SetVar_WaveBuilder_P6, value=_num:varnum
		
	variable StimulusType
	controlinfo WBP_WaveType
	StimulusType=v_value
	
	variable SegmentNo
	controlinfo setvar_WaveBuilder_SegmentEdit
	SegmentNo=v_value
	
	string parameterName
	variable ParameterRow=str2num("SetVar_WaveBuilder_P6"[(strsearch("SetVar_WaveBuilder_P6", "P",0)+1),inf])
	
	string NameOfParamWave
	string cmd
	
	ParameterName="SetVar_WaveBuilder_P"+num2str(ParameterRow)
	controlinfo parameterName
	NameOfParamWave="WP"//WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW
	
	sprintf cmd, "%s[%d][%d][%d]=%g" nameOfParamWave, ParameterRow, segmentNo, stimulusType,varnum
	execute cmd
			
	MakeStimSet()
	DisplaySetInPanel()
End

Function WBP_SetVarProc_6(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	Setvariable SetVar_WaveBuilder_P7, value=_num:varnum
		
	variable StimulusType
	controlinfo WBP_WaveType
	StimulusType=v_value
	
	variable SegmentNo
	controlinfo setvar_WaveBuilder_SegmentEdit
	SegmentNo=v_value
	
	string parameterName
	variable ParameterRow=str2num("SetVar_WaveBuilder_P7"[(strsearch("SetVar_WaveBuilder_P7", "P",0)+1),inf])
	
	string NameOfParamWave
	string cmd
	
	ParameterName="SetVar_WaveBuilder_P"+num2str(ParameterRow)
	controlinfo parameterName
	NameOfParamWave="WP"//+num2str(StimulusType)
	
	sprintf cmd, "%s[%d][%d][%d]=%g" nameOfParamWave, ParameterRow, segmentNo, stimulusType, varnum
	execute cmd
			
	MakeStimSet()
	DisplaySetInPanel()
End

Function WBP_SetVarProc_2(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	wave WP7T
	variable StimulusType
	controlinfo WBP_WaveType
	StimulusType=v_value
	
	variable SegmentNo
	controlinfo setvar_WaveBuilder_SegmentEdit
	SegmentNo=v_value
	
	string parameterName
	variable ParameterRow=str2num(ctrlName[(strsearch(ctrlName, "P",0)+1),inf])
	
	string NameOfParamWave
	string cmd
	
	ParameterName="SetVar_WaveBuilder_P"+num2str(ParameterRow)
	controlinfo parameterName
	NameOfParamWave="WP"
	
	sprintf cmd, "%s[%d][%d][%d]=%g" nameOfParamWave, ParameterRow, segmentNo, stimulusType, varnum
	execute cmd
	
	controlinfo WBP_WaveType
	if(v_value==2)
	LowPassDeltaLimits()
	HighPassDeltaLimits()
	endif
	
	MakeStimSet()
	DisplaySetInPanel()

End

Function LowPassDeltaLimits()
variable LowPassCutOff, StepCount, LowPassDelta, DeltaLimit

	ControlInfo SetVar_WaveBuilder_StepCount
	StepCount = v_value
	
	ControlInfo SetVar_WaveBuilder_P20
	LowPassCutoff=v_value
	
	ControlInfo SetVar_WaveBuilder_P21
	LowPassDelta = v_value
	
	if(LowPassDelta>0)
	DeltaLimit=trunc(100000/StepCount)
	SetVariable SetVar_WaveBuilder_P21 limits={-inf,DeltaLimit,1}
		If(LowPassDelta>DeltaLimit)
		SetVariable SetVar_WaveBuilder_P21 value=_num:DeltaLimit
		endif
	endif
	
	if(LowPassDelta<0)
	DeltaLimit=trunc(-((LowPassCutOff/StepCount)-1))
	SetVariable SetVar_WaveBuilder_P21 limits={DeltaLimit,99999,1}
		If(LowPassDelta<DeltaLimit)
		SetVariable SetVar_WaveBuilder_P21 value=_num:DeltaLimit
		endif
		
	endif

End

Function HighPassDeltaLimits()
variable HighPassCutOff, StepCount, HighPassDelta, DeltaLimit

	ControlInfo SetVar_WaveBuilder_StepCount
	StepCount = v_value
	
	ControlInfo SetVar_WaveBuilder_P22
	HighPassCutoff=v_value
	
	ControlInfo SetVar_WaveBuilder_P23
	HighPassDelta = v_value
	
	if(HighPassDelta>0)
	DeltaLimit=trunc((100000-HighPassCutOff)/StepCount)-1
	SetVariable SetVar_WaveBuilder_P23 limits={-inf,DeltaLimit,1}
		If(HighPassDelta>DeltaLimit)
		SetVariable SetVar_WaveBuilder_P23 value=_num:DeltaLimit
		endif
	endif
	
	if(HighPassDelta<0)
	DeltaLimit=trunc(HighPassCutOff/StepCount)+1
	SetVariable SetVar_WaveBuilder_P23 limits={DeltaLimit,99999,1}
		If(HighPassDelta<DeltaLimit)
		SetVariable SetVar_WaveBuilder_P23 value=_num:DeltaLimit
		endif
		
	endif

End

Function WBP_SetVarProc_7(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	Setvariable SetVar_WaveBuilder_P4, value=_num:varnum
		
	variable StimulusType
	controlinfo WBP_WaveType
	StimulusType=v_value
	
	variable SegmentNo
	controlinfo setvar_WaveBuilder_SegmentEdit
	SegmentNo=v_value
	
	string parameterName
	variable ParameterRow=str2num("SetVar_WaveBuilder_P4"[(strsearch("SetVar_WaveBuilder_P4", "P",0)+1),inf])
	
	string NameOfParamWave
	string cmd
	
	ParameterName="SetVar_WaveBuilder_P"+num2str(ParameterRow)
	controlinfo parameterName
	NameOfParamWave="WP"//+num2str(StimulusType)
	
	sprintf cmd, "%s[%d][%d][%d]=%g" nameOfParamWave, ParameterRow, segmentNo, stimulusType, varnum
	execute cmd
		
		
		MakeStimSet()
	DisplaySetInPanel()
End

Function WBP_SetVarProc_8(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	Setvariable SetVar_WaveBuilder_P5, value=_num:varnum
		
	variable StimulusType
	controlinfo WBP_WaveType
	StimulusType=v_value
	
	variable SegmentNo
	controlinfo setvar_WaveBuilder_SegmentEdit
	SegmentNo=v_value
	
	string parameterName
	variable ParameterRow=str2num("SetVar_WaveBuilder_P5"[(strsearch("SetVar_WaveBuilder_P5", "P",0)+1),inf])
	
	string NameOfParamWave
	string cmd
	
	ParameterName="SetVar_WaveBuilder_P"+num2str(ParameterRow)
	controlinfo parameterName
	NameOfParamWave="WP"//+num2str(StimulusType)
	
	sprintf cmd, "%s[%d][%d][%d]=%g" nameOfParamWave, ParameterRow, segmentNo, stimulusType, varnum
	execute cmd
		
		
		MakeStimSet()
	DisplaySetInPanel()
End


Function ExecuteAdamsTabcontrol(TabToGoTo)
	variable TabToGoTo
	Struct WMTabControlAction tca

	tca.ctrlName = "WBP_WaveType"	
	tca.win	= "wavebuilder"	
	tca.eventCode =2	
	tca.tab=	TabToGoTo

	Variable returnedValue = ACL_DisplayTab(tca)
End


Function WBP_PopMenuProc(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	wave segmentwavetype, WP//WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW
if (cmpstr(popstr,"TTL")==0)

	SegmentWaveType=0
	WP[1,6][][]=0//WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW
	//WP1[1,6][]=0
	//WP2[1,6][]=0
	//WP3[1,6][]=0
	//WP4[1,6][]=0
	//WP5[1,6][]=0
	//WP6[1,6][]=0
	//WP7[1,6][]=0
	
	SetVariable SetVar_WaveBuilder_P2 limits={0,1,1}, value= _NUM:0
	WBP_SetVarProc_2("SetVar_WaveBuilder_P2",0,"1","")
	SetVariable SetVar_WaveBuilder_P3 disable=2,value= _NUM:0
	WBP_SetVarProc_2("SetVar_WaveBuilder_P3",0,"0","")
	SetVariable SetVar_WaveBuilder_P4 disable=2,value= _NUM:0
	WBP_SetVarProc_2("SetVar_WaveBuilder_P4",0,"0","")
	SetVariable SetVar_WaveBuilder_P5 disable=2,value= _NUM:0
	WBP_SetVarProc_2("SetVar_WaveBuilder_P5",0,"0","")
	
	SetVariable SetVar_WaveBuilder_OD00 disable=2,value= _NUM:0// i need to run the procedure associated to the particular set variable
	SetVariable SetVar_WaveBuilder_OD01 disable=2,value= _NUM:0
	SetVariable SetVar_WaveBuilder_OD02 disable=2,value= _NUM:0
	SetVariable SetVar_WaveBuilder_OD03 disable=2,value= _NUM:0
	SetVariable SetVar_WaveBuilder_OD04 disable=2,value= _NUM:0
	
	SetVariable SetVar_WaveBuilder_DD02 disable=2,value= _NUM:0
	SetVariable SetVar_WaveBuilder_DD03 disable=2,value= _NUM:0
	SetVariable SetVar_WaveBuilder_DD04 disable=2,value= _NUM:0
	SetVariable SetVar_WaveBuilder_DD05 disable=2,value= _NUM:0
	SetVariable SetVar_WaveBuilder_DD06 disable=2,value= _NUM:0
	
	TabControl WBP_WaveType value=0
	
	ExecuteAdamsTabcontrol(0)

endif

if (cmpstr(popstr,"DAC")==0)
//SetVariable SetVar_WaveBuilder_P2 disable=0
	SetVariable SetVar_WaveBuilder_P2 limits={-inf,inf,1}
	SetVariable SetVar_WaveBuilder_P3 disable=0
	SetVariable SetVar_WaveBuilder_P4 disable=0
	SetVariable SetVar_WaveBuilder_P5 disable=0
	
	SetVariable SetVar_WaveBuilder_OD00 disable=0
	SetVariable SetVar_WaveBuilder_OD01 disable=0
	SetVariable SetVar_WaveBuilder_OD02 disable=0
	SetVariable SetVar_WaveBuilder_OD03 disable=0
	SetVariable SetVar_WaveBuilder_OD04 disable=0
	
	SetVariable SetVar_WaveBuilder_DD02 disable=0
	SetVariable SetVar_WaveBuilder_DD03 disable=0
	SetVariable SetVar_WaveBuilder_DD04 disable=0
	SetVariable SetVar_WaveBuilder_DD05 disable=0
	SetVariable SetVar_WaveBuilder_DD06 disable=0
endif

End

Function WBP_SetVarProc_SetSearchString(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName

String cmd
//String SearchString = VarStr

variable i = 0


//PopupMenu popup_WaveBuilder_ListOfWaves value="- none -;"+Wavelist(SearchString(),";","TEXT:0,MAXCOLS:1")

// = stringfromlist(0,tracenamelist("WaveBuilder#WaveBuilderGraph", ";",0+1 ),";")


PopupMenu popup_WaveBuilder_ListOfWaves value= RemoveGraphTracesFromList()


End

Function/t SearchString()
String Str

controlInfo setvar_WaveBuilder_SearchString

	If (strlen(s_value)==0)
		str="*"
		else
		str = s_value
	endif

Return str
End

Function/t RemoveGraphTracesFromList()
	variable i = 0
	variable ListItems = itemsinlist(tracenamelist("WaveBuilder#WaveBuilderGraph", ";",0+1 ),";")
	string ListString ="- none -;"+Wavelist(SearchString(),";","TEXT:0,MAXCOLS:1")
	string ListItemToRemove
	
	do
		ListItemToRemove = stringfromlist(i,tracenamelist("WaveBuilder#WaveBuilderGraph", ";",0+1 ),";")
		ListItemToRemove= ListItemToRemove[1,(strlen(ListItemToRemove)-2)]
		ListString=Removefromlist( ListItemToRemove, ListString,";")
		i+=1
	while(i<ListItems)
	
	return ListString
End

Function WBP_PopMenuProc_1(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	wave/t WP7T
		//CUSTOM WAVE CODE
	string cmd
	variable SegmentNo
	
	ControlInfo setvar_WaveBuilder_SegmentEdit
	SegmentNo=v_value
		
		
		If(stringmatch(popStr,"- none -")==0)// checks to make sure "- none -" is not selected as a wave type	
		sprintf cmd, "WP7T[%d][%d]= nameofwave('%s')" 0, SegmentNo, popStr
		execute cmd
		else
		WP7T[0][SegmentNo]= ""
			
		
		endif
	
	//END OF CUSTOM WAVE CODE
	MakeStimSet()
	DisplaySetInPanel()
End



