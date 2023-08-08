#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_IDM
#endif

Window IDM_Headstage_Panel() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel/K=1/W=(490,960,726,1225) as "InputPanelForHeadstages"
	Button button_continue,pos={22.00,227.00},size={92.00,20.00},proc=ID_ButtonProc
	Button button_continue,title="Continue"
	Button button_continue,userdata(ResizeControlsInfo)= A"!!,Bi!!#Ar!!#?q!!#<Xz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_continue,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button button_continue,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	Button button_cancel,pos={125.00,227.00},size={92.00,20.00},proc=ID_ButtonProc
	Button button_cancel,title="Cancel"
	Button button_cancel,userdata(ResizeControlsInfo)= A"!!,F_!!#Ar!!#?q!!#<Xz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_cancel,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button button_cancel,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_HS0,pos={78.00,28.00},size={85.00,18.00},bodyWidth=60,proc=ID_SetVarProc
	SetVariable setvar_HS0,title="HS0",userdata(index)=  "0"
	SetVariable setvar_HS0,userdata(ResizeControlsInfo)= A"!!,EV!!#=C!!#?c!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_HS0,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_HS0,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_HS0,value= _NUM:0
	SetVariable setvar_HS1,pos={78.00,50.00},size={85.00,18.00},bodyWidth=60,proc=ID_SetVarProc
	SetVariable setvar_HS1,title="HS1",userdata(index)=  "1"
	SetVariable setvar_HS1,userdata(ResizeControlsInfo)= A"!!,EV!!#>V!!#?c!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_HS1,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_HS1,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_HS1,value= _NUM:0
	SetVariable setvar_HS2,pos={78.00,71.00},size={85.00,18.00},bodyWidth=60,proc=ID_SetVarProc
	SetVariable setvar_HS2,title="HS2",userdata(index)=  "2"
	SetVariable setvar_HS2,userdata(ResizeControlsInfo)= A"!!,EV!!#?G!!#?c!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_HS2,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_HS2,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_HS2,value= _NUM:0
	SetVariable setvar_HS3,pos={78.00,92.00},size={85.00,18.00},bodyWidth=60,proc=ID_SetVarProc
	SetVariable setvar_HS3,title="HS3",userdata(index)=  "3"
	SetVariable setvar_HS3,userdata(ResizeControlsInfo)= A"!!,EV!!#?q!!#?c!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_HS3,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_HS3,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_HS3,value= _NUM:0
	SetVariable setvar_HS4,pos={78.00,114.00},size={85.00,18.00},bodyWidth=60,proc=ID_SetVarProc
	SetVariable setvar_HS4,title="HS4",userdata(index)=  "4"
	SetVariable setvar_HS4,userdata(ResizeControlsInfo)= A"!!,EV!!#@H!!#?c!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_HS4,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_HS4,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_HS4,value= _NUM:0
	SetVariable setvar_HS5,pos={78.00,135.00},size={85.00,18.00},bodyWidth=60,proc=ID_SetVarProc
	SetVariable setvar_HS5,title="HS5",userdata(index)=  "5"
	SetVariable setvar_HS5,userdata(ResizeControlsInfo)= A"!!,EV!!#@k!!#?c!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_HS5,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_HS5,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_HS5,value= _NUM:0
	SetVariable setvar_HS6,pos={78.00,157.00},size={85.00,18.00},bodyWidth=60,proc=ID_SetVarProc
	SetVariable setvar_HS6,title="HS6",userdata(index)=  "6"
	SetVariable setvar_HS6,userdata(ResizeControlsInfo)= A"!!,EV!!#A,!!#?c!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_HS6,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_HS6,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_HS6,value= _NUM:0
	SetVariable setvar_HS7,pos={78.00,178.00},size={85.00,18.00},bodyWidth=60,proc=ID_SetVarProc
	SetVariable setvar_HS7,title="HS7",userdata(index)=  "7"
	SetVariable setvar_HS7,userdata(ResizeControlsInfo)= A"!!,EV!!#AA!!#?c!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_HS7,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_HS7,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_HS7,value= _NUM:0
	SetVariable setvar_INDEP,pos={66.00,199.00},size={97.00,18.00},bodyWidth=60,proc=ID_SetVarProc
	SetVariable setvar_INDEP,title="INDEP",userdata(index)=  "8"
	SetVariable setvar_INDEP,userdata(ResizeControlsInfo)= A"!!,E>!!#AV!!#@&!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_INDEP,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_INDEP,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_INDEP,value= _NUM:0
	SetWindow kwTopWin,hook(ResizeControls)=ResizeControls#ResizeControlsHook
	SetWindow kwTopWin,userdata(ResizeControlsInfo)= A"!!*'\"z!!#B&!!#B>J,fQLzzzzzzzzzzzzzzzzzzzz"
	SetWindow kwTopWin,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzzzzzzzzzzzzzzz"
	SetWindow kwTopWin,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzzzzzzzzz!!!"
	Execute/Q/Z "SetWindow kwTopWin sizeLimit={177,198.75,inf,inf}" // sizeLimit requires Igor 7 or later
EndMacro

Window IDM_Popup_Panel() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /K=1 /W=(490,960,735,1066) as "InputPanelForPopupEntries"
	SetDrawLayer UserBack
	Button button_continue,pos={32.00,75.00},size={92.00,20.00},proc=ID_ButtonProc
	Button button_continue,title="Continue"
	Button button_continue,userdata(ResizeControlsInfo)=A"!!,Cd!!#?O!!#?q!!#<Xz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_continue,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button button_continue,userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	Button button_cancel,pos={135.00,75.00},size={92.00,20.00},proc=ID_ButtonProc
	Button button_cancel,title="Cancel"
	Button button_cancel,userdata(ResizeControlsInfo)=A"!!,Fl!!#?O!!#?q!!#<Xz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_cancel,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button button_cancel,userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu popup0,pos={68.00,37.00},size={120.00,19.00},bodyWidth=120,proc=ID_PopMenuProc
	PopupMenu popup0,userdata(ResizeControlsInfo)=A"!!,EB!!#>\"!!#@T!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu popup0,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu popup0,userdata(ResizeControlsInfo)+=A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetWindow kwTopWin,userdata(ResizeControlsInfo)=A"!!*'\"z!!#B7!!#A!zzzzzzzzzzzzzzzzzzzzz"
	SetWindow kwTopWin,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzzzzzzzzzzzzzzz"
	SetWindow kwTopWin,userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzzzzzzzzz!!!"
	SetWindow kwTopWin,userdata(ResizeControlsHookStash)= "ResizeControls#ResizeControlsHook"
EndMacro
