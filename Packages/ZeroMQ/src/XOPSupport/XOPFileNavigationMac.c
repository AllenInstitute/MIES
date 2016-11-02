﻿// Platform-specific routines for Open File and Save File dialogs

#include "XOPStandardHeaders.h"			// Include ANSI headers, Mac headers, IgorXOP.h, XOP.h and XOPSupport.h

#ifdef IGOR64	// [ 64-bit support

int
XOPOpenFileDialog(
	const char* prompt,
	const char* fileFilterStr, int* fileIndexPtr,
	const char* initialDir,
	char filePath[MAX_PATH_LEN+1])
{
	return NOT_IMPLEMENTED;		// Not yet implemented for 64 bits
}

int
XOPSaveFileDialog(
	const char* prompt,
	const char* fileFilterStr, int* fileIndexPtr,
	const char* initialDir,
	const char* defaultExtensionStr,
	char filePath[MAX_PATH_LEN+1])
{
	return NOT_IMPLEMENTED;		// Not yet implemented for 64 bits
}

#else			// ][ 32-bit support

// Structure used during the filtering of files.
struct XOPNavFileTypeInfo {
	char menuItemText[256];
	char fileTypes[256];			// e.g., "TEXT,IGTX,****"
	char extensions[256];			// e.g., ".txt,.itx"
};
typedef struct XOPNavFileTypeInfo XOPNavFileTypeInfo;
typedef struct XOPNavFileTypeInfo* XOPNavFileTypeInfoPtr;
typedef struct XOPNavFileTypeInfo** XOPNavFileTypeInfoHandle;

/*	XOPNavParseFileFilterString(fileFilterStr, ftiHPtr)
	
	Parses the fileFilterStr into a form more easily used by the file filter function.	
	
	If the fileFilterStr can be parsed correctly, XOPNavParseFileFilterString
	returns a newly created XOPNavFileTypeInfoHandle via ftiHPtr
	and returns a function result of 0. You must dispose of the handle
	when you are finished with it.
	
	If there is an error in parsing, no handle is returned and the function
	result is non-zero.
*/
static int
XOPNavParseFileFilterString(const char* fileFilterStr, XOPNavFileTypeInfoHandle* ftiHPtr)
{
	XOPNavFileTypeInfoHandle ftiH;
	XOPNavFileTypeInfo fti;
	const char* p;
	const char* p1;
	
	*ftiHPtr = NULL;
	
	ftiH = (XOPNavFileTypeInfoHandle)NewHandle(0L);
	
	p = fileFilterStr;
	while(*p != 0) {
		MemClear(&fti, sizeof(fti));
		
		// First get the menu item text.
		
		p1 = strchr(p, ':');
		if (p1 == NULL) {
			DisposeHandle((Handle)ftiH);
			return 1;						// Error - no colon to mark end of menu string.
		}
		
		if (p1 - p >= sizeof(fti.menuItemText)) {
			DisposeHandle((Handle)ftiH);
			return 2;						// Error - no colon to mark end of menu string.
		}
			
		strncpy(fti.menuItemText, p, p1-p);
		p = p1 + 1;							// Skip past menu string to file type.
	
		// Now get the file types associated with this menu item.
		
		p1 = strchr(p, ':');
		if (p1 == NULL) {
			DisposeHandle((Handle)ftiH);
			return 3;						// Error - no colon to mark end of file types.
		}
		
		if (p1 - p >= sizeof(fti.fileTypes)) {
			DisposeHandle((Handle)ftiH);
			return 4;						// Error - file types string too long.
		}
		
		strncpy(fti.fileTypes, p, p1-p);
		p = p1 + 1;							// Skip past file types to extensions.

		// Now get the extensions associated with this menu item.
				
		p1 = strchr(p, ';');
		if (p1 == NULL) {
			DisposeHandle((Handle)ftiH);
			return 5;						// Error - no semicolon to mark end of extensions.
		}
		
		if (p1 - p >= sizeof(fti.extensions)) {
			DisposeHandle((Handle)ftiH);
			return 6;						// Error - extensions string too long.
		}
		
		strncpy(fti.extensions, p, p1-p);
		p = p1 + 1;							// Skip past extensions to next menu item, if any.
		
		// Add the XOPNavFileTypeInfo record to the handle.
		{
			int origNumBytes = GetHandleSize((Handle)ftiH);
			SetHandleSize((Handle)ftiH, origNumBytes + sizeof(XOPNavFileTypeInfo));
			if (MemError()) {
				DisposeHandle((Handle)ftiH);
				return 7;
			}
			memcpy((char*)*ftiH + origNumBytes, &fti, sizeof(XOPNavFileTypeInfo));
		}
	}
	
	*ftiHPtr = ftiH;
	
	return 0;
}

struct XOPNavCallbackData {		// Data that is passed by Navigation Services to our filter and event functions.
	int gotNavStartMessage;						// Used to workaround a bug in Navigation Service in Mac OS X.

	int isOpen;									// True if Open File dialog.
	int isSave;									// True if Save File dialog.

