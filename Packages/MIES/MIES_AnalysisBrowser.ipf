#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_AB
#endif

/// @file MIES_AnalysisBrowser.ipf
/// @brief __AB__ Analysis browser
///
/// Has no dependencies on any hardware related functions.

static Constant    EXPERIMENT_TREEVIEW_COLUMN = 0
static Constant    DEVICE_TREEVIEW_COLUMN     = 3
static Constant    AB_LOAD_SWEEP              = 0
static Constant    AB_LOAD_STIMSET            = 1
static StrConstant AB_UDATA_WORKINGDF         = "datafolder"
static StrConstant AB_WORKFOLDER_NAME         = "workFolder"

static Function AB_ResetListBoxWaves()

	variable col, val, newSize

	WAVE   expBrowserSel  = GetExperimentBrowserGUISel()
	WAVE/T expBrowserList = GetExperimentBrowserGUIList()
	newSize = GetNumberFromWaveNote(expBrowserList, NOTE_INDEX)
	Redimension/N=(newSize, -1, -1, -1) expBrowserList, expBrowserSel

	if(DimSize(expBrowserSel, ROWS) > 0)
		FastOp expBrowserSel = 0

		val = LISTBOX_TREEVIEW | LISTBOX_TREEVIEW_EXPANDED

		col = FindDimLabel(expBrowserList, COLS, "file")
		ASSERT(col >= 0, "invalid column index")
		expBrowserSel[][col - 1] = !cmpstr(expBrowserList[p][col], "") ? 0 : val

		col = FindDimLabel(expBrowserList, COLS, "device")
		ASSERT(col >= 0, "invalid column index")
		expBrowserSel[][col - 1] = !cmpstr(expBrowserList[p][col], "") ? 0 : val
	endif

	// backup initial state
	WAVE/T expBrowserSelBak  = CreateBackupWave(expBrowserSel, forceCreation = 1)
	WAVE/T expBrowserListBak = CreateBackupWave(expBrowserList, forceCreation = 1)
End

/// @brief Remove empty working DF from previous AB sessions
static Function AB_RemoveEmptyWorkingDF()

	string regEx = AB_WORKFOLDER_NAME + "*"
	DFREF dfrFolder

	DFREF  dfr         = GetAnalysisFolder()
	WAVE/T workFolders = ListToTextWave(GetListOfObjects(dfr, regEx, typeFlag = COUNTOBJECTS_DATAFOLDER, fullPath = 1), ";")
	Make/FREE/N=(DimSize(workFolders, ROWS))/DF dfrWork = $workFolders[p]
	for(dfrFolder : dfrWork)
		RemoveEmptyDataFolder(dfrFolder)
	endfor
End

/// @brief Reset all waves of the main experiment browser
static Function AB_InitializeAnalysisBrowserWaves()

	WAVE folderColors = GetAnalysisBrowserGUIFolderColors()

	WAVE/T folderList      = GetAnalysisBrowserGUIFolderList()
	WAVE   folderSelection = GetAnalysisBrowserGUIFolderSelection()
	Redimension/N=(0, -1, -1) folderList, folderSelection

	WAVE/T map = GetAnalysisBrowserMap()
	map = ""
	SetNumberInWaveNote(map, NOTE_INDEX, 0)

	WAVE/T list = GetExperimentBrowserGUIList()
	WAVE   sel  = GetExperimentBrowserGUISel()
	Redimension/N=(MINIMUM_WAVE_SIZE, -1, -1, -1) list, sel
	list = ""
	SetNumberInWaveNote(list, NOTE_INDEX, 0)
	FastOp sel = 0
End

/// @brief Create relation (map) between file on disk and datafolder in current experiment
///
/// @return index into mapping wave of the newly added entry or -1 if the file
///         is already in the map
static Function AB_AddMapEntry(baseFolder, discLocation)
	string baseFolder, discLocation

	variable nextFreeIndex, fileID, nwbVersion, dim, writeIndex
	string dataFolder, fileType, relativePath, extension
	WAVE/T map = GetAnalysisBrowserMap()

	WAVE/Z indizes = FindIndizes(map, colLabel = "DiscLocation", str = discLocation)

	if(WaveExists(indizes))
		DEBUGPRINT("Skipping duplicated file: ", str = discLocation)
		return -1
	endif

	nextFreeIndex = GetNumberFromWaveNote(map, NOTE_INDEX)
	dim           = FindDimLabel(map, COLS, "DiscLocation")
	FindValue/TEXT=""/TXOP=4/RMD=[0, nextFreeIndex - 1][dim] map
	if(V_row >= 0)
		writeIndex = V_row
	else
		writeIndex = nextFreeIndex
		EnsureLargeEnoughWave(map, indexShouldExist = writeIndex, dimension = ROWS)
	endif

	// %DiscLocation = full path to file
	map[writeIndex][%DiscLocation] = discLocation

	// %FileName = filename + extension
	relativePath               = RemovePrefix(discLocation, start = baseFolder)
	map[writeIndex][%FileName] = relativePath

	extension = "." + GetFileSuffix(discLocation)

	// %FileType = igor
	strswitch(extension)
		case ".pxp":
		case ".uxp":
			fileType = ANALYSISBROWSER_FILE_TYPE_IGOR
			break
		case ".nwb":
			fileID     = H5_OpenFile(discLocation)
			nwbVersion = GetNWBMajorVersion(ReadNWBVersion(fileID))
			H5_CloseFile(fileID)
			switch(nwbVersion)
				case 1:
					fileType = ANALYSISBROWSER_FILE_TYPE_NWBv1
					break
				case 2:
					fileType = ANALYSISBROWSER_FILE_TYPE_NWBv2
					break
				default:
					ASSERT(0, "Unknown NWB version")
			endswitch
			break
		default:
			ASSERT(0, "invalid file type")
	endswitch
	map[writeIndex][%FileType] = fileType

	DFREF dfrAB     = GetAnalysisFolder()
	DFREF dfr       = dfrAB:$AB_GetUserData(AB_UDATA_WORKINGDF)
	DFREF expFolder = UniqueDataFolder(dfr, RemoveEnding(relativePath, extension))
	dataFolder                   = RemovePrefix(GetDataFolder(1, expFolder), start = GetDataFolder(1, dfrAB))
	map[writeIndex][%DataFolder] = RemoveEnding(dataFolder, ":")
	RefCounterDFIncrease(expFolder)

	if(writeIndex == nextFreeIndex)
		nextFreeIndex += 1
		SetNumberInWaveNote(map, NOTE_INDEX, nextFreeIndex)
	endif

	return writeIndex
End

static Function AB_RemoveMapEntry(variable index)

	string dfABPath, dfPath

	WAVE/T map = GetAnalysisBrowserMap()

	ASSERT(index < DimSize(map, ROWS), "row index out-of-bounds")

	dfABPath = GetDataFolder(1, GetAnalysisFolder())
	dfPath   = map[index][%DataFolder]
	if(!IsEmpty(dfPath))
		DFREF dfr = $(dfABPath + dfPath)
		RefCounterDFDecrease(dfr)
	endif
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
/// 3: %FileType       File Type identifier for routing to loader functions, one of @ref AnalysisBrowserFileTypes
Function/WAVE AB_GetMap(string discLocation)

	variable dim

	WAVE/T map = GetAnalysisBrowserMap()
	dim = FindDimLabel(map, COLS, "DiscLocation")
	FindValue/TXOP=4/TEXT=(discLocation)/RMD=[][dim] map
	ASSERT(V_row >= 0, "invalid index")

	Make/FREE/N=4/T wv
	wv = map[V_row][p]

	SetDimLabel ROWS, 0, DiscLocation, wv
	SetDimLabel ROWS, 1, FileName, wv
	SetDimLabel ROWS, 2, DataFolder, wv
	SetDimLabel ROWS, 3, FileType, wv

	return wv
End

/// @brief save deviceList to wave
/// @return created wave.
Function/WAVE AB_SaveDeviceList(deviceList, dataFolder)
	string deviceList, dataFolder

	variable numDevices
	WAVE/T wv = GetAnalysisDeviceWave(dataFolder)

	WAVE/T deviceListWave = ListToTextWave(deviceList, ";")
	numDevices = DimSize(deviceListWave, ROWS)
	if(numDevices > 0)
		EnsureLargeEnoughWave(wv, indexShouldExist = numDevices, dimension = ROWS)
		wv[0, numDevices - 1] = deviceListWave[p]
	endif

	SetNumberInWaveNote(wv, NOTE_INDEX, numDevices)

	return wv
End

/// @brief general loader for pxp, uxp and nwb files
///
/// @return 0 if the file was loaded, or 1 if not (usually due to an error
///         or because it was already loaded)
static Function AB_AddFile(string discLocation, string sourceEntry)

	variable mapIndex
	variable firstMapped, lastMapped
	string baseFolder

	WAVE/T list = GetExperimentBrowserGUIList()

	baseFolder = SelectString(FileExists(sourceEntry), sourceEntry, GetFolder(sourceEntry))
	mapIndex   = AB_AddMapEntry(baseFolder, discLocation)

	if(mapIndex < 0)
		return 1
	endif

	firstMapped = GetNumberFromWaveNote(list, NOTE_INDEX)
	AB_LoadFile(discLocation)
	lastMapped = GetNumberFromWaveNote(list, NOTE_INDEX) - 1

	if(lastMapped >= firstMapped)
		list[firstMapped, lastMapped][%file][1] = num2str(mapIndex)
		list[firstMapped, lastMapped][%type][1] = sourceEntry
	else // experiment could not be loaded
		AB_RemoveMapEntry(mapIndex)
		return 1
	endif

	return 0
End

/// @brief from a list of extended stimset names with WP_, WPT_ or SegWvType_ prefix
///        return a boiled down list of unique stimset names without prefix
///        @sa NWB_SuffixExtendedStimsetNamesToStimsetNames
Function/S AB_PrefixExtendedStimsetNamesToStimsetNames(string stimsets)

	string prefix1, prefix2, prefix3
	string regexp, prefixRemovedList

	sprintf prefix1, "%s_", GetWaveBuilderParameterTypeName(STIMSET_PARAM_WP)
	sprintf prefix2, "%s_", GetWaveBuilderParameterTypeName(STIMSET_PARAM_WPT)
	sprintf prefix3, "%s_", GetWaveBuilderParameterTypeName(STIMSET_PARAM_SEGWVTYPE)

	regExp            = prefix1 + "|" + prefix2 + "|" + prefix3
	prefixRemovedList = RemovePrefixFromListItem(regExp, stimsets, regExp = 1)

	return GetUniqueTextEntriesFromList(prefixRemovedList, caseSensitive = 0)
End

/// @brief Returns a list of stimset names from an igor experiment file
static Function/S AB_GetStimsetListFromIgorFile(string fullPath)

	string list, wList

	DFREF tmpDFR = NewFreeDataFolder()
	AB_LoadDataWrapper(tmpDFR, fullPath, GetWBSvdStimSetParamPathAS(), "")
	wList = GetListOfObjects(tmpDFR, "*", recursive = 1, typeFlag = COUNTOBJECTS_WAVES, exprType = MATCH_WILDCARD)
	AB_LoadDataWrapper(tmpDFR, fullPath, GetWBSvdStimSetPathAsString(), "")
	list = GetListOfObjects(tmpDFR, "*", recursive = 1, typeFlag = COUNTOBJECTS_WAVES, exprType = MATCH_WILDCARD)

	list = AddListItem(RemoveEnding(wList, ";"), list)

	return AB_PrefixExtendedStimsetNamesToStimsetNames(list)
End

/// @brief returns 1 if the file has stimsets, 0 otherwise
static Function AB_FileHasStimsets(WAVE/T map)

	string   stimSetList
	variable h5_fileID

	strswitch(map[%FileType])
		case ANALYSISBROWSER_FILE_TYPE_IGOR:
			DFREF tmpDFR = NewFreeDataFolder()
			if(AB_LoadDataWrapper(tmpDFR, map[%DiscLocation], GetWBSvdStimSetParamPathAS(), ""))
				return 1
			endif

			return !!AB_LoadDataWrapper(tmpDFR, map[%DiscLocation], GetWBSvdStimSetPathAsString(), "")
		case ANALYSISBROWSER_FILE_TYPE_NWBv1:
		case ANALYSISBROWSER_FILE_TYPE_NWBv2:

			h5_fileID   = H5_OpenFile(map[%DiscLocation])
			stimSetList = ReadStimsets(h5_fileID)
			H5_CloseFile(h5_fileID)

			return !IsEmpty(stimSetList)
		default:
			ASSERT(0, "invalid file type")
	endswitch

	return 0
End

