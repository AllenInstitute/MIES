#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_AB
#endif

/// @file MIES_AnalysisBrowser.ipf
/// @brief __AB__ Analysis browser
///
/// Has no dependencies on any hardware related functions.

static Constant EXPERIMENT_TREEVIEW_COLUMN = 0
static Constant DEVICE_TREEVIEW_COLUMN     = 2
static Constant AB_LOAD_SWEEP = 0
static Constant AB_LOAD_STIMSET = 1

static Function AB_ResetListBoxWaves(variable newSize)

	variable col, val

	WAVE expBrowserSel    = GetExperimentBrowserGUISel()
	WAVE/T expBrowserList = GetExperimentBrowserGUIList()

	Redimension/N=(newSize, -1, -1, -1) expBrowserList, expBrowserSel

	if(DimSize(expBrowserSel, ROWS) > 0)
		expBrowserSel = 0

		val = LISTBOX_TREEVIEW | LISTBOX_TREEVIEW_EXPANDED

		col = FindDimLabel(expBrowserList, COLS, "experiment")
		ASSERT(col >= 0, "invalid column index")
		expBrowserSel[][col - 1] = !cmpstr(expBrowserList[p][col], "") ? 0 : val

		col = FindDimLabel(expBrowserList, COLS, "device")
		ASSERT(col >= 0, "invalid column index")
		expBrowserSel[][col - 1] = !cmpstr(expBrowserList[p][col], "") ? 0 : val
	endif

	// backup initial state
	WAVE/T expBrowserSelBak = CreateBackupWave(expBrowserSel, forceCreation=1)
	WAVE/T expBrowserListBak = CreateBackupWave(expBrowserList, forceCreation=1)
End

/// @brief Clear all waves of the main experiment browser
///        and delete all folders inside GetAnalysisFolder().
static Function AB_ClearAnalysisFolder()

	string folders

	WAVE/T map = GetAnalysisBrowserMap()
	map = ""
	SetNumberInWaveNote(map, NOTE_INDEX, 0)

	WAVE/T list = GetExperimentBrowserGUIList()
	list = ""
	SetNumberInWaveNote(list, NOTE_INDEX, 0)

	WAVE sel = GetExperimentBrowserGUISel()
	sel = NaN

	DFREF dfr = GetAnalysisFolder()
	folders = GetListOfDataFolders(dfr, absolute=1)
	CallFunctionForEachListItem_TS(KillOrMoveToTrashPath, folders)
End

/// @brief Create relation (map) between file on disk and datafolder in current experiment
///
/// @return index into mapping wave of the newly added entry or -1 if the file
///         is already in the map
static Function AB_AddMapEntry(baseFolder, discLocation)
	string baseFolder, discLocation

	variable index
	string dataFolder, fileType, relativePath, extension
	WAVE/T map = GetAnalysisBrowserMap()

	WAVE/Z indizes = FindIndizes(map, colLabel="DiscLocation", str = discLocation)

	if(WaveExists(indizes))
		DEBUGPRINT("Skipping duplicated file: ", str = discLocation)
		return -1
	endif

	index = GetNumberFromWaveNote(map, NOTE_INDEX)
	EnsureLargeEnoughWave(map, minimumSize=index, dimension=ROWS)

	// %DiscLocation = full path to file
	map[index][%DiscLocation] = discLocation

	// %FileName = filename + extension
	relativePath = RemovePrefix(discLocation, start = baseFolder)
	map[index][%FileName] = relativePath

	extension = "." + GetFileSuffix(discLocation)

	// %FileType = igor
	strswitch(extension)
		case ".pxp":
		case ".uxp":
			fileType = ANALYSISBROWSER_FILE_TYPE_IGOR
			break
		case ".nwb":
			fileType = ANALYSISBROWSER_FILE_TYPE_NWB
			break
		default:
			ASSERT(0, "invalid file type")
	endswitch
	map[index][%FileType] = fileType
	// %DataFolder = igor friendly DF name
	DFREF dfr = GetAnalysisFolder()
	DFREF expFolder = UniqueDataFolder(dfr, RemoveEnding(relativePath, extension))
	dataFolder = RemovePrefix(GetDataFolder(1, expFolder), start = GetDataFolder(1, dfr))
	map[index][%DataFolder] = RemoveEnding(dataFolder, ":")

	index += 1
	SetNumberInWaveNote(map, NOTE_INDEX, index)

	return index - 1
End

static Function AB_RemoveMapEntry(index)
	variable index

	WAVE/T map = GetAnalysisBrowserMap()

	ASSERT(index < DimSize(map, ROWS), "row index out-of-bounds")

	map[index][] = ""

	if(index + 1 == GetNumberFromWaveNote(map, NOTE_INDEX))
		SetNumberInWaveNote(map, NOTE_INDEX, index)
	endif
End

/// @brief  Get single matching entry from GetAnalysisBrowserMap
/// @param  discLocation: first column. Path to file on disc
/// @return wave with 4 columns
/// Columns:
/// 0: %DiscLocation:  Path to Experiment on Disc
/// 1: %FileName:      Name of File in experiment column in ExperimentBrowser
/// 2: %DataFolder     Data folder inside current Igor experiment
/// 3: %FileType       File Type identifier for routing to loader functions
Function/Wave AB_GetMap(discLocation)
	string discLocation

	WAVE/T map = GetAnalysisBrowserMap()

	FindValue/TXOP=4/TEXT=(discLocation) map
	ASSERT(V_Value >= 0, "invalid index")

	Make/FREE/N=4/T wv
	wv = 	map[V_Value][p]

	SetDimLabel ROWS, 0, DiscLocation, wv
	SetDimLabel ROWS, 1, FileName, wv
	SetDimLabel ROWS, 2, DataFolder, wv
	SetDimLabel ROWS, 3, FileType, wv

	return wv
End

/// @brief save deviceList to wave
/// @return created wave.
Function/Wave AB_SaveDeviceList(deviceList, dataFolder)
	String deviceList, dataFolder

	Variable numDevices
	Wave/T wv = GetAnalysisDeviceWave(dataFolder)

	Wave/T deviceListWave = ListToTextWave(deviceList, ";")
	numDevices = DimSize(deviceListWave, ROWS)
	if(numDevices > 0)
		EnsureLargeEnoughWave(wv, minimumSize=numDevices, dimension=ROWS)
		wv[0, numDevices - 1] = deviceListWave[p]
	endif

	SetNumberInWaveNote(wv, NOTE_INDEX, numDevices)

	return wv
End

/// @brief general loader for pxp, uxp and nwb files
///
/// @return 0 if the file was loaded, or 1 if not (usually due to an error
///         or because it was already loaded)
static Function AB_AddFile(baseFolder, discLocation)
	string baseFolder, discLocation

	variable mapIndex
	variable firstMapped, lastMapped

	WAVE/T list = GetExperimentBrowserGUIList()

	mapIndex = AB_AddMapEntry(baseFolder, discLocation)

	if(mapIndex < 0)
		return 1
	endif

	firstMapped = GetNumberFromWaveNote(list, NOTE_INDEX)
	AB_LoadFile(discLocation)
	lastMapped = GetNumberFromWaveNote(list, NOTE_INDEX) - 1

	if(lastMapped >= firstMapped)
		list[firstMapped, lastMapped][%experiment][1] = num2str(mapIndex)
	else // experiment could not be loaded
		AB_RemoveMapEntry(mapIndex)
		return 1
	endif

	return 0
End

/// @brief function tries to load Data From discLocation.
static Function AB_LoadFile(discLocation)
	string discLocation

	string device, deviceList
	variable numDevices, i, highestSweepNumber

	Wave/T map = AB_GetMap(discLocation)

	if(!AB_HasCompatibleVersion(discLocation))
		return NaN
	endif

	deviceList = AB_LoadLabNotebook(discLocation)
	Wave/T deviceWave = AB_SaveDeviceList(deviceList, map[%DataFolder])

	numDevices = GetNumberFromWaveNote(deviceWave, NOTE_INDEX)
	for(i = 0; i < numDevices; i += 1)
		device = deviceWave[i]
		strswitch(map[%FileType])
			case ANALYSISBROWSER_FILE_TYPE_IGOR:
				AB_LoadSweepsFromExperiment(map[%DiscLocation], device)
				AB_LoadTPStorageFromIgor(map[%DiscLocation], map[%DataFolder], device)
				AB_LoadUserCommentFromFile(map[%DiscLocation], map[%DataFolder], device)
				break
			case ANALYSISBROWSER_FILE_TYPE_NWB:
				AB_LoadSweepsFromNWB(map[%DiscLocation], map[%DataFolder], device)
				AB_LoadTPStorageFromNWB(map[%DiscLocation], map[%DataFolder], device)
				AB_LoadUserCommentAndHistoryFromNWB(map[%DiscLocation], map[%DataFolder], device)
				break
			default:
				ASSERT(0, "invalid file type")
		endswitch

		Wave/I sweeps = GetAnalysisChannelSweepWave(map[%DataFolder], device)
		AB_FillListWave(map[%FileName], device, map[%DataFolder], sweeps)
	endfor
End

/// @brief Check if the given file has a compatible version
///        which this version of the analysis browser can handle.
///
/// @param discLocation file to check, parameter to AB_GetMap()
static Function AB_HasCompatibleVersion(discLocation)
	string discLocation

	string dataFolderPath
	variable numWavesLoaded

	WAVE/T map = AB_GetMap(discLocation)

	strswitch(map[%FileType])
		case ANALYSISBROWSER_FILE_TYPE_IGOR:
			DFREF targetDFR = GetAnalysisExpFolder(map[%DataFolder])
			dataFolderPath  = GetMiesPathAsString()

			DFREF saveDFR  = GetDataFolderDFR()
			numWavesLoaded = AB_LoadDataWrapper(targetDFR, map[%DiscLocation], dataFolderPath, "pxpVersion", typeFlags = LOAD_DATA_TYPE_NUMBERS)
			SetDataFolder saveDFR

			// no pxpVersion present
			// we can load the file
			if(numWavesLoaded == 0)
				DEBUGPRINT("Experiment has no pxp version so we can load it.")
				return 1
			else
				NVAR/Z pxpVersion = targetDFR:pxpVersion
				ASSERT(NVAR_Exists(pxpVersion), "Expected existing pxpVersion")

				if(IsFinite(pxpVersion) && pxpVersion <= ANALYSIS_BROWSER_SUPP_VERSION)
					DEBUGPRINT("Experiment has a compatible pxp version.", var = pxpVersion)
					return 1
				else
					printf "The experiment %s has the pxpVersion %d which this version of MIES can not handle.\r", map[%DiscLocation], pxpVersion
					ControlWindowToFront()
					return 0
				endif
			endif
			break
		case ANALYSISBROWSER_FILE_TYPE_NWB:
			return 1
		default:
			ASSERT(0, "invalid file type")
	endswitch
End

static Function/S AB_GetSettingNumFiniteVals(wv, device, sweepNo, name)
	Wave wv
	variable sweepNo
	string name, device

	variable numRows

	WAVE/Z settings = GetLastSetting(wv, sweepNo, name, DATA_ACQUISITION_MODE)
	if(!WaveExists(settings))
		printf "Could not query the labnotebook of device %s for the setting %s\r", device, name
		return "unknown"
	else
		WaveStats/Q/M=1 settings
		return num2str(V_npnts)
	endif
End

/// @brief Add an experiment entry into the list
///        if there is none yet.
static Function AB_AddExperimentNameIfReq(expName, list, index)
	string expName
	WAVE/T list
	variable index

	variable lastIndex

	WAVE/Z indizes = FindIndizes(list, colLabel="experiment", str=expName)

	if(WaveExists(indizes))
		lastIndex = indizes[DimSize(indizes, ROWS) - 1]
		if(!cmpstr(list[lastIndex][%experiment][0], expName))
			return NaN
		endif
	endif

	EnsureLargeEnoughWave(list, minimumSize=index, dimension=ROWS)
	list[index][%experiment][0] = expName
	index += 1
End

