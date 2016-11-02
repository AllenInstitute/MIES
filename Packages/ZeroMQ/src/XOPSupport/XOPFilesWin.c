/*	Contains platform-specific file-related routines.
	Platform-independent file-related routines are in XOPFiles.c
*/

#include "XOPStandardHeaders.h"			// Include ANSI headers, Mac headers, IgorXOP.h, XOP.h and XOPSupport.h

static int
ConvertWCHARCStringToUTF8(const WCHAR* source, int destBufSizeInBytes, char* dest)
{
	int err = 0;
	int numSourceWCHARs = (int)wcslen(source) + 1;			// +1 for null terminator
	DWORD conversionFlags = 0x80;							// 0x80 = WC_ERR_INVALID_CHARS. It is defined only if WINVER >= 0x0600 and supported in Vista or later.
	int result = WideCharToMultiByte(CP_UTF8, conversionFlags, source, numSourceWCHARs, dest, destBufSizeInBytes, NULL, NULL);
	if (result == 0) {
		err = TEXT_ENCODING_CONVERSION_ERROR;
		if (destBufSizeInBytes >= 1)
			*dest = 0;
	}
	return err;
}

static int
ConvertUTF8CStringToWCHAR(const char* source, int destBufSizeInBytes, WCHAR* dest)
{
	int err = 0;
	int numSourceBytes = (int)strlen(source) + 1;			// +1 for null terminator
	int destSizeInWCHARs = destBufSizeInBytes / 2;
	int result = MultiByteToWideChar(CP_UTF8, 0, source, numSourceBytes, dest, destSizeInWCHARs);
	if (result == 0) {
		err = TEXT_ENCODING_CONVERSION_ERROR;
		if (destBufSizeInBytes >= 2)
			*dest = 0;
	}
	return err;
}

/*	XOPCreateFile(fullFilePath, overwrite, macCreator, macFileType)

	Creates a file with the location and name specified by fullFilePath.
	
	fullFilePath must be an HFS path (using colon separators) on Macintosh and a Windows path
	(using backslashes) on Windows.
	
	On Macintosh, the elements of fullFilePath may exceed the normal HFS 31 character limit.

	If overwrite is true and a file by that name already exists, it first
	deletes the conflicting file. If overwrite is false and a file by that
	name exists, it returns an error.
	
	macFileType is ignored on Windows. On Macintosh, it is used to set
	the new file's type. For example, use 'TEXT' for a text file.
	
	macCreator is ignored on Windows. On Macintosh, it is used to set
	the new file's creator code. For example, use 'IGR0' (last character is zero)
	for an file.
	
	Returns 0 if OK or an error code.
	
	Thread Safety: XOPCreateFile is thread-safe with Igor Pro 6.20 or later.
*/
int
XOPCreateFile(const char* fullFilePath, int overwrite, int macCreator, int macFileType)
{
	HANDLE fileH;
	DWORD accessMode, shareMode;
	int err;
	
	if (FullPathPointsToFile(fullFilePath)) {
		if (overwrite) {
			if (err = XOPDeleteFile(fullFilePath))
				return err;
		}
		else {
			return FILE_CREATE_ERROR;
		}
	}
	
	err = 0;
	accessMode = GENERIC_READ | GENERIC_WRITE;
	shareMode = 0;
	if (igorVersion >= 700) {
		// In Igor7 and later text is assumed to be UTF-8. This requires that we use the Unicode version of Windows routines.
		WCHAR fullFilePathW[MAX_PATH_LEN+1];
		err = ConvertUTF8CStringToWCHAR(fullFilePath, sizeof(fullFilePathW), fullFilePathW);
		if (err != 0)
			return err;
		fileH = CreateFileW(fullFilePathW, accessMode, shareMode, NULL, CREATE_NEW, FILE_ATTRIBUTE_NORMAL, NULL);
	}	
	else {
		// In Igor6 and before text is assumed to be system text encoding.
		fileH = CreateFileA(fullFilePath, accessMode, shareMode, NULL, CREATE_NEW, FILE_ATTRIBUTE_NORMAL, NULL);
	}
	if (fileH == INVALID_HANDLE_VALUE)
		err = WMGetLastError();
	else
		CloseHandle(fileH);
	return err;
}

/*	XOPDeleteFile(fullFilePath)

	Deletes the file specified by fullFilePath.
	
	fullFilePath must be an HFS path (using colon separators) on Macintosh and a Windows path
	(using backslashes) on Windows.
	
	On Macintosh, the elements of fullFilePath may exceed the normal HFS 31 character limit.
	
	Returns 0 if OK or an error code.
	
	Thread Safety: XOPDeleteFile is thread-safe with Igor Pro 6.20 or later.
*/
int
XOPDeleteFile(const char* fullFilePath)
{
	int err;

	err = 0;
	if (igorVersion >= 700) {
		// In Igor7 and later text is assumed to be UTF-8. This requires that we use the Unicode version of Windows routines.
		WCHAR fullFilePathW[MAX_PATH_LEN+1];
		err = ConvertUTF8CStringToWCHAR(fullFilePath, sizeof(fullFilePathW), fullFilePathW);
		if (err != 0)
			return err;
		if (DeleteFileW(fullFilePathW) == 0)
			err = WMGetLastError();
	}	
	else {
		// In Igor6 and before text is assumed to be system text encoding.
		if (DeleteFileA(fullFilePath) == 0)
			err = WMGetLastError();
	}
	return err;
}

