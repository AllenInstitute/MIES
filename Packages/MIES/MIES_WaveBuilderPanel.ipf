#pragma rtGlobals=3		// Use modern global access method and strict wave access.

/// @file MIES_WaveBuilderPanel.ipf
/// @brief __WBP__ Panel for creating stimulus sets

// stock igor
#include <Resize Controls>

// third party includes
#include ":ACL_TabUtilities"
#include ":ACL_UserdataEditor"
#include ":FixScrolling"

// our includes
#include ":MIES_AnalysisFunctions"
#include ":MIES_AnalysisFunctionHelpers"
#include ":MIES_Constants"
#include ":MIES_Debugging"
#include ":MIES_EnhancedWMRoutines"
#include ":MIES_GlobalStringAndVariableAccess"
#include ":MIES_GuiUtilities"
#include ":MIES_MiesUtilities"
#include ":MIES_Utilities"
#include ":MIES_Structures"
#include ":MIES_WaveDataFolderGetters"
#include ":MIES_WaveBuilder"

Menu "Mies Panels", dynamic
		"WaveBuilder", /Q,  WBP_CreateWaveBuilderPanel()
End

static StrConstant panel                     = "WaveBuilder"
static StrConstant WaveBuilderGraph          = "WaveBuilder#WaveBuilderGraph"
static StrConstant CHANNEL_DA_SEARCH_STRING  = "*DA*"
static StrConstant CHANNEL_TTL_SEARCH_STRING = "*TTL*"

// Equal to the indizes of the Wave Type popup menu
static Constant  STIMULUS_TYPE_DA            = 1
static Constant  STIMULUS_TYPE_TLL           = 2

Function WBP_CreateWaveBuilderPanel()

	if(windowExists(panel))
		DoWindow/F $panel
		return NaN
	endif

	// create all necessary data folders
	GetWBSvdStimSetParamPath()
	GetWBSvdStimSetParamDAPath()
	GetWBSvdStimSetParamTTLPath()
	GetWBSvdStimSetPath()
	GetWBSvdStimSetDAPath()
	GetWBSvdStimSetTTLPath()

	KillOrMoveToTrash(wv=GetSegmentTypeWave())
	KillOrMoveToTrash(wv=GetWaveBuilderWaveParam())
	KillOrMoveToTrash(wv=GetWaveBuilderWaveTextParam())

	Execute "WaveBuilder()"
End