/// @brief Creates list-view for AnalysisBrowser
///
/// Depends on LabNoteBook to be loaded prior to call.
///
/// @param fileName   current Project's filename
/// @param device     current device
/// @param dataFolder current Project's Lab Notebook DataFolder reference
/// @param sweepNums  Wave containing all sweeps actually present for device
static Function AB_FillListWave(fileName, device, dataFolder, sweepNums)
	string fileName, device, dataFolder
	WAVE sweepNums
	variable index, numWaves, i, j, sweepNo, numRows, numCols, setCount
	string str

	DFREF labNBdfr         = GetAnalysisLabNBFolder(dataFolder, device)
	WAVE  numericalValues  = GetAnalysLBNumericalValues(dataFolder, device)
	WAVE  textualValues    = GetAnalysLBTextualValues(dataFolder, device)

	WAVE/T list = GetExperimentBrowserGUIList()
	index = GetNumberFromWaveNote(list, NOTE_INDEX)

	AB_AddExperimentNameIfReq(fileName, list, index)

	EnsureLargeEnoughWave(list, minimumSize=index, dimension=ROWS)
	list[index][%device][0] = device

	numWaves = GetNumberFromWaveNote(sweepNums, NOTE_INDEX)

	list[index][%'#sweeps'][0] = num2istr(numWaves)
	index += 1

	for(i = 0; i < numWaves; i += 1)
		EnsureLargeEnoughWave(list, minimumSize=index, dimension=ROWS)

		sweepNo = sweepNums[i]
		list[index][%sweep][0] = num2str(sweepNo)

		str = AB_GetSettingNumFiniteVals(numericalValues, device, sweepNo, "DAC")
		list[index][%'#DAC'][0] = str

		str = AB_GetSettingNumFiniteVals(numericalValues, device, sweepNo, "ADC")
		list[index][%'#ADC'][0] = str

		WAVE/Z settings = GetLastSetting(numericalValues, sweepNo, "Headstage Active", DATA_ACQUISITION_MODE)
		numRows = WaveExists(settings) ? NUM_HEADSTAGES : 0
		if(numRows > 0)
			list[index][%'#headstages'][0] = num2str(Sum(settings, 0, NUM_HEADSTAGES - 1))
		else
			list[index][%'#headstages'][0] = "unknown"
		endif

		WAVE/T/Z settingsText = GetLastSetting(textualValues, sweepNo, "Stim Wave Name", DATA_ACQUISITION_MODE)
		numRows = WaveExists(settingsText) ? NUM_HEADSTAGES : 0

		WAVE/Z settings = GetLastSetting(numericalValues, sweepNo, "Set Sweep Count", DATA_ACQUISITION_MODE)

		if(!numRows)
			list[index][%'stim sets'][0] = "unknown"
			list[index][%'set count'][0] = "-"
			index += 1
		else
			for(j = 0; j < numRows; j += 1)
				str = settingsText[j]

				if(isEmpty(str))
					continue
				endif

				EnsureLargeEnoughWave(list, minimumSize=index, dimension=ROWS)
				list[index][%'stim sets'][0] = str

				if(WaveExists(settings))
					list[index][%'set count'][0] = num2istr(settings[j])
				else
					list[index][%'set count'][0] = "-"
				endif

				index += 1
			endfor
		endif
	endfor

	SetNumberInWaveNote(list, NOTE_INDEX, index)
End

/// @brief Load waves from a packed/unpacked experiment file
///
/// This function is special as it does change the CDF!
///
/// @param tmpDFR		  Temporary work folder, function returns with that folder as CDF
/// @param expFilePath    full path to the experiment file on disc
/// @param datafolderPath igor datafolder to look for the waves inside the experiment
/// @param listOfNames    list of names of waves/strings/numbers to load
/// @param typeFlags      [optional, defaults to 1 (waves)] data types to load, valid values
///                       are the same as for `LoadData`, see also @ref LoadDataConstants
///
/// @returns number of loaded items
static Function AB_LoadDataWrapper(tmpDFR, expFilePath, datafolderPath, listOfNames, [typeFlags])
	DFREF tmpDFR
	string expFilePath, datafolderPath, listOfNames
	variable typeFlags

	variable numEntries, i, debugOnError
	string cdf, fileNameWOExtension, baseFolder, extension, expFileOrFolder
	string str, list, regexp

	ASSERT(DataFolderExistsDFR(tmpDFR), "tmpDFR does not exist")
	ASSERT(!isEmpty(expFilePath), "empty path")
	ASSERT(!isEmpty(dataFolderPath), "empty datafolder path")
	ASSERT(strlen(listOfNames) < 1000, "LoadData limit for listOfNames length reached")

	if(ParamIsDefault(typeFlags))
		typeFlags = 1
	else
		ASSERT(typeFlags == COUNTOBJECTS_WAVES || typeFlags == COUNTOBJECTS_VAR || typeFlags == COUNTOBJECTS_STR || typeFlags == COUNTOBJECTS_DATAFOLDER, "Unknown typeFlags, bitmasks are not supported")
	endif

	fileNameWOExtension = GetBaseName(expFilePath)
	baseFolder          = GetFolder(expFilePath)
	extension           = GetFileSuffix(expFilePath)

	/// @todo this is not 100% correct as users might choose a different name for the unpacked experiment folder
	if(!cmpstr(extension, "uxp"))
		expFileOrFolder = baseFolder + fileNameWOExtension  + " Folder"
	else
		expFileOrFolder = expFilePath
	endif

	SetDataFolder tmpDFR

	// work around LoadData not respecting AbortOnRTE properly
	debugOnError = DisableDebugOnError()

	// also with "/Q" LoadData still complains if the subfolder path does not exist
	try
		ClearRTError()
		if(FileExists(expFileOrFolder))
			LoadData/Q/R/L=(typeFlags)/S=dataFolderPath/J=listOfNames/O=1 expFileOrFolder; AbortOnRTE
		elseif(FolderExists(expFileOrFolder))
			LoadData/Q/D/R/L=(typeFlags)/J=listOfNames/O=1 expFileOrFolder + ":" + dataFolderPath; AbortOnRTE
		else
			sprintf str, "The experiment file/folder \"%s\" could not be found!\r", ParseFilePath(5, expFileOrFolder, "\\", 0, 0)
			DoAlert/T="Error in AB_LoadDataWrapper" 0, str
			Abort
		endif
	catch
		ClearRTError()
		ResetDebugOnError(debugOnError)
		return 0
	endtry

	ResetDebugOnError(debugOnError)

	RemoveAllEmptyDataFolders(tmpDFR)

	regexp = ConvertListToRegexpWithAlternations(listOfNames)
	list = GetListOfObjects(tmpDFR, regexp, recursive=1, typeFlag=typeFlags)

	return ItemsInList(list)
End

/// @brief Returns a wave containing all present sweep numbers
///
/// @param dataFolder    DataFolder of HDF5 or Experiment File where LabNoteBook is saved
/// @param device        device for which to get sweeps.
/// @param clean         Variable indicating if ouput can contain duplicate values
static Function/WAVE AB_GetSweepsFromLabNotebook(dataFolder, device, [clean])
	String dataFolder, device
	variable clean
	if(ParamIsDefault(clean))
		clean = 0
	endif

	DFREF dfr = GetAnalysisLabNBFolder(dataFolder, device)
	WAVE/SDFR=dfr numericalValues

	variable sweepCol = GetSweepColumn(numericalValues)
	MatrixOP/FREE sweepNums = col(numericalValues, sweepCol)
	Redimension/N=-1 sweepNums

	if(clean)
		return GetUniqueEntries(sweepNums)
	else
		return sweepNums
	endif
End

/// @brief Returns the highest referenced sweep number from the labnotebook
static Function AB_GetHighestPossibleSweepNum(dataFolder, device)
	string dataFolder, device

	WAVE sweepNums = AB_GetSweepsFromLabNotebook(dataFolder, device, clean = 0)
	WaveStats/M=1/Q sweepNums

	return V_max
End

/// @brief Returns a wave containing all present sweep numbers
///
/// Function uses Config Waves from Igor Experiment to determine present sweeps
///
/// @param discLocation  location of Experiment File on Disc.
///                      ID in AnalysisBrowserMap
/// @param device        device for which to get sweeps.
static Function/WAVE AB_LoadSweepsFromExperiment(discLocation, device)
	string discLocation, device

	variable highestSweepNumber, sweepNumber, numSweeps, i
	string listSweepConfig, sweepConfig
	WAVE/T map = AB_GetMap(discLocation)
	DFREF SweepConfigDFR = GetAnalysisDeviceConfigFolder(map[%DataFolder], device)
	WAVE/I sweeps = GetAnalysisChannelSweepWave(map[%DataFolder], device)

	// Load Sweep Config Waves
	highestSweepNumber = AB_GetHighestPossibleSweepNum(map[%DataFolder], device)
	if(IsFinite(highestSweepNumber))
		AB_LoadSweepConfigData(map[%DiscLocation], map[%DataFolder], device, highestSweepNumber)
	endif
	listSweepConfig = GetListOfObjects(sweepConfigDFR, ".*")

	// store Sweep Numbers in wave
	numSweeps = ItemsInList(listSweepConfig)
	EnsureLargeEnoughWave(sweeps, minimumSize=numSweeps, dimension=ROWS, initialValue = -1)
	for(i = 0; i < numSweeps; i += 1)
		sweepConfig = StringFromList(i, listSweepConfig)
		sweepNumber = ExtractSweepNumber(sweepConfig)
		sweeps[i] = sweepNumber
	endfor
	SetNumberInWaveNote(sweeps, NOTE_INDEX, numSweeps)

	return sweeps
End

/// @brief Analyse data in NWB file and sort as sweeps.
///
/// @todo: Update this function for the use with SweepTable
///
/// @param discLocation  location of NWB File on Disc.
///                      ID in AnalysisBrowserMap
/// @param dataFolder    datafolder of the project
/// @param device        device for which to get sweeps.
static Function AB_LoadSweepsFromNWB(discLocation, dataFolder, device)
	string discLocation, dataFolder, device

	variable h5_fileID, nwbVersion
	string channelList

	Wave/I sweeps = GetAnalysisChannelSweepWave(dataFolder, device)

	// open hdf5 file
	h5_fileID = H5_OpenFile(discLocation)

	// load from /acquisition
	nwbVersion = GetNWBMajorVersion(ReadNWBVersion(h5_fileID))
	channelList = ReadAcquisition(h5_fileID, nwbVersion)
	Wave/T acquisition = GetAnalysisChannelAcqWave(dataFolder, device)
	AB_StoreChannelsBySweep(h5_fileID, nwbVersion, channelList, sweeps, acquisition)

	// load from /stimulus/presentation
	channelList = ReadStimulus(h5_fileID)
	Wave/T stimulus = GetAnalysisChannelStimWave(dataFolder, device)
	AB_StoreChannelsBySweep(h5_fileID, nwbVersion, channelList, sweeps, stimulus)

	// close hdf5 file
	H5_CloseFile(h5_fileID)
End

/// @brief Store channelList in storage wave according to index in sweeps wave
///
/// @todo Update this function for the use with SweepTable
static Function AB_StoreChannelsBySweep(groupID, nwbVersion, channelList, sweeps, storage)
	variable groupID, nwbVersion
	string channelList
	Wave/I sweeps
	Wave/T storage

	variable numChannels, numSweeps, i, sweepNo, sweep_table_id
	string channelString

	numChannels = ItemsInList(channelList)
	numSweeps = GetNumberFromWaveNote(sweeps, NOTE_INDEX)

	EnsureLargeEnoughWave(storage, minimumSize = numSweeps, dimension = ROWS)
	storage = ""

	WAVE/Z SweepTableNumber
	WAVE/Z/T SweepTableSeries
	if(nwbVersion == 2)
		[SweepTableNumber, SweepTableSeries] = LoadSweepTable(groupID, nwbVersion)
	endif

	for(i = 0; i < numChannels; i += 1)
		channelString = StringFromList(i, channelList)
		if(nwbVersion == 2)
			WAVE indices = FindIndizes(SweepTableSeries, col = 0, str = channelString)
			ASSERT(DimSize(indices, ROWS) == 1, "Invalid Amount of Sweep Number Associated in " + channelString)
			sweepNo = SweepTableNumber[indices[0]]
		else
			sweepNo = LoadSweepNumber(groupID, channelString, nwbVersion)
		endif
		FindValue/I=(sweepNo)/S=0 sweeps
		ASSERT(isFinite(sweepNo), "Invalid Sweep Number Associated in " + channelString)
		if(V_Value == -1)
			numSweeps += 1
			EnsureLargeEnoughWave(sweeps, minimumSize = numSweeps, dimension = ROWS, initialValue = -1)
			EnsureLargeEnoughWave(storage, minimumSize = numSweeps, dimension = ROWS)
			sweeps[numSweeps - 1] = sweepNo
			storage[numSweeps - 1] = AddListItem(channelString, "")
		else
			storage[V_Value] = AddListItem(channelString, storage[V_Value])
		endif
	endfor

	SetNumberInWaveNote(sweeps, NOTE_INDEX, numSweeps)
	SetNumberInWaveNote(storage, NOTE_INDEX, numSweeps)
