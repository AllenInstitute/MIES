/*	XOPWaveAccess.c
	
	Routines for Igor XOPs that provide access to multi-dimensional waves.
*/

#include "XOPStandardHeaders.h"			// Include ANSI headers, Mac headers, IgorXOP.h, XOP.h and XOPSupport.h

/*	ABOUT WAVE ACCESS
	
	Waves are stored in handles that contain a wave header structure followed by the wave data.
	Routines in this file provide access to wave properties and wave data.
	
	When running with Igor6 or earlier, some of these routines access the structure directly
	while others call back to Igor.
	
	When running with Igor7 or later, all calls call back to Igor. This is because the internal
	Igor structures were changed in Igor7 and providing direct access to the Igor7 structure
	would restrict WaveMetrics' ability to change it.
*/

#define MAXDIMS1 4					// Maximum dimensions in wave struct version 3.

/*	All Igor versions must have a version field in the internal wave structure so that
	the XOP Toolkit can determine the structure version. In IGOR32 this field is at offset
	26. In IGOR64 it is at offset 64.
	
	Igor3 through Igor6 used the same internal wave structure. The version field has the
	value 1. Some routines in this file are able to directly access the wave structure.
	
	In Igor7 the internal wave structure was changed. The version field has the value 2.
	Routines in this file can not directly access this wave structure and so they must
	call back to Igor.
*/
#define kWaveStruct3Version 1
#ifdef IGOR64
	#define WAVE_VERSION(waveH) (*(short*)((char*)*waveH+34))
#else
	#define WAVE_VERSION(waveH) (*(short*)((char*)*waveH+26))
#endif

/*	*** Wave Access Routines *** */

/*	WaveHandleModified(waveH)

	WaveHandleModified does a callBack to Igor to notify it that the specified
	wave has been modified.
	
	Thread Safety: WaveHandleModified is Igor-thread-safe with XOP Toolkit 6 and Igor Pro 6.20 or later
	except for waves passed to threads as parameters. You can call it from a thread created
	by Igor but not from a private thread that you created yourself.
*/
void
WaveHandleModified(waveHndl waveH)
{
	CallBack1(WAVEMODIFIED, waveH);
}

// WaveHandlesModified has been removed. Use WaveHandleModified.

/*	WaveModified(waveName)

	WaveModified() does a callBack to Igor to notify it that the specified wave
	has been modified. It ASSUMES that waveName is the name of a valid wave.
	
	Thread Safety: WaveModified is Igor-thread-safe with XOP Toolkit 6 and Igor Pro 6.20 or later
	except for waves passed to threads as parameters. You can call it from a thread created
	by Igor but not from a private thread that you created yourself.
*/
void
WaveModified(const char *waveName)
{
	CallBack1(WAVEMODIFIED, FetchWave(waveName));
}

/*	FetchWave(waveName)

	FetchWave returns a handle to the data structure for the specified wave
	or NULL if the wave does not exist.
	
	Thread Safety: FetchWave is Igor-thread-safe with XOP Toolkit 6 and Igor Pro 6.20 or later.
	You can call it from a thread created by Igor but not from a private thread that you created yourself.
*/
waveHndl
FetchWave(const char *waveName)
{
	waveHndl waveH;
	
	waveH = (waveHndl)CallBack1(FETCHWAVE, (void*)waveName);
	return(waveH);
}

/*	FetchWaveFromDataFolder(dataFolderH, waveName)

	FetchWaveFromDataFolder returns a handle to the data structure for the
	specified wave in the specified data folder or NULL if the wave does not exist.

	If dataFolderH is NULL, it uses the current data folder.
	
	Thread Safety: FetchWaveFromDataFolder is thread-safe with Igor Pro 6.20 or later.
	You can call it from a thread created by Igor but not from a private thread that you created yourself.
*/
waveHndl
FetchWaveFromDataFolder(DataFolderHandle dataFolderH, const char* waveName)
{
	waveHndl waveH;
	
	waveH = (waveHndl)CallBack2(FETCHWAVE_FROM_DATAFOLDER, dataFolderH, (void*)waveName);
	return(waveH);
}

/*	WaveType(waveH)

	Returns wave type which is:
		NT_FP32, NT_FP64 for single or double precision floating point
		NT_I8, NT_I16, NT_I32, NT_I64 for 8, 16, 32 or 64 bit signed integer
	This is ORed with NT_COMPLEX if the wave is complex
	and ORed with NT_UNSIGNED if the wave is unsigned integer.
	
	64-bit integer waves (NT_I64) were added in Igor Pro 7.00.
	
	The wave type can also be one of the following:
		TEXT_WAVE_TYPE			text wave
		WAVE_TYPE				wave wave - holds wave references
		DATAFOLDER_TYPE			DFREF wave - holds data folder references
	These types of waves can not be complex.
	
	Note: Future versions may support other wave types.
		  Always check the wave type to make sure it is a type you can handle.
	
	Thread Safety: WaveType is Igor-thread-safe with XOP Toolkit 6 and Igor Pro 6.20 or later
	except for waves passed to threads as parameters. You can call it from a thread created
	by Igor but not from a private thread that you created yourself.
*/
int
WaveType(waveHndl waveH)
{
	switch(WAVE_VERSION(waveH)) {
		case kWaveStruct3Version:		// type field
			#ifdef IGOR64
				return (*(short*)((char*)*waveH+24));
			#else
				return (*(short*)((char*)*waveH+16));
			#endif
			break;
		
		default:		/* Future version of Igor with a different wave structure. */
			return (int)CallBack1(WAVETYPE, waveH);
			break;
	}
}

/*	WavePoints(waveH)

	Returns number of points in wave.
	
	For multi-dimensional waves, WavePoints returns the total number of
	points in all dimensions.
	
	Thread Safety: WavePoints is Igor-thread-safe with XOP Toolkit 6 and Igor Pro 6.20 or later
	except for waves passed to threads as parameters. You can call it from a thread created
	by Igor but not from a private thread that you created yourself.
*/
CountInt
WavePoints(waveHndl waveH)
{
	switch(WAVE_VERSION(waveH)) {
		case kWaveStruct3Version:		// npnts field
			#ifdef IGOR64
				return (*(CountInt*)((char*)*waveH+16));
			#else
				return (*(CountInt*)((char*)*waveH+12));
			#endif
			break;
		
		default:		/* Future version of Igor with a different wave structure. */
			return (CountInt)CallBack1(WAVEPOINTS, waveH);
			break;
	}
}

/*	WaveName(waveH, namePtr)

	Returns name of the wave via namePtr.
	
	Thread Safety: WaveName is Igor-thread-safe with XOP Toolkit 6 and Igor Pro 6.20 or later
	except for waves passed to threads as parameters. You can call it from a thread created
	by Igor but not from a private thread that you created yourself.
*/
void
WaveName(waveHndl waveH, char name[MAX_OBJ_NAME+1])
{
	CallBack2(WAVENAME, waveH, name);
}

/*	WaveData(waveH)

	Returns pointer to start of wave's data.
	
	WARNING: Do not use WaveData to access a text wave.
	
	Thread Safety: WaveData is Igor-thread-safe with XOP Toolkit 6 and Igor Pro 6.20 or later
	except for waves passed to threads as parameters. You can call it from a thread created
	by Igor but not from a private thread that you created yourself.
*/
void*
WaveData(waveHndl waveH)
{
	switch(WAVE_VERSION(waveH)) {
		case kWaveStruct3Version:		// Address of wData field
			#ifdef IGOR64
				return (void*)((char*)*waveH+400);
			#else
				return (void*)((char*)*waveH+320);
			#endif
			break;
		
		default:		/* Future version of Igor with a different wave structure. */
			return (void*)CallBack1(WAVEDATA, waveH);
			break;
	}
}

/*	WaveScaling(waveH, hsAPtr, hsBPtr, topPtr, botPtr)

	Returns the wave's X and Y scaling information.
	
	hsA and hsB define the transformation from point number to X value where
	  X value = hsA*Point# + hsB.
	  
	top and bottom are the values that the user entered for the wave's Y Full Scale.
	If both are zero, there is no Y Full Scale for this wave.
	
	The wave can be multi-dimensional. See MDGetWaveScaling.
	
	Thread Safety: WaveScaling is Igor-thread-safe with XOP Toolkit 6 and Igor Pro 6.20 or later
	except for waves passed to threads as parameters. You can call it from a thread created
	by Igor but not from a private thread that you created yourself.
*/
void
WaveScaling(waveHndl waveH, double *hsAPtr, double *hsBPtr, double *topPtr, double *botPtr)
{
	CallBack5(WAVESCALING, waveH, hsAPtr, hsBPtr, topPtr, botPtr);
}

/*	SetWaveScaling(waveH, hsAPtr, hsBPtr, topPtr, botPtr)

	Sets the wave's X and Y scaling information.
	If hsAPtr and/or hsBPtr are NULL, does not set X scaling.
	If topPtr and/or botPtr are NULL, does not set Y scaling.
	
	For multidimensional waves use MDSetWaveScaling.
	
	Thread Safety: SetWaveScaling is Igor-thread-safe with XOP Toolkit 6 and Igor Pro 6.20 or later
	except for waves passed to threads as parameters. You can call it from a thread created
	by Igor but not from a private thread that you created yourself.
*/
void
SetWaveScaling(waveHndl waveH, const double *hsAPtr, const double *hsBPtr, const double *topPtr, const double *botPtr)
{
	CallBack5(SETWAVESCALING, waveH, (void*)hsAPtr, (void*)hsBPtr, (void*)topPtr, (void*)botPtr);
}

/*	WaveUnits(waveH, xUnits, dataUnits)

	Returns the wave's X and data units string.
	
	In Igor Pro 3.0, the number of characters allowed was increased from
	3 to 49 (MAX_UNIT_CHARS). For backward compatibility, WaveUnits will return
	no more than 3 characters (plus the null terminator). To get the full units and
	to access units for higher dimensions, new XOPs should use MDGetWaveUnits instead
	of WaveUnits.
	
	Thread Safety: WaveUnits is Igor-thread-safe with XOP Toolkit 6 and Igor Pro 6.20 or later
	except for waves passed to threads as parameters. You can call it from a thread created
	by Igor but not from a private thread that you created yourself.
*/
void
WaveUnits(waveHndl waveH, char *xUnits, char *dataUnits)
{
	CallBack3(WAVEUNITS, waveH, xUnits, dataUnits);
}

/*	SetWaveUnits(waveH, xUnits, dataUnits)

	Sets the wave's X and data units string.

	If xUnits is NULL, does not set X units.
	If dataUnits is NULL, does not set data units.

	When running with Igor Pro 3.0 or later, units can be up to 49 (MAX_UNIT_CHARS)
	characters long. In earlier versions of Igor, units are limited to 3 characters.
	You can pass a longer units string but only the first 3 characters will be used.
	
	To access units for higher dimensions, use MDSetWaveUnits instead
	of SetWaveUnits.
	
	Thread Safety: SetWaveUnits is Igor-thread-safe with XOP Toolkit 6 and Igor Pro 6.20 or later
	except for waves passed to threads as parameters. You can call it from a thread created
	by Igor but not from a private thread that you created yourself.
*/
void
SetWaveUnits(waveHndl waveH, const char *xUnits, const char *dataUnits)
{
	CallBack3(SETWAVEUNITS, waveH, (void*)xUnits, (void*)dataUnits);
}

// WaveNote was removed in XOP Toolkit 7. Use WaveNoteCopy.