Window WaveBuilder() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /K=1 /W=(522,113,1529,751)
	SetDrawLayer UserBack
	SetDrawEnv fname= "MS Sans Serif",fsize= 16,fstyle= 1
	DrawText 32,25,"Set Parameters"
	SetVariable SetVar_WB_NumEpochs_S100,pos={35,81},size={124,20},proc=WBP_SetVarProc_TotEpoch,title="Total Epochs"
	SetVariable SetVar_WB_NumEpochs_S100,help={"Number of consecutive epochs in a sweep"}
	SetVariable SetVar_WB_NumEpochs_S100,userdata(tabcontrol)=  "WBP_Set_Parameters"
	SetVariable SetVar_WB_NumEpochs_S100,userdata(tabnum)=  "0"
	SetVariable SetVar_WB_NumEpochs_S100,userdata(ResizeControlsInfo)= A"!!,Cp!!#?[!!#@\\!!#<Xz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WB_NumEpochs_S100,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WB_NumEpochs_S100,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WB_NumEpochs_S100,fSize=14,limits={1,100,1},value= _NUM:1
	SetVariable SetVar_WaveBuilder_P0,pos={194,34},size={100,16},proc=WBP_SetVarProc_UpdateParam,title="Duration"
	SetVariable SetVar_WaveBuilder_P0,help={"Duration (ms) of the epoch being edited."}
	SetVariable SetVar_WaveBuilder_P0,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P0,userdata(ResizeControlsInfo)= A"!!,GR!!#=k!!#@,!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P0,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P0,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P0,limits={0,inf,1},value= _NUM:0
	SetVariable SetVar_WaveBuilder_P1,pos={300,34},size={100,16},proc=WBP_SetVarProc_UpdateParam,title="Delta"
	SetVariable SetVar_WaveBuilder_P1,help={"Sweep to sweep duration delta."}
	SetVariable SetVar_WaveBuilder_P1,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P1,userdata(ResizeControlsInfo)= A"!!,HQ!!#=k!!#@,!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P1,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P1,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P1,value= _NUM:0
	SetVariable SetVar_WB_SweepCount_S101,pos={32,105},size={127,20},proc=WBP_SetVarProc_SweepCount,title="Total Sweeps"
	SetVariable SetVar_WB_SweepCount_S101,help={"Number of sweeps in a stimulus set."}
	SetVariable SetVar_WB_SweepCount_S101,userdata(tabcontrol)=  "WBP_Set_Parameters"
	SetVariable SetVar_WB_SweepCount_S101,userdata(tabnum)=  "0"
	SetVariable SetVar_WB_SweepCount_S101,userdata(ResizeControlsInfo)= A"!!,DG!!#@6!!#@F!!#<Xz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WB_SweepCount_S101,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WB_SweepCount_S101,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WB_SweepCount_S101,fSize=14,limits={1,99,1},value= _NUM:1
	SetVariable setvar_WaveBuilder_P10,pos={552,34},size={100,16},disable=1,proc=WBP_SetVarProc_UpdateParam,title="Tau Rise"
	SetVariable setvar_WaveBuilder_P10,help={"PSC exponential rise time constant (ms)"}
	SetVariable setvar_WaveBuilder_P10,userdata(tabnum)=  "6"
	SetVariable setvar_WaveBuilder_P10,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable setvar_WaveBuilder_P10,userdata(ResizeControlsInfo)= A"!!,Ip!!#=k!!#@,!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_WaveBuilder_P10,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_WaveBuilder_P10,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_WaveBuilder_P10,value= _NUM:0
	SetVariable setvar_WaveBuilder_P12,pos={552,56},size={100,16},disable=1,proc=WBP_SetVarProc_UpdateParam,title="Tau Decay 1"
	SetVariable setvar_WaveBuilder_P12,help={"PSC exponential decay time constant. One of Two."}
	SetVariable setvar_WaveBuilder_P12,userdata(tabnum)=  "6"
	SetVariable setvar_WaveBuilder_P12,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable setvar_WaveBuilder_P12,userdata(ResizeControlsInfo)= A"!!,Ip!!#>n!!#@,!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_WaveBuilder_P12,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_WaveBuilder_P12,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_WaveBuilder_P12,value= _NUM:0
	SetVariable setvar_WaveBuilder_P14,pos={552,80},size={100,16},disable=1,proc=WBP_SetVarProc_UpdateParam,title="Tau Decay 2"
	SetVariable setvar_WaveBuilder_P14,help={"PSC exponential decay time constant. Two of Two."}
	SetVariable setvar_WaveBuilder_P14,userdata(tabnum)=  "6"
	SetVariable setvar_WaveBuilder_P14,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable setvar_WaveBuilder_P14,userdata(ResizeControlsInfo)= A"!!,Ip!!#?Y!!#@,!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_WaveBuilder_P14,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_WaveBuilder_P14,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_WaveBuilder_P14,value= _NUM:0
	SetVariable setvar_WaveBuilder_P16,pos={552,103},size={100,16},disable=1,proc=WBP_SetVarProc_UpdateParam,title="Tau 2 weight"
	SetVariable setvar_WaveBuilder_P16,help={"PSC ratio of decay time constants"}
	SetVariable setvar_WaveBuilder_P16,userdata(tabnum)=  "6"
	SetVariable setvar_WaveBuilder_P16,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable setvar_WaveBuilder_P16,userdata(ResizeControlsInfo)= A"!!,Ip!!#@2!!#@,!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_WaveBuilder_P16,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_WaveBuilder_P16,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_WaveBuilder_P16,limits={0,1,0.1},value= _NUM:0
	SetVariable setvar_WaveBuilder_P17,pos={662,103},size={90,16},disable=1,proc=WBP_SetVarProc_UpdateParam,title="Delta"
	SetVariable setvar_WaveBuilder_P17,help={"PSC ratio of decay time constants sweep to sweep delta"}
	SetVariable setvar_WaveBuilder_P17,userdata(ResizeControlsInfo)= A"!!,J6J,hp]!!#?m!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_WaveBuilder_P17,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_WaveBuilder_P17,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_WaveBuilder_P17,userdata(tabnum)=  "6"
	SetVariable setvar_WaveBuilder_P17,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable setvar_WaveBuilder_P17,limits={-inf,inf,0.1},value= _NUM:0
	SetVariable setvar_WaveBuilder_P15,pos={662,80},size={90,16},disable=1,proc=WBP_SetVarProc_UpdateParam,title="Delta"
	SetVariable setvar_WaveBuilder_P15,help={"PSC exponential decay time constant sweep to sweep delta. Two of Two."}
	SetVariable setvar_WaveBuilder_P15,userdata(ResizeControlsInfo)= A"!!,J6J,hp/!!#?m!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_WaveBuilder_P15,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_WaveBuilder_P15,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_WaveBuilder_P15,userdata(tabnum)=  "6"
	SetVariable setvar_WaveBuilder_P15,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable setvar_WaveBuilder_P15,value= _NUM:0
	SetVariable setvar_WaveBuilder_P13,pos={662,57},size={90,16},disable=1,proc=WBP_SetVarProc_UpdateParam,title="Delta"
	SetVariable setvar_WaveBuilder_P13,help={"PSC exponential decay time constant sweep to sweep delta. One of Two."}
	SetVariable setvar_WaveBuilder_P13,userdata(ResizeControlsInfo)= A"!!,J6J,hoH!!#?m!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_WaveBuilder_P13,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_WaveBuilder_P13,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_WaveBuilder_P13,userdata(tabnum)=  "6"
	SetVariable setvar_WaveBuilder_P13,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable setvar_WaveBuilder_P13,value= _NUM:0
	SetVariable setvar_WaveBuilder_P11,pos={662,34},size={90,16},disable=1,proc=WBP_SetVarProc_UpdateParam,title="Delta"
	SetVariable setvar_WaveBuilder_P11,help={"PSC exponential rise time constant sweep to sweep delta"}
	SetVariable setvar_WaveBuilder_P11,userdata(ResizeControlsInfo)= A"!!,J6J,hnA!!#?m!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_WaveBuilder_P11,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_WaveBuilder_P11,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_WaveBuilder_P11,userdata(tabnum)=  "6"
	SetVariable setvar_WaveBuilder_P11,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable setvar_WaveBuilder_P11,limits={-inf,inf,0.1},value= _NUM:0
	SetVariable SetVar_WaveBuilder_P2,pos={194,57},size={100,16},proc=WBP_SetVarProc_UpdateParam,title="Amplitude"
	SetVariable SetVar_WaveBuilder_P2,help={"Amplitude of the epoch being edited. The unit depends on the DA channel configuration. For GPB-Noise epochs, amplitude = Standard deviation"}
	SetVariable SetVar_WaveBuilder_P2,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P2,userdata(ResizeControlsInfo)= A"!!,GR!!#>r!!#@,!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P2,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P2,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P2,value= _NUM:0
	SetVariable SetVar_WaveBuilder_P3,pos={300,57},size={100,16},proc=WBP_SetVarProc_UpdateParam,title="Delta"
	SetVariable SetVar_WaveBuilder_P3,help={"Sweep to sweep amplitude delta."}
	SetVariable SetVar_WaveBuilder_P3,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P3,userdata(ResizeControlsInfo)= A"!!,HQ!!#>r!!#@,!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P3,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P3,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P3,value= _NUM:0
	SetVariable setvar_WaveBuilder_SetNumber,pos={882,33},size={116,16},proc=WBP_SetVarProc_SetNo,title="Set Number"
	SetVariable setvar_WaveBuilder_SetNumber,help={"A numeric suffix for the set name that can be used to sort sets with identical prefixes."}
	SetVariable setvar_WaveBuilder_SetNumber,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable setvar_WaveBuilder_SetNumber,userdata(ResizeControlsInfo)= A"!!,Jl^]6\\H!!#@L!!#<8z!!#o2B4uAezzzzzzzzzzzzzz!!#o2B4uAezz"
	SetVariable setvar_WaveBuilder_SetNumber,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_WaveBuilder_SetNumber,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_WaveBuilder_SetNumber,limits={0,inf,1},value= _NUM:0
	SetVariable SetVar_WaveBuilder_P4,pos={194,80},size={100,16},disable=1,proc=WBP_SetVarProc_UpdateParam,title="Offset"
	SetVariable SetVar_WaveBuilder_P4,help={"Epoch offset. Offset value is added to epoch."}
	SetVariable SetVar_WaveBuilder_P4,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P4,userdata(ResizeControlsInfo)= A"!!,GR!!#?[!!#@,!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P4,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P4,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P4,userdata(tabnum)=  "1",value= _NUM:0
	SetVariable SetVar_WaveBuilder_P6,pos={194,104},size={100,16},disable=1,proc=WBP_SetVarProc_UpdateParam,title="Start Freq"
	SetVariable SetVar_WaveBuilder_P6,help={"Sin frequency or chirp start frequency"}
	SetVariable SetVar_WaveBuilder_P6,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P6,userdata(ResizeControlsInfo)= A"!!,GR!!#@6!!#@,!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P6,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P6,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P6,userdata(tabnum)=  "3",value= _NUM:0
	TabControl WBP_WaveType,pos={187,3},size={686,205},proc=ACL_DisplayTab
	TabControl WBP_WaveType,help={"Select epoch type"}
	TabControl WBP_WaveType,userdata(tabcontrol)=  "WBP_WaveType"
	TabControl WBP_WaveType,userdata(currenttab)=  "0"
	TabControl WBP_WaveType,userdata(initialhook)= "WBP_InitialTabHook"
	TabControl WBP_WaveType,userdata(finalhook)= "WBP_FinalTabHook"
	TabControl WBP_WaveType,userdata(ResizeControlsInfo)= A"!!,GK!!#8L!!#D;J,hr/z!!#](Aon\"Qzzzzzzzzzzzzzz!!#o2B4uAezz"
	TabControl WBP_WaveType,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	TabControl WBP_WaveType,userdata(ResizeControlsInfo) += A"zzz!!#N3Bk1ct<C]S7zzzzzzzzzzzzz!!!"
	TabControl WBP_WaveType,tabLabel(0)="Square pulse",tabLabel(1)="Ramp"
	TabControl WBP_WaveType,tabLabel(2)="GPB-Noise",tabLabel(3)="Sin"
	TabControl WBP_WaveType,tabLabel(4)="Saw tooth",tabLabel(5)="Square pulse train"
	TabControl WBP_WaveType,tabLabel(6)="PSC",tabLabel(7)="Load custom wave"
	TabControl WBP_WaveType,value= 0
	SetVariable setvar_WaveBuilder_CurrentEpoch,pos={37,129},size={122,20},proc=WBP_SetVarProc_EpochToEdit,title="Epoch to edit"
	SetVariable setvar_WaveBuilder_CurrentEpoch,help={"Epoch to edit. The active epoch is displayed on the graph with a white background. Inactive epochs have a gray background."}
	SetVariable setvar_WaveBuilder_CurrentEpoch,userdata(tabcontrol)=  "WBP_Set_Parameters"
	SetVariable setvar_WaveBuilder_CurrentEpoch,userdata(tabnum)=  "0"
	SetVariable setvar_WaveBuilder_CurrentEpoch,userdata(ResizeControlsInfo)= A"!!,D#!!#@e!!#@X!!#<Xz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_WaveBuilder_CurrentEpoch,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_WaveBuilder_CurrentEpoch,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_WaveBuilder_CurrentEpoch,fSize=14
	SetVariable setvar_WaveBuilder_CurrentEpoch,limits={0,0,1},value= _NUM:0
	SetVariable setvar_WaveBuilder_ITI,pos={87,153},size={71,16},proc=WBP_SetVarProc_ITI,title="ITI (s)"
	SetVariable setvar_WaveBuilder_ITI,help={"Inter-trial interval for the stimulus set e.g. time between sweeps. The ITI can be manually over ridden at run time."}
	SetVariable setvar_WaveBuilder_ITI,userdata(tabcontrol)=  "WBP_Set_Parameters"
	SetVariable setvar_WaveBuilder_ITI,userdata(tabnum)=  "0"
	SetVariable setvar_WaveBuilder_ITI,userdata(ResizeControlsInfo)= A"!!,Eh!!#A(!!#?G!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_WaveBuilder_ITI,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable setvar_WaveBuilder_ITI,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable setvar_WaveBuilder_ITI,limits={0,inf,0},value= _NUM:0
	SetVariable SetVar_WaveBuilder_P5,pos={300,80},size={100,16},disable=1,proc=WBP_SetVarProc_UpdateParam,title="Delta"
	SetVariable SetVar_WaveBuilder_P5,help={"Epoch sweep to sweep offset delta."}
	SetVariable SetVar_WaveBuilder_P5,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P5,userdata(ResizeControlsInfo)= A"!!,HQ!!#?[!!#@,!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P5,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P5,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P5,userdata(tabnum)=  "1",value= _NUM:0
	SetVariable SetVar_WaveBuilder_P7,pos={300,104},size={100,16},disable=1,proc=WBP_SetVarProc_UpdateParam,title="Delta"
	SetVariable SetVar_WaveBuilder_P7,help={"Start frequency delta"}
	SetVariable SetVar_WaveBuilder_P7,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P7,userdata(ResizeControlsInfo)= A"!!,HQJ,hpa!!#@,!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P7,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P7,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P7,userdata(tabnum)=  "3",value= _NUM:0
	SetVariable SetVar_WaveBuilder_P8,pos={194,128},size={100,16},disable=1,proc=WBP_SetVarProc_UpdateParam,title="Pulse Dur"
	SetVariable SetVar_WaveBuilder_P8,help={"Duration of the square pulse. Max = pulse interval - 0.005 ms"}
	SetVariable SetVar_WaveBuilder_P8,userdata(tabnum)=  "5"
	SetVariable SetVar_WaveBuilder_P8,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P8,userdata(ResizeControlsInfo)= A"!!,GR!!#@e!!#@,!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P8,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P8,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P8,limits={0,inf,0.1},value= _NUM:0
	SetVariable SetVar_WaveBuilder_P9,pos={300,128},size={100,16},disable=1,proc=WBP_SetVarProc_UpdateParam,title="Delta"
	SetVariable SetVar_WaveBuilder_P9,help={"Square pulse duration delta"}
	SetVariable SetVar_WaveBuilder_P9,userdata(tabnum)=  "5"
	SetVariable SetVar_WaveBuilder_P9,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P9,userdata(ResizeControlsInfo)= A"!!,HQJ,hq;!!#@,!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P9,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P9,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P9,value= _NUM:0
	SetVariable setvar_WaveBuilder_baseName,pos={882,55},size={116,30},proc=WBP_SetVarProc_SetNo,title="Name\rprefix"
	SetVariable setvar_WaveBuilder_baseName,help={"Stimulus set name prefix. Max number of characters = 16"}
	SetVariable setvar_WaveBuilder_baseName,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable setvar_WaveBuilder_baseName,userdata(ResizeControlsInfo)= A"!!,Jl^]6]K!!#@L!!#=Sz!!#o2B4uAezzzzzzzzzzzzzz!!#o2B4uAezz"
	SetVariable setvar_WaveBuilder_baseName,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_WaveBuilder_baseName,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_WaveBuilder_baseName,fSize=8
	SetVariable setvar_WaveBuilder_baseName,limits={0,10,1},value= _STR:"StimulusSetA"
	PopupMenu popup_WaveBuilder_SetList,pos={686,609},size={150,21},bodyWidth=150
	PopupMenu popup_WaveBuilder_SetList,help={"Select stimulus set to load or delete."}
	PopupMenu popup_WaveBuilder_SetList,userdata(tabcontrol)=  "WBP_WaveType"
	PopupMenu popup_WaveBuilder_SetList,userdata(ResizeControlsInfo)= A"!!,J<^]6b>5QF.e!!#<`z!!#o2B4uAezzzzzzzzzzzzzz!!#o2B4uAezz"
	PopupMenu popup_WaveBuilder_SetList,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#?(FEDG<zzzzzzzzzzz"
	PopupMenu popup_WaveBuilder_SetList,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	PopupMenu popup_WaveBuilder_SetList,mode=1,popvalue="- none -",value= #"\"- none -;\"+ WBP_ReturnListSavedSets(\"DA\") + WBP_ReturnListSavedSets(\"TTL\")"
	Button button_WaveBuilder_KillSet,pos={839,608},size={152,23},proc=WBP_ButtonProc_DeleteSet,title="Delete Set"
	Button button_WaveBuilder_KillSet,help={"Delete stimulus set selected in popup menu on the left."}
	Button button_WaveBuilder_KillSet,userdata(tabcontrol)=  "WBP_WaveType"
	Button button_WaveBuilder_KillSet,userdata(ResizeControlsInfo)= A"!!,Jc!!#D(!!#A'!!#<pz!!#o2B4uAezzzzzzzzzzzzzz!!#o2B4uAezz"
	Button button_WaveBuilder_KillSet,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#?(FEDG<zzzzzzzzzzz"
	Button button_WaveBuilder_KillSet,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	PopupMenu popup_WaveBuilder_exp_P40,pos={467,32},size={55,21},proc=WBP_DeltaPopup
	PopupMenu popup_WaveBuilder_exp_P40,help={"Epoch delta type."}
	PopupMenu popup_WaveBuilder_exp_P40,userdata(tabcontrol)=  "WBP_WaveType"
	PopupMenu popup_WaveBuilder_exp_P40,userdata(ResizeControlsInfo)= A"!!,IOJ,hn9!!#>j!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu popup_WaveBuilder_exp_P40,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu popup_WaveBuilder_exp_P40,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu popup_WaveBuilder_exp_P40,mode=1,popvalue="None",value= #"\"None;Multiplier;Log;Squared;Power;Alternate\""
	Button button_WaveBuilder_setaxisA,pos={19,608},size={152,23},proc=WBP_ButtonProc_AutoScale,title="Autoscale"
	Button button_WaveBuilder_setaxisA,help={"Returns the WaveBuilder graph to full scale. Ctrl-A does not work for panel graphs."}
	Button button_WaveBuilder_setaxisA,userdata(tabcontrol)=  "WBP_WaveType"
	Button button_WaveBuilder_setaxisA,userdata(ResizeControlsInfo)= A"!!,BQ!!#D(!!#A'!!#<pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_WaveBuilder_setaxisA,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#?(FEDG<zzzzzzzzzzz"
	Button button_WaveBuilder_setaxisA,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	PopupMenu popup_WaveBuilder_OutputType,pos={30,54},size={129,21},bodyWidth=55,proc=WBP_PopMenuProc_WaveType,title="Wave Type"
	PopupMenu popup_WaveBuilder_OutputType,help={"Stimulus set output type. TTL selection limits certain paramater values. This may result in changes to the active parameter values."}
	PopupMenu popup_WaveBuilder_OutputType,userdata(tabcontrol)=  "WBP_Set_Parameters"
	PopupMenu popup_WaveBuilder_OutputType,userdata(tabnum)=  "0"
	PopupMenu popup_WaveBuilder_OutputType,userdata(ResizeControlsInfo)= A"!!,CT!!#>f!!#@e!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu popup_WaveBuilder_OutputType,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu popup_WaveBuilder_OutputType,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu popup_WaveBuilder_OutputType,fSize=14
	PopupMenu popup_WaveBuilder_OutputType,mode=1,popvalue="DA",value= #"\"DA;TTL\""
	Button button_WaveBuilder_SaveSet,pos={881,88},size={118,46},proc=WBP_ButtonProc_SaveSet,title="Save Set"
	Button button_WaveBuilder_SaveSet,help={"Saves the stimulus set and clears the WaveBuilder graph. On save the set is available for data acquisition."}
	Button button_WaveBuilder_SaveSet,userdata(ResizeControlsInfo)= A"!!,JlJ,hpO!!#@L!!#>Bz!!#o2B4uAezzzzzzzzzzzzzz!!#o2B4uAezz"
	Button button_WaveBuilder_SaveSet,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	Button button_WaveBuilder_SaveSet,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P6_FD00,pos={194,104},size={100,16},disable=1,proc=WBP_SetVarProc_UpdateParam,title="Freq"
	SetVariable SetVar_WaveBuilder_P6_FD00,help={"Saw tooth frequency"}
	SetVariable SetVar_WaveBuilder_P6_FD00,userdata(tabnum)=  "4"
	SetVariable SetVar_WaveBuilder_P6_FD00,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P6_FD00,userdata(ResizeControlsInfo)= A"!!,GR!!#@6!!#@,!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P6_FD00,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P6_FD00,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P6_FD00,value= _NUM:0
	SetVariable SetVar_WaveBuilder_P7_DD00,pos={300,104},size={100,16},disable=1,proc=WBP_SetVarProc_UpdateParam,title="Delta"
	SetVariable SetVar_WaveBuilder_P7_DD00,help={"Saw tooth frequency delta"}
	SetVariable SetVar_WaveBuilder_P7_DD00,userdata(tabnum)=  "4"
	SetVariable SetVar_WaveBuilder_P7_DD00,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P7_DD00,userdata(ResizeControlsInfo)= A"!!,HQJ,hpa!!#@,!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P7_DD00,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P7_DD00,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P7_DD00,value= _NUM:0
	SetVariable SetVar_WaveBuilder_P6_FD01,pos={194,104},size={100,16},disable=1,proc=WBP_SetVarProc_UpdateParam,title="Freq"
	SetVariable SetVar_WaveBuilder_P6_FD01,userdata(tabnum)=  "5"
	SetVariable SetVar_WaveBuilder_P6_FD01,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P6_FD01,userdata(ResizeControlsInfo)= A"!!,GR!!#@6!!#@,!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P6_FD01,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P6_FD01,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P6_FD01,value= _NUM:0
	SetVariable SetVar_WaveBuilder_P7_DD01,pos={300,104},size={100,16},disable=1,proc=WBP_SetVarProc_UpdateParam,title="Delta"
	SetVariable SetVar_WaveBuilder_P7_DD01,userdata(tabnum)=  "5"
	SetVariable SetVar_WaveBuilder_P7_DD01,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P7_DD01,userdata(ResizeControlsInfo)= A"!!,HQJ,hpa!!#@,!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P7_DD01,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P7_DD01,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P7_DD01,value= _NUM:0
	SetVariable SetVar_WaveBuilder_P4_OD00,pos={194,80},size={100,16},disable=1,proc=WBP_SetVarProc_UpdateParam,title="Offset"
	SetVariable SetVar_WaveBuilder_P4_OD00,help={"GPB noise offset."}
	SetVariable SetVar_WaveBuilder_P4_OD00,userdata(tabnum)=  "2"
	SetVariable SetVar_WaveBuilder_P4_OD00,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P4_OD00,userdata(ResizeControlsInfo)= A"!!,GR!!#?[!!#@,!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P4_OD00,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P4_OD00,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P4_OD00,value= _NUM:0
	SetVariable SetVar_WaveBuilder_P5_DD02,pos={300,80},size={100,16},disable=1,proc=WBP_SetVarProc_UpdateParam,title="Delta"
	SetVariable SetVar_WaveBuilder_P5_DD02,help={"GPB noise offset delta."}
	SetVariable SetVar_WaveBuilder_P5_DD02,userdata(tabnum)=  "2"
	SetVariable SetVar_WaveBuilder_P5_DD02,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P5_DD02,userdata(ResizeControlsInfo)= A"!!,HQJ,hp1!!#@,!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P5_DD02,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P5_DD02,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P5_DD02,value= _NUM:0
	SetVariable SetVar_WaveBuilder_P5_DD03,pos={300,80},size={100,16},disable=1,proc=WBP_SetVarProc_UpdateParam,title="Delta"
	SetVariable SetVar_WaveBuilder_P5_DD03,userdata(tabnum)=  "3"
	SetVariable SetVar_WaveBuilder_P5_DD03,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P5_DD03,userdata(ResizeControlsInfo)= A"!!,HQJ,hp1!!#@,!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P5_DD03,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P5_DD03,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P5_DD03,value= _NUM:0
	SetVariable SetVar_WaveBuilder_P4_OD01,pos={194,80},size={100,16},disable=1,proc=WBP_SetVarProc_UpdateParam,title="Offset"
	SetVariable SetVar_WaveBuilder_P4_OD01,userdata(tabnum)=  "3"
	SetVariable SetVar_WaveBuilder_P4_OD01,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P4_OD01,userdata(ResizeControlsInfo)= A"!!,GR!!#?[!!#@,!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P4_OD01,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P4_OD01,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P4_OD01,value= _NUM:0
	SetVariable SetVar_WaveBuilder_P5_DD04,pos={300,80},size={100,16},disable=1,proc=WBP_SetVarProc_UpdateParam,title="Delta"
	SetVariable SetVar_WaveBuilder_P5_DD04,userdata(tabnum)=  "4"
	SetVariable SetVar_WaveBuilder_P5_DD04,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P5_DD04,userdata(ResizeControlsInfo)= A"!!,HQJ,hp1!!#@,!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P5_DD04,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P5_DD04,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P5_DD04,value= _NUM:0
	SetVariable SetVar_WaveBuilder_P4_OD02,pos={194,80},size={100,16},disable=1,proc=WBP_SetVarProc_UpdateParam,title="Offset"
	SetVariable SetVar_WaveBuilder_P4_OD02,userdata(tabnum)=  "4"
	SetVariable SetVar_WaveBuilder_P4_OD02,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P4_OD02,userdata(ResizeControlsInfo)= A"!!,GR!!#?[!!#@,!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P4_OD02,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P4_OD02,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P4_OD02,value= _NUM:0
	SetVariable SetVar_WaveBuilder_P5_DD05,pos={300,80},size={100,16},disable=1,proc=WBP_SetVarProc_UpdateParam,title="Delta"
	SetVariable SetVar_WaveBuilder_P5_DD05,userdata(tabnum)=  "5"
	SetVariable SetVar_WaveBuilder_P5_DD05,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P5_DD05,userdata(ResizeControlsInfo)= A"!!,HQJ,hp3!!#@,!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P5_DD05,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P5_DD05,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P5_DD05,value= _NUM:0
	SetVariable SetVar_WaveBuilder_P4_OD03,pos={194,80},size={100,16},disable=1,proc=WBP_SetVarProc_UpdateParam,title="Offset"
	SetVariable SetVar_WaveBuilder_P4_OD03,userdata(tabnum)=  "5"
	SetVariable SetVar_WaveBuilder_P4_OD03,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P4_OD03,userdata(ResizeControlsInfo)= A"!!,GR!!#?[!!#@,!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P4_OD03,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P4_OD03,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P4_OD03,value= _NUM:0
	SetVariable SetVar_WaveBuilder_P5_DD06,pos={300,80},size={100,16},disable=1,proc=WBP_SetVarProc_UpdateParam,title="Delta"
	SetVariable SetVar_WaveBuilder_P5_DD06,help={"PSC epoch sweep to sweep offset delta"}
	SetVariable SetVar_WaveBuilder_P5_DD06,userdata(tabnum)=  "6"
	SetVariable SetVar_WaveBuilder_P5_DD06,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P5_DD06,userdata(ResizeControlsInfo)= A"!!,HQ!!#?[!!#@,!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P5_DD06,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P5_DD06,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P5_DD06,value= _NUM:0
	SetVariable SetVar_WaveBuilder_P4_OD04,pos={194,80},size={100,16},disable=1,proc=WBP_SetVarProc_UpdateParam,title="Offset"
	SetVariable SetVar_WaveBuilder_P4_OD04,help={"Offset of post synaptic current (PSC) epoch "}
	SetVariable SetVar_WaveBuilder_P4_OD04,userdata(tabnum)=  "6"
	SetVariable SetVar_WaveBuilder_P4_OD04,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P4_OD04,userdata(ResizeControlsInfo)= A"!!,GR!!#?[!!#@,!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P4_OD04,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P4_OD04,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P4_OD04,value= _NUM:0
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
	SetVariable setvar_WaveBuilder_SearchString,pos={574,118},size={212,30},disable=1,proc=WBP_SetVarProc_SetSearchString,title="Search\rstring"
	SetVariable setvar_WaveBuilder_SearchString,help={"Refines list of waves based on search string. Include asterisk \"wildcard\" where appropriate."}
	SetVariable setvar_WaveBuilder_SearchString,userdata(tabnum)=  "7"
	SetVariable setvar_WaveBuilder_SearchString,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable setvar_WaveBuilder_SearchString,userdata(ResizeControlsInfo)= A"!!,IuJ,hq&!!#Ac!!#=Sz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_WaveBuilder_SearchString,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_WaveBuilder_SearchString,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_WaveBuilder_SearchString,value= _STR:""
	PopupMenu popup_WaveBuilder_ListOfWaves,pos={577,88},size={210,26},bodyWidth=175,disable=1,proc=WBP_PopMenuProc_WaveToLoad,title="Wave\rto load"
	PopupMenu popup_WaveBuilder_ListOfWaves,help={"Select custom epoch wave. Popup menu displays waves contained in selected folder. Waves must have 5 micro second sampling interval."}
	PopupMenu popup_WaveBuilder_ListOfWaves,userdata(tabnum)=  "7"
	PopupMenu popup_WaveBuilder_ListOfWaves,userdata(tabcontrol)=  "WBP_WaveType"
	PopupMenu popup_WaveBuilder_ListOfWaves,userdata(ResizeControlsInfo)= A"!!,J!5QF-T!!#Aa!!#=3z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
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
	SetVariable SetVar_WaveBuilder_P21,help={"Low pass filter cut off frequency delta."}
	SetVariable SetVar_WaveBuilder_P21,userdata(tabnum)=  "2"
	SetVariable SetVar_WaveBuilder_P21,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P21,userdata(ResizeControlsInfo)= A"!!,JJ5QF+N!!#?o!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P21,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P21,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P21,limits={-499,99999,1},value= _NUM:0
	SetVariable SetVar_WaveBuilder_P22,pos={584,97},size={152,30},disable=1,proc=WBP_SetVarProc_UpdateParam,title="High pass cut \roff frequency"
	SetVariable SetVar_WaveBuilder_P22,help={"Set to zero to turn off high pass filter"}
	SetVariable SetVar_WaveBuilder_P22,userdata(tabnum)=  "2"
	SetVariable SetVar_WaveBuilder_P22,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P22,userdata(ResizeControlsInfo)= A"!!,J#!!#@&!!#A'!!#=Sz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P22,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P22,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P22,limits={0,100000,100},value= _NUM:0
	SetVariable SetVar_WaveBuilder_P23,pos={741,65},size={91,16},disable=1,proc=WBP_SetVarProc_UpdateParam,title="Delta"
	SetVariable SetVar_WaveBuilder_P23,help={"High pass filter coefficient delta."}
	SetVariable SetVar_WaveBuilder_P23,userdata(tabnum)=  "2"
	SetVariable SetVar_WaveBuilder_P23,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P23,userdata(ResizeControlsInfo)= A"!!,JJ5QF-&!!#?o!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P23,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P23,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P23,limits={-inf,99999,1},value= _NUM:0
	CheckBox check_SPT_Poisson_P44,pos={413,103},size={68,26},disable=1,proc=WBP_CheckProc,title="Poisson\rdistribution"
	CheckBox check_SPT_Poisson_P44,help={"Poisson distribution of square pulses at the average frequency specified by the user."}
	CheckBox check_SPT_Poisson_P44,userdata(ResizeControlsInfo)= A"!!,I4J,hp]!!#?A!!#=3z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_SPT_Poisson_P44,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_SPT_Poisson_P44,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_SPT_Poisson_P44,userdata(tabnum)=  "5"
	CheckBox check_SPT_Poisson_P44,userdata(tabcontrol)=  "WBP_WaveType",value= 0
	SetVariable SetVar_WaveBuilder_P24,pos={194,128},size={100,16},disable=3,proc=WBP_SetVarProc_UpdateParam,title="End Freq"
	SetVariable SetVar_WaveBuilder_P24,help={"Chirp end frequency"}
	SetVariable SetVar_WaveBuilder_P24,userdata(ResizeControlsInfo)= A"!!,GR!!#@e!!#@,!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P24,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P24,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P24,userdata(tabnum)=  "3"
	SetVariable SetVar_WaveBuilder_P24,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P24,limits={0,inf,0.1},value= _NUM:0
	SetVariable SetVar_WaveBuilder_P25,pos={300,128},size={100,16},disable=3,proc=WBP_SetVarProc_UpdateParam,title="Delta"
	SetVariable SetVar_WaveBuilder_P25,help={"Chirp end frequency delta"}
	SetVariable SetVar_WaveBuilder_P25,userdata(ResizeControlsInfo)= A"!!,HQJ,hq;!!#@,!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P25,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P25,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P25,userdata(tabnum)=  "3"
	SetVariable SetVar_WaveBuilder_P25,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P25,value= _NUM:0
	CheckBox check_Sin_Chirp_P43,pos={413,101},size={41,26},disable=1,proc=WBP_CheckProc,title="log\rchirp"
	CheckBox check_Sin_Chirp_P43,help={"A chirp is a signal in which the frequency increases or decreases with time."}
	CheckBox check_Sin_Chirp_P43,userdata(tabnum)=  "3"
	CheckBox check_Sin_Chirp_P43,userdata(tabcontrol)=  "WBP_WaveType"
	CheckBox check_Sin_Chirp_P43,userdata(ResizeControlsInfo)= A"!!,I4J,hpY!!#>2!!#=3z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_Sin_Chirp_P43,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_Sin_Chirp_P43,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_Sin_Chirp_P43,value= 0
	Button button_WaveBuilder_LoadSet,pos={530,608},size={152,23},proc=WBP_ButtonProc_LoadSet,title="Load Set"
	Button button_WaveBuilder_LoadSet,help={"Load set selected in popup menu on the right."}
	Button button_WaveBuilder_LoadSet,userdata(tabcontrol)=  "WBP_WaveType"
	Button button_WaveBuilder_LoadSet,userdata(ResizeControlsInfo)= A"!!,IjJ,htS!!#A'!!#<pz!!#o2B4uAezzzzzzzzzzzzzz!!#o2B4uAezz"
	Button button_WaveBuilder_LoadSet,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#?(FEDG<zzzzzzzzzzz"
	Button button_WaveBuilder_LoadSet,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P27,pos={741,97},size={91,16},disable=1,proc=WBP_SetVarProc_UpdateParam,title="Delta"
	SetVariable SetVar_WaveBuilder_P27,help={"High pass filter cut off frequency delta."}
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
	SetVariable SetVar_WaveBuilder_P26,limits={3,32767,50},value= _NUM:0
	SetVariable SetVar_WaveBuilder_P29,pos={741,129},size={91,16},disable=1,proc=WBP_SetVarProc_UpdateParam,title="Delta"
	SetVariable SetVar_WaveBuilder_P29,help={"Low pass filter coefficent delta."}
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
	SetVariable SetVar_WaveBuilder_P28,limits={3,32767,50},value= _NUM:0
	SetVariable SetVar_WB_DurDeltaMult_P52,pos={405,34},size={55,16},disable=2,proc=WBP_SetVarProc_UpdateParam,title="* "
	SetVariable SetVar_WB_DurDeltaMult_P52,help={"Epoch duration delta multiplier or exponent."}
	SetVariable SetVar_WB_DurDeltaMult_P52,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WB_DurDeltaMult_P52,userdata(ResizeControlsInfo)= A"!!,I1J,hn=!!#>j!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WB_DurDeltaMult_P52,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable SetVar_WB_DurDeltaMult_P52,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WB_DurDeltaMult_P52,value= _NUM:0
	PopupMenu popup_WaveBuilder_FolderList,pos={579,60},size={208,26},bodyWidth=175,disable=1,proc=WBP_PopMenuProc_FolderSelect,title="Select\rfolder"
	PopupMenu popup_WaveBuilder_FolderList,help={"Select folder that contains custom epoch wave. After each selection, contents of selected folder are listed in popup menu."}
	PopupMenu popup_WaveBuilder_FolderList,userdata(tabnum)=  "7"
	PopupMenu popup_WaveBuilder_FolderList,userdata(tabcontrol)=  "WBP_WaveType"
	PopupMenu popup_WaveBuilder_FolderList,userdata(ResizeControlsInfo)= A"!!,J!^]6]?!!#A_!!#=3z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu popup_WaveBuilder_FolderList,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	PopupMenu popup_WaveBuilder_FolderList,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	PopupMenu popup_WaveBuilder_FolderList,mode=1,popvalue="- none -",value= #"WBP_ReturnFoldersList()"
	GroupBox group_WaveBuilder_FolderPath,pos={548,34},size={269,127},disable=1,title="root:"
	GroupBox group_WaveBuilder_FolderPath,help={"Displays user defined path to custom epoch wave"}
	GroupBox group_WaveBuilder_FolderPath,userdata(tabnum)=  "7"
	GroupBox group_WaveBuilder_FolderPath,userdata(tabcontrol)=  "WBP_WaveType"
	GroupBox group_WaveBuilder_FolderPath,userdata(ResizeControlsInfo)= A"!!,Io!!#=k!!#B@J,hq8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	GroupBox group_WaveBuilder_FolderPath,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	GroupBox group_WaveBuilder_FolderPath,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	GroupBox group_WaveBuilder_SaveSet,pos={876,6},size={127,134},title="\\Z16\\f01Save Set"
	GroupBox group_WaveBuilder_SaveSet,userdata(tabcontrol)=  "WBP_WaveType"
	GroupBox group_WaveBuilder_SaveSet,userdata(ResizeControlsInfo)= A"!!,Jk5QF)X!!#@b!!#@jz!!#o2B4uAezzzzzzzzzzzzzz!!#o2B4uAezz"
	GroupBox group_WaveBuilder_SaveSet,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	GroupBox group_WaveBuilder_SaveSet,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	GroupBox group_WaveBuilder_SaveSet,fStyle=0
	SetVariable SetVar_WaveBuilder_P30,pos={309,103},size={91,16},disable=3,proc=WBP_SetVarProc_UpdateParam,title="- increment"
	SetVariable SetVar_WaveBuilder_P30,userdata(tabnum)=  "2"
	SetVariable SetVar_WaveBuilder_P30,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P30,userdata(ResizeControlsInfo)= A"!!,HV!!#@6!!#?o!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P30,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P30,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P30,limits={0.01,99999,1},value= _NUM:0
	TitleBox title_WBP_GNoise_F,pos={300,96},size={6,32},disable=1,title="\\Z30f"
	TitleBox title_WBP_GNoise_F,userdata(tabnum)=  "2"
	TitleBox title_WBP_GNoise_F,userdata(tabcontrol)=  "WBP_WaveType"
	TitleBox title_WBP_GNoise_F,userdata(ResizeControlsInfo)= A"!!,HQ!!#@$!!#:\"!!#=cz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TitleBox title_WBP_GNoise_F,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	TitleBox title_WBP_GNoise_F,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	TitleBox title_WBP_GNoise_F,frame=0
	CheckBox check_Noise_Pink_P41,pos={413,107},size={39,14},disable=1,proc=WBP_CheckProc,title="Pink"
	CheckBox check_Noise_Pink_P41,help={"Pink noise amplitude = 1 / frequency"}
	CheckBox check_Noise_Pink_P41,userdata(tabnum)=  "2"
	CheckBox check_Noise_Pink_P41,userdata(tabcontrol)=  "WBP_WaveType"
	CheckBox check_Noise_Pink_P41,userdata(ResizeControlsInfo)= A"!!,I4J,hpe!!#>*!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_Noise_Pink_P41,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_Noise_Pink_P41,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox check_Noise_Pink_P41,value= 0
	CheckBox Check_Noise_Brown_P42,pos={413,126},size={48,14},disable=1,proc=WBP_CheckProc,title="Brown"
	CheckBox Check_Noise_Brown_P42,help={"Brown noise amplitude = 1 / (frequency ^ 0.5)"}
	CheckBox Check_Noise_Brown_P42,userdata(tabnum)=  "2"
	CheckBox Check_Noise_Brown_P42,userdata(tabcontrol)=  "WBP_WaveType"
	CheckBox Check_Noise_Brown_P42,userdata(ResizeControlsInfo)= A"!!,I4J,hq6!!#>N!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox Check_Noise_Brown_P42,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox Check_Noise_Brown_P42,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox Check_Noise_Brown_P42,value= 0
	CheckBox check_PreventUpdate,pos={189,613},size={91,14},proc=WBP_CheckProc_PreventUpdate,title="Prevent update"
	CheckBox check_PreventUpdate,help={"Stops graph updating when checked. Useful when updating multiple parameters in \"big\" stimulus sets."}
	CheckBox check_PreventUpdate,userdata(tabcontrol)=  "WBP_WaveType"
	CheckBox check_PreventUpdate,userdata(ResizeControlsInfo)= A"!!,GM!!#D)5QF-Z!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_PreventUpdate,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#?(FEDG<zzzzzzzzzzz"
	CheckBox check_PreventUpdate,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	CheckBox check_PreventUpdate,value= 0
	SetVariable SetVar_WB_AmpDeltaMult_P50,pos={405,57},size={55,16},disable=2,proc=WBP_SetVarProc_UpdateParam,title="* "
	SetVariable SetVar_WB_AmpDeltaMult_P50,help={"Epoch amplitude delta multiplier or exponent."}
	SetVariable SetVar_WB_AmpDeltaMult_P50,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WB_AmpDeltaMult_P50,userdata(ResizeControlsInfo)= A"!!,I1!!#>r!!#>j!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WB_AmpDeltaMult_P50,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable SetVar_WB_AmpDeltaMult_P50,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WB_AmpDeltaMult_P50,value= _NUM:0
	SetVariable SetVar_WB_OffsetDeltaMult_P51,pos={405,80},size={55,16},disable=3,proc=WBP_SetVarProc_UpdateParam,title="* "
	SetVariable SetVar_WB_OffsetDeltaMult_P51,help={"Specify the epoch offset delta multiplier or exponent."}
	SetVariable SetVar_WB_OffsetDeltaMult_P51,userdata(tabnum)=  "1"
	SetVariable SetVar_WB_OffsetDeltaMult_P51,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WB_OffsetDeltaMult_P51,userdata(ResizeControlsInfo)= A"!!,I1!!#?[!!#>j!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WB_OffsetDeltaMult_P51,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable SetVar_WB_OffsetDeltaMult_P51,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WB_OffsetDeltaMult_P51,value= _NUM:0
	SetVariable SetVar_WB_OffsetDeltaMult_P51_0,pos={405,80},size={55,16},disable=3,proc=WBP_SetVarProc_OMD,title="* "
	SetVariable SetVar_WB_OffsetDeltaMult_P51_0,userdata(tabnum)=  "2"
	SetVariable SetVar_WB_OffsetDeltaMult_P51_0,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WB_OffsetDeltaMult_P51_0,userdata(ResizeControlsInfo)= A"!!,I1!!#?[!!#>j!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WB_OffsetDeltaMult_P51_0,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable SetVar_WB_OffsetDeltaMult_P51_0,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WB_OffsetDeltaMult_P51_0,value= _NUM:0
	SetVariable SetVar_WB_OffsetDeltaMult_P51_1,pos={405,80},size={55,16},disable=3,proc=WBP_SetVarProc_OMD,title="* "
	SetVariable SetVar_WB_OffsetDeltaMult_P51_1,userdata(tabnum)=  "3"
	SetVariable SetVar_WB_OffsetDeltaMult_P51_1,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WB_OffsetDeltaMult_P51_1,userdata(ResizeControlsInfo)= A"!!,I1!!#?[!!#>j!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WB_OffsetDeltaMult_P51_1,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable SetVar_WB_OffsetDeltaMult_P51_1,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WB_OffsetDeltaMult_P51_1,value= _NUM:0
	SetVariable SetVar_WB_OffsetDeltaMult_P51_2,pos={405,80},size={55,16},disable=3,proc=WBP_SetVarProc_OMD,title="* "
	SetVariable SetVar_WB_OffsetDeltaMult_P51_2,userdata(tabnum)=  "4"
	SetVariable SetVar_WB_OffsetDeltaMult_P51_2,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WB_OffsetDeltaMult_P51_2,userdata(ResizeControlsInfo)= A"!!,I1!!#?[!!#>j!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WB_OffsetDeltaMult_P51_2,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable SetVar_WB_OffsetDeltaMult_P51_2,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WB_OffsetDeltaMult_P51_2,value= _NUM:0
	SetVariable SetVar_WB_OffsetDeltaMult_P51_3,pos={405,80},size={55,16},disable=3,proc=WBP_SetVarProc_OMD,title="* "
	SetVariable SetVar_WB_OffsetDeltaMult_P51_3,userdata(tabnum)=  "5"
	SetVariable SetVar_WB_OffsetDeltaMult_P51_3,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WB_OffsetDeltaMult_P51_3,userdata(ResizeControlsInfo)= A"!!,I1!!#?[!!#>j!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WB_OffsetDeltaMult_P51_3,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable SetVar_WB_OffsetDeltaMult_P51_3,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WB_OffsetDeltaMult_P51_3,value= _NUM:0
	SetVariable SetVar_WB_OffsetDeltaMult_P51_4,pos={405,80},size={55,16},disable=3,proc=WBP_SetVarProc_OMD,title="* "
	SetVariable SetVar_WB_OffsetDeltaMult_P51_4,userdata(tabnum)=  "6"
	SetVariable SetVar_WB_OffsetDeltaMult_P51_4,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WB_OffsetDeltaMult_P51_4,userdata(ResizeControlsInfo)= A"!!,I1!!#?[!!#>j!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WB_OffsetDeltaMult_P51_4,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable SetVar_WB_OffsetDeltaMult_P51_4,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WB_OffsetDeltaMult_P51_4,value= _NUM:0
	SetVariable SetVar_WB_OffsetDeltaMult_P51_5,pos={406,81},size={55,16},disable=3,proc=SetVarProc_WB_OMD,title="*"
	SetVariable SetVar_WB_OffsetDeltaMult_P51_5,userdata(tabnum)=  "7"
	SetVariable SetVar_WB_OffsetDeltaMult_P51_5,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WB_OffsetDeltaMult_P51_5,userdata(ResizeControlsInfo)= A"!!,I1!!#?[!!#>j!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WB_OffsetDeltaMult_P51_5,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable SetVar_WB_OffsetDeltaMult_P51_5,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WB_OffsetDeltaMult_P51_5,value= _NUM:0
	SetVariable SetVar_WaveBuilder_P45,pos={194,151},size={100,16},disable=3,proc=WBP_SetVarProc_UpdateParam,title="Num Pulses"
	SetVariable SetVar_WaveBuilder_P45,help={"Number of pulses in epoch at specified frequency"}
	SetVariable SetVar_WaveBuilder_P45,userdata(tabnum)=  "5"
	SetVariable SetVar_WaveBuilder_P45,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P45,userdata(ResizeControlsInfo)= A"!!,GR!!#A'!!#@,!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P45,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P45,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P45,limits={0,inf,1},value= _NUM:0
	SetVariable SetVar_WaveBuilder_P47,pos={300,151},size={100,16},disable=3,proc=WBP_SetVarProc_UpdateParam,title="Delta"
	SetVariable SetVar_WaveBuilder_P47,help={"Epoch pulse number delta"}
	SetVariable SetVar_WaveBuilder_P47,userdata(tabnum)=  "5"
	SetVariable SetVar_WaveBuilder_P47,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P47,userdata(ResizeControlsInfo)= A"!!,HQJ,hqR!!#@,!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P47,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P47,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P47,value= _NUM:0
	CheckBox check_SPT_NumPulses_P46,pos={413,133},size={71,14},disable=1,proc=WBP_CheckProc,title="Use Pulses"
	CheckBox check_SPT_NumPulses_P46,help={"Checked: epoch duration is determined by the user specified pulse number and frequency. Unchecked: epoch duration is set by the user."}
	CheckBox check_SPT_NumPulses_P46,userdata(tabnum)=  "5"
	CheckBox check_SPT_NumPulses_P46,userdata(tabcontrol)=  "WBP_WaveType"
	CheckBox check_SPT_NumPulses_P46,userdata(ResizeControlsInfo)= A"!!,I4J,hq?!!#?G!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_SPT_NumPulses_P46,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_SPT_NumPulses_P46,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_SPT_NumPulses_P46,value= 0
	Button button_NewSeed_P48,pos={338,128},size={61,20},disable=1,proc=WBP_ButtonProc_NewSeed,title="New Noise"
	Button button_NewSeed_P48,help={"Create new noise waveforms"}
	Button button_NewSeed_P48,userdata(tabnum)=  "2"
	Button button_NewSeed_P48,userdata(tabcontrol)=  "WBP_WaveType"
	Button button_NewSeed_P48,userdata(ResizeControlsInfo)= A"!!,Hd!!#@d!!#?-!!#<Xz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_NewSeed_P48,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	Button button_NewSeed_P48,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox check_NewSeedForEachStep_P49,pos={413,145},size={76,14},disable=1,proc=WBP_CheckProc,title="Seed / Step"
	CheckBox check_NewSeedForEachStep_P49,help={"When checked, the random number generator (RNG) seed is updated with each sweep. Seeds are saved with the stimulus."}
	CheckBox check_NewSeedForEachStep_P49,userdata(tabnum)=  "2"
	CheckBox check_NewSeedForEachStep_P49,userdata(tabcontrol)=  "WBP_WaveType"
	CheckBox check_NewSeedForEachStep_P49,userdata(ResizeControlsInfo)= A"!!,I4J,hqK!!#>B!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_NewSeedForEachStep_P49,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_NewSeedForEachStep_P49,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox check_NewSeedForEachStep_P49,value= 0
	CheckBox check_FlipEpoch_S98,pos={121,174},size={34,14},proc=WBP_CheckProc_FlipStimSet,title="Flip"
	CheckBox check_FlipEpoch_S98,help={"Flip the whole stim set in the time domain"}
	CheckBox check_FlipEpoch_S98,userdata(tabcontrol)=  "WBP_Set_Parameters"
	CheckBox check_FlipEpoch_S98,userdata(tabnum)=  "0"
	CheckBox check_FlipEpoch_S98,userdata(ResizeControlsInfo)= A"!!,FW!!#A=!!#=k!!#;mz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_FlipEpoch_S98,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_FlipEpoch_S98,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox check_FlipEpoch_S98,value= 0
	PopupMenu popup_af_postSweep_S3,pos={7,102},size={170,21},bodyWidth=110,disable=1,proc=WBP_PopupMenu_AnalysisFunctions,title="Post Sweep"
	PopupMenu popup_af_postSweep_S3,help={"After each sweep"},userdata(tabnum)=  "1"
	PopupMenu popup_af_postSweep_S3,userdata(tabcontrol)=  "WBP_Set_Parameters"
	PopupMenu popup_af_postSweep_S3,userdata(ResizeControlsInfo)= A"!!,@C!!#@2!!#A9!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu popup_af_postSweep_S3,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	PopupMenu popup_af_postSweep_S3,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	PopupMenu popup_af_postSweep_S3,mode=1,popvalue="- none -",value= #"WBP_GetAnalysisFunctions()"
	TabControl WBP_Set_Parameters,pos={3,29},size={182,174},proc=ACL_DisplayTab
	TabControl WBP_Set_Parameters,userdata(finalhook)= "WBP_FinalTabHook"
	TabControl WBP_Set_Parameters,help={"Stimulus set parameters and custom analysis functions."}
	TabControl WBP_Set_Parameters,userdata(currenttab)=  "0"
	TabControl WBP_Set_Parameters,userdata(ResizeControlsInfo)= A"!!,>M!!#=K!!#AE!!#A?z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TabControl WBP_Set_Parameters,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	TabControl WBP_Set_Parameters,userdata(ResizeControlsInfo) += A"zzz!!#N3Bk1ct<C]S7zzzzzzzzzzzzz!!!"
	TabControl WBP_Set_Parameters,labelBack=(60928,60928,60928),tabLabel(0)="Basic"
	TabControl WBP_Set_Parameters,tabLabel(1)="Analysis Functions",value= 0
	PopupMenu popup_af_postSet_S4,pos={24,128},size={153,21},bodyWidth=110,disable=1,proc=WBP_PopupMenu_AnalysisFunctions,title="Post Set"
	PopupMenu popup_af_postSet_S4,help={"After a *full* set has been acquired (This event is not always reached as the user might not acquire all sweeps of a set)"}
	PopupMenu popup_af_postSet_S4,userdata(tabnum)=  "1"
	PopupMenu popup_af_postSet_S4,userdata(tabcontrol)=  "WBP_Set_Parameters"
	PopupMenu popup_af_postSet_S4,userdata(ResizeControlsInfo)= A"!!,C$!!#@f!!#A(!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu popup_af_postSet_S4,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	PopupMenu popup_af_postSet_S4,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	PopupMenu popup_af_postSet_S4,mode=1,popvalue="- none -",value= #"WBP_GetAnalysisFunctions()"
	PopupMenu popup_af_preDAQEvent_S1,pos={22,50},size={155,21},bodyWidth=110,disable=1,proc=WBP_PopupMenu_AnalysisFunctions,title="Pre DAQ"
	PopupMenu popup_af_preDAQEvent_S1,help={"Immediately before any DAQ occurs"}
	PopupMenu popup_af_preDAQEvent_S1,userdata(tabnum)=  "1"
	PopupMenu popup_af_preDAQEvent_S1,userdata(tabcontrol)=  "WBP_Set_Parameters"
	PopupMenu popup_af_preDAQEvent_S1,userdata(ResizeControlsInfo)= A"!!,Bi!!#>V!!#A*!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu popup_af_preDAQEvent_S1,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	PopupMenu popup_af_preDAQEvent_S1,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	PopupMenu popup_af_preDAQEvent_S1,mode=1,popvalue="- none -",value= #"WBP_GetAnalysisFunctions()"
	PopupMenu popup_af_midSweep_S2,pos={13,76},size={164,21},bodyWidth=110,disable=1,proc=WBP_PopupMenu_AnalysisFunctions,title="Mid sweep"
	PopupMenu popup_af_midSweep_S2,help={"Each time when new data is polled (available for background DAQ only)"}
	PopupMenu popup_af_midSweep_S2,userdata(tabnum)=  "1"
	PopupMenu popup_af_midSweep_S2,userdata(tabcontrol)=  "WBP_Set_Parameters"
	PopupMenu popup_af_midSweep_S2,userdata(ResizeControlsInfo)= A"!!,A^!!#?Q!!#A3!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu popup_af_midSweep_S2,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	PopupMenu popup_af_midSweep_S2,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	PopupMenu popup_af_midSweep_S2,mode=1,popvalue="- none -",value= #"WBP_GetAnalysisFunctions()"
	PopupMenu popup_af_postDAQEvent_S5,pos={17,154},size={160,21},bodyWidth=110,disable=1,proc=WBP_PopupMenu_AnalysisFunctions,title="Post DAQ"
	PopupMenu popup_af_postDAQEvent_S5,help={"After all DAQ has been finished"}
	PopupMenu popup_af_postDAQEvent_S5,userdata(tabnum)=  "1"
	PopupMenu popup_af_postDAQEvent_S5,userdata(tabcontrol)=  "WBP_Set_Parameters"
	PopupMenu popup_af_postDAQEvent_S5,userdata(ResizeControlsInfo)= A"!!,BA!!#A,!!#A/!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu popup_af_postDAQEvent_S5,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	PopupMenu popup_af_postDAQEvent_S5,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	PopupMenu popup_af_postDAQEvent_S5,mode=1,popvalue="- none -",value= #"WBP_GetAnalysisFunctions()"
	Button button_af_jump_to_proc,pos={66,179},size={113,21},disable=1,proc=WBP_ButtonProc_OpenAnaFuncs,title="Open procedure file"
	Button button_af_jump_to_proc,help={"Open the procedure where the analysis functions have to be defined"}
	Button button_af_jump_to_proc,userdata(tabnum)=  "1"
	Button button_af_jump_to_proc,userdata(tabcontrol)=  "WBP_Set_Parameters"
	Button button_af_jump_to_proc,userdata(ResizeControlsInfo)= A"!!,E6!!#AD!!#@L!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_af_jump_to_proc,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	Button button_af_jump_to_proc,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	DefineGuide UGH1={FT,206},UGH0={UGH1,0.902778,FB}
	SetWindow kwTopWin,hook(ResizeControls)=ResizeControls#ResizeControlsHook
	SetWindow kwTopWin,userdata(ResizeControlsInfo)= A"!!*'\"z!!#E6^]6bEJ,fQLzzzzzzzzzzzzzzzzzzzz"
	SetWindow kwTopWin,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzzzzzzzzzzzzzzz"
	SetWindow kwTopWin,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzzzzzzzzz!!!"
	SetWindow kwTopWin,userdata(ResizeControlsGuides)=  "UGH0;UGH1;"
	SetWindow kwTopWin,userdata(ResizeControlsInfoUGH0)= A":-hTC3`S[@0KW?-:-)HbG%F!_Bl%<kE][6':dmEFF(KAR85E,T>#.mm5tj<o4&A^O8Q88W:-(6m2EOE/8OQ!%3`S[@0fqm*8OQ!&3^uFt;FO8U:K'ha8P`)B0J5@>1,h-O3r"
	SetWindow kwTopWin,userdata(ResizeControlsInfoUGH1)= A":-hTC3`S[@0frH.:-)HbG%F!_Bl%<kE][6':dmEFF(KAR85E,T>#.mm5tj<o4&A^O8Q88W:-(-a2EOE/8OQ!%3_!(17o`,K75?nc;FO8U:K'ha8P`)B1,(UJ"
	Display/W=(0,286,1068,487)/FG=(,UGH1,FR,UGH0)/HOST=# 
	SetWindow kwTopWin,hook(ResizeControls)=ResizeControls#ResizeControlsHook
	SetWindow kwTopWin,userdata(ResizeControlsInfo)= A"!!,Ct!!#A/!!#E!5QF0#!!!!\"zzzzzzzzzzzzzzzzzzzz"
	SetWindow kwTopWin,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzzzzzzzzzzzzzzz"
	SetWindow kwTopWin,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzzzzzzzzz!!!"
	SetWindow kwTopWin,userdata(ResizeControlsGuides)=  "UGH0;"
	SetWindow kwTopWin,userdata(ResizeControlsInfoUGH0)= A":-hTC3`S[@0KW?-:-)HbG%F!_Bl%<kE][6':dmEFF(KAR85E,T>#.mm5tj<o4&A^O8Q88W:-(6j2*4<.8OQ!%3^uFt7o`,K75?nc;FO8U:K'ha8P`)B/Mo4E"
	RenameWindow #,WaveBuilderGraph
	SetActiveSubwindow ##
