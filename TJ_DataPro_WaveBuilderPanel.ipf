#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#include <Resize Controls>
#include <FilterDialog> menus=0

Window WaveBuilder() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(498,184,1515,658)
	SetVariable SetVar_WaveBuilder_NoOfSegments,pos={23,61},size={124,20},proc=WBP_SetVarProc_TotEpoch,title="Total Epochs"
	SetVariable SetVar_WaveBuilder_NoOfSegments,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_NoOfSegments,userdata(ResizeControlsInfo)= A"!!,Bq!!#?-!!#@\\!!#<Xz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_NoOfSegments,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_NoOfSegments,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_NoOfSegments,fSize=14
	SetVariable SetVar_WaveBuilder_NoOfSegments,limits={1,100,1},value= _NUM:3
	SetVariable SetVar_WaveBuilder_P0,pos={194,34},size={100,16},proc=WBP_SetVarProc_UpdateParam,title="Duration"
	SetVariable SetVar_WaveBuilder_P0,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P0,userdata(ResizeControlsInfo)= A"!!,GR!!#=k!!#@,!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P0,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P0,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P0,limits={0,inf,1},value= _NUM:50
	SetVariable SetVar_WaveBuilder_P1,pos={300,34},size={100,16},proc=WBP_SetVarProc_UpdateParam,title="Delta"
	SetVariable SetVar_WaveBuilder_P1,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P1,userdata(ResizeControlsInfo)= A"!!,HQ!!#=k!!#@,!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P1,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P1,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P1,value= _NUM:0
	SetVariable SetVar_WaveBuilder_StepCount,pos={34,85},size={113,20},proc=WBP_SetVarProc_StepCount,title="Total Steps"
	SetVariable SetVar_WaveBuilder_StepCount,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_StepCount,userdata(ResizeControlsInfo)= A"!!,Cl!!#?c!!#@F!!#<Xz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_StepCount,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_StepCount,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_StepCount,fSize=14,limits={1,99,1},value= _NUM:1
	SetVariable setvar_WaveBuilder_P10,pos={488,34},size={100,16},disable=1,proc=WBP_SetVarProc_UpdateParam,title="Tau Rise"
	SetVariable setvar_WaveBuilder_P10,userdata(tabnum)=  "6"
	SetVariable setvar_WaveBuilder_P10,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable setvar_WaveBuilder_P10,userdata(ResizeControlsInfo)= A"!!,IZ!!#=k!!#@,!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_WaveBuilder_P10,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_WaveBuilder_P10,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_WaveBuilder_P10,value= _NUM:0
	SetVariable setvar_WaveBuilder_P12,pos={488,56},size={100,16},disable=1,proc=WBP_SetVarProc_UpdateParam,title="Tau Decay 1"
	SetVariable setvar_WaveBuilder_P12,userdata(tabnum)=  "6"
	SetVariable setvar_WaveBuilder_P12,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable setvar_WaveBuilder_P12,userdata(ResizeControlsInfo)= A"!!,IZ!!#>n!!#@,!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_WaveBuilder_P12,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_WaveBuilder_P12,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_WaveBuilder_P12,value= _NUM:0
	SetVariable setvar_WaveBuilder_P14,pos={488,80},size={100,16},disable=1,proc=WBP_SetVarProc_UpdateParam,title="Tau Decay 2"
	SetVariable setvar_WaveBuilder_P14,userdata(tabnum)=  "6"
	SetVariable setvar_WaveBuilder_P14,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable setvar_WaveBuilder_P14,userdata(ResizeControlsInfo)= A"!!,IZ!!#?Y!!#@,!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_WaveBuilder_P14,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_WaveBuilder_P14,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_WaveBuilder_P14,value= _NUM:0
	SetVariable setvar_WaveBuilder_P16,pos={488,103},size={100,16},disable=1,proc=WBP_SetVarProc_UpdateParam,title="Tau 2 weight"
	SetVariable setvar_WaveBuilder_P16,userdata(tabnum)=  "6"
	SetVariable setvar_WaveBuilder_P16,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable setvar_WaveBuilder_P16,userdata(ResizeControlsInfo)= A"!!,IZ!!#@2!!#@,!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_WaveBuilder_P16,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_WaveBuilder_P16,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_WaveBuilder_P16,limits={0,1,0.1},value= _NUM:0
	SetVariable SetVar_WaveBuilder_P2,pos={194,57},size={100,16},proc=WBP_SetVarProc_UpdateParam,title="Amplitude"
	SetVariable SetVar_WaveBuilder_P2,help={"For G-Noise wave, amplitude = Standard deviation"}
	SetVariable SetVar_WaveBuilder_P2,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P2,userdata(ResizeControlsInfo)= A"!!,GR!!#>r!!#@,!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P2,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P2,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P2,value= _NUM:0
	SetVariable SetVar_WaveBuilder_P3,pos={300,57},size={100,16},proc=WBP_SetVarProc_UpdateParam,title="Delta"
	SetVariable SetVar_WaveBuilder_P3,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P3,userdata(ResizeControlsInfo)= A"!!,HQ!!#>r!!#@,!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P3,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P3,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P3,value= _NUM:0
	SetVariable setvar_WaveBuilder_SetNumber,pos={879,41},size={116,16},proc=WBP_SetVarProc_SetNo,title="Set Number"
	SetVariable setvar_WaveBuilder_SetNumber,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable setvar_WaveBuilder_SetNumber,userdata(ResizeControlsInfo)= A"!!,Jl^]6\\H!!#@L!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_WaveBuilder_SetNumber,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_WaveBuilder_SetNumber,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_WaveBuilder_SetNumber,limits={0,inf,1},value= _NUM:0
	SetVariable SetVar_WaveBuilder_P4,pos={194,81},size={100,16},proc=WBP_SetVarProc_UpdateParam,title="Offset"
	SetVariable SetVar_WaveBuilder_P4,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P4,userdata(ResizeControlsInfo)= A"!!,GR!!#?[!!#@,!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P4,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P4,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P4,userdata(tabnum)=  "1",value= _NUM:0
	SetVariable SetVar_WaveBuilder_P6,pos={194,105},size={100,16},disable=1,proc=WBP_SetVarProc_UpdateParam,title="Start Freq"
	SetVariable SetVar_WaveBuilder_P6,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P6,userdata(ResizeControlsInfo)= A"!!,GR!!#@6!!#@,!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P6,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P6,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P6,userdata(tabnum)=  "3",value= _NUM:0
	TabControl WBP_WaveType,pos={186,3},size={677,173},proc=ACL_DisplayTab
	TabControl WBP_WaveType,userdata(tabcontrol)=  "WBP_WaveType"
	TabControl WBP_WaveType,userdata(currenttab)=  "0"
	TabControl WBP_WaveType,userdata(initialhook)=  "TabTJHook"
	TabControl WBP_WaveType,userdata(ResizeControlsInfo)= A"!!,GJ!!#8L!!#D8^]6_Sz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TabControl WBP_WaveType,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	TabControl WBP_WaveType,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	TabControl WBP_WaveType,tabLabel(0)="Square pulse",tabLabel(1)="Ramp"
	TabControl WBP_WaveType,tabLabel(2)="G-Noise",tabLabel(3)="Sin"
	TabControl WBP_WaveType,tabLabel(4)="Saw tooth",tabLabel(5)="Square pulse train"
	TabControl WBP_WaveType,tabLabel(6)="PSC",tabLabel(7)="Load custom wave"
	TabControl WBP_WaveType,value= 0
	SetVariable setvar_WaveBuilder_SegmentEdit,pos={25,109},size={122,20},proc=WBP_SetVarProc_EpochToEdit,title="Epoch to edit"
	SetVariable setvar_WaveBuilder_SegmentEdit,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable setvar_WaveBuilder_SegmentEdit,userdata(ResizeControlsInfo)= A"!!,C,!!#@>!!#@X!!#<Xz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_WaveBuilder_SegmentEdit,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_WaveBuilder_SegmentEdit,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_WaveBuilder_SegmentEdit,fSize=14,limits={0,2,1},value= _NUM:1
	SetVariable SetVar_WaveBuilder_P5,pos={300,81},size={100,16},proc=WBP_SetVarProc_UpdateParam,title="Delta"
	SetVariable SetVar_WaveBuilder_P5,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P5,userdata(ResizeControlsInfo)= A"!!,HQ!!#?[!!#@,!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P5,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P5,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P5,userdata(tabnum)=  "1",value= _NUM:0
	SetVariable SetVar_WaveBuilder_P7,pos={301,105},size={100,16},disable=1,proc=WBP_SetVarProc_UpdateParam,title="Delta"
	SetVariable SetVar_WaveBuilder_P7,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P7,userdata(ResizeControlsInfo)= A"!!,HQJ,hpa!!#@,!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P7,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P7,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P7,userdata(tabnum)=  "3",value= _NUM:0
	SetVariable SetVar_WaveBuilder_P8,pos={194,129},size={100,16},disable=1,proc=WBP_SetVarProc_UpdateParam,title="Pulse Dur"
	SetVariable SetVar_WaveBuilder_P8,userdata(tabnum)=  "5"
	SetVariable SetVar_WaveBuilder_P8,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P8,userdata(ResizeControlsInfo)= A"!!,GR!!#@e!!#@,!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P8,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P8,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P8,limits={0,99.991,0.1},value= _NUM:0
	SetVariable SetVar_WaveBuilder_P9,pos={301,129},size={100,16},disable=1,proc=WBP_SetVarProc_UpdateParam,title="Delta"
	SetVariable SetVar_WaveBuilder_P9,userdata(tabnum)=  "5"
	SetVariable SetVar_WaveBuilder_P9,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P9,userdata(ResizeControlsInfo)= A"!!,HQJ,hq;!!#@,!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P9,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P9,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P9,value= _NUM:0
	SetVariable setvar_WaveBuilder_baseName,pos={879,63},size={116,30},proc=WBP_SetVarProc_SetNo,title="Name\rprefix"
	SetVariable setvar_WaveBuilder_baseName,help={"max number of characters = 16"}
	SetVariable setvar_WaveBuilder_baseName,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable setvar_WaveBuilder_baseName,userdata(ResizeControlsInfo)= A"!!,Jl^]6]K!!#@L!!#=Sz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_WaveBuilder_baseName,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_WaveBuilder_baseName,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_WaveBuilder_baseName,fSize=8
	SetVariable setvar_WaveBuilder_baseName,limits={0,10,1},value= _STR:"InsertBaseName"
	PopupMenu popup_WaveBuilder_SetList,pos={685,443},size={150,21},bodyWidth=150
	PopupMenu popup_WaveBuilder_SetList,userdata(tabcontrol)=  "WBP_WaveType"
	PopupMenu popup_WaveBuilder_SetList,userdata(ResizeControlsInfo)= A"!!,J<5QF1-J,hqP!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu popup_WaveBuilder_SetList,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#?(FEDG<zzzzzzzzzzz"
	PopupMenu popup_WaveBuilder_SetList,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	PopupMenu popup_WaveBuilder_SetList,mode=1,popvalue="- none -",value= #"\"- none -;\"+ WBP_ReturnListSavedSets(\"DA\")+WBP_ReturnListSavedSets(\"TTL\")"
	Button button_WaveBuilder_KillSet,pos={840,442},size={150,23},proc=WBP_ButtonProc_DeleteSet,title="Delete Set"
	Button button_WaveBuilder_KillSet,help={"If set isn't removed from list after deleting, a wave from the set must be in use, kill the appropriate graph or table and retry."}
	Button button_WaveBuilder_KillSet,userdata(tabcontrol)=  "WBP_WaveType"
	Button button_WaveBuilder_KillSet,userdata(ResizeControlsInfo)= A"!!,Jc!!#CB!!#A%!!#<pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_WaveBuilder_KillSet,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#?(FEDG<zzzzzzzzzzz"
	Button button_WaveBuilder_KillSet,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	CheckBox check_WaveBuilder_exp,pos={413,32},size={49,20},proc=WBP_CheckProc,title="Delta\\S2"
	CheckBox check_WaveBuilder_exp,userdata(tabcontrol)=  "WBP_WaveType"
	CheckBox check_WaveBuilder_exp,userdata(ResizeControlsInfo)= A"!!,I4J,hn9!!#>R!!#<Xz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_WaveBuilder_exp,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_WaveBuilder_exp,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_WaveBuilder_exp,value= 0
	Button button_WaveBuilder_setaxisA,pos={19,442},size={150,23},proc=WBP_ButtonProc_AutoScale,title="Autoscale"
	Button button_WaveBuilder_setaxisA,userdata(tabcontrol)=  "WBP_WaveType"
	Button button_WaveBuilder_setaxisA,userdata(ResizeControlsInfo)= A"!!,BQ!!#CB!!#A%!!#<pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_WaveBuilder_setaxisA,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#?(FEDG<zzzzzzzzzzz"
	Button button_WaveBuilder_setaxisA,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	PopupMenu popup_WaveBuilder_OutputType,pos={33,37},size={129,21},bodyWidth=55,proc=WBP_PopMenuProc_WaveType,title="Wave Type"
	PopupMenu popup_WaveBuilder_OutputType,help={"TTL selection results in automatic changes to the set being created in the Wave Builder that cannot be recovered. "}
	PopupMenu popup_WaveBuilder_OutputType,userdata(ResizeControlsInfo)= A"!!,Ch!!#>\"!!#@e!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu popup_WaveBuilder_OutputType,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu popup_WaveBuilder_OutputType,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu popup_WaveBuilder_OutputType,fSize=14
	PopupMenu popup_WaveBuilder_OutputType,mode=1,popvalue="DA",value= #"\"DA;TTL\""
	Button button_WaveBuilder_SaveSet,pos={879,96},size={116,45},proc=WBP_ButtonProc_SaveSet,title="Save Set"
	Button button_WaveBuilder_SaveSet,help={"Saving a set is not required to use the set"}
	Button button_WaveBuilder_SaveSet,userdata(ResizeControlsInfo)= A"!!,Jl^]6^:!!#@L!!#>Bz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_WaveBuilder_SaveSet,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	Button button_WaveBuilder_SaveSet,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_FD00,pos={194,105},size={100,16},disable=1,proc=WBP_SetVarProc_Frequency,title="Freq"
	SetVariable SetVar_WaveBuilder_FD00,userdata(tabnum)=  "4"
	SetVariable SetVar_WaveBuilder_FD00,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_FD00,userdata(ResizeControlsInfo)= A"!!,GR!!#@6!!#@,!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_FD00,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_FD00,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_FD00,value= _NUM:5
	SetVariable SetVar_WaveBuilder_DD00,pos={301,105},size={100,16},disable=1,proc=WBP_SetVarProc_Delta00,title="Delta"
	SetVariable SetVar_WaveBuilder_DD00,userdata(tabnum)=  "4"
	SetVariable SetVar_WaveBuilder_DD00,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_DD00,userdata(ResizeControlsInfo)= A"!!,HQJ,hpa!!#@,!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_DD00,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_DD00,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_DD00,value= _NUM:10
	SetVariable SetVar_WaveBuilder_FD01,pos={194,105},size={100,16},disable=1,proc=WBP_SetVarProc_Frequency,title="Freq"
	SetVariable SetVar_WaveBuilder_FD01,userdata(tabnum)=  "5"
	SetVariable SetVar_WaveBuilder_FD01,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_FD01,userdata(ResizeControlsInfo)= A"!!,GR!!#@6!!#@,!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_FD01,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_FD01,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_FD01,value= _NUM:10
	SetVariable SetVar_WaveBuilder_DD01,pos={301,105},size={100,16},disable=1,proc=WBP_SetVarProc_Delta00,title="Delta"
	SetVariable SetVar_WaveBuilder_DD01,userdata(tabnum)=  "5"
	SetVariable SetVar_WaveBuilder_DD01,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_DD01,userdata(ResizeControlsInfo)= A"!!,HQJ,hpa!!#@,!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_DD01,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_DD01,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_DD01,value= _NUM:0
	SetVariable SetVar_WaveBuilder_OD00,pos={194,81},size={100,16},proc=WBP_SetVarProc_Offset,title="Offset"
	SetVariable SetVar_WaveBuilder_OD00,userdata(tabnum)=  "2"
	SetVariable SetVar_WaveBuilder_OD00,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_OD00,userdata(ResizeControlsInfo)= A"!!,GR!!#?[!!#@,!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_OD00,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_OD00,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_OD00,value= _NUM:0
	SetVariable SetVar_WaveBuilder_DD02,pos={301,81},size={100,16},proc=WBP_SetVarProc_Delta01,title="Delta"
	SetVariable SetVar_WaveBuilder_DD02,userdata(tabnum)=  "2"
	SetVariable SetVar_WaveBuilder_DD02,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_DD02,userdata(ResizeControlsInfo)= A"!!,HQJ,hp1!!#@,!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_DD02,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_DD02,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_DD02,value= _NUM:0
	SetVariable SetVar_WaveBuilder_DD03,pos={301,81},size={100,16},proc=WBP_SetVarProc_Delta01,title="Delta"
	SetVariable SetVar_WaveBuilder_DD03,userdata(tabnum)=  "3"
	SetVariable SetVar_WaveBuilder_DD03,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_DD03,userdata(ResizeControlsInfo)= A"!!,HQJ,hp1!!#@,!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_DD03,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_DD03,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_DD03,value= _NUM:0
	SetVariable SetVar_WaveBuilder_OD01,pos={194,81},size={100,16},proc=WBP_SetVarProc_Offset,title="Offset"
	SetVariable SetVar_WaveBuilder_OD01,userdata(tabnum)=  "3"
	SetVariable SetVar_WaveBuilder_OD01,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_OD01,userdata(ResizeControlsInfo)= A"!!,GR!!#?[!!#@,!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_OD01,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_OD01,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_OD01,value= _NUM:0
	SetVariable SetVar_WaveBuilder_DD04,pos={301,81},size={100,16},proc=WBP_SetVarProc_Delta01,title="Delta"
	SetVariable SetVar_WaveBuilder_DD04,userdata(tabnum)=  "4"
	SetVariable SetVar_WaveBuilder_DD04,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_DD04,userdata(ResizeControlsInfo)= A"!!,HQJ,hp1!!#@,!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_DD04,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_DD04,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_DD04,value= _NUM:0
	SetVariable SetVar_WaveBuilder_OD02,pos={194,81},size={100,16},proc=WBP_SetVarProc_Offset,title="Offset"
	SetVariable SetVar_WaveBuilder_OD02,userdata(tabnum)=  "4"
	SetVariable SetVar_WaveBuilder_OD02,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_OD02,userdata(ResizeControlsInfo)= A"!!,GR!!#?[!!#@,!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_OD02,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_OD02,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_OD02,value= _NUM:0
	SetVariable SetVar_WaveBuilder_DD05,pos={301,82},size={100,16},proc=WBP_SetVarProc_Delta01,title="Delta"
	SetVariable SetVar_WaveBuilder_DD05,userdata(tabnum)=  "5"
	SetVariable SetVar_WaveBuilder_DD05,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_DD05,userdata(ResizeControlsInfo)= A"!!,HQJ,hp3!!#@,!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_DD05,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_DD05,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_DD05,value= _NUM:0
	SetVariable SetVar_WaveBuilder_OD03,pos={194,81},size={100,16},proc=WBP_SetVarProc_Offset,title="Offset"
	SetVariable SetVar_WaveBuilder_OD03,userdata(tabnum)=  "5"
	SetVariable SetVar_WaveBuilder_OD03,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_OD03,userdata(ResizeControlsInfo)= A"!!,GR!!#?[!!#@,!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_OD03,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_OD03,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_OD03,value= _NUM:0
	SetVariable SetVar_WaveBuilder_DD06,pos={300,81},size={100,16},proc=WBP_SetVarProc_Delta01,title="Delta"
	SetVariable SetVar_WaveBuilder_DD06,userdata(tabnum)=  "6"
	SetVariable SetVar_WaveBuilder_DD06,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_DD06,userdata(ResizeControlsInfo)= A"!!,HQ!!#?[!!#@,!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_DD06,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_DD06,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_DD06,value= _NUM:0
	SetVariable SetVar_WaveBuilder_OD04,pos={194,81},size={100,16},proc=WBP_SetVarProc_Offset,title="Offset"
	SetVariable SetVar_WaveBuilder_OD04,userdata(tabnum)=  "6"
	SetVariable SetVar_WaveBuilder_OD04,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_OD04,userdata(ResizeControlsInfo)= A"!!,GR!!#?[!!#@,!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_OD04,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_OD04,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_OD04,value= _NUM:0
	SetVariable SetVar_WaveBuilder_P18,pos={194,81},size={100,16},disable=1,proc=WBP_SetVarProc_UpdateParam,title="Offset"
	SetVariable SetVar_WaveBuilder_P18,userdata(tabnum)=  "7"
	SetVariable SetVar_WaveBuilder_P18,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P18,userdata(ResizeControlsInfo)= A"!!,GR!!#?[!!#@,!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P18,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P18,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P18,value= _NUM:0
	SetVariable SetVar_WaveBuilder_P19,pos={300,81},size={100,16},disable=1,proc=WBP_SetVarProc_UpdateParam,title="Delta"
	SetVariable SetVar_WaveBuilder_P19,userdata(tabnum)=  "7"
	SetVariable SetVar_WaveBuilder_P19,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P19,userdata(ResizeControlsInfo)= A"!!,HQ!!#?[!!#@,!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P19,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P19,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P19,value= _NUM:0
	SetVariable setvar_WaveBuilder_SearchString,pos={541,118},size={212,30},disable=1,proc=WBP_SetVarProc_SetSearchString,title="Search\rstring"
	SetVariable setvar_WaveBuilder_SearchString,help={"Include asterisk where appropriate"}
	SetVariable setvar_WaveBuilder_SearchString,userdata(tabnum)=  "7"
	SetVariable setvar_WaveBuilder_SearchString,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable setvar_WaveBuilder_SearchString,userdata(ResizeControlsInfo)= A"!!,Im5QF.;!!#Ac!!#=Sz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_WaveBuilder_SearchString,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_WaveBuilder_SearchString,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_WaveBuilder_SearchString,value= _STR:""
	PopupMenu popup_WaveBuilder_ListOfWaves,pos={544,88},size={210,26},bodyWidth=175,disable=1,proc=WBP_PopMenuProc_WaveToLoad,title="Wave\rto load"
	PopupMenu popup_WaveBuilder_ListOfWaves,userdata(tabnum)=  "7"
	PopupMenu popup_WaveBuilder_ListOfWaves,userdata(tabcontrol)=  "WBP_WaveType"
	PopupMenu popup_WaveBuilder_ListOfWaves,userdata(ResizeControlsInfo)= A"!!,In!!#?i!!#Aa!!#=3z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu popup_WaveBuilder_ListOfWaves,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu popup_WaveBuilder_ListOfWaves,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu popup_WaveBuilder_ListOfWaves,mode=1,popvalue="- none - ",value= #"\"- none - ;W_coef;W_sigma;W_fitConstants;W_Hist1;\""
	SetVariable SetVar_WaveBuilder_P20,pos={586,32},size={150,30},disable=1,proc=WBP_SetVarProc_UpdateParam,title="Low pass cut \roff frequency"
	SetVariable SetVar_WaveBuilder_P20,help={"Set to 100001 to turn off low pass filter"}
	SetVariable SetVar_WaveBuilder_P20,userdata(tabnum)=  "2"
	SetVariable SetVar_WaveBuilder_P20,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P20,userdata(ResizeControlsInfo)= A"!!,J#J,hn9!!#A%!!#=Sz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P20,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P20,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P20,limits={1,100001,100},value= _NUM:0
	SetVariable SetVar_WaveBuilder_P21,pos={741,32},size={91,16},disable=1,proc=WBP_SetVarProc_UpdateParam,title="Delta"
	SetVariable SetVar_WaveBuilder_P21,userdata(tabnum)=  "2"
	SetVariable SetVar_WaveBuilder_P21,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P21,userdata(ResizeControlsInfo)= A"!!,JJ5QF+N!!#?o!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P21,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P21,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P21,limits={-inf,20000,1},value= _NUM:0
	SetVariable SetVar_WaveBuilder_P22,pos={584,97},size={152,30},disable=1,proc=WBP_SetVarProc_UpdateParam,title="High pass cut \roff frequency"
	SetVariable SetVar_WaveBuilder_P22,help={"Set to zero to turn off high pass filter"}
	SetVariable SetVar_WaveBuilder_P22,userdata(tabnum)=  "2"
	SetVariable SetVar_WaveBuilder_P22,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P22,userdata(ResizeControlsInfo)= A"!!,J#!!#@&!!#A'!!#=Sz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P22,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P22,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P22,limits={0,100000,100},value= _NUM:0
	SetVariable SetVar_WaveBuilder_P23,pos={741,65},size={91,16},disable=1,proc=WBP_SetVarProc_UpdateParam,title="Delta"
	SetVariable SetVar_WaveBuilder_P23,userdata(tabnum)=  "2"
	SetVariable SetVar_WaveBuilder_P23,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P23,userdata(ResizeControlsInfo)= A"!!,JJ5QF-&!!#?o!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P23,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P23,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P23,limits={-inf,99999,1},value= _NUM:0
	SetVariable setvar_WaveBuilder_P11,pos={598,34},size={90,16},disable=1,proc=WBP_SetVarProc_UpdateParam,title="Delta"
	SetVariable setvar_WaveBuilder_P11,userdata(ResizeControlsInfo)= A"!!,J&J,hnA!!#?m!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_WaveBuilder_P11,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_WaveBuilder_P11,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_WaveBuilder_P11,userdata(tabnum)=  "6"
	SetVariable setvar_WaveBuilder_P11,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable setvar_WaveBuilder_P11,limits={-inf,inf,0.1},value= _NUM:0
	SetVariable setvar_WaveBuilder_P13,pos={598,57},size={90,16},disable=1,proc=WBP_SetVarProc_UpdateParam,title="Delta"
	SetVariable setvar_WaveBuilder_P13,userdata(ResizeControlsInfo)= A"!!,J&J,hoH!!#?m!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_WaveBuilder_P13,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_WaveBuilder_P13,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_WaveBuilder_P13,userdata(tabnum)=  "6"
	SetVariable setvar_WaveBuilder_P13,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable setvar_WaveBuilder_P13,value= _NUM:0
	SetVariable setvar_WaveBuilder_P15,pos={598,80},size={90,16},disable=1,proc=WBP_SetVarProc_UpdateParam,title="Delta"
	SetVariable setvar_WaveBuilder_P15,userdata(ResizeControlsInfo)= A"!!,J&J,hp/!!#?m!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_WaveBuilder_P15,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_WaveBuilder_P15,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_WaveBuilder_P15,userdata(tabnum)=  "6"
	SetVariable setvar_WaveBuilder_P15,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable setvar_WaveBuilder_P15,value= _NUM:0
	SetVariable setvar_WaveBuilder_P17,pos={598,103},size={90,16},disable=1,proc=WBP_SetVarProc_UpdateParam,title="Delta"
	SetVariable setvar_WaveBuilder_P17,userdata(ResizeControlsInfo)= A"!!,J&J,hp]!!#?m!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_WaveBuilder_P17,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_WaveBuilder_P17,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_WaveBuilder_P17,userdata(tabnum)=  "6"
	SetVariable setvar_WaveBuilder_P17,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable setvar_WaveBuilder_P17,limits={-inf,inf,0.1},value= _NUM:0
	CheckBox check_SPT_Poisson,pos={413,103},size={68,26},disable=1,proc=WBP_CheckProc,title="Poisson\rdistribution"
	CheckBox check_SPT_Poisson,userdata(ResizeControlsInfo)= A"!!,I4J,hp]!!#?A!!#=3z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_SPT_Poisson,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_SPT_Poisson,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_SPT_Poisson,userdata(tabnum)=  "5"
	CheckBox check_SPT_Poisson,userdata(tabcontrol)=  "WBP_WaveType",value= 1
	SetVariable SetVar_WaveBuilder_P24,pos={194,129},size={100,16},disable=3,proc=WBP_SetVarProc_UpdateParam,title="End Freq"
	SetVariable SetVar_WaveBuilder_P24,userdata(ResizeControlsInfo)= A"!!,GR!!#@e!!#@,!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P24,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P24,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P24,userdata(tabnum)=  "3"
	SetVariable SetVar_WaveBuilder_P24,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P24,limits={0,inf,0.1},value= _NUM:100.1
	SetVariable SetVar_WaveBuilder_P25,pos={301,129},size={100,16},disable=3,proc=WBP_SetVarProc_UpdateParam,title="Delta"
	SetVariable SetVar_WaveBuilder_P25,userdata(ResizeControlsInfo)= A"!!,HQJ,hq;!!#@,!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P25,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P25,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P25,userdata(tabnum)=  "3"
	SetVariable SetVar_WaveBuilder_P25,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P25,value= _NUM:0
	CheckBox check_Sin_Chirp,pos={413,101},size={41,26},disable=1,proc=WBP_CheckProc,title="log\rchirp"
	CheckBox check_Sin_Chirp,userdata(tabnum)=  "3"
	CheckBox check_Sin_Chirp,userdata(tabcontrol)=  "WBP_WaveType"
	CheckBox check_Sin_Chirp,userdata(ResizeControlsInfo)= A"!!,I4J,hpY!!#>2!!#=3z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_Sin_Chirp,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_Sin_Chirp,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_Sin_Chirp,value= 0
	Button button_WaveBuilder_LoadSet,pos={530,442},size={150,23},proc=WBP_ButtonProc_LoadSet,title="Load Set"
	Button button_WaveBuilder_LoadSet,help={"If set isn't removed from list after deleting, a wave from the set must be in use, kill the appropriate graph or table and retry."}
	Button button_WaveBuilder_LoadSet,userdata(ResizeControlsInfo)= A"!!,IjJ,hsm!!#A%!!#<pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_WaveBuilder_LoadSet,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#?(FEDG<zzzzzzzzzzz"
	Button button_WaveBuilder_LoadSet,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P27,pos={741,97},size={91,16},disable=1,proc=WBP_SetVarProc_UpdateParam,title="Delta"
	SetVariable SetVar_WaveBuilder_P27,userdata(tabnum)=  "2"
	SetVariable SetVar_WaveBuilder_P27,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P27,userdata(ResizeControlsInfo)= A"!!,JJ5QF-f!!#?o!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P27,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P27,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P27,limits={-inf,99999,1},value= _NUM:0
	SetVariable SetVar_WaveBuilder_P26,pos={599,65},size={137,30},disable=1,proc=WBP_SetVarProc_UpdateParam,title="High pass  \rcoef No."
	SetVariable SetVar_WaveBuilder_P26,help={"A larger number gives better stop-band rejection. A good number to start with is 101. Values can range between 3 and 32767."}
	SetVariable SetVar_WaveBuilder_P26,userdata(tabnum)=  "2"
	SetVariable SetVar_WaveBuilder_P26,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P26,userdata(ResizeControlsInfo)= A"!!,J&^]6]Q!!#@m!!#=Sz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P26,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P26,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P26,limits={3,32767,50},value= _NUM:550
	SetVariable SetVar_WaveBuilder_P29,pos={741,129},size={91,16},disable=1,proc=WBP_SetVarProc_UpdateParam,title="Delta"
	SetVariable SetVar_WaveBuilder_P29,userdata(tabnum)=  "2"
	SetVariable SetVar_WaveBuilder_P29,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P29,userdata(ResizeControlsInfo)= A"!!,JJ5QF.P!!#?o!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P29,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P29,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P29,limits={-inf,99999,1},value= _NUM:0
	SetVariable SetVar_WaveBuilder_P28,pos={601,129},size={135,30},disable=1,proc=WBP_SetVarProc_UpdateParam,title="Low pass  \rcoef No."
	SetVariable SetVar_WaveBuilder_P28,help={"A larger number gives better stop-band rejection. A good number to start with is 101. Values can range between 3 and 32767."}
	SetVariable SetVar_WaveBuilder_P28,userdata(tabnum)=  "2"
	SetVariable SetVar_WaveBuilder_P28,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P28,userdata(ResizeControlsInfo)= A"!!,J'5QF.P!!#@k!!#=Sz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P28,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P28,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P28,limits={3,32767,50},value= _NUM:500
	PopupMenu popup_WaveBuilder_FolderList,pos={546,60},size={208,26},bodyWidth=175,disable=1,proc=WBP_PopMenuProc_FolderSelect,title="Select\rfolder"
	PopupMenu popup_WaveBuilder_FolderList,userdata(tabnum)=  "7"
	PopupMenu popup_WaveBuilder_FolderList,userdata(tabcontrol)=  "WBP_WaveType"
	PopupMenu popup_WaveBuilder_FolderList,userdata(ResizeControlsInfo)= A"!!,InJ,hoT!!#A_!!#=3z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu popup_WaveBuilder_FolderList,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	PopupMenu popup_WaveBuilder_FolderList,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	PopupMenu popup_WaveBuilder_FolderList,mode=1,popvalue="- none -",value= #"\"- none -; root:;\"+WBP_ReturnFoldersList(\"root:\")"
	GroupBox group_WaveBuilder_FolderPath,pos={515,34},size={269,127},disable=1,title="root:"
	GroupBox group_WaveBuilder_FolderPath,userdata(tabnum)=  "7"
	GroupBox group_WaveBuilder_FolderPath,userdata(tabcontrol)=  "WBP_WaveType"
	GroupBox group_WaveBuilder_FolderPath,userdata(ResizeControlsInfo)= A"!!,If^]6\\,!!#B@J,hq8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	GroupBox group_WaveBuilder_FolderPath,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	GroupBox group_WaveBuilder_FolderPath,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	GroupBox group_WaveBuilder_SetParameters,pos={12,7},size={162,146},title="\\Z16\\f01Set Parmeters"
	GroupBox group_WaveBuilder_SetParameters,userdata(ResizeControlsInfo)= A"!!,AN!!#:B!!#A1!!#A!z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	GroupBox group_WaveBuilder_SetParameters,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	GroupBox group_WaveBuilder_SetParameters,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	GroupBox group_WaveBuilder_SaveSet,pos={873,14},size={130,139},title="\\Z16\\f01Save Set"
	GroupBox group_WaveBuilder_SaveSet,userdata(ResizeControlsInfo)= A"!!,Jk5QF)X!!#@f!!#@oz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	GroupBox group_WaveBuilder_SaveSet,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	GroupBox group_WaveBuilder_SaveSet,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	GroupBox group_WaveBuilder_SaveSet,fStyle=0
	DefineGuide UGH0={FB,-42}
	SetWindow kwTopWin,hook(ResizeControls)=ResizeControls#ResizeControlsHook
	SetWindow kwTopWin,userdata(ResizeControlsInfo)= A"!!*'\"z!!#E95QF1=zzzzzzzzzzzzzzzzzzzzz"
	SetWindow kwTopWin,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzzzzzzzzzzzzzzz"
	SetWindow kwTopWin,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzzzzzzzzz!!!"
	SetWindow kwTopWin,userdata(ResizeControlsGuides)=  "UGH0;"
	SetWindow kwTopWin,userdata(ResizeControlsInfoUGH0)= A":-hTC3`S[@0KW?-:-*T-G%G-*Bl%<kE][6':dmEFF(KAR85E,T>#.mm5tj<o4&A^O8Q88W:-(3f1-8!+8OQ!%3^uFt7o`,K75?nc;FO8U:K'ha8P`)B/Mo4E"
	Display/W=(0,172,671,397)/FG=(,,FR,UGH0)/HOST=# 
	ModifyGraph frameInset=2
	SetWindow kwTopWin,userdata(tabcontrol)=  "WBP_WaveType"
	SetWindow kwTopWin,userdata(ResizeControlsInfo)= A"!!,Ct!!#A/!!#E!5QF0#!!!!\"zzzzzzzzzzzzzzzzzzzz"
	SetWindow kwTopWin,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzzzzzzzzzzzzzzz"
	SetWindow kwTopWin,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzzzzzzzzz!!!"
	RenameWindow #,WaveBuilderGraph
	SetActiveSubwindow ##