/*	WaveNoteCopy(waveH)

	Returns handle to wave's note text or NULL if wave has no note.
	
	The returned handle is a copy of Igor's internal wave note handle. You own the
	returned handle and, if it is not NULL, you must dispose it using WMDisposeHandle.
	
	Use SetWaveNote to change the wave note.
	
	WaveNoteCopy is a replacement for the WaveNote routine from XOP Toolkit 6 and before.
	If you used WaveNote, change the call to WaveNoteCopy and, if the returned handle
	is not NULL, dispose the handle when you are finished using it.
	
	Added in Igor Pro 7.00 but works with any version.
	
	Thread Safety: WaveNoteCopy is Igor-thread-safe with XOP Toolkit 6 and Igor Pro 6.20 or later
	except for waves passed to threads as parameters. You can call it from a thread created
	by Igor but not from a private thread that you created yourself.
*/
Handle
WaveNoteCopy(waveHndl waveH)
{
	Handle noteH;
	int err;
	
	if (igorVersion < 700) {
		noteH = (Handle)CallBack1(WAVENOTE, waveH);
		if (noteH == NULL)
			return NULL;
		err = WMHandToHand(&noteH);
		if (err != 0)
			return NULL;
		return noteH;				// This is a copy of the original wave note handle. You own it.
	}
	
	// Igor7 or later
	noteH = (Handle)CallBack1(WAVENOTECOPY, waveH);
	if (noteH == NULL)
		return NULL;
	return noteH;					// This is a copy of the original wave note handle. You own it.
}

/*	SetWaveNote(waveH, noteHandle)

	Sets wave's note text.
	noteHandle is handle to text or NULL if you want to kill wave's note.
	
	NOTE: once you pass the noteHandle to Igor, don't modify or dispose of it.
	
	Thread Safety: SetWaveNote is Igor-thread-safe with XOP Toolkit 6 and Igor Pro 6.20 or later
	except for waves passed to threads as parameters. You can call it from a thread created
	by Igor but not from a private thread that you created yourself.
*/
void
SetWaveNote(waveHndl waveH, Handle noteHandle)
{
	CallBack2(SETWAVENOTE, waveH, noteHandle);
}

/*	WaveModDate(waveH)

	Returns wave modification date. This is an unsigned long in Macintosh
	date/time format, namely the number of seconds since midnight, January 1, 1904.
	
	The main use for this is to allow an XOP to check if a particular wave has been
	changed. For example, an XOP that displays a wave can check the wave's mod date
	in the XOP's idle routine. If the date has changed since the last time the
	XOP updated its display, it can update the display again.
	
	Modification date tracking was added to Igor in Igor 1.2. If a wave
	is loaded from a file created by an older version of Igor, the mod date field
	will be zero and this routine will return zero.
	
	Thread Safety: WaveModDate is Igor-thread-safe with XOP Toolkit 6 and Igor Pro 6.20 or later
	except for waves passed to threads as parameters. You can call it from a thread created
	by Igor but not from a private thread that you created yourself.
*/
TickCountInt
WaveModDate(waveHndl waveH)
{
	switch(WAVE_VERSION(waveH)) {
		case kWaveStruct3Version:		// modDate field
			#ifdef IGOR64
				return (*(UInt32*)((char*)*waveH+12));
			#else
				return (*(UInt32*)((char*)*waveH+8));
			#endif
			break;
		
		default:		/* Future version of Igor with a different wave structure. */
			return (TickCountInt)CallBack1(WAVEMODDATE, waveH);
			break;
	}
}

/*	WaveLock(waveH)

	Returns the lock state of the wave.
	
	A return value of 0 signifies that the wave is not locked.
	
	A return value of 1 signifies that the wave is locked. In that case, you should
	not kill the wave or modify it in any way.
	
	Thread Safety: WaveLock is Igor-thread-safe with XOP Toolkit 6 and Igor Pro 6.20 or later
	except for waves passed to threads as parameters. You can call it from a thread created
	by Igor but not from a private thread that you created yourself.
*/
int
WaveLock(waveHndl waveH)
{
	return (int)CallBack1(WAVELOCK, waveH);
}

/*	SetWaveLock(waveH, lockState)

	Sets wave's lock state.
	
	If lockState is 0, the wave will be unlocked. If it is 1, the wave will be locked.
	
	All other bits are reserved.
	
	Returns the previous state of the wave lock setting.
	
	Thread Safety: SetWaveLock is Igor-thread-safe with XOP Toolkit 6 and Igor Pro 6.20 or later
	except for waves passed to threads as parameters. You can call it from a thread created
	by Igor but not from a private thread that you created yourself.
*/
int
SetWaveLock(waveHndl waveH, int lockState)
{
	return (int)CallBack2(SETWAVELOCK, waveH, XOP_CALLBACK_INT(lockState));
}

/*	WaveModState(waveH)

	Returns the truth that the wave has been modified since the last save to disk.

	This routine works with all versions of Igor.
	
	Thread Safety: WaveModState is Igor-thread-safe with XOP Toolkit 6 and Igor Pro 6.20 or later
	except for waves passed to threads as parameters. You can call it from a thread created
	by Igor but not from a private thread that you created yourself.
*/
int
WaveModState(waveHndl waveH)
{
	switch(WAVE_VERSION(waveH)) {
		case kWaveStruct3Version:		// swModified field
			#ifdef IGOR64
				return (*(short*)((char*)*waveH+364));
			#else
				return (*(short*)((char*)*waveH+296));
			#endif
			break;
		
		default:		/* Future version of Igor with a different wave structure. */
			return (int)CallBack1(WAVEMODSTATE, waveH);
			break;
	}
}

/*	WaveModCount(waveH)

	Returns a value that can be used to tell if a wave has been changed between
	one call to WaveModCount and another. This function was created so that the
	Igor Data Browser could tell when a wave was changed. Previously, the Data
	Browser used the WaveModDate function, but that function can not identify
	changes that happen closer than 1 second apart.
	
	The exact value returned by WaveModCount has no significance. The only valid
	use for it is to compare the values returned by two calls to WaveModCount. If
	they are the different, the wave was changed in the interim.
	
	Example:
		waveModCount1 = WaveModCount(waveH);
		. . .
		waveModCount2 = WaveModCount(waveH);
		if (waveModCount2 != waveModCount1)
			// Wave has changed.
	
	Thread Safety: WaveModCount is Igor-thread-safe with XOP Toolkit 6 and Igor Pro 6.20 or later
	except for waves passed to threads as parameters. You can call it from a thread created
	by Igor but not from a private thread that you created yourself.
*/
int
WaveModCount(waveHndl waveH)
{
	switch(WAVE_VERSION(waveH)) {
		case kWaveStruct3Version:		// modCount
			#ifdef IGOR64
				return (*(short*)((char*)*waveH+380));
			#else
				return (*(short*)((char*)*waveH+308));
			#endif
			break;
		
		default:		/* Future version of Igor with a different wave structure. */
			return (int)CallBack1(WAVEMODCOUNT, waveH);
			break;
	}
}

// GetWavesInfo has been removed. Use WaveType, WavePoints and WaveData as needed.

// SetWavesStates has been removed. It is obsolete and no longer needed.

/*	MakeWave(waveHPtr,waveName,numPoints,type,overwrite)

	Tries to make wave with specified name, number of points, numeric type.
	
	NOTE: For historical reasons from ancient times, prior to XOP Toolkit 6,
	if numPoints was zero, MakeWave created a 128 point wave. As of XOP Toolkit 6,
	passing 0 for numPoints creates a zero-point wave.

	Returns error code or 0 if wave was made.
	
	Thread Safety: MakeWave is Igor-thread-safe with XOP Toolkit 6 and Igor Pro 6.20 or later
	except for waves passed to threads as parameters. You can call it from a thread created
	by Igor but not from a private thread that you created yourself.
*/
int
MakeWave(waveHndl *waveHPtr, const char *waveName, CountInt numPoints, int type, int overwrite)
{
	*waveHPtr = NULL;
	
	if (numPoints == 0) {	// See note above.
		CountInt dimSizes[MAX_DIMENSIONS+1];
		MemClear(dimSizes, sizeof(dimSizes));
		return (int)MDMakeWave(waveHPtr,waveName,NULL,dimSizes,type,overwrite);	
	}
	
	return (int)CallBack5(MAKEWAVE, waveHPtr, (void*)waveName, XOP_CALLBACK_INT(numPoints), XOP_CALLBACK_INT(type), XOP_CALLBACK_INT(overwrite));
}

/*	ChangeWave(waveH, numPoints, type)

	Changes wave length to specified number of points and numeric type.
	Returns error code or 0 if OK.
	
	Thread Safety: ChangeWave is Igor-thread-safe with XOP Toolkit 6 and Igor Pro 6.20 or later
	except for waves passed to threads as parameters. You can call it from a thread created
	by Igor but not from a private thread that you created yourself.
*/
int
ChangeWave(waveHndl waveH, CountInt numPoints, int type)
{
	return (int)CallBack3(CHANGEWAVE, waveH, XOP_CALLBACK_INT(numPoints), XOP_CALLBACK_INT(type));
}

/*	KillWave(waveH)

	Kills wave.
	Returns error code or 0 if OK.
	
	NOTE: if wave is in use, returns error code and wave is not killed.
	
	Thread Safety: KillWave is Igor-thread-safe with XOP Toolkit 6 and Igor Pro 6.20 or later
	except for waves passed to threads as parameters. You can call it from a thread created
	by Igor but not from a private thread that you created yourself.
*/
int
KillWave(waveHndl waveH)
{
	return (int)CallBack1(KILLWAVE, waveH);
}

/*	*** Multi-dimension Wave Access Routines *** */

/*	MDMakeWave(waveHPtr,waveName,dataFolderH,dimSizes,type,overwrite)

	Tries to make wave with specified name and type in the specified data folder.
	
	If dataFolderH is NULL, it uses the current data folder.
	
	For each dimension, dimSizes[i] specifies the number of points
	in that dimension. For a wave of dimension n, i goes from 0 to n-1.
	
	NOTE: dimSizes[n] must be zero. This is how Igor determines
		  how many dimensions the wave is to have.
		  
	Igor supports a maximum of four dimensions. Therefore, dimSizes[n] must be zero,
	where n is less than or equal to four. MAX_DIMENSIONS is larger than 4 to allow
	XOPs to continue to work in the event that a future version of Igor supports
	more than four dimensions.
	
	If you are running with Igor Pro 6.20 or later, you can pass -1 for
	dataFolderH to create a free wave. This would be appropriate if, for example,
	your external function were called from a user-defined function with a flag
	parameter indicating that the user wants to create a free wave.
	You must be sure that you are running with Igor Pro 6.20 or a later.
	If you are running with an earlier version, this will cause a crash.
	For example:
		if (igorVersion < 620)
			return IGOR_OBSOLETE;	// Can't create free wave in old Igor
		result = MDMakeWave(&waveH, "freejack", (DataFolderHandle)-1, dimensionSizes, type, overwrite);
	When making a free wave, the overwrite parameter is irrelevant and is ignored.
	
	You can also create a free wave using GetOperationDestWave.

	Returns error code or 0 if wave was made.
	
	Thread Safety: MDMakeWave is Igor-thread-safe with XOP Toolkit 6 and Igor Pro 6.20 or later
	except for waves passed to threads as parameters. You can call it from a thread created
	by Igor but not from a private thread that you created yourself.
*/
int
MDMakeWave(waveHndl *waveHPtr, const char *waveName, DataFolderHandle dataFolderH, CountInt dimSizes[MAX_DIMENSIONS+1], int type, int overwrite)
{
	*waveHPtr = NULL;
	return (int)CallBack6(MD_MAKEWAVE,waveHPtr, (void*)waveName,dataFolderH, dimSizes, XOP_CALLBACK_INT(type), XOP_CALLBACK_INT(overwrite));
}

