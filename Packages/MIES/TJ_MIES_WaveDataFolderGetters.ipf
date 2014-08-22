#pragma rtGlobals=3

/// @brief Return a wave reference to the channel <-> amplifier relation wave (numeric part)
///
/// Rows:
/// - 0-3: V-Clamp: DA channel number of amp (0 or 1), DA gain, AD channel, AD gain
/// - 4-7: I-Clamp: DA channel number of amp (0 or 1), DA gain, AD channel, AD gain
/// - 8: Amplifier Serial number as returned by `AxonTelegraphFindServers`. This differs
///      compared to the ones returned by `MCC_FindServers`, as the latter are strings with leading zeros.
///      E.g.: "00000123" vs 123
///      E.g.: "Demo"     vs 0
/// - 9: Amplifier Channel ID
/// - 10: Index into popup_Settings_Amplifier in the DA_Ephys panel
/// - 11: Unused
///
/// Columns:
/// - Head stage number
///
Function/Wave GetChanAmpAssign(panelTitle)
	string panelTitle

	DFREF dfr = HSU_GetDevicePathFromTitle(panelTitle)

	Wave/Z/SDFR=dfr wv = ChanAmpAssign

	if(WaveExists(wv))
		return wv
	endif

	Make/N=(12,8) dfr:ChanAmpAssign/Wave=wv
	wv = NaN

	return wv
End

/// @brief Return a wave reference to the channel <-> amplifier relation wave (textual part)
///
/// Rows:
/// - 0: DA unit (V-Clamp mode)
/// - 1: AD unit (V-Clamp mode)
/// - 3: DA unit (I-Clamp mode)
/// - 4: AD unit (I-Clamp mode)
///
/// Columns:
/// - Head stage number
///
Function/Wave GetChanAmpAssignUnit(panelTitle)
	string panelTitle

	DFREF dfr = HSU_GetDevicePathFromTitle(panelTitle)

	Wave/T/Z/SDFR=dfr wv = ChanAmpAssignUnit

	if(WaveExists(wv))
		return wv
	endif

	Make/T/N=(4,8) dfr:ChanAmpAssignUnit/Wave=wv
	wv = ""

	return wv
End

/// @brief Return a wave reference to the channel clamp mode wave
///
/// Rows:
/// - Channel numbers
///
/// Columns:
/// - 0: DAC channels
/// - 1: ADC channels
///
/// Contents:
/// - Clamp mode: One of V_CLAMP_MODE, I_CLAMP_MODE and I_EQUAL_ZERO_MODE
Function/Wave GetChannelClampMode(panelTitle)
	string panelTitle

	DFREF dfr = HSU_GetDevicePathFromTitle(panelTitle)

	Wave/Z/SDFR=dfr wv = ChannelClampMode

	if(WaveExists(wv))
		return wv
	endif

	Make/N=(16,2) dfr:ChannelClampMode/Wave=wv

	SetDimLabel COLS, 0, DAC, wv
	SetDimLabel COLS, 1, ADC, wv

	return wv
End

/// @brief Returns a wave reference to the SweepData
///
/// SweepData is used to store GUI configuration info which can then be transferred into the documenting functions
///
/// Rows:
/// - Only one
///
/// Columns:
/// - 0: DAC
/// - 1: ADC
/// - 2: DA Gain
/// - 3: AD Gain
/// - 4: DA Scale
/// - 5: Set sweep count 
///
/// Layers:
/// - Headstage
Function/Wave DC_SweepDataWvRef(panelTitle)
	string panelTitle
	
	DFREF dfr = HSU_GetDevicePathFromTitle(panelTitle)

	Wave/Z/SDFR=dfr wv = SweepData

	if(WaveExists(wv))
		return wv
	endif

	Make/N=(1, 6, 8) dfr:SweepData/Wave=wv
	wv = NaN

	return wv
End

/// @brief Returns a wave reference to the SweepTxtData
///
/// SweepTxtData is used to store the set name used on a particular headstage
/// Rows:
/// - Only one
///
/// Columns:
/// - 0: SetName
///
/// Layers:
/// - Headstage
Function/Wave DC_SweepDataTxtWvRef(panelTitle)
	string panelTitle
	
	DFREF dfr = HSU_GetDevicePathFromTitle(panelTitle)

	Wave/Z/T/SDFR=dfr wv = SweepTxtData

	if(WaveExists(wv))
		return wv
	endif

	Make/T/N=(1,1,8) dfr:SweepTxtData/Wave=wv
	wv = ""

	return wv
