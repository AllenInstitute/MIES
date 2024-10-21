#pragma TextEncoding="UTF-8"
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
	int32 count ///< Number of invocations of background function
	int32 threadDeadCount ///< DAQ/TP-MD with ITC hardware only: Number of successive tries to get data from the thread
	variable tickslastReceivedFifoPos ///< DAQ-MD with ITC hardware only: ticks count when the fifo position was last updated
	variable lastReceivedFifoPos ///< DAQ-MD with ITC hardware only: last received fifo position
EndStructure

Structure PostPlotSettings
	/// @name Trace averaging settings
	///@{
	variable averageTraces
	DFREF averageDataFolder
	///@}

	variable hideSweep

	/// Zero traces settings
	variable zeroTraces

	/// @name Time alignment settings
	///@{
	variable timeAlignment
	variable timeAlignMode //< one of #TimeAlignmentConstants
	string timeAlignRefTrace
	variable timeAlignLevel
	///@}

	variable visualizeEpochs

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

	///@{
	/// These settings influence the extracted single pulse waves, see also
	/// PA_GenerateAllPulseWaves().
	variable startingPulse, endingPulse, overridePulseLength, fixedPulseLength
	///@}

	DFREF dfr

	STRUCT PulseAverageDeconvSettings deconvolution
EndStructure

Structure PulseAverageDeconvSettings
	variable enable, smth, tau, range
EndStructure

///@{
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

///@}

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
	int16 visualizeEpochs
EndStructure

/// @brief Helper structure for formula parsing of the Wavebuilder combine epoch
Structure FormulaProperties
	string formula, stimsetList
	variable numRows, numCols /// minimum number of rows and colums in the referenced sets
EndStructure

Function InitFormulaProperties(fp)
	STRUCT FormulaProperties &fp

	fp.formula     = ""
	fp.stimsetList = ""
	fp.numRows     = NaN
	fp.numCols     = NaN
End

/// @brief Helper structure for UpgradeWaveLocationAndGetIt()
Structure WaveLocationMod
	DFREF dfr ///< former location of the wave
	DFREF newDFR ///< new location of the wave (can be invalid)
	string name ///< former name of the wave
	string newName ///< new name of the wave (can be null/empty)
EndStructure

Function InitOOdDAQParams(params, stimSets, setColumns, preFeatureTime, postFeatureTime)
	STRUCT OOdDAQParams &params
	WAVE/WAVE            stimSets
	WAVE                 setColumns
	variable preFeatureTime, postFeatureTime

	ASSERT(DimSize(stimSets, ROWS) >= 1, "Stimsets wave is empty")
	ASSERT(preFeatureTime >= 0, "Unexpected pre feature time")
	ASSERT(postFeatureTime >= 0, "Unexpected post feature time")
	ASSERT(DimSize(stimSets, ROWS) == DimSize(setColumns, ROWS), "Mismatched simtSets and setColumns sizes")

	WaveClear params.offsets
	WaveClear params.regions

	WAVE params.stimSets   = stimSets
	WAVE params.setColumns = setColumns
	params.preFeaturePoints  = preFeatureTime / WAVEBUILDER_MIN_SAMPINT
	params.postFeaturePoints = postFeatureTime / WAVEBUILDER_MIN_SAMPINT
End

/// @brief Helper structure for Optimized overlap distributed acquisition (oodDAQ) functions
Structure OOdDAQParams
	///@name Input
	///@{
	WAVE/WAVE stimSets ///< Wave ref wave with different stimsets
	WAVE setColumns ///< Set (aka column) to use for each stimset
	variable preFeaturePoints ///< Time in points which should be kept signal-free before features
	variable postFeaturePoints ///< Time in points which should be kept signal-free after features
	///@}

	///@name Output
	/// @anchor OOdDAQParams_Output
	///@{
	WAVE offsets ///< Result of the optimization in points
	WAVE/T regions ///< List of the form `%begin-%end;...` which denotes the x-coordinates of
	///< the smeared regions in units of time of the DAQDataWave. @sa OOD_GetFeatureRegions()
	///@}
EndStructure