/*	MDGetWaveDimensions(waveH, numDimensionsPtr, dimSizes)

	Returns number of used dimensions in wave via numDimensionsPtr
	and the number of points in each used dimension via dimSizes.

	If you only want o know the number of dimensions, you can pass NULL for dimSizes.
	
	NOTE: dimSizes (if not NULL) should have room for MAX_DIMENSIONS+1 values.

	For an n dimensional wave, MDGetWaveDimensions sets dimSizes[0..n-1] 
	to the number of elements in the corresponding dimension and sets
	dimSizes[n..MAX_DIMENSIONS] to zero, indicating that they are unused
	dimensions. This guarantees that there will always be an element containing
	zero in the dimSizes array.
	
	The function result is 0 or an Igor error code.
	
	Thread Safety: MDGetWaveDimensions is Igor-thread-safe with XOP Toolkit 6 and Igor Pro 6.20 or later
	except for waves passed to threads as parameters. You can call it from a thread created
	by Igor but not from a private thread that you created yourself.
*/
int
MDGetWaveDimensions(waveHndl waveH, int* numDimensionsPtr, CountInt dimSizes[MAX_DIMENSIONS+1])
{
	CountInt dimSize;
	CountInt* nDim;
	int i;
	
	if (dimSizes != NULL)
		MemClear(dimSizes, (MAX_DIMENSIONS+1)*sizeof(CountInt));		/* All unused dimensions are zeroed. */
	switch(WAVE_VERSION(waveH)) {
		case kWaveStruct3Version:		// nDim field
			#ifdef IGOR64
				nDim = (CountInt*)((char*)*waveH + 80);
			#else
				nDim = (CountInt*)((char*)*waveH + 68);
			#endif
			*numDimensionsPtr = 0;
			for(i=0; i<MAXDIMS1; i++) {
				dimSize = nDim[i];
				if (dimSize==0)
					break;
				*numDimensionsPtr += 1;
				if (dimSizes!=NULL)
					dimSizes[i] = dimSize;
			}
			return 0;
			break;
		
		default:		/* Future version of Igor with a different wave structure. */
			return (int)CallBack3(MD_GETWAVEDIMENSIONS, waveH, numDimensionsPtr, dimSizes);
			break;
	}
}

/*	MDChangeWave(waveH, type, dimSizes)

	Changes one or more of the following:
		the wave's data type
		the number of dimensions in the wave
		the number of points in one or more dimensions
	
	type is one of the following:
		-1 for no change in data type.
		
		NT_FP32, NT_FP64 for single or double precision floating point
		NT_I8, NT_I16, NT_I32, NT_I64 for 8, 16, 32 or 64 bit signed integer.
		These may be ORed with NT_COMPLEX to make the wave complex
		and ORed with NT_UNSIGNED to make the wave unsigned integer.
	
		TEXT_WAVE_TYPE.
	However converting a text wave to numeric or vice versa is currently not
	supported and will result in an error.
	
	64-bit integer waves (NT_I64) were added in Igor Pro 7.00.
	
	dimSizes[i] contains the desired number of points for dimension i.
	For n dimensions, dimSizes[n] must be zero. Then the size of each
	dimension is set by dimSizes[0..n-1]. If dimSizes[i] == -1, then the
	size of dimension i will be unchanged.
		  
	Igor supports a maximum of four dimensions. Therefore, dimSizes[n] must be zero,
	where n is less than or equal to four. MAX_DIMENSIONS is larger than 4 to allow
	XOPs to continue to work in the event that a future version of Igor supports
	more than four dimensions.
	
	Returns 0 or an error code.
	
	The block of memory referenced by the wave handle can be relocated if you increase
	the size of the wave. To avoid dangling pointer bugs, you must refresh any pointer
	that points to the waves data after calling MDChangeWave.
	
	Thread Safety: MDChangeWave is Igor-thread-safe with XOP Toolkit 6 and Igor Pro 6.20 or later
	except for waves passed to threads as parameters. You can call it from a thread created
	by Igor but not from a private thread that you created yourself.
*/
int
MDChangeWave(waveHndl waveH, int type, CountInt dimSizes[MAX_DIMENSIONS+1])
{
	return (int)CallBack3(MD_CHANGEWAVE, waveH, XOP_CALLBACK_INT(type), dimSizes);
}

/*	MDChangeWave2(waveH, type, dimSizes, mode)

	This is the same as MDChangeWave except for the added mode parameter.
	
	mode = 0:	Does a normal redimension.
	
	mode = 1:	Changes the wave's dimensions without changing the wave data.
				This is useful, for example, when you have a 2D wave
				consisting of 5 rows and 3 columns which you want to treat
				as a 2D wave consisting of 3 rows and 5 columns.
	
	mode = 2:	Changes the wave data from big-endian to little-endian
				or vice versa. This is useful when you have loaded data
				from a file that uses a byte ordering different from that
				of the platform on which you are running.
	
	Returns 0 or an error code.
	
	See MDChangeWave for further discussion.
	
	Thread Safety: MDChangeWave2 is Igor-thread-safe with XOP Toolkit 6 and Igor Pro 6.20 or later
	except for waves passed to threads as parameters. You can call it from a thread created
	by Igor but not from a private thread that you created yourself.
*/
int
MDChangeWave2(waveHndl waveH, int type, CountInt dimSizes[MAX_DIMENSIONS+1], int mode)
{
	if (mode == 0)
		return (int)CallBack3(MD_CHANGEWAVE, waveH, XOP_CALLBACK_INT(type), dimSizes);
	
	return (int)CallBack4(MD_CHANGEWAVE2, waveH, XOP_CALLBACK_INT(type), dimSizes, XOP_CALLBACK_INT(mode));
}

/*	MDGetWaveScaling(waveH, dimension, sfAPtr, sfBPtr)

	Returns the dimension scaling values or the full scale values for the wave.
	If dimension is -1, it returns the full scale values. Otherwise, it returns the dimension
	scaling.
	
	For dimension d, the scaled index of point p is:
	  scaled index = sfA[d]*p + sfB[d].
	
	If dimension is -1, this gets the wave's data full scale setting instead of
	dimension scaling. *sfAPtr points to the top full scale value and *sfBPtr
	points to the bottom full scale value.
	
	The function result is 0 or an Igor error code.
	
	Thread Safety: MDGetWaveScaling is Igor-thread-safe with XOP Toolkit 6 and Igor Pro 6.20 or later
	except for waves passed to threads as parameters. You can call it from a thread created
	by Igor but not from a private thread that you created yourself.
*/
int
MDGetWaveScaling(waveHndl waveH, int dimension, double* sfAPtr, double* sfBPtr)
{
	switch(WAVE_VERSION(waveH)) {
		case kWaveStruct3Version:
		default:		/* Future version of Igor with a different wave structure. */
			return (int)CallBack4(MD_GETWAVESCALING, waveH, XOP_CALLBACK_INT(dimension), sfAPtr, sfBPtr);	// HR, 091201: This was CallBack3 which was wrong.
			break;
	}
}

/*	MDSetWaveScaling(waveH, dimension, sfAPtr, sfBPtr)

	Sets the dimension scaling values or the full scale values for the wave.
	If dimension is -1, it sets the full scale values. *sfAPtr is the top full
	scale value and *sfBPtr is the bottom full scale value.
	
	If dimension is 0 or greater, it sets the dimension scaling.
	For dimension d, the scaled index of point p is:
	  scaled index = sfA[d]*p + sfB[d].
	The sfA value can never be set to zero. If you pass 0.0 for sfA, this routine
	will use 1.0 instead.
	
	If dimension is -1, this sets the wave's data full scale setting instead of
	dimension scaling. *sfAPtr points to the top full scale value and *sfBPtr
	points to the bottom full scale value.
	
	The function result is 0 or an Igor error code.
	
	Thread Safety: MDSetWaveScaling is Igor-thread-safe with XOP Toolkit 6 and Igor Pro 6.20 or later
	except for waves passed to threads as parameters. You can call it from a thread created
	by Igor but not from a private thread that you created yourself.
*/
int
MDSetWaveScaling(waveHndl waveH, int dimension, const double* sfAPtr, const double* sfBPtr)
{
	/*	HR, 031112, XOP Toolkit 5.00:
		This routine previously set wave fields directly instead of calling
		back to Igor. This was not sufficient because Igor internally sets
		other flags in addition to the wave fields. So now it always does
		a callback to Igor.
	*/
	return (int)CallBack4(MD_SETWAVESCALING, waveH, XOP_CALLBACK_INT(dimension), (void*)sfAPtr, (void*)sfBPtr);
}

/*	MDGetWaveUnits(waveH, dimension, units)

	Returns the units string for the specified dimension in the wave via units.
	
	To get the data units (as opposed to dimension units), pass -1 for dimension.
	
	In Igor Pro 3.0 or later, units can be up to 49 (MAX_UNIT_CHARS) characters. In
	earlier versions, units were limited to 3 characters.
		
	The function result is 0 or an Igor error code.
	
	Thread Safety: MDGetWaveUnits is Igor-thread-safe with XOP Toolkit 6 and Igor Pro 6.20 or later
	except for waves passed to threads as parameters. You can call it from a thread created
	by Igor but not from a private thread that you created yourself.
*/
int
MDGetWaveUnits(waveHndl waveH, int dimension, char units[MAX_UNIT_CHARS+1])
{
	*units = 0;
	
	switch (WAVE_VERSION(waveH)) {
		case kWaveStruct3Version:
		default:
			return (int)CallBack3(MD_GETWAVEUNITS, waveH, XOP_CALLBACK_INT(dimension), units);
			break;
	}
}

/*	MDSetWaveUnits(waveH, int dimension, units[MAX_UNIT_CHARS+1])

	Sets the units string for the specified dimension.
	
	To set the data units (as opposed to dimension units), pass -1 for dimension.
	
	In Igor Pro 3.0 or later, units can be up to 49 (MAX_UNIT_CHARS) characters. In
	earlier versions, units were limited to 3 characters. In either case, if the
	string you pass is too long, Igor will store a truncated version of it. 
	
	The function result is 0 or an Igor error code.
	
	Thread Safety: MDSetWaveUnits is Igor-thread-safe with XOP Toolkit 6 and Igor Pro 6.20 or later
	except for waves passed to threads as parameters. You can call it from a thread created
	by Igor but not from a private thread that you created yourself.
*/
int
MDSetWaveUnits(waveHndl waveH, int dimension, const char units[MAX_UNIT_CHARS+1])
{
	switch (WAVE_VERSION(waveH)) {
		case kWaveStruct3Version:
		default:
			return (int)CallBack3(MD_SETWAVEUNITS, waveH, XOP_CALLBACK_INT(dimension), (void*)units);
			break;
	}
}

/*	MDGetDimensionLabel(waveH, dimension, element, label)

	Returns the label for the specified element of the specified dimension via label.
	
	If element is -1, this specifies a label for the entire dimension.
	If element is between 0 to n-1, where n is the size of the dimension,
	then element specifies a label for that element of the dimension only.
	
	label must have room for MAX_DIM_LABEL_BYTES+1 bytes.
 
	The function result is 0 or an Igor error code.
	
	Thread Safety: MDGetDimensionLabel is Igor-thread-safe with XOP Toolkit 6 and Igor Pro 6.20 or later
	except for waves passed to threads as parameters. You can call it from a thread created
	by Igor but not from a private thread that you created yourself.
*/
int
MDGetDimensionLabel(waveHndl waveH, int dimension, IndexInt element, char label[MAX_DIM_LABEL_BYTES+1])
{
	switch (WAVE_VERSION(waveH)) {
		case kWaveStruct3Version:
		default:
			return (int)CallBack4(MD_GETDIMLABELS, waveH, XOP_CALLBACK_INT(dimension), XOP_CALLBACK_INT(element), label);
			break;
	}
}

/*	MDSetDimensionLabel(waveH, dimension, element, label)

	Sets the label for the specified element of the specified dimension via label.
	
	If element is -1, this specifies a label for the entire dimension.
	If element is between 0 to n-1, where n is the size of the dimension,
	then element specifies a label for that element of the dimension only.
 
	The function result is 0 or an Igor error code.
	
	Thread Safety: MDSetDimensionLabel is Igor-thread-safe with XOP Toolkit 6 and Igor Pro 6.20 or later
	except for waves passed to threads as parameters. You can call it from a thread created
	by Igor but not from a private thread that you created yourself.
*/
int
MDSetDimensionLabel(waveHndl waveH, int dimension, IndexInt element, const char label[MAX_DIM_LABEL_BYTES+1])
{
	switch (WAVE_VERSION(waveH)) {
		case kWaveStruct3Version:
		default:
			return (int)CallBack4(MD_SETDIMLABELS, waveH, XOP_CALLBACK_INT(dimension), XOP_CALLBACK_INT(element), (void*)label);
			break;
	}
}