End

/// @name Experiment Documentation
/// @{

/// @brief Return the datafolder reference to the lab notebook
Function/DF GetLabNotebookFolder(panelTitle)
	string panelTitle

	return createDFWithAllParents(GetLabNotebookFolderAsString(panelTitle))
End

/// @brief Return the full path to the lab notebook, e.g. root:MIES:LabNoteBook
Function/S GetLabNotebookFolderAsString(panelTitle)
	string panelTitle

	return Path_MIESfolder(panelTitle) + ":LabNoteBook"
End

/// @brief Return the data folder reference to the device specific lab notebook
Function/DF GetDevSpecLabNBFolder(panelTitle)
	string panelTitle

	return createDFWithAllParents(GetDevSpecLabNBFolderAsString(panelTitle))
End

/// @brief Return the full path to the device specific lab notebook, e.g. root:MIES:LabNoteBook:ITC18USB:Device0
Function/S GetDevSpecLabNBFolderAsString(panelTitle)
	string panelTitle

	string deviceType, deviceNumber
	variable ret

	ret = ParseDeviceString(panelTitle, deviceType, deviceNumber)
	ASSERT(ret, "Could not parse the panelTitle")

	return GetLabNotebookFolderAsString(panelTitle) + ":" + deviceType + ":Device" + deviceNumber
End

/// @brief Return the datafolder reference to the device specific settings key
Function/DF GetDevSpecLabNBSettKeyFolder(panelTitle)
	string panelTitle

	return createDFWithAllParents(GetDevSpecLabNBSettKeyFolderAS(panelTitle))
End

/// @brief Return the full path to the device specific settings key, e.g. root:mies:LabNoteBook:ITC18USB:Device0:KeyWave
Function/S GetDevSpecLabNBSettKeyFolderAS(panelTitle)
	string panelTitle

	return GetDevSpecLabNBFolderAsString(panelTitle) + ":KeyWave"
End

/// @brief Return the datafolder reference to the device specific settings history
Function/DF GetDevSpecLabNBSettHistFolder(panelTitle)
	string panelTitle

	return createDFWithAllParents(GetDevSpecLabNBSettHistFolderAS(panelTitle))
End

/// @brief Return the full path to the device specific settings history, e.g. root:mies:LabNoteBook:ITC18USB:Device0:settingsHistory
Function/S GetDevSpecLabNBSettHistFolderAS(panelTitle)
	string panelTitle

	return GetDevSpecLabNBFolderAsString(panelTitle) + ":settingsHistory"
End

/// @brief Return the datafolder reference to the device specific text doc key
Function/DF GetDevSpecLabNBTxtDocKeyFolder(panelTitle)
	string panelTitle

	return createDFWithAllParents(GetDevSpecLabNBTextDocKeyFoldAS(panelTitle))
End

/// @brief Return the full path to the device specific text doc key, e.g. root:mies:LabNoteBook:ITC18USB:Device0:textDocKeyWave
Function/S GetDevSpecLabNBTextDocKeyFoldAS(panelTitle)
	string panelTitle

	return GetDevSpecLabNBFolderAsString(panelTitle) + ":TextDocKeyWave"
End

/// @brief Return the datafolder reference to the device specific text documentation
Function/DF GetDevSpecLabNBTextDocFolder(panelTitle)
	string panelTitle

	return createDFWithAllParents(GetDevSpecLabNBTextDocFolderAS(panelTitle))
End

/// @brief Return the full path to the device specific text documentation, e.g. root:mies:LabNoteBook:ITC18USB:Device0:textDocumentation
Function/S GetDevSpecLabNBTextDocFolderAS(panelTitle)
	string panelTitle

	return GetDevSpecLabNBFolderAsString(panelTitle) + ":textDocumentation"
End

/// @brief Returns a wave reference to the textDocWave
///
/// textDocWave is used to save settings for each data sweep and
/// create waveNotes for tagging data sweeps
///
/// Rows:
/// - Only one
///
/// Columns:
/// - 0: Sweep Number
/// - 1: Time Stamp
///
/// Layers:
/// - Headstage
Function/Wave GetTextDocWave(panelTitle)
	string panelTitle

	DFREF dfr = GetDevSpecLabNBTextDocFolder(panelTitle)

	Wave/Z/T/SDFR=dfr wv = txtDocWave

	if(WaveExists(wv))
		return wv
	endif

	Make/T/N=(1,2,0) dfr:txtDocWave/Wave=wv
	wv = ""

	return wv
