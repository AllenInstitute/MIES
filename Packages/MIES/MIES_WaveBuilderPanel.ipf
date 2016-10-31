#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma igorVersion=7.0

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_WBP
#endif

/// @file MIES_WaveBuilderPanel.ipf
/// @brief __WBP__ Panel for creating stimulus sets

// stock igor
#include <Resize Controls>

// third party includes
#include ":ACL_TabUtilities"
#include ":ACL_UserdataEditor"

// ZeroMQ procedures
#include ":..:ZeroMQ:procedures:ZeroMQ_Interop"

// our includes
#include ":MIES_AnalysisFunctionHelpers"
#include ":MIES_AnalysisFunctionPrototypes"
#include ":MIES_ArtefactRemoval"
#include ":MIES_Cache"
#include ":MIES_Constants"
#include ":MIES_Debugging"
#include ":MIES_EnhancedWMRoutines"
#include ":MIES_GlobalStringAndVariableAccess"
#include ":MIES_GuiUtilities"
#include ":MIES_MiesUtilities"
#include ":MIES_ProgrammaticGUIControl"
#include ":MIES_PulseAveraging"
#include ":MIES_Utilities"
#include ":MIES_Structures"
#include ":MIES_WaveDataFolderGetters"
#include ":MIES_WaveBuilder"

Menu "Mies Panels", dynamic
		"WaveBuilder", /Q,  WBP_CreateWaveBuilderPanel()
End

static StrConstant panel                     = "WaveBuilder"
static StrConstant WaveBuilderGraph          = "WaveBuilder#WaveBuilderGraph"
static StrConstant DEFAULT_SET_PREFIX        = "StimulusSetA"

// Equal to the indizes of the Wave Type popup menu
static Constant  STIMULUS_TYPE_DA            = 1
static Constant  STIMULUS_TYPE_TLL           = 2

/// @name Parameters for WBP_TranslateControlContents()
/// @{
static Constant FROM_PANEL_TO_WAVE = 0x1
static Constant FROM_WAVE_TO_PANEL = 0x2
/// @}

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
	ListBox listbox_combineEpochMap, listWave=GetWBEpochCombineList()
	AddVersionToPanel(panel, WAVEBUILDER_PANEL_VERSION)
End

