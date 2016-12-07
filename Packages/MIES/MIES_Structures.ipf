#pragma TextEncoding = "UTF-8"
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

	/// Artefact removal settings
	/// @{
	variable artefactRemoval
	variable autoRemove
	variable sweepNo
	DFREF sweepFolder
	WAVE numericalValues
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

Function InitOOdDAQParams(params, stimSets, setColumns, preFeatureTime, postFeatureTime, resolution)
	STRUCT OOdDAQParams &params
	WAVE/WAVE stimSets
	WAVE setColumns
	variable preFeatureTime, postFeatureTime, resolution

	ASSERT(DimSize(stimSets, ROWS) >= 1, "Stimsets wave is empty")
	ASSERT(resolution >= 0, "Unexpected resolution")
	ASSERT(preFeatureTime >= 0, "Unexpected pre feature time")
	ASSERT(postFeatureTime >= 0, "Unexpected post feature time")
	ASSERT(DimSize(stimSets, ROWS) == DimSize(setColumns, ROWS), "Mismatched simtSets and setColumns sizes")
	ASSERT(resolution >= 1 && resolution <= 1000, "Invalid resolution")

	WaveClear params.preload
	WaveClear params.stimSetsSmeared
	WaveClear params.offsets
	WaveClear params.regions

	WAVE params.stimSets        = stimSets
	WAVE params.setColumns      = setColumns
	params.preFeaturePoints     = preFeatureTime  / HARDWARE_ITC_MIN_SAMPINT
	params.postFeaturePoints    = postFeatureTime / HARDWARE_ITC_MIN_SAMPINT
	params.resolution           = resolution
End

/// @brief Helper structure for Optimized overlap distributed acquisition (oodDAQ) functions
Structure OOdDAQParams
	///@name Temporaries
	///@{
	WAVE preload                       ///< Data used for prefilling the optimization wave.
	                                   ///< Allows to take previous runs into account.
	WAVE/WAVE stimSetsSmeared          ///< StimSets (single set) with pre/post feature time applied. @sa OOD_SmearStimSet()
	WAVE/WAVE stimSetsSmearedAndOffset ///< StimSets (single set) with pre/post feature time applied and offsets.
	///@}

	///@name Input
	///@{
	WAVE/WAVE stimSets         ///< Wave ref wave with different stimsets
	WAVE setColumns            ///< Set (aka column) to use for each stimset
	variable preFeaturePoints  ///< Time in points which should be kept signal-free before features
	variable postFeaturePoints ///< Time in points which should be kept signal-free after features
	variable resolution        ///< Accuracy in ms used for searching an optimum, features in the stim set
	                           ///< smaller than that *might* be ignored.
	///@}

	///@name Output
	///@{
	WAVE offsets               ///< Result of the optimization in points
	WAVE/T regions             ///< List of the form `%begin-%end;...` which denotes the x-coordinates of
	                           ///< the smeared regions in units of time of the ITCDataWave. @sa OOD_ExtractFeatureRegions()
	///@}
EndStructure
