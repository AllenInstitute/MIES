#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_CONST
#endif

/// @file MIES_Constants.ipf
/// @brief Global constants

/// @defgroup BackgroundFunctions All background functions

/// @name Version constants
/// @anchor VersioningConstants
///@{

Constant DAQ_CONFIG_WAVE_VERSION = 3

/// Used to upgrade the GuiStateWave as well as the DA Ephys panel
Constant DA_EPHYS_PANEL_VERSION           = 64
Constant DATA_SWEEP_BROWSER_PANEL_VERSION = 51
Constant WAVEBUILDER_PANEL_VERSION        = 14
Constant ANALYSISBROWSER_PANEL_VERSION    = 5

/// Version of the stimset wave note
Constant STIMSET_NOTE_VERSION = 11

/// Version of the epoch information for DA+TTL data
Constant SWEEP_EPOCH_VERSION = 9

/// Version of the labnotebooks and results (numerical and textual) waves
///
/// Has to be increased on the following occasions:
/// - New/Removed entries
/// - Changed names of entries
/// - Changed units or meaning of entries
/// - New/Changed layers of entries
///
///@{
Constant LABNOTEBOOK_VERSION = 76
Constant RESULTS_VERSION     = 3
///@}

/// @name Analysis function versions
///@{
Constant PSQ_PIPETTE_BATH_VERSION    = 4
Constant PSQ_ACC_RES_SMOKE_VERSION   = 2
Constant PSQ_CHIRP_VERSION           = 13
Constant PSQ_DA_SCALE_VERSION        = 11
Constant PSQ_RAMP_VERSION            = 6
Constant PSQ_RHEOBASE_VERSION        = 5
Constant PSQ_SQUARE_PULSE_VERSION    = 4
Constant PSQ_SEAL_EVALUATION_VERSION = 3
Constant PSQ_TRUE_REST_VM_VERSION    = 2
Constant MSQ_FAST_RHEO_EST_VERSION   = 1
Constant MSQ_DA_SCALE_VERSION        = 1
Constant SC_SPIKE_CONTROL_VERSION    = 2
///@}

/// Especially interesting for PXP consumers like the analysis browser.
Constant EXPERIMENT_VERSION = 3

/// All experiment versions up to the given value are supported
Constant ANALYSIS_BROWSER_SUPP_VERSION = 3

Constant PA_SETTINGS_STRUCT_VERSION = 6
///@}

/// @name Constans for the number of channels
/// @anchor NUM_CHANNELS_CONSTANTS
///@{
Constant NUM_DA_TTL_CHANNELS       = 8
Constant NUM_HEADSTAGES            = 8
Constant NUM_AD_CHANNELS           = 16
Constant NUM_ASYNC_CHANNELS        = 8
Constant NUM_ITC_TTL_BITS_PER_RACK = 4
///@}

/// Maximum values of @ref NUM_CHANNELS_CONSTANTS
Constant NUM_MAX_CHANNELS = 16

StrConstant ITC_DEVICE_REGEXP = "^ITC.*"

StrConstant DEVICE_TYPES_ITC = "ITC16;ITC18;ITC1600;ITC00;ITC16USB;ITC18USB"
StrConstant DEVICE_NUMBERS   = "0;1;2;3;4;5;6;7;8;9;10"

StrConstant DEVICE_NAME_NICE_SUTTER        = "Sutter Instrument Integrated Patch Amplifier"
StrConstant DEVICE_SUTTER_NAME_START_CLEAN = "IPA_E_"
Constant    SUTTER_AI_PER_AMP              = 4
Constant    SUTTER_AO_PER_AMP              = 2
Constant    SUTTER_DIO_PER_AMP             = 8

StrConstant BASE_WINDOW_NAME          = "DA_Ephys"
StrConstant DATABROWSER_WINDOW_NAME   = "DataBrowser"
StrConstant SWEEPBROWSER_WINDOW_NAME  = "SweepBrowser"
StrConstant EXT_PANEL_SETTINGSHISTORY = "SettingsHistoryPanel"

/// @name Task names
/// @anchor MiesTasknames
///@{
StrConstant TASKNAME_TP        = "Testpulse"
StrConstant TASKNAME_TPMD      = "TestpulseMD"
StrConstant TASKNAME_TIMER     = "Timer"
StrConstant TASKNAME_TIMERMD   = "TimerMD"
StrConstant TASKNAME_FIFOMON   = "FIFOMonitor"
StrConstant TASKNAME_FIFOMONMD = "FIFOMonitorMD"
StrConstant TASKNAMES          = "Testpulse;TestpulseMD;Timer;TimerMD;FIFOMonitor;FIFOMonitorMD;"
///@}

/// @name Various mies specific regular expressions
/// @anchor MiesRegexps
///@{
StrConstant DATA_SWEEP_REGEXP        = "(?i)^Sweep_[[:digit:]]+$"
StrConstant DATA_CONFIG_REGEXP       = "(?i)^Config_Sweep_[[:digit:]]+$"
StrConstant TP_STORAGE_REGEXP        = "(?i)^TPStorage(_[[:digit:]]+)?$"
StrConstant STORED_TESTPULSES_REGEXP = "(?i)^StoredTestPulses_([[:digit:]]+)$"
StrConstant DATA_SWEEP_REGEXP_BAK    = "(?i)^Sweep_[[:digit:]]+_bak$"
StrConstant DATA_CONFIG_REGEXP_BAK   = "(?i)^Config_Sweep_[[:digit:]]+_bak$"
///@}

StrConstant UNTITLED_EXPERIMENT           = "Untitled"
StrConstant PACKED_FILE_EXPERIMENT_SUFFIX = ".pxp"

/// Amount of free memory required to perform data aquisition in GB
Constant FREE_MEMORY_LOWER_LIMIT = 0.75

/// @name Pressure Control constants
///@{
/// Max and min pressure regulator pressure in psi
Constant MAX_REGULATOR_PRESSURE = 9.9
Constant MIN_REGULATOR_PRESSURE = -9.9
///@}

/// The indizies correspond to the values from @ref XopChannelConstants
StrConstant XOP_CHANNEL_NAMES = "AD;DA;;TTL"

/// @name Channel constants shared with the ITC XOP.
///
/// Due to historic reasons these are now also used for other hardware types
/// @anchor XopChannelConstants
///@{
Constant XOP_CHANNEL_TYPE_ADC   = 0
Constant XOP_CHANNEL_TYPE_DAC   = 1
Constant XOP_CHANNEL_TYPE_TTL   = 3
Constant XOP_CHANNEL_TYPE_COUNT = 4 // last channel type + 1
///@}

/// @name DAQ Channel Type constants used in DAQConfigWave
/// @anchor DaqChannelTypeConstants
///@{
Constant DAQ_CHANNEL_TYPE_UNKOWN = -1
Constant DAQ_CHANNEL_TYPE_DAQ    = 1
Constant DAQ_CHANNEL_TYPE_TP     = 2
///@}

/// @name When all DAQ Channels are set to TestPulse the output runs for TIME_TP_ONLY_ON_DAQ seconds
/// @anchor TimeTpOnlyOnDaqConstant
///@{
Constant TIME_TP_ONLY_ON_DAQ = 1
///@}

/// @name Flags for GetActiveChannels
/// @anchor ActiveChannelsTTLMode
///@{
Constant TTL_HARDWARE_CHANNEL = 0x0
Constant TTL_DAEPHYS_CHANNEL  = 0x1
Constant TTL_GUITOHW_CHANNEL  = 0x2
Constant TTL_HWTOGUI_CHANNEL  = 0x3
///@}

Constant MINIMUM_WAVE_SIZE       = 64
Constant MINIMUM_WAVE_SIZE_LARGE = 2048
Constant MAXIMUM_WAVE_SIZE       = 16384 // 2^14

/// @name Wave dimension constants
/// @anchor WaveDimensions
/// Convenience definition to nicify expressions like DimSize(wv, ROWS)
/// easier to read than DimSize(wv, 0).
///@{
Constant DATADIMENSION = -1
Constant ROWS          = 0
Constant COLS          = 1
Constant LAYERS        = 2
Constant CHUNKS        = 3
///@}
Constant MAX_DIMENSION_COUNT = 4

/// @name append userData constants
/// Convenience definition.
/// easier to read than ModifyGraph userData(trace)={name, 0, value}
///@{
Constant USERDATA_MODIFYGRAPH_REPLACE = 0
Constant USERDATA_MODIFYGRAPH_APPEND  = 1
///@}

/// @name Constants used by Downsample
///@{
Constant DECIMATION_BY_OMISSION  = 1
Constant DECIMATION_BY_SMOOTHING = 2
Constant DECIMATION_BY_AVERAGING = 4
///@}

Constant DEFAULT_DECIMATION_FACTOR = -1

/// Common string to denote an invalid entry in a popupmenu
StrConstant NONE = "- none -"

/// @name WMWinHookStruct eventCode field constants
/// @anchor WinHookEventCodes
///@{
Constant EVENT_WINDOW_HOOK_ACTIVATE            = 0
Constant EVENT_WINDOW_HOOK_DEACTIVATE          = 1
Constant EVENT_WINDOW_HOOK_KILL                = 2
Constant EVENT_WINDOW_HOOK_MOUSEDOWN           = 3
Constant EVENT_WINDOW_HOOK_MOUSEMOVED          = 4
Constant EVENT_WINDOW_HOOK_MOUSEUP             = 5
Constant EVENT_WINDOW_HOOK_RESIZE              = 6
Constant EVENT_WINDOW_HOOK_CURSORMOVED         = 7
Constant EVENT_WINDOW_HOOK_MODIFIED            = 8
Constant EVENT_WINDOW_HOOK_ENABLEMENU          = 9
Constant EVENT_WINDOW_HOOK_MENU                = 10
Constant EVENT_WINDOW_HOOK_KEYBOARD            = 11
Constant EVENT_WINDOW_HOOK_MOVED               = 12
Constant EVENT_WINDOW_HOOK_RENAMED             = 13
Constant EVENT_WINDOW_HOOK_SUBWINDOWKILL       = 14
Constant EVENT_WINDOW_HOOK_HIDE                = 15
Constant EVENT_WINDOW_HOOK_SHOW                = 16
Constant EVENT_WINDOW_HOOK_KILLVOTE            = 17
Constant EVENT_WINDOW_HOOK_SHOWTOOLS           = 18
Constant EVENT_WINDOW_HOOK_HIDETOOLS           = 19
Constant EVENT_WINDOW_HOOK_SHOWINFO            = 20
Constant EVENT_WINDOW_HOOK_HIDEINFO            = 21
Constant EVENT_WINDOW_HOOK_MOUSEWHEEL          = 22
Constant EVENT_WINDOW_HOOK_SPINUPDATE          = 23
Constant EVENT_WINDOW_HOOK_TABLEENTRYACCEPTED  = 24
Constant EVENT_WINDOW_HOOK_TABLEENTRYCANCELLED = 25
Constant EVENT_WINDOW_HOOK_EARLYKEYBOARD       = 26
///@}

/// @name Trace Display Types
/// @anchor TraceDisplayTypes
///@{
Constant TRACE_DISPLAY_MODE_LINES          = 0
Constant TRACE_DISPLAY_MODE_STICKS         = 1
Constant TRACE_DISPLAY_MODE_DOTS           = 2
Constant TRACE_DISPLAY_MODE_MARKERS        = 3
Constant TRACE_DISPLAY_MODE_LINES_MARKERS  = 4
Constant TRACE_DISPLAY_MODE_BARS           = 5
Constant TRACE_DISPLAY_MODE_CITY           = 6
Constant TRACE_DISPLAY_MODE_FILL           = 7
Constant TRACE_DISPLAY_MODE_STICKS_MARKERS = 8
Constant TRACE_DISPLAY_MODE_LAST_VALID     = 8
///@}

/// Used by CheckName and UniqueName
Constant CONTROL_PANEL_TYPE = 9

/// @name CountObjects, CountObjectsDFR, GetIndexedObjName, GetIndexedObjNameDFR constants
/// @anchor TypeFlags
///@{
Constant COUNTOBJECTS_WAVES      = 1
Constant COUNTOBJECTS_VAR        = 2
Constant COUNTOBJECTS_STR        = 3
Constant COUNTOBJECTS_DATAFOLDER = 4
///@}

/// @name Control types from ControlInfo
/// @anchor GUIControlTypes
///@{
Constant CONTROL_TYPE_BUTTON        = 1
Constant CONTROL_TYPE_CHECKBOX      = 2
Constant CONTROL_TYPE_POPUPMENU     = 3
Constant CONTROL_TYPE_VALDISPLAY    = 4
Constant CONTROL_TYPE_SETVARIABLE   = 5
Constant CONTROL_TYPE_CHART         = 6
Constant CONTROL_TYPE_SLIDER        = 7
Constant CONTROL_TYPE_TAB           = 8
Constant CONTROL_TYPE_GROUPBOX      = 9
Constant CONTROL_TYPE_TITLEBOX      = 10
Constant CONTROL_TYPE_LISTBOX       = 11
Constant CONTROL_TYPE_CUSTOMCONTROL = 12
///@}

/// @name Modifier flags from the eventMod field of the WMWinHookStruct
/// @anchor WMWinHookEventMod
///@{
Constant WINDOW_HOOK_EMOD_MBUTTONDOWN  = 1
Constant WINDOW_HOOK_EMOD_SHIFTKEYDOWN = 2
Constant WINDOW_HOOK_EMOD_ALTKEYDOWN   = 4
Constant WINDOW_HOOK_EMOD_CTRLKEYDOWN  = 8
Constant WINDOW_HOOK_EMOD_RIGHTCLICK   = 16
///@}

StrConstant CURSOR_NAMES = "A;B;C;D;E;F;G;H;I;J"

// Conversion factor from ticks to seconds, exact value is 1/60
Constant TICKS_TO_SECONDS = 0.0166666666666667

StrConstant TRASH_FOLDER_PREFIX     = "trash"
StrConstant SIBLING_FILENAME_SUFFIX = "sibling"

StrConstant NOTE_INDEX = "Index"

///@name   Parameters for FindIndizes
///@anchor FindIndizesProps
///@{
Constant PROP_NOT                  = 0x01 ///< Inverts the matching
Constant PROP_EMPTY                = 0x02 ///< Wave entry is NaN or ""
Constant PROP_MATCHES_VAR_BIT_MASK = 0x04 ///< Wave entry matches the bitmask given in var
Constant PROP_GREP                 = 0x08 ///< Wave entry matches the regular expression given in str
Constant PROP_WILDCARD             = 0x10 ///< Wave entry matches the wildcard expression given in str
///@}

/// @name Parameters for GetPanelControl and IDX_GetSetsInRange, GetSetFolder, GetSetParamFolder and GetChanneListFromITCConfig
/// @anchor ChannelTypeAndControlConstants
///@{
Constant CHANNEL_TYPE_DAC          = 0x000
Constant CHANNEL_TYPE_TTL          = 0x001
Constant CHANNEL_TYPE_ADC          = 0x002
Constant CHANNEL_CONTROL_WAVE      = 0x004
Constant CHANNEL_CONTROL_INDEX_END = 0x008
Constant CHANNEL_CONTROL_UNIT      = 0x010
Constant CHANNEL_CONTROL_GAIN      = 0x020
Constant CHANNEL_CONTROL_SCALE     = 0x030
Constant CHANNEL_CONTROL_CHECK     = 0x040
Constant CHANNEL_TYPE_HEADSTAGE    = 0x080
Constant CHANNEL_TYPE_ASYNC        = 0x100
Constant CHANNEL_TYPE_ALARM        = 0x110
Constant CHANNEL_CONTROL_ALARM_MIN = 0x120
Constant CHANNEL_CONTROL_ALARM_MAX = 0x130
Constant CHANNEL_CONTROL_SEARCH    = 0x140
Constant CHANNEL_TYPE_UNKNOWN      = 0x150
Constant CHANNEL_CONTROL_TITLE     = 0x160
///@}