End

static Function AB_LoadTPStorageFromIgor(expFilePath, expFolder, device)
	string expFilePath, expFolder, device

	string dataFolderPath, wanted, unwanted, all
	variable numWavesLoaded

	DFREF targetDFR = GetAnalysisDeviceTestpulse(expFolder, device)
	dataFolderPath  = GetDeviceTestPulseAsString(device)
	dataFolderPath  = AB_TranslatePath(dataFolderPath, expFolder)
	DFREF saveDFR   = GetDataFolderDFR()

	// we can not determine how many TPStorage waves are in dataFolderPath
	// therefore we load all waves and throw the ones we don't need away
	numWavesLoaded  = AB_LoadDataWrapper(targetDFR, expFilePath, dataFolderPath, "")

	if(numWavesLoaded)
		wanted   = GetListOfObjects(targetDFR, TP_STORAGE_REGEXP, fullPath=1)
		all      = GetListOfObjects(targetDFR, ".*", fullPath=1)
		unwanted = RemoveFromList(wanted, all)

		CallFunctionForEachListItem_TS(KillOrMoveToTrashPath, unwanted)
	endif

	SetDataFolder saveDFR
	return numWavesLoaded
End

Function AB_LoadTPStorageFromNWB(nwbFilePath, expFolder, device)
	string nwbFilePath, expFolder, device

	variable h5_fileID, testpulseGroup, numEntries, i
	string dataFolderPath, list, name, groupName

	h5_fileID = H5_OpenFile(nwbFilePath)

	groupName = "/general/testpulse/" + device
	testpulseGroup = H5_OpenGroup(h5_fileID, groupName)

	list = H5_ListGroupMembers(testpulseGroup, groupName)
	list = GrepList(list, TP_STORAGE_REGEXP)

	DFREF targetDFR = GetAnalysisDeviceTestpulse(expFolder, device)

	numEntries = ItemsInList(list)
	for(i = 0; i < numEntries; i += 1)
		name = StringFromList(i, list)
		WAVE wv = H5_LoadDataset(testpulseGroup, name)
		MoveWave wv, targetDFR
	endfor

	HDF5CloseGroup/Z testpulseGroup
	H5_CloseFile(h5_fileID)
End

static Function AB_LoadUserCommentFromFile(expFilePath, expFolder, device)
	string expFilePath, expFolder, device

	string dataFolderPath
	variable numStringsLoaded

	DFREF targetDFR = GetAnalysisDeviceFolder(expFolder, device)
	dataFolderPath  = GetDevicePathAsString(device)
	dataFolderPath  = AB_TranslatePath(dataFolderPath, expFolder)
	DFREF saveDFR   = GetDataFolderDFR()

	numStringsLoaded = AB_LoadDataWrapper(targetDFR, expFilePath, dataFolderPath, "userComment", typeFlags=LOAD_DATA_TYPE_STRING)

	SetDataFolder saveDFR
	return numStringsLoaded
End

static Function AB_LoadUserCommentAndHistoryFromNWB(nwbFilePath, expFolder, device)
	string nwbFilePath, expFolder, device

	string groupName, comment, datasetName, history
	variable h5_fileID, commentGroup, version

	DFREF targetDFR = GetAnalysisDeviceFolder(expFolder, device)
	h5_fileID = H5_OpenFile(nwbFilePath)

	groupName = "/general/user_comment/" + device
	commentGroup = H5_OpenGroup(h5_fileID, groupName)

	comment = ReadTextDataSetAsString(commentGroup, "userComment")
	HDF5CloseGroup/Z commentGroup

	version = GetNWBMajorVersion(ReadNWBVersion(h5_fileID))

	datasetName = "/general/" + GetHistoryAndLogFileDatasetName(version)
	history = ReadTextDataSetAsString(h5_fileID, datasetName)

	H5_CloseFile(h5_fileID)

	string/G targetDFR:userComment = comment
	string/G targetDFR:historyAndLogFile = history
End

static Function/S AB_LoadLabNotebook(discLocation)
	string discLocation

	string device, deviceList, err
	string deviceListChecked = ""
	variable numDevices, i

	Wave/T map = AB_GetMap(discLocation)
	deviceList = AB_LoadLabNoteBookFromFile(discLocation)

	numDevices = ItemsInList(deviceList)
	for(i = 0; i < numDevices; i += 1)
		device = StringFromList(i, deviceList)

		// check if data was loaded
		DFREF dfr = GetAnalysisLabNBFolder(map[%DataFolder], device)
		if (!AB_checkLabNotebook(dfr))
			KillOrMoveToTrash(dfr = dfr)
			continue
		endif

		AB_updateLabelsInLabNotebook(dfr)

		deviceListChecked = AddListItem(device, deviceListchecked, ";", inf)
	endfor

	numDevices -= ItemsInList(deviceListChecked)
	if(numDevices > 0)
		sprintf err, "Dropped %d Loaded Items\r", numDevices
		DEBUGPRINT(err)
	endif

	return deviceListChecked
End

static Function/S AB_LoadLabNotebookFromFile(discLocation)
	string discLocation

	String deviceList = ""
	Wave/T map = AB_GetMap(discLocation)

	strswitch(map[%FileType])
		case ANALYSISBROWSER_FILE_TYPE_IGOR:
			deviceList = AB_LoadLabNotebookFromIgor(map[%DiscLocation])
			break
		case ANALYSISBROWSER_FILE_TYPE_NWB:
			deviceList = AB_LoadLabNotebookFromNWB(map[%DiscLocation])
			break
	endswitch

	return deviceList
End

static Function/S AB_LoadLabNotebookFromIgor(discLocation)
	String discLocation

	string labNotebookWaves, labNotebookPath, type, number, path, basepath, device, str
	string deviceList = ""
	variable numEntries, i, j, numWavesLoaded, numNumbers

	WAVE/T experiment = AB_GetMap(discLocation)

	if(cmpstr(experiment[%FileType], ANALYSISBROWSER_FILE_TYPE_IGOR))
		return "" // can not load file
	endif

	// load notebook waves from file to (temporary) data folder
	labNotebookWaves  = "settingsHistory;keyWave;txtDocWave;txtDocKeyWave;"
	labNotebookWaves += "numericalKeys;textualKeys;numericalValues;textualValues"
	labNotebookPath = GetLabNotebookFolderAsString()
	DFREF saveDFR = GetDataFolderDFR()
	DFREF newDFR = UniqueDataFolder(GetAnalysisFolder(), "igorLoadNote")
	numWavesLoaded = AB_LoadDataWrapper(newDFR, discLocation, labNotebookPath, labNotebookWaves)

	if(numWavesLoaded <= 0)
		SetDataFolder saveDFR
		KillOrMoveToTrash(dfr=newDFR)
		return ""
	endif

	numEntries = CountObjectsDFR(newDFR, COUNTOBJECTS_DATAFOLDER)
	numNumbers = ItemsInList(DEVICE_NUMBERS)
	for(i = 0; i < numEntries; i += 1)

		type = GetIndexedObjNameDFR(newDFR, COUNTOBJECTS_DATAFOLDER, i)

		if(GrepString(type, ITC_DEVICE_REGEXP))
			// ITC hardware is in a specific subfolder
			for(j = 0; j < numNumbers ; j += 1)
				number = StringFromList(j, DEVICE_NUMBERS)
				device = HW_ITC_BuildDeviceString(type, number)
				path = GetDataFolder(1, newDFR) + type + ":Device" + number

				AB_LoadLabNotebookFromIgorLow(discLocation, path, device, deviceList)
			endfor
		else // other hardware not
			device = type
			path = GetDataFolder(1, newDFR) + device
			AB_LoadLabNotebookFromIgorLow(discLocation, path, device, deviceList)
		endif
	endfor

	SetDataFolder saveDFR
	KillOrMoveToTrash(dfr=newDFR)

	return deviceList
End

/// @brief Try loading the four labnotebooks from path
///
/// @param[in] discLocation    experiment location on disc
/// @param[in] path            datafolder path which holds the labnotebooks (might not exist)
/// @param[in] device          name of the device
/// @param[in, out] deviceList list of loaded devices, for successful loads we add to that list
static Function AB_LoadLabNotebookFromIgorLow(discLocation, path, device, deviceList)
	string discLocation, path, device
	string &deviceList

	string basepath

	if(!DataFolderExists(path))
		return NaN
	endif

	WAVE/T experiment = AB_GetMap(discLocation)

	// search for Loaded labNotebookWaves
	// first try the new wave names and then as fallback
	// the old ones
	// Supports old/new wavename mixes although these should not
	// exist in the wild.

	Wave/Z/SDFR=$path numericalKeys

	if(!WaveExists(numericalKeys))
		basepath = path + ":KeyWave"
		if(DataFolderExists(basepath))
			Wave/Z/SDFR=$basepath numericalKeys = keyWave
		endif
	endif

	Wave/Z/SDFR=$path numericalValues

	if(!WaveExists(numericalValues))
		basepath = path + ":settingsHistory"
		if(DataFolderExists(basepath))
			Wave/Z/SDFR=$basepath numericalValues = settingsHistory
		endif
	endif

	Wave/Z/SDFR=$path textualKeys

	if(!WaveExists(textualKeys))
		basepath = path + ":TextDocKeyWave"
		if(DataFolderExists(basepath))
			Wave/Z/SDFR=$basepath textualKeys = txtDocKeyWave
		endif
	endif

	Wave/Z/SDFR=$path textualValues

	if(!WaveExists(textualValues))
		basepath = path + ":textDocumentation"
		if(DataFolderExists(basepath))
			Wave/Z/SDFR=$basepath textualValues = txtDocWave
		endif
	endif

	if(!WaveExists(numericalKeys) || !WaveExists(numericalValues) || !WaveExists(textualKeys) || !WaveExists(textualValues))
		printf "Could not find all four labnotebook waves, dropping all data from device %s in file %s\r", device, discLocation
		return NaN
	endif

	// copy and rename loaded waves to Analysisbrowser directory
	DFREF dfr = GetAnalysisLabNBFolder(experiment[%DataFolder], device)
	Duplicate/O numericalKeys, dfr:numericalKeys/Wave=numericalKeys
	Duplicate/O numericalValues, dfr:numericalValues/Wave=numericalValues
	Duplicate/O textualKeys, dfr:textualKeys/Wave=textualKeys
	Duplicate/O textualValues, dfr:textualValues

	DEBUGPRINT("Loaded Igor labnotebook for device: ", str=device)
	deviceList = AddListItem(device, deviceList, ";", inf)
End

static Function/S AB_LoadLabNotebookFromNWB(discLocation)
	String discLocation

	variable numDevices, numLoaded, i
	variable h5_fileID, h5_notebooksID
	string notebookList, deviceList, device

	Wave/T nwb = AB_GetMap(discLocation)

	try
		h5_fileID = H5_OpenFile(nwb[%DiscLocation])
	catch
		printf "Could not open the NWB file %s.\r", nwb[%DiscLocation]
		H5_CloseFile(h5_fileID)
		return ""
	endtry

	notebookList = ReadLabNoteBooks(h5_fileID)
	h5_notebooksID = H5_OpenGroup(h5_fileID, "/general/labnotebook")

	numDevices = ItemsInList(notebookList)
	devicelist = ""
	for(i = 0; i < numDevices; i += 1)
		device = StringFromList(i, notebookList)

		DFREF notebookDFR = GetAnalysisLabNBFolder(nwb[%DataFolder], device)
		numLoaded = NWB_LoadLabNoteBook(h5_notebooksID, device, notebookDFR)
		if (numLoaded != 4)
			printf "Could not find four labnotebook waves in nwb file for device %s\r", device
			KillOrMoveToTrash(dfr=NotebookDFR)
			continue
		endif

		/// add current device to output devicelist
		DEBUGPRINT("Loaded NWB labnotebook for device: ", str=device)
		devicelist = AddListItem(device, devicelist, ";", inf)
	endfor

	// H5_CloseFile closes all associated open groups.
	HDF5CloseGroup/Z h5_notebooksID
	H5_CloseFile(h5_fileID)

	return devicelist
End