End

/// @brief Returns a wave reference to the textDocKeyWave
///
/// textDocKeyWave is used to index save settings for each data sweep
/// and create waveNotes for tagging data sweeps
///
/// Rows:
/// - 0: Parameter Name
///
/// Columns:
/// - 0: Sweep Number
/// - 1: Time Stamp
///
/// Layers:
/// - Headstage
Function/Wave GetTextDocKeyWave(panelTitle)
	string panelTitle

	DFREF dfr = GetDevSpecLabNBTxtDocKeyFolder(panelTitle)

	Wave/Z/T/SDFR=dfr wv = txtDocKeyWave

	if(WaveExists(wv))
		return wv
	endif

	Make/T/N=(1,2,0) dfr:txtDocKeyWave/Wave=wv
	wv = ""

	SetDimLabel 0, 0, Parameter, wv

	return wv
End

/// @brief Returns a wave reference to the sweepSettingsWave
///
/// sweepSettingsWave is used to save stimulus settings for each
/// data sweep and create waveNotes for tagging data sweeps
///
/// Rows:
///  - One row
///
/// Columns:
/// - 0: Stim Wave Name
/// - 1: Stim Scale Factor
///
/// Layers:
/// - Headstage
Function/Wave GetSweepSettingsWave(panelTitle, noHeadStages)
	string panelTitle
	variable noHeadStages

	DFREF dfr = GetDevSpecLabNBSettHistFolder(panelTitle)

	Wave/Z/SDFR=dfr wv = sweepSettingsWave

	if(WaveExists(wv))
		// we have to resize the wave here as the user relies
		// on the requested size
		if(DimSize(wv, LAYERS) != noHeadStages)
			Redimension/N=(-1, -1, noHeadStages) wv
		endif
		return wv
	endif

	Make/N=(1,6,noHeadStages) dfr:sweepSettingsWave/Wave=wv
	wv = Nan

	return wv
End

/// @brief Returns a wave reference to the sweepSettingsKeyWave
///
/// sweepSettingsKeyWave is used to index save stimulus settings for
/// each data sweep and create waveNotes for tagging data sweeps
///
/// Rows:
/// - 0: Parameter
/// - 1: Units
/// - 2: Tolerance Factor
///
/// Columns:
/// - 0: Stim Scale Factor
/// - 1: DAC
/// - 2: ADC
/// - 3: DA Gain
/// - 4: AD Gain
/// - 5: Set sweep count
///
/// Layers:
/// - Headstage
Function/Wave GetSweepSettingsKeyWave(panelTitle)
	string panelTitle

	DFREF dfr = GetDevSpecLabNBSettKeyFolder(panelTitle)

	Wave/Z/T/SDFR=dfr wv = sweepSettingsKeyWave

	if(WaveExists(wv))
		return wv
	endif

	Make/T/N=(3,6) dfr:sweepSettingsKeyWave/Wave=wv
	wv = ""

	SetDimLabel 0, 0, Parameter, wv
	SetDimLabel 0, 1, Units, wv
	SetDimLabel 0, 2, Tolerance, wv

	wv[%Parameter][0] = "Stim Scale Factor"
	wv[%Units][0]     = "%"
	wv[%Tolerance][0] = ".0001"

	wv[%Parameter][1] = "DAC"
	wv[%Units][1]     = ""
	wv[%Tolerance][1] = ".0001"

	wv[%Parameter][2] = "ADC"
	wv[%Units][2]     = ""
	wv[%Tolerance][2] = ".0001"

	wv[%Parameter][3] = "DA Gain"
	wv[%Units][3]     = "mV/V"
	wv[%Tolerance][3] = ".000001"

	wv[%Parameter][4] = "AD Gain"
	wv[%Units][4]     = "V/pA"
	wv[%Tolerance][4] = ".000001"

	wv[%Parameter][5] = "Set Sweep Count"
	wv[%Units][5]     = ""
	wv[%Tolerance][5] = ".0001"

	return wv
End

