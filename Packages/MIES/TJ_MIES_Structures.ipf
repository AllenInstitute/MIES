#pragma rtGlobals=3		// Use modern global access method and strict wave access.

/// @file TJ_MIES_Structures.ipf
///
/// @brief All non-static structures are defined here

Structure BackgroundStruct
	STRUCT WMBackgroundStruct wmbs
	int32 count ///< Number of invocations of background function
EndStructure

Function FinalUpdateHookProto(graph)
	string graph
End

Structure PostPlotSettings
	/// @name Trace averaging settings
	/// @{
	variable averageTraces
	DFREF averageDataFolder
	/// @}

	/// Zero traces settings
	variable zeroTraces

	/// @name Time alignment settings
	/// @{
	variable timeAlignment
	variable timeAlignMode //< one of #TimeAlignmentConstants
	string timeAlignRefTrace
	variable timeAlignLevel
	/// @}

	/// Hook function which is called at the very end of #PostPlotTransformations
	FUNCREF FinalUpdateHookProto finalUpdateHook
EndStructure
