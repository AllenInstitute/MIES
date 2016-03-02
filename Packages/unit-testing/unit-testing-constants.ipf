#pragma rtGlobals=3
#pragma version=1.03

// Author: Thomas Braun (c) 2015
// Email: thomas dot braun at byte-physics dott de

///@cond HIDDEN_SYMBOL

/// Settings folder
StrConstant PKG_FOLDER = "root:Packages:UnitTesting"

Constant CLOSE_COMPARE_STRONG_OR_WEAK = 1
Constant DEFAULT_TOLERANCE            = 1e-8

/// Action flags
///@{
Constant OUTPUT_MESSAGE = 0x01
Constant INCREASE_ERROR = 0x02
Constant ABORT_FUNCTION = 0x04
Constant WARN_MODE      = 0x01 // == OUTPUT_MESSAGE
Constant CHECK_MODE     = 0x03 // == OUTPUT_MESSAGE | INCREASE_ERROR
Constant REQUIRE_MODE   = 0x07 // == OUTPUT_MESSAGE | INCREASE_ERROR | ABORT_FUNCTION
///@}

///@endcond // HIDDEN_SYMBOL

/// @addtogroup assertionFlags
///@{

/// @addtogroup testWaveFlags
///@{
Constant TEXT_WAVE    = 2
Constant NUMERIC_WAVE = 1

Constant COMPLEX_WAVE = 0x01
Constant FLOAT_WAVE   = 0x02
Constant DOUBLE_WAVE  = 0x04
Constant INT8_WAVE    = 0x08
Constant INT16_WAVE   = 0x16
Constant INT32_WAVE   = 0x20
Constant UNSIGNED_WAVE= 0x40
///@}

/// @addtogroup equalWaveFlags
///@{
Constant WAVE_DATA        =   1
Constant WAVE_DATA_TYPE   =   2
Constant WAVE_SCALING     =   4
Constant DATA_UNITS       =   8
Constant DIMENSION_UNITS  =  16
Constant DIMENSION_LABELS =  32
Constant WAVE_NOTE        =  64
Constant WAVE_LOCK_STATE  = 128
Constant DATA_FULL_SCALE  = 256
Constant DIMENSION_SIZES  = 512
///@}
///@}