/*	MDAccessNumericWaveData(waveH, accessMode, dataOffsetPtr)
	
	MDAccessNumericWaveData provides access to the data for numeric waves.
	
	waveH is the wave handle containing the data you want to access.
	
	accessMode is a code that tells Igor how you plan to access the wave data
	and is used for a future compatibility check. At present, there is only one
	accessMode. You should use the symbol kMDWaveAccessMode0 for the accessMode parameter.
	
	On output, if there is no error, *dataOffsetPtr contains the offset in bytes
	from the start of the wave handle to the data.
	
	MDAccessNumericWaveData returns 0 or an error code.
	
	If it returns a non-zero error code, you should not attempt to access
	the wave data but merely return the error code to Igor.
	
	At present, there is only one case in which MDAccessNumericWaveData will return an
	error code. This is if the wave is a text wave.
	
	Numeric wave data is stored contiguously in the wave handle in one of the
	supported data types (NT_I8, NT_I16, NT_I32, NT_I64, NT_FP32, NT_FP64). These types
	will be ORed with NT_CMPLX if the wave is complex and ORed with NT_UNSIGNED if
	the wave is unsigned integer. 64-bit integer waves (NT_I64) were added in Igor Pro 7.00.
	
	It is possible that a future version of Igor Pro will store wave data in
	a different way, such that the current method of accessing wave data will no
	longer work. If your XOP ever runs with such a future Igor, MDAccessNumericWaveData
	will return an error code indicating the incompatibility. Your XOP will refrain
	from attempting to access the wave data and return the error code to Igor.
	This will prevent a crash and indicate the nature of the problem to the user.
	
	Although they are not truly numeric waves, MDAccessNumericWaveData also allows
	you to access wave reference waves (WAVE_TYPE) and data folder reference waves
	(DATAFOLDER_TYPE) which store waveHndls and DataFolderHandles respectively.
	
	To access the a particular point, you need to know the number of data points in each
	dimension. To find this, you must call MDGetWaveDimensions. This returns the number
	of used dimensions in the wave and an array of dimension lengths. The dimension lengths
	are interpreted as follows:
		dimSizes[0]		number of rows in a column
		dimSizes[1]		number of columns in a layer
		dimSizes[2]		number of layers in a chunk
		dimSizes[3]		number of chunks in the wave
	
	The data is stored in row/column/layer/chunk order. This means that,
	as you step linearly through memory one point at a time, you first pass the
	value for each row in the first column. At the end of the first column,
	you reach the start of the second column. After you have passed the data for
	each column in the first layer, you reach the data for the first column
	in the second layer. After you have passed the data for each layer, you
	reach the data for the first layer of the second chunk. And so on.
	
	Thread Safety: MDAccessNumericWaveData is Igor-thread-safe with XOP Toolkit 6 and Igor Pro 6.20 or later
	except for waves passed to threads as parameters. You can call it from a thread created
	by Igor but not from a private thread that you created yourself.
*/
int
MDAccessNumericWaveData(waveHndl waveH, int accessMode, BCInt* dataOffsetPtr)
{
	if (accessMode!=kMDWaveAccessMode0)		/* Call back to Igor if this is an unknown (future) access mode. */
		return (int)CallBack3(MD_ACCESSNUMERICWAVEDATA, waveH, XOP_CALLBACK_INT(accessMode), dataOffsetPtr);
	
	switch(WAVE_VERSION(waveH)) {
		case kWaveStruct3Version:		// offset of wData field
			if (WaveType(waveH) == TEXT_WAVE_TYPE)
				return NUMERIC_ACCESS_ON_TEXT_WAVE;
			#ifdef IGOR64
				*dataOffsetPtr = 400;
			#else
				*dataOffsetPtr = 320;
			#endif
			return 0;
			break;
		
		default:		/* Future version of Igor with a different wave structure. */
			return (int)CallBack3(MD_ACCESSNUMERICWAVEDATA, waveH, XOP_CALLBACK_INT(accessMode), dataOffsetPtr);
			break;
	}
}

/*	MDPointIndexV3(waveH, indices[MAX_DIMENSIONS], indexPtr)
	
	For version 3 waves, returns a linear index number to access the point
	indicated by the indices.
	
	waveH must be a version 3 wave.
	
	NOTE: This routine ignores indices for dimensions that do not exist in the wave.
	
	Thread Safety: MDPointIndexV3 is Igor-thread-safe with XOP Toolkit 6 and Igor Pro 6.20 or later
	except for waves passed to threads as parameters. You can call it from a thread created
	by Igor but not from a private thread that you created yourself.
*/
static int
MDPointIndexV3(waveHndl waveH, CountInt indices[MAX_DIMENSIONS], IndexInt* indexPtr)
{
	CountInt* nDim;
	IndexInt p;
	CountInt dimtot= 1;
	CountInt dimSize;
	int i;
	
	#ifdef IGOR64
		nDim = (CountInt*)((char*)*waveH + 80);
	#else
		nDim = (CountInt*)((char*)*waveH + 68);
	#endif
	
	*indexPtr = 0;
	for(i=0; i<MAXDIMS1; i++) {
		dimSize = nDim[i];
		if (dimSize == 0)
			break;							/* We've done all used dimensions. */
		p = indices[i];
		if (p<0 || p>=dimSize)
			return MD_WAVE_BAD_INDEX;
		if (dimSize != 0) {
			*indexPtr += p*dimtot;
			dimtot *= dimSize;
		}
	}

	return 0;		
}

/*	FetchNumericValue(type, dataStartPtr, index, value)

	type is an Igor numeric type.
	
	dataStartPtr points to the start of the data of the specified type.
	
	index is the "point number" of the point of interest, considering
	the data as one long vector.
	
	Scaling of signed and unsigned 64-bit integer values is subject to inaccuracies
	for values exceeding 2^53 in magnitude because calculations are done in double-precision
	and double-precision can not precisely represent the full range of 64-integer values.
	Values returned for signed and unsigned 64-bit integer data will be imprecise
	if the value exceeds 2^53 in magnitude because double-precision floating point
	can not precisely represent integers larger than 2^53. See "64-bit Integer Issues"
	in the XOP Toolkit manual for further discussion.
	
	Thread Safety: FetchNumericValue is Igor-thread-safe with XOP Toolkit 6 and Igor Pro 6.20 or later
	except for waves passed to threads as parameters. You can call it from a thread created
	by Igor but not from a private thread that you created yourself.
*/
int
FetchNumericValue(int type, const char* dataStartPtr, IndexInt index, double value[2])
{
	int isComplex;
	double* dp;
	float* fp;
	SInt64* llp;
	UInt64* ullp;
	SInt32* lp;
	UInt32* ulp;
	short* sp;
	unsigned short* usp;
	signed char* cp;
	unsigned char* ucp;

	isComplex = type & NT_CMPLX;
	if (isComplex)
		index *= 2;
	type &= ~NT_CMPLX;
	
	switch (type) {
		case NT_FP64:
			dp = (double*)dataStartPtr + index;
			value[0] = *dp++;
			if (isComplex)
				value[1] = *dp;
			break;
	
		case NT_FP32:
			fp = (float*)dataStartPtr + index;
			value[0] = *fp++;
			if (isComplex)
				value[1] = *fp;
			break;
	
		case NT_I64:								// Added in Igor Pro 7.00
			llp = (SInt64*)dataStartPtr + index;	// See note above about 2^53 limit
			value[0] = (double)*llp++;
			if (isComplex)
				value[1] = (double)*llp;
			break;
	
		case NT_I64 | NT_UNSIGNED:					// Added in Igor Pro 7.00
			ullp = (UInt64*)dataStartPtr + index;	// See note above about 2^53 limit
			value[0] = (double)*ullp++;
			if (isComplex)
				value[1] = (double)*ullp;
			break;
	
		case NT_I32:
			lp = (SInt32*)dataStartPtr + index;
			value[0] = *lp++;
			if (isComplex)
				value[1] = *lp;
			break;
	
		case NT_I32 | NT_UNSIGNED:
			ulp = (UInt32*)dataStartPtr + index;
			value[0] = *ulp++;
			if (isComplex)
				value[1] = *ulp;
			break;
	
		case NT_I16:
			sp = (short*)dataStartPtr + index;
			value[0] = *sp++;
			if (isComplex)
				value[1] = *sp;
			break;
	
		case NT_I16 | NT_UNSIGNED:
			usp = (unsigned short*)dataStartPtr + index;
			value[0] = *usp++;
			if (isComplex)
				value[1] = *usp;
			break;
	
		case NT_I8:
			cp = (signed char*)dataStartPtr + index;
			value[0] = *cp++;
			if (isComplex)
				value[1] = *cp;
			break;
	
		case NT_I8 | NT_UNSIGNED:
			ucp = (unsigned char*)dataStartPtr + index;
			value[0] = *ucp++;
			if (isComplex)
				value[1] = *ucp;
			break;
		
		case TEXT_WAVE_TYPE:
			return NUMERIC_ACCESS_ON_TEXT_WAVE;

		case WAVE_TYPE:
		case DATAFOLDER_TYPE:
			return NUMERIC_ACCESS_ON_NON_NUMERIC_WAVE;
			
		default:
			return WAVE_TYPE_INCONSISTENT;		/* Should never happen. */
	}
	
	return 0;
}

/*	MDGetNumericWavePointValue(waveH, indices, value)
	
	Returns via value the value of a particular point in the specified wave.
	The value returned is always double precision floating point, regardless
	of the precision of the wave.
	
	Values returned for signed and unsigned 64-bit integer waves will be imprecise
	if the value exceeds 2^53 in magnitude because double-precision floating point
	can not precisely represent integers larger than 2^53. See "64-bit Integer Issues"
	in the XOP Toolkit manual for further discussion. If you must use 64-bit
	integer waves at full precision, use MDGetNumericWavePointValueSInt64 or 
	MDGetNumericWavePointValueUInt64 instead.
	
	indices is an array of dimension indices. For example, for a 3D wave,
		indices[0] should contain the row number
		indices[1] should contain the column number
		indices[2] should contain the layer number
	
	NOTE: This routine ignores indices for dimensions that do not exist in the wave.
	
	The real part of the value of specified point is returned in value[0].
	If the wave is complex, the imaginary part of the value of specified point
	is returned in value[1]. If the wave is not complex, value[1] is undefined.
	
	The function result is 0 or an error code.

	Currently the only error code returned is MD_WAVE_BAD_INDEX, indicating
	that you have passed invalid indices. Future versions of Igor may return
	other error codes. If you receive an error, just return it to Igor so
	that it will be reported to the user.
	
	Thread Safety: MDGetNumericWavePointValue is Igor-thread-safe with XOP Toolkit 6 and Igor Pro 6.20 or later
	except for waves passed to threads as parameters. You can call it from a thread created
	by Igor but not from a private thread that you created yourself.
*/
int
MDGetNumericWavePointValue(waveHndl waveH, IndexInt indices[MAX_DIMENSIONS], double value[2])
{
	int waveType;
	IndexInt index;
	int result;
	
	switch(WAVE_VERSION(waveH)) {
		case kWaveStruct3Version:
			waveType = WaveType(waveH);
			switch(waveType) {
				case TEXT_WAVE_TYPE:
					return NUMERIC_ACCESS_ON_TEXT_WAVE;
				case WAVE_TYPE:
				case DATAFOLDER_TYPE:
					return NUMERIC_ACCESS_ON_NON_NUMERIC_WAVE;
					break;
			}
			if (result = MDPointIndexV3(waveH, indices, &index))
				return result;
			return FetchNumericValue(waveType, (char*)WaveData(waveH), index, value);
			break;
		
		default:		/* Future version of Igor with a different wave structure. */
			return (int)CallBack3(MD_GETWAVEPOINTVALUE, waveH, indices, value);
			break;
	}
}