Window WaveBuilder() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /K=1 /W=(106,687,1113,1325)
	SetDrawLayer UserBack
	SetDrawEnv fname= "MS Sans Serif",fsize= 16,fstyle= 1
	DrawText 32,25,"Set Parameters"
	TabControl WBP_WaveType,pos={187.00,3.00},size={686.00,205.00},proc=ACL_DisplayTab
	TabControl WBP_WaveType,userdata(tabcontrol)=  "WBP_WaveType"
	TabControl WBP_WaveType,userdata(currenttab)=  "0"
	TabControl WBP_WaveType,userdata(initialhook)=  "WBP_InitialTabHook"
	TabControl WBP_WaveType,userdata(finalhook)=  "WBP_FinalTabHook"
	TabControl WBP_WaveType,userdata(ResizeControlsInfo)= A"!!,GK!!#8L!!#D;J,hr2z!!#](Aon\"Qzzzzzzzzzzzzzz!!#o2B4uAezz"
	TabControl WBP_WaveType,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	TabControl WBP_WaveType,userdata(ResizeControlsInfo) += A"zzz!!#N3Bk1ct<C]S7zzzzzzzzzzzzz!!!"
	TabControl WBP_WaveType,tabLabel(0)="Square pulse",tabLabel(1)="Ramp"
	TabControl WBP_WaveType,tabLabel(2)="Noise",tabLabel(3)="Sin"
	TabControl WBP_WaveType,tabLabel(4)="Saw tooth",tabLabel(5)="Pulse train"
	TabControl WBP_WaveType,tabLabel(6)="PSC",tabLabel(7)="Load"
	TabControl WBP_WaveType,tabLabel(8)="Combine",value= 0
	TabControl WBP_Set_Parameters,pos={3.00,29.00},size={182.00,174.00},proc=ACL_DisplayTab
	TabControl WBP_Set_Parameters,userdata(finalhook)=  "WBP_FinalTabHook"
	TabControl WBP_Set_Parameters,userdata(currenttab)=  "0"
	TabControl WBP_Set_Parameters,userdata(ResizeControlsInfo)= A"!!,>M!!#=K!!#AE!!#A=z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	TabControl WBP_Set_Parameters,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	TabControl WBP_Set_Parameters,userdata(ResizeControlsInfo) += A"zzz!!#N3Bk1ct<C]S7zzzzzzzzzzzzz!!!"
	TabControl WBP_Set_Parameters,labelBack=(60928,60928,60928),tabLabel(0)="Basic"
	TabControl WBP_Set_Parameters,tabLabel(1)="Analysis Functions",value= 0
	SetVariable SetVar_WB_NumEpochs_S100,pos={35.00,81.00},size={124.00,22.00},proc=WBP_SetVarProc_TotEpoch,title="Total Epochs"
	SetVariable SetVar_WB_NumEpochs_S100,help={"Number of consecutive epochs in a sweep"}
	SetVariable SetVar_WB_NumEpochs_S100,userdata(tabcontrol)=  "WBP_Set_Parameters"
	SetVariable SetVar_WB_NumEpochs_S100,userdata(tabnum)=  "0"
	SetVariable SetVar_WB_NumEpochs_S100,userdata(ResizeControlsInfo)= A"!!,Cp!!#?[!!#@\\!!#<hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WB_NumEpochs_S100,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WB_NumEpochs_S100,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WB_NumEpochs_S100,fSize=14,limits={1,100,1},value= _NUM:1
	SetVariable SetVar_WaveBuilder_P0,pos={194.00,34.00},size={100.00,18.00},proc=WBP_SetVarProc_UpdateParam,title="Duration"
	SetVariable SetVar_WaveBuilder_P0,help={"Duration (ms) of the epoch being edited."}
	SetVariable SetVar_WaveBuilder_P0,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P0,userdata(ResizeControlsInfo)= A"!!,GR!!#=k!!#@,!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P0,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P0,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P0,limits={0,inf,1},value= _NUM:0
	SetVariable SetVar_WaveBuilder_P1,pos={300.00,34.00},size={100.00,18.00},proc=WBP_SetVarProc_UpdateParam,title="Delta"
	SetVariable SetVar_WaveBuilder_P1,help={"Sweep to sweep duration delta."}
	SetVariable SetVar_WaveBuilder_P1,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P1,userdata(ResizeControlsInfo)= A"!!,HQ!!#=k!!#@,!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P1,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P1,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P1,value= _NUM:0
	SetVariable SetVar_WB_SweepCount_S101,pos={32.00,105.00},size={127.00,22.00},proc=WBP_SetVarProc_SweepCount,title="Total Sweeps"
	SetVariable SetVar_WB_SweepCount_S101,help={"Number of sweeps in a stimulus set."}
	SetVariable SetVar_WB_SweepCount_S101,userdata(tabcontrol)=  "WBP_Set_Parameters"
	SetVariable SetVar_WB_SweepCount_S101,userdata(tabnum)=  "0"
	SetVariable SetVar_WB_SweepCount_S101,userdata(ResizeControlsInfo)= A"!!,Cd!!#@6!!#@b!!#<hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WB_SweepCount_S101,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WB_SweepCount_S101,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WB_SweepCount_S101,fSize=14,limits={1,99,1},value= _NUM:1
	SetVariable setvar_WaveBuilder_P10,pos={552.00,34.00},size={100.00,18.00},disable=1,proc=WBP_SetVarProc_UpdateParam,title="Tau Rise"
	SetVariable setvar_WaveBuilder_P10,help={"PSC exponential rise time constant (ms)"}
	SetVariable setvar_WaveBuilder_P10,userdata(tabnum)=  "6"
	SetVariable setvar_WaveBuilder_P10,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable setvar_WaveBuilder_P10,userdata(ResizeControlsInfo)= A"!!,Ip!!#=k!!#@,!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_WaveBuilder_P10,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_WaveBuilder_P10,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_WaveBuilder_P10,value= _NUM:0
	SetVariable setvar_WaveBuilder_P12,pos={552.00,56.00},size={100.00,18.00},disable=1,proc=WBP_SetVarProc_UpdateParam,title="Tau Decay 1"
	SetVariable setvar_WaveBuilder_P12,help={"PSC exponential decay time constant. One of Two."}
	SetVariable setvar_WaveBuilder_P12,userdata(tabnum)=  "6"
	SetVariable setvar_WaveBuilder_P12,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable setvar_WaveBuilder_P12,userdata(ResizeControlsInfo)= A"!!,Ip!!#>n!!#@,!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_WaveBuilder_P12,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_WaveBuilder_P12,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_WaveBuilder_P12,value= _NUM:0
	SetVariable setvar_WaveBuilder_P14,pos={552.00,80.00},size={100.00,18.00},disable=1,proc=WBP_SetVarProc_UpdateParam,title="Tau Decay 2"
	SetVariable setvar_WaveBuilder_P14,help={"PSC exponential decay time constant. Two of Two."}
	SetVariable setvar_WaveBuilder_P14,userdata(tabnum)=  "6"
	SetVariable setvar_WaveBuilder_P14,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable setvar_WaveBuilder_P14,userdata(ResizeControlsInfo)= A"!!,Ip!!#?Y!!#@,!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_WaveBuilder_P14,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_WaveBuilder_P14,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_WaveBuilder_P14,value= _NUM:0
	SetVariable setvar_WaveBuilder_P16,pos={552.00,103.00},size={100.00,18.00},disable=1,proc=WBP_SetVarProc_UpdateParam,title="Tau 2 weight"
	SetVariable setvar_WaveBuilder_P16,help={"PSC ratio of decay time constants"}
	SetVariable setvar_WaveBuilder_P16,userdata(tabnum)=  "6"
	SetVariable setvar_WaveBuilder_P16,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable setvar_WaveBuilder_P16,userdata(ResizeControlsInfo)= A"!!,Ip!!#@2!!#@,!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_WaveBuilder_P16,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_WaveBuilder_P16,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_WaveBuilder_P16,limits={0,1,0.1},value= _NUM:0
	SetVariable setvar_WaveBuilder_P17,pos={662.00,103.00},size={90.00,18.00},disable=1,proc=WBP_SetVarProc_UpdateParam,title="Delta"
	SetVariable setvar_WaveBuilder_P17,help={"PSC ratio of decay time constants sweep to sweep delta"}
	SetVariable setvar_WaveBuilder_P17,userdata(ResizeControlsInfo)= A"!!,J6J,hp]!!#?m!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_WaveBuilder_P17,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_WaveBuilder_P17,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_WaveBuilder_P17,userdata(tabnum)=  "6"
	SetVariable setvar_WaveBuilder_P17,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable setvar_WaveBuilder_P17,limits={-inf,inf,0.1},value= _NUM:0
	SetVariable setvar_WaveBuilder_P15,pos={662.00,80.00},size={90.00,18.00},disable=1,proc=WBP_SetVarProc_UpdateParam,title="Delta"
	SetVariable setvar_WaveBuilder_P15,help={"PSC exponential decay time constant sweep to sweep delta. Two of Two."}
	SetVariable setvar_WaveBuilder_P15,userdata(ResizeControlsInfo)= A"!!,J6J,hp/!!#?m!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_WaveBuilder_P15,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_WaveBuilder_P15,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_WaveBuilder_P15,userdata(tabnum)=  "6"
	SetVariable setvar_WaveBuilder_P15,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable setvar_WaveBuilder_P15,value= _NUM:0
	SetVariable setvar_WaveBuilder_P13,pos={662.00,57.00},size={90.00,18.00},disable=1,proc=WBP_SetVarProc_UpdateParam,title="Delta"
	SetVariable setvar_WaveBuilder_P13,help={"PSC exponential decay time constant sweep to sweep delta. One of Two."}
	SetVariable setvar_WaveBuilder_P13,userdata(ResizeControlsInfo)= A"!!,J6J,hoH!!#?m!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_WaveBuilder_P13,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_WaveBuilder_P13,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_WaveBuilder_P13,userdata(tabnum)=  "6"
	SetVariable setvar_WaveBuilder_P13,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable setvar_WaveBuilder_P13,value= _NUM:0
	SetVariable setvar_WaveBuilder_P11,pos={662.00,34.00},size={90.00,18.00},disable=1,proc=WBP_SetVarProc_UpdateParam,title="Delta"
	SetVariable setvar_WaveBuilder_P11,help={"PSC exponential rise time constant sweep to sweep delta"}
	SetVariable setvar_WaveBuilder_P11,userdata(ResizeControlsInfo)= A"!!,J6J,hnA!!#?m!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_WaveBuilder_P11,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_WaveBuilder_P11,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_WaveBuilder_P11,userdata(tabnum)=  "6"
	SetVariable setvar_WaveBuilder_P11,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable setvar_WaveBuilder_P11,limits={-inf,inf,0.1},value= _NUM:0
	SetVariable SetVar_WaveBuilder_P2,pos={194.00,57.00},size={100.00,18.00},proc=WBP_SetVarProc_UpdateParam,title="Amplitude"
	SetVariable SetVar_WaveBuilder_P2,help={"Amplitude of the epoch being edited. The unit depends on the DA channel configuration. For Noise epochs, amplitude = peak to peak."}
	SetVariable SetVar_WaveBuilder_P2,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P2,userdata(ResizeControlsInfo)= A"!!,GR!!#>r!!#@,!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P2,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P2,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P2,value= _NUM:0
	SetVariable SetVar_WaveBuilder_P3,pos={300.00,57.00},size={100.00,18.00},proc=WBP_SetVarProc_UpdateParam,title="Delta"
	SetVariable SetVar_WaveBuilder_P3,help={"Sweep to sweep amplitude delta."}
	SetVariable SetVar_WaveBuilder_P3,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P3,userdata(ResizeControlsInfo)= A"!!,HQ!!#>r!!#@,!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P3,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P3,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P3,value= _NUM:0
	SetVariable setvar_WaveBuilder_SetNumber,pos={882.00,33.00},size={116.00,18.00},proc=WBP_SetVarProc_SetNo,title="Set Number"
	SetVariable setvar_WaveBuilder_SetNumber,help={"A numeric suffix for the set name that can be used to sort sets with identical prefixes."}
	SetVariable setvar_WaveBuilder_SetNumber,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable setvar_WaveBuilder_SetNumber,userdata(ResizeControlsInfo)= A"!!,JmJ,hn=!!#@L!!#<Hz!!#o2B4uAezzzzzzzzzzzzzz!!#o2B4uAezz"
	SetVariable setvar_WaveBuilder_SetNumber,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_WaveBuilder_SetNumber,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_WaveBuilder_SetNumber,limits={0,inf,1},value= _NUM:0
	SetVariable SetVar_WaveBuilder_P4,pos={194.00,80.00},size={100.00,18.00},disable=1,proc=WBP_SetVarProc_UpdateParam,title="Offset"
	SetVariable SetVar_WaveBuilder_P4,help={"Epoch offset. Offset value is added to epoch."}
	SetVariable SetVar_WaveBuilder_P4,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P4,userdata(ResizeControlsInfo)= A"!!,GR!!#?Y!!#@,!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P4,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P4,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P4,userdata(tabnum)=  "1",value= _NUM:0
	SetVariable SetVar_WaveBuilder_P6,pos={194.00,104.00},size={100.00,18.00},disable=1,proc=WBP_SetVarProc_UpdateParam,title="Start Freq"
	SetVariable SetVar_WaveBuilder_P6,help={"Sin frequency or chirp start frequency"}
	SetVariable SetVar_WaveBuilder_P6,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P6,userdata(ResizeControlsInfo)= A"!!,GR!!#@4!!#@,!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P6,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P6,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P6,userdata(tabnum)=  "3",value= _NUM:0
	SetVariable setvar_WaveBuilder_CurrentEpoch,pos={37.00,129.00},size={122.00,22.00},proc=WBP_SetVarProc_EpochToEdit,title="Epoch to edit"
	SetVariable setvar_WaveBuilder_CurrentEpoch,help={"Epoch to edit. The active epoch is displayed on the graph with a white background. Inactive epochs have a gray background."}
	SetVariable setvar_WaveBuilder_CurrentEpoch,userdata(tabcontrol)=  "WBP_Set_Parameters"
	SetVariable setvar_WaveBuilder_CurrentEpoch,userdata(tabnum)=  "0"
	SetVariable setvar_WaveBuilder_CurrentEpoch,userdata(ResizeControlsInfo)= A"!!,D#!!#@e!!#@X!!#<hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_WaveBuilder_CurrentEpoch,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_WaveBuilder_CurrentEpoch,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_WaveBuilder_CurrentEpoch,fSize=14
	SetVariable setvar_WaveBuilder_CurrentEpoch,limits={0,0,1},value= _NUM:0
	SetVariable setvar_WaveBuilder_ITI,pos={87.00,153.00},size={71.00,18.00},proc=WBP_SetVarProc_ITI,title="ITI (s)"
	SetVariable setvar_WaveBuilder_ITI,help={"Inter-trial interval for the stimulus set e.g. time between sweeps. The ITI can be manually over ridden at run time."}
	SetVariable setvar_WaveBuilder_ITI,userdata(tabcontrol)=  "WBP_Set_Parameters"
	SetVariable setvar_WaveBuilder_ITI,userdata(tabnum)=  "0"
	SetVariable setvar_WaveBuilder_ITI,userdata(ResizeControlsInfo)= A"!!,Eh!!#A(!!#?G!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_WaveBuilder_ITI,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable setvar_WaveBuilder_ITI,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable setvar_WaveBuilder_ITI,limits={0,inf,0},value= _NUM:0
	SetVariable SetVar_WaveBuilder_P5,pos={300.00,80.00},size={100.00,18.00},disable=1,proc=WBP_SetVarProc_UpdateParam,title="Delta"
	SetVariable SetVar_WaveBuilder_P5,help={"Epoch sweep to sweep offset delta."}
	SetVariable SetVar_WaveBuilder_P5,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P5,userdata(ResizeControlsInfo)= A"!!,HQ!!#?Y!!#@,!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P5,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P5,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P5,userdata(tabnum)=  "1",value= _NUM:0
	SetVariable SetVar_WaveBuilder_P7,pos={300.00,104.00},size={100.00,18.00},disable=1,proc=WBP_SetVarProc_UpdateParam,title="Delta"
	SetVariable SetVar_WaveBuilder_P7,help={"Start frequency delta"}
	SetVariable SetVar_WaveBuilder_P7,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P7,userdata(ResizeControlsInfo)= A"!!,HQ!!#@4!!#@,!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P7,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P7,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P7,userdata(tabnum)=  "3",value= _NUM:0
	SetVariable SetVar_WaveBuilder_P8,pos={194.00,128.00},size={100.00,18.00},disable=1,proc=WBP_SetVarProc_UpdateParam,title="Pulse Dur"
	SetVariable SetVar_WaveBuilder_P8,help={"Duration of the square pulse. Max = pulse interval - 0.005 ms"}
	SetVariable SetVar_WaveBuilder_P8,userdata(tabnum)=  "5"
	SetVariable SetVar_WaveBuilder_P8,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P8,userdata(ResizeControlsInfo)= A"!!,GR!!#@d!!#@,!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P8,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P8,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P8,limits={0,inf,0.1},value= _NUM:0
	SetVariable SetVar_WaveBuilder_P9,pos={300.00,128.00},size={100.00,18.00},disable=1,proc=WBP_SetVarProc_UpdateParam,title="Delta"
	SetVariable SetVar_WaveBuilder_P9,help={"Square pulse duration delta"}
	SetVariable SetVar_WaveBuilder_P9,userdata(tabnum)=  "5"
	SetVariable SetVar_WaveBuilder_P9,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P9,userdata(ResizeControlsInfo)= A"!!,HQ!!#@d!!#@,!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P9,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P9,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P9,value= _NUM:0
	SetVariable setvar_WaveBuilder_baseName,pos={882.00,55.00},size={116.00,25.00},proc=WBP_SetVarProc_SetNo,title="Name\rprefix"
	SetVariable setvar_WaveBuilder_baseName,help={"Stimulus set name prefix. Max number of characters = 16"}
	SetVariable setvar_WaveBuilder_baseName,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable setvar_WaveBuilder_baseName,userdata(ResizeControlsInfo)= A"!!,JmJ,ho@!!#@L!!#=+z!!#o2B4uAezzzzzzzzzzzzzz!!#o2B4uAezz"
	SetVariable setvar_WaveBuilder_baseName,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_WaveBuilder_baseName,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_WaveBuilder_baseName,fSize=8
	SetVariable setvar_WaveBuilder_baseName,limits={0,10,1},value= _STR:"StimulusSetA"
	PopupMenu popup_WaveBuilder_SetList,pos={686.00,609.00},size={150.00,19.00},bodyWidth=150
	PopupMenu popup_WaveBuilder_SetList,help={"Select stimulus set to load or delete."}
	PopupMenu popup_WaveBuilder_SetList,userdata(tabcontrol)=  "WBP_WaveType"
	PopupMenu popup_WaveBuilder_SetList,userdata(ResizeControlsInfo)= A"!!,J<J,htS5QF.e!!#<Pz!!#o2B4uAezzzzzzzzzzzzzz!!#o2B4uAezz"
	PopupMenu popup_WaveBuilder_SetList,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#?(FEDG<zzzzzzzzzzz"
	PopupMenu popup_WaveBuilder_SetList,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	PopupMenu popup_WaveBuilder_SetList,mode=1,popvalue="- none -",value= #"\"- none -;\"+ WBP_ReturnListSavedSets(\"DA\") + WBP_ReturnListSavedSets(\"TTL\")"
	Button button_WaveBuilder_KillSet,pos={839.00,608.00},size={152.00,23.00},proc=WBP_ButtonProc_DeleteSet,title="Delete Set"
	Button button_WaveBuilder_KillSet,help={"Delete stimulus set selected in popup menu on the left."}
	Button button_WaveBuilder_KillSet,userdata(tabcontrol)=  "WBP_WaveType"
	Button button_WaveBuilder_KillSet,userdata(ResizeControlsInfo)= A"!!,Jb^]6b>!!#A'!!#<pz!!#o2B4uAezzzzzzzzzzzzzz!!#o2B4uAezz"
	Button button_WaveBuilder_KillSet,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#?(FEDG<zzzzzzzzzzz"
	Button button_WaveBuilder_KillSet,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	PopupMenu popup_WaveBuilder_exp_P40,pos={467.00,32.00},size={51.00,19.00},proc=WBP_PopupMenu
	PopupMenu popup_WaveBuilder_exp_P40,help={"Epoch delta type."}
	PopupMenu popup_WaveBuilder_exp_P40,userdata(tabcontrol)=  "WBP_WaveType"
	PopupMenu popup_WaveBuilder_exp_P40,userdata(ResizeControlsInfo)= A"!!,IOJ,hn9!!#>Z!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu popup_WaveBuilder_exp_P40,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu popup_WaveBuilder_exp_P40,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu popup_WaveBuilder_exp_P40,mode=1,popvalue="None",value= #"\"None;Multiplier;Log;Squared;Power;Alternate\""
	Button button_WaveBuilder_setaxisA,pos={19.00,608.00},size={152.00,23.00},proc=WBP_ButtonProc_AutoScale,title="Autoscale"
	Button button_WaveBuilder_setaxisA,help={"Returns the WaveBuilder graph to full scale. Ctrl-A does not work for panel graphs."}
	Button button_WaveBuilder_setaxisA,userdata(tabcontrol)=  "WBP_WaveType"
	Button button_WaveBuilder_setaxisA,userdata(ResizeControlsInfo)= A"!!,BQ!!#D(!!#A'!!#<pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_WaveBuilder_setaxisA,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#?(FEDG<zzzzzzzzzzz"
	Button button_WaveBuilder_setaxisA,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	PopupMenu popup_WaveBuilder_OutputType,pos={34.00,54.00},size={125.00,19.00},bodyWidth=55,proc=WBP_PopMenuProc_WaveType,title="Wave Type"
	PopupMenu popup_WaveBuilder_OutputType,help={"Stimulus set output type. TTL selection limits certain paramater values. This may result in changes to the active parameter values."}
	PopupMenu popup_WaveBuilder_OutputType,userdata(tabcontrol)=  "WBP_Set_Parameters"
	PopupMenu popup_WaveBuilder_OutputType,userdata(tabnum)=  "0"
	PopupMenu popup_WaveBuilder_OutputType,userdata(ResizeControlsInfo)= A"!!,Cl!!#>f!!#@^!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu popup_WaveBuilder_OutputType,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu popup_WaveBuilder_OutputType,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu popup_WaveBuilder_OutputType,fSize=14
	PopupMenu popup_WaveBuilder_OutputType,mode=1,popvalue="DA",value= #"\"DA;TTL\""
	Button button_WaveBuilder_SaveSet,pos={881.00,88.00},size={118.00,46.00},proc=WBP_ButtonProc_SaveSet,title="Save Set"
	Button button_WaveBuilder_SaveSet,help={"Saves the stimulus set and clears the WaveBuilder graph. On save the set is available for data acquisition."}
	Button button_WaveBuilder_SaveSet,userdata(ResizeControlsInfo)= A"!!,Jm5QF-T!!#@P!!#>Fz!!#o2B4uAezzzzzzzzzzzzzz!!#o2B4uAezz"
	Button button_WaveBuilder_SaveSet,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	Button button_WaveBuilder_SaveSet,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P6_FD00,pos={194.00,104.00},size={100.00,18.00},disable=1,proc=WBP_SetVarProc_UpdateParam,title="Freq"
	SetVariable SetVar_WaveBuilder_P6_FD00,help={"Saw tooth frequency"}
	SetVariable SetVar_WaveBuilder_P6_FD00,userdata(tabnum)=  "4"
	SetVariable SetVar_WaveBuilder_P6_FD00,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P6_FD00,userdata(ResizeControlsInfo)= A"!!,GR!!#@4!!#@,!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P6_FD00,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P6_FD00,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P6_FD00,value= _NUM:0
	SetVariable SetVar_WaveBuilder_P7_DD00,pos={300.00,104.00},size={100.00,18.00},disable=1,proc=WBP_SetVarProc_UpdateParam,title="Delta"
	SetVariable SetVar_WaveBuilder_P7_DD00,help={"Saw tooth frequency delta"}
	SetVariable SetVar_WaveBuilder_P7_DD00,userdata(tabnum)=  "4"
	SetVariable SetVar_WaveBuilder_P7_DD00,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P7_DD00,userdata(ResizeControlsInfo)= A"!!,HQ!!#@4!!#@,!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P7_DD00,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P7_DD00,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P7_DD00,value= _NUM:0
	SetVariable SetVar_WaveBuilder_P6_FD01,pos={194.00,104.00},size={100.00,18.00},disable=1,proc=WBP_SetVarProc_UpdateParam,title="Freq"
	SetVariable SetVar_WaveBuilder_P6_FD01,userdata(tabnum)=  "5"
	SetVariable SetVar_WaveBuilder_P6_FD01,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P6_FD01,userdata(ResizeControlsInfo)= A"!!,GR!!#@4!!#@,!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P6_FD01,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P6_FD01,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P6_FD01,value= _NUM:0
	SetVariable SetVar_WaveBuilder_P7_DD01,pos={300.00,104.00},size={100.00,18.00},disable=1,proc=WBP_SetVarProc_UpdateParam,title="Delta"
	SetVariable SetVar_WaveBuilder_P7_DD01,userdata(tabnum)=  "5"
	SetVariable SetVar_WaveBuilder_P7_DD01,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P7_DD01,userdata(ResizeControlsInfo)= A"!!,HQ!!#@4!!#@,!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P7_DD01,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P7_DD01,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P7_DD01,value= _NUM:0
	SetVariable SetVar_WaveBuilder_P4_OD00,pos={194.00,80.00},size={100.00,18.00},disable=1,proc=WBP_SetVarProc_UpdateParam,title="Offset"
	SetVariable SetVar_WaveBuilder_P4_OD00,help={"Noise offset."}
	SetVariable SetVar_WaveBuilder_P4_OD00,userdata(tabnum)=  "2"
	SetVariable SetVar_WaveBuilder_P4_OD00,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P4_OD00,userdata(ResizeControlsInfo)= A"!!,GR!!#?Y!!#@,!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P4_OD00,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P4_OD00,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P4_OD00,value= _NUM:0
	SetVariable SetVar_WaveBuilder_P5_DD02,pos={300.00,80.00},size={100.00,18.00},disable=1,proc=WBP_SetVarProc_UpdateParam,title="Delta"
	SetVariable SetVar_WaveBuilder_P5_DD02,help={"Noise offset delta."}
	SetVariable SetVar_WaveBuilder_P5_DD02,userdata(tabnum)=  "2"
	SetVariable SetVar_WaveBuilder_P5_DD02,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P5_DD02,userdata(ResizeControlsInfo)= A"!!,HQ!!#?Y!!#@,!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P5_DD02,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P5_DD02,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P5_DD02,value= _NUM:0
	SetVariable SetVar_WaveBuilder_P5_DD03,pos={300.00,80.00},size={100.00,18.00},disable=1,proc=WBP_SetVarProc_UpdateParam,title="Delta"
	SetVariable SetVar_WaveBuilder_P5_DD03,userdata(tabnum)=  "3"
	SetVariable SetVar_WaveBuilder_P5_DD03,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P5_DD03,userdata(ResizeControlsInfo)= A"!!,HQ!!#?Y!!#@,!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P5_DD03,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P5_DD03,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P5_DD03,value= _NUM:0
	SetVariable SetVar_WaveBuilder_P4_OD01,pos={194.00,80.00},size={100.00,18.00},disable=1,proc=WBP_SetVarProc_UpdateParam,title="Offset"
	SetVariable SetVar_WaveBuilder_P4_OD01,userdata(tabnum)=  "3"
	SetVariable SetVar_WaveBuilder_P4_OD01,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P4_OD01,userdata(ResizeControlsInfo)= A"!!,GR!!#?Y!!#@,!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P4_OD01,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P4_OD01,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P4_OD01,value= _NUM:0
	SetVariable SetVar_WaveBuilder_P5_DD04,pos={300.00,80.00},size={100.00,18.00},disable=1,proc=WBP_SetVarProc_UpdateParam,title="Delta"
	SetVariable SetVar_WaveBuilder_P5_DD04,userdata(tabnum)=  "4"
	SetVariable SetVar_WaveBuilder_P5_DD04,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P5_DD04,userdata(ResizeControlsInfo)= A"!!,HQ!!#?Y!!#@,!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P5_DD04,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P5_DD04,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P5_DD04,value= _NUM:0
	SetVariable SetVar_WaveBuilder_P4_OD02,pos={194.00,80.00},size={100.00,18.00},disable=1,proc=WBP_SetVarProc_UpdateParam,title="Offset"
	SetVariable SetVar_WaveBuilder_P4_OD02,userdata(tabnum)=  "4"
	SetVariable SetVar_WaveBuilder_P4_OD02,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P4_OD02,userdata(ResizeControlsInfo)= A"!!,GR!!#?Y!!#@,!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P4_OD02,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P4_OD02,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P4_OD02,value= _NUM:0
	SetVariable SetVar_WaveBuilder_P5_DD05,pos={300.00,80.00},size={100.00,18.00},disable=1,proc=WBP_SetVarProc_UpdateParam,title="Delta"
	SetVariable SetVar_WaveBuilder_P5_DD05,userdata(tabnum)=  "5"
	SetVariable SetVar_WaveBuilder_P5_DD05,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P5_DD05,userdata(ResizeControlsInfo)= A"!!,HQ!!#?Y!!#@,!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P5_DD05,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P5_DD05,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P5_DD05,value= _NUM:0
	SetVariable SetVar_WaveBuilder_P4_OD03,pos={194.00,80.00},size={100.00,18.00},disable=1,proc=WBP_SetVarProc_UpdateParam,title="Offset"
	SetVariable SetVar_WaveBuilder_P4_OD03,userdata(tabnum)=  "5"
	SetVariable SetVar_WaveBuilder_P4_OD03,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P4_OD03,userdata(ResizeControlsInfo)= A"!!,GR!!#?Y!!#@,!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P4_OD03,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P4_OD03,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P4_OD03,value= _NUM:0
	SetVariable SetVar_WaveBuilder_P5_DD06,pos={300.00,80.00},size={100.00,18.00},disable=1,proc=WBP_SetVarProc_UpdateParam,title="Delta"
	SetVariable SetVar_WaveBuilder_P5_DD06,help={"PSC epoch sweep to sweep offset delta"}
	SetVariable SetVar_WaveBuilder_P5_DD06,userdata(tabnum)=  "6"
	SetVariable SetVar_WaveBuilder_P5_DD06,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P5_DD06,userdata(ResizeControlsInfo)= A"!!,HQ!!#?Y!!#@,!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P5_DD06,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P5_DD06,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P5_DD06,value= _NUM:0
	SetVariable SetVar_WaveBuilder_P4_OD04,pos={194.00,80.00},size={100.00,18.00},disable=1,proc=WBP_SetVarProc_UpdateParam,title="Offset"
	SetVariable SetVar_WaveBuilder_P4_OD04,help={"Offset of post synaptic current (PSC) epoch "}
	SetVariable SetVar_WaveBuilder_P4_OD04,userdata(tabnum)=  "6"
	SetVariable SetVar_WaveBuilder_P4_OD04,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P4_OD04,userdata(ResizeControlsInfo)= A"!!,GR!!#?Y!!#@,!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P4_OD04,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P4_OD04,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P4_OD04,value= _NUM:0
	SetVariable SetVar_WaveBuilder_P4_OD05,pos={194.00,33.00},size={100.00,18.00},disable=1,proc=WBP_SetVarProc_UpdateParam,title="Offset"
	SetVariable SetVar_WaveBuilder_P4_OD05,userdata(tabnum)=  "7"
	SetVariable SetVar_WaveBuilder_P4_OD05,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P4_OD05,value= _NUM:0
	SetVariable SetVar_WaveBuilder_P4_OD05,userdata(ResizeControlsInfo)= A"!!,GR!!#=g!!#@,!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P4_OD05,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P4_OD05,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P5_DD07,pos={300.00,33.00},size={100.00,18.00},disable=1,proc=WBP_SetVarProc_UpdateParam,title="Delta"
	SetVariable SetVar_WaveBuilder_P5_DD07,userdata(tabnum)=  "7"
	SetVariable SetVar_WaveBuilder_P5_DD07,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P5_DD07,value= _NUM:0
	SetVariable SetVar_WaveBuilder_P5_DD07,userdata(ResizeControlsInfo)= A"!!,HQ!!#=g!!#@,!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P5_DD07,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P5_DD07,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_WaveBuilder_SearchString,pos={574.00,118.00},size={212.00,33.00},disable=1,proc=WBP_SetVarProc_SetSearchString,title="Search\rstring"
	SetVariable setvar_WaveBuilder_SearchString,help={"Refines list of waves based on search string. Include asterisk \"wildcard\" where appropriate."}
	SetVariable setvar_WaveBuilder_SearchString,userdata(tabnum)=  "7"
	SetVariable setvar_WaveBuilder_SearchString,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable setvar_WaveBuilder_SearchString,userdata(ResizeControlsInfo)= A"!!,IuJ,hq&!!#Ac!!#=gz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_WaveBuilder_SearchString,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_WaveBuilder_SearchString,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_WaveBuilder_SearchString,value= _STR:""
	PopupMenu popup_WaveBuilder_ListOfWaves,pos={572.00,88.00},size={215.00,30.00},bodyWidth=175,disable=1,proc=WBP_PopMenuProc_WaveToLoad,title="Wave\rto load"
	PopupMenu popup_WaveBuilder_ListOfWaves,help={"Select custom epoch wave. Popup menu displays waves contained in selected folder. Waves must have 5 micro second sampling interval."}
	PopupMenu popup_WaveBuilder_ListOfWaves,userdata(tabnum)=  "7"
	PopupMenu popup_WaveBuilder_ListOfWaves,userdata(tabcontrol)=  "WBP_WaveType"
	PopupMenu popup_WaveBuilder_ListOfWaves,userdata(ResizeControlsInfo)= A"!!,Iu!!#?i!!#Af!!#=Sz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu popup_WaveBuilder_ListOfWaves,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu popup_WaveBuilder_ListOfWaves,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu popup_WaveBuilder_ListOfWaves,mode=1,popvalue="- none -",value= #"WBP_GetListOfWaves()"
	SetVariable SetVar_WaveBuilder_P20,pos={601.00,39.00},size={135.00,33.00},bodyWidth=60,disable=1,proc=WBP_SetVarProc_UpdateParam,title="Low pass cut \roff frequency"
	SetVariable SetVar_WaveBuilder_P20,help={"Set to zero turn off low pass filter"}
	SetVariable SetVar_WaveBuilder_P20,userdata(tabnum)=  "2"
	SetVariable SetVar_WaveBuilder_P20,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P20,userdata(ResizeControlsInfo)= A"!!,J'5QF+j!!#@k!!#=gz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P20,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P20,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P20,limits={0,100001,100},value= _NUM:0
	SetVariable SetVar_WaveBuilder_P21,pos={741.00,48.00},size={91.00,18.00},disable=1,proc=WBP_SetVarProc_UpdateParam,title="Delta"
	SetVariable SetVar_WaveBuilder_P21,help={"Low pass filter cut off frequency delta."}
	SetVariable SetVar_WaveBuilder_P21,userdata(tabnum)=  "2"
	SetVariable SetVar_WaveBuilder_P21,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P21,userdata(ResizeControlsInfo)= A"!!,JJ5QF,9!!#?o!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P21,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P21,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P21,limits={-inf,100000,1},value= _NUM:0
	SetVariable SetVar_WaveBuilder_P22,pos={597.00,78.00},size={139.00,33.00},bodyWidth=60,disable=1,proc=WBP_SetVarProc_UpdateParam,title="High pass cut \roff frequency"
	SetVariable SetVar_WaveBuilder_P22,help={"Set to zero to turn off high pass filter"}
	SetVariable SetVar_WaveBuilder_P22,userdata(tabnum)=  "2"
	SetVariable SetVar_WaveBuilder_P22,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P22,userdata(ResizeControlsInfo)= A"!!,J&5QF-@!!#@o!!#=gz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P22,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P22,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P22,limits={0,100001,100},value= _NUM:0
	SetVariable SetVar_WaveBuilder_P23,pos={741.00,85.00},size={91.00,18.00},disable=1,proc=WBP_SetVarProc_UpdateParam,title="Delta"
	SetVariable SetVar_WaveBuilder_P23,help={"High pass filter cut off frequency delta."}
	SetVariable SetVar_WaveBuilder_P23,userdata(tabnum)=  "2"
	SetVariable SetVar_WaveBuilder_P23,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P23,userdata(ResizeControlsInfo)= A"!!,JJ5QF-N!!#?o!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P23,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P23,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P23,limits={-inf,99749,1},value= _NUM:0
	CheckBox check_SPT_Poisson_P44,pos={494.00,99.00},size={76.00,30.00},disable=1,proc=WBP_CheckProc,title="Poisson\rdistribution"
	CheckBox check_SPT_Poisson_P44,help={"Poisson distribution of square pulses at the average frequency specified by the user."}
	CheckBox check_SPT_Poisson_P44,userdata(ResizeControlsInfo)= A"!!,I]!!#@*!!#?Q!!#=Sz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_SPT_Poisson_P44,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_SPT_Poisson_P44,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_SPT_Poisson_P44,userdata(tabnum)=  "5"
	CheckBox check_SPT_Poisson_P44,userdata(tabcontrol)=  "WBP_WaveType",value= 0
	SetVariable SetVar_WaveBuilder_P24,pos={194.00,128.00},size={100.00,18.00},disable=3,proc=WBP_SetVarProc_UpdateParam,title="End Freq"
	SetVariable SetVar_WaveBuilder_P24,help={"Chirp end frequency"}
	SetVariable SetVar_WaveBuilder_P24,userdata(ResizeControlsInfo)= A"!!,GR!!#@d!!#@,!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P24,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P24,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P24,userdata(tabnum)=  "3"
	SetVariable SetVar_WaveBuilder_P24,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P24,limits={0,inf,0.1},value= _NUM:0
	SetVariable SetVar_WaveBuilder_P25,pos={300.00,128.00},size={100.00,18.00},disable=3,proc=WBP_SetVarProc_UpdateParam,title="Delta"
	SetVariable SetVar_WaveBuilder_P25,help={"Chirp end frequency delta"}
	SetVariable SetVar_WaveBuilder_P25,userdata(ResizeControlsInfo)= A"!!,HQ!!#@d!!#@,!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P25,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P25,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P25,userdata(tabnum)=  "3"
	SetVariable SetVar_WaveBuilder_P25,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P25,value= _NUM:0
	CheckBox check_Sin_Chirp_P43,pos={415.00,106.00},size={62.00,15.00},disable=1,proc=WBP_CheckProc,title="log chirp"
	CheckBox check_Sin_Chirp_P43,help={"A chirp is a signal in which the frequency increases or decreases with time."}
	CheckBox check_Sin_Chirp_P43,userdata(tabnum)=  "3"
	CheckBox check_Sin_Chirp_P43,userdata(tabcontrol)=  "WBP_WaveType"
	CheckBox check_Sin_Chirp_P43,userdata(ResizeControlsInfo)= A"!!,I5J,hpc!!#?1!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_Sin_Chirp_P43,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_Sin_Chirp_P43,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_Sin_Chirp_P43,value= 0
	Button button_WaveBuilder_LoadSet,pos={530.00,608.00},size={152.00,23.00},proc=WBP_ButtonProc_LoadSet,title="Load Set"
	Button button_WaveBuilder_LoadSet,help={"Load set selected in popup menu on the right."}
	Button button_WaveBuilder_LoadSet,userdata(tabcontrol)=  "WBP_WaveType"
	Button button_WaveBuilder_LoadSet,userdata(ResizeControlsInfo)= A"!!,IjJ,htS!!#A'!!#<pz!!#o2B4uAezzzzzzzzzzzzzz!!#o2B4uAezz"
	Button button_WaveBuilder_LoadSet,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#?(FEDG<zzzzzzzzzzz"
	Button button_WaveBuilder_LoadSet,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WB_DurDeltaMult_P52,pos={405.00,34.00},size={55.00,18.00},disable=2,proc=WBP_SetVarProc_UpdateParam,title="* "
	SetVariable SetVar_WB_DurDeltaMult_P52,help={"Epoch duration delta multiplier or exponent."}
	SetVariable SetVar_WB_DurDeltaMult_P52,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WB_DurDeltaMult_P52,userdata(ResizeControlsInfo)= A"!!,I0J,hnA!!#>j!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WB_DurDeltaMult_P52,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable SetVar_WB_DurDeltaMult_P52,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WB_DurDeltaMult_P52,value= _NUM:0
	PopupMenu popup_WaveBuilder_FolderList,pos={578.00,60.00},size={209.00,30.00},bodyWidth=175,disable=1,proc=WBP_PopMenuProc_FolderSelect,title="Select\rfolder"
	PopupMenu popup_WaveBuilder_FolderList,help={"Select folder that contains custom epoch wave. After each selection, contents of selected folder are listed in popup menu."}
	PopupMenu popup_WaveBuilder_FolderList,userdata(tabnum)=  "7"
	PopupMenu popup_WaveBuilder_FolderList,userdata(tabcontrol)=  "WBP_WaveType"
	PopupMenu popup_WaveBuilder_FolderList,userdata(ResizeControlsInfo)= A"!!,J!J,hoT!!#A`!!#=Sz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu popup_WaveBuilder_FolderList,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	PopupMenu popup_WaveBuilder_FolderList,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	PopupMenu popup_WaveBuilder_FolderList,mode=1,popvalue="- none -",value= #"WBP_ReturnFoldersList()"
	GroupBox group_WaveBuilder_FolderPath,pos={548.00,34.00},size={269.00,127.00},disable=1,title="root:"
	GroupBox group_WaveBuilder_FolderPath,help={"Displays user defined path to custom epoch wave"}
	GroupBox group_WaveBuilder_FolderPath,userdata(tabnum)=  "7"
	GroupBox group_WaveBuilder_FolderPath,userdata(tabcontrol)=  "WBP_WaveType"
	GroupBox group_WaveBuilder_FolderPath,userdata(ResizeControlsInfo)= A"!!,Io!!#=k!!#B@J,hq8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	GroupBox group_WaveBuilder_FolderPath,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	GroupBox group_WaveBuilder_FolderPath,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	GroupBox group_WaveBuilder_SaveSet,pos={876.00,6.00},size={127.00,134.00},title="\\Z16\\f01Save Set"
	GroupBox group_WaveBuilder_SaveSet,userdata(tabcontrol)=  "WBP_WaveType"
	GroupBox group_WaveBuilder_SaveSet,userdata(ResizeControlsInfo)= A"!!,Jl!!#:\"!!#@b!!#@jz!!#o2B4uAezzzzzzzzzzzzzz!!#o2B4uAezz"
	GroupBox group_WaveBuilder_SaveSet,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	GroupBox group_WaveBuilder_SaveSet,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	GroupBox group_WaveBuilder_SaveSet,fStyle=0
	PopupMenu popup_noise_type_P54,pos={228.00,113.00},size={89.00,19.00},bodyWidth=60,disable=1,proc=WBP_PopupMenu,title="Type"
	PopupMenu popup_noise_type_P54,help={"White Noise: Constant power density, Pink Noise: 1/f power density drop (10dB per decade), Brown Noise: 1/f^2 power density drop (20db per decade)"}
	PopupMenu popup_noise_type_P54,userdata(tabnum)=  "2"
	PopupMenu popup_noise_type_P54,userdata(tabcontrol)=  "WBP_WaveType"
	PopupMenu popup_noise_type_P54,userdata(ResizeControlsInfo)= A"!!,Gt!!#@F!!#?k!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu popup_noise_type_P54,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	PopupMenu popup_noise_type_P54,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	PopupMenu popup_noise_type_P54,mode=1,popvalue="White",value= #"WBP_GetNoiseTypes()"
	CheckBox check_PreventUpdate,pos={189.00,613.00},size={95.00,15.00},proc=WBP_CheckProc_PreventUpdate,title="Prevent update"
	CheckBox check_PreventUpdate,help={"Stops graph updating when checked. Useful when updating multiple parameters in \"big\" stimulus sets."}
	CheckBox check_PreventUpdate,userdata(tabcontrol)=  "WBP_WaveType"
	CheckBox check_PreventUpdate,userdata(ResizeControlsInfo)= A"!!,GM!!#D)5QF-b!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_PreventUpdate,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#?(FEDG<zzzzzzzzzzz"
	CheckBox check_PreventUpdate,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	CheckBox check_PreventUpdate,value= 0
	SetVariable SetVar_WB_AmpDeltaMult_P50,pos={405.00,57.00},size={55.00,18.00},disable=2,proc=WBP_SetVarProc_UpdateParam,title="* "
	SetVariable SetVar_WB_AmpDeltaMult_P50,help={"Epoch amplitude delta multiplier or exponent."}
	SetVariable SetVar_WB_AmpDeltaMult_P50,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WB_AmpDeltaMult_P50,userdata(ResizeControlsInfo)= A"!!,I0J,hoH!!#>j!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WB_AmpDeltaMult_P50,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable SetVar_WB_AmpDeltaMult_P50,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WB_AmpDeltaMult_P50,value= _NUM:0
	SetVariable SetVar_WB_OffsetDeltaMult_P51,pos={405.00,80.00},size={55.00,18.00},disable=3,proc=WBP_SetVarProc_UpdateParam,title="* "
	SetVariable SetVar_WB_OffsetDeltaMult_P51,help={"Specify the epoch offset delta multiplier or exponent."}
	SetVariable SetVar_WB_OffsetDeltaMult_P51,userdata(tabnum)=  "1"
	SetVariable SetVar_WB_OffsetDeltaMult_P51,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WB_OffsetDeltaMult_P51,userdata(ResizeControlsInfo)= A"!!,I0J,hp/!!#>j!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WB_OffsetDeltaMult_P51,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable SetVar_WB_OffsetDeltaMult_P51,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WB_OffsetDeltaMult_P51,value= _NUM:0
	SetVariable SetVar_WB_OffsetDeltaMult_P51_0,pos={405.00,80.00},size={55.00,18.00},disable=3,proc=WBP_SetVarProc_UpdateParam,title="* "
	SetVariable SetVar_WB_OffsetDeltaMult_P51_0,userdata(tabnum)=  "2"
	SetVariable SetVar_WB_OffsetDeltaMult_P51_0,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WB_OffsetDeltaMult_P51_0,userdata(ResizeControlsInfo)= A"!!,I0J,hp/!!#>j!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WB_OffsetDeltaMult_P51_0,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable SetVar_WB_OffsetDeltaMult_P51_0,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WB_OffsetDeltaMult_P51_0,value= _NUM:0
	SetVariable SetVar_WB_OffsetDeltaMult_P51_1,pos={405.00,80.00},size={55.00,18.00},disable=3,proc=WBP_SetVarProc_UpdateParam,title="* "
	SetVariable SetVar_WB_OffsetDeltaMult_P51_1,userdata(tabnum)=  "3"
	SetVariable SetVar_WB_OffsetDeltaMult_P51_1,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WB_OffsetDeltaMult_P51_1,userdata(ResizeControlsInfo)= A"!!,I0J,hp/!!#>j!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WB_OffsetDeltaMult_P51_1,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable SetVar_WB_OffsetDeltaMult_P51_1,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WB_OffsetDeltaMult_P51_1,value= _NUM:0
	SetVariable SetVar_WB_OffsetDeltaMult_P51_2,pos={405.00,80.00},size={55.00,18.00},disable=3,proc=WBP_SetVarProc_UpdateParam,title="* "
	SetVariable SetVar_WB_OffsetDeltaMult_P51_2,userdata(tabnum)=  "4"
	SetVariable SetVar_WB_OffsetDeltaMult_P51_2,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WB_OffsetDeltaMult_P51_2,userdata(ResizeControlsInfo)= A"!!,I0J,hp/!!#>j!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WB_OffsetDeltaMult_P51_2,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable SetVar_WB_OffsetDeltaMult_P51_2,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WB_OffsetDeltaMult_P51_2,value= _NUM:0
	SetVariable SetVar_WB_OffsetDeltaMult_P51_3,pos={405.00,80.00},size={55.00,18.00},disable=3,proc=WBP_SetVarProc_UpdateParam,title="* "
	SetVariable SetVar_WB_OffsetDeltaMult_P51_3,userdata(tabnum)=  "5"
	SetVariable SetVar_WB_OffsetDeltaMult_P51_3,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WB_OffsetDeltaMult_P51_3,userdata(ResizeControlsInfo)= A"!!,I0J,hp/!!#>j!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WB_OffsetDeltaMult_P51_3,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable SetVar_WB_OffsetDeltaMult_P51_3,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WB_OffsetDeltaMult_P51_3,value= _NUM:0
	SetVariable SetVar_WB_OffsetDeltaMult_P51_4,pos={405.00,80.00},size={55.00,18.00},disable=3,proc=WBP_SetVarProc_UpdateParam,title="* "
	SetVariable SetVar_WB_OffsetDeltaMult_P51_4,userdata(tabnum)=  "6"
	SetVariable SetVar_WB_OffsetDeltaMult_P51_4,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WB_OffsetDeltaMult_P51_4,userdata(ResizeControlsInfo)= A"!!,I0J,hp/!!#>j!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WB_OffsetDeltaMult_P51_4,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable SetVar_WB_OffsetDeltaMult_P51_4,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WB_OffsetDeltaMult_P51_4,value= _NUM:0
	SetVariable SetVar_WB_OffsetDeltaMult_P51_5,pos={406.00,33.00},size={55.00,18.00},disable=3,proc=WBP_SetVarProc_UpdateParam,title="*"
	SetVariable SetVar_WB_OffsetDeltaMult_P51_5,userdata(tabnum)=  "7"
	SetVariable SetVar_WB_OffsetDeltaMult_P51_5,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WB_OffsetDeltaMult_P51_5,value= _NUM:0
	SetVariable SetVar_WB_OffsetDeltaMult_P51_5,userdata(ResizeControlsInfo)= A"!!,I1!!#=g!!#>j!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WB_OffsetDeltaMult_P51_5,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable SetVar_WB_OffsetDeltaMult_P51_5,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P45,pos={194.00,151.00},size={100.00,18.00},disable=3,proc=WBP_SetVarProc_UpdateParam,title="Num Pulses"
	SetVariable SetVar_WaveBuilder_P45,help={"Number of pulses in epoch at specified frequency"}
	SetVariable SetVar_WaveBuilder_P45,userdata(tabnum)=  "5"
	SetVariable SetVar_WaveBuilder_P45,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P45,userdata(ResizeControlsInfo)= A"!!,GR!!#A&!!#@,!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P45,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P45,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P45,limits={0,inf,1},value= _NUM:0
	SetVariable SetVar_WaveBuilder_P47,pos={300.00,151.00},size={100.00,18.00},disable=3,proc=WBP_SetVarProc_UpdateParam,title="Delta"
	SetVariable SetVar_WaveBuilder_P47,help={"Epoch pulse number delta"}
	SetVariable SetVar_WaveBuilder_P47,userdata(tabnum)=  "5"
	SetVariable SetVar_WaveBuilder_P47,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P47,userdata(ResizeControlsInfo)= A"!!,HQ!!#A&!!#@,!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P47,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P47,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P47,value= _NUM:0
	CheckBox check_SPT_NumPulses_P46,pos={418.00,133.00},size={70.00,15.00},disable=1,proc=WBP_CheckProc,title="Use Pulses"
	CheckBox check_SPT_NumPulses_P46,help={"Checked: epoch duration is determined by the user specified pulse number and frequency. Unchecked: epoch duration is set by the user."}
	CheckBox check_SPT_NumPulses_P46,userdata(tabnum)=  "5"
	CheckBox check_SPT_NumPulses_P46,userdata(tabcontrol)=  "WBP_WaveType"
	CheckBox check_SPT_NumPulses_P46,userdata(ResizeControlsInfo)= A"!!,I7!!#@i!!#?E!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_SPT_NumPulses_P46,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_SPT_NumPulses_P46,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_SPT_NumPulses_P46,value= 0
	Button button_NewSeed_P48,pos={322.00,112.00},size={72.00,20.00},disable=1,proc=WBP_ButtonProc_NewSeed,title="New Noise"
	Button button_NewSeed_P48,help={"Create new noise waveforms"}
	Button button_NewSeed_P48,userdata(tabnum)=  "2"
	Button button_NewSeed_P48,userdata(tabcontrol)=  "WBP_WaveType"
	Button button_NewSeed_P48,userdata(ResizeControlsInfo)= A"!!,H\\!!#@D!!#?I!!#<Xz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_NewSeed_P48,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	Button button_NewSeed_P48,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox check_NewSeedForEachSweep_P49,pos={324.00,139.00},size={85.00,15.00},disable=1,proc=WBP_CheckProc,title="Seed / Sweep"
	CheckBox check_NewSeedForEachSweep_P49,help={"When checked, the random number generator (RNG) seed is updated with each sweep. Seeds are saved with the stimulus."}
	CheckBox check_NewSeedForEachSweep_P49,userdata(tabnum)=  "2"
	CheckBox check_NewSeedForEachSweep_P49,userdata(tabcontrol)=  "WBP_WaveType"
	CheckBox check_NewSeedForEachSweep_P49,userdata(ResizeControlsInfo)= A"!!,H]!!#@o!!#?c!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_NewSeedForEachSweep_P49,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_NewSeedForEachSweep_P49,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox check_NewSeedForEachSweep_P49,value= 0
	ListBox listbox_combineEpochMap,pos={194.00,25.00},size={228.00,178.00},disable=1
	ListBox listbox_combineEpochMap,help={"Shorthand <-> Stimset mapping for use with the formula"}
	ListBox listbox_combineEpochMap,userdata(tabnum)=  "8"
	ListBox listbox_combineEpochMap,userdata(tabcontrol)=  "WBP_WaveType"
	ListBox listbox_combineEpochMap,userdata(ResizeControlsInfo)= A"!!,GR!!#=+!!#As!!#AAz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	ListBox listbox_combineEpochMap,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	ListBox listbox_combineEpochMap,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	ListBox listbox_combineEpochMap,widths={58,120}
	SetVariable setvar_combine_formula_T6,pos={428.00,180.00},size={437.00,18.00},disable=1,proc=WBP_SetVarCombineEpochFormula,title="Formula"
	SetVariable setvar_combine_formula_T6,help={"Mathematical formula for combining stim sets. All math operators from Igor are supported. Examples: +/-*^,sin,cos,tan. All are applied elementwise on the stim set contents. Mutiple sweeps are flattened into one sweep."}
	SetVariable setvar_combine_formula_T6,userdata(tabnum)=  "8"
	SetVariable setvar_combine_formula_T6,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable setvar_combine_formula_T6,userdata(ResizeControlsInfo)= A"!!,I<!!#AC!!#C?J,hlsz!!#](Aon\"Qzzzzzzzzzzzzzz!!#o2B4uAezz"
	SetVariable setvar_combine_formula_T6,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable setvar_combine_formula_T6,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetVariable setvar_combine_formula_T6,limits={-inf,inf,0},value= _STR:""
	CheckBox check_FlipEpoch_S98,pos={121.00,174.00},size={34.00,15.00},proc=WBP_CheckProc_FlipStimSet,title="Flip"
	CheckBox check_FlipEpoch_S98,help={"Flip the whole stim set in the time domain"}
	CheckBox check_FlipEpoch_S98,userdata(tabcontrol)=  "WBP_Set_Parameters"
	CheckBox check_FlipEpoch_S98,userdata(tabnum)=  "0"
	CheckBox check_FlipEpoch_S98,userdata(ResizeControlsInfo)= A"!!,FW!!#A=!!#=k!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_FlipEpoch_S98,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_FlipEpoch_S98,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox check_FlipEpoch_S98,value= 0
	PopupMenu popup_af_postSweep_S3,pos={7.00,102.00},size={170.00,21.00},bodyWidth=110,disable=1,proc=WBP_PopupMenu_AnalysisFunctions,title="Post Sweep"
	PopupMenu popup_af_postSweep_S3,help={"After each sweep"},userdata(tabnum)=  "1"
	PopupMenu popup_af_postSweep_S3,userdata(tabcontrol)=  "WBP_Set_Parameters"
	PopupMenu popup_af_postSweep_S3,userdata(ResizeControlsInfo)= A"!!,@C!!#@0!!#A9!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu popup_af_postSweep_S3,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	PopupMenu popup_af_postSweep_S3,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	PopupMenu popup_af_postSweep_S3,mode=1,popvalue="- none -",value= #"WBP_GetAnalysisFunctions()"
	PopupMenu popup_af_postSet_S4,pos={24.00,128.00},size={153.00,21.00},bodyWidth=110,disable=1,proc=WBP_PopupMenu_AnalysisFunctions,title="Post Set"
	PopupMenu popup_af_postSet_S4,help={"After a *full* set has been acquired (This event is not always reached as the user might not acquire all sweeps of a set)"}
	PopupMenu popup_af_postSet_S4,userdata(tabnum)=  "1"
	PopupMenu popup_af_postSet_S4,userdata(tabcontrol)=  "WBP_Set_Parameters"
	PopupMenu popup_af_postSet_S4,userdata(ResizeControlsInfo)= A"!!,C$!!#@d!!#A(!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu popup_af_postSet_S4,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	PopupMenu popup_af_postSet_S4,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	PopupMenu popup_af_postSet_S4,mode=1,popvalue="- none -",value= #"WBP_GetAnalysisFunctions()"
	PopupMenu popup_af_preDAQEvent_S1,pos={22.00,50.00},size={155.00,21.00},bodyWidth=110,disable=1,proc=WBP_PopupMenu_AnalysisFunctions,title="Pre DAQ"
	PopupMenu popup_af_preDAQEvent_S1,help={"Immediately before any DAQ occurs"}
	PopupMenu popup_af_preDAQEvent_S1,userdata(tabnum)=  "1"
	PopupMenu popup_af_preDAQEvent_S1,userdata(tabcontrol)=  "WBP_Set_Parameters"
	PopupMenu popup_af_preDAQEvent_S1,userdata(ResizeControlsInfo)= A"!!,Bi!!#>V!!#A*!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu popup_af_preDAQEvent_S1,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	PopupMenu popup_af_preDAQEvent_S1,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	PopupMenu popup_af_preDAQEvent_S1,mode=1,popvalue="- none -",value= #"WBP_GetAnalysisFunctions()"
	PopupMenu popup_af_midSweep_S2,pos={13.00,76.00},size={164.00,21.00},bodyWidth=110,disable=1,proc=WBP_PopupMenu_AnalysisFunctions,title="Mid sweep"
	PopupMenu popup_af_midSweep_S2,help={"Each time when new data is polled (available for background DAQ only)"}
	PopupMenu popup_af_midSweep_S2,userdata(tabnum)=  "1"
	PopupMenu popup_af_midSweep_S2,userdata(tabcontrol)=  "WBP_Set_Parameters"
	PopupMenu popup_af_midSweep_S2,userdata(ResizeControlsInfo)= A"!!,A^!!#?Q!!#A3!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu popup_af_midSweep_S2,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	PopupMenu popup_af_midSweep_S2,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	PopupMenu popup_af_midSweep_S2,mode=1,popvalue="- none -",value= #"WBP_GetAnalysisFunctions()"
	PopupMenu popup_af_postDAQEvent_S5,pos={17.00,154.00},size={160.00,21.00},bodyWidth=110,disable=1,proc=WBP_PopupMenu_AnalysisFunctions,title="Post DAQ"
	PopupMenu popup_af_postDAQEvent_S5,help={"After all DAQ has been finished"}
	PopupMenu popup_af_postDAQEvent_S5,userdata(tabnum)=  "1"
	PopupMenu popup_af_postDAQEvent_S5,userdata(tabcontrol)=  "WBP_Set_Parameters"
	PopupMenu popup_af_postDAQEvent_S5,userdata(ResizeControlsInfo)= A"!!,BA!!#A)!!#A/!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu popup_af_postDAQEvent_S5,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	PopupMenu popup_af_postDAQEvent_S5,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	PopupMenu popup_af_postDAQEvent_S5,mode=1,popvalue="- none -",value= #"WBP_GetAnalysisFunctions()"
	Button button_af_jump_to_proc,pos={66.00,179.00},size={113.00,21.00},disable=1,proc=WBP_ButtonProc_OpenAnaFuncs,title="Open procedure file"
	Button button_af_jump_to_proc,help={"Open the procedure where the analysis functions have to be defined"}
	Button button_af_jump_to_proc,userdata(tabnum)=  "1"
	Button button_af_jump_to_proc,userdata(tabcontrol)=  "WBP_Set_Parameters"
	Button button_af_jump_to_proc,userdata(ResizeControlsInfo)= A"!!,E>!!#AB!!#@F!!#<`z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_af_jump_to_proc,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	Button button_af_jump_to_proc,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	PopupMenu popup_WaveBuilder_trig_type_P53,pos={413.00,127.00},size={38.00,19.00},disable=1,proc=WBP_PopupMenu
	PopupMenu popup_WaveBuilder_trig_type_P53,help={"Type of trigonometric function"}
	PopupMenu popup_WaveBuilder_trig_type_P53,userdata(tabcontrol)=  "WBP_WaveType"
	PopupMenu popup_WaveBuilder_trig_type_P53,userdata(ResizeControlsInfo)= A"!!,I4J,hq8!!#>&!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu popup_WaveBuilder_trig_type_P53,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu popup_WaveBuilder_trig_type_P53,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu popup_WaveBuilder_trig_type_P53,userdata(tabnum)=  "3"
	PopupMenu popup_WaveBuilder_trig_type_P53,mode=1,popvalue="Sin",value= #"\"Sin;Cos\""
	PopupMenu popup_WaveBuilder_build_res_P55,pos={188.00,138.00},size={129.00,19.00},bodyWidth=40,disable=1,proc=WBP_PopupMenu,title="Build Resolution"
	PopupMenu popup_WaveBuilder_build_res_P55,help={"*Experimental*: Changes the resolution of the frequency spectra serving as input for the time-domain output. Requires a lot of RAM!"}
	PopupMenu popup_WaveBuilder_build_res_P55,userdata(tabnum)=  "2"
	PopupMenu popup_WaveBuilder_build_res_P55,userdata(tabcontrol)=  "WBP_WaveType"
	PopupMenu popup_WaveBuilder_build_res_P55,userdata(ResizeControlsInfo)= A"!!,GL!!#@n!!#@e!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu popup_WaveBuilder_build_res_P55,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu popup_WaveBuilder_build_res_P55,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu popup_WaveBuilder_build_res_P55,mode=1,popvalue="1",value= #"WBP_GetNoiseBuildResolution()"
	SetVariable SetVar_WaveBuilder_P26,pos={613.00,117.00},size={123.00,18.00},bodyWidth=60,disable=3,proc=WBP_SetVarProc_UpdateParam,title="Filter Order"
	SetVariable SetVar_WaveBuilder_P26,help={"Order of the Butterworth filter, see also DisplayHelpTopic `FilterIIR`"}
	SetVariable SetVar_WaveBuilder_P26,userdata(tabnum)=  "2"
	SetVariable SetVar_WaveBuilder_P26,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P26,userdata(ResizeControlsInfo)= A"!!,J*5QF.9!!#@Z!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P26,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P26,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P26,limits={1,100,1},value= _NUM:0
	SetVariable SetVar_WaveBuilder_P27,pos={741.00,117.00},size={91.00,18.00},disable=3,proc=WBP_SetVarProc_UpdateParam,title="Delta"
	SetVariable SetVar_WaveBuilder_P27,help={"Filter order delta."}
	SetVariable SetVar_WaveBuilder_P27,userdata(tabnum)=  "2"
	SetVariable SetVar_WaveBuilder_P27,userdata(tabcontrol)=  "WBP_WaveType"
	SetVariable SetVar_WaveBuilder_P27,userdata(ResizeControlsInfo)= A"!!,JJ5QF.9!!#?o!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable SetVar_WaveBuilder_P27,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable SetVar_WaveBuilder_P27,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable SetVar_WaveBuilder_P27,limits={-inf,99999,1},value= _NUM:0
	PopupMenu popup_WaveBuilder_exp_P56,pos={417.00,153.00},size={58.00,19.00},disable=1,proc=WBP_PopupMenu
	PopupMenu popup_WaveBuilder_exp_P56,help={"Pulse train type"}
	PopupMenu popup_WaveBuilder_exp_P56,userdata(tabnum)=  "5"
	PopupMenu popup_WaveBuilder_exp_P56,userdata(tabcontrol)=  "WBP_WaveType"
	PopupMenu popup_WaveBuilder_exp_P56,userdata(ResizeControlsInfo)= A"!!,I6J,hqS!!#?!!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu popup_WaveBuilder_exp_P56,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu popup_WaveBuilder_exp_P56,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	PopupMenu popup_WaveBuilder_exp_P56,mode=1,popvalue="Square",value= #"\"Square;Triangle\""
	CheckBox check_NewSeedForEachSweep_P49_0,pos={494.00,133.00},size={85.00,15.00},disable=3,proc=WBP_CheckProc,title="Seed / Sweep"
	CheckBox check_NewSeedForEachSweep_P49_0,help={"When checked, the random number generator (RNG) seed is updated with each sweep. Seeds are saved with the stimulus."}
	CheckBox check_NewSeedForEachSweep_P49_0,userdata(tabnum)=  "5"
	CheckBox check_NewSeedForEachSweep_P49_0,userdata(tabcontrol)=  "WBP_WaveType"
	CheckBox check_NewSeedForEachSweep_P49_0,userdata(ResizeControlsInfo)= A"!!,I]!!#@i!!#?c!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_NewSeedForEachSweep_P49_0,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	CheckBox check_NewSeedForEachSweep_P49_0,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	CheckBox check_NewSeedForEachSweep_P49_0,value= 0
	Button button_NewSeed_P48_0,pos={494.00,153.00},size={72.00,20.00},disable=3,proc=WBP_ButtonProc_NewSeed,title="New Seed"
	Button button_NewSeed_P48_0,help={"Create a different epoch by changing the seed value of the PRNG "}
	Button button_NewSeed_P48_0,userdata(tabnum)=  "5"
	Button button_NewSeed_P48_0,userdata(tabcontrol)=  "WBP_WaveType"
	Button button_NewSeed_P48_0,userdata(ResizeControlsInfo)= A"!!,I]!!#A(!!#?I!!#<Xz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_NewSeed_P48_0,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	Button button_NewSeed_P48_0,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	DefineGuide UGH1={FT,206},UGH0={UGH1,0.902778,FB}
	SetWindow kwTopWin,hook(main)=WBP_MainWindowHook
	SetWindow kwTopWin,hook(ResizeControls)=ResizeControls#ResizeControlsHook
	SetWindow kwTopWin,userdata(ResizeControlsInfo)= A"!!*'\"z!!#E6^]6bEJ,fQLzzzzzzzzzzzzzzzzzzzz"
	SetWindow kwTopWin,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzzzzzzzzzzzzzzz"
	SetWindow kwTopWin,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzzzzzzzzz!!!"
	SetWindow kwTopWin,userdata(ResizeControlsGuides)=  "UGH1;UGH0;"
	SetWindow kwTopWin,userdata(ResizeControlsInfoUGH0)= A":-hTC3`S[@0KW?-:-)HbG%F!_Bl%<kE][6':dmEFF(KAR85E,T>#.mm5tj<o4&A^O8Q88W:-(6m2D-[;4%E:B6q&gk<C]S74%E:B6q&jl7RB1778-NR;b9q[:JNr)/ibU@2`E]X"
	SetWindow kwTopWin,userdata(ResizeControlsInfoUGH1)= A":-hTC3`S[@0frH.:-)HbG%F!_Bl%<kE][6':dmEFF(KAR85E,T>#.mm5tj<o4&A^O8Q88W:-(-a2D-[;4%E:B6q&gk7T;H><CoSI1-.Kp78-NR;b9q[:JNr+0K(u"
	SetWindow kwTopWin,userdata(panelVersion)=  "1"
	Display/W=(0,286,1068,487)/FG=($"",UGH1,FR,UGH0)/HOST=#
	SetWindow kwTopWin,hook(ResizeControls)=ResizeControls#ResizeControlsHook
	SetWindow kwTopWin,userdata(ResizeControlsInfo)= A"!!,Ct!!#A/!!#E!5QF0#!!!!\"zzzzzzzzzzzzzzzzzzzz"
	SetWindow kwTopWin,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzzzzzzzzzzzzzzz"
	SetWindow kwTopWin,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzzzzzzzzz!!!"
	SetWindow kwTopWin,userdata(ResizeControlsGuides)=  "UGH0;"
	SetWindow kwTopWin,userdata(ResizeControlsInfoUGH0)= A":-hTC3`S[@0KW?-:-)HbG%F!_Bl%<kE][6':dmEFF(KAR85E,T>#.mm5tj<o4&A^O8Q88W:-(6j2*4<.8OQ!%3^uFt7o`,K75?nc;FO8U:K'ha8P`)B/Mo4E"
	RenameWindow #,WaveBuilderGraph
	SetActiveSubwindow ##
