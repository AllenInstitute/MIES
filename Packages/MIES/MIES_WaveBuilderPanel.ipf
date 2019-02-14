#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_WBP
#endif

/// @file MIES_WaveBuilderPanel.ipf
/// @brief __WBP__ Panel for creating stimulus sets

static StrConstant panel              = "WaveBuilder"
static StrConstant WaveBuilderGraph   = "WaveBuilder#WaveBuilderGraph"
static StrConstant AnalysisParamGUI   = "WaveBuilder#AnalysisParamGUI"
static StrConstant DEFAULT_SET_PREFIX = "StimulusSetA"

static StrConstant SEGWVTYPE_CONTROL_REGEXP = ".*_S[[:digit:]]+"
static StrConstant WP_CONTROL_REGEXP        = ".*_P[[:digit:]]+"
static StrConstant WPT_CONTROL_REGEXP       = ".*_T[[:digit:]]+"

static Constant WBP_WAVETYPE_WP        = 0x1
static Constant WBP_WAVETYPE_WPT       = 0x2
static Constant WBP_WAVETYPE_SEGWVTYPE = 0x4

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
	NewPanel /K=1 /W=(95,479,1127,1026)
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
	PopupMenu popup_WaveBuilder_SetList,pos={23.00,425.00},size={125.00,19.00},bodyWidth=125,proc=WBP_PopupMenu_LoadSet
	PopupMenu popup_WaveBuilder_SetList,help={"Select stimulus set to load."}
	PopupMenu popup_WaveBuilder_SetList,userdata(ResizeControlsInfo)= A"!!,Bq!!#C9J,hq4!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu popup_WaveBuilder_SetList,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	PopupMenu popup_WaveBuilder_SetList,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	PopupMenu popup_WaveBuilder_SetList,mode=1,popvalue="- none -",value= #"WBP_ReturnListSavedSets()"
	Button button_WaveBuilder_KillSet,pos={22.00,460.00},size={125.00,20.00},proc=WBP_ButtonProc_DeleteSet,title="Delete Set"
	Button button_WaveBuilder_KillSet,help={"Delete stimulus set selected in popup menu."}
	Button button_WaveBuilder_KillSet,userdata(ResizeControlsInfo)= A"!!,Bi!!#CK!!#@^!!#<Xz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
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
	PopupMenu popup_WaveBuilder_OutputType,pos={29.00,45.00},size={125.00,19.00},bodyWidth=55,proc=WBP_PopMenuProc_WaveType,title="Wave Type"
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
	CheckBox check_UseEpochSeed_P39_0,pos={880.00,79.00},size={121.00,15.00},disable=1,proc=WBP_CheckProc,title="Epoch/Stimset Seed"
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
	PopupMenu popup_WaveBuilder_op_P70,help={"Delta operation"}
	PopupMenu popup_WaveBuilder_op_P70,userdata(ResizeControlsInfo)= A"!!,J/^]6]c!!#?O!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu popup_WaveBuilder_op_P70,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	PopupMenu popup_WaveBuilder_op_P70,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	PopupMenu popup_WaveBuilder_op_P70,mode=1,popvalue="None",value= #"\"None;Multiplier;Log;Squared;Power;Alternate;Explicit\""
	PopupMenu popup_WaveBuilder_op_P71,pos={635.00,99.00},size={75.00,19.00},bodyWidth=75,disable=1,proc=WBP_PopupMenu
	PopupMenu popup_WaveBuilder_op_P71,help={"Delta operation"}
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
	PopupMenu popup_WaveBuilder_op_P73,help={"Delta operation"}
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
	PopupMenu popup_WaveBuilder_op_P74,help={"Delta operation"}
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
	PopupMenu popup_WaveBuilder_op_P85,help={"Delta operation"}
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
	PopupMenu popup_WaveBuilder_op_P83,help={"Delta operation"}
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
	PopupMenu popup_WaveBuilder_op_P84,help={"Delta operation"}
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
	PopupMenu popup_WaveBuilder_op_P72,help={"Delta operation"}
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
	PopupMenu popup_WaveBuilder_op_S94,help={"Delta operation"}
	PopupMenu popup_WaveBuilder_op_S94,userdata(ResizeControlsInfo)= A"!!,H<!!#?G!!#?O!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu popup_WaveBuilder_op_S94,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	PopupMenu popup_WaveBuilder_op_S94,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	PopupMenu popup_WaveBuilder_op_S94,mode=1,popvalue="None",value= #"\"None;Multiplier;Log;Squared;Power;Alternate;Explicit\""
	SetVariable setvar_explDeltaValues_T28_ALL,pos={209.00,94.00},size={125.00,18.00},disable=2,proc=WBP_SetVarProc_UpdateParam
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
	Button button_WaveBuilder_SaveSet1,pos={22.00,399.00},size={125.00,20.00},proc=WBP_ButtonProc_LoadSet,title="Load Set"
	Button button_WaveBuilder_SaveSet1,help={"Load the selected stimulus set"}
	Button button_WaveBuilder_SaveSet1,userdata(ResizeControlsInfo)= A"!!,Bi!!#C,J,hq4!!#<Xz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_WaveBuilder_SaveSet1,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	Button button_WaveBuilder_SaveSet1,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	GroupBox group_load_set,pos={13.00,380.00},size={160.00,75.00},title="Loading"
	GroupBox group_load_set,userdata(ResizeControlsInfo)= A"!!,A^!!#C#!!#A/!!#?Oz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	GroupBox group_load_set,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	GroupBox group_load_set,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	DefineGuide UGH1={FT,237},UGV0={FL,187}
	SetWindow kwTopWin,hook(main)=WBP_MainWindowHook
	SetWindow kwTopWin,hook(ResizeControls)=ResizeControls#ResizeControlsHook
	SetWindow kwTopWin,userdata(ResizeControlsInfo)= A"!!*'\"z!!#E<!!#Cm^]4?7zzzzzzzzzzzzzzzzzzzz"
	SetWindow kwTopWin,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzzzzzzzzzzzzzzz"
	SetWindow kwTopWin,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzzzzzzzzz!!!"
	SetWindow kwTopWin,userdata(ResizeControlsGuides)=  "UGH1;UGV0;"
	SetWindow kwTopWin,userdata(ResizeControlsInfoUGH1)=  "NAME:UGH1;WIN:WaveBuilder;TYPE:User;HORIZONTAL:1;POSITION:237.00;GUIDE1:FT;GUIDE2:;RELPOSITION:237;"
	SetWindow kwTopWin,userdata(panelVersion)=  "7"
	SetWindow kwTopWin,userdata(ResizeControlsInfoUGV0)=  "NAME:UGV0;WIN:WaveBuilder;TYPE:User;HORIZONTAL:0;POSITION:187.00;GUIDE1:FL;GUIDE2:;RELPOSITION:187;"
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

	SetCheckBoxState(panel, "check_allow_saving_builtin_nam", CHECKBOX_UNSELECTED)

	WBP_LoadSet(NONE)

	if(WindowExists(AnalysisParamGUI))
		PGC_SetAndActivateControl(panel, "button_toggle_params")
	endif

	CallFunctionForEachListItem(WBP_AdjustDeltaControls, ControlNameList(panel, ";", "popup_WaveBuilder_op_*"))

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
	endif

	if(first == last)
		// don't try to highlight empty epochs
		return NaN
	endif

	SetScale/I x, first, last, "ms", waveBegin, waveEnd

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
		DoAbortNow("Wavebuilder panel is out of date. Please close and reopen it.")
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
		WBP_GetSweepColor(i, red, green, blue)
		ModifyGraph/W=$waveBuilderGraph rgb($trace) = (red, green, blue)
	endfor

	maxYValue = WaveMax(displayData)
	minYValue = WaveMin(displayData)

	if(maxYValue == minYValue)
		maxYValue = 1e-12
		minYValue = 1e-12
	endif

	epochHLBeginRight = maxYValue
	epochHLBeginLeft  = maxYValue

	epochHLEndRight   = min(0, minYValue)
	epochHLEndLeft    = min(0, minYValue)

	SetAxis/W=$waveBuilderGraph/A/E=3 left
	SetAxesRanges(waveBuilderGraph, ranges)
