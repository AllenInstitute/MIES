#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_CONST
#endif

/// @file MIES_Constants.ipf
/// @brief Global constants

/// @defgroup BackgroundFunctions All background functions

/// @name Constans for the number of channels
/// @anchor NUM_CHANNELS_CONSTANTS
/// @{
Constant NUM_DA_TTL_CHANNELS   = 8
Constant NUM_HEADSTAGES        = 8
Constant NUM_AD_CHANNELS       = 16
Constant NUM_ASYNC_CHANNELS    = 8
Constant NUM_ITC_TTL_BITS_PER_RACK = 4
/// @}

/// Maximum values of @ref NUM_CHANNELS_CONSTANTS
Constant NUM_MAX_CHANNELS      = 16

StrConstant DEVICE_TYPES_ITC = "ITC16;ITC18;ITC1600;ITC00;ITC16USB;ITC18USB"
StrConstant DEVICE_NUMBERS   = "0;1;2;3;4;5;6;7;8;9;10"

StrConstant ITC1600_FIRST_DEVICE = "ITC1600_Dev_0"
StrConstant BASE_WINDOW_TITLE    = "DA_Ephys"
StrConstant DATABROWSER_WINDOW_TITLE = "DataBrowser"
StrConstant SWEEPBROWSER_WINDOW_TITLE = "SweepBrowser"
StrConstant EXT_PANEL_SETTINGSHISTORY = "SettingsHistoryPanel"

/// @name Task names
/// @anchor MiesTasknames
/// @{
StrConstant TASKNAME_TP        = "Testpulse"
StrConstant TASKNAME_TPMD      = "TestpulseMD"
StrConstant TASKNAME_TIMER     = "ITC_Timer"
StrConstant TASKNAME_TIMERMD   = "ITC_TimerMD"
StrConstant TASKNAME_FIFOMON   = "ITC_FIFOMonitor"
StrConstant TASKNAME_FIFOMONMD = "ITC_FIFOMonitorMD"
StrConstant TASKNAMES          = "Testpulse;TestpulseMD;ITC_Timer;ITC_TimerMD;ITC_FIFOMonitor;ITC_FIFOMonitorMD;"
/// @}

/// @name Various mies specific regular expressions
/// @anchor MiesRegexps
/// @{
StrConstant DATA_SWEEP_REGEXP        = "(?i)^Sweep_[[:digit:]]+$"
StrConstant DATA_CONFIG_REGEXP       = "(?i)^Config_Sweep_[[:digit:]]+$"
StrConstant TP_STORAGE_REGEXP        = "(?i)^TPStorage(_[[:digit:]]+)?$"
StrConstant STORED_TESTPULSES_REGEXP = "(?i)^StoredTestPulses_([[:digit:]]+)$"
StrConstant DATA_SWEEP_REGEXP_BAK    = "(?i)^Sweep_[[:digit:]]+_bak$"
StrConstant DATA_CONFIG_REGEXP_BAK   = "(?i)^Config_Sweep_[[:digit:]]+_bak$"
/// @}

StrConstant UNTITLED_EXPERIMENT           = "Untitled"
StrConstant PACKED_FILE_EXPERIMENT_SUFFIX = ".pxp"

/// Amount of free memory required to perform data aquisition in GB
Constant FREE_MEMORY_LOWER_LIMIT = 0.75

/// @name Pressure Control constants
/// @{
/// Max and min pressure regulator pressure in psi
Constant MAX_REGULATOR_PRESSURE =  9.9
Constant MIN_REGULATOR_PRESSURE = -9.9
/// @}

/// @name Latest version of config wave
/// @anchor ItcConfigWaveVersion
/// @{
Constant ITC_CONFIG_WAVE_VERSION = 2
/// @}

StrConstant ITC_CHANNEL_NAMES    = "AD;DA;;TTL"

/// @name Channel constants shared with the ITC XOP
/// @anchor ItcXopChannelConstants
/// @{
Constant ITC_XOP_CHANNEL_TYPE_ADC = 0
Constant ITC_XOP_CHANNEL_TYPE_DAC = 1
Constant ITC_XOP_CHANNEL_TYPE_TTL = 3
/// @}

/// @name DAQ Channel Type constants used in ITCChanConfigWave
/// @anchor DaqChannelTypeConstants
/// @{
Constant DAQ_CHANNEL_TYPE_UNKOWN = -1
Constant DAQ_CHANNEL_TYPE_DAQ    = 1
Constant DAQ_CHANNEL_TYPE_TP     = 2
/// @}

/// @name When all DAQ Channels are set to TestPulse the output runs for TIME_TP_ONLY_ON_DAQ seconds
/// @anchor TimeTpOnlyOnDaqConstant
/// @{
Constant TIME_TP_ONLY_ON_DAQ = 1
/// @}


Constant MINIMUM_WAVE_SIZE = 64
Constant MINIMUM_WAVE_SIZE_LARGE = 2048
Constant MAXIMUM_WAVE_SIZE = 16384 // 2^14

/// @name Wave dimension constants
/// @anchor WaveDimensions
/// Convenience definition to nicify expressions like DimSize(wv, ROWS)
/// easier to read than DimSize(wv, 0).
/// @{
Constant ROWS                = 0
Constant COLS                = 1
Constant LAYERS              = 2
Constant CHUNKS              = 3
/// @}
Constant MAX_DIMENSION_COUNT = 4

/// @name append userData constants
/// Convenience definition.
/// easier to read than ModifyGraph userData(trace)={name, 0, value}
/// @{
Constant USERDATA_MODIFYGRAPH_REPLACE = 0
Constant USERDATA_MODIFYGRAPH_APPEND  = 1
/// @}

/// @name Constants used by Downsample
/// @{
Constant DECIMATION_BY_OMISSION  = 1
Constant DECIMATION_BY_SMOOTHING = 2
Constant DECIMATION_BY_AVERAGING = 4
StrConstant ALL_WINDOW_FUNCTIONS = "Bartlett;Blackman367;Blackman361;Blackman492;Blackman474;Cos1;Cos2;Cos3;Cos4;Hamming;Hanning;KaiserBessel20;KaiserBessel25;KaiserBessel30;None;Parzen;Poisson2;Poisson3;Poisson4;Riemann"
/// @}

/// Common string to denote an invalid entry in a popupmenu
StrConstant NONE = "- none -"

/// Hook events constants
Constant EVENT_KILL_WINDOW_HOOK = 2

/// Used by CheckName and UniqueName
Constant CONTROL_PANEL_TYPE = 9