EndMacro

Function WBP_StartupSettings()

	if(!WindowExists(panel))
		printf "The window %s does not exist\r", panel
		ControlWindowToFront()
		return 1
	endif

	HideTools/A/W=$panel

	WAVE/Z wv = $""
	ListBox listbox_combineEpochMap, listWave=wv, win=$panel

	KillWindow/Z $WBP_GetFFTSpectrumPanel()

	if(SearchForInvalidControlProcs(panel))
		return NaN
	endif

	KillOrMoveToTrash(wv=GetSegmentTypeWave())
	KillOrMoveToTrash(wv=GetWaveBuilderWaveParam())
	KillOrMoveToTrash(wv=GetWaveBuilderWaveTextParam())

	SetPopupMenuIndex(panel, "popup_WaveBuilder_SetList", 0)
	SetCheckBoxState(panel, "check_PreventUpdate", CHECKBOX_UNSELECTED)

	SetPopupMenuIndex(panel, "popup_WaveBuilder_FolderList", 0)
	SetPopupMenuIndex(panel, "popup_WaveBuilder_ListOfWaves", 0)

	WBP_LoadSet(NONE)

	Execute/P/Q/Z "DoWindow/R " + panel
	Execute/P/Q/Z "COMPILEPROCEDURES "
End

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

	variable i, epoch, numEpochs, numSweeps
	variable red, green, blue
	string trace
	variable maxYValue, minYValue

	if(!HasPanelLatestVersion(panel, WAVEBUILDER_PANEL_VERSION))
		Abort "Wavebuilder panel is out of date. Please close and reopen it."
	endif

	RemoveTracesFromGraph(waveBuilderGraph)

	WAVE/Z stimSet = WB_GetStimSet()
	if(!WaveExists(stimSet))
		return NaN
	endif

	WAVE ranges = GetAxesRanges(waveBuilderGraph)

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

	numSweeps = DimSize(displayData, COLS)

	if(numSweeps == 0)
		return NaN
	endif

	for(i = 0; i < numSweeps; i += 1)
		trace = NameOfWave(displayData) + "_S" + num2str(i)
		AppendToGraph/W=$waveBuilderGraph displayData[][i]/TN=$trace
		GetSweepColor(i, red, green, blue)
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
	variable lowPassCutOff, highPassCutOff, maxDuration

	if(!GetCheckBoxState(panel, "check_PreventUpdate"))
		WBP_DisplaySetInPanel()
	endif

	switch(GetTabID(panel, "WBP_WaveType"))
		case EPOCH_TYPE_NOISE:
			lowPassCutOff  = GetSetVariable(panel, "SetVar_WaveBuilder_P20")
			highPassCutOff = GetSetVariable(panel, "SetVar_WaveBuilder_P22")

			if(WB_IsValidCutoffFrequency(HighPassCutOff) || WB_IsValidCutoffFrequency(LowPassCutOff))
				EnableControls(panel, "SetVar_WaveBuilder_P26;SetVar_WaveBuilder_P27")
			else
				DisableControls(panel, "SetVar_WaveBuilder_P26;SetVar_WaveBuilder_P27")
			endif

			WBP_LowPassDeltaLimits()
			WBP_HighPassDeltaLimits()
			WBP_CutOffCrossOver()
			break
		case EPOCH_TYPE_SIN_COS:
			if(GetCheckBoxState(panel,"check_Sin_Chirp_P43"))
				EnableControls(panel, "SetVar_WaveBuilder_P24;SetVar_WaveBuilder_P25")
			else
				DisableControls(panel, "SetVar_WaveBuilder_P24;SetVar_WaveBuilder_P25")
			endif
			break
		case EPOCH_TYPE_PULSE_TRAIN:
			if(GetCheckBoxState(panel,"check_SPT_NumPulses_P46"))
				DisableControl(panel, "SetVar_WaveBuilder_P0")
				EnableControls(panel, "SetVar_WaveBuilder_P45;SetVar_WaveBuilder_P47")
			else
				EnableControl(panel, "SetVar_WaveBuilder_P0")
				DisableControls(panel, "SetVar_WaveBuilder_P45;SetVar_WaveBuilder_P47")
			endif

			if(GetCheckBoxState(panel,"check_SPT_Poisson_P44"))
				EnableControls(panel, "check_NewSeedForEachSweep_P49_0;button_NewSeed_P48_0")
			else
				DisableControls(panel, "check_NewSeedForEachSweep_P49_0;button_NewSeed_P48_0")
			endif

			maxDuration = WBP_ReturnPulseDurationMax()
			SetVariable SetVar_WaveBuilder_P8 win=$panel, limits = {0, maxDuration, 0.1}
			if(GetSetVariable(panel, "SetVar_WaveBuilder_P8") > maxDuration)
				SetSetVariable(panel, "SetVar_WaveBuilder_P8", maxDuration)
			endif
			break
		case EPOCH_TYPE_COMBINE:
			WB_UpdateEpochCombineList(WBP_GetOutputType())
			break
		default:
			// nothing to do
			break
	endswitch

	controls = "SetVar_WB_DurDeltaMult_P52;SetVar_WB_AmpDeltaMult_P50;SetVar_WB_OffsetDeltaMult_P51;"             + \
			   "SetVar_WB_OffsetDeltaMult_P51_0;SetVar_WB_OffsetDeltaMult_P51_1;SetVar_WB_OffsetDeltaMult_P51_2;" + \
			   "SetVar_WB_OffsetDeltaMult_P51_3;SetVar_WB_OffsetDeltaMult_P51_4;SetVar_WB_OffsetDeltaMult_P51_5"

	deltaMode = GetPopupMenuString(panel,"popup_WaveBuilder_exp_P40")
	if(!cmpstr(deltaMode, "Power") || !cmpstr(deltaMode, "Multiplier"))
		EnableControls(panel, controls)
	else
		DisableControls(panel, controls)
	endif