/// @name Controls for multiple channels have negative channel indizes
/// @anchor AllHeadstageModeConstants
///@{
Constant CHANNEL_INDEX_ALL         = -1
Constant CHANNEL_INDEX_ALL_V_CLAMP = -2
Constant CHANNEL_INDEX_ALL_I_CLAMP = -3
Constant CHANNEL_INDEX_ALL_I_ZERO  = -4
///@}

/// @name Constants for the bitmask entries stored in the selection wave
///       of a ListBox
/// @anchor ListBoxSelectionWaveFlags
///@{
Constant LISTBOX_SELECTED              = 0x01
Constant LISTBOX_CELL_EDITABLE         = 0x02
Constant LISTBOX_CELL_DOUBLECLICK_EDIT = 0x04
Constant LISTBOX_SHIFT_SELECTION       = 0x08
Constant LISTBOX_CHECKBOX_SELECTED     = 0x10
Constant LISTBOX_CHECKBOX              = 0x20
Constant LISTBOX_TREEVIEW_EXPANDED     = 0x10 ///< Convenience definition, equal to #LISTBOX_CHECKBOX_SELECTED
Constant LISTBOX_TREEVIEW              = 0x40
///@}

Constant INITIAL_KEY_WAVE_COL_COUNT = 5

StrConstant LABNOTEBOOK_KEYS_INITIAL = "SweepNum;TimeStamp;TimeStampSinceIgorEpochUTC;EntrySourceType;AcquisitionState"

/// @name Constants for the note of the wave returned by GetTPStorage
///@{
StrConstant AUTOBIAS_LAST_INVOCATION_KEY = "AutoBiasLastInvocation"
StrConstant DIMENSION_SCALING_LAST_INVOC = "DimensionScalingLastInvocation"
StrConstant PRESSURE_CTRL_LAST_INVOC     = "PressureControlLastInvocation"
StrConstant INDEX_ON_TP_START            = "IndexOnTestPulseStart"
StrConstant AUTOTP_LAST_INVOCATION_KEY   = "AutoTPLastInvocation"
///@}

/// @name Modes for SaveExperimentSpecial
/// @anchor SaveExperimentModes
///@{
Constant SAVE_AND_CLEAR = 0x01
Constant SAVE_AND_SPLIT = 0x02
///@}

/// @name Constants for data acquisition modes
/// @anchor DataAcqModes
///@{
Constant UNKNOWN_MODE          = NaN
Constant DATA_ACQUISITION_MODE = 0
Constant TEST_PULSE_MODE       = 1
Constant SWEEP_FORMULA_RESULT  = 2
Constant SWEEP_FORMULA_PSX     = 3
///@}

Constant NUMBER_OF_LBN_DAQ_MODES = 4

/// @name Constants for three Amplifier modes
/// @anchor AmplifierClampModes
///@{
Constant V_CLAMP_MODE      = 0
Constant I_CLAMP_MODE      = 1
Constant I_EQUAL_ZERO_MODE = 2
///@}

Constant NUM_CLAMP_MODES = 3

/// @name Possible values for the function parameter of AI_SendToAmp
/// @anchor AI_SendToAmpConstants
///@{
Constant MCC_BEGIN_INVALID_FUNC          = 10000
Constant MCC_SETHOLDING_FUNC             = 10001
Constant MCC_GETHOLDING_FUNC             = 10002
Constant MCC_SETHOLDINGENABLE_FUNC       = 10003
Constant MCC_GETHOLDINGENABLE_FUNC       = 10004
Constant MCC_SETBRIDGEBALENABLE_FUNC     = 10005
Constant MCC_GETBRIDGEBALENABLE_FUNC     = 10006
Constant MCC_SETBRIDGEBALRESIST_FUNC     = 10007
Constant MCC_GETBRIDGEBALRESIST_FUNC     = 10008
Constant MCC_AUTOBRIDGEBALANCE_FUNC      = 10009
Constant MCC_SETNEUTRALIZATIONENABL_FUNC = 10010
Constant MCC_GETNEUTRALIZATIONENABL_FUNC = 10011
Constant MCC_SETNEUTRALIZATIONCAP_FUNC   = 10012
Constant MCC_GETNEUTRALIZATIONCAP_FUNC   = 10013
Constant MCC_SETWHOLECELLCOMPENABLE_FUNC = 10014
Constant MCC_GETWHOLECELLCOMPENABLE_FUNC = 10015
Constant MCC_SETWHOLECELLCOMPCAP_FUNC    = 10016
Constant MCC_GETWHOLECELLCOMPCAP_FUNC    = 10017
Constant MCC_SETWHOLECELLCOMPRESIST_FUNC = 10018
Constant MCC_GETWHOLECELLCOMPRESIST_FUNC = 10019
Constant MCC_AUTOWHOLECELLCOMP_FUNC      = 10020
Constant MCC_SETRSCOMPENABLE_FUNC        = 10021
Constant MCC_GETRSCOMPENABLE_FUNC        = 10022
Constant MCC_SETRSCOMPBANDWIDTH_FUNC     = 10023
Constant MCC_GETRSCOMPBANDWIDTH_FUNC     = 10024
Constant MCC_SETRSCOMPCORRECTION_FUNC    = 10025
Constant MCC_GETRSCOMPCORRECTION_FUNC    = 10026
Constant MCC_SETRSCOMPPREDICTION_FUNC    = 10027
Constant MCC_GETRSCOMPPREDICTION_FUNC    = 10028
Constant MCC_SETOSCKILLERENABLE_FUNC     = 10029
Constant MCC_GETOSCKILLERENABLE_FUNC     = 10030
Constant MCC_AUTOPIPETTEOFFSET_FUNC      = 10031
Constant MCC_SETPIPETTEOFFSET_FUNC       = 10032
Constant MCC_GETPIPETTEOFFSET_FUNC       = 10033
Constant MCC_SETFASTCOMPCAP_FUNC         = 10034
Constant MCC_GETFASTCOMPCAP_FUNC         = 10035
Constant MCC_SETSLOWCOMPCAP_FUNC         = 10036
Constant MCC_GETSLOWCOMPCAP_FUNC         = 10037
Constant MCC_SETFASTCOMPTAU_FUNC         = 10038
Constant MCC_GETFASTCOMPTAU_FUNC         = 10039
Constant MCC_SETSLOWCOMPTAU_FUNC         = 10040
Constant MCC_GETSLOWCOMPTAU_FUNC         = 10041
Constant MCC_SETSLOWCOMPTAUX20ENAB_FUNC  = 10042
Constant MCC_GETSLOWCOMPTAUX20ENAB_FUNC  = 10043
Constant MCC_AUTOFASTCOMP_FUNC           = 10044
Constant MCC_AUTOSLOWCOMP_FUNC           = 10045
Constant MCC_SETSLOWCURRENTINJENABL_FUNC = 10046
Constant MCC_GETSLOWCURRENTINJENABL_FUNC = 10047
Constant MCC_SETSLOWCURRENTINJLEVEL_FUNC = 10048
Constant MCC_GETSLOWCURRENTINJLEVEL_FUNC = 10049
Constant MCC_SETSLOWCURRENTINJSETLT_FUNC = 10050
Constant MCC_GETSLOWCURRENTINJSETLT_FUNC = 10051
Constant MCC_SETPRIMARYSIGNALGAIN_FUNC   = 10052
Constant MCC_GETPRIMARYSIGNALGAIN_FUNC   = 10053
Constant MCC_SETSECONDARYSIGNALGAIN_FUNC = 10054
Constant MCC_GETSECONDARYSIGNALGAIN_FUNC = 10055
Constant MCC_SETPRIMARYSIGNALHPF_FUNC    = 10056
Constant MCC_GETPRIMARYSIGNALHPF_FUNC    = 10057
Constant MCC_SETPRIMARYSIGNALLPF_FUNC    = 10058
Constant MCC_GETPRIMARYSIGNALLPF_FUNC    = 10059
Constant MCC_SETSECONDARYSIGNALLPF_FUNC  = 10060
Constant MCC_GETSECONDARYSIGNALLPF_FUNC  = 10061
Constant MCC_END_INVALID_FUNC            = 10062
///@}

/// Magic value for selecting "Bypass" in the bessel filter for the primary output
Constant LPF_BYPASS = 100e3

Constant CHECKBOX_SELECTED   = 1
Constant CHECKBOX_UNSELECTED = 0

/// @name Constants for FunctionInfo and WaveType
///
/// @anchor IgorTypes
///@{
Constant IGOR_TYPE_COMPLEX          = 0x001
Constant IGOR_TYPE_32BIT_FLOAT      = 0x002
Constant IGOR_TYPE_64BIT_FLOAT      = 0x004
Constant IGOR_TYPE_8BIT_INT         = 0x008
Constant IGOR_TYPE_16BIT_INT        = 0x010
Constant IGOR_TYPE_32BIT_INT        = 0x020
Constant IGOR_TYPE_64BIT_INT        = 0x080
Constant IGOR_TYPE_UNSIGNED         = 0x040 ///< Can be combined, using bitwise or, with all integer types
Constant IGOR_TYPE_STRUCT_PARAMETER = 0x200
// If wavetype is called with selector 1
Constant IGOR_TYPE_NULL_WAVE    = 0x000
Constant IGOR_TYPE_NUMERIC_WAVE = 0x001
Constant IGOR_TYPE_TEXT_WAVE    = 0x002
Constant IGOR_TYPE_DFREF_WAVE   = 0x003
Constant IGOR_TYPE_WAVEREF_WAVE = 0x004
// If wavetype is called with selector 2
//Constant IGOR_TYPE_NULL_WAVE      = 0x000
Constant IGOR_TYPE_GLOBAL_WAVE = 0x001
Constant IGOR_TYPE_FREE_WAVE   = 0x002
Constant IGOR_TYPE_FREEDF_WAVE = 0x002
///@}

/// @name TabControl values in Browser Settings Panel
///@{
Constant MIES_BSP_OVS = 1
Constant MIES_BSP_CS  = 2
Constant MIES_BSP_AR  = 3
Constant MIES_BSP_PA  = 4
Constant MIES_BSP_SF  = 5
Constant MIES_BSP_DS  = 7
///@}

/// @name values for  UserData in BrowserSettings and derived windows
///@{
StrConstant MIES_BSP_BROWSER        = "BROWSER"
StrConstant MIES_BSP_BROWSER_MODE   = "BROWSERMODE"
StrConstant MIES_BSP_DEVICE         = "DEVICE"
StrConstant MIES_BSP_PANEL_FOLDER   = "PANEL_FOLDER"
StrConstant MIES_BSP_AR_SWEEPFOLDER = "AR_SWEEPFOLDER"
StrConstant MIES_BSP_PA_MAINPANEL   = "HOSTWINDOW"
///@}

StrConstant NUMERALS = "First;Second;Third;Fourth;Fifth;Sixth;Seventh;Eighth"

/// Generic axis name for graphs using split axis
StrConstant VERT_AXIS_BASE_NAME  = "row"
StrConstant HORIZ_AXIS_BASE_NAME = "col"

/// Fallback value for  the sampling interval in milliseconds (1e-3) used by
/// #SI_CalculateMinSampInterval if the lookup table could not be found on disk.
Constant SAMPLING_INTERVAL_FALLBACK = 0.050

/// @name Constants for the type flag of `LoadData`
/// @anchor LoadDataConstants
///@{
Constant LOAD_DATA_TYPE_WAVES   = 1
Constant LOAD_DATA_TYPE_NUMBERS = 2
Constant LOAD_DATA_TYPE_STRING  = 4
///@}

/// @name Constants for the time alignment mode of TimeAlignmentIfReq
/// @anchor TimeAlignmentConstants
///@{
Constant TIME_ALIGNMENT_NONE          = -1
Constant TIME_ALIGNMENT_LEVEL_RISING  = 0
Constant TIME_ALIGNMENT_LEVEL_FALLING = 1
Constant TIME_ALIGNMENT_MIN           = 2
Constant TIME_ALIGNMENT_MAX           = 3
///@}

StrConstant WAVE_BACKUP_SUFFIX = "_bak"

/// @name Test pulse modes
/// @anchor TestPulseRunModes
///@{
Constant TEST_PULSE_NOT_RUNNING      = 0x000
Constant TEST_PULSE_BG_SINGLE_DEVICE = 0x001
Constant TEST_PULSE_BG_MULTI_DEVICE  = 0x002
Constant TEST_PULSE_FG_SINGLE_DEVICE = 0x004
Constant TEST_PULSE_DURING_RA_MOD    = 0x100 ///< Or'ed with the testpulse mode. Special casing for testpulse during DAQ/RA/ITI
// foreground multi device does not exist
///@}

/// @name Data acquisition modes
/// @anchor DAQRunModes
///@{
Constant DAQ_NOT_RUNNING      = 0x000
Constant DAQ_BG_SINGLE_DEVICE = 0x001
Constant DAQ_BG_MULTI_DEVICE  = 0x002
Constant DAQ_FG_SINGLE_DEVICE = 0x004
// foreground multi device does not exist
///@}

/// @name Reserved Stim set name for TP while DAQ
/// @anchor ReservedStimSetName
///@{
StrConstant STIMSET_TP_WHILE_DAQ = "TestPulse"
///@}

/// @name Constants for GetAxisOrientation
/// @anchor AxisOrientationConstants
///@{
Constant AXIS_ORIENTATION_HORIZ  = 0x01
Constant AXIS_ORIENTATION_BOTTOM = 0x05
Constant AXIS_ORIENTATION_TOP    = 0x09
Constant AXIS_ORIENTATION_VERT   = 0x02
Constant AXIS_ORIENTATION_LEFT   = 0x12
Constant AXIS_ORIENTATION_RIGHT  = 0x22
///@}

/// @name Constants for Set/GetAxesRanges modes, use binary pattern
/// @anchor AxisPropModeConstants
///@{
Constant AXIS_RANGE_DEFAULT        = 0x00
Constant AXIS_RANGE_USE_MINMAX     = 0x01
Constant AXIS_RANGE_INC_AUTOSCALED = 0x02
///@}

/// @name Constants for Axis name template
/// @anchor AxisNameTemplates
///@{
StrConstant AXIS_SCOPE_AD        = "AD"
StrConstant AXIS_SCOPE_AD_REGEXP = "AD[0123456789]+"
StrConstant AXIS_SCOPE_TP_TIME   = "top"
///@}

/// @name Constants for DAP_ToggleAcquisitionButton
/// @anchor ToggleAcquisitionButtonConstants
///@{
Constant DATA_ACQ_BUTTON_TO_STOP = 0x01
Constant DATA_ACQ_BUTTON_TO_DAQ  = 0x02
///@}