/// @name CountObjects, CountObjectsDFR, GetIndexedObjName, GetIndexedObjNameDFR constants
/// @anchor TypeFlags
/// @{
Constant COUNTOBJECTS_WAVES      = 1
Constant COUNTOBJECTS_VAR        = 2
Constant COUNTOBJECTS_STR        = 3
Constant COUNTOBJECTS_DATAFOLDER = 4
/// @}

/// @name Control types from ControlInfo
/// @anchor GUIControlTypes
/// @{
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
/// @}

StrConstant CURSOR_NAMES = "A;B;C;D;E;F;G;H;I;J"

// Conversion factor from ticks to seconds, exact value is 1/60
Constant TICKS_TO_SECONDS = 0.0166666666666667

StrConstant TRASH_FOLDER_PREFIX     = "trash"
StrConstant SIBLING_FILENAME_SUFFIX = "sibling"

StrConstant NOTE_INDEX = "Index"

///@name   Parameters for FindIndizes
///@anchor FindIndizesProps
///@{
Constant PROP_NON_EMPTY                = 0x01 ///< Wave entry is not NaN or ""
Constant PROP_EMPTY                    = 0x02 ///< Wave entry is NaN or ""
Constant PROP_MATCHES_VAR_BIT_MASK     = 0x04 ///< Wave entry matches the bitmask given in var
Constant PROP_NOT_MATCHES_VAR_BIT_MASK = 0x08 ///< Wave entry does not match the bitmask given in var
///@}

/// @name Parameters for GetPanelControl and IDX_GetSetsInRange, GetSetFolder, GetSetParamFolder and GetChanneListFromITCConfig
/// @anchor ChannelTypeAndControlConstants
/// @{
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
/// @}

/// @name Controls for multiple channels have negative channel indizes
/// @anchor AllHeadstageModeConstants
/// @{
Constant CHANNEL_INDEX_ALL         = -1
Constant CHANNEL_INDEX_ALL_V_CLAMP = -2
Constant CHANNEL_INDEX_ALL_I_CLAMP = -3
Constant CHANNEL_INDEX_ALL_I_ZERO  = -4
/// @}

/// @name Constants for the bitmask entries stored in the selection wave
///       of a ListBox
/// @anchor ListBoxSelectionWaveFlags
/// @{
Constant LISTBOX_SELECTED              = 0x01
Constant LISTBOX_CELL_EDITABLE         = 0x02
Constant LISTBOX_CELL_DOUBLECLICK_EDIT = 0x04
Constant LISTBOX_SHIFT_SELECTION       = 0x08
Constant LISTBOX_CHECKBOX_SELECTED     = 0x10
Constant LISTBOX_CHECKBOX              = 0x20
Constant LISTBOX_TREEVIEW_EXPANDED     = 0x10 ///< Convenience definition, equal to #LISTBOX_CHECKBOX_SELECTED
Constant LISTBOX_TREEVIEW              = 0x40
/// @}

Constant INITIAL_KEY_WAVE_COL_COUNT = 4

/// @name Constants for the note of the wave returned by GetTPStorage
/// @{
StrConstant AUTOBIAS_LAST_INVOCATION_KEY   = "AutoBiasLastInvocation"
StrConstant DIMENSION_SCALING_LAST_INVOC   = "DimensionScalingLastInvocation"
StrConstant PRESSURE_CTRL_LAST_INVOC       = "PressureControlLastInvocation"
StrConstant INDEX_ON_TP_START              = "IndexOnTestPulseStart"
/// @}

/// @name Modes for SaveExperimentSpecial
/// @anchor SaveExperimentModes
/// @{
Constant SAVE_AND_CLEAR            = 0x01
Constant SAVE_AND_SPLIT            = 0x02
/// @}

/// @name Constants for data acquisition modes
/// @anchor DataAcqModes
/// @{
Constant UNKNOWN_MODE            = NaN
Constant DATA_ACQUISITION_MODE   = 0
Constant TEST_PULSE_MODE         = 1
Constant NUMBER_OF_LBN_DAQ_MODES = 3
/// @}

/// @name Constants for three Amplifier modes
/// @anchor AmplifierClampModes
/// @{
Constant V_CLAMP_MODE      = 0
Constant I_CLAMP_MODE      = 1
Constant I_EQUAL_ZERO_MODE = 2
/// @}

Constant NUM_CLAMP_MODES = 3

/// @name Possible values for the function parameter of AI_SendToAmp
/// @anchor AI_SendToAmpConstants
/// @{
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
Constant MCC_END_INVALID_FUNC            = 10052
// MCC primary and secondary are not required
/// @}

Constant CHECKBOX_SELECTED     = 1
Constant CHECKBOX_UNSELECTED   = 0

/// @name Constants for FunctionInfo and WaveType
///
/// @anchor IgorTypes
/// @{
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
Constant IGOR_TYPE_NULL_WAVE        = 0x000
Constant IGOR_TYPE_NUMERIC_WAVE     = 0x001
Constant IGOR_TYPE_TEXT_WAVE        = 0x002
Constant IGOR_TYPE_DFREF_WAVE       = 0x003
Constant IGOR_TYPE_WAVEREF_WAVE     = 0x004
// If wavetype is called with selector 2
//Constant IGOR_TYPE_NULL_WAVE      = 0x000
Constant IGOR_TYPE_GLOBAL_WAVE      = 0x001
Constant IGOR_TYPE_FREE_WAVE        = 0x002
Constant IGOR_TYPE_FREEDF_WAVE      = 0x002
/// @}

/// @name TabControl values in Browser Settings Panel
/// @{
Constant MIES_BSP_OVS = 1
Constant MIES_BSP_CS  = 2
Constant MIES_BSP_AR  = 3
Constant MIES_BSP_PA  = 4
Constant MIES_BSP_SF  = 5
/// @}

/// @name values for  UserData in BrowserSettings and derived windows
/// @{
strConstant MIES_BSP_BROWSER = "BROWSER"
strConstant MIES_BSP_DEVICE = "DEVICE"
strConstant MIES_BSP_PANEL_FOLDER = "PANEL_FOLDER"
strConstant MIES_BSP_AR_SWEEPFOLDER = "AR_SWEEPFOLDER"
strConstant MIES_BSP_PA_MAINPANEL = "HOSTWINDOW"
/// @}

StrConstant NUMERALS = "First;Second;Third;Fourth;Fifth;Sixth;Seventh;Eighth"

/// Generic axis name for graphs using split axis
StrConstant VERT_AXIS_BASE_NAME   = "row"
StrConstant HORIZ_AXIS_BASE_NAME  = "col"

/// Fallback value for  the sampling interval in milliseconds (1e-3) used by
/// #SI_CalculateMinSampInterval if the lookup table could not be found on disk.
Constant SAMPLING_INTERVAL_FALLBACK = 0.050