/*	StoreNumericValue(type, dataStartPtr, index, value)

	type is an Igor numeric type.
	
	dataStartPtr points to the start of the data of the specified type.
	
	index is the "point number" of the point of interest, considering
	the data as one long vector.
	
	Values stored for signed and unsigned 64-bit integer data will be imprecise
	if the value exceeds 2^53 in magnitude because double-precision floating point
	can not precisely represent integers larger than 2^53. See "64-bit Integer Issues"
	in the XOP Toolkit manual for further discussion.
	
	Thread Safety: StoreNumericValue is Igor-thread-safe with XOP Toolkit 6 and Igor Pro 6.20 or later
	except for waves passed to threads as parameters. You can call it from a thread created
	by Igor but not from a private thread that you created yourself.
*/
int
StoreNumericValue(int type, char* dataStartPtr, CountInt index, double value[2])
{
	int isComplex;
	double* dp;
	float* fp;
	SInt64* llp;
	UInt64* ullp;
	SInt32* lp;
	UInt32* ulp;
	short* sp;
	unsigned short* usp;
	signed char* cp;
	unsigned char* ucp;

	isComplex = type & NT_CMPLX;
	if (isComplex)
		index *= 2;
	type &= ~NT_CMPLX;
	
	switch (type) {
		case NT_FP64:
			dp = (double*)dataStartPtr + index;
			*dp++ = value[0];
			if (isComplex)
				*dp = value[1];
			break;
	
		case NT_FP32:
			fp = (float*)dataStartPtr + index;
			*fp++ = (float)value[0];
			if (isComplex)
				*fp = (float)value[1];
			break;
	
		case NT_I64:								// Added in Igor Pro 7.00
			llp = (SInt64*)dataStartPtr + index;	// See note above about 2^53 limit
			*llp++ = (SInt64)value[0];
			if (isComplex)
				*llp = (SInt64)value[1];
			break;
	
		case NT_I64 | NT_UNSIGNED:					// Added in Igor Pro 7.00
			ullp = (UInt64*)dataStartPtr + index;	// See note above about 2^53 limit
			*ullp++ = (UInt64)value[0];
			if (isComplex)
				*ullp = (UInt64)value[1];
			break;
	
		case NT_I32:
			lp = (SInt32*)dataStartPtr + index;
			*lp++ = (SInt32)value[0];
			if (isComplex)
				*lp = (SInt32)value[1];
			break;
	
		case NT_I32 | NT_UNSIGNED:
			ulp = (UInt32*)dataStartPtr + index;
			*ulp++ = (UInt32)value[0];
			if (isComplex)
				*ulp = (UInt32)value[1];
			break;
	
		case NT_I16:
			sp = (short*)dataStartPtr + index;
			*sp++ = (short)value[0];
			if (isComplex)
				*sp = (short)value[1];
			break;
	
		case NT_I16 | NT_UNSIGNED:
			usp = (unsigned short*)dataStartPtr + index;
			*usp++ = (unsigned short)value[0];
			if (isComplex)
				*usp = (unsigned short)value[1];
			break;
	
		case NT_I8:
			cp = (signed char*)dataStartPtr + index;
			*cp++ = (signed char)value[0];
			if (isComplex)
				*cp = (signed char)value[1];
			break;
	
		case NT_I8 | NT_UNSIGNED:
			ucp = (unsigned char*)dataStartPtr + index;
			*ucp++ = (unsigned char)value[0];
			if (isComplex)
				*ucp = (unsigned char)value[1];
			break;
		
		case TEXT_WAVE_TYPE:
			return NUMERIC_ACCESS_ON_TEXT_WAVE;

		case WAVE_TYPE:
		case DATAFOLDER_TYPE:
			return NUMERIC_ACCESS_ON_NON_NUMERIC_WAVE;
		
		default:
			return WAVE_TYPE_INCONSISTENT;		/* Should never happen. */
	}
	
	return 0;
}

/*	MDSetNumericWavePointValue(waveH, indices, value)
	
	Sets the value of a particular point in the specified wave.
	The value that you supply is always double precision floating point,
	regardless of the precision of the wave.
	
	Values stored in signed and unsigned 64-bit integer waves will be imprecise
	if the value exceeds 2^53 in magnitude because double-precision floating point
	can not precisely represent integers larger than 2^53. See "64-bit Integer Issues"
	in the XOP Toolkit manual for further discussion. If you must use 64-bit
	integer waves at full precision, use MDSetNumericWavePointValueSInt64 or
	MDSetNumericWavePointValueUInt64 instead.
	
	indices is an array of dimension indices. For example, for a 3D wave,
		indices[0] should contain the row number
		indices[1] should contain the column number
		indices[2] should contain the layer number
	
	NOTE: This routine ignores indices for dimensions that do not exist in the wave.
	
	You should pass in value[0] the real part of the value.
	If the wave is complex, you should pass the complex part in value[1].
	If the wave is not complex, Igor ignores value[1].
	
	The function result is 0 or an error code.

	Currently the only error code returned is MD_WAVE_BAD_INDEX, indicating
	that you have passed invalid indices. Future versions of Igor may return
	other error codes. If you receive an error, just return it to Igor so
	that it will be reported to the user.
	
	Thread Safety: MDSetNumericWavePointValue is Igor-thread-safe with XOP Toolkit 6 and Igor Pro 6.20 or later
	except for waves passed to threads as parameters. You can call it from a thread created
	by Igor but not from a private thread that you created yourself.
*/
int
MDSetNumericWavePointValue(waveHndl waveH, IndexInt indices[MAX_DIMENSIONS], double value[2])
{
	int waveType;
	IndexInt index;
	int result;

	switch(WAVE_VERSION(waveH)) {
		case kWaveStruct3Version:
			waveType = WaveType(waveH);
			switch(waveType) {
				case TEXT_WAVE_TYPE:
					return NUMERIC_ACCESS_ON_TEXT_WAVE;
				case WAVE_TYPE:
				case DATAFOLDER_TYPE:
					return NUMERIC_ACCESS_ON_NON_NUMERIC_WAVE;
					break;
			}
			if (result = MDPointIndexV3(waveH, indices, &index))
				return result;
			return StoreNumericValue(waveType, (char*)WaveData(waveH), index, value);
			break;
		
		default:		/* Future version of Igor with a different wave structure. */
			return (int)CallBack3(MD_SETWAVEPOINTVALUE, waveH, indices, value);
			break;
	}
}

/*	MDGetNumericWavePointValueSInt64(waveH, indices, value)
	
	Returns via value the value of a particular point in the specified numeric wave.
	The value returned is always signed 64-bit integer, regardless of the
	data type of the wave.
	
	This routine can be called for any numeric wave but is intended for use with signed
	64-bit integer (NT_I64) waves. For most applications, use MDGetNumericWavePointValue instead.
	
	Values returned for floating point waves are truncated to integers. Values returned
	will be incorrect if the wave value is outside the range of signed 64-bit integers
	(-9223372036854775808 to 9223372036854775807). These issues do not apply if the data
	type of the specified wave is NT_I64. See "64-bit Integer Issues" in the XOP Toolkit
	manual for further discussion.
	
	indices is an array of dimension indices. For example, for a 3D wave,
		indices[0] should contain the row number
		indices[1] should contain the column number
		indices[2] should contain the layer number
	
	NOTE: This routine ignores indices for dimensions that do not exist in the wave.
	
	The real part of the value of specified point is returned in value[0].
	If the wave is complex, the imaginary part of the value of specified point
	is returned in value[1]. If the wave is not complex, value[1] is undefined.
	
	The function result is 0 or an error code.
	
	MDGetNumericWavePointValueSInt64 was added in Igor Pro 7.03. If you call this
	with an earlier version of Igor, it will return IGOR_OBSOLETE and do nothing.
	
	Thread Safety: MDGetNumericWavePointValueSInt64 is Igor-thread-safe with XOP Toolkit 7
	and Igor Pro 7.03 or later except for waves passed to threads as parameters. You can call
	it from a thread created by Igor but not from a private thread that you created yourself.
*/
int
MDGetNumericWavePointValueSInt64(waveHndl waveH, IndexInt indices[MAX_DIMENSIONS], SInt64 value[2])
{
	int result = (int)CallBack3(MD_GETWAVEPOINTVALUE_SINT64, waveH, indices, value);
	return result;
}

/*	MDSetNumericWavePointValueSInt64(waveH, indices, value)
	
	Sets the value of a particular point in the specified numeric wave. The value that
	you supply is always signed 64-bit integer, regardless of the data type of the wave.
	
	This routine can be called for any numeric wave but is intended for use with signed
	64-bit integer (NT_I64) waves. For most applications, use MDSetNumericWavePointValue instead.
	
	Values stored in floating point waves will be imprecise if the value exceeds
	the range of integers that can be represented precisely in the wave's data type.
	Values stored in integer waves will be incorrect if value is outside the range that
	can be represented by the wave's data type. These issues do not apply if the data
	type of the specified wave is NT_I64. See "64-bit Integer Issues" in the XOP Toolkit
	manual for further discussion.
	
	indices is an array of dimension indices. For example, for a 3D wave,
		indices[0] should contain the row number
		indices[1] should contain the column number
		indices[2] should contain the layer number
	
	NOTE: This routine ignores indices for dimensions that do not exist in the wave.
	
	You should pass in value[0] the real part of the value.
	If the wave is complex, you should pass the complex part in value[1].
	If the wave is not complex, Igor ignores value[1].
	
	The function result is 0 or an error code.

	MDSetNumericWavePointValueSInt64 was added in Igor Pro 7.03. If you call this
	with an earlier version of Igor, it will return IGOR_OBSOLETE and do nothing.
	
	Thread Safety: MDSetNumericWavePointValueSInt64 is Igor-thread-safe with XOP Toolkit 7
	and Igor Pro 7.03 or later except for waves passed to threads as parameters. You can call
	it from a thread created by Igor but not from a private thread that you created yourself.
*/
int
MDSetNumericWavePointValueSInt64(waveHndl waveH, IndexInt indices[MAX_DIMENSIONS], SInt64 value[2])
{
	int result = (int)CallBack3(MD_SETWAVEPOINTVALUE_SINT64, waveH, indices, value);
	return result;
}

/*	MDGetNumericWavePointValueUInt64(waveH, indices, value)
	
	Returns via value the value of a particular point in the specified numeric wave.
	The value returned is always unsigned 64-bit integer, regardless of the
	data type of the wave.
	
	This routine can be called for any numeric wave but is intended for use with unsigned
	64-bit integer (NT_I64 | NT_UNSIGNED) waves. For most applications, use
	MDGetNumericWavePointValue instead.
	
	Values returned for floating point waves are truncated to integers. Values returned
	will be incorrect if the wave value is outside the range of unsigned 64-bit integers
	(0 to 18446744073709551615). These issues do not apply if the data type of the specified
	wave is NT_I64 | NT_UNSIGNED. See "64-bit Integer Issues" in the XOP Toolkit manual
	for further discussion.
	
	indices is an array of dimension indices. For example, for a 3D wave,
		indices[0] should contain the row number
		indices[1] should contain the column number
		indices[2] should contain the layer number
	
	NOTE: This routine ignores indices for dimensions that do not exist in the wave.
	
	The real part of the value of specified point is returned in value[0].
	If the wave is complex, the imaginary part of the value of specified point
	is returned in value[1]. If the wave is not complex, value[1] is undefined.
	
	The function result is 0 or an error code.
	
	MDGetNumericWavePointValueUInt64 was added in Igor Pro 7.03. If you call this
	with an earlier version of Igor, it will return IGOR_OBSOLETE and do nothing.
	
	Thread Safety: MDGetNumericWavePointValueUInt64 is Igor-thread-safe with XOP Toolkit 7
	and Igor Pro 7.03 or later except for waves passed to threads as parameters. You can call
	it from a thread created by Igor but not from a private thread that you created yourself.
*/
int
MDGetNumericWavePointValueUInt64(waveHndl waveH, IndexInt indices[MAX_DIMENSIONS], UInt64 value[2])
{
	int result = (int)CallBack3(MD_GETWAVEPOINTVALUE_UINT64, waveH, indices, value);
	return result;
}