/// @name Constants for DAP_ToggleTestpulseButton
/// @anchor ToggleTestpulseButtonConstants
///@{
Constant TESTPULSE_BUTTON_TO_STOP  = 0x01
Constant TESTPULSE_BUTTON_TO_START = 0x02
///@}

/// @name Constants for functions using rack number parameters
/// @anchor RackConstants
///@{
Constant RACK_ZERO = 0x00
Constant RACK_ONE  = 0x01
///@}

StrConstant STIM_WAVE_NAME_KEY = "Stim Wave Name"

/// Last valid row index for storing epoch types in #GetSegmentTypeWave
Constant WB_TOTAL_NUMBER_OF_EPOCHS = 94

/// Minimum logarithm to base two for the DAQDataWave size for ITC hardware
Constant MINIMUM_ITCDATAWAVE_EXPONENT = 20

/// Minimum value for the baseline fraction of the Testpulse in percent
Constant MINIMUM_TP_BASELINE_PERCENTAGE = 25

/// @name Return types of @ref GetInternalSetVariableType
/// @anchor GetInternalSetVariableTypeReturnTypes
///@{
Constant SET_VARIABLE_BUILTIN_NUM = 0x01
Constant SET_VARIABLE_BUILTIN_STR = 0x02
Constant SET_VARIABLE_GLOBAL      = 0x04
///@}

Constant DISABLE_CONTROL_BIT = 2
Constant HIDDEN_CONTROL_BIT  = 1

/// @name Acquisition states
/// @anchor AcquisitionStates
///
/// @todo extend these with PRE_SET_EVENT and POST_SET_EVENT once this is
/// reworked, see https://github.com/AllenInstitute/MIES/issues/658 and
/// https://github.com/AllenInstitute/MIES/issues/39.
///
/// The state values are serialized to the labnotebooks, so they must never change.
///
///@{
Constant AS_INACTIVE         = 0
Constant AS_EARLY_CHECK      = 1
Constant AS_PRE_DAQ          = 2
Constant AS_PRE_SWEEP        = 3
Constant AS_MID_SWEEP        = 4
Constant AS_POST_SWEEP       = 5
Constant AS_ITI              = 6
Constant AS_POST_DAQ         = 7
Constant AS_PRE_SWEEP_CONFIG = 8
Constant AS_NUM_STATES       = 9
///@}

/// @name Event types for analysis functions
/// @anchor EVENT_TYPE_ANALYSIS_FUNCTIONS
///@{
Constant PRE_DAQ_EVENT          = 0
Constant MID_SWEEP_EVENT        = 1
Constant POST_SWEEP_EVENT       = 2
Constant POST_SET_EVENT         = 3
Constant POST_DAQ_EVENT         = 4
Constant PRE_SWEEP_CONFIG_EVENT = 5
Constant PRE_SET_EVENT          = 7
///@}

Constant GENERIC_EVENT = 6 ///< Only used for internal bookkeeping. Never
///  send to analysis functions.

/// Number of @ref EVENT_TYPE_ANALYSIS_FUNCTIONS
Constant TOTAL_NUM_EVENTS = 8

/// Column for GetAnalysisFunctionStorage(). Same value as #TOTAL_NUM_EVENTS
/// but more readable.
Constant ANALYSIS_FUNCTION_PARAMS = 8

StrConstant ANALYSIS_FUNCTION_PARAMS_LBN     = "Function params (encoded)"
StrConstant ANALYSIS_FUNCTION_PARAMS_STIMSET = "Function params (encoded)"

/// Human readable names for @ref EVENT_TYPE_ANALYSIS_FUNCTIONS
StrConstant EVENT_NAME_LIST = "Pre DAQ;Mid Sweep;Post Sweep;Post Set;Post DAQ;Pre Sweep Config;Generic;Pre Set"

/// Labnotebook entries
StrConstant EVENT_NAME_LIST_LBN = "Pre DAQ function;Mid Sweep function;Post Sweep function;Post Set function;Post DAQ function;Pre Sweep Config function;Generic function;Pre Set function"

/// List of valid analysis function types
/// @anchor AnalysisFunctionParameterTypes
StrConstant ANALYSIS_FUNCTION_PARAMS_TYPES = "variable;string;wave;textwave"

/// @name Special return values for analysis functions. See also @ref
/// AnalysisFunctionReturnTypes.
///
/// @anchor AnalysisFuncReturnTypesConstants
///@{
Constant ANALYSIS_FUNC_RET_REPURP_TIME = -100
Constant ANALYSIS_FUNC_RET_EARLY_STOP  = -101
///@}

/// @name Constants for differentiating between different analysis function versions
/// @anchor AnalysisFunctionVersions
///@{
Constant ANALYSIS_FUNCTION_VERSION_V1  = 0x0001
Constant ANALYSIS_FUNCTION_VERSION_V2  = 0x0002
Constant ANALYSIS_FUNCTION_VERSION_V3  = 0x0004
Constant ANALYSIS_FUNCTION_VERSION_ALL = 0xFFFF
///@}

/// Number of layers in the labnotebook
Constant LABNOTEBOOK_LAYER_COUNT = 9

/// Index for storing headstage independent data into the labnotebook
Constant INDEP_HEADSTAGE = 8

StrConstant UNKNOWN_MIES_VERSION = "unknown version"

/// Number of common control groups in the DA_EPHYS panel
Constant COMMON_CONTROL_GROUP_COUNT_NUM = 19
Constant COMMON_CONTROL_GROUP_COUNT_TXT = 10

/// Equals 2^5 from `GetKeyState`
Constant ESCAPE_KEY = 32

/// Window hook key constants
///@{
Constant LEFT_KEY  = 28
Constant RIGHT_KEY = 29
Constant UP_KEY    = 30
Constant DOWN_KEY  = 31
Constant SPACE_KEY = 32
Constant C_KEY     = 99
Constant E_KEY     = 101
Constant F_KEY     = 102
Constant R_KEY     = 114
Constant Z_KEY     = 122
///@}

Constant MAX_COMMANDLINE_LENGTH = 2500

StrConstant WAVEBUILDER_COMBINE_FORMULA_VER = "1"

/// Conversion factor between volts and bits for the AD/DA channels
/// The ITC 16 bit range is +-10.24 V such that a value of 32000 represents exactly 10 V, thus 3200 -> 1 V.
Constant HARDWARE_ITC_BITS_PER_VOLT = 3200

/// @name Trigger modes
/// External trigger is used for yoking multiple ITC 1600 devices (not supported anymore)
/// @anchor TriggerModeStartAcq
///@{
Constant HARDWARE_DAC_DEFAULT_TRIGGER  = 0x0
Constant HARDWARE_DAC_EXTERNAL_TRIGGER = 0x1
///@}

/// @name The channel numbers for the different ITC devices used for accesssing
///       the TTLs
///@{
Constant HARDWARE_ITC_TTL_DEF_RACK_ZERO  = 1
Constant HARDWARE_ITC_TTL_1600_RACK_ZERO = 0
Constant HARDWARE_ITC_TTL_1600_RACK_ONE  = 3
///@}

/// @name Flags for all hardware interaction functions from MIES_DAC-Hardware.ipf
/// @anchor HardwareInteractionFlags
///@{
Constant HARDWARE_ABORT_ON_ERROR        = 0x01
Constant HARDWARE_PREVENT_ERROR_MESSAGE = 0x04
///@}

/// List of different DAC hardware types
StrConstant HARDWARE_DAC_TYPES = "ITC;NI;SUTTER;"

/// @name Indizes into HARDWARE_DAC_TYPES
/// @anchor HardwareDACTypeConstants
///@{
Constant HARDWARE_ITC_DAC         = 0
Constant HARDWARE_NI_DAC          = 1
Constant HARDWARE_SUTTER_DAC      = 2
Constant HARDWARE_UNSUPPORTED_DAC = 1000
///@}

/// @name Name of NI_DAC FIFO
/// @anchor NIDAQ FIFO Name
///@{
StrConstant HARDWARE_NI_ADC_FIFO = "NI_AnalogIn"
///@}

/// We always use this DIO port for NI hardware
Constant HARDWARE_NI_TTL_PORT = 0

Constant HARDWARE_MAX_DEVICES = 10

/// @name Minimum possible sampling intervals in milliseconds (1e-3s)
///@{
#ifdef EVIL_KITTEN_EATING_MODE
Constant HARDWARE_NI_DAC_MIN_SAMPINT = 0.2
#else
Constant HARDWARE_NI_DAC_MIN_SAMPINT = 0.002 ///< NI 6343 and other devices, so it is 4E-3 ms for 2 channels, 6E-3 ms for 3 a.s.o.
#endif
Constant HARDWARE_ITC_MIN_SAMPINT     = 0.005 ///< ITC DACs
Constant HARDWARE_NI_6001_MIN_SAMPINT = 0.2   ///< NI 6001 USB
Constant HARDWARE_SU_MIN_SAMPINT_DAC  = 0.1   /// Sutter output -> 10 kHz
Constant HARDWARE_SU_MIN_SAMPINT_ADC  = 0.02  /// Sutter input -> 50 kHz
///@}

Constant WAVEBUILDER_MIN_SAMPINT    = 0.005 ///< [ms]
Constant WAVEBUILDER_MIN_SAMPINT_HZ = 200e3 ///< Stimulus sets are created with that frequency

StrConstant CHANNEL_DA_SEARCH_STRING  = "*DA*"
StrConstant CHANNEL_TTL_SEARCH_STRING = "*TTL*"

/// @name Constants for the return value of AI_SelectMultiClamp()
/// @anchor AISelectMultiClampReturnValues
///@{
Constant AMPLIFIER_CONNECTION_SUCCESS    = 0 ///< success
Constant AMPLIFIER_CONNECTION_INVAL_SER  = 1 ///< stored amplifier serials are invalid
Constant AMPLIFIER_CONNECTION_MCC_FAILED = 2 ///< calling MCC_SelectMultiClamp700B failed
///@}

/// Additional entry in the NWB source attribute for TTL data
StrConstant NWB_SOURCE_TTL_BIT = "TTLBit"
StrConstant IPNWB_PLACEHOLDER  = "PLACEHOLDER"

/// @name Constants for the options parameter of DAP_ChangeHeadStageMode()
/// @anchor ClampModeChangeOptions
///@{
Constant DO_MCC_MIES_SYNCING = 0x0 ///< Default mode with all bells and whistles
Constant NO_SLIDER_MOVEMENT  = 0x2 ///< Does not move the headstage slider
Constant MCC_SKIP_UPDATES    = 0x4 ///< Skips all unnecessary updates. Intereseting for temporarily switching the clamp mode,
///< e.g. for an auto MCC amplifier function.
///< Using that option requires to switch the clamp mode back to its original value.
///@}

/// Number of trials to find a suitable port for binding a ZeroMQ service
Constant ZEROMQ_NUM_BIND_TRIALS = 32

Constant ZEROMQ_BIND_REP_PORT = 5670

Constant ZEROMQ_BIND_PUB_PORT = 5770

/// @name Constants for AnalysisBrowserMap (Text Wave)
/// @anchor AnalysisBrowserFileTypes
///@{
StrConstant ANALYSISBROWSER_FILE_TYPE_IGOR  = "Igor"
StrConstant ANALYSISBROWSER_FILE_TYPE_NWBv1 = "NWBv1"
StrConstant ANALYSISBROWSER_FILE_TYPE_NWBV2 = "NWBv2"
///@}

/// Convenience definition for functions interacting with threads
Constant MAIN_THREAD = 0

/// @name Available pressure modes for P_SetPressureMode()
///
/// See P_PressureMethodToString() for getting a string representation.
///
/// @anchor PressureModeConstants
///@{
Constant PRESSURE_METHOD_ATM      = -1
Constant PRESSURE_METHOD_APPROACH = 0
Constant PRESSURE_METHOD_SEAL     = 1
Constant PRESSURE_METHOD_BREAKIN  = 2
Constant PRESSURE_METHOD_CLEAR    = 3
Constant PRESSURE_METHOD_MANUAL   = 4
///@}

/// @name Different pressure types of each headstage
/// @anchor PressureTypeConstants
///@{
Constant PRESSURE_TYPE_ATM    = -1
Constant PRESSURE_TYPE_AUTO   = 0
Constant PRESSURE_TYPE_MANUAL = 1
Constant PRESSURE_TYPE_USER   = 2
///@}

StrConstant POPUPMENU_DIVIDER = "\\M1(-"

/// @name Constants for different WaveBuilder epochs
/// Numbers are stored in the SegWvType waves, so they are part of our "API".
/// @anchor WaveBuilderEpochTypes
///@{
Constant EPOCH_TYPE_SQUARE_PULSE  = 0
Constant EPOCH_TYPE_RAMP          = 1
Constant EPOCH_TYPE_NOISE         = 2
Constant EPOCH_TYPE_SIN_COS       = 3
Constant EPOCH_TYPE_SAW_TOOTH     = 4
Constant EPOCH_TYPE_PULSE_TRAIN   = 5
Constant EPOCH_TYPE_PSC           = 6
Constant EPOCH_TYPE_CUSTOM        = 7
Constant EPOCH_TYPE_COMBINE       = 8
Constant EPOCH_TYPES_TOTAL_NUMBER = 9
///@}

/// Used for the textual wavebuilder parameter wave `WPT` as that stores
/// the set parameters in layer 0. Coincides with `EPOCH_TYPE_SQUARE_PULSE`.
Constant INDEP_EPOCH_TYPE = 0

/// @name Parameters for gnoise and enoise
///@{
Constant NOISE_GEN_LINEAR_CONGRUENTIAL = 1 ///< Don't use for new code.
Constant NOISE_GEN_MERSENNE_TWISTER    = 2 ///< Don't use for new code.
Constant NOISE_GEN_XOSHIRO             = 3
///@}

StrConstant SEGMENTWAVE_SPECTRUM_PREFIX = "segmentWaveSpectrum"

/// @name Different types of noise epochs
/// @anchor EpochNoiseTypes
///@{
Constant NOISE_TYPE_WHITE = 0
Constant NOISE_TYPE_PINK  = 1
Constant NOISE_TYPE_BROWN = 2
///@}

StrConstant NOISE_TYPES_STRINGS = "White;Pink;Brown"
StrConstant PULSE_TYPES_STRINGS = "Square;Triangle"

StrConstant NOTE_KEY_ZEROED                 = "Zeroed"
StrConstant NOTE_KEY_TIMEALIGN              = "TimeAlign"
StrConstant NOTE_KEY_ARTEFACT_REMOVAL       = "ArtefactRemoval"
StrConstant NOTE_KEY_SEARCH_FAILED_PULSE    = "SearchFailedPulses"
StrConstant NOTE_KEY_FAILED_PULSE_LEVEL     = "FailedPulseLevel"
StrConstant NOTE_KEY_NUMBER_OF_SPIKES       = "NumberOfSpikes"
StrConstant NOTE_KEY_PULSE_SORT_ORDER       = "PulseSortOrder"
StrConstant NOTE_KEY_WAVE_MINIMUM           = "WaveMinimum"
StrConstant NOTE_KEY_WAVE_MAXIMUM           = "WaveMaximum"
StrConstant NOTE_KEY_PULSE_LENGTH           = "PulseLength"
StrConstant NOTE_KEY_TIMEALIGN_FEATURE_POS  = "TimeAlignmentFeaturePosition"
StrConstant NOTE_KEY_TIMEALIGN_TOTAL_OFFSET = "TimeAlignmentTotalOffset"
StrConstant NOTE_KEY_IMG_PMIN               = "PulsesMinimum"
StrConstant NOTE_KEY_IMG_PMAX               = "PulsesMaximum"
StrConstant NOTE_KEY_PULSE_IS_DIAGONAL      = "IsDiagonal"
StrConstant NOTE_KEY_PULSE_START            = "PulseStart"
StrConstant NOTE_KEY_PULSE_END              = "PulseEnd"
StrConstant NOTE_KEY_CLAMP_MODE             = "ClampMode"

