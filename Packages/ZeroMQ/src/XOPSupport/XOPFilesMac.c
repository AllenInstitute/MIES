/*	Contains platform-specific file-related routines.
	Platform-independent file-related routines are in XOPFiles.c
*/

#include "XOPStandardHeaders.h"			// Include ANSI headers, Mac headers, IgorXOP.h, XOP.h and XOPSupport.h

static CFStringEncoding
GetIgorTextEncoding(void)
{
	CFStringEncoding encoding;
	
	if (igorVersion < 700) {
		// Text in Igor Pro 6 uses system text encoding as set in the Language&Text control panel
		encoding = CFStringGetSystemEncoding();
	}
	else {
		// Text in Igor Pro 7 is UTF-8
		encoding = kCFStringEncodingUTF8;
	}
	return encoding;
}

/*	HFSToPosixPath(hfsPath, posixPath[MAX_PATH_LEN+1], isDirectory)

	Converts an HFS (colon-separated) path into a POSIX (Unix-style) path.
	This is used only on Mac OS X and only to convert paths into POSIX paths
	so that we can pass them to the standard file routines fopen.
	
	It is allowed for hfsPath and posixPath to point to the same memory.
	
	From the point of view of the Igor user, all paths should be HFS paths
	although Windows paths are accepted and converted when necessary. POSIX
	paths are not valid paths in Igor procedures.		
	
	When running with Igor Pro 6, hfsPath is assumed to be encoded as system
	text encoding as set by the preferred language in the Language&Text control panel.
	
	When running with Igor Pro 7, hfsPath is assumed to be encoded as UTF-8.
	
	posixPath is always encoded as UTF-8.
	
	Returns 0 if OK or an error code. If an error is returned, *posixPath is undefined.
	
	Thread Safety: HFSToPosixPath is thread-safe. It can be called from any thread.
*/
int
HFSToPosixPath(const char* hfsPath, char posixPath[MAX_PATH_LEN+1], int isDirectory)
{
	CFStringRef cfHFSPath = NULL;
	CFURLRef cfURLPath = NULL;
	CFStringEncoding encoding = GetIgorTextEncoding();	// UTF-8 in Igor7, system text encoding in Igor6
	int err;
	
	err = 0;
	
	cfHFSPath = CFStringCreateWithCString(NULL, hfsPath, encoding);
	if (cfHFSPath == NULL) {
		err = NOMEM;								// We have no way to know what the real error is.
		goto done;
	}

	// Make a CFURLRef from the CFString representation of the bundle's path.
	cfURLPath = CFURLCreateWithFileSystemPath(NULL, cfHFSPath, kCFURLHFSPathStyle, isDirectory);
	if (cfURLPath == NULL) {
		err = FILE_OPEN_ERROR;						// We have no way to know what the real error is.
		goto done;
	}
	
	// Apple's documentation does not say it but the output path uses UTF-8 encoding.
	if (CFURLGetFileSystemRepresentation(cfURLPath, 1, (unsigned char*)posixPath, MAX_PATH_LEN) == 0)
		err = PATH_TOO_LONG;

done:
	if (cfHFSPath != NULL)
		CFRelease(cfHFSPath);
	if (cfURLPath != NULL)
		CFRelease(cfURLPath);
	return err;
}

/*	ConvertIgorTextEncodingToUTF2(text, textLength, unicodeText, maxUnicodeBytes, unicodeLengthPtr)

	Thread Safety: ConvertIgorTextEncodingToUTF2 is thread-safe. It can be called from any thread.
*/
static int
ConvertIgorTextEncodingToUTF2(const char* text, int textLength, UniChar* unicodeText, int maxUnicodeBytes, int* unicodeLengthPtr)
{
	CFStringRef ref;
	CFRange range;
	CFIndex numChars, usedBufferLength=0;
	CFStringEncoding encoding = GetIgorTextEncoding();	// UTF-8 in Igor7, system text encoding in Igor6
	
	*unicodeLengthPtr = 0;
	if (textLength <= 0)
		return 0;
	
	ref = CFStringCreateWithBytes(NULL, (UInt8*)text, textLength, encoding, 0);
	if (ref == NULL)
		return GENERAL_BAD_VIBS;							// Should never happen.
	
	range = CFRangeMake(0, CFStringGetLength(ref));
	numChars = CFStringGetBytes(ref, range, kCFStringEncodingUnicode, '?', 0, (UInt8*)unicodeText, maxUnicodeBytes, &usedBufferLength);

	CFRelease(ref);

	if (numChars <= 0)
		return GENERAL_BAD_VIBS;							// Should never happen.

	*unicodeLengthPtr = usedBufferLength / 2;

	return 0;
}