/// @brief The structure passed into `V3` and later analysis functions
Structure AnalysisFunction_V3
	/// one of @ref EVENT_TYPE_ANALYSIS_FUNCTIONS
	variable eventType

	/// scaled and undecimated data from the DAC hardware, wave ref wave where each element is a channel wave.
	/// Channels are in the same order as the config wave rows.
	WAVE/WAVE scaledDACWave

	/// active headstage index, `[0, NUM_HEADSTAGES[`
	variable headStage

	/// Potential *future* number of the sweep. Once the sweep is finished it will be
	/// saved with this number. Use GetSweepWave() to query the sweep itself.
	variable sweepNo

	/// Number of sweeps in the currently acquired stimset of the passed headstage
	variable sweepsInSet

	/// Analysis function parameters set in the stimset's textual parameter
	/// wave. Settable via AFH_AddAnalysisParameter().
	string params

	/// last valid row index for DA channels in `rawDAQWave` which will be filled with data at the
	/// end of DAQ. If the acquisition was aborted, the remaining samples beyond lastValidRowIndexDA
	/// are NaN.
	/// The total number of rows in `rawDAQWave` might be higher
	/// due to alignment requirements of the data acquisition hardware (e.g. ITC).
	///
	/// Always `NaN` for #PRE_DAQ_EVENT/#PRE_SET_EVENT events.
	variable lastValidRowIndexDA

	/// last valid row index for AD/TTL channels in `rawDAQWave` which will be filled with data at the
	/// end of DAQ. The total number of rows in `rawDAQWave` might be higher
	/// due to alignment requirements of the data acquisition hardware (e.g. ITC).
	///
	/// Always `NaN` for #PRE_DAQ_EVENT/#PRE_SET_EVENT events.
	variable lastValidRowIndexAD

	/// last written row index in `rawDAQWave`/`scaledDACWave`s DA channel(s) with already acquired data
	///
	/// Always `NaN` for #PRE_DAQ_EVENT/#PRE_SET_EVENT/#PRE_SWEEP_CONFIG_EVENT.
	variable lastKnownRowIndexDA

	/// last written row index in `rawDAQWave`/`scaledDACWave`s AD/TTL channel(s) with already acquired data
	///
	/// Always `NaN` for #PRE_DAQ_EVENT/#PRE_SET_EVENT/#PRE_SWEEP_CONFIG_EVENT.
	variable lastKnownRowIndexAD

	/// sample interval of DA channel(s) in ms
	variable sampleIntervalDA

	/// sample interval of AD channel(s) in ms
	variable sampleIntervalAD
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
	variable tpLengthPointsADC
	variable pulseLengthPointsADC
	variable pulseStartPointsADC
	variable samplingIntervalADC
	variable tpLengthPointsDAC
	variable pulseLengthPointsDAC
	variable pulseStartPointsDAC
	variable samplingIntervalDAC
	variable baselineFrac
	variable readTimeStamp
	variable hsIndex
	string device
	variable measurementMarker
	variable activeADCs
	variable timeStamp
	variable timeStampUTC
	variable cycleId
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
	WAVE gains, DACAmpTP
	variable testPulseLength, baselineFrac
EndStructure

/// @brief initializes a BufferedDrawInfo structure
///        The json path for AppendTracesToGraph and Labels is set empty by default
///        @sa TiledGraphAccelerateDraw
Function InitBufferedDrawInfo(STRUCT BufferedDrawInfo &s)

	s.jsonID = JSON_Parse("{}")
	JSON_AddTreeObject(s.jsonID, BUFFEREDDRAWAPPEND)
	JSON_AddTreeObject(s.jsonID, BUFFEREDDRAWLABEL)
	JSON_AddTreeObject(s.jsonID, BUFFEREDDRAWHIDDENTRACES)
	JSON_AddTreeObject(s.jsonID, BUFFEREDDRAWDDAQAXES)
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

/// @brief Helper strucuture for PSQ_CR_DetermineBoundsState()
Structure ChirpBoundsInfo
	variable minimumFac, centerFac, maximumFac
	string state
EndStructure

/// @brief Helper structure for the ASYNC NWB writing during DAQ
///
/// @sa NWB_ASYNC_SerializeStruct() and NWB_ASYNC_DeserializeStruct()
Structure NWBAsyncParameters
	string device, userComment, nwbFilePath

	variable sweep, compressionMode, session_start_time
	variable locationID, nwbVersion

	// DAQDataWave is a waveRef wave referencing the sweep channels from the main thread
	// See also @ref GetSweepWave "intermediate sweep format"
	WAVE DAQDataWave, DAQConfigWave

	WAVE numericalValues
	WAVE/T numericalKeys
	WAVE/T textualValues
	WAVE/T textualKeys

	WAVE numericalResultsValues
	WAVE/T numericalResultsKeys
	WAVE/T textualResultsValues
	WAVE/T textualResultsKeys