/// Only present for diagonal pulses
///@{
StrConstant NOTE_KEY_PULSE_HAS_FAILED      = "PulseHasFailed"
StrConstant NOTE_KEY_PULSE_FOUND_SPIKES    = "NumberOfFoundSpikes"
StrConstant NOTE_KEY_PULSE_SPIKE_POSITIONS = "SpikePositions"
///@}

/// DA_Ephys Panel Tabs
Constant DA_EPHYS_PANEL_DATA_ACQUISITION = 0
Constant DA_EPHYS_PANEL_DA               = 1
Constant DA_EPHYS_PANEL_AD               = 2
Constant DA_EPHYS_PANEL_TTL              = 3
Constant DA_EPHYS_PANEL_ASYNCHRONOUS     = 4
Constant DA_EPHYS_PANEL_SETTINGS         = 5
Constant DA_EPHYS_PANEL_HARDWARE         = 6
Constant DA_EPHYS_PANEL_VCLAMP           = 0
Constant DA_EPHYS_PANEL_ICLAMP           = 1
Constant DA_EPHYS_PANEL_IEQUALZERO       = 2
Constant DA_EPHYS_PANEL_PRESSURE_AUTO    = 0
Constant DA_EPHYS_PANEL_PRESSURE_MANUAL  = 1
Constant DA_EPHYS_PANEL_PRESSURE_USER    = 2

StrConstant PULSE_START_TIMES_KEY       = "Pulse Train Pulses"
StrConstant PULSE_TO_PULSE_LENGTH_KEY   = "Pulse To Pulse Length"
StrConstant HIGH_PREC_SWEEP_START_KEY   = "High precision sweep start"
StrConstant STIMSET_SCALE_FACTOR_KEY    = "Stim Scale Factor"
StrConstant STIMSET_WAVE_NOTE_KEY       = "Stim Wave Note"
StrConstant EPOCHS_ENTRY_KEY            = "Epochs"
StrConstant CLAMPMODE_ENTRY_KEY         = "Clamp Mode"
StrConstant TP_AMPLITUDE_VC_ENTRY_KEY   = "TP Amplitude VC"
StrConstant TP_AMPLITUDE_IC_ENTRY_KEY   = "TP Amplitude IC"
StrConstant PULSE_START_INDICES_KEY     = "Pulse Train Pulse Start Indices"
StrConstant PULSE_END_INDICES_KEY       = "Pulse Train Pulse End Indices"
StrConstant INFLECTION_POINTS_INDEX_KEY = "Inflection Points Indices"
StrConstant EPOCH_LENGTH_INDEX_KEY      = "Epoch Length Indices"
StrConstant STIMSET_SIZE_KEY            = "Stimset Size"
StrConstant STIMSET_ERROR_KEY           = "Wavebuilder Error"
StrConstant AUTOBIAS_PERC_KEY           = "Autobias %"

Constant WAVEBUILDER_STATUS_ERROR = 1

/// DA_Ephys controls which should be disabled during DAQ
StrConstant CONTROLS_DISABLE_DURING_DAQ = "Check_DataAcqHS_All;Radio_ClampMode_AllIClamp;Radio_ClampMode_AllVClamp;Radio_ClampMode_AllIZero;SetVar_Sweep;Check_DataAcq_Indexing;check_DataAcq_IndexRandom;Check_DataAcq1_IndexingLocked;check_DataAcq_RepAcqRandom;Check_DataAcq1_RepeatAcq;Check_Settings_SkipAnalysFuncs;check_Settings_MD"
StrConstant CONTROLS_DISABLE_DURING_IDX = "SetVar_DataAcq_ListRepeats;SetVar_DataAcq_SetRepeats"

/// DA_Ephys controls which should be disabled during DAQ *and* TP
StrConstant CONTROLS_DISABLE_DURING_DAQ_TP = "Check_Settings_BkgTP;Check_Settings_BackgrndDataAcq"

/// @name Parameters for GetAllDevicesWithContent()
/// @anchor CONTENT_TYPES
///@{
Constant CONTENT_TYPE_SWEEP     = 0x01
Constant CONTENT_TYPE_TPSTORAGE = 0x02
Constant CONTENT_TYPE_COMMENT   = 0x04
Constant CONTENT_TYPE_ALL       = 0xFF
///@}

/// @name Parameter type flags for WB_GetParameterWaveName
///
/// @anchor ParameterWaveTypes
///@{
Constant STIMSET_PARAM_WP        = 0
Constant STIMSET_PARAM_WPT       = 1
Constant STIMSET_PARAM_SEGWVTYPE = 2
///@}

/// @name Ranges for different integer wave types
///
/// @anchor IntegerWaveRanges
///@{
Constant SIGNED_INT_16BIT_MIN = -32768
Constant SIGNED_INT_16BIT_MAX = 32767
///@}

/// @name Ranges for NIDAQ analog output in volts
///
/// @anchor NIDAQ_AO_WaveRanges
///@{
Constant NI_DAC_MIN = -10
Constant NI_DAC_MAX = 10
Constant NI_ADC_MIN = -10
Constant NI_ADC_MAX = 10
Constant NI_TTL_MIN = 0
Constant NI_TTL_MAX = 1
///@}

/// @name Ranges for Sutter DAQ analog output in volts
///
/// @anchor SUDAQ_WaveRanges
///@{
Constant SU_HS_IN_V_MIN = -1     // V
Constant SU_HS_IN_V_MAX = 1      // V
Constant SU_HS_IN_I_MIN = -20E-9 // A
Constant SU_HS_IN_I_MAX = 20E-9  // A
Constant SU_DAC_MIN     = -10    // V
Constant SU_DAC_MAX     = 10     // V
Constant SU_ADC_MIN     = -10    // V
Constant SU_ADC_MAX     = 10     // V
Constant SU_HS_OUT_MIN  = -1     // V
Constant SU_HS_OUT_MAX  = 1      // V
Constant SU_TTL_MIN     = 0      // V
Constant SU_TTL_MAX     = 1      // V
///@}

/// Maximum length of a valid object name in bytes in Igor Pro >= 8
Constant MAX_OBJECT_NAME_LENGTH_IN_BYTES = 255

/// (Deprecated) Maximum length of a valid object name in bytes in Igor Pro < 8
Constant MAX_OBJECT_NAME_LENGTH_IN_BYTES_SHORT = 31

StrConstant LABNOTEBOOK_NO_TOLERANCE = "-"
StrConstant LABNOTEBOOK_BINARY_UNIT  = "On/Off"
StrConstant LABNOTEBOOK_NO_UNIT      = ""

/// `Key` prefix for runtime added labnotebooks by ED_AddEntryToLabnotebook()
StrConstant LABNOTEBOOK_USER_PREFIX = "USER_"

StrConstant RA_ACQ_CYCLE_ID_KEY      = "Repeated Acq Cycle ID"
StrConstant STIMSET_ACQ_CYCLE_ID_KEY = "Stimset Acq Cycle ID"
StrConstant SKIP_SWEEPS_KEY          = "Skip Sweeps"
StrConstant SKIP_SWEEPS_SOURCE_KEY   = "Skip Sweeps source"

/// @name Update flags for DAP_UpdateDAQControls()
///
/// @anchor UpdateControlsFlags
///@{
Constant REASON_STIMSET_CHANGE         = 0x01
Constant REASON_HEADSTAGE_CHANGE       = 0x02
Constant REASON_STIMSET_CHANGE_DUR_DAQ = 0x04
///@}

/// Parameters for GetLastSetting() for using the row caching
/// mechanism.
Constant LABNOTEBOOK_GET_RANGE = -1

/// @name Mode parameters for OVS_GetSelectedSweeps()
///@{
Constant OVS_SWEEP_SELECTION_INDEX   = 0x0
Constant OVS_SWEEP_SELECTION_SWEEPNO = 0x1
Constant OVS_SWEEP_ALL_SWEEPNO       = 0x2
///@}

/// @name Export type parameters for NWB_ExportWithDialog()
///@{
Constant NWB_EXPORT_DATA     = 0x1
Constant NWB_EXPORT_STIMSETS = 0x2
///@}

/// Maximum number of microsecond timers in Igor Pro
Constant MAX_NUM_MS_TIMERS = 10

/// @name PatchSeq various constants
///@{
Constant PSQ_BL_EVAL_RANGE = 500

Constant PSQ_DS_SPIKE_LEVEL = -20 // mV

StrConstant PSQ_CR_BEM = "Symmetric;Depolarized;Hyperpolarized"

/// @name Different bounds evaluation modes
/// @anchor PSQChirpBoundsEvaluationMode
///@{
Constant PSQ_CR_BEM_SYMMETRIC      = 0x0 // Upper and Lower
Constant PSQ_CR_BEM_DEPOLARIZED    = 0x1 // Upper
Constant PSQ_CR_BEM_HYPERPOLARIZED = 0x2 // Lower
///@}

Constant PSQ_SPIKE_LEVEL         = 0.01 // mV
Constant PSQ_RMS_SHORT_THRESHOLD = 0.07 // mV
Constant PSQ_RMS_LONG_THRESHOLD  = 0.5  // mV
Constant PSQ_TARGETV_THRESHOLD   = 1    // mV

Constant PSQ_CALC_METHOD_AVG = 0x1 // average
Constant PSQ_CALC_METHOD_RMS = 0x2 // root-mean-square (rms)

Constant PSQ_BL_FAILED = 1

StrConstant PSQ_BASELINE_CHUNK_SHORT_NAME_PREFIX         = "BLC"
StrConstant PSQ_BASELINE_CHUNK_SHORT_NAME_RE_MATCHER     = "^U_BLC[[:digit:]]+$"
StrConstant PSQ_BASELINE_SELECTION_SHORT_NAME_RE_MATCHER = "^U_BLS[[:digit:]]+$"
///@}

/// @name PatchSeq labnotebook constants
///
/// Use with CreateAnaFuncLBNKey() only.
///
/// The longest key must be tested in CheckLength().
///
/// @anchor PatchSeqLabnotebookFormatStrings
///@{
StrConstant PSQ_FMT_LBN_RB_DASCALE_EXC              = "%s DAScale exceeded"
StrConstant PSQ_FMT_LBN_STEPSIZE                    = "%s step size"
StrConstant PSQ_FMT_LBN_STEPSIZE_FUTURE             = "%s step size (fut.)"
StrConstant PSQ_FMT_LBN_SPIKE_DETECT                = "%s spike detected"
StrConstant PSQ_FMT_LBN_SPIKE_POSITIONS             = "%s spike positions"
StrConstant PSQ_FMT_LBN_SPIKE_COUNT                 = "%s spike count"
StrConstant PSQ_FMT_LBN_FINAL_SCALE                 = "%s final DAScale"
StrConstant PSQ_FMT_LBN_INITIAL_SCALE               = "%s initial DAScale"
StrConstant PSQ_FMT_LBN_RMS_SHORT_PASS              = "%s Chk%d S-RMS QC"
StrConstant PSQ_FMT_LBN_RMS_SHORT_THRESHOLD         = "%s S-RMS Threshold"
StrConstant PSQ_FMT_LBN_RMS_LONG_PASS               = "%s Chk%d L-RMS QC"
StrConstant PSQ_FMT_LBN_RMS_LONG_THRESHOLD          = "%s L-RMS Threshold"
StrConstant PSQ_FMT_LBN_TARGETV                     = "%s Chk%d T-V BL"
StrConstant PSQ_FMT_LBN_TARGETV_THRESHOLD           = "%s T-V Threshold"
StrConstant PSQ_FMT_LBN_TARGETV_PASS                = "%s Chk%d T-V BL QC"
StrConstant PSQ_FMT_LBN_LEAKCUR                     = "%s Chk%d Leak Current BL"
StrConstant PSQ_FMT_LBN_LEAKCUR_PASS                = "%s Chk%d Leak Current BL QC"
StrConstant PSQ_FMT_LBN_CHUNK_PASS                  = "%s Chk%d BL QC"
StrConstant PSQ_FMT_LBN_BL_QC_PASS                  = "%s BL QC"
StrConstant PSQ_FMT_LBN_SWEEP_PASS                  = "%s Sweep QC"
StrConstant PSQ_FMT_LBN_SET_PASS                    = "%s Set QC"
StrConstant PSQ_FMT_LBN_SAMPLING_PASS               = "%s Sampling interval QC"
StrConstant PSQ_FMT_LBN_PULSE_DUR                   = "%s Pulse duration"
StrConstant PSQ_FMT_LBN_SPIKE_DASCALE_ZERO          = "%s spike with zero"
StrConstant PSQ_FMT_LBN_RB_LIMITED_RES              = "%s limited resolut."
StrConstant PSQ_FMT_LBN_DA_FI_SLOPE                 = "%s f-I slope"
StrConstant PSQ_FMT_LBN_DA_AT_FI_OFFSET             = "%s f-I offset"
StrConstant PSQ_FMT_LBN_DA_FI_SLOPE_REACHED_PASS    = "%s f-I slope QC"
StrConstant PSQ_FMT_LBN_DA_OPMODE                   = "%s operation mode"
StrConstant PSQ_FMT_LBN_DA_AT_ENOUGH_FI_POINTS_PASS = "%s enough f-I pairs for line fit QC"
StrConstant PSQ_FMT_LBN_DA_AT_FREQ                  = "%s AP frequency"
StrConstant PSQ_FMT_LBN_DA_AT_FUTURE_DASCALES       = "%s DAScale values left"
StrConstant PSQ_FMT_LBN_DA_AT_FUTURE_DASCALES_PASS  = "%s DAScale values left QC"
StrConstant PSQ_FMT_LBN_DA_AT_MAX_DASCALE_NORM      = "%s Max. norm. DAScale step"
StrConstant PSQ_FMT_LBN_DA_AT_MAX_SLOPE             = "%s f-I maximum slope"
StrConstant PSQ_FMT_LBN_DA_AT_MIN_DASCALE_NORM      = "%s Min. norm. DAScale step"
StrConstant PSQ_FMT_LBN_DA_AT_RSA_DASCALE           = "%s DAScale from rheobase, supra, adaptive"
StrConstant PSQ_FMT_LBN_DA_AT_RSA_FI_OFFSETS        = "%s f-I offsets from rheobase, supra, adaptive"
StrConstant PSQ_FMT_LBN_DA_AT_RSA_FI_SLOPES         = "%s f-I slopes from rheobase, supra, adaptive"
StrConstant PSQ_FMT_LBN_DA_AT_RSA_FI_SLOPES_PASS    = "%s f-I slope QCs from rheobase, supra, adaptive"
StrConstant PSQ_FMT_LBN_DA_AT_RSA_FREQ              = "%s AP frequency from rheobase, supra, adaptive"
StrConstant PSQ_FMT_LBN_DA_AT_RSA_SWEEPS            = "%s passing sweep numbers from rheobase, supra, adaptive"
StrConstant PSQ_FMT_LBN_DA_AT_RSA_VALID_SLOPE_PASS  = "%s f-I initial slope valid from rheobase, supra, adaptive QC"
StrConstant PSQ_FMT_LBN_DA_AT_VALID_SLOPE_PASS      = "%s f-I slope valid QC"
StrConstant PSQ_FMT_LBN_CR_RESISTANCE               = "%s input resistance"
StrConstant PSQ_FMT_LBN_CR_INSIDE_BOUNDS            = "%s inside bounds"
StrConstant PSQ_FMT_LBN_CR_BOUNDS_ACTION            = "%s bounds action"
StrConstant PSQ_FMT_LBN_CR_CYCLES                   = "%s cycle x values"
StrConstant PSQ_FMT_LBN_CR_BOUNDS_STATE             = "%s bounds state"
StrConstant PSQ_FMT_LBN_CR_SPIKE_CHECK              = "%s spike check"
StrConstant PSQ_FMT_LBN_CR_INIT_UOD                 = "%s initial user onset delay"
StrConstant PSQ_FMT_LBN_CR_INIT_LPF                 = "%s initial low pass filter"
StrConstant PSQ_FMT_LBN_CR_STIMSET_QC               = "%s stimset QC"
StrConstant PSQ_FMT_LBN_SPIKE_PASS                  = "%s spike QC"
StrConstant PSQ_FMT_LBN_PB_RESISTANCE               = "%s pipette resistance"
StrConstant PSQ_FMT_LBN_PB_RESISTANCE_PASS          = "%s pipette resistance QC"
StrConstant PSQ_FMT_LBN_SE_RESISTANCE_A             = "%s seal resistance A"
StrConstant PSQ_FMT_LBN_SE_RESISTANCE_B             = "%s seal resistance B"
StrConstant PSQ_FMT_LBN_SE_RESISTANCE_MAX           = "%s seal resistance max"
StrConstant PSQ_FMT_LBN_SE_RESISTANCE_PASS          = "%s seal resistance QC"
StrConstant PSQ_FMT_LBN_SE_TESTPULSE_GROUP          = "%s test pulse group"
StrConstant PSQ_FMT_LBN_AVERAGEV                    = "%s Chk%d Average"
StrConstant PSQ_FMT_LBN_VM_FULL_AVG                 = "%s Full Average"
StrConstant PSQ_FMT_LBN_VM_FULL_AVG_ADIFF           = "%s Full Average absolute difference"
StrConstant PSQ_FMT_LBN_VM_FULL_AVG_ADIFF_PASS      = "%s Full Average absolute difference QC"
StrConstant PSQ_FMT_LBN_VM_FULL_AVG_RDIFF           = "%s Full Average relative difference"
StrConstant PSQ_FMT_LBN_VM_FULL_AVG_RDIFF_PASS      = "%s Full Average relative difference QC"
StrConstant PSQ_FMT_LBN_VM_FULL_AVG_PASS            = "%s Full Average QC"
StrConstant PSQ_FMT_LBN_AR_ACCESS_RESISTANCE        = "%s access resistance"
StrConstant PSQ_FMT_LBN_AR_ACCESS_RESISTANCE_PASS   = "%s access resistance QC"
StrConstant PSQ_FMT_LBN_AR_STEADY_STATE_RESISTANCE  = "%s steady state resistance"
StrConstant PSQ_FMT_LBN_AR_RESISTANCE_RATIO         = "%s access vs steady state ratio"
StrConstant PSQ_FMT_LBN_AR_RESISTANCE_RATIO_PASS    = "%s access vs steady state ratio QC"
StrConstant PSQ_FMT_LBN_ASYNC_PASS                  = "%s async QC"
///@}