///@brief function checks if LabNoteBook Waves do exist.
///@param  dfr path to labNoteBook dataFolder reference.
///@return 0 labNotebook does not exist.
///        1 labNoteBook exists. also update dimension lables
static Function AB_checkLabNotebook(dfr)
	DFREF dfr

	Wave/Z/SDFR=dfr numericalKeys
	Wave/Z/SDFR=dfr numericalValues
	Wave/Z/SDFR=dfr textualKeys
	Wave/Z/SDFR=dfr textualValues

	if(!WaveExists(numericalKeys) || !WaveExists(numericalValues) || !WaveExists(textualKeys) || !WaveExists(textualValues))
		printf "Data is not in correct Format for %s\r", GetDataFolder(0, dfr)
		return 0
	endif

	return 1
End

/// @brief add dimension labels in older versions of igor-MIES and hdf5-loaded data
///        overwrite invalid dim labels (labnotebook waves created with versions prior to a8f0f43)
static Function AB_updateLabelsInLabNotebook(dfr)
	DFREF dfr

	string str

	Wave/Z/SDFR=dfr numericalKeys
	Wave/Z/SDFR=dfr numericalValues
	Wave/Z/SDFR=dfr textualKeys
	Wave/Z/SDFR=dfr textualValues

	str = GetDimLabel(textualValues, COLS, 0)
	if(isEmpty(str) || !cmpstr(str, "dimLabelText"))
		LBN_SetDimensionLabels(textualKeys, textualValues)
	endif

	str = GetDimLabel(numericalKeys, COLS, 0)
	if(isEmpty(str) || !cmpstr(str, "dimLabelText"))
		LBN_SetDimensionLabels(numericalKeys, numericalValues)
	endif

	return 1
End

static Function/S AB_TranslatePath(path, expFolder)
	string path, expFolder

	DFREF dfr = GetAnalysisExpFolder(expFolder)
	NVAR pxpVersion = $GetPxpVersionForAB(dfr)

	if(isNaN(pxpVersion) || pxpVersion == 1)
		// old data in expFolder still uses ITCDevices but
		// path already uses the new name
		return ReplaceString(":HardwareDevices", path, ":ITCDevices")
	endif

	// pxpVersion 2
	// HardwareDevices is used consistently

	return path
End

static Constant LOAD_CONFIG_CHUNK_SIZE = 50

/// @brief Load all `Config_Sweep_*` waves from the given experiment file or folder and the given device
///
/// The implementation here tries to load `LOAD_CONFIG_CHUNK_SIZE` number of config sweep waves at a time
/// until there could not be loaded at least one config sweep wave and we have reached highestSweepNumber.
///
/// The size of `LOAD_CONFIG_CHUNK_SIZE` is limited by a limitation of LoadData as this operations accepts
/// only a stringlist of waves shorter than 400 characters.
static Function AB_LoadSweepConfigData(expFilePath, expFolder, device, highestSweepNumber)
	string expFilePath, expFolder, device
	variable highestSweepNumber

	string dataFolderPath, listOfWaves
	variable numWavesLoaded, totalNumWavesLoaded
	variable start, step, stop, i

	ASSERT(IsFinite(highestSweepNumber), "highestSweepNumber has to be finite")

	DFREF targetDFR = GetAnalysisDeviceConfigFolder(expFolder, device)
	dataFolderPath = GetDeviceDataPathAsString(device)
	dataFolderPath = AB_TranslatePath(dataFolderPath, expFolder)
	DFREF saveDFR = GetDataFolderDFR()

	step  = 1
	for(i = 0;; i += 1)
		start = i * LOAD_CONFIG_CHUNK_SIZE
		stop  = (i + 1) * LOAD_CONFIG_CHUNK_SIZE

		listOfWaves = BuildList("Config_Sweep_%d", start, step, stop)
		numWavesLoaded = AB_LoadDataWrapper(targetDFR, expFilePath, dataFolderPath, listOfWaves)

		if(numWavesLoaded <= 0 && stop >= highestSweepNumber)
			break
		endif

		totalNumWavesLoaded += numWavesLoaded
	endfor

	SetDataFolder saveDFR
	return totalNumWavesLoaded
End

/// @brief Expand all tree views in the given column
static Function AB_ExpandListColumn(col)
	variable col

	variable numRows, row, i, mask

	WAVE expBrowserSel = GetExperimentBrowserGUISel()

	WAVE selBits = AB_ReturnAndClearGUISelBits()
	WAVE/Z indizes = FindIndizes(expBrowserSel, col=col, var=LISTBOX_TREEVIEW)
	AB_SetGUISelBits(selBits)

	if(!WaveExists(indizes))
		return NaN
	endif

	numRows = DimSize(indizes, ROWS)
	for(i = numRows - 1; i >= 0; i -= 1)

		row = indizes[i]
		mask = expBrowserSel[row][col]
		if(mask & LISTBOX_TREEVIEW_EXPANDED)
			continue
		endif

		AB_ExpandListEntry(row, col)
		expBrowserSel[row][col] = SetBit(mask, LISTBOX_TREEVIEW_EXPANDED)
	endfor
End

/// @brief Collapse all tree views in the given column
static Function AB_CollapseListColumn(col)
	variable col

	variable numRows, row, i, mask

	WAVE expBrowserSel = GetExperimentBrowserGUISel()

	WAVE selBits = AB_ReturnAndClearGUISelBits()
	WAVE/Z indizes = FindIndizes(expBrowserSel, col=col, var=LISTBOX_TREEVIEW | LISTBOX_TREEVIEW_EXPANDED)
	AB_SetGUISelBits(selBits)

	if(!WaveExists(indizes))
		return NaN
	endif

	numRows = DimSize(indizes, ROWS)
	for(i = numRows - 1; i >= 0; i -= 1)

		row = indizes[i]
		mask = expBrowserSel[row][col]
		if(mask & LISTBOX_TREEVIEW_EXPANDED)
			AB_CollapseListEntry(row, col)
			expBrowserSel[row][col] = ClearBit(mask, LISTBOX_TREEVIEW_EXPANDED)
		endif
	endfor
End

/// @brief Set the selection bits of the experiment browser ListBox selection wave
///
/// @param selBits wave returned by AB_ReturnAndClearGUISelBits
static Function AB_SetGUISelBits(selBits)
	WAVE selBits

	WAVE expBrowserSel = GetExperimentBrowserGUISel()
	expBrowserSel[][0] = expBrowserSel[p][0] | selBits[p]
End

/// @brief Return the selection bits from the experiment browser ListBox selection wave and clear them
static Function/Wave AB_ReturnAndClearGUISelBits()

	WAVE expBrowserSel = GetExperimentBrowserGUISel()

	Make/FREE/N=(DimSize(expBrowserSel, ROWS)) selBits = expBrowserSel[p][0] & LISTBOX_SELECTED
	expBrowserSel[][0] = expBrowserSel[p][0] & ~LISTBOX_SELECTED

	return selBits
End

/// @brief Collapse the given treeview
static Function AB_CollapseListEntry(row, col)
	variable row, col

	variable mask, last, length
	string str

	WAVE/T expBrowserList    = GetExperimentBrowserGUIList()
	WAVE expBrowserSel       = GetExperimentBrowserGUISel()
	WAVE/T expBrowserListBak = CreateBackupWave(expBrowserList)
	WAVE expBrowserSelBak    = CreateBackupWave(expBrowserSel)

	mask = expBrowserSel[row][col]
	ASSERT(mask & LISTBOX_TREEVIEW && mask & LISTBOX_TREEVIEW_EXPANDED, "listbox entry is not a treeview expansion node or is already collapsed")

	// contract the list by deleting all rows between the current one
	// and one before the next one which has a tree view icon in the same column or lower columns
	last  = AB_GetRowWithNextTreeView(expBrowserSel, row, col)
	last -= 1

	row += 1
	length = last - row + 1

	sprintf str, "range=[%d, %d], length=%d", row, last, length
	DEBUGPRINT("contract listbox:", str=str)

	DeletePoints/M=(ROWS) row, length, expBrowserList, expBrowserSel
End

/// @brief Expand the given treeview
static Function AB_ExpandListEntry(row, col)
	variable row, col

	variable mask, last, length, sourceRow, targetRow
	string str

	WAVE/T expBrowserList    = GetExperimentBrowserGUIList()
	WAVE expBrowserSel       = GetExperimentBrowserGUISel()
	WAVE/T expBrowserListBak = CreateBackupWave(expBrowserList)
	WAVE expBrowserSelBak    = CreateBackupWave(expBrowserSel)

	mask = expBrowserSel[row][col]
	ASSERT(mask & LISTBOX_TREEVIEW && !(mask & LISTBOX_TREEVIEW_EXPANDED) , "listbox entry is not a treeview expansion node or already expanded")

	// expand the list
	// - search the backup wave for the row index (sourceRow) with the same contents as row for the contracted list
	// - search the next tree view icon in the same or lower columns in the backup selection wave
	// - calculate the required new rows and insert them
	// - copy the contents from the backup waves
	targetRow = row + 1
	sourceRow = GetRowWithSameContent(expBrowserListBak, expBrowserList, row)

	last = AB_GetRowWithNextTreeView(expBrowserSelBak, sourceRow, col)
	last -= 1

	sourceRow += 1
	length = last - sourceRow + 1

	sprintf str, "sourceRow=%d, targetRow=%d, last=%d", sourceRow, targetRow, last
	DEBUGPRINT("expand listbox:", str=str)

	InsertPoints/M=(ROWS) targetRow, length, expBrowserList, expBrowserSel
	expBrowserList[targetRow, targetRow + length - 1][][] = expBrowserListBak[sourceRow - targetRow + p][q][r]
	expBrowserSel[targetRow, targetRow + length - 1][]    = expBrowserSelBak[sourceRow - targetRow + p][q]
End

/// @returns 0 if the treeview could be expanded, zero otherwise
static Function AB_ExpandIfCollapsed(row, subSectionColumn)
	variable row, subSectionColumn

	WAVE expBrowserSel = GetExperimentBrowserGUISel()

	ASSERT(subSectionColumn == EXPERIMENT_TREEVIEW_COLUMN || subSectionColumn == DEVICE_TREEVIEW_COLUMN, "Invalid subsection column")
	if(!(expBrowserSel[row][subSectionColumn] & LISTBOX_TREEVIEW))
		// entry is not a tree view
		return 1
	endif

	if(!(expBrowserSel[row][subSectionColumn] & LISTBOX_TREEVIEW_EXPANDED))
		AB_ExpandListEntry(row, subSectionColumn)
		expBrowserSel[row][subSectionColumn] = expBrowserSel[row][subSectionColumn] | LISTBOX_TREEVIEW_EXPANDED
		return 0
	endif
End

/// @brief get indizes from AB window while successive expanding all columns
///
/// @returns valid indizes wave on success
static Function/WAVE AB_GetExpandedIndices()
	variable i, row

	WAVE expBrowserSel    = GetExperimentBrowserGUISel()
	// Our mode for the listbox stores the selection bit only in the first column
	WAVE/Z wv = FindIndizes(expBrowserSel, col=0, var=1, prop=PROP_MATCHES_VAR_BIT_MASK)
	if(!WaveExists(wv))
		Make/FREE/N=0 wv
		return wv
	endif

	// expand all selected treeviews
	// as indizes might change during the loop run we have to determine the
	// dimension size in the loop condition
	for(i = 0; i < DimSize(wv, ROWS); i += 1)
		row = wv[i]

		// we have to refetch the selected entries
		if(!AB_ExpandIfCollapsed(row, EXPERIMENT_TREEVIEW_COLUMN))
			WAVE wv = FindIndizes(expBrowserSel, col=0, var=1, prop=PROP_MATCHES_VAR_BIT_MASK)
			i = 0
		endif

		if(!AB_ExpandIfCollapsed(row, DEVICE_TREEVIEW_COLUMN))
			WAVE wv = FindIndizes(expBrowserSel, col=0, var=1, prop=PROP_MATCHES_VAR_BIT_MASK)
			i = 0
		endif
	endfor

	return wv
End