/// @brief Returns a wave reference to the SweepSettingsTxtWave
///
/// SweepSettingsTxtData is used to store the set name used on a particular
/// headstage and then create waveNotes for the sweep data
///
/// Rows:
/// - Only one
///
/// Columns:
/// - 0: SetName
///
/// Layers:
/// - Headstage
Function/Wave GetSweepSettingsTextWave(panelTitle, noHeadStages)
	string panelTitle
	variable noHeadStages

	DFREF dfr = GetDevSpecLabNBTextDocFolder(panelTitle)

	Wave/Z/T/SDFR=dfr wv = SweepSettingsTxtData

	if(WaveExists(wv))
		// we have to resize the wave here as the user relies
		// on the requested size
		if(DimSize(wv, LAYERS) != noHeadStages)
			Redimension/N=(-1, -1, noHeadStages) wv
		endif
		return wv
	endif

	Make/T/N=(1,1,noHeadStages) dfr:SweepSettingsTxtData/Wave=wv
	wv = ""

	return wv
End

/// @brief Returns a wave reference to the SweepSettingsKeyTxtData
///
/// SweepSettingsKeyTxtData is used to index Txt Key Wave
///
/// Rows:
/// - Only one
///
/// Columns:
/// - 0: SetName
///
/// Layers:
/// - Headstage
Function/Wave GetSweepSettingsTextKeyWave(panelTitle, noHeadStages)
	string panelTitle
	variable noHeadStages

	DFREF dfr = GetDevSpecLabNBTxtDocKeyFolder(panelTitle)

	Wave/Z/T/SDFR=dfr wv = SweepSettingsKeyTxtData

	if(WaveExists(wv))
		// we have to resize the wave here as the user relies
		// on the requested size
		if(DimSize(wv, LAYERS) != noHeadStages)
			Redimension/N=(-1, -1, noHeadStages) wv
		endif
		return wv
	endif

	Make/T/N=(1,1,noHeadStages) dfr:SweepSettingsKeyTxtData/Wave=wv
	wv = ""

	return wv
End
/// @}

/// @brief Return a wave reference for TPStorage
///
/// The wave stores TP resistance and Vm data as
/// function of time while the TP is running.
Function/Wave GetTPStorage(panelTitle)
	string 	panelTitle

	dfref dfr = GetDeviceTestPulse(panelTitle)
	Wave/Z/SDFR=dfr wv = TPStorage

	if(WaveExists(wv))
		return wv
	endif

	Make/N=(128,8,8) dfr:TPStorage/Wave=wv
	wv = NaN

	SetDimLabel COLS,  -1, HeadStage            , wv

	SetDimLabel LAYERS, 0, Vm                   , wv
	SetDimLabel LAYERS, 1, PeakResistance       , wv
	SetDimLabel LAYERS, 2, SteadyStateResistance, wv
	SetDimLabel LAYERS, 3, TimeInSeconds        , wv
	SetDimLabel LAYERS, 4, DeltaTimeInSeconds   , wv
	SetDimLabel LAYERS, 5, Vm_Slope             , wv
	SetDimLabel LAYERS, 6, Rpeak_Slope          , wv
	SetDimLabel LAYERS, 7, Rss_Slope            , wv

	Note wv, "TPCycleCount:0;"

	return wv
End

/// @brief Return a datafolder reference to the test pulse folder
Function/DF GetDeviceTestPulse(panelTitle)
	string panelTitle

	return createDFWithAllParents(GetDeviceTestPulseAsString(panelTitle))
End

/// @brief Return the path to the test pulse folder, e.g. root:mies::ITCDevices:ITC1600:Device0:TestPulse
Function/S GetDeviceTestPulseAsString(panelTitle)
	string panelTitle

	return HSU_DataFullFolderPathString(panelTitle) + ":TestPulse"
End

/// @brief Return a datafolder reference to the device type folder
Function/DF GetDeviceTypePath(deviceType)
	string deviceType

	return createDFWithAllParents(GetDeviceTypePathAsString(deviceType))
End

/// @brief Return the path to the device type folder, e.g. root:mies::ITCDevices:ITC1600
Function/S GetDeviceTypePathAsString(deviceType)
	string deviceType

	return Path_ITCDevicesFolder("") + ":" + deviceType
End

/// @brief Return a datafolder reference to the device folder
Function/DF GetDevicePath(deviceType, deviceNumber)
	string deviceType, deviceNumber

	return createDFWithAllParents(GetDevicePathAsString(deviceType, deviceNumber))
End

/// @brief Return the path to the device folder, e.g. root:mies::ITCDevices:ITC1600:Device0
Function/S GetDevicePathAsString(deviceType, deviceNumber)
	string deviceType, deviceNumber

	return GetDeviceTypePathAsString(deviceType) + ":Device" + deviceNumber
End

