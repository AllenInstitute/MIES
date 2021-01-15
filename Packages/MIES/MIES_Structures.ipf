#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
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
EndStructure

Function InitPulseAverageSettings(pa)
	STRUCT PulseAverageSettings &pa

	pa.enabled              = 0
	pa.showIndividualPulses = NaN
	pa.showAverage          = NaN
	pa.startingPulse        = NaN
	pa.endingPulse          = NaN
	pa.regionSlider         = NaN
	pa.overridePulseLength  = NaN
	pa.fixedPulseLength     = NaN
	pa.multipleGraphs       = NaN
	pa.zeroPulses           = NaN
	pa.autoTimeAlignment    = NaN
	pa.dfr                  = $""
	pa.hideFailedPulses     = NaN
	pa.searchFailedPulses   = NaN
	pa.failedPulsesLevel    = NaN
	pa.yScaleBarLength      = NaN
	pa.showImages           = NaN
	pa.showTraces           = NaN
	pa.drawXZeroLine        = NaN
	pa.pulseSortOrder       = NaN
	pa.imageColorScale      = ""
End

// If this structure changes, #PA_SETTINGS_STRUCT_VERSION/PA_SerializeSettings() and
// PA_DeSerializeSettings() and PA_DetermineConstantSettings() needs adaptation.
Structure PulseAverageSettings
	variable showIndividualPulses, showAverage
	variable regionSlider, multipleGraphs
	variable zeroPulses, autoTimeAlignment, enabled
	variable hideFailedPulses, searchFailedPulses
	variable failedPulsesLevel, failedNumberOfSpikes, yScaleBarLength
	variable showImages, showTraces, drawXZeroLine
	variable pulseSortOrder
	string imageColorScale

	/// @{
	/// These settings influence the extracted single pulse waves, see also
	/// PA_GenerateAllPulseWaves().
	variable startingPulse, endingPulse, overridePulseLength, fixedPulseLength
	/// @}

	DFREF dfr

	STRUCT PulseAverageDeconvSettings deconvolution
EndStructure

Structure PulseAverageDeconvSettings
	variable enable, smth, tau, range
EndStructure