/*	MDSetNumericWavePointValueUInt64(waveH, indices, value)
	
	Sets the value of a particular point in the specified numeric wave. The value that
	you supply is always unsigned 64-bit integer, regardless of the data type of the wave.
	
	This routine can be called for any numeric wave but is intended for use with unsigned
	64-bit integer (NT_I64 | NT_UNSIGNED) waves. For most applications, use
	MDSetNumericWavePointValue instead.
	
	Values stored in floating point waves will be imprecise if the value exceeds
	the range of integers that can be represented precisely in the wave's data type.
	Values stored in integer waves will be incorrect if value is outside the range that
	can be represented by the wave's data type. These issues do not apply if the data
	type of the specified wave is NT_I64 | NT_UNSIGNED. See "64-bit Integer Issues"
	in the XOP Toolkit manual for further discussion.
	
	indices is an array of dimension indices. For example, for a 3D wave,
		indices[0] should contain the row number
		indices[1] should contain the column number
		indices[2] should contain the layer number
	
	NOTE: This routine ignores indices for dimensions that do not exist in the wave.
	
	You should pass in value[0] the real part of the value.
	If the wave is complex, you should pass the complex part in value[1].
	If the wave is not complex, Igor ignores value[1].
	
	The function result is 0 or an error code.

	MDSetNumericWavePointValueUInt64 was added in Igor Pro 7.03. If you call this
	with an earlier version of Igor, it will return IGOR_OBSOLETE and do nothing.
	
	Thread Safety: MDSetNumericWavePointValueUInt64 is Igor-thread-safe with XOP Toolkit 7
	and Igor Pro 7.03 or later except for waves passed to threads as parameters. You can call
	it from a thread created by Igor but not from a private thread that you created yourself.
*/
int
MDSetNumericWavePointValueUInt64(waveHndl waveH, IndexInt indices[MAX_DIMENSIONS], UInt64 value[2])
{
	int result = (int)CallBack3(MD_SETWAVEPOINTVALUE_UINT64, waveH, indices, value);
	return result;
}

/*	MDGetDPDataFromNumericWave(waveH, dPtr)
	
	MDGetDPDataFromNumericWave stores a double-precision representation of
	the specified wave's data in the memory pointed to by dPtr. dPtr must
	point to a block of memory that you have allocated and which must be
	at least (WavePoints(waveH)*sizeof(double)) bytes.
	
	Values returned for signed and unsigned 64-bit integer waves will be imprecise
	if the value exceeds 2^53 in magnitude because double-precision floating point
	can not precisely represent integers larger than 2^53. If you must use 64-bit
	integer waves and require full precision for very large values, you must use
	MDGetNumericWavePointValueSInt64, MDGetNumericWavePointValueUInt64, or the
	direct access method as described for MDAccessNumericWaveData. See
	"64-bit Integer Issues" in the XOP Toolkit manual for further discussion.
	
	This routine is a companion to MDStoreDPDataInNumericWave.
	
	The function result is zero or an error code.
	
	Thread Safety: MDGetDPDataFromNumericWave is Igor-thread-safe with XOP Toolkit 6 and Igor Pro 6.20 or later
	except for waves passed to threads as parameters. You can call it from a thread created
	by Igor but not from a private thread that you created yourself.
*/
int
MDGetDPDataFromNumericWave(waveHndl waveH, double* dPtr)
{
	CountInt numNumbers;
	int bytesPerPoint;
	int waveType, type2;
	int srcFormat;
	
	switch(WAVE_VERSION(waveH)) {
		case kWaveStruct3Version:
			waveType = WaveType(waveH);
			switch(waveType) {
				case TEXT_WAVE_TYPE:
					return NUMERIC_ACCESS_ON_TEXT_WAVE;
				case WAVE_TYPE:
				case DATAFOLDER_TYPE:
					return NUMERIC_ACCESS_ON_NON_NUMERIC_WAVE;
					break;
			}
			type2 = waveType & ~NT_CMPLX;
			switch(type2) {
				case NT_I8:
					bytesPerPoint = sizeof(char);
					srcFormat = SIGNED_INT;
					break;
				case NT_I8 | NT_UNSIGNED:
					bytesPerPoint = sizeof(char);
					srcFormat = UNSIGNED_INT;
					break;
				case NT_I16:
					bytesPerPoint = sizeof(short);
					srcFormat = SIGNED_INT;
					break;
				case NT_I16 | NT_UNSIGNED:
					bytesPerPoint = sizeof(short);
					srcFormat = UNSIGNED_INT;
					break;
				case NT_I32:
					bytesPerPoint = sizeof(SInt32);
					srcFormat = SIGNED_INT;
					break;
				case NT_I32 | NT_UNSIGNED:
					bytesPerPoint = sizeof(UInt32);
					srcFormat = UNSIGNED_INT;
					break;
				case NT_I64:						// Added in Igor Pro 7.00
					bytesPerPoint = sizeof(SInt64);
					srcFormat = SIGNED_INT;
					break;
				case NT_I64 | NT_UNSIGNED:			// Added in Igor Pro 7.00
					bytesPerPoint = sizeof(UInt64);
					srcFormat = UNSIGNED_INT;
					break;
				case NT_FP32:
					bytesPerPoint = sizeof(float);
					srcFormat = IEEE_FLOAT;
					break;
				case NT_FP64:
					bytesPerPoint = sizeof(double);
					srcFormat = IEEE_FLOAT;
					break;
				default:
					return WAVE_TYPE_INCONSISTENT;		/* Corrupted wave. */
			}
			numNumbers = WavePoints(waveH);
			if (waveType & NT_CMPLX)
				numNumbers *= 2;
			ConvertData(WaveData(waveH), dPtr, numNumbers, bytesPerPoint, srcFormat, sizeof(double), IEEE_FLOAT);
			break;
		
		default:		/* Future version of Igor with a different wave structure. */
			return (int)CallBack2(MD_GETDPDATAFROMNUMERICWAVE, waveH, dPtr);
			break;
	}
	return 0;
}

/*	MDStoreDPDataInNumericWave(waveH, dPtr)
	
	MDStoreDPDataInNumericWave stores the data pointed to by dPtr in the specified wave.
	During the transfer, it converts the data from double precision to the numeric type
	of the wave. The conversion is done on-the-fly and the data pointed to by dPtr is not
	changed.
	
	When storing into an integer wave, MDStoreDPDataInNumericWave truncates the value that
	you are storing. If you want, you can do rounding before calling MDStoreDPDataInNumericWave.
	
	Values stored for signed and unsigned 64-bit integer waves will be imprecise
	if the value exceeds 2^53 in magnitude because double-precision floating point
	can not precisely represent integers larger than 2^53. If you must use 64-bit
	integer waves and require full precision for very large values, you must use
	MDGetNumericWavePointValueSInt64, MDGetNumericWavePointValueUInt64, or the
	direct access method as described for MDAccessNumericWaveData. See
	"64-bit Integer Issues" in the XOP Toolkit manual for further discussion.
	
	This routine is a companion to MDGetDPDataInNumericWave.
	
	The function result is zero or an error code.
	
	Thread Safety: MDStoreDPDataInNumericWave is Igor-thread-safe with XOP Toolkit 6 and Igor Pro 6.20 or later
	except for waves passed to threads as parameters. You can call it from a thread created
	by Igor but not from a private thread that you created yourself.
*/
int
MDStoreDPDataInNumericWave(waveHndl waveH, const double* dPtr)
{
	CountInt numNumbers;
	int bytesPerPoint;
	int waveType, type2;
	int destFormat;
	
	switch(WAVE_VERSION(waveH)) {
		case kWaveStruct3Version:
			waveType = WaveType(waveH);
			switch(waveType) {
				case TEXT_WAVE_TYPE:
					return NUMERIC_ACCESS_ON_TEXT_WAVE;
				case WAVE_TYPE:
				case DATAFOLDER_TYPE:
					return NUMERIC_ACCESS_ON_NON_NUMERIC_WAVE;
					break;
			}
			type2 = waveType & ~NT_CMPLX;
			switch(type2) {
				case NT_I8:
					bytesPerPoint = sizeof(char);
					destFormat = SIGNED_INT;
					break;
				case NT_I8 | NT_UNSIGNED:
					bytesPerPoint = sizeof(char);
					destFormat = UNSIGNED_INT;
					break;
				case NT_I16:
					bytesPerPoint = sizeof(short);
					destFormat = SIGNED_INT;
					break;
				case NT_I16 | NT_UNSIGNED:
					bytesPerPoint = sizeof(short);
					destFormat = UNSIGNED_INT;
					break;
				case NT_I32:
					bytesPerPoint = sizeof(SInt32);
					destFormat = SIGNED_INT;
					break;
				case NT_I32 | NT_UNSIGNED:
					bytesPerPoint = sizeof(UInt32);
					destFormat = UNSIGNED_INT;
					break;
				case NT_I64:
					bytesPerPoint = sizeof(SInt64);
					destFormat = SIGNED_INT;
					break;
				case NT_I64 | NT_UNSIGNED:
					bytesPerPoint = sizeof(UInt64);
					destFormat = UNSIGNED_INT;
					break;
				case NT_FP32:
					bytesPerPoint = sizeof(float);
					destFormat = IEEE_FLOAT;
					break;
				case NT_FP64:
					bytesPerPoint = sizeof(double);
					destFormat = IEEE_FLOAT;
					break;
				default:
					return WAVE_TYPE_INCONSISTENT;		/* Corrupted wave. */
			}
			numNumbers = WavePoints(waveH);
			if (waveType & NT_CMPLX)
				numNumbers *= 2;
			ConvertData(dPtr, WaveData(waveH), numNumbers, sizeof(double), IEEE_FLOAT, bytesPerPoint, destFormat);
			break;
		
		default:		/* Future version of Igor with a different wave structure. */
			return (int)CallBack2(MD_STOREDPDATAINNUMERICWAVE, waveH, (void*)dPtr);
			break;
	}
	return 0;
}

/*	MDGetTextWavePointValue(waveH, indices, textH)
	
	Returns via textH the value of a particular point in the specified wave.
	Any previous contents of textH are overwritten.
	
	If the wave is not a text wave, returns an error code and does not
	alter textH.
	
	indices is an array of dimension indices. For example, for a 3D wave,
		indices[0] should contain the row number
		indices[1] should contain the column number
		indices[2] should contain the layer number
	
	NOTE: This routine ignores indices for dimensions that do not exist in the wave.
	
	You must create textH before calling MDGetTextWavePointValue.
	For example:
		textH = WMNewHandle(0L);
	
	On output, if there is no error, textH contains a copy of the characters
	in the specified wave point. A point in an Igor text wave can contain
	any number of characters, including zero. Therefore, the handle can
	contain any number of characters. Igor text waves can contain any characters,
	including control characters. No characters codes are considered illegal.
	
	The characters in the handle are not null terminated. If you want
	to treat them as a C string, you should add a null character at the end.
	Make sure to remove any null termination if you pass the handle back to Igor.
		
	The function result is 0 or an error code.
	
	Thread Safety: MDGetTextWavePointValue is Igor-thread-safe with XOP Toolkit 6 and Igor Pro 6.20 or later
	except for waves passed to threads as parameters. You can call it from a thread created
	by Igor but not from a private thread that you created yourself.
*/
int
MDGetTextWavePointValue(waveHndl waveH, IndexInt indices[MAX_DIMENSIONS], Handle textH)
{
	return (int)CallBack3(MD_GETTEXTWAVEPOINTVALUE, waveH, indices, textH);
}