/// @brief Return a datafolder reference to the device data folder
Function/DF GetDeviceDataPath(deviceType, deviceNumber)
	string deviceType, deviceNumber

	return createDFWithAllParents(GetDeviceDataPathAsString(deviceType, deviceNumber))
End

/// @brief Return the path to the device folder, e.g. root:mies::ITCDevices:ITC1600:Device0:Data
Function/S GetDeviceDataPathAsString(deviceType, deviceNumber)
	string deviceType, deviceNumber

	return GetDevicePathAsString(deviceType, deviceNumber) + ":Data"
End

/// @brief Return the datafolder reference to the amplifier
Function/DF GetAmplifierFolder()
	return createDFWithAllParents(GetAmplifierFolderAsString())
End

/// @brief Return the path to the amplifierm e.g. root:mies:Amplifiers"
Function/S GetAmplifierFolderAsString()
	return Path_MIESfolder("") + ":Amplifiers"
End

/// @brief Return the datafolder reference to the amplifier settings
Function/DF GetAmpSettingsFolder()
	return createDFWithAllParents(GetAmpSettingsFolderAsString())
End

/// @brief Return the path to the amplifier settings, e.g. root:MIES:Amplifiers:Settings
Function/S GetAmpSettingsFolderAsString()
	return GetAmplifierFolderAsString() + ":Settings"
End

/// @brief Return a wave reference to the amplifier parameter storage wave
///
/// Rows:
/// - 0-31: Amplifier settings identified by dimension labels
///
/// Columns:
/// - Only one
///
/// Layers:
/// - 0-7: Headstage identifier
///
/// Contents:
/// - numerical amplifier settings
Function/Wave GetAmplifierParamStorageWave(panelTitle)
	string panelTitle

	DFREF dfr = GetAmpSettingsFolder()

	// wave's name is like ITC18USB_Dev_0
	Wave/Z/SDFR=dfr wv = $panelTitle

	if(WaveExists(wv))
		return wv
	endif

	Make/N=(31, 1, 8) dfr:$panelTitle/Wave=wv

	SetDimLabel LAYERS, -1, Headstage             , wv
	SetDimLabel ROWS  , 0 , HoldingPotential      , wv
	SetDimLabel ROWS  , 1 , HoldingPotentialEnable, wv
	SetDimLabel ROWS  , 2 , WholeCellCap          , wv
	SetDimLabel ROWS  , 3 , WholeCellRes          , wv
	SetDimLabel ROWS  , 4 , WholeCellEnable       , wv
	SetDimLabel ROWS  , 5 , Correction            , wv
	SetDimLabel ROWS  , 6 , Prediction            , wv
	SetDimLabel ROWS  , 7 , RsCompEnable          , wv
	SetDimLabel ROWS  , 8 , VClampPlaceHolder     , wv
	SetDimLabel ROWS  , 9 , VClampPlaceHolder     , wv
	SetDimLabel ROWS  , 10, VClampPlaceHolder     , wv
	SetDimLabel ROWS  , 11, VClampPlaceHolder     , wv
	SetDimLabel ROWS  , 12, VClampPlaceHolder     , wv
	SetDimLabel ROWS  , 13, VClampPlaceHolder     , wv
	SetDimLabel ROWS  , 14, VClampPlaceHolder     , wv
	SetDimLabel ROWS  , 15, VClampPlaceHolder     , wv
	SetDimLabel ROWS  , 16, BiasCurrent           , wv
	SetDimLabel ROWS  , 17, BiasCurrentEnable     , wv
	SetDimLabel ROWS  , 18, BridgeBalance         , wv
	SetDimLabel ROWS  , 19, BridgeBalanceEnable   , wv
	SetDimLabel ROWS  , 20, CapNeut               , wv
	SetDimLabel ROWS  , 21, CapNeutEnable         , wv
	SetDimLabel ROWS  , 22, AutoBiasVcom          , wv
	SetDimLabel ROWS  , 23, AutoBiasVcomVariance  , wv
	SetDimLabel ROWS  , 24, AutoBiasIbiasmax      , wv
	SetDimLabel ROWS  , 25, AutoBiasEnable        , wv
	SetDimLabel ROWS  , 26, IclampPlaceHolder     , wv
	SetDimLabel ROWS  , 27, IclampPlaceHolder     , wv
	SetDimLabel ROWS  , 28, IclampPlaceHolder     , wv
	SetDimLabel ROWS  , 29, IclampPlaceHolder     , wv
	SetDimLabel ROWS  , 30, IZeroEnable           , wv

	return wv
End
