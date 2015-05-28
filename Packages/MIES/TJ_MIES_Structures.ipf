#pragma rtGlobals=3		// Use modern global access method and strict wave access.

/// @file TJ_MIES_Structures.ipf
///
/// @brief All non-static structures are defined here

Structure BackgroundStruct
	STRUCT WMBackgroundStruct wmbs
	int32 count ///< Number of invocations of background function
EndStructure

Structure PostPlotSettings
	/// @name Trace averaging settings
	/// @{
	variable averageTraces
	DFREF averageDataFolder
	/// @}

	/// Zero traces settings
	variable zeroTraces
EndStructure