/// @brief function tries to load Data From discLocation.
static Function AB_LoadFile(discLocation)
	string discLocation

	string device, deviceList
	variable numDevices, i, highestSweepNumber

	WAVE/T map = AB_GetMap(discLocation)

	if(!AB_HasCompatibleVersion(discLocation))
		return NaN
	endif

	strswitch(map[%FileType])
		case ANALYSISBROWSER_FILE_TYPE_IGOR:
			AB_LoadResultsFromIgor(map[%DiscLocation], map[%DataFolder])
			break
		case ANALYSISBROWSER_FILE_TYPE_NWBv1:
			// nothing to load
			break
		case ANALYSISBROWSER_FILE_TYPE_NWBv2:
			AB_LoadResultsFromNWB(map[%DiscLocation], map[%DataFolder])
			break
		default:
			ASSERT(0, "invalid file type")
	endswitch

	deviceList = AB_LoadLabNotebook(discLocation)
	WAVE/T deviceWave = AB_SaveDeviceList(deviceList, map[%DataFolder])

	numDevices = GetNumberFromWaveNote(deviceWave, NOTE_INDEX)
	if(!numDevices && AB_FileHasStimsets(map))
		AB_FillListWave(map[%DiscLocation], map[%FileName], "", map[%DataFolder], map[%FileType], $"")
		return NaN
	endif
	for(i = 0; i < numDevices; i += 1)
		device = deviceWave[i]
		strswitch(map[%FileType])
			case ANALYSISBROWSER_FILE_TYPE_IGOR:
				AB_LoadSweepsFromExperiment(map[%DiscLocation], device)
				AB_LoadTPStorageFromIgor(map[%DiscLocation], map[%DataFolder], device)
				AB_LoadUserCommentFromFile(map[%DiscLocation], map[%DataFolder], device)
				break
			case ANALYSISBROWSER_FILE_TYPE_NWBv1:
			case ANALYSISBROWSER_FILE_TYPE_NWBv2:
				AB_LoadSweepsFromNWB(map[%DiscLocation], map[%DataFolder], device)
				AB_LoadTPStorageFromNWB(map[%DiscLocation], map[%DataFolder], device)
				AB_LoadUserCommentAndHistoryFromNWB(map[%DiscLocation], map[%DataFolder], device)
				break
			default:
				ASSERT(0, "invalid file type")
		endswitch

		WAVE/I sweeps = GetAnalysisChannelSweepWave(map[%DataFolder], device)
		AB_FillListWave(map[%DiscLocation], map[%FileName], device, map[%DataFolder], map[%FileType], sweeps)
	endfor
End

/// @brief Check if the given file has a compatible version
///        which this version of the analysis browser can handle.
///
/// @param discLocation file to check, parameter to AB_GetMap()
static Function AB_HasCompatibleVersion(discLocation)
	string discLocation

	string   dataFolderPath
	variable numWavesLoaded

	WAVE/T map = AB_GetMap(discLocation)

	strswitch(map[%FileType])
		case ANALYSISBROWSER_FILE_TYPE_IGOR:
			DFREF targetDFR = GetAnalysisExpFolder(map[%DataFolder])
			dataFolderPath = GetMiesPathAsString()

			numWavesLoaded = AB_LoadDataWrapper(targetDFR, map[%DiscLocation], dataFolderPath, "pxpVersion", typeFlags = LOAD_DATA_TYPE_NUMBERS)

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
		case ANALYSISBROWSER_FILE_TYPE_NWBv1:
		case ANALYSISBROWSER_FILE_TYPE_NWBv2:
			return 1
		default:
			ASSERT(0, "invalid file type")
	endswitch
End

static Function/S AB_GetSettingNumFiniteVals(wv, device, sweepNo, name)
	WAVE     wv
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

/// @brief Creates list-view for AnalysisBrowser
///
/// Depends on LabNoteBook to be loaded prior to call.
///
/// @param diskLocation full file path of Project file
/// @param fileName     current Project's filename
/// @param device       current device, if device is empty only the experiment name is added
/// @param dataFolder   current Project's Lab Notebook DataFolder reference
/// @param fileType     current Project's file type, one of @ref AnalysisBrowserFileTypes
/// @param sweepNums    Wave containing all sweeps actually present for device
static Function AB_FillListWave(string diskLocation, string fileName, string device, string dataFolder, string fileType, WAVE/Z sweepNums)

	variable index, startIndex, numWaves, i, j, sweepNo, numRows, numCols, setCount, dim
	string str

	WAVE/T list = GetExperimentBrowserGUIList()
	startIndex = GetNumberFromWaveNote(list, NOTE_INDEX)
	index      = startIndex

	dim = FindDimLabel(list, COLS, "device")
	FindValue/TXOP=4/TEXT=diskLocation/RMD=[0, index - 1][dim][1] list
	if(V_value == -1)
		EnsureLargeEnoughWave(list, indexShouldExist = index, dimension = ROWS)
		list[index][%file][0]   = fileName
		list[index][%type][0]   = fileType
		list[index][%device][1] = diskLocation
	endif

	if(IsEmpty(device))
		SetNumberInWaveNote(list, NOTE_INDEX, index + 1)
		return NaN
	endif

	ASSERT(WaveExists(sweepNums), "sweepNums wave is empty.")

	EnsureLargeEnoughWave(list, indexShouldExist = index, dimension = ROWS)
	list[index][%device][0] = device

	numWaves = GetNumberFromWaveNote(sweepNums, NOTE_INDEX)

	list[index][%'#sweeps'][0] = num2istr(numWaves)
	index                     += 1

	WAVE numericalValues = GetAnalysLBNumericalValues(dataFolder, device)
	WAVE textualValues   = GetAnalysLBTextualValues(dataFolder, device)

	for(i = 0; i < numWaves; i += 1)
		EnsureLargeEnoughWave(list, indexShouldExist = index, dimension = ROWS)

		sweepNo                = sweepNums[i]
		list[index][%sweep][0] = num2str(sweepNo)

		str                     = AB_GetSettingNumFiniteVals(numericalValues, device, sweepNo, "DAC")
		list[index][%'#DAC'][0] = str

		str                     = AB_GetSettingNumFiniteVals(numericalValues, device, sweepNo, "ADC")
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
			index                       += 1
		else
			for(j = 0; j < numRows; j += 1)
				str = settingsText[j]

				if(isEmpty(str))
					continue
				endif

				EnsureLargeEnoughWave(list, indexShouldExist = index, dimension = ROWS)
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
	list[startIndex, index - 1][%sweep][1] = AB_GetRowHash(list, p)
End

static Function/S AB_GetRowHash(WAVE/T list, variable row)

	Duplicate/FREE/RMD=[row][][] list, rowWave

	return WaveHash(rowWave, 4)
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
/// @param recursive      [optional, defaults to 1] when set loads data recursive from the experiment file
///
/// @returns number of loaded items
static Function AB_LoadDataWrapper(DFREF tmpDFR, string expFilePath, string datafolderPath, string listOfNames, [variable typeFlags, variable recursive])

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
	recursive = ParamisDefault(recursive) ? 1 : !!recursive

	fileNameWOExtension = GetBaseName(expFilePath)
	baseFolder          = GetFolder(expFilePath)
	extension           = GetFileSuffix(expFilePath)

	/// @todo this is not 100% correct as users might choose a different name for the unpacked experiment folder
	if(!cmpstr(extension, "uxp"))
		expFileOrFolder = baseFolder + fileNameWOExtension + " Folder"
	else
		expFileOrFolder = expFilePath
	endif

	DFREF savedDF = GetDataFolderDFR()
	SetDataFolder tmpDFR

	// work around LoadData not respecting AbortOnRTE properly
	debugOnError = DisableDebugOnError()

	// also with "/Q" LoadData still complains if the subfolder path does not exist
	AssertOnAndClearRTError()
	try
		if(FileExists(expFileOrFolder))
			if(recursive)
				LoadData/Q/R/L=(typeFlags)/S=dataFolderPath/J=listOfNames/O=1 expFileOrFolder; AbortOnRTE
			else
				LoadData/Q/L=(typeFlags)/S=dataFolderPath/J=listOfNames/O=1 expFileOrFolder; AbortOnRTE
			endif
		elseif(FolderExists(expFileOrFolder))
			if(recursive)
				LoadData/Q/D/R/L=(typeFlags)/J=listOfNames/O=1 expFileOrFolder + ":" + dataFolderPath; AbortOnRTE
			else
				LoadData/Q/D/L=(typeFlags)/J=listOfNames/O=1 expFileOrFolder + ":" + dataFolderPath; AbortOnRTE
			endif
		else
			sprintf str, "The experiment file/folder \"%s\" could not be found!\r", ParseFilePath(5, expFileOrFolder, "\\", 0, 0)
			DoAlert/T="Error in AB_LoadDataWrapper" 0, str
			Abort
		endif
	catch
		ClearRTError()
		SetDataFolder savedDF
		ResetDebugOnError(debugOnError)
		return 0
	endtry

	SetDataFolder savedDF
	ResetDebugOnError(debugOnError)

	RemoveAllEmptyDataFolders(tmpDFR)

	regexp = "(?i)" + ConvertListToRegexpWithAlternations(listOfNames)
	list   = GetListOfObjects(tmpDFR, regexp, recursive = recursive, typeFlag = typeFlags)

	return ItemsInList(list)
End

/// @brief Returns a wave containing all present sweep numbers
///
/// @param dataFolder    DataFolder of HDF5 or Experiment File where LabNoteBook is saved
/// @param device        device for which to get sweeps.
/// @param clean         Variable indicating if ouput can contain duplicate values
static Function/WAVE AB_GetSweepsFromLabNotebook(dataFolder, device, [clean])
	string dataFolder, device
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
	WAVE/T map            = AB_GetMap(discLocation)
	DFREF  SweepConfigDFR = GetAnalysisDeviceConfigFolder(map[%DataFolder], device)
	WAVE/I sweeps         = GetAnalysisChannelSweepWave(map[%DataFolder], device)

	// Load Sweep Config Waves
	highestSweepNumber = AB_GetHighestPossibleSweepNum(map[%DataFolder], device)
	if(IsFinite(highestSweepNumber))
		AB_LoadSweepConfigData(map[%DiscLocation], map[%DataFolder], device, highestSweepNumber)
	endif
	listSweepConfig = GetListOfObjects(sweepConfigDFR, ".*")

	// store Sweep Numbers in wave
	numSweeps = ItemsInList(listSweepConfig)
	EnsureLargeEnoughWave(sweeps, indexShouldExist = numSweeps, dimension = ROWS, initialValue = -1)
	for(i = 0; i < numSweeps; i += 1)
		sweepConfig = StringFromList(i, listSweepConfig)
		sweepNumber = ExtractSweepNumber(sweepConfig)
		sweeps[i]   = sweepNumber
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

	WAVE/I sweeps = GetAnalysisChannelSweepWave(dataFolder, device)

	// open hdf5 file
	h5_fileID = H5_OpenFile(discLocation)

	// load from /acquisition
	nwbVersion  = GetNWBMajorVersion(ReadNWBVersion(h5_fileID))
	channelList = ReadAcquisition(h5_fileID, nwbVersion)
	WAVE/T acquisition = GetAnalysisChannelAcqWave(dataFolder, device)
	AB_StoreChannelsBySweep(h5_fileID, nwbVersion, channelList, sweeps, acquisition)

	// load from /stimulus/presentation
	channelList = ReadStimulus(h5_fileID)
	WAVE/T stimulus = GetAnalysisChannelStimWave(dataFolder, device)
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
	WAVE/I sweeps
	WAVE/T storage

	variable numChannels, numSweeps, i, sweepNo, sweep_table_id
	string channelString

	numChannels = ItemsInList(channelList)
	numSweeps   = GetNumberFromWaveNote(sweeps, NOTE_INDEX)

	EnsureLargeEnoughWave(storage, indexShouldExist = numSweeps, dimension = ROWS)
	storage = ""

	WAVE/Z   SweepTableNumber
	WAVE/Z/T SweepTableSeries
	if(nwbVersion == 2)
		[SweepTableNumber, SweepTableSeries] = LoadSweepTable(groupID, nwbVersion)
	endif

	for(i = 0; i < numChannels; i += 1)
		channelString = StringFromList(i, channelList)
		if(nwbVersion == 2)
			WAVE indices = FindIndizes(SweepTableSeries, str = channelString)
			ASSERT(DimSize(indices, ROWS) == 1, "Invalid Amount of Sweep Number Associated in " + channelString)
			sweepNo = SweepTableNumber[indices[0]]
		else
			sweepNo = LoadSweepNumber(groupID, channelString, nwbVersion)
		endif
		FindValue/I=(sweepNo)/S=0 sweeps
		ASSERT(isFinite(sweepNo), "Invalid Sweep Number Associated in " + channelString)
		if(V_Value == -1)
			numSweeps += 1
			EnsureLargeEnoughWave(sweeps, indexShouldExist = numSweeps, dimension = ROWS, initialValue = -1)
			EnsureLargeEnoughWave(storage, indexShouldExist = numSweeps, dimension = ROWS)
			sweeps[numSweeps - 1]  = sweepNo
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
	dataFolderPath = GetDeviceTestPulseAsString(device)
	dataFolderPath = AB_TranslatePath(dataFolderPath, expFolder)

	// we can not determine how many TPStorage waves are in dataFolderPath
	// therefore we load all waves and throw the ones we don't need away
	numWavesLoaded = AB_LoadDataWrapper(targetDFR, expFilePath, dataFolderPath, "")

	if(numWavesLoaded)
		wanted   = GetListOfObjects(targetDFR, TP_STORAGE_REGEXP, fullPath = 1)
		all      = GetListOfObjects(targetDFR, ".*", fullPath = 1)
		unwanted = RemoveFromList(wanted, all)

		CallFunctionForEachListItem_TS(KillOrMoveToTrashPath, unwanted)
	endif

	return numWavesLoaded