	XOPNavFileTypeInfoHandle ftiH;				// Used during filtering of files. Can be NULL.

	int index;									// Index into array of Enable menu (open) or Format menu (save) items to the selected type.
};
typedef struct XOPNavCallbackData XOPNavCallbackData;
typedef struct XOPNavCallbackData* XOPNavCallbackDataPtr;

static int
XOPNavFileDoFilter(XOPNavCallbackDataPtr callbackDataPtr, OSType theType, const char* theName)
{
	XOPNavFileTypeInfoHandle ftiH;
	XOPNavFileTypeInfoPtr ftiP;
	int index, numMenuItems;
	const char* fp;					// Pointer to file types.
	const char* ep;					// Pointer to extensions.
	const char* p;
	
	ftiH = callbackDataPtr->ftiH;
	if (ftiH == NULL)
		return 1;
	
	index = callbackDataPtr->index;				// Zero-based index of currently-selected menu item.
	numMenuItems = GetHandleSize((Handle)ftiH) / sizeof(XOPNavFileTypeInfo);
	if (index<0 || index>=numMenuItems)
		return 1;								// Something is wrong.

	ftiP = &(*ftiH)[callbackDataPtr->index];	// DEREFERENCE
	fp = ftiP->fileTypes;						// DEREFERENCE. Points to something like "TEXT,DATA"
	ep = ftiP->extensions;						// DEREFERENCE. Points to something like ".txt,.dat,.csv"
	
	// See if this file type passes the file type test.
	p = fp;
	while(*p) {									// Look through list of file types for one that matches this file's type.
		OSType thisType;
		int i;
		
		for(i=0; i<4; i++) {					// Check file type.
			if (p[i] == 0)
				return 1;						// Bad file type, contains NULL character.
		}
		
		thisType = *(OSType*)p;
		
		if (thisType == '****')
			return 1;							// '****' matches any file type.
		
		if (thisType == theType)
			return 1;							// This is the type we're looking for.
			
		p += 4;									// Skip this file type.
			
		if (*p != ',')
			break;								// No more file types.
		p += 1;									// Skip comma and continue.
	}
	
	// See if this file name passes the extension test.
	
	{
		int theNameLen;
		char theExtension[64];					// Extension from this file's name.
		int theExtensionLen;
		
		p = strrchr(theName, '.');				// Find last dot.
		if (p == NULL)
			return 0;							// File has no extension so there can be no match.
		
		theNameLen = strlen(theName);
		
		theExtensionLen = theName + theNameLen - p;
		if (theExtensionLen >= sizeof(theExtension))
			return 0;							// File has an outlandish extension.
		
		strncpy(theExtension, p, theExtensionLen);
		theExtension[theExtensionLen] = 0;
	
		p = ep;
		while(*p) {									// Look through list of file extensions for one that matches this file's extension.
			char thisExtension[64];
			int thisExtensionLen;
			const char* p1;
			
			p1 = strchr(p, ',');					// Point to separator between extensions.
			if (p1 == NULL)
				p1 = p + strlen(p);					// Point to null after last extension.
			
			thisExtensionLen = p1 - p;
			if (thisExtensionLen >= sizeof(thisExtension))
				return 0;							// Outlandish filter string.
			
			if (thisExtensionLen == theExtensionLen) {
				strncpy(thisExtension, p, thisExtensionLen);
				thisExtension[thisExtensionLen] = 0;
				
				if (CmpStr(thisExtension, theExtension) == 0)
					return 1;						// Extensions match.
			}
			
			if (*p1 == 0)
				break;								// End of extensions.
				
			p = p1 + 1;								// Skip comma and continue.
		}
	}
	
	return 0;			// Failed all tests.
}

static pascal Boolean
XOPNavFileFilter(
	AEDesc* theItem,
	void* info,
	NavCallBackUserData callBackUD,
	NavFilterModes filterMode)
{
	int display;
	NavFileOrFolderInfo* navInfo;
	XOPNavCallbackDataPtr callbackDataPtr;
	
	callbackDataPtr = (XOPNavCallbackDataPtr)callBackUD;

	display = 1;
	
	navInfo = (NavFileOrFolderInfo*)info;
	if (theItem->descriptorType == typeFSS) {		// This is the old method that works with the old NavGetFile and NavPutFile routines.
		if (!navInfo->isFolder) {
			FSSpec spec;
			char theName[256];
			OSType theType;
			int err;

			*theName = 0;
			err = AEGetDescData(theItem, &spec, sizeof(FSSpec));
			if (err == 0)
				CopyPascalStringToC(spec.name, theName);
				
			theType = navInfo->fileAndFolder.fileInfo.finderInfo.fdType;

			display = XOPNavFileDoFilter(callbackDataPtr, theType, theName);
		}
	}

	if (theItem->descriptorType == typeFSRef) {		// This is the new method that works with NavDialogRun.
		if (!navInfo->isFolder) {
			FSRef fsRef;
			int err;

			err = AEGetDescData(theItem, &fsRef, sizeof(FSRef));
			if (err == 0) {
				FSCatalogInfo catalogInfo;
				HFSUniStr255 unicodeName;
				char name[256];
				int nameLength;
				OSType fileType;

				err = FSGetCatalogInfo(&fsRef, kFSCatInfoNone, &catalogInfo, &unicodeName, NULL, NULL);
				if (err == 0) {
					err = ConvertUTF2ToSystemEncoding(unicodeName.unicode, unicodeName.length, name, sizeof(name)-1, &nameLength);
					if (err == 0) {
						fileType = navInfo->fileAndFolder.fileInfo.finderInfo.fdType;
						display = XOPNavFileDoFilter(callbackDataPtr, fileType, name);
					}
				}
			}
		}
	}
	
	return display;
}