EndMacro

Function WBP_SetVarProc_SetNo(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	DFREF saveDFR = GetDataFolderDFR()// creates a data folder reference that is later used to access the folder
	SetDataFolder root:WaveBuilder:Data
	WB_MakeStimSet()
	WB_DisplaySetInPanel()
	SetDataFolder saveDFR
End
	
Function WBP_ButtonProc_DeleteSet(ctrlName) : ButtonControl
	String ctrlName
	String DAorTTL
	SVAR ITCPanelTitleList
	controlinfo /W=wavebuilder popup_WaveBuilder_SetList
	string SetWaveToDelete = s_value
	//getwindow kwTopWin wtitle
	variable i = 0
	
	do
		string panelTitle=stringfromlist(i,ITCPanelTitleList, ";")
		if(stringmatch(SetWaveToDelete,"*DA*")==1)
		DAorTTL="DA"
		else
		DAorTTL="TTL"
		endif
	
		string popupMenuSelectedItemsStart = ITCP_PopupMenuWaveNameList(DAorTTL,0, panelTitle)
		string popupMenuSelectedItemsEnd = ITCP_PopupMenuWaveNameList(DAorTTL,1, panelTitle)
		WBP_DeleteSet()
		WBP_UpdateITCPanelPopUps(panelTitle)
		ITCP_RestorePopupMenuSelection(popupMenuSelectedItemsStart, DAorTTL,0, panelTitle)
		ITCP_RestorePopupMenuSelection(popupMenuSelectedItemsEnd, DAorTTL,1, panelTitle)
		i+=1
	while(i<itemsinlist(ITCPanelTitleList))
	
	controlupdate /W=wavebuilder popup_WaveBuilder_SetList
	PopupMenu popup_WaveBuilder_SetList mode=1
End

Function WBP_SetVarProc_StepCount(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	DFREF saveDFR = GetDataFolderDFR()// creates a data folder reference that is later used to access the folder
	SetDataFolder root:WaveBuilder:Data
	WBP_LowPassDeltaLimits()
	WBP_HighPassDeltaLimits()
	WB_MakeStimSet()
	WB_DisplaySetInPanel()
	SetDataFolder saveDFR
	
End

Function WBP_ButtonProc_AutoScale(ctrlName) : ButtonControl
	String ctrlName
SetAxis/A/w=wavebuilder#wavebuildergraph
End

Function WBP_CheckProc(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	DFREF saveDFR = GetDataFolderDFR()// creates a data folder reference that is later used to access the folder
	SetDataFolder root:WaveBuilder:Data
	//controlinfo 
	if(cmpstr(ctrlName,"check_Sin_Chirp")==0)
		if(checked==1)
		SetVariable SetVar_WaveBuilder_P24 disable=0
		SetVariable SetVar_WaveBuilder_P25 disable=0
		else
		SetVariable SetVar_WaveBuilder_P24 disable=2
		SetVariable SetVar_WaveBuilder_P25 disable=2
		endif
	endif
	WB_MakeStimSet()
	WB_DisplaySetInPanel()
	SetDataFolder saveDFR
End

Function TabTJHook(tca)//This is a function that gets run by ACLight's tab control function every time a tab is selected
	STRUCT WMTabControlAction &tca
	
	DFREF saveDFR = GetDataFolderDFR()// creates a data folder reference that is later used to access the folder
	SetDataFolder root:WaveBuilder:Data
	
	variable tabnum
	wave SegWvType

	tabnum=tca.tab

	controlinfo popup_WaveBuilder_OutputType
	if(cmpstr(s_value,"TTL")==0)
		if(tabnum==1 || tabnum==2|| tabnum==3|| tabnum==4|| tabnum==6)
			SetDataFolder saveDFR
			return 1
		else
			controlinfo setvar_WaveBuilder_SegmentEdit
			SegWvType[v_value]=tabnum
	
			variable ParamWaveType=tabnum
			WB_ParamToPanel(ParamWaveType)

			WB_MakeStimSet()
			WB_DisplaySetInPanel()
			
			SetDataFolder saveDFR

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
	SegWvType[v_value]=tabnum
	
	ParamWaveType=tabnum
	WB_ParamToPanel(ParamWaveType)// passed parameters from appropriate parameter wave to panel
	
	WB_MakeStimSet()
	WB_DisplaySetInPanel()
	SetDataFolder saveDFR

	return 0
	endif
End


//Function/s WBP_SetListForPopUp()
//	DFREF saveDFR = GetDataFolderDFR()// creates a data folder reference that is later used to access the folder
//	SetDataFolder root:WaveBuilder:Data
//	
//	string ListString ="- none -;"+WaveList("*_Set_*DA", ";","" )//+WaveList("1_*TTL_*", ";","" )
//	
//	SetDataFolder saveDFR
//
//	return liststring
//End


Function WBP_ButtonProc_SaveSet(ctrlName) : ButtonControl
	String ctrlName
	variable i = 0
	SVAR ITCPanelTitleList
	string panelTitle
	DFREF saveDFR = GetDataFolderDFR()// creates a data folder reference that is later used to access the folder
	SetDataFolder root:WaveBuilder:Data
	string ListOfTracesOnGraph
	ListOfTracesOnGraph=TraceNameList("WaveBuilder#WaveBuilderGraph", ",",0+1 )
	
	WBP_Transfer1DsTo2D(ListOfTracesOnGraph)//takes the waves displayed in the wavebuilder and makes them into a single wave
	WBP_RemoveAndKillWavesOnGraph("WaveBuilder#WaveBuilderGraph")//removes waves displayed in wave builder
	WBP_MoveWaveTOFolder(WBP_FolderAssignment(), WBP_AssembleBaseName(), 1, "")// moves 2D wave that contains stimulus set to DA or TTL folder
	WBP_SaveSetParam()//Saves set parameters with base name in appropriate ttl of DA folder
	
	SetDataFolder saveDFR

	do
		paneltitle = stringfromlist(i, ITCPanelTitleList, ";")
		WBP_UpdateITCPanelPopUps(panelTitle)
		i+=1
	while (i<itemsinlist(ITCPanelTitleList, ";"))
	
	SetVariable setvar_WaveBuilder_baseName win = wavebuilder, value= _STR:"InsertBaseName"
	controlupdate /W = wavebuilder popup_WaveBuilder_SetList
End


Function WBP_SetVarProc_Frequency(ctrlName,varNum,varStr,varName) : SetVariableControl// setvarproc 5-8 pass data from one setvariable control to another, they also run a version of the other controls procedures
	String ctrlName
	Variable varNum
	String varStr
	String varName
	
	DFREF saveDFR = GetDataFolderDFR()// creates a data folder reference that is later used to access the folder
	SetDataFolder root:WaveBuilder:Data
	
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
	NameOfParamWave="WP"
	
	sprintf cmd, "%s[%d][%d][%d]=%g" nameOfParamWave, ParameterRow, segmentNo, stimulusType,varnum
	execute cmd
			
	WB_MakeStimSet()
	WB_DisplaySetInPanel()
	
	SetDataFolder saveDFR

End

Function WBP_SetVarProc_Delta00(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName

	DFREF saveDFR = GetDataFolderDFR()// creates a data folder reference that is later used to access the folder
	SetDataFolder root:WaveBuilder:Data	
	
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
			
	WB_MakeStimSet()
	WB_DisplaySetInPanel()
	
	SetDataFolder saveDFR

End

Function WBP_SetVarProc_UpdateParam(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	
	DFREF saveDFR = GetDataFolderDFR()// creates a data folder reference that is later used to access the folder
	SetDataFolder root:WaveBuilder:Data
	
	wave WPT
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
	WBP_LowPassDeltaLimits()
	WBP_HighPassDeltaLimits()
	WBP_CutOffCrossOver()
	endif
	
	if(v_value==5)
	SetVariable SetVar_WaveBuilder_P8 limits={0,WBP_ReturnPulseDurationMax(),0.1}
	controlinfo SetVar_WaveBuilder_P8
		if(v_value>WBP_ReturnPulseDurationMax())
		SetVariable SetVar_WaveBuilder_P8 value= _NUM:WBP_ReturnPulseDurationMax()
		endif
	endif
	
	WB_MakeStimSet()
	WB_DisplaySetInPanel()

	SetDataFolder saveDFR

End

Function WBP_LowPassDeltaLimits()
variable LowPassCutOff, StepCount, LowPassDelta, DeltaLimit

	DFREF saveDFR = GetDataFolderDFR()// creates a data folder reference that is later used to access the folder
	SetDataFolder root:WaveBuilder:Data
	
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
	SetDataFolder saveDFR
End

Function WBP_HighPassDeltaLimits()
variable HighPassCutOff, StepCount, HighPassDelta, DeltaLimit

	DFREF saveDFR = GetDataFolderDFR()// creates a data folder reference that is later used to access the folder
	SetDataFolder root:WaveBuilder:Data
	
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
	SetDataFolder saveDFR
End

Function WBP_SetVarProc_Offset(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	
	DFREF saveDFR = GetDataFolderDFR()// creates a data folder reference that is later used to access the folder
	SetDataFolder root:WaveBuilder:Data
	
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
		
	WB_MakeStimSet()
	WB_DisplaySetInPanel()
	
	SetDataFolder saveDFR
End

Function WBP_SetVarProc_Delta01(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	
	DFREF saveDFR = GetDataFolderDFR()// creates a data folder reference that is later used to access the folder
	SetDataFolder root:WaveBuilder:Data
	
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
			
	WB_MakeStimSet()
	WB_DisplaySetInPanel()
	
	SetDataFolder saveDFR
End


Function WBP_ExecuteAdamsTabcontrol(TabToGoTo)
	variable TabToGoTo
	Struct WMTabControlAction tca

	DFREF saveDFR = GetDataFolderDFR()// creates a data folder reference that is later used to access the folder
	SetDataFolder root:WaveBuilder:Data
	
	tca.ctrlName = "WBP_WaveType"	
	tca.win	= "wavebuilder"	
	tca.eventCode =2	
	tca.tab=	TabToGoTo

	Variable returnedValue = ACL_DisplayTab(tca)
	SetDataFolder saveDFR
End

Function WBP_PopMenuProc_WaveType(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	
	DFREF saveDFR = GetDataFolderDFR()// creates a data folder reference that is later used to access the folder
	SetDataFolder root:WaveBuilder:Data
	
	wave SegWvType, WP
if (cmpstr(popstr,"TTL")==0)

	SegWvType=0
	WP[1,6][][]=0
	
	SetVariable SetVar_WaveBuilder_P2 win = wavebuilder, limits={0,1,1}, value= _NUM:0
	WBP_SetVarProc_UpdateParam("SetVar_WaveBuilder_P2",0,"1","")
	SetVariable SetVar_WaveBuilder_P3 win = wavebuilder, disable=2,value= _NUM:0
	WBP_SetVarProc_UpdateParam("SetVar_WaveBuilder_P3",0,"0","")
	SetVariable SetVar_WaveBuilder_P4 win = wavebuilder, disable=2,value= _NUM:0
	WBP_SetVarProc_UpdateParam("SetVar_WaveBuilder_P4",0,"0","")
	SetVariable SetVar_WaveBuilder_P5 win = wavebuilder, disable=2,value= _NUM:0
	WBP_SetVarProc_UpdateParam("SetVar_WaveBuilder_P5",0,"0","")
	
	SetVariable SetVar_WaveBuilder_OD00 win = wavebuilder, disable=2,value= _NUM:0// i need to run the procedure associated to the particular set variable
	SetVariable SetVar_WaveBuilder_OD01 win = wavebuilder, disable=2,value= _NUM:0
	SetVariable SetVar_WaveBuilder_OD02 win = wavebuilder, disable=2,value= _NUM:0
	SetVariable SetVar_WaveBuilder_OD03 win = wavebuilder, disable=2,value= _NUM:0
	SetVariable SetVar_WaveBuilder_OD04 win = wavebuilder, disable=2,value= _NUM:0
	
	SetVariable SetVar_WaveBuilder_DD02 win = wavebuilder, disable=2,value= _NUM:0
	SetVariable SetVar_WaveBuilder_DD03 win = wavebuilder, disable=2,value= _NUM:0
	SetVariable SetVar_WaveBuilder_DD04 win = wavebuilder, disable=2,value= _NUM:0
	SetVariable SetVar_WaveBuilder_DD05 win = wavebuilder, disable=2,value= _NUM:0
	SetVariable SetVar_WaveBuilder_DD06 win = wavebuilder, disable=2,value= _NUM:0
	
	TabControl WBP_WaveType value=0
	WBP_ExecuteAdamsTabcontrol(0)

endif

if (cmpstr(popstr,"DA")==0)
	SetVariable SetVar_WaveBuilder_P2 win = wavebuilder, limits={-inf,inf,1}
	SetVariable SetVar_WaveBuilder_P3 win = wavebuilder, disable=0
	SetVariable SetVar_WaveBuilder_P4 win = wavebuilder, disable=0
	SetVariable SetVar_WaveBuilder_P5 win = wavebuilder, disable=0
	
	SetVariable SetVar_WaveBuilder_OD00 win = wavebuilder, disable=0
	SetVariable SetVar_WaveBuilder_OD01 win = wavebuilder, disable=0
	SetVariable SetVar_WaveBuilder_OD02 win = wavebuilder, disable=0
	SetVariable SetVar_WaveBuilder_OD03 win = wavebuilder, disable=0
	SetVariable SetVar_WaveBuilder_OD04 win = wavebuilder, disable=0
	
	SetVariable SetVar_WaveBuilder_DD02 win = wavebuilder, disable=0
	SetVariable SetVar_WaveBuilder_DD03 win = wavebuilder, disable=0
	SetVariable SetVar_WaveBuilder_DD04 win = wavebuilder, disable=0
	SetVariable SetVar_WaveBuilder_DD05 win = wavebuilder, disable=0
	SetVariable SetVar_WaveBuilder_DD06 win = wavebuilder, disable=0
endif

	SetDataFolder saveDFR

End

Function WBP_SetVarProc_SetSearchString(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	
	DFREF saveDFR = GetDataFolderDFR()// creates a data folder reference that is later used to access the folder
	controlinfo group_WaveBuilder_FolderPath
	string FolderPath = s_value

	
	SetDataFolder FolderPath

	string ListOfWavesInFolder="\"- none - ;" +Wavelist(WBP_SearchString(),";","TEXT:0,MAXCOLS:1")+"\""
	PopupMenu popup_WaveBuilder_ListOfWaves value=#ListOfWavesInFolder

	//PopupMenu popup_WaveBuilder_ListOfWaves value= WBP_RemoveGraphTracesFromList()
	SetDataFolder saveDFR
End

Function/t WBP_SearchString()
	String Str
	controlInfo setvar_WaveBuilder_SearchString
	
		If (strlen(s_value)==0)
			str="*"
			else
			str = s_value
		endif
	
	Return str
End

Function/t WBP_RemoveGraphTracesFromList()
	variable i = 0
	
	DFREF saveDFR = GetDataFolderDFR()// creates a data folder reference that is later used to access the folder
	SetDataFolder root:WaveBuilder:Data
	
	variable ListItems = itemsinlist(tracenamelist("WaveBuilder#WaveBuilderGraph", ";",0+1 ),";")
	string ListString ="- none -;"+Wavelist(WBP_SearchString(),";","TEXT:0,MAXCOLS:1")
	string ListItemToRemove
	
	do
		ListItemToRemove = stringfromlist(i,tracenamelist("WaveBuilder#WaveBuilderGraph", ";",0+1 ),";")
		ListItemToRemove= ListItemToRemove[1,(strlen(ListItemToRemove)-2)]
		ListString=Removefromlist( ListItemToRemove, ListString,";")
		i+=1
	while(i<ListItems)
	SetDataFolder saveDFR
	return ListString
End

Function WBP_PopMenuProc_WaveToLoad(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	
	DFREF saveDFR = GetDataFolderDFR()// creates a data folder reference that is later used to access the folder
	
	controlinfo group_WaveBuilder_FolderPath
	string FolderPath = s_value

	
	SetDataFolder FolderPath
	//SetDataFolder root:WaveBuilder:Data
	
	wave/t WPT = root:WaveBuilder:Data:WPT
		//CUSTOM WAVE CODE
	string cmd
	variable SegmentNo
	
	ControlInfo setvar_WaveBuilder_SegmentEdit
	SegmentNo=v_value
		
		
		If(stringmatch(popStr,"- none -")==0)// checks to make sure "- none -" is not selected as a wave type	
		sprintf cmd, "root:WaveBuilder:Data:WPT[%d][%d]= nameofwave(%s)" 0, SegmentNo, FolderPath+popStr
		execute cmd
		else
		WPT[0][SegmentNo]= ""
		endif
		SetDataFolder saveDFR

	//END OF CUSTOM WAVE CODE
	WB_MakeStimSet()
	WB_DisplaySetInPanel()
	

End

Function WBP_Transfer1DsTo2D(WaveNameList)
	string WaveNameList
	
	DFREF saveDFR = GetDataFolderDFR()// creates a data folder reference that is later used to access the folder
	SetDataFolder root:WaveBuilder:Data
	
	string SetName=WBP_AssembleBaseName()
	string activeWaveName=stringfromlist(0,WaveNameList,",")
	activewavename= activewavename[1,(strlen(ActiveWaveName))-2]
	variable lengthOf1DWaves=numpnts($activeWaveName)
	variable numberOf1DWaves=itemsinlist(WaveNameList,",")+1
	variable i =0
	string cmd
	
	make/o/n=(lengthOf1DWaves,(numberOf1DWaves-1)) $SetName
	
	do
		activeWaveName=stringfromlist(i,WaveNameList,",")
		sprintf cmd, "%s[0,%d][%d]=%s[p]" SetName, lengthOf1DWaves-1, i, activeWaveName
		execute cmd
		activewavename= activewavename[1,(strlen(ActiveWaveName))-2]
		if(i==0)
		WBP_PassNoteOneWaveToAnother($activeWaveName, $SetName)// appends notes from 1d waves to 2d wave
		endif
		i+=1
	while(i<numberOf1DWaves-1)
	
	SetDataFolder saveDFR

End

Function/t WBP_AssembleBaseName()// This function creates a string that is used to name the 2d output wave of the wavebuilder panel. The naming is based on userinput to the wavebuilder panel
	string AssembledBaseName=""//"root:StimulusSets:"
	
	controlinfo setvar_WaveBuilder_baseName
	AssembledBaseName+=s_value[0,15]
	controlinfo popup_WaveBuilder_OutputType
	AssembledBaseName+="_"+s_value+"_"
	controlinfo setvar_WaveBuilder_SetNumber
	AssembledBaseName+=num2str(v_value)
	
	return AssembledBaseName
End

Function/t WBP_FolderAssignment()// returns a folder path based on they wave type ie. TTL or DA - this is used to store the actual sets in the correct folders
	string FolderLocationString="root:WaveBuilder:SavedStimulusSets:"
	controlinfo popup_WaveBuilder_OutputType
	FolderLocationString+=s_value
	FolderLocationString+=":"
	return FolderLocationString
End

Function/t WBP_WPFolderAssignment()// returns a folder path based on they wave type ie. TTL or DA - this is used to store the set parameters in the correct folders
	string FolderLocationString="root:WaveBuilder:SavedStimulusSetParameters:"
	controlinfo popup_WaveBuilder_OutputType
	FolderLocationString+=s_value
	FolderLocationString+=":"
	return FolderLocationString
End

Function WBP_RemoveAndKillWavesOnGraph(GraphName)
	string GraphName
	variable i=0
	
	DFREF saveDFR = GetDataFolderDFR()// creates a data folder reference that is later used to access the folder
	SetDataFolder root:WaveBuilder:Data
	
	string cmd, WaveNameFromList
	string ListOfTracesOnGraph=TraceNameList(GraphName, ";",0+1)
	string Tracename
	variable NoOfTracesOnGraph = itemsinlist(ListOfTracesOnGraph,";")
	if(NoOfTracesOnGraph>0)
		do
			TraceName = "\"#0\""
			sprintf cmd, "removefromgraph/w=%s $%s" GraphName, TraceName
			execute cmd
			Tracename=stringfromlist(i, ListOfTracesOnGraph,";")
			Tracename=Tracename[1,(strlen(Tracename))-2]
			Killwaves  $Tracename
			i+=1
		while(i<NoOfTracesOnGraph)
	endif
	
	SetDataFolder saveDFR

End


string myString = "root:foo1:foo2:waveName"
whoops..make that
Make $myString
WAVE myWave = $myString


DFREF saveDFR = GetDataFolderDFR()// creates a data folder reference that is later used to access the folder
SetDataFolder root:someFolder
String listOfWaves = WaveList("*", ";", "")
SetDataFolder saveDFR


//if you don't create a wave reference, when you use a wave name that wave must either be in the current DF or you must provide the full path to the wave
//and in either of those cases, Igor has to parse the name and look at all waves in the data folder to find the one you want

Function WBP_MoveWaveTOFolder(FolderPath, NameOfWaveToBeMoved, Kill, BaseName)// This will fail if the NameOfWaveToBeMoved is already in use by a non-wave in the target folder
	string FolderPath, NameOfWaveToBeMoved, BaseName//Folder Path ex. root:FolderName:subFolderName:
	variable Kill
	string NameOfWaveWithFolderPath=FolderPath+NameOfWaveToBeMoved+BaseName
	duplicate/o $NameOfWaveToBeMoved $NameOfWaveWithFolderPath
	if(kill==1)
	killwaves $NameOfWaveToBeMoved
	endif
End
	
	DFREF saveDFR = GetDataFolderDFR()// creates a data folder reference that is later used to access the folder
	SetDataFolder root:WaveBuilder:Data
	SetDataFolder saveDFR
	
Function WBP_PassNoteOneWaveToAnother(WaveNoteSource, WaveNoteSink)
	wave WaveNoteSource, WaveNoteSink
	note WaveNoteSink, note(WaveNoteSource)
End

Function WBP_SaveSetParam()
	Wave SegWvType
	controlinfo SetVar_WaveBuilder_NoOfSegments
	SegWvType[100]=v_value// stores the total number of segments for a set in the penultimate cell of the wave that stores the segment type for each segment
	controlinfo SetVar_WaveBuilder_StepCount
	SegWvType[101]=v_value// stores the total number or steps for a set in the last cell of the wave that stores the segment type for each segment
	WBP_MoveWaveTOFolder( WBP_WPFolderAssignment(), "SegWvType", 0, "_"+WBP_AssembleBaseName())
	WBP_MoveWaveTOFolder( WBP_WPFolderAssignment(), "WP", 0, "_"+WBP_AssembleBaseName())
	WBP_MoveWaveTOFolder( WBP_WPFolderAssignment(), "WPT", 0, "_"+WBP_AssembleBaseName())
End

Function/t WBP_ReturnListSavedSets(SetType)
	string SetType
	string FolderPath="root:WaveBuilder:SavedStimulusSets:"+SetType
	DFREF saveDFR = GetDataFolderDFR()// creates a data folder reference that is later used to access the folder
	SetDataFolder $FolderPath
	string TTLSetList = wavelist("*",";","")
	SetDataFolder saveDFR
	return TTLSetList
end

Function WBP_LoadSet()
	string SetName
	string FolderPath, WPName, WPTName, SegWvTypeName
	
	controlinfo popup_WaveBuilder_SetList
	SetName=s_value
	
	WPName="WP_"+SetName
	WPTName="WPT_"+SetName
	SegWvTypeName="SegWvType_"+SetName
	
	if(stringmatch(SetName,"- none -") == 0)
		If(stringmatch(SetName, "*TTL*")==1)// are you loading a DA or TTL set?
			PopupMenu popup_WaveBuilder_OutputType win = wavebuilder, mode=2
			WBP_PopMenuProc_WaveType("popup_WaveBuilder_OutputType",2,"TTL")
			FolderPath="root:WaveBuilder:SavedStimulusSetParameters:TTL"
			DFREF saveDFR = GetDataFolderDFR()// creates a data folder reference that is later used to access the folder
			SetDataFolder $FolderPath
			duplicate/o $WPName, $"root:WaveBuilder:Data:WP"
			duplicate/o $WPTName, $"root:WaveBuilder:Data:WPT"
			duplicate/o $SegWvTypeName, $"root:WaveBuilder:Data:SegWvType"
	
		else
			PopupMenu popup_WaveBuilder_OutputType win = wavebuilder, mode=1
			WBP_PopMenuProc_WaveType("popup_WaveBuilder_OutputType",1,"DA")
			FolderPath="root:WaveBuilder:SavedStimulusSetParameters:DA"
			DFREF saveDFR = GetDataFolderDFR()// creates a data folder reference that is later used to access the folder
			SetDataFolder $FolderPath
			duplicate/o $WPName, $"root:WaveBuilder:Data:WP"
			duplicate/o $WPTName, $"root:WaveBuilder:Data:WPT"
			duplicate/o $SegWvTypeName, $"root:WaveBuilder:Data:SegWvType"
			
		endif
		
			wave LocalWave=root:WaveBuilder:Data:SegWvType
			SetVariable SetVar_WaveBuilder_NoOfSegments value= _NUM:LocalWave[100]
			SetVariable SetVar_WaveBuilder_StepCount value= _NUM:LocalWave[101]
			SetVariable setvar_WaveBuilder_SegmentEdit value= _NUM:0
			TabControl WBP_WaveType value=LocalWave[0]
			WB_ParamToPanel(LocalWave[0])
			WBP_SetVarProc_TotEpoch("setvar_wavebuilder_noofsegments",LocalWave[100],num2str(LocalWave[100]),"")
			SetDataFolder saveDFR
	endif
End

Function WBP_DeleteSet()
string SetName
	string FolderPath, WPName, WPTName, SegWvTypeName
	DFREF saveDFR = GetDataFolderDFR()// creates a data folder reference that is later used to access the folder

	controlinfo popup_WaveBuilder_SetList
	SetName=s_value
	
	WPName="WP_"+SetName
	WPTName="WPT_"+SetName
	SegWvTypeName="SegWvType_"+SetName

	if(stringmatch(SetName,"- none -") == 0)	// makes sure that a set is selected
		If(stringmatch(SetName, "*TTL*")==1)// are you deleting a DA or TTL set?
			FolderPath="root:WaveBuilder:SavedStimulusSetParameters:TTL"
			SetDataFolder $FolderPath
			Killwaves /F /Z $WPName, $WPTName, $SegWvTypeName
			FolderPath="root:WaveBuilder:SavedStimulusSets:TTL"
			SetDataFolder $FolderPath
			Killwaves /F /Z $SetName
			
		else
			FolderPath="root:WaveBuilder:SavedStimulusSetParameters:DA"
			SetDataFolder $FolderPath
			Killwaves /F /Z $WPName, $WPTName, $SegWvTypeName
			FolderPath="root:WaveBuilder:SavedStimulusSets:DA"
			SetDataFolder $FolderPath
			Killwaves /F /Z $SetName
		endif
	endif
	SetDataFolder saveDFR
End

Function WBP_SetVarProc_TotEpoch(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName

	DFREF saveDFR = GetDataFolderDFR()// creates a data folder reference that is later used to access the folder
	SetDataFolder root:WaveBuilder:Data

	wave SegWvType

	variable SegmentNo, SegmentToEdit
	controlinfo SetVar_WaveBuilder_NoOfSegments
	SegmentNo=v_value
	controlinfo Setvar_WaveBuilder_SegmentEdit
	SegmentToEdit=v_value
	
	if(SegmentNo<=SegmentToEdit)// This prevents the segment to edit from being larger than the max number of segements
	SetVariable setvar_WaveBuilder_SegmentEdit value=_num:SegmentNo-1
	
		TabControl WBP_WaveType value=SegWvType[SegmentNo-1]// this selects the correct tab based on changes to the segment to edit value
		WBP_ExecuteAdamsTabcontrol(SegWvType[SegmentNo-1])
	endif
	
	WB_MakeStimSet()
	WB_DisplaySetInPanel()
	
	SetDataFolder saveDFR

End

Function WBP_SetVarProc_EpochToEdit(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	
	DFREF saveDFR = GetDataFolderDFR()// creates a data folder reference that is later used to access the folder
	SetDataFolder root:WaveBuilder:Data
	
	controlinfo SetVar_WaveBuilder_NoOfSegments
	SetVariable setvar_WaveBuilder_SegmentEdit ,limits={0,v_value-1,1}// sets the maximum segment to edit number to be equal to the numbeer of segments specified
	
	wave SegWvType
	variable StimulusType
	StimulusType=SegWvType[varNum]//selects the appropriate tab based on the data in the SegWvType wave
	TabControl WBP_WaveType value=StimulusType
	WBP_ExecuteAdamsTabcontrol(StimulusType)

	
	variable ParamWaveType=StimulusType
	WB_ParamToPanel(ParamWaveType)
	
	WB_MakeStimSet()
	WB_DisplaySetInPanel()
	
	SetDataFolder saveDFR
End

Function WBP_ButtonProc_LoadSet(ctrlName) : ButtonControl
	String ctrlName
	 WBP_LoadSet()
End

Function WBP_CutOffCrossOver()
	variable HighPassCutOff, LowPassCutOff
	controlinfo SetVar_WaveBuilder_P20//Low pass cut off frequency
	LowPassCutOff=v_value
	
	controlinfo SetVar_WaveBuilder_P22//High pass cut off frequency
	HighPassCutOff=v_value
	
	If(HighPassCutOff>=LowPassCutOff)
	SetVariable SetVar_WaveBuilder_P20 value= _NUM:HighPassCutOff+1
	endif
	
	If(LowPassCutOff<=HighPassCutOff)
	SetVariable SetVar_WaveBuilder_P22 value= _NUM:LowPassCutOff-1
	endif
End

Function WBP_ReturnPulseDurationMax()//checks to see if the pulse duration in square pulse stimulus trains is too long
	variable MaxPulseDur, PulseDuration, Frequency,Duration,MinPulseIntTotDuration
	
	controlinfo SetVar_WaveBuilder_P0//Duration
	Duration=v_value
	controlinfo SetVar_WaveBuilder_FD01//Frequency
	Frequency=v_value
	controlinfo SetVar_WaveBuilder_P8//Pulse Duration
	PulseDuration=V_value
	
	MinPulseIntTotDuration=((duration/1000)*(Frequency-1))*0.01
	Duration-=MinPulseIntTotDuration
	MaxPulseDur=((duration/1000)/Frequency)
	return (MaxPulseDur*1000)
End

Function/t WBP_ReturnFoldersList(ParentFolderPath)
	string ParentFolderPath
	string FolderNameList =""
	string FolderName =""
	DFREF DataFolder = $ParentFolderPath
	variable i = 0
	
	do
		FolderName = GetIndexedObjNameDFR(DataFolder, 4, i)
		if (strlen(FolderName)==0)
			break
		endif
		FolderNameList+=FolderName+";"
		i+=1
	while(1)
	
	return FolderNameList
End


Function WBP_PopMenuProc_FolderSelect(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	
	string FolderPath
	string cmd
	string value 
	string PopMenuSubProc
	string ListOfWavesInFolder
	if (popNum != 1)
		if (cmpstr(" root:",popstr) !=0 )
			controlinfo group_WaveBuilder_FolderPath
			
			FolderPath = s_value + popstr
			//FolderPath = "root:" + popstr + ":"
		else
			//print "here"
			FolderPath="root:"
		endif
	
	PopMenuSubProc="\"- none -; root:;\"+WBP_ReturnFoldersList(\""+ FolderPath +"\")"
	PopupMenu popup_WaveBuilder_FolderList value= #PopMenuSubProc
	setdatafolder FolderPath
	GroupBox group_WaveBuilder_FolderPath title=getdatafolder(1)
	else
	GroupBox group_WaveBuilder_FolderPath title=getdatafolder(1)
	endif

	PopupMenu popup_WaveBuilder_FolderList mode=1
	PopupMenu popup_WaveBuilder_ListOfWaves mode=1
	ListOfWavesInFolder="\"- none - ;" + Wavelist(WBP_SearchString(),";","TEXT:0,MAXCOLS:1")+"\""
	PopupMenu popup_WaveBuilder_ListOfWaves value=#ListOfWavesInFolder
	controlupdate /A /W = wavebuilder 

	setdatafolder root:
End

Function WBP_UpdateITCPanelPopUps(panelTitle)// Used after a new set has been saved to the DA or TTL folder. It repopulates the popup menus in the ITC control Panel to reflect the new waves
	string panelTitle
	string ctrlName0, ctrlName1, WB_WaveType, ListOfWavesInFolder,ctrlName0d, ctrlName1d, ListOfItemsSelectedInPopup, DAorTTL
	string ListOfWaves
	variable NoOfControls, i
	controlinfo /W =waveBuilder popup_WaveBuilder_OutputType
	WB_WaveType=s_value
	
	if(stringmatch(WB_WaveType,"DA")==1)//if statement determines if the set being saved is a DA or TTL
	ctrlName0="Wave_DA_"
	ctrlName1="Popup_DA_IndexEnd_"
	NoOfControls = TotNoOfControlType("Wave", "DA", panelTitle)
	setDataFolder root:waveBuilder:savedStimulusSets:DA
	ListOfWavesInFolder="\"- none -;TestPulse;\"" +"+"+"\""+ Wavelist("*DA*",";","")+"\""
	ListOfWaves = Wavelist("*DA*",";","")
	DAorTTL="DA"
	else
	ctrlName0="Wave_TTL_"
	ctrlName1="Popup_TTL_IndexEnd_"
	NoOfControls = TotNoOfControlType("Wave", "TTL", panelTitle)
	setDataFolder root:waveBuilder:savedStimulusSets:TTL
	ListOfWavesInFolder="\"- none -;TestPulse;\"" +"+"+"\""+ Wavelist("*TTL*",";","")+"\""
	ListOfWaves = Wavelist("*TTL*",";","")
	DAorTTL="TTL"
	endif

	do
		ctrlName0d=ctrlName0
		ctrlName1d=ctrlName1
		if(i<10)// allows for more than 10 controls but no more than 20
		ctrlName0d+="0"+num2str(i)
		ctrlName1d+="0"+num2str(i)
		else
		ctrlName0d+=num2str(i)
		ctrlName1d+=num2str(i)
		endif
	PopupMenu  $ctrlName0d win=$panelTitle, value=#ListOfWavesInFolder, userdata(MenuExp) = ListOfWaves
	controlupdate/w=$panelTitle $ctrlname0d
	PopupMenu  $ctrlName1d win=$panelTitle, value=#ListOfWavesInFolder, userdata(MenuExp) = ListOfWaves
	controlupdate/w=$panelTitle $ctrlname1d

	i+=1
	while(i<noOfControls)
	setdatafolder root:
End