End

Function AB_LoadTPStorageFromNWB(nwbFilePath, expFolder, device)
	string nwbFilePath, expFolder, device

	variable h5_fileID, testpulseGroup, numEntries, i
	string dataFolderPath, list, name, groupName

	h5_fileID = H5_OpenFile(nwbFilePath)

	groupName      = "/general/testpulse/" + device
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

static Function AB_LoadStoredTestpulsesFromNWB(nwbFilePath, expFolder, device)
	string nwbFilePath, expFolder, device

	variable h5_fileID, testpulseGroup, numEntries, i
	string dataFolderPath, list, name, groupName

	WAVE/WAVE wv = GetAnalysisStoredTestPulses(expFolder, device)

	if(DimSize(wv, ROWS) > 0)
		return NaN
	endif

	h5_fileID = H5_OpenFile(nwbFilePath)

	groupName      = "/general/testpulse/" + device
	testpulseGroup = H5_OpenGroup(h5_fileID, groupName)

	list = H5_ListGroupMembers(testpulseGroup, groupName)
	list = GrepList(list, STORED_TESTPULSES_REGEXP)

	numEntries = ItemsInList(list)
	Redimension/N=(numEntries) wv

	for(i = 0; i < numEntries; i += 1)
		name  = StringFromList(i, list)
		wv[i] = H5_LoadDataset(testpulseGroup, name)
	endfor

	SetNumberInWaveNote(wv, NOTE_INDEX, numEntries)

	HDF5CloseGroup/Z testpulseGroup
	H5_CloseFile(h5_fileID)
End

static Function AB_LoadResultsFromIgor(string expFilePath, string expFolder)
	string   dataFolderPath
	variable numWavesLoaded

	DFREF targetDFR = GetAnalysisResultsFolder(expFolder)
	dataFolderPath = GetResultsFolderAsString()

	numWavesLoaded = AB_LoadDataWrapper(targetDFR, expFilePath, dataFolderPath, "")

	return numWavesLoaded
End

static Function AB_LoadResultsFromNWB(string nwbFilePath, string expFolder)
	variable h5_fileID, resultsGroup, numEntries, i
	string list, name, groupName

	DFREF dfr = GetAnalysisResultsFolder(expFolder)

	if(!IsDataFolderEmpty(dfr))
		return NaN
	endif

	h5_fileID = H5_OpenFile(nwbFilePath)

	groupName    = NWB_RESULTS
	resultsGroup = H5_OpenGroup(h5_fileID, groupName)

	if(IsNaN(resultsGroup))
		// results waves do not exist
		return NaN
	endif

	list = H5_ListGroupMembers(resultsGroup, groupName)

	numEntries = ItemsInList(list)

	for(i = 0; i < numEntries; i += 1)
		name = StringFromList(i, list)
		WAVE/Z wv = H5_LoadDataset(resultsGroup, name)

		if(!WaveExists(wv))
			continue
		endif

		MoveWave wv, dfr
	endfor

	HDF5CloseGroup/Z resultsGroup
	H5_CloseFile(h5_fileID)
End

static Function AB_LoadUserCommentFromFile(expFilePath, expFolder, device)
	string expFilePath, expFolder, device

	string   dataFolderPath
	variable numStringsLoaded

	DFREF targetDFR = GetAnalysisDeviceFolder(expFolder, device)
	dataFolderPath = GetDevicePathAsString(device)
	dataFolderPath = AB_TranslatePath(dataFolderPath, expFolder)

	numStringsLoaded = AB_LoadDataWrapper(targetDFR, expFilePath, dataFolderPath, "userComment", typeFlags = LOAD_DATA_TYPE_STRING)

	return numStringsLoaded
End

static Function AB_LoadUserCommentAndHistoryFromNWB(nwbFilePath, expFolder, device)
	string nwbFilePath, expFolder, device

	string groupName, comment, datasetName, history
	variable h5_fileID, commentGroup, version

	DFREF targetDFR = GetAnalysisDeviceFolder(expFolder, device)
	h5_fileID = H5_OpenFile(nwbFilePath)

	groupName    = "/general/user_comment/" + device
	commentGroup = H5_OpenGroup(h5_fileID, groupName)

	comment = ReadTextDataSetAsString(commentGroup, "userComment")
	HDF5CloseGroup/Z commentGroup

	version = GetNWBMajorVersion(ReadNWBVersion(h5_fileID))

	datasetName = "/general/" + GetHistoryAndLogFileDatasetName(version)
	history     = ReadTextDataSetAsString(h5_fileID, datasetName)

	H5_CloseFile(h5_fileID)

	string/G targetDFR:userComment       = comment
	string/G targetDFR:historyAndLogFile = history
End

static Function/S AB_LoadLabNotebook(discLocation)
	string discLocation

	string device, deviceList, err
	string deviceListChecked = ""
	variable numDevices, i

	WAVE/T map = AB_GetMap(discLocation)
	deviceList = AB_LoadLabNoteBookFromFile(discLocation)

	numDevices = ItemsInList(deviceList)
	for(i = 0; i < numDevices; i += 1)
		device = StringFromList(i, deviceList)

		// check if data was loaded
		DFREF dfr = GetAnalysisLabNBFolder(map[%DataFolder], device)
		if(!AB_checkLabNotebook(dfr))
			KillOrMoveToTrash(dfr = dfr)
			continue
		endif

		AB_updateLabelsInLabNotebook(dfr)

		deviceListChecked = AddListItem(device, deviceListchecked, ";", Inf)
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

	string deviceList = ""
	WAVE/T map        = AB_GetMap(discLocation)

	strswitch(map[%FileType])
		case ANALYSISBROWSER_FILE_TYPE_IGOR:
			deviceList = AB_LoadLabNotebookFromIgor(map[%DiscLocation])
			break
		case ANALYSISBROWSER_FILE_TYPE_NWBv1:
		case ANALYSISBROWSER_FILE_TYPE_NWBv2:
			deviceList = AB_LoadLabNotebookFromNWB(map[%DiscLocation])
			break
	endswitch

	return deviceList
End

static Function/S AB_LoadLabNotebookFromIgor(discLocation)
	string discLocation

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
	labNotebookPath   = GetLabNotebookFolderAsString()
	DFREF newDFR = UniqueDataFolder(GetAnalysisFolder(), "igorLoadNote")
	numWavesLoaded = AB_LoadDataWrapper(newDFR, discLocation, labNotebookPath, labNotebookWaves)

	if(numWavesLoaded <= 0)
		KillOrMoveToTrash(dfr = newDFR)
		return ""
	endif

	numEntries = CountObjectsDFR(newDFR, COUNTOBJECTS_DATAFOLDER)
	numNumbers = ItemsInList(DEVICE_NUMBERS)
	for(i = 0; i < numEntries; i += 1)

		type = GetIndexedObjNameDFR(newDFR, COUNTOBJECTS_DATAFOLDER, i)

		if(GrepString(type, ITC_DEVICE_REGEXP))
			// ITC hardware is in a specific subfolder
			for(j = 0; j < numNumbers; j += 1)
				number = StringFromList(j, DEVICE_NUMBERS)
				device = HW_ITC_BuildDeviceString(type, number)
				path   = GetDataFolder(1, newDFR) + type + ":Device" + number

				AB_LoadLabNotebookFromIgorLow(discLocation, path, device, deviceList)
			endfor
		else // other hardware not
			device = type
			path   = GetDataFolder(1, newDFR) + device
			AB_LoadLabNotebookFromIgorLow(discLocation, path, device, deviceList)
		endif
	endfor

	KillOrMoveToTrash(dfr = newDFR)

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

	WAVE/Z/SDFR=$path numericalKeys

	if(!WaveExists(numericalKeys))
		basepath = path + ":KeyWave"
		if(DataFolderExists(basepath))
			WAVE/Z/SDFR=$basepath numericalKeys = keyWave
		endif
	endif

	WAVE/Z/SDFR=$path numericalValues

	if(!WaveExists(numericalValues))
		basepath = path + ":settingsHistory"
		if(DataFolderExists(basepath))
			WAVE/Z/SDFR=$basepath numericalValues = settingsHistory
		endif
	endif

	WAVE/Z/SDFR=$path textualKeys

	if(!WaveExists(textualKeys))
		basepath = path + ":TextDocKeyWave"
		if(DataFolderExists(basepath))
			WAVE/Z/SDFR=$basepath textualKeys = txtDocKeyWave
		endif
	endif

	WAVE/Z/SDFR=$path textualValues

	if(!WaveExists(textualValues))
		basepath = path + ":textDocumentation"
		if(DataFolderExists(basepath))
			WAVE/Z/SDFR=$basepath textualValues = txtDocWave
		endif
	endif

	if(!WaveExists(numericalKeys) || !WaveExists(numericalValues) || !WaveExists(textualKeys) || !WaveExists(textualValues))
		printf "Could not find all four labnotebook waves, dropping all data from device %s in file %s\r", device, discLocation
		return NaN
	endif

	// copy and rename loaded waves to Analysisbrowser directory
	DFREF dfr = GetAnalysisLabNBFolder(experiment[%DataFolder], device)
	Duplicate/O numericalKeys, dfr:numericalKeys/WAVE=numericalKeys
	Duplicate/O numericalValues, dfr:numericalValues/WAVE=numericalValues
	Duplicate/O textualKeys, dfr:textualKeys/WAVE=textualKeys
	Duplicate/O textualValues, dfr:textualValues

	DEBUGPRINT("Loaded Igor labnotebook for device: ", str = device)
	deviceList = AddListItem(device, deviceList, ";", Inf)
End

static Function/S AB_LoadLabNotebookFromNWB(discLocation)
	string discLocation

	variable numDevices, numLoaded, i
	variable h5_fileID, h5_notebooksID
	string notebookList, deviceList, device

	WAVE/T nwb = AB_GetMap(discLocation)

	AssertOnAndClearRTError()
	try
		h5_fileID = H5_OpenFile(nwb[%DiscLocation])
	catch
		ClearRTError()
		printf "Could not open the NWB file %s.\r", nwb[%DiscLocation]
		H5_CloseFile(h5_fileID)
		return ""
	endtry

	notebookList   = ReadLabNoteBooks(h5_fileID)
	h5_notebooksID = H5_OpenGroup(h5_fileID, "/general/labnotebook")

	numDevices = ItemsInList(notebookList)
	devicelist = ""
	for(i = 0; i < numDevices; i += 1)
		device = StringFromList(i, notebookList)

		DFREF notebookDFR = GetAnalysisLabNBFolder(nwb[%DataFolder], device)
		numLoaded = NWB_LoadLabNoteBook(h5_notebooksID, device, notebookDFR)
		if(numLoaded != 4)
			printf "Could not find four labnotebook waves in nwb file for device %s\r", device
			KillOrMoveToTrash(dfr = NotebookDFR)
			continue
		endif

		/// add current device to output devicelist
		DEBUGPRINT("Loaded NWB labnotebook for device: ", str = device)
		devicelist = AddListItem(device, devicelist, ";", Inf)
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

	WAVE/Z/SDFR=dfr numericalKeys
	WAVE/Z/SDFR=dfr numericalValues
	WAVE/Z/SDFR=dfr textualKeys
	WAVE/Z/SDFR=dfr textualValues

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

	WAVE/Z/SDFR=dfr numericalKeys
	WAVE/Z/SDFR=dfr numericalValues
	WAVE/Z/SDFR=dfr textualKeys
	WAVE/Z/SDFR=dfr textualValues

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

	DFREF dfr        = GetAnalysisExpFolder(expFolder)
	NVAR  pxpVersion = $GetPxpVersionForAB(dfr)

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

	step = 1
	for(i = 0;; i += 1)
		start = i * LOAD_CONFIG_CHUNK_SIZE
		stop  = (i + 1) * LOAD_CONFIG_CHUNK_SIZE

		listOfWaves    = BuildList("Config_Sweep_%d", start, step, stop)
		numWavesLoaded = AB_LoadDataWrapper(targetDFR, expFilePath, dataFolderPath, listOfWaves)

		if(numWavesLoaded <= 0 && stop >= highestSweepNumber)
			break
		endif

		totalNumWavesLoaded += numWavesLoaded
	endfor

	return totalNumWavesLoaded