EndStructure

Function NWB_ASYNC_SerializeStruct(STRUCT NWBAsyncParameters &s, DFREF threadDFR)

	ASYNC_AddParam(threadDFR, str = s.device, name = "device")
	ASYNC_AddParam(threadDFR, str = s.userComment, name = "userComment")

	ASYNC_AddParam(threadDFR, var = s.sweep, name = "sweep")
	ASYNC_AddParam(threadDFR, var = s.compressionMode, name = "compressionMode")
	ASYNC_AddParam(threadDFR, var = s.session_start_time, name = "session_start_time")
	ASYNC_AddParam(threadDFR, var = s.locationID, name = "locationID")
	ASYNC_AddParam(threadDFR, var = s.nwbVersion, name = "nwbVersion")

	ASYNC_AddParam(threadDFR, w = s.DAQDataWave, name = "DAQDataWave")
	ASYNC_AddParam(threadDFR, w = s.DAQConfigWave, name = "DAQConfigWave")

	ASYNC_AddParam(threadDFR, w = s.numericalValues, name = "numericalValues")
	ASYNC_AddParam(threadDFR, w = s.numericalKeys, name = "numericalKeys")
	ASYNC_AddParam(threadDFR, w = s.textualValues, name = "textualValues")
	ASYNC_AddParam(threadDFR, w = s.textualKeys, name = "textualKeys")

	ASYNC_AddParam(threadDFR, w = s.numericalResultsValues, name = "numericalResultsValues")
	ASYNC_AddParam(threadDFR, w = s.numericalResultsKeys, name = "numericalResultsKeys")
	ASYNC_AddParam(threadDFR, w = s.textualResultsValues, name = "textualResultsValues")
	ASYNC_AddParam(threadDFR, w = s.textualResultsKeys, name = "textualResultsKeys")
End

threadsafe Function [STRUCT NWBAsyncParameters s] NWB_ASYNC_DeserializeStruct(DFREF threadDFR)

	s.device      = ASYNC_FetchString(threadDFR, "device")
	s.userComment = ASYNC_FetchString(threadDFR, "userComment")
	// always an empty string as we are not writing epoch info during sweep-by-sweep export
	s.nwbFilePath = ""

	s.sweep              = ASYNC_FetchVariable(threadDFR, "sweep")
	s.compressionMode    = ASYNC_FetchVariable(threadDFR, "compressionMode")
	s.session_start_time = ASYNC_FetchVariable(threadDFR, "session_start_time")

	s.locationID = ASYNC_FetchVariable(threadDFR, "locationID")
	s.nwbVersion = ASYNC_FetchVariable(threadDFR, "nwbVersion")

	WAVE s.DAQDataWave = ASYNC_FetchWave(threadDFR, "DAQDataWave")
	ASSERT_TS(IsWaveRefWave(s.DAQDataWave), "Unsupported sweep wave format")
	ChangeWaveLock(s.DAQDataWave, 1)

	WAVE s.DAQConfigWave = ASYNC_FetchWave(threadDFR, "DAQConfigWave")
	ChangeWaveLock(s.DAQConfigWave, 1)

	WAVE s.numericalValues = ASYNC_FetchWave(threadDFR, "numericalValues")
	ChangeWaveLock(s.numericalValues, 1)

	WAVE/T s.numericalKeys = ASYNC_FetchWave(threadDFR, "numericalKeys")
	ChangeWaveLock(s.numericalKeys, 1)

	WAVE/T s.textualValues = ASYNC_FetchWave(threadDFR, "textualValues")
	ChangeWaveLock(s.textualValues, 1)

	WAVE/T s.textualKeys = ASYNC_FetchWave(threadDFR, "textualKeys")
	ChangeWaveLock(s.textualKeys, 1)

	WAVE s.numericalResultsValues = ASYNC_FetchWave(threadDFR, "numericalResultsValues")
	ChangeWaveLock(s.numericalResultsValues, 1)

	WAVE/T s.numericalResultsKeys = ASYNC_FetchWave(threadDFR, "numericalResultsKeys")
	ChangeWaveLock(s.numericalResultsKeys, 1)

	WAVE/T s.textualResultsValues = ASYNC_FetchWave(threadDFR, "textualResultsValues")
	ChangeWaveLock(s.textualResultsValues, 1)

	WAVE/T s.textualResultsKeys = ASYNC_FetchWave(threadDFR, "textualResultsKeys")
	ChangeWaveLock(s.textualResultsKeys, 1)