/*	ConvertUTF2ToIgorTextEncoding(unicodeText, unicodeLength, text, maxTextBytes, textLengthPtr)

	Returns via text a null-terminated string in the system encoding.

	maxTextBytes is the maximum number of bytes of text in the returned string, not including the null terminator.
	
	*textLengthPtr is set to the number of returned text bytes, not including the null terminator.
	
	Thread Safety: ConvertUTF2ToIgorTextEncoding is thread-safe. It can be called from any thread.
*/
static int
ConvertUTF2ToIgorTextEncoding(UniChar* unicodeText, int unicodeLength, char* text, int maxTextBytes, int* textLengthPtr)
{
	CFStringRef ref;
	CFRange range;
	CFIndex numChars, usedBufferLength=0;
	CFStringEncoding encoding = GetIgorTextEncoding();	// UTF-8 in Igor7, system text encoding in Igor6
	
	*text = 0;
	*textLengthPtr = 0;
	if (unicodeLength <= 0)
		return 0;
	
	ref = CFStringCreateWithBytes(NULL, (UInt8*)unicodeText, 2*unicodeLength, kCFStringEncodingUnicode, 0);
	if (ref == NULL)
		return GENERAL_BAD_VIBS;							// Should never happen.
	
	range = CFRangeMake(0, CFStringGetLength(ref));
	numChars = CFStringGetBytes(ref, range, encoding, '?', 0, (UInt8*)text, maxTextBytes, &usedBufferLength);

	CFRelease(ref);

	if (numChars <= 0)
		return GENERAL_BAD_VIBS;							// Should never happen.

	text[usedBufferLength] = 0;
	*textLengthPtr = usedBufferLength;

	return 0;
}

/*	MacFSRefToFullHFSPath(fsRefPtr, pathOut)

	fsRefPtr refers to an existing file or folder.
	
	Sets pathOut to refer to the file or folder. If *fsRefPtr refers to a folder then
	pathOut will include a trailing colon.
	
	NOTE: MAX_PATH_LEN must hold MAX_PATH_LEN characters plus a null terminator.
	
	When running with Igor Pro 6, pathOut is encoded as system text encoding.
	
	When running with Igor Pro 7, pathOut is encoded as UTF-8.
	
	Returns 0 if OK or an error code.	

	Thread Safety: MacFSRefToFullHFSPath is thread-safe. It can be called from any thread.
*/
static int
MacFSRefToFullHFSPath(FSRef* fsRefPtr, char* pathOut)
{
	FSRef parentFSRef;
	HFSUniStr255 unicodeName;
	FSCatalogInfo catalogInfo;
	FSCatalogInfoBitmap whichInfo;
	int isDirectory = 0;
	char element[MAX_FILENAME_LEN+1];
	int elementNumber, elementLength;
	int pathOutLength;
	int err;
	
	MemClear(pathOut, MAX_PATH_LEN+1);
	pathOutLength = 0;
	
	elementNumber = 0;
	
	while(1) {
		whichInfo = kFSCatInfoNodeFlags | kFSCatInfoParentDirID;
		if (err = FSGetCatalogInfo(fsRefPtr, whichInfo, &catalogInfo, &unicodeName, NULL, &parentFSRef))
			return err;
		
		if (elementNumber == 0)		// Element 0 is the leaf of the path.
			isDirectory = (catalogInfo.nodeFlags & kFSNodeIsDirectoryMask) != 0;
			
		if (err = ConvertUTF2ToIgorTextEncoding(unicodeName.unicode, unicodeName.length, element, sizeof(element)-1, &elementLength))
			return err;
		
		if (elementLength + pathOutLength > MAX_PATH_LEN)
			return PATH_TOO_LONG;
		
		if (elementNumber == 0) {
			strcpy(pathOut, element);
			pathOutLength = elementLength;
		}
		else {
			memmove(pathOut+elementLength+1, pathOut, pathOutLength);
			memcpy(pathOut, element, elementLength);
			pathOut[elementLength] = ':';
			pathOutLength += elementLength + 1;
		}
		
		if (catalogInfo.parentDirID == fsRtParID)
			break;									// We just handled the root of the volume.
			
		fsRefPtr = &parentFSRef;
			
		elementNumber += 1;
	}
	
	if (isDirectory) {
		if (strlen(pathOut) >= MAX_PATH_LEN)
			return PATH_TOO_LONG;
		strcat(pathOut, ":");						// Add trailing colon.
	}
				
	return 0;
}