EndMacro

static Constant EPOCH_HL_TYPE_LEFT  = 0x01
static Constant EPOCH_HL_TYPE_RIGHT = 0x02

/// @brief Add epoch highlightning traces
/// Uses fill-to-next on specially created waves added before and after the current trace
static Function WBP_AddEpochHLTraces(dfr, epochHLType, epoch, numEpochs)
	DFREF dfr
	variable epochHLType, epoch, numEpochs

	string nameBegin, nameEnd
	variable first, last

	WAVE epochID = GetEpochID()

	if(epochHLType == EPOCH_HL_TYPE_LEFT)
		nameBegin = "epochHLBeginLeft"
		nameEnd   = "epochHLEndLeft"

		Make/O/N=(2) dfr:$nameBegin = NaN, dfr:$nameEnd = NaN
		WAVE/SDFR=dfr waveBegin = $nameBegin
		WAVE/SDFR=dfr waveEnd   = $nameEnd

		if(epoch == 0)
			// no epoch to highlight left of the current one
			return NaN
		endif

		// we highlight the range 0, 1, ..., epoch - 1
		first = epochID[0][%timeBegin]
		last  = epochID[epoch - 1][%timeEnd]
		SetScale/I x, first, last, "ms", waveBegin, waveEnd
	elseif(epochHLType == EPOCH_HL_TYPE_RIGHT)
		nameBegin = "epochHLBeginRight"
		nameEnd   = "epochHLEndRight"

		Make/O/N=(2) dfr:$nameBegin = NaN, dfr:$nameEnd = NaN
		WAVE/SDFR=dfr waveBegin = $nameBegin
		WAVE/SDFR=dfr waveEnd   = $nameEnd

		if(epoch == numEpochs - 1)
			// no epoch to highlight right of the current one
			return NaN
		endif

		// and the range epoch + 1, ...,  lastEpoch
		first = epochID[epoch + 1][%timeBegin]
		last  = epochID[numEpochs - 1][%timeEnd]
		SetScale/I x, first, last, "ms", waveBegin, waveEnd
	endif

	AppendToGraph/W=$waveBuilderGraph waveBegin
	ModifyGraph/W=$waveBuilderGraph hbFill($nameBegin)=5
	ModifyGraph/W=$waveBuilderGraph mode($nameBegin)=7, toMode($nameBegin)=1
	ModifyGraph/W=$waveBuilderGraph useNegRGB($nameBegin)=1, usePlusRGB($nameBegin)=1
	ModifyGraph/W=$waveBuilderGraph plusRGB($nameBegin)=(56576,56576,56576), negRGB($nameBegin)=(56576,56576,56576)
	ModifyGraph/W=$waveBuilderGraph rgb($nameBegin)=(65535,65535,65535)

	AppendToGraph/W=$waveBuilderGraph waveEnd
	ModifyGraph/W=$waveBuilderGraph rgb($nameEnd)=(65535,65535,65535)