StrConstant FMT_LBN_ANA_FUNC_VERSION = "%s version"

/// @name PatchSeq and MultiPatchSeq types of analysis functions
/// @anchor SpecialAnalysisFunctionTypes
///
/// Constant values must *not* overlap between PSQ_XXX and MSQ_YYY.
///@{

Constant INVALID_ANALYSIS_FUNCTION = 0xFFFF
Constant TEST_ANALYSIS_FUNCTION    = 0x10000

/// Legacy analysis functions
///@{
Constant ADJUST_DA_SCALE      = 0x1000 // AD
Constant REACH_TARGET_VOLTAGE = 0x2000 // RV
///@}

/// Legacy analysis functions labnotebook entries
///
/// These are without analysis function prefixes.
///
///@{
StrConstant LBN_DELTA_I              = "Delta I"
StrConstant LBN_DELTA_V              = "Delta V"
StrConstant LBN_RESISTANCE_FIT       = "ResistanceFromFit"
StrConstant LBN_RESISTANCE_FIT_ERR   = "ResistanceFromFit_Err"
StrConstant LBN_AUTOBIAS_TARGET_DIAG = "Autobias target voltage from dialog"
///@}

/// @anchor PatchSeqAnalysisFunctionTypes
///@{
Constant PSQ_DA_SCALE        = 0x001
Constant PSQ_SQUARE_PULSE    = 0x002
Constant PSQ_RHEOBASE        = 0x004
Constant PSQ_RAMP            = 0x008
Constant PSQ_CHIRP           = 0x080
Constant PSQ_PIPETTE_BATH    = 0x100
Constant PSQ_SEAL_EVALUATION = 0x200
Constant PSQ_TRUE_REST_VM    = 0x400
Constant PSQ_ACC_RES_SMOKE   = 0x800
///@}

/// @anchor MultiPatchSeqAnalysisFunctionTypes
///@{
Constant MSQ_FAST_RHEO_EST = 0x010
Constant MSQ_DA_SCALE      = 0x020
Constant SC_SPIKE_CONTROL  = 0x040
///@}

///@}
///
/// @name PatchSeq SquarePulse
///@{
Constant PSQ_SP_INIT_AMP_m50     = -50e-12
Constant PSQ_SP_INIT_AMP_p100    = +100e-12
Constant PSQ_SP_INIT_AMP_p10     = +10e-12
Constant PSQ_SP_MAX_DASCALE_ZERO = 3
Constant PSQ_SP_NUM_SWEEPS_PASS  = 1
///@}

/// @name PatchSeq Rheobase
///@{
Constant    PSQ_RB_MAX_DASCALE_DIFF     = 60e-12
Constant    PSQ_RB_DASCALE_SMALL_BORDER = 50e-12
Constant    PSQ_RB_DASCALE_STEP_LARGE   = 10e-12
Constant    PSQ_RB_DASCALE_STEP_SMALL   = 2e-12
StrConstant PSQ_RB_FINALSCALE_FAKE_KEY  = "PSQRheobaseFinalDAScaleFake"
///@}

/// @name PatchSeq DAScale
///@{
Constant    PSQ_DS_OFFSETSCALE_FAKE = 23              // pA
StrConstant PSQ_DS_SUB              = "Sub"
StrConstant PSQ_DS_SUPRA            = "Supra"
StrConstant PSQ_DS_ADAPT            = "AdaptiveSupra"
Constant    PSQ_DS_MAX_FREQ_OFFSET  = 2
Constant    PSQ_DS_SKIPPED_FI_SLOPE = -Inf

// minimum frequency distance between two measurements
Constant PSQ_DA_ABS_FREQUENCY_MIN_DISTANCE       = 15
Constant PSQ_DA_SLOPE_PERCENTAGE_DEFAULT         = 10
Constant PSQ_DA_NUM_POINTS_LINE_FIT              = 2
Constant PSQ_DA_NUM_SWEEPS_SATURATION            = 2
Constant PSQ_DA_NUM_INVALID_SLOPE_SWEEPS_ALLOWED = 3
Constant PSQ_DA_MAX_FREQUENCY_CHANGE_PERCENT     = 20
Constant PSQ_DA_DASCALE_STEP_WITH_MIN_MAX_FACTOR = 3

///@}

/// @name PatchSeq Ramp
///@{
Constant PSQ_RA_DASCALE_DEFAULT = 1 // pA
Constant PSQ_RA_NUM_SWEEPS_PASS = 3
///@}

/// @name PatchSeq Chirp
///@{
Constant PSQ_CR_NUM_SWEEPS_PASS  = 3
Constant PSQ_CR_RESISTANCE_FAKE  = 1    // GΩ
Constant PSQ_CR_BASELINE_V_FAKE  = 1    // mV
Constant PSQ_CR_LIMIT_BAND_LOW   = 1    // mV
Constant PSQ_CR_LIMIT_BAND_HIGH  = 100  // mV
Constant PSQ_CR_USE_TRUE_RMP_DEF = 1
Constant PSQ_CR_DEFAULT_LPF      = 10e3 // Hz
///@}

/// @name PatchSeq Pipette
///@{
Constant PSQ_PB_NUM_SWEEPS_PASS = 1
///@}

/// @name PatchSeq SealCheck
///@{
Constant PSQ_SE_NUM_SWEEPS_PASS = 1
Constant PSQ_SE_REQUIRED_EPOCHS = 22
///@}

/// @name Testpulse Group Selector values, see also PSQ_SE_ParseTestpulseGroupSelection()
///@{
Constant PSQ_SE_TGS_FIRST  = 0x1
Constant PSQ_SE_TGS_SECOND = 0x2
Constant PSQ_SE_TGS_BOTH   = 0x3
///@}

/// @name PatchSeq True Resting Membrane Potential
///@{
Constant PSQ_VM_NUM_SWEEPS_PASS = 1
Constant PSQ_VM_REQUIRED_EPOCHS = 3
///@}

/// @name Bounds action values, see also PSQ_CR_BoundsActionToString()
/// @anchor ChirpBoundsAction
///@{
Constant PSQ_CR_PASS     = 0x1
Constant PSQ_CR_DECREASE = 0x2
Constant PSQ_CR_INCREASE = 0x4
Constant PSQ_CR_RERUN    = 0x8
///@}

/// @name PatchSeq AccessResistance
///@{
Constant PSQ_AR_NUM_SWEEPS_PASS = 1
///@}

/// @name MultiPatchSeq various constants
///@{
Constant MSQ_FRE_INIT_AMP_m50  = -50e-12
Constant MSQ_FRE_INIT_AMP_p100 = +100e-12
Constant MSQ_FRE_INIT_AMP_p10  = +10e-12

Constant MSQ_DS_PULSE_DUR = 1000

Constant MSQ_DS_OFFSETSCALE_FAKE = 23 // pA
Constant MSQ_DS_SWEEP_FAKE       = 42

Constant MSQ_SPIKE_LEVEL         = -10.0 // mV
Constant MSQ_RMS_SHORT_THRESHOLD = 0.07  // mV
Constant MSQ_RMS_LONG_THRESHOLD  = 0.5   // mV
Constant MSQ_TARGETV_THRESHOLD   = 1     // mV
///@}

/// @name MultiPatchSeq SpikeControl
///@{

/// @name Spike Counts state constants
/// @anchor SpikeCountsStateConstants
///@{
Constant SC_SPIKE_COUNT_NUM_GOOD     = 0x0
Constant SC_SPIKE_COUNT_NUM_TOO_FEW  = 0x1
Constant SC_SPIKE_COUNT_NUM_TOO_MANY = 0x2
Constant SC_SPIKE_COUNT_NUM_MIXED    = 0x4

StrConstant SC_SPIKE_COUNT_STATE_STR_GOOD     = "Good"
StrConstant SC_SPIKE_COUNT_STATE_STR_TOO_FEW  = "Too few"
StrConstant SC_SPIKE_COUNT_STATE_STR_TOO_MANY = "Too many"
StrConstant SC_SPIKE_COUNT_STATE_STR_MIXED    = "Mixed"
///@}

///@}

/// @anchor MultiPatchSeqLabnotebookFormatStrings
///@{
StrConstant MSQ_FMT_LBN_DASCALE_EXC         = "%s DAScale exceeded"
StrConstant MSQ_FMT_LBN_STEPSIZE            = "%s step size"
StrConstant MSQ_FMT_LBN_SPIKE_DETECT        = "%s spike detected"
StrConstant MSQ_FMT_LBN_SPIKE_POSITIONS     = "%s Spike positions"
StrConstant MSQ_FMT_LBN_SPIKE_COUNTS        = "%s Spike counts"
StrConstant MSQ_FMT_LBN_FINAL_SCALE         = "%s final DAScale"
StrConstant MSQ_FMT_LBN_INITIAL_SCALE       = "%s initial DAScale"
StrConstant MSQ_FMT_LBN_RMS_SHORT_PASS      = "%s Chk%d S-RMS QC"
StrConstant MSQ_FMT_LBN_RMS_LONG_PASS       = "%s Chk%d L-RMS QC"
StrConstant MSQ_FMT_LBN_TARGETV_PASS        = "%s Chk%d T-V BL QC"
StrConstant MSQ_FMT_LBN_CHUNK_PASS          = "%s Chk%d BL QC"
StrConstant MSQ_FMT_LBN_SPONT_SPIKE_PASS    = "%s Spontaneous Spiking QC"
StrConstant MSQ_FMT_LBN_HEADSTAGE_PASS      = "%s Headstage QC"
StrConstant MSQ_FMT_LBN_SWEEP_PASS          = "%s Sweep QC"
StrConstant MSQ_FMT_LBN_SET_PASS            = "%s Set QC"
StrConstant MSQ_FMT_LBN_PULSE_DUR           = "%s Pulse duration"
StrConstant MSQ_FMT_LBN_ACTIVE_HS           = "%s Active Headstage"
StrConstant MSQ_FMT_LBN_FAILED_PULSE_LEVEL  = "%s Failed Pulse Level"
StrConstant MSQ_FMT_LBN_SPIKE_POSITION_PASS = "%s Spike positions QC"
StrConstant MSQ_FMT_LBN_SPIKE_COUNTS_STATE  = "%s Spike counts state"
StrConstant MSQ_FMT_LBN_IDEAL_SPIKE_COUNTS  = "%s Ideal spike counts"
StrConstant MSQ_FMT_LBN_RERUN_TRIAL         = "%s Rerun Trials"
StrConstant MSQ_FMT_LBN_RERUN_TRIAL_EXC     = "%s Rerun Trials exceeded"
///@}

/// @name Workaround flags for CreateAnaFuncLBNKey()
/// @anchor LBNWorkAroundFlags
///@{
Constant PSQ_LBN_WA_NONE  = 0x0
Constant PSQ_LBN_WA_SP_SE = 0x1
///@}

Constant TP_MD_THREAD_DEAD_MAX_RETRIES  = 10
Constant DAQ_MD_THREAD_DEAD_MAX_RETRIES = 10

/// @todo: IP8 convert all call sites to use MultiThread/T=
Constant NUM_ENTRIES_FOR_MULTITHREAD = 16

/// Exclusive list of functions which are allowed to call
/// DQS_StartDAQSingleDevice()/DQM_StartDAQMultiDevice()
StrConstant DAQ_ALLOWED_FUNCTIONS = "DQ_RestartDAQ;DAP_ButtonProc_TPDAQ;RA_CounterMD"

StrConstant RESISTANCE_GRAPH = "AnalysisFuncResistanceGraph"
StrConstant SPIKE_FREQ_GRAPH = "SpikeFrequencyGraph"
StrConstant CHANNEL_UNIT_KEY = "ChannelUnit"