End

/// @brief Passes the data from the WP wave to the panel
static Function WBP_ParameterWaveToPanel(stimulusType)
	variable stimulusType

	string list, control, data, customWaveName
	variable segment, numEntries, i, row

	WAVE WP    = GetWaveBuilderWaveParam()
	WAVE/T WPT = GetWaveBuilderWaveTextParam()

	segment = GetSetVariable(panel, "setvar_WaveBuilder_CurrentEpoch")

	list = GrepList(ControlNameList(panel), ".*_P[[:digit:]]+")

	numEntries = ItemsInList(list)
	for(i = 0; i < numEntries; i += 1)
		control = StringFromList(i, list)
		row = WBP_ExtractRowNumberFromControl(control, "P")
		WBP_SetControl(panel, control, WP[row][segment][stimulusType])
	endfor

	list = GrepList(ControlNameList(panel), ".*_T[[:digit:]]+")

	numEntries = ItemsInList(list)
	for(i = 0; i < numEntries; i += 1)
		control = StringFromList(i, list)
		row = WBP_ExtractRowNumberFromControl(control, "T")
		data = WBP_TranslateControlContents(control, FROM_WAVE_TO_PANEL, WPT[row][segment])
		SetSetVariableString(panel, control, data)
	endfor

	if(stimulusType == EPOCH_TYPE_CUSTOM)
		customWaveName = WPT[0][segment]
		WAVE/Z customWave = $customWaveName
		if(WaveExists(customWave))
			GroupBox group_WaveBuilder_FolderPath win=$panel, title=GetWavesDataFolder(customWave, 1)
			PopupMenu popup_WaveBuilder_ListOfWaves, win=$panel, popMatch=NameOfWave(customWave)
		endif
	endif
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
	variable i, numPanels, channelType

	switch(ba.eventCode)
		case 2: // mouse up

			setWaveToDelete = GetPopupMenuString(panel, "popup_WaveBuilder_SetList")

			if(!CmpStr(SetWaveToDelete, NONE))
				print "Select a set to delete from popup menu."
				break
			endif

			SVAR/Z/SDFR=GetITCDevicesFolder() ITCPanelTitleList
			if(SVAR_Exists(ITCPanelTitleList) && cmpstr(ITCPanelTitleList, ""))
				numPanels = ItemsInList(ITCPanelTitleList)
				for(i = 0; i < numPanels; i += 1)
					panelTitle = StringFromList(i, ITCPanelTitleList)
					if(StringMatch(SetWaveToDelete, CHANNEL_DA_SEARCH_STRING))
						channelType = CHANNEL_TYPE_DAC
					else
						channelType = CHANNEL_TYPE_TTL
					endif

					if(!WindowExists(panelTitle))
						WBP_DeleteSet()
						continue
					endif

					popupMenuSelectedItemsStart = WBP_PopupMenuWaveNameList(panelTitle, channelType, CHANNEL_CONTROL_WAVE)
					popupMenuSelectedItemsEnd = WBP_PopupMenuWaveNameList(panelTitle, channelType, CHANNEL_CONTROL_INDEX_END)
					WBP_DeleteSet()
					WBP_RestorePopupMenuSelection(panelTitle, channelType, CHANNEL_CONTROL_WAVE, popupMenuSelectedItemsStart)
					WBP_RestorePopupMenuSelection(panelTitle, channelType, CHANNEL_CONTROL_INDEX_END, popupMenuSelectedItemsEnd)
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
			WAVE SegWvType = GetSegmentTypeWave()
			SegWvType[101] = sva.dval
			WBP_UpdatePanelIfAllowed()
			break
	endswitch

	return 0