End

/// @brief Expand all tree views in the given column
static Function AB_ExpandListColumn(col)
	variable col

	variable numRows, row, i, mask

	WAVE expBrowserSel = GetExperimentBrowserGUISel()

	WAVE   selBits = AB_ReturnAndClearGUISelBits()
	WAVE/Z indizes = FindIndizes(expBrowserSel, col = col, var = LISTBOX_TREEVIEW)
	AB_SetGUISelBits(selBits)

	if(!WaveExists(indizes))
		return NaN
	endif

	numRows = DimSize(indizes, ROWS)
	for(i = numRows - 1; i >= 0; i -= 1)

		row  = indizes[i]
		mask = expBrowserSel[row][col]
		if(mask & LISTBOX_TREEVIEW_EXPANDED)
			continue
		endif

		expBrowserSel[row][col] = SetBit(mask, LISTBOX_TREEVIEW_EXPANDED)
		AB_ExpandListEntry(row, col)
	endfor
End

/// @brief Collapse all tree views in the given column
static Function AB_CollapseListColumn(col)
	variable col

	variable numRows, row, i, mask

	WAVE expBrowserSel = GetExperimentBrowserGUISel()

	WAVE   selBits = AB_ReturnAndClearGUISelBits()
	WAVE/Z indizes = FindIndizes(expBrowserSel, col = col, var = LISTBOX_TREEVIEW | LISTBOX_TREEVIEW_EXPANDED)
	AB_SetGUISelBits(selBits)

	if(!WaveExists(indizes))
		return NaN
	endif

	numRows = DimSize(indizes, ROWS)
	for(i = numRows - 1; i >= 0; i -= 1)

		row  = indizes[i]
		mask = expBrowserSel[row][col]
		if(mask & LISTBOX_TREEVIEW_EXPANDED)
			expBrowserSel[row][col] = ClearBit(mask, LISTBOX_TREEVIEW_EXPANDED)
			AB_CollapseListEntry(row, col)
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
static Function/WAVE AB_ReturnAndClearGUISelBits()

	WAVE expBrowserSel = GetExperimentBrowserGUISel()

	Make/FREE/N=(DimSize(expBrowserSel, ROWS)) selBits = expBrowserSel[p][0] & LISTBOX_SELECTED
	expBrowserSel[][0] = expBrowserSel[p][0] & ~LISTBOX_SELECTED

	return selBits
End

/// @brief Collapse the given treeview
static Function AB_CollapseListEntry(variable row, variable col)

	variable mask, last, i, j, colSize, hasTreeView

	WAVE/T expBrowserList    = GetExperimentBrowserGUIList()
	WAVE   expBrowserSel     = GetExperimentBrowserGUISel()
	WAVE/T expBrowserListBak = CreateBackupWave(expBrowserList)
	WAVE   expBrowserSelBak  = CreateBackupWave(expBrowserSel)

	mask = expBrowserSel[row][col]
	ASSERT(mask & LISTBOX_TREEVIEW && !(mask & LISTBOX_TREEVIEW_EXPANDED), "listbox entry is not a treeview expansion node or is already collapsed")

	last    = AB_GetRowWithNextTreeView(expBrowserSel, row, col)
	colSize = DimSize(expBrowserSel, COLS)
	for(i = last - 1; i >= row; i -= 1)
		hasTreeView = i == row
		for(j = col + 1; j < colSize; j += 1)
			mask = expBrowserSel[i][j]
			if(mask & (LISTBOX_TREEVIEW | LISTBOX_TREEVIEW_EXPANDED))
				expBrowserSel[i][j] = ClearBit(mask, LISTBOX_TREEVIEW_EXPANDED)
				hasTreeView         = 1
			endif
		endfor
		if(!hasTreeView)
			DeleteWavePoint(expBrowserSel, ROWS, i)
			DeleteWavePoint(expBrowserList, ROWS, i)
		endif
	endfor
End

/// @brief Expand the given treeview
static Function AB_ExpandListEntry(variable row, variable col)

	variable mask, last, length
	variable sourceRowStart, sourceRowEnd, targetRow
	variable i, j, colSize, val, lastExpandedRow

	WAVE/T expBrowserList    = GetExperimentBrowserGUIList()
	WAVE   expBrowserSel     = GetExperimentBrowserGUISel()
	WAVE/T expBrowserListBak = CreateBackupWave(expBrowserList)
	WAVE   expBrowserSelBak  = CreateBackupWave(expBrowserSel)

	mask = expBrowserSel[row][col]
	ASSERT(mask & LISTBOX_TREEVIEW && mask & LISTBOX_TREEVIEW_EXPANDED, "listbox entry is not a treeview expansion node or already expanded")

	lastExpandedRow = NaN
	last            = AB_GetRowWithNextTreeView(expBrowserSel, row, col)
	colSize         = DimSize(expBrowserSel, COLS)
	for(i = last - 1; i >= row; i -= 1)
		for(j = colSize - 1; j >= col; j -= 1)
			val = i == row && j == col ? ClearBit(mask, LISTBOX_TREEVIEW_EXPANDED) : expBrowserSel[i][j]
			if(!(val & LISTBOX_TREEVIEW))
				continue
			endif

			if(val & LISTBOX_TREEVIEW_EXPANDED)
				lastExpandedRow = i
				continue
			endif

			if(lastExpandedRow != i)
				sourceRowStart = AB_GetListRowWithSameHash(expBrowserListBak, expBrowserList[i][%sweep][1]) + 1
				sourceRowEnd   = AB_GetRowWithNextTreeView(expBrowserSelBak, sourceRowStart - 1, j) - 1
				length         = sourceRowEnd - sourceRowStart + 1
				if(length > 0)
					targetRow = i + 1
					InsertPoints targetRow, length, expBrowserList, expBrowserSel
					expBrowserList[targetRow, targetRow + length - 1][][] = expBrowserListBak[sourceRowStart - targetRow + p][q][r]
					expBrowserSel[targetRow, targetRow + length - 1][]    = expBrowserSelBak[sourceRowStart - targetRow + p][q]
				endif
				lastExpandedRow = i
			endif
			expBrowserSel[i][j] = SetBit(val, LISTBOX_TREEVIEW_EXPANDED)
		endfor
	endfor
End

static Function AB_GetListRowWithSameHash(WAVE/T list, string h)

	variable dim = FindDimLabel(list, COLS, "sweep")
	FindValue/TXOP=4/TEXT=h/RMD=[][dim][1] list
	ASSERT(V_row >= 0, "List row not found")

	return V_row
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
		expBrowserSel[row][subSectionColumn] = expBrowserSel[row][subSectionColumn] | LISTBOX_TREEVIEW_EXPANDED
		AB_ExpandListEntry(row, subSectionColumn)
		return 0
	endif
End

/// @brief get indizes from AB window while successive expanding all columns
///
/// @returns valid indizes wave on success
static Function/WAVE AB_GetExpandedIndices()
	variable i, row, numEntries

	WAVE expBrowserSel = GetExperimentBrowserGUISel()
	// Our mode for the listbox stores the selection bit only in the first column
	WAVE/Z wv = FindIndizes(expBrowserSel, var = 1, prop = PROP_MATCHES_VAR_BIT_MASK)
	if(!WaveExists(wv))
		Make/FREE/N=0 wv
		return wv
	endif

	// expand all selected treeviews
	// as indizes might change during the loop run we have to determine the
	// dimension size in the loop condition
	numEntries = DimSize(wv, ROWS)
	for(i = 0; i < numEntries; i += 1)
		row = wv[i]

		// we have to refetch the selected entries
		if(!AB_ExpandIfCollapsed(row, EXPERIMENT_TREEVIEW_COLUMN))
			WAVE wv = FindIndizes(expBrowserSel, var = 1, prop = PROP_MATCHES_VAR_BIT_MASK)
			i = 0
		endif

		if(!AB_ExpandIfCollapsed(row, DEVICE_TREEVIEW_COLUMN))
			WAVE wv = FindIndizes(expBrowserSel, var = 1, prop = PROP_MATCHES_VAR_BIT_MASK)
			i = 0
		endif
	endfor

	return wv
End

static Function AB_GUIRowIsStimsetsOnly(variable row)

	WAVE/T expBrowserList = GetExperimentBrowserGUIList()

	return !IsEmpty(expBrowserList[row][%file]) && IsEmpty(expBrowserList[row][%device])
End

/// @returns 0 if at least one sweep or stimset could be loaded, 1 otherwise
static Function AB_LoadFromExpandedRange(variable row, variable subSectionColumn, variable loadType, [variable overwrite, DFREF sweepBrowserDFR, WAVE/T dfCollect])

	variable j, endRow, mapIndex, sweep, oneValidLoad, index
	string device, discLocation, dataFolder, fileName, fileType

	WAVE   expBrowserSel  = GetExperimentBrowserGUISel()
	WAVE/T expBrowserList = GetExperimentBrowserGUIList()
	WAVE/T map            = GetAnalysisBrowserMap()

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

		if(AB_GUIRowIsStimsetsOnly(row))
			if(loadType != AB_LOAD_STIMSET)
				return 1
			endif
			device = ""
		else
			if(expBrowserSel[j][EXPERIMENT_TREEVIEW_COLUMN] & LISTBOX_TREEVIEW || expBrowserSel[j][DEVICE_TREEVIEW_COLUMN] & LISTBOX_TREEVIEW)
				// ignore rows with tree view icons, we have them already in our list
				continue
			endif

			sweep = str2num(expBrowserList[j][%sweep])

			// sweeps with multiple DA channels occupy multiple rows,
			// ignore them as they all stem from the same sweep
			if(!IsFinite(sweep))
				continue
			endif

			device = GetLastNonEmptyEntry(expBrowserList, "device", j)
		endif
		mapIndex     = str2num(expBrowserList[j][%file][1])
		dataFolder   = map[mapIndex][%DataFolder]
		discLocation = map[mapIndex][%DiscLocation]
		fileType     = map[mapIndex][%FileType]
		fileName     = map[mapIndex][%FileName]

		switch(loadType)
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

				index = GetNumberFromWaveNote(dfCollect, NOTE_INDEX)
				EnsureLargeEnoughWave(dfCollect, indexShouldExist = index)
				dfCollect[index] = dataFolder
				SetNumberInWaveNote(dfCollect, NOTE_INDEX, index + 1)

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
	WAVE selWave
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

static Function AB_LoadFromFile(loadType, [sweepBrowserDFR])
	variable loadType
	DFREF    sweepBrowserDFR

	variable mapIndex, sweep, numRows, i, row, overwrite, oneValidLoad, index
	string dataFolder, fileName, discLocation, fileType, device

	if(loadType == AB_LOAD_SWEEP)
		ASSERT(!ParamIsDefault(sweepBrowserDFR), "create sweepBrowser DataFolder with SB_OpenSweepBrowser() prior")
		ASSERT(IsGlobalDataFolder(sweepBrowserDFR), "sweepBrowser DataFolder does not exist")
	endif

	WAVE indizes = AB_GetExpandedIndices()
	numRows = DimSize(indizes, ROWS)
	if(numRows == 0)
		return 0
	endif

	WAVE/T expBrowserList = GetExperimentBrowserGUIList()
	WAVE/T map            = GetAnalysisBrowserMap()
	overwrite = GetCheckBoxState("AnalysisBrowser", "checkbox_load_overwrite")
	Make/FREE/T/N=(MINIMUM_WAVE_SIZE) dfCollect
	SetNumberInWaveNote(dfCollect, NOTE_INDEX, 0)

	for(i = 0; i < numRows; i += 1)
		row = indizes[i]

		// handle not expanded EXPERIMENT and DEVICE COLUMNS
		switch(loadType)
			case AB_LOAD_STIMSET:
				if(!AB_LoadFromExpandedRange(row, EXPERIMENT_TREEVIEW_COLUMN, loadType, overwrite = overwrite))
					oneValidLoad = 1
					continue
				endif
				if(!AB_LoadFromExpandedRange(row, DEVICE_TREEVIEW_COLUMN, loadType, overwrite = overwrite))
					oneValidLoad = 1
					continue
				endif
				break
			case AB_LOAD_SWEEP:
				if(!AB_LoadFromExpandedRange(row, EXPERIMENT_TREEVIEW_COLUMN, loadType, sweepBrowserDFR = sweepBrowserDFR, overwrite = overwrite, dfCollect = dfCollect))
					oneValidLoad = 1
					continue
				endif
				if(!AB_LoadFromExpandedRange(row, DEVICE_TREEVIEW_COLUMN, loadType, sweepBrowserDFR = sweepBrowserDFR, overwrite = overwrite, dfCollect = dfCollect))
					oneValidLoad = 1
					continue
				endif
				break
			default:
				break
		endswitch

		sweep = str2num(GetLastNonEmptyEntry(expBrowserList, "sweep", row))
		if(!IsFinite(sweep))
			continue
		endif
		device = GetLastNonEmptyEntry(expBrowserList, "device", row)

		mapIndex     = str2num(expBrowserList[row][%file][1])
		fileName     = map[mapIndex][%FileName]
		dataFolder   = map[mapIndex][%DataFolder]
		discLocation = map[mapIndex][%DiscLocation]
		fileType     = map[mapIndex][%FileType]

		switch(loadType)
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

				index = GetNumberFromWaveNote(dfCollect, NOTE_INDEX)
				EnsureLargeEnoughWave(dfCollect, indexShouldExist = index)
				dfCollect[index] = dataFolder
				SetNumberInWaveNote(dfCollect, NOTE_INDEX, index + 1)
				break
			default:
				break
		endswitch
	endfor

	index = GetNumberFromWaveNote(dfCollect, NOTE_INDEX)
	AB_AllocWorkingDFs(dfCollect, index)

	return oneValidLoad