/// @name Constants for the type flag of `LoadData`
/// @anchor LoadDataConstants
/// @{
Constant LOAD_DATA_TYPE_WAVES   = 1
Constant LOAD_DATA_TYPE_NUMBERS = 2
Constant LOAD_DATA_TYPE_STRING  = 4
/// @}

/// @name Constants for the time alignment mode of TimeAlignmentIfReq
/// @anchor TimeAlignmentConstants
/// @{
Constant TIME_ALIGNMENT_NONE          = -1
Constant TIME_ALIGNMENT_LEVEL_RISING  = 0
Constant TIME_ALIGNMENT_LEVEL_FALLING = 1
Constant TIME_ALIGNMENT_MIN           = 2
Constant TIME_ALIGNMENT_MAX           = 3
/// @}

StrConstant WAVE_BACKUP_SUFFIX = "_bak"

/// @name Test pulse modes
/// @anchor TestPulseRunModes
/// @{
Constant TEST_PULSE_NOT_RUNNING      = 0x000
Constant TEST_PULSE_BG_SINGLE_DEVICE = 0x001
Constant TEST_PULSE_BG_MULTI_DEVICE  = 0x002
Constant TEST_PULSE_FG_SINGLE_DEVICE = 0x004
Constant TEST_PULSE_DURING_RA_MOD    = 0x100 ///< Or'ed with the testpulse mode. Special casing for testpulse during DAQ/RA/ITI
// foreground multi device does not exist
/// @}

/// @name Data acquisition modes
/// @anchor DAQRunModes
/// @{
Constant DAQ_NOT_RUNNING      = 0x000
Constant DAQ_BG_SINGLE_DEVICE = 0x001
Constant DAQ_BG_MULTI_DEVICE  = 0x002
Constant DAQ_FG_SINGLE_DEVICE = 0x004
// foreground multi device does not exist
/// @}

/// @name Reserved Stim set name for TP while DAQ
/// @anchor ReservedStimSetName
/// @{
StrConstant STIMSET_TP_WHILE_DAQ = "TestPulse"
/// @}

/// @name Constants for GetAxisOrientation
/// @anchor AxisOrientationConstants
/// @{
Constant AXIS_ORIENTATION_HORIZ  = 0x01
Constant AXIS_ORIENTATION_BOTTOM = 0x05
Constant AXIS_ORIENTATION_TOP    = 0x09
Constant AXIS_ORIENTATION_VERT   = 0x02
Constant AXIS_ORIENTATION_LEFT   = 0x12
Constant AXIS_ORIENTATION_RIGHT  = 0x22
/// @}

/// @name Constants for Set/GetAxesRanges modes, use binary pattern
/// @anchor AxisRangeModeConstants
/// @{
Constant AXIS_RANGE_DEFAULT        = 0x00
Constant AXIS_RANGE_USE_MINMAX     = 0x01
Constant AXIS_RANGE_INC_AUTOSCALED = 0x02
/// @}

/// @name Constants for Axis name template
/// @anchor AxisNameTemplates
/// @{
StrConstant AXIS_SCOPE_AD        = "AD"
StrConstant AXIS_SCOPE_AD_REGEXP = "AD[0123456789]+"
StrConstant AXIS_SCOPE_TP_TIME   = "top"
/// @}

/// @name Constants for DAP_ToggleAcquisitionButton
/// @anchor ToggleAcquisitionButtonConstants
/// @{
Constant DATA_ACQ_BUTTON_TO_STOP = 0x01
Constant DATA_ACQ_BUTTON_TO_DAQ  = 0x02
/// @}

/// @name Constants for DAP_ToggleTestpulseButton
/// @anchor ToggleTestpulseButtonConstants
/// @{
Constant TESTPULSE_BUTTON_TO_STOP  = 0x01
Constant TESTPULSE_BUTTON_TO_START = 0x02
/// @}

/// @name Constants for functions using rack number parameters
/// @anchor RackConstants
/// @{
Constant RACK_ZERO = 0x00
Constant RACK_ONE  = 0x01
/// @}

StrConstant STIM_WAVE_NAME_KEY = "Stim Wave Name"

/// Last valid row index for storing epoch types in #GetSegmentTypeWave
Constant SEGMENT_TYPE_WAVE_LAST_IDX = 93

/// Minimum logarithm to base two for the ITCDataWave size
Constant MINIMUM_ITCDATAWAVE_EXPONENT = 20

/// Minimum value for the baseline fraction of the Testpulse in percent
Constant MINIMUM_TP_BASELINE_PERCENTAGE = 25

/// @name Return types of @ref GetInternalSetVariableType
/// @anchor GetInternalSetVariableTypeReturnTypes
/// @{
Constant SET_VARIABLE_BUILTIN_NUM = 0x01
Constant SET_VARIABLE_BUILTIN_STR = 0x02
Constant SET_VARIABLE_GLOBAL      = 0x04
/// @}

Constant DISABLE_CONTROL_BIT = 2
Constant HIDDEN_CONTROL_BIT  = 1

/// @name Event types for analysis functions
/// @anchor EVENT_TYPE_ANALYSIS_FUNCTIONS
/// @{
Constant PRE_DAQ_EVENT    = 0
Constant MID_SWEEP_EVENT  = 1
Constant POST_SWEEP_EVENT = 2
Constant POST_SET_EVENT   = 3
Constant POST_DAQ_EVENT   = 4
Constant PRE_SWEEP_EVENT  = 5
Constant PRE_SET_EVENT    = 7
/// @}

Constant GENERIC_EVENT = 6 ///< Only used for internal bookkeeping. Never
                           ///  send to analysis functions.

/// Number of @ref EVENT_TYPE_ANALYSIS_FUNCTIONS
Constant TOTAL_NUM_EVENTS   = 8

/// Column for GetAnalysisFunctionStorage(). Same value as #TOTAL_NUM_EVENTS
/// but more readable.
Constant ANALYSIS_FUNCTION_PARAMS = 8

StrConstant ANALYSIS_FUNCTION_PARAMS_LBN = "Function params (encoded)"
StrConstant ANALYSIS_FUNCTION_PARAMS_STIMSET = "Function params (encoded)"

/// Human readable names for @ref EVENT_TYPE_ANALYSIS_FUNCTIONS
StrConstant EVENT_NAME_LIST = "Pre DAQ;Mid Sweep;Post Sweep;Post Set;Post DAQ;Pre Sweep;Generic;Pre Set"

/// Labnotebook entries
StrConstant EVENT_NAME_LIST_LBN = "Pre DAQ function;Mid Sweep function;Post Sweep function;Post Set function;Post DAQ function;Pre Sweep function;Generic function;Pre Set function"