/*	MDSetTextWavePointValue(waveH, indices, textH)
	
	Transfers the characters in textH to the specified point in the specified
	wave. The contents of textH is not altered.
	
	If the wave is not a text wave, returns an error code.
	
	indices is an array of dimension indices. For example, for a 3D wave,
		indices[0] should contain the row number
		indices[1] should contain the column number
		indices[2] should contain the layer number
	
	NOTE: This routine ignores indices for dimensions that do not exist in the wave.
	
	A point in an Igor text wave can contain any number of characters, including zero.
	Therefore, the handle can contain any number of characters. Igor text waves can
	contain any characters, including control characters. No characters codes are
	considered illegal.
	
	The characters in the handle should not null terminated. If you have
	put a null terminator in the handle, remove it before calling MDSetTextWavePointValue.
	
	After calling MDSetTextWavePointValue, the handle is still yours so
	you should dispose it when you no longer need it.
		
	The function result is 0 or an error code.
	
	Thread Safety: MDSetTextWavePointValue is Igor-thread-safe with XOP Toolkit 6 and Igor Pro 6.20 or later
	except for waves passed to threads as parameters. You can call it from a thread created
	by Igor but not from a private thread that you created yourself.
*/
int
MDSetTextWavePointValue(waveHndl waveH, IndexInt indices[MAX_DIMENSIONS], Handle textH)
{
	return (int)CallBack3(MD_SETTEXTWAVEPOINTVALUE, waveH, indices, textH);
}

/*	GetTextWaveData(waveH, mode, textDataHPtr)

	Returns all of the text for the specified text wave via textDataHPtr.
	
	NOTE: This routine is for advanced programmers who are comfortable with
	pointer arithmetic and handles. Less experienced programmers should use
	MDGetTextWavePointValue to get the wave text values one at a time.
	
	If the function result is 0 then *textDataHPtr is a handle that you own.
	When you are finished, dispose of it using WMDisposeHandle.
	
	In the event of an error, the function result will be non-zero and
	*textDataHPtr will be NULL.
	
	The returned handle will contain the text for all of the wave's elements
	in one of several formats explained below. The format depends on the mode
	parameter.
	
	Modes 0 and 1 use a null byte to mark the end of a string and thus
	will not work if 0 is considered to be a legal character value.

	mode = 0
		The returned handle contains one C string (null-terminated) for each element
		of the wave.

		Example:
			"Zero"<null>
			"One"<null>
			"Two"<null>
	
	mode = 1
		The returned handle contains a list of 32-bit (in IGOR32) or 64-bit (in IGOR64)
		offsets to strings followed by the string data. There is one extra offset which
		is the offset to where the string would be for the next element if the wave had
		one more element.
		
		The text for each element in the wave is represented by a C string (null-terminated).
		
		Example:
			<Offset to "Zero">
			<Offset to "One">
			<Offset to "Two">
			<Extra offset>
			"Zero"<null>
			"One"<null>
			"Two"<null>
	
	mode = 2
		The returned handle contains a list of 32-bit (in IGOR32) or 64-bit (in IGOR64)
		offsets to strings followed by the string data.	There is one extra offset which
		is the offset to where the string would be for the next element if the wave had
		one more element.
		
		The text for each element in the wave is not null-terminated.
		
		Example:
			<Offset to "Zero">
			<Offset to "One">
			<Offset to "Two">
			<Extra offset>
			"Zero"
			"One"
			"Two"
			
	Using modes 1 and 2, you can determine the length of element i by subtracting
	offset i from offset i+1.
	
	You can convert the offsets into pointers to strings by adding
	**textDataHPtr to each of the offsets. However, since the handle in
	theory can be relocated in memory, you should lock the handle before
	converting to pointers and unlock it when you are done with it.
	
	For the purposes of GetTextWaveData, the wave is treated as a 1D wave
	regardless of its true dimensionality. If waveH a 2D text wave, the
	data returned via textDataHPtr is in column-major order. This means that
	the data for each row of the first column appears first in memory, followed
	by the data for the each row of the next column, and so on.
		
	Returns 0 or an error code.
	
	For an example using this routine, see TestGetAndSetTextWaveData below.
	
	Thread Safety: GetTextWaveData is Igor-thread-safe with XOP Toolkit 6 and Igor Pro 6.20 or later
	except for waves passed to threads as parameters. You can call it from a thread created
	by Igor but not from a private thread that you created yourself.
*/
int
GetTextWaveData(waveHndl waveH, int mode, Handle* textDataHPtr)
{
	return (int)CallBack3(GET_TEXT_WAVE_DATA, waveH, XOP_CALLBACK_INT(mode), textDataHPtr);
}

/*	SetTextWaveData(waveH, mode, textDataH)

	Sets all of the text for the specified text wave according to textDataH.
	
	NOTE: This routine is for advanced programmers who are comfortable with
	pointer arithmetic and handles. Less experienced programmers should use
	MDSetTextWavePointValue to set the wave text values one at a time.
	
	WARNING: If you pass inconsistent data in textDataH you will cause Igor to crash.
	
	SetTextWaveData can not change the number of points in the text wave.
	Therefore the data in textDataH must be consistent with the number of
	points in text wave. Otherwise a crash will occur.

	Also, when using modes 1 or 2, the offsets must be correct. Otherwise a
	crash will occur.
	
	Crashes caused by inconsistent data may occur at unpredictable times making
	it hard to trace it to the problem. So triple-check your code.
	
	You own the textDataH handle. When you are finished with it, dispose of it
	using WMDisposeHandle.
	
	The format of textDataH depends on the mode parameter. See the documentation
	for GetTextWaveData for a description of these formats.
	
	Modes 0 and 1 use a null byte to mark the end of a string and thus
	will not work if 0 is considered to be a legal character value.
		
	Returns 0 or an error code.
	
	For an example using this routine, see TestGetAndSetTextWaveData below.
	
	Thread Safety: SetTextWaveData is Igor-thread-safe with XOP Toolkit 6 and Igor Pro 6.20 or later
	except for waves passed to threads as parameters. You can call it from a thread created
	by Igor but not from a private thread that you created yourself.
*/
int
SetTextWaveData(waveHndl waveH, int mode, Handle textDataH)
{
	return (int)CallBack3(SET_TEXT_WAVE_DATA, waveH, XOP_CALLBACK_INT(mode), textDataH);
}

/*	TestGetAndSetTextWaveData(sourceWaveH, destWaveH, mode, echo)

	This routine is here just to give you and example of using GetTextWaveData
	and SetTextWaveData.
	
	If echo is true the contents of the source wave are printed in the history area.

	Then the data from the source wave is copied to the dest wave.
	
	Thread Safety: TestGetAndSetTextWaveData is Igor-thread-safe with XOP Toolkit 6 and Igor Pro 6.20 or later
	except for waves passed to threads as parameters. You can call it from a thread created
	by Igor but not from a private thread that you created yourself.
*/
#if 0	// This is just for testing
static int
TestGetAndSetTextWaveData(waveHndl sourceWaveH, waveHndl destWaveH, int mode, int echo)
{
	Handle textDataH;
	CountInt npnts;
	IndexInt* pTableOffset;
	char* pTextData;
	char message[256];
	int dataLen, prefixLen, availableBytes;
	int i;
	int err;
	
	if (WaveType(sourceWaveH) != TEXT_WAVE_TYPE)
		return TEXT_ACCESS_ON_NUMERIC_WAVE;
	
	if (WaveType(destWaveH) != TEXT_WAVE_TYPE)
		return TEXT_ACCESS_ON_NUMERIC_WAVE;
	
	npnts = WavePoints(sourceWaveH);
	
	if (err = ChangeWave(destWaveH, npnts, TEXT_WAVE_TYPE))
		return err;
	
	if (err = GetTextWaveData(sourceWaveH, mode, &textDataH))
		return err;
		
	pTableOffset = (PSInt*)*textDataH;					// Pointer to table of offsets if mode==1 or mode==2
	pTextData = *textDataH;
	if (mode > 0)
		pTextData += (npnts+1) * sizeof(PSInt);
		
	for(i=0; i<npnts; i+=1) {
		switch(mode) {
			case 0:
				dataLen = strlen(pTextData);
				break;
			
			case 1:
				dataLen = pTableOffset[i+1] - pTableOffset[i];
				dataLen -= 1;							// Exclude null terminator.
				break;

			case 2:
				dataLen = pTableOffset[i+1] - pTableOffset[i];
				break;	
		}

		if (echo) {
			snprintf(message, sizeof(message), "Element %d: ", i);
			prefixLen = strlen(message);
			availableBytes = sizeof(message) - prefixLen - 1 - 1;		// Allow 1 for CR and 1 for null terminator.
			if (dataLen > availableBytes)
				dataLen = availableBytes;
			memcpy(message+prefixLen, pTextData, dataLen);
			message[prefixLen + dataLen] = 0x0D;
			message[prefixLen + dataLen+1] = 0;
			XOPNotice(message);
		}
		
		switch(mode) {
			case 0:
				pTextData += dataLen + 1;
				break;
			
			case 1:
				pTextData += dataLen + 1;
				break;

			case 2:
				pTextData += dataLen;
				break;	
		}		
	}
	
	err = SetTextWaveData(destWaveH, mode, textDataH);

	WMDisposeHandle(textDataH);
	return err;
}
#endif

/*	GetWaveDimensionLabels(waveH, dimLabelsHArray)

	dimLabelsHArray points to an array of MAX_DIMENSIONS handles. GetWaveDimensionLabels
	sets each element of this array to a handle containing dimension labels or to NULL.
	
	On output, if the function result is 0 (no error), dimLabelsHArray[i] will be a
	handle containing dimension labels for dimension i or NULL if dimension i has no
	dimension labels.
	
	If the function result is non-zero then all handles in dimLabelsHArray will be NULL.
	
	Any non-NULL output handles belong to you. Dispose of them with WMDisposeHandle
	when you are finished with them.
	
	For each dimension, the corresponding dimension label handle consists of
	an array of N+1 C strings, each in a field of (MAX_DIM_LABEL_BYTES+1) bytes.
	
	The first label is the overall dimension label for that dimension.
	
	Label i+1 is the dimension label for element i of the dimension.
	
	N is the smallest number such that the last non-empty dimension label
	for a given dimension and all dimension labels before it, whether empty
	or not, can be stored in the handle.
	
	For example, if a 5 point 1D wave has dimension labels for rows 0 and 2
	with all other dimension labels being empty then dimLabelsHArray[0] will
	contain four dimension labels, one for the overall dimension and three
	for rows 0 through 2. dimLabelsHArray[0] will not contain any storage
	for any point after row 2 because the remaining dimension labels for
	that dimension are empty.
		
	Returns 0 or an error code.
	
	For an example using this routine, see TestGetAndSetWaveDimensionLabels below.
	
	Thread Safety: GetWaveDimensionLabels is Igor-thread-safe with XOP Toolkit 6 and Igor Pro 6.20 or later
	except for waves passed to threads as parameters. You can call it from a thread created
	by Igor but not from a private thread that you created yourself.
*/
int
GetWaveDimensionLabels(waveHndl waveH, Handle dimLabelsHArray[MAX_DIMENSIONS])
{
	return (int)CallBack2(GET_WAVE_DIMENSION_LABELS, waveH, dimLabelsHArray);
}

/*	SetWaveDimensionLabels(waveH, dimLabelsHArray)

	dimLabelsHArray points to an array of MAX_DIMENSIONS handles. SetWaveDimensionLabels
	sets the dimension labels for each existing dimension of waveH based on the
	corresponding handle in dimLabelsHArray.
	
	The handles in dimLabelsHArray belong to you. Dispose of them with WMDisposeHandle
	when you are finished with them.
	
	See the documentation for GetWaveDimensionLabels for a discussion of how
	the dimension labels are stored in the handles.
		
	Returns 0 or an error code.
	
	For an example using this routine, see TestGetAndSetWaveDimensionLabels below.
	
	Thread Safety: SetWaveDimensionLabels is Igor-thread-safe with XOP Toolkit 6 and Igor Pro 6.20 or later
	except for waves passed to threads as parameters. You can call it from a thread created
	by Igor but not from a private thread that you created yourself.
*/
int
SetWaveDimensionLabels(waveHndl waveH, Handle dimLabelsHArray[MAX_DIMENSIONS])
{
	return (int)CallBack2(SET_WAVE_DIMENSION_LABELS, waveH, dimLabelsHArray);
}