End

Function AB_FreeWorkingDFs(WAVE/T relativeDFPaths, variable actualSize)
	AB_FreeOrAllocWorkingDF(relativeDFPaths, actualSize, 1)
End

Function AB_AllocWorkingDFs(WAVE/T relativeDFPaths, variable actualSize)
	AB_FreeOrAllocWorkingDF(relativeDFPaths, actualSize, 0)
End

static Function AB_FreeOrAllocWorkingDF(WAVE/T relativeDFPaths, variable actualSize, variable free)

	string dfABPath = GetDataFolder(1, GetAnalysisFolder())

	Redimension/N=(actualSize) relativeDFPaths
	WAVE/T uniqueDF = GetUniqueEntries(relativeDFPaths, dontDuplicate = 1)
	uniqueDF[] = dfABPath + uniqueDF[p]
	if(free)
		for(dfPath : uniqueDF)
			RefCounterDFDecrease($dfPath)
		endfor

		return NaN
	endif

	for(dfPath : uniqueDF)
		RefCounterDFIncrease($dfPath)
	endfor
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
	if(!IsEmpty(device))
		ASSERT(isFinite(sweep), "Non-finite sweep")
	endif
	ASSERT(overwrite == 0 || overwrite == 1, "overwrite can either be one or zero")
End

/// @returns 0 if the sweeps could be loaded, or already exists, and 1 on error
static Function AB_LoadSweepFromFile(discLocation, dataFolder, fileType, device, sweep, [overwrite])
	string discLocation, dataFolder, fileType, device
	variable sweep, overwrite

	string sweepFolder, sweeps, msg
	variable h5_fileID, h5_groupID, err

	if(ParamIsDefault(overwrite))
		overwrite = 0
	endif

	ASSERT(!IsEmpty(device), "Empty device.")
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
			err = AB_LoadSweepFromIgor(discLocation, dataFolder, sweepDFR, device, sweep)
			if(err)
				return 1
			endif
			break
		case ANALYSISBROWSER_FILE_TYPE_NWBv1:
		case ANALYSISBROWSER_FILE_TYPE_NWBv2:
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

	string loadedStimsets, msg
	variable h5_fileID, h5_groupID
	string stimsets = ""

	if(ParamIsDefault(overwrite))
		overwrite = 0
	endif
	AB_LoadFromFileASSERT(discLocation, dataFolder, fileType, device, sweep, overwrite)

	strswitch(fileType)
		case ANALYSISBROWSER_FILE_TYPE_IGOR:
			stimsets       = AB_GetStimsetList(fileType, discLocation, dataFolder, device, sweep)
			loadedStimsets = AB_LoadStimsets(discLocation, stimsets, overwrite)
			loadedStimsets = AB_LoadCustomWaves(discLocation, loadedStimsets, overwrite)
			stimsets       = GetListDifference(stimsets, loadedStimsets)
			if(AB_LoadStimsetsRAW(discLocation, stimsets, overwrite))
				return 1
			endif
			break
		case ANALYSISBROWSER_FILE_TYPE_NWBv1:
		case ANALYSISBROWSER_FILE_TYPE_NWBv2:
			stimsets  = AB_GetStimsetList(fileType, discLocation, dataFolder, device, sweep)
			h5_fileID = H5_OpenFile(discLocation)
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

	WB_UpdateChangedStimsets()

	return 0
End

static Function AB_LoadSweepFromNWB(discLocation, sweepDFR, device, sweep)
	string discLocation, device
	DFREF    sweepDFR
	variable sweep

	string channelList
	variable h5_fileID, h5_groupID, numSweeps, version

	WAVE/T nwb = AB_GetMap(discLocation)

	// find sweep in map
	WAVE/T devices = GetAnalysisDeviceWave(nwb[%DataFolder])
	FindValue/S=0/TEXT=(device) devices
	ASSERT(V_Value >= 0, "device not found")
	WAVE/I sweeps = GetAnalysisChannelSweepWave(nwb[%DataFolder], device)
	FindValue/S=0/I=(sweep) sweeps
	ASSERT(V_Value >= 0, "sweep not found")

	// load sweep info wave
	WAVE/WAVE channelStorage = GetAnalysisChannelStorage(nwb[%DataFolder], device)
	numSweeps = GetNumberFromWaveNote(sweeps, NOTE_INDEX)
	if(numSweeps != GetNumberFromWaveNote(channelStorage, NOTE_INDEX))
		EnsureLargeEnoughWave(channelStorage, indexShouldExist = numSweeps, dimension = ROWS)
	endif
	WAVE/Z/I configSweep = channelStorage[V_Value][%configSweep]
	if(!WaveExists(configSweep))
		WAVE/I configSweep = GetAnalysisConfigWave(nwb[%DataFolder], device, sweep)
		channelStorage[V_Value][%configSweep] = configSweep
	endif

	// open NWB file
	h5_fileID = H5_OpenFile(discLocation)
	version   = GetNWBMajorVersion(ReadNWBVersion(h5_fileID))

	// load acquisition
	WAVE/T acquisition = GetAnalysisChannelAcqWave(nwb[%DataFolder], device)
	channelList = acquisition[V_Value]
	h5_groupID  = OpenAcquisition(h5_fileID, version)
	if(AB_LoadSweepFromNWBgeneric(h5_groupID, version, channelList, sweepDFR, configSweep))
		return 1
	endif

	// load stimulus
	WAVE/T stimulus = GetAnalysisChannelStimWave(nwb[%DataFolder], device)
	channelList = stimulus[V_Value]
	h5_groupID  = OpenStimulus(h5_fileID)
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
	DFREF  sweepDFR
	WAVE/I configSweep

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
				WAVE loaded = LoadStimulus(h5_groupID, channel)
				channelName   += "_" + num2str(p.channelNumber)
				fakeConfigWave = 1
				break
			case XOP_CHANNEL_TYPE_ADC:
				channelName = "AD"
				WAVE loaded = LoadTimeseries(h5_groupID, channel, nwbVersion)
				channelName   += "_" + num2str(p.channelNumber)
				fakeConfigWave = 1
				break
			case XOP_CHANNEL_TYPE_TTL:
				channelName = "TTL"
				WAVE loaded = LoadStimulus(h5_groupID, channel)
				channelName += "_" + num2str(p.channelNumber)

				if(IsFinite(p.ttlBit))
					// always fake TTL base wave (bitwise sum of all TTL channels)
					WAVE/Z/I base = sweepDFR:$channelName
					if(!WaveExists(base))
						Duplicate loaded, sweepDFR:$channelName/WAVE=base
						base           = 0
						fakeConfigWave = 1
						SetNumberInWaveNote(base, "fake", 1)
					endif

					if(WaveMax(loaded) < 2)
						base += 2^(p.ttlBit) * loaded
					else
						base += loaded
					endif

					channelName += "_" + num2str(NWB_ConvertToStandardTTLBit(p.ttlBit))
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
			configSweep[numEntries][%timeMS] = trunc(DimDelta(loaded, ROWS) * ONE_TO_MILLI)
			configSweep[numEntries][3]       = -1                                           // -1 for faked Config_Sweeps Waves

			// set unit in config_wave from WaveNote of loaded dataset
			Note/K configSweep, AddListItem(WaveUnits(loaded, COLS), Note(configSweep), ";", Inf)

			fakeConfigWave = 0
		endif

		WAVE/Z/SDFR=sweepDFR targetName = $channelName
		// nwb files created prior to 901428b might have duplicated datasets
		if(WaveExists(targetName) && WaveCRC(0, targetName) != WaveCRC(0, loaded))
			KillOrMoveToTrash(dfr = sweepDFR)
			ASSERT(0, "wave with same name, but different content, already exists: " + channelName)
		endif
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
	WAVE/I config

	string   wavenote = Note(config)
	variable numRows  = DimSize(config, ROWS)

	ASSERT(IsValidConfigWave(config, version = 0), "Invalid config wave")
	ASSERT(FindDimLabel(config, COLS, "type") != -2, "Config Wave has no column labels")
	ASSERT(FindDimLabel(config, COLS, "number") != -2, "Config Wave has no column labels")

	WAVE/T units = AFH_GetChannelUnits(config)
	Make/I/FREE/N=(numRows) keyPrimary, keySecondary
	Make/FREE/N=(numRows)/I/U valindex = p

	//sort order: XOP_CHANNEL_TYPE_DAC = 1, XOP_CHANNEL_TYPE_ADC = 0, XOP_CHANNEL_TYPE_TTL = 3
	MultiThread keyPrimary[] = config[p][%type] == XOP_CHANNEL_TYPE_ADC ? 2 : config[p][%type]
	MultiThread keySecondary[] = config[p][%number]
	Sort/A {keyPrimary, keySecondary}, valindex

	Duplicate/FREE/I config, config_temp
	Duplicate/FREE/T units, units_temp
	MultiThread config[][] = config_temp[valindex[p]][q]
	units[] = units_temp[valindex[p]]

	Note/K config, TextWaveToList(units, ";")
End