/// @{
// This structure stores data that is used in many PA functions.
// setIndices: 2D wave reference wave, each entry refers to a permanent setIndice wave @sa GetPulseAverageSetIndizes
//             The size is (numActive, numActive) where numActive is the number of regions/channels
//             rows index the channels and columns index the regions
// setIndicesUnsorted: same size and layout as setIndices, but it stores references to free waves of setIndices.
//                     These setIndice waves are copies of the setIndices at creation time, where they are unsorted.
// setWaves2Unsorted: same size and layout as setIndices, but it stores references to the set waves.
//                    Each set wave is a two column wave reference wave where the first column refers to the pulse data and
//                    the second column to the pulse note wave. @sa PA_GetSetWaves
//                    The 2 in the name relates to the fact that the referenced wave is a two column wave reference wave, where
//                    the pulse data and the note data is split into several waves.
// properties: reference to the PA properties wave. @sa GetPulseAverageProperties
// propertiesWaves: reference to the PA propertiesWaves wave (from GetPulseAveragePropertiesWaves)
// axesNames: same size and layout as setIndices, but it stores references to two element text waves.
//            The two element text waves store the name of the horizontal and vertical axis for the display.
//            @sa PA_GetAxes
// ovlTracesAvg: numeric wave with size (numActive, numActive). It is used in @sa PA_ShowPulses to log if in a channel/region
//               a average trace was plotted. @sa PA_IsDataOnSubPlot
// ovlTracesDeconv: numeric wave with size (numActive, numActive). It is used in @sa PA_ShowPulses to log if in a channel/region
//               a deconvolution trace was plotted. @sa PA_IsDataOnSubPlot
// imageAvgDataPresent: numeric wave with size (numActive, numActive). It is used in @sa PA_ShowImage to log if in a channel/region
//               a average data was plotted. @sa PA_IsDataOnSubPlot
// imageDeconvDataPresent: numeric wave with size (numActive, numActive). It is used in @sa PA_ShowImage to log if in a channel/region
//               a deconvolution data was plotted. @sa PA_IsDataOnSubPlot
// pulseAverageHelperDFR: data folder reference to the PA helper DF
// pulseAverageDFR: data folder reference to the PA DF
// channels: 1D numeric wave of size numActive. It stores the channel numbers. The index is position in y on the displayed layout grid.
// regions: 1D numeric wave of size numActive. It stores the region numbers. The index is position in x on the displayed layout grid.
// numEntries: 2D numeric wave of size (numActive, numActive). Stores the number of used elements in the corresponding indice wave from
//             setIndicesUnsorted. @sa NOTE_INDEX
// startEntry: 2D numeric wave of size (numActive, numActive). Stores the number of start index in the corresponding indice wave from
//             setIndicesUnsorted for incremental averaging and display.
// indexHelper: 2D numeric wave of size (numActive, numActive). For use as helper wave for multithreaded auto indexing using one of
//              the other waves from the structure.
Structure PulseAverageSetIndices
	WAVE/WAVE setIndices
	WAVE/WAVE setIndicesUnsorted
	WAVE/WAVE setWaves2Unsorted
	WAVE properties
	WAVE/WAVE propertiesWaves
	WAVE/WAVE axesNames
	WAVE ovlTracesAvg
	WAVE ovlTracesDeconv
	WAVE imageAvgDataPresent
	WAVE imageDeconvDataPresent
	DFREF pulseAverageHelperDFR
	DFREF pulseAverageDFR
	WAVE channels
	WAVE regions
	WAVE numEntries
	WAVE startEntry
	WAVE indexHelper
EndStructure

/// @}

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

Function InitOOdDAQParams(params, stimSets, setColumns, preFeatureTime, postFeatureTime)
	STRUCT OOdDAQParams &params
	WAVE/WAVE stimSets
	WAVE setColumns
	variable preFeatureTime, postFeatureTime

	ASSERT(DimSize(stimSets, ROWS) >= 1, "Stimsets wave is empty")
	ASSERT(preFeatureTime >= 0, "Unexpected pre feature time")
	ASSERT(postFeatureTime >= 0, "Unexpected post feature time")
	ASSERT(DimSize(stimSets, ROWS) == DimSize(setColumns, ROWS), "Mismatched simtSets and setColumns sizes")

	WaveClear params.preload
	WaveClear params.offsets
	WaveClear params.regions

	WAVE params.stimSets        = stimSets
	WAVE params.setColumns      = setColumns
	params.preFeaturePoints     = preFeatureTime  / WAVEBUILDER_MIN_SAMPINT
	params.postFeaturePoints    = postFeatureTime / WAVEBUILDER_MIN_SAMPINT
End

/// @brief Helper structure for Optimized overlap distributed acquisition (oodDAQ) functions
Structure OOdDAQParams
	///@name Temporaries
	///@{
	WAVE preload                       ///< Data used for prefilling the optimization wave.
	                                   ///< Allows to take previous runs into account.
	///@}

	///@name Input
	///@{
	WAVE/WAVE stimSets         ///< Wave ref wave with different stimsets
	WAVE setColumns            ///< Set (aka column) to use for each stimset
	variable preFeaturePoints  ///< Time in points which should be kept signal-free before features
	variable postFeaturePoints ///< Time in points which should be kept signal-free after features
	///@}

	///@name Output
	///@{
	WAVE offsets               ///< Result of the optimization in points
	WAVE/T regions             ///< List of the form `%begin-%end;...` which denotes the x-coordinates of
	                           ///< the smeared regions in units of time of the DAQDataWave. @sa OOD_GetFeatureRegions()
	///@}