/// List of valid analysis function types
/// @anchor AnalysisFunctionParameterTypes
StrConstant ANALYSIS_FUNCTION_PARAMS_TYPES = "variable;string;wave;textwave"

/// @name Special return values for analysis functions. See also @ref
/// AnalysisFunctionReturnTypes.
///
/// @anchor AnalysisFuncReturnTypesConstants
/// @{
Constant ANALYSIS_FUNC_RET_REPURP_TIME = -100
Constant ANALYSIS_FUNC_RET_EARLY_STOP  = -101
/// @}

/// @name Constants for differentiating between different analysis function versions
/// @anchor AnalysisFunctionVersions
/// @{
Constant ANALYSIS_FUNCTION_VERSION_V1  = 0x0001
Constant ANALYSIS_FUNCTION_VERSION_V2  = 0x0002
Constant ANALYSIS_FUNCTION_VERSION_V3  = 0x0004
Constant ANALYSIS_FUNCTION_VERSION_ALL = 0xFFFF
/// @}

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

Constant MAX_COMMANDLINE_LENGTH = 2500

StrConstant WAVEBUILDER_COMBINE_FORMULA_VER = "1"

/// Conversion factor between volts and bits for the AD/DA channels
/// The ITC 16 bit range is +-10.24 V such that a value of 32000 represents exactly 10 V, thus 3200 -> 1 V.
Constant HARDWARE_ITC_BITS_PER_VOLT = 3200

/// @name Trigger modes
/// External trigger is used for yoking multiple ITC 1600 devices
/// @anchor TriggerModeStartAcq
/// @{
Constant HARDWARE_DAC_DEFAULT_TRIGGER  = 0x0
Constant HARDWARE_DAC_EXTERNAL_TRIGGER = 0x1
/// @}

/// Used to upgrade the GuiStateWave as well as the DA Ephys panel
Constant DA_EPHYS_PANEL_VERSION           = 49
Constant DATA_SWEEP_BROWSER_PANEL_VERSION = 22
Constant WAVEBUILDER_PANEL_VERSION         = 8

/// Version of the labnotebooks (numerical and textual)
///
/// Has to be increased on the following occasions:
/// - New/Removed entries
/// - Changed names of entries
/// - Changed units or meaning of entries
/// - New/Changed layers of entries
Constant LABNOTEBOOK_VERSION = 38

/// Version of the stimset wave note
Constant STIMSET_NOTE_VERSION = 7

/// @name The channel numbers for the different ITC devices used for accesssing
///       the TTLs
/// @{
Constant HARDWARE_ITC_TTL_DEF_RACK_ZERO  = 1
Constant HARDWARE_ITC_TTL_1600_RACK_ZERO = 0
Constant HARDWARE_ITC_TTL_1600_RACK_ONE  = 3
/// @}

/// @name Flags for all hardware interaction functions from MIES_DAC-Hardware.ipf
/// @anchor HardwareInteractionFlags
/// @{
Constant HARDWARE_ABORT_ON_ERROR        = 0x01
Constant HARDWARE_PREVENT_ERROR_POPUP   = 0x02
Constant HARDWARE_PREVENT_ERROR_MESSAGE = 0x04
/// @}

/// List of different DAC hardware types
StrConstant HARDWARE_DAC_TYPES = "ITC;NI"

/// @name Indizes into HARDWARE_DAC_TYPES
/// @anchor HardwareDACTypeConstants
/// @{
Constant HARDWARE_ITC_DAC = 0
Constant HARDWARE_NI_DAC  = 1
Constant HARDWARE_UNSUPPORTED_DAC  = 1000
/// @}

/// @name Name of NI_DAC FIFO
/// @anchor NIDAQ FIFO Name
/// @{
StrConstant HARDWARE_NI_ADC_FIFO = "NI_AnalogIn"
/// @}

/// We always use this DIO port for NI hardware
Constant HARDWARE_NI_TTL_PORT = 0

Constant HARDWARE_MAX_DEVICES = 10

/// @name Minimum possible sampling intervals in milliseconds (1e-3s)
/// @{
#ifdef EVIL_KITTEN_EATING_MODE
Constant HARDWARE_NI_DAC_MIN_SAMPINT  = 0.2
#else
Constant HARDWARE_NI_DAC_MIN_SAMPINT  = 0.002 ///< NI 6343 and other devices, so it is 4E-3 ms for 2 channels, 6E-3 ms for 3 a.s.o.
#endif
Constant HARDWARE_ITC_MIN_SAMPINT     = 0.005 ///< ITC DACs
Constant HARDWARE_NI_6001_MIN_SAMPINT = 0.2   ///< NI 6001 USB
/// @}

Constant WAVEBUILDER_MIN_SAMPINT    = 0.005
Constant WAVEBUILDER_MIN_SAMPINT_HZ = 200e3 ///< Stimulus sets are created with that frequency

StrConstant CHANNEL_DA_SEARCH_STRING  = "*DA*"
StrConstant CHANNEL_TTL_SEARCH_STRING = "*TTL*"

/// @name Constants for the return value of AI_SelectMultiClamp()
/// @anchor AISelectMultiClampReturnValues
/// @{
Constant AMPLIFIER_CONNECTION_SUCCESS    = 0 ///< success
Constant AMPLIFIER_CONNECTION_INVAL_SER  = 1 ///< stored amplifier serials are invalid
Constant AMPLIFIER_CONNECTION_MCC_FAILED = 2 ///< calling MCC_SelectMultiClamp700B failed
/// @}

/// Additional entry in the NWB source attribute for TTL data
StrConstant NWB_SOURCE_TTL_BIT = "TTLBit"
StrConstant IPNWB_PLACEHOLDER = "PLACEHOLDER"

/// @name Convenience constants for DAP_UpdateClampmodeTabs() and DAP_ChangeHeadStageMode()
/// @anchor MCCSyncOverrides
/// @{
Constant DO_MCC_MIES_SYNCING   = 0x0
Constant SKIP_MCC_MIES_SYNCING = 0x1
Constant NO_SLIDER_MOVEMENT    = 0x2
/// @}

/// Number of trials to find a suitable port for binding a ZeroMQ service
Constant ZEROMQ_NUM_BIND_TRIALS = 32

Constant ZEROMQ_BIND_REP_PORT = 5670

/// @name Constants for AnalysisBrowserMap (Text Wave)
/// @{
StrConstant ANALYSISBROWSER_FILE_TYPE_IGOR = "I"
StrConstant ANALYSISBROWSER_FILE_TYPE_NWB  = "N"
/// @}

/// Convenience definition for functions interacting with threads
Constant MAIN_THREAD = 0