/// @brief Load specified device/sweep combination from Igor experiment file to sweepDFR
///
/// @returns name of loaded sweep
static Function AB_LoadSweepFromIgor(string discLocation, string expFolder, DFREF sweepDFR, string device, variable sweep)

	variable i, numWavesLoaded, numComponentsLoaded, numChannels
	string sweepWaveList = ""
	string sweepWaveName, sweepWaveNameBak, dataPath, componentsDataPath, sweepComponent
	string channelName, channelWaveList

	// we load the backup wave also
	// in case it exists, it holds the original unmodified data
	sweepWaveName    = "sweep_" + num2str(sweep)
	sweepWaveNameBak = sweepWaveName + WAVE_BACKUP_SUFFIX
	sweepWaveList    = AddListItem(sweepWaveList, sweepWaveName, ";", Inf)
	sweepWaveList    = AddListItem(sweepWaveList, sweepWaveNameBak, ";", Inf)

	dataPath = GetDeviceDataPathAsString(device)
	dataPath = AB_TranslatePath(dataPath, expFolder)
	DFREF newDFR = NewFreeDataFolder()
	numWavesLoaded = AB_LoadDataWrapper(newDFR, discLocation, dataPath, sweepWaveList)

	if(numWavesLoaded <= 0)
		printf "Could not load sweep %d of device %s and %s\r", sweep, device, discLocation
		KillOrMoveToTrash(dfr = newDFR)
		KillOrMoveToTrash(dfr = sweepDFR)
		return 1
	endif

	WAVE sweepWave = newDFR:$sweepWaveName
	if(IsTextWave(sweepWave) && DimSize(sweepWave, ROWS) > 0)
		WAVE/Z/T sweepT = newDFR:$sweepWaveNameBak
		if(!WaveExists(sweepT))
			printf "Could not find original sweep wave in pxp (only working copy). Sweep %d of device %s and %s\r", sweep, device, discLocation
			return 1
		endif

		numChannels = DimSize(sweepT, ROWS)
		for(i = 0; i < numChannels; i += 1)
			[componentsDataPath, channelName] = SplitTextSweepElement(sweepT[i])
			sweepT[i] = channelName
		endfor
		channelWaveList = TextWaveToList(sweepT, ";")
		DFREF sweepComponentsDFR = NewFreeDataFolder()
		numComponentsLoaded = AB_LoadDataWrapper(sweepComponentsDFR, discLocation, dataPath + ":" + componentsDataPath, channelWaveList)
		if(numComponentsLoaded != DimSize(sweepT, ROWS))
			printf "Error loading all sweep components. Sweep %d of device %s and %s\r", sweep, device, discLocation
			return 1
		endif

		for(sweepComponent : sweepT)
			WAVE wv = sweepComponentsDFR:$sweepComponent
			MoveWave wv, sweepDFR
		endfor
		RestoreFromBackupWavesForAll(sweepDFR)
	else
		// old sweep format
		if(numWavesLoaded == 2)
			ReplaceWaveWithBackup(sweepWave)
		endif

		MoveWave sweepWave, sweepDFR
		if(AB_SplitSweepIntoComponents(expFolder, device, sweep, sweepWave))
			return 1
		endif
	endif

	return 0
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
	numBefore     = ItemsInList(totalStimsets)

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
		numMoved      += WB_StimsetFamilyNames(totalStimsets, parent = stimset)
	endfor
	numAfter = ItemsInList(totalStimsets)

	// load next order stimsets
	numNewStimsets = numAfter - numBefore + numMoved
	if(numNewStimsets > 0)
		newStimsets = ListFromList(totalStimsets, 0, numNewStimsets - 1)
		oldStimsets = ListFromList(totalStimsets, numNewStimsets, Inf)
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
	variable numWavesLoaded, channelType

	WB_KillParameterWaves(stimset)
	if(overwrite)
		WB_KillStimset(stimset)
	endif

	channelType = GetStimSetType(stimset)

	if(channeltype == CHANNEL_TYPE_UNKNOWN)
		return 1
	endif

	DFREF newDFR = UniqueDataFolder(GetAnalysisFolder(), "temp")
	DFREF setDFR = GetSetFolder(channelType)

	WAVE/Z/SDFR=setDFR wv = $stimset
	if(WaveExists(wv))
		return 0
	endif

	dataPath = GetDataFolder(1, setDFR)
	data     = AddListItem(stimset, "")

	numWavesLoaded = AB_LoadDataWrapper(newDFR, expFilePath, dataPath, data)

	if(numWavesLoaded != 1)
		KillOrMoveToTrash(dfr = newDFR)
		return 1
	endif

	MoveWave newDFR:$stimset, setDFR
	KillOrMoveToTrash(dfr = newDFR)

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

	if(channeltype == CHANNEL_TYPE_UNKNOWN)
		return 1
	endif

	dataPath = GetSetParamFolderAsString(channelType)

	numWavesLoaded = AB_LoadDataWrapper(newDFR, expFilePath, dataPath, parameterWaves)

	if(numWavesLoaded != 3)
		KillOrMoveToTrash(dfr = newDFR)
		return 1
	endif

	// move loaded waves to stimset parameter dataFolder
	WAVE   WP        = newDFR:$(WB_GetParameterWaveName(stimset, STIMSET_PARAM_WP))
	WAVE/T WPT       = newDFR:$(WB_GetParameterWaveName(stimset, STIMSET_PARAM_WPT))
	WAVE   SegWvType = newDFR:$(WB_GetParameterWaveName(stimset, STIMSET_PARAM_SEGWVTYPE))

	DFREF paramDFR = GetSetParamFolder(channelType)

	MoveWave WP, paramDFR
	MoveWave WPT, paramDFR
	MoveWave SegWvType, paramDFR

	KillOrMoveToTrash(dfr = newDFR)

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

	WAVE/T cw = WB_CustomWavesPathFromStimSet(stimsets)

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
		valid   = 1
		stimset = StringFromList(i, stimsets)
		WAVE/T single_cw = WB_CustomWavesPathFromStimSet(stimset)
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
	string   dataFolder
	string loadList = ""

	WAVE/Z wv = $fullPath
	if(overwrite)
		KillOrMoveToTrash(wv = wv)
	endif
	if(WaveExists(wv))
		return 0
	endif

	DFREF newDFR = UniqueDataFolder(GetAnalysisFolder(), "temp")

	dataFolder = GetFolder(fullPath)
	loadList   = AddListItem(RemovePrefix(fullPath, start = dataFolder), loadList)
	if(isEmpty(dataFolder))
		dataFolder = "root:"
	endif
	numWavesLoaded = AB_LoadDataWrapper(newDFR, expFilePath, dataFolder, loadList, recursive = 0)

	if(numWavesLoaded == 0)
		KillOrMoveToTrash(dfr = newDFR)
		KillOrMoveToTrash(dfr = sweepDFR)
		return 1
	endif

	WAVE/SDFR=newDFR wv = $(GetIndexedObjNameDFR(newDFR, COUNTOBJECTS_WAVES, 0))
	createDFWithAllParents(dataFolder)
	MoveWave wv, $fullPath

	KillOrMoveToTrash(dfr = newDFR)

	return 0
End

static Function AB_SplitSweepIntoComponents(expFolder, device, sweep, sweepWave)
	string expFolder, device
	variable sweep
	WAVE     sweepWave

	DFREF sweepFolder = GetAnalysisSweepDataPath(expFolder, device, sweep)
	WAVE  configSweep = GetAnalysisConfigWave(expFolder, device, sweep)

	if(!IsValidSweepAndConfig(sweepWave, configSweep, configVersion = 0))
		printf "The sweep %d of device %s in experiment %s does not match its configuration data. Therefore we ignore it.\r", sweep, device, expFolder
		return 1
	endif

	DFREF dfr = GetAnalysisLabNBFolder(expFolder, device)
	WAVE/SDFR=dfr numericalValues

	SplitAndUpgradeSweep(numericalValues, sweep, sweepWave, configSweep, TTL_RESCALE_ON, 1, targetDFR = sweepFolder)
	KillOrMoveToTrash(wv = sweepWave)

	return 0
End

static Function AB_RemoveExperimentEntry(string win, string entry)

	variable i, size, mapIndex, cnt

	PGC_SetAndActivateControl(win, "button_expand_all", val = 1)

	WAVE/T list = GetExperimentBrowserGUIList()
	WAVE   sel  = GetExperimentBrowserGUISel()

	size = GetNumberFromWaveNote(list, NOTE_INDEX)
	for(i = size - 1; i >= 0; i -= 1)
		if(!CmpStr(list[i][%type][1], entry, 1))
			mapIndex = str2num(list[i][%file][1])
			AB_RemoveMapEntry(mapIndex)
			DeleteWavePoint(list, ROWS, i)
			DeleteWavePoint(sel, ROWS, i)
			cnt += 1
		endif
	endfor
	SetNumberInWaveNote(list, NOTE_INDEX, size - cnt)

	AB_ResetListBoxWaves()
End

static Function AB_AddExperimentEntries(string win, WAVE/T entries)

	string entry, symbPath, fName, nwbFileUsedForExport, panel
	string pxpList, uxpList, nwbList, title
	variable sTime

	nwbFileUsedForExport = ROStr(GetNWBFilePathExport())
	panel                = AB_GetPanelName()

	PGC_SetAndActivateControl(win, "button_expand_all", val = 1)

	sTime = stopMSTimer(-2) * MILLI_TO_ONE + 1
	for(entry : entries)

		if(FolderExists(entry))
			symbPath = GetUniqueSymbolicPath()
			NewPath/O/Q/Z $symbPath, entry
			pxpList = GetAllFilesRecursivelyFromPath(symbPath, extension = ".pxp")
			uxpList = GetAllFilesRecursivelyFromPath(symbPath, extension = ".uxp")
			nwbList = GetAllFilesRecursivelyFromPath(symbPath, extension = ".nwb")
			KillPath/Z $symbPath
			WAVE/T fileList = ListToTextWave(SortList(pxpList + uxpList + nwbList, FILE_LIST_SEP), FILE_LIST_SEP)
		elseif(FileExists(entry))
			Make/FREE/T fileList = {entry}
		else
			printf "AnalysisBrowser: Can not find location %s. Skipped it.\r", entry
			continue
		endif
		for(fName : fileList)

			if(!CmpStr(fName, nwbFileUsedForExport))
				printf "Ignore %s for adding into the analysis browser\ras we currently export data into it!\r", nwbFileUsedForExport
				ControlWindowToFront()
				continue
			endif
			if(sTime < stopMSTimer(-2) * MILLI_TO_ONE)
				sprintf title, "%s, Reading %s", panel, GetFile(fName)
				DoWindow/T $panel, title
				DoUpdate/W=$panel
				sTime = stopMSTimer(-2) * MILLI_TO_ONE + 1
			endif
			AB_AddFile(fName, entry)
		endfor
	endfor
	DoWindow/T $panel, panel

	AB_ResetListBoxWaves()
End

Function/S AB_GetPanelName()

	return ANALYSIS_BROWSER_NAME
End

static Function AB_SetUserData(string key, string value)

	string panel = AB_GetPanelName()

	ASSERT(WindowExists(panel), "AnalysisBrowser is not open.")

	SetWindow $panel, userData($key)=value
End

static Function/S AB_GetUserData(string key)

	string panel = AB_GetPanelName()

	ASSERT(WindowExists(panel), "AnalysisBrowser is not open.")

	return GetUserData(panel, "", key)
End

Function/S AB_OpenAnalysisBrowser([variable restoreSettings])

	variable oldFolderListSize, i
	string workingDF
	string panel = AB_GetPanelName()

	restoreSettings = ParamisDefault(restoreSettings) ? 1 : !!restoreSettings

	if(WindowExists(panel))
		if(HasPanelLatestVersion(panel, ANALYSISBROWSER_PANEL_VERSION))
			DoWindow/F $panel
			return panel
		endif

		KillWindow/Z $panel
	endif

	AB_InitializeAnalysisBrowserWaves()
	AB_RemoveEmptyWorkingDF()

	WAVE/T folderList      = GetAnalysisBrowserGUIFolderList()
	WAVE   folderSelection = GetAnalysisBrowserGUIFolderSelection()
	WAVE   folderColors    = GetAnalysisBrowserGUIFolderColors()
	if(restoreSettings)
		NVAR   JSONid        = $GetSettingsJSONid()
		WAVE/T oldFolderList = JSON_GetTextWave(jsonID, SETTINGS_AB_FOLDER)
		oldFolderListSize = DimSize(oldFolderList, ROWS)
		Redimension/N=(oldFolderListSize, -1, -1) folderList, folderSelection
		folderList[] = oldFolderList[p]
		FastOp folderSelection = 0
	endif

	Execute "AnalysisBrowser()"
	GetMiesVersion()

	AddVersionToPanel(panel, ANALYSISBROWSER_PANEL_VERSION)

	DFREF dfrAB      = GetAnalysisFolder()
	DFREF workingDFR = UniqueDataFolder(dfrAB, AB_WORKFOLDER_NAME)
	workingDF = RemovePrefix(GetDataFolder(1, workingDFR), start = GetDataFolder(1, dfrAB))
	AB_SetUserData(AB_UDATA_WORKINGDF, RemoveEnding(workingDF, ":"))

	ListBox listbox_AB_Folders, win=$panel, listWave=folderList, selWave=folderSelection, colorWave=folderColors

	WAVE/T list = GetExperimentBrowserGUIList()
	WAVE   sel  = GetExperimentBrowserGUISel()
	ListBox list_experiment_contents, win=$panel, listWave=list, selWave=sel

	PS_InitCoordinates(JSONid, panel, "analysisbrowser")
	SetWindow $panel, hook(cleanup)=AB_WindowHook

	if(restoreSettings)
		DoUpdate/W=$panel
		PGC_SetAndActivateControl(panel, "button_AB_refresh")
	endif

	return panel
End

static Function AB_CheckPanelVersion(string panel)

	if(!HasPanelLatestVersion(panel, ANALYSISBROWSER_PANEL_VERSION))
		DoAbortNow("The Analysisbrowser is too old to be usable. Please close it and open a new one.")
	endif
End

Function AB_BrowserStartupSettings()
	string panel

	panel = AB_GetPanelName()

	HideTools/W=$panel/A
	SetWindow $panel, userData(panelVersion)=""
	SetWindow $panel, userData(datafolder)=""

	SetCheckBoxState(panel, "checkbox_load_overwrite", CHECKBOX_UNSELECTED)

	StoreCurrentPanelsResizeInfo(panel)

	SearchForInvalidControlProcs(panel)
	print "Do not forget to increase ANALYSISBROWSER_PANEL_VERSION."

	ListBox list_experiment_contents, win=$panel, listWave=$"", selWave=$"", colorWave=$""
	ListBox listbox_AB_Folders, win=$panel, listWave=$"", selWave=$"", colorWave=$""

	Execute/P/Z "DoWindow/R " + panel
	Execute/P/Q/Z "COMPILEPROCEDURES "
End