End

static Function WBP_DisplaySetInPanel()

	variable i, epoch, numEpochs, numSteps
	variable red, green, blue
	string trace
	variable maxYValue, minYValue

	WAVE/Z stimSet = WB_GetStimSet()
	if(!WaveExists(stimSet))
		return NaN
	endif

	WAVE ranges = GetAxesRanges(waveBuilderGraph)
	RemoveTracesFromGraph(waveBuilderGraph)

	WAVE SegWvType = GetSegmentTypeWave()

	epoch     = GetSetVariable(panel, "setvar_WaveBuilder_CurrentEpoch")
	numEpochs = SegWvType[100]

	DFREF dfr = GetWaveBuilderDataPath()
	WBP_AddEpochHLTraces(dfr, EPOCH_HL_TYPE_LEFT, epoch, numEpochs)
	WAVE/SDFR=dfr epochHLBeginLeft, epochHLEndLeft

	WBP_AddEpochHLTraces(dfr, EPOCH_HL_TYPE_RIGHT, epoch, numEpochs)
	WAVE/SDFR=dfr epochHLBeginRight, epochHLEndRight

	WAVE displayData = GetWaveBuilderDispWave()
	Duplicate/O stimSet, displayData
	WaveClear stimSet

	numSteps = DimSize(displayData, COLS)

	if(numSteps == 0)
		return NaN
	endif

	for(i = 0; i < numSteps; i += 1)
		trace = NameOfWave(displayData) + "_S" + num2str(i)
		AppendToGraph/W=$waveBuilderGraph displayData[][i]/TN=$trace
		GetTraceColor(i, red, green, blue)
		ModifyGraph/W=$waveBuilderGraph rgb($trace) = (red, green, blue)
	endfor

	maxYValue = WaveMax(displayData)
	minYValue = WaveMin(displayData)

	epochHLBeginRight = maxYValue
	epochHLBeginLeft  = maxYValue

	epochHLEndRight   = min(0, minYValue)
	epochHLEndLeft    = min(0, minYValue)

	SetAxis/W=$waveBuilderGraph/A/E=3 left
	SetAxesRanges(waveBuilderGraph, ranges)
