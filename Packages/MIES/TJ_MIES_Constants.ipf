#pragma rtGlobals=3		// Use modern global access method and strict wave access.

/// @file TJ_MIES_Constants.ipf
/// This file holds various constants
Constant NUM_DA_TTL_CHANNELS = 8
Constant NUM_HEADSTAGES      = 8
Constant NUM_AD_CHANNELS     = 16
Constant NUM_ASYNC_CHANNELS  = 8

StrConstant DEVICE_TYPES     = "ITC16;ITC18;ITC1600;ITC00;ITC16USB;ITC18USB"
StrConstant DEVICE_NUMBERS   = "0;1;2;3;4;5;6;7;8;9;10"

StrConstant ITC1600_FIRST_DEVICE = "ITC1600_Dev_0"
StrConstant BASE_WINDOW_TITLE    = "DA_Ephys"

/// This regular expression matches all sweep waves
StrConstant DATA_SWEEP_REGEXP = "(?i)^Sweep_[[:digit:]]+$"

StrConstant UNTITLED_EXPERIMENT           = "Untitled"
StrConstant PACKED_FILE_EXPERIMENT_SUFFIX = ".pxp"

/// Amount of free memory required to perform data aquisition in GB
Constant FREE_MEMORY_LOWER_LIMIT = 0.5

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

/// See "Control Structure eventMod Field"
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

/// @name Parameters for GetChannelControl and IDX_GetSetsInRange, IDX_GetSetFolder
/// @anchor ChannelTypeAndControlConstants
/// @{
Constant CHANNEL_TYPE_DAC          = 0x00
Constant CHANNEL_TYPE_TTL          = 0x01
Constant CHANNEL_TYPE_ADC          = 0x02
Constant CHANNEL_CONTROL_WAVE      = 0x04
Constant CHANNEL_CONTROL_INDEX_END = 0x08
Constant CHANNEL_CONTROL_UNIT      = 0x10
Constant CHANNEL_CONTROL_GAIN      = 0x20
Constant CHANNEL_CONTROL_SCALE     = 0x30
Constant CHANNEL_CONTROL_CHECK     = 0x40
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

/// @name Modes for IM_SaveExperiment
/// @anchor SaveExperimentModes
/// @{
Constant SAVE_AND_CLEAR            = 0x01
Constant SAVE_AND_SPLIT            = 0x02
/// @}