/// @returns 0 if at least one sweep or stimset could be loaded, 1 otherwise
static Function AB_LoadFromExpandedRange(row, subSectionColumn, AB_LoadType, [overwrite, sweepBrowserDFR])
	variable row, subSectionColumn, AB_LoadType, overwrite
	DFREF sweepBrowserDFR

	variable j, endRow, mapIndex, sweep, oneValidLoad
	string device, discLocation, dataFolder, fileName, fileType

	WAVE expBrowserSel    = GetExperimentBrowserGUISel()
	WAVE/T expBrowserList = GetExperimentBrowserGUIList()
	WAVE/T map = GetAnalysisBrowserMap()

	if(ParamIsDefault(overwrite))
		overwrite = 0
	endif

	ASSERT(subSectionColumn == EXPERIMENT_TREEVIEW_COLUMN || subSectionColumn == DEVICE_TREEVIEW_COLUMN, "Invalid subsection column")
	if(!(expBrowserSel[row][subSectionColumn] & LISTBOX_TREEVIEW))
		// entry is not a tree view
		return 1
	endif

	endRow = AB_GetRowWithNextTreeView(expBrowserSel, row, subSectionColumn)

	for(j = row; j < endRow; j += 1)
		if(expBrowserSel[j][0] & LISTBOX_TREEVIEW || expBrowserSel[j][2] & LISTBOX_TREEVIEW)
			// ignore rows with tree view icons, we have them already in our list
			continue
		endif

		sweep = str2num(expBrowserList[j][%sweep])

		// sweeps with multiple DA channels occupy multiple rows,
		// ignore them as they all stem from the same sweep
		if(!IsFinite(sweep))
			continue
		endif

		device      = GetLastNonEmptyEntry(expBrowserList, "device", j)
		mapIndex    = str2num(expBrowserList[j][%experiment][1])
		dataFolder   = map[mapIndex][%DataFolder]
		discLocation = map[mapIndex][%DiscLocation]
		fileType     = map[mapIndex][%FileType]
		fileName     = map[mapIndex][%FileName]

		switch(AB_LoadType)
			case AB_LOAD_STIMSET:
				if(AB_LoadStimsetFromFile(discLocation, dataFolder, fileType, device, sweep, overwrite = overwrite) == 1)
					continue
				endif
				oneValidLoad = 1
				break
			case AB_LOAD_SWEEP:
				if(AB_LoadSweepFromFile(discLocation, dataFolder, fileType, device, sweep, overwrite = overwrite) == 1)
					continue
				endif
				oneValidLoad = 1
				SB_AddToSweepBrowser(sweepBrowserDFR, fileName, dataFolder, device, sweep)
				break
			default:
				break
		endswitch
	endfor

	if(oneValidLoad)
		return 0
	else
		return 1
	endif
End

/// @brief Return the row with treeview in the column col starting from startRow
static Function AB_GetRowWithNextTreeView(selWave, startRow, col)
	Wave selWave
	variable startRow, col

	variable numRows, i
	Make/FREE/N=(DimSize(selWave, COLS)) status

	numRows = DimSize(selWave, ROWS)
	for(i = startRow + 1; i < numRows; i += 1)
		status[] = (selWave[i][p] & LISTBOX_TREEVIEW ? 1 : 0)

		if(Sum(status, 0, col) > 0)
			return i
		endif
	endfor

	return numRows
End

static Function AB_LoadFromFile(AB_LoadType, [sweepBrowserDFR])
	variable AB_LoadType
	DFREF sweepBrowserDFR

	variable mapIndex, sweep, numRows, i, row, overwrite, oneValidLoad
	string dataFolder, fileName, discLocation, fileType, device

	if(AB_LoadType == AB_LOAD_SWEEP)
		ASSERT(!ParamIsDefault(sweepBrowserDFR), "create sweepBrowser DataFolder with SB_OpenSweepBrowser() prior")
		ASSERT(DataFolderRefStatus(sweepBrowserDFR) == 1, "sweepBrowser DataFolder does not exist")
	endif

	WAVE indizes = AB_GetExpandedIndices()
	numRows = DimSize(indizes, ROWS)
	if(numRows == 0)
		return 0
	endif

	WAVE/T expBrowserList = GetExperimentBrowserGUIList()
	WAVE/T map = GetAnalysisBrowserMap()
	overwrite = GetCheckBoxState("AnalysisBrowser", "checkbox_load_overwrite")

	for(i = 0; i < numRows; i += 1)
		row = indizes[i]

		// handle not expanded EXPERIMENT and DEVICE COLUMNS
		switch(AB_LoadType)
			case AB_LOAD_STIMSET:
				if(!AB_LoadFromExpandedRange(row, EXPERIMENT_TREEVIEW_COLUMN, AB_LoadType, overwrite = overwrite))
					oneValidLoad = 1
					continue
				endif
				if(!AB_LoadFromExpandedRange(row, DEVICE_TREEVIEW_COLUMN, AB_LoadType, overwrite = overwrite))
					oneValidLoad = 1
					continue
				endif
				break
			case AB_LOAD_SWEEP:
				if(!AB_LoadFromExpandedRange(row, EXPERIMENT_TREEVIEW_COLUMN, AB_LoadType, sweepBrowserDFR = sweepBrowserDFR, overwrite = overwrite))
					oneValidLoad = 1
					continue
				endif
				if(!AB_LoadFromExpandedRange(row, DEVICE_TREEVIEW_COLUMN, AB_LoadType, sweepBrowserDFR = sweepBrowserDFR, overwrite = overwrite))
					oneValidLoad = 1
					continue
				endif
				break
			default:
				break
		endswitch

		sweep  = str2num(GetLastNonEmptyEntry(expBrowserList, "sweep", row))
		if(!IsFinite(sweep))
			continue
		endif
		device = GetLastNonEmptyEntry(expBrowserList, "device", row)

		mapIndex    = str2num(expBrowserList[row][%experiment][1])
		fileName     = map[mapIndex][%FileName]
		dataFolder   = map[mapIndex][%DataFolder]
		discLocation = map[mapIndex][%DiscLocation]
		fileType     = map[mapIndex][%FileType]

		switch(AB_LoadType)
			case AB_LOAD_STIMSET:
				if(AB_LoadStimsetFromFile(discLocation, dataFolder, fileType, device, sweep, overwrite = overwrite))
					continue
				endif
				oneValidLoad = 1
				break
			case AB_LOAD_SWEEP:
				if(AB_LoadSweepFromFile(discLocation, dataFolder, fileType, device, sweep, overwrite = overwrite))
					continue
				endif
				oneValidLoad = 1
				SB_AddToSweepBrowser(sweepBrowserDFR, fileName, dataFolder, device, sweep)
				break
			default:
				break
		endswitch
	endfor

	return oneValidLoad
End

Function AB_LoadStimsetForSweep(string device, variable index, variable sweep)

	string dataFolder, discLocation, fileType

	WAVE/T map = GetAnalysisBrowserMap()

	dataFolder   = map[index][%DataFolder]
	discLocation = map[index][%DiscLocation]
	fileType     = map[index][%FileType]

	return AB_LoadStimsetFromFile(discLocation, dataFolder, fileType, device, sweep, overwrite = 0)
End

// @brief common ASSERT statements for AB_LoadSweepFromFile and AB_LoadStimsetFromFile
static Function AB_LoadFromFileASSERT(discLocation, dataFolder, fileType, device, sweep, overwrite)
	string discLocation, dataFolder, fileType, device
	variable sweep, overwrite

	ASSERT(!isEmpty(discLocation), "Empty file or Folder name on disc")
	ASSERT(!isEmpty(dataFolder), "Empty dataFolder")
	ASSERT(cmpstr(fileType, "unknown"), "unknown file format")
	ASSERT(!isEmpty(device), "Empty device")
	ASSERT(isFinite(sweep), "Non-finite sweep")
	ASSERT(overwrite == 0 || overwrite == 1, "overwrite can either be one or zero")
End

/// @returns 0 if the sweeps could be loaded, or already exists, and 1 on error
static Function AB_LoadSweepFromFile(discLocation, dataFolder, fileType, device, sweep, [overwrite])
	string discLocation, dataFolder, fileType, device
	variable sweep, overwrite

	string sweepFolder, sweeps, msg
	variable h5_fileID, h5_groupID

	if(ParamIsDefault(overwrite))
		overwrite = 0
	endif
	AB_LoadFromFileASSERT(discLocation, dataFolder, fileType, device, sweep, overwrite)

	sweepFolder = GetAnalysisSweepDataPathAS(dataFolder, device, sweep)

	// sweep already loaded
	if(DataFolderExists(sweepFolder))
		if(!overwrite)
			return 0
		endif

		KillOrMoveToTrash(dfr = $sweepFolder)
		KillOrMoveToTrash(wv = GetAnalysisConfigWave(dataFolder, device, sweep))
	endif

	DFREF sweepDFR = createDFWithAllParents(sweepFolder)

	strswitch(fileType)
		case ANALYSISBROWSER_FILE_TYPE_IGOR:
			sweeps = AB_LoadSweepFromIgor(discLocation, dataFolder, sweepDFR, device, sweep)
			if(!cmpstr(sweeps, ""))
				return 1
			endif
			Wave sweepsWave = sweepDFR:$sweeps
			if(AB_SplitSweepIntoComponents(dataFolder, device, sweep, sweepsWave))
				return 1
			endif
			break
		case ANALYSISBROWSER_FILE_TYPE_NWB:
			if(AB_LoadSweepFromNWB(discLocation, sweepDFR, device, sweep))
				return 1
			endif
			break
		default:
			ASSERT(0, "fileType not handled")
	endswitch

	sprintf msg, "Loaded sweep %d of device %s and %s\r", sweep, device, discLocation
	DEBUGPRINT(msg)

	return 0
End

static Function AB_LoadStimsetFromFile(discLocation, dataFolder, fileType, device, sweep, [overwrite])
	string discLocation, dataFolder, fileType, device
	variable sweep, overwrite

	string stimsets, loadedStimsets, msg
	variable h5_fileID, h5_groupID

	if(ParamIsDefault(overwrite))
		overwrite = 0
	endif
	AB_LoadFromFileASSERT(discLocation, dataFolder, fileType, device, sweep, overwrite)

	strswitch(fileType)
		case ANALYSISBROWSER_FILE_TYPE_IGOR:
			stimsets = NWB_GetStimsetFromSpecificSweep(dataFolder, device, sweep)
			loadedStimsets = AB_LoadStimsets(discLocation, stimsets, overwrite)
			loadedStimsets = AB_LoadCustomWaves(discLocation, loadedStimsets, overwrite)
			stimsets = GetListDifference(stimsets, loadedStimsets)
			if(AB_LoadStimsetsRAW(discLocation, stimsets, overwrite))
				return 1
			endif
			break
		case ANALYSISBROWSER_FILE_TYPE_NWB:
			stimsets = NWB_GetStimsetFromSpecificSweep(dataFolder, device, sweep)
			h5_fileID  = H5_OpenFile(discLocation)
			if(!StimsetPathExists(h5_fileID))
				H5_CloseFile(h5_fileID)
				return 1
			endif
			h5_groupID = OpenStimset(h5_fileID)
			if(NWB_LoadStimsets(h5_groupID, stimsets, overwrite))
				H5_CloseFile(h5_fileID)
				return 1
			endif
			if(NWB_LoadCustomWaves(h5_groupID, stimsets, overwrite))
				H5_CloseFile(h5_fileID)
				return 1
			endif
			H5_CloseFile(h5_fileID)
			break
		default:
			ASSERT(0, "fileType not handled")
	endswitch

	sprintf msg, "Loaded stimsets %s of device %s and %s\r", stimsets, device, discLocation
	DEBUGPRINT(msg)

	return 0
End

