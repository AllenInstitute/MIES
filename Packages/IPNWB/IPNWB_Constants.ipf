#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma IgorVersion=6.3
#pragma IndependentModule=IPNWB
#pragma version=0.15

/// @file IPNWB_Constants.ipf
/// @brief Constants

StrConstant PLACEHOLDER = "PLACEHOLDER"
Strconstant NWB_VERSION = "NWB-1.0.5"

/// @name Constants for FunctionInfo and WaveType
///
/// @anchor IPNWB_IgorTypes
/// @{
Constant IGOR_TYPE_COMPLEX          = 0x001
CONSTANT IGOR_TYPE_32BIT_FLOAT      = 0x002
CONSTANT IGOR_TYPE_64BIT_FLOAT      = 0x004
Constant IGOR_TYPE_8BIT_INT         = 0x008
Constant IGOR_TYPE_16BIT_INT        = 0x010
Constant IGOR_TYPE_32BIT_INT        = 0x020
CONSTANT IGOR_TYPE_UNSIGNED         = 0x040 ///< Can be combined, using bitwise or, with all integer types
Constant IGOR_TYPE_STRUCT_PARAMETER = 0x200
/// @}

/// Convenience definition to nicify expressions like DimSize(wv, ROWS)
/// easier to read than DimSize(wv, 0).
/// @{
Constant ROWS                = 0
Constant COLS                = 1
Constant LAYERS              = 2
Constant CHUNKS              = 3
/// @}

StrConstant CHANNEL_NAMES = "AD;DA;;TTL"

/// @name Channel constants (inspired by the ITC XOP)
/// @anchor IPNWB_ChannelTypes
/// @{
Constant CHANNEL_TYPE_OTHER = -1
Constant CHANNEL_TYPE_ADC   = 0
Constant CHANNEL_TYPE_DAC   = 1
Constant CHANNEL_TYPE_TTL   = 3
/// @}

/// @name Constants for the acquisition modes
/// @anchor IPNWB_ClampModes
/// @{
Constant V_CLAMP_MODE      = 0
Constant I_CLAMP_MODE      = 1
Constant I_EQUAL_ZERO_MODE = 2
/// @}