static pascal void
XOPNavFileEventProc(
	const NavEventCallbackMessage callBackSelector, 
	NavCBRecPtr callBackParms, 
	NavCallBackUserData callBackUD)
{
	XOPNavCallbackDataPtr callbackDataPtr;
	int err;
	
	callbackDataPtr = (XOPNavCallbackDataPtr)callBackUD;

	switch(callBackSelector) {
		case kNavCBStart:
			{	// Set the initial item in the Enable popup menu.
				NavMenuItemSpec menuItemSpec;
				int index;

				index = callbackDataPtr->index;
				MemClear(&menuItemSpec, sizeof(menuItemSpec));
				menuItemSpec.menuType = (OSType)index;
				menuItemSpec.menuCreator = 'extn';		// See Carbon mailing list, 2001-05-30.
				err = NavCustomControl(callBackParms->context, kNavCtlSelectCustomType, &menuItemSpec);
				callbackDataPtr->gotNavStartMessage = 1;
			}
			break;
			
		case kNavCBPopupMenuSelect:		// User made selection in Show popup menu.
			if (callbackDataPtr->gotNavStartMessage) {		// In Mac OS X, we received this message before the dialog appears. This is a Mac OS X bug.
				NavMenuItemSpecPtr msp;
				
				// Remember the index of the selected file format.
				msp = (NavMenuItemSpecPtr)callBackParms->eventData.eventDataParms.param;
				callbackDataPtr->index = msp->menuType;		// menuType is a 0-based index into our array of CFStrings.
			}
			break;
	}
}

static void
XOPNavSetCustomMenuItems(XOPNavFileTypeInfoHandle ftiH, int numMenuItems, NavDialogCreationOptions* dialogOptionsPtr,
						int* fileIndexPtr, XOPNavCallbackDataPtr callbackDataPtr)
{
	CFStringRef menuPopupStrings[16];
	int menuItemNumber;
	int encoding;

	encoding = GetApplicationTextEncoding();		// Used for menu strings and prompts which can be localized.
	
	if (numMenuItems > 16)
		numMenuItems = 16;		// Limit set by size of menuPopupStrings array.

	for(menuItemNumber=0; menuItemNumber<numMenuItems; menuItemNumber+=1) {
		char menuItemText[255];
		strcpy(menuItemText, (*ftiH)[menuItemNumber].menuItemText);
		menuPopupStrings[menuItemNumber] = CFStringCreateWithCString(NULL, menuItemText, encoding);
	}
	dialogOptionsPtr->popupExtension = CFArrayCreate(NULL, (void*)menuPopupStrings, numMenuItems, NULL);
	if (dialogOptionsPtr->popupExtension != NULL)
		dialogOptionsPtr->optionFlags &= ~kNavNoTypePopup;
	
	/*	This is what will be initially selected in the Enable popup menu.
		By setting these fields, we make our filter function aware of that fact.
	*/
	if (fileIndexPtr != NULL) {						// If fileIndexPtr not null, honor the caller's request.
		if (*fileIndexPtr > 0) {					// *fileIndexPtr is one-based.
			if (*fileIndexPtr <= numMenuItems)
				callbackDataPtr->index = *fileIndexPtr-1;
		}
	}
}

