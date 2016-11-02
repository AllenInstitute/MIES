/*	XOPSupport.h

	Declares routines, global variables and other items needed to use XOPSupport routines.
*/

#ifdef __cplusplus
extern "C" {						// This allows C++ to call the XOPSupport routines.
#endif

// Global variables used by XOPSupport.c.
extern IORecHandle XOPRecHandle;
extern int XOPModified;
extern int igorVersion;

// NaN represents a missing value.

#ifdef MACIGOR
	// NAN is defined as a macro in math.h.
	#define SINGLE_NAN ((float)NAN)			// The evaluates to a NaN represented as 0x7FC00000
	#define DOUBLE_NAN ((double)NAN)		// The evaluates to a NaN represented as 0x7FF8000000000000
#endif

#ifdef WINIGOR
	/*	Visual C++ does not define the NAN macro. In XOP Toolkit 6.31 this was changed to
		produce the same NaN as on Macintosh. Previously it produced 0x7FFFFFFFFFFFFFFF for
		double-precision and 0xFFFFFFFF for single-precision. This change makes it consistent
		with Macintosh and with the Visual C++ numeric_limits<double>::quiet_NaN() function.
	*/
	static unsigned char DOUBLE_NAN_BYTES[] = {0x00,0x00,0x00,0x00,0x00,0x00,0xF8,0x7F};
	#define DOUBLE_NAN *(double*)DOUBLE_NAN_BYTES
	static unsigned char SINGLE_NAN_BYTES[] = {0x00,0x00,0xC0,0x7F};
	#define SINGLE_NAN *(float*)SINGLE_NAN_BYTES
#endif

/*	"Private" routines.
	The XOPSupport files use these to call Igor. You should not call them directly.
*/
XOPIORecResult CallBack0(int message);
XOPIORecResult CallBack1(int message, void* item0);
XOPIORecResult CallBack2(int message, void* item0, void* item1);
XOPIORecResult CallBack3(int message, void* item0, void* item1, void* item2);
XOPIORecResult CallBack4(int message, void* item0, void* item1, void* item2, void* item3);
XOPIORecResult CallBack5(int message, void* item0, void* item1, void* item2, void* item3, void* item4);
XOPIORecResult CallBack6(int message, void* item0, void* item1, void* item2, void* item3, void* item4, void* item5);
XOPIORecResult CallBack7(int message, void* item0, void* item1, void* item2, void* item3, void* item4, void* item5, void* item6);
XOPIORecResult CallBack8(int message, void* item0, void* item1, void* item2, void* item3, void* item4, void* item5, void* item6, void* item7);

// Notice Routines (in XOPSupport.c).
void XOPNotice(const char* noticePtr);
void XOPNotice2(const char* noticePtr, UInt32 options);
void XOPNotice3(const char *noticePtr, const char* rulerName, UInt32 options);
void XOPResNotice(int strListID, int index);

// Utility routines (in XOPSupport.c).
int CmpStr(const char* str1, const char* str2);
const char* strchr2(const char* str, int ch);
const char* strrchr2(const char* str, int ch);
int EscapeSpecialCharacters(const char* input, int inputLength, char* output, int outputBufferSize, int* numCharsOutPtr);
int UnEscapeSpecialCharacters(const char* input, int inputLength, char* output, int outputBufferSize, int* numCharsOutPtr);
int ConvertTextEncoding(const char* source, int numSourceBytes, WMTextEncodingCode sourceTextEncoding, char* dest, int destBufSizeInBytes, WMTextEncodingCode destTextEncoding, WMTextEncodingConversionErrorMode errorMode, WMTextEncodingConversionOptions options, int* numOutputBytesPtr);
void MemClear(void* p, BCInt n);
int GetCStringFromHandle(Handle h, char* str, int maxChars);
int PutCStringInHandle(const char* str, Handle h);
int CheckAbort(TickCountInt timeOutTicks);
int IsNaN32(float* floatPtr);
int IsNaN64(double* doublePtr);
void SetNaN32(float* fPtr);
void SetNaN64(double* dPtr);
int IsINF32(float* floatPtr);
int IsINF64(double* doublePtr);
void XOPInit(IORecHandle ioRecHandle);
int RunningInMainThread(void);
int CheckRunningInMainThread(const char* routineName);
void SetXOPType(int type);
void SetXOPEntry(void (*entryPoint)(void));
void SetXOPResult(XOPIORecResult result);
XOPIORecResult GetXOPResult(void);
void SetXOPMessage(int message);
int GetXOPMessage(void);
int GetXOPStatus(void);
XOPIORecParam GetXOPItem(int itemNumber);
void IgorError(const char* title, int errCode);
int GetIgorErrorMessage(int errCode, char errorMessage[256]);
int WinInfo(int index, int typeMask, char* name, IgorWindowRef* windowRefPtr);

// Numeric conversion utilities (in XOPNumericConversion.c).
#define SIGNED_INT 1
#define UNSIGNED_INT 2
#define IEEE_FLOAT 3

void DoubleToFloat(const double* inPtr, float* outPtr, CountInt numValues);
void DoubleToSInt64(const double* inPtr, SInt64* outPtr, CountInt numValues);
void DoubleToSInt32(const double* inPtr, SInt32* outPtr, CountInt numValues);
void DoubleToShort(const double* inPtr, short* outPtr, CountInt numValues);
void DoubleToByte(const double* inPtr, char* outPtr, CountInt numValues);
void DoubleToUInt64(const double* inPtr, UInt64* outPtr, CountInt numValues);
void DoubleToUInt32(const double* inPtr, UInt32* outPtr, CountInt numValues);
void DoubleToUnsignedShort(const double* inPtr, unsigned short* outPtr, CountInt numValues);
void DoubleToUnsignedByte(const double* inPtr, unsigned char* outPtr, CountInt numValues);
int ConvertDouble(const double* src, void* dest, CountInt numValues, int destFormat, int destBytes);

void FloatToDouble(const float* inPtr, double* outPtr, CountInt numValues);
void FloatToSInt64(const float* inPtr, SInt64* outPtr, CountInt numValues);
void FloatToSInt32(const float* inPtr, SInt32* outPtr, CountInt numValues);
void FloatToShort(const float* inPtr, short* outPtr, CountInt numValues);
void FloatToByte(const float* inPtr, char* outPtr, CountInt numValues);
void FloatToUInt64(const float* inPtr, UInt64* outPtr, CountInt numValues);
void FloatToUInt32(const float* inPtr, UInt32* outPtr, CountInt numValues);
void FloatToUnsignedShort(const float* inPtr, unsigned short* outPtr, CountInt numValues);
void FloatToUnsignedByte(const float* inPtr, unsigned char* outPtr, CountInt numValues);
int ConvertFloat(const float* src, void* dest, CountInt numValues, int destFormat, int destBytes);

void SInt64ToDouble(const SInt64* inPtr, double* outPtr, CountInt numValues);
void SInt64ToFloat(const SInt64* inPtr, float* outPtr, CountInt numValues);
void SInt64ToSInt32(const SInt64* inPtr, SInt32* outPtr, CountInt numValues);
void SInt64ToShort(const SInt64* inPtr, short* outPtr, CountInt numValues);
void SInt64ToByte(const SInt64* inPtr, char* outPtr, CountInt numValues);
void WMSInt64ToUInt64(const SInt64* inPtr, UInt64* outPtr, CountInt numValues);	// SInt64ToUInt64 conflicts with an Apple macro
void SInt64ToUInt32(const SInt64* inPtr, UInt32* outPtr, CountInt numValues);
void SInt64ToUnsignedShort(const SInt64* inPtr, unsigned short* outPtr, CountInt numValues);
void SInt64ToUnsignedByte(const SInt64* inPtr, unsigned char* outPtr, CountInt numValues);
int ConvertSInt64(const SInt64* src, void* dest, CountInt numValues, int destFormat, int destBytes);

void SInt32ToDouble(const SInt32* inPtr, double* outPtr, CountInt numValues);
void SInt32ToFloat(const SInt32* inPtr, float* outPtr, CountInt numValues);
void SInt32ToSInt64(const SInt32* inPtr, SInt64* outPtr, CountInt numValues);
void SInt32ToShort(const SInt32* inPtr, short* outPtr, CountInt numValues);
void SInt32ToByte(const SInt32* inPtr, char* outPtr, CountInt numValues);
void SInt32ToUInt64(const SInt32* inPtr, UInt64* outPtr, CountInt numValues);
void SInt32ToUInt32(const SInt32* inPtr, UInt32* outPtr, CountInt numValues);
void SInt32ToUnsignedShort(const SInt32* inPtr, unsigned short* outPtr, CountInt numValues);
void SInt32ToUnsignedByte(const SInt32* inPtr, unsigned char* outPtr, CountInt numValues);
int ConvertSInt32(const SInt32* src, void* dest, CountInt numValues, int destFormat, int destBytes);

void ShortToDouble(const short* inPtr, double* outPtr, CountInt numValues);
void ShortToFloat(const short* inPtr, float* outPtr, CountInt numValues);
void ShortToSInt64(const short* inPtr, SInt64* outPtr, CountInt numValues);
void ShortToSInt32(const short* inPtr, SInt32* outPtr, CountInt numValues);
void ShortToByte(const short* inPtr, char* outPtr, CountInt numValues);
void ShortToUInt64(const short* inPtr, UInt64* outPtr, CountInt numValues);
void ShortToUInt32(const short* inPtr, UInt32* outPtr, CountInt numValues);
void ShortToUnsignedShort(const short* inPtr, unsigned short* outPtr, CountInt numValues);
void ShortToUnsignedByte(const short* inPtr, unsigned char* outPtr, CountInt numValues);
int ConvertShort(const short* src, void* dest, CountInt numValues, int destFormat, int destBytes);

void ByteToDouble(const char* inPtr, double* outPtr, CountInt numValues);
void ByteToFloat(const char* inPtr, float* outPtr, CountInt numValues);
void ByteToSInt64(const char* inPtr, SInt64* outPtr, CountInt numValues);
void ByteToSInt32(const char* inPtr, SInt32* outPtr, CountInt numValues);
void ByteToShort(const char* inPtr, short* outPtr, CountInt numValues);
void ByteToUInt64(const char* inPtr, UInt64* outPtr, CountInt numValues);
void ByteToUInt32(const char* inPtr, UInt32* outPtr, CountInt numValues);
void ByteToUnsignedShort(const char* inPtr, unsigned short* outPtr, CountInt numValues);
void ByteToUnsignedByte(const char* inPtr, unsigned char* outPtr, CountInt numValues);
int ConvertByte(const char* src, void* dest, CountInt numValues, int destFormat, int destBytes);

void UInt64ToDouble(const UInt64* inPtr, double* outPtr, CountInt numValues);
void UInt64ToFloat(const UInt64* inPtr, float* outPtr, CountInt numValues);
void WMUInt64ToSInt64(const UInt64* inPtr, SInt64* outPtr, CountInt numValues);	// UInt64ToSInt64 conflicts with an Apple macro
void UInt64ToSInt32(const UInt64* inPtr, SInt32* outPtr, CountInt numValues);
void UInt64ToShort(const UInt64* inPtr, short* outPtr, CountInt numValues);
void UInt64ToByte(const UInt64* inPtr, char* outPtr, CountInt numValues);
void UInt64ToUInt32(const UInt64* inPtr, UInt32* outPtr, CountInt numValues);
void UInt64ToUnsignedShort(const UInt64* inPtr, unsigned short* outPtr, CountInt numValues);
void UInt64ToUnsignedByte(const UInt64* inPtr, unsigned char* outPtr, CountInt numValues);
int ConvertUInt64(const UInt64* src, void* dest, CountInt numValues, int destFormat, int destBytes);

void UInt32ToDouble(const UInt32* inPtr, double* outPtr, CountInt numValues);
void UInt32ToFloat(const UInt32* inPtr, float* outPtr, CountInt numValues);
void UInt32ToSInt64(const UInt32* inPtr, SInt64* outPtr, CountInt numValues);
void UInt32ToSInt32(const UInt32* inPtr, SInt32* outPtr, CountInt numValues);
void UInt32ToShort(const UInt32* inPtr, short* outPtr, CountInt numValues);
void UInt32ToByte(const UInt32* inPtr, char* outPtr, CountInt numValues);
void UInt32ToUInt64(const UInt32* inPtr, UInt64* outPtr, CountInt numValues);
void UInt32ToUnsignedShort(const UInt32* inPtr, unsigned short* outPtr, CountInt numValues);
void UInt32ToUnsignedByte(const UInt32* inPtr, unsigned char* outPtr, CountInt numValues);
int ConvertUInt32(const UInt32* src, void* dest, CountInt numValues, int destFormat, int destBytes);

void UnsignedShortToDouble(const unsigned short* inPtr, double* outPtr, CountInt numValues);
void UnsignedShortToFloat(const unsigned short* inPtr, float* outPtr, CountInt numValues);
void UnsignedShortToSInt64(const unsigned short* inPtr, SInt64* outPtr, CountInt numValues);
void UnsignedShortToSInt32(const unsigned short* inPtr, SInt32* outPtr, CountInt numValues);
void UnsignedShortToShort(const unsigned short* inPtr, short* outPtr, CountInt numValues);
void UnsignedShortToByte(const unsigned short* inPtr, char* outPtr, CountInt numValues);
void UnsignedShortToUInt64(const unsigned short* inPtr, UInt64* outPtr, CountInt numValues);
void UnsignedShortToUInt32(const unsigned short* inPtr, UInt32* outPtr, CountInt numValues);
void UnsignedShortToUnsignedByte(const unsigned short* inPtr, unsigned char* outPtr, CountInt numValues);
int ConvertUnsignedShort(const unsigned short* src, void* dest, CountInt numValues, int destFormat, int destBytes);

void UnsignedByteToDouble(const unsigned char* inPtr, double* outPtr, CountInt numValues);
void UnsignedByteToFloat(const unsigned char* outPtr, float* fPtr, CountInt numValues);
void UnsignedByteToSInt64(const unsigned char* inPtr, SInt64* outPtr, CountInt numValues);
void UnsignedByteToSInt32(const unsigned char* inPtr, SInt32* outPtr, CountInt numValues);
void UnsignedByteToShort(const unsigned char* inPtr, short* outPtr, CountInt numValues);
void UnsignedByteToByte(const unsigned char* inPtr, char* outPtr, CountInt numValues);
void UnsignedByteToUInt64(const unsigned char* inPtr, UInt64* outPtr, CountInt numValues);
void UnsignedByteToUInt32(const unsigned char* inPtr, UInt32* outPtr, CountInt numValues);
void UnsignedByteToUnsignedShort(const unsigned char* inPtr, unsigned short* outPtr, CountInt numValues);
int ConvertUnsignedByte(const unsigned char* src, void* dest, CountInt numValues, int destFormat, int destBytes);

int NumTypeToNumBytesAndFormat(int numType, int* numBytesPerPointPtr, int* dataFormatPtr, int* isComplexPtr);
int NumBytesAndFormatToNumType(int numBytesPerValue, int dataFormat, int* numTypePtr);
void FixByteOrder(void* p, int bytesPerPoint, CountInt count);
int ConvertData(const void* src, void* dest, CountInt numValues, int srcBytes, int srcFormat, int destBytes, int destFormat);
int ConvertData2(const void* src, void* dest, CountInt numValues, int srcDataType, int destDataType);

void ScaleDouble(double* dPtr, double* offset, double* multiplier, CountInt numValues);
void ScaleFloat(float* fPtr, double* offset, double* multiplier, CountInt numValues);
void ScaleSInt64(SInt64* iPtr, double* offset, double* multiplier, CountInt numValues);
void ScaleSInt32(SInt32* iPtr, double* offset, double* multiplier, CountInt numValues);
void ScaleShort(short* iPtr, double* offset, double* multiplier, CountInt numValues);
void ScaleByte(char* iPtr, double* offset, double* multiplier, CountInt numValues);
void ScaleUInt64(UInt64* iPtr, double* offset, double* multiplier, CountInt numValues);
void ScaleUInt32(UInt32* iPtr, double* offset, double* multiplier, CountInt numValues);
void ScaleUnsignedShort(unsigned short* iPtr, double* offset, double* multiplier, CountInt numValues);
void ScaleUnsignedByte(unsigned char* iPtr, double* offset, double* multiplier, CountInt numValues);
void ScaleData(int dataType, void* dataPtr, double* offsetPtr, double* multiplierPtr, CountInt numValues);
void ScaleClipAndRoundData(int dataType, void* dataPtr, CountInt numValues, double offset, double multiplier, double dMin, double dMax, int doRound);

// Wave access routines (in XOPWaveAccess.c).
int FetchNumericValue(int type, const char* dataStartPtr, IndexInt index, double value[2]);
int StoreNumericValue(int type, char* dataStartPtr, IndexInt index, double value[2]);
void WaveHandleModified(waveHndl waveHandle);
// WaveHandlesModified is obsolete and was removed from XOP Toolkit 6. Use WaveHandleModified.
void WaveModified(const char* waveName);
waveHndl FetchWave(const char* waveName);
waveHndl FetchWaveFromDataFolder(DataFolderHandle dataFolderH, const char* waveName);
int WaveType(waveHndl waveHandle);
CountInt WavePoints(waveHndl waveHandle);
void WaveName(waveHndl waveHandle, char* namePtr);
void* WaveData(waveHndl waveHandle);
void WaveScaling(waveHndl waveHandle, double* hsAPtr, double* hsBPtr, double* topPtr, double* botPtr);
void SetWaveScaling(waveHndl waveHandle, const double* hsAPtr, const double* hsBPtr, const double* topPtr, const double* botPtr);
void WaveUnits(waveHndl waveHandle, char* xUnits, char* dataUnits);
void SetWaveUnits(waveHndl waveHandle, const char* xUnits, const char* dataUnits);
// Handle WaveNote(waveHndl waveHandle);			// Support for WaveNote was removed in XOP Toolkit 7. See WaveNoteCopy.
Handle WaveNoteCopy(waveHndl waveHandle);			// Added for Igor Pro 7.00 but works with any version. 
void SetWaveNote(waveHndl waveHandle, Handle noteHandle);
TickCountInt WaveModDate(waveHndl waveH);
int WaveLock(waveHndl waveH);
int SetWaveLock(waveHndl waveH, int lockState);
int WaveModState(waveHndl waveH);
int WaveModCount(waveHndl waveH);
int MakeWave(waveHndl* waveHandlePtr, const char* waveName, CountInt numPoints, int type, int overwrite);
int ChangeWave(waveHndl waveHandle, CountInt numPoints, int type);
int KillWave(waveHndl waveHandle);
int WaveTextEncoding(waveHndl waveHandle, int element, int getEffectiveTextEncoding, int* tecPtr);
BCInt WaveMemorySize(waveHndl waveH, int which);

// Data folder access routines (in XOPDataFolderAccess.c).
int GetDataFolderNameOrPath(DataFolderHandle dataFolderH, int flags, char dataFolderPathOrName[MAXCMDLEN+1]);
int GetDataFolderIDNumber(DataFolderHandle dataFolderH, int* IDNumberPtr);
int GetDataFolderProperties(DataFolderHandle dataFolderH, int* propertiesPtr);
int SetDataFolderProperties(DataFolderHandle dataFolderH, int properties);
int GetDataFolderListing(DataFolderHandle dataFolderH, int optionsFlag, Handle h);
int GetRootDataFolder(int refNum, DataFolderHandle* rootFolderHPtr);
int GetCurrentDataFolder(DataFolderHandle* currentFolderHPtr);
int SetCurrentDataFolder(DataFolderHandle dataFolderH);
int GetNamedDataFolder(DataFolderHandle startingDataFolderH, const char dataFolderPath[MAXCMDLEN+1], DataFolderHandle* dataFolderHPtr);
int GetDataFolderByIDNumber(int IDNumber, DataFolderHandle* dataFolderHPtr);
int GetParentDataFolder(DataFolderHandle dataFolderH, DataFolderHandle* parentFolderHPtr);
int GetNumChildDataFolders(DataFolderHandle parentDataFolderH, int* numChildDataFolderPtr);
int GetIndexedChildDataFolder(DataFolderHandle parentDataFolderH, int index, DataFolderHandle* childDataFolderHPtr);
int GetWavesDataFolder(waveHndl waveH, DataFolderHandle* dataFolderHPtr);
int NewDataFolder(DataFolderHandle parentFolderH, const char newDataFolderName[MAX_OBJ_NAME+1], DataFolderHandle* newDataFolderHPtr);
int KillDataFolder(DataFolderHandle dataFolderH);
int DuplicateDataFolder(DataFolderHandle sourceDataFolderH, DataFolderHandle parentDataFolderH, const char newDataFolderName[MAX_OBJ_NAME+1]);
int MoveDataFolder(DataFolderHandle sourceDataFolderH, DataFolderHandle newParentDataFolderH);
int RenameDataFolder(DataFolderHandle dataFolderH, const char newName[MAX_OBJ_NAME+1]);
int GetNumDataFolderObjects(DataFolderHandle dataFolderH, int objectType, int* numObjectsPtr);
int GetIndexedDataFolderObject(DataFolderHandle dataFolderH, int objectType, int index, char objectName[MAX_OBJ_NAME+1], DataObjectValuePtr objectValuePtr);
int GetDataFolderObject(DataFolderHandle dataFolderH, const char objectName[MAX_OBJ_NAME+1], int* objectTypePtr, DataObjectValuePtr objectValuePtr);
int SetDataFolderObject(DataFolderHandle dataFolderH, const char objectName[MAX_OBJ_NAME+1], int objectType, DataObjectValuePtr objectValuePtr);
int KillDataFolderObject(DataFolderHandle dataFolderH, int objectType, const char objectName[MAX_OBJ_NAME+1]);
int MoveDataFolderObject(DataFolderHandle sourceDataFolderH, int objectType, const char objectName[MAX_OBJ_NAME+1], DataFolderHandle destDataFolderH);
int RenameDataFolderObject(DataFolderHandle dataFolderH, int objectType, const char objectName[MAX_OBJ_NAME+1], const char newObjectName[MAX_OBJ_NAME+1]);
int DuplicateDataFolderObject(DataFolderHandle dataFolderH, int objectType, const char objectName[MAX_OBJ_NAME+1], DataFolderHandle destFolderH, const char newObjectName[MAX_OBJ_NAME+1], int overwrite);
void ClearDataFolderFlags(void);
int GetDataFolderChangesCount(void);
int GetDataFolderChangeFlags(DataFolderHandle dataFolderH, int* flagsP);
int HoldDataFolder(DataFolderHandle dfH);			// Added for Igor Pro 6.20. Second parameter removed in XOP Toolkit 6.30.
int ReleaseDataFolder(DataFolderHandle* dfRefPtr);	// Added for Igor Pro 6.20.

// Multi-dimension wave access routines (in XOPWaveAccess.c).
int MDMakeWave(waveHndl* waveHPtr, const char* waveName, DataFolderHandle dataFolderH, CountInt dimSizes[MAX_DIMENSIONS+1], int type, int overwrite);
int MDGetWaveDimensions(waveHndl waveH, int* numDimensionsPtr, CountInt dimSizes[MAX_DIMENSIONS+1]);
int MDChangeWave(waveHndl waveH, int dataType, CountInt dimSizes[MAX_DIMENSIONS+1]);
int MDChangeWave2(waveHndl waveH, int dataType, CountInt dimSizes[MAX_DIMENSIONS+1], int mode);
int MDGetWaveScaling(waveHndl waveH, int dimension, double* sfA, double* sfB);
int MDSetWaveScaling(waveHndl waveH, int dimension, const double* sfA, const double* sfB);
int MDGetWaveUnits(waveHndl waveH, int dimension, char units[MAX_UNIT_CHARS+1]);
int MDSetWaveUnits(waveHndl waveH, int dimension, const char units[MAX_UNIT_CHARS+1]);
int MDGetDimensionLabel(waveHndl waveH, int dimension, IndexInt element, char label[MAX_DIM_LABEL_CHARS+1]);
int MDSetDimensionLabel(waveHndl waveH, int dimension, IndexInt element, const char label[MAX_DIM_LABEL_CHARS+1]);
int MDAccessNumericWaveData(waveHndl waveH, int accessMode, BCInt* dataOffsetPtr);
int MDGetNumericWavePointValue(waveHndl waveH, IndexInt indices[MAX_DIMENSIONS], double value[2]);
int MDSetNumericWavePointValue(waveHndl waveH, IndexInt indices[MAX_DIMENSIONS], double value[2]);
int MDGetDPDataFromNumericWave(waveHndl waveH, double* dPtr);
int MDStoreDPDataInNumericWave(waveHndl waveH, const double* dPtr);
int MDGetTextWavePointValue(waveHndl waveH, IndexInt indices[MAX_DIMENSIONS], Handle textH);
int MDSetTextWavePointValue(waveHndl waveH, IndexInt indices[MAX_DIMENSIONS], Handle textH);

// Command line routines (in XOPSupport.c).
int XOPCommand(const char* cmdPtr);
int XOPSilentCommand(const char* cmdPtr);
int XOPCommand2(const char *cmdPtr, int silent, int sendToHistory);
int XOPCommand3(const char *cmdPtr, int silent, int sendToHistory, Handle* historyTextHPtr);
void PutCmdLine(const char* cmd, int mode);
void FinishDialogCmd(const char* cmd, int mode);

// Variable access routines (in XOPSupport.c).
int FetchNumVar(const char* varName, double* doublePtr1, double* doublePtr2);
int StoreNumVar(const char* varName, const double* doublePtr1, const double* doublePtr2);
int FetchStrVar(const char* varName, char* stringPtr);
Handle FetchStrHandle(const char* varName);
int StoreStrVar(const char* varName, const char* stringPtr);
int Variable(const char* varName, int varType);
int VariableList(Handle listHandle, const char* match, const char* sep, int varTypeCode);
int StringList(Handle listHandle, const char* match, const char* sep);
int SetIgorIntVar(const char* numVarName, int value, int forceGlobal);
int SetIgorFloatingVar(const char* numVarName, const double* valuePtr, int forceGlobal);
int SetIgorComplexVar(const char* numVarName, const double* realValuePtr, const double* imagValuePtr, int forceGlobal);
int SetIgorStringVar(const char* stringVarName, const char* stringVarValue, int forceGlobal);

// Name utilities (in XOPSupport.c).
int UniqueName(const char* baseName, char* finalName);
int UniqueName2(int nameSpaceCode, const char* baseName, char* finalName, int* suffixNumPtr);
int SanitizeWaveName(char* waveName, int column);
int CheckName(DataFolderHandle dataFolderH, int objectType, const char* name);
int PossiblyQuoteName(char* name);
void CatPossiblyQuotedName(char* str, const char* name);
int CleanupName(int beLiberal, char* name, int maxNameChars);
int CreateValidDataObjectName(DataFolderHandle dataFolderH, const char* inName, char* outName, int* suffixNumPtr, int objectType, int beLiberal, int allowOverwrite, int inNameIsBaseName, int printMessage, int* nameChangedPtr, int* doOverwritePtr);

// Igor thread support (in XOPSupport.c).
int ThreadProcessorCount(void);																	// Added for Igor Pro 6.23B01.
int ThreadGroupPutDF(int threadGroupID, DataFolderHandle dataFolderH);							// Added for Igor Pro 6.23B01.
int ThreadGroupGetDF(int threadGroupID, int waitMilliseconds, DataFolderHandle* dataFolderHPtr);// Added for Igor Pro 6.23B01.

// Utilities for XOPs with menu items (in XOPMenus.c).
typedef void* XOPMenuRef;															// Replaces MenuHandle
XOPMenuRef XOPActualMenuIDToMenuRef(int actualMenuID);								// Replaces GetMenuHandle
XOPMenuRef XOPResourceMenuIDToMenuRef(int resourceMenuID);							// Replaces ResourceMenuIDToMenuHandle
int XOPGetMenuInfo(XOPMenuRef menuRef, int* menuID, char* menuTitle, int* isVisible, void* reserved1, void* reserved2);	// Replaces GetMenuID
int XOPCountMenuItems(XOPMenuRef menuRef);											// Replaces CountMItems
int XOPShowMainMenu(XOPMenuRef menuRef, int beforeMenuID);							// Replaces WMInsertMenu followed by WMDrawMenuBar
int XOPHideMainMenu(XOPMenuRef menuRef);											// Replaces WMDeleteMenu followed by WMDrawMenuBar
int XOPGetMenuItemInfo(XOPMenuRef menuRef, int itemNumber, int* enabled, int* checked, void* reserved1, void* reserved2);	// Requires Igor Pro 6.32 or later
int XOPGetMenuItemText(XOPMenuRef menuRef, int itemNumber, char text[256]);			// Replaces getmenuitemtext
int XOPSetMenuItemText(XOPMenuRef menuRef, int itemNumber, const char* text);		// Replaces setmenuitemtext
int XOPAppendMenuItem(XOPMenuRef menuRef, const char* text);						// Replaces appendmenu
int XOPInsertMenuItem(XOPMenuRef menuRef, int afterItemNumber, const char* text);	// Replaces insertmenuitem
int XOPDeleteMenuItem(XOPMenuRef menuRef, int itemNumber);							// Replaces DeleteMenuItem
int XOPDeleteMenuItemRange(XOPMenuRef menuRef, int first, int last);				// Replaces WMDeleteMenuItems
int XOPEnableMenuItem(XOPMenuRef menuRef, int itemNumber);							// Replaces EnableItem
int XOPDisableMenuItem(XOPMenuRef menuRef, int itemNumber);							// Replaces DisableItem
int XOPCheckMenuItem(XOPMenuRef menuRef, int itemNumber, int state);				// Replaces CheckItem
int XOPFillMenu(XOPMenuRef menuRef, int afterItemNumber, const char* itemList);
int XOPFillMenuNoMeta(XOPMenuRef menuRef, int afterItemNumber, const char* itemList);
int XOPFillWaveMenu(XOPMenuRef menuRef, const char* match, const char* options, int afterItemNumber);
int XOPFillPathMenu(XOPMenuRef menuRef, const char* match, const char* options, int afterItemNumber);
int XOPFillWinMenu(XOPMenuRef menuRef, const char* match, const char* options, int afterItemNumber);
int	ResourceToActualMenuID(int resourceMenuID);
int	ActualToResourceMenuID(int menuID);
int ActualToResourceItem(int igorMenuID, int actualItemNumber);
int ResourceToActualItem(int igorMenuID, int resourceItemNumber);
int SetIgorMenuItem(int message, int enable, const char* text, int param);

// Utilities for XOPs with windows (in XOPWindows.c). These require Igor Pro 7 or later.
int CreateXOPWindow(int units, const double coords[4], const char* title, int options, IgorWindowRef* xopWindowRefPtr);
int KillXOPWindow(IgorWindowRef xopWindowRef);
int GetIgorWindowInfo(IgorWindowRef windowRef, IgorWindowInfoType which, void** infoPtr);
int SetXOPWindowInfo(IgorWindowRef xopWindowRef, IgorWindowInfoType which, void* info);
IgorWindowRef GetActiveIgorWindow(void);
IgorWindowRef GetNamedIgorWindow(const char* name);
IgorWindowRef GetIndexedXOPWindow(int index);
IgorWindowRef GetNextXOPWindow(IgorWindowRef xopWindowRef, int visibleOnly);
int IsIgorWindowActive(IgorWindowRef windowRef);
int IsIgorWindowVisible(IgorWindowRef windowRef);
void ShowIgorWindow(IgorWindowRef windowRef);
void HideIgorWindow(IgorWindowRef windowRef);
void ShowAndActivateIgorWindow(IgorWindowRef windowRef);
void HideAndDeactivateIgorWindow(IgorWindowRef windowRef);
void GetIgorWindowTitle(IgorWindowRef windowRef, char title[256]);
void SetIgorWindowTitle(IgorWindowRef windowRef, const char* title);
void GetIgorWindowPositionAndState(IgorWindowRef windowRef, Rect* r, int* winStatePtr);
void SetIgorWindowPositionAndState(IgorWindowRef windowRef, const Rect* r, int winState);
void TransformWindowCoordinates(int mode, double coords[4]);
void GetIgorWindowIgorPositionAndState(IgorWindowRef windowRef, double coords[4], int* winStatePtr);
void SetIgorWindowIgorPositionAndState(IgorWindowRef windowRef, double coords[4], int winState);

// Igor Window Content Container routines (in XOPContainers.c). These require Igor Pro 7 or later.
int CreateXOPContainer(IgorWindowRef windowRef, IgorContainerRef parentContainer, int units, const double coords[4], const char frameGuides[4][MAX_OBJ_NAME+1], const char* proposedName, const char* baseName, int options, IgorContainerRef* xopContainerPtrPtr);
int KillXOPContainer(IgorContainerRef xopContainer);
void ActivateXOPContainer(IgorContainerRef xopContainer);
int GetActiveIgorContainer(IgorWindowRef windowRef, IgorContainerRef* containerPtr);
int GetNamedIgorContainer(const char* path, int mask, IgorContainerRef* containerPtr);
int GetParentIgorContainer(IgorContainerRef container, IgorContainerRef* containerPtr);
int GetChildIgorContainer(IgorContainerRef container, int index, IgorContainerRef* containerPtr);
int GetIndexedXOPContainer(IgorWindowRef windowRef, int index, IgorContainerRef* xopContainerPtr);
int GetIgorContainerPath(IgorContainerRef container, IgorContainerRef ancestor, char path[MAX_LONG_NAME+1]);
int GetIgorContainerInfo(IgorContainerRef container, IgorContainerInfoType which, void** infoPtr);
int SetIgorContainerInfo(IgorContainerRef container, IgorContainerInfoType which, void* info);
#ifdef MACIGOR
	int SendContainerNSEventToIgor(IgorContainerRef xopContainer, int message, const void* nsView, const void* nsEvent);
#endif
#ifdef WINIGOR
	int SendContainerHWNDEventToIgor(IgorContainerRef xopContainer, int message, HWND hwnd, UInt32 iMsg, PSInt wParam, PSInt lParam);
#endif
int SetXOPContainerMouseCursor(IgorContainerRef xopContainer, enum IgorMouseCursorCode mouseCursorCode);

// Utilities for XOPs with text windows (in XOPTextUtilityWindows.c).
int TUNew2(const char* winTitle, const Rect* winRectPtr, Handle* TUPtr, IgorWindowRef* windowRefPtr);
void TUDispose(TUStuffHandle TU);
void TUDisplaySelection(TUStuffHandle TU);
void TUGrow(TUStuffHandle TU, int size);
void TUDrawWindow(TUStuffHandle TU);
void TUUpdate(TUStuffHandle TU);
void TUFind(TUStuffHandle TU, int messageCode);
void TUReplace(TUStuffHandle TU);
void TUIndentLeft(TUStuffHandle TU);
void TUIndentRight(TUStuffHandle TU);
void TUClick(TUStuffHandle TU, WMMouseEventRecord* eventPtr);
void TUActivate(TUStuffHandle TU, int flag);
void TUIdle(TUStuffHandle TU);
void TUNull(TUStuffHandle TU, WMMouseEventRecord* merP);
void TUCopy(TUStuffHandle TU);
void TUCut(TUStuffHandle TU);
void TUPaste(TUStuffHandle TU);
void TUClear(TUStuffHandle TU);
void TUKey(TUStuffHandle TU, WMKeyboardEventRecord* eventPtr);
void TUInsert(TUStuffHandle TU, const char* dataPtr, int dataLen);
void TUDelete(TUStuffHandle TU);
void TUSelectAll(TUStuffHandle TU);
void TUUndo(TUStuffHandle TU);
void TUPrint(TUStuffHandle TU);
void TUFixEditMenu(TUStuffHandle TU);
void TUFixFileMenu(TUStuffHandle TU);
int TULines(TUStuffHandle TU);
int TUSFInsertFile(TUStuffHandle TU, const char* prompt, OSType fileTypes[], int numTypes);
int TUSFWriteFile(TUStuffHandle TU, const char* prompt, OSType fileType, int allFlag);
void TUPageSetupDialog(TUStuffHandle TU);
int TUGetDocInfo(TUStuffHandle TU, TUDocInfoPtr dip);
int TUGetSelLocs(TUStuffHandle TU, TULocPtr startLocPtr, TULocPtr endLocPtr);
int TUSetSelLocs(TUStuffHandle TU, TULocPtr startLocPtr, TULocPtr endLocPtr, int flags);
int TUFetchParagraphText(TUStuffHandle TU, int paragraph,  Ptr* textPtrPtr, int* lengthPtr);
int TUFetchSelectedText(TUStuffHandle TU, Handle* textHandlePtr, void* reservedForFuture, int flags);
int TUFetchText2(TUStuffHandle TU, TULocPtr startLocPtr, TULocPtr endLocPtr, Handle* textHandlePtr, void* reservedForFuture, int flags);
int TUSetStatusArea(TUStuffHandle TU, const char* message, int eraseFlags, int statusAreaWidth);
void TUMoveToPreferredPosition(TUStuffHandle TU);
void TUMoveToFullSizePosition(TUStuffHandle TU);
void TURetrieveWindow(TUStuffHandle TU);

// Utilities for accessing the history area
void HistoryDisplaySelection(void);
void HistoryInsert(const char* dataPtr, int dataLen);
void HistoryDelete(void);
int HistoryLines(void);
int HistoryGetSelLocs(TULocPtr startLocPtr, TULocPtr endLocPtr);
int HistorySetSelLocs(TULocPtr startLocPtr, TULocPtr endLocPtr, int flags);
int HistoryFetchParagraphText(int paragraph,  Ptr* textPtrPtr, int* lengthPtr);
int HistoryFetchText(TULocPtr startLocPtr, TULocPtr endLocPtr, Handle* textHPtr);

// Cross-platform dialog routines (in XOPDialogsMac.c and XOPDialogsWin.c)
void XOPEmergencyAlert(const char* message);
void XOPOKAlert(const char* title, const char* message);
int XOPOKCancelAlert(const char* title, const char* message);
int XOPYesNoAlert(const char* title, const char* message);
int XOPYesNoCancelAlert(const char* title, const char* message);
int XOPOpenFileDialog(const char* prompt, const char* fileFilterStr, int* fileIndexPtr, const char* initialDir, char filePath[MAX_PATH_LEN+1]);
int XOPOpenFileDialog2(int flagsIn, const char* prompt, const char* fileFilterStr, int* fileIndexPtr, const char* initialDir, const char* initialFile, int* flagsOutPtr, char fullPathOut[MAX_PATH_LEN+1]);
int XOPSaveFileDialog(const char* prompt, const char* fileFilterStr, int* fileIndexPtr, const char* initialDir, const char* defaultExtensionStr, char filePath[MAX_PATH_LEN+1]);
int XOPSaveFileDialog2(int flagsIn, const char* prompt, const char* fileFilterStr, int* fileIndexPtr, const char* initialDir, const char* initialFile, int* flagsOutPtr, char fullPathOut[MAX_PATH_LEN+1]);

// Windows dialog-related routines (in XOPDialogsWin.c).
#ifdef WINIGOR
	void PositionWinDialogWindow(HWND theDialog, HWND refWindow);
#endif

// Macintosh file-related routines (in XOPFilesMac.c).
#ifdef MACIGOR
	int HFSToPosixPath(const char* hfsPath, char posixPath[MAX_PATH_LEN+1], int isDirectory);
#endif

// Cross-platform file handling routines (in XOPFiles.c).
int XOPCreateFile(const char* fullFilePath, int overwrite, int macCreator, int macFileType);
int XOPDeleteFile(const char* fullFilePath);
int XOPOpenFile(const char* fullFilePath, int readOrWrite, XOP_FILE_REF* fileRefPtr);
int XOPCloseFile(XOP_FILE_REF fileRef);
int XOPReadFile(XOP_FILE_REF fileRef, UInt32 count, void* buffer, UInt32* numBytesReadPtr);
int XOPReadFile2(XOP_FILE_REF fileRef, UInt32 count, void* buffer, UInt32* numBytesReadPtr);
int XOPReadFile64(XOP_FILE_REF fileRef, SInt64 count, void* buffer, SInt64* numBytesReadPtr);
int XOPWriteFile(XOP_FILE_REF fileRef, UInt32 count, const void* buffer, UInt32* numBytesWrittenPtr);
int XOPWriteFile64(XOP_FILE_REF fileRef, SInt64 count, const void* buffer, SInt64* numBytesWrittenPtr);
int XOPGetFilePosition(XOP_FILE_REF fileRef, UInt32* filePosPtr);
int XOPSetFilePosition(XOP_FILE_REF fileRef, SInt32 filePos, int mode);
int XOPGetFilePosition2(XOP_FILE_REF fileRef, SInt64* dFilePosPtr);
int XOPSetFilePosition2(XOP_FILE_REF fileRef, SInt64 dFilePos);
int XOPAtEndOfFile(XOP_FILE_REF fileRef);
int XOPNumberOfBytesInFile(XOP_FILE_REF fileRef, UInt32* numBytesPtr);
int XOPNumberOfBytesInFile2(XOP_FILE_REF fileRef, SInt64* dNumBytesPtr);
int XOPReadLine(XOP_FILE_REF fileRef, char* buffer, UInt32 bufferLength, UInt32* numBytesReadPtr);
int FullPathPointsToFile(const char* fullPath);
int FullPathPointsToFolder(const char* fullPath);
int WinToMacPath(char path[MAX_PATH_LEN+1]);
int MacToWinPath(char path[MAX_PATH_LEN+1]);
int GetNativePath(const char* filePathIn, char filePathOut[MAX_PATH_LEN+1]);
int EscapeBackslashesInUNCVolumeName(char macFilePath[MAX_PATH_LEN+1]);
int GetDirectoryAndFileNameFromFullPath(const char* fullFilePath, char dirPath[MAX_PATH_LEN+1], char fileName[MAX_FILENAME_LEN+1]);
int GetLeafName(const char* filePath, char name[MAX_FILENAME_LEN+1]);
int GetFullPathFromSymbolicPathAndFilePath(const char* symbolicPathName, const char filePath[MAX_PATH_LEN+1], char fullFilePath[MAX_PATH_LEN+1]);
int ConcatenatePaths(const char* pathIn1, const char* nameOrPathIn2, char pathOut[MAX_PATH_LEN+1]);
int ParseFilePath(int mode, const char* pathIn, const char* separator, int whichEnd, int whichElement, char pathOut[MAX_PATH_LEN+1]);	// Added for Igor Pro 6.20B03
int SpecialDirPath(const char* pathID, int domain, int flags, int createDir, char pathOut[MAX_PATH_LEN+1]);								// Added for Igor Pro 6.20B03

// File loader utilities (in XOPFiles.c).
int FileLoaderMakeWave(int column, char* waveName, CountInt numPoints, int fileLoaderFlags, waveHndl* waveHandlePtr);
int SetFileLoaderOutputVariables(const char* fileNameOrPath, int numWavesLoaded, const char* waveNames);
int SetFileLoaderOperationOutputVariables(int runningInUserFunction, const char* fileNameOrPath, int numWavesLoaded, const char* waveNames);

// Data loading and saving utilities for internal WaveMetrics use only (used by WaveMetrics Browser). (In XOPFiles.c).
struct LoadDataInfo;		// GNU C requires this.
struct LoadFileInfo;		// GNU C requires this.
struct SaveDataInfo;		// GNU C requires this.
int PrepareLoadIgorData(struct LoadDataInfo* ldiPtr, int* refNumPtr, struct LoadFileInfo*** topFIHPtr);
int LoadIgorData(struct LoadDataInfo* ldiPtr, int refNum, struct LoadFileInfo** topFIH, DataFolderHandle destDataFolderH);
int EndLoadIgorData(struct LoadDataInfo* ldiPtr, int refNum, struct LoadFileInfo** topFIH);
int SaveIgorData(struct SaveDataInfo* sdiPtr, DataFolderHandle topDataFolderH);

// IGOR color table routines (in XOPSupport.c).
int GetIndexedIgorColorTableName(int index, char name[MAX_OBJ_NAME+1]);
int GetNamedIgorColorTableHandle(const char* name, IgorColorTableHandle* ictHPtr);
int GetIgorColorTableInfo(IgorColorTableHandle ictH, char name[MAX_OBJ_NAME+1], int* numColorsPtr);
int GetIgorColorTableValues(IgorColorTableHandle ictH, int startColorIndex, int endColorIndex, int updatePixelValues, IgorColorSpec* csPtr);

// Cross-Platform Utilities (in XOPSupport.c).
void WinRectToMacRect(const RECT* wr, Rect* mr);
void MacRectToWinRect(const Rect *mr, RECT *wr);
int XOPGetClipboardData(OSType dataType, int options, Handle* hPtr, BCInt* lengthPtr);	// Added in Igor Pro 7.00.
int XOPSetClipboardData(OSType dataType, int options, void* data, BCInt length);		// Added in Igor Pro 7.00.

// Miscellaneous routines (in XOPSupport.c).
void XOPBeep(void);
void GetXOPIndString(char* text, int strID, int index);
void ArrowCursor(void);
void WatchCursor(void);
int SpinProcess(void);
int DoUpdate(void);
void PauseUpdate(int* savePtr);
void ResumeUpdate(int* savePtr);
int WaveList(Handle listHandle, const char* match, const char* sep, const char* options);
int WinList(Handle listHandle, const char* match, const char* sep, const char* options);
int PathList(Handle listHandle, const char* match, const char* sep, const char* options);
int GetPathInfo2(const char* pathName, char fullDirPath[MAX_PATH_LEN+1]);
struct NamedFIFO** GetNamedFIFO(const char* name);
void MarkFIFOUpdated(struct NamedFIFO** fifo);
int SaveXOPPrefsHandle(Handle prefsHandle);
int GetXOPPrefsHandle(Handle* prefsHandlePtr);
int GetPrefsState(int* prefsStatePtr);
int XOPDisplayHelpTopic(const char* title, const char* topicStr, int flags);
enum CloseWinAction DoWindowRecreationDialog(char* procedureName);
int GetIgorProcedureList(Handle* hPtr, int flags);
int GetIgorProcedure(const char* procedureName, Handle* hPtr, int flags);
int SetIgorProcedure(const char* procedureName, Handle h, int flags);
int XOPSetContextualHelpMessage(IgorWindowRef theWindow, const char* message, const Rect* r);

int GetFunctionInfo(const char* name, FunctionInfoPtr fip);
int CheckFunctionForm(struct FunctionInfo* fip, int requiredNumParameters, int requiredParameterTypes[], int* badParameterNumberPtr, int returnType);
int CallFunction(struct FunctionInfo* fip, void* parameters, void* resultPtr);
int GetFunctionInfoFromFuncRef(FUNCREF fref, FunctionInfoPtr fip);
int GetIgorCallerInfo(char pathOrTitle[MAX_PATH_LEN+1], int* linePtr, char routineName[256], Handle* callStackHPtr);
int GetIgorRTStackInfo(int code, Handle* stackInfoHPtr);	// Added for Igor Pro 6.02B01.

int RegisterOperation(const char* cmdTemplate, const char* runtimeNumVarList, const char* runtimeStrVarList, int runtimeParamStructSize, const void* runtimeAddress, int options);
int SetOperationNumVar(const char* varName, double dval);
int SetOperationStrVar(const char* varName, const char* str);
int SetOperationStrVar2(const char* varName, const char* data, BCInt dataLength);				// Added for Igor Pro 6.10B02.
int VarNameToDataType(const char* varName, int* dataTypePtr);
int FetchNumericDataUsingVarName(const char* varName, double* realPartPtr, double* imagPartPtr);// Added for Igor Pro 6.10.
int StoreNumericDataUsingVarName(const char* varName, double realPart, double imagPart);
int FetchStringDataUsingVarName(const char* varName, Handle* hPtr);								// Added for Igor Pro 6.10.
int StoreStringDataUsingVarName(const char* varName, const char* buf, BCInt len);
int GetOperationWaveRef(DataFolderHandle dfH, const char* name, int destWaveRefIdentifier, waveHndl* destWaveHPtr);	// Added in Igor Pro 6.20
int GetOperationDestWave(DataFolderHandle dfH, const char* name, int destWaveRefIdentifier, int options, CountInt dimensionSizes[], int dataType, waveHndl* destWaveHPtr, int* destWaveCreatedPtr);	// Added in Igor Pro 6.20
int SetOperationWaveRef(waveHndl waveH, int waveRefIndentifier);
int CalcWaveRange(WaveRangeRecPtr wrp);
int HoldWave(waveHndl waveH);				// Added for Igor Pro 6.20. Second parameter removed in XOP Toolkit 6.30.
int ReleaseWave(waveHndl* waveRefPtr);		// Added for Igor Pro 6.20.

int DateToIgorDateInSeconds(CountInt numValues, short* year, short* month, short* dayOfMonth, double* secs);
int IgorDateInSecondsToDate(CountInt numValues, double* secs, short* dates);

int GetNVAR(const NVARRec* nvp, double* realPartPtr, double* imagPartPtr, int* numTypePtr);
int SetNVAR(const NVARRec* nvp, const double* realPartPtr, const double* imagPartPtr);
int GetSVAR(const SVARRec* nvp, Handle* strHPtr);
int SetSVAR(const SVARRec* nvp, Handle strH);

int GetTextWaveData(waveHndl waveH, int mode, Handle* textDataHPtr);
int SetTextWaveData(waveHndl waveH, int mode, Handle textDataH);
int GetWaveDimensionLabels(waveHndl waveH, Handle dimLabelsHArray[MAX_DIMENSIONS]);
int SetWaveDimensionLabels(waveHndl waveH, Handle dimLabelsHArray[MAX_DIMENSIONS]);

#ifdef __cplusplus
}
#endif