/// @name Available pressure modes for P_SetPressureMode()
/// @anchor PressureModeConstants
/// @{
Constant PRESSURE_METHOD_ATM      = -1
Constant PRESSURE_METHOD_APPROACH = 0
Constant PRESSURE_METHOD_SEAL     = 1
Constant PRESSURE_METHOD_BREAKIN  = 2
Constant PRESSURE_METHOD_CLEAR    = 3
Constant PRESSURE_METHOD_MANUAL   = 4
/// @}

/// @name Different pressure types of each headstage
/// @anchor PressureTypeConstants
/// @{
Constant PRESSURE_TYPE_ATM    = -1
Constant PRESSURE_TYPE_AUTO   =  0
Constant PRESSURE_TYPE_MANUAL =  1
Constant PRESSURE_TYPE_USER   =  2
/// @}

StrConstant POPUPMENU_DIVIDER = "\\M1(-"

/// @name Constants for different WaveBuilder epochs
/// Numbers are stored in the SegWvType waves, so they are part of our "API".
/// @anchor WaveBuilderEpochTypes
/// @{
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
/// @}

/// Used for the textual wavebuilder parameter wave `WPT` as that stores
/// the set parameters in layer 0. Coincides with `EPOCH_TYPE_SQUARE_PULSE`.
Constant INDEP_EPOCH_TYPE = 0

/// @name Parameters for gnoise and enoise
///@{
Constant NOISE_GEN_LINEAR_CONGRUENTIAL = 1 ///< Don't use for new code.
Constant NOISE_GEN_MERSENNE_TWISTER    = 2
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

StrConstant NOTE_KEY_ZEROED               = "Zeroed"
StrConstant NOTE_KEY_TIMEALIGN            = "TimeAlign"
StrConstant NOTE_KEY_ARTEFACT_REMOVAL     = "ArtefactRemoval"
StrConstant NOTE_KEY_SEARCH_FAILED_PULSE  = "SearchFailedPulses"
StrConstant NOTE_KEY_FAILED_PULSE_LEVEL   = "FailedPulseLevel"

/// DA_Ephys Panel Tabs
Constant DA_EPHYS_PANEL_DATA_ACQUISITION = 0
Constant DA_EPHYS_PANEL_DA = 1
Constant DA_EPHYS_PANEL_AD = 2
Constant DA_EPHYS_PANEL_TTL = 3
Constant DA_EPHYS_PANEL_ASYNCHRONOUS = 4
Constant DA_EPHYS_PANEL_SETTINGS = 5
Constant DA_EPHYS_PANEL_HARDWARE = 6
Constant DA_EPHYS_PANEL_VCLAMP = 0
Constant DA_EPHYS_PANEL_ICLAMP = 1
Constant DA_EPHYS_PANEL_IEQUALZERO = 2
Constant DA_EPHYS_PANEL_PRESSURE_AUTO = 0
Constant DA_EPHYS_PANEL_PRESSURE_MANUAL = 1
Constant DA_EPHYS_PANEL_PRESSURE_USER = 2

StrConstant PULSE_START_TIMES_KEY     = "Pulse Train Pulses"
StrConstant PULSE_TO_PULSE_LENGTH_KEY = "Pulse To Pulse Length"
StrConstant HIGH_PREC_SWEEP_START_KEY = "High precision sweep start"
StrConstant STIMSET_SCALE_FACTOR_KEY  = "Stim Scale Factor"
StrConstant STIMSET_WAVE_NOTE_KEY     = "Stim Wave Note"
StrConstant EPOCHS_ENTRY_KEY          = "Epochs"

/// DA_Ephys controls which should be disabled during DAQ
StrConstant CONTROLS_DISABLE_DURING_DAQ = "Check_DataAcqHS_All;Radio_ClampMode_AllIClamp;Radio_ClampMode_AllVClamp;Radio_ClampMode_AllIZero;SetVar_Sweep;Check_DataAcq1_DistribDaq;Check_DataAcq1_dDAQOptOv;Check_DataAcq_Indexing;check_DataAcq_IndexRandom;Check_DataAcq1_IndexingLocked;check_DataAcq_RepAcqRandom;Check_DataAcq1_RepeatAcq;Check_Settings_SkipAnalysFuncs"
StrConstant CONTROLS_DISABLE_DURING_IDX = "SetVar_DataAcq_ListRepeats;SetVar_DataAcq_SetRepeats"

/// DA_Ephys controls which should be disabled during DAQ *and* TP
StrConstant CONTROLS_DISABLE_DURING_DAQ_TP = "Check_Settings_BkgTP;Check_Settings_BackgrndDataAcq"

/// @name Parameters for GetAllDevicesWithContent()
/// @anchor CONTENT_TYPES
/// @{
Constant CONTENT_TYPE_SWEEP     = 0x01
Constant CONTENT_TYPE_TPSTORAGE = 0x02
Constant CONTENT_TYPE_ALL       = 0xFF
/// @}

/// @name Parameter type flags for WB_GetParameterWaveName
///
/// @anchor ParameterWaveTypes
/// @{
Constant STIMSET_PARAM_WP        = 0
Constant STIMSET_PARAM_WPT       = 1
Constant STIMSET_PARAM_SEGWVTYPE = 2
/// @}

/// @name Ranges for different integer wave types
///
/// @anchor IntegerWaveRanges
/// @{
Constant SIGNED_INT_16BIT_MIN = -32768
Constant SIGNED_INT_16BIT_MAX =  32767
/// @}

/// @name Ranges for NIDAQ analog output in volts
///
/// @anchor NIDAQ_AO_WaveRanges
/// @{
Constant NI_DAC_MIN = -10
Constant NI_DAC_MAX =  10
Constant NI_ADC_MIN = -10
Constant NI_ADC_MAX =  10
/// @}

/// Maximum length of a valid object name in bytes in Igor Pro >= 8
Constant MAX_OBJECT_NAME_LENGTH_IN_BYTES = 255

/// (Deprecated) Maximum length of a valid object name in bytes in Igor Pro < 8
Constant MAX_OBJECT_NAME_LENGTH_IN_BYTES_SHORT = 31

StrConstant LABNOTEBOOK_NO_TOLERANCE = "-"
StrConstant LABNOTEBOOK_BINARY_UNIT  = "On/Off"

/// `Key` prefix for runtime added labnotebooks by ED_AddEntryToLabnotebook()
StrConstant LABNOTEBOOK_USER_PREFIX = "USER_"

StrConstant RA_ACQ_CYCLE_ID_KEY      = "Repeated Acq Cycle ID"
StrConstant STIMSET_ACQ_CYCLE_ID_KEY = "Stimset Acq Cycle ID"