End

/// @brief Structure to hold the result of data configuration from DC_GetConfiguration()
Structure DataConfigurationResult
	/// Various GUI settings
	///@{
	variable globalTPInsert
	variable scalingZero
	variable indexingLocked
	variable indexing
	variable distributedDAQ
	variable distributedDAQOptOv
	variable distributedDAQOptPre
	variable distributedDAQOptPost
	variable multiDevice
	variable powerSpectrum
	WAVE statusHS
	///@}

	/// What type of operation is done.
	/// Either DAQ(`DATA_ACQUISITION_MODE`) or TP(`TEST_PULSE_MODE`)
	variable dataAcqOrTP

	/// @sa GetTestpulseBaselineFraction()
	variable baselineFrac

	/// @sa DC_GetDecimationFactor()
	variable decimationFactor

	/// Number of DAC's, always larger than 0.
	variable numDACEntries

	/// Number of ADC's, always larger than 0.
	variable numADCEntries

	/// Number of TTLs, can be zero.
	variable numTTLEntries

	/// Sum of numDACEntries/numADCEntries/numTTLEntries
	variable numActiveChannels

	/// One of @ref HardwareDACTypeConstants
	variable hardwareType

	/// Sampling interval for DA channels in μs, @sa DAP_GetSampInt()
	variable samplingIntervalDA
	/// Sampling interval for AD channels in μs, @sa DAP_GetSampInt()
	variable samplingIntervalAD
	/// Sampling interval for TTL channels in μs, @sa DAP_GetSampInt()
	variable samplingIntervalTTL

	/// @name Various delays in points of the DA data wave
	///@{
	variable onsetDelayUser
	variable onsetDelayAuto
	variable onsetDelay ///< Sum of onsetDelayUser and onsetDelayAuto
	variable distributedDAQDelay
	variable terminationDelay
	///@}

	/// @sa GetTestPulse()
	WAVE testPulse

	/// Length of the DataConfigurationResult::testPulse wave in points
	/// test pulse properties from @ref TP_GetCreationPropertiesInPoints
	variable testPulseLength
	variable tpPulseStartPoint
	variable tpPulseLengthPoints

	/// oodDAQ optimization results, see @ref OOdDAQParams_Output
	///@{
	WAVE offsets ///< [ms]
	WAVE/T regions
	///@}

	/// @sa SWS_GetChannelGains() with `GAIN_BEFORE_DAQ`
	WAVE gains

	/// List of active channels per type
	///@{
	WAVE DACList
	WAVE ADCList
	WAVE TTLList
	///@}

	/// All waves here use active channel indexing like DataConfigurationResult::DACList
	/// and can thus be all indexed together.
	///@{
	/// @sa GetDACAmplitudes()
	WAVE/D DACAmp

	/// Stimulus set name
	WAVE/T setName
	WAVE/T TTLsetName

	/// Stimulus set wave (2D)
	WAVE/WAVE stimSet
	WAVE/WAVE TTLstimSet

	/// @sa DC_CalculateStimsetLength()
	WAVE/D setLength
	WAVE/D TTLsetLength

	/// Headstage of DAC if associated, `NaN` iff unassociated
	WAVE/D headstageDAC

	/// @sa DC_CalculateChannelColumnNo()
	///@{
	WAVE/D setColumn
	WAVE/D TTLsetColumn
	WAVE/D setCycleCount
	WAVE/D TTLcycleCount
	///@}

	/// Offset in points where the stimulus set starts in the DAQ data wave
	WAVE/D insertStart
	///@}

	/// Headstage of ADC if associated, `NaN` iff unassociated
	/// Uses active channel indexing like DataConfigurationResult::ADCList
	WAVE/D headstageADC

	/// Number of sweeps to skip over on start of data acquisition
	variable skipAhead

	/// Maximum number of samples that can be acquired to the data wave
	/// For ITC can be higher that planned samples to be acquired (no automatic stop, only programmatic)
	variable stopCollectionPoint

	/// for ITC, TTL stimset size in DC after TTL stimsets were bit-combined to a joined wave
	/// fixing https://github.com/AllenInstitute/MIES/issues/2007 should remove the need for this
	variable joinedTTLStimsetSize

	/// wave indexing GUI TTL channels, 1 - activated, 0 deactivated
	WAVE statusTTLFiltered