End

static Function WBP_UpdatePanelIfAllowed()

	string controls, deltaMode
	variable currentTab

	if(!GetCheckBoxState(panel, "check_PreventUpdate"))
		WBP_DisplaySetInPanel()
	endif

	switch(GetTabID(panel, "WBP_WaveType"))
		case 2:
			if(GetCheckBoxState(panel,"check_Noise_Pink_P41"))
				SetCheckBoxState(panel,"Check_Noise_Brown_P42", 0)
				DisableControl(panel, "Check_Noise_Brown_P42")
				DisableListOfControls(panel, "SetVar_WaveBuilder_P23;SetVar_WaveBuilder_P26;SetVar_WaveBuilder_P28;SetVar_WaveBuilder_P29")
				EnableControl(panel, "SetVar_WaveBuilder_P30")
			else
				EnableControl(panel, "Check_Noise_Brown_P42")
				EnableListOfControls(panel, "SetVar_WaveBuilder_P23;SetVar_WaveBuilder_P26;SetVar_WaveBuilder_P28;SetVar_WaveBuilder_P29")
				DisableControl(panel, "SetVar_WaveBuilder_P30")
			endif

			if(GetCheckBoxState(panel,"Check_Noise_Brown_P42"))
				SetCheckBoxState(panel,"check_Noise_Pink_P41", 0)
				DisableControl(panel, "check_Noise_Pink_P41")
				DisableListOfControls(panel, "SetVar_WaveBuilder_P23;SetVar_WaveBuilder_P26;SetVar_WaveBuilder_P28;SetVar_WaveBuilder_P29")
				EnableControl(panel, "SetVar_WaveBuilder_P30")
			else
				EnableControl(panel, "check_Noise_Pink_P41")
				EnableListOfControls(panel, "SetVar_WaveBuilder_P23;SetVar_WaveBuilder_P26;SetVar_WaveBuilder_P28;SetVar_WaveBuilder_P29")
				DisableControl(panel, "SetVar_WaveBuilder_P30")
			endif
			break
		case 3:
			if(GetCheckBoxState(panel,"check_Sin_Chirp_P43"))
				EnableListOfControls(panel, "SetVar_WaveBuilder_P24;SetVar_WaveBuilder_P25")
			else
				DisableListOfControls(panel, "SetVar_WaveBuilder_P24;SetVar_WaveBuilder_P25")
			endif
			break
		case 5:
			if(GetCheckBoxState(panel,"check_SPT_NumPulses_P46"))
				DisableControl(panel, "SetVar_WaveBuilder_P0")
				EnableListOfControls(panel, "SetVar_WaveBuilder_P45;SetVar_WaveBuilder_P47")
			else
				EnableControl(panel, "SetVar_WaveBuilder_P0")
				DisableListOfControls(panel, "SetVar_WaveBuilder_P45;SetVar_WaveBuilder_P47")
			endif
			break
		default:
			// nothing to do
			break
	endswitch

	controls = "SetVar_WB_DurDeltaMult_P52;SetVar_WB_AmpDeltaMult_P50;SetVar_WB_OffsetDeltaMult_P51;SetVar_WB_OffsetDeltaMult_P51_0;SetVar_WB_OffsetDeltaMult_P51_1;SetVar_WB_OffsetDeltaMult_P51_2;SetVar_WB_OffsetDeltaMult_P51_3;SetVar_WB_OffsetDeltaMult_P51_4;SetVar_WB_OffsetDeltaMult_P51_5"

	deltaMode = GetPopupMenuString(panel,"popup_WaveBuilder_exp_P40")
	if(!cmpstr(deltaMode, "Power") || !cmpstr(deltaMode, "Multiplier"))
		EnableListOfControls(panel, controls)
	else
		DisableListOfControls(panel, controls)
	endif