/// @name Update flags for DAP_UpdateDAQControls()
///
/// @anchor UpdateControlsFlags
/// @{
Constant REASON_STIMSET_CHANGE         = 0x01
Constant REASON_HEADSTAGE_CHANGE       = 0x02
Constant REASON_STIMSET_CHANGE_DUR_DAQ = 0x04
/// @}

/// Parameters for GetLastSetting() for using the row caching
/// mechanism.
Constant LABNOTEBOOK_GET_RANGE = -1

/// @name Mode parameters for OVS_GetSelectedSweeps()
/// @{
Constant OVS_SWEEP_SELECTION_INDEX   = 0x0
Constant OVS_SWEEP_SELECTION_SWEEPNO = 0x1
Constant OVS_SWEEP_ALL_SWEEPNO       = 0x2
/// @}

/// @name Export type parameters for NWB_ExportWithDialog()
/// @{
Constant NWB_EXPORT_DATA     = 0x1
Constant NWB_EXPORT_STIMSETS = 0x2
/// @}

/// Maximum number of microsecond timers in Igor Pro
Constant MAX_NUM_MS_TIMERS = 10

/// @name PatchSeq various constants
/// @{
Constant PSQ_SP_INIT_AMP_m50      = -50e-12
Constant PSQ_SP_INIT_AMP_p100     = +100e-12
Constant PSQ_SP_INIT_AMP_p10      = +10e-12
Constant PSQ_NUM_MAX_DASCALE_ZERO = 3

Constant PSQ_RB_PRE_BL_EVAL_RANGE  = 500
Constant PSQ_RB_POST_BL_EVAL_RANGE = 500

Constant PSQ_DS_BL_EVAL_RANGE_MS = 500
Constant PSQ_DS_PULSE_DUR        = 1000

Constant PSQ_RA_BL_EVAL_RANGE = 500

Constant PSQ_SPIKE_LEVEL         = 0.01 // mV
Constant PSQ_RMS_SHORT_THRESHOLD = 0.07 // mV
Constant PSQ_RMS_LONG_THRESHOLD  = 0.5  // mV
Constant PSQ_TARGETV_THRESHOLD   = 1    // mV
/// @}

/// @name PatchSeq labnotebook constants
///
/// Use with PSQ_PSQ_CreateLBNKey() only.
///
/// The longest key must be tested in CheckLength().
///
/// @anchor PatchSeqLabnotebookFormatStrings
/// @{
StrConstant PSQ_FMT_LBN_RB_DASCALE_EXC     = "%s DAScale exceeded"
StrConstant PSQ_FMT_LBN_STEPSIZE           = "%s step size"
StrConstant PSQ_FMT_LBN_STEPSIZE_FUTURE    = "%s step size (fut.)"
StrConstant PSQ_FMT_LBN_SPIKE_DETECT       = "%s spike detected"
StrConstant PSQ_FMT_LBN_SPIKE_POSITIONS    = "%s spike positions"
StrConstant PSQ_FMT_LBN_SPIKE_COUNT        = "%s spike count"
StrConstant PSQ_FMT_LBN_FINAL_SCALE        = "%s final DAScale"
StrConstant PSQ_FMT_LBN_INITIAL_SCALE      = "%s initial DAScale"
StrConstant PSQ_FMT_LBN_RMS_SHORT_PASS     = "%s Chk%d S-RMS QC"
StrConstant PSQ_FMT_LBN_RMS_LONG_PASS      = "%s Chk%d L-RMS QC"
StrConstant PSQ_FMT_LBN_TARGETV_PASS       = "%s Chk%d T-V BL QC"
StrConstant PSQ_FMT_LBN_CHUNK_PASS         = "%s Chk%d BL QC"
StrConstant PSQ_FMT_LBN_BL_QC_PASS         = "%s BL QC"
StrConstant PSQ_FMT_LBN_SWEEP_PASS         = "%s Sweep QC"
StrConstant PSQ_FMT_LBN_SET_PASS           = "%s Set QC"
StrConstant PSQ_FMT_LBN_PULSE_DUR          = "%s Pulse duration"
StrConstant PSQ_FMT_LBN_SPIKE_DASCALE_ZERO = "%s spike with zero"
StrConstant PSQ_FMT_LBN_RB_LIMITED_RES     = "%s limited resolut."
StrConstant PSQ_FMT_LBN_DA_fI_SLOPE        = "%s f-I slope"
StrConstant PSQ_FMT_LBN_DA_fI_SLOPE_REACHED= "%s f-I slope QC"
/// @}

/// @name PatchSeq types of analysis functions
/// @anchor PatchSeqAnalysisFunctionTypes
/// @{
Constant PSQ_DA_SCALE     = 0x1
Constant PSQ_SQUARE_PULSE = 0x2
Constant PSQ_RHEOBASE     = 0x4
Constant PSQ_RAMP         = 0x8
/// List of analysis function types
StrConstant PSQ_LIST_OF_TYPES = "0x1;0x2;0x4;0x8"
/// @}

/// @name PatchSeq Rheobase
/// @{
Constant PSQ_RB_MAX_DASCALE_DIFF       = 60e-12
Constant PSQ_RB_DASCALE_SMALL_BORDER   = 50e-12
Constant PSQ_RB_DASCALE_STEP_LARGE     = 10e-12
Constant PSQ_RB_DASCALE_STEP_SMALL     =  2e-12
StrConstant PSQ_RB_FINALSCALE_FAKE_KEY = "PSQRheobaseFinalDAScaleFake"
Constant PSQ_RB_FINALSCALE_FAKE_HIGH   = 70e-12
Constant PSQ_RB_FINALSCALE_FAKE_LOW    = 40e-12
/// @}

/// @name PatchSeq DAScale
/// @{
Constant PSQ_DS_OFFSETSCALE_FAKE = 23 // pA
StrConstant PSQ_DS_SUB           = "Sub"
StrConstant PSQ_DS_SUPRA         = "Supra"
/// @}

/// @name PatchSeq Ramp
/// @{
Constant PSQ_RA_DASCALE_DEFAULT = 1 // pA
Constant PSQ_RA_NUM_SWEEPS_PASS = 3
/// @}

/// @name MultiPatchSeq various constants
/// @{
Constant MSQ_FRE_INIT_AMP_m50    = -50e-12
Constant MSQ_FRE_INIT_AMP_p100   = +100e-12
Constant MSQ_FRE_INIT_AMP_p10    = +10e-12

Constant MSQ_RB_PRE_BL_EVAL_RANGE  = 500
Constant MSQ_RB_POST_BL_EVAL_RANGE = 500

Constant MSQ_DS_BL_EVAL_RANGE_MS = 500
Constant MSQ_DS_PULSE_DUR        = 1000