static Function AB_LoadSweepFromNWB(discLocation, sweepDFR, device, sweep)
	string discLocation, device
	DFREF sweepDFR
	variable sweep

	string channelList
	variable h5_fileID, h5_groupID, numSweeps, version

	Wave/T nwb = AB_GetMap(discLocation)

	// find sweep in map
	Wave/T devices = GetAnalysisDeviceWave(nwb[%DataFolder])
	FindValue/S=0/TEXT=(device) devices
	ASSERT(V_Value >= 0, "device not found")
	Wave/I sweeps  = GetAnalysisChannelSweepWave(nwb[%DataFolder], device)
	FindValue/S=0/I=(sweep) sweeps
	ASSERT(V_Value >= 0, "sweep not found")

	// load sweep info wave
	Wave/Wave channelStorage = GetAnalysisChannelStorage(nwb[%DataFolder], device)
	numSweeps = GetNumberFromWaveNote(sweeps, NOTE_INDEX)
	if(numSweeps != GetNumberFromWaveNote(channelStorage, NOTE_INDEX))
		EnsureLargeEnoughWave(channelStorage, minimumSize = numSweeps, dimension = ROWS)
	endif
	Wave/Z/I configSweep = channelStorage[V_Value][%configSweep]
	if(!WaveExists(configSweep))
		Wave/I configSweep = GetAnalysisConfigWave(nwb[%DataFolder], device, sweep)
		channelStorage[V_Value][%configSweep] = configSweep
	endif

	// open NWB file
	h5_fileID = H5_OpenFile(discLocation)
	version = GetNWBMajorVersion(ReadNWBVersion(h5_fileID))

	// load acquisition
	Wave/T acquisition = GetAnalysisChannelAcqWave(nwb[%DataFolder], device)
	channelList = acquisition[V_Value]
	h5_groupID = OpenAcquisition(h5_fileID, version)
	if(AB_LoadSweepFromNWBgeneric(h5_groupID, version, channelList, sweepDFR, configSweep))
		return 1
	endif

	// load stimulus
	Wave/T stimulus = GetAnalysisChannelStimWave(nwb[%DataFolder], device)
	channelList = stimulus[V_Value]
	h5_groupID = OpenStimulus(h5_fileID)
	if(AB_LoadSweepFromNWBgeneric(h5_groupID, version, channelList, sweepDFR, configSweep))
		return 1
	endif

	// close NWB file
	H5_CloseFile(h5_fileID)

	return 0
End

static Function AB_LoadSweepFromNWBgeneric(h5_groupID, nwbVersion, channelList, sweepDFR, configSweep)
	variable h5_groupID, nwbVersion
	string channelList
	DFREF sweepDFR
	Wave/I configSweep

	string channel, channelName
	variable numChannels, numEntries, i
	STRUCT ReadChannelParams p
	variable waveNoteLoaded, fakeConfigWave

	numChannels = ItemsInList(channelList)

	for(i = 0; i < numChannels; i += 1)
		channel = StringFromList(i, channelList)
		AnalyseChannelName(channel, p)

		switch(p.channelType)
			case XOP_CHANNEL_TYPE_DAC:
				channelName = "DA"
				wave loaded = LoadStimulus(h5_groupID, channel)
				channelName += "_" + num2str(p.channelNumber)
				fakeConfigWave = 1
				break
			case XOP_CHANNEL_TYPE_ADC:
				channelName = "AD"
				wave loaded = LoadTimeseries(h5_groupID, channel, nwbVersion)
				channelName += "_" + num2str(p.channelNumber)
				fakeConfigWave = 1
				break
			case XOP_CHANNEL_TYPE_TTL:
				channelName  = "TTL"
				wave loaded = LoadStimulus(h5_groupID, channel)
				channelName += "_" + num2str(p.channelNumber)

				if(IsFinite(p.ttlBit))
					// always fake TTL base wave (bitwise sum of all TTL channels)
					wave/Z/I base = sweepDFR:$channelName
					if(!WaveExists(base))
						Duplicate loaded sweepDFR:$channelName/wave=base
						base = 0
						fakeConfigWave = 1
						SetNumberInWaveNote(base, "fake", 1)
					endif

					if(WaveMax(loaded) < 2)
						base += 2^(p.ttlBit) * loaded
					else
						base += loaded
					endif

					channelName += "_" + num2str(log(p.ttlBit)/log(2))
				else
					// for non-ITC hardware we don't have multiple bits in one channel
					// so we don't need to fake a base wave
					fakeConfigWave = 1
				endif

				break
			default:
				ASSERT(0, "unknown channel type " + num2str(p.channelType))
		endswitch
		ASSERT(WaveExists(loaded), "No Wave loaded")

		if(waveNoteLoaded == 0)
			SVAR/Z test = sweepDFR:note
			if(!SVAR_EXISTS(test))
				string/G sweepDFR:note = note(loaded)
			endif
			waveNoteLoaded = 1
		endif

		// fake Config_Sweeps Wave
		if(fakeConfigWave)
			numEntries = DimSize(configSweep, ROWS)
			Redimension/N=((numEntries + 1), -1) configSweep

			configSweep[numEntries][%type]   = p.channelType
			configSweep[numEntries][%number] = p.channelNumber
			configSweep[numEntries][%timeMS] = trunc(DimDelta(loaded, ROWS) * 1000)
			configSweep[numEntries][3]       = -1 // -1 for faked Config_Sweeps Waves

			// set unit in config_wave from WaveNote of loaded dataset
			Note/K configSweep, AddListItem(WaveUnits(loaded, COLS), Note(configSweep), ";", Inf)

			fakeConfigWave = 0
		endif

		WAVE/Z/SDFR=sweepDFR targetName = $channelName
		// nwb files created prior to 901428b might have duplicated datasets
		ASSERT(!WaveExists(targetName) || (WaveExists(targetName) && WaveCRC(0, targetName) == WaveCRC(0, loaded)), "wave with same name, but different content, already exists")
		Duplicate/O loaded, sweepDFR:$channelName/WAVE=targetRef
		CreateBackupWave(targetRef)
		WaveClear loaded
	endfor

	AB_SortConfigSweeps(configSweep)

	if(!waveNoteLoaded)
		return 1 // nothing was loaded
	else
		return 0 // no error
	endif
End

/// @brief Sorts the faked Config Sweeps Wave to get correct display order in Sweep Browser
///
/// function is oriented at MDSort()
static Function AB_SortConfigSweeps(config)
	wave/I config

	string wavenote = Note(config)
	variable numRows = DimSize(config, ROWS)

	ASSERT(IsValidConfigWave(config, version=0), "Invalid config wave")
	ASSERT(FindDimLabel(config, COLS, "type") != -2, "Config Wave has no column labels")
	ASSERT(FindDimLabel(config, COLS, "number") != -2, "Config Wave has no column labels")

	WAVE/T units = AFH_GetChannelUnits(config)
	Make/I/Free/N=(numRows) keyPrimary, keySecondary
	Make/Free/N=(numRows)/I/U valindex = p

	//sort order: XOP_CHANNEL_TYPE_DAC = 1, XOP_CHANNEL_TYPE_ADC = 0, XOP_CHANNEL_TYPE_TTL = 3
	MultiThread keyPrimary[]   = config[p][%type] == XOP_CHANNEL_TYPE_ADC ? 2 : config[p][%type]
	MultiThread keySecondary[] = config[p][%number]
	Sort/A {keyPrimary, keySecondary}, valindex

	Duplicate/FREE/I config config_temp
	Duplicate/FREE/T units units_temp
	MultiThread config[][] = config_temp[valindex[p]][q]
	units[] = units_temp[valindex[p]]

	Note/K config, TextWaveToList(units, ";")
End

/// @brief Load specified device/sweep combination from Igor experiment file to sweepDFR
///
/// @returns name of loaded sweep
static Function/S AB_LoadSweepFromIgor(discLocation, expFolder, sweepDFR, device, sweep)
	string discLocation, expFolder, device
	DFREF sweepDFR
	variable sweep

	variable numWavesLoaded
	string sweepWaveList = ""
	string sweepWaveName, dataPath

	// we load the backup wave also
	// in case it exists, it holds the original unmodified data
	sweepWaveName  = "sweep_" + num2str(sweep)
	sweepWaveList = AddListItem(sweepWaveList, sweepWaveName, ";", Inf)
	sweepWaveList = AddListItem(sweepWaveList, sweepWaveName + WAVE_BACKUP_SUFFIX, ";", Inf)

	dataPath = GetDeviceDataPathAsString(device)
	dataPath = AB_TranslatePath(dataPath, expFolder)
	DFREF saveDFR = GetDataFolderDFR()
	DFREF newDFR = UniqueDataFolder(GetAnalysisFolder(), "temp")
	numWavesLoaded = AB_LoadDataWrapper(newDFR, discLocation, dataPath, sweepWaveList)

	if(numWavesLoaded <= 0)
		printf "Could not load sweep %d of device %s and %s\r", sweep, device, discLocation
		SetDataFolder saveDFR
		KillOrMoveToTrash(dfr=newDFR)
		KillOrMoveToTrash(dfr=sweepDFR)
		return ""
	endif

	Wave sweepWave = $sweepWaveName

	if(numWavesLoaded == 2)
		ReplaceWaveWithBackup(sweepWave)
	endif

	MoveWave sweepWave, sweepDFR
	SetDataFolder saveDFR
	KillOrMoveToTrash(dfr=newDFR)

	return sweepWaveName
End

/// @brief a failsave alternative for AB_LoadStimsets() to load RAW stimsets
///
/// If a stimset could not get loaded using AB_LoadStimsets()
/// this function is used in addition to try to load the
/// stimset without its corresponding Parameter Waves.
/// overwrite is not supported
///
/// @param expFilePath    Path on disc to igor experiment
/// @param stimsets       ";" separated list of all stimsets
/// @param overwrite      overwrite flag
///
/// @return 1 on error and 0 on success
static Function AB_LoadStimsetsRAW(expFilePath, stimsets, overwrite)
	string expFilePath, stimsets
	variable overwrite

	string stimset
	variable numStimsets, i
	variable error = 0

	numStimsets = ItemsInList(stimsets)
	for(i = 0; i < numStimsets; i += 1)
		stimset = StringFromList(i, stimsets)
		if(AB_LoadStimsetRAW(expFilePath, stimset, overwrite))
			printf "experiment: \t%s \tstimset: \t%s \tload failed for complete stimset\r", expFilePath, stimset
			error = 1
			continue
		endif
		printf "experiment: \t%s \tstimset: \t%s \tloaded complete stimset\r", expFilePath, stimset
	endfor

	return error
End

/// @brief Load specified stimsets from Igor experiment file
///
/// recurses into all dependent stimsets as soon as they have been loaded.
/// the list of stimsets is extended "on the left side": new items are added left.
/// use numEnd to indicate unto which item the list was already processed.
/// see StimsetRecursion() for a similar structure
///
/// @param expFilePath Path on disc to igor experiment
/// @param stimsets           ";" separated list of all stimsets of the current sweep.
/// @param processedStimsets  [optional] input a list of already processed stimsets
/// @param overwrite          overwrite flag
///
/// @return 1 on error and 0 on success
static Function/S AB_LoadStimsets(expFilePath, stimsets, overwrite, [processedStimsets])
	string expFilePath, stimsets, processedStimsets
	variable overwrite

	string stimset, totalStimsets, newStimsets, oldStimsets
	variable numBefore, numMoved, numAfter, numNewStimsets, i
	string loadedStimsets = ""

	if(ParamIsDefault(processedStimsets))
		processedStimsets = ""
	endif

	totalStimsets = stimsets + processedStimsets
	numBefore = ItemsInList(totalStimsets)

	// load first order stimsets
	numNewStimsets = ItemsInList(stimsets)
	for(i = 0; i < numNewStimsets; i += 1)
		stimset = StringFromList(i, stimsets)
		if(AB_LoadStimset(expFilePath, stimset, overwrite))
			if(ItemsInList(processedStimsets) == 0)
				// parent corrupt
				// load other parents, no children needed.
				continue
			else
				// if a (dependent) stimset is missing
				// the corresponding parent can not be created with Parameter Waves
				return loadedStimsets
			endif
		endif
		loadedStimsets = AddListItem(stimset, loadedStimsets)
		numMoved += WB_StimsetFamilyNames(totalStimsets, parent = stimset)
	endfor
	numAfter = ItemsInList(totalStimsets)

	// load next order stimsets
	numNewStimsets = numAfter - numBefore + numMoved
	if(numNewStimsets > 0)
		newStimsets = ListFromList(totalStimsets, 0, numNewStimsets - 1)
		oldStimsets = ListFromList(totalStimsets, numNewStimsets, inf)
		return loadedStimsets + AB_LoadStimsets(expFilePath, newStimsets, overwrite, processedStimsets = oldStimsets)
	endif

	return loadedStimsets
End

/// @brief Load specified stimset from Igor experiment file
///
/// @return 1 on error and 0 on success
static Function AB_LoadStimset(expFilePath, stimset, overwrite)
	string expFilePath, stimset
	variable overwrite

	if(overwrite)
		WB_KillParameterWaves(stimset)
		WB_KillStimset(stimset)
	endif

	if(WB_ParameterWavesExist(stimset))
		return 0
	endif
	if(WB_StimsetExists(stimset))
		return 0
	endif

	if(overwrite)
		WB_KillParameterWaves(stimset)
	endif
	if(!AB_LoadStimsetTemplateWaves(expFilePath, stimset))
		return 0
	endif
	if(!AB_LoadStimsetRAW(expFilePath, stimset, overwrite))
		return 0
	endif

	printf "experiment: \t%s \tstimset: \t%s \tfailed to recreate stimset\r", expFilePath, stimset
	return 1