/// Maximum length of a sweep in the wavebuilder
Constant MAX_SWEEP_DURATION_IN_MS = 1.8e6 // 30 minutes

StrConstant REC_MACRO_PROCEDURE = "proc"
StrConstant REC_MACRO_MODE      = "mode"

/// @name Constants for the wave cache
///@{

/// @anchor CacheFetchOptions
///
/// Don't return a duplicate of the cached wave, but return the wave itself.
/// Useful if you use the wave cache as an alternative storage.
Constant CA_OPTS_NO_DUPLICATE = 0x1
///@}

Constant    LABNOTEBOOK_MISSING_VALUE  = -1
Constant    LABNOTEBOOK_UNCACHED_VALUE = -2
StrConstant LABNOTEBOOK_MOD_COUNT      = "Labnotebook modification count"

/// @name Constants for the different delta operation modes in the Wavebuilder
/// @anchor WaveBuilderDeltaOperationModes
///@{
Constant DELTA_OPERATION_DEFAULT   = 0
Constant DELTA_OPERATION_FACTOR    = 1
Constant DELTA_OPERATION_LOG       = 2
Constant DELTA_OPERATION_SQUARED   = 3
Constant DELTA_OPERATION_POWER     = 4
Constant DELTA_OPERATION_ALTERNATE = 5
Constant DELTA_OPERATION_EXPLICIT  = 6
///@}

Constant MINIMUM_FREE_DISK_SPACE = 10737418240 // 10GB

/// @name Stimset wave note entry types for WB_GetWaveNoteEntry()
/// @anchor StimsetWaveNoteEntryTypes
///@{
Constant VERSION_ENTRY = 0x1
Constant SWEEP_ENTRY   = 0x2
Constant EPOCH_ENTRY   = 0x4
Constant STIMSET_ENTRY = 0x8
///@}

/// @name Mode flag for AFH_GetListOfAnalysisParams()
/// @anchor GetListOfParamsModeFlags
///@{
Constant REQUIRED_PARAMS = 0x1
Constant OPTIONAL_PARAMS = 0x2
///@}

/// @name GUI settings oscilloscopy Y scale update modes
/// @anchor GUISettingOscilloscopeScaleMode
///@{
Constant GUI_SETTING_OSCI_SCALE_AUTO     = 0
Constant GUI_SETTING_OSCI_SCALE_FIXED    = 1
Constant GUI_SETTING_OSCI_SCALE_INTERVAL = 2
///@}

StrConstant PRESSURE_CONTROL_LED_DASHBOARD = "valdisp_DataAcq_P_LED_0;valdisp_DataAcq_P_LED_1;valdisp_DataAcq_P_LED_2;valdisp_DataAcq_P_LED_3;valdisp_DataAcq_P_LED_4;valdisp_DataAcq_P_LED_5;valdisp_DataAcq_P_LED_6;valdisp_DataAcq_P_LED_7"

/// @name Match expression types for GetListOfObjects
/// @anchor MatchExpressions
///@{
Constant MATCH_REGEXP   = 0x1
Constant MATCH_WILDCARD = 0x2
///@}

/// @name Options for SplitTTLWaveIntoComponents() and SplitSweepIntoComponents()
/// @anchor TTLRescalingOptions
///@{
Constant TTL_RESCALE_OFF = 0x0
Constant TTL_RESCALE_ON  = 0x1
///@}

/// @name Epoch key constants
/// @anchor EpochKeys
///@{
StrConstant EPOCH_OODDAQ_REGION_KEY   = "oodDAQRegion"
StrConstant EPOCH_BASELINE_REGION_KEY = "Baseline"
///@}

/// @name Time parameter for SWS_GetChannelGains()
/// @anchor GainTimeParameter
///@{
Constant GAIN_BEFORE_DAQ = 0x1
Constant GAIN_AFTER_DAQ  = 0x2
///@}

/// @brief User data on the stimset controls listing all stimsets in range
StrConstant USER_DATA_MENU_EXP = "MenuExp"

/// @name Find level edge types
/// @anchor FindLevelEdgeTypes
///@{
Constant FINDLEVEL_EDGE_INCREASING = 1
Constant FINDLEVEL_EDGE_DECREASING = 2
Constant FINDLEVEL_EDGE_BOTH       = 0
///@}

/// @name Find level modes
/// @anchor FindLevelModes
///@{
Constant FINDLEVEL_MODE_SINGLE = 1
Constant FINDLEVEL_MODE_MULTI  = 2
///@}

/// @name Return codes of the Igor exists function
/// @anchor existsReturnCodes
///@{
Constant EXISTS_NAME_NOT_USED   = 0
Constant EXISTS_AS_WAVE         = 1
Constant EXISTS_AS_VAR_OR_STR   = 2
Constant EXISTS_AS_FUNCTION     = 3
Constant EXISTS_AS_OPERATION    = 4
Constant EXISTS_AS_MACRO        = 5
Constant EXISTS_AS_USERFUNCTION = 6
///@}

/// @name Return codes of the Igor WinType function
/// @anchor wintypeReturnCodes
///@{
Constant WINTYPE_NOWINDOW = 0
Constant WINTYPE_GRAPH    = 1
Constant WINTYPE_TABLE    = 2
Constant WINTYPE_LAYOUT   = 3
Constant WINTYPE_NOTEBOOK = 5
Constant WINTYPE_PANEL    = 7
Constant WINTYPE_XOP      = 13
Constant WINTYPE_CAMERA   = 15
Constant WINTYPE_GIZMO    = 17
///@}

/// @name Panel tag codes to identify panel types, set in creation macro as main window userdata($EXPCONFIG_UDATA_PANELTYPE)
/// @anchor panelTags
///@{
StrConstant EXPCONFIG_UDATA_PANELTYPE = "Config_PanelType"

StrConstant PANELTAG_DAEPHYS         = "DA_Ephys"
StrConstant PANELTAG_DATABROWSER     = "DataBrowser"
StrConstant PANELTAG_WAVEBUILDER     = "WaveBuilder"
StrConstant PANELTAG_ANALYSISBROWSER = "AnalysisBrowser"
StrConstant PANELTAG_IVSCCP          = "IVSCControlPanel"
///@}

StrConstant EXPCONFIG_UDATA_SOURCEFILE_PATH  = "Config_FileName"
StrConstant EXPCONFIG_UDATA_SOURCEFILE_HASH  = "Config_FileHash"
StrConstant EXPCONFIG_UDATA_STIMSET_NWB_PATH = "Config_StimsetNWBPath"

/// @name Bit mask constants for properties for window control saving/restore
/// @anchor WindowControlSavingMask
///@{
Constant EXPCONFIG_SAVE_VALUE                    = 1
Constant EXPCONFIG_SAVE_POSITION                 = 2
Constant EXPCONFIG_SAVE_USERDATA                 = 4
Constant EXPCONFIG_SAVE_DISABLED                 = 8
Constant EXPCONFIG_SAVE_CTRLTYPE                 = 16
Constant EXPCONFIG_SAVE_POPUPMENU_AS_STRING_ONLY = 32
Constant EXPCONFIG_SAVE_POPUPMENU_AS_INDEX_ONLY  = 64
Constant EXPCONFIG_MINIMIZE_ON_RESTORE           = 128
Constant EXPCONFIG_SAVE_BUTTONS_ONLY_PRESSED     = 256
Constant EXPCONFIG_SAVE_ONLY_RELEVANT            = 512
///@}

/// @name Correlated control name/type/valuetype list for use with e.g. ControlInfo
/// @anchor IgorControlData
///@{
StrConstant EXPCONFIG_GUI_CTRLLIST    = "Button;Chart;CheckBox;CustomControl;GroupBox;ListBox;PopupMenu;SetVariable;Slider;TabControl;TitleBox;ValDisplay;"
StrConstant EXPCONFIG_GUI_CTRLTYPES   = "1;6;2;12;9;11;3;5;7;8;10;4;"
StrConstant EXPCONFIG_GUI_VVALUE      = "1;1;1;1;0;1;1;1;1;1;0;1;"
StrConstant EXPCONFIG_GUI_SVALUE      = "0;1;0;0;1;1;1;1;1;1;0;1;"
StrConstant EXPCONFIG_GUI_SDATAFOLDER = "0;0;0;0;0;1;0;1;1;0;1;0;"
/// 0 does not apply, 1 V_Value, 2 S_Value, 3 S_DataFolder for EXPCONFIG_SAVE_ONLY_RELEVANT
StrConstant EXPCONFIG_GUI_PREFERRED = "0;2;0;0;0;3;2;0;1;1;0;1;"

StrConstant EXPCONFIG_GUI_SUSERDATA = "1;0;1;1;0;1;1;1;1;1;0;0;"
///@}

/// @name PopupMenu extension keys for userdata definition of procedures
/// @anchor PopupMenuExtension
///@{
StrConstant PEXT_UDATA_ITEMGETTER = "Items"
StrConstant PEXT_UDATA_POPUPPROC  = "popupProc"
///@}

/// @name PopupMenu extension sub menu splitting methods
/// @anchor PEXT_SubMenuSplitting
///@{
Constant PEXT_SUBSPLIT_DEFAULT = 0
Constant PEXT_SUBSPLIT_ALPHA   = 1
///@}

/// @name PopupMenu extension sub menu name generation methods
/// @anchor PEXT_SubMenuNameGeneration
///@{
Constant PEXT_SUBNAMEGEN_DEFAULT = 0
///@}

/// @brief Wave note key for the indexing helper JSON document
StrConstant TUD_INDEX_JSON = "INDEX_JSON"

/// @brief sprintf field width for trace names
Constant TRACE_NAME_NUM_DIGITS = 6

/// Space used between numbers and their units
StrConstant NUMBER_UNIT_SPACE = "\u2006"

/// @name Incremental update modes for PostPlotTransformations()
/// @anchor PostPlotUpdateModes
///
///@{

Constant POST_PLOT_ADDED_SWEEPS    = 0x1 ///< The only change: Some sweeps were added
Constant POST_PLOT_REMOVED_SWEEPS  = 0x2 ///< The only change: Some sweeps were removed
Constant POST_PLOT_CONSTANT_SWEEPS = 0x4 ///< The displayed data in the databrowser stayed *constant* but some settings changed
Constant POST_PLOT_FULL_UPDATE     = 0x8 ///< Forces a complete update from scratch, use that if nothing else fits

///@}

/// @name Work Load Class names used in ASYNC frame work
/// @anchor AsyncWorkLoadClassNames
///
///@{
StrConstant WORKLOADCLASS_TP  = "TestPulse"
StrConstant WORKLOADCLASS_NWB = "nwb_writing"
///@}

/// @name Column numbers of epoch information
/// @anchor epochColumnNumber
///
///@{

Constant EPOCH_COL_STARTTIME = 0
Constant EPOCH_COL_ENDTIME   = 1
Constant EPOCH_COL_TAGS      = 2
Constant EPOCH_COL_TREELEVEL = 3

///@}
Constant PA_IMAGE_SPECIAL_ENTRIES_RANGE = 0.065
Constant PA_IMAGE_FAILEDMARKERSTART     = 0.9

StrConstant NOTE_NEEDS_UPDATE = "NeedsUpdate"

Constant GRAPH_DIV_SPACING = 0.03

StrConstant NOTE_PA_NEW_PULSES_START = "StartIndexOfNewPulses"

/// @name Modes for what PA_GetSetWaves returns
/// @anchor PAGetSetWavesModes
///
///@{

Constant PA_GETSETWAVES_ALL = 0x01
Constant PA_GETSETWAVES_OLD = 0x02
Constant PA_GETSETWAVES_NEW = 0x04

///@}

StrConstant PULSEWAVE_NOTE_SUFFIX        = "_note"
StrConstant PA_AVERAGE_WAVE_PREFIX       = "average_"
StrConstant PA_DECONVOLUTION_WAVE_PREFIX = "deconv_"

/// @name Indices into PA properties wave
/// @anchor PAPropertyWaveIndices
///
///@{

Constant PA_PROPERTIES_INDEX_SWEEP          = 0
Constant PA_PROPERTIES_INDEX_CHANNELNUMBER  = 1
Constant PA_PROPERTIES_INDEX_REGION         = 2
Constant PA_PROPERTIES_INDEX_HEADSTAGE      = 3
Constant PA_PROPERTIES_INDEX_PULSE          = 4
Constant PA_PROPERTIES_INDEX_PULSEHASFAILED = 5
Constant PA_PROPERTIES_INDEX_LASTSWEEP      = 6
Constant PA_PROPERTIES_INDEX_CLAMPMODE      = 7
///@}

/// @name Indices into PA propertiesWaves wave
/// @anchor PAPropertyWavesIndices
///
///@{

Constant PA_PROPERTIESWAVES_INDEX_PULSE     = 0
Constant PA_PROPERTIESWAVES_INDEX_PULSENOTE = 1

///@}

/// @name Header labels for draw groups within the json of a BufferedDrawInfo structure
///       Currently this method is only used in @sa CreateTiledChannelGraph
/// @anchor BDIHeaderLabels
///
///@{

StrConstant BUFFEREDDRAWAPPEND       = "AppendToGraph"
StrConstant BUFFEREDDRAWLABEL        = "Label"
StrConstant BUFFEREDDRAWHIDDENTRACES = "HiddenTraces"
StrConstant BUFFEREDDRAWDDAQAXES     = "dDAQAxes"

///@}

StrConstant TP_PROPERTIES_HASH = "TestPulsePropertiesHash"

StrConstant DASHBOARD_PASSING_MESSAGE    = "Pass"
StrConstant DAQ_STOPPED_EARLY_LEGACY_MSG = "DAQ was stopped early (n.a.)"

Constant MAX_DOUBLE_PRECISION = 15

StrConstant PACKAGE_MIES = "MIES"

StrConstant LOGFILE_NWB_MARKER = "### LOGFILE:JSONL ###"

/// @name National Instruments input configuration
/// @anchor NIAnalogInputConfigs
///@{
Constant HW_NI_CONFIG_RSE                 = 1 //< RSE terminal configuration
Constant HW_NI_CONFIG_NRSE                = 2 //< NRSE terminal configuration
Constant HW_NI_CONFIG_DIFFERENTIAL        = 4 //< Differential terminal configuration
Constant HW_NI_CONFIG_PSEUDO_DIFFERENTIAL = 8 //< Pseudodifferential terminal configuration
///@}

StrConstant PACKAGE_SETTINGS_JSON             = "Settings.json"
StrConstant PACKAGE_SETTINGS_USERPING         = "userping"
Constant    PACKAGE_SETTINGS_USERPING_DEFAULT = 1

StrConstant LOGFILE_NAME = "Log.jsonl"

Constant PSQ_CR_SPIKE_CHECK_DEFAULT = 1

StrConstant NOT_AVAILABLE = "n/a"

/// @name Flags for stopping DAQ
/// @anchor DAQStoppingFlags
///
///@{
Constant DQ_STOP_REASON_DAQ_BUTTON        = 0x0001
Constant DQ_STOP_REASON_CONFIG_FAILED     = 0x0002
Constant DQ_STOP_REASON_FINISHED          = 0x0004
Constant DQ_STOP_REASON_UNCOMPILED        = 0x0008
Constant DQ_STOP_REASON_HW_ERROR          = 0x0010
Constant DQ_STOP_REASON_ESCAPE_KEY        = 0x0020
Constant DQ_STOP_REASON_TP_STARTED        = 0x0040
Constant DQ_STOP_REASON_STIMSET_SELECTION = 0x0080
Constant DQ_STOP_REASON_UNLOCKED_DEVICE   = 0x0100
Constant DQ_STOP_REASON_OUT_OF_MEMORY     = 0x0200
Constant DQ_STOP_REASON_FIFO_TIMEOUT      = 0x0400
Constant DQ_STOP_REASON_STUCK_FIFO        = 0x0800
Constant DQ_STOP_REASON_INVALID           = 0xFFFF
///@}

