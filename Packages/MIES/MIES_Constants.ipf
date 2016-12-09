#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

/// @file MIES_Constants.ipf
/// @brief Global constants

/// @name Constans for the number of channels
/// @anchor NUM_CHANNELS_CONSTANTS
/// @{
Constant NUM_DA_TTL_CHANNELS   = 8
Constant NUM_HEADSTAGES        = 8
Constant NUM_AD_CHANNELS       = 16
Constant NUM_ASYNC_CHANNELS    = 8
Constant NUM_TTL_BITS_PER_RACK = 4
/// @}

/// Maximum values of @ref NUM_CHANNELS_CONSTANTS
Constant NUM_MAX_CHANNELS      = 16

StrConstant DEVICE_TYPES     = "ITC16;ITC18;ITC1600;ITC00;ITC16USB;ITC18USB"
StrConstant DEVICE_NUMBERS   = "0;1;2;3;4;5;6;7;8;9;10"

StrConstant ITC1600_FIRST_DEVICE = "ITC1600_Dev_0"
StrConstant BASE_WINDOW_TITLE    = "DA_Ephys"

StrConstant amPanel = "analysisMaster"

/// @name Various mies specific regular expressions
/// @anchor MIES_REGEXPS
/// @{
StrConstant DATA_SWEEP_REGEXP  = "(?i)^Sweep_[[:digit:]]+$"
StrConstant DATA_CONFIG_REGEXP = "(?i)^Config_Sweep_[[:digit:]]+$"
StrConstant TP_STORAGE_REGEXP  = "(?i)^TPStorage(_[[:digit:]]+)?$"
/// @}

StrConstant UNTITLED_EXPERIMENT           = "Untitled"
StrConstant PACKED_FILE_EXPERIMENT_SUFFIX = ".pxp"

/// Amount of free memory required to perform data aquisition in GB
Constant FREE_MEMORY_LOWER_LIMIT = 0.75

/// @name Pressure Control constants
/// @{
/// Max and min pressure regulator pressure in psi
Constant MAX_REGULATOR_PRESSURE =  9.95
Constant MIN_REGULATOR_PRESSURE = -9.95
/// @}

StrConstant ITC_CHANNEL_NAMES    = "AD;DA;;TTL"

/// @name Channel constants shared with the ITC XOP
/// @anchor ITC_XOP_CHANNEL_CONSTANTS
/// @{
Constant ITC_XOP_CHANNEL_TYPE_ADC = 0
Constant ITC_XOP_CHANNEL_TYPE_DAC = 1
Constant ITC_XOP_CHANNEL_TYPE_TTL = 3
/// @}

StrConstant LAST_SWEEP_USER_DATA = "lastSweep"

Constant MINIMUM_WAVE_SIZE = 64
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

/// @name CountObjects and CountObjectsDFR constant
/// @{
Constant COUNTOBJECTS_WAVES      = 1
Constant COUNTOBJECTS_VAR        = 2
Constant COUNTOBJECTS_STR        = 3
Constant COUNTOBJECTS_DATAFOLDER = 4
/// @}

/// @name Control types from ControlInfo
/// @{
Constant CONTROL_TYPE_BUTTON      = 1
Constant CONTROL_TYPE_CHECKBOX    = 2
Constant CONTROL_TYPE_POPUPMENU   = 3
Constant CONTROL_TYPE_VALDISPLAY  = 4
Constant CONTROL_TYPE_SETVARIABLE = 5
Constant CONTROL_TYPE_SLIDER      = 7
Constant CONTROL_TYPE_TAB         = 8
Constant CONTROL_TYPE_LISTBOX     = 11
/// @}

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
Constant CHANNEL_INDEX_ALL         = -1    ///< Controls which control groups have this special channel index
Constant CHANNEL_TYPE_UNKNOWN      = 0x150
/// @}

/// @name Constants for the selection wave of a ListBox
/// @{
Constant LISTBOX_SELECTED          = 0x01
Constant LISTBOX_TREEVIEW_EXPANDED = 0x10
Constant LISTBOX_TREEVIEW          = 0x40
/// @}

Constant INITIAL_KEY_WAVE_COL_COUNT = 4

/// @name Constants for the note of the wave returned by GetTPStorage
/// @{
StrConstant TP_CYLCE_COUNT_KEY             = "TPCycleCount"
StrConstant AUTOBIAS_LAST_INVOCATION_KEY   = "AutoBiasLastInvocation"
StrConstant DIMENSION_SCALING_LAST_INVOC   = "DimensionScalingLastInvocation"
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
Constant UNKNOWN_MODE          = NaN
Constant DATA_ACQUISITION_MODE = 0
Constant TEST_PULSE_MODE       = 1
/// @}

/// @name Constants for three Amplifier modes
/// @anchor AmplifierClampModes
/// @{
Constant V_CLAMP_MODE      = 0
Constant I_CLAMP_MODE      = 1
Constant I_EQUAL_ZERO_MODE = 2
/// @}

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