/*	XOPNavOpenFileDialog(prompt, fileFilterStr, fileIndexPtr, initialDirSpecPtr, fileRefPtr)

	This routine should not be called directly by an XOP. Instead, use the
	platform-independent XOPOpenFileDialog routine.
	
	The fileFilterString controls what appears in the Show popup menu of the
	Macintosh Navigation Services Open File dialog. If you pass "", all files
	will be displayed in the Open File dialog. Otherwise, the files displayed
	will be controlled by the Show popup menu and the items in the Show popup
	menu will be defined by the fileFilterString.
	
	For example, if you want to let the user open text data files, you might
	design the fileFilterString such that the Show popup menu contains two items,
	like this:
		Data Files
		All Files
		
	By providing an All Files item, you give the user a chance to open a file
	that does not have the correct Macintosh file type. For example, a text file
	transfered from a PC to a Macintosh might have the file type "????" rather than
	"TEXT".
	
	To obtain a Show popup menu like this, you need to supply a fileFilterString
	with two sections. It might look like this:
	
		"Data Files:TEXT,DATA:.txt,.dat,.csv;All Files:****:;"
		
	The two section sections of this fileFilterString are:
		"Data Files:TEXT,DATA:.txt,.dat,.csv;"
		"All Files:****:;"
		
	Each section causes the creation of one item in the Show popup menu.
	
	Each section consists of three components: a menu item string to be displayed
	in the Show popup menu, a list of zero or more Macintosh file types (e.g., TEXT,DATA),
	and a list of extensions (e.g., .txt,.dat,.csv).
	
	In this example, the first menu item would be "Data Files". When the user selects
	this menu item, the Open File dialog would show any file whose Macintosh file type
	is TEXT or DATA plus any file whose extension is .txt, .dat, or .csv.
	
	Note that a colon marks the end of the menu item string, another colon marks the
	end of the list of Macintosh file types, and a semicolon marks the end of the
	list of extensions.
	
	The **** file type used in the second section is special. It means that the
	Open File dialog should display all files. In this section, no extensions
	are specified because there are no characters between the colon and the
	semicolon.
	
	The syntax of the fileFilterString is unforgiving. You must not use any
	extraneous spaces or any other extraneous characters. You must include the
	colons and semicolons as shown above. The trailing semicolon is required.
	If there is a syntax error, the entire fileFilterString will be treated
	as if it were empty, which will display all files.
	
	Thread Safety: XOPNavOpenFileDialog is not thread-safe.
*/
static int
XOPNavOpenFileDialog(
	const char* prompt,
	const char* fileFilterStr,
	int* fileIndexPtr,					// NULL or one-based index into typeList.
	FSRef* initialDirRefPtr,			// If not NULL, points to directory to display initially.
	FSRef* fileRefPtr)					// Output.
{
	NavDialogRef dialogRef;
	NavReplyRecord theReply;
	NavDialogCreationOptions dialogOptions;
	XOPNavCallbackData callbackData;
	XOPNavFileTypeInfoHandle ftiH;
	int numMenuItems;
	CFStringRef formatPopupStrings[16];
	TextEncoding encoding;
	int err;

	MemClear(&theReply, sizeof(NavReplyRecord));

	NavEventUPP eventUPP = NewNavEventUPP(XOPNavFileEventProc);
	NavObjectFilterUPP filterUPP = NewNavObjectFilterUPP(XOPNavFileFilter);
	
	MemClear(fileRefPtr, sizeof(FSRef));

	MemClear(formatPopupStrings, sizeof(formatPopupStrings));

	encoding = GetApplicationTextEncoding();		// Used for menu strings and prompts which can be localized.

	// Set default behavior for browser and dialog.
	NavGetDefaultDialogCreationOptions(&dialogOptions);
	dialogOptions.optionFlags |= kNavDontAddTranslateItems;
	dialogOptions.optionFlags |= kNavDontAutoTranslate;
	dialogOptions.optionFlags |= kNavSelectAllReadableItem;			// We don't care what application created the file.
	dialogOptions.preferenceKey = 0;
	if (*prompt != 0) {						// Have prompt?
		dialogOptions.message = CFStringCreateWithCString(NULL, prompt, encoding);
		dialogOptions.windowTitle = CFStringCreateWithCString(NULL, prompt, encoding);
	}
	
	// Prepare structure that is passed by Navigation Services to our filter and event functions.
	MemClear(&callbackData, sizeof(callbackData));
	callbackData.isOpen = 1;
	
	// Parse filter strings, if any. This defines Enable menu items.
	ftiH = NULL;
	numMenuItems = 0;
	if (*fileFilterStr != 0) {								// Not empty fileFilterStr?
		XOPNavParseFileFilterString(fileFilterStr, &ftiH);	// ftiH will be NULL if fileFilterStr is not correctly formed.
		if (ftiH != NULL)
			numMenuItems = GetHandleSize((Handle)ftiH) / sizeof(XOPNavFileTypeInfo);
	}
	callbackData.ftiH = ftiH;
	
	if (ftiH != NULL)				// Want custom Enable menu items?
		XOPNavSetCustomMenuItems(ftiH, numMenuItems, &dialogOptions, fileIndexPtr, &callbackData);
	
	err = NavCreateGetFileDialog(&dialogOptions, NULL, eventUPP, NULL, filterUPP, &callbackData, &dialogRef);
	if (err == 0) {
		if (initialDirRefPtr != NULL) {	// Do we want to point the dialog to a particular initial folder?
			AEDesc defaultLocation;

			err = AECreateDesc(typeFSRef, initialDirRefPtr, sizeof(FSRef), &defaultLocation);
			if (err == 0) {
				// This can be done before calling NavDialogRun. See Carbon mailing list 2001-04-21.
				err = NavCustomControl(dialogRef, kNavCtlSetLocation, &defaultLocation);
			}
			AEDisposeDesc(&defaultLocation);
			err = 0;		// This error does not prevent dialog from showing.
		}

		err = NavDialogRun(dialogRef);
		
		if (err == 0) {
			err = NavDialogGetReply(dialogRef, &theReply);
	
			// Get FSRef from Navigation Services reply record.
			if (err==0 && theReply.validRecord) {
				AEKeyword keyWord;
				DescType typeCode;
				Size actualSize;
				
				err = AEGetNthPtr(&theReply.selection, 1, typeFSRef, &keyWord, &typeCode, fileRefPtr, sizeof(FSRef), &actualSize);
			}
		}
	}
	
	if (err == userCanceledErr)
		err = -1;		// -1 means cancel in Igor.

	// Let the caller know which custom menu item was chosen.
	if (fileIndexPtr != NULL)
		*fileIndexPtr = callbackData.index+1;	// *fileIndexPtr is one-based.
	
	if (ftiH != NULL)
		DisposeHandle((Handle)ftiH);

	NavDisposeReply(&theReply);

	DisposeNavEventUPP(eventUPP);
	
	DisposeNavObjectFilterUPP(filterUPP);

	if (dialogOptions.message != NULL)
		CFRelease(dialogOptions.message);

	if (dialogOptions.windowTitle != NULL)
		CFRelease(dialogOptions.windowTitle);
		
	if (dialogOptions.popupExtension != NULL)
		CFRelease(dialogOptions.popupExtension);	// Also releases the CFStrings that we allocated.

	NavDialogDispose(dialogRef);
	
	return err;
}