/// @brief Button "Expand all"
Function AB_ButtonProc_ExpandAll(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch(ba.eventcode)
		case 2:
			AB_CheckPanelVersion(ba.win)
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
			AB_CheckPanelVersion(ba.win)
			AB_CollapseListColumn(DEVICE_TREEVIEW_COLUMN)
			AB_CollapseListColumn(EXPERIMENT_TREEVIEW_COLUMN)
			break
	endswitch

	return 0
End

/// @brief Button "Load Sweeps"
Function AB_ButtonProc_LoadSweeps(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	variable oneValidSweep
	string   panel

	switch(ba.eventcode)
		case 2:
			AB_CheckPanelVersion(ba.win)

			DFREF dfr = SB_OpenSweepBrowser()
			oneValidSweep = AB_LoadFromFile(AB_LOAD_SWEEP, sweepBrowserDFR = dfr)
			SVAR/SDFR=dfr graph
			if(oneValidSweep)
				AD_Update(graph)
				panel = BSP_GetSweepControlsPanel(graph)
				PGC_SetAndActivateControl(panel, "button_SweepControl_PrevSweep")
				LBV_SelectExperimentAndDevice(graph)
			else
				KillWindow $graph
			endif
			break
	endswitch

	return 0
End

/// @brief Button "Load Both"
Function AB_ButtonProc_LoadBoth(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch(ba.eventcode)
		case 2:
			PGC_SetAndActivateControl(ba.win, "button_load_stimsets")
			PGC_SetAndActivateControl(ba.win, "button_load_sweeps")
	endswitch

	return 0
End

/// @brief Button "Load Stimsets"
Function AB_ButtonProc_LoadStimsets(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	variable oneValidStimset

	switch(ba.eventcode)
		case 2:
			AB_CheckPanelVersion(ba.win)

			oneValidStimset = AB_LoadFromFile(AB_LOAD_STIMSET)
			if(oneValidStimset)
				WBP_CreateWaveBuilderPanel()
			endif
			break
	endswitch

	return 0
End

/// @brief Button "Refresh"
Function AB_ButtonProc_Refresh(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	variable size, index, refreshIndex
	string entry

	switch(ba.eventCode)
		case 2: // mouse up
			AB_CheckPanelVersion(ba.win)

			WAVE/T folderList      = GetAnalysisBrowserGUIFolderList()
			WAVE   folderSelection = GetAnalysisBrowserGUIFolderSelection()
			WAVE/Z indices         = FindIndizes(folderSelection, col = 0, var = 0x1, prop = PROP_MATCHES_VAR_BIT_MASK)
			if(!WaveExists(indices))
				size = DimSize(folderList, ROWS)
				Make/FREE/N=(size) indices
				indices = size - 1 - p
			else
				Sort/R indices, indices
			endif

			Make/FREE/T/N=(DimSize(indices, ROWS)) refreshList

			for(index : indices)
				entry = folderList[index]
				if(!FileExists(entry) && !FolderExists(entry))
					AB_RemoveExperimentEntry(ba.win, folderList[index])
					DeleteWavePoint(folderSelection, ROWS, index)
					DeleteWavePoint(folderList, ROWS, index)
				else
					refreshList[refreshIndex] = entry
					refreshIndex             += 1
				endif
			endfor
			AB_SaveSourceListInSettings()
			Redimension/N=(refreshIndex) refreshList

			for(entry : refreshList)
				AB_RemoveExperimentEntry(ba.win, entry)
			endfor
			Duplicate/FREE/T refreshList, refreshInverted
			refreshInverted = refreshList[refreshIndex - 1 - p]
			AB_AddExperimentEntries(ba.win, refreshInverted)

			AB_UpdateColors()
			break
	endswitch

	return 0
End

/// @brief Button "Open folder(s)"
Function AB_ButtonProc_OpenFolders(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	string symbPath, folder
	variable size, i

	switch(ba.eventCode)
		case 2: // mouse up
			AB_CheckPanelVersion(ba.win)

			WAVE/T folderList      = GetAnalysisBrowserGUIFolderList()
			WAVE   folderSelection = GetAnalysisBrowserGUIFolderSelection()
			size     = DimSize(folderSelection, ROWS)
			symbPath = GetUniqueSymbolicPath()
			for(i = 0; i < size; i += 1)
				if(folderSelection[i] == 1)
					if(FileExists(folderList[i]))
						folder = GetFolder(folderList[i])
					elseif(FolderExists(folderList[i]))
						folder = folderList[i]
					else
						continue
					endif
					NewPath/O/Q/Z $symbPath, folder
					PathInfo/SHOW $symbPath
				endif
			endfor
			KillPath/Z $symbPath
			break
	endswitch

	return 0
End

/// @brief Button "Remove folder(s)"
Function AB_ButtonProc_Remove(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	variable size, i

	switch(ba.eventCode)
		case 2: // mouse up
			AB_CheckPanelVersion(ba.win)

			WAVE/T folderList      = GetAnalysisBrowserGUIFolderList()
			WAVE   folderSelection = GetAnalysisBrowserGUIFolderSelection()
			size = DimSize(folderSelection, ROWS)
			for(i = size - 1; i >= 0; i -= 1)
				if(folderSelection[i] == 1)
					AB_RemoveExperimentEntry(ba.win, folderList[i])
					DeleteWavePoint(folderSelection, ROWS, i)
					DeleteWavePoint(folderList, ROWS, i)
				endif
			endfor
			AB_SaveSourceListInSettings()

			break
	endswitch

	return 0
End

/// @brief Button "Add folder"
/// Display dialog box for choosing a folder and call AB_ScanFolder()
Function AB_ButtonProc_AddFolder(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	string baseFolder, folder
	variable size

	switch(ba.eventCode)
		case 2: // mouse up
			AB_CheckPanelVersion(ba.win)

			NVAR   JSONid        = $GetSettingsJSONid()
			WAVE/T setFolderList = JSON_GetTextWave(jsonID, SETTINGS_AB_FOLDER)
			size = DimSize(setFolderList, ROWS)
			if(size)
				baseFolder = GetFolder(setFolderList[size - 1])
			else
				baseFolder = GetUserDocumentsFolderPath()
			endif
			folder = AskUserForExistingFolder(baseFolder)
			if(IsEmpty(folder))
				break
			endif
			FindValue/TEXT=folder/TXOP=4 setFolderList
			if(V_Value >= 0)
				break
			endif

			AB_AddElementToSourceList(folder)

			Make/FREE/T wFolder = {folder}
			AB_AddExperimentEntries(ba.win, wFolder)
			break
	endswitch

	return 0
End

/// @brief Button "Add files"
/// Display dialog box for choosing files and call AB_AddFolder()
Function AB_ButtonProc_AddFiles(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	string baseFolder, symbPath, fileFilters, fNum, message, fileList
	variable i, size, index

	switch(ba.eventCode)
		case 2: // mouse up
			AB_CheckPanelVersion(ba.win)

			WAVE/T folderList = GetAnalysisBrowserGUIFolderList()
			size = DimSize(folderList, ROWS)
			if(size)
				baseFolder = GetFolder(folderList[size - 1])
			else
				baseFolder = GetUserDocumentsFolderPath()
			endif

			symbPath = GetUniqueSymbolicPath()
			NewPath/O/Q/Z $symbPath, baseFolder

			fileFilters = "Data Files (*.pxp,*.nwb,*.uxp):.pxp,.nwb,.uxp;All Files:.*;"
			message     = "Select data file(s)"
			Open/D/R/MULT=1/F=fileFilters/M=message/P=$symbPath fnum
			fileList = S_fileName
			KillPath/Z $symbPath
			if(IsEmpty(fileList))
				break
			endif
			WAVE/T selFiles = ListToTextWave(fileList, "\r")
			AB_AddFiles(ba.win, selFiles)
			break
	endswitch

	return 0
End

static Function AB_AddFiles(string win, WAVE/T selFiles)

	variable i, index, size

	Duplicate/FREE/T selFiles, newFiles

	WAVE/T folderList = GetAnalysisBrowserGUIFolderList()
	size = DimSize(selFiles, ROWS)
	for(i = 0; i < size; i += 1)
		FindValue/TEXT=selFiles[i]/TXOP=4 folderList
		if(V_Value >= 0)
			continue
		endif
		AB_AddElementToSourceList(selFiles[i])
		newFiles[index] = selFiles[i]
		index          += 1
	endfor
	Redimension/N=(index) newFiles

	AB_AddExperimentEntries(win, newFiles)
End

Function AB_AddElementToSourceList(string entry)

	variable size

	WAVE/T entryList = GetAnalysisBrowserGUIFolderList()
	size = DimSize(entryList, ROWS)
	Redimension/N=(size + 1) entryList
	entryList[size] = entry
	WAVE folderSelection = GetAnalysisBrowserGUIFolderSelection()
	Redimension/N=(size + 1, -1, -1) folderSelection

	AB_SaveSourceListInSettings()
End

static Function AB_SaveSourceListInSettings()

	WAVE/T entryList = GetAnalysisBrowserGUIFolderList()

	Make/FREE/T/N=(DimSize(entryList, ROWS)) setFolderList
	setFolderList[] = entryList[p]
	NVAR JSONid = $GetSettingsJSONid()
	JSON_SetWave(jsonID, SETTINGS_AB_FOLDER, setFolderList)
End

/// @brief Button "Select same stim set sweeps"
Function AB_ButtonProc_SelectStimSets(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	variable numEntries, i
	string selectedStimSet

	switch(ba.eventCode)
		case 2: // mouse up
			AB_CheckPanelVersion(ba.win)

			WAVE/T expBrowserList = GetExperimentBrowserGUIList()
			WAVE   expBrowserSel  = GetExperimentBrowserGUISel()

			WAVE/Z indizes = FindIndizes(expBrowserSel, var = 1)

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

			WAVE indizes = FindIndizes(expBrowserList, colLabel = "stim sets", str = selectedStimSet)
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

	variable mask, numRows, row, col

	switch(lba.eventCode)
		case 5: // cell selection + shift key
		case 4: // cell selection
			AB_CheckPanelVersion(lba.win)
			AB_UpdateColors()
			break

		case 13: // sel wave update
			AB_CheckPanelVersion(lba.win)

			row = lba.row
			col = lba.col

			WAVE/T expBrowserList    = GetExperimentBrowserGUIList()
			WAVE   expBrowserSel     = GetExperimentBrowserGUISel()
			WAVE/T expBrowserListBak = CreateBackupWave(expBrowserList)
			WAVE   expBrowserSelBak  = CreateBackupWave(expBrowserSel)

			numRows = DimSize(expBrowserSel, ROWS)
			if(row < 0 || row >= numRows || col < 0 || col >= DimSize(expBrowserSel, COLS))
				// clicked outside the list
				AB_UpdateColors()
				break
			endif
			mask = expBrowserSel[row][col]
			if(!(mask & LISTBOX_TREEVIEW)) // clicked cell is not a treeview expansion node
				AB_UpdateColors()
				break
			endif

			if(mask & LISTBOX_TREEVIEW_EXPANDED)
				AB_ExpandListEntry(row, col)
			else
				AB_CollapseListEntry(row, col)
			endif
			AB_UpdateColors()

			break
	endswitch

	return 0
End

static Function AB_UpdateColors()

	variable size, index
	string fName

	WAVE/T expBrowserList  = GetExperimentBrowserGUIList()
	WAVE   expBrowserSel   = GetExperimentBrowserGUISel()
	WAVE/T folderList      = GetAnalysisBrowserGUIFolderList()
	WAVE   folderSelection = GetAnalysisBrowserGUIFolderSelection()

	MultiThread folderSelection[][0][%$LISTBOX_LAYER_BACKGROUND] = 0
	size = min(GetNumberFromWaveNote(expBrowserList, NOTE_INDEX), DimSize(expBrowserList, ROWS))
	if(!size)
		return NaN
	endif
	WAVE/Z indizes = FindIndizes(expBrowserSel, col = 0, var = 0x1, prop = PROP_MATCHES_VAR_BIT_MASK, endRow = size - 1)
	if(!WaveExists(indizes))
		return NaN
	endif
	for(index : indizes)
		fName = expBrowserList[index][%type][1]
		if(IsEmpty(fName))
			continue
		endif
		FindValue/TEXT=fName/TXOP=4 folderList
		ASSERT(V_row >= 0, "Source file not found in folderlist")
		folderSelection[V_row][0][%$LISTBOX_LAYER_BACKGROUND] = 2
	endfor
End

/// @brief Button "Open comment NB"
Function AB_ButtonProc_OpenCommentNB(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	variable row, mapIndex
	string device, fileName, dataFolder, discLocation
	string titleString, commentNotebook, comment

	switch(ba.eventCode)
		case 2: // mouse up
			AB_CheckPanelVersion(ba.win)

			WAVE/T expBrowserList = GetExperimentBrowserGUIList()
			WAVE   expBrowserSel  = GetExperimentBrowserGUISel()
			WAVE/T map            = GetAnalysisBrowserMap()

			WAVE/Z indizes = FindIndizes(expBrowserSel, var = 1)

			if(!WaveExists(indizes) || DimSize(indizes, ROWS) != 1)
				print "Please select a sweep belonging to a device to use this feature"
				ControlWindowToFront()
				break
			endif

			row      = indizes[0]
			mapIndex = str2num(expBrowserList[row][%file][1])

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
			NewNoteBook/K=1/F=0/OPTS=(2^2 + 2^3)/N=$commentNotebook/W=(0, 0, 300, 400) as titleString
			ReplaceNotebookText(commentNotebook, comment)
			break
	endswitch

	return 0
End

Function AB_ButtonProc_ResaveAsNWB(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	variable row, i, index, overwrite
	string fileType, discLocation, experiment, win

	switch(ba.eventCode)
		case 2: // mouse up
			win = ba.win
			AB_CheckPanelVersion(ba.win)
			WAVE/T map = GetAnalysisBrowserMap()

			index = GetNumberFromWaveNote(map, NOTE_INDEX)

			if(!index)
				printf "No experiments loaded, aborting.\r"
				ControlWindowToFront()
				break
			endif

			overwrite = GetCheckBoxState(win, "checkbox_load_overwrite")

			for(i = 0; i < index; i += 1)
				experiment   = map[i][%FileName]
				fileType     = map[i][%FileType]
				discLocation = map[i][%DiscLocation]

				if(cmpstr(fileType, ANALYSISBROWSER_FILE_TYPE_NWBv1))
					printf "Skipping %s: Resaving to NWBv2 only works for NWBv1 files.\r", experiment
					ControlWindowToFront()
					continue
				endif

				AB_ReExport(i, overwrite)
			endfor
			break
	endswitch
End

static Function AB_LoadAllSweepsAndStimsets(string discLocation, string dataFolder, string fileType, string device)

	variable i, sweep, numEntries

	// load all sweeps and stimsets
	WAVE/Z sweeps = GetAnalysisChannelSweepWave(dataFolder, device)

	if(!WaveExists(sweeps))
		return NaN
	endif

	numEntries = DimSize(sweeps, ROWS)
	for(i = 0; i < numEntries; i += 1)
		sweep = sweeps[i]

		if(!IsValidSweepNumber(sweep))
			continue
		endif

		AB_LoadStimsetFromFile(discLocation, dataFolder, fileType, device, sweep, overwrite = 1)
		AB_LoadSweepFromFile(discLocation, dataFolder, fileType, device, sweep, overwrite = 1)
	endfor
End

static Function AB_ReExport(variable index, variable overwrite)

	string fileName, discLocation, dataFolder, experiment, path, name, suffix
	string folder, devices, device, list, fileType
	variable numDevices, i, j, numEntries, sweep, ret

	WAVE/T map = GetAnalysisBrowserMap()

	fileType     = map[index][%FileType]
	discLocation = map[index][%DiscLocation]
	dataFolder   = map[index][%DataFolder]
	experiment   = map[index][%FileName]

	// Iterate over all devices
	devices    = AB_GetAllDevicesForExperiment(dataFolder)
	numDevices = ItemsInList(devices)

	for(i = 0; i < numDevices; i += 1)
		device = StringFromList(i, devices)

		// load all sweeps and stimsets into the analysis browser
		AB_LoadAllSweepsAndStimsets(discLocation, dataFolder, fileType, device)

		// load stored testpulses
		AB_LoadStoredTestpulsesFromNWB(discLocation, dataFolder, device)

		// Move HardwareDevices out of the way
		path = GetDAQDevicesFolderAsString()
		RenameDataFolderToUniqueName(path, "_old")

		// Move LabNoteBook out of the way
		path = GetLabNotebookFolderAsString()
		RenameDataFolderToUniqueName(path, "_old")

		// Move NWB out of the way
		path = GetNWBFolderAS()
		RenameDataFolderToUniqueName(path, "_old")

		// Create folders
		DFREF dfr = GetDeviceDataPath(device)
		DFREF dfr = GetDeviceTestPulse(device)
		DFREF dfr = GetLabNotebookFolder()
		DFREF dfr = GetDevSpecLabNBFolder(device)

		// Copy labnotebooks
		// root:MIES:Analysis:HardwareTests_compressed_V1_example:ITC18USB_Dev_0:labnotebook:
		// ↓
		// root:MIES:LabNoteBook:ITC18USB:Device0:
		DFREF source = GetAnalysisLabNBFolder(dataFolder, device)
		path = GetDevSpecLabNBFolderAsString(device)
		path = path + "::" + GetFile(path)
		DuplicateDataFolder/O=2 source, $path

		// Copy TPStorage and StoredTestPulses waves
		// root:MIES:Analysis:HardwareTests_compressed_V1_example:ITC18USB_Dev_0:testpulse:
		// ↓
		// root:MIES:HardwareDevices:ITC18USB:Device0:TestPulse:
		DFREF source = GetAnalysisDeviceTestPulse(dataFolder, device)
		path = GetDeviceTestPulseAsString(device) + "::"
		DuplicateDataFolder/O=2 source, $path

		// Copy DAQConfig waves
		// root:MIES:Analysis:HardwareTests_compressed_V1_example:ITC18USB_Dev_0:config:
		// ↓
		// root:MIES:HardwareDevices:ITC18USB:Device0:Data:
		DFREF source = GetAnalysisDeviceConfigFolder(dataFolder, device)
		path = GetDeviceDataPathAsString(device)
		path = path + "::" + GetFile(path)
		DuplicateDataFolder/O=2 source, $path

		// Copy sweeps
		// root:MIES:Analysis:HardwareTests_compressed_V1_example:ITC18USB_Dev_0:sweep:
		// ↓
		// root:MIES:HardwareDevices:ITC18USB:Device0:Data:
		DFREF source = GetAnalysisSweepPath(dataFolder, device)
		path = GetDeviceDataPathAsString(device)
		path = path + "::" + GetFile(path)
		DuplicateDataFolder/O=2 source, $path

		// Mock deviceID for GetAllDevices
		NVAR deviceID = $GetDAQDeviceID(device)

		DFREF dfr = GetDeviceDataPath(device)

		if(!IsDataFolderEmpty(dfr))
			// Copy reconstructed 2D sweep waves
			// Because we only have 1D sweep waves from the NWB file
			RecreateMissingSweepAndConfigWaves(device, dfr)
			//
			// root:reconstructed
			// ↓
			// root:MIES:HardwareDevices:ITC18USB:Device0:Data:
			DFREF source = root:reconstructed
			path = GetDeviceDataPathAsString(device)
			path = path + "::" + GetFile(path)
			DuplicateDataFolder/O=2 source, $path
		endif

		// Place history in override location
		DFREF source = GetAnalysisDeviceFolder(dataFolder, device)
		SVAR/Z/SDFR=source historyAndLogFile
		if(SVAR_Exists(historyAndLogFile))
			SVAR overrideHistoryAndLogFile = $GetNwbOverrideHistoryAndLogFile()
			overrideHistoryAndLogFile = historyAndLogFile
		endif

		// Now export all that data into NWBv2
		suffix = "." + GetFileSuffix(discLocation)
		name   = GetFile(discLocation)
		sprintf name, "%s%s-converted%s", RemoveEnding(name, suffix), SelectString(numDevices > 1, "", "-" + device), suffix
		path = GetFolder(discLocation) + name

		ret = NWB_ExportAllData(NWB_VERSION_LATEST, overrideFilePath = path, writeStoredTestPulses = 1, overwrite = overwrite)

		if(!ret)
			printf "####\r"
			printf "Folder: %s\r", GetWindowsPath(GetFolder(discLocation))
			printf "NWbv1: %s\r", GetFile(discLocation)
			printf "NWbv2 (new): %s\r", GetFile(path)
			printf "####\r"
		endif
	endfor
End

/// @brief Load dropped NWB files into the analysis browser
static Function BeforeFileOpenHook(refNum, file, pathName, type, creator, kind)
	variable refNum, kind
	string file, pathName, type, creator
	string baseFolder, fileSuffix, entry
	variable numEntries

	LOG_AddEntry(PACKAGE_MIES, "start")

	fileSuffix = GetFileSuffix(file)
	if(cmpstr(fileSuffix, "nwb"))
		LOG_AddEntry(PACKAGE_MIES, "end")
		return 0
	endif

	Pathinfo $pathName
	baseFolder = S_path

	AB_OpenAnalysisBrowser(restoreSettings = 0)
	// we can not add files to the map if some entries are collapsed
	// so we have to expand all first.
	PGC_SetAndActivateControl("AnalysisBrowser", "button_expand_all", val = 1)

	entry = basefolder + file
	if(AB_AddFile(entry, entry))
		// already loaded or error
		LOG_AddEntry(PACKAGE_MIES, "end")
		return 1
	endif
	AB_AddElementToSourceList(entry)

	AB_ResetListBoxWaves()

	LOG_AddEntry(PACKAGE_MIES, "end")

	return 1
End

Function/S AB_GetAllDevicesForExperiment(string dataFolder)

	DFREF dfr = GetAnalysisExpFolder(dataFolder)

	return GetListOfObjects(dfr, ".*", typeFlag = COUNTOBJECTS_DATAFOLDER)
End

/// @brief Return all experiments the analysis browser knows about
Function/S AB_GetAllExperiments()

	variable i, index
	string list = ""

	WAVE/T map = GetAnalysisBrowserMap()
	index = GetNumberFromWaveNote(map, NOTE_INDEX)

	for(i = 0; i < index; i += 1)
		list = AddListItem(map[i][%DataFolder], list, ";", Inf)
	endfor

	return list
End

/// @brief Get stimset list either by analysing dataFolder of loaded sweep or if device is empty, get all stimsets
///
/// numericalValues and textualValues are generated from previously loaded data.
/// used in the context of loading from a stored experiment file.
/// on load a sweep is stored in a device/dataFolder hierarchy.
///
/// @returns list of stimsets
Function/S AB_GetStimsetList(string fileType, string discLocation, string dataFolder, string device, variable sweep)

	if(IsEmpty(device))
		strswitch(fileType)
			case ANALYSISBROWSER_FILE_TYPE_IGOR:
				return AB_GetStimsetListFromIgorFile(discLocation)
			case ANALYSISBROWSER_FILE_TYPE_NWBv1:
			case ANALYSISBROWSER_FILE_TYPE_NWBv2:
				return NWB_ReadStimSetList(discLocation)
			default:
				ASSERT(0, "fileType not handled")
		endswitch
	endif

	DFREF dfr = GetAnalysisLabNBFolder(dataFolder, device)
	WAVE/SDFR=dfr   numericalValues
	WAVE/SDFR=dfr/T textualValues

	return AB_GetStimsetFromSweepGeneric(sweep, numericalValues, textualValues)
End

/// @brief Get related Stimsets by corresponding sweep
///
/// input numerical and textual values storage waves for current sweep
///
/// @returns list of stimsets
static Function/S AB_GetStimsetFromSweepGeneric(sweep, numericalValues, textualValues)
	variable sweep
	WAVE     numericalValues
	WAVE/T   textualValues

	variable i, j, numEntries
	string ttlList, name
	string stimsetList = ""

	WAVE/Z/T stimsets = GetLastSetting(textualValues, sweep, STIM_WAVE_NAME_KEY, DATA_ACQUISITION_MODE)
	if(!WaveExists(stimsets))
		return ""
	endif

	// handle AD/DA channels
	for(i = 0; i < NUM_HEADSTAGES; i += 1)
		name = stimsets[i]
		if(isEmpty(name))
			continue
		endif
		stimsetList = AddListItem(name, stimsetList)
	endfor

	WAVE/Z/T ttlStimSets = GetTTLLabnotebookEntry(textualValues, LABNOTEBOOK_TTL_STIMSETS, sweep)

	// handle TTL channels
	for(i = 0; i < NUM_DA_TTL_CHANNELS; i += 1)

		if(!WaveExists(ttlStimsets))
			break
		endif

		name = ttlStimSets[i]
		if(isEmpty(name))
			continue
		endif
		stimsetList = AddListItem(name, stimsetList)
	endfor

	return stimsetList
End

/// @brief Get stimsets by analysing currently loaded sweep
///
/// numericalValues and textualValues are generated from device
///
/// @returns list of stimsets
Function/S AB_GetStimsetFromPanel(device, sweep)
	string   device
	variable sweep

	WAVE   numericalValues = GetLBNumericalValues(device)
	WAVE/T textualValues   = GetLBTextualValues(device)

	return AB_GetStimsetFromSweepGeneric(sweep, numericalValues, textualValues)
End

Function AB_WindowHook(s)
	STRUCT WMWinHookStruct &s

	switch(s.eventCode)
		case EVENT_WINDOW_HOOK_KILL:

			AB_MemoryFreeMappedDF()
			AB_RemoveEmptyWorkingDF()

			break
	endswitch

	// return zero so that other hooks are called as well
	return 0
End

static Function AB_MemoryFreeMappedDF()

	variable i, size

	WAVE/T map = GetAnalysisBrowserMap()
	size = GetNumberFromWaveNote(map, NOTE_INDEX)
	for(i = 0; i < size; i += 1)
		AB_RemoveMapEntry(i)
	endfor
End