End

Function WBP_ButtonProc_AutoScale(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch(ba.eventCode)
		case 2: // mouse up
			SetAxis/A/W=$WaveBuilderGraph
			break
	endswitch

	return 0
End

Function WBP_CheckProc(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	switch(cba.eventCode)
		case 2: // mouse up
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

	variable tabID = GetTabID(panel, "WBP_WaveType")

	if(tabID != EPOCH_TYPE_PULSE_TRAIN)
		EnableControl(panel, "SetVar_WaveBuilder_P0")
	endif

	if(tabID == EPOCH_TYPE_CUSTOM || tabID == EPOCH_TYPE_COMBINE)
		HideControls(tca.win, "SetVar_WaveBuilder_P0;SetVar_WaveBuilder_P1;SetVar_WaveBuilder_P2;SetVar_WaveBuilder_P3;SetVar_WB_DurDeltaMult_P52;SetVar_WB_AmpDeltaMult_P50")
		if(tabID == EPOCH_TYPE_COMBINE)
			HideControl(tca.win, "popup_WaveBuilder_exp_P40")
		endif
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
			WB_UpdateEpochCombineList(WBP_GetOutputType())

			SetSetVariableString(panel, "setvar_WaveBuilder_baseName", DEFAULT_SET_PREFIX)
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
/// @param control name of the control, the expected format is `$str_$sep$row_$suffix` where `$str` may contain any
/// @param sep single character, either `P` or `T`
/// characters but `$suffix` is not allowed to include the substring `_$sep`.
static Function WBP_ExtractRowNumberFromControl(control, sep)
	string control, sep

	variable start, stop, row

	start = strsearch(control, "_" + sep, Inf, 1)
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

	variable stimulusType, epoch, paramRow

	WAVE WP = GetWaveBuilderWaveParam()

	WBP_SetControl(panel, control, value)

	stimulusType = GetTabID(panel, "WBP_WaveType")
	epoch        = GetSetVariable(panel, "setvar_WaveBuilder_CurrentEpoch")
	paramRow     = WBP_ExtractRowNumberFromControl(control, "P")
	WP[paramRow][epoch][stimulusType] = value
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

	variable LowPassCutOff, numSweeps, LowPassDelta, DeltaLimit

	WAVE SegWvType = GetSegmentTypeWave()
	numSweeps = SegWvType[101]

	LowPassCutoff = GetSetVariable(panel, "SetVar_WaveBuilder_P20")
	LowPassDelta = GetSetVariable(panel, "SetVar_WaveBuilder_P21")

	if(LowPassDelta > 0)
		DeltaLimit = trunc(100000 / numSweeps)
		SetVariable SetVar_WaveBuilder_P21 win=$panel, limits = {-inf, DeltaLimit, 1}
		if(LowPassDelta > DeltaLimit)
			SetSetVariable(panel, "SetVar_WaveBuilder_P21", DeltaLimit)
		endif
	endif

	if(LowPassDelta < 0)
		DeltaLimit = trunc(-((LowPassCutOff/numSweeps) -1))
		SetVariable SetVar_WaveBuilder_P21 win=$panel, limits = {DeltaLimit, 99999, 1}
		if(LowPassDelta < DeltaLimit)
			SetSetVariable(panel, "SetVar_WaveBuilder_P21", DeltaLimit)
		endif
	endif
End

static Function WBP_HighPassDeltaLimits()

	variable HighPassCutOff, numSweeps, HighPassDelta, DeltaLimit

	WAVE SegWvType = GetSegmentTypeWave()
	numSweeps = SegWvType[101]

	HighPassCutoff = GetSetVariable(panel, "SetVar_WaveBuilder_P22")
	HighPassDelta = GetSetVariable(panel, "SetVar_WaveBuilder_P23")

	if(HighPassDelta > 0)
		DeltaLimit = trunc((100000 - HighPassCutOff) / numSweeps) - 1
		SetVariable SetVar_WaveBuilder_P23 win=$panel, limits = { -inf, DeltaLimit, 1}
		if(HighPassDelta > DeltaLimit)
			SetSetVariable(panel, "SetVar_WaveBuilder_P23", DeltaLimit)
		endif
	endif

	if(HighPassDelta < 0)
		DeltaLimit = trunc(HighPassCutOff / numSweeps) + 1
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
		DisableControls(panel, list)

		WBP_UpdateControlAndWP("SetVar_WaveBuilder_P2", 0)
		WBP_UpdateControlAndWP("SetVar_WaveBuilder_P3", 0)
		WBP_UpdateControlAndWP("SetVar_WaveBuilder_P4", 0)
		WBP_UpdateControlAndWP("SetVar_WaveBuilder_P5", 0)
	elseif(stimulusType == STIMULUS_TYPE_DA)
		SetVariable SetVar_WaveBuilder_P2 win =$panel, limits = {-inf,inf,1}
		EnableControls(panel, list)
	else
		ASSERT(0, "Unknown stimulus type")
	endif

	WBP_UpdatePanelIfAllowed()
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

Function/S WBP_GetListOfWaves()

	string listOfWaves
	string searchPattern = "*"

	ControlInfo/W=$panel setvar_WaveBuilder_SearchString
	if(!IsEmpty(s_value))
		searchPattern = S_Value
	endif

	DFREF dfr = WBP_GetFolderPath()
	DFREF saveDFR = GetDataFolderDFR()
	SetDataFolder dfr
	listOfWaves = NONE + ";" + Wavelist(searchPattern, ";", "TEXT:0,MAXCOLS:1")
	SetDataFolder saveDFR

	return listOfWaves
End

Function WBP_SetVarProc_SetSearchString(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	switch(sva.eventCode)
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			break
	endswitch

	return 0
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
static Function/S WBP_AssembleSetName([modName])
	string modName
	string AssembledBaseName = ""

	ControlInfo/W=$panel setvar_WaveBuilder_baseName
	if(ParamIsDefault(modName))
		AssembledBaseName += s_value[0,15]
	else
		AssembledBaseName += s_value[0,(15 - strlen(modName))]
		AssembledBaseName += modName
	endif
	ControlInfo/W=$panel popup_WaveBuilder_OutputType
	AssembledBaseName += "_" + s_value + "_"
	ControlInfo/W=$panel setvar_WaveBuilder_SetNumber
	AssembledBaseName += num2str(v_value)

	return CleanupName(AssembledBaseName, 0)
End

/// @brief Split the full setname into its three parts: prefix, outputType and set number
///
/// Counterpart to WBP_AssembleSetName()
static Function WBP_SplitSetName(setName, setPrefix, channelType, setNumber)
	string setName
	string &setPrefix
	variable &channelType, &setNumber

	string channelTypeString, setNumberString

	SplitString/E="(.*)_(DA|TTL)_([[:digit:]]+)" setName, setPrefix, channelTypeString, setNumberString

	ASSERT(V_flag == 3, "Invalid setName format")

	channelType = !cmpstr(channelTypeString, "DA") ? CHANNEL_TYPE_DAC : CHANNEL_TYPE_TTL
	setNumber   = str2num(setNumberString)
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

	list = GetListOfObjects($path, "WP_.*" + setType + ".*")
	stimSetList = ""

	numWaves = ItemsInList(list)
	for(i = 0; i < numWaves; i += 1)
		stimSetList = AddListItem(RemovePrefix(StringFromList(i, list), startStr="WP_"), stimSetList, ";", Inf)
	endfor

	return SortList(stimSetList, ";", 16)
end

static Function WBP_SaveSetParam()
	string setName, childStimsets
	variable i

	WAVE SegWvType = GetSegmentTypeWave()
	WAVE WP        = GetWaveBuilderWaveParam()
	WAVE WPT       = GetWaveBuilderWaveTextParam()

	DFREF dfr = GetSetParamFolder(WBP_GetOutputType())
	setName = WBP_AssembleSetName()

	// avoid circle references of any order
	childStimsets = WB_StimsetRecursion()
	if(WhichListItem(setname, childStimsets, ";", 0, 0) != -1)
		do
			i += 1
			setName = WBP_AssembleSetName(modName = "_" + num2str(i))
		while(WhichListItem(setname, childStimsets, ";", 0, 0) != -1)
		printf "Naming failure: Stimset can not reference itself. Saving with different name: \"%s\" to remove reference to itself.\r", setName
	endif

	Duplicate/O SegWvType , dfr:$WB_GetParameterWaveName(setName, STIMSET_PARAM_SEGWVTYPE)
	Duplicate/O WP	      , dfr:$WB_GetParameterWaveName(setName, STIMSET_PARAM_WP)
	Duplicate/O WPT       , dfr:$WB_GetParameterWaveName(setName, STIMSET_PARAM_WPT)
End

static Function WBP_LoadSet(setName)
	string setName

	string funcList, setPrefix
	variable channelType, setNumber, preventUpdate

	// prevent update until graph was loaded
	preventUpdate = GetCheckBoxState(panel, "check_PreventUpdate")
	SetCheckBoxState(panel, "check_PreventUpdate", 1)

	if(cmpstr(setName, NONE))
		WBP_SplitSetname(setName, setPrefix, channelType, setNumber)

		WAVE WP        = WB_GetWaveParamForSet(setName)
		WAVE/T WPT     = WB_GetWaveTextParamForSet(setName)
		WAVE SegWvType = WB_GetSegWvTypeForSet(setName)

		DFREF dfr = GetWaveBuilderDataPath()
		Duplicate/O WP, dfr:WP
		Duplicate/O WPT, dfr:WPT
		Duplicate/O SegWvType, dfr:SegWvType
	else
		setPrefix = DEFAULT_SET_PREFIX
		channelType = CHANNEL_TYPE_DAC
	endif

	if(channelType == CHANNEL_TYPE_TTL)
		PopupMenu popup_WaveBuilder_OutputType win=$panel, mode = 2
		WBP_ChangeWaveType(STIMULUS_TYPE_TLL)
	elseif(channelType == CHANNEL_TYPE_DAC)
		PopupMenu popup_WaveBuilder_OutputType win=$panel, mode = 1
		WBP_ChangeWaveType(STIMULUS_TYPE_DA)
	else
		ASSERT(0, "unknown channelType")
	endif

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

	SetSetVariableString(panel, "setvar_WaveBuilder_baseName", setPrefix)
	SetSetVariable(panel, "setvar_WaveBuilder_SetNumber", setNumber)

	funcList = WBP_GetAnalysisFunctions()
	SetAnalysisFunctionIfFuncExists(panel, "popup_af_preDAQEvent_S1", funcList, WPT[1][99])
	SetAnalysisFunctionIfFuncExists(panel, "popup_af_midSweep_S2", funcList, WPT[2][99])
	SetAnalysisFunctionIfFuncExists(panel, "popup_af_postSweep_S3", funcList, WPT[3][99])
	SetAnalysisFunctionIfFuncExists(panel, "popup_af_postSet_S4", funcList, WPT[4][99])
	SetAnalysisFunctionIfFuncExists(panel, "popup_af_postDAQEvent_S5", funcList, WPT[5][99])

	WBP_SelectEpoch(0)
	WBP_UpdateEpochControls()

	// reset old state of checkbox and update panel
	SetCheckBoxState(panel, "check_PreventUpdate", preventUpdate)
	WBP_UpdatePanelIfAllowed()
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

	WPName        = WB_GetParameterWaveName(setName, STIMSET_PARAM_WP)
	WPTName       = WB_GetParameterWaveName(setName, STIMSET_PARAM_WPT)
	SegWvTypeName = WB_GetParameterWaveName(setName, STIMSET_PARAM_SEGWVTYPE)

	// makes sure that a set is selected
	if(!CmpStr(setName, NONE))
		return NaN
	endif

	if(StringMatch(setName, CHANNEL_TTL_SEARCH_STRING))
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

	string setName

	switch(ba.eventCode)
		case 2: // mouse up
			setName = GetPopupMenuString(panel, "popup_WaveBuilder_SetList")
			WBP_LoadSet(setName)
			break
	endswitch

	return 0
End

static Function WBP_CutOffCrossOver()

	variable HighPassCutOff, LowPassCutOff

	LowPassCutOff = GetSetVariable(panel, "SetVar_WaveBuilder_P20")
	HighPassCutOff = GetSetVariable(panel, "SetVar_WaveBuilder_P22")

	if(!WB_IsValidCutoffFrequency(HighPassCutOff) || !WB_IsValidCutoffFrequency(LowPassCutOff))
		return NaN
	endif

	if(HighPassCutOff <= LowPassCutOff)
		SetSetVariable(panel, "SetVar_WaveBuilder_P22", LowPassCutOff + 1)
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

	return NONE + ";root:;..;" + folderNameList
End

Function WBP_PopMenuProc_FolderSelect(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	string popStr, path

	switch(pa.eventCode)
		case 2: // mouse up
			popStr = pa.popStr

			if(!CmpStr(popStr, NONE))
				return 0
			elseif(!CmpStr(popStr, "root:"))
				path = "root:"
			else
				ControlInfo/W=$panel group_WaveBuilder_FolderPath

				if(!cmpstr(popStr, ".."))
					path = S_Value + ":"
				else
					path = s_value + popStr + ":"
				endif

				// canonicalize path
				if(DataFolderExists(path))
					path = GetDataFolder(1, $path)
				endif
			endif

			GroupBox group_WaveBuilder_FolderPath win=$panel, title = path
			PopupMenu popup_WaveBuilder_FolderList win=$panel, mode = 1
			PopupMenu popup_WaveBuilder_ListOfWaves win=$panel, mode = 1
			ControlUpdate/W=$panel popup_WaveBuilder_ListOfWaves
			break
	endswitch

	return 0
End

/// @brief Update the popup menus and its `MenuExp` user data after stim set changes
///
/// @param panelTitle [optional, defaults to all locked devices] device
Function WBP_UpdateITCPanelPopUps([panelTitle])
	string panelTitle

	variable i, j, numPanels
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

		if(!WindowExists(panelTitle))
			continue
		endif

		for(j = CHANNEL_INDEX_ALL; j < NUM_DA_TTL_CHANNELS; j += 1)
			ctrlWave     = GetPanelControl(j, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE)
			ctrlIndexEnd = GetPanelControl(j, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_INDEX_END)
			SetControlUserData(panelTitle, ctrlWave, "MenuExp", DAlist)
			SetControlUserData(panelTitle, ctrlIndexEnd, "MenuExp", DAlist)

			ctrlWave     = GetPanelControl(j, CHANNEL_TYPE_TTL, CHANNEL_CONTROL_WAVE)
			ctrlIndexEnd = GetPanelControl(j, CHANNEL_TYPE_TTL, CHANNEL_CONTROL_INDEX_END)
			SetControlUserData(panelTitle, ctrlWave, "MenuExp", TTLlist)
			SetControlUserData(panelTitle, ctrlIndexEnd, "MenuExp", TTLlist)
		endfor
	endfor
End

/// @brief Returns the names of the items in the popmenu controls in a list
static Function/S WBP_PopupMenuWaveNameList(panelTitle, channelType, controlType)
	string panelTitle
	variable channelType, controlType

	string ctrl, stimset
	string list = ""
	variable i

	ASSERT(controlType == CHANNEL_CONTROL_WAVE || controlType == CHANNEL_CONTROL_INDEX_END, "Invalid controlType")

	for(i = 0; i < NUM_DA_TTL_CHANNELS; i += 1)
		ctrl = GetPanelControl(i, channelType, controlType)
		stimset = GetPopupMenuString(panelTitle, ctrl)
		list = AddListItem(stimset, list, ";", Inf)
	endfor

	return list
End

static Function WBP_RestorePopupMenuSelection(panelTitle, channelType, controlType, list)
	variable channelType, controlType
	string panelTitle, list

	variable i, stimsetIndex
	string ctrl, stimset

	ASSERT(controlType == CHANNEL_CONTROL_WAVE || controlType == CHANNEL_CONTROL_INDEX_END, "Invalid controlType")

	for(i = 0; i < NUM_DA_TTL_CHANNELS; i += 1)
		ctrl    = GetPanelControl(i, channelType, controlType)
		stimset = GetPopupMenuString(panelTitle, ctrl)

		if(cmpstr(stimset, StringFromList(i, list)) == 1 || isEmpty(stimset))
			stimsetIndex = GetPopupMenuIndex(panelTitle, ctrl)
			PGC_SetAndActivateControl(paneltitle, ctrl, val=(stimsetIndex - 1))
		endif
	endfor
End

Function WBP_CheckProc_PreventUpdate(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	switch(cba.eventCode)
		case 2: // mouse up
			WBP_UpdatePanelIfAllowed()
			break
	endswitch
End

Function WBP_PopupMenu(pa) : PopupMenuControl
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
	variable numEntries, i, valid_f1, valid_f2

	funcList  = FunctionList("!AF_PROTO_ANALYSIS_FUNC*", ";", "KIND:2,WIN:MIES_AnalysisFunctions.ipf")
	funcList += FunctionList("*", ";", "KIND:2,WIN:UserAnalysisFunctions.ipf")

	numEntries = ItemsInList(funcList)
	for(i = 0; i < numEntries; i += 1)
		func = StringFromList(i, funcList)

		// assign each function to the function reference of type AF_PROTO_ANALYSIS_FUNC_V*
		// this allows to check if the signature of func is the same as the one of AF_PROTO_ANALYSIS_FUNC_V*
		FUNCREF AF_PROTO_ANALYSIS_FUNC_V1 f1 = $func
		FUNCREF AF_PROTO_ANALYSIS_FUNC_V2 f2 = $func

		valid_f1 = FuncRefIsAssigned(FuncRefInfo(f1))
		valid_f2 = FuncRefIsAssigned(FuncRefInfo(f2))

		if(valid_f1 || valid_f2)
			funcListClean = AddListItem(func, funcListClean, ";", Inf)
		endif
	endfor

	return funcListClean
End

/// @brief Return a list of noise types, usable for popup menues
Function/S WBP_GetNoiseTypes()
	return NOISE_TYPES_STRINGS
End

/// @brief Return a list of build resolutions , usable for popup menues
Function/S WBP_GetNoiseBuildResolution()
	return "1;5;10;20;40;60;80;100"
End

Function WBP_ButtonProc_OpenAnaFuncs(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	string userFile, baseName, fileName
	variable refNum

	switch(ba.eventCode)
		case 2: // mouse up
			baseName = "UserAnalysisFunctions"
			fileName = baseName + ".ipf"
			userFile = GetFolder(FunctionPath("")) + fileName
			GetFileFolderInfo/Q/Z userFile
			if(V_Flag) // create a default file
				Open refNum as userFile

				fprintf refNum, "#pragma rtGlobals=3		// Use modern global access method and strict wave access.\n"
				fprintf refNum, "\n"
				fprintf refNum, "// This file can be used for user analysis functions.\n"
				fprintf refNum, "// It will not be overwritten by MIES on an upgrade.\n"
				Close refNum
			endif
			Execute/P/Q/Z "INSERTINCLUDE \"" + baseName + "\""
			Execute/P/Q/Z "COMPILEPROCEDURES "
			Execute/P/Q/Z "DisplayProcedure/W=$\"" + fileName + "\""
			break
	endswitch

	return 0
End

Function WBP_SetVarCombineEpochFormula(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	struct FormulaProperties fp
	string win, formula
	variable currentEpoch, lastSweep

	switch(sva.eventCode)
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			win     = sva.win
			formula = sva.sval

			WAVE/T WPT = GetWaveBuilderWaveTextParam()

			lastSweep = GetSetVariable(win, "SetVar_WB_SweepCount_S101") - 1

			if(WB_ParseCombinerFormula(formula, lastSweep, fp))
				break
			endif

			currentEpoch = GetSetVariable(win, "setvar_WaveBuilder_CurrentEpoch")

			WPT[6][currentEpoch] = WBP_TranslateControlContents(sva.ctrlName, FROM_PANEL_TO_WAVE, formula)
			WPT[7][currentEpoch] = WAVEBUILDER_COMBINE_FORMULA_VER

			WBP_UpdatePanelIfAllowed()
			break
	endswitch

	return 0
End

/// @brief Convert a control entry for the panel or the wave.
///
/// Useful if the visualization is different from the stored data.
///
/// @param control   name of WaveBuilder GUI control
/// @param direction one of #FROM_PANEL_TO_WAVE or #FROM_WAVE_TO_PANEL
/// @param data      string to convert
static Function/S WBP_TranslateControlContents(control, direction, data)
	string control, data
	variable direction

	strswitch(control)
		case "setvar_combine_formula_T6":
			if(direction == FROM_PANEL_TO_WAVE)
				struct FormulaProperties fp
				WB_FormulaSwitchToStimset(data, fp)
				return fp.formula
			elseif(direction == FROM_WAVE_TO_PANEL)
				return WB_FormulaSwitchToShorthand(data)
			endif
			break
		default:
			return data
			break
	endswitch
End

/// @brief Wavebuilder panel window hook
///
/// The epoch selection is done on the mouseup event if there exists no marquee.
/// This allows to still use the zooming capability.
Function WBP_MainWindowHook(s)
	STRUCT WMWinHookStruct &s

	string win
	variable numEntries, i, loc

	switch(s.eventCode)
		case 5:

		win = s.winName

		if(cmpstr(win, WaveBuilderGraph))
			break
		endif

		GetAxis/Q/W=$WaveBuilderGraph bottom
		if(V_Flag)
			break
		endif

		loc = AxisValFromPixel(WaveBuilderGraph, "bottom", s.mouseLoc.h)

		if(loc < V_min || loc > V_max)
			break
		endif

		GetMarquee/W=$WaveBuilderGraph/Z
		if(V_flag)
			break
		endif

		WAVE epochID = GetEpochID()
		numEntries = DimSize(epochID, ROWS)
		for(i = 0; i < numEntries; i += 1)
			if(epochID[i][%timeBegin] < loc && epochID[i][%timeEnd] > loc)

				if(GetSetVariable(panel, "setvar_WaveBuilder_CurrentEpoch") == i)
					return 0
				endif

				SetSetVariable(panel, "setvar_WaveBuilder_CurrentEpoch", i)
				WBP_SelectEpoch(i)
				return 1
			endif
		endfor

		break
	endswitch

	return 0
End

Function/S WBP_GetFFTSpectrumPanel()
	return panel + "#fftSpectrum"
End

Function WBP_ShowFFTSpectrumIfReq(segmentWave, sweep)
	WAVE segmentWave
	variable sweep

	DEBUGPRINT("sweep=", var=sweep)

	string extPanel, graphMag, graphPhase, trace
	string cursorInfoMagA, cursorInfoMagB
	string cursorInfoPhaseA, cursorInfoPhaseB
	variable red, green, blue

	if(!WindowExists(panel))
		return NaN
	endif

	extPanel = WBP_GetFFTSpectrumPanel()

	if(GetTabID(panel, "WBP_WaveType") != EPOCH_TYPE_NOISE)
		KillWindow/z $extPanel
		return NaN
	endif

	if(DimSize(segmentWave, ROWS) == 0)
		return NaN
	endif

	ASSERT(IsInteger(sweep), "Expected an integer sweep value")

	DFREF dfr = GetWaveBuilderDataPath()

	Duplicate/FREE segmentWave, input

	ASSERT(!cmpstr(WaveUnits(input, ROWS), "ms"), "Unexpected data units for row dimension")
	SetScale/P x 0, HARDWARE_ITC_MIN_SAMPINT/1000, "s", input
	FFT/FREE/DEST=cmplxFFT input

	MultiThread cmplxFFT = r2polar(cmplxFFT)

	Duplicate/O cmplxFFT dfr:$(SEGMENTWAVE_SPECTRUM_PREFIX + "Mag_" + num2str(sweep))/WAVE=spectrumMag
	Redimension/R spectrumMag

	MultiThread spectrumMag = 20 * log(real(cmplxFFT[p]))
	SetScale y, 0, 0, "dB", spectrumMag

	Duplicate/O cmplxFFT dfr:$(SEGMENTWAVE_SPECTRUM_PREFIX + "Phase_" + num2str(sweep))/WAVE=spectrumPhase
	Redimension/R spectrumPhase

	MultiThread spectrumPhase = imag(cmplxFFT[p]) * 180 / Pi
	SetScale y, 0, 0, "deg", spectrumPhase

	if(!WindowExists(extPanel))
		SetActiveSubwindow $panel
		NewPanel/HOST=#/EXT=0/W=(0,0,460,638)
		ModifyPanel fixedSize=1
		Display/W=(10,10,450,330)/HOST=#
		RenameWindow #,magnitude
		SetActiveSubwindow ##
		Display/W=(10,330,450,629)/HOST=#
		RenameWindow #,phase
		SetActiveSubwindow ##
		RenameWindow #,fftSpectrum
		SetActiveSubwindow ##
	endif

	graphMag   = extPanel + "#magnitude"
	graphPhase = extPanel + "#phase"

	WAVE axesRangesMag   = GetAxesRanges(graphMag)
	WAVE axesRangesPhase = GetAxesRanges(graphPhase)

	cursorInfoMagA   = CsrInfo(A, graphMag)
	cursorInfoMagB   = CsrInfo(B, graphMag)
	cursorInfoPhaseA = CsrInfo(A, graphPhase)
	cursorInfoPhaseB = CsrInfo(B, graphPhase)

	if(sweep == 0)
		RemoveTracesFromGraph(graphMag)
		RemoveTracesFromGraph(graphPhase)
	endif

	trace = "sweep_" + num2str(sweep)

	AppendToGraph/W=$graphMag spectrumMag/TN=$trace
	ModifyGraph/W=$graphMag log(bottom)=1
	ModifyGraph/W=$graphMag mode=4

	AppendToGraph/W=$graphPhase spectrumPhase/TN=$trace
	ModifyGraph/W=$graphPhase log(bottom)=1
	ModifyGraph/W=$graphPhase mode=4

	GetSweepColor(sweep, red, green, blue)
	ModifyGraph/W=$graphMag rgb($trace)   = (red, green, blue)
	ModifyGraph/W=$graphPhase rgb($trace) = (red, green, blue)

	SetAxesRanges(graphMag, axesRangesMag)
	SetAxesRanges(graphPhase, axesRangesPhase)

	RestoreCursor(graphMag, cursorInfoMagA)
	RestoreCursor(graphMag, cursorInfoMagB)

	RestoreCursor(graphPhase, cursorInfoPhaseA)
	RestoreCursor(graphPhase, cursorInfoPhaseB)
End

/// @brief Return distinct colors the sweeps of the wavebuilder
///
/// These are backwards compared to the trace colors
static Function GetSweepColor(sweep, red, green, blue)
	variable sweep, &red, &green, &blue

	return GetTraceColor(20 - sweep, red, green, blue)
End