End

/// @brief Passes the data from the WP wave to the panel
static Function WBP_ParameterWaveToPanel(stimulusType)
	variable stimulusType

	string list, control
	variable segment, numEntries, i, row

	WAVE WP = GetWaveBuilderWaveParam()

	segment = GetSetVariable(panel, "setvar_WaveBuilder_CurrentEpoch")

	list = GrepList(ControlNameList(panel), ".*_P[[:digit:]]+")

	numEntries = ItemsInList(list)
	for(i = 0; i < numEntries; i += 1)
		control = StringFromList(i, list)
		row = WBP_ExtractRowNumberFromControl(control)
		WBP_SetControl(panel, control, WP[row][segment][stimulusType])
	endfor
End

/// @brief Generic wrapper for setting a control's value
static Function WBP_SetControl(win, control, value)
	string win, control
	variable value

	variable controlType

	ControlInfo/W=$win $control
	ASSERT(V_flag != 0, "Non-existing control or window")
	controlType = abs(V_flag)

	if(controlType == 1)
		// nothing to do
	elseif(controlType == 2)
		CheckBox $control, win=$win, value=(value == CHECKBOX_SELECTED)
	elseif(controlType == 5)
		SetVariable $control, win=$win, value=_NUM:value
	elseif(controlType == 3)
		PopupMenu $control, win=$win, mode=value + 1
	else
		ASSERT(0, "Unsupported control type")
	endif
End