Constant MSQ_RA_BL_EVAL_RANGE = 500

Constant MSQ_DS_OFFSETSCALE_FAKE = 23 // pA
Constant MSQ_DS_SWEEP_FAKE       = 42

Constant MSQ_SPIKE_LEVEL         = -10.0 // mV
Constant MSQ_RMS_SHORT_THRESHOLD = 0.07 // mV
Constant MSQ_RMS_LONG_THRESHOLD  = 0.5  // mV
Constant MSQ_TARGETV_THRESHOLD   = 1    // mV
/// @}

/// @name MultiPatchSeq types of analysis functions
/// @anchor MultiPatchSeqAnalysisFunctionTypes
/// @{
Constant MSQ_FAST_RHEO_EST = 0x1
Constant MSQ_DA_SCALE      = 0x2

/// List of analysis function types
StrConstant MSQ_LIST_OF_TYPES = "0x1;0x2"
/// @}

/// @anchor MultiPatchSeqLabnotebookFormatStrings
/// @{
StrConstant MSQ_FMT_LBN_DASCALE_EXC    = "%s DAScale exceeded"
StrConstant MSQ_FMT_LBN_STEPSIZE          = "%s step size"
StrConstant MSQ_FMT_LBN_SPIKE_DETECT      = "%s spike detected"
StrConstant MSQ_FMT_LBN_SPIKE_POSITIONS   = "%s spike positions"
StrConstant MSQ_FMT_LBN_FINAL_SCALE       = "%s final DAScale"
StrConstant MSQ_FMT_LBN_INITIAL_SCALE     = "%s initial DAScale"
StrConstant MSQ_FMT_LBN_RMS_SHORT_PASS    = "%s Chk%d S-RMS QC"
StrConstant MSQ_FMT_LBN_RMS_LONG_PASS     = "%s Chk%d L-RMS QC"
StrConstant MSQ_FMT_LBN_TARGETV_PASS      = "%s Chk%d T-V BL QC"
StrConstant MSQ_FMT_LBN_CHUNK_PASS        = "%s Chk%d BL QC"
StrConstant MSQ_FMT_LBN_BL_QC_PASS        = "%s Baseline QC"
StrConstant MSQ_FMT_LBN_HEADSTAGE_PASS    = "%s Headstage QC"
StrConstant MSQ_FMT_LBN_SWEEP_PASS        = "%s Sweep QC"
StrConstant MSQ_FMT_LBN_SET_PASS          = "%s Set QC"
StrConstant MSQ_FMT_LBN_PULSE_DUR         = "%s Pulse duration"
StrConstant MSQ_FMT_LBN_ACTIVE_HS         = "%s Active Headstage"
/// @}

Constant TP_MD_THREAD_DEAD_MAX_RETRIES = 10

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
/// @{

/// @anchor CacheFetchOptions
///
/// Don't return a duplicate of the cached wave, but return the wave itself.
/// Useful if you use the wave cache as an alternative storage.
Constant CA_OPTS_NO_DUPLICATE = 0x1
/// @}

Constant LABNOTEBOOK_MISSING_VALUE  = -1
Constant LABNOTEBOOK_UNCACHED_VALUE = -2
StrConstant LABNOTEBOOK_MOD_COUNT   = "Labnotebook modification count"

/// @name Constants for the different delta operation modes in the Wavebuilder
/// @anchor WaveBuilderDeltaOperationModes
/// @{
Constant DELTA_OPERATION_DEFAULT   = 0
Constant DELTA_OPERATION_FACTOR    = 1
Constant DELTA_OPERATION_LOG       = 2
Constant DELTA_OPERATION_SQUARED   = 3
Constant DELTA_OPERATION_POWER     = 4
Constant DELTA_OPERATION_ALTERNATE = 5
Constant DELTA_OPERATION_EXPLICIT  = 6
/// @}

Constant MINIMUM_FREE_DISC_SPACE = 10737418240 // 10GB

/// @name Stimset wave note entry types for WB_GetWaveNoteEntry()
/// @anchor StimsetWaveNoteEntryTypes
/// @{
Constant VERSION_ENTRY = 0x1
Constant SWEEP_ENTRY   = 0x2
Constant EPOCH_ENTRY   = 0x4
Constant STIMSET_ENTRY = 0x8
/// @}
/// Especially interesting for PXP consumers like the analysis browser.
Constant EXPERIMENT_VERSION = 2

/// All experiment versions up to the given value are supported
Constant ANALYSIS_BROWSER_SUPP_VERSION = 2

/// @name Mode flag for AFH_GetListOfAnalysisParams()
/// @anchor GetListOfParamsModeFlags
/// @{
Constant REQUIRED_PARAMS = 0x1
Constant OPTIONAL_PARAMS = 0x2
/// @}

/// @name GUI settings oscilloscopy Y scale update modes
/// @anchor GUISettingOscilloscopeScaleMode
/// @{
Constant GUI_SETTING_OSCI_SCALE_AUTO      = 0
Constant GUI_SETTING_OSCI_SCALE_FIXED     = 1
Constant GUI_SETTING_OSCI_SCALE_INTERVAL  = 2
/// @}

StrConstant PRESSURE_CONTROL_LED_DASHBOARD = "valdisp_DataAcq_P_LED_0;valdisp_DataAcq_P_LED_1;valdisp_DataAcq_P_LED_2;valdisp_DataAcq_P_LED_3;valdisp_DataAcq_P_LED_4;valdisp_DataAcq_P_LED_5;valdisp_DataAcq_P_LED_6;valdisp_DataAcq_P_LED_7"

/// @name Match expression types for GetListOfObjects
/// @anchor MatchExpressions
/// @{
Constant MATCH_REGEXP   = 0x1
Constant MATCH_WILDCARD = 0x2
/// @}

/// @name Options for SplitTTLWaveIntoComponents() and SplitSweepIntoComponents()
/// @anchor TTLRescalingOptions
/// @{
Constant TTL_RESCALE_OFF = 0x0
Constant TTL_RESCALE_ON  = 0x1
/// @}

/// @brief Helper struct for storing the number of active channels per rack
Structure ActiveChannels
	int32 numDARack1
	int32 numADRack1
	int32 numTTLRack1
	int32 numDARack2
	int32 numADRack2
	int32 numTTLRack2
EndStructure

/// @name Epoch key constants
/// @anchor EpochKeys
/// @{
StrConstant EPOCH_OODDAQ_REGION_KEY   = "oodDAQRegion"
StrConstant EPOCH_BASELINE_REGION_KEY = "Baseline"
/// @}

/// @name Time parameter for SWS_GetChannelGains()
/// @anchor GainTimeParameter
/// @{
Constant GAIN_BEFORE_DAQ = 0x1
Constant GAIN_AFTER_DAQ  = 0x2
/// @}

