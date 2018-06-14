#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_STRUCTURES
#endif

/// @file MIES_Structures.ipf
///
/// @brief All non-static structures together with their initialization
///        routines are defined here.

Structure BackgroundStruct
	STRUCT WMBackgroundStruct wmbs
	int32 count           ///< Number of invocations of background function
	int32 threadDeadCount ///< TP-MD only: Number of successive tries to get data from the thread
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

	variable hideSweep

	/// Zero traces settings
	variable zeroTraces

	/// @name Time alignment settings
	/// @{
	variable timeAlignment
	variable timeAlignMode //< one of #TimeAlignmentConstants
	string timeAlignRefTrace
	variable timeAlignLevel
	/// @}

	STRUCT PulseAverageSettings pulseAverSett

	/// Hook function which is called at the very end of #PostPlotTransformations
	FUNCREF FinalUpdateHookProto finalUpdateHook
EndStructure

Function InitPulseAverageSettings(pa)
	STRUCT PulseAverageSettings &pa

	pa.showIndividualTraces = NaN
	pa.showAverageTrace     = NaN
	pa.startingPulse        = NaN
	pa.endingPulse          = NaN
	pa.regionSlider         = NaN
	pa.fallbackPulseLength  = NaN
	pa.multipleGraphs       = NaN
End

Structure PulseAverageSettings
	variable showIndividualTraces, showAverageTrace
	variable startingPulse, endingPulse, regionSlider
	variable fallbackPulseLength, multipleGraphs
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
	int16 dDAQHeadstageRegions
	int16 highlightSweep
	int16 hideSweep
EndStructure

/// @brief Helper structure for formula parsing of the Wavebuilder combine epoch
Structure FormulaProperties
	string formula, stimsetList
	variable numRows, numCols /// minimum number of rows and colums in the referenced sets
EndStructure

Function InitFormulaProperties(fp)
	struct FormulaProperties &fp

	fp.formula = ""
	fp.stimsetList = ""
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

/// @brief The structure passed into `V3` and later analysis functions
Structure AnalysisFunction_V3
	/// one of @ref EVENT_TYPE_ANALYSIS_FUNCTIONS
	variable eventType

	/// raw data wave for interacting with the DAC hardware (locked to prevent
	/// changes using `SetWaveLock`). The exact wave format depends on the hardware.
	///
	/// ITC Hardware: ITCDataWave, see GetITCDataWave()
	WAVE rawDACWave

	/// active headstage index, `[0, NUM_HEADSTAGES[`
	variable headStage

	/// number of rows in `rawDACWave` which will be filled with data at the
	/// end of DAQ. The total number of rows in `rawDACWave` might be higher
	/// due to alignment requirements of the data acquisition hardware.
	///
	/// Always `NaN` for #PRE_DAQ_EVENT events.
	variable lastValidRowIndex

	/// number of rows in `rawDACWave` with already acquired data
	variable lastKnownRowIndex

	/// Potential *future* number of the sweep. Once the sweep is finished it will be
	/// saved with this number. Use GetSweepWave() to query the sweep itself.
	variable sweepNo

	/// Number of sweeps in the currently acquired stimset of the passed headstage
	variable sweepsInSet

	/// Analysis function parameters set in the stimset's textual parameter
	/// wave. Settable via WBP_AddAnalysisParameter().
	string params
EndStructure

/// @brief Helper structure for WB_GetDeltaDimLabel()
Structure DeltaControlNames
	string main, delta, dme, op, ldelta
EndStructure