EndStructure

/// @brief The structure passed into `V3` and later analysis functions
Structure AnalysisFunction_V3
	/// one of @ref EVENT_TYPE_ANALYSIS_FUNCTIONS
	variable eventType

	/// raw data wave for interacting with the DAC hardware (locked to prevent
	/// changes using `SetWaveLock`). The exact wave format depends on the hardware.
	/// @sa GetDAQDataWave()
	WAVE rawDACWave

	/// scaled and undecimated data from the DAC hardware, 2D floating-point wave
	/// Rows has channel data, one column per channel, channels are in the order DA/AD/TTL
	WAVE scaledDACWave

	/// active headstage index, `[0, NUM_HEADSTAGES[`
	variable headStage

	/// last valid row index in `rawDACWave` which will be filled with data at the
	/// end of DAQ. The total number of rows in `rawDACWave` might be higher
	/// due to alignment requirements of the data acquisition hardware.
	///
	/// Always `NaN` for #PRE_DAQ_EVENT/#PRE_SET_EVENT events.
	variable lastValidRowIndex

	/// last written row index in `rawDACWave`/`scaledDACWave` with already acquired data
	///
	/// Always `NaN` for #PRE_DAQ_EVENT/#PRE_SET_EVENT/#PRE_SWEEP_EVENT.
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

Function InitDeltaControlNames(s)
	STRUCT DeltaControlNames &s

	s.main   = ""
	s.delta  = ""
	s.dme    = ""
	s.ldelta = ""
	s.op     = ""
End

/// @brief Helper structure for WB_GetDeltaDimLabel()
Structure DeltaControlNames
	string main, delta, dme, op, ldelta
EndStructure

/// @brief Helper structure for TP data transfer to analysis
Structure TPAnalysisInput
	WAVE data
	variable clampAmp
	variable clampMode
	variable duration
	variable baselineFrac
	variable tpLengthPoints
	variable readTimeStamp
	variable hsIndex
	string panelTitle
	variable measurementMarker
	variable activeADCs
EndStructure

/// @brief Helper structure for GetPlotArea()
Structure RectD
	double top
	double left
	double bottom
	double right
EndStructure

Function InitRectD(s)
	STRUCT RectD &s

	s.left   = NaN
	s.right  = NaN
	s.top    = NaN
	s.bottom = NaN
End

/// @brief Helper structure for CA_HardwareDataTPKey()
Structure HardwareDataTPInput
	variable hardwareType
	variable numDACs, numActiveChannels
	variable numberOfRows
	variable samplingInterval
	WAVE DAGain, DACAmpTP
	variable testPulseLength, baselineFrac
EndStructure

/// @brief initializes a BufferedDrawInfo structure
///        The json path for AppendTracesToGraph and Labels is set empty by default
///        @sa TiledGraphAccelerateDraw
Function InitBufferedDrawInfo(STRUCT BufferedDrawInfo &s)

	s.jsonID = JSON_Parse("{}")
	JSON_AddTreeObject (s.jsonID, BUFFEREDDRAWAPPEND)
	JSON_AddTreeObject (s.jsonID, BUFFEREDDRAWLABEL)
	JSON_AddTreeObject (s.jsonID, BUFFEREDDRAWHIDDENTRACES)
	JSON_AddTreeObject (s.jsonID, BUFFEREDDRAWDDAQAXES)
	Make/FREE/WAVE/N=(MINIMUM_WAVE_SIZE_LARGE) tw
	WAVE/WAVE s.traceWaves = tw
	SetNumberInWaveNote(s.traceWaves, NOTE_INDEX, 0)
End

/// @brief Stores information for buffered draw
///        jsonID - stores information about traces and labels to draw/setup
///        traceWaves - wave ref wave with references to the trace waves (which are always non-free)
Structure BufferedDrawInfo
	variable jsonID
	WAVE/WAVE traceWaves
EndStructure