/// @brief User data on the stimset controls listing all stimsets in range
StrConstant USER_DATA_MENU_EXP = "MenuExp"

/// @name Find level edge types
/// @anchor FindLevelEdgeTypes
/// @{
Constant FINDLEVEL_EDGE_INCREASING = 1
Constant FINDLEVEL_EDGE_DECREASING = 2
Constant FINDLEVEL_EDGE_BOTH       = 0
/// @}

/// @name Find level modes
/// @anchor FindLevelModes
/// @{
Constant FINDLEVEL_MODE_SINGLE = 1
Constant FINDLEVEL_MODE_MULTI  = 2
/// @}

/// @name Return codes of the Igor exists function
/// @anchor existsReturnCodes
/// @{
Constant EXISTS_NAME_NOT_USED = 0
Constant EXISTS_AS_WAVE = 1
Constant EXISTS_AS_VAR_OR_STR = 2
Constant EXISTS_AS_FUNCTION = 3
Constant EXISTS_AS_OPERATION = 4
Constant EXISTS_AS_MACRO = 5
Constant EXISTS_AS_USERFUNCTION = 6
/// @}

/// @name Return codes of the Igor WinType function
/// @anchor wintypeReturnCodes
/// @{
Constant WINTYPE_NOWINDOW = 0
Constant WINTYPE_GRAPH = 1
Constant WINTYPE_TABLE = 2
Constant WINTYPE_LAYOUT = 3
Constant WINTYPE_NOTEBOOK = 5
Constant WINTYPE_PANEL = 7
Constant WINTYPE_XOP = 13
Constant WINTYPE_CAMERA = 15
Constant WINTYPE_GIZMO = 17
/// @}

/// @name Panel tag codes to identify panel types, set in creation macro as main window userdata($EXPCONFIG_UDATA_PANELTYPE)
/// @anchor panelTags
/// @{
StrConstant EXPCONFIG_UDATA_PANELTYPE = "Config_PanelType"

StrConstant PANELTAG_DAEPHYS = "DA_Ephys"
StrConstant PANELTAG_DATABROWSER = "DataBrowser"
/// @}

StrConstant EXPCONFIG_UDATA_SOURCEFILE_PATH = "Config_FileName"
StrConstant EXPCONFIG_UDATA_SOURCEFILE_HASH = "Config_FileHash"

/// @name Bit mask constants for properties for window control saving/restore
/// @anchor WindowControlSavingMask
/// @{
Constant EXPCONFIG_SAVE_VALUE = 1
Constant EXPCONFIG_SAVE_POSITION = 2
Constant EXPCONFIG_SAVE_USERDATA = 4
Constant EXPCONFIG_SAVE_DISABLED = 8
Constant EXPCONFIG_SAVE_CTRLTYPE = 16
Constant EXPCONFIG_SAVE_POPUPMENU_AS_STRING_ONLY = 32
Constant EXPCONFIG_SAVE_POPUPMENU_AS_INDEX_ONLY = 64
Constant EXPCONFIG_MINIMIZE_ON_RESTORE = 128
Constant EXPCONFIG_SAVE_BUTTONS_ONLY_PRESSED = 256
Constant EXPCONFIG_SAVE_ONLY_RELEVANT = 512
/// @}

/// @name Correlated control name/type/valuetype list for use with e.g. ControlInfo
/// @anchor IgorControlData
/// @{
StrConstant EXPCONFIG_GUI_CTRLLIST = "Button;Chart;CheckBox;CustomControl;GroupBox;ListBox;PopupMenu;SetVariable;Slider;TabControl;TitleBox;ValDisplay;"
StrConstant EXPCONFIG_GUI_CTRLTYPES = "1;6;2;12;9;11;3;5;7;8;10;4;"
StrConstant EXPCONFIG_GUI_VVALUE =      "1;1;1;1;0;1;1;1;1;1;0;1;"
StrConstant EXPCONFIG_GUI_SVALUE =      "0;1;0;0;1;1;1;1;1;1;0;1;"
StrConstant EXPCONFIG_GUI_SDATAFOLDER = "0;0;0;0;0;1;0;1;1;0;1;0;"
/// 0 does not apply, 1 V_Value, 2 S_Value, 3 S_DataFolder for EXPCONFIG_SAVE_ONLY_RELEVANT
StrConstant EXPCONFIG_GUI_PREFERRED =   "0;2;0;0;0;3;2;0;1;1;0;1;"

StrConstant EXPCONFIG_GUI_SUSERDATA =   "1;0;1;1;0;1;1;1;1;1;0;0;"
/// @}

/// @name PopupMenu extension keys for userdata definition of procedures
/// @anchor PopupMenuExtension
/// @{
StrConstant PEXT_UDATA_ITEMGETTER = "Items"
StrConstant PEXT_UDATA_POPUPPROC = "popupProc"
/// @}

/// @name PopupMenu extension sub menu splitting methods
/// @anchor PEXT_SubMenuSplitting
/// @{
Constant PEXT_SUBSPLIT_DEFAULT = 0
Constant PEXT_SUBSPLIT_ALPHA = 1
/// @}

/// @name PopupMenu extension sub menu name generation methods
/// @anchor PEXT_SubMenuNameGeneration
/// @{
Constant PEXT_SUBNAMEGEN_DEFAULT = 0
/// @}

/// @name Lab notebook entry types
/// @anchor LNBEntryTypes
/// @{
Constant LNB_TYPE_NONE = 0
Constant LNB_TYPE_NUMERICAL = 1
Constant LNB_TYPE_TEXTUAL = 2
/// @}

/// @brief Wave note key for the indexing helper JSON document
StrConstant TUD_INDEX_JSON = "INDEX_JSON"

/// @brief sprintf field width for trace names
Constant TRACE_NAME_NUM_DIGITS = 6

/// Space used between numbers and their units
StrConstant NUMBER_UNIT_SPACE = "\u2006"

/// @name Incremental update modes for PostPlotTransformations()
/// @anchor PostPlotUpdateModes
///
/// @{

Constant POST_PLOT_ADDED_SWEEPS = 0x1    ///< The only change: Some sweeps were added
Constant POST_PLOT_REMOVED_SWEEPS = 0x2  ///< The only change: Some sweeps were removed
Constant POST_PLOT_CONSTANT_SWEEPS = 0x4 ///< The displayed data in the databrowser stayed *constant* but some settings changed
Constant POST_PLOT_FULL_UPDATE = 0x8     ///< Forces a complete update from scratch, use that if nothing else fits

/// @}

Constant PA_SETTINGS_STRUCT_VERSION = 1
