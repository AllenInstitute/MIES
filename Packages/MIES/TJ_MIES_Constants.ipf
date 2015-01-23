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

/// @name Pressure Control constants
/// @{
Constant SAMPLE_INT_MICRO        = 5
/// @}