/// @name Mode flags for ID_AskUserForSettings()
/// @anchor AskUserSettingsModeFlag
///
///@{
Constant ID_HEADSTAGE_SETTINGS = 0x1
Constant ID_POPUPMENU_SETTINGS = 0x2
///@}

Constant DND_STIMSET_DANDI_SET = 107

StrConstant WAVEBUILDER_DELTA_MODES = "None;Multiplier;Log;Squared;Power;Alternate;Explicit"

StrConstant WAVEBUILDER_TRIGGER_TYPES = "Sin;Cos"

/// @name Popup menu list types
/// @anchor PopupMenuListTypes
///@{
Constant POPUPMENULIST_TYPE_BUILTIN = 0x1 // COLORTABLEPOP, etc.
Constant POPUPMENULIST_TYPE_OTHER   = 0x2 // everything else
///@}

/// @name Possible log book types
/// @anchor LogbookTypes
///@{
Constant LBT_LABNOTEBOOK = 0x1
Constant LBT_TPSTORAGE   = 0x2
Constant LBT_RESULTS     = 0x4
///@}

/// @name Possible labnotebook wave types
/// @anchor LabnotebookWaveTypes
///@{
Constant LBN_NUMERICAL_KEYS   = 0x1
Constant LBN_NUMERICAL_VALUES = 0x2
Constant LBN_TEXTUAL_KEYS     = 0x4
Constant LBN_TEXTUAL_VALUES   = 0x8
///@}

/// @name Labnotebook wave names
///
/// @anchor LabnotebookWaveNames
///@{
StrConstant LBN_NUMERICAL_VALUES_NAME = "numericalValues"
StrConstant LBN_NUMERICAL_KEYS_NAME   = "numericalKeys"
StrConstant LBN_TEXTUAL_VALUES_NAME   = "textualValues"
StrConstant LBN_TEXTUAL_KEYS_NAME     = "textualKeys"
///@}

/// @name Labnotebook wave names
///
/// @anchor ResultLogbookWaveNames
///@{
StrConstant LBN_NUMERICALRESULT_VALUES_NAME = "numericalResultsValues"
StrConstant LBN_NUMERICALRESULT_KEYS_NAME   = "numericalResultsKeys"
StrConstant LBN_TEXTUALRESULT_VALUES_NAME   = "textualResultsValues"
StrConstant LBN_TEXTUALRESULT_KEYS_NAME     = "textualResultsKeys"
///@}

StrConstant LOGBOOK_WAVE_TEMP_FOLDER = "Temp"

/// @name All available ZeroMQ message filters
/// @anchor ZeroMQMessageFilters
///@{
StrConstant IVS_PUB_FILTER                = "ivscc"
StrConstant PRESSURE_STATE_FILTER         = "pressure:state"
StrConstant PRESSURE_SEALED_FILTER        = "pressure:sealed"
StrConstant PRESSURE_BREAKIN_FILTER       = "pressure:break in"
StrConstant AUTO_TP_FILTER                = "testpulse:autotune result"
StrConstant ZMQ_FILTER_TPRESULT_NOW       = "testpulse:results live"
StrConstant ZMQ_FILTER_TPRESULT_1S        = "testpulse:results 1s update"
StrConstant ZMQ_FILTER_TPRESULT_5S        = "testpulse:results 5s update"
StrConstant ZMQ_FILTER_TPRESULT_10S       = "testpulse:results 10s update"
StrConstant AMPLIFIER_CLAMP_MODE_FILTER   = "amplifier:clamp mode"
StrConstant AMPLIFIER_AUTO_BRIDGE_BALANCE = "amplifier:auto bridge balance"
StrConstant ANALYSIS_FUNCTION_PB          = "analysis function:pipette in bath"
StrConstant ANALYSIS_FUNCTION_SE          = "analysis function:seal evaluation"
StrConstant ANALYSIS_FUNCTION_VM          = "analysis function:true resting membrane potential"
StrConstant DAQ_TP_STATE_CHANGE_FILTER    = "data acquisition:state change"
StrConstant ANALYSIS_FUNCTION_AR          = "analysis function:access resistance smoke"
///@}

/// which is sufficient to represent each sample point time with a distinctive number up to rates of 10 MHz.
Constant EPOCHTIME_PRECISION = 7

StrConstant EPOCH_LIST_ROW_SEP = ":"
StrConstant EPOCH_LIST_COL_SEP = ","

/// These characters are not allowed to be in epoch tags
/// as they are used for serialization.
StrConstant EPOCH_TAG_INVALID_CHARS_REGEXP = "[:,]"

/// @name Possible cell state values
/// @anchor CellStateValues
///@{
Constant TPSTORAGE_SEALED = 0x1
///@}

Constant EPOCH_USER_LEVEL = -1

StrConstant EPOCH_SHORTNAME_USER_PREFIX = "U_"

/// @name SweepFormula display modes
/// @anchor SweepFormulaDisplayModes
///@{
Constant SF_DM_NORMAL     = 1
Constant SF_DM_SUBWINDOWS = 2
///@}

/// @name Parameters for GetTTLLabnotebookEntry()
/// @anchor LabnotebookTTLNames
///
///@{
StrConstant LABNOTEBOOK_TTL_STIMSETS       = "stim sets"
StrConstant LABNOTEBOOK_TTL_SETSWEEPCOUNTS = "set sweep counts"
StrConstant LABNOTEBOOK_TTL_SETCYCLECOUNTS = "set cycle counts"
///@}

/// @brief Mode flags for PGC_SetAndActivateControl
/// @anchor PGC_MODES
///@{
Constant PGC_MODE_ASSERT_ON_DISABLED = 0
Constant PGC_MODE_FORCE_ON_DISABLED  = 1
Constant PGC_MODE_SKIP_ON_DISABLED   = 2
///@}

Constant TP_BASELINE_FRACTION_LOW  = 0.25
Constant TP_BASELINE_FRACTION_HIGH = 0.49

StrConstant DAEPHYS_TP_CONTROLS_ALL        = "SetVar_DataAcq_TPDuration;SetVar_DataAcq_TPBaselinePerc;SetVar_DataAcq_TPAmplitude;SetVar_DataAcq_TPAmplitudeIC;setvar_Settings_TPBuffer;setvar_Settings_TP_RTolerance;Check_TP_SendToAllHS;check_DataAcq_AutoTP;setvar_DataAcq_IinjMax;setvar_DataAcq_targetVoltage;setvar_DataAcq_targetVoltageRange;setvar_Settings_autoTP_perc;setvar_Settings_autoTP_int"
StrConstant DAEPHYS_TP_CONTROLS_DEPEND     = "SetVar_DataAcq_TPAmplitude;SetVar_DataAcq_TPAmplitudeIC;check_DataAcq_AutoTP;setvar_DataAcq_IinjMax;setvar_DataAcq_targetVoltage;setvar_DataAcq_targetVoltageRange"
StrConstant DAEPHYS_TP_CONTROLS_INDEP      = "SetVar_DataAcq_TPDuration;SetVar_DataAcq_TPBaselinePerc;setvar_Settings_TPBuffer;setvar_Settings_TP_RTolerance;Check_TP_SendToAllHS;setvar_Settings_autoTP_perc;setvar_Settings_autoTP_int"
StrConstant DAEPHYS_TP_CONTROLS_NO_RESTART = "Check_TP_SendToAllHS;check_DataAcq_AutoTP;setvar_DataAcq_IinjMax;setvar_DataAcq_targetVoltage;setvar_DataAcq_targetVoltageRange;setvar_Settings_autoTP_perc;setvar_Settings_autoTP_int"

Constant TP_BASELINE_RATIO_HIGH = 0.285714 // 1 / 3.50
Constant TP_BASELINE_RATIO_OPT  = 0.25     // 1 / 4.00
Constant TP_BASELINE_RATIO_LOW  = 0.222222 // 1 / 4.50

Constant TP_AUTO_TP_CONSECUTIVE_PASSES            = 3
Constant TP_AUTO_TP_BASELINE_RANGE_EXCEEDED_FAILS = 3

Constant TP_OVERRIDE_RESULTS_AUTO_TP = 0x0

/// Possible result values for TP_AutoFitBaseline
/// @anchor TPBaselineFitResults
///@{
Constant TP_BASELINE_FIT_RESULT_OK    = 0
Constant TP_BASELINE_FIT_RESULT_ERROR = 1
// future space for more elaborated error codes
Constant TP_BASELINE_FIT_RESULT_TOO_NOISY = 32
///@}

/// Possible option values for TP_GetValuesFromTPStorage
/// @anchor TPStorageQueryingOptions
///@{
Constant TP_GETVALUES_DEFAULT            = 0x0
Constant TP_GETVALUES_LATEST_AUTOTPCYCLE = 0x1
///@}

/// Possible names for TSDS_Read*/TSDS_Write
/// @anchor ThreadsafeDataExchangeNames
///@{
StrConstant TSDS_BUGCOUNT = "BugCount"
///@}

/// Headstage contingency modes
///
/// @anchor HeadstageContingencyModes
///@{
Constant HCM_EMPTY  = 0x00
Constant HCM_DEPEND = 0x01
Constant HCM_INDEP  = 0x02
///@}

/// @name Decimation methods
/// @anchor DecimationMethods
///@{
Constant DECIMATION_NONE   = 0x0
Constant DECIMATION_MINMAX = 0x1
///@}

StrConstant DEFAULT_KEY_SEP  = ":"
StrConstant DEFAULT_LIST_SEP = ";"

/// \rst
///
/// =====  ======  ===============
/// Name   Symbol  Numerical value
/// =====  ======  ===============
/// yotta    Y        1e24
/// zetta    Z        1e21
/// exa      E        1e18
/// peta     P        1e15
/// tera     T        1e12
/// giga     G        1e9
/// mega     M        1e6
/// kilo     k        1e3
/// hecto    h        1e2
/// deca     da       1e1
/// deci     d        1e-1
/// centi    c        1e-2
/// milli    m        1e-3
/// micro    mu       1e-6
/// nano     n        1e-9
/// pico     p        1e-12
/// femto    f        1e-15
/// atto     a        1e-18
/// zepto    z        1e-21
/// yocto    y        1e-24
/// =====  ======  ===============
///
/// \endrst
///
/// From: 9th edition of the SI Brochure (2019), https://www.bipm.org/en/publications/si-brochure
StrConstant PREFIX_SHORT_LIST = ";Y;Z;E;P;T;G;M;k;h;da;d;c;m;mu;n;p;f;a;z;y"
StrConstant PREFIX_LONG_LIST  = "one;yotta;zetta;exa;peta;tera;giga;mega;kilo;hecto;deca;deci;centi;milli;micro;nano;pico;femto;atto;zepto;yocto"
StrConstant PREFIX_VALUE_LIST = "1;1e24;1e21;1e18;1e15;1e12;1e9;1e6;1e3;1e2;1e1;1e-1;1e-2;1e-3;1e-6;1e-9;1e-12;1e-15;1e-18;1e-21;1e-24"

/// @name Possible return values for PSQ_DetermineSweepQCResults()
/// @anchor DetermineSweepQCReturns
///@{
Constant PSQ_RESULTS_DONE = 0x1
Constant PSQ_RESULTS_CONT = 0x2
///@}

/// @name Possible mode parameters for AdaptDependentControls
/// @anchor DependentControlModes
///@{
Constant DEP_CTRLS_SAME   = 0x1
Constant DEP_CTRLS_INVERT = 0x2
///@}

Constant FIRST_XOP_ERROR = 10000 ///< Smaller error codes are from Igor Pro

/// @name Returned bits of DataFolderRefStatus
/// @anchor DataFolderRefStatusConstants
///@{
Constant DFREF_VALID = 0x1
Constant DFREF_FREE  = 0x2
///@}

/// @name Called once names
/// @anchor CalledOnceNames
///@{
StrConstant CO_EMPTY_DAC_LIST     = "emptyDACList"
StrConstant CO_SF_TOO_MANY_TRACES = "SF_tooManyTraces"
StrConstant CO_PSX_CLIPPED_STATS  = "psx_clippedStats"
StrConstant CO_ARCHIVE_ONCE       = "ArchiveLogs"
///@}

/// @name Constants for SweepFormula Meta data in JSON format
/// @anchor SFMetaDataConstants
///@{
StrConstant SF_META_DATATYPE             = "/DataType"           // string
StrConstant SF_META_SWEEPNO              = "/SweepNumber"        // number
StrConstant SF_META_RANGE                = "/Range"              // numeric wave
StrConstant SF_META_CHANNELTYPE          = "/ChannelType"        // number
StrConstant SF_META_CHANNELNUMBER        = "/ChannelNumber"      // number
StrConstant SF_META_DEVICE               = "/Device"             // string
StrConstant SF_META_EXPERIMENT           = "/Experiment"         // string
StrConstant SF_META_SWEEPMAPINDEX        = "/SweepMapIndex"      // number
StrConstant SF_META_ISAVERAGED           = "/IsAveraged"         // number
StrConstant SF_META_AVERAGED_FIRST_SWEEP = "/AveragedFirstSweep" // number
StrConstant SF_META_XVALUES              = "/XValues"            // numeric wave
StrConstant SF_META_XTICKLABELS          = "/XTickLabels"        // text wave
StrConstant SF_META_XTICKPOSITIONS       = "/XTickPositions"     // numeric wave
StrConstant SF_META_XAXISLABEL           = "/XAxisLabel"         // string
StrConstant SF_META_YAXISLABEL           = "/YAxisLabel"         // string
StrConstant SF_META_LEGEND_LINE_PREFIX   = "/LegendLinePrefix"   // string
StrConstant SF_META_OPSTACK              = "/OperationStack"     // string
StrConstant SF_META_MOD_MARKER           = "/Marker"             // numeric wave
StrConstant SF_META_SHOW_LEGEND          = "/ShowLegend"         // numeric, boolean, defaults to true (1)
StrConstant SF_META_CUSTOM_LEGEND        = "/CustomLegend"       // string with custom legend text, honours /ShowLegend
StrConstant SF_META_ARGSETUPSTACK        = "/ArgSetupStack"      // string
StrConstant SF_META_TRACECOLOR           = "/TraceColor"         // numeric wave, applies to markers and lines
StrConstant SF_META_LINESTYLE            = "/LineStyle"          // number
StrConstant SF_META_TRACE_MODE           = "/TraceMode"          // number
StrConstant SF_META_TRACETOFRONT         = "/TraceToFront"       // number, boolean, defaults to false (0)
StrConstant SF_META_DONOTPLOT            = "/DoNotPlot"          // number, boolean, defaults to false (0)

StrConstant SF_META_USER_GROUP = "/User/" // custom metadata for individual operations,
// top-level group with individual entries
StrConstant SF_META_FIT_COEFF     = "FitCoefficients"
StrConstant SF_META_FIT_SIGMA     = "FitSigma"
StrConstant SF_META_FIT_PARAMETER = "FitParameter"