Function WBP_SetVarProc_SetNo(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	switch(sva.eventCode)
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			WBP_UpdatePanelIfAllowed()
			break
	endswitch

	return 0
End

Function WBP_ButtonProc_DeleteSet(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	string DAorTTL, setWaveToDelete, panelTitle
	string popupMenuSelectedItemsStart, popupMenuSelectedItemsEnd
	variable i, numPanels

	switch(ba.eventCode)
		case 2: // mouse up

			setWaveToDelete = GetPopupMenuString(panel, "popup_WaveBuilder_SetList")

			if(!CmpStr(SetWaveToDelete, NONE))
				print "Select a set to delete from popup menu."
				break
			endif

			SVAR/Z/SDFR=GetITCDevicesFolder() ITCPanelTitleList
			if(SVAR_Exists(ITCPanelTitleList))
				numPanels = ItemsInList(ITCPanelTitleList)
				for(i = 0; i < numPanels; i += 1)
					panelTitle = StringFromList(i, ITCPanelTitleList)
					if(StringMatch(SetWaveToDelete, "*DA*"))
						DAorTTL = "DA"
					else
						DAorTTL = "TTL"
					endif

					popupMenuSelectedItemsStart = WBP_PopupMenuWaveNameList(DAorTTL, 0, panelTitle)
					popupMenuSelectedItemsEnd = WBP_PopupMenuWaveNameList(DAorTTL, 1, panelTitle)
					WBP_DeleteSet()
					WBP_RestorePopupMenuSelection(popupMenuSelectedItemsStart, DAorTTL, 0, panelTitle)
					WBP_RestorePopupMenuSelection(popupMenuSelectedItemsEnd, DAorTTL, 1, panelTitle)
				endfor
			else
				WBP_DeleteSet()
			endif

			WBP_UpdateITCPanelPopUps()

			ControlUpdate/W=$panel popup_WaveBuilder_SetList
			PopupMenu popup_WaveBuilder_SetList win=$panel, mode = 1
			break
	endswitch

	return 0
End

Function WBP_SetVarProc_SweepCount(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	switch(sva.eventCode)
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			WBP_LowPassDeltaLimits()
			WBP_HighPassDeltaLimits()
			WAVE SegWvType = GetSegmentTypeWave()
			SegWvType[101] = sva.dval
			WBP_UpdatePanelIfAllowed()
			break
	endswitch

	return 0
End

Function WBP_ButtonProc_AutoScale(ctrlName) : ButtonControl
	String ctrlName

	SetAxis/A/W=$WaveBuilderGraph
End

Function WBP_CheckProc(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	switch(cba.eventCode)
		case EVENT_MOUSE_UP:
			WBP_UpdateControlAndWP(cba.ctrlName, cba.checked)
			WBP_UpdatePanelIfAllowed()
			break
	endswitch

	return 0
End

/// @brief Additional `initialhook` called in `ACL_DisplayTab`
Function WBP_InitialTabHook(tca)
	STRUCT WMTabControlAction &tca

	string type
	variable tabnum, idx
	Wave SegWvType = GetSegmentTypeWave()

	tabnum = tca.tab

	type = GetPopupMenuString(panel, "popup_WaveBuilder_OutputType")
	if(!CmpStr(type, "TTL"))
		// only allow 0th and 5th tab for TTL wave type
		if(tabnum == 1 || tabnum == 2 || tabnum == 3 || tabnum == 4 || tabnum == 6)
			return 1
		endif
	endif

	idx = GetSetVariable(panel, "setvar_WaveBuilder_CurrentEpoch")
	ASSERT(idx <= SEGMENT_TYPE_WAVE_LAST_IDX, "Only supports up to different SEGMENT_TYPE_WAVE_LAST_IDX epochs")
	SegWvType[idx] = tabnum

	WBP_ParameterWaveToPanel(tabnum)
	WBP_UpdatePanelIfAllowed()
	return 0
End

/// @brief Additional `finalhook` called in `ACL_DisplayTab`
Function WBP_FinalTabHook(tca)
	STRUCT WMTabControlAction &tca

	if(tca.tab == 7)
		HideListOfControls(tca.win, "SetVar_WaveBuilder_P0;SetVar_WaveBuilder_P1;SetVar_WaveBuilder_P2;SetVar_WaveBuilder_P3;SetVar_WB_DurDeltaMult_P52;SetVar_WB_AmpDeltaMult_P50;popup_WaveBuilder_exp_P40")
	endif

	return 0
End

Function WBP_ButtonProc_SaveSet(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch(ba.eventCode)
		case 2: // mouse up

			RemoveTracesFromGraph(WaveBuilderGraph)
			WBP_SaveSetParam()
			WBP_UpdateITCPanelPopUps()

			SetSetVariableString(panel, "setvar_WaveBuilder_baseName", "StimulusSetA")
			ControlUpdate/W=$panel popup_WaveBuilder_SetList

			SetPopupMenuIndex(panel, "popup_af_preDAQEvent_S1",  0)
			SetPopupMenuIndex(panel, "popup_af_MidSweep_S2",     0)
			SetPopupMenuIndex(panel, "popup_af_PostSweep_S3",    0)
			SetPopupMenuIndex(panel, "popup_af_PostSet_S4",      0)
			SetPopupMenuIndex(panel, "popup_af_postDAQEvent_S5", 0)
			WBP_AnaFuncsToWPT()
			break
	endswitch
End

/// @brief Returns the row index into the parameter wave of the parameter represented by the named control
///
/// @param control name of the control, the expected format is `$str_P$row_$suffix` where `$str` may contain any
/// characters but `$suffix` is not allowed to include the substring `_P`.
static Function WBP_ExtractRowNumberFromControl(control)
	string control

	variable start, stop, row

	start = strsearch(control, "_P", Inf, 1)
	ASSERT(start != -1, "Could not find the row indicator in the parameter name")

	stop = strsearch(control, "_", start + 2)

	if(stop == -1)
		stop = Inf
	endif

	row = str2num(control[start + 2,stop - 1])
	ASSERT(IsFinite(row), "Non finite row")

	return row
End

/// @brief Update the named control and pass its new value into the parameter wave
Function WBP_UpdateControlAndWP(control, value)
	string control
	variable value

	variable maxDuration, stimulusType, epoch, paramRow

	WAVE WP = GetWaveBuilderWaveParam()

	WBP_SetControl(panel, control, value)

	stimulusType = GetTabID(panel, "WBP_WaveType")
	epoch        = GetSetVariable(panel, "setvar_WaveBuilder_CurrentEpoch")
	paramRow     = WBP_ExtractRowNumberFromControl(control)
	WP[paramRow][epoch][stimulusType] = value

	if(stimulusType == 2)
		WBP_LowPassDeltaLimits()
		WBP_HighPassDeltaLimits()
		WBP_CutOffCrossOver()
	elseif(stimulusType == 5)
		maxDuration = WBP_ReturnPulseDurationMax()
		SetVariable SetVar_WaveBuilder_P8 win=$panel, limits = {0, maxDuration, 0.1}
		if(GetSetVariable(panel, "SetVar_WaveBuilder_P8") > maxDuration)
			SetSetVariable(panel, "SetVar_WaveBuilder_P8", maxDuration)
		endif
	endif
End

Function WBP_SetVarProc_UpdateParam(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	switch(sva.eventCode)
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			WBP_UpdateControlAndWP(sva.ctrlName, sva.dval)
			WBP_UpdatePanelIfAllowed()
			break
	endswitch

	return 0
End

Function WBP_SetVarProc_ITI(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			Wave SegWvType = GetSegmentTypeWave()
			SegWvType[99] = sva.dval
			WBP_UpdatePanelIfAllowed()
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

static Function WBP_LowPassDeltaLimits()

	variable LowPassCutOff, StepCount, LowPassDelta, DeltaLimit

	WAVE SegWvType = GetSegmentTypeWave()
	StepCount = SegWvType[101]

	LowPassCutoff = GetSetVariable(panel, "SetVar_WaveBuilder_P20")
	LowPassDelta = GetSetVariable(panel, "SetVar_WaveBuilder_P21")

	if(LowPassDelta > 0)
		DeltaLimit = trunc(100000 / StepCount)
		SetVariable SetVar_WaveBuilder_P21 win=$panel, limits = {-inf, DeltaLimit, 1}
		if(LowPassDelta > DeltaLimit)
			SetSetVariable(panel, "SetVar_WaveBuilder_P21", DeltaLimit)
		endif
	endif

	if(LowPassDelta < 0)
		DeltaLimit = trunc(-((LowPassCutOff/StepCount) -1))
		SetVariable SetVar_WaveBuilder_P21 win=$panel, limits = {DeltaLimit, 99999, 1}
		if(LowPassDelta < DeltaLimit)
			SetSetVariable(panel, "SetVar_WaveBuilder_P21", DeltaLimit)
		endif
	endif
End

static Function WBP_HighPassDeltaLimits()

	variable HighPassCutOff, StepCount, HighPassDelta, DeltaLimit

	WAVE SegWvType = GetSegmentTypeWave()
	StepCount = SegWvType[101]

	HighPassCutoff = GetSetVariable(panel, "SetVar_WaveBuilder_P22")
	HighPassDelta = GetSetVariable(panel, "SetVar_WaveBuilder_P23")

	if(HighPassDelta > 0)
		DeltaLimit = trunc((100000 - HighPassCutOff) / StepCount) - 1
		SetVariable SetVar_WaveBuilder_P23 win=$panel, limits = { -inf, DeltaLimit, 1}
		if(HighPassDelta > DeltaLimit)
			SetSetVariable(panel, "SetVar_WaveBuilder_P23", DeltaLimit)
		endif
	endif

	if(HighPassDelta < 0)
		DeltaLimit = trunc(HighPassCutOff / StepCount) + 1
		SetVariable SetVar_WaveBuilder_P23 win=$panel, limits = {DeltaLimit, 99999, 1}
		if(HighPassDelta < DeltaLimit)
			SetSetVariable(panel, "SetVar_WaveBuilder_P23", DeltaLimit)
		endif
	endif
End

static Function WBP_ExecuteAdamsTabcontrol(tabID)
	variable tabID

	TabControl $"WBP_WaveType" win=$panel, value = tabID
	return ChangeTab(panel, "WBP_WaveType", tabID)
End

static Function WBP_ChangeWaveType(stimulusType)
	variable stimulusType

	WAVE SegWvType = GetSegmentTypeWave()
	WAVE WP = GetWaveBuilderWaveParam()

	string list

	list  = "SetVar_WaveBuilder_P3;SetVar_WaveBuilder_P4;SetVar_WaveBuilder_P5;"
	list += "SetVar_WaveBuilder_P4_OD00;SetVar_WaveBuilder_P4_OD01;SetVar_WaveBuilder_P4_OD02;SetVar_WaveBuilder_P4_OD03;SetVar_WaveBuilder_P4_OD04;"
	list += "SetVar_WaveBuilder_P5_DD02;SetVar_WaveBuilder_P5_DD03;SetVar_WaveBuilder_P5_DD04;SetVar_WaveBuilder_P5_DD05;SetVar_WaveBuilder_P5_DD06;"

	if(stimulusType == STIMULUS_TYPE_TLL)
		// recreate SegWvType with its defaults
		KillOrMoveToTrash(wv=GetSegmentTypeWave())

		WP[1,6][][] = 0

		SetVariable SetVar_WaveBuilder_P2 win = $panel, limits = {0,1,1}
		DisableListOfControls(panel, list)

		WBP_UpdateControlAndWP("SetVar_WaveBuilder_P2", 0)
		WBP_UpdateControlAndWP("SetVar_WaveBuilder_P3", 0)
		WBP_UpdateControlAndWP("SetVar_WaveBuilder_P4", 0)
		WBP_UpdateControlAndWP("SetVar_WaveBuilder_P5", 0)
		WBP_UpdatePanelIfAllowed()

		WBP_ExecuteAdamsTabcontrol(0)
	elseif(stimulusType == STIMULUS_TYPE_DA)
		SetVariable SetVar_WaveBuilder_P2 win =$panel, limits = {-inf,inf,1}
		EnableListOfControls(panel, list)
	else
		ASSERT(0, "Unknown stimulus type")
	endif
End

Function WBP_PopMenuProc_WaveType(pa) : PopupMenuControl
	STRUCT WMPopupAction& pa

	switch(pa.eventCode)
		case 2:
			if(!cmpstr(pa.popStr,"TTL"))
				WBP_ChangeWaveType(STIMULUS_TYPE_TLL)
			else
				WBP_ChangeWaveType(STIMULUS_TYPE_DA)
			endif
			break
	endswitch

	return 0
End

static Function WBP_UpdateListOfWaves()

	string searchPattern = "*"

	dfref dfr = WBP_GetFolderPath()

	ControlInfo/W=$panel setvar_WaveBuilder_SearchString
	if(!IsEmpty(s_value))
		searchPattern = S_Value
	endif

	dfref saveDFR = GetDataFolderDFR()
	SetDataFolder dfr
	string ListOfWavesInFolder = "\"" + NONE + ";" + Wavelist(searchPattern, ";", "TEXT:0,MAXCOLS:1") + "\""
	SetDataFolder saveDFR

	PopupMenu popup_WaveBuilder_ListOfWaves win=$panel, value = #ListOfWavesInFolder
End

Function WBP_SetVarProc_SetSearchString(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName

	WBP_UpdateListOfWaves()
End

Function WBP_PopMenuProc_WaveToLoad(pa) : PopupMenuControl
	struct WMPopupAction& pa

	variable SegmentNo
	string win

	switch(pa.eventCode)
		case 2:
			win = pa.win

			WAVE/T WPT = GetWaveBuilderWaveTextParam()

			dfref dfr = WBP_GetFolderPath()
			Wave/Z/SDFR=dfr customWave = $pa.popStr

			SegmentNo = GetSetVariable(win, "setvar_WaveBuilder_CurrentEpoch")

			if(WaveExists(customWave))
				WPT[0][SegmentNo] = GetWavesDataFolder(customWave, 2)
			else
				WPT[0][SegmentNo] = ""
			endif

			WBP_UpdatePanelIfAllowed()
		break
	endswitch
End

/// @brief This function creates a string that is used to name the 2d output wave of the wavebuilder panel.
///
/// The naming is based on userinput to the wavebuilder panel
static Function/S WBP_AssembleSetName()
	string AssembledBaseName = ""

	ControlInfo/W=$panel setvar_WaveBuilder_baseName
	AssembledBaseName += s_value[0,15]
	ControlInfo/W=$panel popup_WaveBuilder_OutputType
	AssembledBaseName += "_" + s_value + "_"
	ControlInfo/W=$panel setvar_WaveBuilder_SetNumber
	AssembledBaseName += num2str(v_value)

	return CleanupName(AssembledBaseName, 0)
End

/// @brief Return the output type, one of #CHANNEL_TYPE_DAC or #CHANNEL_TYPE_TTL
Function WBP_GetOutputType()

	variable outputType, idx
	idx = GetPopupMenuIndex(panel, "popup_WaveBuilder_OutputType")

	switch(idx)
		case 0:
			outputType = CHANNEL_TYPE_DAC
			break
		case 1:
			outputType = CHANNEL_TYPE_TTL
			break
		default:
			ASSERT(0, "unknown channelType")
			break
	endswitch

	return outputType
End

/// @brief Return a list of all stim sets for the given type
/// @param setType One of `DA` or `TTL`
Function/S WBP_ReturnListSavedSets(setType)
	string setType

	string path, list, stimSetList
	variable numWaves, i
	path= GetWBSvdStimSetParamPathAS() + ":" + setType

	list = GetListOfWaves($path, "WP_.*" + setType + ".*")
	stimSetList = ""

	numWaves = ItemsInList(list)
	for(i = 0; i < numWaves; i += 1)
		stimSetList = AddListItem(RemovePrefix(StringFromList(i, list), startStr="WP_"), stimSetList, ";", Inf)
	endfor

	return SortList(stimSetList, ";", 16)
end

static Function WBP_SaveSetParam()

	string setName

	WAVE SegWvType = GetSegmentTypeWave()
	WAVE WP        = GetWaveBuilderWaveParam()
	WAVE WPT       = GetWaveBuilderWaveTextParam()

	DFREF dfr = GetSetParamFolder(WBP_GetOutputType())
	setName = WBP_AssembleSetName()

	Duplicate/O SegWvType , dfr:$("SegWvType_" + setName)
	Duplicate/O WP	       , dfr:$("WP_" + setName)
	Duplicate/O WPT       , dfr:$("WPT_" + setName)
End

static Function WBP_LoadSet()
	string setName, funcList

	ControlInfo/W=$panel popup_WaveBuilder_SetList
	setName = s_value

	if(!CmpStr(SetName, NONE))
		Print "Select set to load from popup menu."
		return NaN
	endif

	if(StringMatch(SetName, "*TTL*"))
		PopupMenu popup_WaveBuilder_OutputType win=$panel, mode = 2
		WBP_ChangeWaveType(STIMULUS_TYPE_TLL)
		dfref dfr = GetWBSvdStimSetParamTTLPath()
	else
		PopupMenu popup_WaveBuilder_OutputType win=$panel, mode = 1
		WBP_ChangeWaveType(STIMULUS_TYPE_DA)
		dfref dfr = GetWBSvdStimSetParamDAPath()
	endif

	Wave/SDFR=dfr WP        = $"WP_"  + setName
	Wave/T/SDFR=dfr WPT     = $"WPT_" + setName
	Wave/SDFR=dfr SegWvType = $"SegWvType_" + setName

	DFREF dfr = GetWaveBuilderDataPath()
	Duplicate/O WP, dfr:WP
	Duplicate/O WPT, dfr:WPT
	Duplicate/O SegWvType, dfr:SegWvType

	// fetch wave references, possibly updating the wave layout if required
	WAVE WP        = GetWaveBuilderWaveParam()
	WAVE/T WPT     = GetWaveBuilderWaveTextParam()
	WAVE SegWvType = GetSegmentTypeWave()

	SetCheckBoxState(panel, "check_FlipEpoch_S98", SegWvType[98])

	// we might be called from an old panel without an ITI setvariable control
	ControlInfo/W=$panel setvar_WaveBuilder_ITI
	if(V_flag > 0)
		SetSetVariable(panel, "setvar_WaveBuilder_ITI", SegWvType[99])
	endif

	SetSetVariable(panel, "SetVar_WB_NumEpochs_S100", SegWvType[100])
	SetSetVariable(panel, "SetVar_WB_SweepCount_S101", SegWvType[101])
	SetSetVariable(panel, "setvar_WaveBuilder_CurrentEpoch", 0)

	funcList = WBP_GetAnalysisFunctions()
	SetAnalysisFunctionIfFuncExists(panel, "popup_af_preDAQEvent_S1", funcList, WPT[1][99])
	SetAnalysisFunctionIfFuncExists(panel, "popup_af_midSweep_S2", funcList, WPT[2][99])
	SetAnalysisFunctionIfFuncExists(panel, "popup_af_postSweep_S3", funcList, WPT[3][99])
	SetAnalysisFunctionIfFuncExists(panel, "popup_af_postSet_S4", funcList, WPT[4][99])
	SetAnalysisFunctionIfFuncExists(panel, "popup_af_postDAQEvent_S5", funcList, WPT[5][99])

	WBP_ExecuteAdamsTabControl(SegWvType[0])
	WBP_ParameterWaveToPanel(SegWvType[0])
	WBP_UpdateEpochControls()
End

static Function SetAnalysisFunctionIfFuncExists(win, ctrl, funcList, func)
	string win, ctrl, funcList, func

	variable idx

	idx = WhichListItem(func, funcList)

	if(idx == -1)
		idx = 0 // selects NONE
	endif

	SetPopupMenuIndex(win, ctrl, idx)
End

static Function WBP_DeleteSet()

	string WPName, WPTName, SegWvTypeName, setName

	setName = GetPopupMenuString(panel, "popup_WaveBuilder_SetList")

	WPName = "WP_" + setName
	WPTName = "WPT_" + setName
	SegWvTypeName = "SegWvType_" + setName

	// makes sure that a set is selected
	if(!CmpStr(setName, NONE))
		return NaN
	endif

	if(StringMatch(setName, "*TTL*"))
		dfref paramDFR = GetWBSvdStimSetParamTTLPath()
		dfref dfr      = GetWBSvdStimSetTTLPath()
	else
		dfref paramDFR = GetWBSvdStimSetParamDAPath()
		dfref dfr      = GetWBSvdStimSetDAPath()
	endif

	KillOrMoveToTrash(wv=dfr:$SetName)
	KillOrMoveToTrash(wv=paramDFR:$WPName)
	KillOrMoveToTrash(wv=paramDFR:$WPTName)
	KillOrMoveToTrash(wv=paramDFR:$SegWvTypeName)
End

static Function WBP_UpdateEpochControls()

	variable currentEpoch, numEpochs

	WAVE SegWvType = GetSegmentTypeWave()
	currentEpoch = GetSetVariable("WaveBuilder", "setvar_WaveBuilder_CurrentEpoch")
	numEpochs = SegWvType[100]

	SetVariable setvar_WaveBuilder_CurrentEpoch win=$panel, limits = {0, numEpochs - 1, 1}

	if(currentEpoch >= numEpochs)
		SetSetVariable(panel, "setvar_WaveBuilder_CurrentEpoch", numEpochs - 1)
		WBP_SelectEpoch(numEpochs - 1)
	else
		WBP_UpdatePanelIfAllowed()
	endif
End

static Function WBP_SelectEpoch(epoch)
	variable epoch

	WAVE SegWvType = GetSegmentTypeWave()

	WBP_ExecuteAdamsTabcontrol(SegWvType[epoch])
	WBP_ParameterWaveToPanel(SegWvType[epoch])
	WBP_UpdatePanelIfAllowed()
End

Function WBP_SetVarProc_TotEpoch(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	switch(sva.eventCode)
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			WAVE SegWvType = GetSegmentTypeWave()
			SegWvType[100] = sva.dval
			WBP_UpdateEpochControls()
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function WBP_SetVarProc_EpochToEdit(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	switch(sva.eventCode)
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			WBP_SelectEpoch(sva.dval)
			break
	endswitch
End

Function WBP_ButtonProc_LoadSet(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch(ba.eventCode)
		case 2: // mouse up
			WBP_LoadSet()
			break
	endswitch

	return 0
End

static Function WBP_CutOffCrossOver()

	variable HighPassCutOff, LowPassCutOff

	LowPassCutOff = GetSetVariable(panel, "SetVar_WaveBuilder_P20")
	HighPassCutOff = GetSetVariable(panel, "SetVar_WaveBuilder_P22")

	if(HighPassCutOff >= LowPassCutOff)
		SetSetVariable(panel, "SetVar_WaveBuilder_P20", HighPassCutOff + 1)
	endif

	if(LowPassCutOff <= HighPassCutOff)
		SetSetVariable(panel, "SetVar_WaveBuilder_P22", LowPassCutOff - 1)
	endif
End

/// @brief Checks to see if the pulse duration in square pulse stimulus trains is too long
static Function WBP_ReturnPulseDurationMax()

	variable frequency

	if(GetCheckBoxState(panel, "check_SPT_NumPulses_P46"))
		return Inf
	endif

	frequency = GetSetVariable(panel, "SetVar_WaveBuilder_P6_FD01")

	return 1000 / frequency
End

Function/DF WBP_GetFolderPath()

	ControlInfo/W=$panel group_WaveBuilder_FolderPath
	if(IsEmpty(S_value) || !DataFolderExists(S_value))
		return $"root:"
	else
		return $S_value
	endif
End

Function/S WBP_ReturnFoldersList()

	string parent
	string folderNameList = ""
	string folderName
	variable i = 0

	DFREF dfr = WBP_GetFolderPath()
	do
		folderName = GetIndexedObjNameDFR(dfr, 4, i)
		if (strlen(folderName) == 0)
			break
		endif
		folderNameList = AddListItem(folderName, folderNamelist, ";", inf)
		i += 1
	while(1)

	return NONE + ";root:;" + folderNameList
End

Function WBP_PopMenuProc_FolderSelect(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr

	string path, list

	if(!CmpStr(popStr, NONE))
		return 0
	elseif(!CmpStr(popStr, "root:"))
		path = "root:"
	else
		ControlInfo group_WaveBuilder_FolderPath
		path = s_value + popStr + ":"
	endif

	GroupBox group_WaveBuilder_FolderPath win=$panel, title = path
	ControlUpdate/A/W=$panel
	PopupMenu popup_WaveBuilder_FolderList win=$panel, mode = 1
	PopupMenu popup_WaveBuilder_ListOfWaves win=$panel, mode = 1
	WBP_UpdateListOfWaves()
	ControlUpdate/A/W=$panel
End

/// @brief Update the popup menus and its `MenuExp` user data after stim set changes
///
/// @param panelTitle [optional, defaults to all locked devices] device
Function WBP_UpdateITCPanelPopUps([panelTitle])
	string panelTitle

	variable i, numPanels
	string ctrlWave, ctrlIndexEnd, DAlist, TTLlist, listOfPanels

	if(ParamIsDefault(panelTitle))
		SVAR/Z/SDFR=GetITCDevicesFolder() ITCPanelTitleList
		if(!SVAR_Exists(ITCPanelTitleList))
			return NaN
		endif
		listOfPanels = ITCPanelTitleList
	else
		listOfPanels = panelTitle
	endif

	DEBUGPRINT("Updating", str=listOfPanels)

	DAlist  = ReturnListOfAllStimSets(CHANNEL_TYPE_DAC, CHANNEL_DA_SEARCH_STRING)
	TTLlist = ReturnListOfAllStimSets(CHANNEL_TYPE_TTL, CHANNEL_TTL_SEARCH_STRING)

	numPanels = ItemsInList(listOfPanels)
	for(i = 0; i < numPanels; i += 1)
		panelTitle = StringFromList(i, listOfPanels)

		for(i = 0; i < NUM_DA_TTL_CHANNELS; i += 1)
			ctrlWave     = GetPanelControl(panelTitle, i, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE)
			ctrlIndexEnd = GetPanelControl(panelTitle, i, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_INDEX_END)
			SetControlUserData(panelTitle, ctrlWave, "MenuExp", DAlist)
			SetControlUserData(panelTitle, ctrlIndexEnd, "MenuExp", DAlist)

			ctrlWave     = GetPanelControl(panelTitle, i, CHANNEL_TYPE_TTL, CHANNEL_CONTROL_WAVE)
			ctrlIndexEnd = GetPanelControl(panelTitle, i, CHANNEL_TYPE_TTL, CHANNEL_CONTROL_INDEX_END)
			SetControlUserData(panelTitle, ctrlWave, "MenuExp", TTLlist)
			SetControlUserData(panelTitle, ctrlIndexEnd, "MenuExp", TTLlist)
		endfor
	endfor
End

/// @brief Returns the names of the items in the popmenu controls in a list
static Function/S WBP_PopupMenuWaveNameList(DAorTTL, StartOrEnd, panelTitle)
	string DAorTTL, panelTitle
	variable StartOrEnd

	string ListOfSelectedWaveNames = ""
	string popupMenuName
	variable i
	DelayUpdate
	do
		switch(StartOrEnd)
			case 0:
				popupMenuName = "Wave_" + DAorTTL + "_0" + num2str(i)
				break
			case 1:
				popupMenuName = "Popup_" + DAorTTL + "_IndexEnd_0" + num2str(i)
				break
		endswitch
		ControlInfo/W=$panelTitle $popupMenuName
		ListOfSelectedWaveNames += s_value + ";"
		i += 1
	while(i < NUM_DA_TTL_CHANNELS)

	return ListOfSelectedWaveNames
End

static Function WBP_RestorePopupMenuSelection(ListOfSelections, DAorTTL, StartOrEnd, panelTitle)
	string ListOfSelections, DAorTTL, panelTitle
	variable StartOrEnd
	string popupMenuName
	string CheckBoxName
	variable i
	DelayUpdate

	do
		switch(StartOrEnd)
			case 0:
				popupMenuName = "Wave_"+DAorTTL+"_0"+ num2str(i)
				break
			case 1:
				popupMenuName = "Popup_"+DAorTTL+"_IndexEnd_0"+num2str(i)
				break
			endswitch
		ControlInfo/w=$panelTitle $popupMenuName
		if(cmpstr(s_value, stringfromlist(i, ListOfSelections,";")) == 1 || cmpstr(s_value,"")==0)
			PopupMenu  $popupMenuName win = $panelTitle, mode = v_value - 1
			ControlInfo /w = $panelTitle $popupMenuName
			if(!IsTestPulseSet(s_value))
				PopupMenu  $popupMenuName win = $panelTitle, mode=1
				CheckBoxName = "Check_" + DAorTTL + "_0" + num2str(i)
				CheckBox Check_DA_00 win = $panelTitle, value = 0
			endif
		endif
		i += 1
	while(i < NUM_DA_TTL_CHANNELS)
	DoUpdate /W = $panelTitle
End

Function WBP_CheckProc_PreventUpdate(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked

	variable tabID, maxDur

	if(!checked)
		tabID = GetTabID(panel, "WBP_WaveType")
		if(tabID == 2)
			WBP_LowPassDeltaLimits()
			WBP_HighPassDeltaLimits()
			WBP_CutOffCrossOver()
		elseif(tabID == 5)
			maxDur = WBP_ReturnPulseDurationMax()
			SetVariable SetVar_WaveBuilder_P8 win=$panel, limits = {0, maxDur, 0.1}
			if(GetSetVariable(panel, "SetVar_WaveBuilder_P8") > maxDur)
				SetSetVariable(panel, "SetVar_WaveBuilder_P8", maxDur)
			endif
		endif
		WBP_UpdatePanelIfAllowed()
	endif
End

Function WBP_DeltaPopup(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	switch(pa.eventCode)
		case 2:
			WBP_UpdateControlAndWP(pa.ctrlName, pa.popNum - 1)
			WBP_UpdatePanelIfAllowed()
			break
	endswitch

	return 0
End

Function WBP_ButtonProc_NewSeed(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch(ba.eventCode)
		case 2: // mouse up
			WBP_UpdateControlAndWP(ba.ctrlName, GetNonReproducibleRandom())
			WBP_UpdatePanelIfAllowed()
			break
	endswitch

	return 0
End

Function WBP_CheckProc_FlipStimSet(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	switch( cba.eventCode )
		case 2: // mouse up
			Wave SegWvType = GetSegmentTypeWave()
			SegWvType[98] = cba.checked
			WBP_UpdatePanelIfAllowed()
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function WBP_PopupMenu_AnalysisFunctions(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	switch(pa.eventCode)
		case 2: // mouse up
			WBP_AnaFuncsToWPT()
			break
	endswitch

	return 0
End

Function WBP_AnaFuncsToWPT()

	string func

	WAVE/T WPT = GetWaveBuilderWaveTextParam()

	func = GetPopupMenuString(panel, "popup_af_preDAQEvent_S1")
	WPT[1][99] = SelectString(cmpstr(func, NONE), "", func)
	func = GetPopupMenuString(panel, "popup_af_MidSweep_S2")
	WPT[2][99] = SelectString(cmpstr(func, NONE), "", func)
	func = GetPopupMenuString(panel, "popup_af_PostSweep_S3")
	WPT[3][99] = SelectString(cmpstr(func, NONE), "", func)
	func = GetPopupMenuString(panel, "popup_af_PostSet_S4")
	WPT[4][99] = SelectString(cmpstr(func, NONE), "", func)
	func = GetPopupMenuString(panel, "popup_af_postDAQEvent_S5")
	WPT[5][99] = SelectString(cmpstr(func, NONE), "", func)
End

/// @brief Return a list of analysis functions including NONE, usable for popup menues
Function/S WBP_GetAnalysisFunctions()

	string funcList, func
	string funcListClean = NONE
	variable numEntries, i

	funcList = FunctionList("!AF_PROTO_ANALYSIS_FUNC*", ";", "KIND:2,WIN:MIES_AnalysisFunctions.ipf")

	numEntries = ItemsInList(funcList)
	for(i = 0; i < numEntries; i += 1)
		func = StringFromList(i, funcList)

		// assign each function to the function reference of type AF_PROTO_ANALYSIS_FUNC_V1
		// this allows to check if the signature of func is the same as the one of AF_PROTO_ANALYSIS_FUNC_V1
		FUNCREF AF_PROTO_ANALYSIS_FUNC_V1 f = $func

		if(FuncRefIsAssigned(FuncRefInfo(f))) // func has the expected signature
			funcListClean = AddListItem(func, funcListClean, ";", Inf)
		endif
	endfor

	return funcListClean
End

Function WBP_ButtonProc_OpenAnaFuncs(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch(ba.eventCode)
		case 2: // mouse up
			DisplayProcedure/L=(5)/W=$"MIES_AnalysisFunctions.ipf"
			break
	endswitch

	return 0
End