EndStructure

/// @brief Helper struct for storing the number of active channels per rack
Structure ActiveChannels
	int32 numDARack1
	int32 numADRack1
	int32 numTTLRack1
	int32 numDARack2
	int32 numADRack2
	int32 numTTLRack2
EndStructure

/// @brief Settings structure filled by PSQ_GetPulseSettingsForType()
Structure PSQ_PulseSettings
	variable prePulseChunkLength // ms
	variable pulseDuration // ms
	variable postPulseChunkLength // ms

	/// Allows to define the baseline chunks by user epochs with shortname `U_BLS%d`
	/// other members are ignored with this option.
	/// The baseline chunks should be added in PRE_SWEEP_CONFIG_EVENT.
	variable usesBaselineChunkEpochs
EndStructure

Structure CheckParametersStruct
	string params // supplied analysis functions parameters
	string setName // name of the stimulus set
EndStructure

/// @brief Helper struct for data gathered by SF formula plotter in SF_GatherFormulaResults
Structure SF_PlotMetaData
	string dataType // from SF_META_DATATYPE constant
	string opStack // from SF_META_OPSTACK constant
	string argSetupStack // from SF_META_ARGSETUPSTACK constant
	string xAxisLabel // from SF_META_XAXISLABEL constant
	string yAxisLabel // from SF_META_YAXISLABEL constant
EndStructure

/// @brief ReadOut Structure for ASYNC
Structure ASYNC_ReadOutStruct
	DFREF dfr // dfr with output data
	variable rtErr // runtime error code
	string rtErrMsg // runtime error message
	variable abortCode // abort code
EndStructure

/// @brief Wraps all parameters combined for one SF select call
///        When adapting also change @ref SF_DuplicateSelectFilter
///        Initialization with uninitialized state value @see SF_InitSelectFilterUninitalized
///        Initialization with defaults for uninitialized elements after select argument parsing @see SF_SetSelectionFilterDefaults
Structure SF_SelectParameters
	WAVE selects // selection wave (SF_DATATYPE_SELECT) or null if no select(...) argument appeared
	WAVE channels // result from channels(...) (SF_DATATYPE_CHANNELS), if no argument was given result of "selchannels()"
	WAVE sweeps // result from selsweeps(...) (SF_DATATYPE_SWEEPNO), if no argument was given result of "selsweeps()"
	variable sweepsSet // 1 if WAVE sweeps was set due to a selsweeps(...) argument, 0 otherwise
	string vis // result from selvis(...), if this argument was given one of SF_OP_SELECTVIS_*, if not then if a select argument was given SF_OP_SELECTVIS_ALL, SF_OP_SELECTVIS_DISPLAYED otherwise
	variable clampMode // result from selcm(...), if this argument was given a bit combination of SF_OP_SELECT_CLAMPCODE_*, SF_OP_SELECT_CLAMPCODE_ALL otherwise
	WAVE/T stimsets // result from setstimset(...), wildcard patterns, if this argument was not given "*"
	WAVE ranges // result from selrange(...), if this argument was not given the full range
	variable sweepQC // result from selivsccsweepqc(...), if this argument was given SF_OP_SELECT_IVSCCSWEEPQC_PASSED or SF_OP_SELECT_IVSCCSWEEPQC_FAILED, SF_OP_SELECT_IVSCCSWEEPQC_IGNORE otherwise
	variable setQC // result from selivsccsetqc(...), if this argument was given SF_OP_SELECT_IVSCCSETQC_PASSED or SF_OP_SELECT_IVSCCSETQC_FAILED, SF_OP_SELECT_IVSCCSETQC_IGNORE otherwise
	string experimentName // result from selexp(...), wildcard pattern if this argument was not given, "" otherwise
	string device // result from seldev(...), wildcard pattern if this argument was not given, "" otherwise
	variable expandSCI // result from selexpandsci(...), 1 if this argument was given, 0 otherwise
	variable expandRAC // result from selexpandrac(...), 1 if this argument was given, 0 otherwise
	variable setCycleCount // result from selsetcyclecount(x), x if this argument was given, NaN otherwise
	variable setSweepCount // result from selsetsweepcount(x), x if this argument was given, NaN otherwise
	variable sciIndex // result from selsciindex(x), x if this argument was given, NaN otherwise
	variable racIndex // result from selracindex(x), x if this argument was given, NaN otherwise
EndStructure