/*	TestGetAndSetWaveDimensionLabels(sourceWaveH, destWaveH, echo)

	This routine is here just to give you and example of using GetWaveDimensionLabels
	and SetWaveDimensionLabels.
	
	If echo is true the source wave's dimension labels are printed in the history area.
	
	Then the dimension labels are copied from the source to the dest wave.
	
	Thread Safety: TestGetAndSetWaveDimensionLabels is Igor-thread-safe with XOP Toolkit 6 and Igor Pro 6.20 or later
	except for waves passed to threads as parameters. You can call it from a thread created
	by Igor but not from a private thread that you created yourself.
*/
#if 0	// This is just for testing
static int
TestGetAndSetWaveDimensionLabels(waveHndl sourceWaveH, waveHndl destWaveH, int echo)
{
	Handle dimLabelsH;
	CountInt dimSizes[MAX_DIMENSIONS+1];
	CountInt numLabels;
	IndexInt element;
	int dim, numDimensions;
	Handle dimLabelsHArray[MAX_DIMENSIONS];
	char label[MAX_DIM_LABEL_BYTES+1];
	char message[256];
	int err;
	
	if (err = MDGetWaveDimensions(sourceWaveH, &numDimensions, dimSizes))
		return err;
	
	if (err = MDChangeWave(destWaveH, WaveType(destWaveH), dimSizes))
		return err;
	
	if (err = GetWaveDimensionLabels(sourceWaveH, dimLabelsHArray))
		return err;
		
	if (echo) {
		for(dim=0; dim<numDimensions; dim+=1) {
			dimLabelsH = dimLabelsHArray[dim];
			if (dimLabelsH == NULL) {
				snprintf(message, sizeof(message), "Dimension %d has no labels" CR_STR, dim);
				XOPNotice(message);
			}
			else {
				numLabels = WMGetHandleSize(dimLabelsH) / (MAX_DIM_LABEL_BYTES+1);
				for(element=-1; element<(numLabels-1); element++) {
					strcpy(label, *dimLabelsH + (element+1)*(MAX_DIM_LABEL_BYTES+1));
					snprintf(message, sizeof(message), "Dimension %d, element %lld = '%s'" CR_STR, dim, (SInt64)element, label);
					XOPNotice(message);				
				}
			}
		}
	}
		
	err = SetWaveDimensionLabels(destWaveH, dimLabelsHArray);

	// We own the label handles and thus must dispose of them.
	for(dim=0; dim<numDimensions; dim+=1) {
		dimLabelsH = dimLabelsHArray[dim];
		if (dimLabelsH != NULL)
			WMDisposeHandle(dimLabelsH);
	}
	
	return err;
}
#endif

/*	HoldWave(waveH)
	
	waveH is a wave handle that you have obtained from Igor.
	
	As of XOP Toolkit 6.30, if waveH is NULL, HoldWave does nothing and returns 0.

	HoldWave tells Igor that you are holding a reference to a wave and that the wave
	should not be deleted until you release it by calling ReleaseWave. This prevents
	a crash that would occur if Igor deleted a wave to which you held a handle and
	you later used that handle.
	
	In most XOP programming, such as a straight-forward external operation
	or external function, you do not need to call HoldWave/ReleaseWave. If you are just
	using the wave handle temporarily during the execution of your external function
	or operation and you make no calls that could potentially delete the wave then
	you do not need to and should not call HoldWave and ReleaseWave.
	
	You need to call HoldWave/ReleaseWave only if you are storing a wave handle over
	a period during which Igor could delete the wave. For example, you might indefinitely
	store a wave handle in a global variable or you might do a callback, such as XOPCommand,
	that could cause the wave to be deleted. In such cases, call HoldWave to prevent Igor
	from deleting the wave until you are finished with it. Then call ReleaseWave to permit
	Igor to delete the wave.
	
	For background information and further detail, please see "Wave Reference Counting"
	in the Accessing Igor Data chapter of the XOP Toolkit manual.

	HoldWave returns an error code as the function result, typically 0 for success or
	IGOR_OBSOLETE.
	
	HoldWave was added in Igor Pro 6.20. If you call this with an earlier version of Igor,
	it will return IGOR_OBSOLETE and do nothing.
	
	Prior to XOP Toolkit 6.30, HoldWave had a second parameter. That parameter was removed
	in XOP Toolkit 6.30. This change does not affect XOPs compiled with earlier versions
	of the XOP Toolkit. It will cause a compile error that you will have to correct
	if you compile with XOP Toolkit 6.30 or later.
	
	Thread Safety: HoldWave is Igor-thread-safe with XOP Toolkit 6 and Igor Pro 6.20 or later
	except for waves passed to threads as parameters. You can call it from a thread created
	by Igor but not from a private thread that you created yourself.
*/
int
HoldWave(waveHndl waveH)
{
	waveHndl tempWaveH = NULL;
	if (waveH == NULL)
		return 0;
	return (int)CallBack2(HOLD_WAVE, waveH, &tempWaveH);
}

/*	ReleaseWave(waveRefPtr)

	Tells Igor that you are no longer holding a wave.
	
	waveRefPtr contains the address of your waveHndl variable that refers to a wave.
	ReleaseWave sets *waveRefPtr to NULL so your waveHndl variable is not valid
	after you call ReleaseWave.
	
	If *waveRefPtr is NULL on input then ReleaseWave does nothing and returns 0.
	
	See HoldWave for a detailed discussion.

	ReleaseWave returns an error code as the function result, typically 0 for success or
	IGOR_OBSOLETE.
	
	ReleaseWave was added in Igor Pro 6.20. If you call this with an earlier version of Igor,
	it will return IGOR_OBSOLETE and do nothing.
	
	Thread Safety: ReleaseWave is Igor-thread-safe with XOP Toolkit 6 and Igor Pro 6.20 or later
	except for waves passed to threads as parameters. You can call it from a thread created
	by Igor but not from a private thread that you created yourself.
*/
int
ReleaseWave(waveHndl* waveRefPtr)
{
	if (*waveRefPtr == NULL)
		return 0;				// Nothing to release.
	return (int)CallBack1(RELEASE_WAVE, waveRefPtr);
}

/*	WaveTextEncoding(waveH, element, getEffectiveTextEncoding, tecPtr)

	Returns via tecPtr a WMTextEncodingCode that identifies the text encoding of the stored
	text associated with the part of a wave identified by element.
	
	WMTextEncodingCode is an enum defined in IgorXOP.h.
	
	element is one of the following:
		1:	Wave name
		2:	Wave units
		4:	Wave note
		8:	Wave dimension labels
		16:	Text wave contents
		
	If getEffectiveTextEncoding is 1, WaveTextEncoding returns the effective wave
	text encoding. Otherwise it returns the raw wave text encoding. See the
	help for the built-in Igor7 WaveTextEncoding function for an explanation of
	this distinction.
		
	The values returned via tecPtr are described in the documentation for the built-in
	Igor WaveTextEncoding function in Igor Pro 7. The most common values are:
		kWMTextEncodingUTF8						UTF-8
		kWMTextEncodingMacRoman					MacRoman (Macintosh western European)
		kWMTextEncodingWindows1252				Windows-1252 (Windows western European)
		kWMTextEncodingJIS						Shift-JIS (Japanese)
		kWMTextEncodingBinary

	kWMTextEncodingBinary is not a real text encoding code but rather indicates that the wave
	contains binary data rather than text data.

	Because nearly all XOPSupport routines, when running with Igor7, require text parameters to
	be UTF-8 and return output text as UTF-8, most XOPs will not need to use this routine.
	
	See the XOP Toolkit 7 Text Encodings section and the documentation for the built-in Igor7
	WaveTextEncoding function for further information.
	
	The function result is 0 or an error code.
	
	Added for Igor Pro 7.00. If you call this with an earlier version of Igor,
	it will return IGOR_OBSOLETE and do nothing.
	
	Thread Safety: WaveTextEncoding is Igor-thread-safe with XOP Toolkit 7 and Igor Pro 7.00
	or later except for waves passed to threads as parameters. You can call it from a thread
	created by Igor but not from a private thread that you created yourself.
*/
int
WaveTextEncoding(waveHndl waveH, int element, int getEffectiveTextEncoding, int* tecPtr)
{
	return (int)CallBack4(WAVE_TEXT_ENCODING, waveH, XOP_CALLBACK_INT(element), XOP_CALLBACK_INT(getEffectiveTextEncoding), tecPtr);
}

/*	WaveMemorySize(waveH, which)

	Most XOPs will not need this function.
	
	In Igor Pro 6 and before wave handles were regular handles. Although there was
	little reason to do so, you could call WMGetHandleSize on them and get a correct
	answer.
	
	In Igor Pro 7, to support 64 bits on Macintosh, WaveMetrics had to change the
	way a wave's data was allocated. As a result, a wave handle is no longer
	a regular handle. Calling WMGetHandleSize on it will return the wrong result
	or crash. 
	
	This function provides a way to get information about the memory occupied by
	a wave that will work in Igor Pro 7 as well as in earlier versions.
	
	which is defined as follows:
		0:	Returns the size in bytes of the wave handle itself
		1:	Returns the size in bytes of the wave header
		2:	Returns the size in bytes of the wave numeric or text data
		3:	Returns the size in bytes of the wave handle plus the numeric or text data
		4:	Returns the total number of bytes required to store all wave data (IP7 only)

	The total number of bytes includes the memory required for ancillary wave properties
	such as the wave note, wave units and dimension labels. This is available when
	running with Igor Pro 7 or later. In Igor Pro 6, which=4 acts the same as
	which=3.
	
	which=2 returns the size of numeric data for numeric a wave and the size of
	text data for a text wave.
		
	which=4 returns the most accurate assessment of the total memory usage of the wave.
	This is because, in Igor Pro 7 and later, it includes ancillary data and also because,
	in some cases as explained below, the data for text waves is stored in separate objects,
	not in the wave handle itself.
	
	In Igor Pro 7, the size of the wave handle itself may not accurately reflect
	the amount of memory required by a text wave. This is because, in most cases,
	Igor Pro 7 stores the text data for each element in a separate text element
	object and stores pointers to the text element objects in the wave handle
	itself. Thus the size of the wave handle itself reflects the storage needed
	for the pointers, not the storage needed for the actual text.
	
	In Igor Pro 7 determining the size of text data for a large text wave, using
	which=2, which=3 or which=4, can be time-consuming. This is because, in most cases,
	Igor Pro 7 stores the data for each element of the wave in a separate text
	element object and stores pointers to the text element objects in the wave
	handle itself. Thus Igor must determine the sum of the sizes of each of the objects.
	
	Added in XOP Toolkit 6.40. Works with Igor Pro 3 or later.
*/
BCInt
WaveMemorySize(waveHndl waveH, int which)
{
	CountInt sizeInBytes = 0;
	
	if (waveH == NULL)
		return 0;								// XOP programmer error
	
	if (igorVersion >= 700) {
		sizeInBytes = (CountInt)CallBack2(WAVE_MEMORY_SIZE, waveH, XOP_CALLBACK_INT(which));
		return sizeInBytes;
	}

	// Igor Pro 6 or before
	if (WAVE_VERSION(waveH) != kWaveStruct3Version)
		return 0;								// Running with Igor 1 or Igor 2 - should never happen
	
	switch(which) {
		case 0:									// Size in bytes of the wave handle itself
			sizeInBytes = WMGetHandleSize((Handle)waveH);
			break;
	
		case 1:									// Size in bytes of the wave header
			#ifdef IGOR64
				sizeInBytes = 400;
			#else
				sizeInBytes = 320;
			#endif
			break;
	
		case 2:									// Size in bytes of the wave numeric or text data
			// The numeric or text data is stored in the wave handle after the header
			sizeInBytes = WMGetHandleSize((Handle)waveH);
			#ifdef IGOR64
				sizeInBytes -= 400;
			#else
				sizeInBytes -= 320;
			#endif
			break;
	
		case 3:									// Size in bytes of the wave handle plus the numeric or text data
		case 4:									// Total memory required. In Igor Pro 6 and before which=4 is treated as which=3.
			sizeInBytes = WMGetHandleSize((Handle)waveH);
			break;
	
		default:
			break;								// Programmer error
	}

	return sizeInBytes;
}