/// Interval in iterations between the switch from live update false to true
Constant TEST_PULSE_LIVE_UPDATE_INTERVAL = 25

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
Constant IGOR_TYPE_UNSIGNED         = 0x040 ///< Can be combined, using bitwise or, with all integer types
Constant IGOR_TYPE_STRUCT_PARAMETER = 0x200
/// @}

/// User data which identifies MIES related panels
StrConstant MIES_PANEL_TYPE_USER_DATA = "MiesPanelType"

/// @name Possible values of #MIES_PANEL_TYPE_USER_DATA
/// @{
StrConstant MIES_DATABROWSER_PANEL = "DataBrowser"
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

/// Define error/success values to be used with the WSE engine
Constant TI_WRITEACK_SUCCESS = 0
Constant TI_WRITEACK_FAILURE = -1

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

/// @name Constants for GetAxisOrientation
/// @anchor AxisOrientationConstants
/// @{
Constant AXIS_ORIENTATION_LEFT   = 0x01
Constant AXIS_ORIENTATION_RIGHT  = 0x02
Constant AXIS_ORIENTATION_BOTTOM = 0x04
Constant AXIS_ORIENTATION_TOP    = 0x08
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
Constant SEGMENT_TYPE_WAVE_LAST_IDX = 97

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

/// Event types for analysis functions
/// @anchor EVENT_TYPE_ANALYSIS_FUNCTIONS
/// @{
Constant PRE_DAQ_EVENT    = 0
Constant MID_SWEEP_EVENT  = 1
Constant POST_SWEEP_EVENT = 2
Constant POST_SET_EVENT   = 3
Constant POST_DAQ_EVENT   = 4
/// @}

/// Number of @ref EVENT_TYPE_ANALYSIS_FUNCTIONS
Constant TOTAL_NUM_EVENTS   = 5

/// Human readable names for @ref EVENT_TYPE_ANALYSIS_FUNCTIONS
StrConstant EVENT_NAME_LIST = "Pre DAQ;Mid Sweep;Post Sweep;Post Set;Post DAQ"

/// Number of layers in the labnotebook
Constant LABNOTEBOOK_LAYER_COUNT = 9

/// Index for storing headstage independent data into the labnotebook
Constant INDEP_HEADSTAGE = 8

StrConstant UNKNOWN_MIES_VERSION = "unknown version"

/// Number of common control groups in the DA_EPHYS panel
Constant COMMON_CONTROL_GROUP_COUNT = 17

/// Equals 2^5 from `GetKeyState`
Constant ESCAPE_KEY = 32

Constant MAX_COMMANDLINE_LENGTH = 1000

StrConstant WAVEBUILDER_COMBINE_FORMULA_VER = "1"

/// @name Flags for functions returning the length of a sampling wave in points
/// @anchor SamplingIntervalQueryFlags
/// @{
Constant MIN_SAMPLING_INTERVAL_TYPE  = 0x1
Constant REAL_SAMPLING_INTERVAL_TYPE = 0x2
/// @}

/// Conversion factor between volts and bits for the AD/DA channels
Constant HARDWARE_ITC_BITS_PER_VOLT = 3200

/// @name Trigger modes
/// External trigger is used for yoking multiple ITC 1600 devices
/// @anchor TriggerModeStartAcq
/// @{
Constant HARDWARE_DAC_DEFAULT_TRIGGER  = 0x0
Constant HARDWARE_DAC_EXTERNAL_TRIGGER = 0x1
/// @}

/// Used to upgrade the GuiStateWave as well as the DA Ephys panel
Constant DA_EPHYS_PANEL_VERSION = 12

/// Version of the labnotebooks (numerical and textual)
///
/// Hast to be increased on the following occasions:
/// - New entries
/// - Changed names of entries
/// - Changed units or meaning of entries
Constant LABNOTEBOOK_VERSION = 6

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
/// @}

Constant HARDWARE_MAX_DEVICES = 10

/// @name Minimum possible sampling intervals in milliseconds (1e-3s)
/// @{
Constant HARDWARE_ITC_MIN_SAMPINT     = 0.005 ///< ITC DACs
Constant HARDWARE_NI_6001_MIN_SAMPINT = 0.2   ///< NI 6001 USB
/// @}

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

/// @name Convenience constants for DAP_UpdateClampmodeTabs() and DAP_ChangeHeadStageMode()
/// @anchor MCCSyncOverrides
/// @{
Constant SKIP_MCC_MIES_SYNCING = 1
Constant DO_MCC_MIES_SYNCING   = 0
/// @}

/// Number of trials to find a suitable port for binding a ZeroMQ service
Constant ZEROMQ_NUM_BIND_TRIALS = 4

Constant ZEROMQ_BIND_REP_PORT = 5670

/// @name Constants for AnalysisBrowserMap (Text Wave)
/// @{
StrConstant ANALYSISBROWSER_FILE_TYPE_IGOR = "I"
StrConstant ANALYSISBROWSER_FILE_TYPE_NWB  = "N"
/// @}

/// Device restart happens after this number of trials with stuck FIFO, used by
/// TP MD
Constant NUM_CONSEC_FIFO_STILLSTANDS = 3

/// Convenience definition for functions interacting with threads
Constant MAIN_THREAD = 0