/*	XOPOpenFile(fullFilePath, readOrWrite, fileRefPtr)

	If readOrWrite is zero, opens an existing file for reading and returns a file reference
	via fileRefPtr.

	If readOrWrite is non-zero, opens an existing file for writing or creates a new
	file if none exists and returns a file reference via fileRefPtr.

	fullFilePath must be an HFS path (using colon separators) on Macintosh and a Windows path
	(using backslashes) on Windows.
	
	On Macintosh, the elements of fullFilePath may exceed the normal HFS 31 character limit.
	
	Returns 0 if OK or an error code.
	
	Thread Safety: XOPOpenFile is thread-safe. It can be called from any thread.
*/
int
XOPOpenFile(const char* fullFilePath, int readOrWrite, XOP_FILE_REF* fileRefPtr)
{
	if (strlen(fullFilePath) > MAX_PATH_LEN)
		return PATH_TOO_LONG;

	if (igorVersion >= 700) {
		// In Igor7 and later text is assumed to be UTF-8. This requires that we use the Unicode version of Windows routines.
		WCHAR fullFilePathW[MAX_PATH_LEN+1];
		int err = ConvertUTF8CStringToWCHAR(fullFilePath, sizeof(fullFilePathW), fullFilePathW);
		if (err != 0)
			return err;
		// Other than taking a Unicode path, _wfopen behaves identically to fopen
		*fileRefPtr = _wfopen(fullFilePathW, readOrWrite ? L"wb" : L"rb");
	}	
	else {
		// In Igor6 and before text is assumed to be system text encoding.
		*fileRefPtr = fopen(fullFilePath, readOrWrite ? "wb" : "rb");
	}
	if (*fileRefPtr == NULL)
		return FILE_OPEN_ERROR;
	return 0;
}

/*	FullPathPointsToFile(fullPath)

	Returns 1 if the path points to an existing file, 0 if it points to a folder or
	does not point to anything.
	
	fullPath may be a Macintosh or a Windows path.

	This routine is typically used by a file-loader XOP when it decides if it has
	enough information to load the file or needs to display an Open File dialog.	
	
	Thread Safety: FullPathPointsToFile is thread-safe with Igor Pro 6.20 or later.
*/
int
FullPathPointsToFile(const char* fullPath)
{
	char nativePath[MAX_PATH_LEN+1];
	DWORD attributes;
	int err;
	
	if (err = GetNativePath(fullPath, nativePath))
		return err;

	if (igorVersion >= 700) {
		// In Igor7 and later text is assumed to be UTF-8. This requires that we use the Unicode version of Windows routines.
		WCHAR nativePathW[MAX_PATH_LEN+1];
		err = ConvertUTF8CStringToWCHAR(nativePath, sizeof(nativePathW), nativePathW);
		if (err != 0)
			return err;
		attributes = GetFileAttributesW(nativePathW);
	}	
	else {
		// In Igor6 and before text is assumed to be system text encoding.
		attributes = GetFileAttributesA(nativePath);
	}
	if (attributes == 0xFFFFFFFF)					// Error?
		return 0;

	if ((attributes & FILE_ATTRIBUTE_DIRECTORY) != 0)
		return 0;									// Points to a folder.
	
	return 1;
}

/*	FullPathPointsToFolder(fullPath)

	Returns true if the path points to an existing folder, false if it points to a file or
	does not point to anything.
	
	fullPath may be a Macintosh or a Windows path.
	
	Thread Safety: FullPathPointsToFolder is thread-safe with Igor Pro 6.20 or later.
*/
int
FullPathPointsToFolder(const char* fullPath)
{
	char nativePath[MAX_PATH_LEN+1];
	DWORD attributes;
	int err;
	
	if (err = GetNativePath(fullPath, nativePath))
		return err;

	if (igorVersion >= 700) {
		// In Igor7 and later text is assumed to be UTF-8. This requires that we use the Unicode version of Windows routines.
		WCHAR nativePathW[MAX_PATH_LEN+1];
		err = ConvertUTF8CStringToWCHAR(nativePath, sizeof(nativePathW), nativePathW);
		if (err != 0)
			return err;
		attributes = GetFileAttributesW(nativePathW);
	}	
	else {
		// In Igor6 and before text is assumed to be system text encoding.
		attributes = GetFileAttributesA(nativePath);
	}
	if (attributes == 0xFFFFFFFF)					// Error?
		return 0;

	if ((attributes & FILE_ATTRIBUTE_DIRECTORY) == 0)
		return 0;									// Points to a file.
	
	return 1;
}

/*	GetNativePath(filePathIn, filePathOut)
	
	Call this to make sure that a file path uses the conventions regarding
	colons and backslashes of the current platform.
	
	It copies filePathIn to filePathOut. If filePathIn does not use the conventions
	of the current platform, it converts filePathOut to use those conventions.
	
	filePathOut can point to the same memory as filePathIn or it can
	point to different memory.
	
	filePathOut must be declared to hold MAX_PATH_LEN+1 characters.
	
	Function result is 0 if OK or an error code (e.g., PATH_TOO_LONG).
	
	Thread Safety: GetNativePath is thread-safe with Igor Pro 6.20 or later.
*/
int
GetNativePath(const char* filePathIn, char filePathOut[MAX_PATH_LEN+1])
{
	int err;
	
	if (strlen(filePathIn) > MAX_PATH_LEN)
		return PATH_TOO_LONG;
		
	if (filePathOut != filePathIn)
		strcpy(filePathOut, filePathIn);
	
	err = MacToWinPath(filePathOut);

	return err;
}