End

/// @brief Reponsible for adjusting controls which depend on other controls
///
/// Must be called before the changed settings are written into the parameter waves.
static Function WBP_UpdateDependentControls(checkBoxCtrl, checked)
	string checkBoxCtrl
	variable checked

	variable val

	switch(GetTabID(panel, "WBP_WaveType"))
		case EPOCH_TYPE_PULSE_TRAIN:
			if(!cmpstr(checkBoxCtrl,"check_SPT_Poisson_P44"))

				if(checked)
					WBP_UpdateControlAndWave("check_SPT_MixedFreq_P41", var = CHECKBOX_UNSELECTED)

					val = str2numsafe(GetUserData(panel, "check_SPT_NumPulses_P46", "old_state"))
					if(IsFinite(val))
						WBP_UpdateControlAndWave("check_SPT_NumPulses_P46", var = !!val)
					endif

					EnableControls(panel,"check_SPT_NumPulses_P46;SetVar_WaveBuilder_P6_FD01;SetVar_WaveBuilder_P7_DD01")
				endif

			elseif(!cmpstr(checkBoxCtrl,"check_SPT_MixedFreq_P41"))

				if(checked)
					WBP_UpdateControlAndWave("check_SPT_Poisson_P44", var = CHECKBOX_UNSELECTED)
					val = GetCheckBoxState(panel,"check_SPT_NumPulses_P46")
					SetControlUserData(panel, "check_SPT_NumPulses_P46", "old_state", num2str(val))
					WBP_UpdateControlAndWave("check_SPT_NumPulses_P46", var = CHECKBOX_SELECTED)
					DisableControls(panel,"check_SPT_NumPulses_P46;SetVar_WaveBuilder_P6_FD01;SetVar_WaveBuilder_P7_DD01")
				else
					EnableControls(panel,"check_SPT_NumPulses_P46;SetVar_WaveBuilder_P6_FD01;SetVar_WaveBuilder_P7_DD01")
				endif

			endif
			break
		default:
			// nothing to do
			break
	endswitch
End

static Function WBP_UpdatePanelIfAllowed()

	string controls
	variable lowPassCutOff, highPassCutOff, maxDuration, deltaMode

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
				EnableControls(panel, "SetVar_WaveBuilder_P24;SetVar_WaveBuilder_P25;SetVar_WB_DeltaMult_P65;popup_WaveBuilder_op_P81;setvar_explDeltaValues_T22")
			else
				DisableControls(panel, "SetVar_WaveBuilder_P24;SetVar_WaveBuilder_P25;SetVar_WB_DeltaMult_P65;popup_WaveBuilder_op_P81;setvar_explDeltaValues_T22")
			endif
			break
		case EPOCH_TYPE_PULSE_TRAIN:
			if(GetCheckBoxState(panel,"check_SPT_NumPulses_P46"))
				DisableControl(panel, "SetVar_WaveBuilder_P0")
				EnableControls(panel, "SetVar_WaveBuilder_P45;SetVar_WaveBuilder_P47;SetVar_WB_DeltaMult_P69;popup_WaveBuilder_op_P85;setvar_explDeltaValues_T26")
			else
				EnableControl(panel, "SetVar_WaveBuilder_P0")
				DisableControls(panel, "SetVar_WaveBuilder_P45;SetVar_WaveBuilder_P47;SetVar_WB_DeltaMult_P69;popup_WaveBuilder_op_P85;setvar_explDeltaValues_T26")
			endif

			if(GetCheckBoxState(panel,"check_SPT_Poisson_P44") || GetCheckBoxState(panel,"check_SPT_MixedFreqShuffle_P42"))
				EnableControls(panel, "check_NewSeedForEachSweep_P49_0;button_NewSeed_P48_0;check_UseEpochSeed_P39_0")
			else
				DisableControls(panel, "check_NewSeedForEachSweep_P49_0;button_NewSeed_P48_0;check_UseEpochSeed_P39_0")
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
End

/// @brief Passes the data from the WP wave to the panel
static Function WBP_ParameterWaveToPanel(stimulusType)
	variable stimulusType

	string list, control, data, customWaveName, allControls
	variable segment, numEntries, i, row

	WAVE WP    = GetWaveBuilderWaveParam()
	WAVE/T WPT = GetWaveBuilderWaveTextParam()

	segment = GetSetVariable(panel, "setvar_WaveBuilder_CurrentEpoch")
	allControls = ControlNameList(panel)

	list = GrepList(allControls, WP_CONTROL_REGEXP)

	numEntries = ItemsInList(list)
	for(i = 0; i < numEntries; i += 1)
		control = StringFromList(i, list)
		row = WBP_ExtractRowNumberFromControl(control)
		ASSERT(IsFinite(row), "Could not find row in: " + control)
		WBP_SetControl(panel, control, value = WP[row][segment][stimulusType])
	endfor

	list = GrepList(allControls, WPT_CONTROL_REGEXP)

	numEntries = ItemsInList(list)
	for(i = 0; i < numEntries; i += 1)
		control = StringFromList(i, list)
		row = WBP_ExtractRowNumberFromControl(control)
		ASSERT(IsFinite(row), "Could not find row in: " + control)

		if(GrepString(control, "^.*_ALL$"))
			data = WPT[row][%Set][INDEP_EPOCH_TYPE]
		else
			data = WPT[row][segment][stimulusType]
		endif

		data = WBP_TranslateControlContents(control, FROM_WAVE_TO_PANEL, data)
		SetSetVariableString(panel, control, data)
	endfor

	if(stimulusType == EPOCH_TYPE_CUSTOM)
		customWaveName = WPT[0][segment][EPOCH_TYPE_CUSTOM]
		WAVE/Z customWave = $customWaveName
		if(WaveExists(customWave))
			GroupBox group_WaveBuilder_FolderPath win=$panel, title=GetWavesDataFolder(customWave, 1)
			PopupMenu popup_WaveBuilder_ListOfWaves, win=$panel, popMatch=NameOfWave(customWave)
		endif
	elseif(stimulusType == EPOCH_TYPE_PULSE_TRAIN)
		WBP_UpdateDependentControls("check_SPT_Poisson_P44", GetCheckBoxState(panel, "check_SPT_Poisson_P44"))
		WBP_UpdateDependentControls("check_SPT_MixedFreq_P41", GetCheckBoxState(panel, "check_SPT_MixedFreq_P41"))
	endif
