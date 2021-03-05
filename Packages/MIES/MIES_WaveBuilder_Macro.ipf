#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_WBPM
#endif

/// @file MIES_WaveBuilder_Macro.ipf
/// @brief __WBPM__ WaveBuilder panel macro

Window WaveBuilder() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /K=1 /W=(126,813,1158,1360)
	SetDrawLayer UserBack
	SetDrawEnv fname= "MS Sans Serif",fsize= 16,fstyle= 1
	DrawText 186,27,"Sweep Parameters"
	SetDrawEnv fname= "MS Sans Serif",fsize= 16,fstyle= 1
	DrawText 32,25,"Set Parameters"
	SetDrawEnv fname= "MS Sans Serif",fsize= 16,fstyle= 1
	DrawText 618,25,"Epoch Parameters"
	GroupBox group_sweep_params,pos={185.00,41.00},size={159.00,77.00}
	GroupBox group_sweep_params,userdata(ResizeControlsInfo)= A"!!,GI!!#>2!!#A.!!#?Sz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	GroupBox group_sweep_params,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	GroupBox group_sweep_params,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	TabControl WBP_WaveType,pos={355.00,29.00},size={680.00,210.00},proc=ACL_DisplayTab
	TabControl WBP_WaveType,userdata(currenttab)=  "0"
	TabControl WBP_WaveType,userdata(initialhook)=  "WBP_InitialTabHook"
	TabControl WBP_WaveType,userdata(finalhook)=  "WBP_FinalTabHook"
	TabControl WBP_WaveType,userdata(ResizeControlsInfo)= A"!!,HlJ,hn!!!#D:!!#Aaz!!#](Aon\"Qzzzzzzzzzzzzzz!!#o2B4uAezz"
	TabControl WBP_WaveType,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	TabControl WBP_WaveType,userdata(ResizeControlsInfo) += A"zzz!!#N3Bk1ct<C]S7zzzzzzzzzzzzz!!!"
	TabControl WBP_WaveType,tabLabel(0)="Square pulse",tabLabel(1)="Ramp"
	TabControl WBP_WaveType,tabLabel(2)="Noise",tabLabel(3)="Sin"
	TabControl WBP_WaveType,tabLabel(4)="Saw tooth",tabLabel(5)="Pulse train"
	TabControl WBP_WaveType,tabLabel(6)="PSC",tabLabel(7)="Load"
	TabControl WBP_WaveType,tabLabel(8)="Combine",value= 0
	SetVariable SetVar_WB_NumEpochs_S100,pos={30.00,66.00},size={124.00,22.00},proc=WBP_SetVarProc_UpdateParam,title="Total Epochs"
	SetVariable SetVar_WB_NumEpochs_S100,help={"Number of consecutive epochs in a sweep"}
	SetVariable SetVar_WB_NumEpochs_S100,userdata(ResizeControlsInfo)= A"!!,CT!!#?=!!#@\\!!#<hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WB_NumEpochs_S100,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WB_NumEpochs_S100,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WB_NumEpochs_S100,fSize=14,limits={1,100,1},value= _NUM:1
	SetVariable SetVar_WaveBuilder_P0,pos={365.00,52.00},size={100.00,18.00},proc=WBP_SetVarProc_UpdateParam,title="Duration"
	SetVariable SetVar_WaveBuilder_P0,help={"Duration (ms) of the epoch being edited."}
	SetVariable SetVar_WaveBuilder_P0,userdata(ResizeControlsInfo)= A"!!,HqJ,ho4!!#@,!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P0,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P0,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P0,limits={0,inf,1},value= _NUM:0
	SetVariable SetVar_WaveBuilder_P1,pos={471.00,52.00},size={100.00,18.00},proc=WBP_SetVarProc_UpdateParam,title="Delta"
	SetVariable SetVar_WaveBuilder_P1,help={"Sweep to sweep duration delta."}
	SetVariable SetVar_WaveBuilder_P1,userdata(ResizeControlsInfo)= A"!!,IQJ,ho4!!#@,!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P1,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P1,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P1,value= _NUM:0
	SetVariable SetVar_WB_SweepCount_S101,pos={27.00,90.00},size={127.00,22.00},proc=WBP_SetVarProc_UpdateParam,title="Total Sweeps"
	SetVariable SetVar_WB_SweepCount_S101,help={"Number of sweeps in a stimulus set."}
	SetVariable SetVar_WB_SweepCount_S101,userdata(ResizeControlsInfo)= A"!!,C<!!#?m!!#@b!!#<hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WB_SweepCount_S101,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WB_SweepCount_S101,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WB_SweepCount_S101,fSize=14,limits={1,99,1},value= _NUM:1
	SetVariable setvar_WaveBuilder_P10,pos={364.00,124.00},size={100.00,18.00},disable=1,proc=WBP_SetVarProc_UpdateParam,title="Tau Rise"
	SetVariable setvar_WaveBuilder_P10,help={"PSC exponential rise time constant (ms)"}
	SetVariable setvar_WaveBuilder_P10,userdata(tabnum)=  "6"
	SetVariable setvar_WaveBuilder_P10,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable setvar_WaveBuilder_P10,userdata(ResizeControlsInfo)= A"!!,Hq!!#@\\!!#@,!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_WaveBuilder_P10,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_WaveBuilder_P10,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_WaveBuilder_P10,value= _NUM:0
	SetVariable setvar_WaveBuilder_P12,pos={364.00,146.00},size={100.00,18.00},disable=1,proc=WBP_SetVarProc_UpdateParam,title="Tau Decay 1"
	SetVariable setvar_WaveBuilder_P12,help={"PSC exponential decay time constant. One of Two."}
	SetVariable setvar_WaveBuilder_P12,userdata(tabnum)=  "6"
	SetVariable setvar_WaveBuilder_P12,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable setvar_WaveBuilder_P12,userdata(ResizeControlsInfo)= A"!!,Hq!!#A!!!#@,!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_WaveBuilder_P12,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_WaveBuilder_P12,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_WaveBuilder_P12,value= _NUM:0
	SetVariable setvar_WaveBuilder_P14,pos={364.00,170.00},size={100.00,18.00},disable=1,proc=WBP_SetVarProc_UpdateParam,title="Tau Decay 2"
	SetVariable setvar_WaveBuilder_P14,help={"PSC exponential decay time constant. Two of Two."}
	SetVariable setvar_WaveBuilder_P14,userdata(tabnum)=  "6"
	SetVariable setvar_WaveBuilder_P14,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable setvar_WaveBuilder_P14,userdata(ResizeControlsInfo)= A"!!,Hq!!#A9!!#@,!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_WaveBuilder_P14,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_WaveBuilder_P14,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_WaveBuilder_P14,value= _NUM:0
	SetVariable setvar_WaveBuilder_P16,pos={364.00,193.00},size={100.00,18.00},disable=1,proc=WBP_SetVarProc_UpdateParam,title="Tau 2 weight"
	SetVariable setvar_WaveBuilder_P16,help={"PSC ratio of decay time constants"}
	SetVariable setvar_WaveBuilder_P16,userdata(tabnum)=  "6"
	SetVariable setvar_WaveBuilder_P16,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable setvar_WaveBuilder_P16,userdata(ResizeControlsInfo)= A"!!,Hq!!#AP!!#@,!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_WaveBuilder_P16,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_WaveBuilder_P16,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_WaveBuilder_P16,limits={0,1,0.1},value= _NUM:0
	SetVariable setvar_WaveBuilder_P17,pos={471.00,193.00},size={100.00,18.00},disable=1,proc=WBP_SetVarProc_UpdateParam,title="Delta"
	SetVariable setvar_WaveBuilder_P17,help={"PSC ratio of decay time constants sweep to sweep delta"}
	SetVariable setvar_WaveBuilder_P17,userdata(ResizeControlsInfo)= A"!!,IQJ,hr&!!#@,!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_WaveBuilder_P17,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_WaveBuilder_P17,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_WaveBuilder_P17,userdata(tabnum)=  "6"
	SetVariable setvar_WaveBuilder_P17,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable setvar_WaveBuilder_P17,limits={-inf,inf,0.1},value= _NUM:0
	SetVariable setvar_WaveBuilder_P15,pos={471.00,170.00},size={100.00,18.00},disable=1,proc=WBP_SetVarProc_UpdateParam,title="Delta"
	SetVariable setvar_WaveBuilder_P15,help={"PSC exponential decay time constant sweep to sweep delta. Two of Two."}
	SetVariable setvar_WaveBuilder_P15,userdata(ResizeControlsInfo)= A"!!,IQJ,hqd!!#@,!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_WaveBuilder_P15,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_WaveBuilder_P15,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_WaveBuilder_P15,userdata(tabnum)=  "6"
	SetVariable setvar_WaveBuilder_P15,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable setvar_WaveBuilder_P15,value= _NUM:0
	SetVariable setvar_WaveBuilder_P13,pos={471.00,147.00},size={100.00,18.00},disable=1,proc=WBP_SetVarProc_UpdateParam,title="Delta"
	SetVariable setvar_WaveBuilder_P13,help={"PSC exponential decay time constant sweep to sweep delta. One of Two."}
	SetVariable setvar_WaveBuilder_P13,userdata(ResizeControlsInfo)= A"!!,IQJ,hqM!!#@,!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_WaveBuilder_P13,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_WaveBuilder_P13,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_WaveBuilder_P13,userdata(tabnum)=  "6"
	SetVariable setvar_WaveBuilder_P13,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable setvar_WaveBuilder_P13,value= _NUM:0
	SetVariable setvar_WaveBuilder_P11,pos={471.00,124.00},size={100.00,18.00},disable=1,proc=WBP_SetVarProc_UpdateParam,title="Delta"
	SetVariable setvar_WaveBuilder_P11,help={"PSC exponential rise time constant sweep to sweep delta"}
	SetVariable setvar_WaveBuilder_P11,userdata(ResizeControlsInfo)= A"!!,IQJ,hq2!!#@,!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_WaveBuilder_P11,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_WaveBuilder_P11,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_WaveBuilder_P11,userdata(tabnum)=  "6"
	SetVariable setvar_WaveBuilder_P11,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable setvar_WaveBuilder_P11,limits={-inf,inf,0.1},value= _NUM:0
	SetVariable SetVar_WaveBuilder_P2,pos={365.00,76.00},size={100.00,18.00},proc=WBP_SetVarProc_UpdateParam,title="Amplitude"
	SetVariable SetVar_WaveBuilder_P2,help={"Amplitude of the epoch being edited. The unit depends on the DA channel configuration. For Noise epochs, amplitude = peak to peak."}
	SetVariable SetVar_WaveBuilder_P2,userdata(ResizeControlsInfo)= A"!!,HqJ,hp'!!#@,!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P2,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P2,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P2,value= _NUM:0
	SetVariable SetVar_WaveBuilder_P3,pos={471.00,75.00},size={100.00,18.00},proc=WBP_SetVarProc_UpdateParam,title="Delta"
	SetVariable SetVar_WaveBuilder_P3,help={"Sweep to sweep amplitude delta."}
	SetVariable SetVar_WaveBuilder_P3,userdata(ResizeControlsInfo)= A"!!,IQJ,hp%!!#@,!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P3,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P3,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P3,value= _NUM:0
	SetVariable setvar_WaveBuilder_SetNumber,pos={25.00,310.00},size={83.00,18.00},bodyWidth=35,title="Number"
	SetVariable setvar_WaveBuilder_SetNumber,help={"A numeric suffix for the set name that can be used to sort sets with identical prefixes."}
	SetVariable setvar_WaveBuilder_SetNumber,userdata(ResizeControlsInfo)= A"!!,C,!!#BU!!#?_!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_WaveBuilder_SetNumber,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_WaveBuilder_SetNumber,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_WaveBuilder_SetNumber,limits={0,inf,1},value= _NUM:0
	SetVariable SetVar_WaveBuilder_P4,pos={365.00,101.00},size={100.00,18.00},disable=1,proc=WBP_SetVarProc_UpdateParam,title="Offset"
	SetVariable SetVar_WaveBuilder_P4,help={"Epoch offset. Offset value is added to epoch."}
	SetVariable SetVar_WaveBuilder_P4,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P4,userdata(ResizeControlsInfo)= A"!!,HqJ,hpY!!#@,!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P4,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P4,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P4,userdata(tabnum)=  "1",value= _NUM:0
	SetVariable SetVar_WaveBuilder_P6,pos={364.00,122.00},size={100.00,18.00},disable=1,proc=WBP_SetVarProc_UpdateParam,title="Start Freq"
	SetVariable SetVar_WaveBuilder_P6,help={"Sin frequency or chirp start frequency"}
	SetVariable SetVar_WaveBuilder_P6,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P6,userdata(ResizeControlsInfo)= A"!!,Hq!!#@X!!#@,!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P6,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P6,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P6,userdata(tabnum)=  "3",value= _NUM:0
	SetVariable setvar_WaveBuilder_CurrentEpoch,pos={32.00,114.00},size={122.00,22.00},proc=WBP_SetVarProc_EpochToEdit,title="Epoch to edit"
	SetVariable setvar_WaveBuilder_CurrentEpoch,help={"Epoch to edit. The active epoch is displayed on the graph with a white background. Inactive epochs have a gray background."}
	SetVariable setvar_WaveBuilder_CurrentEpoch,userdata(ResizeControlsInfo)= A"!!,Cd!!#@H!!#@X!!#<hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_WaveBuilder_CurrentEpoch,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_WaveBuilder_CurrentEpoch,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_WaveBuilder_CurrentEpoch,fSize=14
	SetVariable setvar_WaveBuilder_CurrentEpoch,limits={0,0,1},value= _NUM:0
	SetVariable SetVar_WaveBuilder_P5,pos={470.00,100.00},size={100.00,18.00},disable=1,proc=WBP_SetVarProc_UpdateParam,title="Delta"
	SetVariable SetVar_WaveBuilder_P5,help={"Epoch sweep to sweep offset delta."}
	SetVariable SetVar_WaveBuilder_P5,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P5,userdata(ResizeControlsInfo)= A"!!,IQ!!#@,!!#@,!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P5,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P5,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P5,userdata(tabnum)=  "1",value= _NUM:0
	SetVariable SetVar_WaveBuilder_P7,pos={470.00,122.00},size={100.00,18.00},disable=1,proc=WBP_SetVarProc_UpdateParam,title="Delta"
	SetVariable SetVar_WaveBuilder_P7,help={"Start frequency delta"}
	SetVariable SetVar_WaveBuilder_P7,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P7,userdata(ResizeControlsInfo)= A"!!,IQ!!#@X!!#@,!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P7,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P7,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P7,userdata(tabnum)=  "3",value= _NUM:0
	SetVariable SetVar_WaveBuilder_P8,pos={366.00,148.00},size={100.00,18.00},disable=1,proc=WBP_SetVarProc_UpdateParam,title="Pulse Dur"
	SetVariable SetVar_WaveBuilder_P8,help={"Duration of the square pulse. Max = pulse interval - 0.005 ms"}
	SetVariable SetVar_WaveBuilder_P8,userdata(tabnum)=  "5"
	SetVariable SetVar_WaveBuilder_P8,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P8,userdata(ResizeControlsInfo)= A"!!,Hr!!#A#!!#@,!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P8,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P8,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P8,limits={0,inf,0.1},value= _NUM:0
	SetVariable SetVar_WaveBuilder_P9,pos={471.00,148.00},size={100.00,18.00},disable=1,proc=WBP_SetVarProc_UpdateParam,title="Delta"
	SetVariable SetVar_WaveBuilder_P9,help={"Square pulse duration delta"}
	SetVariable SetVar_WaveBuilder_P9,userdata(tabnum)=  "5"
	SetVariable SetVar_WaveBuilder_P9,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P9,userdata(ResizeControlsInfo)= A"!!,IQJ,hqN!!#@,!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P9,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P9,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P9,value= _NUM:0
	SetVariable setvar_WaveBuilder_baseName,pos={23.00,330.00},size={125.00,18.00}
	SetVariable setvar_WaveBuilder_baseName,help={"Stimulus set name prefix. Max number of characters = 16"}
	SetVariable setvar_WaveBuilder_baseName,userdata(ResizeControlsInfo)= A"!!,Bq!!#B_!!#@^!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_WaveBuilder_baseName,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_WaveBuilder_baseName,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_WaveBuilder_baseName,fSize=12
	SetVariable setvar_WaveBuilder_baseName,limits={0,10,1},value= _STR:"StimulusSetA"
	PopupMenu popup_WaveBuilder_SetList,pos={23.00,421.00},size={125.00,19.00},bodyWidth=125,proc=WBP_PopupMenu_LoadSet
	PopupMenu popup_WaveBuilder_SetList,help={"Select stimulus set to load."}
	PopupMenu popup_WaveBuilder_SetList,userdata(ResizeControlsInfo)= A"!!,Bq!!#C7J,hq4!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu popup_WaveBuilder_SetList,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	PopupMenu popup_WaveBuilder_SetList,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	PopupMenu popup_WaveBuilder_SetList,mode=1,popvalue="- none -",value= #"WBP_ReturnListSavedSets()"
	Button button_WaveBuilder_KillSet,pos={22.00,472.00},size={125.00,20.00},proc=WBP_ButtonProc_DeleteSet,title="Delete Set"
	Button button_WaveBuilder_KillSet,help={"Delete stimulus set selected in popup menu."}
	Button button_WaveBuilder_KillSet,userdata(ResizeControlsInfo)= A"!!,Bi!!#CQ!!#@^!!#<Xz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_WaveBuilder_KillSet,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	Button button_WaveBuilder_KillSet,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	PopupMenu popup_WaveBuilder_op_P71_DD01,pos={644.00,53.00},size={75.00,19.00},bodyWidth=75,disable=1,proc=WBP_PopupMenu
	PopupMenu popup_WaveBuilder_op_P71_DD01,help={"Delta operation"}
	PopupMenu popup_WaveBuilder_op_P71_DD01,userdata(tabcontrol)=  "WBP_WaveType"
	PopupMenu popup_WaveBuilder_op_P71_DD01,userdata(ResizeControlsInfo)= A"!!,J2!!#>b!!#?O!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu popup_WaveBuilder_op_P71_DD01,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu popup_WaveBuilder_op_P71_DD01,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu popup_WaveBuilder_op_P71_DD01,userdata(tabnum)=  "7"
	PopupMenu popup_WaveBuilder_op_P71_DD01,mode=1,popvalue="None",value= #"\"None;Multiplier;Log;Squared;Power;Alternate;Explicit\""
	Button button_WaveBuilder_setaxisA,pos={32.00,497.00},size={107.00,22.00},proc=WBP_ButtonProc_AutoScale,title="Autoscale"
	Button button_WaveBuilder_setaxisA,help={"Returns the WaveBuilder graph to full scale. Ctrl-A does not work for panel graphs."}
	Button button_WaveBuilder_setaxisA,userdata(ResizeControlsInfo)= A"!!,Cd!!#C]J,hpe!!#<hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_WaveBuilder_setaxisA,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#?(FEDG<zzzzzzzzzzz"
	Button button_WaveBuilder_setaxisA,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	PopupMenu popup_WaveBuilder_OutputType,pos={31.00,45.00},size={123.00,19.00},bodyWidth=55,proc=WBP_PopMenuProc_WaveType,title="Wave Type"
	PopupMenu popup_WaveBuilder_OutputType,help={"Stimulus set output type. TTL selection limits certain paramater values. This may result in changes to the active parameter values."}
	PopupMenu popup_WaveBuilder_OutputType,userdata(ResizeControlsInfo)= A"!!,CL!!#>B!!#@^!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu popup_WaveBuilder_OutputType,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu popup_WaveBuilder_OutputType,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu popup_WaveBuilder_OutputType,fSize=14
	PopupMenu popup_WaveBuilder_OutputType,mode=1,popvalue="DA",value= #"\"DA;TTL\""
	Button button_WaveBuilder_SaveSet,pos={22.00,351.00},size={125.00,20.00},proc=WBP_ButtonProc_SaveSet,title="Save Set"
	Button button_WaveBuilder_SaveSet,help={"Saves the stimulus set and clears the WaveBuilder graph. On save the set is available for data acquisition."}
	Button button_WaveBuilder_SaveSet,userdata(ResizeControlsInfo)= A"!!,Bi!!#BiJ,hq4!!#<Xz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_WaveBuilder_SaveSet,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	Button button_WaveBuilder_SaveSet,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P6_FD00,pos={364.00,124.00},size={100.00,18.00},disable=1,proc=WBP_SetVarProc_UpdateParam,title="Freq"
	SetVariable SetVar_WaveBuilder_P6_FD00,help={"Saw tooth frequency"}
	SetVariable SetVar_WaveBuilder_P6_FD00,userdata(tabnum)=  "4"
	SetVariable SetVar_WaveBuilder_P6_FD00,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P6_FD00,userdata(ResizeControlsInfo)= A"!!,Hq!!#@\\!!#@,!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P6_FD00,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P6_FD00,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P6_FD00,value= _NUM:0
	SetVariable SetVar_WaveBuilder_P7_DD00,pos={470.00,124.00},size={100.00,18.00},disable=1,proc=WBP_SetVarProc_UpdateParam,title="Delta"
	SetVariable SetVar_WaveBuilder_P7_DD00,help={"Saw tooth frequency delta"}
	SetVariable SetVar_WaveBuilder_P7_DD00,userdata(tabnum)=  "4"
	SetVariable SetVar_WaveBuilder_P7_DD00,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P7_DD00,userdata(ResizeControlsInfo)= A"!!,IQ!!#@\\!!#@,!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P7_DD00,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P7_DD00,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P7_DD00,value= _NUM:0
	SetVariable SetVar_WaveBuilder_P6_FD01,pos={366.00,124.00},size={100.00,18.00},disable=1,proc=WBP_SetVarProc_UpdateParam,title="Freq"
	SetVariable SetVar_WaveBuilder_P6_FD01,userdata(tabnum)=  "5"
	SetVariable SetVar_WaveBuilder_P6_FD01,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P6_FD01,userdata(ResizeControlsInfo)= A"!!,Hr!!#@\\!!#@,!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P6_FD01,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P6_FD01,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P6_FD01,value= _NUM:0
	SetVariable SetVar_WaveBuilder_P7_DD01,pos={471.00,124.00},size={100.00,18.00},disable=1,proc=WBP_SetVarProc_UpdateParam,title="Delta"
	SetVariable SetVar_WaveBuilder_P7_DD01,userdata(tabnum)=  "5"
	SetVariable SetVar_WaveBuilder_P7_DD01,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P7_DD01,userdata(ResizeControlsInfo)= A"!!,IQJ,hq2!!#@,!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P7_DD01,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P7_DD01,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P7_DD01,value= _NUM:0
	SetVariable SetVar_WaveBuilder_P4_OD00,pos={365.00,100.00},size={100.00,18.00},disable=1,proc=WBP_SetVarProc_UpdateParam,title="Offset"
	SetVariable SetVar_WaveBuilder_P4_OD00,help={"Noise offset."}
	SetVariable SetVar_WaveBuilder_P4_OD00,userdata(tabnum)=  "2"
	SetVariable SetVar_WaveBuilder_P4_OD00,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P4_OD00,userdata(ResizeControlsInfo)= A"!!,HqJ,hpW!!#@,!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P4_OD00,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P4_OD00,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P4_OD00,value= _NUM:0
	SetVariable SetVar_WaveBuilder_P5_DD02,pos={471.00,98.00},size={100.00,18.00},disable=1,proc=WBP_SetVarProc_UpdateParam,title="Delta"
	SetVariable SetVar_WaveBuilder_P5_DD02,help={"Noise offset delta."}
	SetVariable SetVar_WaveBuilder_P5_DD02,userdata(tabnum)=  "2"
	SetVariable SetVar_WaveBuilder_P5_DD02,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P5_DD02,userdata(ResizeControlsInfo)= A"!!,IQJ,hpS!!#@,!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P5_DD02,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P5_DD02,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P5_DD02,value= _NUM:0
	SetVariable SetVar_WaveBuilder_P5_DD03,pos={470.00,98.00},size={100.00,18.00},disable=1,proc=WBP_SetVarProc_UpdateParam,title="Delta"
	SetVariable SetVar_WaveBuilder_P5_DD03,userdata(tabnum)=  "3"
	SetVariable SetVar_WaveBuilder_P5_DD03,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P5_DD03,userdata(ResizeControlsInfo)= A"!!,IQ!!#@(!!#@,!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P5_DD03,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P5_DD03,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P5_DD03,value= _NUM:0
	SetVariable SetVar_WaveBuilder_P4_OD01,pos={364.00,98.00},size={100.00,18.00},disable=1,proc=WBP_SetVarProc_UpdateParam,title="Offset"
	SetVariable SetVar_WaveBuilder_P4_OD01,userdata(tabnum)=  "3"
	SetVariable SetVar_WaveBuilder_P4_OD01,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P4_OD01,userdata(ResizeControlsInfo)= A"!!,Hq!!#@(!!#@,!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P4_OD01,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P4_OD01,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P4_OD01,value= _NUM:0
	SetVariable SetVar_WaveBuilder_P5_DD04,pos={470.00,100.00},size={100.00,18.00},disable=1,proc=WBP_SetVarProc_UpdateParam,title="Delta"
	SetVariable SetVar_WaveBuilder_P5_DD04,userdata(tabnum)=  "4"
	SetVariable SetVar_WaveBuilder_P5_DD04,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P5_DD04,userdata(ResizeControlsInfo)= A"!!,IQ!!#@,!!#@,!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P5_DD04,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P5_DD04,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P5_DD04,value= _NUM:0
	SetVariable SetVar_WaveBuilder_P4_OD02,pos={364.00,100.00},size={100.00,18.00},disable=1,proc=WBP_SetVarProc_UpdateParam,title="Offset"
	SetVariable SetVar_WaveBuilder_P4_OD02,userdata(tabnum)=  "4"
	SetVariable SetVar_WaveBuilder_P4_OD02,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P4_OD02,userdata(ResizeControlsInfo)= A"!!,Hq!!#@,!!#@,!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P4_OD02,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P4_OD02,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P4_OD02,value= _NUM:0
	SetVariable SetVar_WaveBuilder_P5_DD05,pos={471.00,100.00},size={100.00,18.00},disable=1,proc=WBP_SetVarProc_UpdateParam,title="Delta"
	SetVariable SetVar_WaveBuilder_P5_DD05,userdata(tabnum)=  "5"
	SetVariable SetVar_WaveBuilder_P5_DD05,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P5_DD05,userdata(ResizeControlsInfo)= A"!!,IQJ,hpW!!#@,!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P5_DD05,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P5_DD05,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P5_DD05,value= _NUM:0
	SetVariable SetVar_WaveBuilder_P4_OD03,pos={366.00,100.00},size={100.00,18.00},disable=1,proc=WBP_SetVarProc_UpdateParam,title="Offset"
	SetVariable SetVar_WaveBuilder_P4_OD03,userdata(tabnum)=  "5"
	SetVariable SetVar_WaveBuilder_P4_OD03,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P4_OD03,userdata(ResizeControlsInfo)= A"!!,Hr!!#@,!!#@,!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P4_OD03,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P4_OD03,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P4_OD03,value= _NUM:0
	SetVariable SetVar_WaveBuilder_P5_DD06,pos={471.00,100.00},size={100.00,18.00},disable=1,proc=WBP_SetVarProc_UpdateParam,title="Delta"
	SetVariable SetVar_WaveBuilder_P5_DD06,help={"PSC epoch sweep to sweep offset delta"}
	SetVariable SetVar_WaveBuilder_P5_DD06,userdata(tabnum)=  "6"
	SetVariable SetVar_WaveBuilder_P5_DD06,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P5_DD06,userdata(ResizeControlsInfo)= A"!!,IQJ,hpW!!#@,!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P5_DD06,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P5_DD06,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P5_DD06,value= _NUM:0
	SetVariable SetVar_WaveBuilder_P4_OD04,pos={365.00,100.00},size={100.00,18.00},disable=1,proc=WBP_SetVarProc_UpdateParam,title="Offset"
	SetVariable SetVar_WaveBuilder_P4_OD04,help={"Offset of post synaptic current (PSC) epoch "}
	SetVariable SetVar_WaveBuilder_P4_OD04,userdata(tabnum)=  "6"
	SetVariable SetVar_WaveBuilder_P4_OD04,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P4_OD04,userdata(ResizeControlsInfo)= A"!!,HqJ,hpW!!#@,!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P4_OD04,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P4_OD04,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P4_OD04,value= _NUM:0
	SetVariable SetVar_WaveBuilder_P4_OD05,pos={363.00,53.00},size={100.00,18.00},disable=1,proc=WBP_SetVarProc_UpdateParam,title="Offset"
	SetVariable SetVar_WaveBuilder_P4_OD05,userdata(tabnum)=  "7"
	SetVariable SetVar_WaveBuilder_P4_OD05,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P4_OD05,userdata(ResizeControlsInfo)= A"!!,HpJ,ho8!!#@,!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P4_OD05,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P4_OD05,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P4_OD05,value= _NUM:0
	SetVariable SetVar_WaveBuilder_P5_DD07,pos={469.00,53.00},size={100.00,18.00},disable=1,proc=WBP_SetVarProc_UpdateParam,title="Delta"
	SetVariable SetVar_WaveBuilder_P5_DD07,userdata(tabnum)=  "7"
	SetVariable SetVar_WaveBuilder_P5_DD07,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P5_DD07,userdata(ResizeControlsInfo)= A"!!,IPJ,ho8!!#@,!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P5_DD07,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P5_DD07,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P5_DD07,value= _NUM:0
	SetVariable setvar_WaveBuilder_SearchString,pos={558.00,172.00},size={212.00,33.00},disable=1,proc=WBP_SetVarProc_SetSearchString,title="Search\rstring"
	SetVariable setvar_WaveBuilder_SearchString,help={"Refines list of waves based on search string. Include asterisk \"wildcard\" where appropriate."}
	SetVariable setvar_WaveBuilder_SearchString,userdata(tabnum)=  "7"
	SetVariable setvar_WaveBuilder_SearchString,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable setvar_WaveBuilder_SearchString,userdata(ResizeControlsInfo)= A"!!,IqJ,hqf!!#Ac!!#=gz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_WaveBuilder_SearchString,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_WaveBuilder_SearchString,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_WaveBuilder_SearchString,value= _STR:""
	PopupMenu popup_WaveBuilder_ListOfWaves,pos={556.00,142.00},size={215.00,30.00},bodyWidth=175,disable=1,proc=WBP_PopMenuProc_WaveToLoad,title="Wave\rto load"
	PopupMenu popup_WaveBuilder_ListOfWaves,help={"Select custom epoch wave. Popup menu displays waves contained in selected folder. Waves must have 5 micro second sampling interval."}
	PopupMenu popup_WaveBuilder_ListOfWaves,userdata(tabnum)=  "7"
	PopupMenu popup_WaveBuilder_ListOfWaves,userdata(tabcontrol)=  "WBP_WaveType"
	PopupMenu popup_WaveBuilder_ListOfWaves,userdata(ResizeControlsInfo)= A"!!,Iq!!#@r!!#Af!!#=Sz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu popup_WaveBuilder_ListOfWaves,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu popup_WaveBuilder_ListOfWaves,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu popup_WaveBuilder_ListOfWaves,mode=1,popvalue="- none -",value= #"WBP_GetListOfWaves()"
	SetVariable SetVar_WaveBuilder_P20,pos={364.00,124.00},size={101.00,18.00},bodyWidth=49,disable=1,proc=WBP_SetVarProc_UpdateParam,title="Low pass"
	SetVariable SetVar_WaveBuilder_P20,help={"The low pass frequency defines an <b>upper</b> border for the passband (higher frequencies will be cut off).<br>Set to zero to turn off."}
	SetVariable SetVar_WaveBuilder_P20,userdata(tabnum)=  "2"
	SetVariable SetVar_WaveBuilder_P20,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P20,userdata(ResizeControlsInfo)= A"!!,Hq!!#@\\!!#@.!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P20,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P20,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P20,limits={0,100001,100},value= _NUM:0
	SetVariable SetVar_WaveBuilder_P21,pos={471.00,122.00},size={100.00,18.00},disable=1,proc=WBP_SetVarProc_UpdateParam,title="Delta"
	SetVariable SetVar_WaveBuilder_P21,help={"Low pass filter cut off frequency delta."}
	SetVariable SetVar_WaveBuilder_P21,userdata(tabnum)=  "2"
	SetVariable SetVar_WaveBuilder_P21,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P21,userdata(ResizeControlsInfo)= A"!!,IQJ,hq.!!#@,!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P21,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P21,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P21,limits={-inf,100000,1},value= _NUM:0
	SetVariable SetVar_WaveBuilder_P22,pos={359.00,148.00},size={106.00,18.00},bodyWidth=50,disable=1,proc=WBP_SetVarProc_UpdateParam,title="High pass"
	SetVariable SetVar_WaveBuilder_P22,help={"The high pass frequency defines a <b>lower</b> border for the passband (lower frequencies will be cut off).<br>Set to zero to turn off."}
	SetVariable SetVar_WaveBuilder_P22,userdata(tabnum)=  "2"
	SetVariable SetVar_WaveBuilder_P22,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P22,userdata(ResizeControlsInfo)= A"!!,HnJ,hqN!!#@8!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P22,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P22,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P22,limits={0,100001,100},value= _NUM:0
	SetVariable SetVar_WaveBuilder_P23,pos={471.00,148.00},size={100.00,18.00},disable=1,proc=WBP_SetVarProc_UpdateParam,title="Delta"
	SetVariable SetVar_WaveBuilder_P23,help={"High pass filter cut off frequency delta."}
	SetVariable SetVar_WaveBuilder_P23,userdata(tabnum)=  "2"
	SetVariable SetVar_WaveBuilder_P23,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P23,userdata(ResizeControlsInfo)= A"!!,IQJ,hqN!!#@,!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P23,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P23,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P23,limits={-inf,99749,1},value= _NUM:0
	CheckBox check_SPT_Poisson_P44,pos={880.00,123.00},size={121.00,15.00},disable=1,proc=WBP_CheckProc,title="Poisson distribution"
	CheckBox check_SPT_Poisson_P44,help={"Poisson distribution of square pulses at the average frequency specified by the user."}
	CheckBox check_SPT_Poisson_P44,userdata(ResizeControlsInfo)= A"!!,Jm!!#@Z!!#@V!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_SPT_Poisson_P44,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_SPT_Poisson_P44,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_SPT_Poisson_P44,userdata(tabnum)=  "5"
	CheckBox check_SPT_Poisson_P44,userdata(tabcontrol)=  "WBP_WaveType",value= 0
	SetVariable SetVar_WaveBuilder_P24,pos={364.00,146.00},size={100.00,18.00},disable=3,proc=WBP_SetVarProc_UpdateParam,title="End Freq"
	SetVariable SetVar_WaveBuilder_P24,help={"Chirp end frequency"}
	SetVariable SetVar_WaveBuilder_P24,userdata(ResizeControlsInfo)= A"!!,Hq!!#A!!!#@,!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P24,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P24,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P24,userdata(tabnum)=  "3"
	SetVariable SetVar_WaveBuilder_P24,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P24,limits={0,inf,0.1},value= _NUM:0
	SetVariable SetVar_WaveBuilder_P25,pos={470.00,146.00},size={100.00,18.00},disable=1,proc=WBP_SetVarProc_UpdateParam,title="Delta"
	SetVariable SetVar_WaveBuilder_P25,help={"Chirp end frequency delta"}
	SetVariable SetVar_WaveBuilder_P25,userdata(ResizeControlsInfo)= A"!!,IQ!!#A!!!#@,!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P25,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P25,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P25,userdata(tabnum)=  "3"
	SetVariable SetVar_WaveBuilder_P25,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P25,value= _NUM:0
	CheckBox check_Sin_Chirp_P43,pos={878.00,168.00},size={63.00,15.00},disable=1,proc=WBP_CheckProc,title="log chirp"
	CheckBox check_Sin_Chirp_P43,help={"A chirp is a signal in which the frequency increases or decreases with time."}
	CheckBox check_Sin_Chirp_P43,userdata(tabnum)=  "3"
	CheckBox check_Sin_Chirp_P43,userdata(tabcontrol)=  "WBP_WaveType"
	CheckBox check_Sin_Chirp_P43,userdata(ResizeControlsInfo)= A"!!,JlJ,hqb!!#?5!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_Sin_Chirp_P43,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_Sin_Chirp_P43,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_Sin_Chirp_P43,value= 0
	SetVariable SetVar_WB_DurDeltaMult_P52,pos={573.00,52.00},size={57.00,18.00},disable=2,proc=WBP_SetVarProc_UpdateParam,title="* "
	SetVariable SetVar_WB_DurDeltaMult_P52,help={"Epoch duration delta multiplier or exponent."}
	SetVariable SetVar_WB_DurDeltaMult_P52,userdata(ResizeControlsInfo)= A"!!,Iu5QF,I!!#>r!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WB_DurDeltaMult_P52,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable SetVar_WB_DurDeltaMult_P52,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WB_DurDeltaMult_P52,value= _NUM:0
	PopupMenu popup_WaveBuilder_FolderList,pos={562.00,111.00},size={209.00,30.00},bodyWidth=175,disable=1,proc=WBP_PopMenuProc_FolderSelect,title="Select\rfolder"
	PopupMenu popup_WaveBuilder_FolderList,help={"Select folder that contains custom epoch wave. After each selection, contents of selected folder are listed in popup menu."}
	PopupMenu popup_WaveBuilder_FolderList,userdata(tabnum)=  "7"
	PopupMenu popup_WaveBuilder_FolderList,userdata(tabcontrol)=  "WBP_WaveType"
	PopupMenu popup_WaveBuilder_FolderList,userdata(ResizeControlsInfo)= A"!!,IrJ,hpm!!#A`!!#=Sz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu popup_WaveBuilder_FolderList,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	PopupMenu popup_WaveBuilder_FolderList,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	PopupMenu popup_WaveBuilder_FolderList,mode=1,popvalue="- none -",value= #"WBP_ReturnFoldersList()"
	GroupBox group_WaveBuilder_FolderPath,pos={532.00,88.00},size={269.00,127.00},disable=1,title="root:MIES:WaveBuilder:"
	GroupBox group_WaveBuilder_FolderPath,help={"Displays user defined path to custom epoch wave"}
	GroupBox group_WaveBuilder_FolderPath,userdata(tabnum)=  "7"
	GroupBox group_WaveBuilder_FolderPath,userdata(tabcontrol)=  "WBP_WaveType"
	GroupBox group_WaveBuilder_FolderPath,userdata(ResizeControlsInfo)= A"!!,Ik!!#?i!!#B@J,hq8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	GroupBox group_WaveBuilder_FolderPath,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	GroupBox group_WaveBuilder_FolderPath,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	PopupMenu popup_noise_type_P54,pos={884.00,97.00},size={129.00,19.00},bodyWidth=100,disable=1,proc=WBP_PopupMenu,title="Type"
	PopupMenu popup_noise_type_P54,help={"White Noise: Constant power density, Pink Noise: 1/f power density drop (10dB per decade), Brown Noise: 1/f^2 power density drop (20db per decade)"}
	PopupMenu popup_noise_type_P54,userdata(tabnum)=  "2"
	PopupMenu popup_noise_type_P54,userdata(tabcontrol)=  "WBP_WaveType"
	PopupMenu popup_noise_type_P54,userdata(ResizeControlsInfo)= A"!!,Jn!!#@&!!#@e!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu popup_noise_type_P54,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	PopupMenu popup_noise_type_P54,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	PopupMenu popup_noise_type_P54,mode=1,popvalue="White",value= #"WBP_GetNoiseTypes()"
	CheckBox check_PreventUpdate,pos={34.00,525.00},size={96.00,15.00},proc=WBP_CheckProc_PreventUpdate,title="Prevent update"
	CheckBox check_PreventUpdate,help={"Stops graph updating when checked. Useful when updating multiple parameters in \"big\" stimulus sets."}
	CheckBox check_PreventUpdate,userdata(ResizeControlsInfo)= A"!!,Cl!!#Ch5QF-d!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_PreventUpdate,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#?(FEDG<zzzzzzzzzzz"
	CheckBox check_PreventUpdate,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	CheckBox check_PreventUpdate,value= 0
	SetVariable SetVar_WB_AmpDeltaMult_P50,pos={573.00,75.00},size={57.00,18.00},disable=2,proc=WBP_SetVarProc_UpdateParam,title="* "
	SetVariable SetVar_WB_AmpDeltaMult_P50,help={"Epoch amplitude delta multiplier or exponent."}
	SetVariable SetVar_WB_AmpDeltaMult_P50,userdata(ResizeControlsInfo)= A"!!,Iu5QF-:!!#>r!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WB_AmpDeltaMult_P50,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable SetVar_WB_AmpDeltaMult_P50,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WB_AmpDeltaMult_P50,value= _NUM:0
	SetVariable SetVar_WB_DeltaMult_P51,pos={575.00,100.00},size={55.00,18.00},disable=3,proc=WBP_SetVarProc_UpdateParam,title="* "
	SetVariable SetVar_WB_DeltaMult_P51,help={"Specify the epoch offset delta multiplier or exponent."}
	SetVariable SetVar_WB_DeltaMult_P51,userdata(tabnum)=  "1"
	SetVariable SetVar_WB_DeltaMult_P51,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WB_DeltaMult_P51,userdata(ResizeControlsInfo)= A"!!,Iu^]6^B!!#>j!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WB_DeltaMult_P51,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable SetVar_WB_DeltaMult_P51,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WB_DeltaMult_P51,value= _NUM:0
	SetVariable SetVar_WB_DeltaMult_P51_0,pos={575.00,100.00},size={55.00,18.00},disable=3,proc=WBP_SetVarProc_UpdateParam,title="* "
	SetVariable SetVar_WB_DeltaMult_P51_0,userdata(tabnum)=  "2"
	SetVariable SetVar_WB_DeltaMult_P51_0,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WB_DeltaMult_P51_0,userdata(ResizeControlsInfo)= A"!!,Iu^]6^B!!#>j!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WB_DeltaMult_P51_0,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable SetVar_WB_DeltaMult_P51_0,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WB_DeltaMult_P51_0,value= _NUM:0
	SetVariable SetVar_WB_DeltaMult_P51_1,pos={574.00,99.00},size={55.00,18.00},disable=3,proc=WBP_SetVarProc_UpdateParam,title="* "
	SetVariable SetVar_WB_DeltaMult_P51_1,userdata(tabnum)=  "3"
	SetVariable SetVar_WB_DeltaMult_P51_1,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WB_DeltaMult_P51_1,userdata(ResizeControlsInfo)= A"!!,IuJ,hpU!!#>j!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WB_DeltaMult_P51_1,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable SetVar_WB_DeltaMult_P51_1,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WB_DeltaMult_P51_1,value= _NUM:0
	SetVariable SetVar_WB_DeltaMult_P51_2,pos={575.00,100.00},size={55.00,18.00},disable=3,proc=WBP_SetVarProc_UpdateParam,title="* "
	SetVariable SetVar_WB_DeltaMult_P51_2,userdata(tabnum)=  "4"
	SetVariable SetVar_WB_DeltaMult_P51_2,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WB_DeltaMult_P51_2,userdata(ResizeControlsInfo)= A"!!,Iu^]6^B!!#>j!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WB_DeltaMult_P51_2,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable SetVar_WB_DeltaMult_P51_2,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WB_DeltaMult_P51_2,value= _NUM:0
	SetVariable SetVar_WB_DeltaMult_P51_3,pos={573.00,100.00},size={55.00,18.00},disable=3,proc=WBP_SetVarProc_UpdateParam,title="* "
	SetVariable SetVar_WB_DeltaMult_P51_3,userdata(tabnum)=  "5"
	SetVariable SetVar_WB_DeltaMult_P51_3,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WB_DeltaMult_P51_3,userdata(ResizeControlsInfo)= A"!!,Iu5QF-l!!#>j!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WB_DeltaMult_P51_3,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable SetVar_WB_DeltaMult_P51_3,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WB_DeltaMult_P51_3,value= _NUM:0
	SetVariable SetVar_WB_DeltaMult_P51_4,pos={571.00,99.00},size={57.00,18.00},disable=3,proc=WBP_SetVarProc_UpdateParam,title="* "
	SetVariable SetVar_WB_DeltaMult_P51_4,userdata(tabnum)=  "6"
	SetVariable SetVar_WB_DeltaMult_P51_4,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WB_DeltaMult_P51_4,userdata(ResizeControlsInfo)= A"!!,It^]6^@!!#>r!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WB_DeltaMult_P51_4,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable SetVar_WB_DeltaMult_P51_4,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WB_DeltaMult_P51_4,value= _NUM:0
	SetVariable SetVar_WB_DeltaMult_P51_5,pos={575.00,53.00},size={55.00,18.00},disable=3,proc=WBP_SetVarProc_UpdateParam,title="*"
	SetVariable SetVar_WB_DeltaMult_P51_5,userdata(tabnum)=  "7"
	SetVariable SetVar_WB_DeltaMult_P51_5,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WB_DeltaMult_P51_5,userdata(ResizeControlsInfo)= A"!!,Iu^]6]#!!#>j!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WB_DeltaMult_P51_5,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable SetVar_WB_DeltaMult_P51_5,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WB_DeltaMult_P51_5,value= _NUM:0
	SetVariable SetVar_WaveBuilder_P45,pos={366.00,171.00},size={100.00,18.00},disable=3,proc=WBP_SetVarProc_UpdateParam,title="# Pulses"
	SetVariable SetVar_WaveBuilder_P45,help={"Number of pulses in epoch"}
	SetVariable SetVar_WaveBuilder_P45,userdata(tabnum)=  "5"
	SetVariable SetVar_WaveBuilder_P45,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P45,userdata(ResizeControlsInfo)= A"!!,Hr!!#A:!!#@,!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P45,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P45,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P45,limits={0,inf,1},value= _NUM:0
	SetVariable SetVar_WaveBuilder_P47,pos={471.00,171.00},size={100.00,18.00},disable=1,proc=WBP_SetVarProc_UpdateParam,title="Delta"
	SetVariable SetVar_WaveBuilder_P47,help={"Epoch pulse number delta"}
	SetVariable SetVar_WaveBuilder_P47,userdata(tabnum)=  "5"
	SetVariable SetVar_WaveBuilder_P47,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P47,userdata(ResizeControlsInfo)= A"!!,IQJ,hqe!!#@,!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P47,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P47,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P47,value= _NUM:0
	CheckBox check_SPT_NumPulses_P46,pos={880.00,145.00},size={71.00,15.00},disable=1,proc=WBP_CheckProc,title="Use Pulses"
	CheckBox check_SPT_NumPulses_P46,help={"Checked: epoch duration is determined by the user specified pulse number and frequency. Unchecked: epoch duration is set by the user."}
	CheckBox check_SPT_NumPulses_P46,userdata(tabnum)=  "5"
	CheckBox check_SPT_NumPulses_P46,userdata(tabcontrol)=  "WBP_WaveType"
	CheckBox check_SPT_NumPulses_P46,userdata(ResizeControlsInfo)= A"!!,Jm!!#@u!!#?G!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_SPT_NumPulses_P46,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_SPT_NumPulses_P46,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_SPT_NumPulses_P46,userdata(old_state)=  "1",value= 0
	Button button_NewSeed_P48,pos={884.00,148.00},size={72.00,20.00},disable=1,proc=WBP_ButtonProc_NewSeed,title="New Noise"
	Button button_NewSeed_P48,help={"Create new noise waveforms for the selected epoch."}
	Button button_NewSeed_P48,userdata(tabnum)=  "2"
	Button button_NewSeed_P48,userdata(tabcontrol)=  "WBP_WaveType"
	Button button_NewSeed_P48,userdata(ResizeControlsInfo)= A"!!,Jn!!#A#!!#?I!!#<Xz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_NewSeed_P48,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	Button button_NewSeed_P48,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox check_NewSeedForEachSweep_P49,pos={884.00,175.00},size={86.00,15.00},disable=1,proc=WBP_CheckProc,title="Seed / Sweep"
	CheckBox check_NewSeedForEachSweep_P49,help={"When checked, the random number generator (RNG) seed is updated with each sweep. Seeds are saved with the stimulus."}
	CheckBox check_NewSeedForEachSweep_P49,userdata(tabnum)=  "2"
	CheckBox check_NewSeedForEachSweep_P49,userdata(tabcontrol)=  "WBP_WaveType"
	CheckBox check_NewSeedForEachSweep_P49,userdata(ResizeControlsInfo)= A"!!,Jn!!#A>!!#?e!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_NewSeedForEachSweep_P49,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_NewSeedForEachSweep_P49,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox check_NewSeedForEachSweep_P49,value= 0
	ListBox listbox_combineEpochMap,pos={365.00,53.00},size={227.00,181.00},disable=1
	ListBox listbox_combineEpochMap,help={"Shorthand <-> Stimset mapping for use with the formula"}
	ListBox listbox_combineEpochMap,userdata(tabnum)=  "8"
	ListBox listbox_combineEpochMap,userdata(tabcontrol)=  "WBP_WaveType"
	ListBox listbox_combineEpochMap,userdata(ResizeControlsInfo)= A"!!,HqJ,ho8!!#Ar!!#ADz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	ListBox listbox_combineEpochMap,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	ListBox listbox_combineEpochMap,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	ListBox listbox_combineEpochMap,widths={58,120}
	SetVariable setvar_combine_formula_T6,pos={598.00,210.00},size={427.00,18.00},disable=1,proc=WBP_SetVarCombineEpochFormula,title="Formula"
	SetVariable setvar_combine_formula_T6,help={"Mathematical formula for combining stim sets. All math operators from Igor are supported. Examples: +/-*^,sin,cos,tan. All are applied elementwise on the stim set contents. Mutiple sweeps are flattened into one sweep."}
	SetVariable setvar_combine_formula_T6,userdata(tabnum)=  "8"
	SetVariable setvar_combine_formula_T6,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable setvar_combine_formula_T6,userdata(ResizeControlsInfo)= A"!!,J&J,hr7!!#C:J,hlsz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_combine_formula_T6,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable setvar_combine_formula_T6,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable setvar_combine_formula_T6,limits={-inf,inf,0},value= _STR:""
	CheckBox check_FlipEpoch_S98,pos={118.00,139.00},size={35.00,15.00},proc=WBP_CheckProc,title="Flip"
	CheckBox check_FlipEpoch_S98,help={"Flip the whole stim set in the time domain"}
	CheckBox check_FlipEpoch_S98,userdata(ResizeControlsInfo)= A"!!,FQ!!#@o!!#=o!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_FlipEpoch_S98,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_FlipEpoch_S98,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox check_FlipEpoch_S98,value= 0
	Button button_af_jump_to_proc,pos={18.00,241.00},size={135.00,22.00},proc=WBP_ButtonProc_OpenAnaFuncs,title="Open procedure file"
	Button button_af_jump_to_proc,help={"Open the procedure where the analysis functions have to be defined"}
	Button button_af_jump_to_proc,userdata(ResizeControlsInfo)= A"!!,BI!!#B+!!#@k!!#<hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_af_jump_to_proc,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	Button button_af_jump_to_proc,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	PopupMenu popup_WaveBuilder_trig_type_P53,pos={878.00,190.00},size={48.00,19.00},bodyWidth=48,disable=1,proc=WBP_PopupMenu
	PopupMenu popup_WaveBuilder_trig_type_P53,help={"Type of trigonometric function"}
	PopupMenu popup_WaveBuilder_trig_type_P53,userdata(tabcontrol)=  "WBP_WaveType"
	PopupMenu popup_WaveBuilder_trig_type_P53,userdata(ResizeControlsInfo)= A"!!,JlJ,hr#!!#>N!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu popup_WaveBuilder_trig_type_P53,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu popup_WaveBuilder_trig_type_P53,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu popup_WaveBuilder_trig_type_P53,userdata(tabnum)=  "3"
	PopupMenu popup_WaveBuilder_trig_type_P53,mode=1,popvalue="Sin",value= #"\"Sin;Cos\""
	PopupMenu popup_WaveBuilder_build_res_P55,pos={884.00,121.00},size={129.00,19.00},bodyWidth=40,disable=1,proc=WBP_PopupMenu,title="Build Resolution"
	PopupMenu popup_WaveBuilder_build_res_P55,help={"*Experimental*: Changes the resolution of the frequency spectra serving as input for the time-domain output. Requires a lot of RAM!"}
	PopupMenu popup_WaveBuilder_build_res_P55,userdata(tabnum)=  "2"
	PopupMenu popup_WaveBuilder_build_res_P55,userdata(tabcontrol)=  "WBP_WaveType"
	PopupMenu popup_WaveBuilder_build_res_P55,userdata(ResizeControlsInfo)= A"!!,Jn!!#@V!!#@e!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu popup_WaveBuilder_build_res_P55,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu popup_WaveBuilder_build_res_P55,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu popup_WaveBuilder_build_res_P55,mode=1,popvalue="1",value= #"WBP_GetNoiseBuildResolution()"
	SetVariable SetVar_WaveBuilder_P26,pos={352.00,173.00},size={113.00,18.00},bodyWidth=50,disable=3,proc=WBP_SetVarProc_UpdateParam,title="Filter Order"
	SetVariable SetVar_WaveBuilder_P26,help={"Order of the Butterworth filter, see also DisplayHelpTopic `FilterIIR`"}
	SetVariable SetVar_WaveBuilder_P26,userdata(tabnum)=  "2"
	SetVariable SetVar_WaveBuilder_P26,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P26,userdata(ResizeControlsInfo)= A"!!,Hk!!#A<!!#@F!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P26,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P26,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P26,limits={1,100,1},value= _NUM:0
	SetVariable SetVar_WaveBuilder_P27,pos={471.00,173.00},size={100.00,18.00},disable=1,proc=WBP_SetVarProc_UpdateParam,title="Delta"
	SetVariable SetVar_WaveBuilder_P27,help={"Filter order delta."}
	SetVariable SetVar_WaveBuilder_P27,userdata(tabnum)=  "2"
	SetVariable SetVar_WaveBuilder_P27,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P27,userdata(ResizeControlsInfo)= A"!!,IQJ,hqg!!#@,!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P27,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P27,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P27,limits={-inf,99999,1},value= _NUM:0
	PopupMenu popup_WaveBuilder_exp_P56,pos={880.00,165.00},size={58.00,19.00},disable=1,proc=WBP_PopupMenu
	PopupMenu popup_WaveBuilder_exp_P56,help={"Pulse train type"}
	PopupMenu popup_WaveBuilder_exp_P56,userdata(tabnum)=  "5"
	PopupMenu popup_WaveBuilder_exp_P56,userdata(tabcontrol)=  "WBP_WaveType"
	PopupMenu popup_WaveBuilder_exp_P56,userdata(ResizeControlsInfo)= A"!!,Jm!!#A4!!#?!!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu popup_WaveBuilder_exp_P56,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu popup_WaveBuilder_exp_P56,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu popup_WaveBuilder_exp_P56,mode=1,popvalue="Square",value= #"\"Square;Triangle\""
	CheckBox check_NewSeedForEachSweep_P49_0,pos={880.00,57.00},size={86.00,15.00},disable=3,proc=WBP_CheckProc,title="Seed / Sweep"
	CheckBox check_NewSeedForEachSweep_P49_0,help={"When checked, the random number generator (RNG) seed is updated with each sweep. Seeds are saved with the stimulus."}
	CheckBox check_NewSeedForEachSweep_P49_0,userdata(tabnum)=  "5"
	CheckBox check_NewSeedForEachSweep_P49_0,userdata(tabcontrol)=  "WBP_WaveType"
	CheckBox check_NewSeedForEachSweep_P49_0,userdata(ResizeControlsInfo)= A"!!,Jm!!#>r!!#?e!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_NewSeedForEachSweep_P49_0,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_NewSeedForEachSweep_P49_0,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox check_NewSeedForEachSweep_P49_0,value= 0
	Button button_NewSeed_P48_0,pos={880.00,98.00},size={72.00,20.00},disable=3,proc=WBP_ButtonProc_NewSeed,title="New Seed"
	Button button_NewSeed_P48_0,help={"Create a different epoch by changing the seed value of the PRNG "}
	Button button_NewSeed_P48_0,userdata(tabnum)=  "5"
	Button button_NewSeed_P48_0,userdata(tabcontrol)=  "WBP_WaveType"
	Button button_NewSeed_P48_0,userdata(ResizeControlsInfo)= A"!!,Jm!!#@(!!#?I!!#<Xz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_NewSeed_P48_0,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	Button button_NewSeed_P48_0,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P28,pos={365.00,194.00},size={100.00,18.00},disable=1,proc=WBP_SetVarProc_UpdateParam,title="First Freq"
	SetVariable SetVar_WaveBuilder_P28,userdata(tabnum)=  "5"
	SetVariable SetVar_WaveBuilder_P28,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P28,userdata(ResizeControlsInfo)= A"!!,HqJ,hr'!!#@,!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P28,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P28,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P28,value= _NUM:0
	SetVariable SetVar_WaveBuilder_P30,pos={365.00,214.00},size={100.00,18.00},disable=1,proc=WBP_SetVarProc_UpdateParam,title="Last Freq"
	SetVariable SetVar_WaveBuilder_P30,userdata(tabnum)=  "5"
	SetVariable SetVar_WaveBuilder_P30,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P30,userdata(ResizeControlsInfo)= A"!!,HqJ,hr;!!#@,!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P30,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P30,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P30,value= _NUM:0
	CheckBox check_SPT_MixedFreq_P41,pos={880.00,189.00},size={106.00,15.00},disable=1,proc=WBP_CheckProc,title="Mixed Frequency"
	CheckBox check_SPT_MixedFreq_P41,help={"Draw the pulses from a frequency range instead of only using a fixed frequency."}
	CheckBox check_SPT_MixedFreq_P41,userdata(tabnum)=  "5"
	CheckBox check_SPT_MixedFreq_P41,userdata(tabcontrol)=  "WBP_WaveType"
	CheckBox check_SPT_MixedFreq_P41,userdata(ResizeControlsInfo)= A"!!,Jm!!#AL!!#@8!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_SPT_MixedFreq_P41,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_SPT_MixedFreq_P41,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox check_SPT_MixedFreq_P41,value= 0
	SetVariable SetVar_WaveBuilder_P29,pos={471.00,193.00},size={100.00,18.00},disable=1,proc=WBP_SetVarProc_UpdateParam,title="Delta"
	SetVariable SetVar_WaveBuilder_P29,userdata(tabnum)=  "5"
	SetVariable SetVar_WaveBuilder_P29,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P29,userdata(ResizeControlsInfo)= A"!!,IQJ,hr&!!#@,!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P29,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P29,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P29,value= _NUM:0
	SetVariable SetVar_WaveBuilder_P31,pos={471.00,214.00},size={100.00,18.00},disable=1,proc=WBP_SetVarProc_UpdateParam,title="Delta"
	SetVariable SetVar_WaveBuilder_P31,userdata(tabnum)=  "5"
	SetVariable SetVar_WaveBuilder_P31,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P31,userdata(ResizeControlsInfo)= A"!!,IQJ,hr;!!#@,!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P31,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P31,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P31,value= _NUM:0
	CheckBox check_SPT_MixedFreqShuffle_P42,pos={880.00,211.00},size={89.00,15.00},disable=1,proc=WBP_CheckProc,title="Shuffle pulses"
	CheckBox check_SPT_MixedFreqShuffle_P42,help={"Shuffle the pulses"}
	CheckBox check_SPT_MixedFreqShuffle_P42,userdata(ResizeControlsInfo)= A"!!,Jm!!#Ab!!#?k!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_SPT_MixedFreqShuffle_P42,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_SPT_MixedFreqShuffle_P42,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox check_SPT_MixedFreqShuffle_P42,userdata(tabnum)=  "5"
	CheckBox check_SPT_MixedFreqShuffle_P42,userdata(tabcontrol)=  "WBP_WaveType"
	CheckBox check_SPT_MixedFreqShuffle_P42,value= 0
	Button button_NewStimsetSeed_S97,pos={62.00,138.00},size={53.00,19.00},proc=WBP_ButtonProc_NewSeed,title="Reseed"
	Button button_NewStimsetSeed_S97,help={"Reseed the pseudo RNG for epochs using the global seed."}
	Button button_NewStimsetSeed_S97,userdata(ResizeControlsInfo)= A"!!,E2!!#@n!!#>b!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_NewStimsetSeed_S97,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	Button button_NewStimsetSeed_S97,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox check_UseStimsetSeed_P39,pos={884.00,195.00},size={121.00,15.00},disable=1,proc=WBP_CheckProc,title="Epoch/Stimset Seed"
	CheckBox check_UseStimsetSeed_P39,help={"Use the per-epoch random number generator (RNG) seed (checked) or use the stimset seed (unchecked).<br>Seeds are saved with the stimulus."}
	CheckBox check_UseStimsetSeed_P39,userdata(tabnum)=  "2"
	CheckBox check_UseStimsetSeed_P39,userdata(tabcontrol)=  "WBP_WaveType"
	CheckBox check_UseStimsetSeed_P39,userdata(ResizeControlsInfo)= A"!!,Jn!!#AR!!#@V!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_UseStimsetSeed_P39,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_UseStimsetSeed_P39,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox check_UseStimsetSeed_P39,value= 1
	CheckBox check_UseEpochSeed_P39_0,pos={880.00,79.00},size={121.00,15.00},disable=3,proc=WBP_CheckProc,title="Epoch/Stimset Seed"
	CheckBox check_UseEpochSeed_P39_0,help={"Use the per-epoch random number generator (RNG) seed (checked) or use the stimset seed (unchecked).<br>Seeds are saved with the stimulus."}
	CheckBox check_UseEpochSeed_P39_0,userdata(tabnum)=  "5"
	CheckBox check_UseEpochSeed_P39_0,userdata(tabcontrol)=  "WBP_WaveType"
	CheckBox check_UseEpochSeed_P39_0,userdata(ResizeControlsInfo)= A"!!,Jm!!#?W!!#@V!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_UseEpochSeed_P39_0,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_UseEpochSeed_P39_0,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox check_UseEpochSeed_P39_0,value= 1
	CheckBox check_allow_saving_builtin_nam,pos={28.00,290.00},size={116.00,15.00},title="Allow reserv. name"
	CheckBox check_allow_saving_builtin_nam,help={"Stimsets starting with \"_MIES\" are treated as special builtin stimsets and can only be saved if this checkbox is checked."}
	CheckBox check_allow_saving_builtin_nam,userdata(ResizeControlsInfo)= A"!!,CD!!#BK!!#@L!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_allow_saving_builtin_nam,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_allow_saving_builtin_nam,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox check_allow_saving_builtin_nam,value= 0
	PopupMenu popup_af_generic_S9,pos={16.00,191.00},size={143.00,19.00},bodyWidth=100,proc=WBP_PopupMenu_AnalysisFunctions,title="Generic"
	PopupMenu popup_af_generic_S9,help={"Generic analysis function (V3 and above only) which will be called for all events"}
	PopupMenu popup_af_generic_S9,userdata(ResizeControlsInfo)= A"!!,B9!!#AN!!#@s!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu popup_af_generic_S9,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	PopupMenu popup_af_generic_S9,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	PopupMenu popup_af_generic_S9,mode=1,popvalue="- none -",value= #"WBP_GetAnalysisFunctions_V3()"
	Button button_toggle_params,pos={18.00,214.00},size={137.00,23.00},proc=WBP_ButtonProc_OpenAnaParamGUI,title="Open parameters panel"
	Button button_toggle_params,userdata(ResizeControlsInfo)= A"!!,BI!!#Ae!!#@m!!#<pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_toggle_params,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	Button button_toggle_params,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	PopupMenu popup_WaveBuilder_op_P70,pos={635.00,74.00},size={75.00,19.00},bodyWidth=75,proc=WBP_PopupMenu
	PopupMenu popup_WaveBuilder_op_P70,help={"<html><ul><li>None: No delta</li><li>mult: delta *= mult</li><li>Logarithmic: delta = log(delta)</li><li>Squared: delta = delta^2</li><li>Power: delta = delta^(mult)</li><li>Alternate: delta *= -1</li><li>Explicit: delta = listitem</li></ul></html>"}
	PopupMenu popup_WaveBuilder_op_P70,userdata(ResizeControlsInfo)= A"!!,J/^]6]c!!#?O!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu popup_WaveBuilder_op_P70,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	PopupMenu popup_WaveBuilder_op_P70,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	PopupMenu popup_WaveBuilder_op_P70,mode=1,popvalue="None",value= #"\"None;Multiplier;Log;Squared;Power;Alternate;Explicit\""
	PopupMenu popup_WaveBuilder_op_P71,pos={635.00,99.00},size={75.00,19.00},bodyWidth=75,disable=1,proc=WBP_PopupMenu
	PopupMenu popup_WaveBuilder_op_P71,help={"<html><ul><li>None: No delta</li><li>mult: delta *= mult</li><li>Logarithmic: delta = log(delta)</li><li>Squared: delta = delta^2</li><li>Power: delta = delta^(mult)</li><li>Alternate: delta *= -1</li><li>Explicit: delta = listitem</li></ul></html>"}
	PopupMenu popup_WaveBuilder_op_P71,userdata(ResizeControlsInfo)= A"!!,J/^]6^@!!#?O!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu popup_WaveBuilder_op_P71,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	PopupMenu popup_WaveBuilder_op_P71,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	PopupMenu popup_WaveBuilder_op_P71,mode=1,popvalue="None",value= #"\"None;Multiplier;Log;Squared;Power;Alternate;Explicit\""
	SetVariable SetVar_WB_DurDeltaMult_P63,pos={575.00,124.00},size={55.00,18.00},disable=3,proc=WBP_SetVarProc_UpdateParam,title="* "
	SetVariable SetVar_WB_DurDeltaMult_P63,help={"Epoch duration delta multiplier or exponent."}
	SetVariable SetVar_WB_DurDeltaMult_P63,userdata(tabnum)=  "2"
	SetVariable SetVar_WB_DurDeltaMult_P63,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WB_DurDeltaMult_P63,userdata(ResizeControlsInfo)= A"!!,Iu^]6^r!!#>j!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WB_DurDeltaMult_P63,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable SetVar_WB_DurDeltaMult_P63,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WB_DurDeltaMult_P63,value= _NUM:0
	SetVariable SetVar_WB_AmpDeltaMult_P64,pos={575.00,148.00},size={55.00,18.00},disable=3,proc=WBP_SetVarProc_UpdateParam,title="* "
	SetVariable SetVar_WB_AmpDeltaMult_P64,help={"Epoch amplitude delta multiplier or exponent."}
	SetVariable SetVar_WB_AmpDeltaMult_P64,userdata(tabnum)=  "2"
	SetVariable SetVar_WB_AmpDeltaMult_P64,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WB_AmpDeltaMult_P64,userdata(ResizeControlsInfo)= A"!!,Iu^]6_9!!#>j!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WB_AmpDeltaMult_P64,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable SetVar_WB_AmpDeltaMult_P64,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WB_AmpDeltaMult_P64,value= _NUM:0
	SetVariable SetVar_WB_DeltaMult_P66,pos={575.00,172.00},size={55.00,18.00},disable=3,proc=WBP_SetVarProc_UpdateParam,title="* "
	SetVariable SetVar_WB_DeltaMult_P66,userdata(tabnum)=  "2"
	SetVariable SetVar_WB_DeltaMult_P66,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WB_DeltaMult_P66,userdata(ResizeControlsInfo)= A"!!,Iu^]6_Q!!#>j!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WB_DeltaMult_P66,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable SetVar_WB_DeltaMult_P66,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WB_DeltaMult_P66,value= _NUM:0
	PopupMenu popup_WaveBuilder_op_P82,pos={635.00,171.00},size={75.00,19.00},bodyWidth=75,disable=1,proc=WBP_PopupMenu
	PopupMenu popup_WaveBuilder_op_P82,help={"Delta operation"}
	PopupMenu popup_WaveBuilder_op_P82,userdata(tabnum)=  "2"
	PopupMenu popup_WaveBuilder_op_P82,userdata(tabcontrol)=  "WBP_WaveType"
	PopupMenu popup_WaveBuilder_op_P82,userdata(ResizeControlsInfo)= A"!!,J/^]6_P!!#?O!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu popup_WaveBuilder_op_P82,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	PopupMenu popup_WaveBuilder_op_P82,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	PopupMenu popup_WaveBuilder_op_P82,mode=1,popvalue="None",value= #"\"None;Multiplier;Log;Squared;Power;Alternate;Explicit\""
	PopupMenu popup_WaveBuilder_op_P80,pos={635.00,147.00},size={75.00,19.00},bodyWidth=75,disable=1,proc=WBP_PopupMenu
	PopupMenu popup_WaveBuilder_op_P80,help={"Delta operation"}
	PopupMenu popup_WaveBuilder_op_P80,userdata(tabnum)=  "2"
	PopupMenu popup_WaveBuilder_op_P80,userdata(tabcontrol)=  "WBP_WaveType"
	PopupMenu popup_WaveBuilder_op_P80,userdata(ResizeControlsInfo)= A"!!,J/^]6_8!!#?O!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu popup_WaveBuilder_op_P80,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	PopupMenu popup_WaveBuilder_op_P80,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	PopupMenu popup_WaveBuilder_op_P80,mode=1,popvalue="None",value= #"\"None;Multiplier;Log;Squared;Power;Alternate;Explicit\""
	PopupMenu popup_WaveBuilder_op_P79,pos={635.00,123.00},size={75.00,19.00},bodyWidth=75,disable=1,proc=WBP_PopupMenu
	PopupMenu popup_WaveBuilder_op_P79,help={"Delta operation"}
	PopupMenu popup_WaveBuilder_op_P79,userdata(tabnum)=  "2"
	PopupMenu popup_WaveBuilder_op_P79,userdata(tabcontrol)=  "WBP_WaveType"
	PopupMenu popup_WaveBuilder_op_P79,userdata(ResizeControlsInfo)= A"!!,J/^]6^p!!#?O!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu popup_WaveBuilder_op_P79,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	PopupMenu popup_WaveBuilder_op_P79,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	PopupMenu popup_WaveBuilder_op_P79,mode=1,popvalue="None",value= #"\"None;Multiplier;Log;Squared;Power;Alternate;Explicit\""
	SetVariable SetVar_WB_DeltaMult_P57,pos={574.00,122.00},size={55.00,18.00},disable=3,proc=WBP_SetVarProc_UpdateParam,title="* "
	SetVariable SetVar_WB_DeltaMult_P57,userdata(tabnum)=  "3"
	SetVariable SetVar_WB_DeltaMult_P57,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WB_DeltaMult_P57,userdata(ResizeControlsInfo)= A"!!,IuJ,hq.!!#>j!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WB_DeltaMult_P57,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable SetVar_WB_DeltaMult_P57,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WB_DeltaMult_P57,value= _NUM:0
	SetVariable SetVar_WB_DeltaMult_P65,pos={574.00,146.00},size={55.00,18.00},disable=3,proc=WBP_SetVarProc_UpdateParam,title="* "
	SetVariable SetVar_WB_DeltaMult_P65,userdata(tabnum)=  "3"
	SetVariable SetVar_WB_DeltaMult_P65,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WB_DeltaMult_P65,userdata(ResizeControlsInfo)= A"!!,IuJ,hqL!!#>j!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WB_DeltaMult_P65,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable SetVar_WB_DeltaMult_P65,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WB_DeltaMult_P65,value= _NUM:0
	PopupMenu popup_WaveBuilder_op_P81,pos={634.00,145.00},size={75.00,19.00},bodyWidth=75,disable=3,proc=WBP_PopupMenu
	PopupMenu popup_WaveBuilder_op_P81,help={"Delta operation"}
	PopupMenu popup_WaveBuilder_op_P81,userdata(tabnum)=  "3"
	PopupMenu popup_WaveBuilder_op_P81,userdata(tabcontrol)=  "WBP_WaveType"
	PopupMenu popup_WaveBuilder_op_P81,userdata(ResizeControlsInfo)= A"!!,J/J,hqK!!#?O!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu popup_WaveBuilder_op_P81,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	PopupMenu popup_WaveBuilder_op_P81,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	PopupMenu popup_WaveBuilder_op_P81,mode=1,popvalue="None",value= #"\"None;Multiplier;Log;Squared;Power;Alternate;Explicit\""
	SetVariable SetVar_WB_DeltaMult_P57_DD01,pos={573.00,123.00},size={55.00,18.00},disable=3,proc=WBP_SetVarProc_UpdateParam,title="* "
	SetVariable SetVar_WB_DeltaMult_P57_DD01,userdata(tabnum)=  "5"
	SetVariable SetVar_WB_DeltaMult_P57_DD01,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WB_DeltaMult_P57_DD01,userdata(ResizeControlsInfo)= A"!!,Iu5QF.E!!#>j!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WB_DeltaMult_P57_DD01,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable SetVar_WB_DeltaMult_P57_DD01,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WB_DeltaMult_P57_DD01,value= _NUM:0
	PopupMenu popup_WaveBuilder_op_P73,pos={635.00,122.00},size={75.00,19.00},bodyWidth=75,disable=1,proc=WBP_PopupMenu
	PopupMenu popup_WaveBuilder_op_P73,help={"<html><ul><li>None: No delta</li><li>mult: delta *= mult</li><li>Logarithmic: delta = log(delta)</li><li>Squared: delta = delta^2</li><li>Power: delta = delta^(mult)</li><li>Alternate: delta *= -1</li><li>Explicit: delta = listitem</li></ul></html>"}
	PopupMenu popup_WaveBuilder_op_P73,userdata(tabnum)=  "5"
	PopupMenu popup_WaveBuilder_op_P73,userdata(tabcontrol)=  "WBP_WaveType"
	PopupMenu popup_WaveBuilder_op_P73,userdata(ResizeControlsInfo)= A"!!,J/^]6^n!!#?O!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu popup_WaveBuilder_op_P73,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	PopupMenu popup_WaveBuilder_op_P73,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	PopupMenu popup_WaveBuilder_op_P73,mode=1,popvalue="None",value= #"\"None;Multiplier;Log;Squared;Power;Alternate;Explicit\""
	SetVariable SetVar_WB_DeltaMult_P58,pos={573.00,146.00},size={55.00,18.00},disable=3,proc=WBP_SetVarProc_UpdateParam,title="* "
	SetVariable SetVar_WB_DeltaMult_P58,userdata(tabnum)=  "5"
	SetVariable SetVar_WB_DeltaMult_P58,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WB_DeltaMult_P58,userdata(ResizeControlsInfo)= A"!!,Iu5QF.a!!#>j!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WB_DeltaMult_P58,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable SetVar_WB_DeltaMult_P58,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WB_DeltaMult_P58,value= _NUM:0
	PopupMenu popup_WaveBuilder_op_P74,pos={635.00,145.00},size={75.00,19.00},bodyWidth=75,disable=1,proc=WBP_PopupMenu
	PopupMenu popup_WaveBuilder_op_P74,help={"<html><ul><li>None: No delta</li><li>mult: delta *= mult</li><li>Logarithmic: delta = log(delta)</li><li>Squared: delta = delta^2</li><li>Power: delta = delta^(mult)</li><li>Alternate: delta *= -1</li><li>Explicit: delta = listitem</li></ul></html>"}
	PopupMenu popup_WaveBuilder_op_P74,userdata(tabnum)=  "5"
	PopupMenu popup_WaveBuilder_op_P74,userdata(tabcontrol)=  "WBP_WaveType"
	PopupMenu popup_WaveBuilder_op_P74,userdata(ResizeControlsInfo)= A"!!,J/^]6_6!!#?O!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu popup_WaveBuilder_op_P74,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	PopupMenu popup_WaveBuilder_op_P74,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	PopupMenu popup_WaveBuilder_op_P74,mode=1,popvalue="None",value= #"\"None;Multiplier;Log;Squared;Power;Alternate;Explicit\""
	SetVariable SetVar_WB_DeltaMult_P69,pos={573.00,169.00},size={55.00,18.00},disable=3,proc=WBP_SetVarProc_UpdateParam,title="* "
	SetVariable SetVar_WB_DeltaMult_P69,userdata(tabnum)=  "5"
	SetVariable SetVar_WB_DeltaMult_P69,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WB_DeltaMult_P69,userdata(ResizeControlsInfo)= A"!!,Iu5QF/#!!#>j!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WB_DeltaMult_P69,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable SetVar_WB_DeltaMult_P69,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WB_DeltaMult_P69,value= _NUM:0
	PopupMenu popup_WaveBuilder_op_P85,pos={635.00,168.00},size={75.00,19.00},bodyWidth=75,disable=3,proc=WBP_PopupMenu
	PopupMenu popup_WaveBuilder_op_P85,help={"<html><ul><li>None: No delta</li><li>mult: delta *= mult</li><li>Logarithmic: delta = log(delta)</li><li>Squared: delta = delta^2</li><li>Power: delta = delta^(mult)</li><li>Alternate: delta *= -1</li><li>Explicit: delta = listitem</li></ul></html>"}
	PopupMenu popup_WaveBuilder_op_P85,userdata(tabnum)=  "5"
	PopupMenu popup_WaveBuilder_op_P85,userdata(tabcontrol)=  "WBP_WaveType"
	PopupMenu popup_WaveBuilder_op_P85,userdata(ResizeControlsInfo)= A"!!,J/^]6_M!!#?O!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu popup_WaveBuilder_op_P85,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	PopupMenu popup_WaveBuilder_op_P85,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	PopupMenu popup_WaveBuilder_op_P85,mode=1,popvalue="None",value= #"\"None;Multiplier;Log;Squared;Power;Alternate;Explicit\""
	SetVariable SetVar_WB_DeltaMult_P67,pos={573.00,192.00},size={55.00,18.00},disable=3,proc=WBP_SetVarProc_UpdateParam,title="* "
	SetVariable SetVar_WB_DeltaMult_P67,userdata(tabnum)=  "5"
	SetVariable SetVar_WB_DeltaMult_P67,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WB_DeltaMult_P67,userdata(ResizeControlsInfo)= A"!!,Iu5QF/:!!#>j!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WB_DeltaMult_P67,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable SetVar_WB_DeltaMult_P67,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WB_DeltaMult_P67,value= _NUM:0
	PopupMenu popup_WaveBuilder_op_P83,pos={635.00,191.00},size={75.00,19.00},bodyWidth=75,disable=1,proc=WBP_PopupMenu
	PopupMenu popup_WaveBuilder_op_P83,help={"<html><ul><li>None: No delta</li><li>mult: delta *= mult</li><li>Logarithmic: delta = log(delta)</li><li>Squared: delta = delta^2</li><li>Power: delta = delta^(mult)</li><li>Alternate: delta *= -1</li><li>Explicit: delta = listitem</li></ul></html>"}
	PopupMenu popup_WaveBuilder_op_P83,userdata(tabnum)=  "5"
	PopupMenu popup_WaveBuilder_op_P83,userdata(tabcontrol)=  "WBP_WaveType"
	PopupMenu popup_WaveBuilder_op_P83,userdata(ResizeControlsInfo)= A"!!,J/^]6_d!!#?O!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu popup_WaveBuilder_op_P83,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	PopupMenu popup_WaveBuilder_op_P83,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	PopupMenu popup_WaveBuilder_op_P83,mode=1,popvalue="None",value= #"\"None;Multiplier;Log;Squared;Power;Alternate;Explicit\""
	SetVariable SetVar_WB_DeltaMult_P68,pos={573.00,215.00},size={55.00,18.00},disable=3,proc=WBP_SetVarProc_UpdateParam,title="* "
	SetVariable SetVar_WB_DeltaMult_P68,userdata(tabnum)=  "5"
	SetVariable SetVar_WB_DeltaMult_P68,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WB_DeltaMult_P68,userdata(ResizeControlsInfo)= A"!!,Iu5QF/Q!!#>j!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WB_DeltaMult_P68,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable SetVar_WB_DeltaMult_P68,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WB_DeltaMult_P68,value= _NUM:0
	PopupMenu popup_WaveBuilder_op_P84,pos={635.00,215.00},size={75.00,19.00},bodyWidth=75,disable=1,proc=WBP_PopupMenu
	PopupMenu popup_WaveBuilder_op_P84,help={"<html><ul><li>None: No delta</li><li>mult: delta *= mult</li><li>Logarithmic: delta = log(delta)</li><li>Squared: delta = delta^2</li><li>Power: delta = delta^(mult)</li><li>Alternate: delta *= -1</li><li>Explicit: delta = listitem</li></ul></html>"}
	PopupMenu popup_WaveBuilder_op_P84,userdata(tabnum)=  "5"
	PopupMenu popup_WaveBuilder_op_P84,userdata(tabcontrol)=  "WBP_WaveType"
	PopupMenu popup_WaveBuilder_op_P84,userdata(ResizeControlsInfo)= A"!!,J/^]6`'!!#?O!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu popup_WaveBuilder_op_P84,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	PopupMenu popup_WaveBuilder_op_P84,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	PopupMenu popup_WaveBuilder_op_P84,mode=1,popvalue="None",value= #"\"None;Multiplier;Log;Squared;Power;Alternate;Explicit\""
	SetVariable SetVar_WB_DeltaMult_P57_03,pos={574.00,123.00},size={55.00,18.00},disable=3,proc=WBP_SetVarProc_UpdateParam,title="* "
	SetVariable SetVar_WB_DeltaMult_P57_03,userdata(tabnum)=  "4"
	SetVariable SetVar_WB_DeltaMult_P57_03,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WB_DeltaMult_P57_03,userdata(ResizeControlsInfo)= A"!!,IuJ,hq0!!#>j!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WB_DeltaMult_P57_03,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable SetVar_WB_DeltaMult_P57_03,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WB_DeltaMult_P57_03,value= _NUM:0
	PopupMenu popup_WaveBuilder_op_P73_1,pos={635.00,123.00},size={75.00,19.00},bodyWidth=75,disable=1,proc=WBP_PopupMenu
	PopupMenu popup_WaveBuilder_op_P73_1,help={"Delta operation"}
	PopupMenu popup_WaveBuilder_op_P73_1,userdata(tabnum)=  "4"
	PopupMenu popup_WaveBuilder_op_P73_1,userdata(tabcontrol)=  "WBP_WaveType"
	PopupMenu popup_WaveBuilder_op_P73_1,userdata(ResizeControlsInfo)= A"!!,J/^]6^p!!#?O!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu popup_WaveBuilder_op_P73_1,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	PopupMenu popup_WaveBuilder_op_P73_1,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	PopupMenu popup_WaveBuilder_op_P73_1,mode=1,popvalue="None",value= #"\"None;Multiplier;Log;Squared;Power;Alternate;Explicit\""
	PopupMenu popup_WaveBuilder_op_P73_2,pos={634.00,121.00},size={75.00,19.00},bodyWidth=75,disable=1,proc=WBP_PopupMenu
	PopupMenu popup_WaveBuilder_op_P73_2,help={"Delta operation"}
	PopupMenu popup_WaveBuilder_op_P73_2,userdata(tabnum)=  "3"
	PopupMenu popup_WaveBuilder_op_P73_2,userdata(tabcontrol)=  "WBP_WaveType"
	PopupMenu popup_WaveBuilder_op_P73_2,userdata(ResizeControlsInfo)= A"!!,J/J,hq,!!#?O!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu popup_WaveBuilder_op_P73_2,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	PopupMenu popup_WaveBuilder_op_P73_2,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	PopupMenu popup_WaveBuilder_op_P73_2,mode=1,popvalue="None",value= #"\"None;Multiplier;Log;Squared;Power;Alternate;Explicit\""
	SetVariable SetVar_WB_DeltaMult_P60,pos={571.00,145.00},size={57.00,18.00},disable=3,proc=WBP_SetVarProc_UpdateParam,title="* "
	SetVariable SetVar_WB_DeltaMult_P60,userdata(tabnum)=  "6"
	SetVariable SetVar_WB_DeltaMult_P60,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WB_DeltaMult_P60,userdata(ResizeControlsInfo)= A"!!,It^]6_6!!#>r!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WB_DeltaMult_P60,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable SetVar_WB_DeltaMult_P60,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WB_DeltaMult_P60,value= _NUM:0
	PopupMenu popup_WaveBuilder_op_P76,pos={635.00,144.00},size={75.00,19.00},bodyWidth=75,disable=1,proc=WBP_PopupMenu
	PopupMenu popup_WaveBuilder_op_P76,help={"Delta operation"}
	PopupMenu popup_WaveBuilder_op_P76,userdata(tabnum)=  "6"
	PopupMenu popup_WaveBuilder_op_P76,userdata(tabcontrol)=  "WBP_WaveType"
	PopupMenu popup_WaveBuilder_op_P76,userdata(ResizeControlsInfo)= A"!!,J/^]6_5!!#?O!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu popup_WaveBuilder_op_P76,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	PopupMenu popup_WaveBuilder_op_P76,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	PopupMenu popup_WaveBuilder_op_P76,mode=1,popvalue="None",value= #"\"None;Multiplier;Log;Squared;Power;Alternate;Explicit\""
	SetVariable SetVar_WB_DeltaMult_P61,pos={571.00,168.00},size={57.00,18.00},disable=3,proc=WBP_SetVarProc_UpdateParam,title="* "
	SetVariable SetVar_WB_DeltaMult_P61,userdata(tabnum)=  "6"
	SetVariable SetVar_WB_DeltaMult_P61,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WB_DeltaMult_P61,userdata(ResizeControlsInfo)= A"!!,It^]6_M!!#>r!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WB_DeltaMult_P61,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable SetVar_WB_DeltaMult_P61,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WB_DeltaMult_P61,value= _NUM:0
	PopupMenu popup_WaveBuilder_op_P77,pos={635.00,167.00},size={75.00,19.00},bodyWidth=75,disable=1,proc=WBP_PopupMenu
	PopupMenu popup_WaveBuilder_op_P77,help={"Delta operation"}
	PopupMenu popup_WaveBuilder_op_P77,userdata(tabnum)=  "6"
	PopupMenu popup_WaveBuilder_op_P77,userdata(tabcontrol)=  "WBP_WaveType"
	PopupMenu popup_WaveBuilder_op_P77,userdata(ResizeControlsInfo)= A"!!,J/^]6_L!!#?O!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu popup_WaveBuilder_op_P77,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	PopupMenu popup_WaveBuilder_op_P77,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	PopupMenu popup_WaveBuilder_op_P77,mode=1,popvalue="None",value= #"\"None;Multiplier;Log;Squared;Power;Alternate;Explicit\""
	SetVariable SetVar_WB_DeltaMult_P62,pos={571.00,192.00},size={57.00,18.00},disable=3,proc=WBP_SetVarProc_UpdateParam,title="* "
	SetVariable SetVar_WB_DeltaMult_P62,userdata(tabnum)=  "6"
	SetVariable SetVar_WB_DeltaMult_P62,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WB_DeltaMult_P62,userdata(ResizeControlsInfo)= A"!!,It^]6_e!!#>r!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WB_DeltaMult_P62,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable SetVar_WB_DeltaMult_P62,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WB_DeltaMult_P62,value= _NUM:0
	PopupMenu popup_WaveBuilder_op_P78,pos={635.00,191.00},size={75.00,19.00},bodyWidth=75,disable=1,proc=WBP_PopupMenu
	PopupMenu popup_WaveBuilder_op_P78,help={"Delta operation"}
	PopupMenu popup_WaveBuilder_op_P78,userdata(tabnum)=  "6"
	PopupMenu popup_WaveBuilder_op_P78,userdata(tabcontrol)=  "WBP_WaveType"
	PopupMenu popup_WaveBuilder_op_P78,userdata(ResizeControlsInfo)= A"!!,J/^]6_d!!#?O!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu popup_WaveBuilder_op_P78,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	PopupMenu popup_WaveBuilder_op_P78,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	PopupMenu popup_WaveBuilder_op_P78,mode=1,popvalue="None",value= #"\"None;Multiplier;Log;Squared;Power;Alternate;Explicit\""
	SetVariable SetVar_WB_DeltaMult_P59,pos={571.00,122.00},size={57.00,18.00},disable=3,proc=WBP_SetVarProc_UpdateParam,title="* "
	SetVariable SetVar_WB_DeltaMult_P59,userdata(tabnum)=  "6"
	SetVariable SetVar_WB_DeltaMult_P59,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WB_DeltaMult_P59,userdata(ResizeControlsInfo)= A"!!,It^]6^n!!#>r!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WB_DeltaMult_P59,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable SetVar_WB_DeltaMult_P59,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WB_DeltaMult_P59,value= _NUM:0
	PopupMenu popup_WaveBuilder_op_P75_1,pos={635.00,121.00},size={75.00,19.00},bodyWidth=75,disable=1,proc=WBP_PopupMenu
	PopupMenu popup_WaveBuilder_op_P75_1,help={"Delta operation"}
	PopupMenu popup_WaveBuilder_op_P75_1,userdata(tabnum)=  "6"
	PopupMenu popup_WaveBuilder_op_P75_1,userdata(tabcontrol)=  "WBP_WaveType"
	PopupMenu popup_WaveBuilder_op_P75_1,userdata(ResizeControlsInfo)= A"!!,J/^]6^l!!#?O!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu popup_WaveBuilder_op_P75_1,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	PopupMenu popup_WaveBuilder_op_P75_1,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	PopupMenu popup_WaveBuilder_op_P75_1,mode=1,popvalue="None",value= #"\"None;Multiplier;Log;Squared;Power;Alternate;Explicit\""
	SetVariable setvar_explDeltaValues_T13,pos={717.00,52.00},size={149.00,18.00},disable=2,proc=WBP_SetVarProc_UpdateParam
	SetVariable setvar_explDeltaValues_T13,userdata(ResizeControlsInfo)= A"!!,JD5QF,I!!#A$!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_explDeltaValues_T13,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable setvar_explDeltaValues_T13,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable setvar_explDeltaValues_T13,value= _STR:""
	SetVariable setvar_explDeltaValues_T11,pos={717.00,75.00},size={149.00,18.00},disable=2,proc=WBP_SetVarProc_UpdateParam
	SetVariable setvar_explDeltaValues_T11,userdata(ResizeControlsInfo)= A"!!,JD5QF-:!!#A$!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_explDeltaValues_T11,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable setvar_explDeltaValues_T11,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable setvar_explDeltaValues_T11,value= _STR:""
	SetVariable setvar_explDeltaValues_T12,pos={557.00,81.00},size={149.00,18.00},disable=3,proc=WBP_SetVarProc_UpdateParam
	SetVariable setvar_explDeltaValues_T12,userdata(ResizeControlsInfo)= A"!!,Iq5QF-F!!#A$!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_explDeltaValues_T12,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable setvar_explDeltaValues_T12,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable setvar_explDeltaValues_T12,value= _STR:""
	SetVariable setvar_explDeltaValues_T20,pos={717.00,124.00},size={149.00,18.00},disable=3,proc=WBP_SetVarProc_UpdateParam
	SetVariable setvar_explDeltaValues_T20,userdata(tabnum)=  "2"
	SetVariable setvar_explDeltaValues_T20,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable setvar_explDeltaValues_T20,userdata(ResizeControlsInfo)= A"!!,JD5QF.G!!#A$!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_explDeltaValues_T20,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable setvar_explDeltaValues_T20,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable setvar_explDeltaValues_T20,value= _STR:""
	SetVariable setvar_explDeltaValues_T21,pos={717.00,148.00},size={149.00,18.00},disable=3,proc=WBP_SetVarProc_UpdateParam
	SetVariable setvar_explDeltaValues_T21,userdata(tabnum)=  "2"
	SetVariable setvar_explDeltaValues_T21,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable setvar_explDeltaValues_T21,userdata(ResizeControlsInfo)= A"!!,JD5QF.c!!#A$!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_explDeltaValues_T21,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable setvar_explDeltaValues_T21,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable setvar_explDeltaValues_T21,value= _STR:""
	SetVariable setvar_explDeltaValues_T23,pos={717.00,173.00},size={149.00,18.00},disable=3,proc=WBP_SetVarProc_UpdateParam
	SetVariable setvar_explDeltaValues_T23,userdata(tabnum)=  "2"
	SetVariable setvar_explDeltaValues_T23,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable setvar_explDeltaValues_T23,userdata(ResizeControlsInfo)= A"!!,JD5QF/'!!#A$!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_explDeltaValues_T23,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable setvar_explDeltaValues_T23,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable setvar_explDeltaValues_T23,value= _STR:""
	SetVariable setvar_explDeltaValues_T14,pos={716.00,122.00},size={149.00,18.00},disable=3,proc=WBP_SetVarProc_UpdateParam
	SetVariable setvar_explDeltaValues_T14,userdata(tabnum)=  "3"
	SetVariable setvar_explDeltaValues_T14,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable setvar_explDeltaValues_T14,userdata(ResizeControlsInfo)= A"!!,JD!!#@X!!#A$!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_explDeltaValues_T14,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable setvar_explDeltaValues_T14,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable setvar_explDeltaValues_T14,value= _STR:""
	SetVariable setvar_explDeltaValues_T22,pos={716.00,146.00},size={149.00,18.00},disable=3,proc=WBP_SetVarProc_UpdateParam
	SetVariable setvar_explDeltaValues_T22,userdata(tabnum)=  "3"
	SetVariable setvar_explDeltaValues_T22,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable setvar_explDeltaValues_T22,userdata(ResizeControlsInfo)= A"!!,JD!!#A!!!#A$!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_explDeltaValues_T22,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable setvar_explDeltaValues_T22,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable setvar_explDeltaValues_T22,value= _STR:""
	SetVariable setvar_explDeltaValues_T14_DD01,pos={718.00,124.00},size={149.00,18.00},disable=3,proc=WBP_SetVarProc_UpdateParam
	SetVariable setvar_explDeltaValues_T14_DD01,userdata(tabnum)=  "4"
	SetVariable setvar_explDeltaValues_T14_DD01,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable setvar_explDeltaValues_T14_DD01,userdata(ResizeControlsInfo)= A"!!,JDJ,hq2!!#A$!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_explDeltaValues_T14_DD01,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable setvar_explDeltaValues_T14_DD01,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable setvar_explDeltaValues_T14_DD01,value= _STR:""
	SetVariable setvar_explDeltaValues_T14_FD01,pos={717.00,123.00},size={149.00,18.00},disable=3,proc=WBP_SetVarProc_UpdateParam
	SetVariable setvar_explDeltaValues_T14_FD01,userdata(tabnum)=  "5"
	SetVariable setvar_explDeltaValues_T14_FD01,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable setvar_explDeltaValues_T14_FD01,userdata(ResizeControlsInfo)= A"!!,JD5QF.E!!#A$!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_explDeltaValues_T14_FD01,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable setvar_explDeltaValues_T14_FD01,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable setvar_explDeltaValues_T14_FD01,value= _STR:""
	SetVariable setvar_explDeltaValues_T26,pos={717.00,169.00},size={149.00,18.00},disable=3,proc=WBP_SetVarProc_UpdateParam
	SetVariable setvar_explDeltaValues_T26,userdata(tabnum)=  "5"
	SetVariable setvar_explDeltaValues_T26,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable setvar_explDeltaValues_T26,userdata(ResizeControlsInfo)= A"!!,JD5QF/#!!#A$!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_explDeltaValues_T26,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable setvar_explDeltaValues_T26,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable setvar_explDeltaValues_T26,value= _STR:""
	SetVariable setvar_explDeltaValues_T15,pos={717.00,146.00},size={149.00,18.00},disable=3,proc=WBP_SetVarProc_UpdateParam
	SetVariable setvar_explDeltaValues_T15,userdata(tabnum)=  "5"
	SetVariable setvar_explDeltaValues_T15,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable setvar_explDeltaValues_T15,userdata(ResizeControlsInfo)= A"!!,JD5QF.a!!#A$!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_explDeltaValues_T15,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable setvar_explDeltaValues_T15,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable setvar_explDeltaValues_T15,value= _STR:""
	SetVariable setvar_explDeltaValues_T24,pos={717.00,192.00},size={149.00,18.00},disable=3,proc=WBP_SetVarProc_UpdateParam
	SetVariable setvar_explDeltaValues_T24,userdata(tabnum)=  "5"
	SetVariable setvar_explDeltaValues_T24,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable setvar_explDeltaValues_T24,userdata(ResizeControlsInfo)= A"!!,JD5QF/:!!#A$!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_explDeltaValues_T24,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable setvar_explDeltaValues_T24,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable setvar_explDeltaValues_T24,value= _STR:""
	SetVariable setvar_explDeltaValues_T25,pos={717.00,215.00},size={149.00,18.00},disable=3,proc=WBP_SetVarProc_UpdateParam
	SetVariable setvar_explDeltaValues_T25,userdata(tabnum)=  "5"
	SetVariable setvar_explDeltaValues_T25,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable setvar_explDeltaValues_T25,userdata(ResizeControlsInfo)= A"!!,JD5QF/Q!!#A$!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_explDeltaValues_T25,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable setvar_explDeltaValues_T25,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable setvar_explDeltaValues_T25,value= _STR:""
	SetVariable setvar_explDeltaValues_T16,pos={717.00,123.00},size={149.00,18.00},disable=3
	SetVariable setvar_explDeltaValues_T16,userdata(tabnum)=  "6"
	SetVariable setvar_explDeltaValues_T16,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable setvar_explDeltaValues_T16,userdata(ResizeControlsInfo)= A"!!,JD5QF.E!!#A$!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_explDeltaValues_T16,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable setvar_explDeltaValues_T16,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable setvar_explDeltaValues_T16,value= _STR:""
	SetVariable setvar_explDeltaValues_T17,pos={717.00,146.00},size={149.00,18.00},disable=3
	SetVariable setvar_explDeltaValues_T17,userdata(tabnum)=  "6"
	SetVariable setvar_explDeltaValues_T17,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable setvar_explDeltaValues_T17,userdata(ResizeControlsInfo)= A"!!,JD5QF.a!!#A$!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_explDeltaValues_T17,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable setvar_explDeltaValues_T17,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable setvar_explDeltaValues_T17,value= _STR:""
	SetVariable setvar_explDeltaValues_T18,pos={717.00,169.00},size={149.00,18.00},disable=3
	SetVariable setvar_explDeltaValues_T18,userdata(tabnum)=  "6"
	SetVariable setvar_explDeltaValues_T18,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable setvar_explDeltaValues_T18,userdata(ResizeControlsInfo)= A"!!,JD5QF/#!!#A$!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_explDeltaValues_T18,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable setvar_explDeltaValues_T18,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable setvar_explDeltaValues_T18,value= _STR:""
	SetVariable setvar_explDeltaValues_T19,pos={717.00,192.00},size={149.00,18.00},disable=3
	SetVariable setvar_explDeltaValues_T19,userdata(tabnum)=  "6"
	SetVariable setvar_explDeltaValues_T19,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable setvar_explDeltaValues_T19,userdata(ResizeControlsInfo)= A"!!,JD5QF/:!!#A$!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_explDeltaValues_T19,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable setvar_explDeltaValues_T19,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable setvar_explDeltaValues_T19,value= _STR:""
	PopupMenu popup_WaveBuilder_op_P72,pos={635.00,50.00},size={75.00,19.00},bodyWidth=75,proc=WBP_PopupMenu
	PopupMenu popup_WaveBuilder_op_P72,help={"<html><ul><li>None: No delta</li><li>mult: delta *= mult</li><li>Logarithmic: delta = log(delta)</li><li>Squared: delta = delta^2</li><li>Power: delta = delta^(mult)</li><li>Alternate: delta *= -1</li><li>Explicit: delta = listitem</li></ul></html>"}
	PopupMenu popup_WaveBuilder_op_P72,userdata(ResizeControlsInfo)= A"!!,J/^]6\\l!!#?O!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu popup_WaveBuilder_op_P72,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	PopupMenu popup_WaveBuilder_op_P72,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	PopupMenu popup_WaveBuilder_op_P72,mode=1,popvalue="None",value= #"\"None;Multiplier;Log;Squared;Power;Alternate;Explicit\""
	SetVariable setvar_explDeltaValues_T12_DD01,pos={724.00,54.00},size={149.00,18.00},disable=3,proc=WBP_SetVarProc_UpdateParam
	SetVariable setvar_explDeltaValues_T12_DD01,userdata(tabnum)=  "7"
	SetVariable setvar_explDeltaValues_T12_DD01,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable setvar_explDeltaValues_T12_DD01,userdata(ResizeControlsInfo)= A"!!,JF!!#>f!!#A$!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_explDeltaValues_T12_DD01,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable setvar_explDeltaValues_T12_DD01,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable setvar_explDeltaValues_T12_DD01,value= _STR:""
	SetVariable setvar_explDeltaValues_T12_DD02,pos={718.00,98.00},size={149.00,18.00},disable=3,proc=WBP_SetVarProc_UpdateParam
	SetVariable setvar_explDeltaValues_T12_DD02,userdata(ResizeControlsInfo)= A"!!,JDJ,hpS!!#A$!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_explDeltaValues_T12_DD02,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable setvar_explDeltaValues_T12_DD02,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable setvar_explDeltaValues_T12_DD02,value= _STR:""
	SetVariable SetVar_WaveBuilder_S96,pos={258.00,49.00},size={75.00,18.00},proc=WBP_SetVarProc_UpdateParam,title="Delta"
	SetVariable SetVar_WaveBuilder_S96,help={"Sweep to sweep duration delta."}
	SetVariable SetVar_WaveBuilder_S96,userdata(ResizeControlsInfo)= A"!!,H<!!#>R!!#?O!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_S96,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_S96,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_S96,value= _NUM:0
	SetVariable SetVar_WB_Multiplier_S95,pos={198.00,71.00},size={57.00,18.00},disable=2,proc=WBP_SetVarProc_UpdateParam,title="* "
	SetVariable SetVar_WB_Multiplier_S95,help={"Epoch duration delta multiplier or exponent."}
	SetVariable SetVar_WB_Multiplier_S95,userdata(ResizeControlsInfo)= A"!!,GV!!#?G!!#>r!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WB_Multiplier_S95,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable SetVar_WB_Multiplier_S95,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WB_Multiplier_S95,value= _NUM:0
	PopupMenu popup_WaveBuilder_op_S94,pos={258.00,71.00},size={75.00,19.00},bodyWidth=75,proc=WBP_PopupMenu
	PopupMenu popup_WaveBuilder_op_S94,help={"<html><ul><li>None: No delta</li><li>mult: delta *= mult</li><li>Logarithmic: delta = log(delta)</li><li>Squared: delta = delta^2</li><li>Power: delta = delta^(mult)</li><li>Alternate: delta *= -1</li><li>Explicit: delta = listitem</li></ul></html>"}
	PopupMenu popup_WaveBuilder_op_S94,userdata(ResizeControlsInfo)= A"!!,H<!!#?G!!#?O!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu popup_WaveBuilder_op_S94,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	PopupMenu popup_WaveBuilder_op_S94,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	PopupMenu popup_WaveBuilder_op_S94,mode=1,popvalue="None",value= #"\"None;Multiplier;Log;Squared;Power;Alternate;Explicit\""
	SetVariable setvar_explDeltaValues_T28_ALL,pos={209.00,94.00},size={125.00,18.00},disable=2,proc=WBP_SetVarProc_UpdateParam
	SetVariable setvar_explDeltaValues_T28_ALL,help={"Semi-colon separated list of ITI deltas\nITI is the sum of all previous deltas, plus the initial ITI.\nFirst list item is applied to the second ITI. i.e., second ITI = first list item + initial ITI."}
	SetVariable setvar_explDeltaValues_T28_ALL,userdata(ResizeControlsInfo)= A"!!,Ga!!#?u!!#@^!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_explDeltaValues_T28_ALL,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable setvar_explDeltaValues_T28_ALL,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable setvar_explDeltaValues_T28_ALL,value= _STR:""
	SetVariable SetVar_WaveBuilder_S99,pos={195.00,49.00},size={60.00,18.00},proc=WBP_SetVarProc_UpdateParam,title="ITI"
	SetVariable SetVar_WaveBuilder_S99,help={"Duration (ms) of the epoch being edited."}
	SetVariable SetVar_WaveBuilder_S99,userdata(ResizeControlsInfo)= A"!!,GS!!#>R!!#?)!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_S99,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_S99,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_S99,limits={0,inf,1},value= _NUM:0
	GroupBox group_anafunc_params,pos={12.00,170.00},size={160.00,99.00},title="Analysis functions"
	GroupBox group_anafunc_params,userdata(ResizeControlsInfo)= A"!!,AN!!#A9!!#A/!!#@*z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	GroupBox group_anafunc_params,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	GroupBox group_anafunc_params,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	GroupBox group_set_params,pos={13.00,29.00},size={160.00,137.00},title="Basic"
	GroupBox group_set_params,userdata(ResizeControlsInfo)= A"!!,A^!!#=K!!#A/!!#@mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	GroupBox group_set_params,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	GroupBox group_set_params,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	GroupBox group_save_set,pos={13.00,270.00},size={160.00,108.00},title="Saving"
	GroupBox group_save_set,userdata(ResizeControlsInfo)= A"!!,A^!!#BA!!#A/!!#@<z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	GroupBox group_save_set,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	GroupBox group_save_set,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	Button button_WaveBuilder_SaveSet1,pos={22.00,398.00},size={125.00,20.00},proc=WBP_ButtonProc_LoadSet,title="Load Set"
	Button button_WaveBuilder_SaveSet1,help={"Load the selected stimulus set"}
	Button button_WaveBuilder_SaveSet1,userdata(ResizeControlsInfo)= A"!!,Bi!!#C,!!#@^!!#<Xz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_WaveBuilder_SaveSet1,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	Button button_WaveBuilder_SaveSet1,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	GroupBox group_load_set,pos={12.00,380.00},size={161.00,88.00},title="Loading"
	GroupBox group_load_set,userdata(ResizeControlsInfo)= A"!!,AN!!#C#!!#A0!!#?iz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	GroupBox group_load_set,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	GroupBox group_load_set,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable setvar_WaveBuilder_search,pos={23.00,443.00},size={125.00,18.00},title="Search filter"
	SetVariable setvar_WaveBuilder_search,help={"Search string for filtering the load stimset list"}
	SetVariable setvar_WaveBuilder_search,userdata(ResizeControlsInfo)= A"!!,Bq!!#CBJ,hq4!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_WaveBuilder_search,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable setvar_WaveBuilder_search,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable setvar_WaveBuilder_search,fSize=12,limits={0,10,1},value= _STR:""
	DefineGuide UGH1={FT,237},UGV0={FL,187}
	SetWindow kwTopWin,hook(main)=WBP_MainWindowHook
	SetWindow kwTopWin,hook(ResizeControls)=ResizeControls#ResizeControlsHook
	SetWindow kwTopWin,hook(windowCoordinateSaving)=StoreWindowCoordinatesHook
	SetWindow kwTopWin,userdata(ResizeControlsInfo)= A"!!*'\"z!!#E<!!#Cm^]4?7zzzzzzzzzzzzzzzzzzzz"
	SetWindow kwTopWin,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzzzzzzzzzzzzzzz"
	SetWindow kwTopWin,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzzzzzzzzz!!!"
	SetWindow kwTopWin,userdata(ResizeControlsGuides)=  "UGH1;UGV0;"
	SetWindow kwTopWin,userdata(ResizeControlsInfoUGH1)=  "NAME:UGH1;WIN:WaveBuilder;TYPE:User;HORIZONTAL:1;POSITION:237.00;GUIDE1:FT;GUIDE2:;RELPOSITION:237;"
	SetWindow kwTopWin,userdata(panelVersion)=  "9"
	SetWindow kwTopWin,userdata(ResizeControlsInfoUGV0)=  "NAME:UGV0;WIN:WaveBuilder;TYPE:User;HORIZONTAL:0;POSITION:187.00;GUIDE1:FL;GUIDE2:;RELPOSITION:187;"
	SetWindow kwTopWin,userdata(JSONSettings_StoreCoordinates)=  "1"
	SetWindow kwTopWin,userdata(JSONSettings_WindowName)=  "wavebuilder"
	Execute/Q/Z "SetWindow kwTopWin sizeLimit={774,410.25,inf,inf}" // sizeLimit requires Igor 7 or later
	Display/W=(186,270,1030,544)/FG=(UGV0,UGH1,FR,FB)/HOST=#
	SetWindow kwTopWin,hook(ResizeControls)=ResizeControls#ResizeControlsHook
	SetWindow kwTopWin,userdata(ResizeControlsInfo)= A"!!,Ct!!#A/!!#E!5QF0#!!!!\"zzzzzzzzzzzzzzzzzzzz"
	SetWindow kwTopWin,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzzzzzzzzzzzzzzz"
	SetWindow kwTopWin,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzzzzzzzzz!!!"
	SetWindow kwTopWin,userdata(ResizeControlsGuides)=  "UGH0;"
	SetWindow kwTopWin,userdata(ResizeControlsInfoUGH0)=  "NAME:UGH0;WIN:WaveBuilder;TYPE:User;HORIZONTAL:1;POSITION:565;GUIDE1:FB;GUIDE2:;RELPOSITION:-42;"
	RenameWindow #,WaveBuilderGraph
	SetActiveSubwindow ##
EndMacro
