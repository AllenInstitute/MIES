#pragma rtGlobals=3		// Use modern global access method and strict wave access.

/// @file MIES_Structures.ipf
///
/// @brief All non-static structures together with their initialization
///        routines are defined here.

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

/// @brief Parameter to #CreateTiledChannelGraph
Structure TiledGraphSettings
	int16 displayDAC
	int16 displayADC
	int16 displayTTL
	int16 splitTTLBits
	int16 overlaySweep
	int16 overlayChannels
	int16 dDAQDisplayMode
	int16 oodDAQHeadstageRegions
EndStructure

/// @brief Helper structure for formula parsing of the Wavebuilder combine epoch
Structure FormulaProperties
	string formula
	variable numRows, numCols /// minimum number of rows and colums in the referenced sets
EndStructure

Function InitFormulaProperties(fp)
	struct FormulaProperties &fp

	fp.formula = ""
	fp.numRows = NaN
	fp.numCols = NaN
End

/// @brief Helper structure for UpgradeWaveLocationAndGetIt()
Structure WaveLocationMod
	DFREF dfr      ///< former location of the wave
	DFREF newDFR   ///< new location of the wave (can be invalid)
	string name    ///< former name of the wave
	string newName ///< new name of the wave (can be null/empty)
EndStructure