End

static Function AB_LoadStimsetRAW(expFilePath, stimset, overwrite)
	string expFilePath, stimset
	variable overwrite

	string dataPath, data
	variable numWavesLoaded

	WB_KillParameterWaves(stimset)
	if(overwrite)
		WB_KillStimset(stimset)
	endif

	DFREF newDFR = UniqueDataFolder(GetAnalysisFolder(), "temp")
	DFREF setDFR = GetSetFolder(GetStimSetType(stimset))

	WAVE/Z/SDFR=setDFR wv = $stimset
	if(WaveExists(wv))
		return 0
	endif

	dataPath = GetDataFolder(1, setDFR)
	data = AddListItem(stimset, "")

	DFREF saveDFR = GetDataFolderDFR()
	numWavesLoaded = AB_LoadDataWrapper(newDFR, expFilePath, dataPath, data)
	SetDataFolder saveDFR

	if(numWavesLoaded != 1)
		KillOrMoveToTrash(dfr=newDFR)
		return 1
	endif

	MoveWave newDFR:$stimset setDFR
	KillOrMoveToTrash(dfr=newDFR)

	return 0
End

/// @brief Load template waves for a specific stimset from Igor experiment file
///
/// @return 1 on error and 0 on success
static Function AB_LoadStimsetTemplateWaves(expFilePath, stimset)
	string expFilePath, stimset

	variable channelType, numWavesLoaded, numStimsets, i
	string dataPath
	string parameterWaves = ""

	// load parameter waves
	DFREF newDFR = UniqueDataFolder(GetAnalysisFolder(), "temp")

	parameterWaves = AddListItem(WB_GetParameterWaveName(stimset, STIMSET_PARAM_WP), parameterWaves)
	parameterWaves = AddListItem(WB_GetParameterWaveName(stimset, STIMSET_PARAM_WPT), parameterWaves)
	parameterWaves = AddListItem(WB_GetParameterWaveName(stimset, STIMSET_PARAM_SEGWVTYPE), parameterWaves)

	channelType = GetStimSetType(stimset)
	dataPath = GetSetParamFolderAsString(channelType)

	DFREF saveDFR = GetDataFolderDFR()
	numWavesLoaded = AB_LoadDataWrapper(newDFR, expFilePath, dataPath, parameterWaves)
	SetDataFolder saveDFR

	if(numWavesLoaded != 3)
		KillOrMoveToTrash(dfr=newDFR)
		return 1
	endif

	// move loaded waves to stimset parameter dataFolder
	WAVE WP        = newDFR:$(WB_GetParameterWaveName(stimset, STIMSET_PARAM_WP))
	WAVE/T WPT     = newDFR:$(WB_GetParameterWaveName(stimset, STIMSET_PARAM_WPT))
	WAVE SegWvType = newDFR:$(WB_GetParameterWaveName(stimset, STIMSET_PARAM_SEGWVTYPE))

	DFREF paramDFR = GetSetParamFolder(channelType)

	MoveWave WP, paramDFR
	MoveWave WPT, paramDFR
	MoveWave SegWvType, paramDFR

	KillOrMoveToTrash(dfr=newDFR)

	if(WB_ParameterWavesExist(stimset))
		return 0
	endif

	return 1
End

/// @brief Load custom waves for specified stimset from Igor experiment file
///
/// @return 1 on error and 0 on success
static Function/S AB_LoadCustomWaves(expFilePath, stimsets, overwrite)
	string expFilePath, stimsets
	variable overwrite

	string dependentStimsets, stimset, custom_waves, path, customWaveName
	variable numWaves, numStimsets, i, j, valid
	string loadedStimsets = ""

	WAVE/T cw = WB_CustomWavesPathFromStimSet(stimsetList = stimsets)

	numWaves = DimSize(cw, ROWS)
	Make/FREE/I/N=(numWaves) loaded = 1
	for(i = 0; i < numWaves; i += 1)
		customWaveName = cw[i]

		// handle legacy custom wave format
		if(!isEmpty(customWaveName) && strsearch(customWaveName, ":", 0) == -1)
			path = GetSetFolderAsString(CHANNEL_TYPE_DAC) + ":" + customWaveName
			if(!AB_LoadWave(expFilePath, path, overwrite))
				continue
			endif
			path = GetSetFolderAsString(CHANNEL_TYPE_TTL) + ":" + customWaveName
			if(!AB_LoadWave(expFilePath, path, overwrite))
				continue
			endif
		endif

		// load standard wave format
		if(!AB_LoadWave(expFilePath, customWaveName, overwrite))
			continue
		endif

		// indicate error
		loaded[i] = 0
	endfor

	if(numWaves == 0 || sum(loaded) == numWaves)
		return stimsets
	endif

	// search for uncorrupt stimsets
	numStimsets = ItemsInList(stimsets)
	for(i = 0; i < numStimsets; i += 1)
		valid = 1
		stimset = StringFromList(i, stimsets)
		WAVE/T single_cw = WB_CustomWavesPathFromStimSet(stimsetList = stimset)
		numWaves = DimSize(single_cw, 0)
		for(j = 0; j < numWaves; j += 1)
			FindValue/TEXT=(single_cw[j]) cw
			if(V_Value == -1)
				continue
			endif
			if(loaded[V_Value] == 0)
				valid = 0
				break
			endif
		endfor
		if(valid)
			loadedStimsets = AddListItem(stimset, loadedStimsets)
		endif
	endfor

	return loadedStimsets
End

/// @brief Load specified wave from Igor Experiment file.
///
/// @return 1 on error and 0 on success
static Function AB_LoadWave(expFilePath, fullPath, overwrite)
	string expFilePath, fullPath
	variable overwrite

	variable numWavesLoaded
	string dataFolder
	string loadList = ""

	WAVE/Z wv = $fullPath
	if(overwrite)
		KillOrMoveToTrash(wv=wv)
	endif
	if(WaveExists(wv))
		return 0
	endif

	DFREF saveDFR = GetDataFolderDFR()
	DFREF newDFR = UniqueDataFolder(GetAnalysisFolder(), "temp")

	dataFolder = GetFolder(fullPath)
	loadList = AddListItem(RemovePrefix(fullPath, start = dataFolder), loadList)
	if(isEmpty(dataFolder))
		dataFolder = "root:"
	endif
	numWavesLoaded = AB_LoadDataWrapper(newDFR, expFilePath, dataFolder, loadList)

	if(numWavesLoaded != 1)
		SetDataFolder saveDFR
		KillOrMoveToTrash(dfr=newDFR)
		KillOrMoveToTrash(dfr=sweepDFR)
		return 1
	endif

	WAVE wv = $(GetIndexedObjNameDFR(newDFR, 1, 0))
	SetDataFolder root:
	createDFWithAllParents(dataFolder)
	MoveWave wv, $fullPath

	SetDataFolder saveDFR
	KillOrMoveToTrash(dfr=newDFR)

	return 0
End

static Function AB_SplitSweepIntoComponents(expFolder, device, sweep, sweepWave)
	string expFolder, device
	variable sweep
	Wave sweepWave

	DFREF sweepFolder = GetAnalysisSweepDataPath(expFolder, device, sweep)
	Wave configSweep  = GetAnalysisConfigWave(expFolder, device, sweep)

	if(!IsValidSweepAndConfig(sweepWave, configSweep, configVersion = 0))
		printf "The sweep %d of device %s in experiment %s does not match its configuration data. Therefore we ignore it.\r", sweep, device, expFolder
		return 1
	endif

	DFREF dfr = GetAnalysisLabNBFolder(expFolder, device)
	WAVE/SDFR=dfr numericalValues

	SplitSweepIntoComponents(numericalValues, sweep, sweepWave, configSweep, TTL_RESCALE_ON, targetDFR=sweepFolder)
	KillOrMoveToTrash(wv=sweepWave)

	return 0
End

static Function AB_ScanFolder(win)
	string win

	string baseFolder, path, pxpList, uxpList, nwbList, list, entry
	string nwbFileUsedForExport
	variable i, numEntries

	// create new symbolic path
	baseFolder = GetSetVariableString(win, "setvar_baseFolder")
	path = UniqueName("scanfolder_path", 12, 1)
	NewPath/Q/Z $path, baseFolder

	if(V_flag != 0)
		printf "Could not create the symbolic path referencing %s, maybe the folder does not exist?\r", baseFolder
		return naN
	endif

	AB_ClearAnalysisFolder()

	// process *.pxp, *.uxp, and *.nwb files
	pxpList = GetAllFilesRecursivelyFromPath(path, extension=".pxp")
	uxpList = GetAllFilesRecursivelyFromPath(path, extension=".uxp")
	nwbList = GetAllFilesRecursivelyFromPath(path, extension=".nwb")
	KillPath $path

	// sort combined list for readability
	list = SortList(pxpList + uxpList + nwbList, "|")

	nwbFileUsedForExport = ROStr(GetNWBFilePathExport())

	numEntries = ItemsInList(list, "|")
	for(i = 0; i < numEntries; i += 1)
		entry = StringFromList(i, list, "|")

		if(!cmpstr(entry, nwbFileUsedForExport))
			printf "Ignore %s for adding into the analysis browser\ras we currently export data into it!\r", nwbFileUsedForExport
			ControlWindowToFront()

			continue
		endif

		// analyse files and save content in global list (GetExperimentBrowserGUIList)
		AB_AddFile(baseFolder, entry)
	endfor

	WAVE expBrowserList = GetExperimentBrowserGUIList()
	numEntries = GetNumberFromWaveNote(expBrowserList, NOTE_INDEX)
	AB_ResetListBoxWaves(numEntries)

End

Function/S AB_OpenAnalysisBrowser()

	string panel = "AnalysisBrowser"
	string directory

	if(windowExists(panel))
		DoWindow/F $panel
		return panel
	endif

	WAVE/T list = GetExperimentBrowserGUIList()
	list = ""
	WAVE   sel  = GetExperimentBrowserGUISel()
	sel = 0

	Execute "AnalysisBrowser()"
	GetMiesVersion()

	NVAR JSONid = $GetSettingsJSONid()
	directory = JSON_GetString(jsonID, "/analysisbrowser/directory")
	SetSetVariableString(panel, "setvar_baseFolder", directory)
	PS_InitCoordinates(JSONid, panel, "analysisbrowser")

	return panel
End