/*	FullHFSPathToMacFSRef(hfsPath, fsRefPtr)

	pathIn uses HFS syntax (colon separators) and must point to an existing file or folder.
	However the elements of pathIn may exceed the normal HFS 31 character limit.
	
	Sets fsRefPtr to refer to the file or folder.
	
	When running with Igor Pro 6, hfsPath is assumed to be encoded as system
	text encoding as set by the preferred language in the Language&Text control panel.
	
	When running with Igor Pro 7, hfsPath is assumed to be encoded as UTF-8.
	
	Returns 0 if OK or an error code.	

	Thread Safety: FullHFSPathToMacFSRef is thread-safe. It can be called from any thread.
*/
static int
FullHFSPathToMacFSRef(const char* hfsPath, FSRef* fsRefPtr)
{
	char posixPath[MAX_PATH_LEN+1];
	int err;
	
	if (strlen(hfsPath) > MAX_PATH_LEN)
		return PATH_TOO_LONG;
	
	// hfsPath is system text encoding in Igor6, UTF-8 in Igor7. posixPath is always UTF-8.
	if (err = HFSToPosixPath(hfsPath, posixPath, 0))
		return err;

	if (err = FSPathMakeRef((unsigned char*)posixPath, fsRefPtr, NULL))	// Takes UTF-8 POSIX path
		return err;
				
	return 0;
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
	FSRef parentFSRef;
	FSCatalogInfoBitmap whichInfo;
	FSCatalogInfo catalogInfo;
	FileInfo* fInfoPtr;
	const char* p;
	char pathToParent[MAX_PATH_LEN+1];
	int parentPathLength;
	char fileName[MAX_FILENAME_LEN+1];
	int fileNameLength;
	UniChar unicodeName[MAX_FILENAME_LEN];
	int unicodeLength;
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
			
	p = strrchr2(fullFilePath, ':');		// Find last colon.
	if (p == NULL)							// Has no colon?
		return FILE_CREATE_ERROR;
	
	parentPathLength = p - fullFilePath + 1;
	if (parentPathLength > MAX_PATH_LEN)
		return PATH_TOO_LONG;
	strncpy(pathToParent, fullFilePath, parentPathLength);
	pathToParent[parentPathLength] = 0;

	if (err = FullHFSPathToMacFSRef(pathToParent, &parentFSRef))
		return err;
	
	p += 1;
	if (strlen(p) > MAX_FILENAME_LEN)
		return WM_FILENAME_TOO_LONG;
	strcpy(fileName, p);

	fileNameLength = strlen(fileName);
	if (err = ConvertIgorTextEncodingToUTF2(fileName, fileNameLength, unicodeName, sizeof(unicodeName), &unicodeLength))
		return err;

	MemClear(&catalogInfo, sizeof(catalogInfo));
	whichInfo = kFSCatInfoFinderInfo;
	fInfoPtr = (FileInfo*)&catalogInfo.finderInfo;
	fInfoPtr->fileType = macFileType;
	fInfoPtr->fileCreator = macCreator;

	if (err = FSCreateFileUnicode(&parentFSRef, unicodeLength, unicodeName, whichInfo, &catalogInfo, NULL, NULL))
		return err;
	
	return 0;
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
	FSRef fsRef;
	int err;
	
	if (!FullPathPointsToFile(fullFilePath))
		return EXPECTED_FILE_NAME;
	
	if (err = FullHFSPathToMacFSRef(fullFilePath, &fsRef))
		return err;
		
	if (err = FSDeleteObject(&fsRef))
		return err;

	return 0;
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
	char path[MAX_PATH_LEN+1];
	
	if (strlen(fullFilePath) > MAX_PATH_LEN)
		return PATH_TOO_LONG;
	strcpy(path, fullFilePath);

	// Xcode's fopen expects a POSIX path.
	if (*path != '/') {	// Don't try to convert to POSIX if the calling routine has already done it. This is an "unofficial" behavior introduced by mistake but I will continue to support it so as not to break existing code.
		int err;
		if (err = HFSToPosixPath(path, path, 0))
			return err;			
	}

	*fileRefPtr = fopen(path, readOrWrite ? "wb" : "rb");
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
	FSRef fsRef;
	FSCatalogInfo catalogInfo;
	int flags;
	int err;
	
	if (err = FullHFSPathToMacFSRef(fullPath, &fsRef))
		return 0;
		
	MemClear(&catalogInfo, sizeof(catalogInfo));	// Not really necessary but makes it easier to see what's going on.
	flags = kFSCatInfoNodeFlags;
	if (err = FSGetCatalogInfo(&fsRef, flags, &catalogInfo, NULL, NULL, NULL))
		return err;
	
	if ((catalogInfo.nodeFlags & kFSNodeIsDirectoryMask) != 0)
		return 0;			// It's a directory
		
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
	FSRef fsRef;
	FSCatalogInfo catalogInfo;
	int flags;
	int err;
	
	if (err = FullHFSPathToMacFSRef(fullPath, &fsRef))
		return 0;
		
	MemClear(&catalogInfo, sizeof(catalogInfo));	// Not really necessary but makes it easier to see what's going on.
	flags = kFSCatInfoNodeFlags;
	if (err = FSGetCatalogInfo(&fsRef, flags, &catalogInfo, NULL, NULL, NULL))
		return err;
	
	if ((catalogInfo.nodeFlags & kFSNodeIsDirectoryMask) == 0)
		return 0;			// It's a file
		
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
	
	err = WinToMacPath(filePathOut);

	return err;
}