/*	XOPNavSaveFileDialog(prompt, formatMenuStr, fileIndexPtr, proposedFileName, initialDirRefPtr, pathOut)

	This routine should not be called directly by an XOP. Instead, use the
	platform-independent XOPSaveFileDialog routine.
	
	The formatMenuStr controls what appears in the Format popup menu of the
	Macintosh Navigation Services Save File dialog. If you pass "", the Format
	menu will be hidden. This is appropriate if the file can be saved in one format
	only. Otherwise, the Format popup menu will be displayed and its items will
	be defined by formatMenuStr.
	
	For example, if you want to let the user save a file as either plain text or
	as an Igor text file, you would use the following for formatMenuStr:
		"Plain Text:TEXT:.txt;Igor Text:IGTX:.itx;"
		
	This would give you a Format menu like this:
		Plain Text
		Igor Text
	
	The format of formatMenuStr is the same as the format of the fileFilterStr
	parameter to XOPNavOpenFileDialog, except that you should specify only one
	file type and extension for each section.
	
	At present, only the menu item strings ("Plain Text" and "Igor Text"
	in the example above) are used. The Macintosh file types (TEXT and IGTX) and
	the extensions (".txt" and ".itx") are currently not used. But you should pass
	some valid values anyway because a future XOP Toolkit might use them. If there
	is no meaningful extension, leave the extension section blank.
	
	The Format popup menu in the Save File dialog allows the user to tell you
	in what format the file should be saved. Unlike the Show popup menu in the
	Open File dialog, the Format menu has no filtering function. You find out
	which item the user chose via the fileIndexPtr parameter.
	
	The syntax of the formatMenuString is unforgiving. You must not use any
	extraneous spaces or any other extraneous characters. You must include the
	colons and semicolons as shown above. The trailing semicolon is required.
	If there is a syntax error, the entire fileFilterString will be treated
	as if it were empty, which will display all files.
	
	Thread Safety: XOPNavSaveFileDialog is not thread-safe.
*/
static int
XOPNavSaveFileDialog(
	const char* prompt, const char* formatMenuStr, int* fileIndexPtr, const char* proposedFileName,
	FSRef* initialDirRefPtr, char pathOut[MAX_PATH_LEN+1])
{	
	NavDialogRef dialogRef;
	NavDialogCreationOptions dialogOptions;
	NavUserAction userAction;
	NavReplyRecord theReply;
	XOPNavCallbackData callbackData;
	XOPNavFileTypeInfoHandle ftiH;
	int numMenuItems;
	int encoding;
	int err;

	NavEventUPP eventUPP = NewNavEventUPP(XOPNavFileEventProc);
	
	*pathOut = 0;
	
	MemClear(&theReply, sizeof(theReply));
	
	encoding = GetApplicationTextEncoding();		// Used for menu strings and prompts which can be localized.
	
	// Set default behavior for browser and dialog.
	if (err = NavGetDefaultDialogCreationOptions(&dialogOptions))
		return err;
	dialogOptions.optionFlags |= kNavNoTypePopup;					// Fixed later if we want a custom Format menu.
	dialogOptions.optionFlags |= kNavDontAddTranslateItems;
	dialogOptions.optionFlags &= ~kNavAllowStationery;				// XOP usually do not support stationery.
	if (*prompt != 0) {						// Have prompt?
		dialogOptions.message = CFStringCreateWithCString(NULL, prompt, encoding);
		dialogOptions.windowTitle = CFStringCreateWithCString(NULL, prompt, encoding);
	}
	dialogOptions.saveFileName = CFStringCreateWithCString(NULL, proposedFileName, encoding);
	
	// Prepare structure that is passed by Navigation Services to our event function.
	MemClear(&callbackData, sizeof(callbackData));
	callbackData.isSave = 1;
	
	// Parse filter strings, if any. This defines Format menu items.
	ftiH = NULL;
	numMenuItems = 0;
	if (*formatMenuStr != 0) {								// Not empty formatMenuStr?
		XOPNavParseFileFilterString(formatMenuStr, &ftiH);	// ftiH will be NULL if formatMenuStr is not correctly formed.
		if (ftiH != NULL)
			numMenuItems = GetHandleSize((Handle)ftiH) / sizeof(XOPNavFileTypeInfo);
	}
	callbackData.ftiH = ftiH;

	if (ftiH != NULL)				// Want custom Format menu items?
		XOPNavSetCustomMenuItems(ftiH, numMenuItems, &dialogOptions, fileIndexPtr, &callbackData);

	if (err = NavCreatePutFileDialog(&dialogOptions,'\?\?\?\?',kNavGenericSignature,eventUPP,&callbackData,&dialogRef))
		return err;
		
	// Point the dialog to a particular initial folder.
	if (initialDirRefPtr != NULL) {
		AEDesc defaultLocation;
		err = AECreateDesc(typeFSRef, initialDirRefPtr, sizeof(FSRef), &defaultLocation);
		if (err == 0) {
			// This can be done before calling NavDialogRun. See Carbon mailing list 2001-04-21.
			err = NavCustomControl(dialogRef, kNavCtlSetLocation, &defaultLocation);
			err = 0;		// Error here is not fatal.
			AEDisposeDesc(&defaultLocation);
		}
	}
		
	err = NavDialogRun(dialogRef);
	
	userAction = NavDialogGetUserAction(dialogRef);
	if (err==0 && userAction==kNavUserActionCancel)
		err = -1;			// -1 means cancel in Igor.
		
	if (err == 0) {
		err = NavDialogGetReply(dialogRef, &theReply);
		if (err==0 && !theReply.validRecord)
			err = fnfErr;						// Unlikely.
		if (err == 0) {
			AEKeyword keyWord;
			AEDesc resultDesc;
			FSRef parentDirFSRef;
			
			MemClear(&parentDirFSRef, sizeof(parentDirFSRef));

			err = AEGetNthDesc(&theReply.selection, 1, typeFSRef, &keyWord, &resultDesc);
			if (err == 0) {
				err = AEGetDescData(&resultDesc, &parentDirFSRef, sizeof(FSRef));
				AEDisposeDesc(&resultDesc);
			}
			
			if (err == 0) {
				err = MacFSRefToFullHFSPath(&parentDirFSRef, pathOut);
				if (err == 0) {
					char fileName[MAX_FILENAME_LEN+1];
					if (CFStringGetCString(theReply.saveFileName, fileName, sizeof(fileName), CFStringGetSystemEncoding()) == 0)
						err = PATH_TOO_LONG;
					if (err == 0) {
						if (strlen(pathOut) + strlen(fileName) > MAX_PATH_LEN)
							err = PATH_TOO_LONG;
						else
							strcat(pathOut, fileName);
					}
				}
			}

			NavDisposeReply(&theReply);
		}
	}
	
	// Let the caller know which custom menu item was chosen.
	if (fileIndexPtr != NULL)
		*fileIndexPtr = callbackData.index+1;	// *fileIndexPtr is one-based.
	
	if (eventUPP != NULL)
		DisposeNavEventUPP(eventUPP);

	if (ftiH != NULL)
		DisposeHandle((Handle)ftiH);

	if (dialogOptions.message != NULL)
		CFRelease(dialogOptions.message);

	if (dialogOptions.windowTitle != NULL)
		CFRelease(dialogOptions.windowTitle);

	if (dialogOptions.saveFileName != NULL)
		CFRelease(dialogOptions.saveFileName);
		
	if (dialogOptions.popupExtension != NULL)
		CFRelease(dialogOptions.popupExtension);	// Also releases the CFStrings that we allocated, if any.
	
	NavDialogDispose(dialogRef);
	
	return err;
}