StrConstant SF_DATATYPE_SWEEP               = "SweepData"
StrConstant SF_DATATYPE_SWEEPNO             = "SweepNumbers"
StrConstant SF_DATATYPE_CHANNELS            = "Channels"
StrConstant SF_DATATYPE_SELECTCOMP          = "SelectionComposite"
StrConstant SF_DATATYPE_SELECT              = "Selection"
StrConstant SF_DATATYPE_FINDLEVEL           = "FindLevel"
StrConstant SF_DATATYPE_APFREQUENCY         = "ApFrequency"
StrConstant SF_DATATYPE_LABNOTEBOOK         = "LabNotebook"
StrConstant SF_DATATYPE_BUTTERWORTH         = "Butterworth"
StrConstant SF_DATATYPE_AREA                = "Area"
StrConstant SF_DATATYPE_INTEGRATE           = "Integrate"
StrConstant SF_DATATYPE_DERIVATIVE          = "Derivative"
StrConstant SF_DATATYPE_STDEV               = "StDev"
StrConstant SF_DATATYPE_VARIANCE            = "Variance"
StrConstant SF_DATATYPE_RMS                 = "RMS"
StrConstant SF_DATATYPE_AVG                 = "Average"
StrConstant SF_DATATYPE_MAX                 = "Max"
StrConstant SF_DATATYPE_MIN                 = "Min"
StrConstant SF_DATATYPE_RANGE               = "Range"
StrConstant SF_DATATYPE_EPOCHS              = "Epochs"
StrConstant SF_DATATYPE_TP                  = "TestPulse"
StrConstant SF_DATATYPE_TPSS                = "TestPulseMode_SteadyState"
StrConstant SF_DATATYPE_TPINST              = "TestPulseMode_Instantaneous"
StrConstant SF_DATATYPE_TPBASE              = "TestPulseMode_Baseline"
StrConstant SF_DATATYPE_TPFIT               = "TestPulseMode_Fit"
StrConstant SF_DATATYPE_POWERSPECTRUM       = "Powerspectrum"
StrConstant SF_DATATYPE_PSX                 = "PSX"
StrConstant SF_DATATYPE_SELECTVIS           = "SelectVis"
StrConstant SF_DATATYPE_SELECTEXP           = "SelectExp"
StrConstant SF_DATATYPE_SELECTDEV           = "SelectDev"
StrConstant SF_DATATYPE_SELECTEXPANDSCI     = "SelectExpandSCI"
StrConstant SF_DATATYPE_SELECTEXPANDRAC     = "SelectExpandRAC"
StrConstant SF_DATATYPE_SELECTCM            = "SelectClampMode"
StrConstant SF_DATATYPE_SELECTSTIMSET       = "selectStimset"
StrConstant SF_DATATYPE_SELECTIVSCCSWEEPQC  = "selectIVSCCSweepQC"
StrConstant SF_DATATYPE_SELECTIVSCCSETQC    = "selectIVSCCSetQC"
StrConstant SF_DATATYPE_SELECTRANGE         = "selectRange"
StrConstant SF_DATATYPE_SELECTSETCYCLECOUNT = "SelectSetCycleCount"
StrConstant SF_DATATYPE_SELECTSETSWEEPCOUNT = "SelectSetSweepCount"
StrConstant SF_DATATYPE_SELECTSCIINDEX      = "SelectSCIIndex"
StrConstant SF_DATATYPE_SELECTRACINDEX      = "SelectRACIndex"

StrConstant SF_WREF_MARKER     = "\"WREF@\":"
StrConstant SF_VARIABLE_MARKER = "/SF_IsVariable" // numeric
///@}

/// @name Constants for SweepFormula Clampmode codes returned by operation selcm()
/// @anchor SFClampcodeConstants
/// @{
Constant SF_OP_SELECT_CLAMPCODE_ALL   = 0x0F
Constant SF_OP_SELECT_CLAMPCODE_NONE  = 0x01
Constant SF_OP_SELECT_CLAMPCODE_IC    = 0x02
Constant SF_OP_SELECT_CLAMPCODE_VC    = 0x04
Constant SF_OP_SELECT_CLAMPCODE_IZERO = 0x08
/// @}

/// @name Constants for SweepFormula IVSCC SweepQC codes returned by operation selivsccsweepqc()
/// @anchor SFIVSCCSweepQCConstants
/// @{
Constant SF_OP_SELECT_IVSCCSWEEPQC_IGNORE = 0x01
Constant SF_OP_SELECT_IVSCCSWEEPQC_PASSED = 0x02
Constant SF_OP_SELECT_IVSCCSWEEPQC_FAILED = 0x04
/// @}

/// @name Constants for SweepFormula IVSCC SetQC codes returned by operation selivsccsetqc()
/// @anchor SFIVSCCSetQCConstants
/// @{
Constant SF_OP_SELECT_IVSCCSETQC_IGNORE = 0x01
Constant SF_OP_SELECT_IVSCCSETQC_PASSED = 0x02
Constant SF_OP_SELECT_IVSCCSETQC_FAILED = 0x04
/// @}

/// @name Available source options for RA_SkipSweeps()
/// @anchor SkipSweepOptions
///@{
Constant SWEEP_SKIP_USER = 0x1
Constant SWEEP_SKIP_AUTO = 0x2
///@}

/// @name Public constants from MIES_Configuration
/// @anchor ExpConfigUserData
///@{
StrConstant EXPCONFIG_UDATA_EXCLUDE_SAVE    = "Config_DontSave"
StrConstant EXPCONFIG_UDATA_EXCLUDE_RESTORE = "Config_DontRestore"
///@}

/// @name FFT Window Functions
/// @anchor FFTWinFunctions
///@{
StrConstant FFT_WINF         = "Bartlet;Bartlett;Blackman367;Blackman361;Blackman492;Blackman474;Cos1;Cos2;Cos3;Cos4;Hamming;Hanning;KaiserBessel20;KaiserBessel25;KaiserBessel30;Parzen;Poisson2;Poisson3;Poisson4;Riemann;SFT3F;SFT3M;FTNI;SFT4F;SFT5F;SFT4M;FTHP;HFT70;FTSRS;SFT5M;HFT90D;HFT95;HFT116D;HFT144D;HFT169D;HFT196D;HFT223D;HFT248D;"
StrConstant FFT_WINF_DEFAULT = "Hanning"
///@}

/// @name Types for DB_GetBoundDataBrowser
/// @anchor BrowserModes
///@{
Constant BROWSER_MODE_USER       = 0x01
Constant BROWSER_MODE_AUTOMATION = 0x02
Constant BROWSER_MODE_ALL        = 0xFF
///@}

Constant THREAD_QUEUE_TRIES            = 1000
Constant HARDWARE_ITC_FIFO_ERROR       = -1
Constant HARDWARE_ITC_STUCK_FIFO_TICKS = 120  // 2s

StrConstant SF_PLOT_NAME_TEMPLATE = "SweepFormula plot"
StrConstant SFH_USER_DATA_BROWSER = "browser"

/// @name Available result types for SFH_CreateResultsWaveWithCode()
/// @anchor ResultTypes
///@{
Constant SFH_RESULT_TYPE_STORE      = 0x01
Constant SFH_RESULT_TYPE_PSX_EVENTS = 0x02
Constant SFH_RESULT_TYPE_PSX_MISC   = 0x04
///@}

/// @name Constants used in the wave note JSON support
/// @anchor WaveNoteJSONSupportConstants
///@{
StrConstant WAVE_NOTE_EMPTY_JSON     = "{}"
StrConstant WAVE_NOTE_JSON_SEPARATOR = "\rJSON_BEGIN\r"
///@}

/// @name Different log modes for ModifyGraph/Axes
/// @anchor ModifyGraphLogModes
///@{
Constant MODIFY_GRAPH_LOG_MODE_NORMAL = 0
Constant MODIFY_GRAPH_LOG_MODE_LOG10  = 1
Constant MODIFY_GRAPH_LOG_MODE_LOG2   = 2
///@}

StrConstant FILE_LIST_SEP = "|"

/// @name Constants for EqualWaves mode
/// @anchor EqualWavesConstants
///@{
Constant EQWAVES_DATA          = 1
Constant EQWAVES_DATATYPE      = 2
Constant EQWAVES_SCALING       = 4
Constant EQWAVES_DATAUNITS     = 8
Constant EQWAVES_DIMUNITS      = 16
Constant EQWAVES_DIMLABELS     = 32
Constant EQWAVES_WAVENOTE      = 64
Constant EQWAVES_LOCKSTATE     = 128
Constant EQWAVES_DATAFULLSCALE = 256
Constant EQWAVES_DIMSIZE       = 512
Constant EQWAVES_ALL           = -1
///@}

/// @name Igor reserved layer dim labels for ListBox GUI control
/// @anchor ListBoxLayerDimLabels
///@{
StrConstant LISTBOX_LAYER_FOREGROUND = "foreColors"
StrConstant LISTBOX_LAYER_BACKGROUND = "backColors"
///@}

/// @name MIES Settings paths
/// @anchor SettingsPaths
///@{
StrConstant SETTINGS_AB_FOLDER             = "/analysisbrowser/directory"
StrConstant SETTINGS_AB_FOLDER_OLD_DEFAULT = "C:"
///@}

StrConstant ANALYSIS_BROWSER_NAME = "AnalysisBrowser"

StrConstant MEMORY_REFCOUNTER_DF = "MemoryReferenceCounterDF"

StrConstant LOG_ACTION_ASSERT = "assert"
StrConstant LOG_MESSAGE_KEY   = "msg"
StrConstant LOG_ACTION_REPORT = "report"

/// Poorly understood difference required for vertical direction for MoveSubWindow
Constant SUBWINDOW_MOVE_CORRECTION = 5

/// @name Constants for Hash/WaveHash
/// @anchor HashMethods
///@{
Constant HASH_SHA2_256 = 1
///@}

// see DisplayHelpTopic "LoadWave"
Constant LOADWAVE_V_FLAGS_IGNORECOLEND                = 0x01
Constant LOADWAVE_V_FLAGS_WCOLSPACEBLANK              = 0x02
Constant LOADWAVE_V_FLAGS_DISABLELINEPRECOUNTING      = 0x04
Constant LOADWAVE_V_FLAGS_DISABLEUNESCAPEBACKSLASH    = 0x08
Constant LOADWAVE_V_FLAGS_DISABLESUPPORTQUOTEDSTRINGS = 0x10

Constant MEGABYTE = 1048576

Constant STRING_MAX_SIZE = 2147483647

Constant LOGUPLOAD_PAYLOAD_SPLITSIZE = 104857600
Constant LOG_ARCHIVING_SPLITSIZE     = 524288000
Constant LOG_MAX_LINESIZE            = 2097152

StrConstant LOG_FILE_LINE_END = "\n"

/// @name Igor Pro week days
/// @anchor WeekDays
///@{
Constant SUNDAY    = 1
Constant MONDAY    = 2
Constant TUESDAY   = 3
Constant WEDNESDAY = 4
Constant THURSDAY  = 5
Constant FRIDAY    = 6
Constant SATURDAY  = 7
///@}

Constant SECONDS_PER_DAY = 86400

/// @name DataBrowser visualisation constants
/// @anchor DataBrowserVisualizationConstants
///@{
StrConstant DB_AXIS_PART_EPOCHS = "_EP"
///@}

StrConstant SF_OP_PSX               = "psx"
StrConstant SF_OP_PSX_KERNEL        = "psxKernel"
StrConstant SF_OP_PSX_STATS         = "psxStats"
StrConstant SF_OP_PSX_RISETIME      = "psxRiseTime"
StrConstant SF_OP_PSX_PREP          = "psxPrep"
StrConstant SF_OP_PSX_DECONV_FILTER = "psxDeconvFilter"

/// @name Available PSX states
/// @anchor PSXStates
///@{
Constant PSX_ACCEPT = 0x01
Constant PSX_REJECT = 0x02
Constant PSX_UNDET  = 0x04
Constant PSX_LAST   = 0x04 // neeeds to be the same as the last valid state
Constant PSX_ALL    = 0x07
///@}

/// @name Available PSX state types
/// @anchor PSXStateTypes
///@{
Constant PSX_STATE_EVENT = 0x1
Constant PSX_STATE_FIT   = 0x2
Constant PSX_STATE_BOTH  = 0x3
///@}

StrConstant PSX_EVENTS_COMBO_KEY_WAVE_NOTE = "comboKey"

Constant PSX_MARKER_ACCEPT = 19
Constant PSX_MARKER_REJECT = 23
Constant PSX_MARKER_UNDET  = 18

/// @name Custom error codes for PSX_FitEventDecay()
/// @anchor FitEventDecayCustomErrors
///@{
Constant PSX_DECAY_FIT_ERROR = -10000
///@}

StrConstant PSX_STATS_LABELS = "Average;Median;Average Deviation;Standard deviation;Skewness;Kurtosis"

/// @name Horizontal offset modes in all event graph
///
/// Corresponds to zero-based indizes of popup_event_offset
///
/// @anchor HorizOffsetModesAllEvent
///@{
Constant PSX_HORIZ_OFFSET_ONSET = 0
Constant PSX_HORIZ_OFFSET_PEAK  = 1
///@}

Constant PSX_DECONV_FILTER_DEF_LOW   = 0.002
Constant PSX_DECONV_FILTER_DEF_HIGH  = 0.004
Constant PSX_DECONV_FILTER_DEF_ORDER = 101

StrConstant SF_OP_MERGE   = "merge"
StrConstant SF_OP_FIT     = "fit"
StrConstant SF_OP_FITLINE = "fitline"
StrConstant SF_OP_DATASET = "dataset"

StrConstant SWEEP_NOTE_KEY_ORIGCREATIONTIME_UTC = "OriginalCreationTimeInUTC"

StrConstant DF_NAME_FREE = "freeroot"
StrConstant DF_NAME_MIES = "MIES"

Constant SUTTER_MAX_MAX_TP_PULSES = 10000

Constant INVALID_SWEEP_NUMBER = -1

StrConstant PERCENT_F_MAX_PREC = "%.15f"

/// @name Igor Internal Abort Codes
///
/// @anchor IgorAbortCodes
///@{
Constant ABORTCODE_ABORTONRTE    = -4
Constant ABORTCODE_ABORT         = -3
Constant ABORTCODE_STACKOVERFLOW = -2
Constant ABORTCODE_USERABORT     = -1
///@}

// If this constant with dimLabels is changed the following functions should be verified:
//
// TP_TSAnalysis
// GetTPResultAsyncBuffer
// GetTPResults (reuses same dimlabels partially)
StrConstant TP_ANALYSIS_DATA_LABELS = "BASELINE;STEADYSTATERES;INSTANTRES;ELEVATED_SS;ELEVATED_INST;NOW;HEADSTAGE;MARKER;NUMBER_OF_TP_CHANNELS;TIMESTAMP;TIMESTAMPUTC;CLAMPMODE;CLAMPAMP;BASELINEFRAC;CYCLEID;TPLENGTHPOINTSADC;PULSELENGTHPOINTSADC;PULSESTARTPOINTSADC;SAMPLINGINTERVALADC;TPLENGTHPOINTSDAC;PULSELENGTHPOINTSDAC;PULSESTARTPOINTSDAC;SAMPLINGINTERVALDAC;"