End

/// @brief Generic wrapper for setting a control's value
static Function WBP_SetControl(win, control, [value, str])
	string win, control
	variable value
	string str

	variable controlType

	ControlInfo/W=$win $control
	ASSERT(V_flag != 0, "Non-existing control or window")
	controlType = abs(V_flag)

	if(controlType == 1)
		// nothing to do
	elseif(controlType == 2)
		ASSERT(!ParamIsDefault(value), "Missing value parameter")
		CheckBox $control, win=$win, value=(value == CHECKBOX_SELECTED)
	elseif(controlType == 5)
		if(!ParamIsDefault(value))
			SetVariable $control, win=$win, value=_NUM:value
		elseif(!ParamIsDefault(str))
			SetVariable $control, win=$win, value=_STR:str
		else
			ASSERT(0, "Missing optional parameter")
		endif
	elseif(controlType == 3)
		ASSERT(!ParamIsDefault(value), "Missing value parameter")
		PopupMenu $control, win=$win, mode=value + 1
	else
		ASSERT(0, "Unsupported control type")
	endif
End

Function WBP_ButtonProc_DeleteSet(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	string DAorTTL, setWaveToDelete, panelTitle, lockedDevices
	string popupMenuSelectedItemsStart, popupMenuSelectedItemsEnd
	variable i, numPanels, channelType

	switch(ba.eventCode)
		case 2: // mouse up

			setWaveToDelete = GetPopupMenuString(panel, "popup_WaveBuilder_SetList")

			if(!CmpStr(SetWaveToDelete, NONE))
				print "Select a set to delete from popup menu."
				ControlWindowToFront()
				break
			endif

			lockedDevices = GetListOfLockedDevices()
			if(!IsEmpty(lockedDevices))
				numPanels = ItemsInList(lockedDevices)
				for(i = 0; i < numPanels; i += 1)
					panelTitle = StringFromList(i, lockedDevices)
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

			WBP_UpdateDependentControls(cba.ctrlName, cba.checked)
			WBP_UpdateControlAndWave(cba.ctrlName, var = cba.checked)
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
	ASSERT(IsValidEpochNumber(idx), "Invalid number of epochs")
	SegWvType[idx] = tabnum

	WBP_ParameterWaveToPanel(tabnum)
	WBP_UpdatePanelIfAllowed()
	return 0
End

/// @brief Additional `finalhook` called in `ACL_DisplayTab`
Function WBP_FinalTabHook(tca)
	STRUCT WMTabControlAction &tca

	if(tca.tab != EPOCH_TYPE_PULSE_TRAIN)
		EnableControl(panel, "SetVar_WaveBuilder_P0")
	endif

	ShowControls(tca.win, "SetVar_WaveBuilder_P0;SetVar_WaveBuilder_P1;SetVar_WaveBuilder_P2;SetVar_WaveBuilder_P3;SetVar_WB_DurDeltaMult_P52;SetVar_WB_AmpDeltaMult_P50;popup_WaveBuilder_op_P70;popup_WaveBuilder_op_P71;popup_WaveBuilder_op_P72;setvar_explDeltaValues_T11;setvar_explDeltaValues_T12_DD02;setvar_explDeltaValues_T13")

	switch(tca.tab)
		case EPOCH_TYPE_CUSTOM:
			HideControls(tca.win, "SetVar_WaveBuilder_P0;SetVar_WaveBuilder_P1;SetVar_WaveBuilder_P2;SetVar_WaveBuilder_P3;SetVar_WB_DurDeltaMult_P52;SetVar_WB_AmpDeltaMult_P50;popup_WaveBuilder_op_P70;popup_WaveBuilder_op_P71;popup_WaveBuilder_op_P72;setvar_explDeltaValues_T11;setvar_explDeltaValues_T12_DD02;setvar_explDeltaValues_T13")
			break
		case EPOCH_TYPE_COMBINE:
			HideControls(tca.win, "SetVar_WaveBuilder_P0;SetVar_WaveBuilder_P1;SetVar_WaveBuilder_P2;SetVar_WaveBuilder_P3;SetVar_WB_DurDeltaMult_P52;SetVar_WB_AmpDeltaMult_P50;popup_WaveBuilder_op_P70;popup_WaveBuilder_op_P71;popup_WaveBuilder_op_P72;setvar_explDeltaValues_T11;setvar_explDeltaValues_T12_DD02;setvar_explDeltaValues_T13")
			break
		case EPOCH_TYPE_SQUARE_PULSE:
			HideControls(tca.win, "popup_WaveBuilder_op_P71;setvar_explDeltaValues_T12_DD02;")
			break
	endswitch

	CallFunctionForEachListItem(WBP_AdjustDeltaControls, ControlNameList(panel, ";", "popup_WaveBuilder_op_*"))

	return 0
End

Function WBP_ButtonProc_SaveSet(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	string setName

	switch(ba.eventCode)
		case 2: // mouse up
			setName = WBP_AssembleSetName()

			if(WBP_IsBuiltinStimset(setName) && !GetCheckBoxState(panel, "check_allow_saving_builtin_nam"))
				printf "The stimset %s can not be saved as it violates the naming scheme "       + \
					   "for user stimsets. Check the checkbox above if you really want to save " + \
					   "a builtin stimset.\r", setName
				ControlWindowToFront()
				break
			endif

			WBP_SaveSetParam(setName)

			// propagate the existence of the new set
			WBP_UpdateITCPanelPopUps()
			WB_UpdateEpochCombineList(WBP_GetOutputType())

			WAVE/Z stimset = WB_CreateAndGetStimSet(setName)
			ASSERT(WaveExists(stimset), "Could not recreate stimset")

			SetSetVariableString(panel, "setvar_WaveBuilder_baseName", DEFAULT_SET_PREFIX)
			WBP_LoadSet(NONE)
			break
	endswitch
End

static Function WBP_GetWaveTypeFromControl(control)
	string control

	if(GrepString(control, WP_CONTROL_REGEXP))
		return WBP_WAVETYPE_WP
	elseif(GrepString(control, SEGWVTYPE_CONTROL_REGEXP))
		return WBP_WAVETYPE_SEGWVTYPE
	elseif(GrepString(control, WPT_CONTROL_REGEXP))
		return WBP_WAVETYPE_WPT
	else
		return NaN
	endif
End

/// @brief Returns the row index into the parameter wave of the parameter represented by the named control
///
/// @param control name of the control, the expected format is `$str_$sep$row_$suffix` where `$str` may contain any
/// characters but `$suffix` is not allowed to include the substring `_$sep`.
///
/// All entries are per epoch type and per epoch number except when the `$suffix` is `ALL`
/// which denotes that it is a setting for the full stimset.
static Function WBP_ExtractRowNumberFromControl(control)
	string control

	variable start, stop, row
	string sep

	switch(WBP_GetWaveTypeFromControl(control))
		case WBP_WAVETYPE_WP:
			sep = "P"
			break
		case WBP_WAVETYPE_WPT:
			sep = "T"
			break
		case WBP_WAVETYPE_SEGWVTYPE:
			sep = "S"
			break
		default:
			return NaN
			break
	endswitch

	start = strsearch(control, "_" + sep, Inf, 1)
	stop  = strsearch(control, "_", start + 2)

	if(stop == -1)
		stop = Inf
	endif

	row = str2num(control[start + 2,stop - 1])
	ASSERT(IsFinite(row), "Non finite row")

	return row
End

/// @brief Update the named control and pass its new value into the parameter wave
Function WBP_UpdateControlAndWave(control, [var, str])
	string control
	variable var
	string str

	variable stimulusType, epoch, paramRow

	ASSERT(ParamIsDefault(var) + ParamIsDefault(str) == 1, "Exactly one of var/str must be given")

	if(!ParamIsDefault(var))
		WBP_SetControl(panel, control, value = var)
	elseif(!ParamIsDefault(str))
		WBP_SetControl(panel, control, str = str)
	endif

	stimulusType = GetTabID(panel, "WBP_WaveType")
	epoch        = GetSetVariable(panel, "setvar_WaveBuilder_CurrentEpoch")
	paramRow     = WBP_ExtractRowNumberFromControl(control)
	ASSERT(IsFinite(paramRow), "Could not find row in: " + control)

	switch(WBP_GetWaveTypeFromControl(control))
		case WBP_WAVETYPE_WP:
			WAVE WP = GetWaveBuilderWaveParam()
			WP[paramRow][epoch][stimulusType] = var
			break
		case WBP_WAVETYPE_WPT:
			WAVE/T WPT = GetWaveBuilderWaveTextParam()

			if(GrepString(control, "^.*_ALL$"))
				WPT[paramRow][%Set][INDEP_EPOCH_TYPE] = str
			else
				WPT[paramRow][epoch][stimulusType] = str
			endif

			break
		case WBP_WAVETYPE_SEGWVTYPE:
			WAVE SegWvType = GetSegmentTypeWave()
			SegWvType[paramRow] = var
			break
	endswitch
End

Function WBP_SetVarProc_UpdateParam(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	switch(sva.eventCode)
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update

			if(sva.isStr)
				WBP_UpdateControlAndWave(sva.ctrlName, str = sva.sval)
			else
				WBP_UpdateControlAndWave(sva.ctrlName, var = sva.dval)
			endif

			if(!cmpstr(sva.ctrlName, "SetVar_WB_NumEpochs_S100"))
				WBP_UpdateEpochControls()
			endif

			WBP_UpdatePanelIfAllowed()
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

static Function WBP_ChangeWaveType()

	variable stimulusType
	string list

	WAVE SegWvType = GetSegmentTypeWave()
	WAVE WP = GetWaveBuilderWaveParam()

	list  = "SetVar_WaveBuilder_P3;SetVar_WaveBuilder_P4;SetVar_WaveBuilder_P5;"
	list += "SetVar_WaveBuilder_P4_OD00;SetVar_WaveBuilder_P4_OD01;SetVar_WaveBuilder_P4_OD02;SetVar_WaveBuilder_P4_OD03;SetVar_WaveBuilder_P4_OD04;"
	list += "SetVar_WaveBuilder_P5_DD02;SetVar_WaveBuilder_P5_DD03;SetVar_WaveBuilder_P5_DD04;SetVar_WaveBuilder_P5_DD05;SetVar_WaveBuilder_P5_DD06;"
	list += "popup_af_generic_S9;button_af_jump_to_proc"

	stimulusType = WBP_GetStimulusType()

	if(stimulusType == STIMULUS_TYPE_TLL)
		// recreate SegWvType with its defaults
		KillOrMoveToTrash(wv=GetSegmentTypeWave())

		WP[1,6][][] = 0

		SetVariable SetVar_WaveBuilder_P2 win = $panel, limits = {0,1,1}
		DisableControls(panel, list)

		WBP_UpdateControlAndWave("SetVar_WaveBuilder_P2", var = 0)
		WBP_UpdateControlAndWave("SetVar_WaveBuilder_P3", var = 0)
		WBP_UpdateControlAndWave("SetVar_WaveBuilder_P4", var = 0)
		WBP_UpdateControlAndWave("SetVar_WaveBuilder_P5", var = 0)
	elseif(stimulusType == STIMULUS_TYPE_DA)
		SetVariable SetVar_WaveBuilder_P2 win =$panel, limits = {-inf,inf,1}
		EnableControls(panel, list)
	else
		ASSERT(0, "Unknown stimulus type")
	endif

	WBP_UpdatePanelIfAllowed()
End

static Function WBP_GetStimulusType()

	strswitch(GetPopupMenuString(panel, "popup_WaveBuilder_OutputType"))
		case "TTL":
			return STIMULUS_TYPE_TLL
			break
		case "DA":
			return STIMULUS_TYPE_DA
			break
		default:
			ASSERT(0, "unknown stimulus type")
			break
	endswitch
End

Function WBP_PopMenuProc_WaveType(pa) : PopupMenuControl
	STRUCT WMPopupAction& pa

	switch(pa.eventCode)
		case 2:
			WBP_ChangeWaveType()
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
				WPT[0][SegmentNo][EPOCH_TYPE_CUSTOM] = GetWavesDataFolder(customWave, 2)
			else
				WPT[0][SegmentNo][EPOCH_TYPE_CUSTOM] = ""
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

/// @brief Return a sorted list of all stim sets created by the wavebuilder
Function/S WBP_ReturnListSavedSets()

	string list = ""

	DFREF dfr = GetSetParamFolder(CHANNEL_TYPE_DAC)
	list += GetListOfObjects(dfr, "WP_.*")

	DFREF dfr = GetSetParamFolder(CHANNEL_TYPE_TTL)
	list += GetListOfObjects(dfr, "WP_.*")

	return NONE + ";" + SortList(RemovePrefixFromListItem("WP_", list), ";", 16)
end

/// @brief Return true if the given stimset is a builtin, false otherwise
Function WBP_IsBuiltinStimset(setName)
	string setName

	return GrepString(setName, "^MIES_.*")
End

/// @brief Save the set parameter waves
static Function WBP_SaveSetParam(setName)
	string setName

	string childStimsets
	variable i

	WAVE SegWvType = GetSegmentTypeWave()
	WAVE WP        = GetWaveBuilderWaveParam()
	WAVE WPT       = GetWaveBuilderWaveTextParam()

	DFREF dfr = GetSetParamFolder(WBP_GetOutputType())

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

		PGC_SetAndActivateControl(panel, "popup_WaveBuilder_OutputType", val = channelType)

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

		KillOrMoveToTrash(wv=GetSegmentTypeWave())
		KillOrMoveToTrash(wv=GetWaveBuilderWaveParam())
		KillOrMoveToTrash(wv=GetWaveBuilderWaveTextParam())

		PGC_SetAndActivateControl(panel, "popup_WaveBuilder_OutputType", val = channelType)
	endif

	// fetch wave references, possibly updating the wave layout if required
	WAVE WP        = GetWaveBuilderWaveParam()
	WAVE/T WPT     = GetWaveBuilderWaveTextParam()
	WAVE SegWvType = GetSegmentTypeWave()

	SetPopupMenuIndex(panel, "popup_WaveBuilder_op_S94", SegWvType[94])
	SetSetVariable(panel, "SetVar_WB_Multiplier_S95", SegWvType[95])
	SetSetVariable(panel, "SetVar_WaveBuilder_S96", SegWvType[96])
	SetCheckBoxState(panel, "check_FlipEpoch_S98", SegWvType[98])
	SetSetVariable(panel, "SetVar_WaveBuilder_S99", SegWvType[99])
	SetSetVariable(panel, "SetVar_WB_NumEpochs_S100", SegWvType[100])
	SetSetVariable(panel, "SetVar_WB_SweepCount_S101", SegWvType[101])
	SetSetVariable(panel, "setvar_WaveBuilder_CurrentEpoch", 0)

	SetSetVariableString(panel, "setvar_WaveBuilder_baseName", setPrefix)
	SetSetVariable(panel, "setvar_WaveBuilder_SetNumber", setNumber)

	funcList = WBP_GetAnalysisFunctions_V3()
	SetAnalysisFunctionIfFuncExists(panel, "popup_af_generic_S9", setName, funcList, WPT[9][%Set][INDEP_EPOCH_TYPE])
	WBP_AnaFuncsToWPT()

	ASSERT(IsValidEpochNumber(SegWvType[100]), "Invalid number of epochs")

	WBP_UpdateEpochControls()
	PGC_SetAndActivateControl(panel, "setvar_WaveBuilder_CurrentEpoch", val = 0)

	// reset old state of checkbox and update panel
	SetCheckBoxState(panel, "check_PreventUpdate", preventUpdate)
	WBP_UpdatePanelIfAllowed()

	if(WindowExists(AnalysisParamGUI))
		Wave/T listWave = WBP_GetAnalysisParamGUIListWave()

		if(DimSize(listWave, ROWS) == 0)
			PGC_SetAndActivateControl(AnalysisParamGUI, "setvar_param_name", str = "")
			PGC_SetAndActivateControl(AnalysisParamGUI, "setvar_param_value", str = "")
		endif
	endif
End

static Function SetAnalysisFunctionIfFuncExists(win, ctrl, stimset, funcList, func)
	string win, ctrl, stimset, funcList, func

	string entry

	if(IsEmpty(func))
		entry = NONE
	else
		if(WhichListItem(func, funcList) != -1)
			entry = func
		else
			printf "The analysis function \"%s\" referenced in the stimset \"%s\" could not be found.\r", func, stimset
			ControlWindowToFront()
			entry = NONE
		endif
	endif

	SetPopupMenuString(win, ctrl, entry)
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
		PGC_SetAndActivateControl(panel, "setvar_WaveBuilder_CurrentEpoch", val = numEpochs - 1)
	else
		WBP_UpdatePanelIfAllowed()
	endif
End

Function WBP_SetVarProc_EpochToEdit(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	switch(sva.eventCode)
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			WAVE SegWvType = GetSegmentTypeWave()
			PGC_SetAndActivateControl(panel, "WBP_WaveType", val = SegWvType[sva.dval])
			break
	endswitch
End

Function WBP_PopupMenu_LoadSet(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	string setName

	switch(pa.eventCode)
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

	if(HighPassCutOff >= LowPassCutOff)
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

	DFREF dfr = WBP_GetFolderPath()

	return NONE + ";root:;..;" + GetListOfObjects(dfr, ".*", typeFlag = COUNTOBJECTS_DATAFOLDER)
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
		listOfPanels = GetListOfLockedDevices()

		if(isEmpty(listOfPanels))
			return NaN
		endif
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

		DAP_UpdateDAQControls(panelTitle, REASON_STIMSET_CHANGE)
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
			WBP_UpdateControlAndWave(pa.ctrlName, var = pa.popNum - 1)
			WBP_UpdatePanelIfAllowed()
			if(StringMatch(pa.ctrlName, "popup_WaveBuilder_op_*"))
				WBP_AdjustDeltaControls(pa.ctrlName)
			endif
			break
	endswitch

	return 0
End

/// @brief Convert from the row index of a delta related control to a list of control names
static Function/S WBP_ConvertDeltaLblToCtrlNames(allControls, dimLabel)
	string allControls
	string dimLabel

	variable index

	WAVE WP  = GetWaveBuilderWaveParam()
	WAVE WPT = GetWaveBuilderWaveTextParam()
	WAVE SegWvType = GetSegmentTypeWave()

	index = FindDimLabel(WP, ROWS, dimLabel)
	if(index >= 0)
		return GrepList(allControls, ".*_P" + num2str(index) + "(_|$)")
	endif

	index = FindDimLabel(WPT, ROWS, dimLabel)
	if(index >= 0)
		return GrepList(allControls, ".*_T" + num2str(index) + "(_|$)")
	endif

	index = FindDimLabel(SegWvType, ROWS, dimLabel)
	if(index >= 0)
		return GrepList(allControls, ".*_S" + num2str(index) + "(_|$)")
	endif

	ASSERT(0, "Invalid dimLabel")
End

/// @brief Depending on the delta operation the visibility of related controls
/// is adjusted.
///
/// @param control delta operation control name
static Function WBP_AdjustDeltaControls(control)
	string control

	variable deltaMode, index, row
	string allControls, op, delta, dme, ldelta
	string lbl

	row = WBP_ExtractRowNumberFromControl(control)

	switch(WBP_GetWaveTypeFromControl(control))
		case WBP_WAVETYPE_WP:
			WAVE loc = GetWaveBuilderWaveParam()
			break
		case WBP_WAVETYPE_SEGWVTYPE:
			WAVE loc = GetSegmentTypeWave()
			break
		default:
			ASSERT(0, "Invalid control type")
	endswitch

	lbl   = GetDimLabel(loc, ROWS, row)
	lbl   = RemoveEnding(lbl, " op")
	index = FindDimLabel(loc, ROWS, lbl)

	if(index < 0)
		return NaN
	endif

	STRUCT DeltaControlNames s
	WB_GetDeltaDimLabel(loc, index, s)

	allControls = ControlNameList(panel)

	op     = WBP_ConvertDeltaLblToCtrlNames(allControls, s.op)
	delta  = WBP_ConvertDeltaLblToCtrlNames(allControls, s.delta)
	dme    = WBP_ConvertDeltaLblToCtrlNames(allControls, s.dme)
	ldelta = WBP_ConvertDeltaLblToCtrlNames(allControls, s.ldelta)

	deltaMode = GetPopupMenuIndex(panel, control)
	switch(deltaMode)
		case DELTA_OPERATION_DEFAULT:
			EnableControls(panel, delta)
			DisableControls(panel, dme)
			DisableControls(panel, ldelta)
			break
		case DELTA_OPERATION_FACTOR:
			EnableControls(panel, delta)
			EnableControls(panel, dme)
			DisableControls(panel, ldelta)
			break
		case DELTA_OPERATION_LOG:
			EnableControls(panel, delta)
			DisableControls(panel, dme)
			DisableControls(panel, ldelta)
			break
		case DELTA_OPERATION_SQUARED:
			EnableControls(panel, delta)
			DisableControls(panel, dme)
			DisableControls(panel, ldelta)
			break
		case DELTA_OPERATION_POWER:
			EnableControls(panel, delta)
			EnableControls(panel, dme)
			DisableControls(panel, ldelta)
			break
		case DELTA_OPERATION_ALTERNATE:
			EnableControls(panel, delta)
			DisableControls(panel, dme)
			DisableControls(panel, ldelta)
			break
		case DELTA_OPERATION_EXPLICIT:
			DisableControls(panel, delta)
			DisableControls(panel, dme)
			EnableControls(panel, ldelta)
			break
		default:
			ASSERT(0, "Unknown delta mode")
	endswitch
End

Function WBP_ButtonProc_NewSeed(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch(ba.eventCode)
		case 2: // mouse up
			NewRandomSeed()
			WBP_UpdateControlAndWave(ba.ctrlName, var = GetReproducibleRandom())
			WBP_UpdatePanelIfAllowed()
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

static Function WBP_AnaFuncsToWPT()

	string func

	if(WBP_GetStimulusType() == STIMULUS_TYPE_TLL)
		// don't store analysis functions for TTL
		return NaN
	endif

	WAVE/T WPT = GetWaveBuilderWaveTextParam()

	func = GetPopupMenuString(panel, "popup_af_generic_S9")
	WPT[9][%Set][INDEP_EPOCH_TYPE] = SelectString(cmpstr(func, NONE), "", func)

	// clear deprecated entries for single analysis function events
	if(cmpstr(func, NONE))
		WPT[1, 5][%Set][INDEP_EPOCH_TYPE] = ""
		WPT[8][%Set][INDEP_EPOCH_TYPE]    = ""
		WPT[27][%Set][INDEP_EPOCH_TYPE]   = ""
	endif

	WBP_UpdateParameterWave()
End

/// Wrapper functions to be used in GUI recreation macros
/// This avoids having to hardcode the parameter values.
/// @{
Function/S WBP_GetAnalysisFunctions_V3()
	return WBP_GetAnalysisFunctions(ANALYSIS_FUNCTION_VERSION_V3)
End
/// @}

/// @brief Return a list of analysis functions including NONE, usable for popup menues
///
/// @sa AFM_GetAnalysisFunctions
Function/S WBP_GetAnalysisFunctions(versionBitMask)
	variable versionBitMask

	return AddListItem(NONE, AFH_GetAnalysisFunctions(versionBitMask))
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

			if(TP_GetNumDevicesWithTPRunning() > 0)
				printf "The analysis function procedure window can not be opened when the testpulse is running.\n"
				ControlWindowToFront()
				break
			endif

			baseName = "UserAnalysisFunctions"
			fileName = baseName + ".ipf"
			userFile = GetFolder(FunctionPath("")) + fileName
			GetFileFolderInfo/Q/Z userFile
			if(V_Flag) // create a default file
				Open refNum as userFile

				fprintf refNum, "#pragma rtGlobals=3 // Use modern global access method and strict wave access.\n"
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

			WPT[6][currentEpoch][EPOCH_TYPE_COMBINE] = WBP_TranslateControlContents(sva.ctrlName, FROM_PANEL_TO_WAVE, formula)
			WPT[7][currentEpoch][EPOCH_TYPE_COMBINE] = WAVEBUILDER_COMBINE_FORMULA_VER

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
		case 2:
			KillOrMoveToTrash(dfr = GetWaveBuilderDataPath())
			break
#ifdef DEBUGGING_ENABLED
		case 4:
			string controls, ctrl, name
			variable row, found

			if(DP_DebuggingEnabledForFile(GetFile(FunctionPath(""))))
				controls = ControlNameList(s.winName)
				numEntries = ItemsInList(controls)
				for(i = 0; i < numEntries; i += 1)
					ctrl = StringFromList(i, controls)
					ControlInfo/W=$s.winName $ctrl

					if(V_disable & HIDDEN_CONTROL_BIT)
						continue
					endif

					if(!cmpstr(ctrl, "WBP_WaveType"))
						continue
					endif

					if(s.mouseLoc.h >= V_left && s.mouseLoc.h <= V_left + V_width)
						if(s.mouseLoc.v >= V_top && s.mouseLoc.v <= V_top + V_Height)

							row = WBP_ExtractRowNumberFromControl(ctrl)

							switch(WBP_GetWaveTypeFromControl(ctrl))
								case WBP_WAVETYPE_WP:
									WAVE WP = GetWaveBuilderWaveParam()
									name = GetDimLabel(WP, ROWS, row)
									break
								case WBP_WAVETYPE_WPT:
									WAVE/T WPT = GetWaveBuilderWaveTextParam()
									name = GetDimLabel(WPT, ROWS, row)
									break
								case WBP_WAVETYPE_SEGWVTYPE:
									WAVE SegWvType = GetSegmentTypeWave()
									name = GetDimLabel(SegWvType, ROWS, row)
									break
								default:
									name = "unknown type"
									break
							endswitch

							printf "%s -> %s\r", ctrl, 	name
						endif
					endif
				endfor
			endif
			break
#endif
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

				PGC_SetAndActivateControl(panel, "setvar_WaveBuilder_CurrentEpoch", val = i)
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
	SetScale/P x 0, WAVEBUILDER_MIN_SAMPINT/1000, "s", input
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

	WBP_GetSweepColor(sweep, red, green, blue)
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
static Function WBP_GetSweepColor(sweep, red, green, blue)
	variable sweep, &red, &green, &blue

	return GetTraceColor(20 - mod(sweep, 20), red, green, blue)
End

/// @brief Add an analysis function parameter to the given stimset
///
/// This function adds the parameter to the `WPT` wave and checks that it is valid.
///
/// Exactly one of `var`/`str`/`wv` must be given.
///
/// @param stimset stimset name
/// @param name    name of the parameter
/// @param var     [optional] numeric parameter
/// @param str     [optional] string parameter
/// @param wv      [optional] wave parameter can be numeric or text
Function WBP_AddAnalysisParameter(stimset, name, [var, str, wv])
	string stimset, name
	variable var
	string str
	WAVE wv

	WAVE/T/Z WPT = WB_GetWaveTextParamForSet(stimset)
	ASSERT(WaveExists(WPT), "Missing stimset")

	ASSERT(ParamIsDefault(var) + ParamIsDefault(str) + ParamIsDefault(wv) == 2, "Expected one of var, str or wv")

	if(!ParamIsDefault(var))
		return WBP_AddAnalysisParameterIntoWPT(WPT, name, var = var)
	elseif(!ParamIsDefault(str))
		return WBP_AddAnalysisParameterIntoWPT(WPT, name, str = str)
	elseif(!ParamIsDefault(wv))
		return WBP_AddAnalysisParameterIntoWPT(WPT, name, wv = wv)
	endif
End

static Function WBP_AddAnalysisParameterIntoWPT(WPT, name, [var, str, wv])
	WAVE/T WPT
	string name
	variable var
	string str
	WAVE wv

	string type, value, formattedString, params

	ASSERT(ParamIsDefault(var) + ParamIsDefault(str) + ParamIsDefault(wv) == 2, "Expected one of var, str or wv")

	if(!ParamIsDefault(var))
		type = "variable"
		value = num2str(var)
	elseif(!ParamIsDefault(str))
		type = "string"
		value = str
	elseif(!ParamIsDefault(wv))
		ASSERT(DimSize(wv, ROWS) > 0, "Expected non-empty wave")
		if(IsTextWave(wv))
			type  = "textwave"
			FindValue/TEXT="|" wv
			ASSERT(V_Value == -1, "textwave can not hold \"|\" character")
			value = TextWaveToList(wv, "|")
		else
			type = "wave"
			value = NumericWaveToList(wv, "|", format = "%.15g")
		endif
	endif

	ASSERT(AFH_IsValidAnalysisParameter(name), "Name is not a legal non-liberal igor object name")
	ASSERT(!GrepString(value, "[=:,;]+"), "Written entry contains invalid characters (one of `=:,;`)")
	ASSERT(AFH_IsValidAnalysisParamType(type), "Invalid type")

	params = WPT[10][%Set][INDEP_EPOCH_TYPE]

	if(WhichListItem(name, AFH_GetListOfAnalysisParamNames(params)) != -1)
		printf "Parameter \"%s\" is already present and will be overwritten!\r", name
	endif

	WPT[10][%Set][INDEP_EPOCH_TYPE] = ReplaceStringByKey(name, params , type + "=" + value, ":", ",", 0)
End


/// @brief Delete the given analysis parameter
///
/// @param name    name of the parameter
static Function WBP_DeleteAnalysisParameter(name)
	string name

	string params

	WAVE/T WPT = GetWaveBuilderWaveTextParam()

	params = WPT[%$"Analysis function params"][%Set][INDEP_EPOCH_TYPE]
	params = AFH_RemoveAnalysisParameter(name, params)
	WPT[%$"Analysis function params"][%Set][INDEP_EPOCH_TYPE] = params
End

/// @brief Return a list of all possible analysis parameter types
Function/S WBP_GetParameterTypes()

	return ANALYSIS_FUNCTION_PARAMS_TYPES
End

/// @brief Return the analysis parameters
Function/S WBP_GetAnalysisParameters()

	WAVE/T WPT = GetWaveBuilderWaveTextParam()

	return WPT[%$"Analysis function params"][%Set][INDEP_EPOCH_TYPE]
End

/// @brief Return the analysis parameter names for the currently
///        selected stimset
Function/S WBP_GetAnalysisParameterNames()

	string params = WBP_GetAnalysisParameters()

	if(IsEmpty(params))
		return NONE
	endif

	return NONE + ";" + AFH_GetListOfAnalysisParamNames(params)
End

/// @brief Fill the listwave from the stimset analysis
///        parameters extracted from its WPT
static Function WBP_UpdateParameterWave()

	string params, names, name, type, genericFunc, suggParams
	string missingParams, suggNames, reqNames
	variable i, numEntries, offset

	Wave/T listWave = WBP_GetAnalysisParamGUIListWave()
	WAVE   selWave  = WBP_GetAnalysisParamGUISelWave()

	WAVE/T WPT = GetWaveBuilderWaveTextParam()

	genericFunc = WPT[%$("Analysis function (generic)")][%Set][INDEP_EPOCH_TYPE]

	suggParams = AFH_GetListOfAnalysisParams(genericFunc, REQUIRED_PARAMS | OPTIONAL_PARAMS)
	suggNames = AFH_GetListOfAnalysisParamNames(suggParams)

	reqNames = AFH_GetListOfAnalysisParamNames(AFH_GetListOfAnalysisParams(genericFunc, REQUIRED_PARAMS))

	params = WBP_GetAnalysisParameters()
	names  = AFH_GetListOfAnalysisParamNames(params)

	numEntries = ItemsInList(names)
	Redimension/N=(numEntries, -1) listWave, selWave

	for(i = 0; i < numEntries; i += 1)
		name = StringFromList(i, names)
		listWave[i][%Name]  = name
		listWave[i][%Type]  = AFH_GetAnalysisParamType(name, params)
		listWave[i][%Value] = AFH_GetAnalysisParameter(name, params)
	endfor

	offset = DimSize(listWave, ROWS)

	missingParams = GetListDifference(suggNames, names)
	numEntries = ItemsInList(missingParams)
	Redimension/N=(offset + numEntries, -1) listWave, selWave

	for(i = 0; i < numEntries; i += 1)
		name = StringFromList(i, missingParams)
		listWave[offset + i][%Name]     = name
		listWave[offset + i][%Type]     = AFH_GetAnalysisParamType(name, suggParams, typeCheck = 0)
		listWave[offset + i][%Required] = ToTrueFalse(WhichListItem(name, reqNames) != -1)
	endfor
End

/// @brief Toggle the analysis parameter GUI
///
/// @return one if the panel was killed, zero if it was created
static Function WBP_ToggleAnalysisParamGUI()

	if(WindowExists(AnalysisParamGUI))
		KillWindow $AnalysisParamGUI
		return 1
	endif

	Wave/T listWave = WBP_GetAnalysisParamGUIListWave()
	WAVE   selWave  = WBP_GetAnalysisParamGUISelWave()

	NewPanel/EXT=2/HOST=WaveBuilder/N=AnalysisParamGUI/W=(0,0,670,200)/K=2 as " "
	GroupBox group_main,pos={36.00,19.00},size={135.00,113.00},win=AnalysisParamGUI
	Button button_delete_parameter,pos={73.00,139.00},size={60.00,25.00},proc=WBP_ButtonProc_DeleteParam,title="Delete",win=AnalysisParamGUI
	Button button_delete_parameter,win=AnalysisParamGUI,help={"Delete the selected parameter"}
	Button button_add_parameter,pos={73.00,99.00},size={60.00,25.00},proc=WBP_ButtonProc_AddParam,title="Add",win=AnalysisParamGUI
	Button button_add_parameter,win=AnalysisParamGUI,help={"Add the parameter with type and value to the stimset"}
	PopupMenu popup_param_types,pos={45.00,52.00},size={102.00,19.00},bodyWidth=70,title="Type:",win=AnalysisParamGUI
	PopupMenu popup_param_types,mode=1,popvalue="variable",value= #"WBP_GetParameterTypes()",win=AnalysisParamGUI
	PopupMenu popup_param_types,help={"Choose the parameter type"},win=AnalysisParamGUI
	SetVariable setvar_param_value,pos={43.00,76.00},size={120.00,18.00},bodyWidth=120,win=AnalysisParamGUI
	SetVariable setvar_param_value,limits={-inf,inf,0},value= _STR:"",win=AnalysisParamGUI
	SetVariable setvar_param_value,help={"Input the parameter value as string. For wave/textwave entries separate the entries with \";\""},win=AnalysisParamGUI
	SetVariable setvar_param_name,pos={43.00,27.00},size={120.00,18.00},bodyWidth=120,value= _STR:"",win=AnalysisParamGUI
	SetVariable setvar_param_name,help={"The parameter name"}
	ListBox list_params,pos={174.00,19.00},size={453.00,175.00},win=AnalysisParamGUI
	ListBox list_params,listWave=listWave,win=AnalysisParamGUI
	ListBox list_params,selWave=selWave,mode=4,proc=WBP_ListBoxProc_AnalysisParams,win=AnalysisParamGUI
	ListBox list_params widths={25,15,50,13},win=AnalysisParamGUI,help={"Visualization of all parameters with types and values"}

	WBP_UpdateParameterWave()

	return 0
End

Function WBP_ButtonProc_DeleteParam(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	variable numEntries, i

	switch(ba.eventCode)
		case 2: // mouse up
			Wave/T listWave = WBP_GetAnalysisParamGUIListWave()
			WAVE selWave    = WBP_GetAnalysisParamGUISelWave()

			WAVE/Z indizes = FindIndizes(selWave, var = LISTBOX_SELECTED, col = 0, prop = PROP_MATCHES_VAR_BIT_MASK)
			if(!WaveExists(indizes))
				break
			endif

			numEntries = DimSize(indizes, ROWS)

			// map to names which are stable even after deletion
			Make/T/FREE/N=(numEntries) names = listWave[indizes[p]][%Name]

			for(i = 0; i < numEntries; i += 1)
				WBP_DeleteAnalysisParameter(names[i])
			endfor

			WBP_UpdateParameterWave()
			break
	endswitch

	return 0
End

Function WBP_ButtonProc_AddParam(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	string win, name, type
	string value

	switch(ba.eventCode)
		case 2: // mouse up
			win  = ba.win
			name = GetSetVariableString(win, "setvar_param_name")
			if(!AFH_IsValidAnalysisParameter(name))
				printf "The parameter name \"%s\" is not valid.\r", name
				ControlWindowToFront()
				break
			endif

			WAVE/T WPT = GetWaveBuilderWaveTextParam()
			type       = GetPopupMenuString(win, "popup_param_types")
			value      = GetSetVariableString(win, "setvar_param_value")

			strswitch(type)
				case "variable":
					WBP_AddAnalysisParameterIntoWPT(WPT, name, var = str2numSafe(value))
					break
				case "string":
					WBP_AddAnalysisParameterIntoWPT(WPT, name, str = value)
					break
				case "wave":
					WBP_AddAnalysisParameterIntoWPT(WPT, name, wv = ListToNumericWave(value, ";"))
					break
				case "textwave":
					WBP_AddAnalysisParameterIntoWPT(WPT, name, wv = ListToTextWave(value, ";"))
					break
				default:
					ASSERT(0, "invalid type")
					break
			endswitch

			WBP_UpdateParameterWave()
			SetSetVariableString(win, "setvar_param_name", "")
			SetSetVariableString(win, "setvar_param_value", "")
			break
	endswitch

	return 0
End

Function WBP_ButtonProc_OpenAnaParamGUI(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch(ba.eventCode)
		case 2: // mouse up
			if(WBP_ToggleAnalysisParamGUI())
				SetControlTitle(panel, "button_toggle_params","Open parameters panel")
			else
				SetControlTitle(panel, "button_toggle_params","Close parameters panel")
			endif
			break
	endswitch

	return 0
End

Function WBP_ListBoxProc_AnalysisParams(lba) : ListBoxControl
	STRUCT WMListboxAction &lba

	variable numericValue
	string stimset, win, name, value, params
	string type
	variable row, col

	switch(lba.eventCode)
		case 1: // mouse down
		case 3: // double click
		case 4: // cell selection
		case 5: // cell selection plus shift key

			win = lba.win
			row = lba.row
			col = lba.col
			WAVE/T/Z listWave = lba.listWave
			WAVE/Z selWave = lba.selWave

			if(row < 0 || row >= DimSize(listWave, ROWS))
				break
			endif

			params = WBP_GetAnalysisParameters()
			name   = listWave[row][%Name]

			value = listWave[row][%Value]
			type  = listWave[row][%Type]
			if(!IsEmpty(type))
				strswitch(type)
					case "variable":
						numericValue = AFH_GetAnalysisParamNumerical(name, params)
						if(!IsNan(numericValue))
							value = num2str(numericValue)
						endif
						break
					case "string":
						value = AFH_GetAnalysisParamTextual(name, params)
						break
					case "wave":
						WAVE/Z wv = AFH_GetAnalysisParamWave(name, params)
						if(WaveExists(wv))
							value = NumericWaveToList(wv, ";")
						endif
						break
					case "textwave":
						WAVE/Z wv = AFH_GetAnalysisParamTextWave(name, params)
						if(WaveExists(wv))
							value = TextWaveToList(wv, ";")
						endif
						break
					default:
						ASSERT(0, "invalid type")
						break
				endswitch

				SetPopupMenuString(win, "popup_param_types", type)
			endif

			SetSetVariableString(win, "setvar_param_name", name)
			SetSetVariableString(win, "setvar_param_value", value)

			break
	endswitch

	return 0
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
