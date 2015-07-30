#pragma rtGlobals=3		// Use modern global access method and strict wave access.

/// @file TJ_MIES_Constants.ipf
/// This file holds various constants
Constant NUM_DA_TTL_CHANNELS   = 8
Constant NUM_HEADSTAGES        = 8
Constant NUM_AD_CHANNELS       = 16
Constant NUM_ASYNC_CHANNELS    = 8
Constant NUM_TTL_BITS_PER_RACK = 4

StrConstant DEVICE_TYPES     = "ITC16;ITC18;ITC1600;ITC00;ITC16USB;ITC18USB"
StrConstant DEVICE_NUMBERS   = "0;1;2;3;4;5;6;7;8;9;10"

StrConstant ITC1600_FIRST_DEVICE = "ITC1600_Dev_0"
StrConstant BASE_WINDOW_TITLE    = "DA_Ephys"

StrConstant amPanel = "analysisMaster"

/// @name RegExps matching all sweep and config waves
/// @{
StrConstant DATA_SWEEP_REGEXP  = "(?i)^Sweep_[[:digit:]]+$"
StrConstant DATA_CONFIG_REGEXP = "(?i)^Config_Sweep_[[:digit:]]+$"
/// @}

StrConstant UNTITLED_EXPERIMENT           = "Untitled"
StrConstant PACKED_FILE_EXPERIMENT_SUFFIX = ".pxp"

/// Amount of free memory required to perform data aquisition in GB
Constant FREE_MEMORY_LOWER_LIMIT = 0.75

/// @name Pressure Control constants
/// @{
Constant SAMPLE_INT_MICRO        = 5
/// @}

StrConstant ITC_CHANNEL_NAMES    = "AD;DA;;TTL"

///@name Constants shared with the ITC XOP
///@{
Constant ITC_XOP_CHANNEL_TYPE_ADC = 0
Constant ITC_XOP_CHANNEL_TYPE_DAC = 1
Constant ITC_XOP_CHANNEL_TYPE_TTL = 3
///@}

StrConstant LAST_SWEEP_USER_DATA = "lastSweep"

Constant MINIMUM_WAVE_SIZE = 64
Constant MAXIMUM_WAVE_SIZE = 16384 // 2^14

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
/// @}

/// See "Control Structure eventMod Field"
/// @deprecated as the numerical values are dependent on the
/// control type this approach here will give a huge mess of constants
Constant EVENT_MOUSE_UP = 2

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
Constant HEADSTAGE                 = 0x080
Constant CHANNEL_TYPE_ASYNC        = 0x100
/// @}

/// @name Constants for the selection wave of a ListBox
/// @{
Constant LISTBOX_SELECTED          = 0x01
Constant LISTBOX_TREEVIEW_EXPANDED = 0x10
Constant LISTBOX_TREEVIEW          = 0x40
/// @}

Constant INITIAL_KEY_WAVE_COL_COUNT = 2

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

/// @name Constants for both data acquisition modes
/// @anchor DataAcqModes
/// @{
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
Constant MCC_SETHOLDING_FUNC             = 0x001
Constant MCC_GETHOLDING_FUNC             = 0x002
Constant MCC_SETHOLDINGENABLE_FUNC       = 0x004
Constant MCC_SETWHOLECELLCOMPCAP_FUNC    = 0x008
Constant MCC_SETWHOLECELLCOMPRESIST_FUNC = 0x010
Constant MCC_SETWHOLECELLCOMPENABLE_FUNC = 0x020
Constant MCC_SETRSCOMPCORRECTION_FUNC    = 0x030
Constant MCC_SETRSCOMPPREDICTION_FUNC    = 0x040
Constant MCC_SETRSCOMPENABLE_FUNC        = 0x050
Constant MCC_AUTOBRIDGEBALANCE_FUNC      = 0x060
Constant MCC_SETBRIDGEBALRESIST_FUNC     = 0x070
Constant MCC_SETBRIDGEBALENABLE_FUNC     = 0x080
Constant MCC_SETNEUTRALIZATIONCAP_FUNC   = 0x090
Constant MCC_SETNEUTRALIZATIONENABL_FUNC = 0x100
Constant MCC_AUTOPIPETTEOFFSET_FUNC      = 0x110
Constant MCC_SETPIPETTEOFFSET_FUNC       = 0x120
Constant MCC_GETPIPETTEOFFSET_FUNC       = 0x130
Constant MCC_SETSLOWCURRENTINJENABL_FUNC = 0x140
Constant MCC_GETSLOWCURRENTINJENABL_FUNC = 0x150
Constant MCC_SETSLOWCURRENTINJLEVEL_FUNC = 0x160
Constant MCC_GETSLOWCURRENTINJLEVEL_FUNC = 0x170
Constant MCC_SETSLOWCURRENTINJSETLT_FUNC = 0x180
Constant MCC_GETSLOWCURRENTINJSETLT_FUNC = 0x190
Constant MCC_GETHOLDINGENABLE_FUNC       = 0x200
Constant MCC_AUTOFASTCOMP_FUNC           = 0x210
Constant MCC_AUTOSLOWCOMP_FUNC           = 0x220
Constant MCC_GETFASTCOMPTAU_FUNC         = 0x230
Constant MCC_GETFASTCOMPCAP_FUNC         = 0x240
Constant MCC_GETSLOWCOMPTAU_FUNC         = 0x250
Constant MCC_GETSLOWCOMPCAP_FUNC         = 0x260
/// @}

Constant CHECKBOX_SELECTED     = 1
Constant CHECKBOX_UNSELECTED   = 0

/// Interval in iterations between the switch from live update false to true
Constant TEST_PULSE_LIVE_UPDATE_INTERVAL = 25

/// @name Constants for FunctionInfo
/// @anchor FunctionInfoParameterTypes
/// @{
Constant STRUCT_PARAMETER_TYPE = 512
/// @}

/// User data which identifies MIES related panels
StrConstant MIES_PANEL_TYPE_USER_DATA = "MiesPanelType"

/// @name Possible values of #MIES_PANEL_TYPE_USER_DATA
/// @{
StrConstant MIES_DATABROWSER_PANEL = "DataBrowser"
/// @}

StrConstant NUMERALS = "First;Second;Third;Fourth;Fifth;Sixth;Seventh;Eighth"

/// Generic axis name for graphs using split axis
StrConstant AXIS_BASE_NAME = "col"

/// Minimum possible sampling interval for our ITC DACs in milliseconds (1e-3s)
Constant MINIMUM_SAMPLING_INTERVAL = 0.005

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
Constant TEST_PULSE_NOT_RUNNING      = 0x00
Constant TEST_PULSE_BG_SINGLE_DEVICE = 0x01
Constant TEST_PULSE_BG_MULTI_DEVICE  = 0x02
Constant TEST_PULSE_FG_SINGLE_DEVICE = 0x04
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

/// @name Constants for functions using rack number parameters
/// @anchor RackConstants
/// @{
Constant RACK_ZERO = 0x00
Constant RACK_ONE  = 0x01
/// @}

StrConstant STIM_WAVE_NAME_KEY = "Stim Wave Name"

/// Last valid row index for storing epoch types in #GetSegmentTypeWave
Constant SEGMENT_TYPE_WAVE_LAST_IDX = 97