/*	XOPOpenFileDialog(prompt, fileFilterStr, fileIndexPtr, initialDir, filePath)

	Displays the open file dialog.
	
	Returns 0 if the user chooses a file or -1 if the user cancels or another
	non-zero number in the event of an error. Returns the full path to the
	file via filePath. In the event of a cancel, filePath is unmodified.
	filePath is a native path (using colons on Macintosh, backslashes on Windows).
	
	prompt sets the dialog window title.
	
	If fileFilterStr is "", then the open file dialog displays all types
	of files, both on Macintosh and Windows. If fileFilterStr is not "",
	it identifies the type of files to display.

	fileFilterStr provides control over the Enable popup menu which the Macintosh Navigation
	Manager displays in the Open File dialog.  For example, the string
		"Text Files:TEXT,IGTX:.txt,.itx;All Files:****:;"
	results in two items in the Enable popup menu. The first says "Text Files"
	and displays any file whose Macintosh file type is TEXT or IGTX as well as any
	file whose file name extension is ".txt" or ".itx". The second item says "All Files"
	and displays all files.
	
	For further details on the fileFilterStr on Macintosh, see the comments in XOPNavOpenFileDialog.
	
	On Windows, fileFilterStr is constructed as for the lpstrFilter field of
	the OPENFILENAME structure for the Windows GetOpenFileName routine. For
	example, to allow the user to select text files and Igor Text files, use
	"Text Files (*.txt)\0*.txt\0Igor Text Files (*.itx)\0*.itx\0All Files (*.*)\0*.*\0\0".
	Note that the string ends with two null characters (\0\0).
	
	fileIndexPtr is ignored if it is NULL. If it is not NULL, then
	*fileIndexPtr is the one-based index of the file type filter to be initially
	selected. In the example given above, setting *fileIndexPtr to 2 would select
	the Igor Text file filter on entry to the dialog. On exit from the dialog,
	*fileIndexPtr is set to the index of the file filter string that the user last
	selected.  
	
	initialDir can be "" or it can point to a full path to a directory. It
	determines the directory that will be initially displayed in the open file
	dialog. If "", the directory will be the last directory that was seen
	in the open or save file dialogs. If initialDir points to a valid path to a directory,
	then this directory will be initially displayed in the dialog. On Macintosh,
	initialDir is a Macintosh HFS path. On Windows, it is a Windows path.
	
	Returns via filePath the full path to the file that the user chose. filePath
	is unchanged if the user cancels. filePath is a Macintosh HFS path on Macintosh
	and a Windows path on Windows. filePath must point to a buffer of
	at least MAX_PATH_LEN+1 bytes.
	
	On Windows, the initial value of filePath sets the initial contents of
	the File Name edit control in the open file dialog. The following values
	are valid:
		""									If there is no initial file name
		a file name
		a full Mac or Win path to a file
	
	On Macintosh, the initial value of filePath is not currently used. It should be set
	the same as for Windows because it may be used in the future.
	
	In the event of an error other than a cancel, XOPOpenFileDialog displays
	an error dialog. This should never or rarely happen.
	
	WINDOWS NOTES
	
	The dialog will appear in the upper left corner of the screen. This is
	because Windows provides no straight-forward way to set the position of
	the dialog.
	
	Thread Safety: XOPOpenFileDialog is not thread-safe.
*/
int
XOPOpenFileDialog(
	const char* prompt,
	const char* fileFilterStr, int* fileIndexPtr,
	const char* initialDir,
	char filePath[MAX_PATH_LEN+1])
{
	FSRef initialDirRef;
	FSRef* initialDirRefPtr;
	FSRef resultRef;
	int err;

	if (!CheckRunningInMainThread("XOPOpenFileDialog"))
		return NOT_IN_THREADSAFE;
	
	initialDirRefPtr = NULL;
	if (*initialDir != 0) {
		if (strlen(initialDir) < 256) {		// We need a Pascal string for FSMakeFSSpec and Pascal strings are limited to 255 characters.
			FSSpec initialDirSpec;
			unsigned char pInitialDir[256];
			
			CopyCStringToPascal(initialDir, pInitialDir);
			err = FSMakeFSSpec(0, 0, pInitialDir, &initialDirSpec);
			if (err == 0) {
				err = FSpMakeFSRef(&initialDirSpec, &initialDirRef);
				if (err == 0)
					initialDirRefPtr = &initialDirRef;
			}
		}
	}
	
	if (err = XOPNavOpenFileDialog(prompt, fileFilterStr, fileIndexPtr, initialDirRefPtr, &resultRef)) {
		if (err != -1)			// -1 is cancel
			IgorError("XOPOpenFileDialog XOPNavOpenFileDialog", err);
		return err;
	}
	
	if (err = MacFSRefToFullHFSPath(&resultRef, filePath)) {
		IgorError("XOPOpenFileDialog MacFSRefToFullHFSPath", err);
		return err;				// Should never happen.
	}
	
	return 0;
}