Window AnalysisBrowser() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /K=1 /W=(242,176,1118,664)
	SetDrawLayer UserBack
	DrawLine 5,185,105,185
	DrawLine 5,275,105,275
	DrawLine 5,74,105,74
	Button button_base_folder_scan,pos={5,45},size={100,25},proc=AB_ButtonProc_ScanFolder,title="Scan folder"
	Button button_base_folder_scan,userdata(ResizeControlsInfo)= A"!!,?X!!#>B!!#@,!!#=+z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_base_folder_scan,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button button_base_folder_scan,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	Button button_base_folder_scan, help={"Start scanning the base folder recursively for packed/unpacked experiments holding MIES data"}
	SetVariable setvar_baseFolder,pos={118.00,17.00},size={338.00,18.00}
	SetVariable setvar_baseFolder,userdata(ResizeControlsInfo)= A"!!,FQ!!#<@!!#Bc!!#<Hz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	SetVariable setvar_baseFolder,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvar_baseFolder,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvar_baseFolder,value= _STR:"",noedit= 1
	SetVariable setvar_baseFolder, help={"Base folder which is recursively searched for packed/unpacked experiments holding MIES data"}
	ListBox list_experiment_contents,pos={119.00,43.00},size={749.00,439.00},proc=AB_ListBoxProc_ExpBrowser
	ListBox list_experiment_contents,userdata(ResizeControlsInfo)= A"!!,FS!!#>:!!#DK5QF1+J,fQL!!#](Aon\"Qzzzzzzzzzzzzzz!!#o2B4uAezz"
	ListBox list_experiment_contents,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	ListBox list_experiment_contents,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	ListBox list_experiment_contents,listWave=root:MIES:Analysis:expBrowserList
	ListBox list_experiment_contents,selWave=root:MIES:Analysis:expBrowserSel,row= 1
	ListBox list_experiment_contents,mode= 4
	ListBox list_experiment_contents,widths={33,260,24,137,55,45,75,130,45,63}
	ListBox list_experiment_contents,userColumnResize= 1,hScroll= 3
	ListBox list_experiment_contents, help={"Various properties of the loaded sweep data"}
	Button button_select_same_stim_sets,pos={5,80},size={100,40},proc=AB_ButtonProc_SelectStimSets,title="Select same\rstim set sweeps"
	Button button_select_same_stim_sets,help={"Starting from one selected sweep, select all other sweeps which were acquired with the same stimset"}
	Button button_select_same_stim_sets,userdata(ResizeControlsInfo)= A"!!,?X!!#?Y!!#@,!!#>.z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_select_same_stim_sets,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button button_select_same_stim_sets,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	Button button_select_directory,pos={5,15},size={100,25},proc=AB_ButtonProc_SelectDirectory,title="Select directory"
	Button button_select_directory,userdata(ResizeControlsInfo)= A"!!,?X!!#<(!!#@,!!#=+z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_select_directory,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button button_select_directory,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	Button button_select_directory, help={"Open a directory selection dialog"}
	Button button_collapse_all,pos={5,125},size={100,25},proc=AB_ButtonProc_CollapseAll,title="Collapse all"
	Button button_collapse_all, help={"Collapse all entries giving the most compact view"}
	Button button_collapse_all,userdata(ResizeControlsInfo)= A"!!,?X!!#@^!!#@,!!#=+z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_collapse_all,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button button_collapse_all,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	Button button_expand_all,pos={5,155},size={100,25},proc=AB_ButtonProc_ExpandAll,title="Expand all"
	Button button_expand_all, help={"Expand all entries giving the longest view"}
	Button button_expand_all,userdata(ResizeControlsInfo)= A"!!,?X!!#A*!!#@,!!#=+z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_expand_all,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button button_expand_all,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	Button button_load_sweeps,pos={5.00,190.00},size={100.00,25.00},proc=AB_ButtonProc_LoadSweeps,title="Load Sweeps"
	Button button_load_sweeps, help={"Open a sweep browser panel from the selected sweeps. In case an experiment or device is selected, all sweeps are loaded from them."}
	Button button_load_sweeps,userdata(ResizeControlsInfo)= A"!!,?X!!#AM!!#@,!!#=+z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_load_sweeps,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button button_load_sweeps,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	Button button_load_stimsets,pos={5.00,220.00},size={100.00,25.00},proc=AB_ButtonProc_LoadStimsets,title="Load Stimsets"
	Button button_load_stimsets,help={"Open the wave builder panel with the selected stimset. All selected stimsets are loaded recursively."}
	Button button_load_stimsets,userdata(ResizeControlsInfo)= A"!!,?X!!#Ak!!#@,!!#=+z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_load_stimsets,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button button_load_stimsets,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	Button button_show_usercomments,pos={5,280},size={100,40},proc=AB_ButtonProc_OpenCommentNB,title="Open comment \rNB"
	Button button_show_usercomments, help={"Open a read-only notebook showing the user comment for the currently selected experiment."}
	Button button_show_usercomments,userdata(ResizeControlsInfo)= A"!!,?X!!#BF!!#@,!!#>.z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button button_show_usercomments,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button button_show_usercomments,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox checkbox_load_overwrite,pos={20,250},size={64.00,15.00},title="overwrite"
	CheckBox checkbox_load_overwrite,userdata(ResizeControlsInfo)= A"!!,BY!!#B4!!#?9!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox checkbox_load_overwrite,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox checkbox_load_overwrite,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox checkbox_load_overwrite,value= 0, help={"Overwrite existing stimsets"}
	SetWindow kwTopWin,hook(ResizeControls)=ResizeControls#ResizeControlsHook
	SetWindow kwTopWin,userdata(ResizeControlsInfo)= A"!!*'\"z!!#Dk!!#CYzzzzzzzzzzzzzzzzzzzzz"
	SetWindow kwTopWin,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzzzzzzzzzzzzzzz"
	SetWindow kwTopWin,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzzzzzzzzz!!!"
	Execute/Q/Z "SetWindow kwTopWin sizeLimit={657,366,inf,inf}" // sizeLimit requires Igor 7 or later
EndMacro

/// @brief Button "Expand all"
Function AB_ButtonProc_ExpandAll(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch(ba.eventcode)
		case 2:
			AB_ExpandListColumn(EXPERIMENT_TREEVIEW_COLUMN)
			AB_ExpandListColumn(DEVICE_TREEVIEW_COLUMN)
			break
	endswitch

	return 0
End

/// @brief Button "Collapse all"
Function AB_ButtonProc_CollapseAll(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch(ba.eventCode)
		case 2:
			AB_CollapseListColumn(EXPERIMENT_TREEVIEW_COLUMN)
			break
	endswitch

	return 0
End

/// @brief Button "Load Sweeps"
Function AB_ButtonProc_LoadSweeps(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	variable oneValidSweep
	string panel

	switch(ba.eventcode)
		case 2:
			DFREF dfr = SB_OpenSweepBrowser()
			oneValidSweep = AB_LoadFromFile(AB_LOAD_SWEEP, sweepBrowserDFR = dfr)
			SVAR/SDFR=dfr graph
			if(oneValidSweep)
				AD_Update(graph)
				panel = BSP_GetSweepControlsPanel(graph)
				PGC_SetAndActivateControl(panel, "button_SweepControl_PrevSweep")
			else
				KillWindow $graph
			endif
			break
	endswitch


	return 0
End

/// @brief Button "Load Stimsets"
Function AB_ButtonProc_LoadStimsets(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	variable oneValidStimset

	switch(ba.eventcode)
		case 2:
			oneValidStimset = AB_LoadFromFile(AB_LOAD_STIMSET)
			if(oneValidStimset)
				WBP_CreateWaveBuilderPanel()
			endif
			break
	endswitch

	return 0
End

/// @brief Button "Scan folder"
Function AB_ButtonProc_ScanFolder(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch(ba.eventCode)
		case 2: // mouse up
			AB_ScanFolder(ba.win)
		break
	endswitch

	return 0
End

/// @brief Button "Select directory"
/// Display dialog box for choosing a folder and call AB_ScanFolder()
Function AB_ButtonProc_SelectDirectory(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	string path, win, baseFolder, folder

	switch(ba.eventCode)
		case 2: // mouse up
			win = ba.win
			baseFolder = GetSetVariableString(win, "setvar_baseFolder")
			folder = AskUserForExistingFolder(baseFolder=baseFolder)
			SetSetVariableString(win, "setvar_baseFolder", folder)
			NVAR JSONid = $GetSettingsJSONid()
			JSON_SetString(jsonID, "/analysisbrowser/directory", folder)
			AB_ScanFolder(win)
			break
	endswitch

	return 0
End

/// @brief Button "Select same stim set sweeps"
Function AB_ButtonProc_SelectStimSets(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	variable numEntries, i
	string selectedStimSet

	switch(ba.eventCode)
		case 2: // mouse up
			WAVE/T expBrowserList = GetExperimentBrowserGUIList()
			WAVE expBrowserSel    = GetExperimentBrowserGUISel()

			WAVE/Z indizes = FindIndizes(expBrowserSel, col=0, var=1)

			if(!WaveExists(indizes) || DimSize(indizes, ROWS) != 1)
				print "Please select exactly one row to use this feature"
				ControlWindowToFront()
				break
			endif

			selectedStimSet = expBrowserList[indizes[0]][%$"stim sets"]

			if(isEmpty(selectedStimSet))
				print "Can not work with an empty stim set in the selection"
				ControlWindowToFront()
				break
			endif

			WAVE indizes = FindIndizes(expBrowserList, colLabel="stim sets", str=selectedStimSet)
			expBrowserSel[][] = expBrowserSel[p][q] & ~LISTBOX_SELECTED

			numEntries = DimSize(indizes, ROWS)
			for(i = 0; i < numEntries; i += 1)
				expBrowserSel[indizes[i]][] = expBrowserSel[p][q] | LISTBOX_SELECTED
			endfor

			break
	endswitch

	return 0
End

/// @brief main ListBox list_experiment_contents
Function AB_ListBoxProc_ExpBrowser(lba) : ListBoxControl
	STRUCT WMListboxAction &lba

	variable mask ,last, length, sourceRow, targetRow, numRows, row, col
	variable i, sweepCol, sweep
	string str, expFolder, device

	switch(lba.eventCode)
		case 1: // mouse down
			row = lba.row
			col = lba.col
			lba.blockreentry = 1

			WAVE/T expBrowserList = GetExperimentBrowserGUIList()
			WAVE expBrowserSel = GetExperimentBrowserGUISel()
			WAVE/T expBrowserListBak = CreateBackupWave(expBrowserList)
			WAVE expBrowserSelBak = CreateBackupWave(expBrowserSel)

			numRows = DimSize(expBrowserSel, ROWS)

			if(row < 0 || row >=  numRows || col < 0 || col >= DimSize(expBrowserSel, COLS))
				// clicked outside the list
				break
			endif

			mask = expBrowserSel[row][col]
			if(!(mask & LISTBOX_TREEVIEW)) // clicked cell is not a treeview expansion node
				break
			endif

			if(mask & LISTBOX_TREEVIEW_EXPANDED)
				AB_CollapseListEntry(row, col)
			else
				AB_ExpandListEntry(row, col)
			endif

			break
	endswitch

	return 0
End

/// @brief Button "Open comment NB"
Function AB_ButtonProc_OpenCommentNB(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	variable row, mapIndex
	string device, fileName, dataFolder, discLocation
	string titleString, commentNotebook, comment

	switch(ba.eventCode)
		case 2: // mouse up
			WAVE/T expBrowserList = GetExperimentBrowserGUIList()
			WAVE expBrowserSel    = GetExperimentBrowserGUISel()
			WAVE/T map = GetAnalysisBrowserMap()

			WAVE/Z indizes = FindIndizes(expBrowserSel, col=0, var=1)

			if(!WaveExists(indizes) || DimSize(indizes, ROWS) != 1)
				print "Please select a sweep belonging to a device to use this feature"
				ControlWindowToFront()
				break
			endif

			row = indizes[0]
			mapIndex = str2num(expBrowserList[row][%experiment][1])

			device = GetLastNonEmptyEntry(expBrowserList, "device", row)
			if(isEmpty(device))
				print "Please select a sweep belonging to a device to use this feature"
				ControlWindowToFront()
				break
			endif

			fileName     = map[mapIndex][%FileName]
			dataFolder   = map[mapIndex][%DataFolder]
			discLocation = map[mapIndex][%DiscLocation]

			SVAR/Z/SDFR=GetAnalysisDeviceFolder(dataFolder, device) userComment
			if(!SVAR_Exists(userComment))
				comment = "The user comment string does not exist for the given device!"
			else
				comment = userComment
			endif

			sprintf titleString, "Experiment %s and Device %s", fileName, device
			commentNotebook = UniqueName("EB_UserComment", 10, 0)
			NewNoteBook/K=1/F=0/OPTS=(2^2 + 2^3)/N=$commentNotebook/W=(0,0,300,400) as titleString
			ReplaceNotebookText(commentNotebook, comment)
			break
	endswitch

	return 0
End

/// @brief Load dropped NWB files into the analysis browser
static Function BeforeFileOpenHook(refNum, file, pathName, type, creator, kind)
	variable refNum, kind
	string file, pathName, type, creator
	string baseFolder, fileSuffix
	variable numEntries

	LOG_AddEntry(PACKAGE_MIES, "start")

	fileSuffix = GetFileSuffix(file)
	if(cmpstr(fileSuffix, "nwb"))
		LOG_AddEntry(PACKAGE_MIES, "end")
		return 0
	endif

	Pathinfo $pathName
	baseFolder = S_path

	AB_OpenAnalysisBrowser()
	// we can not add files to the map if some entries are collapsed
	// so we have to expand all first.
	PGC_SetAndActivateControl("AnalysisBrowser", "button_expand_all", val = 1)

	if(AB_AddFile(basefolder, basefolder + file))
		// already loaded or error
		LOG_AddEntry(PACKAGE_MIES, "end")
		return 1
	endif

	WAVE expBrowserList = GetExperimentBrowserGUIList()
	numEntries = GetNumberFromWaveNote(expBrowserList, NOTE_INDEX)
	AB_ResetListBoxWaves(numEntries)

	LOG_AddEntry(PACKAGE_MIES, "end")

	return 1
End

Function/S AB_GetAllDevicesForExperiment(string dataFolder)

	DFREF dfr = GetAnalysisExpFolder(dataFolder)

	return GetListOfDataFolders(dfr)
End