/*	XOPSaveFileDialog(prompt, fileFilterStr, fileIndexPtr, initialDir, defaultExtensionStr, filePath)

	Displays the save file dialog.
	
	Returns 0 if the user provides a file name or -1 if the user cancels or another
	non-zero number in the event of an error.
	
	Returns the full path to the file via filePath. filePath is both an input and an
	output as explained below. In the event of a cancel, filePath is unmodified.
	filePath is a Macintosh HFS path on Macintosh and a Windows path on Windows.
	
	prompt sets the dialog window title.
	
	On Macintosh, if there is only one format in which you can save the file,
	pass "" for fileFilterStr. This will cause the Format menu to be hidden.
	If you can save the file in more than one format, pass a string like this:
		"Plain Text:TEXT:.txt;Igor Text:IGTX:.itx;"
		
	This would give you a Format menu like this:
		Plain Text
		Igor Text
	
	fileFilterStr on Macintosh

		fileFilterStr consists of sections terminated by a semicolon. For example,
		here is one section:
			"Data Files:TEXT:.dat;"
			
		Each section consists of three components: a menu item string (e.g., Data Files)
		to be displayed in the Format popup menu, a Macintosh file type (e.g., TEXT),
		and an extension (e.g., .dat).

		At present, only the menu item string and extension are used.

		The Macintosh file type is currently not used. If there is no meaningful Macintosh
		file type, leave the file type component empty.

		If there is no meaningful extension, leave the extension component empty.

	fileFilterStr on Windows
	
		On Windows, fileFilterStr identifies the types of files to display and the types
		of files that can be created. It is constructed as for the lpstrFilter
		field of the OPENFILENAME structure for the Windows GetSaveFileName routine.
		For example, to allow the user to save as a text file or as an Igor Text file,
		use "Text Files (*.txt)\0*.txt\0Igor Text Files (*.itx)\0*.itx\0\0". Note that
		the string ends with two null characters (\0\0). If fileFilterStr is "", this
		behaves the same as "Text Files (*.txt)\0*.txt\0\0". 
	
	fileIndexPtr is ignored if it is NULL. If it is not NULL, then *fileIndexPtr
	is the one-based index of the file type filter to be initially selected.
	In the example given above, setting *fileIndexPtr to 2 would select the Igor
	Text file type on entry to the dialog. On exit from the dialog, *fileIndexPtr
	is set to the index of the file type string that the user last selected.
	
	initialDir can be "" or it can point to a full path to a directory. It
	determines the directory that will be initially displayed in the save file
	dialog. If "", the directory will be the last directory that was seen in the
	open or save file dialogs. If initialDir points to a valid path to a directory,
	then this directory will be initially displayed in the dialog. On Macintosh,
	initialDir is a Macintosh HFS path. On Windows, it is a Windows path. 
	
	defaultExtensionStr points to the extension to be added to the
	file name if the user does not enter an extension. For example, pass "txt"
	to have ".txt" appended if the user does not enter an extension. If you don't
	want any extension to be added in this case, pass NULL.
	
	Prior to XOP Toolkit 6.00, defaultExtensionStr was ignored on Macintosh.
	
	Returns via filePath the full path to the file that the user chose
	or "" if the user cancelled. The path is a Macintosh HFS path on Macintosh
	and a Windows path on Windows. filePath must point to a buffer of
	at least MAX_PATH_LEN+1 bytes.
	
	On Windows and Macintosh, the initial value of filePath sets the initial contents of
	the File Name edit control in the save file dialog. The following values
	are valid:
		""									If there is no initial file name
		a file name
		a full Mac or Win path to a file
	
	In the event of an error other than a cancel, XOPSaveFileDialog displays
	an error dialog. This should never or rarely happen.
	
	WINDOWS NOTES
	
	The dialog will appear in the upper left corner of the screen. This is
	because Windows provides no straight-forward way to set the position of
	the dialog.
	
	Thread Safety: XOPSaveFileDialog is not thread-safe.
*/
int
XOPSaveFileDialog(
	const char* prompt,
	const char* fileFilterStr, int* fileIndexPtr,
	const char* initialDir,
	const char* defaultExtensionStr,
	char filePath[MAX_PATH_LEN+1])
{
	FSRef initialDirRef;
	FSRef* initialDirRefPtr;
	char proposedFileName[MAX_FILENAME_LEN+1];
	int err;

	if (!CheckRunningInMainThread("XOPSaveFileDialog"))
		return NOT_IN_THREADSAFE;
	
	initialDirRefPtr = NULL;
	if (*initialDir != 0) {
		if (FullHFSPathToMacFSRef(initialDir, &initialDirRef) == 0)
			initialDirRefPtr = &initialDirRef;
	}
	
	GetLeafName(filePath, proposedFileName);		// This can be a full path.

	if (err = XOPNavSaveFileDialog(prompt, fileFilterStr, fileIndexPtr, proposedFileName, initialDirRefPtr, filePath)) {
		if (err != -1)			// -1 is cancel
			IgorError("XOPSaveFileDialog XOPNavSaveFileDialog", err);
		return err;
	}

	// HR, 100712, XOP Toolkit 6.00: The defaultExtensionStr parameter is now honored.
	if (defaultExtensionStr!=NULL && *defaultExtensionStr!=0) {
		char* pDot;
		char* pColon;
		pDot = strrchr(filePath, '.');				// Note that dot is not a legal second byte in a two-byte Japanese character.
		pColon = strrchr(filePath, ':');			// Note that colon is not a legal second byte in a two-byte Japanese character.
		if (pDot==NULL || pDot<pColon) {			// No dot or last dot occurs before last colon?
			int len1 = strlen(filePath);
			int len2 = strlen(defaultExtensionStr);
			if (len1 + 1 + len2 <= MAX_PATH_LEN)	// HR, 2014-08-29: Fixed error in checking length
				sprintf(filePath+len1, ".%s", defaultExtensionStr);
			else
				return PATH_TOO_LONG;
		}
	}

	return 0;
}

#endif		// ] 32-bit support
